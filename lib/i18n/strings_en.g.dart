///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
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

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final TranslationsAppEn app = TranslationsAppEn._(_root);
	late final TranslationsAuthEn auth = TranslationsAuthEn._(_root);
	late final TranslationsCommonEn common = TranslationsCommonEn._(_root);
	late final TranslationsScreensEn screens = TranslationsScreensEn._(_root);
	late final TranslationsUpdateEn update = TranslationsUpdateEn._(_root);
	late final TranslationsSettingsEn settings = TranslationsSettingsEn._(_root);
	late final TranslationsSearchEn search = TranslationsSearchEn._(_root);
	late final TranslationsHotkeysEn hotkeys = TranslationsHotkeysEn._(_root);
	late final TranslationsPinEntryEn pinEntry = TranslationsPinEntryEn._(_root);
	late final TranslationsFileInfoEn fileInfo = TranslationsFileInfoEn._(_root);
	late final TranslationsMediaMenuEn mediaMenu = TranslationsMediaMenuEn._(_root);
	late final TranslationsAccessibilityEn accessibility = TranslationsAccessibilityEn._(_root);
	late final TranslationsTooltipsEn tooltips = TranslationsTooltipsEn._(_root);
	late final TranslationsVideoControlsEn videoControls = TranslationsVideoControlsEn._(_root);
	late final TranslationsUserStatusEn userStatus = TranslationsUserStatusEn._(_root);
	late final TranslationsMessagesEn messages = TranslationsMessagesEn._(_root);
	late final TranslationsSubtitlingStylingEn subtitlingStyling = TranslationsSubtitlingStylingEn._(_root);
	late final TranslationsMpvConfigEn mpvConfig = TranslationsMpvConfigEn._(_root);
	late final TranslationsDialogEn dialog = TranslationsDialogEn._(_root);
	late final TranslationsDiscoverEn discover = TranslationsDiscoverEn._(_root);
	late final TranslationsErrorsEn errors = TranslationsErrorsEn._(_root);
	late final TranslationsLibrariesEn libraries = TranslationsLibrariesEn._(_root);
	late final TranslationsAboutEn about = TranslationsAboutEn._(_root);
	late final TranslationsServerSelectionEn serverSelection = TranslationsServerSelectionEn._(_root);
	late final TranslationsHubDetailEn hubDetail = TranslationsHubDetailEn._(_root);
	late final TranslationsLogsEn logs = TranslationsLogsEn._(_root);
	late final TranslationsLicensesEn licenses = TranslationsLicensesEn._(_root);
	late final TranslationsNavigationEn navigation = TranslationsNavigationEn._(_root);
	late final TranslationsLiveTvEn liveTv = TranslationsLiveTvEn._(_root);
	late final TranslationsCollectionsEn collections = TranslationsCollectionsEn._(_root);
	late final TranslationsPlaylistsEn playlists = TranslationsPlaylistsEn._(_root);
	late final TranslationsWatchTogetherEn watchTogether = TranslationsWatchTogetherEn._(_root);
	late final TranslationsDownloadsEn downloads = TranslationsDownloadsEn._(_root);
	late final TranslationsShadersEn shaders = TranslationsShadersEn._(_root);
	late final TranslationsCompanionRemoteEn companionRemote = TranslationsCompanionRemoteEn._(_root);
	late final TranslationsVideoSettingsEn videoSettings = TranslationsVideoSettingsEn._(_root);
	late final TranslationsExternalPlayerEn externalPlayer = TranslationsExternalPlayerEn._(_root);
	late final TranslationsMetadataEditEn metadataEdit = TranslationsMetadataEditEn._(_root);
}

// Path: app
class TranslationsAppEn {
	TranslationsAppEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Plezy'
	String get title => 'Plezy';
}

// Path: auth
class TranslationsAuthEn {
	TranslationsAuthEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Sign in with Plex'
	String get signInWithPlex => 'Sign in with Plex';

	/// en: 'Show QR Code'
	String get showQRCode => 'Show QR Code';

	/// en: 'Authenticate'
	String get authenticate => 'Authenticate';

	/// en: 'Debug: Enter Plex Token'
	String get debugEnterToken => 'Debug: Enter Plex Token';

	/// en: 'Plex Auth Token'
	String get plexTokenLabel => 'Plex Auth Token';

	/// en: 'Enter your Plex.tv token'
	String get plexTokenHint => 'Enter your Plex.tv token';

	/// en: 'Authentication timed out. Please try again.'
	String get authenticationTimeout => 'Authentication timed out. Please try again.';

	/// en: 'Scan this QR code to sign in'
	String get scanQRToSignIn => 'Scan this QR code to sign in';

	/// en: 'Waiting for authentication... Please complete sign-in in your browser.'
	String get waitingForAuth => 'Waiting for authentication...\nPlease complete sign-in in your browser.';

	/// en: 'Use browser'
	String get useBrowser => 'Use browser';
}

// Path: common
class TranslationsCommonEn {
	TranslationsCommonEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'Close'
	String get close => 'Close';

	/// en: 'Clear'
	String get clear => 'Clear';

	/// en: 'Reset'
	String get reset => 'Reset';

	/// en: 'Later'
	String get later => 'Later';

	/// en: 'Submit'
	String get submit => 'Submit';

	/// en: 'Confirm'
	String get confirm => 'Confirm';

	/// en: 'Retry'
	String get retry => 'Retry';

	/// en: 'Logout'
	String get logout => 'Logout';

	/// en: 'Unknown'
	String get unknown => 'Unknown';

	/// en: 'Refresh'
	String get refresh => 'Refresh';

	/// en: 'Yes'
	String get yes => 'Yes';

	/// en: 'No'
	String get no => 'No';

	/// en: 'Delete'
	String get delete => 'Delete';

	/// en: 'Shuffle'
	String get shuffle => 'Shuffle';

	/// en: 'Add to...'
	String get addTo => 'Add to...';

	/// en: 'Remove'
	String get remove => 'Remove';

	/// en: 'Paste'
	String get paste => 'Paste';

	/// en: 'Connect'
	String get connect => 'Connect';

	/// en: 'Disconnect'
	String get disconnect => 'Disconnect';

	/// en: 'Play'
	String get play => 'Play';

	/// en: 'Pause'
	String get pause => 'Pause';

	/// en: 'Resume'
	String get resume => 'Resume';

	/// en: 'Error'
	String get error => 'Error';

	/// en: 'Search'
	String get search => 'Search';

	/// en: 'Home'
	String get home => 'Home';

	/// en: 'Back'
	String get back => 'Back';

	/// en: 'Settings'
	String get settings => 'Settings';

	/// en: 'Mute'
	String get mute => 'Mute';

	/// en: 'OK'
	String get ok => 'OK';

	/// en: 'Loading...'
	String get loading => 'Loading...';

	/// en: 'Reconnect'
	String get reconnect => 'Reconnect';

	/// en: 'Exit app?'
	String get exitConfirmTitle => 'Exit app?';

	/// en: 'Are you sure you want to exit?'
	String get exitConfirmMessage => 'Are you sure you want to exit?';

	/// en: 'Don't ask again'
	String get dontAskAgain => 'Don\'t ask again';

	/// en: 'Exit'
	String get exit => 'Exit';

	/// en: 'View All'
	String get viewAll => 'View All';

	/// en: 'Checking network...'
	String get checkingNetwork => 'Checking network...';

	/// en: 'Refreshing servers...'
	String get refreshingServers => 'Refreshing servers...';

	/// en: 'Loading servers...'
	String get loadingServers => 'Loading servers...';

	/// en: 'Connecting to servers...'
	String get connectingToServers => 'Connecting to servers...';

	/// en: 'Starting offline mode...'
	String get startingOfflineMode => 'Starting offline mode...';
}

// Path: screens
class TranslationsScreensEn {
	TranslationsScreensEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Licenses'
	String get licenses => 'Licenses';

	/// en: 'Switch Profile'
	String get switchProfile => 'Switch Profile';

	/// en: 'Subtitle Styling'
	String get subtitleStyling => 'Subtitle Styling';

	/// en: 'MPV Configuration'
	String get mpvConfig => 'MPV Configuration';

	/// en: 'Logs'
	String get logs => 'Logs';
}

// Path: update
class TranslationsUpdateEn {
	TranslationsUpdateEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Update Available'
	String get available => 'Update Available';

	/// en: 'Version ${version} is available'
	String versionAvailable({required Object version}) => 'Version ${version} is available';

	/// en: 'Current: ${version}'
	String currentVersion({required Object version}) => 'Current: ${version}';

	/// en: 'Skip This Version'
	String get skipVersion => 'Skip This Version';

	/// en: 'View Release'
	String get viewRelease => 'View Release';

	/// en: 'You are on the latest version'
	String get latestVersion => 'You are on the latest version';

	/// en: 'Failed to check for updates'
	String get checkFailed => 'Failed to check for updates';
}

// Path: settings
class TranslationsSettingsEn {
	TranslationsSettingsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Settings'
	String get title => 'Settings';

	/// en: 'Language'
	String get language => 'Language';

	/// en: 'Theme'
	String get theme => 'Theme';

	/// en: 'Appearance'
	String get appearance => 'Appearance';

	/// en: 'Video Playback'
	String get videoPlayback => 'Video Playback';

	/// en: 'Advanced'
	String get advanced => 'Advanced';

	/// en: 'Episode Poster Style'
	String get episodePosterMode => 'Episode Poster Style';

	/// en: 'Series Poster'
	String get seriesPoster => 'Series Poster';

	/// en: 'Show the series poster for all episodes'
	String get seriesPosterDescription => 'Show the series poster for all episodes';

	/// en: 'Season Poster'
	String get seasonPoster => 'Season Poster';

	/// en: 'Show the season-specific poster for episodes'
	String get seasonPosterDescription => 'Show the season-specific poster for episodes';

	/// en: 'Episode Thumbnail'
	String get episodeThumbnail => 'Episode Thumbnail';

	/// en: 'Show 16:9 episode screenshot thumbnails'
	String get episodeThumbnailDescription => 'Show 16:9 episode screenshot thumbnails';

	/// en: 'Display featured content carousel on home screen'
	String get showHeroSectionDescription => 'Display featured content carousel on home screen';

	/// en: 'Seconds'
	String get secondsLabel => 'Seconds';

	/// en: 'Minutes'
	String get minutesLabel => 'Minutes';

	/// en: 's'
	String get secondsShort => 's';

	/// en: 'm'
	String get minutesShort => 'm';

	/// en: 'Enter duration (${min}-${max})'
	String durationHint({required Object min, required Object max}) => 'Enter duration (${min}-${max})';

	/// en: 'System'
	String get systemTheme => 'System';

	/// en: 'Follow system settings'
	String get systemThemeDescription => 'Follow system settings';

	/// en: 'Light'
	String get lightTheme => 'Light';

	/// en: 'Dark'
	String get darkTheme => 'Dark';

	/// en: 'OLED'
	String get oledTheme => 'OLED';

	/// en: 'Pure black for OLED screens'
	String get oledThemeDescription => 'Pure black for OLED screens';

	/// en: 'Library Density'
	String get libraryDensity => 'Library Density';

	/// en: 'Compact'
	String get compact => 'Compact';

	/// en: 'Smaller cards, more items visible'
	String get compactDescription => 'Smaller cards, more items visible';

	/// en: 'Normal'
	String get normal => 'Normal';

	/// en: 'Default size'
	String get normalDescription => 'Default size';

	/// en: 'Comfortable'
	String get comfortable => 'Comfortable';

	/// en: 'Larger cards, fewer items visible'
	String get comfortableDescription => 'Larger cards, fewer items visible';

	/// en: 'View Mode'
	String get viewMode => 'View Mode';

	/// en: 'Grid'
	String get gridView => 'Grid';

	/// en: 'Display items in a grid layout'
	String get gridViewDescription => 'Display items in a grid layout';

	/// en: 'List'
	String get listView => 'List';

	/// en: 'Display items in a list layout'
	String get listViewDescription => 'Display items in a list layout';

	/// en: 'Show Hero Section'
	String get showHeroSection => 'Show Hero Section';

	/// en: 'Use Plex Home Layout'
	String get useGlobalHubs => 'Use Plex Home Layout';

	/// en: 'Show home page hubs like the official Plex client. When off, shows per-library recommendations instead.'
	String get useGlobalHubsDescription => 'Show home page hubs like the official Plex client. When off, shows per-library recommendations instead.';

	/// en: 'Show Server Name on Hubs'
	String get showServerNameOnHubs => 'Show Server Name on Hubs';

	/// en: 'Always display the server name in hub titles. When off, only shows for duplicate hub names.'
	String get showServerNameOnHubsDescription => 'Always display the server name in hub titles. When off, only shows for duplicate hub names.';

	/// en: 'Always Keep Sidebar Open'
	String get alwaysKeepSidebarOpen => 'Always Keep Sidebar Open';

	/// en: 'Sidebar stays expanded and content area adjusts to fit'
	String get alwaysKeepSidebarOpenDescription => 'Sidebar stays expanded and content area adjusts to fit';

	/// en: 'Show Unwatched Count'
	String get showUnwatchedCount => 'Show Unwatched Count';

	/// en: 'Display unwatched episode count on shows and seasons'
	String get showUnwatchedCountDescription => 'Display unwatched episode count on shows and seasons';

	/// en: 'Hide Spoilers for Unwatched Episodes'
	String get hideSpoilers => 'Hide Spoilers for Unwatched Episodes';

	/// en: 'Blur thumbnails and hide descriptions for episodes you haven\'t watched yet'
	String get hideSpoilersDescription => 'Blur thumbnails and hide descriptions for episodes you haven\'t watched yet';

	/// en: 'Player Backend'
	String get playerBackend => 'Player Backend';

	/// en: 'ExoPlayer (Recommended)'
	String get exoPlayer => 'ExoPlayer (Recommended)';

	/// en: 'Android native player with better hardware support'
	String get exoPlayerDescription => 'Android native player with better hardware support';

	/// en: 'MPV'
	String get mpv => 'MPV';

	/// en: 'Advanced player with more features and ASS subtitle support'
	String get mpvDescription => 'Advanced player with more features and ASS subtitle support';

	/// en: 'Hardware Decoding'
	String get hardwareDecoding => 'Hardware Decoding';

	/// en: 'Use hardware acceleration when available'
	String get hardwareDecodingDescription => 'Use hardware acceleration when available';

	/// en: 'Buffer Size'
	String get bufferSize => 'Buffer Size';

	/// en: '${size}MB'
	String bufferSizeMB({required Object size}) => '${size}MB';

	/// en: 'Auto (Recommended)'
	String get bufferSizeAuto => 'Auto (Recommended)';

	/// en: 'Your device has ${heap}MB of memory. A ${size}MB buffer may cause playback issues.'
	String bufferSizeWarning({required Object heap, required Object size}) => 'Your device has ${heap}MB of memory. A ${size}MB buffer may cause playback issues.';

	/// en: 'Subtitle Styling'
	String get subtitleStyling => 'Subtitle Styling';

	/// en: 'Customize subtitle appearance'
	String get subtitleStylingDescription => 'Customize subtitle appearance';

	/// en: 'Small Skip Duration'
	String get smallSkipDuration => 'Small Skip Duration';

	/// en: 'Large Skip Duration'
	String get largeSkipDuration => 'Large Skip Duration';

	/// en: '${seconds} seconds'
	String secondsUnit({required Object seconds}) => '${seconds} seconds';

	/// en: 'Default Sleep Timer'
	String get defaultSleepTimer => 'Default Sleep Timer';

	/// en: '${minutes} minutes'
	String minutesUnit({required Object minutes}) => '${minutes} minutes';

	/// en: 'Remember track selections per show/movie'
	String get rememberTrackSelections => 'Remember track selections per show/movie';

	/// en: 'Automatically save audio and subtitle language preferences when you change tracks during playback'
	String get rememberTrackSelectionsDescription => 'Automatically save audio and subtitle language preferences when you change tracks during playback';

	/// en: 'Click on video to toggle play/pause'
	String get clickVideoTogglesPlayback => 'Click on video to toggle play/pause';

