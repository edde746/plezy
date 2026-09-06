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
	late final Translations$app$en app = Translations$app$en.internal(_root);
	late final Translations$auth$en auth = Translations$auth$en.internal(_root);
	late final Translations$common$en common = Translations$common$en.internal(_root);
	late final Translations$screens$en screens = Translations$screens$en.internal(_root);
	late final Translations$update$en update = Translations$update$en.internal(_root);
	late final Translations$settings$en settings = Translations$settings$en.internal(_root);
	late final Translations$search$en search = Translations$search$en.internal(_root);
	late final Translations$hotkeys$en hotkeys = Translations$hotkeys$en.internal(_root);
	late final Translations$fileInfo$en fileInfo = Translations$fileInfo$en.internal(_root);
	late final Translations$mediaMenu$en mediaMenu = Translations$mediaMenu$en.internal(_root);
	late final Translations$rateSheet$en rateSheet = Translations$rateSheet$en.internal(_root);
	late final Translations$accessibility$en accessibility = Translations$accessibility$en.internal(_root);
	late final Translations$tooltips$en tooltips = Translations$tooltips$en.internal(_root);
	late final Translations$audioTracks$en audioTracks = Translations$audioTracks$en.internal(_root);
	late final Translations$videoControls$en videoControls = Translations$videoControls$en.internal(_root);
	late final Translations$messages$en messages = Translations$messages$en.internal(_root);
	late final Translations$subtitlingStyling$en subtitlingStyling = Translations$subtitlingStyling$en.internal(_root);
	late final Translations$mpvConfig$en mpvConfig = Translations$mpvConfig$en.internal(_root);
	late final Translations$dialog$en dialog = Translations$dialog$en.internal(_root);
	late final Translations$profiles$en profiles = Translations$profiles$en.internal(_root);
	late final Translations$connections$en connections = Translations$connections$en.internal(_root);
	late final Translations$accountPreferences$en accountPreferences = Translations$accountPreferences$en.internal(_root);
	late final Translations$discover$en discover = Translations$discover$en.internal(_root);
	late final Translations$errors$en errors = Translations$errors$en.internal(_root);
	late final Translations$libraries$en libraries = Translations$libraries$en.internal(_root);
	late final Translations$about$en about = Translations$about$en.internal(_root);
	late final Translations$serverSelection$en serverSelection = Translations$serverSelection$en.internal(_root);
	late final Translations$hubDetail$en hubDetail = Translations$hubDetail$en.internal(_root);
	late final Translations$logs$en logs = Translations$logs$en.internal(_root);
	late final Translations$startup$en startup = Translations$startup$en.internal(_root);
	late final Translations$licenses$en licenses = Translations$licenses$en.internal(_root);
	late final Translations$navigation$en navigation = Translations$navigation$en.internal(_root);
	late final Translations$explore$en explore = Translations$explore$en.internal(_root);
	late final Translations$liveTv$en liveTv = Translations$liveTv$en.internal(_root);
	late final Translations$collections$en collections = Translations$collections$en.internal(_root);
	late final Translations$playlists$en playlists = Translations$playlists$en.internal(_root);
	late final Translations$music$en music = Translations$music$en.internal(_root);
	late final Translations$watchTogether$en watchTogether = Translations$watchTogether$en.internal(_root);
	late final Translations$downloads$en downloads = Translations$downloads$en.internal(_root);
	late final Translations$shaders$en shaders = Translations$shaders$en.internal(_root);
	late final Translations$companionRemote$en companionRemote = Translations$companionRemote$en.internal(_root);
	late final Translations$videoSettings$en videoSettings = Translations$videoSettings$en.internal(_root);
	late final Translations$performanceOverlay$en performanceOverlay = Translations$performanceOverlay$en.internal(_root);
	late final Translations$externalPlayer$en externalPlayer = Translations$externalPlayer$en.internal(_root);
	late final Translations$metadataEdit$en metadataEdit = Translations$metadataEdit$en.internal(_root);
	late final Translations$matchScreen$en matchScreen = Translations$matchScreen$en.internal(_root);
	late final Translations$serverTasks$en serverTasks = Translations$serverTasks$en.internal(_root);
	late final Translations$trakt$en trakt = Translations$trakt$en.internal(_root);
	late final Translations$seerr$en seerr = Translations$seerr$en.internal(_root);
	late final Translations$services$en services = Translations$services$en.internal(_root);
	late final Translations$addServer$en addServer = Translations$addServer$en.internal(_root);
}

// Path: app
class Translations$app$en {
	Translations$app$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Plezy'
	String get title => 'Plezy';
}

// Path: auth
class Translations$auth$en {
	Translations$auth$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Sign in with Plex'
	String get signInWithPlex => 'Sign in with Plex';

	/// en: 'Show QR Code'
	String get showQRCode => 'Show QR Code';

	/// en: 'Authenticate'
	String get authenticate => 'Authenticate';

	/// en: 'Authentication timed out. Please try again.'
	String get authenticationTimeout => 'Authentication timed out. Please try again.';

	/// en: 'Scan this QR code to sign in'
	String get scanQRToSignIn => 'Scan this QR code to sign in';

	/// en: 'Waiting for authentication... Sign in from your browser.'
	String get waitingForAuth => 'Waiting for authentication...\nSign in from your browser.';

	/// en: 'Use browser'
	String get useBrowser => 'Use browser';

	/// en: 'or'
	String get or => 'or';

	/// en: 'Connect to ${product}'
	String connectToMediaBrowser({required Object product}) => 'Connect to ${product}';

	/// en: 'Quick Connect'
	String get quickConnect => 'Quick Connect';

	/// en: 'Use Quick Connect'
	String get useQuickConnect => 'Use Quick Connect';

	/// en: 'Open Quick Connect in Jellyfin and enter this code.'
	String get quickConnectInstructions => 'Open Quick Connect in Jellyfin and enter this code.';

	/// en: 'Waiting for approval…'
	String get quickConnectWaiting => 'Waiting for approval…';

	/// en: 'Cancel'
	String get quickConnectCancel => 'Cancel';

	/// en: 'Quick Connect expired. Try again.'
	String get quickConnectExpired => 'Quick Connect expired. Try again.';

	/// en: 'Plezy could not safely recover local sign-in and pending playback data. Please sign in again.'
	String get localDataRecoveryRequired => 'Plezy could not safely recover local sign-in and pending playback data. Please sign in again.';

	/// en: 'The Plex PIN check was rejected'
	String get pinCheckRejected => 'The Plex PIN check was rejected';
}

// Path: common
class Translations$common$en {
	Translations$common$en.internal(this._root);

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

	/// en: 'Log out'
	String get logout => 'Log out';

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

	/// en: 'Edit'
	String get edit => 'Edit';

	/// en: 'Shuffle'
	String get shuffle => 'Shuffle';

	/// en: 'Add to...'
	String get addTo => 'Add to...';

	/// en: 'Create new'
	String get createNew => 'Create new';

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

	/// en: 'Off'
	String get off => 'Off';

	/// en: 'Options'
	String get options => 'Options';

	/// en: 'Season ${number}'
	String seasonNumber({required Object number}) => 'Season ${number}';

	/// en: 'Episode ${number} - ${title}'
	String episodeNumberTitle({required Object number, required Object title}) => 'Episode ${number} - ${title}';

	/// en: 'Chapter ${number}'
	String chapterNumber({required Object number}) => 'Chapter ${number}';

	/// en: 'Reconnect'
	String get reconnect => 'Reconnect';

	/// en: 'View All'
	String get viewAll => 'View All';

	/// en: 'Checking network...'
	String get checkingNetwork => 'Checking network...';

	/// en: 'Loading servers...'
	String get loadingServers => 'Loading servers...';

	/// en: 'Connecting to servers...'
	String get connectingToServers => 'Connecting to servers...';

	/// en: 'Starting offline mode...'
	String get startingOfflineMode => 'Starting offline mode...';

	/// en: 'Loading...'
	String get loading => 'Loading...';

	/// en: 'Fullscreen'
	String get fullscreen => 'Fullscreen';

	/// en: 'Exit fullscreen'
	String get exitFullscreen => 'Exit fullscreen';

	/// en: 'Press back again to exit'
	String get pressBackAgainToExit => 'Press back again to exit';

	late final Translations$common$ratingSource$en ratingSource = Translations$common$ratingSource$en.internal(_root);

	/// en: 'N/A'
	String get notAvailable => 'N/A';

	/// en: 'URL'
	String get url => 'URL';

	/// en: 'ABC'
	String get letterKeys => 'ABC';

	late final Translations$common$mediaKind$en mediaKind = Translations$common$mediaKind$en.internal(_root);
}

// Path: screens
class Translations$screens$en {
	Translations$screens$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Licenses'
	String get licenses => 'Licenses';

	/// en: 'Switch Profile'
	String get switchProfile => 'Switch Profile';

	/// en: 'Subtitle Styling'
	String get subtitleStyling => 'Subtitle Styling';

	/// en: 'mpv.conf'
	String get mpvConfig => 'mpv.conf';

	/// en: 'Logs'
	String get logs => 'Logs';
}

// Path: update
class Translations$update$en {
	Translations$update$en.internal(this._root);

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
class Translations$settings$en {
	Translations$settings$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Settings'
	String get title => 'Settings';

	/// en: 'Support Plezy'
	String get supportDeveloper => 'Support Plezy';

	/// en: 'Donate via Liberapay to fund development'
	String get supportDeveloperDescription => 'Donate via Liberapay to fund development';

	/// en: 'Language'
	String get language => 'Language';

	/// en: 'Theme'
	String get theme => 'Theme';

	/// en: 'Appearance'
	String get appearance => 'Appearance';

	/// en: 'Video Playback'
	String get videoPlayback => 'Video Playback';

	/// en: 'Configure playback behavior'
	String get videoPlaybackDescription => 'Configure playback behavior';

	/// en: 'Advanced'
	String get advanced => 'Advanced';

	/// en: 'Episode Poster Style'
	String get episodePosterMode => 'Episode Poster Style';

	/// en: 'Series Poster'
	String get seriesPoster => 'Series Poster';

	/// en: 'Season Poster'
	String get seasonPoster => 'Season Poster';

	/// en: 'Thumbnail'
	String get episodeThumbnail => 'Thumbnail';

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

	/// en: 'Light'
	String get lightTheme => 'Light';

	/// en: 'Dark'
	String get darkTheme => 'Dark';

	/// en: 'OLED'
	String get oledTheme => 'OLED';

	/// en: 'Library Density'
	String get libraryDensity => 'Library Density';

	/// en: 'Display Scale'
	String get displayScale => 'Display Scale';

	/// en: 'Compact'
	String get compact => 'Compact';

	/// en: 'Comfortable'
	String get comfortable => 'Comfortable';

	/// en: 'Grid Spacing'
	String get gridSpacing => 'Grid Spacing';

	/// en: 'Tight'
	String get gridSpacingTight => 'Tight';

	/// en: 'Normal'
	String get gridSpacingNormal => 'Normal';

	/// en: 'Spacious'
	String get gridSpacingSpacious => 'Spacious';

	/// en: 'Corner Spotlight Backdrop'
	String get tvCornerSpotlightBackdrop => 'Corner Spotlight Backdrop';

	/// en: 'Show spotlight artwork in the top-right corner instead of filling the screen'
	String get tvCornerSpotlightBackdropDescription => 'Show spotlight artwork in the top-right corner instead of filling the screen';

	/// en: 'View Mode'
	String get viewMode => 'View Mode';

	/// en: 'Grid'
	String get gridView => 'Grid';

	/// en: 'List'
	String get listView => 'List';

	/// en: 'Show Hero Section'
	String get showHeroSection => 'Show Hero Section';

	/// en: 'Continue Watching Action'
	String get continueWatchingAction => 'Continue Watching Action';

	/// en: 'Play'
	String get continueWatchingPlay => 'Play';

	/// en: 'Open Details'
	String get continueWatchingDetails => 'Open Details';

	/// en: 'Episode Action'
	String get episodeAction => 'Episode Action';

	/// en: 'Play'
	String get episodePlay => 'Play';

	/// en: 'Open Details'
	String get episodeDetails => 'Open Details';

	/// en: 'Use Home Layout'
	String get useGlobalHubs => 'Use Home Layout';

	/// en: 'Show unified home hubs. Otherwise use library recommendations.'
	String get useGlobalHubsDescription => 'Show unified home hubs. Otherwise use library recommendations.';

	/// en: 'Show Server Name on Hubs'
	String get showServerNameOnHubs => 'Show Server Name on Hubs';

	/// en: 'Always show server names in hub titles.'
	String get showServerNameOnHubsDescription => 'Always show server names in hub titles.';

	/// en: 'Group Libraries by Server'
	String get groupLibrariesByServer => 'Group Libraries by Server';

	/// en: 'Group sidebar libraries under each media server.'
	String get groupLibrariesByServerDescription => 'Group sidebar libraries under each media server.';

	/// en: 'Always Keep Sidebar Open'
	String get alwaysKeepSidebarOpen => 'Always Keep Sidebar Open';

	/// en: 'Sidebar stays expanded and content area adjusts to fit'
	String get alwaysKeepSidebarOpenDescription => 'Sidebar stays expanded and content area adjusts to fit';

	/// en: 'Show Unwatched Count'
	String get showUnwatchedCount => 'Show Unwatched Count';

	/// en: 'Display unwatched episode count on shows and seasons'
	String get showUnwatchedCountDescription => 'Display unwatched episode count on shows and seasons';

	/// en: 'Show Watched Indicators'
	String get showWatchedIndicators => 'Show Watched Indicators';

	/// en: 'Display a checkmark on watched movies, shows, and episodes'
	String get showWatchedIndicatorsDescription => 'Display a checkmark on watched movies, shows, and episodes';

	/// en: 'Show Episode Number on Cards'
	String get showEpisodeNumberOnCards => 'Show Episode Number on Cards';

	/// en: 'Show season and episode number on episode cards'
	String get showEpisodeNumberOnCardsDescription => 'Show season and episode number on episode cards';

	/// en: 'Show Season Posters on Tabs'
	String get showSeasonPostersOnTabs => 'Show Season Posters on Tabs';

	/// en: 'Show each season's poster above its tab'
	String get showSeasonPostersOnTabsDescription => 'Show each season\'s poster above its tab';

	/// en: 'Full TV Cards'
	String get tvFullCardLayout => 'Full TV Cards';

	/// en: 'Use image-only TV cards with actor names overlaid'
	String get tvFullCardLayoutDescription => 'Use image-only TV cards with actor names overlaid';

	/// en: 'Focus Glow'
	String get focusGlow => 'Focus Glow';

	/// en: 'Draw a soft glow around the focused card'
	String get focusGlowDescription => 'Draw a soft glow around the focused card';

	/// en: 'Visual Effects'
	String get visualEffects => 'Visual Effects';

	/// en: 'Auto'
	String get visualEffectsAuto => 'Auto';

	/// en: 'Reduce effects automatically on low-power devices'
	String get visualEffectsAutoDescription => 'Reduce effects automatically on low-power devices';

	/// en: 'Full'
	String get visualEffectsFull => 'Full';

	/// en: 'Reduced'
	String get visualEffectsReduced => 'Reduced';

	/// en: 'Fewer animations and lower-resolution artwork'
	String get visualEffectsReducedDescription => 'Fewer animations and lower-resolution artwork';

	/// en: 'Hide Spoilers for Unwatched Episodes'
	String get hideSpoilers => 'Hide Spoilers for Unwatched Episodes';

	/// en: 'Blur thumbnails and descriptions for unwatched episodes'
	String get hideSpoilersDescription => 'Blur thumbnails and descriptions for unwatched episodes';

	/// en: 'Player Backend'
	String get playerBackend => 'Player Backend';

	/// en: 'ExoPlayer'
	String get exoPlayer => 'ExoPlayer';

	/// en: 'mpv'
	String get mpv => 'mpv';

	/// en: 'Hardware Decoding'
	String get hardwareDecoding => 'Hardware Decoding';

	/// en: 'Use hardware acceleration when available'
	String get hardwareDecodingDescription => 'Use hardware acceleration when available';

	/// en: 'Playback Buffer'
	String get playbackBuffer => 'Playback Buffer';

	/// en: 'Auto (Recommended)'
	String get playbackBufferAuto => 'Auto (Recommended)';

	/// en: 'Large'
	String get playbackBufferLarge => 'Large';

	/// en: 'Extra Large'
	String get playbackBufferExtraLarge => 'Extra Large';

	/// en: 'Buffer more against unstable connections. Also limited by Buffer Size.'
	String get playbackBufferDescription => 'Buffer more against unstable connections. Also limited by Buffer Size.';

	/// en: 'Default Quality'
	String get defaultQualityTitle => 'Default Quality';

	/// en: 'Default Quality on Cellular'
	String get cellularQualityTitle => 'Default Quality on Cellular';

	/// en: 'Same as Default Quality'
	String get cellularQualitySameAsDefault => 'Same as Default Quality';

	/// en: 'Play Smaller Videos at Original Quality'
	String get directPlayCoveredQuality => 'Play Smaller Videos at Original Quality';

	/// en: 'Direct play videos already within the quality limit instead of transcoding them'
	String get directPlayCoveredQualityDescription => 'Direct play videos already within the quality limit instead of transcoding them';

	/// en: 'Music Quality'
	String get musicQualityTitle => 'Music Quality';

	/// en: 'Subtitle Styling'
	String get subtitleStyling => 'Subtitle Styling';

	/// en: 'Customize subtitle appearance'
	String get subtitleStylingDescription => 'Customize subtitle appearance';

	/// en: 'Small Skip Duration'
	String get smallSkipDuration => 'Small Skip Duration';

	/// en: 'Large Skip Duration'
	String get largeSkipDuration => 'Large Skip Duration';

	/// en: 'Rewind on Resume'
	String get rewindOnResume => 'Rewind on Resume';

	/// en: '${seconds} seconds'
	String secondsUnit({required Object seconds}) => '${seconds} seconds';

	/// en: 'Default Sleep Timer'
	String get defaultSleepTimer => 'Default Sleep Timer';

	/// en: '${minutes} minutes'
	String minutesUnit({required Object minutes}) => '${minutes} minutes';

	/// en: 'Remember track selections per show/movie'
	String get rememberTrackSelections => 'Remember track selections per show/movie';

	/// en: 'Remember audio and subtitle choices per title'
	String get rememberTrackSelectionsDescription => 'Remember audio and subtitle choices per title';

	/// en: 'Use server's per-episode track selections'
	String get followServerTrackSelections => 'Use server\'s per-episode track selections';

	/// en: 'On episode change, apply the audio and subtitles selected on the server instead of carrying over the current choice'
	String get followServerTrackSelectionsDescription => 'On episode change, apply the audio and subtitles selected on the server instead of carrying over the current choice';

	/// en: 'Remember music session'
	String get resumeMusicOnLaunch => 'Remember music session';

	/// en: 'Reopen the last song paused where it left off when the app starts'
	String get resumeMusicOnLaunchDescription => 'Reopen the last song paused where it left off when the app starts';

	/// en: 'Show chapter markers on seek bar'
	String get showChapterMarkersOnTimeline => 'Show chapter markers on seek bar';

	/// en: 'Segment the seek bar at chapter boundaries'
	String get showChapterMarkersOnTimelineDescription => 'Segment the seek bar at chapter boundaries';

	/// en: 'Specials in episode order'
	String get specialsOrdering => 'Specials in episode order';

	/// en: 'Where specials play in a show's watch order'
	String get specialsOrderingDescription => 'Where specials play in a show\'s watch order';

	/// en: 'Follow server order'
	String get specialsOrderingServer => 'Follow server order';

	/// en: 'Interleave by air date'
	String get specialsOrderingAirDate => 'Interleave by air date';

	/// en: 'After regular seasons'
	String get specialsOrderingLast => 'After regular seasons';

	/// en: 'Click on video to toggle play/pause'
	String get clickVideoTogglesPlayback => 'Click on video to toggle play/pause';

	/// en: 'Click video to play/pause instead of showing controls.'
	String get clickVideoTogglesPlaybackDescription => 'Click video to play/pause instead of showing controls.';

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

	/// en: 'Watch Together Relay'
	String get watchTogetherRelay => 'Watch Together Relay';

	/// en: 'Set a custom relay. Everyone must use the same server.'
	String get watchTogetherRelayDescription => 'Set a custom relay. Everyone must use the same server.';

	/// en: 'https://my-relay.example.com'
	String get watchTogetherRelayHint => 'https://my-relay.example.com';

	/// en: 'Enter a valid HTTP or HTTPS relay base URL.'
	String get watchTogetherRelayInvalid => 'Enter a valid HTTP or HTTPS relay base URL.';

	/// en: 'Crash Reporting'
	String get crashReporting => 'Crash Reporting';

	/// en: 'Send crash reports to help improve the app'
	String get crashReportingDescription => 'Send crash reports to help improve the app';

	/// en: 'Debug Logging'
	String get debugLogging => 'Debug Logging';

	/// en: 'Enable detailed logging for troubleshooting'
	String get debugLoggingDescription => 'Enable detailed logging for troubleshooting';

	/// en: 'View Logs'
	String get viewLogs => 'View Logs';

	/// en: 'View application logs'
	String get viewLogsDescription => 'View application logs';

	/// en: 'Clear Image Cache'
	String get clearImageCache => 'Clear Image Cache';

	/// en: 'Clear cached artwork and thumbnails. Images may load slower until downloaded again.'
	String get clearImageCacheDescription => 'Clear cached artwork and thumbnails. Images may load slower until downloaded again.';

	/// en: 'Image cache cleared successfully'
	String get clearImageCacheSuccess => 'Image cache cleared successfully';

	/// en: 'Reset Settings'
	String get resetSettings => 'Reset Settings';

	/// en: 'Restore default settings. This can't be undone.'
	String get resetSettingsDescription => 'Restore default settings. This can\'t be undone.';

	/// en: 'Settings reset successfully'
	String get resetSettingsSuccess => 'Settings reset successfully';

	/// en: 'Backup'
	String get backup => 'Backup';

	/// en: 'Export Settings'
	String get exportSettings => 'Export Settings';

	/// en: 'Save your preferences to a file'
	String get exportSettingsDescription => 'Save your preferences to a file';

	/// en: 'Settings exported'
	String get exportSettingsSuccess => 'Settings exported';

	/// en: 'Import Settings'
	String get importSettings => 'Import Settings';

	/// en: 'Restore preferences from a file'
	String get importSettingsDescription => 'Restore preferences from a file';

	/// en: 'This will replace your current settings. Continue?'
	String get importSettingsConfirm => 'This will replace your current settings. Continue?';

	/// en: 'Settings imported'
	String get importSettingsSuccess => 'Settings imported';

	/// en: 'This file isn't a valid Plezy settings export'
	String get importSettingsInvalidFile => 'This file isn\'t a valid Plezy settings export';

	/// en: 'Sign in before importing settings'
	String get importSettingsNoUser => 'Sign in before importing settings';

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

	/// en: 'Automatically check for updates on startup'
	String get autoCheckUpdatesOnStartup => 'Automatically check for updates on startup';

	/// en: 'Notify when an update is available at launch'
	String get autoCheckUpdatesOnStartupDescription => 'Notify when an update is available at launch';

	/// en: 'Please enter a valid number'
	String get validationErrorEnterNumber => 'Please enter a valid number';

	/// en: 'Duration must be between ${min} and ${max} ${unit}'
	String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Duration must be between ${min} and ${max} ${unit}';

	/// en: 'Shortcut already assigned to ${action}'
	String shortcutAlreadyAssigned({required Object action}) => 'Shortcut already assigned to ${action}';

	/// en: 'Shortcut updated for ${action}'
	String shortcutUpdated({required Object action}) => 'Shortcut updated for ${action}';

	/// en: 'Could not save changes. Try again.'
	String get saveFailed => 'Could not save changes. Try again.';

	/// en: 'Auto-Play & Skip'
	String get autoPlayAndSkip => 'Auto-Play & Skip';

	/// en: 'Auto-Play Next Episode'
	String get autoPlayNextEpisode => 'Auto-Play Next Episode';

	/// en: 'Start the next episode automatically when one ends'
	String get autoPlayNextEpisodeDescription => 'Start the next episode automatically when one ends';

	/// en: 'Play Next Countdown'
	String get playNextCountdown => 'Play Next Countdown';

	/// en: 'Play immediately'
	String get playNextCountdownImmediate => 'Play immediately';

	/// en: 'Skip Intro'
	String get skipIntroMode => 'Skip Intro';

	/// en: 'Play intros normally without a skip button'
	String get skipIntroModeOffDescription => 'Play intros normally without a skip button';

	/// en: 'Show a skip button when an intro starts'
	String get skipIntroModeButtonDescription => 'Show a skip button when an intro starts';

	/// en: 'Skip intros automatically after the delay below'
	String get skipIntroModeAutoDescription => 'Skip intros automatically after the delay below';

	/// en: 'Skip Credits'
	String get skipCreditsMode => 'Skip Credits';

	/// en: 'Play credits normally without a skip button'
	String get skipCreditsModeOffDescription => 'Play credits normally without a skip button';

	/// en: 'Show a skip button when credits start'
	String get skipCreditsModeButtonDescription => 'Show a skip button when credits start';

	/// en: 'Skip credits automatically and play the next episode'
	String get skipCreditsModeAutoDescription => 'Skip credits automatically and play the next episode';

	/// en: 'Off'
	String get skipMarkerModeOff => 'Off';

	/// en: 'Show button'
	String get skipMarkerModeButton => 'Show button';

	/// en: 'Automatic'
	String get skipMarkerModeAuto => 'Automatic';

	/// en: 'Force Fallback Markers'
	String get forceSkipMarkerFallback => 'Force Fallback Markers';

	/// en: 'Use chapter title patterns even when Plex has markers'
	String get forceSkipMarkerFallbackDescription => 'Use chapter title patterns even when Plex has markers';

	/// en: 'Auto Skip Delay'
	String get autoSkipDelay => 'Auto Skip Delay';

	/// en: 'Wait ${seconds} seconds before auto-skipping'
	String autoSkipDelayDescription({required Object seconds}) => 'Wait ${seconds} seconds before auto-skipping';

	/// en: 'Intro Marker Pattern'
	String get introPattern => 'Intro Marker Pattern';

	/// en: 'Regex pattern to match intro markers in chapter titles'
	String get introPatternDescription => 'Regex pattern to match intro markers in chapter titles';

	/// en: 'Credits Marker Pattern'
	String get creditsPattern => 'Credits Marker Pattern';

	/// en: 'Regex pattern to match credits markers in chapter titles'
	String get creditsPatternDescription => 'Regex pattern to match credits markers in chapter titles';

	/// en: 'Invalid regular expression'
	String get invalidRegex => 'Invalid regular expression';

	/// en: 'Regular expression'
	String get regex => 'Regular expression';

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

	/// en: 'Folder selection is not available on this device'
	String get downloadLocationPickerUnavailable => 'Folder selection is not available on this device';

	/// en: 'Download on Wi-Fi only'
	String get downloadOnWifiOnly => 'Download on Wi-Fi only';

	/// en: 'Prevent downloads when on cellular data'
	String get downloadOnWifiOnlyDescription => 'Prevent downloads when on cellular data';

	/// en: 'Auto-remove watched downloads'
	String get autoRemoveWatchedDownloads => 'Auto-remove watched downloads';

	/// en: 'Delete watched downloads automatically'
	String get autoRemoveWatchedDownloadsDescription => 'Delete watched downloads automatically';

	/// en: 'Downloads are blocked on cellular. Use Wi-Fi or change the setting.'
	String get cellularDownloadBlocked => 'Downloads are blocked on cellular. Use Wi-Fi or change the setting.';

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

	/// en: 'Services'
	String get services => 'Services';

	/// en: 'Connect Trakt, MyAnimeList, Seerr, and more'
	String get servicesDescription => 'Connect Trakt, MyAnimeList, Seerr, and more';

	/// en: 'Reorder and hide libraries'
	String get manageLibrariesDescription => 'Reorder and hide libraries';

	/// en: 'Companion Remote Server'
	String get companionRemoteServer => 'Companion Remote Server';

	/// en: 'Allow mobile devices on your network to control this app'
	String get companionRemoteServerDescription => 'Allow mobile devices on your network to control this app';

	/// en: 'Auto Picture-in-Picture'
	String get autoPip => 'Auto Picture-in-Picture';

	/// en: 'Automatically enter picture-in-picture when you leave the app during playback'
	String get autoPipDescription => 'Automatically enter picture-in-picture when you leave the app during playback';

	/// en: 'Match Content Frame Rate'
	String get matchContentFrameRate => 'Match Content Frame Rate';

	/// en: 'Match display refresh rate to video content'
	String get matchContentFrameRateDescription => 'Match display refresh rate to video content';

	/// en: 'Match Content Resolution'
	String get matchContentResolution => 'Match Content Resolution';

	/// en: 'Switch the display to the video's native resolution so your TV handles upscaling. Menus and subtitles are upscaled too during playback'
	String get matchContentResolutionDescription => 'Switch the display to the video\'s native resolution so your TV handles upscaling. Menus and subtitles are upscaled too during playback';

	/// en: 'Match Refresh Rate'
	String get matchRefreshRate => 'Match Refresh Rate';

	/// en: 'Match display refresh rate in fullscreen'
	String get matchRefreshRateDescription => 'Match display refresh rate in fullscreen';

	/// en: 'Match Dynamic Range'
	String get matchDynamicRange => 'Match Dynamic Range';

	/// en: 'Switch HDR on for HDR content, then back to SDR'
	String get matchDynamicRangeDescription => 'Switch HDR on for HDR content, then back to SDR';

	/// en: 'Display Switch Delay'
	String get displaySwitchDelay => 'Display Switch Delay';

	/// en: 'Tunneled Playback'
	String get tunneledPlayback => 'Tunneled Playback';

	/// en: 'Use video tunneling. Disable if HDR playback shows black video or motion stutters.'
	String get tunneledPlaybackDescription => 'Use video tunneling. Disable if HDR playback shows black video or motion stutters.';

	/// en: 'Audio Passthrough'
	String get audioPassthrough => 'Audio Passthrough';

	/// en: 'Send Dolby/DTS audio to your receiver or TV without re-encoding, preserving surround sound. Turn off if you have no sound.'
	String get audioPassthroughDescription => 'Send Dolby/DTS audio to your receiver or TV without re-encoding, preserving surround sound. Turn off if you have no sound.';

	/// en: 'Use Apple's native Dolby decoder for Dolby Digital Plus, including Atmos. DTS and TrueHD still play as multichannel PCM. Turn off if you have no sound.'
	String get audioPassthroughDescriptionAppleTv => 'Use Apple\'s native Dolby decoder for Dolby Digital Plus, including Atmos. DTS and TrueHD still play as multichannel PCM. Turn off if you have no sound.';

	/// en: 'Downmix to Stereo'
	String get audioDownmix => 'Downmix to Stereo';

	/// en: 'Mix surround audio down to two channels for stereo speakers or headphones'
	String get audioDownmixDescription => 'Mix surround audio down to two channels for stereo speakers or headphones';

	/// en: 'Center Channel Boost'
	String get downmixCenterBoost => 'Center Channel Boost';

	/// en: '${db} dB'
	String downmixCenterBoostValue({required Object db}) => '${db} dB';

	/// en: 'Boost (dB)'
	String get downmixCenterBoostLabel => 'Boost (dB)';

	/// en: 'dB'
	String get downmixCenterBoostShort => 'dB';

	/// en: 'Normalize Volume on Downmix'
	String get audioDownmixNormalize => 'Normalize Volume on Downmix';

	/// en: 'Lower the mix to prevent clipping. Turn off to keep the original volume (may distort loud scenes).'
	String get audioDownmixNormalizeDescription => 'Lower the mix to prevent clipping. Turn off to keep the original volume (may distort loud scenes).';

	/// en: 'Dolby Vision Conversion'
	String get dvConversionMode => 'Dolby Vision Conversion';

	/// en: 'Choose how Dolby Vision Profile 7 files are handled.'
	String get dvConversionModeDescription => 'Choose how Dolby Vision Profile 7 files are handled.';

	/// en: 'Auto'
	String get dvConversionAuto => 'Auto';

	/// en: 'Native / Disabled'
	String get dvConversionNative => 'Native / Disabled';

	/// en: 'P7 → P8.1'
	String get dvConversionDv81 => 'P7 → P8.1';

	/// en: 'P7 → HEVC'
	String get dvConversionHevcStrip => 'P7 → HEVC';

	/// en: 'Use device capability detection and normal fallback behavior'
	String get dvConversionAutoDescription => 'Use device capability detection and normal fallback behavior';

	/// en: 'Force native DV7 and suppress DV conversion retry'
	String get dvConversionNativeDescription => 'Force native DV7 and suppress DV conversion retry';

	/// en: 'Force inline RPU conversion to Dolby Vision profile 8.1'
	String get dvConversionDv81Description => 'Force inline RPU conversion to Dolby Vision profile 8.1';

	/// en: 'Strip Dolby Vision RPU/EL layers and present plain HEVC'
	String get dvConversionHevcStripDescription => 'Strip Dolby Vision RPU/EL layers and present plain HEVC';

	/// en: 'Deinterlacing'
	String get deinterlace => 'Deinterlacing';

	/// en: 'Remove combing artifacts from interlaced video (mpv player only)'
	String get deinterlaceDescription => 'Remove combing artifacts from interlaced video (mpv player only)';

	/// en: 'Ask for profile on app open'
	String get requireProfileSelectionOnOpen => 'Ask for profile on app open';

	/// en: 'Show profile selection every time the app is opened'
	String get requireProfileSelectionOnOpenDescription => 'Show profile selection every time the app is opened';

	/// en: 'Force TV mode'
	String get forceTvMode => 'Force TV mode';

	/// en: 'Force TV layout. For devices that don't auto-detect. Requires restart.'
	String get forceTvModeDescription => 'Force TV layout. For devices that don\'t auto-detect. Requires restart.';

	/// en: 'Start in fullscreen'
	String get startInFullscreen => 'Start in fullscreen';

	/// en: 'Open Plezy in fullscreen mode at launch'
	String get startInFullscreenDescription => 'Open Plezy in fullscreen mode at launch';

	/// en: 'Exit fullscreen on player close'
	String get exitFullscreenOnPlayerClose => 'Exit fullscreen on player close';

	/// en: 'Automatically exit fullscreen when closing the video player'
	String get exitFullscreenOnPlayerCloseDescription => 'Automatically exit fullscreen when closing the video player';

	/// en: 'Auto-Hide Performance Overlay'
	String get autoHidePerformanceOverlay => 'Auto-Hide Performance Overlay';

	/// en: 'Fade the performance overlay with the playback controls'
	String get autoHidePerformanceOverlayDescription => 'Fade the performance overlay with the playback controls';

	/// en: 'Show Navigation Bar Labels'
	String get showNavBarLabels => 'Show Navigation Bar Labels';

	/// en: 'Display text labels under navigation bar icons'
	String get showNavBarLabelsDescription => 'Display text labels under navigation bar icons';

	/// en: 'Startup Section'
	String get startupSection => 'Startup Section';

	/// en: 'Show Explore Tab'
	String get showExploreTab => 'Show Explore Tab';

	/// en: 'Display the Explore tab with content from Plex Discover and connected trackers'
	String get showExploreTabDescription => 'Display the Explore tab with content from Plex Discover and connected trackers';

	/// en: 'Default to Favorite Channels'
	String get liveTvDefaultFavorites => 'Default to Favorite Channels';

	/// en: 'Show only favorite channels when opening Live TV'
	String get liveTvDefaultFavoritesDescription => 'Show only favorite channels when opening Live TV';

	/// en: 'General'
	String get general => 'General';

	/// en: 'Language, startup, and window behavior'
	String get generalDescription => 'Language, startup, and window behavior';

	/// en: 'Language & Region'
	String get languageAndRegion => 'Language & Region';

	/// en: 'Startup'
	String get startup => 'Startup';

	/// en: 'Display'
	String get display => 'Display';

	/// en: 'Library & Cards'
	String get libraryAndCards => 'Library & Cards';

	/// en: 'Home Screen'
	String get homeScreen => 'Home Screen';

	/// en: 'Navigation'
	String get navigation => 'Navigation';

	/// en: 'Window'
	String get window => 'Window';

	/// en: 'Live TV'
	String get liveTv => 'Live TV';

