/// Generated file. Do not edit.
///
/// Original: lib/i18n
/// To regenerate, run: `dart run slang`
///
/// Locales: 6
/// Strings: 2100 (350 per locale)
///
/// Built on 2025-11-15 at 02:45 UTC

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
	late final _StringsTooltipsEn tooltips = _StringsTooltipsEn._(_root);
	late final _StringsVideoControlsEn videoControls = _StringsVideoControlsEn._(_root);
	late final _StringsUserStatusEn userStatus = _StringsUserStatusEn._(_root);
	late final _StringsMessagesEn messages = _StringsMessagesEn._(_root);
	late final _StringsProfileEn profile = _StringsProfileEn._(_root);
	late final _StringsSubtitlingStylingEn subtitlingStyling = _StringsSubtitlingStylingEn._(_root);
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
	late final _StringsPlaylistsEn playlists = _StringsPlaylistsEn._(_root);
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
	String get playNow => 'Play Now';
	String get logout => 'Logout';
	String get online => 'Online';
	String get offline => 'Offline';
	String get owned => 'Owned';
	String get shared => 'Shared';
	String get current => 'CURRENT';
	String get unknown => 'Unknown';
	String get refresh => 'Refresh';
	String get yes => 'Yes';
	String get no => 'No';
	String get server => 'Server';
}

// Path: screens
class _StringsScreensEn {
	_StringsScreensEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get licenses => 'Licenses';
	String get selectServer => 'Select Server';
	String get switchProfile => 'Switch Profile';
	String get subtitleStyling => 'Subtitle Styling';
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
	String get shufflePlay => 'Shuffle Play';
	String get advanced => 'Advanced';
	String get useSeasonPostersDescription => 'Show season poster instead of series poster for episodes';
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
	String get useSeasonPosters => 'Use Season Posters';
	String get showHeroSection => 'Show Hero Section';
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
	String get unwatchedOnly => 'Unwatched Only';
	String get unwatchedOnlyDescription => 'Only include unwatched episodes in shuffle queue';
	String get shuffleOrderNavigation => 'Shuffle Order Navigation';
	String get shuffleOrderNavigationDescription => 'Next/previous buttons follow shuffled order';
	String get loopShuffleQueue => 'Loop Shuffle Queue';
	String get loopShuffleQueueDescription => 'Restart queue when reaching the end';
	String get videoPlayerControls => 'Video Player Controls';
	String get keyboardShortcuts => 'Keyboard Shortcuts';
	String get keyboardShortcutsDescription => 'Customize keyboard shortcuts';
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
}

// Path: userStatus
class _StringsUserStatusEn {
	_StringsUserStatusEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get admin => 'Admin';
	String get restricted => 'Restricted';
	String get protected => 'Protected';
}

// Path: messages
class _StringsMessagesEn {
	_StringsMessagesEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get markedAsWatched => 'Marked as watched';
	String get markedAsUnwatched => 'Marked as unwatched';
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
	String get noPlexToken => 'No Plex token found. Please login again.';
	String get logoutConfirm => 'Are you sure you want to logout?';
	String get noSeasonsFound => 'No seasons found';
	String get noEpisodesFound => 'No episodes found in first season';
	String get noEpisodesFoundGeneral => 'No episodes found';
	String get noResultsFound => 'No results found';
	String sleepTimerSet({required Object label}) => 'Sleep timer set for ${label}';
	String failedToSwitchProfile({required Object displayName}) => 'Failed to switch to ${displayName}';
}