	/// en: 'If enabled, clicking on the video player will play/pause the video. Otherwise, clicking will show/hide the playback controls.'
	String get clickVideoTogglesPlaybackDescription => 'If enabled, clicking on the video player will play/pause the video. Otherwise, clicking will show/hide the playback controls.';

	/// en: 'Video Player Controls'
	String get videoPlayerControls => 'Video Player Controls';

	/// en: 'Keyboard Shortcuts'
	String get keyboardShortcuts => 'Keyboard Shortcuts';

	/// en: 'Customize keyboard shortcuts'
	String get keyboardShortcutsDescription => 'Customize keyboard shortcuts';

	/// en: 'Video Player Navigation'
	String get videoPlayerNavigation => 'Video Player Navigation';

	/// en: 'Use arrow keys to navigate video player controls'
	String get videoPlayerNavigationDescription => 'Use arrow keys to navigate video player controls';

	/// en: 'Debug Logging'
	String get debugLogging => 'Debug Logging';

	/// en: 'Enable detailed logging for troubleshooting'
	String get debugLoggingDescription => 'Enable detailed logging for troubleshooting';

	/// en: 'View Logs'
	String get viewLogs => 'View Logs';

	/// en: 'View application logs'
	String get viewLogsDescription => 'View application logs';

	/// en: 'Clear Cache'
	String get clearCache => 'Clear Cache';

	/// en: 'This will clear all cached images and data. The app may take longer to load content after clearing the cache.'
	String get clearCacheDescription => 'This will clear all cached images and data. The app may take longer to load content after clearing the cache.';

	/// en: 'Cache cleared successfully'
	String get clearCacheSuccess => 'Cache cleared successfully';

	/// en: 'Reset Settings'
	String get resetSettings => 'Reset Settings';

	/// en: 'This will reset all settings to their default values. This action cannot be undone.'
	String get resetSettingsDescription => 'This will reset all settings to their default values. This action cannot be undone.';

	/// en: 'Settings reset successfully'
	String get resetSettingsSuccess => 'Settings reset successfully';

	/// en: 'Shortcuts reset to defaults'
	String get shortcutsReset => 'Shortcuts reset to defaults';

	/// en: 'About'
	String get about => 'About';

	/// en: 'App information and licenses'
	String get aboutDescription => 'App information and licenses';

	/// en: 'Updates'
	String get updates => 'Updates';

	/// en: 'Update Available'
	String get updateAvailable => 'Update Available';

	/// en: 'Check for Updates'
	String get checkForUpdates => 'Check for Updates';

	/// en: 'Please enter a valid number'
	String get validationErrorEnterNumber => 'Please enter a valid number';

	/// en: 'Duration must be between ${min} and ${max} ${unit}'
	String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Duration must be between ${min} and ${max} ${unit}';

	/// en: 'Shortcut already assigned to ${action}'
	String shortcutAlreadyAssigned({required Object action}) => 'Shortcut already assigned to ${action}';

	/// en: 'Shortcut updated for ${action}'
	String shortcutUpdated({required Object action}) => 'Shortcut updated for ${action}';

	/// en: 'Auto Skip'
	String get autoSkip => 'Auto Skip';

	/// en: 'Auto Skip Intro'
	String get autoSkipIntro => 'Auto Skip Intro';

	/// en: 'Automatically skip intro markers after a few seconds'
	String get autoSkipIntroDescription => 'Automatically skip intro markers after a few seconds';

	/// en: 'Auto Skip Credits'
	String get autoSkipCredits => 'Auto Skip Credits';

	/// en: 'Automatically skip credits and play next episode'
	String get autoSkipCreditsDescription => 'Automatically skip credits and play next episode';

	/// en: 'Auto Skip Delay'
	String get autoSkipDelay => 'Auto Skip Delay';

	/// en: 'Wait ${seconds} seconds before auto-skipping'
	String autoSkipDelayDescription({required Object seconds}) => 'Wait ${seconds} seconds before auto-skipping';

	/// en: 'Downloads'
	String get downloads => 'Downloads';

	/// en: 'Choose where to store downloaded content'
	String get downloadLocationDescription => 'Choose where to store downloaded content';

	/// en: 'Default (App Storage)'
	String get downloadLocationDefault => 'Default (App Storage)';

	/// en: 'Custom Location'
	String get downloadLocationCustom => 'Custom Location';

	/// en: 'Select Folder'
	String get selectFolder => 'Select Folder';

	/// en: 'Reset to Default'
	String get resetToDefault => 'Reset to Default';

	/// en: 'Current: ${path}'
	String currentPath({required Object path}) => 'Current: ${path}';

	/// en: 'Download location changed'
	String get downloadLocationChanged => 'Download location changed';

	/// en: 'Download location reset to default'
	String get downloadLocationReset => 'Download location reset to default';

	/// en: 'Selected folder is not writable'
	String get downloadLocationInvalid => 'Selected folder is not writable';

	/// en: 'Failed to select folder'
	String get downloadLocationSelectError => 'Failed to select folder';

	/// en: 'Download on WiFi only'
	String get downloadOnWifiOnly => 'Download on WiFi only';

	/// en: 'Prevent downloads when on cellular data'
	String get downloadOnWifiOnlyDescription => 'Prevent downloads when on cellular data';

	/// en: 'Downloads are disabled on cellular data. Connect to WiFi or change the setting.'
	String get cellularDownloadBlocked => 'Downloads are disabled on cellular data. Connect to WiFi or change the setting.';

	/// en: 'Maximum Volume'
	String get maxVolume => 'Maximum Volume';

	/// en: 'Allow volume boost above 100% for quiet media'
	String get maxVolumeDescription => 'Allow volume boost above 100% for quiet media';

	/// en: '${percent}%'
	String maxVolumePercent({required Object percent}) => '${percent}%';

	/// en: 'Discord Rich Presence'
	String get discordRichPresence => 'Discord Rich Presence';

	/// en: 'Show what you're watching on Discord'
	String get discordRichPresenceDescription => 'Show what you\'re watching on Discord';

	/// en: 'Auto Picture-in-Picture'
	String get autoPip => 'Auto Picture-in-Picture';

	/// en: 'Automatically enter picture-in-picture when leaving the app during playback'
	String get autoPipDescription => 'Automatically enter picture-in-picture when leaving the app during playback';

	/// en: 'Match Content Frame Rate'
	String get matchContentFrameRate => 'Match Content Frame Rate';

	/// en: 'Adjust display refresh rate to match video content, reducing judder and saving battery'
	String get matchContentFrameRateDescription => 'Adjust display refresh rate to match video content, reducing judder and saving battery';

	/// en: 'Tunneled Playback'
	String get tunneledPlayback => 'Tunneled Playback';

	/// en: 'Use hardware-accelerated video tunneling. Disable if you see a black screen with audio on HDR content'
	String get tunneledPlaybackDescription => 'Use hardware-accelerated video tunneling. Disable if you see a black screen with audio on HDR content';

	/// en: 'Ask for profile on app open'
	String get requireProfileSelectionOnOpen => 'Ask for profile on app open';

	/// en: 'Show profile selection every time the app is opened'
	String get requireProfileSelectionOnOpenDescription => 'Show profile selection every time the app is opened';

	/// en: 'Confirm before exiting'
	String get confirmExitOnBack => 'Confirm before exiting';

	/// en: 'Show a confirmation dialog when pressing back to exit the app'
	String get confirmExitOnBackDescription => 'Show a confirmation dialog when pressing back to exit the app';
}

// Path: search
class TranslationsSearchEn {
	TranslationsSearchEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Search movies, shows, music...'
	String get hint => 'Search movies, shows, music...';

	/// en: 'Try a different search term'
	String get tryDifferentTerm => 'Try a different search term';

	/// en: 'Search your media'
	String get searchYourMedia => 'Search your media';

	/// en: 'Enter a title, actor, or keyword'
	String get enterTitleActorOrKeyword => 'Enter a title, actor, or keyword';
}

// Path: hotkeys
class TranslationsHotkeysEn {
	TranslationsHotkeysEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Set Shortcut for ${actionName}'
	String setShortcutFor({required Object actionName}) => 'Set Shortcut for ${actionName}';

	/// en: 'Clear shortcut'
	String get clearShortcut => 'Clear shortcut';

	late final TranslationsHotkeysActionsEn actions = TranslationsHotkeysActionsEn._(_root);
}

// Path: pinEntry
class TranslationsPinEntryEn {
	TranslationsPinEntryEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Enter PIN'
	String get enterPin => 'Enter PIN';

	/// en: 'Show PIN'
	String get showPin => 'Show PIN';

	/// en: 'Hide PIN'
	String get hidePin => 'Hide PIN';
}

// Path: fileInfo
class TranslationsFileInfoEn {
	TranslationsFileInfoEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'File Info'
	String get title => 'File Info';

	/// en: 'Video'
	String get video => 'Video';

	/// en: 'Audio'
	String get audio => 'Audio';

	/// en: 'File'
	String get file => 'File';

	/// en: 'Advanced'
	String get advanced => 'Advanced';

	/// en: 'Codec'
	String get codec => 'Codec';

	/// en: 'Resolution'
	String get resolution => 'Resolution';

	/// en: 'Bitrate'
	String get bitrate => 'Bitrate';

	/// en: 'Frame Rate'
	String get frameRate => 'Frame Rate';

	/// en: 'Aspect Ratio'
	String get aspectRatio => 'Aspect Ratio';

	/// en: 'Profile'
	String get profile => 'Profile';

	/// en: 'Bit Depth'
	String get bitDepth => 'Bit Depth';

	/// en: 'Color Space'
	String get colorSpace => 'Color Space';

	/// en: 'Color Range'
	String get colorRange => 'Color Range';

	/// en: 'Color Primaries'
	String get colorPrimaries => 'Color Primaries';

	/// en: 'Chroma Subsampling'
	String get chromaSubsampling => 'Chroma Subsampling';

	/// en: 'Channels'
	String get channels => 'Channels';

	/// en: 'Path'
	String get path => 'Path';

	/// en: 'Size'
	String get size => 'Size';

	/// en: 'Container'
	String get container => 'Container';

	/// en: 'Duration'
	String get duration => 'Duration';

	/// en: 'Optimized for Streaming'
	String get optimizedForStreaming => 'Optimized for Streaming';

	/// en: '64-bit Offsets'
	String get has64bitOffsets => '64-bit Offsets';
}

// Path: mediaMenu
class TranslationsMediaMenuEn {
	TranslationsMediaMenuEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Mark as Watched'
	String get markAsWatched => 'Mark as Watched';

	/// en: 'Mark as Unwatched'
	String get markAsUnwatched => 'Mark as Unwatched';

	/// en: 'Remove from Continue Watching'
	String get removeFromContinueWatching => 'Remove from Continue Watching';

	/// en: 'Go to series'
	String get goToSeries => 'Go to series';

	/// en: 'Go to season'
	String get goToSeason => 'Go to season';

	/// en: 'Shuffle Play'
	String get shufflePlay => 'Shuffle Play';

	/// en: 'File Info'
	String get fileInfo => 'File Info';

	/// en: 'Delete from server'
	String get deleteFromServer => 'Delete from server';

	/// en: 'This will permanently delete this media and its files from your server. This cannot be undone.'
	String get confirmDelete => 'This will permanently delete this media and its files from your server. This cannot be undone.';

	/// en: 'This includes all episodes and their files.'
	String get deleteMultipleWarning => 'This includes all episodes and their files.';

	/// en: 'Media item deleted successfully'
	String get mediaDeletedSuccessfully => 'Media item deleted successfully';

	/// en: 'Failed to delete media item'
	String get mediaFailedToDelete => 'Failed to delete media item';

	/// en: 'Rate'
	String get rate => 'Rate';
}

// Path: accessibility
class TranslationsAccessibilityEn {
	TranslationsAccessibilityEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: '${title}, movie'
	String mediaCardMovie({required Object title}) => '${title}, movie';

	/// en: '${title}, TV show'
	String mediaCardShow({required Object title}) => '${title}, TV show';

	/// en: '${title}, ${episodeInfo}'
	String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';

	/// en: '${title}, ${seasonInfo}'
	String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';

	/// en: 'watched'
	String get mediaCardWatched => 'watched';

	/// en: '${percent} percent watched'
	String mediaCardPartiallyWatched({required Object percent}) => '${percent} percent watched';

	/// en: 'unwatched'
	String get mediaCardUnwatched => 'unwatched';

	/// en: 'Tap to play'
	String get tapToPlay => 'Tap to play';
}

// Path: tooltips
class TranslationsTooltipsEn {
	TranslationsTooltipsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Shuffle play'
	String get shufflePlay => 'Shuffle play';

	/// en: 'Play trailer'
	String get playTrailer => 'Play trailer';

	/// en: 'Mark as watched'
	String get markAsWatched => 'Mark as watched';

	/// en: 'Mark as unwatched'
	String get markAsUnwatched => 'Mark as unwatched';
}

// Path: videoControls
class TranslationsVideoControlsEn {
	TranslationsVideoControlsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Audio'
	String get audioLabel => 'Audio';

	/// en: 'Subtitles'
	String get subtitlesLabel => 'Subtitles';

	/// en: 'Reset to 0ms'
	String get resetToZero => 'Reset to 0ms';

	/// en: '+${amount}${unit}'
	String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';

	/// en: '-${amount}${unit}'
	String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';

	/// en: '${label} plays later'
	String playsLater({required Object label}) => '${label} plays later';

	/// en: '${label} plays earlier'
	String playsEarlier({required Object label}) => '${label} plays earlier';

	/// en: 'No offset'
	String get noOffset => 'No offset';

	/// en: 'Letterbox'
	String get letterbox => 'Letterbox';

	/// en: 'Fill screen'
	String get fillScreen => 'Fill screen';

	/// en: 'Stretch'
	String get stretch => 'Stretch';

	/// en: 'Lock rotation'
	String get lockRotation => 'Lock rotation';

	/// en: 'Unlock rotation'
	String get unlockRotation => 'Unlock rotation';

	/// en: 'Timer Active'
	String get timerActive => 'Timer Active';

	/// en: 'Playback will pause in ${duration}'
	String playbackWillPauseIn({required Object duration}) => 'Playback will pause in ${duration}';

	/// en: 'Sleep timer completed - playback paused'
	String get sleepTimerCompleted => 'Sleep timer completed - playback paused';

	/// en: 'Still watching?'
	String get stillWatching => 'Still watching?';

	/// en: 'Pausing in ${seconds}s'
	String pausingIn({required Object seconds}) => 'Pausing in ${seconds}s';

	/// en: 'Continue'
	String get continueWatching => 'Continue';

	/// en: 'Auto-Play Next'
	String get autoPlayNext => 'Auto-Play Next';

	/// en: 'Play Next'
	String get playNext => 'Play Next';

	/// en: 'Play'
	String get playButton => 'Play';

	/// en: 'Pause'
	String get pauseButton => 'Pause';

	/// en: 'Seek backward ${seconds} seconds'
	String seekBackwardButton({required Object seconds}) => 'Seek backward ${seconds} seconds';

	/// en: 'Seek forward ${seconds} seconds'
	String seekForwardButton({required Object seconds}) => 'Seek forward ${seconds} seconds';

	/// en: 'Previous episode'
	String get previousButton => 'Previous episode';

	/// en: 'Next episode'
	String get nextButton => 'Next episode';

	/// en: 'Previous chapter'
	String get previousChapterButton => 'Previous chapter';

	/// en: 'Next chapter'
	String get nextChapterButton => 'Next chapter';

	/// en: 'Mute'
	String get muteButton => 'Mute';

	/// en: 'Unmute'
	String get unmuteButton => 'Unmute';

	/// en: 'Video settings'
	String get settingsButton => 'Video settings';

	/// en: 'Audio tracks'
	String get audioTrackButton => 'Audio tracks';

	/// en: 'Subtitles'
	String get subtitlesButton => 'Subtitles';

	/// en: 'Chapters'
	String get chaptersButton => 'Chapters';

	/// en: 'Video versions'
	String get versionsButton => 'Video versions';

	/// en: 'Picture-in-Picture mode'
	String get pipButton => 'Picture-in-Picture mode';

	/// en: 'Aspect ratio'
	String get aspectRatioButton => 'Aspect ratio';

	/// en: 'Ambient lighting'
	String get ambientLighting => 'Ambient lighting';

