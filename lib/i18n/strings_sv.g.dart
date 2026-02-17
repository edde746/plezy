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
	@override late final _TranslationsPinEntrySv pinEntry = _TranslationsPinEntrySv._(_root);
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
	@override late final _TranslationsDownloadsSv downloads = _TranslationsDownloadsSv._(_root);
	@override late final _TranslationsPlaylistsSv playlists = _TranslationsPlaylistsSv._(_root);
	@override late final _TranslationsCollectionsSv collections = _TranslationsCollectionsSv._(_root);
	@override late final _TranslationsWatchTogetherSv watchTogether = _TranslationsWatchTogetherSv._(_root);
	@override late final _TranslationsShadersSv shaders = _TranslationsShadersSv._(_root);
	@override late final _TranslationsCompanionRemoteSv companionRemote = _TranslationsCompanionRemoteSv._(_root);
	@override late final _TranslationsVideoSettingsSv videoSettings = _TranslationsVideoSettingsSv._(_root);
	@override late final _TranslationsExternalPlayerSv externalPlayer = _TranslationsExternalPlayerSv._(_root);
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
	@override String get debugEnterToken => 'Debug: Ange Plex-token';
	@override String get plexTokenLabel => 'Plex-autentiseringstoken';
	@override String get plexTokenHint => 'Ange din Plex.tv-token';
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
	@override String get remove => 'Ta bort';
	@override String get paste => 'Klistra in';
	@override String get connect => 'Anslut';
	@override String get disconnect => 'Koppla från';
	@override String get play => 'Spela';
	@override String get pause => 'Pausa';
	@override String get resume => 'Återuppta';
	@override String get error => 'Fel';
	@override String get search => 'Sök';
	@override String get home => 'Hem';
	@override String get back => 'Tillbaka';
	@override String get settings => 'Inställningar';
	@override String get mute => 'Ljud av';
	@override String get ok => 'OK';
	@override String get loading => 'Laddar...';
	@override String get reconnect => 'Återanslut';
	@override String get exitConfirmTitle => 'Avsluta appen?';
	@override String get exitConfirmMessage => 'Är du säker på att du vill avsluta?';
	@override String get dontAskAgain => 'Fråga inte igen';
	@override String get exit => 'Avsluta';
}