	/// en: 'Player'
	String get player => 'Player';

	/// en: 'Video & Display'
	String get videoAndDisplay => 'Video & Display';

	/// en: 'Audio'
	String get audio => 'Audio';

	/// en: 'Quality'
	String get quality => 'Quality';

	/// en: 'Subtitles'
	String get subtitles => 'Subtitles';

	/// en: 'Seek & Timing'
	String get seekAndTiming => 'Seek & Timing';

	/// en: 'Behavior'
	String get behavior => 'Behavior';

	/// en: 'Gestures'
	String get gestures => 'Gestures';

	/// en: 'Brightness Swipe'
	String get gestureBrightnessSwipe => 'Brightness Swipe';

	/// en: 'Swipe up or down on the left edge to adjust brightness'
	String get gestureBrightnessSwipeDescription => 'Swipe up or down on the left edge to adjust brightness';

	/// en: 'Volume Swipe'
	String get gestureVolumeSwipe => 'Volume Swipe';

	/// en: 'Swipe up or down on the right edge to adjust volume'
	String get gestureVolumeSwipeDescription => 'Swipe up or down on the right edge to adjust volume';

	/// en: 'Pinch to Zoom'
	String get gesturePinchToZoom => 'Pinch to Zoom';

	/// en: 'Pinch on the video to zoom in or out'
	String get gesturePinchToZoomDescription => 'Pinch on the video to zoom in or out';

	/// en: 'Remember Brightness Level'
	String get rememberBrightnessLevel => 'Remember Brightness Level';

	/// en: 'Start playback at the brightness set by the last swipe'
	String get rememberBrightnessLevelDescription => 'Start playback at the brightness set by the last swipe';

	/// en: 'Controls'
	String get controls => 'Controls';

	/// en: 'Remember Player Changes'
	String get rememberPlayerChanges => 'Remember Player Changes';

	/// en: 'Where a change made during playback is saved and reapplied from'
	String get rememberPlayerChangesDescription => 'Where a change made during playback is saved and reapplied from';

	/// en: 'Playback Speed'
	String get scopePlaybackSpeed => 'Playback Speed';

	/// en: 'Shader Preset'
	String get scopeShaderPreset => 'Shader Preset';

	/// en: 'Aspect Ratio'
	String get scopeAspectRatio => 'Aspect Ratio';

	/// en: 'Audio & Subtitle Sync'
	String get scopeSyncOffsets => 'Audio & Subtitle Sync';

	/// en: 'Don't save'
	String get playerScopeOff => 'Don\'t save';

	/// en: 'Everywhere'
	String get playerScopeGlobal => 'Everywhere';

	/// en: 'Per library'
	String get playerScopeLibrary => 'Per library';

	/// en: 'Per show or movie'
	String get playerScopeTitle => 'Per show or movie';

	/// en: 'Export Plezy settings'
	String get exportDialogTitle => 'Export Plezy settings';
}

// Path: search
class Translations$search$en {
	Translations$search$en.internal(this._root);

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
class Translations$hotkeys$en {
	Translations$hotkeys$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Set Shortcut for ${actionName}'
	String setShortcutFor({required Object actionName}) => 'Set Shortcut for ${actionName}';

	/// en: 'Clear shortcut'
	String get clearShortcut => 'Clear shortcut';

	/// en: 'No shortcut set'
	String get noShortcutSet => 'No shortcut set';

	/// en: 'Current shortcut:'
	String get currentShortcut => 'Current shortcut:';

	/// en: 'Select to record a shortcut'
	String get pressToRecord => 'Select to record a shortcut';

	/// en: 'Press the shortcut now'
	String get recordingShortcut => 'Press the shortcut now';

	late final Translations$hotkeys$actions$en actions = Translations$hotkeys$actions$en.internal(_root);
}

// Path: fileInfo
class Translations$fileInfo$en {
	Translations$fileInfo$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'File Info'
	String get title => 'File Info';

	/// en: 'Overview'
	String get overview => 'Overview';

	/// en: 'Video'
	String get video => 'Video';

	/// en: 'Audio'
	String get audio => 'Audio';

	/// en: 'Subtitles'
	String get subtitles => 'Subtitles';

	/// en: 'Embedded Images'
	String get images => 'Embedded Images';

	/// en: 'Data Streams'
	String get dataStreams => 'Data Streams';

	/// en: 'Lyrics'
	String get lyrics => 'Lyrics';

	/// en: 'File'
	String get file => 'File';

	/// en: 'Attachments'
	String get attachments => 'Attachments';

	/// en: 'Delivery'
	String get delivery => 'Delivery';

	/// en: 'Version ${index} of ${count}'
	String versionCounter({required Object index, required Object count}) => 'Version ${index} of ${count}';

	/// en: 'File ${index} of ${count}'
	String fileCounter({required Object index, required Object count}) => 'File ${index} of ${count}';

	/// en: 'The server reported no streams for this file.'
	String get noStreams => 'The server reported no streams for this file.';

	/// en: 'Copy path'
	String get copyPath => 'Copy path';

	/// en: 'File path copied'
	String get pathCopied => 'File path copied';

	/// en: 'Codec'
	String get codec => 'Codec';

	/// en: 'Codec Tag'
	String get codecTag => 'Codec Tag';

	/// en: 'Resolution'
	String get resolution => 'Resolution';

	/// en: 'Coded Resolution'
	String get codedResolution => 'Coded Resolution';

	/// en: 'Bitrate'
	String get bitrate => 'Bitrate';

	/// en: 'Frame Rate'
	String get frameRate => 'Frame Rate';

	/// en: 'Rotation'
	String get rotation => 'Rotation';

	/// en: 'Comment'
	String get comment => 'Comment';

	/// en: 'Audio Description'
	String get audioDescription => 'Audio Description';

	/// en: 'Header Compression'
	String get headerCompression => 'Header Compression';

	/// en: 'Sidecar File'
	String get sidecarFile => 'Sidecar File';

	/// en: 'Transport Timestamp'
	String get transportTimestamp => 'Transport Timestamp';

	/// en: 'Display Offset'
	String get displayOffset => 'Display Offset';

	/// en: 'Preview Failure Code'
	String get previewFailureCode => 'Preview Failure Code';

	/// en: 'Preview Retries'
	String get previewRetries => 'Preview Retries';

	/// en: 'Aspect Ratio'
	String get aspectRatio => 'Aspect Ratio';

	/// en: 'Pixel Aspect Ratio'
	String get pixelAspectRatio => 'Pixel Aspect Ratio';

	/// en: 'Profile'
	String get profile => 'Profile';

	/// en: 'Level'
	String get level => 'Level';

	/// en: 'Bit Depth'
	String get bitDepth => 'Bit Depth';

	/// en: 'Pixel Format'
	String get pixelFormat => 'Pixel Format';

	/// en: 'Color Space'
	String get colorSpace => 'Color Space';

	/// en: 'Color Range'
	String get colorRange => 'Color Range';

	/// en: 'Color Primaries'
	String get colorPrimaries => 'Color Primaries';

	/// en: 'Color Transfer'
	String get colorTransfer => 'Color Transfer';

	/// en: 'Chroma Subsampling'
	String get chromaSubsampling => 'Chroma Subsampling';

	/// en: 'Chroma Location'
	String get chromaLocation => 'Chroma Location';

	/// en: 'Scan Type'
	String get scanType => 'Scan Type';

	/// en: 'Interlaced'
	String get interlaced => 'Interlaced';

	/// en: 'Anamorphic'
	String get anamorphic => 'Anamorphic';

	/// en: 'Reference Frames'
	String get referenceFrames => 'Reference Frames';

	/// en: 'Dynamic Range'
	String get dynamicRange => 'Dynamic Range';

	/// en: 'Dolby Vision'
	String get dolbyVision => 'Dolby Vision';

	/// en: 'Dolby Vision Level'
	String get dolbyVisionLevel => 'Dolby Vision Level';

	/// en: 'Dolby Vision Version'
	String get dolbyVisionVersion => 'Dolby Vision Version';

	/// en: 'Dolby Vision Layers'
	String get dolbyVisionLayers => 'Dolby Vision Layers';

	/// en: 'Base Layer Compatibility'
	String get baseLayerCompatibility => 'Base Layer Compatibility';

	/// en: 'AVC Bitstream'
	String get avcBitstream => 'AVC Bitstream';

	/// en: 'NAL Length Size'
	String get nalLengthSize => 'NAL Length Size';

	/// en: 'Custom Scaling Matrix'
	String get scalingMatrix => 'Custom Scaling Matrix';

	/// en: 'Stream Identifier'
	String get streamIdentifier => 'Stream Identifier';

	/// en: 'Stream Index'
	String get streamIndex => 'Stream Index';

	/// en: 'Stream ID'
	String get streamId => 'Stream ID';

	/// en: 'Language'
	String get language => 'Language';

	/// en: 'Language Code'
	String get languageCode => 'Language Code';

	/// en: 'Track Title'
	String get streamTitle => 'Track Title';

	/// en: 'Channels'
	String get channels => 'Channels';

	/// en: 'Sample Rate'
	String get sampleRate => 'Sample Rate';

	/// en: 'Spatial Audio'
	String get spatialAudio => 'Spatial Audio';

	/// en: 'Text Based'
	String get textBased => 'Text Based';

	/// en: 'Sidecar Format'
	String get subtitleFormat => 'Sidecar Format';

	/// en: 'Provider'
	String get provider => 'Provider';

	/// en: 'Match Score'
	String get matchScore => 'Match Score';

	/// en: 'Can Be Served Separately'
	String get externalDelivery => 'Can Be Served Separately';

	/// en: 'Sidecar Path'
	String get sidecarPath => 'Sidecar Path';

	/// en: 'Copied From'
	String get sourceStream => 'Copied From';

	/// en: 'Temporary'
	String get temporary => 'Temporary';

	/// en: 'Time Base'
	String get timeBase => 'Time Base';

	/// en: 'Overall Bitrate'
	String get overallBitrate => 'Overall Bitrate';

	/// en: 'Path'
	String get path => 'Path';

	/// en: 'File Name'
	String get fileName => 'File Name';

	/// en: 'Size'
	String get size => 'Size';

	/// en: 'Total Size'
	String get totalSize => 'Total Size';

	/// en: 'Container'
	String get container => 'Container';

	/// en: 'Duration'
	String get duration => 'Duration';

	/// en: 'Preview Thumbnails'
	String get previewThumbnails => 'Preview Thumbnails';

	/// en: 'Preview Index'
	String get previewIndex => 'Preview Index';

	/// en: 'Packet Length'
	String get packetLength => 'Packet Length';

	/// en: 'File Present'
	String get filePresent => 'File Present';

	/// en: 'Readable by Server'
	String get fileReadable => 'Readable by Server';

	/// en: 'Stream Path'
	String get streamPath => 'Stream Path';

	/// en: 'Optimized for Streaming'
	String get optimizedForStreaming => 'Optimized for Streaming';

	/// en: '64-bit Offsets'
	String get has64bitOffsets => '64-bit Offsets';

	/// en: 'Protocol'
	String get protocol => 'Protocol';

	/// en: 'Media Type'
	String get mediaType => 'Media Type';

	/// en: 'Source Kind'
	String get sourceKind => 'Source Kind';

	/// en: 'Optimized Version'
	String get optimizedVersion => 'Optimized Version';

	/// en: 'Optimization Target'
	String get optimizationTarget => 'Optimization Target';

	/// en: 'Deleted'
	String get deletedAt => 'Deleted';

	/// en: 'Remote Source'
	String get remoteSource => 'Remote Source';

	/// en: 'Infinite Stream'
	String get infiniteStream => 'Infinite Stream';

	/// en: 'Direct Play'
	String get directPlay => 'Direct Play';

	/// en: 'Direct Stream'
	String get directStream => 'Direct Stream';

	/// en: 'Transcoding'
	String get transcoding => 'Transcoding';

	/// en: 'ETag'
	String get etag => 'ETag';

	/// en: 'Version ID'
	String get versionId => 'Version ID';

	/// en: 'File ID'
	String get fileId => 'File ID';

	/// en: 'Default Audio Track'
	String get defaultAudioTrack => 'Default Audio Track';

	/// en: 'Default Subtitle Track'
	String get defaultSubtitleTrack => 'Default Subtitle Track';

	/// en: 'Off'
	String get subtitlesOff => 'Off';

	/// en: 'Default'
	String get flagDefault => 'Default';

	/// en: 'Forced'
	String get flagForced => 'Forced';

	/// en: 'Selected'
	String get flagSelected => 'Selected';

	/// en: 'External'
	String get flagExternal => 'External';

	/// en: 'Hearing impaired'
	String get flagHearingImpaired => 'Hearing impaired';

	/// en: 'Dub'
	String get flagDub => 'Dub';

	/// en: 'Original'
	String get flagOriginal => 'Original';

	/// en: 'Mono'
	String get channelsMono => 'Mono';

	/// en: 'Profile ${profile}'
	String dolbyVisionProfile({required Object profile}) => 'Profile ${profile}';
}

// Path: mediaMenu
class Translations$mediaMenu$en {
	Translations$mediaMenu$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Mark as Watched'
	String get markAsWatched => 'Mark as Watched';

	/// en: 'Mark as Unwatched'
	String get markAsUnwatched => 'Mark as Unwatched';

	/// en: 'Remove from Continue Watching'
	String get removeFromContinueWatching => 'Remove from Continue Watching';

	/// en: 'View details'
	String get viewDetails => 'View details';

	/// en: 'Go to series'
	String get goToSeries => 'Go to series';

	/// en: 'Shuffle Play'
	String get shufflePlay => 'Shuffle Play';

	/// en: 'Shuffle not available offline'
	String get shuffleNotAvailableOffline => 'Shuffle not available offline';

	/// en: 'File Info'
	String get fileInfo => 'File Info';

	/// en: 'Delete episode from server'
	String get deleteEpisodeFromServer => 'Delete episode from server';

	/// en: 'Delete season from server'
	String get deleteSeasonFromServer => 'Delete season from server';

	/// en: 'Delete show from server'
	String get deleteShowFromServer => 'Delete show from server';

	/// en: 'Delete movie from server'
	String get deleteMovieFromServer => 'Delete movie from server';

	/// en: 'Delete this episode?'
	String get deleteEpisodeTitle => 'Delete this episode?';

	/// en: 'Delete this season?'
	String get deleteSeasonTitle => 'Delete this season?';

	/// en: 'Delete this show?'
	String get deleteShowTitle => 'Delete this show?';

	/// en: 'Delete this movie?'
	String get deleteMovieTitle => 'Delete this movie?';

	/// en: 'Delete episode'
	String get deleteEpisodeConfirm => 'Delete episode';

	/// en: 'Delete season'
	String get deleteSeasonConfirm => 'Delete season';

	/// en: 'Delete show'
	String get deleteShowConfirm => 'Delete show';

	/// en: 'Delete movie'
	String get deleteMovieConfirm => 'Delete movie';

	/// en: 'Delete anyway'
	String get deleteAnyway => 'Delete anyway';

	/// en: 'Permanently delete ${title} from your server?'
	String confirmDeleteTarget({required Object title}) => 'Permanently delete ${title} from your server?';

	/// en: 'This includes all episodes and their files.'
	String get deleteMultipleWarning => 'This includes all episodes and their files.';

	/// en: '(one) {This deletes all ${n} episode in it, and its file.} (other) {This deletes all ${n} episodes in it, and their files.}'
	String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'This deletes all ${n} episode in it, and its file.',
		other: 'This deletes all ${n} episodes in it, and their files.',
	);

	/// en: '(one) {This item is stored as ${n} file, which will be deleted.} (other) {This item is stored across ${n} files, and all of them will be deleted.}'
	String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'This item is stored as ${n} file, which will be deleted.',
		other: 'This item is stored across ${n} files, and all of them will be deleted.',
	);

	/// en: '(one) {${n} other episode is stored in the same file and will be deleted too:} (other) {${n} other episodes are stored in the same file and will be deleted too:}'
	String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} other episode is stored in the same file and will be deleted too:',
		other: '${n} other episodes are stored in the same file and will be deleted too:',
	);

	/// en: 'Plezy could not check which files this will remove, so it may delete more than the item named above. Cancel and try again, or delete anyway.'
	String get deleteScopeUnverifiedProbeFailed => 'Plezy could not check which files this will remove, so it may delete more than the item named above. Cancel and try again, or delete anyway.';

	/// en: 'Your server did not provide file details for this item, so Plezy cannot check which files this will remove. It may delete more than the item named above.'
	String get deleteScopeUnverifiedNoFileInfo => 'Your server did not provide file details for this item, so Plezy cannot check which files this will remove. It may delete more than the item named above.';

	/// en: 'Media item deleted successfully'
	String get mediaDeletedSuccessfully => 'Media item deleted successfully';

	/// en: 'Failed to delete media item'
	String get mediaFailedToDelete => 'Failed to delete media item';

	/// en: 'Rate'
	String get rate => 'Rate';

	/// en: 'Play from Beginning'
	String get playFromBeginning => 'Play from Beginning';

	/// en: 'Play Version...'
	String get playVersion => 'Play Version...';
}

// Path: rateSheet
class Translations$rateSheet$en {
	Translations$rateSheet$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Rate'
	String get title => 'Rate';

	/// en: 'Server'
	String get server => 'Server';

	/// en: 'Favorite'
	String get favorite => 'Favorite';

	/// en: 'Favorited'
	String get favorited => 'Favorited';

	/// en: 'Saved'
	String get saved => 'Saved';

	/// en: 'No match found'
	String get notAvailable => 'No match found';

	/// en: 'Connect a service in Settings to rate there.'
	String get noConnectedServices => 'Connect a service in Settings to rate there.';
}

// Path: accessibility
class Translations$accessibility$en {
	Translations$accessibility$en.internal(this._root);

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

	/// en: 'Decrease'
	String get decrease => 'Decrease';

	/// en: 'Increase'
	String get increase => 'Increase';

	/// en: 'Decrease ${label}'
	String decreaseValue({required Object label}) => 'Decrease ${label}';

	/// en: 'Increase ${label}'
	String increaseValue({required Object label}) => 'Increase ${label}';

	/// en: 'Hue'
	String get hue => 'Hue';

	/// en: 'Saturation'
	String get saturation => 'Saturation';

	/// en: 'Brightness'
	String get brightness => 'Brightness';

	/// en: 'Hex color'
	String get hexColor => 'Hex color';

	/// en: 'Expand text'
	String get expandText => 'Expand text';

	/// en: 'Collapse text'
	String get collapseText => 'Collapse text';

	/// en: 'Alphabet navigation'
	String get alphabetNavigation => 'Alphabet navigation';

	/// en: 'Swipe up or down to move by letter'
	String get alphabetScrollHint => 'Swipe up or down to move by letter';

	/// en: 'Row ${row} of ${rowCount}, column ${column} of ${columnCount}'
	String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Row ${row} of ${rowCount}, column ${column} of ${columnCount}';

	/// en: 'Row ${row} of ${rowCount}'
	String rowPosition({required Object row, required Object rowCount}) => 'Row ${row} of ${rowCount}';

	/// en: 'Play auto-scroll'
	String get autoScrollPlay => 'Play auto-scroll';

	/// en: 'Pause auto-scroll'
	String get autoScrollPause => 'Pause auto-scroll';

	/// en: 'H'
	String get hueShort => 'H';

	/// en: 'S'
	String get saturationShort => 'S';

	/// en: 'V'
	String get valueShort => 'V';
}

// Path: tooltips
class Translations$tooltips$en {
	Translations$tooltips$en.internal(this._root);

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

// Path: audioTracks
class Translations$audioTracks$en {
	Translations$audioTracks$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Audio Track ${n}'
	String track({required Object n}) => 'Audio Track ${n}';
}

// Path: videoControls
class Translations$videoControls$en {
	Translations$videoControls$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Audio'
	String get audioLabel => 'Audio';

	/// en: 'Subtitles'
	String get subtitlesLabel => 'Subtitles';

	/// en: '+${amount}${unit}'
	String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';

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

	/// en: 'End of current video'
	String get sleepTimerEndOfVideo => 'End of current video';

	/// en: 'Stop at'
	String get sleepTimerStopAtHeader => 'Stop at';

	/// en: 'Timer'
	String get sleepTimerDurationHeader => 'Timer';

	/// en: 'Playback will pause at the end of this video'
	String get playbackWillPauseAtEnd => 'Playback will pause at the end of this video';

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

	/// en: 'Paused'
	String get playbackPaused => 'Paused';

	/// en: 'Playing'
	String get playbackResumed => 'Playing';

	/// en: 'Loading video'
	String get loadingVideo => 'Loading video';

	/// en: 'Show playback controls'
	String get showPlaybackControls => 'Show playback controls';

	/// en: 'Hide playback controls'
	String get hidePlaybackControls => 'Hide playback controls';

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

	/// en: 'Playback Settings'
	String get settingsButton => 'Playback Settings';

	/// en: 'Audio & Subtitles'
	String get tracksButton => 'Audio & Subtitles';

	/// en: 'Chapters'
	String get chaptersButton => 'Chapters';

	/// en: 'Version & Quality'
	String get versionQualityButton => 'Version & Quality';

	/// en: 'Version'
	String get versionColumnHeader => 'Version';

	/// en: 'Quality'
	String get qualityColumnHeader => 'Quality';

	/// en: 'Original'
	String get qualityOriginal => 'Original';

	/// en: '${resolution}p ${bitrate} Mbps'
	String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';

	/// en: 'Transcoding unavailable — playing original quality'
	String get transcodeUnavailableFallback => 'Transcoding unavailable — playing original quality';

	/// en: 'Selected subtitles could not be loaded — continuing without subtitles'
	String get subtitleUnavailableFallback => 'Selected subtitles could not be loaded — continuing without subtitles';

	/// en: 'Picture-in-Picture mode'
	String get pipButton => 'Picture-in-Picture mode';

	/// en: 'Aspect ratio'
	String get aspectRatioButton => 'Aspect ratio';

	/// en: 'Ambient lighting'
	String get ambientLighting => 'Ambient lighting';

	/// en: 'Enter fullscreen'
	String get fullscreenButton => 'Enter fullscreen';

	/// en: 'Exit fullscreen'
	String get exitFullscreenButton => 'Exit fullscreen';

	/// en: 'Always on top'
	String get alwaysOnTopButton => 'Always on top';

	/// en: 'Rotation lock'
	String get rotationLockButton => 'Rotation lock';

	/// en: 'Lock screen'
	String get lockScreen => 'Lock screen';

	/// en: 'Screen lock'
	String get screenLockButton => 'Screen lock';

	/// en: 'Long press to unlock'
	String get longPressToUnlock => 'Long press to unlock';

	/// en: 'Video timeline'
	String get timelineSlider => 'Video timeline';

	/// en: 'Volume level'
	String get volumeSlider => 'Volume level';

	/// en: 'Ends at ${time}'
	String endsAt({required Object time}) => 'Ends at ${time}';

	/// en: 'Playing in Picture-in-Picture'
	String get pipActive => 'Playing in Picture-in-Picture';

	/// en: 'Picture-in-picture failed to start'
	String get pipFailed => 'Picture-in-picture failed to start';

	/// en: 'Screenshot saved'
	String get screenshotSaved => 'Screenshot saved';

	/// en: 'Zoom ${percent}%'
	String zoomPercent({required Object percent}) => 'Zoom ${percent}%';

	late final Translations$videoControls$pipErrors$en pipErrors = Translations$videoControls$pipErrors$en.internal(_root);

	/// en: 'Chapters'
	String get chapters => 'Chapters';

	/// en: 'No chapters available'
	String get noChaptersAvailable => 'No chapters available';

	/// en: 'Queue'
	String get queue => 'Queue';

	/// en: 'No items in queue'
	String get noQueueItems => 'No items in queue';

	/// en: 'No audio devices available'
	String get noAudioDevicesAvailable => 'No audio devices available';

	/// en: 'Search Subtitles'
	String get searchSubtitles => 'Search Subtitles';

	/// en: 'Language'
	String get language => 'Language';

	/// en: 'No subtitles found'
	String get noSubtitlesFound => 'No subtitles found';

	/// en: 'Subtitle downloaded'
	String get subtitleDownloaded => 'Subtitle downloaded';

	/// en: 'Subtitle downloaded, but it could not be selected'
	String get subtitleDownloadedNotApplied => 'Subtitle downloaded, but it could not be selected';

	/// en: 'Failed to download subtitle'
	String get subtitleDownloadFailed => 'Failed to download subtitle';

	/// en: 'Search languages...'
	String get searchLanguages => 'Search languages...';

	/// en: 'Skip Intro'
	String get skipIntro => 'Skip Intro';

	/// en: 'Skip Credits'
	String get skipCredits => 'Skip Credits';

	/// en: 'Next Episode'
	String get nextEpisode => 'Next Episode';

	/// en: 'Track ${n}'
	String subtitleTrack({required Object n}) => 'Track ${n}';

	/// en: 'Subtitle ${name}'
	String subtitleFile({required Object name}) => 'Subtitle ${name}';

	/// en: '${label} (Forced)'
	String forcedTrack({required Object label}) => '${label} (Forced)';

	/// en: 'Subtitles: Off'
	String get osdSubtitlesOff => 'Subtitles: Off';

	/// en: 'Subtitles: ${track}'
	String osdSubtitles({required Object track}) => 'Subtitles: ${track}';

	/// en: 'Audio: ${track}'
	String osdAudio({required Object track}) => 'Audio: ${track}';
}

// Path: messages
class Translations$messages$en {
	Translations$messages$en.internal(this._root);

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

	/// en: 'Auto-removed: ${title}'
	String autoRemovedWatchedDownload({required Object title}) => 'Auto-removed: ${title}';

	/// en: '(one) {Auto-removed ${n} watched download} (other) {Auto-removed ${n} watched downloads}'
	String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'Auto-removed ${n} watched download',
		other: 'Auto-removed ${n} watched downloads',
	);

	/// en: 'Removed from Continue Watching'
	String get removedFromContinueWatching => 'Removed from Continue Watching';

	/// en: 'Error: ${error}'
	String errorLoading({required Object error}) => 'Error: ${error}';

	/// en: 'Some media servers could not be searched. Showing available results.'
	String get searchPartialResults => 'Some media servers could not be searched. Showing available results.';

	/// en: 'The stream was interrupted. Press play or seek to retry.'
	String get streamInterrupted => 'The stream was interrupted. Press play or seek to retry.';

	/// en: 'The live stream was interrupted. Press play to retry.'
	String get liveStreamInterrupted => 'The live stream was interrupted. Press play to retry.';

	/// en: 'File information not available'
	String get fileInfoNotAvailable => 'File information not available';

	/// en: 'Sign in to the media server again to play this item.'
	String get playbackAuthenticationRequired => 'Sign in to the media server again to play this item.';

	/// en: 'The media server is unavailable. Try again later.'
	String get playbackServerUnavailable => 'The media server is unavailable. Try again later.';

	/// en: 'The server returned invalid playback information.'
	String get playbackDataInvalid => 'The server returned invalid playback information.';

	/// en: 'Playback was canceled.'
	String get playbackCancelled => 'Playback was canceled.';

	/// en: 'Playback could not be started.'
	String get playbackFailed => 'Playback could not be started.';

	/// en: 'This content is no longer available.'
	String get mediaUnavailable => 'This content is no longer available.';

	/// en: 'Error loading file info: ${error}'
	String errorLoadingFileInfo({required Object error}) => 'Error loading file info: ${error}';

	/// en: 'Error loading series'
	String get errorLoadingSeries => 'Error loading series';

	/// en: 'Music playback is not yet supported'
	String get musicNotSupported => 'Music playback is not yet supported';

	/// en: 'No description available'
	String get noDescriptionAvailable => 'No description available';

	/// en: 'No profiles available'
	String get noProfilesAvailable => 'No profiles available';

	/// en: 'Contact your server administrator to add profiles'
	String get contactAdminForProfiles => 'Contact your server administrator to add profiles';

	/// en: 'Unable to determine library section for this item'
	String get unableToDetermineLibrarySection => 'Unable to determine library section for this item';

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

	/// en: 'Are you sure you want to log out?'
	String get logoutConfirm => 'Are you sure you want to log out?';

	/// en: 'No seasons found'
	String get noSeasonsFound => 'No seasons found';

	/// en: 'Couldn't load seasons'
	String get seasonsLoadFailed => 'Couldn\'t load seasons';

	/// en: 'No episodes found in first season'
	String get noEpisodesFound => 'No episodes found in first season';

	/// en: 'No episodes found'
	String get noEpisodesFoundGeneral => 'No episodes found';

	/// en: 'Couldn't load episodes'
	String get episodesLoadFailed => 'Couldn\'t load episodes';

	/// en: 'No results found'
	String get noResultsFound => 'No results found';

	/// en: 'Sleep timer set for ${label}'
	String sleepTimerSet({required Object label}) => 'Sleep timer set for ${label}';

	/// en: 'No items available'
	String get noItemsAvailable => 'No items available';

	/// en: 'Failed to create a play queue — no items'
	String get failedToCreatePlayQueueNoItems => 'Failed to create a play queue — no items';

	/// en: 'Failed to ${action}: ${error}'
	String failedPlayback({required Object action, required Object error}) => 'Failed to ${action}: ${error}';

	/// en: 'Switching to compatible player...'
	String get switchingToCompatiblePlayer => 'Switching to compatible player...';

	/// en: 'Playback failed'
	String get serverLimitTitle => 'Playback failed';

	/// en: 'Server error (HTTP 500). A bandwidth/transcoding limit likely rejected this session. Ask the owner to adjust it.'
	String get serverLimitBody => 'Server error (HTTP 500). A bandwidth/transcoding limit likely rejected this session. Ask the owner to adjust it.';

	/// en: 'File unavailable'
	String get mediaUnreadableTitle => 'File unavailable';

	/// en: 'The server found this item but could not read its file (HTTP 404). The file was probably moved, deleted, or its storage is offline. Ask the server owner to check the file and rescan the library.'
	String get mediaUnreadableBody => 'The server found this item but could not read its file (HTTP 404). The file was probably moved, deleted, or its storage is offline. Ask the server owner to check the file and rescan the library.';

	/// en: 'Stream unavailable'
	String get serverBusyTitle => 'Stream unavailable';

	/// en: 'The server kept refusing to stream this file (HTTP 503). It may be restarting, busy, or the file's storage may be offline. Try again in a moment — if it keeps happening, ask the server owner to check the server and the file's storage.'
	String get serverBusyBody => 'The server kept refusing to stream this file (HTTP 503). It may be restarting, busy, or the file\'s storage may be offline. Try again in a moment — if it keeps happening, ask the server owner to check the server and the file\'s storage.';

	/// en: 'Logs uploaded'
	String get logsUploaded => 'Logs uploaded';

	/// en: 'Failed to upload logs'
	String get logsUploadFailed => 'Failed to upload logs';

	/// en: 'Log ID'
	String get logId => 'Log ID';

	/// en: 'Subtitles are burned into this stream. Change them from the subtitle menu.'
	String get burnedSubtitlesUseMenu => 'Subtitles are burned into this stream. Change them from the subtitle menu.';

	/// en: 'No video URL available'
	String get noVideoUrl => 'No video URL available';

	/// en: 'The server returned no playable media sources'
	String get playbackNoMediaSources => 'The server returned no playable media sources';

	/// en: 'Playback was started before its data was ready'
	String get playbackDataNotPrepared => 'Playback was started before its data was ready';

	/// en: 'Stream selection is not available for this source'
	String get streamSelectionUnavailable => 'Stream selection is not available for this source';

	/// en: 'Could not apply the selected streams'
	String get streamSelectionFailed => 'Could not apply the selected streams';

	/// en: 'No server is available for the active profile'
	String get serverUnavailableForProfile => 'No server is available for the active profile';
}

// Path: subtitlingStyling
class Translations$subtitlingStyling$en {
	Translations$subtitlingStyling$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Text'
	String get text => 'Text';

	/// en: 'Border'
	String get border => 'Border';

	/// en: 'Background'
	String get background => 'Background';

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

	/// en: 'ASS Override'
	String get assOverride => 'ASS Override';

	/// en: 'Scale'
	String get overrideScale => 'Scale';

	/// en: 'Force'
	String get overrideForce => 'Force';

	/// en: 'Remove styling'
	String get overrideStrip => 'Remove styling';

	/// en: 'Top'
	String get positionTop => 'Top';

	/// en: 'Bottom'
	String get positionBottom => 'Bottom';

	/// en: 'Anchor to Screen'
	String get anchorToScreen => 'Anchor to Screen';

	/// en: 'Show text subtitles in the black bars below widescreen video'
	String get anchorToScreenDescription => 'Show text subtitles in the black bars below widescreen video';

	/// en: 'Bold'
	String get bold => 'Bold';

	/// en: 'Italic'
	String get italic => 'Italic';

	/// en: 'Render Resolution'
	String get renderResolution => 'Render Resolution';

	/// en: 'Screen resolution'
	String get renderResolutionScreen => 'Screen resolution';

	/// en: 'Video resolution'
	String get renderResolutionVideo => 'Video resolution';
}

// Path: mpvConfig
class Translations$mpvConfig$en {
	Translations$mpvConfig$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'mpv.conf'
	String get title => 'mpv.conf';

	/// en: 'Advanced video player settings'
	String get description => 'Advanced video player settings';

	/// en: 'Presets'
	String get presets => 'Presets';

	/// en: 'No saved presets'
	String get noPresets => 'No saved presets';

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

	/// en: 'gpu-api=vulkan hwdec=auto # comment'
	String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comment';

	/// en: 'option=value'
	String get lineHint => 'option=value';

	/// en: 'Add line'
	String get addLine => 'Add line';

	/// en: 'Remove line'
	String get removeLine => 'Remove line';

	/// en: 'vo, gpu-context and gpu-api are ignored on Linux: embedded video always renders through vo=libmpv on the video plane, and gpu-next (which compute shaders like ArtCNN need) cannot run embedded.'
	String get embeddedVoHint => 'vo, gpu-context and gpu-api are ignored on Linux: embedded video always renders through vo=libmpv on the video plane, and gpu-next (which compute shaders like ArtCNN need) cannot run embedded.';
}

// Path: dialog
class Translations$dialog$en {
	Translations$dialog$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Confirm Action'
	String get confirmAction => 'Confirm Action';
}

// Path: profiles
class Translations$profiles$en {
	Translations$profiles$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Add Plezy profile'
	String get addPlezyProfile => 'Add Plezy profile';

	/// en: 'Switching profile…'
	String get switchingProfile => 'Switching profile…';

	/// en: 'Delete this profile?'
	String get deleteThisProfileTitle => 'Delete this profile?';

	/// en: 'Remove ${displayName}. Connections aren't affected.'
	String deleteThisProfileMessage({required Object displayName}) => 'Remove ${displayName}. Connections aren\'t affected.';

	/// en: 'Active'
	String get active => 'Active';

	/// en: 'Manage'
	String get manage => 'Manage';

	/// en: 'Delete'
	String get delete => 'Delete';

	/// en: 'Sign out'
	String get signOut => 'Sign out';

	/// en: 'Sign out of Plex?'
	String get signOutPlexTitle => 'Sign out of Plex?';

	/// en: 'Remove ${displayName} and all Plex Home users? Sign back in anytime.'
	String signOutPlexMessage({required Object displayName}) => 'Remove ${displayName} and all Plex Home users? Sign back in anytime.';

	/// en: 'Signed out of Plex.'
	String get signedOutPlex => 'Signed out of Plex.';

	/// en: 'Sign out failed.'
	String get signOutFailed => 'Sign out failed.';

	/// en: 'Profiles'
	String get sectionTitle => 'Profiles';

	/// en: 'Add profiles to mix managed users and local identities'
	String get summarySingle => 'Add profiles to mix managed users and local identities';