	/// en: 'Enable ambient lighting'
	String get ambientLightingOn => 'Enable ambient lighting';

	/// en: 'Disable ambient lighting'
	String get ambientLightingOff => 'Disable ambient lighting';

	/// en: 'Enter fullscreen'
	String get fullscreenButton => 'Enter fullscreen';

	/// en: 'Exit fullscreen'
	String get exitFullscreenButton => 'Exit fullscreen';

	/// en: 'Always on top'
	String get alwaysOnTopButton => 'Always on top';

	/// en: 'Rotation lock'
	String get rotationLockButton => 'Rotation lock';

	/// en: 'Video timeline'
	String get timelineSlider => 'Video timeline';

	/// en: 'Volume level'
	String get volumeSlider => 'Volume level';

	/// en: 'Ends at ${time}'
	String endsAt({required Object time}) => 'Ends at ${time}';

	/// en: 'Picture-in-picture failed to start'
	String get pipFailed => 'Picture-in-picture failed to start';

	late final TranslationsVideoControlsPipErrorsEn pipErrors = TranslationsVideoControlsPipErrorsEn._(_root);

	/// en: 'Chapters'
	String get chapters => 'Chapters';

	/// en: 'No chapters available'
	String get noChaptersAvailable => 'No chapters available';

	/// en: 'Queue'
	String get queue => 'Queue';

	/// en: 'No items in queue'
	String get noQueueItems => 'No items in queue';
}

// Path: userStatus
class TranslationsUserStatusEn {
	TranslationsUserStatusEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Admin'
	String get admin => 'Admin';

	/// en: 'Restricted'
	String get restricted => 'Restricted';

	/// en: 'Protected'
	String get protected => 'Protected';

	/// en: 'CURRENT'
	String get current => 'CURRENT';
}

// Path: messages
class TranslationsMessagesEn {
	TranslationsMessagesEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Marked as watched'
	String get markedAsWatched => 'Marked as watched';

	/// en: 'Marked as unwatched'
	String get markedAsUnwatched => 'Marked as unwatched';

	/// en: 'Marked as watched (will sync when online)'
	String get markedAsWatchedOffline => 'Marked as watched (will sync when online)';

	/// en: 'Marked as unwatched (will sync when online)'
	String get markedAsUnwatchedOffline => 'Marked as unwatched (will sync when online)';

	/// en: 'Removed from Continue Watching'
	String get removedFromContinueWatching => 'Removed from Continue Watching';

	/// en: 'Error: ${error}'
	String errorLoading({required Object error}) => 'Error: ${error}';

	/// en: 'File information not available'
	String get fileInfoNotAvailable => 'File information not available';

	/// en: 'Error loading file info: ${error}'
	String errorLoadingFileInfo({required Object error}) => 'Error loading file info: ${error}';

	/// en: 'Error loading series'
	String get errorLoadingSeries => 'Error loading series';

	/// en: 'Error loading season'
	String get errorLoadingSeason => 'Error loading season';

	/// en: 'Music playback is not yet supported'
	String get musicNotSupported => 'Music playback is not yet supported';

	/// en: 'Logs cleared'
	String get logsCleared => 'Logs cleared';

	/// en: 'Logs copied to clipboard'
	String get logsCopied => 'Logs copied to clipboard';

	/// en: 'No logs available'
	String get noLogsAvailable => 'No logs available';

	/// en: 'Scanning "${title}"...'
	String libraryScanning({required Object title}) => 'Scanning "${title}"...';

	/// en: 'Library scan started for "${title}"'
	String libraryScanStarted({required Object title}) => 'Library scan started for "${title}"';

	/// en: 'Failed to scan library: ${error}'
	String libraryScanFailed({required Object error}) => 'Failed to scan library: ${error}';

	/// en: 'Refreshing metadata for "${title}"...'
	String metadataRefreshing({required Object title}) => 'Refreshing metadata for "${title}"...';

	/// en: 'Metadata refresh started for "${title}"'
	String metadataRefreshStarted({required Object title}) => 'Metadata refresh started for "${title}"';

	/// en: 'Failed to refresh metadata: ${error}'
	String metadataRefreshFailed({required Object error}) => 'Failed to refresh metadata: ${error}';

	/// en: 'Are you sure you want to logout?'
	String get logoutConfirm => 'Are you sure you want to logout?';

	/// en: 'No seasons found'
	String get noSeasonsFound => 'No seasons found';

	/// en: 'No episodes found in first season'
	String get noEpisodesFound => 'No episodes found in first season';

	/// en: 'No episodes found'
	String get noEpisodesFoundGeneral => 'No episodes found';

	/// en: 'No results found'
	String get noResultsFound => 'No results found';

	/// en: 'Sleep timer set for ${label}'
	String sleepTimerSet({required Object label}) => 'Sleep timer set for ${label}';

	/// en: 'No items available'
	String get noItemsAvailable => 'No items available';

	/// en: 'Failed to create play queue - no items'
	String get failedToCreatePlayQueueNoItems => 'Failed to create play queue - no items';

	/// en: 'Failed to ${action}: ${error}'
	String failedPlayback({required Object action, required Object error}) => 'Failed to ${action}: ${error}';

	/// en: 'Switching to compatible player...'
	String get switchingToCompatiblePlayer => 'Switching to compatible player...';

	/// en: 'Logs uploaded'
	String get logsUploaded => 'Logs uploaded';

	/// en: 'Failed to upload logs'
	String get logsUploadFailed => 'Failed to upload logs';

	/// en: 'Log ID'
	String get logId => 'Log ID';
}

// Path: subtitlingStyling
class TranslationsSubtitlingStylingEn {
	TranslationsSubtitlingStylingEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Styling Options'
	String get stylingOptions => 'Styling Options';

	/// en: 'Font Size'
	String get fontSize => 'Font Size';

	/// en: 'Text Color'
	String get textColor => 'Text Color';

	/// en: 'Border Size'
	String get borderSize => 'Border Size';

	/// en: 'Border Color'
	String get borderColor => 'Border Color';

	/// en: 'Background Opacity'
	String get backgroundOpacity => 'Background Opacity';

	/// en: 'Background Color'
	String get backgroundColor => 'Background Color';

	/// en: 'Position'
	String get position => 'Position';
}

// Path: mpvConfig
class TranslationsMpvConfigEn {
	TranslationsMpvConfigEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'MPV Configuration'
	String get title => 'MPV Configuration';

	/// en: 'Advanced video player settings'
	String get description => 'Advanced video player settings';

	/// en: 'Properties'
	String get properties => 'Properties';

	/// en: 'Presets'
	String get presets => 'Presets';

	/// en: 'No properties configured'
	String get noProperties => 'No properties configured';

	/// en: 'No saved presets'
	String get noPresets => 'No saved presets';

	/// en: 'Add Property'
	String get addProperty => 'Add Property';

	/// en: 'Edit Property'
	String get editProperty => 'Edit Property';

	/// en: 'Delete Property'
	String get deleteProperty => 'Delete Property';

	/// en: 'Property Key'
	String get propertyKey => 'Property Key';

	/// en: 'e.g., hwdec, demuxer-max-bytes'
	String get propertyKeyHint => 'e.g., hwdec, demuxer-max-bytes';

	/// en: 'Property Value'
	String get propertyValue => 'Property Value';

	/// en: 'e.g., auto, 256000000'
	String get propertyValueHint => 'e.g., auto, 256000000';

	/// en: 'Save as Preset...'
	String get saveAsPreset => 'Save as Preset...';

	/// en: 'Preset Name'
	String get presetName => 'Preset Name';

	/// en: 'Enter a name for this preset'
	String get presetNameHint => 'Enter a name for this preset';

	/// en: 'Load'
	String get loadPreset => 'Load';

	/// en: 'Delete'
	String get deletePreset => 'Delete';

	/// en: 'Preset saved'
	String get presetSaved => 'Preset saved';

	/// en: 'Preset loaded'
	String get presetLoaded => 'Preset loaded';

	/// en: 'Preset deleted'
	String get presetDeleted => 'Preset deleted';

	/// en: 'Are you sure you want to delete this preset?'
	String get confirmDeletePreset => 'Are you sure you want to delete this preset?';

	/// en: 'Are you sure you want to delete this property?'
	String get confirmDeleteProperty => 'Are you sure you want to delete this property?';

	/// en: '${count} entries'
	String entriesCount({required Object count}) => '${count} entries';
}

// Path: dialog
class TranslationsDialogEn {
	TranslationsDialogEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Confirm Action'
	String get confirmAction => 'Confirm Action';
}

// Path: discover
class TranslationsDiscoverEn {
	TranslationsDiscoverEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Discover'
	String get title => 'Discover';

	/// en: 'Switch Profile'
	String get switchProfile => 'Switch Profile';

	/// en: 'No content available'
	String get noContentAvailable => 'No content available';

	/// en: 'Add some media to your libraries'
	String get addMediaToLibraries => 'Add some media to your libraries';

	/// en: 'Continue Watching'
	String get continueWatching => 'Continue Watching';

	/// en: 'S${season}E${episode}'
	String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';

	/// en: 'Overview'
	String get overview => 'Overview';

	/// en: 'Cast'
	String get cast => 'Cast';

	/// en: 'Trailers & Extras'
	String get extras => 'Trailers & Extras';

	/// en: 'Seasons'
	String get seasons => 'Seasons';

	/// en: 'Studio'
	String get studio => 'Studio';

	/// en: 'Rating'
	String get rating => 'Rating';

	/// en: '${count} episodes'
	String episodeCount({required Object count}) => '${count} episodes';

	/// en: '${watched}/${total} watched'
	String watchedProgress({required Object watched, required Object total}) => '${watched}/${total} watched';

	/// en: 'Movie'
	String get movie => 'Movie';

	/// en: 'TV Show'
	String get tvShow => 'TV Show';

	/// en: '${minutes} min left'
	String minutesLeft({required Object minutes}) => '${minutes} min left';
}

// Path: errors
class TranslationsErrorsEn {
	TranslationsErrorsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Search failed: ${error}'
	String searchFailed({required Object error}) => 'Search failed: ${error}';

	/// en: 'Connection timeout while loading ${context}'
	String connectionTimeout({required Object context}) => 'Connection timeout while loading ${context}';

	/// en: 'Unable to connect to Plex server'
	String get connectionFailed => 'Unable to connect to Plex server';

	/// en: 'Failed to load ${context}: ${error}'
	String failedToLoad({required Object context, required Object error}) => 'Failed to load ${context}: ${error}';

	/// en: 'No client available'
	String get noClientAvailable => 'No client available';

	/// en: 'Authentication failed: ${error}'
	String authenticationFailed({required Object error}) => 'Authentication failed: ${error}';

	/// en: 'Could not launch auth URL'
	String get couldNotLaunchUrl => 'Could not launch auth URL';

	/// en: 'Please enter a token'
	String get pleaseEnterToken => 'Please enter a token';

	/// en: 'Invalid token'
	String get invalidToken => 'Invalid token';

	/// en: 'Failed to verify token: ${error}'
	String failedToVerifyToken({required Object error}) => 'Failed to verify token: ${error}';

	/// en: 'Failed to switch to ${displayName}'
	String failedToSwitchProfile({required Object displayName}) => 'Failed to switch to ${displayName}';
}

// Path: libraries
class TranslationsLibrariesEn {
	TranslationsLibrariesEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Libraries'
	String get title => 'Libraries';

	/// en: 'Scan Library Files'
	String get scanLibraryFiles => 'Scan Library Files';

	/// en: 'Scan Library'
	String get scanLibrary => 'Scan Library';

	/// en: 'Analyze'
	String get analyze => 'Analyze';

	/// en: 'Analyze Library'
	String get analyzeLibrary => 'Analyze Library';

	/// en: 'Refresh Metadata'
	String get refreshMetadata => 'Refresh Metadata';

	/// en: 'Empty Trash'
	String get emptyTrash => 'Empty Trash';

	/// en: 'Emptying trash for "${title}"...'
	String emptyingTrash({required Object title}) => 'Emptying trash for "${title}"...';

	/// en: 'Trash emptied for "${title}"'
	String trashEmptied({required Object title}) => 'Trash emptied for "${title}"';

	/// en: 'Failed to empty trash: ${error}'
	String failedToEmptyTrash({required Object error}) => 'Failed to empty trash: ${error}';

	/// en: 'Analyzing "${title}"...'
	String analyzing({required Object title}) => 'Analyzing "${title}"...';

	/// en: 'Analysis started for "${title}"'
	String analysisStarted({required Object title}) => 'Analysis started for "${title}"';

	/// en: 'Failed to analyze library: ${error}'
	String failedToAnalyze({required Object error}) => 'Failed to analyze library: ${error}';

	/// en: 'No libraries found'
	String get noLibrariesFound => 'No libraries found';

	/// en: 'This library is empty'
	String get thisLibraryIsEmpty => 'This library is empty';

	/// en: 'All'
	String get all => 'All';

	/// en: 'Clear All'
	String get clearAll => 'Clear All';

	/// en: 'Are you sure you want to scan "${title}"?'
	String scanLibraryConfirm({required Object title}) => 'Are you sure you want to scan "${title}"?';

	/// en: 'Are you sure you want to analyze "${title}"?'
	String analyzeLibraryConfirm({required Object title}) => 'Are you sure you want to analyze "${title}"?';

	/// en: 'Are you sure you want to refresh metadata for "${title}"?'
	String refreshMetadataConfirm({required Object title}) => 'Are you sure you want to refresh metadata for "${title}"?';

	/// en: 'Are you sure you want to empty trash for "${title}"?'
	String emptyTrashConfirm({required Object title}) => 'Are you sure you want to empty trash for "${title}"?';

	/// en: 'Manage Libraries'
	String get manageLibraries => 'Manage Libraries';

	/// en: 'Sort'
	String get sort => 'Sort';

	/// en: 'Sort By'
	String get sortBy => 'Sort By';

	/// en: 'Filters'
	String get filters => 'Filters';

	/// en: 'Are you sure you want to perform this action?'
	String get confirmActionMessage => 'Are you sure you want to perform this action?';

	/// en: 'Show library'
	String get showLibrary => 'Show library';

	/// en: 'Hide library'
	String get hideLibrary => 'Hide library';

	/// en: 'Library options'
	String get libraryOptions => 'Library options';

	/// en: 'library content'
	String get content => 'library content';

	/// en: 'Select library'
	String get selectLibrary => 'Select library';

	/// en: 'Filters (${count})'
	String filtersWithCount({required Object count}) => 'Filters (${count})';

	/// en: 'No recommendations available'
	String get noRecommendations => 'No recommendations available';

	/// en: 'No collections in this library'
	String get noCollections => 'No collections in this library';

	/// en: 'No folders found'
	String get noFoldersFound => 'No folders found';

	/// en: 'folders'
	String get folders => 'folders';

	late final TranslationsLibrariesTabsEn tabs = TranslationsLibrariesTabsEn._(_root);
	late final TranslationsLibrariesGroupingsEn groupings = TranslationsLibrariesGroupingsEn._(_root);
}

// Path: about
class TranslationsAboutEn {
	TranslationsAboutEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'About'
	String get title => 'About';

	/// en: 'Open Source Licenses'
	String get openSourceLicenses => 'Open Source Licenses';

	/// en: 'Version ${version}'
	String versionLabel({required Object version}) => 'Version ${version}';

	/// en: 'A beautiful Plex client for Flutter'
	String get appDescription => 'A beautiful Plex client for Flutter';

	/// en: 'View licenses of third-party libraries'
	String get viewLicensesDescription => 'View licenses of third-party libraries';
}

// Path: serverSelection
class TranslationsServerSelectionEn {
	TranslationsServerSelectionEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Failed to connect to any servers. Please check your network and try again.'
	String get allServerConnectionsFailed => 'Failed to connect to any servers. Please check your network and try again.';

	/// en: 'No servers found for ${username} (${email})'
	String noServersFoundForAccount({required Object username, required Object email}) => 'No servers found for ${username} (${email})';

	/// en: 'Failed to load servers: ${error}'
	String failedToLoadServers({required Object error}) => 'Failed to load servers: ${error}';
}

// Path: hubDetail
class TranslationsHubDetailEn {
	TranslationsHubDetailEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Title'
	String get title => 'Title';

