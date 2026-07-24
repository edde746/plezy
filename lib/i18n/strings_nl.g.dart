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
class TranslationsNl extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsNl({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.nl,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <nl>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsNl _root = this; // ignore: unused_field

	@override 
	TranslationsNl $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsNl(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$nl app = _Translations$app$nl._(_root);
	@override late final _Translations$auth$nl auth = _Translations$auth$nl._(_root);
	@override late final _Translations$common$nl common = _Translations$common$nl._(_root);
	@override late final _Translations$screens$nl screens = _Translations$screens$nl._(_root);
	@override late final _Translations$update$nl update = _Translations$update$nl._(_root);
	@override late final _Translations$settings$nl settings = _Translations$settings$nl._(_root);
	@override late final _Translations$search$nl search = _Translations$search$nl._(_root);
	@override late final _Translations$hotkeys$nl hotkeys = _Translations$hotkeys$nl._(_root);
	@override late final _Translations$fileInfo$nl fileInfo = _Translations$fileInfo$nl._(_root);
	@override late final _Translations$mediaMenu$nl mediaMenu = _Translations$mediaMenu$nl._(_root);
	@override late final _Translations$rateSheet$nl rateSheet = _Translations$rateSheet$nl._(_root);
	@override late final _Translations$accessibility$nl accessibility = _Translations$accessibility$nl._(_root);
	@override late final _Translations$tooltips$nl tooltips = _Translations$tooltips$nl._(_root);
	@override late final _Translations$audioTracks$nl audioTracks = _Translations$audioTracks$nl._(_root);
	@override late final _Translations$videoControls$nl videoControls = _Translations$videoControls$nl._(_root);
	@override late final _Translations$messages$nl messages = _Translations$messages$nl._(_root);
	@override late final _Translations$subtitlingStyling$nl subtitlingStyling = _Translations$subtitlingStyling$nl._(_root);
	@override late final _Translations$mpvConfig$nl mpvConfig = _Translations$mpvConfig$nl._(_root);
	@override late final _Translations$dialog$nl dialog = _Translations$dialog$nl._(_root);
	@override late final _Translations$profiles$nl profiles = _Translations$profiles$nl._(_root);
	@override late final _Translations$connections$nl connections = _Translations$connections$nl._(_root);
	@override late final _Translations$discover$nl discover = _Translations$discover$nl._(_root);
	@override late final _Translations$errors$nl errors = _Translations$errors$nl._(_root);
	@override late final _Translations$libraries$nl libraries = _Translations$libraries$nl._(_root);
	@override late final _Translations$about$nl about = _Translations$about$nl._(_root);
	@override late final _Translations$serverSelection$nl serverSelection = _Translations$serverSelection$nl._(_root);
	@override late final _Translations$hubDetail$nl hubDetail = _Translations$hubDetail$nl._(_root);
	@override late final _Translations$logs$nl logs = _Translations$logs$nl._(_root);
	@override late final _Translations$licenses$nl licenses = _Translations$licenses$nl._(_root);
	@override late final _Translations$navigation$nl navigation = _Translations$navigation$nl._(_root);
	@override late final _Translations$explore$nl explore = _Translations$explore$nl._(_root);
	@override late final _Translations$liveTv$nl liveTv = _Translations$liveTv$nl._(_root);
	@override late final _Translations$collections$nl collections = _Translations$collections$nl._(_root);
	@override late final _Translations$playlists$nl playlists = _Translations$playlists$nl._(_root);
	@override late final _Translations$music$nl music = _Translations$music$nl._(_root);
	@override late final _Translations$watchTogether$nl watchTogether = _Translations$watchTogether$nl._(_root);
	@override late final _Translations$downloads$nl downloads = _Translations$downloads$nl._(_root);
	@override late final _Translations$shaders$nl shaders = _Translations$shaders$nl._(_root);
	@override late final _Translations$companionRemote$nl companionRemote = _Translations$companionRemote$nl._(_root);
	@override late final _Translations$videoSettings$nl videoSettings = _Translations$videoSettings$nl._(_root);
	@override late final _Translations$performanceOverlay$nl performanceOverlay = _Translations$performanceOverlay$nl._(_root);
	@override late final _Translations$externalPlayer$nl externalPlayer = _Translations$externalPlayer$nl._(_root);
	@override late final _Translations$metadataEdit$nl metadataEdit = _Translations$metadataEdit$nl._(_root);
	@override late final _Translations$matchScreen$nl matchScreen = _Translations$matchScreen$nl._(_root);
	@override late final _Translations$serverTasks$nl serverTasks = _Translations$serverTasks$nl._(_root);
	@override late final _Translations$trakt$nl trakt = _Translations$trakt$nl._(_root);
	@override late final _Translations$seerr$nl seerr = _Translations$seerr$nl._(_root);
	@override late final _Translations$services$nl services = _Translations$services$nl._(_root);
	@override late final _Translations$addServer$nl addServer = _Translations$addServer$nl._(_root);
}

// Path: app
class _Translations$app$nl extends Translations$app$en {
	_Translations$app$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _Translations$auth$nl extends Translations$auth$en {
	_Translations$auth$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Inloggen met Plex';
	@override String get showQRCode => 'Toon QR-code';
	@override String get authenticate => 'Authenticeren';
	@override String get authenticationTimeout => 'Authenticatie verlopen. Probeer opnieuw.';
	@override String get scanQRToSignIn => 'Scan deze QR-code om in te loggen';
	@override String get waitingForAuth => 'Wachten op authenticatie...\nMeld je aan via je browser.';
	@override String get useBrowser => 'Gebruik browser';
	@override String get or => 'of';
	@override String get connectToJellyfin => 'Verbinden met Jellyfin';
	@override String get useQuickConnect => 'Quick Connect gebruiken';
	@override String get quickConnectInstructions => 'Open Quick Connect in Jellyfin en voer deze code in.';
	@override String get quickConnectWaiting => 'Wachten op goedkeuring…';
	@override String get quickConnectCancel => 'Annuleren';
	@override String get quickConnectExpired => 'Quick Connect is verlopen. Probeer opnieuw.';
	@override String get localDataRecoveryRequired => 'Plezy kon lokale aanmeldings- en openstaande afspeelgegevens niet veilig herstellen. Meld je opnieuw aan.';
}

// Path: common
class _Translations$common$nl extends Translations$common$en {
	_Translations$common$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Annuleren';
	@override String get save => 'Opslaan';
	@override String get close => 'Sluiten';
	@override String get clear => 'Wissen';
	@override String get reset => 'Resetten';
	@override String get later => 'Later';
	@override String get submit => 'Verzenden';
	@override String get confirm => 'Bevestigen';
	@override String get retry => 'Opnieuw proberen';
	@override String get logout => 'Uitloggen';
	@override String get unknown => 'Onbekend';
	@override String get refresh => 'Vernieuwen';
	@override String get yes => 'Ja';
	@override String get no => 'Nee';
	@override String get delete => 'Verwijderen';
	@override String get edit => 'Bewerken';
	@override String get shuffle => 'Willekeurig';
	@override String get addTo => 'Toevoegen aan...';
	@override String get createNew => 'Nieuw aanmaken';
	@override String get connect => 'Verbinden';
	@override String get disconnect => 'Verbinding verbreken';
	@override String get play => 'Afspelen';
	@override String get pause => 'Pauzeren';
	@override String get resume => 'Hervatten';
	@override String get error => 'Fout';
	@override String get search => 'Zoeken';
	@override String get home => 'Home';
	@override String get back => 'Terug';
	@override String get settings => 'Instellingen';
	@override String get mute => 'Dempen';
	@override String get ok => 'OK';
	@override String get off => 'Uit';
	@override String seasonNumber({required Object number}) => 'Seizoen ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'Aflevering ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'Hoofdstuk ${number}';
	@override String get reconnect => 'Opnieuw verbinden';
	@override String get viewAll => 'Alles weergeven';
	@override String get checkingNetwork => 'Netwerk controleren...';
	@override String get loadingServers => 'Servers laden...';
	@override String get connectingToServers => 'Verbinden met servers...';
	@override String get startingOfflineMode => 'Offlinemodus starten...';
	@override String get loading => 'Laden...';
	@override String get fullscreen => 'Volledig scherm';
	@override String get exitFullscreen => 'Volledig scherm verlaten';
	@override String get pressBackAgainToExit => 'Druk nogmaals op terug om af te sluiten';
}

// Path: screens
class _Translations$screens$nl extends Translations$screens$en {
	_Translations$screens$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licenties';
	@override String get switchProfile => 'Wissel van profiel';
	@override String get subtitleStyling => 'Ondertitelopmaak';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Logbestanden';
}

// Path: update
class _Translations$update$nl extends Translations$update$en {
	_Translations$update$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get available => 'Update beschikbaar';
	@override String versionAvailable({required Object version}) => 'Versie ${version} is beschikbaar';
	@override String currentVersion({required Object version}) => 'Huidig: ${version}';
	@override String get skipVersion => 'Deze versie overslaan';
	@override String get viewRelease => 'Bekijk release';
	@override String get latestVersion => 'Je hebt de nieuwste versie';
	@override String get checkFailed => 'Kon niet controleren op updates';
}

// Path: settings
class _Translations$settings$nl extends Translations$settings$en {
	_Translations$settings$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Instellingen';
	@override String get supportDeveloper => 'Steun Plezy';
	@override String get supportDeveloperDescription => 'Doneer via Liberapay om de ontwikkeling te steunen';
	@override String get language => 'Taal';
	@override String get theme => 'Thema';
	@override String get appearance => 'Uiterlijk';
	@override String get videoPlayback => 'Video afspelen';
	@override String get videoPlaybackDescription => 'Afspeelgedrag configureren';
	@override String get advanced => 'Geavanceerd';
	@override String get episodePosterMode => 'Stijl van afleveringsposter';
	@override String get seriesPoster => 'Serieposter';
	@override String get seasonPoster => 'Seizoensposter';
	@override String get episodeThumbnail => 'Miniatuur';
	@override String get showHeroSectionDescription => 'Toon de carrousel met uitgelichte inhoud op het startscherm';
	@override String get secondsLabel => 'Seconden';
	@override String get minutesLabel => 'Minuten';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Voer duur in (${min}-${max})';
	@override String get systemTheme => 'Systeem';
	@override String get lightTheme => 'Licht';
	@override String get darkTheme => 'Donker';
	@override String get oledTheme => 'OLED';
	@override String get libraryDensity => 'Bibliotheekdichtheid';
	@override String get compact => 'Compact';
	@override String get comfortable => 'Comfortabel';
	@override String get tvCornerSpotlightBackdrop => 'Uitgelichte achtergrond in de hoek';
	@override String get tvCornerSpotlightBackdropDescription => 'Toon de uitgelichte afbeelding rechtsboven in plaats van schermvullend';
	@override String get viewMode => 'Weergavemodus';
	@override String get gridView => 'Raster';
	@override String get listView => 'Lijst';
	@override String get showHeroSection => 'Toon hoofdsectie';
	@override String get continueWatchingAction => 'Actie voor \'Doorgaan met kijken\'';
	@override String get continueWatchingPlay => 'Afspelen';
	@override String get continueWatchingDetails => 'Details openen';
	@override String get episodeAction => 'Afleveringsactie';
	@override String get episodePlay => 'Afspelen';
	@override String get episodeDetails => 'Details openen';
	@override String get useGlobalHubs => 'Startlayout gebruiken';
	@override String get useGlobalHubsDescription => 'Toon gecombineerde hubs op het startscherm. Gebruik anders bibliotheekaanbevelingen.';
	@override String get showServerNameOnHubs => 'Servernaam tonen bij hubs';
	@override String get showServerNameOnHubsDescription => 'Toon servernamen altijd in hubtitels.';
	@override String get groupLibrariesByServer => 'Bibliotheken groeperen per server';
	@override String get groupLibrariesByServerDescription => 'Groepeer zijbalkbibliotheken onder elke mediaserver.';
	@override String get alwaysKeepSidebarOpen => 'Zijbalk altijd open houden';
	@override String get alwaysKeepSidebarOpenDescription => 'Zijbalk blijft uitgevouwen en inhoudsgebied past zich aan';
	@override String get showUnwatchedCount => 'Aantal ongekeken tonen';
	@override String get showUnwatchedCountDescription => 'Toon aantal ongekeken afleveringen bij series en seizoenen';
	@override String get showEpisodeNumberOnCards => 'Afleveringsnummer op kaarten tonen';
	@override String get showEpisodeNumberOnCardsDescription => 'Toon seizoen- en afleveringsnummer op afleveringskaarten';
	@override String get showSeasonPostersOnTabs => 'Toon seizoensposters op tabbladen';
	@override String get showSeasonPostersOnTabsDescription => 'Toon de poster van elk seizoen boven het tabblad';
	@override String get tvFullCardLayout => 'Volledige tv-kaarten';
	@override String get tvFullCardLayoutDescription => 'Gebruik tv-kaarten met alleen afbeeldingen en namen van acteurs als overlay';
	@override String get focusGlow => 'Focusgloed';
	@override String get focusGlowDescription => 'Toon een zachte gloed rond de kaart met focus';
	@override String get visualEffects => 'Visuele effecten';
	@override String get visualEffectsAuto => 'Automatisch';
	@override String get visualEffectsAutoDescription => 'Effecten automatisch verminderen op apparaten met laag vermogen';
	@override String get visualEffectsFull => 'Volledig';
	@override String get visualEffectsReduced => 'Verminderd';
	@override String get visualEffectsReducedDescription => 'Minder animaties en illustraties met lagere resolutie';
	@override String get hideSpoilers => 'Spoilers voor ongekeken afleveringen verbergen';
	@override String get hideSpoilersDescription => 'Vervaag miniaturen en beschrijvingen van ongekeken afleveringen';
	@override String get playerBackend => 'Afspeelbackend';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Hardwaredecodering';
	@override String get hardwareDecodingDescription => 'Gebruik hardwareversnelling indien beschikbaar';
	@override String get bufferSize => 'Buffergrootte';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => 'Automatisch (aanbevolen)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => '${heap}MB geheugen beschikbaar. Een buffer van ${size}MB kan afspelen beïnvloeden.';
	@override String get defaultQualityTitle => 'Standaardkwaliteit';
	@override String get musicQualityTitle => 'Muziekkwaliteit';
	@override String get subtitleStyling => 'Ondertitelopmaak';
	@override String get subtitleStylingDescription => 'Pas de weergave van ondertitels aan';
	@override String get smallSkipDuration => 'Korte sprong';
	@override String get largeSkipDuration => 'Lange sprong';
	@override String get rewindOnResume => 'Terugspoelen bij hervatten';
	@override String secondsUnit({required Object seconds}) => '${seconds} seconden';
	@override String get defaultSleepTimer => 'Standaardslaaptimer';
	@override String minutesUnit({required Object minutes}) => '${minutes} minuten';
	@override String get rememberTrackSelections => 'Trackselecties per serie of film onthouden';
	@override String get rememberTrackSelectionsDescription => 'Onthoud audio- en ondertitelkeuzes per titel';
	@override String get showChapterMarkersOnTimeline => 'Hoofdstukmarkeringen op tijdlijn tonen';
	@override String get showChapterMarkersOnTimelineDescription => 'Verdeel de tijdlijn bij hoofdstukgrenzen';
	@override String get clickVideoTogglesPlayback => 'Klik op de video om afspelen of pauzeren te wisselen';
	@override String get clickVideoTogglesPlaybackDescription => 'Klik op de video om af te spelen of te pauzeren in plaats van de bediening te tonen.';
	@override String get videoPlayerControls => 'Videospelerbediening';
	@override String get keyboardShortcuts => 'Toetsenbordsneltoetsen';
	@override String get keyboardShortcutsDescription => 'Pas de toetsenbordsneltoetsen aan';
	@override String get videoPlayerNavigation => 'Videospelernavigatie';
	@override String get videoPlayerNavigationDescription => 'Gebruik de pijltjestoetsen om door de videospelerbediening te navigeren';
	@override String get watchTogetherRelay => 'Relay voor Samen kijken';
	@override String get watchTogetherRelayDescription => 'Stel een aangepaste relay in. Iedereen moet dezelfde server gebruiken.';
	@override String get watchTogetherRelayHint => 'https://mijn-relay.voorbeeld.nl';
	@override String get watchTogetherRelayInvalid => 'Voer een geldige HTTP- of HTTPS-basis-URL voor de relay in.';
	@override String get crashReporting => 'Crashrapportage';
	@override String get crashReportingDescription => 'Crashrapporten verzenden om de app te verbeteren';
	@override String get debugLogging => 'Debuglogboek';
	@override String get debugLoggingDescription => 'Schakel gedetailleerde logboekregistratie in om problemen op te lossen';
	@override String get viewLogs => 'Logbestanden bekijken';
	@override String get viewLogsDescription => 'Logbestanden van de app bekijken';
	@override String get clearCache => 'Cache wissen';
	@override String get clearCacheDescription => 'Wis gecachete afbeeldingen en gegevens. Inhoud kan langzamer laden.';
	@override String get clearCacheSuccess => 'Cache succesvol gewist';
	@override String get resetSettings => 'Instellingen resetten';
	@override String get resetSettingsDescription => 'Standaardinstellingen herstellen. Dit kan niet ongedaan worden gemaakt.';
	@override String get resetSettingsSuccess => 'Instellingen succesvol gereset';
	@override String get backup => 'Back-up';
	@override String get exportSettings => 'Instellingen exporteren';
	@override String get exportSettingsDescription => 'Sla je voorkeuren op in een bestand';
	@override String get exportSettingsSuccess => 'Instellingen geëxporteerd';
	@override String get importSettings => 'Instellingen importeren';
	@override String get importSettingsDescription => 'Voorkeuren herstellen vanuit een bestand';
	@override String get importSettingsConfirm => 'Hiermee worden je huidige instellingen vervangen. Doorgaan?';
	@override String get importSettingsSuccess => 'Instellingen geïmporteerd';
	@override String get importSettingsInvalidFile => 'Dit bestand is geen geldige Plezy-export';
	@override String get importSettingsNoUser => 'Meld je aan voordat je instellingen importeert';
	@override String get shortcutsReset => 'Sneltoetsen gereset naar standaard';
	@override String get about => 'Over';
	@override String get aboutDescription => 'App-informatie en licenties';
	@override String get updates => 'Updates';
	@override String get updateAvailable => 'Update beschikbaar';
	@override String get checkForUpdates => 'Controleer op updates';
	@override String get autoCheckUpdatesOnStartup => 'Automatisch controleren op updates bij opstarten';
	@override String get autoCheckUpdatesOnStartupDescription => 'Melden wanneer er bij start een update beschikbaar is';
	@override String get validationErrorEnterNumber => 'Voer een geldig nummer in';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Duur moet tussen ${min} en ${max} ${unit} zijn';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Sneltoets al toegewezen aan ${action}';
	@override String shortcutUpdated({required Object action}) => 'Sneltoets bijgewerkt voor ${action}';
	@override String get saveFailed => 'Wijzigingen konden niet worden opgeslagen. Probeer het opnieuw.';
	@override String get autoSkip => 'Automatisch overslaan';
	@override String get autoSkipIntro => 'Intro automatisch overslaan';
	@override String get autoSkipIntroDescription => 'Intromarkeringen na enkele seconden automatisch overslaan';
	@override String get autoSkipCredits => 'Aftiteling automatisch overslaan';
	@override String get autoSkipCreditsDescription => 'Aftiteling automatisch overslaan en de volgende aflevering afspelen';
	@override String get forceSkipMarkerFallback => 'Reservemarkeringen afdwingen';
	@override String get forceSkipMarkerFallbackDescription => 'Gebruik patronen in hoofdstuktitels, zelfs wanneer Plex markeringen heeft';
	@override String get autoSkipDelay => 'Vertraging voor automatisch overslaan';
	@override String autoSkipDelayDescription({required Object seconds}) => '${seconds} seconden wachten voor automatisch overslaan';
	@override String get introPattern => 'Intromarkeringspatroon';
	@override String get introPatternDescription => 'Reguliere expressie om intromarkeringen in hoofdstuktitels te herkennen';
	@override String get creditsPattern => 'Aftitelingmarkeringspatroon';
	@override String get creditsPatternDescription => 'Reguliere expressie om aftitelingmarkeringen in hoofdstuktitels te herkennen';
	@override String get invalidRegex => 'Ongeldige reguliere expressie';
	@override String get regex => 'Reguliere expressie';
	@override String get downloads => 'Downloads';
	@override String get downloadLocationDescription => 'Kies waar gedownloade inhoud wordt opgeslagen';
	@override String get downloadLocationDefault => 'Standaard (app-opslag)';
	@override String get downloadLocationCustom => 'Aangepaste locatie';
	@override String get selectFolder => 'Map selecteren';
	@override String get resetToDefault => 'Standaardinstelling herstellen';
	@override String currentPath({required Object path}) => 'Huidig: ${path}';
	@override String get downloadLocationChanged => 'Downloadlocatie gewijzigd';
	@override String get downloadLocationReset => 'Downloadlocatie hersteld naar standaard';
	@override String get downloadLocationInvalid => 'Geselecteerde map is niet beschrijfbaar';
	@override String get downloadLocationPickerUnavailable => 'Mapselectie is niet beschikbaar op dit apparaat';
	@override String get downloadOnWifiOnly => 'Alleen via wifi downloaden';
	@override String get downloadOnWifiOnlyDescription => 'Voorkom downloads bij gebruik van mobiele data';
	@override String get autoRemoveWatchedDownloads => 'Bekeken downloads automatisch verwijderen';
	@override String get autoRemoveWatchedDownloadsDescription => 'Bekeken downloads automatisch verwijderen';
	@override String get cellularDownloadBlocked => 'Downloads via een mobiel netwerk zijn geblokkeerd. Gebruik wifi of wijzig de instelling.';
	@override String get maxVolume => 'Maximaal volume';
	@override String get maxVolumeDescription => 'Volume boven 100% toestaan voor stille media';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Toon op Discord wat je aan het kijken bent';
	@override String get services => 'Diensten';
	@override String get servicesDescription => 'Koppel Trakt, MyAnimeList, Seerr en meer';
	@override String get manageLibrariesDescription => 'Bibliotheken herordenen en verbergen';
	@override String get companionRemoteServer => 'Companion Remote-server';
	@override String get companionRemoteServerDescription => 'Sta mobiele apparaten op je netwerk toe om deze app te bedienen';
	@override String get autoPip => 'Automatische beeld-in-beeld';
	@override String get autoPipDescription => 'Schakel over naar beeld-in-beeld als je tijdens het afspelen de app verlaat';
	@override String get matchContentFrameRate => 'Inhoudsframesnelheid afstemmen';
	@override String get matchContentFrameRateDescription => 'Stem schermverversing af op videocontent';
	@override String get matchRefreshRate => 'Verversingssnelheid afstemmen';
	@override String get matchRefreshRateDescription => 'Stem schermverversing af in volledig scherm';
	@override String get matchDynamicRange => 'Dynamisch bereik afstemmen';
	@override String get matchDynamicRangeDescription => 'Schakel HDR in voor HDR-content en daarna terug naar SDR';
	@override String get displaySwitchDelay => 'Vertraging bij schermwisseling';
	@override String get tunneledPlayback => 'Getunnelde weergave';
	@override String get tunneledPlaybackDescription => 'Gebruik videotunneling. Schakel uit als HDR-afspelen zwart beeld geeft.';
	@override String get audioPassthrough => 'Audio-doorvoer';
	@override String get audioPassthroughDescription => 'Stuur Dolby/DTS-audio zonder hercodering naar je receiver of tv en behoud surroundgeluid. Schakel uit als je geen geluid hebt.';
	@override String get audioPassthroughDescriptionAppleTv => 'Gebruik de ingebouwde Dolby-decoder van Apple voor Dolby Digital Plus, inclusief Atmos. DTS en TrueHD worden nog steeds als meerkanaals-PCM afgespeeld. Schakel dit uit als je geen geluid hoort.';
	@override String get audioDownmix => 'Downmixen naar stereo';
	@override String get audioDownmixDescription => 'Mix surroundgeluid terug naar twee kanalen voor stereoluidsprekers of een koptelefoon';
	@override String get downmixCenterBoost => 'Versterking middenkanaal';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Versterking (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Volume normaliseren bij downmix';
	@override String get audioDownmixNormalizeDescription => 'Verlaagt de mix om clipping te voorkomen. Zet uit om het originele volume te behouden (kan vervormen bij luide scènes).';
	@override String get atmosDiagnostics => 'Atmos-uitvoertest';
	@override String get atmosDiagnosticsDescription => 'Diagnosticeer de Dolby Atmos-uitvoer door testsignalen via de systeemspeler af te spelen';
	@override String get atmosTestHlsAtmos => 'Apple Atmos-stream';
	@override String get atmosTestHlsAtmosDescription => 'Bewezen werkende Dolby Atmos-stream. De receiver zou Dolby Atmos moeten tonen.';
	@override String get atmosTestHlsControl => 'Apple surround-stream';
	@override String get atmosTestHlsControlDescription => 'Controlestream zonder Atmos. De receiver zou surround zonder Atmos moeten tonen.';
	@override String get atmosTestRawStream => 'Ruwe EAC3-stream';
	@override String get atmosTestRawStreamDescription => 'Streamt het testbestand precies zoals Atmos-weergave in de speler. Vereist de URL van het testbestand.';
	@override String get atmosTestRawFile => 'Ruw EAC3-bestand';
	@override String get atmosTestRawFileDescription => 'Speelt het testbestand met bekende lengte af. Vereist de URL van het testbestand.';
	@override String get atmosTestStop => 'Test stoppen';
	@override String get atmosTestUrl => 'URL van testbestand';
	@override String get atmosTestUrlDescription => 'HTTP-URL van een ruw .ec3 Dolby Atmos-bestand (bijv. uitgepakt met ffmpeg)';
	@override String get atmosTestUrlMissing => 'Stel eerst de URL van het testbestand in';
	@override String get atmosTestStatus => 'Status';
	@override String get dvConversionMode => 'Dolby Vision-conversie';
	@override String get dvConversionModeDescription => 'Kies hoe ExoPlayer Dolby Vision Profile 7-bestanden verwerkt.';
	@override String get dvConversionAuto => 'Automatisch';
	@override String get dvConversionNative => 'Native / uitgeschakeld';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Gebruik detectie van apparaatmogelijkheden en het normale terugvalgedrag';
	@override String get dvConversionNativeDescription => 'Dwing native DV7 af en voorkom een nieuwe poging met DV-conversie';
	@override String get dvConversionDv81Description => 'Dwing directe RPU-conversie naar Dolby Vision-profiel 8.1 af';
	@override String get dvConversionHevcStripDescription => 'Verwijder Dolby Vision RPU/EL-lagen en bied gewone HEVC aan';
	@override String get requireProfileSelectionOnOpen => 'Vraag om profiel bij openen';
	@override String get requireProfileSelectionOnOpenDescription => 'Toon profielselectie telkens wanneer de app wordt geopend';
	@override String get forceTvMode => 'Tv-modus afdwingen';
	@override String get forceTvModeDescription => 'Dwing de tv-indeling af op apparaten zonder automatische detectie. Herstart vereist.';
	@override String get startInFullscreen => 'Starten in volledig scherm';
	@override String get startInFullscreenDescription => 'Open Plezy bij het starten in volledig scherm';
	@override String get exitFullscreenOnPlayerClose => 'Volledig scherm verlaten bij sluiten van speler';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Verlaat automatisch de volledigschermmodus wanneer de videospeler wordt gesloten';
	@override String get autoHidePerformanceOverlay => 'Prestatie-overlay automatisch verbergen';
	@override String get autoHidePerformanceOverlayDescription => 'Laat de prestatie-overlay samen met de afspeelknoppen vervagen';
	@override String get showNavBarLabels => 'Labels op navigatiebalk tonen';
	@override String get showNavBarLabelsDescription => 'Tekstlabels onder de pictogrammen op de navigatiebalk weergeven';
	@override String get startupSection => 'Opstartsectie';
	@override String get liveTvDefaultFavorites => 'Standaard favoriete zenders';
	@override String get liveTvDefaultFavoritesDescription => 'Toon alleen favoriete zenders bij het openen van Live TV';
	@override String get display => 'Weergave';
	@override String get homeScreen => 'Startscherm';
	@override String get navigation => 'Navigatie';
	@override String get window => 'Venster';
	@override String get content => 'Inhoud';
	@override String get player => 'Speler';
	@override String get subtitlesAndConfig => 'Ondertitels en instellingen';
	@override String get seekAndTiming => 'Spoelen en timing';
	@override String get behavior => 'Gedrag';
}

// Path: search
class _Translations$search$nl extends Translations$search$en {
	_Translations$search$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Zoek films, series, muziek...';
	@override String get tryDifferentTerm => 'Probeer een andere zoekterm';
	@override String get searchYourMedia => 'Zoek in je media';
	@override String get enterTitleActorOrKeyword => 'Voer een titel, acteur of trefwoord in';
}

// Path: hotkeys
class _Translations$hotkeys$nl extends Translations$hotkeys$en {
	_Translations$hotkeys$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Stel sneltoets in voor ${actionName}';
	@override String get clearShortcut => 'Wis sneltoets';
	@override String get noShortcutSet => 'Geen sneltoets ingesteld';
	@override String get currentShortcut => 'Huidige sneltoets:';
	@override String get pressToRecord => 'Selecteer om een sneltoets op te nemen';
	@override String get recordingShortcut => 'Druk nu op de sneltoets';
	@override late final _Translations$hotkeys$actions$nl actions = _Translations$hotkeys$actions$nl._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$nl extends Translations$fileInfo$en {
	_Translations$fileInfo$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bestandsinformatie';
	@override String get video => 'Video';
	@override String get audio => 'Audio';
	@override String get file => 'Bestand';
	@override String get advanced => 'Geavanceerd';
	@override String get codec => 'Codec';
	@override String get resolution => 'Resolutie';
	@override String get bitrate => 'Bitrate';
	@override String get frameRate => 'Framesnelheid';
	@override String get aspectRatio => 'Beeldverhouding';
	@override String get profile => 'Profiel';
	@override String get bitDepth => 'Bitdiepte';
	@override String get colorSpace => 'Kleurruimte';
	@override String get colorRange => 'Kleurbereik';
	@override String get colorPrimaries => 'Kleurprimaires';
	@override String get chromaSubsampling => 'Chroma-subsampling';
	@override String get channels => 'Kanalen';
	@override String get subtitles => 'Ondertitels';
	@override String get overallBitrate => 'Totale bitrate';
	@override String get path => 'Pad';
	@override String get size => 'Grootte';
	@override String get container => 'Container';
	@override String get duration => 'Duur';
	@override String get optimizedForStreaming => 'Geoptimaliseerd voor streaming';
	@override String get has64bitOffsets => '64-bits offsets';
}

// Path: mediaMenu
class _Translations$mediaMenu$nl extends Translations$mediaMenu$en {
	_Translations$mediaMenu$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Als bekeken markeren';
	@override String get markAsUnwatched => 'Als ongekeken markeren';
	@override String get removeFromContinueWatching => 'Uit \'Doorgaan met kijken\' verwijderen';
	@override String get viewDetails => 'Details bekijken';
	@override String get goToSeries => 'Ga naar serie';
	@override String get shufflePlay => 'Willekeurig afspelen';
	@override String get shuffleNotAvailableOffline => 'Willekeurig afspelen is offline niet beschikbaar';
	@override String get fileInfo => 'Bestandsinformatie';
	@override String get deleteFromServer => 'Van server verwijderen';
	@override String get confirmDelete => 'Deze media en bestanden van je server verwijderen?';
	@override String get deleteMultipleWarning => 'Dit omvat alle afleveringen en hun bestanden.';
	@override String get mediaDeletedSuccessfully => 'Media-item succesvol verwijderd';
	@override String get mediaFailedToDelete => 'Verwijderen van media-item mislukt';
	@override String get rate => 'Beoordelen';
	@override String get playFromBeginning => 'Afspelen vanaf het begin';
	@override String get playVersion => 'Versie afspelen...';
}

// Path: rateSheet
class _Translations$rateSheet$nl extends Translations$rateSheet$en {
	_Translations$rateSheet$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Beoordelen';
	@override String get server => 'Server';
	@override String get favorite => 'Favoriet';
	@override String get favorited => 'Toegevoegd aan favorieten';
	@override String get saved => 'Opgeslagen';
	@override String get notAvailable => 'Geen overeenkomst gevonden';
	@override String get noConnectedServices => 'Koppel een dienst in Instellingen om daar een beoordeling te geven.';
}

// Path: accessibility
class _Translations$accessibility$nl extends Translations$accessibility$en {
	_Translations$accessibility$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, film';
	@override String mediaCardShow({required Object title}) => '${title}, tv-serie';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'bekeken';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} procent bekeken';
	@override String get mediaCardUnwatched => 'niet bekeken';
	@override String get tapToPlay => 'Tik om af te spelen';
	@override String get decrease => 'Verlagen';
	@override String get increase => 'Verhogen';
	@override String decreaseValue({required Object label}) => '${label} verlagen';
	@override String increaseValue({required Object label}) => '${label} verhogen';
	@override String get hue => 'Tint';
	@override String get saturation => 'Verzadiging';
	@override String get brightness => 'Helderheid';
	@override String get hexColor => 'Hexkleur';
	@override String get expandText => 'Tekst uitvouwen';
	@override String get collapseText => 'Tekst samenvouwen';
	@override String get alphabetNavigation => 'Alfabetische navigatie';
	@override String get alphabetScrollHint => 'Veeg omhoog of omlaag om per letter te bewegen';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Rij ${row} van ${rowCount}, kolom ${column} van ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'Rij ${row} van ${rowCount}';
}

// Path: tooltips
class _Translations$tooltips$nl extends Translations$tooltips$en {
	_Translations$tooltips$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Willekeurig afspelen';
	@override String get playTrailer => 'Trailer afspelen';
	@override String get markAsWatched => 'Als bekeken markeren';
	@override String get markAsUnwatched => 'Als ongekeken markeren';
}

// Path: audioTracks
class _Translations$audioTracks$nl extends Translations$audioTracks$en {
	_Translations$audioTracks$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'Audiospoor ${n}';
}

// Path: videoControls
class _Translations$videoControls$nl extends Translations$videoControls$en {
	_Translations$videoControls$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Audio';
	@override String get subtitlesLabel => 'Ondertitels';
	@override String get resetToZero => 'Terugzetten naar 0 ms';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} speelt later af';
	@override String playsEarlier({required Object label}) => '${label} speelt eerder af';
	@override String get noOffset => 'Geen offset';
	@override String get letterbox => 'Letterbox';
	@override String get fillScreen => 'Scherm vullen';
	@override String get stretch => 'Uitrekken';
	@override String get lockRotation => 'Rotatie vergrendelen';
	@override String get unlockRotation => 'Rotatie ontgrendelen';
	@override String get timerActive => 'Timer actief';
	@override String playbackWillPauseIn({required Object duration}) => 'Afspelen wordt gepauzeerd over ${duration}';
	@override String get sleepTimerEndOfVideo => 'Einde van huidige video';
	@override String get sleepTimerStopAtHeader => 'Stoppen bij';
	@override String get sleepTimerDurationHeader => 'Timer';
	@override String get playbackWillPauseAtEnd => 'Afspelen wordt gepauzeerd aan het einde van deze video';
	@override String get stillWatching => 'Kijk je nog?';
	@override String pausingIn({required Object seconds}) => 'Pauze over ${seconds}s';
	@override String get continueWatching => 'Doorgaan';
	@override String get autoPlayNext => 'Volgende automatisch afspelen';
	@override String get playNext => 'Volgende afspelen';
	@override String get playButton => 'Afspelen';
	@override String get pauseButton => 'Pauzeren';
	@override String get showPlaybackControls => 'Afspeelbediening tonen';
	@override String get hidePlaybackControls => 'Afspeelbediening verbergen';
	@override String seekBackwardButton({required Object seconds}) => '${seconds} seconden terugspoelen';
	@override String seekForwardButton({required Object seconds}) => '${seconds} seconden vooruitspoelen';
	@override String get previousButton => 'Vorige aflevering';
	@override String get nextButton => 'Volgende aflevering';
	@override String get previousChapterButton => 'Vorig hoofdstuk';
	@override String get nextChapterButton => 'Volgend hoofdstuk';
	@override String get muteButton => 'Dempen';
	@override String get unmuteButton => 'Dempen opheffen';
	@override String get settingsButton => 'Afspeelinstellingen';
	@override String get tracksButton => 'Audio en ondertitels';
	@override String get chaptersButton => 'Hoofdstukken';
	@override String get versionQualityButton => 'Versie en kwaliteit';
	@override String get versionColumnHeader => 'Versie';
	@override String get qualityColumnHeader => 'Kwaliteit';
	@override String get qualityOriginal => 'Origineel';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Transcoderen niet beschikbaar — originele kwaliteit wordt afgespeeld';
	@override String get subtitleUnavailableFallback => 'De geselecteerde ondertitels konden niet worden geladen — afspelen gaat door zonder ondertitels';
	@override String get pipButton => 'Beeld-in-beeldmodus';
	@override String get aspectRatioButton => 'Beeldverhouding';
	@override String get ambientLighting => 'Omgevingsverlichting';
	@override String get fullscreenButton => 'Volledig scherm activeren';
	@override String get exitFullscreenButton => 'Volledig scherm verlaten';
	@override String get alwaysOnTopButton => 'Altijd bovenop';
	@override String get rotationLockButton => 'Rotatievergrendeling';
	@override String get lockScreen => 'Scherm vergrendelen';
	@override String get screenLockButton => 'Schermvergrendeling';
	@override String get longPressToUnlock => 'Lang indrukken om te ontgrendelen';
	@override String get timelineSlider => 'Videotijdlijn';
	@override String get volumeSlider => 'Volumeniveau';
	@override String endsAt({required Object time}) => 'Eindigt om ${time}';
	@override String get pipActive => 'Afspelen in beeld-in-beeld';
	@override String get pipFailed => 'Beeld-in-beeld kon niet worden gestart';
	@override String get screenshotSaved => 'Schermafbeelding opgeslagen';
	@override String zoomPercent({required Object percent}) => 'Zoom ${percent}%';
	@override late final _Translations$videoControls$pipErrors$nl pipErrors = _Translations$videoControls$pipErrors$nl._(_root);
	@override String get chapters => 'Hoofdstukken';
	@override String get noChaptersAvailable => 'Geen hoofdstukken beschikbaar';
	@override String get queue => 'Wachtrij';
	@override String get noQueueItems => 'Geen items in de wachtrij';
	@override String get searchSubtitles => 'Ondertitels zoeken';
	@override String get language => 'Taal';
	@override String get noSubtitlesFound => 'Geen ondertitels gevonden';
	@override String get noSubtitlesAvailable => 'Geen ondertitels beschikbaar';
	@override String get noAudioTracksAvailable => 'Geen audiotracks beschikbaar';
	@override String get noTracksAvailable => 'Geen tracks beschikbaar';
	@override String get subtitleDownloaded => 'Ondertitel gedownload';
	@override String get subtitleDownloadedNotApplied => 'De ondertiteling is gedownload, maar kon niet worden geselecteerd';
	@override String get subtitleDownloadFailed => 'Ondertitel downloaden mislukt';
	@override String get searchLanguages => 'Talen zoeken...';
}

// Path: messages
class _Translations$messages$nl extends Translations$messages$en {
	_Translations$messages$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Gemarkeerd als gekeken';
	@override String get markedAsUnwatched => 'Gemarkeerd als ongekeken';
	@override String get markedAsWatchedOffline => 'Gemarkeerd als bekeken (wordt gesynchroniseerd zodra je online bent)';
	@override String get markedAsUnwatchedOffline => 'Gemarkeerd als ongekeken (wordt gesynchroniseerd zodra je online bent)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Automatisch verwijderd: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nl'))(n,
		one: 'Automatisch ${n} bekeken download verwijderd',
		other: 'Automatisch ${n} bekeken downloads verwijderd',
	);
	@override String get removedFromContinueWatching => 'Verwijderd uit \'Doorgaan met kijken\'';
	@override String errorLoading({required Object error}) => 'Fout: ${error}';
	@override String get streamInterrupted => 'De stream is onderbroken. Druk op afspelen of spoel om het opnieuw te proberen.';
	@override String get liveStreamInterrupted => 'De livestream is onderbroken. Druk op afspelen om het opnieuw te proberen.';
	@override String get fileInfoNotAvailable => 'Bestandsinformatie niet beschikbaar';
	@override String get playbackAuthenticationRequired => 'Meld je opnieuw aan bij de mediaserver om dit item af te spelen.';
	@override String get playbackServerUnavailable => 'De mediaserver is niet beschikbaar. Probeer het later opnieuw.';
	@override String get playbackDataInvalid => 'De server heeft ongeldige afspeelinformatie geretourneerd.';
	@override String get playbackCancelled => 'Het afspelen is geannuleerd.';
	@override String get playbackFailed => 'Het afspelen kon niet worden gestart.';
	@override String errorLoadingFileInfo({required Object error}) => 'Fout bij laden van bestandsinformatie: ${error}';
	@override String get errorLoadingSeries => 'Fout bij laden van serie';
	@override String get musicNotSupported => 'Muziek afspelen wordt nog niet ondersteund';
	@override String get noDescriptionAvailable => 'Geen beschrijving beschikbaar';
	@override String get noProfilesAvailable => 'Geen profielen beschikbaar';
	@override String get contactAdminForProfiles => 'Neem contact op met je serverbeheerder om profielen toe te voegen';
	@override String get unableToDetermineLibrarySection => 'Kan bibliotheeksectie voor dit item niet bepalen';
	@override String get logsCleared => 'Logbestanden gewist';
	@override String get logsCopied => 'Logbestanden naar het klembord gekopieerd';
	@override String get noLogsAvailable => 'Geen logbestanden beschikbaar';
	@override String libraryScanning({required Object title}) => '"${title}" scannen...';
	@override String libraryScanStarted({required Object title}) => 'Bibliotheekscan gestart voor "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Bibliotheek scannen mislukt: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Metadata voor "${title}" vernieuwen...';
	@override String metadataRefreshStarted({required Object title}) => 'Vernieuwen van metadata gestart voor "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Metadata vernieuwen mislukt: ${error}';
	@override String get logoutConfirm => 'Weet je zeker dat je wilt uitloggen?';
	@override String get noSeasonsFound => 'Geen seizoenen gevonden';
	@override String get seasonsLoadFailed => 'Kan seizoenen niet laden';
	@override String get noEpisodesFound => 'Geen afleveringen gevonden in eerste seizoen';
	@override String get noEpisodesFoundGeneral => 'Geen afleveringen gevonden';
	@override String get episodesLoadFailed => 'Kan afleveringen niet laden';
	@override String get noResultsFound => 'Geen resultaten gevonden';
	@override String sleepTimerSet({required Object label}) => 'Slaaptimer ingesteld op ${label}';
	@override String get noItemsAvailable => 'Geen items beschikbaar';
	@override String get failedToCreatePlayQueueNoItems => 'Afspeelwachtrij maken mislukt — geen items';
	@override String failedPlayback({required Object action, required Object error}) => 'Afspelen van ${action} mislukt: ${error}';
	@override String get switchingToCompatiblePlayer => 'Overschakelen naar compatibele speler...';
	@override String get serverLimitTitle => 'Afspelen mislukt';
	@override String get serverLimitBody => 'Serverfout (HTTP 500). Waarschijnlijk weigerde een bandbreedte-/transcodeerlimiet deze sessie. Vraag de eigenaar dit aan te passen.';
	@override String get logsUploaded => 'Logbestanden geüpload';
	@override String get logsUploadFailed => 'Uploaden van logbestanden mislukt';
	@override String get logId => 'Logboek-ID';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$nl extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get text => 'Tekst';
	@override String get border => 'Rand';
	@override String get background => 'Achtergrond';
	@override String get fontSize => 'Lettergrootte';
	@override String get textColor => 'Tekstkleur';
	@override String get borderSize => 'Randdikte';
	@override String get borderColor => 'Randkleur';
	@override String get backgroundOpacity => 'Achtergronddekking';
	@override String get backgroundColor => 'Achtergrondkleur';
	@override String get position => 'Positie';
	@override String get assOverride => 'ASS-overschrijving';
	@override String get overrideScale => 'Schalen';
	@override String get overrideForce => 'Forceren';
	@override String get overrideStrip => 'Opmaak verwijderen';
	@override String get positionTop => 'Bovenaan';
	@override String get positionBottom => 'Onderaan';
	@override String get bold => 'Vet';
	@override String get italic => 'Cursief';
	@override String get renderResolution => 'Renderresolutie';
	@override String get renderResolutionScreen => 'Schermresolutie';
	@override String get renderResolutionVideo => 'Videoresolutie';
}

// Path: mpvConfig
class _Translations$mpvConfig$nl extends Translations$mpvConfig$en {
	_Translations$mpvConfig$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Geavanceerde videospelerinstellingen';
	@override String get presets => 'Voorinstellingen';
	@override String get noPresets => 'Geen opgeslagen voorinstellingen';
	@override String get saveAsPreset => 'Opslaan als voorinstelling...';
	@override String get presetName => 'Naam voorinstelling';
	@override String get presetNameHint => 'Voer een naam in voor deze voorinstelling';
	@override String get loadPreset => 'Laden';
	@override String get deletePreset => 'Verwijderen';
	@override String get presetSaved => 'Voorinstelling opgeslagen';
	@override String get presetLoaded => 'Voorinstelling geladen';
	@override String get presetDeleted => 'Voorinstelling verwijderd';
	@override String get confirmDeletePreset => 'Weet je zeker dat je deze voorinstelling wilt verwijderen?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comment';
}

// Path: dialog
class _Translations$dialog$nl extends Translations$dialog$en {
	_Translations$dialog$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Bevestig actie';
}

// Path: profiles
class _Translations$profiles$nl extends Translations$profiles$en {
	_Translations$profiles$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Plezy-profiel toevoegen';
	@override String get switchingProfile => 'Profiel wisselen…';
	@override String get deleteThisProfileTitle => 'Dit profiel verwijderen?';
	@override String deleteThisProfileMessage({required Object displayName}) => 'Verwijder ${displayName}. Verbindingen blijven ongewijzigd.';
	@override String get active => 'Actief';
	@override String get manage => 'Beheren';
	@override String get delete => 'Verwijderen';
	@override String get signOut => 'Afmelden';
	@override String get signOutPlexTitle => 'Afmelden bij Plex?';
	@override String signOutPlexMessage({required Object displayName}) => '${displayName} en alle Plex Home-gebruikers verwijderen? Je kunt altijd opnieuw inloggen.';
	@override String get signedOutPlex => 'Afgemeld bij Plex.';
	@override String get signOutFailed => 'Afmelden mislukt.';
	@override String get sectionTitle => 'Profielen';
	@override String get summarySingle => 'Voeg profielen toe om beheerde gebruikers en lokale identiteiten te combineren';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} profielen · actief: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} profielen';
	@override String get removeConnectionTitle => 'Verbinding verwijderen?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'Verwijder de toegang van ${displayName} tot ${connectionLabel}. Andere profielen behouden deze toegang.';
	@override String get deleteProfileTitle => 'Profiel verwijderen?';
	@override String deleteProfileMessage({required Object displayName}) => 'Verwijder ${displayName} en de verbindingen. Servers blijven beschikbaar.';
	@override String get profileNameLabel => 'Profielnaam';
	@override String get pinProtectionLabel => 'Pincodebeveiliging';
	@override String get pinManagedByPlex => 'De pincode wordt beheerd door Plex. Pas deze aan op plex.tv.';
	@override String get noPinSetEditOnPlex => 'Geen pincode ingesteld. Bewerk de Plex Home-gebruiker op plex.tv om er een te vereisen.';
	@override String get setPin => 'Pincode instellen';
	@override String get setPinTitle => 'Pincode instellen';
	@override String get confirmPinTitle => 'Pincode bevestigen';
	@override String get pinSet => 'Pincode ingesteld';
	@override String get changePin => 'Wijzigen';
	@override String get removePin => 'Verwijderen';
	@override String get connectionsLabel => 'Verbindingen';
	@override String get add => 'Toevoegen';
	@override String get deleteProfileButton => 'Profiel verwijderen';
	@override String get noConnectionsHint => 'Geen verbindingen — voeg er één toe om dit profiel te gebruiken.';
	@override String get noConnections => 'Geen verbindingen';
	@override String get plexHomeAccount => 'Plex Home-account';
	@override String get connectionDefault => 'Standaard';
	@override String connectionAs({required Object displayName}) => 'als ${displayName}';
	@override String get makeDefault => 'Als standaard instellen';
	@override String get removeConnection => 'Verwijderen';
	@override String get profileRenamed => 'Profiel hernoemd.';
	@override String borrowAddTo({required Object displayName}) => 'Toevoegen aan ${displayName}';
	@override String get borrowExplain => 'Leen de verbinding van een ander profiel. Voor profielen met pincodebeveiliging is een pincode vereist.';
	@override String get borrowEmpty => 'Nog niets te lenen.';
	@override String get borrowEmptySubtitle => 'Verbind Plex of Jellyfin eerst met een ander profiel.';
	@override String get borrowLoadFailed => 'Beschikbare verbindingen konden niet worden geladen. Probeer het opnieuw.';
	@override String borrowFromProfile({required Object displayName}) => 'Van ${displayName}';
	@override String get borrowConnectionBorrowed => 'Verbinding geleend.';
	@override String get borrowFailed => 'Kan verbinding niet lenen.';
	@override String get incorrectPin => 'Onjuiste pincode.';
	@override String get incorrectPinTryAgain => 'Onjuiste pincode. Probeer het opnieuw.';
	@override String get sourceProfileMissingParentAccount => 'Het bovenliggende account van het bronprofiel ontbreekt.';
	@override String get failedToLoadHomeUsers => 'Je Plex Home-gebruikers konden niet worden geladen. Controleer je verbinding en probeer het opnieuw.';
	@override String get failedToVerifyPin => 'De pincode kon niet worden geverifieerd.';
	@override String get newProfile => 'Nieuw profiel';
	@override String get profileNameHint => 'bijv. Gasten, Kinderen, Woonkamer';
	@override String get pinProtectionOptional => 'Pincodebeveiliging (optioneel)';
	@override String get pinExplain => 'Een viercijferige pincode is vereist om van profiel te wisselen.';
	@override String get continueButton => 'Doorgaan';
	@override String get pinsDontMatch => 'De pincodes komen niet overeen';
}