	/// en: '${count} profiles · active: ${activeName}'
	String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} profiles · active: ${activeName}';

	/// en: '${count} profiles'
	String summaryMultiple({required Object count}) => '${count} profiles';

	/// en: 'Remove connection?'
	String get removeConnectionTitle => 'Remove connection?';

	/// en: 'Remove ${displayName}'s access to ${connectionLabel}. Other profiles keep it.'
	String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'Remove ${displayName}\'s access to ${connectionLabel}. Other profiles keep it.';

	/// en: 'Delete profile?'
	String get deleteProfileTitle => 'Delete profile?';

	/// en: 'Remove ${displayName} and its connections. Servers stay available.'
	String deleteProfileMessage({required Object displayName}) => 'Remove ${displayName} and its connections. Servers stay available.';

	/// en: 'Profile name'
	String get profileNameLabel => 'Profile name';

	/// en: 'PIN protection'
	String get pinProtectionLabel => 'PIN protection';

	/// en: 'PIN managed by Plex. Edit on plex.tv.'
	String get pinManagedByPlex => 'PIN managed by Plex. Edit on plex.tv.';

	/// en: 'No PIN set. To require one, edit the home user on plex.tv.'
	String get noPinSetEditOnPlex => 'No PIN set. To require one, edit the home user on plex.tv.';

	/// en: 'Set PIN'
	String get setPin => 'Set PIN';

	/// en: 'Set PIN'
	String get setPinTitle => 'Set PIN';

	/// en: 'Confirm PIN'
	String get confirmPinTitle => 'Confirm PIN';

	/// en: 'PIN set'
	String get pinSet => 'PIN set';

	/// en: 'Change'
	String get changePin => 'Change';

	/// en: 'Remove'
	String get removePin => 'Remove';

	/// en: 'Connections'
	String get connectionsLabel => 'Connections';

	/// en: 'Add'
	String get add => 'Add';

	/// en: 'Delete profile'
	String get deleteProfileButton => 'Delete profile';

	/// en: 'No connections — add one to use this profile.'
	String get noConnectionsHint => 'No connections — add one to use this profile.';

	/// en: 'No connections'
	String get noConnections => 'No connections';

	/// en: 'Plex Home account'
	String get plexHomeAccount => 'Plex Home account';

	/// en: 'Plex account: ${account}'
	String plexAccountChip({required Object account}) => 'Plex account: ${account}';

	/// en: '${user} via ${account}'
	String plexAccountUserChip({required Object user, required Object account}) => '${user} via ${account}';

	/// en: 'Default'
	String get connectionDefault => 'Default';

	/// en: 'as ${displayName}'
	String connectionAs({required Object displayName}) => 'as ${displayName}';

	/// en: 'Make default'
	String get makeDefault => 'Make default';

	/// en: 'Remove'
	String get removeConnection => 'Remove';

	/// en: 'Profile renamed.'
	String get profileRenamed => 'Profile renamed.';

	/// en: 'Add to ${displayName}'
	String borrowAddTo({required Object displayName}) => 'Add to ${displayName}';

	/// en: 'Borrow another profile's connection. PIN-protected profiles require a PIN.'
	String get borrowExplain => 'Borrow another profile\'s connection. PIN-protected profiles require a PIN.';

	/// en: 'Nothing to borrow yet.'
	String get borrowEmpty => 'Nothing to borrow yet.';

	/// en: 'Connect Plex, Jellyfin, or Emby to another profile first.'
	String get borrowEmptySubtitle => 'Connect Plex, Jellyfin, or Emby to another profile first.';

	/// en: 'Available connections could not be loaded. Try again.'
	String get borrowLoadFailed => 'Available connections could not be loaded. Try again.';

	/// en: 'From ${displayName}'
	String borrowFromProfile({required Object displayName}) => 'From ${displayName}';

	/// en: 'Connection borrowed.'
	String get borrowConnectionBorrowed => 'Connection borrowed.';

	/// en: 'Failed to borrow connection.'
	String get borrowFailed => 'Failed to borrow connection.';

	/// en: 'Incorrect PIN.'
	String get incorrectPin => 'Incorrect PIN.';

	/// en: 'Incorrect PIN. Please try again.'
	String get incorrectPinTryAgain => 'Incorrect PIN. Please try again.';

	/// en: 'Source profile is missing its parent account.'
	String get sourceProfileMissingParentAccount => 'Source profile is missing its parent account.';

	/// en: 'Could not load your Plex Home users. Check your connection and try again.'
	String get failedToLoadHomeUsers => 'Could not load your Plex Home users. Check your connection and try again.';

	/// en: 'Failed to verify PIN.'
	String get failedToVerifyPin => 'Failed to verify PIN.';

	/// en: 'New profile'
	String get newProfile => 'New profile';

	/// en: 'e.g. Guests, Kids, Family Room'
	String get profileNameHint => 'e.g. Guests, Kids, Family Room';

	/// en: 'PIN protection (optional)'
	String get pinProtectionOptional => 'PIN protection (optional)';

	/// en: '4-digit PIN required to switch profiles.'
	String get pinExplain => '4-digit PIN required to switch profiles.';

	/// en: 'Continue'
	String get continueButton => 'Continue';

	/// en: 'PINs don't match'
	String get pinsDontMatch => 'PINs don\'t match';

	/// en: 'The Plex profile token resolved to an unexpected server'
	String get tokenIdentityMismatch => 'The Plex profile token resolved to an unexpected server';
}

// Path: connections
class Translations$connections$en {
	Translations$connections$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Connections'
	String get sectionTitle => 'Connections';

	/// en: 'Add connection'
	String get addConnection => 'Add connection';

	/// en: 'Sign in with Plex or connect a Jellyfin or Emby server'
	String get addConnectionSubtitleNoProfile => 'Sign in with Plex or connect a Jellyfin or Emby server';

	/// en: 'Add to ${displayName}: Plex, Jellyfin, Emby, or another profile connection'
	String addConnectionSubtitleScoped({required Object displayName}) => 'Add to ${displayName}: Plex, Jellyfin, Emby, or another profile connection';

	/// en: 'Session expired for ${name}'
	String sessionExpiredOne({required Object name}) => 'Session expired for ${name}';

	/// en: 'Session expired for ${count} servers'
	String sessionExpiredMany({required Object count}) => 'Session expired for ${count} servers';

	/// en: 'Sign in again'
	String get signInAgain => 'Sign in again';

	/// en: 'Edit ${product} connection'
	String editMediaBrowserTitle({required Object product}) => 'Edit ${product} connection';

	/// en: 'Add or remove URLs for ${serverName}. Plezy will use the reachable URL with the lowest latency.'
	String editMediaBrowserIntro({required Object serverName}) => 'Add or remove URLs for ${serverName}. Plezy will use the reachable URL with the lowest latency.';
}

// Path: accountPreferences
class Translations$accountPreferences$en {
	Translations$accountPreferences$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Account preferences'
	String get sectionTitle => 'Account preferences';

	/// en: 'Audio, subtitle and library options saved on ${account}'
	String hubSubtitleSingle({required Object account}) => 'Audio, subtitle and library options saved on ${account}';

	/// en: 'Audio, subtitle and library options saved on ${count} accounts'
	String hubSubtitleMultiple({required Object count}) => 'Audio, subtitle and library options saved on ${count} accounts';

	/// en: 'Every account stores its own preferences. Pick the one to edit.'
	String get pickAccount => 'Every account stores its own preferences. Pick the one to edit.';

	/// en: 'These options are saved on the account itself, so every app signed in to it uses them — including Plezy on your other devices.'
	String get storedOnAccount => 'These options are saved on the account itself, so every app signed in to it uses them — including Plezy on your other devices.';

	/// en: 'No accounts to configure'
	String get noAccounts => 'No accounts to configure';

	/// en: 'Sign in to Plex, or connect a Jellyfin or Emby server, and the preferences stored on that account show up here.'
	String get noAccountsHint => 'Sign in to Plex, or connect a Jellyfin or Emby server, and the preferences stored on that account show up here.';

	/// en: 'Can't reach this account'
	String get unavailable => 'Can\'t reach this account';

	/// en: 'Couldn't load these preferences'
	String get loadFailed => 'Couldn\'t load these preferences';

	/// en: 'No preference'
	String get noPreference => 'No preference';

	/// en: 'Not set'
	String get notSet => 'Not set';

	late final Translations$accountPreferences$groups$en groups = Translations$accountPreferences$groups$en.internal(_root);

	/// en: 'Preferred audio language'
	String get preferredAudioLanguage => 'Preferred audio language';

	/// en: 'Choose audio by language'
	String get autoSelectAudio => 'Choose audio by language';

	/// en: 'Off keeps whatever audio track the file marks as default.'
	String get autoSelectAudioDescription => 'Off keeps whatever audio track the file marks as default.';

	/// en: 'Preferred subtitle language'
	String get preferredSubtitleLanguage => 'Preferred subtitle language';

	/// en: 'Turn subtitles on'
	String get subtitleMode => 'Turn subtitles on';

	late final Translations$accountPreferences$subtitleModes$en subtitleModes = Translations$accountPreferences$subtitleModes$en.internal(_root);

	/// en: 'SDH subtitles'
	String get subtitleAccessibility => 'SDH subtitles';

	late final Translations$accountPreferences$subtitleAccessibilityOptions$en subtitleAccessibilityOptions = Translations$accountPreferences$subtitleAccessibilityOptions$en.internal(_root);

	/// en: 'Forced subtitles'
	String get forcedSubtitles => 'Forced subtitles';

	late final Translations$accountPreferences$forcedSubtitleOptions$en forcedSubtitleOptions = Translations$accountPreferences$forcedSubtitleOptions$en.internal(_root);

	/// en: 'Show missing episodes'
	String get displayMissingEpisodes => 'Show missing episodes';

	/// en: 'List episodes the server knows about but has no file for.'
	String get displayMissingEpisodesDescription => 'List episodes the server knows about but has no file for.';

	/// en: 'Hide watched items in Latest'
	String get hidePlayedInLatest => 'Hide watched items in Latest';

	/// en: 'Leave items you have already watched out of the server's Latest rows.'
	String get hidePlayedInLatestDescription => 'Leave items you have already watched out of the server\'s Latest rows.';

	/// en: 'Show the Collections view'
	String get displayCollectionsView => 'Show the Collections view';

	/// en: 'Offer the server's Collections view alongside your libraries.'
	String get displayCollectionsViewDescription => 'Offer the server\'s Collections view alongside your libraries.';

	/// en: 'Keep rewatched shows in Next Up'
	String get rewatchingInNextUp => 'Keep rewatched shows in Next Up';

	/// en: 'Once you finish a show, start it again and Next Up follows the rewatch instead of dropping the show.'
	String get rewatchingInNextUpDescription => 'Once you finish a show, start it again and Next Up follows the rewatch instead of dropping the show.';

	/// en: 'Watched indicators'
	String get watchedIndicator => 'Watched indicators';

	late final Translations$accountPreferences$watchedIndicatorOptions$en watchedIndicatorOptions = Translations$accountPreferences$watchedIndicatorOptions$en.internal(_root);

	/// en: 'Ratings & reviews'
	String get mediaReviewsVisibility => 'Ratings & reviews';

	late final Translations$accountPreferences$mediaReviewsOptions$en mediaReviewsOptions = Translations$accountPreferences$mediaReviewsOptions$en.internal(_root);
}

// Path: discover
class Translations$discover$en {
	Translations$discover$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Discover'
	String get title => 'Discover';

	/// en: 'No content available'
	String get noContentAvailable => 'No content available';

	/// en: 'Add some media to your libraries'
	String get addMediaToLibraries => 'Add some media to your libraries';

	/// en: 'Continue Watching'
	String get continueWatching => 'Continue Watching';

	/// en: 'Continue Watching in ${library}'
	String continueWatchingIn({required Object library}) => 'Continue Watching in ${library}';

	/// en: 'Next Up'
	String get nextUp => 'Next Up';

	/// en: 'Next Up in ${library}'
	String nextUpIn({required Object library}) => 'Next Up in ${library}';

	/// en: 'Recently Added'
	String get recentlyAdded => 'Recently Added';

	/// en: 'Recently Added in ${library}'
	String recentlyAddedIn({required Object library}) => 'Recently Added in ${library}';

	/// en: 'Latest Albums in ${library}'
	String latestAlbumsIn({required Object library}) => 'Latest Albums in ${library}';

	/// en: 'Recently Played in ${library}'
	String recentlyPlayedIn({required Object library}) => 'Recently Played in ${library}';

	/// en: 'Most Played in ${library}'
	String mostPlayedIn({required Object library}) => 'Most Played in ${library}';

	/// en: 'S${season}E${episode}'
	String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';

	/// en: 'Overview'
	String get overview => 'Overview';

	/// en: 'Cast'
	String get cast => 'Cast';

	/// en: 'Trailers & Extras'
	String get extras => 'Trailers & Extras';

	/// en: 'Studio'
	String get studio => 'Studio';

	/// en: 'Rating'
	String get rating => 'Rating';

	/// en: 'Director'
	String get director => 'Director';

	/// en: 'Directors'
	String get directors => 'Directors';

	/// en: 'Movie'
	String get movie => 'Movie';

	/// en: 'TV Show'
	String get tvShow => 'TV Show';

	/// en: '${minutes} min left'
	String minutesLeft({required Object minutes}) => '${minutes} min left';

	/// en: 'More Like This'
	String get moreLikeThis => 'More Like This';

	/// en: '(one) {${n} title} (other) {${n} titles}'
	String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} title',
		other: '${n} titles',
	);
}

// Path: errors
class Translations$errors$en {
	Translations$errors$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Search failed: ${error}'
	String searchFailed({required Object error}) => 'Search failed: ${error}';

	/// en: 'Search could not reach any media server.'
	String get searchUnavailable => 'Search could not reach any media server.';

	/// en: 'Connection timeout while loading ${context}'
	String connectionTimeout({required Object context}) => 'Connection timeout while loading ${context}';

	/// en: 'Unable to connect to media server'
	String get connectionFailed => 'Unable to connect to media server';

	/// en: 'Unable to load ${context}. Please try again.'
	String unableToLoad({required Object context}) => 'Unable to load ${context}. Please try again.';

	/// en: 'No client available'
	String get noClientAvailable => 'No client available';

	/// en: 'Please enter a token'
	String get pleaseEnterToken => 'Please enter a token';

	/// en: 'Invalid token'
	String get invalidToken => 'Invalid token';

	/// en: 'Failed to verify token: ${error}'
	String failedToVerifyToken({required Object error}) => 'Failed to verify token: ${error}';

	/// en: 'Failed to switch to ${displayName}'
	String failedToSwitchProfile({required Object displayName}) => 'Failed to switch to ${displayName}';

	/// en: 'Failed to delete ${displayName}'
	String failedToDeleteProfile({required Object displayName}) => 'Failed to delete ${displayName}';

	/// en: 'Couldn't update rating'
	String get failedToRate => 'Couldn\'t update rating';
}

// Path: libraries
class Translations$libraries$en {
	Translations$libraries$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Libraries'
	String get title => 'Libraries';

	/// en: 'Library'
	String get fallbackTitle => 'Library';

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

	/// en: 'All libraries are hidden'
	String get allLibrariesHidden => 'All libraries are hidden';

	/// en: 'Hidden libraries (${count})'
	String hiddenLibrariesCount({required Object count}) => 'Hidden libraries (${count})';

	/// en: 'This library is empty'
	String get thisLibraryIsEmpty => 'This library is empty';

	/// en: 'No items match the active filters'
	String get noItemsMatchFilters => 'No items match the active filters';

	/// en: 'Reset filters'
	String get resetFilters => 'Reset filters';

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

	late final Translations$libraries$tabs$en tabs = Translations$libraries$tabs$en.internal(_root);
	late final Translations$libraries$groupings$en groupings = Translations$libraries$groupings$en.internal(_root);
	late final Translations$libraries$filterCategories$en filterCategories = Translations$libraries$filterCategories$en.internal(_root);
	late final Translations$libraries$sortLabels$en sortLabels = Translations$libraries$sortLabels$en.internal(_root);
}

// Path: about
class Translations$about$en {
	Translations$about$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'About'
	String get title => 'About';

	/// en: 'Open Source Licenses'
	String get openSourceLicenses => 'Open Source Licenses';

	/// en: 'Version ${version}'
	String versionLabel({required Object version}) => 'Version ${version}';

	/// en: 'A beautiful Plex, Jellyfin, and Emby client for Flutter'
	String get appDescription => 'A beautiful Plex, Jellyfin, and Emby client for Flutter';

	/// en: 'View licenses of third-party libraries'
	String get viewLicensesDescription => 'View licenses of third-party libraries';
}

// Path: serverSelection
class Translations$serverSelection$en {
	Translations$serverSelection$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'No servers found for ${username} (${email})'
	String noServersFoundForAccount({required Object username, required Object email}) => 'No servers found for ${username} (${email})';

	/// en: 'Failed to load servers: ${error}'
	String failedToLoadServers({required Object error}) => 'Failed to load servers: ${error}';

	/// en: 'No usable servers were found on this account'
	String get noValidServers => 'No usable servers were found on this account';
}

// Path: hubDetail
class Translations$hubDetail$en {
	Translations$hubDetail$en.internal(this._root);

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
class Translations$logs$en {
	Translations$logs$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Clear Logs'
	String get clearLogs => 'Clear Logs';

	/// en: 'Copy Logs'
	String get copyLogs => 'Copy Logs';

	/// en: 'Upload Logs'
	String get uploadLogs => 'Upload Logs';
}

// Path: startup
class Translations$startup$en {
	Translations$startup$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Plezy could not start'
	String get failedTitle => 'Plezy could not start';

	/// en: 'Something went wrong during startup. The details below identify what failed.'
	String get failedBody => 'Something went wrong during startup. The details below identify what failed.';

	/// en: 'Plezy's saved settings file is damaged and has to be rebuilt before Plezy can start. Retrying will not help — choose Repair storage.'
	String get failedBodyRepairable => 'Plezy\'s saved settings file is damaged and has to be rebuilt before Plezy can start. Retrying will not help — choose Repair storage.';

	/// en: 'Step'
	String get phaseLabel => 'Step';

	/// en: 'Show details'
	String get showDetails => 'Show details';

	/// en: 'Hide details'
	String get hideDetails => 'Hide details';

	/// en: 'Copy details'
	String get copyDetails => 'Copy details';

	/// en: 'Details copied to clipboard'
	String get detailsCopied => 'Details copied to clipboard';

	/// en: 'Upload details'
	String get uploadDetails => 'Upload details';

	/// en: 'Repair storage'
	String get repairStorage => 'Repair storage';

	/// en: 'Repair stored data?'
	String get repairTitle => 'Repair stored data?';

	/// en: 'Plezy's settings file is damaged and cannot be read. Repairing resets every setting to its default.'
	String get repairBodyCommon => 'Plezy\'s settings file is damaged and cannot be read. Repairing resets every setting to its default.';

	/// en: 'One saved sign-in is damaged and cannot be read. Repairing removes just that one; your other settings are left alone.'
	String get repairBodyOneCredential => 'One saved sign-in is damaged and cannot be read. Repairing removes just that one; your other settings are left alone.';

	/// en: 'Your servers and profiles should stay signed in.'
	String get repairBodySignInsKept => 'Your servers and profiles should stay signed in.';

	/// en: 'The key protecting your saved sign-ins cannot be recovered from this file, so you will have to sign in to every server and profile again. Nothing on your media server is affected.'
	String get repairBodySignInsLost => 'The key protecting your saved sign-ins cannot be recovered from this file, so you will have to sign in to every server and profile again. Nothing on your media server is affected.';

	/// en: 'Trackers (MAL, AniList, Simkl, Trakt) and Seerr are stored separately and may or may not survive. Plezy will tell you exactly what it kept.'
	String get repairBodySessionsUncertain => 'Trackers (MAL, AniList, Simkl, Trakt) and Seerr are stored separately and may or may not survive. Plezy will tell you exactly what it kept.';

	/// en: 'Repair'
	String get repairConfirm => 'Repair';

	/// en: 'Storage repaired'
	String get repairSucceeded => 'Storage repaired';

	/// en: 'Storage repaired — restart required'
	String get repairNeedsRestart => 'Storage repaired — restart required';

	/// en: 'Your data was repaired, but Plezy has to start fresh before it can use it. Close Plezy and open it again.'
	String get restartRequiredBody => 'Your data was repaired, but Plezy has to start fresh before it can use it. Close Plezy and open it again.';

	/// en: 'Quit Plezy'
	String get quitPlezy => 'Quit Plezy';

	/// en: 'Repair failed'
	String get repairFailed => 'Repair failed';

	/// en: 'Your servers and profiles are still signed in.'
	String get repairKeptSignIns => 'Your servers and profiles are still signed in.';

	/// en: 'The key protecting your saved sign-ins could not be recovered. You will have to sign in to every server and profile again.'
	String get repairLostSignIns => 'The key protecting your saved sign-ins could not be recovered. You will have to sign in to every server and profile again.';

	/// en: 'At least one tracker or Seerr connection was lost and has to be reconnected.'
	String get repairLostSessions => 'At least one tracker or Seerr connection was lost and has to be reconnected.';

	/// en: 'A copy of the damaged file was kept'
	String get backupTitle => 'A copy of the damaged file was kept';

	/// en: 'It contains your sign-in credentials. Do not upload or share it.'
	String get backupWarning => 'It contains your sign-in credentials. Do not upload or share it.';

	/// en: 'Delete copy'
	String get deleteBackup => 'Delete copy';

	/// en: 'Copy deleted.'
	String get backupDeleted => 'Copy deleted.';

	/// en: 'Plezy failed to start last time'
	String get previousFailureTitle => 'Plezy failed to start last time';
}

// Path: licenses
class Translations$licenses$en {
	Translations$licenses$en.internal(this._root);

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
class Translations$navigation$en {
	Translations$navigation$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Libraries'
	String get libraries => 'Libraries';

	/// en: 'Downloads'
	String get downloads => 'Downloads';

	/// en: 'Live TV'
	String get liveTv => 'Live TV';

	/// en: 'Explore'
	String get explore => 'Explore';
}

// Path: explore
class Translations$explore$en {
	Translations$explore$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Explore'
	String get title => 'Explore';

	/// en: 'Select source'
	String get selectSource => 'Select source';

	late final Translations$explore$rows$en rows = Translations$explore$rows$en.internal(_root);
	late final Translations$explore$status$en status = Translations$explore$status$en.internal(_root);

	/// en: '(one) {${n} episode} (other) {${n} episodes}'
	String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} episode',
		other: '${n} episodes',
	);

	/// en: 'Cast'
	String get cast => 'Cast';

	/// en: 'Characters'
	String get characters => 'Characters';

	/// en: 'Add to Watchlist'
	String get addToWatchlist => 'Add to Watchlist';

	/// en: 'Remove from Watchlist'
	String get removeFromWatchlist => 'Remove from Watchlist';

	/// en: 'Added to watchlist'
	String get addedToWatchlist => 'Added to watchlist';

	/// en: 'Removed from watchlist'
	String get removedFromWatchlist => 'Removed from watchlist';

	/// en: 'Couldn't update watchlist'
	String get watchlistUpdateFailed => 'Couldn\'t update watchlist';

	/// en: 'Couldn't match this item to a watchlist'
	String get watchlistNoMatch => 'Couldn\'t match this item to a watchlist';

	/// en: 'Not in your library'
	String get notInLibrary => 'Not in your library';

	/// en: 'In these libraries'
	String get inTheseLibraries => 'In these libraries';

	/// en: 'Checking your library...'
	String get checkingLibrary => 'Checking your library...';

	/// en: '(one) {Couldn't check ${n} server} (other) {Couldn't check ${n} servers}'
	String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'Couldn\'t check ${n} server',
		other: 'Couldn\'t check ${n} servers',
	);

	/// en: 'Nothing here yet'
	String get emptyTitle => 'Nothing here yet';

	/// en: 'Rows from ${source} will appear here once they have content.'
	String emptyMessage({required Object source}) => 'Rows from ${source} will appear here once they have content.';

	/// en: 'Search ${source}'
	String searchHint({required Object source}) => 'Search ${source}';

	/// en: 'No results for "${query}"'
	String searchEmpty({required Object query}) => 'No results for "${query}"';

	/// en: 'Search for movies and shows on ${source}.'
	String searchPrompt({required Object source}) => 'Search for movies and shows on ${source}.';

	/// en: 'Search failed. Check your connection and try again.'
	String get searchFailed => 'Search failed. Check your connection and try again.';

	late final Translations$explore$badge$en badge = Translations$explore$badge$en.internal(_root);
	late final Translations$explore$stats$en stats = Translations$explore$stats$en.internal(_root);
	late final Translations$explore$season$en season = Translations$explore$season$en.internal(_root);
	late final Translations$explore$format$en format = Translations$explore$format$en.internal(_root);
	late final Translations$explore$sourceMaterial$en sourceMaterial = Translations$explore$sourceMaterial$en.internal(_root);
	late final Translations$explore$creditRole$en creditRole = Translations$explore$creditRole$en.internal(_root);
	late final Translations$explore$relation$en relation = Translations$explore$relation$en.internal(_root);

	/// en: 'Airs ${day} at ${time}'
	String broadcast({required Object day, required Object time}) => 'Airs ${day} at ${time}';

	/// en: 'Airs ${day} at ${time} ${timezone}'
	String broadcastWithZone({required Object day, required Object time, required Object timezone}) => 'Airs ${day} at ${time} ${timezone}';

	late final Translations$explore$detail$en detail = Translations$explore$detail$en.internal(_root);

	/// en: '(one) {${n} result} (other) {${n} results}'
	String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} result',
		other: '${n} results',
	);
}

// Path: liveTv
class Translations$liveTv$en {
	Translations$liveTv$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Live TV'
	String get title => 'Live TV';

	/// en: 'Guide'
	String get guide => 'Guide';

	/// en: 'No channels available'
	String get noChannels => 'No channels available';

	/// en: 'No DVR configured on any server'
	String get noDvr => 'No DVR configured on any server';

	/// en: 'Live TV server is not available.'
	String get serverUnavailable => 'Live TV server is not available.';

	/// en: 'Live TV server is not connected.'
	String get serverNotConnected => 'Live TV server is not connected.';

	/// en: 'No program data available'
	String get noPrograms => 'No program data available';

	/// en: 'Live stream failed'
	String get liveStreamFailed => 'Live stream failed';

	/// en: 'Unknown Program'
	String get unknownProgram => 'Unknown Program';

	/// en: 'Unknown'
	String get unknownHub => 'Unknown';

	/// en: 'Unknown error'
	String get unknownError => 'Unknown error';

	/// en: 'Channel ${number}'
	String channelNumber({required Object number}) => 'Channel ${number}';

	/// en: 'Unknown channel'
	String get unknownChannel => 'Unknown channel';

	/// en: 'LIVE'
	String get live => 'LIVE';

	/// en: 'Reload Guide'
	String get reloadGuide => 'Reload Guide';

	/// en: 'Search Guide'
	String get searchGuide => 'Search Guide';

	/// en: 'Search channels & programs'
	String get searchHint => 'Search channels & programs';

	/// en: 'No matches for "${query}"'
	String searchNoResults({required Object query}) => 'No matches for "${query}"';

	/// en: 'Channels'
	String get channelsSection => 'Channels';

	/// en: 'Programs'
	String get programsSection => 'Programs';

	/// en: 'Now'
	String get now => 'Now';

	/// en: 'Today'
	String get today => 'Today';

	/// en: 'Tomorrow'
	String get tomorrow => 'Tomorrow';

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

	/// en: 'Favorites'
	String get favorites => 'Favorites';

	/// en: 'Reorder Favorites'
	String get reorderFavorites => 'Reorder Favorites';

	/// en: 'No favorite channels'
	String get noFavoriteChannels => 'No favorite channels';

	/// en: 'Show all channels, then long-press a channel to add it to your favorites.'
	String get noFavoriteChannelsHint => 'Show all channels, then long-press a channel to add it to your favorites.';

	/// en: 'Show All Channels'
	String get showAllChannels => 'Show All Channels';

	/// en: 'Could not load favorites. Check your connection and try again.'
	String get favoritesLoadFailed => 'Could not load favorites. Check your connection and try again.';

	/// en: 'Could not update favorites. Check your connection and try again.'
	String get favoritesUpdateFailed => 'Could not update favorites. Check your connection and try again.';

	/// en: 'Join Session in Progress'
	String get joinSession => 'Join Session in Progress';

	/// en: 'Watch from start (${minutes} min ago)'
	String watchFromStart({required Object minutes}) => 'Watch from start (${minutes} min ago)';

	/// en: 'Watch Live'
	String get watchLive => 'Watch Live';

	/// en: 'Go to Live'
	String get goToLive => 'Go to Live';

	/// en: 'Record'
	String get record => 'Record';

	/// en: 'Record Episode'
	String get recordEpisode => 'Record Episode';

	/// en: 'Record Series'
	String get recordSeries => 'Record Series';

	/// en: 'Record Options'
	String get recordOptions => 'Record Options';

	/// en: 'Save to'
	String get saveTo => 'Save to';

	/// en: 'Recordings'
	String get recordings => 'Recordings';

	/// en: 'Scheduled'
	String get scheduledRecordings => 'Scheduled';

	/// en: 'Recording Rules'
	String get recordingRules => 'Recording Rules';

	/// en: 'Nothing scheduled to record'
	String get noScheduledRecordings => 'Nothing scheduled to record';

	/// en: 'Manage recording'
	String get manageRecording => 'Manage recording';

	/// en: 'Cancel recording'
	String get cancelRecording => 'Cancel recording';

	/// en: 'Cancel this recording?'
	String get cancelRecordingTitle => 'Cancel this recording?';

	/// en: '${title} will no longer be recorded.'
	String cancelRecordingMessage({required Object title}) => '${title} will no longer be recorded.';

	/// en: 'Delete rule'
	String get deleteRule => 'Delete rule';

	/// en: 'Delete recording rule?'
	String get deleteRuleTitle => 'Delete recording rule?';

	/// en: 'Future episodes of ${title} will not be recorded.'
	String deleteRuleMessage({required Object title}) => 'Future episodes of ${title} will not be recorded.';

	/// en: 'Recording scheduled'
	String get recordingScheduled => 'Recording scheduled';

	/// en: 'This program is already scheduled'
	String get alreadyScheduled => 'This program is already scheduled';

	/// en: 'DVR settings require an admin account'
	String get dvrAdminRequired => 'DVR settings require an admin account';

	/// en: 'Couldn't schedule recording'
	String get recordingFailed => 'Couldn\'t schedule recording';

	/// en: 'Couldn't determine recording library'
	String get recordingTargetMissing => 'Couldn\'t determine recording library';

	/// en: 'Recording not available for this program'
	String get recordNotAvailable => 'Recording not available for this program';

	/// en: 'Recording canceled'
	String get recordingCancelled => 'Recording canceled';

	/// en: 'Recording rule deleted'
	String get recordingRuleDeleted => 'Recording rule deleted';

	/// en: 'Re-evaluate rules'
	String get processRecordingRules => 'Re-evaluate rules';

	/// en: 'Recording now'
	String get recordingInProgress => 'Recording now';

	/// en: '${count} scheduled'
	String recordingsCount({required Object count}) => '${count} scheduled';

	/// en: 'Edit rule'
	String get editRule => 'Edit rule';

	/// en: 'Edit'
	String get editRuleAction => 'Edit';

	/// en: 'Recording rule updated'
	String get recordingRuleUpdated => 'Recording rule updated';

	/// en: 'Guide refresh requested'
	String get guideReloadRequested => 'Guide refresh requested';

	/// en: 'Rule re-evaluation requested'
	String get rulesProcessRequested => 'Rule re-evaluation requested';

	/// en: 'Record show'
	String get recordShow => 'Record show';

	late final Translations$liveTv$recordSettings$en recordSettings = Translations$liveTv$recordSettings$en.internal(_root);

	/// en: 'Starting in ${minutes} min'
	String startingInMinutes({required Object minutes}) => 'Starting in ${minutes} min';

	/// en: '${day} at ${time}'
	String dayAtTime({required Object day, required Object time}) => '${day} at ${time}';

	/// en: '${product} returned invalid Live TV playback data'
	String invalidPlaybackData({required Object product}) => '${product} returned invalid Live TV playback data';

	/// en: 'Could not start the live channel'
	String get failedToStartChannel => 'Could not start the live channel';

	/// en: 'Could not build the stream URL'
	String get failedToBuildStreamUrl => 'Could not build the stream URL';
}

// Path: collections
class Translations$collections$en {
	Translations$collections$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Collections'
	String get title => 'Collections';

	/// en: 'Collection'
	String get collection => 'Collection';

	/// en: 'Collection is empty'
	String get empty => 'Collection is empty';

	/// en: 'Delete Collection'
	String get deleteCollection => 'Delete Collection';

	/// en: 'Delete "${title}"? This can't be undone.'
	String deleteConfirm({required Object title}) => 'Delete "${title}"? This can\'t be undone.';

	/// en: 'Collection deleted'
	String get deleted => 'Collection deleted';

	/// en: 'Failed to delete collection'
	String get deleteFailed => 'Failed to delete collection';

	/// en: 'Failed to delete collection: ${error}'
	String deleteFailedWithError({required Object error}) => 'Failed to delete collection: ${error}';

	/// en: 'Select Collection'
	String get selectCollection => 'Select Collection';

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

	/// en: 'Search collections...'
	String get searchCollections => 'Search collections...';
}

// Path: playlists
class Translations$playlists$en {
	Translations$playlists$en.internal(this._root);

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

	/// en: 'Search playlists...'
	String get searchPlaylists => 'Search playlists...';

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

// Path: music
class Translations$music$en {
	Translations$music$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Go to album'
	String get goToAlbum => 'Go to album';

	/// en: 'Go to artist'
	String get goToArtist => 'Go to artist';

	/// en: 'Instant Mix'
	String get instantMix => 'Instant Mix';

	/// en: 'Play next'
	String get playNext => 'Play next';

	/// en: 'Add to queue'
	String get addToQueue => 'Add to queue';

	/// en: 'Disc ${n}'
	String discNumber({required Object n}) => 'Disc ${n}';

	/// en: '(one) {${n} track} (other) {${n} tracks}'
	String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} track',
		other: '${n} tracks',
	);

	/// en: 'Now Playing'
	String get nowPlaying => 'Now Playing';

	/// en: 'Playing from ${title}'
	String playingFrom({required Object title}) => 'Playing from ${title}';

	/// en: 'Queue'
	String get queue => 'Queue';

	/// en: 'Clear queue'
	String get clearQueue => 'Clear queue';

	/// en: 'Lyrics'
	String get lyrics => 'Lyrics';

	/// en: 'No lyrics available'
	String get noLyrics => 'No lyrics available';

	/// en: 'Sleep timer'
	String get sleepTimer => 'Sleep timer';

	/// en: 'End of track'
	String get sleepTimerEndOfTrack => 'End of track';

	/// en: '${n} minutes'
	String sleepTimerMinutes({required Object n}) => '${n} minutes';

	/// en: 'Stop playback'
	String get stopPlayback => 'Stop playback';

	/// en: 'Previous track'
	String get previousTrack => 'Previous track';

	/// en: 'Next track'
	String get nextTrack => 'Next track';

	/// en: 'Repeat'
	String get repeat => 'Repeat';

	/// en: 'Repeat all'
	String get repeatAll => 'Repeat all';

	/// en: 'Repeat one'
	String get repeatOne => 'Repeat one';

	/// en: 'No server is available for an instant mix'
	String get instantMixNoServer => 'No server is available for an instant mix';

	/// en: 'Failed to load the instant mix'
	String get instantMixFailed => 'Failed to load the instant mix';

	/// en: 'The instant mix came back with no tracks'
	String get instantMixEmpty => 'The instant mix came back with no tracks';

	/// en: 'No audio URL is available for ${track}'
	String noAudioUrl({required Object track}) => 'No audio URL is available for ${track}';

	late final Translations$music$discography$en discography = Translations$music$discography$en.internal(_root);
}

// Path: watchTogether
class Translations$watchTogether$en {
	Translations$watchTogether$en.internal(this._root);

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

	/// en: 'Open Watch Together session controls'
	String get openSessionControls => 'Open Watch Together session controls';

	/// en: 'Copy session code'
	String get copySessionCode => 'Copy session code';

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

	/// en: 'Make host'
	String get makeHost => 'Make host';

	/// en: 'Transfer host?'
	String get makeHostQuestion => 'Transfer host?';

	/// en: '${name} will control playback and drive the session for everyone.'
	String makeHostConfirm({required Object name}) => '${name} will control playback and drive the session for everyone.';

	/// en: 'Transfer'
	String get transfer => 'Transfer';

	/// en: '${name} is now the host'
	String hostChangedTo({required Object name}) => '${name} is now the host';

	/// en: 'You are now the host'
	String get youAreNowHost => 'You are now the host';

