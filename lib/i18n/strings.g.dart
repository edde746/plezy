/// Generated file. Do not edit.
///
/// Original: lib/i18n
/// To regenerate, run: `dart run slang`
///
/// Locales: 2
/// Strings: 618 (309 per locale)
///
/// Built on 2025-11-10 at 08:56 UTC

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