// Path: connections
class _Translations$connections$nl extends Translations$connections$en {
	_Translations$connections$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Verbindingen';
	@override String get addConnection => 'Verbinding toevoegen';
	@override String get addConnectionSubtitleNoProfile => 'Meld je aan met Plex of verbind een Jellyfin-server';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Toevoegen aan ${displayName}: Plex, Jellyfin of een andere profielverbinding';
	@override String sessionExpiredOne({required Object name}) => 'Sessie verlopen voor ${name}';
	@override String sessionExpiredMany({required Object count}) => 'Sessie verlopen voor ${count} servers';
	@override String get signInAgain => 'Opnieuw aanmelden';
	@override String get editJellyfinTitle => 'Jellyfin-verbinding bewerken';
	@override String editJellyfinIntro({required Object serverName}) => 'Voeg URL\'s voor ${serverName} toe of verwijder ze. Plezy gebruikt de bereikbare URL met de laagste latentie.';
}

// Path: discover
class _Translations$discover$nl extends Translations$discover$en {
	_Translations$discover$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ontdekken';
	@override String get noContentAvailable => 'Geen inhoud beschikbaar';
	@override String get addMediaToLibraries => 'Voeg wat media toe aan je bibliotheken';
	@override String get continueWatching => 'Verder kijken';
	@override String continueWatchingIn({required Object library}) => 'Verder kijken in ${library}';
	@override String get nextUp => 'Volgende';
	@override String nextUpIn({required Object library}) => 'Volgende in ${library}';
	@override String get recentlyAdded => 'Recent toegevoegd';
	@override String recentlyAddedIn({required Object library}) => 'Recent toegevoegd in ${library}';
	@override String latestAlbumsIn({required Object library}) => 'Nieuwste albums in ${library}';
	@override String recentlyPlayedIn({required Object library}) => 'Onlangs afgespeeld in ${library}';
	@override String mostPlayedIn({required Object library}) => 'Meest afgespeeld in ${library}';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'Overzicht';
	@override String get cast => 'Acteurs';
	@override String get extras => 'Trailers en extra\'s';
	@override String get studio => 'Studio';
	@override String get rating => 'Beoordeling';
	@override String get movie => 'Film';
	@override String get tvShow => 'Tv-serie';
	@override String minutesLeft({required Object minutes}) => 'nog ${minutes} min';
	@override String get moreLikeThis => 'Meer zoals dit';
}