	/// en: 'Couldn't make ${name} the host'
	String hostTransferFailed({required Object name}) => 'Couldn\'t make ${name} the host';

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

	/// en: 'Enter 5-character code'
	String get enterCodeHint => 'Enter 5-character code';

	/// en: 'Paste from clipboard'
	String get pasteFromClipboard => 'Paste from clipboard';

	/// en: 'Please enter a session code'
	String get pleaseEnterCode => 'Please enter a session code';

	/// en: 'Session code must be 5 characters'
	String get codeMustBe5Chars => 'Session code must be 5 characters';

	/// en: 'Enter the host's session code to join.'
	String get joinInstructions => 'Enter the host\'s session code to join.';

	/// en: 'Failed to create session'
	String get failedToCreate => 'Failed to create session';

	/// en: 'Failed to join session'
	String get failedToJoin => 'Failed to join session';

	/// en: 'Session code copied to clipboard'
	String get sessionCodeCopied => 'Session code copied to clipboard';

	/// en: 'Relay server unreachable. ISP blocking may prevent Watch Together.'
	String get relayUnreachable => 'Relay server unreachable. ISP blocking may prevent Watch Together.';

	/// en: 'Reconnecting to host...'
	String get reconnectingToHost => 'Reconnecting to host...';

	/// en: 'Current Playback'
	String get currentPlayback => 'Current Playback';

	/// en: 'Join Current Playback'
	String get joinCurrentPlayback => 'Join Current Playback';

	/// en: 'Jump back into what the host is currently watching'
	String get joinCurrentPlaybackDescription => 'Jump back into what the host is currently watching';

	/// en: 'Failed to open current playback'
	String get failedToOpenCurrentPlayback => 'Failed to open current playback';

	/// en: '${name} joined'
	String participantJoined({required Object name}) => '${name} joined';

	/// en: '${name} left'
	String participantLeft({required Object name}) => '${name} left';

	/// en: '${name} paused'
	String participantPaused({required Object name}) => '${name} paused';

	/// en: '${name} resumed'
	String participantResumed({required Object name}) => '${name} resumed';

	/// en: '${name} changed the playback position'
	String participantSeeked({required Object name}) => '${name} changed the playback position';

	/// en: '${name} set the speed to ${speed}'
	String participantChangedSpeed({required Object name, required Object speed}) => '${name} set the speed to ${speed}';

	/// en: '${name} is buffering'
	String participantBuffering({required Object name}) => '${name} is buffering';

	/// en: '${name} is on an older app version — sync unavailable'
	String participantNeedsUpdate({required Object name}) => '${name} is on an older app version — sync unavailable';

	/// en: 'Resuming without ${name}'
	String resumingWithout({required Object name}) => 'Resuming without ${name}';

	/// en: 'Waiting for others to load...'
	String get waitingForParticipants => 'Waiting for others to load...';

	/// en: 'Waiting for ${name}...'
	String waitingForName({required Object name}) => 'Waiting for ${name}...';

	/// en: 'Recent Rooms'
	String get recentRooms => 'Recent Rooms';

	/// en: 'Rename Room'
	String get renameRoom => 'Rename Room';

	/// en: 'Remove'
	String get removeRoom => 'Remove';

	/// en: 'Couldn't switch — server unavailable for sync'
	String get guestSwitchUnavailable => 'Couldn\'t switch — server unavailable for sync';

	/// en: 'Couldn't switch — content not found on this server'
	String get guestSwitchFailed => 'Couldn\'t switch — content not found on this server';

	/// en: 'User'
	String get defaultDisplayName => 'User';

	late final Translations$watchTogether$errors$en errors = Translations$watchTogether$errors$en.internal(_root);
}

// Path: downloads
class Translations$downloads$en {
	Translations$downloads$en.internal(this._root);

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

	/// en: 'Music'
	String get music => 'Music';

	/// en: '${count} tracks queued for download'
	String tracksQueued({required Object count}) => '${count} tracks queued for download';

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

	/// en: 'Download resumed'
	String get downloadResumed => 'Download resumed';

	/// en: 'Server error: file may exceed the remote bitrate limit'
	String get serverErrorBitrate => 'Server error: file may exceed the remote bitrate limit';

	/// en: 'Downloads stopped because device storage is full. Free some space, then retry.'
	String get storageFull => 'Downloads stopped because device storage is full. Free some space, then retry.';

	/// en: '${count} episodes queued for download'
	String episodesQueued({required Object count}) => '${count} episodes queued for download';

	/// en: 'Download deleted'
	String get downloadDeleted => 'Download deleted';

	/// en: 'Delete "${title}" from this device?'
	String deleteConfirm({required Object title}) => 'Delete "${title}" from this device?';

	/// en: 'Canceled Download'
	String get cancelledDownloadTitle => 'Canceled Download';

	/// en: 'This download was canceled. What would you like to do?'
	String get cancelledDownloadMessage => 'This download was canceled. What would you like to do?';

	/// en: 'All episodes already downloaded'
	String get allEpisodesAlreadyDownloaded => 'All episodes already downloaded';

	/// en: 'Resume download'
	String get resumeDownload => 'Resume download';

	/// en: 'Canceled download'
	String get cancelledDownload => 'Canceled download';

	/// en: '${file} (syncing ${status})'
	String syncingFile({required Object file, required Object status}) => '${file} (syncing ${status})';

	/// en: 'Downloaded ${file} - Click to complete'
	String downloadedFileClickToComplete({required Object file}) => 'Downloaded ${file} - Click to complete';

	/// en: 'Partially downloaded - Click to complete'
	String get partialDownloadClickToComplete => 'Partially downloaded - Click to complete';

	/// en: 'Deleting...'
	String get deleting => 'Deleting...';

	/// en: 'Deleting ${title}... (${current} of ${total})'
	String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Deleting ${title}... (${current} of ${total})';

	/// en: 'Queued'
	String get queuedTooltip => 'Queued';

	/// en: 'Queued ${files}'
	String queuedFilesTooltip({required Object files}) => 'Queued ${files}';

	/// en: 'Downloading...'
	String get downloadingTooltip => 'Downloading...';

	/// en: 'Downloading ${files}'
	String downloadingFilesTooltip({required Object files}) => 'Downloading ${files}';

	/// en: 'No downloads'
	String get noDownloadsTree => 'No downloads';

	/// en: 'Pause all'
	String get pauseAll => 'Pause all';

	/// en: 'Resume all'
	String get resumeAll => 'Resume all';

	/// en: 'Delete all'
	String get deleteAll => 'Delete all';

	/// en: 'Select Version'
	String get selectVersion => 'Select Version';

	/// en: 'All episodes'
	String get allEpisodes => 'All episodes';

	/// en: 'Unwatched only'
	String get unwatchedOnly => 'Unwatched only';

	/// en: 'Next ${count} unwatched'
	String nextNUnwatched({required Object count}) => 'Next ${count} unwatched';

	/// en: 'Custom amount...'
	String get customAmount => 'Custom amount...';

	/// en: 'Include Specials'
	String get includeSpecials => 'Include Specials';

	/// en: 'How many episodes?'
	String get howManyEpisodes => 'How many episodes?';

	/// en: 'Enter a valid episode count.'
	String get invalidEpisodeCount => 'Enter a valid episode count.';

	/// en: 'Keep synced'
	String get keepSynced => 'Keep synced';

	/// en: 'Download once'
	String get downloadOnce => 'Download once';

	/// en: 'Keep ${count} unwatched'
	String keepNUnwatched({required Object count}) => 'Keep ${count} unwatched';

	/// en: 'Edit sync rule'
	String get editSyncRule => 'Edit sync rule';

	/// en: 'Remove sync rule'
	String get removeSyncRule => 'Remove sync rule';

	/// en: 'Stop syncing "${title}"? Downloaded episodes will be kept.'
	String removeSyncRuleConfirm({required Object title}) => 'Stop syncing "${title}"? Downloaded episodes will be kept.';

	/// en: 'Stop syncing "${title}"?'
	String removeListSyncRuleConfirm({required Object title}) => 'Stop syncing "${title}"?';

	/// en: 'Also delete associated downloads'
	String get deleteSyncRuleDownloads => 'Also delete associated downloads';

	/// en: 'Downloads used by another sync rule or profile will be kept.'
	String get deleteSyncRuleDownloadsDescription => 'Downloads used by another sync rule or profile will be kept.';

	/// en: 'Sync rule created — keeping ${count} unwatched episodes'
	String syncRuleCreated({required Object count}) => 'Sync rule created — keeping ${count} unwatched episodes';

	/// en: 'Sync rule updated'
	String get syncRuleUpdated => 'Sync rule updated';

	/// en: 'Sync rule removed'
	String get syncRuleRemoved => 'Sync rule removed';

	/// en: 'Sync rule and associated downloads removed'
	String get syncRuleAndDownloadsRemoved => 'Sync rule and associated downloads removed';

	/// en: 'Sync rules are currently updating. Try again in a moment.'
	String get syncRuleCleanupBusy => 'Sync rules are currently updating. Try again in a moment.';

	/// en: 'Associated downloads could not be identified safely. Reconnect the server and try again, or remove the rule without deleting downloads.'
	String get syncRuleCleanupUnavailable => 'Associated downloads could not be identified safely. Reconnect the server and try again, or remove the rule without deleting downloads.';

	/// en: 'Synced ${count} new episodes for ${title}'
	String syncedNewEpisodes({required Object count, required Object title}) => 'Synced ${count} new episodes for ${title}';

	/// en: 'Sync rules'
	String get activeSyncRules => 'Sync rules';

	/// en: 'No sync rules'
	String get noSyncRules => 'No sync rules';

	/// en: 'Manage sync'
	String get manageSyncRule => 'Manage sync';

	/// en: 'Episode count'
	String get editEpisodeCount => 'Episode count';

	/// en: 'Sync filter'
	String get editSyncFilter => 'Sync filter';

	/// en: 'Syncing all items'
	String get syncAllItems => 'Syncing all items';

	/// en: 'Syncing unwatched items'
	String get syncUnwatchedItems => 'Syncing unwatched items';

	/// en: 'Server: ${server} • ${status}'
	String syncRuleServerContext({required Object server, required Object status}) => 'Server: ${server} • ${status}';

	/// en: 'Available'
	String get syncRuleAvailable => 'Available';

	/// en: 'Offline'
	String get syncRuleOffline => 'Offline';

	/// en: 'Sign in required'
	String get syncRuleSignInRequired => 'Sign in required';

	/// en: 'Not available for current profile'
	String get syncRuleNotAvailableForProfile => 'Not available for current profile';

	/// en: 'Unknown server'
	String get syncRuleUnknownServer => 'Unknown server';

	/// en: 'Sync rule created'
	String get syncRuleListCreated => 'Sync rule created';

	late final Translations$downloads$backgroundWarning$en backgroundWarning = Translations$downloads$backgroundWarning$en.internal(_root);

	/// en: 'Unknown Show'
	String get unknownShow => 'Unknown Show';

	/// en: 'Unknown Season'
	String get unknownSeason => 'Unknown Season';

	/// en: 'Unknown Album'
	String get unknownAlbum => 'Unknown Album';

	/// en: '${completed}/${total} completed'
	String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} completed';

	/// en: 'File not found (404)'
	String get errorFileNotFound => 'File not found (404)';

	/// en: 'Download failed'
	String get errorDownloadFailed => 'Download failed';

	/// en: 'Post-processing failed: ${error}'
	String errorPostProcessing({required Object error}) => 'Post-processing failed: ${error}';

	/// en: 'Downloading...'
	String get notificationDownloading => 'Downloading...';

	/// en: 'Download complete'
	String get notificationComplete => 'Download complete';

	/// en: 'Download paused'
	String get notificationPaused => 'Download paused';
}

// Path: shaders
class Translations$shaders$en {
	Translations$shaders$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Shaders'
	String get title => 'Shaders';

	/// en: 'No video enhancement'
	String get noShaderDescription => 'No video enhancement';

	/// en: 'NVIDIA image scaling for sharper video'
	String get nvscalerDescription => 'NVIDIA image scaling for sharper video';

	/// en: 'Neutral'
	String get artcnnVariantNeutral => 'Neutral';

	/// en: 'Denoise'
	String get artcnnVariantDenoise => 'Denoise';

	/// en: 'Denoise + Sharpen'
	String get artcnnVariantDenoiseSharpen => 'Denoise + Sharpen';

	/// en: 'Fast'
	String get qualityFast => 'Fast';

	/// en: 'High Quality'
	String get qualityHQ => 'High Quality';

	/// en: 'Mode'
	String get mode => 'Mode';

	/// en: 'Import Shader'
	String get importShader => 'Import Shader';

	/// en: 'Custom GLSL shader'
	String get customShaderDescription => 'Custom GLSL shader';

	/// en: 'Shader imported'
	String get shaderImported => 'Shader imported';

	/// en: 'Failed to import shader'
	String get shaderImportFailed => 'Failed to import shader';

	/// en: 'Delete Shader'
	String get deleteShader => 'Delete Shader';

	/// en: 'Delete "${name}"?'
	String deleteShaderConfirm({required Object name}) => 'Delete "${name}"?';
}

// Path: companionRemote
class Translations$companionRemote$en {
	Translations$companionRemote$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Companion Remote'
	String get title => 'Companion Remote';

	/// en: 'Connected to ${name}'
	String connectedTo({required Object name}) => 'Connected to ${name}';

	/// en: 'Unknown Device'
	String get unknownDevice => 'Unknown Device';

	late final Translations$companionRemote$session$en session = Translations$companionRemote$session$en.internal(_root);
	late final Translations$companionRemote$pairing$en pairing = Translations$companionRemote$pairing$en.internal(_root);
	late final Translations$companionRemote$remote$en remote = Translations$companionRemote$remote$en.internal(_root);
	late final Translations$companionRemote$errors$en errors = Translations$companionRemote$errors$en.internal(_root);

	/// en: 'The connection closed before authentication'
	String get closedBeforeAuth => 'The connection closed before authentication';
}

// Path: videoSettings
class Translations$videoSettings$en {
	Translations$videoSettings$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Playback Speed'
	String get playbackSpeed => 'Playback Speed';

	/// en: 'Normal'
	String get normalSpeed => 'Normal';

	/// en: 'Active (${duration})'
	String sleepTimerActive({required Object duration}) => 'Active (${duration})';

	/// en: 'Zoom'
	String get zoom => 'Zoom';

	/// en: 'Sleep Timer'
	String get sleepTimer => 'Sleep Timer';

	/// en: 'Audio Sync'
	String get audioSync => 'Audio Sync';

	/// en: 'Subtitle Sync'
	String get subtitleSync => 'Subtitle Sync';

	/// en: 'HDR'
	String get hdr => 'HDR';

	/// en: 'HDR isn't available here — this desktop compositor or video output can't carry it.'
	String get hdrUnsupported => 'HDR isn\'t available here — this desktop compositor or video output can\'t carry it.';

	/// en: 'HDR Tone Mapping'
	String get hdrToneMapping => 'HDR Tone Mapping';

	/// en: 'Compositor'
	String get hdrToneMappingCompositor => 'Compositor';

	/// en: 'Pass the source's HDR metadata through and let the desktop compositor map it.'
	String get hdrToneMappingCompositorDescription => 'Pass the source\'s HDR metadata through and let the desktop compositor map it.';

	/// en: 'Player'
	String get hdrToneMappingPlayer => 'Player';

	/// en: 'Map to the display's peak brightness in the player, then tell the compositor the result.'
	String get hdrToneMappingPlayerDescription => 'Map to the display\'s peak brightness in the player, then tell the compositor the result.';

	/// en: 'Couldn't change HDR tone mapping — the previous mode is still active.'
	String get hdrToneMappingFailed => 'Couldn\'t change HDR tone mapping — the previous mode is still active.';

	/// en: 'Audio Output'
	String get audioOutput => 'Audio Output';

	/// en: 'Performance Overlay'
	String get performanceOverlay => 'Performance Overlay';

	/// en: 'Dolby Atmos'
	String get audioOutputDolbyAtmos => 'Dolby Atmos';

	/// en: 'Dolby Audio'
	String get audioOutputDolbyAudio => 'Dolby Audio';

	/// en: 'Surround'
	String get audioOutputSurround => 'Surround';

	/// en: 'Spatial Audio'
	String get audioOutputSpatial => 'Spatial Audio';

	/// en: 'Stereo'
	String get audioOutputStereo => 'Stereo';

	/// en: 'Normalize Loudness'
	String get audioNormalization => 'Normalize Loudness';

	/// en: 'Downmix to Stereo'
	String get audioDownmix => 'Downmix to Stereo';
}

// Path: performanceOverlay
class Translations$performanceOverlay$en {
	Translations$performanceOverlay$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Color'
	String get color => 'Color';

	/// en: 'Performance'
	String get performance => 'Performance';

	/// en: 'Buffer'
	String get buffer => 'Buffer';

	/// en: 'App'
	String get app => 'App';

	/// en: 'Decoder'
	String get decoder => 'Decoder';

	/// en: 'Raw Decoder'
	String get rawDecoder => 'Raw Decoder';

	/// en: 'Tunneling'
	String get tunneling => 'Tunneling';

	/// en: 'Passthrough'
	String get passthrough => 'Passthrough';

	/// en: 'Aspect'
	String get aspect => 'Aspect';

	/// en: 'Rotation'
	String get rotation => 'Rotation';

	/// en: 'DV Source'
	String get dvSource => 'DV Source';

	/// en: 'DV Path'
	String get dvPath => 'DV Path';

	/// en: 'P7 Conv'
	String get p7Conversion => 'P7 Conv';

	/// en: 'Sample Rate'
	String get sampleRate => 'Sample Rate';

	/// en: 'Pixel Fmt'
	String get pixelFormat => 'Pixel Fmt';

	/// en: 'HW Fmt'
	String get hwFormat => 'HW Fmt';

	/// en: 'Matrix'
	String get matrix => 'Matrix';

	/// en: 'Primaries'
	String get primaries => 'Primaries';

	/// en: 'Transfer'
	String get transfer => 'Transfer';

	/// en: 'Render FPS'
	String get renderFps => 'Render FPS';

	/// en: 'Display FPS'
	String get displayFps => 'Display FPS';

	/// en: 'A/V Sync'
	String get avSync => 'A/V Sync';

	/// en: 'Dropped'
	String get dropped => 'Dropped';

	/// en: 'DV RPUs'
	String get dvRpus => 'DV RPUs';

	/// en: 'DV RPU Avg'
	String get dvRpuAverage => 'DV RPU Avg';

	/// en: 'DV Sample Avg'
	String get dvSampleAverage => 'DV Sample Avg';

	/// en: 'Max Luma'
	String get maxLuma => 'Max Luma';

	/// en: 'Min Luma'
	String get minLuma => 'Min Luma';

	/// en: 'MaxCLL'
	String get maxCll => 'MaxCLL';

	/// en: 'MaxFALL'
	String get maxFall => 'MaxFALL';

	/// en: 'Cache Used'
	String get cacheUsed => 'Cache Used';

	/// en: 'Cache Limit'
	String get cacheLimit => 'Cache Limit';

	/// en: 'Speed'
	String get speed => 'Speed';

	/// en: 'Player'
	String get player => 'Player';

	/// en: 'Memory'
	String get memory => 'Memory';

	/// en: 'UI FPS'
	String get uiFps => 'UI FPS';

	/// en: 'FPS'
	String get fps => 'FPS';

	/// en: 'Android HW'
	String get decoderAndroidHw => 'Android HW';

	/// en: 'NVIDIA HW'
	String get decoderNvidiaHw => 'NVIDIA HW';

	/// en: 'Qualcomm HW'
	String get decoderQualcommHw => 'Qualcomm HW';

	/// en: 'MediaTek HW'
	String get decoderMediatekHw => 'MediaTek HW';

	/// en: 'Exynos HW'
	String get decoderExynosHw => 'Exynos HW';

	/// en: 'Software'
	String get decoderSoftware => 'Software';

	/// en: 'Hardware'
	String get decoderHardware => 'Hardware';

	/// en: 'Active'
	String get tunnelingActive => 'Active';

	/// en: '${converted} (${failures} failed)'
	String dvRpuFailed({required Object converted, required Object failures}) => '${converted} (${failures} failed)';
}

// Path: externalPlayer
class Translations$externalPlayer$en {
	Translations$externalPlayer$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'External Player'
	String get title => 'External Player';

	/// en: 'Use External Player'
	String get useExternalPlayer => 'Use External Player';

	/// en: 'Open videos in another app'
	String get useExternalPlayerDescription => 'Open videos in another app';

	/// en: 'Select Player'
	String get selectPlayer => 'Select Player';

	/// en: 'Custom Players'
	String get customPlayers => 'Custom Players';

	/// en: 'System Default'
	String get systemDefault => 'System Default';

	/// en: 'Add Custom Player'
	String get addCustomPlayer => 'Add Custom Player';

	/// en: 'Player Name'
	String get playerName => 'Player Name';

	/// en: 'My Player'
	String get playerNameHint => 'My Player';

	/// en: 'Command'
	String get playerCommand => 'Command';

	/// en: 'Package Name'
	String get playerPackage => 'Package Name';

	/// en: 'URL Scheme'
	String get playerUrlScheme => 'URL Scheme';

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
class Translations$metadataEdit$en {
	Translations$metadataEdit$en.internal(this._root);

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

	/// en: 'Logo'
	String get logo => 'Logo';

	/// en: 'Square Art'
	String get squareArt => 'Square Art';

	/// en: 'Select Poster'
	String get selectPoster => 'Select Poster';

	/// en: 'Select Background'
	String get selectBackground => 'Select Background';

	/// en: 'Select Logo'
	String get selectLogo => 'Select Logo';

	/// en: 'Select Square Art'
	String get selectSquareArt => 'Select Square Art';

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

	/// en: 'Artwork option ${index}'
	String artworkOption({required Object index}) => 'Artwork option ${index}';

	/// en: 'Artwork option ${index}, selected'
	String selectedArtworkOption({required Object index}) => 'Artwork option ${index}, selected';

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

	/// en: 'Tags'
	String get tags => 'Tags';

	/// en: 'Add tag'
	String get addTag => 'Add tag';

	/// en: 'Genre'
	String get genre => 'Genre';

	/// en: 'Director'
	String get director => 'Director';

	/// en: 'Writer'
	String get writer => 'Writer';

	/// en: 'Producer'
	String get producer => 'Producer';

	/// en: 'Country'
	String get country => 'Country';

	/// en: 'Collection'
	String get collection => 'Collection';

	/// en: 'Label'
	String get label => 'Label';
}

// Path: matchScreen
class Translations$matchScreen$en {
	Translations$matchScreen$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Match...'
	String get match => 'Match...';

	/// en: 'Fix Match...'
	String get fixMatch => 'Fix Match...';

	/// en: 'Unmatch'
	String get unmatch => 'Unmatch';

	/// en: 'Clear this match? Plex treats it as unmatched until rematched.'
	String get unmatchConfirm => 'Clear this match? Plex treats it as unmatched until rematched.';

	/// en: 'Item unmatched'
	String get unmatchSuccess => 'Item unmatched';

	/// en: 'Failed to unmatch item'
	String get unmatchFailed => 'Failed to unmatch item';

	/// en: 'Match applied'
	String get matchApplied => 'Match applied';

	/// en: 'Failed to apply match'
	String get matchFailed => 'Failed to apply match';

	/// en: 'Title'
	String get titleHint => 'Title';

	/// en: 'Year'
	String get yearHint => 'Year';

	/// en: 'Search'
	String get search => 'Search';

	/// en: 'No matches found'
	String get noMatchesFound => 'No matches found';
}

// Path: serverTasks
class Translations$serverTasks$en {
	Translations$serverTasks$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Server Tasks'
	String get title => 'Server Tasks';

	/// en: 'Failed to load tasks'
	String get failedToLoad => 'Failed to load tasks';

	/// en: 'No tasks running'
	String get noTasks => 'No tasks running';
}

// Path: trakt
class Translations$trakt$en {
	Translations$trakt$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Trakt'
	String get title => 'Trakt';

	/// en: 'Connected'
	String get connected => 'Connected';

	/// en: 'Connected as @${username}'
	String connectedAs({required Object username}) => 'Connected as @${username}';

	/// en: 'Disconnect Trakt account?'
	String get disconnectConfirm => 'Disconnect Trakt account?';

	/// en: 'Plezy will stop sending events to Trakt. You can reconnect any time.'
	String get disconnectConfirmBody => 'Plezy will stop sending events to Trakt. You can reconnect any time.';

	/// en: 'Real-time scrobbling'
	String get scrobble => 'Real-time scrobbling';

	/// en: 'Send play, pause, and stop events to Trakt during playback.'
	String get scrobbleDescription => 'Send play, pause, and stop events to Trakt during playback.';

	/// en: 'Sync watched status'
	String get watchedSync => 'Sync watched status';

	/// en: 'When you mark items as watched in Plezy, they are also marked as watched on Trakt.'
	String get watchedSyncDescription => 'When you mark items as watched in Plezy, they are also marked as watched on Trakt.';
}

// Path: seerr
class Translations$seerr$en {
	Translations$seerr$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Seerr'
	String get title => 'Seerr';

	/// en: 'Connect Seerr'
	String get connectTitle => 'Connect Seerr';

	/// en: 'Server URL'
	String get serverUrl => 'Server URL';

	/// en: 'The address of your Seerr instance'
	String get serverUrlHelper => 'The address of your Seerr instance';

	/// en: 'Continue'
	String get checkServer => 'Continue';

	/// en: 'Sign in with Jellyfin'
	String get signInWithJellyfin => 'Sign in with Jellyfin';

	/// en: 'Sign in with Emby'
	String get signInWithEmby => 'Sign in with Emby';

	/// en: 'Use a local account'
	String get signInWithLocal => 'Use a local account';

	/// en: 'Email'
	String get email => 'Email';

	/// en: 'This Seerr instance offers no sign-in method Plezy supports.'
	String get noSignInMethods => 'This Seerr instance offers no sign-in method Plezy supports.';

	/// en: 'Instance'
	String get instance => 'Instance';

	/// en: 'Disconnect Seerr?'
	String get disconnectConfirm => 'Disconnect Seerr?';

	/// en: 'Plezy will forget this Seerr instance. Reconnect any time.'
	String get disconnectConfirmBody => 'Plezy will forget this Seerr instance. Reconnect any time.';

	/// en: 'Request'
	String get request => 'Request';

	/// en: 'Request in 4K'
	String get request4k => 'Request in 4K';

	/// en: 'Seasons'
	String get seasons => 'Seasons';

	/// en: 'All seasons'
	String get allSeasons => 'All seasons';

	/// en: 'Advanced'
	String get advancedOptions => 'Advanced';

	/// en: 'Destination server'
	String get destinationServer => 'Destination server';

	/// en: 'Quality profile'
	String get qualityProfile => 'Quality profile';

	/// en: 'Root folder'
	String get rootFolder => 'Root folder';

	/// en: 'Language profile'
	String get languageProfile => 'Language profile';

	/// en: 'Tags'
	String get tags => 'Tags';

	/// en: 'No tags'
	String get noTags => 'No tags';

	/// en: '${name} (Default)'
	String defaultOption({required Object name}) => '${name} (Default)';

	/// en: 'This series is an anime.'
	String get animeNote => 'This series is an anime.';

	/// en: 'Request submitted'
	String get requestSubmitted => 'Request submitted';

	/// en: 'Request failed: ${error}'
	String requestFailed({required Object error}) => 'Request failed: ${error}';

	/// en: 'Couldn't load request options'
	String get requestsLoadFailed => 'Couldn\'t load request options';

	/// en: 'Everything is already available or requested.'
	String get nothingToRequest => 'Everything is already available or requested.';

	/// en: 'Available'
	String get statusAvailable => 'Available';

	/// en: 'Partially available'
	String get statusPartiallyAvailable => 'Partially available';

	/// en: 'Requested'
	String get statusRequested => 'Requested';

	/// en: 'Processing'
	String get statusProcessing => 'Processing';

	/// en: 'Blocklisted'
	String get statusBlocklisted => 'Blocklisted';

	/// en: 'Could not reach ${url}: ${error}'
	String couldNotReach({required Object url, required Object error}) => 'Could not reach ${url}: ${error}';

	/// en: 'No Seerr instance at ${url} (HTTP ${status})'
	String noInstanceAtUrl({required Object url, required Object status}) => 'No Seerr instance at ${url} (HTTP ${status})';

	/// en: 'An authenticating reverse proxy (SSO or HTTP auth) answered instead of Seerr. Plezy cannot sign in through it: let Seerr's /api/v1 path bypass the proxy for this app, or use an address that reaches Seerr directly.'
	String get behindAuthProxy => 'An authenticating reverse proxy (SSO or HTTP auth) answered instead of Seerr. Plezy cannot sign in through it: let Seerr\'s /api/v1 path bypass the proxy for this app, or use an address that reaches Seerr directly.';

	/// en: 'Enter a server address like https://seerr.example.com'
	String get invalidUrl => 'Enter a server address like https://seerr.example.com';

	/// en: 'This Seerr instance does not support Quick Connect. It needs Seerr 3.4 or newer.'
	String get quickConnectUnsupported => 'This Seerr instance does not support Quick Connect. It needs Seerr 3.4 or newer.';

	/// en: 'This Seerr instance has not completed first-run setup'
	String get notInitialized => 'This Seerr instance has not completed first-run setup';

	/// en: 'No Plex token is available to sign in again'
	String get noPlexTokenForReauth => 'No Plex token is available to sign in again';

	/// en: 'No stored credentials are available to sign in again'
	String get noStoredCredentials => 'No stored credentials are available to sign in again';

	/// en: 'Sign-in was rejected'
	String get signInRejected => 'Sign-in was rejected';

	/// en: 'Seerr did not issue a session cookie'
	String get noSessionCookie => 'Seerr did not issue a session cookie';

	/// en: 'Seerr rejected the new session cookie'
	String get freshCookieRejected => 'Seerr rejected the new session cookie';

	/// en: 'Seerr did not return user information'
	String get noUserInformation => 'Seerr did not return user information';

	/// en: 'The session was rejected after signing in again'
	String get sessionRejectedAfterReauth => 'The session was rejected after signing in again';

	/// en: 'Seerr denied this action: your account no longer has the required permission'
	String get permissionDenied => 'Seerr denied this action: your account no longer has the required permission';

	/// en: 'You no longer have permission to request this'
	String get permissionRevoked => 'You no longer have permission to request this';
}

// Path: services
class Translations$services$en {
	Translations$services$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Services'
	String get title => 'Services';

	/// en: 'Sync watch progress and request new titles.'
	String get hubSubtitle => 'Sync watch progress and request new titles.';

	/// en: 'Integrations'
	String get integrations => 'Integrations';

	/// en: 'Not connected'
	String get notConnected => 'Not connected';

	/// en: 'Connected as @${username}'
	String connectedAs({required Object username}) => 'Connected as @${username}';

	/// en: 'Track progress automatically'
	String get scrobble => 'Track progress automatically';

	/// en: 'Update your list when you finish an episode or movie.'
	String get scrobbleDescription => 'Update your list when you finish an episode or movie.';

	/// en: 'Disconnect ${service}?'
	String disconnectConfirm({required Object service}) => 'Disconnect ${service}?';

	/// en: 'Plezy will stop updating ${service}. Reconnect any time.'
	String disconnectConfirmBody({required Object service}) => 'Plezy will stop updating ${service}. Reconnect any time.';

	/// en: 'Couldn't connect to ${service}. Try again.'
	String connectFailed({required Object service}) => 'Couldn\'t connect to ${service}. Try again.';

	late final Translations$services$names$en names = Translations$services$names$en.internal(_root);
	late final Translations$services$deviceCode$en deviceCode = Translations$services$deviceCode$en.internal(_root);
	late final Translations$services$oauthProxy$en oauthProxy = Translations$services$oauthProxy$en.internal(_root);
	late final Translations$services$pendingAuth$en pendingAuth = Translations$services$pendingAuth$en.internal(_root);
	late final Translations$services$libraryFilter$en libraryFilter = Translations$services$libraryFilter$en.internal(_root);
}

// Path: addServer
class Translations$addServer$en {
	Translations$addServer$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Add ${product} server'
	String addMediaBrowserTitle({required Object product}) => 'Add ${product} server';

	/// en: 'Server URLs'
	String get serverUrls => 'Server URLs';

	/// en: 'Multiple URLs allowed, separated by commas.'
	String get serverUrlsHelper => 'Multiple URLs allowed, separated by commas.';

	/// en: 'Find server'
	String get findServer => 'Find server';

	/// en: 'Looking for local ${product} servers...'
	String searchingLocalMediaBrowserServers({required Object product}) => 'Looking for local ${product} servers...';

	/// en: 'Local ${product} servers'
	String localMediaBrowserServers({required Object product}) => 'Local ${product} servers';

	/// en: 'Username'
	String get username => 'Username';

	/// en: 'Password'
	String get password => 'Password';

	/// en: 'Sign in'
	String get signIn => 'Sign in';

	/// en: 'Change'
	String get change => 'Change';

	/// en: 'Required'
	String get required => 'Required';

	/// en: 'Could not reach the server: ${error}'
	String couldNotReachServer({required Object error}) => 'Could not reach the server: ${error}';

	/// en: 'Sign-in failed: ${error}'
	String signInFailed({required Object error}) => 'Sign-in failed: ${error}';

	/// en: 'Quick Connect failed: ${error}'
	String quickConnectFailed({required Object error}) => 'Quick Connect failed: ${error}';

	/// en: 'Sign in with Plex'
	String get addPlexTitle => 'Sign in with Plex';

	/// en: 'PIN expired before sign-in. Please try again.'
	String get pinExpired => 'PIN expired before sign-in. Please try again.';

	/// en: 'Failed to register account: ${error}'
	String failedToRegisterAccount({required Object error}) => 'Failed to register account: ${error}';

	/// en: 'Enter your ${product} server URL'
	String enterMediaBrowserUrlError({required Object product}) => 'Enter your ${product} server URL';

	/// en: 'Add connection'
	String get addConnectionTitle => 'Add connection';

	/// en: 'Add to ${name}'
	String addConnectionTitleScoped({required Object name}) => 'Add to ${name}';

	/// en: 'Sign in with Plex'
	String get signInWithPlexCard => 'Sign in with Plex';

	/// en: 'Authorize this device. Shared servers are added.'
	String get signInWithPlexCardSubtitle => 'Authorize this device. Shared servers are added.';

	/// en: 'Authorize a Plex account. Home users become profiles.'
	String get signInWithPlexCardSubtitleScoped => 'Authorize a Plex account. Home users become profiles.';

	/// en: 'Connect to ${product}'
	String connectToMediaBrowserCard({required Object product}) => 'Connect to ${product}';

	/// en: 'Enter your server URL, username, and password.'
	String get connectToMediaBrowserCardSubtitle => 'Enter your server URL, username, and password.';

	/// en: 'Sign in to your ${product} server. Binds to ${name}.'
	String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => 'Sign in to your ${product} server. Binds to ${name}.';

	/// en: 'Borrow from another profile'
	String get borrowFromAnotherProfile => 'Borrow from another profile';

	/// en: 'Reuse another profile's connection. PIN-protected profiles require a PIN.'
	String get borrowFromAnotherProfileSubtitle => 'Reuse another profile\'s connection. PIN-protected profiles require a PIN.';

	/// en: 'Invalid username or password'
	String get invalidCredentials => 'Invalid username or password';

	/// en: 'The authentication response was not valid JSON'
	String get authResponseNotJson => 'The authentication response was not valid JSON';

	/// en: 'The sign-in response from the server was incomplete'
	String get authResponseIncomplete => 'The sign-in response from the server was incomplete';

	/// en: 'Quick Connect was rejected by the server'
	String get quickConnectRejected => 'Quick Connect was rejected by the server';

	/// en: 'The Quick Connect response was not valid JSON'
	String get quickConnectNotJson => 'The Quick Connect response was not valid JSON';

	/// en: 'The Quick Connect response is missing a code or secret'
	String get quickConnectMissingFields => 'The Quick Connect response is missing a code or secret';

	/// en: 'Quick Connect polling was rejected by the server'
	String get quickConnectPollRejected => 'Quick Connect polling was rejected by the server';

	/// en: 'The server did not respond in time'
	String get serverTimedOut => 'The server did not respond in time';