// Path: screens
class _TranslationsScreensSv implements TranslationsScreensEn {
	_TranslationsScreensSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licenser';
	@override String get switchProfile => 'Byt profil';
	@override String get subtitleStyling => 'Undertext-styling';
	@override String get mpvConfig => 'MPV-konfiguration';
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
	@override String get language => 'Språk';
	@override String get theme => 'Tema';
	@override String get appearance => 'Utseende';
	@override String get videoPlayback => 'Videouppspelning';
	@override String get advanced => 'Avancerat';
	@override String get episodePosterMode => 'Avsnittsaffisch-stil';
	@override String get seriesPoster => 'Serieaffisch';
	@override String get seriesPosterDescription => 'Visa seriens affisch för alla avsnitt';
	@override String get seasonPoster => 'Säsongsaffisch';
	@override String get seasonPosterDescription => 'Visa säsongens affisch för avsnitt';
	@override String get episodeThumbnail => 'Avsnittsminiatyr';
	@override String get episodeThumbnailDescription => 'Visa 16:9 skärmbild från avsnittet';
	@override String get showHeroSectionDescription => 'Visa utvalda innehållskarusell på startsidan';
	@override String get secondsLabel => 'Sekunder';
	@override String get minutesLabel => 'Minuter';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Ange tid (${min}-${max})';
	@override String get systemTheme => 'System';
	@override String get systemThemeDescription => 'Följ systeminställningar';
	@override String get lightTheme => 'Ljust';
	@override String get darkTheme => 'Mörkt';
	@override String get oledTheme => 'OLED';
	@override String get oledThemeDescription => 'Rent svart för OLED-skärmar';
	@override String get libraryDensity => 'Biblioteksdensitet';
	@override String get compact => 'Kompakt';
	@override String get compactDescription => 'Mindre kort, fler objekt synliga';
	@override String get normal => 'Normal';
	@override String get normalDescription => 'Standardstorlek';
	@override String get comfortable => 'Bekväm';
	@override String get comfortableDescription => 'Större kort, färre objekt synliga';
	@override String get viewMode => 'Visningsläge';
	@override String get gridView => 'Rutnät';
	@override String get gridViewDescription => 'Visa objekt i rutnätslayout';
	@override String get listView => 'Lista';
	@override String get listViewDescription => 'Visa objekt i listlayout';
	@override String get showHeroSection => 'Visa hjältesektion';
	@override String get useGlobalHubs => 'Använd Plex hem-layout';
	@override String get useGlobalHubsDescription => 'Visar startsidans hubbar som den officiella Plex-klienten. När av visas rekommendationer per bibliotek istället.';
	@override String get showServerNameOnHubs => 'Visa servernamn på hubbar';
	@override String get showServerNameOnHubsDescription => 'Visa alltid servernamnet i hubbtitlar. När av visas endast för duplicerade hubbnamn.';
	@override String get alwaysKeepSidebarOpen => 'Håll sidofältet alltid öppet';
	@override String get alwaysKeepSidebarOpenDescription => 'Sidofältet förblir expanderat och innehållsytan anpassas';
	@override String get showUnwatchedCount => 'Visa antal osedda';
	@override String get showUnwatchedCountDescription => 'Visa antal osedda avsnitt för serier och säsonger';
	@override String get playerBackend => 'Spelarmotor';
	@override String get exoPlayer => 'ExoPlayer (Rekommenderad)';
	@override String get exoPlayerDescription => 'Android-nativ spelare med bättre hårdvarustöd';
	@override String get mpv => 'MPV';
	@override String get mpvDescription => 'Avancerad spelare med fler funktioner och ASS-undertextstöd';
	@override String get hardwareDecoding => 'Hårdvaruavkodning';
	@override String get hardwareDecodingDescription => 'Använd hårdvaruacceleration när tillgängligt';
	@override String get bufferSize => 'Bufferstorlek';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get subtitleStyling => 'Undertext-styling';
	@override String get subtitleStylingDescription => 'Anpassa undertextutseende';
	@override String get smallSkipDuration => 'Kort hoppvaraktighet';
	@override String get largeSkipDuration => 'Lång hoppvaraktighet';
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
	@override String get shortcutsReset => 'Genvägar återställda till standard';
	@override String get about => 'Om';
	@override String get aboutDescription => 'Appinformation och licenser';
	@override String get updates => 'Uppdateringar';
	@override String get updateAvailable => 'Uppdatering tillgänglig';
	@override String get checkForUpdates => 'Kontrollera uppdateringar';
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
	@override String get autoDownloadNewEpisodes => 'Download new episodes automatically';
	@override String get autoDownloadNewEpisodesDescription => 'Automatically download new episodes in your downloaded seasons';
	@override String get autoDownloadNewSeasons => 'Download new seasons automatically';
	@override String get autoDownloadNewSeasonsDescription => 'Automatically download new seasons for your downloaded shows';
	@override String get cellularDownloadBlocked => 'Nedladdningar är inaktiverade på mobildata. Anslut till WiFi eller ändra inställningen.';
	@override String get maxVolume => 'Maximal volym';
	@override String get maxVolumeDescription => 'Tillåt volym över 100% för tyst media';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Visa vad du tittar på i Discord';
	@override String get matchContentFrameRate => 'Matcha innehållets bildfrekvens';
	@override String get matchContentFrameRateDescription => 'Justera skärmens uppdateringsfrekvens för att matcha videoinnehållet, minskar hackighet och sparar batteri';
	@override String get requireProfileSelectionOnOpen => 'Fråga efter profil vid appstart';
	@override String get requireProfileSelectionOnOpenDescription => 'Visa profilval varje gång appen öppnas';
	@override String get confirmExitOnBack => 'Bekräfta innan avslut';
	@override String get confirmExitOnBackDescription => 'Visa en bekräftelsedialog när du trycker tillbaka för att avsluta appen';
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

// Path: pinEntry
class _TranslationsPinEntrySv implements TranslationsPinEntryEn {
	_TranslationsPinEntrySv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get enterPin => 'Ange PIN';
	@override String get showPin => 'Visa PIN';
	@override String get hidePin => 'Dölj PIN';
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
	@override String get confirmDelete => 'Är du säker på att du vill ta bort detta objekt från ditt filsystem?';
	@override String get deleteMultipleWarning => 'Flera objekt kan komma att tas bort.';
	@override String get mediaDeletedSuccessfully => 'Mediaobjekt borttaget';
	@override String get mediaFailedToDelete => 'Kunde inte ta bort mediaobjekt';
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
	@override String get sleepTimerCompleted => 'Sovtimer slutförd - uppspelning pausad';
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
	@override String get audioTrackButton => 'Ljudspår';
	@override String get subtitlesButton => 'Undertexter';
	@override String get chaptersButton => 'Kapitel';
	@override String get versionsButton => 'Videoversioner';
	@override String get pipButton => 'Bild-i-bild läge';
	@override String get aspectRatioButton => 'Bildförhållande';
	@override String get fullscreenButton => 'Aktivera helskärm';
	@override String get exitFullscreenButton => 'Avsluta helskärm';
	@override String get alwaysOnTopButton => 'Alltid överst';
	@override String get rotationLockButton => 'Rotationslås';
	@override String get timelineSlider => 'Videotidslinje';
	@override String get volumeSlider => 'Volymnivå';
	@override String endsAt({required Object time}) => 'Slutar ${time}';
	@override String get pipFailed => 'Bild-i-bild kunde inte starta';
	@override late final _TranslationsVideoControlsPipErrorsSv pipErrors = _TranslationsVideoControlsPipErrorsSv._(_root);
	@override String get chapters => 'Kapitel';
	@override String get noChaptersAvailable => 'Inga kapitel tillgängliga';
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
	@override String get removedFromContinueWatching => 'Borttagen från Fortsätt titta';
	@override String errorLoading({required Object error}) => 'Fel: ${error}';
	@override String get fileInfoNotAvailable => 'Filinformation inte tillgänglig';
	@override String errorLoadingFileInfo({required Object error}) => 'Fel vid laddning av filinformation: ${error}';
	@override String get errorLoadingSeries => 'Fel vid laddning av serie';
	@override String get errorLoadingSeason => 'Fel vid laddning av säsong';
	@override String get musicNotSupported => 'Musikuppspelning stöds inte ännu';
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
	@override String get logsUploaded => 'Logs uploaded';
	@override String get logsUploadFailed => 'Failed to upload logs';
	@override String get logId => 'Log ID';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingSv implements TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get stylingOptions => 'Stilalternativ';
	@override String get fontSize => 'Teckenstorlek';
	@override String get textColor => 'Textfärg';
	@override String get borderSize => 'Kantstorlek';
	@override String get borderColor => 'Kantfärg';
	@override String get backgroundOpacity => 'Bakgrundsopacitet';
	@override String get backgroundColor => 'Bakgrundsfärg';
	@override String get position => 'Position';
}

// Path: mpvConfig
class _TranslationsMpvConfigSv implements TranslationsMpvConfigEn {
	_TranslationsMpvConfigSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'MPV-konfiguration';
	@override String get description => 'Avancerade videospelares inställningar';
	@override String get properties => 'Egenskaper';
	@override String get presets => 'Förval';
	@override String get noProperties => 'Inga egenskaper konfigurerade';
	@override String get noPresets => 'Inga sparade förval';
	@override String get addProperty => 'Lägg till egenskap';
	@override String get editProperty => 'Redigera egenskap';
	@override String get deleteProperty => 'Ta bort egenskap';
	@override String get propertyKey => 'Egenskapsnyckel';
	@override String get propertyKeyHint => 't.ex. hwdec, demuxer-max-bytes';
	@override String get propertyValue => 'Egenskapsvärde';
	@override String get propertyValueHint => 't.ex. auto, 256000000';
	@override String get saveAsPreset => 'Spara som förval...';
	@override String get presetName => 'Förvalnamn';
	@override String get presetNameHint => 'Ange ett namn för detta förval';
	@override String get loadPreset => 'Ladda';
	@override String get deletePreset => 'Ta bort';
	@override String get presetSaved => 'Förval sparat';
	@override String get presetLoaded => 'Förval laddat';
	@override String get presetDeleted => 'Förval borttaget';
	@override String get confirmDeletePreset => 'Är du säker på att du vill ta bort detta förval?';
	@override String get confirmDeleteProperty => 'Är du säker på att du vill ta bort denna egenskap?';
	@override String entriesCount({required Object count}) => '${count} poster';
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
	@override String get seasons => 'Säsonger';
	@override String get studio => 'Studio';
	@override String get rating => 'Åldersgräns';
	@override String episodeCount({required Object count}) => '${count} avsnitt';
	@override String watchedProgress({required Object watched, required Object total}) => '${watched}/${total} sedda';
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
	@override String get uploadLogs => 'Upload Logs';
	@override String get error => 'Fel:';
	@override String get stackTrace => 'Stack trace:';
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
	@override String get downloads => 'Nedladdningar';
	@override String get liveTv => 'Live-TV';
}

// Path: liveTv
class _TranslationsLiveTvSv implements TranslationsLiveTvEn {
	_TranslationsLiveTvSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Live-TV';
	@override String get channels => 'Kanaler';
	@override String get guide => 'Programguide';
	@override String get recordings => 'Inspelningar';
	@override String get subscriptions => 'Inspelningsregler';
	@override String get scheduled => 'Schemalagda';
	@override String get noChannels => 'Inga kanaler tillgängliga';
	@override String get noDvr => 'Ingen DVR konfigurerad på någon server';
	@override String get tuneFailed => 'Kunde inte ställa in kanalen';
	@override String get loading => 'Laddar kanaler...';
	@override String get nowPlaying => 'Spelas nu';
	@override String get record => 'Spela in';
	@override String get recordSeries => 'Spela in serie';
	@override String get cancelRecording => 'Avbryt inspelning';
	@override String get deleteSubscription => 'Ta bort inspelningsregel';
	@override String get deleteSubscriptionConfirm => 'Är du säker på att du vill ta bort denna inspelningsregel?';
	@override String get subscriptionDeleted => 'Inspelningsregel borttagen';
	@override String get noPrograms => 'Ingen programdata tillgänglig';
	@override String get noRecordings => 'Inga inspelningar schemalagda';
	@override String get noSubscriptions => 'Inga inspelningsregler';
	@override String channelNumber({required Object number}) => 'Kanal ${number}';
	@override String get live => 'LIVE';
	@override String get hd => 'HD';
	@override String get premiere => 'NY';
	@override String get reloadGuide => 'Ladda om programguide';
	@override String get guideReloaded => 'Programdata omladdad';
	@override String get allChannels => 'Alla kanaler';
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
	@override String episodesQueued({required Object count}) => '${count} avsnitt köade för nedladdning';
	@override String get downloadDeleted => 'Nedladdning borttagen';
	@override String deleteConfirm({required Object title}) => 'Är du säker på att du vill ta bort "${title}"? Den nedladdade filen kommer att tas bort från din enhet.';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Tar bort ${title}... (${current} av ${total})';
	@override String get noDownloadsTree => 'Inga nedladdningar';
	@override String get pauseAll => 'Pausa alla';
	@override String get resumeAll => 'Återuppta alla';
	@override String get deleteAll => 'Ta bort alla';
	@override String get checkForNewEpisodes => 'Check for new episodes';
	@override String get noNewEpisodesFound => 'No new episodes found';
}

// Path: playlists
class _TranslationsPlaylistsSv implements TranslationsPlaylistsEn {
	_TranslationsPlaylistsSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Spellistor';
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
	@override String get createNewPlaylist => 'Skapa ny spellista';
	@override String get errorCreating => 'Det gick inte att skapa spellista';
	@override String get errorDeleting => 'Det gick inte att ta bort spellista';
	@override String get errorLoading => 'Det gick inte att ladda spellistor';
	@override String get errorAdding => 'Det gick inte att lägga till i spellista';
	@override String get errorReordering => 'Det gick inte att omordna spellisteobjekt';
	@override String get errorRemoving => 'Det gick inte att ta bort från spellista';
	@override String get playlist => 'Spellista';
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
	@override String get createNewCollection => 'Skapa ny samling';
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
	@override String get enterCodeHint => 'Ange 8-teckens kod';
	@override String get pasteFromClipboard => 'Klistra in från urklipp';
	@override String get pleaseEnterCode => 'Vänligen ange en sessionskod';
	@override String get codeMustBe8Chars => 'Sessionskod måste vara 8 tecken';
	@override String get joinInstructions => 'Ange sessionskoden som delats av värden för att gå med i deras tittarsession.';
	@override String get failedToCreate => 'Det gick inte att skapa session';
	@override String get failedToJoin => 'Det gick inte att gå med i session';
	@override String get sessionCodeCopied => 'Sessionskod kopierad till urklipp';
	@override String get relayUnreachable => 'Reläservern kan inte nås. Detta kan bero på att din internetleverantör blockerar anslutningen. Du kan fortfarande försöka, men Watch Together kanske inte fungerar.';
	@override String get reconnectingToHost => 'Återansluter till värd...';
	@override String participantJoined({required Object name}) => '${name} gick med';
	@override String participantLeft({required Object name}) => '${name} lämnade';
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
}

// Path: companionRemote
class _TranslationsCompanionRemoteSv implements TranslationsCompanionRemoteEn {
	_TranslationsCompanionRemoteSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Companion Remote';
	@override String get connectToDevice => 'Anslut till enhet';
	@override String get hostRemoteSession => 'Starta fjärrsession';
	@override String get controlThisDevice => 'Styr den här enheten med din telefon';
	@override String get remoteControl => 'Fjärrkontroll';
	@override String get controlDesktop => 'Styr en datorenhet';
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
	@override String get systemDefault => 'Systemstandard';
	@override String get addCustomPlayer => 'Lägg till anpassad spelare';
	@override String get playerName => 'Spelarnamn';
	@override String get playerCommand => 'Kommando';
	@override String get playerPackage => 'Paketnamn';
	@override String get playerUrlScheme => 'URL-schema';
	@override String get customPlayer => 'Anpassad spelare';
	@override String get off => 'Av';
	@override String get launchFailed => 'Kunde inte öppna extern spelare';
	@override String appNotInstalled({required Object name}) => '${name} är inte installerad';
	@override String get playInExternalPlayer => 'Spela i extern spelare';
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
	@override String get permissionDisabled => 'Bild-i-bild-behörighet är inaktiverad. Aktivera den i Inställningar > Appar > Plezy > Bild-i-bild';
	@override String get notSupported => 'Denna enhet stöder inte bild-i-bild-läge';
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
	@override String get creatingSession => 'Skapar fjärrsession...';
	@override String get failedToCreate => 'Kunde inte skapa fjärrsession:';
	@override String get noSession => 'Ingen session tillgänglig';
	@override String get scanQrCode => 'Skanna QR-kod';
	@override String get orEnterManually => 'Eller ange manuellt';
	@override String get hostAddress => 'Värdadress';
	@override String get sessionId => 'Sessions-ID';
	@override String get pin => 'PIN';
	@override String get connected => 'Ansluten';
	@override String get waitingForConnection => 'Väntar på anslutning...';
	@override String get usePhoneToControl => 'Använd din mobila enhet för att styra denna app';
	@override String copiedToClipboard({required Object label}) => '${label} kopierad till urklipp';
	@override String get copyToClipboard => 'Kopiera till urklipp';
	@override String get newSession => 'Ny session';
	@override String get minimize => 'Minimera';
}

// Path: companionRemote.pairing
class _TranslationsCompanionRemotePairingSv implements TranslationsCompanionRemotePairingEn {
	_TranslationsCompanionRemotePairingSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get recent => 'Senaste';
	@override String get scan => 'Skanna';
	@override String get manual => 'Manuell';
	@override String get recentConnections => 'Senaste anslutningar';
	@override String get quickReconnect => 'Återanslut snabbt till tidigare parkopplade enheter';
	@override String get pairWithDesktop => 'Parkoppla med dator';
	@override String get enterSessionDetails => 'Ange sessionsuppgifterna som visas på din datorenhet';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get sessionIdHint => 'Ange 8-teckens sessions-ID';
	@override String get pinHint => 'Ange 6-siffrig PIN';
	@override String get connecting => 'Ansluter...';
	@override String get tips => 'Tips';
	@override String get tipDesktop => 'Öppna Plezy på din dator och aktivera Companion Remote via inställningar eller meny';
	@override String get tipScan => 'Använd fliken Skanna för att snabbt parkoppla genom att skanna QR-koden på din dator';
	@override String get tipWifi => 'Se till att båda enheterna är på samma WiFi-nätverk';
	@override String get cameraPermissionRequired => 'Kamerabehörighet krävs för att skanna QR-koder.\nVänligen ge kameraåtkomst i enhetsinställningarna.';
	@override String cameraError({required Object error}) => 'Kunde inte starta kameran: ${error}';
	@override String get scanInstruction => 'Rikta kameran mot QR-koden som visas på din dator';
	@override String get noRecentConnections => 'Inga senaste anslutningar';
	@override String get connectUsingManual => 'Anslut till en enhet via Manuell inmatning för att komma igång';
	@override String get invalidQrCode => 'Ogiltigt QR-kodformat';
	@override String get removeRecentConnection => 'Ta bort senaste anslutning';
	@override String removeConfirm({required Object name}) => 'Ta bort "${name}" från senaste anslutningar?';
	@override String get validationHostRequired => 'Ange en värdadress';
	@override String get validationHostFormat => 'Format måste vara IP:port (t.ex. 192.168.1.100:48632)';
	@override String get validationSessionIdRequired => 'Ange ett sessions-ID';
	@override String get validationSessionIdLength => 'Sessions-ID måste vara 8 tecken';
	@override String get validationPinRequired => 'Ange en PIN';
	@override String get validationPinLength => 'PIN måste vara 6 siffror';
	@override String get connectionTimedOut => 'Anslutningen tog för lång tid. Kontrollera sessions-ID och PIN.';
	@override String get sessionNotFound => 'Kunde inte hitta sessionen. Kontrollera dina uppgifter.';
	@override String failedToConnect({required Object error}) => 'Kunde inte ansluta: ${error}';
	@override String failedToLoadRecent({required Object error}) => 'Kunde inte ladda senaste sessioner: ${error}';
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
	@override String get connectionError => 'Anslutningsfel';
	@override String get notConnected => 'Inte ansluten';
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
			'auth.debugEnterToken' => 'Debug: Ange Plex-token',
			'auth.plexTokenLabel' => 'Plex-autentiseringstoken',
			'auth.plexTokenHint' => 'Ange din Plex.tv-token',
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
			'common.remove' => 'Ta bort',
			'common.paste' => 'Klistra in',
			'common.connect' => 'Anslut',
			'common.disconnect' => 'Koppla från',
			'common.play' => 'Spela',
			'common.pause' => 'Pausa',
			'common.resume' => 'Återuppta',
			'common.error' => 'Fel',
			'common.search' => 'Sök',
			'common.home' => 'Hem',
			'common.back' => 'Tillbaka',
			'common.settings' => 'Inställningar',
			'common.mute' => 'Ljud av',
			'common.ok' => 'OK',
			'common.loading' => 'Laddar...',
			'common.reconnect' => 'Återanslut',
			'common.exitConfirmTitle' => 'Avsluta appen?',
			'common.exitConfirmMessage' => 'Är du säker på att du vill avsluta?',
			'common.dontAskAgain' => 'Fråga inte igen',
			'common.exit' => 'Avsluta',
			'screens.licenses' => 'Licenser',
			'screens.switchProfile' => 'Byt profil',
			'screens.subtitleStyling' => 'Undertext-styling',
			'screens.mpvConfig' => 'MPV-konfiguration',
			'screens.logs' => 'Loggar',
			'update.available' => 'Uppdatering tillgänglig',
			'update.versionAvailable' => ({required Object version}) => 'Version ${version} är tillgänglig',
			'update.currentVersion' => ({required Object version}) => 'Nuvarande: ${version}',
			'update.skipVersion' => 'Hoppa över denna version',
			'update.viewRelease' => 'Visa release',
			'update.latestVersion' => 'Du har den senaste versionen',
			'update.checkFailed' => 'Misslyckades att kontrollera uppdateringar',
			'settings.title' => 'Inställningar',
			'settings.language' => 'Språk',
			'settings.theme' => 'Tema',
			'settings.appearance' => 'Utseende',
			'settings.videoPlayback' => 'Videouppspelning',
			'settings.advanced' => 'Avancerat',
			'settings.episodePosterMode' => 'Avsnittsaffisch-stil',
			'settings.seriesPoster' => 'Serieaffisch',
			'settings.seriesPosterDescription' => 'Visa seriens affisch för alla avsnitt',
			'settings.seasonPoster' => 'Säsongsaffisch',
			'settings.seasonPosterDescription' => 'Visa säsongens affisch för avsnitt',
			'settings.episodeThumbnail' => 'Avsnittsminiatyr',
			'settings.episodeThumbnailDescription' => 'Visa 16:9 skärmbild från avsnittet',
			'settings.showHeroSectionDescription' => 'Visa utvalda innehållskarusell på startsidan',
			'settings.secondsLabel' => 'Sekunder',
			'settings.minutesLabel' => 'Minuter',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Ange tid (${min}-${max})',
			'settings.systemTheme' => 'System',
			'settings.systemThemeDescription' => 'Följ systeminställningar',
			'settings.lightTheme' => 'Ljust',
			'settings.darkTheme' => 'Mörkt',
			'settings.oledTheme' => 'OLED',
			'settings.oledThemeDescription' => 'Rent svart för OLED-skärmar',
			'settings.libraryDensity' => 'Biblioteksdensitet',
			'settings.compact' => 'Kompakt',
			'settings.compactDescription' => 'Mindre kort, fler objekt synliga',
			'settings.normal' => 'Normal',
			'settings.normalDescription' => 'Standardstorlek',
			'settings.comfortable' => 'Bekväm',
			'settings.comfortableDescription' => 'Större kort, färre objekt synliga',
			'settings.viewMode' => 'Visningsläge',
			'settings.gridView' => 'Rutnät',
			'settings.gridViewDescription' => 'Visa objekt i rutnätslayout',
			'settings.listView' => 'Lista',
			'settings.listViewDescription' => 'Visa objekt i listlayout',
			'settings.showHeroSection' => 'Visa hjältesektion',
			'settings.useGlobalHubs' => 'Använd Plex hem-layout',
			'settings.useGlobalHubsDescription' => 'Visar startsidans hubbar som den officiella Plex-klienten. När av visas rekommendationer per bibliotek istället.',
			'settings.showServerNameOnHubs' => 'Visa servernamn på hubbar',
			'settings.showServerNameOnHubsDescription' => 'Visa alltid servernamnet i hubbtitlar. När av visas endast för duplicerade hubbnamn.',
			'settings.alwaysKeepSidebarOpen' => 'Håll sidofältet alltid öppet',
			'settings.alwaysKeepSidebarOpenDescription' => 'Sidofältet förblir expanderat och innehållsytan anpassas',
			'settings.showUnwatchedCount' => 'Visa antal osedda',
			'settings.showUnwatchedCountDescription' => 'Visa antal osedda avsnitt för serier och säsonger',
			'settings.playerBackend' => 'Spelarmotor',
			'settings.exoPlayer' => 'ExoPlayer (Rekommenderad)',
			'settings.exoPlayerDescription' => 'Android-nativ spelare med bättre hårdvarustöd',
			'settings.mpv' => 'MPV',
			'settings.mpvDescription' => 'Avancerad spelare med fler funktioner och ASS-undertextstöd',
			'settings.hardwareDecoding' => 'Hårdvaruavkodning',
			'settings.hardwareDecodingDescription' => 'Använd hårdvaruacceleration när tillgängligt',
			'settings.bufferSize' => 'Bufferstorlek',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.subtitleStyling' => 'Undertext-styling',
			'settings.subtitleStylingDescription' => 'Anpassa undertextutseende',
			'settings.smallSkipDuration' => 'Kort hoppvaraktighet',
			'settings.largeSkipDuration' => 'Lång hoppvaraktighet',
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
			'settings.shortcutsReset' => 'Genvägar återställda till standard',
			'settings.about' => 'Om',
			'settings.aboutDescription' => 'Appinformation och licenser',
			'settings.updates' => 'Uppdateringar',
			'settings.updateAvailable' => 'Uppdatering tillgänglig',
			'settings.checkForUpdates' => 'Kontrollera uppdateringar',
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
			'settings.autoDownloadNewEpisodes' => 'Download new episodes automatically',
			'settings.autoDownloadNewEpisodesDescription' => 'Automatically download new episodes in your downloaded seasons',
			'settings.autoDownloadNewSeasons' => 'Download new seasons automatically',
			'settings.autoDownloadNewSeasonsDescription' => 'Automatically download new seasons for your downloaded shows',
			'settings.cellularDownloadBlocked' => 'Nedladdningar är inaktiverade på mobildata. Anslut till WiFi eller ändra inställningen.',
			'settings.maxVolume' => 'Maximal volym',
			'settings.maxVolumeDescription' => 'Tillåt volym över 100% för tyst media',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Visa vad du tittar på i Discord',
			'settings.matchContentFrameRate' => 'Matcha innehållets bildfrekvens',
			'settings.matchContentFrameRateDescription' => 'Justera skärmens uppdateringsfrekvens för att matcha videoinnehållet, minskar hackighet och sparar batteri',
			'settings.requireProfileSelectionOnOpen' => 'Fråga efter profil vid appstart',
			'settings.requireProfileSelectionOnOpenDescription' => 'Visa profilval varje gång appen öppnas',
			'settings.confirmExitOnBack' => 'Bekräfta innan avslut',
			'settings.confirmExitOnBackDescription' => 'Visa en bekräftelsedialog när du trycker tillbaka för att avsluta appen',
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
			'hotkeys.actions.speedIncrease' => 'Öka hastighet',
			'hotkeys.actions.speedDecrease' => 'Minska hastighet',
			'hotkeys.actions.speedReset' => 'Återställ hastighet',
			'hotkeys.actions.subSeekNext' => 'Hoppa till nästa undertext',
			'hotkeys.actions.subSeekPrev' => 'Hoppa till föregående undertext',
			'hotkeys.actions.shaderToggle' => 'Växla shaders',
			'hotkeys.actions.skipMarker' => 'Hoppa över intro/eftertexter',
			'pinEntry.enterPin' => 'Ange PIN',
			'pinEntry.showPin' => 'Visa PIN',
			'pinEntry.hidePin' => 'Dölj PIN',
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
			'mediaMenu.confirmDelete' => 'Är du säker på att du vill ta bort detta objekt från ditt filsystem?',
			'mediaMenu.deleteMultipleWarning' => 'Flera objekt kan komma att tas bort.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Mediaobjekt borttaget',
			'mediaMenu.mediaFailedToDelete' => 'Kunde inte ta bort mediaobjekt',
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
			'videoControls.sleepTimerCompleted' => 'Sovtimer slutförd - uppspelning pausad',
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
			'videoControls.audioTrackButton' => 'Ljudspår',
			'videoControls.subtitlesButton' => 'Undertexter',
			'videoControls.chaptersButton' => 'Kapitel',
			'videoControls.versionsButton' => 'Videoversioner',
			'videoControls.pipButton' => 'Bild-i-bild läge',
			'videoControls.aspectRatioButton' => 'Bildförhållande',
			'videoControls.fullscreenButton' => 'Aktivera helskärm',
			'videoControls.exitFullscreenButton' => 'Avsluta helskärm',
			'videoControls.alwaysOnTopButton' => 'Alltid överst',
			'videoControls.rotationLockButton' => 'Rotationslås',
			'videoControls.timelineSlider' => 'Videotidslinje',
			'videoControls.volumeSlider' => 'Volymnivå',
			'videoControls.endsAt' => ({required Object time}) => 'Slutar ${time}',
			'videoControls.pipFailed' => 'Bild-i-bild kunde inte starta',
			'videoControls.pipErrors.androidVersion' => 'Kräver Android 8.0 eller nyare',
			'videoControls.pipErrors.permissionDisabled' => 'Bild-i-bild-behörighet är inaktiverad. Aktivera den i Inställningar > Appar > Plezy > Bild-i-bild',
			'videoControls.pipErrors.notSupported' => 'Denna enhet stöder inte bild-i-bild-läge',
			'videoControls.pipErrors.failed' => 'Bild-i-bild kunde inte starta',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Ett fel uppstod: ${error}',
			'videoControls.chapters' => 'Kapitel',
			'videoControls.noChaptersAvailable' => 'Inga kapitel tillgängliga',
			'userStatus.admin' => 'Admin',
			'userStatus.restricted' => 'Begränsad',
			'userStatus.protected' => 'Skyddad',
			'userStatus.current' => 'NUVARANDE',
			'messages.markedAsWatched' => 'Markerad som sedd',
			'messages.markedAsUnwatched' => 'Markerad som osedd',
			'messages.markedAsWatchedOffline' => 'Markerad som sedd (synkroniseras när online)',
			'messages.markedAsUnwatchedOffline' => 'Markerad som osedd (synkroniseras när online)',
			'messages.removedFromContinueWatching' => 'Borttagen från Fortsätt titta',
			'messages.errorLoading' => ({required Object error}) => 'Fel: ${error}',
			'messages.fileInfoNotAvailable' => 'Filinformation inte tillgänglig',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Fel vid laddning av filinformation: ${error}',
			'messages.errorLoadingSeries' => 'Fel vid laddning av serie',
			'messages.errorLoadingSeason' => 'Fel vid laddning av säsong',
			'messages.musicNotSupported' => 'Musikuppspelning stöds inte ännu',
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
			'messages.logsUploaded' => 'Logs uploaded',
			'messages.logsUploadFailed' => 'Failed to upload logs',
			'messages.logId' => 'Log ID',
			'subtitlingStyling.stylingOptions' => 'Stilalternativ',
			'subtitlingStyling.fontSize' => 'Teckenstorlek',
			'subtitlingStyling.textColor' => 'Textfärg',
			'subtitlingStyling.borderSize' => 'Kantstorlek',
			'subtitlingStyling.borderColor' => 'Kantfärg',
			'subtitlingStyling.backgroundOpacity' => 'Bakgrundsopacitet',
			'subtitlingStyling.backgroundColor' => 'Bakgrundsfärg',
			'subtitlingStyling.position' => 'Position',
			'mpvConfig.title' => 'MPV-konfiguration',
			'mpvConfig.description' => 'Avancerade videospelares inställningar',
			'mpvConfig.properties' => 'Egenskaper',
			'mpvConfig.presets' => 'Förval',
			'mpvConfig.noProperties' => 'Inga egenskaper konfigurerade',
			'mpvConfig.noPresets' => 'Inga sparade förval',
			'mpvConfig.addProperty' => 'Lägg till egenskap',
			'mpvConfig.editProperty' => 'Redigera egenskap',
			'mpvConfig.deleteProperty' => 'Ta bort egenskap',
			'mpvConfig.propertyKey' => 'Egenskapsnyckel',
			'mpvConfig.propertyKeyHint' => 't.ex. hwdec, demuxer-max-bytes',
			'mpvConfig.propertyValue' => 'Egenskapsvärde',
			'mpvConfig.propertyValueHint' => 't.ex. auto, 256000000',
			'mpvConfig.saveAsPreset' => 'Spara som förval...',
			'mpvConfig.presetName' => 'Förvalnamn',
			'mpvConfig.presetNameHint' => 'Ange ett namn för detta förval',
			'mpvConfig.loadPreset' => 'Ladda',
			'mpvConfig.deletePreset' => 'Ta bort',
			'mpvConfig.presetSaved' => 'Förval sparat',
			'mpvConfig.presetLoaded' => 'Förval laddat',
			'mpvConfig.presetDeleted' => 'Förval borttaget',
			'mpvConfig.confirmDeletePreset' => 'Är du säker på att du vill ta bort detta förval?',
			'mpvConfig.confirmDeleteProperty' => 'Är du säker på att du vill ta bort denna egenskap?',
			'mpvConfig.entriesCount' => ({required Object count}) => '${count} poster',
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
			'discover.seasons' => 'Säsonger',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Åldersgräns',
			'discover.episodeCount' => ({required Object count}) => '${count} avsnitt',
			'discover.watchedProgress' => ({required Object watched, required Object total}) => '${watched}/${total} sedda',
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
			'logs.uploadLogs' => 'Upload Logs',
			'logs.error' => 'Fel:',
			'logs.stackTrace' => 'Stack trace:',
			'licenses.relatedPackages' => 'Relaterade paket',
			'licenses.license' => 'Licens',
			'licenses.licenseNumber' => ({required Object number}) => 'Licens ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licenser',
			'navigation.libraries' => 'Bibliotek',
			'navigation.downloads' => 'Nedladdningar',
			'navigation.liveTv' => 'Live-TV',
			'liveTv.title' => 'Live-TV',
			'liveTv.channels' => 'Kanaler',
			'liveTv.guide' => 'Programguide',
			'liveTv.recordings' => 'Inspelningar',
			'liveTv.subscriptions' => 'Inspelningsregler',
			'liveTv.scheduled' => 'Schemalagda',
			'liveTv.noChannels' => 'Inga kanaler tillgängliga',
			'liveTv.noDvr' => 'Ingen DVR konfigurerad på någon server',
			'liveTv.tuneFailed' => 'Kunde inte ställa in kanalen',
			'liveTv.loading' => 'Laddar kanaler...',
			'liveTv.nowPlaying' => 'Spelas nu',
			'liveTv.record' => 'Spela in',
			'liveTv.recordSeries' => 'Spela in serie',
			'liveTv.cancelRecording' => 'Avbryt inspelning',
			'liveTv.deleteSubscription' => 'Ta bort inspelningsregel',
			'liveTv.deleteSubscriptionConfirm' => 'Är du säker på att du vill ta bort denna inspelningsregel?',
			'liveTv.subscriptionDeleted' => 'Inspelningsregel borttagen',
			'liveTv.noPrograms' => 'Ingen programdata tillgänglig',
			'liveTv.noRecordings' => 'Inga inspelningar schemalagda',
			'liveTv.noSubscriptions' => 'Inga inspelningsregler',
			'liveTv.channelNumber' => ({required Object number}) => 'Kanal ${number}',
			'liveTv.live' => 'LIVE',
			'liveTv.hd' => 'HD',
			'liveTv.premiere' => 'NY',
			'liveTv.reloadGuide' => 'Ladda om programguide',
			'liveTv.guideReloaded' => 'Programdata omladdad',
			'liveTv.allChannels' => 'Alla kanaler',
			'liveTv.now' => 'Nu',
			'liveTv.today' => 'Idag',
			'liveTv.midnight' => 'Midnatt',
			'liveTv.overnight' => 'Natt',
			'liveTv.morning' => 'Morgon',
			_ => null,
		} ?? switch (path) {
			'liveTv.daytime' => 'Dagtid',
			'liveTv.evening' => 'Kväll',
			'liveTv.lateNight' => 'Sen kväll',
			'liveTv.whatsOn' => 'På TV nu',
			'liveTv.watchChannel' => 'Titta på kanal',
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
			'downloads.episodesQueued' => ({required Object count}) => '${count} avsnitt köade för nedladdning',
			'downloads.downloadDeleted' => 'Nedladdning borttagen',
			'downloads.deleteConfirm' => ({required Object title}) => 'Är du säker på att du vill ta bort "${title}"? Den nedladdade filen kommer att tas bort från din enhet.',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Tar bort ${title}... (${current} av ${total})',
			'downloads.noDownloadsTree' => 'Inga nedladdningar',
			'downloads.pauseAll' => 'Pausa alla',
			'downloads.resumeAll' => 'Återuppta alla',
			'downloads.deleteAll' => 'Ta bort alla',
			'downloads.checkForNewEpisodes' => 'Check for new episodes',
			'downloads.noNewEpisodesFound' => 'No new episodes found',
			'playlists.title' => 'Spellistor',
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
			'playlists.createNewPlaylist' => 'Skapa ny spellista',
			'playlists.errorCreating' => 'Det gick inte att skapa spellista',
			'playlists.errorDeleting' => 'Det gick inte att ta bort spellista',
			'playlists.errorLoading' => 'Det gick inte att ladda spellistor',
			'playlists.errorAdding' => 'Det gick inte att lägga till i spellista',
			'playlists.errorReordering' => 'Det gick inte att omordna spellisteobjekt',
			'playlists.errorRemoving' => 'Det gick inte att ta bort från spellista',
			'playlists.playlist' => 'Spellista',
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
			'collections.createNewCollection' => 'Skapa ny samling',
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
			'watchTogether.enterCodeHint' => 'Ange 8-teckens kod',
			'watchTogether.pasteFromClipboard' => 'Klistra in från urklipp',
			'watchTogether.pleaseEnterCode' => 'Vänligen ange en sessionskod',
			'watchTogether.codeMustBe8Chars' => 'Sessionskod måste vara 8 tecken',
			'watchTogether.joinInstructions' => 'Ange sessionskoden som delats av värden för att gå med i deras tittarsession.',
			'watchTogether.failedToCreate' => 'Det gick inte att skapa session',
			'watchTogether.failedToJoin' => 'Det gick inte att gå med i session',
			'watchTogether.sessionCodeCopied' => 'Sessionskod kopierad till urklipp',
			'watchTogether.relayUnreachable' => 'Reläservern kan inte nås. Detta kan bero på att din internetleverantör blockerar anslutningen. Du kan fortfarande försöka, men Watch Together kanske inte fungerar.',
			'watchTogether.reconnectingToHost' => 'Återansluter till värd...',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} gick med',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} lämnade',
			'shaders.title' => 'Shaders',
			'shaders.noShaderDescription' => 'Ingen videoförbättring',
			'shaders.nvscalerDescription' => 'NVIDIA-bildskalning för skarpare video',
			'shaders.qualityFast' => 'Snabb',
			'shaders.qualityHQ' => 'Hög kvalitet',
			'shaders.mode' => 'Läge',
			'companionRemote.title' => 'Companion Remote',
			'companionRemote.connectToDevice' => 'Anslut till enhet',
			'companionRemote.hostRemoteSession' => 'Starta fjärrsession',
			'companionRemote.controlThisDevice' => 'Styr den här enheten med din telefon',
			'companionRemote.remoteControl' => 'Fjärrkontroll',
			'companionRemote.controlDesktop' => 'Styr en datorenhet',
			'companionRemote.connectedTo' => ({required Object name}) => 'Ansluten till ${name}',
			'companionRemote.session.creatingSession' => 'Skapar fjärrsession...',
			'companionRemote.session.failedToCreate' => 'Kunde inte skapa fjärrsession:',
			'companionRemote.session.noSession' => 'Ingen session tillgänglig',
			'companionRemote.session.scanQrCode' => 'Skanna QR-kod',
			'companionRemote.session.orEnterManually' => 'Eller ange manuellt',
			'companionRemote.session.hostAddress' => 'Värdadress',
			'companionRemote.session.sessionId' => 'Sessions-ID',
			'companionRemote.session.pin' => 'PIN',
			'companionRemote.session.connected' => 'Ansluten',
			'companionRemote.session.waitingForConnection' => 'Väntar på anslutning...',
			'companionRemote.session.usePhoneToControl' => 'Använd din mobila enhet för att styra denna app',
			'companionRemote.session.copiedToClipboard' => ({required Object label}) => '${label} kopierad till urklipp',
			'companionRemote.session.copyToClipboard' => 'Kopiera till urklipp',
			'companionRemote.session.newSession' => 'Ny session',
			'companionRemote.session.minimize' => 'Minimera',
			'companionRemote.pairing.recent' => 'Senaste',
			'companionRemote.pairing.scan' => 'Skanna',
			'companionRemote.pairing.manual' => 'Manuell',
			'companionRemote.pairing.recentConnections' => 'Senaste anslutningar',
			'companionRemote.pairing.quickReconnect' => 'Återanslut snabbt till tidigare parkopplade enheter',
			'companionRemote.pairing.pairWithDesktop' => 'Parkoppla med dator',
			'companionRemote.pairing.enterSessionDetails' => 'Ange sessionsuppgifterna som visas på din datorenhet',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.sessionIdHint' => 'Ange 8-teckens sessions-ID',
			'companionRemote.pairing.pinHint' => 'Ange 6-siffrig PIN',
			'companionRemote.pairing.connecting' => 'Ansluter...',
			'companionRemote.pairing.tips' => 'Tips',
			'companionRemote.pairing.tipDesktop' => 'Öppna Plezy på din dator och aktivera Companion Remote via inställningar eller meny',
			'companionRemote.pairing.tipScan' => 'Använd fliken Skanna för att snabbt parkoppla genom att skanna QR-koden på din dator',
			'companionRemote.pairing.tipWifi' => 'Se till att båda enheterna är på samma WiFi-nätverk',
			'companionRemote.pairing.cameraPermissionRequired' => 'Kamerabehörighet krävs för att skanna QR-koder.\nVänligen ge kameraåtkomst i enhetsinställningarna.',
			'companionRemote.pairing.cameraError' => ({required Object error}) => 'Kunde inte starta kameran: ${error}',
			'companionRemote.pairing.scanInstruction' => 'Rikta kameran mot QR-koden som visas på din dator',
			'companionRemote.pairing.noRecentConnections' => 'Inga senaste anslutningar',
			'companionRemote.pairing.connectUsingManual' => 'Anslut till en enhet via Manuell inmatning för att komma igång',
			'companionRemote.pairing.invalidQrCode' => 'Ogiltigt QR-kodformat',
			'companionRemote.pairing.removeRecentConnection' => 'Ta bort senaste anslutning',
			'companionRemote.pairing.removeConfirm' => ({required Object name}) => 'Ta bort "${name}" från senaste anslutningar?',
			'companionRemote.pairing.validationHostRequired' => 'Ange en värdadress',
			'companionRemote.pairing.validationHostFormat' => 'Format måste vara IP:port (t.ex. 192.168.1.100:48632)',
			'companionRemote.pairing.validationSessionIdRequired' => 'Ange ett sessions-ID',
			'companionRemote.pairing.validationSessionIdLength' => 'Sessions-ID måste vara 8 tecken',
			'companionRemote.pairing.validationPinRequired' => 'Ange en PIN',
			'companionRemote.pairing.validationPinLength' => 'PIN måste vara 6 siffror',
			'companionRemote.pairing.connectionTimedOut' => 'Anslutningen tog för lång tid. Kontrollera sessions-ID och PIN.',
			'companionRemote.pairing.sessionNotFound' => 'Kunde inte hitta sessionen. Kontrollera dina uppgifter.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Kunde inte ansluta: ${error}',
			'companionRemote.pairing.failedToLoadRecent' => ({required Object error}) => 'Kunde inte ladda senaste sessioner: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'Vill du koppla från fjärrsessionen?',
			'companionRemote.remote.reconnecting' => 'Återansluter...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Försök ${current} av 5',
			'companionRemote.remote.retryNow' => 'Försök nu',
			'companionRemote.remote.connectionError' => 'Anslutningsfel',
			'companionRemote.remote.notConnected' => 'Inte ansluten',
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
			'externalPlayer.title' => 'Extern spelare',
			'externalPlayer.useExternalPlayer' => 'Använd extern spelare',
			'externalPlayer.useExternalPlayerDescription' => 'Öppna videor i en extern app istället för den inbyggda spelaren',
			'externalPlayer.selectPlayer' => 'Välj spelare',
			'externalPlayer.systemDefault' => 'Systemstandard',
			'externalPlayer.addCustomPlayer' => 'Lägg till anpassad spelare',
			'externalPlayer.playerName' => 'Spelarnamn',
			'externalPlayer.playerCommand' => 'Kommando',
			'externalPlayer.playerPackage' => 'Paketnamn',
			'externalPlayer.playerUrlScheme' => 'URL-schema',
			'externalPlayer.customPlayer' => 'Anpassad spelare',
			'externalPlayer.off' => 'Av',
			'externalPlayer.launchFailed' => 'Kunde inte öppna extern spelare',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} är inte installerad',
			'externalPlayer.playInExternalPlayer' => 'Spela i extern spelare',
			_ => null,
		};
	}
}