// Path: profile
class _StringsProfileEn {
	_StringsProfileEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get noUsersAvailable => 'No users available';
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

// Path: dialog
class _StringsDialogEn {
	_StringsDialogEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get confirmAction => 'Confirm Action';
	String get areYouSure => 'Are you sure you want to perform this action?';
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
	String get switchServer => 'Switch Server';
	String get logout => 'Logout';
	String get noContentAvailable => 'No content available';
	String get addMediaToLibraries => 'Add some media to your libraries';
	String get continueWatching => 'Continue Watching';
	String get recentlyAdded => 'Recently Added';
	String get play => 'Play';
	String get resume => 'Resume';
	String playEpisode({required Object season, required Object episode}) => 'Play S${season}, E${episode}';
	String resumeEpisode({required Object season, required Object episode}) => 'Resume S${season}, E${episode}';
	String get pause => 'Pause';
	String get overview => 'Overview';
	String get cast => 'Cast';
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
	String get connectionFailedGeneric => 'Connection failed';
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
	String loadingLibraryWithCount({required Object count}) => 'Loading library... (${count} items loaded)';
	String get confirmActionMessage => 'Are you sure you want to perform this action?';
	String get showLibrary => 'Show library';
	String get hideLibrary => 'Hide library';
	String get libraryOptions => 'Library options';
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
	String get connectingToServer => 'Connecting to server...';
	String get serverDebugCopied => 'Server debug data copied to clipboard';
	String get copyDebugData => 'Copy Debug Data';
	String get noServersFound => 'No servers found';
	String malformedServerData({required Object count}) => 'Found ${count} server(s) with malformed data. No valid servers available.';
	String get incompleteServerInfo => 'Some servers have incomplete information and were skipped. Please check your Plex.tv account.';
	String get incompleteConnectionInfo => 'Server connection information is incomplete. Please try again.';
	String malformedServerInfo({required Object message}) => 'Server information is malformed: ${message}';
	String get networkConnectionFailed => 'Network connection failed. Please check your internet connection and try again.';
	String get authenticationFailed => 'Authentication failed. Please sign in again.';
	String get plexServiceUnavailable => 'Plex service unavailable. Please try again later.';
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
	String get title => 'Logs';
	String get clearLogs => 'Clear Logs';
	String get copyLogs => 'Copy Logs';
	String get exportLogs => 'Export Logs';
	String get noLogsToShow => 'No logs to show';
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
}

// Path: playlists
class _StringsPlaylistsEn {
	_StringsPlaylistsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Playlists';
	String get noPlaylists => 'No playlists found';
	String get create => 'Create Playlist';
	String get newPlaylist => 'New Playlist';
	String get playlistName => 'Playlist Name';
	String get enterPlaylistName => 'Enter playlist name';
	String get edit => 'Edit Playlist';
	String get delete => 'Delete Playlist';
	String get addTo => 'Add to Playlist';
	String get addItems => 'Add Items';
	String get removeItem => 'Remove from Playlist';
	String get clearPlaylist => 'Clear Playlist';
	String get playAll => 'Play All';
	String get shuffle => 'Shuffle';
	String get smartPlaylist => 'Smart Playlist';
	String get regularPlaylist => 'Regular Playlist';
	String itemCount({required Object count}) => '${count} items';
	String get oneItem => '1 item';
	String get emptyPlaylist => 'This playlist is empty';
	String get deleteConfirm => 'Delete Playlist?';
	String deleteMessage({required Object name}) => 'Are you sure you want to delete "${name}"?';
	String get created => 'Playlist created';
	String get updated => 'Playlist updated';
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
	@override late final _StringsTooltipsDe tooltips = _StringsTooltipsDe._(_root);
	@override late final _StringsVideoControlsDe videoControls = _StringsVideoControlsDe._(_root);
	@override late final _StringsUserStatusDe userStatus = _StringsUserStatusDe._(_root);
	@override late final _StringsMessagesDe messages = _StringsMessagesDe._(_root);
	@override late final _StringsProfileDe profile = _StringsProfileDe._(_root);
	@override late final _StringsSubtitlingStylingDe subtitlingStyling = _StringsSubtitlingStylingDe._(_root);
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
	@override late final _StringsPlaylistsDe playlists = _StringsPlaylistsDe._(_root);
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
	@override String get playNow => 'Jetzt abspielen';
	@override String get logout => 'Abmelden';
	@override String get online => 'Online';
	@override String get offline => 'Offline';
	@override String get owned => 'Eigentum';
	@override String get shared => 'Geteilt';
	@override String get current => 'AKTUELL';
	@override String get unknown => 'Unbekannt';
	@override String get refresh => 'Aktualisieren';
	@override String get yes => 'Ja';
	@override String get no => 'Nein';
	@override String get server => 'Server';
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
	@override String get theme => 'Theme';
	@override String get appearance => 'Darstellung';
	@override String get videoPlayback => 'Videowiedergabe';
	@override String get shufflePlay => 'Zufallswiedergabe';
	@override String get advanced => 'Erweitert';
	@override String get useSeasonPostersDescription => 'Staffelposter statt Serienposter für Episoden anzeigen';
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
	@override String get libraryDensity => 'Bibliotheksdichte';
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
	@override String get useSeasonPosters => 'Staffelposter verwenden';
	@override String get showHeroSection => 'Hero-Bereich anzeigen';
	@override String get hardwareDecoding => 'Hardware-Decodierung';
	@override String get hardwareDecodingDescription => 'Hardwarebeschleunigung verwenden, wenn verfügbar';
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
	@override String get unwatchedOnly => 'Nur ungesehene';
	@override String get unwatchedOnlyDescription => 'Nur ungesehene Episoden in die Shuffle-Warteschlange aufnehmen';
	@override String get shuffleOrderNavigation => 'Navigation der Shuffle-Reihenfolge';
	@override String get shuffleOrderNavigationDescription => 'Weiter/Zurück folgt der zufälligen Reihenfolge';
	@override String get loopShuffleQueue => 'Shuffle-Warteschlange wiederholen';
	@override String get loopShuffleQueueDescription => 'Warteschlange neu starten, wenn das Ende erreicht ist';
	@override String get videoPlayerControls => 'Videoplayer-Steuerung';
	@override String get keyboardShortcuts => 'Tastenkürzel';
	@override String get keyboardShortcutsDescription => 'Tastenkürzel anpassen';
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
}

// Path: userStatus
class _StringsUserStatusDe implements _StringsUserStatusEn {
	_StringsUserStatusDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Admin';
	@override String get restricted => 'Eingeschränkt';
	@override String get protected => 'Geschützt';
}

// Path: messages
class _StringsMessagesDe implements _StringsMessagesEn {
	_StringsMessagesDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Als gesehen markiert';
	@override String get markedAsUnwatched => 'Als ungesehen markiert';
	@override String get removedFromContinueWatching => 'Aus ‚Weiterschauen‘ entfernt';
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
	@override String libraryScanStarted({required Object title}) => 'Bibliotheksscan gestartet für „${title}“';
	@override String libraryScanFailed({required Object error}) => 'Fehler beim Scannen der Bibliothek: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Metadaten werden aktualisiert für „${title}“...';
	@override String metadataRefreshStarted({required Object title}) => 'Metadaten-Aktualisierung gestartet für „${title}“';
	@override String metadataRefreshFailed({required Object error}) => 'Metadaten konnten nicht aktualisiert werden: ${error}';
	@override String get noPlexToken => 'Kein Plex-Token gefunden. Bitte erneut anmelden.';
	@override String get logoutConfirm => 'Abmeldung wirklich durchführen?';
	@override String get noSeasonsFound => 'Keine Staffeln gefunden';
	@override String get noEpisodesFound => 'Keine Episoden in der ersten Staffel gefunden';
	@override String get noEpisodesFoundGeneral => 'Keine Episoden gefunden';
	@override String get noResultsFound => 'Keine Ergebnisse gefunden';
	@override String sleepTimerSet({required Object label}) => 'Sleep-Timer gesetzt auf ${label}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Profilwechsel zu ${displayName} fehlgeschlagen';
}

// Path: profile
class _StringsProfileDe implements _StringsProfileEn {
	_StringsProfileDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get noUsersAvailable => 'Keine Benutzer verfügbar';
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

// Path: dialog
class _StringsDialogDe implements _StringsDialogEn {
	_StringsDialogDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Aktion bestätigen';
	@override String get areYouSure => 'Aktion wirklich ausführen?';
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
	@override String get addMediaToLibraries => 'Medien zur Bibliothek hinzufügen';
	@override String get continueWatching => 'Weiterschauen';
	@override String get recentlyAdded => 'Kürzlich hinzugefügt';
	@override String get play => 'Abspielen';
	@override String get resume => 'Fortsetzen';
	@override String playEpisode({required Object season, required Object episode}) => 'Spiele S${season}, E${episode}';
	@override String resumeEpisode({required Object season, required Object episode}) => 'Fortsetzen S${season}, E${episode}';
	@override String get pause => 'Pause';
	@override String get overview => 'Übersicht';
	@override String get cast => 'Besetzung';
	@override String episodeCount({required Object count}) => '${count} Episoden';
	@override String watchedProgress({required Object watched, required Object total}) => '${watched}/${total} gesehen';
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
	@override String get connectionFailedGeneric => 'Verbindung fehlgeschlagen';
}

// Path: libraries
class _StringsLibrariesDe implements _StringsLibrariesEn {
	_StringsLibrariesDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bibliotheken';
	@override String get scanLibraryFiles => 'Bibliotheksdateien scannen';
	@override String get scanLibrary => 'Bibliothek scannen';
	@override String get analyze => 'Analysieren';
	@override String get analyzeLibrary => 'Bibliothek analysieren';
	@override String get refreshMetadata => 'Metadaten aktualisieren';
	@override String get emptyTrash => 'Papierkorb leeren';
	@override String emptyingTrash({required Object title}) => 'Papierkorb für „${title}“ wird geleert...';
	@override String trashEmptied({required Object title}) => 'Papierkorb für „${title}“ geleert';
	@override String failedToEmptyTrash({required Object error}) => 'Papierkorb konnte nicht geleert werden: ${error}';
	@override String analyzing({required Object title}) => 'Analysiere „${title}“...';
	@override String analysisStarted({required Object title}) => 'Analyse gestartet für „${title}“';
	@override String failedToAnalyze({required Object error}) => 'Analyse der Bibliothek fehlgeschlagen: ${error}';
	@override String get noLibrariesFound => 'Keine Bibliotheken gefunden';
	@override String get thisLibraryIsEmpty => 'Diese Bibliothek ist leer';
	@override String get all => 'Alle';
	@override String get clearAll => 'Alle löschen';
	@override String scanLibraryConfirm({required Object title}) => '„${title}“ wirklich scannen?';
	@override String analyzeLibraryConfirm({required Object title}) => '„${title}“ wirklich analysieren?';
	@override String refreshMetadataConfirm({required Object title}) => 'Metadaten für „${title}“ wirklich aktualisieren?';
	@override String emptyTrashConfirm({required Object title}) => 'Papierkorb für „${title}“ wirklich leeren?';
	@override String get manageLibraries => 'Bibliotheken verwalten';
	@override String get sort => 'Sortieren';
	@override String get sortBy => 'Sortieren nach';
	@override String get filters => 'Filter';
	@override String loadingLibraryWithCount({required Object count}) => 'Lade Bibliothek... (${count} Elemente geladen)';
	@override String get confirmActionMessage => 'Aktion wirklich durchführen?';
	@override String get showLibrary => 'Bibliothek anzeigen';
	@override String get hideLibrary => 'Bibliothek ausblenden';
	@override String get libraryOptions => 'Bibliotheksoptionen';
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
	@override String get connectingToServer => 'Verbinde mit Server...';
	@override String get serverDebugCopied => 'Server-Debugdaten kopiert';
	@override String get copyDebugData => 'Debugdaten kopieren';
	@override String get noServersFound => 'Keine Server gefunden';
	@override String malformedServerData({required Object count}) => '${count} Server mit fehlerhaften Daten gefunden. Keine gültigen Server verfügbar.';
	@override String get incompleteServerInfo => 'Einige Serverinformationen sind unvollständig und wurden übersprungen. Plex.tv-Konto prüfen.';
	@override String get incompleteConnectionInfo => 'Serververbindungsinformationen unvollständig. Bitte erneut versuchen.';
	@override String malformedServerInfo({required Object message}) => 'Serverinformationen fehlerhaft: ${message}';
	@override String get networkConnectionFailed => 'Netzwerkverbindung fehlgeschlagen. Internetverbindung prüfen und erneut versuchen.';
	@override String get authenticationFailed => 'Authentifizierung fehlgeschlagen. Bitte erneut anmelden.';
	@override String get plexServiceUnavailable => 'Plex-Dienst nicht verfügbar. Bitte später erneut versuchen.';
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
	@override String get title => 'Protokolle';
	@override String get clearLogs => 'Protokolle löschen';
	@override String get copyLogs => 'Protokolle kopieren';
	@override String get exportLogs => 'Protokolle exportieren';
	@override String get noLogsToShow => 'Keine Protokolle zum Anzeigen';
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
	@override String get libraries => 'Bibliotheken';
	@override String get settings => 'Einstellungen';
}

// Path: playlists
class _StringsPlaylistsDe implements _StringsPlaylistsEn {
	_StringsPlaylistsDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Playlists';
	@override String get noPlaylists => 'Keine Playlists gefunden';
	@override String get create => 'Playlist erstellen';
	@override String get newPlaylist => 'Neue Playlist';
	@override String get playlistName => 'Playlist-Name';
	@override String get enterPlaylistName => 'Playlist-Namen eingeben';
	@override String get edit => 'Playlist bearbeiten';
	@override String get delete => 'Playlist löschen';
	@override String get addTo => 'Zur Playlist hinzufügen';
	@override String get addItems => 'Elemente hinzufügen';
	@override String get removeItem => 'Aus Playlist entfernen';
	@override String get clearPlaylist => 'Playlist leeren';
	@override String get playAll => 'Alle abspielen';
	@override String get shuffle => 'Zufällig';
	@override String get smartPlaylist => 'Intelligente Playlist';
	@override String get regularPlaylist => 'Normale Playlist';
	@override String itemCount({required Object count}) => '${count} Elemente';
	@override String get oneItem => '1 Element';
	@override String get emptyPlaylist => 'Diese Playlist ist leer';
	@override String get deleteConfirm => 'Playlist löschen?';
	@override String deleteMessage({required Object name}) => 'Möchten Sie "${name}" wirklich löschen?';
	@override String get created => 'Playlist erstellt';
	@override String get updated => 'Playlist aktualisiert';
	@override String get deleted => 'Playlist gelöscht';
	@override String get itemAdded => 'Zur Playlist hinzugefügt';
	@override String get itemRemoved => 'Aus Playlist entfernt';
	@override String get selectPlaylist => 'Playlist auswählen';
	@override String get createNewPlaylist => 'Neue Playlist erstellen';
	@override String get errorCreating => 'Fehler beim Erstellen der Playlist';
	@override String get errorDeleting => 'Fehler beim Löschen der Playlist';
	@override String get errorLoading => 'Fehler beim Laden der Playlists';
	@override String get errorAdding => 'Fehler beim Hinzufügen zur Playlist';
	@override String get errorReordering => 'Fehler beim Neuordnen des Playlist-Elements';
	@override String get errorRemoving => 'Fehler beim Entfernen aus der Playlist';
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
	@override late final _StringsTooltipsIt tooltips = _StringsTooltipsIt._(_root);
	@override late final _StringsVideoControlsIt videoControls = _StringsVideoControlsIt._(_root);
	@override late final _StringsUserStatusIt userStatus = _StringsUserStatusIt._(_root);
	@override late final _StringsMessagesIt messages = _StringsMessagesIt._(_root);
	@override late final _StringsProfileIt profile = _StringsProfileIt._(_root);
	@override late final _StringsSubtitlingStylingIt subtitlingStyling = _StringsSubtitlingStylingIt._(_root);
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
	@override late final _StringsPlaylistsIt playlists = _StringsPlaylistsIt._(_root);
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
	@override String get playNow => 'Riproduci ora';
	@override String get logout => 'Disconnetti';
	@override String get online => 'Online';
	@override String get offline => 'Offline';
	@override String get owned => 'Di proprietà';
	@override String get shared => 'Condiviso';
	@override String get current => 'CORRENTE';
	@override String get unknown => 'Sconosciuto';
	@override String get refresh => 'Aggiorna';
	@override String get yes => 'Sì';
	@override String get no => 'No';
	@override String get server => 'Server';
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
	@override String get search => 'Cerca';
	@override String get logs => 'Logs';
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
	@override String get shufflePlay => 'Riproduzione casuale';
	@override String get advanced => 'Avanzate';
	@override String get useSeasonPostersDescription => 'Mostra il poster della stagione invece del poster della serie per gli episodi';
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
	@override String get useSeasonPosters => 'Usa poster delle stagioni';
	@override String get showHeroSection => 'Mostra sezione principale';
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
	@override String get unwatchedOnly => 'Solo non guardati';
	@override String get unwatchedOnlyDescription => 'Includi solo gli episodi non guardati nella coda di riproduzione casuale';
	@override String get shuffleOrderNavigation => 'Navigazione in ordine casuale';
	@override String get shuffleOrderNavigationDescription => 'I pulsanti Avanti/Indietro seguono l\'ordine casuale';
	@override String get loopShuffleQueue => 'Coda di riproduzione casuale in loop';
	@override String get loopShuffleQueueDescription => 'Riavvia la coda quando raggiungi la fine';
	@override String get videoPlayerControls => 'Controlli del lettore video';
	@override String get keyboardShortcuts => 'Scorciatoie da tastiera';
	@override String get keyboardShortcutsDescription => 'Personalizza le scorciatoie da tastiera';
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
	@override String get noOffset => 'No offset';
	@override String get letterbox => 'Letterbox';
	@override String get fillScreen => 'Riempi schermo';
	@override String get stretch => 'Allunga';
	@override String get lockRotation => 'Blocca rotazione';
	@override String get unlockRotation => 'Sblocca rotazione';
}

// Path: userStatus
class _StringsUserStatusIt implements _StringsUserStatusEn {
	_StringsUserStatusIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Admin';
	@override String get restricted => 'Limitato';
	@override String get protected => 'Protetto';
}

// Path: messages
class _StringsMessagesIt implements _StringsMessagesEn {
	_StringsMessagesIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Segna come visto';
	@override String get markedAsUnwatched => 'Segna come non visto';
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
	@override String get noPlexToken => 'Nessun token Plex trovato. Riesegui l\'accesso.';
	@override String get logoutConfirm => 'Sei sicuro di volerti disconnettere?';
	@override String get noSeasonsFound => 'Nessuna stagione trovata';
	@override String get noEpisodesFound => 'Nessun episodio trovato nella prima stagione';
	@override String get noEpisodesFoundGeneral => 'Nessun episodio trovato';
	@override String get noResultsFound => 'Nessun risultato';
	@override String sleepTimerSet({required Object label}) => 'Imposta timer spegnimento per ${label}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Impossibile passare a ${displayName}';
}

// Path: profile
class _StringsProfileIt implements _StringsProfileEn {
	_StringsProfileIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get noUsersAvailable => 'Nessun utente disponibile';
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

// Path: dialog
class _StringsDialogIt implements _StringsDialogEn {
	_StringsDialogIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Conferma azione';
	@override String get areYouSure => 'Sei sicuro di voler eseguire questa azione?';
	@override String get cancel => 'Cancella';
	@override String get playNow => 'Riproduci ora';
}

// Path: discover
class _StringsDiscoverIt implements _StringsDiscoverEn {
	_StringsDiscoverIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Discover';
	@override String get switchProfile => 'Cambia profilo';
	@override String get switchServer => 'Cambia server';
	@override String get logout => 'Disconnetti';
	@override String get noContentAvailable => 'Nessun contenuto disponibile';
	@override String get addMediaToLibraries => 'Aggiungi alcuni file multimediali alle tue librerie';
	@override String get continueWatching => 'Continua a guardare';
	@override String get recentlyAdded => 'Aggiunti di recente';
	@override String get play => 'Riproduci';
	@override String get resume => 'Riprendi';
	@override String playEpisode({required Object season, required Object episode}) => 'Riproduci S${season}, E${episode}';
	@override String resumeEpisode({required Object season, required Object episode}) => 'Riprendi S${season}, E${episode}';
	@override String get pause => 'Pausa';
	@override String get overview => 'Panoramica';
	@override String get cast => 'Cast';
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
	@override String get connectionFailedGeneric => 'Connessione fallita';
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
	@override String loadingLibraryWithCount({required Object count}) => 'Caricamento librerie... (${count} oggetti caricati)';
	@override String get confirmActionMessage => 'Sei sicuro di voler eseguire questa azione?';
	@override String get showLibrary => 'Mostra libreria';
	@override String get hideLibrary => 'Nascondi libreria';
	@override String get libraryOptions => 'Opzioni libreria';
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
	@override String get connectingToServer => 'Connessione al server...';
	@override String get serverDebugCopied => 'Dati di debug del server copiati negli appunti';
	@override String get copyDebugData => 'Copia dati di debug';
	@override String get noServersFound => 'Nessun server trovato';
	@override String malformedServerData({required Object count}) => 'Trovato ${count} server con dati difettosi. Nessun server valido disponibile.';
	@override String get incompleteServerInfo => 'Alcuni server presentano informazioni incomplete e sono stati ignorati. Controlla il tuo account Plex.tv.';
	@override String get incompleteConnectionInfo => 'Le informazioni di connessione al server sono incomplete. Riprova.';
	@override String malformedServerInfo({required Object message}) => 'Le informazioni sul server sono errate: ${message}';
	@override String get networkConnectionFailed => 'Connessione di rete non riuscita. Controlla la tua connessione Internet e riprova.';
	@override String get authenticationFailed => 'Autenticazione fallita. Effettua nuovamente l\'accesso.';
	@override String get plexServiceUnavailable => 'Servizio Plex non disponibile. Riprova più tardi.';
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
	@override String get title => 'Log';
	@override String get clearLogs => 'Cancella log';
	@override String get copyLogs => 'Copia log';
	@override String get exportLogs => 'Esporta log';
	@override String get noLogsToShow => 'Nessun log da mostrare';
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
}

// Path: playlists
class _StringsPlaylistsIt implements _StringsPlaylistsEn {
	_StringsPlaylistsIt._(this._root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Playlist';
	@override String get noPlaylists => 'Nessuna playlist trovata';
	@override String get create => 'Crea playlist';
	@override String get newPlaylist => 'Nuova playlist';
	@override String get playlistName => 'Nome playlist';
	@override String get enterPlaylistName => 'Inserisci nome playlist';
	@override String get edit => 'Modifica playlist';
	@override String get delete => 'Elimina playlist';
	@override String get addTo => 'Aggiungi a playlist';
	@override String get addItems => 'Aggiungi elementi';
	@override String get removeItem => 'Rimuovi da playlist';
	@override String get clearPlaylist => 'Svuota playlist';
	@override String get playAll => 'Riproduci tutto';
	@override String get shuffle => 'Casuale';
	@override String get smartPlaylist => 'Playlist intelligente';
	@override String get regularPlaylist => 'Playlist normale';
	@override String itemCount({required Object count}) => '${count} elementi';
	@override String get oneItem => '1 elemento';
	@override String get emptyPlaylist => 'Questa playlist è vuota';
	@override String get deleteConfirm => 'Eliminare playlist?';
	@override String deleteMessage({required Object name}) => 'Sei sicuro di voler eliminare "${name}"?';
	@override String get created => 'Playlist creata';
	@override String get updated => 'Playlist aggiornata';
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
	@override late final _StringsTooltipsNl tooltips = _StringsTooltipsNl._(_root);
	@override late final _StringsVideoControlsNl videoControls = _StringsVideoControlsNl._(_root);
	@override late final _StringsUserStatusNl userStatus = _StringsUserStatusNl._(_root);
	@override late final _StringsMessagesNl messages = _StringsMessagesNl._(_root);
	@override late final _StringsProfileNl profile = _StringsProfileNl._(_root);
	@override late final _StringsSubtitlingStylingNl subtitlingStyling = _StringsSubtitlingStylingNl._(_root);
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
	@override late final _StringsPlaylistsNl playlists = _StringsPlaylistsNl._(_root);
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
	@override String get plexTokenLabel => 'Plex Auth Token';
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
	@override String get playNow => 'Nu afspelen';
	@override String get logout => 'Uitloggen';
	@override String get online => 'Online';
	@override String get offline => 'Offline';
	@override String get owned => 'Eigendom';
	@override String get shared => 'Gedeeld';
	@override String get current => 'HUIDIG';
	@override String get unknown => 'Onbekend';
	@override String get refresh => 'Vernieuwen';
	@override String get yes => 'Ja';
	@override String get no => 'Nee';
	@override String get server => 'Server';
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
	@override String get search => 'Zoeken';
	@override String get logs => 'Logs';
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
	@override String get shufflePlay => 'Willekeurig afspelen';
	@override String get advanced => 'Geavanceerd';
	@override String get useSeasonPostersDescription => 'Toon seizoenposter in plaats van serieposter voor afleveringen';
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
	@override String get useSeasonPosters => 'Gebruik seizoenposters';
	@override String get showHeroSection => 'Toon hoofdsectie';
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
	@override String get unwatchedOnly => 'Alleen ongekeken';
	@override String get unwatchedOnlyDescription => 'Alleen ongekeken afleveringen opnemen in willekeurige wachtrij';
	@override String get shuffleOrderNavigation => 'Willekeurige volgorde navigatie';
	@override String get shuffleOrderNavigationDescription => 'Volgende/vorige knoppen volgen willekeurige volgorde';
	@override String get loopShuffleQueue => 'Herhaal willekeurige wachtrij';
	@override String get loopShuffleQueueDescription => 'Start wachtrij opnieuw bij het einde';
	@override String get videoPlayerControls => 'Videospeler bediening';
	@override String get keyboardShortcuts => 'Toetsenbord sneltoetsen';
	@override String get keyboardShortcutsDescription => 'Pas toetsenbord sneltoetsen aan';
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
}

// Path: userStatus
class _StringsUserStatusNl implements _StringsUserStatusEn {
	_StringsUserStatusNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Beheerder';
	@override String get restricted => 'Beperkt';
	@override String get protected => 'Beschermd';
}

// Path: messages
class _StringsMessagesNl implements _StringsMessagesEn {
	_StringsMessagesNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Gemarkeerd als gekeken';
	@override String get markedAsUnwatched => 'Gemarkeerd als ongekeken';
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
	@override String get noPlexToken => 'Geen Plex token gevonden. Log opnieuw in.';
	@override String get logoutConfirm => 'Weet je zeker dat je wilt uitloggen?';
	@override String get noSeasonsFound => 'Geen seizoenen gevonden';
	@override String get noEpisodesFound => 'Geen afleveringen gevonden in eerste seizoen';
	@override String get noEpisodesFoundGeneral => 'Geen afleveringen gevonden';
	@override String get noResultsFound => 'Geen resultaten gevonden';
	@override String sleepTimerSet({required Object label}) => 'Slaap timer ingesteld voor ${label}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Kon niet wisselen naar ${displayName}';
}

// Path: profile
class _StringsProfileNl implements _StringsProfileEn {
	_StringsProfileNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get noUsersAvailable => 'Geen gebruikers beschikbaar';
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

// Path: dialog
class _StringsDialogNl implements _StringsDialogEn {
	_StringsDialogNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Bevestig actie';
	@override String get areYouSure => 'Weet je zeker dat je deze actie wilt uitvoeren?';
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
	@override String get recentlyAdded => 'Recent toegevoegd';
	@override String get play => 'Afspelen';
	@override String get resume => 'Hervatten';
	@override String playEpisode({required Object season, required Object episode}) => 'Speel S${season}, E${episode}';
	@override String resumeEpisode({required Object season, required Object episode}) => 'Hervat S${season}, E${episode}';
	@override String get pause => 'Pauzeren';
	@override String get overview => 'Overzicht';
	@override String get cast => 'Cast';
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
	@override String get connectionFailedGeneric => 'Verbinding mislukt';
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
	@override String loadingLibraryWithCount({required Object count}) => 'Bibliotheek laden... (${count} items geladen)';
	@override String get confirmActionMessage => 'Weet je zeker dat je deze actie wilt uitvoeren?';
	@override String get showLibrary => 'Toon bibliotheek';
	@override String get hideLibrary => 'Verberg bibliotheek';
	@override String get libraryOptions => 'Bibliotheek opties';
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
	@override String get connectingToServer => 'Verbinden met server...';
	@override String get serverDebugCopied => 'Server debug gegevens gekopieerd naar klembord';
	@override String get copyDebugData => 'Kopieer debug gegevens';
	@override String get noServersFound => 'Geen servers gevonden';
	@override String malformedServerData({required Object count}) => '${count} server(s) gevonden met verkeerde data. Geen geldige servers beschikbaar.';
	@override String get incompleteServerInfo => 'Sommige servers hebben incomplete informatie en zijn overgeslagen. Controleer je Plex.tv account.';
	@override String get incompleteConnectionInfo => 'Server verbinding informatie is incompleet. Probeer opnieuw.';
	@override String malformedServerInfo({required Object message}) => 'Server informatie is verkeerd geformatteerd: ${message}';
	@override String get networkConnectionFailed => 'Netwerkverbinding mislukt. Controleer je internetverbinding en probeer opnieuw.';
	@override String get authenticationFailed => 'Authenticatie mislukt. Log opnieuw in.';
	@override String get plexServiceUnavailable => 'Plex service niet beschikbaar. Probeer later opnieuw.';
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
	@override String get title => 'Logs';
	@override String get clearLogs => 'Wis logs';
	@override String get copyLogs => 'Kopieer logs';
	@override String get exportLogs => 'Exporteer logs';
	@override String get noLogsToShow => 'Geen logs om te tonen';
	@override String get error => 'Fout:';
	@override String get stackTrace => 'Stack Trace:';
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
	@override String get home => 'Home';
	@override String get search => 'Zoeken';
	@override String get libraries => 'Bibliotheken';
	@override String get settings => 'Instellingen';
}

// Path: playlists
class _StringsPlaylistsNl implements _StringsPlaylistsEn {
	_StringsPlaylistsNl._(this._root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Afspeellijsten';
	@override String get noPlaylists => 'Geen afspeellijsten gevonden';
	@override String get create => 'Afspeellijst maken';
	@override String get newPlaylist => 'Nieuwe afspeellijst';
	@override String get playlistName => 'Naam afspeellijst';
	@override String get enterPlaylistName => 'Voer naam afspeellijst in';
	@override String get edit => 'Afspeellijst bewerken';
	@override String get delete => 'Afspeellijst verwijderen';
	@override String get addTo => 'Toevoegen aan afspeellijst';
	@override String get addItems => 'Items toevoegen';
	@override String get removeItem => 'Verwijderen uit afspeellijst';
	@override String get clearPlaylist => 'Afspeellijst wissen';
	@override String get playAll => 'Alles afspelen';
	@override String get shuffle => 'Shuffle';
	@override String get smartPlaylist => 'Slimme afspeellijst';
	@override String get regularPlaylist => 'Normale afspeellijst';
	@override String itemCount({required Object count}) => '${count} items';
	@override String get oneItem => '1 item';
	@override String get emptyPlaylist => 'Deze afspeellijst is leeg';
	@override String get deleteConfirm => 'Afspeellijst verwijderen?';
	@override String deleteMessage({required Object name}) => 'Weet je zeker dat je "${name}" wilt verwijderen?';
	@override String get created => 'Afspeellijst gemaakt';
	@override String get updated => 'Afspeellijst bijgewerkt';
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
	@override late final _StringsTooltipsSv tooltips = _StringsTooltipsSv._(_root);
	@override late final _StringsVideoControlsSv videoControls = _StringsVideoControlsSv._(_root);
	@override late final _StringsUserStatusSv userStatus = _StringsUserStatusSv._(_root);
	@override late final _StringsMessagesSv messages = _StringsMessagesSv._(_root);
	@override late final _StringsProfileSv profile = _StringsProfileSv._(_root);
	@override late final _StringsSubtitlingStylingSv subtitlingStyling = _StringsSubtitlingStylingSv._(_root);
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
	@override late final _StringsPlaylistsSv playlists = _StringsPlaylistsSv._(_root);
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
	@override String get playNow => 'Spela nu';
	@override String get logout => 'Logga ut';
	@override String get online => 'Online';
	@override String get offline => 'Offline';
	@override String get owned => 'Egen';
	@override String get shared => 'Delad';
	@override String get current => 'NUVARANDE';
	@override String get unknown => 'Okänd';
	@override String get refresh => 'Uppdatera';
	@override String get yes => 'Ja';
	@override String get no => 'Nej';
	@override String get server => 'Server';
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
	@override String get shufflePlay => 'Blanda uppspelning';
	@override String get advanced => 'Avancerat';
	@override String get useSeasonPostersDescription => 'Visa säsongsaffisch istället för serieaffisch för avsnitt';
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
	@override String get useSeasonPosters => 'Använd säsongsaffischer';
	@override String get showHeroSection => 'Visa hjältesektion';
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
	@override String get unwatchedOnly => 'Endast osedda';
	@override String get unwatchedOnlyDescription => 'Inkludera endast osedda avsnitt i blandningskön';
	@override String get shuffleOrderNavigation => 'Blandningsordning-navigation';
	@override String get shuffleOrderNavigationDescription => 'Nästa/föregående knappar följer blandad ordning';
	@override String get loopShuffleQueue => 'Loopa blandningskö';
	@override String get loopShuffleQueueDescription => 'Starta om kö när slutet nås';
	@override String get videoPlayerControls => 'Videospelar-kontroller';
	@override String get keyboardShortcuts => 'Tangentbordsgenvägar';
	@override String get keyboardShortcutsDescription => 'Anpassa tangentbordsgenvägar';
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
}

// Path: userStatus
class _StringsUserStatusSv implements _StringsUserStatusEn {
	_StringsUserStatusSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Admin';
	@override String get restricted => 'Begränsad';
	@override String get protected => 'Skyddad';
}

// Path: messages
class _StringsMessagesSv implements _StringsMessagesEn {
	_StringsMessagesSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Markerad som sedd';
	@override String get markedAsUnwatched => 'Markerad som osedd';
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
	@override String get noPlexToken => 'Ingen Plex-token hittad. Vänligen logga in igen.';
	@override String get logoutConfirm => 'Är du säker på att du vill logga ut?';
	@override String get noSeasonsFound => 'Inga säsonger hittades';
	@override String get noEpisodesFound => 'Inga avsnitt hittades i första säsongen';
	@override String get noEpisodesFoundGeneral => 'Inga avsnitt hittades';
	@override String get noResultsFound => 'Inga resultat hittades';
	@override String sleepTimerSet({required Object label}) => 'Sovtimer inställd för ${label}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Misslyckades att byta till ${displayName}';
}

// Path: profile
class _StringsProfileSv implements _StringsProfileEn {
	_StringsProfileSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get noUsersAvailable => 'Inga användare tillgängliga';
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

// Path: dialog
class _StringsDialogSv implements _StringsDialogEn {
	_StringsDialogSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Bekräfta åtgärd';
	@override String get areYouSure => 'Är du säker på att du vill utföra denna åtgärd?';
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
	@override String get recentlyAdded => 'Nyligen tillagda';
	@override String get play => 'Spela';
	@override String get resume => 'Återuppta';
	@override String playEpisode({required Object season, required Object episode}) => 'Spela S${season}, E${episode}';
	@override String resumeEpisode({required Object season, required Object episode}) => 'Återuppta S${season}, E${episode}';
	@override String get pause => 'Pausa';
	@override String get overview => 'Översikt';
	@override String get cast => 'Rollbesättning';
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
	@override String get connectionFailedGeneric => 'Anslutning misslyckades';
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
	@override String loadingLibraryWithCount({required Object count}) => 'Laddar bibliotek... (${count} objekt laddade)';
	@override String get confirmActionMessage => 'Är du säker på att du vill utföra denna åtgärd?';
	@override String get showLibrary => 'Visa bibliotek';
	@override String get hideLibrary => 'Dölj bibliotek';
	@override String get libraryOptions => 'Biblioteksalternativ';
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
	@override String get connectingToServer => 'Ansluter till server...';
	@override String get serverDebugCopied => 'Server-felsökningsdata kopierad till urklipp';
	@override String get copyDebugData => 'Kopiera felsökningsdata';
	@override String get noServersFound => 'Inga servrar hittades';
	@override String malformedServerData({required Object count}) => 'Hittade ${count} server(ar) med felformaterad data. Inga giltiga servrar tillgängliga.';
	@override String get incompleteServerInfo => 'Vissa servrar har ofullständig information och hoppades över. Vänligen kontrollera ditt Plex.tv-konto.';
	@override String get incompleteConnectionInfo => 'Server-anslutningsinformation är ofullständig. Försök igen.';
	@override String malformedServerInfo({required Object message}) => 'Serverinformation är felformaterad: ${message}';
	@override String get networkConnectionFailed => 'Nätverksanslutning misslyckades. Kontrollera din internetanslutning och försök igen.';
	@override String get authenticationFailed => 'Autentisering misslyckades. Logga in igen.';
	@override String get plexServiceUnavailable => 'Plex-tjänst otillgänglig. Försök igen senare.';
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
	@override String get title => 'Loggar';
	@override String get clearLogs => 'Rensa loggar';
	@override String get copyLogs => 'Kopiera loggar';
	@override String get exportLogs => 'Exportera loggar';
	@override String get noLogsToShow => 'Inga loggar att visa';
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
}

// Path: playlists
class _StringsPlaylistsSv implements _StringsPlaylistsEn {
	_StringsPlaylistsSv._(this._root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Spellistor';
	@override String get noPlaylists => 'Inga spellistor hittades';
	@override String get create => 'Skapa spellista';
	@override String get newPlaylist => 'Ny spellista';
	@override String get playlistName => 'Spellistans namn';
	@override String get enterPlaylistName => 'Ange spellistans namn';
	@override String get edit => 'Redigera spellista';
	@override String get delete => 'Ta bort spellista';
	@override String get addTo => 'Lägg till i spellista';
	@override String get addItems => 'Lägg till objekt';
	@override String get removeItem => 'Ta bort från spellista';
	@override String get clearPlaylist => 'Rensa spellista';
	@override String get playAll => 'Spela alla';
	@override String get shuffle => 'Blanda';
	@override String get smartPlaylist => 'Smart spellista';
	@override String get regularPlaylist => 'Vanlig spellista';
	@override String itemCount({required Object count}) => '${count} objekt';
	@override String get oneItem => '1 objekt';
	@override String get emptyPlaylist => 'Denna spellista är tom';
	@override String get deleteConfirm => 'Ta bort spellista?';
	@override String deleteMessage({required Object name}) => 'Är du säker på att du vill ta bort "${name}"?';
	@override String get created => 'Spellista skapad';
	@override String get updated => 'Spellista uppdaterad';
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
	@override late final _StringsTooltipsZh tooltips = _StringsTooltipsZh._(_root);
	@override late final _StringsVideoControlsZh videoControls = _StringsVideoControlsZh._(_root);
	@override late final _StringsUserStatusZh userStatus = _StringsUserStatusZh._(_root);
	@override late final _StringsMessagesZh messages = _StringsMessagesZh._(_root);
	@override late final _StringsProfileZh profile = _StringsProfileZh._(_root);
	@override late final _StringsSubtitlingStylingZh subtitlingStyling = _StringsSubtitlingStylingZh._(_root);
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
	@override late final _StringsPlaylistsZh playlists = _StringsPlaylistsZh._(_root);
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
	@override String get playNow => '立即播放';
	@override String get logout => '登出';
	@override String get online => '在线';
	@override String get offline => '离线';
	@override String get owned => '拥有';
	@override String get shared => '共享';
	@override String get current => '当前';
	@override String get unknown => '未知';
	@override String get refresh => '刷新';
	@override String get yes => '是';
	@override String get no => '否';
	@override String get server => '服务器';
}

// Path: screens
class _StringsScreensZh implements _StringsScreensEn {
	_StringsScreensZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get licenses => '许可证';
	@override String get selectServer => '选择服务器';
	@override String get switchProfile => '切换配置文件';
	@override String get subtitleStyling => '字幕样式';
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
	@override String get shufflePlay => '随机播放';
	@override String get advanced => '高级';
	@override String get useSeasonPostersDescription => '为剧集显示季海报而非剧集海报';
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
	@override String get useSeasonPosters => '使用季海报';
	@override String get showHeroSection => '显示主要精选区';
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
	@override String get unwatchedOnly => '仅未观看';
	@override String get unwatchedOnlyDescription => '随机队列中仅包含未观看的剧集';
	@override String get shuffleOrderNavigation => '随机顺序导航';
	@override String get shuffleOrderNavigationDescription => '下一集/上一集按钮遵循随机播放顺序';
	@override String get loopShuffleQueue => '循环随机队列';
	@override String get loopShuffleQueueDescription => '在队列结束时重新开始';
	@override String get videoPlayerControls => '视频播放器控制';
	@override String get keyboardShortcuts => '键盘快捷键';
	@override String get keyboardShortcutsDescription => '自定义键盘快捷键';
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
}

// Path: userStatus
class _StringsUserStatusZh implements _StringsUserStatusEn {
	_StringsUserStatusZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get admin => '管理员';
	@override String get restricted => '受限';
	@override String get protected => '受保护';
}

// Path: messages
class _StringsMessagesZh implements _StringsMessagesEn {
	_StringsMessagesZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => '已标记为已观看';
	@override String get markedAsUnwatched => '已标记为未观看';
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
	@override String get noPlexToken => '未找到 Plex 令牌。请重新登录。';
	@override String get logoutConfirm => '你确定要登出吗？';
	@override String get noSeasonsFound => '未找到季';
	@override String get noEpisodesFound => '在第一季中未找到剧集';
	@override String get noEpisodesFoundGeneral => '未找到剧集';
	@override String get noResultsFound => '未找到结果';
	@override String sleepTimerSet({required Object label}) => '睡眠定时器已设置为 ${label}';
	@override String failedToSwitchProfile({required Object displayName}) => '无法切换到 ${displayName}';
}

// Path: profile
class _StringsProfileZh implements _StringsProfileEn {
	_StringsProfileZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get noUsersAvailable => '没有可用用户';
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

// Path: dialog
class _StringsDialogZh implements _StringsDialogEn {
	_StringsDialogZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => '确认操作';
	@override String get areYouSure => '确定要执行此操作吗？';
	@override String get cancel => '取消';
	@override String get playNow => '立即播放';
}

// Path: discover
class _StringsDiscoverZh implements _StringsDiscoverEn {
	_StringsDiscoverZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '发现';
	@override String get switchProfile => '切换配置文件';
	@override String get switchServer => '切换服务器';
	@override String get logout => '登出';
	@override String get noContentAvailable => '没有可用内容';
	@override String get addMediaToLibraries => '请向你的媒体库添加一些媒体';
	@override String get continueWatching => '继续观看';
	@override String get recentlyAdded => '最近添加';
	@override String get play => '播放';
	@override String get resume => '继续';
	@override String playEpisode({required Object season, required Object episode}) => '播放 S${season}, E${episode}';
	@override String resumeEpisode({required Object season, required Object episode}) => '继续 S${season}, E${episode}';
	@override String get pause => '暂停';
	@override String get overview => '概述';
	@override String get cast => '演员表';
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
	@override String get connectionFailedGeneric => '连接失败';
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
	@override String loadingLibraryWithCount({required Object count}) => '正在加载媒体库... (已加载 ${count} 个项目)';
	@override String get confirmActionMessage => '确定要执行此操作吗？';
	@override String get showLibrary => '显示媒体库';
	@override String get hideLibrary => '隐藏媒体库';
	@override String get libraryOptions => '媒体库选项';
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
	@override String get connectingToServer => '正在连接服务器...';
	@override String get serverDebugCopied => '服务器调试数据已复制到剪贴板';
	@override String get copyDebugData => '复制调试数据';
	@override String get noServersFound => '未找到服务器';
	@override String malformedServerData({required Object count}) => '找到 ${count} 个数据格式错误的服务器。没有可用的有效服务器。';
	@override String get incompleteServerInfo => '某些服务器信息不完整，已被跳过。请检查你的 Plex.tv 账户。';
	@override String get incompleteConnectionInfo => '服务器连接信息不完整。请重试。';
	@override String malformedServerInfo({required Object message}) => '服务器信息格式错误: ${message}';
	@override String get networkConnectionFailed => '网络连接失败。请检查你的网络连接并重试。';
	@override String get authenticationFailed => '验证失败。请重新登录。';
	@override String get plexServiceUnavailable => 'Plex 服务不可用。请稍后重试。';
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
	@override String get title => '日志';
	@override String get clearLogs => '清除日志';
	@override String get copyLogs => '复制日志';
	@override String get exportLogs => '导出日志';
	@override String get noLogsToShow => '没有可显示的日志';
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
}

// Path: playlists
class _StringsPlaylistsZh implements _StringsPlaylistsEn {
	_StringsPlaylistsZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '播放列表';
	@override String get noPlaylists => '未找到播放列表';
	@override String get create => '创建播放列表';
	@override String get newPlaylist => '新播放列表';
	@override String get playlistName => '播放列表名称';
	@override String get enterPlaylistName => '输入播放列表名称';
	@override String get edit => '编辑播放列表';
	@override String get delete => '删除播放列表';
	@override String get addTo => '添加到播放列表';
	@override String get addItems => '添加项目';
	@override String get removeItem => '从播放列表中移除';
	@override String get clearPlaylist => '清空播放列表';
	@override String get playAll => '全部播放';
	@override String get shuffle => '随机播放';
	@override String get smartPlaylist => '智能播放列表';
	@override String get regularPlaylist => '普通播放列表';
	@override String itemCount({required Object count}) => '${count} 个项目';
	@override String get oneItem => '1 个项目';
	@override String get emptyPlaylist => '此播放列表为空';
	@override String get deleteConfirm => '删除播放列表？';
	@override String deleteMessage({required Object name}) => '确定要删除 "${name}" 吗？';
	@override String get created => '播放列表已创建';
	@override String get updated => '播放列表已更新';
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
			case 'common.playNow': return 'Play Now';
			case 'common.logout': return 'Logout';
			case 'common.online': return 'Online';
			case 'common.offline': return 'Offline';
			case 'common.owned': return 'Owned';
			case 'common.shared': return 'Shared';
			case 'common.current': return 'CURRENT';
			case 'common.unknown': return 'Unknown';
			case 'common.refresh': return 'Refresh';
			case 'common.yes': return 'Yes';
			case 'common.no': return 'No';
			case 'common.server': return 'Server';
			case 'screens.licenses': return 'Licenses';
			case 'screens.selectServer': return 'Select Server';
			case 'screens.switchProfile': return 'Switch Profile';
			case 'screens.subtitleStyling': return 'Subtitle Styling';
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
			case 'settings.shufflePlay': return 'Shuffle Play';
			case 'settings.advanced': return 'Advanced';
			case 'settings.useSeasonPostersDescription': return 'Show season poster instead of series poster for episodes';
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
			case 'settings.useSeasonPosters': return 'Use Season Posters';
			case 'settings.showHeroSection': return 'Show Hero Section';
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
			case 'settings.unwatchedOnly': return 'Unwatched Only';
			case 'settings.unwatchedOnlyDescription': return 'Only include unwatched episodes in shuffle queue';
			case 'settings.shuffleOrderNavigation': return 'Shuffle Order Navigation';
			case 'settings.shuffleOrderNavigationDescription': return 'Next/previous buttons follow shuffled order';
			case 'settings.loopShuffleQueue': return 'Loop Shuffle Queue';
			case 'settings.loopShuffleQueueDescription': return 'Restart queue when reaching the end';
			case 'settings.videoPlayerControls': return 'Video Player Controls';
			case 'settings.keyboardShortcuts': return 'Keyboard Shortcuts';
			case 'settings.keyboardShortcutsDescription': return 'Customize keyboard shortcuts';
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
			case 'userStatus.admin': return 'Admin';
			case 'userStatus.restricted': return 'Restricted';
			case 'userStatus.protected': return 'Protected';
			case 'messages.markedAsWatched': return 'Marked as watched';
			case 'messages.markedAsUnwatched': return 'Marked as unwatched';
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
			case 'messages.noPlexToken': return 'No Plex token found. Please login again.';
			case 'messages.logoutConfirm': return 'Are you sure you want to logout?';
			case 'messages.noSeasonsFound': return 'No seasons found';
			case 'messages.noEpisodesFound': return 'No episodes found in first season';
			case 'messages.noEpisodesFoundGeneral': return 'No episodes found';
			case 'messages.noResultsFound': return 'No results found';
			case 'messages.sleepTimerSet': return ({required Object label}) => 'Sleep timer set for ${label}';
			case 'messages.failedToSwitchProfile': return ({required Object displayName}) => 'Failed to switch to ${displayName}';
			case 'profile.noUsersAvailable': return 'No users available';
			case 'subtitlingStyling.stylingOptions': return 'Styling Options';
			case 'subtitlingStyling.fontSize': return 'Font Size';
			case 'subtitlingStyling.textColor': return 'Text Color';
			case 'subtitlingStyling.borderSize': return 'Border Size';
			case 'subtitlingStyling.borderColor': return 'Border Color';
			case 'subtitlingStyling.backgroundOpacity': return 'Background Opacity';
			case 'subtitlingStyling.backgroundColor': return 'Background Color';
			case 'dialog.confirmAction': return 'Confirm Action';
			case 'dialog.areYouSure': return 'Are you sure you want to perform this action?';
			case 'dialog.cancel': return 'Cancel';
			case 'dialog.playNow': return 'Play Now';
			case 'discover.title': return 'Discover';
			case 'discover.switchProfile': return 'Switch Profile';
			case 'discover.switchServer': return 'Switch Server';
			case 'discover.logout': return 'Logout';
			case 'discover.noContentAvailable': return 'No content available';
			case 'discover.addMediaToLibraries': return 'Add some media to your libraries';
			case 'discover.continueWatching': return 'Continue Watching';
			case 'discover.recentlyAdded': return 'Recently Added';
			case 'discover.play': return 'Play';
			case 'discover.resume': return 'Resume';
			case 'discover.playEpisode': return ({required Object season, required Object episode}) => 'Play S${season}, E${episode}';
			case 'discover.resumeEpisode': return ({required Object season, required Object episode}) => 'Resume S${season}, E${episode}';
			case 'discover.pause': return 'Pause';
			case 'discover.overview': return 'Overview';
			case 'discover.cast': return 'Cast';
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
			case 'errors.connectionFailedGeneric': return 'Connection failed';
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
			case 'libraries.loadingLibraryWithCount': return ({required Object count}) => 'Loading library... (${count} items loaded)';
			case 'libraries.confirmActionMessage': return 'Are you sure you want to perform this action?';
			case 'libraries.showLibrary': return 'Show library';
			case 'libraries.hideLibrary': return 'Hide library';
			case 'libraries.libraryOptions': return 'Library options';
			case 'about.title': return 'About';
			case 'about.openSourceLicenses': return 'Open Source Licenses';
			case 'about.versionLabel': return ({required Object version}) => 'Version ${version}';
			case 'about.appDescription': return 'A beautiful Plex client for Flutter';
			case 'about.viewLicensesDescription': return 'View licenses of third-party libraries';
			case 'serverSelection.connectingToServer': return 'Connecting to server...';
			case 'serverSelection.serverDebugCopied': return 'Server debug data copied to clipboard';
			case 'serverSelection.copyDebugData': return 'Copy Debug Data';
			case 'serverSelection.noServersFound': return 'No servers found';
			case 'serverSelection.malformedServerData': return ({required Object count}) => 'Found ${count} server(s) with malformed data. No valid servers available.';
			case 'serverSelection.incompleteServerInfo': return 'Some servers have incomplete information and were skipped. Please check your Plex.tv account.';
			case 'serverSelection.incompleteConnectionInfo': return 'Server connection information is incomplete. Please try again.';
			case 'serverSelection.malformedServerInfo': return ({required Object message}) => 'Server information is malformed: ${message}';
			case 'serverSelection.networkConnectionFailed': return 'Network connection failed. Please check your internet connection and try again.';
			case 'serverSelection.authenticationFailed': return 'Authentication failed. Please sign in again.';
			case 'serverSelection.plexServiceUnavailable': return 'Plex service unavailable. Please try again later.';
			case 'serverSelection.failedToLoadServers': return ({required Object error}) => 'Failed to load servers: ${error}';
			case 'hubDetail.title': return 'Title';
			case 'hubDetail.releaseYear': return 'Release Year';
			case 'hubDetail.dateAdded': return 'Date Added';
			case 'hubDetail.rating': return 'Rating';
			case 'hubDetail.noItemsFound': return 'No items found';
			case 'logs.title': return 'Logs';
			case 'logs.clearLogs': return 'Clear Logs';
			case 'logs.copyLogs': return 'Copy Logs';
			case 'logs.exportLogs': return 'Export Logs';
			case 'logs.noLogsToShow': return 'No logs to show';
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
			case 'playlists.title': return 'Playlists';
			case 'playlists.noPlaylists': return 'No playlists found';
			case 'playlists.create': return 'Create Playlist';
			case 'playlists.newPlaylist': return 'New Playlist';
			case 'playlists.playlistName': return 'Playlist Name';
			case 'playlists.enterPlaylistName': return 'Enter playlist name';
			case 'playlists.edit': return 'Edit Playlist';
			case 'playlists.delete': return 'Delete Playlist';
			case 'playlists.addTo': return 'Add to Playlist';
			case 'playlists.addItems': return 'Add Items';
			case 'playlists.removeItem': return 'Remove from Playlist';
			case 'playlists.clearPlaylist': return 'Clear Playlist';
			case 'playlists.playAll': return 'Play All';
			case 'playlists.shuffle': return 'Shuffle';
			case 'playlists.smartPlaylist': return 'Smart Playlist';
			case 'playlists.regularPlaylist': return 'Regular Playlist';
			case 'playlists.itemCount': return ({required Object count}) => '${count} items';
			case 'playlists.oneItem': return '1 item';
			case 'playlists.emptyPlaylist': return 'This playlist is empty';
			case 'playlists.deleteConfirm': return 'Delete Playlist?';
			case 'playlists.deleteMessage': return ({required Object name}) => 'Are you sure you want to delete "${name}"?';
			case 'playlists.created': return 'Playlist created';
			case 'playlists.updated': return 'Playlist updated';
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
			case 'common.playNow': return 'Jetzt abspielen';
			case 'common.logout': return 'Abmelden';
			case 'common.online': return 'Online';
			case 'common.offline': return 'Offline';
			case 'common.owned': return 'Eigentum';
			case 'common.shared': return 'Geteilt';
			case 'common.current': return 'AKTUELL';
			case 'common.unknown': return 'Unbekannt';
			case 'common.refresh': return 'Aktualisieren';
			case 'common.yes': return 'Ja';
			case 'common.no': return 'Nein';
			case 'common.server': return 'Server';
			case 'screens.licenses': return 'Lizenzen';
			case 'screens.selectServer': return 'Server auswählen';
			case 'screens.switchProfile': return 'Profil wechseln';
			case 'screens.subtitleStyling': return 'Untertitel-Stil';
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
			case 'settings.theme': return 'Theme';
			case 'settings.appearance': return 'Darstellung';
			case 'settings.videoPlayback': return 'Videowiedergabe';
			case 'settings.shufflePlay': return 'Zufallswiedergabe';
			case 'settings.advanced': return 'Erweitert';
			case 'settings.useSeasonPostersDescription': return 'Staffelposter statt Serienposter für Episoden anzeigen';
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
			case 'settings.libraryDensity': return 'Bibliotheksdichte';
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
			case 'settings.useSeasonPosters': return 'Staffelposter verwenden';
			case 'settings.showHeroSection': return 'Hero-Bereich anzeigen';
			case 'settings.hardwareDecoding': return 'Hardware-Decodierung';
			case 'settings.hardwareDecodingDescription': return 'Hardwarebeschleunigung verwenden, wenn verfügbar';
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
			case 'settings.unwatchedOnly': return 'Nur ungesehene';
			case 'settings.unwatchedOnlyDescription': return 'Nur ungesehene Episoden in die Shuffle-Warteschlange aufnehmen';
			case 'settings.shuffleOrderNavigation': return 'Navigation der Shuffle-Reihenfolge';
			case 'settings.shuffleOrderNavigationDescription': return 'Weiter/Zurück folgt der zufälligen Reihenfolge';
			case 'settings.loopShuffleQueue': return 'Shuffle-Warteschlange wiederholen';
			case 'settings.loopShuffleQueueDescription': return 'Warteschlange neu starten, wenn das Ende erreicht ist';
			case 'settings.videoPlayerControls': return 'Videoplayer-Steuerung';
			case 'settings.keyboardShortcuts': return 'Tastenkürzel';
			case 'settings.keyboardShortcutsDescription': return 'Tastenkürzel anpassen';
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
			case 'userStatus.admin': return 'Admin';
			case 'userStatus.restricted': return 'Eingeschränkt';
			case 'userStatus.protected': return 'Geschützt';
			case 'messages.markedAsWatched': return 'Als gesehen markiert';
			case 'messages.markedAsUnwatched': return 'Als ungesehen markiert';
			case 'messages.removedFromContinueWatching': return 'Aus ‚Weiterschauen‘ entfernt';
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
			case 'messages.libraryScanStarted': return ({required Object title}) => 'Bibliotheksscan gestartet für „${title}“';
			case 'messages.libraryScanFailed': return ({required Object error}) => 'Fehler beim Scannen der Bibliothek: ${error}';
			case 'messages.metadataRefreshing': return ({required Object title}) => 'Metadaten werden aktualisiert für „${title}“...';
			case 'messages.metadataRefreshStarted': return ({required Object title}) => 'Metadaten-Aktualisierung gestartet für „${title}“';
			case 'messages.metadataRefreshFailed': return ({required Object error}) => 'Metadaten konnten nicht aktualisiert werden: ${error}';
			case 'messages.noPlexToken': return 'Kein Plex-Token gefunden. Bitte erneut anmelden.';
			case 'messages.logoutConfirm': return 'Abmeldung wirklich durchführen?';
			case 'messages.noSeasonsFound': return 'Keine Staffeln gefunden';
			case 'messages.noEpisodesFound': return 'Keine Episoden in der ersten Staffel gefunden';
			case 'messages.noEpisodesFoundGeneral': return 'Keine Episoden gefunden';
			case 'messages.noResultsFound': return 'Keine Ergebnisse gefunden';
			case 'messages.sleepTimerSet': return ({required Object label}) => 'Sleep-Timer gesetzt auf ${label}';
			case 'messages.failedToSwitchProfile': return ({required Object displayName}) => 'Profilwechsel zu ${displayName} fehlgeschlagen';
			case 'profile.noUsersAvailable': return 'Keine Benutzer verfügbar';
			case 'subtitlingStyling.stylingOptions': return 'Stiloptionen';
			case 'subtitlingStyling.fontSize': return 'Schriftgröße';
			case 'subtitlingStyling.textColor': return 'Textfarbe';
			case 'subtitlingStyling.borderSize': return 'Rahmengröße';
			case 'subtitlingStyling.borderColor': return 'Rahmenfarbe';
			case 'subtitlingStyling.backgroundOpacity': return 'Hintergrunddeckkraft';
			case 'subtitlingStyling.backgroundColor': return 'Hintergrundfarbe';
			case 'dialog.confirmAction': return 'Aktion bestätigen';
			case 'dialog.areYouSure': return 'Aktion wirklich ausführen?';
			case 'dialog.cancel': return 'Abbrechen';
			case 'dialog.playNow': return 'Jetzt abspielen';
			case 'discover.title': return 'Entdecken';
			case 'discover.switchProfile': return 'Profil wechseln';
			case 'discover.switchServer': return 'Server wechseln';
			case 'discover.logout': return 'Abmelden';
			case 'discover.noContentAvailable': return 'Kein Inhalt verfügbar';
			case 'discover.addMediaToLibraries': return 'Medien zur Bibliothek hinzufügen';
			case 'discover.continueWatching': return 'Weiterschauen';
			case 'discover.recentlyAdded': return 'Kürzlich hinzugefügt';
			case 'discover.play': return 'Abspielen';
			case 'discover.resume': return 'Fortsetzen';
			case 'discover.playEpisode': return ({required Object season, required Object episode}) => 'Spiele S${season}, E${episode}';
			case 'discover.resumeEpisode': return ({required Object season, required Object episode}) => 'Fortsetzen S${season}, E${episode}';
			case 'discover.pause': return 'Pause';
			case 'discover.overview': return 'Übersicht';
			case 'discover.cast': return 'Besetzung';
			case 'discover.episodeCount': return ({required Object count}) => '${count} Episoden';
			case 'discover.watchedProgress': return ({required Object watched, required Object total}) => '${watched}/${total} gesehen';
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
			case 'errors.connectionFailedGeneric': return 'Verbindung fehlgeschlagen';
			case 'libraries.title': return 'Bibliotheken';
			case 'libraries.scanLibraryFiles': return 'Bibliotheksdateien scannen';
			case 'libraries.scanLibrary': return 'Bibliothek scannen';
			case 'libraries.analyze': return 'Analysieren';
			case 'libraries.analyzeLibrary': return 'Bibliothek analysieren';
			case 'libraries.refreshMetadata': return 'Metadaten aktualisieren';
			case 'libraries.emptyTrash': return 'Papierkorb leeren';
			case 'libraries.emptyingTrash': return ({required Object title}) => 'Papierkorb für „${title}“ wird geleert...';
			case 'libraries.trashEmptied': return ({required Object title}) => 'Papierkorb für „${title}“ geleert';
			case 'libraries.failedToEmptyTrash': return ({required Object error}) => 'Papierkorb konnte nicht geleert werden: ${error}';
			case 'libraries.analyzing': return ({required Object title}) => 'Analysiere „${title}“...';
			case 'libraries.analysisStarted': return ({required Object title}) => 'Analyse gestartet für „${title}“';
			case 'libraries.failedToAnalyze': return ({required Object error}) => 'Analyse der Bibliothek fehlgeschlagen: ${error}';
			case 'libraries.noLibrariesFound': return 'Keine Bibliotheken gefunden';
			case 'libraries.thisLibraryIsEmpty': return 'Diese Bibliothek ist leer';
			case 'libraries.all': return 'Alle';
			case 'libraries.clearAll': return 'Alle löschen';
			case 'libraries.scanLibraryConfirm': return ({required Object title}) => '„${title}“ wirklich scannen?';
			case 'libraries.analyzeLibraryConfirm': return ({required Object title}) => '„${title}“ wirklich analysieren?';
			case 'libraries.refreshMetadataConfirm': return ({required Object title}) => 'Metadaten für „${title}“ wirklich aktualisieren?';
			case 'libraries.emptyTrashConfirm': return ({required Object title}) => 'Papierkorb für „${title}“ wirklich leeren?';
			case 'libraries.manageLibraries': return 'Bibliotheken verwalten';
			case 'libraries.sort': return 'Sortieren';
			case 'libraries.sortBy': return 'Sortieren nach';
			case 'libraries.filters': return 'Filter';
			case 'libraries.loadingLibraryWithCount': return ({required Object count}) => 'Lade Bibliothek... (${count} Elemente geladen)';
			case 'libraries.confirmActionMessage': return 'Aktion wirklich durchführen?';
			case 'libraries.showLibrary': return 'Bibliothek anzeigen';
			case 'libraries.hideLibrary': return 'Bibliothek ausblenden';
			case 'libraries.libraryOptions': return 'Bibliotheksoptionen';
			case 'about.title': return 'Über';
			case 'about.openSourceLicenses': return 'Open-Source-Lizenzen';
			case 'about.versionLabel': return ({required Object version}) => 'Version ${version}';
			case 'about.appDescription': return 'Ein schöner Plex-Client für Flutter';
			case 'about.viewLicensesDescription': return 'Lizenzen von Drittanbieter-Bibliotheken anzeigen';
			case 'serverSelection.connectingToServer': return 'Verbinde mit Server...';
			case 'serverSelection.serverDebugCopied': return 'Server-Debugdaten kopiert';
			case 'serverSelection.copyDebugData': return 'Debugdaten kopieren';
			case 'serverSelection.noServersFound': return 'Keine Server gefunden';
			case 'serverSelection.malformedServerData': return ({required Object count}) => '${count} Server mit fehlerhaften Daten gefunden. Keine gültigen Server verfügbar.';
			case 'serverSelection.incompleteServerInfo': return 'Einige Serverinformationen sind unvollständig und wurden übersprungen. Plex.tv-Konto prüfen.';
			case 'serverSelection.incompleteConnectionInfo': return 'Serververbindungsinformationen unvollständig. Bitte erneut versuchen.';
			case 'serverSelection.malformedServerInfo': return ({required Object message}) => 'Serverinformationen fehlerhaft: ${message}';
			case 'serverSelection.networkConnectionFailed': return 'Netzwerkverbindung fehlgeschlagen. Internetverbindung prüfen und erneut versuchen.';
			case 'serverSelection.authenticationFailed': return 'Authentifizierung fehlgeschlagen. Bitte erneut anmelden.';
			case 'serverSelection.plexServiceUnavailable': return 'Plex-Dienst nicht verfügbar. Bitte später erneut versuchen.';
			case 'serverSelection.failedToLoadServers': return ({required Object error}) => 'Server konnten nicht geladen werden: ${error}';
			case 'hubDetail.title': return 'Titel';
			case 'hubDetail.releaseYear': return 'Erscheinungsjahr';
			case 'hubDetail.dateAdded': return 'Hinzugefügt am';
			case 'hubDetail.rating': return 'Bewertung';
			case 'hubDetail.noItemsFound': return 'Keine Elemente gefunden';
			case 'logs.title': return 'Protokolle';
			case 'logs.clearLogs': return 'Protokolle löschen';
			case 'logs.copyLogs': return 'Protokolle kopieren';
			case 'logs.exportLogs': return 'Protokolle exportieren';
			case 'logs.noLogsToShow': return 'Keine Protokolle zum Anzeigen';
			case 'logs.error': return 'Fehler:';
			case 'logs.stackTrace': return 'Stacktrace:';
			case 'licenses.relatedPackages': return 'Verwandte Pakete';
			case 'licenses.license': return 'Lizenz';
			case 'licenses.licenseNumber': return ({required Object number}) => 'Lizenz ${number}';
			case 'licenses.licensesCount': return ({required Object count}) => '${count} Lizenzen';
			case 'navigation.home': return 'Start';
			case 'navigation.search': return 'Suche';
			case 'navigation.libraries': return 'Bibliotheken';
			case 'navigation.settings': return 'Einstellungen';
			case 'playlists.title': return 'Playlists';
			case 'playlists.noPlaylists': return 'Keine Playlists gefunden';
			case 'playlists.create': return 'Playlist erstellen';
			case 'playlists.newPlaylist': return 'Neue Playlist';
			case 'playlists.playlistName': return 'Playlist-Name';
			case 'playlists.enterPlaylistName': return 'Playlist-Namen eingeben';
			case 'playlists.edit': return 'Playlist bearbeiten';
			case 'playlists.delete': return 'Playlist löschen';
			case 'playlists.addTo': return 'Zur Playlist hinzufügen';
			case 'playlists.addItems': return 'Elemente hinzufügen';
			case 'playlists.removeItem': return 'Aus Playlist entfernen';
			case 'playlists.clearPlaylist': return 'Playlist leeren';
			case 'playlists.playAll': return 'Alle abspielen';
			case 'playlists.shuffle': return 'Zufällig';
			case 'playlists.smartPlaylist': return 'Intelligente Playlist';
			case 'playlists.regularPlaylist': return 'Normale Playlist';
			case 'playlists.itemCount': return ({required Object count}) => '${count} Elemente';
			case 'playlists.oneItem': return '1 Element';
			case 'playlists.emptyPlaylist': return 'Diese Playlist ist leer';
			case 'playlists.deleteConfirm': return 'Playlist löschen?';
			case 'playlists.deleteMessage': return ({required Object name}) => 'Möchten Sie "${name}" wirklich löschen?';
			case 'playlists.created': return 'Playlist erstellt';
			case 'playlists.updated': return 'Playlist aktualisiert';
			case 'playlists.deleted': return 'Playlist gelöscht';
			case 'playlists.itemAdded': return 'Zur Playlist hinzugefügt';
			case 'playlists.itemRemoved': return 'Aus Playlist entfernt';
			case 'playlists.selectPlaylist': return 'Playlist auswählen';
			case 'playlists.createNewPlaylist': return 'Neue Playlist erstellen';
			case 'playlists.errorCreating': return 'Fehler beim Erstellen der Playlist';
			case 'playlists.errorDeleting': return 'Fehler beim Löschen der Playlist';
			case 'playlists.errorLoading': return 'Fehler beim Laden der Playlists';
			case 'playlists.errorAdding': return 'Fehler beim Hinzufügen zur Playlist';
			case 'playlists.errorReordering': return 'Fehler beim Neuordnen des Playlist-Elements';
			case 'playlists.errorRemoving': return 'Fehler beim Entfernen aus der Playlist';
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
			case 'common.playNow': return 'Riproduci ora';
			case 'common.logout': return 'Disconnetti';
			case 'common.online': return 'Online';
			case 'common.offline': return 'Offline';
			case 'common.owned': return 'Di proprietà';
			case 'common.shared': return 'Condiviso';
			case 'common.current': return 'CORRENTE';
			case 'common.unknown': return 'Sconosciuto';
			case 'common.refresh': return 'Aggiorna';
			case 'common.yes': return 'Sì';
			case 'common.no': return 'No';
			case 'common.server': return 'Server';
			case 'screens.licenses': return 'Licenze';
			case 'screens.selectServer': return 'Seleziona server';
			case 'screens.switchProfile': return 'Cambia profilo';
			case 'screens.subtitleStyling': return 'Stile sottotitoli';
			case 'screens.search': return 'Cerca';
			case 'screens.logs': return 'Logs';
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
			case 'settings.shufflePlay': return 'Riproduzione casuale';
			case 'settings.advanced': return 'Avanzate';
			case 'settings.useSeasonPostersDescription': return 'Mostra il poster della stagione invece del poster della serie per gli episodi';
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
			case 'settings.useSeasonPosters': return 'Usa poster delle stagioni';
			case 'settings.showHeroSection': return 'Mostra sezione principale';
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
			case 'settings.unwatchedOnly': return 'Solo non guardati';
			case 'settings.unwatchedOnlyDescription': return 'Includi solo gli episodi non guardati nella coda di riproduzione casuale';
			case 'settings.shuffleOrderNavigation': return 'Navigazione in ordine casuale';
			case 'settings.shuffleOrderNavigationDescription': return 'I pulsanti Avanti/Indietro seguono l\'ordine casuale';
			case 'settings.loopShuffleQueue': return 'Coda di riproduzione casuale in loop';
			case 'settings.loopShuffleQueueDescription': return 'Riavvia la coda quando raggiungi la fine';
			case 'settings.videoPlayerControls': return 'Controlli del lettore video';
			case 'settings.keyboardShortcuts': return 'Scorciatoie da tastiera';
			case 'settings.keyboardShortcutsDescription': return 'Personalizza le scorciatoie da tastiera';
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
			case 'videoControls.noOffset': return 'No offset';
			case 'videoControls.letterbox': return 'Letterbox';
			case 'videoControls.fillScreen': return 'Riempi schermo';
			case 'videoControls.stretch': return 'Allunga';
			case 'videoControls.lockRotation': return 'Blocca rotazione';
			case 'videoControls.unlockRotation': return 'Sblocca rotazione';
			case 'userStatus.admin': return 'Admin';
			case 'userStatus.restricted': return 'Limitato';
			case 'userStatus.protected': return 'Protetto';
			case 'messages.markedAsWatched': return 'Segna come visto';
			case 'messages.markedAsUnwatched': return 'Segna come non visto';
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
			case 'messages.noPlexToken': return 'Nessun token Plex trovato. Riesegui l\'accesso.';
			case 'messages.logoutConfirm': return 'Sei sicuro di volerti disconnettere?';
			case 'messages.noSeasonsFound': return 'Nessuna stagione trovata';
			case 'messages.noEpisodesFound': return 'Nessun episodio trovato nella prima stagione';
			case 'messages.noEpisodesFoundGeneral': return 'Nessun episodio trovato';
			case 'messages.noResultsFound': return 'Nessun risultato';
			case 'messages.sleepTimerSet': return ({required Object label}) => 'Imposta timer spegnimento per ${label}';
			case 'messages.failedToSwitchProfile': return ({required Object displayName}) => 'Impossibile passare a ${displayName}';
			case 'profile.noUsersAvailable': return 'Nessun utente disponibile';
			case 'subtitlingStyling.stylingOptions': return 'Opzioni stile';
			case 'subtitlingStyling.fontSize': return 'Dimensione';
			case 'subtitlingStyling.textColor': return 'Colore testo';
			case 'subtitlingStyling.borderSize': return 'Dimensione bordo';
			case 'subtitlingStyling.borderColor': return 'Colore bordo';
			case 'subtitlingStyling.backgroundOpacity': return 'Opacità sfondo';
			case 'subtitlingStyling.backgroundColor': return 'Colore sfondo';
			case 'dialog.confirmAction': return 'Conferma azione';
			case 'dialog.areYouSure': return 'Sei sicuro di voler eseguire questa azione?';
			case 'dialog.cancel': return 'Cancella';
			case 'dialog.playNow': return 'Riproduci ora';
			case 'discover.title': return 'Discover';
			case 'discover.switchProfile': return 'Cambia profilo';
			case 'discover.switchServer': return 'Cambia server';
			case 'discover.logout': return 'Disconnetti';
			case 'discover.noContentAvailable': return 'Nessun contenuto disponibile';
			case 'discover.addMediaToLibraries': return 'Aggiungi alcuni file multimediali alle tue librerie';
			case 'discover.continueWatching': return 'Continua a guardare';
			case 'discover.recentlyAdded': return 'Aggiunti di recente';
			case 'discover.play': return 'Riproduci';
			case 'discover.resume': return 'Riprendi';
			case 'discover.playEpisode': return ({required Object season, required Object episode}) => 'Riproduci S${season}, E${episode}';
			case 'discover.resumeEpisode': return ({required Object season, required Object episode}) => 'Riprendi S${season}, E${episode}';
			case 'discover.pause': return 'Pausa';
			case 'discover.overview': return 'Panoramica';
			case 'discover.cast': return 'Cast';
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
			case 'errors.connectionFailedGeneric': return 'Connessione fallita';
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
			case 'libraries.loadingLibraryWithCount': return ({required Object count}) => 'Caricamento librerie... (${count} oggetti caricati)';
			case 'libraries.confirmActionMessage': return 'Sei sicuro di voler eseguire questa azione?';
			case 'libraries.showLibrary': return 'Mostra libreria';
			case 'libraries.hideLibrary': return 'Nascondi libreria';
			case 'libraries.libraryOptions': return 'Opzioni libreria';
			case 'about.title': return 'Informazioni';
			case 'about.openSourceLicenses': return 'Licenze Open Source';
			case 'about.versionLabel': return ({required Object version}) => 'Versione ${version}';
			case 'about.appDescription': return 'Un bellissimo client Plex per Flutter';
			case 'about.viewLicensesDescription': return 'Visualizza le licenze delle librerie di terze parti';
			case 'serverSelection.connectingToServer': return 'Connessione al server...';
			case 'serverSelection.serverDebugCopied': return 'Dati di debug del server copiati negli appunti';
			case 'serverSelection.copyDebugData': return 'Copia dati di debug';
			case 'serverSelection.noServersFound': return 'Nessun server trovato';
			case 'serverSelection.malformedServerData': return ({required Object count}) => 'Trovato ${count} server con dati difettosi. Nessun server valido disponibile.';
			case 'serverSelection.incompleteServerInfo': return 'Alcuni server presentano informazioni incomplete e sono stati ignorati. Controlla il tuo account Plex.tv.';
			case 'serverSelection.incompleteConnectionInfo': return 'Le informazioni di connessione al server sono incomplete. Riprova.';
			case 'serverSelection.malformedServerInfo': return ({required Object message}) => 'Le informazioni sul server sono errate: ${message}';
			case 'serverSelection.networkConnectionFailed': return 'Connessione di rete non riuscita. Controlla la tua connessione Internet e riprova.';
			case 'serverSelection.authenticationFailed': return 'Autenticazione fallita. Effettua nuovamente l\'accesso.';
			case 'serverSelection.plexServiceUnavailable': return 'Servizio Plex non disponibile. Riprova più tardi.';
			case 'serverSelection.failedToLoadServers': return ({required Object error}) => 'Impossibile caricare i server: ${error}';
			case 'hubDetail.title': return 'Titolo';
			case 'hubDetail.releaseYear': return 'Anno rilascio';
			case 'hubDetail.dateAdded': return 'Data aggiunta';
			case 'hubDetail.rating': return 'Valutazione';
			case 'hubDetail.noItemsFound': return 'Nessun elemento trovato';
			case 'logs.title': return 'Log';
			case 'logs.clearLogs': return 'Cancella log';
			case 'logs.copyLogs': return 'Copia log';
			case 'logs.exportLogs': return 'Esporta log';
			case 'logs.noLogsToShow': return 'Nessun log da mostrare';
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
			case 'playlists.title': return 'Playlist';
			case 'playlists.noPlaylists': return 'Nessuna playlist trovata';
			case 'playlists.create': return 'Crea playlist';
			case 'playlists.newPlaylist': return 'Nuova playlist';
			case 'playlists.playlistName': return 'Nome playlist';
			case 'playlists.enterPlaylistName': return 'Inserisci nome playlist';
			case 'playlists.edit': return 'Modifica playlist';
			case 'playlists.delete': return 'Elimina playlist';
			case 'playlists.addTo': return 'Aggiungi a playlist';
			case 'playlists.addItems': return 'Aggiungi elementi';
			case 'playlists.removeItem': return 'Rimuovi da playlist';
			case 'playlists.clearPlaylist': return 'Svuota playlist';
			case 'playlists.playAll': return 'Riproduci tutto';
			case 'playlists.shuffle': return 'Casuale';
			case 'playlists.smartPlaylist': return 'Playlist intelligente';
			case 'playlists.regularPlaylist': return 'Playlist normale';
			case 'playlists.itemCount': return ({required Object count}) => '${count} elementi';
			case 'playlists.oneItem': return '1 elemento';
			case 'playlists.emptyPlaylist': return 'Questa playlist è vuota';
			case 'playlists.deleteConfirm': return 'Eliminare playlist?';
			case 'playlists.deleteMessage': return ({required Object name}) => 'Sei sicuro di voler eliminare "${name}"?';
			case 'playlists.created': return 'Playlist creata';
			case 'playlists.updated': return 'Playlist aggiornata';
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
			case 'auth.plexTokenLabel': return 'Plex Auth Token';
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
			case 'common.playNow': return 'Nu afspelen';
			case 'common.logout': return 'Uitloggen';
			case 'common.online': return 'Online';
			case 'common.offline': return 'Offline';
			case 'common.owned': return 'Eigendom';
			case 'common.shared': return 'Gedeeld';
			case 'common.current': return 'HUIDIG';
			case 'common.unknown': return 'Onbekend';
			case 'common.refresh': return 'Vernieuwen';
			case 'common.yes': return 'Ja';
			case 'common.no': return 'Nee';
			case 'common.server': return 'Server';
			case 'screens.licenses': return 'Licenties';
			case 'screens.selectServer': return 'Selecteer server';
			case 'screens.switchProfile': return 'Wissel van profiel';
			case 'screens.subtitleStyling': return 'Ondertitel opmaak';
			case 'screens.search': return 'Zoeken';
			case 'screens.logs': return 'Logs';
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
			case 'settings.shufflePlay': return 'Willekeurig afspelen';
			case 'settings.advanced': return 'Geavanceerd';
			case 'settings.useSeasonPostersDescription': return 'Toon seizoenposter in plaats van serieposter voor afleveringen';
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
			case 'settings.useSeasonPosters': return 'Gebruik seizoenposters';
			case 'settings.showHeroSection': return 'Toon hoofdsectie';
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
			case 'settings.unwatchedOnly': return 'Alleen ongekeken';
			case 'settings.unwatchedOnlyDescription': return 'Alleen ongekeken afleveringen opnemen in willekeurige wachtrij';
			case 'settings.shuffleOrderNavigation': return 'Willekeurige volgorde navigatie';
			case 'settings.shuffleOrderNavigationDescription': return 'Volgende/vorige knoppen volgen willekeurige volgorde';
			case 'settings.loopShuffleQueue': return 'Herhaal willekeurige wachtrij';
			case 'settings.loopShuffleQueueDescription': return 'Start wachtrij opnieuw bij het einde';
			case 'settings.videoPlayerControls': return 'Videospeler bediening';
			case 'settings.keyboardShortcuts': return 'Toetsenbord sneltoetsen';
			case 'settings.keyboardShortcutsDescription': return 'Pas toetsenbord sneltoetsen aan';
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
			case 'userStatus.admin': return 'Beheerder';
			case 'userStatus.restricted': return 'Beperkt';
			case 'userStatus.protected': return 'Beschermd';
			case 'messages.markedAsWatched': return 'Gemarkeerd als gekeken';
			case 'messages.markedAsUnwatched': return 'Gemarkeerd als ongekeken';
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
			case 'messages.noPlexToken': return 'Geen Plex token gevonden. Log opnieuw in.';
			case 'messages.logoutConfirm': return 'Weet je zeker dat je wilt uitloggen?';
			case 'messages.noSeasonsFound': return 'Geen seizoenen gevonden';
			case 'messages.noEpisodesFound': return 'Geen afleveringen gevonden in eerste seizoen';
			case 'messages.noEpisodesFoundGeneral': return 'Geen afleveringen gevonden';
			case 'messages.noResultsFound': return 'Geen resultaten gevonden';
			case 'messages.sleepTimerSet': return ({required Object label}) => 'Slaap timer ingesteld voor ${label}';
			case 'messages.failedToSwitchProfile': return ({required Object displayName}) => 'Kon niet wisselen naar ${displayName}';
			case 'profile.noUsersAvailable': return 'Geen gebruikers beschikbaar';
			case 'subtitlingStyling.stylingOptions': return 'Opmaak opties';
			case 'subtitlingStyling.fontSize': return 'Lettergrootte';
			case 'subtitlingStyling.textColor': return 'Tekstkleur';
			case 'subtitlingStyling.borderSize': return 'Rand grootte';
			case 'subtitlingStyling.borderColor': return 'Randkleur';
			case 'subtitlingStyling.backgroundOpacity': return 'Achtergrond transparantie';
			case 'subtitlingStyling.backgroundColor': return 'Achtergrondkleur';
			case 'dialog.confirmAction': return 'Bevestig actie';
			case 'dialog.areYouSure': return 'Weet je zeker dat je deze actie wilt uitvoeren?';
			case 'dialog.cancel': return 'Annuleren';
			case 'dialog.playNow': return 'Nu afspelen';
			case 'discover.title': return 'Ontdekken';
			case 'discover.switchProfile': return 'Wissel van profiel';
			case 'discover.switchServer': return 'Wissel van server';
			case 'discover.logout': return 'Uitloggen';
			case 'discover.noContentAvailable': return 'Geen inhoud beschikbaar';
			case 'discover.addMediaToLibraries': return 'Voeg wat media toe aan je bibliotheken';
			case 'discover.continueWatching': return 'Verder kijken';
			case 'discover.recentlyAdded': return 'Recent toegevoegd';
			case 'discover.play': return 'Afspelen';
			case 'discover.resume': return 'Hervatten';
			case 'discover.playEpisode': return ({required Object season, required Object episode}) => 'Speel S${season}, E${episode}';
			case 'discover.resumeEpisode': return ({required Object season, required Object episode}) => 'Hervat S${season}, E${episode}';
			case 'discover.pause': return 'Pauzeren';
			case 'discover.overview': return 'Overzicht';
			case 'discover.cast': return 'Cast';
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
			case 'errors.connectionFailedGeneric': return 'Verbinding mislukt';
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
			case 'libraries.loadingLibraryWithCount': return ({required Object count}) => 'Bibliotheek laden... (${count} items geladen)';
			case 'libraries.confirmActionMessage': return 'Weet je zeker dat je deze actie wilt uitvoeren?';
			case 'libraries.showLibrary': return 'Toon bibliotheek';
			case 'libraries.hideLibrary': return 'Verberg bibliotheek';
			case 'libraries.libraryOptions': return 'Bibliotheek opties';
			case 'about.title': return 'Over';
			case 'about.openSourceLicenses': return 'Open Source licenties';
			case 'about.versionLabel': return ({required Object version}) => 'Versie ${version}';
			case 'about.appDescription': return 'Een mooie Plex client voor Flutter';
			case 'about.viewLicensesDescription': return 'Bekijk licenties van third-party bibliotheken';
			case 'serverSelection.connectingToServer': return 'Verbinden met server...';
			case 'serverSelection.serverDebugCopied': return 'Server debug gegevens gekopieerd naar klembord';
			case 'serverSelection.copyDebugData': return 'Kopieer debug gegevens';
			case 'serverSelection.noServersFound': return 'Geen servers gevonden';
			case 'serverSelection.malformedServerData': return ({required Object count}) => '${count} server(s) gevonden met verkeerde data. Geen geldige servers beschikbaar.';
			case 'serverSelection.incompleteServerInfo': return 'Sommige servers hebben incomplete informatie en zijn overgeslagen. Controleer je Plex.tv account.';
			case 'serverSelection.incompleteConnectionInfo': return 'Server verbinding informatie is incompleet. Probeer opnieuw.';
			case 'serverSelection.malformedServerInfo': return ({required Object message}) => 'Server informatie is verkeerd geformatteerd: ${message}';
			case 'serverSelection.networkConnectionFailed': return 'Netwerkverbinding mislukt. Controleer je internetverbinding en probeer opnieuw.';
			case 'serverSelection.authenticationFailed': return 'Authenticatie mislukt. Log opnieuw in.';
			case 'serverSelection.plexServiceUnavailable': return 'Plex service niet beschikbaar. Probeer later opnieuw.';
			case 'serverSelection.failedToLoadServers': return ({required Object error}) => 'Kon servers niet laden: ${error}';
			case 'hubDetail.title': return 'Titel';
			case 'hubDetail.releaseYear': return 'Uitgavejaar';
			case 'hubDetail.dateAdded': return 'Datum toegevoegd';
			case 'hubDetail.rating': return 'Beoordeling';
			case 'hubDetail.noItemsFound': return 'Geen items gevonden';
			case 'logs.title': return 'Logs';
			case 'logs.clearLogs': return 'Wis logs';
			case 'logs.copyLogs': return 'Kopieer logs';
			case 'logs.exportLogs': return 'Exporteer logs';
			case 'logs.noLogsToShow': return 'Geen logs om te tonen';
			case 'logs.error': return 'Fout:';
			case 'logs.stackTrace': return 'Stack Trace:';
			case 'licenses.relatedPackages': return 'Gerelateerde pakketten';
			case 'licenses.license': return 'Licentie';
			case 'licenses.licenseNumber': return ({required Object number}) => 'Licentie ${number}';
			case 'licenses.licensesCount': return ({required Object count}) => '${count} licenties';
			case 'navigation.home': return 'Home';
			case 'navigation.search': return 'Zoeken';
			case 'navigation.libraries': return 'Bibliotheken';
			case 'navigation.settings': return 'Instellingen';
			case 'playlists.title': return 'Afspeellijsten';
			case 'playlists.noPlaylists': return 'Geen afspeellijsten gevonden';
			case 'playlists.create': return 'Afspeellijst maken';
			case 'playlists.newPlaylist': return 'Nieuwe afspeellijst';
			case 'playlists.playlistName': return 'Naam afspeellijst';
			case 'playlists.enterPlaylistName': return 'Voer naam afspeellijst in';
			case 'playlists.edit': return 'Afspeellijst bewerken';
			case 'playlists.delete': return 'Afspeellijst verwijderen';
			case 'playlists.addTo': return 'Toevoegen aan afspeellijst';
			case 'playlists.addItems': return 'Items toevoegen';
			case 'playlists.removeItem': return 'Verwijderen uit afspeellijst';
			case 'playlists.clearPlaylist': return 'Afspeellijst wissen';
			case 'playlists.playAll': return 'Alles afspelen';
			case 'playlists.shuffle': return 'Shuffle';
			case 'playlists.smartPlaylist': return 'Slimme afspeellijst';
			case 'playlists.regularPlaylist': return 'Normale afspeellijst';
			case 'playlists.itemCount': return ({required Object count}) => '${count} items';
			case 'playlists.oneItem': return '1 item';
			case 'playlists.emptyPlaylist': return 'Deze afspeellijst is leeg';
			case 'playlists.deleteConfirm': return 'Afspeellijst verwijderen?';
			case 'playlists.deleteMessage': return ({required Object name}) => 'Weet je zeker dat je "${name}" wilt verwijderen?';
			case 'playlists.created': return 'Afspeellijst gemaakt';
			case 'playlists.updated': return 'Afspeellijst bijgewerkt';
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
			case 'common.playNow': return 'Spela nu';
			case 'common.logout': return 'Logga ut';
			case 'common.online': return 'Online';
			case 'common.offline': return 'Offline';
			case 'common.owned': return 'Egen';
			case 'common.shared': return 'Delad';
			case 'common.current': return 'NUVARANDE';
			case 'common.unknown': return 'Okänd';
			case 'common.refresh': return 'Uppdatera';
			case 'common.yes': return 'Ja';
			case 'common.no': return 'Nej';
			case 'common.server': return 'Server';
			case 'screens.licenses': return 'Licenser';
			case 'screens.selectServer': return 'Välj server';
			case 'screens.switchProfile': return 'Byt profil';
			case 'screens.subtitleStyling': return 'Undertext-styling';
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
			case 'settings.shufflePlay': return 'Blanda uppspelning';
			case 'settings.advanced': return 'Avancerat';
			case 'settings.useSeasonPostersDescription': return 'Visa säsongsaffisch istället för serieaffisch för avsnitt';
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
			case 'settings.useSeasonPosters': return 'Använd säsongsaffischer';
			case 'settings.showHeroSection': return 'Visa hjältesektion';
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
			case 'settings.unwatchedOnly': return 'Endast osedda';
			case 'settings.unwatchedOnlyDescription': return 'Inkludera endast osedda avsnitt i blandningskön';
			case 'settings.shuffleOrderNavigation': return 'Blandningsordning-navigation';
			case 'settings.shuffleOrderNavigationDescription': return 'Nästa/föregående knappar följer blandad ordning';
			case 'settings.loopShuffleQueue': return 'Loopa blandningskö';
			case 'settings.loopShuffleQueueDescription': return 'Starta om kö när slutet nås';
			case 'settings.videoPlayerControls': return 'Videospelar-kontroller';
			case 'settings.keyboardShortcuts': return 'Tangentbordsgenvägar';
			case 'settings.keyboardShortcutsDescription': return 'Anpassa tangentbordsgenvägar';
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
			case 'userStatus.admin': return 'Admin';
			case 'userStatus.restricted': return 'Begränsad';
			case 'userStatus.protected': return 'Skyddad';
			case 'messages.markedAsWatched': return 'Markerad som sedd';
			case 'messages.markedAsUnwatched': return 'Markerad som osedd';
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
			case 'messages.noPlexToken': return 'Ingen Plex-token hittad. Vänligen logga in igen.';
			case 'messages.logoutConfirm': return 'Är du säker på att du vill logga ut?';
			case 'messages.noSeasonsFound': return 'Inga säsonger hittades';
			case 'messages.noEpisodesFound': return 'Inga avsnitt hittades i första säsongen';
			case 'messages.noEpisodesFoundGeneral': return 'Inga avsnitt hittades';
			case 'messages.noResultsFound': return 'Inga resultat hittades';
			case 'messages.sleepTimerSet': return ({required Object label}) => 'Sovtimer inställd för ${label}';
			case 'messages.failedToSwitchProfile': return ({required Object displayName}) => 'Misslyckades att byta till ${displayName}';
			case 'profile.noUsersAvailable': return 'Inga användare tillgängliga';
			case 'subtitlingStyling.stylingOptions': return 'Stilalternativ';
			case 'subtitlingStyling.fontSize': return 'Teckenstorlek';
			case 'subtitlingStyling.textColor': return 'Textfärg';
			case 'subtitlingStyling.borderSize': return 'Kantstorlek';
			case 'subtitlingStyling.borderColor': return 'Kantfärg';
			case 'subtitlingStyling.backgroundOpacity': return 'Bakgrundsopacitet';
			case 'subtitlingStyling.backgroundColor': return 'Bakgrundsfärg';
			case 'dialog.confirmAction': return 'Bekräfta åtgärd';
			case 'dialog.areYouSure': return 'Är du säker på att du vill utföra denna åtgärd?';
			case 'dialog.cancel': return 'Avbryt';
			case 'dialog.playNow': return 'Spela nu';
			case 'discover.title': return 'Upptäck';
			case 'discover.switchProfile': return 'Byt profil';
			case 'discover.switchServer': return 'Byt server';
			case 'discover.logout': return 'Logga ut';
			case 'discover.noContentAvailable': return 'Inget innehåll tillgängligt';
			case 'discover.addMediaToLibraries': return 'Lägg till media till dina bibliotek';
			case 'discover.continueWatching': return 'Fortsätt titta';
			case 'discover.recentlyAdded': return 'Nyligen tillagda';
			case 'discover.play': return 'Spela';
			case 'discover.resume': return 'Återuppta';
			case 'discover.playEpisode': return ({required Object season, required Object episode}) => 'Spela S${season}, E${episode}';
			case 'discover.resumeEpisode': return ({required Object season, required Object episode}) => 'Återuppta S${season}, E${episode}';
			case 'discover.pause': return 'Pausa';
			case 'discover.overview': return 'Översikt';
			case 'discover.cast': return 'Rollbesättning';
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
			case 'errors.connectionFailedGeneric': return 'Anslutning misslyckades';
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
			case 'libraries.loadingLibraryWithCount': return ({required Object count}) => 'Laddar bibliotek... (${count} objekt laddade)';
			case 'libraries.confirmActionMessage': return 'Är du säker på att du vill utföra denna åtgärd?';
			case 'libraries.showLibrary': return 'Visa bibliotek';
			case 'libraries.hideLibrary': return 'Dölj bibliotek';
			case 'libraries.libraryOptions': return 'Biblioteksalternativ';
			case 'about.title': return 'Om';
			case 'about.openSourceLicenses': return 'Öppen källkod-licenser';
			case 'about.versionLabel': return ({required Object version}) => 'Version ${version}';
			case 'about.appDescription': return 'En vacker Plex-klient för Flutter';
			case 'about.viewLicensesDescription': return 'Visa licenser för tredjepartsbibliotek';
			case 'serverSelection.connectingToServer': return 'Ansluter till server...';
			case 'serverSelection.serverDebugCopied': return 'Server-felsökningsdata kopierad till urklipp';
			case 'serverSelection.copyDebugData': return 'Kopiera felsökningsdata';
			case 'serverSelection.noServersFound': return 'Inga servrar hittades';
			case 'serverSelection.malformedServerData': return ({required Object count}) => 'Hittade ${count} server(ar) med felformaterad data. Inga giltiga servrar tillgängliga.';
			case 'serverSelection.incompleteServerInfo': return 'Vissa servrar har ofullständig information och hoppades över. Vänligen kontrollera ditt Plex.tv-konto.';
			case 'serverSelection.incompleteConnectionInfo': return 'Server-anslutningsinformation är ofullständig. Försök igen.';
			case 'serverSelection.malformedServerInfo': return ({required Object message}) => 'Serverinformation är felformaterad: ${message}';
			case 'serverSelection.networkConnectionFailed': return 'Nätverksanslutning misslyckades. Kontrollera din internetanslutning och försök igen.';
			case 'serverSelection.authenticationFailed': return 'Autentisering misslyckades. Logga in igen.';
			case 'serverSelection.plexServiceUnavailable': return 'Plex-tjänst otillgänglig. Försök igen senare.';
			case 'serverSelection.failedToLoadServers': return ({required Object error}) => 'Misslyckades att ladda servrar: ${error}';
			case 'hubDetail.title': return 'Titel';
			case 'hubDetail.releaseYear': return 'Utgivningsår';
			case 'hubDetail.dateAdded': return 'Datum tillagd';
			case 'hubDetail.rating': return 'Betyg';
			case 'hubDetail.noItemsFound': return 'Inga objekt hittades';
			case 'logs.title': return 'Loggar';
			case 'logs.clearLogs': return 'Rensa loggar';
			case 'logs.copyLogs': return 'Kopiera loggar';
			case 'logs.exportLogs': return 'Exportera loggar';
			case 'logs.noLogsToShow': return 'Inga loggar att visa';
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
			case 'playlists.title': return 'Spellistor';
			case 'playlists.noPlaylists': return 'Inga spellistor hittades';
			case 'playlists.create': return 'Skapa spellista';
			case 'playlists.newPlaylist': return 'Ny spellista';
			case 'playlists.playlistName': return 'Spellistans namn';
			case 'playlists.enterPlaylistName': return 'Ange spellistans namn';
			case 'playlists.edit': return 'Redigera spellista';
			case 'playlists.delete': return 'Ta bort spellista';
			case 'playlists.addTo': return 'Lägg till i spellista';
			case 'playlists.addItems': return 'Lägg till objekt';
			case 'playlists.removeItem': return 'Ta bort från spellista';
			case 'playlists.clearPlaylist': return 'Rensa spellista';
			case 'playlists.playAll': return 'Spela alla';
			case 'playlists.shuffle': return 'Blanda';
			case 'playlists.smartPlaylist': return 'Smart spellista';
			case 'playlists.regularPlaylist': return 'Vanlig spellista';
			case 'playlists.itemCount': return ({required Object count}) => '${count} objekt';
			case 'playlists.oneItem': return '1 objekt';
			case 'playlists.emptyPlaylist': return 'Denna spellista är tom';
			case 'playlists.deleteConfirm': return 'Ta bort spellista?';
			case 'playlists.deleteMessage': return ({required Object name}) => 'Är du säker på att du vill ta bort "${name}"?';
			case 'playlists.created': return 'Spellista skapad';
			case 'playlists.updated': return 'Spellista uppdaterad';
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
			case 'common.playNow': return '立即播放';
			case 'common.logout': return '登出';
			case 'common.online': return '在线';
			case 'common.offline': return '离线';
			case 'common.owned': return '拥有';
			case 'common.shared': return '共享';
			case 'common.current': return '当前';
			case 'common.unknown': return '未知';
			case 'common.refresh': return '刷新';
			case 'common.yes': return '是';
			case 'common.no': return '否';
			case 'common.server': return '服务器';
			case 'screens.licenses': return '许可证';
			case 'screens.selectServer': return '选择服务器';
			case 'screens.switchProfile': return '切换配置文件';
			case 'screens.subtitleStyling': return '字幕样式';
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
			case 'settings.shufflePlay': return '随机播放';
			case 'settings.advanced': return '高级';
			case 'settings.useSeasonPostersDescription': return '为剧集显示季海报而非剧集海报';
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
			case 'settings.useSeasonPosters': return '使用季海报';
			case 'settings.showHeroSection': return '显示主要精选区';
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
			case 'settings.unwatchedOnly': return '仅未观看';
			case 'settings.unwatchedOnlyDescription': return '随机队列中仅包含未观看的剧集';
			case 'settings.shuffleOrderNavigation': return '随机顺序导航';
			case 'settings.shuffleOrderNavigationDescription': return '下一集/上一集按钮遵循随机播放顺序';
			case 'settings.loopShuffleQueue': return '循环随机队列';
			case 'settings.loopShuffleQueueDescription': return '在队列结束时重新开始';
			case 'settings.videoPlayerControls': return '视频播放器控制';
			case 'settings.keyboardShortcuts': return '键盘快捷键';
			case 'settings.keyboardShortcutsDescription': return '自定义键盘快捷键';
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
			case 'userStatus.admin': return '管理员';
			case 'userStatus.restricted': return '受限';
			case 'userStatus.protected': return '受保护';
			case 'messages.markedAsWatched': return '已标记为已观看';
			case 'messages.markedAsUnwatched': return '已标记为未观看';
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
			case 'messages.noPlexToken': return '未找到 Plex 令牌。请重新登录。';
			case 'messages.logoutConfirm': return '你确定要登出吗？';
			case 'messages.noSeasonsFound': return '未找到季';
			case 'messages.noEpisodesFound': return '在第一季中未找到剧集';
			case 'messages.noEpisodesFoundGeneral': return '未找到剧集';
			case 'messages.noResultsFound': return '未找到结果';
			case 'messages.sleepTimerSet': return ({required Object label}) => '睡眠定时器已设置为 ${label}';
			case 'messages.failedToSwitchProfile': return ({required Object displayName}) => '无法切换到 ${displayName}';
			case 'profile.noUsersAvailable': return '没有可用用户';
			case 'subtitlingStyling.stylingOptions': return '样式选项';
			case 'subtitlingStyling.fontSize': return '字号';
			case 'subtitlingStyling.textColor': return '文本颜色';
			case 'subtitlingStyling.borderSize': return '边框大小';
			case 'subtitlingStyling.borderColor': return '边框颜色';
			case 'subtitlingStyling.backgroundOpacity': return '背景不透明度';
			case 'subtitlingStyling.backgroundColor': return '背景颜色';
			case 'dialog.confirmAction': return '确认操作';
			case 'dialog.areYouSure': return '确定要执行此操作吗？';
			case 'dialog.cancel': return '取消';
			case 'dialog.playNow': return '立即播放';
			case 'discover.title': return '发现';
			case 'discover.switchProfile': return '切换配置文件';
			case 'discover.switchServer': return '切换服务器';
			case 'discover.logout': return '登出';
			case 'discover.noContentAvailable': return '没有可用内容';
			case 'discover.addMediaToLibraries': return '请向你的媒体库添加一些媒体';
			case 'discover.continueWatching': return '继续观看';
			case 'discover.recentlyAdded': return '最近添加';
			case 'discover.play': return '播放';
			case 'discover.resume': return '继续';
			case 'discover.playEpisode': return ({required Object season, required Object episode}) => '播放 S${season}, E${episode}';
			case 'discover.resumeEpisode': return ({required Object season, required Object episode}) => '继续 S${season}, E${episode}';
			case 'discover.pause': return '暂停';
			case 'discover.overview': return '概述';
			case 'discover.cast': return '演员表';
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
			case 'errors.connectionFailedGeneric': return '连接失败';
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
			case 'libraries.loadingLibraryWithCount': return ({required Object count}) => '正在加载媒体库... (已加载 ${count} 个项目)';
			case 'libraries.confirmActionMessage': return '确定要执行此操作吗？';
			case 'libraries.showLibrary': return '显示媒体库';
			case 'libraries.hideLibrary': return '隐藏媒体库';
			case 'libraries.libraryOptions': return '媒体库选项';
			case 'about.title': return '关于';
			case 'about.openSourceLicenses': return '开源许可证';
			case 'about.versionLabel': return ({required Object version}) => '版本 ${version}';
			case 'about.appDescription': return '一款精美的 Flutter Plex 客户端';
			case 'about.viewLicensesDescription': return '查看第三方库的许可证';
			case 'serverSelection.connectingToServer': return '正在连接服务器...';
			case 'serverSelection.serverDebugCopied': return '服务器调试数据已复制到剪贴板';
			case 'serverSelection.copyDebugData': return '复制调试数据';
			case 'serverSelection.noServersFound': return '未找到服务器';
			case 'serverSelection.malformedServerData': return ({required Object count}) => '找到 ${count} 个数据格式错误的服务器。没有可用的有效服务器。';
			case 'serverSelection.incompleteServerInfo': return '某些服务器信息不完整，已被跳过。请检查你的 Plex.tv 账户。';
			case 'serverSelection.incompleteConnectionInfo': return '服务器连接信息不完整。请重试。';
			case 'serverSelection.malformedServerInfo': return ({required Object message}) => '服务器信息格式错误: ${message}';
			case 'serverSelection.networkConnectionFailed': return '网络连接失败。请检查你的网络连接并重试。';
			case 'serverSelection.authenticationFailed': return '验证失败。请重新登录。';
			case 'serverSelection.plexServiceUnavailable': return 'Plex 服务不可用。请稍后重试。';
			case 'serverSelection.failedToLoadServers': return ({required Object error}) => '无法加载服务器: ${error}';
			case 'hubDetail.title': return '标题';
			case 'hubDetail.releaseYear': return '发行年份';
			case 'hubDetail.dateAdded': return '添加日期';
			case 'hubDetail.rating': return '评分';
			case 'hubDetail.noItemsFound': return '未找到项目';
			case 'logs.title': return '日志';
			case 'logs.clearLogs': return '清除日志';
			case 'logs.copyLogs': return '复制日志';
			case 'logs.exportLogs': return '导出日志';
			case 'logs.noLogsToShow': return '没有可显示的日志';
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
			case 'playlists.title': return '播放列表';
			case 'playlists.noPlaylists': return '未找到播放列表';
			case 'playlists.create': return '创建播放列表';
			case 'playlists.newPlaylist': return '新播放列表';
			case 'playlists.playlistName': return '播放列表名称';
			case 'playlists.enterPlaylistName': return '输入播放列表名称';
			case 'playlists.edit': return '编辑播放列表';
			case 'playlists.delete': return '删除播放列表';
			case 'playlists.addTo': return '添加到播放列表';
			case 'playlists.addItems': return '添加项目';
			case 'playlists.removeItem': return '从播放列表中移除';
			case 'playlists.clearPlaylist': return '清空播放列表';
			case 'playlists.playAll': return '全部播放';
			case 'playlists.shuffle': return '随机播放';
			case 'playlists.smartPlaylist': return '智能播放列表';
			case 'playlists.regularPlaylist': return '普通播放列表';
			case 'playlists.itemCount': return ({required Object count}) => '${count} 个项目';
			case 'playlists.oneItem': return '1 个项目';
			case 'playlists.emptyPlaylist': return '此播放列表为空';
			case 'playlists.deleteConfirm': return '删除播放列表？';
			case 'playlists.deleteMessage': return ({required Object name}) => '确定要删除 "${name}" 吗？';
			case 'playlists.created': return '播放列表已创建';
			case 'playlists.updated': return '播放列表已更新';
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
			default: return null;
		}
	}
}