	/// en: 'The server response was not valid JSON'
	String get responseNotJson => 'The server response was not valid JSON';

	/// en: 'The response is missing an ID or server name — is this a ${product} server?'
	String responseMissingIdentity({required Object product}) => 'The response is missing an ID or server name — is this a ${product} server?';

	/// en: 'Could not reach the server: ${error}'
	String probeFailed({required Object error}) => 'Could not reach the server: ${error}';

	/// en: 'Enter at least one ${product} server URL'
	String enterAtLeastOneUrl({required Object product}) => 'Enter at least one ${product} server URL';

	/// en: 'No reachable ${product} server was found'
	String noReachableServer({required Object product}) => 'No reachable ${product} server was found';

	/// en: 'These URLs point to different ${product} servers'
	String urlsPointToDifferentServers({required Object product}) => 'These URLs point to different ${product} servers';

	/// en: 'This URL does not match the ${product} server'
	String urlDoesNotMatchServer({required Object product}) => 'This URL does not match the ${product} server';

	/// en: 'The server redirected to an unsupported URL'
	String get redirectUnsupported => 'The server redirected to an unsupported URL';

	/// en: 'The server redirected to a different host. Enter the final ${product} URL directly.'
	String redirectDifferentHost({required Object product}) => 'The server redirected to a different host. Enter the final ${product} URL directly.';

	/// en: 'The server redirected from HTTPS to an insecure URL'
	String get redirectInsecure => 'The server redirected from HTTPS to an insecure URL';

	/// en: 'The server redirected to an unsupported URL. Enter the final ${product} URL directly.'
	String redirectUnsupportedEnterFinal({required Object product}) => 'The server redirected to an unsupported URL. Enter the final ${product} URL directly.';
}

// Path: common.ratingSource
class Translations$common$ratingSource$en {
	Translations$common$ratingSource$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Critics'
	String get critic => 'Critics';

	/// en: 'Audience'
	String get audience => 'Audience';

	/// en: 'IMDb'
	String get imdb => 'IMDb';

	/// en: 'TMDB'
	String get tmdb => 'TMDB';

	/// en: 'Rotten Tomatoes'
	String get rottenTomatoes => 'Rotten Tomatoes';

	/// en: 'Simkl'
	String get simkl => 'Simkl';

	/// en: 'MyAnimeList'
	String get mal => 'MyAnimeList';

	/// en: 'AniList'
	String get anilist => 'AniList';

	/// en: 'Trakt'
	String get trakt => 'Trakt';

	/// en: 'Rotten Tomatoes critics'
	String get rottenTomatoesCritic => 'Rotten Tomatoes critics';

	/// en: 'Rotten Tomatoes audience'
	String get rottenTomatoesAudience => 'Rotten Tomatoes audience';
}

// Path: common.mediaKind
class Translations$common$mediaKind$en {
	Translations$common$mediaKind$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Movie'
	String get movie => 'Movie';

	/// en: 'Show'
	String get show => 'Show';

	/// en: 'Season'
	String get season => 'Season';

	/// en: 'Episode'
	String get episode => 'Episode';

	/// en: 'Artist'
	String get artist => 'Artist';

	/// en: 'Album'
	String get album => 'Album';

	/// en: 'Track'
	String get track => 'Track';

	/// en: 'Collection'
	String get collection => 'Collection';

	/// en: 'Playlist'
	String get playlist => 'Playlist';

	/// en: 'Clip'
	String get clip => 'Clip';

	/// en: 'Photo'
	String get photo => 'Photo';

	/// en: 'Folder'
	String get folder => 'Folder';
}

// Path: hotkeys.actions
class Translations$hotkeys$actions$en {
	Translations$hotkeys$actions$en.internal(this._root);

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

	/// en: 'Next Episode'
	String get episodeNext => 'Next Episode';

	/// en: 'Previous Episode'
	String get episodePrevious => 'Previous Episode';

	/// en: 'Increase Speed'
	String get speedIncrease => 'Increase Speed';

	/// en: 'Decrease Speed'
	String get speedDecrease => 'Decrease Speed';

	/// en: 'Reset Speed'
	String get speedReset => 'Reset Speed';

	/// en: 'Zoom In'
	String get zoomIn => 'Zoom In';

	/// en: 'Zoom Out'
	String get zoomOut => 'Zoom Out';

	/// en: 'Reset Zoom'
	String get zoomReset => 'Reset Zoom';

	/// en: 'Seek to Next Subtitle'
	String get subSeekNext => 'Seek to Next Subtitle';

	/// en: 'Seek to Previous Subtitle'
	String get subSeekPrev => 'Seek to Previous Subtitle';

	/// en: 'Toggle Shaders'
	String get shaderToggle => 'Toggle Shaders';

	/// en: 'Skip Intro/Credits'
	String get skipMarker => 'Skip Intro/Credits';

	/// en: 'Take Screenshot'
	String get screenshot => 'Take Screenshot';
}

// Path: videoControls.pipErrors
class Translations$videoControls$pipErrors$en {
	Translations$videoControls$pipErrors$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Requires Android 8.0 or newer'
	String get androidVersion => 'Requires Android 8.0 or newer';

	/// en: 'Requires iOS 15.0 or newer'
	String get iosVersion => 'Requires iOS 15.0 or newer';

	/// en: 'Picture-in-picture is disabled. Enable it in system settings.'
	String get permissionDisabled => 'Picture-in-picture is disabled. Enable it in system settings.';

	/// en: 'Device doesn't support picture-in-picture mode'
	String get notSupported => 'Device doesn\'t support picture-in-picture mode';

	/// en: 'Failed to switch video output for picture-in-picture'
	String get voSwitchFailed => 'Failed to switch video output for picture-in-picture';

	/// en: 'Picture-in-picture failed to start'
	String get failed => 'Picture-in-picture failed to start';

	/// en: 'Picture-in-picture could not be prepared'
	String get prepareFailed => 'Picture-in-picture could not be prepared';

	/// en: 'An error occurred: ${error}'
	String unknown({required Object error}) => 'An error occurred: ${error}';
}

// Path: accountPreferences.groups
class Translations$accountPreferences$groups$en {
	Translations$accountPreferences$groups$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Audio & subtitles'
	String get audioAndSubtitles => 'Audio & subtitles';

	/// en: 'Library'
	String get libraryDisplay => 'Library';

	/// en: 'Personal media'
	String get personalMedia => 'Personal media';
}

// Path: accountPreferences.subtitleModes
class Translations$accountPreferences$subtitleModes$en {
	Translations$accountPreferences$subtitleModes$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Manually selected'
	String get none => 'Manually selected';

	/// en: 'Never turn subtitles on by itself.'
	String get noneDescription => 'Never turn subtitles on by itself.';

	/// en: 'Follow the track flags'
	String get defaultMode => 'Follow the track flags';

	/// en: 'Use the default and forced flags stored on each subtitle track.'
	String get defaultModeDescription => 'Use the default and forced flags stored on each subtitle track.';

	/// en: 'Always enabled'
	String get always => 'Always enabled';

	/// en: 'Turn on a subtitle track in the preferred language whenever one exists.'
	String get alwaysDescription => 'Turn on a subtitle track in the preferred language whenever one exists.';

	/// en: 'Only forced subtitles'
	String get onlyForced => 'Only forced subtitles';

	/// en: 'Load only the tracks marked as forced.'
	String get onlyForcedDescription => 'Load only the tracks marked as forced.';

	/// en: 'Shown with foreign audio'
	String get smart => 'Shown with foreign audio';

	/// en: 'Turn subtitles on only when the audio is in another language.'
	String get smartDescription => 'Turn subtitles on only when the audio is in another language.';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class Translations$accountPreferences$subtitleAccessibilityOptions$en {
	Translations$accountPreferences$subtitleAccessibilityOptions$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Prefer non-SDH subtitles'
	String get preferNonSdh => 'Prefer non-SDH subtitles';

	/// en: 'Prefer SDH subtitles'
	String get preferSdh => 'Prefer SDH subtitles';

	/// en: 'Only SDH subtitles'
	String get onlySdh => 'Only SDH subtitles';

	/// en: 'Only non-SDH subtitles'
	String get onlyNonSdh => 'Only non-SDH subtitles';
}

// Path: accountPreferences.forcedSubtitleOptions
class Translations$accountPreferences$forcedSubtitleOptions$en {
	Translations$accountPreferences$forcedSubtitleOptions$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Prefer non-forced subtitles'
	String get preferNonForced => 'Prefer non-forced subtitles';

	/// en: 'Prefer forced subtitles'
	String get preferForced => 'Prefer forced subtitles';

	/// en: 'Only forced subtitles'
	String get onlyForced => 'Only forced subtitles';

	/// en: 'Only non-forced subtitles'
	String get onlyNonForced => 'Only non-forced subtitles';
}

// Path: accountPreferences.watchedIndicatorOptions
class Translations$accountPreferences$watchedIndicatorOptions$en {
	Translations$accountPreferences$watchedIndicatorOptions$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Never'
	String get none => 'Never';

	/// en: 'Movies and TV shows'
	String get moviesAndShows => 'Movies and TV shows';

	/// en: 'Movies only'
	String get movies => 'Movies only';

	/// en: 'TV shows only'
	String get shows => 'TV shows only';
}

// Path: accountPreferences.mediaReviewsOptions
class Translations$accountPreferences$mediaReviewsOptions$en {
	Translations$accountPreferences$mediaReviewsOptions$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Users and critics'
	String get usersAndCritics => 'Users and critics';

	/// en: 'Users only'
	String get usersOnly => 'Users only';

	/// en: 'Critics only'
	String get criticsOnly => 'Critics only';

	/// en: 'Hidden'
	String get nobody => 'Hidden';
}

// Path: libraries.tabs
class Translations$libraries$tabs$en {
	Translations$libraries$tabs$en.internal(this._root);

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
class Translations$libraries$groupings$en {
	Translations$libraries$groupings$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Grouping'
	String get title => 'Grouping';

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

	/// en: 'Artists'
	String get artists => 'Artists';

	/// en: 'Albums'
	String get albums => 'Albums';

	/// en: 'Tracks'
	String get tracks => 'Tracks';

	/// en: 'Folders'
	String get folders => 'Folders';
}

// Path: libraries.filterCategories
class Translations$libraries$filterCategories$en {
	Translations$libraries$filterCategories$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Genre'
	String get genre => 'Genre';

	/// en: 'Year'
	String get year => 'Year';

	/// en: 'Content Rating'
	String get contentRating => 'Content Rating';

	/// en: 'Tag'
	String get tag => 'Tag';

	/// en: 'Unwatched'
	String get unwatched => 'Unwatched';

	/// en: 'Unplayed'
	String get unplayed => 'Unplayed';

	/// en: 'Favorites'
	String get favorites => 'Favorites';
}

// Path: libraries.sortLabels
class Translations$libraries$sortLabels$en {
	Translations$libraries$sortLabels$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Title'
	String get title => 'Title';

	/// en: 'Date Added'
	String get dateAdded => 'Date Added';

	/// en: 'Release Date'
	String get releaseDate => 'Release Date';

	/// en: 'Rating'
	String get rating => 'Rating';

	/// en: 'Community Rating'
	String get communityRating => 'Community Rating';

	/// en: 'Critic Rating'
	String get criticRating => 'Critic Rating';

	/// en: 'User Rating'
	String get userRating => 'User Rating';

	/// en: 'Date Played'
	String get datePlayed => 'Date Played';

	/// en: 'Play Count'
	String get playCount => 'Play Count';

	/// en: 'Production Year'
	String get productionYear => 'Production Year';

	/// en: 'Runtime'
	String get runtime => 'Runtime';

	/// en: 'Official Rating'
	String get officialRating => 'Official Rating';

	/// en: 'Premiere Date'
	String get premiereDate => 'Premiere Date';

	/// en: 'Start Date'
	String get startDate => 'Start Date';

	/// en: 'Air Time'
	String get airTime => 'Air Time';

	/// en: 'Studio'
	String get studio => 'Studio';

	/// en: 'Random'
	String get random => 'Random';

	/// en: 'Date Shared'
	String get dateShared => 'Date Shared';

	/// en: 'Latest Episode Air Date'
	String get latestEpisodeAirDate => 'Latest Episode Air Date';

	/// en: 'Last Episode Date Added'
	String get lastEpisodeDateAdded => 'Last Episode Date Added';
}

// Path: explore.rows
class Translations$explore$rows$en {
	Translations$explore$rows$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Watchlist'
	String get watchlist => 'Watchlist';

	/// en: 'Recommended Movies'
	String get recommendedMovies => 'Recommended Movies';

	/// en: 'Recommended Shows'
	String get recommendedShows => 'Recommended Shows';

	/// en: 'Trending Movies'
	String get trendingMovies => 'Trending Movies';

	/// en: 'Trending Shows'
	String get trendingShows => 'Trending Shows';

	/// en: 'Popular Movies'
	String get popularMovies => 'Popular Movies';

	/// en: 'Popular Shows'
	String get popularShows => 'Popular Shows';

	/// en: 'Trending Anime'
	String get trendingAnime => 'Trending Anime';

	/// en: 'Suggested Anime'
	String get suggestedAnime => 'Suggested Anime';

	/// en: 'Top Airing Anime'
	String get airingAnime => 'Top Airing Anime';

	/// en: 'Most Popular Anime'
	String get popularAnime => 'Most Popular Anime';

	/// en: 'Trending'
	String get trending => 'Trending';

	/// en: 'Upcoming Movies'
	String get upcomingMovies => 'Upcoming Movies';

	/// en: 'Upcoming Shows'
	String get upcomingShows => 'Upcoming Shows';
}

// Path: explore.status
class Translations$explore$status$en {
	Translations$explore$status$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Airing'
	String get airing => 'Airing';

	/// en: 'Ended'
	String get ended => 'Ended';

	/// en: 'Canceled'
	String get canceled => 'Canceled';

	/// en: 'Upcoming'
	String get upcoming => 'Upcoming';
}

// Path: explore.badge
class Translations$explore$badge$en {
	Translations$explore$badge$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: '#${n} popular'
	String rankPopular({required Object n}) => '#${n} popular';

	/// en: '#${n} airing'
	String rankAiring({required Object n}) => '#${n} airing';

	/// en: '#${n} rated'
	String rankRated({required Object n}) => '#${n} rated';

	/// en: '#${n} trending'
	String rankTrending({required Object n}) => '#${n} trending';

	/// en: '#${n} in ${season}'
	String rankSeasonal({required Object n, required Object season}) => '#${n} in ${season}';

	/// en: '${n} watching'
	String watchingNow({required Object n}) => '${n} watching';

	/// en: 'Available'
	String get available => 'Available';

	/// en: 'Partly available'
	String get partiallyAvailable => 'Partly available';

	/// en: '4K available'
	String get availableIn4k => '4K available';

	/// en: 'Requested'
	String get requested => 'Requested';

	/// en: 'Pending approval'
	String get pendingApproval => 'Pending approval';

	/// en: 'Processing'
	String get processing => 'Processing';

	/// en: 'Declined'
	String get declined => 'Declined';

	/// en: 'Request failed'
	String get requestFailed => 'Request failed';

	/// en: '4K requested'
	String get requested4k => '4K requested';

	/// en: '${available}/${total} seasons'
	String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} seasons';

	/// en: 'Ep ${episode} in ${duration}'
	String nextEpisodeIn({required Object episode, required Object duration}) => 'Ep ${episode} in ${duration}';

	/// en: 'Next in ${duration}'
	String nextAiringIn({required Object duration}) => 'Next in ${duration}';

	/// en: '${n} eps'
	String episodesShort({required Object n}) => '${n} eps';

	/// en: '${n} min/ep'
	String minutesPerEpisode({required Object n}) => '${n} min/ep';

	/// en: '18+'
	String get adult => '18+';
}

// Path: explore.stats
class Translations$explore$stats$en {
	Translations$explore$stats$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: '${n} listed'
	String listed({required Object n}) => '${n} listed';

	/// en: '${n} watched today'
	String viewersDay({required Object n}) => '${n} watched today';

	/// en: '${n} watched this week'
	String viewersWeek({required Object n}) => '${n} watched this week';

	/// en: '${n} watched this month'
	String viewersMonth({required Object n}) => '${n} watched this month';

	/// en: '${n} watched this year'
	String viewersYear({required Object n}) => '${n} watched this year';

	/// en: '${n} viewers'
	String viewersAllTime({required Object n}) => '${n} viewers';

	/// en: '${n} planning to watch'
	String planning({required Object n}) => '${n} planning to watch';

	/// en: '${n} favorites'
	String favorited({required Object n}) => '${n} favorites';

	/// en: '${percent} dropped it'
	String dropRate({required Object percent}) => '${percent} dropped it';

	/// en: '(one) {${n} comment} (other) {${n} comments}'
	String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} comment',
		other: '${n} comments',
	);

	/// en: '${n} votes'
	String votes({required Object n}) => '${n} votes';

	/// en: '${n} watching it'
	String watching({required Object n}) => '${n} watching it';

	/// en: '${n} completed'
	String completed({required Object n}) => '${n} completed';

	/// en: '${n} on hold'
	String onHold({required Object n}) => '${n} on hold';

	/// en: '${n} dropped'
	String dropped({required Object n}) => '${n} dropped';
}

// Path: explore.season
class Translations$explore$season$en {
	Translations$explore$season$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Winter'
	String get winter => 'Winter';

	/// en: 'Spring'
	String get spring => 'Spring';

	/// en: 'Summer'
	String get summer => 'Summer';

	/// en: 'Fall'
	String get fall => 'Fall';

	/// en: '${season} ${year}'
	String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class Translations$explore$format$en {
	Translations$explore$format$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'TV'
	String get tv => 'TV';

	/// en: 'TV Short'
	String get tvShort => 'TV Short';

	/// en: 'Movie'
	String get movie => 'Movie';

	/// en: 'Special'
	String get special => 'Special';

	/// en: 'OVA'
	String get ova => 'OVA';

	/// en: 'ONA'
	String get ona => 'ONA';

	/// en: 'Music'
	String get music => 'Music';

	/// en: 'Other'
	String get other => 'Other';
}

// Path: explore.sourceMaterial
class Translations$explore$sourceMaterial$en {
	Translations$explore$sourceMaterial$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Original'
	String get original => 'Original';

	/// en: 'Manga'
	String get manga => 'Manga';

	/// en: 'Light novel'
	String get lightNovel => 'Light novel';

	/// en: 'Novel'
	String get novel => 'Novel';

	/// en: 'Visual novel'
	String get visualNovel => 'Visual novel';

	/// en: 'Game'
	String get game => 'Game';

	/// en: 'Web comic'
	String get webComic => 'Web comic';

	/// en: 'Music'
	String get musicRelease => 'Music';

	/// en: 'Other'
	String get otherMedia => 'Other';
}

// Path: explore.creditRole
class Translations$explore$creditRole$en {
	Translations$explore$creditRole$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Director'
	String get director => 'Director';

	/// en: 'Writer'
	String get writer => 'Writer';

	/// en: 'Producer'
	String get producer => 'Producer';

	/// en: 'Creator'
	String get creator => 'Creator';

	/// en: 'Composer'
	String get composer => 'Composer';
}

// Path: explore.relation
class Translations$explore$relation$en {
	Translations$explore$relation$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Prequel'
	String get prequel => 'Prequel';

	/// en: 'Sequel'
	String get sequel => 'Sequel';

	/// en: 'Side story'
	String get sideStory => 'Side story';

	/// en: 'Spin-off'
	String get spinOff => 'Spin-off';

	/// en: 'Alternative version'
	String get alternativeVersion => 'Alternative version';

	/// en: 'Summary'
	String get summary => 'Summary';

	/// en: 'Parent story'
	String get parentStory => 'Parent story';

	/// en: 'Adaptation'
	String get adaptation => 'Adaptation';

	/// en: 'Related'
	String get other => 'Related';
}

// Path: explore.detail
class Translations$explore$detail$en {
	Translations$explore$detail$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Original title'
	String get originalTitle => 'Original title';

	/// en: 'Also known as'
	String get alsoKnownAs => 'Also known as';

	/// en: 'Studios'
	String get studios => 'Studios';

	/// en: 'Country'
	String get country => 'Country';

	/// en: 'Language'
	String get language => 'Language';

	/// en: 'Released'
	String get released => 'Released';

	/// en: 'On disc'
	String get physicalRelease => 'On disc';

	/// en: 'Ended'
	String get ended => 'Ended';

	/// en: 'Added ${date}'
	String addedOn({required Object date}) => 'Added ${date}';

	/// en: 'Your rating'
	String get yourRating => 'Your rating';

	/// en: 'Budget'
	String get budget => 'Budget';

	/// en: 'Box office'
	String get revenue => 'Box office';

	/// en: 'Age guidance'
	String get contentAdvisory => 'Age guidance';

	/// en: 'Tags'
	String get tags => 'Tags';

	/// en: 'Show spoiler tags'
	String get revealSpoilerTags => 'Show spoiler tags';

	/// en: 'Links'
	String get links => 'Links';

	/// en: 'Watch on'
	String get watchOn => 'Watch on';

	/// en: 'Watch trailer'
	String get watchTrailer => 'Watch trailer';

	/// en: 'Open on ${site}'
	String openOn({required Object site}) => 'Open on ${site}';

	/// en: 'Crew'
	String get crew => 'Crew';

	/// en: 'Ratings'
	String get ratings => 'Ratings';

	/// en: 'Schedule'
	String get schedule => 'Schedule';

	/// en: '(one) {Recommended by ${n} user} (other) {Recommended by ${n} users}'
	String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'Recommended by ${n} user',
		other: 'Recommended by ${n} users',
	);

	/// en: 'Recommended by ${who}'
	String recommendedBy({required Object who}) => 'Recommended by ${who}';

	/// en: 'Favorited by ${who}'
	String favoritedBy({required Object who}) => 'Favorited by ${who}';

	/// en: '${n} not aired yet'
	String unairedEpisodes({required Object n}) => '${n} not aired yet';

	/// en: 'Recommended by ${percent} of viewers'
	String recommendedByPercent({required Object percent}) => 'Recommended by ${percent} of viewers';

	/// en: 'Related titles'
	String get relatedTitles => 'Related titles';

	/// en: 'Background'
	String get background => 'Background';
}

// Path: liveTv.recordSettings
class Translations$liveTv$recordSettings$en {
	Translations$liveTv$recordSettings$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Start early (seconds)'
	String get startEarly => 'Start early (seconds)';

	/// en: 'End late (seconds)'
	String get endLate => 'End late (seconds)';

	/// en: 'Only new episodes'
	String get newOnly => 'Only new episodes';

	/// en: 'Record on any channel'
	String get anyChannel => 'Record on any channel';

	/// en: 'Record at any time'
	String get anyTime => 'Record at any time';

	/// en: 'Skip episodes already in the library'
	String get skipInLibrary => 'Skip episodes already in the library';

	/// en: 'Episodes to keep'
	String get keepUpTo => 'Episodes to keep';

	/// en: '0 keeps every episode'
	String get keepUpToHint => '0 keeps every episode';
}

// Path: music.discography
class Translations$music$discography$en {
	Translations$music$discography$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Singles & EPs'
	String get singlesAndEps => 'Singles & EPs';

	/// en: 'Live'
	String get live => 'Live';

	/// en: 'Compilations'
	String get compilations => 'Compilations';
}

// Path: watchTogether.errors
class Translations$watchTogether$errors$en {
	Translations$watchTogether$errors$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'The relay did not respond in time'
	String get timedOut => 'The relay did not respond in time';

	/// en: 'The connection closed before the session was ready'
	String get connectionLost => 'The connection closed before the session was ready';

	/// en: 'The relay sent an unexpected response'
	String get invalidRelayResponse => 'The relay sent an unexpected response';

	/// en: 'The host ended the session'
	String get sessionEnded => 'The host ended the session';

	/// en: 'Unable to resume this session. Join or create a room to continue.'
	String get sessionUnavailable => 'Unable to resume this session. Join or create a room to continue.';
}

// Path: downloads.backgroundWarning
class Translations$downloads$backgroundWarning$en {
	Translations$downloads$backgroundWarning$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Downloads will stop when you leave the app'
	String get bannerBlocked => 'Downloads will stop when you leave the app';

	/// en: 'Background downloads may be limited'
	String get bannerDegraded => 'Background downloads may be limited';

	/// en: 'Details'
	String get bannerAction => 'Details';

	/// en: 'Background downloads are blocked'
	String get sheetTitle => 'Background downloads are blocked';

	/// en: 'Background downloads may be limited'
	String get sheetTitleDegraded => 'Background downloads may be limited';

	/// en: 'Android is preventing Plezy from downloading reliably in the background.'
	String get sheetIntro => 'Android is preventing Plezy from downloading reliably in the background.';

	/// en: 'Your device is limiting when Plezy can download in the background.'
	String get sheetIntroDegraded => 'Your device is limiting when Plezy can download in the background.';

	/// en: 'Plezy's background usage is restricted. Set its battery or background usage to "Unrestricted".'
	String get reasonBackgroundRestricted => 'Plezy\'s background usage is restricted. Set its battery or background usage to "Unrestricted".';

	/// en: 'Android has put Plezy in a restricted standby state. Set its battery usage to "Unrestricted".'
	String get reasonStandbyRestricted => 'Android has put Plezy in a restricted standby state. Set its battery usage to "Unrestricted".';

	/// en: 'Download notifications are turned off, so progress and controls may be unavailable.'
	String get reasonDownloadChannelBlocked => 'Download notifications are turned off, so progress and controls may be unavailable.';

	/// en: 'Notifications are turned off. On Android 13 or newer, they are required for long background downloads.'
	String get reasonNotificationsDisabled => 'Notifications are turned off. On Android 13 or newer, they are required for long background downloads.';

	/// en: 'Data Saver is on, which blocks background downloads on mobile data. Downloads should still run on Wi-Fi.'
	String get reasonDataSaver => 'Data Saver is on, which blocks background downloads on mobile data. Downloads should still run on Wi-Fi.';

	/// en: 'Downloads repeatedly stopped while Plezy was in the background. Check Plezy's battery or background usage settings.'
	String get reasonOemUnknown => 'Downloads repeatedly stopped while Plezy was in the background. Check Plezy\'s battery or background usage settings.';

	/// en: 'Open settings'
	String get openSettings => 'Open settings';

	/// en: 'Device-specific help'
	String get stillNotWorking => 'Device-specific help';

	/// en: 'See steps for your device, or send a log from Settings › View Logs if the issue continues.'
	String get stillNotWorkingDescription => 'See steps for your device, or send a log from Settings › View Logs if the issue continues.';

	/// en: 'Downloads may not finish'
	String get dialogTitle => 'Downloads may not finish';

	/// en: 'Download anyway'
	String get dialogDownloadAnyway => 'Download anyway';

	/// en: 'Fix this first'
	String get dialogFixFirst => 'Fix this first';

	/// en: 'Background downloads'
	String get statusTile => 'Background downloads';

	/// en: 'Allowed to run in the background'
	String get statusOk => 'Allowed to run in the background';

	/// en: 'Blocked by system settings'
	String get statusBlocked => 'Blocked by system settings';

	/// en: 'Limited by system settings'
	String get statusDegraded => 'Limited by system settings';

	/// en: 'Not checked yet'
	String get statusUnknown => 'Not checked yet';

	/// en: 'Couldn't open system settings on this device'
	String get settingsUnavailable => 'Couldn\'t open system settings on this device';

	/// en: 'Couldn't open dontkillmyapp.com on this device'
	String get linkUnavailable => 'Couldn\'t open dontkillmyapp.com on this device';
}

// Path: companionRemote.session
class Translations$companionRemote$session$en {
	Translations$companionRemote$session$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Starting remote server...'
	String get startingServer => 'Starting remote server...';

	/// en: 'Host Address'
	String get hostAddress => 'Host Address';

	/// en: 'Connected'
	String get connected => 'Connected';

	/// en: 'Remote server active'
	String get serverRunning => 'Remote server active';

	/// en: 'Remote server stopped'
	String get serverStopped => 'Remote server stopped';

	/// en: 'Mobile devices on your network can connect to this app'
	String get serverRunningDescription => 'Mobile devices on your network can connect to this app';

	/// en: 'Start the server to allow mobile devices to connect'
	String get serverStoppedDescription => 'Start the server to allow mobile devices to connect';

	/// en: 'Use your mobile device to control this app'
	String get usePhoneToControl => 'Use your mobile device to control this app';

	/// en: 'Start Server'
	String get startServer => 'Start Server';

	/// en: 'Stop Server'
	String get stopServer => 'Stop Server';

	/// en: 'Minimize'
	String get minimize => 'Minimize';

	/// en: 'Manual connection address:'
	String get manualAddressHint => 'Manual connection address:';
}

// Path: companionRemote.pairing
class Translations$companionRemote$pairing$en {
	Translations$companionRemote$pairing$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Plezy devices with the same Plex account appear here'
	String get discoveryDescription => 'Plezy devices with the same Plex account appear here';

	/// en: '192.168.1.100:48632'
	String get hostAddressHint => '192.168.1.100:48632';

	/// en: 'Connecting...'
	String get connecting => 'Connecting...';

	/// en: 'Looking for devices...'
	String get searchingForDevices => 'Looking for devices...';

	/// en: 'No devices found on your network'
	String get noDevicesFound => 'No devices found on your network';

	/// en: 'Open Plezy on desktop and use the same Wi-Fi'
	String get noDevicesHint => 'Open Plezy on desktop and use the same Wi-Fi';

	/// en: 'Available Devices'
	String get availableDevices => 'Available Devices';

	/// en: 'Manual Connection'
	String get manualConnection => 'Manual Connection';

	/// en: 'Couldn't start secure connection. Sign in to Plex first.'
	String get cryptoInitFailed => 'Couldn\'t start secure connection. Sign in to Plex first.';

	/// en: 'Please enter host address'
	String get validationHostRequired => 'Please enter host address';

	/// en: 'Format must be IP:port (e.g., 192.168.1.100:48632)'
	String get validationHostFormat => 'Format must be IP:port (e.g., 192.168.1.100:48632)';

	/// en: 'Connection timed out. Use the same network on both devices.'
	String get connectionTimedOut => 'Connection timed out. Use the same network on both devices.';

	/// en: 'Device not found. Make sure Plezy is running on the host.'
	String get sessionNotFound => 'Device not found. Make sure Plezy is running on the host.';

	/// en: 'Authentication failed. Both devices need the same Plex account.'
	String get authFailed => 'Authentication failed. Both devices need the same Plex account.';

	/// en: 'Failed to connect: ${error}'
	String failedToConnect({required Object error}) => 'Failed to connect: ${error}';
}

// Path: companionRemote.remote
class Translations$companionRemote$remote$en {
	Translations$companionRemote$remote$en.internal(this._root);

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

// Path: companionRemote.errors
class Translations$companionRemote$errors$en {
	Translations$companionRemote$errors$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'No network interface found'
	String get noNetworkInterface => 'No network interface found';

	/// en: 'Authentication failed'
	String get authenticationFailed => 'Authentication failed';

	/// en: 'Failed to start remote server: ${error}'
	String serverStartFailed({required Object error}) => 'Failed to start remote server: ${error}';

	/// en: 'Failed to send remote command: ${error}'
	String commandFailed({required Object error}) => 'Failed to send remote command: ${error}';

	/// en: 'Timed out joining session'
	String get joinTimedOut => 'Timed out joining session';

	/// en: 'Failed to connect to any address'
	String get failedToConnectAnyAddress => 'Failed to connect to any address';

	/// en: 'Connection lost after ${attempts} attempts'
	String connectionLostAfterAttempts({required Object attempts}) => 'Connection lost after ${attempts} attempts';

	/// en: 'Connection lost'
	String get connectionLost => 'Connection lost';
}

// Path: services.names
class Translations$services$names$en {
	Translations$services$names$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'MyAnimeList'
	String get mal => 'MyAnimeList';

	/// en: 'AniList'
	String get anilist => 'AniList';

	/// en: 'Simkl'
	String get simkl => 'Simkl';

	/// en: 'Seerr'
	String get seerr => 'Seerr';

	/// en: 'MDBList'
	String get mdblist => 'MDBList';
}

// Path: services.deviceCode
class Translations$services$deviceCode$en {
	Translations$services$deviceCode$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Activate Plezy on ${service}'
	String title({required Object service}) => 'Activate Plezy on ${service}';

	/// en: 'Scan the QR code, or visit the address below and enter this code:'
	String get instructions => 'Scan the QR code, or visit the address below and enter this code:';

	/// en: 'Open ${service} to activate'
	String openToActivate({required Object service}) => 'Open ${service} to activate';

	/// en: 'Copy activation code'
	String get copyCode => 'Copy activation code';

	/// en: 'Waiting for authorization…'
	String get waitingForAuthorization => 'Waiting for authorization…';

	/// en: 'Code copied'
	String get codeCopied => 'Code copied';
}

// Path: services.oauthProxy
class Translations$services$oauthProxy$en {
	Translations$services$oauthProxy$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Sign in to ${service}'
	String title({required Object service}) => 'Sign in to ${service}';

	/// en: 'Scan this QR code or open the URL on any device.'
	String get body => 'Scan this QR code or open the URL on any device.';

	/// en: 'Open ${service} to sign in'
	String openToSignIn({required Object service}) => 'Open ${service} to sign in';
}

// Path: services.pendingAuth
class Translations$services$pendingAuth$en {
	Translations$services$pendingAuth$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Copy sign-in URL'
	String get copyUrl => 'Copy sign-in URL';

	/// en: 'URL copied'
	String get urlCopied => 'URL copied';
}

// Path: services.libraryFilter
class Translations$services$libraryFilter$en {
	Translations$services$libraryFilter$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Library filter'
	String get title => 'Library filter';

	/// en: 'Syncing all libraries'
	String get subtitleAllSyncing => 'Syncing all libraries';

	/// en: 'Nothing syncing'
	String get subtitleNoneSyncing => 'Nothing syncing';

	/// en: '${count} blocked'
	String subtitleBlocked({required Object count}) => '${count} blocked';

	/// en: '${count} allowed'
	String subtitleAllowed({required Object count}) => '${count} allowed';

	/// en: 'Filter mode'
	String get mode => 'Filter mode';

	/// en: 'Blacklist'
	String get modeBlacklist => 'Blacklist';

	/// en: 'Whitelist'
	String get modeWhitelist => 'Whitelist';

	/// en: 'Sync every library except the ones checked below.'
	String get modeHintBlacklist => 'Sync every library except the ones checked below.';

	/// en: 'Sync only the libraries checked below.'
	String get modeHintWhitelist => 'Sync only the libraries checked below.';

	/// en: 'Libraries'
	String get libraries => 'Libraries';

