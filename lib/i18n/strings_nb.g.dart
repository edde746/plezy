///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:plezy/i18n/locale_preferences.dart';
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
	@override late final _Translations$appIcon$nb appIcon = _Translations$appIcon$nb._(_root);
	@override late final _Translations$auth$nb auth = _Translations$auth$nb._(_root);
	@override late final _Translations$common$nb common = _Translations$common$nb._(_root);
	@override late final _Translations$screens$nb screens = _Translations$screens$nb._(_root);
	@override late final _Translations$update$nb update = _Translations$update$nb._(_root);
	@override late final _Translations$settings$nb settings = _Translations$settings$nb._(_root);
	@override late final _Translations$themeEditor$nb themeEditor = _Translations$themeEditor$nb._(_root);
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
	@override late final _Translations$accountPreferences$nb accountPreferences = _Translations$accountPreferences$nb._(_root);
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
	@override late final _Translations$cast$nb cast = _Translations$cast$nb._(_root);
	@override late final _Translations$automation$nb automation = _Translations$automation$nb._(_root);
	@override late final _Translations$notifications$nb notifications = _Translations$notifications$nb._(_root);
	@override late final _Translations$appAccess$nb appAccess = _Translations$appAccess$nb._(_root);
	@override late final _Translations$detail$nb detail = _Translations$detail$nb._(_root);
	@override late final _Translations$watchLink$nb watchLink = _Translations$watchLink$nb._(_root);
	@override late final _Translations$homeLayout$nb homeLayout = _Translations$homeLayout$nb._(_root);
	@override late final _Translations$platform$nb platform = _Translations$platform$nb._(_root);
	@override late final _Translations$universalMedia$nb universalMedia = _Translations$universalMedia$nb._(_root);
	@override late final _Translations$fileSources$nb fileSources = _Translations$fileSources$nb._(_root);
	@override late final _Translations$lending$nb lending = _Translations$lending$nb._(_root);
	@override late final _Translations$audiobook$nb audiobook = _Translations$audiobook$nb._(_root);
	@override late final _Translations$sourceSetup$nb sourceSetup = _Translations$sourceSetup$nb._(_root);
	@override late final _Translations$comics$nb comics = _Translations$comics$nb._(_root);
	@override late final _Translations$games$nb games = _Translations$games$nb._(_root);
	@override late final _Translations$deepLinks$nb deepLinks = _Translations$deepLinks$nb._(_root);
}

// Path: app
class _Translations$app$nb extends Translations$app$en {
	_Translations$app$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: appIcon
class _Translations$appIcon$nb extends Translations$appIcon$en {
	_Translations$appIcon$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Appikon';
	@override String get defaultIcon => 'Standard';
	@override String get current => 'Gjeldende ikon';
	@override String get locked => 'Livslang tilgang kreves';
	@override String get lockedHint => 'Start 7-dagers prøvetur eller avlokk PlezyNG for livet for å bruke alternative ikoner.';
	@override String get changeFailed => 'Kunne ikke endre appikonet';
	@override String get launcherHint => 'Det nye ikonet vises på startskjermen når du forlater PlezyNG.';
	@override String get tvLauncherHint => 'Det nye banneret vises når du forlater PlezyNG. Android TV kan fortsette å vise det gamle til TV-en startes på nytt.';
	@override late final _Translations$appIcon$names$nb names = _Translations$appIcon$names$nb._(_root);
	@override String get description => 'Velg ikonet som vises av enhetslungeren din. Forhåndsvisningene viser hvordan hver alternativ ser ut.';
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
	@override String get quickConnect => 'Quick Connect';
	@override String get useQuickConnect => 'Bruk Quick Connect';
	@override String get quickConnectInstructions => 'Åpne Quick Connect i Jellyfin og skriv inn denne koden.';
	@override String get quickConnectWaiting => 'Venter på godkjenning…';
	@override String get quickConnectCancel => 'Avbryt';
	@override String get quickConnectExpired => 'Quick Connect er utløpt. Prøv igjen.';
	@override String get localDataRecoveryRequired => 'PlezyNG kunne ikke gjenopprette lokale innloggingsdata og ventende avspillingsdata på en sikker måte. Logg inn på nytt.';
	@override String get pinCheckRejected => 'Kontrollen av Plex-PIN-koden ble avvist';
	@override String get connectToDirectPlex => 'Koble til lokal server Plex';
}

// Path: common
class _Translations$common$nb extends Translations$common$en {
	_Translations$common$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Avbryt';
	@override String get save => 'Lagre';
	@override String get close => 'Lukk';
	@override String get closeMiniPlayer => 'Nær Mini-spillere';
	@override String get closeWorkspaceWindow => 'Nær vindu';
	@override String get returnToFullView => 'Tilbake til Full View';
	@override String get manageMediaSessions => 'Ledelse av media sesjoner';
	@override String get hideMediaSessions => 'Skjære mediekonferanser';
	@override String get mediaSessions => 'Media sesjoner';
	@override String get mediaSessionsHint => 'Velg for å bringe en sesjon fremover. Park skjuler vinduet, men holder det åpent. Return åpner den i full visning; nær slutter den.';
	@override String get sessionInWorkspace => 'På arbeidsplassen';
	@override String get sessionParked => 'Parkert';
	@override String get sessionFullscreen => 'Full skjerm';
	@override String get switchToNextWindow => 'Swap med neste vindu';
	@override String get moveWindow => 'Flytte vindu';
	@override String get finishMovingWindow => 'Slutt å flytte vindu';
	@override String get moveWindowHint => 'Lang press og trekk vinduet for å bevege det. Denne kontrollen tillater også armbånd-nøkkelbevegelse.';
	@override String get movingWindowHelp => 'Dra til bevegelse · Slå nøkler justere · Enter sparer · Escape annullerer';
	@override String get resizeWindow => 'Åpne vinduet';
	@override String get resizeWindowHint => 'Dra denne håndboken eller bruk våpennøkler for å revidere vinduet.';
	@override String get workspaceWindowHint => 'Bruk bevegelseskontroller eller langpress og trekk for å flytte.';
	@override String get workspacePaneHint => 'Velg dette panelet for å fokusere på det. Bruk fullskjermkontrollen for å utvide den.';
	@override String workspaceWindowLabel({required Object title}) => 'Sesjon vindu: ${title}';
	@override String get workspaceTitleHint => 'Velg for å fokusere. Dra overskriftsfältet for å flytte; bruk fullskjermknappen for å utvide.';
	@override String get moveToSessionTray => 'Flytt til sesjon trey';
	@override String get moveToSessionTrayHint => 'Keeps denne sesjonen tilgjengelig uten å vise vinduet.';
	@override String get closeSessionHint => 'Stenger dette vinduet og avsluttes sesjonen.';
	@override String get sideBySideLayout => 'Switch til side-by-side layout';
	@override String get floatingWindows => 'Switch til å flyte vinduene';
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
	@override String get options => 'Valg';
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
	@override String get notAvailable => 'I/T';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
	@override late final _Translations$common$mediaKind$nb mediaKind = _Translations$common$mediaKind$nb._(_root);
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
	@override String get supportDeveloper => 'Støtt PlezyNG';
	@override String get supportDeveloperDescription => 'Doner for å støtte utviklingen';
	@override String get lifetimeAccess => 'PlezyNG Livslang tilgang';
	@override String get language => 'Språk';
	@override String get theme => 'Tema';
	@override String get appearance => 'Utseende';
	@override String get detailPage => 'Detail side';
	@override String get themeSongsEnabled => 'Spille tema sanger';
	@override String get themeSongsEnabledDescription => 'Spill tilgjengelige tema sanger mens du ser media detaljer.';
	@override String get themeSongVolume => 'Tema sang volum';
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
	@override String get emberTheme => 'Glød';
	@override String get glacierTheme => 'Isbre';
	@override String get forestTheme => 'Skog';
	@override String get plumTheme => 'Plomme';
	@override String get paperTheme => 'Papir';
	@override String get libraryDensity => 'Innholdstetthet i biblioteket';
	@override String get displayScale => 'Skalering';
	@override String get compact => 'Kompakt';
	@override String get comfortable => 'Komfortabel';
	@override String get gridSpacing => 'Rutenettavstand';
	@override String get gridSpacingTight => 'Tett';
	@override String get gridSpacingNormal => 'Normal';
	@override String get gridSpacingSpacious => 'Rommelig';
	@override String get tvCornerSpotlightBackdrop => 'Fremhevet bakgrunn i hjørnet';
	@override String get tvCornerSpotlightBackdropDescription => 'Vis fremhevet grafikk øverst til høyre i stedet for å fylle skjermen';
	@override String get viewMode => 'Visningsmodus';
	@override String get gridView => 'Rutenett';
	@override String get listView => 'Liste';
	@override String get showHeroSection => 'Vis fremhevet seksjon';
	@override String get showHomeBackdrop => 'Vis hjem bakgrunns kunstverk';
	@override String get showHomeBackdropDescription => 'Vis store kunstverk bak featured Home rader';
	@override String get contentScreensaverEnabled => 'Innhold Screensaver';
	@override String get contentScreensaverEnabledDescription => 'Vis fullskjerm kunstverk etter at appen har vært idle';
	@override String get contentScreensaverDelay => 'Start skjermbeskyttelse etter';
	@override String get contentScreensaverLibraries => 'Skjermbiblioteker';
	@override String get contentScreensaverLibrariesDescription => 'Velg hvilke biblioteker som skal levere bilder til skjermspareren. Hvis ingen velges, brukes bilder fra alle biblioteker.';
	@override String get contentScreensaverAllLibraries => 'Alle biblioteker';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} utvalgte bibliotek';
	@override String get contentScreensaverNoLibraries => 'Ingen tilkoblet mediebibliotek er tilgjengelig.';
	@override String get contentScreensaverDismissHint => 'Trykk på noen knapp eller trykk for å avvise';
	@override String get newEpisodeNotifications => 'Ny episode av meldinger';
	@override String get newEpisodeNotificationsDescription => 'Varsel når en ny episode blir lagt til en show du er fanget opp på. sjekker mens Plezy er åpen.';
	@override String get continueWatchingRowSize => 'Fortsett å se på størrelsen på raden';
	@override String continueWatchingRowSizeValue({required Object label}) => '${label} kort';
	@override String get rowSizeCompact => 'Kompakt';
	@override String get rowSizeStandard => 'Standard';
	@override String get rowSizeLarge => 'Stor';
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
	@override String get showWatchedIndicators => 'Vis sett-indikatorer';
	@override String get showWatchedIndicatorsDescription => 'Vis et hakemerke på sette filmer, serier og episoder';
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
	@override String get playbackBuffer => 'Avspillingsbuffer';
	@override String get playbackBufferAuto => 'Auto (anbefalt)';
	@override String get playbackBufferLarge => 'Stor';
	@override String get playbackBufferExtraLarge => 'Ekstra stor';
	@override String get playbackBufferDescription => 'Bufrer mer mot ustabile tilkoblinger. Begrenses også av bufferstørrelsen.';
	@override String get streamBufferSize => 'Buffer størrelse';
	@override String streamBufferSizeValue({required Object size}) => '${size} MB';
	@override String get streamBufferSizeDescription => 'Hvor mye video å laste frem når du spiller direkte. transkoder stopper på serverens egen transkodebufert. 0 = Auto';
	@override String get streamBufferSizeExoNote => 'Replaser Playback Buffer når du setter inn, kappet til halvparten av appens minnegrense';
	@override String get streamBufferMegabytes => 'Megabytes';
	@override String get defaultQualityTitle => 'Standardkvalitet';
	@override String get cellularQualityTitle => 'Standardkvalitet på mobilnett';
	@override String get remoteQualityTitle => 'Kvalitet på fjernstrømning';
	@override String get remoteQualitySameAsDefault => 'Det samme som standard kvalitet';
	@override String get cellularQualitySameAsDefault => 'Samme som standardkvalitet';
	@override String get directPlayCoveredQuality => 'Spill mindre videoer i original kvalitet';
	@override String get directPlayCoveredQualityDescription => 'Spill av videoer som allerede er innenfor kvalitetsgrensen med Direct Play i stedet for å transkode dem';
	@override String get videoCodecs => 'Videokodeker';
	@override String get videoCodecsDescription => 'Kodeker uten hake transkodes av serveren';
	@override String get videoCodecsAlwaysAccepted => 'Godtas alltid';
	@override String get musicQualityTitle => 'Musikkvalitet';
	@override String get subtitleStyling => 'Undertekststil';
	@override String get subtitleStylingDescription => 'Tilpass utseendet på undertekster';
	@override String get smallSkipDuration => 'Kort hoppvarighet';
	@override String get largeSkipDuration => 'Lang hoppvarighet';
	@override String get rewindOnResume => 'Spol tilbake ved gjenopptakelse';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(seconds,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} sekund',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} sekunder',
	);
	@override String get defaultSleepTimer => 'Standard innsovningstimer';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(minutes,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutt',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutter',
	);
	@override String get rememberTrackSelections => 'Husk sporvalg per serie/film';
	@override String get chooseTracksBeforePlayback => 'Velg lyd og undertittel før spilling';
	@override String get chooseTracksBeforePlaybackDescription => 'Velg opp kildekode og undertittelspor før hver video starter.';
	@override String get alwaysShowSubtitlesOnDevice => 'Vis alltid undertittel på denne enheten';
	@override String get alwaysShowSubtitlesOnDeviceDescription => 'Når serveren ikke har noen undertittel valgt, velg en spor lokalt. Dette endrer aldri serverens foretrukning.';
	@override String get autoDownloadPreferredSubtitle => 'Fettch savner foretrukne undertittel';
	@override String get autoDownloadPreferredSubtitleDescription => 'Velg et tilgjengelig undertittel på ditt foretrukne språk lokalt. Hvis det ikke finnes noe, be serveren om å få et når det støttes.';
	@override String get rememberTrackSelectionsDescription => 'Husk lyd- og undertekstvalg per tittel';
	@override String get rememberTrackSelectionsBackendRule => 'Plex lagrer hvert valg på serveren per fil; Jellyfin slår også på kontoinnstillingen «Husk valg»; Emby støttes ikke';
	@override String get followServerTrackSelections => 'Bruk serverens sporvalg per episode';
	@override String get followServerTrackSelectionsDescription => 'Ved episodebytte brukes lyden og undertekstene som er valgt på serveren, i stedet for å videreføre gjeldende valg';
	@override String get resumeMusicOnLaunch => 'Husk musikkøkt';
	@override String get resumeMusicOnLaunchDescription => 'Åpne den siste sangen på pause der den slapp når appen starter';
	@override String get showChapterMarkersOnTimeline => 'Vis kapittelmarkører på tidslinjen';
	@override String get showChapterMarkersOnTimelineDescription => 'Del tidslinjen ved kapittelgrenser';
	@override String get specialsOrdering => 'Spesialepisoder i episoderekkefølge';
	@override String get specialsOrderingDescription => 'Hvor spesialepisoder spilles av i seriens visningsrekkefølge';
	@override String get specialsOrderingServer => 'Følg serverrekkefølgen';
	@override String get specialsOrderingAirDate => 'Flett inn etter premieredato';
	@override String get specialsOrderingLast => 'Etter vanlige sesonger';
	@override String get clickVideoTogglesPlayback => 'Klikk på video for å veksle avspilling';
	@override String get clickVideoTogglesPlaybackDescription => 'Klikk på video for å spille av/pause i stedet for å vise kontroller.';
	@override String get videoPlayerControls => 'Videospillerkontroller';
	@override String get keyboardShortcuts => 'Tastatursnarveier';
	@override String get keyboardShortcutsDescription => 'Tilpass tastatursnarveier';
	@override String get videoPlayerNavigation => 'Videospillernavigering';
	@override String get videoPlayerNavigationDescription => 'Bruk piltaster for å navigere videospillerkontroller';
	@override String get watchTogetherRelay => 'Reléserver for Se sammen';
	@override String get watchTogetherRelayDescription => 'Offentlige Open Watch Party-reléservere, med mindre du angir din egen';
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
	@override String get importSettingsInvalidFile => 'Denne filen er ikke en gyldig PlezyNG-innstillingseksport';
	@override String get importSettingsNoUser => 'Logg inn før import av innstillinger';
	@override String get cloudBackup => 'Sikkerhetskopi i skyen';
	@override String get cloudBackupDescription => 'Sikkerhetskopier innstillinger som kan overføres, til en WebDAV-adresse via HTTPS. Servertilkoblinger og påloggingsinformasjon blir på denne enheten.';
	@override String get cloudBackupUrl => 'WebDAV JSON fil URL';
	@override String get cloudBackupUsername => 'Brukernavn';
	@override String get cloudBackupPassword => 'Passord';
	@override String get cloudBackupSaved => 'Cloud backup destinasjon reddet';
	@override String get cloudBackupNow => 'Tilbake nå';
	@override String get cloudBackupComplete => 'Oppdatering av Backup upload';
	@override String get cloudBackupRestore => 'Åpne backup';
	@override String get cloudBackupRestoreConfirm => 'Dette vil erstatte matching bærbare innstillinger på denne enheten.';
	@override String get cloudBackupRestored => 'Innstillinger gjenopprettet fra cloud backup';
	@override String get shortcutsReset => 'Snarveier tilbakestilt til standard';
	@override String get resetShortcutsConfirm => 'Dette vil erstatte de egendefinerte snarveiene dine med standardsnarveiene. Fortsette?';
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
	@override String get autoPlayAndSkip => 'Autospill og hopp';
	@override String get autoPlayNextEpisode => 'Spill neste episode automatisk';
	@override String get autoPlayNextEpisodeDescription => 'Start neste episode automatisk når en episode er ferdig';
	@override String get shuffleStartsFromBeginning => 'Tilfeldig avspilling starter fra begynnelsen';
	@override String get shuffleStartsFromBeginningDescription => 'Start hver episode fra begynnelsen ved tilfeldig avspilling i stedet for å fortsette';
	@override String get plexCinemaPreRoll => 'Bruker server kino intros';
	@override String get plexCinemaPreRollDescription => 'Spille konfigurert Plex pre-rolls eller Jellyfin og Emby intros før en film starter.';
	@override String get playNextCountdown => 'Nedtelling for neste episode';
	@override String get playNextCountdownImmediate => 'Spill umiddelbart';
	@override String get skipIntroMode => 'Hopp over intro';
	@override String get skipIntroModeOffDescription => 'Spill av introer normalt uten en hopp over-knapp';
	@override String get skipIntroModeButtonDescription => 'Vis en hopp over-knapp når en intro starter';
	@override String get skipIntroModeAutoDescription => 'Hopp over introer automatisk etter forsinkelsen nedenfor';
	@override String get skipCreditsMode => 'Hopp over rulletekst';
	@override String get skipCreditsModeOffDescription => 'Spill av rulleteksten normalt uten en hopp over-knapp';
	@override String get skipCreditsModeButtonDescription => 'Vis en hopp over-knapp når rulleteksten starter';
	@override String get skipCreditsModeAutoDescription => 'Hopp over rulleteksten automatisk, og spill neste episode';
	@override String get skipAdsMode => 'Hopp over reklame';
	@override String get skipAdsModeOffDescription => 'Spill oppdagede annonser vanligvis uten en skip-knappe';
	@override String get skipAdsModeButtonDescription => 'Vis en skip-knappe når Plex oppdager en annonsering';
	@override String get skipAdsModeAutoDescription => 'Slå opp oppdagede annonser automatisk etter forsinkelsen nedenfor';
	@override String get musicPlayback => 'Musikk Playback';
	@override String get musicSweetFades => 'Sød fader';
	@override String get musicSweetFadesDescription => 'Fade musikk på sporet når Plex har høyddata.';
	@override String get skipMarkerModeOff => 'Av';
	@override String get skipMarkerModeButton => 'Vis knapp';
	@override String get skipMarkerModeAuto => 'Automatisk';
	@override String get forceSkipMarkerFallback => 'Tving reservemarkører';
	@override String get forceSkipMarkerFallbackDescription => 'Bruk mønstre i kapiteltitler selv når Plex har markører';
	@override String get theIntroDbFallback => 'Bruk TheIntroDB som intro fallback';
	@override String get theIntroDbFallbackDescription => 'Bruk fellesskapstidene bare når serveren ikke har intro markerer.';
	@override String get autoSkipDelay => 'Forsinkelse for automatisk hopp';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Vent ${seconds} sekunder før automatisk hopping';
	@override String get introPattern => 'Intromarkørmønster';
	@override String get introPatternDescription => 'Regulært uttrykk for å gjenkjenne intromarkører i kapitteltitler';
	@override String get creditsPattern => 'Rulletekstmarkørmønster';
	@override String get creditsPatternDescription => 'Regulært uttrykk for å gjenkjenne rulletekstmarkører i kapitteltitler';
	@override String get prerolls => 'Forhåndsvideoer';
	@override String get playPrerollsBeforeMovies => 'Spill prorroller før filmer';
	@override String get playPrerollsBeforeMoviesDescription => 'Spille en tilfeldig klipp fra valget nedenfor før hver film. Trykk tilbake for å hoppe.';
	@override String get prerollLibrary => 'Preroll bibliotek';
	@override String get prerollLibraryNotSet => 'Ikke angitt';
	@override String get prerollLibraryNoneFound => 'Ingen biblioteker finnes på servere.';
	@override String get prerollSelection => 'Velg preroll';
	@override String get prerollSelectionPickLibraryFirst => 'Velg biblioteket først';
	@override String get prerollSelectionNoneSelected => 'Ingen forpliktelser valgt';
	@override String prerollSelectionCount({required Object count}) => '${count} valgt';
	@override String get prerollItemPicker => 'Velg forpliktelser';
	@override String get prerollItemPickerLoadFailed => 'Jeg kunne ikke laste opp artikler fra denne biblioteket.';
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
	@override String get autoDownloadContinueWatching => 'Auto-Download fortsetter å se';
	@override String get autoDownloadContinueWatchingDescription => 'Hold elementer på din Fortsatt Se shelf lastet ned, og fjerne dem når de forlater shelf';
	@override String get downloadQuality => 'Last ned kvalitet';
	@override String get downloadQualityDescription => 'Plex forbereder en konvertert kopi i nedlastingskoden. Jellyfin og Emby transkode mens filen lastes ned; avbrutte overføringer kan trenge å starte om.';
	@override String get askDownloadQualityEachTime => 'Velg kvalitet for hver nedlasting';
	@override String get askDownloadQualityEachTimeDescription => 'Vis kvalitetspikeren før du knytter hver video nedlasting';
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
	@override String get companionRemoteServerStartFailed => 'Kunne ikke starte fjernkontrollserveren';
	@override String get companionRemoteServerStopFailed => 'Kunne ikke stoppe fjernkontrollserveren';
	@override String get autoPip => 'Automatisk bilde-i-bilde';
	@override String get autoPipDescription => 'Åpne bilde-i-bilde når du forlater appen under avspilling';
	@override String get matchContentFrameRate => 'Tilpass innholdets bildefrekvens';
	@override String get matchContentFrameRateDescription => 'Tilpass skjermens oppdateringsfrekvens til videoinnhold';
	@override String get matchContentResolution => 'Tilpass til innholdets oppløsning';
	@override String get matchContentResolutionDescription => 'Bytter skjermen til videoens opprinnelige oppløsning, slik at TV-en tar seg av oppskaleringen. Menyer og undertekster skaleres også opp under avspilling';
	@override String get matchRefreshRate => 'Tilpass oppdateringsfrekvens';
	@override String get matchRefreshRateDescription => 'Tilpass skjermens oppdateringsfrekvens i fullskjerm';
	@override String get matchDynamicRange => 'Tilpass dynamikkområde';
	@override String get matchDynamicRangeDescription => 'Slå på HDR for HDR-innhold, og deretter tilbake til SDR';
	@override String get displaySwitchDelay => 'Forsinkelse ved skjermbytte';
	@override String get tunneledPlayback => 'Tunnelert avspilling';
	@override String get tunneledPlaybackDescription => 'Bruk videotunneling. Slå av hvis HDR-avspilling viser svart video eller bevegelser hakker.';
	@override String get audioPassthrough => 'Direkte lydutgang';
	@override String get audioPassthroughDescription => 'Send Dolby/DTS-lyd til mottakeren eller TV-en uten omkoding, slik at surroundlyd bevares. Slå av hvis du ikke har lyd.';
	@override String get audioPassthroughDescriptionApple => 'Bruk Apples innebygde Dolby-dekoder for Dolby Digital Plus, inkludert Atmos. DTS og TrueHD spilles fortsatt av som flerkanals PCM. Slå av hvis du ikke har lyd.';
	@override String get audioPassthroughDescriptionAppleSpatial => 'Bruk Apples innebygde Dolby-dekoder for Dolby Digital Plus, inkludert Atmos. På iOS, iPadOS og tvOS 26 eller nyere spilles TrueHD Atmos og DTS:X av som romlig lyd. Andre DTS- og TrueHD-spor spilles av som flerkanals PCM. Slå av hvis du ikke har lyd.';
	@override String get audioPassthroughOverriddenByNormalization => 'Av mens lydstyrkenormalisering er på';
	@override String get audioChannelLimit => 'Lydkanaler';
	@override String get audioChannelLimitDescription => 'Miks dekodet lyd ned for høyttalere, hodetelefoner eller HDMI-oppsett som ikke kan spille av alle kanalene';
	@override String get audioChannelLimitOriginal => 'Original';
	@override String get audioChannelLimitOriginalDescription => 'Spill av alle kanalene i sporet';
	@override String get audioChannelLimitSurround51 => 'Opptil 5.1';
	@override String get audioChannelLimitSurround51Description => 'Miks 7.1 ned til 5.1 for TV-er og mottakere som bare støtter 5.1 PCM. Direkte lydutgang påvirkes ikke.';
	@override String get audioChannelLimitStereo => 'Stereo';
	@override String get audioChannelLimitStereoDescription => 'Miks ned til to kanaler for stereohøyttalere eller hodetelefoner. Slår av direkte lydutgang.';
	@override String get downmixCenterBoost => 'Forsterkning av senterkanal';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Forsterkning (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Normaliser lydstyrke ved nedmiks';
	@override String get audioDownmixNormalizeDescription => 'Senker miksen for å unngå klipping. Slå av for å beholde originalvolumet (høye scener kan forvrenges).';
	@override String get dvConversionMode => 'Dolby Vision-konvertering';
	@override String get dvConversionModeDescription => 'Velg hvordan filer med Dolby Vision-profil 7 håndteres.';
	@override String get dvConversionAuto => 'Automatisk';
	@override String get dvConversionNative => 'Nativ / deaktivert';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Oppdag enhetens egenskaper og bruk vanlig reserveoppførsel';
	@override String get dvConversionNativeDescription => 'Tving opprinnelig DV7-avspilling og ikke prøv DV-konvertering på nytt';
	@override String get dvConversionDv81Description => 'Tving direkte RPU-konvertering til Dolby Vision-profil 8.1';
	@override String get dvConversionHevcStripDescription => 'Fjern Dolby Vision RPU/EL-lag og lever som vanlig HEVC';
	@override String get experimentalDolbyVision => 'Eksperimentell Dolby Vision';
	@override String get experimentalDolbyVisionDescription => 'Bruk den eksperimentelle FEL-rendereren ved neste avspilling. Krever en separat motorbygging.';
	@override String get dvExperimentUnavailableDescription => 'Dette eksperimentet er foreløpig bare tilgjengelig på Linux.';
	@override String get dvCompatibilityFallback => 'Kompatibilitetsreserve';
	@override String get dvCompatibilityFallbackDescription => 'Bruk standardrendereren hvis eksperimentet ikke kan starte. FEL-data kan gå tapt.';
	@override String get dvExperimentDiagnostics => 'Logging av videoeksperiment';
	@override String get dvExperimentDiagnosticsDescription => 'Aktiver detaljerte spillerlogger ved neste avspilling.';
	@override String get disableDolbyVision => 'Deaktiver Dolby Vision';
	@override String get disableDolbyVisionDescription => 'Spill av filens HDR10- eller HLG-lag i stedet for Dolby Vision når det finnes';
	@override String get hdrSdrConversion => 'HDR til SDR-konvertering';
	@override String get hdrSdrConversionDescription => 'Velg hva som konverterer HDR-video når skjermen ikke kan vise HDR.';
	@override String get hdrSdrConversionAuto => 'Automatisk';
	@override String get hdrSdrConversionAutoDescription => 'Enhet på Android 9 og nyere, spiller på eldre versjoner';
	@override String get hdrSdrConversionDevice => 'Enhet';
	@override String get hdrSdrConversionDeviceDescription => 'Enhetens videomaskinvare konverterer. Raskest, men fargene avhenger av enheten';
	@override String get hdrSdrConversionPlayer => 'Spiller';
	@override String get hdrSdrConversionPlayerDescription => 'Spilleren konverterer. Jevne farger, men 4K kan hakke på enkle TV-bokser';
	@override String get deinterlace => 'Deinterlacing';
	@override String get deinterlaceDescription => 'Fjern combing-artefakter fra interlaced video (kun mpv-spiller)';
	@override String get deinterlaceOff => 'Av';
	@override String get deinterlaceOffDescription => 'Vis interlaced video slik den dekodes';
	@override String get deinterlaceVideo => 'Video';
	@override String get deinterlaceVideoDescription => 'Gjør hvert halvbilde om til et helt bilde. For video spilt inn for TV, som sport, nyheter og konserter';
	@override String get deinterlaceFilm => 'Film';
	@override String get deinterlaceFilmDescription => 'Gjenopprett de opprinnelige bildene i film og animasjon som er konvertert med telecine til 29,97 fps, vanlig på NTSC-DVD-er. Video spilt inn for TV vil hakke. Direkte-TV bruker Video';
	@override String get requireProfileSelectionOnOpen => 'Spør om profil ved appåpning';
	@override String get requireProfileSelectionOnOpenDescription => 'Vis profilvalg hver gang appen åpnes';
	@override String get forceTvMode => 'Tving TV-modus';
	@override String get forceTvModeDescription => 'Tving TV-oppsett. For enheter som ikke oppdages automatisk. Krever omstart.';
	@override String get startInFullscreen => 'Start i fullskjerm';
	@override String get startInFullscreenDescription => 'Åpne PlezyNG i fullskjermmodus ved oppstart';
	@override String get exitFullscreenOnPlayerClose => 'Avslutt fullskjerm ved lukking av avspiller';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Avslutt fullskjerm automatisk når videospilleren lukkes';
	@override String get autoHidePerformanceOverlay => 'Skjul ytelsesoverlegg automatisk';
	@override String get autoHidePerformanceOverlayDescription => 'Ton ytelsesoverlegget ut sammen med avspillingskontrollene';
	@override String get showNavBarLabels => 'Vis etiketter i navigasjonsfeltet';
	@override String get showNavBarLabelsDescription => 'Vis tekstetiketter under ikonene i navigasjonsfeltet';
	@override String get startupSection => 'Startseksjon';
	@override String get preferredServer => 'Foretrukket server';
	@override String get preferredServerDescription => 'Prioriterer resultatene av denne serveren mens alle tilkoblet server er tilgjengelige.';
	@override String get preferredServerAutomatic => 'Automatisk';
	@override String get showExploreTab => 'Vis Oppdag-fanen';
	@override String get showExploreTabDescription => 'Vis Oppdag-fanen med innhold fra Plex Discover og tilkoblede sporingstjenester';
	@override String get hideEmptyLibraries => 'Slå tomme biblioteker';
	@override String get hideEmptyLibrariesDescription => 'Fjern biblioteker med en server-rapporterte elementer tall på null fra navigasjon.';
	@override String get liveTvDefaultFavorites => 'Vis favorittkanaler som standard';
	@override String get liveTvDefaultFavoritesDescription => 'Vis bare favorittkanaler når du åpner Direkte-TV';
	@override String get general => 'Generelt';
	@override String get generalDescription => 'Språk, oppstart og vindusatferd';
	@override String get languageAndRegion => 'Språk og region';
	@override String get startup => 'Oppstart';
	@override String get display => 'Skjerm';
	@override String get libraryAndCards => 'Bibliotek og kort';
	@override String get homeScreen => 'Hjemmeskjerm';
	@override String get navigation => 'Navigering';
	@override String get window => 'Vindu';
	@override String get liveTv => 'Direkte-TV';
	@override String get player => 'Spiller';
	@override String get videoAndDisplay => 'Video og skjerm';
	@override String get audio => 'Lyd';
	@override String get quality => 'Kvalitet';
	@override String get subtitles => 'Undertekster';
	@override String get seekAndTiming => 'Spoling og tidsinnstillinger';
	@override String get behavior => 'Oppførsel';
	@override String get gestures => 'Bevegelser';
	@override String get gestureBrightnessSwipe => 'Lysstyrke-sveip';
	@override String get gestureBrightnessSwipeDescription => 'Sveip opp eller ned på venstre kant for å justere lysstyrken';
	@override String get gestureVolumeSwipe => 'Volum-sveip';
	@override String get gestureVolumeSwipeDescription => 'Sveip opp eller ned på høyre kant for å justere volumet';
	@override String get gesturePinchToZoom => 'Klyp for å zoome';
	@override String get gesturePinchToZoomDescription => 'Klyp på videoen for å zoome inn eller ut';
	@override String get gestureSeekSwipe => 'Søk Swipe';
	@override String get gestureSeekSwipeDescription => 'Sving venstre eller høyre hvor som helst på videoen å søke; frigjør for å hoppe';
	@override String get rememberBrightnessLevel => 'Husk lysstyrkenivå';
	@override String get rememberBrightnessLevelDescription => 'Start avspilling med lysstyrken som ble satt med det siste sveipet';
	@override String get controls => 'Kontroller';
	@override String get rememberPlayerChanges => 'Husk endringer i spilleren';
	@override String get rememberPlayerChangesDescription => 'Hvor en endring under avspilling lagres og brukes på nytt';
	@override String get scopePlaybackSpeed => 'Avspillingshastighet';
	@override String get scopeShaderPreset => 'Forhåndsinnstilling for skyggelegging';
	@override String get scopeAspectRatio => 'Sideforhold';
	@override String get scopeSyncOffsets => 'Synkronisering av lyd og undertekster';
	@override String get playerScopeOff => 'Ikke lagre';
	@override String get playerScopeGlobal => 'Overalt';
	@override String get playerScopeLibrary => 'Per bibliotek';
	@override String get playerScopeTitle => 'Per serie eller film';
	@override String get exportDialogTitle => 'Eksporter PlezyNG-innstillinger';
	@override String get followSystem => 'Følg systemet';
	@override String get followAppLanguage => 'Samme som grensesnittspråket';
	@override String get regionFormat => 'Regionale formater';
	@override String get regionFormatDescription => 'Velg hvordan datoer, tall og måleenheter vises.';
	@override String get metadataLanguage => 'Språk for metadata';
	@override String get metadataLanguageDescription => 'Foretrukket språk for titler og beskrivelser når serveren støtter det. Lyd og undertekster stilles inn separat.';
	@override String get enterFullscreenOnPlaybackStart => 'Skriv inn fullskjermen når playback starter';
	@override String get enterFullscreenOnPlaybackStartDescription => 'Åpne desktop-video på fullskjerm når playback starter';
	@override String get extendVideoIntoDisplayCutout => 'Utvid video til display cutout';
	@override String get extendVideoIntoDisplayCutoutDescription => 'La fullskjermvideoen bruke kameraet på Android-telefoner';
	@override String get languageDescription => 'Velg språket som brukes til PlezyNG-kontroller og meldinger. Følg systemet sporer enhetsspråket ditt.';
	@override String get themeDescription => 'Velg fargene og kontrastene som brukes gjennom appen.';
	@override String get libraryDensityDescription => 'Endre hvor mange bibliotekkort som passer i hver rad.';
	@override String get displayScaleDescription => 'Gjenopprette grensesnittet på denne bilskjermen uten å endre tekststørrelsen på enheten din.';
	@override String get themeSongVolumeDescription => 'Sett volumet av tema sanger i forhold til andre lyd.';
	@override String get viewModeDescription => 'Velg om bibliotekselementer vises som plakater i et nettverk eller som en kompakt liste.';
	@override String get gridViewDescription => 'Ordne bibliotekselementer i rader og kolumner av plakater.';
	@override String get listViewDescription => 'Vis bibliotek elementer i en vertikal liste med mer tekst per element.';
	@override String get gridSpacingDescription => 'Sett gapet mellom plakater i biblioteksnett.';
	@override String get gridSpacingTightDescription => 'Fyll mer poster over skjermen med mindre gap.';
	@override String get gridSpacingNormalDescription => 'Bruk standardfrekvensen mellom poster.';
	@override String get gridSpacingSpaciousDescription => 'Legg til større gap mellom plakater for mer separasjon.';
	@override String get episodePosterModeDescription => 'Velg hvilket kunstverk som vises på episode kort.';
	@override String get seriesPosterDescription => 'Bruk showens serieposter for hver episode.';
	@override String get seasonPosterDescription => 'Bruk sesongposter for hver episode når det er tilgjengelig.';
	@override String get episodeThumbnailDescription => 'Bruk en ramme fra episoden når tilgjengelig.';
	@override String get continueWatchingActionDescription => 'Velg hva som skjer når du aktiverer en Continuing Watching-kort.';
	@override String get continueWatchingPlayDescription => 'Start filmen eller episoden umiddelbart.';
	@override String get continueWatchingDetailsDescription => 'Åpne tittelen først slik at du kan se nærmere på detaljene og velge en handling.';
	@override String get episodeActionDescription => 'Velg hva som skjer når du aktiverer et episode-kort.';
	@override String get episodePlayDescription => 'Begynn episoden umiddelbart.';
	@override String get episodeDetailsDescription => 'Åpne episode-siden før playback.';
	@override String get contentScreensaverDelayDescription => 'Velg hvor lenge PlezyNG venter uten inngang før du viser kunstverk.';
	@override String get continueWatchingRowSizeDescription => 'Velg hvor store kortene er i Continuing Watching-linjen.';
	@override String get rowSizeCompactDescription => 'Vis mindre kort slik at flere elementer passer over raden.';
	@override String get rowSizeStandardDescription => 'Bruk standard kortstørrelse.';
	@override String get rowSizeLargeDescription => 'Vis større kort med mer kunstverk detalj.';
	@override String get visualEffectsDescription => 'Velg animasjon og kunstverk effekter budsjett for denne enheten.';
	@override String get visualEffectsFullDescription => 'Bruk den fullstendige animasjons- og kunstverkseffekten på hver enhet.';
	@override String get startupSectionDescription => 'Velg hvilken del som åpner når PlezyNG starter.';
	@override late final _Translations$settings$startupSectionOptions$nb startupSectionOptions = _Translations$settings$startupSectionOptions$nb._(_root);
	@override String get smallSkipDurationDescription => 'Sett avstanden som flyttes av den korte bakover og fremfor søker kontroller.';
	@override String get largeSkipDurationDescription => 'Sett avstanden som flyttes av den lange bakover og fremfor søker kontroller.';
	@override String get rewindOnResumeDescription => 'Flytt playback tilbake med dette beløpet når du gjenoppretter en video.';
	@override String get defaultSleepTimerDescription => 'Sett den opprinnelige varigheten som brukes når du starter søvn timer.';
	@override String get playNextCountdownDescription => 'Vent dette lenge før du starter neste episode. Sett til 0 for å starte umiddelbart.';
	@override String get autoSkipDelaySettingDescription => 'Det gjelder når en intro, kreditter eller annonsen er satt til å skille automatisk.';
	@override String get downmixCenterBoostDescription => 'Øke dialogen i sentralkanalen når omgivende lyd blandes ned til stereo.';
	@override String get displaySwitchDelayDescription => 'Vennligst vent før du endrer skjermmodus slik at TV-en eller mottakeren kan fullføre sin tidligere skift.';
	@override String get playerBackendDescription => 'Velg hvilken spillmotor som dekoder og renderer video på denne enheten.';
	@override String get exoPlayerDescription => 'Bruk Androids innfødte Media3-baserte spiller og støttet maskinvareveier.';
	@override String get mpvDescription => 'Bruk mpv, som viser ytterligere playback, undertittel og videobehandling kontroller.';
	@override String get scopeOffDescription => 'Lagre endringer for den nåværende playback-sesjonen bare.';
	@override String get scopeGlobalDescription => 'Åpne samme verdi for hver bibliotek og tittel.';
	@override String get scopeLibraryDescription => 'Husk en separat verdi for hver bibliotek.';
	@override String get scopeTitleDescription => 'Husk en separat verdi for hver show eller film.';
	@override String get specialsOrderingServerDescription => 'Oppbevar episoden ordre levert av media serveren.';
	@override String get specialsOrderingAirDateDescription => 'Plasser spesialene blant vanlige episoder etter deres luftdato.';
	@override String get specialsOrderingLastDescription => 'Plasser hver spesiell etter de vanlige sesongene.';
	@override String get skipIntroModeDescription => 'Velg om intro markere spiller normalt, viser en skip-knappe eller skip automatisk.';
	@override String get skipCreditsModeDescription => 'Velg om kreditter spiller normalt, viser en skip-knappe eller skip automatisk.';
	@override String get skipAdsModeDescription => 'Velg om detekterte annonser spiller normalt, viser en skip-knappe eller skip automatisk.';
	@override String get playbackBufferAutoDescription => 'La den aktive spilleren velge sin normale buffer størrelse.';
	@override String get playbackBufferLargeDescription => 'Hold mer media klar før playback; dette bruker mer minne.';
	@override String get playbackBufferExtraLargeDescription => 'Hold den største les-ahead bufferen; dette bruker mest minne.';
	@override String get defaultQualityDescription => 'Sett standard videooppløsning og bitrate tak for strømmer som serveren transkoder.';
	@override String get cellularQualityDescription => 'Override standardkvalitet når enheten bruker en cellulær-only forbindelse.';
	@override String get remoteQualityDescription => 'Override Default Quality når du kobler til en server gjennom en fjerne tilkobling.';
	@override String get qualityPresetOriginalDescription => 'Spill kilden på tilgjengelig kvalitet uten å be serveren om å transkode den.';
	@override String get qualityPresetTranscodeOptionDescription => 'Be serveren om en konvertert strøm ved hjelp av oppløsningen og bitrate som vises ovenfor.';
	@override String get qualityPresetSameAsDefaultDescription => 'Bruk kvaliteten valgt i standardkvalitet.';
	@override String get musicQualityDescription => 'Sett den maksimale lydbitrate som kreves fra serveren; Original holder kildestrømmen.';
	@override String get musicQualityOriginalDescription => 'Spille kildekode uten en bitrate-kapped transcode.';
	@override String get musicQualityTranscodeOptionDescription => 'Be om en server transkode capped nær bitrate vist ovenfor; den virkelige utgangen kan variere.';
	@override String get maxVolumeInputLabel => 'Maksimalt volum (%)';
	@override String get checkForUpdatesDescription => 'Sjekk nå om en nyere versjon av PlezyNG er tilgjengelig.';
	@override String get appearanceDescription => 'Velg app-temaet og juster bibliotekskort, Hjem rader og navigasjon.';
	@override String get prerollLibraryDescription => 'Velg biblioteket som inneholder klippene tilgjengelig som film pre-rolls.';
	@override String get prerollSelectionDescription => 'Velg hvilke klipp fra det valgte biblioteket kan spilles før filmer.';
	@override String get contentScreensaverDelayOptionDescription => 'Vent dette mange minutter uten inngang før du viser skjermbeskyttelse kunstverk.';
	@override String get videoCodecOptionDescription => 'Tillat direkte spill for denne kodeksen når den støttes. Unchecked codecs transcodes av media serveren.';
}

// Path: themeEditor
class _Translations$themeEditor$nb extends Translations$themeEditor$en {
	_Translations$themeEditor$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get builtIn => 'Innebygde';
	@override String get presets => 'Forhåndsinnstillinger';
	@override String get custom => 'Egendefinert';
	@override String get customEmpty => 'Ikke opprettet ennå';
	@override String get editCustom => 'Rediger egendefinert tema';
	@override String get editCustomDescription => 'Velg alle fargene selv';
	@override String get locked => 'Livslang tilgang kreves';
	@override String get savedLocked => 'Sparet – tilgjengelig med livslang tilgang';
	@override String get title => 'Egendefinert tema';
	@override String get startFrom => 'Start fra';
	@override String get startFromDescription => 'Kopier alle fargene fra et annet tema';
	@override String get colors => 'Farger';
	@override String get preview => 'Forhåndsvisning';
	@override late final _Translations$themeEditor$slots$nb slots = _Translations$themeEditor$slots$nb._(_root);
	@override String get opacity => 'Opasitet';
	@override String get hexHint => '#RRGGBB eller #AARRGGBB';
	@override String get fromOtherThemes => 'Fra andre temaer';
	@override String swatchLabel({required Object color, required Object theme}) => '${color} (${theme})';
	@override late final _Translations$themeEditor$contrast$nb contrast = _Translations$themeEditor$contrast$nb._(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, under anbefalt minimum på ${minimum}:1';
	@override String get discardTitle => 'Forkaste endringene?';
	@override String get discardMessage => 'Ulagrede fargeendringer går tapt.';
	@override String get discard => 'Forkast';
	@override String previewCardTitle({required Object number}) => 'Episode ${number}';
	@override String previewCardSubtitle({required Object minutes}) => '${minutes} min igjen';
	@override String get previewSwitch => 'Autospill';
	@override String get previewMutedText => 'Sekundærtekst ser slik ut';
	@override String get themeSystemDescription => 'Følg utseendet på enheten og skift mellom lys og mørke automatisk.';
	@override String get themeLightDescription => 'Bruk en lys bakgrunn med mørk tekst.';
	@override String get themeDarkDescription => 'Bruk en mørk bakgrunn med lys tekst.';
	@override String get themeOledDescription => 'Bruk nærmeste svarte overflater som reduserer lys på OLED-skjermer.';
	@override String get themeEmberDescription => 'Bruk varme røde og amber accent farger.';
	@override String get themeGlacierDescription => 'Bruk kalde blå aksentfarger.';
	@override String get themeForestDescription => 'Bruk malt grønn og naturlig accent farger.';
	@override String get themePlumDescription => 'Bruk violett og plum accent farger.';
	@override String get themePaperDescription => 'Bruk varme papirlignende overflater og ink-inspirerte farger.';
	@override String get themeCustomDescription => 'Bruk fargepaletten du opprettet i den tilpassede tema editoren.';
	@override String get editorDescription => 'Velg en palettfarge, justere dens hue, mottakelse, lyshet eller opacity, og se forhåndsvisning oppdatering før du sparer.';
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
	@override String get people => 'Personer';
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
	@override String get flagDub => 'Dubbet';
	@override String get flagOriginal => 'Original';
	@override String get channelsMono => 'Mono';
	@override String dolbyVisionProfile({required Object profile}) => 'Profil ${profile}';
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
		one: 'Dette sletter ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episode i den, og filen.',
		other: 'Dette sletter alle ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodene i den, og filene deres.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: 'Dette elementet er lagret som ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} fil, som vil bli slettet.',
		other: 'Dette elementet er lagret på tvers av ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filer, og alle vil bli slettet.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} annen episode er lagret i samme fil og vil også bli slettet:',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} andre episoder er lagret i samme fil og vil også bli slettet:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'PlezyNG kunne ikke sjekke hvilke filer dette vil fjerne, så det kan slette mer enn elementet som er nevnt ovenfor. Avbryt og prøv igjen, eller slett likevel.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'Serveren din ga ikke fildetaljer for dette elementet, så PlezyNG kan ikke sjekke hvilke filer dette vil fjerne. Det kan slette mer enn elementet som er nevnt ovenfor.';
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
	@override String get autoScrollPlay => 'Start automatisk rulling';
	@override String get autoScrollPause => 'Sett automatisk rulling på pause';
	@override String get hueShort => 'H';
	@override String get saturationShort => 'S';
	@override String get valueShort => 'V';
	@override String get red => 'Rød';
	@override String get green => 'Grønn';
	@override String get blue => 'Blå';
	@override String get redShort => 'R';
	@override String get greenShort => 'G';
	@override String get blueShort => 'B';
	@override String get colorModeHsv => 'HSV';
	@override String get colorModeRgb => 'RGB';
	@override String get title => 'Tilgjengelighet';
	@override String get summary => 'Tekst, kontrast, bevegelse og kontroller';
	@override String get systemHint => 'Tilgjengelighetsinnstillingene for enheten din gjelder alltid. Disse alternativene legger til justeringer gjennom PlezyNG.';
	@override String get readability => 'Lesing og synlighet';
	@override String get textSize => 'Tilleggsvekst av tekst';
	@override String get preview => 'Finn din neste historie.Les, lytt og se på din egen hastighet.';
	@override String get boldText => 'Høyde Interface Text';
	@override String get highContrast => 'Høy kontrast';
	@override String get highContrastHint => 'Større tekst, utskrifter og fokusindikatorer på lys eller mørke overflater.';
	@override String get interaction => 'Motion og interaksjon';
	@override String get reduceMotion => 'Redusere bevegelse';
	@override String get reduceMotionHint => 'Stopp bevegelser i fokusmarkeringer, sideoverganger og dekorative effekter.';
	@override String get largeTargets => 'Større touch mål';
	@override String get largeTargetsHint => 'Gi delte kontroller mer plass for berøring og assistent navigasjon.';
	@override String get navigationHint => 'Bruk Tab og Shift+Tab for å flytte mellom kontroller, Enter eller mellomrom for å aktivere og Escape eller Tilbake for å lukke. Zoom og leseinnstillinger er tilgjengelige når en bok er åpen.';
	@override String get textSizeDescription => 'Skala grensesnitt tekst i PlezyNG i tillegg til enhetens system tekst-størrelse innstilling.';
	@override String get boldTextHint => 'Bruk en tyngre vekt for grensesnitt etiketter og meldinger for å gjøre dem enklere å skille mellom.';
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
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String get letterbox => 'Letterbox';
	@override String get fillScreen => 'Fyll skjerm';
	@override String get stretch => 'Strekk';
	@override String get lockRotation => 'Lås rotasjon';
	@override String get unlockRotation => 'Lås opp rotasjon';
	@override String get timerActive => 'Timer aktiv';
	@override String playbackWillPauseIn({required Object duration}) => 'Avspillingen settes på pause om ${duration}';
	@override String get sleepTimerEndOfVideo => 'Slutten av gjeldende video';
	@override String get sleepTimerStopAtHeader => 'Stopp ved';
	@override String get sleepTimerDurationHeader => 'Varighet';
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
	@override String get timelineSlider => 'Videotidslinje';
	@override String get volumeSlider => 'Volumnivå';
	@override String endsAt({required Object time}) => 'Slutter kl. ${time}';
	@override String get pipActive => 'Spiller i bilde-i-bilde';
	@override String get pipFailed => 'Bilde-i-bilde kunne ikke starte';
	@override String get screenshotSaved => 'Skjermbilde lagret';
	@override String get screenshotFailed => 'Kunne ikke ta skjermbilde';
	@override String zoomPercent({required Object percent}) => 'Zoom ${percent} %';
	@override String volumePercent({required Object percent}) => 'Volum ${percent} %';
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
	@override String get skipIntro => 'Hopp over intro';
	@override String get skipCredits => 'Hopp over rulletekst';
	@override String get nextEpisode => 'Neste episode';
	@override String subtitleTrack({required Object n}) => 'Spor ${n}';
	@override String subtitleFile({required Object name}) => 'Undertekst ${name}';
	@override String forcedTrack({required Object label}) => '${label} (tvunget)';
	@override String get osdSubtitlesOff => 'Undertekster: Av';
	@override String osdSubtitles({required Object track}) => 'Undertekster: ${track}';
	@override String osdAudio({required Object track}) => 'Lyd: ${track}';
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Frame',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} rammer',
	);
	@override String get trackSelectionTitle => 'Velg spor før playback';
	@override String get trackSelectionAuto => 'Automatisk utvalg';
	@override String get openMiniPlayer => 'Åpne mini-spillere';
	@override String get returnToFullPlayer => 'Tilbake til fullspiller';
	@override String get loadSubtitleFile => 'Last ned undertittelfil...';
	@override String get subtitleLoadFailed => 'Fikk ikke lastet opp subtitle-filen';
	@override String get skipAds => 'Hopp over reklame';
	@override String get tapToUnlock => 'Trykk for å låse opp';
	@override String get tapAgainToUnlock => 'Trykk igjen for å låse opp';
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
		one: 'Fjernet automatisk ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} avspilt nedlasting',
		other: 'Fjernet automatisk ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} avspilte nedlastinger',
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
	@override String playbackFailedDetail({required Object error}) => 'Kunne ikke starte avspillingen: ${error}';
	@override String get audioOutputFailed => 'Lydutgangen svarer ikke lenger. Sjekk lydtilkoblingen til TV-en eller mottakeren; hvis andre apper heller ikke har lyd, må du starte enheten på nytt.';
	@override String get mediaUnavailable => 'Dette innholdet er ikke lenger tilgjengelig.';
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
	@override String get serverBusyTitle => 'Strømmen er utilgjengelig';
	@override String get serverBusyBody => 'Serveren fortsatte å nekte å strømme denne filen (HTTP 503). Den kan være i ferd med å starte på nytt eller være opptatt, eller lagringsstedet til filen kan være frakoblet. Prøv igjen om litt – hvis det fortsetter å skje, kan du be eieren av serveren om å kontrollere serveren og lagringsstedet til filen.';
	@override String get playbackNotAllowedTitle => 'Avspilling er ikke tillatt';
	@override String get playbackNotAllowedBody => 'Serveren nektet å strømme dette elementet (HTTP 403). Kontoen din har kanskje ikke tillatelse til å spille det av, eller serveren tillater kanskje bare avspilling på sitt lokale nettverk.';
	@override String get logsUploaded => 'Logger lastet opp';
	@override String get logsUploadFailed => 'Kunne ikke laste opp logger';
	@override String get logId => 'Logg-ID';
	@override String get burnedSubtitlesUseMenu => 'Undertekstene er brent inn i denne strømmen. Endre dem fra undertekstmenyen.';
	@override String get noVideoUrl => 'Ingen video-URL er tilgjengelig';
	@override String get playbackNoMediaSources => 'Serveren returnerte ingen avspillbare mediekilder';
	@override String get playbackDataNotPrepared => 'Avspillingen ble startet før dataene var klare';
	@override String get streamSelectionUnavailable => 'Valg av strømmer er ikke tilgjengelig for denne kilden';
	@override String get streamSelectionFailed => 'Kunne ikke bruke de valgte strømmene';
	@override String get trackSelectionNotRemembered => 'Dette sporvalget gjelder bare for gjeldende avspilling.';
	@override String get serverUnavailableForProfile => 'Ingen server er tilgjengelig for den aktive profilen';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$nb extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get previewSample => 'Den raske brune fox hopper over den lazy hunden';
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
	@override String get useMargins => 'Bruk marger';
	@override String get useMarginsDescription => 'Tillat tekstundertekster i området utenfor videoen. Stilundertekster kan beholde sin opprinnelige plassering.';
	@override String get anchorToScreen => 'Forankre til skjermen';
	@override String get anchorToScreenDescription => 'Vis tekstundertekster i de svarte feltene under video i bredformat';
	@override String get bold => 'Fet';
	@override String get italic => 'Kursiv';
	@override String get renderResolution => 'Gjengivelsesoppløsning';
	@override String get renderResolutionScreen => 'Skjermoppløsning';
	@override String get renderResolutionVideo => 'Videooppløsning';
	@override String get fontSizeDescription => 'Sett tekststørrelsen på denne enheten.';
	@override String get textColorDescription => 'Velg fargen som brukes til undertekst.';
	@override String get borderSizeDescription => 'Sett tykkelsen av utlinjen rundt undertekst.';
	@override String get borderColorDescription => 'Velg fargen som brukes for undertittelutløpet.';
	@override String get backgroundColorDescription => 'Velg fargen bak undertekst.';
	@override String get backgroundOpacityDescription => 'Sett hvor åpen undertittel bakgrunnen er: 0% er klart og 100% er solid.';
	@override String get positionDescription => 'Beveg subtitlene vertikalt. 0% er toppen av videoen og 100% er bunnen.';
	@override String get assOverrideDescription => 'Velg om spilleren følger, justerer, erstattes eller fjerner styling innebygd i ASS-subtitler.';
	@override late final _Translations$subtitlingStyling$assOverrideOptions$nb assOverrideOptions = _Translations$subtitlingStyling$assOverrideOptions$nb._(_root);
	@override String get renderResolutionDescription => 'Velg oppløsningen som brukes til å rasterisere bilde og ASS-subtitler. Lavere Android-skalaer kan redusere renderingsarbeidet, men ser smalere ut.';
	@override late final _Translations$subtitlingStyling$renderResolutionOptions$nb renderResolutionOptions = _Translations$subtitlingStyling$renderResolutionOptions$nb._(_root);
	@override String get boldDescription => 'Skjær undertekst i en tyngre vekt.';
	@override String get italicDescription => 'Skriv ut undertekst i italiensk.';
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
	@override String get lineHint => 'option=value';
	@override String get addLine => 'Legg til linje';
	@override String get removeLine => 'Fjern linje';
	@override String get embeddedVoHint => 'vo, gpu-context og gpu-api ignoreres på Linux: innebygd video renderes alltid via vo=libmpv på videoplanet, og gpu-next (som compute-shadere som ArtCNN trenger) kan ikke kjøre innebygd.';
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
	@override String get addPlezyProfile => 'Legg til PlezyNG-profil';
	@override String get switchingProfile => 'Bytter profil…';
	@override String get deleteThisProfileTitle => 'Slett denne profilen?';
	@override String deleteThisProfileMessage({required Object displayName}) => 'Fjern ${displayName}. Tilkoblinger påvirkes ikke.';
	@override String get active => 'Aktiv';
	@override String get manage => 'Administrer';
	@override String get delete => 'Slett';
	@override String get signOut => 'Logg ut';
	@override String get signOutPlexTitle => 'Logge ut av Plex?';
	@override String signOutPlexMessage({required Object displayName}) => 'Fjerne ${displayName} og alle Plex Home-brukere? Du kan logge inn igjen når som helst.';
	@override String get signOutPlexDeleteDownloads => 'Slett også nedlastinger';
	@override String get signOutPlexDeleteDownloadsDescription => 'Ellers blir de liggende på denne enheten og kommer tilbake når du logger inn på denne kontoen igjen.';
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
	@override String get copyAutomationLink => 'Kopierer Android automatiseringslink';
	@override String get copyAutomationLinkDescription => 'Velg denne profilen fra en Android intensjon eller automatisering.';
	@override String get automationLinkCopied => 'Profil automatisering link kopieres.';
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
	@override String get borrowEmptySubtitle => 'Koble Plex, Jellyfin eller Emby til en annen profil først.';
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
	@override String get tokenIdentityMismatch => 'Plex-profiltokenet ble knyttet til en uventet server';
	@override String get settingsLocked => 'Innstillinger er låst for denne profilen.';
	@override String get unlockSettings => 'Unlock innstillinger';
	@override String get showExploreForProfile => 'Vis Utforsk for denne profilen';
	@override String get showExploreForProfileDescription => 'Avaktiver for å fjerne Explore fra denne profils navigasjon.';
}

// Path: connections
class _Translations$connections$nb extends Translations$connections$en {
	_Translations$connections$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Tilkoblinger';
	@override String get addConnection => 'Legg til tilkobling';
	@override String get addConnectionSubtitleNoProfile => 'Logg inn med Plex eller koble til en Jellyfin- eller Emby-server';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Legg til for ${displayName}: Plex, Jellyfin, Emby eller en annen profiltilkobling';
	@override String sessionExpiredOne({required Object name}) => 'Økten er utløpt for ${name}';
	@override String sessionExpiredMany({required Object count}) => 'Økten er utløpt for ${count} servere';
	@override String accessDeniedOne({required Object name}) => '${name} nektet tilgang for denne kontoen';
	@override String accessDeniedMany({required Object count}) => '${count} servere nektet tilgang for denne kontoen';
	@override String get signInAgain => 'Logg inn igjen';
	@override String editMediaBrowserTitle({required Object product}) => 'Rediger ${product}-tilkobling';
	@override String editMediaBrowserIntro({required Object serverName}) => 'Legg til eller fjern URL-er for ${serverName}. PlezyNG vil bruke den nåbare URL-en med lavest ventetid.';
}

// Path: accountPreferences
class _Translations$accountPreferences$nb extends Translations$accountPreferences$en {
	_Translations$accountPreferences$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Kontoinnstillinger';
	@override String hubSubtitleSingle({required Object account}) => 'Lyd-, undertekst- og bibliotekalternativer lagret på ${account}';
	@override String hubSubtitleMultiple({required Object count}) => 'Lyd-, undertekst- og bibliotekalternativer lagret på ${count} kontoer';
	@override String get pickAccount => 'Hver konto lagrer sine egne innstillinger. Velg hvilken du vil redigere.';
	@override String get storedOnAccount => 'Disse alternativene lagres på selve kontoen, så alle apper som er logget på den, bruker dem — inkludert PlezyNG på de andre enhetene dine.';
	@override String get noAccounts => 'Ingen kontoer å konfigurere';
	@override String get noAccountsHint => 'Logg inn på Plex, eller koble til en Jellyfin- eller Emby-server, så vises innstillingene som er lagret på den kontoen, her.';
	@override String get unavailable => 'Kan ikke nå denne kontoen';
	@override String get loadFailed => 'Kunne ikke laste inn disse innstillingene';
	@override String get noPreference => 'Ingen preferanse';
	@override String get notSet => 'Ikke angitt';
	@override late final _Translations$accountPreferences$groups$nb groups = _Translations$accountPreferences$groups$nb._(_root);
	@override String get preferredAudioLanguage => 'Foretrukket lydspråk';
	@override String get autoSelectAudio => 'Velg lyd etter språk';
	@override String get autoSelectAudioDescription => 'Av beholder det lydsporet filen markerer som standard.';
	@override String get preferredSubtitleLanguage => 'Foretrukket undertekstspråk';
	@override String get subtitleMode => 'Slå på undertekster';
	@override late final _Translations$accountPreferences$subtitleModes$nb subtitleModes = _Translations$accountPreferences$subtitleModes$nb._(_root);
	@override String get subtitleAccessibility => 'SDH-undertekster';
	@override late final _Translations$accountPreferences$subtitleAccessibilityOptions$nb subtitleAccessibilityOptions = _Translations$accountPreferences$subtitleAccessibilityOptions$nb._(_root);
	@override String get forcedSubtitles => 'Tvungne undertekster';
	@override late final _Translations$accountPreferences$forcedSubtitleOptions$nb forcedSubtitleOptions = _Translations$accountPreferences$forcedSubtitleOptions$nb._(_root);
	@override String get displayMissingEpisodes => 'Vis manglende episoder';
	@override String get displayMissingEpisodesDescription => 'Vis episoder serveren kjenner til, men som ikke har noen fil.';
	@override String get hidePlayedInLatest => 'Skjul sette elementer i Siste';
	@override String get hidePlayedInLatestDescription => 'Hold elementer du allerede har sett utenfor serverens Siste-rader.';
	@override String get displayCollectionsView => 'Vis samlingsvisningen';
	@override String get displayCollectionsViewDescription => 'Vis serverens samlingsvisning sammen med bibliotekene dine.';
	@override String get rewatchingInNextUp => 'Behold serier du ser på nytt i Neste opp';
	@override String get rewatchingInNextUpDescription => 'Når du er ferdig med en serie og starter den på nytt, følger Neste opp den nye avspillingen i stedet for å fjerne serien.';
	@override String get watchedIndicator => 'Sett-indikatorer';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$nb watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$nb._(_root);
	@override String get mediaReviewsVisibility => 'Vurderinger og anmeldelser';
	@override late final _Translations$accountPreferences$mediaReviewsOptions$nb mediaReviewsOptions = _Translations$accountPreferences$mediaReviewsOptions$nb._(_root);
	@override String get preferredAudioLanguageDescription => 'Foretrakk lydspor på dette språket når serveren eller spilleren velger en spor automatisk.';
	@override String get preferredSubtitleLanguageDescription => 'Foretrukker undertitler sporer i dette språket når undertitlene er valgt automatisk.';
	@override String get subtitleAccessibilityDescription => 'Velg om SDH-kapsjoner er foretrukket eller kreves under automatisk undertittelutvalg.';
	@override String get forcedSubtitleDescription => 'Velg om tvunget undertittelspor er foretrukket eller nødvendig i løpet av automatisk utvalg.';
	@override String get watchedIndicatorDescription => 'Velg hvilke medietyper som mottar et sett sjekkmerke i servergrensesnittet.';
	@override String get mediaReviewsVisibilityDescription => 'Velg hvilken publikum og kritiske vurderinger serveren viser på media sider.';
	@override String get subtitleModeDescription => 'Velg når undertitlene åpnes automatisk for denne serverkontoen.';
	@override String get hubDescription => 'Disse preferansene lagres på media-serverkontoen din og kan også gjelde for andre kunder.';
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
	@override late final _Translations$discover$findNext$nb findNext = _Translations$discover$findNext$nb._(_root);
	@override String get extras => 'Trailere og ekstramateriale';
	@override String get studio => 'Studio';
	@override String get rating => 'Vurdering';
	@override String get director => 'Regissør';
	@override String get directors => 'Regissører';
	@override String get movie => 'Film';
	@override String get tvShow => 'TV-serie';
	@override String minutesLeft({required Object minutes}) => '${minutes} min igjen';
	@override String get moreLikeThis => 'Mer som dette';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tittel',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} titler',
	);
	@override late final _Translations$discover$person$nb person = _Translations$discover$person$nb._(_root);
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
	@override String get reasonTimedOut => 'tidsavbrudd på tilkoblingen';
	@override String get reasonUnreachable => 'medieserveren kunne ikke nås';
	@override String get reasonRefused => 'medieserveren avviste forespørselen';
	@override String get reasonNotFound => 'elementet finnes ikke lenger på medieserveren';
	@override String get reasonServerError => 'medieserveren rapporterte en feil';
	@override String get reasonCancelled => 'forespørselen ble avbrutt';
	@override String get reasonUnexpected => 'det oppsto en uventet feil';
}

// Path: libraries
class _Translations$libraries$nb extends Translations$libraries$en {
	_Translations$libraries$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => 'Spill en tilfeldig film';
	@override String get randomPickFailed => 'Kan ikke velge en tilfeldig film fra denne biblioteket.';
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
	@override late final _Translations$libraries$advancedFilters$nb advancedFilters = _Translations$libraries$advancedFilters$nb._(_root);
	@override late final _Translations$libraries$selection$nb selection = _Translations$libraries$selection$nb._(_root);
}

// Path: about
class _Translations$about$nb extends Translations$about$en {
	_Translations$about$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Om';
	@override String get openSourceLicenses => 'Lisenser for åpen kildekode';
	@override String versionLabel({required Object version}) => 'Versjon ${version}';
	@override String get appDescription => 'En vakker Plex-, Jellyfin- og Emby-klient for Flutter';
	@override String get viewLicensesDescription => 'Vis lisenser for tredjepartsbiblioteker';
	@override String get privacyPolicy => 'Personvernerklæring';
}

// Path: serverSelection
class _Translations$serverSelection$nb extends Translations$serverSelection$en {
	_Translations$serverSelection$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Ingen servere funnet for ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Kunne ikke laste servere: ${error}';
	@override String get noValidServers => 'Fant ingen brukbare servere på denne kontoen';
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
	@override String get saveLogs => 'Lagre logger til filer';
	@override String logsSaved({required Object path}) => 'Lister lagret til ${path}';
	@override String get saveLogsFailed => 'Kan ikke lagre loggfilet.';
}

// Path: startup
class _Translations$startup$nb extends Translations$startup$en {
	_Translations$startup$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'PlezyNG kunne ikke starte';
	@override String get failedBody => 'Noe gikk galt under oppstart. Detaljene nedenfor viser hva som feilet.';
	@override String get failedBodyRepairable => 'PlezyNG\'s lagrede innstillingsfil er skadet og må bygges på nytt før PlezyNG kan starte. Å prøve igjen hjelper ikke – velg Reparer lagring.';
	@override String get phaseLabel => 'Trinn';
	@override String get showDetails => 'Vis detaljer';
	@override String get hideDetails => 'Skjul detaljer';
	@override String get copyDetails => 'Kopier detaljer';
	@override String get detailsCopied => 'Detaljer kopiert til utklippstavlen';
	@override String get uploadDetails => 'Last opp detaljer';
	@override String get repairStorage => 'Reparer lagring';
	@override String get repairTitle => 'Reparere lagrede data?';
	@override String get repairBodyCommon => 'PlezyNG\'s innstillingsfil er skadet og kan ikke leses. Reparasjon tilbakestiller alle innstillinger til standard.';
	@override String get repairBodyOneCredential => 'Én lagret pålogging er skadet og kan ikke leses. Reparasjon fjerner bare den; de andre innstillingene dine blir urørt.';
	@override String get repairBodySignInsKept => 'Serverne og profilene dine skal forbli pålogget.';
	@override String get repairBodySignInsLost => 'Nøkkelen som beskytter de lagrede påloggingene dine kan ikke gjenvinnes fra denne filen, så du må logge på alle servere og profiler på nytt. Ingenting på medieserveren din påvirkes.';
	@override String get repairBodySessionsUncertain => 'Trackere (MAL, AniList, Simkl, Trakt) og Seerr lagres separat og kan overleve eller ikke. PlezyNG vil fortelle deg nøyaktig hva det beholdt.';
	@override String get repairConfirm => 'Reparer';
	@override String get repairSucceeded => 'Lagring reparert';
	@override String get repairNeedsRestart => 'Lagring reparert – omstart kreves';
	@override String get restartRequiredBody => 'Dataene dine ble reparert, men PlezyNG må starte på nytt før det kan bruke dem. Lukk PlezyNG og åpne det igjen.';
	@override String get quitPlezy => 'Avslutt PlezyNG';
	@override String get repairFailed => 'Reparasjon mislyktes';
	@override String get repairKeptSignIns => 'Serverne og profilene dine er fortsatt pålogget.';
	@override String get repairLostSignIns => 'Nøkkelen som beskytter de lagrede påloggingene dine kunne ikke gjenvinnes. Du må logge på alle servere og profiler på nytt.';
	@override String get repairLostSessions => 'Minst én tracker- eller Seerr-tilkobling gikk tapt og må kobles til på nytt.';
	@override String get backupTitle => 'En kopi av den skadede filen ble beholdt';
	@override String get backupWarning => 'Den inneholder påloggingsinformasjonen din. Ikke last den opp eller del den.';
	@override String get deleteBackup => 'Slett kopi';
	@override String get backupDeleted => 'Kopi slettet.';
	@override String get previousFailureTitle => 'PlezyNG mislyktes i å starte forrige gang';
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
	@override late final _Translations$explore$mdblistShelves$nb mdblistShelves = _Translations$explore$mdblistShelves$nb._(_root);
	@override String get title => 'Utforsk';
	@override String get selectSource => 'Velg kilde';
	@override late final _Translations$explore$rows$nb rows = _Translations$explore$rows$nb._(_root);
	@override late final _Translations$explore$status$nb status = _Translations$explore$status$nb._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episode',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episoder',
	);
	@override String get cast => 'Skuespillere';
	@override String get characters => 'Figurer';
	@override String get addToWatchlist => 'Legg til i ønskeliste';
	@override String get removeFromWatchlist => 'Fjern fra ønskeliste';
	@override String get addedToWatchlist => 'Lagt til i overvåkningslisten';
	@override String get removedFromWatchlist => 'Fjernet fra overvåkningslisten';
	@override String get watchlistUpdateFailed => 'Kunne ikke oppdatere ønskelisten';
	@override String get watchlistNoMatch => 'Kunne ikke koble dette elementet til en overvåkningsliste';
	@override String get notInLibrary => 'Ikke i biblioteket ditt';
	@override String get inTheseLibraries => 'I disse bibliotekene';
	@override String get checkingLibrary => 'Sjekker biblioteket ditt...';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: 'Kunne ikke sjekke ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} server',
		other: 'Kunne ikke sjekke ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} servere',
	);
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
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} resultat',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} resultater',
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
	@override String get timelineLiveProgram => 'Live program (playback kan være utenfor dette programmet)';
	@override String get timelineBuffer => 'Buffertidslinje';
	@override String get timelineUnavailable => 'Tidslinje utilgjengelig';
	@override String get timelineEstimated => 'Bedre spillback';
	@override String get timelinePending => 'Løp etter';
	@override String get timelineStale => 'Planen kan være fortidig';
	@override String get unknownHub => 'Ukjent';
	@override String get unknownError => 'Ukjent feil';
	@override String channelNumber({required Object number}) => 'Kanal ${number}';
	@override String get unknownChannel => 'Ukjent kanal';
	@override String get live => 'DIREKTE';
	@override String get premiereBadge => 'Nytt';
	@override String get reloadGuide => 'Last inn programguide på nytt';
	@override String get searchGuide => 'Søk i programguiden';
	@override String get searchHint => 'Søk etter kanaler og programmer';
	@override String searchNoResults({required Object query}) => 'Ingen treff for "${query}"';
	@override String get channelsSection => 'Kanaler';
	@override String get programsSection => 'Programmer';
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
	@override String get noFavoriteChannels => 'Ingen favorittkanaler';
	@override String get noFavoriteChannelsHint => 'Vis alle kanaler, og trykk deretter lenge på en kanal for å legge den til i favorittene dine.';
	@override String get showAllChannels => 'Vis alle kanaler';
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
	@override String get guideReloadFailed => 'Kunne ikke oppdatere programguiden';
	@override String get rulesProcessRequested => 'Ny vurdering av reglene er forespurt';
	@override String get rulesProcessFailed => 'Kunne ikke kjøre opptaksreglene på nytt';
	@override String get recordShow => 'Ta opp program';
	@override late final _Translations$liveTv$recordSettings$nb recordSettings = _Translations$liveTv$recordSettings$nb._(_root);
	@override String startingInMinutes({required Object minutes}) => 'Starter om ${minutes} min';
	@override String dayAtTime({required Object day, required Object time}) => '${day} kl. ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} returnerte ugyldige avspillingsdata for direkte-TV';
	@override String get failedToStartChannel => 'Kunne ikke starte direktekanalen';
	@override String get failedToBuildStreamUrl => 'Kunne ikke opprette strømme-URL-en';
	@override String playbackStartFailed({required Object reason}) => 'Kunne ikke starte kanalen: ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'Kunne ikke bytte kanal: ${reason}';
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
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} element',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} elementer',
	);
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
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} spor',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} spor',
	);
	@override String get nowPlaying => 'Spilles nå';
	@override String playingFrom({required Object title}) => 'Spiller fra ${title}';
	@override String get queue => 'Kø';
	@override String get clearQueue => 'Tøm kø';
	@override String get lyrics => 'Sangtekst';
	@override String get visualizer => 'Visualiser';
	@override String get visualizerProfileLoading => 'Lesing av track analyse.';
	@override String get visualizerAmbientMotion => 'Miljøbevegelse';
	@override String get visualizerPlexLoudness => 'Plex støy';
	@override String get visualizerPreviousPreset => 'Tidligere visuell stil';
	@override String get visualizerNextPreset => 'Neste visuell stil';
	@override String get visualizerPresetAurora => 'Aurora';
	@override String get visualizerPresetBloom => 'Blomst';
	@override String get visualizerPresetOrbitals => 'Orbitale';
	@override String get visualizerPresetPrism => 'Prism';
	@override String get visualizerPresetTunnel => 'Tunnel';
	@override String get visualizerPresetTrackMap => 'Track kart';
	@override String get noLyrics => 'Ingen sangtekst tilgjengelig';
	@override String get sleepTimer => 'Innsovningstimer';
	@override String get sleepTimerEndOfTrack => 'Slutten av sporet';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutt',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutter',
	);
	@override String get stopPlayback => 'Stopp avspilling';
	@override String get previousTrack => 'Forrige spor';
	@override String get nextTrack => 'Neste spor';
	@override String get repeat => 'Gjenta';
	@override String get repeatAll => 'Gjenta alle';
	@override String get repeatOne => 'Gjenta ett spor';
	@override String get instantMixNoServer => 'Ingen server er tilgjengelig for en hurtigmiks';
	@override String get instantMixFailed => 'Kunne ikke laste inn direktemiksen';
	@override String get instantMixEmpty => 'Direktemiksen ga ingen spor';
	@override String noAudioUrl({required Object track}) => 'Ingen lyd-URL er tilgjengelig for ${track}';
	@override late final _Translations$music$discography$nb discography = _Translations$music$discography$nb._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$nb extends Translations$watchTogether$en {
	_Translations$watchTogether$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Se sammen';
	@override String get description => 'Se innhold synkronisert med venner og familie';
	@override String get createRoom => 'Opprett rom';
	@override String get creatingRoom => 'Oppretter rom...';
	@override String get joinRoom => 'Bli med i rom';
	@override String get joiningRoom => 'Blir med i rom...';
	@override String get connecting => 'Kobler til...';
	@override String get relayPublic => 'Rom bruker de offentlige Open Watch Party-reléserverne.';
	@override String relayCustom({required Object url}) => 'Rom bruker reléserveren din på ${url}.';
	@override String get recentRooms => 'Nylige rom';
	@override String get roomActions => 'Romhandlinger';
	@override String get renameRoom => 'Gi nytt navn til rom';
	@override String get removeRoom => 'Fjern';
	@override String get enterRoomCode => 'Skriv inn koden på 6 tegn fra verten.';
	@override String get roomCode => 'Romkode';
	@override String get paste => 'Lim inn';
	@override String get noCodeInClipboard => 'Utklippstavlen inneholder ingen romkode';
	@override String get copyCode => 'Kopier kode';
	@override String get codeCopied => 'Romkode kopiert';
	@override String get shareInvite => 'Del invitasjon';
	@override String get inviteCopied => 'Invitasjon kopiert. Lim den inn i en melding.';
	@override String inviteMessage({required Object code}) => 'Bli med i Se sammen-rommet mitt i PlezyNG: åpne Se sammen, velg «Bli med i rom» og skriv inn ${code}.';
	@override String get openSessionControls => 'Åpne øktkontroller for Se sammen';
	@override String get reconnecting => 'Kobler til på nytt...';
	@override String get reconnectingDescription => 'Tilkoblingen ble brutt. Du blir automatisk med i rommet igjen.';
	@override String get connected => 'Tilkoblet';
	@override String get disconnected => 'Frakoblet';
	@override String get youAreHost => 'Du er verten';
	@override String hostedBy({required Object name}) => 'Vert: ${name}';
	@override String get hostControlsPlayback => 'Verten kontrollerer avspilling';
	@override String get anyoneCanControl => 'Alle kan kontrollere avspilling';
	@override String get roomLocked => 'Rommet er låst';
	@override String get nowPlaying => 'Spilles nå';
	@override String get nothingPlaying => 'Ingenting spilles';
	@override String get nothingPlayingHost => 'Spill av noe fra et hvilket som helst bibliotek for å dele det med rommet.';
	@override String get nothingPlayingGuest => 'Når verten spiller av noe, åpnes det her.';
	@override String get notShareable => 'Denne videoen har ingen treff i katalogen, så bare de med tilgang til samme server kan spille den av.';
	@override String get searching => 'Ser etter denne videoen i bibliotekene dine...';
	@override String get yourCopy => 'Din kopi';
	@override String get sharingYourCopy => 'Du deler din kopi';
	@override String playingOtherLength({required Object difference}) => 'Spiller av din kopi, ${difference}';
	@override String get mismatchTitle => 'Kopien din har en annen lengde';
	@override String mismatchDescription({required Object difference}) => 'Den nærmeste kopien din er ${difference} enn videoen i rommet. Det kan være en annen klipping eller versjon.';
	@override String get playAnyway => 'Spill av likevel';
	@override String get chooseAnotherCopy => 'Velg en annen kopi';
	@override String get dontPlay => 'Ikke spill av';
	@override String get unavailableTitle => 'Du har ikke denne videoen';
	@override String get unavailableDescription => 'PlezyNG fant den ikke i bibliotekene dine. Velg en kopi selv eller søk på nytt.';
	@override String get chooseCopy => 'Velg en kopi';
	@override String get searchAgain => 'Søk på nytt';
	@override String get noCandidates => 'Fant ingen kopier i bibliotekene dine.';
	@override String get choiceFailed => 'Kunne ikke spille av denne kopien for rommet';
	@override String lengthLonger({required Object duration}) => '${duration} lengre';
	@override String lengthShorter({required Object duration}) => '${duration} kortere';
	@override String get lengthSame => 'Samme lengde';
	@override String get lengthUnknown => 'Ukjent lengde';
	@override String get joinCurrentPlayback => 'Bli med i gjeldende avspilling';
	@override String get joinCurrentPlaybackDescription => 'Hopp tilbake til det verten ser på nå';
	@override String get stopMedia => 'Stopp videoen for alle';
	@override String get syncOffset => 'Tidsforskyvning';
	@override String get syncOffsetDescription => 'Forskyv videoen din hvis den ligger foran eller bak rommet.';
	@override String offsetHint({required Object difference}) => 'Kopien din er ${difference} enn videoen i rommet.';
	@override String applyDifference({required Object offset}) => 'Bruk ${offset}';
	@override String get offsetMinusSecond => '-1 s';
	@override String get offsetMinusTenth => '-100 ms';
	@override String get offsetPlusTenth => '+100 ms';
	@override String get offsetPlusSecond => '+1 s';
	@override String get participants => 'Deltakere';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} deltaker',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} deltakere',
	);
	@override String get hostBadge => 'VERT';
	@override String nameYou({required Object name}) => '${name} (deg)';
	@override String get playerIdle => 'Inaktiv';
	@override String get playerLoading => 'Laster';
	@override String get playerReady => 'Klar';
	@override String get playerBuffering => 'Bufrer';
	@override String get matchSearching => 'Søker';
	@override String get matchMatched => 'Har videoen';
	@override String get matchMismatched => 'Annen lengde';
	@override String get matchUnavailable => 'Har ikke videoen';
	@override String participantOffset({required Object offset}) => 'Forskyvning ${offset}';
	@override String get makeHost => 'Gjør til vert';
	@override String get makeHostQuestion => 'Overfør vert?';
	@override String makeHostConfirm({required Object name}) => '${name} vil kontrollere avspillingen og styre økten for alle.';
	@override String get transfer => 'Overfør';
	@override String get removeParticipant => 'Fjern fra rommet';
	@override String removeParticipantQuestion({required Object name}) => 'Fjerne ${name}?';
	@override String removeParticipantConfirm({required Object name}) => '${name} fjernes fra rommet, men kan bli med igjen med koden med mindre du låser rommet.';
	@override String get remove => 'Fjern';
	@override String get roomSettings => 'Rominnstillinger';
	@override String get letEveryoneControl => 'La alle kontrollere avspillingen';
	@override String get lockRoom => 'Lås rommet';
	@override String get lockRoomDescription => 'Ingen nye kan bli med';
	@override String get leaveRoom => 'Forlat rommet';
	@override String get leaveRoomQuestion => 'Forlate rommet?';
	@override String get leaveRoomConfirm => 'Du kan bli med igjen med romkoden.';
	@override String get leave => 'Forlat';
	@override String get endRoom => 'Avslutt rommet';
	@override String get endRoomQuestion => 'Avslutte rommet?';
	@override String get endRoomConfirm => 'Dette avslutter rommet for alle.';
	@override String get end => 'Avslutt';
	@override String get playBlockedTitle => 'Avspillingen startet ikke';
	@override String get playBlockedDescription => 'Trykk på spill av for å begynne å se sammen med rommet.';
	@override late final _Translations$watchTogether$notices$nb notices = _Translations$watchTogether$notices$nb._(_root);
	@override late final _Translations$watchTogether$ended$nb ended = _Translations$watchTogether$ended$nb._(_root);
	@override late final _Translations$watchTogether$errors$nb errors = _Translations$watchTogether$errors$nb._(_root);
	@override String untitledEpisode({required Object number}) => 'Episode ${number}';
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
	@override String get storageFull => 'Nedlastingene ble stoppet for å beskytte ledig lagringsplass. Frigjør plass eller velg en annen nedlastingsplassering, og prøv igjen.';
	@override String get storageUnavailable => 'Nedlastingene ble stoppet fordi tilgjengelig lagringsplass ikke kunne sjekkes. Sjekk nedlastingsstedet, og prøv igjen.';
	@override String episodesQueued({required Object count}) => '${count} episoder i nedlastingskø';
	@override String get downloadDeleted => 'Nedlasting slettet';
	@override String deleteConfirm({required Object title}) => 'Slette "${title}" fra denne enheten?';
	@override String get deleteCollectionDownloads => 'Slett nedlastinger';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => 'Slette alle nedlastinger i «${title}» fra denne enheten?';
	@override String get collectionDownloadsDeleted => 'Nedlastinger slettet';
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
	@override String get retryAll => 'Prøv alle på nytt';
	@override String get retryFailed => 'Prøv mislykkede nedlastinger på nytt';
	@override String get deleteAll => 'Slett alle';
	@override String get selectVersion => 'Velg versjon';
	@override String get allEpisodes => 'Alle episoder';
	@override String get unwatchedOnly => 'Kun usette';
	@override String nextNUnwatched({required Object count}) => 'Neste ${count} usette';
	@override String get customAmount => 'Egendefinert antall...';
	@override String get customAmountAny => 'Tilpasset beløp ( hvert år)';
	@override String get randomEpisodes => 'Random episoder';
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
	@override String get syncNow => 'Synkronisering nå';
	@override String get downloadsUpToDate => 'Nedlastinger er oppdatert';
	@override String syncComplete({required Object queued, required Object removed}) => 'Synk full · ${queued} queued, ${removed} fjernet';
	@override String get activeSyncRules => 'Synkroniseringsregler';
	@override String get reviewOrphanFiles => 'Se over foreldreløse nedlastinger';
	@override String get orphanReviewTitle => 'Se over foreldreløse nedlastinger';
	@override String get orphanReviewDescription => 'Disse merkede filene ligger i PlezyNGs standardmapper for appstyrte nedlastinger, men har ingen tilsvarende nedlastingsoppføring eller aktiv oppgave. Kontroller listen før du sletter dem.';
	@override String orphanReviewCount({required Object count, required Object size}) => '${count} filer · ${size}';
	@override String orphanDeleteFiles({required Object count}) => 'Slett ${count} filer';
	@override String get orphanCleanupNone => 'Fant ingen foreldreløse nedlastingsfiler';
	@override String get orphanCleanupFailed => 'PlezyNG kunne ikke skanne den administrerte nedlastingsmappen på en trygg måte. Ingen filer ble slettet.';
	@override String get orphanCleanupChanged => 'Nedlastingslisten ble endret mens du gikk gjennom den. Se over filene på nytt før du rydder opp.';
	@override String orphanCleanupComplete({required Object count, required Object size}) => 'Slettet ${count} foreldreløse filer · ${size} frigjort';
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
	@override String get syncRuleAccessDenied => 'Tilgang nektet';
	@override String get syncRuleNotAvailableForProfile => 'Ikke tilgjengelig for gjeldende profil';
	@override String get syncRuleUnknownServer => 'Ukjent server';
	@override String get syncRuleListCreated => 'Synkroniseringsregel opprettet';
	@override late final _Translations$downloads$backgroundWarning$nb backgroundWarning = _Translations$downloads$backgroundWarning$nb._(_root);
	@override String get options => 'Valg for nedlastinger';
	@override late final _Translations$downloads$groupings$nb groupings = _Translations$downloads$groupings$nb._(_root);
	@override String get unknownLibrary => 'Ukjent bibliotek';
	@override String get unknownShow => 'Ukjent serie';
	@override String get unknownSeason => 'Ukjent sesong';
	@override String get unknownAlbum => 'Ukjent album';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} fullført';
	@override String storageUsed({required Object size}) => 'Brukte lagringsplasser: ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} nedlasting',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} nedlastinger',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} viser',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} viser',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} film',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmer',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} album',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} album',
	);
	@override String get errorFileNotFound => 'Filen ble ikke funnet (404)';
	@override String get errorDownloadNotAllowed => 'Serveren tillater ikke nedlasting (403)';
	@override String get errorDownloadFailed => 'Nedlastingen mislyktes';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'Nedlastingen mislyktes: ${reason}';
	@override String get convertingOnServer => 'Konvertering på server';
	@override String convertingOnServerPercent({required Object percent}) => 'Konverteringer på server · ${percent}%';
	@override String errorHttpStatus({required Object status}) => 'Nedlastingen mislyktes (HTTP ${status})';
	@override String errorPostProcessing({required Object reason}) => 'Etterbehandlingen mislyktes: ${reason}';
	@override String get reasonFileNotSaved => 'filen kunne ikke lagres på denne enheten';
	@override String get reasonCannotResume => 'den delvise nedlastingen kunne ikke gjenopptas';
	@override String get reasonDeviceStorageFull => 'denne enheten er tom for lagringsplass';
	@override String get notificationDownloading => 'Laster ned...';
	@override String get notificationComplete => 'Nedlastingen er fullført';
	@override String get notificationPaused => 'Nedlastingen er satt på pause';
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
	@override String get closedBeforeAuth => 'Tilkoblingen ble lukket før autentisering';
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
	@override String get hdrUnsupported => 'HDR er ikke tilgjengelig her – denne skrivebordskompositoren eller videoutgangen kan ikke overføre HDR.';
	@override String get hdrToneMapping => 'HDR-tonekartlegging';
	@override String get hdrToneMappingCompositor => 'Kompositor';
	@override String get hdrToneMappingCompositorDescription => 'Send kildens HDR-metadata videre, og la skrivebordskompositoren utføre tonekartleggingen.';
	@override String get hdrToneMappingPlayer => 'Spiller';
	@override String get hdrToneMappingPlayerDescription => 'Tilpass til skjermens maksimale lysstyrke i spilleren, og send deretter resultatet til kompositoren.';
	@override String get hdrToneMappingFailed => 'Kunne ikke endre HDR-tonekartleggingen – den forrige modusen er fortsatt aktiv.';
	@override String get audioOutput => 'Lydutgang';
	@override String get performanceOverlay => 'Ytelsesoverlegg';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'Surround';
	@override String get audioOutputSpatial => 'Romlig lyd';
	@override String get audioOutputStereo => 'Stereo';
	@override String get audioEqualizer => 'Lydequalizer';
	@override String get audioEqualizerDescription => 'Tilpass fem frekvensbånd for denne enheten. tilgjengelig på mpv; en aktiv EQ dekoder lyd og avbryter matchhrough.';
	@override String get audioEqualizerFlat => 'Nøytral';
	@override String get audioEqualizerActive => 'Egendefinert';
	@override String get audioEqualizerSaveFailed => 'Kan ikke lagre lydekvaliser innstillinger.';
	@override String get backgroundVideoAudio => 'Video bakgrunnsvideo';
	@override String get backgroundVideoAudioDescription => 'Hold video-audio-spillingen når du forlater spilleren; bildet er skjult til du vender tilbake. Android bruker en media-spillingsanmeldelse.';
	@override String get audioNormalization => 'Normaliser lydstyrke';
	@override String get audioNormalizationDisablesPassthrough => 'Dekoder lyd til PCM; direkte lydutgang er av mens dette er på';
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
	@override String get passthrough => 'Direkte utgang';
	@override String get aspect => 'Format';
	@override String get rotation => 'Rotasjon';
	@override String get dvSource => 'DV-kilde';
	@override String get dvPath => 'DV-sti';
	@override String get dvRouteDecoder => 'Dolby Vision-dekoder';
	@override String get dvRouteDecoderP81 => 'Dolby Vision-dekoder (P7→8.1)';
	@override String get dvRouteBaseLayer => 'Basislag';
	@override String get dvRouteBaseLayerHdr10 => 'HDR10-basislag';
	@override String get dvRouteBaseLayerHlg => 'HLG-basislag';
	@override String get dvRouteBaseLayerSdr => 'SDR-basislag';
	@override String get dvRouteReshaped => 'RPU-omformet (gpu-next)';
	@override String get dvRouteFelGraphActive => 'Eksperimentell P7 FEL-grafikk (unkvalifisert)';
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
	@override String get playMethod => 'Spill Metode';
	@override String get memory => 'Minne';
	@override String get uiFps => 'UI FPS';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Android-maskinvare';
	@override String get decoderNvidiaHw => 'NVIDIA-maskinvare';
	@override String get decoderQualcommHw => 'Qualcomm-maskinvare';
	@override String get decoderMediatekHw => 'MediaTek-maskinvare';
	@override String get decoderExynosHw => 'Exynos-maskinvare';
	@override String get decoderSoftware => 'Programvare';
	@override String get decoderHardware => 'Maskinvare';
	@override String get tunnelingActive => 'Aktiv';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted} (${failures} mislyktes)';
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
	@override String get description => 'Velg en annen app for å åpne videoer i. Tilgjengelige spillere avhenger av din enhet og installerte apper.';
	@override String get systemDefaultDescription => 'La operativsystemet åpne videoen med sin standardapp.';
	@override String playerOptionDescription({required Object player}) => 'Åpne videoer med ${player}.';
	@override String get playerNameDescription => 'Etiketten som vises i spillelisten.';
	@override String get playerPackageDescription => 'Skriv inn Android-pakkenavnet på spilleren app, for eksempel com.example.player.';
	@override String get playerCommandDescription => 'Skriv inn den installerte spillerkommandoen eller utførbar rute for denne enheten.';
	@override String get playerUrlSchemeDescription => 'Skriv inn URL-skjemaet og det valgfrie URL-templet som brukes til å starte spilleren.';
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
	@override String get quickTag => 'Hurtigtagg...';
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
	@override String get disconnectConfirmBody => 'PlezyNG slutter å sende hendelser til Trakt. Du kan koble til igjen når som helst.';
	@override String get scrobble => 'Sanntids-scrobbling';
	@override String get scrobbleDescription => 'Send avspillings-, pause- og stopphendelser til Trakt under avspilling.';
	@override String get watchedSync => 'Synkroniser settstatus';
	@override String get watchedSyncDescription => 'Når du markerer elementer som sett i PlezyNG, markeres de også som sett på Trakt.';
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
	@override String get noSignInMethods => 'Denne Seerr-instansen tilbyr ingen innloggingsmetode som PlezyNG støtter.';
	@override String get instance => 'Instans';
	@override String get disconnectConfirm => 'Koble fra Seerr?';
	@override String get disconnectConfirmBody => 'PlezyNG glemmer denne Seerr-instansen. Koble til igjen når som helst.';
	@override String get request => 'Be om';
	@override String get request4k => 'Be om i 4K';
	@override String get seasons => 'Sesonger';
	@override String get allSeasons => 'Alle sesonger';
	@override String get advancedOptions => 'Avansert';
	@override String get destinationServer => 'Målserver';
	@override String get qualityProfile => 'Kvalitetsprofil';
	@override String get rootFolder => 'Rotmappe';
	@override String get languageProfile => 'Språkprofil';
	@override String get tags => 'Tagger';
	@override String get noTags => 'Ingen tagger';
	@override String defaultOption({required Object name}) => '${name} (standard)';
	@override String get animeNote => 'Denne serien er en anime.';
	@override String get requestSubmitted => 'Forespørsel sendt';
	@override String requestFailed({required Object error}) => 'Forespørsel mislyktes: ${error}';
	@override String get requestsLoadFailed => 'Kunne ikke laste forespørselsalternativer';
	@override String get nothingToRequest => 'Alt er allerede tilgjengelig eller forespurt.';
	@override String get statusAvailable => 'Tilgjengelig';
	@override String get statusPartiallyAvailable => 'Delvis tilgjengelig';
	@override String get statusRequested => 'Forespurt';
	@override String get statusProcessing => 'Behandler';
	@override String get statusBlocklisted => 'På blokkeringslisten';
	@override String couldNotReach({required Object url, required Object error}) => 'Kunne ikke nå ${url}: ${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => 'Ingen Seerr-instans på ${url} (HTTP ${status})';
	@override String get behindAuthProxy => 'En autentiserende omvendt proxy (SSO eller HTTP-autentisering) svarte i stedet for Seerr. PlezyNG kan ikke logge inn gjennom den: La Seerrs /api/v1-sti omgå proxyen for denne appen, eller bruk en adresse som når Seerr direkte.';
	@override String get invalidUrl => 'Skriv inn en serveradresse som https://seerr.example.com';
	@override String get quickConnectUnsupported => 'Denne Seerr-instansen støtter ikke Quick Connect. Den krever Seerr 3.4 eller nyere.';
	@override String get notInitialized => 'Denne Seerr-instansen har ikke fullført førstegangsoppsettet';
	@override String get noPlexTokenForReauth => 'Ingen Plex-token er tilgjengelig for å logge inn på nytt';
	@override String get noStoredCredentials => 'Ingen lagret påloggingsinformasjon er tilgjengelig for å logge inn på nytt';
	@override String get signInRejected => 'Innloggingen ble avvist';
	@override String get noSessionCookie => 'Seerr utstedte ingen øktinformasjonskapsel';
	@override String get freshCookieRejected => 'Seerr avviste den nye øktinformasjonskapselen';
	@override String get noUserInformation => 'Seerr returnerte ingen brukerinformasjon';
	@override String get sessionRejectedAfterReauth => 'Økten ble avvist etter ny innlogging';
	@override String get permissionDenied => 'Seerr avviste denne handlingen: kontoen din har ikke lenger den nødvendige tillatelsen';
	@override String get permissionRevoked => 'Du har ikke lenger tillatelse til å be om dette';
}

// Path: services
class _Translations$services$nb extends Translations$services$en {
	_Translations$services$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tjenester';
	@override String get hubSubtitle => 'Synkroniser fremdrift og forespør nye titler.';
	@override String get integrations => 'Integrasjoner';
	@override String get notConnected => 'Ikke tilkoblet';
	@override String connectedAs({required Object username}) => 'Tilkoblet som @${username}';
	@override String get scrobble => 'Registrer fremdrift automatisk';
	@override String get scrobbleDescription => 'Oppdater listen din når du er ferdig med en episode eller film.';
	@override String disconnectConfirm({required Object service}) => 'Koble fra ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'PlezyNG slutter å oppdatere ${service}. Koble til igjen når som helst.';
	@override String connectFailed({required Object service}) => 'Kunne ikke koble til ${service}. Prøv igjen.';
	@override late final _Translations$services$names$nb names = _Translations$services$names$nb._(_root);
	@override late final _Translations$services$simklReconnect$nb simklReconnect = _Translations$services$simklReconnect$nb._(_root);
	@override late final _Translations$services$deviceCode$nb deviceCode = _Translations$services$deviceCode$nb._(_root);
	@override late final _Translations$services$oauthProxy$nb oauthProxy = _Translations$services$oauthProxy$nb._(_root);
	@override late final _Translations$services$pendingAuth$nb pendingAuth = _Translations$services$pendingAuth$nb._(_root);
	@override late final _Translations$services$libraryFilter$nb libraryFilter = _Translations$services$libraryFilter$nb._(_root);
	@override String get seerrDescription => 'Koble til Seerr eller Overseerr for å søke etter titler og sende medieforespørsler.';
	@override late final _Translations$services$trackerDescriptions$nb trackerDescriptions = _Translations$services$trackerDescriptions$nb._(_root);
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
	@override String get invalidCredentials => 'Ugyldig brukernavn eller passord';
	@override String get authResponseNotJson => 'Autentiseringssvaret var ikke gyldig JSON';
	@override String get authResponseIncomplete => 'Påloggingssvaret fra serveren var ufullstendig';
	@override String get quickConnectRejected => 'Quick Connect ble avvist av serveren';
	@override String get quickConnectNotJson => 'Quick Connect-svaret var ikke gyldig JSON';
	@override String get quickConnectMissingFields => 'Quick Connect-svaret mangler en kode eller hemmelighet';
	@override String get quickConnectPollRejected => 'Quick Connect-spørringen ble avvist av serveren';
	@override String get serverTimedOut => 'Serveren svarte ikke i tide';
	@override String get responseNotJson => 'Serversvaret var ikke gyldig JSON';
	@override String responseMissingIdentity({required Object product}) => 'Svaret mangler en ID eller et servernavn – er dette en ${product}-server?';
	@override String probeFailed({required Object error}) => 'Kunne ikke nå serveren: ${error}';
	@override String enterAtLeastOneUrl({required Object product}) => 'Angi minst én URL til en ${product}-server';
	@override String noReachableServer({required Object product}) => 'Fant ingen tilgjengelig ${product}-server';
	@override String urlsPointToDifferentServers({required Object product}) => 'Disse URL-ene peker til forskjellige ${product}-servere';
	@override String urlDoesNotMatchServer({required Object product}) => 'Denne URL-en samsvarer ikke med ${product}-serveren';
	@override String get redirectUnsupported => 'Serveren omdirigerte til en URL som ikke støttes';
	@override String redirectDifferentHost({required Object product}) => 'Serveren omdirigerte til en annen vert. Angi den endelige ${product}-URL-en direkte.';
	@override String get redirectInsecure => 'Serveren omdirigerte fra HTTPS til en usikker URL';
	@override String redirectUnsupportedEnterFinal({required Object product}) => 'Serveren omdirigerte til en URL som ikke støttes. Angi den endelige ${product}-URL-en direkte.';
	@override String get directPlexServerUrl => 'URL til Plex-server';
	@override String get directPlexServerUrlHelper => 'Skriv inn den lokale IP-adressen og porten til Plex Media Server.';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex Token (valgfritt)';
	@override String get plexTokenHelper => 'La det være tomt hvis tilgang uten auth er tillatt på denne serveren.';
	@override String get plexTokenRequired => 'Vennligst skriv inn din Plex token (X-Plex-Token).';
	@override String get connectDirectPlexCard => 'Plex Media Server (Direkt / Lokal)';
	@override String get connectDirectPlexCardSubtitle => 'Koble direkte ved hjelp av lokal IP eller URL uten plex.tv konto.';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => 'Koble direkte ved hjelp av lokal IP eller URL. Kobler til ${name}.';
	@override String get insecureTitle => 'Unencrypted tilkobling';
	@override String insecureDescription({required Object url}) => '${url} bruker HTTP. Andre på nettverket kan lese eller endre passordet, tokenene og mediene dine. Bruk HTTPS når det er tilgjengelig. Fortsett bare hvis du stoler på dette nettverket og godtar risikoen.';
	@override String get allowHttp => 'Tillat HTTP';
	@override String get httpsRequired => 'Bruk HTTPS eller uttrykkelig tillate en ukryptert tilkobling.';
}

// Path: cast
class _Translations$cast$nb extends Translations$cast$en {
	_Translations$cast$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => 'Stikk til en enhet';
	@override String get searching => 'Søk etter Cast-enheter';
	@override String connectedTo({required Object device}) => 'Tilkoblet til ${device}';
	@override String get device => 'Cast utstyr';
	@override String get readyToCast => 'Klar til å kastes';
	@override String get subtitle => 'Undertekster';
	@override String get serverNotAvailable => 'Media server er ikke tilgjengelig.';
	@override String get stopCasting => 'Stoppe casting';
	@override String get castToDevice => 'Cast til enheten';
	@override String get noEpisodeAvailable => 'Det er ingen episode tilgjengelig for å kaste.';
	@override String get startFailed => 'Kan ikke begynne å kaste. sjekk serveren og prøv igjen.';
}

// Path: automation
class _Translations$automation$nb extends Translations$automation$en {
	_Translations$automation$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => 'Det er ingen aktiv video-session å kontrollere.';
}

// Path: notifications
class _Translations$notifications$nb extends Translations$notifications$en {
	_Translations$notifications$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => 'Nytt episode';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appAccess
class _Translations$appAccess$nb extends Translations$appAccess$en {
	_Translations$appAccess$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Prøv hver funksjon gratis i 7 dager';
	@override String get description => 'Start en sju dagers prøve med full tilgang til hver PlezyNG funksjon. Det er ingen gebyr under prøve og ingen abonnement. Etter prøve, en livslang kjøp på din butikks pris låser opp PlezyNG for livet.';
	@override String get trialEndedDescription => 'Unlock alle funksjoner i PlezyNG for livet med én kjøp til din butikk pris.';
	@override String get startTrial => 'Start min 7 dagers gratis prøve';
	@override String get trialActive => 'Din 7-dagers full-feature-tester er aktiv.';
	@override String get trialEnded => '7 dagers rettssak er over';
	@override String get trialStartFailed => 'Kan ikke spare prøven på denne enheten. vennligst prøv igjen.';
	@override String get lifetimeTitle => 'PlezyNG avsluttet for livet';
	@override String get lifetimeBody => 'Du har livslang tilgang til alle PlezyNG funksjoner.';
	@override String get manageTitle => 'PlezyNG Livslang tilgang';
	@override String get manageDescription => 'Prøv hver funksjon gratis i 7 dager, deretter låse opp alt for livet med en betaling til priset på butikken din.';
	@override String buy({required Object price}) => 'Unlock alle funksjoner for ${price}';
	@override String get loadingPrice => 'Lading butikks pris...';
	@override String get retryPrice => 'Retry pris lookup';
	@override String get restore => 'Åpne livslang kjøp';
	@override String get pending => 'Kjøpet ditt venter på betaling eller godkjenning. Livslang tilgang låser opp så snart butikken fullfører det.';
	@override String get storeUnavailable => 'Kontrollere at du er signert inn i butikken og kjøp er tillatt på denne enheten.';
	@override String get productNotFound => 'PlezyNG livslang avlås er ikke tilgjengelig i denne butikken ennå.';
	@override String get productQueryFailed => 'Kan ikke laste opp priset på butikken. sjekk koblingen din og prøv igjen.';
	@override String get purchaseFailed => 'Kjøpet gikk ikke gjennom. prøv igjen.';
	@override String get restoreFailed => 'Kan ikke nå butikken for å gjenopprette kjøpet. prøv igjen.';
	@override String get nothingToRestore => 'No. PlezyNG livslang kjøp ble funnet for denne butikken konto.';
}

// Path: detail
class _Translations$detail$nb extends Translations$detail$en {
	_Translations$detail$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => 'Slutter kl. ${time}';
}

// Path: watchLink
class _Translations$watchLink$nb extends Translations$watchLink$en {
	_Translations$watchLink$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => 'Kan ikke nå en server på Plex for denne koblingen.';
	@override String get notFound => 'Du kan ikke finne denne show eller film på serverne dine Plex.';
	@override String get ambiguous => 'Denne koblingen matcher elementer på mer enn én server.';
	@override String get plexOnly => 'Se koblinger støtter for tiden bare Plex servere.';
	@override String get unsupportedItem => 'Se lenker kan bare åpne en show eller en film.';
	@override String get menuItem => 'Se på link';
	@override String get dialogTitle => 'Se link';
	@override String get dialogShowHint => 'Åpne denne koblingen spiller neste episode. Legg til &mode=shuffle til slutten for å spille showet på shuffle.';
	@override String get dialogMovieHint => 'Åpning av denne koblingen spiller filmen.';
	@override String get copy => 'Kopierer';
	@override String get copied => 'Link kopieres';
}

// Path: homeLayout
class _Translations$homeLayout$nb extends Translations$homeLayout$en {
	_Translations$homeLayout$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Hjem Layout';
	@override String get resetToast => 'Hjem gjenoppbygging til den opprinnelige Plezy hero layout';
	@override String get resetHeroTitle => 'Åpne hero layout til lager Plezy?';
	@override String get resetHeroBody => 'Avbryter hver rad av hjertesetting og bringer tilbake den eneste roterende banneret på toppen av hjemmet, som før hjerteserien eksisterte.';
	@override String get removeRowTitle => 'Fjerner hjem ruten?';
	@override String removeRowBody({required Object title}) => '${title} vil bli slettet. dette kan ikke bli unntatt.';
	@override String get sync => 'Synkroniser';
	@override String get syncAccountTitle => 'Synkronisere layout med kontoen din Plex';
	@override String get syncAccountOn => 'På: Denne enheten deler rekkefølge, rader, Hero og Auto-slide med dine andre enheter.';
	@override String get syncAccountOff => 'Av: Denne enheten holder sin egen layout.';
	@override String get syncNow => 'Synkronisering nå';
	@override String get plexHomeManager => 'Plex Hjemmanager';
	@override String get managePlexRows => 'Administrer Plex rader i Plezy';
	@override String get managePlexRowsDescription => 'Åpne for å organisere de hjemmelavede radene';
	@override String get organizeHomeRows => 'Organisere hjemmelavede rader';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} rader: bevegelse, Hero, Auto-slide, fjerne';
	@override String organizeLibraryRows({required Object library}) => 'Organisere ${library} rader';
	@override String organizeLibraryRowsDescription({required Object n}) => 'Fortsett å se + ${n} rader: bevegelse, Biblioteket, Hjem, Hero, Auto-slide';
	@override String get renderAsHero => 'Render som en helt kort';
	@override String get heroOnlySingleCollection => 'Kun tilgjengelig når denne raden løses til en enkelt samlings virkelige titler';
	@override String get hero => 'Hjernen';
	@override String get autoSlide => 'Automatisk bytte';
	@override String get autoSlideDescription => 'Arrows (PC) og d-pad (TV) fungerer alltid og starter timeret på nytt.';
	@override String get autoSlideEditDescription => 'Slides også på egen hånd hvert få sekunder. Av: bare beveger seg når du klikker på en pil (PC) eller trykker venstre/høyre på fjern (TV).';
	@override String get enableHeroFirst => 'Oppmuntre til å helte først';
	@override String get showOnHome => 'Show på hjemskjermen';
	@override String get home => 'Hjem';
	@override String get removeFromHome => 'Fjern fra hjemmet';
	@override String get selectRowsFirst => 'Velg hjem ruter nedenfor først.';
	@override String plexManagedRows({required Object n}) => '${n} Plex-styrte rader';
	@override String get continueWatching => 'Fortsett å se';
	@override String get continueWatchingLibraryDescription => 'Denne bibliotekets egen resume-progress-runde';
	@override String get continueWatchingHomeDescription => 'Den gjenoppgående fremskritt rad vist på Hjem';
	@override String get nextUpHomeDescription => 'Neste uoppdaget episode ser ut separat på Home';
	@override String get library => 'Bibliotek';
	@override String get showInRecommended => 'Utstilling i biblioteket anbefales';
	@override String get customPlexRow => 'Tilpasset Plex rad';
	@override String get heroNeedsLibrary => 'Sjekk biblioteket først – Hero trenger noe å vise';
	@override String get heroNeedsSurface => 'Sjekk biblioteket eller hjemmet først – Hero trenger noe å vise';
	@override String get removeHub => 'Fjern Hub';
	@override String get noPlexRows => 'No. Plex-styrt rader returnerte for denne biblioteket.';
	@override String get openDetails => 'Åpne detaljer';
	@override String get heroCards => 'Hero kort';
	@override String get tapHeroCard => 'Tapping av en helte kort';
	@override String get tvPlayFocus => 'TV fjern: Highlight Play-knappen';
	@override String get tvPlayFocusDescription => 'D-pad ned stopper på Play-knappen før du går til neste rad.';
	@override String get tvWrap => 'TV fjernsyn: loop hero kort';
	@override String get tvWrapDescription => 'Rett på det siste kortet går tilbake til det første. av stopper på det siste kartet. venstre på det første kortet går alltid til sidebaren.';
	@override String get castOnHero => 'Spille på hero bannere';
	@override String get castOnHeroDescription => 'Vis casten langs bunnen av en helt banner. Off holder bare tittelen og sammendraget.';
	@override String get customRows => 'Custom ruter';
	@override String get loading => 'Lading hjem layout ...';
	@override String get noCustomRows => 'Ingen vanlig runde ennå';
	@override String get addRowHint => 'Bruk Home-runde for å lage en.';
	@override String get addHomeRow => 'Legg til Home Rue';
	@override String get addHomeRowDescription => 'Velg en kategori; den nye raden blir automatisk lagt til i Organiser';
	@override String get removeRow => 'Fjern runde';
	@override String get recentlyAdded => 'Nylig lagt til';
	@override String get recentlyReleased => 'Nylig frigjort';
	@override String get movieCollections => 'Filmsamlinger';
	@override String get showCollections => 'Vis innsamling';
	@override String get rowTitle => 'Rø titel';
	@override String get content => 'Innhold';
	@override String get showThisRowIn => 'Vis denne raden i:';
	@override String get libraryRecommended => 'Biblioteket anbefales';
	@override String get heroCard => 'Hero kort';
	@override String get heroCardDescription => 'Vises som et fullbredt roterende kort i stedet for et posterskjelv.';
	@override String get heroUnavailableDescription => 'Kun tilgjengelig når denne raden løses til en enkelt samlings virkelige titler - med mer enn én samling valgt det er ingen enkelt tittel å rote gjennom.';
	@override String get librariesSelection => 'Biblioteker (leve alle unchecked for å inkludere hver bibliotek)';
	@override String get librariesMergedDescription => 'Hver bibliotek sjekket her er forbundet i denne ene raden.';
	@override String get movieCollectionsSelection => 'Filmsamlinger (leve alle unchecked for hver utvalgte bibliotek)';
	@override String get showCollectionsSelection => 'Vis samlingene (leve alle u sjekket for hver utvalgte bibliotek)';
	@override String get collectionRowsDescription => 'Hvis det er mer enn én match, vises hver samling som en enkelt poster - trykk på den for å åpne den samling.';
	@override String get allCollections => 'Alle samlinger';
	@override String get noRowsHere => 'Ingen rader her ennå.';
	@override String get hideWatchedRows => 'Skjære oppdagede gjenstander i rader';
	@override String get hideWatchedRowsDescription => 'Fullt sett titler forlater Hjem og bibliotek Rekommenderte rader.';
	@override String get untitledCollection => 'Utektede samlinger';
	@override String get moveRowHint => 'Opp/Down: flytte rad · Velg: drop her · Tilbake: kanseller';
	@override String get organizeRowsHint => 'Velg på en rekke (eller hold Velg): flytte den · Venstre/Rett: rekke alternativer · Tilbake: gjort';
	@override String get layoutNavDescription => 'Velg rader, biblioteker og samlingskategorier';
	@override String get editHomeRow => 'Edit Hjem Rå';
	@override String get resetHeroButton => 'Resett hero layout til lager Plezy';
	@override String get reorderingUnlocked => 'Å gjenoppta unlocked';
	@override String get reorderingLocked => 'Å gjenoppta låst';
	@override String get rowsCanBeDragged => 'Råene kan trekkes - trykk låsen for å forhindre at det';
	@override String get tapLockToDrag => 'Trykk på låsen for å trekke rader';
	@override String customRowLabel({required Object title}) => 'Tilpasset: ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => 'Skjul';
	@override String get remove => 'Fjern';
	@override String get libraryResumeRow => 'Denne bibliotekets resume-runde';
	@override String get pressAgainToDelete => 'Trykk igjen for å slette';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => 'På';
	@override String get resetHeroButtonDescription => 'Avbryter hver rad av hjertesetting og bringer tilbake den ene roterende banneret til toppen, som før hjerteserien eksisterte.';
	@override String get tapHeroCardDescription => 'Velg om tapping eller valg av et Hero-kort starter playback eller åpner detaljene.';
	@override String get heroTapPlayDescription => 'Start det valgte elementet umiddelbart.';
	@override String get heroTapDetailsDescription => 'Åpne detaljer om det valgte elementet før du velger en handling.';
}

// Path: platform
class _Translations$platform$nb extends Translations$platform$en {
	_Translations$platform$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'PlezyNG kobler til medieserverne og avspillingsenhetene dine på det lokale nettverket.';
	@override String get locationPermission => 'PlezyNG bruker lokasjonstilgang når iOS krever det for å oppdage ditt lokale nettverk og koble til dine medie servere.';
	@override String get photoLibraryPermission => 'Velg bilder fra bildebiblioteket som omslag og illustrasjoner til medieinnhold.';
	@override String get cameraPermission => 'Skann QR-koder for å pare en Companion Remote.';
}

// Path: universalMedia
class _Translations$universalMedia$nb extends Translations$universalMedia$en {
	_Translations$universalMedia$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Åpne medier';
	@override String get shortcutHelp => 'Spill en lenke, spillliste eller fil for denne sesjonen.';
	@override String get intro => 'Åpne en lenke, spillliste eller fil. Playback bruker PlezyNGs standardspiller og legger ikke til historie i biblioteket ditt.';
	@override String get openWhat => 'Hva vil du gjerne åpne?';
	@override String get stream => 'Stream adresse';
	@override String get playlist => 'Playlist';
	@override String get files => 'Device filer';
	@override String get favorites => 'Saved stream favoritter';
	@override String get address => 'Media adresser';
	@override String get addressHelp => 'URLer med anerkjente akkrediterings- eller signaturparameter brukes kun for denne sesjonen og kan ikke lagres som favoritter.';
	@override String get displayName => 'Visningsnavnet (alternativt)';
	@override String get displayNameHelp => 'Velg et kort navn for spilleren og systemmediakontrollene.';
	@override String get allowHttp => 'Tillat en ukryptert HTTP-tilkobling';
	@override String get allowHttpHelp => 'HTTP krypterer ikke koblingen. Tillat den bare på et pålitelig nettverk. Bruk HTTPS når det er mulig.';
	@override String get advancedProtocols => 'MPV bare: Skriv inn en RTSP, RTMP/RTMPS, UDP eller RTP-adresse.';
	@override String get liveStream => 'Behandle som levende';
	@override String get liveStreamHelp => 'Bruk dette for live-video eller radio. appen skjuler tidsboken, skip knopper og go-to-time alternativet. slå det av for en opptak.';
	@override String get privateSession => 'Bare denne tilbakemeldingen bruker adressen.Save a eligible stream favorite to keep it in this profile.';
	@override String get saveFavorite => 'Spar favoritt';
	@override String get playNow => 'Spill nå';
	@override String get favoriteSaved => 'Stream favoritt lagret til denne profilen';
	@override String skippedEntries({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: 'Skipet ${count} ustøttet eller usikkert playlist inngang.',
		other: 'Skipede ${count} ustøttet eller usikre playlist-inntekter.',
	);
	@override String get playlistAddress => 'Playlist adresser';
	@override String get playlistAddressHelp => 'Åpne en M3U, M3u8, eller PLS-spillliste fra en nettadresse. direkte strømlinjer sparer ikke spilllisten.';
	@override String get choosePlaylist => 'Velg Playlist filer';
	@override String get openPlaylist => 'Åpne playlist';
	@override String get playlistFormatsHelp => 'En spillliste kan inneholde opptil 1000 elementer og 2 MB. HLS manifesterer seg åpent som strømmer slik at spilleren kan velge en kvalitet.';
	@override String get noFavorites => 'Ingen sparte stream favoritter ennå. Favoritter forblir i denne profilen.';
	@override String get removeFavorite => 'Fjern stream favoritt';
	@override String get filesHelp => 'Velg audio, video eller ISO-filer for en midlertidig kue. filer og URL\'er er ikke lagt til bibliotekets historie.';
	@override String get chooseFiles => 'Velg filer';
	@override String fileQueue({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: '1 utvalgte filer',
		other: '${count} utvalgte filer',
	);
	@override String get wifiTransfer => 'Send filer via Wi-Fi';
	@override String get wifiTransferHelp => 'Overføring av støttet filer fra en nettleser på samme pålitelige nettverk.';
	@override String get wifiTransferIntro => 'Åpne denne adressen i en nettleser på en annen enhet.Velg filer for å legge dem til filer og bøker biblioteket på denne enheten.';
	@override String get wifiTransferPrivacy => 'Denne enheten mottar filer over ditt lokale nettverk. Enhver som kjenner denne adressen kan sende filer til du stopper overføringen eller adressen utløper etter 15 minutter. Maksimum: 100 filer, 4 GiB per fil, 10 GiB totalt.';
	@override String get wifiTransferStarting => 'Forberedelse av en privat, tidsbegrenset overføring ...';
	@override String get wifiTransferUnavailable => 'Kan ikke starte overføringen. sjekk lokalt nettverkstilgang og prøv igjen.';
	@override String get openThisAddress => 'Åpne en av disse adressene på senderenheten';
	@override String get copyAddress => 'Kopierer overføringsadresse';
	@override String get addressCopied => 'Overføringsadresse kopieres';
	@override String transferExpires({required Object time}) => 'Denne adressen utløper i ${time}.';
	@override String uploadCount({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: '${count} filen mottatt',
		other: '${count} filer mottatt',
	);
	@override String uploadedData({required Object size}) => 'Oppsatt av ${size}';
	@override String get stopTransfer => 'Stopp overføring og invalidere adressen';
	@override String get startTransfer => 'Start overføring';
	@override String get wifiImportedFiles => 'Wi-Fi overføring';
	@override String get wifiBrowserTitle => 'Send filer til PlezyNG';
	@override String get wifiBrowserIntro => 'Velg lyd, video, e-bok eller komiksfiler for å sende. filene lagres i denne enhetens Filer og bøker bibliotek. Maksimum: 100 filer, 4 GiB per fil, 10 GiB totalt.';
	@override String get uploadFilesLabel => 'Filer å sende';
	@override String get uploadSelected => 'Last opp utvalgte filer';
	@override String get uploadSelectFirst => 'Velg en eller flere filer først.';
	@override String get uploading => 'Sending';
	@override String get uploadComplete => 'Filet er lagt til PlezyNG.';
	@override String get uploadFailed => 'Filen kan ikke legges til. Hold denne siden åpen og prøv igjen.';
	@override String get liveCue => 'Livet';
	@override String get liveSession => 'Live Stream';
	@override String get liveCueHelp => 'For live-video eller radio, skjuler appen tidsboken og hopper knapper. Det sparar ikke adressen eller se historie.';
	@override String get sessionOnly => 'Dette spillet er sesjon-only';
	@override String get sessionOnlyHelp => 'Playback sparer aldri fremgang eller historie.Save the stream as a favorite to keep it in this profile if it is eligible.';
	@override String get pictureAdjustments => 'Bilder justeringer';
	@override String get pictureHelp => 'Disse endringene i bildet påvirker bare denne playback. De resetter når playback avsluttes.';
	@override String get resetPicture => 'Resett bilde';
	@override String get brightness => 'Skjønnhet';
	@override String get contrast => 'Kontrast';
	@override String get gamma => 'Gamma';
	@override String get hue => 'Hue';
	@override String get saturation => 'Saturasjon';
	@override String get view360 => 'Flat visning for 360° video';
	@override String get view360Help => 'MPV trenger FFmpegs v360-filter for denne visningen.';
	@override String get view360Unavailable => 'Denne MPV-byggingen kan ikke bruke 360°-filteret.';
	@override String get view360Yaw => 'Horisontell utsikt';
	@override String get view360Pitch => 'Vertikalt syn';
	@override String get view360FieldOfView => 'Felt av syn';
	@override String get recordStream => 'Rekord live stream';
	@override String get stopRecording => 'Stoppe og lagre opptak';
	@override String get recordingStarted => 'Opptaket er aktivt.Letting playback stopper og sparer innspillingen.';
	@override String get recordingSaved => 'Oppskriften er avsluttet og reddet.';
	@override String get recordingActive => 'Oppdatering av denne enheten.Leaving playback stopper og sparer det.';
	@override String get recordingFormatHelp => 'For video, velg MKV eller MPEG-TS. for lyd, velge MKA eller MKV.';
	@override String get replaceRecordingTitle => 'Vil du erstatte denne innspillingen?';
	@override String get replaceRecordingHelp => 'PlezyNG gjenoppretter den eksisterende filen under opptak. Hvis det ikke kan lagre den nye opptak, plezyNG restaurerer sikkerhetskopien.';
	@override String get replaceRecording => 'erstatte filer';
	@override String get discHelp => 'Åpne en disk i denne datamaskinens optiske skjerm. Du kan også åpne et ISO-bilde fra Device-filer.';
	@override String get discs => 'Optikal disk';
	@override String get dvd => 'DVD';
	@override String get bluray => 'Blu-ray';
	@override String get audioCd => 'Audio CD';
	@override String get discAvailability => 'Disc playback trenger en kompatibel MPV-bygging, støttet drive og operativsystem tillatelse. Det kan ikke gå glipp av kommersiell diskbeskyttelse.';
	@override String get converterTitle => 'Konverter en lokal mediefil';
	@override String get converterHelp => 'Bruk FFmpeg til å lage en MP4, M4A eller MP3 kopi.';
	@override String get converterIntro => 'Konverter en lokal lyd- eller videofil til et format som fungerer på flere enheter.';
	@override String get converterPrivacy => 'FFmpeg må installeres på denne datamaskinen. Conversion leser bare lokale filer. Det lastes ikke ned strømmer eller fjerner DRM.';
	@override String get converterChooseInput => 'Velg en lokal mediefil';
	@override String get converterFormat => 'Utgangsformatet';
	@override String get converterMp4 => 'MP4 · H.264 og AAC';
	@override String get converterM4a => 'M4A · AAC lyd';
	@override String get converterMp3 => 'MP3 og Audio';
	@override String get converterSaveAs => 'Lagre konverterte medier som';
	@override String get converterExtensionMismatch => 'Velg et filnavn med den valgte utvidelsen.';
	@override String get converterUnsupportedInput => 'Velg en audio eller video fil.';
	@override String get converterLocalOnly => 'Den valgte filen er ikke tilgjengelig som en lokal enhetsvei.';
	@override String get converterReplaceTitle => 'Vil du erstatte denne filen?';
	@override String get converterReplaceHelp => 'PlezyNG gjenoppretter den eksisterende filen til den konverterte kopien er lagret.';
	@override String get converterStarting => 'Start med FFmpeg...';
	@override String get converterProgress => 'For å konvertere til denne datamaskinen...';
	@override String get converterComplete => 'Konversjonen er fullført. den nye filen er klar.';
	@override String get converterFfmpegMissing => 'Installere FFmpeg med H.264, AAC, og MP3 støtte, så prøv igjen.';
	@override String get converterFailed => 'Kontroller at kildefilen kan leses og destinasjonen har nok gratis plass.';
	@override String get converterCancelled => 'Konverteringen ble avlyst. den ufullstendige utgaven ble fjernet.';
	@override String get converterDesktopOnly => 'Lokalt konvertering er tilgjengelig på skrivebord datamaskiner med FFmpeg installert.';
	@override String get converterStart => 'Konverter filer';
	@override String get mediaToolsTitle => 'Media verktøy';
	@override String get mediaToolsShortcut => 'Få eller dele media, legge til søkeklarasjoner, eller bruk kommandelinjen.';
	@override String get mediaToolsIntro => 'Velg et fokusert verktøy. få og strøm-out bruk FFmpeg installert på dette skrivebordet. Extensions og CLI kommandoer bruker begrensede HTTPS forespørsler og den eksisterende Open media strømmen.';
	@override String get mediaToolsAccessibility => 'Verktøyvalg og kontroller fungerer med touch, indikator, tastatur, og D-pad fokus. Opptak, deling og søk status endringer er annonsert.';
	@override String get mediaTool => 'Media verktøy';
	@override String get captureIntro => 'Lagre skjermen eller kameraet til en MP4 fil på denne datamaskinen. FFmpeg må installeres og inkludere koderen H.264.';
	@override String get captureNoDevices => 'Ingen skjerm eller kamera ble funnet. sjekk FFmpeg opptak støtte og operativsystemet personvern tillatelser.';
	@override String get captureSource => 'Skjerm eller kamera';
	@override String get captureScreen => 'Skjerm';
	@override String get captureAudioSource => 'Audio inntak (valgfritt)';
	@override String get captureAudioHelp => 'Legg til lyd fra en mikrofon eller tilgjengelig inngang. Enhetsvalg avhenger av FFmpeg og systemtillatelser.';
	@override String get captureAudioNone => 'Ingen lyd';
	@override String get captureDefaultAudio => 'Standard lydinngang';
	@override String get captureWaylandHelp => 'Wayland begrenser denne XWayland fangen til X display. Windows utenfor XWayland kan ikke vises.';
	@override String get captureFrameRate => 'Rekordframe rate';
	@override String get capturePrivacy => 'Opptaket lagres kun til filen du velger. mikrofonopptak er valgfritt. PlezyNG laster ikke opp opptaket.';
	@override String get captureSaveAs => 'Lagre skjermopptak som';
	@override String get captureExtensionMismatch => 'Velg et filnavn som slutter i .mp4.';
	@override String get captureFfmpegMissing => 'FFmpeg eller H.264 video koder er ikke tilgjengelig. Installere en støttet FFmpeg bygning, og prøv igjen.';
	@override String get captureFailed => 'Kontrollere enhetens tillatelse, tilgjengelig lagring, og FFmpeg støtte.';
	@override String get captureSaved => 'Skjermopptak er redde.';
	@override String get captureElapsedLabel => 'Opptegningstid';
	@override String get captureStart => 'Begynn opptak';
	@override String get captureStop => 'Stopp og redde';
	@override String get captureMode => 'Fanger';
	@override String get shareMode => 'Deling';
	@override String get shareIntro => 'Send en lokal mediafil til en annen enhet på ditt private nettverk. PlezyNG skaper en midlertidig HLS-strøm.';
	@override String get sharePrivacy => 'Alle på ditt lokale nettverk som mottar den private koblingen kan se mens den er aktiv. koblingen utløper etter 60 minutter. stoppe deling for å lukke serveren og invalidere koblingen.';
	@override String get shareChooseFile => 'Velg media filer';
	@override String get shareChooseHelp => 'Velg en lokal audio eller videofil. filen forblir på denne datamaskinen.';
	@override String get shareFfmpegMissing => 'FFmpeg eller H.264/AAC koder er ikke tilgjengelige. Installere FFmpeg med H.264 og AAC koder støtte.';
	@override String get shareFailed => 'Strømmen kunne ikke starte eller stoppe uventet. sjekk FFmpeg og nettverkstilgang.';
	@override String get shareActive => 'Strømmen er klar på ditt private nettverk.';
	@override String get shareEnded => 'Mediene har nådd slutten og er ikke lenger delt.';
	@override String get shareStopped => 'Deling stoppet. den midlertidige koblingen er ikke lenger gyldig.';
	@override String get shareUrlCopied => 'Stream adressen kopieres.';
	@override String get shareOpenUrl => 'Åpne denne adressen i en spiller på den andre enheten';
	@override String get shareQrLabel => 'QR-kode for midlertidig strømadresse';
	@override String get shareQrHelp => 'Scan med en kompatibel spiller som er koblet til det samme private nettverket.';
	@override String get shareHttpHint => 'Denne strømmen bruker ukryptert HTTP. i PlezyNG, tillate HTTP før åpning.';
	@override String get shareCopyUrl => 'Kopierer strømadresse';
	@override String get shareExpiresLabel => 'Linken utløper ved';
	@override String get shareStarting => 'Forberedelse av strømmen...';
	@override String get shareStart => 'Begynn å dele';
	@override String get shareStop => 'Slutt å dele';
	@override String get extensionsMode => 'Utvidelser og CLI';
	@override String get extensionsIntro => 'Legg til en data-enbart søk utvidelse for å finne media. Velg et resultat for å laste den inn i det kjente Open media-skjemaet.';
	@override String get extensionsPrivacy => 'En manifest kan definere et HTTPS søk endpoint og kart responsfelt. Det kan ikke kjøre kode, legge til forespørselshoveder, lese filer, eller lansere shell kommandoer.';
	@override String get extensionImport => 'Legg til utvidelse manifest';
	@override String get extensionEmpty => 'Ingen søketjenester ennå. Velg en pålitelig manifest JSON fil for å legge til en.';
	@override String get extensionChoose => 'Søk service';
	@override String get extensionSearchConsent => 'Hver søk sender ordene dine til denne tjenesten HTTPS. Resultater åpnes bare etter at du har valgt en.';
	@override String get extensionSearchLabel => 'Søk media';
	@override String get extensionSearch => 'Søk';
	@override String get extensionSearching => 'Søk...';
	@override String get extensionNoResults => 'Ingen sikker medieresultater ble returnert. prøv en annen søk.';
	@override String get extensionInstallTitle => 'Legg til denne søketjenesten?';
	@override String get extensionReplaceTitle => 'Oppdaterer du denne søketjenesten?';
	@override String get extensionService => 'Tjenestene';
	@override String get extensionEndpoint => 'HTTPS Endpoint';
	@override String get extensionConsent => 'Din søktekst sendes til denne tjenesten. manifestet inneholder ingen utførbar kode. fortsett bare hvis du stoler på dette slutten.';
	@override String get extensionInstall => 'Legg til service';
	@override String get extensionReplace => 'Oppdateringstjeneste';
	@override String get extensionRemoveTitle => 'Fjerner du denne søketjenesten?';
	@override String get extensionRemoveHelp => 'Dette fjerner tjenesten fra denne profilen. PlezyNG kontakter ikke sin sluttpunkt.';
	@override String get extensionRemove => 'Fjern service';
	@override String get extensionInvalidManifest => 'Denne filen er ikke en støttet utvidelse manifest. se Guiden for Open media formatet.';
	@override String get extensionSaveFailed => 'Utvidelsen kunne ikke lagres til den aktive profilen.';
	@override String get extensionSearchFailed => 'Søketjenesten returnerte ikke et gyldig svar. sjekk slutten og prøv igjen.';
	@override String get cliTitle => 'kommando linje';
	@override String get cliHelp => 'Bruk plezyctl guide for å validere en manifest eller søke etter den samme utvidelsen. Se gjennom HTTPS-tjenesten før hver søk. Resultater åpnes i det eksisterende medieformulæret; velg playback-knappen for å starte.';
	@override String get cliCopyExample => 'Kopierer kommandoeksempel';
	@override String get cliCopied => 'Kommandamodell kopieres.';
}

// Path: fileSources
class _Translations$fileSources$nb extends Translations$fileSources$en {
	_Translations$fileSources$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Filer og bøker';
	@override String get subtitle => 'Les, lytte og se fra dine egne filer.';
	@override String get add => 'Legg til kilde';
	@override String get importFiles => 'Import filer';
	@override String get localFiles => 'På denne enheten';
	@override String get source => 'Kilde';
	@override String get name => 'Navn';
	@override String get endpoint => 'Server-URL';
	@override String get smbEndpointHint => 'Eksempel: smb://nas/Movies';
	@override String get smbEndpointInvalid => 'Angi en SMB-server og én delt mappe.';
	@override String get root => 'Fold eller forhåndsregister';
	@override String get smbFolderHelp => 'La feltet stå tomt for å bruke hele den delte mappen, eller angi en mappe i den.';
	@override String get username => 'Brukernavn';
	@override String get smbDomain => 'Domene (valgfritt)';
	@override String get password => 'Passord';
	@override String get token => 'API token';
	@override String get accessKey => 'Oppsummering av Key ID';
	@override String get secretKey => 'Hemmelig tilgangsnøkkel';
	@override String get sessionToken => 'Session token (valgfritt)';
	@override String get region => 'Regionen';
	@override String get clientId => 'OAuth klient ID';
	@override String get clientSecret => 'OAuth-klienthemmelighet (desktop Google alene)';
	@override String get allowHttp => 'Tillat ukryptert HTTP på et betrodd nettverk';
	@override String get smbEncryption => 'Krypter SMB3-tilkoblingen';
	@override String get smbEncryptionHint => 'Bruk SMB3-kryptering når NAS-en støtter det.';
	@override String get connect => 'Koble til';
	@override String get cancel => 'Avbryt';
	@override String get save => 'Lagre';
	@override String get close => 'Lukk';
	@override String get removeSource => 'Avkoblet kilde';
	@override String get disconnectMessage => 'Koble fra denne kilden? Nedlastede filer og lese- og lyttehistorikken din blir på denne enheten.';
	@override String get localFolder => 'Velg mappe';
	@override String get empty => 'Ingenting her ennå';
	@override String get emptyHint => 'Legg til en kilde eller importere en bok, lydbok, musikk eller video.';
	@override String get search => 'Søk etter denne mappen';
	@override String get searchCached => 'Søk redde bibliotek';
	@override String get refresh => 'Oppdater';
	@override String get loadMore => 'Late mer';
	@override String get offline => 'Tilgjengelig offline';
	@override String get download => 'Hold deg offline';
	@override String get removeDownload => 'Fjern offline kopi';
	@override String get continueReading => 'Fortsett å lese';
	@override String get continueListening => 'Fortsett å lytte';
	@override String get continueWatching => 'Fortsett å se';
	@override String get read => 'Leser';
	@override String get listen => 'Lytt til';
	@override String get play => 'Spill av';
	@override String get pause => 'pause';
	@override String get stop => 'Stopp';
	@override String get startOver => 'Begynn på nytt';
	@override String get finished => 'Ferdig';
	@override String get markFinished => 'Mark er ferdig';
	@override String get markUnfinished => 'Mark uendelig';
	@override String get editions => 'Utgivelser og filer';
	@override String get chapters => 'Kapitler';
	@override String get bookmarks => 'Bokmerker og notater';
	@override String get bookmark => 'Legg til bookmark';
	@override String get highlight => 'Høydepunkter';
	@override String get note => 'Notat';
	@override String get delete => 'Slett';
	@override String get export => 'Eksport notater';
	@override String get exported => 'Notater eksportert';
	@override String get sync => 'Sync fremskritt';
	@override String get synced => 'Synkronisert fremgang';
	@override String get conflict => 'En annen enhet har en annen posisjon. Velg hvor du skal fortsette.';
	@override String get useLocal => 'Bruk denne enheten';
	@override String get useRemote => 'Bruk andre enheter';
	@override String get history => 'Posisjon historie';
	@override String get groupAudio => 'Lytt som en audiobok';
	@override String get groupHint => 'Kombiner de lydfiler som for tiden lastes inn i denne mappen. Last ned alle sidene først.';
	@override String get order => 'Filordene';
	@override String get moveUp => 'Flytt opp';
	@override String get moveDown => 'Flytt ned';
	@override String get speed => 'Spillerskapshastighet';
	@override String get sleep => 'Innsovningstimer';
	@override String get sleepOff => 'Av';
	@override String get endChapter => 'Enden av kapittel';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutt',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutter',
	);
	@override String get skipBack => 'Skip tilbake';
	@override String get skipForward => 'Skip fremover';
	@override String get smartRewind => 'Smart tilbake etter pause';
	@override String get playbackOptions => 'Lytting alternativer';
	@override String remaining({required Object time}) => '${time} gjenværende';
	@override String get contents => 'Innhold';
	@override String get readerSettings => 'Lesing av innstillinger';
	@override String get fontSize => 'Tekst størrelse';
	@override String get lineHeight => 'Line spatial';
	@override String get margin => 'Marger';
	@override String get font => 'Typefase';
	@override String get serif => 'Seriøst';
	@override String get sans => 'Uten seriet';
	@override String get mono => 'Fast tegnbredde';
	@override String get columns => 'Kolonne';
	@override String get scroll => 'Scroll vertikalt';
	@override String get justify => 'Justifiser tekst';
	@override String get readerTheme => 'Side utseende';
	@override String get appTheme => 'Følg app tema';
	@override String get paper => 'Papir';
	@override String get sepia => 'Sepia';
	@override String get night => 'Natt';
	@override String get readAloud => 'Les denne siden høyt';
	@override String get readAlong => 'Les videre';
	@override String get stopReading => 'Stopper narrasjon';
	@override String get searchBook => 'Søk i bok';
	@override String get noMatches => 'Ingen kamper';
	@override String get previousPage => 'Forrige side';
	@override String get nextPage => 'Neste side';
	@override String page({required Object number}) => 'Side ${number}';
	@override String get externalBlocked => 'Eksterne boklinser er deaktiverte i leseren.';
	@override String get loading => 'Åpning...';
	@override String get narrator => 'Narratør';
	@override String get audio => 'Lyd';
	@override String get video => 'Videoen';
	@override String get ebooks => 'Ebook';
	@override String get all => 'Alle';
	@override String get downloads => 'Offline filer';
	@override String get confirmDelete => 'Fjern den valgte offline-kopien? posisjonen og notatene dine vil forbli.';
	@override String get errorAuthentication => 'Registrer deg igjen for å koble til denne kilden.';
	@override String get errorPermission => 'Denne kilden har ikke gitt tilgang til den forespilte filen.';
	@override String get errorUnavailable => 'Forsøk igjen, eller åpne en offline kopi.';
	@override String get errorUnsupported => 'Dette formatet eller koblingen støttes ikke på denne enheten. sjekk kildeinnstillingshandboken.';
	@override String get errorInvalidData => 'Denne filen eller serverresponsen kan ikke leses sikkert.';
	@override String get errorCancelled => 'Operasjonen ble avlyst.';
	@override String get errorConflict => 'Posisjonen endret i en annen sesjon. Åpne gjenstanden for å velge en posisjon.';
	@override String get signIn => 'Logg inn';
	@override String get reconnect => 'Koble til på nytt';
	@override String get folderHelp => 'La det være å starte på kilderoten. S3 URL-er inkluderer bucket.';
	@override String get preferences => 'Foretrukninger';
	@override String get timePosition => 'Posisjon';
	@override String get audioTrack => 'Audio Track';
	@override String get subtitleTrack => 'Subtitle sporing';
	@override String get none => 'Ingen';
	@override String get fullscreen => 'Full skjerm';
	@override String get syncLocation => 'Progress synkronisering mappe (valgfritt)';
	@override String get syncLocationHint => 'En dedikert WebDAV mappe for PlezyNG stat. Bruk betingelsesbrev; media forblir uendret.';
	@override String get audiobooks => 'Audiobøker';
	@override String get comics => 'Tegneserier';
	@override String get scan => 'Skankering av bøker og media';
	@override String get browserReader => 'Åpne lesere';
	@override String get browserReaderHelp => 'Leseren er åpen i nettleseren. Hold PlezyNG åpen for å lagre leseposisjonen og notatene dine.';
	@override String get on => 'På';
	@override String get advancedSetup => 'App registrering';
	@override String get microsoftSignIn => 'Registrer deg med Microsoft';
	@override String get zoomIn => 'Zoom i';
	@override String get zoomOut => 'Zoom ut';
	@override String get fitPage => 'Fikk side';
	@override String get fitWidth => 'Fikk bredde';
	@override String get actualSize => 'Aktuell størrelse';
	@override String get goToPage => 'Gå til side';
	@override String get goToSection => 'Gå til kapittel';
	@override String pageRange({required Object count}) => 'Skriv inn et nummer fra 1 til ${count}';
	@override String get pageLayout => 'Side layout';
	@override String get automatic => 'Automatisk';
	@override String get singlePage => 'Enkel side';
	@override String get twoPages => 'To sider';
	@override String get readingDirection => 'Lesende retning';
	@override String get leftToRight => 'Fra venstre mot høyre';
	@override String get rightToLeft => 'Fra høyre mot venstre';
	@override String get letterSpacing => 'Brev om spati';
	@override String get wordSpacing => 'Ord spati';
	@override String get readerControlsHelp => 'Spre to fingre, eller bruk zoomkontrollene for å forstørre sider. Dra for å flytte siden. Ctrl/⌘ med + eller − justerer zoom; Ctrl/⌘ med 0 nullstiller den. Page Up og Page Down blar mellom sidene.';
	@override String get imagePage => 'Tegneserieside';
	@override String get resetReader => 'Åpne lesingsfortrinnene';
	@override String get zoom => 'Zoom';
	@override String get useFiles => 'Bruk filer og bøker';
	@override String get cancelScan => 'Avbestill skanningen';
	@override String get googleDrive => 'Google Drive';
	@override String get offlineQuota => 'Offline nedlasting begrenset';
	@override String get offlineQuotaHelp => 'Sett maksimalt plass som brukes av offline kopier, importerte filer og nedlastinger. Senke grensen fjerner ikke eksisterende kopier.';
	@override String get offlineStorageUsage => 'Offline lagring';
	@override String get reservedStorage => 'Reserverte';
	@override String get downloadQueue => 'Nedlasting av Queue';
	@override String get downloadRunning => 'nedlasting';
	@override String get downloadQueued => 'Venter på';
	@override String get downloadPaused => 'pause';
	@override String get downloadFailed => 'Trenger tilbakemelding';
	@override String get importing => 'Importerer';
	@override String get importInterrupted => 'Import avbrutt · fjerning til klart';
	@override String get errorQuotaExceeded => 'Den offline lagringsgrensen ble oppnådd. Oppheve grensen eller fjerne en nedlastet kopi.';
	@override String get errorStorageLow => 'Det er ikke tilstrekkelig gratis lagring av enheter for å opprettholde den beskyttede reserven.';
	@override String get errorStorageUnavailable => 'PlezyNG kunne ikke sjekke gratis enhet lagring, så skrivingen ble stoppet.';
	@override String get removeDownloadJob => 'Fjern nedlasting';
	@override String get downloadAlreadyComplete => 'Denne nedlastingen er ferdig før den kan fjernes. elementet er nå tilgjengelig offline.';
	@override String get confirmRemoveDownloadJob => 'Fjern denne nedlastingen og slett alle delvis nedlastede data? din posisjon og notater vil forbli.';
}

// Path: lending
class _Translations$lending$nb extends Translations$lending$en {
	_Translations$lending$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Offentlige bibliotek';
	@override String get add => 'Legg til biblioteket';
	@override String get other => 'En annen bibliotek';
	@override String get libraryName => 'Biblioteksnavnet';
	@override String get libraryUrl => 'Biblioteksnettsted';
	@override String get libraryUrlHint => 'Bruk bibliotekets katalog eller sign-in-side.';
	@override String get intro => 'Lån fra biblioteket ditt, hold bøkene dine lukket.';
	@override String get handoff => 'Registrer deg, låne og les på en sikker måte med bibliotekets egen tjeneste.';
	@override String get openService => 'Åpne bibliotek';
	@override String get findLibrary => 'Finn en bibliotek';
	@override String get search => 'Søk etter bøker og forfattere';
	@override String get catalogue => 'Kataloger';
	@override String get loans => 'Lån';
	@override String get holds => 'Reservasjoner';
	@override String get signIn => 'Registrer deg med biblioteket ditt';
	@override String get waiting => 'Endre registreringen i nettleseren din, og deretter tilbake her.';
	@override String get cancel => 'Avbryt';
	@override String get disconnect => 'Fjern biblioteket';
	@override String get disconnectMessage => 'Fjern dette biblioteket fra denne profilen? Lånene og reservasjonene dine blir hos biblioteket.';
	@override String get getBook => 'Få bok';
	@override String get checkAvailability => 'Sjekk tilgjengeligheten';
	@override String get available => 'Tilgjengelig for lån';
	@override String get unavailable => 'Foreløpig ikke tilgjengelig';
	@override String get borrow => 'Lån';
	@override String get placeHold => 'Reserver';
	@override String get returnBook => 'Retur tidlig';
	@override String get cancelHold => 'Avbestill reservasjon';
	@override String get confirmBorrow => 'Lån dette titlet fra biblioteket ditt?';
	@override String get confirmReturn => 'Lever tilbake denne tittelen nå? Du må kanskje låne den igjen for å fortsette.';
	@override String get confirmCancelHold => 'Avbestill reservasjonen din av denne tittelen?';
	@override String get email => 'Hold melding e-post';
	@override String due({required Object date}) => 'Avgjørende ${date}';
	@override String queue({required Object position}) => 'Posisjon ${position} i linje';
	@override String get empty => 'Ingen titler her ennå.';
	@override String get openLibraryNote => 'Lesing og lånealternativer vises på hver tittelside.';
	@override String get more => 'Late mer';
	@override String get gateway => 'Biblioteket sign-in service';
	@override String get gatewayHint => 'Leveres av biblioteket ditt eller administratoren PlezyNG.';
	@override String get advanced => 'Biblioteksintegrasjon';
	@override String get loadLibraries => 'Velg din bibliotek';
	@override String get expired => 'Dette lånet er utløpt.';
	@override String get updated => 'Biblioteket oppdatert';
	@override String get continueService => 'Fortsett i tjeneste';
	@override String get comingSoon => 'In-app låne · Kom snart';
	@override String get comingSoonDescription => 'Du kan bruke biblioteket ditt i Libby mens vi slutter å koble det.';
	@override String get suspendHold => 'Opphør hold';
	@override String get resumeHold => 'Resumé hold';
	@override String get suspendMessage => 'Behold plassen din i køen, og la neste leser låne dette eksemplaret? Du kan gjenoppta reservasjonen senere.';
	@override String get resumeMessage => 'Gjenoppta denne reservasjonen slik at biblioteket kan tilby deg neste tilgjengelige eksemplar?';
	@override String get editEmail => 'Endre melding e-post';
}

// Path: audiobook
class _Translations$audiobook$nb extends Translations$audiobook$en {
	_Translations$audiobook$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get syncTitle => 'Lesing og lytte synkroniserer';
	@override String get syncHelp => 'Hold lesingposisjoner, lyttingposisjoner, fullføringstilstand, bokmerker og notater over enhetene dine. Velg en tilkoblet lagringskonto og bruk den samme synkroniseringskoden på hver enhet. Lesing og lytting forblir separate.';
	@override String get addSyncSource => 'Legg til Google Drive, OneDrive, Dropbox, WebDAV eller S3 i filer og bøker først.';
	@override String get syncDestination => 'Synk lagringskonto';
	@override String get syncFolder => 'Synk mappe eller prefix';
	@override String get syncFolderHelp => 'Bruk en separat eksisterende mappe i din WebDAV kilde, eller en dedikert S3 prefix. Book filer endres aldri.';
	@override String get syncCode => 'Privat synkroniseringskode';
	@override String get syncCodeHelp => 'Skap en kode på din første enhet, deretter skriv den koden på andre enheter. Hold en privat kopi: det er nøkkelen til kryptert tilstand. Bruk en annen kode for hver person.';
	@override String get showCode => 'Vis eller skjule synkroniseringskode';
	@override String get newSyncCode => 'Skap en ny synkroniseringskode';
	@override String get saveSync => 'Spar og synkronisere';
	@override String get disableSync => 'Unngå synkronisering på denne enheten';
	@override String get syncSourceDisconnect => 'Fjerning av denne kilden vil slette lesing og lytte synk her. krypterte synk filer vil forbli i leverandøren.';
	@override String get syncReconnect => 'Åpne lagringskontoen';
	@override String lastSynced({required Object time}) => 'Sist synkronisert på ${time}';
	@override String get syncPrivacy => 'Kun krypterte fremgang og notater er lagret. Audio og ebook filer, konto tokener og passord er ikke lastet opp. Google Drive og OneDrive bruker app lagring; Dropbox bruker PlezyNG Sync. Tillat synkronisering kan kreve ytterligere skriving tilgang. Mens aktivert, denne destinasjonen eier fremgang synkronisering; server fremgang forblir separat. Turning synkronisering avbeholder lokal historie og fjerne tilstand.';
	@override String get syncConflicts => 'Velg hvor du skal gjenoppta';
	@override String get conflictHelp => 'Disse endringene ble gjort uavhengig. Velg posisjonen eller bookmarkversjonen for å holde. En senere timestamp eller en høyere prosentandel vinner ikke automatisk.';
	@override String syncDevice({required Object device}) => 'Utstyr ${device}';
	@override String get syncUnknownDevice => 'ukjente enheter';
	@override String get deletedBookmark => 'Fjernet bokmerke';
	@override String get finished => 'Avslutter';
	@override String readingPosition({required Object percent}) => 'Lesing · ${percent}%';
	@override String get chapterTimeline => 'Kapittel Progress';
	@override String get bookTimeline => 'Hele boken fremskritt';
	@override String bookRemaining({required Object time}) => 'Tid i denne boken: ${time}';
	@override String chapterRemaining({required Object time}) => 'Tid igjen i dette kapitlet: ${time}';
	@override String get unknownRemaining => 'Totalt tilgjengelig tid som deler spilles';
	@override String get undoSeek => 'Endelig søkt';
	@override String get customSpeed => 'Custom playback hastighet';
	@override String get speedHelp => 'Velg en hastighet fra 0.25× til 4×.';
	@override String get apply => 'Anvendt';
	@override String get customSleep => 'Personlig søvn timer';
	@override String get sleepMinutes => 'Minutter (1 til 1440)';
	@override String sleepChapters({required Object count}) => 'Stopp etter ${count} kapittel';
	@override String get extendSleep => 'Legg til 5 minutter';
	@override String sleepRemaining({required Object time}) => 'Søvn timer: ${time}';
	@override String get useDefaults => 'Bruk disse lyttekontroller for nye bøker';
	@override String get librarySort => 'Sort bøker';
	@override String get sortTitle => 'Tittel';
	@override String get sortAuthor => 'Forfatter';
	@override String get sortNarrator => 'Narratør';
	@override String get sortSeries => 'Serien ordre';
	@override String get sortRecent => 'Nylig åpnet';
	@override String get statusFilter => 'Lesing status';
	@override String get statusAll => 'Alle bøker';
	@override String get statusNew => 'Ikke startet';
	@override String get statusProgress => 'I fremskritt';
	@override String get statusFinished => 'Avslutter';
	@override String get goToTime => 'Gå til tid';
	@override String get timeHelp => 'Tider: minutter: sekunder eller minutter: sekunder';
	@override String get recoveryHelp => 'Eksport en nylig kryptert kopi før du flytter eller reparerer synkronisering data. Importerer fusjon med nåværende tilstand; de erstattes aldri lokal synkroniseringshistorie.';
	@override String get recoveryExport => 'Eksport kryptert gjenoppretting filer';
	@override String get recoveryImport => 'Import kryptert gjenoppretting filer';
	@override String get recoveryImportConfirm => 'Kombiner denne krypterte gjenoppretting filen med aktuelle lesing posisjoner og notater? eksisterende historie vil bli bevaret. delt bibliotek og element IDs er ikke inkludert; sette matching IDs på hver enhet før import.';
	@override String get recoveryExported => 'Kryptert gjenoppretting fil lagret.';
	@override String get recoveryImported => 'Data om gjenoppretting sammensatt.';
}

// Path: sourceSetup
class _Translations$sourceSetup$nb extends Translations$sourceSetup$en {
	_Translations$sourceSetup$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get savedCertificate => 'Lagret serversertifikat';
	@override String get nfsEndpointInvalid => 'Angi en NFS-URL, for eksempel nfs://nas:2049/export.';
	@override String get dlnaNone => 'Ingen DLNA-servere funnet. Angi URL-en til enhetsbeskrivelsen manuelt.';
	@override String get dlnaServers => 'DLNA-medieservere';
	@override String get dlnaUnavailable => 'DLNA-oppdagelse er ikke tilgjengelig på dette nettverket. Angi URL-en til enhetsbeskrivelsen manuelt.';
	@override String get dlnaSearching => 'Søker etter DLNA-servere på lokalnettet';
	@override String get networkSearching => 'Søker på lokalnettet…';
	@override String get dlnaDiscover => 'Finn DLNA-servere';
	@override String get dlnaHelp => 'Oppdagelse avhenger av multicast på lokalnettet. Hvis ingen server vises, angir du URL-en til enhetsbeskrivelsen ovenfor.';
	@override String get dlnaRoot => 'DLNA-objekt-ID; la stå tomt for å bruke enhetens rot.';
	@override String get passwordOrKey => 'Angi et passord eller legg til en privat nøkkel nedenfor.';
	@override String get sshFingerprint => 'SHA256-fingeravtrykk for SSH-vertsnøkkel';
	@override String get sshFingerprintHelp => 'Kontroller det med serveradministratoren. Kjør ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub på serveren og bruk SHA256-verdien.';
	@override String get sshFingerprintKeep => 'La stå tomt for å beholde det fastlåste fingeravtrykket, eller angi et nytt serverfingeravtrykk.';
	@override String get sshAuthentication => 'SSH-autentisering med offentlig nøkkel';
	@override String get sshAuthenticationHelp => 'Valgfritt; autentisering med passord støttes også.';
	@override String get privateKey => 'Privat nøkkel (PEM- eller OpenSSH-format)';
	@override String get privateKeyPassphrase => 'Passfrase for privat nøkkel';
	@override String get nfsMountPort => 'TCP-port for NFS-monteringstjenesten';
	@override String get nfsMountPortHelp => 'Standard: 20048';
	@override String get nfsUserId => 'NFS-bruker-ID (AUTH_SYS)';
	@override String get nfsUserIdHelp => 'Standard: 1000. Bruk ID-en som NAS-enhetens NFS-deling tillater.';
	@override String get nfsGroupId => 'NFS-gruppe-ID (AUTH_SYS)';
	@override String get nfsGroupIdHelp => 'Standard: 1000. Bruk gruppe-ID-en som NAS-enhetens NFS-deling tillater.';
	@override String get nfsEncryption => 'Krev kryptert NFS (RPC-with-TLS)';
	@override String get nfsEncryptionHelp => 'Krev TLS 1.3 for NFS og monteringstjenesten. Hvis NAS-enheten ikke støtter dette, avvises tilkoblingen.';
	@override String get nfsTrustCertificate => 'Egendefinert NFS-CA eller serversertifikat (PEM, valgfritt)';
	@override String get nfsTrustHelp => 'La stå tomt for sertifikater denne enheten stoler på. Legg ved behov til et sertifikat fra en privat CA eller et selvsignert serversertifikat; navnene må samsvare med verten i NFS-URL-en.';
	@override String get nfsTrustInvalid => 'Bruk et CA- eller serversertifikat i PEM-format. Ikke ta med en privat nøkkel.';
	@override String get addTrustCertificate => 'Legg til egendefinert tillitssertifikat';
	@override String get replaceTrustCertificate => 'Erstatt lagret egendefinert sertifikat';
	@override String get nfsTlsHelp => 'RPC-with-TLS bruker de vanlige portene for NFS og monteringstjenesten og krever RFC 9289-støtte på NAS-enheten. TLS 1.3 er påkrevd. Vertsnavnet eller IP-adressen må samsvare med sertifikatet. AUTH_SYS UID/GID gjelder fortsatt i den krypterte kanalen.';
	@override String get clientCertificate => 'Klientsertifikat (valgfritt)';
	@override String get clientCertificateHelp => 'Lar NAS-enheten autentisere denne klienten; AUTH_SYS-ID-er avhenger fortsatt av reglene for NAS-enhetens NFS-deling.';
	@override String get savedIdentity => 'En lagret klientidentitet vil bli brukt.';
	@override String get replaceIdentity => 'Erstatt lagret klientidentitet';
	@override String get chooseIdentity => 'Velg PKCS#12-klientidentitet';
	@override String get identityPassphrase => 'Passfrase for klientidentitet';
	@override String get identityPassphraseHelp => 'La stå tomt hvis filen ikke har en passfrase.';
	@override String get removeIdentity => 'Fjern eventuell lagret klientidentitet';
	@override String get identityStorageHelp => 'Klientidentiteter lagres i kildens krypterte lager for påloggingsinformasjon. La denne delen være uendret for å beholde den lagrede identiteten.';
	@override String get nfsLimitations => 'Skrivebeskyttet NFSv3 over TCP. Uten RPC-with-TLS er NFS-trafikken ukryptert. NAS-enheten må tillate de valgte AUTH_SYS-ID-ene og uprivilegerte klientporter (ofte kalt eksportvalget «insecure»). NFSv4 og UDP støttes ikke.';
	@override String get nfsSetupHelp => 'Hjelp med NFS-oppsett';
	@override String get nfsSetupHint => 'Kontroller disse innstillingene hvis tilkoblingen ikke opprettes.';
	@override String get nfsSetupDetails => 'Bruk en NFSv3-deling over TCP. Når kryptering kreves, må både NFS-tjenesten og monteringstjenesten støtte RPC-with-TLS. La det egendefinerte sertifikatet stå tomt for et serversertifikat denne enheten stoler på, eller legg til NAS-enhetens CA- eller selvsignerte sertifikat. Sertifikatnavnet må samsvare med verten i endepunktet. Hvis NAS-enheten krever gjensidig TLS, legger du til dens PKCS#12-klientidentitet. Bekreft til slutt at delingen tillater konfigurerte AUTH_SYS UID/GID og reglene for klientporter.';
	@override String get ftpHelp => 'FTP bruker passiv modus. Bruk ftp:// for ukryptert FTP, ftpes:// for eksplisitt TLS eller ftps:// for TLS (implisitt på port 990; eksplisitt på andre porter).';
	@override String get openSubtitles => 'OpenSubtitles';
	@override String get subtitleSetup => 'Valgfritt søk etter undertekster for frittstående videoer.';
	@override String get apiKey => 'API-nøkkel';
	@override String get optionalUsername => 'Kontoens brukernavn (valgfritt)';
	@override String get optionalPassword => 'Kontoens passord (valgfritt)';
	@override String get subtitlePrivacy => 'Hent en API-nøkkel fra opensubtitles.com. Søk sender videotittelen og tilgjengelige IMDb/TMDB-ID-er, aldri videofilen. Nøkkelen og valgfri kontoinformasjon krypteres sammen med denne kilden.';
	@override String get automaticMetadata => 'Automatiske videometadata fra nettet';
	@override String get metadataPrivacy => 'Sender bare tittel/år fra filnavnet og episodenumre eller en NFO-ID, aldri medier eller påloggingsinformasjon. NFO-feltene beholder forrang.';
	@override String get nfsEncryptionFailure => 'For kryptert NFS må du kontrollere støtte for RFC 9289 og TLS 1.3 på begge NAS-tjenestene, sertifikatnavnet og delingens UID/GID. PlezyNG prøver ikke denne tilkoblingen på nytt uten kryptering.';
	@override String get sourceConnecting => 'Kobler til kilde';
	@override String get metadataSearchPrivacy => 'Dette tittelsøket sendes til Trakt. Det sender tittelen du oppgir, ikke videoen eller kildens påloggingsinformasjon.';
	@override String get chooseMatch => 'Velg et treff';
	@override String get metadataMatchHelp => 'Kontroller tittel og år før du velger. Trakt mottar søketittelen; videoen blir på kilden sin.';
	@override String get metadataNoMatches => 'Ingen samsvarende titler funnet på nettet. Prøv en annen tittel.';
	@override String get metadataSearch => 'Søk etter metadata på nettet';
	@override String get metadataLoading => 'Søker etter film- og serieinformasjon på nettet…';
	@override String get metadataFromTrakt => 'Metadata fra Trakt på nettet';
	@override String get metadataNoAutomaticMatch => 'Fant ikke et automatisk titteltreff. Søk etter tittelen for å velge et treff.';
	@override String get metadataFailed => 'Kunne ikke laste metadata fra nettet. Avspilling og lokal informasjon er fortsatt tilgjengelig.';
	@override String get videoDetailsLoading => 'Laster videoinformasjon';
	@override String get subtitleKeyRequired => 'OpenSubtitles-API-nøkkel kreves';
	@override String get subtitleKeyHelp => 'Rediger denne filkilden og legg til en OpenSubtitles-API-nøkkel i de valgfrie undertekstinnstillingene.';
	@override String get subtitleSearchFailed => 'Undertekstsøket mislyktes. Kontroller API-nøkkelen, tilkoblingen og tilgangen til tjenesten.';
	@override String get subtitleApplyFailed => 'Kunne ikke laste ned eller bruke denne underteksten. Kontroller tilkoblingen og prøv et annet resultat.';
	@override String get subtitleSearch => 'Søk på OpenSubtitles';
	@override String get subtitleSearchPrivacy => 'Søket bruker tittelen og tilgjengelige IMDb/TMDB-ID-er. Videofilen blir på kilden sin. Kontroller språk, merking for tvungne undertekster eller undertekster for hørselshemmede og vurdering før du velger.';
	@override String get movieOrShow => 'Film eller serie';
	@override String get subtitleTitleHint => 'Angi en tittel for å avgrense resultatene';
	@override String get subtitleLanguage => 'Undertekstspråk';
	@override String get subtitleSearching => 'Søker på OpenSubtitles';
	@override String get subtitleNoMatches => 'Ingen samsvarende undertekster funnet. Prøv en annen tittel eller et annet språk.';
	@override String get downloadSubtitle => 'Last ned undertekst';
	@override String get subtitle => 'Undertekst';
	@override String get nfsTlsRequired => 'RPC-with-TLS kreves';
	@override String get nfsUnencrypted => 'Ukryptert NFS';
	@override String get tlsEncrypted => 'TLS-kryptert';
	@override String get ftpPlain => 'Ukryptert FTP';
	@override String get sshPinned => 'SSH-kryptert · vertsnøkkel fastlåst';
	@override String get smbEncrypted => 'SMB3-kryptering på';
	@override String get smbUnencrypted => 'SMB3-kryptering av';
	@override String get httpUnencrypted => 'HTTP uten transportkryptering';
	@override String get checkEndpointSecurity => 'Kontroller sikkerheten til endepunktet';
	@override String fieldRequired({required Object label}) => '${label} er påkrevd.';
	@override String integerRange({required Object label, required Object min, required Object max}) => 'Angi ${label} fra ${min} til ${max}.';
	@override String replaceFile({required Object name}) => 'Erstatt ${name}';
	@override String selectedIdentity({required Object name}) => 'Valgt klientidentitet: ${name}';
	@override String subtitleRating({required Object rating}) => 'Vurdering ${rating}';
	@override String subtitleDownloading({required Object title}) => 'Laster ned undertekst: ${title}';
	@override String get sharedEntryPair => 'Par dette elementet';
	@override String get sharedEntryPairHelp => 'Skriv inn samme ID for dette elementet på hver enhet. Bruk en stabil delt identifikator eller generer en og kopier den til det matchende elementet. Progress parer bare når utgave filtyper, størrelser og bestillinger matcher. Blank fjerner denne kartleggingen.';
	@override String get sharedEntryId => 'Delte elementer ID';
	@override String get generateSharedEntryId => 'Generere delt element ID';
	@override String get sharedLibraryId => 'Delte bibliotek ID (alternativt)';
	@override String get sharedLibraryHelp => 'Bruk den samme ID på enheter som åpner samme bibliotek. Denne offentlige ID hjelper med å føre lesing fremskritt og notater gjennom ulike kildeforbindelser; det er ikke et passord. Når leverandører bruker forskjellige elementer ID, par disse elementene fra detaljskjermene sine.';
	@override String get sharedLibraryInvalid => 'Bruk 8–100 bokstaver, tall, poeng, underscore eller hyphens.';
	@override String get generateSharedLibraryId => 'Generere en delt bibliotek ID';
	@override String get nfsReadAhead => 'NFS Les-ahead forespørsler';
	@override String get nfsReadAheadHelp => 'Flere parallelle lesinger kan forbedre gjennomgangen på en rask NAS eller nettverk. Bruk 1 hvis serveren begrenser samtidige forespørsler.';
	@override String get nfsReadTest => 'NFS leser ytelse';
	@override String get nfsReadTestHelp => 'Leser opp til 64 MiB fra den største filen for å måle denne NAS-tilkoblingen.';
	@override String get nfsQualificationResult => 'NFS leser måling';
	@override String get nfsReadBytes => 'Data leses';
	@override String get nfsReadSpeed => 'Målt hastighet';
	@override String get nfsReadRequests => 'Les forespørsler';
	@override String get sharedEntryConflict => 'Denne delte element ID er allerede parert med et annet element i denne biblioteket.';
}

// Path: comics
class _Translations$comics$nb extends Translations$comics$en {
	_Translations$comics$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get fitHeight => 'Tilpass høyden';
	@override String get readingMode => 'Lesemodus';
	@override String get paged => 'Sider';
	@override String get webtoon => 'Kontinuerlig rulling';
	@override String get coverAlone => 'Vis omslaget alene';
	@override String get splitWide => 'Del brede sider';
	@override String get splitWideHelp => 'Vis hver halvdel separat i leserekkefølge. Visning av to sider sammen settes på pause mens dette er slått på.';
	@override String get thumbnails => 'Sideminiatyrer';
	@override String get controlsHelp => 'Sveip for å bla. Trykk to ganger for å endre tilpasning. Ved kontinuerlig rulling sveiper du loddrett eller bruker Page Up og Page Down.';
	@override String get savedForComic => 'Visningsinnstillingene huskes for denne tegneserien i denne profilen.';
	@override String get readLists => 'Leselister';
	@override String get collections => 'Samlinger';
}

// Path: games
class _Translations$games$nb extends Translations$games$en {
	_Translations$games$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Games';
	@override String get enable => 'Show Games for this profile';
	@override String get enableDescription => 'Discover your gaming computers and play with an embedded streaming engine.';
	@override String get subtitle => 'Your games, from your computers.';
	@override String get computers => 'Your computers';
	@override String get nearby => 'Nearby computers';
	@override String get findComputers => 'Find computers';
	@override String get addComputer => 'Add computer';
	@override String get scanHint => 'Keep Steam Remote Play or Sunshine running on the same network. VPNs and guest networks may need a manual address.';
	@override String get empty => 'Add your gaming computer to get started.';
	@override String get noNearby => 'No computers found on this network. You can enter an address manually.';
	@override String get name => 'Computer name';
	@override String get address => 'IP address or hostname';
	@override String get port => 'Service port';
	@override String get protocol => 'Streaming service';
	@override String get moonlight => 'Sunshine / Moonlight';
	@override String get steam => 'Steam Remote Play';
	@override String get save => 'Save computer';
	@override String get invalidAddress => 'Enter a valid hostname or IP address, without a URL, and a port from 1 to 65534.';
	@override String get pair => 'Connect computer';
	@override String get pairTitle => 'Approve this device';
	@override String get pairInstructions => 'Enter this code in the host’s pairing prompt. For Sunshine, use the PIN page below. Keep this screen open until the computer approves.';
	@override String get pairHelp => 'Connect this computer again to approve or renew pairing.';
	@override String get openPairingPage => 'Open Sunshine PIN page';
	@override String get qrHelp => 'Scan to open the PIN page. The QR code contains only the computer address, never a password or pairing credential.';
	@override String get refreshGames => 'Refresh games';
	@override String get play => 'Play';
	@override String get recent => 'Recently opened';
	@override String get favorites => 'Favorites';
	@override String get allGames => 'All games';
	@override String get search => 'Find a game';
	@override String get noMatches => 'No games match this search.';
	@override String get favorite => 'Save favorite';
	@override String get unfavorite => 'Remove favorite';
	@override String get forget => 'Forget computer';
	@override String get forgetDescription => 'Remove this computer and its game shortcuts from this profile? To revoke this device’s authorization, remove it from the host’s paired devices.';
	@override String get unavailable => 'The connection could not complete. Check that the computer is awake and paired, then try again.';
	@override String get timeout => 'Connection timed out. Check the computer, pairing code and network before trying again.';
	@override String get libraryHint => 'Choose a computer to connect and load its games. Once connected, choose a game to play inside PlezyNG.';
	@override String get touchControls => 'On-screen controller';
	@override String get touchDescription => 'Show the native controller during a stream. It supports multiple fingers, sticks, buttons and triggers.';
	@override String get touchSetup => 'On-screen controls';
	@override String get touchSetupHint => 'Moonlight’s controller settings support position and opacity changes. During a Steam stream, open the stream menu to toggle its controller. Bluetooth or USB input is also supported.';
	@override String get addGame => 'Add game shortcut';
	@override String get gameName => 'Game name';
	@override String get gameId => 'Host application ID';
	@override String get invalidGame => 'Enter a game name and a positive numeric host application ID.';
	@override String get wake => 'Wake computer';
	@override String get wakeSent => 'Wake request sent. The computer must support Wake-on-LAN on this network.';
	@override String get mac => 'MAC address (optional)';
	@override String get help => 'Games help';
	@override String get helpBody => 'Enable Games for your profile, choose a computer and approve the first connection. Sunshine-compatible hosts load their app list into the game grid. On Android, Steam pairing opens Big Picture inside PlezyNG; saved Steam app-ID shortcuts launch directly. Steam pairing does not grant access to a private account library.\n\nBoth Android engines include touch controls and gamepad input. Pyrowave is an experimental Android option; other native platforms remain in development.\n\nPairing requires the host’s approval. Sunshine QR codes open its PIN page without carrying credentials. For access away from home, use the computer’s VPN address. Automatic discovery normally stays on the local network.\n\nDisconnecting leaves the game running on the computer.';
	@override String get cancel => 'Cancel';
	@override String get scanning => 'Looking for computers…';
	@override String get saveShortcut => 'Save shortcut';
	@override String get manualHint => 'For Moonlight use the host’s GameStream HTTP port (usually 47989), not its web settings port. Steam normally advertises on 27036.';
	@override String get engineUnavailable => 'In-app streaming is not available here yet';
	@override String get nativeEnginePending => 'This build does not include a streaming engine for this platform. You can save the computer, but it cannot play here yet.';
	@override String get steamEnginePending => 'This build does not include the embedded Steam engine. Android builds with Games enabled bundle device pairing and in-app H.264/HEVC playback. Pyrowave is experimental on Android; other platforms remain under development.';
	@override String get steamBetaTitle => 'Steam beta · Pyrowave';
	@override String get steamBetaDescription => 'Experimental Steam beta codec. Off by default; it uses 5–10× more bandwidth than H.264/HEVC, and Valve recommends gigabit Ethernet. Android playback is limited to SDR 4:2:0 with CPU readback and has not been device-qualified.';
	@override String get steamLibrary => 'Steam library';
	@override String get linkSteamAccount => 'Link Steam account';
	@override String get refreshSteamAccount => 'Refresh Steam account';
	@override String get unlinkSteamAccount => 'Unlink Steam account';
	@override String get unlinkSteamAccountConfirm => 'Remove this account and its imported catalog from this profile? Your paired computers and shortcuts stay available.';
	@override String get steamAccountLinked => 'Steam account linked. Games imported.';
	@override String get steamLibraryPrivate => 'Steam account linked. Its library is private or unavailable, so no games were imported.';
	@override String get steamAppId => 'Steam App ID';
	@override String get steamLibraryStale => 'Steam could not refresh the library. Showing the last available catalog.';
	@override String get steamLibraryTruncated => 'Showing up to 2,000 games. The Steam catalog was truncated.';
	@override String get connecting => 'Connecting…';
	@override String get disconnect => 'Disconnect';
	@override String get streamControls => 'Stream controls';
	@override String get steamPairInstructions => 'Enter this code in Steam’s Remote Play pairing prompt on your computer. Keep this screen open until Steam approves.';
	@override String get steamLibraryHint => 'Steam device pairing opens its library inside the stream. Add a shortcut with a Steam app ID for direct launch. Importing a private account library as game cards requires a separate authenticated catalog connection.';
}

// Path: deepLinks
class _Translations$deepLinks$nb extends Translations$deepLinks$en {
	_Translations$deepLinks$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get invalid => 'Denne linken til Plezy er ikke gyldig.';
	@override String profileNotFound({required Object profile}) => 'Ingen profil matcher "${profile}".';
	@override String get serverUnavailable => 'Kan ikke nå serveren for denne koblingen.';
	@override String get notFound => 'Du kan ikke finne denne tittelen i biblioteket ditt.';
	@override String get unsupportedItem => 'Denne linken kan ikke spilles.';
	@override String get noLiveTv => 'Ingen Live TV-server er tilgjengelig for denne koblingen.';
	@override String channelNotFound({required Object channel}) => 'Kan ikke finne kanal "${channel}".';
	@override String get showLink => 'Vis link';
	@override String get showProfileLink => 'Vis profil link';
	@override String get dialogTitle => 'Link';
	@override String get showHint => 'Åpne denne koblingen spiller neste episode. Legg til &mode=shuffle for å spille showet på shuffle.';
	@override String get movieHint => 'Åpning av denne koblingen spiller filmen.';
	@override String get episodeHint => 'Åpning av dette linket spiller denne episoden.';
	@override String get profileHint => 'Åpne denne koblingen skifter til denne profilen.';
	@override String openAsProfile({required Object name}) => 'Åpne som ${name}';
	@override String get copy => 'Kopierer';
	@override String get copied => 'Link kopieres';
}

// Path: appIcon.names
class _Translations$appIcon$names$nb extends Translations$appIcon$names$en {
	_Translations$appIcon$names$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get midnight => 'Midnatt';
	@override String get ember => 'Glød';
	@override String get paper => 'Papir';
	@override String get oled => 'OLED';
	@override String get line => 'Strek';
	@override String get ocean => 'Hav';
	@override String get ultraviolet => 'Ultrafiolett';
	@override String get matcha => 'Matcha';
	@override String get sunset => 'Solnedgang';
	@override String get gold => 'Gull';
	@override String get titanium => 'Titan';
	@override String get glass => 'Glass';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => 'Synthwave';
	@override String get pixel => 'Piksel';
	@override String get neon => 'Neon';
	@override String get sticker => 'Klistremerke';
	@override String get ticket => 'Billett';
	@override String get pop => 'Pop';
	@override String get strata => 'Sjikt';
	@override String get facet => 'Fasett';
	@override String get tilde => 'Tilde';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$nb extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get critic => 'Critics';
	@override String get audience => 'Audience';
	@override String get imdb => 'IMDb';
	@override String get tmdb => 'TMDB';
	@override String get rottenTomatoes => 'Rotten Tomatoes';
	@override String get simkl => 'Simkl';
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get trakt => 'Trakt';
	@override String get rottenTomatoesCritic => 'Rotten Tomatoes critics';
	@override String get rottenTomatoesAudience => 'Rotten Tomatoes audience';
	@override String get metacritic => 'Metacritic';
	@override String get letterboxd => 'Letterboxd';
}

// Path: common.mediaKind
class _Translations$common$mediaKind$nb extends Translations$common$mediaKind$en {
	_Translations$common$mediaKind$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get movie => 'Film';
	@override String get show => 'Serie';
	@override String get season => 'Sesong';
	@override String get episode => 'Episode';
	@override String get artist => 'Artist';
	@override String get album => 'Album';
	@override String get track => 'Spor';
	@override String get collection => 'Samling';
	@override String get playlist => 'Spilleliste';
	@override String get clip => 'Klipp';
	@override String get photo => 'Bilde';
	@override String get folder => 'Mappe';
}

// Path: settings.startupSectionOptions
class _Translations$settings$startupSectionOptions$nb extends Translations$settings$startupSectionOptions$en {
	_Translations$settings$startupSectionOptions$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get discover => 'Åpne anbefalinger og elementer fra tilknyttede oppdagelseskilder.';
	@override String get libraries => 'Åpne dine tilkoblede mediebiblioteker.';
	@override String get liveTv => 'Åpne Live TV når en server gir den; ellers faller oppstart tilbake til hjemmet.';
	@override String get search => 'Åpne medier søk.';
}

// Path: themeEditor.slots
class _Translations$themeEditor$slots$nb extends Translations$themeEditor$slots$en {
	_Translations$themeEditor$slots$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get bg => 'Bakgrunn';
	@override String get surface => 'Overflate';
	@override String get outline => 'Kontur';
	@override String get text => 'Tekst';
	@override String get textMuted => 'Sekundærtekst';
	@override String get accent => 'Aksent';
}

// Path: themeEditor.contrast
class _Translations$themeEditor$contrast$nb extends Translations$themeEditor$contrast$en {
	_Translations$themeEditor$contrast$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => 'Tekst på bakgrunn';
	@override String get textOnSurface => 'Tekst på overflate';
	@override String get textMutedOnBg => 'Sekundærtekst på bakgrunn';
	@override String get textMutedOnSurface => 'Sekundærtekst på overflate';
	@override String get accentOnBg => 'Aksent på bakgrunn';
	@override String get accentOnSurface => 'Aksent på overflate';
	@override String get labelOnAccent => 'Knappetekst på aksent';
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
	@override String get subtitleDelayIncrease => 'Forsink undertekster';
	@override String get subtitleDelayDecrease => 'Fremskynd undertekster';
	@override String get shaderToggle => 'Slå shadere av/på';
	@override String get skipMarker => 'Hopp over intro/rulletekst';
	@override String get screenshot => 'Ta skjermbilde';
	@override String get framePrevious => 'Forrige Frame';
	@override String get frameNext => 'Neste Frame';
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
	@override String get prepareFailed => 'Bilde-i-bilde kunne ikke forberedes';
	@override String unknown({required Object error}) => 'En feil oppstod: ${error}';
}

// Path: subtitlingStyling.assOverrideOptions
class _Translations$subtitlingStyling$assOverrideOptions$nb extends Translations$subtitlingStyling$assOverrideOptions$en {
	_Translations$subtitlingStyling$assOverrideOptions$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get no => 'Hold bokstaver, farger, størrelser og plassering skrevet i undertittelfilen.';
	@override String get yes => 'Tillat spillernes undertittelstilinnstillinger til å justere ASS-subtitler.';
	@override String get scale => 'Bruk spilleren styling og skala innebygde størrelser for å matche video dimensjonene.';
	@override String get force => 'Endre innebygde ASS-stiler med spillerens undertittelstil.';
	@override String get strip => 'Fjern innebygd ASS-formatering og gjengiv underteksten tydelig.';
}

// Path: subtitlingStyling.renderResolutionOptions
class _Translations$subtitlingStyling$renderResolutionOptions$nb extends Translations$subtitlingStyling$renderResolutionOptions$en {
	_Translations$subtitlingStyling$renderResolutionOptions$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get screen => 'Render på den fullstendige overflateoppløsningen for det skarpeste resultatet.';
	@override String get video => 'Render bruker videooppløsningen som referanse, noe som kan redusere arbeidet på høye oppløsningsskjermer.';
	@override String get threeQuarter => 'Render på 75% av skjermoverflatesolusjonen for en modest ytelsesbesparelse.';
	@override String get half => 'Render på 50% av skjermoverflateoppløsningen for å redusere arbeidet, med mykere edder.';
	@override String get third => 'Render på en tredjedel av skjermoverflateoppløsningen for å redusere arbeid, med mykere edder.';
	@override String get quarter => 'Render på en fjerdedel av display overflateoppløsningen for å redusere arbeid, med det mykeste resultatet.';
}

// Path: accountPreferences.groups
class _Translations$accountPreferences$groups$nb extends Translations$accountPreferences$groups$en {
	_Translations$accountPreferences$groups$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => 'Lyd og undertekster';
	@override String get libraryDisplay => 'Bibliotek';
	@override String get personalMedia => 'Personlige medier';
}

// Path: accountPreferences.subtitleModes
class _Translations$accountPreferences$subtitleModes$nb extends Translations$accountPreferences$subtitleModes$en {
	_Translations$accountPreferences$subtitleModes$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get none => 'Manuelt valgt';
	@override String get noneDescription => 'Slå aldri på undertekster av seg selv.';
	@override String get defaultMode => 'Følg sporflaggene';
	@override String get defaultModeDescription => 'Bruk standard- og tvunget-flaggene som er lagret på hvert undertekstspor.';
	@override String get always => 'Alltid aktivert';
	@override String get alwaysDescription => 'Slå på et undertekstspor på foretrukket språk når det finnes et.';
	@override String get onlyForced => 'Kun tvungne undertekster';
	@override String get onlyForcedDescription => 'Last inn bare sporene som er merket som tvungne.';
	@override String get smart => 'Vist med fremmedspråklig lyd';
	@override String get smartDescription => 'Slå på undertekster bare når lyden er på et annet språk.';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class _Translations$accountPreferences$subtitleAccessibilityOptions$nb extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	_Translations$accountPreferences$subtitleAccessibilityOptions$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'Foretrekk ikke-SDH-undertekster';
	@override String get preferSdh => 'Foretrekk SDH-undertekster';
	@override String get onlySdh => 'Kun SDH-undertekster';
	@override String get onlyNonSdh => 'Kun ikke-SDH-undertekster';
	@override String get preferNonSdhDescription => 'Foretrukker standard undertittel når både standard og SDH versjoner er tilgjengelige.';
	@override String get preferSdhDescription => 'De foretrekker SDH-subtitler når de er tilgjengelige, men tillater standard subtitler som en fallback.';
	@override String get onlySdhDescription => 'Bruk bare SDH-subtitler; ikke fall tilbake til standard subtitler.';
	@override String get onlyNonSdhDescription => 'Bruk bare standard undertitler; unngå SDH-subtitler.';
}

// Path: accountPreferences.forcedSubtitleOptions
class _Translations$accountPreferences$forcedSubtitleOptions$nb extends Translations$accountPreferences$forcedSubtitleOptions$en {
	_Translations$accountPreferences$forcedSubtitleOptions$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => 'Foretrekk ikke-tvungne undertekster';
	@override String get preferForced => 'Foretrekk tvungne undertekster';
	@override String get onlyForced => 'Kun tvungne undertekster';
	@override String get onlyNonForced => 'Kun ikke-tvungne undertekster';
	@override String get preferNonForcedDescription => 'Foretrakk regelmessige undertitler, men tillater tvunget spor som en fallback.';
	@override String get preferForcedDescription => 'De foretrekker tvungne spor når de er tilgjengelige, men tillater regelmessige undertitler som en fallback.';
	@override String get onlyForcedDescription => 'Bruk bare spor markerte som tvunget.';
	@override String get onlyNonForcedDescription => 'Utelukker spor markeret som tvunget.';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$nb extends Translations$accountPreferences$watchedIndicatorOptions$en {
	_Translations$accountPreferences$watchedIndicatorOptions$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get none => 'Aldri';
	@override String get moviesAndShows => 'Filmer og TV-serier';
	@override String get movies => 'Kun filmer';
	@override String get shows => 'Kun TV-serier';
	@override String get noneDescription => 'Ikke vise observerte sjekkmerker.';
	@override String get moviesAndShowsDescription => 'Vis sett sjekkmerker for filmer og TV-programmer.';
	@override String get moviesDescription => 'Se sjekkmerker for filmer bare.';
	@override String get showsDescription => 'Se seerte sjekkmerker for TV-serier bare.';
}

// Path: accountPreferences.mediaReviewsOptions
class _Translations$accountPreferences$mediaReviewsOptions$nb extends Translations$accountPreferences$mediaReviewsOptions$en {
	_Translations$accountPreferences$mediaReviewsOptions$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'Brukere og kritikere';
	@override String get usersOnly => 'Kun brukere';
	@override String get criticsOnly => 'Kun kritikere';
	@override String get nobody => 'Skjult';
	@override String get usersAndCriticsDescription => 'Vis både brukervurderinger og kritiske vurderinger.';
	@override String get usersOnlyDescription => 'Vis vurderinger og anmeldelser som er lagt fram av brukerne.';
	@override String get criticsOnlyDescription => 'Vis kritiske vurderinger og anmeldelser.';
	@override String get nobodyDescription => 'Skjære vurderinger og anmeldelser.';
}

// Path: discover.findNext
class _Translations$discover$findNext$nb extends Translations$discover$findNext$en {
	_Translations$discover$findNext$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Finn din neste favoritt';
	@override String get open => 'Finn din neste favoritt';
	@override String get anyTime => 'Uansett varighet';
	@override String get timeAvailable => 'Hvor mye tid har du?';
	@override String get filters => 'Velg det som passer nå';
	@override String get watch => 'Se';
	@override String get listen => 'Lytt';
	@override String get read => 'Les';
	@override String finishable({required Object duration}) => 'Kan fullføres på ${duration}';
	@override String aboutDuration({required Object duration}) => 'Omtrent ${duration}';
	@override String nextUnit({required Object duration}) => 'Neste kapittel · ${duration}';
	@override String totalDuration({required Object duration}) => '${duration} totalt';
	@override String get timingVaries => 'Varigheten kan variere';
	@override String get notNow => 'Ikke nå';
	@override String get swipeHint => 'Sveip omslaget mot en pil, eller bruk knappene nedenfor.';
	@override String get saved => 'Lagrede forslag';
	@override String savedCount({required Object count}) => 'Lagrede forslag · ${count}';
	@override String get undo => 'Angre';
	@override String get details => 'Detaljer';
	@override String get noPicks => 'Det er ikke noe å velge mellom ennå';
	@override String get noPicksHint => 'Koble til et bibliotek eller legg til en mediekilde for å komme i gang.';
	@override String get noMatches => 'Ingenting passer akkurat nå';
	@override String get noMatchesHint => 'Prøv en annen medietype, eller sett av mer tid.';
	@override String get allDone => 'Du har sett alle forslagene';
	@override String get allDoneHint => 'Start et nytt utvalg for å se disse forslagene igjen.';
	@override String get refresh => 'Finn et nytt utvalg';
	@override String sourceReason({required Object source}) => 'Fra ${source}';
	@override String libraryReason({required Object library}) => 'Fra ${library}';
	@override String get ownedReason => 'Fra biblioteket ditt';
	@override String get liveNow => 'Sendes nå';
	@override String get watchLive => 'Se direkte';
	@override String get filterAnything => 'Hva som helst';
	@override String get filterWatch => 'Se';
	@override String get filterListen => 'Lytt';
	@override String get filterRead => 'Les';
	@override String get twentyMinutes => '20 min';
	@override String get fortyFiveMinutes => '45 min';
	@override String get ninetyMinutes => '90 min';
	@override String get apply => 'Bruk';
	@override String get openFailed => 'Dette valget er ikke lenger tilgjengelig. Oppdater for å sjekke på nytt.';
	@override String get changeFailed => 'Kunne ikke lagre endringen. Prøv igjen.';
	@override String get savedLimit => 'Listen over lagrede forslag er full. Fjern et forslag for å lagre et nytt.';
	@override String get chooseHint => 'Åpne en tittel, lagre den til senere eller hopp over den.';
	@override String get howItWorks => 'Slik fungerer det';
	@override String get notNowHelp => 'Hopp over denne tittelen foreløpig. Den blir i biblioteket ditt.';
	@override String get saveHelp => 'Lagre den under lagrede valg for denne profilen på denne enheten. Lagring laster ikke ned tittelen.';
	@override String get openHelp => 'Velg omslaget for detaljer. Bruk hovedhandlingen til å spille av, lese eller åpne tittelen.';
	@override String get controlsHelp => 'Tastatur eller fjernkontroll: velg en knapp, og trykk Enter eller Velg. Angre gjenoppretter det siste valget ditt.';
	@override String get artworkLoading => 'Laster bilde…';
	@override String get artworkUnavailable => 'Bilde utilgjengelig';
	@override String get savedFeedback => 'Lagt til i lagrede valg';
	@override String get skippedFeedback => 'Hoppet over foreløpig';
	@override String get releaseToConfirm => 'Slipp for å bekrefte';
	@override String get remoteHint => 'Omslag i fokus: ← / → velg · Velg: detaljer · ↑ / ↓ flytt fokus';
}

// Path: discover.person
class _Translations$discover$person$nb extends Translations$discover$person$en {
	_Translations$discover$person$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get born => 'Født';
	@override String get died => 'Død';
	@override String get birthplace => 'Fødested';
	@override String dateWithAge({required Object date, required Object age}) => '${date} (${age} år)';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (${age} år gammel)';
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
	@override String get tag => 'Tagg';
	@override String get unwatched => 'Usette';
	@override String get unplayed => 'Ikke avspilt';
	@override String get favorites => 'Favoritter';
	@override String get filePath => 'Filbane';
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
	@override String get dateDownloaded => 'Dato lastet ned';
	@override String get size => 'Størrelse';
	@override String get library => 'Bibliotek';
}

// Path: libraries.advancedFilters
class _Translations$libraries$advancedFilters$nb extends Translations$libraries$advancedFilters$en {
	_Translations$libraries$advancedFilters$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get include => 'Inkluder';
	@override String get exclude => 'Ekskluder';
	@override String get any => 'Uansett';
	@override String get yes => 'Ja';
	@override String get no => 'Nei';
	@override String not({required Object value}) => 'Ikke ${value}';
	@override String valueCount({required Object count}) => '${count} valgt';
	@override String valueCountExcluded({required Object count}) => '${count} ekskludert';
	@override String get searchValues => 'Søk etter verdier';
	@override String get noValues => 'Ingen verdier';
	@override String get matchContains => 'Inneholder';
	@override String get matchNotContains => 'Inneholder ikke';
	@override String get matchIs => 'Er';
	@override String get matchIsNot => 'Er ikke';
	@override String get matchBeginsWith => 'Begynner med';
	@override String get matchEndsWith => 'Slutter med';
	@override String get textHint => 'Skriv inn tekst';
	@override String get from => 'Fra';
	@override String get to => 'Til';
	@override String range({required Object from, required Object to}) => '${from} til ${to}';
	@override String atLeast({required Object value}) => '${value} og over';
	@override String atMost({required Object value}) => 'Opptil ${value}';
	@override String dateLastDays({required Object count}) => 'Siste ${count} dager';
	@override String get dateLastYear => 'Siste år';
	@override String dateOlderThanDays({required Object count}) => 'Eldre enn ${count} dager';
	@override String get dateOlderThanYear => 'Eldre enn ett år';
}

// Path: libraries.selection
class _Translations$libraries$selection$nb extends Translations$libraries$selection$en {
	_Translations$libraries$selection$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get selectItems => 'Velg elementer';
	@override String selectedCount({required Object count}) => '${count} valgt';
	@override String get actions => 'Seleksjonshandlinger';
	@override String get confirmDescendants => 'Dette endrer alle episoder i de utvalgte showene og sesongene.';
	@override String get confirmUnwatched => 'Dette nullstiller også avspillingsfremdriften for de valgte elementene.';
	@override String confirmCount({required Object count}) => 'Velg elementer: ${count}.';
	@override String completed({required Object count}) => 'Oppdaterte elementer: ${count}.';
	@override String partialFailure({required Object succeeded, required Object failed}) => 'Oppdatert ${succeeded}; mislyktes ${failed}. mislyktede elementer forblir valgt.';
}

// Path: explore.mdblistShelves
class _Translations$explore$mdblistShelves$nb extends Translations$explore$mdblistShelves$en {
	_Translations$explore$mdblistShelves$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get manage => 'Utforsk skjeletter';
	@override String get manageDescription => 'Velg og ordne oppføringer fra kontoen din MDBList';
	@override String get description => 'Velg offentlige film- og TV-lister fra kontoen din MDBList. opprette eller kopiere lister på MDBList, og oppdater deretter.';
	@override String get selected => 'Velg skjelett';
	@override String get available => 'Tilgjengelige kontoer';
	@override String get noLists => 'Ingen offentlig film eller TV-lister returneres. opprette eller kopiere en liste på MDBList, og oppdater deretter.';
	@override String get displayName => 'Shelf Display navn';
	@override String get nameHint => 'La det være å bruke kildelistenavnet.';
	@override String get add => 'Legg til shelf';
	@override String get save => 'Sparer shelter';
	@override String moveUp({required Object title}) => 'Flytte ${title} opp';
	@override String moveDown({required Object title}) => 'Flytte ${title} ned';
	@override String get unavailable => 'Denne listen er ikke tilgjengelig. Retur eller fjerne skjoldet i innstillinger.';
	@override String get rateLimited => 'MDBList forespørselsgrense er nådd. vennligst trekke tilbake senere.';
	@override String get loadFailed => 'Kan ikke laste opp skjermer. sjekk koblingen din og tilbakekall.';
	@override String get saveFailed => 'Kan ikke spares, så snill tilbake.';
	@override String get accountChanged => 'Konto eller profil endret. Åpne disse innstillingene igjen.';
	@override String get settingsUnreadable => 'Spare skjermer kan ikke leses. Velg listen din igjen for å erstatte disse innstillingene.';
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
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} kommentar',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} kommentarer',
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
	@override String get actor => 'Skuespiller';
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
	@override String get prequel => 'Forløper';
	@override String get sequel => 'Oppfølger';
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
		one: 'Anbefalt av ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} bruker',
		other: 'Anbefalt av ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} brukere',
	);
	@override String recommendedBy({required Object who}) => 'Anbefalt av ${who}';
	@override String favoritedBy({required Object who}) => 'Favorisert av ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} har ikke blitt sendt ennå';
	@override String recommendedByPercent({required Object percent}) => 'Anbefalt av ${percent} av seerne';
	@override String get relatedTitles => 'Relaterte titler';
	@override String get background => 'Bakgrunn';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$nb extends Translations$liveTv$recordSettings$en {
	_Translations$liveTv$recordSettings$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get startEarly => 'Start tidligere (sekunder)';
	@override String get endLate => 'Slutt senere (sekunder)';
	@override String get newOnly => 'Bare nye episoder';
	@override String get anyChannel => 'Ta opp på alle kanaler';
	@override String get anyTime => 'Ta opp når som helst';
	@override String get skipInLibrary => 'Hopp over episoder som allerede finnes i biblioteket';
	@override String get keepUpTo => 'Episoder som skal beholdes';
	@override String get keepUpToHint => '0 beholder alle episoder';
}

// Path: music.discography
class _Translations$music$discography$nb extends Translations$music$discography$en {
	_Translations$music$discography$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'Singler og EP-er';
	@override String get live => 'Live';
	@override String get compilations => 'Samlealbum';
}

// Path: watchTogether.notices
class _Translations$watchTogether$notices$nb extends Translations$watchTogether$notices$en {
	_Translations$watchTogether$notices$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name} trykket på spill av';
	@override String get playbackStarted => 'Avspillingen startet';
	@override String paused({required Object name}) => '${name} satte avspillingen på pause';
	@override String get playbackPaused => 'Avspillingen ble satt på pause';
	@override String jumpedTo({required Object name, required Object position}) => '${name} hoppet til ${position}';
	@override String roomJumpedTo({required Object position}) => 'Hoppet til ${position}';
	@override String changedSpeed({required Object name, required Object speed}) => '${name} satte hastigheten til ${speed}';
	@override String speedChanged({required Object speed}) => 'Hastigheten satt til ${speed}';
	@override String startedMedia({required Object name, required Object title}) => '${name} startet ${title}';
	@override String mediaStarted({required Object title}) => 'Spilles nå: ${title}';
	@override String stoppedMedia({required Object name}) => '${name} stoppet videoen';
	@override String get mediaStopped => 'Videoen stoppet';
	@override String waitingFor({required Object name}) => 'Venter på ${name}...';
	@override String get waitingForSomeone => 'Venter på at noen skal ta igjen...';
	@override String get finished => 'Ferdig';
	@override String hostChangedTo({required Object name}) => '${name} er nå verten';
	@override String get youAreNowHost => 'Du er nå verten';
	@override String joined({required Object name}) => '${name} ble med';
	@override String left({required Object name}) => '${name} forlot';
	@override String get controlRefused => 'Bare verten kan kontrollere avspillingen';
	@override String get searchFailed => 'Enkelte servere kunne ikke gjennomsøkes etter videoen i rommet';
	@override String get playBlocked => 'Trykk på spill av for å starte';
	@override String get shareFailed => 'Kunne ikke dele denne videoen med rommet';
	@override String get downloadNotShared => 'Nedlastinger deles ikke med rommet mens serveren deres er frakoblet';
	@override String get openFailed => 'Kunne ikke åpne videoen i rommet';
}

// Path: watchTogether.ended
class _Translations$watchTogether$ended$nb extends Translations$watchTogether$ended$en {
	_Translations$watchTogether$ended$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get ended => 'Verten avsluttet rommet';
	@override String get kicked => 'Du ble fjernet fra rommet';
	@override String get expired => 'Rommet er utløpt';
	@override String get replaced => 'Du ble med i dette rommet på en annen enhet';
	@override String get lost => 'Mistet tilkoblingen til rommet';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$nb extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => 'Det er ikke en romkode. Koder har 6 bokstaver og sifre, uten 0, 1, I, L eller O.';
	@override String get roomNotFound => 'Ingen rom har den koden. Det kan være avsluttet.';
	@override String get roomFull => 'Rommet er fullt.';
	@override String get roomLocked => 'Verten har låst rommet.';
	@override String get relayFull => 'Se sammen er opptatt akkurat nå. Prøv igjen senere.';
	@override String get unreachable => 'Kunne ikke nå reléserveren for Se sammen. Sjekk tilkoblingen.';
	@override String get rateLimited => 'For mange forsøk. Vent litt og prøv igjen.';
	@override String get clientBlocked => 'Denne versjonen av PlezyNG kan ikke bruke reléserveren. Oppdater appen.';
	@override String get forbidden => 'Bare verten kan gjøre det.';
	@override String get notInRoom => 'Du er ikke i et rom.';
	@override String get alreadyInRoom => 'Du er allerede i et rom.';
	@override String get resumeFailed => 'Kunne ikke bli med i rommet igjen.';
	@override String get unsupported => 'Reléserveren støtter ikke dette.';
	@override String get generic => 'Noe gikk galt. Prøv igjen.';
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
	@override String get sheetIntro => 'Android hindrer PlezyNG i å laste ned pålitelig i bakgrunnen.';
	@override String get sheetIntroDegraded => 'Enheten din begrenser når PlezyNG kan laste ned i bakgrunnen.';
	@override String get reasonBackgroundRestricted => 'Bakgrunnsbruken til PlezyNG er begrenset. Sett batteribruk eller bakgrunnsbruk til «Ubegrenset».';
	@override String get reasonStandbyRestricted => 'Android har satt PlezyNG i begrenset hvilemodus. Sett batteribruken til «Ubegrenset».';
	@override String get reasonDownloadChannelBlocked => 'Varsler om nedlastinger er slått av, så fremdrift og kontroller kan være utilgjengelige.';
	@override String get reasonNotificationsDisabled => 'Varsler er slått av. På Android 13 eller nyere kreves de for lange bakgrunnsnedlastinger.';
	@override String get reasonDataSaver => 'Datasparing er slått på og blokkerer bakgrunnsnedlastinger via mobildata. Nedlastinger skal fortsatt fungere på Wi-Fi.';
	@override String get reasonOemUnknown => 'Nedlastinger har stoppet gjentatte ganger mens PlezyNG var i bakgrunnen. Sjekk innstillingene for batteribruk eller bakgrunnsbruk for PlezyNG.';
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

// Path: downloads.groupings
class _Translations$downloads$groupings$nb extends Translations$downloads$groupings$en {
	_Translations$downloads$groupings$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get library => 'Bibliotek';
	@override String get collections => 'Samlinger';
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
	@override String get manualAddressHint => 'Manuell tilkoblingsadresse:';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$nb extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'PlezyNG-enheter med samme Plex-konto vises her';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Kobler til...';
	@override String get searchingForDevices => 'Søker etter enheter...';
	@override String get noDevicesFound => 'Ingen enheter funnet på nettverket ditt';
	@override String get noDevicesHint => 'Åpne PlezyNG på datamaskinen, og bruk samme Wi-Fi';
	@override String get availableDevices => 'Tilgjengelige enheter';
	@override String get manualConnection => 'Manuell tilkobling';
	@override String get cryptoInitFailed => 'Kunne ikke starte sikker tilkobling. Logg inn på Plex først.';
	@override String get validationHostRequired => 'Vennligst oppgi vertsadresse';
	@override String get validationHostFormat => 'Format må være IP:port (f.eks. 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Tilkoblingen fikk tidsavbrudd. Bruk samme nettverk på begge enheter.';
	@override String get sessionNotFound => 'Enhet ikke funnet. Sørg for at PlezyNG kjører på verten.';
	@override String get authFailed => 'Autentisering mislyktes. Begge enheter må bruke samme Plex-konto.';
	@override String failedToConnect({required Object error}) => 'Kunne ikke koble til: ${error}';
	@override String get codeTitle => 'Paring kode';
	@override String get codeDescription => 'Skriv inn koden som vises i Companion Remote på host-enheten.Båda enhetene må bruke en versjon som støtter sikker paring.';
	@override String get codeInvalid => 'Skriv inn alle 32 bokstaver og tall fra hostekoden.';
	@override String get updateRequired => 'Oppdater begge enhetene til en versjon som støtter sikker paring.';
	@override String get hostDescription => 'Skriv inn denne koden en gang på hver fjerntjeneste. Hold den privat: den gir kontroll over denne profilen.';
	@override String get resetCode => 'For å gjenopprette paring-koden';
	@override String get resetDescription => 'Slå av alle fjernet og opprette en ny kode. hver fjernet må parere igjen.';
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

// Path: services.simklReconnect
class _Translations$services$simklReconnect$nb extends Translations$services$simklReconnect$en {
	_Translations$services$simklReconnect$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Koble til Simkl på nytt';
	@override String get subtitle => 'Simkl avvikler påloggingsmetoden som denne tilkoblingen bruker. Når du kobler til på nytt, åpnes simkl.com slik at du kan godkjenne PlezyNG – PlezyNG ser aldri passordet ditt. Visningshistorikken din blir liggende på Simkl.';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$nb extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Aktiver PlezyNG på ${service}';
	@override String get instructions => 'Skann QR-koden, eller gå til adressen nedenfor og skriv inn denne koden:';
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
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$nb extends Translations$services$pendingAuth$en {
	_Translations$services$pendingAuth$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
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
	@override String get modeDescription => 'Velg om de sjekkede bibliotekene er blokkert fra synkronisering eller er det eneste biblioteket som synkroniserer.';
}

// Path: services.trackerDescriptions
class _Translations$services$trackerDescriptions$nb extends Translations$services$trackerDescriptions$en {
	_Translations$services$trackerDescriptions$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get trakt => 'Synkroniserte sett episoder og filmer med din Trakt konto.';
	@override String get mal => 'Synk anime-lister og se fremskritt med MyAnimeList.';
	@override String get anilist => 'Synkronisere anime-lister og se fremskritt med AniList.';
	@override String get simkl => 'Sync så filmer, TV-programmer og anime med Simkl.';
	@override String get mdblist => 'Vis MDBList-vurderinger og lister i anbefalinger og Utforsk.';
}

/// The flat map containing all translations for locale <nb>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsNb {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'appIcon.title' => 'Appikon',
			'appIcon.defaultIcon' => 'Standard',
			'appIcon.current' => 'Gjeldende ikon',
			'appIcon.locked' => 'Livslang tilgang kreves',
			'appIcon.lockedHint' => 'Start 7-dagers prøvetur eller avlokk PlezyNG for livet for å bruke alternative ikoner.',
			'appIcon.changeFailed' => 'Kunne ikke endre appikonet',
			'appIcon.launcherHint' => 'Det nye ikonet vises på startskjermen når du forlater PlezyNG.',
			'appIcon.tvLauncherHint' => 'Det nye banneret vises når du forlater PlezyNG. Android TV kan fortsette å vise det gamle til TV-en startes på nytt.',
			'appIcon.names.midnight' => 'Midnatt',
			'appIcon.names.ember' => 'Glød',
			'appIcon.names.paper' => 'Papir',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => 'Strek',
			'appIcon.names.ocean' => 'Hav',
			'appIcon.names.ultraviolet' => 'Ultrafiolett',
			'appIcon.names.matcha' => 'Matcha',
			'appIcon.names.sunset' => 'Solnedgang',
			'appIcon.names.gold' => 'Gull',
			'appIcon.names.titanium' => 'Titan',
			'appIcon.names.glass' => 'Glass',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => 'Synthwave',
			'appIcon.names.pixel' => 'Piksel',
			'appIcon.names.neon' => 'Neon',
			'appIcon.names.sticker' => 'Klistremerke',
			'appIcon.names.ticket' => 'Billett',
			'appIcon.names.pop' => 'Pop',
			'appIcon.names.strata' => 'Sjikt',
			'appIcon.names.facet' => 'Fasett',
			'appIcon.names.tilde' => 'Tilde',
			'appIcon.description' => 'Velg ikonet som vises av enhetslungeren din. Forhåndsvisningene viser hvordan hver alternativ ser ut.',
			'auth.signInWithPlex' => 'Logg inn med Plex',
			'auth.showQRCode' => 'Vis QR-kode',
			'auth.authenticate' => 'Autentiser',
			'auth.authenticationTimeout' => 'Autentiseringen tok for lang tid. Prøv igjen.',
			'auth.scanQRToSignIn' => 'Skann denne QR-koden for å logge inn',
			'auth.waitingForAuth' => 'Venter på autentisering...\nLogg inn fra nettleseren.',
			'auth.useBrowser' => 'Bruk nettleser',
			'auth.or' => 'eller',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'Koble til ${product}',
			'auth.quickConnect' => 'Quick Connect',
			'auth.useQuickConnect' => 'Bruk Quick Connect',
			'auth.quickConnectInstructions' => 'Åpne Quick Connect i Jellyfin og skriv inn denne koden.',
			'auth.quickConnectWaiting' => 'Venter på godkjenning…',
			'auth.quickConnectCancel' => 'Avbryt',
			'auth.quickConnectExpired' => 'Quick Connect er utløpt. Prøv igjen.',
			'auth.localDataRecoveryRequired' => 'PlezyNG kunne ikke gjenopprette lokale innloggingsdata og ventende avspillingsdata på en sikker måte. Logg inn på nytt.',
			'auth.pinCheckRejected' => 'Kontrollen av Plex-PIN-koden ble avvist',
			'auth.connectToDirectPlex' => 'Koble til lokal server Plex',
			'common.cancel' => 'Avbryt',
			'common.save' => 'Lagre',
			'common.close' => 'Lukk',
			'common.closeMiniPlayer' => 'Nær Mini-spillere',
			'common.closeWorkspaceWindow' => 'Nær vindu',
			'common.returnToFullView' => 'Tilbake til Full View',
			'common.manageMediaSessions' => 'Ledelse av media sesjoner',
			'common.hideMediaSessions' => 'Skjære mediekonferanser',
			'common.mediaSessions' => 'Media sesjoner',
			'common.mediaSessionsHint' => 'Velg for å bringe en sesjon fremover. Park skjuler vinduet, men holder det åpent. Return åpner den i full visning; nær slutter den.',
			'common.sessionInWorkspace' => 'På arbeidsplassen',
			'common.sessionParked' => 'Parkert',
			'common.sessionFullscreen' => 'Full skjerm',
			'common.switchToNextWindow' => 'Swap med neste vindu',
			'common.moveWindow' => 'Flytte vindu',
			'common.finishMovingWindow' => 'Slutt å flytte vindu',
			'common.moveWindowHint' => 'Lang press og trekk vinduet for å bevege det. Denne kontrollen tillater også armbånd-nøkkelbevegelse.',
			'common.movingWindowHelp' => 'Dra til bevegelse · Slå nøkler justere · Enter sparer · Escape annullerer',
			'common.resizeWindow' => 'Åpne vinduet',
			'common.resizeWindowHint' => 'Dra denne håndboken eller bruk våpennøkler for å revidere vinduet.',
			'common.workspaceWindowHint' => 'Bruk bevegelseskontroller eller langpress og trekk for å flytte.',
			'common.workspacePaneHint' => 'Velg dette panelet for å fokusere på det. Bruk fullskjermkontrollen for å utvide den.',
			'common.workspaceWindowLabel' => ({required Object title}) => 'Sesjon vindu: ${title}',
			'common.workspaceTitleHint' => 'Velg for å fokusere. Dra overskriftsfältet for å flytte; bruk fullskjermknappen for å utvide.',
			'common.moveToSessionTray' => 'Flytt til sesjon trey',
			'common.moveToSessionTrayHint' => 'Keeps denne sesjonen tilgjengelig uten å vise vinduet.',
			'common.closeSessionHint' => 'Stenger dette vinduet og avsluttes sesjonen.',
			'common.sideBySideLayout' => 'Switch til side-by-side layout',
			'common.floatingWindows' => 'Switch til å flyte vinduene',
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
			'common.options' => 'Valg',
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
			'common.ratingSource.critic' => 'Critics',
			'common.ratingSource.audience' => 'Audience',
			'common.ratingSource.imdb' => 'IMDb',
			'common.ratingSource.tmdb' => 'TMDB',
			'common.ratingSource.rottenTomatoes' => 'Rotten Tomatoes',
			'common.ratingSource.simkl' => 'Simkl',
			'common.ratingSource.mal' => 'MyAnimeList',
			'common.ratingSource.anilist' => 'AniList',
			'common.ratingSource.trakt' => 'Trakt',
			'common.ratingSource.rottenTomatoesCritic' => 'Rotten Tomatoes critics',
			'common.ratingSource.rottenTomatoesAudience' => 'Rotten Tomatoes audience',
			'common.ratingSource.metacritic' => 'Metacritic',
			'common.ratingSource.letterboxd' => 'Letterboxd',
			'common.notAvailable' => 'I/T',
			'common.url' => 'URL',
			'common.letterKeys' => 'ABC',
			'common.mediaKind.movie' => 'Film',
			'common.mediaKind.show' => 'Serie',
			'common.mediaKind.season' => 'Sesong',
			'common.mediaKind.episode' => 'Episode',
			'common.mediaKind.artist' => 'Artist',
			'common.mediaKind.album' => 'Album',
			'common.mediaKind.track' => 'Spor',
			'common.mediaKind.collection' => 'Samling',
			'common.mediaKind.playlist' => 'Spilleliste',
			'common.mediaKind.clip' => 'Klipp',
			'common.mediaKind.photo' => 'Bilde',
			'common.mediaKind.folder' => 'Mappe',
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
			'settings.supportDeveloper' => 'Støtt PlezyNG',
			'settings.supportDeveloperDescription' => 'Doner for å støtte utviklingen',
			'settings.lifetimeAccess' => 'PlezyNG Livslang tilgang',
			'settings.language' => 'Språk',
			'settings.theme' => 'Tema',
			'settings.appearance' => 'Utseende',
			'settings.detailPage' => 'Detail side',
			'settings.themeSongsEnabled' => 'Spille tema sanger',
			'settings.themeSongsEnabledDescription' => 'Spill tilgjengelige tema sanger mens du ser media detaljer.',
			'settings.themeSongVolume' => 'Tema sang volum',
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
			'settings.emberTheme' => 'Glød',
			'settings.glacierTheme' => 'Isbre',
			'settings.forestTheme' => 'Skog',
			'settings.plumTheme' => 'Plomme',
			'settings.paperTheme' => 'Papir',
			'settings.libraryDensity' => 'Innholdstetthet i biblioteket',
			'settings.displayScale' => 'Skalering',
			'settings.compact' => 'Kompakt',
			'settings.comfortable' => 'Komfortabel',
			'settings.gridSpacing' => 'Rutenettavstand',
			'settings.gridSpacingTight' => 'Tett',
			'settings.gridSpacingNormal' => 'Normal',
			'settings.gridSpacingSpacious' => 'Rommelig',
			'settings.tvCornerSpotlightBackdrop' => 'Fremhevet bakgrunn i hjørnet',
			'settings.tvCornerSpotlightBackdropDescription' => 'Vis fremhevet grafikk øverst til høyre i stedet for å fylle skjermen',
			'settings.viewMode' => 'Visningsmodus',
			'settings.gridView' => 'Rutenett',
			'settings.listView' => 'Liste',
			'settings.showHeroSection' => 'Vis fremhevet seksjon',
			'settings.showHomeBackdrop' => 'Vis hjem bakgrunns kunstverk',
			'settings.showHomeBackdropDescription' => 'Vis store kunstverk bak featured Home rader',
			'settings.contentScreensaverEnabled' => 'Innhold Screensaver',
			'settings.contentScreensaverEnabledDescription' => 'Vis fullskjerm kunstverk etter at appen har vært idle',
			'settings.contentScreensaverDelay' => 'Start skjermbeskyttelse etter',
			'settings.contentScreensaverLibraries' => 'Skjermbiblioteker',
			'settings.contentScreensaverLibrariesDescription' => 'Velg hvilke biblioteker som skal levere bilder til skjermspareren. Hvis ingen velges, brukes bilder fra alle biblioteker.',
			'settings.contentScreensaverAllLibraries' => 'Alle biblioteker',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} utvalgte bibliotek',
			'settings.contentScreensaverNoLibraries' => 'Ingen tilkoblet mediebibliotek er tilgjengelig.',
			'settings.contentScreensaverDismissHint' => 'Trykk på noen knapp eller trykk for å avvise',
			'settings.newEpisodeNotifications' => 'Ny episode av meldinger',
			'settings.newEpisodeNotificationsDescription' => 'Varsel når en ny episode blir lagt til en show du er fanget opp på. sjekker mens Plezy er åpen.',
			'settings.continueWatchingRowSize' => 'Fortsett å se på størrelsen på raden',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => '${label} kort',
			'settings.rowSizeCompact' => 'Kompakt',
			'settings.rowSizeStandard' => 'Standard',
			'settings.rowSizeLarge' => 'Stor',
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
			'settings.showWatchedIndicators' => 'Vis sett-indikatorer',
			'settings.showWatchedIndicatorsDescription' => 'Vis et hakemerke på sette filmer, serier og episoder',
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
			'settings.playbackBuffer' => 'Avspillingsbuffer',
			'settings.playbackBufferAuto' => 'Auto (anbefalt)',
			'settings.playbackBufferLarge' => 'Stor',
			'settings.playbackBufferExtraLarge' => 'Ekstra stor',
			'settings.playbackBufferDescription' => 'Bufrer mer mot ustabile tilkoblinger. Begrenses også av bufferstørrelsen.',
			'settings.streamBufferSize' => 'Buffer størrelse',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} MB',
			'settings.streamBufferSizeDescription' => 'Hvor mye video å laste frem når du spiller direkte. transkoder stopper på serverens egen transkodebufert. 0 = Auto',
			'settings.streamBufferSizeExoNote' => 'Replaser Playback Buffer når du setter inn, kappet til halvparten av appens minnegrense',
			'settings.streamBufferMegabytes' => 'Megabytes',
			'settings.defaultQualityTitle' => 'Standardkvalitet',
			'settings.cellularQualityTitle' => 'Standardkvalitet på mobilnett',
			'settings.remoteQualityTitle' => 'Kvalitet på fjernstrømning',
			'settings.remoteQualitySameAsDefault' => 'Det samme som standard kvalitet',
			'settings.cellularQualitySameAsDefault' => 'Samme som standardkvalitet',
			'settings.directPlayCoveredQuality' => 'Spill mindre videoer i original kvalitet',
			'settings.directPlayCoveredQualityDescription' => 'Spill av videoer som allerede er innenfor kvalitetsgrensen med Direct Play i stedet for å transkode dem',
			'settings.videoCodecs' => 'Videokodeker',
			'settings.videoCodecsDescription' => 'Kodeker uten hake transkodes av serveren',
			'settings.videoCodecsAlwaysAccepted' => 'Godtas alltid',
			'settings.musicQualityTitle' => 'Musikkvalitet',
			'settings.subtitleStyling' => 'Undertekststil',
			'settings.subtitleStylingDescription' => 'Tilpass utseendet på undertekster',
			'settings.smallSkipDuration' => 'Kort hoppvarighet',
			'settings.largeSkipDuration' => 'Lang hoppvarighet',
			'settings.rewindOnResume' => 'Spol tilbake ved gjenopptakelse',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(seconds, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} sekund', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} sekunder', ), 
			'settings.defaultSleepTimer' => 'Standard innsovningstimer',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(minutes, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutt', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutter', ), 
			'settings.rememberTrackSelections' => 'Husk sporvalg per serie/film',
			'settings.chooseTracksBeforePlayback' => 'Velg lyd og undertittel før spilling',
			'settings.chooseTracksBeforePlaybackDescription' => 'Velg opp kildekode og undertittelspor før hver video starter.',
			'settings.alwaysShowSubtitlesOnDevice' => 'Vis alltid undertittel på denne enheten',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => 'Når serveren ikke har noen undertittel valgt, velg en spor lokalt. Dette endrer aldri serverens foretrukning.',
			'settings.autoDownloadPreferredSubtitle' => 'Fettch savner foretrukne undertittel',
			'settings.autoDownloadPreferredSubtitleDescription' => 'Velg et tilgjengelig undertittel på ditt foretrukne språk lokalt. Hvis det ikke finnes noe, be serveren om å få et når det støttes.',
			'settings.rememberTrackSelectionsDescription' => 'Husk lyd- og undertekstvalg per tittel',
			'settings.rememberTrackSelectionsBackendRule' => 'Plex lagrer hvert valg på serveren per fil; Jellyfin slår også på kontoinnstillingen «Husk valg»; Emby støttes ikke',
			'settings.followServerTrackSelections' => 'Bruk serverens sporvalg per episode',
			'settings.followServerTrackSelectionsDescription' => 'Ved episodebytte brukes lyden og undertekstene som er valgt på serveren, i stedet for å videreføre gjeldende valg',
			'settings.resumeMusicOnLaunch' => 'Husk musikkøkt',
			'settings.resumeMusicOnLaunchDescription' => 'Åpne den siste sangen på pause der den slapp når appen starter',
			'settings.showChapterMarkersOnTimeline' => 'Vis kapittelmarkører på tidslinjen',
			'settings.showChapterMarkersOnTimelineDescription' => 'Del tidslinjen ved kapittelgrenser',
			'settings.specialsOrdering' => 'Spesialepisoder i episoderekkefølge',
			'settings.specialsOrderingDescription' => 'Hvor spesialepisoder spilles av i seriens visningsrekkefølge',
			'settings.specialsOrderingServer' => 'Følg serverrekkefølgen',
			'settings.specialsOrderingAirDate' => 'Flett inn etter premieredato',
			'settings.specialsOrderingLast' => 'Etter vanlige sesonger',
			'settings.clickVideoTogglesPlayback' => 'Klikk på video for å veksle avspilling',
			'settings.clickVideoTogglesPlaybackDescription' => 'Klikk på video for å spille av/pause i stedet for å vise kontroller.',
			'settings.videoPlayerControls' => 'Videospillerkontroller',
			'settings.keyboardShortcuts' => 'Tastatursnarveier',
			'settings.keyboardShortcutsDescription' => 'Tilpass tastatursnarveier',
			'settings.videoPlayerNavigation' => 'Videospillernavigering',
			'settings.videoPlayerNavigationDescription' => 'Bruk piltaster for å navigere videospillerkontroller',
			'settings.watchTogetherRelay' => 'Reléserver for Se sammen',
			'settings.watchTogetherRelayDescription' => 'Offentlige Open Watch Party-reléservere, med mindre du angir din egen',
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
			'settings.importSettingsInvalidFile' => 'Denne filen er ikke en gyldig PlezyNG-innstillingseksport',
			'settings.importSettingsNoUser' => 'Logg inn før import av innstillinger',
			'settings.cloudBackup' => 'Sikkerhetskopi i skyen',
			'settings.cloudBackupDescription' => 'Sikkerhetskopier innstillinger som kan overføres, til en WebDAV-adresse via HTTPS. Servertilkoblinger og påloggingsinformasjon blir på denne enheten.',
			'settings.cloudBackupUrl' => 'WebDAV JSON fil URL',
			'settings.cloudBackupUsername' => 'Brukernavn',
			'settings.cloudBackupPassword' => 'Passord',
			'settings.cloudBackupSaved' => 'Cloud backup destinasjon reddet',
			'settings.cloudBackupNow' => 'Tilbake nå',
			'settings.cloudBackupComplete' => 'Oppdatering av Backup upload',
			'settings.cloudBackupRestore' => 'Åpne backup',
			'settings.cloudBackupRestoreConfirm' => 'Dette vil erstatte matching bærbare innstillinger på denne enheten.',
			'settings.cloudBackupRestored' => 'Innstillinger gjenopprettet fra cloud backup',
			'settings.shortcutsReset' => 'Snarveier tilbakestilt til standard',
			'settings.resetShortcutsConfirm' => 'Dette vil erstatte de egendefinerte snarveiene dine med standardsnarveiene. Fortsette?',
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
			'settings.autoPlayAndSkip' => 'Autospill og hopp',
			'settings.autoPlayNextEpisode' => 'Spill neste episode automatisk',
			'settings.autoPlayNextEpisodeDescription' => 'Start neste episode automatisk når en episode er ferdig',
			'settings.shuffleStartsFromBeginning' => 'Tilfeldig avspilling starter fra begynnelsen',
			'settings.shuffleStartsFromBeginningDescription' => 'Start hver episode fra begynnelsen ved tilfeldig avspilling i stedet for å fortsette',
			'settings.plexCinemaPreRoll' => 'Bruker server kino intros',
			'settings.plexCinemaPreRollDescription' => 'Spille konfigurert Plex pre-rolls eller Jellyfin og Emby intros før en film starter.',
			'settings.playNextCountdown' => 'Nedtelling for neste episode',
			'settings.playNextCountdownImmediate' => 'Spill umiddelbart',
			'settings.skipIntroMode' => 'Hopp over intro',
			'settings.skipIntroModeOffDescription' => 'Spill av introer normalt uten en hopp over-knapp',
			'settings.skipIntroModeButtonDescription' => 'Vis en hopp over-knapp når en intro starter',
			'settings.skipIntroModeAutoDescription' => 'Hopp over introer automatisk etter forsinkelsen nedenfor',
			'settings.skipCreditsMode' => 'Hopp over rulletekst',
			'settings.skipCreditsModeOffDescription' => 'Spill av rulleteksten normalt uten en hopp over-knapp',
			'settings.skipCreditsModeButtonDescription' => 'Vis en hopp over-knapp når rulleteksten starter',
			'settings.skipCreditsModeAutoDescription' => 'Hopp over rulleteksten automatisk, og spill neste episode',
			'settings.skipAdsMode' => 'Hopp over reklame',
			'settings.skipAdsModeOffDescription' => 'Spill oppdagede annonser vanligvis uten en skip-knappe',
			'settings.skipAdsModeButtonDescription' => 'Vis en skip-knappe når Plex oppdager en annonsering',
			'settings.skipAdsModeAutoDescription' => 'Slå opp oppdagede annonser automatisk etter forsinkelsen nedenfor',
			'settings.musicPlayback' => 'Musikk Playback',
			'settings.musicSweetFades' => 'Sød fader',
			'settings.musicSweetFadesDescription' => 'Fade musikk på sporet når Plex har høyddata.',
			'settings.skipMarkerModeOff' => 'Av',
			'settings.skipMarkerModeButton' => 'Vis knapp',
			'settings.skipMarkerModeAuto' => 'Automatisk',
			'settings.forceSkipMarkerFallback' => 'Tving reservemarkører',
			'settings.forceSkipMarkerFallbackDescription' => 'Bruk mønstre i kapiteltitler selv når Plex har markører',
			'settings.theIntroDbFallback' => 'Bruk TheIntroDB som intro fallback',
			'settings.theIntroDbFallbackDescription' => 'Bruk fellesskapstidene bare når serveren ikke har intro markerer.',
			'settings.autoSkipDelay' => 'Forsinkelse for automatisk hopp',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Vent ${seconds} sekunder før automatisk hopping',
			'settings.introPattern' => 'Intromarkørmønster',
			'settings.introPatternDescription' => 'Regulært uttrykk for å gjenkjenne intromarkører i kapitteltitler',
			'settings.creditsPattern' => 'Rulletekstmarkørmønster',
			'settings.creditsPatternDescription' => 'Regulært uttrykk for å gjenkjenne rulletekstmarkører i kapitteltitler',
			'settings.prerolls' => 'Forhåndsvideoer',
			'settings.playPrerollsBeforeMovies' => 'Spill prorroller før filmer',
			'settings.playPrerollsBeforeMoviesDescription' => 'Spille en tilfeldig klipp fra valget nedenfor før hver film. Trykk tilbake for å hoppe.',
			'settings.prerollLibrary' => 'Preroll bibliotek',
			'settings.prerollLibraryNotSet' => 'Ikke angitt',
			'settings.prerollLibraryNoneFound' => 'Ingen biblioteker finnes på servere.',
			'settings.prerollSelection' => 'Velg preroll',
			'settings.prerollSelectionPickLibraryFirst' => 'Velg biblioteket først',
			'settings.prerollSelectionNoneSelected' => 'Ingen forpliktelser valgt',
			'settings.prerollSelectionCount' => ({required Object count}) => '${count} valgt',
			'settings.prerollItemPicker' => 'Velg forpliktelser',
			'settings.prerollItemPickerLoadFailed' => 'Jeg kunne ikke laste opp artikler fra denne biblioteket.',
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
			'settings.autoDownloadContinueWatching' => 'Auto-Download fortsetter å se',
			'settings.autoDownloadContinueWatchingDescription' => 'Hold elementer på din Fortsatt Se shelf lastet ned, og fjerne dem når de forlater shelf',
			'settings.downloadQuality' => 'Last ned kvalitet',
			'settings.downloadQualityDescription' => 'Plex forbereder en konvertert kopi i nedlastingskoden. Jellyfin og Emby transkode mens filen lastes ned; avbrutte overføringer kan trenge å starte om.',
			'settings.askDownloadQualityEachTime' => 'Velg kvalitet for hver nedlasting',
			'settings.askDownloadQualityEachTimeDescription' => 'Vis kvalitetspikeren før du knytter hver video nedlasting',
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
			'settings.companionRemoteServerStartFailed' => 'Kunne ikke starte fjernkontrollserveren',
			'settings.companionRemoteServerStopFailed' => 'Kunne ikke stoppe fjernkontrollserveren',
			'settings.autoPip' => 'Automatisk bilde-i-bilde',
			'settings.autoPipDescription' => 'Åpne bilde-i-bilde når du forlater appen under avspilling',
			'settings.matchContentFrameRate' => 'Tilpass innholdets bildefrekvens',
			'settings.matchContentFrameRateDescription' => 'Tilpass skjermens oppdateringsfrekvens til videoinnhold',
			'settings.matchContentResolution' => 'Tilpass til innholdets oppløsning',
			'settings.matchContentResolutionDescription' => 'Bytter skjermen til videoens opprinnelige oppløsning, slik at TV-en tar seg av oppskaleringen. Menyer og undertekster skaleres også opp under avspilling',
			'settings.matchRefreshRate' => 'Tilpass oppdateringsfrekvens',
			'settings.matchRefreshRateDescription' => 'Tilpass skjermens oppdateringsfrekvens i fullskjerm',
			'settings.matchDynamicRange' => 'Tilpass dynamikkområde',
			'settings.matchDynamicRangeDescription' => 'Slå på HDR for HDR-innhold, og deretter tilbake til SDR',
			'settings.displaySwitchDelay' => 'Forsinkelse ved skjermbytte',
			'settings.tunneledPlayback' => 'Tunnelert avspilling',
			'settings.tunneledPlaybackDescription' => 'Bruk videotunneling. Slå av hvis HDR-avspilling viser svart video eller bevegelser hakker.',
			'settings.audioPassthrough' => 'Direkte lydutgang',
			'settings.audioPassthroughDescription' => 'Send Dolby/DTS-lyd til mottakeren eller TV-en uten omkoding, slik at surroundlyd bevares. Slå av hvis du ikke har lyd.',
			'settings.audioPassthroughDescriptionApple' => 'Bruk Apples innebygde Dolby-dekoder for Dolby Digital Plus, inkludert Atmos. DTS og TrueHD spilles fortsatt av som flerkanals PCM. Slå av hvis du ikke har lyd.',
			'settings.audioPassthroughDescriptionAppleSpatial' => 'Bruk Apples innebygde Dolby-dekoder for Dolby Digital Plus, inkludert Atmos. På iOS, iPadOS og tvOS 26 eller nyere spilles TrueHD Atmos og DTS:X av som romlig lyd. Andre DTS- og TrueHD-spor spilles av som flerkanals PCM. Slå av hvis du ikke har lyd.',
			'settings.audioPassthroughOverriddenByNormalization' => 'Av mens lydstyrkenormalisering er på',
			'settings.audioChannelLimit' => 'Lydkanaler',
			'settings.audioChannelLimitDescription' => 'Miks dekodet lyd ned for høyttalere, hodetelefoner eller HDMI-oppsett som ikke kan spille av alle kanalene',
			'settings.audioChannelLimitOriginal' => 'Original',
			'settings.audioChannelLimitOriginalDescription' => 'Spill av alle kanalene i sporet',
			'settings.audioChannelLimitSurround51' => 'Opptil 5.1',
			'settings.audioChannelLimitSurround51Description' => 'Miks 7.1 ned til 5.1 for TV-er og mottakere som bare støtter 5.1 PCM. Direkte lydutgang påvirkes ikke.',
			'settings.audioChannelLimitStereo' => 'Stereo',
			'settings.audioChannelLimitStereoDescription' => 'Miks ned til to kanaler for stereohøyttalere eller hodetelefoner. Slår av direkte lydutgang.',
			'settings.downmixCenterBoost' => 'Forsterkning av senterkanal',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Forsterkning (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Normaliser lydstyrke ved nedmiks',
			'settings.audioDownmixNormalizeDescription' => 'Senker miksen for å unngå klipping. Slå av for å beholde originalvolumet (høye scener kan forvrenges).',
			'settings.dvConversionMode' => 'Dolby Vision-konvertering',
			'settings.dvConversionModeDescription' => 'Velg hvordan filer med Dolby Vision-profil 7 håndteres.',
			'settings.dvConversionAuto' => 'Automatisk',
			'settings.dvConversionNative' => 'Nativ / deaktivert',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Oppdag enhetens egenskaper og bruk vanlig reserveoppførsel',
			'settings.dvConversionNativeDescription' => 'Tving opprinnelig DV7-avspilling og ikke prøv DV-konvertering på nytt',
			'settings.dvConversionDv81Description' => 'Tving direkte RPU-konvertering til Dolby Vision-profil 8.1',
			'settings.dvConversionHevcStripDescription' => 'Fjern Dolby Vision RPU/EL-lag og lever som vanlig HEVC',
			'settings.experimentalDolbyVision' => 'Eksperimentell Dolby Vision',
			'settings.experimentalDolbyVisionDescription' => 'Bruk den eksperimentelle FEL-rendereren ved neste avspilling. Krever en separat motorbygging.',
			'settings.dvExperimentUnavailableDescription' => 'Dette eksperimentet er foreløpig bare tilgjengelig på Linux.',
			'settings.dvCompatibilityFallback' => 'Kompatibilitetsreserve',
			'settings.dvCompatibilityFallbackDescription' => 'Bruk standardrendereren hvis eksperimentet ikke kan starte. FEL-data kan gå tapt.',
			'settings.dvExperimentDiagnostics' => 'Logging av videoeksperiment',
			'settings.dvExperimentDiagnosticsDescription' => 'Aktiver detaljerte spillerlogger ved neste avspilling.',
			'settings.disableDolbyVision' => 'Deaktiver Dolby Vision',
			'settings.disableDolbyVisionDescription' => 'Spill av filens HDR10- eller HLG-lag i stedet for Dolby Vision når det finnes',
			'settings.hdrSdrConversion' => 'HDR til SDR-konvertering',
			'settings.hdrSdrConversionDescription' => 'Velg hva som konverterer HDR-video når skjermen ikke kan vise HDR.',
			_ => null,
		} ?? switch (path) {
			'settings.hdrSdrConversionAuto' => 'Automatisk',
			'settings.hdrSdrConversionAutoDescription' => 'Enhet på Android 9 og nyere, spiller på eldre versjoner',
			'settings.hdrSdrConversionDevice' => 'Enhet',
			'settings.hdrSdrConversionDeviceDescription' => 'Enhetens videomaskinvare konverterer. Raskest, men fargene avhenger av enheten',
			'settings.hdrSdrConversionPlayer' => 'Spiller',
			'settings.hdrSdrConversionPlayerDescription' => 'Spilleren konverterer. Jevne farger, men 4K kan hakke på enkle TV-bokser',
			'settings.deinterlace' => 'Deinterlacing',
			'settings.deinterlaceDescription' => 'Fjern combing-artefakter fra interlaced video (kun mpv-spiller)',
			'settings.deinterlaceOff' => 'Av',
			'settings.deinterlaceOffDescription' => 'Vis interlaced video slik den dekodes',
			'settings.deinterlaceVideo' => 'Video',
			'settings.deinterlaceVideoDescription' => 'Gjør hvert halvbilde om til et helt bilde. For video spilt inn for TV, som sport, nyheter og konserter',
			'settings.deinterlaceFilm' => 'Film',
			'settings.deinterlaceFilmDescription' => 'Gjenopprett de opprinnelige bildene i film og animasjon som er konvertert med telecine til 29,97 fps, vanlig på NTSC-DVD-er. Video spilt inn for TV vil hakke. Direkte-TV bruker Video',
			'settings.requireProfileSelectionOnOpen' => 'Spør om profil ved appåpning',
			'settings.requireProfileSelectionOnOpenDescription' => 'Vis profilvalg hver gang appen åpnes',
			'settings.forceTvMode' => 'Tving TV-modus',
			'settings.forceTvModeDescription' => 'Tving TV-oppsett. For enheter som ikke oppdages automatisk. Krever omstart.',
			'settings.startInFullscreen' => 'Start i fullskjerm',
			'settings.startInFullscreenDescription' => 'Åpne PlezyNG i fullskjermmodus ved oppstart',
			'settings.exitFullscreenOnPlayerClose' => 'Avslutt fullskjerm ved lukking av avspiller',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Avslutt fullskjerm automatisk når videospilleren lukkes',
			'settings.autoHidePerformanceOverlay' => 'Skjul ytelsesoverlegg automatisk',
			'settings.autoHidePerformanceOverlayDescription' => 'Ton ytelsesoverlegget ut sammen med avspillingskontrollene',
			'settings.showNavBarLabels' => 'Vis etiketter i navigasjonsfeltet',
			'settings.showNavBarLabelsDescription' => 'Vis tekstetiketter under ikonene i navigasjonsfeltet',
			'settings.startupSection' => 'Startseksjon',
			'settings.preferredServer' => 'Foretrukket server',
			'settings.preferredServerDescription' => 'Prioriterer resultatene av denne serveren mens alle tilkoblet server er tilgjengelige.',
			'settings.preferredServerAutomatic' => 'Automatisk',
			'settings.showExploreTab' => 'Vis Oppdag-fanen',
			'settings.showExploreTabDescription' => 'Vis Oppdag-fanen med innhold fra Plex Discover og tilkoblede sporingstjenester',
			'settings.hideEmptyLibraries' => 'Slå tomme biblioteker',
			'settings.hideEmptyLibrariesDescription' => 'Fjern biblioteker med en server-rapporterte elementer tall på null fra navigasjon.',
			'settings.liveTvDefaultFavorites' => 'Vis favorittkanaler som standard',
			'settings.liveTvDefaultFavoritesDescription' => 'Vis bare favorittkanaler når du åpner Direkte-TV',
			'settings.general' => 'Generelt',
			'settings.generalDescription' => 'Språk, oppstart og vindusatferd',
			'settings.languageAndRegion' => 'Språk og region',
			'settings.startup' => 'Oppstart',
			'settings.display' => 'Skjerm',
			'settings.libraryAndCards' => 'Bibliotek og kort',
			'settings.homeScreen' => 'Hjemmeskjerm',
			'settings.navigation' => 'Navigering',
			'settings.window' => 'Vindu',
			'settings.liveTv' => 'Direkte-TV',
			'settings.player' => 'Spiller',
			'settings.videoAndDisplay' => 'Video og skjerm',
			'settings.audio' => 'Lyd',
			'settings.quality' => 'Kvalitet',
			'settings.subtitles' => 'Undertekster',
			'settings.seekAndTiming' => 'Spoling og tidsinnstillinger',
			'settings.behavior' => 'Oppførsel',
			'settings.gestures' => 'Bevegelser',
			'settings.gestureBrightnessSwipe' => 'Lysstyrke-sveip',
			'settings.gestureBrightnessSwipeDescription' => 'Sveip opp eller ned på venstre kant for å justere lysstyrken',
			'settings.gestureVolumeSwipe' => 'Volum-sveip',
			'settings.gestureVolumeSwipeDescription' => 'Sveip opp eller ned på høyre kant for å justere volumet',
			'settings.gesturePinchToZoom' => 'Klyp for å zoome',
			'settings.gesturePinchToZoomDescription' => 'Klyp på videoen for å zoome inn eller ut',
			'settings.gestureSeekSwipe' => 'Søk Swipe',
			'settings.gestureSeekSwipeDescription' => 'Sving venstre eller høyre hvor som helst på videoen å søke; frigjør for å hoppe',
			'settings.rememberBrightnessLevel' => 'Husk lysstyrkenivå',
			'settings.rememberBrightnessLevelDescription' => 'Start avspilling med lysstyrken som ble satt med det siste sveipet',
			'settings.controls' => 'Kontroller',
			'settings.rememberPlayerChanges' => 'Husk endringer i spilleren',
			'settings.rememberPlayerChangesDescription' => 'Hvor en endring under avspilling lagres og brukes på nytt',
			'settings.scopePlaybackSpeed' => 'Avspillingshastighet',
			'settings.scopeShaderPreset' => 'Forhåndsinnstilling for skyggelegging',
			'settings.scopeAspectRatio' => 'Sideforhold',
			'settings.scopeSyncOffsets' => 'Synkronisering av lyd og undertekster',
			'settings.playerScopeOff' => 'Ikke lagre',
			'settings.playerScopeGlobal' => 'Overalt',
			'settings.playerScopeLibrary' => 'Per bibliotek',
			'settings.playerScopeTitle' => 'Per serie eller film',
			'settings.exportDialogTitle' => 'Eksporter PlezyNG-innstillinger',
			'settings.followSystem' => 'Følg systemet',
			'settings.followAppLanguage' => 'Samme som grensesnittspråket',
			'settings.regionFormat' => 'Regionale formater',
			'settings.regionFormatDescription' => 'Velg hvordan datoer, tall og måleenheter vises.',
			'settings.metadataLanguage' => 'Språk for metadata',
			'settings.metadataLanguageDescription' => 'Foretrukket språk for titler og beskrivelser når serveren støtter det. Lyd og undertekster stilles inn separat.',
			'settings.enterFullscreenOnPlaybackStart' => 'Skriv inn fullskjermen når playback starter',
			'settings.enterFullscreenOnPlaybackStartDescription' => 'Åpne desktop-video på fullskjerm når playback starter',
			'settings.extendVideoIntoDisplayCutout' => 'Utvid video til display cutout',
			'settings.extendVideoIntoDisplayCutoutDescription' => 'La fullskjermvideoen bruke kameraet på Android-telefoner',
			'settings.languageDescription' => 'Velg språket som brukes til PlezyNG-kontroller og meldinger. Følg systemet sporer enhetsspråket ditt.',
			'settings.themeDescription' => 'Velg fargene og kontrastene som brukes gjennom appen.',
			'settings.libraryDensityDescription' => 'Endre hvor mange bibliotekkort som passer i hver rad.',
			'settings.displayScaleDescription' => 'Gjenopprette grensesnittet på denne bilskjermen uten å endre tekststørrelsen på enheten din.',
			'settings.themeSongVolumeDescription' => 'Sett volumet av tema sanger i forhold til andre lyd.',
			'settings.viewModeDescription' => 'Velg om bibliotekselementer vises som plakater i et nettverk eller som en kompakt liste.',
			'settings.gridViewDescription' => 'Ordne bibliotekselementer i rader og kolumner av plakater.',
			'settings.listViewDescription' => 'Vis bibliotek elementer i en vertikal liste med mer tekst per element.',
			'settings.gridSpacingDescription' => 'Sett gapet mellom plakater i biblioteksnett.',
			'settings.gridSpacingTightDescription' => 'Fyll mer poster over skjermen med mindre gap.',
			'settings.gridSpacingNormalDescription' => 'Bruk standardfrekvensen mellom poster.',
			'settings.gridSpacingSpaciousDescription' => 'Legg til større gap mellom plakater for mer separasjon.',
			'settings.episodePosterModeDescription' => 'Velg hvilket kunstverk som vises på episode kort.',
			'settings.seriesPosterDescription' => 'Bruk showens serieposter for hver episode.',
			'settings.seasonPosterDescription' => 'Bruk sesongposter for hver episode når det er tilgjengelig.',
			'settings.episodeThumbnailDescription' => 'Bruk en ramme fra episoden når tilgjengelig.',
			'settings.continueWatchingActionDescription' => 'Velg hva som skjer når du aktiverer en Continuing Watching-kort.',
			'settings.continueWatchingPlayDescription' => 'Start filmen eller episoden umiddelbart.',
			'settings.continueWatchingDetailsDescription' => 'Åpne tittelen først slik at du kan se nærmere på detaljene og velge en handling.',
			'settings.episodeActionDescription' => 'Velg hva som skjer når du aktiverer et episode-kort.',
			'settings.episodePlayDescription' => 'Begynn episoden umiddelbart.',
			'settings.episodeDetailsDescription' => 'Åpne episode-siden før playback.',
			'settings.contentScreensaverDelayDescription' => 'Velg hvor lenge PlezyNG venter uten inngang før du viser kunstverk.',
			'settings.continueWatchingRowSizeDescription' => 'Velg hvor store kortene er i Continuing Watching-linjen.',
			'settings.rowSizeCompactDescription' => 'Vis mindre kort slik at flere elementer passer over raden.',
			'settings.rowSizeStandardDescription' => 'Bruk standard kortstørrelse.',
			'settings.rowSizeLargeDescription' => 'Vis større kort med mer kunstverk detalj.',
			'settings.visualEffectsDescription' => 'Velg animasjon og kunstverk effekter budsjett for denne enheten.',
			'settings.visualEffectsFullDescription' => 'Bruk den fullstendige animasjons- og kunstverkseffekten på hver enhet.',
			'settings.startupSectionDescription' => 'Velg hvilken del som åpner når PlezyNG starter.',
			'settings.startupSectionOptions.discover' => 'Åpne anbefalinger og elementer fra tilknyttede oppdagelseskilder.',
			'settings.startupSectionOptions.libraries' => 'Åpne dine tilkoblede mediebiblioteker.',
			'settings.startupSectionOptions.liveTv' => 'Åpne Live TV når en server gir den; ellers faller oppstart tilbake til hjemmet.',
			'settings.startupSectionOptions.search' => 'Åpne medier søk.',
			'settings.smallSkipDurationDescription' => 'Sett avstanden som flyttes av den korte bakover og fremfor søker kontroller.',
			'settings.largeSkipDurationDescription' => 'Sett avstanden som flyttes av den lange bakover og fremfor søker kontroller.',
			'settings.rewindOnResumeDescription' => 'Flytt playback tilbake med dette beløpet når du gjenoppretter en video.',
			'settings.defaultSleepTimerDescription' => 'Sett den opprinnelige varigheten som brukes når du starter søvn timer.',
			'settings.playNextCountdownDescription' => 'Vent dette lenge før du starter neste episode. Sett til 0 for å starte umiddelbart.',
			'settings.autoSkipDelaySettingDescription' => 'Det gjelder når en intro, kreditter eller annonsen er satt til å skille automatisk.',
			'settings.downmixCenterBoostDescription' => 'Øke dialogen i sentralkanalen når omgivende lyd blandes ned til stereo.',
			'settings.displaySwitchDelayDescription' => 'Vennligst vent før du endrer skjermmodus slik at TV-en eller mottakeren kan fullføre sin tidligere skift.',
			'settings.playerBackendDescription' => 'Velg hvilken spillmotor som dekoder og renderer video på denne enheten.',
			'settings.exoPlayerDescription' => 'Bruk Androids innfødte Media3-baserte spiller og støttet maskinvareveier.',
			'settings.mpvDescription' => 'Bruk mpv, som viser ytterligere playback, undertittel og videobehandling kontroller.',
			'settings.scopeOffDescription' => 'Lagre endringer for den nåværende playback-sesjonen bare.',
			'settings.scopeGlobalDescription' => 'Åpne samme verdi for hver bibliotek og tittel.',
			'settings.scopeLibraryDescription' => 'Husk en separat verdi for hver bibliotek.',
			'settings.scopeTitleDescription' => 'Husk en separat verdi for hver show eller film.',
			'settings.specialsOrderingServerDescription' => 'Oppbevar episoden ordre levert av media serveren.',
			'settings.specialsOrderingAirDateDescription' => 'Plasser spesialene blant vanlige episoder etter deres luftdato.',
			'settings.specialsOrderingLastDescription' => 'Plasser hver spesiell etter de vanlige sesongene.',
			'settings.skipIntroModeDescription' => 'Velg om intro markere spiller normalt, viser en skip-knappe eller skip automatisk.',
			'settings.skipCreditsModeDescription' => 'Velg om kreditter spiller normalt, viser en skip-knappe eller skip automatisk.',
			'settings.skipAdsModeDescription' => 'Velg om detekterte annonser spiller normalt, viser en skip-knappe eller skip automatisk.',
			'settings.playbackBufferAutoDescription' => 'La den aktive spilleren velge sin normale buffer størrelse.',
			'settings.playbackBufferLargeDescription' => 'Hold mer media klar før playback; dette bruker mer minne.',
			'settings.playbackBufferExtraLargeDescription' => 'Hold den største les-ahead bufferen; dette bruker mest minne.',
			'settings.defaultQualityDescription' => 'Sett standard videooppløsning og bitrate tak for strømmer som serveren transkoder.',
			'settings.cellularQualityDescription' => 'Override standardkvalitet når enheten bruker en cellulær-only forbindelse.',
			'settings.remoteQualityDescription' => 'Override Default Quality når du kobler til en server gjennom en fjerne tilkobling.',
			'settings.qualityPresetOriginalDescription' => 'Spill kilden på tilgjengelig kvalitet uten å be serveren om å transkode den.',
			'settings.qualityPresetTranscodeOptionDescription' => 'Be serveren om en konvertert strøm ved hjelp av oppløsningen og bitrate som vises ovenfor.',
			'settings.qualityPresetSameAsDefaultDescription' => 'Bruk kvaliteten valgt i standardkvalitet.',
			'settings.musicQualityDescription' => 'Sett den maksimale lydbitrate som kreves fra serveren; Original holder kildestrømmen.',
			'settings.musicQualityOriginalDescription' => 'Spille kildekode uten en bitrate-kapped transcode.',
			'settings.musicQualityTranscodeOptionDescription' => 'Be om en server transkode capped nær bitrate vist ovenfor; den virkelige utgangen kan variere.',
			'settings.maxVolumeInputLabel' => 'Maksimalt volum (%)',
			'settings.checkForUpdatesDescription' => 'Sjekk nå om en nyere versjon av PlezyNG er tilgjengelig.',
			'settings.appearanceDescription' => 'Velg app-temaet og juster bibliotekskort, Hjem rader og navigasjon.',
			'settings.prerollLibraryDescription' => 'Velg biblioteket som inneholder klippene tilgjengelig som film pre-rolls.',
			'settings.prerollSelectionDescription' => 'Velg hvilke klipp fra det valgte biblioteket kan spilles før filmer.',
			'settings.contentScreensaverDelayOptionDescription' => 'Vent dette mange minutter uten inngang før du viser skjermbeskyttelse kunstverk.',
			'settings.videoCodecOptionDescription' => 'Tillat direkte spill for denne kodeksen når den støttes. Unchecked codecs transcodes av media serveren.',
			'themeEditor.builtIn' => 'Innebygde',
			'themeEditor.presets' => 'Forhåndsinnstillinger',
			'themeEditor.custom' => 'Egendefinert',
			'themeEditor.customEmpty' => 'Ikke opprettet ennå',
			'themeEditor.editCustom' => 'Rediger egendefinert tema',
			'themeEditor.editCustomDescription' => 'Velg alle fargene selv',
			'themeEditor.locked' => 'Livslang tilgang kreves',
			'themeEditor.savedLocked' => 'Sparet – tilgjengelig med livslang tilgang',
			'themeEditor.title' => 'Egendefinert tema',
			'themeEditor.startFrom' => 'Start fra',
			'themeEditor.startFromDescription' => 'Kopier alle fargene fra et annet tema',
			'themeEditor.colors' => 'Farger',
			'themeEditor.preview' => 'Forhåndsvisning',
			'themeEditor.slots.bg' => 'Bakgrunn',
			'themeEditor.slots.surface' => 'Overflate',
			'themeEditor.slots.outline' => 'Kontur',
			'themeEditor.slots.text' => 'Tekst',
			'themeEditor.slots.textMuted' => 'Sekundærtekst',
			'themeEditor.slots.accent' => 'Aksent',
			'themeEditor.opacity' => 'Opasitet',
			'themeEditor.hexHint' => '#RRGGBB eller #AARRGGBB',
			'themeEditor.fromOtherThemes' => 'Fra andre temaer',
			'themeEditor.swatchLabel' => ({required Object color, required Object theme}) => '${color} (${theme})',
			'themeEditor.contrast.textOnBg' => 'Tekst på bakgrunn',
			'themeEditor.contrast.textOnSurface' => 'Tekst på overflate',
			'themeEditor.contrast.textMutedOnBg' => 'Sekundærtekst på bakgrunn',
			'themeEditor.contrast.textMutedOnSurface' => 'Sekundærtekst på overflate',
			'themeEditor.contrast.accentOnBg' => 'Aksent på bakgrunn',
			'themeEditor.contrast.accentOnSurface' => 'Aksent på overflate',
			'themeEditor.contrast.labelOnAccent' => 'Knappetekst på aksent',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, under anbefalt minimum på ${minimum}:1',
			'themeEditor.discardTitle' => 'Forkaste endringene?',
			'themeEditor.discardMessage' => 'Ulagrede fargeendringer går tapt.',
			'themeEditor.discard' => 'Forkast',
			'themeEditor.previewCardTitle' => ({required Object number}) => 'Episode ${number}',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => '${minutes} min igjen',
			'themeEditor.previewSwitch' => 'Autospill',
			'themeEditor.previewMutedText' => 'Sekundærtekst ser slik ut',
			'themeEditor.themeSystemDescription' => 'Følg utseendet på enheten og skift mellom lys og mørke automatisk.',
			'themeEditor.themeLightDescription' => 'Bruk en lys bakgrunn med mørk tekst.',
			'themeEditor.themeDarkDescription' => 'Bruk en mørk bakgrunn med lys tekst.',
			'themeEditor.themeOledDescription' => 'Bruk nærmeste svarte overflater som reduserer lys på OLED-skjermer.',
			'themeEditor.themeEmberDescription' => 'Bruk varme røde og amber accent farger.',
			'themeEditor.themeGlacierDescription' => 'Bruk kalde blå aksentfarger.',
			'themeEditor.themeForestDescription' => 'Bruk malt grønn og naturlig accent farger.',
			'themeEditor.themePlumDescription' => 'Bruk violett og plum accent farger.',
			'themeEditor.themePaperDescription' => 'Bruk varme papirlignende overflater og ink-inspirerte farger.',
			'themeEditor.themeCustomDescription' => 'Bruk fargepaletten du opprettet i den tilpassede tema editoren.',
			'themeEditor.editorDescription' => 'Velg en palettfarge, justere dens hue, mottakelse, lyshet eller opacity, og se forhåndsvisning oppdatering før du sparer.',
			'search.hint' => 'Søk i filmer, serier, musikk...',
			'search.tryDifferentTerm' => 'Prøv et annet søkeord',
			'search.searchYourMedia' => 'Søk i mediene dine',
			'search.enterTitleActorOrKeyword' => 'Skriv inn tittel, skuespiller eller nøkkelord',
			'search.people' => 'Personer',
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
			'hotkeys.actions.subtitleDelayIncrease' => 'Forsink undertekster',
			'hotkeys.actions.subtitleDelayDecrease' => 'Fremskynd undertekster',
			'hotkeys.actions.shaderToggle' => 'Slå shadere av/på',
			'hotkeys.actions.skipMarker' => 'Hopp over intro/rulletekst',
			'hotkeys.actions.screenshot' => 'Ta skjermbilde',
			'hotkeys.actions.framePrevious' => 'Forrige Frame',
			'hotkeys.actions.frameNext' => 'Neste Frame',
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
			'fileInfo.flagDub' => 'Dubbet',
			'fileInfo.flagOriginal' => 'Original',
			'fileInfo.channelsMono' => 'Mono',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'Profil ${profile}',
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
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: 'Dette sletter ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episode i den, og filen.', other: 'Dette sletter alle ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodene i den, og filene deres.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: 'Dette elementet er lagret som ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} fil, som vil bli slettet.', other: 'Dette elementet er lagret på tvers av ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filer, og alle vil bli slettet.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} annen episode er lagret i samme fil og vil også bli slettet:', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} andre episoder er lagret i samme fil og vil også bli slettet:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'PlezyNG kunne ikke sjekke hvilke filer dette vil fjerne, så det kan slette mer enn elementet som er nevnt ovenfor. Avbryt og prøv igjen, eller slett likevel.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'Serveren din ga ikke fildetaljer for dette elementet, så PlezyNG kan ikke sjekke hvilke filer dette vil fjerne. Det kan slette mer enn elementet som er nevnt ovenfor.',
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
			'accessibility.alphabetNavigation' => 'Alfabetisk navigasjon',
			'accessibility.alphabetScrollHint' => 'Sveip opp eller ned for å gå én bokstav om gangen',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Rad ${row} av ${rowCount}, kolonne ${column} av ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'Rad ${row} av ${rowCount}',
			'accessibility.autoScrollPlay' => 'Start automatisk rulling',
			'accessibility.autoScrollPause' => 'Sett automatisk rulling på pause',
			'accessibility.hueShort' => 'H',
			'accessibility.saturationShort' => 'S',
			'accessibility.valueShort' => 'V',
			'accessibility.red' => 'Rød',
			'accessibility.green' => 'Grønn',
			'accessibility.blue' => 'Blå',
			'accessibility.redShort' => 'R',
			'accessibility.greenShort' => 'G',
			'accessibility.blueShort' => 'B',
			'accessibility.colorModeHsv' => 'HSV',
			'accessibility.colorModeRgb' => 'RGB',
			'accessibility.title' => 'Tilgjengelighet',
			'accessibility.summary' => 'Tekst, kontrast, bevegelse og kontroller',
			'accessibility.systemHint' => 'Tilgjengelighetsinnstillingene for enheten din gjelder alltid. Disse alternativene legger til justeringer gjennom PlezyNG.',
			'accessibility.readability' => 'Lesing og synlighet',
			'accessibility.textSize' => 'Tilleggsvekst av tekst',
			'accessibility.preview' => 'Finn din neste historie.Les, lytt og se på din egen hastighet.',
			'accessibility.boldText' => 'Høyde Interface Text',
			'accessibility.highContrast' => 'Høy kontrast',
			'accessibility.highContrastHint' => 'Større tekst, utskrifter og fokusindikatorer på lys eller mørke overflater.',
			'accessibility.interaction' => 'Motion og interaksjon',
			'accessibility.reduceMotion' => 'Redusere bevegelse',
			'accessibility.reduceMotionHint' => 'Stopp bevegelser i fokusmarkeringer, sideoverganger og dekorative effekter.',
			'accessibility.largeTargets' => 'Større touch mål',
			'accessibility.largeTargetsHint' => 'Gi delte kontroller mer plass for berøring og assistent navigasjon.',
			'accessibility.navigationHint' => 'Bruk Tab og Shift+Tab for å flytte mellom kontroller, Enter eller mellomrom for å aktivere og Escape eller Tilbake for å lukke. Zoom og leseinnstillinger er tilgjengelige når en bok er åpen.',
			'accessibility.textSizeDescription' => 'Skala grensesnitt tekst i PlezyNG i tillegg til enhetens system tekst-størrelse innstilling.',
			'accessibility.boldTextHint' => 'Bruk en tyngre vekt for grensesnitt etiketter og meldinger for å gjøre dem enklere å skille mellom.',
			'tooltips.shufflePlay' => 'Tilfeldig avspilling',
			'tooltips.playTrailer' => 'Spill trailer',
			'tooltips.markAsWatched' => 'Merk som sett',
			'tooltips.markAsUnwatched' => 'Merk som usett',
			'audioTracks.track' => ({required Object n}) => 'Lydspor ${n}',
			'videoControls.audioLabel' => 'Lyd',
			'videoControls.subtitlesLabel' => 'Undertekster',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => 'Letterbox',
			'videoControls.fillScreen' => 'Fyll skjerm',
			'videoControls.stretch' => 'Strekk',
			'videoControls.lockRotation' => 'Lås rotasjon',
			'videoControls.unlockRotation' => 'Lås opp rotasjon',
			'videoControls.timerActive' => 'Timer aktiv',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Avspillingen settes på pause om ${duration}',
			'videoControls.sleepTimerEndOfVideo' => 'Slutten av gjeldende video',
			'videoControls.sleepTimerStopAtHeader' => 'Stopp ved',
			'videoControls.sleepTimerDurationHeader' => 'Varighet',
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
			_ => null,
		} ?? switch (path) {
			'videoControls.lockScreen' => 'Lås skjerm',
			'videoControls.screenLockButton' => 'Skjermlås',
			'videoControls.timelineSlider' => 'Videotidslinje',
			'videoControls.volumeSlider' => 'Volumnivå',
			'videoControls.endsAt' => ({required Object time}) => 'Slutter kl. ${time}',
			'videoControls.pipActive' => 'Spiller i bilde-i-bilde',
			'videoControls.pipFailed' => 'Bilde-i-bilde kunne ikke starte',
			'videoControls.screenshotSaved' => 'Skjermbilde lagret',
			'videoControls.screenshotFailed' => 'Kunne ikke ta skjermbilde',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Zoom ${percent} %',
			'videoControls.volumePercent' => ({required Object percent}) => 'Volum ${percent} %',
			'videoControls.pipErrors.androidVersion' => 'Krever Android 8.0 eller nyere',
			'videoControls.pipErrors.iosVersion' => 'Krever iOS 15.0 eller nyere',
			'videoControls.pipErrors.permissionDisabled' => 'Bilde-i-bilde er deaktivert. Slå det på i systeminnstillinger.',
			'videoControls.pipErrors.notSupported' => 'Enheten støtter ikke bilde-i-bilde-modus',
			'videoControls.pipErrors.voSwitchFailed' => 'Kunne ikke bytte videoutgang for bilde-i-bilde',
			'videoControls.pipErrors.failed' => 'Bilde-i-bilde kunne ikke starte',
			'videoControls.pipErrors.prepareFailed' => 'Bilde-i-bilde kunne ikke forberedes',
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
			'videoControls.skipIntro' => 'Hopp over intro',
			'videoControls.skipCredits' => 'Hopp over rulletekst',
			'videoControls.nextEpisode' => 'Neste episode',
			'videoControls.subtitleTrack' => ({required Object n}) => 'Spor ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => 'Undertekst ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (tvunget)',
			'videoControls.osdSubtitlesOff' => 'Undertekster: Av',
			'videoControls.osdSubtitles' => ({required Object track}) => 'Undertekster: ${track}',
			'videoControls.osdAudio' => ({required Object track}) => 'Lyd: ${track}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Frame', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} rammer', ), 
			'videoControls.trackSelectionTitle' => 'Velg spor før playback',
			'videoControls.trackSelectionAuto' => 'Automatisk utvalg',
			'videoControls.openMiniPlayer' => 'Åpne mini-spillere',
			'videoControls.returnToFullPlayer' => 'Tilbake til fullspiller',
			'videoControls.loadSubtitleFile' => 'Last ned undertittelfil...',
			'videoControls.subtitleLoadFailed' => 'Fikk ikke lastet opp subtitle-filen',
			'videoControls.skipAds' => 'Hopp over reklame',
			'videoControls.tapToUnlock' => 'Trykk for å låse opp',
			'videoControls.tapAgainToUnlock' => 'Trykk igjen for å låse opp',
			'messages.markedAsWatched' => 'Merket som sett',
			'messages.markedAsUnwatched' => 'Merket som usett',
			'messages.markedAsWatchedOffline' => 'Merket som sett (synkroniseres når tilkoblet)',
			'messages.markedAsUnwatchedOffline' => 'Merket som usett (synkroniseres når tilkoblet)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Automatisk fjernet: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: 'Fjernet automatisk ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} avspilt nedlasting', other: 'Fjernet automatisk ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} avspilte nedlastinger', ), 
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
			'messages.playbackFailedDetail' => ({required Object error}) => 'Kunne ikke starte avspillingen: ${error}',
			'messages.audioOutputFailed' => 'Lydutgangen svarer ikke lenger. Sjekk lydtilkoblingen til TV-en eller mottakeren; hvis andre apper heller ikke har lyd, må du starte enheten på nytt.',
			'messages.mediaUnavailable' => 'Dette innholdet er ikke lenger tilgjengelig.',
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
			'messages.serverBusyTitle' => 'Strømmen er utilgjengelig',
			'messages.serverBusyBody' => 'Serveren fortsatte å nekte å strømme denne filen (HTTP 503). Den kan være i ferd med å starte på nytt eller være opptatt, eller lagringsstedet til filen kan være frakoblet. Prøv igjen om litt – hvis det fortsetter å skje, kan du be eieren av serveren om å kontrollere serveren og lagringsstedet til filen.',
			'messages.playbackNotAllowedTitle' => 'Avspilling er ikke tillatt',
			'messages.playbackNotAllowedBody' => 'Serveren nektet å strømme dette elementet (HTTP 403). Kontoen din har kanskje ikke tillatelse til å spille det av, eller serveren tillater kanskje bare avspilling på sitt lokale nettverk.',
			'messages.logsUploaded' => 'Logger lastet opp',
			'messages.logsUploadFailed' => 'Kunne ikke laste opp logger',
			'messages.logId' => 'Logg-ID',
			'messages.burnedSubtitlesUseMenu' => 'Undertekstene er brent inn i denne strømmen. Endre dem fra undertekstmenyen.',
			'messages.noVideoUrl' => 'Ingen video-URL er tilgjengelig',
			'messages.playbackNoMediaSources' => 'Serveren returnerte ingen avspillbare mediekilder',
			'messages.playbackDataNotPrepared' => 'Avspillingen ble startet før dataene var klare',
			'messages.streamSelectionUnavailable' => 'Valg av strømmer er ikke tilgjengelig for denne kilden',
			'messages.streamSelectionFailed' => 'Kunne ikke bruke de valgte strømmene',
			'messages.trackSelectionNotRemembered' => 'Dette sporvalget gjelder bare for gjeldende avspilling.',
			'messages.serverUnavailableForProfile' => 'Ingen server er tilgjengelig for den aktive profilen',
			'subtitlingStyling.previewSample' => 'Den raske brune fox hopper over den lazy hunden',
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
			'subtitlingStyling.useMargins' => 'Bruk marger',
			'subtitlingStyling.useMarginsDescription' => 'Tillat tekstundertekster i området utenfor videoen. Stilundertekster kan beholde sin opprinnelige plassering.',
			'subtitlingStyling.anchorToScreen' => 'Forankre til skjermen',
			'subtitlingStyling.anchorToScreenDescription' => 'Vis tekstundertekster i de svarte feltene under video i bredformat',
			'subtitlingStyling.bold' => 'Fet',
			'subtitlingStyling.italic' => 'Kursiv',
			'subtitlingStyling.renderResolution' => 'Gjengivelsesoppløsning',
			'subtitlingStyling.renderResolutionScreen' => 'Skjermoppløsning',
			'subtitlingStyling.renderResolutionVideo' => 'Videooppløsning',
			'subtitlingStyling.fontSizeDescription' => 'Sett tekststørrelsen på denne enheten.',
			'subtitlingStyling.textColorDescription' => 'Velg fargen som brukes til undertekst.',
			'subtitlingStyling.borderSizeDescription' => 'Sett tykkelsen av utlinjen rundt undertekst.',
			'subtitlingStyling.borderColorDescription' => 'Velg fargen som brukes for undertittelutløpet.',
			'subtitlingStyling.backgroundColorDescription' => 'Velg fargen bak undertekst.',
			'subtitlingStyling.backgroundOpacityDescription' => 'Sett hvor åpen undertittel bakgrunnen er: 0% er klart og 100% er solid.',
			'subtitlingStyling.positionDescription' => 'Beveg subtitlene vertikalt. 0% er toppen av videoen og 100% er bunnen.',
			'subtitlingStyling.assOverrideDescription' => 'Velg om spilleren følger, justerer, erstattes eller fjerner styling innebygd i ASS-subtitler.',
			'subtitlingStyling.assOverrideOptions.no' => 'Hold bokstaver, farger, størrelser og plassering skrevet i undertittelfilen.',
			'subtitlingStyling.assOverrideOptions.yes' => 'Tillat spillernes undertittelstilinnstillinger til å justere ASS-subtitler.',
			'subtitlingStyling.assOverrideOptions.scale' => 'Bruk spilleren styling og skala innebygde størrelser for å matche video dimensjonene.',
			'subtitlingStyling.assOverrideOptions.force' => 'Endre innebygde ASS-stiler med spillerens undertittelstil.',
			'subtitlingStyling.assOverrideOptions.strip' => 'Fjern innebygd ASS-formatering og gjengiv underteksten tydelig.',
			'subtitlingStyling.renderResolutionDescription' => 'Velg oppløsningen som brukes til å rasterisere bilde og ASS-subtitler. Lavere Android-skalaer kan redusere renderingsarbeidet, men ser smalere ut.',
			'subtitlingStyling.renderResolutionOptions.screen' => 'Render på den fullstendige overflateoppløsningen for det skarpeste resultatet.',
			'subtitlingStyling.renderResolutionOptions.video' => 'Render bruker videooppløsningen som referanse, noe som kan redusere arbeidet på høye oppløsningsskjermer.',
			'subtitlingStyling.renderResolutionOptions.threeQuarter' => 'Render på 75% av skjermoverflatesolusjonen for en modest ytelsesbesparelse.',
			'subtitlingStyling.renderResolutionOptions.half' => 'Render på 50% av skjermoverflateoppløsningen for å redusere arbeidet, med mykere edder.',
			'subtitlingStyling.renderResolutionOptions.third' => 'Render på en tredjedel av skjermoverflateoppløsningen for å redusere arbeid, med mykere edder.',
			'subtitlingStyling.renderResolutionOptions.quarter' => 'Render på en fjerdedel av display overflateoppløsningen for å redusere arbeid, med det mykeste resultatet.',
			'subtitlingStyling.boldDescription' => 'Skjær undertekst i en tyngre vekt.',
			'subtitlingStyling.italicDescription' => 'Skriv ut undertekst i italiensk.',
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
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => 'Legg til linje',
			'mpvConfig.removeLine' => 'Fjern linje',
			'mpvConfig.embeddedVoHint' => 'vo, gpu-context og gpu-api ignoreres på Linux: innebygd video renderes alltid via vo=libmpv på videoplanet, og gpu-next (som compute-shadere som ArtCNN trenger) kan ikke kjøre innebygd.',
			'dialog.confirmAction' => 'Bekreft handling',
			'profiles.addPlezyProfile' => 'Legg til PlezyNG-profil',
			'profiles.switchingProfile' => 'Bytter profil…',
			'profiles.deleteThisProfileTitle' => 'Slett denne profilen?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'Fjern ${displayName}. Tilkoblinger påvirkes ikke.',
			'profiles.active' => 'Aktiv',
			'profiles.manage' => 'Administrer',
			'profiles.delete' => 'Slett',
			'profiles.signOut' => 'Logg ut',
			'profiles.signOutPlexTitle' => 'Logge ut av Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'Fjerne ${displayName} og alle Plex Home-brukere? Du kan logge inn igjen når som helst.',
			'profiles.signOutPlexDeleteDownloads' => 'Slett også nedlastinger',
			'profiles.signOutPlexDeleteDownloadsDescription' => 'Ellers blir de liggende på denne enheten og kommer tilbake når du logger inn på denne kontoen igjen.',
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
			'profiles.copyAutomationLink' => 'Kopierer Android automatiseringslink',
			'profiles.copyAutomationLinkDescription' => 'Velg denne profilen fra en Android intensjon eller automatisering.',
			'profiles.automationLinkCopied' => 'Profil automatisering link kopieres.',
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
			'profiles.borrowEmptySubtitle' => 'Koble Plex, Jellyfin eller Emby til en annen profil først.',
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
			'profiles.tokenIdentityMismatch' => 'Plex-profiltokenet ble knyttet til en uventet server',
			'profiles.settingsLocked' => 'Innstillinger er låst for denne profilen.',
			'profiles.unlockSettings' => 'Unlock innstillinger',
			'profiles.showExploreForProfile' => 'Vis Utforsk for denne profilen',
			'profiles.showExploreForProfileDescription' => 'Avaktiver for å fjerne Explore fra denne profils navigasjon.',
			'connections.sectionTitle' => 'Tilkoblinger',
			'connections.addConnection' => 'Legg til tilkobling',
			'connections.addConnectionSubtitleNoProfile' => 'Logg inn med Plex eller koble til en Jellyfin- eller Emby-server',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Legg til for ${displayName}: Plex, Jellyfin, Emby eller en annen profiltilkobling',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Økten er utløpt for ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Økten er utløpt for ${count} servere',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} nektet tilgang for denne kontoen',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} servere nektet tilgang for denne kontoen',
			'connections.signInAgain' => 'Logg inn igjen',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'Rediger ${product}-tilkobling',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'Legg til eller fjern URL-er for ${serverName}. PlezyNG vil bruke den nåbare URL-en med lavest ventetid.',
			'accountPreferences.sectionTitle' => 'Kontoinnstillinger',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => 'Lyd-, undertekst- og bibliotekalternativer lagret på ${account}',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => 'Lyd-, undertekst- og bibliotekalternativer lagret på ${count} kontoer',
			'accountPreferences.pickAccount' => 'Hver konto lagrer sine egne innstillinger. Velg hvilken du vil redigere.',
			'accountPreferences.storedOnAccount' => 'Disse alternativene lagres på selve kontoen, så alle apper som er logget på den, bruker dem — inkludert PlezyNG på de andre enhetene dine.',
			'accountPreferences.noAccounts' => 'Ingen kontoer å konfigurere',
			'accountPreferences.noAccountsHint' => 'Logg inn på Plex, eller koble til en Jellyfin- eller Emby-server, så vises innstillingene som er lagret på den kontoen, her.',
			'accountPreferences.unavailable' => 'Kan ikke nå denne kontoen',
			'accountPreferences.loadFailed' => 'Kunne ikke laste inn disse innstillingene',
			'accountPreferences.noPreference' => 'Ingen preferanse',
			'accountPreferences.notSet' => 'Ikke angitt',
			'accountPreferences.groups.audioAndSubtitles' => 'Lyd og undertekster',
			'accountPreferences.groups.libraryDisplay' => 'Bibliotek',
			'accountPreferences.groups.personalMedia' => 'Personlige medier',
			'accountPreferences.preferredAudioLanguage' => 'Foretrukket lydspråk',
			'accountPreferences.autoSelectAudio' => 'Velg lyd etter språk',
			'accountPreferences.autoSelectAudioDescription' => 'Av beholder det lydsporet filen markerer som standard.',
			'accountPreferences.preferredSubtitleLanguage' => 'Foretrukket undertekstspråk',
			'accountPreferences.subtitleMode' => 'Slå på undertekster',
			'accountPreferences.subtitleModes.none' => 'Manuelt valgt',
			'accountPreferences.subtitleModes.noneDescription' => 'Slå aldri på undertekster av seg selv.',
			'accountPreferences.subtitleModes.defaultMode' => 'Følg sporflaggene',
			'accountPreferences.subtitleModes.defaultModeDescription' => 'Bruk standard- og tvunget-flaggene som er lagret på hvert undertekstspor.',
			'accountPreferences.subtitleModes.always' => 'Alltid aktivert',
			'accountPreferences.subtitleModes.alwaysDescription' => 'Slå på et undertekstspor på foretrukket språk når det finnes et.',
			'accountPreferences.subtitleModes.onlyForced' => 'Kun tvungne undertekster',
			'accountPreferences.subtitleModes.onlyForcedDescription' => 'Last inn bare sporene som er merket som tvungne.',
			'accountPreferences.subtitleModes.smart' => 'Vist med fremmedspråklig lyd',
			'accountPreferences.subtitleModes.smartDescription' => 'Slå på undertekster bare når lyden er på et annet språk.',
			'accountPreferences.subtitleAccessibility' => 'SDH-undertekster',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'Foretrekk ikke-SDH-undertekster',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'Foretrekk SDH-undertekster',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'Kun SDH-undertekster',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'Kun ikke-SDH-undertekster',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdhDescription' => 'Foretrukker standard undertittel når både standard og SDH versjoner er tilgjengelige.',
			'accountPreferences.subtitleAccessibilityOptions.preferSdhDescription' => 'De foretrekker SDH-subtitler når de er tilgjengelige, men tillater standard subtitler som en fallback.',
			'accountPreferences.subtitleAccessibilityOptions.onlySdhDescription' => 'Bruk bare SDH-subtitler; ikke fall tilbake til standard subtitler.',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdhDescription' => 'Bruk bare standard undertitler; unngå SDH-subtitler.',
			'accountPreferences.forcedSubtitles' => 'Tvungne undertekster',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'Foretrekk ikke-tvungne undertekster',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'Foretrekk tvungne undertekster',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'Kun tvungne undertekster',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'Kun ikke-tvungne undertekster',
			'accountPreferences.forcedSubtitleOptions.preferNonForcedDescription' => 'Foretrakk regelmessige undertitler, men tillater tvunget spor som en fallback.',
			'accountPreferences.forcedSubtitleOptions.preferForcedDescription' => 'De foretrekker tvungne spor når de er tilgjengelige, men tillater regelmessige undertitler som en fallback.',
			'accountPreferences.forcedSubtitleOptions.onlyForcedDescription' => 'Bruk bare spor markerte som tvunget.',
			'accountPreferences.forcedSubtitleOptions.onlyNonForcedDescription' => 'Utelukker spor markeret som tvunget.',
			'accountPreferences.displayMissingEpisodes' => 'Vis manglende episoder',
			'accountPreferences.displayMissingEpisodesDescription' => 'Vis episoder serveren kjenner til, men som ikke har noen fil.',
			'accountPreferences.hidePlayedInLatest' => 'Skjul sette elementer i Siste',
			'accountPreferences.hidePlayedInLatestDescription' => 'Hold elementer du allerede har sett utenfor serverens Siste-rader.',
			'accountPreferences.displayCollectionsView' => 'Vis samlingsvisningen',
			'accountPreferences.displayCollectionsViewDescription' => 'Vis serverens samlingsvisning sammen med bibliotekene dine.',
			'accountPreferences.rewatchingInNextUp' => 'Behold serier du ser på nytt i Neste opp',
			'accountPreferences.rewatchingInNextUpDescription' => 'Når du er ferdig med en serie og starter den på nytt, følger Neste opp den nye avspillingen i stedet for å fjerne serien.',
			'accountPreferences.watchedIndicator' => 'Sett-indikatorer',
			'accountPreferences.watchedIndicatorOptions.none' => 'Aldri',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => 'Filmer og TV-serier',
			'accountPreferences.watchedIndicatorOptions.movies' => 'Kun filmer',
			'accountPreferences.watchedIndicatorOptions.shows' => 'Kun TV-serier',
			'accountPreferences.watchedIndicatorOptions.noneDescription' => 'Ikke vise observerte sjekkmerker.',
			'accountPreferences.watchedIndicatorOptions.moviesAndShowsDescription' => 'Vis sett sjekkmerker for filmer og TV-programmer.',
			'accountPreferences.watchedIndicatorOptions.moviesDescription' => 'Se sjekkmerker for filmer bare.',
			'accountPreferences.watchedIndicatorOptions.showsDescription' => 'Se seerte sjekkmerker for TV-serier bare.',
			'accountPreferences.mediaReviewsVisibility' => 'Vurderinger og anmeldelser',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'Brukere og kritikere',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'Kun brukere',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'Kun kritikere',
			'accountPreferences.mediaReviewsOptions.nobody' => 'Skjult',
			'accountPreferences.mediaReviewsOptions.usersAndCriticsDescription' => 'Vis både brukervurderinger og kritiske vurderinger.',
			'accountPreferences.mediaReviewsOptions.usersOnlyDescription' => 'Vis vurderinger og anmeldelser som er lagt fram av brukerne.',
			'accountPreferences.mediaReviewsOptions.criticsOnlyDescription' => 'Vis kritiske vurderinger og anmeldelser.',
			'accountPreferences.mediaReviewsOptions.nobodyDescription' => 'Skjære vurderinger og anmeldelser.',
			'accountPreferences.preferredAudioLanguageDescription' => 'Foretrakk lydspor på dette språket når serveren eller spilleren velger en spor automatisk.',
			'accountPreferences.preferredSubtitleLanguageDescription' => 'Foretrukker undertitler sporer i dette språket når undertitlene er valgt automatisk.',
			'accountPreferences.subtitleAccessibilityDescription' => 'Velg om SDH-kapsjoner er foretrukket eller kreves under automatisk undertittelutvalg.',
			'accountPreferences.forcedSubtitleDescription' => 'Velg om tvunget undertittelspor er foretrukket eller nødvendig i løpet av automatisk utvalg.',
			'accountPreferences.watchedIndicatorDescription' => 'Velg hvilke medietyper som mottar et sett sjekkmerke i servergrensesnittet.',
			'accountPreferences.mediaReviewsVisibilityDescription' => 'Velg hvilken publikum og kritiske vurderinger serveren viser på media sider.',
			'accountPreferences.subtitleModeDescription' => 'Velg når undertitlene åpnes automatisk for denne serverkontoen.',
			'accountPreferences.hubDescription' => 'Disse preferansene lagres på media-serverkontoen din og kan også gjelde for andre kunder.',
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
			'discover.findNext.title' => 'Finn din neste favoritt',
			'discover.findNext.open' => 'Finn din neste favoritt',
			'discover.findNext.anyTime' => 'Uansett varighet',
			'discover.findNext.timeAvailable' => 'Hvor mye tid har du?',
			'discover.findNext.filters' => 'Velg det som passer nå',
			'discover.findNext.watch' => 'Se',
			'discover.findNext.listen' => 'Lytt',
			'discover.findNext.read' => 'Les',
			'discover.findNext.finishable' => ({required Object duration}) => 'Kan fullføres på ${duration}',
			'discover.findNext.aboutDuration' => ({required Object duration}) => 'Omtrent ${duration}',
			'discover.findNext.nextUnit' => ({required Object duration}) => 'Neste kapittel · ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => '${duration} totalt',
			'discover.findNext.timingVaries' => 'Varigheten kan variere',
			'discover.findNext.notNow' => 'Ikke nå',
			'discover.findNext.swipeHint' => 'Sveip omslaget mot en pil, eller bruk knappene nedenfor.',
			'discover.findNext.saved' => 'Lagrede forslag',
			'discover.findNext.savedCount' => ({required Object count}) => 'Lagrede forslag · ${count}',
			'discover.findNext.undo' => 'Angre',
			'discover.findNext.details' => 'Detaljer',
			'discover.findNext.noPicks' => 'Det er ikke noe å velge mellom ennå',
			'discover.findNext.noPicksHint' => 'Koble til et bibliotek eller legg til en mediekilde for å komme i gang.',
			'discover.findNext.noMatches' => 'Ingenting passer akkurat nå',
			'discover.findNext.noMatchesHint' => 'Prøv en annen medietype, eller sett av mer tid.',
			'discover.findNext.allDone' => 'Du har sett alle forslagene',
			'discover.findNext.allDoneHint' => 'Start et nytt utvalg for å se disse forslagene igjen.',
			'discover.findNext.refresh' => 'Finn et nytt utvalg',
			'discover.findNext.sourceReason' => ({required Object source}) => 'Fra ${source}',
			'discover.findNext.libraryReason' => ({required Object library}) => 'Fra ${library}',
			'discover.findNext.ownedReason' => 'Fra biblioteket ditt',
			'discover.findNext.liveNow' => 'Sendes nå',
			'discover.findNext.watchLive' => 'Se direkte',
			'discover.findNext.filterAnything' => 'Hva som helst',
			'discover.findNext.filterWatch' => 'Se',
			'discover.findNext.filterListen' => 'Lytt',
			'discover.findNext.filterRead' => 'Les',
			'discover.findNext.twentyMinutes' => '20 min',
			'discover.findNext.fortyFiveMinutes' => '45 min',
			'discover.findNext.ninetyMinutes' => '90 min',
			'discover.findNext.apply' => 'Bruk',
			'discover.findNext.openFailed' => 'Dette valget er ikke lenger tilgjengelig. Oppdater for å sjekke på nytt.',
			'discover.findNext.changeFailed' => 'Kunne ikke lagre endringen. Prøv igjen.',
			'discover.findNext.savedLimit' => 'Listen over lagrede forslag er full. Fjern et forslag for å lagre et nytt.',
			'discover.findNext.chooseHint' => 'Åpne en tittel, lagre den til senere eller hopp over den.',
			'discover.findNext.howItWorks' => 'Slik fungerer det',
			'discover.findNext.notNowHelp' => 'Hopp over denne tittelen foreløpig. Den blir i biblioteket ditt.',
			'discover.findNext.saveHelp' => 'Lagre den under lagrede valg for denne profilen på denne enheten. Lagring laster ikke ned tittelen.',
			'discover.findNext.openHelp' => 'Velg omslaget for detaljer. Bruk hovedhandlingen til å spille av, lese eller åpne tittelen.',
			'discover.findNext.controlsHelp' => 'Tastatur eller fjernkontroll: velg en knapp, og trykk Enter eller Velg. Angre gjenoppretter det siste valget ditt.',
			'discover.findNext.artworkLoading' => 'Laster bilde…',
			'discover.findNext.artworkUnavailable' => 'Bilde utilgjengelig',
			'discover.findNext.savedFeedback' => 'Lagt til i lagrede valg',
			'discover.findNext.skippedFeedback' => 'Hoppet over foreløpig',
			'discover.findNext.releaseToConfirm' => 'Slipp for å bekrefte',
			'discover.findNext.remoteHint' => 'Omslag i fokus: ← / → velg · Velg: detaljer · ↑ / ↓ flytt fokus',
			'discover.extras' => 'Trailere og ekstramateriale',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Vurdering',
			'discover.director' => 'Regissør',
			'discover.directors' => 'Regissører',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'TV-serie',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} min igjen',
			'discover.moreLikeThis' => 'Mer som dette',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tittel', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} titler', ), 
			'discover.person.born' => 'Født',
			'discover.person.died' => 'Død',
			'discover.person.birthplace' => 'Fødested',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date} (${age} år)',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date} (${age} år gammel)',
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
			'errors.reasonTimedOut' => 'tidsavbrudd på tilkoblingen',
			'errors.reasonUnreachable' => 'medieserveren kunne ikke nås',
			'errors.reasonRefused' => 'medieserveren avviste forespørselen',
			'errors.reasonNotFound' => 'elementet finnes ikke lenger på medieserveren',
			'errors.reasonServerError' => 'medieserveren rapporterte en feil',
			'errors.reasonCancelled' => 'forespørselen ble avbrutt',
			'errors.reasonUnexpected' => 'det oppsto en uventet feil',
			'libraries.playRandomMovie' => 'Spill en tilfeldig film',
			'libraries.randomPickFailed' => 'Kan ikke velge en tilfeldig film fra denne biblioteket.',
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
			'libraries.filterCategories.tag' => 'Tagg',
			_ => null,
		} ?? switch (path) {
			'libraries.filterCategories.unwatched' => 'Usette',
			'libraries.filterCategories.unplayed' => 'Ikke avspilt',
			'libraries.filterCategories.favorites' => 'Favoritter',
			'libraries.filterCategories.filePath' => 'Filbane',
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
			'libraries.sortLabels.dateDownloaded' => 'Dato lastet ned',
			'libraries.sortLabels.size' => 'Størrelse',
			'libraries.sortLabels.library' => 'Bibliotek',
			'libraries.advancedFilters.include' => 'Inkluder',
			'libraries.advancedFilters.exclude' => 'Ekskluder',
			'libraries.advancedFilters.any' => 'Uansett',
			'libraries.advancedFilters.yes' => 'Ja',
			'libraries.advancedFilters.no' => 'Nei',
			'libraries.advancedFilters.not' => ({required Object value}) => 'Ikke ${value}',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '${count} valgt',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '${count} ekskludert',
			'libraries.advancedFilters.searchValues' => 'Søk etter verdier',
			'libraries.advancedFilters.noValues' => 'Ingen verdier',
			'libraries.advancedFilters.matchContains' => 'Inneholder',
			'libraries.advancedFilters.matchNotContains' => 'Inneholder ikke',
			'libraries.advancedFilters.matchIs' => 'Er',
			'libraries.advancedFilters.matchIsNot' => 'Er ikke',
			'libraries.advancedFilters.matchBeginsWith' => 'Begynner med',
			'libraries.advancedFilters.matchEndsWith' => 'Slutter med',
			'libraries.advancedFilters.textHint' => 'Skriv inn tekst',
			'libraries.advancedFilters.from' => 'Fra',
			'libraries.advancedFilters.to' => 'Til',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from} til ${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value} og over',
			'libraries.advancedFilters.atMost' => ({required Object value}) => 'Opptil ${value}',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => 'Siste ${count} dager',
			'libraries.advancedFilters.dateLastYear' => 'Siste år',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => 'Eldre enn ${count} dager',
			'libraries.advancedFilters.dateOlderThanYear' => 'Eldre enn ett år',
			'libraries.selection.selectItems' => 'Velg elementer',
			'libraries.selection.selectedCount' => ({required Object count}) => '${count} valgt',
			'libraries.selection.actions' => 'Seleksjonshandlinger',
			'libraries.selection.confirmDescendants' => 'Dette endrer alle episoder i de utvalgte showene og sesongene.',
			'libraries.selection.confirmUnwatched' => 'Dette nullstiller også avspillingsfremdriften for de valgte elementene.',
			'libraries.selection.confirmCount' => ({required Object count}) => 'Velg elementer: ${count}.',
			'libraries.selection.completed' => ({required Object count}) => 'Oppdaterte elementer: ${count}.',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => 'Oppdatert ${succeeded}; mislyktes ${failed}. mislyktede elementer forblir valgt.',
			'about.title' => 'Om',
			'about.openSourceLicenses' => 'Lisenser for åpen kildekode',
			'about.versionLabel' => ({required Object version}) => 'Versjon ${version}',
			'about.appDescription' => 'En vakker Plex-, Jellyfin- og Emby-klient for Flutter',
			'about.viewLicensesDescription' => 'Vis lisenser for tredjepartsbiblioteker',
			'about.privacyPolicy' => 'Personvernerklæring',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Ingen servere funnet for ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Kunne ikke laste servere: ${error}',
			'serverSelection.noValidServers' => 'Fant ingen brukbare servere på denne kontoen',
			'hubDetail.title' => 'Tittel',
			'hubDetail.releaseYear' => 'Utgivelsesår',
			'hubDetail.dateAdded' => 'Dato lagt til',
			'hubDetail.rating' => 'Vurdering',
			'hubDetail.noItemsFound' => 'Ingen elementer funnet',
			'logs.clearLogs' => 'Tøm logger',
			'logs.copyLogs' => 'Kopier logger',
			'logs.uploadLogs' => 'Last opp logger',
			'logs.saveLogs' => 'Lagre logger til filer',
			'logs.logsSaved' => ({required Object path}) => 'Lister lagret til ${path}',
			'logs.saveLogsFailed' => 'Kan ikke lagre loggfilet.',
			'startup.failedTitle' => 'PlezyNG kunne ikke starte',
			'startup.failedBody' => 'Noe gikk galt under oppstart. Detaljene nedenfor viser hva som feilet.',
			'startup.failedBodyRepairable' => 'PlezyNG\'s lagrede innstillingsfil er skadet og må bygges på nytt før PlezyNG kan starte. Å prøve igjen hjelper ikke – velg Reparer lagring.',
			'startup.phaseLabel' => 'Trinn',
			'startup.showDetails' => 'Vis detaljer',
			'startup.hideDetails' => 'Skjul detaljer',
			'startup.copyDetails' => 'Kopier detaljer',
			'startup.detailsCopied' => 'Detaljer kopiert til utklippstavlen',
			'startup.uploadDetails' => 'Last opp detaljer',
			'startup.repairStorage' => 'Reparer lagring',
			'startup.repairTitle' => 'Reparere lagrede data?',
			'startup.repairBodyCommon' => 'PlezyNG\'s innstillingsfil er skadet og kan ikke leses. Reparasjon tilbakestiller alle innstillinger til standard.',
			'startup.repairBodyOneCredential' => 'Én lagret pålogging er skadet og kan ikke leses. Reparasjon fjerner bare den; de andre innstillingene dine blir urørt.',
			'startup.repairBodySignInsKept' => 'Serverne og profilene dine skal forbli pålogget.',
			'startup.repairBodySignInsLost' => 'Nøkkelen som beskytter de lagrede påloggingene dine kan ikke gjenvinnes fra denne filen, så du må logge på alle servere og profiler på nytt. Ingenting på medieserveren din påvirkes.',
			'startup.repairBodySessionsUncertain' => 'Trackere (MAL, AniList, Simkl, Trakt) og Seerr lagres separat og kan overleve eller ikke. PlezyNG vil fortelle deg nøyaktig hva det beholdt.',
			'startup.repairConfirm' => 'Reparer',
			'startup.repairSucceeded' => 'Lagring reparert',
			'startup.repairNeedsRestart' => 'Lagring reparert – omstart kreves',
			'startup.restartRequiredBody' => 'Dataene dine ble reparert, men PlezyNG må starte på nytt før det kan bruke dem. Lukk PlezyNG og åpne det igjen.',
			'startup.quitPlezy' => 'Avslutt PlezyNG',
			'startup.repairFailed' => 'Reparasjon mislyktes',
			'startup.repairKeptSignIns' => 'Serverne og profilene dine er fortsatt pålogget.',
			'startup.repairLostSignIns' => 'Nøkkelen som beskytter de lagrede påloggingene dine kunne ikke gjenvinnes. Du må logge på alle servere og profiler på nytt.',
			'startup.repairLostSessions' => 'Minst én tracker- eller Seerr-tilkobling gikk tapt og må kobles til på nytt.',
			'startup.backupTitle' => 'En kopi av den skadede filen ble beholdt',
			'startup.backupWarning' => 'Den inneholder påloggingsinformasjonen din. Ikke last den opp eller del den.',
			'startup.deleteBackup' => 'Slett kopi',
			'startup.backupDeleted' => 'Kopi slettet.',
			'startup.previousFailureTitle' => 'PlezyNG mislyktes i å starte forrige gang',
			'licenses.relatedPackages' => 'Relaterte pakker',
			'licenses.license' => 'Lisens',
			'licenses.licenseNumber' => ({required Object number}) => 'Lisens ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} lisenser',
			'navigation.libraries' => 'Biblioteker',
			'navigation.downloads' => 'Nedlastinger',
			'navigation.liveTv' => 'Direkte-TV',
			'navigation.explore' => 'Utforsk',
			'explore.mdblistShelves.manage' => 'Utforsk skjeletter',
			'explore.mdblistShelves.manageDescription' => 'Velg og ordne oppføringer fra kontoen din MDBList',
			'explore.mdblistShelves.description' => 'Velg offentlige film- og TV-lister fra kontoen din MDBList. opprette eller kopiere lister på MDBList, og oppdater deretter.',
			'explore.mdblistShelves.selected' => 'Velg skjelett',
			'explore.mdblistShelves.available' => 'Tilgjengelige kontoer',
			'explore.mdblistShelves.noLists' => 'Ingen offentlig film eller TV-lister returneres. opprette eller kopiere en liste på MDBList, og oppdater deretter.',
			'explore.mdblistShelves.displayName' => 'Shelf Display navn',
			'explore.mdblistShelves.nameHint' => 'La det være å bruke kildelistenavnet.',
			'explore.mdblistShelves.add' => 'Legg til shelf',
			'explore.mdblistShelves.save' => 'Sparer shelter',
			'explore.mdblistShelves.moveUp' => ({required Object title}) => 'Flytte ${title} opp',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => 'Flytte ${title} ned',
			'explore.mdblistShelves.unavailable' => 'Denne listen er ikke tilgjengelig. Retur eller fjerne skjoldet i innstillinger.',
			'explore.mdblistShelves.rateLimited' => 'MDBList forespørselsgrense er nådd. vennligst trekke tilbake senere.',
			'explore.mdblistShelves.loadFailed' => 'Kan ikke laste opp skjermer. sjekk koblingen din og tilbakekall.',
			'explore.mdblistShelves.saveFailed' => 'Kan ikke spares, så snill tilbake.',
			'explore.mdblistShelves.accountChanged' => 'Konto eller profil endret. Åpne disse innstillingene igjen.',
			'explore.mdblistShelves.settingsUnreadable' => 'Spare skjermer kan ikke leses. Velg listen din igjen for å erstatte disse innstillingene.',
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
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episode', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episoder', ), 
			'explore.cast' => 'Skuespillere',
			'explore.characters' => 'Figurer',
			'explore.addToWatchlist' => 'Legg til i ønskeliste',
			'explore.removeFromWatchlist' => 'Fjern fra ønskeliste',
			'explore.addedToWatchlist' => 'Lagt til i overvåkningslisten',
			'explore.removedFromWatchlist' => 'Fjernet fra overvåkningslisten',
			'explore.watchlistUpdateFailed' => 'Kunne ikke oppdatere ønskelisten',
			'explore.watchlistNoMatch' => 'Kunne ikke koble dette elementet til en overvåkningsliste',
			'explore.notInLibrary' => 'Ikke i biblioteket ditt',
			'explore.inTheseLibraries' => 'I disse bibliotekene',
			'explore.checkingLibrary' => 'Sjekker biblioteket ditt...',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: 'Kunne ikke sjekke ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} server', other: 'Kunne ikke sjekke ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} servere', ), 
			'explore.emptyTitle' => 'Ingenting her ennå',
			'explore.emptyMessage' => ({required Object source}) => 'Rader fra ${source} vises her når de har innhold.',
			'explore.searchHint' => ({required Object source}) => 'Søk i ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'Ingen treff for "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'Søk etter filmer og serier på ${source}.',
			'explore.searchFailed' => 'Søk mislyktes. Sjekk tilkoblingen og prøv igjen.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} populær',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} på lufta',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} vurdert',
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
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} kommentar', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} kommentarer', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} stemmer',
			'explore.stats.watching' => ({required Object n}) => '${n} ser på den',
			'explore.stats.completed' => ({required Object n}) => '${n} fullførte',
			'explore.stats.onHold' => ({required Object n}) => '${n} på pause',
			'explore.stats.dropped' => ({required Object n}) => '${n} droppet',
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
			'explore.creditRole.actor' => 'Skuespiller',
			'explore.creditRole.director' => 'Regissør',
			'explore.creditRole.writer' => 'Forfatter',
			'explore.creditRole.producer' => 'Produsent',
			'explore.creditRole.creator' => 'Skaper',
			'explore.creditRole.composer' => 'Komponist',
			'explore.relation.prequel' => 'Forløper',
			'explore.relation.sequel' => 'Oppfølger',
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
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: 'Anbefalt av ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} bruker', other: 'Anbefalt av ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} brukere', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'Anbefalt av ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'Favorisert av ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} har ikke blitt sendt ennå',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'Anbefalt av ${percent} av seerne',
			'explore.detail.relatedTitles' => 'Relaterte titler',
			'explore.detail.background' => 'Bakgrunn',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} resultat', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} resultater', ), 
			'liveTv.title' => 'Direkte-TV',
			'liveTv.guide' => 'Programguide',
			'liveTv.noChannels' => 'Ingen kanaler tilgjengelig',
			'liveTv.noDvr' => 'Ingen DVR konfigurert på noen server',
			'liveTv.serverUnavailable' => 'Direkte-TV-serveren er ikke tilgjengelig.',
			'liveTv.serverNotConnected' => 'Direkte-TV-serveren er ikke tilkoblet.',
			'liveTv.noPrograms' => 'Ingen programdata tilgjengelig',
			'liveTv.liveStreamFailed' => 'Direktesending mislyktes',
			'liveTv.unknownProgram' => 'Ukjent program',
			'liveTv.timelineLiveProgram' => 'Live program (playback kan være utenfor dette programmet)',
			'liveTv.timelineBuffer' => 'Buffertidslinje',
			'liveTv.timelineUnavailable' => 'Tidslinje utilgjengelig',
			'liveTv.timelineEstimated' => 'Bedre spillback',
			'liveTv.timelinePending' => 'Løp etter',
			'liveTv.timelineStale' => 'Planen kan være fortidig',
			'liveTv.unknownHub' => 'Ukjent',
			'liveTv.unknownError' => 'Ukjent feil',
			'liveTv.channelNumber' => ({required Object number}) => 'Kanal ${number}',
			'liveTv.unknownChannel' => 'Ukjent kanal',
			'liveTv.live' => 'DIREKTE',
			'liveTv.premiereBadge' => 'Nytt',
			'liveTv.reloadGuide' => 'Last inn programguide på nytt',
			'liveTv.searchGuide' => 'Søk i programguiden',
			'liveTv.searchHint' => 'Søk etter kanaler og programmer',
			'liveTv.searchNoResults' => ({required Object query}) => 'Ingen treff for "${query}"',
			'liveTv.channelsSection' => 'Kanaler',
			'liveTv.programsSection' => 'Programmer',
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
			'liveTv.noFavoriteChannels' => 'Ingen favorittkanaler',
			'liveTv.noFavoriteChannelsHint' => 'Vis alle kanaler, og trykk deretter lenge på en kanal for å legge den til i favorittene dine.',
			'liveTv.showAllChannels' => 'Vis alle kanaler',
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
			'liveTv.guideReloadFailed' => 'Kunne ikke oppdatere programguiden',
			'liveTv.rulesProcessRequested' => 'Ny vurdering av reglene er forespurt',
			'liveTv.rulesProcessFailed' => 'Kunne ikke kjøre opptaksreglene på nytt',
			'liveTv.recordShow' => 'Ta opp program',
			'liveTv.recordSettings.startEarly' => 'Start tidligere (sekunder)',
			'liveTv.recordSettings.endLate' => 'Slutt senere (sekunder)',
			'liveTv.recordSettings.newOnly' => 'Bare nye episoder',
			'liveTv.recordSettings.anyChannel' => 'Ta opp på alle kanaler',
			'liveTv.recordSettings.anyTime' => 'Ta opp når som helst',
			'liveTv.recordSettings.skipInLibrary' => 'Hopp over episoder som allerede finnes i biblioteket',
			'liveTv.recordSettings.keepUpTo' => 'Episoder som skal beholdes',
			'liveTv.recordSettings.keepUpToHint' => '0 beholder alle episoder',
			'liveTv.startingInMinutes' => ({required Object minutes}) => 'Starter om ${minutes} min',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} kl. ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product} returnerte ugyldige avspillingsdata for direkte-TV',
			'liveTv.failedToStartChannel' => 'Kunne ikke starte direktekanalen',
			'liveTv.failedToBuildStreamUrl' => 'Kunne ikke opprette strømme-URL-en',
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'Kunne ikke starte kanalen: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'Kunne ikke bytte kanal: ${reason}',
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
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} element', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} elementer', ), 
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
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} spor', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} spor', ), 
			'music.nowPlaying' => 'Spilles nå',
			'music.playingFrom' => ({required Object title}) => 'Spiller fra ${title}',
			'music.queue' => 'Kø',
			'music.clearQueue' => 'Tøm kø',
			'music.lyrics' => 'Sangtekst',
			'music.visualizer' => 'Visualiser',
			'music.visualizerProfileLoading' => 'Lesing av track analyse.',
			'music.visualizerAmbientMotion' => 'Miljøbevegelse',
			'music.visualizerPlexLoudness' => 'Plex støy',
			'music.visualizerPreviousPreset' => 'Tidligere visuell stil',
			'music.visualizerNextPreset' => 'Neste visuell stil',
			'music.visualizerPresetAurora' => 'Aurora',
			'music.visualizerPresetBloom' => 'Blomst',
			'music.visualizerPresetOrbitals' => 'Orbitale',
			'music.visualizerPresetPrism' => 'Prism',
			'music.visualizerPresetTunnel' => 'Tunnel',
			'music.visualizerPresetTrackMap' => 'Track kart',
			'music.noLyrics' => 'Ingen sangtekst tilgjengelig',
			'music.sleepTimer' => 'Innsovningstimer',
			'music.sleepTimerEndOfTrack' => 'Slutten av sporet',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutt', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutter', ), 
			'music.stopPlayback' => 'Stopp avspilling',
			'music.previousTrack' => 'Forrige spor',
			'music.nextTrack' => 'Neste spor',
			'music.repeat' => 'Gjenta',
			'music.repeatAll' => 'Gjenta alle',
			'music.repeatOne' => 'Gjenta ett spor',
			'music.instantMixNoServer' => 'Ingen server er tilgjengelig for en hurtigmiks',
			'music.instantMixFailed' => 'Kunne ikke laste inn direktemiksen',
			'music.instantMixEmpty' => 'Direktemiksen ga ingen spor',
			'music.noAudioUrl' => ({required Object track}) => 'Ingen lyd-URL er tilgjengelig for ${track}',
			'music.discography.singlesAndEps' => 'Singler og EP-er',
			'music.discography.live' => 'Live',
			'music.discography.compilations' => 'Samlealbum',
			'watchTogether.title' => 'Se sammen',
			'watchTogether.description' => 'Se innhold synkronisert med venner og familie',
			'watchTogether.createRoom' => 'Opprett rom',
			'watchTogether.creatingRoom' => 'Oppretter rom...',
			'watchTogether.joinRoom' => 'Bli med i rom',
			'watchTogether.joiningRoom' => 'Blir med i rom...',
			'watchTogether.connecting' => 'Kobler til...',
			'watchTogether.relayPublic' => 'Rom bruker de offentlige Open Watch Party-reléserverne.',
			'watchTogether.relayCustom' => ({required Object url}) => 'Rom bruker reléserveren din på ${url}.',
			'watchTogether.recentRooms' => 'Nylige rom',
			'watchTogether.roomActions' => 'Romhandlinger',
			'watchTogether.renameRoom' => 'Gi nytt navn til rom',
			'watchTogether.removeRoom' => 'Fjern',
			'watchTogether.enterRoomCode' => 'Skriv inn koden på 6 tegn fra verten.',
			'watchTogether.roomCode' => 'Romkode',
			'watchTogether.paste' => 'Lim inn',
			'watchTogether.noCodeInClipboard' => 'Utklippstavlen inneholder ingen romkode',
			'watchTogether.copyCode' => 'Kopier kode',
			'watchTogether.codeCopied' => 'Romkode kopiert',
			'watchTogether.shareInvite' => 'Del invitasjon',
			'watchTogether.inviteCopied' => 'Invitasjon kopiert. Lim den inn i en melding.',
			'watchTogether.inviteMessage' => ({required Object code}) => 'Bli med i Se sammen-rommet mitt i PlezyNG: åpne Se sammen, velg «Bli med i rom» og skriv inn ${code}.',
			'watchTogether.openSessionControls' => 'Åpne øktkontroller for Se sammen',
			'watchTogether.reconnecting' => 'Kobler til på nytt...',
			'watchTogether.reconnectingDescription' => 'Tilkoblingen ble brutt. Du blir automatisk med i rommet igjen.',
			'watchTogether.connected' => 'Tilkoblet',
			'watchTogether.disconnected' => 'Frakoblet',
			'watchTogether.youAreHost' => 'Du er verten',
			'watchTogether.hostedBy' => ({required Object name}) => 'Vert: ${name}',
			'watchTogether.hostControlsPlayback' => 'Verten kontrollerer avspilling',
			'watchTogether.anyoneCanControl' => 'Alle kan kontrollere avspilling',
			'watchTogether.roomLocked' => 'Rommet er låst',
			'watchTogether.nowPlaying' => 'Spilles nå',
			'watchTogether.nothingPlaying' => 'Ingenting spilles',
			'watchTogether.nothingPlayingHost' => 'Spill av noe fra et hvilket som helst bibliotek for å dele det med rommet.',
			'watchTogether.nothingPlayingGuest' => 'Når verten spiller av noe, åpnes det her.',
			'watchTogether.notShareable' => 'Denne videoen har ingen treff i katalogen, så bare de med tilgang til samme server kan spille den av.',
			'watchTogether.searching' => 'Ser etter denne videoen i bibliotekene dine...',
			'watchTogether.yourCopy' => 'Din kopi',
			'watchTogether.sharingYourCopy' => 'Du deler din kopi',
			'watchTogether.playingOtherLength' => ({required Object difference}) => 'Spiller av din kopi, ${difference}',
			'watchTogether.mismatchTitle' => 'Kopien din har en annen lengde',
			'watchTogether.mismatchDescription' => ({required Object difference}) => 'Den nærmeste kopien din er ${difference} enn videoen i rommet. Det kan være en annen klipping eller versjon.',
			'watchTogether.playAnyway' => 'Spill av likevel',
			'watchTogether.chooseAnotherCopy' => 'Velg en annen kopi',
			'watchTogether.dontPlay' => 'Ikke spill av',
			_ => null,
		} ?? switch (path) {
			'watchTogether.unavailableTitle' => 'Du har ikke denne videoen',
			'watchTogether.unavailableDescription' => 'PlezyNG fant den ikke i bibliotekene dine. Velg en kopi selv eller søk på nytt.',
			'watchTogether.chooseCopy' => 'Velg en kopi',
			'watchTogether.searchAgain' => 'Søk på nytt',
			'watchTogether.noCandidates' => 'Fant ingen kopier i bibliotekene dine.',
			'watchTogether.choiceFailed' => 'Kunne ikke spille av denne kopien for rommet',
			'watchTogether.lengthLonger' => ({required Object duration}) => '${duration} lengre',
			'watchTogether.lengthShorter' => ({required Object duration}) => '${duration} kortere',
			'watchTogether.lengthSame' => 'Samme lengde',
			'watchTogether.lengthUnknown' => 'Ukjent lengde',
			'watchTogether.joinCurrentPlayback' => 'Bli med i gjeldende avspilling',
			'watchTogether.joinCurrentPlaybackDescription' => 'Hopp tilbake til det verten ser på nå',
			'watchTogether.stopMedia' => 'Stopp videoen for alle',
			'watchTogether.syncOffset' => 'Tidsforskyvning',
			'watchTogether.syncOffsetDescription' => 'Forskyv videoen din hvis den ligger foran eller bak rommet.',
			'watchTogether.offsetHint' => ({required Object difference}) => 'Kopien din er ${difference} enn videoen i rommet.',
			'watchTogether.applyDifference' => ({required Object offset}) => 'Bruk ${offset}',
			'watchTogether.offsetMinusSecond' => '-1 s',
			'watchTogether.offsetMinusTenth' => '-100 ms',
			'watchTogether.offsetPlusTenth' => '+100 ms',
			'watchTogether.offsetPlusSecond' => '+1 s',
			'watchTogether.participants' => 'Deltakere',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} deltaker', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} deltakere', ), 
			'watchTogether.hostBadge' => 'VERT',
			'watchTogether.nameYou' => ({required Object name}) => '${name} (deg)',
			'watchTogether.playerIdle' => 'Inaktiv',
			'watchTogether.playerLoading' => 'Laster',
			'watchTogether.playerReady' => 'Klar',
			'watchTogether.playerBuffering' => 'Bufrer',
			'watchTogether.matchSearching' => 'Søker',
			'watchTogether.matchMatched' => 'Har videoen',
			'watchTogether.matchMismatched' => 'Annen lengde',
			'watchTogether.matchUnavailable' => 'Har ikke videoen',
			'watchTogether.participantOffset' => ({required Object offset}) => 'Forskyvning ${offset}',
			'watchTogether.makeHost' => 'Gjør til vert',
			'watchTogether.makeHostQuestion' => 'Overfør vert?',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} vil kontrollere avspillingen og styre økten for alle.',
			'watchTogether.transfer' => 'Overfør',
			'watchTogether.removeParticipant' => 'Fjern fra rommet',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => 'Fjerne ${name}?',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} fjernes fra rommet, men kan bli med igjen med koden med mindre du låser rommet.',
			'watchTogether.remove' => 'Fjern',
			'watchTogether.roomSettings' => 'Rominnstillinger',
			'watchTogether.letEveryoneControl' => 'La alle kontrollere avspillingen',
			'watchTogether.lockRoom' => 'Lås rommet',
			'watchTogether.lockRoomDescription' => 'Ingen nye kan bli med',
			'watchTogether.leaveRoom' => 'Forlat rommet',
			'watchTogether.leaveRoomQuestion' => 'Forlate rommet?',
			'watchTogether.leaveRoomConfirm' => 'Du kan bli med igjen med romkoden.',
			'watchTogether.leave' => 'Forlat',
			'watchTogether.endRoom' => 'Avslutt rommet',
			'watchTogether.endRoomQuestion' => 'Avslutte rommet?',
			'watchTogether.endRoomConfirm' => 'Dette avslutter rommet for alle.',
			'watchTogether.end' => 'Avslutt',
			'watchTogether.playBlockedTitle' => 'Avspillingen startet ikke',
			'watchTogether.playBlockedDescription' => 'Trykk på spill av for å begynne å se sammen med rommet.',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} trykket på spill av',
			'watchTogether.notices.playbackStarted' => 'Avspillingen startet',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} satte avspillingen på pause',
			'watchTogether.notices.playbackPaused' => 'Avspillingen ble satt på pause',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} hoppet til ${position}',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => 'Hoppet til ${position}',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} satte hastigheten til ${speed}',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => 'Hastigheten satt til ${speed}',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} startet ${title}',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => 'Spilles nå: ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} stoppet videoen',
			'watchTogether.notices.mediaStopped' => 'Videoen stoppet',
			'watchTogether.notices.waitingFor' => ({required Object name}) => 'Venter på ${name}...',
			'watchTogether.notices.waitingForSomeone' => 'Venter på at noen skal ta igjen...',
			'watchTogether.notices.finished' => 'Ferdig',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} er nå verten',
			'watchTogether.notices.youAreNowHost' => 'Du er nå verten',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} ble med',
			'watchTogether.notices.left' => ({required Object name}) => '${name} forlot',
			'watchTogether.notices.controlRefused' => 'Bare verten kan kontrollere avspillingen',
			'watchTogether.notices.searchFailed' => 'Enkelte servere kunne ikke gjennomsøkes etter videoen i rommet',
			'watchTogether.notices.playBlocked' => 'Trykk på spill av for å starte',
			'watchTogether.notices.shareFailed' => 'Kunne ikke dele denne videoen med rommet',
			'watchTogether.notices.downloadNotShared' => 'Nedlastinger deles ikke med rommet mens serveren deres er frakoblet',
			'watchTogether.notices.openFailed' => 'Kunne ikke åpne videoen i rommet',
			'watchTogether.ended.ended' => 'Verten avsluttet rommet',
			'watchTogether.ended.kicked' => 'Du ble fjernet fra rommet',
			'watchTogether.ended.expired' => 'Rommet er utløpt',
			'watchTogether.ended.replaced' => 'Du ble med i dette rommet på en annen enhet',
			'watchTogether.ended.lost' => 'Mistet tilkoblingen til rommet',
			'watchTogether.errors.invalidCode' => 'Det er ikke en romkode. Koder har 6 bokstaver og sifre, uten 0, 1, I, L eller O.',
			'watchTogether.errors.roomNotFound' => 'Ingen rom har den koden. Det kan være avsluttet.',
			'watchTogether.errors.roomFull' => 'Rommet er fullt.',
			'watchTogether.errors.roomLocked' => 'Verten har låst rommet.',
			'watchTogether.errors.relayFull' => 'Se sammen er opptatt akkurat nå. Prøv igjen senere.',
			'watchTogether.errors.unreachable' => 'Kunne ikke nå reléserveren for Se sammen. Sjekk tilkoblingen.',
			'watchTogether.errors.rateLimited' => 'For mange forsøk. Vent litt og prøv igjen.',
			'watchTogether.errors.clientBlocked' => 'Denne versjonen av PlezyNG kan ikke bruke reléserveren. Oppdater appen.',
			'watchTogether.errors.forbidden' => 'Bare verten kan gjøre det.',
			'watchTogether.errors.notInRoom' => 'Du er ikke i et rom.',
			'watchTogether.errors.alreadyInRoom' => 'Du er allerede i et rom.',
			'watchTogether.errors.resumeFailed' => 'Kunne ikke bli med i rommet igjen.',
			'watchTogether.errors.unsupported' => 'Reléserveren støtter ikke dette.',
			'watchTogether.errors.generic' => 'Noe gikk galt. Prøv igjen.',
			'watchTogether.untitledEpisode' => ({required Object number}) => 'Episode ${number}',
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
			'downloads.storageFull' => 'Nedlastingene ble stoppet for å beskytte ledig lagringsplass. Frigjør plass eller velg en annen nedlastingsplassering, og prøv igjen.',
			'downloads.storageUnavailable' => 'Nedlastingene ble stoppet fordi tilgjengelig lagringsplass ikke kunne sjekkes. Sjekk nedlastingsstedet, og prøv igjen.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} episoder i nedlastingskø',
			'downloads.downloadDeleted' => 'Nedlasting slettet',
			'downloads.deleteConfirm' => ({required Object title}) => 'Slette "${title}" fra denne enheten?',
			'downloads.deleteCollectionDownloads' => 'Slett nedlastinger',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => 'Slette alle nedlastinger i «${title}» fra denne enheten?',
			'downloads.collectionDownloadsDeleted' => 'Nedlastinger slettet',
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
			'downloads.retryAll' => 'Prøv alle på nytt',
			'downloads.retryFailed' => 'Prøv mislykkede nedlastinger på nytt',
			'downloads.deleteAll' => 'Slett alle',
			'downloads.selectVersion' => 'Velg versjon',
			'downloads.allEpisodes' => 'Alle episoder',
			'downloads.unwatchedOnly' => 'Kun usette',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Neste ${count} usette',
			'downloads.customAmount' => 'Egendefinert antall...',
			'downloads.customAmountAny' => 'Tilpasset beløp ( hvert år)',
			'downloads.randomEpisodes' => 'Random episoder',
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
			'downloads.syncNow' => 'Synkronisering nå',
			'downloads.downloadsUpToDate' => 'Nedlastinger er oppdatert',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => 'Synk full · ${queued} queued, ${removed} fjernet',
			'downloads.activeSyncRules' => 'Synkroniseringsregler',
			'downloads.reviewOrphanFiles' => 'Se over foreldreløse nedlastinger',
			'downloads.orphanReviewTitle' => 'Se over foreldreløse nedlastinger',
			'downloads.orphanReviewDescription' => 'Disse merkede filene ligger i PlezyNGs standardmapper for appstyrte nedlastinger, men har ingen tilsvarende nedlastingsoppføring eller aktiv oppgave. Kontroller listen før du sletter dem.',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count} filer · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => 'Slett ${count} filer',
			'downloads.orphanCleanupNone' => 'Fant ingen foreldreløse nedlastingsfiler',
			'downloads.orphanCleanupFailed' => 'PlezyNG kunne ikke skanne den administrerte nedlastingsmappen på en trygg måte. Ingen filer ble slettet.',
			'downloads.orphanCleanupChanged' => 'Nedlastingslisten ble endret mens du gikk gjennom den. Se over filene på nytt før du rydder opp.',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => 'Slettet ${count} foreldreløse filer · ${size} frigjort',
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
			'downloads.syncRuleAccessDenied' => 'Tilgang nektet',
			'downloads.syncRuleNotAvailableForProfile' => 'Ikke tilgjengelig for gjeldende profil',
			'downloads.syncRuleUnknownServer' => 'Ukjent server',
			'downloads.syncRuleListCreated' => 'Synkroniseringsregel opprettet',
			'downloads.backgroundWarning.bannerBlocked' => 'Nedlastinger stopper når du forlater appen',
			'downloads.backgroundWarning.bannerDegraded' => 'Bakgrunnsnedlastinger kan være begrenset',
			'downloads.backgroundWarning.bannerAction' => 'Detaljer',
			'downloads.backgroundWarning.sheetTitle' => 'Bakgrunnsnedlastinger er blokkert',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Bakgrunnsnedlastinger kan være begrenset',
			'downloads.backgroundWarning.sheetIntro' => 'Android hindrer PlezyNG i å laste ned pålitelig i bakgrunnen.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Enheten din begrenser når PlezyNG kan laste ned i bakgrunnen.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'Bakgrunnsbruken til PlezyNG er begrenset. Sett batteribruk eller bakgrunnsbruk til «Ubegrenset».',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android har satt PlezyNG i begrenset hvilemodus. Sett batteribruken til «Ubegrenset».',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Varsler om nedlastinger er slått av, så fremdrift og kontroller kan være utilgjengelige.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Varsler er slått av. På Android 13 eller nyere kreves de for lange bakgrunnsnedlastinger.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Datasparing er slått på og blokkerer bakgrunnsnedlastinger via mobildata. Nedlastinger skal fortsatt fungere på Wi-Fi.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Nedlastinger har stoppet gjentatte ganger mens PlezyNG var i bakgrunnen. Sjekk innstillingene for batteribruk eller bakgrunnsbruk for PlezyNG.',
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
			'downloads.options' => 'Valg for nedlastinger',
			'downloads.groupings.library' => 'Bibliotek',
			'downloads.groupings.collections' => 'Samlinger',
			'downloads.unknownLibrary' => 'Ukjent bibliotek',
			'downloads.unknownShow' => 'Ukjent serie',
			'downloads.unknownSeason' => 'Ukjent sesong',
			'downloads.unknownAlbum' => 'Ukjent album',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} fullført',
			'downloads.storageUsed' => ({required Object size}) => 'Brukte lagringsplasser: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} nedlasting', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} nedlastinger', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} viser', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} viser', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} film', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmer', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} album', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} album', ), 
			'downloads.errorFileNotFound' => 'Filen ble ikke funnet (404)',
			'downloads.errorDownloadNotAllowed' => 'Serveren tillater ikke nedlasting (403)',
			'downloads.errorDownloadFailed' => 'Nedlastingen mislyktes',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'Nedlastingen mislyktes: ${reason}',
			'downloads.convertingOnServer' => 'Konvertering på server',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => 'Konverteringer på server · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => 'Nedlastingen mislyktes (HTTP ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => 'Etterbehandlingen mislyktes: ${reason}',
			'downloads.reasonFileNotSaved' => 'filen kunne ikke lagres på denne enheten',
			'downloads.reasonCannotResume' => 'den delvise nedlastingen kunne ikke gjenopptas',
			'downloads.reasonDeviceStorageFull' => 'denne enheten er tom for lagringsplass',
			'downloads.notificationDownloading' => 'Laster ned...',
			'downloads.notificationComplete' => 'Nedlastingen er fullført',
			'downloads.notificationPaused' => 'Nedlastingen er satt på pause',
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
			'companionRemote.session.manualAddressHint' => 'Manuell tilkoblingsadresse:',
			'companionRemote.pairing.discoveryDescription' => 'PlezyNG-enheter med samme Plex-konto vises her',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Kobler til...',
			'companionRemote.pairing.searchingForDevices' => 'Søker etter enheter...',
			'companionRemote.pairing.noDevicesFound' => 'Ingen enheter funnet på nettverket ditt',
			'companionRemote.pairing.noDevicesHint' => 'Åpne PlezyNG på datamaskinen, og bruk samme Wi-Fi',
			'companionRemote.pairing.availableDevices' => 'Tilgjengelige enheter',
			'companionRemote.pairing.manualConnection' => 'Manuell tilkobling',
			'companionRemote.pairing.cryptoInitFailed' => 'Kunne ikke starte sikker tilkobling. Logg inn på Plex først.',
			'companionRemote.pairing.validationHostRequired' => 'Vennligst oppgi vertsadresse',
			'companionRemote.pairing.validationHostFormat' => 'Format må være IP:port (f.eks. 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Tilkoblingen fikk tidsavbrudd. Bruk samme nettverk på begge enheter.',
			'companionRemote.pairing.sessionNotFound' => 'Enhet ikke funnet. Sørg for at PlezyNG kjører på verten.',
			'companionRemote.pairing.authFailed' => 'Autentisering mislyktes. Begge enheter må bruke samme Plex-konto.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Kunne ikke koble til: ${error}',
			'companionRemote.pairing.codeTitle' => 'Paring kode',
			'companionRemote.pairing.codeDescription' => 'Skriv inn koden som vises i Companion Remote på host-enheten.Båda enhetene må bruke en versjon som støtter sikker paring.',
			'companionRemote.pairing.codeInvalid' => 'Skriv inn alle 32 bokstaver og tall fra hostekoden.',
			'companionRemote.pairing.updateRequired' => 'Oppdater begge enhetene til en versjon som støtter sikker paring.',
			'companionRemote.pairing.hostDescription' => 'Skriv inn denne koden en gang på hver fjerntjeneste. Hold den privat: den gir kontroll over denne profilen.',
			'companionRemote.pairing.resetCode' => 'For å gjenopprette paring-koden',
			'companionRemote.pairing.resetDescription' => 'Slå av alle fjernet og opprette en ny kode. hver fjernet må parere igjen.',
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
			'companionRemote.closedBeforeAuth' => 'Tilkoblingen ble lukket før autentisering',
			'videoSettings.playbackSpeed' => 'Avspillingshastighet',
			'videoSettings.normalSpeed' => 'Normal',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Aktiv (${duration})',
			'videoSettings.zoom' => 'Zoom',
			'videoSettings.sleepTimer' => 'Innsovningstimer',
			'videoSettings.audioSync' => 'Lydsynkronisering',
			'videoSettings.subtitleSync' => 'Undertekstsynkronisering',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'HDR er ikke tilgjengelig her – denne skrivebordskompositoren eller videoutgangen kan ikke overføre HDR.',
			'videoSettings.hdrToneMapping' => 'HDR-tonekartlegging',
			'videoSettings.hdrToneMappingCompositor' => 'Kompositor',
			'videoSettings.hdrToneMappingCompositorDescription' => 'Send kildens HDR-metadata videre, og la skrivebordskompositoren utføre tonekartleggingen.',
			'videoSettings.hdrToneMappingPlayer' => 'Spiller',
			'videoSettings.hdrToneMappingPlayerDescription' => 'Tilpass til skjermens maksimale lysstyrke i spilleren, og send deretter resultatet til kompositoren.',
			'videoSettings.hdrToneMappingFailed' => 'Kunne ikke endre HDR-tonekartleggingen – den forrige modusen er fortsatt aktiv.',
			'videoSettings.audioOutput' => 'Lydutgang',
			'videoSettings.performanceOverlay' => 'Ytelsesoverlegg',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'Surround',
			'videoSettings.audioOutputSpatial' => 'Romlig lyd',
			'videoSettings.audioOutputStereo' => 'Stereo',
			'videoSettings.audioEqualizer' => 'Lydequalizer',
			'videoSettings.audioEqualizerDescription' => 'Tilpass fem frekvensbånd for denne enheten. tilgjengelig på mpv; en aktiv EQ dekoder lyd og avbryter matchhrough.',
			'videoSettings.audioEqualizerFlat' => 'Nøytral',
			'videoSettings.audioEqualizerActive' => 'Egendefinert',
			'videoSettings.audioEqualizerSaveFailed' => 'Kan ikke lagre lydekvaliser innstillinger.',
			'videoSettings.backgroundVideoAudio' => 'Video bakgrunnsvideo',
			'videoSettings.backgroundVideoAudioDescription' => 'Hold video-audio-spillingen når du forlater spilleren; bildet er skjult til du vender tilbake. Android bruker en media-spillingsanmeldelse.',
			'videoSettings.audioNormalization' => 'Normaliser lydstyrke',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'Dekoder lyd til PCM; direkte lydutgang er av mens dette er på',
			'performanceOverlay.color' => 'Farge',
			'performanceOverlay.performance' => 'Ytelse',
			'performanceOverlay.buffer' => 'Buffer',
			'performanceOverlay.app' => 'App',
			'performanceOverlay.decoder' => 'Dekoder',
			'performanceOverlay.rawDecoder' => 'Rå dekoder',
			'performanceOverlay.tunneling' => 'Tunneling',
			'performanceOverlay.passthrough' => 'Direkte utgang',
			'performanceOverlay.aspect' => 'Format',
			'performanceOverlay.rotation' => 'Rotasjon',
			'performanceOverlay.dvSource' => 'DV-kilde',
			'performanceOverlay.dvPath' => 'DV-sti',
			'performanceOverlay.dvRouteDecoder' => 'Dolby Vision-dekoder',
			'performanceOverlay.dvRouteDecoderP81' => 'Dolby Vision-dekoder (P7→8.1)',
			'performanceOverlay.dvRouteBaseLayer' => 'Basislag',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'HDR10-basislag',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'HLG-basislag',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'SDR-basislag',
			'performanceOverlay.dvRouteReshaped' => 'RPU-omformet (gpu-next)',
			'performanceOverlay.dvRouteFelGraphActive' => 'Eksperimentell P7 FEL-grafikk (unkvalifisert)',
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
			'performanceOverlay.playMethod' => 'Spill Metode',
			'performanceOverlay.memory' => 'Minne',
			'performanceOverlay.uiFps' => 'UI FPS',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android-maskinvare',
			'performanceOverlay.decoderNvidiaHw' => 'NVIDIA-maskinvare',
			'performanceOverlay.decoderQualcommHw' => 'Qualcomm-maskinvare',
			'performanceOverlay.decoderMediatekHw' => 'MediaTek-maskinvare',
			'performanceOverlay.decoderExynosHw' => 'Exynos-maskinvare',
			'performanceOverlay.decoderSoftware' => 'Programvare',
			'performanceOverlay.decoderHardware' => 'Maskinvare',
			'performanceOverlay.tunnelingActive' => 'Aktiv',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted} (${failures} mislyktes)',
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
			'externalPlayer.description' => 'Velg en annen app for å åpne videoer i. Tilgjengelige spillere avhenger av din enhet og installerte apper.',
			'externalPlayer.systemDefaultDescription' => 'La operativsystemet åpne videoen med sin standardapp.',
			'externalPlayer.playerOptionDescription' => ({required Object player}) => 'Åpne videoer med ${player}.',
			'externalPlayer.playerNameDescription' => 'Etiketten som vises i spillelisten.',
			'externalPlayer.playerPackageDescription' => 'Skriv inn Android-pakkenavnet på spilleren app, for eksempel com.example.player.',
			'externalPlayer.playerCommandDescription' => 'Skriv inn den installerte spillerkommandoen eller utførbar rute for denne enheten.',
			'externalPlayer.playerUrlSchemeDescription' => 'Skriv inn URL-skjemaet og det valgfrie URL-templet som brukes til å starte spilleren.',
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
			_ => null,
		} ?? switch (path) {
			'metadataEdit.addTag' => 'Legg til tagg',
			'metadataEdit.genre' => 'Sjanger',
			'metadataEdit.director' => 'Regissør',
			'metadataEdit.writer' => 'Forfatter',
			'metadataEdit.producer' => 'Produsent',
			'metadataEdit.country' => 'Land',
			'metadataEdit.collection' => 'Samling',
			'metadataEdit.label' => 'Etikett',
			'metadataEdit.quickTag' => 'Hurtigtagg...',
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
			'trakt.disconnectConfirmBody' => 'PlezyNG slutter å sende hendelser til Trakt. Du kan koble til igjen når som helst.',
			'trakt.scrobble' => 'Sanntids-scrobbling',
			'trakt.scrobbleDescription' => 'Send avspillings-, pause- og stopphendelser til Trakt under avspilling.',
			'trakt.watchedSync' => 'Synkroniser settstatus',
			'trakt.watchedSyncDescription' => 'Når du markerer elementer som sett i PlezyNG, markeres de også som sett på Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Koble til Seerr',
			'seerr.serverUrl' => 'Server-URL',
			'seerr.serverUrlHelper' => 'Adressen til Seerr-instansen din',
			'seerr.checkServer' => 'Fortsett',
			'seerr.signInWithJellyfin' => 'Logg inn med Jellyfin',
			'seerr.signInWithEmby' => 'Logg inn med Emby',
			'seerr.signInWithLocal' => 'Bruk en lokal konto',
			'seerr.email' => 'E-post',
			'seerr.noSignInMethods' => 'Denne Seerr-instansen tilbyr ingen innloggingsmetode som PlezyNG støtter.',
			'seerr.instance' => 'Instans',
			'seerr.disconnectConfirm' => 'Koble fra Seerr?',
			'seerr.disconnectConfirmBody' => 'PlezyNG glemmer denne Seerr-instansen. Koble til igjen når som helst.',
			'seerr.request' => 'Be om',
			'seerr.request4k' => 'Be om i 4K',
			'seerr.seasons' => 'Sesonger',
			'seerr.allSeasons' => 'Alle sesonger',
			'seerr.advancedOptions' => 'Avansert',
			'seerr.destinationServer' => 'Målserver',
			'seerr.qualityProfile' => 'Kvalitetsprofil',
			'seerr.rootFolder' => 'Rotmappe',
			'seerr.languageProfile' => 'Språkprofil',
			'seerr.tags' => 'Tagger',
			'seerr.noTags' => 'Ingen tagger',
			'seerr.defaultOption' => ({required Object name}) => '${name} (standard)',
			'seerr.animeNote' => 'Denne serien er en anime.',
			'seerr.requestSubmitted' => 'Forespørsel sendt',
			'seerr.requestFailed' => ({required Object error}) => 'Forespørsel mislyktes: ${error}',
			'seerr.requestsLoadFailed' => 'Kunne ikke laste forespørselsalternativer',
			'seerr.nothingToRequest' => 'Alt er allerede tilgjengelig eller forespurt.',
			'seerr.statusAvailable' => 'Tilgjengelig',
			'seerr.statusPartiallyAvailable' => 'Delvis tilgjengelig',
			'seerr.statusRequested' => 'Forespurt',
			'seerr.statusProcessing' => 'Behandler',
			'seerr.statusBlocklisted' => 'På blokkeringslisten',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => 'Kunne ikke nå ${url}: ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => 'Ingen Seerr-instans på ${url} (HTTP ${status})',
			'seerr.behindAuthProxy' => 'En autentiserende omvendt proxy (SSO eller HTTP-autentisering) svarte i stedet for Seerr. PlezyNG kan ikke logge inn gjennom den: La Seerrs /api/v1-sti omgå proxyen for denne appen, eller bruk en adresse som når Seerr direkte.',
			'seerr.invalidUrl' => 'Skriv inn en serveradresse som https://seerr.example.com',
			'seerr.quickConnectUnsupported' => 'Denne Seerr-instansen støtter ikke Quick Connect. Den krever Seerr 3.4 eller nyere.',
			'seerr.notInitialized' => 'Denne Seerr-instansen har ikke fullført førstegangsoppsettet',
			'seerr.noPlexTokenForReauth' => 'Ingen Plex-token er tilgjengelig for å logge inn på nytt',
			'seerr.noStoredCredentials' => 'Ingen lagret påloggingsinformasjon er tilgjengelig for å logge inn på nytt',
			'seerr.signInRejected' => 'Innloggingen ble avvist',
			'seerr.noSessionCookie' => 'Seerr utstedte ingen øktinformasjonskapsel',
			'seerr.freshCookieRejected' => 'Seerr avviste den nye øktinformasjonskapselen',
			'seerr.noUserInformation' => 'Seerr returnerte ingen brukerinformasjon',
			'seerr.sessionRejectedAfterReauth' => 'Økten ble avvist etter ny innlogging',
			'seerr.permissionDenied' => 'Seerr avviste denne handlingen: kontoen din har ikke lenger den nødvendige tillatelsen',
			'seerr.permissionRevoked' => 'Du har ikke lenger tillatelse til å be om dette',
			'services.title' => 'Tjenester',
			'services.hubSubtitle' => 'Synkroniser fremdrift og forespør nye titler.',
			'services.integrations' => 'Integrasjoner',
			'services.notConnected' => 'Ikke tilkoblet',
			'services.connectedAs' => ({required Object username}) => 'Tilkoblet som @${username}',
			'services.scrobble' => 'Registrer fremdrift automatisk',
			'services.scrobbleDescription' => 'Oppdater listen din når du er ferdig med en episode eller film.',
			'services.disconnectConfirm' => ({required Object service}) => 'Koble fra ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'PlezyNG slutter å oppdatere ${service}. Koble til igjen når som helst.',
			'services.connectFailed' => ({required Object service}) => 'Kunne ikke koble til ${service}. Prøv igjen.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'Koble til Simkl på nytt',
			'services.simklReconnect.subtitle' => 'Simkl avvikler påloggingsmetoden som denne tilkoblingen bruker. Når du kobler til på nytt, åpnes simkl.com slik at du kan godkjenne PlezyNG – PlezyNG ser aldri passordet ditt. Visningshistorikken din blir liggende på Simkl.',
			'services.deviceCode.title' => ({required Object service}) => 'Aktiver PlezyNG på ${service}',
			'services.deviceCode.instructions' => 'Skann QR-koden, eller gå til adressen nedenfor og skriv inn denne koden:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Åpne ${service} for å aktivere',
			'services.deviceCode.copyCode' => 'Kopier aktiveringskode',
			'services.deviceCode.waitingForAuthorization' => 'Venter på godkjenning…',
			'services.deviceCode.codeCopied' => 'Kode kopiert',
			'services.oauthProxy.title' => ({required Object service}) => 'Logg inn på ${service}',
			'services.oauthProxy.body' => 'Skann denne QR-koden eller åpne URL-en på en enhet.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Åpne ${service} for å logge inn',
			'services.pendingAuth.copyUrl' => 'Kopier URL for pålogging',
			'services.pendingAuth.urlCopied' => 'URL kopiert',
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
			'services.libraryFilter.modeDescription' => 'Velg om de sjekkede bibliotekene er blokkert fra synkronisering eller er det eneste biblioteket som synkroniserer.',
			'services.seerrDescription' => 'Koble til Seerr eller Overseerr for å søke etter titler og sende medieforespørsler.',
			'services.trackerDescriptions.trakt' => 'Synkroniserte sett episoder og filmer med din Trakt konto.',
			'services.trackerDescriptions.mal' => 'Synk anime-lister og se fremskritt med MyAnimeList.',
			'services.trackerDescriptions.anilist' => 'Synkronisere anime-lister og se fremskritt med AniList.',
			'services.trackerDescriptions.simkl' => 'Sync så filmer, TV-programmer og anime med Simkl.',
			'services.trackerDescriptions.mdblist' => 'Vis MDBList-vurderinger og lister i anbefalinger og Utforsk.',
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
			'addServer.invalidCredentials' => 'Ugyldig brukernavn eller passord',
			'addServer.authResponseNotJson' => 'Autentiseringssvaret var ikke gyldig JSON',
			'addServer.authResponseIncomplete' => 'Påloggingssvaret fra serveren var ufullstendig',
			'addServer.quickConnectRejected' => 'Quick Connect ble avvist av serveren',
			'addServer.quickConnectNotJson' => 'Quick Connect-svaret var ikke gyldig JSON',
			'addServer.quickConnectMissingFields' => 'Quick Connect-svaret mangler en kode eller hemmelighet',
			'addServer.quickConnectPollRejected' => 'Quick Connect-spørringen ble avvist av serveren',
			'addServer.serverTimedOut' => 'Serveren svarte ikke i tide',
			'addServer.responseNotJson' => 'Serversvaret var ikke gyldig JSON',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'Svaret mangler en ID eller et servernavn – er dette en ${product}-server?',
			'addServer.probeFailed' => ({required Object error}) => 'Kunne ikke nå serveren: ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => 'Angi minst én URL til en ${product}-server',
			'addServer.noReachableServer' => ({required Object product}) => 'Fant ingen tilgjengelig ${product}-server',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'Disse URL-ene peker til forskjellige ${product}-servere',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'Denne URL-en samsvarer ikke med ${product}-serveren',
			'addServer.redirectUnsupported' => 'Serveren omdirigerte til en URL som ikke støttes',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'Serveren omdirigerte til en annen vert. Angi den endelige ${product}-URL-en direkte.',
			'addServer.redirectInsecure' => 'Serveren omdirigerte fra HTTPS til en usikker URL',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'Serveren omdirigerte til en URL som ikke støttes. Angi den endelige ${product}-URL-en direkte.',
			'addServer.directPlexServerUrl' => 'URL til Plex-server',
			'addServer.directPlexServerUrlHelper' => 'Skriv inn den lokale IP-adressen og porten til Plex Media Server.',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex Token (valgfritt)',
			'addServer.plexTokenHelper' => 'La det være tomt hvis tilgang uten auth er tillatt på denne serveren.',
			'addServer.plexTokenRequired' => 'Vennligst skriv inn din Plex token (X-Plex-Token).',
			'addServer.connectDirectPlexCard' => 'Plex Media Server (Direkt / Lokal)',
			'addServer.connectDirectPlexCardSubtitle' => 'Koble direkte ved hjelp av lokal IP eller URL uten plex.tv konto.',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => 'Koble direkte ved hjelp av lokal IP eller URL. Kobler til ${name}.',
			'addServer.insecureTitle' => 'Unencrypted tilkobling',
			'addServer.insecureDescription' => ({required Object url}) => '${url} bruker HTTP. Andre på nettverket kan lese eller endre passordet, tokenene og mediene dine. Bruk HTTPS når det er tilgjengelig. Fortsett bare hvis du stoler på dette nettverket og godtar risikoen.',
			'addServer.allowHttp' => 'Tillat HTTP',
			'addServer.httpsRequired' => 'Bruk HTTPS eller uttrykkelig tillate en ukryptert tilkobling.',
			'cast.chooseDevice' => 'Stikk til en enhet',
			'cast.searching' => 'Søk etter Cast-enheter',
			'cast.connectedTo' => ({required Object device}) => 'Tilkoblet til ${device}',
			'cast.device' => 'Cast utstyr',
			'cast.readyToCast' => 'Klar til å kastes',
			'cast.subtitle' => 'Undertekster',
			'cast.serverNotAvailable' => 'Media server er ikke tilgjengelig.',
			'cast.stopCasting' => 'Stoppe casting',
			'cast.castToDevice' => 'Cast til enheten',
			'cast.noEpisodeAvailable' => 'Det er ingen episode tilgjengelig for å kaste.',
			'cast.startFailed' => 'Kan ikke begynne å kaste. sjekk serveren og prøv igjen.',
			'automation.noActivePlayback' => 'Det er ingen aktiv video-session å kontrollere.',
			'notifications.newEpisodeTitle' => 'Nytt episode',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appAccess.title' => 'Prøv hver funksjon gratis i 7 dager',
			'appAccess.description' => 'Start en sju dagers prøve med full tilgang til hver PlezyNG funksjon. Det er ingen gebyr under prøve og ingen abonnement. Etter prøve, en livslang kjøp på din butikks pris låser opp PlezyNG for livet.',
			'appAccess.trialEndedDescription' => 'Unlock alle funksjoner i PlezyNG for livet med én kjøp til din butikk pris.',
			'appAccess.startTrial' => 'Start min 7 dagers gratis prøve',
			'appAccess.trialActive' => 'Din 7-dagers full-feature-tester er aktiv.',
			'appAccess.trialEnded' => '7 dagers rettssak er over',
			'appAccess.trialStartFailed' => 'Kan ikke spare prøven på denne enheten. vennligst prøv igjen.',
			'appAccess.lifetimeTitle' => 'PlezyNG avsluttet for livet',
			'appAccess.lifetimeBody' => 'Du har livslang tilgang til alle PlezyNG funksjoner.',
			'appAccess.manageTitle' => 'PlezyNG Livslang tilgang',
			'appAccess.manageDescription' => 'Prøv hver funksjon gratis i 7 dager, deretter låse opp alt for livet med en betaling til priset på butikken din.',
			'appAccess.buy' => ({required Object price}) => 'Unlock alle funksjoner for ${price}',
			'appAccess.loadingPrice' => 'Lading butikks pris...',
			'appAccess.retryPrice' => 'Retry pris lookup',
			'appAccess.restore' => 'Åpne livslang kjøp',
			'appAccess.pending' => 'Kjøpet ditt venter på betaling eller godkjenning. Livslang tilgang låser opp så snart butikken fullfører det.',
			'appAccess.storeUnavailable' => 'Kontrollere at du er signert inn i butikken og kjøp er tillatt på denne enheten.',
			'appAccess.productNotFound' => 'PlezyNG livslang avlås er ikke tilgjengelig i denne butikken ennå.',
			'appAccess.productQueryFailed' => 'Kan ikke laste opp priset på butikken. sjekk koblingen din og prøv igjen.',
			'appAccess.purchaseFailed' => 'Kjøpet gikk ikke gjennom. prøv igjen.',
			'appAccess.restoreFailed' => 'Kan ikke nå butikken for å gjenopprette kjøpet. prøv igjen.',
			'appAccess.nothingToRestore' => 'No. PlezyNG livslang kjøp ble funnet for denne butikken konto.',
			'detail.endsAt' => ({required Object time}) => 'Slutter kl. ${time}',
			'watchLink.serverUnavailable' => 'Kan ikke nå en server på Plex for denne koblingen.',
			'watchLink.notFound' => 'Du kan ikke finne denne show eller film på serverne dine Plex.',
			'watchLink.ambiguous' => 'Denne koblingen matcher elementer på mer enn én server.',
			'watchLink.plexOnly' => 'Se koblinger støtter for tiden bare Plex servere.',
			'watchLink.unsupportedItem' => 'Se lenker kan bare åpne en show eller en film.',
			'watchLink.menuItem' => 'Se på link',
			'watchLink.dialogTitle' => 'Se link',
			'watchLink.dialogShowHint' => 'Åpne denne koblingen spiller neste episode. Legg til &mode=shuffle til slutten for å spille showet på shuffle.',
			'watchLink.dialogMovieHint' => 'Åpning av denne koblingen spiller filmen.',
			'watchLink.copy' => 'Kopierer',
			'watchLink.copied' => 'Link kopieres',
			'homeLayout.title' => 'Hjem Layout',
			'homeLayout.resetToast' => 'Hjem gjenoppbygging til den opprinnelige Plezy hero layout',
			'homeLayout.resetHeroTitle' => 'Åpne hero layout til lager Plezy?',
			'homeLayout.resetHeroBody' => 'Avbryter hver rad av hjertesetting og bringer tilbake den eneste roterende banneret på toppen av hjemmet, som før hjerteserien eksisterte.',
			'homeLayout.removeRowTitle' => 'Fjerner hjem ruten?',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} vil bli slettet. dette kan ikke bli unntatt.',
			'homeLayout.sync' => 'Synkroniser',
			'homeLayout.syncAccountTitle' => 'Synkronisere layout med kontoen din Plex',
			'homeLayout.syncAccountOn' => 'På: Denne enheten deler rekkefølge, rader, Hero og Auto-slide med dine andre enheter.',
			'homeLayout.syncAccountOff' => 'Av: Denne enheten holder sin egen layout.',
			'homeLayout.syncNow' => 'Synkronisering nå',
			'homeLayout.plexHomeManager' => 'Plex Hjemmanager',
			'homeLayout.managePlexRows' => 'Administrer Plex rader i Plezy',
			'homeLayout.managePlexRowsDescription' => 'Åpne for å organisere de hjemmelavede radene',
			'homeLayout.organizeHomeRows' => 'Organisere hjemmelavede rader',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} rader: bevegelse, Hero, Auto-slide, fjerne',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => 'Organisere ${library} rader',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => 'Fortsett å se + ${n} rader: bevegelse, Biblioteket, Hjem, Hero, Auto-slide',
			'homeLayout.renderAsHero' => 'Render som en helt kort',
			'homeLayout.heroOnlySingleCollection' => 'Kun tilgjengelig når denne raden løses til en enkelt samlings virkelige titler',
			'homeLayout.hero' => 'Hjernen',
			'homeLayout.autoSlide' => 'Automatisk bytte',
			'homeLayout.autoSlideDescription' => 'Arrows (PC) og d-pad (TV) fungerer alltid og starter timeret på nytt.',
			'homeLayout.autoSlideEditDescription' => 'Slides også på egen hånd hvert få sekunder. Av: bare beveger seg når du klikker på en pil (PC) eller trykker venstre/høyre på fjern (TV).',
			'homeLayout.enableHeroFirst' => 'Oppmuntre til å helte først',
			'homeLayout.showOnHome' => 'Show på hjemskjermen',
			'homeLayout.home' => 'Hjem',
			'homeLayout.removeFromHome' => 'Fjern fra hjemmet',
			'homeLayout.selectRowsFirst' => 'Velg hjem ruter nedenfor først.',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} Plex-styrte rader',
			'homeLayout.continueWatching' => 'Fortsett å se',
			'homeLayout.continueWatchingLibraryDescription' => 'Denne bibliotekets egen resume-progress-runde',
			'homeLayout.continueWatchingHomeDescription' => 'Den gjenoppgående fremskritt rad vist på Hjem',
			'homeLayout.nextUpHomeDescription' => 'Neste uoppdaget episode ser ut separat på Home',
			'homeLayout.library' => 'Bibliotek',
			'homeLayout.showInRecommended' => 'Utstilling i biblioteket anbefales',
			'homeLayout.customPlexRow' => 'Tilpasset Plex rad',
			'homeLayout.heroNeedsLibrary' => 'Sjekk biblioteket først – Hero trenger noe å vise',
			'homeLayout.heroNeedsSurface' => 'Sjekk biblioteket eller hjemmet først – Hero trenger noe å vise',
			'homeLayout.removeHub' => 'Fjern Hub',
			'homeLayout.noPlexRows' => 'No. Plex-styrt rader returnerte for denne biblioteket.',
			'homeLayout.openDetails' => 'Åpne detaljer',
			'homeLayout.heroCards' => 'Hero kort',
			'homeLayout.tapHeroCard' => 'Tapping av en helte kort',
			'homeLayout.tvPlayFocus' => 'TV fjern: Highlight Play-knappen',
			'homeLayout.tvPlayFocusDescription' => 'D-pad ned stopper på Play-knappen før du går til neste rad.',
			'homeLayout.tvWrap' => 'TV fjernsyn: loop hero kort',
			'homeLayout.tvWrapDescription' => 'Rett på det siste kortet går tilbake til det første. av stopper på det siste kartet. venstre på det første kortet går alltid til sidebaren.',
			'homeLayout.castOnHero' => 'Spille på hero bannere',
			'homeLayout.castOnHeroDescription' => 'Vis casten langs bunnen av en helt banner. Off holder bare tittelen og sammendraget.',
			'homeLayout.customRows' => 'Custom ruter',
			'homeLayout.loading' => 'Lading hjem layout ...',
			'homeLayout.noCustomRows' => 'Ingen vanlig runde ennå',
			'homeLayout.addRowHint' => 'Bruk Home-runde for å lage en.',
			'homeLayout.addHomeRow' => 'Legg til Home Rue',
			'homeLayout.addHomeRowDescription' => 'Velg en kategori; den nye raden blir automatisk lagt til i Organiser',
			'homeLayout.removeRow' => 'Fjern runde',
			'homeLayout.recentlyAdded' => 'Nylig lagt til',
			'homeLayout.recentlyReleased' => 'Nylig frigjort',
			'homeLayout.movieCollections' => 'Filmsamlinger',
			'homeLayout.showCollections' => 'Vis innsamling',
			'homeLayout.rowTitle' => 'Rø titel',
			'homeLayout.content' => 'Innhold',
			'homeLayout.showThisRowIn' => 'Vis denne raden i:',
			'homeLayout.libraryRecommended' => 'Biblioteket anbefales',
			'homeLayout.heroCard' => 'Hero kort',
			'homeLayout.heroCardDescription' => 'Vises som et fullbredt roterende kort i stedet for et posterskjelv.',
			'homeLayout.heroUnavailableDescription' => 'Kun tilgjengelig når denne raden løses til en enkelt samlings virkelige titler - med mer enn én samling valgt det er ingen enkelt tittel å rote gjennom.',
			'homeLayout.librariesSelection' => 'Biblioteker (leve alle unchecked for å inkludere hver bibliotek)',
			'homeLayout.librariesMergedDescription' => 'Hver bibliotek sjekket her er forbundet i denne ene raden.',
			'homeLayout.movieCollectionsSelection' => 'Filmsamlinger (leve alle unchecked for hver utvalgte bibliotek)',
			'homeLayout.showCollectionsSelection' => 'Vis samlingene (leve alle u sjekket for hver utvalgte bibliotek)',
			'homeLayout.collectionRowsDescription' => 'Hvis det er mer enn én match, vises hver samling som en enkelt poster - trykk på den for å åpne den samling.',
			'homeLayout.allCollections' => 'Alle samlinger',
			'homeLayout.noRowsHere' => 'Ingen rader her ennå.',
			'homeLayout.hideWatchedRows' => 'Skjære oppdagede gjenstander i rader',
			'homeLayout.hideWatchedRowsDescription' => 'Fullt sett titler forlater Hjem og bibliotek Rekommenderte rader.',
			'homeLayout.untitledCollection' => 'Utektede samlinger',
			'homeLayout.moveRowHint' => 'Opp/Down: flytte rad · Velg: drop her · Tilbake: kanseller',
			'homeLayout.organizeRowsHint' => 'Velg på en rekke (eller hold Velg): flytte den · Venstre/Rett: rekke alternativer · Tilbake: gjort',
			'homeLayout.layoutNavDescription' => 'Velg rader, biblioteker og samlingskategorier',
			'homeLayout.editHomeRow' => 'Edit Hjem Rå',
			'homeLayout.resetHeroButton' => 'Resett hero layout til lager Plezy',
			'homeLayout.reorderingUnlocked' => 'Å gjenoppta unlocked',
			'homeLayout.reorderingLocked' => 'Å gjenoppta låst',
			'homeLayout.rowsCanBeDragged' => 'Råene kan trekkes - trykk låsen for å forhindre at det',
			'homeLayout.tapLockToDrag' => 'Trykk på låsen for å trekke rader',
			'homeLayout.customRowLabel' => ({required Object title}) => 'Tilpasset: ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => 'Skjul',
			'homeLayout.remove' => 'Fjern',
			'homeLayout.libraryResumeRow' => 'Denne bibliotekets resume-runde',
			'homeLayout.pressAgainToDelete' => 'Trykk igjen for å slette',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => 'På',
			'homeLayout.resetHeroButtonDescription' => 'Avbryter hver rad av hjertesetting og bringer tilbake den ene roterende banneret til toppen, som før hjerteserien eksisterte.',
			'homeLayout.tapHeroCardDescription' => 'Velg om tapping eller valg av et Hero-kort starter playback eller åpner detaljene.',
			'homeLayout.heroTapPlayDescription' => 'Start det valgte elementet umiddelbart.',
			'homeLayout.heroTapDetailsDescription' => 'Åpne detaljer om det valgte elementet før du velger en handling.',
			'platform.localNetworkPermission' => 'PlezyNG kobler til medieserverne og avspillingsenhetene dine på det lokale nettverket.',
			'platform.locationPermission' => 'PlezyNG bruker lokasjonstilgang når iOS krever det for å oppdage ditt lokale nettverk og koble til dine medie servere.',
			'platform.photoLibraryPermission' => 'Velg bilder fra bildebiblioteket som omslag og illustrasjoner til medieinnhold.',
			'platform.cameraPermission' => 'Skann QR-koder for å pare en Companion Remote.',
			'universalMedia.title' => 'Åpne medier',
			'universalMedia.shortcutHelp' => 'Spill en lenke, spillliste eller fil for denne sesjonen.',
			'universalMedia.intro' => 'Åpne en lenke, spillliste eller fil. Playback bruker PlezyNGs standardspiller og legger ikke til historie i biblioteket ditt.',
			'universalMedia.openWhat' => 'Hva vil du gjerne åpne?',
			'universalMedia.stream' => 'Stream adresse',
			'universalMedia.playlist' => 'Playlist',
			'universalMedia.files' => 'Device filer',
			'universalMedia.favorites' => 'Saved stream favoritter',
			'universalMedia.address' => 'Media adresser',
			'universalMedia.addressHelp' => 'URLer med anerkjente akkrediterings- eller signaturparameter brukes kun for denne sesjonen og kan ikke lagres som favoritter.',
			'universalMedia.displayName' => 'Visningsnavnet (alternativt)',
			'universalMedia.displayNameHelp' => 'Velg et kort navn for spilleren og systemmediakontrollene.',
			'universalMedia.allowHttp' => 'Tillat en ukryptert HTTP-tilkobling',
			'universalMedia.allowHttpHelp' => 'HTTP krypterer ikke koblingen. Tillat den bare på et pålitelig nettverk. Bruk HTTPS når det er mulig.',
			'universalMedia.advancedProtocols' => 'MPV bare: Skriv inn en RTSP, RTMP/RTMPS, UDP eller RTP-adresse.',
			'universalMedia.liveStream' => 'Behandle som levende',
			'universalMedia.liveStreamHelp' => 'Bruk dette for live-video eller radio. appen skjuler tidsboken, skip knopper og go-to-time alternativet. slå det av for en opptak.',
			'universalMedia.privateSession' => 'Bare denne tilbakemeldingen bruker adressen.Save a eligible stream favorite to keep it in this profile.',
			'universalMedia.saveFavorite' => 'Spar favoritt',
			'universalMedia.playNow' => 'Spill nå',
			'universalMedia.favoriteSaved' => 'Stream favoritt lagret til denne profilen',
			'universalMedia.skippedEntries' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: 'Skipet ${count} ustøttet eller usikkert playlist inngang.', other: 'Skipede ${count} ustøttet eller usikre playlist-inntekter.', ), 
			'universalMedia.playlistAddress' => 'Playlist adresser',
			'universalMedia.playlistAddressHelp' => 'Åpne en M3U, M3u8, eller PLS-spillliste fra en nettadresse. direkte strømlinjer sparer ikke spilllisten.',
			'universalMedia.choosePlaylist' => 'Velg Playlist filer',
			'universalMedia.openPlaylist' => 'Åpne playlist',
			'universalMedia.playlistFormatsHelp' => 'En spillliste kan inneholde opptil 1000 elementer og 2 MB. HLS manifesterer seg åpent som strømmer slik at spilleren kan velge en kvalitet.',
			'universalMedia.noFavorites' => 'Ingen sparte stream favoritter ennå. Favoritter forblir i denne profilen.',
			'universalMedia.removeFavorite' => 'Fjern stream favoritt',
			'universalMedia.filesHelp' => 'Velg audio, video eller ISO-filer for en midlertidig kue. filer og URL\'er er ikke lagt til bibliotekets historie.',
			'universalMedia.chooseFiles' => 'Velg filer',
			'universalMedia.fileQueue' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: '1 utvalgte filer', other: '${count} utvalgte filer', ), 
			'universalMedia.wifiTransfer' => 'Send filer via Wi-Fi',
			'universalMedia.wifiTransferHelp' => 'Overføring av støttet filer fra en nettleser på samme pålitelige nettverk.',
			'universalMedia.wifiTransferIntro' => 'Åpne denne adressen i en nettleser på en annen enhet.Velg filer for å legge dem til filer og bøker biblioteket på denne enheten.',
			'universalMedia.wifiTransferPrivacy' => 'Denne enheten mottar filer over ditt lokale nettverk. Enhver som kjenner denne adressen kan sende filer til du stopper overføringen eller adressen utløper etter 15 minutter. Maksimum: 100 filer, 4 GiB per fil, 10 GiB totalt.',
			'universalMedia.wifiTransferStarting' => 'Forberedelse av en privat, tidsbegrenset overføring ...',
			'universalMedia.wifiTransferUnavailable' => 'Kan ikke starte overføringen. sjekk lokalt nettverkstilgang og prøv igjen.',
			'universalMedia.openThisAddress' => 'Åpne en av disse adressene på senderenheten',
			'universalMedia.copyAddress' => 'Kopierer overføringsadresse',
			'universalMedia.addressCopied' => 'Overføringsadresse kopieres',
			'universalMedia.transferExpires' => ({required Object time}) => 'Denne adressen utløper i ${time}.',
			'universalMedia.uploadCount' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: '${count} filen mottatt', other: '${count} filer mottatt', ), 
			'universalMedia.uploadedData' => ({required Object size}) => 'Oppsatt av ${size}',
			'universalMedia.stopTransfer' => 'Stopp overføring og invalidere adressen',
			'universalMedia.startTransfer' => 'Start overføring',
			'universalMedia.wifiImportedFiles' => 'Wi-Fi overføring',
			'universalMedia.wifiBrowserTitle' => 'Send filer til PlezyNG',
			'universalMedia.wifiBrowserIntro' => 'Velg lyd, video, e-bok eller komiksfiler for å sende. filene lagres i denne enhetens Filer og bøker bibliotek. Maksimum: 100 filer, 4 GiB per fil, 10 GiB totalt.',
			'universalMedia.uploadFilesLabel' => 'Filer å sende',
			'universalMedia.uploadSelected' => 'Last opp utvalgte filer',
			'universalMedia.uploadSelectFirst' => 'Velg en eller flere filer først.',
			'universalMedia.uploading' => 'Sending',
			'universalMedia.uploadComplete' => 'Filet er lagt til PlezyNG.',
			'universalMedia.uploadFailed' => 'Filen kan ikke legges til. Hold denne siden åpen og prøv igjen.',
			'universalMedia.liveCue' => 'Livet',
			'universalMedia.liveSession' => 'Live Stream',
			'universalMedia.liveCueHelp' => 'For live-video eller radio, skjuler appen tidsboken og hopper knapper. Det sparar ikke adressen eller se historie.',
			'universalMedia.sessionOnly' => 'Dette spillet er sesjon-only',
			'universalMedia.sessionOnlyHelp' => 'Playback sparer aldri fremgang eller historie.Save the stream as a favorite to keep it in this profile if it is eligible.',
			'universalMedia.pictureAdjustments' => 'Bilder justeringer',
			'universalMedia.pictureHelp' => 'Disse endringene i bildet påvirker bare denne playback. De resetter når playback avsluttes.',
			'universalMedia.resetPicture' => 'Resett bilde',
			'universalMedia.brightness' => 'Skjønnhet',
			'universalMedia.contrast' => 'Kontrast',
			'universalMedia.gamma' => 'Gamma',
			'universalMedia.hue' => 'Hue',
			'universalMedia.saturation' => 'Saturasjon',
			'universalMedia.view360' => 'Flat visning for 360° video',
			'universalMedia.view360Help' => 'MPV trenger FFmpegs v360-filter for denne visningen.',
			'universalMedia.view360Unavailable' => 'Denne MPV-byggingen kan ikke bruke 360°-filteret.',
			'universalMedia.view360Yaw' => 'Horisontell utsikt',
			'universalMedia.view360Pitch' => 'Vertikalt syn',
			'universalMedia.view360FieldOfView' => 'Felt av syn',
			'universalMedia.recordStream' => 'Rekord live stream',
			'universalMedia.stopRecording' => 'Stoppe og lagre opptak',
			'universalMedia.recordingStarted' => 'Opptaket er aktivt.Letting playback stopper og sparer innspillingen.',
			'universalMedia.recordingSaved' => 'Oppskriften er avsluttet og reddet.',
			'universalMedia.recordingActive' => 'Oppdatering av denne enheten.Leaving playback stopper og sparer det.',
			'universalMedia.recordingFormatHelp' => 'For video, velg MKV eller MPEG-TS. for lyd, velge MKA eller MKV.',
			'universalMedia.replaceRecordingTitle' => 'Vil du erstatte denne innspillingen?',
			'universalMedia.replaceRecordingHelp' => 'PlezyNG gjenoppretter den eksisterende filen under opptak. Hvis det ikke kan lagre den nye opptak, plezyNG restaurerer sikkerhetskopien.',
			'universalMedia.replaceRecording' => 'erstatte filer',
			'universalMedia.discHelp' => 'Åpne en disk i denne datamaskinens optiske skjerm. Du kan også åpne et ISO-bilde fra Device-filer.',
			'universalMedia.discs' => 'Optikal disk',
			'universalMedia.dvd' => 'DVD',
			'universalMedia.bluray' => 'Blu-ray',
			'universalMedia.audioCd' => 'Audio CD',
			'universalMedia.discAvailability' => 'Disc playback trenger en kompatibel MPV-bygging, støttet drive og operativsystem tillatelse. Det kan ikke gå glipp av kommersiell diskbeskyttelse.',
			'universalMedia.converterTitle' => 'Konverter en lokal mediefil',
			'universalMedia.converterHelp' => 'Bruk FFmpeg til å lage en MP4, M4A eller MP3 kopi.',
			'universalMedia.converterIntro' => 'Konverter en lokal lyd- eller videofil til et format som fungerer på flere enheter.',
			'universalMedia.converterPrivacy' => 'FFmpeg må installeres på denne datamaskinen. Conversion leser bare lokale filer. Det lastes ikke ned strømmer eller fjerner DRM.',
			'universalMedia.converterChooseInput' => 'Velg en lokal mediefil',
			'universalMedia.converterFormat' => 'Utgangsformatet',
			'universalMedia.converterMp4' => 'MP4 · H.264 og AAC',
			'universalMedia.converterM4a' => 'M4A · AAC lyd',
			'universalMedia.converterMp3' => 'MP3 og Audio',
			'universalMedia.converterSaveAs' => 'Lagre konverterte medier som',
			'universalMedia.converterExtensionMismatch' => 'Velg et filnavn med den valgte utvidelsen.',
			'universalMedia.converterUnsupportedInput' => 'Velg en audio eller video fil.',
			'universalMedia.converterLocalOnly' => 'Den valgte filen er ikke tilgjengelig som en lokal enhetsvei.',
			'universalMedia.converterReplaceTitle' => 'Vil du erstatte denne filen?',
			'universalMedia.converterReplaceHelp' => 'PlezyNG gjenoppretter den eksisterende filen til den konverterte kopien er lagret.',
			'universalMedia.converterStarting' => 'Start med FFmpeg...',
			'universalMedia.converterProgress' => 'For å konvertere til denne datamaskinen...',
			'universalMedia.converterComplete' => 'Konversjonen er fullført. den nye filen er klar.',
			'universalMedia.converterFfmpegMissing' => 'Installere FFmpeg med H.264, AAC, og MP3 støtte, så prøv igjen.',
			'universalMedia.converterFailed' => 'Kontroller at kildefilen kan leses og destinasjonen har nok gratis plass.',
			'universalMedia.converterCancelled' => 'Konverteringen ble avlyst. den ufullstendige utgaven ble fjernet.',
			'universalMedia.converterDesktopOnly' => 'Lokalt konvertering er tilgjengelig på skrivebord datamaskiner med FFmpeg installert.',
			'universalMedia.converterStart' => 'Konverter filer',
			'universalMedia.mediaToolsTitle' => 'Media verktøy',
			'universalMedia.mediaToolsShortcut' => 'Få eller dele media, legge til søkeklarasjoner, eller bruk kommandelinjen.',
			'universalMedia.mediaToolsIntro' => 'Velg et fokusert verktøy. få og strøm-out bruk FFmpeg installert på dette skrivebordet. Extensions og CLI kommandoer bruker begrensede HTTPS forespørsler og den eksisterende Open media strømmen.',
			'universalMedia.mediaToolsAccessibility' => 'Verktøyvalg og kontroller fungerer med touch, indikator, tastatur, og D-pad fokus. Opptak, deling og søk status endringer er annonsert.',
			'universalMedia.mediaTool' => 'Media verktøy',
			'universalMedia.captureIntro' => 'Lagre skjermen eller kameraet til en MP4 fil på denne datamaskinen. FFmpeg må installeres og inkludere koderen H.264.',
			'universalMedia.captureNoDevices' => 'Ingen skjerm eller kamera ble funnet. sjekk FFmpeg opptak støtte og operativsystemet personvern tillatelser.',
			'universalMedia.captureSource' => 'Skjerm eller kamera',
			'universalMedia.captureScreen' => 'Skjerm',
			'universalMedia.captureAudioSource' => 'Audio inntak (valgfritt)',
			'universalMedia.captureAudioHelp' => 'Legg til lyd fra en mikrofon eller tilgjengelig inngang. Enhetsvalg avhenger av FFmpeg og systemtillatelser.',
			'universalMedia.captureAudioNone' => 'Ingen lyd',
			'universalMedia.captureDefaultAudio' => 'Standard lydinngang',
			'universalMedia.captureWaylandHelp' => 'Wayland begrenser denne XWayland fangen til X display. Windows utenfor XWayland kan ikke vises.',
			'universalMedia.captureFrameRate' => 'Rekordframe rate',
			'universalMedia.capturePrivacy' => 'Opptaket lagres kun til filen du velger. mikrofonopptak er valgfritt. PlezyNG laster ikke opp opptaket.',
			'universalMedia.captureSaveAs' => 'Lagre skjermopptak som',
			'universalMedia.captureExtensionMismatch' => 'Velg et filnavn som slutter i .mp4.',
			'universalMedia.captureFfmpegMissing' => 'FFmpeg eller H.264 video koder er ikke tilgjengelig. Installere en støttet FFmpeg bygning, og prøv igjen.',
			'universalMedia.captureFailed' => 'Kontrollere enhetens tillatelse, tilgjengelig lagring, og FFmpeg støtte.',
			'universalMedia.captureSaved' => 'Skjermopptak er redde.',
			'universalMedia.captureElapsedLabel' => 'Opptegningstid',
			'universalMedia.captureStart' => 'Begynn opptak',
			'universalMedia.captureStop' => 'Stopp og redde',
			'universalMedia.captureMode' => 'Fanger',
			'universalMedia.shareMode' => 'Deling',
			'universalMedia.shareIntro' => 'Send en lokal mediafil til en annen enhet på ditt private nettverk. PlezyNG skaper en midlertidig HLS-strøm.',
			'universalMedia.sharePrivacy' => 'Alle på ditt lokale nettverk som mottar den private koblingen kan se mens den er aktiv. koblingen utløper etter 60 minutter. stoppe deling for å lukke serveren og invalidere koblingen.',
			'universalMedia.shareChooseFile' => 'Velg media filer',
			'universalMedia.shareChooseHelp' => 'Velg en lokal audio eller videofil. filen forblir på denne datamaskinen.',
			'universalMedia.shareFfmpegMissing' => 'FFmpeg eller H.264/AAC koder er ikke tilgjengelige. Installere FFmpeg med H.264 og AAC koder støtte.',
			'universalMedia.shareFailed' => 'Strømmen kunne ikke starte eller stoppe uventet. sjekk FFmpeg og nettverkstilgang.',
			'universalMedia.shareActive' => 'Strømmen er klar på ditt private nettverk.',
			'universalMedia.shareEnded' => 'Mediene har nådd slutten og er ikke lenger delt.',
			'universalMedia.shareStopped' => 'Deling stoppet. den midlertidige koblingen er ikke lenger gyldig.',
			'universalMedia.shareUrlCopied' => 'Stream adressen kopieres.',
			'universalMedia.shareOpenUrl' => 'Åpne denne adressen i en spiller på den andre enheten',
			'universalMedia.shareQrLabel' => 'QR-kode for midlertidig strømadresse',
			'universalMedia.shareQrHelp' => 'Scan med en kompatibel spiller som er koblet til det samme private nettverket.',
			'universalMedia.shareHttpHint' => 'Denne strømmen bruker ukryptert HTTP. i PlezyNG, tillate HTTP før åpning.',
			'universalMedia.shareCopyUrl' => 'Kopierer strømadresse',
			'universalMedia.shareExpiresLabel' => 'Linken utløper ved',
			'universalMedia.shareStarting' => 'Forberedelse av strømmen...',
			'universalMedia.shareStart' => 'Begynn å dele',
			'universalMedia.shareStop' => 'Slutt å dele',
			'universalMedia.extensionsMode' => 'Utvidelser og CLI',
			'universalMedia.extensionsIntro' => 'Legg til en data-enbart søk utvidelse for å finne media. Velg et resultat for å laste den inn i det kjente Open media-skjemaet.',
			'universalMedia.extensionsPrivacy' => 'En manifest kan definere et HTTPS søk endpoint og kart responsfelt. Det kan ikke kjøre kode, legge til forespørselshoveder, lese filer, eller lansere shell kommandoer.',
			'universalMedia.extensionImport' => 'Legg til utvidelse manifest',
			'universalMedia.extensionEmpty' => 'Ingen søketjenester ennå. Velg en pålitelig manifest JSON fil for å legge til en.',
			'universalMedia.extensionChoose' => 'Søk service',
			'universalMedia.extensionSearchConsent' => 'Hver søk sender ordene dine til denne tjenesten HTTPS. Resultater åpnes bare etter at du har valgt en.',
			'universalMedia.extensionSearchLabel' => 'Søk media',
			'universalMedia.extensionSearch' => 'Søk',
			'universalMedia.extensionSearching' => 'Søk...',
			'universalMedia.extensionNoResults' => 'Ingen sikker medieresultater ble returnert. prøv en annen søk.',
			'universalMedia.extensionInstallTitle' => 'Legg til denne søketjenesten?',
			'universalMedia.extensionReplaceTitle' => 'Oppdaterer du denne søketjenesten?',
			'universalMedia.extensionService' => 'Tjenestene',
			_ => null,
		} ?? switch (path) {
			'universalMedia.extensionEndpoint' => 'HTTPS Endpoint',
			'universalMedia.extensionConsent' => 'Din søktekst sendes til denne tjenesten. manifestet inneholder ingen utførbar kode. fortsett bare hvis du stoler på dette slutten.',
			'universalMedia.extensionInstall' => 'Legg til service',
			'universalMedia.extensionReplace' => 'Oppdateringstjeneste',
			'universalMedia.extensionRemoveTitle' => 'Fjerner du denne søketjenesten?',
			'universalMedia.extensionRemoveHelp' => 'Dette fjerner tjenesten fra denne profilen. PlezyNG kontakter ikke sin sluttpunkt.',
			'universalMedia.extensionRemove' => 'Fjern service',
			'universalMedia.extensionInvalidManifest' => 'Denne filen er ikke en støttet utvidelse manifest. se Guiden for Open media formatet.',
			'universalMedia.extensionSaveFailed' => 'Utvidelsen kunne ikke lagres til den aktive profilen.',
			'universalMedia.extensionSearchFailed' => 'Søketjenesten returnerte ikke et gyldig svar. sjekk slutten og prøv igjen.',
			'universalMedia.cliTitle' => 'kommando linje',
			'universalMedia.cliHelp' => 'Bruk plezyctl guide for å validere en manifest eller søke etter den samme utvidelsen. Se gjennom HTTPS-tjenesten før hver søk. Resultater åpnes i det eksisterende medieformulæret; velg playback-knappen for å starte.',
			'universalMedia.cliCopyExample' => 'Kopierer kommandoeksempel',
			'universalMedia.cliCopied' => 'Kommandamodell kopieres.',
			'fileSources.title' => 'Filer og bøker',
			'fileSources.subtitle' => 'Les, lytte og se fra dine egne filer.',
			'fileSources.add' => 'Legg til kilde',
			'fileSources.importFiles' => 'Import filer',
			'fileSources.localFiles' => 'På denne enheten',
			'fileSources.source' => 'Kilde',
			'fileSources.name' => 'Navn',
			'fileSources.endpoint' => 'Server-URL',
			'fileSources.smbEndpointHint' => 'Eksempel: smb://nas/Movies',
			'fileSources.smbEndpointInvalid' => 'Angi en SMB-server og én delt mappe.',
			'fileSources.root' => 'Fold eller forhåndsregister',
			'fileSources.smbFolderHelp' => 'La feltet stå tomt for å bruke hele den delte mappen, eller angi en mappe i den.',
			'fileSources.username' => 'Brukernavn',
			'fileSources.smbDomain' => 'Domene (valgfritt)',
			'fileSources.password' => 'Passord',
			'fileSources.token' => 'API token',
			'fileSources.accessKey' => 'Oppsummering av Key ID',
			'fileSources.secretKey' => 'Hemmelig tilgangsnøkkel',
			'fileSources.sessionToken' => 'Session token (valgfritt)',
			'fileSources.region' => 'Regionen',
			'fileSources.clientId' => 'OAuth klient ID',
			'fileSources.clientSecret' => 'OAuth-klienthemmelighet (desktop Google alene)',
			'fileSources.allowHttp' => 'Tillat ukryptert HTTP på et betrodd nettverk',
			'fileSources.smbEncryption' => 'Krypter SMB3-tilkoblingen',
			'fileSources.smbEncryptionHint' => 'Bruk SMB3-kryptering når NAS-en støtter det.',
			'fileSources.connect' => 'Koble til',
			'fileSources.cancel' => 'Avbryt',
			'fileSources.save' => 'Lagre',
			'fileSources.close' => 'Lukk',
			'fileSources.removeSource' => 'Avkoblet kilde',
			'fileSources.disconnectMessage' => 'Koble fra denne kilden? Nedlastede filer og lese- og lyttehistorikken din blir på denne enheten.',
			'fileSources.localFolder' => 'Velg mappe',
			'fileSources.empty' => 'Ingenting her ennå',
			'fileSources.emptyHint' => 'Legg til en kilde eller importere en bok, lydbok, musikk eller video.',
			'fileSources.search' => 'Søk etter denne mappen',
			'fileSources.searchCached' => 'Søk redde bibliotek',
			'fileSources.refresh' => 'Oppdater',
			'fileSources.loadMore' => 'Late mer',
			'fileSources.offline' => 'Tilgjengelig offline',
			'fileSources.download' => 'Hold deg offline',
			'fileSources.removeDownload' => 'Fjern offline kopi',
			'fileSources.continueReading' => 'Fortsett å lese',
			'fileSources.continueListening' => 'Fortsett å lytte',
			'fileSources.continueWatching' => 'Fortsett å se',
			'fileSources.read' => 'Leser',
			'fileSources.listen' => 'Lytt til',
			'fileSources.play' => 'Spill av',
			'fileSources.pause' => 'pause',
			'fileSources.stop' => 'Stopp',
			'fileSources.startOver' => 'Begynn på nytt',
			'fileSources.finished' => 'Ferdig',
			'fileSources.markFinished' => 'Mark er ferdig',
			'fileSources.markUnfinished' => 'Mark uendelig',
			'fileSources.editions' => 'Utgivelser og filer',
			'fileSources.chapters' => 'Kapitler',
			'fileSources.bookmarks' => 'Bokmerker og notater',
			'fileSources.bookmark' => 'Legg til bookmark',
			'fileSources.highlight' => 'Høydepunkter',
			'fileSources.note' => 'Notat',
			'fileSources.delete' => 'Slett',
			'fileSources.export' => 'Eksport notater',
			'fileSources.exported' => 'Notater eksportert',
			'fileSources.sync' => 'Sync fremskritt',
			'fileSources.synced' => 'Synkronisert fremgang',
			'fileSources.conflict' => 'En annen enhet har en annen posisjon. Velg hvor du skal fortsette.',
			'fileSources.useLocal' => 'Bruk denne enheten',
			'fileSources.useRemote' => 'Bruk andre enheter',
			'fileSources.history' => 'Posisjon historie',
			'fileSources.groupAudio' => 'Lytt som en audiobok',
			'fileSources.groupHint' => 'Kombiner de lydfiler som for tiden lastes inn i denne mappen. Last ned alle sidene først.',
			'fileSources.order' => 'Filordene',
			'fileSources.moveUp' => 'Flytt opp',
			'fileSources.moveDown' => 'Flytt ned',
			'fileSources.speed' => 'Spillerskapshastighet',
			'fileSources.sleep' => 'Innsovningstimer',
			'fileSources.sleepOff' => 'Av',
			'fileSources.endChapter' => 'Enden av kapittel',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutt', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutter', ), 
			'fileSources.skipBack' => 'Skip tilbake',
			'fileSources.skipForward' => 'Skip fremover',
			'fileSources.smartRewind' => 'Smart tilbake etter pause',
			'fileSources.playbackOptions' => 'Lytting alternativer',
			'fileSources.remaining' => ({required Object time}) => '${time} gjenværende',
			'fileSources.contents' => 'Innhold',
			'fileSources.readerSettings' => 'Lesing av innstillinger',
			'fileSources.fontSize' => 'Tekst størrelse',
			'fileSources.lineHeight' => 'Line spatial',
			'fileSources.margin' => 'Marger',
			'fileSources.font' => 'Typefase',
			'fileSources.serif' => 'Seriøst',
			'fileSources.sans' => 'Uten seriet',
			'fileSources.mono' => 'Fast tegnbredde',
			'fileSources.columns' => 'Kolonne',
			'fileSources.scroll' => 'Scroll vertikalt',
			'fileSources.justify' => 'Justifiser tekst',
			'fileSources.readerTheme' => 'Side utseende',
			'fileSources.appTheme' => 'Følg app tema',
			'fileSources.paper' => 'Papir',
			'fileSources.sepia' => 'Sepia',
			'fileSources.night' => 'Natt',
			'fileSources.readAloud' => 'Les denne siden høyt',
			'fileSources.readAlong' => 'Les videre',
			'fileSources.stopReading' => 'Stopper narrasjon',
			'fileSources.searchBook' => 'Søk i bok',
			'fileSources.noMatches' => 'Ingen kamper',
			'fileSources.previousPage' => 'Forrige side',
			'fileSources.nextPage' => 'Neste side',
			'fileSources.page' => ({required Object number}) => 'Side ${number}',
			'fileSources.externalBlocked' => 'Eksterne boklinser er deaktiverte i leseren.',
			'fileSources.loading' => 'Åpning...',
			'fileSources.narrator' => 'Narratør',
			'fileSources.audio' => 'Lyd',
			'fileSources.video' => 'Videoen',
			'fileSources.ebooks' => 'Ebook',
			'fileSources.all' => 'Alle',
			'fileSources.downloads' => 'Offline filer',
			'fileSources.confirmDelete' => 'Fjern den valgte offline-kopien? posisjonen og notatene dine vil forbli.',
			'fileSources.errorAuthentication' => 'Registrer deg igjen for å koble til denne kilden.',
			'fileSources.errorPermission' => 'Denne kilden har ikke gitt tilgang til den forespilte filen.',
			'fileSources.errorUnavailable' => 'Forsøk igjen, eller åpne en offline kopi.',
			'fileSources.errorUnsupported' => 'Dette formatet eller koblingen støttes ikke på denne enheten. sjekk kildeinnstillingshandboken.',
			'fileSources.errorInvalidData' => 'Denne filen eller serverresponsen kan ikke leses sikkert.',
			'fileSources.errorCancelled' => 'Operasjonen ble avlyst.',
			'fileSources.errorConflict' => 'Posisjonen endret i en annen sesjon. Åpne gjenstanden for å velge en posisjon.',
			'fileSources.signIn' => 'Logg inn',
			'fileSources.reconnect' => 'Koble til på nytt',
			'fileSources.folderHelp' => 'La det være å starte på kilderoten. S3 URL-er inkluderer bucket.',
			'fileSources.preferences' => 'Foretrukninger',
			'fileSources.timePosition' => 'Posisjon',
			'fileSources.audioTrack' => 'Audio Track',
			'fileSources.subtitleTrack' => 'Subtitle sporing',
			'fileSources.none' => 'Ingen',
			'fileSources.fullscreen' => 'Full skjerm',
			'fileSources.syncLocation' => 'Progress synkronisering mappe (valgfritt)',
			'fileSources.syncLocationHint' => 'En dedikert WebDAV mappe for PlezyNG stat. Bruk betingelsesbrev; media forblir uendret.',
			'fileSources.audiobooks' => 'Audiobøker',
			'fileSources.comics' => 'Tegneserier',
			'fileSources.scan' => 'Skankering av bøker og media',
			'fileSources.browserReader' => 'Åpne lesere',
			'fileSources.browserReaderHelp' => 'Leseren er åpen i nettleseren. Hold PlezyNG åpen for å lagre leseposisjonen og notatene dine.',
			'fileSources.on' => 'På',
			'fileSources.advancedSetup' => 'App registrering',
			'fileSources.microsoftSignIn' => 'Registrer deg med Microsoft',
			'fileSources.zoomIn' => 'Zoom i',
			'fileSources.zoomOut' => 'Zoom ut',
			'fileSources.fitPage' => 'Fikk side',
			'fileSources.fitWidth' => 'Fikk bredde',
			'fileSources.actualSize' => 'Aktuell størrelse',
			'fileSources.goToPage' => 'Gå til side',
			'fileSources.goToSection' => 'Gå til kapittel',
			'fileSources.pageRange' => ({required Object count}) => 'Skriv inn et nummer fra 1 til ${count}',
			'fileSources.pageLayout' => 'Side layout',
			'fileSources.automatic' => 'Automatisk',
			'fileSources.singlePage' => 'Enkel side',
			'fileSources.twoPages' => 'To sider',
			'fileSources.readingDirection' => 'Lesende retning',
			'fileSources.leftToRight' => 'Fra venstre mot høyre',
			'fileSources.rightToLeft' => 'Fra høyre mot venstre',
			'fileSources.letterSpacing' => 'Brev om spati',
			'fileSources.wordSpacing' => 'Ord spati',
			'fileSources.readerControlsHelp' => 'Spre to fingre, eller bruk zoomkontrollene for å forstørre sider. Dra for å flytte siden. Ctrl/⌘ med + eller − justerer zoom; Ctrl/⌘ med 0 nullstiller den. Page Up og Page Down blar mellom sidene.',
			'fileSources.imagePage' => 'Tegneserieside',
			'fileSources.resetReader' => 'Åpne lesingsfortrinnene',
			'fileSources.zoom' => 'Zoom',
			'fileSources.useFiles' => 'Bruk filer og bøker',
			'fileSources.cancelScan' => 'Avbestill skanningen',
			'fileSources.googleDrive' => 'Google Drive',
			'fileSources.offlineQuota' => 'Offline nedlasting begrenset',
			'fileSources.offlineQuotaHelp' => 'Sett maksimalt plass som brukes av offline kopier, importerte filer og nedlastinger. Senke grensen fjerner ikke eksisterende kopier.',
			'fileSources.offlineStorageUsage' => 'Offline lagring',
			'fileSources.reservedStorage' => 'Reserverte',
			'fileSources.downloadQueue' => 'Nedlasting av Queue',
			'fileSources.downloadRunning' => 'nedlasting',
			'fileSources.downloadQueued' => 'Venter på',
			'fileSources.downloadPaused' => 'pause',
			'fileSources.downloadFailed' => 'Trenger tilbakemelding',
			'fileSources.importing' => 'Importerer',
			'fileSources.importInterrupted' => 'Import avbrutt · fjerning til klart',
			'fileSources.errorQuotaExceeded' => 'Den offline lagringsgrensen ble oppnådd. Oppheve grensen eller fjerne en nedlastet kopi.',
			'fileSources.errorStorageLow' => 'Det er ikke tilstrekkelig gratis lagring av enheter for å opprettholde den beskyttede reserven.',
			'fileSources.errorStorageUnavailable' => 'PlezyNG kunne ikke sjekke gratis enhet lagring, så skrivingen ble stoppet.',
			'fileSources.removeDownloadJob' => 'Fjern nedlasting',
			'fileSources.downloadAlreadyComplete' => 'Denne nedlastingen er ferdig før den kan fjernes. elementet er nå tilgjengelig offline.',
			'fileSources.confirmRemoveDownloadJob' => 'Fjern denne nedlastingen og slett alle delvis nedlastede data? din posisjon og notater vil forbli.',
			'lending.title' => 'Offentlige bibliotek',
			'lending.add' => 'Legg til biblioteket',
			'lending.other' => 'En annen bibliotek',
			'lending.libraryName' => 'Biblioteksnavnet',
			'lending.libraryUrl' => 'Biblioteksnettsted',
			'lending.libraryUrlHint' => 'Bruk bibliotekets katalog eller sign-in-side.',
			'lending.intro' => 'Lån fra biblioteket ditt, hold bøkene dine lukket.',
			'lending.handoff' => 'Registrer deg, låne og les på en sikker måte med bibliotekets egen tjeneste.',
			'lending.openService' => 'Åpne bibliotek',
			'lending.findLibrary' => 'Finn en bibliotek',
			'lending.search' => 'Søk etter bøker og forfattere',
			'lending.catalogue' => 'Kataloger',
			'lending.loans' => 'Lån',
			'lending.holds' => 'Reservasjoner',
			'lending.signIn' => 'Registrer deg med biblioteket ditt',
			'lending.waiting' => 'Endre registreringen i nettleseren din, og deretter tilbake her.',
			'lending.cancel' => 'Avbryt',
			'lending.disconnect' => 'Fjern biblioteket',
			'lending.disconnectMessage' => 'Fjern dette biblioteket fra denne profilen? Lånene og reservasjonene dine blir hos biblioteket.',
			'lending.getBook' => 'Få bok',
			'lending.checkAvailability' => 'Sjekk tilgjengeligheten',
			'lending.available' => 'Tilgjengelig for lån',
			'lending.unavailable' => 'Foreløpig ikke tilgjengelig',
			'lending.borrow' => 'Lån',
			'lending.placeHold' => 'Reserver',
			'lending.returnBook' => 'Retur tidlig',
			'lending.cancelHold' => 'Avbestill reservasjon',
			'lending.confirmBorrow' => 'Lån dette titlet fra biblioteket ditt?',
			'lending.confirmReturn' => 'Lever tilbake denne tittelen nå? Du må kanskje låne den igjen for å fortsette.',
			'lending.confirmCancelHold' => 'Avbestill reservasjonen din av denne tittelen?',
			'lending.email' => 'Hold melding e-post',
			'lending.due' => ({required Object date}) => 'Avgjørende ${date}',
			'lending.queue' => ({required Object position}) => 'Posisjon ${position} i linje',
			'lending.empty' => 'Ingen titler her ennå.',
			'lending.openLibraryNote' => 'Lesing og lånealternativer vises på hver tittelside.',
			'lending.more' => 'Late mer',
			'lending.gateway' => 'Biblioteket sign-in service',
			'lending.gatewayHint' => 'Leveres av biblioteket ditt eller administratoren PlezyNG.',
			'lending.advanced' => 'Biblioteksintegrasjon',
			'lending.loadLibraries' => 'Velg din bibliotek',
			'lending.expired' => 'Dette lånet er utløpt.',
			'lending.updated' => 'Biblioteket oppdatert',
			'lending.continueService' => 'Fortsett i tjeneste',
			'lending.comingSoon' => 'In-app låne · Kom snart',
			'lending.comingSoonDescription' => 'Du kan bruke biblioteket ditt i Libby mens vi slutter å koble det.',
			'lending.suspendHold' => 'Opphør hold',
			'lending.resumeHold' => 'Resumé hold',
			'lending.suspendMessage' => 'Behold plassen din i køen, og la neste leser låne dette eksemplaret? Du kan gjenoppta reservasjonen senere.',
			'lending.resumeMessage' => 'Gjenoppta denne reservasjonen slik at biblioteket kan tilby deg neste tilgjengelige eksemplar?',
			'lending.editEmail' => 'Endre melding e-post',
			'audiobook.syncTitle' => 'Lesing og lytte synkroniserer',
			'audiobook.syncHelp' => 'Hold lesingposisjoner, lyttingposisjoner, fullføringstilstand, bokmerker og notater over enhetene dine. Velg en tilkoblet lagringskonto og bruk den samme synkroniseringskoden på hver enhet. Lesing og lytting forblir separate.',
			'audiobook.addSyncSource' => 'Legg til Google Drive, OneDrive, Dropbox, WebDAV eller S3 i filer og bøker først.',
			'audiobook.syncDestination' => 'Synk lagringskonto',
			'audiobook.syncFolder' => 'Synk mappe eller prefix',
			'audiobook.syncFolderHelp' => 'Bruk en separat eksisterende mappe i din WebDAV kilde, eller en dedikert S3 prefix. Book filer endres aldri.',
			'audiobook.syncCode' => 'Privat synkroniseringskode',
			'audiobook.syncCodeHelp' => 'Skap en kode på din første enhet, deretter skriv den koden på andre enheter. Hold en privat kopi: det er nøkkelen til kryptert tilstand. Bruk en annen kode for hver person.',
			'audiobook.showCode' => 'Vis eller skjule synkroniseringskode',
			'audiobook.newSyncCode' => 'Skap en ny synkroniseringskode',
			'audiobook.saveSync' => 'Spar og synkronisere',
			'audiobook.disableSync' => 'Unngå synkronisering på denne enheten',
			'audiobook.syncSourceDisconnect' => 'Fjerning av denne kilden vil slette lesing og lytte synk her. krypterte synk filer vil forbli i leverandøren.',
			'audiobook.syncReconnect' => 'Åpne lagringskontoen',
			'audiobook.lastSynced' => ({required Object time}) => 'Sist synkronisert på ${time}',
			'audiobook.syncPrivacy' => 'Kun krypterte fremgang og notater er lagret. Audio og ebook filer, konto tokener og passord er ikke lastet opp. Google Drive og OneDrive bruker app lagring; Dropbox bruker PlezyNG Sync. Tillat synkronisering kan kreve ytterligere skriving tilgang. Mens aktivert, denne destinasjonen eier fremgang synkronisering; server fremgang forblir separat. Turning synkronisering avbeholder lokal historie og fjerne tilstand.',
			'audiobook.syncConflicts' => 'Velg hvor du skal gjenoppta',
			'audiobook.conflictHelp' => 'Disse endringene ble gjort uavhengig. Velg posisjonen eller bookmarkversjonen for å holde. En senere timestamp eller en høyere prosentandel vinner ikke automatisk.',
			'audiobook.syncDevice' => ({required Object device}) => 'Utstyr ${device}',
			'audiobook.syncUnknownDevice' => 'ukjente enheter',
			'audiobook.deletedBookmark' => 'Fjernet bokmerke',
			'audiobook.finished' => 'Avslutter',
			'audiobook.readingPosition' => ({required Object percent}) => 'Lesing · ${percent}%',
			'audiobook.chapterTimeline' => 'Kapittel Progress',
			'audiobook.bookTimeline' => 'Hele boken fremskritt',
			'audiobook.bookRemaining' => ({required Object time}) => 'Tid i denne boken: ${time}',
			'audiobook.chapterRemaining' => ({required Object time}) => 'Tid igjen i dette kapitlet: ${time}',
			'audiobook.unknownRemaining' => 'Totalt tilgjengelig tid som deler spilles',
			'audiobook.undoSeek' => 'Endelig søkt',
			'audiobook.customSpeed' => 'Custom playback hastighet',
			'audiobook.speedHelp' => 'Velg en hastighet fra 0.25× til 4×.',
			'audiobook.apply' => 'Anvendt',
			'audiobook.customSleep' => 'Personlig søvn timer',
			'audiobook.sleepMinutes' => 'Minutter (1 til 1440)',
			'audiobook.sleepChapters' => ({required Object count}) => 'Stopp etter ${count} kapittel',
			'audiobook.extendSleep' => 'Legg til 5 minutter',
			'audiobook.sleepRemaining' => ({required Object time}) => 'Søvn timer: ${time}',
			'audiobook.useDefaults' => 'Bruk disse lyttekontroller for nye bøker',
			'audiobook.librarySort' => 'Sort bøker',
			'audiobook.sortTitle' => 'Tittel',
			'audiobook.sortAuthor' => 'Forfatter',
			'audiobook.sortNarrator' => 'Narratør',
			'audiobook.sortSeries' => 'Serien ordre',
			'audiobook.sortRecent' => 'Nylig åpnet',
			'audiobook.statusFilter' => 'Lesing status',
			'audiobook.statusAll' => 'Alle bøker',
			'audiobook.statusNew' => 'Ikke startet',
			'audiobook.statusProgress' => 'I fremskritt',
			'audiobook.statusFinished' => 'Avslutter',
			'audiobook.goToTime' => 'Gå til tid',
			'audiobook.timeHelp' => 'Tider: minutter: sekunder eller minutter: sekunder',
			'audiobook.recoveryHelp' => 'Eksport en nylig kryptert kopi før du flytter eller reparerer synkronisering data. Importerer fusjon med nåværende tilstand; de erstattes aldri lokal synkroniseringshistorie.',
			'audiobook.recoveryExport' => 'Eksport kryptert gjenoppretting filer',
			'audiobook.recoveryImport' => 'Import kryptert gjenoppretting filer',
			'audiobook.recoveryImportConfirm' => 'Kombiner denne krypterte gjenoppretting filen med aktuelle lesing posisjoner og notater? eksisterende historie vil bli bevaret. delt bibliotek og element IDs er ikke inkludert; sette matching IDs på hver enhet før import.',
			'audiobook.recoveryExported' => 'Kryptert gjenoppretting fil lagret.',
			'audiobook.recoveryImported' => 'Data om gjenoppretting sammensatt.',
			'sourceSetup.savedCertificate' => 'Lagret serversertifikat',
			'sourceSetup.nfsEndpointInvalid' => 'Angi en NFS-URL, for eksempel nfs://nas:2049/export.',
			'sourceSetup.dlnaNone' => 'Ingen DLNA-servere funnet. Angi URL-en til enhetsbeskrivelsen manuelt.',
			'sourceSetup.dlnaServers' => 'DLNA-medieservere',
			'sourceSetup.dlnaUnavailable' => 'DLNA-oppdagelse er ikke tilgjengelig på dette nettverket. Angi URL-en til enhetsbeskrivelsen manuelt.',
			'sourceSetup.dlnaSearching' => 'Søker etter DLNA-servere på lokalnettet',
			'sourceSetup.networkSearching' => 'Søker på lokalnettet…',
			'sourceSetup.dlnaDiscover' => 'Finn DLNA-servere',
			'sourceSetup.dlnaHelp' => 'Oppdagelse avhenger av multicast på lokalnettet. Hvis ingen server vises, angir du URL-en til enhetsbeskrivelsen ovenfor.',
			'sourceSetup.dlnaRoot' => 'DLNA-objekt-ID; la stå tomt for å bruke enhetens rot.',
			'sourceSetup.passwordOrKey' => 'Angi et passord eller legg til en privat nøkkel nedenfor.',
			'sourceSetup.sshFingerprint' => 'SHA256-fingeravtrykk for SSH-vertsnøkkel',
			'sourceSetup.sshFingerprintHelp' => 'Kontroller det med serveradministratoren. Kjør ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub på serveren og bruk SHA256-verdien.',
			'sourceSetup.sshFingerprintKeep' => 'La stå tomt for å beholde det fastlåste fingeravtrykket, eller angi et nytt serverfingeravtrykk.',
			'sourceSetup.sshAuthentication' => 'SSH-autentisering med offentlig nøkkel',
			'sourceSetup.sshAuthenticationHelp' => 'Valgfritt; autentisering med passord støttes også.',
			'sourceSetup.privateKey' => 'Privat nøkkel (PEM- eller OpenSSH-format)',
			'sourceSetup.privateKeyPassphrase' => 'Passfrase for privat nøkkel',
			'sourceSetup.nfsMountPort' => 'TCP-port for NFS-monteringstjenesten',
			'sourceSetup.nfsMountPortHelp' => 'Standard: 20048',
			'sourceSetup.nfsUserId' => 'NFS-bruker-ID (AUTH_SYS)',
			'sourceSetup.nfsUserIdHelp' => 'Standard: 1000. Bruk ID-en som NAS-enhetens NFS-deling tillater.',
			'sourceSetup.nfsGroupId' => 'NFS-gruppe-ID (AUTH_SYS)',
			'sourceSetup.nfsGroupIdHelp' => 'Standard: 1000. Bruk gruppe-ID-en som NAS-enhetens NFS-deling tillater.',
			'sourceSetup.nfsEncryption' => 'Krev kryptert NFS (RPC-with-TLS)',
			'sourceSetup.nfsEncryptionHelp' => 'Krev TLS 1.3 for NFS og monteringstjenesten. Hvis NAS-enheten ikke støtter dette, avvises tilkoblingen.',
			'sourceSetup.nfsTrustCertificate' => 'Egendefinert NFS-CA eller serversertifikat (PEM, valgfritt)',
			'sourceSetup.nfsTrustHelp' => 'La stå tomt for sertifikater denne enheten stoler på. Legg ved behov til et sertifikat fra en privat CA eller et selvsignert serversertifikat; navnene må samsvare med verten i NFS-URL-en.',
			'sourceSetup.nfsTrustInvalid' => 'Bruk et CA- eller serversertifikat i PEM-format. Ikke ta med en privat nøkkel.',
			'sourceSetup.addTrustCertificate' => 'Legg til egendefinert tillitssertifikat',
			'sourceSetup.replaceTrustCertificate' => 'Erstatt lagret egendefinert sertifikat',
			'sourceSetup.nfsTlsHelp' => 'RPC-with-TLS bruker de vanlige portene for NFS og monteringstjenesten og krever RFC 9289-støtte på NAS-enheten. TLS 1.3 er påkrevd. Vertsnavnet eller IP-adressen må samsvare med sertifikatet. AUTH_SYS UID/GID gjelder fortsatt i den krypterte kanalen.',
			'sourceSetup.clientCertificate' => 'Klientsertifikat (valgfritt)',
			'sourceSetup.clientCertificateHelp' => 'Lar NAS-enheten autentisere denne klienten; AUTH_SYS-ID-er avhenger fortsatt av reglene for NAS-enhetens NFS-deling.',
			'sourceSetup.savedIdentity' => 'En lagret klientidentitet vil bli brukt.',
			'sourceSetup.replaceIdentity' => 'Erstatt lagret klientidentitet',
			'sourceSetup.chooseIdentity' => 'Velg PKCS#12-klientidentitet',
			'sourceSetup.identityPassphrase' => 'Passfrase for klientidentitet',
			'sourceSetup.identityPassphraseHelp' => 'La stå tomt hvis filen ikke har en passfrase.',
			'sourceSetup.removeIdentity' => 'Fjern eventuell lagret klientidentitet',
			'sourceSetup.identityStorageHelp' => 'Klientidentiteter lagres i kildens krypterte lager for påloggingsinformasjon. La denne delen være uendret for å beholde den lagrede identiteten.',
			'sourceSetup.nfsLimitations' => 'Skrivebeskyttet NFSv3 over TCP. Uten RPC-with-TLS er NFS-trafikken ukryptert. NAS-enheten må tillate de valgte AUTH_SYS-ID-ene og uprivilegerte klientporter (ofte kalt eksportvalget «insecure»). NFSv4 og UDP støttes ikke.',
			'sourceSetup.nfsSetupHelp' => 'Hjelp med NFS-oppsett',
			'sourceSetup.nfsSetupHint' => 'Kontroller disse innstillingene hvis tilkoblingen ikke opprettes.',
			'sourceSetup.nfsSetupDetails' => 'Bruk en NFSv3-deling over TCP. Når kryptering kreves, må både NFS-tjenesten og monteringstjenesten støtte RPC-with-TLS. La det egendefinerte sertifikatet stå tomt for et serversertifikat denne enheten stoler på, eller legg til NAS-enhetens CA- eller selvsignerte sertifikat. Sertifikatnavnet må samsvare med verten i endepunktet. Hvis NAS-enheten krever gjensidig TLS, legger du til dens PKCS#12-klientidentitet. Bekreft til slutt at delingen tillater konfigurerte AUTH_SYS UID/GID og reglene for klientporter.',
			'sourceSetup.ftpHelp' => 'FTP bruker passiv modus. Bruk ftp:// for ukryptert FTP, ftpes:// for eksplisitt TLS eller ftps:// for TLS (implisitt på port 990; eksplisitt på andre porter).',
			'sourceSetup.openSubtitles' => 'OpenSubtitles',
			'sourceSetup.subtitleSetup' => 'Valgfritt søk etter undertekster for frittstående videoer.',
			'sourceSetup.apiKey' => 'API-nøkkel',
			'sourceSetup.optionalUsername' => 'Kontoens brukernavn (valgfritt)',
			'sourceSetup.optionalPassword' => 'Kontoens passord (valgfritt)',
			'sourceSetup.subtitlePrivacy' => 'Hent en API-nøkkel fra opensubtitles.com. Søk sender videotittelen og tilgjengelige IMDb/TMDB-ID-er, aldri videofilen. Nøkkelen og valgfri kontoinformasjon krypteres sammen med denne kilden.',
			'sourceSetup.automaticMetadata' => 'Automatiske videometadata fra nettet',
			'sourceSetup.metadataPrivacy' => 'Sender bare tittel/år fra filnavnet og episodenumre eller en NFO-ID, aldri medier eller påloggingsinformasjon. NFO-feltene beholder forrang.',
			'sourceSetup.nfsEncryptionFailure' => 'For kryptert NFS må du kontrollere støtte for RFC 9289 og TLS 1.3 på begge NAS-tjenestene, sertifikatnavnet og delingens UID/GID. PlezyNG prøver ikke denne tilkoblingen på nytt uten kryptering.',
			'sourceSetup.sourceConnecting' => 'Kobler til kilde',
			'sourceSetup.metadataSearchPrivacy' => 'Dette tittelsøket sendes til Trakt. Det sender tittelen du oppgir, ikke videoen eller kildens påloggingsinformasjon.',
			'sourceSetup.chooseMatch' => 'Velg et treff',
			'sourceSetup.metadataMatchHelp' => 'Kontroller tittel og år før du velger. Trakt mottar søketittelen; videoen blir på kilden sin.',
			'sourceSetup.metadataNoMatches' => 'Ingen samsvarende titler funnet på nettet. Prøv en annen tittel.',
			'sourceSetup.metadataSearch' => 'Søk etter metadata på nettet',
			'sourceSetup.metadataLoading' => 'Søker etter film- og serieinformasjon på nettet…',
			'sourceSetup.metadataFromTrakt' => 'Metadata fra Trakt på nettet',
			'sourceSetup.metadataNoAutomaticMatch' => 'Fant ikke et automatisk titteltreff. Søk etter tittelen for å velge et treff.',
			'sourceSetup.metadataFailed' => 'Kunne ikke laste metadata fra nettet. Avspilling og lokal informasjon er fortsatt tilgjengelig.',
			'sourceSetup.videoDetailsLoading' => 'Laster videoinformasjon',
			'sourceSetup.subtitleKeyRequired' => 'OpenSubtitles-API-nøkkel kreves',
			'sourceSetup.subtitleKeyHelp' => 'Rediger denne filkilden og legg til en OpenSubtitles-API-nøkkel i de valgfrie undertekstinnstillingene.',
			'sourceSetup.subtitleSearchFailed' => 'Undertekstsøket mislyktes. Kontroller API-nøkkelen, tilkoblingen og tilgangen til tjenesten.',
			'sourceSetup.subtitleApplyFailed' => 'Kunne ikke laste ned eller bruke denne underteksten. Kontroller tilkoblingen og prøv et annet resultat.',
			'sourceSetup.subtitleSearch' => 'Søk på OpenSubtitles',
			'sourceSetup.subtitleSearchPrivacy' => 'Søket bruker tittelen og tilgjengelige IMDb/TMDB-ID-er. Videofilen blir på kilden sin. Kontroller språk, merking for tvungne undertekster eller undertekster for hørselshemmede og vurdering før du velger.',
			'sourceSetup.movieOrShow' => 'Film eller serie',
			'sourceSetup.subtitleTitleHint' => 'Angi en tittel for å avgrense resultatene',
			'sourceSetup.subtitleLanguage' => 'Undertekstspråk',
			'sourceSetup.subtitleSearching' => 'Søker på OpenSubtitles',
			'sourceSetup.subtitleNoMatches' => 'Ingen samsvarende undertekster funnet. Prøv en annen tittel eller et annet språk.',
			'sourceSetup.downloadSubtitle' => 'Last ned undertekst',
			'sourceSetup.subtitle' => 'Undertekst',
			'sourceSetup.nfsTlsRequired' => 'RPC-with-TLS kreves',
			'sourceSetup.nfsUnencrypted' => 'Ukryptert NFS',
			'sourceSetup.tlsEncrypted' => 'TLS-kryptert',
			'sourceSetup.ftpPlain' => 'Ukryptert FTP',
			'sourceSetup.sshPinned' => 'SSH-kryptert · vertsnøkkel fastlåst',
			'sourceSetup.smbEncrypted' => 'SMB3-kryptering på',
			'sourceSetup.smbUnencrypted' => 'SMB3-kryptering av',
			'sourceSetup.httpUnencrypted' => 'HTTP uten transportkryptering',
			'sourceSetup.checkEndpointSecurity' => 'Kontroller sikkerheten til endepunktet',
			'sourceSetup.fieldRequired' => ({required Object label}) => '${label} er påkrevd.',
			'sourceSetup.integerRange' => ({required Object label, required Object min, required Object max}) => 'Angi ${label} fra ${min} til ${max}.',
			'sourceSetup.replaceFile' => ({required Object name}) => 'Erstatt ${name}',
			'sourceSetup.selectedIdentity' => ({required Object name}) => 'Valgt klientidentitet: ${name}',
			'sourceSetup.subtitleRating' => ({required Object rating}) => 'Vurdering ${rating}',
			'sourceSetup.subtitleDownloading' => ({required Object title}) => 'Laster ned undertekst: ${title}',
			'sourceSetup.sharedEntryPair' => 'Par dette elementet',
			'sourceSetup.sharedEntryPairHelp' => 'Skriv inn samme ID for dette elementet på hver enhet. Bruk en stabil delt identifikator eller generer en og kopier den til det matchende elementet. Progress parer bare når utgave filtyper, størrelser og bestillinger matcher. Blank fjerner denne kartleggingen.',
			'sourceSetup.sharedEntryId' => 'Delte elementer ID',
			'sourceSetup.generateSharedEntryId' => 'Generere delt element ID',
			'sourceSetup.sharedLibraryId' => 'Delte bibliotek ID (alternativt)',
			'sourceSetup.sharedLibraryHelp' => 'Bruk den samme ID på enheter som åpner samme bibliotek. Denne offentlige ID hjelper med å føre lesing fremskritt og notater gjennom ulike kildeforbindelser; det er ikke et passord. Når leverandører bruker forskjellige elementer ID, par disse elementene fra detaljskjermene sine.',
			'sourceSetup.sharedLibraryInvalid' => 'Bruk 8–100 bokstaver, tall, poeng, underscore eller hyphens.',
			'sourceSetup.generateSharedLibraryId' => 'Generere en delt bibliotek ID',
			'sourceSetup.nfsReadAhead' => 'NFS Les-ahead forespørsler',
			'sourceSetup.nfsReadAheadHelp' => 'Flere parallelle lesinger kan forbedre gjennomgangen på en rask NAS eller nettverk. Bruk 1 hvis serveren begrenser samtidige forespørsler.',
			'sourceSetup.nfsReadTest' => 'NFS leser ytelse',
			'sourceSetup.nfsReadTestHelp' => 'Leser opp til 64 MiB fra den største filen for å måle denne NAS-tilkoblingen.',
			'sourceSetup.nfsQualificationResult' => 'NFS leser måling',
			'sourceSetup.nfsReadBytes' => 'Data leses',
			'sourceSetup.nfsReadSpeed' => 'Målt hastighet',
			'sourceSetup.nfsReadRequests' => 'Les forespørsler',
			'sourceSetup.sharedEntryConflict' => 'Denne delte element ID er allerede parert med et annet element i denne biblioteket.',
			'comics.fitHeight' => 'Tilpass høyden',
			'comics.readingMode' => 'Lesemodus',
			'comics.paged' => 'Sider',
			'comics.webtoon' => 'Kontinuerlig rulling',
			'comics.coverAlone' => 'Vis omslaget alene',
			'comics.splitWide' => 'Del brede sider',
			'comics.splitWideHelp' => 'Vis hver halvdel separat i leserekkefølge. Visning av to sider sammen settes på pause mens dette er slått på.',
			'comics.thumbnails' => 'Sideminiatyrer',
			'comics.controlsHelp' => 'Sveip for å bla. Trykk to ganger for å endre tilpasning. Ved kontinuerlig rulling sveiper du loddrett eller bruker Page Up og Page Down.',
			'comics.savedForComic' => 'Visningsinnstillingene huskes for denne tegneserien i denne profilen.',
			'comics.readLists' => 'Leselister',
			'comics.collections' => 'Samlinger',
			'games.title' => 'Games',
			'games.enable' => 'Show Games for this profile',
			'games.enableDescription' => 'Discover your gaming computers and play with an embedded streaming engine.',
			'games.subtitle' => 'Your games, from your computers.',
			'games.computers' => 'Your computers',
			'games.nearby' => 'Nearby computers',
			'games.findComputers' => 'Find computers',
			'games.addComputer' => 'Add computer',
			'games.scanHint' => 'Keep Steam Remote Play or Sunshine running on the same network. VPNs and guest networks may need a manual address.',
			'games.empty' => 'Add your gaming computer to get started.',
			'games.noNearby' => 'No computers found on this network. You can enter an address manually.',
			'games.name' => 'Computer name',
			'games.address' => 'IP address or hostname',
			'games.port' => 'Service port',
			'games.protocol' => 'Streaming service',
			'games.moonlight' => 'Sunshine / Moonlight',
			'games.steam' => 'Steam Remote Play',
			'games.save' => 'Save computer',
			'games.invalidAddress' => 'Enter a valid hostname or IP address, without a URL, and a port from 1 to 65534.',
			'games.pair' => 'Connect computer',
			'games.pairTitle' => 'Approve this device',
			'games.pairInstructions' => 'Enter this code in the host’s pairing prompt. For Sunshine, use the PIN page below. Keep this screen open until the computer approves.',
			'games.pairHelp' => 'Connect this computer again to approve or renew pairing.',
			'games.openPairingPage' => 'Open Sunshine PIN page',
			'games.qrHelp' => 'Scan to open the PIN page. The QR code contains only the computer address, never a password or pairing credential.',
			'games.refreshGames' => 'Refresh games',
			'games.play' => 'Play',
			'games.recent' => 'Recently opened',
			'games.favorites' => 'Favorites',
			'games.allGames' => 'All games',
			'games.search' => 'Find a game',
			'games.noMatches' => 'No games match this search.',
			'games.favorite' => 'Save favorite',
			'games.unfavorite' => 'Remove favorite',
			'games.forget' => 'Forget computer',
			'games.forgetDescription' => 'Remove this computer and its game shortcuts from this profile? To revoke this device’s authorization, remove it from the host’s paired devices.',
			'games.unavailable' => 'The connection could not complete. Check that the computer is awake and paired, then try again.',
			'games.timeout' => 'Connection timed out. Check the computer, pairing code and network before trying again.',
			'games.libraryHint' => 'Choose a computer to connect and load its games. Once connected, choose a game to play inside PlezyNG.',
			'games.touchControls' => 'On-screen controller',
			'games.touchDescription' => 'Show the native controller during a stream. It supports multiple fingers, sticks, buttons and triggers.',
			'games.touchSetup' => 'On-screen controls',
			'games.touchSetupHint' => 'Moonlight’s controller settings support position and opacity changes. During a Steam stream, open the stream menu to toggle its controller. Bluetooth or USB input is also supported.',
			'games.addGame' => 'Add game shortcut',
			'games.gameName' => 'Game name',
			'games.gameId' => 'Host application ID',
			'games.invalidGame' => 'Enter a game name and a positive numeric host application ID.',
			'games.wake' => 'Wake computer',
			'games.wakeSent' => 'Wake request sent. The computer must support Wake-on-LAN on this network.',
			'games.mac' => 'MAC address (optional)',
			'games.help' => 'Games help',
			'games.helpBody' => 'Enable Games for your profile, choose a computer and approve the first connection. Sunshine-compatible hosts load their app list into the game grid. On Android, Steam pairing opens Big Picture inside PlezyNG; saved Steam app-ID shortcuts launch directly. Steam pairing does not grant access to a private account library.\n\nBoth Android engines include touch controls and gamepad input. Pyrowave is an experimental Android option; other native platforms remain in development.\n\nPairing requires the host’s approval. Sunshine QR codes open its PIN page without carrying credentials. For access away from home, use the computer’s VPN address. Automatic discovery normally stays on the local network.\n\nDisconnecting leaves the game running on the computer.',
			'games.cancel' => 'Cancel',
			'games.scanning' => 'Looking for computers…',
			'games.saveShortcut' => 'Save shortcut',
			'games.manualHint' => 'For Moonlight use the host’s GameStream HTTP port (usually 47989), not its web settings port. Steam normally advertises on 27036.',
			'games.engineUnavailable' => 'In-app streaming is not available here yet',
			'games.nativeEnginePending' => 'This build does not include a streaming engine for this platform. You can save the computer, but it cannot play here yet.',
			'games.steamEnginePending' => 'This build does not include the embedded Steam engine. Android builds with Games enabled bundle device pairing and in-app H.264/HEVC playback. Pyrowave is experimental on Android; other platforms remain under development.',
			'games.steamBetaTitle' => 'Steam beta · Pyrowave',
			'games.steamBetaDescription' => 'Experimental Steam beta codec. Off by default; it uses 5–10× more bandwidth than H.264/HEVC, and Valve recommends gigabit Ethernet. Android playback is limited to SDR 4:2:0 with CPU readback and has not been device-qualified.',
			'games.steamLibrary' => 'Steam library',
			'games.linkSteamAccount' => 'Link Steam account',
			'games.refreshSteamAccount' => 'Refresh Steam account',
			'games.unlinkSteamAccount' => 'Unlink Steam account',
			'games.unlinkSteamAccountConfirm' => 'Remove this account and its imported catalog from this profile? Your paired computers and shortcuts stay available.',
			'games.steamAccountLinked' => 'Steam account linked. Games imported.',
			'games.steamLibraryPrivate' => 'Steam account linked. Its library is private or unavailable, so no games were imported.',
			'games.steamAppId' => 'Steam App ID',
			'games.steamLibraryStale' => 'Steam could not refresh the library. Showing the last available catalog.',
			'games.steamLibraryTruncated' => 'Showing up to 2,000 games. The Steam catalog was truncated.',
			'games.connecting' => 'Connecting…',
			'games.disconnect' => 'Disconnect',
			'games.streamControls' => 'Stream controls',
			'games.steamPairInstructions' => 'Enter this code in Steam’s Remote Play pairing prompt on your computer. Keep this screen open until Steam approves.',
			'games.steamLibraryHint' => 'Steam device pairing opens its library inside the stream. Add a shortcut with a Steam app ID for direct launch. Importing a private account library as game cards requires a separate authenticated catalog connection.',
			'deepLinks.invalid' => 'Denne linken til Plezy er ikke gyldig.',
			'deepLinks.profileNotFound' => ({required Object profile}) => 'Ingen profil matcher "${profile}".',
			'deepLinks.serverUnavailable' => 'Kan ikke nå serveren for denne koblingen.',
			'deepLinks.notFound' => 'Du kan ikke finne denne tittelen i biblioteket ditt.',
			'deepLinks.unsupportedItem' => 'Denne linken kan ikke spilles.',
			'deepLinks.noLiveTv' => 'Ingen Live TV-server er tilgjengelig for denne koblingen.',
			'deepLinks.channelNotFound' => ({required Object channel}) => 'Kan ikke finne kanal "${channel}".',
			'deepLinks.showLink' => 'Vis link',
			_ => null,
		} ?? switch (path) {
			'deepLinks.showProfileLink' => 'Vis profil link',
			'deepLinks.dialogTitle' => 'Link',
			'deepLinks.showHint' => 'Åpne denne koblingen spiller neste episode. Legg til &mode=shuffle for å spille showet på shuffle.',
			'deepLinks.movieHint' => 'Åpning av denne koblingen spiller filmen.',
			'deepLinks.episodeHint' => 'Åpning av dette linket spiller denne episoden.',
			'deepLinks.profileHint' => 'Åpne denne koblingen skifter til denne profilen.',
			'deepLinks.openAsProfile' => ({required Object name}) => 'Åpne som ${name}',
			'deepLinks.copy' => 'Kopierer',
			'deepLinks.copied' => 'Link kopieres',
			_ => null,
		};
	}
}
