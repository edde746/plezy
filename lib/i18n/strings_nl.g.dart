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
class TranslationsNl with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsNl({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.nl,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <nl>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsNl _root = this; // ignore: unused_field

	@override 
	TranslationsNl $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsNl(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsAppNl app = _TranslationsAppNl._(_root);
	@override late final _TranslationsAuthNl auth = _TranslationsAuthNl._(_root);
	@override late final _TranslationsCommonNl common = _TranslationsCommonNl._(_root);
	@override late final _TranslationsScreensNl screens = _TranslationsScreensNl._(_root);
	@override late final _TranslationsUpdateNl update = _TranslationsUpdateNl._(_root);
	@override late final _TranslationsSettingsNl settings = _TranslationsSettingsNl._(_root);
	@override late final _TranslationsSearchNl search = _TranslationsSearchNl._(_root);
	@override late final _TranslationsHotkeysNl hotkeys = _TranslationsHotkeysNl._(_root);
	@override late final _TranslationsPinEntryNl pinEntry = _TranslationsPinEntryNl._(_root);
	@override late final _TranslationsFileInfoNl fileInfo = _TranslationsFileInfoNl._(_root);
	@override late final _TranslationsMediaMenuNl mediaMenu = _TranslationsMediaMenuNl._(_root);
	@override late final _TranslationsAccessibilityNl accessibility = _TranslationsAccessibilityNl._(_root);
	@override late final _TranslationsTooltipsNl tooltips = _TranslationsTooltipsNl._(_root);
	@override late final _TranslationsVideoControlsNl videoControls = _TranslationsVideoControlsNl._(_root);
	@override late final _TranslationsUserStatusNl userStatus = _TranslationsUserStatusNl._(_root);
	@override late final _TranslationsMessagesNl messages = _TranslationsMessagesNl._(_root);
	@override late final _TranslationsSubtitlingStylingNl subtitlingStyling = _TranslationsSubtitlingStylingNl._(_root);
	@override late final _TranslationsMpvConfigNl mpvConfig = _TranslationsMpvConfigNl._(_root);
	@override late final _TranslationsDialogNl dialog = _TranslationsDialogNl._(_root);
	@override late final _TranslationsDiscoverNl discover = _TranslationsDiscoverNl._(_root);
	@override late final _TranslationsErrorsNl errors = _TranslationsErrorsNl._(_root);
	@override late final _TranslationsLibrariesNl libraries = _TranslationsLibrariesNl._(_root);
	@override late final _TranslationsAboutNl about = _TranslationsAboutNl._(_root);
	@override late final _TranslationsServerSelectionNl serverSelection = _TranslationsServerSelectionNl._(_root);
	@override late final _TranslationsHubDetailNl hubDetail = _TranslationsHubDetailNl._(_root);
	@override late final _TranslationsLogsNl logs = _TranslationsLogsNl._(_root);
	@override late final _TranslationsLicensesNl licenses = _TranslationsLicensesNl._(_root);
	@override late final _TranslationsNavigationNl navigation = _TranslationsNavigationNl._(_root);
	@override late final _TranslationsLiveTvNl liveTv = _TranslationsLiveTvNl._(_root);
	@override late final _TranslationsDownloadsNl downloads = _TranslationsDownloadsNl._(_root);
	@override late final _TranslationsPlaylistsNl playlists = _TranslationsPlaylistsNl._(_root);
	@override late final _TranslationsCollectionsNl collections = _TranslationsCollectionsNl._(_root);
	@override late final _TranslationsWatchTogetherNl watchTogether = _TranslationsWatchTogetherNl._(_root);
	@override late final _TranslationsShadersNl shaders = _TranslationsShadersNl._(_root);
	@override late final _TranslationsCompanionRemoteNl companionRemote = _TranslationsCompanionRemoteNl._(_root);
	@override late final _TranslationsVideoSettingsNl videoSettings = _TranslationsVideoSettingsNl._(_root);
	@override late final _TranslationsExternalPlayerNl externalPlayer = _TranslationsExternalPlayerNl._(_root);
}

// Path: app
class _TranslationsAppNl implements TranslationsAppEn {
	_TranslationsAppNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _TranslationsAuthNl implements TranslationsAuthEn {
	_TranslationsAuthNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Inloggen met Plex';
	@override String get showQRCode => 'Toon QR-code';
	@override String get authenticate => 'Authenticeren';
	@override String get debugEnterToken => 'Debug: Voer Plex Token in';
	@override String get plexTokenLabel => 'Plex Authenticatietoken';
	@override String get plexTokenHint => 'Voer je Plex.tv token in';
	@override String get authenticationTimeout => 'Authenticatie verlopen. Probeer opnieuw.';
	@override String get scanQRToSignIn => 'Scan deze QR-code om in te loggen';
	@override String get waitingForAuth => 'Wachten op authenticatie...\nVoltooi het inloggen in je browser.';
	@override String get useBrowser => 'Gebruik browser';
}

// Path: common
class _TranslationsCommonNl implements TranslationsCommonEn {
	_TranslationsCommonNl._(this._root);

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
	@override String get shuffle => 'Willekeurig';
	@override String get addTo => 'Toevoegen aan...';
	@override String get remove => 'Verwijderen';
	@override String get paste => 'Plakken';
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
	@override String get loading => 'Laden...';
	@override String get reconnect => 'Opnieuw verbinden';
}

// Path: screens
class _TranslationsScreensNl implements TranslationsScreensEn {
	_TranslationsScreensNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licenties';
	@override String get switchProfile => 'Wissel van profiel';
	@override String get subtitleStyling => 'Ondertitel opmaak';
	@override String get mpvConfig => 'MPV-configuratie';
	@override String get logs => 'Logbestanden';
}

// Path: update
class _TranslationsUpdateNl implements TranslationsUpdateEn {
	_TranslationsUpdateNl._(this._root);

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
class _TranslationsSettingsNl implements TranslationsSettingsEn {
	_TranslationsSettingsNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Instellingen';
	@override String get language => 'Taal';
	@override String get theme => 'Thema';
	@override String get appearance => 'Uiterlijk';
	@override String get videoPlayback => 'Video afspelen';
	@override String get advanced => 'Geavanceerd';
	@override String get episodePosterMode => 'Aflevering poster stijl';
	@override String get seriesPoster => 'Serie poster';
	@override String get seriesPosterDescription => 'Toon de serie poster voor alle afleveringen';
	@override String get seasonPoster => 'Seizoen poster';
	@override String get seasonPosterDescription => 'Toon de seizoensspecifieke poster voor afleveringen';
	@override String get episodeThumbnail => 'Aflevering miniatuur';
	@override String get episodeThumbnailDescription => 'Toon 16:9 aflevering miniaturen';
	@override String get showHeroSectionDescription => 'Toon uitgelichte inhoud carrousel op startscherm';
	@override String get secondsLabel => 'Seconden';
	@override String get minutesLabel => 'Minuten';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Voer duur in (${min}-${max})';
	@override String get systemTheme => 'Systeem';
	@override String get systemThemeDescription => 'Volg systeeminstellingen';
	@override String get lightTheme => 'Licht';
	@override String get darkTheme => 'Donker';
	@override String get oledTheme => 'OLED';
	@override String get oledThemeDescription => 'Puur zwart voor OLED-schermen';
	@override String get libraryDensity => 'Bibliotheek dichtheid';
	@override String get compact => 'Compact';
	@override String get compactDescription => 'Kleinere kaarten, meer items zichtbaar';
	@override String get normal => 'Normaal';
	@override String get normalDescription => 'Standaard grootte';
	@override String get comfortable => 'Comfortabel';
	@override String get comfortableDescription => 'Grotere kaarten, minder items zichtbaar';
	@override String get viewMode => 'Weergavemodus';
	@override String get gridView => 'Raster';
	@override String get gridViewDescription => 'Items weergeven in een rasterindeling';
	@override String get listView => 'Lijst';
	@override String get listViewDescription => 'Items weergeven in een lijstindeling';
	@override String get showHeroSection => 'Toon hoofdsectie';
	@override String get useGlobalHubs => 'Plex Home-indeling gebruiken';
	@override String get useGlobalHubsDescription => 'Toon startpagina-hubs zoals de officiële Plex-client. Indien uitgeschakeld, worden in plaats daarvan aanbevelingen per bibliotheek getoond.';
	@override String get showServerNameOnHubs => 'Servernaam tonen bij hubs';
	@override String get showServerNameOnHubsDescription => 'Toon altijd de servernaam in hub-titels. Indien uitgeschakeld, alleen bij dubbele hub-namen.';
	@override String get alwaysKeepSidebarOpen => 'Zijbalk altijd open houden';
	@override String get alwaysKeepSidebarOpenDescription => 'Zijbalk blijft uitgevouwen en inhoudsgebied past zich aan';
	@override String get showUnwatchedCount => 'Aantal ongekeken tonen';
	@override String get showUnwatchedCountDescription => 'Toon aantal ongekeken afleveringen bij series en seizoenen';
	@override String get playerBackend => 'Speler backend';
	@override String get exoPlayer => 'ExoPlayer (Aanbevolen)';
	@override String get exoPlayerDescription => 'Android-native speler met betere hardware-ondersteuning';
	@override String get mpv => 'MPV';
	@override String get mpvDescription => 'Geavanceerde speler met meer functies en ASS-ondertitelondersteuning';
	@override String get hardwareDecoding => 'Hardware decodering';
	@override String get hardwareDecodingDescription => 'Gebruik hardware versnelling indien beschikbaar';
	@override String get bufferSize => 'Buffer grootte';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get subtitleStyling => 'Ondertitel opmaak';
	@override String get subtitleStylingDescription => 'Pas ondertitel uiterlijk aan';
	@override String get smallSkipDuration => 'Korte skip duur';
	@override String get largeSkipDuration => 'Lange skip duur';
	@override String secondsUnit({required Object seconds}) => '${seconds} seconden';
	@override String get defaultSleepTimer => 'Standaard slaap timer';
	@override String minutesUnit({required Object minutes}) => 'bij ${minutes} minuten';
	@override String get rememberTrackSelections => 'Onthoud track selecties per serie/film';
	@override String get rememberTrackSelectionsDescription => 'Bewaar automatisch audio- en ondertiteltaalvoorkeuren wanneer je tracks wijzigt tijdens afspelen';
	@override String get clickVideoTogglesPlayback => 'Klik op de video om afspelen/pauzeren te wisselen.';
	@override String get clickVideoTogglesPlaybackDescription => 'Als deze optie is ingeschakeld, wordt de video afgespeeld of gepauzeerd wanneer je op de videospeler klikt. Anders worden bij een klik de afspeelbedieningen weergegeven of verborgen.';
	@override String get videoPlayerControls => 'Videospeler bediening';
	@override String get keyboardShortcuts => 'Toetsenbord sneltoetsen';
	@override String get keyboardShortcutsDescription => 'Pas toetsenbord sneltoetsen aan';
	@override String get videoPlayerNavigation => 'Videospeler navigatie';
	@override String get videoPlayerNavigationDescription => 'Gebruik pijltjestoetsen om door de videospeler bediening te navigeren';
	@override String get debugLogging => 'Debug logging';
	@override String get debugLoggingDescription => 'Schakel gedetailleerde logging in voor probleemoplossing';
	@override String get viewLogs => 'Bekijk logs';
	@override String get viewLogsDescription => 'Bekijk applicatie logs';
	@override String get clearCache => 'Cache wissen';
	@override String get clearCacheDescription => 'Dit wist alle gecachte afbeeldingen en gegevens. De app kan langer duren om inhoud te laden na het wissen van de cache.';
	@override String get clearCacheSuccess => 'Cache succesvol gewist';
	@override String get resetSettings => 'Instellingen resetten';
	@override String get resetSettingsDescription => 'Dit reset alle instellingen naar hun standaard waarden. Deze actie kan niet ongedaan gemaakt worden.';
	@override String get resetSettingsSuccess => 'Instellingen succesvol gereset';
	@override String get shortcutsReset => 'Sneltoetsen gereset naar standaard';
	@override String get about => 'Over';
	@override String get aboutDescription => 'App informatie en licenties';
	@override String get updates => 'Updates';
	@override String get updateAvailable => 'Update beschikbaar';
	@override String get checkForUpdates => 'Controleer op updates';
	@override String get validationErrorEnterNumber => 'Voer een geldig nummer in';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Duur moet tussen ${min} en ${max} ${unit} zijn';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Sneltoets al toegewezen aan ${action}';
	@override String shortcutUpdated({required Object action}) => 'Sneltoets bijgewerkt voor ${action}';
	@override String get autoSkip => 'Automatisch Overslaan';
	@override String get autoSkipIntro => 'Intro Automatisch Overslaan';
	@override String get autoSkipIntroDescription => 'Intro-markeringen na enkele seconden automatisch overslaan';
	@override String get autoSkipCredits => 'Credits Automatisch Overslaan';
	@override String get autoSkipCreditsDescription => 'Credits automatisch overslaan en volgende aflevering afspelen';
	@override String get autoSkipDelay => 'Vertraging Automatisch Overslaan';
	@override String autoSkipDelayDescription({required Object seconds}) => '${seconds} seconden wachten voor automatisch overslaan';
	@override String get downloads => 'Downloads';
	@override String get downloadLocationDescription => 'Kies waar gedownloade content wordt opgeslagen';
	@override String get downloadLocationDefault => 'Standaard (App-opslag)';
	@override String get downloadLocationCustom => 'Aangepaste Locatie';
	@override String get selectFolder => 'Selecteer Map';
	@override String get resetToDefault => 'Herstel naar Standaard';
	@override String currentPath({required Object path}) => 'Huidig: ${path}';
	@override String get downloadLocationChanged => 'Downloadlocatie gewijzigd';
	@override String get downloadLocationReset => 'Downloadlocatie hersteld naar standaard';
	@override String get downloadLocationInvalid => 'Geselecteerde map is niet beschrijfbaar';
	@override String get downloadLocationSelectError => 'Kan map niet selecteren';
	@override String get downloadOnWifiOnly => 'Alleen via WiFi downloaden';
	@override String get downloadOnWifiOnlyDescription => 'Voorkom downloads bij gebruik van mobiele data';
	@override String get cellularDownloadBlocked => 'Downloads zijn uitgeschakeld bij mobiele data. Maak verbinding met WiFi of wijzig de instelling.';
	@override String get maxVolume => 'Maximaal volume';
	@override String get maxVolumeDescription => 'Volume boven 100% toestaan voor stille media';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Toon op Discord wat je aan het kijken bent';
	@override String get matchContentFrameRate => 'Inhoudsframesnelheid afstemmen';
	@override String get matchContentFrameRateDescription => 'Pas de schermverversingssnelheid aan op de video-inhoud, vermindert haperingen en bespaart batterij';
	@override String get requireProfileSelectionOnOpen => 'Vraag om profiel bij openen';
	@override String get requireProfileSelectionOnOpenDescription => 'Toon profielselectie telkens wanneer de app wordt geopend';
}

// Path: search
class _TranslationsSearchNl implements TranslationsSearchEn {
	_TranslationsSearchNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Zoek films, series, muziek...';
	@override String get tryDifferentTerm => 'Probeer een andere zoekterm';
	@override String get searchYourMedia => 'Zoek in je media';
	@override String get enterTitleActorOrKeyword => 'Voer een titel, acteur of trefwoord in';
}

// Path: hotkeys
class _TranslationsHotkeysNl implements TranslationsHotkeysEn {
	_TranslationsHotkeysNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Stel sneltoets in voor ${actionName}';
	@override String get clearShortcut => 'Wis sneltoets';
	@override late final _TranslationsHotkeysActionsNl actions = _TranslationsHotkeysActionsNl._(_root);
}

// Path: pinEntry
class _TranslationsPinEntryNl implements TranslationsPinEntryEn {
	_TranslationsPinEntryNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get enterPin => 'Voer PIN in';
	@override String get showPin => 'Toon PIN';
	@override String get hidePin => 'Verberg PIN';
}

// Path: fileInfo
class _TranslationsFileInfoNl implements TranslationsFileInfoEn {
	_TranslationsFileInfoNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bestand info';
	@override String get video => 'Video';
	@override String get audio => 'Audio';
	@override String get file => 'Bestand';
	@override String get advanced => 'Geavanceerd';
	@override String get codec => 'Codec';
	@override String get resolution => 'Resolutie';
	@override String get bitrate => 'Bitrate';
	@override String get frameRate => 'Frame rate';
	@override String get aspectRatio => 'Beeldverhouding';
	@override String get profile => 'Profiel';
	@override String get bitDepth => 'Bit diepte';
	@override String get colorSpace => 'Kleurruimte';
	@override String get colorRange => 'Kleurbereik';
	@override String get colorPrimaries => 'Kleurprimaires';
	@override String get chromaSubsampling => 'Chroma subsampling';
	@override String get channels => 'Kanalen';
	@override String get path => 'Pad';
	@override String get size => 'Grootte';
	@override String get container => 'Container';
	@override String get duration => 'Duur';
	@override String get optimizedForStreaming => 'Geoptimaliseerd voor streaming';
	@override String get has64bitOffsets => '64-bit Offsets';
}

// Path: mediaMenu
class _TranslationsMediaMenuNl implements TranslationsMediaMenuEn {
	_TranslationsMediaMenuNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Markeer als gekeken';
	@override String get markAsUnwatched => 'Markeer als ongekeken';
	@override String get removeFromContinueWatching => 'Verwijder uit Doorgaan met kijken';
	@override String get goToSeries => 'Ga naar serie';
	@override String get goToSeason => 'Ga naar seizoen';
	@override String get shufflePlay => 'Willekeurig afspelen';
	@override String get fileInfo => 'Bestand info';
	@override String get confirmDelete => 'Weet je zeker dat je dit item van je bestandssysteem wilt verwijderen?';
	@override String get deleteMultipleWarning => 'Meerdere items kunnen worden verwijderd.';
	@override String get mediaDeletedSuccessfully => 'Media-item succesvol verwijderd';
	@override String get mediaFailedToDelete => 'Verwijderen van media-item mislukt';
}

// Path: accessibility
class _TranslationsAccessibilityNl implements TranslationsAccessibilityEn {
	_TranslationsAccessibilityNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, film';
	@override String mediaCardShow({required Object title}) => '${title}, TV-serie';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'bekeken';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} procent bekeken';
	@override String get mediaCardUnwatched => 'niet bekeken';
	@override String get tapToPlay => 'Tik om af te spelen';
}

// Path: tooltips
class _TranslationsTooltipsNl implements TranslationsTooltipsEn {
	_TranslationsTooltipsNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Willekeurig afspelen';
	@override String get markAsWatched => 'Markeer als gekeken';
	@override String get markAsUnwatched => 'Markeer als ongekeken';
}

// Path: videoControls
class _TranslationsVideoControlsNl implements TranslationsVideoControlsEn {
	_TranslationsVideoControlsNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Audio';
	@override String get subtitlesLabel => 'Ondertitels';
	@override String get resetToZero => 'Reset naar 0ms';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} speelt later af';
	@override String playsEarlier({required Object label}) => '${label} speelt eerder af';
	@override String get noOffset => 'Geen offset';
	@override String get letterbox => 'Letterbox';
	@override String get fillScreen => 'Vul scherm';
	@override String get stretch => 'Uitrekken';
	@override String get lockRotation => 'Vergrendel rotatie';
	@override String get unlockRotation => 'Ontgrendel rotatie';
	@override String get timerActive => 'Timer actief';
	@override String playbackWillPauseIn({required Object duration}) => 'Afspelen wordt gepauzeerd over ${duration}';
	@override String get sleepTimerCompleted => 'Slaaptimer voltooid - afspelen gepauzeerd';
	@override String get autoPlayNext => 'Automatisch volgende afspelen';
	@override String get playNext => 'Volgende afspelen';
	@override String get playButton => 'Afspelen';
	@override String get pauseButton => 'Pauzeren';
	@override String seekBackwardButton({required Object seconds}) => 'Terugspoelen ${seconds} seconden';
	@override String seekForwardButton({required Object seconds}) => 'Vooruitspoelen ${seconds} seconden';
	@override String get previousButton => 'Vorige aflevering';
	@override String get nextButton => 'Volgende aflevering';
	@override String get previousChapterButton => 'Vorig hoofdstuk';
	@override String get nextChapterButton => 'Volgend hoofdstuk';
	@override String get muteButton => 'Dempen';
	@override String get unmuteButton => 'Dempen opheffen';
	@override String get settingsButton => 'Video-instellingen';
	@override String get audioTrackButton => 'Audiosporen';
	@override String get subtitlesButton => 'Ondertitels';
	@override String get chaptersButton => 'Hoofdstukken';
	@override String get versionsButton => 'Videoversies';
	@override String get pipButton => 'Beeld-in-beeld modus';
	@override String get aspectRatioButton => 'Beeldverhouding';
	@override String get fullscreenButton => 'Volledig scherm activeren';
	@override String get exitFullscreenButton => 'Volledig scherm verlaten';
	@override String get alwaysOnTopButton => 'Altijd bovenop';
	@override String get rotationLockButton => 'Rotatievergrendeling';
	@override String get timelineSlider => 'Videotijdlijn';
	@override String get volumeSlider => 'Volumeniveau';
	@override String endsAt({required Object time}) => 'Eindigt om ${time}';
	@override String get pipFailed => 'Beeld-in-beeld kon niet worden gestart';
	@override late final _TranslationsVideoControlsPipErrorsNl pipErrors = _TranslationsVideoControlsPipErrorsNl._(_root);
	@override String get chapters => 'Hoofdstukken';
	@override String get noChaptersAvailable => 'Geen hoofdstukken beschikbaar';
}

// Path: userStatus
class _TranslationsUserStatusNl implements TranslationsUserStatusEn {
	_TranslationsUserStatusNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Beheerder';
	@override String get restricted => 'Beperkt';
	@override String get protected => 'Beschermd';
	@override String get current => 'HUIDIG';
}

// Path: messages
class _TranslationsMessagesNl implements TranslationsMessagesEn {
	_TranslationsMessagesNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Gemarkeerd als gekeken';
	@override String get markedAsUnwatched => 'Gemarkeerd als ongekeken';
	@override String get markedAsWatchedOffline => 'Gemarkeerd als gekeken (sync wanneer online)';
	@override String get markedAsUnwatchedOffline => 'Gemarkeerd als ongekeken (sync wanneer online)';
	@override String get removedFromContinueWatching => 'Verwijderd uit Doorgaan met kijken';
	@override String errorLoading({required Object error}) => 'Fout: ${error}';
	@override String get fileInfoNotAvailable => 'Bestand informatie niet beschikbaar';
	@override String errorLoadingFileInfo({required Object error}) => 'Fout bij laden bestand info: ${error}';
	@override String get errorLoadingSeries => 'Fout bij laden serie';
	@override String get errorLoadingSeason => 'Fout bij laden seizoen';
	@override String get musicNotSupported => 'Muziek afspelen wordt nog niet ondersteund';
	@override String get logsCleared => 'Logs gewist';
	@override String get logsCopied => 'Logs gekopieerd naar klembord';
	@override String get noLogsAvailable => 'Geen logs beschikbaar';
	@override String libraryScanning({required Object title}) => 'Scannen "${title}"...';
	@override String libraryScanStarted({required Object title}) => 'Bibliotheek scan gestart voor "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Kon bibliotheek niet scannen: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Metadata vernieuwen voor "${title}"...';
	@override String metadataRefreshStarted({required Object title}) => 'Metadata vernieuwen gestart voor "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Kon metadata niet vernieuwen: ${error}';
	@override String get logoutConfirm => 'Weet je zeker dat je wilt uitloggen?';
	@override String get noSeasonsFound => 'Geen seizoenen gevonden';
	@override String get noEpisodesFound => 'Geen afleveringen gevonden in eerste seizoen';
	@override String get noEpisodesFoundGeneral => 'Geen afleveringen gevonden';
	@override String get noResultsFound => 'Geen resultaten gevonden';
	@override String sleepTimerSet({required Object label}) => 'Slaap timer ingesteld voor ${label}';
	@override String get noItemsAvailable => 'Geen items beschikbaar';
	@override String get failedToCreatePlayQueueNoItems => 'Kan afspeelwachtrij niet maken - geen items';
	@override String failedPlayback({required Object action, required Object error}) => 'Afspelen van ${action} mislukt: ${error}';
	@override String get switchingToCompatiblePlayer => 'Overschakelen naar compatibele speler...';
	@override String get logsUploaded => 'Logs uploaded';
	@override String get logsUploadFailed => 'Failed to upload logs';
	@override String get logId => 'Log ID';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingNl implements TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get stylingOptions => 'Opmaak opties';
	@override String get fontSize => 'Lettergrootte';
	@override String get textColor => 'Tekstkleur';
	@override String get borderSize => 'Rand grootte';
	@override String get borderColor => 'Randkleur';
	@override String get backgroundOpacity => 'Achtergrond transparantie';
	@override String get backgroundColor => 'Achtergrondkleur';
	@override String get position => 'Position';
}

// Path: mpvConfig
class _TranslationsMpvConfigNl implements TranslationsMpvConfigEn {
	_TranslationsMpvConfigNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'MPV-configuratie';
	@override String get description => 'Geavanceerde videospeler-instellingen';
	@override String get properties => 'Eigenschappen';
	@override String get presets => 'Voorinstellingen';
	@override String get noProperties => 'Geen eigenschappen geconfigureerd';
	@override String get noPresets => 'Geen opgeslagen voorinstellingen';
	@override String get addProperty => 'Eigenschap toevoegen';
	@override String get editProperty => 'Eigenschap bewerken';
	@override String get deleteProperty => 'Eigenschap verwijderen';
	@override String get propertyKey => 'Eigenschapssleutel';
	@override String get propertyKeyHint => 'bijv. hwdec, demuxer-max-bytes';
	@override String get propertyValue => 'Eigenschapswaarde';
	@override String get propertyValueHint => 'bijv. auto, 256000000';
	@override String get saveAsPreset => 'Opslaan als voorinstelling...';
	@override String get presetName => 'Naam voorinstelling';
	@override String get presetNameHint => 'Voer een naam in voor deze voorinstelling';
	@override String get loadPreset => 'Laden';
	@override String get deletePreset => 'Verwijderen';
	@override String get presetSaved => 'Voorinstelling opgeslagen';
	@override String get presetLoaded => 'Voorinstelling geladen';
	@override String get presetDeleted => 'Voorinstelling verwijderd';
	@override String get confirmDeletePreset => 'Weet je zeker dat je deze voorinstelling wilt verwijderen?';
	@override String get confirmDeleteProperty => 'Weet je zeker dat je deze eigenschap wilt verwijderen?';
	@override String entriesCount({required Object count}) => '${count} items';
}

// Path: dialog
class _TranslationsDialogNl implements TranslationsDialogEn {
	_TranslationsDialogNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Bevestig actie';
}

// Path: discover
class _TranslationsDiscoverNl implements TranslationsDiscoverEn {
	_TranslationsDiscoverNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ontdekken';
	@override String get switchProfile => 'Wissel van profiel';
	@override String get noContentAvailable => 'Geen inhoud beschikbaar';
	@override String get addMediaToLibraries => 'Voeg wat media toe aan je bibliotheken';
	@override String get continueWatching => 'Verder kijken';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'Overzicht';
	@override String get cast => 'Acteurs';
	@override String get seasons => 'Seizoenen';
	@override String get studio => 'Studio';
	@override String get rating => 'Leeftijd';
	@override String episodeCount({required Object count}) => '${count} afleveringen';
	@override String watchedProgress({required Object watched, required Object total}) => '${watched}/${total} gekeken';
	@override String get movie => 'Film';
	@override String get tvShow => 'TV Serie';
	@override String minutesLeft({required Object minutes}) => '${minutes} min over';
}

// Path: errors
class _TranslationsErrorsNl implements TranslationsErrorsEn {
	_TranslationsErrorsNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Zoeken mislukt: ${error}';
	@override String connectionTimeout({required Object context}) => 'Verbinding time-out tijdens laden ${context}';
	@override String get connectionFailed => 'Kan geen verbinding maken met Plex server';
	@override String failedToLoad({required Object context, required Object error}) => 'Kon ${context} niet laden: ${error}';
	@override String get noClientAvailable => 'Geen client beschikbaar';
	@override String authenticationFailed({required Object error}) => 'Authenticatie mislukt: ${error}';
	@override String get couldNotLaunchUrl => 'Kon auth URL niet openen';
	@override String get pleaseEnterToken => 'Voer een token in';
	@override String get invalidToken => 'Ongeldig token';
	@override String failedToVerifyToken({required Object error}) => 'Kon token niet verifiëren: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Kon niet wisselen naar ${displayName}';
}

// Path: libraries
class _TranslationsLibrariesNl implements TranslationsLibrariesEn {
	_TranslationsLibrariesNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bibliotheken';
	@override String get scanLibraryFiles => 'Scan bibliotheek bestanden';
	@override String get scanLibrary => 'Scan bibliotheek';
	@override String get analyze => 'Analyseren';
	@override String get analyzeLibrary => 'Analyseer bibliotheek';
	@override String get refreshMetadata => 'Vernieuw metadata';
	@override String get emptyTrash => 'Prullenbak legen';
	@override String emptyingTrash({required Object title}) => 'Prullenbak legen voor "${title}"...';
	@override String trashEmptied({required Object title}) => 'Prullenbak geleegd voor "${title}"';
	@override String failedToEmptyTrash({required Object error}) => 'Kon prullenbak niet legen: ${error}';
	@override String analyzing({required Object title}) => 'Analyseren "${title}"...';
	@override String analysisStarted({required Object title}) => 'Analyse gestart voor "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Kon bibliotheek niet analyseren: ${error}';
	@override String get noLibrariesFound => 'Geen bibliotheken gevonden';
	@override String get thisLibraryIsEmpty => 'Deze bibliotheek is leeg';
	@override String get all => 'Alles';
	@override String get clearAll => 'Alles wissen';
	@override String scanLibraryConfirm({required Object title}) => 'Weet je zeker dat je "${title}" wilt scannen?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Weet je zeker dat je "${title}" wilt analyseren?';
	@override String refreshMetadataConfirm({required Object title}) => 'Weet je zeker dat je metadata wilt vernieuwen voor "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Weet je zeker dat je de prullenbak wilt legen voor "${title}"?';
	@override String get manageLibraries => 'Beheer bibliotheken';
	@override String get sort => 'Sorteren';
	@override String get sortBy => 'Sorteer op';
	@override String get filters => 'Filters';
	@override String get confirmActionMessage => 'Weet je zeker dat je deze actie wilt uitvoeren?';
	@override String get showLibrary => 'Toon bibliotheek';
	@override String get hideLibrary => 'Verberg bibliotheek';
	@override String get libraryOptions => 'Bibliotheek opties';
	@override String get content => 'bibliotheekinhoud';
	@override String get selectLibrary => 'Bibliotheek kiezen';
	@override String filtersWithCount({required Object count}) => 'Filters (${count})';
	@override String get noRecommendations => 'Geen aanbevelingen beschikbaar';
	@override String get noCollections => 'Geen collecties in deze bibliotheek';
	@override String get noFoldersFound => 'Geen mappen gevonden';
	@override String get folders => 'mappen';
	@override late final _TranslationsLibrariesTabsNl tabs = _TranslationsLibrariesTabsNl._(_root);
	@override late final _TranslationsLibrariesGroupingsNl groupings = _TranslationsLibrariesGroupingsNl._(_root);
}

// Path: about
class _TranslationsAboutNl implements TranslationsAboutEn {
	_TranslationsAboutNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Over';
	@override String get openSourceLicenses => 'Open Source licenties';
	@override String versionLabel({required Object version}) => 'Versie ${version}';
	@override String get appDescription => 'Een mooie Plex client voor Flutter';
	@override String get viewLicensesDescription => 'Bekijk licenties van third-party bibliotheken';
}

// Path: serverSelection
class _TranslationsServerSelectionNl implements TranslationsServerSelectionEn {
	_TranslationsServerSelectionNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get allServerConnectionsFailed => 'Kon niet verbinden met servers. Controleer je netwerk en probeer opnieuw.';
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Geen servers gevonden voor ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Kon servers niet laden: ${error}';
}

// Path: hubDetail
class _TranslationsHubDetailNl implements TranslationsHubDetailEn {
	_TranslationsHubDetailNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titel';
	@override String get releaseYear => 'Uitgavejaar';
	@override String get dateAdded => 'Datum toegevoegd';
	@override String get rating => 'Beoordeling';
	@override String get noItemsFound => 'Geen items gevonden';
}

// Path: logs
class _TranslationsLogsNl implements TranslationsLogsEn {
	_TranslationsLogsNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Wis logs';
	@override String get copyLogs => 'Kopieer logs';
	@override String get uploadLogs => 'Upload Logs';
	@override String get error => 'Fout:';
	@override String get stackTrace => 'Stacktracering:';
}

// Path: licenses
class _TranslationsLicensesNl implements TranslationsLicensesEn {
	_TranslationsLicensesNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Gerelateerde pakketten';
	@override String get license => 'Licentie';
	@override String licenseNumber({required Object number}) => 'Licentie ${number}';
	@override String licensesCount({required Object count}) => '${count} licenties';
}

// Path: navigation
class _TranslationsNavigationNl implements TranslationsNavigationEn {
	_TranslationsNavigationNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Bibliotheken';
	@override String get downloads => 'Downloads';
	@override String get liveTv => 'Live TV';
}

// Path: liveTv
class _TranslationsLiveTvNl implements TranslationsLiveTvEn {
	_TranslationsLiveTvNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Live TV';
	@override String get channels => 'Zenders';
	@override String get guide => 'Gids';
	@override String get recordings => 'Opnames';
	@override String get subscriptions => 'Opnameregels';
	@override String get scheduled => 'Gepland';
	@override String get noChannels => 'Geen zenders beschikbaar';
	@override String get noDvr => 'Geen DVR geconfigureerd op een server';
	@override String get tuneFailed => 'Kan zender niet afstemmen';
	@override String get loading => 'Zenders laden...';
	@override String get nowPlaying => 'Nu aan het afspelen';
	@override String get record => 'Opnemen';
	@override String get recordSeries => 'Serie opnemen';
	@override String get cancelRecording => 'Opname annuleren';
	@override String get deleteSubscription => 'Opnameregel verwijderen';
	@override String get deleteSubscriptionConfirm => 'Weet je zeker dat je deze opnameregel wilt verwijderen?';
	@override String get subscriptionDeleted => 'Opnameregel verwijderd';
	@override String get noPrograms => 'Geen programmagegevens beschikbaar';
	@override String get noRecordings => 'Geen opnames gepland';
	@override String get noSubscriptions => 'Geen opnameregels';
	@override String channelNumber({required Object number}) => 'Kanaal ${number}';
	@override String get live => 'LIVE';
	@override String get hd => 'HD';
	@override String get premiere => 'NIEUW';
	@override String get reloadGuide => 'Gids herladen';
	@override String get guideReloaded => 'Gidsgegevens herladen';
	@override String get allChannels => 'Alle zenders';
	@override String get now => 'Nu';
	@override String get today => 'Vandaag';
	@override String get midnight => 'Middernacht';
	@override String get overnight => 'Nacht';
	@override String get morning => 'Ochtend';
	@override String get daytime => 'Overdag';
	@override String get evening => 'Avond';
	@override String get lateNight => 'Late avond';
	@override String get whatsOn => 'Nu op TV';
	@override String get watchChannel => 'Kanaal bekijken';
}

// Path: downloads
class _TranslationsDownloadsNl implements TranslationsDownloadsEn {
	_TranslationsDownloadsNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Downloads';
	@override String get manage => 'Beheren';
	@override String get tvShows => 'Series';
	@override String get movies => 'Films';
	@override String get noDownloads => 'Nog geen downloads';
	@override String get noDownloadsDescription => 'Gedownloade content verschijnt hier voor offline weergave';
	@override String get downloadNow => 'Download';
	@override String get deleteDownload => 'Download verwijderen';
	@override String get retryDownload => 'Download opnieuw proberen';
	@override String get downloadQueued => 'Download in wachtrij';
	@override String episodesQueued({required Object count}) => '${count} afleveringen in wachtrij voor download';
	@override String get downloadDeleted => 'Download verwijderd';
	@override String deleteConfirm({required Object title}) => 'Weet je zeker dat je "${title}" wilt verwijderen? Het gedownloade bestand wordt van je apparaat verwijderd.';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Verwijderen van ${title}... (${current} van ${total})';
	@override String get noDownloadsTree => 'Geen downloads';
	@override String get pauseAll => 'Alles pauzeren';
	@override String get resumeAll => 'Alles hervatten';
	@override String get deleteAll => 'Alles verwijderen';
}

// Path: playlists
class _TranslationsPlaylistsNl implements TranslationsPlaylistsEn {
	_TranslationsPlaylistsNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Afspeellijsten';
	@override String get noPlaylists => 'Geen afspeellijsten gevonden';
	@override String get create => 'Afspeellijst maken';
	@override String get playlistName => 'Naam afspeellijst';
	@override String get enterPlaylistName => 'Voer naam afspeellijst in';
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
	@override String get selectPlaylist => 'Selecteer afspeellijst';
	@override String get createNewPlaylist => 'Nieuwe afspeellijst maken';
	@override String get errorCreating => 'Fout bij maken afspeellijst';
	@override String get errorDeleting => 'Fout bij verwijderen afspeellijst';
	@override String get errorLoading => 'Fout bij laden afspeellijsten';
	@override String get errorAdding => 'Fout bij toevoegen aan afspeellijst';
	@override String get errorReordering => 'Fout bij herschikken van afspeellijstitem';
	@override String get errorRemoving => 'Fout bij verwijderen uit afspeellijst';
	@override String get playlist => 'Afspeellijst';
}

// Path: collections
class _TranslationsCollectionsNl implements TranslationsCollectionsEn {
	_TranslationsCollectionsNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Collecties';
	@override String get collection => 'Collectie';
	@override String get empty => 'Collectie is leeg';
	@override String get unknownLibrarySection => 'Kan niet verwijderen: onbekende bibliotheeksectie';
	@override String get deleteCollection => 'Collectie verwijderen';
	@override String deleteConfirm({required Object title}) => 'Weet je zeker dat je "${title}" wilt verwijderen? Deze actie kan niet ongedaan worden gemaakt.';
	@override String get deleted => 'Collectie verwijderd';
	@override String get deleteFailed => 'Collectie verwijderen mislukt';
	@override String deleteFailedWithError({required Object error}) => 'Collectie verwijderen mislukt: ${error}';
	@override String failedToLoadItems({required Object error}) => 'Collectie-items laden mislukt: ${error}';
	@override String get selectCollection => 'Selecteer collectie';
	@override String get createNewCollection => 'Nieuwe collectie maken';
	@override String get collectionName => 'Collectienaam';
	@override String get enterCollectionName => 'Voer collectienaam in';
	@override String get addedToCollection => 'Toegevoegd aan collectie';
	@override String get errorAddingToCollection => 'Fout bij toevoegen aan collectie';
	@override String get created => 'Collectie gemaakt';
	@override String get removeFromCollection => 'Verwijderen uit collectie';
	@override String removeFromCollectionConfirm({required Object title}) => '"${title}" uit deze collectie verwijderen?';
	@override String get removedFromCollection => 'Uit collectie verwijderd';
	@override String get removeFromCollectionFailed => 'Verwijderen uit collectie mislukt';
	@override String removeFromCollectionError({required Object error}) => 'Fout bij verwijderen uit collectie: ${error}';
}

// Path: watchTogether
class _TranslationsWatchTogetherNl implements TranslationsWatchTogetherEn {
	_TranslationsWatchTogetherNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Samen Kijken';
	@override String get description => 'Kijk synchroon met vrienden en familie';
	@override String get createSession => 'Sessie Maken';
	@override String get creating => 'Maken...';
	@override String get joinSession => 'Sessie Deelnemen';
	@override String get joining => 'Deelnemen...';
	@override String get controlMode => 'Controlemodus';
	@override String get controlModeQuestion => 'Wie kan het afspelen bedienen?';
	@override String get hostOnly => 'Alleen Host';
	@override String get anyone => 'Iedereen';
	@override String get hostingSession => 'Sessie Hosten';
	@override String get inSession => 'In Sessie';
	@override String get sessionCode => 'Sessiecode';
	@override String get hostControlsPlayback => 'Host bedient het afspelen';
	@override String get anyoneCanControl => 'Iedereen kan het afspelen bedienen';
	@override String get hostControls => 'Host bedient';
	@override String get anyoneControls => 'Iedereen bedient';
	@override String get participants => 'Deelnemers';
	@override String get host => 'Host';
	@override String get hostBadge => 'HOST';
	@override String get youAreHost => 'Jij bent de host';
	@override String get watchingWithOthers => 'Kijken met anderen';
	@override String get endSession => 'Sessie Beëindigen';
	@override String get leaveSession => 'Sessie Verlaten';
	@override String get endSessionQuestion => 'Sessie Beëindigen?';
	@override String get leaveSessionQuestion => 'Sessie Verlaten?';
	@override String get endSessionConfirm => 'Dit beëindigt de sessie voor alle deelnemers.';
	@override String get leaveSessionConfirm => 'Je wordt uit de sessie verwijderd.';
	@override String get endSessionConfirmOverlay => 'Dit beëindigt de kijksessie voor alle deelnemers.';
	@override String get leaveSessionConfirmOverlay => 'Je wordt losgekoppeld van de kijksessie.';
	@override String get end => 'Beëindigen';
	@override String get leave => 'Verlaten';
	@override String get syncing => 'Synchroniseren...';
	@override String get joinWatchSession => 'Kijksessie Deelnemen';
	@override String get enterCodeHint => 'Voer 8-teken code in';
	@override String get pasteFromClipboard => 'Plakken van klembord';
	@override String get pleaseEnterCode => 'Voer een sessiecode in';
	@override String get codeMustBe8Chars => 'Sessiecode moet 8 tekens zijn';
	@override String get joinInstructions => 'Voer de sessiecode in die door de host is gedeeld om deel te nemen aan hun kijksessie.';
	@override String get failedToCreate => 'Sessie maken mislukt';
	@override String get failedToJoin => 'Sessie deelnemen mislukt';
	@override String get sessionCodeCopied => 'Sessiecode gekopieerd naar klembord';
	@override String get relayUnreachable => 'De relayserver is niet bereikbaar. Dit kan worden veroorzaakt doordat je internetprovider de verbinding blokkeert. Je kunt het toch proberen, maar Watch Together werkt mogelijk niet.';
	@override String get reconnectingToHost => 'Opnieuw verbinden met host...';
	@override String participantJoined({required Object name}) => '${name} is toegetreden';
	@override String participantLeft({required Object name}) => '${name} heeft de sessie verlaten';
}

// Path: shaders
class _TranslationsShadersNl implements TranslationsShadersEn {
	_TranslationsShadersNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shaders';
	@override String get noShaderDescription => 'Geen videoverbetering';
	@override String get nvscalerDescription => 'NVIDIA-beeldschaling voor scherpere video';
	@override String get qualityFast => 'Snel';
	@override String get qualityHQ => 'Hoge kwaliteit';
	@override String get mode => 'Modus';
}

// Path: companionRemote
class _TranslationsCompanionRemoteNl implements TranslationsCompanionRemoteEn {
	_TranslationsCompanionRemoteNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Companion Remote';
	@override String get connectToDevice => 'Verbinden met apparaat';
	@override String get hostRemoteSession => 'Externe sessie hosten';
	@override String get controlThisDevice => 'Bedien dit apparaat met je telefoon';
	@override String get remoteControl => 'Afstandsbediening';
	@override String get controlDesktop => 'Bedien een desktop-apparaat';
	@override String connectedTo({required Object name}) => 'Verbonden met ${name}';
	@override late final _TranslationsCompanionRemoteSessionNl session = _TranslationsCompanionRemoteSessionNl._(_root);
	@override late final _TranslationsCompanionRemotePairingNl pairing = _TranslationsCompanionRemotePairingNl._(_root);
	@override late final _TranslationsCompanionRemoteRemoteNl remote = _TranslationsCompanionRemoteRemoteNl._(_root);
}

// Path: videoSettings
class _TranslationsVideoSettingsNl implements TranslationsVideoSettingsEn {
	_TranslationsVideoSettingsNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get playbackSettings => 'Afspeelinstellingen';
	@override String get playbackSpeed => 'Afspeelsnelheid';
	@override String get sleepTimer => 'Slaaptimer';
	@override String get audioSync => 'Audio synchronisatie';
	@override String get subtitleSync => 'Ondertitel synchronisatie';
	@override String get hdr => 'HDR';
	@override String get audioOutput => 'Audio-uitvoer';
	@override String get performanceOverlay => 'Prestatie-overlay';
}

// Path: externalPlayer
class _TranslationsExternalPlayerNl implements TranslationsExternalPlayerEn {
	_TranslationsExternalPlayerNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Externe speler';
	@override String get useExternalPlayer => 'Externe speler gebruiken';
	@override String get useExternalPlayerDescription => 'Open video\'s in een externe app in plaats van de ingebouwde speler';
	@override String get selectPlayer => 'Speler selecteren';
	@override String get systemDefault => 'Systeemstandaard';
	@override String get addCustomPlayer => 'Aangepaste speler toevoegen';
	@override String get playerName => 'Spelernaam';
	@override String get playerCommand => 'Commando';
	@override String get playerPackage => 'Pakketnaam';
	@override String get playerUrlScheme => 'URL-schema';
	@override String get customPlayer => 'Aangepaste speler';
	@override String get off => 'Uit';
	@override String get launchFailed => 'Kan externe speler niet openen';
	@override String appNotInstalled({required Object name}) => '${name} is niet geïnstalleerd';
	@override String get playInExternalPlayer => 'Afspelen in externe speler';
}

// Path: hotkeys.actions
class _TranslationsHotkeysActionsNl implements TranslationsHotkeysActionsEn {
	_TranslationsHotkeysActionsNl._(this._root);

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
	@override String get speedIncrease => 'Snelheid verhogen';
	@override String get speedDecrease => 'Snelheid verlagen';
	@override String get speedReset => 'Snelheid resetten';
	@override String get subSeekNext => 'Naar volgende ondertitel';
	@override String get subSeekPrev => 'Naar vorige ondertitel';
	@override String get shaderToggle => 'Shaders aan/uit';
	@override String get skipMarker => 'Intro/aftiteling overslaan';
}

// Path: videoControls.pipErrors
class _TranslationsVideoControlsPipErrorsNl implements TranslationsVideoControlsPipErrorsEn {
	_TranslationsVideoControlsPipErrorsNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Vereist Android 8.0 of nieuwer';
	@override String get permissionDisabled => 'Beeld-in-beeld toestemming is uitgeschakeld. Schakel deze in via Instellingen > Apps > Plezy > Beeld-in-beeld';
	@override String get notSupported => 'Dit apparaat ondersteunt geen beeld-in-beeld modus';
	@override String get failed => 'Beeld-in-beeld kon niet worden gestart';
	@override String unknown({required Object error}) => 'Er is een fout opgetreden: ${error}';
}

// Path: libraries.tabs
class _TranslationsLibrariesTabsNl implements TranslationsLibrariesTabsEn {
	_TranslationsLibrariesTabsNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Aanbevolen';
	@override String get browse => 'Bladeren';
	@override String get collections => 'Collecties';
	@override String get playlists => 'Afspeellijsten';
}

// Path: libraries.groupings
class _TranslationsLibrariesGroupingsNl implements TranslationsLibrariesGroupingsEn {
	_TranslationsLibrariesGroupingsNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get all => 'Alles';
	@override String get movies => 'Films';
	@override String get shows => 'Series';
	@override String get seasons => 'Seizoenen';
	@override String get episodes => 'Afleveringen';
	@override String get folders => 'Mappen';
}

// Path: companionRemote.session
class _TranslationsCompanionRemoteSessionNl implements TranslationsCompanionRemoteSessionEn {
	_TranslationsCompanionRemoteSessionNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get creatingSession => 'Externe sessie aanmaken...';
	@override String get failedToCreate => 'Kan externe sessie niet aanmaken:';
	@override String get noSession => 'Geen sessie beschikbaar';
	@override String get scanQrCode => 'Scan QR-code';
	@override String get orEnterManually => 'Of voer handmatig in';
	@override String get hostAddress => 'Hostadres';
	@override String get sessionId => 'Sessie-ID';
	@override String get pin => 'PIN';
	@override String get connected => 'Verbonden';
	@override String get waitingForConnection => 'Wachten op verbinding...';
	@override String get usePhoneToControl => 'Gebruik je mobiele apparaat om deze app te bedienen';
	@override String copiedToClipboard({required Object label}) => '${label} gekopieerd naar klembord';
	@override String get copyToClipboard => 'Kopieer naar klembord';
	@override String get newSession => 'Nieuwe sessie';
	@override String get minimize => 'Minimaliseren';
}

// Path: companionRemote.pairing
class _TranslationsCompanionRemotePairingNl implements TranslationsCompanionRemotePairingEn {
	_TranslationsCompanionRemotePairingNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get recent => 'Recent';
	@override String get scan => 'Scannen';
	@override String get manual => 'Handmatig';
	@override String get recentConnections => 'Recente verbindingen';
	@override String get quickReconnect => 'Snel opnieuw verbinden met eerder gekoppelde apparaten';
	@override String get pairWithDesktop => 'Koppelen met desktop';
	@override String get enterSessionDetails => 'Voer de sessiegegevens in die op je desktop-apparaat worden getoond';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get sessionIdHint => 'Voer 8-tekens sessie-ID in';
	@override String get pinHint => 'Voer 6-cijferige PIN in';
	@override String get connecting => 'Verbinden...';
	@override String get tips => 'Tips';
	@override String get tipDesktop => 'Open Plezy op je desktop en schakel Companion Remote in via instellingen of menu';
	@override String get tipScan => 'Gebruik het tabblad Scannen om snel te koppelen door de QR-code op je desktop te scannen';
	@override String get tipWifi => 'Zorg ervoor dat beide apparaten op hetzelfde WiFi-netwerk zitten';
	@override String get cameraPermissionRequired => 'Cameratoestemming is vereist om QR-codes te scannen.\nGeef cameratoegang in je apparaatinstellingen.';
	@override String cameraError({required Object error}) => 'Kan camera niet starten: ${error}';
	@override String get scanInstruction => 'Richt je camera op de QR-code die op je desktop wordt getoond';
	@override String get noRecentConnections => 'Geen recente verbindingen';
	@override String get connectUsingManual => 'Verbind met een apparaat via Handmatige invoer om te beginnen';
	@override String get invalidQrCode => 'Ongeldig QR-codeformaat';
	@override String get removeRecentConnection => 'Recente verbinding verwijderen';
	@override String removeConfirm({required Object name}) => '"${name}" verwijderen uit recente verbindingen?';
	@override String get validationHostRequired => 'Voer een hostadres in';
	@override String get validationHostFormat => 'Formaat moet IP:poort zijn (bijv. 192.168.1.100:48632)';
	@override String get validationSessionIdRequired => 'Voer een sessie-ID in';
	@override String get validationSessionIdLength => 'Sessie-ID moet 8 tekens zijn';
	@override String get validationPinRequired => 'Voer een PIN in';
	@override String get validationPinLength => 'PIN moet 6 cijfers zijn';
	@override String get connectionTimedOut => 'Verbinding verlopen. Controleer de sessie-ID en PIN.';
	@override String get sessionNotFound => 'Kan de sessie niet vinden. Controleer je gegevens.';
	@override String failedToConnect({required Object error}) => 'Verbinden mislukt: ${error}';
	@override String failedToLoadRecent({required Object error}) => 'Kan recente sessies niet laden: ${error}';
}

// Path: companionRemote.remote
class _TranslationsCompanionRemoteRemoteNl implements TranslationsCompanionRemoteRemoteEn {
	_TranslationsCompanionRemoteRemoteNl._(this._root);

	final TranslationsNl _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Wil je de verbinding met de externe sessie verbreken?';
	@override String get reconnecting => 'Opnieuw verbinden...';
	@override String attemptOf({required Object current}) => 'Poging ${current} van 5';
	@override String get retryNow => 'Nu opnieuw proberen';
	@override String get connectionError => 'Verbindingsfout';
	@override String get notConnected => 'Niet verbonden';
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
			'auth.debugEnterToken' => 'Debug: Voer Plex Token in',
			'auth.plexTokenLabel' => 'Plex Authenticatietoken',
			'auth.plexTokenHint' => 'Voer je Plex.tv token in',
			'auth.authenticationTimeout' => 'Authenticatie verlopen. Probeer opnieuw.',
			'auth.scanQRToSignIn' => 'Scan deze QR-code om in te loggen',
			'auth.waitingForAuth' => 'Wachten op authenticatie...\nVoltooi het inloggen in je browser.',
			'auth.useBrowser' => 'Gebruik browser',
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
			'common.shuffle' => 'Willekeurig',
			'common.addTo' => 'Toevoegen aan...',
			'common.remove' => 'Verwijderen',
			'common.paste' => 'Plakken',
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
			'common.loading' => 'Laden...',
			'common.reconnect' => 'Opnieuw verbinden',
			'screens.licenses' => 'Licenties',
			'screens.switchProfile' => 'Wissel van profiel',
			'screens.subtitleStyling' => 'Ondertitel opmaak',
			'screens.mpvConfig' => 'MPV-configuratie',
			'screens.logs' => 'Logbestanden',
			'update.available' => 'Update beschikbaar',
			'update.versionAvailable' => ({required Object version}) => 'Versie ${version} is beschikbaar',
			'update.currentVersion' => ({required Object version}) => 'Huidig: ${version}',
			'update.skipVersion' => 'Deze versie overslaan',
			'update.viewRelease' => 'Bekijk release',
			'update.latestVersion' => 'Je hebt de nieuwste versie',
			'update.checkFailed' => 'Kon niet controleren op updates',
			'settings.title' => 'Instellingen',
			'settings.language' => 'Taal',
			'settings.theme' => 'Thema',
			'settings.appearance' => 'Uiterlijk',
			'settings.videoPlayback' => 'Video afspelen',
			'settings.advanced' => 'Geavanceerd',
			'settings.episodePosterMode' => 'Aflevering poster stijl',
			'settings.seriesPoster' => 'Serie poster',
			'settings.seriesPosterDescription' => 'Toon de serie poster voor alle afleveringen',
			'settings.seasonPoster' => 'Seizoen poster',
			'settings.seasonPosterDescription' => 'Toon de seizoensspecifieke poster voor afleveringen',
			'settings.episodeThumbnail' => 'Aflevering miniatuur',
			'settings.episodeThumbnailDescription' => 'Toon 16:9 aflevering miniaturen',
			'settings.showHeroSectionDescription' => 'Toon uitgelichte inhoud carrousel op startscherm',
			'settings.secondsLabel' => 'Seconden',
			'settings.minutesLabel' => 'Minuten',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Voer duur in (${min}-${max})',
			'settings.systemTheme' => 'Systeem',
			'settings.systemThemeDescription' => 'Volg systeeminstellingen',
			'settings.lightTheme' => 'Licht',
			'settings.darkTheme' => 'Donker',
			'settings.oledTheme' => 'OLED',
			'settings.oledThemeDescription' => 'Puur zwart voor OLED-schermen',
			'settings.libraryDensity' => 'Bibliotheek dichtheid',
			'settings.compact' => 'Compact',
			'settings.compactDescription' => 'Kleinere kaarten, meer items zichtbaar',
			'settings.normal' => 'Normaal',
			'settings.normalDescription' => 'Standaard grootte',
			'settings.comfortable' => 'Comfortabel',
			'settings.comfortableDescription' => 'Grotere kaarten, minder items zichtbaar',
			'settings.viewMode' => 'Weergavemodus',
			'settings.gridView' => 'Raster',
			'settings.gridViewDescription' => 'Items weergeven in een rasterindeling',
			'settings.listView' => 'Lijst',
			'settings.listViewDescription' => 'Items weergeven in een lijstindeling',
			'settings.showHeroSection' => 'Toon hoofdsectie',
			'settings.useGlobalHubs' => 'Plex Home-indeling gebruiken',
			'settings.useGlobalHubsDescription' => 'Toon startpagina-hubs zoals de officiële Plex-client. Indien uitgeschakeld, worden in plaats daarvan aanbevelingen per bibliotheek getoond.',
			'settings.showServerNameOnHubs' => 'Servernaam tonen bij hubs',
			'settings.showServerNameOnHubsDescription' => 'Toon altijd de servernaam in hub-titels. Indien uitgeschakeld, alleen bij dubbele hub-namen.',
			'settings.alwaysKeepSidebarOpen' => 'Zijbalk altijd open houden',
			'settings.alwaysKeepSidebarOpenDescription' => 'Zijbalk blijft uitgevouwen en inhoudsgebied past zich aan',
			'settings.showUnwatchedCount' => 'Aantal ongekeken tonen',
			'settings.showUnwatchedCountDescription' => 'Toon aantal ongekeken afleveringen bij series en seizoenen',
			'settings.playerBackend' => 'Speler backend',
			'settings.exoPlayer' => 'ExoPlayer (Aanbevolen)',
			'settings.exoPlayerDescription' => 'Android-native speler met betere hardware-ondersteuning',
			'settings.mpv' => 'MPV',
			'settings.mpvDescription' => 'Geavanceerde speler met meer functies en ASS-ondertitelondersteuning',
			'settings.hardwareDecoding' => 'Hardware decodering',
			'settings.hardwareDecodingDescription' => 'Gebruik hardware versnelling indien beschikbaar',
			'settings.bufferSize' => 'Buffer grootte',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.subtitleStyling' => 'Ondertitel opmaak',
			'settings.subtitleStylingDescription' => 'Pas ondertitel uiterlijk aan',
			'settings.smallSkipDuration' => 'Korte skip duur',
			'settings.largeSkipDuration' => 'Lange skip duur',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} seconden',
			'settings.defaultSleepTimer' => 'Standaard slaap timer',
			'settings.minutesUnit' => ({required Object minutes}) => 'bij ${minutes} minuten',
			'settings.rememberTrackSelections' => 'Onthoud track selecties per serie/film',
			'settings.rememberTrackSelectionsDescription' => 'Bewaar automatisch audio- en ondertiteltaalvoorkeuren wanneer je tracks wijzigt tijdens afspelen',
			'settings.clickVideoTogglesPlayback' => 'Klik op de video om afspelen/pauzeren te wisselen.',
			'settings.clickVideoTogglesPlaybackDescription' => 'Als deze optie is ingeschakeld, wordt de video afgespeeld of gepauzeerd wanneer je op de videospeler klikt. Anders worden bij een klik de afspeelbedieningen weergegeven of verborgen.',
			'settings.videoPlayerControls' => 'Videospeler bediening',
			'settings.keyboardShortcuts' => 'Toetsenbord sneltoetsen',
			'settings.keyboardShortcutsDescription' => 'Pas toetsenbord sneltoetsen aan',
			'settings.videoPlayerNavigation' => 'Videospeler navigatie',
			'settings.videoPlayerNavigationDescription' => 'Gebruik pijltjestoetsen om door de videospeler bediening te navigeren',
			'settings.debugLogging' => 'Debug logging',
			'settings.debugLoggingDescription' => 'Schakel gedetailleerde logging in voor probleemoplossing',
			'settings.viewLogs' => 'Bekijk logs',
			'settings.viewLogsDescription' => 'Bekijk applicatie logs',
			'settings.clearCache' => 'Cache wissen',
			'settings.clearCacheDescription' => 'Dit wist alle gecachte afbeeldingen en gegevens. De app kan langer duren om inhoud te laden na het wissen van de cache.',
			'settings.clearCacheSuccess' => 'Cache succesvol gewist',
			'settings.resetSettings' => 'Instellingen resetten',
			'settings.resetSettingsDescription' => 'Dit reset alle instellingen naar hun standaard waarden. Deze actie kan niet ongedaan gemaakt worden.',
			'settings.resetSettingsSuccess' => 'Instellingen succesvol gereset',
			'settings.shortcutsReset' => 'Sneltoetsen gereset naar standaard',
			'settings.about' => 'Over',
			'settings.aboutDescription' => 'App informatie en licenties',
			'settings.updates' => 'Updates',
			'settings.updateAvailable' => 'Update beschikbaar',
			'settings.checkForUpdates' => 'Controleer op updates',
			'settings.validationErrorEnterNumber' => 'Voer een geldig nummer in',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Duur moet tussen ${min} en ${max} ${unit} zijn',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Sneltoets al toegewezen aan ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Sneltoets bijgewerkt voor ${action}',
			'settings.autoSkip' => 'Automatisch Overslaan',
			'settings.autoSkipIntro' => 'Intro Automatisch Overslaan',
			'settings.autoSkipIntroDescription' => 'Intro-markeringen na enkele seconden automatisch overslaan',
			'settings.autoSkipCredits' => 'Credits Automatisch Overslaan',
			'settings.autoSkipCreditsDescription' => 'Credits automatisch overslaan en volgende aflevering afspelen',
			'settings.autoSkipDelay' => 'Vertraging Automatisch Overslaan',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => '${seconds} seconden wachten voor automatisch overslaan',
			'settings.downloads' => 'Downloads',
			'settings.downloadLocationDescription' => 'Kies waar gedownloade content wordt opgeslagen',
			'settings.downloadLocationDefault' => 'Standaard (App-opslag)',
			'settings.downloadLocationCustom' => 'Aangepaste Locatie',
			'settings.selectFolder' => 'Selecteer Map',
			'settings.resetToDefault' => 'Herstel naar Standaard',
			'settings.currentPath' => ({required Object path}) => 'Huidig: ${path}',
			'settings.downloadLocationChanged' => 'Downloadlocatie gewijzigd',
			'settings.downloadLocationReset' => 'Downloadlocatie hersteld naar standaard',
			'settings.downloadLocationInvalid' => 'Geselecteerde map is niet beschrijfbaar',
			'settings.downloadLocationSelectError' => 'Kan map niet selecteren',
			'settings.downloadOnWifiOnly' => 'Alleen via WiFi downloaden',
			'settings.downloadOnWifiOnlyDescription' => 'Voorkom downloads bij gebruik van mobiele data',
			'settings.cellularDownloadBlocked' => 'Downloads zijn uitgeschakeld bij mobiele data. Maak verbinding met WiFi of wijzig de instelling.',
			'settings.maxVolume' => 'Maximaal volume',
			'settings.maxVolumeDescription' => 'Volume boven 100% toestaan voor stille media',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Toon op Discord wat je aan het kijken bent',
			'settings.matchContentFrameRate' => 'Inhoudsframesnelheid afstemmen',
			'settings.matchContentFrameRateDescription' => 'Pas de schermverversingssnelheid aan op de video-inhoud, vermindert haperingen en bespaart batterij',
			'settings.requireProfileSelectionOnOpen' => 'Vraag om profiel bij openen',
			'settings.requireProfileSelectionOnOpenDescription' => 'Toon profielselectie telkens wanneer de app wordt geopend',
			'search.hint' => 'Zoek films, series, muziek...',
			'search.tryDifferentTerm' => 'Probeer een andere zoekterm',
			'search.searchYourMedia' => 'Zoek in je media',
			'search.enterTitleActorOrKeyword' => 'Voer een titel, acteur of trefwoord in',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Stel sneltoets in voor ${actionName}',
			'hotkeys.clearShortcut' => 'Wis sneltoets',
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
			'hotkeys.actions.speedIncrease' => 'Snelheid verhogen',
			'hotkeys.actions.speedDecrease' => 'Snelheid verlagen',
			'hotkeys.actions.speedReset' => 'Snelheid resetten',
			'hotkeys.actions.subSeekNext' => 'Naar volgende ondertitel',
			'hotkeys.actions.subSeekPrev' => 'Naar vorige ondertitel',
			'hotkeys.actions.shaderToggle' => 'Shaders aan/uit',
			'hotkeys.actions.skipMarker' => 'Intro/aftiteling overslaan',
			'pinEntry.enterPin' => 'Voer PIN in',
			'pinEntry.showPin' => 'Toon PIN',
			'pinEntry.hidePin' => 'Verberg PIN',
			'fileInfo.title' => 'Bestand info',
			'fileInfo.video' => 'Video',
			'fileInfo.audio' => 'Audio',
			'fileInfo.file' => 'Bestand',
			'fileInfo.advanced' => 'Geavanceerd',
			'fileInfo.codec' => 'Codec',
			'fileInfo.resolution' => 'Resolutie',
			'fileInfo.bitrate' => 'Bitrate',
			'fileInfo.frameRate' => 'Frame rate',
			'fileInfo.aspectRatio' => 'Beeldverhouding',
			'fileInfo.profile' => 'Profiel',
			'fileInfo.bitDepth' => 'Bit diepte',
			'fileInfo.colorSpace' => 'Kleurruimte',
			'fileInfo.colorRange' => 'Kleurbereik',
			'fileInfo.colorPrimaries' => 'Kleurprimaires',
			'fileInfo.chromaSubsampling' => 'Chroma subsampling',
			'fileInfo.channels' => 'Kanalen',
			'fileInfo.path' => 'Pad',
			'fileInfo.size' => 'Grootte',
			'fileInfo.container' => 'Container',
			'fileInfo.duration' => 'Duur',
			'fileInfo.optimizedForStreaming' => 'Geoptimaliseerd voor streaming',
			'fileInfo.has64bitOffsets' => '64-bit Offsets',
			'mediaMenu.markAsWatched' => 'Markeer als gekeken',
			'mediaMenu.markAsUnwatched' => 'Markeer als ongekeken',
			'mediaMenu.removeFromContinueWatching' => 'Verwijder uit Doorgaan met kijken',
			'mediaMenu.goToSeries' => 'Ga naar serie',
			'mediaMenu.goToSeason' => 'Ga naar seizoen',
			'mediaMenu.shufflePlay' => 'Willekeurig afspelen',
			'mediaMenu.fileInfo' => 'Bestand info',
			'mediaMenu.confirmDelete' => 'Weet je zeker dat je dit item van je bestandssysteem wilt verwijderen?',
			'mediaMenu.deleteMultipleWarning' => 'Meerdere items kunnen worden verwijderd.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Media-item succesvol verwijderd',
			'mediaMenu.mediaFailedToDelete' => 'Verwijderen van media-item mislukt',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, film',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, TV-serie',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'bekeken',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} procent bekeken',
			'accessibility.mediaCardUnwatched' => 'niet bekeken',
			'accessibility.tapToPlay' => 'Tik om af te spelen',
			'tooltips.shufflePlay' => 'Willekeurig afspelen',
			'tooltips.markAsWatched' => 'Markeer als gekeken',
			'tooltips.markAsUnwatched' => 'Markeer als ongekeken',
			'videoControls.audioLabel' => 'Audio',
			'videoControls.subtitlesLabel' => 'Ondertitels',
			'videoControls.resetToZero' => 'Reset naar 0ms',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount}${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label} speelt later af',
			'videoControls.playsEarlier' => ({required Object label}) => '${label} speelt eerder af',
			'videoControls.noOffset' => 'Geen offset',
			'videoControls.letterbox' => 'Letterbox',
			'videoControls.fillScreen' => 'Vul scherm',
			'videoControls.stretch' => 'Uitrekken',
			'videoControls.lockRotation' => 'Vergrendel rotatie',
			'videoControls.unlockRotation' => 'Ontgrendel rotatie',
			'videoControls.timerActive' => 'Timer actief',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Afspelen wordt gepauzeerd over ${duration}',
			'videoControls.sleepTimerCompleted' => 'Slaaptimer voltooid - afspelen gepauzeerd',
			'videoControls.autoPlayNext' => 'Automatisch volgende afspelen',
			'videoControls.playNext' => 'Volgende afspelen',
			'videoControls.playButton' => 'Afspelen',
			'videoControls.pauseButton' => 'Pauzeren',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Terugspoelen ${seconds} seconden',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Vooruitspoelen ${seconds} seconden',
			'videoControls.previousButton' => 'Vorige aflevering',
			'videoControls.nextButton' => 'Volgende aflevering',
			'videoControls.previousChapterButton' => 'Vorig hoofdstuk',
			'videoControls.nextChapterButton' => 'Volgend hoofdstuk',
			'videoControls.muteButton' => 'Dempen',
			'videoControls.unmuteButton' => 'Dempen opheffen',
			'videoControls.settingsButton' => 'Video-instellingen',
			'videoControls.audioTrackButton' => 'Audiosporen',
			'videoControls.subtitlesButton' => 'Ondertitels',
			'videoControls.chaptersButton' => 'Hoofdstukken',
			'videoControls.versionsButton' => 'Videoversies',
			'videoControls.pipButton' => 'Beeld-in-beeld modus',
			'videoControls.aspectRatioButton' => 'Beeldverhouding',
			'videoControls.fullscreenButton' => 'Volledig scherm activeren',
			'videoControls.exitFullscreenButton' => 'Volledig scherm verlaten',
			'videoControls.alwaysOnTopButton' => 'Altijd bovenop',
			'videoControls.rotationLockButton' => 'Rotatievergrendeling',
			'videoControls.timelineSlider' => 'Videotijdlijn',
			'videoControls.volumeSlider' => 'Volumeniveau',
			'videoControls.endsAt' => ({required Object time}) => 'Eindigt om ${time}',
			'videoControls.pipFailed' => 'Beeld-in-beeld kon niet worden gestart',
			'videoControls.pipErrors.androidVersion' => 'Vereist Android 8.0 of nieuwer',
			'videoControls.pipErrors.permissionDisabled' => 'Beeld-in-beeld toestemming is uitgeschakeld. Schakel deze in via Instellingen > Apps > Plezy > Beeld-in-beeld',
			'videoControls.pipErrors.notSupported' => 'Dit apparaat ondersteunt geen beeld-in-beeld modus',
			'videoControls.pipErrors.failed' => 'Beeld-in-beeld kon niet worden gestart',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Er is een fout opgetreden: ${error}',
			'videoControls.chapters' => 'Hoofdstukken',
			'videoControls.noChaptersAvailable' => 'Geen hoofdstukken beschikbaar',
			'userStatus.admin' => 'Beheerder',
			'userStatus.restricted' => 'Beperkt',
			'userStatus.protected' => 'Beschermd',
			'userStatus.current' => 'HUIDIG',
			'messages.markedAsWatched' => 'Gemarkeerd als gekeken',
			'messages.markedAsUnwatched' => 'Gemarkeerd als ongekeken',
			'messages.markedAsWatchedOffline' => 'Gemarkeerd als gekeken (sync wanneer online)',
			'messages.markedAsUnwatchedOffline' => 'Gemarkeerd als ongekeken (sync wanneer online)',
			'messages.removedFromContinueWatching' => 'Verwijderd uit Doorgaan met kijken',
			'messages.errorLoading' => ({required Object error}) => 'Fout: ${error}',
			'messages.fileInfoNotAvailable' => 'Bestand informatie niet beschikbaar',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Fout bij laden bestand info: ${error}',
			'messages.errorLoadingSeries' => 'Fout bij laden serie',
			'messages.errorLoadingSeason' => 'Fout bij laden seizoen',
			'messages.musicNotSupported' => 'Muziek afspelen wordt nog niet ondersteund',
			'messages.logsCleared' => 'Logs gewist',
			'messages.logsCopied' => 'Logs gekopieerd naar klembord',
			'messages.noLogsAvailable' => 'Geen logs beschikbaar',
			'messages.libraryScanning' => ({required Object title}) => 'Scannen "${title}"...',
			'messages.libraryScanStarted' => ({required Object title}) => 'Bibliotheek scan gestart voor "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Kon bibliotheek niet scannen: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Metadata vernieuwen voor "${title}"...',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Metadata vernieuwen gestart voor "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Kon metadata niet vernieuwen: ${error}',
			'messages.logoutConfirm' => 'Weet je zeker dat je wilt uitloggen?',
			'messages.noSeasonsFound' => 'Geen seizoenen gevonden',
			'messages.noEpisodesFound' => 'Geen afleveringen gevonden in eerste seizoen',
			'messages.noEpisodesFoundGeneral' => 'Geen afleveringen gevonden',
			'messages.noResultsFound' => 'Geen resultaten gevonden',
			'messages.sleepTimerSet' => ({required Object label}) => 'Slaap timer ingesteld voor ${label}',
			'messages.noItemsAvailable' => 'Geen items beschikbaar',
			'messages.failedToCreatePlayQueueNoItems' => 'Kan afspeelwachtrij niet maken - geen items',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Afspelen van ${action} mislukt: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Overschakelen naar compatibele speler...',
			'messages.logsUploaded' => 'Logs uploaded',
			'messages.logsUploadFailed' => 'Failed to upload logs',
			'messages.logId' => 'Log ID',
			'subtitlingStyling.stylingOptions' => 'Opmaak opties',
			'subtitlingStyling.fontSize' => 'Lettergrootte',
			'subtitlingStyling.textColor' => 'Tekstkleur',
			'subtitlingStyling.borderSize' => 'Rand grootte',
			'subtitlingStyling.borderColor' => 'Randkleur',
			'subtitlingStyling.backgroundOpacity' => 'Achtergrond transparantie',
			'subtitlingStyling.backgroundColor' => 'Achtergrondkleur',
			'subtitlingStyling.position' => 'Position',
			'mpvConfig.title' => 'MPV-configuratie',
			'mpvConfig.description' => 'Geavanceerde videospeler-instellingen',
			'mpvConfig.properties' => 'Eigenschappen',
			'mpvConfig.presets' => 'Voorinstellingen',
			'mpvConfig.noProperties' => 'Geen eigenschappen geconfigureerd',
			'mpvConfig.noPresets' => 'Geen opgeslagen voorinstellingen',
			'mpvConfig.addProperty' => 'Eigenschap toevoegen',
			'mpvConfig.editProperty' => 'Eigenschap bewerken',
			'mpvConfig.deleteProperty' => 'Eigenschap verwijderen',
			'mpvConfig.propertyKey' => 'Eigenschapssleutel',
			'mpvConfig.propertyKeyHint' => 'bijv. hwdec, demuxer-max-bytes',
			'mpvConfig.propertyValue' => 'Eigenschapswaarde',
			'mpvConfig.propertyValueHint' => 'bijv. auto, 256000000',
			'mpvConfig.saveAsPreset' => 'Opslaan als voorinstelling...',
			'mpvConfig.presetName' => 'Naam voorinstelling',
			'mpvConfig.presetNameHint' => 'Voer een naam in voor deze voorinstelling',
			'mpvConfig.loadPreset' => 'Laden',
			'mpvConfig.deletePreset' => 'Verwijderen',
			'mpvConfig.presetSaved' => 'Voorinstelling opgeslagen',
			'mpvConfig.presetLoaded' => 'Voorinstelling geladen',
			'mpvConfig.presetDeleted' => 'Voorinstelling verwijderd',
			'mpvConfig.confirmDeletePreset' => 'Weet je zeker dat je deze voorinstelling wilt verwijderen?',
			'mpvConfig.confirmDeleteProperty' => 'Weet je zeker dat je deze eigenschap wilt verwijderen?',
			'mpvConfig.entriesCount' => ({required Object count}) => '${count} items',
			'dialog.confirmAction' => 'Bevestig actie',
			'discover.title' => 'Ontdekken',
			'discover.switchProfile' => 'Wissel van profiel',
			'discover.noContentAvailable' => 'Geen inhoud beschikbaar',
			'discover.addMediaToLibraries' => 'Voeg wat media toe aan je bibliotheken',
			'discover.continueWatching' => 'Verder kijken',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Overzicht',
			'discover.cast' => 'Acteurs',
			'discover.seasons' => 'Seizoenen',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Leeftijd',
			'discover.episodeCount' => ({required Object count}) => '${count} afleveringen',
			'discover.watchedProgress' => ({required Object watched, required Object total}) => '${watched}/${total} gekeken',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'TV Serie',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} min over',
			'errors.searchFailed' => ({required Object error}) => 'Zoeken mislukt: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => 'Verbinding time-out tijdens laden ${context}',
			'errors.connectionFailed' => 'Kan geen verbinding maken met Plex server',
			'errors.failedToLoad' => ({required Object context, required Object error}) => 'Kon ${context} niet laden: ${error}',
			'errors.noClientAvailable' => 'Geen client beschikbaar',
			'errors.authenticationFailed' => ({required Object error}) => 'Authenticatie mislukt: ${error}',
			'errors.couldNotLaunchUrl' => 'Kon auth URL niet openen',
			'errors.pleaseEnterToken' => 'Voer een token in',
			'errors.invalidToken' => 'Ongeldig token',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Kon token niet verifiëren: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Kon niet wisselen naar ${displayName}',
			'libraries.title' => 'Bibliotheken',
			'libraries.scanLibraryFiles' => 'Scan bibliotheek bestanden',
			'libraries.scanLibrary' => 'Scan bibliotheek',
			'libraries.analyze' => 'Analyseren',
			'libraries.analyzeLibrary' => 'Analyseer bibliotheek',
			'libraries.refreshMetadata' => 'Vernieuw metadata',
			'libraries.emptyTrash' => 'Prullenbak legen',
			'libraries.emptyingTrash' => ({required Object title}) => 'Prullenbak legen voor "${title}"...',
			'libraries.trashEmptied' => ({required Object title}) => 'Prullenbak geleegd voor "${title}"',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Kon prullenbak niet legen: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'Analyseren "${title}"...',
			'libraries.analysisStarted' => ({required Object title}) => 'Analyse gestart voor "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Kon bibliotheek niet analyseren: ${error}',
			'libraries.noLibrariesFound' => 'Geen bibliotheken gevonden',
			'libraries.thisLibraryIsEmpty' => 'Deze bibliotheek is leeg',
			'libraries.all' => 'Alles',
			'libraries.clearAll' => 'Alles wissen',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'Weet je zeker dat je "${title}" wilt scannen?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'Weet je zeker dat je "${title}" wilt analyseren?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'Weet je zeker dat je metadata wilt vernieuwen voor "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'Weet je zeker dat je de prullenbak wilt legen voor "${title}"?',
			'libraries.manageLibraries' => 'Beheer bibliotheken',
			'libraries.sort' => 'Sorteren',
			'libraries.sortBy' => 'Sorteer op',
			'libraries.filters' => 'Filters',
			'libraries.confirmActionMessage' => 'Weet je zeker dat je deze actie wilt uitvoeren?',
			'libraries.showLibrary' => 'Toon bibliotheek',
			'libraries.hideLibrary' => 'Verberg bibliotheek',
			'libraries.libraryOptions' => 'Bibliotheek opties',
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
			'libraries.groupings.all' => 'Alles',
			'libraries.groupings.movies' => 'Films',
			'libraries.groupings.shows' => 'Series',
			'libraries.groupings.seasons' => 'Seizoenen',
			'libraries.groupings.episodes' => 'Afleveringen',
			'libraries.groupings.folders' => 'Mappen',
			'about.title' => 'Over',
			'about.openSourceLicenses' => 'Open Source licenties',
			'about.versionLabel' => ({required Object version}) => 'Versie ${version}',
			'about.appDescription' => 'Een mooie Plex client voor Flutter',
			'about.viewLicensesDescription' => 'Bekijk licenties van third-party bibliotheken',
			'serverSelection.allServerConnectionsFailed' => 'Kon niet verbinden met servers. Controleer je netwerk en probeer opnieuw.',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Geen servers gevonden voor ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Kon servers niet laden: ${error}',
			'hubDetail.title' => 'Titel',
			'hubDetail.releaseYear' => 'Uitgavejaar',
			'hubDetail.dateAdded' => 'Datum toegevoegd',
			'hubDetail.rating' => 'Beoordeling',
			'hubDetail.noItemsFound' => 'Geen items gevonden',
			'logs.clearLogs' => 'Wis logs',
			'logs.copyLogs' => 'Kopieer logs',
			'logs.uploadLogs' => 'Upload Logs',
			'logs.error' => 'Fout:',
			'logs.stackTrace' => 'Stacktracering:',
			'licenses.relatedPackages' => 'Gerelateerde pakketten',
			'licenses.license' => 'Licentie',
			'licenses.licenseNumber' => ({required Object number}) => 'Licentie ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licenties',
			'navigation.libraries' => 'Bibliotheken',
			'navigation.downloads' => 'Downloads',
			'navigation.liveTv' => 'Live TV',
			'liveTv.title' => 'Live TV',
			'liveTv.channels' => 'Zenders',
			'liveTv.guide' => 'Gids',
			'liveTv.recordings' => 'Opnames',
			'liveTv.subscriptions' => 'Opnameregels',
			'liveTv.scheduled' => 'Gepland',
			'liveTv.noChannels' => 'Geen zenders beschikbaar',
			'liveTv.noDvr' => 'Geen DVR geconfigureerd op een server',
			'liveTv.tuneFailed' => 'Kan zender niet afstemmen',
			'liveTv.loading' => 'Zenders laden...',
			'liveTv.nowPlaying' => 'Nu aan het afspelen',
			'liveTv.record' => 'Opnemen',
			'liveTv.recordSeries' => 'Serie opnemen',
			'liveTv.cancelRecording' => 'Opname annuleren',
			'liveTv.deleteSubscription' => 'Opnameregel verwijderen',
			'liveTv.deleteSubscriptionConfirm' => 'Weet je zeker dat je deze opnameregel wilt verwijderen?',
			'liveTv.subscriptionDeleted' => 'Opnameregel verwijderd',
			'liveTv.noPrograms' => 'Geen programmagegevens beschikbaar',
			'liveTv.noRecordings' => 'Geen opnames gepland',
			'liveTv.noSubscriptions' => 'Geen opnameregels',
			'liveTv.channelNumber' => ({required Object number}) => 'Kanaal ${number}',
			'liveTv.live' => 'LIVE',
			'liveTv.hd' => 'HD',
			'liveTv.premiere' => 'NIEUW',
			'liveTv.reloadGuide' => 'Gids herladen',
			'liveTv.guideReloaded' => 'Gidsgegevens herladen',
			'liveTv.allChannels' => 'Alle zenders',
			'liveTv.now' => 'Nu',
			'liveTv.today' => 'Vandaag',
			'liveTv.midnight' => 'Middernacht',
			'liveTv.overnight' => 'Nacht',
			'liveTv.morning' => 'Ochtend',
			'liveTv.daytime' => 'Overdag',
			'liveTv.evening' => 'Avond',
			'liveTv.lateNight' => 'Late avond',
			'liveTv.whatsOn' => 'Nu op TV',
			'liveTv.watchChannel' => 'Kanaal bekijken',
			'downloads.title' => 'Downloads',
			'downloads.manage' => 'Beheren',
			'downloads.tvShows' => 'Series',
			'downloads.movies' => 'Films',
			'downloads.noDownloads' => 'Nog geen downloads',
			'downloads.noDownloadsDescription' => 'Gedownloade content verschijnt hier voor offline weergave',
			'downloads.downloadNow' => 'Download',
			_ => null,
		} ?? switch (path) {
			'downloads.deleteDownload' => 'Download verwijderen',
			'downloads.retryDownload' => 'Download opnieuw proberen',
			'downloads.downloadQueued' => 'Download in wachtrij',
			'downloads.episodesQueued' => ({required Object count}) => '${count} afleveringen in wachtrij voor download',
			'downloads.downloadDeleted' => 'Download verwijderd',
			'downloads.deleteConfirm' => ({required Object title}) => 'Weet je zeker dat je "${title}" wilt verwijderen? Het gedownloade bestand wordt van je apparaat verwijderd.',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Verwijderen van ${title}... (${current} van ${total})',
			'downloads.noDownloadsTree' => 'Geen downloads',
			'downloads.pauseAll' => 'Alles pauzeren',
			'downloads.resumeAll' => 'Alles hervatten',
			'downloads.deleteAll' => 'Alles verwijderen',
			'playlists.title' => 'Afspeellijsten',
			'playlists.noPlaylists' => 'Geen afspeellijsten gevonden',
			'playlists.create' => 'Afspeellijst maken',
			'playlists.playlistName' => 'Naam afspeellijst',
			'playlists.enterPlaylistName' => 'Voer naam afspeellijst in',
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
			'playlists.selectPlaylist' => 'Selecteer afspeellijst',
			'playlists.createNewPlaylist' => 'Nieuwe afspeellijst maken',
			'playlists.errorCreating' => 'Fout bij maken afspeellijst',
			'playlists.errorDeleting' => 'Fout bij verwijderen afspeellijst',
			'playlists.errorLoading' => 'Fout bij laden afspeellijsten',
			'playlists.errorAdding' => 'Fout bij toevoegen aan afspeellijst',
			'playlists.errorReordering' => 'Fout bij herschikken van afspeellijstitem',
			'playlists.errorRemoving' => 'Fout bij verwijderen uit afspeellijst',
			'playlists.playlist' => 'Afspeellijst',
			'collections.title' => 'Collecties',
			'collections.collection' => 'Collectie',
			'collections.empty' => 'Collectie is leeg',
			'collections.unknownLibrarySection' => 'Kan niet verwijderen: onbekende bibliotheeksectie',
			'collections.deleteCollection' => 'Collectie verwijderen',
			'collections.deleteConfirm' => ({required Object title}) => 'Weet je zeker dat je "${title}" wilt verwijderen? Deze actie kan niet ongedaan worden gemaakt.',
			'collections.deleted' => 'Collectie verwijderd',
			'collections.deleteFailed' => 'Collectie verwijderen mislukt',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Collectie verwijderen mislukt: ${error}',
			'collections.failedToLoadItems' => ({required Object error}) => 'Collectie-items laden mislukt: ${error}',
			'collections.selectCollection' => 'Selecteer collectie',
			'collections.createNewCollection' => 'Nieuwe collectie maken',
			'collections.collectionName' => 'Collectienaam',
			'collections.enterCollectionName' => 'Voer collectienaam in',
			'collections.addedToCollection' => 'Toegevoegd aan collectie',
			'collections.errorAddingToCollection' => 'Fout bij toevoegen aan collectie',
			'collections.created' => 'Collectie gemaakt',
			'collections.removeFromCollection' => 'Verwijderen uit collectie',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => '"${title}" uit deze collectie verwijderen?',
			'collections.removedFromCollection' => 'Uit collectie verwijderd',
			'collections.removeFromCollectionFailed' => 'Verwijderen uit collectie mislukt',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Fout bij verwijderen uit collectie: ${error}',
			'watchTogether.title' => 'Samen Kijken',
			'watchTogether.description' => 'Kijk synchroon met vrienden en familie',
			'watchTogether.createSession' => 'Sessie Maken',
			'watchTogether.creating' => 'Maken...',
			'watchTogether.joinSession' => 'Sessie Deelnemen',
			'watchTogether.joining' => 'Deelnemen...',
			'watchTogether.controlMode' => 'Controlemodus',
			'watchTogether.controlModeQuestion' => 'Wie kan het afspelen bedienen?',
			'watchTogether.hostOnly' => 'Alleen Host',
			'watchTogether.anyone' => 'Iedereen',
			'watchTogether.hostingSession' => 'Sessie Hosten',
			'watchTogether.inSession' => 'In Sessie',
			'watchTogether.sessionCode' => 'Sessiecode',
			'watchTogether.hostControlsPlayback' => 'Host bedient het afspelen',
			'watchTogether.anyoneCanControl' => 'Iedereen kan het afspelen bedienen',
			'watchTogether.hostControls' => 'Host bedient',
			'watchTogether.anyoneControls' => 'Iedereen bedient',
			'watchTogether.participants' => 'Deelnemers',
			'watchTogether.host' => 'Host',
			'watchTogether.hostBadge' => 'HOST',
			'watchTogether.youAreHost' => 'Jij bent de host',
			'watchTogether.watchingWithOthers' => 'Kijken met anderen',
			'watchTogether.endSession' => 'Sessie Beëindigen',
			'watchTogether.leaveSession' => 'Sessie Verlaten',
			'watchTogether.endSessionQuestion' => 'Sessie Beëindigen?',
			'watchTogether.leaveSessionQuestion' => 'Sessie Verlaten?',
			'watchTogether.endSessionConfirm' => 'Dit beëindigt de sessie voor alle deelnemers.',
			'watchTogether.leaveSessionConfirm' => 'Je wordt uit de sessie verwijderd.',
			'watchTogether.endSessionConfirmOverlay' => 'Dit beëindigt de kijksessie voor alle deelnemers.',
			'watchTogether.leaveSessionConfirmOverlay' => 'Je wordt losgekoppeld van de kijksessie.',
			'watchTogether.end' => 'Beëindigen',
			'watchTogether.leave' => 'Verlaten',
			'watchTogether.syncing' => 'Synchroniseren...',
			'watchTogether.joinWatchSession' => 'Kijksessie Deelnemen',
			'watchTogether.enterCodeHint' => 'Voer 8-teken code in',
			'watchTogether.pasteFromClipboard' => 'Plakken van klembord',
			'watchTogether.pleaseEnterCode' => 'Voer een sessiecode in',
			'watchTogether.codeMustBe8Chars' => 'Sessiecode moet 8 tekens zijn',
			'watchTogether.joinInstructions' => 'Voer de sessiecode in die door de host is gedeeld om deel te nemen aan hun kijksessie.',
			'watchTogether.failedToCreate' => 'Sessie maken mislukt',
			'watchTogether.failedToJoin' => 'Sessie deelnemen mislukt',
			'watchTogether.sessionCodeCopied' => 'Sessiecode gekopieerd naar klembord',
			'watchTogether.relayUnreachable' => 'De relayserver is niet bereikbaar. Dit kan worden veroorzaakt doordat je internetprovider de verbinding blokkeert. Je kunt het toch proberen, maar Watch Together werkt mogelijk niet.',
			'watchTogether.reconnectingToHost' => 'Opnieuw verbinden met host...',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} is toegetreden',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} heeft de sessie verlaten',
			'shaders.title' => 'Shaders',
			'shaders.noShaderDescription' => 'Geen videoverbetering',
			'shaders.nvscalerDescription' => 'NVIDIA-beeldschaling voor scherpere video',
			'shaders.qualityFast' => 'Snel',
			'shaders.qualityHQ' => 'Hoge kwaliteit',
			'shaders.mode' => 'Modus',
			'companionRemote.title' => 'Companion Remote',
			'companionRemote.connectToDevice' => 'Verbinden met apparaat',
			'companionRemote.hostRemoteSession' => 'Externe sessie hosten',
			'companionRemote.controlThisDevice' => 'Bedien dit apparaat met je telefoon',
			'companionRemote.remoteControl' => 'Afstandsbediening',
			'companionRemote.controlDesktop' => 'Bedien een desktop-apparaat',
			'companionRemote.connectedTo' => ({required Object name}) => 'Verbonden met ${name}',
			'companionRemote.session.creatingSession' => 'Externe sessie aanmaken...',
			'companionRemote.session.failedToCreate' => 'Kan externe sessie niet aanmaken:',
			'companionRemote.session.noSession' => 'Geen sessie beschikbaar',
			'companionRemote.session.scanQrCode' => 'Scan QR-code',
			'companionRemote.session.orEnterManually' => 'Of voer handmatig in',
			'companionRemote.session.hostAddress' => 'Hostadres',
			'companionRemote.session.sessionId' => 'Sessie-ID',
			'companionRemote.session.pin' => 'PIN',
			'companionRemote.session.connected' => 'Verbonden',
			'companionRemote.session.waitingForConnection' => 'Wachten op verbinding...',
			'companionRemote.session.usePhoneToControl' => 'Gebruik je mobiele apparaat om deze app te bedienen',
			'companionRemote.session.copiedToClipboard' => ({required Object label}) => '${label} gekopieerd naar klembord',
			'companionRemote.session.copyToClipboard' => 'Kopieer naar klembord',
			'companionRemote.session.newSession' => 'Nieuwe sessie',
			'companionRemote.session.minimize' => 'Minimaliseren',
			'companionRemote.pairing.recent' => 'Recent',
			'companionRemote.pairing.scan' => 'Scannen',
			'companionRemote.pairing.manual' => 'Handmatig',
			'companionRemote.pairing.recentConnections' => 'Recente verbindingen',
			'companionRemote.pairing.quickReconnect' => 'Snel opnieuw verbinden met eerder gekoppelde apparaten',
			'companionRemote.pairing.pairWithDesktop' => 'Koppelen met desktop',
			'companionRemote.pairing.enterSessionDetails' => 'Voer de sessiegegevens in die op je desktop-apparaat worden getoond',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.sessionIdHint' => 'Voer 8-tekens sessie-ID in',
			'companionRemote.pairing.pinHint' => 'Voer 6-cijferige PIN in',
			'companionRemote.pairing.connecting' => 'Verbinden...',
			'companionRemote.pairing.tips' => 'Tips',
			'companionRemote.pairing.tipDesktop' => 'Open Plezy op je desktop en schakel Companion Remote in via instellingen of menu',
			'companionRemote.pairing.tipScan' => 'Gebruik het tabblad Scannen om snel te koppelen door de QR-code op je desktop te scannen',
			'companionRemote.pairing.tipWifi' => 'Zorg ervoor dat beide apparaten op hetzelfde WiFi-netwerk zitten',
			'companionRemote.pairing.cameraPermissionRequired' => 'Cameratoestemming is vereist om QR-codes te scannen.\nGeef cameratoegang in je apparaatinstellingen.',
			'companionRemote.pairing.cameraError' => ({required Object error}) => 'Kan camera niet starten: ${error}',
			'companionRemote.pairing.scanInstruction' => 'Richt je camera op de QR-code die op je desktop wordt getoond',
			'companionRemote.pairing.noRecentConnections' => 'Geen recente verbindingen',
			'companionRemote.pairing.connectUsingManual' => 'Verbind met een apparaat via Handmatige invoer om te beginnen',
			'companionRemote.pairing.invalidQrCode' => 'Ongeldig QR-codeformaat',
			'companionRemote.pairing.removeRecentConnection' => 'Recente verbinding verwijderen',
			'companionRemote.pairing.removeConfirm' => ({required Object name}) => '"${name}" verwijderen uit recente verbindingen?',
			'companionRemote.pairing.validationHostRequired' => 'Voer een hostadres in',
			'companionRemote.pairing.validationHostFormat' => 'Formaat moet IP:poort zijn (bijv. 192.168.1.100:48632)',
			'companionRemote.pairing.validationSessionIdRequired' => 'Voer een sessie-ID in',
			'companionRemote.pairing.validationSessionIdLength' => 'Sessie-ID moet 8 tekens zijn',
			'companionRemote.pairing.validationPinRequired' => 'Voer een PIN in',
			'companionRemote.pairing.validationPinLength' => 'PIN moet 6 cijfers zijn',
			'companionRemote.pairing.connectionTimedOut' => 'Verbinding verlopen. Controleer de sessie-ID en PIN.',
			'companionRemote.pairing.sessionNotFound' => 'Kan de sessie niet vinden. Controleer je gegevens.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Verbinden mislukt: ${error}',
			'companionRemote.pairing.failedToLoadRecent' => ({required Object error}) => 'Kan recente sessies niet laden: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'Wil je de verbinding met de externe sessie verbreken?',
			'companionRemote.remote.reconnecting' => 'Opnieuw verbinden...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Poging ${current} van 5',
			'companionRemote.remote.retryNow' => 'Nu opnieuw proberen',
			'companionRemote.remote.connectionError' => 'Verbindingsfout',
			'companionRemote.remote.notConnected' => 'Niet verbonden',
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
			'videoSettings.playbackSettings' => 'Afspeelinstellingen',
			'videoSettings.playbackSpeed' => 'Afspeelsnelheid',
			'videoSettings.sleepTimer' => 'Slaaptimer',
			'videoSettings.audioSync' => 'Audio synchronisatie',
			'videoSettings.subtitleSync' => 'Ondertitel synchronisatie',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => 'Audio-uitvoer',
			'videoSettings.performanceOverlay' => 'Prestatie-overlay',
			'externalPlayer.title' => 'Externe speler',
			'externalPlayer.useExternalPlayer' => 'Externe speler gebruiken',
			'externalPlayer.useExternalPlayerDescription' => 'Open video\'s in een externe app in plaats van de ingebouwde speler',
			'externalPlayer.selectPlayer' => 'Speler selecteren',
			'externalPlayer.systemDefault' => 'Systeemstandaard',
			'externalPlayer.addCustomPlayer' => 'Aangepaste speler toevoegen',
			'externalPlayer.playerName' => 'Spelernaam',
			'externalPlayer.playerCommand' => 'Commando',
			'externalPlayer.playerPackage' => 'Pakketnaam',
			'externalPlayer.playerUrlScheme' => 'URL-schema',
			'externalPlayer.customPlayer' => 'Aangepaste speler',
			'externalPlayer.off' => 'Uit',
			'externalPlayer.launchFailed' => 'Kan externe speler niet openen',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} is niet geïnstalleerd',
			'externalPlayer.playInExternalPlayer' => 'Afspelen in externe speler',
			_ => null,
		};
	}
}