	/// en: 'No libraries available'
	String get noLibraries => 'No libraries available';
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
			'auth.authenticationTimeout' => 'Authentication timed out. Please try again.',
			'auth.scanQRToSignIn' => 'Scan this QR code to sign in',
			'auth.waitingForAuth' => 'Waiting for authentication...\nSign in from your browser.',
			'auth.useBrowser' => 'Use browser',
			'auth.or' => 'or',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'Connect to ${product}',
			'auth.quickConnect' => 'Quick Connect',
			'auth.useQuickConnect' => 'Use Quick Connect',
			'auth.quickConnectInstructions' => 'Open Quick Connect in Jellyfin and enter this code.',
			'auth.quickConnectWaiting' => 'Waiting for approval…',
			'auth.quickConnectCancel' => 'Cancel',
			'auth.quickConnectExpired' => 'Quick Connect expired. Try again.',
			'auth.localDataRecoveryRequired' => 'Plezy could not safely recover local sign-in and pending playback data. Please sign in again.',
			'auth.pinCheckRejected' => 'The Plex PIN check was rejected',
			'common.cancel' => 'Cancel',
			'common.save' => 'Save',
			'common.close' => 'Close',
			'common.clear' => 'Clear',
			'common.reset' => 'Reset',
			'common.later' => 'Later',
			'common.submit' => 'Submit',
			'common.confirm' => 'Confirm',
			'common.retry' => 'Retry',
			'common.logout' => 'Log out',
			'common.unknown' => 'Unknown',
			'common.refresh' => 'Refresh',
			'common.yes' => 'Yes',
			'common.no' => 'No',
			'common.delete' => 'Delete',
			'common.edit' => 'Edit',
			'common.shuffle' => 'Shuffle',
			'common.addTo' => 'Add to...',
			'common.createNew' => 'Create new',
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
			'common.off' => 'Off',
			'common.options' => 'Options',
			'common.seasonNumber' => ({required Object number}) => 'Season ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'Episode ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'Chapter ${number}',
			'common.reconnect' => 'Reconnect',
			'common.viewAll' => 'View All',
			'common.checkingNetwork' => 'Checking network...',
			'common.loadingServers' => 'Loading servers...',
			'common.connectingToServers' => 'Connecting to servers...',
			'common.startingOfflineMode' => 'Starting offline mode...',
			'common.loading' => 'Loading...',
			'common.fullscreen' => 'Fullscreen',
			'common.exitFullscreen' => 'Exit fullscreen',
			'common.pressBackAgainToExit' => 'Press back again to exit',
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
			'common.notAvailable' => 'N/A',
			'common.url' => 'URL',
			'common.letterKeys' => 'ABC',
			'common.mediaKind.movie' => 'Movie',
			'common.mediaKind.show' => 'Show',
			'common.mediaKind.season' => 'Season',
			'common.mediaKind.episode' => 'Episode',
			'common.mediaKind.artist' => 'Artist',
			'common.mediaKind.album' => 'Album',
			'common.mediaKind.track' => 'Track',
			'common.mediaKind.collection' => 'Collection',
			'common.mediaKind.playlist' => 'Playlist',
			'common.mediaKind.clip' => 'Clip',
			'common.mediaKind.photo' => 'Photo',
			'common.mediaKind.folder' => 'Folder',
			'screens.licenses' => 'Licenses',
			'screens.switchProfile' => 'Switch Profile',
			'screens.subtitleStyling' => 'Subtitle Styling',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Logs',
			'update.available' => 'Update Available',
			'update.versionAvailable' => ({required Object version}) => 'Version ${version} is available',
			'update.currentVersion' => ({required Object version}) => 'Current: ${version}',
			'update.skipVersion' => 'Skip This Version',
			'update.viewRelease' => 'View Release',
			'update.latestVersion' => 'You are on the latest version',
			'update.checkFailed' => 'Failed to check for updates',
			'settings.title' => 'Settings',
			'settings.supportDeveloper' => 'Support Plezy',
			'settings.supportDeveloperDescription' => 'Donate via Liberapay to fund development',
			'settings.language' => 'Language',
			'settings.theme' => 'Theme',
			'settings.appearance' => 'Appearance',
			'settings.videoPlayback' => 'Video Playback',
			'settings.videoPlaybackDescription' => 'Configure playback behavior',
			'settings.advanced' => 'Advanced',
			'settings.episodePosterMode' => 'Episode Poster Style',
			'settings.seriesPoster' => 'Series Poster',
			'settings.seasonPoster' => 'Season Poster',
			'settings.episodeThumbnail' => 'Thumbnail',
			'settings.showHeroSectionDescription' => 'Display featured content carousel on home screen',
			'settings.secondsLabel' => 'Seconds',
			'settings.minutesLabel' => 'Minutes',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Enter duration (${min}-${max})',
			'settings.systemTheme' => 'System',
			'settings.lightTheme' => 'Light',
			'settings.darkTheme' => 'Dark',
			'settings.oledTheme' => 'OLED',
			'settings.libraryDensity' => 'Library Density',
			'settings.displayScale' => 'Display Scale',
			'settings.compact' => 'Compact',
			'settings.comfortable' => 'Comfortable',
			'settings.gridSpacing' => 'Grid Spacing',
			'settings.gridSpacingTight' => 'Tight',
			'settings.gridSpacingNormal' => 'Normal',
			'settings.gridSpacingSpacious' => 'Spacious',
			'settings.tvCornerSpotlightBackdrop' => 'Corner Spotlight Backdrop',
			'settings.tvCornerSpotlightBackdropDescription' => 'Show spotlight artwork in the top-right corner instead of filling the screen',
			'settings.viewMode' => 'View Mode',
			'settings.gridView' => 'Grid',
			'settings.listView' => 'List',
			'settings.showHeroSection' => 'Show Hero Section',
			'settings.continueWatchingAction' => 'Continue Watching Action',
			'settings.continueWatchingPlay' => 'Play',
			'settings.continueWatchingDetails' => 'Open Details',
			'settings.episodeAction' => 'Episode Action',
			'settings.episodePlay' => 'Play',
			'settings.episodeDetails' => 'Open Details',
			'settings.useGlobalHubs' => 'Use Home Layout',
			'settings.useGlobalHubsDescription' => 'Show unified home hubs. Otherwise use library recommendations.',
			'settings.showServerNameOnHubs' => 'Show Server Name on Hubs',
			'settings.showServerNameOnHubsDescription' => 'Always show server names in hub titles.',
			'settings.groupLibrariesByServer' => 'Group Libraries by Server',
			'settings.groupLibrariesByServerDescription' => 'Group sidebar libraries under each media server.',
			'settings.alwaysKeepSidebarOpen' => 'Always Keep Sidebar Open',
			'settings.alwaysKeepSidebarOpenDescription' => 'Sidebar stays expanded and content area adjusts to fit',
			'settings.showUnwatchedCount' => 'Show Unwatched Count',
			'settings.showUnwatchedCountDescription' => 'Display unwatched episode count on shows and seasons',
			'settings.showWatchedIndicators' => 'Show Watched Indicators',
			'settings.showWatchedIndicatorsDescription' => 'Display a checkmark on watched movies, shows, and episodes',
			'settings.showEpisodeNumberOnCards' => 'Show Episode Number on Cards',
			'settings.showEpisodeNumberOnCardsDescription' => 'Show season and episode number on episode cards',
			'settings.showSeasonPostersOnTabs' => 'Show Season Posters on Tabs',
			'settings.showSeasonPostersOnTabsDescription' => 'Show each season\'s poster above its tab',
			'settings.tvFullCardLayout' => 'Full TV Cards',
			'settings.tvFullCardLayoutDescription' => 'Use image-only TV cards with actor names overlaid',
			'settings.focusGlow' => 'Focus Glow',
			'settings.focusGlowDescription' => 'Draw a soft glow around the focused card',
			'settings.visualEffects' => 'Visual Effects',
			'settings.visualEffectsAuto' => 'Auto',
			'settings.visualEffectsAutoDescription' => 'Reduce effects automatically on low-power devices',
			'settings.visualEffectsFull' => 'Full',
			'settings.visualEffectsReduced' => 'Reduced',
			'settings.visualEffectsReducedDescription' => 'Fewer animations and lower-resolution artwork',
			'settings.hideSpoilers' => 'Hide Spoilers for Unwatched Episodes',
			'settings.hideSpoilersDescription' => 'Blur thumbnails and descriptions for unwatched episodes',
			'settings.playerBackend' => 'Player Backend',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Hardware Decoding',
			'settings.hardwareDecodingDescription' => 'Use hardware acceleration when available',
			'settings.playbackBuffer' => 'Playback Buffer',
			'settings.playbackBufferAuto' => 'Auto (Recommended)',
			'settings.playbackBufferLarge' => 'Large',
			'settings.playbackBufferExtraLarge' => 'Extra Large',
			'settings.playbackBufferDescription' => 'Buffer more against unstable connections. Also limited by Buffer Size.',
			'settings.defaultQualityTitle' => 'Default Quality',
			'settings.cellularQualityTitle' => 'Default Quality on Cellular',
			'settings.cellularQualitySameAsDefault' => 'Same as Default Quality',
			'settings.directPlayCoveredQuality' => 'Play Smaller Videos at Original Quality',
			'settings.directPlayCoveredQualityDescription' => 'Direct play videos already within the quality limit instead of transcoding them',
			'settings.musicQualityTitle' => 'Music Quality',
			'settings.subtitleStyling' => 'Subtitle Styling',
			'settings.subtitleStylingDescription' => 'Customize subtitle appearance',
			'settings.smallSkipDuration' => 'Small Skip Duration',
			'settings.largeSkipDuration' => 'Large Skip Duration',
			'settings.rewindOnResume' => 'Rewind on Resume',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} seconds',
			'settings.defaultSleepTimer' => 'Default Sleep Timer',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} minutes',
			'settings.rememberTrackSelections' => 'Remember track selections per show/movie',
			'settings.rememberTrackSelectionsDescription' => 'Remember audio and subtitle choices per title',
			'settings.followServerTrackSelections' => 'Use server\'s per-episode track selections',
			'settings.followServerTrackSelectionsDescription' => 'On episode change, apply the audio and subtitles selected on the server instead of carrying over the current choice',
			'settings.resumeMusicOnLaunch' => 'Remember music session',
			'settings.resumeMusicOnLaunchDescription' => 'Reopen the last song paused where it left off when the app starts',
			'settings.showChapterMarkersOnTimeline' => 'Show chapter markers on seek bar',
			'settings.showChapterMarkersOnTimelineDescription' => 'Segment the seek bar at chapter boundaries',
			'settings.specialsOrdering' => 'Specials in episode order',
			'settings.specialsOrderingDescription' => 'Where specials play in a show\'s watch order',
			'settings.specialsOrderingServer' => 'Follow server order',
			'settings.specialsOrderingAirDate' => 'Interleave by air date',
			'settings.specialsOrderingLast' => 'After regular seasons',
			'settings.clickVideoTogglesPlayback' => 'Click on video to toggle play/pause',
			'settings.clickVideoTogglesPlaybackDescription' => 'Click video to play/pause instead of showing controls.',
			'settings.videoPlayerControls' => 'Video Player Controls',
			'settings.keyboardShortcuts' => 'Keyboard Shortcuts',
			'settings.keyboardShortcutsDescription' => 'Customize keyboard shortcuts',
			'settings.videoPlayerNavigation' => 'Video Player Navigation',
			'settings.videoPlayerNavigationDescription' => 'Use arrow keys to navigate video player controls',
			'settings.watchTogetherRelay' => 'Watch Together Relay',
			'settings.watchTogetherRelayDescription' => 'Set a custom relay. Everyone must use the same server.',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.watchTogetherRelayInvalid' => 'Enter a valid HTTP or HTTPS relay base URL.',
			'settings.crashReporting' => 'Crash Reporting',
			'settings.crashReportingDescription' => 'Send crash reports to help improve the app',
			'settings.debugLogging' => 'Debug Logging',
			'settings.debugLoggingDescription' => 'Enable detailed logging for troubleshooting',
			'settings.viewLogs' => 'View Logs',
			'settings.viewLogsDescription' => 'View application logs',
			'settings.clearImageCache' => 'Clear Image Cache',
			'settings.clearImageCacheDescription' => 'Clear cached artwork and thumbnails. Images may load slower until downloaded again.',
			'settings.clearImageCacheSuccess' => 'Image cache cleared successfully',
			'settings.resetSettings' => 'Reset Settings',
			'settings.resetSettingsDescription' => 'Restore default settings. This can\'t be undone.',
			'settings.resetSettingsSuccess' => 'Settings reset successfully',
			'settings.backup' => 'Backup',
			'settings.exportSettings' => 'Export Settings',
			'settings.exportSettingsDescription' => 'Save your preferences to a file',
			'settings.exportSettingsSuccess' => 'Settings exported',
			'settings.importSettings' => 'Import Settings',
			'settings.importSettingsDescription' => 'Restore preferences from a file',
			'settings.importSettingsConfirm' => 'This will replace your current settings. Continue?',
			'settings.importSettingsSuccess' => 'Settings imported',
			'settings.importSettingsInvalidFile' => 'This file isn\'t a valid Plezy settings export',
			'settings.importSettingsNoUser' => 'Sign in before importing settings',
			'settings.shortcutsReset' => 'Shortcuts reset to defaults',
			'settings.about' => 'About',
			'settings.aboutDescription' => 'App information and licenses',
			'settings.updates' => 'Updates',
			'settings.updateAvailable' => 'Update Available',
			'settings.checkForUpdates' => 'Check for Updates',
			'settings.autoCheckUpdatesOnStartup' => 'Automatically check for updates on startup',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Notify when an update is available at launch',
			'settings.validationErrorEnterNumber' => 'Please enter a valid number',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Duration must be between ${min} and ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Shortcut already assigned to ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Shortcut updated for ${action}',
			'settings.saveFailed' => 'Could not save changes. Try again.',
			'settings.autoPlayAndSkip' => 'Auto-Play & Skip',
			'settings.autoPlayNextEpisode' => 'Auto-Play Next Episode',
			'settings.autoPlayNextEpisodeDescription' => 'Start the next episode automatically when one ends',
			'settings.playNextCountdown' => 'Play Next Countdown',
			'settings.playNextCountdownImmediate' => 'Play immediately',
			'settings.skipIntroMode' => 'Skip Intro',
			'settings.skipIntroModeOffDescription' => 'Play intros normally without a skip button',
			'settings.skipIntroModeButtonDescription' => 'Show a skip button when an intro starts',
			'settings.skipIntroModeAutoDescription' => 'Skip intros automatically after the delay below',
			'settings.skipCreditsMode' => 'Skip Credits',
			'settings.skipCreditsModeOffDescription' => 'Play credits normally without a skip button',
			'settings.skipCreditsModeButtonDescription' => 'Show a skip button when credits start',
			'settings.skipCreditsModeAutoDescription' => 'Skip credits automatically and play the next episode',
			'settings.skipMarkerModeOff' => 'Off',
			'settings.skipMarkerModeButton' => 'Show button',
			'settings.skipMarkerModeAuto' => 'Automatic',
			'settings.forceSkipMarkerFallback' => 'Force Fallback Markers',
			'settings.forceSkipMarkerFallbackDescription' => 'Use chapter title patterns even when Plex has markers',
			'settings.autoSkipDelay' => 'Auto Skip Delay',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Wait ${seconds} seconds before auto-skipping',
			'settings.introPattern' => 'Intro Marker Pattern',
			'settings.introPatternDescription' => 'Regex pattern to match intro markers in chapter titles',
			'settings.creditsPattern' => 'Credits Marker Pattern',
			'settings.creditsPatternDescription' => 'Regex pattern to match credits markers in chapter titles',
			'settings.invalidRegex' => 'Invalid regular expression',
			'settings.regex' => 'Regular expression',
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
			'settings.downloadLocationPickerUnavailable' => 'Folder selection is not available on this device',
			'settings.downloadOnWifiOnly' => 'Download on Wi-Fi only',
			'settings.downloadOnWifiOnlyDescription' => 'Prevent downloads when on cellular data',
			'settings.autoRemoveWatchedDownloads' => 'Auto-remove watched downloads',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Delete watched downloads automatically',
			'settings.cellularDownloadBlocked' => 'Downloads are blocked on cellular. Use Wi-Fi or change the setting.',
			'settings.maxVolume' => 'Maximum Volume',
			'settings.maxVolumeDescription' => 'Allow volume boost above 100% for quiet media',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Show what you\'re watching on Discord',
			'settings.services' => 'Services',
			'settings.servicesDescription' => 'Connect Trakt, MyAnimeList, Seerr, and more',
			'settings.manageLibrariesDescription' => 'Reorder and hide libraries',
			'settings.companionRemoteServer' => 'Companion Remote Server',
			'settings.companionRemoteServerDescription' => 'Allow mobile devices on your network to control this app',
			'settings.autoPip' => 'Auto Picture-in-Picture',
			'settings.autoPipDescription' => 'Automatically enter picture-in-picture when you leave the app during playback',
			'settings.matchContentFrameRate' => 'Match Content Frame Rate',
			'settings.matchContentFrameRateDescription' => 'Match display refresh rate to video content',
			'settings.matchContentResolution' => 'Match Content Resolution',
			'settings.matchContentResolutionDescription' => 'Switch the display to the video\'s native resolution so your TV handles upscaling. Menus and subtitles are upscaled too during playback',
			'settings.matchRefreshRate' => 'Match Refresh Rate',
			'settings.matchRefreshRateDescription' => 'Match display refresh rate in fullscreen',
			'settings.matchDynamicRange' => 'Match Dynamic Range',
			'settings.matchDynamicRangeDescription' => 'Switch HDR on for HDR content, then back to SDR',
			'settings.displaySwitchDelay' => 'Display Switch Delay',
			'settings.tunneledPlayback' => 'Tunneled Playback',
			'settings.tunneledPlaybackDescription' => 'Use video tunneling. Disable if HDR playback shows black video or motion stutters.',
			'settings.audioPassthrough' => 'Audio Passthrough',
			'settings.audioPassthroughDescription' => 'Send Dolby/DTS audio to your receiver or TV without re-encoding, preserving surround sound. Turn off if you have no sound.',
			'settings.audioPassthroughDescriptionAppleTv' => 'Use Apple\'s native Dolby decoder for Dolby Digital Plus, including Atmos. DTS and TrueHD still play as multichannel PCM. Turn off if you have no sound.',
			'settings.audioDownmix' => 'Downmix to Stereo',
			'settings.audioDownmixDescription' => 'Mix surround audio down to two channels for stereo speakers or headphones',
			'settings.downmixCenterBoost' => 'Center Channel Boost',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Boost (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Normalize Volume on Downmix',
			'settings.audioDownmixNormalizeDescription' => 'Lower the mix to prevent clipping. Turn off to keep the original volume (may distort loud scenes).',
			'settings.dvConversionMode' => 'Dolby Vision Conversion',
			'settings.dvConversionModeDescription' => 'Choose how Dolby Vision Profile 7 files are handled.',
			'settings.dvConversionAuto' => 'Auto',
			'settings.dvConversionNative' => 'Native / Disabled',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Use device capability detection and normal fallback behavior',
			'settings.dvConversionNativeDescription' => 'Force native DV7 and suppress DV conversion retry',
			'settings.dvConversionDv81Description' => 'Force inline RPU conversion to Dolby Vision profile 8.1',
			'settings.dvConversionHevcStripDescription' => 'Strip Dolby Vision RPU/EL layers and present plain HEVC',
			'settings.deinterlace' => 'Deinterlacing',
			'settings.deinterlaceDescription' => 'Remove combing artifacts from interlaced video (mpv player only)',
			'settings.requireProfileSelectionOnOpen' => 'Ask for profile on app open',
			'settings.requireProfileSelectionOnOpenDescription' => 'Show profile selection every time the app is opened',
			'settings.forceTvMode' => 'Force TV mode',
			'settings.forceTvModeDescription' => 'Force TV layout. For devices that don\'t auto-detect. Requires restart.',
			'settings.startInFullscreen' => 'Start in fullscreen',
			'settings.startInFullscreenDescription' => 'Open Plezy in fullscreen mode at launch',
			'settings.exitFullscreenOnPlayerClose' => 'Exit fullscreen on player close',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Automatically exit fullscreen when closing the video player',
			'settings.autoHidePerformanceOverlay' => 'Auto-Hide Performance Overlay',
			'settings.autoHidePerformanceOverlayDescription' => 'Fade the performance overlay with the playback controls',
			'settings.showNavBarLabels' => 'Show Navigation Bar Labels',
			'settings.showNavBarLabelsDescription' => 'Display text labels under navigation bar icons',
			'settings.startupSection' => 'Startup Section',
			'settings.showExploreTab' => 'Show Explore Tab',
			'settings.showExploreTabDescription' => 'Display the Explore tab with content from Plex Discover and connected trackers',
			'settings.liveTvDefaultFavorites' => 'Default to Favorite Channels',
			'settings.liveTvDefaultFavoritesDescription' => 'Show only favorite channels when opening Live TV',
			'settings.general' => 'General',
			'settings.generalDescription' => 'Language, startup, and window behavior',
			'settings.languageAndRegion' => 'Language & Region',
			'settings.startup' => 'Startup',
			'settings.display' => 'Display',
			'settings.libraryAndCards' => 'Library & Cards',
			'settings.homeScreen' => 'Home Screen',
			'settings.navigation' => 'Navigation',
			'settings.window' => 'Window',
			'settings.liveTv' => 'Live TV',
			'settings.player' => 'Player',
			'settings.videoAndDisplay' => 'Video & Display',
			'settings.audio' => 'Audio',
			'settings.quality' => 'Quality',
			'settings.subtitles' => 'Subtitles',
			'settings.seekAndTiming' => 'Seek & Timing',
			'settings.behavior' => 'Behavior',
			'settings.gestures' => 'Gestures',
			'settings.gestureBrightnessSwipe' => 'Brightness Swipe',
			'settings.gestureBrightnessSwipeDescription' => 'Swipe up or down on the left edge to adjust brightness',
			'settings.gestureVolumeSwipe' => 'Volume Swipe',
			'settings.gestureVolumeSwipeDescription' => 'Swipe up or down on the right edge to adjust volume',
			'settings.gesturePinchToZoom' => 'Pinch to Zoom',
			'settings.gesturePinchToZoomDescription' => 'Pinch on the video to zoom in or out',
			'settings.rememberBrightnessLevel' => 'Remember Brightness Level',
			'settings.rememberBrightnessLevelDescription' => 'Start playback at the brightness set by the last swipe',
			'settings.controls' => 'Controls',
			'settings.rememberPlayerChanges' => 'Remember Player Changes',
			'settings.rememberPlayerChangesDescription' => 'Where a change made during playback is saved and reapplied from',
			'settings.scopePlaybackSpeed' => 'Playback Speed',
			'settings.scopeShaderPreset' => 'Shader Preset',
			'settings.scopeAspectRatio' => 'Aspect Ratio',
			'settings.scopeSyncOffsets' => 'Audio & Subtitle Sync',
			'settings.playerScopeOff' => 'Don\'t save',
			'settings.playerScopeGlobal' => 'Everywhere',
			'settings.playerScopeLibrary' => 'Per library',
			'settings.playerScopeTitle' => 'Per show or movie',
			'settings.exportDialogTitle' => 'Export Plezy settings',
			'search.hint' => 'Search movies, shows, music...',
			'search.tryDifferentTerm' => 'Try a different search term',
			'search.searchYourMedia' => 'Search your media',
			'search.enterTitleActorOrKeyword' => 'Enter a title, actor, or keyword',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Set Shortcut for ${actionName}',
			'hotkeys.clearShortcut' => 'Clear shortcut',
			'hotkeys.noShortcutSet' => 'No shortcut set',
			'hotkeys.currentShortcut' => 'Current shortcut:',
			'hotkeys.pressToRecord' => 'Select to record a shortcut',
			'hotkeys.recordingShortcut' => 'Press the shortcut now',
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
			'hotkeys.actions.episodeNext' => 'Next Episode',
			'hotkeys.actions.episodePrevious' => 'Previous Episode',
			'hotkeys.actions.speedIncrease' => 'Increase Speed',
			'hotkeys.actions.speedDecrease' => 'Decrease Speed',
			'hotkeys.actions.speedReset' => 'Reset Speed',
			'hotkeys.actions.zoomIn' => 'Zoom In',
			'hotkeys.actions.zoomOut' => 'Zoom Out',
			'hotkeys.actions.zoomReset' => 'Reset Zoom',
			'hotkeys.actions.subSeekNext' => 'Seek to Next Subtitle',
			'hotkeys.actions.subSeekPrev' => 'Seek to Previous Subtitle',
			'hotkeys.actions.shaderToggle' => 'Toggle Shaders',
			'hotkeys.actions.skipMarker' => 'Skip Intro/Credits',
			'hotkeys.actions.screenshot' => 'Take Screenshot',
			'fileInfo.title' => 'File Info',
			'fileInfo.overview' => 'Overview',
			'fileInfo.video' => 'Video',
			'fileInfo.audio' => 'Audio',
			'fileInfo.subtitles' => 'Subtitles',
			'fileInfo.images' => 'Embedded Images',
			'fileInfo.dataStreams' => 'Data Streams',
			'fileInfo.lyrics' => 'Lyrics',
			'fileInfo.file' => 'File',
			'fileInfo.attachments' => 'Attachments',
			'fileInfo.delivery' => 'Delivery',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => 'Version ${index} of ${count}',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => 'File ${index} of ${count}',
			'fileInfo.noStreams' => 'The server reported no streams for this file.',
			'fileInfo.copyPath' => 'Copy path',
			'fileInfo.pathCopied' => 'File path copied',
			'fileInfo.codec' => 'Codec',
			'fileInfo.codecTag' => 'Codec Tag',
			'fileInfo.resolution' => 'Resolution',
			'fileInfo.codedResolution' => 'Coded Resolution',
			'fileInfo.bitrate' => 'Bitrate',
			'fileInfo.frameRate' => 'Frame Rate',
			'fileInfo.rotation' => 'Rotation',
			'fileInfo.comment' => 'Comment',
			'fileInfo.audioDescription' => 'Audio Description',
			'fileInfo.headerCompression' => 'Header Compression',
			'fileInfo.sidecarFile' => 'Sidecar File',
			'fileInfo.transportTimestamp' => 'Transport Timestamp',
			'fileInfo.displayOffset' => 'Display Offset',
			'fileInfo.previewFailureCode' => 'Preview Failure Code',
			'fileInfo.previewRetries' => 'Preview Retries',
			'fileInfo.aspectRatio' => 'Aspect Ratio',
			'fileInfo.pixelAspectRatio' => 'Pixel Aspect Ratio',
			'fileInfo.profile' => 'Profile',
			'fileInfo.level' => 'Level',
			'fileInfo.bitDepth' => 'Bit Depth',
			'fileInfo.pixelFormat' => 'Pixel Format',
			'fileInfo.colorSpace' => 'Color Space',
			'fileInfo.colorRange' => 'Color Range',
			'fileInfo.colorPrimaries' => 'Color Primaries',
			'fileInfo.colorTransfer' => 'Color Transfer',
			'fileInfo.chromaSubsampling' => 'Chroma Subsampling',
			'fileInfo.chromaLocation' => 'Chroma Location',
			'fileInfo.scanType' => 'Scan Type',
			'fileInfo.interlaced' => 'Interlaced',
			'fileInfo.anamorphic' => 'Anamorphic',
			'fileInfo.referenceFrames' => 'Reference Frames',
			'fileInfo.dynamicRange' => 'Dynamic Range',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Dolby Vision Level',
			'fileInfo.dolbyVisionVersion' => 'Dolby Vision Version',
			'fileInfo.dolbyVisionLayers' => 'Dolby Vision Layers',
			'fileInfo.baseLayerCompatibility' => 'Base Layer Compatibility',
			'fileInfo.avcBitstream' => 'AVC Bitstream',
			'fileInfo.nalLengthSize' => 'NAL Length Size',
			'fileInfo.scalingMatrix' => 'Custom Scaling Matrix',
			'fileInfo.streamIdentifier' => 'Stream Identifier',
			'fileInfo.streamIndex' => 'Stream Index',
			'fileInfo.streamId' => 'Stream ID',
			'fileInfo.language' => 'Language',
			'fileInfo.languageCode' => 'Language Code',
			'fileInfo.streamTitle' => 'Track Title',
			'fileInfo.channels' => 'Channels',
			'fileInfo.sampleRate' => 'Sample Rate',
			'fileInfo.spatialAudio' => 'Spatial Audio',
			'fileInfo.textBased' => 'Text Based',
			'fileInfo.subtitleFormat' => 'Sidecar Format',
			'fileInfo.provider' => 'Provider',
			'fileInfo.matchScore' => 'Match Score',
			'fileInfo.externalDelivery' => 'Can Be Served Separately',
			'fileInfo.sidecarPath' => 'Sidecar Path',
			'fileInfo.sourceStream' => 'Copied From',
			'fileInfo.temporary' => 'Temporary',
			'fileInfo.timeBase' => 'Time Base',
			'fileInfo.overallBitrate' => 'Overall Bitrate',
			'fileInfo.path' => 'Path',
			'fileInfo.fileName' => 'File Name',
			'fileInfo.size' => 'Size',
			_ => null,
		} ?? switch (path) {
			'fileInfo.totalSize' => 'Total Size',
			'fileInfo.container' => 'Container',
			'fileInfo.duration' => 'Duration',
			'fileInfo.previewThumbnails' => 'Preview Thumbnails',
			'fileInfo.previewIndex' => 'Preview Index',
			'fileInfo.packetLength' => 'Packet Length',
			'fileInfo.filePresent' => 'File Present',
			'fileInfo.fileReadable' => 'Readable by Server',
			'fileInfo.streamPath' => 'Stream Path',
			'fileInfo.optimizedForStreaming' => 'Optimized for Streaming',
			'fileInfo.has64bitOffsets' => '64-bit Offsets',
			'fileInfo.protocol' => 'Protocol',
			'fileInfo.mediaType' => 'Media Type',
			'fileInfo.sourceKind' => 'Source Kind',
			'fileInfo.optimizedVersion' => 'Optimized Version',
			'fileInfo.optimizationTarget' => 'Optimization Target',
			'fileInfo.deletedAt' => 'Deleted',
			'fileInfo.remoteSource' => 'Remote Source',
			'fileInfo.infiniteStream' => 'Infinite Stream',
			'fileInfo.directPlay' => 'Direct Play',
			'fileInfo.directStream' => 'Direct Stream',
			'fileInfo.transcoding' => 'Transcoding',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'Version ID',
			'fileInfo.fileId' => 'File ID',
			'fileInfo.defaultAudioTrack' => 'Default Audio Track',
			'fileInfo.defaultSubtitleTrack' => 'Default Subtitle Track',
			'fileInfo.subtitlesOff' => 'Off',
			'fileInfo.flagDefault' => 'Default',
			'fileInfo.flagForced' => 'Forced',
			'fileInfo.flagSelected' => 'Selected',
			'fileInfo.flagExternal' => 'External',
			'fileInfo.flagHearingImpaired' => 'Hearing impaired',
			'fileInfo.flagDub' => 'Dub',
			'fileInfo.flagOriginal' => 'Original',
			'fileInfo.channelsMono' => 'Mono',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'Profile ${profile}',
			'mediaMenu.markAsWatched' => 'Mark as Watched',
			'mediaMenu.markAsUnwatched' => 'Mark as Unwatched',
			'mediaMenu.removeFromContinueWatching' => 'Remove from Continue Watching',
			'mediaMenu.viewDetails' => 'View details',
			'mediaMenu.goToSeries' => 'Go to series',
			'mediaMenu.shufflePlay' => 'Shuffle Play',
			'mediaMenu.shuffleNotAvailableOffline' => 'Shuffle not available offline',
			'mediaMenu.fileInfo' => 'File Info',
			'mediaMenu.deleteEpisodeFromServer' => 'Delete episode from server',
			'mediaMenu.deleteSeasonFromServer' => 'Delete season from server',
			'mediaMenu.deleteShowFromServer' => 'Delete show from server',
			'mediaMenu.deleteMovieFromServer' => 'Delete movie from server',
			'mediaMenu.deleteEpisodeTitle' => 'Delete this episode?',
			'mediaMenu.deleteSeasonTitle' => 'Delete this season?',
			'mediaMenu.deleteShowTitle' => 'Delete this show?',
			'mediaMenu.deleteMovieTitle' => 'Delete this movie?',
			'mediaMenu.deleteEpisodeConfirm' => 'Delete episode',
			'mediaMenu.deleteSeasonConfirm' => 'Delete season',
			'mediaMenu.deleteShowConfirm' => 'Delete show',
			'mediaMenu.deleteMovieConfirm' => 'Delete movie',
			'mediaMenu.deleteAnyway' => 'Delete anyway',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => 'Permanently delete ${title} from your server?',
			'mediaMenu.deleteMultipleWarning' => 'This includes all episodes and their files.',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'This deletes all ${n} episode in it, and its file.', other: 'This deletes all ${n} episodes in it, and their files.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'This item is stored as ${n} file, which will be deleted.', other: 'This item is stored across ${n} files, and all of them will be deleted.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} other episode is stored in the same file and will be deleted too:', other: '${n} other episodes are stored in the same file and will be deleted too:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'Plezy could not check which files this will remove, so it may delete more than the item named above. Cancel and try again, or delete anyway.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'Your server did not provide file details for this item, so Plezy cannot check which files this will remove. It may delete more than the item named above.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Media item deleted successfully',
			'mediaMenu.mediaFailedToDelete' => 'Failed to delete media item',
			'mediaMenu.rate' => 'Rate',
			'mediaMenu.playFromBeginning' => 'Play from Beginning',
			'mediaMenu.playVersion' => 'Play Version...',
			'rateSheet.title' => 'Rate',
			'rateSheet.server' => 'Server',
			'rateSheet.favorite' => 'Favorite',
			'rateSheet.favorited' => 'Favorited',
			'rateSheet.saved' => 'Saved',
			'rateSheet.notAvailable' => 'No match found',
			'rateSheet.noConnectedServices' => 'Connect a service in Settings to rate there.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, movie',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, TV show',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'watched',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} percent watched',
			'accessibility.mediaCardUnwatched' => 'unwatched',
			'accessibility.tapToPlay' => 'Tap to play',
			'accessibility.decrease' => 'Decrease',
			'accessibility.increase' => 'Increase',
			'accessibility.decreaseValue' => ({required Object label}) => 'Decrease ${label}',
			'accessibility.increaseValue' => ({required Object label}) => 'Increase ${label}',
			'accessibility.hue' => 'Hue',
			'accessibility.saturation' => 'Saturation',
			'accessibility.brightness' => 'Brightness',
			'accessibility.hexColor' => 'Hex color',
			'accessibility.expandText' => 'Expand text',
			'accessibility.collapseText' => 'Collapse text',
			'accessibility.alphabetNavigation' => 'Alphabet navigation',
			'accessibility.alphabetScrollHint' => 'Swipe up or down to move by letter',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Row ${row} of ${rowCount}, column ${column} of ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'Row ${row} of ${rowCount}',
			'accessibility.autoScrollPlay' => 'Play auto-scroll',
			'accessibility.autoScrollPause' => 'Pause auto-scroll',
			'accessibility.hueShort' => 'H',
			'accessibility.saturationShort' => 'S',
			'accessibility.valueShort' => 'V',
			'tooltips.shufflePlay' => 'Shuffle play',
			'tooltips.playTrailer' => 'Play trailer',
			'tooltips.markAsWatched' => 'Mark as watched',
			'tooltips.markAsUnwatched' => 'Mark as unwatched',
			'audioTracks.track' => ({required Object n}) => 'Audio Track ${n}',
			'videoControls.audioLabel' => 'Audio',
			'videoControls.subtitlesLabel' => 'Subtitles',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => 'Letterbox',
			'videoControls.fillScreen' => 'Fill screen',
			'videoControls.stretch' => 'Stretch',
			'videoControls.lockRotation' => 'Lock rotation',
			'videoControls.unlockRotation' => 'Unlock rotation',
			'videoControls.timerActive' => 'Timer Active',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Playback will pause in ${duration}',
			'videoControls.sleepTimerEndOfVideo' => 'End of current video',
			'videoControls.sleepTimerStopAtHeader' => 'Stop at',
			'videoControls.sleepTimerDurationHeader' => 'Timer',
			'videoControls.playbackWillPauseAtEnd' => 'Playback will pause at the end of this video',
			'videoControls.stillWatching' => 'Still watching?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Pausing in ${seconds}s',
			'videoControls.continueWatching' => 'Continue',
			'videoControls.autoPlayNext' => 'Auto-Play Next',
			'videoControls.playNext' => 'Play Next',
			'videoControls.playButton' => 'Play',
			'videoControls.pauseButton' => 'Pause',
			'videoControls.playbackPaused' => 'Paused',
			'videoControls.playbackResumed' => 'Playing',
			'videoControls.loadingVideo' => 'Loading video',
			'videoControls.showPlaybackControls' => 'Show playback controls',
			'videoControls.hidePlaybackControls' => 'Hide playback controls',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Seek backward ${seconds} seconds',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Seek forward ${seconds} seconds',
			'videoControls.previousButton' => 'Previous episode',
			'videoControls.nextButton' => 'Next episode',
			'videoControls.previousChapterButton' => 'Previous chapter',
			'videoControls.nextChapterButton' => 'Next chapter',
			'videoControls.muteButton' => 'Mute',
			'videoControls.unmuteButton' => 'Unmute',
			'videoControls.settingsButton' => 'Playback Settings',
			'videoControls.tracksButton' => 'Audio & Subtitles',
			'videoControls.chaptersButton' => 'Chapters',
			'videoControls.versionQualityButton' => 'Version & Quality',
			'videoControls.versionColumnHeader' => 'Version',
			'videoControls.qualityColumnHeader' => 'Quality',
			'videoControls.qualityOriginal' => 'Original',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Transcoding unavailable — playing original quality',
			'videoControls.subtitleUnavailableFallback' => 'Selected subtitles could not be loaded — continuing without subtitles',
			'videoControls.pipButton' => 'Picture-in-Picture mode',
			'videoControls.aspectRatioButton' => 'Aspect ratio',
			'videoControls.ambientLighting' => 'Ambient lighting',
			'videoControls.fullscreenButton' => 'Enter fullscreen',
			'videoControls.exitFullscreenButton' => 'Exit fullscreen',
			'videoControls.alwaysOnTopButton' => 'Always on top',
			'videoControls.rotationLockButton' => 'Rotation lock',
			'videoControls.lockScreen' => 'Lock screen',
			'videoControls.screenLockButton' => 'Screen lock',
			'videoControls.longPressToUnlock' => 'Long press to unlock',
			'videoControls.timelineSlider' => 'Video timeline',
			'videoControls.volumeSlider' => 'Volume level',
			'videoControls.endsAt' => ({required Object time}) => 'Ends at ${time}',
			'videoControls.pipActive' => 'Playing in Picture-in-Picture',
			'videoControls.pipFailed' => 'Picture-in-picture failed to start',
			'videoControls.screenshotSaved' => 'Screenshot saved',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Zoom ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Requires Android 8.0 or newer',
			'videoControls.pipErrors.iosVersion' => 'Requires iOS 15.0 or newer',
			'videoControls.pipErrors.permissionDisabled' => 'Picture-in-picture is disabled. Enable it in system settings.',
			'videoControls.pipErrors.notSupported' => 'Device doesn\'t support picture-in-picture mode',
			'videoControls.pipErrors.voSwitchFailed' => 'Failed to switch video output for picture-in-picture',
			'videoControls.pipErrors.failed' => 'Picture-in-picture failed to start',
			'videoControls.pipErrors.prepareFailed' => 'Picture-in-picture could not be prepared',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'An error occurred: ${error}',
			'videoControls.chapters' => 'Chapters',
			'videoControls.noChaptersAvailable' => 'No chapters available',
			'videoControls.queue' => 'Queue',
			'videoControls.noQueueItems' => 'No items in queue',
			'videoControls.noAudioDevicesAvailable' => 'No audio devices available',
			'videoControls.searchSubtitles' => 'Search Subtitles',
			'videoControls.language' => 'Language',
			'videoControls.noSubtitlesFound' => 'No subtitles found',
			'videoControls.subtitleDownloaded' => 'Subtitle downloaded',
			'videoControls.subtitleDownloadedNotApplied' => 'Subtitle downloaded, but it could not be selected',
			'videoControls.subtitleDownloadFailed' => 'Failed to download subtitle',
			'videoControls.searchLanguages' => 'Search languages...',
			'videoControls.skipIntro' => 'Skip Intro',
			'videoControls.skipCredits' => 'Skip Credits',
			'videoControls.nextEpisode' => 'Next Episode',
			'videoControls.subtitleTrack' => ({required Object n}) => 'Track ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => 'Subtitle ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (Forced)',
			'videoControls.osdSubtitlesOff' => 'Subtitles: Off',
			'videoControls.osdSubtitles' => ({required Object track}) => 'Subtitles: ${track}',
			'videoControls.osdAudio' => ({required Object track}) => 'Audio: ${track}',
			'messages.markedAsWatched' => 'Marked as watched',
			'messages.markedAsUnwatched' => 'Marked as unwatched',
			'messages.markedAsWatchedOffline' => 'Marked as watched (will sync when online)',
			'messages.markedAsUnwatchedOffline' => 'Marked as unwatched (will sync when online)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Auto-removed: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'Auto-removed ${n} watched download', other: 'Auto-removed ${n} watched downloads', ), 
			'messages.removedFromContinueWatching' => 'Removed from Continue Watching',
			'messages.errorLoading' => ({required Object error}) => 'Error: ${error}',
			'messages.searchPartialResults' => 'Some media servers could not be searched. Showing available results.',
			'messages.streamInterrupted' => 'The stream was interrupted. Press play or seek to retry.',
			'messages.liveStreamInterrupted' => 'The live stream was interrupted. Press play to retry.',
			'messages.fileInfoNotAvailable' => 'File information not available',
			'messages.playbackAuthenticationRequired' => 'Sign in to the media server again to play this item.',
			'messages.playbackServerUnavailable' => 'The media server is unavailable. Try again later.',
			'messages.playbackDataInvalid' => 'The server returned invalid playback information.',
			'messages.playbackCancelled' => 'Playback was canceled.',
			'messages.playbackFailed' => 'Playback could not be started.',
			'messages.mediaUnavailable' => 'This content is no longer available.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Error loading file info: ${error}',
			'messages.errorLoadingSeries' => 'Error loading series',
			'messages.musicNotSupported' => 'Music playback is not yet supported',
			'messages.noDescriptionAvailable' => 'No description available',
			'messages.noProfilesAvailable' => 'No profiles available',
			'messages.contactAdminForProfiles' => 'Contact your server administrator to add profiles',
			'messages.unableToDetermineLibrarySection' => 'Unable to determine library section for this item',
			'messages.logsCleared' => 'Logs cleared',
			'messages.logsCopied' => 'Logs copied to clipboard',
			'messages.noLogsAvailable' => 'No logs available',
			'messages.libraryScanning' => ({required Object title}) => 'Scanning "${title}"...',
			'messages.libraryScanStarted' => ({required Object title}) => 'Library scan started for "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Failed to scan library: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Refreshing metadata for "${title}"...',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Metadata refresh started for "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Failed to refresh metadata: ${error}',
			'messages.logoutConfirm' => 'Are you sure you want to log out?',
			'messages.noSeasonsFound' => 'No seasons found',
			'messages.seasonsLoadFailed' => 'Couldn\'t load seasons',
			'messages.noEpisodesFound' => 'No episodes found in first season',
			'messages.noEpisodesFoundGeneral' => 'No episodes found',
			'messages.episodesLoadFailed' => 'Couldn\'t load episodes',
			'messages.noResultsFound' => 'No results found',
			'messages.sleepTimerSet' => ({required Object label}) => 'Sleep timer set for ${label}',
			'messages.noItemsAvailable' => 'No items available',
			'messages.failedToCreatePlayQueueNoItems' => 'Failed to create a play queue — no items',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Failed to ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Switching to compatible player...',
			'messages.serverLimitTitle' => 'Playback failed',
			'messages.serverLimitBody' => 'Server error (HTTP 500). A bandwidth/transcoding limit likely rejected this session. Ask the owner to adjust it.',
			'messages.mediaUnreadableTitle' => 'File unavailable',
			'messages.mediaUnreadableBody' => 'The server found this item but could not read its file (HTTP 404). The file was probably moved, deleted, or its storage is offline. Ask the server owner to check the file and rescan the library.',
			'messages.serverBusyTitle' => 'Stream unavailable',
			'messages.serverBusyBody' => 'The server kept refusing to stream this file (HTTP 503). It may be restarting, busy, or the file\'s storage may be offline. Try again in a moment — if it keeps happening, ask the server owner to check the server and the file\'s storage.',
			'messages.logsUploaded' => 'Logs uploaded',
			'messages.logsUploadFailed' => 'Failed to upload logs',
			'messages.logId' => 'Log ID',
			'messages.burnedSubtitlesUseMenu' => 'Subtitles are burned into this stream. Change them from the subtitle menu.',
			'messages.noVideoUrl' => 'No video URL available',
			'messages.playbackNoMediaSources' => 'The server returned no playable media sources',
			'messages.playbackDataNotPrepared' => 'Playback was started before its data was ready',
			'messages.streamSelectionUnavailable' => 'Stream selection is not available for this source',
			'messages.streamSelectionFailed' => 'Could not apply the selected streams',
			'messages.serverUnavailableForProfile' => 'No server is available for the active profile',
			'subtitlingStyling.text' => 'Text',
			'subtitlingStyling.border' => 'Border',
			'subtitlingStyling.background' => 'Background',
			'subtitlingStyling.fontSize' => 'Font Size',
			'subtitlingStyling.textColor' => 'Text Color',
			'subtitlingStyling.borderSize' => 'Border Size',
			'subtitlingStyling.borderColor' => 'Border Color',
			'subtitlingStyling.backgroundOpacity' => 'Background Opacity',
			'subtitlingStyling.backgroundColor' => 'Background Color',
			'subtitlingStyling.position' => 'Position',
			'subtitlingStyling.assOverride' => 'ASS Override',
			'subtitlingStyling.overrideScale' => 'Scale',
			'subtitlingStyling.overrideForce' => 'Force',
			'subtitlingStyling.overrideStrip' => 'Remove styling',
			'subtitlingStyling.positionTop' => 'Top',
			'subtitlingStyling.positionBottom' => 'Bottom',
			'subtitlingStyling.anchorToScreen' => 'Anchor to Screen',
			'subtitlingStyling.anchorToScreenDescription' => 'Show text subtitles in the black bars below widescreen video',
			'subtitlingStyling.bold' => 'Bold',
			'subtitlingStyling.italic' => 'Italic',
			'subtitlingStyling.renderResolution' => 'Render Resolution',
			'subtitlingStyling.renderResolutionScreen' => 'Screen resolution',
			'subtitlingStyling.renderResolutionVideo' => 'Video resolution',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Advanced video player settings',
			'mpvConfig.presets' => 'Presets',
			'mpvConfig.noPresets' => 'No saved presets',
			'mpvConfig.saveAsPreset' => 'Save as Preset...',
			'mpvConfig.presetName' => 'Preset Name',
			'mpvConfig.presetNameHint' => 'Enter a name for this preset',
			'mpvConfig.loadPreset' => 'Load',
			'mpvConfig.deletePreset' => 'Delete',
			'mpvConfig.presetSaved' => 'Preset saved',
			'mpvConfig.presetLoaded' => 'Preset loaded',
			'mpvConfig.presetDeleted' => 'Preset deleted',
			'mpvConfig.confirmDeletePreset' => 'Are you sure you want to delete this preset?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comment',
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => 'Add line',
			'mpvConfig.removeLine' => 'Remove line',
			'mpvConfig.embeddedVoHint' => 'vo, gpu-context and gpu-api are ignored on Linux: embedded video always renders through vo=libmpv on the video plane, and gpu-next (which compute shaders like ArtCNN need) cannot run embedded.',
			'dialog.confirmAction' => 'Confirm Action',
			'profiles.addPlezyProfile' => 'Add Plezy profile',
			'profiles.switchingProfile' => 'Switching profile…',
			'profiles.deleteThisProfileTitle' => 'Delete this profile?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'Remove ${displayName}. Connections aren\'t affected.',
			'profiles.active' => 'Active',
			'profiles.manage' => 'Manage',
			'profiles.delete' => 'Delete',
			'profiles.signOut' => 'Sign out',
			'profiles.signOutPlexTitle' => 'Sign out of Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'Remove ${displayName} and all Plex Home users? Sign back in anytime.',
			'profiles.signedOutPlex' => 'Signed out of Plex.',
			'profiles.signOutFailed' => 'Sign out failed.',
			'profiles.sectionTitle' => 'Profiles',
			'profiles.summarySingle' => 'Add profiles to mix managed users and local identities',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} profiles · active: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} profiles',
			'profiles.removeConnectionTitle' => 'Remove connection?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'Remove ${displayName}\'s access to ${connectionLabel}. Other profiles keep it.',
			'profiles.deleteProfileTitle' => 'Delete profile?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'Remove ${displayName} and its connections. Servers stay available.',
			'profiles.profileNameLabel' => 'Profile name',
			'profiles.pinProtectionLabel' => 'PIN protection',
			'profiles.pinManagedByPlex' => 'PIN managed by Plex. Edit on plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'No PIN set. To require one, edit the home user on plex.tv.',
			'profiles.setPin' => 'Set PIN',
			'profiles.setPinTitle' => 'Set PIN',
			'profiles.confirmPinTitle' => 'Confirm PIN',
			'profiles.pinSet' => 'PIN set',
			'profiles.changePin' => 'Change',
			'profiles.removePin' => 'Remove',
			'profiles.connectionsLabel' => 'Connections',
			'profiles.add' => 'Add',
			'profiles.deleteProfileButton' => 'Delete profile',
			'profiles.noConnectionsHint' => 'No connections — add one to use this profile.',
			'profiles.noConnections' => 'No connections',
			'profiles.plexHomeAccount' => 'Plex Home account',
			'profiles.plexAccountChip' => ({required Object account}) => 'Plex account: ${account}',
			'profiles.plexAccountUserChip' => ({required Object user, required Object account}) => '${user} via ${account}',
			'profiles.connectionDefault' => 'Default',
			'profiles.connectionAs' => ({required Object displayName}) => 'as ${displayName}',
			'profiles.makeDefault' => 'Make default',
			'profiles.removeConnection' => 'Remove',
			'profiles.profileRenamed' => 'Profile renamed.',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Add to ${displayName}',
			'profiles.borrowExplain' => 'Borrow another profile\'s connection. PIN-protected profiles require a PIN.',
			'profiles.borrowEmpty' => 'Nothing to borrow yet.',
			'profiles.borrowEmptySubtitle' => 'Connect Plex, Jellyfin, or Emby to another profile first.',
			'profiles.borrowLoadFailed' => 'Available connections could not be loaded. Try again.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'From ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'Connection borrowed.',
			'profiles.borrowFailed' => 'Failed to borrow connection.',
			'profiles.incorrectPin' => 'Incorrect PIN.',
			'profiles.incorrectPinTryAgain' => 'Incorrect PIN. Please try again.',
			'profiles.sourceProfileMissingParentAccount' => 'Source profile is missing its parent account.',
			'profiles.failedToLoadHomeUsers' => 'Could not load your Plex Home users. Check your connection and try again.',
			'profiles.failedToVerifyPin' => 'Failed to verify PIN.',
			'profiles.newProfile' => 'New profile',
			'profiles.profileNameHint' => 'e.g. Guests, Kids, Family Room',
			'profiles.pinProtectionOptional' => 'PIN protection (optional)',
			'profiles.pinExplain' => '4-digit PIN required to switch profiles.',
			'profiles.continueButton' => 'Continue',
			'profiles.pinsDontMatch' => 'PINs don\'t match',
			'profiles.tokenIdentityMismatch' => 'The Plex profile token resolved to an unexpected server',
			'connections.sectionTitle' => 'Connections',
			'connections.addConnection' => 'Add connection',
			'connections.addConnectionSubtitleNoProfile' => 'Sign in with Plex or connect a Jellyfin or Emby server',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Add to ${displayName}: Plex, Jellyfin, Emby, or another profile connection',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Session expired for ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Session expired for ${count} servers',
			'connections.signInAgain' => 'Sign in again',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'Edit ${product} connection',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'Add or remove URLs for ${serverName}. Plezy will use the reachable URL with the lowest latency.',
			'accountPreferences.sectionTitle' => 'Account preferences',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => 'Audio, subtitle and library options saved on ${account}',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => 'Audio, subtitle and library options saved on ${count} accounts',
			'accountPreferences.pickAccount' => 'Every account stores its own preferences. Pick the one to edit.',
			'accountPreferences.storedOnAccount' => 'These options are saved on the account itself, so every app signed in to it uses them — including Plezy on your other devices.',
			'accountPreferences.noAccounts' => 'No accounts to configure',
			'accountPreferences.noAccountsHint' => 'Sign in to Plex, or connect a Jellyfin or Emby server, and the preferences stored on that account show up here.',
			'accountPreferences.unavailable' => 'Can\'t reach this account',
			'accountPreferences.loadFailed' => 'Couldn\'t load these preferences',
			'accountPreferences.noPreference' => 'No preference',
			'accountPreferences.notSet' => 'Not set',
			'accountPreferences.groups.audioAndSubtitles' => 'Audio & subtitles',
			'accountPreferences.groups.libraryDisplay' => 'Library',
			'accountPreferences.groups.personalMedia' => 'Personal media',
			'accountPreferences.preferredAudioLanguage' => 'Preferred audio language',
			'accountPreferences.autoSelectAudio' => 'Choose audio by language',
			'accountPreferences.autoSelectAudioDescription' => 'Off keeps whatever audio track the file marks as default.',
			'accountPreferences.preferredSubtitleLanguage' => 'Preferred subtitle language',
			'accountPreferences.subtitleMode' => 'Turn subtitles on',
			'accountPreferences.subtitleModes.none' => 'Manually selected',
			'accountPreferences.subtitleModes.noneDescription' => 'Never turn subtitles on by itself.',
			'accountPreferences.subtitleModes.defaultMode' => 'Follow the track flags',
			'accountPreferences.subtitleModes.defaultModeDescription' => 'Use the default and forced flags stored on each subtitle track.',
			'accountPreferences.subtitleModes.always' => 'Always enabled',
			'accountPreferences.subtitleModes.alwaysDescription' => 'Turn on a subtitle track in the preferred language whenever one exists.',
			'accountPreferences.subtitleModes.onlyForced' => 'Only forced subtitles',
			'accountPreferences.subtitleModes.onlyForcedDescription' => 'Load only the tracks marked as forced.',
			'accountPreferences.subtitleModes.smart' => 'Shown with foreign audio',
			'accountPreferences.subtitleModes.smartDescription' => 'Turn subtitles on only when the audio is in another language.',
			'accountPreferences.subtitleAccessibility' => 'SDH subtitles',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'Prefer non-SDH subtitles',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'Prefer SDH subtitles',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'Only SDH subtitles',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'Only non-SDH subtitles',
			'accountPreferences.forcedSubtitles' => 'Forced subtitles',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'Prefer non-forced subtitles',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'Prefer forced subtitles',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'Only forced subtitles',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'Only non-forced subtitles',
			'accountPreferences.displayMissingEpisodes' => 'Show missing episodes',
			'accountPreferences.displayMissingEpisodesDescription' => 'List episodes the server knows about but has no file for.',
			'accountPreferences.hidePlayedInLatest' => 'Hide watched items in Latest',
			'accountPreferences.hidePlayedInLatestDescription' => 'Leave items you have already watched out of the server\'s Latest rows.',
			'accountPreferences.displayCollectionsView' => 'Show the Collections view',
			'accountPreferences.displayCollectionsViewDescription' => 'Offer the server\'s Collections view alongside your libraries.',
			'accountPreferences.rewatchingInNextUp' => 'Keep rewatched shows in Next Up',
			'accountPreferences.rewatchingInNextUpDescription' => 'Once you finish a show, start it again and Next Up follows the rewatch instead of dropping the show.',
			'accountPreferences.watchedIndicator' => 'Watched indicators',
			'accountPreferences.watchedIndicatorOptions.none' => 'Never',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => 'Movies and TV shows',
			'accountPreferences.watchedIndicatorOptions.movies' => 'Movies only',
			'accountPreferences.watchedIndicatorOptions.shows' => 'TV shows only',
			'accountPreferences.mediaReviewsVisibility' => 'Ratings & reviews',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'Users and critics',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'Users only',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'Critics only',
			'accountPreferences.mediaReviewsOptions.nobody' => 'Hidden',
			'discover.title' => 'Discover',
			'discover.noContentAvailable' => 'No content available',
			'discover.addMediaToLibraries' => 'Add some media to your libraries',
			'discover.continueWatching' => 'Continue Watching',
			'discover.continueWatchingIn' => ({required Object library}) => 'Continue Watching in ${library}',
			'discover.nextUp' => 'Next Up',
			'discover.nextUpIn' => ({required Object library}) => 'Next Up in ${library}',
			'discover.recentlyAdded' => 'Recently Added',
			'discover.recentlyAddedIn' => ({required Object library}) => 'Recently Added in ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => 'Latest Albums in ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'Recently Played in ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'Most Played in ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Overview',
			'discover.cast' => 'Cast',
			'discover.extras' => 'Trailers & Extras',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Rating',
			'discover.director' => 'Director',
			'discover.directors' => 'Directors',
			'discover.movie' => 'Movie',
			'discover.tvShow' => 'TV Show',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} min left',
			'discover.moreLikeThis' => 'More Like This',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} title', other: '${n} titles', ), 
			'errors.searchFailed' => ({required Object error}) => 'Search failed: ${error}',
			'errors.searchUnavailable' => 'Search could not reach any media server.',
			'errors.connectionTimeout' => ({required Object context}) => 'Connection timeout while loading ${context}',
			'errors.connectionFailed' => 'Unable to connect to media server',
			'errors.unableToLoad' => ({required Object context}) => 'Unable to load ${context}. Please try again.',
			'errors.noClientAvailable' => 'No client available',
			'errors.pleaseEnterToken' => 'Please enter a token',
			'errors.invalidToken' => 'Invalid token',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Failed to verify token: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Failed to switch to ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'Failed to delete ${displayName}',
			'errors.failedToRate' => 'Couldn\'t update rating',
			'libraries.title' => 'Libraries',
			'libraries.fallbackTitle' => 'Library',
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
			'libraries.allLibrariesHidden' => 'All libraries are hidden',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Hidden libraries (${count})',
			'libraries.thisLibraryIsEmpty' => 'This library is empty',
			'libraries.noItemsMatchFilters' => 'No items match the active filters',
			'libraries.resetFilters' => 'Reset filters',
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
			_ => null,
		} ?? switch (path) {
			'libraries.tabs.collections' => 'Collections',
			'libraries.tabs.playlists' => 'Playlists',
			'libraries.groupings.title' => 'Grouping',
			'libraries.groupings.all' => 'All',
			'libraries.groupings.movies' => 'Movies',
			'libraries.groupings.shows' => 'TV Shows',
			'libraries.groupings.seasons' => 'Seasons',
			'libraries.groupings.episodes' => 'Episodes',
			'libraries.groupings.artists' => 'Artists',
			'libraries.groupings.albums' => 'Albums',
			'libraries.groupings.tracks' => 'Tracks',
			'libraries.groupings.folders' => 'Folders',
			'libraries.filterCategories.genre' => 'Genre',
			'libraries.filterCategories.year' => 'Year',
			'libraries.filterCategories.contentRating' => 'Content Rating',
			'libraries.filterCategories.tag' => 'Tag',
			'libraries.filterCategories.unwatched' => 'Unwatched',
			'libraries.filterCategories.unplayed' => 'Unplayed',
			'libraries.filterCategories.favorites' => 'Favorites',
			'libraries.sortLabels.title' => 'Title',
			'libraries.sortLabels.dateAdded' => 'Date Added',
			'libraries.sortLabels.releaseDate' => 'Release Date',
			'libraries.sortLabels.rating' => 'Rating',
			'libraries.sortLabels.communityRating' => 'Community Rating',
			'libraries.sortLabels.criticRating' => 'Critic Rating',
			'libraries.sortLabels.userRating' => 'User Rating',
			'libraries.sortLabels.datePlayed' => 'Date Played',
			'libraries.sortLabels.playCount' => 'Play Count',
			'libraries.sortLabels.productionYear' => 'Production Year',
			'libraries.sortLabels.runtime' => 'Runtime',
			'libraries.sortLabels.officialRating' => 'Official Rating',
			'libraries.sortLabels.premiereDate' => 'Premiere Date',
			'libraries.sortLabels.startDate' => 'Start Date',
			'libraries.sortLabels.airTime' => 'Air Time',
			'libraries.sortLabels.studio' => 'Studio',
			'libraries.sortLabels.random' => 'Random',
			'libraries.sortLabels.dateShared' => 'Date Shared',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Latest Episode Air Date',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Last Episode Date Added',
			'about.title' => 'About',
			'about.openSourceLicenses' => 'Open Source Licenses',
			'about.versionLabel' => ({required Object version}) => 'Version ${version}',
			'about.appDescription' => 'A beautiful Plex, Jellyfin, and Emby client for Flutter',
			'about.viewLicensesDescription' => 'View licenses of third-party libraries',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'No servers found for ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Failed to load servers: ${error}',
			'serverSelection.noValidServers' => 'No usable servers were found on this account',
			'hubDetail.title' => 'Title',
			'hubDetail.releaseYear' => 'Release Year',
			'hubDetail.dateAdded' => 'Date Added',
			'hubDetail.rating' => 'Rating',
			'hubDetail.noItemsFound' => 'No items found',
			'logs.clearLogs' => 'Clear Logs',
			'logs.copyLogs' => 'Copy Logs',
			'logs.uploadLogs' => 'Upload Logs',
			'startup.failedTitle' => 'Plezy could not start',
			'startup.failedBody' => 'Something went wrong during startup. The details below identify what failed.',
			'startup.failedBodyRepairable' => 'Plezy\'s saved settings file is damaged and has to be rebuilt before Plezy can start. Retrying will not help — choose Repair storage.',
			'startup.phaseLabel' => 'Step',
			'startup.showDetails' => 'Show details',
			'startup.hideDetails' => 'Hide details',
			'startup.copyDetails' => 'Copy details',
			'startup.detailsCopied' => 'Details copied to clipboard',
			'startup.uploadDetails' => 'Upload details',
			'startup.repairStorage' => 'Repair storage',
			'startup.repairTitle' => 'Repair stored data?',
			'startup.repairBodyCommon' => 'Plezy\'s settings file is damaged and cannot be read. Repairing resets every setting to its default.',
			'startup.repairBodyOneCredential' => 'One saved sign-in is damaged and cannot be read. Repairing removes just that one; your other settings are left alone.',
			'startup.repairBodySignInsKept' => 'Your servers and profiles should stay signed in.',
			'startup.repairBodySignInsLost' => 'The key protecting your saved sign-ins cannot be recovered from this file, so you will have to sign in to every server and profile again. Nothing on your media server is affected.',
			'startup.repairBodySessionsUncertain' => 'Trackers (MAL, AniList, Simkl, Trakt) and Seerr are stored separately and may or may not survive. Plezy will tell you exactly what it kept.',
			'startup.repairConfirm' => 'Repair',
			'startup.repairSucceeded' => 'Storage repaired',
			'startup.repairNeedsRestart' => 'Storage repaired — restart required',
			'startup.restartRequiredBody' => 'Your data was repaired, but Plezy has to start fresh before it can use it. Close Plezy and open it again.',
			'startup.quitPlezy' => 'Quit Plezy',
			'startup.repairFailed' => 'Repair failed',
			'startup.repairKeptSignIns' => 'Your servers and profiles are still signed in.',
			'startup.repairLostSignIns' => 'The key protecting your saved sign-ins could not be recovered. You will have to sign in to every server and profile again.',
			'startup.repairLostSessions' => 'At least one tracker or Seerr connection was lost and has to be reconnected.',
			'startup.backupTitle' => 'A copy of the damaged file was kept',
			'startup.backupWarning' => 'It contains your sign-in credentials. Do not upload or share it.',
			'startup.deleteBackup' => 'Delete copy',
			'startup.backupDeleted' => 'Copy deleted.',
			'startup.previousFailureTitle' => 'Plezy failed to start last time',
			'licenses.relatedPackages' => 'Related Packages',
			'licenses.license' => 'License',
			'licenses.licenseNumber' => ({required Object number}) => 'License ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licenses',
			'navigation.libraries' => 'Libraries',
			'navigation.downloads' => 'Downloads',
			'navigation.liveTv' => 'Live TV',
			'navigation.explore' => 'Explore',
			'explore.title' => 'Explore',
			'explore.selectSource' => 'Select source',
			'explore.rows.watchlist' => 'Watchlist',
			'explore.rows.recommendedMovies' => 'Recommended Movies',
			'explore.rows.recommendedShows' => 'Recommended Shows',
			'explore.rows.trendingMovies' => 'Trending Movies',
			'explore.rows.trendingShows' => 'Trending Shows',
			'explore.rows.popularMovies' => 'Popular Movies',
			'explore.rows.popularShows' => 'Popular Shows',
			'explore.rows.trendingAnime' => 'Trending Anime',
			'explore.rows.suggestedAnime' => 'Suggested Anime',
			'explore.rows.airingAnime' => 'Top Airing Anime',
			'explore.rows.popularAnime' => 'Most Popular Anime',
			'explore.rows.trending' => 'Trending',
			'explore.rows.upcomingMovies' => 'Upcoming Movies',
			'explore.rows.upcomingShows' => 'Upcoming Shows',
			'explore.status.airing' => 'Airing',
			'explore.status.ended' => 'Ended',
			'explore.status.canceled' => 'Canceled',
			'explore.status.upcoming' => 'Upcoming',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} episode', other: '${n} episodes', ), 
			'explore.cast' => 'Cast',
			'explore.characters' => 'Characters',
			'explore.addToWatchlist' => 'Add to Watchlist',
			'explore.removeFromWatchlist' => 'Remove from Watchlist',
			'explore.addedToWatchlist' => 'Added to watchlist',
			'explore.removedFromWatchlist' => 'Removed from watchlist',
			'explore.watchlistUpdateFailed' => 'Couldn\'t update watchlist',
			'explore.watchlistNoMatch' => 'Couldn\'t match this item to a watchlist',
			'explore.notInLibrary' => 'Not in your library',
			'explore.inTheseLibraries' => 'In these libraries',
			'explore.checkingLibrary' => 'Checking your library...',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'Couldn\'t check ${n} server', other: 'Couldn\'t check ${n} servers', ), 
			'explore.emptyTitle' => 'Nothing here yet',
			'explore.emptyMessage' => ({required Object source}) => 'Rows from ${source} will appear here once they have content.',
			'explore.searchHint' => ({required Object source}) => 'Search ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'No results for "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'Search for movies and shows on ${source}.',
			'explore.searchFailed' => 'Search failed. Check your connection and try again.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} popular',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} airing',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} rated',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} trending',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} in ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} watching',
			'explore.badge.available' => 'Available',
			'explore.badge.partiallyAvailable' => 'Partly available',
			'explore.badge.availableIn4k' => '4K available',
			'explore.badge.requested' => 'Requested',
			'explore.badge.pendingApproval' => 'Pending approval',
			'explore.badge.processing' => 'Processing',
			'explore.badge.declined' => 'Declined',
			'explore.badge.requestFailed' => 'Request failed',
			'explore.badge.requested4k' => '4K requested',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} seasons',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => 'Ep ${episode} in ${duration}',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'Next in ${duration}',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} eps',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} min/ep',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} listed',
			'explore.stats.viewersDay' => ({required Object n}) => '${n} watched today',
			'explore.stats.viewersWeek' => ({required Object n}) => '${n} watched this week',
			'explore.stats.viewersMonth' => ({required Object n}) => '${n} watched this month',
			'explore.stats.viewersYear' => ({required Object n}) => '${n} watched this year',
			'explore.stats.viewersAllTime' => ({required Object n}) => '${n} viewers',
			'explore.stats.planning' => ({required Object n}) => '${n} planning to watch',
			'explore.stats.favorited' => ({required Object n}) => '${n} favorites',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} dropped it',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} comment', other: '${n} comments', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} votes',
			'explore.stats.watching' => ({required Object n}) => '${n} watching it',
			'explore.stats.completed' => ({required Object n}) => '${n} completed',
			'explore.stats.onHold' => ({required Object n}) => '${n} on hold',
			'explore.stats.dropped' => ({required Object n}) => '${n} dropped',
			'explore.season.winter' => 'Winter',
			'explore.season.spring' => 'Spring',
			'explore.season.summer' => 'Summer',
			'explore.season.fall' => 'Fall',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'TV',
			'explore.format.tvShort' => 'TV Short',
			'explore.format.movie' => 'Movie',
			'explore.format.special' => 'Special',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => 'Music',
			'explore.format.other' => 'Other',
			'explore.sourceMaterial.original' => 'Original',
			'explore.sourceMaterial.manga' => 'Manga',
			'explore.sourceMaterial.lightNovel' => 'Light novel',
			'explore.sourceMaterial.novel' => 'Novel',
			'explore.sourceMaterial.visualNovel' => 'Visual novel',
			'explore.sourceMaterial.game' => 'Game',
			'explore.sourceMaterial.webComic' => 'Web comic',
			'explore.sourceMaterial.musicRelease' => 'Music',
			'explore.sourceMaterial.otherMedia' => 'Other',
			'explore.creditRole.director' => 'Director',
			'explore.creditRole.writer' => 'Writer',
			'explore.creditRole.producer' => 'Producer',
			'explore.creditRole.creator' => 'Creator',
			'explore.creditRole.composer' => 'Composer',
			'explore.relation.prequel' => 'Prequel',
			'explore.relation.sequel' => 'Sequel',
			'explore.relation.sideStory' => 'Side story',
			'explore.relation.spinOff' => 'Spin-off',
			'explore.relation.alternativeVersion' => 'Alternative version',
			'explore.relation.summary' => 'Summary',
			'explore.relation.parentStory' => 'Parent story',
			'explore.relation.adaptation' => 'Adaptation',
			'explore.relation.other' => 'Related',
			'explore.broadcast' => ({required Object day, required Object time}) => 'Airs ${day} at ${time}',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => 'Airs ${day} at ${time} ${timezone}',
			'explore.detail.originalTitle' => 'Original title',
			'explore.detail.alsoKnownAs' => 'Also known as',
			'explore.detail.studios' => 'Studios',
			'explore.detail.country' => 'Country',
			'explore.detail.language' => 'Language',
			'explore.detail.released' => 'Released',
			'explore.detail.physicalRelease' => 'On disc',
			'explore.detail.ended' => 'Ended',
			'explore.detail.addedOn' => ({required Object date}) => 'Added ${date}',
			'explore.detail.yourRating' => 'Your rating',
			'explore.detail.budget' => 'Budget',
			'explore.detail.revenue' => 'Box office',
			'explore.detail.contentAdvisory' => 'Age guidance',
			'explore.detail.tags' => 'Tags',
			'explore.detail.revealSpoilerTags' => 'Show spoiler tags',
			'explore.detail.links' => 'Links',
			'explore.detail.watchOn' => 'Watch on',
			'explore.detail.watchTrailer' => 'Watch trailer',
			'explore.detail.openOn' => ({required Object site}) => 'Open on ${site}',
			'explore.detail.crew' => 'Crew',
			'explore.detail.ratings' => 'Ratings',
			'explore.detail.schedule' => 'Schedule',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'Recommended by ${n} user', other: 'Recommended by ${n} users', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'Recommended by ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'Favorited by ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} not aired yet',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'Recommended by ${percent} of viewers',
			'explore.detail.relatedTitles' => 'Related titles',
			'explore.detail.background' => 'Background',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} result', other: '${n} results', ), 
			'liveTv.title' => 'Live TV',
			'liveTv.guide' => 'Guide',
			'liveTv.noChannels' => 'No channels available',
			'liveTv.noDvr' => 'No DVR configured on any server',
			'liveTv.serverUnavailable' => 'Live TV server is not available.',
			'liveTv.serverNotConnected' => 'Live TV server is not connected.',
			'liveTv.noPrograms' => 'No program data available',
			'liveTv.liveStreamFailed' => 'Live stream failed',
			'liveTv.unknownProgram' => 'Unknown Program',
			'liveTv.unknownHub' => 'Unknown',
			'liveTv.unknownError' => 'Unknown error',
			'liveTv.channelNumber' => ({required Object number}) => 'Channel ${number}',
			'liveTv.unknownChannel' => 'Unknown channel',
			'liveTv.live' => 'LIVE',
			'liveTv.reloadGuide' => 'Reload Guide',
			'liveTv.searchGuide' => 'Search Guide',
			'liveTv.searchHint' => 'Search channels & programs',
			'liveTv.searchNoResults' => ({required Object query}) => 'No matches for "${query}"',
			'liveTv.channelsSection' => 'Channels',
			'liveTv.programsSection' => 'Programs',
			'liveTv.now' => 'Now',
			'liveTv.today' => 'Today',
			'liveTv.tomorrow' => 'Tomorrow',
			'liveTv.midnight' => 'Midnight',
			'liveTv.overnight' => 'Overnight',
			'liveTv.morning' => 'Morning',
			'liveTv.daytime' => 'Daytime',
			'liveTv.evening' => 'Evening',
			'liveTv.lateNight' => 'Late Night',
			'liveTv.whatsOn' => 'What\'s On',
			'liveTv.watchChannel' => 'Watch Channel',
			'liveTv.favorites' => 'Favorites',
			'liveTv.reorderFavorites' => 'Reorder Favorites',
			'liveTv.noFavoriteChannels' => 'No favorite channels',
			'liveTv.noFavoriteChannelsHint' => 'Show all channels, then long-press a channel to add it to your favorites.',
			'liveTv.showAllChannels' => 'Show All Channels',
			'liveTv.favoritesLoadFailed' => 'Could not load favorites. Check your connection and try again.',
			'liveTv.favoritesUpdateFailed' => 'Could not update favorites. Check your connection and try again.',
			'liveTv.joinSession' => 'Join Session in Progress',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Watch from start (${minutes} min ago)',
			'liveTv.watchLive' => 'Watch Live',
			'liveTv.goToLive' => 'Go to Live',
			'liveTv.record' => 'Record',
			'liveTv.recordEpisode' => 'Record Episode',
			'liveTv.recordSeries' => 'Record Series',
			'liveTv.recordOptions' => 'Record Options',
			'liveTv.saveTo' => 'Save to',
			'liveTv.recordings' => 'Recordings',
			'liveTv.scheduledRecordings' => 'Scheduled',
			'liveTv.recordingRules' => 'Recording Rules',
			'liveTv.noScheduledRecordings' => 'Nothing scheduled to record',
			'liveTv.manageRecording' => 'Manage recording',
			'liveTv.cancelRecording' => 'Cancel recording',
			'liveTv.cancelRecordingTitle' => 'Cancel this recording?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} will no longer be recorded.',
			'liveTv.deleteRule' => 'Delete rule',
			'liveTv.deleteRuleTitle' => 'Delete recording rule?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'Future episodes of ${title} will not be recorded.',
			'liveTv.recordingScheduled' => 'Recording scheduled',
			'liveTv.alreadyScheduled' => 'This program is already scheduled',
			'liveTv.dvrAdminRequired' => 'DVR settings require an admin account',
			'liveTv.recordingFailed' => 'Couldn\'t schedule recording',
			'liveTv.recordingTargetMissing' => 'Couldn\'t determine recording library',
			'liveTv.recordNotAvailable' => 'Recording not available for this program',
			'liveTv.recordingCancelled' => 'Recording canceled',
			'liveTv.recordingRuleDeleted' => 'Recording rule deleted',
			'liveTv.processRecordingRules' => 'Re-evaluate rules',
			'liveTv.recordingInProgress' => 'Recording now',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} scheduled',
			'liveTv.editRule' => 'Edit rule',
			'liveTv.editRuleAction' => 'Edit',
			'liveTv.recordingRuleUpdated' => 'Recording rule updated',
			'liveTv.guideReloadRequested' => 'Guide refresh requested',
			'liveTv.rulesProcessRequested' => 'Rule re-evaluation requested',
			'liveTv.recordShow' => 'Record show',
			'liveTv.recordSettings.startEarly' => 'Start early (seconds)',
			'liveTv.recordSettings.endLate' => 'End late (seconds)',
			'liveTv.recordSettings.newOnly' => 'Only new episodes',
			'liveTv.recordSettings.anyChannel' => 'Record on any channel',
			'liveTv.recordSettings.anyTime' => 'Record at any time',
			'liveTv.recordSettings.skipInLibrary' => 'Skip episodes already in the library',
			'liveTv.recordSettings.keepUpTo' => 'Episodes to keep',
			'liveTv.recordSettings.keepUpToHint' => '0 keeps every episode',
			'liveTv.startingInMinutes' => ({required Object minutes}) => 'Starting in ${minutes} min',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} at ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product} returned invalid Live TV playback data',
			'liveTv.failedToStartChannel' => 'Could not start the live channel',
			'liveTv.failedToBuildStreamUrl' => 'Could not build the stream URL',
			'collections.title' => 'Collections',
			'collections.collection' => 'Collection',
			'collections.empty' => 'Collection is empty',
			'collections.deleteCollection' => 'Delete Collection',
			'collections.deleteConfirm' => ({required Object title}) => 'Delete "${title}"? This can\'t be undone.',
			'collections.deleted' => 'Collection deleted',
			'collections.deleteFailed' => 'Failed to delete collection',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Failed to delete collection: ${error}',
			'collections.selectCollection' => 'Select Collection',
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
			'collections.searchCollections' => 'Search collections...',
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
			'playlists.searchPlaylists' => 'Search playlists...',
			'playlists.errorCreating' => 'Failed to create playlist',
			'playlists.errorDeleting' => 'Failed to delete playlist',
			'playlists.errorLoading' => 'Failed to load playlists',
			'playlists.errorAdding' => 'Failed to add to playlist',
			'playlists.errorReordering' => 'Failed to reorder playlist item',
			'playlists.errorRemoving' => 'Failed to remove from playlist',
			'music.goToAlbum' => 'Go to album',
			'music.goToArtist' => 'Go to artist',
			'music.instantMix' => 'Instant Mix',
			'music.playNext' => 'Play next',
			'music.addToQueue' => 'Add to queue',
			'music.discNumber' => ({required Object n}) => 'Disc ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} track', other: '${n} tracks', ), 
			'music.nowPlaying' => 'Now Playing',
			'music.playingFrom' => ({required Object title}) => 'Playing from ${title}',
			'music.queue' => 'Queue',
			'music.clearQueue' => 'Clear queue',
			'music.lyrics' => 'Lyrics',
			'music.noLyrics' => 'No lyrics available',
			'music.sleepTimer' => 'Sleep timer',
			'music.sleepTimerEndOfTrack' => 'End of track',
			'music.sleepTimerMinutes' => ({required Object n}) => '${n} minutes',
			'music.stopPlayback' => 'Stop playback',
			'music.previousTrack' => 'Previous track',
			'music.nextTrack' => 'Next track',
			'music.repeat' => 'Repeat',
			'music.repeatAll' => 'Repeat all',
			'music.repeatOne' => 'Repeat one',
			'music.instantMixNoServer' => 'No server is available for an instant mix',
			'music.instantMixFailed' => 'Failed to load the instant mix',
			'music.instantMixEmpty' => 'The instant mix came back with no tracks',
			'music.noAudioUrl' => ({required Object track}) => 'No audio URL is available for ${track}',
			'music.discography.singlesAndEps' => 'Singles & EPs',
			'music.discography.live' => 'Live',
			'music.discography.compilations' => 'Compilations',
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
			'watchTogether.openSessionControls' => 'Open Watch Together session controls',
			'watchTogether.copySessionCode' => 'Copy session code',
			'watchTogether.hostControlsPlayback' => 'Host controls playback',
			'watchTogether.anyoneCanControl' => 'Anyone can control playback',
			'watchTogether.hostControls' => 'Host controls',
			'watchTogether.anyoneControls' => 'Anyone controls',
			'watchTogether.participants' => 'Participants',
			'watchTogether.host' => 'Host',
			'watchTogether.hostBadge' => 'HOST',
			'watchTogether.youAreHost' => 'You are the host',
			'watchTogether.makeHost' => 'Make host',
			'watchTogether.makeHostQuestion' => 'Transfer host?',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} will control playback and drive the session for everyone.',
			'watchTogether.transfer' => 'Transfer',
			'watchTogether.hostChangedTo' => ({required Object name}) => '${name} is now the host',
			'watchTogether.youAreNowHost' => 'You are now the host',
			'watchTogether.hostTransferFailed' => ({required Object name}) => 'Couldn\'t make ${name} the host',
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
			'watchTogether.enterCodeHint' => 'Enter 5-character code',
			'watchTogether.pasteFromClipboard' => 'Paste from clipboard',
			'watchTogether.pleaseEnterCode' => 'Please enter a session code',
			'watchTogether.codeMustBe5Chars' => 'Session code must be 5 characters',
			'watchTogether.joinInstructions' => 'Enter the host\'s session code to join.',
			'watchTogether.failedToCreate' => 'Failed to create session',
			'watchTogether.failedToJoin' => 'Failed to join session',
			'watchTogether.sessionCodeCopied' => 'Session code copied to clipboard',
			'watchTogether.relayUnreachable' => 'Relay server unreachable. ISP blocking may prevent Watch Together.',
			'watchTogether.reconnectingToHost' => 'Reconnecting to host...',
			'watchTogether.currentPlayback' => 'Current Playback',
			'watchTogether.joinCurrentPlayback' => 'Join Current Playback',
			'watchTogether.joinCurrentPlaybackDescription' => 'Jump back into what the host is currently watching',
			'watchTogether.failedToOpenCurrentPlayback' => 'Failed to open current playback',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} joined',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} left',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} paused',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} resumed',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} changed the playback position',
			'watchTogether.participantChangedSpeed' => ({required Object name, required Object speed}) => '${name} set the speed to ${speed}',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} is buffering',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name} is on an older app version — sync unavailable',
			'watchTogether.resumingWithout' => ({required Object name}) => 'Resuming without ${name}',
			'watchTogether.waitingForParticipants' => 'Waiting for others to load...',
			'watchTogether.waitingForName' => ({required Object name}) => 'Waiting for ${name}...',
			'watchTogether.recentRooms' => 'Recent Rooms',
			'watchTogether.renameRoom' => 'Rename Room',
			'watchTogether.removeRoom' => 'Remove',
			'watchTogether.guestSwitchUnavailable' => 'Couldn\'t switch — server unavailable for sync',
			'watchTogether.guestSwitchFailed' => 'Couldn\'t switch — content not found on this server',
			'watchTogether.defaultDisplayName' => 'User',
			'watchTogether.errors.timedOut' => 'The relay did not respond in time',
			'watchTogether.errors.connectionLost' => 'The connection closed before the session was ready',
			'watchTogether.errors.invalidRelayResponse' => 'The relay sent an unexpected response',
			'watchTogether.errors.sessionEnded' => 'The host ended the session',
			'watchTogether.errors.sessionUnavailable' => 'Unable to resume this session. Join or create a room to continue.',
			'downloads.title' => 'Downloads',
			'downloads.manage' => 'Manage',
			'downloads.tvShows' => 'TV Shows',
			'downloads.movies' => 'Movies',
			'downloads.music' => 'Music',
			'downloads.tracksQueued' => ({required Object count}) => '${count} tracks queued for download',
			'downloads.noDownloads' => 'No downloads yet',
			'downloads.noDownloadsDescription' => 'Downloaded content will appear here for offline viewing',
			'downloads.downloadNow' => 'Download',
			'downloads.deleteDownload' => 'Delete download',
			'downloads.retryDownload' => 'Retry download',
			'downloads.downloadQueued' => 'Download queued',
			'downloads.downloadResumed' => 'Download resumed',
			'downloads.serverErrorBitrate' => 'Server error: file may exceed the remote bitrate limit',
			'downloads.storageFull' => 'Downloads stopped because device storage is full. Free some space, then retry.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} episodes queued for download',
			'downloads.downloadDeleted' => 'Download deleted',
			'downloads.deleteConfirm' => ({required Object title}) => 'Delete "${title}" from this device?',
			'downloads.cancelledDownloadTitle' => 'Canceled Download',
			'downloads.cancelledDownloadMessage' => 'This download was canceled. What would you like to do?',
			'downloads.allEpisodesAlreadyDownloaded' => 'All episodes already downloaded',
			'downloads.resumeDownload' => 'Resume download',
			'downloads.cancelledDownload' => 'Canceled download',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (syncing ${status})',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => 'Downloaded ${file} - Click to complete',
			'downloads.partialDownloadClickToComplete' => 'Partially downloaded - Click to complete',
			'downloads.deleting' => 'Deleting...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Deleting ${title}... (${current} of ${total})',
			'downloads.queuedTooltip' => 'Queued',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'Queued ${files}',
			'downloads.downloadingTooltip' => 'Downloading...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'Downloading ${files}',
			'downloads.noDownloadsTree' => 'No downloads',
			'downloads.pauseAll' => 'Pause all',
			_ => null,
		} ?? switch (path) {
			'downloads.resumeAll' => 'Resume all',
			'downloads.deleteAll' => 'Delete all',
			'downloads.selectVersion' => 'Select Version',
			'downloads.allEpisodes' => 'All episodes',
			'downloads.unwatchedOnly' => 'Unwatched only',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Next ${count} unwatched',
			'downloads.customAmount' => 'Custom amount...',
			'downloads.includeSpecials' => 'Include Specials',
			'downloads.howManyEpisodes' => 'How many episodes?',
			'downloads.invalidEpisodeCount' => 'Enter a valid episode count.',
			'downloads.keepSynced' => 'Keep synced',
			'downloads.downloadOnce' => 'Download once',
			'downloads.keepNUnwatched' => ({required Object count}) => 'Keep ${count} unwatched',
			'downloads.editSyncRule' => 'Edit sync rule',
			'downloads.removeSyncRule' => 'Remove sync rule',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'Stop syncing "${title}"? Downloaded episodes will be kept.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => 'Stop syncing "${title}"?',
			'downloads.deleteSyncRuleDownloads' => 'Also delete associated downloads',
			'downloads.deleteSyncRuleDownloadsDescription' => 'Downloads used by another sync rule or profile will be kept.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Sync rule created — keeping ${count} unwatched episodes',
			'downloads.syncRuleUpdated' => 'Sync rule updated',
			'downloads.syncRuleRemoved' => 'Sync rule removed',
			'downloads.syncRuleAndDownloadsRemoved' => 'Sync rule and associated downloads removed',
			'downloads.syncRuleCleanupBusy' => 'Sync rules are currently updating. Try again in a moment.',
			'downloads.syncRuleCleanupUnavailable' => 'Associated downloads could not be identified safely. Reconnect the server and try again, or remove the rule without deleting downloads.',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => 'Synced ${count} new episodes for ${title}',
			'downloads.activeSyncRules' => 'Sync rules',
			'downloads.noSyncRules' => 'No sync rules',
			'downloads.manageSyncRule' => 'Manage sync',
			'downloads.editEpisodeCount' => 'Episode count',
			'downloads.editSyncFilter' => 'Sync filter',
			'downloads.syncAllItems' => 'Syncing all items',
			'downloads.syncUnwatchedItems' => 'Syncing unwatched items',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Server: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Available',
			'downloads.syncRuleOffline' => 'Offline',
			'downloads.syncRuleSignInRequired' => 'Sign in required',
			'downloads.syncRuleNotAvailableForProfile' => 'Not available for current profile',
			'downloads.syncRuleUnknownServer' => 'Unknown server',
			'downloads.syncRuleListCreated' => 'Sync rule created',
			'downloads.backgroundWarning.bannerBlocked' => 'Downloads will stop when you leave the app',
			'downloads.backgroundWarning.bannerDegraded' => 'Background downloads may be limited',
			'downloads.backgroundWarning.bannerAction' => 'Details',
			'downloads.backgroundWarning.sheetTitle' => 'Background downloads are blocked',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Background downloads may be limited',
			'downloads.backgroundWarning.sheetIntro' => 'Android is preventing Plezy from downloading reliably in the background.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Your device is limiting when Plezy can download in the background.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'Plezy\'s background usage is restricted. Set its battery or background usage to "Unrestricted".',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android has put Plezy in a restricted standby state. Set its battery usage to "Unrestricted".',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Download notifications are turned off, so progress and controls may be unavailable.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Notifications are turned off. On Android 13 or newer, they are required for long background downloads.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Data Saver is on, which blocks background downloads on mobile data. Downloads should still run on Wi-Fi.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Downloads repeatedly stopped while Plezy was in the background. Check Plezy\'s battery or background usage settings.',
			'downloads.backgroundWarning.openSettings' => 'Open settings',
			'downloads.backgroundWarning.stillNotWorking' => 'Device-specific help',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'See steps for your device, or send a log from Settings › View Logs if the issue continues.',
			'downloads.backgroundWarning.dialogTitle' => 'Downloads may not finish',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'Download anyway',
			'downloads.backgroundWarning.dialogFixFirst' => 'Fix this first',
			'downloads.backgroundWarning.statusTile' => 'Background downloads',
			'downloads.backgroundWarning.statusOk' => 'Allowed to run in the background',
			'downloads.backgroundWarning.statusBlocked' => 'Blocked by system settings',
			'downloads.backgroundWarning.statusDegraded' => 'Limited by system settings',
			'downloads.backgroundWarning.statusUnknown' => 'Not checked yet',
			'downloads.backgroundWarning.settingsUnavailable' => 'Couldn\'t open system settings on this device',
			'downloads.backgroundWarning.linkUnavailable' => 'Couldn\'t open dontkillmyapp.com on this device',
			'downloads.unknownShow' => 'Unknown Show',
			'downloads.unknownSeason' => 'Unknown Season',
			'downloads.unknownAlbum' => 'Unknown Album',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} completed',
			'downloads.errorFileNotFound' => 'File not found (404)',
			'downloads.errorDownloadFailed' => 'Download failed',
			'downloads.errorPostProcessing' => ({required Object error}) => 'Post-processing failed: ${error}',
			'downloads.notificationDownloading' => 'Downloading...',
			'downloads.notificationComplete' => 'Download complete',
			'downloads.notificationPaused' => 'Download paused',
			'shaders.title' => 'Shaders',
			'shaders.noShaderDescription' => 'No video enhancement',
			'shaders.nvscalerDescription' => 'NVIDIA image scaling for sharper video',
			'shaders.artcnnVariantNeutral' => 'Neutral',
			'shaders.artcnnVariantDenoise' => 'Denoise',
			'shaders.artcnnVariantDenoiseSharpen' => 'Denoise + Sharpen',
			'shaders.qualityFast' => 'Fast',
			'shaders.qualityHQ' => 'High Quality',
			'shaders.mode' => 'Mode',
			'shaders.importShader' => 'Import Shader',
			'shaders.customShaderDescription' => 'Custom GLSL shader',
			'shaders.shaderImported' => 'Shader imported',
			'shaders.shaderImportFailed' => 'Failed to import shader',
			'shaders.deleteShader' => 'Delete Shader',
			'shaders.deleteShaderConfirm' => ({required Object name}) => 'Delete "${name}"?',
			'companionRemote.title' => 'Companion Remote',
			'companionRemote.connectedTo' => ({required Object name}) => 'Connected to ${name}',
			'companionRemote.unknownDevice' => 'Unknown Device',
			'companionRemote.session.startingServer' => 'Starting remote server...',
			'companionRemote.session.hostAddress' => 'Host Address',
			'companionRemote.session.connected' => 'Connected',
			'companionRemote.session.serverRunning' => 'Remote server active',
			'companionRemote.session.serverStopped' => 'Remote server stopped',
			'companionRemote.session.serverRunningDescription' => 'Mobile devices on your network can connect to this app',
			'companionRemote.session.serverStoppedDescription' => 'Start the server to allow mobile devices to connect',
			'companionRemote.session.usePhoneToControl' => 'Use your mobile device to control this app',
			'companionRemote.session.startServer' => 'Start Server',
			'companionRemote.session.stopServer' => 'Stop Server',
			'companionRemote.session.minimize' => 'Minimize',
			'companionRemote.session.manualAddressHint' => 'Manual connection address:',
			'companionRemote.pairing.discoveryDescription' => 'Plezy devices with the same Plex account appear here',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Connecting...',
			'companionRemote.pairing.searchingForDevices' => 'Looking for devices...',
			'companionRemote.pairing.noDevicesFound' => 'No devices found on your network',
			'companionRemote.pairing.noDevicesHint' => 'Open Plezy on desktop and use the same Wi-Fi',
			'companionRemote.pairing.availableDevices' => 'Available Devices',
			'companionRemote.pairing.manualConnection' => 'Manual Connection',
			'companionRemote.pairing.cryptoInitFailed' => 'Couldn\'t start secure connection. Sign in to Plex first.',
			'companionRemote.pairing.validationHostRequired' => 'Please enter host address',
			'companionRemote.pairing.validationHostFormat' => 'Format must be IP:port (e.g., 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Connection timed out. Use the same network on both devices.',
			'companionRemote.pairing.sessionNotFound' => 'Device not found. Make sure Plezy is running on the host.',
			'companionRemote.pairing.authFailed' => 'Authentication failed. Both devices need the same Plex account.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Failed to connect: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'Do you want to disconnect from the remote session?',
			'companionRemote.remote.reconnecting' => 'Reconnecting...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Attempt ${current} of 5',
			'companionRemote.remote.retryNow' => 'Retry Now',
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
			'companionRemote.errors.noNetworkInterface' => 'No network interface found',
			'companionRemote.errors.authenticationFailed' => 'Authentication failed',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'Failed to start remote server: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'Failed to send remote command: ${error}',
			'companionRemote.errors.joinTimedOut' => 'Timed out joining session',
			'companionRemote.errors.failedToConnectAnyAddress' => 'Failed to connect to any address',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'Connection lost after ${attempts} attempts',
			'companionRemote.errors.connectionLost' => 'Connection lost',
			'companionRemote.closedBeforeAuth' => 'The connection closed before authentication',
			'videoSettings.playbackSpeed' => 'Playback Speed',
			'videoSettings.normalSpeed' => 'Normal',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Active (${duration})',
			'videoSettings.zoom' => 'Zoom',
			'videoSettings.sleepTimer' => 'Sleep Timer',
			'videoSettings.audioSync' => 'Audio Sync',
			'videoSettings.subtitleSync' => 'Subtitle Sync',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'HDR isn\'t available here — this desktop compositor or video output can\'t carry it.',
			'videoSettings.hdrToneMapping' => 'HDR Tone Mapping',
			'videoSettings.hdrToneMappingCompositor' => 'Compositor',
			'videoSettings.hdrToneMappingCompositorDescription' => 'Pass the source\'s HDR metadata through and let the desktop compositor map it.',
			'videoSettings.hdrToneMappingPlayer' => 'Player',
			'videoSettings.hdrToneMappingPlayerDescription' => 'Map to the display\'s peak brightness in the player, then tell the compositor the result.',
			'videoSettings.hdrToneMappingFailed' => 'Couldn\'t change HDR tone mapping — the previous mode is still active.',
			'videoSettings.audioOutput' => 'Audio Output',
			'videoSettings.performanceOverlay' => 'Performance Overlay',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'Surround',
			'videoSettings.audioOutputSpatial' => 'Spatial Audio',
			'videoSettings.audioOutputStereo' => 'Stereo',
			'videoSettings.audioNormalization' => 'Normalize Loudness',
			'videoSettings.audioDownmix' => 'Downmix to Stereo',
			'performanceOverlay.color' => 'Color',
			'performanceOverlay.performance' => 'Performance',
			'performanceOverlay.buffer' => 'Buffer',
			'performanceOverlay.app' => 'App',
			'performanceOverlay.decoder' => 'Decoder',
			'performanceOverlay.rawDecoder' => 'Raw Decoder',
			'performanceOverlay.tunneling' => 'Tunneling',
			'performanceOverlay.passthrough' => 'Passthrough',
			'performanceOverlay.aspect' => 'Aspect',
			'performanceOverlay.rotation' => 'Rotation',
			'performanceOverlay.dvSource' => 'DV Source',
			'performanceOverlay.dvPath' => 'DV Path',
			'performanceOverlay.p7Conversion' => 'P7 Conv',
			'performanceOverlay.sampleRate' => 'Sample Rate',
			'performanceOverlay.pixelFormat' => 'Pixel Fmt',
			'performanceOverlay.hwFormat' => 'HW Fmt',
			'performanceOverlay.matrix' => 'Matrix',
			'performanceOverlay.primaries' => 'Primaries',
			'performanceOverlay.transfer' => 'Transfer',
			'performanceOverlay.renderFps' => 'Render FPS',
			'performanceOverlay.displayFps' => 'Display FPS',
			'performanceOverlay.avSync' => 'A/V Sync',
			'performanceOverlay.dropped' => 'Dropped',
			'performanceOverlay.dvRpus' => 'DV RPUs',
			'performanceOverlay.dvRpuAverage' => 'DV RPU Avg',
			'performanceOverlay.dvSampleAverage' => 'DV Sample Avg',
			'performanceOverlay.maxLuma' => 'Max Luma',
			'performanceOverlay.minLuma' => 'Min Luma',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Cache Used',
			'performanceOverlay.cacheLimit' => 'Cache Limit',
			'performanceOverlay.speed' => 'Speed',
			'performanceOverlay.player' => 'Player',
			'performanceOverlay.memory' => 'Memory',
			'performanceOverlay.uiFps' => 'UI FPS',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android HW',
			'performanceOverlay.decoderNvidiaHw' => 'NVIDIA HW',
			'performanceOverlay.decoderQualcommHw' => 'Qualcomm HW',
			'performanceOverlay.decoderMediatekHw' => 'MediaTek HW',
			'performanceOverlay.decoderExynosHw' => 'Exynos HW',
			'performanceOverlay.decoderSoftware' => 'Software',
			'performanceOverlay.decoderHardware' => 'Hardware',
			'performanceOverlay.tunnelingActive' => 'Active',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted} (${failures} failed)',
			'externalPlayer.title' => 'External Player',
			'externalPlayer.useExternalPlayer' => 'Use External Player',
			'externalPlayer.useExternalPlayerDescription' => 'Open videos in another app',
			'externalPlayer.selectPlayer' => 'Select Player',
			'externalPlayer.customPlayers' => 'Custom Players',
			'externalPlayer.systemDefault' => 'System Default',
			'externalPlayer.addCustomPlayer' => 'Add Custom Player',
			'externalPlayer.playerName' => 'Player Name',
			'externalPlayer.playerNameHint' => 'My Player',
			'externalPlayer.playerCommand' => 'Command',
			'externalPlayer.playerPackage' => 'Package Name',
			'externalPlayer.playerUrlScheme' => 'URL Scheme',
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
			'metadataEdit.logo' => 'Logo',
			'metadataEdit.squareArt' => 'Square Art',
			'metadataEdit.selectPoster' => 'Select Poster',
			'metadataEdit.selectBackground' => 'Select Background',
			'metadataEdit.selectLogo' => 'Select Logo',
			'metadataEdit.selectSquareArt' => 'Select Square Art',
			'metadataEdit.fromUrl' => 'From URL',
			'metadataEdit.uploadFile' => 'Upload File',
			'metadataEdit.enterImageUrl' => 'Enter image URL',
			'metadataEdit.imageUrl' => 'Image URL',
			'metadataEdit.metadataUpdated' => 'Metadata updated',
			'metadataEdit.metadataUpdateFailed' => 'Failed to update metadata',
			'metadataEdit.artworkUpdated' => 'Artwork updated',
			'metadataEdit.artworkUpdateFailed' => 'Failed to update artwork',
			'metadataEdit.noArtworkAvailable' => 'No artwork available',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Artwork option ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Artwork option ${index}, selected',
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
			'metadataEdit.tags' => 'Tags',
			'metadataEdit.addTag' => 'Add tag',
			'metadataEdit.genre' => 'Genre',
			'metadataEdit.director' => 'Director',
			'metadataEdit.writer' => 'Writer',
			'metadataEdit.producer' => 'Producer',
			'metadataEdit.country' => 'Country',
			'metadataEdit.collection' => 'Collection',
			'metadataEdit.label' => 'Label',
			'matchScreen.match' => 'Match...',
			'matchScreen.fixMatch' => 'Fix Match...',
			'matchScreen.unmatch' => 'Unmatch',
			'matchScreen.unmatchConfirm' => 'Clear this match? Plex treats it as unmatched until rematched.',
			'matchScreen.unmatchSuccess' => 'Item unmatched',
			'matchScreen.unmatchFailed' => 'Failed to unmatch item',
			'matchScreen.matchApplied' => 'Match applied',
			'matchScreen.matchFailed' => 'Failed to apply match',
			'matchScreen.titleHint' => 'Title',
			'matchScreen.yearHint' => 'Year',
			'matchScreen.search' => 'Search',
			'matchScreen.noMatchesFound' => 'No matches found',
			'serverTasks.title' => 'Server Tasks',
			'serverTasks.failedToLoad' => 'Failed to load tasks',
			'serverTasks.noTasks' => 'No tasks running',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Connected',
			'trakt.connectedAs' => ({required Object username}) => 'Connected as @${username}',
			'trakt.disconnectConfirm' => 'Disconnect Trakt account?',
			'trakt.disconnectConfirmBody' => 'Plezy will stop sending events to Trakt. You can reconnect any time.',
			'trakt.scrobble' => 'Real-time scrobbling',
			'trakt.scrobbleDescription' => 'Send play, pause, and stop events to Trakt during playback.',
			'trakt.watchedSync' => 'Sync watched status',
			'trakt.watchedSyncDescription' => 'When you mark items as watched in Plezy, they are also marked as watched on Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Connect Seerr',
			'seerr.serverUrl' => 'Server URL',
			'seerr.serverUrlHelper' => 'The address of your Seerr instance',
			'seerr.checkServer' => 'Continue',
			'seerr.signInWithJellyfin' => 'Sign in with Jellyfin',
			'seerr.signInWithEmby' => 'Sign in with Emby',
			'seerr.signInWithLocal' => 'Use a local account',
			'seerr.email' => 'Email',
			'seerr.noSignInMethods' => 'This Seerr instance offers no sign-in method Plezy supports.',
			'seerr.instance' => 'Instance',
			'seerr.disconnectConfirm' => 'Disconnect Seerr?',
			'seerr.disconnectConfirmBody' => 'Plezy will forget this Seerr instance. Reconnect any time.',
			'seerr.request' => 'Request',
			'seerr.request4k' => 'Request in 4K',
			'seerr.seasons' => 'Seasons',
			'seerr.allSeasons' => 'All seasons',
			'seerr.advancedOptions' => 'Advanced',
			'seerr.destinationServer' => 'Destination server',
			'seerr.qualityProfile' => 'Quality profile',
			'seerr.rootFolder' => 'Root folder',
			'seerr.languageProfile' => 'Language profile',
			'seerr.tags' => 'Tags',
			'seerr.noTags' => 'No tags',
			'seerr.defaultOption' => ({required Object name}) => '${name} (Default)',
			'seerr.animeNote' => 'This series is an anime.',
			'seerr.requestSubmitted' => 'Request submitted',
			'seerr.requestFailed' => ({required Object error}) => 'Request failed: ${error}',
			'seerr.requestsLoadFailed' => 'Couldn\'t load request options',
			'seerr.nothingToRequest' => 'Everything is already available or requested.',
			'seerr.statusAvailable' => 'Available',
			'seerr.statusPartiallyAvailable' => 'Partially available',
			'seerr.statusRequested' => 'Requested',
			'seerr.statusProcessing' => 'Processing',
			'seerr.statusBlocklisted' => 'Blocklisted',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => 'Could not reach ${url}: ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => 'No Seerr instance at ${url} (HTTP ${status})',
			'seerr.behindAuthProxy' => 'An authenticating reverse proxy (SSO or HTTP auth) answered instead of Seerr. Plezy cannot sign in through it: let Seerr\'s /api/v1 path bypass the proxy for this app, or use an address that reaches Seerr directly.',
			'seerr.invalidUrl' => 'Enter a server address like https://seerr.example.com',
			'seerr.quickConnectUnsupported' => 'This Seerr instance does not support Quick Connect. It needs Seerr 3.4 or newer.',
			'seerr.notInitialized' => 'This Seerr instance has not completed first-run setup',
			'seerr.noPlexTokenForReauth' => 'No Plex token is available to sign in again',
			'seerr.noStoredCredentials' => 'No stored credentials are available to sign in again',
			'seerr.signInRejected' => 'Sign-in was rejected',
			'seerr.noSessionCookie' => 'Seerr did not issue a session cookie',
			'seerr.freshCookieRejected' => 'Seerr rejected the new session cookie',
			'seerr.noUserInformation' => 'Seerr did not return user information',
			'seerr.sessionRejectedAfterReauth' => 'The session was rejected after signing in again',
			'seerr.permissionDenied' => 'Seerr denied this action: your account no longer has the required permission',
			'seerr.permissionRevoked' => 'You no longer have permission to request this',
			'services.title' => 'Services',
			'services.hubSubtitle' => 'Sync watch progress and request new titles.',
			'services.integrations' => 'Integrations',
			'services.notConnected' => 'Not connected',
			'services.connectedAs' => ({required Object username}) => 'Connected as @${username}',
			'services.scrobble' => 'Track progress automatically',
			'services.scrobbleDescription' => 'Update your list when you finish an episode or movie.',
			'services.disconnectConfirm' => ({required Object service}) => 'Disconnect ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'Plezy will stop updating ${service}. Reconnect any time.',
			'services.connectFailed' => ({required Object service}) => 'Couldn\'t connect to ${service}. Try again.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.deviceCode.title' => ({required Object service}) => 'Activate Plezy on ${service}',
			'services.deviceCode.instructions' => 'Scan the QR code, or visit the address below and enter this code:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Open ${service} to activate',
			'services.deviceCode.copyCode' => 'Copy activation code',
			'services.deviceCode.waitingForAuthorization' => 'Waiting for authorization…',
			'services.deviceCode.codeCopied' => 'Code copied',
			'services.oauthProxy.title' => ({required Object service}) => 'Sign in to ${service}',
			'services.oauthProxy.body' => 'Scan this QR code or open the URL on any device.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Open ${service} to sign in',
			'services.pendingAuth.copyUrl' => 'Copy sign-in URL',
			'services.pendingAuth.urlCopied' => 'URL copied',
			'services.libraryFilter.title' => 'Library filter',
			'services.libraryFilter.subtitleAllSyncing' => 'Syncing all libraries',
			'services.libraryFilter.subtitleNoneSyncing' => 'Nothing syncing',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} blocked',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} allowed',
			'services.libraryFilter.mode' => 'Filter mode',
			'services.libraryFilter.modeBlacklist' => 'Blacklist',
			'services.libraryFilter.modeWhitelist' => 'Whitelist',
			'services.libraryFilter.modeHintBlacklist' => 'Sync every library except the ones checked below.',
			'services.libraryFilter.modeHintWhitelist' => 'Sync only the libraries checked below.',
			'services.libraryFilter.libraries' => 'Libraries',
			'services.libraryFilter.noLibraries' => 'No libraries available',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => 'Add ${product} server',
			'addServer.serverUrls' => 'Server URLs',
			'addServer.serverUrlsHelper' => 'Multiple URLs allowed, separated by commas.',
			'addServer.findServer' => 'Find server',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'Looking for local ${product} servers...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'Local ${product} servers',
			'addServer.username' => 'Username',
			'addServer.password' => 'Password',
			'addServer.signIn' => 'Sign in',
			'addServer.change' => 'Change',
			'addServer.required' => 'Required',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Could not reach the server: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Sign-in failed: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect failed: ${error}',
			'addServer.addPlexTitle' => 'Sign in with Plex',
			'addServer.pinExpired' => 'PIN expired before sign-in. Please try again.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Failed to register account: ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => 'Enter your ${product} server URL',
			'addServer.addConnectionTitle' => 'Add connection',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Add to ${name}',
			'addServer.signInWithPlexCard' => 'Sign in with Plex',
			'addServer.signInWithPlexCardSubtitle' => 'Authorize this device. Shared servers are added.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Authorize a Plex account. Home users become profiles.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => 'Connect to ${product}',
			'addServer.connectToMediaBrowserCardSubtitle' => 'Enter your server URL, username, and password.',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => 'Sign in to your ${product} server. Binds to ${name}.',
			'addServer.borrowFromAnotherProfile' => 'Borrow from another profile',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Reuse another profile\'s connection. PIN-protected profiles require a PIN.',
			'addServer.invalidCredentials' => 'Invalid username or password',
			'addServer.authResponseNotJson' => 'The authentication response was not valid JSON',
			'addServer.authResponseIncomplete' => 'The sign-in response from the server was incomplete',
			'addServer.quickConnectRejected' => 'Quick Connect was rejected by the server',
			'addServer.quickConnectNotJson' => 'The Quick Connect response was not valid JSON',
			'addServer.quickConnectMissingFields' => 'The Quick Connect response is missing a code or secret',
			'addServer.quickConnectPollRejected' => 'Quick Connect polling was rejected by the server',
			'addServer.serverTimedOut' => 'The server did not respond in time',
			'addServer.responseNotJson' => 'The server response was not valid JSON',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'The response is missing an ID or server name — is this a ${product} server?',
			'addServer.probeFailed' => ({required Object error}) => 'Could not reach the server: ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => 'Enter at least one ${product} server URL',
			'addServer.noReachableServer' => ({required Object product}) => 'No reachable ${product} server was found',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'These URLs point to different ${product} servers',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'This URL does not match the ${product} server',
			'addServer.redirectUnsupported' => 'The server redirected to an unsupported URL',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'The server redirected to a different host. Enter the final ${product} URL directly.',
			'addServer.redirectInsecure' => 'The server redirected from HTTPS to an insecure URL',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'The server redirected to an unsupported URL. Enter the final ${product} URL directly.',
			_ => null,
		};
	}
}
