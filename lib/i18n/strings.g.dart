/// Generated file. Do not edit.
///
/// Original: lib/i18n
/// To regenerate, run: `dart run slang`
///
/// Locales: 7
/// Strings: 3603 (514 per locale)
///
/// Built on 2026-01-08 at 05:05 UTC

// coverage:ignore-file
// ignore_for_file: type=lint

import 'package:flutter/widgets.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang_flutter/slang_flutter.dart';
export 'package:slang_flutter/slang_flutter.dart';

const AppLocale _baseLocale = AppLocale.en;

/// Supported locales, see extension methods below.
///
/// Usage:
/// - LocaleSettings.setLocale(AppLocale.en) // set locale
/// - Locale locale = AppLocale.en.flutterLocale // get flutter locale from enum
/// - if (LocaleSettings.currentLocale == AppLocale.en) // locale check
enum AppLocale with BaseAppLocale<AppLocale, Translations> {
	en(languageCode: 'en', build: Translations.build),
	de(languageCode: 'de', build: _StringsDe.build),
	it(languageCode: 'it', build: _StringsIt.build),
	ko(languageCode: 'ko', build: _StringsKo.build),
	nl(languageCode: 'nl', build: _StringsNl.build),
	sv(languageCode: 'sv', build: _StringsSv.build),
	zh(languageCode: 'zh', build: _StringsZh.build);

	const AppLocale({required this.languageCode, this.scriptCode, this.countryCode, required this.build}); // ignore: unused_element

	@override final String languageCode;
	@override final String? scriptCode;
	@override final String? countryCode;
	@override final TranslationBuilder<AppLocale, Translations> build;

	/// Gets current instance managed by [LocaleSettings].
	Translations get translations => LocaleSettings.instance.translationMap[this]!;
}

/// Method A: Simple
///
/// No rebuild after locale change.
/// Translation happens during initialization of the widget (call of t).
/// Configurable via 'translate_var'.
///
/// Usage:
/// String a = t.someKey.anotherKey;
/// String b = t['someKey.anotherKey']; // Only for edge cases!
Translations get t => LocaleSettings.instance.currentTranslations;

/// Method B: Advanced
///
/// All widgets using this method will trigger a rebuild when locale changes.
/// Use this if you have e.g. a settings page where the user can select the locale during runtime.
///
/// Step 1:
/// wrap your App with
/// TranslationProvider(
/// 	child: MyApp()
/// );
///
/// Step 2:
/// final t = Translations.of(context); // Get t variable.
/// String a = t.someKey.anotherKey; // Use t variable.
/// String b = t['someKey.anotherKey']; // Only for edge cases!
class TranslationProvider extends BaseTranslationProvider<AppLocale, Translations> {
	TranslationProvider({required super.child}) : super(settings: LocaleSettings.instance);

	static InheritedLocaleData<AppLocale, Translations> of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context);
}

/// Method B shorthand via [BuildContext] extension method.
/// Configurable via 'translate_var'.
///
/// Usage (e.g. in a widget's build method):
/// context.t.someKey.anotherKey
extension BuildContextTranslationsExtension on BuildContext {
	Translations get t => TranslationProvider.of(this).translations;
}

/// Manages all translation instances and the current locale
class LocaleSettings extends BaseFlutterLocaleSettings<AppLocale, Translations> {
	LocaleSettings._() : super(utils: AppLocaleUtils.instance);

	static final instance = LocaleSettings._();

	// static aliases (checkout base methods for documentation)
	static AppLocale get currentLocale => instance.currentLocale;
	static Stream<AppLocale> getLocaleStream() => instance.getLocaleStream();
	static AppLocale setLocale(AppLocale locale, {bool? listenToDeviceLocale = false}) => instance.setLocale(locale, listenToDeviceLocale: listenToDeviceLocale);
	static AppLocale setLocaleRaw(String rawLocale, {bool? listenToDeviceLocale = false}) => instance.setLocaleRaw(rawLocale, listenToDeviceLocale: listenToDeviceLocale);
	static AppLocale useDeviceLocale() => instance.useDeviceLocale();
	@Deprecated('Use [AppLocaleUtils.supportedLocales]') static List<Locale> get supportedLocales => instance.supportedLocales;
	@Deprecated('Use [AppLocaleUtils.supportedLocalesRaw]') static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
	static void setPluralResolver({String? language, AppLocale? locale, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver}) => instance.setPluralResolver(
		language: language,
		locale: locale,
		cardinalResolver: cardinalResolver,
		ordinalResolver: ordinalResolver,
	);
}

/// Provides utility functions without any side effects.
class AppLocaleUtils extends BaseAppLocaleUtils<AppLocale, Translations> {
	AppLocaleUtils._() : super(baseLocale: _baseLocale, locales: AppLocale.values);

	static final instance = AppLocaleUtils._();

	// static aliases (checkout base methods for documentation)
	static AppLocale parse(String rawLocale) => instance.parse(rawLocale);
	static AppLocale parseLocaleParts({required String languageCode, String? scriptCode, String? countryCode}) => instance.parseLocaleParts(languageCode: languageCode, scriptCode: scriptCode, countryCode: countryCode);
	static AppLocale findDeviceLocale() => instance.findDeviceLocale();
	static List<Locale> get supportedLocales => instance.supportedLocales;
	static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
}

// translations

// Path: <root>
class Translations implements BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	// Translations
	late final _StringsAppEn app = _StringsAppEn._(_root);
	late final _StringsAuthEn auth = _StringsAuthEn._(_root);
	late final _StringsCommonEn common = _StringsCommonEn._(_root);
	late final _StringsScreensEn screens = _StringsScreensEn._(_root);
	late final _StringsUpdateEn update = _StringsUpdateEn._(_root);
	late final _StringsSettingsEn settings = _StringsSettingsEn._(_root);
	late final _StringsSearchEn search = _StringsSearchEn._(_root);
	late final _StringsHotkeysEn hotkeys = _StringsHotkeysEn._(_root);
	late final _StringsPinEntryEn pinEntry = _StringsPinEntryEn._(_root);
	late final _StringsFileInfoEn fileInfo = _StringsFileInfoEn._(_root);
	late final _StringsMediaMenuEn mediaMenu = _StringsMediaMenuEn._(_root);
	late final _StringsAccessibilityEn accessibility = _StringsAccessibilityEn._(_root);
	late final _StringsTooltipsEn tooltips = _StringsTooltipsEn._(_root);
	late final _StringsVideoControlsEn videoControls = _StringsVideoControlsEn._(_root);
	late final _StringsUserStatusEn userStatus = _StringsUserStatusEn._(_root);
	late final _StringsMessagesEn messages = _StringsMessagesEn._(_root);
	late final _StringsSubtitlingStylingEn subtitlingStyling = _StringsSubtitlingStylingEn._(_root);
	late final _StringsMpvConfigEn mpvConfig = _StringsMpvConfigEn._(_root);
	late final _StringsDialogEn dialog = _StringsDialogEn._(_root);
	late final _StringsDiscoverEn discover = _StringsDiscoverEn._(_root);
	late final _StringsErrorsEn errors = _StringsErrorsEn._(_root);
	late final _StringsLibrariesEn libraries = _StringsLibrariesEn._(_root);
	late final _StringsAboutEn about = _StringsAboutEn._(_root);
	late final _StringsServerSelectionEn serverSelection = _StringsServerSelectionEn._(_root);
	late final _StringsHubDetailEn hubDetail = _StringsHubDetailEn._(_root);
	late final _StringsLogsEn logs = _StringsLogsEn._(_root);
	late final _StringsLicensesEn licenses = _StringsLicensesEn._(_root);
	late final _StringsNavigationEn navigation = _StringsNavigationEn._(_root);
	late final _StringsCollectionsEn collections = _StringsCollectionsEn._(_root);
	late final _StringsPlaylistsEn playlists = _StringsPlaylistsEn._(_root);
	late final _StringsWatchTogetherEn watchTogether = _StringsWatchTogetherEn._(_root);
	late final _StringsDownloadsEn downloads = _StringsDownloadsEn._(_root);
}

// Path: app
class _StringsAppEn {
	_StringsAppEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Plezy';
	String get loading => 'Loading...';
}

// Path: auth
class _StringsAuthEn {
	_StringsAuthEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get signInWithPlex => 'Sign in with Plex';
	String get showQRCode => 'Show QR Code';
	String get cancel => 'Cancel';
	String get authenticate => 'Authenticate';
	String get retry => 'Retry';
	String get debugEnterToken => 'Debug: Enter Plex Token';
	String get plexTokenLabel => 'Plex Auth Token';
	String get plexTokenHint => 'Enter your Plex.tv token';
	String get authenticationTimeout => 'Authentication timed out. Please try again.';
	String get scanQRCodeInstruction => 'Scan this QR code with a device logged into Plex to authenticate.';
	String get waitingForAuth => 'Waiting for authentication...\nPlease complete sign-in in your browser.';
}

// Path: common
class _StringsCommonEn {
	_StringsCommonEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get cancel => 'Cancel';
	String get save => 'Save';
	String get close => 'Close';
	String get clear => 'Clear';
	String get reset => 'Reset';
	String get later => 'Later';
	String get submit => 'Submit';
	String get confirm => 'Confirm';
	String get retry => 'Retry';
	String get logout => 'Logout';
	String get unknown => 'Unknown';
	String get refresh => 'Refresh';
	String get yes => 'Yes';
	String get no => 'No';
	String get delete => 'Delete';
	String get shuffle => 'Shuffle';
	String get addTo => 'Add to...';
}

// Path: screens
class _StringsScreensEn {
	_StringsScreensEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get licenses => 'Licenses';
	String get switchProfile => 'Switch Profile';
	String get subtitleStyling => 'Subtitle Styling';
	String get mpvConfig => 'MPV Configuration';
	String get search => 'Search';
	String get logs => 'Logs';
}

// Path: update
class _StringsUpdateEn {
	_StringsUpdateEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get available => 'Update Available';
	String versionAvailable({required Object version}) => 'Version ${version} is available';
	String currentVersion({required Object version}) => 'Current: ${version}';
	String get skipVersion => 'Skip This Version';
	String get viewRelease => 'View Release';
	String get latestVersion => 'You are on the latest version';
	String get checkFailed => 'Failed to check for updates';
}

// Path: settings
class _StringsSettingsEn {
	_StringsSettingsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Settings';
	String get language => 'Language';
	String get theme => 'Theme';
	String get appearance => 'Appearance';
	String get videoPlayback => 'Video Playback';
	String get advanced => 'Advanced';
	String get episodePosterMode => 'Episode Poster Style';
	String get seriesPoster => 'Series Poster';
	String get seriesPosterDescription => 'Show the series poster for all episodes';
	String get seasonPoster => 'Season Poster';
	String get seasonPosterDescription => 'Show the season-specific poster for episodes';
	String get episodeThumbnail => 'Episode Thumbnail';
	String get episodeThumbnailDescription => 'Show 16:9 episode screenshot thumbnails';
	String get showHeroSectionDescription => 'Display featured content carousel on home screen';
	String get secondsLabel => 'Seconds';
	String get minutesLabel => 'Minutes';
	String get secondsShort => 's';
	String get minutesShort => 'm';
	String durationHint({required Object min, required Object max}) => 'Enter duration (${min}-${max})';
	String get systemTheme => 'System';
	String get systemThemeDescription => 'Follow system settings';
	String get lightTheme => 'Light';
	String get darkTheme => 'Dark';
	String get libraryDensity => 'Library Density';
	String get compact => 'Compact';
	String get compactDescription => 'Smaller cards, more items visible';
	String get normal => 'Normal';
	String get normalDescription => 'Default size';
	String get comfortable => 'Comfortable';
	String get comfortableDescription => 'Larger cards, fewer items visible';
	String get viewMode => 'View Mode';
	String get gridView => 'Grid';
	String get gridViewDescription => 'Display items in a grid layout';
	String get listView => 'List';
	String get listViewDescription => 'Display items in a list layout';
	String get showHeroSection => 'Show Hero Section';
	String get useGlobalHubs => 'Use Plex Home Layout';
	String get useGlobalHubsDescription => 'Show home page hubs like the official Plex client. When off, shows per-library recommendations instead.';
	String get hardwareDecoding => 'Hardware Decoding';
	String get hardwareDecodingDescription => 'Use hardware acceleration when available';
	String get bufferSize => 'Buffer Size';
	String bufferSizeMB({required Object size}) => '${size}MB';
	String get subtitleStyling => 'Subtitle Styling';
	String get subtitleStylingDescription => 'Customize subtitle appearance';
	String get smallSkipDuration => 'Small Skip Duration';
	String get largeSkipDuration => 'Large Skip Duration';
	String secondsUnit({required Object seconds}) => '${seconds} seconds';
	String get defaultSleepTimer => 'Default Sleep Timer';
	String minutesUnit({required Object minutes}) => '${minutes} minutes';
	String get rememberTrackSelections => 'Remember track selections per show/movie';
	String get rememberTrackSelectionsDescription => 'Automatically save audio and subtitle language preferences when you change tracks during playback';
	String get videoPlayerControls => 'Video Player Controls';
	String get keyboardShortcuts => 'Keyboard Shortcuts';
	String get keyboardShortcutsDescription => 'Customize keyboard shortcuts';
	String get videoPlayerNavigation => 'Video Player Navigation';
	String get videoPlayerNavigationDescription => 'Use arrow keys to navigate video player controls';
	String get debugLogging => 'Debug Logging';
	String get debugLoggingDescription => 'Enable detailed logging for troubleshooting';
	String get viewLogs => 'View Logs';
	String get viewLogsDescription => 'View application logs';
	String get clearCache => 'Clear Cache';
	String get clearCacheDescription => 'This will clear all cached images and data. The app may take longer to load content after clearing the cache.';
	String get clearCacheSuccess => 'Cache cleared successfully';
	String get resetSettings => 'Reset Settings';
	String get resetSettingsDescription => 'This will reset all settings to their default values. This action cannot be undone.';
	String get resetSettingsSuccess => 'Settings reset successfully';
	String get shortcutsReset => 'Shortcuts reset to defaults';
	String get about => 'About';
	String get aboutDescription => 'App information and licenses';
	String get updates => 'Updates';
	String get updateAvailable => 'Update Available';
	String get checkForUpdates => 'Check for Updates';
	String get validationErrorEnterNumber => 'Please enter a valid number';
	String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Duration must be between ${min} and ${max} ${unit}';
	String shortcutAlreadyAssigned({required Object action}) => 'Shortcut already assigned to ${action}';
	String shortcutUpdated({required Object action}) => 'Shortcut updated for ${action}';
	String get autoSkip => 'Auto Skip';
	String get autoSkipIntro => 'Auto Skip Intro';
	String get autoSkipIntroDescription => 'Automatically skip intro markers after a few seconds';
	String get autoSkipCredits => 'Auto Skip Credits';
	String get autoSkipCreditsDescription => 'Automatically skip credits and play next episode';
	String get autoSkipDelay => 'Auto Skip Delay';
	String autoSkipDelayDescription({required Object seconds}) => 'Wait ${seconds} seconds before auto-skipping';
	String get downloads => 'Downloads';
	String get downloadLocationDescription => 'Choose where to store downloaded content';
	String get downloadLocationDefault => 'Default (App Storage)';
	String get downloadLocationCustom => 'Custom Location';
	String get selectFolder => 'Select Folder';
	String get resetToDefault => 'Reset to Default';
	String currentPath({required Object path}) => 'Current: ${path}';
	String get downloadLocationChanged => 'Download location changed';
	String get downloadLocationReset => 'Download location reset to default';
	String get downloadLocationInvalid => 'Selected folder is not writable';
	String get downloadLocationSelectError => 'Failed to select folder';
	String get downloadOnWifiOnly => 'Download on WiFi only';
	String get downloadOnWifiOnlyDescription => 'Prevent downloads when on cellular data';
	String get cellularDownloadBlocked => 'Downloads are disabled on cellular data. Connect to WiFi or change the setting.';
	String get maxVolume => 'Maximum Volume';
	String get maxVolumeDescription => 'Allow volume boost above 100% for quiet media';
	String maxVolumePercent({required Object percent}) => '${percent}%';
	String get maxVolumeHint => 'Enter max volume (100-300)';
	String get discordRichPresence => 'Discord Rich Presence';
	String get discordRichPresenceDescription => 'Show what you\'re watching on Discord';
}

// Path: search
class _StringsSearchEn {
	_StringsSearchEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get hint => 'Search movies, shows, music...';
	String get tryDifferentTerm => 'Try a different search term';
	String get searchYourMedia => 'Search your media';
	String get enterTitleActorOrKeyword => 'Enter a title, actor, or keyword';
}

// Path: hotkeys
class _StringsHotkeysEn {
	_StringsHotkeysEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String setShortcutFor({required Object actionName}) => 'Set Shortcut for ${actionName}';
	String get clearShortcut => 'Clear shortcut';
}

// Path: pinEntry
class _StringsPinEntryEn {
	_StringsPinEntryEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get enterPin => 'Enter PIN';
	String get showPin => 'Show PIN';
	String get hidePin => 'Hide PIN';
}

// Path: fileInfo
class _StringsFileInfoEn {
	_StringsFileInfoEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'File Info';
	String get video => 'Video';
	String get audio => 'Audio';
	String get file => 'File';
	String get advanced => 'Advanced';
	String get codec => 'Codec';
	String get resolution => 'Resolution';
	String get bitrate => 'Bitrate';
	String get frameRate => 'Frame Rate';
	String get aspectRatio => 'Aspect Ratio';
	String get profile => 'Profile';
	String get bitDepth => 'Bit Depth';
	String get colorSpace => 'Color Space';
	String get colorRange => 'Color Range';
	String get colorPrimaries => 'Color Primaries';
	String get chromaSubsampling => 'Chroma Subsampling';
	String get channels => 'Channels';
	String get path => 'Path';
	String get size => 'Size';
	String get container => 'Container';
	String get duration => 'Duration';
	String get optimizedForStreaming => 'Optimized for Streaming';
	String get has64bitOffsets => '64-bit Offsets';
}

// Path: mediaMenu
class _StringsMediaMenuEn {
	_StringsMediaMenuEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get markAsWatched => 'Mark as Watched';
	String get markAsUnwatched => 'Mark as Unwatched';
	String get removeFromContinueWatching => 'Remove from Continue Watching';
	String get goToSeries => 'Go to series';
	String get goToSeason => 'Go to season';
	String get shufflePlay => 'Shuffle Play';
	String get fileInfo => 'File Info';
}

// Path: accessibility
class _StringsAccessibilityEn {
	_StringsAccessibilityEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String mediaCardMovie({required Object title}) => '${title}, movie';
	String mediaCardShow({required Object title}) => '${title}, TV show';
	String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	String get mediaCardWatched => 'watched';
	String mediaCardPartiallyWatched({required Object percent}) => '${percent} percent watched';
	String get mediaCardUnwatched => 'unwatched';
	String get tapToPlay => 'Tap to play';
}

// Path: tooltips
class _StringsTooltipsEn {
	_StringsTooltipsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get shufflePlay => 'Shuffle play';
	String get markAsWatched => 'Mark as watched';
	String get markAsUnwatched => 'Mark as unwatched';
}

// Path: videoControls
class _StringsVideoControlsEn {
	_StringsVideoControlsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get audioLabel => 'Audio';
	String get subtitlesLabel => 'Subtitles';
	String get resetToZero => 'Reset to 0ms';
	String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	String playsLater({required Object label}) => '${label} plays later';
	String playsEarlier({required Object label}) => '${label} plays earlier';
	String get noOffset => 'No offset';
	String get letterbox => 'Letterbox';
	String get fillScreen => 'Fill screen';
	String get stretch => 'Stretch';
	String get lockRotation => 'Lock rotation';
	String get unlockRotation => 'Unlock rotation';
	String get sleepTimer => 'Sleep Timer';
	String get timerActive => 'Timer Active';
	String playbackWillPauseIn({required Object duration}) => 'Playback will pause in ${duration}';
	String get sleepTimerCompleted => 'Sleep timer completed - playback paused';
	String get playButton => 'Play';
	String get pauseButton => 'Pause';
	String seekBackwardButton({required Object seconds}) => 'Seek backward ${seconds} seconds';
	String seekForwardButton({required Object seconds}) => 'Seek forward ${seconds} seconds';
	String get previousButton => 'Previous episode';
	String get nextButton => 'Next episode';
	String get previousChapterButton => 'Previous chapter';
	String get nextChapterButton => 'Next chapter';
	String get muteButton => 'Mute';
	String get unmuteButton => 'Unmute';
	String get settingsButton => 'Video settings';
	String get audioTrackButton => 'Audio tracks';
	String get subtitlesButton => 'Subtitles';
	String get chaptersButton => 'Chapters';
	String get versionsButton => 'Video versions';
	String get pipButton => 'Picture-in-Picture mode';
	String get aspectRatioButton => 'Aspect ratio';
	String get fullscreenButton => 'Enter fullscreen';
	String get exitFullscreenButton => 'Exit fullscreen';
	String get alwaysOnTopButton => 'Always on top';
	String get rotationLockButton => 'Rotation lock';
	String get timelineSlider => 'Video timeline';
	String get volumeSlider => 'Volume level';
	String get backButton => 'Back';
}

// Path: userStatus
class _StringsUserStatusEn {
	_StringsUserStatusEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get admin => 'Admin';
	String get restricted => 'Restricted';
	String get protected => 'Protected';
	String get current => 'CURRENT';
}

// Path: messages
class _StringsMessagesEn {
	_StringsMessagesEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get markedAsWatched => 'Marked as watched';
	String get markedAsUnwatched => 'Marked as unwatched';
	String get markedAsWatchedOffline => 'Marked as watched (will sync when online)';
	String get markedAsUnwatchedOffline => 'Marked as unwatched (will sync when online)';
	String get removedFromContinueWatching => 'Removed from Continue Watching';
	String errorLoading({required Object error}) => 'Error: ${error}';
	String get fileInfoNotAvailable => 'File information not available';
	String errorLoadingFileInfo({required Object error}) => 'Error loading file info: ${error}';
	String get errorLoadingSeries => 'Error loading series';
	String get errorLoadingSeason => 'Error loading season';
	String get musicNotSupported => 'Music playback is not yet supported';
	String get logsCleared => 'Logs cleared';
	String get logsCopied => 'Logs copied to clipboard';
	String get noLogsAvailable => 'No logs available';
	String libraryScanning({required Object title}) => 'Scanning "${title}"...';
	String libraryScanStarted({required Object title}) => 'Library scan started for "${title}"';
	String libraryScanFailed({required Object error}) => 'Failed to scan library: ${error}';
	String metadataRefreshing({required Object title}) => 'Refreshing metadata for "${title}"...';
	String metadataRefreshStarted({required Object title}) => 'Metadata refresh started for "${title}"';
	String metadataRefreshFailed({required Object error}) => 'Failed to refresh metadata: ${error}';
	String get logoutConfirm => 'Are you sure you want to logout?';
	String get noSeasonsFound => 'No seasons found';
	String get noEpisodesFound => 'No episodes found in first season';
	String get noEpisodesFoundGeneral => 'No episodes found';
	String get noResultsFound => 'No results found';
	String sleepTimerSet({required Object label}) => 'Sleep timer set for ${label}';
	String get noItemsAvailable => 'No items available';
	String get failedToCreatePlayQueue => 'Failed to create play queue';
	String get failedToCreatePlayQueueNoItems => 'Failed to create play queue - no items';
	String failedPlayback({required Object action, required Object error}) => 'Failed to ${action}: ${error}';
}

// Path: subtitlingStyling
class _StringsSubtitlingStylingEn {
	_StringsSubtitlingStylingEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get stylingOptions => 'Styling Options';
	String get fontSize => 'Font Size';
	String get textColor => 'Text Color';
	String get borderSize => 'Border Size';
	String get borderColor => 'Border Color';
	String get backgroundOpacity => 'Background Opacity';
	String get backgroundColor => 'Background Color';
}

// Path: mpvConfig
class _StringsMpvConfigEn {
	_StringsMpvConfigEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'MPV Configuration';
	String get description => 'Advanced video player settings';
	String get properties => 'Properties';
	String get presets => 'Presets';
	String get noProperties => 'No properties configured';
	String get noPresets => 'No saved presets';
	String get addProperty => 'Add Property';
	String get editProperty => 'Edit Property';
	String get deleteProperty => 'Delete Property';
	String get propertyKey => 'Property Key';
	String get propertyKeyHint => 'e.g., hwdec, demuxer-max-bytes';
	String get propertyValue => 'Property Value';
	String get propertyValueHint => 'e.g., auto, 256000000';
	String get saveAsPreset => 'Save as Preset...';
	String get presetName => 'Preset Name';
	String get presetNameHint => 'Enter a name for this preset';
	String get loadPreset => 'Load';
	String get deletePreset => 'Delete';
	String get presetSaved => 'Preset saved';
	String get presetLoaded => 'Preset loaded';
	String get presetDeleted => 'Preset deleted';
	String get confirmDeletePreset => 'Are you sure you want to delete this preset?';
	String get confirmDeleteProperty => 'Are you sure you want to delete this property?';
	String entriesCount({required Object count}) => '${count} entries';
}

// Path: dialog
class _StringsDialogEn {
	_StringsDialogEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get confirmAction => 'Confirm Action';
	String get cancel => 'Cancel';
	String get playNow => 'Play Now';
}

// Path: discover
class _StringsDiscoverEn {
	_StringsDiscoverEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Discover';
	String get switchProfile => 'Switch Profile';
	String get logout => 'Logout';
	String get noContentAvailable => 'No content available';
	String get addMediaToLibraries => 'Add some media to your libraries';
	String get continueWatching => 'Continue Watching';
	String get play => 'Play';
	String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	String get pause => 'Pause';
	String get overview => 'Overview';
	String get cast => 'Cast';
	String get seasons => 'Seasons';
	String get studio => 'Studio';
	String get rating => 'Rating';
	String get watched => 'Watched';
	String episodeCount({required Object count}) => '${count} episodes';
	String watchedProgress({required Object watched, required Object total}) => '${watched}/${total} watched';
	String get movie => 'Movie';
	String get tvShow => 'TV Show';
	String minutesLeft({required Object minutes}) => '${minutes} min left';
}

// Path: errors
class _StringsErrorsEn {
	_StringsErrorsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String searchFailed({required Object error}) => 'Search failed: ${error}';
	String connectionTimeout({required Object context}) => 'Connection timeout while loading ${context}';
	String get connectionFailed => 'Unable to connect to Plex server';
	String failedToLoad({required Object context, required Object error}) => 'Failed to load ${context}: ${error}';
	String get noClientAvailable => 'No client available';
	String authenticationFailed({required Object error}) => 'Authentication failed: ${error}';
	String get couldNotLaunchUrl => 'Could not launch auth URL';
	String get pleaseEnterToken => 'Please enter a token';
	String get invalidToken => 'Invalid token';
	String failedToVerifyToken({required Object error}) => 'Failed to verify token: ${error}';
	String failedToSwitchProfile({required Object displayName}) => 'Failed to switch to ${displayName}';
}

// Path: libraries
class _StringsLibrariesEn {
	_StringsLibrariesEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Libraries';
	String get scanLibraryFiles => 'Scan Library Files';
	String get scanLibrary => 'Scan Library';
	String get analyze => 'Analyze';
	String get analyzeLibrary => 'Analyze Library';
	String get refreshMetadata => 'Refresh Metadata';
	String get emptyTrash => 'Empty Trash';
	String emptyingTrash({required Object title}) => 'Emptying trash for "${title}"...';
	String trashEmptied({required Object title}) => 'Trash emptied for "${title}"';
	String failedToEmptyTrash({required Object error}) => 'Failed to empty trash: ${error}';
	String analyzing({required Object title}) => 'Analyzing "${title}"...';
	String analysisStarted({required Object title}) => 'Analysis started for "${title}"';
	String failedToAnalyze({required Object error}) => 'Failed to analyze library: ${error}';
	String get noLibrariesFound => 'No libraries found';
	String get thisLibraryIsEmpty => 'This library is empty';
	String get all => 'All';
	String get clearAll => 'Clear All';
	String scanLibraryConfirm({required Object title}) => 'Are you sure you want to scan "${title}"?';
	String analyzeLibraryConfirm({required Object title}) => 'Are you sure you want to analyze "${title}"?';
	String refreshMetadataConfirm({required Object title}) => 'Are you sure you want to refresh metadata for "${title}"?';
	String emptyTrashConfirm({required Object title}) => 'Are you sure you want to empty trash for "${title}"?';
	String get manageLibraries => 'Manage Libraries';
	String get sort => 'Sort';
	String get sortBy => 'Sort By';
	String get filters => 'Filters';
	String get confirmActionMessage => 'Are you sure you want to perform this action?';
	String get showLibrary => 'Show library';
	String get hideLibrary => 'Hide library';
	String get libraryOptions => 'Library options';
	String get content => 'library content';
	String get selectLibrary => 'Select library';
	String filtersWithCount({required Object count}) => 'Filters (${count})';
	String get noRecommendations => 'No recommendations available';
	String get noCollections => 'No collections in this library';
	String get noFoldersFound => 'No folders found';
	String get folders => 'folders';
	late final _StringsLibrariesTabsEn tabs = _StringsLibrariesTabsEn._(_root);
	late final _StringsLibrariesGroupingsEn groupings = _StringsLibrariesGroupingsEn._(_root);
}

// Path: about
class _StringsAboutEn {
	_StringsAboutEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'About';
	String get openSourceLicenses => 'Open Source Licenses';
	String versionLabel({required Object version}) => 'Version ${version}';
	String get appDescription => 'A beautiful Plex client for Flutter';
	String get viewLicensesDescription => 'View licenses of third-party libraries';
}

// Path: serverSelection
class _StringsServerSelectionEn {
	_StringsServerSelectionEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get allServerConnectionsFailed => 'Failed to connect to any servers. Please check your network and try again.';
	String get noServersFound => 'No servers found';
	String noServersFoundForAccount({required Object username, required Object email}) => 'No servers found for ${username} (${email})';
	String failedToLoadServers({required Object error}) => 'Failed to load servers: ${error}';
}

// Path: hubDetail
class _StringsHubDetailEn {
	_StringsHubDetailEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Title';
	String get releaseYear => 'Release Year';
	String get dateAdded => 'Date Added';
	String get rating => 'Rating';
	String get noItemsFound => 'No items found';
}

// Path: logs
class _StringsLogsEn {
	_StringsLogsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get clearLogs => 'Clear Logs';
	String get copyLogs => 'Copy Logs';
	String get error => 'Error:';
	String get stackTrace => 'Stack Trace:';
}

// Path: licenses
class _StringsLicensesEn {
	_StringsLicensesEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get relatedPackages => 'Related Packages';
	String get license => 'License';
	String licenseNumber({required Object number}) => 'License ${number}';
	String licensesCount({required Object count}) => '${count} licenses';
}

// Path: navigation
class _StringsNavigationEn {
	_StringsNavigationEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get home => 'Home';
	String get search => 'Search';
	String get libraries => 'Libraries';
	String get settings => 'Settings';
	String get downloads => 'Downloads';
}

// Path: collections
class _StringsCollectionsEn {
	_StringsCollectionsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Collections';
	String get collection => 'Collection';
	String get empty => 'Collection is empty';
	String get unknownLibrarySection => 'Cannot delete: Unknown library section';
	String get deleteCollection => 'Delete Collection';
	String deleteConfirm({required Object title}) => 'Are you sure you want to delete "${title}"? This action cannot be undone.';
	String get deleted => 'Collection deleted';
	String get deleteFailed => 'Failed to delete collection';
	String deleteFailedWithError({required Object error}) => 'Failed to delete collection: ${error}';
	String failedToLoadItems({required Object error}) => 'Failed to load collection items: ${error}';
	String get selectCollection => 'Select Collection';
	String get createNewCollection => 'Create New Collection';
	String get collectionName => 'Collection Name';
	String get enterCollectionName => 'Enter collection name';
	String get addedToCollection => 'Added to collection';
	String get errorAddingToCollection => 'Failed to add to collection';
	String get created => 'Collection created';
	String get removeFromCollection => 'Remove from collection';
	String removeFromCollectionConfirm({required Object title}) => 'Remove "${title}" from this collection?';
	String get removedFromCollection => 'Removed from collection';
	String get removeFromCollectionFailed => 'Failed to remove from collection';
	String removeFromCollectionError({required Object error}) => 'Error removing from collection: ${error}';
}

// Path: playlists
class _StringsPlaylistsEn {
	_StringsPlaylistsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Playlists';
	String get playlist => 'Playlist';
	String get noPlaylists => 'No playlists found';
	String get create => 'Create Playlist';
	String get playlistName => 'Playlist Name';
	String get enterPlaylistName => 'Enter playlist name';
	String get delete => 'Delete Playlist';
	String get removeItem => 'Remove from Playlist';
	String get smartPlaylist => 'Smart Playlist';
	String itemCount({required Object count}) => '${count} items';
	String get oneItem => '1 item';
	String get emptyPlaylist => 'This playlist is empty';
	String get deleteConfirm => 'Delete Playlist?';
	String deleteMessage({required Object name}) => 'Are you sure you want to delete "${name}"?';
	String get created => 'Playlist created';
	String get deleted => 'Playlist deleted';
	String get itemAdded => 'Added to playlist';
	String get itemRemoved => 'Removed from playlist';
	String get selectPlaylist => 'Select Playlist';
	String get createNewPlaylist => 'Create New Playlist';
	String get errorCreating => 'Failed to create playlist';
	String get errorDeleting => 'Failed to delete playlist';
	String get errorLoading => 'Failed to load playlists';
	String get errorAdding => 'Failed to add to playlist';
	String get errorReordering => 'Failed to reorder playlist item';
	String get errorRemoving => 'Failed to remove from playlist';
}

// Path: watchTogether
class _StringsWatchTogetherEn {
	_StringsWatchTogetherEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Watch Together';
	String get description => 'Watch content in sync with friends and family';
	String get createSession => 'Create Session';
	String get creating => 'Creating...';
	String get joinSession => 'Join Session';
	String get joining => 'Joining...';
	String get controlMode => 'Control Mode';
	String get controlModeQuestion => 'Who can control playback?';
	String get hostOnly => 'Host Only';
	String get anyone => 'Anyone';
	String get hostingSession => 'Hosting Session';
	String get inSession => 'In Session';
	String get sessionCode => 'Session Code';
	String get hostControlsPlayback => 'Host controls playback';
	String get anyoneCanControl => 'Anyone can control playback';
	String get hostControls => 'Host controls';
	String get anyoneControls => 'Anyone controls';
	String get participants => 'Participants';
	String get host => 'Host';
	String get hostBadge => 'HOST';
	String get youAreHost => 'You are the host';
	String get watchingWithOthers => 'Watching with others';
	String get endSession => 'End Session';
	String get leaveSession => 'Leave Session';
	String get endSessionQuestion => 'End Session?';
	String get leaveSessionQuestion => 'Leave Session?';
	String get endSessionConfirm => 'This will end the session for all participants.';
	String get leaveSessionConfirm => 'You will be removed from the session.';
	String get endSessionConfirmOverlay => 'This will end the watch session for all participants.';
	String get leaveSessionConfirmOverlay => 'You will be disconnected from the watch session.';
	String get end => 'End';
	String get leave => 'Leave';
	String get syncing => 'Syncing...';
	String get participant => 'participant';
	String get joinWatchSession => 'Join Watch Session';
	String get enterCodeHint => 'Enter 8-character code';
	String get pasteFromClipboard => 'Paste from clipboard';
	String get pleaseEnterCode => 'Please enter a session code';
	String get codeMustBe8Chars => 'Session code must be 8 characters';
	String get joinInstructions => 'Enter the session code shared by the host to join their watch session.';
	String get failedToCreate => 'Failed to create session';
	String get failedToJoin => 'Failed to join session';
}

// Path: downloads
class _StringsDownloadsEn {
	_StringsDownloadsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Downloads';
	String get manage => 'Manage';
	String get tvShows => 'TV Shows';
	String get movies => 'Movies';
	String get noDownloads => 'No downloads yet';
	String get noDownloadsDescription => 'Downloaded content will appear here for offline viewing';
	String get downloadNow => 'Download';
	String get deleteDownload => 'Delete download';
	String get retryDownload => 'Retry download';
	String get downloadQueued => 'Download queued';
	String episodesQueued({required Object count}) => '${count} episodes queued for download';
	String get downloadDeleted => 'Download deleted';
	String deleteConfirm({required Object title}) => 'Are you sure you want to delete "${title}"? This will remove the downloaded file from your device.';
	String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Deleting ${title}... (${current} of ${total})';
}

// Path: libraries.tabs
class _StringsLibrariesTabsEn {
	_StringsLibrariesTabsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get recommended => 'Recommended';
	String get browse => 'Browse';
	String get collections => 'Collections';
	String get playlists => 'Playlists';
}

// Path: libraries.groupings
class _StringsLibrariesGroupingsEn {
	_StringsLibrariesGroupingsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get all => 'All';
	String get movies => 'Movies';
	String get shows => 'TV Shows';
	String get seasons => 'Seasons';
	String get episodes => 'Episodes';
	String get folders => 'Folders';
}

// Path: <root>
class _StringsDe implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	_StringsDe.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.de,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <de>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	@override late final _StringsDe _root = this; // ignore: unused_field

	// Translations
	@override late final _StringsAppDe app = _StringsAppDe._(_root);
	@override late final _StringsAuthDe auth = _StringsAuthDe._(_root);
	@override late final _StringsCommonDe common = _StringsCommonDe._(_root);
	@override late final _StringsScreensDe screens = _StringsScreensDe._(_root);
	@override late final _StringsUpdateDe update = _StringsUpdateDe._(_root);
	@override late final _StringsSettingsDe settings = _StringsSettingsDe._(_root);
	@override late final _StringsSearchDe search = _StringsSearchDe._(_root);
	@override late final _StringsHotkeysDe hotkeys = _StringsHotkeysDe._(_root);
	@override late final _StringsPinEntryDe pinEntry = _StringsPinEntryDe._(_root);
	@override late final _StringsFileInfoDe fileInfo = _StringsFileInfoDe._(_root);
	@override late final _StringsMediaMenuDe mediaMenu = _StringsMediaMenuDe._(_root);
	@override late final _StringsAccessibilityDe accessibility = _StringsAccessibilityDe._(_root);
	@override late final _StringsTooltipsDe tooltips = _StringsTooltipsDe._(_root);
	@override late final _StringsVideoControlsDe videoControls = _StringsVideoControlsDe._(_root);
	@override late final _StringsUserStatusDe userStatus = _StringsUserStatusDe._(_root);
	@override late final _StringsMessagesDe messages = _StringsMessagesDe._(_root);
	@override late final _StringsSubtitlingStylingDe subtitlingStyling = _StringsSubtitlingStylingDe._(_root);
	@override late final _StringsMpvConfigDe mpvConfig = _StringsMpvConfigDe._(_root);
	@override late final _StringsDialogDe dialog = _StringsDialogDe._(_root);
	@override late final _StringsDiscoverDe discover = _StringsDiscoverDe._(_root);
	@override late final _StringsErrorsDe errors = _StringsErrorsDe._(_root);
	@override late final _StringsLibrariesDe libraries = _StringsLibrariesDe._(_root);
	@override late final _StringsAboutDe about = _StringsAboutDe._(_root);
	@override late final _StringsServerSelectionDe serverSelection = _StringsServerSelectionDe._(_root);
	@override late final _StringsHubDetailDe hubDetail = _StringsHubDetailDe._(_root);
	@override late final _StringsLogsDe logs = _StringsLogsDe._(_root);
	@override late final _StringsLicensesDe licenses = _StringsLicensesDe._(_root);
	@override late final _StringsNavigationDe navigation = _StringsNavigationDe._(_root);
	@override late final _StringsDownloadsDe downloads = _StringsDownloadsDe._(_root);
	@override late final _StringsPlaylistsDe playlists = _StringsPlaylistsDe._(_root);
	@override late final _StringsCollectionsDe collections = _StringsCollectionsDe._(_root);
	@override late final _StringsWatchTogetherDe watchTogether = _StringsWatchTogetherDe._(_root);
}

// Path: app
class _StringsAppDe implements _StringsAppEn {
	_StringsAppDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
	@override String get loading => 'Lädt...';
}

// Path: auth
class _StringsAuthDe implements _StringsAuthEn {
	_StringsAuthDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Mit Plex anmelden';
	@override String get showQRCode => 'QR-Code anzeigen';
	@override String get cancel => 'Abbrechen';
	@override String get authenticate => 'Authentifizieren';
	@override String get retry => 'Erneut versuchen';
	@override String get debugEnterToken => 'Debug: Plex-Token eingeben';
	@override String get plexTokenLabel => 'Plex-Auth-Token';
	@override String get plexTokenHint => 'Plex.tv-Token eingeben';
	@override String get authenticationTimeout => 'Authentifizierung abgelaufen. Bitte erneut versuchen.';
	@override String get scanQRCodeInstruction => 'Diesen QR-Code mit einem bei Plex angemeldeten Gerät scannen, um zu authentifizieren.';
	@override String get waitingForAuth => 'Warte auf Authentifizierung...\nBitte Anmeldung im Browser abschließen.';
}

// Path: common
class _StringsCommonDe implements _StringsCommonEn {
	_StringsCommonDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Abbrechen';
	@override String get save => 'Speichern';
	@override String get close => 'Schließen';
	@override String get clear => 'Leeren';
	@override String get reset => 'Zurücksetzen';
	@override String get later => 'Später';
	@override String get submit => 'Senden';
	@override String get confirm => 'Bestätigen';
	@override String get retry => 'Erneut versuchen';
	@override String get logout => 'Abmelden';
	@override String get unknown => 'Unbekannt';
	@override String get refresh => 'Aktualisieren';
	@override String get yes => 'Ja';
	@override String get no => 'Nein';
	@override String get delete => 'Löschen';
	@override String get shuffle => 'Zufall';
	@override String get addTo => 'Hinzufügen zu...';
}

// Path: screens
class _StringsScreensDe implements _StringsScreensEn {
	_StringsScreensDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Lizenzen';
	@override String get selectServer => 'Server auswählen';
	@override String get switchProfile => 'Profil wechseln';
	@override String get subtitleStyling => 'Untertitel-Stil';
	@override String get mpvConfig => 'MPV-Konfiguration';
	@override String get search => 'Suche';
	@override String get logs => 'Protokolle';
}

// Path: update
class _StringsUpdateDe implements _StringsUpdateEn {
	_StringsUpdateDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get available => 'Update verfügbar';
	@override String versionAvailable({required Object version}) => 'Version ${version} ist verfügbar';
	@override String currentVersion({required Object version}) => 'Aktuell: ${version}';
	@override String get skipVersion => 'Diese Version überspringen';
	@override String get viewRelease => 'Release anzeigen';
	@override String get latestVersion => 'Aktuellste Version installiert';
	@override String get checkFailed => 'Fehler bei der Updateprüfung';
}

// Path: settings
class _StringsSettingsDe implements _StringsSettingsEn {
	_StringsSettingsDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Einstellungen';
	@override String get language => 'Sprache';
	@override String get theme => 'Design';
	@override String get appearance => 'Darstellung';
	@override String get videoPlayback => 'Videowiedergabe';
	@override String get advanced => 'Erweitert';
	@override String get episodePosterMode => 'Episoden-Poster-Stil';
	@override String get seriesPoster => 'Serienposter';
	@override String get seriesPosterDescription => 'Zeige das Serienposter für alle Episoden';
	@override String get seasonPoster => 'Staffelposter';
	@override String get seasonPosterDescription => 'Zeige das staffelspezifische Poster für Episoden';
	@override String get episodeThumbnail => 'Episoden-Miniatur';
	@override String get episodeThumbnailDescription => 'Zeige 16:9 Episoden-Vorschaubilder';
	@override String get showHeroSectionDescription => 'Bereich mit empfohlenen Inhalten auf der Startseite anzeigen';
	@override String get secondsLabel => 'Sekunden';
	@override String get minutesLabel => 'Minuten';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Dauer eingeben (${min}-${max})';
	@override String get systemTheme => 'System';
	@override String get systemThemeDescription => 'Systemeinstellungen folgen';
	@override String get lightTheme => 'Hell';
	@override String get darkTheme => 'Dunkel';
	@override String get libraryDensity => 'Mediathekdichte';
	@override String get compact => 'Kompakt';
	@override String get compactDescription => 'Kleinere Karten, mehr Elemente sichtbar';
	@override String get normal => 'Normal';
	@override String get normalDescription => 'Standardgröße';
	@override String get comfortable => 'Großzügig';
	@override String get comfortableDescription => 'Größere Karten, weniger Elemente sichtbar';
	@override String get viewMode => 'Ansichtsmodus';
	@override String get gridView => 'Raster';
	@override String get gridViewDescription => 'Elemente im Raster anzeigen';
	@override String get listView => 'Liste';
	@override String get listViewDescription => 'Elemente in Listenansicht anzeigen';
	@override String get showHeroSection => 'Hero-Bereich anzeigen';
	@override String get useGlobalHubs => 'Plex-Startseiten-Layout verwenden';
	@override String get useGlobalHubsDescription => 'Zeigt Startseiten-Hubs wie der offizielle Plex-Client. Wenn deaktiviert, werden stattdessen Empfehlungen pro Bibliothek angezeigt.';
	@override String get hardwareDecoding => 'Hardware-Decodierung';
	@override String get hardwareDecodingDescription => 'Hardwarebeschleunigung verwenden, sofern verfügbar';
	@override String get bufferSize => 'Puffergröße';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get subtitleStyling => 'Untertitel-Stil';
	@override String get subtitleStylingDescription => 'Aussehen von Untertiteln anpassen';
	@override String get smallSkipDuration => 'Kleine Sprungdauer';
	@override String get largeSkipDuration => 'Große Sprungdauer';
	@override String secondsUnit({required Object seconds}) => '${seconds} Sekunden';
	@override String get defaultSleepTimer => 'Standard-Sleep-Timer';
	@override String minutesUnit({required Object minutes}) => '${minutes} Minuten';
	@override String get rememberTrackSelections => 'Spurauswahl pro Serie/Film merken';
	@override String get rememberTrackSelectionsDescription => 'Audio- und Untertitelsprache automatisch speichern, wenn während der Wiedergabe geändert';
	@override String get videoPlayerControls => 'Videoplayer-Steuerung';
	@override String get keyboardShortcuts => 'Tastenkürzel';
	@override String get keyboardShortcutsDescription => 'Tastenkürzel anpassen';
	@override String get videoPlayerNavigation => 'Videoplayer-Navigation';
	@override String get videoPlayerNavigationDescription => 'Pfeiltasten zur Navigation der Videoplayer-Steuerung verwenden';
	@override String get debugLogging => 'Debug-Protokollierung';
	@override String get debugLoggingDescription => 'Detaillierte Protokolle zur Fehleranalyse aktivieren';
	@override String get viewLogs => 'Protokolle anzeigen';
	@override String get viewLogsDescription => 'App-Protokolle anzeigen';
	@override String get clearCache => 'Cache löschen';
	@override String get clearCacheDescription => 'Löscht alle zwischengespeicherten Bilder und Daten. Die App kann danach langsamer laden.';
	@override String get clearCacheSuccess => 'Cache erfolgreich gelöscht';
	@override String get resetSettings => 'Einstellungen zurücksetzen';
	@override String get resetSettingsDescription => 'Alle Einstellungen auf Standard zurücksetzen. Dies kann nicht rückgängig gemacht werden.';
	@override String get resetSettingsSuccess => 'Einstellungen erfolgreich zurückgesetzt';
	@override String get shortcutsReset => 'Tastenkürzel auf Standard zurückgesetzt';
	@override String get about => 'Über';
	@override String get aboutDescription => 'App-Informationen und Lizenzen';
	@override String get updates => 'Updates';
	@override String get updateAvailable => 'Update verfügbar';
	@override String get checkForUpdates => 'Nach Updates suchen';
	@override String get validationErrorEnterNumber => 'Bitte eine gültige Zahl eingeben';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Dauer muss zwischen ${min} und ${max} ${unit} liegen';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Tastenkürzel bereits zugewiesen an ${action}';
	@override String shortcutUpdated({required Object action}) => 'Tastenkürzel aktualisiert für ${action}';
	@override String get autoSkip => 'Automatisches Überspringen';
	@override String get autoSkipIntro => 'Intro automatisch überspringen';
	@override String get autoSkipIntroDescription => 'Intro-Marker nach wenigen Sekunden automatisch überspringen';
	@override String get autoSkipCredits => 'Abspann automatisch überspringen';
	@override String get autoSkipCreditsDescription => 'Abspann automatisch überspringen und nächste Episode abspielen';
	@override String get autoSkipDelay => 'Verzögerung für automatisches Überspringen';
	@override String autoSkipDelayDescription({required Object seconds}) => '${seconds} Sekunden vor dem automatischen Überspringen warten';
	@override String get downloads => 'Downloads';
	@override String get downloadLocationDescription => 'Speicherort für heruntergeladene Inhalte wählen';
	@override String get downloadLocationDefault => 'Standard (App-Speicher)';
	@override String get downloadLocationCustom => 'Benutzerdefinierter Speicherort';
	@override String get selectFolder => 'Ordner auswählen';
	@override String get resetToDefault => 'Auf Standard zurücksetzen';
	@override String currentPath({required Object path}) => 'Aktuell: ${path}';
	@override String get downloadLocationChanged => 'Download-Speicherort geändert';
	@override String get downloadLocationReset => 'Download-Speicherort auf Standard zurückgesetzt';
	@override String get downloadLocationInvalid => 'Ausgewählter Ordner ist nicht beschreibbar';
	@override String get downloadLocationSelectError => 'Ordnerauswahl fehlgeschlagen';
	@override String get downloadOnWifiOnly => 'Nur über WLAN herunterladen';
	@override String get downloadOnWifiOnlyDescription => 'Downloads über mobile Daten verhindern';
	@override String get cellularDownloadBlocked => 'Downloads sind über mobile Daten deaktiviert. Verbinde dich mit einem WLAN oder ändere die Einstellung.';
	@override String get maxVolume => 'Maximale Lautstärke';
	@override String get maxVolumeDescription => 'Lautstärke über 100% für leise Medien erlauben';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get maxVolumeHint => 'Maximale Lautstärke eingeben (100-300)';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Zeige auf Discord, was du gerade schaust';
}

// Path: search
class _StringsSearchDe implements _StringsSearchEn {
	_StringsSearchDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Filme, Serien, Musik suchen...';
	@override String get tryDifferentTerm => 'Anderen Suchbegriff versuchen';
	@override String get searchYourMedia => 'In den eigenen Medien suchen';
	@override String get enterTitleActorOrKeyword => 'Titel, Schauspieler oder Stichwort eingeben';
}

// Path: hotkeys
class _StringsHotkeysDe implements _StringsHotkeysEn {
	_StringsHotkeysDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Tastenkürzel festlegen für ${actionName}';
	@override String get clearShortcut => 'Kürzel löschen';
}

// Path: pinEntry
class _StringsPinEntryDe implements _StringsPinEntryEn {
	_StringsPinEntryDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get enterPin => 'PIN eingeben';
	@override String get showPin => 'PIN anzeigen';
	@override String get hidePin => 'PIN verbergen';
}

// Path: fileInfo
class _StringsFileInfoDe implements _StringsFileInfoEn {
	_StringsFileInfoDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Dateiinfo';
	@override String get video => 'Video';
	@override String get audio => 'Audio';
	@override String get file => 'Datei';
	@override String get advanced => 'Erweitert';
	@override String get codec => 'Codec';
	@override String get resolution => 'Auflösung';
	@override String get bitrate => 'Bitrate';
	@override String get frameRate => 'Bildrate';
	@override String get aspectRatio => 'Seitenverhältnis';
	@override String get profile => 'Profil';
	@override String get bitDepth => 'Farbtiefe';
	@override String get colorSpace => 'Farbraum';
	@override String get colorRange => 'Farbbereich';
	@override String get colorPrimaries => 'Primärfarben';
	@override String get chromaSubsampling => 'Chroma-Subsampling';
	@override String get channels => 'Kanäle';
	@override String get path => 'Pfad';
	@override String get size => 'Größe';
	@override String get container => 'Container';
	@override String get duration => 'Dauer';
	@override String get optimizedForStreaming => 'Für Streaming optimiert';
	@override String get has64bitOffsets => '64-Bit-Offsets';
}

// Path: mediaMenu
class _StringsMediaMenuDe implements _StringsMediaMenuEn {
	_StringsMediaMenuDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Als gesehen markieren';
	@override String get markAsUnwatched => 'Als ungesehen markieren';
	@override String get removeFromContinueWatching => 'Aus ‚Weiterschauen‘ entfernen';
	@override String get goToSeries => 'Zur Serie';
	@override String get goToSeason => 'Zur Staffel';
	@override String get shufflePlay => 'Zufallswiedergabe';
	@override String get fileInfo => 'Dateiinfo';
}

// Path: accessibility
class _StringsAccessibilityDe implements _StringsAccessibilityEn {
	_StringsAccessibilityDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, Film';
	@override String mediaCardShow({required Object title}) => '${title}, Serie';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'angesehen';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} Prozent angesehen';
	@override String get mediaCardUnwatched => 'ungeschaut';
	@override String get tapToPlay => 'Zum Abspielen tippen';
}

// Path: tooltips
class _StringsTooltipsDe implements _StringsTooltipsEn {
	_StringsTooltipsDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Zufallswiedergabe';
	@override String get markAsWatched => 'Als gesehen markieren';
	@override String get markAsUnwatched => 'Als ungesehen markieren';
}

// Path: videoControls
class _StringsVideoControlsDe implements _StringsVideoControlsEn {
	_StringsVideoControlsDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Audio';
	@override String get subtitlesLabel => 'Untertitel';
	@override String get resetToZero => 'Auf 0 ms zurücksetzen';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} spielt später';
	@override String playsEarlier({required Object label}) => '${label} spielt früher';
	@override String get noOffset => 'Kein Offset';
	@override String get letterbox => 'Letterbox';
	@override String get fillScreen => 'Bild füllen';
	@override String get stretch => 'Strecken';
	@override String get lockRotation => 'Rotation sperren';
	@override String get unlockRotation => 'Rotation entsperren';
	@override String get sleepTimer => 'Schlaftimer';
	@override String get timerActive => 'Schlaftimer aktiv';
	@override String playbackWillPauseIn({required Object duration}) => 'Wiedergabe wird in ${duration} pausiert';
	@override String get sleepTimerCompleted => 'Schlaftimer abgelaufen – Wiedergabe pausiert';
	@override String get playButton => 'Wiedergeben';
	@override String get pauseButton => 'Pause';
	@override String seekBackwardButton({required Object seconds}) => '${seconds} Sekunden zurück';
	@override String seekForwardButton({required Object seconds}) => '${seconds} Sekunden vor';
	@override String get previousButton => 'Vorherige Episode';
	@override String get nextButton => 'Nächste Episode';
	@override String get previousChapterButton => 'Vorheriges Kapitel';
	@override String get nextChapterButton => 'Nächstes Kapitel';
	@override String get muteButton => 'Stumm schalten';
	@override String get unmuteButton => 'Stummschaltung aufheben';
	@override String get settingsButton => 'Videoeinstellungen';
	@override String get audioTrackButton => 'Tonspuren';
	@override String get subtitlesButton => 'Untertitel';
	@override String get chaptersButton => 'Kapitel';
	@override String get versionsButton => 'Videoversionen';
	@override String get pipButton => 'Bild-in-Bild Modus';
	@override String get aspectRatioButton => 'Seitenverhältnis';
	@override String get fullscreenButton => 'Vollbild aktivieren';
	@override String get exitFullscreenButton => 'Vollbild verlassen';
	@override String get alwaysOnTopButton => 'Immer im Vordergrund';
	@override String get rotationLockButton => 'Dreh­sperre';
	@override String get timelineSlider => 'Video-Zeitleiste';
	@override String get volumeSlider => 'Lautstärkepegel';
	@override String get backButton => 'Zurück';
}

// Path: userStatus
class _StringsUserStatusDe implements _StringsUserStatusEn {
	_StringsUserStatusDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Eigentümer';
	@override String get restricted => 'Eingeschränkt';
	@override String get protected => 'Geschützt';
	@override String get current => 'AKTUELL';
}

// Path: messages
class _StringsMessagesDe implements _StringsMessagesEn {
	_StringsMessagesDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Als gesehen markiert';
	@override String get markedAsUnwatched => 'Als ungesehen markiert';
	@override String get markedAsWatchedOffline => 'Als gesehen markiert (wird synchronisiert, wenn online)';
	@override String get markedAsUnwatchedOffline => 'Als ungesehen markiert (wird synchronisiert, wenn online)';
	@override String get removedFromContinueWatching => 'Aus ‚Weiterschauen\' entfernt';
	@override String errorLoading({required Object error}) => 'Fehler: ${error}';
	@override String get fileInfoNotAvailable => 'Dateiinfo nicht verfügbar';
	@override String errorLoadingFileInfo({required Object error}) => 'Fehler beim Laden der Dateiinfo: ${error}';
	@override String get errorLoadingSeries => 'Fehler beim Laden der Serie';
	@override String get errorLoadingSeason => 'Fehler beim Laden der Staffel';
	@override String get musicNotSupported => 'Musikwiedergabe wird noch nicht unterstützt';
	@override String get logsCleared => 'Protokolle gelöscht';
	@override String get logsCopied => 'Protokolle in Zwischenablage kopiert';
	@override String get noLogsAvailable => 'Keine Protokolle verfügbar';
	@override String libraryScanning({required Object title}) => 'Scanne „${title}“...';
	@override String libraryScanStarted({required Object title}) => 'Mediathekscan gestartet für „${title}“';
	@override String libraryScanFailed({required Object error}) => 'Fehler beim Scannen der Mediathek: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Metadaten werden aktualisiert für „${title}“...';
	@override String metadataRefreshStarted({required Object title}) => 'Metadaten-Aktualisierung gestartet für „${title}“';
	@override String metadataRefreshFailed({required Object error}) => 'Metadaten konnten nicht aktualisiert werden: ${error}';
	@override String get logoutConfirm => 'Abmeldung wirklich durchführen?';
	@override String get noSeasonsFound => 'Keine Staffeln gefunden';
	@override String get noEpisodesFound => 'Keine Episoden in der ersten Staffel gefunden';
	@override String get noEpisodesFoundGeneral => 'Keine Episoden gefunden';
	@override String get noResultsFound => 'Keine Ergebnisse gefunden';
	@override String sleepTimerSet({required Object label}) => 'Sleep-Timer gesetzt auf ${label}';
	@override String get noItemsAvailable => 'Keine Elemente verfügbar';
	@override String get failedToCreatePlayQueue => 'Wiedergabewarteschlange konnte nicht erstellt werden';
	@override String get failedToCreatePlayQueueNoItems => 'Wiedergabewarteschlange konnte nicht erstellt werden – keine Elemente';
	@override String failedPlayback({required Object action, required Object error}) => 'Wiedergabe für ${action} fehlgeschlagen: ${error}';
}

// Path: subtitlingStyling
class _StringsSubtitlingStylingDe implements _StringsSubtitlingStylingEn {
	_StringsSubtitlingStylingDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get stylingOptions => 'Stiloptionen';
	@override String get fontSize => 'Schriftgröße';
	@override String get textColor => 'Textfarbe';
	@override String get borderSize => 'Rahmengröße';
	@override String get borderColor => 'Rahmenfarbe';
	@override String get backgroundOpacity => 'Hintergrunddeckkraft';
	@override String get backgroundColor => 'Hintergrundfarbe';
}

// Path: mpvConfig
class _StringsMpvConfigDe implements _StringsMpvConfigEn {
	_StringsMpvConfigDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'MPV-Konfiguration';
	@override String get description => 'Erweiterte Videoplayer-Einstellungen';
	@override String get properties => 'Eigenschaften';
	@override String get presets => 'Voreinstellungen';
	@override String get noProperties => 'Keine Eigenschaften konfiguriert';
	@override String get noPresets => 'Keine gespeicherten Voreinstellungen';
	@override String get addProperty => 'Eigenschaft hinzufügen';
	@override String get editProperty => 'Eigenschaft bearbeiten';
	@override String get deleteProperty => 'Eigenschaft löschen';
	@override String get propertyKey => 'Eigenschaftsschlüssel';
	@override String get propertyKeyHint => 'z.B. hwdec, demuxer-max-bytes';
	@override String get propertyValue => 'Eigenschaftswert';
	@override String get propertyValueHint => 'z.B. auto, 256000000';
	@override String get saveAsPreset => 'Als Voreinstellung speichern...';
	@override String get presetName => 'Name der Voreinstellung';
	@override String get presetNameHint => 'Namen für diese Voreinstellung eingeben';
	@override String get loadPreset => 'Laden';
	@override String get deletePreset => 'Löschen';
	@override String get presetSaved => 'Voreinstellung gespeichert';
	@override String get presetLoaded => 'Voreinstellung geladen';
	@override String get presetDeleted => 'Voreinstellung gelöscht';
	@override String get confirmDeletePreset => 'Möchten Sie diese Voreinstellung wirklich löschen?';
	@override String get confirmDeleteProperty => 'Möchten Sie diese Eigenschaft wirklich löschen?';
	@override String entriesCount({required Object count}) => '${count} Einträge';
}

// Path: dialog
class _StringsDialogDe implements _StringsDialogEn {
	_StringsDialogDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Aktion bestätigen';
	@override String get cancel => 'Abbrechen';
	@override String get playNow => 'Jetzt abspielen';
}

// Path: discover
class _StringsDiscoverDe implements _StringsDiscoverEn {
	_StringsDiscoverDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Entdecken';
	@override String get switchProfile => 'Profil wechseln';
	@override String get switchServer => 'Server wechseln';
	@override String get logout => 'Abmelden';
	@override String get noContentAvailable => 'Kein Inhalt verfügbar';
	@override String get addMediaToLibraries => 'Medien zur Mediathek hinzufügen';
	@override String get continueWatching => 'Weiterschauen';
	@override String get play => 'Abspielen';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get pause => 'Pause';
	@override String get overview => 'Übersicht';
	@override String get cast => 'Besetzung';
	@override String get seasons => 'Staffeln';
	@override String get studio => 'Studio';
	@override String get rating => 'Altersfreigabe';
	@override String get watched => 'Gesehen';
	@override String episodeCount({required Object count}) => '${count} Episoden';
	@override String watchedProgress({required Object watched, required Object total}) => '${watched} von ${total} gesehen';
	@override String get movie => 'Film';
	@override String get tvShow => 'Serie';
	@override String minutesLeft({required Object minutes}) => '${minutes} Min übrig';
}

// Path: errors
class _StringsErrorsDe implements _StringsErrorsEn {
	_StringsErrorsDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Suche fehlgeschlagen: ${error}';
	@override String connectionTimeout({required Object context}) => 'Zeitüberschreitung beim Laden von ${context}';
	@override String get connectionFailed => 'Verbindung zum Plex-Server fehlgeschlagen';
	@override String failedToLoad({required Object context, required Object error}) => 'Fehler beim Laden von ${context}: ${error}';
	@override String get noClientAvailable => 'Kein Client verfügbar';
	@override String authenticationFailed({required Object error}) => 'Authentifizierung fehlgeschlagen: ${error}';
	@override String get couldNotLaunchUrl => 'Auth-URL konnte nicht geöffnet werden';
	@override String get pleaseEnterToken => 'Bitte Token eingeben';
	@override String get invalidToken => 'Ungültiges Token';
	@override String failedToVerifyToken({required Object error}) => 'Token-Verifizierung fehlgeschlagen: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Profilwechsel zu ${displayName} fehlgeschlagen';
}

// Path: libraries
class _StringsLibrariesDe implements _StringsLibrariesEn {
	_StringsLibrariesDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Mediatheken';
	@override String get scanLibraryFiles => 'Mediatheksdateien scannen';
	@override String get scanLibrary => 'Mediathek scannen';
	@override String get analyze => 'Analysieren';
	@override String get analyzeLibrary => 'Mediathek analysieren';
	@override String get refreshMetadata => 'Metadaten aktualisieren';
	@override String get emptyTrash => 'Papierkorb leeren';
	@override String emptyingTrash({required Object title}) => 'Papierkorb für „${title}“ wird geleert...';
	@override String trashEmptied({required Object title}) => 'Papierkorb für „${title}“ geleert';
	@override String failedToEmptyTrash({required Object error}) => 'Papierkorb konnte nicht geleert werden: ${error}';
	@override String analyzing({required Object title}) => 'Analysiere „${title}“...';
	@override String analysisStarted({required Object title}) => 'Analyse gestartet für „${title}“';
	@override String failedToAnalyze({required Object error}) => 'Analyse der Mediathek fehlgeschlagen: ${error}';
	@override String get noLibrariesFound => 'Keine Mediatheken gefunden';
	@override String get thisLibraryIsEmpty => 'Diese Mediathek ist leer';
	@override String get all => 'Alle';
	@override String get clearAll => 'Alle löschen';
	@override String scanLibraryConfirm({required Object title}) => '„${title}“ wirklich scannen?';
	@override String analyzeLibraryConfirm({required Object title}) => '„${title}“ wirklich analysieren?';
	@override String refreshMetadataConfirm({required Object title}) => 'Metadaten für „${title}“ wirklich aktualisieren?';
	@override String emptyTrashConfirm({required Object title}) => 'Papierkorb für „${title}“ wirklich leeren?';
	@override String get manageLibraries => 'Mediatheken verwalten';
	@override String get sort => 'Sortieren';
	@override String get sortBy => 'Sortieren nach';
	@override String get filters => 'Filter';
	@override String get confirmActionMessage => 'Aktion wirklich durchführen?';
	@override String get showLibrary => 'Mediathek anzeigen';
	@override String get hideLibrary => 'Mediathek ausblenden';
	@override String get libraryOptions => 'Mediatheksoptionen';
	@override String get content => 'Bibliotheksinhalt';
	@override String get selectLibrary => 'Bibliothek auswählen';
	@override String filtersWithCount({required Object count}) => 'Filter (${count})';
	@override String get noRecommendations => 'Keine Empfehlungen verfügbar';
	@override String get noCollections => 'Keine Sammlungen in dieser Mediathek';
	@override String get noFoldersFound => 'Keine Ordner gefunden';
	@override String get folders => 'Ordner';
	@override late final _StringsLibrariesTabsDe tabs = _StringsLibrariesTabsDe._(_root);
	@override late final _StringsLibrariesGroupingsDe groupings = _StringsLibrariesGroupingsDe._(_root);
}

// Path: about
class _StringsAboutDe implements _StringsAboutEn {
	_StringsAboutDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Über';
	@override String get openSourceLicenses => 'Open-Source-Lizenzen';
	@override String versionLabel({required Object version}) => 'Version ${version}';
	@override String get appDescription => 'Ein schöner Plex-Client für Flutter';
	@override String get viewLicensesDescription => 'Lizenzen von Drittanbieter-Bibliotheken anzeigen';
}

// Path: serverSelection
class _StringsServerSelectionDe implements _StringsServerSelectionEn {
	_StringsServerSelectionDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get allServerConnectionsFailed => 'Verbindung zu allen Servern fehlgeschlagen. Bitte Netzwerk prüfen und erneut versuchen.';
	@override String get noServersFound => 'Keine Server gefunden';
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Keine Server gefunden für ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Server konnten nicht geladen werden: ${error}';
}

// Path: hubDetail
class _StringsHubDetailDe implements _StringsHubDetailEn {
	_StringsHubDetailDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titel';
	@override String get releaseYear => 'Erscheinungsjahr';
	@override String get dateAdded => 'Hinzugefügt am';
	@override String get rating => 'Bewertung';
	@override String get noItemsFound => 'Keine Elemente gefunden';
}

// Path: logs
class _StringsLogsDe implements _StringsLogsEn {
	_StringsLogsDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Protokolle löschen';
	@override String get copyLogs => 'Protokolle kopieren';
	@override String get error => 'Fehler:';
	@override String get stackTrace => 'Stacktrace:';
}

// Path: licenses
class _StringsLicensesDe implements _StringsLicensesEn {
	_StringsLicensesDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Verwandte Pakete';
	@override String get license => 'Lizenz';
	@override String licenseNumber({required Object number}) => 'Lizenz ${number}';
	@override String licensesCount({required Object count}) => '${count} Lizenzen';
}

// Path: navigation
class _StringsNavigationDe implements _StringsNavigationEn {
	_StringsNavigationDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get home => 'Start';
	@override String get search => 'Suche';
	@override String get libraries => 'Mediatheken';
	@override String get settings => 'Einstellungen';
	@override String get downloads => 'Downloads';
}

// Path: downloads
class _StringsDownloadsDe implements _StringsDownloadsEn {
	_StringsDownloadsDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Downloads';
	@override String get manage => 'Verwalten';
	@override String get tvShows => 'Serien';
	@override String get movies => 'Filme';
	@override String get noDownloads => 'Noch keine Downloads';
	@override String get noDownloadsDescription => 'Heruntergeladene Inhalte werden hier für die Offline-Wiedergabe angezeigt';
	@override String get downloadNow => 'Herunterladen';
	@override String get deleteDownload => 'Download löschen';
	@override String get retryDownload => 'Download wiederholen';
	@override String get downloadQueued => 'Download in Warteschlange';
	@override String episodesQueued({required Object count}) => '${count} Episoden zum Download hinzugefügt';
	@override String get downloadDeleted => 'Download gelöscht';
	@override String deleteConfirm({required Object title}) => 'Möchtest du "${title}" wirklich löschen? Die heruntergeladene Datei wird von deinem Gerät entfernt.';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Lösche ${title}... (${current} von ${total})';
}

// Path: playlists
class _StringsPlaylistsDe implements _StringsPlaylistsEn {
	_StringsPlaylistsDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wiedergabelisten';
	@override String get noPlaylists => 'Keine Wiedergabelisten gefunden';
	@override String get create => 'Wiedergabeliste erstellen';
	@override String get playlistName => 'Name der Wiedergabeliste';
	@override String get enterPlaylistName => 'Name der Wiedergabeliste eingeben';
	@override String get delete => 'Wiedergabeliste löschen';
	@override String get removeItem => 'Aus Wiedergabeliste entfernen';
	@override String get smartPlaylist => 'Intelligente Wiedergabeliste';
	@override String itemCount({required Object count}) => '${count} Elemente';
	@override String get oneItem => '1 Element';
	@override String get emptyPlaylist => 'Diese Wiedergabeliste ist leer';
	@override String get deleteConfirm => 'Wiedergabeliste löschen?';
	@override String deleteMessage({required Object name}) => 'Soll "${name}" wirklich gelöscht werden?';
	@override String get created => 'Wiedergabeliste erstellt';
	@override String get deleted => 'Wiedergabeliste gelöscht';
	@override String get itemAdded => 'Zur Wiedergabeliste hinzugefügt';
	@override String get itemRemoved => 'Aus Wiedergabeliste entfernt';
	@override String get selectPlaylist => 'Wiedergabeliste auswählen';
	@override String get createNewPlaylist => 'Neue Wiedergabeliste erstellen';
	@override String get errorCreating => 'Wiedergabeliste konnte nicht erstellt werden';
	@override String get errorDeleting => 'Wiedergabeliste konnte nicht gelöscht werden';
	@override String get errorLoading => 'Wiedergabelisten konnten nicht geladen werden';
	@override String get errorAdding => 'Konnte nicht zur Wiedergabeliste hinzugefügt werden';
	@override String get errorReordering => 'Element der Wiedergabeliste konnte nicht neu geordnet werden';
	@override String get errorRemoving => 'Konnte nicht aus der Wiedergabeliste entfernt werden';
	@override String get playlist => 'Wiedergabeliste';
}

// Path: collections
class _StringsCollectionsDe implements _StringsCollectionsEn {
	_StringsCollectionsDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Sammlungen';
	@override String get collection => 'Sammlung';
	@override String get empty => 'Sammlung ist leer';
	@override String get unknownLibrarySection => 'Löschen nicht möglich: Unbekannte Bibliothekssektion';
	@override String get deleteCollection => 'Sammlung löschen';
	@override String deleteConfirm({required Object title}) => 'Sind Sie sicher, dass Sie "${title}" löschen möchten? Dies kann nicht rückgängig gemacht werden.';
	@override String get deleted => 'Sammlung gelöscht';
	@override String get deleteFailed => 'Sammlung konnte nicht gelöscht werden';
	@override String deleteFailedWithError({required Object error}) => 'Sammlung konnte nicht gelöscht werden: ${error}';
	@override String failedToLoadItems({required Object error}) => 'Sammlungselemente konnten nicht geladen werden: ${error}';
	@override String get selectCollection => 'Sammlung auswählen';
	@override String get createNewCollection => 'Neue Sammlung erstellen';
	@override String get collectionName => 'Sammlungsname';
	@override String get enterCollectionName => 'Sammlungsnamen eingeben';
	@override String get addedToCollection => 'Zur Sammlung hinzugefügt';
	@override String get errorAddingToCollection => 'Fehler beim Hinzufügen zur Sammlung';
	@override String get created => 'Sammlung erstellt';
	@override String get removeFromCollection => 'Aus Sammlung entfernen';
	@override String removeFromCollectionConfirm({required Object title}) => '"${title}" aus dieser Sammlung entfernen?';
	@override String get removedFromCollection => 'Aus Sammlung entfernt';
	@override String get removeFromCollectionFailed => 'Entfernen aus Sammlung fehlgeschlagen';
	@override String removeFromCollectionError({required Object error}) => 'Fehler beim Entfernen aus der Sammlung: ${error}';
}

// Path: watchTogether
class _StringsWatchTogetherDe implements _StringsWatchTogetherEn {
	_StringsWatchTogetherDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Gemeinsam Schauen';
	@override String get description => 'Inhalte synchron mit Freunden und Familie schauen';
	@override String get createSession => 'Sitzung Erstellen';
	@override String get creating => 'Erstellen...';
	@override String get joinSession => 'Sitzung Beitreten';
	@override String get joining => 'Beitreten...';
	@override String get controlMode => 'Steuerungsmodus';
	@override String get controlModeQuestion => 'Wer kann die Wiedergabe steuern?';
	@override String get hostOnly => 'Nur Host';
	@override String get anyone => 'Alle';
	@override String get hostingSession => 'Sitzung Hosten';
	@override String get inSession => 'In Sitzung';
	@override String get sessionCode => 'Sitzungscode';
	@override String get hostControlsPlayback => 'Host steuert die Wiedergabe';
	@override String get anyoneCanControl => 'Alle können die Wiedergabe steuern';
	@override String get hostControls => 'Host steuert';
	@override String get anyoneControls => 'Alle steuern';
	@override String get participants => 'Teilnehmer';
	@override String get host => 'Host';
	@override String get hostBadge => 'HOST';
	@override String get youAreHost => 'Du bist der Host';
	@override String get watchingWithOthers => 'Mit anderen schauen';
	@override String get endSession => 'Sitzung Beenden';
	@override String get leaveSession => 'Sitzung Verlassen';
	@override String get endSessionQuestion => 'Sitzung Beenden?';
	@override String get leaveSessionQuestion => 'Sitzung Verlassen?';
	@override String get endSessionConfirm => 'Dies beendet die Sitzung für alle Teilnehmer.';
	@override String get leaveSessionConfirm => 'Du wirst aus der Sitzung entfernt.';
	@override String get endSessionConfirmOverlay => 'Dies beendet die Schausitzung für alle Teilnehmer.';
	@override String get leaveSessionConfirmOverlay => 'Du wirst von der Schausitzung getrennt.';
	@override String get end => 'Beenden';
	@override String get leave => 'Verlassen';
	@override String get syncing => 'Synchronisieren...';
	@override String get participant => 'Teilnehmer';
	@override String get joinWatchSession => 'Schausitzung Beitreten';
	@override String get enterCodeHint => '8-stelligen Code eingeben';
	@override String get pasteFromClipboard => 'Aus Zwischenablage einfügen';
	@override String get pleaseEnterCode => 'Bitte gib einen Sitzungscode ein';
	@override String get codeMustBe8Chars => 'Sitzungscode muss 8 Zeichen haben';
	@override String get joinInstructions => 'Gib den vom Host geteilten Sitzungscode ein, um seiner Schausitzung beizutreten.';
	@override String get failedToCreate => 'Sitzung konnte nicht erstellt werden';
	@override String get failedToJoin => 'Sitzung konnte nicht beigetreten werden';
}

// Path: libraries.tabs
class _StringsLibrariesTabsDe implements _StringsLibrariesTabsEn {
	_StringsLibrariesTabsDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Empfohlen';
	@override String get browse => 'Durchsuchen';
	@override String get collections => 'Sammlungen';
	@override String get playlists => 'Wiedergabelisten';
}

// Path: libraries.groupings
class _StringsLibrariesGroupingsDe implements _StringsLibrariesGroupingsEn {
	_StringsLibrariesGroupingsDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get all => 'Alle';
	@override String get movies => 'Filme';
	@override String get shows => 'Serien';
	@override String get seasons => 'Staffeln';
	@override String get episodes => 'Episoden';
	@override String get folders => 'Ordner';
}

// Path: <root>
class _StringsIt implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	_StringsIt.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.it,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <it>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	@override late final _StringsIt _root = this; // ignore: unused_field

	// Translations
	@override late final _StringsAppIt app = _StringsAppIt._(_root);
	@override late final _StringsAuthIt auth = _StringsAuthIt._(_root);
	@override late final _StringsCommonIt common = _StringsCommonIt._(_root);
	@override late final _StringsScreensIt screens = _StringsScreensIt._(_root);
	@override late final _StringsUpdateIt update = _StringsUpdateIt._(_root);
	@override late final _StringsSettingsIt settings = _StringsSettingsIt._(_root);
	@override late final _StringsSearchIt search = _StringsSearchIt._(_root);
	@override late final _StringsHotkeysIt hotkeys = _StringsHotkeysIt._(_root);
	@override late final _StringsPinEntryIt pinEntry = _StringsPinEntryIt._(_root);
	@override late final _StringsFileInfoIt fileInfo = _StringsFileInfoIt._(_root);
	@override late final _StringsMediaMenuIt mediaMenu = _StringsMediaMenuIt._(_root);
	@override late final _StringsAccessibilityIt accessibility = _StringsAccessibilityIt._(_root);
	@override late final _StringsTooltipsIt tooltips = _StringsTooltipsIt._(_root);
	@override late final _StringsVideoControlsIt videoControls = _StringsVideoControlsIt._(_root);
	@override late final _StringsUserStatusIt userStatus = _StringsUserStatusIt._(_root);
	@override late final _StringsMessagesIt messages = _StringsMessagesIt._(_root);
	@override late final _StringsSubtitlingStylingIt subtitlingStyling = _StringsSubtitlingStylingIt._(_root);
	@override late final _StringsMpvConfigIt mpvConfig = _StringsMpvConfigIt._(_root);
	@override late final _StringsDialogIt dialog = _StringsDialogIt._(_root);
	@override late final _StringsDiscoverIt discover = _StringsDiscoverIt._(_root);
	@override late final _StringsErrorsIt errors = _StringsErrorsIt._(_root);
	@override late final _StringsLibrariesIt libraries = _StringsLibrariesIt._(_root);
	@override late final _StringsAboutIt about = _StringsAboutIt._(_root);
	@override late final _StringsServerSelectionIt serverSelection = _StringsServerSelectionIt._(_root);
	@override late final _StringsHubDetailIt hubDetail = _StringsHubDetailIt._(_root);
	@override late final _StringsLogsIt logs = _StringsLogsIt._(_root);
	@override late final _StringsLicensesIt licenses = _StringsLicensesIt._(_root);
	@override late final _StringsNavigationIt navigation = _StringsNavigationIt._(_root);
	@override late final _StringsDownloadsIt downloads = _StringsDownloadsIt._(_root);
	@override late final _StringsPlaylistsIt playlists = _StringsPlaylistsIt._(_root);
	@override late final _StringsCollectionsIt collections = _StringsCollectionsIt._(_root);
	@override late final _StringsWatchTogetherIt watchTogether = _StringsWatchTogetherIt._(_root);
}

// Path: app
class _StringsAppIt implements _StringsAppEn {
	_StringsAppIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
	@override String get loading => 'Caricamento...';
}

// Path: auth
class _StringsAuthIt implements _StringsAuthEn {
	_StringsAuthIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Accedi con Plex';
	@override String get showQRCode => 'Mostra QR Code';
	@override String get cancel => 'Cancella';
	@override String get authenticate => 'Autenticazione';
	@override String get retry => 'Riprova';
	@override String get debugEnterToken => 'Debug: Inserisci Token Plex';
	@override String get plexTokenLabel => 'Token Auth Plex';
	@override String get plexTokenHint => 'Inserisci il tuo token di Plex.tv';
	@override String get authenticationTimeout => 'Autenticazione scaduta. Riprova.';
	@override String get scanQRCodeInstruction => 'Scansiona questo QR code con un dispositivo connesso a Plex per autenticarti.';
	@override String get waitingForAuth => 'In attesa di autenticazione...\nCompleta l\'accesso dal tuo browser.';
}

// Path: common
class _StringsCommonIt implements _StringsCommonEn {
	_StringsCommonIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Cancella';
	@override String get save => 'Salva';
	@override String get close => 'Chiudi';
	@override String get clear => 'Pulisci';
	@override String get reset => 'Ripristina';
	@override String get later => 'Più tardi';
	@override String get submit => 'Invia';
	@override String get confirm => 'Conferma';
	@override String get retry => 'Riprova';
	@override String get logout => 'Disconnetti';
	@override String get unknown => 'Sconosciuto';
	@override String get refresh => 'Aggiorna';
	@override String get yes => 'Sì';
	@override String get no => 'No';
	@override String get delete => 'Elimina';
	@override String get shuffle => 'Casuale';
	@override String get addTo => 'Aggiungi a...';
}

// Path: screens
class _StringsScreensIt implements _StringsScreensEn {
	_StringsScreensIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licenze';
	@override String get selectServer => 'Seleziona server';
	@override String get switchProfile => 'Cambia profilo';
	@override String get subtitleStyling => 'Stile sottotitoli';
	@override String get mpvConfig => 'Configurazione MPV';
	@override String get search => 'Cerca';
	@override String get logs => 'Registro';
}

// Path: update
class _StringsUpdateIt implements _StringsUpdateEn {
	_StringsUpdateIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get available => 'Aggiornamento disponibile';
	@override String versionAvailable({required Object version}) => 'Versione ${version} disponibile';
	@override String currentVersion({required Object version}) => 'Corrente: ${version}';
	@override String get skipVersion => 'Salta questa versione';
	@override String get viewRelease => 'Visualizza dettagli release';
	@override String get latestVersion => 'La versione installata è l\'ultima disponibile';
	@override String get checkFailed => 'Impossibile controllare gli aggiornamenti';
}

// Path: settings
class _StringsSettingsIt implements _StringsSettingsEn {
	_StringsSettingsIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Impostazioni';
	@override String get language => 'Lingua';
	@override String get theme => 'Tema';
	@override String get appearance => 'Aspetto';
	@override String get videoPlayback => 'Riproduzione video';
	@override String get advanced => 'Avanzate';
	@override String get episodePosterMode => 'Stile poster episodio';
	@override String get seriesPoster => 'Poster della serie';
	@override String get seriesPosterDescription => 'Mostra il poster della serie per tutti gli episodi';
	@override String get seasonPoster => 'Poster della stagione';
	@override String get seasonPosterDescription => 'Mostra il poster specifico della stagione per gli episodi';
	@override String get episodeThumbnail => 'Miniatura episodio';
	@override String get episodeThumbnailDescription => 'Mostra miniature 16:9 degli episodi';
	@override String get showHeroSectionDescription => 'Visualizza il carosello dei contenuti in primo piano sulla schermata iniziale';
	@override String get secondsLabel => 'Secondi';
	@override String get minutesLabel => 'Minuti';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Inserisci durata (${min}-${max})';
	@override String get systemTheme => 'Sistema';
	@override String get systemThemeDescription => 'Segui le impostazioni di sistema';
	@override String get lightTheme => 'Chiaro';
	@override String get darkTheme => 'Scuro';
	@override String get libraryDensity => 'Densità libreria';
	@override String get compact => 'Compatta';
	@override String get compactDescription => 'Schede più piccole, più elementi visibili';
	@override String get normal => 'Normale';
	@override String get normalDescription => 'Dimensione predefinita';
	@override String get comfortable => 'Comoda';
	@override String get comfortableDescription => 'Schede più grandi, meno elementi visibili';
	@override String get viewMode => 'Modalità di visualizzazione';
	@override String get gridView => 'Griglia';
	@override String get gridViewDescription => 'Visualizza gli elementi in un layout a griglia';
	@override String get listView => 'Elenco';
	@override String get listViewDescription => 'Visualizza gli elementi in un layout a elenco';
	@override String get showHeroSection => 'Mostra sezione principale';
	@override String get useGlobalHubs => 'Usa layout Home di Plex';
	@override String get useGlobalHubsDescription => 'Mostra gli hub della home page come il client Plex ufficiale. Se disattivato, mostra invece i suggerimenti per libreria.';
	@override String get hardwareDecoding => 'Decodifica Hardware';
	@override String get hardwareDecodingDescription => 'Utilizza l\'accelerazione hardware quando disponibile';
	@override String get bufferSize => 'Dimensione buffer';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get subtitleStyling => 'Stile sottotitoli';
	@override String get subtitleStylingDescription => 'Personalizza l\'aspetto dei sottotitoli';
	@override String get smallSkipDuration => 'Durata skip breve';
	@override String get largeSkipDuration => 'Durata skip lungo';
	@override String secondsUnit({required Object seconds}) => '${seconds} secondi';
	@override String get defaultSleepTimer => 'Timer spegnimento predefinito';
	@override String minutesUnit({required Object minutes}) => '${minutes} minuti';
	@override String get rememberTrackSelections => 'Ricorda selezioni tracce per serie/film';
	@override String get rememberTrackSelectionsDescription => 'Salva automaticamente le preferenze delle lingue audio e sottotitoli quando cambi tracce durante la riproduzione';
	@override String get videoPlayerControls => 'Controlli del lettore video';
	@override String get keyboardShortcuts => 'Scorciatoie da tastiera';
	@override String get keyboardShortcutsDescription => 'Personalizza le scorciatoie da tastiera';
	@override String get videoPlayerNavigation => 'Navigazione del lettore video';
	@override String get videoPlayerNavigationDescription => 'Usa i tasti freccia per navigare nei controlli del lettore video';
	@override String get debugLogging => 'Log di debug';
	@override String get debugLoggingDescription => 'Abilita il logging dettagliato per la risoluzione dei problemi';
	@override String get viewLogs => 'Visualizza log';
	@override String get viewLogsDescription => 'Visualizza i log dell\'applicazione';
	@override String get clearCache => 'Svuota cache';
	@override String get clearCacheDescription => 'Questa opzione cancellerà tutte le immagini e i dati memorizzati nella cache. Dopo aver cancellato la cache, l\'app potrebbe impiegare più tempo per caricare i contenuti.';
	@override String get clearCacheSuccess => 'Cache cancellata correttamente';
	@override String get resetSettings => 'Ripristina impostazioni';
	@override String get resetSettingsDescription => 'Questa opzione ripristinerà tutte le impostazioni ai valori predefiniti. Non può essere annullata.';
	@override String get resetSettingsSuccess => 'Impostazioni ripristinate correttamente';
	@override String get shortcutsReset => 'Scorciatoie ripristinate alle impostazioni predefinite';
	@override String get about => 'Informazioni';
	@override String get aboutDescription => 'Informazioni sull\'app e le licenze';
	@override String get updates => 'Aggiornamenti';
	@override String get updateAvailable => 'Aggiornamento disponibile';
	@override String get checkForUpdates => 'Controlla aggiornamenti';
	@override String get validationErrorEnterNumber => 'Inserisci un numero valido';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'la durata deve essere compresa tra ${min} e ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Scorciatoia già assegnata a ${action}';
	@override String shortcutUpdated({required Object action}) => 'Scorciatoia aggiornata per ${action}';
	@override String get autoSkip => 'Salto Automatico';
	@override String get autoSkipIntro => 'Salta Intro Automaticamente';
	@override String get autoSkipIntroDescription => 'Salta automaticamente i marcatori dell\'intro dopo alcuni secondi';
	@override String get autoSkipCredits => 'Salta Crediti Automaticamente';
	@override String get autoSkipCreditsDescription => 'Salta automaticamente i crediti e riproduci l\'episodio successivo';
	@override String get autoSkipDelay => 'Ritardo Salto Automatico';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Aspetta ${seconds} secondi prima del salto automatico';
	@override String get downloads => 'Download';
	@override String get downloadLocationDescription => 'Scegli dove salvare i contenuti scaricati';
	@override String get downloadLocationDefault => 'Predefinita (Archiviazione App)';
	@override String get downloadLocationCustom => 'Posizione Personalizzata';
	@override String get selectFolder => 'Seleziona Cartella';
	@override String get resetToDefault => 'Ripristina Predefinita';
	@override String currentPath({required Object path}) => 'Corrente: ${path}';
	@override String get downloadLocationChanged => 'Posizione di download modificata';
	@override String get downloadLocationReset => 'Posizione di download ripristinata a predefinita';
	@override String get downloadLocationInvalid => 'La cartella selezionata non è scrivibile';
	@override String get downloadLocationSelectError => 'Impossibile selezionare la cartella';
	@override String get downloadOnWifiOnly => 'Scarica solo con WiFi';
	@override String get downloadOnWifiOnlyDescription => 'Impedisci i download quando si utilizza la rete dati cellulare';
	@override String get cellularDownloadBlocked => 'I download sono disabilitati sulla rete dati cellulare. Connettiti al WiFi o modifica l\'impostazione.';
	@override String get maxVolume => 'Volume massimo';
	@override String get maxVolumeDescription => 'Consenti volume superiore al 100% per contenuti audio bassi';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get maxVolumeHint => 'Inserisci volume massimo (100-300)';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Mostra su Discord cosa stai guardando';
}

// Path: search
class _StringsSearchIt implements _StringsSearchEn {
	_StringsSearchIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Cerca film. spettacoli, musica...';
	@override String get tryDifferentTerm => 'Prova altri termini di ricerca';
	@override String get searchYourMedia => 'Cerca nei tuoi media';
	@override String get enterTitleActorOrKeyword => 'Inserisci un titolo, attore o parola chiave';
}

// Path: hotkeys
class _StringsHotkeysIt implements _StringsHotkeysEn {
	_StringsHotkeysIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Imposta scorciatoia per ${actionName}';
	@override String get clearShortcut => 'Elimina scorciatoia';
}

// Path: pinEntry
class _StringsPinEntryIt implements _StringsPinEntryEn {
	_StringsPinEntryIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get enterPin => 'Inserisci PIN';
	@override String get showPin => 'Mostra PIN';
	@override String get hidePin => 'Nascondi PIN';
}

// Path: fileInfo
class _StringsFileInfoIt implements _StringsFileInfoEn {
	_StringsFileInfoIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Info sul file';
	@override String get video => 'Video';
	@override String get audio => 'Audio';
	@override String get file => 'File';
	@override String get advanced => 'Avanzate';
	@override String get codec => 'Codec';
	@override String get resolution => 'Risoluzione';
	@override String get bitrate => 'Bitrate';
	@override String get frameRate => 'Frame Rate';
	@override String get aspectRatio => 'Aspect Ratio';
	@override String get profile => 'Profilo';
	@override String get bitDepth => 'Profondità colore';
	@override String get colorSpace => 'Spazio colore';
	@override String get colorRange => 'Gamma colori';
	@override String get colorPrimaries => 'Colori primari';
	@override String get chromaSubsampling => 'Sottocampionamento cromatico';
	@override String get channels => 'Canali';
	@override String get path => 'Percorso';
	@override String get size => 'Dimensione';
	@override String get container => 'Contenitore';
	@override String get duration => 'Durata';
	@override String get optimizedForStreaming => 'Ottimizzato per lo streaming';
	@override String get has64bitOffsets => 'Offset a 64-bit';
}

// Path: mediaMenu
class _StringsMediaMenuIt implements _StringsMediaMenuEn {
	_StringsMediaMenuIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Segna come visto';
	@override String get markAsUnwatched => 'Segna come non visto';
	@override String get removeFromContinueWatching => 'Rimuovi da Continua a guardare';
	@override String get goToSeries => 'Vai alle serie';
	@override String get goToSeason => 'Vai alla stagione';
	@override String get shufflePlay => 'Riproduzione casuale';
	@override String get fileInfo => 'Info sul file';
}

// Path: accessibility
class _StringsAccessibilityIt implements _StringsAccessibilityEn {
	_StringsAccessibilityIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, film';
	@override String mediaCardShow({required Object title}) => '${title}, serie TV';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'visto';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} percento visto';
	@override String get mediaCardUnwatched => 'non visto';
	@override String get tapToPlay => 'Tocca per riprodurre';
}

// Path: tooltips
class _StringsTooltipsIt implements _StringsTooltipsEn {
	_StringsTooltipsIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Riproduzione casuale';
	@override String get markAsWatched => 'Segna come visto';
	@override String get markAsUnwatched => 'Segna come non visto';
}

// Path: videoControls
class _StringsVideoControlsIt implements _StringsVideoControlsEn {
	_StringsVideoControlsIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Audio';
	@override String get subtitlesLabel => 'Sottotitoli';
	@override String get resetToZero => 'Riporta a 0ms';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} riprodotto dopo';
	@override String playsEarlier({required Object label}) => '${label} riprodotto prima';
	@override String get noOffset => 'Nessun offset';
	@override String get letterbox => 'Letterbox';
	@override String get fillScreen => 'Riempi schermo';
	@override String get stretch => 'Allunga';
	@override String get lockRotation => 'Blocca rotazione';
	@override String get unlockRotation => 'Sblocca rotazione';
	@override String get sleepTimer => 'Timer di spegnimento';
	@override String get timerActive => 'Timer attivo';
	@override String playbackWillPauseIn({required Object duration}) => 'La riproduzione si interromperà tra ${duration}';
	@override String get sleepTimerCompleted => 'Timer di spegnimento completato - riproduzione in pausa';
	@override String get playButton => 'Riproduci';
	@override String get pauseButton => 'Pausa';
	@override String seekBackwardButton({required Object seconds}) => 'Riavvolgi di ${seconds} secondi';
	@override String seekForwardButton({required Object seconds}) => 'Avanza di ${seconds} secondi';
	@override String get previousButton => 'Episodio precedente';
	@override String get nextButton => 'Episodio successivo';
	@override String get previousChapterButton => 'Capitolo precedente';
	@override String get nextChapterButton => 'Capitolo successivo';
	@override String get muteButton => 'Silenzia';
	@override String get unmuteButton => 'Riattiva audio';
	@override String get settingsButton => 'Impostazioni video';
	@override String get audioTrackButton => 'Tracce audio';
	@override String get subtitlesButton => 'Sottotitoli';
	@override String get chaptersButton => 'Capitoli';
	@override String get versionsButton => 'Versioni video';
	@override String get pipButton => 'Modalità Picture-in-Picture';
	@override String get aspectRatioButton => 'Proporzioni';
	@override String get fullscreenButton => 'Attiva schermo intero';
	@override String get exitFullscreenButton => 'Esci da schermo intero';
	@override String get alwaysOnTopButton => 'Sempre in primo piano';
	@override String get rotationLockButton => 'Blocco rotazione';
	@override String get timelineSlider => 'Timeline video';
	@override String get volumeSlider => 'Livello volume';
	@override String get backButton => 'Indietro';
}

// Path: userStatus
class _StringsUserStatusIt implements _StringsUserStatusEn {
	_StringsUserStatusIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Admin';
	@override String get restricted => 'Limitato';
	@override String get protected => 'Protetto';
	@override String get current => 'ATTUALE';
}

// Path: messages
class _StringsMessagesIt implements _StringsMessagesEn {
	_StringsMessagesIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Segna come visto';
	@override String get markedAsUnwatched => 'Segna come non visto';
	@override String get markedAsWatchedOffline => 'Segnato come visto (sincronizzato online)';
	@override String get markedAsUnwatchedOffline => 'Segnato come non visto (sincronizzato online)';
	@override String get removedFromContinueWatching => 'Rimosso da Continua a guardare';
	@override String errorLoading({required Object error}) => 'Errore: ${error}';
	@override String get fileInfoNotAvailable => 'Informazioni sul file non disponibili';
	@override String errorLoadingFileInfo({required Object error}) => 'Errore caricamento informazioni sul file: ${error}';
	@override String get errorLoadingSeries => 'Errore caricamento serie';
	@override String get errorLoadingSeason => 'Errore caricamento stagione';
	@override String get musicNotSupported => 'La riproduzione musicale non è ancora supportata';
	@override String get logsCleared => 'Log eliminati';
	@override String get logsCopied => 'Log copiati negli appunti';
	@override String get noLogsAvailable => 'Nessun log disponibile';
	@override String libraryScanning({required Object title}) => 'Scansione "${title}"...';
	@override String libraryScanStarted({required Object title}) => 'Scansione libreria iniziata per "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Impossibile eseguire scansione della libreria: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Aggiornamento metadati per "${title}"...';
	@override String metadataRefreshStarted({required Object title}) => 'Aggiornamento metadati per "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Errore aggiornamento metadati: ${error}';
	@override String get logoutConfirm => 'Sei sicuro di volerti disconnettere?';
	@override String get noSeasonsFound => 'Nessuna stagione trovata';
	@override String get noEpisodesFound => 'Nessun episodio trovato nella prima stagione';
	@override String get noEpisodesFoundGeneral => 'Nessun episodio trovato';
	@override String get noResultsFound => 'Nessun risultato';
	@override String sleepTimerSet({required Object label}) => 'Imposta timer spegnimento per ${label}';
	@override String get noItemsAvailable => 'Nessun elemento disponibile';
	@override String get failedToCreatePlayQueue => 'Impossibile creare la coda di riproduzione';
	@override String get failedToCreatePlayQueueNoItems => 'Impossibile creare la coda di riproduzione - nessun elemento';
	@override String failedPlayback({required Object action, required Object error}) => 'Impossibile ${action}: ${error}';
}

// Path: subtitlingStyling
class _StringsSubtitlingStylingIt implements _StringsSubtitlingStylingEn {
	_StringsSubtitlingStylingIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get stylingOptions => 'Opzioni stile';
	@override String get fontSize => 'Dimensione';
	@override String get textColor => 'Colore testo';
	@override String get borderSize => 'Dimensione bordo';
	@override String get borderColor => 'Colore bordo';
	@override String get backgroundOpacity => 'Opacità sfondo';
	@override String get backgroundColor => 'Colore sfondo';
}

// Path: mpvConfig
class _StringsMpvConfigIt implements _StringsMpvConfigEn {
	_StringsMpvConfigIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Configurazione MPV';
	@override String get description => 'Impostazioni avanzate del lettore video';
	@override String get properties => 'Proprietà';
	@override String get presets => 'Preset';
	@override String get noProperties => 'Nessuna proprietà configurata';
	@override String get noPresets => 'Nessun preset salvato';
	@override String get addProperty => 'Aggiungi proprietà';
	@override String get editProperty => 'Modifica proprietà';
	@override String get deleteProperty => 'Elimina proprietà';
	@override String get propertyKey => 'Chiave proprietà';
	@override String get propertyKeyHint => 'es. hwdec, demuxer-max-bytes';
	@override String get propertyValue => 'Valore proprietà';
	@override String get propertyValueHint => 'es. auto, 256000000';
	@override String get saveAsPreset => 'Salva come preset...';
	@override String get presetName => 'Nome preset';
	@override String get presetNameHint => 'Inserisci un nome per questo preset';
	@override String get loadPreset => 'Carica';
	@override String get deletePreset => 'Elimina';
	@override String get presetSaved => 'Preset salvato';
	@override String get presetLoaded => 'Preset caricato';
	@override String get presetDeleted => 'Preset eliminato';
	@override String get confirmDeletePreset => 'Sei sicuro di voler eliminare questo preset?';
	@override String get confirmDeleteProperty => 'Sei sicuro di voler eliminare questa proprietà?';
	@override String entriesCount({required Object count}) => '${count} voci';
}

// Path: dialog
class _StringsDialogIt implements _StringsDialogEn {
	_StringsDialogIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Conferma azione';
	@override String get cancel => 'Cancella';
	@override String get playNow => 'Riproduci ora';
}

// Path: discover
class _StringsDiscoverIt implements _StringsDiscoverEn {
	_StringsDiscoverIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Esplora';
	@override String get switchProfile => 'Cambia profilo';
	@override String get switchServer => 'Cambia server';
	@override String get logout => 'Disconnetti';
	@override String get noContentAvailable => 'Nessun contenuto disponibile';
	@override String get addMediaToLibraries => 'Aggiungi alcuni file multimediali alle tue librerie';
	@override String get continueWatching => 'Continua a guardare';
	@override String get play => 'Riproduci';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get pause => 'Pausa';
	@override String get overview => 'Panoramica';
	@override String get cast => 'Attori';
	@override String get seasons => 'Stagioni';
	@override String get studio => 'Studio';
	@override String get rating => 'Classificazione';
	@override String get watched => 'Guardato';
	@override String episodeCount({required Object count}) => '${count} episodi';
	@override String watchedProgress({required Object watched, required Object total}) => '${watched}/${total} guardati';
	@override String get movie => 'Film';
	@override String get tvShow => 'Serie TV';
	@override String minutesLeft({required Object minutes}) => '${minutes} minuti rimanenti';
}

// Path: errors
class _StringsErrorsIt implements _StringsErrorsEn {
	_StringsErrorsIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Ricerca fallita: ${error}';
	@override String connectionTimeout({required Object context}) => 'Timeout connessione durante caricamento di ${context}';
	@override String get connectionFailed => 'Impossibile connettersi al server Plex.';
	@override String failedToLoad({required Object context, required Object error}) => 'Impossibile caricare ${context}: ${error}';
	@override String get noClientAvailable => 'Nessun client disponibile';
	@override String authenticationFailed({required Object error}) => 'Autenticazione fallita: ${error}';
	@override String get couldNotLaunchUrl => 'Impossibile avviare URL di autenticazione';
	@override String get pleaseEnterToken => 'Inserisci token';
	@override String get invalidToken => 'Token non valido';
	@override String failedToVerifyToken({required Object error}) => 'Verifica token fallita: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Impossibile passare a ${displayName}';
}

// Path: libraries
class _StringsLibrariesIt implements _StringsLibrariesEn {
	_StringsLibrariesIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Librerie';
	@override String get scanLibraryFiles => 'Scansiona file libreria';
	@override String get scanLibrary => 'Scansiona libreria';
	@override String get analyze => 'Analizza';
	@override String get analyzeLibrary => 'Analizza libreria';
	@override String get refreshMetadata => 'Aggiorna metadati';
	@override String get emptyTrash => 'Svuota cestino';
	@override String emptyingTrash({required Object title}) => 'Svuotamento cestino per "${title}"...';
	@override String trashEmptied({required Object title}) => 'Cestino svuotato per "${title}"';
	@override String failedToEmptyTrash({required Object error}) => 'Impossibile svuotare cestino: ${error}';
	@override String analyzing({required Object title}) => 'Analisi "${title}"...';
	@override String analysisStarted({required Object title}) => 'Analisi iniziata per "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Impossibile analizzare libreria: ${error}';
	@override String get noLibrariesFound => 'Nessuna libreria trovata';
	@override String get thisLibraryIsEmpty => 'Questa libreria è vuota';
	@override String get all => 'Tutto';
	@override String get clearAll => 'Cancella tutto';
	@override String scanLibraryConfirm({required Object title}) => 'Sei sicuro di voler scansionare "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Sei sicuro di voler analizzare "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => 'Sei sicuro di voler aggiornare i metadati per "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Sei sicuro di voler svuotare il cestino per "${title}"?';
	@override String get manageLibraries => 'Gestisci librerie';
	@override String get sort => 'Ordina';
	@override String get sortBy => 'Ordina per';
	@override String get filters => 'Filtri';
	@override String get confirmActionMessage => 'Sei sicuro di voler eseguire questa azione?';
	@override String get showLibrary => 'Mostra libreria';
	@override String get hideLibrary => 'Nascondi libreria';
	@override String get libraryOptions => 'Opzioni libreria';
	@override String get content => 'contenuto della libreria';
	@override String get selectLibrary => 'Seleziona libreria';
	@override String filtersWithCount({required Object count}) => 'Filtri (${count})';
	@override String get noRecommendations => 'Nessun consiglio disponibile';
	@override String get noCollections => 'Nessuna raccolta in questa libreria';
	@override String get noFoldersFound => 'Nessuna cartella trovata';
	@override String get folders => 'cartelle';
	@override late final _StringsLibrariesTabsIt tabs = _StringsLibrariesTabsIt._(_root);
	@override late final _StringsLibrariesGroupingsIt groupings = _StringsLibrariesGroupingsIt._(_root);
}

// Path: about
class _StringsAboutIt implements _StringsAboutEn {
	_StringsAboutIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Informazioni';
	@override String get openSourceLicenses => 'Licenze Open Source';
	@override String versionLabel({required Object version}) => 'Versione ${version}';
	@override String get appDescription => 'Un bellissimo client Plex per Flutter';
	@override String get viewLicensesDescription => 'Visualizza le licenze delle librerie di terze parti';
}

// Path: serverSelection
class _StringsServerSelectionIt implements _StringsServerSelectionEn {
	_StringsServerSelectionIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get allServerConnectionsFailed => 'Impossibile connettersi a nessun server. Controlla la tua rete e riprova.';
	@override String get noServersFound => 'Nessun server trovato';
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Nessun server trovato per ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Impossibile caricare i server: ${error}';
}

// Path: hubDetail
class _StringsHubDetailIt implements _StringsHubDetailEn {
	_StringsHubDetailIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titolo';
	@override String get releaseYear => 'Anno rilascio';
	@override String get dateAdded => 'Data aggiunta';
	@override String get rating => 'Valutazione';
	@override String get noItemsFound => 'Nessun elemento trovato';
}

// Path: logs
class _StringsLogsIt implements _StringsLogsEn {
	_StringsLogsIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Cancella log';
	@override String get copyLogs => 'Copia log';
	@override String get error => 'Errore:';
	@override String get stackTrace => 'Traccia dello stack:';
}

// Path: licenses
class _StringsLicensesIt implements _StringsLicensesEn {
	_StringsLicensesIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Pacchetti correlati';
	@override String get license => 'Licenza';
	@override String licenseNumber({required Object number}) => 'Licenza ${number}';
	@override String licensesCount({required Object count}) => '${count} licenze';
}

// Path: navigation
class _StringsNavigationIt implements _StringsNavigationEn {
	_StringsNavigationIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get home => 'Home';
	@override String get search => 'Cerca';
	@override String get libraries => 'Librerie';
	@override String get settings => 'Impostazioni';
	@override String get downloads => 'Download';
}

// Path: downloads
class _StringsDownloadsIt implements _StringsDownloadsEn {
	_StringsDownloadsIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Download';
	@override String get manage => 'Gestisci';
	@override String get tvShows => 'Serie TV';
	@override String get movies => 'Film';
	@override String get noDownloads => 'Nessun download';
	@override String get noDownloadsDescription => 'I contenuti scaricati appariranno qui per la visualizzazione offline';
	@override String get downloadNow => 'Scarica';
	@override String get deleteDownload => 'Elimina download';
	@override String get retryDownload => 'Riprova download';
	@override String get downloadQueued => 'Download in coda';
	@override String episodesQueued({required Object count}) => '${count} episodi in coda per il download';
	@override String get downloadDeleted => 'Download eliminato';
	@override String deleteConfirm({required Object title}) => 'Sei sicuro di voler eliminare "${title}"? Il file scaricato verrà rimosso dal tuo dispositivo.';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Eliminazione di ${title}... (${current} di ${total})';
}

// Path: playlists
class _StringsPlaylistsIt implements _StringsPlaylistsEn {
	_StringsPlaylistsIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Playlist';
	@override String get noPlaylists => 'Nessuna playlist trovata';
	@override String get create => 'Crea playlist';
	@override String get playlistName => 'Nome playlist';
	@override String get enterPlaylistName => 'Inserisci nome playlist';
	@override String get delete => 'Elimina playlist';
	@override String get removeItem => 'Rimuovi da playlist';
	@override String get smartPlaylist => 'Playlist intelligente';
	@override String itemCount({required Object count}) => '${count} elementi';
	@override String get oneItem => '1 elemento';
	@override String get emptyPlaylist => 'Questa playlist è vuota';
	@override String get deleteConfirm => 'Eliminare playlist?';
	@override String deleteMessage({required Object name}) => 'Sei sicuro di voler eliminare "${name}"?';
	@override String get created => 'Playlist creata';
	@override String get deleted => 'Playlist eliminata';
	@override String get itemAdded => 'Aggiunto alla playlist';
	@override String get itemRemoved => 'Rimosso dalla playlist';
	@override String get selectPlaylist => 'Seleziona playlist';
	@override String get createNewPlaylist => 'Crea nuova playlist';
	@override String get errorCreating => 'Errore durante la creazione della playlist';
	@override String get errorDeleting => 'Errore durante l\'eliminazione della playlist';
	@override String get errorLoading => 'Errore durante il caricamento delle playlist';
	@override String get errorAdding => 'Errore durante l\'aggiunta alla playlist';
	@override String get errorReordering => 'Errore durante il riordino dell\'elemento della playlist';
	@override String get errorRemoving => 'Errore durante la rimozione dalla playlist';
	@override String get playlist => 'Playlist';
}

// Path: collections
class _StringsCollectionsIt implements _StringsCollectionsEn {
	_StringsCollectionsIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Raccolte';
	@override String get collection => 'Raccolta';
	@override String get empty => 'La raccolta è vuota';
	@override String get unknownLibrarySection => 'Impossibile eliminare: sezione libreria sconosciuta';
	@override String get deleteCollection => 'Elimina raccolta';
	@override String deleteConfirm({required Object title}) => 'Sei sicuro di voler eliminare "${title}"? Questa azione non può essere annullata.';
	@override String get deleted => 'Raccolta eliminata';
	@override String get deleteFailed => 'Impossibile eliminare la raccolta';
	@override String deleteFailedWithError({required Object error}) => 'Impossibile eliminare la raccolta: ${error}';
	@override String failedToLoadItems({required Object error}) => 'Impossibile caricare gli elementi della raccolta: ${error}';
	@override String get selectCollection => 'Seleziona raccolta';
	@override String get createNewCollection => 'Crea nuova raccolta';
	@override String get collectionName => 'Nome raccolta';
	@override String get enterCollectionName => 'Inserisci nome raccolta';
	@override String get addedToCollection => 'Aggiunto alla raccolta';
	@override String get errorAddingToCollection => 'Errore nell\'aggiunta alla raccolta';
	@override String get created => 'Raccolta creata';
	@override String get removeFromCollection => 'Rimuovi dalla raccolta';
	@override String removeFromCollectionConfirm({required Object title}) => 'Rimuovere "${title}" da questa raccolta?';
	@override String get removedFromCollection => 'Rimosso dalla raccolta';
	@override String get removeFromCollectionFailed => 'Impossibile rimuovere dalla raccolta';
	@override String removeFromCollectionError({required Object error}) => 'Errore durante la rimozione dalla raccolta: ${error}';
}

// Path: watchTogether
class _StringsWatchTogetherIt implements _StringsWatchTogetherEn {
	_StringsWatchTogetherIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Guarda Insieme';
	@override String get description => 'Guarda contenuti in sincronia con amici e familiari';
	@override String get createSession => 'Crea Sessione';
	@override String get creating => 'Creazione...';
	@override String get joinSession => 'Unisciti alla Sessione';
	@override String get joining => 'Connessione...';
	@override String get controlMode => 'Modalità di Controllo';
	@override String get controlModeQuestion => 'Chi può controllare la riproduzione?';
	@override String get hostOnly => 'Solo Host';
	@override String get anyone => 'Tutti';
	@override String get hostingSession => 'Hosting Sessione';
	@override String get inSession => 'In Sessione';
	@override String get sessionCode => 'Codice Sessione';
	@override String get hostControlsPlayback => 'L\'host controlla la riproduzione';
	@override String get anyoneCanControl => 'Tutti possono controllare la riproduzione';
	@override String get hostControls => 'Controllo host';
	@override String get anyoneControls => 'Controllo di tutti';
	@override String get participants => 'Partecipanti';
	@override String get host => 'Host';
	@override String get hostBadge => 'HOST';
	@override String get youAreHost => 'Sei l\'host';
	@override String get watchingWithOthers => 'Guardando con altri';
	@override String get endSession => 'Termina Sessione';
	@override String get leaveSession => 'Lascia Sessione';
	@override String get endSessionQuestion => 'Terminare la Sessione?';
	@override String get leaveSessionQuestion => 'Lasciare la Sessione?';
	@override String get endSessionConfirm => 'Questo terminerà la sessione per tutti i partecipanti.';
	@override String get leaveSessionConfirm => 'Sarai rimosso dalla sessione.';
	@override String get endSessionConfirmOverlay => 'Questo terminerà la sessione di visione per tutti i partecipanti.';
	@override String get leaveSessionConfirmOverlay => 'Sarai disconnesso dalla sessione di visione.';
	@override String get end => 'Termina';
	@override String get leave => 'Lascia';
	@override String get syncing => 'Sincronizzazione...';
	@override String get participant => 'partecipante';
	@override String get joinWatchSession => 'Unisciti alla Sessione di Visione';
	@override String get enterCodeHint => 'Inserisci codice di 8 caratteri';
	@override String get pasteFromClipboard => 'Incolla dagli appunti';
	@override String get pleaseEnterCode => 'Inserisci un codice sessione';
	@override String get codeMustBe8Chars => 'Il codice sessione deve essere di 8 caratteri';
	@override String get joinInstructions => 'Inserisci il codice sessione condiviso dall\'host per unirti alla loro sessione di visione.';
	@override String get failedToCreate => 'Impossibile creare la sessione';
	@override String get failedToJoin => 'Impossibile unirsi alla sessione';
}

// Path: libraries.tabs
class _StringsLibrariesTabsIt implements _StringsLibrariesTabsEn {
	_StringsLibrariesTabsIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Consigliati';
	@override String get browse => 'Esplora';
	@override String get collections => 'Raccolte';
	@override String get playlists => 'Playlist';
}

// Path: libraries.groupings
class _StringsLibrariesGroupingsIt implements _StringsLibrariesGroupingsEn {
	_StringsLibrariesGroupingsIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get all => 'Tutti';
	@override String get movies => 'Film';
	@override String get shows => 'Serie TV';
	@override String get seasons => 'Stagioni';
	@override String get episodes => 'Episodi';
	@override String get folders => 'Cartelle';
}

// Path: <root>
class _StringsKo implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	_StringsKo.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.ko,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ko>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	@override late final _StringsKo _root = this; // ignore: unused_field

	// Translations
	@override late final _StringsAppKo app = _StringsAppKo._(_root);
	@override late final _StringsAuthKo auth = _StringsAuthKo._(_root);
	@override late final _StringsCommonKo common = _StringsCommonKo._(_root);
	@override late final _StringsScreensKo screens = _StringsScreensKo._(_root);
	@override late final _StringsUpdateKo update = _StringsUpdateKo._(_root);
	@override late final _StringsSettingsKo settings = _StringsSettingsKo._(_root);
	@override late final _StringsSearchKo search = _StringsSearchKo._(_root);
	@override late final _StringsHotkeysKo hotkeys = _StringsHotkeysKo._(_root);
	@override late final _StringsPinEntryKo pinEntry = _StringsPinEntryKo._(_root);
	@override late final _StringsFileInfoKo fileInfo = _StringsFileInfoKo._(_root);
	@override late final _StringsMediaMenuKo mediaMenu = _StringsMediaMenuKo._(_root);
	@override late final _StringsAccessibilityKo accessibility = _StringsAccessibilityKo._(_root);
	@override late final _StringsTooltipsKo tooltips = _StringsTooltipsKo._(_root);
	@override late final _StringsVideoControlsKo videoControls = _StringsVideoControlsKo._(_root);
	@override late final _StringsUserStatusKo userStatus = _StringsUserStatusKo._(_root);
	@override late final _StringsMessagesKo messages = _StringsMessagesKo._(_root);
	@override late final _StringsSubtitlingStylingKo subtitlingStyling = _StringsSubtitlingStylingKo._(_root);
	@override late final _StringsMpvConfigKo mpvConfig = _StringsMpvConfigKo._(_root);
	@override late final _StringsDialogKo dialog = _StringsDialogKo._(_root);
	@override late final _StringsDiscoverKo discover = _StringsDiscoverKo._(_root);
	@override late final _StringsErrorsKo errors = _StringsErrorsKo._(_root);
	@override late final _StringsLibrariesKo libraries = _StringsLibrariesKo._(_root);
	@override late final _StringsAboutKo about = _StringsAboutKo._(_root);
	@override late final _StringsServerSelectionKo serverSelection = _StringsServerSelectionKo._(_root);
	@override late final _StringsHubDetailKo hubDetail = _StringsHubDetailKo._(_root);
	@override late final _StringsLogsKo logs = _StringsLogsKo._(_root);
	@override late final _StringsLicensesKo licenses = _StringsLicensesKo._(_root);
	@override late final _StringsNavigationKo navigation = _StringsNavigationKo._(_root);
	@override late final _StringsCollectionsKo collections = _StringsCollectionsKo._(_root);
	@override late final _StringsPlaylistsKo playlists = _StringsPlaylistsKo._(_root);
	@override late final _StringsWatchTogetherKo watchTogether = _StringsWatchTogetherKo._(_root);
	@override late final _StringsDownloadsKo downloads = _StringsDownloadsKo._(_root);
}

// Path: app
class _StringsAppKo implements _StringsAppEn {
	_StringsAppKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
	@override String get loading => '로딩 중...';
}

// Path: auth
class _StringsAuthKo implements _StringsAuthEn {
	_StringsAuthKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Plex 계정으로 로그인';
	@override String get showQRCode => 'QR 코드';
	@override String get cancel => '취소';
	@override String get authenticate => '인증';
	@override String get retry => '재시도';
	@override String get debugEnterToken => '디버깅을 위해 Plex 토큰을 입력하세요.';
	@override String get plexTokenLabel => 'Plex 인증 토큰';
	@override String get plexTokenHint => 'Plex.tv 토큰을 입력하세요';
	@override String get authenticationTimeout => '인증 시간이 초과되었습니다. 다시 시도해 주세요.';
	@override String get scanQRCodeInstruction => 'Plex 계정에 로그인된 기기에서 이 QR 코드를 스캔하여 본인 인증을 해주세요.';
	@override String get waitingForAuth => '인증 대기 중... 브라우저에서 로그인을 완료해 주세요.';
}

// Path: common
class _StringsCommonKo implements _StringsCommonEn {
	_StringsCommonKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get cancel => '취소';
	@override String get save => '저장';
	@override String get close => '닫기';
	@override String get clear => '지우기';
	@override String get reset => '초기화';
	@override String get later => '나중에';
	@override String get submit => '보내기';
	@override String get confirm => '확인';
	@override String get retry => '재시도';
	@override String get logout => '로그아웃';
	@override String get unknown => '알 수 없는';
	@override String get refresh => '새로고침';
	@override String get yes => '예';
	@override String get no => '아니오';
	@override String get delete => '삭제';
	@override String get shuffle => '무작위 재생';
	@override String get addTo => '추가하기...';
}

// Path: screens
class _StringsScreensKo implements _StringsScreensEn {
	_StringsScreensKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get licenses => '라이선스';
	@override String get selectServer => '서버 선택';
	@override String get switchProfile => '프로필 전환';
	@override String get subtitleStyling => '자막 스타일 설정';
	@override String get mpvConfig => 'MPV 설정';
	@override String get search => '검색';
	@override String get logs => '로그';
}

// Path: update
class _StringsUpdateKo implements _StringsUpdateEn {
	_StringsUpdateKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get available => '사용 가능한 업데이트';
	@override String versionAvailable({required Object version}) => '버전 ${version} 출시됨';
	@override String currentVersion({required Object version}) => '현재 버전: ${version}';
	@override String get skipVersion => '이 버전 건너뛰기';
	@override String get viewRelease => '릴리스 정보 보기';
	@override String get latestVersion => '최신 버전을 사용 중입니다';
	@override String get checkFailed => '업데이트 확인 실패';
}

// Path: settings
class _StringsSettingsKo implements _StringsSettingsEn {
	_StringsSettingsKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '설정';
	@override String get language => '언어';
	@override String get theme => '테마';
	@override String get appearance => '외관';
	@override String get videoPlayback => '비디오 재생';
	@override String get advanced => '고급';
	@override String get episodePosterMode => '에피소드 포스터 스타일';
	@override String get seriesPoster => '시리즈 포스터';
	@override String get seriesPosterDescription => '모든 에피소드에 시리즈 포스터 표시';
	@override String get seasonPoster => '시즌 포스터';
	@override String get seasonPosterDescription => '에피소드에 시즌별 포스터 표시';
	@override String get episodeThumbnail => '에피소드 썸네일';
	@override String get episodeThumbnailDescription => '16:9 에피소드 스크린샷 썸네일 표시';
	@override String get showHeroSectionDescription => '홈 화면에 주요 콘텐츠 캐러셀(슬라이드) 표시';
	@override String get secondsLabel => '초';
	@override String get minutesLabel => '분';
	@override String get secondsShort => '초';
	@override String get minutesShort => '분';
	@override String durationHint({required Object min, required Object max}) => '기간 입력 (${min}-${max})';
	@override String get systemTheme => '시스템 설정';
	@override String get systemThemeDescription => '시스템 설정에 따름';
	@override String get lightTheme => '라이트 모드';
	@override String get darkTheme => '다크 모드';
	@override String get libraryDensity => '라이브러리 표시 밀도';
	@override String get compact => '좁게';
	@override String get compactDescription => '카드를 작게 표시하여 더 많은 항목을 보여줍니다.';
	@override String get normal => '보통';
	@override String get normalDescription => '기본 크기';
	@override String get comfortable => '넓게';
	@override String get comfortableDescription => '카드를 크게 표시하여 더 적은 항목을 보여줍니다.';
	@override String get viewMode => '보기 모드';
	@override String get gridView => '그리드 보기';
	@override String get gridViewDescription => '항목을 그리드 레이아웃으로 표시합니다';
	@override String get listView => '목록 보기';
	@override String get listViewDescription => '항목을 목록 레이아웃으로 표시합니다';
	@override String get showHeroSection => '주요 추천 영역 표시';
	@override String get useGlobalHubs => 'Plex 홈 레이아웃 사용';
	@override String get useGlobalHubsDescription => '공식 Plex 클라이언트처럼 홈 페이지 허브를 표시합니다. 끄면 라이브러리별 추천이 대신 표시됩니다.';
	@override String get hardwareDecoding => '하드웨어 디코딩';
	@override String get hardwareDecodingDescription => '가능한 경우 하드웨어 가속을 사용합니다';
	@override String get bufferSize => '버퍼 크기';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get subtitleStyling => '자막 스타일';
	@override String get subtitleStylingDescription => '자막의 외형을 사용자 설정';
	@override String get smallSkipDuration => '짧은 건너뛰기 시간';
	@override String get largeSkipDuration => '긴 건너뛰기 시간';
	@override String secondsUnit({required Object seconds}) => '${seconds}초';
	@override String get defaultSleepTimer => '기본 취침 타이머';
	@override String minutesUnit({required Object minutes}) => '${minutes}분';
	@override String get rememberTrackSelections => '에피소드/영화별 트랙 선택 기억';
	@override String get rememberTrackSelectionsDescription => '재생 중 트랙을 변경할 때 오디오 및 자막 언어 설정을 자동으로 저장합니다';
	@override String get videoPlayerControls => '비디오 플레이어 컨트롤';
	@override String get keyboardShortcuts => '키보드 단축키';
	@override String get keyboardShortcutsDescription => '사용자 정의 키보드 단축키';
	@override String get videoPlayerNavigation => '비디오 플레이어 탐색';
	@override String get videoPlayerNavigationDescription => '방향 키를 사용하여 비디오 플레이어 컨트롤 탐색';
	@override String get debugLogging => '디버그 로깅';
	@override String get debugLoggingDescription => '문제 해결을 위해 상세 로깅 활성화';
	@override String get viewLogs => '로그 보기';
	@override String get viewLogsDescription => '애플리케이션 로그 확인';
	@override String get clearCache => '캐시 삭제';
	@override String get clearCacheDescription => '모든 캐시된 이미지와 데이터를 지웁니다. 캐시를 지우면 애플리케이션 콘텐츠 로딩 속도가 느려질 수 있습니다.';
	@override String get clearCacheSuccess => '캐시 삭제 성공';
	@override String get resetSettings => '설정 재설정';
	@override String get resetSettingsDescription => '모든 설정을 기본값으로 재설정합니다. 이 작업은 되돌릴 수 없습니다.';
	@override String get resetSettingsSuccess => '설정 재설정 성공';
	@override String get shortcutsReset => '단축키가 기본값으로 재설정되었습니다';
	@override String get about => '정보';
	@override String get aboutDescription => '응용 프로그램 정보 및 라이선스';
	@override String get updates => '업데이트';
	@override String get updateAvailable => '사용 가능한 업데이트 있음';
	@override String get checkForUpdates => '업데이트 확인';
	@override String get validationErrorEnterNumber => '유효한 숫자를 입력하세요';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => '기간은 ${min}과 ${max} ${unit} 사이여야 합니다';
	@override String shortcutAlreadyAssigned({required Object action}) => '단축키가 이미 ${action}에 할당 되었습니다';
	@override String shortcutUpdated({required Object action}) => '단축키가 ${action}에 대해 업데이트 되었습니다';
	@override String get autoSkip => '자동 건너뛰기';
	@override String get autoSkipIntro => '자동으로 오프닝 건너뛰기';
	@override String get autoSkipIntroDescription => '몇 초 후 오프닝을 자동으로 건너뛰기';
	@override String get autoSkipCredits => '자동으로 엔딩 건너뛰기';
	@override String get autoSkipCreditsDescription => '엔딩 크레딧 자동 건너뛰기 후 다음 에피소드 재생';
	@override String get autoSkipDelay => '자동 건너뛰기 지연';
	@override String autoSkipDelayDescription({required Object seconds}) => '자동 건너뛰기 전 ${seconds} 초 대기';
	@override String get downloads => '다운로드';
	@override String get downloadLocationDescription => '다운로드 콘텐츠 저장 위치 선택';
	@override String get downloadLocationDefault => '기본값 (앱 저장소)';
	@override String get downloadLocationCustom => '사용자 지정 위치';
	@override String get selectFolder => '폴더 선택';
	@override String get resetToDefault => '기본값으로 재설정';
	@override String currentPath({required Object path}) => '현재: ${path}';
	@override String get downloadLocationChanged => '다운로드 위치가 변경 되었습니다';
	@override String get downloadLocationReset => '다운로드 위치가 기본값으로 재설정 되었습니다';
	@override String get downloadLocationInvalid => '선택한 폴더에 쓰기 권한이 없습니다';
	@override String get downloadLocationSelectError => '폴더 선택 실패';
	@override String get downloadOnWifiOnly => 'WiFi 연결 시에만 다운로드';
	@override String get downloadOnWifiOnlyDescription => '셀룰러 데이터 사용 시 다운로드 불가';
	@override String get cellularDownloadBlocked => '셀룰러 데이터에서 다운로드가 차단 되었습니다. WiFi에 연결하거나 설정을 변경하세요.';
	@override String get maxVolume => '최대 볼륨';
	@override String get maxVolumeDescription => '조용한 미디어를 위해 100% 이상의 볼륨 허용';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get maxVolumeHint => '최대 볼륨 입력 (100-300)';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Discord에서 시청 중인 콘텐츠 표시';
}

// Path: search
class _StringsSearchKo implements _StringsSearchEn {
	_StringsSearchKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get hint => '영화, 시리즈, 음악 등을 검색하세요...';
	@override String get tryDifferentTerm => '다른 검색어를 시도해 보세요';
	@override String get searchYourMedia => '미디어 검색';
	@override String get enterTitleActorOrKeyword => '제목, 배우 또는 키워드를 입력하세요';
}

// Path: hotkeys
class _StringsHotkeysKo implements _StringsHotkeysEn {
	_StringsHotkeysKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => '${actionName}에 대한 단축키 설정';
	@override String get clearShortcut => '단축키 삭제';
}

// Path: pinEntry
class _StringsPinEntryKo implements _StringsPinEntryEn {
	_StringsPinEntryKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get enterPin => 'PIN 입력';
	@override String get showPin => 'PIN 표시';
	@override String get hidePin => 'PIN 숨기기';
}

// Path: fileInfo
class _StringsFileInfoKo implements _StringsFileInfoEn {
	_StringsFileInfoKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '파일 정보';
	@override String get video => '비디오';
	@override String get audio => '오디오';
	@override String get file => '파일';
	@override String get advanced => '고급';
	@override String get codec => '코덱';
	@override String get resolution => '해상도';
	@override String get bitrate => '비트레이트';
	@override String get frameRate => '프레임 속도';
	@override String get aspectRatio => '종횡비';
	@override String get profile => '프로파일';
	@override String get bitDepth => '비트 심도';
	@override String get colorSpace => '색 공간';
	@override String get colorRange => '색 범위';
	@override String get colorPrimaries => '색상 원색';
	@override String get chromaSubsampling => '채도 서브샘플링';
	@override String get channels => '채널';
	@override String get path => '경로';
	@override String get size => '크기';
	@override String get container => '컨테이너';
	@override String get duration => '재생 시간';
	@override String get optimizedForStreaming => '스트리밍 최적화';
	@override String get has64bitOffsets => '64비트 오프셋';
}

// Path: mediaMenu
class _StringsMediaMenuKo implements _StringsMediaMenuEn {
	_StringsMediaMenuKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => '시청 완료로 표시';
	@override String get markAsUnwatched => '시청 안 함으로 표시';
	@override String get removeFromContinueWatching => '계속 보기에서 제거';
	@override String get goToSeries => '시리즈로 이동';
	@override String get goToSeason => '시즌으로 이동';
	@override String get shufflePlay => '무작위 재생';
	@override String get fileInfo => '파일 정보';
}

// Path: accessibility
class _StringsAccessibilityKo implements _StringsAccessibilityEn {
	_StringsAccessibilityKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, 영화';
	@override String mediaCardShow({required Object title}) => '${title}, TV 프로그램';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => '시청 완료';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} 퍼센트 시청 완료';
	@override String get mediaCardUnwatched => '미시청';
	@override String get tapToPlay => '터치 하여 재생';
}

// Path: tooltips
class _StringsTooltipsKo implements _StringsTooltipsEn {
	_StringsTooltipsKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => '무작위 재생';
	@override String get markAsWatched => '시청 완료로 표시';
	@override String get markAsUnwatched => '시청 안 함으로 표시';
}

// Path: videoControls
class _StringsVideoControlsKo implements _StringsVideoControlsEn {
	_StringsVideoControlsKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => '오디오';
	@override String get subtitlesLabel => '자막';
	@override String get resetToZero => '0ms로 재설정';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} 나중에 재생됨';
	@override String playsEarlier({required Object label}) => '${label} 더 먼저 재생됨';
	@override String get noOffset => '오프셋 없음';
	@override String get letterbox => '레터박스 모드';
	@override String get fillScreen => '화면 채우기';
	@override String get stretch => '확장';
	@override String get lockRotation => '회전 잠금';
	@override String get unlockRotation => '회전 잠금 해제';
	@override String get sleepTimer => '수면 타이머';
	@override String get timerActive => '타이머 활성화됨';
	@override String playbackWillPauseIn({required Object duration}) => '재생이 ${duration} 후에 일시 중지 됩니다';
	@override String get sleepTimerCompleted => '수면 타이머 완료됨 - 재생이 일시 중지되었습니다';
	@override String get playButton => '재생';
	@override String get pauseButton => '일시정지';
	@override String seekBackwardButton({required Object seconds}) => '${seconds} 초 뒤로';
	@override String seekForwardButton({required Object seconds}) => '${seconds} 초 앞으로';
	@override String get previousButton => '이전 에피소드';
	@override String get nextButton => '다음 에피소드';
	@override String get previousChapterButton => '이전 챕터';
	@override String get nextChapterButton => '다음 챕터';
	@override String get muteButton => '음소거';
	@override String get unmuteButton => '음소거 해제';
	@override String get settingsButton => '동영상 설정';
	@override String get audioTrackButton => '음원 트랙';
	@override String get subtitlesButton => '자막';
	@override String get chaptersButton => '챕터';
	@override String get versionsButton => '동영상 버전';
	@override String get pipButton => '픽처 인 픽처 모드';
	@override String get aspectRatioButton => '화면비율';
	@override String get fullscreenButton => '전체화면';
	@override String get exitFullscreenButton => '전체화면 종료';
	@override String get alwaysOnTopButton => '창 최상위 고정';
	@override String get rotationLockButton => '회전 잠금';
	@override String get timelineSlider => '타임라인';
	@override String get volumeSlider => '볼륨 조절';
	@override String get backButton => '뒤로 가기';
}

// Path: userStatus
class _StringsUserStatusKo implements _StringsUserStatusEn {
	_StringsUserStatusKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get admin => '관리자';
	@override String get restricted => '제한됨';
	@override String get protected => '보호됨';
	@override String get current => '현재';
}

// Path: messages
class _StringsMessagesKo implements _StringsMessagesEn {
	_StringsMessagesKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => '시청 완료로 표시됨';
	@override String get markedAsUnwatched => '시청 안 함으로 표시됨';
	@override String get markedAsWatchedOffline => '시청 완료로 표시됨 (연결 시 동기화됨)';
	@override String get markedAsUnwatchedOffline => '미시청으로 표시됨 (연결 시 동기화됨)';
	@override String get removedFromContinueWatching => '계속 시청 목록에서 제거됨';
	@override String errorLoading({required Object error}) => '오류: ${error}';
	@override String get fileInfoNotAvailable => '파일 정보가 없습니다';
	@override String errorLoadingFileInfo({required Object error}) => '파일 정보 로딩 중 오류: ${error}';
	@override String get errorLoadingSeries => '시리즈 로딩 중 오류';
	@override String get errorLoadingSeason => '시즌 로딩 중 오류';
	@override String get musicNotSupported => '음악 재생 미지원';
	@override String get logsCleared => '로그가 삭제 되었습니다';
	@override String get logsCopied => '로그가 클립보드에 복사 되었습니다';
	@override String get noLogsAvailable => '사용 가능한 로그가 없습니다';
	@override String libraryScanning({required Object title}) => '"${title}"을(를) 스캔 중입니다...';
	@override String libraryScanStarted({required Object title}) => '"${title}" 미디어 라이브러리 스캔 시작';
	@override String libraryScanFailed({required Object error}) => '미디어 라이브러리 스캔 실패: ${error}';
	@override String metadataRefreshing({required Object title}) => '"${title}" 메타데이터 새로고침 중...';
	@override String metadataRefreshStarted({required Object title}) => '"${title}" 메타데이터 새로고침 시작됨';
	@override String metadataRefreshFailed({required Object error}) => '메타데이터 새로고침 실패: ${error}';
	@override String get logoutConfirm => '로그아웃 하시겠습니까?';
	@override String get noSeasonsFound => '시즌을 찾을 수 없음';
	@override String get noEpisodesFound => '시즌 1에서 에피소드를 찾을 수 없습니다';
	@override String get noEpisodesFoundGeneral => '에피소드를 찾을 수 없습니다';
	@override String get noResultsFound => '결과를 찾을 수 없습니다';
	@override String sleepTimerSet({required Object label}) => '수면 타이머가 ${label}로 설정 되었습니다';
	@override String get noItemsAvailable => '사용 가능한 항목이 없습니다';
	@override String get failedToCreatePlayQueue => '재생 대기열 생성 실패';
	@override String get failedToCreatePlayQueueNoItems => '재생 대기열 생성 실패 - 항목 없음';
	@override String failedPlayback({required Object action, required Object error}) => '${action}을(를) 수행할 수 없습니다: ${error}';
}

// Path: subtitlingStyling
class _StringsSubtitlingStylingKo implements _StringsSubtitlingStylingEn {
	_StringsSubtitlingStylingKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get stylingOptions => '스타일 옵션';
	@override String get fontSize => '글자 크기';
	@override String get textColor => '텍스트 색상';
	@override String get borderSize => '테두리 크기';
	@override String get borderColor => '테두리 색상';
	@override String get backgroundOpacity => '배경 불투명도';
	@override String get backgroundColor => '배경색';
}

// Path: mpvConfig
class _StringsMpvConfigKo implements _StringsMpvConfigEn {
	_StringsMpvConfigKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get title => 'MPV 설정';
	@override String get description => '고급 비디오 플레이어 설정';
	@override String get properties => '속성';
	@override String get presets => '사전 설정';
	@override String get noProperties => '설정된 속성이 없습니다';
	@override String get noPresets => '저장된 사전 설정이 없습니다';
	@override String get addProperty => '속성 추가';
	@override String get editProperty => '속성 편집';
	@override String get deleteProperty => '속성 삭제';
	@override String get propertyKey => '속성 키';
	@override String get propertyKeyHint => '예: hwdec, demuxer-max-bytes';
	@override String get propertyValue => '속성값';
	@override String get propertyValueHint => '예: auto, 256000000';
	@override String get saveAsPreset => '프리셋으로 저장...';
	@override String get presetName => '프리셋 이름';
	@override String get presetNameHint => '이 프리셋의 이름을 입력하세요';
	@override String get loadPreset => '로드';
	@override String get deletePreset => '삭제';
	@override String get presetSaved => '프리셋이 저장 되었습니다';
	@override String get presetLoaded => '프리셋이 로드 되었습니다';
	@override String get presetDeleted => '프리셋이 삭제 되었습니다';
	@override String get confirmDeletePreset => '이 프리셋을 삭제 하시겠습니까?';
	@override String get confirmDeleteProperty => '이 속성을 삭제 하시겠습니까?';
	@override String entriesCount({required Object count}) => '${count} 항목';
}

// Path: dialog
class _StringsDialogKo implements _StringsDialogEn {
	_StringsDialogKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => '확인';
	@override String get cancel => '취소';
	@override String get playNow => '지금 재생';
}

// Path: discover
class _StringsDiscoverKo implements _StringsDiscoverEn {
	_StringsDiscoverKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '발견';
	@override String get switchProfile => '사용자 전환';
	@override String get switchServer => '서버 전환';
	@override String get logout => '로그아웃';
	@override String get noContentAvailable => '사용 가능한 콘텐츠가 없습니다';
	@override String get addMediaToLibraries => '미디어 라이브러리에 미디어를 추가해 주세요';
	@override String get continueWatching => '계속 시청';
	@override String get play => '재생';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get pause => '일시정지';
	@override String get overview => '개요';
	@override String get cast => '출연진';
	@override String get seasons => '시즌 수';
	@override String get studio => '제작사';
	@override String get rating => '연령 등급';
	@override String get watched => '시청 완료';
	@override String episodeCount({required Object count}) => '${count} 편';
	@override String watchedProgress({required Object watched, required Object total}) => '${watched}/${total} 편 시청 완료';
	@override String get movie => '영화';
	@override String get tvShow => 'TV 시리즈';
	@override String minutesLeft({required Object minutes}) => '${minutes}분 남음';
}

// Path: errors
class _StringsErrorsKo implements _StringsErrorsEn {
	_StringsErrorsKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => '검색 실패: ${error}';
	@override String connectionTimeout({required Object context}) => '${context} 로드 중 연결 시간 초과';
	@override String get connectionFailed => 'Plex 서버에 연결할 수 없음';
	@override String failedToLoad({required Object context, required Object error}) => '${context} 로드 실패: ${error}';
	@override String get noClientAvailable => '사용 가능한 클라이언트가 없습니다';
	@override String authenticationFailed({required Object error}) => '인증 실패: ${error}';
	@override String get couldNotLaunchUrl => '인증 URL을 열 수 없습니다';
	@override String get pleaseEnterToken => '토큰을 입력해 주세요';
	@override String get invalidToken => '토큰이 유효하지 않습니다';
	@override String failedToVerifyToken({required Object error}) => '토큰을 확인할 수 없습니다: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => '${displayName}으로 전환할 수 없습니다';
}

// Path: libraries
class _StringsLibrariesKo implements _StringsLibrariesEn {
	_StringsLibrariesKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '미디어 라이브러리';
	@override String get scanLibraryFiles => '미디어 라이브러리 파일 스캔';
	@override String get scanLibrary => '미디어 라이브러리 스캔';
	@override String get analyze => '분석';
	@override String get analyzeLibrary => '미디어 라이브러리 분석';
	@override String get refreshMetadata => '메타데이터 새로 고침';
	@override String get emptyTrash => '휴지통 비우기';
	@override String emptyingTrash({required Object title}) => '「${title}」의 휴지통을 비우고 있습니다...';
	@override String trashEmptied({required Object title}) => '「${title}」의 휴지통을 비웠습니다';
	@override String failedToEmptyTrash({required Object error}) => '휴지통 비우기 실패: ${error}';
	@override String analyzing({required Object title}) => '"${title}" 분석 중...';
	@override String analysisStarted({required Object title}) => '"${title}" 분석 시작됨';
	@override String failedToAnalyze({required Object error}) => '미디어 라이브러리 분석 실패: ${error}';
	@override String get noLibrariesFound => '미디어 라이브러리 없음';
	@override String get thisLibraryIsEmpty => '이 미디어 라이브러리는 비어 있습니다';
	@override String get all => '전체';
	@override String get clearAll => '모두 삭제';
	@override String scanLibraryConfirm({required Object title}) => '「${title}」를 스캔 하시겠습니까?';
	@override String analyzeLibraryConfirm({required Object title}) => '「${title}」를 분석 하시겠습니까?';
	@override String refreshMetadataConfirm({required Object title}) => '「${title}」의 메타데이터를 새로고침 하시겠습니까?';
	@override String emptyTrashConfirm({required Object title}) => '${title}의 휴지통을 비우시겠습니까?';
	@override String get manageLibraries => '미디어 라이브러리 관리';
	@override String get sort => '정렬';
	@override String get sortBy => '정렬 기준';
	@override String get filters => '필터';
	@override String get confirmActionMessage => '이 작업을 실행 하시겠습니까?';
	@override String get showLibrary => '미디어 라이브러리 표시';
	@override String get hideLibrary => '미디어 라이브러리 숨기기';
	@override String get libraryOptions => '미디어 라이브러리 옵션';
	@override String get content => '미디어 라이브러리 콘텐츠';
	@override String get selectLibrary => '미디어 라이브러리 선택';
	@override String filtersWithCount({required Object count}) => '필터 (${count})';
	@override String get noRecommendations => '추천 없음';
	@override String get noCollections => '이 미디어 라이브러리에는 컬렉션이 없습니다';
	@override String get noFoldersFound => '폴더를 찾을 수 없습니다';
	@override String get folders => '폴더';
	@override late final _StringsLibrariesTabsKo tabs = _StringsLibrariesTabsKo._(_root);
	@override late final _StringsLibrariesGroupingsKo groupings = _StringsLibrariesGroupingsKo._(_root);
}

// Path: about
class _StringsAboutKo implements _StringsAboutEn {
	_StringsAboutKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '소개';
	@override String get openSourceLicenses => '오픈소스 라이선스';
	@override String versionLabel({required Object version}) => '버전 ${version}';
	@override String get appDescription => '아름다운 Flutter Plex 클라이언트';
	@override String get viewLicensesDescription => '타사 라이브러리 라이선스 보기';
}

// Path: serverSelection
class _StringsServerSelectionKo implements _StringsServerSelectionEn {
	_StringsServerSelectionKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get allServerConnectionsFailed => '어떤 서버에도 연결할 수 없습니다. 네트워크를 확인하고 다시 시도하세요.';
	@override String get noServersFound => '서버를 찾을 수 없습니다.';
	@override String noServersFoundForAccount({required Object username, required Object email}) => '${username} (${email})의 서버를 찾을 수 없습니다.';
	@override String failedToLoadServers({required Object error}) => '서버를 로드할 수 없습니다: ${error}';
}

// Path: hubDetail
class _StringsHubDetailKo implements _StringsHubDetailEn {
	_StringsHubDetailKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '제목';
	@override String get releaseYear => '출시 연도';
	@override String get dateAdded => '추가 날짜';
	@override String get rating => '평점';
	@override String get noItemsFound => '항목이 없습니다';
}

// Path: logs
class _StringsLogsKo implements _StringsLogsEn {
	_StringsLogsKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => '로그 지우기';
	@override String get copyLogs => '로그 복사';
	@override String get error => '오류:';
	@override String get stackTrace => '스택 추적 (Stack Trace):';
}

// Path: licenses
class _StringsLicensesKo implements _StringsLicensesEn {
	_StringsLicensesKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => '관련 소프트웨어 패키지';
	@override String get license => '라이선스';
	@override String licenseNumber({required Object number}) => '라이선스 ${number}';
	@override String licensesCount({required Object count}) => '${count} 개의 라이선스';
}

// Path: navigation
class _StringsNavigationKo implements _StringsNavigationEn {
	_StringsNavigationKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get home => '홈';
	@override String get search => '검색';
	@override String get libraries => '미디어 라이브러리';
	@override String get settings => '설정';
	@override String get downloads => '다운로드';
}

// Path: collections
class _StringsCollectionsKo implements _StringsCollectionsEn {
	_StringsCollectionsKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '컬렉션';
	@override String get collection => '컬렉션';
	@override String get empty => '컬렉션이 비어 있습니다';
	@override String get unknownLibrarySection => '삭제할 수 없습니다: 알 수 없는 미디어 라이브러리 섹션입니다';
	@override String get deleteCollection => '컬렉션 삭제';
	@override String deleteConfirm({required Object title}) => '"${title}"을(를) 삭제 하시겠습니까? 이 작업은 되돌릴 수 없습니다.';
	@override String get deleted => '컬렉션 삭제됨';
	@override String get deleteFailed => '컬렉션 삭제 실패';
	@override String deleteFailedWithError({required Object error}) => '컬렉션 삭제 실패: ${error}';
	@override String failedToLoadItems({required Object error}) => '컬렉션 항목 로드 실패: ${error}';
	@override String get selectCollection => '컬렉션 선택';
	@override String get createNewCollection => '새 컬렉션 생성';
	@override String get collectionName => '컬렉션 이름';
	@override String get enterCollectionName => '컬렉션 이름 입력';
	@override String get addedToCollection => '컬렉션에 추가됨';
	@override String get errorAddingToCollection => '컬렉션에 추가 실패';
	@override String get created => '컬렉션 생성됨';
	@override String get removeFromCollection => '컬렉션에서 제거';
	@override String removeFromCollectionConfirm({required Object title}) => '${title}을/를 이 컬렉션에서 제거 하시겠습니까?';
	@override String get removedFromCollection => '컬렉션에서 제거됨';
	@override String get removeFromCollectionFailed => '컬렉션에서 제거 실패';
	@override String removeFromCollectionError({required Object error}) => '컬렉션에서 제거 중 오류 발생: ${error}';
}

// Path: playlists
class _StringsPlaylistsKo implements _StringsPlaylistsEn {
	_StringsPlaylistsKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '플레이리스트';
	@override String get playlist => '재생 목록';
	@override String get noPlaylists => '재생 목록을 찾을 수 없습니다';
	@override String get create => '재생 목록 생성';
	@override String get playlistName => '재생 목록 이름';
	@override String get enterPlaylistName => '재생 목록 이름 입력';
	@override String get delete => '재생 목록 삭제';
	@override String get removeItem => '재생 목록에서 항목 제거';
	@override String get smartPlaylist => '스마트 재생 목록';
	@override String itemCount({required Object count}) => '${count}개 항목';
	@override String get oneItem => '1개 항목';
	@override String get emptyPlaylist => '이 재생 목록은 비어 있습니다';
	@override String get deleteConfirm => '재생 목록을 삭제 하시겠습니까?';
	@override String deleteMessage({required Object name}) => '"${name}"을(를) 삭제 하시겠습니까?';
	@override String get created => '재생 목록이 생성 되었습니다';
	@override String get deleted => '재생 목록이 삭제 되었습니다';
	@override String get itemAdded => '재생 목록에 추가 되었습니다';
	@override String get itemRemoved => '재생 목록에서 제거됨';
	@override String get selectPlaylist => '재생 목록 선택';
	@override String get createNewPlaylist => '새 재생 목록 생성';
	@override String get errorCreating => '재생 목록 생성 실패';
	@override String get errorDeleting => '재생 목록 삭제 실패';
	@override String get errorLoading => '재생 목록 로드 실패';
	@override String get errorAdding => '재생 목록에 추가 실패';
	@override String get errorReordering => '재생 목록 항목 재정렬 실패';
	@override String get errorRemoving => '재생 목록에서 제거 실패';
}

// Path: watchTogether
class _StringsWatchTogetherKo implements _StringsWatchTogetherEn {
	_StringsWatchTogetherKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '함께 보기';
	@override String get description => '친구 및 가족과 콘텐츠를 동시에 시청하세요';
	@override String get createSession => '세션 생성';
	@override String get creating => '생성 중...';
	@override String get joinSession => '세션 참여';
	@override String get joining => '참가 중...';
	@override String get controlMode => '제어 모드';
	@override String get controlModeQuestion => '누가 재생을 제어할 수 있나요?';
	@override String get hostOnly => '호스트만';
	@override String get anyone => '누구나';
	@override String get hostingSession => '세션 호스팅';
	@override String get inSession => '세션 중';
	@override String get sessionCode => '세션 코드';
	@override String get hostControlsPlayback => '호스트 재생 제어';
	@override String get anyoneCanControl => '누구나 재생 제어 가능';
	@override String get hostControls => '호스트 제어';
	@override String get anyoneControls => '누구나 제어';
	@override String get participants => '참가자';
	@override String get host => '호스트';
	@override String get hostBadge => '호스트';
	@override String get youAreHost => '당신은 호스트 입니다';
	@override String get watchingWithOthers => '다른 사람과 함께 시청 중';
	@override String get endSession => '세션 종료';
	@override String get leaveSession => '세션 탈퇴';
	@override String get endSessionQuestion => '세션을 종료 하시겠습니까?';
	@override String get leaveSessionQuestion => '세션을 탈퇴 하시겠습니까?';
	@override String get endSessionConfirm => '이 작업은 모든 참가자의 세션을 종료합니다.';
	@override String get leaveSessionConfirm => '당신은 세션에서 제거됩니다.';
	@override String get endSessionConfirmOverlay => '이것은 모든 참가자의 시청 세션을 종료합니다.';
	@override String get leaveSessionConfirmOverlay => '시청 세션 연결이 끊어집니다.';
	@override String get end => '종료';
	@override String get leave => '이탈';
	@override String get syncing => '동기화 중...';
	@override String get participant => '참여자';
	@override String get joinWatchSession => '시청 세션에 참여';
	@override String get enterCodeHint => '8자리 코드 입력';
	@override String get pasteFromClipboard => '클립보드에서 붙여넣기';
	@override String get pleaseEnterCode => '세션 코드를 입력하세요';
	@override String get codeMustBe8Chars => '세션 코드는 반드시 8자리여야 합니다';
	@override String get joinInstructions => '호스트가 공유한 세션 코드를 입력하여 시청 세션에 참여하세요.';
	@override String get failedToCreate => '세션 생성 실패';
	@override String get failedToJoin => '세션 참여 실패';
}

// Path: downloads
class _StringsDownloadsKo implements _StringsDownloadsEn {
	_StringsDownloadsKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '다운로드';
	@override String get manage => '관리';
	@override String get tvShows => 'TV 프로그램';
	@override String get movies => '영화';
	@override String get noDownloads => '다운로드 없음';
	@override String get noDownloadsDescription => '다운로드한 콘텐츠는 오프라인 시청을 위해 여기에 표시됩니다';
	@override String get downloadNow => '다운로드';
	@override String get deleteDownload => '다운로드 삭제';
	@override String get retryDownload => '다운로드 재시도';
	@override String get downloadQueued => '다운로드 대기 중';
	@override String episodesQueued({required Object count}) => '${count} 에피소드가 다운로드 대기열에 추가 되었습니다';
	@override String get downloadDeleted => '다운로드 삭제됨';
	@override String deleteConfirm({required Object title}) => '"${title}"를 삭제 하시겠습니까? 다운로드한 파일이 기기에서 삭제됩니다.';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => '${title} 삭제 중... (${current}/${total})';
}

// Path: libraries.tabs
class _StringsLibrariesTabsKo implements _StringsLibrariesTabsEn {
	_StringsLibrariesTabsKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get recommended => '추천';
	@override String get browse => '찾아보기';
	@override String get collections => '컬렉션';
	@override String get playlists => '재생 목록';
}

// Path: libraries.groupings
class _StringsLibrariesGroupingsKo implements _StringsLibrariesGroupingsEn {
	_StringsLibrariesGroupingsKo._(this._root);

	@override final _StringsKo _root; // ignore: unused_field

	// Translations
	@override String get all => '전체';
	@override String get movies => '영화';
	@override String get shows => 'TV 프로그램';
	@override String get seasons => '시즌';
	@override String get episodes => '화';
	@override String get folders => '폴더';
}

// Path: <root>
class _StringsNl implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	_StringsNl.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
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

	@override late final _StringsNl _root = this; // ignore: unused_field

	// Translations
	@override late final _StringsAppNl app = _StringsAppNl._(_root);
	@override late final _StringsAuthNl auth = _StringsAuthNl._(_root);
	@override late final _StringsCommonNl common = _StringsCommonNl._(_root);
	@override late final _StringsScreensNl screens = _StringsScreensNl._(_root);
	@override late final _StringsUpdateNl update = _StringsUpdateNl._(_root);
	@override late final _StringsSettingsNl settings = _StringsSettingsNl._(_root);
	@override late final _StringsSearchNl search = _StringsSearchNl._(_root);
	@override late final _StringsHotkeysNl hotkeys = _StringsHotkeysNl._(_root);
	@override late final _StringsPinEntryNl pinEntry = _StringsPinEntryNl._(_root);
	@override late final _StringsFileInfoNl fileInfo = _StringsFileInfoNl._(_root);
	@override late final _StringsMediaMenuNl mediaMenu = _StringsMediaMenuNl._(_root);
	@override late final _StringsAccessibilityNl accessibility = _StringsAccessibilityNl._(_root);
	@override late final _StringsTooltipsNl tooltips = _StringsTooltipsNl._(_root);
	@override late final _StringsVideoControlsNl videoControls = _StringsVideoControlsNl._(_root);
	@override late final _StringsUserStatusNl userStatus = _StringsUserStatusNl._(_root);
	@override late final _StringsMessagesNl messages = _StringsMessagesNl._(_root);
	@override late final _StringsSubtitlingStylingNl subtitlingStyling = _StringsSubtitlingStylingNl._(_root);
	@override late final _StringsMpvConfigNl mpvConfig = _StringsMpvConfigNl._(_root);
	@override late final _StringsDialogNl dialog = _StringsDialogNl._(_root);
	@override late final _StringsDiscoverNl discover = _StringsDiscoverNl._(_root);
	@override late final _StringsErrorsNl errors = _StringsErrorsNl._(_root);
	@override late final _StringsLibrariesNl libraries = _StringsLibrariesNl._(_root);
	@override late final _StringsAboutNl about = _StringsAboutNl._(_root);
	@override late final _StringsServerSelectionNl serverSelection = _StringsServerSelectionNl._(_root);
	@override late final _StringsHubDetailNl hubDetail = _StringsHubDetailNl._(_root);
	@override late final _StringsLogsNl logs = _StringsLogsNl._(_root);
	@override late final _StringsLicensesNl licenses = _StringsLicensesNl._(_root);
	@override late final _StringsNavigationNl navigation = _StringsNavigationNl._(_root);
	@override late final _StringsDownloadsNl downloads = _StringsDownloadsNl._(_root);
	@override late final _StringsPlaylistsNl playlists = _StringsPlaylistsNl._(_root);
	@override late final _StringsCollectionsNl collections = _StringsCollectionsNl._(_root);
	@override late final _StringsWatchTogetherNl watchTogether = _StringsWatchTogetherNl._(_root);
}

// Path: app
class _StringsAppNl implements _StringsAppEn {
	_StringsAppNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
	@override String get loading => 'Laden...';
}

// Path: auth
class _StringsAuthNl implements _StringsAuthEn {
	_StringsAuthNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Inloggen met Plex';
	@override String get showQRCode => 'Toon QR-code';
	@override String get cancel => 'Annuleren';
	@override String get authenticate => 'Authenticeren';
	@override String get retry => 'Opnieuw proberen';
	@override String get debugEnterToken => 'Debug: Voer Plex Token in';
	@override String get plexTokenLabel => 'Plex Authenticatietoken';
	@override String get plexTokenHint => 'Voer je Plex.tv token in';
	@override String get authenticationTimeout => 'Authenticatie verlopen. Probeer opnieuw.';
	@override String get scanQRCodeInstruction => 'Scan deze QR-code met een apparaat dat is ingelogd op Plex om te authenticeren.';
	@override String get waitingForAuth => 'Wachten op authenticatie...\nVoltooi het inloggen in je browser.';
}

// Path: common
class _StringsCommonNl implements _StringsCommonEn {
	_StringsCommonNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

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
}

// Path: screens
class _StringsScreensNl implements _StringsScreensEn {
	_StringsScreensNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licenties';
	@override String get selectServer => 'Selecteer server';
	@override String get switchProfile => 'Wissel van profiel';
	@override String get subtitleStyling => 'Ondertitel opmaak';
	@override String get mpvConfig => 'MPV-configuratie';
	@override String get search => 'Zoeken';
	@override String get logs => 'Logbestanden';
}

// Path: update
class _StringsUpdateNl implements _StringsUpdateEn {
	_StringsUpdateNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

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
class _StringsSettingsNl implements _StringsSettingsEn {
	_StringsSettingsNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

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
	@override String get maxVolumeHint => 'Voer maximaal volume in (100-300)';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Toon op Discord wat je aan het kijken bent';
}

// Path: search
class _StringsSearchNl implements _StringsSearchEn {
	_StringsSearchNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Zoek films, series, muziek...';
	@override String get tryDifferentTerm => 'Probeer een andere zoekterm';
	@override String get searchYourMedia => 'Zoek in je media';
	@override String get enterTitleActorOrKeyword => 'Voer een titel, acteur of trefwoord in';
}

// Path: hotkeys
class _StringsHotkeysNl implements _StringsHotkeysEn {
	_StringsHotkeysNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Stel sneltoets in voor ${actionName}';
	@override String get clearShortcut => 'Wis sneltoets';
}

// Path: pinEntry
class _StringsPinEntryNl implements _StringsPinEntryEn {
	_StringsPinEntryNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get enterPin => 'Voer PIN in';
	@override String get showPin => 'Toon PIN';
	@override String get hidePin => 'Verberg PIN';
}

// Path: fileInfo
class _StringsFileInfoNl implements _StringsFileInfoEn {
	_StringsFileInfoNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

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
class _StringsMediaMenuNl implements _StringsMediaMenuEn {
	_StringsMediaMenuNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Markeer als gekeken';
	@override String get markAsUnwatched => 'Markeer als ongekeken';
	@override String get removeFromContinueWatching => 'Verwijder uit Doorgaan met kijken';
	@override String get goToSeries => 'Ga naar serie';
	@override String get goToSeason => 'Ga naar seizoen';
	@override String get shufflePlay => 'Willekeurig afspelen';
	@override String get fileInfo => 'Bestand info';
}

// Path: accessibility
class _StringsAccessibilityNl implements _StringsAccessibilityEn {
	_StringsAccessibilityNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

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
class _StringsTooltipsNl implements _StringsTooltipsEn {
	_StringsTooltipsNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Willekeurig afspelen';
	@override String get markAsWatched => 'Markeer als gekeken';
	@override String get markAsUnwatched => 'Markeer als ongekeken';
}

// Path: videoControls
class _StringsVideoControlsNl implements _StringsVideoControlsEn {
	_StringsVideoControlsNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

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
	@override String get sleepTimer => 'Slaaptimer';
	@override String get timerActive => 'Timer actief';
	@override String playbackWillPauseIn({required Object duration}) => 'Afspelen wordt gepauzeerd over ${duration}';
	@override String get sleepTimerCompleted => 'Slaaptimer voltooid - afspelen gepauzeerd';
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
	@override String get backButton => 'Terug';
}

// Path: userStatus
class _StringsUserStatusNl implements _StringsUserStatusEn {
	_StringsUserStatusNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Beheerder';
	@override String get restricted => 'Beperkt';
	@override String get protected => 'Beschermd';
	@override String get current => 'HUIDIG';
}

// Path: messages
class _StringsMessagesNl implements _StringsMessagesEn {
	_StringsMessagesNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

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
	@override String get failedToCreatePlayQueue => 'Kan afspeelwachtrij niet maken';
	@override String get failedToCreatePlayQueueNoItems => 'Kan afspeelwachtrij niet maken - geen items';
	@override String failedPlayback({required Object action, required Object error}) => 'Afspelen van ${action} mislukt: ${error}';
}

// Path: subtitlingStyling
class _StringsSubtitlingStylingNl implements _StringsSubtitlingStylingEn {
	_StringsSubtitlingStylingNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get stylingOptions => 'Opmaak opties';
	@override String get fontSize => 'Lettergrootte';
	@override String get textColor => 'Tekstkleur';
	@override String get borderSize => 'Rand grootte';
	@override String get borderColor => 'Randkleur';
	@override String get backgroundOpacity => 'Achtergrond transparantie';
	@override String get backgroundColor => 'Achtergrondkleur';
}

// Path: mpvConfig
class _StringsMpvConfigNl implements _StringsMpvConfigEn {
	_StringsMpvConfigNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

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
class _StringsDialogNl implements _StringsDialogEn {
	_StringsDialogNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Bevestig actie';
	@override String get cancel => 'Annuleren';
	@override String get playNow => 'Nu afspelen';
}

// Path: discover
class _StringsDiscoverNl implements _StringsDiscoverEn {
	_StringsDiscoverNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ontdekken';
	@override String get switchProfile => 'Wissel van profiel';
	@override String get switchServer => 'Wissel van server';
	@override String get logout => 'Uitloggen';
	@override String get noContentAvailable => 'Geen inhoud beschikbaar';
	@override String get addMediaToLibraries => 'Voeg wat media toe aan je bibliotheken';
	@override String get continueWatching => 'Verder kijken';
	@override String get play => 'Afspelen';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get pause => 'Pauzeren';
	@override String get overview => 'Overzicht';
	@override String get cast => 'Acteurs';
	@override String get seasons => 'Seizoenen';
	@override String get studio => 'Studio';
	@override String get rating => 'Leeftijd';
	@override String get watched => 'Bekeken';
	@override String episodeCount({required Object count}) => '${count} afleveringen';
	@override String watchedProgress({required Object watched, required Object total}) => '${watched}/${total} gekeken';
	@override String get movie => 'Film';
	@override String get tvShow => 'TV Serie';
	@override String minutesLeft({required Object minutes}) => '${minutes} min over';
}

// Path: errors
class _StringsErrorsNl implements _StringsErrorsEn {
	_StringsErrorsNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

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
class _StringsLibrariesNl implements _StringsLibrariesEn {
	_StringsLibrariesNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

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
	@override late final _StringsLibrariesTabsNl tabs = _StringsLibrariesTabsNl._(_root);
	@override late final _StringsLibrariesGroupingsNl groupings = _StringsLibrariesGroupingsNl._(_root);
}

// Path: about
class _StringsAboutNl implements _StringsAboutEn {
	_StringsAboutNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Over';
	@override String get openSourceLicenses => 'Open Source licenties';
	@override String versionLabel({required Object version}) => 'Versie ${version}';
	@override String get appDescription => 'Een mooie Plex client voor Flutter';
	@override String get viewLicensesDescription => 'Bekijk licenties van third-party bibliotheken';
}

// Path: serverSelection
class _StringsServerSelectionNl implements _StringsServerSelectionEn {
	_StringsServerSelectionNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get allServerConnectionsFailed => 'Kon niet verbinden met servers. Controleer je netwerk en probeer opnieuw.';
	@override String get noServersFound => 'Geen servers gevonden';
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Geen servers gevonden voor ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Kon servers niet laden: ${error}';
}

// Path: hubDetail
class _StringsHubDetailNl implements _StringsHubDetailEn {
	_StringsHubDetailNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titel';
	@override String get releaseYear => 'Uitgavejaar';
	@override String get dateAdded => 'Datum toegevoegd';
	@override String get rating => 'Beoordeling';
	@override String get noItemsFound => 'Geen items gevonden';
}

// Path: logs
class _StringsLogsNl implements _StringsLogsEn {
	_StringsLogsNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Wis logs';
	@override String get copyLogs => 'Kopieer logs';
	@override String get error => 'Fout:';
	@override String get stackTrace => 'Stacktracering:';
}

// Path: licenses
class _StringsLicensesNl implements _StringsLicensesEn {
	_StringsLicensesNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Gerelateerde pakketten';
	@override String get license => 'Licentie';
	@override String licenseNumber({required Object number}) => 'Licentie ${number}';
	@override String licensesCount({required Object count}) => '${count} licenties';
}

// Path: navigation
class _StringsNavigationNl implements _StringsNavigationEn {
	_StringsNavigationNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get home => 'Thuis';
	@override String get search => 'Zoeken';
	@override String get libraries => 'Bibliotheken';
	@override String get settings => 'Instellingen';
	@override String get downloads => 'Downloads';
}

// Path: downloads
class _StringsDownloadsNl implements _StringsDownloadsEn {
	_StringsDownloadsNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

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
}

// Path: playlists
class _StringsPlaylistsNl implements _StringsPlaylistsEn {
	_StringsPlaylistsNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

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
class _StringsCollectionsNl implements _StringsCollectionsEn {
	_StringsCollectionsNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

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
class _StringsWatchTogetherNl implements _StringsWatchTogetherEn {
	_StringsWatchTogetherNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

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
	@override String get participant => 'deelnemer';
	@override String get joinWatchSession => 'Kijksessie Deelnemen';
	@override String get enterCodeHint => 'Voer 8-teken code in';
	@override String get pasteFromClipboard => 'Plakken van klembord';
	@override String get pleaseEnterCode => 'Voer een sessiecode in';
	@override String get codeMustBe8Chars => 'Sessiecode moet 8 tekens zijn';
	@override String get joinInstructions => 'Voer de sessiecode in die door de host is gedeeld om deel te nemen aan hun kijksessie.';
	@override String get failedToCreate => 'Sessie maken mislukt';
	@override String get failedToJoin => 'Sessie deelnemen mislukt';
}

// Path: libraries.tabs
class _StringsLibrariesTabsNl implements _StringsLibrariesTabsEn {
	_StringsLibrariesTabsNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Aanbevolen';
	@override String get browse => 'Bladeren';
	@override String get collections => 'Collecties';
	@override String get playlists => 'Afspeellijsten';
}

// Path: libraries.groupings
class _StringsLibrariesGroupingsNl implements _StringsLibrariesGroupingsEn {
	_StringsLibrariesGroupingsNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get all => 'Alles';
	@override String get movies => 'Films';
	@override String get shows => 'Series';
	@override String get seasons => 'Seizoenen';
	@override String get episodes => 'Afleveringen';
	@override String get folders => 'Mappen';
}

// Path: <root>
class _StringsSv implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	_StringsSv.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
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

	@override late final _StringsSv _root = this; // ignore: unused_field

	// Translations
	@override late final _StringsAppSv app = _StringsAppSv._(_root);
	@override late final _StringsAuthSv auth = _StringsAuthSv._(_root);
	@override late final _StringsCommonSv common = _StringsCommonSv._(_root);
	@override late final _StringsScreensSv screens = _StringsScreensSv._(_root);
	@override late final _StringsUpdateSv update = _StringsUpdateSv._(_root);
	@override late final _StringsSettingsSv settings = _StringsSettingsSv._(_root);
	@override late final _StringsSearchSv search = _StringsSearchSv._(_root);
	@override late final _StringsHotkeysSv hotkeys = _StringsHotkeysSv._(_root);
	@override late final _StringsPinEntrySv pinEntry = _StringsPinEntrySv._(_root);
	@override late final _StringsFileInfoSv fileInfo = _StringsFileInfoSv._(_root);
	@override late final _StringsMediaMenuSv mediaMenu = _StringsMediaMenuSv._(_root);
	@override late final _StringsAccessibilitySv accessibility = _StringsAccessibilitySv._(_root);
	@override late final _StringsTooltipsSv tooltips = _StringsTooltipsSv._(_root);
	@override late final _StringsVideoControlsSv videoControls = _StringsVideoControlsSv._(_root);
	@override late final _StringsUserStatusSv userStatus = _StringsUserStatusSv._(_root);
	@override late final _StringsMessagesSv messages = _StringsMessagesSv._(_root);
	@override late final _StringsSubtitlingStylingSv subtitlingStyling = _StringsSubtitlingStylingSv._(_root);
	@override late final _StringsMpvConfigSv mpvConfig = _StringsMpvConfigSv._(_root);
	@override late final _StringsDialogSv dialog = _StringsDialogSv._(_root);
	@override late final _StringsDiscoverSv discover = _StringsDiscoverSv._(_root);
	@override late final _StringsErrorsSv errors = _StringsErrorsSv._(_root);
	@override late final _StringsLibrariesSv libraries = _StringsLibrariesSv._(_root);
	@override late final _StringsAboutSv about = _StringsAboutSv._(_root);
	@override late final _StringsServerSelectionSv serverSelection = _StringsServerSelectionSv._(_root);
	@override late final _StringsHubDetailSv hubDetail = _StringsHubDetailSv._(_root);
	@override late final _StringsLogsSv logs = _StringsLogsSv._(_root);
	@override late final _StringsLicensesSv licenses = _StringsLicensesSv._(_root);
	@override late final _StringsNavigationSv navigation = _StringsNavigationSv._(_root);
	@override late final _StringsDownloadsSv downloads = _StringsDownloadsSv._(_root);
	@override late final _StringsPlaylistsSv playlists = _StringsPlaylistsSv._(_root);
	@override late final _StringsCollectionsSv collections = _StringsCollectionsSv._(_root);
	@override late final _StringsWatchTogetherSv watchTogether = _StringsWatchTogetherSv._(_root);
}

// Path: app
class _StringsAppSv implements _StringsAppEn {
	_StringsAppSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
	@override String get loading => 'Laddar...';
}

// Path: auth
class _StringsAuthSv implements _StringsAuthEn {
	_StringsAuthSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Logga in med Plex';
	@override String get showQRCode => 'Visa QR-kod';
	@override String get cancel => 'Avbryt';
	@override String get authenticate => 'Autentisera';
	@override String get retry => 'Försök igen';
	@override String get debugEnterToken => 'Debug: Ange Plex-token';
	@override String get plexTokenLabel => 'Plex-autentiseringstoken';
	@override String get plexTokenHint => 'Ange din Plex.tv-token';
	@override String get authenticationTimeout => 'Autentisering tog för lång tid. Försök igen.';
	@override String get scanQRCodeInstruction => 'Skanna denna QR-kod med en enhet inloggad på Plex för att autentisera.';
	@override String get waitingForAuth => 'Väntar på autentisering...\nVänligen slutför inloggning i din webbläsare.';
}

// Path: common
class _StringsCommonSv implements _StringsCommonEn {
	_StringsCommonSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

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
}

// Path: screens
class _StringsScreensSv implements _StringsScreensEn {
	_StringsScreensSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licenser';
	@override String get selectServer => 'Välj server';
	@override String get switchProfile => 'Byt profil';
	@override String get subtitleStyling => 'Undertext-styling';
	@override String get mpvConfig => 'MPV-konfiguration';
	@override String get search => 'Sök';
	@override String get logs => 'Loggar';
}

// Path: update
class _StringsUpdateSv implements _StringsUpdateEn {
	_StringsUpdateSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

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
class _StringsSettingsSv implements _StringsSettingsEn {
	_StringsSettingsSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

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
	@override String get cellularDownloadBlocked => 'Nedladdningar är inaktiverade på mobildata. Anslut till WiFi eller ändra inställningen.';
	@override String get maxVolume => 'Maximal volym';
	@override String get maxVolumeDescription => 'Tillåt volym över 100% för tyst media';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get maxVolumeHint => 'Ange maximal volym (100-300)';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Visa vad du tittar på i Discord';
}

// Path: search
class _StringsSearchSv implements _StringsSearchEn {
	_StringsSearchSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Sök filmer, serier, musik...';
	@override String get tryDifferentTerm => 'Prova en annan sökterm';
	@override String get searchYourMedia => 'Sök i dina media';
	@override String get enterTitleActorOrKeyword => 'Ange en titel, skådespelare eller nyckelord';
}

// Path: hotkeys
class _StringsHotkeysSv implements _StringsHotkeysEn {
	_StringsHotkeysSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Sätt genväg för ${actionName}';
	@override String get clearShortcut => 'Rensa genväg';
}

// Path: pinEntry
class _StringsPinEntrySv implements _StringsPinEntryEn {
	_StringsPinEntrySv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get enterPin => 'Ange PIN';
	@override String get showPin => 'Visa PIN';
	@override String get hidePin => 'Dölj PIN';
}

// Path: fileInfo
class _StringsFileInfoSv implements _StringsFileInfoEn {
	_StringsFileInfoSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

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
class _StringsMediaMenuSv implements _StringsMediaMenuEn {
	_StringsMediaMenuSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Markera som sedd';
	@override String get markAsUnwatched => 'Markera som osedd';
	@override String get removeFromContinueWatching => 'Ta bort från Fortsätt titta';
	@override String get goToSeries => 'Gå till serie';
	@override String get goToSeason => 'Gå till säsong';
	@override String get shufflePlay => 'Blanda uppspelning';
	@override String get fileInfo => 'Filinformation';
}

// Path: accessibility
class _StringsAccessibilitySv implements _StringsAccessibilityEn {
	_StringsAccessibilitySv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

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
class _StringsTooltipsSv implements _StringsTooltipsEn {
	_StringsTooltipsSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Blanda uppspelning';
	@override String get markAsWatched => 'Markera som sedd';
	@override String get markAsUnwatched => 'Markera som osedd';
}

// Path: videoControls
class _StringsVideoControlsSv implements _StringsVideoControlsEn {
	_StringsVideoControlsSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

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
	@override String get sleepTimer => 'Sovtimer';
	@override String get timerActive => 'Timer aktiv';
	@override String playbackWillPauseIn({required Object duration}) => 'Uppspelningen pausas om ${duration}';
	@override String get sleepTimerCompleted => 'Sovtimer slutförd - uppspelning pausad';
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
	@override String get backButton => 'Tillbaka';
}

// Path: userStatus
class _StringsUserStatusSv implements _StringsUserStatusEn {
	_StringsUserStatusSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Admin';
	@override String get restricted => 'Begränsad';
	@override String get protected => 'Skyddad';
	@override String get current => 'NUVARANDE';
}

// Path: messages
class _StringsMessagesSv implements _StringsMessagesEn {
	_StringsMessagesSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

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
	@override String get failedToCreatePlayQueue => 'Det gick inte att skapa uppspelningskö';
	@override String get failedToCreatePlayQueueNoItems => 'Det gick inte att skapa uppspelningskö – inga objekt';
	@override String failedPlayback({required Object action, required Object error}) => 'Kunde inte ${action}: ${error}';
}

// Path: subtitlingStyling
class _StringsSubtitlingStylingSv implements _StringsSubtitlingStylingEn {
	_StringsSubtitlingStylingSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get stylingOptions => 'Stilalternativ';
	@override String get fontSize => 'Teckenstorlek';
	@override String get textColor => 'Textfärg';
	@override String get borderSize => 'Kantstorlek';
	@override String get borderColor => 'Kantfärg';
	@override String get backgroundOpacity => 'Bakgrundsopacitet';
	@override String get backgroundColor => 'Bakgrundsfärg';
}

// Path: mpvConfig
class _StringsMpvConfigSv implements _StringsMpvConfigEn {
	_StringsMpvConfigSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

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
class _StringsDialogSv implements _StringsDialogEn {
	_StringsDialogSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Bekräfta åtgärd';
	@override String get cancel => 'Avbryt';
	@override String get playNow => 'Spela nu';
}

// Path: discover
class _StringsDiscoverSv implements _StringsDiscoverEn {
	_StringsDiscoverSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Upptäck';
	@override String get switchProfile => 'Byt profil';
	@override String get switchServer => 'Byt server';
	@override String get logout => 'Logga ut';
	@override String get noContentAvailable => 'Inget innehåll tillgängligt';
	@override String get addMediaToLibraries => 'Lägg till media till dina bibliotek';
	@override String get continueWatching => 'Fortsätt titta';
	@override String get play => 'Spela';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get pause => 'Pausa';
	@override String get overview => 'Översikt';
	@override String get cast => 'Rollbesättning';
	@override String get seasons => 'Säsonger';
	@override String get studio => 'Studio';
	@override String get rating => 'Åldersgräns';
	@override String get watched => 'Tittad';
	@override String episodeCount({required Object count}) => '${count} avsnitt';
	@override String watchedProgress({required Object watched, required Object total}) => '${watched}/${total} sedda';
	@override String get movie => 'Film';
	@override String get tvShow => 'TV-serie';
	@override String minutesLeft({required Object minutes}) => '${minutes} min kvar';
}

// Path: errors
class _StringsErrorsSv implements _StringsErrorsEn {
	_StringsErrorsSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

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
class _StringsLibrariesSv implements _StringsLibrariesEn {
	_StringsLibrariesSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

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
	@override late final _StringsLibrariesTabsSv tabs = _StringsLibrariesTabsSv._(_root);
	@override late final _StringsLibrariesGroupingsSv groupings = _StringsLibrariesGroupingsSv._(_root);
}

// Path: about
class _StringsAboutSv implements _StringsAboutEn {
	_StringsAboutSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Om';
	@override String get openSourceLicenses => 'Öppen källkod-licenser';
	@override String versionLabel({required Object version}) => 'Version ${version}';
	@override String get appDescription => 'En vacker Plex-klient för Flutter';
	@override String get viewLicensesDescription => 'Visa licenser för tredjepartsbibliotek';
}

// Path: serverSelection
class _StringsServerSelectionSv implements _StringsServerSelectionEn {
	_StringsServerSelectionSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get allServerConnectionsFailed => 'Misslyckades att ansluta till servrar. Kontrollera ditt nätverk och försök igen.';
	@override String get noServersFound => 'Inga servrar hittades';
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Inga servrar hittades för ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Misslyckades att ladda servrar: ${error}';
}

// Path: hubDetail
class _StringsHubDetailSv implements _StringsHubDetailEn {
	_StringsHubDetailSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titel';
	@override String get releaseYear => 'Utgivningsår';
	@override String get dateAdded => 'Datum tillagd';
	@override String get rating => 'Betyg';
	@override String get noItemsFound => 'Inga objekt hittades';
}

// Path: logs
class _StringsLogsSv implements _StringsLogsEn {
	_StringsLogsSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Rensa loggar';
	@override String get copyLogs => 'Kopiera loggar';
	@override String get error => 'Fel:';
	@override String get stackTrace => 'Stack trace:';
}

// Path: licenses
class _StringsLicensesSv implements _StringsLicensesEn {
	_StringsLicensesSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Relaterade paket';
	@override String get license => 'Licens';
	@override String licenseNumber({required Object number}) => 'Licens ${number}';
	@override String licensesCount({required Object count}) => '${count} licenser';
}

// Path: navigation
class _StringsNavigationSv implements _StringsNavigationEn {
	_StringsNavigationSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get home => 'Hem';
	@override String get search => 'Sök';
	@override String get libraries => 'Bibliotek';
	@override String get settings => 'Inställningar';
	@override String get downloads => 'Nedladdningar';
}

// Path: downloads
class _StringsDownloadsSv implements _StringsDownloadsEn {
	_StringsDownloadsSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

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
}

// Path: playlists
class _StringsPlaylistsSv implements _StringsPlaylistsEn {
	_StringsPlaylistsSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

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
class _StringsCollectionsSv implements _StringsCollectionsEn {
	_StringsCollectionsSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

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
class _StringsWatchTogetherSv implements _StringsWatchTogetherEn {
	_StringsWatchTogetherSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

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
	@override String get participant => 'deltagare';
	@override String get joinWatchSession => 'Gå med i Tittarsession';
	@override String get enterCodeHint => 'Ange 8-teckens kod';
	@override String get pasteFromClipboard => 'Klistra in från urklipp';
	@override String get pleaseEnterCode => 'Vänligen ange en sessionskod';
	@override String get codeMustBe8Chars => 'Sessionskod måste vara 8 tecken';
	@override String get joinInstructions => 'Ange sessionskoden som delats av värden för att gå med i deras tittarsession.';
	@override String get failedToCreate => 'Det gick inte att skapa session';
	@override String get failedToJoin => 'Det gick inte att gå med i session';
}

// Path: libraries.tabs
class _StringsLibrariesTabsSv implements _StringsLibrariesTabsEn {
	_StringsLibrariesTabsSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Rekommenderat';
	@override String get browse => 'Bläddra';
	@override String get collections => 'Samlingar';
	@override String get playlists => 'Spellistor';
}

// Path: libraries.groupings
class _StringsLibrariesGroupingsSv implements _StringsLibrariesGroupingsEn {
	_StringsLibrariesGroupingsSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get all => 'Alla';
	@override String get movies => 'Filmer';
	@override String get shows => 'Serier';
	@override String get seasons => 'Säsonger';
	@override String get episodes => 'Avsnitt';
	@override String get folders => 'Mappar';
}

// Path: <root>
class _StringsZh implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	_StringsZh.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.zh,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <zh>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	@override late final _StringsZh _root = this; // ignore: unused_field

	// Translations
	@override late final _StringsAppZh app = _StringsAppZh._(_root);
	@override late final _StringsAuthZh auth = _StringsAuthZh._(_root);
	@override late final _StringsCommonZh common = _StringsCommonZh._(_root);
	@override late final _StringsScreensZh screens = _StringsScreensZh._(_root);
	@override late final _StringsUpdateZh update = _StringsUpdateZh._(_root);
	@override late final _StringsSettingsZh settings = _StringsSettingsZh._(_root);
	@override late final _StringsSearchZh search = _StringsSearchZh._(_root);
	@override late final _StringsHotkeysZh hotkeys = _StringsHotkeysZh._(_root);
	@override late final _StringsPinEntryZh pinEntry = _StringsPinEntryZh._(_root);
	@override late final _StringsFileInfoZh fileInfo = _StringsFileInfoZh._(_root);
	@override late final _StringsMediaMenuZh mediaMenu = _StringsMediaMenuZh._(_root);
	@override late final _StringsAccessibilityZh accessibility = _StringsAccessibilityZh._(_root);
	@override late final _StringsTooltipsZh tooltips = _StringsTooltipsZh._(_root);
	@override late final _StringsVideoControlsZh videoControls = _StringsVideoControlsZh._(_root);
	@override late final _StringsUserStatusZh userStatus = _StringsUserStatusZh._(_root);
	@override late final _StringsMessagesZh messages = _StringsMessagesZh._(_root);
	@override late final _StringsSubtitlingStylingZh subtitlingStyling = _StringsSubtitlingStylingZh._(_root);
	@override late final _StringsMpvConfigZh mpvConfig = _StringsMpvConfigZh._(_root);
	@override late final _StringsDialogZh dialog = _StringsDialogZh._(_root);
	@override late final _StringsDiscoverZh discover = _StringsDiscoverZh._(_root);
	@override late final _StringsErrorsZh errors = _StringsErrorsZh._(_root);
	@override late final _StringsLibrariesZh libraries = _StringsLibrariesZh._(_root);
	@override late final _StringsAboutZh about = _StringsAboutZh._(_root);
	@override late final _StringsServerSelectionZh serverSelection = _StringsServerSelectionZh._(_root);
	@override late final _StringsHubDetailZh hubDetail = _StringsHubDetailZh._(_root);
	@override late final _StringsLogsZh logs = _StringsLogsZh._(_root);
	@override late final _StringsLicensesZh licenses = _StringsLicensesZh._(_root);
	@override late final _StringsNavigationZh navigation = _StringsNavigationZh._(_root);
	@override late final _StringsDownloadsZh downloads = _StringsDownloadsZh._(_root);
	@override late final _StringsPlaylistsZh playlists = _StringsPlaylistsZh._(_root);
	@override late final _StringsCollectionsZh collections = _StringsCollectionsZh._(_root);
	@override late final _StringsWatchTogetherZh watchTogether = _StringsWatchTogetherZh._(_root);
}

// Path: app
class _StringsAppZh implements _StringsAppEn {
	_StringsAppZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
	@override String get loading => '加载中...';
}

// Path: auth
class _StringsAuthZh implements _StringsAuthEn {
	_StringsAuthZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => '使用 Plex 登录';
	@override String get showQRCode => '显示二维码';
	@override String get cancel => '取消';
	@override String get authenticate => '验证';
	@override String get retry => '重试';
	@override String get debugEnterToken => '调试：输入 Plex Token';
	@override String get plexTokenLabel => 'Plex 授权令牌 (Auth Token)';
	@override String get plexTokenHint => '输入你的 Plex.tv 令牌';
	@override String get authenticationTimeout => '验证超时。请重试。';
	@override String get scanQRCodeInstruction => '请使用已登录 Plex 的设备扫描此二维码进行验证。';
	@override String get waitingForAuth => '等待验证中...\n请在你的浏览器中完成登录。';
}

// Path: common
class _StringsCommonZh implements _StringsCommonEn {
	_StringsCommonZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get cancel => '取消';
	@override String get save => '保存';
	@override String get close => '关闭';
	@override String get clear => '清除';
	@override String get reset => '重置';
	@override String get later => '稍后';
	@override String get submit => '提交';
	@override String get confirm => '确认';
	@override String get retry => '重试';
	@override String get logout => '登出';
	@override String get unknown => '未知';
	@override String get refresh => '刷新';
	@override String get yes => '是';
	@override String get no => '否';
	@override String get delete => '删除';
	@override String get shuffle => '随机播放';
	@override String get addTo => '添加到...';
}

// Path: screens
class _StringsScreensZh implements _StringsScreensEn {
	_StringsScreensZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get licenses => '许可证';
	@override String get selectServer => '选择服务器';
	@override String get switchProfile => '切换用户';
	@override String get subtitleStyling => '字幕样式';
	@override String get mpvConfig => 'MPV 配置';
	@override String get search => '搜索';
	@override String get logs => '日志';
}

// Path: update
class _StringsUpdateZh implements _StringsUpdateEn {
	_StringsUpdateZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get available => '有可用更新';
	@override String versionAvailable({required Object version}) => '版本 ${version} 已发布';
	@override String currentVersion({required Object version}) => '当前版本: ${version}';
	@override String get skipVersion => '跳过此版本';
	@override String get viewRelease => '查看发布详情';
	@override String get latestVersion => '已安装的版本是可用的最新版本';
	@override String get checkFailed => '无法检查更新';
}

// Path: settings
class _StringsSettingsZh implements _StringsSettingsEn {
	_StringsSettingsZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '设置';
	@override String get language => '语言';
	@override String get theme => '主题';
	@override String get appearance => '外观';
	@override String get videoPlayback => '视频播放';
	@override String get advanced => '高级';
	@override String get episodePosterMode => '剧集海报样式';
	@override String get seriesPoster => '剧集海报';
	@override String get seriesPosterDescription => '为所有剧集显示剧集海报';
	@override String get seasonPoster => '季海报';
	@override String get seasonPosterDescription => '为剧集显示特定季的海报';
	@override String get episodeThumbnail => '剧集缩略图';
	@override String get episodeThumbnailDescription => '显示16:9剧集截图缩略图';
	@override String get showHeroSectionDescription => '在主屏幕上显示精选内容轮播区';
	@override String get secondsLabel => '秒';
	@override String get minutesLabel => '分钟';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => '输入时长 (${min}-${max})';
	@override String get systemTheme => '系统';
	@override String get systemThemeDescription => '跟随系统设置';
	@override String get lightTheme => '浅色';
	@override String get darkTheme => '深色';
	@override String get libraryDensity => '媒体库密度';
	@override String get compact => '紧凑';
	@override String get compactDescription => '卡片更小，显示更多项目';
	@override String get normal => '标准';
	@override String get normalDescription => '默认尺寸';
	@override String get comfortable => '舒适';
	@override String get comfortableDescription => '卡片更大，显示更少项目';
	@override String get viewMode => '视图模式';
	@override String get gridView => '网格视图';
	@override String get gridViewDescription => '以网格布局显示项目';
	@override String get listView => '列表视图';
	@override String get listViewDescription => '以列表布局显示项目';
	@override String get showHeroSection => '显示主要精选区';
	@override String get useGlobalHubs => '使用 Plex 主页布局';
	@override String get useGlobalHubsDescription => '显示与官方 Plex 客户端相同的主页推荐。关闭时将显示按媒体库分类的推荐。';
	@override String get hardwareDecoding => '硬件解码';
	@override String get hardwareDecodingDescription => '如果可用，使用硬件加速';
	@override String get bufferSize => '缓冲区大小';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get subtitleStyling => '字幕样式';
	@override String get subtitleStylingDescription => '调整字幕外观';
	@override String get smallSkipDuration => '短跳过时长';
	@override String get largeSkipDuration => '长跳过时长';
	@override String secondsUnit({required Object seconds}) => '${seconds} 秒';
	@override String get defaultSleepTimer => '默认睡眠定时器';
	@override String minutesUnit({required Object minutes}) => '${minutes} 分钟';
	@override String get rememberTrackSelections => '记住每个剧集/电影的音轨选择';
	@override String get rememberTrackSelectionsDescription => '在播放过程中更改音轨时自动保存音频和字幕语言偏好';
	@override String get videoPlayerControls => '视频播放器控制';
	@override String get keyboardShortcuts => '键盘快捷键';
	@override String get keyboardShortcutsDescription => '自定义键盘快捷键';
	@override String get videoPlayerNavigation => '视频播放器导航';
	@override String get videoPlayerNavigationDescription => '使用方向键导航视频播放器控件';
	@override String get debugLogging => '调试日志';
	@override String get debugLoggingDescription => '启用详细日志记录以便故障排除';
	@override String get viewLogs => '查看日志';
	@override String get viewLogsDescription => '查看应用程序日志';
	@override String get clearCache => '清除缓存';
	@override String get clearCacheDescription => '这将清除所有缓存的图片和数据。清除缓存后，应用程序加载内容可能会变慢。';
	@override String get clearCacheSuccess => '缓存清除成功';
	@override String get resetSettings => '重置设置';
	@override String get resetSettingsDescription => '这会将所有设置重置为其默认值。此操作无法撤销。';
	@override String get resetSettingsSuccess => '设置重置成功';
	@override String get shortcutsReset => '快捷键已重置为默认值';
	@override String get about => '关于';
	@override String get aboutDescription => '应用程序信息和许可证';
	@override String get updates => '更新';
	@override String get updateAvailable => '有可用更新';
	@override String get checkForUpdates => '检查更新';
	@override String get validationErrorEnterNumber => '请输入一个有效的数字';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => '时长必须介于 ${min} 和 ${max} ${unit} 之间';
	@override String shortcutAlreadyAssigned({required Object action}) => '快捷键已被分配给 ${action}';
	@override String shortcutUpdated({required Object action}) => '快捷键已为 ${action} 更新';
	@override String get autoSkip => '自动跳过';
	@override String get autoSkipIntro => '自动跳过片头';
	@override String get autoSkipIntroDescription => '几秒钟后自动跳过片头标记';
	@override String get autoSkipCredits => '自动跳过片尾';
	@override String get autoSkipCreditsDescription => '自动跳过片尾并播放下一集';
	@override String get autoSkipDelay => '自动跳过延迟';
	@override String autoSkipDelayDescription({required Object seconds}) => '自动跳过前等待 ${seconds} 秒';
	@override String get downloads => '下载';
	@override String get downloadLocationDescription => '选择下载内容的存储位置';
	@override String get downloadLocationDefault => '默认（应用存储）';
	@override String get downloadLocationCustom => '自定义位置';
	@override String get selectFolder => '选择文件夹';
	@override String get resetToDefault => '重置为默认';
	@override String currentPath({required Object path}) => '当前: ${path}';
	@override String get downloadLocationChanged => '下载位置已更改';
	@override String get downloadLocationReset => '下载位置已重置为默认';
	@override String get downloadLocationInvalid => '所选文件夹不可写入';
	@override String get downloadLocationSelectError => '选择文件夹失败';
	@override String get downloadOnWifiOnly => '仅在 WiFi 时下载';
	@override String get downloadOnWifiOnlyDescription => '使用蜂窝数据时禁止下载';
	@override String get cellularDownloadBlocked => '蜂窝数据下已禁用下载。请连接 WiFi 或更改设置。';
	@override String get maxVolume => '最大音量';
	@override String get maxVolumeDescription => '允许音量超过 100% 以适应安静的媒体';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get maxVolumeHint => '输入最大音量 (100-300)';
	@override String get discordRichPresence => 'Discord 动态状态';
	@override String get discordRichPresenceDescription => '在 Discord 上显示您正在观看的内容';
}

// Path: search
class _StringsSearchZh implements _StringsSearchEn {
	_StringsSearchZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get hint => '搜索电影、系列、音乐...';
	@override String get tryDifferentTerm => '尝试不同的搜索词';
	@override String get searchYourMedia => '搜索媒体';
	@override String get enterTitleActorOrKeyword => '输入标题、演员或关键词';
}

// Path: hotkeys
class _StringsHotkeysZh implements _StringsHotkeysEn {
	_StringsHotkeysZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => '为 ${actionName} 设置快捷键';
	@override String get clearShortcut => '清除快捷键';
}

// Path: pinEntry
class _StringsPinEntryZh implements _StringsPinEntryEn {
	_StringsPinEntryZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get enterPin => '输入 PIN';
	@override String get showPin => '显示 PIN';
	@override String get hidePin => '隐藏 PIN';
}

// Path: fileInfo
class _StringsFileInfoZh implements _StringsFileInfoEn {
	_StringsFileInfoZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '文件信息';
	@override String get video => '视频';
	@override String get audio => '音频';
	@override String get file => '文件';
	@override String get advanced => '高级';
	@override String get codec => '编解码器';
	@override String get resolution => '分辨率';
	@override String get bitrate => '比特率';
	@override String get frameRate => '帧率';
	@override String get aspectRatio => '宽高比';
	@override String get profile => '配置文件';
	@override String get bitDepth => '位深度';
	@override String get colorSpace => '色彩空间';
	@override String get colorRange => '色彩范围';
	@override String get colorPrimaries => '颜色原色';
	@override String get chromaSubsampling => '色度子采样';
	@override String get channels => '声道';
	@override String get path => '路径';
	@override String get size => '大小';
	@override String get container => '容器';
	@override String get duration => '时长';
	@override String get optimizedForStreaming => '已优化用于流媒体';
	@override String get has64bitOffsets => '64位偏移量';
}

// Path: mediaMenu
class _StringsMediaMenuZh implements _StringsMediaMenuEn {
	_StringsMediaMenuZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => '标记为已观看';
	@override String get markAsUnwatched => '标记为未观看';
	@override String get removeFromContinueWatching => '从继续观看中移除';
	@override String get goToSeries => '转到系列';
	@override String get goToSeason => '转到季';
	@override String get shufflePlay => '随机播放';
	@override String get fileInfo => '文件信息';
}

// Path: accessibility
class _StringsAccessibilityZh implements _StringsAccessibilityEn {
	_StringsAccessibilityZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, 电影';
	@override String mediaCardShow({required Object title}) => '${title}, 电视剧';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => '已观看';
	@override String mediaCardPartiallyWatched({required Object percent}) => '已观看 ${percent} 百分比';
	@override String get mediaCardUnwatched => '未观看';
	@override String get tapToPlay => '点击播放';
}

// Path: tooltips
class _StringsTooltipsZh implements _StringsTooltipsEn {
	_StringsTooltipsZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => '随机播放';
	@override String get markAsWatched => '标记为已观看';
	@override String get markAsUnwatched => '标记为未观看';
}

// Path: videoControls
class _StringsVideoControlsZh implements _StringsVideoControlsEn {
	_StringsVideoControlsZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => '音频';
	@override String get subtitlesLabel => '字幕';
	@override String get resetToZero => '重置为 0ms';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} 播放较晚';
	@override String playsEarlier({required Object label}) => '${label} 播放较早';
	@override String get noOffset => '无偏移';
	@override String get letterbox => '信箱模式（Letterbox）';
	@override String get fillScreen => '填充屏幕';
	@override String get stretch => '拉伸';
	@override String get lockRotation => '锁定旋转';
	@override String get unlockRotation => '解锁旋转';
	@override String get sleepTimer => '睡眠定时器';
	@override String get timerActive => '定时器已激活';
	@override String playbackWillPauseIn({required Object duration}) => '播放将在 ${duration} 后暂停';
	@override String get sleepTimerCompleted => '睡眠定时器已完成 - 播放已暂停';
	@override String get playButton => '播放';
	@override String get pauseButton => '暂停';
	@override String seekBackwardButton({required Object seconds}) => '后退 ${seconds} 秒';
	@override String seekForwardButton({required Object seconds}) => '前进 ${seconds} 秒';
	@override String get previousButton => '上一集';
	@override String get nextButton => '下一集';
	@override String get previousChapterButton => '上一章节';
	@override String get nextChapterButton => '下一章节';
	@override String get muteButton => '静音';
	@override String get unmuteButton => '取消静音';
	@override String get settingsButton => '视频设置';
	@override String get audioTrackButton => '音轨';
	@override String get subtitlesButton => '字幕';
	@override String get chaptersButton => '章节';
	@override String get versionsButton => '视频版本';
	@override String get pipButton => '画中画模式';
	@override String get aspectRatioButton => '宽高比';
	@override String get fullscreenButton => '进入全屏';
	@override String get exitFullscreenButton => '退出全屏';
	@override String get alwaysOnTopButton => '置顶窗口';
	@override String get rotationLockButton => '旋转锁定';
	@override String get timelineSlider => '视频时间轴';
	@override String get volumeSlider => '音量调节';
	@override String get backButton => '返回';
}

// Path: userStatus
class _StringsUserStatusZh implements _StringsUserStatusEn {
	_StringsUserStatusZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get admin => '管理员';
	@override String get restricted => '受限';
	@override String get protected => '受保护';
	@override String get current => '当前';
}

// Path: messages
class _StringsMessagesZh implements _StringsMessagesEn {
	_StringsMessagesZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => '已标记为已观看';
	@override String get markedAsUnwatched => '已标记为未观看';
	@override String get markedAsWatchedOffline => '已标记为已观看 (将在联网时同步)';
	@override String get markedAsUnwatchedOffline => '已标记为未观看 (将在联网时同步)';
	@override String get removedFromContinueWatching => '已从继续观看中移除';
	@override String errorLoading({required Object error}) => '错误: ${error}';
	@override String get fileInfoNotAvailable => '文件信息不可用';
	@override String errorLoadingFileInfo({required Object error}) => '加载文件信息时出错: ${error}';
	@override String get errorLoadingSeries => '加载系列时出错';
	@override String get errorLoadingSeason => '加载季时出错';
	@override String get musicNotSupported => '尚不支持播放音乐';
	@override String get logsCleared => '日志已清除';
	@override String get logsCopied => '日志已复制到剪贴板';
	@override String get noLogsAvailable => '没有可用日志';
	@override String libraryScanning({required Object title}) => '正在扫描 “${title}”...';
	@override String libraryScanStarted({required Object title}) => '已开始扫描 “${title}” 媒体库';
	@override String libraryScanFailed({required Object error}) => '无法扫描媒体库: ${error}';
	@override String metadataRefreshing({required Object title}) => '正在刷新 “${title}” 的元数据...';
	@override String metadataRefreshStarted({required Object title}) => '已开始刷新 “${title}” 的元数据';
	@override String metadataRefreshFailed({required Object error}) => '无法刷新元数据: ${error}';
	@override String get logoutConfirm => '你确定要登出吗？';
	@override String get noSeasonsFound => '未找到季';
	@override String get noEpisodesFound => '在第一季中未找到剧集';
	@override String get noEpisodesFoundGeneral => '未找到剧集';
	@override String get noResultsFound => '未找到结果';
	@override String sleepTimerSet({required Object label}) => '睡眠定时器已设置为 ${label}';
	@override String get noItemsAvailable => '没有可用的项目';
	@override String get failedToCreatePlayQueue => '创建播放队列失败';
	@override String get failedToCreatePlayQueueNoItems => '创建播放队列失败 - 没有项目';
	@override String failedPlayback({required Object action, required Object error}) => '无法${action}: ${error}';
}

// Path: subtitlingStyling
class _StringsSubtitlingStylingZh implements _StringsSubtitlingStylingEn {
	_StringsSubtitlingStylingZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get stylingOptions => '样式选项';
	@override String get fontSize => '字号';
	@override String get textColor => '文本颜色';
	@override String get borderSize => '边框大小';
	@override String get borderColor => '边框颜色';
	@override String get backgroundOpacity => '背景不透明度';
	@override String get backgroundColor => '背景颜色';
}

// Path: mpvConfig
class _StringsMpvConfigZh implements _StringsMpvConfigEn {
	_StringsMpvConfigZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'MPV 配置';
	@override String get description => '高级视频播放器设置';
	@override String get properties => '属性';
	@override String get presets => '预设';
	@override String get noProperties => '未配置任何属性';
	@override String get noPresets => '没有保存的预设';
	@override String get addProperty => '添加属性';
	@override String get editProperty => '编辑属性';
	@override String get deleteProperty => '删除属性';
	@override String get propertyKey => '属性键';
	@override String get propertyKeyHint => '例如 hwdec, demuxer-max-bytes';
	@override String get propertyValue => '属性值';
	@override String get propertyValueHint => '例如 auto, 256000000';
	@override String get saveAsPreset => '保存为预设...';
	@override String get presetName => '预设名称';
	@override String get presetNameHint => '输入此预设的名称';
	@override String get loadPreset => '加载';
	@override String get deletePreset => '删除';
	@override String get presetSaved => '预设已保存';
	@override String get presetLoaded => '预设已加载';
	@override String get presetDeleted => '预设已删除';
	@override String get confirmDeletePreset => '确定要删除此预设吗？';
	@override String get confirmDeleteProperty => '确定要删除此属性吗？';
	@override String entriesCount({required Object count}) => '${count} 条目';
}

// Path: dialog
class _StringsDialogZh implements _StringsDialogEn {
	_StringsDialogZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => '确认操作';
	@override String get cancel => '取消';
	@override String get playNow => '立即播放';
}

// Path: discover
class _StringsDiscoverZh implements _StringsDiscoverEn {
	_StringsDiscoverZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '发现';
	@override String get switchProfile => '切换用户';
	@override String get switchServer => '切换服务器';
	@override String get logout => '登出';
	@override String get noContentAvailable => '没有可用内容';
	@override String get addMediaToLibraries => '请向你的媒体库添加一些媒体';
	@override String get continueWatching => '继续观看';
	@override String get play => '播放';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get pause => '暂停';
	@override String get overview => '概述';
	@override String get cast => '演员表';
	@override String get seasons => '季数';
	@override String get studio => '制作公司';
	@override String get rating => '年龄分级';
	@override String get watched => '已观看';
	@override String episodeCount({required Object count}) => '${count} 集';
	@override String watchedProgress({required Object watched, required Object total}) => '已观看 ${watched}/${total} 集';
	@override String get movie => '电影';
	@override String get tvShow => '电视剧';
	@override String minutesLeft({required Object minutes}) => '剩余 ${minutes} 分钟';
}

// Path: errors
class _StringsErrorsZh implements _StringsErrorsEn {
	_StringsErrorsZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => '搜索失败: ${error}';
	@override String connectionTimeout({required Object context}) => '加载 ${context} 时连接超时';
	@override String get connectionFailed => '无法连接到 Plex 服务器';
	@override String failedToLoad({required Object context, required Object error}) => '无法加载 ${context}: ${error}';
	@override String get noClientAvailable => '没有可用客户端';
	@override String authenticationFailed({required Object error}) => '验证失败: ${error}';
	@override String get couldNotLaunchUrl => '无法打开授权 URL';
	@override String get pleaseEnterToken => '请输入一个令牌';
	@override String get invalidToken => '令牌无效';
	@override String failedToVerifyToken({required Object error}) => '无法验证令牌: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => '无法切换到 ${displayName}';
}

// Path: libraries
class _StringsLibrariesZh implements _StringsLibrariesEn {
	_StringsLibrariesZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '媒体库';
	@override String get scanLibraryFiles => '扫描媒体库文件';
	@override String get scanLibrary => '扫描媒体库';
	@override String get analyze => '分析';
	@override String get analyzeLibrary => '分析媒体库';
	@override String get refreshMetadata => '刷新元数据';
	@override String get emptyTrash => '清空回收站';
	@override String emptyingTrash({required Object title}) => '正在清空 “${title}” 的回收站...';
	@override String trashEmptied({required Object title}) => '已清空 “${title}” 的回收站';
	@override String failedToEmptyTrash({required Object error}) => '无法清空回收站: ${error}';
	@override String analyzing({required Object title}) => '正在分析 “${title}”...';
	@override String analysisStarted({required Object title}) => '已开始分析 “${title}”';
	@override String failedToAnalyze({required Object error}) => '无法分析媒体库: ${error}';
	@override String get noLibrariesFound => '未找到媒体库';
	@override String get thisLibraryIsEmpty => '此媒体库为空';
	@override String get all => '全部';
	@override String get clearAll => '全部清除';
	@override String scanLibraryConfirm({required Object title}) => '确定要扫描 “${title}” 吗？';
	@override String analyzeLibraryConfirm({required Object title}) => '确定要分析 “${title}” 吗？';
	@override String refreshMetadataConfirm({required Object title}) => '确定要刷新 “${title}” 的元数据吗？';
	@override String emptyTrashConfirm({required Object title}) => '确定要清空 “${title}” 的回收站吗？';
	@override String get manageLibraries => '管理媒体库';
	@override String get sort => '排序';
	@override String get sortBy => '排序依据';
	@override String get filters => '筛选器';
	@override String get confirmActionMessage => '确定要执行此操作吗？';
	@override String get showLibrary => '显示媒体库';
	@override String get hideLibrary => '隐藏媒体库';
	@override String get libraryOptions => '媒体库选项';
	@override String get content => '媒体库内容';
	@override String get selectLibrary => '选择媒体库';
	@override String filtersWithCount({required Object count}) => '筛选器（${count}）';
	@override String get noRecommendations => '暂无推荐';
	@override String get noCollections => '此媒体库中没有合集';
	@override String get noFoldersFound => '未找到文件夹';
	@override String get folders => '文件夹';
	@override late final _StringsLibrariesTabsZh tabs = _StringsLibrariesTabsZh._(_root);
	@override late final _StringsLibrariesGroupingsZh groupings = _StringsLibrariesGroupingsZh._(_root);
}

// Path: about
class _StringsAboutZh implements _StringsAboutEn {
	_StringsAboutZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '关于';
	@override String get openSourceLicenses => '开源许可证';
	@override String versionLabel({required Object version}) => '版本 ${version}';
	@override String get appDescription => '一款精美的 Flutter Plex 客户端';
	@override String get viewLicensesDescription => '查看第三方库的许可证';
}

// Path: serverSelection
class _StringsServerSelectionZh implements _StringsServerSelectionEn {
	_StringsServerSelectionZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get allServerConnectionsFailed => '无法连接到任何服务器。请检查你的网络并重试。';
	@override String get noServersFound => '未找到服务器';
	@override String noServersFoundForAccount({required Object username, required Object email}) => '未找到 ${username} (${email}) 的服务器';
	@override String failedToLoadServers({required Object error}) => '无法加载服务器: ${error}';
}

// Path: hubDetail
class _StringsHubDetailZh implements _StringsHubDetailEn {
	_StringsHubDetailZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '标题';
	@override String get releaseYear => '发行年份';
	@override String get dateAdded => '添加日期';
	@override String get rating => '评分';
	@override String get noItemsFound => '未找到项目';
}

// Path: logs
class _StringsLogsZh implements _StringsLogsEn {
	_StringsLogsZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => '清除日志';
	@override String get copyLogs => '复制日志';
	@override String get error => '错误:';
	@override String get stackTrace => '堆栈跟踪 (Stack Trace):';
}

// Path: licenses
class _StringsLicensesZh implements _StringsLicensesEn {
	_StringsLicensesZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => '相关软件包';
	@override String get license => '许可证';
	@override String licenseNumber({required Object number}) => '许可证 ${number}';
	@override String licensesCount({required Object count}) => '${count} 个许可证';
}

// Path: navigation
class _StringsNavigationZh implements _StringsNavigationEn {
	_StringsNavigationZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get home => '主页';
	@override String get search => '搜索';
	@override String get libraries => '媒体库';
	@override String get settings => '设置';
	@override String get downloads => '下载';
}

// Path: downloads
class _StringsDownloadsZh implements _StringsDownloadsEn {
	_StringsDownloadsZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '下载';
	@override String get manage => '管理';
	@override String get tvShows => '电视剧';
	@override String get movies => '电影';
	@override String get noDownloads => '暂无下载';
	@override String get noDownloadsDescription => '下载的内容将在此处显示以供离线观看';
	@override String get downloadNow => '下载';
	@override String get deleteDownload => '删除下载';
	@override String get retryDownload => '重试下载';
	@override String get downloadQueued => '下载已排队';
	@override String episodesQueued({required Object count}) => '${count} 集已加入下载队列';
	@override String get downloadDeleted => '下载已删除';
	@override String deleteConfirm({required Object title}) => '确定要删除 "${title}" 吗？下载的文件将从您的设备中删除。';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => '正在删除 ${title}... (${current}/${total})';
}

// Path: playlists
class _StringsPlaylistsZh implements _StringsPlaylistsEn {
	_StringsPlaylistsZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '播放列表';
	@override String get noPlaylists => '未找到播放列表';
	@override String get create => '创建播放列表';
	@override String get playlistName => '播放列表名称';
	@override String get enterPlaylistName => '输入播放列表名称';
	@override String get delete => '删除播放列表';
	@override String get removeItem => '从播放列表中移除';
	@override String get smartPlaylist => '智能播放列表';
	@override String itemCount({required Object count}) => '${count} 个项目';
	@override String get oneItem => '1 个项目';
	@override String get emptyPlaylist => '此播放列表为空';
	@override String get deleteConfirm => '删除播放列表？';
	@override String deleteMessage({required Object name}) => '确定要删除 "${name}" 吗？';
	@override String get created => '播放列表已创建';
	@override String get deleted => '播放列表已删除';
	@override String get itemAdded => '已添加到播放列表';
	@override String get itemRemoved => '已从播放列表中移除';
	@override String get selectPlaylist => '选择播放列表';
	@override String get createNewPlaylist => '创建新播放列表';
	@override String get errorCreating => '创建播放列表失败';
	@override String get errorDeleting => '删除播放列表失败';
	@override String get errorLoading => '加载播放列表失败';
	@override String get errorAdding => '添加到播放列表失败';
	@override String get errorReordering => '重新排序播放列表项目失败';
	@override String get errorRemoving => '从播放列表中移除失败';
	@override String get playlist => '播放列表';
}

// Path: collections
class _StringsCollectionsZh implements _StringsCollectionsEn {
	_StringsCollectionsZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '合集';
	@override String get collection => '合集';
	@override String get empty => '合集为空';
	@override String get unknownLibrarySection => '无法删除：未知的媒体库分区';
	@override String get deleteCollection => '删除合集';
	@override String deleteConfirm({required Object title}) => '确定要删除"${title}"吗？此操作无法撤销。';
	@override String get deleted => '已删除合集';
	@override String get deleteFailed => '删除合集失败';
	@override String deleteFailedWithError({required Object error}) => '删除合集失败：${error}';
	@override String failedToLoadItems({required Object error}) => '加载合集项目失败：${error}';
	@override String get selectCollection => '选择合集';
	@override String get createNewCollection => '创建新合集';
	@override String get collectionName => '合集名称';
	@override String get enterCollectionName => '输入合集名称';
	@override String get addedToCollection => '已添加到合集';
	@override String get errorAddingToCollection => '添加到合集失败';
	@override String get created => '已创建合集';
	@override String get removeFromCollection => '从合集移除';
	@override String removeFromCollectionConfirm({required Object title}) => '将“${title}”从此合集移除？';
	@override String get removedFromCollection => '已从合集移除';
	@override String get removeFromCollectionFailed => '从合集移除失败';
	@override String removeFromCollectionError({required Object error}) => '从合集移除时出错：${error}';
}

// Path: watchTogether
class _StringsWatchTogetherZh implements _StringsWatchTogetherEn {
	_StringsWatchTogetherZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '一起看';
	@override String get description => '与朋友和家人同步观看内容';
	@override String get createSession => '创建会话';
	@override String get creating => '创建中...';
	@override String get joinSession => '加入会话';
	@override String get joining => '加入中...';
	@override String get controlMode => '控制模式';
	@override String get controlModeQuestion => '谁可以控制播放？';
	@override String get hostOnly => '仅主持人';
	@override String get anyone => '任何人';
	@override String get hostingSession => '主持会话';
	@override String get inSession => '在会话中';
	@override String get sessionCode => '会话代码';
	@override String get hostControlsPlayback => '主持人控制播放';
	@override String get anyoneCanControl => '任何人都可以控制播放';
	@override String get hostControls => '主持人控制';
	@override String get anyoneControls => '任何人控制';
	@override String get participants => '参与者';
	@override String get host => '主持人';
	@override String get hostBadge => '主持人';
	@override String get youAreHost => '你是主持人';
	@override String get watchingWithOthers => '与他人一起观看';
	@override String get endSession => '结束会话';
	@override String get leaveSession => '离开会话';
	@override String get endSessionQuestion => '结束会话？';
	@override String get leaveSessionQuestion => '离开会话？';
	@override String get endSessionConfirm => '这将为所有参与者结束会话。';
	@override String get leaveSessionConfirm => '你将被移出会话。';
	@override String get endSessionConfirmOverlay => '这将为所有参与者结束观看会话。';
	@override String get leaveSessionConfirmOverlay => '你将断开与观看会话的连接。';
	@override String get end => '结束';
	@override String get leave => '离开';
	@override String get syncing => '同步中...';
	@override String get participant => '参与者';
	@override String get joinWatchSession => '加入观看会话';
	@override String get enterCodeHint => '输入8位代码';
	@override String get pasteFromClipboard => '从剪贴板粘贴';
	@override String get pleaseEnterCode => '请输入会话代码';
	@override String get codeMustBe8Chars => '会话代码必须是8个字符';
	@override String get joinInstructions => '输入主持人分享的会话代码以加入他们的观看会话。';
	@override String get failedToCreate => '创建会话失败';
	@override String get failedToJoin => '加入会话失败';
}

// Path: libraries.tabs
class _StringsLibrariesTabsZh implements _StringsLibrariesTabsEn {
	_StringsLibrariesTabsZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get recommended => '推荐';
	@override String get browse => '浏览';
	@override String get collections => '合集';
	@override String get playlists => '播放列表';
}

// Path: libraries.groupings
class _StringsLibrariesGroupingsZh implements _StringsLibrariesGroupingsEn {
	_StringsLibrariesGroupingsZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get all => '全部';
	@override String get movies => '电影';
	@override String get shows => '剧集';
	@override String get seasons => '季';
	@override String get episodes => '集';
	@override String get folders => '文件夹';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.

extension on Translations {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'app.title': return 'Plezy';
			case 'app.loading': return 'Loading...';
			case 'auth.signInWithPlex': return 'Sign in with Plex';
			case 'auth.showQRCode': return 'Show QR Code';
			case 'auth.cancel': return 'Cancel';
			case 'auth.authenticate': return 'Authenticate';
			case 'auth.retry': return 'Retry';
			case 'auth.debugEnterToken': return 'Debug: Enter Plex Token';
			case 'auth.plexTokenLabel': return 'Plex Auth Token';
			case 'auth.plexTokenHint': return 'Enter your Plex.tv token';
			case 'auth.authenticationTimeout': return 'Authentication timed out. Please try again.';
			case 'auth.scanQRCodeInstruction': return 'Scan this QR code with a device logged into Plex to authenticate.';
			case 'auth.waitingForAuth': return 'Waiting for authentication...\nPlease complete sign-in in your browser.';
			case 'common.cancel': return 'Cancel';
			case 'common.save': return 'Save';
			case 'common.close': return 'Close';
			case 'common.clear': return 'Clear';
			case 'common.reset': return 'Reset';
			case 'common.later': return 'Later';
			case 'common.submit': return 'Submit';
			case 'common.confirm': return 'Confirm';
			case 'common.retry': return 'Retry';
			case 'common.logout': return 'Logout';
			case 'common.unknown': return 'Unknown';
			case 'common.refresh': return 'Refresh';
			case 'common.yes': return 'Yes';
			case 'common.no': return 'No';
			case 'common.delete': return 'Delete';
			case 'common.shuffle': return 'Shuffle';
			case 'common.addTo': return 'Add to...';
			case 'screens.licenses': return 'Licenses';
			case 'screens.switchProfile': return 'Switch Profile';
			case 'screens.subtitleStyling': return 'Subtitle Styling';
			case 'screens.mpvConfig': return 'MPV Configuration';
			case 'screens.search': return 'Search';
			case 'screens.logs': return 'Logs';
			case 'update.available': return 'Update Available';
			case 'update.versionAvailable': return ({required Object version}) => 'Version ${version} is available';
			case 'update.currentVersion': return ({required Object version}) => 'Current: ${version}';
			case 'update.skipVersion': return 'Skip This Version';
			case 'update.viewRelease': return 'View Release';
			case 'update.latestVersion': return 'You are on the latest version';
			case 'update.checkFailed': return 'Failed to check for updates';
			case 'settings.title': return 'Settings';
			case 'settings.language': return 'Language';
			case 'settings.theme': return 'Theme';
			case 'settings.appearance': return 'Appearance';
			case 'settings.videoPlayback': return 'Video Playback';
			case 'settings.advanced': return 'Advanced';
			case 'settings.episodePosterMode': return 'Episode Poster Style';
			case 'settings.seriesPoster': return 'Series Poster';
			case 'settings.seriesPosterDescription': return 'Show the series poster for all episodes';
			case 'settings.seasonPoster': return 'Season Poster';
			case 'settings.seasonPosterDescription': return 'Show the season-specific poster for episodes';
			case 'settings.episodeThumbnail': return 'Episode Thumbnail';
			case 'settings.episodeThumbnailDescription': return 'Show 16:9 episode screenshot thumbnails';
			case 'settings.showHeroSectionDescription': return 'Display featured content carousel on home screen';
			case 'settings.secondsLabel': return 'Seconds';
			case 'settings.minutesLabel': return 'Minutes';
			case 'settings.secondsShort': return 's';
			case 'settings.minutesShort': return 'm';
			case 'settings.durationHint': return ({required Object min, required Object max}) => 'Enter duration (${min}-${max})';
			case 'settings.systemTheme': return 'System';
			case 'settings.systemThemeDescription': return 'Follow system settings';
			case 'settings.lightTheme': return 'Light';
			case 'settings.darkTheme': return 'Dark';
			case 'settings.libraryDensity': return 'Library Density';
			case 'settings.compact': return 'Compact';
			case 'settings.compactDescription': return 'Smaller cards, more items visible';
			case 'settings.normal': return 'Normal';
			case 'settings.normalDescription': return 'Default size';
			case 'settings.comfortable': return 'Comfortable';
			case 'settings.comfortableDescription': return 'Larger cards, fewer items visible';
			case 'settings.viewMode': return 'View Mode';
			case 'settings.gridView': return 'Grid';
			case 'settings.gridViewDescription': return 'Display items in a grid layout';
			case 'settings.listView': return 'List';
			case 'settings.listViewDescription': return 'Display items in a list layout';
			case 'settings.showHeroSection': return 'Show Hero Section';
			case 'settings.useGlobalHubs': return 'Use Plex Home Layout';
			case 'settings.useGlobalHubsDescription': return 'Show home page hubs like the official Plex client. When off, shows per-library recommendations instead.';
			case 'settings.hardwareDecoding': return 'Hardware Decoding';
			case 'settings.hardwareDecodingDescription': return 'Use hardware acceleration when available';
			case 'settings.bufferSize': return 'Buffer Size';
			case 'settings.bufferSizeMB': return ({required Object size}) => '${size}MB';
			case 'settings.subtitleStyling': return 'Subtitle Styling';
			case 'settings.subtitleStylingDescription': return 'Customize subtitle appearance';
			case 'settings.smallSkipDuration': return 'Small Skip Duration';
			case 'settings.largeSkipDuration': return 'Large Skip Duration';
			case 'settings.secondsUnit': return ({required Object seconds}) => '${seconds} seconds';
			case 'settings.defaultSleepTimer': return 'Default Sleep Timer';
			case 'settings.minutesUnit': return ({required Object minutes}) => '${minutes} minutes';
			case 'settings.rememberTrackSelections': return 'Remember track selections per show/movie';
			case 'settings.rememberTrackSelectionsDescription': return 'Automatically save audio and subtitle language preferences when you change tracks during playback';
			case 'settings.videoPlayerControls': return 'Video Player Controls';
			case 'settings.keyboardShortcuts': return 'Keyboard Shortcuts';
			case 'settings.keyboardShortcutsDescription': return 'Customize keyboard shortcuts';
			case 'settings.videoPlayerNavigation': return 'Video Player Navigation';
			case 'settings.videoPlayerNavigationDescription': return 'Use arrow keys to navigate video player controls';
			case 'settings.debugLogging': return 'Debug Logging';
			case 'settings.debugLoggingDescription': return 'Enable detailed logging for troubleshooting';
			case 'settings.viewLogs': return 'View Logs';
			case 'settings.viewLogsDescription': return 'View application logs';
			case 'settings.clearCache': return 'Clear Cache';
			case 'settings.clearCacheDescription': return 'This will clear all cached images and data. The app may take longer to load content after clearing the cache.';
			case 'settings.clearCacheSuccess': return 'Cache cleared successfully';
			case 'settings.resetSettings': return 'Reset Settings';
			case 'settings.resetSettingsDescription': return 'This will reset all settings to their default values. This action cannot be undone.';
			case 'settings.resetSettingsSuccess': return 'Settings reset successfully';
			case 'settings.shortcutsReset': return 'Shortcuts reset to defaults';
			case 'settings.about': return 'About';
			case 'settings.aboutDescription': return 'App information and licenses';
			case 'settings.updates': return 'Updates';
			case 'settings.updateAvailable': return 'Update Available';
			case 'settings.checkForUpdates': return 'Check for Updates';
			case 'settings.validationErrorEnterNumber': return 'Please enter a valid number';
			case 'settings.validationErrorDuration': return ({required Object min, required Object max, required Object unit}) => 'Duration must be between ${min} and ${max} ${unit}';
			case 'settings.shortcutAlreadyAssigned': return ({required Object action}) => 'Shortcut already assigned to ${action}';
			case 'settings.shortcutUpdated': return ({required Object action}) => 'Shortcut updated for ${action}';
			case 'settings.autoSkip': return 'Auto Skip';
			case 'settings.autoSkipIntro': return 'Auto Skip Intro';
			case 'settings.autoSkipIntroDescription': return 'Automatically skip intro markers after a few seconds';
			case 'settings.autoSkipCredits': return 'Auto Skip Credits';
			case 'settings.autoSkipCreditsDescription': return 'Automatically skip credits and play next episode';
			case 'settings.autoSkipDelay': return 'Auto Skip Delay';
			case 'settings.autoSkipDelayDescription': return ({required Object seconds}) => 'Wait ${seconds} seconds before auto-skipping';
			case 'settings.downloads': return 'Downloads';
			case 'settings.downloadLocationDescription': return 'Choose where to store downloaded content';
			case 'settings.downloadLocationDefault': return 'Default (App Storage)';
			case 'settings.downloadLocationCustom': return 'Custom Location';
			case 'settings.selectFolder': return 'Select Folder';
			case 'settings.resetToDefault': return 'Reset to Default';
			case 'settings.currentPath': return ({required Object path}) => 'Current: ${path}';
			case 'settings.downloadLocationChanged': return 'Download location changed';
			case 'settings.downloadLocationReset': return 'Download location reset to default';
			case 'settings.downloadLocationInvalid': return 'Selected folder is not writable';
			case 'settings.downloadLocationSelectError': return 'Failed to select folder';
			case 'settings.downloadOnWifiOnly': return 'Download on WiFi only';
			case 'settings.downloadOnWifiOnlyDescription': return 'Prevent downloads when on cellular data';
			case 'settings.cellularDownloadBlocked': return 'Downloads are disabled on cellular data. Connect to WiFi or change the setting.';
			case 'settings.maxVolume': return 'Maximum Volume';
			case 'settings.maxVolumeDescription': return 'Allow volume boost above 100% for quiet media';
			case 'settings.maxVolumePercent': return ({required Object percent}) => '${percent}%';
			case 'settings.maxVolumeHint': return 'Enter max volume (100-300)';
			case 'settings.discordRichPresence': return 'Discord Rich Presence';
			case 'settings.discordRichPresenceDescription': return 'Show what you\'re watching on Discord';
			case 'search.hint': return 'Search movies, shows, music...';
			case 'search.tryDifferentTerm': return 'Try a different search term';
			case 'search.searchYourMedia': return 'Search your media';
			case 'search.enterTitleActorOrKeyword': return 'Enter a title, actor, or keyword';
			case 'hotkeys.setShortcutFor': return ({required Object actionName}) => 'Set Shortcut for ${actionName}';
			case 'hotkeys.clearShortcut': return 'Clear shortcut';
			case 'pinEntry.enterPin': return 'Enter PIN';
			case 'pinEntry.showPin': return 'Show PIN';
			case 'pinEntry.hidePin': return 'Hide PIN';
			case 'fileInfo.title': return 'File Info';
			case 'fileInfo.video': return 'Video';
			case 'fileInfo.audio': return 'Audio';
			case 'fileInfo.file': return 'File';
			case 'fileInfo.advanced': return 'Advanced';
			case 'fileInfo.codec': return 'Codec';
			case 'fileInfo.resolution': return 'Resolution';
			case 'fileInfo.bitrate': return 'Bitrate';
			case 'fileInfo.frameRate': return 'Frame Rate';
			case 'fileInfo.aspectRatio': return 'Aspect Ratio';
			case 'fileInfo.profile': return 'Profile';
			case 'fileInfo.bitDepth': return 'Bit Depth';
			case 'fileInfo.colorSpace': return 'Color Space';
			case 'fileInfo.colorRange': return 'Color Range';
			case 'fileInfo.colorPrimaries': return 'Color Primaries';
			case 'fileInfo.chromaSubsampling': return 'Chroma Subsampling';
			case 'fileInfo.channels': return 'Channels';
			case 'fileInfo.path': return 'Path';
			case 'fileInfo.size': return 'Size';
			case 'fileInfo.container': return 'Container';
			case 'fileInfo.duration': return 'Duration';
			case 'fileInfo.optimizedForStreaming': return 'Optimized for Streaming';
			case 'fileInfo.has64bitOffsets': return '64-bit Offsets';
			case 'mediaMenu.markAsWatched': return 'Mark as Watched';
			case 'mediaMenu.markAsUnwatched': return 'Mark as Unwatched';
			case 'mediaMenu.removeFromContinueWatching': return 'Remove from Continue Watching';
			case 'mediaMenu.goToSeries': return 'Go to series';
			case 'mediaMenu.goToSeason': return 'Go to season';
			case 'mediaMenu.shufflePlay': return 'Shuffle Play';
			case 'mediaMenu.fileInfo': return 'File Info';
			case 'accessibility.mediaCardMovie': return ({required Object title}) => '${title}, movie';
			case 'accessibility.mediaCardShow': return ({required Object title}) => '${title}, TV show';
			case 'accessibility.mediaCardEpisode': return ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
			case 'accessibility.mediaCardSeason': return ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
			case 'accessibility.mediaCardWatched': return 'watched';
			case 'accessibility.mediaCardPartiallyWatched': return ({required Object percent}) => '${percent} percent watched';
			case 'accessibility.mediaCardUnwatched': return 'unwatched';
			case 'accessibility.tapToPlay': return 'Tap to play';
			case 'tooltips.shufflePlay': return 'Shuffle play';
			case 'tooltips.markAsWatched': return 'Mark as watched';
			case 'tooltips.markAsUnwatched': return 'Mark as unwatched';
			case 'videoControls.audioLabel': return 'Audio';
			case 'videoControls.subtitlesLabel': return 'Subtitles';
			case 'videoControls.resetToZero': return 'Reset to 0ms';
			case 'videoControls.addTime': return ({required Object amount, required Object unit}) => '+${amount}${unit}';
			case 'videoControls.minusTime': return ({required Object amount, required Object unit}) => '-${amount}${unit}';
			case 'videoControls.playsLater': return ({required Object label}) => '${label} plays later';
			case 'videoControls.playsEarlier': return ({required Object label}) => '${label} plays earlier';
			case 'videoControls.noOffset': return 'No offset';
			case 'videoControls.letterbox': return 'Letterbox';
			case 'videoControls.fillScreen': return 'Fill screen';
			case 'videoControls.stretch': return 'Stretch';
			case 'videoControls.lockRotation': return 'Lock rotation';
			case 'videoControls.unlockRotation': return 'Unlock rotation';
			case 'videoControls.sleepTimer': return 'Sleep Timer';
			case 'videoControls.timerActive': return 'Timer Active';
			case 'videoControls.playbackWillPauseIn': return ({required Object duration}) => 'Playback will pause in ${duration}';
			case 'videoControls.sleepTimerCompleted': return 'Sleep timer completed - playback paused';
			case 'videoControls.playButton': return 'Play';
			case 'videoControls.pauseButton': return 'Pause';
			case 'videoControls.seekBackwardButton': return ({required Object seconds}) => 'Seek backward ${seconds} seconds';
			case 'videoControls.seekForwardButton': return ({required Object seconds}) => 'Seek forward ${seconds} seconds';
			case 'videoControls.previousButton': return 'Previous episode';
			case 'videoControls.nextButton': return 'Next episode';
			case 'videoControls.previousChapterButton': return 'Previous chapter';
			case 'videoControls.nextChapterButton': return 'Next chapter';
			case 'videoControls.muteButton': return 'Mute';
			case 'videoControls.unmuteButton': return 'Unmute';
			case 'videoControls.settingsButton': return 'Video settings';
			case 'videoControls.audioTrackButton': return 'Audio tracks';
			case 'videoControls.subtitlesButton': return 'Subtitles';
			case 'videoControls.chaptersButton': return 'Chapters';
			case 'videoControls.versionsButton': return 'Video versions';
			case 'videoControls.pipButton': return 'Picture-in-Picture mode';
			case 'videoControls.aspectRatioButton': return 'Aspect ratio';
			case 'videoControls.fullscreenButton': return 'Enter fullscreen';
			case 'videoControls.exitFullscreenButton': return 'Exit fullscreen';
			case 'videoControls.alwaysOnTopButton': return 'Always on top';
			case 'videoControls.rotationLockButton': return 'Rotation lock';
			case 'videoControls.timelineSlider': return 'Video timeline';
			case 'videoControls.volumeSlider': return 'Volume level';
			case 'videoControls.backButton': return 'Back';
			case 'userStatus.admin': return 'Admin';
			case 'userStatus.restricted': return 'Restricted';
			case 'userStatus.protected': return 'Protected';
			case 'userStatus.current': return 'CURRENT';
			case 'messages.markedAsWatched': return 'Marked as watched';
			case 'messages.markedAsUnwatched': return 'Marked as unwatched';
			case 'messages.markedAsWatchedOffline': return 'Marked as watched (will sync when online)';
			case 'messages.markedAsUnwatchedOffline': return 'Marked as unwatched (will sync when online)';
			case 'messages.removedFromContinueWatching': return 'Removed from Continue Watching';
			case 'messages.errorLoading': return ({required Object error}) => 'Error: ${error}';
			case 'messages.fileInfoNotAvailable': return 'File information not available';
			case 'messages.errorLoadingFileInfo': return ({required Object error}) => 'Error loading file info: ${error}';
			case 'messages.errorLoadingSeries': return 'Error loading series';
			case 'messages.errorLoadingSeason': return 'Error loading season';
			case 'messages.musicNotSupported': return 'Music playback is not yet supported';
			case 'messages.logsCleared': return 'Logs cleared';
			case 'messages.logsCopied': return 'Logs copied to clipboard';
			case 'messages.noLogsAvailable': return 'No logs available';
			case 'messages.libraryScanning': return ({required Object title}) => 'Scanning "${title}"...';
			case 'messages.libraryScanStarted': return ({required Object title}) => 'Library scan started for "${title}"';
			case 'messages.libraryScanFailed': return ({required Object error}) => 'Failed to scan library: ${error}';
			case 'messages.metadataRefreshing': return ({required Object title}) => 'Refreshing metadata for "${title}"...';
			case 'messages.metadataRefreshStarted': return ({required Object title}) => 'Metadata refresh started for "${title}"';
			case 'messages.metadataRefreshFailed': return ({required Object error}) => 'Failed to refresh metadata: ${error}';
			case 'messages.logoutConfirm': return 'Are you sure you want to logout?';
			case 'messages.noSeasonsFound': return 'No seasons found';
			case 'messages.noEpisodesFound': return 'No episodes found in first season';
			case 'messages.noEpisodesFoundGeneral': return 'No episodes found';
			case 'messages.noResultsFound': return 'No results found';
			case 'messages.sleepTimerSet': return ({required Object label}) => 'Sleep timer set for ${label}';
			case 'messages.noItemsAvailable': return 'No items available';
			case 'messages.failedToCreatePlayQueue': return 'Failed to create play queue';
			case 'messages.failedToCreatePlayQueueNoItems': return 'Failed to create play queue - no items';
			case 'messages.failedPlayback': return ({required Object action, required Object error}) => 'Failed to ${action}: ${error}';
			case 'subtitlingStyling.stylingOptions': return 'Styling Options';
			case 'subtitlingStyling.fontSize': return 'Font Size';
			case 'subtitlingStyling.textColor': return 'Text Color';
			case 'subtitlingStyling.borderSize': return 'Border Size';
			case 'subtitlingStyling.borderColor': return 'Border Color';
			case 'subtitlingStyling.backgroundOpacity': return 'Background Opacity';
			case 'subtitlingStyling.backgroundColor': return 'Background Color';
			case 'mpvConfig.title': return 'MPV Configuration';
			case 'mpvConfig.description': return 'Advanced video player settings';
			case 'mpvConfig.properties': return 'Properties';
			case 'mpvConfig.presets': return 'Presets';
			case 'mpvConfig.noProperties': return 'No properties configured';
			case 'mpvConfig.noPresets': return 'No saved presets';
			case 'mpvConfig.addProperty': return 'Add Property';
			case 'mpvConfig.editProperty': return 'Edit Property';
			case 'mpvConfig.deleteProperty': return 'Delete Property';
			case 'mpvConfig.propertyKey': return 'Property Key';
			case 'mpvConfig.propertyKeyHint': return 'e.g., hwdec, demuxer-max-bytes';
			case 'mpvConfig.propertyValue': return 'Property Value';
			case 'mpvConfig.propertyValueHint': return 'e.g., auto, 256000000';
			case 'mpvConfig.saveAsPreset': return 'Save as Preset...';
			case 'mpvConfig.presetName': return 'Preset Name';
			case 'mpvConfig.presetNameHint': return 'Enter a name for this preset';
			case 'mpvConfig.loadPreset': return 'Load';
			case 'mpvConfig.deletePreset': return 'Delete';
			case 'mpvConfig.presetSaved': return 'Preset saved';
			case 'mpvConfig.presetLoaded': return 'Preset loaded';
			case 'mpvConfig.presetDeleted': return 'Preset deleted';
			case 'mpvConfig.confirmDeletePreset': return 'Are you sure you want to delete this preset?';
			case 'mpvConfig.confirmDeleteProperty': return 'Are you sure you want to delete this property?';
			case 'mpvConfig.entriesCount': return ({required Object count}) => '${count} entries';
			case 'dialog.confirmAction': return 'Confirm Action';
			case 'dialog.cancel': return 'Cancel';
			case 'dialog.playNow': return 'Play Now';
			case 'discover.title': return 'Discover';
			case 'discover.switchProfile': return 'Switch Profile';
			case 'discover.logout': return 'Logout';
			case 'discover.noContentAvailable': return 'No content available';
			case 'discover.addMediaToLibraries': return 'Add some media to your libraries';
			case 'discover.continueWatching': return 'Continue Watching';
			case 'discover.play': return 'Play';
			case 'discover.playEpisode': return ({required Object season, required Object episode}) => 'S${season}E${episode}';
			case 'discover.pause': return 'Pause';
			case 'discover.overview': return 'Overview';
			case 'discover.cast': return 'Cast';
			case 'discover.seasons': return 'Seasons';
			case 'discover.studio': return 'Studio';
			case 'discover.rating': return 'Rating';
			case 'discover.watched': return 'Watched';
			case 'discover.episodeCount': return ({required Object count}) => '${count} episodes';
			case 'discover.watchedProgress': return ({required Object watched, required Object total}) => '${watched}/${total} watched';
			case 'discover.movie': return 'Movie';
			case 'discover.tvShow': return 'TV Show';
			case 'discover.minutesLeft': return ({required Object minutes}) => '${minutes} min left';
			case 'errors.searchFailed': return ({required Object error}) => 'Search failed: ${error}';
			case 'errors.connectionTimeout': return ({required Object context}) => 'Connection timeout while loading ${context}';
			case 'errors.connectionFailed': return 'Unable to connect to Plex server';
			case 'errors.failedToLoad': return ({required Object context, required Object error}) => 'Failed to load ${context}: ${error}';
			case 'errors.noClientAvailable': return 'No client available';
			case 'errors.authenticationFailed': return ({required Object error}) => 'Authentication failed: ${error}';
			case 'errors.couldNotLaunchUrl': return 'Could not launch auth URL';
			case 'errors.pleaseEnterToken': return 'Please enter a token';
			case 'errors.invalidToken': return 'Invalid token';
			case 'errors.failedToVerifyToken': return ({required Object error}) => 'Failed to verify token: ${error}';
			case 'errors.failedToSwitchProfile': return ({required Object displayName}) => 'Failed to switch to ${displayName}';
			case 'libraries.title': return 'Libraries';
			case 'libraries.scanLibraryFiles': return 'Scan Library Files';
			case 'libraries.scanLibrary': return 'Scan Library';
			case 'libraries.analyze': return 'Analyze';
			case 'libraries.analyzeLibrary': return 'Analyze Library';
			case 'libraries.refreshMetadata': return 'Refresh Metadata';
			case 'libraries.emptyTrash': return 'Empty Trash';
			case 'libraries.emptyingTrash': return ({required Object title}) => 'Emptying trash for "${title}"...';
			case 'libraries.trashEmptied': return ({required Object title}) => 'Trash emptied for "${title}"';
			case 'libraries.failedToEmptyTrash': return ({required Object error}) => 'Failed to empty trash: ${error}';
			case 'libraries.analyzing': return ({required Object title}) => 'Analyzing "${title}"...';
			case 'libraries.analysisStarted': return ({required Object title}) => 'Analysis started for "${title}"';
			case 'libraries.failedToAnalyze': return ({required Object error}) => 'Failed to analyze library: ${error}';
			case 'libraries.noLibrariesFound': return 'No libraries found';
			case 'libraries.thisLibraryIsEmpty': return 'This library is empty';
			case 'libraries.all': return 'All';
			case 'libraries.clearAll': return 'Clear All';
			case 'libraries.scanLibraryConfirm': return ({required Object title}) => 'Are you sure you want to scan "${title}"?';
			case 'libraries.analyzeLibraryConfirm': return ({required Object title}) => 'Are you sure you want to analyze "${title}"?';
			case 'libraries.refreshMetadataConfirm': return ({required Object title}) => 'Are you sure you want to refresh metadata for "${title}"?';
			case 'libraries.emptyTrashConfirm': return ({required Object title}) => 'Are you sure you want to empty trash for "${title}"?';
			case 'libraries.manageLibraries': return 'Manage Libraries';
			case 'libraries.sort': return 'Sort';
			case 'libraries.sortBy': return 'Sort By';
			case 'libraries.filters': return 'Filters';
			case 'libraries.confirmActionMessage': return 'Are you sure you want to perform this action?';
			case 'libraries.showLibrary': return 'Show library';
			case 'libraries.hideLibrary': return 'Hide library';
			case 'libraries.libraryOptions': return 'Library options';
			case 'libraries.content': return 'library content';
			case 'libraries.selectLibrary': return 'Select library';
			case 'libraries.filtersWithCount': return ({required Object count}) => 'Filters (${count})';
			case 'libraries.noRecommendations': return 'No recommendations available';
			case 'libraries.noCollections': return 'No collections in this library';
			case 'libraries.noFoldersFound': return 'No folders found';
			case 'libraries.folders': return 'folders';
			case 'libraries.tabs.recommended': return 'Recommended';
			case 'libraries.tabs.browse': return 'Browse';
			case 'libraries.tabs.collections': return 'Collections';
			case 'libraries.tabs.playlists': return 'Playlists';
			case 'libraries.groupings.all': return 'All';
			case 'libraries.groupings.movies': return 'Movies';
			case 'libraries.groupings.shows': return 'TV Shows';
			case 'libraries.groupings.seasons': return 'Seasons';
			case 'libraries.groupings.episodes': return 'Episodes';
			case 'libraries.groupings.folders': return 'Folders';
			case 'about.title': return 'About';
			case 'about.openSourceLicenses': return 'Open Source Licenses';
			case 'about.versionLabel': return ({required Object version}) => 'Version ${version}';
			case 'about.appDescription': return 'A beautiful Plex client for Flutter';
			case 'about.viewLicensesDescription': return 'View licenses of third-party libraries';
			case 'serverSelection.allServerConnectionsFailed': return 'Failed to connect to any servers. Please check your network and try again.';
			case 'serverSelection.noServersFound': return 'No servers found';
			case 'serverSelection.noServersFoundForAccount': return ({required Object username, required Object email}) => 'No servers found for ${username} (${email})';
			case 'serverSelection.failedToLoadServers': return ({required Object error}) => 'Failed to load servers: ${error}';
			case 'hubDetail.title': return 'Title';
			case 'hubDetail.releaseYear': return 'Release Year';
			case 'hubDetail.dateAdded': return 'Date Added';
			case 'hubDetail.rating': return 'Rating';
			case 'hubDetail.noItemsFound': return 'No items found';
			case 'logs.clearLogs': return 'Clear Logs';
			case 'logs.copyLogs': return 'Copy Logs';
			case 'logs.error': return 'Error:';
			case 'logs.stackTrace': return 'Stack Trace:';
			case 'licenses.relatedPackages': return 'Related Packages';
			case 'licenses.license': return 'License';
			case 'licenses.licenseNumber': return ({required Object number}) => 'License ${number}';
			case 'licenses.licensesCount': return ({required Object count}) => '${count} licenses';
			case 'navigation.home': return 'Home';
			case 'navigation.search': return 'Search';
			case 'navigation.libraries': return 'Libraries';
			case 'navigation.settings': return 'Settings';
			case 'navigation.downloads': return 'Downloads';
			case 'collections.title': return 'Collections';
			case 'collections.collection': return 'Collection';
			case 'collections.empty': return 'Collection is empty';
			case 'collections.unknownLibrarySection': return 'Cannot delete: Unknown library section';
			case 'collections.deleteCollection': return 'Delete Collection';
			case 'collections.deleteConfirm': return ({required Object title}) => 'Are you sure you want to delete "${title}"? This action cannot be undone.';
			case 'collections.deleted': return 'Collection deleted';
			case 'collections.deleteFailed': return 'Failed to delete collection';
			case 'collections.deleteFailedWithError': return ({required Object error}) => 'Failed to delete collection: ${error}';
			case 'collections.failedToLoadItems': return ({required Object error}) => 'Failed to load collection items: ${error}';
			case 'collections.selectCollection': return 'Select Collection';
			case 'collections.createNewCollection': return 'Create New Collection';
			case 'collections.collectionName': return 'Collection Name';
			case 'collections.enterCollectionName': return 'Enter collection name';
			case 'collections.addedToCollection': return 'Added to collection';
			case 'collections.errorAddingToCollection': return 'Failed to add to collection';
			case 'collections.created': return 'Collection created';
			case 'collections.removeFromCollection': return 'Remove from collection';
			case 'collections.removeFromCollectionConfirm': return ({required Object title}) => 'Remove "${title}" from this collection?';
			case 'collections.removedFromCollection': return 'Removed from collection';
			case 'collections.removeFromCollectionFailed': return 'Failed to remove from collection';
			case 'collections.removeFromCollectionError': return ({required Object error}) => 'Error removing from collection: ${error}';
			case 'playlists.title': return 'Playlists';
			case 'playlists.playlist': return 'Playlist';
			case 'playlists.noPlaylists': return 'No playlists found';
			case 'playlists.create': return 'Create Playlist';
			case 'playlists.playlistName': return 'Playlist Name';
			case 'playlists.enterPlaylistName': return 'Enter playlist name';
			case 'playlists.delete': return 'Delete Playlist';
			case 'playlists.removeItem': return 'Remove from Playlist';
			case 'playlists.smartPlaylist': return 'Smart Playlist';
			case 'playlists.itemCount': return ({required Object count}) => '${count} items';
			case 'playlists.oneItem': return '1 item';
			case 'playlists.emptyPlaylist': return 'This playlist is empty';
			case 'playlists.deleteConfirm': return 'Delete Playlist?';
			case 'playlists.deleteMessage': return ({required Object name}) => 'Are you sure you want to delete "${name}"?';
			case 'playlists.created': return 'Playlist created';
			case 'playlists.deleted': return 'Playlist deleted';
			case 'playlists.itemAdded': return 'Added to playlist';
			case 'playlists.itemRemoved': return 'Removed from playlist';
			case 'playlists.selectPlaylist': return 'Select Playlist';
			case 'playlists.createNewPlaylist': return 'Create New Playlist';
			case 'playlists.errorCreating': return 'Failed to create playlist';
			case 'playlists.errorDeleting': return 'Failed to delete playlist';
			case 'playlists.errorLoading': return 'Failed to load playlists';
			case 'playlists.errorAdding': return 'Failed to add to playlist';
			case 'playlists.errorReordering': return 'Failed to reorder playlist item';
			case 'playlists.errorRemoving': return 'Failed to remove from playlist';
			case 'watchTogether.title': return 'Watch Together';
			case 'watchTogether.description': return 'Watch content in sync with friends and family';
			case 'watchTogether.createSession': return 'Create Session';
			case 'watchTogether.creating': return 'Creating...';
			case 'watchTogether.joinSession': return 'Join Session';
			case 'watchTogether.joining': return 'Joining...';
			case 'watchTogether.controlMode': return 'Control Mode';
			case 'watchTogether.controlModeQuestion': return 'Who can control playback?';
			case 'watchTogether.hostOnly': return 'Host Only';
			case 'watchTogether.anyone': return 'Anyone';
			case 'watchTogether.hostingSession': return 'Hosting Session';
			case 'watchTogether.inSession': return 'In Session';
			case 'watchTogether.sessionCode': return 'Session Code';
			case 'watchTogether.hostControlsPlayback': return 'Host controls playback';
			case 'watchTogether.anyoneCanControl': return 'Anyone can control playback';
			case 'watchTogether.hostControls': return 'Host controls';
			case 'watchTogether.anyoneControls': return 'Anyone controls';
			case 'watchTogether.participants': return 'Participants';
			case 'watchTogether.host': return 'Host';
			case 'watchTogether.hostBadge': return 'HOST';
			case 'watchTogether.youAreHost': return 'You are the host';
			case 'watchTogether.watchingWithOthers': return 'Watching with others';
			case 'watchTogether.endSession': return 'End Session';
			case 'watchTogether.leaveSession': return 'Leave Session';
			case 'watchTogether.endSessionQuestion': return 'End Session?';
			case 'watchTogether.leaveSessionQuestion': return 'Leave Session?';
			case 'watchTogether.endSessionConfirm': return 'This will end the session for all participants.';
			case 'watchTogether.leaveSessionConfirm': return 'You will be removed from the session.';
			case 'watchTogether.endSessionConfirmOverlay': return 'This will end the watch session for all participants.';
			case 'watchTogether.leaveSessionConfirmOverlay': return 'You will be disconnected from the watch session.';
			case 'watchTogether.end': return 'End';
			case 'watchTogether.leave': return 'Leave';
			case 'watchTogether.syncing': return 'Syncing...';
			case 'watchTogether.participant': return 'participant';
			case 'watchTogether.joinWatchSession': return 'Join Watch Session';
			case 'watchTogether.enterCodeHint': return 'Enter 8-character code';
			case 'watchTogether.pasteFromClipboard': return 'Paste from clipboard';
			case 'watchTogether.pleaseEnterCode': return 'Please enter a session code';
			case 'watchTogether.codeMustBe8Chars': return 'Session code must be 8 characters';
			case 'watchTogether.joinInstructions': return 'Enter the session code shared by the host to join their watch session.';
			case 'watchTogether.failedToCreate': return 'Failed to create session';
			case 'watchTogether.failedToJoin': return 'Failed to join session';
			case 'downloads.title': return 'Downloads';
			case 'downloads.manage': return 'Manage';
			case 'downloads.tvShows': return 'TV Shows';
			case 'downloads.movies': return 'Movies';
			case 'downloads.noDownloads': return 'No downloads yet';
			case 'downloads.noDownloadsDescription': return 'Downloaded content will appear here for offline viewing';
			case 'downloads.downloadNow': return 'Download';
			case 'downloads.deleteDownload': return 'Delete download';
			case 'downloads.retryDownload': return 'Retry download';
			case 'downloads.downloadQueued': return 'Download queued';
			case 'downloads.episodesQueued': return ({required Object count}) => '${count} episodes queued for download';
			case 'downloads.downloadDeleted': return 'Download deleted';
			case 'downloads.deleteConfirm': return ({required Object title}) => 'Are you sure you want to delete "${title}"? This will remove the downloaded file from your device.';
			case 'downloads.deletingWithProgress': return ({required Object title, required Object current, required Object total}) => 'Deleting ${title}... (${current} of ${total})';
			default: return null;
		}
	}
}

extension on _StringsDe {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'app.title': return 'Plezy';
			case 'app.loading': return 'Lädt...';
			case 'auth.signInWithPlex': return 'Mit Plex anmelden';
			case 'auth.showQRCode': return 'QR-Code anzeigen';
			case 'auth.cancel': return 'Abbrechen';
			case 'auth.authenticate': return 'Authentifizieren';
			case 'auth.retry': return 'Erneut versuchen';
			case 'auth.debugEnterToken': return 'Debug: Plex-Token eingeben';
			case 'auth.plexTokenLabel': return 'Plex-Auth-Token';
			case 'auth.plexTokenHint': return 'Plex.tv-Token eingeben';
			case 'auth.authenticationTimeout': return 'Authentifizierung abgelaufen. Bitte erneut versuchen.';
			case 'auth.scanQRCodeInstruction': return 'Diesen QR-Code mit einem bei Plex angemeldeten Gerät scannen, um zu authentifizieren.';
			case 'auth.waitingForAuth': return 'Warte auf Authentifizierung...\nBitte Anmeldung im Browser abschließen.';
			case 'common.cancel': return 'Abbrechen';
			case 'common.save': return 'Speichern';
			case 'common.close': return 'Schließen';
			case 'common.clear': return 'Leeren';
			case 'common.reset': return 'Zurücksetzen';
			case 'common.later': return 'Später';
			case 'common.submit': return 'Senden';
			case 'common.confirm': return 'Bestätigen';
			case 'common.retry': return 'Erneut versuchen';
			case 'common.logout': return 'Abmelden';
			case 'common.unknown': return 'Unbekannt';
			case 'common.refresh': return 'Aktualisieren';
			case 'common.yes': return 'Ja';
			case 'common.no': return 'Nein';
			case 'common.delete': return 'Löschen';
			case 'common.shuffle': return 'Zufall';
			case 'common.addTo': return 'Hinzufügen zu...';
			case 'screens.licenses': return 'Lizenzen';
			case 'screens.selectServer': return 'Server auswählen';
			case 'screens.switchProfile': return 'Profil wechseln';
			case 'screens.subtitleStyling': return 'Untertitel-Stil';
			case 'screens.mpvConfig': return 'MPV-Konfiguration';
			case 'screens.search': return 'Suche';
			case 'screens.logs': return 'Protokolle';
			case 'update.available': return 'Update verfügbar';
			case 'update.versionAvailable': return ({required Object version}) => 'Version ${version} ist verfügbar';
			case 'update.currentVersion': return ({required Object version}) => 'Aktuell: ${version}';
			case 'update.skipVersion': return 'Diese Version überspringen';
			case 'update.viewRelease': return 'Release anzeigen';
			case 'update.latestVersion': return 'Aktuellste Version installiert';
			case 'update.checkFailed': return 'Fehler bei der Updateprüfung';
			case 'settings.title': return 'Einstellungen';
			case 'settings.language': return 'Sprache';
			case 'settings.theme': return 'Design';
			case 'settings.appearance': return 'Darstellung';
			case 'settings.videoPlayback': return 'Videowiedergabe';
			case 'settings.advanced': return 'Erweitert';
			case 'settings.episodePosterMode': return 'Episoden-Poster-Stil';
			case 'settings.seriesPoster': return 'Serienposter';
			case 'settings.seriesPosterDescription': return 'Zeige das Serienposter für alle Episoden';
			case 'settings.seasonPoster': return 'Staffelposter';
			case 'settings.seasonPosterDescription': return 'Zeige das staffelspezifische Poster für Episoden';
			case 'settings.episodeThumbnail': return 'Episoden-Miniatur';
			case 'settings.episodeThumbnailDescription': return 'Zeige 16:9 Episoden-Vorschaubilder';
			case 'settings.showHeroSectionDescription': return 'Bereich mit empfohlenen Inhalten auf der Startseite anzeigen';
			case 'settings.secondsLabel': return 'Sekunden';
			case 'settings.minutesLabel': return 'Minuten';
			case 'settings.secondsShort': return 's';
			case 'settings.minutesShort': return 'm';
			case 'settings.durationHint': return ({required Object min, required Object max}) => 'Dauer eingeben (${min}-${max})';
			case 'settings.systemTheme': return 'System';
			case 'settings.systemThemeDescription': return 'Systemeinstellungen folgen';
			case 'settings.lightTheme': return 'Hell';
			case 'settings.darkTheme': return 'Dunkel';
			case 'settings.libraryDensity': return 'Mediathekdichte';
			case 'settings.compact': return 'Kompakt';
			case 'settings.compactDescription': return 'Kleinere Karten, mehr Elemente sichtbar';
			case 'settings.normal': return 'Normal';
			case 'settings.normalDescription': return 'Standardgröße';
			case 'settings.comfortable': return 'Großzügig';
			case 'settings.comfortableDescription': return 'Größere Karten, weniger Elemente sichtbar';
			case 'settings.viewMode': return 'Ansichtsmodus';
			case 'settings.gridView': return 'Raster';
			case 'settings.gridViewDescription': return 'Elemente im Raster anzeigen';
			case 'settings.listView': return 'Liste';
			case 'settings.listViewDescription': return 'Elemente in Listenansicht anzeigen';
			case 'settings.showHeroSection': return 'Hero-Bereich anzeigen';
			case 'settings.useGlobalHubs': return 'Plex-Startseiten-Layout verwenden';
			case 'settings.useGlobalHubsDescription': return 'Zeigt Startseiten-Hubs wie der offizielle Plex-Client. Wenn deaktiviert, werden stattdessen Empfehlungen pro Bibliothek angezeigt.';
			case 'settings.hardwareDecoding': return 'Hardware-Decodierung';
			case 'settings.hardwareDecodingDescription': return 'Hardwarebeschleunigung verwenden, sofern verfügbar';
			case 'settings.bufferSize': return 'Puffergröße';
			case 'settings.bufferSizeMB': return ({required Object size}) => '${size}MB';
			case 'settings.subtitleStyling': return 'Untertitel-Stil';
			case 'settings.subtitleStylingDescription': return 'Aussehen von Untertiteln anpassen';
			case 'settings.smallSkipDuration': return 'Kleine Sprungdauer';
			case 'settings.largeSkipDuration': return 'Große Sprungdauer';
			case 'settings.secondsUnit': return ({required Object seconds}) => '${seconds} Sekunden';
			case 'settings.defaultSleepTimer': return 'Standard-Sleep-Timer';
			case 'settings.minutesUnit': return ({required Object minutes}) => '${minutes} Minuten';
			case 'settings.rememberTrackSelections': return 'Spurauswahl pro Serie/Film merken';
			case 'settings.rememberTrackSelectionsDescription': return 'Audio- und Untertitelsprache automatisch speichern, wenn während der Wiedergabe geändert';
			case 'settings.videoPlayerControls': return 'Videoplayer-Steuerung';
			case 'settings.keyboardShortcuts': return 'Tastenkürzel';
			case 'settings.keyboardShortcutsDescription': return 'Tastenkürzel anpassen';
			case 'settings.videoPlayerNavigation': return 'Videoplayer-Navigation';
			case 'settings.videoPlayerNavigationDescription': return 'Pfeiltasten zur Navigation der Videoplayer-Steuerung verwenden';
			case 'settings.debugLogging': return 'Debug-Protokollierung';
			case 'settings.debugLoggingDescription': return 'Detaillierte Protokolle zur Fehleranalyse aktivieren';
			case 'settings.viewLogs': return 'Protokolle anzeigen';
			case 'settings.viewLogsDescription': return 'App-Protokolle anzeigen';
			case 'settings.clearCache': return 'Cache löschen';
			case 'settings.clearCacheDescription': return 'Löscht alle zwischengespeicherten Bilder und Daten. Die App kann danach langsamer laden.';
			case 'settings.clearCacheSuccess': return 'Cache erfolgreich gelöscht';
			case 'settings.resetSettings': return 'Einstellungen zurücksetzen';
			case 'settings.resetSettingsDescription': return 'Alle Einstellungen auf Standard zurücksetzen. Dies kann nicht rückgängig gemacht werden.';
			case 'settings.resetSettingsSuccess': return 'Einstellungen erfolgreich zurückgesetzt';
			case 'settings.shortcutsReset': return 'Tastenkürzel auf Standard zurückgesetzt';
			case 'settings.about': return 'Über';
			case 'settings.aboutDescription': return 'App-Informationen und Lizenzen';
			case 'settings.updates': return 'Updates';
			case 'settings.updateAvailable': return 'Update verfügbar';
			case 'settings.checkForUpdates': return 'Nach Updates suchen';
			case 'settings.validationErrorEnterNumber': return 'Bitte eine gültige Zahl eingeben';
			case 'settings.validationErrorDuration': return ({required Object min, required Object max, required Object unit}) => 'Dauer muss zwischen ${min} und ${max} ${unit} liegen';
			case 'settings.shortcutAlreadyAssigned': return ({required Object action}) => 'Tastenkürzel bereits zugewiesen an ${action}';
			case 'settings.shortcutUpdated': return ({required Object action}) => 'Tastenkürzel aktualisiert für ${action}';
			case 'settings.autoSkip': return 'Automatisches Überspringen';
			case 'settings.autoSkipIntro': return 'Intro automatisch überspringen';
			case 'settings.autoSkipIntroDescription': return 'Intro-Marker nach wenigen Sekunden automatisch überspringen';
			case 'settings.autoSkipCredits': return 'Abspann automatisch überspringen';
			case 'settings.autoSkipCreditsDescription': return 'Abspann automatisch überspringen und nächste Episode abspielen';
			case 'settings.autoSkipDelay': return 'Verzögerung für automatisches Überspringen';
			case 'settings.autoSkipDelayDescription': return ({required Object seconds}) => '${seconds} Sekunden vor dem automatischen Überspringen warten';
			case 'settings.downloads': return 'Downloads';
			case 'settings.downloadLocationDescription': return 'Speicherort für heruntergeladene Inhalte wählen';
			case 'settings.downloadLocationDefault': return 'Standard (App-Speicher)';
			case 'settings.downloadLocationCustom': return 'Benutzerdefinierter Speicherort';
			case 'settings.selectFolder': return 'Ordner auswählen';
			case 'settings.resetToDefault': return 'Auf Standard zurücksetzen';
			case 'settings.currentPath': return ({required Object path}) => 'Aktuell: ${path}';
			case 'settings.downloadLocationChanged': return 'Download-Speicherort geändert';
			case 'settings.downloadLocationReset': return 'Download-Speicherort auf Standard zurückgesetzt';
			case 'settings.downloadLocationInvalid': return 'Ausgewählter Ordner ist nicht beschreibbar';
			case 'settings.downloadLocationSelectError': return 'Ordnerauswahl fehlgeschlagen';
			case 'settings.downloadOnWifiOnly': return 'Nur über WLAN herunterladen';
			case 'settings.downloadOnWifiOnlyDescription': return 'Downloads über mobile Daten verhindern';
			case 'settings.cellularDownloadBlocked': return 'Downloads sind über mobile Daten deaktiviert. Verbinde dich mit einem WLAN oder ändere die Einstellung.';
			case 'settings.maxVolume': return 'Maximale Lautstärke';
			case 'settings.maxVolumeDescription': return 'Lautstärke über 100% für leise Medien erlauben';
			case 'settings.maxVolumePercent': return ({required Object percent}) => '${percent}%';
			case 'settings.maxVolumeHint': return 'Maximale Lautstärke eingeben (100-300)';
			case 'settings.discordRichPresence': return 'Discord Rich Presence';
			case 'settings.discordRichPresenceDescription': return 'Zeige auf Discord, was du gerade schaust';
			case 'search.hint': return 'Filme, Serien, Musik suchen...';
			case 'search.tryDifferentTerm': return 'Anderen Suchbegriff versuchen';
			case 'search.searchYourMedia': return 'In den eigenen Medien suchen';
			case 'search.enterTitleActorOrKeyword': return 'Titel, Schauspieler oder Stichwort eingeben';
			case 'hotkeys.setShortcutFor': return ({required Object actionName}) => 'Tastenkürzel festlegen für ${actionName}';
			case 'hotkeys.clearShortcut': return 'Kürzel löschen';
			case 'pinEntry.enterPin': return 'PIN eingeben';
			case 'pinEntry.showPin': return 'PIN anzeigen';
			case 'pinEntry.hidePin': return 'PIN verbergen';
			case 'fileInfo.title': return 'Dateiinfo';
			case 'fileInfo.video': return 'Video';
			case 'fileInfo.audio': return 'Audio';
			case 'fileInfo.file': return 'Datei';
			case 'fileInfo.advanced': return 'Erweitert';
			case 'fileInfo.codec': return 'Codec';
			case 'fileInfo.resolution': return 'Auflösung';
			case 'fileInfo.bitrate': return 'Bitrate';
			case 'fileInfo.frameRate': return 'Bildrate';
			case 'fileInfo.aspectRatio': return 'Seitenverhältnis';
			case 'fileInfo.profile': return 'Profil';
			case 'fileInfo.bitDepth': return 'Farbtiefe';
			case 'fileInfo.colorSpace': return 'Farbraum';
			case 'fileInfo.colorRange': return 'Farbbereich';
			case 'fileInfo.colorPrimaries': return 'Primärfarben';
			case 'fileInfo.chromaSubsampling': return 'Chroma-Subsampling';
			case 'fileInfo.channels': return 'Kanäle';
			case 'fileInfo.path': return 'Pfad';
			case 'fileInfo.size': return 'Größe';
			case 'fileInfo.container': return 'Container';
			case 'fileInfo.duration': return 'Dauer';
			case 'fileInfo.optimizedForStreaming': return 'Für Streaming optimiert';
			case 'fileInfo.has64bitOffsets': return '64-Bit-Offsets';
			case 'mediaMenu.markAsWatched': return 'Als gesehen markieren';
			case 'mediaMenu.markAsUnwatched': return 'Als ungesehen markieren';
			case 'mediaMenu.removeFromContinueWatching': return 'Aus ‚Weiterschauen‘ entfernen';
			case 'mediaMenu.goToSeries': return 'Zur Serie';
			case 'mediaMenu.goToSeason': return 'Zur Staffel';
			case 'mediaMenu.shufflePlay': return 'Zufallswiedergabe';
			case 'mediaMenu.fileInfo': return 'Dateiinfo';
			case 'accessibility.mediaCardMovie': return ({required Object title}) => '${title}, Film';
			case 'accessibility.mediaCardShow': return ({required Object title}) => '${title}, Serie';
			case 'accessibility.mediaCardEpisode': return ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
			case 'accessibility.mediaCardSeason': return ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
			case 'accessibility.mediaCardWatched': return 'angesehen';
			case 'accessibility.mediaCardPartiallyWatched': return ({required Object percent}) => '${percent} Prozent angesehen';
			case 'accessibility.mediaCardUnwatched': return 'ungeschaut';
			case 'accessibility.tapToPlay': return 'Zum Abspielen tippen';
			case 'tooltips.shufflePlay': return 'Zufallswiedergabe';
			case 'tooltips.markAsWatched': return 'Als gesehen markieren';
			case 'tooltips.markAsUnwatched': return 'Als ungesehen markieren';
			case 'videoControls.audioLabel': return 'Audio';
			case 'videoControls.subtitlesLabel': return 'Untertitel';
			case 'videoControls.resetToZero': return 'Auf 0 ms zurücksetzen';
			case 'videoControls.addTime': return ({required Object amount, required Object unit}) => '+${amount}${unit}';
			case 'videoControls.minusTime': return ({required Object amount, required Object unit}) => '-${amount}${unit}';
			case 'videoControls.playsLater': return ({required Object label}) => '${label} spielt später';
			case 'videoControls.playsEarlier': return ({required Object label}) => '${label} spielt früher';
			case 'videoControls.noOffset': return 'Kein Offset';
			case 'videoControls.letterbox': return 'Letterbox';
			case 'videoControls.fillScreen': return 'Bild füllen';
			case 'videoControls.stretch': return 'Strecken';
			case 'videoControls.lockRotation': return 'Rotation sperren';
			case 'videoControls.unlockRotation': return 'Rotation entsperren';
			case 'videoControls.sleepTimer': return 'Schlaftimer';
			case 'videoControls.timerActive': return 'Schlaftimer aktiv';
			case 'videoControls.playbackWillPauseIn': return ({required Object duration}) => 'Wiedergabe wird in ${duration} pausiert';
			case 'videoControls.sleepTimerCompleted': return 'Schlaftimer abgelaufen – Wiedergabe pausiert';
			case 'videoControls.playButton': return 'Wiedergeben';
			case 'videoControls.pauseButton': return 'Pause';
			case 'videoControls.seekBackwardButton': return ({required Object seconds}) => '${seconds} Sekunden zurück';
			case 'videoControls.seekForwardButton': return ({required Object seconds}) => '${seconds} Sekunden vor';
			case 'videoControls.previousButton': return 'Vorherige Episode';
			case 'videoControls.nextButton': return 'Nächste Episode';
			case 'videoControls.previousChapterButton': return 'Vorheriges Kapitel';
			case 'videoControls.nextChapterButton': return 'Nächstes Kapitel';
			case 'videoControls.muteButton': return 'Stumm schalten';
			case 'videoControls.unmuteButton': return 'Stummschaltung aufheben';
			case 'videoControls.settingsButton': return 'Videoeinstellungen';
			case 'videoControls.audioTrackButton': return 'Tonspuren';
			case 'videoControls.subtitlesButton': return 'Untertitel';
			case 'videoControls.chaptersButton': return 'Kapitel';
			case 'videoControls.versionsButton': return 'Videoversionen';
			case 'videoControls.pipButton': return 'Bild-in-Bild Modus';
			case 'videoControls.aspectRatioButton': return 'Seitenverhältnis';
			case 'videoControls.fullscreenButton': return 'Vollbild aktivieren';
			case 'videoControls.exitFullscreenButton': return 'Vollbild verlassen';
			case 'videoControls.alwaysOnTopButton': return 'Immer im Vordergrund';
			case 'videoControls.rotationLockButton': return 'Dreh­sperre';
			case 'videoControls.timelineSlider': return 'Video-Zeitleiste';
			case 'videoControls.volumeSlider': return 'Lautstärkepegel';
			case 'videoControls.backButton': return 'Zurück';
			case 'userStatus.admin': return 'Eigentümer';
			case 'userStatus.restricted': return 'Eingeschränkt';
			case 'userStatus.protected': return 'Geschützt';
			case 'userStatus.current': return 'AKTUELL';
			case 'messages.markedAsWatched': return 'Als gesehen markiert';
			case 'messages.markedAsUnwatched': return 'Als ungesehen markiert';
			case 'messages.markedAsWatchedOffline': return 'Als gesehen markiert (wird synchronisiert, wenn online)';
			case 'messages.markedAsUnwatchedOffline': return 'Als ungesehen markiert (wird synchronisiert, wenn online)';
			case 'messages.removedFromContinueWatching': return 'Aus ‚Weiterschauen\' entfernt';
			case 'messages.errorLoading': return ({required Object error}) => 'Fehler: ${error}';
			case 'messages.fileInfoNotAvailable': return 'Dateiinfo nicht verfügbar';
			case 'messages.errorLoadingFileInfo': return ({required Object error}) => 'Fehler beim Laden der Dateiinfo: ${error}';
			case 'messages.errorLoadingSeries': return 'Fehler beim Laden der Serie';
			case 'messages.errorLoadingSeason': return 'Fehler beim Laden der Staffel';
			case 'messages.musicNotSupported': return 'Musikwiedergabe wird noch nicht unterstützt';
			case 'messages.logsCleared': return 'Protokolle gelöscht';
			case 'messages.logsCopied': return 'Protokolle in Zwischenablage kopiert';
			case 'messages.noLogsAvailable': return 'Keine Protokolle verfügbar';
			case 'messages.libraryScanning': return ({required Object title}) => 'Scanne „${title}“...';
			case 'messages.libraryScanStarted': return ({required Object title}) => 'Mediathekscan gestartet für „${title}“';
			case 'messages.libraryScanFailed': return ({required Object error}) => 'Fehler beim Scannen der Mediathek: ${error}';
			case 'messages.metadataRefreshing': return ({required Object title}) => 'Metadaten werden aktualisiert für „${title}“...';
			case 'messages.metadataRefreshStarted': return ({required Object title}) => 'Metadaten-Aktualisierung gestartet für „${title}“';
			case 'messages.metadataRefreshFailed': return ({required Object error}) => 'Metadaten konnten nicht aktualisiert werden: ${error}';
			case 'messages.logoutConfirm': return 'Abmeldung wirklich durchführen?';
			case 'messages.noSeasonsFound': return 'Keine Staffeln gefunden';
			case 'messages.noEpisodesFound': return 'Keine Episoden in der ersten Staffel gefunden';
			case 'messages.noEpisodesFoundGeneral': return 'Keine Episoden gefunden';
			case 'messages.noResultsFound': return 'Keine Ergebnisse gefunden';
			case 'messages.sleepTimerSet': return ({required Object label}) => 'Sleep-Timer gesetzt auf ${label}';
			case 'messages.noItemsAvailable': return 'Keine Elemente verfügbar';
			case 'messages.failedToCreatePlayQueue': return 'Wiedergabewarteschlange konnte nicht erstellt werden';
			case 'messages.failedToCreatePlayQueueNoItems': return 'Wiedergabewarteschlange konnte nicht erstellt werden – keine Elemente';
			case 'messages.failedPlayback': return ({required Object action, required Object error}) => 'Wiedergabe für ${action} fehlgeschlagen: ${error}';
			case 'subtitlingStyling.stylingOptions': return 'Stiloptionen';
			case 'subtitlingStyling.fontSize': return 'Schriftgröße';
			case 'subtitlingStyling.textColor': return 'Textfarbe';
			case 'subtitlingStyling.borderSize': return 'Rahmengröße';
			case 'subtitlingStyling.borderColor': return 'Rahmenfarbe';
			case 'subtitlingStyling.backgroundOpacity': return 'Hintergrunddeckkraft';
			case 'subtitlingStyling.backgroundColor': return 'Hintergrundfarbe';
			case 'mpvConfig.title': return 'MPV-Konfiguration';
			case 'mpvConfig.description': return 'Erweiterte Videoplayer-Einstellungen';
			case 'mpvConfig.properties': return 'Eigenschaften';
			case 'mpvConfig.presets': return 'Voreinstellungen';
			case 'mpvConfig.noProperties': return 'Keine Eigenschaften konfiguriert';
			case 'mpvConfig.noPresets': return 'Keine gespeicherten Voreinstellungen';
			case 'mpvConfig.addProperty': return 'Eigenschaft hinzufügen';
			case 'mpvConfig.editProperty': return 'Eigenschaft bearbeiten';
			case 'mpvConfig.deleteProperty': return 'Eigenschaft löschen';
			case 'mpvConfig.propertyKey': return 'Eigenschaftsschlüssel';
			case 'mpvConfig.propertyKeyHint': return 'z.B. hwdec, demuxer-max-bytes';
			case 'mpvConfig.propertyValue': return 'Eigenschaftswert';
			case 'mpvConfig.propertyValueHint': return 'z.B. auto, 256000000';
			case 'mpvConfig.saveAsPreset': return 'Als Voreinstellung speichern...';
			case 'mpvConfig.presetName': return 'Name der Voreinstellung';
			case 'mpvConfig.presetNameHint': return 'Namen für diese Voreinstellung eingeben';
			case 'mpvConfig.loadPreset': return 'Laden';
			case 'mpvConfig.deletePreset': return 'Löschen';
			case 'mpvConfig.presetSaved': return 'Voreinstellung gespeichert';
			case 'mpvConfig.presetLoaded': return 'Voreinstellung geladen';
			case 'mpvConfig.presetDeleted': return 'Voreinstellung gelöscht';
			case 'mpvConfig.confirmDeletePreset': return 'Möchten Sie diese Voreinstellung wirklich löschen?';
			case 'mpvConfig.confirmDeleteProperty': return 'Möchten Sie diese Eigenschaft wirklich löschen?';
			case 'mpvConfig.entriesCount': return ({required Object count}) => '${count} Einträge';
			case 'dialog.confirmAction': return 'Aktion bestätigen';
			case 'dialog.cancel': return 'Abbrechen';
			case 'dialog.playNow': return 'Jetzt abspielen';
			case 'discover.title': return 'Entdecken';
			case 'discover.switchProfile': return 'Profil wechseln';
			case 'discover.switchServer': return 'Server wechseln';
			case 'discover.logout': return 'Abmelden';
			case 'discover.noContentAvailable': return 'Kein Inhalt verfügbar';
			case 'discover.addMediaToLibraries': return 'Medien zur Mediathek hinzufügen';
			case 'discover.continueWatching': return 'Weiterschauen';
			case 'discover.play': return 'Abspielen';
			case 'discover.playEpisode': return ({required Object season, required Object episode}) => 'S${season}E${episode}';
			case 'discover.pause': return 'Pause';
			case 'discover.overview': return 'Übersicht';
			case 'discover.cast': return 'Besetzung';
			case 'discover.seasons': return 'Staffeln';
			case 'discover.studio': return 'Studio';
			case 'discover.rating': return 'Altersfreigabe';
			case 'discover.watched': return 'Gesehen';
			case 'discover.episodeCount': return ({required Object count}) => '${count} Episoden';
			case 'discover.watchedProgress': return ({required Object watched, required Object total}) => '${watched} von ${total} gesehen';
			case 'discover.movie': return 'Film';
			case 'discover.tvShow': return 'Serie';
			case 'discover.minutesLeft': return ({required Object minutes}) => '${minutes} Min übrig';
			case 'errors.searchFailed': return ({required Object error}) => 'Suche fehlgeschlagen: ${error}';
			case 'errors.connectionTimeout': return ({required Object context}) => 'Zeitüberschreitung beim Laden von ${context}';
			case 'errors.connectionFailed': return 'Verbindung zum Plex-Server fehlgeschlagen';
			case 'errors.failedToLoad': return ({required Object context, required Object error}) => 'Fehler beim Laden von ${context}: ${error}';
			case 'errors.noClientAvailable': return 'Kein Client verfügbar';
			case 'errors.authenticationFailed': return ({required Object error}) => 'Authentifizierung fehlgeschlagen: ${error}';
			case 'errors.couldNotLaunchUrl': return 'Auth-URL konnte nicht geöffnet werden';
			case 'errors.pleaseEnterToken': return 'Bitte Token eingeben';
			case 'errors.invalidToken': return 'Ungültiges Token';
			case 'errors.failedToVerifyToken': return ({required Object error}) => 'Token-Verifizierung fehlgeschlagen: ${error}';
			case 'errors.failedToSwitchProfile': return ({required Object displayName}) => 'Profilwechsel zu ${displayName} fehlgeschlagen';
			case 'libraries.title': return 'Mediatheken';
			case 'libraries.scanLibraryFiles': return 'Mediatheksdateien scannen';
			case 'libraries.scanLibrary': return 'Mediathek scannen';
			case 'libraries.analyze': return 'Analysieren';
			case 'libraries.analyzeLibrary': return 'Mediathek analysieren';
			case 'libraries.refreshMetadata': return 'Metadaten aktualisieren';
			case 'libraries.emptyTrash': return 'Papierkorb leeren';
			case 'libraries.emptyingTrash': return ({required Object title}) => 'Papierkorb für „${title}“ wird geleert...';
			case 'libraries.trashEmptied': return ({required Object title}) => 'Papierkorb für „${title}“ geleert';
			case 'libraries.failedToEmptyTrash': return ({required Object error}) => 'Papierkorb konnte nicht geleert werden: ${error}';
			case 'libraries.analyzing': return ({required Object title}) => 'Analysiere „${title}“...';
			case 'libraries.analysisStarted': return ({required Object title}) => 'Analyse gestartet für „${title}“';
			case 'libraries.failedToAnalyze': return ({required Object error}) => 'Analyse der Mediathek fehlgeschlagen: ${error}';
			case 'libraries.noLibrariesFound': return 'Keine Mediatheken gefunden';
			case 'libraries.thisLibraryIsEmpty': return 'Diese Mediathek ist leer';
			case 'libraries.all': return 'Alle';
			case 'libraries.clearAll': return 'Alle löschen';
			case 'libraries.scanLibraryConfirm': return ({required Object title}) => '„${title}“ wirklich scannen?';
			case 'libraries.analyzeLibraryConfirm': return ({required Object title}) => '„${title}“ wirklich analysieren?';
			case 'libraries.refreshMetadataConfirm': return ({required Object title}) => 'Metadaten für „${title}“ wirklich aktualisieren?';
			case 'libraries.emptyTrashConfirm': return ({required Object title}) => 'Papierkorb für „${title}“ wirklich leeren?';
			case 'libraries.manageLibraries': return 'Mediatheken verwalten';
			case 'libraries.sort': return 'Sortieren';
			case 'libraries.sortBy': return 'Sortieren nach';
			case 'libraries.filters': return 'Filter';
			case 'libraries.confirmActionMessage': return 'Aktion wirklich durchführen?';
			case 'libraries.showLibrary': return 'Mediathek anzeigen';
			case 'libraries.hideLibrary': return 'Mediathek ausblenden';
			case 'libraries.libraryOptions': return 'Mediatheksoptionen';
			case 'libraries.content': return 'Bibliotheksinhalt';
			case 'libraries.selectLibrary': return 'Bibliothek auswählen';
			case 'libraries.filtersWithCount': return ({required Object count}) => 'Filter (${count})';
			case 'libraries.noRecommendations': return 'Keine Empfehlungen verfügbar';
			case 'libraries.noCollections': return 'Keine Sammlungen in dieser Mediathek';
			case 'libraries.noFoldersFound': return 'Keine Ordner gefunden';
			case 'libraries.folders': return 'Ordner';
			case 'libraries.tabs.recommended': return 'Empfohlen';
			case 'libraries.tabs.browse': return 'Durchsuchen';
			case 'libraries.tabs.collections': return 'Sammlungen';
			case 'libraries.tabs.playlists': return 'Wiedergabelisten';
			case 'libraries.groupings.all': return 'Alle';
			case 'libraries.groupings.movies': return 'Filme';
			case 'libraries.groupings.shows': return 'Serien';
			case 'libraries.groupings.seasons': return 'Staffeln';
			case 'libraries.groupings.episodes': return 'Episoden';
			case 'libraries.groupings.folders': return 'Ordner';
			case 'about.title': return 'Über';
			case 'about.openSourceLicenses': return 'Open-Source-Lizenzen';
			case 'about.versionLabel': return ({required Object version}) => 'Version ${version}';
			case 'about.appDescription': return 'Ein schöner Plex-Client für Flutter';
			case 'about.viewLicensesDescription': return 'Lizenzen von Drittanbieter-Bibliotheken anzeigen';
			case 'serverSelection.allServerConnectionsFailed': return 'Verbindung zu allen Servern fehlgeschlagen. Bitte Netzwerk prüfen und erneut versuchen.';
			case 'serverSelection.noServersFound': return 'Keine Server gefunden';
			case 'serverSelection.noServersFoundForAccount': return ({required Object username, required Object email}) => 'Keine Server gefunden für ${username} (${email})';
			case 'serverSelection.failedToLoadServers': return ({required Object error}) => 'Server konnten nicht geladen werden: ${error}';
			case 'hubDetail.title': return 'Titel';
			case 'hubDetail.releaseYear': return 'Erscheinungsjahr';
			case 'hubDetail.dateAdded': return 'Hinzugefügt am';
			case 'hubDetail.rating': return 'Bewertung';
			case 'hubDetail.noItemsFound': return 'Keine Elemente gefunden';
			case 'logs.clearLogs': return 'Protokolle löschen';
			case 'logs.copyLogs': return 'Protokolle kopieren';
			case 'logs.error': return 'Fehler:';
			case 'logs.stackTrace': return 'Stacktrace:';
			case 'licenses.relatedPackages': return 'Verwandte Pakete';
			case 'licenses.license': return 'Lizenz';
			case 'licenses.licenseNumber': return ({required Object number}) => 'Lizenz ${number}';
			case 'licenses.licensesCount': return ({required Object count}) => '${count} Lizenzen';
			case 'navigation.home': return 'Start';
			case 'navigation.search': return 'Suche';
			case 'navigation.libraries': return 'Mediatheken';
			case 'navigation.settings': return 'Einstellungen';
			case 'navigation.downloads': return 'Downloads';
			case 'downloads.title': return 'Downloads';
			case 'downloads.manage': return 'Verwalten';
			case 'downloads.tvShows': return 'Serien';
			case 'downloads.movies': return 'Filme';
			case 'downloads.noDownloads': return 'Noch keine Downloads';
			case 'downloads.noDownloadsDescription': return 'Heruntergeladene Inhalte werden hier für die Offline-Wiedergabe angezeigt';
			case 'downloads.downloadNow': return 'Herunterladen';
			case 'downloads.deleteDownload': return 'Download löschen';
			case 'downloads.retryDownload': return 'Download wiederholen';
			case 'downloads.downloadQueued': return 'Download in Warteschlange';
			case 'downloads.episodesQueued': return ({required Object count}) => '${count} Episoden zum Download hinzugefügt';
			case 'downloads.downloadDeleted': return 'Download gelöscht';
			case 'downloads.deleteConfirm': return ({required Object title}) => 'Möchtest du "${title}" wirklich löschen? Die heruntergeladene Datei wird von deinem Gerät entfernt.';
			case 'downloads.deletingWithProgress': return ({required Object title, required Object current, required Object total}) => 'Lösche ${title}... (${current} von ${total})';
			case 'playlists.title': return 'Wiedergabelisten';
			case 'playlists.noPlaylists': return 'Keine Wiedergabelisten gefunden';
			case 'playlists.create': return 'Wiedergabeliste erstellen';
			case 'playlists.playlistName': return 'Name der Wiedergabeliste';
			case 'playlists.enterPlaylistName': return 'Name der Wiedergabeliste eingeben';
			case 'playlists.delete': return 'Wiedergabeliste löschen';
			case 'playlists.removeItem': return 'Aus Wiedergabeliste entfernen';
			case 'playlists.smartPlaylist': return 'Intelligente Wiedergabeliste';
			case 'playlists.itemCount': return ({required Object count}) => '${count} Elemente';
			case 'playlists.oneItem': return '1 Element';
			case 'playlists.emptyPlaylist': return 'Diese Wiedergabeliste ist leer';
			case 'playlists.deleteConfirm': return 'Wiedergabeliste löschen?';
			case 'playlists.deleteMessage': return ({required Object name}) => 'Soll "${name}" wirklich gelöscht werden?';
			case 'playlists.created': return 'Wiedergabeliste erstellt';
			case 'playlists.deleted': return 'Wiedergabeliste gelöscht';
			case 'playlists.itemAdded': return 'Zur Wiedergabeliste hinzugefügt';
			case 'playlists.itemRemoved': return 'Aus Wiedergabeliste entfernt';
			case 'playlists.selectPlaylist': return 'Wiedergabeliste auswählen';
			case 'playlists.createNewPlaylist': return 'Neue Wiedergabeliste erstellen';
			case 'playlists.errorCreating': return 'Wiedergabeliste konnte nicht erstellt werden';
			case 'playlists.errorDeleting': return 'Wiedergabeliste konnte nicht gelöscht werden';
			case 'playlists.errorLoading': return 'Wiedergabelisten konnten nicht geladen werden';
			case 'playlists.errorAdding': return 'Konnte nicht zur Wiedergabeliste hinzugefügt werden';
			case 'playlists.errorReordering': return 'Element der Wiedergabeliste konnte nicht neu geordnet werden';
			case 'playlists.errorRemoving': return 'Konnte nicht aus der Wiedergabeliste entfernt werden';
			case 'playlists.playlist': return 'Wiedergabeliste';
			case 'collections.title': return 'Sammlungen';
			case 'collections.collection': return 'Sammlung';
			case 'collections.empty': return 'Sammlung ist leer';
			case 'collections.unknownLibrarySection': return 'Löschen nicht möglich: Unbekannte Bibliothekssektion';
			case 'collections.deleteCollection': return 'Sammlung löschen';
			case 'collections.deleteConfirm': return ({required Object title}) => 'Sind Sie sicher, dass Sie "${title}" löschen möchten? Dies kann nicht rückgängig gemacht werden.';
			case 'collections.deleted': return 'Sammlung gelöscht';
			case 'collections.deleteFailed': return 'Sammlung konnte nicht gelöscht werden';
			case 'collections.deleteFailedWithError': return ({required Object error}) => 'Sammlung konnte nicht gelöscht werden: ${error}';
			case 'collections.failedToLoadItems': return ({required Object error}) => 'Sammlungselemente konnten nicht geladen werden: ${error}';
			case 'collections.selectCollection': return 'Sammlung auswählen';
			case 'collections.createNewCollection': return 'Neue Sammlung erstellen';
			case 'collections.collectionName': return 'Sammlungsname';
			case 'collections.enterCollectionName': return 'Sammlungsnamen eingeben';
			case 'collections.addedToCollection': return 'Zur Sammlung hinzugefügt';
			case 'collections.errorAddingToCollection': return 'Fehler beim Hinzufügen zur Sammlung';
			case 'collections.created': return 'Sammlung erstellt';
			case 'collections.removeFromCollection': return 'Aus Sammlung entfernen';
			case 'collections.removeFromCollectionConfirm': return ({required Object title}) => '"${title}" aus dieser Sammlung entfernen?';
			case 'collections.removedFromCollection': return 'Aus Sammlung entfernt';
			case 'collections.removeFromCollectionFailed': return 'Entfernen aus Sammlung fehlgeschlagen';
			case 'collections.removeFromCollectionError': return ({required Object error}) => 'Fehler beim Entfernen aus der Sammlung: ${error}';
			case 'watchTogether.title': return 'Gemeinsam Schauen';
			case 'watchTogether.description': return 'Inhalte synchron mit Freunden und Familie schauen';
			case 'watchTogether.createSession': return 'Sitzung Erstellen';
			case 'watchTogether.creating': return 'Erstellen...';
			case 'watchTogether.joinSession': return 'Sitzung Beitreten';
			case 'watchTogether.joining': return 'Beitreten...';
			case 'watchTogether.controlMode': return 'Steuerungsmodus';
			case 'watchTogether.controlModeQuestion': return 'Wer kann die Wiedergabe steuern?';
			case 'watchTogether.hostOnly': return 'Nur Host';
			case 'watchTogether.anyone': return 'Alle';
			case 'watchTogether.hostingSession': return 'Sitzung Hosten';
			case 'watchTogether.inSession': return 'In Sitzung';
			case 'watchTogether.sessionCode': return 'Sitzungscode';
			case 'watchTogether.hostControlsPlayback': return 'Host steuert die Wiedergabe';
			case 'watchTogether.anyoneCanControl': return 'Alle können die Wiedergabe steuern';
			case 'watchTogether.hostControls': return 'Host steuert';
			case 'watchTogether.anyoneControls': return 'Alle steuern';
			case 'watchTogether.participants': return 'Teilnehmer';
			case 'watchTogether.host': return 'Host';
			case 'watchTogether.hostBadge': return 'HOST';
			case 'watchTogether.youAreHost': return 'Du bist der Host';
			case 'watchTogether.watchingWithOthers': return 'Mit anderen schauen';
			case 'watchTogether.endSession': return 'Sitzung Beenden';
			case 'watchTogether.leaveSession': return 'Sitzung Verlassen';
			case 'watchTogether.endSessionQuestion': return 'Sitzung Beenden?';
			case 'watchTogether.leaveSessionQuestion': return 'Sitzung Verlassen?';
			case 'watchTogether.endSessionConfirm': return 'Dies beendet die Sitzung für alle Teilnehmer.';
			case 'watchTogether.leaveSessionConfirm': return 'Du wirst aus der Sitzung entfernt.';
			case 'watchTogether.endSessionConfirmOverlay': return 'Dies beendet die Schausitzung für alle Teilnehmer.';
			case 'watchTogether.leaveSessionConfirmOverlay': return 'Du wirst von der Schausitzung getrennt.';
			case 'watchTogether.end': return 'Beenden';
			case 'watchTogether.leave': return 'Verlassen';
			case 'watchTogether.syncing': return 'Synchronisieren...';
			case 'watchTogether.participant': return 'Teilnehmer';
			case 'watchTogether.joinWatchSession': return 'Schausitzung Beitreten';
			case 'watchTogether.enterCodeHint': return '8-stelligen Code eingeben';
			case 'watchTogether.pasteFromClipboard': return 'Aus Zwischenablage einfügen';
			case 'watchTogether.pleaseEnterCode': return 'Bitte gib einen Sitzungscode ein';
			case 'watchTogether.codeMustBe8Chars': return 'Sitzungscode muss 8 Zeichen haben';
			case 'watchTogether.joinInstructions': return 'Gib den vom Host geteilten Sitzungscode ein, um seiner Schausitzung beizutreten.';
			case 'watchTogether.failedToCreate': return 'Sitzung konnte nicht erstellt werden';
			case 'watchTogether.failedToJoin': return 'Sitzung konnte nicht beigetreten werden';
			default: return null;
		}
	}
}

extension on _StringsIt {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'app.title': return 'Plezy';
			case 'app.loading': return 'Caricamento...';
			case 'auth.signInWithPlex': return 'Accedi con Plex';
			case 'auth.showQRCode': return 'Mostra QR Code';
			case 'auth.cancel': return 'Cancella';
			case 'auth.authenticate': return 'Autenticazione';
			case 'auth.retry': return 'Riprova';
			case 'auth.debugEnterToken': return 'Debug: Inserisci Token Plex';
			case 'auth.plexTokenLabel': return 'Token Auth Plex';
			case 'auth.plexTokenHint': return 'Inserisci il tuo token di Plex.tv';
			case 'auth.authenticationTimeout': return 'Autenticazione scaduta. Riprova.';
			case 'auth.scanQRCodeInstruction': return 'Scansiona questo QR code con un dispositivo connesso a Plex per autenticarti.';
			case 'auth.waitingForAuth': return 'In attesa di autenticazione...\nCompleta l\'accesso dal tuo browser.';
			case 'common.cancel': return 'Cancella';
			case 'common.save': return 'Salva';
			case 'common.close': return 'Chiudi';
			case 'common.clear': return 'Pulisci';
			case 'common.reset': return 'Ripristina';
			case 'common.later': return 'Più tardi';
			case 'common.submit': return 'Invia';
			case 'common.confirm': return 'Conferma';
			case 'common.retry': return 'Riprova';
			case 'common.logout': return 'Disconnetti';
			case 'common.unknown': return 'Sconosciuto';
			case 'common.refresh': return 'Aggiorna';
			case 'common.yes': return 'Sì';
			case 'common.no': return 'No';
			case 'common.delete': return 'Elimina';
			case 'common.shuffle': return 'Casuale';
			case 'common.addTo': return 'Aggiungi a...';
			case 'screens.licenses': return 'Licenze';
			case 'screens.selectServer': return 'Seleziona server';
			case 'screens.switchProfile': return 'Cambia profilo';
			case 'screens.subtitleStyling': return 'Stile sottotitoli';
			case 'screens.mpvConfig': return 'Configurazione MPV';
			case 'screens.search': return 'Cerca';
			case 'screens.logs': return 'Registro';
			case 'update.available': return 'Aggiornamento disponibile';
			case 'update.versionAvailable': return ({required Object version}) => 'Versione ${version} disponibile';
			case 'update.currentVersion': return ({required Object version}) => 'Corrente: ${version}';
			case 'update.skipVersion': return 'Salta questa versione';
			case 'update.viewRelease': return 'Visualizza dettagli release';
			case 'update.latestVersion': return 'La versione installata è l\'ultima disponibile';
			case 'update.checkFailed': return 'Impossibile controllare gli aggiornamenti';
			case 'settings.title': return 'Impostazioni';
			case 'settings.language': return 'Lingua';
			case 'settings.theme': return 'Tema';
			case 'settings.appearance': return 'Aspetto';
			case 'settings.videoPlayback': return 'Riproduzione video';
			case 'settings.advanced': return 'Avanzate';
			case 'settings.episodePosterMode': return 'Stile poster episodio';
			case 'settings.seriesPoster': return 'Poster della serie';
			case 'settings.seriesPosterDescription': return 'Mostra il poster della serie per tutti gli episodi';
			case 'settings.seasonPoster': return 'Poster della stagione';
			case 'settings.seasonPosterDescription': return 'Mostra il poster specifico della stagione per gli episodi';
			case 'settings.episodeThumbnail': return 'Miniatura episodio';
			case 'settings.episodeThumbnailDescription': return 'Mostra miniature 16:9 degli episodi';
			case 'settings.showHeroSectionDescription': return 'Visualizza il carosello dei contenuti in primo piano sulla schermata iniziale';
			case 'settings.secondsLabel': return 'Secondi';
			case 'settings.minutesLabel': return 'Minuti';
			case 'settings.secondsShort': return 's';
			case 'settings.minutesShort': return 'm';
			case 'settings.durationHint': return ({required Object min, required Object max}) => 'Inserisci durata (${min}-${max})';
			case 'settings.systemTheme': return 'Sistema';
			case 'settings.systemThemeDescription': return 'Segui le impostazioni di sistema';
			case 'settings.lightTheme': return 'Chiaro';
			case 'settings.darkTheme': return 'Scuro';
			case 'settings.libraryDensity': return 'Densità libreria';
			case 'settings.compact': return 'Compatta';
			case 'settings.compactDescription': return 'Schede più piccole, più elementi visibili';
			case 'settings.normal': return 'Normale';
			case 'settings.normalDescription': return 'Dimensione predefinita';
			case 'settings.comfortable': return 'Comoda';
			case 'settings.comfortableDescription': return 'Schede più grandi, meno elementi visibili';
			case 'settings.viewMode': return 'Modalità di visualizzazione';
			case 'settings.gridView': return 'Griglia';
			case 'settings.gridViewDescription': return 'Visualizza gli elementi in un layout a griglia';
			case 'settings.listView': return 'Elenco';
			case 'settings.listViewDescription': return 'Visualizza gli elementi in un layout a elenco';
			case 'settings.showHeroSection': return 'Mostra sezione principale';
			case 'settings.useGlobalHubs': return 'Usa layout Home di Plex';
			case 'settings.useGlobalHubsDescription': return 'Mostra gli hub della home page come il client Plex ufficiale. Se disattivato, mostra invece i suggerimenti per libreria.';
			case 'settings.hardwareDecoding': return 'Decodifica Hardware';
			case 'settings.hardwareDecodingDescription': return 'Utilizza l\'accelerazione hardware quando disponibile';
			case 'settings.bufferSize': return 'Dimensione buffer';
			case 'settings.bufferSizeMB': return ({required Object size}) => '${size}MB';
			case 'settings.subtitleStyling': return 'Stile sottotitoli';
			case 'settings.subtitleStylingDescription': return 'Personalizza l\'aspetto dei sottotitoli';
			case 'settings.smallSkipDuration': return 'Durata skip breve';
			case 'settings.largeSkipDuration': return 'Durata skip lungo';
			case 'settings.secondsUnit': return ({required Object seconds}) => '${seconds} secondi';
			case 'settings.defaultSleepTimer': return 'Timer spegnimento predefinito';
			case 'settings.minutesUnit': return ({required Object minutes}) => '${minutes} minuti';
			case 'settings.rememberTrackSelections': return 'Ricorda selezioni tracce per serie/film';
			case 'settings.rememberTrackSelectionsDescription': return 'Salva automaticamente le preferenze delle lingue audio e sottotitoli quando cambi tracce durante la riproduzione';
			case 'settings.videoPlayerControls': return 'Controlli del lettore video';
			case 'settings.keyboardShortcuts': return 'Scorciatoie da tastiera';
			case 'settings.keyboardShortcutsDescription': return 'Personalizza le scorciatoie da tastiera';
			case 'settings.videoPlayerNavigation': return 'Navigazione del lettore video';
			case 'settings.videoPlayerNavigationDescription': return 'Usa i tasti freccia per navigare nei controlli del lettore video';
			case 'settings.debugLogging': return 'Log di debug';
			case 'settings.debugLoggingDescription': return 'Abilita il logging dettagliato per la risoluzione dei problemi';
			case 'settings.viewLogs': return 'Visualizza log';
			case 'settings.viewLogsDescription': return 'Visualizza i log dell\'applicazione';
			case 'settings.clearCache': return 'Svuota cache';
			case 'settings.clearCacheDescription': return 'Questa opzione cancellerà tutte le immagini e i dati memorizzati nella cache. Dopo aver cancellato la cache, l\'app potrebbe impiegare più tempo per caricare i contenuti.';
			case 'settings.clearCacheSuccess': return 'Cache cancellata correttamente';
			case 'settings.resetSettings': return 'Ripristina impostazioni';
			case 'settings.resetSettingsDescription': return 'Questa opzione ripristinerà tutte le impostazioni ai valori predefiniti. Non può essere annullata.';
			case 'settings.resetSettingsSuccess': return 'Impostazioni ripristinate correttamente';
			case 'settings.shortcutsReset': return 'Scorciatoie ripristinate alle impostazioni predefinite';
			case 'settings.about': return 'Informazioni';
			case 'settings.aboutDescription': return 'Informazioni sull\'app e le licenze';
			case 'settings.updates': return 'Aggiornamenti';
			case 'settings.updateAvailable': return 'Aggiornamento disponibile';
			case 'settings.checkForUpdates': return 'Controlla aggiornamenti';
			case 'settings.validationErrorEnterNumber': return 'Inserisci un numero valido';
			case 'settings.validationErrorDuration': return ({required Object min, required Object max, required Object unit}) => 'la durata deve essere compresa tra ${min} e ${max} ${unit}';
			case 'settings.shortcutAlreadyAssigned': return ({required Object action}) => 'Scorciatoia già assegnata a ${action}';
			case 'settings.shortcutUpdated': return ({required Object action}) => 'Scorciatoia aggiornata per ${action}';
			case 'settings.autoSkip': return 'Salto Automatico';
			case 'settings.autoSkipIntro': return 'Salta Intro Automaticamente';
			case 'settings.autoSkipIntroDescription': return 'Salta automaticamente i marcatori dell\'intro dopo alcuni secondi';
			case 'settings.autoSkipCredits': return 'Salta Crediti Automaticamente';
			case 'settings.autoSkipCreditsDescription': return 'Salta automaticamente i crediti e riproduci l\'episodio successivo';
			case 'settings.autoSkipDelay': return 'Ritardo Salto Automatico';
			case 'settings.autoSkipDelayDescription': return ({required Object seconds}) => 'Aspetta ${seconds} secondi prima del salto automatico';
			case 'settings.downloads': return 'Download';
			case 'settings.downloadLocationDescription': return 'Scegli dove salvare i contenuti scaricati';
			case 'settings.downloadLocationDefault': return 'Predefinita (Archiviazione App)';
			case 'settings.downloadLocationCustom': return 'Posizione Personalizzata';
			case 'settings.selectFolder': return 'Seleziona Cartella';
			case 'settings.resetToDefault': return 'Ripristina Predefinita';
			case 'settings.currentPath': return ({required Object path}) => 'Corrente: ${path}';
			case 'settings.downloadLocationChanged': return 'Posizione di download modificata';
			case 'settings.downloadLocationReset': return 'Posizione di download ripristinata a predefinita';
			case 'settings.downloadLocationInvalid': return 'La cartella selezionata non è scrivibile';
			case 'settings.downloadLocationSelectError': return 'Impossibile selezionare la cartella';
			case 'settings.downloadOnWifiOnly': return 'Scarica solo con WiFi';
			case 'settings.downloadOnWifiOnlyDescription': return 'Impedisci i download quando si utilizza la rete dati cellulare';
			case 'settings.cellularDownloadBlocked': return 'I download sono disabilitati sulla rete dati cellulare. Connettiti al WiFi o modifica l\'impostazione.';
			case 'settings.maxVolume': return 'Volume massimo';
			case 'settings.maxVolumeDescription': return 'Consenti volume superiore al 100% per contenuti audio bassi';
			case 'settings.maxVolumePercent': return ({required Object percent}) => '${percent}%';
			case 'settings.maxVolumeHint': return 'Inserisci volume massimo (100-300)';
			case 'settings.discordRichPresence': return 'Discord Rich Presence';
			case 'settings.discordRichPresenceDescription': return 'Mostra su Discord cosa stai guardando';
			case 'search.hint': return 'Cerca film. spettacoli, musica...';
			case 'search.tryDifferentTerm': return 'Prova altri termini di ricerca';
			case 'search.searchYourMedia': return 'Cerca nei tuoi media';
			case 'search.enterTitleActorOrKeyword': return 'Inserisci un titolo, attore o parola chiave';
			case 'hotkeys.setShortcutFor': return ({required Object actionName}) => 'Imposta scorciatoia per ${actionName}';
			case 'hotkeys.clearShortcut': return 'Elimina scorciatoia';
			case 'pinEntry.enterPin': return 'Inserisci PIN';
			case 'pinEntry.showPin': return 'Mostra PIN';
			case 'pinEntry.hidePin': return 'Nascondi PIN';
			case 'fileInfo.title': return 'Info sul file';
			case 'fileInfo.video': return 'Video';
			case 'fileInfo.audio': return 'Audio';
			case 'fileInfo.file': return 'File';
			case 'fileInfo.advanced': return 'Avanzate';
			case 'fileInfo.codec': return 'Codec';
			case 'fileInfo.resolution': return 'Risoluzione';
			case 'fileInfo.bitrate': return 'Bitrate';
			case 'fileInfo.frameRate': return 'Frame Rate';
			case 'fileInfo.aspectRatio': return 'Aspect Ratio';
			case 'fileInfo.profile': return 'Profilo';
			case 'fileInfo.bitDepth': return 'Profondità colore';
			case 'fileInfo.colorSpace': return 'Spazio colore';
			case 'fileInfo.colorRange': return 'Gamma colori';
			case 'fileInfo.colorPrimaries': return 'Colori primari';
			case 'fileInfo.chromaSubsampling': return 'Sottocampionamento cromatico';
			case 'fileInfo.channels': return 'Canali';
			case 'fileInfo.path': return 'Percorso';
			case 'fileInfo.size': return 'Dimensione';
			case 'fileInfo.container': return 'Contenitore';
			case 'fileInfo.duration': return 'Durata';
			case 'fileInfo.optimizedForStreaming': return 'Ottimizzato per lo streaming';
			case 'fileInfo.has64bitOffsets': return 'Offset a 64-bit';
			case 'mediaMenu.markAsWatched': return 'Segna come visto';
			case 'mediaMenu.markAsUnwatched': return 'Segna come non visto';
			case 'mediaMenu.removeFromContinueWatching': return 'Rimuovi da Continua a guardare';
			case 'mediaMenu.goToSeries': return 'Vai alle serie';
			case 'mediaMenu.goToSeason': return 'Vai alla stagione';
			case 'mediaMenu.shufflePlay': return 'Riproduzione casuale';
			case 'mediaMenu.fileInfo': return 'Info sul file';
			case 'accessibility.mediaCardMovie': return ({required Object title}) => '${title}, film';
			case 'accessibility.mediaCardShow': return ({required Object title}) => '${title}, serie TV';
			case 'accessibility.mediaCardEpisode': return ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
			case 'accessibility.mediaCardSeason': return ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
			case 'accessibility.mediaCardWatched': return 'visto';
			case 'accessibility.mediaCardPartiallyWatched': return ({required Object percent}) => '${percent} percento visto';
			case 'accessibility.mediaCardUnwatched': return 'non visto';
			case 'accessibility.tapToPlay': return 'Tocca per riprodurre';
			case 'tooltips.shufflePlay': return 'Riproduzione casuale';
			case 'tooltips.markAsWatched': return 'Segna come visto';
			case 'tooltips.markAsUnwatched': return 'Segna come non visto';
			case 'videoControls.audioLabel': return 'Audio';
			case 'videoControls.subtitlesLabel': return 'Sottotitoli';
			case 'videoControls.resetToZero': return 'Riporta a 0ms';
			case 'videoControls.addTime': return ({required Object amount, required Object unit}) => '+${amount}${unit}';
			case 'videoControls.minusTime': return ({required Object amount, required Object unit}) => '-${amount}${unit}';
			case 'videoControls.playsLater': return ({required Object label}) => '${label} riprodotto dopo';
			case 'videoControls.playsEarlier': return ({required Object label}) => '${label} riprodotto prima';
			case 'videoControls.noOffset': return 'Nessun offset';
			case 'videoControls.letterbox': return 'Letterbox';
			case 'videoControls.fillScreen': return 'Riempi schermo';
			case 'videoControls.stretch': return 'Allunga';
			case 'videoControls.lockRotation': return 'Blocca rotazione';
			case 'videoControls.unlockRotation': return 'Sblocca rotazione';
			case 'videoControls.sleepTimer': return 'Timer di spegnimento';
			case 'videoControls.timerActive': return 'Timer attivo';
			case 'videoControls.playbackWillPauseIn': return ({required Object duration}) => 'La riproduzione si interromperà tra ${duration}';
			case 'videoControls.sleepTimerCompleted': return 'Timer di spegnimento completato - riproduzione in pausa';
			case 'videoControls.playButton': return 'Riproduci';
			case 'videoControls.pauseButton': return 'Pausa';
			case 'videoControls.seekBackwardButton': return ({required Object seconds}) => 'Riavvolgi di ${seconds} secondi';
			case 'videoControls.seekForwardButton': return ({required Object seconds}) => 'Avanza di ${seconds} secondi';
			case 'videoControls.previousButton': return 'Episodio precedente';
			case 'videoControls.nextButton': return 'Episodio successivo';
			case 'videoControls.previousChapterButton': return 'Capitolo precedente';
			case 'videoControls.nextChapterButton': return 'Capitolo successivo';
			case 'videoControls.muteButton': return 'Silenzia';
			case 'videoControls.unmuteButton': return 'Riattiva audio';
			case 'videoControls.settingsButton': return 'Impostazioni video';
			case 'videoControls.audioTrackButton': return 'Tracce audio';
			case 'videoControls.subtitlesButton': return 'Sottotitoli';
			case 'videoControls.chaptersButton': return 'Capitoli';
			case 'videoControls.versionsButton': return 'Versioni video';
			case 'videoControls.pipButton': return 'Modalità Picture-in-Picture';
			case 'videoControls.aspectRatioButton': return 'Proporzioni';
			case 'videoControls.fullscreenButton': return 'Attiva schermo intero';
			case 'videoControls.exitFullscreenButton': return 'Esci da schermo intero';
			case 'videoControls.alwaysOnTopButton': return 'Sempre in primo piano';
			case 'videoControls.rotationLockButton': return 'Blocco rotazione';
			case 'videoControls.timelineSlider': return 'Timeline video';
			case 'videoControls.volumeSlider': return 'Livello volume';
			case 'videoControls.backButton': return 'Indietro';
			case 'userStatus.admin': return 'Admin';
			case 'userStatus.restricted': return 'Limitato';
			case 'userStatus.protected': return 'Protetto';
			case 'userStatus.current': return 'ATTUALE';
			case 'messages.markedAsWatched': return 'Segna come visto';
			case 'messages.markedAsUnwatched': return 'Segna come non visto';
			case 'messages.markedAsWatchedOffline': return 'Segnato come visto (sincronizzato online)';
			case 'messages.markedAsUnwatchedOffline': return 'Segnato come non visto (sincronizzato online)';
			case 'messages.removedFromContinueWatching': return 'Rimosso da Continua a guardare';
			case 'messages.errorLoading': return ({required Object error}) => 'Errore: ${error}';
			case 'messages.fileInfoNotAvailable': return 'Informazioni sul file non disponibili';
			case 'messages.errorLoadingFileInfo': return ({required Object error}) => 'Errore caricamento informazioni sul file: ${error}';
			case 'messages.errorLoadingSeries': return 'Errore caricamento serie';
			case 'messages.errorLoadingSeason': return 'Errore caricamento stagione';
			case 'messages.musicNotSupported': return 'La riproduzione musicale non è ancora supportata';
			case 'messages.logsCleared': return 'Log eliminati';
			case 'messages.logsCopied': return 'Log copiati negli appunti';
			case 'messages.noLogsAvailable': return 'Nessun log disponibile';
			case 'messages.libraryScanning': return ({required Object title}) => 'Scansione "${title}"...';
			case 'messages.libraryScanStarted': return ({required Object title}) => 'Scansione libreria iniziata per "${title}"';
			case 'messages.libraryScanFailed': return ({required Object error}) => 'Impossibile eseguire scansione della libreria: ${error}';
			case 'messages.metadataRefreshing': return ({required Object title}) => 'Aggiornamento metadati per "${title}"...';
			case 'messages.metadataRefreshStarted': return ({required Object title}) => 'Aggiornamento metadati per "${title}"';
			case 'messages.metadataRefreshFailed': return ({required Object error}) => 'Errore aggiornamento metadati: ${error}';
			case 'messages.logoutConfirm': return 'Sei sicuro di volerti disconnettere?';
			case 'messages.noSeasonsFound': return 'Nessuna stagione trovata';
			case 'messages.noEpisodesFound': return 'Nessun episodio trovato nella prima stagione';
			case 'messages.noEpisodesFoundGeneral': return 'Nessun episodio trovato';
			case 'messages.noResultsFound': return 'Nessun risultato';
			case 'messages.sleepTimerSet': return ({required Object label}) => 'Imposta timer spegnimento per ${label}';
			case 'messages.noItemsAvailable': return 'Nessun elemento disponibile';
			case 'messages.failedToCreatePlayQueue': return 'Impossibile creare la coda di riproduzione';
			case 'messages.failedToCreatePlayQueueNoItems': return 'Impossibile creare la coda di riproduzione - nessun elemento';
			case 'messages.failedPlayback': return ({required Object action, required Object error}) => 'Impossibile ${action}: ${error}';
			case 'subtitlingStyling.stylingOptions': return 'Opzioni stile';
			case 'subtitlingStyling.fontSize': return 'Dimensione';
			case 'subtitlingStyling.textColor': return 'Colore testo';
			case 'subtitlingStyling.borderSize': return 'Dimensione bordo';
			case 'subtitlingStyling.borderColor': return 'Colore bordo';
			case 'subtitlingStyling.backgroundOpacity': return 'Opacità sfondo';
			case 'subtitlingStyling.backgroundColor': return 'Colore sfondo';
			case 'mpvConfig.title': return 'Configurazione MPV';
			case 'mpvConfig.description': return 'Impostazioni avanzate del lettore video';
			case 'mpvConfig.properties': return 'Proprietà';
			case 'mpvConfig.presets': return 'Preset';
			case 'mpvConfig.noProperties': return 'Nessuna proprietà configurata';
			case 'mpvConfig.noPresets': return 'Nessun preset salvato';
			case 'mpvConfig.addProperty': return 'Aggiungi proprietà';
			case 'mpvConfig.editProperty': return 'Modifica proprietà';
			case 'mpvConfig.deleteProperty': return 'Elimina proprietà';
			case 'mpvConfig.propertyKey': return 'Chiave proprietà';
			case 'mpvConfig.propertyKeyHint': return 'es. hwdec, demuxer-max-bytes';
			case 'mpvConfig.propertyValue': return 'Valore proprietà';
			case 'mpvConfig.propertyValueHint': return 'es. auto, 256000000';
			case 'mpvConfig.saveAsPreset': return 'Salva come preset...';
			case 'mpvConfig.presetName': return 'Nome preset';
			case 'mpvConfig.presetNameHint': return 'Inserisci un nome per questo preset';
			case 'mpvConfig.loadPreset': return 'Carica';
			case 'mpvConfig.deletePreset': return 'Elimina';
			case 'mpvConfig.presetSaved': return 'Preset salvato';
			case 'mpvConfig.presetLoaded': return 'Preset caricato';
			case 'mpvConfig.presetDeleted': return 'Preset eliminato';
			case 'mpvConfig.confirmDeletePreset': return 'Sei sicuro di voler eliminare questo preset?';
			case 'mpvConfig.confirmDeleteProperty': return 'Sei sicuro di voler eliminare questa proprietà?';
			case 'mpvConfig.entriesCount': return ({required Object count}) => '${count} voci';
			case 'dialog.confirmAction': return 'Conferma azione';
			case 'dialog.cancel': return 'Cancella';
			case 'dialog.playNow': return 'Riproduci ora';
			case 'discover.title': return 'Esplora';
			case 'discover.switchProfile': return 'Cambia profilo';
			case 'discover.switchServer': return 'Cambia server';
			case 'discover.logout': return 'Disconnetti';
			case 'discover.noContentAvailable': return 'Nessun contenuto disponibile';
			case 'discover.addMediaToLibraries': return 'Aggiungi alcuni file multimediali alle tue librerie';
			case 'discover.continueWatching': return 'Continua a guardare';
			case 'discover.play': return 'Riproduci';
			case 'discover.playEpisode': return ({required Object season, required Object episode}) => 'S${season}E${episode}';
			case 'discover.pause': return 'Pausa';
			case 'discover.overview': return 'Panoramica';
			case 'discover.cast': return 'Attori';
			case 'discover.seasons': return 'Stagioni';
			case 'discover.studio': return 'Studio';
			case 'discover.rating': return 'Classificazione';
			case 'discover.watched': return 'Guardato';
			case 'discover.episodeCount': return ({required Object count}) => '${count} episodi';
			case 'discover.watchedProgress': return ({required Object watched, required Object total}) => '${watched}/${total} guardati';
			case 'discover.movie': return 'Film';
			case 'discover.tvShow': return 'Serie TV';
			case 'discover.minutesLeft': return ({required Object minutes}) => '${minutes} minuti rimanenti';
			case 'errors.searchFailed': return ({required Object error}) => 'Ricerca fallita: ${error}';
			case 'errors.connectionTimeout': return ({required Object context}) => 'Timeout connessione durante caricamento di ${context}';
			case 'errors.connectionFailed': return 'Impossibile connettersi al server Plex.';
			case 'errors.failedToLoad': return ({required Object context, required Object error}) => 'Impossibile caricare ${context}: ${error}';
			case 'errors.noClientAvailable': return 'Nessun client disponibile';
			case 'errors.authenticationFailed': return ({required Object error}) => 'Autenticazione fallita: ${error}';
			case 'errors.couldNotLaunchUrl': return 'Impossibile avviare URL di autenticazione';
			case 'errors.pleaseEnterToken': return 'Inserisci token';
			case 'errors.invalidToken': return 'Token non valido';
			case 'errors.failedToVerifyToken': return ({required Object error}) => 'Verifica token fallita: ${error}';
			case 'errors.failedToSwitchProfile': return ({required Object displayName}) => 'Impossibile passare a ${displayName}';
			case 'libraries.title': return 'Librerie';
			case 'libraries.scanLibraryFiles': return 'Scansiona file libreria';
			case 'libraries.scanLibrary': return 'Scansiona libreria';
			case 'libraries.analyze': return 'Analizza';
			case 'libraries.analyzeLibrary': return 'Analizza libreria';
			case 'libraries.refreshMetadata': return 'Aggiorna metadati';
			case 'libraries.emptyTrash': return 'Svuota cestino';
			case 'libraries.emptyingTrash': return ({required Object title}) => 'Svuotamento cestino per "${title}"...';
			case 'libraries.trashEmptied': return ({required Object title}) => 'Cestino svuotato per "${title}"';
			case 'libraries.failedToEmptyTrash': return ({required Object error}) => 'Impossibile svuotare cestino: ${error}';
			case 'libraries.analyzing': return ({required Object title}) => 'Analisi "${title}"...';
			case 'libraries.analysisStarted': return ({required Object title}) => 'Analisi iniziata per "${title}"';
			case 'libraries.failedToAnalyze': return ({required Object error}) => 'Impossibile analizzare libreria: ${error}';
			case 'libraries.noLibrariesFound': return 'Nessuna libreria trovata';
			case 'libraries.thisLibraryIsEmpty': return 'Questa libreria è vuota';
			case 'libraries.all': return 'Tutto';
			case 'libraries.clearAll': return 'Cancella tutto';
			case 'libraries.scanLibraryConfirm': return ({required Object title}) => 'Sei sicuro di voler scansionare "${title}"?';
			case 'libraries.analyzeLibraryConfirm': return ({required Object title}) => 'Sei sicuro di voler analizzare "${title}"?';
			case 'libraries.refreshMetadataConfirm': return ({required Object title}) => 'Sei sicuro di voler aggiornare i metadati per "${title}"?';
			case 'libraries.emptyTrashConfirm': return ({required Object title}) => 'Sei sicuro di voler svuotare il cestino per "${title}"?';
			case 'libraries.manageLibraries': return 'Gestisci librerie';
			case 'libraries.sort': return 'Ordina';
			case 'libraries.sortBy': return 'Ordina per';
			case 'libraries.filters': return 'Filtri';
			case 'libraries.confirmActionMessage': return 'Sei sicuro di voler eseguire questa azione?';
			case 'libraries.showLibrary': return 'Mostra libreria';
			case 'libraries.hideLibrary': return 'Nascondi libreria';
			case 'libraries.libraryOptions': return 'Opzioni libreria';
			case 'libraries.content': return 'contenuto della libreria';
			case 'libraries.selectLibrary': return 'Seleziona libreria';
			case 'libraries.filtersWithCount': return ({required Object count}) => 'Filtri (${count})';
			case 'libraries.noRecommendations': return 'Nessun consiglio disponibile';
			case 'libraries.noCollections': return 'Nessuna raccolta in questa libreria';
			case 'libraries.noFoldersFound': return 'Nessuna cartella trovata';
			case 'libraries.folders': return 'cartelle';
			case 'libraries.tabs.recommended': return 'Consigliati';
			case 'libraries.tabs.browse': return 'Esplora';
			case 'libraries.tabs.collections': return 'Raccolte';
			case 'libraries.tabs.playlists': return 'Playlist';
			case 'libraries.groupings.all': return 'Tutti';
			case 'libraries.groupings.movies': return 'Film';
			case 'libraries.groupings.shows': return 'Serie TV';
			case 'libraries.groupings.seasons': return 'Stagioni';
			case 'libraries.groupings.episodes': return 'Episodi';
			case 'libraries.groupings.folders': return 'Cartelle';
			case 'about.title': return 'Informazioni';
			case 'about.openSourceLicenses': return 'Licenze Open Source';
			case 'about.versionLabel': return ({required Object version}) => 'Versione ${version}';
			case 'about.appDescription': return 'Un bellissimo client Plex per Flutter';
			case 'about.viewLicensesDescription': return 'Visualizza le licenze delle librerie di terze parti';
			case 'serverSelection.allServerConnectionsFailed': return 'Impossibile connettersi a nessun server. Controlla la tua rete e riprova.';
			case 'serverSelection.noServersFound': return 'Nessun server trovato';
			case 'serverSelection.noServersFoundForAccount': return ({required Object username, required Object email}) => 'Nessun server trovato per ${username} (${email})';
			case 'serverSelection.failedToLoadServers': return ({required Object error}) => 'Impossibile caricare i server: ${error}';
			case 'hubDetail.title': return 'Titolo';
			case 'hubDetail.releaseYear': return 'Anno rilascio';
			case 'hubDetail.dateAdded': return 'Data aggiunta';
			case 'hubDetail.rating': return 'Valutazione';
			case 'hubDetail.noItemsFound': return 'Nessun elemento trovato';
			case 'logs.clearLogs': return 'Cancella log';
			case 'logs.copyLogs': return 'Copia log';
			case 'logs.error': return 'Errore:';
			case 'logs.stackTrace': return 'Traccia dello stack:';
			case 'licenses.relatedPackages': return 'Pacchetti correlati';
			case 'licenses.license': return 'Licenza';
			case 'licenses.licenseNumber': return ({required Object number}) => 'Licenza ${number}';
			case 'licenses.licensesCount': return ({required Object count}) => '${count} licenze';
			case 'navigation.home': return 'Home';
			case 'navigation.search': return 'Cerca';
			case 'navigation.libraries': return 'Librerie';
			case 'navigation.settings': return 'Impostazioni';
			case 'navigation.downloads': return 'Download';
			case 'downloads.title': return 'Download';
			case 'downloads.manage': return 'Gestisci';
			case 'downloads.tvShows': return 'Serie TV';
			case 'downloads.movies': return 'Film';
			case 'downloads.noDownloads': return 'Nessun download';
			case 'downloads.noDownloadsDescription': return 'I contenuti scaricati appariranno qui per la visualizzazione offline';
			case 'downloads.downloadNow': return 'Scarica';
			case 'downloads.deleteDownload': return 'Elimina download';
			case 'downloads.retryDownload': return 'Riprova download';
			case 'downloads.downloadQueued': return 'Download in coda';
			case 'downloads.episodesQueued': return ({required Object count}) => '${count} episodi in coda per il download';
			case 'downloads.downloadDeleted': return 'Download eliminato';
			case 'downloads.deleteConfirm': return ({required Object title}) => 'Sei sicuro di voler eliminare "${title}"? Il file scaricato verrà rimosso dal tuo dispositivo.';
			case 'downloads.deletingWithProgress': return ({required Object title, required Object current, required Object total}) => 'Eliminazione di ${title}... (${current} di ${total})';
			case 'playlists.title': return 'Playlist';
			case 'playlists.noPlaylists': return 'Nessuna playlist trovata';
			case 'playlists.create': return 'Crea playlist';
			case 'playlists.playlistName': return 'Nome playlist';
			case 'playlists.enterPlaylistName': return 'Inserisci nome playlist';
			case 'playlists.delete': return 'Elimina playlist';
			case 'playlists.removeItem': return 'Rimuovi da playlist';
			case 'playlists.smartPlaylist': return 'Playlist intelligente';
			case 'playlists.itemCount': return ({required Object count}) => '${count} elementi';
			case 'playlists.oneItem': return '1 elemento';
			case 'playlists.emptyPlaylist': return 'Questa playlist è vuota';
			case 'playlists.deleteConfirm': return 'Eliminare playlist?';
			case 'playlists.deleteMessage': return ({required Object name}) => 'Sei sicuro di voler eliminare "${name}"?';
			case 'playlists.created': return 'Playlist creata';
			case 'playlists.deleted': return 'Playlist eliminata';
			case 'playlists.itemAdded': return 'Aggiunto alla playlist';
			case 'playlists.itemRemoved': return 'Rimosso dalla playlist';
			case 'playlists.selectPlaylist': return 'Seleziona playlist';
			case 'playlists.createNewPlaylist': return 'Crea nuova playlist';
			case 'playlists.errorCreating': return 'Errore durante la creazione della playlist';
			case 'playlists.errorDeleting': return 'Errore durante l\'eliminazione della playlist';
			case 'playlists.errorLoading': return 'Errore durante il caricamento delle playlist';
			case 'playlists.errorAdding': return 'Errore durante l\'aggiunta alla playlist';
			case 'playlists.errorReordering': return 'Errore durante il riordino dell\'elemento della playlist';
			case 'playlists.errorRemoving': return 'Errore durante la rimozione dalla playlist';
			case 'playlists.playlist': return 'Playlist';
			case 'collections.title': return 'Raccolte';
			case 'collections.collection': return 'Raccolta';
			case 'collections.empty': return 'La raccolta è vuota';
			case 'collections.unknownLibrarySection': return 'Impossibile eliminare: sezione libreria sconosciuta';
			case 'collections.deleteCollection': return 'Elimina raccolta';
			case 'collections.deleteConfirm': return ({required Object title}) => 'Sei sicuro di voler eliminare "${title}"? Questa azione non può essere annullata.';
			case 'collections.deleted': return 'Raccolta eliminata';
			case 'collections.deleteFailed': return 'Impossibile eliminare la raccolta';
			case 'collections.deleteFailedWithError': return ({required Object error}) => 'Impossibile eliminare la raccolta: ${error}';
			case 'collections.failedToLoadItems': return ({required Object error}) => 'Impossibile caricare gli elementi della raccolta: ${error}';
			case 'collections.selectCollection': return 'Seleziona raccolta';
			case 'collections.createNewCollection': return 'Crea nuova raccolta';
			case 'collections.collectionName': return 'Nome raccolta';
			case 'collections.enterCollectionName': return 'Inserisci nome raccolta';
			case 'collections.addedToCollection': return 'Aggiunto alla raccolta';
			case 'collections.errorAddingToCollection': return 'Errore nell\'aggiunta alla raccolta';
			case 'collections.created': return 'Raccolta creata';
			case 'collections.removeFromCollection': return 'Rimuovi dalla raccolta';
			case 'collections.removeFromCollectionConfirm': return ({required Object title}) => 'Rimuovere "${title}" da questa raccolta?';
			case 'collections.removedFromCollection': return 'Rimosso dalla raccolta';
			case 'collections.removeFromCollectionFailed': return 'Impossibile rimuovere dalla raccolta';
			case 'collections.removeFromCollectionError': return ({required Object error}) => 'Errore durante la rimozione dalla raccolta: ${error}';
			case 'watchTogether.title': return 'Guarda Insieme';
			case 'watchTogether.description': return 'Guarda contenuti in sincronia con amici e familiari';
			case 'watchTogether.createSession': return 'Crea Sessione';
			case 'watchTogether.creating': return 'Creazione...';
			case 'watchTogether.joinSession': return 'Unisciti alla Sessione';
			case 'watchTogether.joining': return 'Connessione...';
			case 'watchTogether.controlMode': return 'Modalità di Controllo';
			case 'watchTogether.controlModeQuestion': return 'Chi può controllare la riproduzione?';
			case 'watchTogether.hostOnly': return 'Solo Host';
			case 'watchTogether.anyone': return 'Tutti';
			case 'watchTogether.hostingSession': return 'Hosting Sessione';
			case 'watchTogether.inSession': return 'In Sessione';
			case 'watchTogether.sessionCode': return 'Codice Sessione';
			case 'watchTogether.hostControlsPlayback': return 'L\'host controlla la riproduzione';
			case 'watchTogether.anyoneCanControl': return 'Tutti possono controllare la riproduzione';
			case 'watchTogether.hostControls': return 'Controllo host';
			case 'watchTogether.anyoneControls': return 'Controllo di tutti';
			case 'watchTogether.participants': return 'Partecipanti';
			case 'watchTogether.host': return 'Host';
			case 'watchTogether.hostBadge': return 'HOST';
			case 'watchTogether.youAreHost': return 'Sei l\'host';
			case 'watchTogether.watchingWithOthers': return 'Guardando con altri';
			case 'watchTogether.endSession': return 'Termina Sessione';
			case 'watchTogether.leaveSession': return 'Lascia Sessione';
			case 'watchTogether.endSessionQuestion': return 'Terminare la Sessione?';
			case 'watchTogether.leaveSessionQuestion': return 'Lasciare la Sessione?';
			case 'watchTogether.endSessionConfirm': return 'Questo terminerà la sessione per tutti i partecipanti.';
			case 'watchTogether.leaveSessionConfirm': return 'Sarai rimosso dalla sessione.';
			case 'watchTogether.endSessionConfirmOverlay': return 'Questo terminerà la sessione di visione per tutti i partecipanti.';
			case 'watchTogether.leaveSessionConfirmOverlay': return 'Sarai disconnesso dalla sessione di visione.';
			case 'watchTogether.end': return 'Termina';
			case 'watchTogether.leave': return 'Lascia';
			case 'watchTogether.syncing': return 'Sincronizzazione...';
			case 'watchTogether.participant': return 'partecipante';
			case 'watchTogether.joinWatchSession': return 'Unisciti alla Sessione di Visione';
			case 'watchTogether.enterCodeHint': return 'Inserisci codice di 8 caratteri';
			case 'watchTogether.pasteFromClipboard': return 'Incolla dagli appunti';
			case 'watchTogether.pleaseEnterCode': return 'Inserisci un codice sessione';
			case 'watchTogether.codeMustBe8Chars': return 'Il codice sessione deve essere di 8 caratteri';
			case 'watchTogether.joinInstructions': return 'Inserisci il codice sessione condiviso dall\'host per unirti alla loro sessione di visione.';
			case 'watchTogether.failedToCreate': return 'Impossibile creare la sessione';
			case 'watchTogether.failedToJoin': return 'Impossibile unirsi alla sessione';
			default: return null;
		}
	}
}

extension on _StringsKo {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'app.title': return 'Plezy';
			case 'app.loading': return '로딩 중...';
			case 'auth.signInWithPlex': return 'Plex 계정으로 로그인';
			case 'auth.showQRCode': return 'QR 코드';
			case 'auth.cancel': return '취소';
			case 'auth.authenticate': return '인증';
			case 'auth.retry': return '재시도';
			case 'auth.debugEnterToken': return '디버깅을 위해 Plex 토큰을 입력하세요.';
			case 'auth.plexTokenLabel': return 'Plex 인증 토큰';
			case 'auth.plexTokenHint': return 'Plex.tv 토큰을 입력하세요';
			case 'auth.authenticationTimeout': return '인증 시간이 초과되었습니다. 다시 시도해 주세요.';
			case 'auth.scanQRCodeInstruction': return 'Plex 계정에 로그인된 기기에서 이 QR 코드를 스캔하여 본인 인증을 해주세요.';
			case 'auth.waitingForAuth': return '인증 대기 중... 브라우저에서 로그인을 완료해 주세요.';
			case 'common.cancel': return '취소';
			case 'common.save': return '저장';
			case 'common.close': return '닫기';
			case 'common.clear': return '지우기';
			case 'common.reset': return '초기화';
			case 'common.later': return '나중에';
			case 'common.submit': return '보내기';
			case 'common.confirm': return '확인';
			case 'common.retry': return '재시도';
			case 'common.logout': return '로그아웃';
			case 'common.unknown': return '알 수 없는';
			case 'common.refresh': return '새로고침';
			case 'common.yes': return '예';
			case 'common.no': return '아니오';
			case 'common.delete': return '삭제';
			case 'common.shuffle': return '무작위 재생';
			case 'common.addTo': return '추가하기...';
			case 'screens.licenses': return '라이선스';
			case 'screens.selectServer': return '서버 선택';
			case 'screens.switchProfile': return '프로필 전환';
			case 'screens.subtitleStyling': return '자막 스타일 설정';
			case 'screens.mpvConfig': return 'MPV 설정';
			case 'screens.search': return '검색';
			case 'screens.logs': return '로그';
			case 'update.available': return '사용 가능한 업데이트';
			case 'update.versionAvailable': return ({required Object version}) => '버전 ${version} 출시됨';
			case 'update.currentVersion': return ({required Object version}) => '현재 버전: ${version}';
			case 'update.skipVersion': return '이 버전 건너뛰기';
			case 'update.viewRelease': return '릴리스 정보 보기';
			case 'update.latestVersion': return '최신 버전을 사용 중입니다';
			case 'update.checkFailed': return '업데이트 확인 실패';
			case 'settings.title': return '설정';
			case 'settings.language': return '언어';
			case 'settings.theme': return '테마';
			case 'settings.appearance': return '외관';
			case 'settings.videoPlayback': return '비디오 재생';
			case 'settings.advanced': return '고급';
			case 'settings.episodePosterMode': return '에피소드 포스터 스타일';
			case 'settings.seriesPoster': return '시리즈 포스터';
			case 'settings.seriesPosterDescription': return '모든 에피소드에 시리즈 포스터 표시';
			case 'settings.seasonPoster': return '시즌 포스터';
			case 'settings.seasonPosterDescription': return '에피소드에 시즌별 포스터 표시';
			case 'settings.episodeThumbnail': return '에피소드 썸네일';
			case 'settings.episodeThumbnailDescription': return '16:9 에피소드 스크린샷 썸네일 표시';
			case 'settings.showHeroSectionDescription': return '홈 화면에 주요 콘텐츠 캐러셀(슬라이드) 표시';
			case 'settings.secondsLabel': return '초';
			case 'settings.minutesLabel': return '분';
			case 'settings.secondsShort': return '초';
			case 'settings.minutesShort': return '분';
			case 'settings.durationHint': return ({required Object min, required Object max}) => '기간 입력 (${min}-${max})';
			case 'settings.systemTheme': return '시스템 설정';
			case 'settings.systemThemeDescription': return '시스템 설정에 따름';
			case 'settings.lightTheme': return '라이트 모드';
			case 'settings.darkTheme': return '다크 모드';
			case 'settings.libraryDensity': return '라이브러리 표시 밀도';
			case 'settings.compact': return '좁게';
			case 'settings.compactDescription': return '카드를 작게 표시하여 더 많은 항목을 보여줍니다.';
			case 'settings.normal': return '보통';
			case 'settings.normalDescription': return '기본 크기';
			case 'settings.comfortable': return '넓게';
			case 'settings.comfortableDescription': return '카드를 크게 표시하여 더 적은 항목을 보여줍니다.';
			case 'settings.viewMode': return '보기 모드';
			case 'settings.gridView': return '그리드 보기';
			case 'settings.gridViewDescription': return '항목을 그리드 레이아웃으로 표시합니다';
			case 'settings.listView': return '목록 보기';
			case 'settings.listViewDescription': return '항목을 목록 레이아웃으로 표시합니다';
			case 'settings.showHeroSection': return '주요 추천 영역 표시';
			case 'settings.useGlobalHubs': return 'Plex 홈 레이아웃 사용';
			case 'settings.useGlobalHubsDescription': return '공식 Plex 클라이언트처럼 홈 페이지 허브를 표시합니다. 끄면 라이브러리별 추천이 대신 표시됩니다.';
			case 'settings.hardwareDecoding': return '하드웨어 디코딩';
			case 'settings.hardwareDecodingDescription': return '가능한 경우 하드웨어 가속을 사용합니다';
			case 'settings.bufferSize': return '버퍼 크기';
			case 'settings.bufferSizeMB': return ({required Object size}) => '${size}MB';
			case 'settings.subtitleStyling': return '자막 스타일';
			case 'settings.subtitleStylingDescription': return '자막의 외형을 사용자 설정';
			case 'settings.smallSkipDuration': return '짧은 건너뛰기 시간';
			case 'settings.largeSkipDuration': return '긴 건너뛰기 시간';
			case 'settings.secondsUnit': return ({required Object seconds}) => '${seconds}초';
			case 'settings.defaultSleepTimer': return '기본 취침 타이머';
			case 'settings.minutesUnit': return ({required Object minutes}) => '${minutes}분';
			case 'settings.rememberTrackSelections': return '에피소드/영화별 트랙 선택 기억';
			case 'settings.rememberTrackSelectionsDescription': return '재생 중 트랙을 변경할 때 오디오 및 자막 언어 설정을 자동으로 저장합니다';
			case 'settings.videoPlayerControls': return '비디오 플레이어 컨트롤';
			case 'settings.keyboardShortcuts': return '키보드 단축키';
			case 'settings.keyboardShortcutsDescription': return '사용자 정의 키보드 단축키';
			case 'settings.videoPlayerNavigation': return '비디오 플레이어 탐색';
			case 'settings.videoPlayerNavigationDescription': return '방향 키를 사용하여 비디오 플레이어 컨트롤 탐색';
			case 'settings.debugLogging': return '디버그 로깅';
			case 'settings.debugLoggingDescription': return '문제 해결을 위해 상세 로깅 활성화';
			case 'settings.viewLogs': return '로그 보기';
			case 'settings.viewLogsDescription': return '애플리케이션 로그 확인';
			case 'settings.clearCache': return '캐시 삭제';
			case 'settings.clearCacheDescription': return '모든 캐시된 이미지와 데이터를 지웁니다. 캐시를 지우면 애플리케이션 콘텐츠 로딩 속도가 느려질 수 있습니다.';
			case 'settings.clearCacheSuccess': return '캐시 삭제 성공';
			case 'settings.resetSettings': return '설정 재설정';
			case 'settings.resetSettingsDescription': return '모든 설정을 기본값으로 재설정합니다. 이 작업은 되돌릴 수 없습니다.';
			case 'settings.resetSettingsSuccess': return '설정 재설정 성공';
			case 'settings.shortcutsReset': return '단축키가 기본값으로 재설정되었습니다';
			case 'settings.about': return '정보';
			case 'settings.aboutDescription': return '응용 프로그램 정보 및 라이선스';
			case 'settings.updates': return '업데이트';
			case 'settings.updateAvailable': return '사용 가능한 업데이트 있음';
			case 'settings.checkForUpdates': return '업데이트 확인';
			case 'settings.validationErrorEnterNumber': return '유효한 숫자를 입력하세요';
			case 'settings.validationErrorDuration': return ({required Object min, required Object max, required Object unit}) => '기간은 ${min}과 ${max} ${unit} 사이여야 합니다';
			case 'settings.shortcutAlreadyAssigned': return ({required Object action}) => '단축키가 이미 ${action}에 할당 되었습니다';
			case 'settings.shortcutUpdated': return ({required Object action}) => '단축키가 ${action}에 대해 업데이트 되었습니다';
			case 'settings.autoSkip': return '자동 건너뛰기';
			case 'settings.autoSkipIntro': return '자동으로 오프닝 건너뛰기';
			case 'settings.autoSkipIntroDescription': return '몇 초 후 오프닝을 자동으로 건너뛰기';
			case 'settings.autoSkipCredits': return '자동으로 엔딩 건너뛰기';
			case 'settings.autoSkipCreditsDescription': return '엔딩 크레딧 자동 건너뛰기 후 다음 에피소드 재생';
			case 'settings.autoSkipDelay': return '자동 건너뛰기 지연';
			case 'settings.autoSkipDelayDescription': return ({required Object seconds}) => '자동 건너뛰기 전 ${seconds} 초 대기';
			case 'settings.downloads': return '다운로드';
			case 'settings.downloadLocationDescription': return '다운로드 콘텐츠 저장 위치 선택';
			case 'settings.downloadLocationDefault': return '기본값 (앱 저장소)';
			case 'settings.downloadLocationCustom': return '사용자 지정 위치';
			case 'settings.selectFolder': return '폴더 선택';
			case 'settings.resetToDefault': return '기본값으로 재설정';
			case 'settings.currentPath': return ({required Object path}) => '현재: ${path}';
			case 'settings.downloadLocationChanged': return '다운로드 위치가 변경 되었습니다';
			case 'settings.downloadLocationReset': return '다운로드 위치가 기본값으로 재설정 되었습니다';
			case 'settings.downloadLocationInvalid': return '선택한 폴더에 쓰기 권한이 없습니다';
			case 'settings.downloadLocationSelectError': return '폴더 선택 실패';
			case 'settings.downloadOnWifiOnly': return 'WiFi 연결 시에만 다운로드';
			case 'settings.downloadOnWifiOnlyDescription': return '셀룰러 데이터 사용 시 다운로드 불가';
			case 'settings.cellularDownloadBlocked': return '셀룰러 데이터에서 다운로드가 차단 되었습니다. WiFi에 연결하거나 설정을 변경하세요.';
			case 'settings.maxVolume': return '최대 볼륨';
			case 'settings.maxVolumeDescription': return '조용한 미디어를 위해 100% 이상의 볼륨 허용';
			case 'settings.maxVolumePercent': return ({required Object percent}) => '${percent}%';
			case 'settings.maxVolumeHint': return '최대 볼륨 입력 (100-300)';
			case 'settings.discordRichPresence': return 'Discord Rich Presence';
			case 'settings.discordRichPresenceDescription': return 'Discord에서 시청 중인 콘텐츠 표시';
			case 'search.hint': return '영화, 시리즈, 음악 등을 검색하세요...';
			case 'search.tryDifferentTerm': return '다른 검색어를 시도해 보세요';
			case 'search.searchYourMedia': return '미디어 검색';
			case 'search.enterTitleActorOrKeyword': return '제목, 배우 또는 키워드를 입력하세요';
			case 'hotkeys.setShortcutFor': return ({required Object actionName}) => '${actionName}에 대한 단축키 설정';
			case 'hotkeys.clearShortcut': return '단축키 삭제';
			case 'pinEntry.enterPin': return 'PIN 입력';
			case 'pinEntry.showPin': return 'PIN 표시';
			case 'pinEntry.hidePin': return 'PIN 숨기기';
			case 'fileInfo.title': return '파일 정보';
			case 'fileInfo.video': return '비디오';
			case 'fileInfo.audio': return '오디오';
			case 'fileInfo.file': return '파일';
			case 'fileInfo.advanced': return '고급';
			case 'fileInfo.codec': return '코덱';
			case 'fileInfo.resolution': return '해상도';
			case 'fileInfo.bitrate': return '비트레이트';
			case 'fileInfo.frameRate': return '프레임 속도';
			case 'fileInfo.aspectRatio': return '종횡비';
			case 'fileInfo.profile': return '프로파일';
			case 'fileInfo.bitDepth': return '비트 심도';
			case 'fileInfo.colorSpace': return '색 공간';
			case 'fileInfo.colorRange': return '색 범위';
			case 'fileInfo.colorPrimaries': return '색상 원색';
			case 'fileInfo.chromaSubsampling': return '채도 서브샘플링';
			case 'fileInfo.channels': return '채널';
			case 'fileInfo.path': return '경로';
			case 'fileInfo.size': return '크기';
			case 'fileInfo.container': return '컨테이너';
			case 'fileInfo.duration': return '재생 시간';
			case 'fileInfo.optimizedForStreaming': return '스트리밍 최적화';
			case 'fileInfo.has64bitOffsets': return '64비트 오프셋';
			case 'mediaMenu.markAsWatched': return '시청 완료로 표시';
			case 'mediaMenu.markAsUnwatched': return '시청 안 함으로 표시';
			case 'mediaMenu.removeFromContinueWatching': return '계속 보기에서 제거';
			case 'mediaMenu.goToSeries': return '시리즈로 이동';
			case 'mediaMenu.goToSeason': return '시즌으로 이동';
			case 'mediaMenu.shufflePlay': return '무작위 재생';
			case 'mediaMenu.fileInfo': return '파일 정보';
			case 'accessibility.mediaCardMovie': return ({required Object title}) => '${title}, 영화';
			case 'accessibility.mediaCardShow': return ({required Object title}) => '${title}, TV 프로그램';
			case 'accessibility.mediaCardEpisode': return ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
			case 'accessibility.mediaCardSeason': return ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
			case 'accessibility.mediaCardWatched': return '시청 완료';
			case 'accessibility.mediaCardPartiallyWatched': return ({required Object percent}) => '${percent} 퍼센트 시청 완료';
			case 'accessibility.mediaCardUnwatched': return '미시청';
			case 'accessibility.tapToPlay': return '터치 하여 재생';
			case 'tooltips.shufflePlay': return '무작위 재생';
			case 'tooltips.markAsWatched': return '시청 완료로 표시';
			case 'tooltips.markAsUnwatched': return '시청 안 함으로 표시';
			case 'videoControls.audioLabel': return '오디오';
			case 'videoControls.subtitlesLabel': return '자막';
			case 'videoControls.resetToZero': return '0ms로 재설정';
			case 'videoControls.addTime': return ({required Object amount, required Object unit}) => '+${amount}${unit}';
			case 'videoControls.minusTime': return ({required Object amount, required Object unit}) => '-${amount}${unit}';
			case 'videoControls.playsLater': return ({required Object label}) => '${label} 나중에 재생됨';
			case 'videoControls.playsEarlier': return ({required Object label}) => '${label} 더 먼저 재생됨';
			case 'videoControls.noOffset': return '오프셋 없음';
			case 'videoControls.letterbox': return '레터박스 모드';
			case 'videoControls.fillScreen': return '화면 채우기';
			case 'videoControls.stretch': return '확장';
			case 'videoControls.lockRotation': return '회전 잠금';
			case 'videoControls.unlockRotation': return '회전 잠금 해제';
			case 'videoControls.sleepTimer': return '수면 타이머';
			case 'videoControls.timerActive': return '타이머 활성화됨';
			case 'videoControls.playbackWillPauseIn': return ({required Object duration}) => '재생이 ${duration} 후에 일시 중지 됩니다';
			case 'videoControls.sleepTimerCompleted': return '수면 타이머 완료됨 - 재생이 일시 중지되었습니다';
			case 'videoControls.playButton': return '재생';
			case 'videoControls.pauseButton': return '일시정지';
			case 'videoControls.seekBackwardButton': return ({required Object seconds}) => '${seconds} 초 뒤로';
			case 'videoControls.seekForwardButton': return ({required Object seconds}) => '${seconds} 초 앞으로';
			case 'videoControls.previousButton': return '이전 에피소드';
			case 'videoControls.nextButton': return '다음 에피소드';
			case 'videoControls.previousChapterButton': return '이전 챕터';
			case 'videoControls.nextChapterButton': return '다음 챕터';
			case 'videoControls.muteButton': return '음소거';
			case 'videoControls.unmuteButton': return '음소거 해제';
			case 'videoControls.settingsButton': return '동영상 설정';
			case 'videoControls.audioTrackButton': return '음원 트랙';
			case 'videoControls.subtitlesButton': return '자막';
			case 'videoControls.chaptersButton': return '챕터';
			case 'videoControls.versionsButton': return '동영상 버전';
			case 'videoControls.pipButton': return '픽처 인 픽처 모드';
			case 'videoControls.aspectRatioButton': return '화면비율';
			case 'videoControls.fullscreenButton': return '전체화면';
			case 'videoControls.exitFullscreenButton': return '전체화면 종료';
			case 'videoControls.alwaysOnTopButton': return '창 최상위 고정';
			case 'videoControls.rotationLockButton': return '회전 잠금';
			case 'videoControls.timelineSlider': return '타임라인';
			case 'videoControls.volumeSlider': return '볼륨 조절';
			case 'videoControls.backButton': return '뒤로 가기';
			case 'userStatus.admin': return '관리자';
			case 'userStatus.restricted': return '제한됨';
			case 'userStatus.protected': return '보호됨';
			case 'userStatus.current': return '현재';
			case 'messages.markedAsWatched': return '시청 완료로 표시됨';
			case 'messages.markedAsUnwatched': return '시청 안 함으로 표시됨';
			case 'messages.markedAsWatchedOffline': return '시청 완료로 표시됨 (연결 시 동기화됨)';
			case 'messages.markedAsUnwatchedOffline': return '미시청으로 표시됨 (연결 시 동기화됨)';
			case 'messages.removedFromContinueWatching': return '계속 시청 목록에서 제거됨';
			case 'messages.errorLoading': return ({required Object error}) => '오류: ${error}';
			case 'messages.fileInfoNotAvailable': return '파일 정보가 없습니다';
			case 'messages.errorLoadingFileInfo': return ({required Object error}) => '파일 정보 로딩 중 오류: ${error}';
			case 'messages.errorLoadingSeries': return '시리즈 로딩 중 오류';
			case 'messages.errorLoadingSeason': return '시즌 로딩 중 오류';
			case 'messages.musicNotSupported': return '음악 재생 미지원';
			case 'messages.logsCleared': return '로그가 삭제 되었습니다';
			case 'messages.logsCopied': return '로그가 클립보드에 복사 되었습니다';
			case 'messages.noLogsAvailable': return '사용 가능한 로그가 없습니다';
			case 'messages.libraryScanning': return ({required Object title}) => '"${title}"을(를) 스캔 중입니다...';
			case 'messages.libraryScanStarted': return ({required Object title}) => '"${title}" 미디어 라이브러리 스캔 시작';
			case 'messages.libraryScanFailed': return ({required Object error}) => '미디어 라이브러리 스캔 실패: ${error}';
			case 'messages.metadataRefreshing': return ({required Object title}) => '"${title}" 메타데이터 새로고침 중...';
			case 'messages.metadataRefreshStarted': return ({required Object title}) => '"${title}" 메타데이터 새로고침 시작됨';
			case 'messages.metadataRefreshFailed': return ({required Object error}) => '메타데이터 새로고침 실패: ${error}';
			case 'messages.logoutConfirm': return '로그아웃 하시겠습니까?';
			case 'messages.noSeasonsFound': return '시즌을 찾을 수 없음';
			case 'messages.noEpisodesFound': return '시즌 1에서 에피소드를 찾을 수 없습니다';
			case 'messages.noEpisodesFoundGeneral': return '에피소드를 찾을 수 없습니다';
			case 'messages.noResultsFound': return '결과를 찾을 수 없습니다';
			case 'messages.sleepTimerSet': return ({required Object label}) => '수면 타이머가 ${label}로 설정 되었습니다';
			case 'messages.noItemsAvailable': return '사용 가능한 항목이 없습니다';
			case 'messages.failedToCreatePlayQueue': return '재생 대기열 생성 실패';
			case 'messages.failedToCreatePlayQueueNoItems': return '재생 대기열 생성 실패 - 항목 없음';
			case 'messages.failedPlayback': return ({required Object action, required Object error}) => '${action}을(를) 수행할 수 없습니다: ${error}';
			case 'subtitlingStyling.stylingOptions': return '스타일 옵션';
			case 'subtitlingStyling.fontSize': return '글자 크기';
			case 'subtitlingStyling.textColor': return '텍스트 색상';
			case 'subtitlingStyling.borderSize': return '테두리 크기';
			case 'subtitlingStyling.borderColor': return '테두리 색상';
			case 'subtitlingStyling.backgroundOpacity': return '배경 불투명도';
			case 'subtitlingStyling.backgroundColor': return '배경색';
			case 'mpvConfig.title': return 'MPV 설정';
			case 'mpvConfig.description': return '고급 비디오 플레이어 설정';
			case 'mpvConfig.properties': return '속성';
			case 'mpvConfig.presets': return '사전 설정';
			case 'mpvConfig.noProperties': return '설정된 속성이 없습니다';
			case 'mpvConfig.noPresets': return '저장된 사전 설정이 없습니다';
			case 'mpvConfig.addProperty': return '속성 추가';
			case 'mpvConfig.editProperty': return '속성 편집';
			case 'mpvConfig.deleteProperty': return '속성 삭제';
			case 'mpvConfig.propertyKey': return '속성 키';
			case 'mpvConfig.propertyKeyHint': return '예: hwdec, demuxer-max-bytes';
			case 'mpvConfig.propertyValue': return '속성값';
			case 'mpvConfig.propertyValueHint': return '예: auto, 256000000';
			case 'mpvConfig.saveAsPreset': return '프리셋으로 저장...';
			case 'mpvConfig.presetName': return '프리셋 이름';
			case 'mpvConfig.presetNameHint': return '이 프리셋의 이름을 입력하세요';
			case 'mpvConfig.loadPreset': return '로드';
			case 'mpvConfig.deletePreset': return '삭제';
			case 'mpvConfig.presetSaved': return '프리셋이 저장 되었습니다';
			case 'mpvConfig.presetLoaded': return '프리셋이 로드 되었습니다';
			case 'mpvConfig.presetDeleted': return '프리셋이 삭제 되었습니다';
			case 'mpvConfig.confirmDeletePreset': return '이 프리셋을 삭제 하시겠습니까?';
			case 'mpvConfig.confirmDeleteProperty': return '이 속성을 삭제 하시겠습니까?';
			case 'mpvConfig.entriesCount': return ({required Object count}) => '${count} 항목';
			case 'dialog.confirmAction': return '확인';
			case 'dialog.cancel': return '취소';
			case 'dialog.playNow': return '지금 재생';
			case 'discover.title': return '발견';
			case 'discover.switchProfile': return '사용자 전환';
			case 'discover.switchServer': return '서버 전환';
			case 'discover.logout': return '로그아웃';
			case 'discover.noContentAvailable': return '사용 가능한 콘텐츠가 없습니다';
			case 'discover.addMediaToLibraries': return '미디어 라이브러리에 미디어를 추가해 주세요';
			case 'discover.continueWatching': return '계속 시청';
			case 'discover.play': return '재생';
			case 'discover.playEpisode': return ({required Object season, required Object episode}) => 'S${season}E${episode}';
			case 'discover.pause': return '일시정지';
			case 'discover.overview': return '개요';
			case 'discover.cast': return '출연진';
			case 'discover.seasons': return '시즌 수';
			case 'discover.studio': return '제작사';
			case 'discover.rating': return '연령 등급';
			case 'discover.watched': return '시청 완료';
			case 'discover.episodeCount': return ({required Object count}) => '${count} 편';
			case 'discover.watchedProgress': return ({required Object watched, required Object total}) => '${watched}/${total} 편 시청 완료';
			case 'discover.movie': return '영화';
			case 'discover.tvShow': return 'TV 시리즈';
			case 'discover.minutesLeft': return ({required Object minutes}) => '${minutes}분 남음';
			case 'errors.searchFailed': return ({required Object error}) => '검색 실패: ${error}';
			case 'errors.connectionTimeout': return ({required Object context}) => '${context} 로드 중 연결 시간 초과';
			case 'errors.connectionFailed': return 'Plex 서버에 연결할 수 없음';
			case 'errors.failedToLoad': return ({required Object context, required Object error}) => '${context} 로드 실패: ${error}';
			case 'errors.noClientAvailable': return '사용 가능한 클라이언트가 없습니다';
			case 'errors.authenticationFailed': return ({required Object error}) => '인증 실패: ${error}';
			case 'errors.couldNotLaunchUrl': return '인증 URL을 열 수 없습니다';
			case 'errors.pleaseEnterToken': return '토큰을 입력해 주세요';
			case 'errors.invalidToken': return '토큰이 유효하지 않습니다';
			case 'errors.failedToVerifyToken': return ({required Object error}) => '토큰을 확인할 수 없습니다: ${error}';
			case 'errors.failedToSwitchProfile': return ({required Object displayName}) => '${displayName}으로 전환할 수 없습니다';
			case 'libraries.title': return '미디어 라이브러리';
			case 'libraries.scanLibraryFiles': return '미디어 라이브러리 파일 스캔';
			case 'libraries.scanLibrary': return '미디어 라이브러리 스캔';
			case 'libraries.analyze': return '분석';
			case 'libraries.analyzeLibrary': return '미디어 라이브러리 분석';
			case 'libraries.refreshMetadata': return '메타데이터 새로 고침';
			case 'libraries.emptyTrash': return '휴지통 비우기';
			case 'libraries.emptyingTrash': return ({required Object title}) => '「${title}」의 휴지통을 비우고 있습니다...';
			case 'libraries.trashEmptied': return ({required Object title}) => '「${title}」의 휴지통을 비웠습니다';
			case 'libraries.failedToEmptyTrash': return ({required Object error}) => '휴지통 비우기 실패: ${error}';
			case 'libraries.analyzing': return ({required Object title}) => '"${title}" 분석 중...';
			case 'libraries.analysisStarted': return ({required Object title}) => '"${title}" 분석 시작됨';
			case 'libraries.failedToAnalyze': return ({required Object error}) => '미디어 라이브러리 분석 실패: ${error}';
			case 'libraries.noLibrariesFound': return '미디어 라이브러리 없음';
			case 'libraries.thisLibraryIsEmpty': return '이 미디어 라이브러리는 비어 있습니다';
			case 'libraries.all': return '전체';
			case 'libraries.clearAll': return '모두 삭제';
			case 'libraries.scanLibraryConfirm': return ({required Object title}) => '「${title}」를 스캔 하시겠습니까?';
			case 'libraries.analyzeLibraryConfirm': return ({required Object title}) => '「${title}」를 분석 하시겠습니까?';
			case 'libraries.refreshMetadataConfirm': return ({required Object title}) => '「${title}」의 메타데이터를 새로고침 하시겠습니까?';
			case 'libraries.emptyTrashConfirm': return ({required Object title}) => '${title}의 휴지통을 비우시겠습니까?';
			case 'libraries.manageLibraries': return '미디어 라이브러리 관리';
			case 'libraries.sort': return '정렬';
			case 'libraries.sortBy': return '정렬 기준';
			case 'libraries.filters': return '필터';
			case 'libraries.confirmActionMessage': return '이 작업을 실행 하시겠습니까?';
			case 'libraries.showLibrary': return '미디어 라이브러리 표시';
			case 'libraries.hideLibrary': return '미디어 라이브러리 숨기기';
			case 'libraries.libraryOptions': return '미디어 라이브러리 옵션';
			case 'libraries.content': return '미디어 라이브러리 콘텐츠';
			case 'libraries.selectLibrary': return '미디어 라이브러리 선택';
			case 'libraries.filtersWithCount': return ({required Object count}) => '필터 (${count})';
			case 'libraries.noRecommendations': return '추천 없음';
			case 'libraries.noCollections': return '이 미디어 라이브러리에는 컬렉션이 없습니다';
			case 'libraries.noFoldersFound': return '폴더를 찾을 수 없습니다';
			case 'libraries.folders': return '폴더';
			case 'libraries.tabs.recommended': return '추천';
			case 'libraries.tabs.browse': return '찾아보기';
			case 'libraries.tabs.collections': return '컬렉션';
			case 'libraries.tabs.playlists': return '재생 목록';
			case 'libraries.groupings.all': return '전체';
			case 'libraries.groupings.movies': return '영화';
			case 'libraries.groupings.shows': return 'TV 프로그램';
			case 'libraries.groupings.seasons': return '시즌';
			case 'libraries.groupings.episodes': return '화';
			case 'libraries.groupings.folders': return '폴더';
			case 'about.title': return '소개';
			case 'about.openSourceLicenses': return '오픈소스 라이선스';
			case 'about.versionLabel': return ({required Object version}) => '버전 ${version}';
			case 'about.appDescription': return '아름다운 Flutter Plex 클라이언트';
			case 'about.viewLicensesDescription': return '타사 라이브러리 라이선스 보기';
			case 'serverSelection.allServerConnectionsFailed': return '어떤 서버에도 연결할 수 없습니다. 네트워크를 확인하고 다시 시도하세요.';
			case 'serverSelection.noServersFound': return '서버를 찾을 수 없습니다.';
			case 'serverSelection.noServersFoundForAccount': return ({required Object username, required Object email}) => '${username} (${email})의 서버를 찾을 수 없습니다.';
			case 'serverSelection.failedToLoadServers': return ({required Object error}) => '서버를 로드할 수 없습니다: ${error}';
			case 'hubDetail.title': return '제목';
			case 'hubDetail.releaseYear': return '출시 연도';
			case 'hubDetail.dateAdded': return '추가 날짜';
			case 'hubDetail.rating': return '평점';
			case 'hubDetail.noItemsFound': return '항목이 없습니다';
			case 'logs.clearLogs': return '로그 지우기';
			case 'logs.copyLogs': return '로그 복사';
			case 'logs.error': return '오류:';
			case 'logs.stackTrace': return '스택 추적 (Stack Trace):';
			case 'licenses.relatedPackages': return '관련 소프트웨어 패키지';
			case 'licenses.license': return '라이선스';
			case 'licenses.licenseNumber': return ({required Object number}) => '라이선스 ${number}';
			case 'licenses.licensesCount': return ({required Object count}) => '${count} 개의 라이선스';
			case 'navigation.home': return '홈';
			case 'navigation.search': return '검색';
			case 'navigation.libraries': return '미디어 라이브러리';
			case 'navigation.settings': return '설정';
			case 'navigation.downloads': return '다운로드';
			case 'collections.title': return '컬렉션';
			case 'collections.collection': return '컬렉션';
			case 'collections.empty': return '컬렉션이 비어 있습니다';
			case 'collections.unknownLibrarySection': return '삭제할 수 없습니다: 알 수 없는 미디어 라이브러리 섹션입니다';
			case 'collections.deleteCollection': return '컬렉션 삭제';
			case 'collections.deleteConfirm': return ({required Object title}) => '"${title}"을(를) 삭제 하시겠습니까? 이 작업은 되돌릴 수 없습니다.';
			case 'collections.deleted': return '컬렉션 삭제됨';
			case 'collections.deleteFailed': return '컬렉션 삭제 실패';
			case 'collections.deleteFailedWithError': return ({required Object error}) => '컬렉션 삭제 실패: ${error}';
			case 'collections.failedToLoadItems': return ({required Object error}) => '컬렉션 항목 로드 실패: ${error}';
			case 'collections.selectCollection': return '컬렉션 선택';
			case 'collections.createNewCollection': return '새 컬렉션 생성';
			case 'collections.collectionName': return '컬렉션 이름';
			case 'collections.enterCollectionName': return '컬렉션 이름 입력';
			case 'collections.addedToCollection': return '컬렉션에 추가됨';
			case 'collections.errorAddingToCollection': return '컬렉션에 추가 실패';
			case 'collections.created': return '컬렉션 생성됨';
			case 'collections.removeFromCollection': return '컬렉션에서 제거';
			case 'collections.removeFromCollectionConfirm': return ({required Object title}) => '${title}을/를 이 컬렉션에서 제거 하시겠습니까?';
			case 'collections.removedFromCollection': return '컬렉션에서 제거됨';
			case 'collections.removeFromCollectionFailed': return '컬렉션에서 제거 실패';
			case 'collections.removeFromCollectionError': return ({required Object error}) => '컬렉션에서 제거 중 오류 발생: ${error}';
			case 'playlists.title': return '플레이리스트';
			case 'playlists.playlist': return '재생 목록';
			case 'playlists.noPlaylists': return '재생 목록을 찾을 수 없습니다';
			case 'playlists.create': return '재생 목록 생성';
			case 'playlists.playlistName': return '재생 목록 이름';
			case 'playlists.enterPlaylistName': return '재생 목록 이름 입력';
			case 'playlists.delete': return '재생 목록 삭제';
			case 'playlists.removeItem': return '재생 목록에서 항목 제거';
			case 'playlists.smartPlaylist': return '스마트 재생 목록';
			case 'playlists.itemCount': return ({required Object count}) => '${count}개 항목';
			case 'playlists.oneItem': return '1개 항목';
			case 'playlists.emptyPlaylist': return '이 재생 목록은 비어 있습니다';
			case 'playlists.deleteConfirm': return '재생 목록을 삭제 하시겠습니까?';
			case 'playlists.deleteMessage': return ({required Object name}) => '"${name}"을(를) 삭제 하시겠습니까?';
			case 'playlists.created': return '재생 목록이 생성 되었습니다';
			case 'playlists.deleted': return '재생 목록이 삭제 되었습니다';
			case 'playlists.itemAdded': return '재생 목록에 추가 되었습니다';
			case 'playlists.itemRemoved': return '재생 목록에서 제거됨';
			case 'playlists.selectPlaylist': return '재생 목록 선택';
			case 'playlists.createNewPlaylist': return '새 재생 목록 생성';
			case 'playlists.errorCreating': return '재생 목록 생성 실패';
			case 'playlists.errorDeleting': return '재생 목록 삭제 실패';
			case 'playlists.errorLoading': return '재생 목록 로드 실패';
			case 'playlists.errorAdding': return '재생 목록에 추가 실패';
			case 'playlists.errorReordering': return '재생 목록 항목 재정렬 실패';
			case 'playlists.errorRemoving': return '재생 목록에서 제거 실패';
			case 'watchTogether.title': return '함께 보기';
			case 'watchTogether.description': return '친구 및 가족과 콘텐츠를 동시에 시청하세요';
			case 'watchTogether.createSession': return '세션 생성';
			case 'watchTogether.creating': return '생성 중...';
			case 'watchTogether.joinSession': return '세션 참여';
			case 'watchTogether.joining': return '참가 중...';
			case 'watchTogether.controlMode': return '제어 모드';
			case 'watchTogether.controlModeQuestion': return '누가 재생을 제어할 수 있나요?';
			case 'watchTogether.hostOnly': return '호스트만';
			case 'watchTogether.anyone': return '누구나';
			case 'watchTogether.hostingSession': return '세션 호스팅';
			case 'watchTogether.inSession': return '세션 중';
			case 'watchTogether.sessionCode': return '세션 코드';
			case 'watchTogether.hostControlsPlayback': return '호스트 재생 제어';
			case 'watchTogether.anyoneCanControl': return '누구나 재생 제어 가능';
			case 'watchTogether.hostControls': return '호스트 제어';
			case 'watchTogether.anyoneControls': return '누구나 제어';
			case 'watchTogether.participants': return '참가자';
			case 'watchTogether.host': return '호스트';
			case 'watchTogether.hostBadge': return '호스트';
			case 'watchTogether.youAreHost': return '당신은 호스트 입니다';
			case 'watchTogether.watchingWithOthers': return '다른 사람과 함께 시청 중';
			case 'watchTogether.endSession': return '세션 종료';
			case 'watchTogether.leaveSession': return '세션 탈퇴';
			case 'watchTogether.endSessionQuestion': return '세션을 종료 하시겠습니까?';
			case 'watchTogether.leaveSessionQuestion': return '세션을 탈퇴 하시겠습니까?';
			case 'watchTogether.endSessionConfirm': return '이 작업은 모든 참가자의 세션을 종료합니다.';
			case 'watchTogether.leaveSessionConfirm': return '당신은 세션에서 제거됩니다.';
			case 'watchTogether.endSessionConfirmOverlay': return '이것은 모든 참가자의 시청 세션을 종료합니다.';
			case 'watchTogether.leaveSessionConfirmOverlay': return '시청 세션 연결이 끊어집니다.';
			case 'watchTogether.end': return '종료';
			case 'watchTogether.leave': return '이탈';
			case 'watchTogether.syncing': return '동기화 중...';
			case 'watchTogether.participant': return '참여자';
			case 'watchTogether.joinWatchSession': return '시청 세션에 참여';
			case 'watchTogether.enterCodeHint': return '8자리 코드 입력';
			case 'watchTogether.pasteFromClipboard': return '클립보드에서 붙여넣기';
			case 'watchTogether.pleaseEnterCode': return '세션 코드를 입력하세요';
			case 'watchTogether.codeMustBe8Chars': return '세션 코드는 반드시 8자리여야 합니다';
			case 'watchTogether.joinInstructions': return '호스트가 공유한 세션 코드를 입력하여 시청 세션에 참여하세요.';
			case 'watchTogether.failedToCreate': return '세션 생성 실패';
			case 'watchTogether.failedToJoin': return '세션 참여 실패';
			case 'downloads.title': return '다운로드';
			case 'downloads.manage': return '관리';
			case 'downloads.tvShows': return 'TV 프로그램';
			case 'downloads.movies': return '영화';
			case 'downloads.noDownloads': return '다운로드 없음';
			case 'downloads.noDownloadsDescription': return '다운로드한 콘텐츠는 오프라인 시청을 위해 여기에 표시됩니다';
			case 'downloads.downloadNow': return '다운로드';
			case 'downloads.deleteDownload': return '다운로드 삭제';
			case 'downloads.retryDownload': return '다운로드 재시도';
			case 'downloads.downloadQueued': return '다운로드 대기 중';
			case 'downloads.episodesQueued': return ({required Object count}) => '${count} 에피소드가 다운로드 대기열에 추가 되었습니다';
			case 'downloads.downloadDeleted': return '다운로드 삭제됨';
			case 'downloads.deleteConfirm': return ({required Object title}) => '"${title}"를 삭제 하시겠습니까? 다운로드한 파일이 기기에서 삭제됩니다.';
			case 'downloads.deletingWithProgress': return ({required Object title, required Object current, required Object total}) => '${title} 삭제 중... (${current}/${total})';
			default: return null;
		}
	}
}

extension on _StringsNl {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'app.title': return 'Plezy';
			case 'app.loading': return 'Laden...';
			case 'auth.signInWithPlex': return 'Inloggen met Plex';
			case 'auth.showQRCode': return 'Toon QR-code';
			case 'auth.cancel': return 'Annuleren';
			case 'auth.authenticate': return 'Authenticeren';
			case 'auth.retry': return 'Opnieuw proberen';
			case 'auth.debugEnterToken': return 'Debug: Voer Plex Token in';
			case 'auth.plexTokenLabel': return 'Plex Authenticatietoken';
			case 'auth.plexTokenHint': return 'Voer je Plex.tv token in';
			case 'auth.authenticationTimeout': return 'Authenticatie verlopen. Probeer opnieuw.';
			case 'auth.scanQRCodeInstruction': return 'Scan deze QR-code met een apparaat dat is ingelogd op Plex om te authenticeren.';
			case 'auth.waitingForAuth': return 'Wachten op authenticatie...\nVoltooi het inloggen in je browser.';
			case 'common.cancel': return 'Annuleren';
			case 'common.save': return 'Opslaan';
			case 'common.close': return 'Sluiten';
			case 'common.clear': return 'Wissen';
			case 'common.reset': return 'Resetten';
			case 'common.later': return 'Later';
			case 'common.submit': return 'Verzenden';
			case 'common.confirm': return 'Bevestigen';
			case 'common.retry': return 'Opnieuw proberen';
			case 'common.logout': return 'Uitloggen';
			case 'common.unknown': return 'Onbekend';
			case 'common.refresh': return 'Vernieuwen';
			case 'common.yes': return 'Ja';
			case 'common.no': return 'Nee';
			case 'common.delete': return 'Verwijderen';
			case 'common.shuffle': return 'Willekeurig';
			case 'common.addTo': return 'Toevoegen aan...';
			case 'screens.licenses': return 'Licenties';
			case 'screens.selectServer': return 'Selecteer server';
			case 'screens.switchProfile': return 'Wissel van profiel';
			case 'screens.subtitleStyling': return 'Ondertitel opmaak';
			case 'screens.mpvConfig': return 'MPV-configuratie';
			case 'screens.search': return 'Zoeken';
			case 'screens.logs': return 'Logbestanden';
			case 'update.available': return 'Update beschikbaar';
			case 'update.versionAvailable': return ({required Object version}) => 'Versie ${version} is beschikbaar';
			case 'update.currentVersion': return ({required Object version}) => 'Huidig: ${version}';
			case 'update.skipVersion': return 'Deze versie overslaan';
			case 'update.viewRelease': return 'Bekijk release';
			case 'update.latestVersion': return 'Je hebt de nieuwste versie';
			case 'update.checkFailed': return 'Kon niet controleren op updates';
			case 'settings.title': return 'Instellingen';
			case 'settings.language': return 'Taal';
			case 'settings.theme': return 'Thema';
			case 'settings.appearance': return 'Uiterlijk';
			case 'settings.videoPlayback': return 'Video afspelen';
			case 'settings.advanced': return 'Geavanceerd';
			case 'settings.episodePosterMode': return 'Aflevering poster stijl';
			case 'settings.seriesPoster': return 'Serie poster';
			case 'settings.seriesPosterDescription': return 'Toon de serie poster voor alle afleveringen';
			case 'settings.seasonPoster': return 'Seizoen poster';
			case 'settings.seasonPosterDescription': return 'Toon de seizoensspecifieke poster voor afleveringen';
			case 'settings.episodeThumbnail': return 'Aflevering miniatuur';
			case 'settings.episodeThumbnailDescription': return 'Toon 16:9 aflevering miniaturen';
			case 'settings.showHeroSectionDescription': return 'Toon uitgelichte inhoud carrousel op startscherm';
			case 'settings.secondsLabel': return 'Seconden';
			case 'settings.minutesLabel': return 'Minuten';
			case 'settings.secondsShort': return 's';
			case 'settings.minutesShort': return 'm';
			case 'settings.durationHint': return ({required Object min, required Object max}) => 'Voer duur in (${min}-${max})';
			case 'settings.systemTheme': return 'Systeem';
			case 'settings.systemThemeDescription': return 'Volg systeeminstellingen';
			case 'settings.lightTheme': return 'Licht';
			case 'settings.darkTheme': return 'Donker';
			case 'settings.libraryDensity': return 'Bibliotheek dichtheid';
			case 'settings.compact': return 'Compact';
			case 'settings.compactDescription': return 'Kleinere kaarten, meer items zichtbaar';
			case 'settings.normal': return 'Normaal';
			case 'settings.normalDescription': return 'Standaard grootte';
			case 'settings.comfortable': return 'Comfortabel';
			case 'settings.comfortableDescription': return 'Grotere kaarten, minder items zichtbaar';
			case 'settings.viewMode': return 'Weergavemodus';
			case 'settings.gridView': return 'Raster';
			case 'settings.gridViewDescription': return 'Items weergeven in een rasterindeling';
			case 'settings.listView': return 'Lijst';
			case 'settings.listViewDescription': return 'Items weergeven in een lijstindeling';
			case 'settings.showHeroSection': return 'Toon hoofdsectie';
			case 'settings.useGlobalHubs': return 'Plex Home-indeling gebruiken';
			case 'settings.useGlobalHubsDescription': return 'Toon startpagina-hubs zoals de officiële Plex-client. Indien uitgeschakeld, worden in plaats daarvan aanbevelingen per bibliotheek getoond.';
			case 'settings.hardwareDecoding': return 'Hardware decodering';
			case 'settings.hardwareDecodingDescription': return 'Gebruik hardware versnelling indien beschikbaar';
			case 'settings.bufferSize': return 'Buffer grootte';
			case 'settings.bufferSizeMB': return ({required Object size}) => '${size}MB';
			case 'settings.subtitleStyling': return 'Ondertitel opmaak';
			case 'settings.subtitleStylingDescription': return 'Pas ondertitel uiterlijk aan';
			case 'settings.smallSkipDuration': return 'Korte skip duur';
			case 'settings.largeSkipDuration': return 'Lange skip duur';
			case 'settings.secondsUnit': return ({required Object seconds}) => '${seconds} seconden';
			case 'settings.defaultSleepTimer': return 'Standaard slaap timer';
			case 'settings.minutesUnit': return ({required Object minutes}) => 'bij ${minutes} minuten';
			case 'settings.rememberTrackSelections': return 'Onthoud track selecties per serie/film';
			case 'settings.rememberTrackSelectionsDescription': return 'Bewaar automatisch audio- en ondertiteltaalvoorkeuren wanneer je tracks wijzigt tijdens afspelen';
			case 'settings.videoPlayerControls': return 'Videospeler bediening';
			case 'settings.keyboardShortcuts': return 'Toetsenbord sneltoetsen';
			case 'settings.keyboardShortcutsDescription': return 'Pas toetsenbord sneltoetsen aan';
			case 'settings.videoPlayerNavigation': return 'Videospeler navigatie';
			case 'settings.videoPlayerNavigationDescription': return 'Gebruik pijltjestoetsen om door de videospeler bediening te navigeren';
			case 'settings.debugLogging': return 'Debug logging';
			case 'settings.debugLoggingDescription': return 'Schakel gedetailleerde logging in voor probleemoplossing';
			case 'settings.viewLogs': return 'Bekijk logs';
			case 'settings.viewLogsDescription': return 'Bekijk applicatie logs';
			case 'settings.clearCache': return 'Cache wissen';
			case 'settings.clearCacheDescription': return 'Dit wist alle gecachte afbeeldingen en gegevens. De app kan langer duren om inhoud te laden na het wissen van de cache.';
			case 'settings.clearCacheSuccess': return 'Cache succesvol gewist';
			case 'settings.resetSettings': return 'Instellingen resetten';
			case 'settings.resetSettingsDescription': return 'Dit reset alle instellingen naar hun standaard waarden. Deze actie kan niet ongedaan gemaakt worden.';
			case 'settings.resetSettingsSuccess': return 'Instellingen succesvol gereset';
			case 'settings.shortcutsReset': return 'Sneltoetsen gereset naar standaard';
			case 'settings.about': return 'Over';
			case 'settings.aboutDescription': return 'App informatie en licenties';
			case 'settings.updates': return 'Updates';
			case 'settings.updateAvailable': return 'Update beschikbaar';
			case 'settings.checkForUpdates': return 'Controleer op updates';
			case 'settings.validationErrorEnterNumber': return 'Voer een geldig nummer in';
			case 'settings.validationErrorDuration': return ({required Object min, required Object max, required Object unit}) => 'Duur moet tussen ${min} en ${max} ${unit} zijn';
			case 'settings.shortcutAlreadyAssigned': return ({required Object action}) => 'Sneltoets al toegewezen aan ${action}';
			case 'settings.shortcutUpdated': return ({required Object action}) => 'Sneltoets bijgewerkt voor ${action}';
			case 'settings.autoSkip': return 'Automatisch Overslaan';
			case 'settings.autoSkipIntro': return 'Intro Automatisch Overslaan';
			case 'settings.autoSkipIntroDescription': return 'Intro-markeringen na enkele seconden automatisch overslaan';
			case 'settings.autoSkipCredits': return 'Credits Automatisch Overslaan';
			case 'settings.autoSkipCreditsDescription': return 'Credits automatisch overslaan en volgende aflevering afspelen';
			case 'settings.autoSkipDelay': return 'Vertraging Automatisch Overslaan';
			case 'settings.autoSkipDelayDescription': return ({required Object seconds}) => '${seconds} seconden wachten voor automatisch overslaan';
			case 'settings.downloads': return 'Downloads';
			case 'settings.downloadLocationDescription': return 'Kies waar gedownloade content wordt opgeslagen';
			case 'settings.downloadLocationDefault': return 'Standaard (App-opslag)';
			case 'settings.downloadLocationCustom': return 'Aangepaste Locatie';
			case 'settings.selectFolder': return 'Selecteer Map';
			case 'settings.resetToDefault': return 'Herstel naar Standaard';
			case 'settings.currentPath': return ({required Object path}) => 'Huidig: ${path}';
			case 'settings.downloadLocationChanged': return 'Downloadlocatie gewijzigd';
			case 'settings.downloadLocationReset': return 'Downloadlocatie hersteld naar standaard';
			case 'settings.downloadLocationInvalid': return 'Geselecteerde map is niet beschrijfbaar';
			case 'settings.downloadLocationSelectError': return 'Kan map niet selecteren';
			case 'settings.downloadOnWifiOnly': return 'Alleen via WiFi downloaden';
			case 'settings.downloadOnWifiOnlyDescription': return 'Voorkom downloads bij gebruik van mobiele data';
			case 'settings.cellularDownloadBlocked': return 'Downloads zijn uitgeschakeld bij mobiele data. Maak verbinding met WiFi of wijzig de instelling.';
			case 'settings.maxVolume': return 'Maximaal volume';
			case 'settings.maxVolumeDescription': return 'Volume boven 100% toestaan voor stille media';
			case 'settings.maxVolumePercent': return ({required Object percent}) => '${percent}%';
			case 'settings.maxVolumeHint': return 'Voer maximaal volume in (100-300)';
			case 'settings.discordRichPresence': return 'Discord Rich Presence';
			case 'settings.discordRichPresenceDescription': return 'Toon op Discord wat je aan het kijken bent';
			case 'search.hint': return 'Zoek films, series, muziek...';
			case 'search.tryDifferentTerm': return 'Probeer een andere zoekterm';
			case 'search.searchYourMedia': return 'Zoek in je media';
			case 'search.enterTitleActorOrKeyword': return 'Voer een titel, acteur of trefwoord in';
			case 'hotkeys.setShortcutFor': return ({required Object actionName}) => 'Stel sneltoets in voor ${actionName}';
			case 'hotkeys.clearShortcut': return 'Wis sneltoets';
			case 'pinEntry.enterPin': return 'Voer PIN in';
			case 'pinEntry.showPin': return 'Toon PIN';
			case 'pinEntry.hidePin': return 'Verberg PIN';
			case 'fileInfo.title': return 'Bestand info';
			case 'fileInfo.video': return 'Video';
			case 'fileInfo.audio': return 'Audio';
			case 'fileInfo.file': return 'Bestand';
			case 'fileInfo.advanced': return 'Geavanceerd';
			case 'fileInfo.codec': return 'Codec';
			case 'fileInfo.resolution': return 'Resolutie';
			case 'fileInfo.bitrate': return 'Bitrate';
			case 'fileInfo.frameRate': return 'Frame rate';
			case 'fileInfo.aspectRatio': return 'Beeldverhouding';
			case 'fileInfo.profile': return 'Profiel';
			case 'fileInfo.bitDepth': return 'Bit diepte';
			case 'fileInfo.colorSpace': return 'Kleurruimte';
			case 'fileInfo.colorRange': return 'Kleurbereik';
			case 'fileInfo.colorPrimaries': return 'Kleurprimaires';
			case 'fileInfo.chromaSubsampling': return 'Chroma subsampling';
			case 'fileInfo.channels': return 'Kanalen';
			case 'fileInfo.path': return 'Pad';
			case 'fileInfo.size': return 'Grootte';
			case 'fileInfo.container': return 'Container';
			case 'fileInfo.duration': return 'Duur';
			case 'fileInfo.optimizedForStreaming': return 'Geoptimaliseerd voor streaming';
			case 'fileInfo.has64bitOffsets': return '64-bit Offsets';
			case 'mediaMenu.markAsWatched': return 'Markeer als gekeken';
			case 'mediaMenu.markAsUnwatched': return 'Markeer als ongekeken';
			case 'mediaMenu.removeFromContinueWatching': return 'Verwijder uit Doorgaan met kijken';
			case 'mediaMenu.goToSeries': return 'Ga naar serie';
			case 'mediaMenu.goToSeason': return 'Ga naar seizoen';
			case 'mediaMenu.shufflePlay': return 'Willekeurig afspelen';
			case 'mediaMenu.fileInfo': return 'Bestand info';
			case 'accessibility.mediaCardMovie': return ({required Object title}) => '${title}, film';
			case 'accessibility.mediaCardShow': return ({required Object title}) => '${title}, TV-serie';
			case 'accessibility.mediaCardEpisode': return ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
			case 'accessibility.mediaCardSeason': return ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
			case 'accessibility.mediaCardWatched': return 'bekeken';
			case 'accessibility.mediaCardPartiallyWatched': return ({required Object percent}) => '${percent} procent bekeken';
			case 'accessibility.mediaCardUnwatched': return 'niet bekeken';
			case 'accessibility.tapToPlay': return 'Tik om af te spelen';
			case 'tooltips.shufflePlay': return 'Willekeurig afspelen';
			case 'tooltips.markAsWatched': return 'Markeer als gekeken';
			case 'tooltips.markAsUnwatched': return 'Markeer als ongekeken';
			case 'videoControls.audioLabel': return 'Audio';
			case 'videoControls.subtitlesLabel': return 'Ondertitels';
			case 'videoControls.resetToZero': return 'Reset naar 0ms';
			case 'videoControls.addTime': return ({required Object amount, required Object unit}) => '+${amount}${unit}';
			case 'videoControls.minusTime': return ({required Object amount, required Object unit}) => '-${amount}${unit}';
			case 'videoControls.playsLater': return ({required Object label}) => '${label} speelt later af';
			case 'videoControls.playsEarlier': return ({required Object label}) => '${label} speelt eerder af';
			case 'videoControls.noOffset': return 'Geen offset';
			case 'videoControls.letterbox': return 'Letterbox';
			case 'videoControls.fillScreen': return 'Vul scherm';
			case 'videoControls.stretch': return 'Uitrekken';
			case 'videoControls.lockRotation': return 'Vergrendel rotatie';
			case 'videoControls.unlockRotation': return 'Ontgrendel rotatie';
			case 'videoControls.sleepTimer': return 'Slaaptimer';
			case 'videoControls.timerActive': return 'Timer actief';
			case 'videoControls.playbackWillPauseIn': return ({required Object duration}) => 'Afspelen wordt gepauzeerd over ${duration}';
			case 'videoControls.sleepTimerCompleted': return 'Slaaptimer voltooid - afspelen gepauzeerd';
			case 'videoControls.playButton': return 'Afspelen';
			case 'videoControls.pauseButton': return 'Pauzeren';
			case 'videoControls.seekBackwardButton': return ({required Object seconds}) => 'Terugspoelen ${seconds} seconden';
			case 'videoControls.seekForwardButton': return ({required Object seconds}) => 'Vooruitspoelen ${seconds} seconden';
			case 'videoControls.previousButton': return 'Vorige aflevering';
			case 'videoControls.nextButton': return 'Volgende aflevering';
			case 'videoControls.previousChapterButton': return 'Vorig hoofdstuk';
			case 'videoControls.nextChapterButton': return 'Volgend hoofdstuk';
			case 'videoControls.muteButton': return 'Dempen';
			case 'videoControls.unmuteButton': return 'Dempen opheffen';
			case 'videoControls.settingsButton': return 'Video-instellingen';
			case 'videoControls.audioTrackButton': return 'Audiosporen';
			case 'videoControls.subtitlesButton': return 'Ondertitels';
			case 'videoControls.chaptersButton': return 'Hoofdstukken';
			case 'videoControls.versionsButton': return 'Videoversies';
			case 'videoControls.pipButton': return 'Beeld-in-beeld modus';
			case 'videoControls.aspectRatioButton': return 'Beeldverhouding';
			case 'videoControls.fullscreenButton': return 'Volledig scherm activeren';
			case 'videoControls.exitFullscreenButton': return 'Volledig scherm verlaten';
			case 'videoControls.alwaysOnTopButton': return 'Altijd bovenop';
			case 'videoControls.rotationLockButton': return 'Rotatievergrendeling';
			case 'videoControls.timelineSlider': return 'Videotijdlijn';
			case 'videoControls.volumeSlider': return 'Volumeniveau';
			case 'videoControls.backButton': return 'Terug';
			case 'userStatus.admin': return 'Beheerder';
			case 'userStatus.restricted': return 'Beperkt';
			case 'userStatus.protected': return 'Beschermd';
			case 'userStatus.current': return 'HUIDIG';
			case 'messages.markedAsWatched': return 'Gemarkeerd als gekeken';
			case 'messages.markedAsUnwatched': return 'Gemarkeerd als ongekeken';
			case 'messages.markedAsWatchedOffline': return 'Gemarkeerd als gekeken (sync wanneer online)';
			case 'messages.markedAsUnwatchedOffline': return 'Gemarkeerd als ongekeken (sync wanneer online)';
			case 'messages.removedFromContinueWatching': return 'Verwijderd uit Doorgaan met kijken';
			case 'messages.errorLoading': return ({required Object error}) => 'Fout: ${error}';
			case 'messages.fileInfoNotAvailable': return 'Bestand informatie niet beschikbaar';
			case 'messages.errorLoadingFileInfo': return ({required Object error}) => 'Fout bij laden bestand info: ${error}';
			case 'messages.errorLoadingSeries': return 'Fout bij laden serie';
			case 'messages.errorLoadingSeason': return 'Fout bij laden seizoen';
			case 'messages.musicNotSupported': return 'Muziek afspelen wordt nog niet ondersteund';
			case 'messages.logsCleared': return 'Logs gewist';
			case 'messages.logsCopied': return 'Logs gekopieerd naar klembord';
			case 'messages.noLogsAvailable': return 'Geen logs beschikbaar';
			case 'messages.libraryScanning': return ({required Object title}) => 'Scannen "${title}"...';
			case 'messages.libraryScanStarted': return ({required Object title}) => 'Bibliotheek scan gestart voor "${title}"';
			case 'messages.libraryScanFailed': return ({required Object error}) => 'Kon bibliotheek niet scannen: ${error}';
			case 'messages.metadataRefreshing': return ({required Object title}) => 'Metadata vernieuwen voor "${title}"...';
			case 'messages.metadataRefreshStarted': return ({required Object title}) => 'Metadata vernieuwen gestart voor "${title}"';
			case 'messages.metadataRefreshFailed': return ({required Object error}) => 'Kon metadata niet vernieuwen: ${error}';
			case 'messages.logoutConfirm': return 'Weet je zeker dat je wilt uitloggen?';
			case 'messages.noSeasonsFound': return 'Geen seizoenen gevonden';
			case 'messages.noEpisodesFound': return 'Geen afleveringen gevonden in eerste seizoen';
			case 'messages.noEpisodesFoundGeneral': return 'Geen afleveringen gevonden';
			case 'messages.noResultsFound': return 'Geen resultaten gevonden';
			case 'messages.sleepTimerSet': return ({required Object label}) => 'Slaap timer ingesteld voor ${label}';
			case 'messages.noItemsAvailable': return 'Geen items beschikbaar';
			case 'messages.failedToCreatePlayQueue': return 'Kan afspeelwachtrij niet maken';
			case 'messages.failedToCreatePlayQueueNoItems': return 'Kan afspeelwachtrij niet maken - geen items';
			case 'messages.failedPlayback': return ({required Object action, required Object error}) => 'Afspelen van ${action} mislukt: ${error}';
			case 'subtitlingStyling.stylingOptions': return 'Opmaak opties';
			case 'subtitlingStyling.fontSize': return 'Lettergrootte';
			case 'subtitlingStyling.textColor': return 'Tekstkleur';
			case 'subtitlingStyling.borderSize': return 'Rand grootte';
			case 'subtitlingStyling.borderColor': return 'Randkleur';
			case 'subtitlingStyling.backgroundOpacity': return 'Achtergrond transparantie';
			case 'subtitlingStyling.backgroundColor': return 'Achtergrondkleur';
			case 'mpvConfig.title': return 'MPV-configuratie';
			case 'mpvConfig.description': return 'Geavanceerde videospeler-instellingen';
			case 'mpvConfig.properties': return 'Eigenschappen';
			case 'mpvConfig.presets': return 'Voorinstellingen';
			case 'mpvConfig.noProperties': return 'Geen eigenschappen geconfigureerd';
			case 'mpvConfig.noPresets': return 'Geen opgeslagen voorinstellingen';
			case 'mpvConfig.addProperty': return 'Eigenschap toevoegen';
			case 'mpvConfig.editProperty': return 'Eigenschap bewerken';
			case 'mpvConfig.deleteProperty': return 'Eigenschap verwijderen';
			case 'mpvConfig.propertyKey': return 'Eigenschapssleutel';
			case 'mpvConfig.propertyKeyHint': return 'bijv. hwdec, demuxer-max-bytes';
			case 'mpvConfig.propertyValue': return 'Eigenschapswaarde';
			case 'mpvConfig.propertyValueHint': return 'bijv. auto, 256000000';
			case 'mpvConfig.saveAsPreset': return 'Opslaan als voorinstelling...';
			case 'mpvConfig.presetName': return 'Naam voorinstelling';
			case 'mpvConfig.presetNameHint': return 'Voer een naam in voor deze voorinstelling';
			case 'mpvConfig.loadPreset': return 'Laden';
			case 'mpvConfig.deletePreset': return 'Verwijderen';
			case 'mpvConfig.presetSaved': return 'Voorinstelling opgeslagen';
			case 'mpvConfig.presetLoaded': return 'Voorinstelling geladen';
			case 'mpvConfig.presetDeleted': return 'Voorinstelling verwijderd';
			case 'mpvConfig.confirmDeletePreset': return 'Weet je zeker dat je deze voorinstelling wilt verwijderen?';
			case 'mpvConfig.confirmDeleteProperty': return 'Weet je zeker dat je deze eigenschap wilt verwijderen?';
			case 'mpvConfig.entriesCount': return ({required Object count}) => '${count} items';
			case 'dialog.confirmAction': return 'Bevestig actie';
			case 'dialog.cancel': return 'Annuleren';
			case 'dialog.playNow': return 'Nu afspelen';
			case 'discover.title': return 'Ontdekken';
			case 'discover.switchProfile': return 'Wissel van profiel';
			case 'discover.switchServer': return 'Wissel van server';
			case 'discover.logout': return 'Uitloggen';
			case 'discover.noContentAvailable': return 'Geen inhoud beschikbaar';
			case 'discover.addMediaToLibraries': return 'Voeg wat media toe aan je bibliotheken';
			case 'discover.continueWatching': return 'Verder kijken';
			case 'discover.play': return 'Afspelen';
			case 'discover.playEpisode': return ({required Object season, required Object episode}) => 'S${season}E${episode}';
			case 'discover.pause': return 'Pauzeren';
			case 'discover.overview': return 'Overzicht';
			case 'discover.cast': return 'Acteurs';
			case 'discover.seasons': return 'Seizoenen';
			case 'discover.studio': return 'Studio';
			case 'discover.rating': return 'Leeftijd';
			case 'discover.watched': return 'Bekeken';
			case 'discover.episodeCount': return ({required Object count}) => '${count} afleveringen';
			case 'discover.watchedProgress': return ({required Object watched, required Object total}) => '${watched}/${total} gekeken';
			case 'discover.movie': return 'Film';
			case 'discover.tvShow': return 'TV Serie';
			case 'discover.minutesLeft': return ({required Object minutes}) => '${minutes} min over';
			case 'errors.searchFailed': return ({required Object error}) => 'Zoeken mislukt: ${error}';
			case 'errors.connectionTimeout': return ({required Object context}) => 'Verbinding time-out tijdens laden ${context}';
			case 'errors.connectionFailed': return 'Kan geen verbinding maken met Plex server';
			case 'errors.failedToLoad': return ({required Object context, required Object error}) => 'Kon ${context} niet laden: ${error}';
			case 'errors.noClientAvailable': return 'Geen client beschikbaar';
			case 'errors.authenticationFailed': return ({required Object error}) => 'Authenticatie mislukt: ${error}';
			case 'errors.couldNotLaunchUrl': return 'Kon auth URL niet openen';
			case 'errors.pleaseEnterToken': return 'Voer een token in';
			case 'errors.invalidToken': return 'Ongeldig token';
			case 'errors.failedToVerifyToken': return ({required Object error}) => 'Kon token niet verifiëren: ${error}';
			case 'errors.failedToSwitchProfile': return ({required Object displayName}) => 'Kon niet wisselen naar ${displayName}';
			case 'libraries.title': return 'Bibliotheken';
			case 'libraries.scanLibraryFiles': return 'Scan bibliotheek bestanden';
			case 'libraries.scanLibrary': return 'Scan bibliotheek';
			case 'libraries.analyze': return 'Analyseren';
			case 'libraries.analyzeLibrary': return 'Analyseer bibliotheek';
			case 'libraries.refreshMetadata': return 'Vernieuw metadata';
			case 'libraries.emptyTrash': return 'Prullenbak legen';
			case 'libraries.emptyingTrash': return ({required Object title}) => 'Prullenbak legen voor "${title}"...';
			case 'libraries.trashEmptied': return ({required Object title}) => 'Prullenbak geleegd voor "${title}"';
			case 'libraries.failedToEmptyTrash': return ({required Object error}) => 'Kon prullenbak niet legen: ${error}';
			case 'libraries.analyzing': return ({required Object title}) => 'Analyseren "${title}"...';
			case 'libraries.analysisStarted': return ({required Object title}) => 'Analyse gestart voor "${title}"';
			case 'libraries.failedToAnalyze': return ({required Object error}) => 'Kon bibliotheek niet analyseren: ${error}';
			case 'libraries.noLibrariesFound': return 'Geen bibliotheken gevonden';
			case 'libraries.thisLibraryIsEmpty': return 'Deze bibliotheek is leeg';
			case 'libraries.all': return 'Alles';
			case 'libraries.clearAll': return 'Alles wissen';
			case 'libraries.scanLibraryConfirm': return ({required Object title}) => 'Weet je zeker dat je "${title}" wilt scannen?';
			case 'libraries.analyzeLibraryConfirm': return ({required Object title}) => 'Weet je zeker dat je "${title}" wilt analyseren?';
			case 'libraries.refreshMetadataConfirm': return ({required Object title}) => 'Weet je zeker dat je metadata wilt vernieuwen voor "${title}"?';
			case 'libraries.emptyTrashConfirm': return ({required Object title}) => 'Weet je zeker dat je de prullenbak wilt legen voor "${title}"?';
			case 'libraries.manageLibraries': return 'Beheer bibliotheken';
			case 'libraries.sort': return 'Sorteren';
			case 'libraries.sortBy': return 'Sorteer op';
			case 'libraries.filters': return 'Filters';
			case 'libraries.confirmActionMessage': return 'Weet je zeker dat je deze actie wilt uitvoeren?';
			case 'libraries.showLibrary': return 'Toon bibliotheek';
			case 'libraries.hideLibrary': return 'Verberg bibliotheek';
			case 'libraries.libraryOptions': return 'Bibliotheek opties';
			case 'libraries.content': return 'bibliotheekinhoud';
			case 'libraries.selectLibrary': return 'Bibliotheek kiezen';
			case 'libraries.filtersWithCount': return ({required Object count}) => 'Filters (${count})';
			case 'libraries.noRecommendations': return 'Geen aanbevelingen beschikbaar';
			case 'libraries.noCollections': return 'Geen collecties in deze bibliotheek';
			case 'libraries.noFoldersFound': return 'Geen mappen gevonden';
			case 'libraries.folders': return 'mappen';
			case 'libraries.tabs.recommended': return 'Aanbevolen';
			case 'libraries.tabs.browse': return 'Bladeren';
			case 'libraries.tabs.collections': return 'Collecties';
			case 'libraries.tabs.playlists': return 'Afspeellijsten';
			case 'libraries.groupings.all': return 'Alles';
			case 'libraries.groupings.movies': return 'Films';
			case 'libraries.groupings.shows': return 'Series';
			case 'libraries.groupings.seasons': return 'Seizoenen';
			case 'libraries.groupings.episodes': return 'Afleveringen';
			case 'libraries.groupings.folders': return 'Mappen';
			case 'about.title': return 'Over';
			case 'about.openSourceLicenses': return 'Open Source licenties';
			case 'about.versionLabel': return ({required Object version}) => 'Versie ${version}';
			case 'about.appDescription': return 'Een mooie Plex client voor Flutter';
			case 'about.viewLicensesDescription': return 'Bekijk licenties van third-party bibliotheken';
			case 'serverSelection.allServerConnectionsFailed': return 'Kon niet verbinden met servers. Controleer je netwerk en probeer opnieuw.';
			case 'serverSelection.noServersFound': return 'Geen servers gevonden';
			case 'serverSelection.noServersFoundForAccount': return ({required Object username, required Object email}) => 'Geen servers gevonden voor ${username} (${email})';
			case 'serverSelection.failedToLoadServers': return ({required Object error}) => 'Kon servers niet laden: ${error}';
			case 'hubDetail.title': return 'Titel';
			case 'hubDetail.releaseYear': return 'Uitgavejaar';
			case 'hubDetail.dateAdded': return 'Datum toegevoegd';
			case 'hubDetail.rating': return 'Beoordeling';
			case 'hubDetail.noItemsFound': return 'Geen items gevonden';
			case 'logs.clearLogs': return 'Wis logs';
			case 'logs.copyLogs': return 'Kopieer logs';
			case 'logs.error': return 'Fout:';
			case 'logs.stackTrace': return 'Stacktracering:';
			case 'licenses.relatedPackages': return 'Gerelateerde pakketten';
			case 'licenses.license': return 'Licentie';
			case 'licenses.licenseNumber': return ({required Object number}) => 'Licentie ${number}';
			case 'licenses.licensesCount': return ({required Object count}) => '${count} licenties';
			case 'navigation.home': return 'Thuis';
			case 'navigation.search': return 'Zoeken';
			case 'navigation.libraries': return 'Bibliotheken';
			case 'navigation.settings': return 'Instellingen';
			case 'navigation.downloads': return 'Downloads';
			case 'downloads.title': return 'Downloads';
			case 'downloads.manage': return 'Beheren';
			case 'downloads.tvShows': return 'Series';
			case 'downloads.movies': return 'Films';
			case 'downloads.noDownloads': return 'Nog geen downloads';
			case 'downloads.noDownloadsDescription': return 'Gedownloade content verschijnt hier voor offline weergave';
			case 'downloads.downloadNow': return 'Download';
			case 'downloads.deleteDownload': return 'Download verwijderen';
			case 'downloads.retryDownload': return 'Download opnieuw proberen';
			case 'downloads.downloadQueued': return 'Download in wachtrij';
			case 'downloads.episodesQueued': return ({required Object count}) => '${count} afleveringen in wachtrij voor download';
			case 'downloads.downloadDeleted': return 'Download verwijderd';
			case 'downloads.deleteConfirm': return ({required Object title}) => 'Weet je zeker dat je "${title}" wilt verwijderen? Het gedownloade bestand wordt van je apparaat verwijderd.';
			case 'downloads.deletingWithProgress': return ({required Object title, required Object current, required Object total}) => 'Verwijderen van ${title}... (${current} van ${total})';
			case 'playlists.title': return 'Afspeellijsten';
			case 'playlists.noPlaylists': return 'Geen afspeellijsten gevonden';
			case 'playlists.create': return 'Afspeellijst maken';
			case 'playlists.playlistName': return 'Naam afspeellijst';
			case 'playlists.enterPlaylistName': return 'Voer naam afspeellijst in';
			case 'playlists.delete': return 'Afspeellijst verwijderen';
			case 'playlists.removeItem': return 'Verwijderen uit afspeellijst';
			case 'playlists.smartPlaylist': return 'Slimme afspeellijst';
			case 'playlists.itemCount': return ({required Object count}) => '${count} items';
			case 'playlists.oneItem': return '1 item';
			case 'playlists.emptyPlaylist': return 'Deze afspeellijst is leeg';
			case 'playlists.deleteConfirm': return 'Afspeellijst verwijderen?';
			case 'playlists.deleteMessage': return ({required Object name}) => 'Weet je zeker dat je "${name}" wilt verwijderen?';
			case 'playlists.created': return 'Afspeellijst gemaakt';
			case 'playlists.deleted': return 'Afspeellijst verwijderd';
			case 'playlists.itemAdded': return 'Toegevoegd aan afspeellijst';
			case 'playlists.itemRemoved': return 'Verwijderd uit afspeellijst';
			case 'playlists.selectPlaylist': return 'Selecteer afspeellijst';
			case 'playlists.createNewPlaylist': return 'Nieuwe afspeellijst maken';
			case 'playlists.errorCreating': return 'Fout bij maken afspeellijst';
			case 'playlists.errorDeleting': return 'Fout bij verwijderen afspeellijst';
			case 'playlists.errorLoading': return 'Fout bij laden afspeellijsten';
			case 'playlists.errorAdding': return 'Fout bij toevoegen aan afspeellijst';
			case 'playlists.errorReordering': return 'Fout bij herschikken van afspeellijstitem';
			case 'playlists.errorRemoving': return 'Fout bij verwijderen uit afspeellijst';
			case 'playlists.playlist': return 'Afspeellijst';
			case 'collections.title': return 'Collecties';
			case 'collections.collection': return 'Collectie';
			case 'collections.empty': return 'Collectie is leeg';
			case 'collections.unknownLibrarySection': return 'Kan niet verwijderen: onbekende bibliotheeksectie';
			case 'collections.deleteCollection': return 'Collectie verwijderen';
			case 'collections.deleteConfirm': return ({required Object title}) => 'Weet je zeker dat je "${title}" wilt verwijderen? Deze actie kan niet ongedaan worden gemaakt.';
			case 'collections.deleted': return 'Collectie verwijderd';
			case 'collections.deleteFailed': return 'Collectie verwijderen mislukt';
			case 'collections.deleteFailedWithError': return ({required Object error}) => 'Collectie verwijderen mislukt: ${error}';
			case 'collections.failedToLoadItems': return ({required Object error}) => 'Collectie-items laden mislukt: ${error}';
			case 'collections.selectCollection': return 'Selecteer collectie';
			case 'collections.createNewCollection': return 'Nieuwe collectie maken';
			case 'collections.collectionName': return 'Collectienaam';
			case 'collections.enterCollectionName': return 'Voer collectienaam in';
			case 'collections.addedToCollection': return 'Toegevoegd aan collectie';
			case 'collections.errorAddingToCollection': return 'Fout bij toevoegen aan collectie';
			case 'collections.created': return 'Collectie gemaakt';
			case 'collections.removeFromCollection': return 'Verwijderen uit collectie';
			case 'collections.removeFromCollectionConfirm': return ({required Object title}) => '"${title}" uit deze collectie verwijderen?';
			case 'collections.removedFromCollection': return 'Uit collectie verwijderd';
			case 'collections.removeFromCollectionFailed': return 'Verwijderen uit collectie mislukt';
			case 'collections.removeFromCollectionError': return ({required Object error}) => 'Fout bij verwijderen uit collectie: ${error}';
			case 'watchTogether.title': return 'Samen Kijken';
			case 'watchTogether.description': return 'Kijk synchroon met vrienden en familie';
			case 'watchTogether.createSession': return 'Sessie Maken';
			case 'watchTogether.creating': return 'Maken...';
			case 'watchTogether.joinSession': return 'Sessie Deelnemen';
			case 'watchTogether.joining': return 'Deelnemen...';
			case 'watchTogether.controlMode': return 'Controlemodus';
			case 'watchTogether.controlModeQuestion': return 'Wie kan het afspelen bedienen?';
			case 'watchTogether.hostOnly': return 'Alleen Host';
			case 'watchTogether.anyone': return 'Iedereen';
			case 'watchTogether.hostingSession': return 'Sessie Hosten';
			case 'watchTogether.inSession': return 'In Sessie';
			case 'watchTogether.sessionCode': return 'Sessiecode';
			case 'watchTogether.hostControlsPlayback': return 'Host bedient het afspelen';
			case 'watchTogether.anyoneCanControl': return 'Iedereen kan het afspelen bedienen';
			case 'watchTogether.hostControls': return 'Host bedient';
			case 'watchTogether.anyoneControls': return 'Iedereen bedient';
			case 'watchTogether.participants': return 'Deelnemers';
			case 'watchTogether.host': return 'Host';
			case 'watchTogether.hostBadge': return 'HOST';
			case 'watchTogether.youAreHost': return 'Jij bent de host';
			case 'watchTogether.watchingWithOthers': return 'Kijken met anderen';
			case 'watchTogether.endSession': return 'Sessie Beëindigen';
			case 'watchTogether.leaveSession': return 'Sessie Verlaten';
			case 'watchTogether.endSessionQuestion': return 'Sessie Beëindigen?';
			case 'watchTogether.leaveSessionQuestion': return 'Sessie Verlaten?';
			case 'watchTogether.endSessionConfirm': return 'Dit beëindigt de sessie voor alle deelnemers.';
			case 'watchTogether.leaveSessionConfirm': return 'Je wordt uit de sessie verwijderd.';
			case 'watchTogether.endSessionConfirmOverlay': return 'Dit beëindigt de kijksessie voor alle deelnemers.';
			case 'watchTogether.leaveSessionConfirmOverlay': return 'Je wordt losgekoppeld van de kijksessie.';
			case 'watchTogether.end': return 'Beëindigen';
			case 'watchTogether.leave': return 'Verlaten';
			case 'watchTogether.syncing': return 'Synchroniseren...';
			case 'watchTogether.participant': return 'deelnemer';
			case 'watchTogether.joinWatchSession': return 'Kijksessie Deelnemen';
			case 'watchTogether.enterCodeHint': return 'Voer 8-teken code in';
			case 'watchTogether.pasteFromClipboard': return 'Plakken van klembord';
			case 'watchTogether.pleaseEnterCode': return 'Voer een sessiecode in';
			case 'watchTogether.codeMustBe8Chars': return 'Sessiecode moet 8 tekens zijn';
			case 'watchTogether.joinInstructions': return 'Voer de sessiecode in die door de host is gedeeld om deel te nemen aan hun kijksessie.';
			case 'watchTogether.failedToCreate': return 'Sessie maken mislukt';
			case 'watchTogether.failedToJoin': return 'Sessie deelnemen mislukt';
			default: return null;
		}
	}
}

extension on _StringsSv {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'app.title': return 'Plezy';
			case 'app.loading': return 'Laddar...';
			case 'auth.signInWithPlex': return 'Logga in med Plex';
			case 'auth.showQRCode': return 'Visa QR-kod';
			case 'auth.cancel': return 'Avbryt';
			case 'auth.authenticate': return 'Autentisera';
			case 'auth.retry': return 'Försök igen';
			case 'auth.debugEnterToken': return 'Debug: Ange Plex-token';
			case 'auth.plexTokenLabel': return 'Plex-autentiseringstoken';
			case 'auth.plexTokenHint': return 'Ange din Plex.tv-token';
			case 'auth.authenticationTimeout': return 'Autentisering tog för lång tid. Försök igen.';
			case 'auth.scanQRCodeInstruction': return 'Skanna denna QR-kod med en enhet inloggad på Plex för att autentisera.';
			case 'auth.waitingForAuth': return 'Väntar på autentisering...\nVänligen slutför inloggning i din webbläsare.';
			case 'common.cancel': return 'Avbryt';
			case 'common.save': return 'Spara';
			case 'common.close': return 'Stäng';
			case 'common.clear': return 'Rensa';
			case 'common.reset': return 'Återställ';
			case 'common.later': return 'Senare';
			case 'common.submit': return 'Skicka';
			case 'common.confirm': return 'Bekräfta';
			case 'common.retry': return 'Försök igen';
			case 'common.logout': return 'Logga ut';
			case 'common.unknown': return 'Okänd';
			case 'common.refresh': return 'Uppdatera';
			case 'common.yes': return 'Ja';
			case 'common.no': return 'Nej';
			case 'common.delete': return 'Ta bort';
			case 'common.shuffle': return 'Blanda';
			case 'common.addTo': return 'Lägg till i...';
			case 'screens.licenses': return 'Licenser';
			case 'screens.selectServer': return 'Välj server';
			case 'screens.switchProfile': return 'Byt profil';
			case 'screens.subtitleStyling': return 'Undertext-styling';
			case 'screens.mpvConfig': return 'MPV-konfiguration';
			case 'screens.search': return 'Sök';
			case 'screens.logs': return 'Loggar';
			case 'update.available': return 'Uppdatering tillgänglig';
			case 'update.versionAvailable': return ({required Object version}) => 'Version ${version} är tillgänglig';
			case 'update.currentVersion': return ({required Object version}) => 'Nuvarande: ${version}';
			case 'update.skipVersion': return 'Hoppa över denna version';
			case 'update.viewRelease': return 'Visa release';
			case 'update.latestVersion': return 'Du har den senaste versionen';
			case 'update.checkFailed': return 'Misslyckades att kontrollera uppdateringar';
			case 'settings.title': return 'Inställningar';
			case 'settings.language': return 'Språk';
			case 'settings.theme': return 'Tema';
			case 'settings.appearance': return 'Utseende';
			case 'settings.videoPlayback': return 'Videouppspelning';
			case 'settings.advanced': return 'Avancerat';
			case 'settings.episodePosterMode': return 'Avsnittsaffisch-stil';
			case 'settings.seriesPoster': return 'Serieaffisch';
			case 'settings.seriesPosterDescription': return 'Visa seriens affisch för alla avsnitt';
			case 'settings.seasonPoster': return 'Säsongsaffisch';
			case 'settings.seasonPosterDescription': return 'Visa säsongens affisch för avsnitt';
			case 'settings.episodeThumbnail': return 'Avsnittsminiatyr';
			case 'settings.episodeThumbnailDescription': return 'Visa 16:9 skärmbild från avsnittet';
			case 'settings.showHeroSectionDescription': return 'Visa utvalda innehållskarusell på startsidan';
			case 'settings.secondsLabel': return 'Sekunder';
			case 'settings.minutesLabel': return 'Minuter';
			case 'settings.secondsShort': return 's';
			case 'settings.minutesShort': return 'm';
			case 'settings.durationHint': return ({required Object min, required Object max}) => 'Ange tid (${min}-${max})';
			case 'settings.systemTheme': return 'System';
			case 'settings.systemThemeDescription': return 'Följ systeminställningar';
			case 'settings.lightTheme': return 'Ljust';
			case 'settings.darkTheme': return 'Mörkt';
			case 'settings.libraryDensity': return 'Biblioteksdensitet';
			case 'settings.compact': return 'Kompakt';
			case 'settings.compactDescription': return 'Mindre kort, fler objekt synliga';
			case 'settings.normal': return 'Normal';
			case 'settings.normalDescription': return 'Standardstorlek';
			case 'settings.comfortable': return 'Bekväm';
			case 'settings.comfortableDescription': return 'Större kort, färre objekt synliga';
			case 'settings.viewMode': return 'Visningsläge';
			case 'settings.gridView': return 'Rutnät';
			case 'settings.gridViewDescription': return 'Visa objekt i rutnätslayout';
			case 'settings.listView': return 'Lista';
			case 'settings.listViewDescription': return 'Visa objekt i listlayout';
			case 'settings.showHeroSection': return 'Visa hjältesektion';
			case 'settings.useGlobalHubs': return 'Använd Plex hem-layout';
			case 'settings.useGlobalHubsDescription': return 'Visar startsidans hubbar som den officiella Plex-klienten. När av visas rekommendationer per bibliotek istället.';
			case 'settings.hardwareDecoding': return 'Hårdvaruavkodning';
			case 'settings.hardwareDecodingDescription': return 'Använd hårdvaruacceleration när tillgängligt';
			case 'settings.bufferSize': return 'Bufferstorlek';
			case 'settings.bufferSizeMB': return ({required Object size}) => '${size}MB';
			case 'settings.subtitleStyling': return 'Undertext-styling';
			case 'settings.subtitleStylingDescription': return 'Anpassa undertextutseende';
			case 'settings.smallSkipDuration': return 'Kort hoppvaraktighet';
			case 'settings.largeSkipDuration': return 'Lång hoppvaraktighet';
			case 'settings.secondsUnit': return ({required Object seconds}) => '${seconds} sekunder';
			case 'settings.defaultSleepTimer': return 'Standard sovtimer';
			case 'settings.minutesUnit': return ({required Object minutes}) => '${minutes} minuter';
			case 'settings.rememberTrackSelections': return 'Kom ihåg spårval per serie/film';
			case 'settings.rememberTrackSelectionsDescription': return 'Spara automatiskt ljud- och undertextspråkpreferenser när du ändrar spår under uppspelning';
			case 'settings.videoPlayerControls': return 'Videospelar-kontroller';
			case 'settings.keyboardShortcuts': return 'Tangentbordsgenvägar';
			case 'settings.keyboardShortcutsDescription': return 'Anpassa tangentbordsgenvägar';
			case 'settings.videoPlayerNavigation': return 'Navigering i videospelaren';
			case 'settings.videoPlayerNavigationDescription': return 'Använd piltangenter för att navigera videospelarens kontroller';
			case 'settings.debugLogging': return 'Felsökningsloggning';
			case 'settings.debugLoggingDescription': return 'Aktivera detaljerad loggning för felsökning';
			case 'settings.viewLogs': return 'Visa loggar';
			case 'settings.viewLogsDescription': return 'Visa applikationsloggar';
			case 'settings.clearCache': return 'Rensa cache';
			case 'settings.clearCacheDescription': return 'Detta rensar alla cachade bilder och data. Appen kan ta längre tid att ladda innehåll efter cache-rensning.';
			case 'settings.clearCacheSuccess': return 'Cache rensad framgångsrikt';
			case 'settings.resetSettings': return 'Återställ inställningar';
			case 'settings.resetSettingsDescription': return 'Detta återställer alla inställningar till standardvärden. Denna åtgärd kan inte ångras.';
			case 'settings.resetSettingsSuccess': return 'Inställningar återställda framgångsrikt';
			case 'settings.shortcutsReset': return 'Genvägar återställda till standard';
			case 'settings.about': return 'Om';
			case 'settings.aboutDescription': return 'Appinformation och licenser';
			case 'settings.updates': return 'Uppdateringar';
			case 'settings.updateAvailable': return 'Uppdatering tillgänglig';
			case 'settings.checkForUpdates': return 'Kontrollera uppdateringar';
			case 'settings.validationErrorEnterNumber': return 'Vänligen ange ett giltigt nummer';
			case 'settings.validationErrorDuration': return ({required Object min, required Object max, required Object unit}) => 'Tiden måste vara mellan ${min} och ${max} ${unit}';
			case 'settings.shortcutAlreadyAssigned': return ({required Object action}) => 'Genväg redan tilldelad ${action}';
			case 'settings.shortcutUpdated': return ({required Object action}) => 'Genväg uppdaterad för ${action}';
			case 'settings.autoSkip': return 'Auto Hoppa Över';
			case 'settings.autoSkipIntro': return 'Hoppa Över Intro Automatiskt';
			case 'settings.autoSkipIntroDescription': return 'Hoppa automatiskt över intro-markörer efter några sekunder';
			case 'settings.autoSkipCredits': return 'Hoppa Över Credits Automatiskt';
			case 'settings.autoSkipCreditsDescription': return 'Hoppa automatiskt över credits och spela nästa avsnitt';
			case 'settings.autoSkipDelay': return 'Fördröjning Auto Hoppa Över';
			case 'settings.autoSkipDelayDescription': return ({required Object seconds}) => 'Vänta ${seconds} sekunder innan automatisk överhoppning';
			case 'settings.downloads': return 'Nedladdningar';
			case 'settings.downloadLocationDescription': return 'Välj var nedladdat innehåll ska lagras';
			case 'settings.downloadLocationDefault': return 'Standard (App-lagring)';
			case 'settings.downloadLocationCustom': return 'Anpassad Plats';
			case 'settings.selectFolder': return 'Välj Mapp';
			case 'settings.resetToDefault': return 'Återställ till Standard';
			case 'settings.currentPath': return ({required Object path}) => 'Nuvarande: ${path}';
			case 'settings.downloadLocationChanged': return 'Nedladdningsplats ändrad';
			case 'settings.downloadLocationReset': return 'Nedladdningsplats återställd till standard';
			case 'settings.downloadLocationInvalid': return 'Vald mapp är inte skrivbar';
			case 'settings.downloadLocationSelectError': return 'Kunde inte välja mapp';
			case 'settings.downloadOnWifiOnly': return 'Ladda ner endast på WiFi';
			case 'settings.downloadOnWifiOnlyDescription': return 'Förhindra nedladdningar vid användning av mobildata';
			case 'settings.cellularDownloadBlocked': return 'Nedladdningar är inaktiverade på mobildata. Anslut till WiFi eller ändra inställningen.';
			case 'settings.maxVolume': return 'Maximal volym';
			case 'settings.maxVolumeDescription': return 'Tillåt volym över 100% för tyst media';
			case 'settings.maxVolumePercent': return ({required Object percent}) => '${percent}%';
			case 'settings.maxVolumeHint': return 'Ange maximal volym (100-300)';
			case 'settings.discordRichPresence': return 'Discord Rich Presence';
			case 'settings.discordRichPresenceDescription': return 'Visa vad du tittar på i Discord';
			case 'search.hint': return 'Sök filmer, serier, musik...';
			case 'search.tryDifferentTerm': return 'Prova en annan sökterm';
			case 'search.searchYourMedia': return 'Sök i dina media';
			case 'search.enterTitleActorOrKeyword': return 'Ange en titel, skådespelare eller nyckelord';
			case 'hotkeys.setShortcutFor': return ({required Object actionName}) => 'Sätt genväg för ${actionName}';
			case 'hotkeys.clearShortcut': return 'Rensa genväg';
			case 'pinEntry.enterPin': return 'Ange PIN';
			case 'pinEntry.showPin': return 'Visa PIN';
			case 'pinEntry.hidePin': return 'Dölj PIN';
			case 'fileInfo.title': return 'Filinformation';
			case 'fileInfo.video': return 'Video';
			case 'fileInfo.audio': return 'Ljud';
			case 'fileInfo.file': return 'Fil';
			case 'fileInfo.advanced': return 'Avancerat';
			case 'fileInfo.codec': return 'Kodek';
			case 'fileInfo.resolution': return 'Upplösning';
			case 'fileInfo.bitrate': return 'Bithastighet';
			case 'fileInfo.frameRate': return 'Bildfrekvens';
			case 'fileInfo.aspectRatio': return 'Bildförhållande';
			case 'fileInfo.profile': return 'Profil';
			case 'fileInfo.bitDepth': return 'Bitdjup';
			case 'fileInfo.colorSpace': return 'Färgrymd';
			case 'fileInfo.colorRange': return 'Färgområde';
			case 'fileInfo.colorPrimaries': return 'Färggrunder';
			case 'fileInfo.chromaSubsampling': return 'Kroma-undersampling';
			case 'fileInfo.channels': return 'Kanaler';
			case 'fileInfo.path': return 'Sökväg';
			case 'fileInfo.size': return 'Storlek';
			case 'fileInfo.container': return 'Container';
			case 'fileInfo.duration': return 'Varaktighet';
			case 'fileInfo.optimizedForStreaming': return 'Optimerad för streaming';
			case 'fileInfo.has64bitOffsets': return '64-bit offset';
			case 'mediaMenu.markAsWatched': return 'Markera som sedd';
			case 'mediaMenu.markAsUnwatched': return 'Markera som osedd';
			case 'mediaMenu.removeFromContinueWatching': return 'Ta bort från Fortsätt titta';
			case 'mediaMenu.goToSeries': return 'Gå till serie';
			case 'mediaMenu.goToSeason': return 'Gå till säsong';
			case 'mediaMenu.shufflePlay': return 'Blanda uppspelning';
			case 'mediaMenu.fileInfo': return 'Filinformation';
			case 'accessibility.mediaCardMovie': return ({required Object title}) => '${title}, film';
			case 'accessibility.mediaCardShow': return ({required Object title}) => '${title}, TV-serie';
			case 'accessibility.mediaCardEpisode': return ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
			case 'accessibility.mediaCardSeason': return ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
			case 'accessibility.mediaCardWatched': return 'sedd';
			case 'accessibility.mediaCardPartiallyWatched': return ({required Object percent}) => '${percent} procent sedd';
			case 'accessibility.mediaCardUnwatched': return 'osedd';
			case 'accessibility.tapToPlay': return 'Tryck för att spela';
			case 'tooltips.shufflePlay': return 'Blanda uppspelning';
			case 'tooltips.markAsWatched': return 'Markera som sedd';
			case 'tooltips.markAsUnwatched': return 'Markera som osedd';
			case 'videoControls.audioLabel': return 'Ljud';
			case 'videoControls.subtitlesLabel': return 'Undertexter';
			case 'videoControls.resetToZero': return 'Återställ till 0ms';
			case 'videoControls.addTime': return ({required Object amount, required Object unit}) => '+${amount}${unit}';
			case 'videoControls.minusTime': return ({required Object amount, required Object unit}) => '-${amount}${unit}';
			case 'videoControls.playsLater': return ({required Object label}) => '${label} spelas senare';
			case 'videoControls.playsEarlier': return ({required Object label}) => '${label} spelas tidigare';
			case 'videoControls.noOffset': return 'Ingen offset';
			case 'videoControls.letterbox': return 'Letterbox';
			case 'videoControls.fillScreen': return 'Fyll skärm';
			case 'videoControls.stretch': return 'Sträck';
			case 'videoControls.lockRotation': return 'Lås rotation';
			case 'videoControls.unlockRotation': return 'Lås upp rotation';
			case 'videoControls.sleepTimer': return 'Sovtimer';
			case 'videoControls.timerActive': return 'Timer aktiv';
			case 'videoControls.playbackWillPauseIn': return ({required Object duration}) => 'Uppspelningen pausas om ${duration}';
			case 'videoControls.sleepTimerCompleted': return 'Sovtimer slutförd - uppspelning pausad';
			case 'videoControls.playButton': return 'Spela';
			case 'videoControls.pauseButton': return 'Pausa';
			case 'videoControls.seekBackwardButton': return ({required Object seconds}) => 'Spola bakåt ${seconds} sekunder';
			case 'videoControls.seekForwardButton': return ({required Object seconds}) => 'Spola framåt ${seconds} sekunder';
			case 'videoControls.previousButton': return 'Föregående avsnitt';
			case 'videoControls.nextButton': return 'Nästa avsnitt';
			case 'videoControls.previousChapterButton': return 'Föregående kapitel';
			case 'videoControls.nextChapterButton': return 'Nästa kapitel';
			case 'videoControls.muteButton': return 'Tysta';
			case 'videoControls.unmuteButton': return 'Slå på ljud';
			case 'videoControls.settingsButton': return 'Videoinställningar';
			case 'videoControls.audioTrackButton': return 'Ljudspår';
			case 'videoControls.subtitlesButton': return 'Undertexter';
			case 'videoControls.chaptersButton': return 'Kapitel';
			case 'videoControls.versionsButton': return 'Videoversioner';
			case 'videoControls.pipButton': return 'Bild-i-bild läge';
			case 'videoControls.aspectRatioButton': return 'Bildförhållande';
			case 'videoControls.fullscreenButton': return 'Aktivera helskärm';
			case 'videoControls.exitFullscreenButton': return 'Avsluta helskärm';
			case 'videoControls.alwaysOnTopButton': return 'Alltid överst';
			case 'videoControls.rotationLockButton': return 'Rotationslås';
			case 'videoControls.timelineSlider': return 'Videotidslinje';
			case 'videoControls.volumeSlider': return 'Volymnivå';
			case 'videoControls.backButton': return 'Tillbaka';
			case 'userStatus.admin': return 'Admin';
			case 'userStatus.restricted': return 'Begränsad';
			case 'userStatus.protected': return 'Skyddad';
			case 'userStatus.current': return 'NUVARANDE';
			case 'messages.markedAsWatched': return 'Markerad som sedd';
			case 'messages.markedAsUnwatched': return 'Markerad som osedd';
			case 'messages.markedAsWatchedOffline': return 'Markerad som sedd (synkroniseras när online)';
			case 'messages.markedAsUnwatchedOffline': return 'Markerad som osedd (synkroniseras när online)';
			case 'messages.removedFromContinueWatching': return 'Borttagen från Fortsätt titta';
			case 'messages.errorLoading': return ({required Object error}) => 'Fel: ${error}';
			case 'messages.fileInfoNotAvailable': return 'Filinformation inte tillgänglig';
			case 'messages.errorLoadingFileInfo': return ({required Object error}) => 'Fel vid laddning av filinformation: ${error}';
			case 'messages.errorLoadingSeries': return 'Fel vid laddning av serie';
			case 'messages.errorLoadingSeason': return 'Fel vid laddning av säsong';
			case 'messages.musicNotSupported': return 'Musikuppspelning stöds inte ännu';
			case 'messages.logsCleared': return 'Loggar rensade';
			case 'messages.logsCopied': return 'Loggar kopierade till urklipp';
			case 'messages.noLogsAvailable': return 'Inga loggar tillgängliga';
			case 'messages.libraryScanning': return ({required Object title}) => 'Skannar "${title}"...';
			case 'messages.libraryScanStarted': return ({required Object title}) => 'Biblioteksskanning startad för "${title}"';
			case 'messages.libraryScanFailed': return ({required Object error}) => 'Misslyckades att skanna bibliotek: ${error}';
			case 'messages.metadataRefreshing': return ({required Object title}) => 'Uppdaterar metadata för "${title}"...';
			case 'messages.metadataRefreshStarted': return ({required Object title}) => 'Metadata-uppdatering startad för "${title}"';
			case 'messages.metadataRefreshFailed': return ({required Object error}) => 'Misslyckades att uppdatera metadata: ${error}';
			case 'messages.logoutConfirm': return 'Är du säker på att du vill logga ut?';
			case 'messages.noSeasonsFound': return 'Inga säsonger hittades';
			case 'messages.noEpisodesFound': return 'Inga avsnitt hittades i första säsongen';
			case 'messages.noEpisodesFoundGeneral': return 'Inga avsnitt hittades';
			case 'messages.noResultsFound': return 'Inga resultat hittades';
			case 'messages.sleepTimerSet': return ({required Object label}) => 'Sovtimer inställd för ${label}';
			case 'messages.noItemsAvailable': return 'Inga objekt tillgängliga';
			case 'messages.failedToCreatePlayQueue': return 'Det gick inte att skapa uppspelningskö';
			case 'messages.failedToCreatePlayQueueNoItems': return 'Det gick inte att skapa uppspelningskö – inga objekt';
			case 'messages.failedPlayback': return ({required Object action, required Object error}) => 'Kunde inte ${action}: ${error}';
			case 'subtitlingStyling.stylingOptions': return 'Stilalternativ';
			case 'subtitlingStyling.fontSize': return 'Teckenstorlek';
			case 'subtitlingStyling.textColor': return 'Textfärg';
			case 'subtitlingStyling.borderSize': return 'Kantstorlek';
			case 'subtitlingStyling.borderColor': return 'Kantfärg';
			case 'subtitlingStyling.backgroundOpacity': return 'Bakgrundsopacitet';
			case 'subtitlingStyling.backgroundColor': return 'Bakgrundsfärg';
			case 'mpvConfig.title': return 'MPV-konfiguration';
			case 'mpvConfig.description': return 'Avancerade videospelares inställningar';
			case 'mpvConfig.properties': return 'Egenskaper';
			case 'mpvConfig.presets': return 'Förval';
			case 'mpvConfig.noProperties': return 'Inga egenskaper konfigurerade';
			case 'mpvConfig.noPresets': return 'Inga sparade förval';
			case 'mpvConfig.addProperty': return 'Lägg till egenskap';
			case 'mpvConfig.editProperty': return 'Redigera egenskap';
			case 'mpvConfig.deleteProperty': return 'Ta bort egenskap';
			case 'mpvConfig.propertyKey': return 'Egenskapsnyckel';
			case 'mpvConfig.propertyKeyHint': return 't.ex. hwdec, demuxer-max-bytes';
			case 'mpvConfig.propertyValue': return 'Egenskapsvärde';
			case 'mpvConfig.propertyValueHint': return 't.ex. auto, 256000000';
			case 'mpvConfig.saveAsPreset': return 'Spara som förval...';
			case 'mpvConfig.presetName': return 'Förvalnamn';
			case 'mpvConfig.presetNameHint': return 'Ange ett namn för detta förval';
			case 'mpvConfig.loadPreset': return 'Ladda';
			case 'mpvConfig.deletePreset': return 'Ta bort';
			case 'mpvConfig.presetSaved': return 'Förval sparat';
			case 'mpvConfig.presetLoaded': return 'Förval laddat';
			case 'mpvConfig.presetDeleted': return 'Förval borttaget';
			case 'mpvConfig.confirmDeletePreset': return 'Är du säker på att du vill ta bort detta förval?';
			case 'mpvConfig.confirmDeleteProperty': return 'Är du säker på att du vill ta bort denna egenskap?';
			case 'mpvConfig.entriesCount': return ({required Object count}) => '${count} poster';
			case 'dialog.confirmAction': return 'Bekräfta åtgärd';
			case 'dialog.cancel': return 'Avbryt';
			case 'dialog.playNow': return 'Spela nu';
			case 'discover.title': return 'Upptäck';
			case 'discover.switchProfile': return 'Byt profil';
			case 'discover.switchServer': return 'Byt server';
			case 'discover.logout': return 'Logga ut';
			case 'discover.noContentAvailable': return 'Inget innehåll tillgängligt';
			case 'discover.addMediaToLibraries': return 'Lägg till media till dina bibliotek';
			case 'discover.continueWatching': return 'Fortsätt titta';
			case 'discover.play': return 'Spela';
			case 'discover.playEpisode': return ({required Object season, required Object episode}) => 'S${season}E${episode}';
			case 'discover.pause': return 'Pausa';
			case 'discover.overview': return 'Översikt';
			case 'discover.cast': return 'Rollbesättning';
			case 'discover.seasons': return 'Säsonger';
			case 'discover.studio': return 'Studio';
			case 'discover.rating': return 'Åldersgräns';
			case 'discover.watched': return 'Tittad';
			case 'discover.episodeCount': return ({required Object count}) => '${count} avsnitt';
			case 'discover.watchedProgress': return ({required Object watched, required Object total}) => '${watched}/${total} sedda';
			case 'discover.movie': return 'Film';
			case 'discover.tvShow': return 'TV-serie';
			case 'discover.minutesLeft': return ({required Object minutes}) => '${minutes} min kvar';
			case 'errors.searchFailed': return ({required Object error}) => 'Sökning misslyckades: ${error}';
			case 'errors.connectionTimeout': return ({required Object context}) => 'Anslutnings-timeout vid laddning ${context}';
			case 'errors.connectionFailed': return 'Kan inte ansluta till Plex-server';
			case 'errors.failedToLoad': return ({required Object context, required Object error}) => 'Misslyckades att ladda ${context}: ${error}';
			case 'errors.noClientAvailable': return 'Ingen klient tillgänglig';
			case 'errors.authenticationFailed': return ({required Object error}) => 'Autentisering misslyckades: ${error}';
			case 'errors.couldNotLaunchUrl': return 'Kunde inte öppna autentiserings-URL';
			case 'errors.pleaseEnterToken': return 'Vänligen ange en token';
			case 'errors.invalidToken': return 'Ogiltig token';
			case 'errors.failedToVerifyToken': return ({required Object error}) => 'Misslyckades att verifiera token: ${error}';
			case 'errors.failedToSwitchProfile': return ({required Object displayName}) => 'Misslyckades att byta till ${displayName}';
			case 'libraries.title': return 'Bibliotek';
			case 'libraries.scanLibraryFiles': return 'Skanna biblioteksfiler';
			case 'libraries.scanLibrary': return 'Skanna bibliotek';
			case 'libraries.analyze': return 'Analysera';
			case 'libraries.analyzeLibrary': return 'Analysera bibliotek';
			case 'libraries.refreshMetadata': return 'Uppdatera metadata';
			case 'libraries.emptyTrash': return 'Töm papperskorg';
			case 'libraries.emptyingTrash': return ({required Object title}) => 'Tömmer papperskorg för "${title}"...';
			case 'libraries.trashEmptied': return ({required Object title}) => 'Papperskorg tömd för "${title}"';
			case 'libraries.failedToEmptyTrash': return ({required Object error}) => 'Misslyckades att tömma papperskorg: ${error}';
			case 'libraries.analyzing': return ({required Object title}) => 'Analyserar "${title}"...';
			case 'libraries.analysisStarted': return ({required Object title}) => 'Analys startad för "${title}"';
			case 'libraries.failedToAnalyze': return ({required Object error}) => 'Misslyckades att analysera bibliotek: ${error}';
			case 'libraries.noLibrariesFound': return 'Inga bibliotek hittades';
			case 'libraries.thisLibraryIsEmpty': return 'Detta bibliotek är tomt';
			case 'libraries.all': return 'Alla';
			case 'libraries.clearAll': return 'Rensa alla';
			case 'libraries.scanLibraryConfirm': return ({required Object title}) => 'Är du säker på att du vill skanna "${title}"?';
			case 'libraries.analyzeLibraryConfirm': return ({required Object title}) => 'Är du säker på att du vill analysera "${title}"?';
			case 'libraries.refreshMetadataConfirm': return ({required Object title}) => 'Är du säker på att du vill uppdatera metadata för "${title}"?';
			case 'libraries.emptyTrashConfirm': return ({required Object title}) => 'Är du säker på att du vill tömma papperskorgen för "${title}"?';
			case 'libraries.manageLibraries': return 'Hantera bibliotek';
			case 'libraries.sort': return 'Sortera';
			case 'libraries.sortBy': return 'Sortera efter';
			case 'libraries.filters': return 'Filter';
			case 'libraries.confirmActionMessage': return 'Är du säker på att du vill utföra denna åtgärd?';
			case 'libraries.showLibrary': return 'Visa bibliotek';
			case 'libraries.hideLibrary': return 'Dölj bibliotek';
			case 'libraries.libraryOptions': return 'Biblioteksalternativ';
			case 'libraries.content': return 'bibliotekets innehåll';
			case 'libraries.selectLibrary': return 'Välj bibliotek';
			case 'libraries.filtersWithCount': return ({required Object count}) => 'Filter (${count})';
			case 'libraries.noRecommendations': return 'Inga rekommendationer tillgängliga';
			case 'libraries.noCollections': return 'Inga samlingar i det här biblioteket';
			case 'libraries.noFoldersFound': return 'Inga mappar hittades';
			case 'libraries.folders': return 'mappar';
			case 'libraries.tabs.recommended': return 'Rekommenderat';
			case 'libraries.tabs.browse': return 'Bläddra';
			case 'libraries.tabs.collections': return 'Samlingar';
			case 'libraries.tabs.playlists': return 'Spellistor';
			case 'libraries.groupings.all': return 'Alla';
			case 'libraries.groupings.movies': return 'Filmer';
			case 'libraries.groupings.shows': return 'Serier';
			case 'libraries.groupings.seasons': return 'Säsonger';
			case 'libraries.groupings.episodes': return 'Avsnitt';
			case 'libraries.groupings.folders': return 'Mappar';
			case 'about.title': return 'Om';
			case 'about.openSourceLicenses': return 'Öppen källkod-licenser';
			case 'about.versionLabel': return ({required Object version}) => 'Version ${version}';
			case 'about.appDescription': return 'En vacker Plex-klient för Flutter';
			case 'about.viewLicensesDescription': return 'Visa licenser för tredjepartsbibliotek';
			case 'serverSelection.allServerConnectionsFailed': return 'Misslyckades att ansluta till servrar. Kontrollera ditt nätverk och försök igen.';
			case 'serverSelection.noServersFound': return 'Inga servrar hittades';
			case 'serverSelection.noServersFoundForAccount': return ({required Object username, required Object email}) => 'Inga servrar hittades för ${username} (${email})';
			case 'serverSelection.failedToLoadServers': return ({required Object error}) => 'Misslyckades att ladda servrar: ${error}';
			case 'hubDetail.title': return 'Titel';
			case 'hubDetail.releaseYear': return 'Utgivningsår';
			case 'hubDetail.dateAdded': return 'Datum tillagd';
			case 'hubDetail.rating': return 'Betyg';
			case 'hubDetail.noItemsFound': return 'Inga objekt hittades';
			case 'logs.clearLogs': return 'Rensa loggar';
			case 'logs.copyLogs': return 'Kopiera loggar';
			case 'logs.error': return 'Fel:';
			case 'logs.stackTrace': return 'Stack trace:';
			case 'licenses.relatedPackages': return 'Relaterade paket';
			case 'licenses.license': return 'Licens';
			case 'licenses.licenseNumber': return ({required Object number}) => 'Licens ${number}';
			case 'licenses.licensesCount': return ({required Object count}) => '${count} licenser';
			case 'navigation.home': return 'Hem';
			case 'navigation.search': return 'Sök';
			case 'navigation.libraries': return 'Bibliotek';
			case 'navigation.settings': return 'Inställningar';
			case 'navigation.downloads': return 'Nedladdningar';
			case 'downloads.title': return 'Nedladdningar';
			case 'downloads.manage': return 'Hantera';
			case 'downloads.tvShows': return 'TV-serier';
			case 'downloads.movies': return 'Filmer';
			case 'downloads.noDownloads': return 'Inga nedladdningar ännu';
			case 'downloads.noDownloadsDescription': return 'Nedladdat innehåll visas här för offline-visning';
			case 'downloads.downloadNow': return 'Ladda ner';
			case 'downloads.deleteDownload': return 'Ta bort nedladdning';
			case 'downloads.retryDownload': return 'Försök igen';
			case 'downloads.downloadQueued': return 'Nedladdning köad';
			case 'downloads.episodesQueued': return ({required Object count}) => '${count} avsnitt köade för nedladdning';
			case 'downloads.downloadDeleted': return 'Nedladdning borttagen';
			case 'downloads.deleteConfirm': return ({required Object title}) => 'Är du säker på att du vill ta bort "${title}"? Den nedladdade filen kommer att tas bort från din enhet.';
			case 'downloads.deletingWithProgress': return ({required Object title, required Object current, required Object total}) => 'Tar bort ${title}... (${current} av ${total})';
			case 'playlists.title': return 'Spellistor';
			case 'playlists.noPlaylists': return 'Inga spellistor hittades';
			case 'playlists.create': return 'Skapa spellista';
			case 'playlists.playlistName': return 'Spellistans namn';
			case 'playlists.enterPlaylistName': return 'Ange spellistans namn';
			case 'playlists.delete': return 'Ta bort spellista';
			case 'playlists.removeItem': return 'Ta bort från spellista';
			case 'playlists.smartPlaylist': return 'Smart spellista';
			case 'playlists.itemCount': return ({required Object count}) => '${count} objekt';
			case 'playlists.oneItem': return '1 objekt';
			case 'playlists.emptyPlaylist': return 'Denna spellista är tom';
			case 'playlists.deleteConfirm': return 'Ta bort spellista?';
			case 'playlists.deleteMessage': return ({required Object name}) => 'Är du säker på att du vill ta bort "${name}"?';
			case 'playlists.created': return 'Spellista skapad';
			case 'playlists.deleted': return 'Spellista borttagen';
			case 'playlists.itemAdded': return 'Tillagd i spellista';
			case 'playlists.itemRemoved': return 'Borttagen från spellista';
			case 'playlists.selectPlaylist': return 'Välj spellista';
			case 'playlists.createNewPlaylist': return 'Skapa ny spellista';
			case 'playlists.errorCreating': return 'Det gick inte att skapa spellista';
			case 'playlists.errorDeleting': return 'Det gick inte att ta bort spellista';
			case 'playlists.errorLoading': return 'Det gick inte att ladda spellistor';
			case 'playlists.errorAdding': return 'Det gick inte att lägga till i spellista';
			case 'playlists.errorReordering': return 'Det gick inte att omordna spellisteobjekt';
			case 'playlists.errorRemoving': return 'Det gick inte att ta bort från spellista';
			case 'playlists.playlist': return 'Spellista';
			case 'collections.title': return 'Samlingar';
			case 'collections.collection': return 'Samling';
			case 'collections.empty': return 'Samlingen är tom';
			case 'collections.unknownLibrarySection': return 'Kan inte ta bort: okänd bibliotekssektion';
			case 'collections.deleteCollection': return 'Ta bort samling';
			case 'collections.deleteConfirm': return ({required Object title}) => 'Är du säker på att du vill ta bort "${title}"? Detta går inte att ångra.';
			case 'collections.deleted': return 'Samling borttagen';
			case 'collections.deleteFailed': return 'Det gick inte att ta bort samlingen';
			case 'collections.deleteFailedWithError': return ({required Object error}) => 'Det gick inte att ta bort samlingen: ${error}';
			case 'collections.failedToLoadItems': return ({required Object error}) => 'Det gick inte att läsa in samlingsobjekt: ${error}';
			case 'collections.selectCollection': return 'Välj samling';
			case 'collections.createNewCollection': return 'Skapa ny samling';
			case 'collections.collectionName': return 'Samlingsnamn';
			case 'collections.enterCollectionName': return 'Ange samlingsnamn';
			case 'collections.addedToCollection': return 'Tillagd i samling';
			case 'collections.errorAddingToCollection': return 'Fel vid tillägg i samling';
			case 'collections.created': return 'Samling skapad';
			case 'collections.removeFromCollection': return 'Ta bort från samling';
			case 'collections.removeFromCollectionConfirm': return ({required Object title}) => 'Ta bort "${title}" från denna samling?';
			case 'collections.removedFromCollection': return 'Borttagen från samling';
			case 'collections.removeFromCollectionFailed': return 'Misslyckades med att ta bort från samling';
			case 'collections.removeFromCollectionError': return ({required Object error}) => 'Fel vid borttagning från samling: ${error}';
			case 'watchTogether.title': return 'Titta Tillsammans';
			case 'watchTogether.description': return 'Titta på innehåll synkroniserat med vänner och familj';
			case 'watchTogether.createSession': return 'Skapa Session';
			case 'watchTogether.creating': return 'Skapar...';
			case 'watchTogether.joinSession': return 'Gå med i Session';
			case 'watchTogether.joining': return 'Ansluter...';
			case 'watchTogether.controlMode': return 'Kontrollläge';
			case 'watchTogether.controlModeQuestion': return 'Vem kan styra uppspelningen?';
			case 'watchTogether.hostOnly': return 'Endast Värd';
			case 'watchTogether.anyone': return 'Alla';
			case 'watchTogether.hostingSession': return 'Värd för Session';
			case 'watchTogether.inSession': return 'I Session';
			case 'watchTogether.sessionCode': return 'Sessionskod';
			case 'watchTogether.hostControlsPlayback': return 'Värden styr uppspelningen';
			case 'watchTogether.anyoneCanControl': return 'Alla kan styra uppspelningen';
			case 'watchTogether.hostControls': return 'Värd styr';
			case 'watchTogether.anyoneControls': return 'Alla styr';
			case 'watchTogether.participants': return 'Deltagare';
			case 'watchTogether.host': return 'Värd';
			case 'watchTogether.hostBadge': return 'VÄRD';
			case 'watchTogether.youAreHost': return 'Du är värden';
			case 'watchTogether.watchingWithOthers': return 'Tittar med andra';
			case 'watchTogether.endSession': return 'Avsluta Session';
			case 'watchTogether.leaveSession': return 'Lämna Session';
			case 'watchTogether.endSessionQuestion': return 'Avsluta Session?';
			case 'watchTogether.leaveSessionQuestion': return 'Lämna Session?';
			case 'watchTogether.endSessionConfirm': return 'Detta avslutar sessionen för alla deltagare.';
			case 'watchTogether.leaveSessionConfirm': return 'Du kommer att tas bort från sessionen.';
			case 'watchTogether.endSessionConfirmOverlay': return 'Detta avslutar tittarsessionen för alla deltagare.';
			case 'watchTogether.leaveSessionConfirmOverlay': return 'Du kommer att kopplas bort från tittarsessionen.';
			case 'watchTogether.end': return 'Avsluta';
			case 'watchTogether.leave': return 'Lämna';
			case 'watchTogether.syncing': return 'Synkroniserar...';
			case 'watchTogether.participant': return 'deltagare';
			case 'watchTogether.joinWatchSession': return 'Gå med i Tittarsession';
			case 'watchTogether.enterCodeHint': return 'Ange 8-teckens kod';
			case 'watchTogether.pasteFromClipboard': return 'Klistra in från urklipp';
			case 'watchTogether.pleaseEnterCode': return 'Vänligen ange en sessionskod';
			case 'watchTogether.codeMustBe8Chars': return 'Sessionskod måste vara 8 tecken';
			case 'watchTogether.joinInstructions': return 'Ange sessionskoden som delats av värden för att gå med i deras tittarsession.';
			case 'watchTogether.failedToCreate': return 'Det gick inte att skapa session';
			case 'watchTogether.failedToJoin': return 'Det gick inte att gå med i session';
			default: return null;
		}
	}
}

extension on _StringsZh {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'app.title': return 'Plezy';
			case 'app.loading': return '加载中...';
			case 'auth.signInWithPlex': return '使用 Plex 登录';
			case 'auth.showQRCode': return '显示二维码';
			case 'auth.cancel': return '取消';
			case 'auth.authenticate': return '验证';
			case 'auth.retry': return '重试';
			case 'auth.debugEnterToken': return '调试：输入 Plex Token';
			case 'auth.plexTokenLabel': return 'Plex 授权令牌 (Auth Token)';
			case 'auth.plexTokenHint': return '输入你的 Plex.tv 令牌';
			case 'auth.authenticationTimeout': return '验证超时。请重试。';
			case 'auth.scanQRCodeInstruction': return '请使用已登录 Plex 的设备扫描此二维码进行验证。';
			case 'auth.waitingForAuth': return '等待验证中...\n请在你的浏览器中完成登录。';
			case 'common.cancel': return '取消';
			case 'common.save': return '保存';
			case 'common.close': return '关闭';
			case 'common.clear': return '清除';
			case 'common.reset': return '重置';
			case 'common.later': return '稍后';
			case 'common.submit': return '提交';
			case 'common.confirm': return '确认';
			case 'common.retry': return '重试';
			case 'common.logout': return '登出';
			case 'common.unknown': return '未知';
			case 'common.refresh': return '刷新';
			case 'common.yes': return '是';
			case 'common.no': return '否';
			case 'common.delete': return '删除';
			case 'common.shuffle': return '随机播放';
			case 'common.addTo': return '添加到...';
			case 'screens.licenses': return '许可证';
			case 'screens.selectServer': return '选择服务器';
			case 'screens.switchProfile': return '切换用户';
			case 'screens.subtitleStyling': return '字幕样式';
			case 'screens.mpvConfig': return 'MPV 配置';
			case 'screens.search': return '搜索';
			case 'screens.logs': return '日志';
			case 'update.available': return '有可用更新';
			case 'update.versionAvailable': return ({required Object version}) => '版本 ${version} 已发布';
			case 'update.currentVersion': return ({required Object version}) => '当前版本: ${version}';
			case 'update.skipVersion': return '跳过此版本';
			case 'update.viewRelease': return '查看发布详情';
			case 'update.latestVersion': return '已安装的版本是可用的最新版本';
			case 'update.checkFailed': return '无法检查更新';
			case 'settings.title': return '设置';
			case 'settings.language': return '语言';
			case 'settings.theme': return '主题';
			case 'settings.appearance': return '外观';
			case 'settings.videoPlayback': return '视频播放';
			case 'settings.advanced': return '高级';
			case 'settings.episodePosterMode': return '剧集海报样式';
			case 'settings.seriesPoster': return '剧集海报';
			case 'settings.seriesPosterDescription': return '为所有剧集显示剧集海报';
			case 'settings.seasonPoster': return '季海报';
			case 'settings.seasonPosterDescription': return '为剧集显示特定季的海报';
			case 'settings.episodeThumbnail': return '剧集缩略图';
			case 'settings.episodeThumbnailDescription': return '显示16:9剧集截图缩略图';
			case 'settings.showHeroSectionDescription': return '在主屏幕上显示精选内容轮播区';
			case 'settings.secondsLabel': return '秒';
			case 'settings.minutesLabel': return '分钟';
			case 'settings.secondsShort': return 's';
			case 'settings.minutesShort': return 'm';
			case 'settings.durationHint': return ({required Object min, required Object max}) => '输入时长 (${min}-${max})';
			case 'settings.systemTheme': return '系统';
			case 'settings.systemThemeDescription': return '跟随系统设置';
			case 'settings.lightTheme': return '浅色';
			case 'settings.darkTheme': return '深色';
			case 'settings.libraryDensity': return '媒体库密度';
			case 'settings.compact': return '紧凑';
			case 'settings.compactDescription': return '卡片更小，显示更多项目';
			case 'settings.normal': return '标准';
			case 'settings.normalDescription': return '默认尺寸';
			case 'settings.comfortable': return '舒适';
			case 'settings.comfortableDescription': return '卡片更大，显示更少项目';
			case 'settings.viewMode': return '视图模式';
			case 'settings.gridView': return '网格视图';
			case 'settings.gridViewDescription': return '以网格布局显示项目';
			case 'settings.listView': return '列表视图';
			case 'settings.listViewDescription': return '以列表布局显示项目';
			case 'settings.showHeroSection': return '显示主要精选区';
			case 'settings.useGlobalHubs': return '使用 Plex 主页布局';
			case 'settings.useGlobalHubsDescription': return '显示与官方 Plex 客户端相同的主页推荐。关闭时将显示按媒体库分类的推荐。';
			case 'settings.hardwareDecoding': return '硬件解码';
			case 'settings.hardwareDecodingDescription': return '如果可用，使用硬件加速';
			case 'settings.bufferSize': return '缓冲区大小';
			case 'settings.bufferSizeMB': return ({required Object size}) => '${size}MB';
			case 'settings.subtitleStyling': return '字幕样式';
			case 'settings.subtitleStylingDescription': return '调整字幕外观';
			case 'settings.smallSkipDuration': return '短跳过时长';
			case 'settings.largeSkipDuration': return '长跳过时长';
			case 'settings.secondsUnit': return ({required Object seconds}) => '${seconds} 秒';
			case 'settings.defaultSleepTimer': return '默认睡眠定时器';
			case 'settings.minutesUnit': return ({required Object minutes}) => '${minutes} 分钟';
			case 'settings.rememberTrackSelections': return '记住每个剧集/电影的音轨选择';
			case 'settings.rememberTrackSelectionsDescription': return '在播放过程中更改音轨时自动保存音频和字幕语言偏好';
			case 'settings.videoPlayerControls': return '视频播放器控制';
			case 'settings.keyboardShortcuts': return '键盘快捷键';
			case 'settings.keyboardShortcutsDescription': return '自定义键盘快捷键';
			case 'settings.videoPlayerNavigation': return '视频播放器导航';
			case 'settings.videoPlayerNavigationDescription': return '使用方向键导航视频播放器控件';
			case 'settings.debugLogging': return '调试日志';
			case 'settings.debugLoggingDescription': return '启用详细日志记录以便故障排除';
			case 'settings.viewLogs': return '查看日志';
			case 'settings.viewLogsDescription': return '查看应用程序日志';
			case 'settings.clearCache': return '清除缓存';
			case 'settings.clearCacheDescription': return '这将清除所有缓存的图片和数据。清除缓存后，应用程序加载内容可能会变慢。';
			case 'settings.clearCacheSuccess': return '缓存清除成功';
			case 'settings.resetSettings': return '重置设置';
			case 'settings.resetSettingsDescription': return '这会将所有设置重置为其默认值。此操作无法撤销。';
			case 'settings.resetSettingsSuccess': return '设置重置成功';
			case 'settings.shortcutsReset': return '快捷键已重置为默认值';
			case 'settings.about': return '关于';
			case 'settings.aboutDescription': return '应用程序信息和许可证';
			case 'settings.updates': return '更新';
			case 'settings.updateAvailable': return '有可用更新';
			case 'settings.checkForUpdates': return '检查更新';
			case 'settings.validationErrorEnterNumber': return '请输入一个有效的数字';
			case 'settings.validationErrorDuration': return ({required Object min, required Object max, required Object unit}) => '时长必须介于 ${min} 和 ${max} ${unit} 之间';
			case 'settings.shortcutAlreadyAssigned': return ({required Object action}) => '快捷键已被分配给 ${action}';
			case 'settings.shortcutUpdated': return ({required Object action}) => '快捷键已为 ${action} 更新';
			case 'settings.autoSkip': return '自动跳过';
			case 'settings.autoSkipIntro': return '自动跳过片头';
			case 'settings.autoSkipIntroDescription': return '几秒钟后自动跳过片头标记';
			case 'settings.autoSkipCredits': return '自动跳过片尾';
			case 'settings.autoSkipCreditsDescription': return '自动跳过片尾并播放下一集';
			case 'settings.autoSkipDelay': return '自动跳过延迟';
			case 'settings.autoSkipDelayDescription': return ({required Object seconds}) => '自动跳过前等待 ${seconds} 秒';
			case 'settings.downloads': return '下载';
			case 'settings.downloadLocationDescription': return '选择下载内容的存储位置';
			case 'settings.downloadLocationDefault': return '默认（应用存储）';
			case 'settings.downloadLocationCustom': return '自定义位置';
			case 'settings.selectFolder': return '选择文件夹';
			case 'settings.resetToDefault': return '重置为默认';
			case 'settings.currentPath': return ({required Object path}) => '当前: ${path}';
			case 'settings.downloadLocationChanged': return '下载位置已更改';
			case 'settings.downloadLocationReset': return '下载位置已重置为默认';
			case 'settings.downloadLocationInvalid': return '所选文件夹不可写入';
			case 'settings.downloadLocationSelectError': return '选择文件夹失败';
			case 'settings.downloadOnWifiOnly': return '仅在 WiFi 时下载';
			case 'settings.downloadOnWifiOnlyDescription': return '使用蜂窝数据时禁止下载';
			case 'settings.cellularDownloadBlocked': return '蜂窝数据下已禁用下载。请连接 WiFi 或更改设置。';
			case 'settings.maxVolume': return '最大音量';
			case 'settings.maxVolumeDescription': return '允许音量超过 100% 以适应安静的媒体';
			case 'settings.maxVolumePercent': return ({required Object percent}) => '${percent}%';
			case 'settings.maxVolumeHint': return '输入最大音量 (100-300)';
			case 'settings.discordRichPresence': return 'Discord 动态状态';
			case 'settings.discordRichPresenceDescription': return '在 Discord 上显示您正在观看的内容';
			case 'search.hint': return '搜索电影、系列、音乐...';
			case 'search.tryDifferentTerm': return '尝试不同的搜索词';
			case 'search.searchYourMedia': return '搜索媒体';
			case 'search.enterTitleActorOrKeyword': return '输入标题、演员或关键词';
			case 'hotkeys.setShortcutFor': return ({required Object actionName}) => '为 ${actionName} 设置快捷键';
			case 'hotkeys.clearShortcut': return '清除快捷键';
			case 'pinEntry.enterPin': return '输入 PIN';
			case 'pinEntry.showPin': return '显示 PIN';
			case 'pinEntry.hidePin': return '隐藏 PIN';
			case 'fileInfo.title': return '文件信息';
			case 'fileInfo.video': return '视频';
			case 'fileInfo.audio': return '音频';
			case 'fileInfo.file': return '文件';
			case 'fileInfo.advanced': return '高级';
			case 'fileInfo.codec': return '编解码器';
			case 'fileInfo.resolution': return '分辨率';
			case 'fileInfo.bitrate': return '比特率';
			case 'fileInfo.frameRate': return '帧率';
			case 'fileInfo.aspectRatio': return '宽高比';
			case 'fileInfo.profile': return '配置文件';
			case 'fileInfo.bitDepth': return '位深度';
			case 'fileInfo.colorSpace': return '色彩空间';
			case 'fileInfo.colorRange': return '色彩范围';
			case 'fileInfo.colorPrimaries': return '颜色原色';
			case 'fileInfo.chromaSubsampling': return '色度子采样';
			case 'fileInfo.channels': return '声道';
			case 'fileInfo.path': return '路径';
			case 'fileInfo.size': return '大小';
			case 'fileInfo.container': return '容器';
			case 'fileInfo.duration': return '时长';
			case 'fileInfo.optimizedForStreaming': return '已优化用于流媒体';
			case 'fileInfo.has64bitOffsets': return '64位偏移量';
			case 'mediaMenu.markAsWatched': return '标记为已观看';
			case 'mediaMenu.markAsUnwatched': return '标记为未观看';
			case 'mediaMenu.removeFromContinueWatching': return '从继续观看中移除';
			case 'mediaMenu.goToSeries': return '转到系列';
			case 'mediaMenu.goToSeason': return '转到季';
			case 'mediaMenu.shufflePlay': return '随机播放';
			case 'mediaMenu.fileInfo': return '文件信息';
			case 'accessibility.mediaCardMovie': return ({required Object title}) => '${title}, 电影';
			case 'accessibility.mediaCardShow': return ({required Object title}) => '${title}, 电视剧';
			case 'accessibility.mediaCardEpisode': return ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
			case 'accessibility.mediaCardSeason': return ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
			case 'accessibility.mediaCardWatched': return '已观看';
			case 'accessibility.mediaCardPartiallyWatched': return ({required Object percent}) => '已观看 ${percent} 百分比';
			case 'accessibility.mediaCardUnwatched': return '未观看';
			case 'accessibility.tapToPlay': return '点击播放';
			case 'tooltips.shufflePlay': return '随机播放';
			case 'tooltips.markAsWatched': return '标记为已观看';
			case 'tooltips.markAsUnwatched': return '标记为未观看';
			case 'videoControls.audioLabel': return '音频';
			case 'videoControls.subtitlesLabel': return '字幕';
			case 'videoControls.resetToZero': return '重置为 0ms';
			case 'videoControls.addTime': return ({required Object amount, required Object unit}) => '+${amount}${unit}';
			case 'videoControls.minusTime': return ({required Object amount, required Object unit}) => '-${amount}${unit}';
			case 'videoControls.playsLater': return ({required Object label}) => '${label} 播放较晚';
			case 'videoControls.playsEarlier': return ({required Object label}) => '${label} 播放较早';
			case 'videoControls.noOffset': return '无偏移';
			case 'videoControls.letterbox': return '信箱模式（Letterbox）';
			case 'videoControls.fillScreen': return '填充屏幕';
			case 'videoControls.stretch': return '拉伸';
			case 'videoControls.lockRotation': return '锁定旋转';
			case 'videoControls.unlockRotation': return '解锁旋转';
			case 'videoControls.sleepTimer': return '睡眠定时器';
			case 'videoControls.timerActive': return '定时器已激活';
			case 'videoControls.playbackWillPauseIn': return ({required Object duration}) => '播放将在 ${duration} 后暂停';
			case 'videoControls.sleepTimerCompleted': return '睡眠定时器已完成 - 播放已暂停';
			case 'videoControls.playButton': return '播放';
			case 'videoControls.pauseButton': return '暂停';
			case 'videoControls.seekBackwardButton': return ({required Object seconds}) => '后退 ${seconds} 秒';
			case 'videoControls.seekForwardButton': return ({required Object seconds}) => '前进 ${seconds} 秒';
			case 'videoControls.previousButton': return '上一集';
			case 'videoControls.nextButton': return '下一集';
			case 'videoControls.previousChapterButton': return '上一章节';
			case 'videoControls.nextChapterButton': return '下一章节';
			case 'videoControls.muteButton': return '静音';
			case 'videoControls.unmuteButton': return '取消静音';
			case 'videoControls.settingsButton': return '视频设置';
			case 'videoControls.audioTrackButton': return '音轨';
			case 'videoControls.subtitlesButton': return '字幕';
			case 'videoControls.chaptersButton': return '章节';
			case 'videoControls.versionsButton': return '视频版本';
			case 'videoControls.pipButton': return '画中画模式';
			case 'videoControls.aspectRatioButton': return '宽高比';
			case 'videoControls.fullscreenButton': return '进入全屏';
			case 'videoControls.exitFullscreenButton': return '退出全屏';
			case 'videoControls.alwaysOnTopButton': return '置顶窗口';
			case 'videoControls.rotationLockButton': return '旋转锁定';
			case 'videoControls.timelineSlider': return '视频时间轴';
			case 'videoControls.volumeSlider': return '音量调节';
			case 'videoControls.backButton': return '返回';
			case 'userStatus.admin': return '管理员';
			case 'userStatus.restricted': return '受限';
			case 'userStatus.protected': return '受保护';
			case 'userStatus.current': return '当前';
			case 'messages.markedAsWatched': return '已标记为已观看';
			case 'messages.markedAsUnwatched': return '已标记为未观看';
			case 'messages.markedAsWatchedOffline': return '已标记为已观看 (将在联网时同步)';
			case 'messages.markedAsUnwatchedOffline': return '已标记为未观看 (将在联网时同步)';
			case 'messages.removedFromContinueWatching': return '已从继续观看中移除';
			case 'messages.errorLoading': return ({required Object error}) => '错误: ${error}';
			case 'messages.fileInfoNotAvailable': return '文件信息不可用';
			case 'messages.errorLoadingFileInfo': return ({required Object error}) => '加载文件信息时出错: ${error}';
			case 'messages.errorLoadingSeries': return '加载系列时出错';
			case 'messages.errorLoadingSeason': return '加载季时出错';
			case 'messages.musicNotSupported': return '尚不支持播放音乐';
			case 'messages.logsCleared': return '日志已清除';
			case 'messages.logsCopied': return '日志已复制到剪贴板';
			case 'messages.noLogsAvailable': return '没有可用日志';
			case 'messages.libraryScanning': return ({required Object title}) => '正在扫描 “${title}”...';
			case 'messages.libraryScanStarted': return ({required Object title}) => '已开始扫描 “${title}” 媒体库';
			case 'messages.libraryScanFailed': return ({required Object error}) => '无法扫描媒体库: ${error}';
			case 'messages.metadataRefreshing': return ({required Object title}) => '正在刷新 “${title}” 的元数据...';
			case 'messages.metadataRefreshStarted': return ({required Object title}) => '已开始刷新 “${title}” 的元数据';
			case 'messages.metadataRefreshFailed': return ({required Object error}) => '无法刷新元数据: ${error}';
			case 'messages.logoutConfirm': return '你确定要登出吗？';
			case 'messages.noSeasonsFound': return '未找到季';
			case 'messages.noEpisodesFound': return '在第一季中未找到剧集';
			case 'messages.noEpisodesFoundGeneral': return '未找到剧集';
			case 'messages.noResultsFound': return '未找到结果';
			case 'messages.sleepTimerSet': return ({required Object label}) => '睡眠定时器已设置为 ${label}';
			case 'messages.noItemsAvailable': return '没有可用的项目';
			case 'messages.failedToCreatePlayQueue': return '创建播放队列失败';
			case 'messages.failedToCreatePlayQueueNoItems': return '创建播放队列失败 - 没有项目';
			case 'messages.failedPlayback': return ({required Object action, required Object error}) => '无法${action}: ${error}';
			case 'subtitlingStyling.stylingOptions': return '样式选项';
			case 'subtitlingStyling.fontSize': return '字号';
			case 'subtitlingStyling.textColor': return '文本颜色';
			case 'subtitlingStyling.borderSize': return '边框大小';
			case 'subtitlingStyling.borderColor': return '边框颜色';
			case 'subtitlingStyling.backgroundOpacity': return '背景不透明度';
			case 'subtitlingStyling.backgroundColor': return '背景颜色';
			case 'mpvConfig.title': return 'MPV 配置';
			case 'mpvConfig.description': return '高级视频播放器设置';
			case 'mpvConfig.properties': return '属性';
			case 'mpvConfig.presets': return '预设';
			case 'mpvConfig.noProperties': return '未配置任何属性';
			case 'mpvConfig.noPresets': return '没有保存的预设';
			case 'mpvConfig.addProperty': return '添加属性';
			case 'mpvConfig.editProperty': return '编辑属性';
			case 'mpvConfig.deleteProperty': return '删除属性';
			case 'mpvConfig.propertyKey': return '属性键';
			case 'mpvConfig.propertyKeyHint': return '例如 hwdec, demuxer-max-bytes';
			case 'mpvConfig.propertyValue': return '属性值';
			case 'mpvConfig.propertyValueHint': return '例如 auto, 256000000';
			case 'mpvConfig.saveAsPreset': return '保存为预设...';
			case 'mpvConfig.presetName': return '预设名称';
			case 'mpvConfig.presetNameHint': return '输入此预设的名称';
			case 'mpvConfig.loadPreset': return '加载';
			case 'mpvConfig.deletePreset': return '删除';
			case 'mpvConfig.presetSaved': return '预设已保存';
			case 'mpvConfig.presetLoaded': return '预设已加载';
			case 'mpvConfig.presetDeleted': return '预设已删除';
			case 'mpvConfig.confirmDeletePreset': return '确定要删除此预设吗？';
			case 'mpvConfig.confirmDeleteProperty': return '确定要删除此属性吗？';
			case 'mpvConfig.entriesCount': return ({required Object count}) => '${count} 条目';
			case 'dialog.confirmAction': return '确认操作';
			case 'dialog.cancel': return '取消';
			case 'dialog.playNow': return '立即播放';
			case 'discover.title': return '发现';
			case 'discover.switchProfile': return '切换用户';
			case 'discover.switchServer': return '切换服务器';
			case 'discover.logout': return '登出';
			case 'discover.noContentAvailable': return '没有可用内容';
			case 'discover.addMediaToLibraries': return '请向你的媒体库添加一些媒体';
			case 'discover.continueWatching': return '继续观看';
			case 'discover.play': return '播放';
			case 'discover.playEpisode': return ({required Object season, required Object episode}) => 'S${season}E${episode}';
			case 'discover.pause': return '暂停';
			case 'discover.overview': return '概述';
			case 'discover.cast': return '演员表';
			case 'discover.seasons': return '季数';
			case 'discover.studio': return '制作公司';
			case 'discover.rating': return '年龄分级';
			case 'discover.watched': return '已观看';
			case 'discover.episodeCount': return ({required Object count}) => '${count} 集';
			case 'discover.watchedProgress': return ({required Object watched, required Object total}) => '已观看 ${watched}/${total} 集';
			case 'discover.movie': return '电影';
			case 'discover.tvShow': return '电视剧';
			case 'discover.minutesLeft': return ({required Object minutes}) => '剩余 ${minutes} 分钟';
			case 'errors.searchFailed': return ({required Object error}) => '搜索失败: ${error}';
			case 'errors.connectionTimeout': return ({required Object context}) => '加载 ${context} 时连接超时';
			case 'errors.connectionFailed': return '无法连接到 Plex 服务器';
			case 'errors.failedToLoad': return ({required Object context, required Object error}) => '无法加载 ${context}: ${error}';
			case 'errors.noClientAvailable': return '没有可用客户端';
			case 'errors.authenticationFailed': return ({required Object error}) => '验证失败: ${error}';
			case 'errors.couldNotLaunchUrl': return '无法打开授权 URL';
			case 'errors.pleaseEnterToken': return '请输入一个令牌';
			case 'errors.invalidToken': return '令牌无效';
			case 'errors.failedToVerifyToken': return ({required Object error}) => '无法验证令牌: ${error}';
			case 'errors.failedToSwitchProfile': return ({required Object displayName}) => '无法切换到 ${displayName}';
			case 'libraries.title': return '媒体库';
			case 'libraries.scanLibraryFiles': return '扫描媒体库文件';
			case 'libraries.scanLibrary': return '扫描媒体库';
			case 'libraries.analyze': return '分析';
			case 'libraries.analyzeLibrary': return '分析媒体库';
			case 'libraries.refreshMetadata': return '刷新元数据';
			case 'libraries.emptyTrash': return '清空回收站';
			case 'libraries.emptyingTrash': return ({required Object title}) => '正在清空 “${title}” 的回收站...';
			case 'libraries.trashEmptied': return ({required Object title}) => '已清空 “${title}” 的回收站';
			case 'libraries.failedToEmptyTrash': return ({required Object error}) => '无法清空回收站: ${error}';
			case 'libraries.analyzing': return ({required Object title}) => '正在分析 “${title}”...';
			case 'libraries.analysisStarted': return ({required Object title}) => '已开始分析 “${title}”';
			case 'libraries.failedToAnalyze': return ({required Object error}) => '无法分析媒体库: ${error}';
			case 'libraries.noLibrariesFound': return '未找到媒体库';
			case 'libraries.thisLibraryIsEmpty': return '此媒体库为空';
			case 'libraries.all': return '全部';
			case 'libraries.clearAll': return '全部清除';
			case 'libraries.scanLibraryConfirm': return ({required Object title}) => '确定要扫描 “${title}” 吗？';
			case 'libraries.analyzeLibraryConfirm': return ({required Object title}) => '确定要分析 “${title}” 吗？';
			case 'libraries.refreshMetadataConfirm': return ({required Object title}) => '确定要刷新 “${title}” 的元数据吗？';
			case 'libraries.emptyTrashConfirm': return ({required Object title}) => '确定要清空 “${title}” 的回收站吗？';
			case 'libraries.manageLibraries': return '管理媒体库';
			case 'libraries.sort': return '排序';
			case 'libraries.sortBy': return '排序依据';
			case 'libraries.filters': return '筛选器';
			case 'libraries.confirmActionMessage': return '确定要执行此操作吗？';
			case 'libraries.showLibrary': return '显示媒体库';
			case 'libraries.hideLibrary': return '隐藏媒体库';
			case 'libraries.libraryOptions': return '媒体库选项';
			case 'libraries.content': return '媒体库内容';
			case 'libraries.selectLibrary': return '选择媒体库';
			case 'libraries.filtersWithCount': return ({required Object count}) => '筛选器（${count}）';
			case 'libraries.noRecommendations': return '暂无推荐';
			case 'libraries.noCollections': return '此媒体库中没有合集';
			case 'libraries.noFoldersFound': return '未找到文件夹';
			case 'libraries.folders': return '文件夹';
			case 'libraries.tabs.recommended': return '推荐';
			case 'libraries.tabs.browse': return '浏览';
			case 'libraries.tabs.collections': return '合集';
			case 'libraries.tabs.playlists': return '播放列表';
			case 'libraries.groupings.all': return '全部';
			case 'libraries.groupings.movies': return '电影';
			case 'libraries.groupings.shows': return '剧集';
			case 'libraries.groupings.seasons': return '季';
			case 'libraries.groupings.episodes': return '集';
			case 'libraries.groupings.folders': return '文件夹';
			case 'about.title': return '关于';
			case 'about.openSourceLicenses': return '开源许可证';
			case 'about.versionLabel': return ({required Object version}) => '版本 ${version}';
			case 'about.appDescription': return '一款精美的 Flutter Plex 客户端';
			case 'about.viewLicensesDescription': return '查看第三方库的许可证';
			case 'serverSelection.allServerConnectionsFailed': return '无法连接到任何服务器。请检查你的网络并重试。';
			case 'serverSelection.noServersFound': return '未找到服务器';
			case 'serverSelection.noServersFoundForAccount': return ({required Object username, required Object email}) => '未找到 ${username} (${email}) 的服务器';
			case 'serverSelection.failedToLoadServers': return ({required Object error}) => '无法加载服务器: ${error}';
			case 'hubDetail.title': return '标题';
			case 'hubDetail.releaseYear': return '发行年份';
			case 'hubDetail.dateAdded': return '添加日期';
			case 'hubDetail.rating': return '评分';
			case 'hubDetail.noItemsFound': return '未找到项目';
			case 'logs.clearLogs': return '清除日志';
			case 'logs.copyLogs': return '复制日志';
			case 'logs.error': return '错误:';
			case 'logs.stackTrace': return '堆栈跟踪 (Stack Trace):';
			case 'licenses.relatedPackages': return '相关软件包';
			case 'licenses.license': return '许可证';
			case 'licenses.licenseNumber': return ({required Object number}) => '许可证 ${number}';
			case 'licenses.licensesCount': return ({required Object count}) => '${count} 个许可证';
			case 'navigation.home': return '主页';
			case 'navigation.search': return '搜索';
			case 'navigation.libraries': return '媒体库';
			case 'navigation.settings': return '设置';
			case 'navigation.downloads': return '下载';
			case 'downloads.title': return '下载';
			case 'downloads.manage': return '管理';
			case 'downloads.tvShows': return '电视剧';
			case 'downloads.movies': return '电影';
			case 'downloads.noDownloads': return '暂无下载';
			case 'downloads.noDownloadsDescription': return '下载的内容将在此处显示以供离线观看';
			case 'downloads.downloadNow': return '下载';
			case 'downloads.deleteDownload': return '删除下载';
			case 'downloads.retryDownload': return '重试下载';
			case 'downloads.downloadQueued': return '下载已排队';
			case 'downloads.episodesQueued': return ({required Object count}) => '${count} 集已加入下载队列';
			case 'downloads.downloadDeleted': return '下载已删除';
			case 'downloads.deleteConfirm': return ({required Object title}) => '确定要删除 "${title}" 吗？下载的文件将从您的设备中删除。';
			case 'downloads.deletingWithProgress': return ({required Object title, required Object current, required Object total}) => '正在删除 ${title}... (${current}/${total})';
			case 'playlists.title': return '播放列表';
			case 'playlists.noPlaylists': return '未找到播放列表';
			case 'playlists.create': return '创建播放列表';
			case 'playlists.playlistName': return '播放列表名称';
			case 'playlists.enterPlaylistName': return '输入播放列表名称';
			case 'playlists.delete': return '删除播放列表';
			case 'playlists.removeItem': return '从播放列表中移除';
			case 'playlists.smartPlaylist': return '智能播放列表';
			case 'playlists.itemCount': return ({required Object count}) => '${count} 个项目';
			case 'playlists.oneItem': return '1 个项目';
			case 'playlists.emptyPlaylist': return '此播放列表为空';
			case 'playlists.deleteConfirm': return '删除播放列表？';
			case 'playlists.deleteMessage': return ({required Object name}) => '确定要删除 "${name}" 吗？';
			case 'playlists.created': return '播放列表已创建';
			case 'playlists.deleted': return '播放列表已删除';
			case 'playlists.itemAdded': return '已添加到播放列表';
			case 'playlists.itemRemoved': return '已从播放列表中移除';
			case 'playlists.selectPlaylist': return '选择播放列表';
			case 'playlists.createNewPlaylist': return '创建新播放列表';
			case 'playlists.errorCreating': return '创建播放列表失败';
			case 'playlists.errorDeleting': return '删除播放列表失败';
			case 'playlists.errorLoading': return '加载播放列表失败';
			case 'playlists.errorAdding': return '添加到播放列表失败';
			case 'playlists.errorReordering': return '重新排序播放列表项目失败';
			case 'playlists.errorRemoving': return '从播放列表中移除失败';
			case 'playlists.playlist': return '播放列表';
			case 'collections.title': return '合集';
			case 'collections.collection': return '合集';
			case 'collections.empty': return '合集为空';
			case 'collections.unknownLibrarySection': return '无法删除：未知的媒体库分区';
			case 'collections.deleteCollection': return '删除合集';
			case 'collections.deleteConfirm': return ({required Object title}) => '确定要删除"${title}"吗？此操作无法撤销。';
			case 'collections.deleted': return '已删除合集';
			case 'collections.deleteFailed': return '删除合集失败';
			case 'collections.deleteFailedWithError': return ({required Object error}) => '删除合集失败：${error}';
			case 'collections.failedToLoadItems': return ({required Object error}) => '加载合集项目失败：${error}';
			case 'collections.selectCollection': return '选择合集';
			case 'collections.createNewCollection': return '创建新合集';
			case 'collections.collectionName': return '合集名称';
			case 'collections.enterCollectionName': return '输入合集名称';
			case 'collections.addedToCollection': return '已添加到合集';
			case 'collections.errorAddingToCollection': return '添加到合集失败';
			case 'collections.created': return '已创建合集';
			case 'collections.removeFromCollection': return '从合集移除';
			case 'collections.removeFromCollectionConfirm': return ({required Object title}) => '将“${title}”从此合集移除？';
			case 'collections.removedFromCollection': return '已从合集移除';
			case 'collections.removeFromCollectionFailed': return '从合集移除失败';
			case 'collections.removeFromCollectionError': return ({required Object error}) => '从合集移除时出错：${error}';
			case 'watchTogether.title': return '一起看';
			case 'watchTogether.description': return '与朋友和家人同步观看内容';
			case 'watchTogether.createSession': return '创建会话';
			case 'watchTogether.creating': return '创建中...';
			case 'watchTogether.joinSession': return '加入会话';
			case 'watchTogether.joining': return '加入中...';
			case 'watchTogether.controlMode': return '控制模式';
			case 'watchTogether.controlModeQuestion': return '谁可以控制播放？';
			case 'watchTogether.hostOnly': return '仅主持人';
			case 'watchTogether.anyone': return '任何人';
			case 'watchTogether.hostingSession': return '主持会话';
			case 'watchTogether.inSession': return '在会话中';
			case 'watchTogether.sessionCode': return '会话代码';
			case 'watchTogether.hostControlsPlayback': return '主持人控制播放';
			case 'watchTogether.anyoneCanControl': return '任何人都可以控制播放';
			case 'watchTogether.hostControls': return '主持人控制';
			case 'watchTogether.anyoneControls': return '任何人控制';
			case 'watchTogether.participants': return '参与者';
			case 'watchTogether.host': return '主持人';
			case 'watchTogether.hostBadge': return '主持人';
			case 'watchTogether.youAreHost': return '你是主持人';
			case 'watchTogether.watchingWithOthers': return '与他人一起观看';
			case 'watchTogether.endSession': return '结束会话';
			case 'watchTogether.leaveSession': return '离开会话';
			case 'watchTogether.endSessionQuestion': return '结束会话？';
			case 'watchTogether.leaveSessionQuestion': return '离开会话？';
			case 'watchTogether.endSessionConfirm': return '这将为所有参与者结束会话。';
			case 'watchTogether.leaveSessionConfirm': return '你将被移出会话。';
			case 'watchTogether.endSessionConfirmOverlay': return '这将为所有参与者结束观看会话。';
			case 'watchTogether.leaveSessionConfirmOverlay': return '你将断开与观看会话的连接。';
			case 'watchTogether.end': return '结束';
			case 'watchTogether.leave': return '离开';
			case 'watchTogether.syncing': return '同步中...';
			case 'watchTogether.participant': return '参与者';
			case 'watchTogether.joinWatchSession': return '加入观看会话';
			case 'watchTogether.enterCodeHint': return '输入8位代码';
			case 'watchTogether.pasteFromClipboard': return '从剪贴板粘贴';
			case 'watchTogether.pleaseEnterCode': return '请输入会话代码';
			case 'watchTogether.codeMustBe8Chars': return '会话代码必须是8个字符';
			case 'watchTogether.joinInstructions': return '输入主持人分享的会话代码以加入他们的观看会话。';
			case 'watchTogether.failedToCreate': return '创建会话失败';
			case 'watchTogether.failedToJoin': return '加入会话失败';
			default: return null;
		}
	}
}