// Path: errors
class _Translations$errors$nl extends Translations$errors$en {
	_Translations$errors$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Zoeken mislukt: ${error}';
	@override String connectionTimeout({required Object context}) => 'Time-out van verbinding tijdens het laden van ${context}';
	@override String get connectionFailed => 'Kan geen verbinding maken met mediaserver';
	@override String unableToLoad({required Object context}) => 'Kan ${context} niet laden. Probeer het opnieuw.';
	@override String get noClientAvailable => 'Geen client beschikbaar';
	@override String get pleaseEnterToken => 'Voer een token in';
	@override String get invalidToken => 'Ongeldig token';
	@override String failedToVerifyToken({required Object error}) => 'Kon token niet verifiëren: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Kon niet wisselen naar ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'Kon ${displayName} niet verwijderen';
	@override String get failedToRate => 'Beoordeling kon niet worden bijgewerkt';
}

// Path: libraries
class _Translations$libraries$nl extends Translations$libraries$en {
	_Translations$libraries$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bibliotheken';
	@override String get fallbackTitle => 'Bibliotheek';
	@override String get scanLibraryFiles => 'Bibliotheekbestanden scannen';
	@override String get scanLibrary => 'Bibliotheek scannen';
	@override String get analyze => 'Analyseren';
	@override String get analyzeLibrary => 'Bibliotheek analyseren';
	@override String get refreshMetadata => 'Metadata vernieuwen';
	@override String get emptyTrash => 'Prullenbak legen';
	@override String emptyingTrash({required Object title}) => 'Prullenbak legen voor "${title}"...';
	@override String trashEmptied({required Object title}) => 'Prullenbak geleegd voor "${title}"';
	@override String failedToEmptyTrash({required Object error}) => 'Kon prullenbak niet legen: ${error}';
	@override String analyzing({required Object title}) => 'Analyseren "${title}"...';
	@override String analysisStarted({required Object title}) => 'Analyse gestart voor "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Kon bibliotheek niet analyseren: ${error}';
	@override String get noLibrariesFound => 'Geen bibliotheken gevonden';
	@override String get allLibrariesHidden => 'Alle bibliotheken zijn verborgen';
	@override String hiddenLibrariesCount({required Object count}) => 'Verborgen bibliotheken (${count})';
	@override String get thisLibraryIsEmpty => 'Deze bibliotheek is leeg';
	@override String get noItemsMatchFilters => 'Geen items komen overeen met de actieve filters';
	@override String get resetFilters => 'Filters opnieuw instellen';
	@override String get all => 'Alles';
	@override String get clearAll => 'Alles wissen';
	@override String scanLibraryConfirm({required Object title}) => 'Weet je zeker dat je "${title}" wilt scannen?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Weet je zeker dat je "${title}" wilt analyseren?';
	@override String refreshMetadataConfirm({required Object title}) => 'Weet je zeker dat je metadata wilt vernieuwen voor "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Weet je zeker dat je de prullenbak wilt legen voor "${title}"?';
	@override String get manageLibraries => 'Bibliotheken beheren';
	@override String get sort => 'Sorteren';
	@override String get sortBy => 'Sorteer op';
	@override String get filters => 'Filters';
	@override String get confirmActionMessage => 'Weet je zeker dat je deze actie wilt uitvoeren?';
	@override String get showLibrary => 'Bibliotheek tonen';
	@override String get hideLibrary => 'Bibliotheek verbergen';
	@override String get libraryOptions => 'Bibliotheekopties';
	@override String get content => 'bibliotheekinhoud';
	@override String get selectLibrary => 'Bibliotheek kiezen';
	@override String filtersWithCount({required Object count}) => 'Filters (${count})';
	@override String get noRecommendations => 'Geen aanbevelingen beschikbaar';
	@override String get noCollections => 'Geen collecties in deze bibliotheek';
	@override String get noFoldersFound => 'Geen mappen gevonden';
	@override String get folders => 'mappen';
	@override late final _Translations$libraries$tabs$nl tabs = _Translations$libraries$tabs$nl._(_root);
	@override late final _Translations$libraries$groupings$nl groupings = _Translations$libraries$groupings$nl._(_root);
	@override late final _Translations$libraries$filterCategories$nl filterCategories = _Translations$libraries$filterCategories$nl._(_root);
	@override late final _Translations$libraries$sortLabels$nl sortLabels = _Translations$libraries$sortLabels$nl._(_root);
}

// Path: about
class _Translations$about$nl extends Translations$about$en {
	_Translations$about$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Over';
	@override String get openSourceLicenses => 'Opensourcelicenties';
	@override String versionLabel({required Object version}) => 'Versie ${version}';
	@override String get appDescription => 'Een mooie Plex- en Jellyfin-client voor Flutter';
	@override String get viewLicensesDescription => 'Licenties van bibliotheken van derden bekijken';
}

// Path: serverSelection
class _Translations$serverSelection$nl extends Translations$serverSelection$en {
	_Translations$serverSelection$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Geen servers gevonden voor ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Kon servers niet laden: ${error}';
}

// Path: hubDetail
class _Translations$hubDetail$nl extends Translations$hubDetail$en {
	_Translations$hubDetail$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titel';
	@override String get releaseYear => 'Uitgavejaar';
	@override String get dateAdded => 'Datum toegevoegd';
	@override String get rating => 'Beoordeling';
	@override String get noItemsFound => 'Geen items gevonden';
}

// Path: logs
class _Translations$logs$nl extends Translations$logs$en {
	_Translations$logs$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Logbestanden wissen';
	@override String get copyLogs => 'Logbestanden kopiëren';
	@override String get uploadLogs => 'Logbestanden uploaden';
}

// Path: licenses
class _Translations$licenses$nl extends Translations$licenses$en {
	_Translations$licenses$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Gerelateerde pakketten';
	@override String get license => 'Licentie';
	@override String licenseNumber({required Object number}) => 'Licentie ${number}';
	@override String licensesCount({required Object count}) => '${count} licenties';
}

// Path: navigation
class _Translations$navigation$nl extends Translations$navigation$en {
	_Translations$navigation$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Media';
	@override String get downloads => 'Downloads';
	@override String get liveTv => 'Live-tv';
	@override String get explore => 'Verkennen';
}

// Path: explore
class _Translations$explore$nl extends Translations$explore$en {
	_Translations$explore$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Verkennen';
	@override String get selectSource => 'Bron kiezen';
	@override late final _Translations$explore$rows$nl rows = _Translations$explore$rows$nl._(_root);
	@override late final _Translations$explore$status$nl status = _Translations$explore$status$nl._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nl'))(n,
		one: '${n} aflevering',
		other: '${n} afleveringen',
	);
	@override String get cast => 'Acteurs';
	@override String get characters => 'Personages';
	@override String get addToWatchlist => 'Toevoegen aan kijklijst';
	@override String get removeFromWatchlist => 'Verwijderen uit kijklijst';
	@override String get watchlistUpdateFailed => 'Kon kijklijst niet bijwerken';
	@override String get notInLibrary => 'Niet in je bibliotheek';
	@override String get inTheseLibraries => 'In deze bibliotheken';
	@override String get checkingLibrary => 'Je bibliotheek controleren...';
	@override String get emptyTitle => 'Hier is nog niets';
	@override String emptyMessage({required Object source}) => 'Rijen van ${source} verschijnen hier zodra ze inhoud hebben.';
	@override String searchHint({required Object source}) => 'Zoeken in ${source}';
	@override String searchEmpty({required Object query}) => 'Geen resultaten voor "${query}"';
	@override String searchPrompt({required Object source}) => 'Zoek naar films en series op ${source}.';
	@override String get searchFailed => 'Zoeken mislukt. Controleer je verbinding en probeer opnieuw.';
}

// Path: liveTv
class _Translations$liveTv$nl extends Translations$liveTv$en {
	_Translations$liveTv$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Live-tv';
	@override String get guide => 'Gids';
	@override String get noChannels => 'Geen zenders beschikbaar';
	@override String get noDvr => 'Geen DVR geconfigureerd op een server';
	@override String get serverUnavailable => 'De live-tv-server is niet beschikbaar.';
	@override String get serverNotConnected => 'De live-tv-server is niet verbonden.';
	@override String get noPrograms => 'Geen programmagegevens beschikbaar';
	@override String get liveStreamFailed => 'Livestream mislukt';
	@override String get unknownProgram => 'Onbekend programma';
	@override String get unknownHub => 'Onbekend';
	@override String get unknownError => 'Onbekende fout';
	@override String channelNumber({required Object number}) => 'Kanaal ${number}';
	@override String get unknownChannel => 'Onbekend kanaal';
	@override String get live => 'LIVE';
	@override String get reloadGuide => 'Gids herladen';
	@override String get now => 'Nu';
	@override String get today => 'Vandaag';
	@override String get tomorrow => 'Morgen';
	@override String get midnight => 'Middernacht';
	@override String get overnight => 'Nacht';
	@override String get morning => 'Ochtend';
	@override String get daytime => 'Overdag';
	@override String get evening => 'Avond';
	@override String get lateNight => 'Late avond';
	@override String get whatsOn => 'Nu op tv';
	@override String get watchChannel => 'Kanaal bekijken';
	@override String get favorites => 'Favorieten';
	@override String get reorderFavorites => 'Favorieten herordenen';
	@override String get favoritesLoadFailed => 'Favorieten konden niet worden geladen. Controleer je verbinding en probeer het opnieuw.';
	@override String get favoritesUpdateFailed => 'Favorieten konden niet worden bijgewerkt. Controleer je verbinding en probeer het opnieuw.';
	@override String get joinSession => 'Deelnemen aan lopende sessie';
	@override String watchFromStart({required Object minutes}) => 'Vanaf het begin kijken (${minutes} min geleden)';
	@override String get watchLive => 'Live kijken';
	@override String get goToLive => 'Naar live-uitzending';
	@override String get record => 'Opnemen';
	@override String get recordEpisode => 'Aflevering opnemen';
	@override String get recordSeries => 'Serie opnemen';
	@override String get recordOptions => 'Opnameopties';
	@override String get saveTo => 'Opslaan in';
	@override String get recordings => 'Opnames';
	@override String get scheduledRecordings => 'Gepland';
	@override String get recordingRules => 'Opnameregels';
	@override String get noScheduledRecordings => 'Geen geplande opnames';
	@override String get manageRecording => 'Opname beheren';
	@override String get cancelRecording => 'Opname annuleren';
	@override String get cancelRecordingTitle => 'Deze opname annuleren?';
	@override String cancelRecordingMessage({required Object title}) => '${title} wordt niet meer opgenomen.';
	@override String get deleteRule => 'Regel verwijderen';
	@override String get deleteRuleTitle => 'Opnameregel verwijderen?';
	@override String deleteRuleMessage({required Object title}) => 'Toekomstige afleveringen van ${title} worden niet opgenomen.';
	@override String get recordingScheduled => 'Opname gepland';
	@override String get alreadyScheduled => 'Dit programma is al gepland';
	@override String get dvrAdminRequired => 'DVR-instellingen vereisen een beheerdersaccount';
	@override String get recordingFailed => 'Kon opname niet plannen';
	@override String get recordingTargetMissing => 'Kon opnamebibliotheek niet bepalen';
	@override String get recordNotAvailable => 'Opname niet beschikbaar voor dit programma';
	@override String get recordingCancelled => 'Opname geannuleerd';
	@override String get recordingRuleDeleted => 'Opnameregel verwijderd';
	@override String get processRecordingRules => 'Regels opnieuw evalueren';
	@override String get recordingInProgress => 'Nu aan het opnemen';
	@override String recordingsCount({required Object count}) => '${count} gepland';
	@override String get editRule => 'Regel bewerken';
	@override String get editRuleAction => 'Bewerken';
	@override String get recordingRuleUpdated => 'Opnameregel bijgewerkt';
	@override String get guideReloadRequested => 'Vernieuwing van de gids aangevraagd';
	@override String get rulesProcessRequested => 'Nieuwe evaluatie van regels aangevraagd';
	@override String get recordShow => 'Programma opnemen';
}

// Path: collections
class _Translations$collections$nl extends Translations$collections$en {
	_Translations$collections$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Collecties';
	@override String get collection => 'Collectie';
	@override String get empty => 'Collectie is leeg';
	@override String get deleteCollection => 'Collectie verwijderen';
	@override String deleteConfirm({required Object title}) => '"${title}" verwijderen? Dit kan niet ongedaan worden gemaakt.';
	@override String get deleted => 'Collectie verwijderd';
	@override String get deleteFailed => 'Collectie verwijderen mislukt';
	@override String deleteFailedWithError({required Object error}) => 'Collectie verwijderen mislukt: ${error}';
	@override String get selectCollection => 'Collectie selecteren';
	@override String get collectionName => 'Collectienaam';
	@override String get enterCollectionName => 'Voer een collectienaam in';
	@override String get addedToCollection => 'Toegevoegd aan collectie';
	@override String get errorAddingToCollection => 'Fout bij toevoegen aan collectie';
	@override String get created => 'Collectie gemaakt';
	@override String get removeFromCollection => 'Verwijderen uit collectie';
	@override String removeFromCollectionConfirm({required Object title}) => '"${title}" uit deze collectie verwijderen?';
	@override String get removedFromCollection => 'Uit collectie verwijderd';
	@override String get removeFromCollectionFailed => 'Verwijderen uit collectie mislukt';
	@override String removeFromCollectionError({required Object error}) => 'Fout bij verwijderen uit collectie: ${error}';
	@override String get searchCollections => 'Collecties zoeken...';
}

// Path: playlists
class _Translations$playlists$nl extends Translations$playlists$en {
	_Translations$playlists$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Afspeellijsten';
	@override String get playlist => 'Afspeellijst';
	@override String get noPlaylists => 'Geen afspeellijsten gevonden';
	@override String get create => 'Afspeellijst maken';
	@override String get playlistName => 'Naam van de afspeellijst';
	@override String get enterPlaylistName => 'Voer een naam voor de afspeellijst in';
	@override String get delete => 'Afspeellijst verwijderen';
	@override String get removeItem => 'Verwijderen uit afspeellijst';
	@override String get smartPlaylist => 'Slimme afspeellijst';
	@override String itemCount({required Object count}) => '${count} items';
	@override String get oneItem => '1 item';
	@override String get emptyPlaylist => 'Deze afspeellijst is leeg';
	@override String get deleteConfirm => 'Afspeellijst verwijderen?';
	@override String deleteMessage({required Object name}) => 'Weet je zeker dat je "${name}" wilt verwijderen?';
	@override String get created => 'Afspeellijst gemaakt';
	@override String get deleted => 'Afspeellijst verwijderd';
	@override String get itemAdded => 'Toegevoegd aan afspeellijst';
	@override String get itemRemoved => 'Verwijderd uit afspeellijst';
	@override String get selectPlaylist => 'Afspeellijst selecteren';
	@override String get searchPlaylists => 'Afspeellijsten zoeken...';
	@override String get errorCreating => 'Afspeellijst maken mislukt';
	@override String get errorDeleting => 'Afspeellijst verwijderen mislukt';
	@override String get errorLoading => 'Afspeellijsten laden mislukt';
	@override String get errorAdding => 'Toevoegen aan afspeellijst mislukt';
	@override String get errorReordering => 'Afspeellijstitem herschikken mislukt';
	@override String get errorRemoving => 'Verwijderen uit afspeellijst mislukt';
}

// Path: music
class _Translations$music$nl extends Translations$music$en {
	_Translations$music$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Ga naar album';
	@override String get goToArtist => 'Ga naar artiest';
	@override String get instantMix => 'Instantmix';
	@override String get playNext => 'Hierna afspelen';
	@override String get addToQueue => 'Toevoegen aan wachtrij';
	@override String discNumber({required Object n}) => 'Schijf ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nl'))(n,
		one: '${n} nummer',
		other: '${n} nummers',
	);
	@override String get nowPlaying => 'Nu afspelen';
	@override String playingFrom({required Object title}) => 'Afspelen vanaf ${title}';
	@override String get queue => 'Wachtrij';
	@override String get clearQueue => 'Wachtrij wissen';
	@override String get lyrics => 'Songtekst';
	@override String get noLyrics => 'Geen songtekst beschikbaar';
	@override String get sleepTimer => 'Slaaptimer';
	@override String get sleepTimerEndOfTrack => 'Einde van nummer';
	@override String sleepTimerMinutes({required Object n}) => '${n} minuten';
	@override String get stopPlayback => 'Afspelen stoppen';
	@override String get previousTrack => 'Vorig nummer';
	@override String get nextTrack => 'Volgend nummer';
	@override String get repeat => 'Herhalen';
	@override String get repeatAll => 'Alles herhalen';
	@override String get repeatOne => 'Eén herhalen';
}

// Path: watchTogether
class _Translations$watchTogether$nl extends Translations$watchTogether$en {
	_Translations$watchTogether$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Samen kijken';
	@override String get description => 'Kijk synchroon met vrienden en familie';
	@override String get createSession => 'Sessie maken';
	@override String get creating => 'Sessie maken...';
	@override String get joinSession => 'Deelnemen aan sessie';
	@override String get joining => 'Deelnemen...';
	@override String get controlMode => 'Bedieningsmodus';
	@override String get controlModeQuestion => 'Wie kan het afspelen bedienen?';
	@override String get hostOnly => 'Alleen host';
	@override String get anyone => 'Iedereen';
	@override String get hostingSession => 'Sessie hosten';
	@override String get inSession => 'In sessie';
	@override String get sessionCode => 'Sessiecode';
	@override String get openSessionControls => 'Bediening voor Samen kijken openen';
	@override String get copySessionCode => 'Sessiecode kopiëren';
	@override String get hostControlsPlayback => 'Host bedient het afspelen';
	@override String get anyoneCanControl => 'Iedereen kan het afspelen bedienen';
	@override String get hostControls => 'Host bedient';
	@override String get anyoneControls => 'Iedereen bedient';
	@override String get participants => 'Deelnemers';
	@override String get host => 'Host';
	@override String get hostBadge => 'HOST';
	@override String get youAreHost => 'Jij bent de host';
	@override String get watchingWithOthers => 'Kijken met anderen';
	@override String get endSession => 'Sessie beëindigen';
	@override String get leaveSession => 'Sessie verlaten';
	@override String get endSessionQuestion => 'Sessie beëindigen?';
	@override String get leaveSessionQuestion => 'Sessie verlaten?';
	@override String get endSessionConfirm => 'Dit beëindigt de sessie voor alle deelnemers.';
	@override String get leaveSessionConfirm => 'Je wordt uit de sessie verwijderd.';
	@override String get endSessionConfirmOverlay => 'Dit beëindigt de kijksessie voor alle deelnemers.';
	@override String get leaveSessionConfirmOverlay => 'Je wordt losgekoppeld van de kijksessie.';
	@override String get end => 'Beëindigen';
	@override String get leave => 'Verlaten';
	@override String get syncing => 'Synchroniseren...';
	@override String get joinWatchSession => 'Deelnemen aan kijksessie';
	@override String get enterCodeHint => 'Voer de code van 5 tekens in';
	@override String get pasteFromClipboard => 'Plakken vanaf klembord';
	@override String get pleaseEnterCode => 'Voer een sessiecode in';
	@override String get codeMustBe5Chars => 'De sessiecode moet 5 tekens lang zijn';
	@override String get joinInstructions => 'Voer de sessiecode van de host in om deel te nemen.';
	@override String get failedToCreate => 'Sessie maken mislukt';
	@override String get failedToJoin => 'Deelnemen aan sessie mislukt';
	@override String get sessionCodeCopied => 'Sessiecode naar het klembord gekopieerd';
	@override String get relayUnreachable => 'De relayserver is onbereikbaar. Een blokkering door je internetprovider kan Samen kijken verhinderen.';
	@override String get reconnectingToHost => 'Opnieuw verbinden met host...';
	@override String get currentPlayback => 'Wat nu wordt afgespeeld';
	@override String get joinCurrentPlayback => 'Deelnemen aan huidige weergave';
	@override String get joinCurrentPlaybackDescription => 'Ga terug naar wat de host nu kijkt';
	@override String get failedToOpenCurrentPlayback => 'Wat nu wordt afgespeeld kon niet worden geopend';
	@override String participantJoined({required Object name}) => '${name} is toegetreden';
	@override String participantLeft({required Object name}) => '${name} heeft de sessie verlaten';
	@override String participantPaused({required Object name}) => '${name} heeft gepauzeerd';
	@override String participantResumed({required Object name}) => '${name} heeft hervat';
	@override String participantSeeked({required Object name}) => '${name} heeft de afspeelpositie gewijzigd';
	@override String participantBuffering({required Object name}) => '${name} is aan het bufferen';
	@override String participantNeedsUpdate({required Object name}) => '${name} gebruikt een oudere appversie — synchronisatie niet beschikbaar';
	@override String resumingWithout({required Object name}) => 'Hervatten zonder ${name}';
	@override String get waitingForParticipants => 'Wachten tot anderen klaar zijn met laden...';
	@override String waitingForName({required Object name}) => 'Wachten op ${name}...';
	@override String get recentRooms => 'Recente kamers';
	@override String get renameRoom => 'Kamer hernoemen';
	@override String get removeRoom => 'Verwijderen';
	@override String get guestSwitchUnavailable => 'Kon niet schakelen — server niet beschikbaar voor synchronisatie';
	@override String get guestSwitchFailed => 'Kon niet schakelen — inhoud niet gevonden op deze server';
}

// Path: downloads
class _Translations$downloads$nl extends Translations$downloads$en {
	_Translations$downloads$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Downloads';
	@override String get manage => 'Beheren';
	@override String get tvShows => 'Series';
	@override String get movies => 'Films';
	@override String get music => 'Muziek';
	@override String tracksQueued({required Object count}) => '${count} nummers in wachtrij voor download';
	@override String get noDownloads => 'Nog geen downloads';
	@override String get noDownloadsDescription => 'Gedownloade inhoud verschijnt hier om offline te bekijken';
	@override String get downloadNow => 'Downloaden';
	@override String get deleteDownload => 'Download verwijderen';
	@override String get retryDownload => 'Download opnieuw proberen';
	@override String get downloadQueued => 'Download in wachtrij';
	@override String get downloadResumed => 'Download hervat';
	@override String get serverErrorBitrate => 'Serverfout: bestand overschrijdt mogelijk de externe bitrate-limiet';
	@override String get storageFull => 'Downloads zijn gestopt omdat de opslag van het apparaat vol is. Maak ruimte vrij en probeer het opnieuw.';
	@override String episodesQueued({required Object count}) => '${count} afleveringen in wachtrij voor download';
	@override String get downloadDeleted => 'Download verwijderd';
	@override String deleteConfirm({required Object title}) => '"${title}" van dit apparaat verwijderen?';
	@override String get cancelledDownloadTitle => 'Geannuleerde download';
	@override String get cancelledDownloadMessage => 'Deze download is geannuleerd. Wat wil je doen?';
	@override String get allEpisodesAlreadyDownloaded => 'Alle afleveringen zijn al gedownload';
	@override String get resumeDownload => 'Download hervatten';
	@override String get cancelledDownload => 'Geannuleerde download';
	@override String syncingFile({required Object file, required Object status}) => '${file} (${status} synchroniseren)';
	@override String downloadedFileClickToComplete({required Object file}) => '${file} gedownload — klik om te voltooien';
	@override String get partialDownloadClickToComplete => 'Gedeeltelijk gedownload — klik om te voltooien';
	@override String get deleting => 'Verwijderen...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Verwijderen van ${title}... (${current} van ${total})';
	@override String get queuedTooltip => 'In wachtrij';
	@override String queuedFilesTooltip({required Object files}) => 'In wachtrij: ${files}';
	@override String get downloadingTooltip => 'Downloaden...';
	@override String downloadingFilesTooltip({required Object files}) => 'Downloaden ${files}';
	@override String get noDownloadsTree => 'Geen downloads';
	@override String get pauseAll => 'Alles pauzeren';
	@override String get resumeAll => 'Alles hervatten';
	@override String get deleteAll => 'Alles verwijderen';
	@override String get selectVersion => 'Versie selecteren';
	@override String get allEpisodes => 'Alle afleveringen';
	@override String get unwatchedOnly => 'Alleen ongekeken afleveringen';
	@override String nextNUnwatched({required Object count}) => 'Volgende ${count} ongekeken afleveringen';
	@override String get customAmount => 'Aangepast aantal...';
	@override String get includeSpecials => 'Specials meenemen';
	@override String get howManyEpisodes => 'Hoeveel afleveringen?';
	@override String get invalidEpisodeCount => 'Voer een geldig aantal afleveringen in.';
	@override String get keepSynced => 'Gesynchroniseerd houden';
	@override String get downloadOnce => 'Eenmalig downloaden';
	@override String keepNUnwatched({required Object count}) => '${count} ongekeken afleveringen behouden';
	@override String get editSyncRule => 'Synchronisatieregel bewerken';
	@override String get removeSyncRule => 'Synchronisatieregel verwijderen';
	@override String removeSyncRuleConfirm({required Object title}) => 'Synchronisatie van "${title}" stoppen? Gedownloade afleveringen worden behouden.';
	@override String syncRuleCreated({required Object count}) => 'Synchronisatieregel aangemaakt — ${count} onbekeken afleveringen behouden';
	@override String get syncRuleUpdated => 'Synchronisatieregel bijgewerkt';
	@override String get syncRuleRemoved => 'Synchronisatieregel verwijderd';
	@override String syncedNewEpisodes({required Object count, required Object title}) => '${count} nieuwe afleveringen gesynchroniseerd voor ${title}';
	@override String get activeSyncRules => 'Synchronisatieregels';
	@override String get noSyncRules => 'Geen synchronisatieregels';
	@override String get manageSyncRule => 'Synchronisatie beheren';
	@override String get editEpisodeCount => 'Aantal afleveringen';
	@override String get editSyncFilter => 'Synchronisatiefilter';
	@override String get syncAllItems => 'Alle items synchroniseren';
	@override String get syncUnwatchedItems => 'Ongekeken items synchroniseren';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Server: ${server} • ${status}';
	@override String get syncRuleAvailable => 'Beschikbaar';
	@override String get syncRuleOffline => 'Offline';
	@override String get syncRuleSignInRequired => 'Inloggen vereist';
	@override String get syncRuleNotAvailableForProfile => 'Niet beschikbaar voor huidig profiel';
	@override String get syncRuleUnknownServer => 'Onbekende server';
	@override String get syncRuleListCreated => 'Synchronisatieregel aangemaakt';
}