	/// en: 'Release Year'
	String get releaseYear => 'Release Year';

	/// en: 'Date Added'
	String get dateAdded => 'Date Added';

	/// en: 'Rating'
	String get rating => 'Rating';

	/// en: 'No items found'
	String get noItemsFound => 'No items found';
}

// Path: logs
class TranslationsLogsEn {
	TranslationsLogsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Clear Logs'
	String get clearLogs => 'Clear Logs';

	/// en: 'Copy Logs'
	String get copyLogs => 'Copy Logs';

	/// en: 'Upload Logs'
	String get uploadLogs => 'Upload Logs';

	/// en: 'Error:'
	String get error => 'Error:';

	/// en: 'Stack Trace:'
	String get stackTrace => 'Stack Trace:';
}

// Path: licenses
class TranslationsLicensesEn {
	TranslationsLicensesEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Related Packages'
	String get relatedPackages => 'Related Packages';

	/// en: 'License'
	String get license => 'License';

	/// en: 'License ${number}'
	String licenseNumber({required Object number}) => 'License ${number}';

	/// en: '${count} licenses'
	String licensesCount({required Object count}) => '${count} licenses';
}

// Path: navigation
class TranslationsNavigationEn {
	TranslationsNavigationEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Libraries'
	String get libraries => 'Libraries';

	/// en: 'Downloads'
	String get downloads => 'Downloads';

	/// en: 'Live TV'
	String get liveTv => 'Live TV';
}

// Path: liveTv
class TranslationsLiveTvEn {
	TranslationsLiveTvEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Live TV'
	String get title => 'Live TV';

	/// en: 'Channels'
	String get channels => 'Channels';

	/// en: 'Guide'
	String get guide => 'Guide';

	/// en: 'No channels available'
	String get noChannels => 'No channels available';

	/// en: 'No DVR configured on any server'
	String get noDvr => 'No DVR configured on any server';

	/// en: 'Failed to tune channel'
	String get tuneFailed => 'Failed to tune channel';

	/// en: 'Loading channels...'
	String get loading => 'Loading channels...';

	/// en: 'Now Playing'
	String get nowPlaying => 'Now Playing';

	/// en: 'No program data available'
	String get noPrograms => 'No program data available';

	/// en: 'Ch. ${number}'
	String channelNumber({required Object number}) => 'Ch. ${number}';

	/// en: 'LIVE'
	String get live => 'LIVE';

	/// en: 'HD'
	String get hd => 'HD';

	/// en: 'NEW'
	String get premiere => 'NEW';

	/// en: 'Reload Guide'
	String get reloadGuide => 'Reload Guide';

	/// en: 'All Channels'
	String get allChannels => 'All Channels';

	/// en: 'Now'
	String get now => 'Now';

	/// en: 'Today'
	String get today => 'Today';

	/// en: 'Midnight'
	String get midnight => 'Midnight';

	/// en: 'Overnight'
	String get overnight => 'Overnight';

	/// en: 'Morning'
	String get morning => 'Morning';

	/// en: 'Daytime'
	String get daytime => 'Daytime';

	/// en: 'Evening'
	String get evening => 'Evening';

	/// en: 'Late Night'
	String get lateNight => 'Late Night';

	/// en: 'What's On'
	String get whatsOn => 'What\'s On';

	/// en: 'Watch Channel'
	String get watchChannel => 'Watch Channel';
}

// Path: collections
class TranslationsCollectionsEn {
	TranslationsCollectionsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Collections'
	String get title => 'Collections';

	/// en: 'Collection'
	String get collection => 'Collection';

	/// en: 'Collection is empty'
	String get empty => 'Collection is empty';

	/// en: 'Cannot delete: Unknown library section'
	String get unknownLibrarySection => 'Cannot delete: Unknown library section';

	/// en: 'Delete Collection'
	String get deleteCollection => 'Delete Collection';

	/// en: 'Are you sure you want to delete "${title}"? This action cannot be undone.'
	String deleteConfirm({required Object title}) => 'Are you sure you want to delete "${title}"? This action cannot be undone.';

	/// en: 'Collection deleted'
	String get deleted => 'Collection deleted';

	/// en: 'Failed to delete collection'
	String get deleteFailed => 'Failed to delete collection';

	/// en: 'Failed to delete collection: ${error}'
	String deleteFailedWithError({required Object error}) => 'Failed to delete collection: ${error}';

	/// en: 'Failed to load collection items: ${error}'
	String failedToLoadItems({required Object error}) => 'Failed to load collection items: ${error}';

	/// en: 'Select Collection'
	String get selectCollection => 'Select Collection';

	/// en: 'Create New Collection'
	String get createNewCollection => 'Create New Collection';

	/// en: 'Collection Name'
	String get collectionName => 'Collection Name';

	/// en: 'Enter collection name'
	String get enterCollectionName => 'Enter collection name';

	/// en: 'Added to collection'
	String get addedToCollection => 'Added to collection';

	/// en: 'Failed to add to collection'
	String get errorAddingToCollection => 'Failed to add to collection';

	/// en: 'Collection created'
	String get created => 'Collection created';

	/// en: 'Remove from collection'
	String get removeFromCollection => 'Remove from collection';

	/// en: 'Remove "${title}" from this collection?'
	String removeFromCollectionConfirm({required Object title}) => 'Remove "${title}" from this collection?';

	/// en: 'Removed from collection'
	String get removedFromCollection => 'Removed from collection';

	/// en: 'Failed to remove from collection'
	String get removeFromCollectionFailed => 'Failed to remove from collection';

	/// en: 'Error removing from collection: ${error}'
	String removeFromCollectionError({required Object error}) => 'Error removing from collection: ${error}';
}

// Path: playlists
class TranslationsPlaylistsEn {
	TranslationsPlaylistsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Playlists'
	String get title => 'Playlists';

	/// en: 'Playlist'
	String get playlist => 'Playlist';

	/// en: 'No playlists found'
	String get noPlaylists => 'No playlists found';

	/// en: 'Create Playlist'
	String get create => 'Create Playlist';

	/// en: 'Playlist Name'
	String get playlistName => 'Playlist Name';

	/// en: 'Enter playlist name'
	String get enterPlaylistName => 'Enter playlist name';

	/// en: 'Delete Playlist'
	String get delete => 'Delete Playlist';

	/// en: 'Remove from Playlist'
	String get removeItem => 'Remove from Playlist';

	/// en: 'Smart Playlist'
	String get smartPlaylist => 'Smart Playlist';

	/// en: '${count} items'
	String itemCount({required Object count}) => '${count} items';

	/// en: '1 item'
	String get oneItem => '1 item';

	/// en: 'This playlist is empty'
	String get emptyPlaylist => 'This playlist is empty';

	/// en: 'Delete Playlist?'
	String get deleteConfirm => 'Delete Playlist?';

	/// en: 'Are you sure you want to delete "${name}"?'
	String deleteMessage({required Object name}) => 'Are you sure you want to delete "${name}"?';

	/// en: 'Playlist created'
	String get created => 'Playlist created';

	/// en: 'Playlist deleted'
	String get deleted => 'Playlist deleted';

	/// en: 'Added to playlist'
	String get itemAdded => 'Added to playlist';

	/// en: 'Removed from playlist'
	String get itemRemoved => 'Removed from playlist';

	/// en: 'Select Playlist'
	String get selectPlaylist => 'Select Playlist';

	/// en: 'Create New Playlist'
	String get createNewPlaylist => 'Create New Playlist';

	/// en: 'Failed to create playlist'
	String get errorCreating => 'Failed to create playlist';

	/// en: 'Failed to delete playlist'
	String get errorDeleting => 'Failed to delete playlist';

	/// en: 'Failed to load playlists'
	String get errorLoading => 'Failed to load playlists';

	/// en: 'Failed to add to playlist'
	String get errorAdding => 'Failed to add to playlist';

	/// en: 'Failed to reorder playlist item'
	String get errorReordering => 'Failed to reorder playlist item';

	/// en: 'Failed to remove from playlist'
	String get errorRemoving => 'Failed to remove from playlist';
}

// Path: watchTogether
class TranslationsWatchTogetherEn {
	TranslationsWatchTogetherEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Watch Together'
	String get title => 'Watch Together';

	/// en: 'Watch content in sync with friends and family'
	String get description => 'Watch content in sync with friends and family';

	/// en: 'Create Session'
	String get createSession => 'Create Session';

	/// en: 'Creating...'
	String get creating => 'Creating...';

	/// en: 'Join Session'
	String get joinSession => 'Join Session';

	/// en: 'Joining...'
	String get joining => 'Joining...';

	/// en: 'Control Mode'
	String get controlMode => 'Control Mode';

	/// en: 'Who can control playback?'
	String get controlModeQuestion => 'Who can control playback?';

	/// en: 'Host Only'
	String get hostOnly => 'Host Only';

	/// en: 'Anyone'
	String get anyone => 'Anyone';

	/// en: 'Hosting Session'
	String get hostingSession => 'Hosting Session';

	/// en: 'In Session'
	String get inSession => 'In Session';

	/// en: 'Session Code'
	String get sessionCode => 'Session Code';

	/// en: 'Host controls playback'
	String get hostControlsPlayback => 'Host controls playback';

	/// en: 'Anyone can control playback'
	String get anyoneCanControl => 'Anyone can control playback';

	/// en: 'Host controls'
	String get hostControls => 'Host controls';

	/// en: 'Anyone controls'
	String get anyoneControls => 'Anyone controls';

	/// en: 'Participants'
	String get participants => 'Participants';

	/// en: 'Host'
	String get host => 'Host';

	/// en: 'HOST'
	String get hostBadge => 'HOST';

	/// en: 'You are the host'
	String get youAreHost => 'You are the host';

	/// en: 'Watching with others'
	String get watchingWithOthers => 'Watching with others';

	/// en: 'End Session'
	String get endSession => 'End Session';

	/// en: 'Leave Session'
	String get leaveSession => 'Leave Session';

	/// en: 'End Session?'
	String get endSessionQuestion => 'End Session?';

	/// en: 'Leave Session?'
	String get leaveSessionQuestion => 'Leave Session?';

	/// en: 'This will end the session for all participants.'
	String get endSessionConfirm => 'This will end the session for all participants.';

	/// en: 'You will be removed from the session.'
	String get leaveSessionConfirm => 'You will be removed from the session.';

	/// en: 'This will end the watch session for all participants.'
	String get endSessionConfirmOverlay => 'This will end the watch session for all participants.';

	/// en: 'You will be disconnected from the watch session.'
	String get leaveSessionConfirmOverlay => 'You will be disconnected from the watch session.';

	/// en: 'End'
	String get end => 'End';

	/// en: 'Leave'
	String get leave => 'Leave';

	/// en: 'Syncing...'
	String get syncing => 'Syncing...';

	/// en: 'Join Watch Session'
	String get joinWatchSession => 'Join Watch Session';

	/// en: 'Enter 8-character code'
	String get enterCodeHint => 'Enter 8-character code';

	/// en: 'Paste from clipboard'
	String get pasteFromClipboard => 'Paste from clipboard';

	/// en: 'Please enter a session code'
	String get pleaseEnterCode => 'Please enter a session code';

	/// en: 'Session code must be 8 characters'
	String get codeMustBe8Chars => 'Session code must be 8 characters';

	/// en: 'Enter the session code shared by the host to join their watch session.'
	String get joinInstructions => 'Enter the session code shared by the host to join their watch session.';

	/// en: 'Failed to create session'
	String get failedToCreate => 'Failed to create session';

	/// en: 'Failed to join session'
	String get failedToJoin => 'Failed to join session';

	/// en: 'Session code copied to clipboard'
	String get sessionCodeCopied => 'Session code copied to clipboard';

	/// en: 'The relay server is unreachable. This may be caused by your ISP blocking the connection. You can still try, but Watch Together may not work.'
	String get relayUnreachable => 'The relay server is unreachable. This may be caused by your ISP blocking the connection. You can still try, but Watch Together may not work.';

	/// en: 'Reconnecting to host...'
	String get reconnectingToHost => 'Reconnecting to host...';

	/// en: '${name} joined'
	String participantJoined({required Object name}) => '${name} joined';

	/// en: '${name} left'
	String participantLeft({required Object name}) => '${name} left';
}

// Path: downloads
class TranslationsDownloadsEn {
	TranslationsDownloadsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Downloads'
	String get title => 'Downloads';

	/// en: 'Manage'
	String get manage => 'Manage';

	/// en: 'TV Shows'
	String get tvShows => 'TV Shows';

	/// en: 'Movies'
	String get movies => 'Movies';

	/// en: 'No downloads yet'
	String get noDownloads => 'No downloads yet';

	/// en: 'Downloaded content will appear here for offline viewing'
	String get noDownloadsDescription => 'Downloaded content will appear here for offline viewing';

	/// en: 'Download'
	String get downloadNow => 'Download';

	/// en: 'Delete download'
	String get deleteDownload => 'Delete download';

	/// en: 'Retry download'
	String get retryDownload => 'Retry download';

	/// en: 'Download queued'
	String get downloadQueued => 'Download queued';

	/// en: '${count} episodes queued for download'
	String episodesQueued({required Object count}) => '${count} episodes queued for download';

	/// en: 'Download deleted'
	String get downloadDeleted => 'Download deleted';

	/// en: 'Are you sure you want to delete "${title}"? This will remove the downloaded file from your device.'
	String deleteConfirm({required Object title}) => 'Are you sure you want to delete "${title}"? This will remove the downloaded file from your device.';

	/// en: 'Deleting ${title}... (${current} of ${total})'
	String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Deleting ${title}... (${current} of ${total})';

	/// en: 'No downloads'
	String get noDownloadsTree => 'No downloads';

	/// en: 'Pause all'
	String get pauseAll => 'Pause all';

	/// en: 'Resume all'
	String get resumeAll => 'Resume all';

	/// en: 'Delete all'
	String get deleteAll => 'Delete all';
}

// Path: shaders
class TranslationsShadersEn {
	TranslationsShadersEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Shaders'
	String get title => 'Shaders';

	/// en: 'No video enhancement'
	String get noShaderDescription => 'No video enhancement';

	/// en: 'NVIDIA image scaling for sharper video'
	String get nvscalerDescription => 'NVIDIA image scaling for sharper video';

	/// en: 'Fast'
	String get qualityFast => 'Fast';

	/// en: 'High Quality'
	String get qualityHQ => 'High Quality';

	/// en: 'Mode'
	String get mode => 'Mode';
}

// Path: companionRemote
class TranslationsCompanionRemoteEn {
	TranslationsCompanionRemoteEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Companion Remote'
	String get title => 'Companion Remote';

	/// en: 'Connect to Device'
	String get connectToDevice => 'Connect to Device';

	/// en: 'Host Remote Session'
	String get hostRemoteSession => 'Host Remote Session';

	/// en: 'Control this device with your phone'
	String get controlThisDevice => 'Control this device with your phone';

	/// en: 'Remote Control'
	String get remoteControl => 'Remote Control';

	/// en: 'Control a desktop device'
	String get controlDesktop => 'Control a desktop device';

	/// en: 'Connected to ${name}'
	String connectedTo({required Object name}) => 'Connected to ${name}';

	late final TranslationsCompanionRemoteSessionEn session = TranslationsCompanionRemoteSessionEn._(_root);
	late final TranslationsCompanionRemotePairingEn pairing = TranslationsCompanionRemotePairingEn._(_root);
	late final TranslationsCompanionRemoteRemoteEn remote = TranslationsCompanionRemoteRemoteEn._(_root);
}

// Path: videoSettings
class TranslationsVideoSettingsEn {
	TranslationsVideoSettingsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Playback Settings'
	String get playbackSettings => 'Playback Settings';

	/// en: 'Playback Speed'
	String get playbackSpeed => 'Playback Speed';

	/// en: 'Sleep Timer'
	String get sleepTimer => 'Sleep Timer';

	/// en: 'Audio Sync'
	String get audioSync => 'Audio Sync';

	/// en: 'Subtitle Sync'
	String get subtitleSync => 'Subtitle Sync';

	/// en: 'HDR'
	String get hdr => 'HDR';

	/// en: 'Audio Output'
	String get audioOutput => 'Audio Output';

