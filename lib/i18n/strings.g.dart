/// Generated file. Do not edit.
///
/// Original: lib/i18n
/// To regenerate, run: `dart run slang`
///
/// Locales: 4
/// Strings: 1264 (316 per locale)
///
/// Built on 2025-11-14 at 21:16 UTC

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
	it(languageCode: 'it', build: _StringsIt.build),
	nl(languageCode: 'nl', build: _StringsNl.build),
	sv(languageCode: 'sv', build: _StringsSv.build);

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
			default: return null;
		}
	}
}