// Path: shaders
class _Translations$shaders$nl extends Translations$shaders$en {
	_Translations$shaders$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shaders';
	@override String get noShaderDescription => 'Geen videoverbetering';
	@override String get nvscalerDescription => 'NVIDIA-beeldschaling voor scherpere video';
	@override String get artcnnVariantNeutral => 'Neutraal';
	@override String get artcnnVariantDenoise => 'Ruisonderdrukking';
	@override String get artcnnVariantDenoiseSharpen => 'Ruisonderdrukking + verscherpen';
	@override String get qualityFast => 'Snel';
	@override String get qualityHQ => 'Hoge kwaliteit';
	@override String get mode => 'Modus';
	@override String get importShader => 'Shader importeren';
	@override String get customShaderDescription => 'Aangepaste GLSL-shader';
	@override String get shaderImported => 'Shader geïmporteerd';
	@override String get shaderImportFailed => 'Shader importeren mislukt';
	@override String get deleteShader => 'Shader verwijderen';
	@override String deleteShaderConfirm({required Object name}) => '"${name}" verwijderen?';
}

// Path: companionRemote
class _Translations$companionRemote$nl extends Translations$companionRemote$en {
	_Translations$companionRemote$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Afstandsbediening';
	@override String connectedTo({required Object name}) => 'Verbonden met ${name}';
	@override String get unknownDevice => 'Onbekend apparaat';
	@override late final _Translations$companionRemote$session$nl session = _Translations$companionRemote$session$nl._(_root);
	@override late final _Translations$companionRemote$pairing$nl pairing = _Translations$companionRemote$pairing$nl._(_root);
	@override late final _Translations$companionRemote$remote$nl remote = _Translations$companionRemote$remote$nl._(_root);
	@override late final _Translations$companionRemote$errors$nl errors = _Translations$companionRemote$errors$nl._(_root);
}

// Path: videoSettings
class _Translations$videoSettings$nl extends Translations$videoSettings$en {
	_Translations$videoSettings$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Afspeelsnelheid';
	@override String get normalSpeed => 'Normaal';
	@override String sleepTimerActive({required Object duration}) => 'Actief (${duration})';
	@override String get zoom => 'Zoom';
	@override String get sleepTimer => 'Slaaptimer';
	@override String get audioSync => 'Audiosynchronisatie';
	@override String get subtitleSync => 'Ondertitelsynchronisatie';
	@override String get hdr => 'HDR';
	@override String get audioOutput => 'Audio-uitvoer';
	@override String get performanceOverlay => 'Prestatie-overlay';
	@override String get audioPassthrough => 'Audio-doorvoer';
	@override String get audioNormalization => 'Volume normaliseren';
	@override String get audioDownmix => 'Downmixen naar stereo';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$nl extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get color => 'Kleur';
	@override String get performance => 'Prestaties';
	@override String get buffer => 'Buffer';
	@override String get app => 'App';
	@override String get decoder => 'Decoder';
	@override String get rawDecoder => 'Raw-decoder';
	@override String get tunneling => 'Tunneling';
	@override String get aspect => 'Verhouding';
	@override String get rotation => 'Rotatie';
	@override String get dvSource => 'DV-bron';
	@override String get dvPath => 'DV-pad';
	@override String get p7Conversion => 'P7-conv.';
	@override String get sampleRate => 'Samplefrequentie';
	@override String get pixelFormat => 'Pixelformaat';
	@override String get hwFormat => 'HW-formaat';
	@override String get matrix => 'Matrix';
	@override String get primaries => 'Primaire kleuren';
	@override String get transfer => 'Overdracht';
	@override String get renderFps => 'Render-FPS';
	@override String get displayFps => 'Scherm-FPS';
	@override String get avSync => 'A/V-sync';
	@override String get dropped => 'Gedropt';
	@override String get dvRpus => 'DV RPU’s';
	@override String get dvRpuAverage => 'DV RPU gem.';
	@override String get dvSampleAverage => 'DV-sample gem.';
	@override String get maxLuma => 'Max luma';
	@override String get minLuma => 'Min luma';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Cache gebruikt';
	@override String get cacheLimit => 'Cachelimiet';
	@override String get speed => 'Snelheid';
	@override String get player => 'Speler';
	@override String get memory => 'Geheugen';
	@override String get uiFps => 'UI FPS';
}

// Path: externalPlayer
class _Translations$externalPlayer$nl extends Translations$externalPlayer$en {
	_Translations$externalPlayer$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Externe speler';
	@override String get useExternalPlayer => 'Externe speler gebruiken';
	@override String get useExternalPlayerDescription => 'Open video\'s in een andere app';
	@override String get selectPlayer => 'Speler selecteren';
	@override String get customPlayers => 'Aangepaste spelers';
	@override String get systemDefault => 'Systeemstandaard';
	@override String get addCustomPlayer => 'Aangepaste speler toevoegen';
	@override String get playerName => 'Spelernaam';
	@override String get playerNameHint => 'Mijn speler';
	@override String get playerCommand => 'Commando';
	@override String get playerPackage => 'Pakketnaam';
	@override String get playerUrlScheme => 'URL-schema';
	@override String get off => 'Uit';
	@override String get launchFailed => 'Kan externe speler niet openen';
	@override String appNotInstalled({required Object name}) => '${name} is niet geïnstalleerd';
	@override String get playInExternalPlayer => 'Afspelen in externe speler';
}

// Path: metadataEdit
class _Translations$metadataEdit$nl extends Translations$metadataEdit$en {
	_Translations$metadataEdit$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Bewerken...';
	@override String get screenTitle => 'Metadata bewerken';
	@override String get basicInfo => 'Basisinformatie';
	@override String get artwork => 'Illustraties';
	@override String get advancedSettings => 'Geavanceerde instellingen';
	@override String get title => 'Titel';
	@override String get sortTitle => 'Sorteertitel';
	@override String get originalTitle => 'Oorspronkelijke titel';
	@override String get releaseDate => 'Releasedatum';
	@override String get contentRating => 'Leeftijdsclassificatie';
	@override String get studio => 'Studio';
	@override String get tagline => 'Slogan';
	@override String get summary => 'Samenvatting';
	@override String get poster => 'Poster';
	@override String get background => 'Achtergrond';
	@override String get logo => 'Logo';
	@override String get squareArt => 'Vierkante afbeelding';
	@override String get selectPoster => 'Poster selecteren';
	@override String get selectBackground => 'Achtergrond selecteren';
	@override String get selectLogo => 'Logo selecteren';
	@override String get selectSquareArt => 'Vierkante afbeelding selecteren';
	@override String get fromUrl => 'Vanaf URL';
	@override String get uploadFile => 'Bestand uploaden';
	@override String get enterImageUrl => 'Voer de afbeeldings-URL in';
	@override String get imageUrl => 'Afbeeldings-URL';
	@override String get metadataUpdated => 'Metadata bijgewerkt';
	@override String get metadataUpdateFailed => 'Metadata bijwerken mislukt';
	@override String get artworkUpdated => 'Illustraties bijgewerkt';
	@override String get artworkUpdateFailed => 'Illustraties bijwerken mislukt';
	@override String get noArtworkAvailable => 'Geen illustraties beschikbaar';
	@override String artworkOption({required Object index}) => 'Illustratie ${index}';
	@override String selectedArtworkOption({required Object index}) => 'Illustratie ${index}, geselecteerd';
	@override String get notSet => 'Niet ingesteld';
	@override String get libraryDefault => 'Standaard van de bibliotheek';
	@override String get accountDefault => 'Standaard van het account';
	@override String get seriesDefault => 'Standaard van de serie';
	@override String get episodeSorting => 'Afleveringen sorteren';
	@override String get oldestFirst => 'Oudste eerst';
	@override String get newestFirst => 'Nieuwste eerst';
	@override String get keep => 'Bewaren';
	@override String get allEpisodes => 'Alle afleveringen';
	@override String latestEpisodes({required Object count}) => '${count} nieuwste afleveringen';
	@override String get latestEpisode => 'Nieuwste aflevering';
	@override String episodesAddedPastDays({required Object count}) => 'Afleveringen toegevoegd in de afgelopen ${count} dagen';
	@override String get deleteAfterPlaying => 'Afleveringen verwijderen na afspelen';
	@override String get never => 'Nooit';
	@override String get afterADay => 'Na een dag';
	@override String get afterAWeek => 'Na een week';
	@override String get afterAMonth => 'Na een maand';
	@override String get onNextRefresh => 'Bij volgende verversing';
	@override String get seasons => 'Seizoenen';
	@override String get show => 'Tonen';
	@override String get hide => 'Verbergen';
	@override String get episodeOrdering => 'Afleveringsvolgorde';
	@override String get tmdbAiring => 'The Movie Database (Uitgezonden)';
	@override String get tvdbAiring => 'TheTVDB (Uitgezonden)';
	@override String get tvdbAbsolute => 'TheTVDB (Absoluut)';
	@override String get metadataLanguage => 'Metadatataal';
	@override String get useOriginalTitle => 'Oorspronkelijke titel gebruiken';
	@override String get preferredAudioLanguage => 'Voorkeurstaal voor audio';
	@override String get preferredSubtitleLanguage => 'Voorkeurstaal voor ondertitels';
	@override String get subtitleMode => 'Automatische ondertitelselectie';
	@override String get manuallySelected => 'Handmatig geselecteerd';
	@override String get shownWithForeignAudio => 'Weergeven bij anderstalig geluid';
	@override String get alwaysEnabled => 'Altijd ingeschakeld';
	@override String get tags => 'Tags';
	@override String get addTag => 'Tag toevoegen';
	@override String get genre => 'Genre';
	@override String get director => 'Regisseur';
	@override String get writer => 'Schrijver';
	@override String get producer => 'Producent';
	@override String get country => 'Land';
	@override String get collection => 'Collectie';
	@override String get label => 'Label';
	@override String get style => 'Stijl';
	@override String get mood => 'Stemming';
}

// Path: matchScreen
class _Translations$matchScreen$nl extends Translations$matchScreen$en {
	_Translations$matchScreen$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get match => 'Koppelen...';
	@override String get fixMatch => 'Koppeling herstellen...';
	@override String get unmatch => 'Ontkoppelen';
	@override String get unmatchConfirm => 'Deze koppeling wissen? Plex behandelt het item als niet-gekoppeld totdat het opnieuw wordt gekoppeld.';
	@override String get unmatchSuccess => 'Item ontkoppeld';
	@override String get unmatchFailed => 'Kon item niet ontkoppelen';
	@override String get matchApplied => 'Koppeling toegepast';
	@override String get matchFailed => 'Koppeling kon niet worden toegepast';
	@override String get titleHint => 'Titel';
	@override String get yearHint => 'Jaar';
	@override String get search => 'Zoeken';
	@override String get noMatchesFound => 'Geen overeenkomsten gevonden';
}

// Path: serverTasks
class _Translations$serverTasks$nl extends Translations$serverTasks$en {
	_Translations$serverTasks$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Servertaken';
	@override String get failedToLoad => 'Taken konden niet worden geladen';
	@override String get noTasks => 'Geen actieve taken';
}

// Path: trakt
class _Translations$trakt$nl extends Translations$trakt$en {
	_Translations$trakt$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Verbonden';
	@override String connectedAs({required Object username}) => 'Verbonden als @${username}';
	@override String get disconnectConfirm => 'Trakt-account loskoppelen?';
	@override String get disconnectConfirmBody => 'Plezy stuurt geen gebeurtenissen meer naar Trakt. Je kunt op elk moment opnieuw verbinding maken.';
	@override String get scrobble => 'Realtime scrobblen';
	@override String get scrobbleDescription => 'Stuur tijdens het afspelen gebeurtenissen voor afspelen, pauzeren en stoppen naar Trakt.';
	@override String get watchedSync => 'Kijkstatus synchroniseren';
	@override String get watchedSyncDescription => 'Wanneer je items in Plezy als bekeken markeert, worden ze op Trakt ook als bekeken gemarkeerd.';
}

// Path: seerr
class _Translations$seerr$nl extends Translations$seerr$en {
	_Translations$seerr$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Verbinden met Seerr';
	@override String get serverUrl => 'Server-URL';
	@override String get serverUrlHelper => 'Het adres van je Seerr-instantie';
	@override String get checkServer => 'Doorgaan';
	@override String get signInWithJellyfin => 'Inloggen met Jellyfin';
	@override String get signInWithEmby => 'Inloggen met Emby';
	@override String get signInWithLocal => 'Een lokaal account gebruiken';
	@override String get email => 'E-mail';
	@override String get noSignInMethods => 'Deze Seerr-instantie biedt geen inlogmethode die Plezy ondersteunt.';
	@override String get instance => 'Instantie';
	@override String get disconnectConfirm => 'Seerr loskoppelen?';
	@override String get disconnectConfirmBody => 'Plezy vergeet deze Seerr-instantie. Je kunt altijd opnieuw verbinden.';
	@override String get request => 'Aanvragen';
	@override String get request4k => 'Aanvragen in 4K';
	@override String get seasons => 'Seizoenen';
	@override String get allSeasons => 'Alle seizoenen';
	@override String get advancedOptions => 'Geavanceerd';
	@override String get destinationServer => 'Doelserver';
	@override String get qualityProfile => 'Kwaliteitsprofiel';
	@override String get rootFolder => 'Hoofdmap';
	@override String get languageProfile => 'Taalprofiel';
	@override String get requestSubmitted => 'Aanvraag verzonden';
	@override String requestFailed({required Object error}) => 'Aanvraag mislukt: ${error}';
	@override String get requestsLoadFailed => 'Aanvraagopties konden niet worden geladen';
	@override String get nothingToRequest => 'Alles is al beschikbaar of aangevraagd.';
	@override String get statusAvailable => 'Beschikbaar';
	@override String get statusPartiallyAvailable => 'Gedeeltelijk beschikbaar';
	@override String get statusRequested => 'Aangevraagd';
	@override String get statusProcessing => 'Verwerken';
}

// Path: services
class _Translations$services$nl extends Translations$services$en {
	_Translations$services$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Diensten';
	@override String get hubSubtitle => 'Synchroniseer kijkvoortgang en vraag nieuwe titels aan.';
	@override String get notConnected => 'Niet verbonden';
	@override String connectedAs({required Object username}) => 'Verbonden als @${username}';
	@override String get scrobble => 'Voortgang automatisch volgen';
	@override String get scrobbleDescription => 'Werk je lijst bij wanneer je een aflevering of film afrondt.';
	@override String disconnectConfirm({required Object service}) => '${service} loskoppelen?';
	@override String disconnectConfirmBody({required Object service}) => 'Plezy werkt ${service} niet meer bij. Je kunt op elk moment opnieuw verbinding maken.';
	@override String connectFailed({required Object service}) => 'Verbinding maken met ${service} is mislukt. Probeer het opnieuw.';
	@override late final _Translations$services$names$nl names = _Translations$services$names$nl._(_root);
	@override late final _Translations$services$deviceCode$nl deviceCode = _Translations$services$deviceCode$nl._(_root);
	@override late final _Translations$services$oauthProxy$nl oauthProxy = _Translations$services$oauthProxy$nl._(_root);
	@override late final _Translations$services$libraryFilter$nl libraryFilter = _Translations$services$libraryFilter$nl._(_root);
}

// Path: addServer
class _Translations$addServer$nl extends Translations$addServer$en {
	_Translations$addServer$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get addJellyfinTitle => 'Jellyfin-server toevoegen';
	@override String get serverUrls => 'Server-URL\'s';
	@override String get serverUrlsHelper => 'Meerdere URL\'s toegestaan, gescheiden door komma\'s.';
	@override String get findServer => 'Server zoeken';
	@override String get searchingLocalServers => 'Lokale Jellyfin-servers zoeken...';
	@override String get localServers => 'Lokale Jellyfin-servers';
	@override String get username => 'Gebruikersnaam';
	@override String get password => 'Wachtwoord';
	@override String get signIn => 'Inloggen';
	@override String get change => 'Wijzigen';
	@override String get required => 'Vereist';
	@override String couldNotReachServer({required Object error}) => 'Kon de server niet bereiken: ${error}';
	@override String signInFailed({required Object error}) => 'Inloggen mislukt: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect mislukt: ${error}';
	@override String get addPlexTitle => 'Inloggen met Plex';
	@override String get pinExpired => 'De pincode verliep voordat je kon inloggen. Probeer het opnieuw.';
	@override String failedToRegisterAccount({required Object error}) => 'Account registreren mislukt: ${error}';
	@override String get enterJellyfinUrlError => 'Voer de URL van je Jellyfin-server in';
	@override String get addConnectionTitle => 'Verbinding toevoegen';
	@override String addConnectionTitleScoped({required Object name}) => 'Toevoegen aan ${name}';
	@override String get signInWithPlexCard => 'Inloggen met Plex';
	@override String get signInWithPlexCardSubtitle => 'Autoriseer dit apparaat. Gedeelde servers worden toegevoegd.';
	@override String get signInWithPlexCardSubtitleScoped => 'Autoriseer een Plex-account. Home-gebruikers worden profielen.';
	@override String get connectToJellyfinCard => 'Verbinden met Jellyfin';
	@override String get connectToJellyfinCardSubtitle => 'Voer je server-URL, gebruikersnaam en wachtwoord in.';
	@override String connectToJellyfinCardSubtitleScoped({required Object name}) => 'Log in op een Jellyfin-server. Wordt gekoppeld aan ${name}.';
	@override String get borrowFromAnotherProfile => 'Van een ander profiel lenen';
	@override String get borrowFromAnotherProfileSubtitle => 'Hergebruik de verbinding van een ander profiel. Voor profielen met pincodebeveiliging is een pincode vereist.';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$nl extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Afspelen/Pauzeren';
	@override String get volumeUp => 'Volume omhoog';
	@override String get volumeDown => 'Volume omlaag';
	@override String seekForward({required Object seconds}) => 'Vooruitspoelen (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'Terugspoelen (${seconds}s)';
	@override String get fullscreenToggle => 'Volledig scherm';
	@override String get muteToggle => 'Dempen';
	@override String get subtitleToggle => 'Ondertiteling';
	@override String get audioTrackNext => 'Volgende audiotrack';
	@override String get subtitleTrackNext => 'Volgende ondertiteltrack';
	@override String get chapterNext => 'Volgend hoofdstuk';
	@override String get chapterPrevious => 'Vorig hoofdstuk';
	@override String get episodeNext => 'Volgende aflevering';
	@override String get episodePrevious => 'Vorige aflevering';
	@override String get speedIncrease => 'Snelheid verhogen';
	@override String get speedDecrease => 'Snelheid verlagen';
	@override String get speedReset => 'Snelheid resetten';
	@override String get zoomIn => 'Inzoomen';
	@override String get zoomOut => 'Uitzoomen';
	@override String get zoomReset => 'Zoom resetten';
	@override String get subSeekNext => 'Naar volgende ondertitel';
	@override String get subSeekPrev => 'Naar vorige ondertitel';
	@override String get shaderToggle => 'Shaders aan/uit';
	@override String get skipMarker => 'Intro/aftiteling overslaan';
	@override String get screenshot => 'Schermafbeelding maken';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$nl extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Vereist Android 8.0 of nieuwer';
	@override String get iosVersion => 'Vereist iOS 15.0 of nieuwer';
	@override String get permissionDisabled => 'Beeld-in-beeld is uitgeschakeld. Schakel het in via de systeeminstellingen.';
	@override String get notSupported => 'Dit apparaat ondersteunt de beeld-in-beeldmodus niet';
	@override String get voSwitchFailed => 'Omschakelen van de video-uitvoer voor beeld-in-beeld is mislukt';
	@override String get failed => 'Beeld-in-beeld kon niet worden gestart';
	@override String unknown({required Object error}) => 'Er is een fout opgetreden: ${error}';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$nl extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Aanbevolen';
	@override String get browse => 'Bladeren';
	@override String get collections => 'Collecties';
	@override String get playlists => 'Afspeellijsten';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$nl extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Groepering';
	@override String get all => 'Alles';
	@override String get movies => 'Films';
	@override String get shows => 'Series';
	@override String get seasons => 'Seizoenen';
	@override String get episodes => 'Afleveringen';
	@override String get artists => 'Artiesten';
	@override String get albums => 'Albums';
	@override String get tracks => 'Nummers';
	@override String get folders => 'Mappen';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$nl extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Genre';
	@override String get year => 'Jaar';
	@override String get contentRating => 'Leeftijdsclassificatie';
	@override String get tag => 'Tag';
	@override String get unwatched => 'Onbekeken';
	@override String get unplayed => 'Niet afgespeeld';
	@override String get favorites => 'Favorieten';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$nl extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titel';
	@override String get dateAdded => 'Toegevoegd op';
	@override String get releaseDate => 'Uitgavedatum';
	@override String get rating => 'Beoordeling';
	@override String get communityRating => 'Beoordeling door community';
	@override String get criticRating => 'Beoordeling door critici';
	@override String get userRating => 'Gebruikersbeoordeling';
	@override String get datePlayed => 'Afspeeldatum';
	@override String get playCount => 'Aantal afspelingen';
	@override String get productionYear => 'Productiejaar';
	@override String get runtime => 'Speelduur';
	@override String get officialRating => 'Officiële beoordeling';
	@override String get premiereDate => 'Premièredatum';
	@override String get startDate => 'Begindatum';
	@override String get airTime => 'Uitzendtijd';
	@override String get studio => 'Studio';
	@override String get random => 'Willekeurig';
	@override String get dateShared => 'Gedeeld op';
	@override String get latestEpisodeAirDate => 'Laatste afleveringsuitzending';
	@override String get lastEpisodeDateAdded => 'Datum laatst toegevoegde aflevering';
}

// Path: explore.rows
class _Translations$explore$rows$nl extends Translations$explore$rows$en {
	_Translations$explore$rows$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'Kijklijst';
	@override String get recommendedMovies => 'Aanbevolen films';
	@override String get recommendedShows => 'Aanbevolen series';
	@override String get trendingMovies => 'Trending films';
	@override String get trendingShows => 'Trending series';
	@override String get popularMovies => 'Populaire films';
	@override String get popularShows => 'Populaire series';
	@override String get trendingAnime => 'Trending anime';
	@override String get suggestedAnime => 'Aanbevolen anime';
	@override String get airingAnime => 'Beste lopende anime';
	@override String get popularAnime => 'Populairste anime';
	@override String get trending => 'Trending';
	@override String get upcomingMovies => 'Aankomende films';
	@override String get upcomingShows => 'Aankomende series';
}

// Path: explore.status
class _Translations$explore$status$nl extends Translations$explore$status$en {
	_Translations$explore$status$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get airing => 'Lopend';
	@override String get ended => 'Afgelopen';
	@override String get canceled => 'Geannuleerd';
	@override String get upcoming => 'Binnenkort';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$nl extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Externe server starten...';
	@override String get hostAddress => 'Hostadres';
	@override String get connected => 'Verbonden';
	@override String get serverRunning => 'Externe server actief';
	@override String get serverStopped => 'Externe server gestopt';
	@override String get serverRunningDescription => 'Mobiele apparaten op je netwerk kunnen met deze app verbinden';
	@override String get serverStoppedDescription => 'Start de server om mobiele apparaten te laten verbinden';
	@override String get usePhoneToControl => 'Gebruik je mobiele apparaat om deze app te bedienen';
	@override String get startServer => 'Server starten';
	@override String get stopServer => 'Server stoppen';
	@override String get minimize => 'Minimaliseren';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$nl extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Plezy-apparaten met hetzelfde Plex-account verschijnen hier';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Verbinden...';
	@override String get searchingForDevices => 'Apparaten zoeken...';
	@override String get noDevicesFound => 'Geen apparaten gevonden op je netwerk';
	@override String get noDevicesHint => 'Open Plezy op je desktop en gebruik op beide apparaten dezelfde wifi';
	@override String get availableDevices => 'Beschikbare apparaten';
	@override String get manualConnection => 'Handmatige verbinding';
	@override String get cryptoInitFailed => 'Kon beveiligde verbinding niet starten. Log eerst in bij Plex.';
	@override String get validationHostRequired => 'Voer het hostadres in';
	@override String get validationHostFormat => 'Formaat moet IP:poort zijn (bijv. 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Er is een time-out opgetreden. Gebruik op beide apparaten hetzelfde netwerk.';
	@override String get sessionNotFound => 'Apparaat niet gevonden. Zorg dat Plezy op de host draait.';
	@override String get authFailed => 'Authenticatie mislukt. Beide apparaten hebben hetzelfde Plex-account nodig.';
	@override String failedToConnect({required Object error}) => 'Kan niet verbinden: ${error}';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$nl extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Wil je de verbinding met de externe sessie verbreken?';
	@override String get reconnecting => 'Opnieuw verbinden...';
	@override String attemptOf({required Object current}) => 'Poging ${current} van 5';
	@override String get retryNow => 'Nu opnieuw proberen';
	@override String get tabRemote => 'Afstandsbediening';
	@override String get tabPlay => 'Afspelen';
	@override String get tabMore => 'Meer';
	@override String get menu => 'Menu';
	@override String get tabNavigation => 'Tabnavigatie';
	@override String get tabDiscover => 'Ontdekken';
	@override String get tabLibraries => 'Bibliotheken';
	@override String get tabSearch => 'Zoeken';
	@override String get tabDownloads => 'Downloads';
	@override String get tabSettings => 'Instellingen';
	@override String get previous => 'Vorige';
	@override String get playPause => 'Afspelen/Pauzeren';
	@override String get next => 'Volgende';
	@override String get seekBack => 'Terugspoelen';
	@override String get stop => 'Stoppen';
	@override String get seekForward => 'Vooruitspoelen';
	@override String get volume => 'Volume';
	@override String get volumeDown => 'Omlaag';
	@override String get volumeUp => 'Omhoog';
	@override String get fullscreen => 'Volledig scherm';
	@override String get subtitles => 'Ondertitels';
	@override String get audio => 'Audio';
	@override String get searchHint => 'Zoeken op desktop...';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$nl extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'Geen netwerkinterface gevonden';
	@override String get authenticationFailed => 'Authenticatie mislukt';
	@override String serverStartFailed({required Object error}) => 'Externe server starten mislukt: ${error}';
	@override String commandFailed({required Object error}) => 'Externe opdracht verzenden mislukt: ${error}';
	@override String get joinTimedOut => 'Time-out bij deelnemen aan sessie';
	@override String get failedToConnectAnyAddress => 'Er kon met geen enkel adres verbinding worden gemaakt';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'Verbinding verbroken na ${attempts} pogingen';
	@override String get connectionLost => 'Verbinding verloren';
}