	/// en: 'Performance Overlay'
	String get performanceOverlay => 'Performance Overlay';

	/// en: 'Audio Passthrough'
	String get audioPassthrough => 'Audio Passthrough';

	/// en: 'Audio Normalization'
	String get audioNormalization => 'Audio Normalization';
}

// Path: externalPlayer
class TranslationsExternalPlayerEn {
	TranslationsExternalPlayerEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'External Player'
	String get title => 'External Player';

	/// en: 'Use External Player'
	String get useExternalPlayer => 'Use External Player';

	/// en: 'Open videos in an external app instead of the built-in player'
	String get useExternalPlayerDescription => 'Open videos in an external app instead of the built-in player';

	/// en: 'Select Player'
	String get selectPlayer => 'Select Player';

	/// en: 'System Default'
	String get systemDefault => 'System Default';

	/// en: 'Add Custom Player'
	String get addCustomPlayer => 'Add Custom Player';

	/// en: 'Player Name'
	String get playerName => 'Player Name';

	/// en: 'Command'
	String get playerCommand => 'Command';

	/// en: 'Package Name'
	String get playerPackage => 'Package Name';

	/// en: 'URL Scheme'
	String get playerUrlScheme => 'URL Scheme';

	/// en: 'Custom Player'
	String get customPlayer => 'Custom Player';

	/// en: 'Off'
	String get off => 'Off';

	/// en: 'Failed to open external player'
	String get launchFailed => 'Failed to open external player';

	/// en: '${name} is not installed'
	String appNotInstalled({required Object name}) => '${name} is not installed';

	/// en: 'Play in External Player'
	String get playInExternalPlayer => 'Play in External Player';
}

// Path: metadataEdit
class TranslationsMetadataEditEn {
	TranslationsMetadataEditEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Edit...'
	String get editMetadata => 'Edit...';

	/// en: 'Edit Metadata'
	String get screenTitle => 'Edit Metadata';

	/// en: 'Basic Info'
	String get basicInfo => 'Basic Info';

	/// en: 'Artwork'
	String get artwork => 'Artwork';

	/// en: 'Advanced Settings'
	String get advancedSettings => 'Advanced Settings';

	/// en: 'Title'
	String get title => 'Title';

	/// en: 'Sort Title'
	String get sortTitle => 'Sort Title';

	/// en: 'Original Title'
	String get originalTitle => 'Original Title';

	/// en: 'Release Date'
	String get releaseDate => 'Release Date';

	/// en: 'Content Rating'
	String get contentRating => 'Content Rating';

	/// en: 'Studio'
	String get studio => 'Studio';

	/// en: 'Tagline'
	String get tagline => 'Tagline';

	/// en: 'Summary'
	String get summary => 'Summary';

	/// en: 'Poster'
	String get poster => 'Poster';

	/// en: 'Background'
	String get background => 'Background';

	/// en: 'Select Poster'
	String get selectPoster => 'Select Poster';

	/// en: 'Select Background'
	String get selectBackground => 'Select Background';

	/// en: 'From URL'
	String get fromUrl => 'From URL';

	/// en: 'Upload File'
	String get uploadFile => 'Upload File';

	/// en: 'Enter image URL'
	String get enterImageUrl => 'Enter image URL';

	/// en: 'Image URL'
	String get imageUrl => 'Image URL';

	/// en: 'Metadata updated'
	String get metadataUpdated => 'Metadata updated';

	/// en: 'Failed to update metadata'
	String get metadataUpdateFailed => 'Failed to update metadata';

	/// en: 'Artwork updated'
	String get artworkUpdated => 'Artwork updated';

	/// en: 'Failed to update artwork'
	String get artworkUpdateFailed => 'Failed to update artwork';

	/// en: 'No artwork available'
	String get noArtworkAvailable => 'No artwork available';

	/// en: 'Not set'
	String get notSet => 'Not set';

	/// en: 'Library default'
	String get libraryDefault => 'Library default';

	/// en: 'Account default'
	String get accountDefault => 'Account default';

	/// en: 'Series default'
	String get seriesDefault => 'Series default';

	/// en: 'Episode Sorting'
	String get episodeSorting => 'Episode Sorting';

	/// en: 'Oldest first'
	String get oldestFirst => 'Oldest first';

	/// en: 'Newest first'
	String get newestFirst => 'Newest first';

	/// en: 'Keep'
	String get keep => 'Keep';

	/// en: 'All episodes'
	String get allEpisodes => 'All episodes';

	/// en: '${count} latest episodes'
	String latestEpisodes({required Object count}) => '${count} latest episodes';

	/// en: 'Latest episode'
	String get latestEpisode => 'Latest episode';

	/// en: 'Episodes added in the past ${count} days'
	String episodesAddedPastDays({required Object count}) => 'Episodes added in the past ${count} days';

	/// en: 'Delete Episodes After Playing'
	String get deleteAfterPlaying => 'Delete Episodes After Playing';

	/// en: 'Never'
	String get never => 'Never';

	/// en: 'After a day'
	String get afterADay => 'After a day';

	/// en: 'After a week'
	String get afterAWeek => 'After a week';

	/// en: 'After a month'
	String get afterAMonth => 'After a month';

	/// en: 'On next refresh'
	String get onNextRefresh => 'On next refresh';

	/// en: 'Seasons'
	String get seasons => 'Seasons';

	/// en: 'Show'
	String get show => 'Show';

	/// en: 'Hide'
	String get hide => 'Hide';

	/// en: 'Episode Ordering'
	String get episodeOrdering => 'Episode Ordering';

	/// en: 'The Movie Database (Aired)'
	String get tmdbAiring => 'The Movie Database (Aired)';

	/// en: 'TheTVDB (Aired)'
	String get tvdbAiring => 'TheTVDB (Aired)';

	/// en: 'TheTVDB (Absolute)'
	String get tvdbAbsolute => 'TheTVDB (Absolute)';

	/// en: 'Metadata Language'
	String get metadataLanguage => 'Metadata Language';

	/// en: 'Use Original Title'
	String get useOriginalTitle => 'Use Original Title';

	/// en: 'Preferred Audio Language'
	String get preferredAudioLanguage => 'Preferred Audio Language';

	/// en: 'Preferred Subtitle Language'
	String get preferredSubtitleLanguage => 'Preferred Subtitle Language';

	/// en: 'Auto-Select Subtitle Mode'
	String get subtitleMode => 'Auto-Select Subtitle Mode';

	/// en: 'Manually selected'
	String get manuallySelected => 'Manually selected';

	/// en: 'Shown with foreign audio'
	String get shownWithForeignAudio => 'Shown with foreign audio';

	/// en: 'Always enabled'
	String get alwaysEnabled => 'Always enabled';
}

// Path: hotkeys.actions
class TranslationsHotkeysActionsEn {
	TranslationsHotkeysActionsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Play/Pause'
	String get playPause => 'Play/Pause';

	/// en: 'Volume Up'
	String get volumeUp => 'Volume Up';

	/// en: 'Volume Down'
	String get volumeDown => 'Volume Down';

	/// en: 'Seek Forward (${seconds}s)'
	String seekForward({required Object seconds}) => 'Seek Forward (${seconds}s)';

	/// en: 'Seek Backward (${seconds}s)'
	String seekBackward({required Object seconds}) => 'Seek Backward (${seconds}s)';

	/// en: 'Toggle Fullscreen'
	String get fullscreenToggle => 'Toggle Fullscreen';

	/// en: 'Toggle Mute'
	String get muteToggle => 'Toggle Mute';

	/// en: 'Toggle Subtitles'
	String get subtitleToggle => 'Toggle Subtitles';

	/// en: 'Next Audio Track'
	String get audioTrackNext => 'Next Audio Track';

	/// en: 'Next Subtitle Track'
	String get subtitleTrackNext => 'Next Subtitle Track';

	/// en: 'Next Chapter'
	String get chapterNext => 'Next Chapter';

	/// en: 'Previous Chapter'
	String get chapterPrevious => 'Previous Chapter';

	/// en: 'Increase Speed'
	String get speedIncrease => 'Increase Speed';

	/// en: 'Decrease Speed'
	String get speedDecrease => 'Decrease Speed';

	/// en: 'Reset Speed'
	String get speedReset => 'Reset Speed';

	/// en: 'Seek to Next Subtitle'
	String get subSeekNext => 'Seek to Next Subtitle';

	/// en: 'Seek to Previous Subtitle'
	String get subSeekPrev => 'Seek to Previous Subtitle';

	/// en: 'Toggle Shaders'
	String get shaderToggle => 'Toggle Shaders';

	/// en: 'Skip Intro/Credits'
	String get skipMarker => 'Skip Intro/Credits';
}

// Path: videoControls.pipErrors
class TranslationsVideoControlsPipErrorsEn {
	TranslationsVideoControlsPipErrorsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Requires Android 8.0 or newer'
	String get androidVersion => 'Requires Android 8.0 or newer';

	/// en: 'Picture-in-picture permission is disabled. Enable it in Settings > Apps > Plezy > Picture-in-picture'
	String get permissionDisabled => 'Picture-in-picture permission is disabled. Enable it in Settings > Apps > Plezy > Picture-in-picture';

	/// en: 'Device doesn't support picture-in-picture mode'
	String get notSupported => 'Device doesn\'t support picture-in-picture mode';

	/// en: 'Picture-in-picture failed to start'
	String get failed => 'Picture-in-picture failed to start';

	/// en: 'An error occurred: ${error}'
	String unknown({required Object error}) => 'An error occurred: ${error}';
}

// Path: libraries.tabs
class TranslationsLibrariesTabsEn {
	TranslationsLibrariesTabsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Recommended'
	String get recommended => 'Recommended';

	/// en: 'Browse'
	String get browse => 'Browse';

	/// en: 'Collections'
	String get collections => 'Collections';

	/// en: 'Playlists'
	String get playlists => 'Playlists';
}

// Path: libraries.groupings
class TranslationsLibrariesGroupingsEn {
	TranslationsLibrariesGroupingsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'All'
	String get all => 'All';

	/// en: 'Movies'
	String get movies => 'Movies';

	/// en: 'TV Shows'
	String get shows => 'TV Shows';

	/// en: 'Seasons'
	String get seasons => 'Seasons';

	/// en: 'Episodes'
	String get episodes => 'Episodes';

	/// en: 'Folders'
	String get folders => 'Folders';
}

// Path: companionRemote.session
class TranslationsCompanionRemoteSessionEn {
	TranslationsCompanionRemoteSessionEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Creating remote session...'
	String get creatingSession => 'Creating remote session...';

	/// en: 'Failed to create remote session:'
	String get failedToCreate => 'Failed to create remote session:';

	/// en: 'No session available'
	String get noSession => 'No session available';

	/// en: 'Scan QR Code'
	String get scanQrCode => 'Scan QR Code';

	/// en: 'Or enter manually'
	String get orEnterManually => 'Or enter manually';

	/// en: 'Host Address'
	String get hostAddress => 'Host Address';

	/// en: 'Session ID'
	String get sessionId => 'Session ID';

	/// en: 'PIN'
	String get pin => 'PIN';

	/// en: 'Connected'
	String get connected => 'Connected';

	/// en: 'Waiting for connection...'
	String get waitingForConnection => 'Waiting for connection...';

	/// en: 'Use your mobile device to control this app'
	String get usePhoneToControl => 'Use your mobile device to control this app';

	/// en: '${label} copied to clipboard'
	String copiedToClipboard({required Object label}) => '${label} copied to clipboard';

	/// en: 'Copy to clipboard'
	String get copyToClipboard => 'Copy to clipboard';

	/// en: 'New Session'
	String get newSession => 'New Session';

	/// en: 'Minimize'
	String get minimize => 'Minimize';
}

// Path: companionRemote.pairing
class TranslationsCompanionRemotePairingEn {
	TranslationsCompanionRemotePairingEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Scan'
	String get scan => 'Scan';

	/// en: 'Manual'
	String get manual => 'Manual';

	/// en: 'Pair with Desktop'
	String get pairWithDesktop => 'Pair with Desktop';

	/// en: 'Enter the session details shown on your desktop device'
	String get enterSessionDetails => 'Enter the session details shown on your desktop device';

	/// en: '192.168.1.100:48632'
	String get hostAddressHint => '192.168.1.100:48632';

	/// en: 'Enter 8-character session ID'
	String get sessionIdHint => 'Enter 8-character session ID';

	/// en: 'Enter 6-digit PIN'
	String get pinHint => 'Enter 6-digit PIN';

	/// en: 'Connecting...'
	String get connecting => 'Connecting...';

	/// en: 'Tips'
	String get tips => 'Tips';

	/// en: 'Open Plezy on your desktop and enable Companion Remote from settings or menu'
	String get tipDesktop => 'Open Plezy on your desktop and enable Companion Remote from settings or menu';

	/// en: 'Use the Scan tab to quickly pair by scanning the QR code on your desktop'
	String get tipScan => 'Use the Scan tab to quickly pair by scanning the QR code on your desktop';

	/// en: 'Make sure both devices are on the same WiFi network'
	String get tipWifi => 'Make sure both devices are on the same WiFi network';

	/// en: 'Camera permission is required to scan QR codes. Please grant camera access in your device settings.'
	String get cameraPermissionRequired => 'Camera permission is required to scan QR codes.\nPlease grant camera access in your device settings.';

	/// en: 'Could not start camera: ${error}'
	String cameraError({required Object error}) => 'Could not start camera: ${error}';

	/// en: 'Point your camera at the QR code shown on your desktop'
	String get scanInstruction => 'Point your camera at the QR code shown on your desktop';

	/// en: 'Invalid QR code format'
	String get invalidQrCode => 'Invalid QR code format';

	/// en: 'Please enter host address'
	String get validationHostRequired => 'Please enter host address';

	/// en: 'Format must be IP:port (e.g., 192.168.1.100:48632)'
	String get validationHostFormat => 'Format must be IP:port (e.g., 192.168.1.100:48632)';

	/// en: 'Please enter a session ID'
	String get validationSessionIdRequired => 'Please enter a session ID';

	/// en: 'Session ID must be 8 characters'
	String get validationSessionIdLength => 'Session ID must be 8 characters';

	/// en: 'Please enter a PIN'
	String get validationPinRequired => 'Please enter a PIN';

	/// en: 'PIN must be 6 digits'
	String get validationPinLength => 'PIN must be 6 digits';

	/// en: 'Connection timed out. Please check the session ID and PIN.'
	String get connectionTimedOut => 'Connection timed out. Please check the session ID and PIN.';

	/// en: 'Could not find the session. Please check your credentials.'
	String get sessionNotFound => 'Could not find the session. Please check your credentials.';

	/// en: 'Failed to connect: ${error}'
	String failedToConnect({required Object error}) => 'Failed to connect: ${error}';

}

// Path: companionRemote.remote
class TranslationsCompanionRemoteRemoteEn {
	TranslationsCompanionRemoteRemoteEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Do you want to disconnect from the remote session?'
	String get disconnectConfirm => 'Do you want to disconnect from the remote session?';

	/// en: 'Reconnecting...'
	String get reconnecting => 'Reconnecting...';

	/// en: 'Attempt ${current} of 5'
	String attemptOf({required Object current}) => 'Attempt ${current} of 5';

	/// en: 'Retry Now'
	String get retryNow => 'Retry Now';

	/// en: 'Connection error'
	String get connectionError => 'Connection error';

	/// en: 'Not connected'
	String get notConnected => 'Not connected';

	/// en: 'Remote'
	String get tabRemote => 'Remote';

	/// en: 'Play'
	String get tabPlay => 'Play';

	/// en: 'More'
	String get tabMore => 'More';

	/// en: 'Menu'
	String get menu => 'Menu';

	/// en: 'Tab Navigation'
	String get tabNavigation => 'Tab Navigation';

	/// en: 'Discover'
	String get tabDiscover => 'Discover';

	/// en: 'Libraries'
	String get tabLibraries => 'Libraries';

	/// en: 'Search'
	String get tabSearch => 'Search';

	/// en: 'Downloads'
	String get tabDownloads => 'Downloads';

	/// en: 'Settings'
	String get tabSettings => 'Settings';

	/// en: 'Previous'
	String get previous => 'Previous';

	/// en: 'Play/Pause'
	String get playPause => 'Play/Pause';

	/// en: 'Next'
	String get next => 'Next';

	/// en: 'Seek Back'
	String get seekBack => 'Seek Back';

	/// en: 'Stop'
	String get stop => 'Stop';

	/// en: 'Seek Fwd'
	String get seekForward => 'Seek Fwd';

	/// en: 'Volume'
	String get volume => 'Volume';

	/// en: 'Down'
	String get volumeDown => 'Down';

	/// en: 'Up'
	String get volumeUp => 'Up';

	/// en: 'Fullscreen'
	String get fullscreen => 'Fullscreen';

	/// en: 'Subtitles'
	String get subtitles => 'Subtitles';

	/// en: 'Audio'
	String get audio => 'Audio';

	/// en: 'Search on desktop...'
	String get searchHint => 'Search on desktop...';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Plezy',
			'auth.signInWithPlex' => 'Sign in with Plex',
			'auth.showQRCode' => 'Show QR Code',
			'auth.authenticate' => 'Authenticate',
			'auth.debugEnterToken' => 'Debug: Enter Plex Token',
			'auth.plexTokenLabel' => 'Plex Auth Token',
			'auth.plexTokenHint' => 'Enter your Plex.tv token',
			'auth.authenticationTimeout' => 'Authentication timed out. Please try again.',
			'auth.scanQRToSignIn' => 'Scan this QR code to sign in',
			'auth.waitingForAuth' => 'Waiting for authentication...\nPlease complete sign-in in your browser.',
			'auth.useBrowser' => 'Use browser',
			'common.cancel' => 'Cancel',
			'common.save' => 'Save',
			'common.close' => 'Close',
			'common.clear' => 'Clear',
			'common.reset' => 'Reset',
			'common.later' => 'Later',
			'common.submit' => 'Submit',
			'common.confirm' => 'Confirm',
			'common.retry' => 'Retry',
			'common.logout' => 'Logout',
			'common.unknown' => 'Unknown',
			'common.refresh' => 'Refresh',
			'common.yes' => 'Yes',
			'common.no' => 'No',
			'common.delete' => 'Delete',
			'common.shuffle' => 'Shuffle',
			'common.addTo' => 'Add to...',
			'common.remove' => 'Remove',
			'common.paste' => 'Paste',
			'common.connect' => 'Connect',
			'common.disconnect' => 'Disconnect',
			'common.play' => 'Play',
			'common.pause' => 'Pause',
			'common.resume' => 'Resume',
			'common.error' => 'Error',
			'common.search' => 'Search',
			'common.home' => 'Home',
			'common.back' => 'Back',
			'common.settings' => 'Settings',
			'common.mute' => 'Mute',
			'common.ok' => 'OK',
			'common.loading' => 'Loading...',
			'common.reconnect' => 'Reconnect',
			'common.exitConfirmTitle' => 'Exit app?',
			'common.exitConfirmMessage' => 'Are you sure you want to exit?',
			'common.dontAskAgain' => 'Don\'t ask again',
			'common.exit' => 'Exit',
			'common.viewAll' => 'View All',
			'common.checkingNetwork' => 'Checking network...',
			'common.refreshingServers' => 'Refreshing servers...',
			'common.loadingServers' => 'Loading servers...',
			'common.connectingToServers' => 'Connecting to servers...',
			'common.startingOfflineMode' => 'Starting offline mode...',
			'screens.licenses' => 'Licenses',
			'screens.switchProfile' => 'Switch Profile',
			'screens.subtitleStyling' => 'Subtitle Styling',
			'screens.mpvConfig' => 'MPV Configuration',
			'screens.logs' => 'Logs',
			'update.available' => 'Update Available',
			'update.versionAvailable' => ({required Object version}) => 'Version ${version} is available',
			'update.currentVersion' => ({required Object version}) => 'Current: ${version}',
			'update.skipVersion' => 'Skip This Version',
			'update.viewRelease' => 'View Release',
			'update.latestVersion' => 'You are on the latest version',
			'update.checkFailed' => 'Failed to check for updates',
			'settings.title' => 'Settings',
			'settings.language' => 'Language',
			'settings.theme' => 'Theme',
			'settings.appearance' => 'Appearance',
			'settings.videoPlayback' => 'Video Playback',
			'settings.advanced' => 'Advanced',
			'settings.episodePosterMode' => 'Episode Poster Style',
			'settings.seriesPoster' => 'Series Poster',
			'settings.seriesPosterDescription' => 'Show the series poster for all episodes',
			'settings.seasonPoster' => 'Season Poster',
			'settings.seasonPosterDescription' => 'Show the season-specific poster for episodes',
			'settings.episodeThumbnail' => 'Episode Thumbnail',
			'settings.episodeThumbnailDescription' => 'Show 16:9 episode screenshot thumbnails',
			'settings.showHeroSectionDescription' => 'Display featured content carousel on home screen',
			'settings.secondsLabel' => 'Seconds',
			'settings.minutesLabel' => 'Minutes',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Enter duration (${min}-${max})',
			'settings.systemTheme' => 'System',
			'settings.systemThemeDescription' => 'Follow system settings',
			'settings.lightTheme' => 'Light',
			'settings.darkTheme' => 'Dark',
			'settings.oledTheme' => 'OLED',
			'settings.oledThemeDescription' => 'Pure black for OLED screens',
			'settings.libraryDensity' => 'Library Density',
			'settings.compact' => 'Compact',
			'settings.compactDescription' => 'Smaller cards, more items visible',
			'settings.normal' => 'Normal',
			'settings.normalDescription' => 'Default size',
			'settings.comfortable' => 'Comfortable',
			'settings.comfortableDescription' => 'Larger cards, fewer items visible',
			'settings.viewMode' => 'View Mode',
			'settings.gridView' => 'Grid',
			'settings.gridViewDescription' => 'Display items in a grid layout',
			'settings.listView' => 'List',
			'settings.listViewDescription' => 'Display items in a list layout',
			'settings.showHeroSection' => 'Show Hero Section',
			'settings.useGlobalHubs' => 'Use Plex Home Layout',
			'settings.useGlobalHubsDescription' => 'Show home page hubs like the official Plex client. When off, shows per-library recommendations instead.',
			'settings.showServerNameOnHubs' => 'Show Server Name on Hubs',
			'settings.showServerNameOnHubsDescription' => 'Always display the server name in hub titles. When off, only shows for duplicate hub names.',
			'settings.alwaysKeepSidebarOpen' => 'Always Keep Sidebar Open',
			'settings.alwaysKeepSidebarOpenDescription' => 'Sidebar stays expanded and content area adjusts to fit',
			'settings.showUnwatchedCount' => 'Show Unwatched Count',
			'settings.showUnwatchedCountDescription' => 'Display unwatched episode count on shows and seasons',
			'settings.hideSpoilers' => 'Hide Spoilers for Unwatched Episodes',
			'settings.hideSpoilersDescription' => 'Blur thumbnails and hide descriptions for episodes you haven\'t watched yet',
			'settings.playerBackend' => 'Player Backend',
			'settings.exoPlayer' => 'ExoPlayer (Recommended)',
			'settings.exoPlayerDescription' => 'Android native player with better hardware support',
			'settings.mpv' => 'MPV',
			'settings.mpvDescription' => 'Advanced player with more features and ASS subtitle support',
			'settings.hardwareDecoding' => 'Hardware Decoding',
			'settings.hardwareDecodingDescription' => 'Use hardware acceleration when available',
			'settings.bufferSize' => 'Buffer Size',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => 'Auto (Recommended)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => 'Your device has ${heap}MB of memory. A ${size}MB buffer may cause playback issues.',
			'settings.subtitleStyling' => 'Subtitle Styling',
			'settings.subtitleStylingDescription' => 'Customize subtitle appearance',
			'settings.smallSkipDuration' => 'Small Skip Duration',
			'settings.largeSkipDuration' => 'Large Skip Duration',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} seconds',
			'settings.defaultSleepTimer' => 'Default Sleep Timer',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} minutes',
			'settings.rememberTrackSelections' => 'Remember track selections per show/movie',
			'settings.rememberTrackSelectionsDescription' => 'Automatically save audio and subtitle language preferences when you change tracks during playback',
			'settings.clickVideoTogglesPlayback' => 'Click on video to toggle play/pause',
			'settings.clickVideoTogglesPlaybackDescription' => 'If enabled, clicking on the video player will play/pause the video. Otherwise, clicking will show/hide the playback controls.',
			'settings.videoPlayerControls' => 'Video Player Controls',
			'settings.keyboardShortcuts' => 'Keyboard Shortcuts',
			'settings.keyboardShortcutsDescription' => 'Customize keyboard shortcuts',
			'settings.videoPlayerNavigation' => 'Video Player Navigation',
			'settings.videoPlayerNavigationDescription' => 'Use arrow keys to navigate video player controls',
			'settings.debugLogging' => 'Debug Logging',
			'settings.debugLoggingDescription' => 'Enable detailed logging for troubleshooting',
			'settings.viewLogs' => 'View Logs',
			'settings.viewLogsDescription' => 'View application logs',
			'settings.clearCache' => 'Clear Cache',
			'settings.clearCacheDescription' => 'This will clear all cached images and data. The app may take longer to load content after clearing the cache.',
			'settings.clearCacheSuccess' => 'Cache cleared successfully',
			'settings.resetSettings' => 'Reset Settings',
			'settings.resetSettingsDescription' => 'This will reset all settings to their default values. This action cannot be undone.',
			'settings.resetSettingsSuccess' => 'Settings reset successfully',
			'settings.shortcutsReset' => 'Shortcuts reset to defaults',
			'settings.about' => 'About',
			'settings.aboutDescription' => 'App information and licenses',
			'settings.updates' => 'Updates',
			'settings.updateAvailable' => 'Update Available',
			'settings.checkForUpdates' => 'Check for Updates',
			'settings.validationErrorEnterNumber' => 'Please enter a valid number',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Duration must be between ${min} and ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Shortcut already assigned to ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Shortcut updated for ${action}',
			'settings.autoSkip' => 'Auto Skip',
			'settings.autoSkipIntro' => 'Auto Skip Intro',
			'settings.autoSkipIntroDescription' => 'Automatically skip intro markers after a few seconds',
			'settings.autoSkipCredits' => 'Auto Skip Credits',
			'settings.autoSkipCreditsDescription' => 'Automatically skip credits and play next episode',
			'settings.autoSkipDelay' => 'Auto Skip Delay',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Wait ${seconds} seconds before auto-skipping',
			'settings.downloads' => 'Downloads',
			'settings.downloadLocationDescription' => 'Choose where to store downloaded content',
			'settings.downloadLocationDefault' => 'Default (App Storage)',
			'settings.downloadLocationCustom' => 'Custom Location',
			'settings.selectFolder' => 'Select Folder',
			'settings.resetToDefault' => 'Reset to Default',
			'settings.currentPath' => ({required Object path}) => 'Current: ${path}',
			'settings.downloadLocationChanged' => 'Download location changed',
			'settings.downloadLocationReset' => 'Download location reset to default',
			'settings.downloadLocationInvalid' => 'Selected folder is not writable',
			'settings.downloadLocationSelectError' => 'Failed to select folder',
			'settings.downloadOnWifiOnly' => 'Download on WiFi only',
			'settings.downloadOnWifiOnlyDescription' => 'Prevent downloads when on cellular data',
			'settings.cellularDownloadBlocked' => 'Downloads are disabled on cellular data. Connect to WiFi or change the setting.',
			'settings.maxVolume' => 'Maximum Volume',
			'settings.maxVolumeDescription' => 'Allow volume boost above 100% for quiet media',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Show what you\'re watching on Discord',
			'settings.autoPip' => 'Auto Picture-in-Picture',
			'settings.autoPipDescription' => 'Automatically enter picture-in-picture when leaving the app during playback',
			'settings.matchContentFrameRate' => 'Match Content Frame Rate',
			'settings.matchContentFrameRateDescription' => 'Adjust display refresh rate to match video content, reducing judder and saving battery',
			'settings.tunneledPlayback' => 'Tunneled Playback',
			'settings.tunneledPlaybackDescription' => 'Use hardware-accelerated video tunneling. Disable if you see a black screen with audio on HDR content',
			'settings.requireProfileSelectionOnOpen' => 'Ask for profile on app open',
			'settings.requireProfileSelectionOnOpenDescription' => 'Show profile selection every time the app is opened',
			'settings.confirmExitOnBack' => 'Confirm before exiting',
			'settings.confirmExitOnBackDescription' => 'Show a confirmation dialog when pressing back to exit the app',
			'search.hint' => 'Search movies, shows, music...',
			'search.tryDifferentTerm' => 'Try a different search term',
			'search.searchYourMedia' => 'Search your media',
			'search.enterTitleActorOrKeyword' => 'Enter a title, actor, or keyword',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Set Shortcut for ${actionName}',
			'hotkeys.clearShortcut' => 'Clear shortcut',
			'hotkeys.actions.playPause' => 'Play/Pause',
			'hotkeys.actions.volumeUp' => 'Volume Up',
			'hotkeys.actions.volumeDown' => 'Volume Down',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Seek Forward (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Seek Backward (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'Toggle Fullscreen',
			'hotkeys.actions.muteToggle' => 'Toggle Mute',
			'hotkeys.actions.subtitleToggle' => 'Toggle Subtitles',
			'hotkeys.actions.audioTrackNext' => 'Next Audio Track',
			'hotkeys.actions.subtitleTrackNext' => 'Next Subtitle Track',
			'hotkeys.actions.chapterNext' => 'Next Chapter',
			'hotkeys.actions.chapterPrevious' => 'Previous Chapter',
			'hotkeys.actions.speedIncrease' => 'Increase Speed',
			'hotkeys.actions.speedDecrease' => 'Decrease Speed',
			'hotkeys.actions.speedReset' => 'Reset Speed',
			'hotkeys.actions.subSeekNext' => 'Seek to Next Subtitle',
			'hotkeys.actions.subSeekPrev' => 'Seek to Previous Subtitle',
			'hotkeys.actions.shaderToggle' => 'Toggle Shaders',
			'hotkeys.actions.skipMarker' => 'Skip Intro/Credits',
			'pinEntry.enterPin' => 'Enter PIN',
			'pinEntry.showPin' => 'Show PIN',
			'pinEntry.hidePin' => 'Hide PIN',
			'fileInfo.title' => 'File Info',
			'fileInfo.video' => 'Video',
			'fileInfo.audio' => 'Audio',
			'fileInfo.file' => 'File',
			'fileInfo.advanced' => 'Advanced',
			'fileInfo.codec' => 'Codec',
			'fileInfo.resolution' => 'Resolution',
			'fileInfo.bitrate' => 'Bitrate',
			'fileInfo.frameRate' => 'Frame Rate',
			'fileInfo.aspectRatio' => 'Aspect Ratio',
			'fileInfo.profile' => 'Profile',
			'fileInfo.bitDepth' => 'Bit Depth',
			'fileInfo.colorSpace' => 'Color Space',
			'fileInfo.colorRange' => 'Color Range',
			'fileInfo.colorPrimaries' => 'Color Primaries',
			'fileInfo.chromaSubsampling' => 'Chroma Subsampling',
			'fileInfo.channels' => 'Channels',
			'fileInfo.path' => 'Path',
			'fileInfo.size' => 'Size',
			'fileInfo.container' => 'Container',
			'fileInfo.duration' => 'Duration',
			'fileInfo.optimizedForStreaming' => 'Optimized for Streaming',
			'fileInfo.has64bitOffsets' => '64-bit Offsets',
			'mediaMenu.markAsWatched' => 'Mark as Watched',
			'mediaMenu.markAsUnwatched' => 'Mark as Unwatched',
			'mediaMenu.removeFromContinueWatching' => 'Remove from Continue Watching',
			'mediaMenu.goToSeries' => 'Go to series',
			'mediaMenu.goToSeason' => 'Go to season',
			'mediaMenu.shufflePlay' => 'Shuffle Play',
			'mediaMenu.fileInfo' => 'File Info',
			'mediaMenu.deleteFromServer' => 'Delete from server',
			'mediaMenu.confirmDelete' => 'This will permanently delete this media and its files from your server. This cannot be undone.',
			'mediaMenu.deleteMultipleWarning' => 'This includes all episodes and their files.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Media item deleted successfully',
			'mediaMenu.mediaFailedToDelete' => 'Failed to delete media item',
			'mediaMenu.rate' => 'Rate',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, movie',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, TV show',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'watched',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} percent watched',
			'accessibility.mediaCardUnwatched' => 'unwatched',
			'accessibility.tapToPlay' => 'Tap to play',
			'tooltips.shufflePlay' => 'Shuffle play',
			'tooltips.playTrailer' => 'Play trailer',
			'tooltips.markAsWatched' => 'Mark as watched',
			'tooltips.markAsUnwatched' => 'Mark as unwatched',
			'videoControls.audioLabel' => 'Audio',
			'videoControls.subtitlesLabel' => 'Subtitles',
			'videoControls.resetToZero' => 'Reset to 0ms',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount}${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label} plays later',
			'videoControls.playsEarlier' => ({required Object label}) => '${label} plays earlier',
			'videoControls.noOffset' => 'No offset',
			'videoControls.letterbox' => 'Letterbox',
			'videoControls.fillScreen' => 'Fill screen',
			'videoControls.stretch' => 'Stretch',
			'videoControls.lockRotation' => 'Lock rotation',
			'videoControls.unlockRotation' => 'Unlock rotation',
			'videoControls.timerActive' => 'Timer Active',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Playback will pause in ${duration}',
			'videoControls.sleepTimerCompleted' => 'Sleep timer completed - playback paused',
			'videoControls.stillWatching' => 'Still watching?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Pausing in ${seconds}s',
			'videoControls.continueWatching' => 'Continue',
			'videoControls.autoPlayNext' => 'Auto-Play Next',
			'videoControls.playNext' => 'Play Next',
			'videoControls.playButton' => 'Play',
			'videoControls.pauseButton' => 'Pause',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Seek backward ${seconds} seconds',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Seek forward ${seconds} seconds',
			'videoControls.previousButton' => 'Previous episode',
			'videoControls.nextButton' => 'Next episode',
			'videoControls.previousChapterButton' => 'Previous chapter',
			'videoControls.nextChapterButton' => 'Next chapter',
			'videoControls.muteButton' => 'Mute',
			'videoControls.unmuteButton' => 'Unmute',
			'videoControls.settingsButton' => 'Video settings',
			'videoControls.audioTrackButton' => 'Audio tracks',
			'videoControls.subtitlesButton' => 'Subtitles',
			'videoControls.chaptersButton' => 'Chapters',
			'videoControls.versionsButton' => 'Video versions',
			'videoControls.pipButton' => 'Picture-in-Picture mode',
			'videoControls.aspectRatioButton' => 'Aspect ratio',
			'videoControls.ambientLighting' => 'Ambient lighting',
			'videoControls.ambientLightingOn' => 'Enable ambient lighting',
			'videoControls.ambientLightingOff' => 'Disable ambient lighting',
			'videoControls.fullscreenButton' => 'Enter fullscreen',
			'videoControls.exitFullscreenButton' => 'Exit fullscreen',
			'videoControls.alwaysOnTopButton' => 'Always on top',
			'videoControls.rotationLockButton' => 'Rotation lock',
			'videoControls.timelineSlider' => 'Video timeline',
			'videoControls.volumeSlider' => 'Volume level',
			'videoControls.endsAt' => ({required Object time}) => 'Ends at ${time}',
			'videoControls.pipFailed' => 'Picture-in-picture failed to start',
			'videoControls.pipErrors.androidVersion' => 'Requires Android 8.0 or newer',
			'videoControls.pipErrors.permissionDisabled' => 'Picture-in-picture permission is disabled. Enable it in Settings > Apps > Plezy > Picture-in-picture',
			'videoControls.pipErrors.notSupported' => 'Device doesn\'t support picture-in-picture mode',
			'videoControls.pipErrors.failed' => 'Picture-in-picture failed to start',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'An error occurred: ${error}',
			'videoControls.chapters' => 'Chapters',
			'videoControls.noChaptersAvailable' => 'No chapters available',
			'videoControls.queue' => 'Queue',
			'videoControls.noQueueItems' => 'No items in queue',
			'userStatus.admin' => 'Admin',
			'userStatus.restricted' => 'Restricted',
			'userStatus.protected' => 'Protected',
			'userStatus.current' => 'CURRENT',
			'messages.markedAsWatched' => 'Marked as watched',
			'messages.markedAsUnwatched' => 'Marked as unwatched',
			'messages.markedAsWatchedOffline' => 'Marked as watched (will sync when online)',
			'messages.markedAsUnwatchedOffline' => 'Marked as unwatched (will sync when online)',
			'messages.removedFromContinueWatching' => 'Removed from Continue Watching',
			'messages.errorLoading' => ({required Object error}) => 'Error: ${error}',
			'messages.fileInfoNotAvailable' => 'File information not available',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Error loading file info: ${error}',
			'messages.errorLoadingSeries' => 'Error loading series',
			'messages.errorLoadingSeason' => 'Error loading season',
			'messages.musicNotSupported' => 'Music playback is not yet supported',
			'messages.logsCleared' => 'Logs cleared',
			'messages.logsCopied' => 'Logs copied to clipboard',
			'messages.noLogsAvailable' => 'No logs available',
			'messages.libraryScanning' => ({required Object title}) => 'Scanning "${title}"...',
			'messages.libraryScanStarted' => ({required Object title}) => 'Library scan started for "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Failed to scan library: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Refreshing metadata for "${title}"...',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Metadata refresh started for "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Failed to refresh metadata: ${error}',
			'messages.logoutConfirm' => 'Are you sure you want to logout?',
			'messages.noSeasonsFound' => 'No seasons found',
			'messages.noEpisodesFound' => 'No episodes found in first season',
			'messages.noEpisodesFoundGeneral' => 'No episodes found',
			'messages.noResultsFound' => 'No results found',
			'messages.sleepTimerSet' => ({required Object label}) => 'Sleep timer set for ${label}',
			'messages.noItemsAvailable' => 'No items available',
			'messages.failedToCreatePlayQueueNoItems' => 'Failed to create play queue - no items',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Failed to ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Switching to compatible player...',
			'messages.logsUploaded' => 'Logs uploaded',
			'messages.logsUploadFailed' => 'Failed to upload logs',
			'messages.logId' => 'Log ID',
			'subtitlingStyling.stylingOptions' => 'Styling Options',
			'subtitlingStyling.fontSize' => 'Font Size',
			'subtitlingStyling.textColor' => 'Text Color',
			'subtitlingStyling.borderSize' => 'Border Size',
			'subtitlingStyling.borderColor' => 'Border Color',
			'subtitlingStyling.backgroundOpacity' => 'Background Opacity',
			'subtitlingStyling.backgroundColor' => 'Background Color',
			'subtitlingStyling.position' => 'Position',
			'mpvConfig.title' => 'MPV Configuration',
			'mpvConfig.description' => 'Advanced video player settings',
			'mpvConfig.properties' => 'Properties',
			'mpvConfig.presets' => 'Presets',
			'mpvConfig.noProperties' => 'No properties configured',
			'mpvConfig.noPresets' => 'No saved presets',
			'mpvConfig.addProperty' => 'Add Property',
			'mpvConfig.editProperty' => 'Edit Property',
			'mpvConfig.deleteProperty' => 'Delete Property',
			'mpvConfig.propertyKey' => 'Property Key',
			'mpvConfig.propertyKeyHint' => 'e.g., hwdec, demuxer-max-bytes',
			'mpvConfig.propertyValue' => 'Property Value',
			'mpvConfig.propertyValueHint' => 'e.g., auto, 256000000',
			'mpvConfig.saveAsPreset' => 'Save as Preset...',
			'mpvConfig.presetName' => 'Preset Name',
			'mpvConfig.presetNameHint' => 'Enter a name for this preset',
			'mpvConfig.loadPreset' => 'Load',
			'mpvConfig.deletePreset' => 'Delete',
			'mpvConfig.presetSaved' => 'Preset saved',
			'mpvConfig.presetLoaded' => 'Preset loaded',
			'mpvConfig.presetDeleted' => 'Preset deleted',
			'mpvConfig.confirmDeletePreset' => 'Are you sure you want to delete this preset?',
			'mpvConfig.confirmDeleteProperty' => 'Are you sure you want to delete this property?',
			'mpvConfig.entriesCount' => ({required Object count}) => '${count} entries',
			'dialog.confirmAction' => 'Confirm Action',
			'discover.title' => 'Discover',
			'discover.switchProfile' => 'Switch Profile',
			'discover.noContentAvailable' => 'No content available',
			'discover.addMediaToLibraries' => 'Add some media to your libraries',
			'discover.continueWatching' => 'Continue Watching',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Overview',
			'discover.cast' => 'Cast',
			'discover.extras' => 'Trailers & Extras',
			'discover.seasons' => 'Seasons',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Rating',
			'discover.episodeCount' => ({required Object count}) => '${count} episodes',
			'discover.watchedProgress' => ({required Object watched, required Object total}) => '${watched}/${total} watched',
			'discover.movie' => 'Movie',
			'discover.tvShow' => 'TV Show',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} min left',
			'errors.searchFailed' => ({required Object error}) => 'Search failed: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => 'Connection timeout while loading ${context}',
			'errors.connectionFailed' => 'Unable to connect to Plex server',
			'errors.failedToLoad' => ({required Object context, required Object error}) => 'Failed to load ${context}: ${error}',
			'errors.noClientAvailable' => 'No client available',
			'errors.authenticationFailed' => ({required Object error}) => 'Authentication failed: ${error}',
			'errors.couldNotLaunchUrl' => 'Could not launch auth URL',
			'errors.pleaseEnterToken' => 'Please enter a token',
			'errors.invalidToken' => 'Invalid token',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Failed to verify token: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Failed to switch to ${displayName}',
			'libraries.title' => 'Libraries',
			'libraries.scanLibraryFiles' => 'Scan Library Files',
			'libraries.scanLibrary' => 'Scan Library',
			'libraries.analyze' => 'Analyze',
			'libraries.analyzeLibrary' => 'Analyze Library',
			'libraries.refreshMetadata' => 'Refresh Metadata',
			'libraries.emptyTrash' => 'Empty Trash',
			'libraries.emptyingTrash' => ({required Object title}) => 'Emptying trash for "${title}"...',
			'libraries.trashEmptied' => ({required Object title}) => 'Trash emptied for "${title}"',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Failed to empty trash: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'Analyzing "${title}"...',
			'libraries.analysisStarted' => ({required Object title}) => 'Analysis started for "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Failed to analyze library: ${error}',
			'libraries.noLibrariesFound' => 'No libraries found',
			'libraries.thisLibraryIsEmpty' => 'This library is empty',
			'libraries.all' => 'All',
			'libraries.clearAll' => 'Clear All',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'Are you sure you want to scan "${title}"?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'Are you sure you want to analyze "${title}"?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'Are you sure you want to refresh metadata for "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'Are you sure you want to empty trash for "${title}"?',
			'libraries.manageLibraries' => 'Manage Libraries',
			'libraries.sort' => 'Sort',
			'libraries.sortBy' => 'Sort By',
			'libraries.filters' => 'Filters',
			'libraries.confirmActionMessage' => 'Are you sure you want to perform this action?',
			'libraries.showLibrary' => 'Show library',
			'libraries.hideLibrary' => 'Hide library',
			'libraries.libraryOptions' => 'Library options',
			'libraries.content' => 'library content',
			'libraries.selectLibrary' => 'Select library',
			'libraries.filtersWithCount' => ({required Object count}) => 'Filters (${count})',
			'libraries.noRecommendations' => 'No recommendations available',
			'libraries.noCollections' => 'No collections in this library',
			'libraries.noFoldersFound' => 'No folders found',
			'libraries.folders' => 'folders',
			'libraries.tabs.recommended' => 'Recommended',
			'libraries.tabs.browse' => 'Browse',
			'libraries.tabs.collections' => 'Collections',
			'libraries.tabs.playlists' => 'Playlists',
			'libraries.groupings.all' => 'All',
			'libraries.groupings.movies' => 'Movies',
			'libraries.groupings.shows' => 'TV Shows',
			'libraries.groupings.seasons' => 'Seasons',
			'libraries.groupings.episodes' => 'Episodes',
			'libraries.groupings.folders' => 'Folders',
			'about.title' => 'About',
			'about.openSourceLicenses' => 'Open Source Licenses',
			'about.versionLabel' => ({required Object version}) => 'Version ${version}',
			'about.appDescription' => 'A beautiful Plex client for Flutter',
			'about.viewLicensesDescription' => 'View licenses of third-party libraries',
			'serverSelection.allServerConnectionsFailed' => 'Failed to connect to any servers. Please check your network and try again.',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'No servers found for ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Failed to load servers: ${error}',
			'hubDetail.title' => 'Title',
			'hubDetail.releaseYear' => 'Release Year',
			'hubDetail.dateAdded' => 'Date Added',
			'hubDetail.rating' => 'Rating',
			'hubDetail.noItemsFound' => 'No items found',
			'logs.clearLogs' => 'Clear Logs',
			'logs.copyLogs' => 'Copy Logs',
			'logs.uploadLogs' => 'Upload Logs',
			'logs.error' => 'Error:',
			'logs.stackTrace' => 'Stack Trace:',
			'licenses.relatedPackages' => 'Related Packages',
			'licenses.license' => 'License',
			'licenses.licenseNumber' => ({required Object number}) => 'License ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licenses',
			'navigation.libraries' => 'Libraries',
			'navigation.downloads' => 'Downloads',
			'navigation.liveTv' => 'Live TV',
			'liveTv.title' => 'Live TV',
			'liveTv.channels' => 'Channels',
			'liveTv.guide' => 'Guide',
			'liveTv.noChannels' => 'No channels available',
			'liveTv.noDvr' => 'No DVR configured on any server',
			'liveTv.tuneFailed' => 'Failed to tune channel',
			'liveTv.loading' => 'Loading channels...',
			'liveTv.nowPlaying' => 'Now Playing',
			'liveTv.noPrograms' => 'No program data available',
			'liveTv.channelNumber' => ({required Object number}) => 'Ch. ${number}',
			'liveTv.live' => 'LIVE',
			'liveTv.hd' => 'HD',
			'liveTv.premiere' => 'NEW',
			'liveTv.reloadGuide' => 'Reload Guide',
			'liveTv.allChannels' => 'All Channels',
			'liveTv.now' => 'Now',
			'liveTv.today' => 'Today',
			'liveTv.midnight' => 'Midnight',
			'liveTv.overnight' => 'Overnight',
			'liveTv.morning' => 'Morning',
			'liveTv.daytime' => 'Daytime',
			'liveTv.evening' => 'Evening',
			'liveTv.lateNight' => 'Late Night',
			'liveTv.whatsOn' => 'What\'s On',
			_ => null,
		} ?? switch (path) {
			'liveTv.watchChannel' => 'Watch Channel',
			'collections.title' => 'Collections',
			'collections.collection' => 'Collection',
			'collections.empty' => 'Collection is empty',
			'collections.unknownLibrarySection' => 'Cannot delete: Unknown library section',
			'collections.deleteCollection' => 'Delete Collection',
			'collections.deleteConfirm' => ({required Object title}) => 'Are you sure you want to delete "${title}"? This action cannot be undone.',
			'collections.deleted' => 'Collection deleted',
			'collections.deleteFailed' => 'Failed to delete collection',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Failed to delete collection: ${error}',
			'collections.failedToLoadItems' => ({required Object error}) => 'Failed to load collection items: ${error}',
			'collections.selectCollection' => 'Select Collection',
			'collections.createNewCollection' => 'Create New Collection',
			'collections.collectionName' => 'Collection Name',
			'collections.enterCollectionName' => 'Enter collection name',
			'collections.addedToCollection' => 'Added to collection',
			'collections.errorAddingToCollection' => 'Failed to add to collection',
			'collections.created' => 'Collection created',
			'collections.removeFromCollection' => 'Remove from collection',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => 'Remove "${title}" from this collection?',
			'collections.removedFromCollection' => 'Removed from collection',
			'collections.removeFromCollectionFailed' => 'Failed to remove from collection',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Error removing from collection: ${error}',
			'playlists.title' => 'Playlists',
			'playlists.playlist' => 'Playlist',
			'playlists.noPlaylists' => 'No playlists found',
			'playlists.create' => 'Create Playlist',
			'playlists.playlistName' => 'Playlist Name',
			'playlists.enterPlaylistName' => 'Enter playlist name',
			'playlists.delete' => 'Delete Playlist',
			'playlists.removeItem' => 'Remove from Playlist',
			'playlists.smartPlaylist' => 'Smart Playlist',
			'playlists.itemCount' => ({required Object count}) => '${count} items',
			'playlists.oneItem' => '1 item',
			'playlists.emptyPlaylist' => 'This playlist is empty',
			'playlists.deleteConfirm' => 'Delete Playlist?',
			'playlists.deleteMessage' => ({required Object name}) => 'Are you sure you want to delete "${name}"?',
			'playlists.created' => 'Playlist created',
			'playlists.deleted' => 'Playlist deleted',
			'playlists.itemAdded' => 'Added to playlist',
			'playlists.itemRemoved' => 'Removed from playlist',
			'playlists.selectPlaylist' => 'Select Playlist',
			'playlists.createNewPlaylist' => 'Create New Playlist',
			'playlists.errorCreating' => 'Failed to create playlist',
			'playlists.errorDeleting' => 'Failed to delete playlist',
			'playlists.errorLoading' => 'Failed to load playlists',
			'playlists.errorAdding' => 'Failed to add to playlist',
			'playlists.errorReordering' => 'Failed to reorder playlist item',
			'playlists.errorRemoving' => 'Failed to remove from playlist',
			'watchTogether.title' => 'Watch Together',
			'watchTogether.description' => 'Watch content in sync with friends and family',
			'watchTogether.createSession' => 'Create Session',
			'watchTogether.creating' => 'Creating...',
			'watchTogether.joinSession' => 'Join Session',
			'watchTogether.joining' => 'Joining...',
			'watchTogether.controlMode' => 'Control Mode',
			'watchTogether.controlModeQuestion' => 'Who can control playback?',
			'watchTogether.hostOnly' => 'Host Only',
			'watchTogether.anyone' => 'Anyone',
			'watchTogether.hostingSession' => 'Hosting Session',
			'watchTogether.inSession' => 'In Session',
			'watchTogether.sessionCode' => 'Session Code',
			'watchTogether.hostControlsPlayback' => 'Host controls playback',
			'watchTogether.anyoneCanControl' => 'Anyone can control playback',
			'watchTogether.hostControls' => 'Host controls',
			'watchTogether.anyoneControls' => 'Anyone controls',
			'watchTogether.participants' => 'Participants',
			'watchTogether.host' => 'Host',
			'watchTogether.hostBadge' => 'HOST',
			'watchTogether.youAreHost' => 'You are the host',
			'watchTogether.watchingWithOthers' => 'Watching with others',
			'watchTogether.endSession' => 'End Session',
			'watchTogether.leaveSession' => 'Leave Session',
			'watchTogether.endSessionQuestion' => 'End Session?',
			'watchTogether.leaveSessionQuestion' => 'Leave Session?',
			'watchTogether.endSessionConfirm' => 'This will end the session for all participants.',
			'watchTogether.leaveSessionConfirm' => 'You will be removed from the session.',
			'watchTogether.endSessionConfirmOverlay' => 'This will end the watch session for all participants.',
			'watchTogether.leaveSessionConfirmOverlay' => 'You will be disconnected from the watch session.',
			'watchTogether.end' => 'End',
			'watchTogether.leave' => 'Leave',
			'watchTogether.syncing' => 'Syncing...',
			'watchTogether.joinWatchSession' => 'Join Watch Session',
			'watchTogether.enterCodeHint' => 'Enter 8-character code',
			'watchTogether.pasteFromClipboard' => 'Paste from clipboard',
			'watchTogether.pleaseEnterCode' => 'Please enter a session code',
			'watchTogether.codeMustBe8Chars' => 'Session code must be 8 characters',
			'watchTogether.joinInstructions' => 'Enter the session code shared by the host to join their watch session.',
			'watchTogether.failedToCreate' => 'Failed to create session',
			'watchTogether.failedToJoin' => 'Failed to join session',
			'watchTogether.sessionCodeCopied' => 'Session code copied to clipboard',
			'watchTogether.relayUnreachable' => 'The relay server is unreachable. This may be caused by your ISP blocking the connection. You can still try, but Watch Together may not work.',
			'watchTogether.reconnectingToHost' => 'Reconnecting to host...',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} joined',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} left',
			'downloads.title' => 'Downloads',
			'downloads.manage' => 'Manage',
			'downloads.tvShows' => 'TV Shows',
			'downloads.movies' => 'Movies',
			'downloads.noDownloads' => 'No downloads yet',
			'downloads.noDownloadsDescription' => 'Downloaded content will appear here for offline viewing',
			'downloads.downloadNow' => 'Download',
			'downloads.deleteDownload' => 'Delete download',
			'downloads.retryDownload' => 'Retry download',
			'downloads.downloadQueued' => 'Download queued',
			'downloads.episodesQueued' => ({required Object count}) => '${count} episodes queued for download',
			'downloads.downloadDeleted' => 'Download deleted',
			'downloads.deleteConfirm' => ({required Object title}) => 'Are you sure you want to delete "${title}"? This will remove the downloaded file from your device.',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Deleting ${title}... (${current} of ${total})',
			'downloads.noDownloadsTree' => 'No downloads',
			'downloads.pauseAll' => 'Pause all',
			'downloads.resumeAll' => 'Resume all',
			'downloads.deleteAll' => 'Delete all',
			'shaders.title' => 'Shaders',
			'shaders.noShaderDescription' => 'No video enhancement',
			'shaders.nvscalerDescription' => 'NVIDIA image scaling for sharper video',
			'shaders.qualityFast' => 'Fast',
			'shaders.qualityHQ' => 'High Quality',
			'shaders.mode' => 'Mode',
			'companionRemote.title' => 'Companion Remote',
			'companionRemote.connectToDevice' => 'Connect to Device',
			'companionRemote.hostRemoteSession' => 'Host Remote Session',
			'companionRemote.controlThisDevice' => 'Control this device with your phone',
			'companionRemote.remoteControl' => 'Remote Control',
			'companionRemote.controlDesktop' => 'Control a desktop device',
			'companionRemote.connectedTo' => ({required Object name}) => 'Connected to ${name}',
			'companionRemote.session.creatingSession' => 'Creating remote session...',
			'companionRemote.session.failedToCreate' => 'Failed to create remote session:',
			'companionRemote.session.noSession' => 'No session available',
			'companionRemote.session.scanQrCode' => 'Scan QR Code',
			'companionRemote.session.orEnterManually' => 'Or enter manually',
			'companionRemote.session.hostAddress' => 'Host Address',
			'companionRemote.session.sessionId' => 'Session ID',
			'companionRemote.session.pin' => 'PIN',
			'companionRemote.session.connected' => 'Connected',
			'companionRemote.session.waitingForConnection' => 'Waiting for connection...',
			'companionRemote.session.usePhoneToControl' => 'Use your mobile device to control this app',
			'companionRemote.session.copiedToClipboard' => ({required Object label}) => '${label} copied to clipboard',
			'companionRemote.session.copyToClipboard' => 'Copy to clipboard',
			'companionRemote.session.newSession' => 'New Session',
			'companionRemote.session.minimize' => 'Minimize',
			'companionRemote.pairing.scan' => 'Scan',
			'companionRemote.pairing.manual' => 'Manual',
			'companionRemote.pairing.pairWithDesktop' => 'Pair with Desktop',
			'companionRemote.pairing.enterSessionDetails' => 'Enter the session details shown on your desktop device',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.sessionIdHint' => 'Enter 8-character session ID',
			'companionRemote.pairing.pinHint' => 'Enter 6-digit PIN',
			'companionRemote.pairing.connecting' => 'Connecting...',
			'companionRemote.pairing.tips' => 'Tips',
			'companionRemote.pairing.tipDesktop' => 'Open Plezy on your desktop and enable Companion Remote from settings or menu',
			'companionRemote.pairing.tipScan' => 'Use the Scan tab to quickly pair by scanning the QR code on your desktop',
			'companionRemote.pairing.tipWifi' => 'Make sure both devices are on the same WiFi network',
			'companionRemote.pairing.cameraPermissionRequired' => 'Camera permission is required to scan QR codes.\nPlease grant camera access in your device settings.',
			'companionRemote.pairing.cameraError' => ({required Object error}) => 'Could not start camera: ${error}',
			'companionRemote.pairing.scanInstruction' => 'Point your camera at the QR code shown on your desktop',
			'companionRemote.pairing.invalidQrCode' => 'Invalid QR code format',
			'companionRemote.pairing.validationHostRequired' => 'Please enter host address',
			'companionRemote.pairing.validationHostFormat' => 'Format must be IP:port (e.g., 192.168.1.100:48632)',
			'companionRemote.pairing.validationSessionIdRequired' => 'Please enter a session ID',
			'companionRemote.pairing.validationSessionIdLength' => 'Session ID must be 8 characters',
			'companionRemote.pairing.validationPinRequired' => 'Please enter a PIN',
			'companionRemote.pairing.validationPinLength' => 'PIN must be 6 digits',
			'companionRemote.pairing.connectionTimedOut' => 'Connection timed out. Please check the session ID and PIN.',
			'companionRemote.pairing.sessionNotFound' => 'Could not find the session. Please check your credentials.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Failed to connect: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'Do you want to disconnect from the remote session?',
			'companionRemote.remote.reconnecting' => 'Reconnecting...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Attempt ${current} of 5',
			'companionRemote.remote.retryNow' => 'Retry Now',
			'companionRemote.remote.connectionError' => 'Connection error',
			'companionRemote.remote.notConnected' => 'Not connected',
			'companionRemote.remote.tabRemote' => 'Remote',
			'companionRemote.remote.tabPlay' => 'Play',
			'companionRemote.remote.tabMore' => 'More',
			'companionRemote.remote.menu' => 'Menu',
			'companionRemote.remote.tabNavigation' => 'Tab Navigation',
			'companionRemote.remote.tabDiscover' => 'Discover',
			'companionRemote.remote.tabLibraries' => 'Libraries',
			'companionRemote.remote.tabSearch' => 'Search',
			'companionRemote.remote.tabDownloads' => 'Downloads',
			'companionRemote.remote.tabSettings' => 'Settings',
			'companionRemote.remote.previous' => 'Previous',
			'companionRemote.remote.playPause' => 'Play/Pause',
			'companionRemote.remote.next' => 'Next',
			'companionRemote.remote.seekBack' => 'Seek Back',
			'companionRemote.remote.stop' => 'Stop',
			'companionRemote.remote.seekForward' => 'Seek Fwd',
			'companionRemote.remote.volume' => 'Volume',
			'companionRemote.remote.volumeDown' => 'Down',
			'companionRemote.remote.volumeUp' => 'Up',
			'companionRemote.remote.fullscreen' => 'Fullscreen',
			'companionRemote.remote.subtitles' => 'Subtitles',
			'companionRemote.remote.audio' => 'Audio',
			'companionRemote.remote.searchHint' => 'Search on desktop...',
			'videoSettings.playbackSettings' => 'Playback Settings',
			'videoSettings.playbackSpeed' => 'Playback Speed',
			'videoSettings.sleepTimer' => 'Sleep Timer',
			'videoSettings.audioSync' => 'Audio Sync',
			'videoSettings.subtitleSync' => 'Subtitle Sync',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => 'Audio Output',
			'videoSettings.performanceOverlay' => 'Performance Overlay',
			'videoSettings.audioPassthrough' => 'Audio Passthrough',
			'videoSettings.audioNormalization' => 'Audio Normalization',
			'externalPlayer.title' => 'External Player',
			'externalPlayer.useExternalPlayer' => 'Use External Player',
			'externalPlayer.useExternalPlayerDescription' => 'Open videos in an external app instead of the built-in player',
			'externalPlayer.selectPlayer' => 'Select Player',
			'externalPlayer.systemDefault' => 'System Default',
			'externalPlayer.addCustomPlayer' => 'Add Custom Player',
			'externalPlayer.playerName' => 'Player Name',
			'externalPlayer.playerCommand' => 'Command',
			'externalPlayer.playerPackage' => 'Package Name',
			'externalPlayer.playerUrlScheme' => 'URL Scheme',
			'externalPlayer.customPlayer' => 'Custom Player',
			'externalPlayer.off' => 'Off',
			'externalPlayer.launchFailed' => 'Failed to open external player',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} is not installed',
			'externalPlayer.playInExternalPlayer' => 'Play in External Player',
			'metadataEdit.editMetadata' => 'Edit...',
			'metadataEdit.screenTitle' => 'Edit Metadata',
			'metadataEdit.basicInfo' => 'Basic Info',
			'metadataEdit.artwork' => 'Artwork',
			'metadataEdit.advancedSettings' => 'Advanced Settings',
			'metadataEdit.title' => 'Title',
			'metadataEdit.sortTitle' => 'Sort Title',
			'metadataEdit.originalTitle' => 'Original Title',
			'metadataEdit.releaseDate' => 'Release Date',
			'metadataEdit.contentRating' => 'Content Rating',
			'metadataEdit.studio' => 'Studio',
			'metadataEdit.tagline' => 'Tagline',
			'metadataEdit.summary' => 'Summary',
			'metadataEdit.poster' => 'Poster',
			'metadataEdit.background' => 'Background',
			'metadataEdit.selectPoster' => 'Select Poster',
			'metadataEdit.selectBackground' => 'Select Background',
			'metadataEdit.fromUrl' => 'From URL',
			'metadataEdit.uploadFile' => 'Upload File',
			'metadataEdit.enterImageUrl' => 'Enter image URL',
			'metadataEdit.imageUrl' => 'Image URL',
			'metadataEdit.metadataUpdated' => 'Metadata updated',
			'metadataEdit.metadataUpdateFailed' => 'Failed to update metadata',
			'metadataEdit.artworkUpdated' => 'Artwork updated',
			'metadataEdit.artworkUpdateFailed' => 'Failed to update artwork',
			'metadataEdit.noArtworkAvailable' => 'No artwork available',
			'metadataEdit.notSet' => 'Not set',
			'metadataEdit.libraryDefault' => 'Library default',
			'metadataEdit.accountDefault' => 'Account default',
			'metadataEdit.seriesDefault' => 'Series default',
			'metadataEdit.episodeSorting' => 'Episode Sorting',
			'metadataEdit.oldestFirst' => 'Oldest first',
			'metadataEdit.newestFirst' => 'Newest first',
			'metadataEdit.keep' => 'Keep',
			'metadataEdit.allEpisodes' => 'All episodes',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} latest episodes',
			'metadataEdit.latestEpisode' => 'Latest episode',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Episodes added in the past ${count} days',
			'metadataEdit.deleteAfterPlaying' => 'Delete Episodes After Playing',
			'metadataEdit.never' => 'Never',
			'metadataEdit.afterADay' => 'After a day',
			'metadataEdit.afterAWeek' => 'After a week',
			'metadataEdit.afterAMonth' => 'After a month',
			'metadataEdit.onNextRefresh' => 'On next refresh',
			'metadataEdit.seasons' => 'Seasons',
			'metadataEdit.show' => 'Show',
			'metadataEdit.hide' => 'Hide',
			'metadataEdit.episodeOrdering' => 'Episode Ordering',
			'metadataEdit.tmdbAiring' => 'The Movie Database (Aired)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (Aired)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (Absolute)',
			'metadataEdit.metadataLanguage' => 'Metadata Language',
			'metadataEdit.useOriginalTitle' => 'Use Original Title',
			'metadataEdit.preferredAudioLanguage' => 'Preferred Audio Language',
			'metadataEdit.preferredSubtitleLanguage' => 'Preferred Subtitle Language',
			'metadataEdit.subtitleMode' => 'Auto-Select Subtitle Mode',
			'metadataEdit.manuallySelected' => 'Manually selected',
			'metadataEdit.shownWithForeignAudio' => 'Shown with foreign audio',
			'metadataEdit.alwaysEnabled' => 'Always enabled',
			_ => null,
		};
	}
}