// Path: services.names
class _Translations$services$names$nl extends Translations$services$names$en {
	_Translations$services$names$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$nl extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Plezy activeren op ${service}';
	@override String body({required Object url}) => 'Ga naar ${url} en voer deze code in:';
	@override String openToActivate({required Object service}) => 'Open ${service} om te activeren';
	@override String get copyCode => 'Activeringscode kopiëren';
	@override String get waitingForAuthorization => 'Wachten op autorisatie…';
	@override String get codeCopied => 'Code gekopieerd';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$nl extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Aanmelden bij ${service}';
	@override String get body => 'Scan deze QR-code of open de URL op een apparaat.';
	@override String openToSignIn({required Object service}) => '${service} openen om aan te melden';
	@override String get copyUrl => 'Aanmeldings-URL kopiëren';
	@override String get urlCopied => 'URL gekopieerd';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$nl extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$nl._(TranslationsNl root) : this._root = root, super.internal(root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bibliotheekfilter';
	@override String get subtitleAllSyncing => 'Alle bibliotheken synchroniseren';
	@override String get subtitleNoneSyncing => 'Niets wordt gesynchroniseerd';
	@override String subtitleBlocked({required Object count}) => '${count} geblokkeerd';
	@override String subtitleAllowed({required Object count}) => '${count} toegestaan';
	@override String get mode => 'Filtermodus';
	@override String get modeBlacklist => 'Blokkeerlijst';
	@override String get modeWhitelist => 'Toelatingslijst';
	@override String get modeHintBlacklist => 'Synchroniseer alle bibliotheken behalve de hieronder aangevinkte.';
	@override String get modeHintWhitelist => 'Synchroniseer alleen de hieronder aangevinkte bibliotheken.';
	@override String get libraries => 'Bibliotheken';
	@override String get noLibraries => 'Geen bibliotheken beschikbaar';
}

/// The flat map containing all translations for locale <nl>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsNl {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Plezy',
			'auth.signInWithPlex' => 'Inloggen met Plex',
			'auth.showQRCode' => 'Toon QR-code',
			'auth.authenticate' => 'Authenticeren',
			'auth.authenticationTimeout' => 'Authenticatie verlopen. Probeer opnieuw.',
			'auth.scanQRToSignIn' => 'Scan deze QR-code om in te loggen',
			'auth.waitingForAuth' => 'Wachten op authenticatie...\nMeld je aan via je browser.',
			'auth.useBrowser' => 'Gebruik browser',
			'auth.or' => 'of',
			'auth.connectToJellyfin' => 'Verbinden met Jellyfin',
			'auth.useQuickConnect' => 'Quick Connect gebruiken',
			'auth.quickConnectInstructions' => 'Open Quick Connect in Jellyfin en voer deze code in.',
			'auth.quickConnectWaiting' => 'Wachten op goedkeuring…',
			'auth.quickConnectCancel' => 'Annuleren',
			'auth.quickConnectExpired' => 'Quick Connect is verlopen. Probeer opnieuw.',
			'auth.localDataRecoveryRequired' => 'Plezy kon lokale aanmeldings- en openstaande afspeelgegevens niet veilig herstellen. Meld je opnieuw aan.',
			'common.cancel' => 'Annuleren',
			'common.save' => 'Opslaan',
			'common.close' => 'Sluiten',
			'common.clear' => 'Wissen',
			'common.reset' => 'Resetten',
			'common.later' => 'Later',
			'common.submit' => 'Verzenden',
			'common.confirm' => 'Bevestigen',
			'common.retry' => 'Opnieuw proberen',
			'common.logout' => 'Uitloggen',
			'common.unknown' => 'Onbekend',
			'common.refresh' => 'Vernieuwen',
			'common.yes' => 'Ja',
			'common.no' => 'Nee',
			'common.delete' => 'Verwijderen',
			'common.edit' => 'Bewerken',
			'common.shuffle' => 'Willekeurig',
			'common.addTo' => 'Toevoegen aan...',
			'common.createNew' => 'Nieuw aanmaken',
			'common.connect' => 'Verbinden',
			'common.disconnect' => 'Verbinding verbreken',
			'common.play' => 'Afspelen',
			'common.pause' => 'Pauzeren',
			'common.resume' => 'Hervatten',
			'common.error' => 'Fout',
			'common.search' => 'Zoeken',
			'common.home' => 'Home',
			'common.back' => 'Terug',
			'common.settings' => 'Instellingen',
			'common.mute' => 'Dempen',
			'common.ok' => 'OK',
			'common.off' => 'Uit',
			'common.seasonNumber' => ({required Object number}) => 'Seizoen ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'Aflevering ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'Hoofdstuk ${number}',
			'common.reconnect' => 'Opnieuw verbinden',
			'common.viewAll' => 'Alles weergeven',
			'common.checkingNetwork' => 'Netwerk controleren...',
			'common.loadingServers' => 'Servers laden...',
			'common.connectingToServers' => 'Verbinden met servers...',
			'common.startingOfflineMode' => 'Offlinemodus starten...',
			'common.loading' => 'Laden...',
			'common.fullscreen' => 'Volledig scherm',
			'common.exitFullscreen' => 'Volledig scherm verlaten',
			'common.pressBackAgainToExit' => 'Druk nogmaals op terug om af te sluiten',
			'screens.licenses' => 'Licenties',
			'screens.switchProfile' => 'Wissel van profiel',
			'screens.subtitleStyling' => 'Ondertitelopmaak',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Logbestanden',
			'update.available' => 'Update beschikbaar',
			'update.versionAvailable' => ({required Object version}) => 'Versie ${version} is beschikbaar',
			'update.currentVersion' => ({required Object version}) => 'Huidig: ${version}',
			'update.skipVersion' => 'Deze versie overslaan',
			'update.viewRelease' => 'Bekijk release',
			'update.latestVersion' => 'Je hebt de nieuwste versie',
			'update.checkFailed' => 'Kon niet controleren op updates',
			'settings.title' => 'Instellingen',
			'settings.supportDeveloper' => 'Steun Plezy',
			'settings.supportDeveloperDescription' => 'Doneer via Liberapay om de ontwikkeling te steunen',
			'settings.language' => 'Taal',
			'settings.theme' => 'Thema',
			'settings.appearance' => 'Uiterlijk',
			'settings.videoPlayback' => 'Video afspelen',
			'settings.videoPlaybackDescription' => 'Afspeelgedrag configureren',
			'settings.advanced' => 'Geavanceerd',
			'settings.episodePosterMode' => 'Stijl van afleveringsposter',
			'settings.seriesPoster' => 'Serieposter',
			'settings.seasonPoster' => 'Seizoensposter',
			'settings.episodeThumbnail' => 'Miniatuur',
			'settings.showHeroSectionDescription' => 'Toon de carrousel met uitgelichte inhoud op het startscherm',
			'settings.secondsLabel' => 'Seconden',
			'settings.minutesLabel' => 'Minuten',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Voer duur in (${min}-${max})',
			'settings.systemTheme' => 'Systeem',
			'settings.lightTheme' => 'Licht',
			'settings.darkTheme' => 'Donker',
			'settings.oledTheme' => 'OLED',
			'settings.libraryDensity' => 'Bibliotheekdichtheid',
			'settings.compact' => 'Compact',
			'settings.comfortable' => 'Comfortabel',
			'settings.tvCornerSpotlightBackdrop' => 'Uitgelichte achtergrond in de hoek',
			'settings.tvCornerSpotlightBackdropDescription' => 'Toon de uitgelichte afbeelding rechtsboven in plaats van schermvullend',
			'settings.viewMode' => 'Weergavemodus',
			'settings.gridView' => 'Raster',
			'settings.listView' => 'Lijst',
			'settings.showHeroSection' => 'Toon hoofdsectie',
			'settings.continueWatchingAction' => 'Actie voor \'Doorgaan met kijken\'',
			'settings.continueWatchingPlay' => 'Afspelen',
			'settings.continueWatchingDetails' => 'Details openen',
			'settings.episodeAction' => 'Afleveringsactie',
			'settings.episodePlay' => 'Afspelen',
			'settings.episodeDetails' => 'Details openen',
			'settings.useGlobalHubs' => 'Startlayout gebruiken',
			'settings.useGlobalHubsDescription' => 'Toon gecombineerde hubs op het startscherm. Gebruik anders bibliotheekaanbevelingen.',
			'settings.showServerNameOnHubs' => 'Servernaam tonen bij hubs',
			'settings.showServerNameOnHubsDescription' => 'Toon servernamen altijd in hubtitels.',
			'settings.groupLibrariesByServer' => 'Bibliotheken groeperen per server',
			'settings.groupLibrariesByServerDescription' => 'Groepeer zijbalkbibliotheken onder elke mediaserver.',
			'settings.alwaysKeepSidebarOpen' => 'Zijbalk altijd open houden',
			'settings.alwaysKeepSidebarOpenDescription' => 'Zijbalk blijft uitgevouwen en inhoudsgebied past zich aan',
			'settings.showUnwatchedCount' => 'Aantal ongekeken tonen',
			'settings.showUnwatchedCountDescription' => 'Toon aantal ongekeken afleveringen bij series en seizoenen',
			'settings.showEpisodeNumberOnCards' => 'Afleveringsnummer op kaarten tonen',
			'settings.showEpisodeNumberOnCardsDescription' => 'Toon seizoen- en afleveringsnummer op afleveringskaarten',
			'settings.showSeasonPostersOnTabs' => 'Toon seizoensposters op tabbladen',
			'settings.showSeasonPostersOnTabsDescription' => 'Toon de poster van elk seizoen boven het tabblad',
			'settings.tvFullCardLayout' => 'Volledige tv-kaarten',
			'settings.tvFullCardLayoutDescription' => 'Gebruik tv-kaarten met alleen afbeeldingen en namen van acteurs als overlay',
			'settings.focusGlow' => 'Focusgloed',
			'settings.focusGlowDescription' => 'Toon een zachte gloed rond de kaart met focus',
			'settings.visualEffects' => 'Visuele effecten',
			'settings.visualEffectsAuto' => 'Automatisch',
			'settings.visualEffectsAutoDescription' => 'Effecten automatisch verminderen op apparaten met laag vermogen',
			'settings.visualEffectsFull' => 'Volledig',
			'settings.visualEffectsReduced' => 'Verminderd',
			'settings.visualEffectsReducedDescription' => 'Minder animaties en illustraties met lagere resolutie',
			'settings.hideSpoilers' => 'Spoilers voor ongekeken afleveringen verbergen',
			'settings.hideSpoilersDescription' => 'Vervaag miniaturen en beschrijvingen van ongekeken afleveringen',
			'settings.playerBackend' => 'Afspeelbackend',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Hardwaredecodering',
			'settings.hardwareDecodingDescription' => 'Gebruik hardwareversnelling indien beschikbaar',
			'settings.bufferSize' => 'Buffergrootte',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => 'Automatisch (aanbevolen)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => '${heap}MB geheugen beschikbaar. Een buffer van ${size}MB kan afspelen beïnvloeden.',
			'settings.defaultQualityTitle' => 'Standaardkwaliteit',
			'settings.musicQualityTitle' => 'Muziekkwaliteit',
			'settings.subtitleStyling' => 'Ondertitelopmaak',
			'settings.subtitleStylingDescription' => 'Pas de weergave van ondertitels aan',
			'settings.smallSkipDuration' => 'Korte sprong',
			'settings.largeSkipDuration' => 'Lange sprong',
			'settings.rewindOnResume' => 'Terugspoelen bij hervatten',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} seconden',
			'settings.defaultSleepTimer' => 'Standaardslaaptimer',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} minuten',
			'settings.rememberTrackSelections' => 'Trackselecties per serie of film onthouden',
			'settings.rememberTrackSelectionsDescription' => 'Onthoud audio- en ondertitelkeuzes per titel',
			'settings.showChapterMarkersOnTimeline' => 'Hoofdstukmarkeringen op tijdlijn tonen',
			'settings.showChapterMarkersOnTimelineDescription' => 'Verdeel de tijdlijn bij hoofdstukgrenzen',
			'settings.clickVideoTogglesPlayback' => 'Klik op de video om afspelen of pauzeren te wisselen',
			'settings.clickVideoTogglesPlaybackDescription' => 'Klik op de video om af te spelen of te pauzeren in plaats van de bediening te tonen.',
			'settings.videoPlayerControls' => 'Videospelerbediening',
			'settings.keyboardShortcuts' => 'Toetsenbordsneltoetsen',
			'settings.keyboardShortcutsDescription' => 'Pas de toetsenbordsneltoetsen aan',
			'settings.videoPlayerNavigation' => 'Videospelernavigatie',
			'settings.videoPlayerNavigationDescription' => 'Gebruik de pijltjestoetsen om door de videospelerbediening te navigeren',
			'settings.watchTogetherRelay' => 'Relay voor Samen kijken',
			'settings.watchTogetherRelayDescription' => 'Stel een aangepaste relay in. Iedereen moet dezelfde server gebruiken.',
			'settings.watchTogetherRelayHint' => 'https://mijn-relay.voorbeeld.nl',
			'settings.watchTogetherRelayInvalid' => 'Voer een geldige HTTP- of HTTPS-basis-URL voor de relay in.',
			'settings.crashReporting' => 'Crashrapportage',
			'settings.crashReportingDescription' => 'Crashrapporten verzenden om de app te verbeteren',
			'settings.debugLogging' => 'Debuglogboek',
			'settings.debugLoggingDescription' => 'Schakel gedetailleerde logboekregistratie in om problemen op te lossen',
			'settings.viewLogs' => 'Logbestanden bekijken',
			'settings.viewLogsDescription' => 'Logbestanden van de app bekijken',
			'settings.clearCache' => 'Cache wissen',
			'settings.clearCacheDescription' => 'Wis gecachete afbeeldingen en gegevens. Inhoud kan langzamer laden.',
			'settings.clearCacheSuccess' => 'Cache succesvol gewist',
			'settings.resetSettings' => 'Instellingen resetten',
			'settings.resetSettingsDescription' => 'Standaardinstellingen herstellen. Dit kan niet ongedaan worden gemaakt.',
			'settings.resetSettingsSuccess' => 'Instellingen succesvol gereset',
			'settings.backup' => 'Back-up',
			'settings.exportSettings' => 'Instellingen exporteren',
			'settings.exportSettingsDescription' => 'Sla je voorkeuren op in een bestand',
			'settings.exportSettingsSuccess' => 'Instellingen geëxporteerd',
			'settings.importSettings' => 'Instellingen importeren',
			'settings.importSettingsDescription' => 'Voorkeuren herstellen vanuit een bestand',
			'settings.importSettingsConfirm' => 'Hiermee worden je huidige instellingen vervangen. Doorgaan?',
			'settings.importSettingsSuccess' => 'Instellingen geïmporteerd',
			'settings.importSettingsInvalidFile' => 'Dit bestand is geen geldige Plezy-export',
			'settings.importSettingsNoUser' => 'Meld je aan voordat je instellingen importeert',
			'settings.shortcutsReset' => 'Sneltoetsen gereset naar standaard',
			'settings.about' => 'Over',
			'settings.aboutDescription' => 'App-informatie en licenties',
			'settings.updates' => 'Updates',
			'settings.updateAvailable' => 'Update beschikbaar',
			'settings.checkForUpdates' => 'Controleer op updates',
			'settings.autoCheckUpdatesOnStartup' => 'Automatisch controleren op updates bij opstarten',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Melden wanneer er bij start een update beschikbaar is',
			'settings.validationErrorEnterNumber' => 'Voer een geldig nummer in',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Duur moet tussen ${min} en ${max} ${unit} zijn',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Sneltoets al toegewezen aan ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Sneltoets bijgewerkt voor ${action}',
			'settings.saveFailed' => 'Wijzigingen konden niet worden opgeslagen. Probeer het opnieuw.',
			'settings.autoSkip' => 'Automatisch overslaan',
			'settings.autoSkipIntro' => 'Intro automatisch overslaan',
			'settings.autoSkipIntroDescription' => 'Intromarkeringen na enkele seconden automatisch overslaan',
			'settings.autoSkipCredits' => 'Aftiteling automatisch overslaan',
			'settings.autoSkipCreditsDescription' => 'Aftiteling automatisch overslaan en de volgende aflevering afspelen',
			'settings.forceSkipMarkerFallback' => 'Reservemarkeringen afdwingen',
			'settings.forceSkipMarkerFallbackDescription' => 'Gebruik patronen in hoofdstuktitels, zelfs wanneer Plex markeringen heeft',
			'settings.autoSkipDelay' => 'Vertraging voor automatisch overslaan',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => '${seconds} seconden wachten voor automatisch overslaan',
			'settings.introPattern' => 'Intromarkeringspatroon',
			'settings.introPatternDescription' => 'Reguliere expressie om intromarkeringen in hoofdstuktitels te herkennen',
			'settings.creditsPattern' => 'Aftitelingmarkeringspatroon',
			'settings.creditsPatternDescription' => 'Reguliere expressie om aftitelingmarkeringen in hoofdstuktitels te herkennen',
			'settings.invalidRegex' => 'Ongeldige reguliere expressie',
			'settings.regex' => 'Reguliere expressie',
			'settings.downloads' => 'Downloads',
			'settings.downloadLocationDescription' => 'Kies waar gedownloade inhoud wordt opgeslagen',
			'settings.downloadLocationDefault' => 'Standaard (app-opslag)',
			'settings.downloadLocationCustom' => 'Aangepaste locatie',
			'settings.selectFolder' => 'Map selecteren',
			'settings.resetToDefault' => 'Standaardinstelling herstellen',
			'settings.currentPath' => ({required Object path}) => 'Huidig: ${path}',
			'settings.downloadLocationChanged' => 'Downloadlocatie gewijzigd',
			'settings.downloadLocationReset' => 'Downloadlocatie hersteld naar standaard',
			'settings.downloadLocationInvalid' => 'Geselecteerde map is niet beschrijfbaar',
			'settings.downloadLocationPickerUnavailable' => 'Mapselectie is niet beschikbaar op dit apparaat',
			'settings.downloadOnWifiOnly' => 'Alleen via wifi downloaden',
			'settings.downloadOnWifiOnlyDescription' => 'Voorkom downloads bij gebruik van mobiele data',
			'settings.autoRemoveWatchedDownloads' => 'Bekeken downloads automatisch verwijderen',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Bekeken downloads automatisch verwijderen',
			'settings.cellularDownloadBlocked' => 'Downloads via een mobiel netwerk zijn geblokkeerd. Gebruik wifi of wijzig de instelling.',
			'settings.maxVolume' => 'Maximaal volume',
			'settings.maxVolumeDescription' => 'Volume boven 100% toestaan voor stille media',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Toon op Discord wat je aan het kijken bent',
			'settings.services' => 'Diensten',
			'settings.servicesDescription' => 'Koppel Trakt, MyAnimeList, Seerr en meer',
			'settings.manageLibrariesDescription' => 'Bibliotheken herordenen en verbergen',
			'settings.companionRemoteServer' => 'Companion Remote-server',
			'settings.companionRemoteServerDescription' => 'Sta mobiele apparaten op je netwerk toe om deze app te bedienen',
			'settings.autoPip' => 'Automatische beeld-in-beeld',
			'settings.autoPipDescription' => 'Schakel over naar beeld-in-beeld als je tijdens het afspelen de app verlaat',
			'settings.matchContentFrameRate' => 'Inhoudsframesnelheid afstemmen',
			'settings.matchContentFrameRateDescription' => 'Stem schermverversing af op videocontent',
			'settings.matchRefreshRate' => 'Verversingssnelheid afstemmen',
			'settings.matchRefreshRateDescription' => 'Stem schermverversing af in volledig scherm',
			'settings.matchDynamicRange' => 'Dynamisch bereik afstemmen',
			'settings.matchDynamicRangeDescription' => 'Schakel HDR in voor HDR-content en daarna terug naar SDR',
			'settings.displaySwitchDelay' => 'Vertraging bij schermwisseling',
			'settings.tunneledPlayback' => 'Getunnelde weergave',
			'settings.tunneledPlaybackDescription' => 'Gebruik videotunneling. Schakel uit als HDR-afspelen zwart beeld geeft.',
			'settings.audioPassthrough' => 'Audio-doorvoer',
			'settings.audioPassthroughDescription' => 'Stuur Dolby/DTS-audio zonder hercodering naar je receiver of tv en behoud surroundgeluid. Schakel uit als je geen geluid hebt.',
			'settings.audioPassthroughDescriptionAppleTv' => 'Gebruik de ingebouwde Dolby-decoder van Apple voor Dolby Digital Plus, inclusief Atmos. DTS en TrueHD worden nog steeds als meerkanaals-PCM afgespeeld. Schakel dit uit als je geen geluid hoort.',
			'settings.audioDownmix' => 'Downmixen naar stereo',
			'settings.audioDownmixDescription' => 'Mix surroundgeluid terug naar twee kanalen voor stereoluidsprekers of een koptelefoon',
			'settings.downmixCenterBoost' => 'Versterking middenkanaal',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Versterking (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Volume normaliseren bij downmix',
			'settings.audioDownmixNormalizeDescription' => 'Verlaagt de mix om clipping te voorkomen. Zet uit om het originele volume te behouden (kan vervormen bij luide scènes).',
			'settings.atmosDiagnostics' => 'Atmos-uitvoertest',
			'settings.atmosDiagnosticsDescription' => 'Diagnosticeer de Dolby Atmos-uitvoer door testsignalen via de systeemspeler af te spelen',
			'settings.atmosTestHlsAtmos' => 'Apple Atmos-stream',
			'settings.atmosTestHlsAtmosDescription' => 'Bewezen werkende Dolby Atmos-stream. De receiver zou Dolby Atmos moeten tonen.',
			'settings.atmosTestHlsControl' => 'Apple surround-stream',
			'settings.atmosTestHlsControlDescription' => 'Controlestream zonder Atmos. De receiver zou surround zonder Atmos moeten tonen.',
			'settings.atmosTestRawStream' => 'Ruwe EAC3-stream',
			'settings.atmosTestRawStreamDescription' => 'Streamt het testbestand precies zoals Atmos-weergave in de speler. Vereist de URL van het testbestand.',
			'settings.atmosTestRawFile' => 'Ruw EAC3-bestand',
			'settings.atmosTestRawFileDescription' => 'Speelt het testbestand met bekende lengte af. Vereist de URL van het testbestand.',
			'settings.atmosTestStop' => 'Test stoppen',
			'settings.atmosTestUrl' => 'URL van testbestand',
			'settings.atmosTestUrlDescription' => 'HTTP-URL van een ruw .ec3 Dolby Atmos-bestand (bijv. uitgepakt met ffmpeg)',
			'settings.atmosTestUrlMissing' => 'Stel eerst de URL van het testbestand in',
			'settings.atmosTestStatus' => 'Status',
			'settings.dvConversionMode' => 'Dolby Vision-conversie',
			'settings.dvConversionModeDescription' => 'Kies hoe ExoPlayer Dolby Vision Profile 7-bestanden verwerkt.',
			'settings.dvConversionAuto' => 'Automatisch',
			'settings.dvConversionNative' => 'Native / uitgeschakeld',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Gebruik detectie van apparaatmogelijkheden en het normale terugvalgedrag',
			'settings.dvConversionNativeDescription' => 'Dwing native DV7 af en voorkom een nieuwe poging met DV-conversie',
			'settings.dvConversionDv81Description' => 'Dwing directe RPU-conversie naar Dolby Vision-profiel 8.1 af',
			'settings.dvConversionHevcStripDescription' => 'Verwijder Dolby Vision RPU/EL-lagen en bied gewone HEVC aan',
			'settings.requireProfileSelectionOnOpen' => 'Vraag om profiel bij openen',
			'settings.requireProfileSelectionOnOpenDescription' => 'Toon profielselectie telkens wanneer de app wordt geopend',
			'settings.forceTvMode' => 'Tv-modus afdwingen',
			'settings.forceTvModeDescription' => 'Dwing de tv-indeling af op apparaten zonder automatische detectie. Herstart vereist.',
			'settings.startInFullscreen' => 'Starten in volledig scherm',
			'settings.startInFullscreenDescription' => 'Open Plezy bij het starten in volledig scherm',
			'settings.exitFullscreenOnPlayerClose' => 'Volledig scherm verlaten bij sluiten van speler',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Verlaat automatisch de volledigschermmodus wanneer de videospeler wordt gesloten',
			'settings.autoHidePerformanceOverlay' => 'Prestatie-overlay automatisch verbergen',
			'settings.autoHidePerformanceOverlayDescription' => 'Laat de prestatie-overlay samen met de afspeelknoppen vervagen',
			'settings.showNavBarLabels' => 'Labels op navigatiebalk tonen',
			'settings.showNavBarLabelsDescription' => 'Tekstlabels onder de pictogrammen op de navigatiebalk weergeven',
			'settings.startupSection' => 'Opstartsectie',
			'settings.liveTvDefaultFavorites' => 'Standaard favoriete zenders',
			'settings.liveTvDefaultFavoritesDescription' => 'Toon alleen favoriete zenders bij het openen van Live TV',
			'settings.display' => 'Weergave',
			'settings.homeScreen' => 'Startscherm',
			'settings.navigation' => 'Navigatie',
			'settings.window' => 'Venster',
			'settings.content' => 'Inhoud',
			'settings.player' => 'Speler',
			'settings.subtitlesAndConfig' => 'Ondertitels en instellingen',
			'settings.seekAndTiming' => 'Spoelen en timing',
			'settings.behavior' => 'Gedrag',
			'search.hint' => 'Zoek films, series, muziek...',
			'search.tryDifferentTerm' => 'Probeer een andere zoekterm',
			'search.searchYourMedia' => 'Zoek in je media',
			'search.enterTitleActorOrKeyword' => 'Voer een titel, acteur of trefwoord in',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Stel sneltoets in voor ${actionName}',
			'hotkeys.clearShortcut' => 'Wis sneltoets',
			'hotkeys.noShortcutSet' => 'Geen sneltoets ingesteld',
			'hotkeys.currentShortcut' => 'Huidige sneltoets:',
			'hotkeys.pressToRecord' => 'Selecteer om een sneltoets op te nemen',
			'hotkeys.recordingShortcut' => 'Druk nu op de sneltoets',
			'hotkeys.actions.playPause' => 'Afspelen/Pauzeren',
			'hotkeys.actions.volumeUp' => 'Volume omhoog',
			'hotkeys.actions.volumeDown' => 'Volume omlaag',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Vooruitspoelen (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Terugspoelen (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'Volledig scherm',
			'hotkeys.actions.muteToggle' => 'Dempen',
			'hotkeys.actions.subtitleToggle' => 'Ondertiteling',
			'hotkeys.actions.audioTrackNext' => 'Volgende audiotrack',
			'hotkeys.actions.subtitleTrackNext' => 'Volgende ondertiteltrack',
			'hotkeys.actions.chapterNext' => 'Volgend hoofdstuk',
			'hotkeys.actions.chapterPrevious' => 'Vorig hoofdstuk',
			'hotkeys.actions.episodeNext' => 'Volgende aflevering',
			'hotkeys.actions.episodePrevious' => 'Vorige aflevering',
			'hotkeys.actions.speedIncrease' => 'Snelheid verhogen',
			'hotkeys.actions.speedDecrease' => 'Snelheid verlagen',
			'hotkeys.actions.speedReset' => 'Snelheid resetten',
			'hotkeys.actions.zoomIn' => 'Inzoomen',
			'hotkeys.actions.zoomOut' => 'Uitzoomen',
			'hotkeys.actions.zoomReset' => 'Zoom resetten',
			'hotkeys.actions.subSeekNext' => 'Naar volgende ondertitel',
			'hotkeys.actions.subSeekPrev' => 'Naar vorige ondertitel',
			'hotkeys.actions.shaderToggle' => 'Shaders aan/uit',
			'hotkeys.actions.skipMarker' => 'Intro/aftiteling overslaan',
			'hotkeys.actions.screenshot' => 'Schermafbeelding maken',
			'fileInfo.title' => 'Bestandsinformatie',
			'fileInfo.video' => 'Video',
			'fileInfo.audio' => 'Audio',
			'fileInfo.file' => 'Bestand',
			'fileInfo.advanced' => 'Geavanceerd',
			'fileInfo.codec' => 'Codec',
			'fileInfo.resolution' => 'Resolutie',
			'fileInfo.bitrate' => 'Bitrate',
			'fileInfo.frameRate' => 'Framesnelheid',
			'fileInfo.aspectRatio' => 'Beeldverhouding',
			'fileInfo.profile' => 'Profiel',
			'fileInfo.bitDepth' => 'Bitdiepte',
			'fileInfo.colorSpace' => 'Kleurruimte',
			'fileInfo.colorRange' => 'Kleurbereik',
			'fileInfo.colorPrimaries' => 'Kleurprimaires',
			'fileInfo.chromaSubsampling' => 'Chroma-subsampling',
			'fileInfo.channels' => 'Kanalen',
			'fileInfo.subtitles' => 'Ondertitels',
			'fileInfo.overallBitrate' => 'Totale bitrate',
			'fileInfo.path' => 'Pad',
			'fileInfo.size' => 'Grootte',
			'fileInfo.container' => 'Container',
			'fileInfo.duration' => 'Duur',
			'fileInfo.optimizedForStreaming' => 'Geoptimaliseerd voor streaming',
			'fileInfo.has64bitOffsets' => '64-bits offsets',
			'mediaMenu.markAsWatched' => 'Als bekeken markeren',
			'mediaMenu.markAsUnwatched' => 'Als ongekeken markeren',
			'mediaMenu.removeFromContinueWatching' => 'Uit \'Doorgaan met kijken\' verwijderen',
			'mediaMenu.viewDetails' => 'Details bekijken',
			'mediaMenu.goToSeries' => 'Ga naar serie',
			'mediaMenu.shufflePlay' => 'Willekeurig afspelen',
			'mediaMenu.shuffleNotAvailableOffline' => 'Willekeurig afspelen is offline niet beschikbaar',
			'mediaMenu.fileInfo' => 'Bestandsinformatie',
			'mediaMenu.deleteFromServer' => 'Van server verwijderen',
			'mediaMenu.confirmDelete' => 'Deze media en bestanden van je server verwijderen?',
			'mediaMenu.deleteMultipleWarning' => 'Dit omvat alle afleveringen en hun bestanden.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Media-item succesvol verwijderd',
			'mediaMenu.mediaFailedToDelete' => 'Verwijderen van media-item mislukt',
			'mediaMenu.rate' => 'Beoordelen',
			'mediaMenu.playFromBeginning' => 'Afspelen vanaf het begin',
			'mediaMenu.playVersion' => 'Versie afspelen...',
			'rateSheet.title' => 'Beoordelen',
			'rateSheet.server' => 'Server',
			'rateSheet.favorite' => 'Favoriet',
			'rateSheet.favorited' => 'Toegevoegd aan favorieten',
			'rateSheet.saved' => 'Opgeslagen',
			'rateSheet.notAvailable' => 'Geen overeenkomst gevonden',
			'rateSheet.noConnectedServices' => 'Koppel een dienst in Instellingen om daar een beoordeling te geven.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, film',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, tv-serie',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'bekeken',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} procent bekeken',
			'accessibility.mediaCardUnwatched' => 'niet bekeken',
			'accessibility.tapToPlay' => 'Tik om af te spelen',
			'accessibility.decrease' => 'Verlagen',
			'accessibility.increase' => 'Verhogen',
			'accessibility.decreaseValue' => ({required Object label}) => '${label} verlagen',
			'accessibility.increaseValue' => ({required Object label}) => '${label} verhogen',
			'accessibility.hue' => 'Tint',
			'accessibility.saturation' => 'Verzadiging',
			'accessibility.brightness' => 'Helderheid',
			'accessibility.hexColor' => 'Hexkleur',
			'accessibility.expandText' => 'Tekst uitvouwen',
			'accessibility.collapseText' => 'Tekst samenvouwen',
			'accessibility.alphabetNavigation' => 'Alfabetische navigatie',
			'accessibility.alphabetScrollHint' => 'Veeg omhoog of omlaag om per letter te bewegen',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Rij ${row} van ${rowCount}, kolom ${column} van ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'Rij ${row} van ${rowCount}',
			'tooltips.shufflePlay' => 'Willekeurig afspelen',
			'tooltips.playTrailer' => 'Trailer afspelen',
			'tooltips.markAsWatched' => 'Als bekeken markeren',
			'tooltips.markAsUnwatched' => 'Als ongekeken markeren',
			'audioTracks.track' => ({required Object n}) => 'Audiospoor ${n}',
			'videoControls.audioLabel' => 'Audio',
			'videoControls.subtitlesLabel' => 'Ondertitels',
			'videoControls.resetToZero' => 'Terugzetten naar 0 ms',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount}${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label} speelt later af',
			'videoControls.playsEarlier' => ({required Object label}) => '${label} speelt eerder af',
			'videoControls.noOffset' => 'Geen offset',
			'videoControls.letterbox' => 'Letterbox',
			'videoControls.fillScreen' => 'Scherm vullen',
			'videoControls.stretch' => 'Uitrekken',
			'videoControls.lockRotation' => 'Rotatie vergrendelen',
			'videoControls.unlockRotation' => 'Rotatie ontgrendelen',
			'videoControls.timerActive' => 'Timer actief',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Afspelen wordt gepauzeerd over ${duration}',
			'videoControls.sleepTimerEndOfVideo' => 'Einde van huidige video',
			'videoControls.sleepTimerStopAtHeader' => 'Stoppen bij',
			'videoControls.sleepTimerDurationHeader' => 'Timer',
			'videoControls.playbackWillPauseAtEnd' => 'Afspelen wordt gepauzeerd aan het einde van deze video',
			'videoControls.stillWatching' => 'Kijk je nog?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Pauze over ${seconds}s',
			'videoControls.continueWatching' => 'Doorgaan',
			'videoControls.autoPlayNext' => 'Volgende automatisch afspelen',
			'videoControls.playNext' => 'Volgende afspelen',
			'videoControls.playButton' => 'Afspelen',
			'videoControls.pauseButton' => 'Pauzeren',
			'videoControls.showPlaybackControls' => 'Afspeelbediening tonen',
			'videoControls.hidePlaybackControls' => 'Afspeelbediening verbergen',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => '${seconds} seconden terugspoelen',
			'videoControls.seekForwardButton' => ({required Object seconds}) => '${seconds} seconden vooruitspoelen',
			'videoControls.previousButton' => 'Vorige aflevering',
			'videoControls.nextButton' => 'Volgende aflevering',
			'videoControls.previousChapterButton' => 'Vorig hoofdstuk',
			'videoControls.nextChapterButton' => 'Volgend hoofdstuk',
			'videoControls.muteButton' => 'Dempen',
			'videoControls.unmuteButton' => 'Dempen opheffen',
			'videoControls.settingsButton' => 'Afspeelinstellingen',
			'videoControls.tracksButton' => 'Audio en ondertitels',
			'videoControls.chaptersButton' => 'Hoofdstukken',
			'videoControls.versionQualityButton' => 'Versie en kwaliteit',
			'videoControls.versionColumnHeader' => 'Versie',
			'videoControls.qualityColumnHeader' => 'Kwaliteit',
			'videoControls.qualityOriginal' => 'Origineel',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Transcoderen niet beschikbaar — originele kwaliteit wordt afgespeeld',
			'videoControls.subtitleUnavailableFallback' => 'De geselecteerde ondertitels konden niet worden geladen — afspelen gaat door zonder ondertitels',
			'videoControls.pipButton' => 'Beeld-in-beeldmodus',
			'videoControls.aspectRatioButton' => 'Beeldverhouding',
			'videoControls.ambientLighting' => 'Omgevingsverlichting',
			'videoControls.fullscreenButton' => 'Volledig scherm activeren',
			'videoControls.exitFullscreenButton' => 'Volledig scherm verlaten',
			'videoControls.alwaysOnTopButton' => 'Altijd bovenop',
			'videoControls.rotationLockButton' => 'Rotatievergrendeling',
			'videoControls.lockScreen' => 'Scherm vergrendelen',
			'videoControls.screenLockButton' => 'Schermvergrendeling',
			'videoControls.longPressToUnlock' => 'Lang indrukken om te ontgrendelen',
			'videoControls.timelineSlider' => 'Videotijdlijn',
			'videoControls.volumeSlider' => 'Volumeniveau',
			'videoControls.endsAt' => ({required Object time}) => 'Eindigt om ${time}',
			'videoControls.pipActive' => 'Afspelen in beeld-in-beeld',
			'videoControls.pipFailed' => 'Beeld-in-beeld kon niet worden gestart',
			'videoControls.screenshotSaved' => 'Schermafbeelding opgeslagen',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Zoom ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Vereist Android 8.0 of nieuwer',
			'videoControls.pipErrors.iosVersion' => 'Vereist iOS 15.0 of nieuwer',
			'videoControls.pipErrors.permissionDisabled' => 'Beeld-in-beeld is uitgeschakeld. Schakel het in via de systeeminstellingen.',
			'videoControls.pipErrors.notSupported' => 'Dit apparaat ondersteunt de beeld-in-beeldmodus niet',
			'videoControls.pipErrors.voSwitchFailed' => 'Omschakelen van de video-uitvoer voor beeld-in-beeld is mislukt',
			'videoControls.pipErrors.failed' => 'Beeld-in-beeld kon niet worden gestart',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Er is een fout opgetreden: ${error}',
			'videoControls.chapters' => 'Hoofdstukken',
			'videoControls.noChaptersAvailable' => 'Geen hoofdstukken beschikbaar',
			'videoControls.queue' => 'Wachtrij',
			'videoControls.noQueueItems' => 'Geen items in de wachtrij',
			'videoControls.searchSubtitles' => 'Ondertitels zoeken',
			'videoControls.language' => 'Taal',
			'videoControls.noSubtitlesFound' => 'Geen ondertitels gevonden',
			'videoControls.noSubtitlesAvailable' => 'Geen ondertitels beschikbaar',
			'videoControls.noAudioTracksAvailable' => 'Geen audiotracks beschikbaar',
			'videoControls.noTracksAvailable' => 'Geen tracks beschikbaar',
			'videoControls.subtitleDownloaded' => 'Ondertitel gedownload',
			'videoControls.subtitleDownloadedNotApplied' => 'De ondertiteling is gedownload, maar kon niet worden geselecteerd',
			'videoControls.subtitleDownloadFailed' => 'Ondertitel downloaden mislukt',
			'videoControls.searchLanguages' => 'Talen zoeken...',
			_ => null,
		} ?? switch (path) {
			'messages.markedAsWatched' => 'Gemarkeerd als gekeken',
			'messages.markedAsUnwatched' => 'Gemarkeerd als ongekeken',
			'messages.markedAsWatchedOffline' => 'Gemarkeerd als bekeken (wordt gesynchroniseerd zodra je online bent)',
			'messages.markedAsUnwatchedOffline' => 'Gemarkeerd als ongekeken (wordt gesynchroniseerd zodra je online bent)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Automatisch verwijderd: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nl'))(n, one: 'Automatisch ${n} bekeken download verwijderd', other: 'Automatisch ${n} bekeken downloads verwijderd', ), 
			'messages.removedFromContinueWatching' => 'Verwijderd uit \'Doorgaan met kijken\'',
			'messages.errorLoading' => ({required Object error}) => 'Fout: ${error}',
			'messages.streamInterrupted' => 'De stream is onderbroken. Druk op afspelen of spoel om het opnieuw te proberen.',
			'messages.liveStreamInterrupted' => 'De livestream is onderbroken. Druk op afspelen om het opnieuw te proberen.',
			'messages.fileInfoNotAvailable' => 'Bestandsinformatie niet beschikbaar',
			'messages.playbackAuthenticationRequired' => 'Meld je opnieuw aan bij de mediaserver om dit item af te spelen.',
			'messages.playbackServerUnavailable' => 'De mediaserver is niet beschikbaar. Probeer het later opnieuw.',
			'messages.playbackDataInvalid' => 'De server heeft ongeldige afspeelinformatie geretourneerd.',
			'messages.playbackCancelled' => 'Het afspelen is geannuleerd.',
			'messages.playbackFailed' => 'Het afspelen kon niet worden gestart.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Fout bij laden van bestandsinformatie: ${error}',
			'messages.errorLoadingSeries' => 'Fout bij laden van serie',
			'messages.musicNotSupported' => 'Muziek afspelen wordt nog niet ondersteund',
			'messages.noDescriptionAvailable' => 'Geen beschrijving beschikbaar',
			'messages.noProfilesAvailable' => 'Geen profielen beschikbaar',
			'messages.contactAdminForProfiles' => 'Neem contact op met je serverbeheerder om profielen toe te voegen',
			'messages.unableToDetermineLibrarySection' => 'Kan bibliotheeksectie voor dit item niet bepalen',
			'messages.logsCleared' => 'Logbestanden gewist',
			'messages.logsCopied' => 'Logbestanden naar het klembord gekopieerd',
			'messages.noLogsAvailable' => 'Geen logbestanden beschikbaar',
			'messages.libraryScanning' => ({required Object title}) => '"${title}" scannen...',
			'messages.libraryScanStarted' => ({required Object title}) => 'Bibliotheekscan gestart voor "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Bibliotheek scannen mislukt: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Metadata voor "${title}" vernieuwen...',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Vernieuwen van metadata gestart voor "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Metadata vernieuwen mislukt: ${error}',
			'messages.logoutConfirm' => 'Weet je zeker dat je wilt uitloggen?',
			'messages.noSeasonsFound' => 'Geen seizoenen gevonden',
			'messages.seasonsLoadFailed' => 'Kan seizoenen niet laden',
			'messages.noEpisodesFound' => 'Geen afleveringen gevonden in eerste seizoen',
			'messages.noEpisodesFoundGeneral' => 'Geen afleveringen gevonden',
			'messages.episodesLoadFailed' => 'Kan afleveringen niet laden',
			'messages.noResultsFound' => 'Geen resultaten gevonden',
			'messages.sleepTimerSet' => ({required Object label}) => 'Slaaptimer ingesteld op ${label}',
			'messages.noItemsAvailable' => 'Geen items beschikbaar',
			'messages.failedToCreatePlayQueueNoItems' => 'Afspeelwachtrij maken mislukt — geen items',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Afspelen van ${action} mislukt: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Overschakelen naar compatibele speler...',
			'messages.serverLimitTitle' => 'Afspelen mislukt',
			'messages.serverLimitBody' => 'Serverfout (HTTP 500). Waarschijnlijk weigerde een bandbreedte-/transcodeerlimiet deze sessie. Vraag de eigenaar dit aan te passen.',
			'messages.logsUploaded' => 'Logbestanden geüpload',
			'messages.logsUploadFailed' => 'Uploaden van logbestanden mislukt',
			'messages.logId' => 'Logboek-ID',
			'subtitlingStyling.text' => 'Tekst',
			'subtitlingStyling.border' => 'Rand',
			'subtitlingStyling.background' => 'Achtergrond',
			'subtitlingStyling.fontSize' => 'Lettergrootte',
			'subtitlingStyling.textColor' => 'Tekstkleur',
			'subtitlingStyling.borderSize' => 'Randdikte',
			'subtitlingStyling.borderColor' => 'Randkleur',
			'subtitlingStyling.backgroundOpacity' => 'Achtergronddekking',
			'subtitlingStyling.backgroundColor' => 'Achtergrondkleur',
			'subtitlingStyling.position' => 'Positie',
			'subtitlingStyling.assOverride' => 'ASS-overschrijving',
			'subtitlingStyling.overrideScale' => 'Schalen',
			'subtitlingStyling.overrideForce' => 'Forceren',
			'subtitlingStyling.overrideStrip' => 'Opmaak verwijderen',
			'subtitlingStyling.positionTop' => 'Bovenaan',
			'subtitlingStyling.positionBottom' => 'Onderaan',
			'subtitlingStyling.bold' => 'Vet',
			'subtitlingStyling.italic' => 'Cursief',
			'subtitlingStyling.renderResolution' => 'Renderresolutie',
			'subtitlingStyling.renderResolutionScreen' => 'Schermresolutie',
			'subtitlingStyling.renderResolutionVideo' => 'Videoresolutie',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Geavanceerde videospelerinstellingen',
			'mpvConfig.presets' => 'Voorinstellingen',
			'mpvConfig.noPresets' => 'Geen opgeslagen voorinstellingen',
			'mpvConfig.saveAsPreset' => 'Opslaan als voorinstelling...',
			'mpvConfig.presetName' => 'Naam voorinstelling',
			'mpvConfig.presetNameHint' => 'Voer een naam in voor deze voorinstelling',
			'mpvConfig.loadPreset' => 'Laden',
			'mpvConfig.deletePreset' => 'Verwijderen',
			'mpvConfig.presetSaved' => 'Voorinstelling opgeslagen',
			'mpvConfig.presetLoaded' => 'Voorinstelling geladen',
			'mpvConfig.presetDeleted' => 'Voorinstelling verwijderd',
			'mpvConfig.confirmDeletePreset' => 'Weet je zeker dat je deze voorinstelling wilt verwijderen?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comment',
			'dialog.confirmAction' => 'Bevestig actie',
			'profiles.addPlezyProfile' => 'Plezy-profiel toevoegen',
			'profiles.switchingProfile' => 'Profiel wisselen…',
			'profiles.deleteThisProfileTitle' => 'Dit profiel verwijderen?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'Verwijder ${displayName}. Verbindingen blijven ongewijzigd.',
			'profiles.active' => 'Actief',
			'profiles.manage' => 'Beheren',
			'profiles.delete' => 'Verwijderen',
			'profiles.signOut' => 'Afmelden',
			'profiles.signOutPlexTitle' => 'Afmelden bij Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => '${displayName} en alle Plex Home-gebruikers verwijderen? Je kunt altijd opnieuw inloggen.',
			'profiles.signedOutPlex' => 'Afgemeld bij Plex.',
			'profiles.signOutFailed' => 'Afmelden mislukt.',
			'profiles.sectionTitle' => 'Profielen',
			'profiles.summarySingle' => 'Voeg profielen toe om beheerde gebruikers en lokale identiteiten te combineren',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} profielen · actief: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} profielen',
			'profiles.removeConnectionTitle' => 'Verbinding verwijderen?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'Verwijder de toegang van ${displayName} tot ${connectionLabel}. Andere profielen behouden deze toegang.',
			'profiles.deleteProfileTitle' => 'Profiel verwijderen?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'Verwijder ${displayName} en de verbindingen. Servers blijven beschikbaar.',
			'profiles.profileNameLabel' => 'Profielnaam',
			'profiles.pinProtectionLabel' => 'Pincodebeveiliging',
			'profiles.pinManagedByPlex' => 'De pincode wordt beheerd door Plex. Pas deze aan op plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'Geen pincode ingesteld. Bewerk de Plex Home-gebruiker op plex.tv om er een te vereisen.',
			'profiles.setPin' => 'Pincode instellen',
			'profiles.setPinTitle' => 'Pincode instellen',
			'profiles.confirmPinTitle' => 'Pincode bevestigen',
			'profiles.pinSet' => 'Pincode ingesteld',
			'profiles.changePin' => 'Wijzigen',
			'profiles.removePin' => 'Verwijderen',
			'profiles.connectionsLabel' => 'Verbindingen',
			'profiles.add' => 'Toevoegen',
			'profiles.deleteProfileButton' => 'Profiel verwijderen',
			'profiles.noConnectionsHint' => 'Geen verbindingen — voeg er één toe om dit profiel te gebruiken.',
			'profiles.noConnections' => 'Geen verbindingen',
			'profiles.plexHomeAccount' => 'Plex Home-account',
			'profiles.connectionDefault' => 'Standaard',
			'profiles.connectionAs' => ({required Object displayName}) => 'als ${displayName}',
			'profiles.makeDefault' => 'Als standaard instellen',
			'profiles.removeConnection' => 'Verwijderen',
			'profiles.profileRenamed' => 'Profiel hernoemd.',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Toevoegen aan ${displayName}',
			'profiles.borrowExplain' => 'Leen de verbinding van een ander profiel. Voor profielen met pincodebeveiliging is een pincode vereist.',
			'profiles.borrowEmpty' => 'Nog niets te lenen.',
			'profiles.borrowEmptySubtitle' => 'Verbind Plex of Jellyfin eerst met een ander profiel.',
			'profiles.borrowLoadFailed' => 'Beschikbare verbindingen konden niet worden geladen. Probeer het opnieuw.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'Van ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'Verbinding geleend.',
			'profiles.borrowFailed' => 'Kan verbinding niet lenen.',
			'profiles.incorrectPin' => 'Onjuiste pincode.',
			'profiles.incorrectPinTryAgain' => 'Onjuiste pincode. Probeer het opnieuw.',
			'profiles.sourceProfileMissingParentAccount' => 'Het bovenliggende account van het bronprofiel ontbreekt.',
			'profiles.failedToLoadHomeUsers' => 'Je Plex Home-gebruikers konden niet worden geladen. Controleer je verbinding en probeer het opnieuw.',
			'profiles.failedToVerifyPin' => 'De pincode kon niet worden geverifieerd.',
			'profiles.newProfile' => 'Nieuw profiel',
			'profiles.profileNameHint' => 'bijv. Gasten, Kinderen, Woonkamer',
			'profiles.pinProtectionOptional' => 'Pincodebeveiliging (optioneel)',
			'profiles.pinExplain' => 'Een viercijferige pincode is vereist om van profiel te wisselen.',
			'profiles.continueButton' => 'Doorgaan',
			'profiles.pinsDontMatch' => 'De pincodes komen niet overeen',
			'connections.sectionTitle' => 'Verbindingen',
			'connections.addConnection' => 'Verbinding toevoegen',
			'connections.addConnectionSubtitleNoProfile' => 'Meld je aan met Plex of verbind een Jellyfin-server',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Toevoegen aan ${displayName}: Plex, Jellyfin of een andere profielverbinding',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Sessie verlopen voor ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Sessie verlopen voor ${count} servers',
			'connections.signInAgain' => 'Opnieuw aanmelden',
			'connections.editJellyfinTitle' => 'Jellyfin-verbinding bewerken',
			'connections.editJellyfinIntro' => ({required Object serverName}) => 'Voeg URL\'s voor ${serverName} toe of verwijder ze. Plezy gebruikt de bereikbare URL met de laagste latentie.',
			'discover.title' => 'Ontdekken',
			'discover.noContentAvailable' => 'Geen inhoud beschikbaar',
			'discover.addMediaToLibraries' => 'Voeg wat media toe aan je bibliotheken',
			'discover.continueWatching' => 'Verder kijken',
			'discover.continueWatchingIn' => ({required Object library}) => 'Verder kijken in ${library}',
			'discover.nextUp' => 'Volgende',
			'discover.nextUpIn' => ({required Object library}) => 'Volgende in ${library}',
			'discover.recentlyAdded' => 'Recent toegevoegd',
			'discover.recentlyAddedIn' => ({required Object library}) => 'Recent toegevoegd in ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => 'Nieuwste albums in ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'Onlangs afgespeeld in ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'Meest afgespeeld in ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Overzicht',
			'discover.cast' => 'Acteurs',
			'discover.extras' => 'Trailers en extra\'s',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Beoordeling',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'Tv-serie',
			'discover.minutesLeft' => ({required Object minutes}) => 'nog ${minutes} min',
			'discover.moreLikeThis' => 'Meer zoals dit',
			'errors.searchFailed' => ({required Object error}) => 'Zoeken mislukt: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => 'Time-out van verbinding tijdens het laden van ${context}',
			'errors.connectionFailed' => 'Kan geen verbinding maken met mediaserver',
			'errors.unableToLoad' => ({required Object context}) => 'Kan ${context} niet laden. Probeer het opnieuw.',
			'errors.noClientAvailable' => 'Geen client beschikbaar',
			'errors.pleaseEnterToken' => 'Voer een token in',
			'errors.invalidToken' => 'Ongeldig token',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Kon token niet verifiëren: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Kon niet wisselen naar ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'Kon ${displayName} niet verwijderen',
			'errors.failedToRate' => 'Beoordeling kon niet worden bijgewerkt',
			'libraries.title' => 'Bibliotheken',
			'libraries.fallbackTitle' => 'Bibliotheek',
			'libraries.scanLibraryFiles' => 'Bibliotheekbestanden scannen',
			'libraries.scanLibrary' => 'Bibliotheek scannen',
			'libraries.analyze' => 'Analyseren',
			'libraries.analyzeLibrary' => 'Bibliotheek analyseren',
			'libraries.refreshMetadata' => 'Metadata vernieuwen',
			'libraries.emptyTrash' => 'Prullenbak legen',
			'libraries.emptyingTrash' => ({required Object title}) => 'Prullenbak legen voor "${title}"...',
			'libraries.trashEmptied' => ({required Object title}) => 'Prullenbak geleegd voor "${title}"',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Kon prullenbak niet legen: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'Analyseren "${title}"...',
			'libraries.analysisStarted' => ({required Object title}) => 'Analyse gestart voor "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Kon bibliotheek niet analyseren: ${error}',
			'libraries.noLibrariesFound' => 'Geen bibliotheken gevonden',
			'libraries.allLibrariesHidden' => 'Alle bibliotheken zijn verborgen',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Verborgen bibliotheken (${count})',
			'libraries.thisLibraryIsEmpty' => 'Deze bibliotheek is leeg',
			'libraries.noItemsMatchFilters' => 'Geen items komen overeen met de actieve filters',
			'libraries.resetFilters' => 'Filters opnieuw instellen',
			'libraries.all' => 'Alles',
			'libraries.clearAll' => 'Alles wissen',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'Weet je zeker dat je "${title}" wilt scannen?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'Weet je zeker dat je "${title}" wilt analyseren?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'Weet je zeker dat je metadata wilt vernieuwen voor "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'Weet je zeker dat je de prullenbak wilt legen voor "${title}"?',
			'libraries.manageLibraries' => 'Bibliotheken beheren',
			'libraries.sort' => 'Sorteren',
			'libraries.sortBy' => 'Sorteer op',
			'libraries.filters' => 'Filters',
			'libraries.confirmActionMessage' => 'Weet je zeker dat je deze actie wilt uitvoeren?',
			'libraries.showLibrary' => 'Bibliotheek tonen',
			'libraries.hideLibrary' => 'Bibliotheek verbergen',
			'libraries.libraryOptions' => 'Bibliotheekopties',
			'libraries.content' => 'bibliotheekinhoud',
			'libraries.selectLibrary' => 'Bibliotheek kiezen',
			'libraries.filtersWithCount' => ({required Object count}) => 'Filters (${count})',
			'libraries.noRecommendations' => 'Geen aanbevelingen beschikbaar',
			'libraries.noCollections' => 'Geen collecties in deze bibliotheek',
			'libraries.noFoldersFound' => 'Geen mappen gevonden',
			'libraries.folders' => 'mappen',
			'libraries.tabs.recommended' => 'Aanbevolen',
			'libraries.tabs.browse' => 'Bladeren',
			'libraries.tabs.collections' => 'Collecties',
			'libraries.tabs.playlists' => 'Afspeellijsten',
			'libraries.groupings.title' => 'Groepering',
			'libraries.groupings.all' => 'Alles',
			'libraries.groupings.movies' => 'Films',
			'libraries.groupings.shows' => 'Series',
			'libraries.groupings.seasons' => 'Seizoenen',
			'libraries.groupings.episodes' => 'Afleveringen',
			'libraries.groupings.artists' => 'Artiesten',
			'libraries.groupings.albums' => 'Albums',
			'libraries.groupings.tracks' => 'Nummers',
			'libraries.groupings.folders' => 'Mappen',
			'libraries.filterCategories.genre' => 'Genre',
			'libraries.filterCategories.year' => 'Jaar',
			'libraries.filterCategories.contentRating' => 'Leeftijdsclassificatie',
			'libraries.filterCategories.tag' => 'Tag',
			'libraries.filterCategories.unwatched' => 'Onbekeken',
			'libraries.filterCategories.unplayed' => 'Niet afgespeeld',
			'libraries.filterCategories.favorites' => 'Favorieten',
			'libraries.sortLabels.title' => 'Titel',
			'libraries.sortLabels.dateAdded' => 'Toegevoegd op',
			'libraries.sortLabels.releaseDate' => 'Uitgavedatum',
			'libraries.sortLabels.rating' => 'Beoordeling',
			'libraries.sortLabels.communityRating' => 'Beoordeling door community',
			'libraries.sortLabels.criticRating' => 'Beoordeling door critici',
			'libraries.sortLabels.userRating' => 'Gebruikersbeoordeling',
			'libraries.sortLabels.datePlayed' => 'Afspeeldatum',
			'libraries.sortLabels.playCount' => 'Aantal afspelingen',
			'libraries.sortLabels.productionYear' => 'Productiejaar',
			'libraries.sortLabels.runtime' => 'Speelduur',
			'libraries.sortLabels.officialRating' => 'Officiële beoordeling',
			'libraries.sortLabels.premiereDate' => 'Premièredatum',
			'libraries.sortLabels.startDate' => 'Begindatum',
			'libraries.sortLabels.airTime' => 'Uitzendtijd',
			'libraries.sortLabels.studio' => 'Studio',
			'libraries.sortLabels.random' => 'Willekeurig',
			'libraries.sortLabels.dateShared' => 'Gedeeld op',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Laatste afleveringsuitzending',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Datum laatst toegevoegde aflevering',
			'about.title' => 'Over',
			'about.openSourceLicenses' => 'Opensourcelicenties',
			'about.versionLabel' => ({required Object version}) => 'Versie ${version}',
			'about.appDescription' => 'Een mooie Plex- en Jellyfin-client voor Flutter',
			'about.viewLicensesDescription' => 'Licenties van bibliotheken van derden bekijken',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Geen servers gevonden voor ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Kon servers niet laden: ${error}',
			'hubDetail.title' => 'Titel',
			'hubDetail.releaseYear' => 'Uitgavejaar',
			'hubDetail.dateAdded' => 'Datum toegevoegd',
			'hubDetail.rating' => 'Beoordeling',
			'hubDetail.noItemsFound' => 'Geen items gevonden',
			'logs.clearLogs' => 'Logbestanden wissen',
			'logs.copyLogs' => 'Logbestanden kopiëren',
			'logs.uploadLogs' => 'Logbestanden uploaden',
			'licenses.relatedPackages' => 'Gerelateerde pakketten',
			'licenses.license' => 'Licentie',
			'licenses.licenseNumber' => ({required Object number}) => 'Licentie ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licenties',
			'navigation.libraries' => 'Media',
			'navigation.downloads' => 'Downloads',
			'navigation.liveTv' => 'Live-tv',
			'navigation.explore' => 'Verkennen',
			'explore.title' => 'Verkennen',
			'explore.selectSource' => 'Bron kiezen',
			'explore.rows.watchlist' => 'Kijklijst',
			'explore.rows.recommendedMovies' => 'Aanbevolen films',
			'explore.rows.recommendedShows' => 'Aanbevolen series',
			'explore.rows.trendingMovies' => 'Trending films',
			'explore.rows.trendingShows' => 'Trending series',
			'explore.rows.popularMovies' => 'Populaire films',
			'explore.rows.popularShows' => 'Populaire series',
			'explore.rows.trendingAnime' => 'Trending anime',
			'explore.rows.suggestedAnime' => 'Aanbevolen anime',
			'explore.rows.airingAnime' => 'Beste lopende anime',
			'explore.rows.popularAnime' => 'Populairste anime',
			'explore.rows.trending' => 'Trending',
			'explore.rows.upcomingMovies' => 'Aankomende films',
			'explore.rows.upcomingShows' => 'Aankomende series',
			'explore.status.airing' => 'Lopend',
			'explore.status.ended' => 'Afgelopen',
			'explore.status.canceled' => 'Geannuleerd',
			'explore.status.upcoming' => 'Binnenkort',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nl'))(n, one: '${n} aflevering', other: '${n} afleveringen', ), 
			'explore.cast' => 'Acteurs',
			'explore.characters' => 'Personages',
			'explore.addToWatchlist' => 'Toevoegen aan kijklijst',
			'explore.removeFromWatchlist' => 'Verwijderen uit kijklijst',
			'explore.watchlistUpdateFailed' => 'Kon kijklijst niet bijwerken',
			'explore.notInLibrary' => 'Niet in je bibliotheek',
			'explore.inTheseLibraries' => 'In deze bibliotheken',
			'explore.checkingLibrary' => 'Je bibliotheek controleren...',
			'explore.emptyTitle' => 'Hier is nog niets',
			'explore.emptyMessage' => ({required Object source}) => 'Rijen van ${source} verschijnen hier zodra ze inhoud hebben.',
			'explore.searchHint' => ({required Object source}) => 'Zoeken in ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'Geen resultaten voor "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'Zoek naar films en series op ${source}.',
			'explore.searchFailed' => 'Zoeken mislukt. Controleer je verbinding en probeer opnieuw.',
			'liveTv.title' => 'Live-tv',
			'liveTv.guide' => 'Gids',
			'liveTv.noChannels' => 'Geen zenders beschikbaar',
			'liveTv.noDvr' => 'Geen DVR geconfigureerd op een server',
			'liveTv.serverUnavailable' => 'De live-tv-server is niet beschikbaar.',
			'liveTv.serverNotConnected' => 'De live-tv-server is niet verbonden.',
			'liveTv.noPrograms' => 'Geen programmagegevens beschikbaar',
			'liveTv.liveStreamFailed' => 'Livestream mislukt',
			'liveTv.unknownProgram' => 'Onbekend programma',
			'liveTv.unknownHub' => 'Onbekend',
			'liveTv.unknownError' => 'Onbekende fout',
			'liveTv.channelNumber' => ({required Object number}) => 'Kanaal ${number}',
			'liveTv.unknownChannel' => 'Onbekend kanaal',
			'liveTv.live' => 'LIVE',
			'liveTv.reloadGuide' => 'Gids herladen',
			'liveTv.now' => 'Nu',
			'liveTv.today' => 'Vandaag',
			'liveTv.tomorrow' => 'Morgen',
			'liveTv.midnight' => 'Middernacht',
			'liveTv.overnight' => 'Nacht',
			'liveTv.morning' => 'Ochtend',
			'liveTv.daytime' => 'Overdag',
			'liveTv.evening' => 'Avond',
			'liveTv.lateNight' => 'Late avond',
			'liveTv.whatsOn' => 'Nu op tv',
			'liveTv.watchChannel' => 'Kanaal bekijken',
			'liveTv.favorites' => 'Favorieten',
			'liveTv.reorderFavorites' => 'Favorieten herordenen',
			'liveTv.favoritesLoadFailed' => 'Favorieten konden niet worden geladen. Controleer je verbinding en probeer het opnieuw.',
			'liveTv.favoritesUpdateFailed' => 'Favorieten konden niet worden bijgewerkt. Controleer je verbinding en probeer het opnieuw.',
			'liveTv.joinSession' => 'Deelnemen aan lopende sessie',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Vanaf het begin kijken (${minutes} min geleden)',
			'liveTv.watchLive' => 'Live kijken',
			'liveTv.goToLive' => 'Naar live-uitzending',
			'liveTv.record' => 'Opnemen',
			'liveTv.recordEpisode' => 'Aflevering opnemen',
			'liveTv.recordSeries' => 'Serie opnemen',
			'liveTv.recordOptions' => 'Opnameopties',
			'liveTv.saveTo' => 'Opslaan in',
			'liveTv.recordings' => 'Opnames',
			'liveTv.scheduledRecordings' => 'Gepland',
			'liveTv.recordingRules' => 'Opnameregels',
			'liveTv.noScheduledRecordings' => 'Geen geplande opnames',
			'liveTv.manageRecording' => 'Opname beheren',
			'liveTv.cancelRecording' => 'Opname annuleren',
			'liveTv.cancelRecordingTitle' => 'Deze opname annuleren?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} wordt niet meer opgenomen.',
			'liveTv.deleteRule' => 'Regel verwijderen',
			'liveTv.deleteRuleTitle' => 'Opnameregel verwijderen?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'Toekomstige afleveringen van ${title} worden niet opgenomen.',
			'liveTv.recordingScheduled' => 'Opname gepland',
			'liveTv.alreadyScheduled' => 'Dit programma is al gepland',
			'liveTv.dvrAdminRequired' => 'DVR-instellingen vereisen een beheerdersaccount',
			'liveTv.recordingFailed' => 'Kon opname niet plannen',
			'liveTv.recordingTargetMissing' => 'Kon opnamebibliotheek niet bepalen',
			'liveTv.recordNotAvailable' => 'Opname niet beschikbaar voor dit programma',
			'liveTv.recordingCancelled' => 'Opname geannuleerd',
			'liveTv.recordingRuleDeleted' => 'Opnameregel verwijderd',
			'liveTv.processRecordingRules' => 'Regels opnieuw evalueren',
			'liveTv.recordingInProgress' => 'Nu aan het opnemen',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} gepland',
			'liveTv.editRule' => 'Regel bewerken',
			'liveTv.editRuleAction' => 'Bewerken',
			'liveTv.recordingRuleUpdated' => 'Opnameregel bijgewerkt',
			'liveTv.guideReloadRequested' => 'Vernieuwing van de gids aangevraagd',
			'liveTv.rulesProcessRequested' => 'Nieuwe evaluatie van regels aangevraagd',
			'liveTv.recordShow' => 'Programma opnemen',
			'collections.title' => 'Collecties',
			'collections.collection' => 'Collectie',
			'collections.empty' => 'Collectie is leeg',
			'collections.deleteCollection' => 'Collectie verwijderen',
			'collections.deleteConfirm' => ({required Object title}) => '"${title}" verwijderen? Dit kan niet ongedaan worden gemaakt.',
			'collections.deleted' => 'Collectie verwijderd',
			'collections.deleteFailed' => 'Collectie verwijderen mislukt',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Collectie verwijderen mislukt: ${error}',
			'collections.selectCollection' => 'Collectie selecteren',
			'collections.collectionName' => 'Collectienaam',
			'collections.enterCollectionName' => 'Voer een collectienaam in',
			'collections.addedToCollection' => 'Toegevoegd aan collectie',
			'collections.errorAddingToCollection' => 'Fout bij toevoegen aan collectie',
			'collections.created' => 'Collectie gemaakt',
			'collections.removeFromCollection' => 'Verwijderen uit collectie',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => '"${title}" uit deze collectie verwijderen?',
			'collections.removedFromCollection' => 'Uit collectie verwijderd',
			'collections.removeFromCollectionFailed' => 'Verwijderen uit collectie mislukt',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Fout bij verwijderen uit collectie: ${error}',
			'collections.searchCollections' => 'Collecties zoeken...',
			'playlists.title' => 'Afspeellijsten',
			'playlists.playlist' => 'Afspeellijst',
			'playlists.noPlaylists' => 'Geen afspeellijsten gevonden',
			'playlists.create' => 'Afspeellijst maken',
			'playlists.playlistName' => 'Naam van de afspeellijst',
			'playlists.enterPlaylistName' => 'Voer een naam voor de afspeellijst in',
			'playlists.delete' => 'Afspeellijst verwijderen',
			'playlists.removeItem' => 'Verwijderen uit afspeellijst',
			'playlists.smartPlaylist' => 'Slimme afspeellijst',
			'playlists.itemCount' => ({required Object count}) => '${count} items',
			'playlists.oneItem' => '1 item',
			'playlists.emptyPlaylist' => 'Deze afspeellijst is leeg',
			'playlists.deleteConfirm' => 'Afspeellijst verwijderen?',
			'playlists.deleteMessage' => ({required Object name}) => 'Weet je zeker dat je "${name}" wilt verwijderen?',
			'playlists.created' => 'Afspeellijst gemaakt',
			'playlists.deleted' => 'Afspeellijst verwijderd',
			'playlists.itemAdded' => 'Toegevoegd aan afspeellijst',
			'playlists.itemRemoved' => 'Verwijderd uit afspeellijst',
			'playlists.selectPlaylist' => 'Afspeellijst selecteren',
			'playlists.searchPlaylists' => 'Afspeellijsten zoeken...',
			'playlists.errorCreating' => 'Afspeellijst maken mislukt',
			'playlists.errorDeleting' => 'Afspeellijst verwijderen mislukt',
			'playlists.errorLoading' => 'Afspeellijsten laden mislukt',
			'playlists.errorAdding' => 'Toevoegen aan afspeellijst mislukt',
			'playlists.errorReordering' => 'Afspeellijstitem herschikken mislukt',
			'playlists.errorRemoving' => 'Verwijderen uit afspeellijst mislukt',
			'music.goToAlbum' => 'Ga naar album',
			'music.goToArtist' => 'Ga naar artiest',
			'music.instantMix' => 'Instantmix',
			'music.playNext' => 'Hierna afspelen',
			'music.addToQueue' => 'Toevoegen aan wachtrij',
			'music.discNumber' => ({required Object n}) => 'Schijf ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nl'))(n, one: '${n} nummer', other: '${n} nummers', ), 
			'music.nowPlaying' => 'Nu afspelen',
			'music.playingFrom' => ({required Object title}) => 'Afspelen vanaf ${title}',
			'music.queue' => 'Wachtrij',
			'music.clearQueue' => 'Wachtrij wissen',
			'music.lyrics' => 'Songtekst',
			'music.noLyrics' => 'Geen songtekst beschikbaar',
			'music.sleepTimer' => 'Slaaptimer',
			'music.sleepTimerEndOfTrack' => 'Einde van nummer',
			'music.sleepTimerMinutes' => ({required Object n}) => '${n} minuten',
			'music.stopPlayback' => 'Afspelen stoppen',
			'music.previousTrack' => 'Vorig nummer',
			'music.nextTrack' => 'Volgend nummer',
			'music.repeat' => 'Herhalen',
			'music.repeatAll' => 'Alles herhalen',
			'music.repeatOne' => 'Eén herhalen',
			'watchTogether.title' => 'Samen kijken',
			'watchTogether.description' => 'Kijk synchroon met vrienden en familie',
			'watchTogether.createSession' => 'Sessie maken',
			'watchTogether.creating' => 'Sessie maken...',
			'watchTogether.joinSession' => 'Deelnemen aan sessie',
			'watchTogether.joining' => 'Deelnemen...',
			'watchTogether.controlMode' => 'Bedieningsmodus',
			'watchTogether.controlModeQuestion' => 'Wie kan het afspelen bedienen?',
			'watchTogether.hostOnly' => 'Alleen host',
			'watchTogether.anyone' => 'Iedereen',
			'watchTogether.hostingSession' => 'Sessie hosten',
			'watchTogether.inSession' => 'In sessie',
			'watchTogether.sessionCode' => 'Sessiecode',
			'watchTogether.openSessionControls' => 'Bediening voor Samen kijken openen',
			'watchTogether.copySessionCode' => 'Sessiecode kopiëren',
			'watchTogether.hostControlsPlayback' => 'Host bedient het afspelen',
			'watchTogether.anyoneCanControl' => 'Iedereen kan het afspelen bedienen',
			'watchTogether.hostControls' => 'Host bedient',
			'watchTogether.anyoneControls' => 'Iedereen bedient',
			'watchTogether.participants' => 'Deelnemers',
			'watchTogether.host' => 'Host',
			'watchTogether.hostBadge' => 'HOST',
			'watchTogether.youAreHost' => 'Jij bent de host',
			'watchTogether.watchingWithOthers' => 'Kijken met anderen',
			'watchTogether.endSession' => 'Sessie beëindigen',
			'watchTogether.leaveSession' => 'Sessie verlaten',
			'watchTogether.endSessionQuestion' => 'Sessie beëindigen?',
			'watchTogether.leaveSessionQuestion' => 'Sessie verlaten?',
			'watchTogether.endSessionConfirm' => 'Dit beëindigt de sessie voor alle deelnemers.',
			'watchTogether.leaveSessionConfirm' => 'Je wordt uit de sessie verwijderd.',
			'watchTogether.endSessionConfirmOverlay' => 'Dit beëindigt de kijksessie voor alle deelnemers.',
			'watchTogether.leaveSessionConfirmOverlay' => 'Je wordt losgekoppeld van de kijksessie.',
			'watchTogether.end' => 'Beëindigen',
			'watchTogether.leave' => 'Verlaten',
			'watchTogether.syncing' => 'Synchroniseren...',
			'watchTogether.joinWatchSession' => 'Deelnemen aan kijksessie',
			'watchTogether.enterCodeHint' => 'Voer de code van 5 tekens in',
			'watchTogether.pasteFromClipboard' => 'Plakken vanaf klembord',
			'watchTogether.pleaseEnterCode' => 'Voer een sessiecode in',
			'watchTogether.codeMustBe5Chars' => 'De sessiecode moet 5 tekens lang zijn',
			'watchTogether.joinInstructions' => 'Voer de sessiecode van de host in om deel te nemen.',
			'watchTogether.failedToCreate' => 'Sessie maken mislukt',
			'watchTogether.failedToJoin' => 'Deelnemen aan sessie mislukt',
			'watchTogether.sessionCodeCopied' => 'Sessiecode naar het klembord gekopieerd',
			'watchTogether.relayUnreachable' => 'De relayserver is onbereikbaar. Een blokkering door je internetprovider kan Samen kijken verhinderen.',
			'watchTogether.reconnectingToHost' => 'Opnieuw verbinden met host...',
			'watchTogether.currentPlayback' => 'Wat nu wordt afgespeeld',
			'watchTogether.joinCurrentPlayback' => 'Deelnemen aan huidige weergave',
			'watchTogether.joinCurrentPlaybackDescription' => 'Ga terug naar wat de host nu kijkt',
			'watchTogether.failedToOpenCurrentPlayback' => 'Wat nu wordt afgespeeld kon niet worden geopend',
			_ => null,
		} ?? switch (path) {
			'watchTogether.participantJoined' => ({required Object name}) => '${name} is toegetreden',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} heeft de sessie verlaten',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} heeft gepauzeerd',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} heeft hervat',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} heeft de afspeelpositie gewijzigd',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} is aan het bufferen',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name} gebruikt een oudere appversie — synchronisatie niet beschikbaar',
			'watchTogether.resumingWithout' => ({required Object name}) => 'Hervatten zonder ${name}',
			'watchTogether.waitingForParticipants' => 'Wachten tot anderen klaar zijn met laden...',
			'watchTogether.waitingForName' => ({required Object name}) => 'Wachten op ${name}...',
			'watchTogether.recentRooms' => 'Recente kamers',
			'watchTogether.renameRoom' => 'Kamer hernoemen',
			'watchTogether.removeRoom' => 'Verwijderen',
			'watchTogether.guestSwitchUnavailable' => 'Kon niet schakelen — server niet beschikbaar voor synchronisatie',
			'watchTogether.guestSwitchFailed' => 'Kon niet schakelen — inhoud niet gevonden op deze server',
			'downloads.title' => 'Downloads',
			'downloads.manage' => 'Beheren',
			'downloads.tvShows' => 'Series',
			'downloads.movies' => 'Films',
			'downloads.music' => 'Muziek',
			'downloads.tracksQueued' => ({required Object count}) => '${count} nummers in wachtrij voor download',
			'downloads.noDownloads' => 'Nog geen downloads',
			'downloads.noDownloadsDescription' => 'Gedownloade inhoud verschijnt hier om offline te bekijken',
			'downloads.downloadNow' => 'Downloaden',
			'downloads.deleteDownload' => 'Download verwijderen',
			'downloads.retryDownload' => 'Download opnieuw proberen',
			'downloads.downloadQueued' => 'Download in wachtrij',
			'downloads.downloadResumed' => 'Download hervat',
			'downloads.serverErrorBitrate' => 'Serverfout: bestand overschrijdt mogelijk de externe bitrate-limiet',
			'downloads.storageFull' => 'Downloads zijn gestopt omdat de opslag van het apparaat vol is. Maak ruimte vrij en probeer het opnieuw.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} afleveringen in wachtrij voor download',
			'downloads.downloadDeleted' => 'Download verwijderd',
			'downloads.deleteConfirm' => ({required Object title}) => '"${title}" van dit apparaat verwijderen?',
			'downloads.cancelledDownloadTitle' => 'Geannuleerde download',
			'downloads.cancelledDownloadMessage' => 'Deze download is geannuleerd. Wat wil je doen?',
			'downloads.allEpisodesAlreadyDownloaded' => 'Alle afleveringen zijn al gedownload',
			'downloads.resumeDownload' => 'Download hervatten',
			'downloads.cancelledDownload' => 'Geannuleerde download',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (${status} synchroniseren)',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => '${file} gedownload — klik om te voltooien',
			'downloads.partialDownloadClickToComplete' => 'Gedeeltelijk gedownload — klik om te voltooien',
			'downloads.deleting' => 'Verwijderen...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Verwijderen van ${title}... (${current} van ${total})',
			'downloads.queuedTooltip' => 'In wachtrij',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'In wachtrij: ${files}',
			'downloads.downloadingTooltip' => 'Downloaden...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'Downloaden ${files}',
			'downloads.noDownloadsTree' => 'Geen downloads',
			'downloads.pauseAll' => 'Alles pauzeren',
			'downloads.resumeAll' => 'Alles hervatten',
			'downloads.deleteAll' => 'Alles verwijderen',
			'downloads.selectVersion' => 'Versie selecteren',
			'downloads.allEpisodes' => 'Alle afleveringen',
			'downloads.unwatchedOnly' => 'Alleen ongekeken afleveringen',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Volgende ${count} ongekeken afleveringen',
			'downloads.customAmount' => 'Aangepast aantal...',
			'downloads.includeSpecials' => 'Specials meenemen',
			'downloads.howManyEpisodes' => 'Hoeveel afleveringen?',
			'downloads.invalidEpisodeCount' => 'Voer een geldig aantal afleveringen in.',
			'downloads.keepSynced' => 'Gesynchroniseerd houden',
			'downloads.downloadOnce' => 'Eenmalig downloaden',
			'downloads.keepNUnwatched' => ({required Object count}) => '${count} ongekeken afleveringen behouden',
			'downloads.editSyncRule' => 'Synchronisatieregel bewerken',
			'downloads.removeSyncRule' => 'Synchronisatieregel verwijderen',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'Synchronisatie van "${title}" stoppen? Gedownloade afleveringen worden behouden.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Synchronisatieregel aangemaakt — ${count} onbekeken afleveringen behouden',
			'downloads.syncRuleUpdated' => 'Synchronisatieregel bijgewerkt',
			'downloads.syncRuleRemoved' => 'Synchronisatieregel verwijderd',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => '${count} nieuwe afleveringen gesynchroniseerd voor ${title}',
			'downloads.activeSyncRules' => 'Synchronisatieregels',
			'downloads.noSyncRules' => 'Geen synchronisatieregels',
			'downloads.manageSyncRule' => 'Synchronisatie beheren',
			'downloads.editEpisodeCount' => 'Aantal afleveringen',
			'downloads.editSyncFilter' => 'Synchronisatiefilter',
			'downloads.syncAllItems' => 'Alle items synchroniseren',
			'downloads.syncUnwatchedItems' => 'Ongekeken items synchroniseren',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Server: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Beschikbaar',
			'downloads.syncRuleOffline' => 'Offline',
			'downloads.syncRuleSignInRequired' => 'Inloggen vereist',
			'downloads.syncRuleNotAvailableForProfile' => 'Niet beschikbaar voor huidig profiel',
			'downloads.syncRuleUnknownServer' => 'Onbekende server',
			'downloads.syncRuleListCreated' => 'Synchronisatieregel aangemaakt',
			'shaders.title' => 'Shaders',
			'shaders.noShaderDescription' => 'Geen videoverbetering',
			'shaders.nvscalerDescription' => 'NVIDIA-beeldschaling voor scherpere video',
			'shaders.artcnnVariantNeutral' => 'Neutraal',
			'shaders.artcnnVariantDenoise' => 'Ruisonderdrukking',
			'shaders.artcnnVariantDenoiseSharpen' => 'Ruisonderdrukking + verscherpen',
			'shaders.qualityFast' => 'Snel',
			'shaders.qualityHQ' => 'Hoge kwaliteit',
			'shaders.mode' => 'Modus',
			'shaders.importShader' => 'Shader importeren',
			'shaders.customShaderDescription' => 'Aangepaste GLSL-shader',
			'shaders.shaderImported' => 'Shader geïmporteerd',
			'shaders.shaderImportFailed' => 'Shader importeren mislukt',
			'shaders.deleteShader' => 'Shader verwijderen',
			'shaders.deleteShaderConfirm' => ({required Object name}) => '"${name}" verwijderen?',
			'companionRemote.title' => 'Afstandsbediening',
			'companionRemote.connectedTo' => ({required Object name}) => 'Verbonden met ${name}',
			'companionRemote.unknownDevice' => 'Onbekend apparaat',
			'companionRemote.session.startingServer' => 'Externe server starten...',
			'companionRemote.session.hostAddress' => 'Hostadres',
			'companionRemote.session.connected' => 'Verbonden',
			'companionRemote.session.serverRunning' => 'Externe server actief',
			'companionRemote.session.serverStopped' => 'Externe server gestopt',
			'companionRemote.session.serverRunningDescription' => 'Mobiele apparaten op je netwerk kunnen met deze app verbinden',
			'companionRemote.session.serverStoppedDescription' => 'Start de server om mobiele apparaten te laten verbinden',
			'companionRemote.session.usePhoneToControl' => 'Gebruik je mobiele apparaat om deze app te bedienen',
			'companionRemote.session.startServer' => 'Server starten',
			'companionRemote.session.stopServer' => 'Server stoppen',
			'companionRemote.session.minimize' => 'Minimaliseren',
			'companionRemote.pairing.discoveryDescription' => 'Plezy-apparaten met hetzelfde Plex-account verschijnen hier',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Verbinden...',
			'companionRemote.pairing.searchingForDevices' => 'Apparaten zoeken...',
			'companionRemote.pairing.noDevicesFound' => 'Geen apparaten gevonden op je netwerk',
			'companionRemote.pairing.noDevicesHint' => 'Open Plezy op je desktop en gebruik op beide apparaten dezelfde wifi',
			'companionRemote.pairing.availableDevices' => 'Beschikbare apparaten',
			'companionRemote.pairing.manualConnection' => 'Handmatige verbinding',
			'companionRemote.pairing.cryptoInitFailed' => 'Kon beveiligde verbinding niet starten. Log eerst in bij Plex.',
			'companionRemote.pairing.validationHostRequired' => 'Voer het hostadres in',
			'companionRemote.pairing.validationHostFormat' => 'Formaat moet IP:poort zijn (bijv. 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Er is een time-out opgetreden. Gebruik op beide apparaten hetzelfde netwerk.',
			'companionRemote.pairing.sessionNotFound' => 'Apparaat niet gevonden. Zorg dat Plezy op de host draait.',
			'companionRemote.pairing.authFailed' => 'Authenticatie mislukt. Beide apparaten hebben hetzelfde Plex-account nodig.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Kan niet verbinden: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'Wil je de verbinding met de externe sessie verbreken?',
			'companionRemote.remote.reconnecting' => 'Opnieuw verbinden...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Poging ${current} van 5',
			'companionRemote.remote.retryNow' => 'Nu opnieuw proberen',
			'companionRemote.remote.tabRemote' => 'Afstandsbediening',
			'companionRemote.remote.tabPlay' => 'Afspelen',
			'companionRemote.remote.tabMore' => 'Meer',
			'companionRemote.remote.menu' => 'Menu',
			'companionRemote.remote.tabNavigation' => 'Tabnavigatie',
			'companionRemote.remote.tabDiscover' => 'Ontdekken',
			'companionRemote.remote.tabLibraries' => 'Bibliotheken',
			'companionRemote.remote.tabSearch' => 'Zoeken',
			'companionRemote.remote.tabDownloads' => 'Downloads',
			'companionRemote.remote.tabSettings' => 'Instellingen',
			'companionRemote.remote.previous' => 'Vorige',
			'companionRemote.remote.playPause' => 'Afspelen/Pauzeren',
			'companionRemote.remote.next' => 'Volgende',
			'companionRemote.remote.seekBack' => 'Terugspoelen',
			'companionRemote.remote.stop' => 'Stoppen',
			'companionRemote.remote.seekForward' => 'Vooruitspoelen',
			'companionRemote.remote.volume' => 'Volume',
			'companionRemote.remote.volumeDown' => 'Omlaag',
			'companionRemote.remote.volumeUp' => 'Omhoog',
			'companionRemote.remote.fullscreen' => 'Volledig scherm',
			'companionRemote.remote.subtitles' => 'Ondertitels',
			'companionRemote.remote.audio' => 'Audio',
			'companionRemote.remote.searchHint' => 'Zoeken op desktop...',
			'companionRemote.errors.noNetworkInterface' => 'Geen netwerkinterface gevonden',
			'companionRemote.errors.authenticationFailed' => 'Authenticatie mislukt',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'Externe server starten mislukt: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'Externe opdracht verzenden mislukt: ${error}',
			'companionRemote.errors.joinTimedOut' => 'Time-out bij deelnemen aan sessie',
			'companionRemote.errors.failedToConnectAnyAddress' => 'Er kon met geen enkel adres verbinding worden gemaakt',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'Verbinding verbroken na ${attempts} pogingen',
			'companionRemote.errors.connectionLost' => 'Verbinding verloren',
			'videoSettings.playbackSpeed' => 'Afspeelsnelheid',
			'videoSettings.normalSpeed' => 'Normaal',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Actief (${duration})',
			'videoSettings.zoom' => 'Zoom',
			'videoSettings.sleepTimer' => 'Slaaptimer',
			'videoSettings.audioSync' => 'Audiosynchronisatie',
			'videoSettings.subtitleSync' => 'Ondertitelsynchronisatie',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => 'Audio-uitvoer',
			'videoSettings.performanceOverlay' => 'Prestatie-overlay',
			'videoSettings.audioPassthrough' => 'Audio-doorvoer',
			'videoSettings.audioNormalization' => 'Volume normaliseren',
			'videoSettings.audioDownmix' => 'Downmixen naar stereo',
			'performanceOverlay.color' => 'Kleur',
			'performanceOverlay.performance' => 'Prestaties',
			'performanceOverlay.buffer' => 'Buffer',
			'performanceOverlay.app' => 'App',
			'performanceOverlay.decoder' => 'Decoder',
			'performanceOverlay.rawDecoder' => 'Raw-decoder',
			'performanceOverlay.tunneling' => 'Tunneling',
			'performanceOverlay.aspect' => 'Verhouding',
			'performanceOverlay.rotation' => 'Rotatie',
			'performanceOverlay.dvSource' => 'DV-bron',
			'performanceOverlay.dvPath' => 'DV-pad',
			'performanceOverlay.p7Conversion' => 'P7-conv.',
			'performanceOverlay.sampleRate' => 'Samplefrequentie',
			'performanceOverlay.pixelFormat' => 'Pixelformaat',
			'performanceOverlay.hwFormat' => 'HW-formaat',
			'performanceOverlay.matrix' => 'Matrix',
			'performanceOverlay.primaries' => 'Primaire kleuren',
			'performanceOverlay.transfer' => 'Overdracht',
			'performanceOverlay.renderFps' => 'Render-FPS',
			'performanceOverlay.displayFps' => 'Scherm-FPS',
			'performanceOverlay.avSync' => 'A/V-sync',
			'performanceOverlay.dropped' => 'Gedropt',
			'performanceOverlay.dvRpus' => 'DV RPU’s',
			'performanceOverlay.dvRpuAverage' => 'DV RPU gem.',
			'performanceOverlay.dvSampleAverage' => 'DV-sample gem.',
			'performanceOverlay.maxLuma' => 'Max luma',
			'performanceOverlay.minLuma' => 'Min luma',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Cache gebruikt',
			'performanceOverlay.cacheLimit' => 'Cachelimiet',
			'performanceOverlay.speed' => 'Snelheid',
			'performanceOverlay.player' => 'Speler',
			'performanceOverlay.memory' => 'Geheugen',
			'performanceOverlay.uiFps' => 'UI FPS',
			'externalPlayer.title' => 'Externe speler',
			'externalPlayer.useExternalPlayer' => 'Externe speler gebruiken',
			'externalPlayer.useExternalPlayerDescription' => 'Open video\'s in een andere app',
			'externalPlayer.selectPlayer' => 'Speler selecteren',
			'externalPlayer.customPlayers' => 'Aangepaste spelers',
			'externalPlayer.systemDefault' => 'Systeemstandaard',
			'externalPlayer.addCustomPlayer' => 'Aangepaste speler toevoegen',
			'externalPlayer.playerName' => 'Spelernaam',
			'externalPlayer.playerNameHint' => 'Mijn speler',
			'externalPlayer.playerCommand' => 'Commando',
			'externalPlayer.playerPackage' => 'Pakketnaam',
			'externalPlayer.playerUrlScheme' => 'URL-schema',
			'externalPlayer.off' => 'Uit',
			'externalPlayer.launchFailed' => 'Kan externe speler niet openen',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} is niet geïnstalleerd',
			'externalPlayer.playInExternalPlayer' => 'Afspelen in externe speler',
			'metadataEdit.editMetadata' => 'Bewerken...',
			'metadataEdit.screenTitle' => 'Metadata bewerken',
			'metadataEdit.basicInfo' => 'Basisinformatie',
			'metadataEdit.artwork' => 'Illustraties',
			'metadataEdit.advancedSettings' => 'Geavanceerde instellingen',
			'metadataEdit.title' => 'Titel',
			'metadataEdit.sortTitle' => 'Sorteertitel',
			'metadataEdit.originalTitle' => 'Oorspronkelijke titel',
			'metadataEdit.releaseDate' => 'Releasedatum',
			'metadataEdit.contentRating' => 'Leeftijdsclassificatie',
			'metadataEdit.studio' => 'Studio',
			'metadataEdit.tagline' => 'Slogan',
			'metadataEdit.summary' => 'Samenvatting',
			'metadataEdit.poster' => 'Poster',
			'metadataEdit.background' => 'Achtergrond',
			'metadataEdit.logo' => 'Logo',
			'metadataEdit.squareArt' => 'Vierkante afbeelding',
			'metadataEdit.selectPoster' => 'Poster selecteren',
			'metadataEdit.selectBackground' => 'Achtergrond selecteren',
			'metadataEdit.selectLogo' => 'Logo selecteren',
			'metadataEdit.selectSquareArt' => 'Vierkante afbeelding selecteren',
			'metadataEdit.fromUrl' => 'Vanaf URL',
			'metadataEdit.uploadFile' => 'Bestand uploaden',
			'metadataEdit.enterImageUrl' => 'Voer de afbeeldings-URL in',
			'metadataEdit.imageUrl' => 'Afbeeldings-URL',
			'metadataEdit.metadataUpdated' => 'Metadata bijgewerkt',
			'metadataEdit.metadataUpdateFailed' => 'Metadata bijwerken mislukt',
			'metadataEdit.artworkUpdated' => 'Illustraties bijgewerkt',
			'metadataEdit.artworkUpdateFailed' => 'Illustraties bijwerken mislukt',
			'metadataEdit.noArtworkAvailable' => 'Geen illustraties beschikbaar',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Illustratie ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Illustratie ${index}, geselecteerd',
			'metadataEdit.notSet' => 'Niet ingesteld',
			'metadataEdit.libraryDefault' => 'Standaard van de bibliotheek',
			'metadataEdit.accountDefault' => 'Standaard van het account',
			'metadataEdit.seriesDefault' => 'Standaard van de serie',
			'metadataEdit.episodeSorting' => 'Afleveringen sorteren',
			'metadataEdit.oldestFirst' => 'Oudste eerst',
			'metadataEdit.newestFirst' => 'Nieuwste eerst',
			'metadataEdit.keep' => 'Bewaren',
			'metadataEdit.allEpisodes' => 'Alle afleveringen',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} nieuwste afleveringen',
			'metadataEdit.latestEpisode' => 'Nieuwste aflevering',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Afleveringen toegevoegd in de afgelopen ${count} dagen',
			'metadataEdit.deleteAfterPlaying' => 'Afleveringen verwijderen na afspelen',
			'metadataEdit.never' => 'Nooit',
			'metadataEdit.afterADay' => 'Na een dag',
			'metadataEdit.afterAWeek' => 'Na een week',
			'metadataEdit.afterAMonth' => 'Na een maand',
			'metadataEdit.onNextRefresh' => 'Bij volgende verversing',
			'metadataEdit.seasons' => 'Seizoenen',
			'metadataEdit.show' => 'Tonen',
			'metadataEdit.hide' => 'Verbergen',
			'metadataEdit.episodeOrdering' => 'Afleveringsvolgorde',
			'metadataEdit.tmdbAiring' => 'The Movie Database (Uitgezonden)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (Uitgezonden)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (Absoluut)',
			'metadataEdit.metadataLanguage' => 'Metadatataal',
			'metadataEdit.useOriginalTitle' => 'Oorspronkelijke titel gebruiken',
			'metadataEdit.preferredAudioLanguage' => 'Voorkeurstaal voor audio',
			'metadataEdit.preferredSubtitleLanguage' => 'Voorkeurstaal voor ondertitels',
			'metadataEdit.subtitleMode' => 'Automatische ondertitelselectie',
			'metadataEdit.manuallySelected' => 'Handmatig geselecteerd',
			'metadataEdit.shownWithForeignAudio' => 'Weergeven bij anderstalig geluid',
			'metadataEdit.alwaysEnabled' => 'Altijd ingeschakeld',
			'metadataEdit.tags' => 'Tags',
			'metadataEdit.addTag' => 'Tag toevoegen',
			'metadataEdit.genre' => 'Genre',
			'metadataEdit.director' => 'Regisseur',
			'metadataEdit.writer' => 'Schrijver',
			'metadataEdit.producer' => 'Producent',
			'metadataEdit.country' => 'Land',
			'metadataEdit.collection' => 'Collectie',
			'metadataEdit.label' => 'Label',
			'metadataEdit.style' => 'Stijl',
			'metadataEdit.mood' => 'Stemming',
			'matchScreen.match' => 'Koppelen...',
			'matchScreen.fixMatch' => 'Koppeling herstellen...',
			'matchScreen.unmatch' => 'Ontkoppelen',
			'matchScreen.unmatchConfirm' => 'Deze koppeling wissen? Plex behandelt het item als niet-gekoppeld totdat het opnieuw wordt gekoppeld.',
			'matchScreen.unmatchSuccess' => 'Item ontkoppeld',
			'matchScreen.unmatchFailed' => 'Kon item niet ontkoppelen',
			'matchScreen.matchApplied' => 'Koppeling toegepast',
			'matchScreen.matchFailed' => 'Koppeling kon niet worden toegepast',
			'matchScreen.titleHint' => 'Titel',
			'matchScreen.yearHint' => 'Jaar',
			'matchScreen.search' => 'Zoeken',
			'matchScreen.noMatchesFound' => 'Geen overeenkomsten gevonden',
			'serverTasks.title' => 'Servertaken',
			'serverTasks.failedToLoad' => 'Taken konden niet worden geladen',
			'serverTasks.noTasks' => 'Geen actieve taken',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Verbonden',
			'trakt.connectedAs' => ({required Object username}) => 'Verbonden als @${username}',
			'trakt.disconnectConfirm' => 'Trakt-account loskoppelen?',
			'trakt.disconnectConfirmBody' => 'Plezy stuurt geen gebeurtenissen meer naar Trakt. Je kunt op elk moment opnieuw verbinding maken.',
			'trakt.scrobble' => 'Realtime scrobblen',
			'trakt.scrobbleDescription' => 'Stuur tijdens het afspelen gebeurtenissen voor afspelen, pauzeren en stoppen naar Trakt.',
			'trakt.watchedSync' => 'Kijkstatus synchroniseren',
			'trakt.watchedSyncDescription' => 'Wanneer je items in Plezy als bekeken markeert, worden ze op Trakt ook als bekeken gemarkeerd.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Verbinden met Seerr',
			'seerr.serverUrl' => 'Server-URL',
			'seerr.serverUrlHelper' => 'Het adres van je Seerr-instantie',
			'seerr.checkServer' => 'Doorgaan',
			'seerr.signInWithJellyfin' => 'Inloggen met Jellyfin',
			'seerr.signInWithEmby' => 'Inloggen met Emby',
			'seerr.signInWithLocal' => 'Een lokaal account gebruiken',
			'seerr.email' => 'E-mail',
			'seerr.noSignInMethods' => 'Deze Seerr-instantie biedt geen inlogmethode die Plezy ondersteunt.',
			'seerr.instance' => 'Instantie',
			'seerr.disconnectConfirm' => 'Seerr loskoppelen?',
			'seerr.disconnectConfirmBody' => 'Plezy vergeet deze Seerr-instantie. Je kunt altijd opnieuw verbinden.',
			'seerr.request' => 'Aanvragen',
			'seerr.request4k' => 'Aanvragen in 4K',
			'seerr.seasons' => 'Seizoenen',
			'seerr.allSeasons' => 'Alle seizoenen',
			'seerr.advancedOptions' => 'Geavanceerd',
			'seerr.destinationServer' => 'Doelserver',
			'seerr.qualityProfile' => 'Kwaliteitsprofiel',
			'seerr.rootFolder' => 'Hoofdmap',
			'seerr.languageProfile' => 'Taalprofiel',
			'seerr.requestSubmitted' => 'Aanvraag verzonden',
			'seerr.requestFailed' => ({required Object error}) => 'Aanvraag mislukt: ${error}',
			'seerr.requestsLoadFailed' => 'Aanvraagopties konden niet worden geladen',
			'seerr.nothingToRequest' => 'Alles is al beschikbaar of aangevraagd.',
			'seerr.statusAvailable' => 'Beschikbaar',
			'seerr.statusPartiallyAvailable' => 'Gedeeltelijk beschikbaar',
			'seerr.statusRequested' => 'Aangevraagd',
			'seerr.statusProcessing' => 'Verwerken',
			'services.title' => 'Diensten',
			'services.hubSubtitle' => 'Synchroniseer kijkvoortgang en vraag nieuwe titels aan.',
			'services.notConnected' => 'Niet verbonden',
			'services.connectedAs' => ({required Object username}) => 'Verbonden als @${username}',
			'services.scrobble' => 'Voortgang automatisch volgen',
			'services.scrobbleDescription' => 'Werk je lijst bij wanneer je een aflevering of film afrondt.',
			'services.disconnectConfirm' => ({required Object service}) => '${service} loskoppelen?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'Plezy werkt ${service} niet meer bij. Je kunt op elk moment opnieuw verbinding maken.',
			'services.connectFailed' => ({required Object service}) => 'Verbinding maken met ${service} is mislukt. Probeer het opnieuw.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.deviceCode.title' => ({required Object service}) => 'Plezy activeren op ${service}',
			'services.deviceCode.body' => ({required Object url}) => 'Ga naar ${url} en voer deze code in:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Open ${service} om te activeren',
			'services.deviceCode.copyCode' => 'Activeringscode kopiëren',
			'services.deviceCode.waitingForAuthorization' => 'Wachten op autorisatie…',
			'services.deviceCode.codeCopied' => 'Code gekopieerd',
			'services.oauthProxy.title' => ({required Object service}) => 'Aanmelden bij ${service}',
			'services.oauthProxy.body' => 'Scan deze QR-code of open de URL op een apparaat.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => '${service} openen om aan te melden',
			'services.oauthProxy.copyUrl' => 'Aanmeldings-URL kopiëren',
			'services.oauthProxy.urlCopied' => 'URL gekopieerd',
			'services.libraryFilter.title' => 'Bibliotheekfilter',
			'services.libraryFilter.subtitleAllSyncing' => 'Alle bibliotheken synchroniseren',
			'services.libraryFilter.subtitleNoneSyncing' => 'Niets wordt gesynchroniseerd',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} geblokkeerd',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} toegestaan',
			'services.libraryFilter.mode' => 'Filtermodus',
			'services.libraryFilter.modeBlacklist' => 'Blokkeerlijst',
			'services.libraryFilter.modeWhitelist' => 'Toelatingslijst',
			'services.libraryFilter.modeHintBlacklist' => 'Synchroniseer alle bibliotheken behalve de hieronder aangevinkte.',
			'services.libraryFilter.modeHintWhitelist' => 'Synchroniseer alleen de hieronder aangevinkte bibliotheken.',
			'services.libraryFilter.libraries' => 'Bibliotheken',
			'services.libraryFilter.noLibraries' => 'Geen bibliotheken beschikbaar',
			'addServer.addJellyfinTitle' => 'Jellyfin-server toevoegen',
			'addServer.serverUrls' => 'Server-URL\'s',
			'addServer.serverUrlsHelper' => 'Meerdere URL\'s toegestaan, gescheiden door komma\'s.',
			'addServer.findServer' => 'Server zoeken',
			'addServer.searchingLocalServers' => 'Lokale Jellyfin-servers zoeken...',
			'addServer.localServers' => 'Lokale Jellyfin-servers',
			'addServer.username' => 'Gebruikersnaam',
			'addServer.password' => 'Wachtwoord',
			'addServer.signIn' => 'Inloggen',
			'addServer.change' => 'Wijzigen',
			'addServer.required' => 'Vereist',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Kon de server niet bereiken: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Inloggen mislukt: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect mislukt: ${error}',
			'addServer.addPlexTitle' => 'Inloggen met Plex',
			'addServer.pinExpired' => 'De pincode verliep voordat je kon inloggen. Probeer het opnieuw.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Account registreren mislukt: ${error}',
			'addServer.enterJellyfinUrlError' => 'Voer de URL van je Jellyfin-server in',
			'addServer.addConnectionTitle' => 'Verbinding toevoegen',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Toevoegen aan ${name}',
			'addServer.signInWithPlexCard' => 'Inloggen met Plex',
			'addServer.signInWithPlexCardSubtitle' => 'Autoriseer dit apparaat. Gedeelde servers worden toegevoegd.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Autoriseer een Plex-account. Home-gebruikers worden profielen.',
			'addServer.connectToJellyfinCard' => 'Verbinden met Jellyfin',
			'addServer.connectToJellyfinCardSubtitle' => 'Voer je server-URL, gebruikersnaam en wachtwoord in.',
			'addServer.connectToJellyfinCardSubtitleScoped' => ({required Object name}) => 'Log in op een Jellyfin-server. Wordt gekoppeld aan ${name}.',
			'addServer.borrowFromAnotherProfile' => 'Van een ander profiel lenen',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Hergebruik de verbinding van een ander profiel. Voor profielen met pincodebeveiliging is een pincode vereist.',
			_ => null,
		};
	}
}
