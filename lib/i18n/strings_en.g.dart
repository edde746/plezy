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
	late final Translations$appIcon$en appIcon = Translations$appIcon$en.internal(_root);
	late final Translations$auth$en auth = Translations$auth$en.internal(_root);
	late final Translations$common$en common = Translations$common$en.internal(_root);
	late final Translations$screens$en screens = Translations$screens$en.internal(_root);
	late final Translations$update$en update = Translations$update$en.internal(_root);
	late final Translations$settings$en settings = Translations$settings$en.internal(_root);
	late final Translations$themeEditor$en themeEditor = Translations$themeEditor$en.internal(_root);
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
	late final Translations$cast$en cast = Translations$cast$en.internal(_root);
	late final Translations$automation$en automation = Translations$automation$en.internal(_root);
	late final Translations$notifications$en notifications = Translations$notifications$en.internal(_root);
	late final Translations$appAccess$en appAccess = Translations$appAccess$en.internal(_root);
	late final Translations$detail$en detail = Translations$detail$en.internal(_root);
	late final Translations$watchLink$en watchLink = Translations$watchLink$en.internal(_root);
	late final Translations$homeLayout$en homeLayout = Translations$homeLayout$en.internal(_root);
	late final Translations$platform$en platform = Translations$platform$en.internal(_root);
	late final Translations$universalMedia$en universalMedia = Translations$universalMedia$en.internal(_root);
	late final Translations$fileSources$en fileSources = Translations$fileSources$en.internal(_root);
	late final Translations$lending$en lending = Translations$lending$en.internal(_root);
	late final Translations$audiobook$en audiobook = Translations$audiobook$en.internal(_root);
	late final Translations$sourceSetup$en sourceSetup = Translations$sourceSetup$en.internal(_root);
	late final Translations$comics$en comics = Translations$comics$en.internal(_root);
	late final Translations$games$en games = Translations$games$en.internal(_root);
	late final Translations$deepLinks$en deepLinks = Translations$deepLinks$en.internal(_root);
	late final Translations$householdSetup$en householdSetup = Translations$householdSetup$en.internal(_root);
	late final Translations$issueReport$en issueReport = Translations$issueReport$en.internal(_root);
}

// Path: app
class Translations$app$en {
	Translations$app$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'PlezyNG'
	String get title => 'PlezyNG';
}

// Path: appIcon
class Translations$appIcon$en {
	Translations$appIcon$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'App icon'
	String get title => 'App icon';

	/// en: 'Default'
	String get defaultIcon => 'Default';

	/// en: 'Current icon'
	String get current => 'Current icon';

	/// en: 'Lifetime access required'
	String get locked => 'Lifetime access required';

	/// en: 'Start your 7-day trial or unlock PlezyNG for life to use alternate icons.'
	String get lockedHint => 'Start your 7-day trial or unlock PlezyNG for life to use alternate icons.';

	/// en: 'Couldn't change the app icon'
	String get changeFailed => 'Couldn\'t change the app icon';

	/// en: 'The new icon appears on your home screen once you leave PlezyNG.'
	String get launcherHint => 'The new icon appears on your home screen once you leave PlezyNG.';

	/// en: 'The new banner appears once you leave PlezyNG. Android TV can keep showing the old one until the TV restarts.'
	String get tvLauncherHint => 'The new banner appears once you leave PlezyNG. Android TV can keep showing the old one until the TV restarts.';

	late final Translations$appIcon$names$en names = Translations$appIcon$names$en.internal(_root);

	/// en: 'Choose the icon shown by your device launcher. The previews show how each option looks.'
	String get description => 'Choose the icon shown by your device launcher. The previews show how each option looks.';
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

	/// en: 'PlezyNG could not safely recover local sign-in and pending playback data. Please sign in again.'
	String get localDataRecoveryRequired => 'PlezyNG could not safely recover local sign-in and pending playback data. Please sign in again.';

	/// en: 'The Plex PIN check was rejected'
	String get pinCheckRejected => 'The Plex PIN check was rejected';

	/// en: 'Connect to local Plex server'
	String get connectToDirectPlex => 'Connect to local Plex server';
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

	/// en: 'Close mini player'
	String get closeMiniPlayer => 'Close mini player';

	/// en: 'Close window'
	String get closeWorkspaceWindow => 'Close window';

	/// en: 'Return to full view'
	String get returnToFullView => 'Return to full view';

	/// en: 'Manage media sessions'
	String get manageMediaSessions => 'Manage media sessions';

	/// en: 'Hide media sessions'
	String get hideMediaSessions => 'Hide media sessions';

	/// en: 'Media sessions'
	String get mediaSessions => 'Media sessions';

	/// en: 'Select to bring a session forward. Park hides its window but keeps it open. Return opens it in full view; close ends it.'
	String get mediaSessionsHint => 'Select to bring a session forward. Park hides its window but keeps it open. Return opens it in full view; close ends it.';

	/// en: 'In workspace'
	String get sessionInWorkspace => 'In workspace';

	/// en: 'Parked'
	String get sessionParked => 'Parked';

	/// en: 'Full screen'
	String get sessionFullscreen => 'Full screen';

	/// en: 'Swap with next window'
	String get switchToNextWindow => 'Swap with next window';

	/// en: 'Move window'
	String get moveWindow => 'Move window';

	/// en: 'Finish moving window'
	String get finishMovingWindow => 'Finish moving window';

	/// en: 'Long-press and drag the window to move it. This control also enables arrow-key movement.'
	String get moveWindowHint => 'Long-press and drag the window to move it. This control also enables arrow-key movement.';

	/// en: 'Drag to move · Arrow keys adjust · Enter saves · Escape cancels'
	String get movingWindowHelp => 'Drag to move · Arrow keys adjust · Enter saves · Escape cancels';

	/// en: 'Resize window'
	String get resizeWindow => 'Resize window';

	/// en: 'Drag this handle or use the arrow keys to resize the window.'
	String get resizeWindowHint => 'Drag this handle or use the arrow keys to resize the window.';

	/// en: 'Use the move control or long-press and drag to move. Use the resize handle to resize.'
	String get workspaceWindowHint => 'Use the move control or long-press and drag to move. Use the resize handle to resize.';

	/// en: 'Select this pane to focus it. Use its fullscreen control to expand.'
	String get workspacePaneHint => 'Select this pane to focus it. Use its fullscreen control to expand.';

	/// en: 'Session window: ${title}'
	String workspaceWindowLabel({required Object title}) => 'Session window: ${title}';

	/// en: 'Select to focus. Drag the title bar to move; use the fullscreen button to expand.'
	String get workspaceTitleHint => 'Select to focus. Drag the title bar to move; use the fullscreen button to expand.';

	/// en: 'Move to session tray'
	String get moveToSessionTray => 'Move to session tray';

	/// en: 'Keeps this session available without showing its window.'
	String get moveToSessionTrayHint => 'Keeps this session available without showing its window.';

	/// en: 'Closes this window and ends its session.'
	String get closeSessionHint => 'Closes this window and ends its session.';

	/// en: 'Switch to side-by-side layout'
	String get sideBySideLayout => 'Switch to side-by-side layout';

	/// en: 'Switch to floating windows'
	String get floatingWindows => 'Switch to floating windows';

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

	/// en: 'Compare'
	String get compare => 'Compare';

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

	/// en: 'Preview'
	String get preview => 'Preview';

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

	/// en: 'Support PlezyNG'
	String get supportDeveloper => 'Support PlezyNG';

	/// en: 'Donate to support development'
	String get supportDeveloperDescription => 'Donate to support development';

	/// en: 'PlezyNG lifetime access'
	String get lifetimeAccess => 'PlezyNG lifetime access';

	/// en: 'Language'
	String get language => 'Language';

	/// en: 'Theme'
	String get theme => 'Theme';

	/// en: 'Appearance'
	String get appearance => 'Appearance';

	/// en: 'Detail Page'
	String get detailPage => 'Detail Page';

	/// en: 'Play Theme Songs'
	String get themeSongsEnabled => 'Play Theme Songs';

	/// en: 'Play available theme songs while viewing media details.'
	String get themeSongsEnabledDescription => 'Play available theme songs while viewing media details.';

	/// en: 'Theme Song Volume'
	String get themeSongVolume => 'Theme Song Volume';

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

	/// en: 'Enter a value (${min}-${max})'
	String durationHint({required Object min, required Object max}) => 'Enter a value (${min}-${max})';

	/// en: 'System'
	String get systemTheme => 'System';

	/// en: 'Light'
	String get lightTheme => 'Light';

	/// en: 'Dark'
	String get darkTheme => 'Dark';

	/// en: 'OLED'
	String get oledTheme => 'OLED';

	/// en: 'Ember'
	String get emberTheme => 'Ember';

	/// en: 'Glacier'
	String get glacierTheme => 'Glacier';

	/// en: 'Forest'
	String get forestTheme => 'Forest';

	/// en: 'Plum'
	String get plumTheme => 'Plum';

	/// en: 'Paper'
	String get paperTheme => 'Paper';

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

	/// en: 'Show home backdrop artwork'
	String get showHomeBackdrop => 'Show home backdrop artwork';

	/// en: 'Show large artwork behind featured Home rows'
	String get showHomeBackdropDescription => 'Show large artwork behind featured Home rows';

	/// en: 'Content screensaver'
	String get contentScreensaverEnabled => 'Content screensaver';

	/// en: 'Show full-screen artwork after the app has been idle'
	String get contentScreensaverEnabledDescription => 'Show full-screen artwork after the app has been idle';

	/// en: 'Start screensaver after'
	String get contentScreensaverDelay => 'Start screensaver after';

	/// en: 'Screensaver libraries'
	String get contentScreensaverLibraries => 'Screensaver libraries';

	/// en: 'Choose which libraries provide screensaver artwork. If none are selected, artwork from all libraries is used.'
	String get contentScreensaverLibrariesDescription => 'Choose which libraries provide screensaver artwork. If none are selected, artwork from all libraries is used.';

	/// en: 'All libraries'
	String get contentScreensaverAllLibraries => 'All libraries';

	/// en: '${count} libraries selected'
	String contentScreensaverSelectedLibraries({required Object count}) => '${count} libraries selected';

	/// en: 'No connected media libraries are available.'
	String get contentScreensaverNoLibraries => 'No connected media libraries are available.';

	/// en: 'Press any button or tap to dismiss'
	String get contentScreensaverDismissHint => 'Press any button or tap to dismiss';

	/// en: 'New episode notifications'
	String get newEpisodeNotifications => 'New episode notifications';

	/// en: 'Alert when a new episode is added to a show you are caught up on. Checks while Plezy is open.'
	String get newEpisodeNotificationsDescription => 'Alert when a new episode is added to a show you are caught up on. Checks while Plezy is open.';

	/// en: 'Continue Watching row size'
	String get continueWatchingRowSize => 'Continue Watching row size';

	/// en: '${label} cards'
	String continueWatchingRowSizeValue({required Object label}) => '${label} cards';

	/// en: 'Compact'
	String get rowSizeCompact => 'Compact';

	/// en: 'Standard'
	String get rowSizeStandard => 'Standard';

	/// en: 'Large'
	String get rowSizeLarge => 'Large';

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

	/// en: 'Buffer Size'
	String get streamBufferSize => 'Buffer Size';

	/// en: '${size} MB'
	String streamBufferSizeValue({required Object size}) => '${size} MB';

	/// en: 'How much video to load ahead when direct playing. Transcodes stop at the server's own transcode buffer. 0 = Auto'
	String get streamBufferSizeDescription => 'How much video to load ahead when direct playing. Transcodes stop at the server\'s own transcode buffer. 0 = Auto';

	/// en: 'Replaces Playback Buffer when set, capped at half of the app's memory limit'
	String get streamBufferSizeExoNote => 'Replaces Playback Buffer when set, capped at half of the app\'s memory limit';

	/// en: 'Megabytes'
	String get streamBufferMegabytes => 'Megabytes';

	/// en: 'Default Quality'
	String get defaultQualityTitle => 'Default Quality';

	/// en: 'Default Quality on Cellular'
	String get cellularQualityTitle => 'Default Quality on Cellular';

	/// en: 'Remote Streaming Quality'
	String get remoteQualityTitle => 'Remote Streaming Quality';

	/// en: 'Same as default quality'
	String get remoteQualitySameAsDefault => 'Same as default quality';

	/// en: 'Same as Default Quality'
	String get cellularQualitySameAsDefault => 'Same as Default Quality';

	/// en: 'Play Smaller Videos at Original Quality'
	String get directPlayCoveredQuality => 'Play Smaller Videos at Original Quality';

	/// en: 'Direct play videos already within the quality limit instead of transcoding them'
	String get directPlayCoveredQualityDescription => 'Direct play videos already within the quality limit instead of transcoding them';

	/// en: 'Video Codecs'
	String get videoCodecs => 'Video Codecs';

	/// en: 'Unchecked codecs are transcoded by the server'
	String get videoCodecsDescription => 'Unchecked codecs are transcoded by the server';

	/// en: 'Always accepted'
	String get videoCodecsAlwaysAccepted => 'Always accepted';

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

	/// en: '(other) {${seconds: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} seconds} (one) {${seconds: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} second}'
	String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(seconds,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} seconds',
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} second',
	);

	/// en: 'Default Sleep Timer'
	String get defaultSleepTimer => 'Default Sleep Timer';

	/// en: '(other) {${minutes: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} minutes} (one) {${minutes: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} minute}'
	String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(minutes,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutes',
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minute',
	);

	/// en: 'Remember track selections per show/movie'
	String get rememberTrackSelections => 'Remember track selections per show/movie';

	/// en: 'Choose audio and subtitles before playback'
	String get chooseTracksBeforePlayback => 'Choose audio and subtitles before playback';

	/// en: 'Pick the source audio and subtitle tracks before each video starts.'
	String get chooseTracksBeforePlaybackDescription => 'Pick the source audio and subtitle tracks before each video starts.';

	/// en: 'Always show subtitles on this device'
	String get alwaysShowSubtitlesOnDevice => 'Always show subtitles on this device';

	/// en: 'When the server has no subtitle selected, choose a track locally. This never changes the server's preference.'
	String get alwaysShowSubtitlesOnDeviceDescription => 'When the server has no subtitle selected, choose a track locally. This never changes the server\'s preference.';

	/// en: 'Fetch missing preferred-language subtitles'
	String get autoDownloadPreferredSubtitle => 'Fetch missing preferred-language subtitles';

	/// en: 'Select an available subtitle in your preferred language locally. If none exists, ask the server to fetch one when supported. The selection stays on this device.'
	String get autoDownloadPreferredSubtitleDescription => 'Select an available subtitle in your preferred language locally. If none exists, ask the server to fetch one when supported. The selection stays on this device.';

	/// en: 'Store audio and subtitle choices by show or movie on this device'
	String get rememberTrackSelectionsDescription => 'Store audio and subtitle choices by show or movie on this device';

	/// en: 'Works locally with Plex, Jellyfin, and Emby; Plex and Jellyfin can also save selections on the server'
	String get rememberTrackSelectionsBackendRule => 'Works locally with Plex, Jellyfin, and Emby; Plex and Jellyfin can also save selections on the server';

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

	/// en: 'Public Open Watch Party relays unless you set your own'
	String get watchTogetherRelayDescription => 'Public Open Watch Party relays unless you set your own';

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

	/// en: 'This file isn't a valid PlezyNG settings export'
	String get importSettingsInvalidFile => 'This file isn\'t a valid PlezyNG settings export';

	/// en: 'Sign in before importing settings'
	String get importSettingsNoUser => 'Sign in before importing settings';

	/// en: 'Cloud Backup'
	String get cloudBackup => 'Cloud Backup';

	/// en: 'Back up portable settings to a WebDAV endpoint over HTTPS. Server connections and credentials stay on this device.'
	String get cloudBackupDescription => 'Back up portable settings to a WebDAV endpoint over HTTPS. Server connections and credentials stay on this device.';

	/// en: 'WebDAV JSON file URL'
	String get cloudBackupUrl => 'WebDAV JSON file URL';

	/// en: 'Username'
	String get cloudBackupUsername => 'Username';

	/// en: 'Password'
	String get cloudBackupPassword => 'Password';

	/// en: 'Cloud backup destination saved'
	String get cloudBackupSaved => 'Cloud backup destination saved';

	/// en: 'Back Up Now'
	String get cloudBackupNow => 'Back Up Now';

	/// en: 'Settings backup uploaded'
	String get cloudBackupComplete => 'Settings backup uploaded';

	/// en: 'Restore Backup'
	String get cloudBackupRestore => 'Restore Backup';

	/// en: 'This will replace matching portable settings on this device. Continue?'
	String get cloudBackupRestoreConfirm => 'This will replace matching portable settings on this device. Continue?';

	/// en: 'Settings restored from cloud backup'
	String get cloudBackupRestored => 'Settings restored from cloud backup';

	/// en: 'Shortcuts reset to defaults'
	String get shortcutsReset => 'Shortcuts reset to defaults';

	/// en: 'This will replace your custom shortcuts with the defaults. Continue?'
	String get resetShortcutsConfirm => 'This will replace your custom shortcuts with the defaults. Continue?';

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

	/// en: 'Must be between ${min} and ${max} ${unit}'
	String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Must be between ${min} and ${max} ${unit}';

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

	/// en: 'Shuffle Starts at Beginning'
	String get shuffleStartsFromBeginning => 'Shuffle Starts at Beginning';

	/// en: 'Start each episode at the beginning when shuffling instead of resuming'
	String get shuffleStartsFromBeginningDescription => 'Start each episode at the beginning when shuffling instead of resuming';

	/// en: 'Use server cinema intros'
	String get plexCinemaPreRoll => 'Use server cinema intros';

	/// en: 'Play configured Plex pre-rolls or Jellyfin and Emby intros before a movie starts.'
	String get plexCinemaPreRollDescription => 'Play configured Plex pre-rolls or Jellyfin and Emby intros before a movie starts.';

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

	/// en: 'Skip Ads'
	String get skipAdsMode => 'Skip Ads';

	/// en: 'Play detected ads normally without a skip button'
	String get skipAdsModeOffDescription => 'Play detected ads normally without a skip button';

	/// en: 'Show a skip button when Plex detects an ad'
	String get skipAdsModeButtonDescription => 'Show a skip button when Plex detects an ad';

	/// en: 'Skip detected ads automatically after the delay below'
	String get skipAdsModeAutoDescription => 'Skip detected ads automatically after the delay below';

	/// en: 'Music Playback'
	String get musicPlayback => 'Music Playback';

	/// en: 'Sweet Fades'
	String get musicSweetFades => 'Sweet Fades';

	/// en: 'Fade music at track edges when Plex has loudness data. Album playback stays unchanged.'
	String get musicSweetFadesDescription => 'Fade music at track edges when Plex has loudness data. Album playback stays unchanged.';

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

	/// en: 'Use TheIntroDB as an intro fallback'
	String get theIntroDbFallback => 'Use TheIntroDB as an intro fallback';

	/// en: 'Use community timings only when the server has no intro marker. Matches can vary by release.'
	String get theIntroDbFallbackDescription => 'Use community timings only when the server has no intro marker. Matches can vary by release.';

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

	/// en: 'Prerolls'
	String get prerolls => 'Prerolls';

	/// en: 'Play prerolls before movies'
	String get playPrerollsBeforeMovies => 'Play prerolls before movies';

	/// en: 'Plays a random clip from your selection below before each movie. Press back to skip.'
	String get playPrerollsBeforeMoviesDescription => 'Plays a random clip from your selection below before each movie. Press back to skip.';

	/// en: 'Preroll library'
	String get prerollLibrary => 'Preroll library';

	/// en: 'Not set'
	String get prerollLibraryNotSet => 'Not set';

	/// en: 'No libraries found on your servers.'
	String get prerollLibraryNoneFound => 'No libraries found on your servers.';

	/// en: 'Selected prerolls'
	String get prerollSelection => 'Selected prerolls';

	/// en: 'Pick a library first'
	String get prerollSelectionPickLibraryFirst => 'Pick a library first';

	/// en: 'No prerolls selected'
	String get prerollSelectionNoneSelected => 'No prerolls selected';

	/// en: '${count} selected'
	String prerollSelectionCount({required Object count}) => '${count} selected';

	/// en: 'Select prerolls'
	String get prerollItemPicker => 'Select prerolls';

	/// en: 'Couldn't load items from this library.'
	String get prerollItemPickerLoadFailed => 'Couldn\'t load items from this library.';

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

	/// en: 'Auto-download Continue Watching'
	String get autoDownloadContinueWatching => 'Auto-download Continue Watching';

	/// en: 'Keep items on your Continue Watching shelf downloaded, and remove them once they leave the shelf'
	String get autoDownloadContinueWatchingDescription => 'Keep items on your Continue Watching shelf downloaded, and remove them once they leave the shelf';

	/// en: 'Download quality'
	String get downloadQuality => 'Download quality';

	/// en: 'Plex prepares a converted copy in its download queue. Jellyfin and Emby transcode while the file downloads; interrupted transfers may need to restart.'
	String get downloadQualityDescription => 'Plex prepares a converted copy in its download queue. Jellyfin and Emby transcode while the file downloads; interrupted transfers may need to restart.';

	/// en: 'Choose quality for each download'
	String get askDownloadQualityEachTime => 'Choose quality for each download';

	/// en: 'Show the quality picker before queueing each video download'
	String get askDownloadQualityEachTimeDescription => 'Show the quality picker before queueing each video download';

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

	/// en: 'Couldn't start the companion server'
	String get companionRemoteServerStartFailed => 'Couldn\'t start the companion server';

	/// en: 'Couldn't stop the companion server'
	String get companionRemoteServerStopFailed => 'Couldn\'t stop the companion server';

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
	String get audioPassthroughDescriptionApple => 'Use Apple\'s native Dolby decoder for Dolby Digital Plus, including Atmos. DTS and TrueHD still play as multichannel PCM. Turn off if you have no sound.';

	/// en: 'Use Apple's native Dolby decoder for Dolby Digital Plus, including Atmos. On iOS, iPadOS and tvOS 26 or later, TrueHD Atmos and DTS:X play as spatial audio. Other DTS and TrueHD tracks play as multichannel PCM. Turn off if you have no sound.'
	String get audioPassthroughDescriptionAppleSpatial => 'Use Apple\'s native Dolby decoder for Dolby Digital Plus, including Atmos. On iOS, iPadOS and tvOS 26 or later, TrueHD Atmos and DTS:X play as spatial audio. Other DTS and TrueHD tracks play as multichannel PCM. Turn off if you have no sound.';

	/// en: 'Off while loudness normalization is on'
	String get audioPassthroughOverriddenByNormalization => 'Off while loudness normalization is on';

	/// en: 'Audio Channels'
	String get audioChannelLimit => 'Audio Channels';

	/// en: 'Mix decoded audio down for speakers, headphones, or HDMI setups that cannot play every channel'
	String get audioChannelLimitDescription => 'Mix decoded audio down for speakers, headphones, or HDMI setups that cannot play every channel';

	/// en: 'Original'
	String get audioChannelLimitOriginal => 'Original';

	/// en: 'Play every channel in the track'
	String get audioChannelLimitOriginalDescription => 'Play every channel in the track';

	/// en: 'Up to 5.1'
	String get audioChannelLimitSurround51 => 'Up to 5.1';

	/// en: 'Mix 7.1 down to 5.1 for TVs and receivers that only take 5.1 PCM. Passthrough is unaffected.'
	String get audioChannelLimitSurround51Description => 'Mix 7.1 down to 5.1 for TVs and receivers that only take 5.1 PCM. Passthrough is unaffected.';

	/// en: 'Stereo'
	String get audioChannelLimitStereo => 'Stereo';

	/// en: 'Mix down to two channels for stereo speakers or headphones. Turns passthrough off.'
	String get audioChannelLimitStereoDescription => 'Mix down to two channels for stereo speakers or headphones. Turns passthrough off.';

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

	/// en: 'Experimental Dolby Vision'
	String get experimentalDolbyVision => 'Experimental Dolby Vision';

	/// en: 'Use the experimental FEL renderer on the next playback. Requires a separate engine build.'
	String get experimentalDolbyVisionDescription => 'Use the experimental FEL renderer on the next playback. Requires a separate engine build.';

	/// en: 'This experiment is currently available on Linux only.'
	String get dvExperimentUnavailableDescription => 'This experiment is currently available on Linux only.';

	/// en: 'Compatibility fallback'
	String get dvCompatibilityFallback => 'Compatibility fallback';

	/// en: 'Use the standard renderer if the experiment cannot start. FEL data may be lost.'
	String get dvCompatibilityFallbackDescription => 'Use the standard renderer if the experiment cannot start. FEL data may be lost.';

	/// en: 'Video experiment logging'
	String get dvExperimentDiagnostics => 'Video experiment logging';

	/// en: 'Enable detailed player logs on the next playback.'
	String get dvExperimentDiagnosticsDescription => 'Enable detailed player logs on the next playback.';

	/// en: 'Disable Dolby Vision'
	String get disableDolbyVision => 'Disable Dolby Vision';

	/// en: 'Play the file's HDR10 or HLG layer instead of Dolby Vision, when it has one'
	String get disableDolbyVisionDescription => 'Play the file\'s HDR10 or HLG layer instead of Dolby Vision, when it has one';

	/// en: 'HDR to SDR Conversion'
	String get hdrSdrConversion => 'HDR to SDR Conversion';

	/// en: 'Choose what converts HDR video when the display can't show HDR.'
	String get hdrSdrConversionDescription => 'Choose what converts HDR video when the display can\'t show HDR.';

	/// en: 'Auto'
	String get hdrSdrConversionAuto => 'Auto';

	/// en: 'Device on Android 9 and later, player on older versions'
	String get hdrSdrConversionAutoDescription => 'Device on Android 9 and later, player on older versions';

	/// en: 'Device'
	String get hdrSdrConversionDevice => 'Device';

	/// en: 'Your device's video hardware converts it. Fastest, but colors depend on the device'
	String get hdrSdrConversionDeviceDescription => 'Your device\'s video hardware converts it. Fastest, but colors depend on the device';

	/// en: 'Player'
	String get hdrSdrConversionPlayer => 'Player';

	/// en: 'The player converts it. Consistent colors, but 4K may stutter on low-end TV boxes'
	String get hdrSdrConversionPlayerDescription => 'The player converts it. Consistent colors, but 4K may stutter on low-end TV boxes';

	/// en: 'Deinterlacing'
	String get deinterlace => 'Deinterlacing';

	/// en: 'Remove combing artifacts from interlaced video (mpv player only)'
	String get deinterlaceDescription => 'Remove combing artifacts from interlaced video (mpv player only)';

	/// en: 'Off'
	String get deinterlaceOff => 'Off';

	/// en: 'Show interlaced video as it is decoded'
	String get deinterlaceOffDescription => 'Show interlaced video as it is decoded';

	/// en: 'Video'
	String get deinterlaceVideo => 'Video';

	/// en: 'Turn each field into a full frame. For video shot for TV, like sports, news, and concerts'
	String get deinterlaceVideoDescription => 'Turn each field into a full frame. For video shot for TV, like sports, news, and concerts';

	/// en: 'Film'
	String get deinterlaceFilm => 'Film';

	/// en: 'Restore the original frames of film and animation telecined to 29.97 fps, common on NTSC DVDs. Video shot for TV stutters. Live TV uses Video'
	String get deinterlaceFilmDescription => 'Restore the original frames of film and animation telecined to 29.97 fps, common on NTSC DVDs. Video shot for TV stutters. Live TV uses Video';

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

	/// en: 'Open PlezyNG in fullscreen mode at launch'
	String get startInFullscreenDescription => 'Open PlezyNG in fullscreen mode at launch';

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

	/// en: 'Preferred Server'
	String get preferredServer => 'Preferred Server';

	/// en: 'Prioritize this server's results while keeping every connected server available.'
	String get preferredServerDescription => 'Prioritize this server\'s results while keeping every connected server available.';

	/// en: 'Automatic'
	String get preferredServerAutomatic => 'Automatic';

	/// en: 'Show Explore Tab'
	String get showExploreTab => 'Show Explore Tab';

	/// en: 'Display the Explore tab with content from Plex Discover and connected trackers'
	String get showExploreTabDescription => 'Display the Explore tab with content from Plex Discover and connected trackers';

	/// en: 'Hide empty libraries'
	String get hideEmptyLibraries => 'Hide empty libraries';

	/// en: 'Remove libraries with a server-reported item count of zero from navigation.'
	String get hideEmptyLibrariesDescription => 'Remove libraries with a server-reported item count of zero from navigation.';

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

	/// en: 'Seek Swipe'
	String get gestureSeekSwipe => 'Seek Swipe';

	/// en: 'Swipe left or right anywhere on the video to seek; release to jump'
	String get gestureSeekSwipeDescription => 'Swipe left or right anywhere on the video to seek; release to jump';

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

	/// en: 'Export PlezyNG settings'
	String get exportDialogTitle => 'Export PlezyNG settings';

	/// en: 'Follow system'
	String get followSystem => 'Follow system';

	/// en: 'Match interface language'
	String get followAppLanguage => 'Match interface language';

	/// en: 'Regional formats'
	String get regionFormat => 'Regional formats';

	/// en: 'Choose how dates, numbers and measurements appear.'
	String get regionFormatDescription => 'Choose how dates, numbers and measurements appear.';

	/// en: 'Metadata language'
	String get metadataLanguage => 'Metadata language';

	/// en: 'Preferred titles and descriptions where the server supports it. Audio and subtitle preferences stay separate.'
	String get metadataLanguageDescription => 'Preferred titles and descriptions where the server supports it. Audio and subtitle preferences stay separate.';

	/// en: 'Enter fullscreen when playback starts'
	String get enterFullscreenOnPlaybackStart => 'Enter fullscreen when playback starts';

	/// en: 'Open desktop video in fullscreen when playback starts'
	String get enterFullscreenOnPlaybackStartDescription => 'Open desktop video in fullscreen when playback starts';

	/// en: 'Extend video into display cutout'
	String get extendVideoIntoDisplayCutout => 'Extend video into display cutout';

	/// en: 'Let fullscreen video use the camera cutout on Android phones'
	String get extendVideoIntoDisplayCutoutDescription => 'Let fullscreen video use the camera cutout on Android phones';

	/// en: 'Choose the language used for PlezyNG controls and messages. Follow system tracks your device language.'
	String get languageDescription => 'Choose the language used for PlezyNG controls and messages. Follow system tracks your device language.';

	/// en: 'Choose the colors and contrast used throughout the app.'
	String get themeDescription => 'Choose the colors and contrast used throughout the app.';

	/// en: 'Change how many library cards fit in each row.'
	String get libraryDensityDescription => 'Change how many library cards fit in each row.';

	/// en: 'Resize the interface on this car display without changing your device-wide text size.'
	String get displayScaleDescription => 'Resize the interface on this car display without changing your device-wide text size.';

	/// en: 'Set the volume of theme songs relative to other audio.'
	String get themeSongVolumeDescription => 'Set the volume of theme songs relative to other audio.';

	/// en: 'Choose whether library items appear as posters in a grid or as a compact list.'
	String get viewModeDescription => 'Choose whether library items appear as posters in a grid or as a compact list.';

	/// en: 'Arrange library items in rows and columns of posters.'
	String get gridViewDescription => 'Arrange library items in rows and columns of posters.';

	/// en: 'Show library items in a vertical list with more text per item.'
	String get listViewDescription => 'Show library items in a vertical list with more text per item.';

	/// en: 'Set the gap between posters in library grids.'
	String get gridSpacingDescription => 'Set the gap between posters in library grids.';

	/// en: 'Fit more posters across the screen with smaller gaps.'
	String get gridSpacingTightDescription => 'Fit more posters across the screen with smaller gaps.';

	/// en: 'Use the standard gap between posters.'
	String get gridSpacingNormalDescription => 'Use the standard gap between posters.';

	/// en: 'Add larger gaps between posters for more separation.'
	String get gridSpacingSpaciousDescription => 'Add larger gaps between posters for more separation.';

	/// en: 'Choose which artwork appears on episode cards.'
	String get episodePosterModeDescription => 'Choose which artwork appears on episode cards.';

	/// en: 'Use the show’s series poster for every episode.'
	String get seriesPosterDescription => 'Use the show’s series poster for every episode.';

	/// en: 'Use the season poster for each episode when available.'
	String get seasonPosterDescription => 'Use the season poster for each episode when available.';

	/// en: 'Use a frame from the episode when available.'
	String get episodeThumbnailDescription => 'Use a frame from the episode when available.';

	/// en: 'Choose what happens when you activate a Continue Watching card.'
	String get continueWatchingActionDescription => 'Choose what happens when you activate a Continue Watching card.';

	/// en: 'Start the movie or episode immediately.'
	String get continueWatchingPlayDescription => 'Start the movie or episode immediately.';

	/// en: 'Open the title page first so you can review details and choose an action.'
	String get continueWatchingDetailsDescription => 'Open the title page first so you can review details and choose an action.';

	/// en: 'Choose what happens when you activate an episode card.'
	String get episodeActionDescription => 'Choose what happens when you activate an episode card.';

	/// en: 'Start the episode immediately.'
	String get episodePlayDescription => 'Start the episode immediately.';

	/// en: 'Open the episode page before playback.'
	String get episodeDetailsDescription => 'Open the episode page before playback.';

	/// en: 'Choose how long PlezyNG waits without input before showing artwork.'
	String get contentScreensaverDelayDescription => 'Choose how long PlezyNG waits without input before showing artwork.';

	/// en: 'Choose how large the cards are in the Continue Watching row.'
	String get continueWatchingRowSizeDescription => 'Choose how large the cards are in the Continue Watching row.';

	/// en: 'Show smaller cards so more items fit across the row.'
	String get rowSizeCompactDescription => 'Show smaller cards so more items fit across the row.';

	/// en: 'Use the standard card size.'
	String get rowSizeStandardDescription => 'Use the standard card size.';

	/// en: 'Show larger cards with more artwork detail.'
	String get rowSizeLargeDescription => 'Show larger cards with more artwork detail.';

	/// en: 'Choose the animation and artwork effects budget for this device.'
	String get visualEffectsDescription => 'Choose the animation and artwork effects budget for this device.';

	/// en: 'Use the full animation and artwork effects on every device.'
	String get visualEffectsFullDescription => 'Use the full animation and artwork effects on every device.';

	/// en: 'Choose which section opens when PlezyNG starts.'
	String get startupSectionDescription => 'Choose which section opens when PlezyNG starts.';

	late final Translations$settings$startupSectionOptions$en startupSectionOptions = Translations$settings$startupSectionOptions$en.internal(_root);

	/// en: 'Set the distance moved by the short backward and forward seek controls.'
	String get smallSkipDurationDescription => 'Set the distance moved by the short backward and forward seek controls.';

	/// en: 'Set the distance moved by the long backward and forward seek controls.'
	String get largeSkipDurationDescription => 'Set the distance moved by the long backward and forward seek controls.';

	/// en: 'Move playback back by this amount when resuming a video.'
	String get rewindOnResumeDescription => 'Move playback back by this amount when resuming a video.';

	/// en: 'Set the initial duration used when you start the sleep timer.'
	String get defaultSleepTimerDescription => 'Set the initial duration used when you start the sleep timer.';

	/// en: 'Wait this long before starting the next episode. Set to 0 to start immediately.'
	String get playNextCountdownDescription => 'Wait this long before starting the next episode. Set to 0 to start immediately.';

	/// en: 'Applies when an intro, credits, or ad is set to skip automatically.'
	String get autoSkipDelaySettingDescription => 'Applies when an intro, credits, or ad is set to skip automatically.';

	/// en: 'Raise dialogue in the center channel when surround audio is mixed down to stereo.'
	String get downmixCenterBoostDescription => 'Raise dialogue in the center channel when surround audio is mixed down to stereo.';

	/// en: 'Wait before changing display mode so the TV or receiver can finish its previous switch.'
	String get displaySwitchDelayDescription => 'Wait before changing display mode so the TV or receiver can finish its previous switch.';

	/// en: 'Choose which playback engine decodes and renders video on this device.'
	String get playerBackendDescription => 'Choose which playback engine decodes and renders video on this device.';

	/// en: 'Use Android’s native Media3-based player and supported hardware paths.'
	String get exoPlayerDescription => 'Use Android’s native Media3-based player and supported hardware paths.';

	/// en: 'Use mpv, which exposes additional playback, subtitle, and video processing controls.'
	String get mpvDescription => 'Use mpv, which exposes additional playback, subtitle, and video processing controls.';

	/// en: 'Keep changes for the current playback session only.'
	String get scopeOffDescription => 'Keep changes for the current playback session only.';

	/// en: 'Reuse the same value for every library and title.'
	String get scopeGlobalDescription => 'Reuse the same value for every library and title.';

	/// en: 'Remember a separate value for each library.'
	String get scopeLibraryDescription => 'Remember a separate value for each library.';

	/// en: 'Remember a separate value for each show or movie.'
	String get scopeTitleDescription => 'Remember a separate value for each show or movie.';

	/// en: 'Keep the episode order supplied by the media server.'
	String get specialsOrderingServerDescription => 'Keep the episode order supplied by the media server.';

	/// en: 'Place specials among regular episodes by their air date.'
	String get specialsOrderingAirDateDescription => 'Place specials among regular episodes by their air date.';

	/// en: 'Place every special after the regular seasons.'
	String get specialsOrderingLastDescription => 'Place every special after the regular seasons.';

	/// en: 'Choose whether intro markers play normally, show a skip button, or skip automatically.'
	String get skipIntroModeDescription => 'Choose whether intro markers play normally, show a skip button, or skip automatically.';

	/// en: 'Choose whether credits play normally, show a skip button, or skip automatically.'
	String get skipCreditsModeDescription => 'Choose whether credits play normally, show a skip button, or skip automatically.';

	/// en: 'Choose whether detected ads play normally, show a skip button, or skip automatically.'
	String get skipAdsModeDescription => 'Choose whether detected ads play normally, show a skip button, or skip automatically.';

	/// en: 'Let the active player choose its normal buffer size.'
	String get playbackBufferAutoDescription => 'Let the active player choose its normal buffer size.';

	/// en: 'Keep more media ready ahead of playback; this uses more memory.'
	String get playbackBufferLargeDescription => 'Keep more media ready ahead of playback; this uses more memory.';

	/// en: 'Keep the largest read-ahead buffer; this uses the most memory.'
	String get playbackBufferExtraLargeDescription => 'Keep the largest read-ahead buffer; this uses the most memory.';

	/// en: 'Set the default video resolution and bitrate ceiling for streams that the server transcodes.'
	String get defaultQualityDescription => 'Set the default video resolution and bitrate ceiling for streams that the server transcodes.';

	/// en: 'Override Default Quality when the device is using a cellular-only connection.'
	String get cellularQualityDescription => 'Override Default Quality when the device is using a cellular-only connection.';

	/// en: 'Override Default Quality when connecting to a server over a remote connection.'
	String get remoteQualityDescription => 'Override Default Quality when connecting to a server over a remote connection.';

	/// en: 'Play the source at its available quality without asking the server to transcode it.'
	String get qualityPresetOriginalDescription => 'Play the source at its available quality without asking the server to transcode it.';

	/// en: 'Ask the server for a converted stream using the resolution and bitrate shown above.'
	String get qualityPresetTranscodeOptionDescription => 'Ask the server for a converted stream using the resolution and bitrate shown above.';

	/// en: 'Use the quality selected in Default Quality.'
	String get qualityPresetSameAsDefaultDescription => 'Use the quality selected in Default Quality.';

	/// en: 'Set the maximum audio bitrate requested from the server; Original keeps the source stream.'
	String get musicQualityDescription => 'Set the maximum audio bitrate requested from the server; Original keeps the source stream.';

	/// en: 'Play the source audio without a bitrate-capped transcode.'
	String get musicQualityOriginalDescription => 'Play the source audio without a bitrate-capped transcode.';

	/// en: 'Request a server transcode capped near the bitrate shown above; the actual output can vary.'
	String get musicQualityTranscodeOptionDescription => 'Request a server transcode capped near the bitrate shown above; the actual output can vary.';

	/// en: 'Maximum volume (%)'
	String get maxVolumeInputLabel => 'Maximum volume (%)';

	/// en: 'Check now whether a newer version of PlezyNG is available.'
	String get checkForUpdatesDescription => 'Check now whether a newer version of PlezyNG is available.';

	/// en: 'Choose the app theme and adjust library cards, Home rows, and navigation.'
	String get appearanceDescription => 'Choose the app theme and adjust library cards, Home rows, and navigation.';

	/// en: 'Choose the library that contains the clips available as movie pre-rolls.'
	String get prerollLibraryDescription => 'Choose the library that contains the clips available as movie pre-rolls.';

	/// en: 'Choose which clips from the selected library can play before movies.'
	String get prerollSelectionDescription => 'Choose which clips from the selected library can play before movies.';

	/// en: 'Wait this many minutes without input before showing screensaver artwork.'
	String get contentScreensaverDelayOptionDescription => 'Wait this many minutes without input before showing screensaver artwork.';

	/// en: 'Allow direct playback for this codec when supported. Unchecked codecs are transcoded by the media server.'
	String get videoCodecOptionDescription => 'Allow direct playback for this codec when supported. Unchecked codecs are transcoded by the media server.';
}

// Path: themeEditor
class Translations$themeEditor$en {
	Translations$themeEditor$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Built-in'
	String get builtIn => 'Built-in';

	/// en: 'Presets'
	String get presets => 'Presets';

	/// en: 'Custom'
	String get custom => 'Custom';

	/// en: 'Not created yet'
	String get customEmpty => 'Not created yet';

	/// en: 'Edit custom theme'
	String get editCustom => 'Edit custom theme';

	/// en: 'Choose every color yourself'
	String get editCustomDescription => 'Choose every color yourself';

	/// en: 'Lifetime access required'
	String get locked => 'Lifetime access required';

	/// en: 'Saved — available with lifetime access'
	String get savedLocked => 'Saved — available with lifetime access';

	/// en: 'Custom Theme'
	String get title => 'Custom Theme';

	/// en: 'Start from'
	String get startFrom => 'Start from';

	/// en: 'Copy all colors from another theme'
	String get startFromDescription => 'Copy all colors from another theme';

	/// en: 'Colors'
	String get colors => 'Colors';

	/// en: 'Preview'
	String get preview => 'Preview';

	late final Translations$themeEditor$slots$en slots = Translations$themeEditor$slots$en.internal(_root);

	/// en: 'Opacity'
	String get opacity => 'Opacity';

	/// en: '#RRGGBB or #AARRGGBB'
	String get hexHint => '#RRGGBB or #AARRGGBB';

	/// en: 'From other themes'
	String get fromOtherThemes => 'From other themes';

	/// en: '${theme} ${color}'
	String swatchLabel({required Object theme, required Object color}) => '${theme} ${color}';

	late final Translations$themeEditor$contrast$en contrast = Translations$themeEditor$contrast$en.internal(_root);

	/// en: '${pair}: ${ratio}:1, below the recommended ${minimum}:1'
	String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, below the recommended ${minimum}:1';

	/// en: 'Discard changes?'
	String get discardTitle => 'Discard changes?';

	/// en: 'Your unsaved color changes will be lost.'
	String get discardMessage => 'Your unsaved color changes will be lost.';

	/// en: 'Discard'
	String get discard => 'Discard';

	/// en: 'Episode ${number}'
	String previewCardTitle({required Object number}) => 'Episode ${number}';

	/// en: '${minutes} min left'
	String previewCardSubtitle({required Object minutes}) => '${minutes} min left';

	/// en: 'Autoplay'
	String get previewSwitch => 'Autoplay';

	/// en: 'Secondary text reads like this'
	String get previewMutedText => 'Secondary text reads like this';

	/// en: 'Follow your device appearance and switch between light and dark automatically.'
	String get themeSystemDescription => 'Follow your device appearance and switch between light and dark automatically.';

	/// en: 'Use a bright background with dark text.'
	String get themeLightDescription => 'Use a bright background with dark text.';

	/// en: 'Use a dark background with light text.'
	String get themeDarkDescription => 'Use a dark background with light text.';

	/// en: 'Use near-black surfaces that reduce light on OLED screens.'
	String get themeOledDescription => 'Use near-black surfaces that reduce light on OLED screens.';

	/// en: 'Use warm red and amber accent colors.'
	String get themeEmberDescription => 'Use warm red and amber accent colors.';

	/// en: 'Use cool blue accent colors.'
	String get themeGlacierDescription => 'Use cool blue accent colors.';

	/// en: 'Use muted green and natural accent colors.'
	String get themeForestDescription => 'Use muted green and natural accent colors.';

	/// en: 'Use violet and plum accent colors.'
	String get themePlumDescription => 'Use violet and plum accent colors.';

	/// en: 'Use warm paper-like surfaces and ink-inspired colors.'
	String get themePaperDescription => 'Use warm paper-like surfaces and ink-inspired colors.';

	/// en: 'Use the color palette you created in the custom theme editor.'
	String get themeCustomDescription => 'Use the color palette you created in the custom theme editor.';

	/// en: 'Choose a palette color, adjust its hue, saturation, brightness, or opacity, and see the preview update before saving. You can also enter a hex color.'
	String get editorDescription => 'Choose a palette color, adjust its hue, saturation, brightness, or opacity, and see the preview update before saving. You can also enter a hex color.';
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

	/// en: 'People'
	String get people => 'People';
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

	/// en: '(one) {This deletes the ${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} episode it contains and its file.} (other) {This deletes all ${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} episodes in it, and their files.}'
	String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'This deletes the ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episode it contains and its file.',
		other: 'This deletes all ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodes in it, and their files.',
	);

	/// en: '(one) {This item is stored as ${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} file, which will be deleted.} (other) {This item is stored across ${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} files, and all of them will be deleted.}'
	String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'This item is stored as ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} file, which will be deleted.',
		other: 'This item is stored across ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} files, and all of them will be deleted.',
	);

	/// en: '(one) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} other episode is stored in the same file and will be deleted too:} (other) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} other episodes are stored in the same file and will be deleted too:}'
	String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} other episode is stored in the same file and will be deleted too:',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} other episodes are stored in the same file and will be deleted too:',
	);

	/// en: 'PlezyNG could not check which files this will remove, so it may delete more than the item named above. Cancel and try again, or delete anyway.'
	String get deleteScopeUnverifiedProbeFailed => 'PlezyNG could not check which files this will remove, so it may delete more than the item named above. Cancel and try again, or delete anyway.';

	/// en: 'Your server did not provide file details for this item, so PlezyNG cannot check which files this will remove. It may delete more than the item named above.'
	String get deleteScopeUnverifiedNoFileInfo => 'Your server did not provide file details for this item, so PlezyNG cannot check which files this will remove. It may delete more than the item named above.';

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

	/// en: 'Red'
	String get red => 'Red';

	/// en: 'Green'
	String get green => 'Green';

	/// en: 'Blue'
	String get blue => 'Blue';

	/// en: 'R'
	String get redShort => 'R';

	/// en: 'G'
	String get greenShort => 'G';

	/// en: 'B'
	String get blueShort => 'B';

	/// en: 'HSV'
	String get colorModeHsv => 'HSV';

	/// en: 'RGB'
	String get colorModeRgb => 'RGB';

	/// en: 'Accessibility'
	String get title => 'Accessibility';

	/// en: 'Text, contrast, motion and controls'
	String get summary => 'Text, contrast, motion and controls';

	/// en: 'Your device’s accessibility settings always apply. These options add adjustments throughout PlezyNG.'
	String get systemHint => 'Your device’s accessibility settings always apply. These options add adjustments throughout PlezyNG.';

	/// en: 'Reading and visibility'
	String get readability => 'Reading and visibility';

	/// en: 'Additional text size'
	String get textSize => 'Additional text size';

	/// en: 'Find your next story. Read, listen and watch at your own pace.'
	String get preview => 'Find your next story. Read, listen and watch at your own pace.';

	/// en: 'Bold interface text'
	String get boldText => 'Bold interface text';

	/// en: 'High contrast'
	String get highContrast => 'High contrast';

	/// en: 'Stronger text, outlines and focus indicators on light or dark surfaces.'
	String get highContrastHint => 'Stronger text, outlines and focus indicators on light or dark surfaces.';

	/// en: 'Motion and interaction'
	String get interaction => 'Motion and interaction';

	/// en: 'Reduce motion'
	String get reduceMotion => 'Reduce motion';

	/// en: 'Keep focus, page transitions and decorative effects still.'
	String get reduceMotionHint => 'Keep focus, page transitions and decorative effects still.';

	/// en: 'Larger touch targets'
	String get largeTargets => 'Larger touch targets';

	/// en: 'Give shared controls more room for touch and assistive navigation.'
	String get largeTargetsHint => 'Give shared controls more room for touch and assistive navigation.';

	/// en: 'Use Tab and Shift+Tab to move between controls, Enter or Space to activate, and Escape or Back to close. Reader zoom and reading preferences are available while a book is open.'
	String get navigationHint => 'Use Tab and Shift+Tab to move between controls, Enter or Space to activate, and Escape or Back to close. Reader zoom and reading preferences are available while a book is open.';

	/// en: 'Scale interface text in PlezyNG in addition to your device’s system text-size setting.'
	String get textSizeDescription => 'Scale interface text in PlezyNG in addition to your device’s system text-size setting.';

	/// en: 'Use a heavier weight for interface labels and messages to make them easier to distinguish.'
	String get boldTextHint => 'Use a heavier weight for interface labels and messages to make them easier to distinguish.';
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

	/// en: 'Loop a section during this playback. Set A, then set B later in the timeline.'
	String get segmentLoopHelp => 'Loop a section during this playback. Set A, then set B later in the timeline.';

	/// en: 'Set loop start (A)'
	String get setLoopStart => 'Set loop start (A)';

	/// en: 'Set loop end (B)'
	String get setLoopEnd => 'Set loop end (B)';

	/// en: 'Clear segment loop'
	String get clearSegmentLoop => 'Clear segment loop';

	/// en: 'Set loop start (A) before the end (B).'
	String get setLoopStartFirst => 'Set loop start (A) before the end (B).';

	/// en: 'The loop end must be later than the start.'
	String get loopEndAfterStart => 'The loop end must be later than the start.';

	/// en: 'Segment looping isn't available for this playback.'
	String get segmentLoopUnavailable => 'Segment looping isn\'t available for this playback.';

	/// en: 'Not set'
	String get loopPointNotSet => 'Not set';

	/// en: 'Bookmarks are saved on this device. Select one to go to that time.'
	String get bookmarksHelp => 'Bookmarks are saved on this device. Select one to go to that time.';

	/// en: 'Bookmarks'
	String get bookmarksButton => 'Bookmarks';

	/// en: 'Chapters and bookmarks'
	String get chaptersAndBookmarks => 'Chapters and bookmarks';

	/// en: 'Segment loop'
	String get segmentLoop => 'Segment loop';

	/// en: 'Add bookmark'
	String get addBookmark => 'Add bookmark';

	/// en: 'Bookmark name'
	String get bookmarkName => 'Bookmark name';

	/// en: 'For example, Opening scene'
	String get bookmarkNameHint => 'For example, Opening scene';

	/// en: 'Bookmark ${n}'
	String bookmarkDefaultName({required Object n}) => 'Bookmark ${n}';

	/// en: 'Enter a name for this bookmark.'
	String get bookmarkNameRequired => 'Enter a name for this bookmark.';

	/// en: 'Delete bookmark'
	String get deleteBookmark => 'Delete bookmark';

	/// en: 'This item already has 100 bookmarks.'
	String get bookmarkLimitReached => 'This item already has 100 bookmarks.';

	/// en: 'Couldn't save or remove this bookmark.'
	String get bookmarkUnavailable => 'Couldn\'t save or remove this bookmark.';

	/// en: 'Bookmark saved.'
	String get bookmarkSaved => 'Bookmark saved.';

	/// en: 'Bookmark deleted.'
	String get bookmarkDeleted => 'Bookmark deleted.';

	/// en: 'Loop point ${point} set at ${time}.'
	String loopPointSet({required Object point, required Object time}) => 'Loop point ${point} set at ${time}.';

	/// en: 'No chapters or bookmarks available.'
	String get noChaptersOrBookmarks => 'No chapters or bookmarks available.';

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

	/// en: 'Couldn't take a screenshot'
	String get screenshotFailed => 'Couldn\'t take a screenshot';

	/// en: 'Zoom ${percent}%'
	String zoomPercent({required Object percent}) => 'Zoom ${percent}%';

	/// en: 'Volume ${percent}%'
	String volumePercent({required Object percent}) => 'Volume ${percent}%';

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

	/// en: '(one) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} frame} (other) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} frames}'
	String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} frame',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} frames',
	);

	/// en: 'Choose tracks before playback'
	String get trackSelectionTitle => 'Choose tracks before playback';

	/// en: 'Automatic selection'
	String get trackSelectionAuto => 'Automatic selection';

	/// en: 'Open mini player'
	String get openMiniPlayer => 'Open mini player';

	/// en: 'Return to full player'
	String get returnToFullPlayer => 'Return to full player';

	/// en: 'Load subtitle file…'
	String get loadSubtitleFile => 'Load subtitle file…';

	/// en: 'Failed to load subtitle file'
	String get subtitleLoadFailed => 'Failed to load subtitle file';

	/// en: 'Skip Ads'
	String get skipAds => 'Skip Ads';

	/// en: 'Tap to unlock'
	String get tapToUnlock => 'Tap to unlock';

	/// en: 'Tap again to unlock'
	String get tapAgainToUnlock => 'Tap again to unlock';
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

	/// en: '(one) {Auto-removed ${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} watched download} (other) {Auto-removed ${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} watched downloads}'
	String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'Auto-removed ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} watched download',
		other: 'Auto-removed ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} watched downloads',
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

	/// en: 'Playback could not be started: ${error}'
	String playbackFailedDetail({required Object error}) => 'Playback could not be started: ${error}';

	/// en: 'The audio output stopped responding. Check the TV or receiver's audio connection; if other apps have no sound either, restart the device.'
	String get audioOutputFailed => 'The audio output stopped responding. Check the TV or receiver\'s audio connection; if other apps have no sound either, restart the device.';

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

	/// en: 'Playback not allowed'
	String get playbackNotAllowedTitle => 'Playback not allowed';

	/// en: 'The server refused to stream this item (HTTP 403). Your account may not have permission to play it, or the server may only allow playback on its local network.'
	String get playbackNotAllowedBody => 'The server refused to stream this item (HTTP 403). Your account may not have permission to play it, or the server may only allow playback on its local network.';

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

	/// en: 'This track choice applies to the current playback only.'
	String get trackSelectionNotRemembered => 'This track choice applies to the current playback only.';

	/// en: 'No server is available for the active profile'
	String get serverUnavailableForProfile => 'No server is available for the active profile';
}

// Path: subtitlingStyling
class Translations$subtitlingStyling$en {
	Translations$subtitlingStyling$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'The quick brown fox jumps over the lazy dog'
	String get previewSample => 'The quick brown fox jumps over the lazy dog';

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

	/// en: 'Use margins'
	String get useMargins => 'Use margins';

	/// en: 'Allow text subtitles in the space outside the video. Styled subtitles may keep their original placement.'
	String get useMarginsDescription => 'Allow text subtitles in the space outside the video. Styled subtitles may keep their original placement.';

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

	/// en: 'Set the subtitle text size on this device.'
	String get fontSizeDescription => 'Set the subtitle text size on this device.';

	/// en: 'Choose the color used for subtitle text.'
	String get textColorDescription => 'Choose the color used for subtitle text.';

	/// en: 'Set the thickness of the outline around subtitle text.'
	String get borderSizeDescription => 'Set the thickness of the outline around subtitle text.';

	/// en: 'Choose the color used for the subtitle outline.'
	String get borderColorDescription => 'Choose the color used for the subtitle outline.';

	/// en: 'Choose the color behind subtitle text.'
	String get backgroundColorDescription => 'Choose the color behind subtitle text.';

	/// en: 'Set how transparent the subtitle background is: 0% is clear and 100% is solid.'
	String get backgroundOpacityDescription => 'Set how transparent the subtitle background is: 0% is clear and 100% is solid.';

	/// en: 'Move subtitles vertically. 0% is the top of the video and 100% is the bottom.'
	String get positionDescription => 'Move subtitles vertically. 0% is the top of the video and 100% is the bottom.';

	/// en: 'Choose whether the player follows, adjusts, replaces, or removes styling embedded in ASS subtitles.'
	String get assOverrideDescription => 'Choose whether the player follows, adjusts, replaces, or removes styling embedded in ASS subtitles.';

	late final Translations$subtitlingStyling$assOverrideOptions$en assOverrideOptions = Translations$subtitlingStyling$assOverrideOptions$en.internal(_root);

	/// en: 'Choose the resolution used to rasterize image and ASS subtitles. Lower Android scales can reduce rendering work but look softer.'
	String get renderResolutionDescription => 'Choose the resolution used to rasterize image and ASS subtitles. Lower Android scales can reduce rendering work but look softer.';

	late final Translations$subtitlingStyling$renderResolutionOptions$en renderResolutionOptions = Translations$subtitlingStyling$renderResolutionOptions$en.internal(_root);

	/// en: 'Draw subtitle text in a heavier weight.'
	String get boldDescription => 'Draw subtitle text in a heavier weight.';

	/// en: 'Draw subtitle text in italics.'
	String get italicDescription => 'Draw subtitle text in italics.';
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

	/// en: 'Add PlezyNG profile'
	String get addPlezyProfile => 'Add PlezyNG profile';

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

	/// en: 'Also delete downloads'
	String get signOutPlexDeleteDownloads => 'Also delete downloads';

	/// en: 'Otherwise they stay on this device and come back when you sign back in to this account.'
	String get signOutPlexDeleteDownloadsDescription => 'Otherwise they stay on this device and come back when you sign back in to this account.';

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

	/// en: 'Copy Android automation link'
	String get copyAutomationLink => 'Copy Android automation link';

	/// en: 'Select this profile from an Android intent or automation. Profile PIN checks still apply.'
	String get copyAutomationLinkDescription => 'Select this profile from an Android intent or automation. Profile PIN checks still apply.';

	/// en: 'Profile automation link copied.'
	String get automationLinkCopied => 'Profile automation link copied.';

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

	/// en: 'Settings are locked for this profile.'
	String get settingsLocked => 'Settings are locked for this profile.';

	/// en: 'Unlock settings'
	String get unlockSettings => 'Unlock settings';

	/// en: 'Show Explore for this profile'
	String get showExploreForProfile => 'Show Explore for this profile';

	/// en: 'Turn off to remove Explore from this profile’s navigation.'
	String get showExploreForProfileDescription => 'Turn off to remove Explore from this profile’s navigation.';
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

	/// en: '${name} refused access for this account'
	String accessDeniedOne({required Object name}) => '${name} refused access for this account';

	/// en: '${count} servers refused access for this account'
	String accessDeniedMany({required Object count}) => '${count} servers refused access for this account';

	/// en: 'Sign in again'
	String get signInAgain => 'Sign in again';

	/// en: 'Edit ${product} connection'
	String editMediaBrowserTitle({required Object product}) => 'Edit ${product} connection';

	/// en: 'Add or remove URLs for ${serverName}. PlezyNG will use the reachable URL with the lowest latency.'
	String editMediaBrowserIntro({required Object serverName}) => 'Add or remove URLs for ${serverName}. PlezyNG will use the reachable URL with the lowest latency.';
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

	/// en: 'These options are saved on the account itself, so every app signed in to it uses them — including PlezyNG on your other devices.'
	String get storedOnAccount => 'These options are saved on the account itself, so every app signed in to it uses them — including PlezyNG on your other devices.';

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

	/// en: 'Prefer audio tracks in this language when the server or player selects a track automatically.'
	String get preferredAudioLanguageDescription => 'Prefer audio tracks in this language when the server or player selects a track automatically.';

	/// en: 'Prefer subtitle tracks in this language when subtitles are selected automatically.'
	String get preferredSubtitleLanguageDescription => 'Prefer subtitle tracks in this language when subtitles are selected automatically.';

	/// en: 'Choose whether SDH captions are preferred or required during automatic subtitle selection.'
	String get subtitleAccessibilityDescription => 'Choose whether SDH captions are preferred or required during automatic subtitle selection.';

	/// en: 'Choose whether forced subtitle tracks are preferred or required during automatic selection.'
	String get forcedSubtitleDescription => 'Choose whether forced subtitle tracks are preferred or required during automatic selection.';

	/// en: 'Choose which media types receive a watched checkmark in the server interface.'
	String get watchedIndicatorDescription => 'Choose which media types receive a watched checkmark in the server interface.';

	/// en: 'Choose which audience and critic ratings the server shows on media pages.'
	String get mediaReviewsVisibilityDescription => 'Choose which audience and critic ratings the server shows on media pages.';

	/// en: 'Choose when subtitles turn on automatically for this server account.'
	String get subtitleModeDescription => 'Choose when subtitles turn on automatically for this server account.';

	/// en: 'These preferences are stored on your media-server account and may apply on other clients too.'
	String get hubDescription => 'These preferences are stored on your media-server account and may apply on other clients too.';
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

	late final Translations$discover$findNext$en findNext = Translations$discover$findNext$en.internal(_root);

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

	/// en: '(one) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} title} (other) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} titles}'
	String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} title',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} titles',
	);

	late final Translations$discover$person$en person = Translations$discover$person$en.internal(_root);
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

	/// en: 'the connection timed out'
	String get reasonTimedOut => 'the connection timed out';

	/// en: 'the server could not be reached'
	String get reasonUnreachable => 'the server could not be reached';

	/// en: 'the server refused the request'
	String get reasonRefused => 'the server refused the request';

	/// en: 'the item is no longer on the server'
	String get reasonNotFound => 'the item is no longer on the server';

	/// en: 'the server reported an error'
	String get reasonServerError => 'the server reported an error';

	/// en: 'the request was cancelled'
	String get reasonCancelled => 'the request was cancelled';

	/// en: 'an unexpected error occurred'
	String get reasonUnexpected => 'an unexpected error occurred';
}

// Path: libraries
class Translations$libraries$en {
	Translations$libraries$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Play a random movie'
	String get playRandomMovie => 'Play a random movie';

	/// en: 'Could not choose a random movie from this library.'
	String get randomPickFailed => 'Could not choose a random movie from this library.';

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
	late final Translations$libraries$advancedFilters$en advancedFilters = Translations$libraries$advancedFilters$en.internal(_root);
	late final Translations$libraries$selection$en selection = Translations$libraries$selection$en.internal(_root);
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

	/// en: 'Privacy Policy'
	String get privacyPolicy => 'Privacy Policy';
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

	/// en: 'Save Logs to File'
	String get saveLogs => 'Save Logs to File';

	/// en: 'Logs saved to ${path}'
	String logsSaved({required Object path}) => 'Logs saved to ${path}';

	/// en: 'Could not save the log file.'
	String get saveLogsFailed => 'Could not save the log file.';
}

// Path: startup
class Translations$startup$en {
	Translations$startup$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'PlezyNG could not start'
	String get failedTitle => 'PlezyNG could not start';

	/// en: 'Something went wrong during startup. The details below identify what failed.'
	String get failedBody => 'Something went wrong during startup. The details below identify what failed.';

	/// en: 'PlezyNG's saved settings file is damaged and has to be rebuilt before PlezyNG can start. Retrying will not help — choose Repair storage.'
	String get failedBodyRepairable => 'PlezyNG\'s saved settings file is damaged and has to be rebuilt before PlezyNG can start. Retrying will not help — choose Repair storage.';

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

	/// en: 'PlezyNG's settings file is damaged and cannot be read. Repairing resets every setting to its default.'
	String get repairBodyCommon => 'PlezyNG\'s settings file is damaged and cannot be read. Repairing resets every setting to its default.';

	/// en: 'One saved sign-in is damaged and cannot be read. Repairing removes just that one; your other settings are left alone.'
	String get repairBodyOneCredential => 'One saved sign-in is damaged and cannot be read. Repairing removes just that one; your other settings are left alone.';

	/// en: 'Your servers and profiles should stay signed in.'
	String get repairBodySignInsKept => 'Your servers and profiles should stay signed in.';

	/// en: 'The key protecting your saved sign-ins cannot be recovered from this file, so you will have to sign in to every server and profile again. Nothing on your media server is affected.'
	String get repairBodySignInsLost => 'The key protecting your saved sign-ins cannot be recovered from this file, so you will have to sign in to every server and profile again. Nothing on your media server is affected.';

	/// en: 'Trackers (MAL, AniList, Simkl, Trakt) and Seerr are stored separately and may or may not survive. PlezyNG will tell you exactly what it kept.'
	String get repairBodySessionsUncertain => 'Trackers (MAL, AniList, Simkl, Trakt) and Seerr are stored separately and may or may not survive. PlezyNG will tell you exactly what it kept.';

	/// en: 'Repair'
	String get repairConfirm => 'Repair';

	/// en: 'Storage repaired'
	String get repairSucceeded => 'Storage repaired';

	/// en: 'Storage repaired — restart required'
	String get repairNeedsRestart => 'Storage repaired — restart required';

	/// en: 'Your data was repaired, but PlezyNG has to start fresh before it can use it. Close PlezyNG and open it again.'
	String get restartRequiredBody => 'Your data was repaired, but PlezyNG has to start fresh before it can use it. Close PlezyNG and open it again.';

	/// en: 'Quit PlezyNG'
	String get quitPlezy => 'Quit PlezyNG';

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

	/// en: 'PlezyNG failed to start last time'
	String get previousFailureTitle => 'PlezyNG failed to start last time';
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
	late final Translations$explore$mdblistShelves$en mdblistShelves = Translations$explore$mdblistShelves$en.internal(_root);

	/// en: 'Explore'
	String get title => 'Explore';

	/// en: 'Select source'
	String get selectSource => 'Select source';

	late final Translations$explore$rows$en rows = Translations$explore$rows$en.internal(_root);
	late final Translations$explore$status$en status = Translations$explore$status$en.internal(_root);

	/// en: '(one) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} episode} (other) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} episodes}'
	String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episode',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodes',
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

	/// en: '(one) {Couldn't check ${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} server} (other) {Couldn't check ${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} servers}'
	String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'Couldn\'t check ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} server',
		other: 'Couldn\'t check ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} servers',
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

	/// en: '(one) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} result} (other) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} results}'
	String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} result',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} results',
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

	/// en: 'Live program (playback may be outside this program)'
	String get timelineLiveProgram => 'Live program (playback may be outside this program)';

	/// en: 'Buffer timeline'
	String get timelineBuffer => 'Buffer timeline';

	/// en: 'Timeline unavailable'
	String get timelineUnavailable => 'Timeline unavailable';

	/// en: 'Estimated playback'
	String get timelineEstimated => 'Estimated playback';

	/// en: 'Pending seek'
	String get timelinePending => 'Pending seek';

	/// en: 'Schedule may be outdated'
	String get timelineStale => 'Schedule may be outdated';

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

	/// en: 'NEW'
	String get premiereBadge => 'NEW';

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

	/// en: 'Couldn't refresh the guide'
	String get guideReloadFailed => 'Couldn\'t refresh the guide';

	/// en: 'Rule re-evaluation requested'
	String get rulesProcessRequested => 'Rule re-evaluation requested';

	/// en: 'Couldn't re-evaluate recording rules'
	String get rulesProcessFailed => 'Couldn\'t re-evaluate recording rules';

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

	/// en: 'Couldn't start the channel: ${reason}'
	String playbackStartFailed({required Object reason}) => 'Couldn\'t start the channel: ${reason}';

	/// en: 'Couldn't switch channel: ${reason}'
	String channelSwitchFailed({required Object reason}) => 'Couldn\'t switch channel: ${reason}';
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

	/// en: '(one) {${count: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} item} (other) {${count: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} items}'
	String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} item',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} items',
	);

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

	/// en: '(one) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} track} (other) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} tracks}'
	String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} track',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tracks',
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

	/// en: 'Visualizer'
	String get visualizer => 'Visualizer';

	/// en: 'Reading track analysis…'
	String get visualizerProfileLoading => 'Reading track analysis…';

	/// en: 'Ambient motion'
	String get visualizerAmbientMotion => 'Ambient motion';

	/// en: 'Plex loudness'
	String get visualizerPlexLoudness => 'Plex loudness';

	/// en: 'Live audio analysis'
	String get visualizerLiveAudio => 'Live audio analysis';

	/// en: 'Previous visual style'
	String get visualizerPreviousPreset => 'Previous visual style';

	/// en: 'Next visual style'
	String get visualizerNextPreset => 'Next visual style';

	/// en: 'Aurora'
	String get visualizerPresetAurora => 'Aurora';

	/// en: 'Bloom'
	String get visualizerPresetBloom => 'Bloom';

	/// en: 'Orbitals'
	String get visualizerPresetOrbitals => 'Orbitals';

	/// en: 'Prism'
	String get visualizerPresetPrism => 'Prism';

	/// en: 'Tunnel'
	String get visualizerPresetTunnel => 'Tunnel';

	/// en: 'Track map'
	String get visualizerPresetTrackMap => 'Track map';

	/// en: 'No lyrics available'
	String get noLyrics => 'No lyrics available';

	/// en: 'Sleep timer'
	String get sleepTimer => 'Sleep timer';

	/// en: 'End of track'
	String get sleepTimerEndOfTrack => 'End of track';

	/// en: '(other) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} minutes} (one) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} minute}'
	String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutes',
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minute',
	);

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

	/// en: 'Create Room'
	String get createRoom => 'Create Room';

	/// en: 'Creating room...'
	String get creatingRoom => 'Creating room...';

	/// en: 'Join Room'
	String get joinRoom => 'Join Room';

	/// en: 'Joining room...'
	String get joiningRoom => 'Joining room...';

	/// en: 'Connecting...'
	String get connecting => 'Connecting...';

	/// en: 'Rooms use the public Open Watch Party relays.'
	String get relayPublic => 'Rooms use the public Open Watch Party relays.';

	/// en: 'Rooms use your relay at ${url}.'
	String relayCustom({required Object url}) => 'Rooms use your relay at ${url}.';

	/// en: 'Recent Rooms'
	String get recentRooms => 'Recent Rooms';

	/// en: 'Room actions'
	String get roomActions => 'Room actions';

	/// en: 'Rename Room'
	String get renameRoom => 'Rename Room';

	/// en: 'Remove'
	String get removeRoom => 'Remove';

	/// en: 'Enter the 6-character code from the host.'
	String get enterRoomCode => 'Enter the 6-character code from the host.';

	/// en: 'Room Code'
	String get roomCode => 'Room Code';

	/// en: 'Paste'
	String get paste => 'Paste';

	/// en: 'The clipboard doesn't contain a room code'
	String get noCodeInClipboard => 'The clipboard doesn\'t contain a room code';

	/// en: 'Copy Code'
	String get copyCode => 'Copy Code';

	/// en: 'Room code copied'
	String get codeCopied => 'Room code copied';

	/// en: 'Share Invite'
	String get shareInvite => 'Share Invite';

	/// en: 'Invite copied. Paste it into a message.'
	String get inviteCopied => 'Invite copied. Paste it into a message.';

	/// en: 'Join my Watch Together room in PlezyNG: open Watch Together, choose Join Room and enter ${code}.'
	String inviteMessage({required Object code}) => 'Join my Watch Together room in PlezyNG: open Watch Together, choose Join Room and enter ${code}.';

	/// en: 'Open Watch Together session controls'
	String get openSessionControls => 'Open Watch Together session controls';

	/// en: 'Reconnecting...'
	String get reconnecting => 'Reconnecting...';

	/// en: 'The connection dropped. You rejoin the room automatically.'
	String get reconnectingDescription => 'The connection dropped. You rejoin the room automatically.';

	/// en: 'Connected'
	String get connected => 'Connected';

	/// en: 'Disconnected'
	String get disconnected => 'Disconnected';

	/// en: 'You are the host'
	String get youAreHost => 'You are the host';

	/// en: 'Hosted by ${name}'
	String hostedBy({required Object name}) => 'Hosted by ${name}';

	/// en: 'Host controls playback'
	String get hostControlsPlayback => 'Host controls playback';

	/// en: 'Anyone can control playback'
	String get anyoneCanControl => 'Anyone can control playback';

	/// en: 'Room locked'
	String get roomLocked => 'Room locked';

	/// en: 'Now Playing'
	String get nowPlaying => 'Now Playing';

	/// en: 'Nothing playing'
	String get nothingPlaying => 'Nothing playing';

	/// en: 'Play something from any library to share it with the room.'
	String get nothingPlayingHost => 'Play something from any library to share it with the room.';

	/// en: 'When the host plays something, it opens here.'
	String get nothingPlayingGuest => 'When the host plays something, it opens here.';

	/// en: 'This video has no catalogue match, so only people with access to the same server can play it.'
	String get notShareable => 'This video has no catalogue match, so only people with access to the same server can play it.';

	/// en: 'Looking for this video in your libraries...'
	String get searching => 'Looking for this video in your libraries...';

	/// en: 'Your copy'
	String get yourCopy => 'Your copy';

	/// en: 'You're sharing your copy'
	String get sharingYourCopy => 'You\'re sharing your copy';

	/// en: 'Playing your copy, ${difference}'
	String playingOtherLength({required Object difference}) => 'Playing your copy, ${difference}';

	/// en: 'Your Copy Is a Different Length'
	String get mismatchTitle => 'Your Copy Is a Different Length';

	/// en: 'Your closest copy is ${difference} than the room's video. It may be another cut or version.'
	String mismatchDescription({required Object difference}) => 'Your closest copy is ${difference} than the room\'s video. It may be another cut or version.';

	/// en: 'Play Anyway'
	String get playAnyway => 'Play Anyway';

	/// en: 'Choose Another Copy'
	String get chooseAnotherCopy => 'Choose Another Copy';

	/// en: 'Don't Play'
	String get dontPlay => 'Don\'t Play';

	/// en: 'You don't have this video'
	String get unavailableTitle => 'You don\'t have this video';

	/// en: 'PlezyNG couldn't find it in your libraries. Pick a copy yourself or search again.'
	String get unavailableDescription => 'PlezyNG couldn\'t find it in your libraries. Pick a copy yourself or search again.';

	/// en: 'Choose a Copy'
	String get chooseCopy => 'Choose a Copy';

	/// en: 'Search Again'
	String get searchAgain => 'Search Again';

	/// en: 'No copies found in your libraries.'
	String get noCandidates => 'No copies found in your libraries.';

	/// en: 'Couldn't play this copy for the room'
	String get choiceFailed => 'Couldn\'t play this copy for the room';

	/// en: '${duration} longer'
	String lengthLonger({required Object duration}) => '${duration} longer';

	/// en: '${duration} shorter'
	String lengthShorter({required Object duration}) => '${duration} shorter';

	/// en: 'Same length'
	String get lengthSame => 'Same length';

	/// en: 'Length unknown'
	String get lengthUnknown => 'Length unknown';

	/// en: 'Join Current Playback'
	String get joinCurrentPlayback => 'Join Current Playback';

	/// en: 'Jump back into what the host is currently watching'
	String get joinCurrentPlaybackDescription => 'Jump back into what the host is currently watching';

	/// en: 'Stop Video for Everyone'
	String get stopMedia => 'Stop Video for Everyone';

	/// en: 'Sync Offset'
	String get syncOffset => 'Sync Offset';

	/// en: 'Shift your video if it runs ahead of or behind the room.'
	String get syncOffsetDescription => 'Shift your video if it runs ahead of or behind the room.';

	/// en: 'Your copy is ${difference} than the room's video.'
	String offsetHint({required Object difference}) => 'Your copy is ${difference} than the room\'s video.';

	/// en: 'Use ${offset}'
	String applyDifference({required Object offset}) => 'Use ${offset}';

	/// en: '-1 s'
	String get offsetMinusSecond => '-1 s';

	/// en: '-100 ms'
	String get offsetMinusTenth => '-100 ms';

	/// en: '+100 ms'
	String get offsetPlusTenth => '+100 ms';

	/// en: '+1 s'
	String get offsetPlusSecond => '+1 s';

	/// en: 'Participants'
	String get participants => 'Participants';

	/// en: '(one) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} participant} (other) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} participants}'
	String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} participant',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} participants',
	);

	/// en: 'HOST'
	String get hostBadge => 'HOST';

	/// en: '${name} (You)'
	String nameYou({required Object name}) => '${name} (You)';

	/// en: 'Idle'
	String get playerIdle => 'Idle';

	/// en: 'Loading'
	String get playerLoading => 'Loading';

	/// en: 'Ready'
	String get playerReady => 'Ready';

	/// en: 'Buffering'
	String get playerBuffering => 'Buffering';

	/// en: 'Searching'
	String get matchSearching => 'Searching';

	/// en: 'Has the video'
	String get matchMatched => 'Has the video';

	/// en: 'Different length'
	String get matchMismatched => 'Different length';

	/// en: 'Doesn't have the video'
	String get matchUnavailable => 'Doesn\'t have the video';

	/// en: 'Offset ${offset}'
	String participantOffset({required Object offset}) => 'Offset ${offset}';

	/// en: 'Make host'
	String get makeHost => 'Make host';

	/// en: 'Transfer host?'
	String get makeHostQuestion => 'Transfer host?';

	/// en: '${name} will control playback and drive the session for everyone.'
	String makeHostConfirm({required Object name}) => '${name} will control playback and drive the session for everyone.';

	/// en: 'Transfer'
	String get transfer => 'Transfer';

	/// en: 'Remove from Room'
	String get removeParticipant => 'Remove from Room';

	/// en: 'Remove ${name}?'
	String removeParticipantQuestion({required Object name}) => 'Remove ${name}?';

	/// en: '${name} leaves the room. They can join again with the code unless you lock the room.'
	String removeParticipantConfirm({required Object name}) => '${name} leaves the room. They can join again with the code unless you lock the room.';

	/// en: 'Remove'
	String get remove => 'Remove';

	/// en: 'Room Settings'
	String get roomSettings => 'Room Settings';

	/// en: 'Let Everyone Control Playback'
	String get letEveryoneControl => 'Let Everyone Control Playback';

	/// en: 'Lock Room'
	String get lockRoom => 'Lock Room';

	/// en: 'Nobody new can join'
	String get lockRoomDescription => 'Nobody new can join';

	/// en: 'Leave Room'
	String get leaveRoom => 'Leave Room';

	/// en: 'Leave Room?'
	String get leaveRoomQuestion => 'Leave Room?';

	/// en: 'You can join again with the room code.'
	String get leaveRoomConfirm => 'You can join again with the room code.';

	/// en: 'Leave'
	String get leave => 'Leave';

	/// en: 'End Room'
	String get endRoom => 'End Room';

	/// en: 'End Room?'
	String get endRoomQuestion => 'End Room?';

	/// en: 'This ends the room for everyone.'
	String get endRoomConfirm => 'This ends the room for everyone.';

	/// en: 'End'
	String get end => 'End';

	/// en: 'Playback didn't start'
	String get playBlockedTitle => 'Playback didn\'t start';

	/// en: 'Press play to start watching with the room.'
	String get playBlockedDescription => 'Press play to start watching with the room.';

	late final Translations$watchTogether$notices$en notices = Translations$watchTogether$notices$en.internal(_root);
	late final Translations$watchTogether$ended$en ended = Translations$watchTogether$ended$en.internal(_root);
	late final Translations$watchTogether$errors$en errors = Translations$watchTogether$errors$en.internal(_root);

	/// en: 'Episode ${number}'
	String untitledEpisode({required Object number}) => 'Episode ${number}';
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

	/// en: 'Downloads stopped to protect available storage. Free some space or choose another download location, then retry.'
	String get storageFull => 'Downloads stopped to protect available storage. Free some space or choose another download location, then retry.';

	/// en: 'Downloads stopped because available storage could not be checked. Check the download location, then retry.'
	String get storageUnavailable => 'Downloads stopped because available storage could not be checked. Check the download location, then retry.';

	/// en: '${count} episodes queued for download'
	String episodesQueued({required Object count}) => '${count} episodes queued for download';

	/// en: 'Download deleted'
	String get downloadDeleted => 'Download deleted';

	/// en: 'Delete "${title}" from this device?'
	String deleteConfirm({required Object title}) => 'Delete "${title}" from this device?';

	/// en: 'Delete downloads'
	String get deleteCollectionDownloads => 'Delete downloads';

	/// en: 'Delete every download in "${title}" from this device?'
	String deleteCollectionDownloadsConfirm({required Object title}) => 'Delete every download in "${title}" from this device?';

	/// en: 'Downloads deleted'
	String get collectionDownloadsDeleted => 'Downloads deleted';

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

	/// en: 'Retry all'
	String get retryAll => 'Retry all';

	/// en: 'Retry failed downloads'
	String get retryFailed => 'Retry failed downloads';

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

	/// en: 'Custom amount (any)...'
	String get customAmountAny => 'Custom amount (any)...';

	/// en: 'Random episodes'
	String get randomEpisodes => 'Random episodes';

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

	/// en: 'Sync now'
	String get syncNow => 'Sync now';

	/// en: 'Downloads are up to date'
	String get downloadsUpToDate => 'Downloads are up to date';

	/// en: 'Sync complete · ${queued} queued, ${removed} removed'
	String syncComplete({required Object queued, required Object removed}) => 'Sync complete · ${queued} queued, ${removed} removed';

	/// en: 'Sync rules'
	String get activeSyncRules => 'Sync rules';

	/// en: 'Review orphaned downloads'
	String get reviewOrphanFiles => 'Review orphaned downloads';

	/// en: 'Review orphaned downloads'
	String get orphanReviewTitle => 'Review orphaned downloads';

	/// en: 'These tagged files are in PlezyNG's default app-managed download folders and have no matching download record or active task. Check the list before deleting them.'
	String get orphanReviewDescription => 'These tagged files are in PlezyNG\'s default app-managed download folders and have no matching download record or active task. Check the list before deleting them.';

	/// en: '${count} files · ${size}'
	String orphanReviewCount({required Object count, required Object size}) => '${count} files · ${size}';

	/// en: 'Delete ${count} files'
	String orphanDeleteFiles({required Object count}) => 'Delete ${count} files';

	/// en: 'No orphaned download files found'
	String get orphanCleanupNone => 'No orphaned download files found';

	/// en: 'PlezyNG could not safely scan the managed downloads folder. No files were deleted.'
	String get orphanCleanupFailed => 'PlezyNG could not safely scan the managed downloads folder. No files were deleted.';

	/// en: 'The download list changed during review. Review the files again before cleaning.'
	String get orphanCleanupChanged => 'The download list changed during review. Review the files again before cleaning.';

	/// en: 'Deleted ${count} orphaned files · ${size} freed'
	String orphanCleanupComplete({required Object count, required Object size}) => 'Deleted ${count} orphaned files · ${size} freed';

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

	/// en: 'Access denied'
	String get syncRuleAccessDenied => 'Access denied';

	/// en: 'Not available for current profile'
	String get syncRuleNotAvailableForProfile => 'Not available for current profile';

	/// en: 'Unknown server'
	String get syncRuleUnknownServer => 'Unknown server';

	/// en: 'Sync rule created'
	String get syncRuleListCreated => 'Sync rule created';

	late final Translations$downloads$backgroundWarning$en backgroundWarning = Translations$downloads$backgroundWarning$en.internal(_root);

	/// en: 'Downloads options'
	String get options => 'Downloads options';

	late final Translations$downloads$groupings$en groupings = Translations$downloads$groupings$en.internal(_root);

	/// en: 'Unknown library'
	String get unknownLibrary => 'Unknown library';

	/// en: 'Unknown Show'
	String get unknownShow => 'Unknown Show';

	/// en: 'Unknown Season'
	String get unknownSeason => 'Unknown Season';

	/// en: 'Unknown Album'
	String get unknownAlbum => 'Unknown Album';

	/// en: '${completed}/${total} completed'
	String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} completed';

	/// en: 'Storage used: ${size}'
	String storageUsed({required Object size}) => 'Storage used: ${size}';

	/// en: '(one) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} download} (other) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} downloads}'
	String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} download',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} downloads',
	);

	/// en: '(one) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} show} (other) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} shows}'
	String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} show',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} shows',
	);

	/// en: '(one) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} movie} (other) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} movies}'
	String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} movie',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} movies',
	);

	/// en: '(one) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} album} (other) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} albums}'
	String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} album',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} albums',
	);

	/// en: 'File not found (404)'
	String get errorFileNotFound => 'File not found (404)';

	/// en: 'Download not allowed by the server (403)'
	String get errorDownloadNotAllowed => 'Download not allowed by the server (403)';

	/// en: 'Download failed'
	String get errorDownloadFailed => 'Download failed';

	/// en: 'Download failed: ${reason}'
	String errorDownloadFailedWithReason({required Object reason}) => 'Download failed: ${reason}';

	/// en: 'Converting on server…'
	String get convertingOnServer => 'Converting on server…';

	/// en: 'Converting on server · ${percent}%'
	String convertingOnServerPercent({required Object percent}) => 'Converting on server · ${percent}%';

	/// en: 'Download failed (HTTP ${status})'
	String errorHttpStatus({required Object status}) => 'Download failed (HTTP ${status})';

	/// en: 'Post-processing failed: ${reason}'
	String errorPostProcessing({required Object reason}) => 'Post-processing failed: ${reason}';

	/// en: 'the file could not be saved on this device'
	String get reasonFileNotSaved => 'the file could not be saved on this device';

	/// en: 'the partial download could not be resumed'
	String get reasonCannotResume => 'the partial download could not be resumed';

	/// en: 'this device is out of storage'
	String get reasonDeviceStorageFull => 'this device is out of storage';

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

	/// en: 'Video Track'
	String get videoTrack => 'Video Track';

	/// en: 'Choose which video stream to display. Available on MPV playback when a file contains alternate video tracks.'
	String get videoTrackDescription => 'Choose which video stream to display. Available on MPV playback when a file contains alternate video tracks.';

	/// en: 'Default'
	String get videoTrackDefault => 'Default';

	/// en: 'No alternate video tracks are available.'
	String get videoTrackUnavailable => 'No alternate video tracks are available.';

	/// en: 'Could not change the video track.'
	String get videoTrackFailed => 'Could not change the video track.';

	/// en: 'Track ${id}'
	String videoTrackNumber({required Object id}) => 'Track ${id}';

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

	/// en: 'Audio Equalizer'
	String get audioEqualizer => 'Audio Equalizer';

	/// en: '10-band equalizer for MPV. Audio filters use decoded audio and turn off passthrough.'
	String get audioEqualizerDescription => '10-band equalizer for MPV. Audio filters use decoded audio and turn off passthrough.';

	/// en: 'Flat'
	String get audioEqualizerFlat => 'Flat';

	/// en: 'Custom'
	String get audioEqualizerActive => 'Custom';

	/// en: 'Couldn't save audio equalizer settings.'
	String get audioEqualizerSaveFailed => 'Couldn\'t save audio equalizer settings.';

	/// en: 'Effects use decoded audio, so passthrough turns off. Room ambience and stereo widening depend on the MPV build and track.'
	String get audioEffectsDescription => 'Effects use decoded audio, so passthrough turns off. Room ambience and stereo widening depend on the MPV build and track.';

	/// en: 'Stereo widening'
	String get audioStereoWidth => 'Stereo widening';

	/// en: 'Room ambience'
	String get audioSpatializer => 'Room ambience';

	/// en: 'Add quiet room reflections.'
	String get audioSpatializerDescription => 'Add quiet room reflections.';

	/// en: 'Pitch shift'
	String get audioPitch => 'Pitch shift';

	/// en: 'Change pitch without changing speed. The MPV build must include Rubber Band.'
	String get audioPitchDescription => 'Change pitch without changing speed. The MPV build must include Rubber Band.';

	/// en: 'This effect isn't available for this track or MPV build.'
	String get audioEffectUnavailable => 'This effect isn\'t available for this track or MPV build.';

	/// en: 'Background Video Audio'
	String get backgroundVideoAudio => 'Background Video Audio';

	/// en: 'Keep video audio playing when you leave the player; the picture is hidden until you return. Android uses a media playback notification.'
	String get backgroundVideoAudioDescription => 'Keep video audio playing when you leave the player; the picture is hidden until you return. Android uses a media playback notification.';

	/// en: 'Normalize Loudness'
	String get audioNormalization => 'Normalize Loudness';

	/// en: 'Decodes audio to PCM; passthrough is off while this is on'
	String get audioNormalizationDisablesPassthrough => 'Decodes audio to PCM; passthrough is off while this is on';
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

	/// en: 'Dolby Vision decoder'
	String get dvRouteDecoder => 'Dolby Vision decoder';

	/// en: 'Dolby Vision decoder (P7→8.1)'
	String get dvRouteDecoderP81 => 'Dolby Vision decoder (P7→8.1)';

	/// en: 'Base layer'
	String get dvRouteBaseLayer => 'Base layer';

	/// en: 'HDR10 base layer'
	String get dvRouteBaseLayerHdr10 => 'HDR10 base layer';

	/// en: 'HLG base layer'
	String get dvRouteBaseLayerHlg => 'HLG base layer';

	/// en: 'SDR base layer'
	String get dvRouteBaseLayerSdr => 'SDR base layer';

	/// en: 'RPU reshaped (gpu-next)'
	String get dvRouteReshaped => 'RPU reshaped (gpu-next)';

	/// en: 'Experimental P7 FEL graph (unqualified)'
	String get dvRouteFelGraphActive => 'Experimental P7 FEL graph (unqualified)';

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

	/// en: 'Play Method'
	String get playMethod => 'Play Method';

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

	/// en: 'Choose another app to open videos in. Available players depend on your device and installed apps.'
	String get description => 'Choose another app to open videos in. Available players depend on your device and installed apps.';

	/// en: 'Let the operating system open the video with its default app.'
	String get systemDefaultDescription => 'Let the operating system open the video with its default app.';

	/// en: 'Open videos with ${player}.'
	String playerOptionDescription({required Object player}) => 'Open videos with ${player}.';

	/// en: 'The label shown in the player list.'
	String get playerNameDescription => 'The label shown in the player list.';

	/// en: 'Enter the Android package name of the player app, such as com.example.player.'
	String get playerPackageDescription => 'Enter the Android package name of the player app, such as com.example.player.';

	/// en: 'Enter the installed player command or executable path for this device.'
	String get playerCommandDescription => 'Enter the installed player command or executable path for this device.';

	/// en: 'Enter the URL scheme and optional URL template used to launch the player.'
	String get playerUrlSchemeDescription => 'Enter the URL scheme and optional URL template used to launch the player.';
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

	/// en: 'Quick Tag...'
	String get quickTag => 'Quick Tag...';
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

	/// en: 'Plex Discover'
	String get plexDiscover => 'Plex Discover';

	/// en: 'Plex library'
	String get plexLibrary => 'Plex library';

	/// en: 'Jellyfin library'
	String get jellyfinLibrary => 'Jellyfin library';

	/// en: 'Emby library'
	String get embyLibrary => 'Emby library';
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

	/// en: 'PlezyNG will stop sending events to Trakt. You can reconnect any time.'
	String get disconnectConfirmBody => 'PlezyNG will stop sending events to Trakt. You can reconnect any time.';

	/// en: 'Real-time scrobbling'
	String get scrobble => 'Real-time scrobbling';

	/// en: 'Send play, pause, and stop events to Trakt during playback.'
	String get scrobbleDescription => 'Send play, pause, and stop events to Trakt during playback.';

	/// en: 'Sync watched status'
	String get watchedSync => 'Sync watched status';

	/// en: 'When you mark items as watched in PlezyNG, they are also marked as watched on Trakt.'
	String get watchedSyncDescription => 'When you mark items as watched in PlezyNG, they are also marked as watched on Trakt.';

	/// en: 'Export to Letterboxd'
	String get historyExport => 'Export to Letterboxd';

	/// en: 'Create a local CSV from Trakt movie history. Nothing is uploaded.'
	String get historyExportDescription => 'Create a local CSV from Trakt movie history. Nothing is uploaded.';

	/// en: 'Loading Trakt movie history…'
	String get historyExportLoading => 'Loading Trakt movie history…';

	/// en: 'Export movie history'
	String get historyExportReviewTitle => 'Export movie history';

	/// en: 'This will save ${plays} movie watch entries covering ${movies} movies in ${files} Letterboxd import CSV file(s). Files include available TMDB/IMDb IDs, titles, years, and watched dates using this device's local calendar date. TV episodes and ratings are excluded; nothing is uploaded. Letterboxd may combine repeat watches on the same date. Each file stays below Letterboxd's 1 MB import limit.'
	String historyExportReview({required Object plays, required Object movies, required Object files}) => 'This will save ${plays} movie watch entries covering ${movies} movies in ${files} Letterboxd import CSV file(s). Files include available TMDB/IMDb IDs, titles, years, and watched dates using this device\'s local calendar date. TV episodes and ratings are excluded; nothing is uploaded. Letterboxd may combine repeat watches on the same date. Each file stays below Letterboxd\'s 1 MB import limit.';

	/// en: '${count} incomplete entries could not be included.'
	String historyExportSkipped({required Object count}) => '${count} incomplete entries could not be included.';

	/// en: 'No exportable movie history was found in Trakt.'
	String get historyExportNoHistory => 'No exportable movie history was found in Trakt.';

	/// en: 'Couldn't load Trakt movie history. Try again.'
	String get historyExportFailed => 'Couldn\'t load Trakt movie history. Try again.';

	/// en: 'Save CSV'
	String get historyExportSave => 'Save CSV';

	/// en: 'Save Letterboxd file ${part} of ${total}'
	String historyExportPart({required Object part, required Object total}) => 'Save Letterboxd file ${part} of ${total}';

	/// en: 'Saved ${count} Letterboxd CSV file(s).'
	String historyExportSaved({required Object count}) => 'Saved ${count} Letterboxd CSV file(s).';

	/// en: 'Export stopped after saving ${saved} of ${total} files.'
	String historyExportPartial({required Object saved, required Object total}) => 'Export stopped after saving ${saved} of ${total} files.';

	/// en: 'Couldn't save the CSV file. Try again.'
	String get historyExportSaveFailed => 'Couldn\'t save the CSV file. Try again.';

	/// en: 'This history is too large to package here. Use Trakt's own data export to split very large histories.'
	String get historyExportTooLarge => 'This history is too large to package here. Use Trakt\'s own data export to split very large histories.';
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

	/// en: 'This Seerr instance offers no sign-in method PlezyNG supports.'
	String get noSignInMethods => 'This Seerr instance offers no sign-in method PlezyNG supports.';

	/// en: 'Instance'
	String get instance => 'Instance';

	/// en: 'Disconnect Seerr?'
	String get disconnectConfirm => 'Disconnect Seerr?';

	/// en: 'PlezyNG will forget this Seerr instance. Reconnect any time.'
	String get disconnectConfirmBody => 'PlezyNG will forget this Seerr instance. Reconnect any time.';

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

	/// en: 'An authenticating reverse proxy (SSO or HTTP auth) answered instead of Seerr. PlezyNG cannot sign in through it: let Seerr's /api/v1 path bypass the proxy for this app, or use an address that reaches Seerr directly.'
	String get behindAuthProxy => 'An authenticating reverse proxy (SSO or HTTP auth) answered instead of Seerr. PlezyNG cannot sign in through it: let Seerr\'s /api/v1 path bypass the proxy for this app, or use an address that reaches Seerr directly.';

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

	/// en: 'Hardcover'
	String get hardcover => 'Hardcover';

	/// en: 'Linked catalog titles'
	String get linkedCatalogTitles => 'Linked catalog titles';

	/// en: 'Optional plan note. This label is only for you; PlezyNG does not verify account access.'
	String get planNote => 'Optional plan note. This label is only for you; PlezyNG does not verify account access.';

	/// en: 'Plan label'
	String get planLabel => 'Plan label';

	/// en: 'Set plan label'
	String get setPlanLabel => 'Set plan label';

	/// en: 'PlezyNG may earn a commission from some links.'
	String get commissionDisclosure => 'PlezyNG may earn a commission from some links.';

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

	/// en: 'PlezyNG will stop updating ${service}. Reconnect any time.'
	String disconnectConfirmBody({required Object service}) => 'PlezyNG will stop updating ${service}. Reconnect any time.';

	/// en: 'Couldn't connect to ${service}. Try again.'
	String connectFailed({required Object service}) => 'Couldn\'t connect to ${service}. Try again.';

	late final Translations$services$names$en names = Translations$services$names$en.internal(_root);
	late final Translations$services$simklReconnect$en simklReconnect = Translations$services$simklReconnect$en.internal(_root);
	late final Translations$services$deviceCode$en deviceCode = Translations$services$deviceCode$en.internal(_root);
	late final Translations$services$oauthProxy$en oauthProxy = Translations$services$oauthProxy$en.internal(_root);
	late final Translations$services$pendingAuth$en pendingAuth = Translations$services$pendingAuth$en.internal(_root);
	late final Translations$services$libraryFilter$en libraryFilter = Translations$services$libraryFilter$en.internal(_root);

	/// en: 'Connect to Seerr or Overseerr to search for titles and submit media requests.'
	String get seerrDescription => 'Connect to Seerr or Overseerr to search for titles and submit media requests.';

	late final Translations$services$trackerDescriptions$en trackerDescriptions = Translations$services$trackerDescriptions$en.internal(_root);
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

	/// en: 'Plex server URL'
	String get directPlexServerUrl => 'Plex server URL';

	/// en: 'Enter the local IP and port of your Plex Media Server.'
	String get directPlexServerUrlHelper => 'Enter the local IP and port of your Plex Media Server.';

	/// en: 'http://192.168.1.100:32400'
	String get directPlexServerUrlHint => 'http://192.168.1.100:32400';

	/// en: 'Plex Token (optional)'
	String get plexToken => 'Plex Token (optional)';

	/// en: 'Leave blank if access without auth is allowed on this server.'
	String get plexTokenHelper => 'Leave blank if access without auth is allowed on this server.';

	/// en: 'Authentication required. Please enter your Plex token (X-Plex-Token).'
	String get plexTokenRequired => 'Authentication required. Please enter your Plex token (X-Plex-Token).';

	/// en: 'Plex Media Server (Direct / Local)'
	String get connectDirectPlexCard => 'Plex Media Server (Direct / Local)';

	/// en: 'Connect directly using local IP or URL without plex.tv account.'
	String get connectDirectPlexCardSubtitle => 'Connect directly using local IP or URL without plex.tv account.';

	/// en: 'Connect directly using local IP or URL. Binds to ${name}.'
	String connectDirectPlexCardSubtitleScoped({required Object name}) => 'Connect directly using local IP or URL. Binds to ${name}.';

	/// en: 'Unencrypted connection'
	String get insecureTitle => 'Unencrypted connection';

	/// en: '$url uses HTTP. People on the network may read or change your password, tokens and media. Use HTTPS when available. Only continue if you trust this network and accept the risk.'
	String insecureDescription({required Object url}) => '${url} uses HTTP. People on the network may read or change your password, tokens and media. Use HTTPS when available. Only continue if you trust this network and accept the risk.';

	/// en: 'Allow HTTP'
	String get allowHttp => 'Allow HTTP';

	/// en: 'Use HTTPS or explicitly allow an unencrypted connection.'
	String get httpsRequired => 'Use HTTPS or explicitly allow an unencrypted connection.';
}

// Path: cast
class Translations$cast$en {
	Translations$cast$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Cast to a device'
	String get chooseDevice => 'Cast to a device';

	/// en: 'Searching for Cast devices…'
	String get searching => 'Searching for Cast devices…';

	/// en: 'Connected to ${device}'
	String connectedTo({required Object device}) => 'Connected to ${device}';

	/// en: 'Cast device'
	String get device => 'Cast device';

	/// en: 'Ready to cast'
	String get readyToCast => 'Ready to cast';

	/// en: 'Subtitles'
	String get subtitle => 'Subtitles';

	/// en: 'The media server is not available.'
	String get serverNotAvailable => 'The media server is not available.';

	/// en: 'Stop casting'
	String get stopCasting => 'Stop casting';

	/// en: 'Cast to device'
	String get castToDevice => 'Cast to device';

	/// en: 'There is no episode available to cast.'
	String get noEpisodeAvailable => 'There is no episode available to cast.';

	/// en: 'Could not start casting. Check the server and try again.'
	String get startFailed => 'Could not start casting. Check the server and try again.';
}

// Path: automation
class Translations$automation$en {
	Translations$automation$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'There is no active video session to control.'
	String get noActivePlayback => 'There is no active video session to control.';
}

// Path: notifications
class Translations$notifications$en {
	Translations$notifications$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'New episode'
	String get newEpisodeTitle => 'New episode';

	/// en: '${show} · ${episode}'
	String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appAccess
class Translations$appAccess$en {
	Translations$appAccess$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Try every feature free for 7 days'
	String get title => 'Try every feature free for 7 days';

	/// en: 'Start a seven-day trial with full access to every PlezyNG feature. There is no charge during the trial and no subscription. After the trial, one lifetime purchase at your store's price unlocks PlezyNG for life.'
	String get description => 'Start a seven-day trial with full access to every PlezyNG feature. There is no charge during the trial and no subscription. After the trial, one lifetime purchase at your store\'s price unlocks PlezyNG for life.';

	/// en: 'Unlock every feature in PlezyNG for life with one purchase at your store's price. There is no subscription.'
	String get trialEndedDescription => 'Unlock every feature in PlezyNG for life with one purchase at your store\'s price. There is no subscription.';

	/// en: 'Start my 7-day free trial'
	String get startTrial => 'Start my 7-day free trial';

	/// en: 'Your 7-day full-feature trial is active.'
	String get trialActive => 'Your 7-day full-feature trial is active.';

	/// en: 'Your 7-day trial has ended'
	String get trialEnded => 'Your 7-day trial has ended';

	/// en: 'Couldn't save the trial on this device. Please try again.'
	String get trialStartFailed => 'Couldn\'t save the trial on this device. Please try again.';

	/// en: 'PlezyNG unlocked for life'
	String get lifetimeTitle => 'PlezyNG unlocked for life';

	/// en: 'Thanks! You have lifetime access to every PlezyNG feature.'
	String get lifetimeBody => 'Thanks! You have lifetime access to every PlezyNG feature.';

	/// en: 'PlezyNG lifetime access'
	String get manageTitle => 'PlezyNG lifetime access';

	/// en: 'Try every feature free for 7 days, then unlock everything for life with one payment at your store's price.'
	String get manageDescription => 'Try every feature free for 7 days, then unlock everything for life with one payment at your store\'s price.';

	/// en: 'Unlock every feature for ${price}'
	String buy({required Object price}) => 'Unlock every feature for ${price}';

	/// en: 'Loading store price...'
	String get loadingPrice => 'Loading store price...';

	/// en: 'Retry price lookup'
	String get retryPrice => 'Retry price lookup';

	/// en: 'Restore lifetime purchase'
	String get restore => 'Restore lifetime purchase';

	/// en: 'Your purchase is waiting for payment or approval. Lifetime access unlocks as soon as the store completes it.'
	String get pending => 'Your purchase is waiting for payment or approval. Lifetime access unlocks as soon as the store completes it.';

	/// en: 'Purchases aren't available. Check that you're signed in to the store and purchases are allowed on this device.'
	String get storeUnavailable => 'Purchases aren\'t available. Check that you\'re signed in to the store and purchases are allowed on this device.';

	/// en: 'The PlezyNG lifetime unlock isn't available in this store yet.'
	String get productNotFound => 'The PlezyNG lifetime unlock isn\'t available in this store yet.';

	/// en: 'Couldn't load the store price. Check your connection and try again.'
	String get productQueryFailed => 'Couldn\'t load the store price. Check your connection and try again.';

	/// en: 'The purchase didn't go through. Try again.'
	String get purchaseFailed => 'The purchase didn\'t go through. Try again.';

	/// en: 'Couldn't reach the store to restore your purchase. Try again.'
	String get restoreFailed => 'Couldn\'t reach the store to restore your purchase. Try again.';

	/// en: 'No PlezyNG lifetime purchase was found for this store account.'
	String get nothingToRestore => 'No PlezyNG lifetime purchase was found for this store account.';
}

// Path: detail
class Translations$detail$en {
	Translations$detail$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Ends at ${time}'
	String endsAt({required Object time}) => 'Ends at ${time}';
}

// Path: watchLink
class Translations$watchLink$en {
	Translations$watchLink$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Couldn't reach a Plex server for this link.'
	String get serverUnavailable => 'Couldn\'t reach a Plex server for this link.';

	/// en: 'Couldn't find this show or movie on your Plex servers.'
	String get notFound => 'Couldn\'t find this show or movie on your Plex servers.';

	/// en: 'This link matches items on more than one server. Add a server to the link.'
	String get ambiguous => 'This link matches items on more than one server. Add a server to the link.';

	/// en: 'Watch links currently support Plex servers only.'
	String get plexOnly => 'Watch links currently support Plex servers only.';

	/// en: 'Watch links can only open a show or a movie.'
	String get unsupportedItem => 'Watch links can only open a show or a movie.';

	/// en: 'Show watch link'
	String get menuItem => 'Show watch link';

	/// en: 'Watch link'
	String get dialogTitle => 'Watch link';

	/// en: 'Opening this link plays the next episode. Add &mode=shuffle to the end to play the show on shuffle.'
	String get dialogShowHint => 'Opening this link plays the next episode. Add &mode=shuffle to the end to play the show on shuffle.';

	/// en: 'Opening this link plays the movie.'
	String get dialogMovieHint => 'Opening this link plays the movie.';

	/// en: 'Copy'
	String get copy => 'Copy';

	/// en: 'Link copied'
	String get copied => 'Link copied';
}

// Path: homeLayout
class Translations$homeLayout$en {
	Translations$homeLayout$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Home layout'
	String get title => 'Home layout';

	/// en: 'Home reset to the original Plezy hero layout'
	String get resetToast => 'Home reset to the original Plezy hero layout';

	/// en: 'Reset hero layout to stock Plezy?'
	String get resetHeroTitle => 'Reset hero layout to stock Plezy?';

	/// en: 'Turns off every row's hero setting and brings back the single rotating banner at the top of Home, like before hero rows existed. Row order and which rows are shown are not affected.'
	String get resetHeroBody => 'Turns off every row\'s hero setting and brings back the single rotating banner at the top of Home, like before hero rows existed. Row order and which rows are shown are not affected.';

	/// en: 'Remove Home row?'
	String get removeRowTitle => 'Remove Home row?';

	/// en: '${title} will be deleted. This can't be undone.'
	String removeRowBody({required Object title}) => '${title} will be deleted. This can\'t be undone.';

	/// en: 'Sync'
	String get sync => 'Sync';

	/// en: 'Sync layout with your Plex account'
	String get syncAccountTitle => 'Sync layout with your Plex account';

	/// en: 'On: this device shares row order, rows, Hero and Auto-slide with your other devices.'
	String get syncAccountOn => 'On: this device shares row order, rows, Hero and Auto-slide with your other devices.';

	/// en: 'Off: this device keeps its own layout.'
	String get syncAccountOff => 'Off: this device keeps its own layout.';

	/// en: 'Sync now'
	String get syncNow => 'Sync now';

	/// en: 'Plex Home manager'
	String get plexHomeManager => 'Plex Home manager';

	/// en: 'Manage Plex rows in Plezy'
	String get managePlexRows => 'Manage Plex rows in Plezy';

	/// en: 'Open to organize the Home-selected rows'
	String get managePlexRowsDescription => 'Open to organize the Home-selected rows';

	/// en: 'Organize Home rows'
	String get organizeHomeRows => 'Organize Home rows';

	/// en: '${n} rows: move, Hero, Auto-slide, remove'
	String organizeHomeRowsDescription({required Object n}) => '${n} rows: move, Hero, Auto-slide, remove';

	/// en: 'Organize ${library} rows'
	String organizeLibraryRows({required Object library}) => 'Organize ${library} rows';

	/// en: 'Continue Watching + ${n} rows: move, Library, Home, Hero, Auto-slide'
	String organizeLibraryRowsDescription({required Object n}) => 'Continue Watching + ${n} rows: move, Library, Home, Hero, Auto-slide';

	/// en: 'Render as a hero card'
	String get renderAsHero => 'Render as a hero card';

	/// en: 'Only available when this row resolves to a single collection's actual titles'
	String get heroOnlySingleCollection => 'Only available when this row resolves to a single collection\'s actual titles';

	/// en: 'Hero'
	String get hero => 'Hero';

	/// en: 'Auto-slide'
	String get autoSlide => 'Auto-slide';

	/// en: 'Also slides on its own every few seconds. Arrows (PC) and d-pad (TV) always work and restart the timer.'
	String get autoSlideDescription => 'Also slides on its own every few seconds. Arrows (PC) and d-pad (TV) always work and restart the timer.';

	/// en: 'Also slides on its own every few seconds. Off: only moves when you click an arrow (PC) or press left/right on the remote (TV). Arrows and d-pad always work either way.'
	String get autoSlideEditDescription => 'Also slides on its own every few seconds. Off: only moves when you click an arrow (PC) or press left/right on the remote (TV). Arrows and d-pad always work either way.';

	/// en: 'Enable Hero first'
	String get enableHeroFirst => 'Enable Hero first';

	/// en: 'Show on Home screen'
	String get showOnHome => 'Show on Home screen';

	/// en: 'Home'
	String get home => 'Home';

	/// en: 'Remove from Home'
	String get removeFromHome => 'Remove from Home';

	/// en: 'Select Home rows below first.'
	String get selectRowsFirst => 'Select Home rows below first.';

	/// en: '${n} Plex-managed rows'
	String plexManagedRows({required Object n}) => '${n} Plex-managed rows';

	/// en: 'Continue Watching'
	String get continueWatching => 'Continue Watching';

	/// en: 'This library's own resume-progress row'
	String get continueWatchingLibraryDescription => 'This library\'s own resume-progress row';

	/// en: 'The resume-progress row shown on Home'
	String get continueWatchingHomeDescription => 'The resume-progress row shown on Home';

	/// en: 'The next unwatched episode row shown separately on Home'
	String get nextUpHomeDescription => 'The next unwatched episode row shown separately on Home';

	/// en: 'Library'
	String get library => 'Library';

	/// en: 'Show in Library Recommended'
	String get showInRecommended => 'Show in Library Recommended';

	/// en: 'Custom Plex row'
	String get customPlexRow => 'Custom Plex row';

	/// en: 'Check Library first — Hero needs somewhere to show'
	String get heroNeedsLibrary => 'Check Library first — Hero needs somewhere to show';

	/// en: 'Check Library or Home first — Hero needs somewhere to show'
	String get heroNeedsSurface => 'Check Library or Home first — Hero needs somewhere to show';

	/// en: 'Remove Hub'
	String get removeHub => 'Remove Hub';

	/// en: 'No Plex-managed rows returned for this library.'
	String get noPlexRows => 'No Plex-managed rows returned for this library.';

	/// en: 'Open details'
	String get openDetails => 'Open details';

	/// en: 'Hero cards'
	String get heroCards => 'Hero cards';

	/// en: 'Tapping a hero card'
	String get tapHeroCard => 'Tapping a hero card';

	/// en: 'TV remote: highlight Play button'
	String get tvPlayFocus => 'TV remote: highlight Play button';

	/// en: 'D-pad down stops on the Play button before moving to the next row. Off skips straight to the next row.'
	String get tvPlayFocusDescription => 'D-pad down stops on the Play button before moving to the next row. Off skips straight to the next row.';

	/// en: 'TV remote: loop hero cards'
	String get tvWrap => 'TV remote: loop hero cards';

	/// en: 'Right on the last card goes back to the first. Off stops at the last card. Left on the first card always goes to the sidebar.'
	String get tvWrapDescription => 'Right on the last card goes back to the first. Off stops at the last card. Left on the first card always goes to the sidebar.';

	/// en: 'Cast on hero banners'
	String get castOnHero => 'Cast on hero banners';

	/// en: 'Shows the cast along the bottom of a hero banner. Off keeps just the title and summary.'
	String get castOnHeroDescription => 'Shows the cast along the bottom of a hero banner. Off keeps just the title and summary.';

	/// en: 'Custom rows'
	String get customRows => 'Custom rows';

	/// en: 'Loading home layout…'
	String get loading => 'Loading home layout…';

	/// en: 'No custom rows yet'
	String get noCustomRows => 'No custom rows yet';

	/// en: 'Use Add Home row to create one.'
	String get addRowHint => 'Use Add Home row to create one.';

	/// en: 'Add Home row'
	String get addHomeRow => 'Add Home row';

	/// en: 'Choose a category; the new row is added to Organizer automatically'
	String get addHomeRowDescription => 'Choose a category; the new row is added to Organizer automatically';

	/// en: 'Remove row'
	String get removeRow => 'Remove row';

	/// en: 'Recently Added'
	String get recentlyAdded => 'Recently Added';

	/// en: 'Recently Released'
	String get recentlyReleased => 'Recently Released';

	/// en: 'Movie Collections'
	String get movieCollections => 'Movie Collections';

	/// en: 'Show Collections'
	String get showCollections => 'Show Collections';

	/// en: 'Row title'
	String get rowTitle => 'Row title';

	/// en: 'Content'
	String get content => 'Content';

	/// en: 'Show this row in:'
	String get showThisRowIn => 'Show this row in:';

	/// en: 'Library Recommended'
	String get libraryRecommended => 'Library Recommended';

	/// en: 'Hero card'
	String get heroCard => 'Hero card';

	/// en: 'Shows as one full-width rotating card instead of a poster shelf.'
	String get heroCardDescription => 'Shows as one full-width rotating card instead of a poster shelf.';

	/// en: 'Only available when this row resolves to a single collection's actual titles — with more than one collection selected there is no single title to rotate through.'
	String get heroUnavailableDescription => 'Only available when this row resolves to a single collection\'s actual titles — with more than one collection selected there is no single title to rotate through.';

	/// en: 'Libraries (leave all unchecked to include every library)'
	String get librariesSelection => 'Libraries (leave all unchecked to include every library)';

	/// en: 'Every library checked here is merged into this one row.'
	String get librariesMergedDescription => 'Every library checked here is merged into this one row.';

	/// en: 'Movie collections (leave all unchecked for every selected library)'
	String get movieCollectionsSelection => 'Movie collections (leave all unchecked for every selected library)';

	/// en: 'Show collections (leave all unchecked for every selected library)'
	String get showCollectionsSelection => 'Show collections (leave all unchecked for every selected library)';

	/// en: 'If exactly one collection matches, its titles show directly in the row. If more than one matches, each collection shows as a single poster — tap it to open that collection.'
	String get collectionRowsDescription => 'If exactly one collection matches, its titles show directly in the row. If more than one matches, each collection shows as a single poster — tap it to open that collection.';

	/// en: 'All collections'
	String get allCollections => 'All collections';

	/// en: 'No rows here yet.'
	String get noRowsHere => 'No rows here yet.';

	/// en: 'Hide watched items in rows'
	String get hideWatchedRows => 'Hide watched items in rows';

	/// en: 'Fully watched titles leave Home and library Recommended rows. In-progress ones stay.'
	String get hideWatchedRowsDescription => 'Fully watched titles leave Home and library Recommended rows. In-progress ones stay.';

	/// en: 'Untitled collection'
	String get untitledCollection => 'Untitled collection';

	/// en: 'Up/Down: move row · Select: drop it here · Back: cancel'
	String get moveRowHint => 'Up/Down: move row · Select: drop it here · Back: cancel';

	/// en: 'Select on a row (or hold Select): move it · Left/Right: row options · Back: done'
	String get organizeRowsHint => 'Select on a row (or hold Select): move it · Left/Right: row options · Back: done';

	/// en: 'Choose rows, libraries, and collection categories'
	String get layoutNavDescription => 'Choose rows, libraries, and collection categories';

	/// en: 'Edit Home row'
	String get editHomeRow => 'Edit Home row';

	/// en: 'Reset hero layout to stock Plezy'
	String get resetHeroButton => 'Reset hero layout to stock Plezy';

	/// en: 'Reordering unlocked'
	String get reorderingUnlocked => 'Reordering unlocked';

	/// en: 'Reordering locked'
	String get reorderingLocked => 'Reordering locked';

	/// en: 'Rows can be dragged — tap the lock to prevent that'
	String get rowsCanBeDragged => 'Rows can be dragged — tap the lock to prevent that';

	/// en: 'Tap the lock to drag rows'
	String get tapLockToDrag => 'Tap the lock to drag rows';

	/// en: 'Custom: ${title}'
	String customRowLabel({required Object title}) => 'Custom: ${title}';

	/// en: '${library}: ${hub}'
	String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';

	/// en: 'Hide'
	String get hide => 'Hide';

	/// en: 'Remove'
	String get remove => 'Remove';

	/// en: 'This library's resume row'
	String get libraryResumeRow => 'This library\'s resume row';

	/// en: 'Press again to delete'
	String get pressAgainToDelete => 'Press again to delete';

	/// en: '${action}: ${state}'
	String actionState({required Object action, required Object state}) => '${action}: ${state}';

	/// en: 'On'
	String get on => 'On';

	/// en: 'Turns off every row's hero setting and brings back the single rotating banner at the top, like before hero rows existed. Row order is kept.'
	String get resetHeroButtonDescription => 'Turns off every row\'s hero setting and brings back the single rotating banner at the top, like before hero rows existed. Row order is kept.';

	/// en: 'Choose whether tapping or selecting a Hero card starts playback or opens its details.'
	String get tapHeroCardDescription => 'Choose whether tapping or selecting a Hero card starts playback or opens its details.';

	/// en: 'Start the selected item right away.'
	String get heroTapPlayDescription => 'Start the selected item right away.';

	/// en: 'Open the selected item’s details before choosing an action.'
	String get heroTapDetailsDescription => 'Open the selected item’s details before choosing an action.';
}

// Path: platform
class Translations$platform$en {
	Translations$platform$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'PlezyNG connects to your media servers and playback devices on your local network.'
	String get localNetworkPermission => 'PlezyNG connects to your media servers and playback devices on your local network.';

	/// en: 'PlezyNG uses location access when iOS requires it to detect your local network and connect to your media servers.'
	String get locationPermission => 'PlezyNG uses location access when iOS requires it to detect your local network and connect to your media servers.';

	/// en: 'Choose images from your photo library to use as media artwork.'
	String get photoLibraryPermission => 'Choose images from your photo library to use as media artwork.';

	/// en: 'Scan QR codes to pair a Companion Remote.'
	String get cameraPermission => 'Scan QR codes to pair a Companion Remote.';
}

// Path: universalMedia
class Translations$universalMedia$en {
	Translations$universalMedia$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Open media'
	String get title => 'Open media';

	/// en: 'Play a link, playlist, or file for this session.'
	String get shortcutHelp => 'Play a link, playlist, or file for this session.';

	/// en: 'Open a link, playlist, or file. Playback uses PlezyNG’s standard player and does not add history to your library.'
	String get intro => 'Open a link, playlist, or file. Playback uses PlezyNG’s standard player and does not add history to your library.';

	/// en: 'What would you like to open?'
	String get openWhat => 'What would you like to open?';

	/// en: 'Stream address'
	String get stream => 'Stream address';

	/// en: 'Playlist'
	String get playlist => 'Playlist';

	/// en: 'Device files'
	String get files => 'Device files';

	/// en: 'Saved stream favorites'
	String get favorites => 'Saved stream favorites';

	/// en: 'Media address'
	String get address => 'Media address';

	/// en: 'HTTPS is preferred. URLs with recognized credential or signature parameters are used only for this session and cannot be saved as favorites.'
	String get addressHelp => 'HTTPS is preferred. URLs with recognized credential or signature parameters are used only for this session and cannot be saved as favorites.';

	/// en: 'Display name (optional)'
	String get displayName => 'Display name (optional)';

	/// en: 'Choose a short name for the player and system media controls.'
	String get displayNameHelp => 'Choose a short name for the player and system media controls.';

	/// en: 'Allow an unencrypted HTTP connection'
	String get allowHttp => 'Allow an unencrypted HTTP connection';

	/// en: 'HTTP does not encrypt the connection. Allow it only on a trusted network. Use HTTPS when possible.'
	String get allowHttpHelp => 'HTTP does not encrypt the connection. Allow it only on a trusted network. Use HTTPS when possible.';

	/// en: 'MPV only: enter an RTSP, RTMP/RTMPS, UDP, or RTP address. These addresses cannot be saved as favorites.'
	String get advancedProtocols => 'MPV only: enter an RTSP, RTMP/RTMPS, UDP, or RTP address. These addresses cannot be saved as favorites.';

	/// en: 'Treat as live'
	String get liveStream => 'Treat as live';

	/// en: 'Use this for live video or radio. The app hides the time bar, skip buttons, and go-to-time option. Turn it off for a recording.'
	String get liveStreamHelp => 'Use this for live video or radio. The app hides the time bar, skip buttons, and go-to-time option. Turn it off for a recording.';

	/// en: 'Only this playback uses the address. Save an eligible stream favorite to keep it in this profile.'
	String get privateSession => 'Only this playback uses the address. Save an eligible stream favorite to keep it in this profile.';

	/// en: 'Save favorite'
	String get saveFavorite => 'Save favorite';

	/// en: 'Play now'
	String get playNow => 'Play now';

	/// en: 'Stream favorite saved to this profile'
	String get favoriteSaved => 'Stream favorite saved to this profile';

	/// en: '(one) {Skipped ${count} unsupported or unsafe playlist entry.} (other) {Skipped ${count} unsupported or unsafe playlist entries.}'
	String skippedEntries({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'Skipped ${count} unsupported or unsafe playlist entry.',
		other: 'Skipped ${count} unsupported or unsafe playlist entries.',
	);

	/// en: 'Playlist address'
	String get playlistAddress => 'Playlist address';

	/// en: 'Open an M3U, M3U8, or PLS playlist from a web address. Direct stream links do not save the playlist.'
	String get playlistAddressHelp => 'Open an M3U, M3U8, or PLS playlist from a web address. Direct stream links do not save the playlist.';

	/// en: 'Choose playlist file'
	String get choosePlaylist => 'Choose playlist file';

	/// en: 'Open playlist'
	String get openPlaylist => 'Open playlist';

	/// en: 'A playlist can contain at most 1,000 items and 2 MB. HLS manifests open as streams so the player can choose a quality.'
	String get playlistFormatsHelp => 'A playlist can contain at most 1,000 items and 2 MB. HLS manifests open as streams so the player can choose a quality.';

	/// en: 'Save queue as playlist'
	String get saveQueuePlaylist => 'Save queue as playlist';

	/// en: 'Playlist saved beside the media files.'
	String get queuePlaylistSaved => 'Playlist saved beside the media files.';

	/// en: 'This queue can’t be saved as a reusable local playlist.'
	String get queuePlaylistUnavailable => 'This queue can’t be saved as a reusable local playlist.';

	/// en: 'Choose a save location in the same folder as the queued files.'
	String get queuePlaylistFolderRequired => 'Choose a save location in the same folder as the queued files.';

	/// en: 'No saved stream favorites yet. Favorites stay in this profile.'
	String get noFavorites => 'No saved stream favorites yet. Favorites stay in this profile.';

	/// en: 'Remove stream favorite'
	String get removeFavorite => 'Remove stream favorite';

	/// en: 'Choose audio, video, or ISO files for a temporary queue. Files and URLs are not added to library history.'
	String get filesHelp => 'Choose audio, video, or ISO files for a temporary queue. Files and URLs are not added to library history.';

	/// en: 'Choose files'
	String get chooseFiles => 'Choose files';

	/// en: '(one) {1 selected file} (other) {${count} selected files}'
	String fileQueue({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '1 selected file',
		other: '${count} selected files',
	);

	/// en: 'Send files over Wi-Fi'
	String get wifiTransfer => 'Send files over Wi-Fi';

	/// en: 'Transfer supported files from a browser on the same trusted network.'
	String get wifiTransferHelp => 'Transfer supported files from a browser on the same trusted network.';

	/// en: 'Open this address in a browser on another device. Choose files to add them to this device’s Files and books library.'
	String get wifiTransferIntro => 'Open this address in a browser on another device. Choose files to add them to this device’s Files and books library.';

	/// en: 'This device receives files over your local network. Anyone who knows this address can send files until you stop the transfer or the address expires after 15 minutes. Maximum: 100 files, 4 GiB per file, 10 GiB total.'
	String get wifiTransferPrivacy => 'This device receives files over your local network. Anyone who knows this address can send files until you stop the transfer or the address expires after 15 minutes. Maximum: 100 files, 4 GiB per file, 10 GiB total.';

	/// en: 'Preparing a private, time-limited transfer…'
	String get wifiTransferStarting => 'Preparing a private, time-limited transfer…';

	/// en: 'Could not start the transfer. Check local-network access and try again.'
	String get wifiTransferUnavailable => 'Could not start the transfer. Check local-network access and try again.';

	/// en: 'Open one of these addresses on the sending device'
	String get openThisAddress => 'Open one of these addresses on the sending device';

	/// en: 'Copy transfer address'
	String get copyAddress => 'Copy transfer address';

	/// en: 'Transfer address copied'
	String get addressCopied => 'Transfer address copied';

	/// en: 'This address expires in ${time}.'
	String transferExpires({required Object time}) => 'This address expires in ${time}.';

	/// en: '(one) {${count} file received} (other) {${count} files received}'
	String uploadCount({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${count} file received',
		other: '${count} files received',
	);

	/// en: 'Received ${size}'
	String uploadedData({required Object size}) => 'Received ${size}';

	/// en: 'Stop transfer and invalidate address'
	String get stopTransfer => 'Stop transfer and invalidate address';

	/// en: 'Start transfer'
	String get startTransfer => 'Start transfer';

	/// en: 'Wi-Fi transfer'
	String get wifiImportedFiles => 'Wi-Fi transfer';

	/// en: 'Send files to PlezyNG'
	String get wifiBrowserTitle => 'Send files to PlezyNG';

	/// en: 'Choose audio, video, ebook, or comic files to send. The files are saved in this device’s Files and books library. Maximum: 100 files, 4 GiB per file, 10 GiB total.'
	String get wifiBrowserIntro => 'Choose audio, video, ebook, or comic files to send. The files are saved in this device’s Files and books library. Maximum: 100 files, 4 GiB per file, 10 GiB total.';

	/// en: 'Files to send'
	String get uploadFilesLabel => 'Files to send';

	/// en: 'Upload selected files'
	String get uploadSelected => 'Upload selected files';

	/// en: 'Choose one or more files first.'
	String get uploadSelectFirst => 'Choose one or more files first.';

	/// en: 'Sending'
	String get uploading => 'Sending';

	/// en: 'File added to PlezyNG.'
	String get uploadComplete => 'File added to PlezyNG.';

	/// en: 'The file could not be added. Keep this page open and try again.'
	String get uploadFailed => 'The file could not be added. Keep this page open and try again.';

	/// en: 'LIVE'
	String get liveCue => 'LIVE';

	/// en: 'Live stream'
	String get liveSession => 'Live stream';

	/// en: 'For live video or radio, the app hides the time bar and skip buttons. It does not save the address or watch history.'
	String get liveCueHelp => 'For live video or radio, the app hides the time bar and skip buttons. It does not save the address or watch history.';

	/// en: 'This playback is session-only'
	String get sessionOnly => 'This playback is session-only';

	/// en: 'Playback never saves progress or history. Save the stream as a favorite to keep it in this profile if it is eligible.'
	String get sessionOnlyHelp => 'Playback never saves progress or history. Save the stream as a favorite to keep it in this profile if it is eligible.';

	/// en: 'Picture adjustments'
	String get pictureAdjustments => 'Picture adjustments';

	/// en: 'These picture changes affect only this playback. They reset when playback ends.'
	String get pictureHelp => 'These picture changes affect only this playback. They reset when playback ends.';

	/// en: 'Reset picture'
	String get resetPicture => 'Reset picture';

	/// en: 'Brightness'
	String get brightness => 'Brightness';

	/// en: 'Contrast'
	String get contrast => 'Contrast';

	/// en: 'Gamma'
	String get gamma => 'Gamma';

	/// en: 'Hue'
	String get hue => 'Hue';

	/// en: 'Saturation'
	String get saturation => 'Saturation';

	/// en: 'Flat view for 360° video'
	String get view360 => 'Flat view for 360° video';

	/// en: 'Use this for equirectangular 360° video. MPV needs FFmpeg’s v360 filter for this view.'
	String get view360Help => 'Use this for equirectangular 360° video. MPV needs FFmpeg’s v360 filter for this view.';

	/// en: 'This mpv build could not apply the 360° filter.'
	String get view360Unavailable => 'This mpv build could not apply the 360° filter.';

	/// en: 'Horizontal view'
	String get view360Yaw => 'Horizontal view';

	/// en: 'Vertical view'
	String get view360Pitch => 'Vertical view';

	/// en: 'Field of view'
	String get view360FieldOfView => 'Field of view';

	/// en: 'Record live stream'
	String get recordStream => 'Record live stream';

	/// en: 'Stop and save recording'
	String get stopRecording => 'Stop and save recording';

	/// en: 'Recording is active. Leaving playback stops and saves the recording.'
	String get recordingStarted => 'Recording is active. Leaving playback stops and saves the recording.';

	/// en: 'Recording finalized and saved.'
	String get recordingSaved => 'Recording finalized and saved.';

	/// en: 'Recording to this device. Leaving playback stops and saves it.'
	String get recordingActive => 'Recording to this device. Leaving playback stops and saves it.';

	/// en: 'For video, choose MKV or MPEG-TS. For audio, choose MKA or MKV.'
	String get recordingFormatHelp => 'For video, choose MKV or MPEG-TS. For audio, choose MKA or MKV.';

	/// en: 'Replace this recording?'
	String get replaceRecordingTitle => 'Replace this recording?';

	/// en: 'PlezyNG backs up the existing file while recording. If it cannot save the new recording, PlezyNG restores the backup.'
	String get replaceRecordingHelp => 'PlezyNG backs up the existing file while recording. If it cannot save the new recording, PlezyNG restores the backup.';

	/// en: 'Replace file'
	String get replaceRecording => 'Replace file';

	/// en: 'Open a disc in this computer’s optical drive. You can also open an ISO image from Device files.'
	String get discHelp => 'Open a disc in this computer’s optical drive. You can also open an ISO image from Device files.';

	/// en: 'Optical disc'
	String get discs => 'Optical disc';

	/// en: 'Edition or disc title'
	String get editionOrTitle => 'Edition or disc title';

	/// en: 'DVD'
	String get dvd => 'DVD';

	/// en: 'Blu-ray'
	String get bluray => 'Blu-ray';

	/// en: 'Audio CD'
	String get audioCd => 'Audio CD';

	/// en: 'Disc playback needs a compatible MPV build, supported drive, and operating-system permission. It cannot bypass commercial disc protection.'
	String get discAvailability => 'Disc playback needs a compatible MPV build, supported drive, and operating-system permission. It cannot bypass commercial disc protection.';

	/// en: 'Convert a local media file'
	String get converterTitle => 'Convert a local media file';

	/// en: 'Convert a local file or remux it with FFmpeg.'
	String get converterHelp => 'Convert a local file or remux it with FFmpeg.';

	/// en: 'Convert a local audio or video file to a format that works on more devices.'
	String get converterIntro => 'Convert a local audio or video file to a format that works on more devices.';

	/// en: 'FFmpeg must be installed on this computer. Conversion reads local files only. It does not download streams or remove DRM.'
	String get converterPrivacy => 'FFmpeg must be installed on this computer. Conversion reads local files only. It does not download streams or remove DRM.';

	/// en: 'Choose a local media file'
	String get converterChooseInput => 'Choose a local media file';

	/// en: 'Output format'
	String get converterFormat => 'Output format';

	/// en: 'MP4 · H.264 and AAC'
	String get converterMp4 => 'MP4 · H.264 and AAC';

	/// en: 'M4A · AAC audio'
	String get converterM4a => 'M4A · AAC audio';

	/// en: 'MP3 · audio'
	String get converterMp3 => 'MP3 · audio';

	/// en: 'Allow FTP'
	String get allowFtp => 'Allow FTP';

	/// en: 'FTP sends media without encryption. Use only on trusted networks.'
	String get allowFtpHelp => 'FTP sends media without encryption. Use only on trusted networks.';

	/// en: 'Save converted media as'
	String get converterSaveAs => 'Save converted media as';

	/// en: 'Choose a filename with the selected output extension.'
	String get converterExtensionMismatch => 'Choose a filename with the selected output extension.';

	/// en: 'Choose an audio or video file.'
	String get converterUnsupportedInput => 'Choose an audio or video file.';

	/// en: 'The selected file is not available as a local device path.'
	String get converterLocalOnly => 'The selected file is not available as a local device path.';

	/// en: 'Replace this file?'
	String get converterReplaceTitle => 'Replace this file?';

	/// en: 'PlezyNG backs up the existing file until the converted copy is saved.'
	String get converterReplaceHelp => 'PlezyNG backs up the existing file until the converted copy is saved.';

	/// en: 'Starting FFmpeg…'
	String get converterStarting => 'Starting FFmpeg…';

	/// en: 'Converting on this computer…'
	String get converterProgress => 'Converting on this computer…';

	/// en: 'Conversion complete. The new file is ready.'
	String get converterComplete => 'Conversion complete. The new file is ready.';

	/// en: 'FFmpeg is missing or does not support this format.'
	String get converterFfmpegMissing => 'FFmpeg is missing or does not support this format.';

	/// en: 'Conversion failed. Check that the source file can be read and the destination has enough free space.'
	String get converterFailed => 'Conversion failed. Check that the source file can be read and the destination has enough free space.';

	/// en: 'Conversion cancelled. The incomplete output was removed.'
	String get converterCancelled => 'Conversion cancelled. The incomplete output was removed.';

	/// en: 'Local conversion is available on desktop computers with FFmpeg installed.'
	String get converterDesktopOnly => 'Local conversion is available on desktop computers with FFmpeg installed.';

	/// en: 'Convert file'
	String get converterStart => 'Convert file';

	/// en: 'Media tools'
	String get mediaToolsTitle => 'Media tools';

	/// en: 'Capture or share media, add search extensions, or use the command line.'
	String get mediaToolsShortcut => 'Capture or share media, add search extensions, or use the command line.';

	/// en: 'Choose a focused tool. Capture and stream-out use FFmpeg installed on this desktop. Extensions and CLI commands use bounded HTTPS requests and the existing Open media flow.'
	String get mediaToolsIntro => 'Choose a focused tool. Capture and stream-out use FFmpeg installed on this desktop. Extensions and CLI commands use bounded HTTPS requests and the existing Open media flow.';

	/// en: 'Tool choices and controls work with touch, pointer, keyboard, and D-pad focus. Recording, sharing, and search status changes are announced.'
	String get mediaToolsAccessibility => 'Tool choices and controls work with touch, pointer, keyboard, and D-pad focus. Recording, sharing, and search status changes are announced.';

	/// en: 'Media tool'
	String get mediaTool => 'Media tool';

	/// en: 'Record your screen or a camera to an MP4 file, or preview a live input in the player. FFmpeg must be installed and include the H.264 encoder for recording.'
	String get captureIntro => 'Record your screen or a camera to an MP4 file, or preview a live input in the player. FFmpeg must be installed and include the H.264 encoder for recording.';

	/// en: 'No screen or camera was found. Check FFmpeg capture support and operating-system privacy permissions.'
	String get captureNoDevices => 'No screen or camera was found. Check FFmpeg capture support and operating-system privacy permissions.';

	/// en: 'Screen or camera'
	String get captureSource => 'Screen or camera';

	/// en: 'Screen'
	String get captureScreen => 'Screen';

	/// en: 'Audio input (optional)'
	String get captureAudioSource => 'Audio input (optional)';

	/// en: 'Add audio from a microphone or available input. Device choices depend on FFmpeg and system permissions.'
	String get captureAudioHelp => 'Add audio from a microphone or available input. Device choices depend on FFmpeg and system permissions.';

	/// en: 'No audio'
	String get captureAudioNone => 'No audio';

	/// en: 'Default audio input'
	String get captureDefaultAudio => 'Default audio input';

	/// en: 'Wayland limits this XWayland capture to the X display. Windows outside XWayland may not appear.'
	String get captureWaylandHelp => 'Wayland limits this XWayland capture to the X display. Windows outside XWayland may not appear.';

	/// en: 'Capture frame rate'
	String get captureFrameRate => 'Capture frame rate';

	/// en: 'The recording is saved only to the file you choose. Microphone capture is optional. PlezyNG does not upload the recording.'
	String get capturePrivacy => 'The recording is saved only to the file you choose. Microphone capture is optional. PlezyNG does not upload the recording.';

	/// en: 'Save screen recording as'
	String get captureSaveAs => 'Save screen recording as';

	/// en: 'Choose a filename ending in .mp4.'
	String get captureExtensionMismatch => 'Choose a filename ending in .mp4.';

	/// en: 'FFmpeg or the H.264 video encoder is unavailable. Install a supported FFmpeg build, then try again.'
	String get captureFfmpegMissing => 'FFmpeg or the H.264 video encoder is unavailable. Install a supported FFmpeg build, then try again.';

	/// en: 'The recording could not be saved. Check device permission, available storage, and FFmpeg support.'
	String get captureFailed => 'The recording could not be saved. Check device permission, available storage, and FFmpeg support.';

	/// en: 'Screen recording saved.'
	String get captureSaved => 'Screen recording saved.';

	/// en: 'Recording time'
	String get captureElapsedLabel => 'Recording time';

	/// en: 'Start recording'
	String get captureStart => 'Start recording';

	/// en: 'Preview in player'
	String get capturePreview => 'Preview in player';

	/// en: 'Preview the selected source in the standard player. It is session-only and does not save a recording. Device support and permissions depend on MPV and the operating system. The preview uses video only; optional audio is included in saved recordings.'
	String get capturePreviewHelp => 'Preview the selected source in the standard player. It is session-only and does not save a recording. Device support and permissions depend on MPV and the operating system. The preview uses video only; optional audio is included in saved recordings.';

	/// en: 'Live preview · not recording'
	String get capturePreviewActive => 'Live preview · not recording';

	/// en: 'Stop and save'
	String get captureStop => 'Stop and save';

	/// en: 'Capture'
	String get captureMode => 'Capture';

	/// en: 'Share'
	String get shareMode => 'Share';

	/// en: 'Send a local media file to another device on your private network. PlezyNG creates a temporary HLS stream.'
	String get shareIntro => 'Send a local media file to another device on your private network. PlezyNG creates a temporary HLS stream.';

	/// en: 'Anyone on your local network who receives the private link can watch while it is active. The link expires after 60 minutes. Stop sharing to close the server and invalidate the link.'
	String get sharePrivacy => 'Anyone on your local network who receives the private link can watch while it is active. The link expires after 60 minutes. Stop sharing to close the server and invalidate the link.';

	/// en: 'Choose media file'
	String get shareChooseFile => 'Choose media file';

	/// en: 'Select a local audio or video file. The file stays on this computer.'
	String get shareChooseHelp => 'Select a local audio or video file. The file stays on this computer.';

	/// en: 'FFmpeg or the H.264/AAC encoders are unavailable. Install FFmpeg with H.264 and AAC encoder support.'
	String get shareFfmpegMissing => 'FFmpeg or the H.264/AAC encoders are unavailable. Install FFmpeg with H.264 and AAC encoder support.';

	/// en: 'The stream could not start or stopped unexpectedly. Check FFmpeg and network access.'
	String get shareFailed => 'The stream could not start or stopped unexpectedly. Check FFmpeg and network access.';

	/// en: 'The stream is ready on your private network.'
	String get shareActive => 'The stream is ready on your private network.';

	/// en: 'The media reached the end and is no longer being shared.'
	String get shareEnded => 'The media reached the end and is no longer being shared.';

	/// en: 'Sharing stopped. The temporary link is no longer valid.'
	String get shareStopped => 'Sharing stopped. The temporary link is no longer valid.';

	/// en: 'Stream address copied.'
	String get shareUrlCopied => 'Stream address copied.';

	/// en: 'Open this address in a player on the other device'
	String get shareOpenUrl => 'Open this address in a player on the other device';

	/// en: 'QR code for the temporary stream address'
	String get shareQrLabel => 'QR code for the temporary stream address';

	/// en: 'Scan with a compatible player connected to the same private network.'
	String get shareQrHelp => 'Scan with a compatible player connected to the same private network.';

	/// en: 'This stream uses unencrypted HTTP. In PlezyNG, allow HTTP before opening it.'
	String get shareHttpHint => 'This stream uses unencrypted HTTP. In PlezyNG, allow HTTP before opening it.';

	/// en: 'Copy stream address'
	String get shareCopyUrl => 'Copy stream address';

	/// en: 'Link expires at'
	String get shareExpiresLabel => 'Link expires at';

	/// en: 'Preparing the stream…'
	String get shareStarting => 'Preparing the stream…';

	/// en: 'Start sharing'
	String get shareStart => 'Start sharing';

	/// en: 'Stop sharing'
	String get shareStop => 'Stop sharing';

	/// en: 'Extensions and CLI'
	String get extensionsMode => 'Extensions and CLI';

	/// en: 'Add a data-only search extension to find media. Choose a result to load it into the familiar Open media form.'
	String get extensionsIntro => 'Add a data-only search extension to find media. Choose a result to load it into the familiar Open media form.';

	/// en: 'A manifest can define one HTTPS search endpoint and map response fields. It cannot run code, add request headers, read files, or launch shell commands.'
	String get extensionsPrivacy => 'A manifest can define one HTTPS search endpoint and map response fields. It cannot run code, add request headers, read files, or launch shell commands.';

	/// en: 'Add extension manifest'
	String get extensionImport => 'Add extension manifest';

	/// en: 'No search services yet. Choose a trusted manifest JSON file to add one.'
	String get extensionEmpty => 'No search services yet. Choose a trusted manifest JSON file to add one.';

	/// en: 'Search service'
	String get extensionChoose => 'Search service';

	/// en: 'Each search sends your words to this HTTPS service. Results open only after you select one.'
	String get extensionSearchConsent => 'Each search sends your words to this HTTPS service. Results open only after you select one.';

	/// en: 'Search media'
	String get extensionSearchLabel => 'Search media';

	/// en: 'Search'
	String get extensionSearch => 'Search';

	/// en: 'Searching…'
	String get extensionSearching => 'Searching…';

	/// en: 'No safe media results were returned. Try another search.'
	String get extensionNoResults => 'No safe media results were returned. Try another search.';

	/// en: 'Add this search service?'
	String get extensionInstallTitle => 'Add this search service?';

	/// en: 'Update this search service?'
	String get extensionReplaceTitle => 'Update this search service?';

	/// en: 'Service'
	String get extensionService => 'Service';

	/// en: 'HTTPS endpoint'
	String get extensionEndpoint => 'HTTPS endpoint';

	/// en: 'Your search text is sent to this service. The manifest contains no executable code. Continue only if you trust this endpoint.'
	String get extensionConsent => 'Your search text is sent to this service. The manifest contains no executable code. Continue only if you trust this endpoint.';

	/// en: 'Add service'
	String get extensionInstall => 'Add service';

	/// en: 'Update service'
	String get extensionReplace => 'Update service';

	/// en: 'Remove this search service?'
	String get extensionRemoveTitle => 'Remove this search service?';

	/// en: 'This removes the service from this profile. PlezyNG does not contact its endpoint.'
	String get extensionRemoveHelp => 'This removes the service from this profile. PlezyNG does not contact its endpoint.';

	/// en: 'Remove service'
	String get extensionRemove => 'Remove service';

	/// en: 'This file is not a supported extension manifest. See the Open media guide for the format.'
	String get extensionInvalidManifest => 'This file is not a supported extension manifest. See the Open media guide for the format.';

	/// en: 'The extension could not be saved to the active profile.'
	String get extensionSaveFailed => 'The extension could not be saved to the active profile.';

	/// en: 'The search service did not return a valid response. Check the endpoint and try again.'
	String get extensionSearchFailed => 'The search service did not return a valid response. Check the endpoint and try again.';

	/// en: 'Command line'
	String get cliTitle => 'Command line';

	/// en: 'Use the plezyctl guide to validate a manifest or search the same extension. Review its HTTPS service before each search. Results open in the existing media form; choose the playback button to start.'
	String get cliHelp => 'Use the plezyctl guide to validate a manifest or search the same extension. Review its HTTPS service before each search. Results open in the existing media form; choose the playback button to start.';

	/// en: 'Copy command example'
	String get cliCopyExample => 'Copy command example';

	/// en: 'Command example copied.'
	String get cliCopied => 'Command example copied.';
}

// Path: fileSources
class Translations$fileSources$en {
	Translations$fileSources$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Files and books'
	String get title => 'Files and books';

	/// en: 'Read, listen, and watch from your own files.'
	String get subtitle => 'Read, listen, and watch from your own files.';

	/// en: 'Add source'
	String get add => 'Add source';

	/// en: 'Import files'
	String get importFiles => 'Import files';

	/// en: 'On this device'
	String get localFiles => 'On this device';

	/// en: 'Source'
	String get source => 'Source';

	/// en: 'Name'
	String get name => 'Name';

	/// en: 'Server URL'
	String get endpoint => 'Server URL';

	/// en: 'Example: smb://nas/Movies'
	String get smbEndpointHint => 'Example: smb://nas/Movies';

	/// en: 'Enter an SMB server and one share.'
	String get smbEndpointInvalid => 'Enter an SMB server and one share.';

	/// en: 'Folder or prefix'
	String get root => 'Folder or prefix';

	/// en: 'Leave blank to use the whole share, or enter a folder within it.'
	String get smbFolderHelp => 'Leave blank to use the whole share, or enter a folder within it.';

	/// en: 'Username'
	String get username => 'Username';

	/// en: 'Domain (optional)'
	String get smbDomain => 'Domain (optional)';

	/// en: 'Password'
	String get password => 'Password';

	/// en: 'API token'
	String get token => 'API token';

	/// en: 'Access key ID'
	String get accessKey => 'Access key ID';

	/// en: 'Secret access key'
	String get secretKey => 'Secret access key';

	/// en: 'Session token (optional)'
	String get sessionToken => 'Session token (optional)';

	/// en: 'Region'
	String get region => 'Region';

	/// en: 'OAuth client ID'
	String get clientId => 'OAuth client ID';

	/// en: 'OAuth client secret (desktop Google only)'
	String get clientSecret => 'OAuth client secret (desktop Google only)';

	/// en: 'Allow unencrypted HTTP on a trusted network'
	String get allowHttp => 'Allow unencrypted HTTP on a trusted network';

	/// en: 'Encrypt SMB3 connection'
	String get smbEncryption => 'Encrypt SMB3 connection';

	/// en: 'Use SMB3 encryption when the NAS supports it.'
	String get smbEncryptionHint => 'Use SMB3 encryption when the NAS supports it.';

	/// en: 'Connect'
	String get connect => 'Connect';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'Close'
	String get close => 'Close';

	/// en: 'Disconnect source'
	String get removeSource => 'Disconnect source';

	/// en: 'Disconnect this source? Downloaded files and your reading and listening history will stay on this device.'
	String get disconnectMessage => 'Disconnect this source? Downloaded files and your reading and listening history will stay on this device.';

	/// en: 'Choose folder'
	String get localFolder => 'Choose folder';

	/// en: 'Nothing here yet'
	String get empty => 'Nothing here yet';

	/// en: 'Add a source or import a book, audiobook, music, or video.'
	String get emptyHint => 'Add a source or import a book, audiobook, music, or video.';

	/// en: 'Search this folder'
	String get search => 'Search this folder';

	/// en: 'Search saved library'
	String get searchCached => 'Search saved library';

	/// en: 'Refresh'
	String get refresh => 'Refresh';

	/// en: 'Load more'
	String get loadMore => 'Load more';

	/// en: 'Available offline'
	String get offline => 'Available offline';

	/// en: 'Keep offline'
	String get download => 'Keep offline';

	/// en: 'Remove offline copy'
	String get removeDownload => 'Remove offline copy';

	/// en: 'Continue reading'
	String get continueReading => 'Continue reading';

	/// en: 'Continue listening'
	String get continueListening => 'Continue listening';

	/// en: 'Continue watching'
	String get continueWatching => 'Continue watching';

	/// en: 'Read'
	String get read => 'Read';

	/// en: 'Listen'
	String get listen => 'Listen';

	/// en: 'Play'
	String get play => 'Play';

	/// en: 'Pause'
	String get pause => 'Pause';

	/// en: 'Stop'
	String get stop => 'Stop';

	/// en: 'Start over'
	String get startOver => 'Start over';

	/// en: 'Finished'
	String get finished => 'Finished';

	/// en: 'Mark finished'
	String get markFinished => 'Mark finished';

	/// en: 'Mark unfinished'
	String get markUnfinished => 'Mark unfinished';

	/// en: 'Editions and files'
	String get editions => 'Editions and files';

	/// en: 'Chapters'
	String get chapters => 'Chapters';

	/// en: 'Bookmarks and notes'
	String get bookmarks => 'Bookmarks and notes';

	/// en: 'Add bookmark'
	String get bookmark => 'Add bookmark';

	/// en: 'Highlight'
	String get highlight => 'Highlight';

	/// en: 'Note'
	String get note => 'Note';

	/// en: 'Delete'
	String get delete => 'Delete';

	/// en: 'Export notes'
	String get export => 'Export notes';

	/// en: 'Notes exported'
	String get exported => 'Notes exported';

	/// en: 'Sync progress'
	String get sync => 'Sync progress';

	/// en: 'Progress synced'
	String get synced => 'Progress synced';

	/// en: 'Another device has a different position. Choose where to continue.'
	String get conflict => 'Another device has a different position. Choose where to continue.';

	/// en: 'Use this device'
	String get useLocal => 'Use this device';

	/// en: 'Use other device'
	String get useRemote => 'Use other device';

	/// en: 'Position history'
	String get history => 'Position history';

	/// en: 'Listen as one audiobook'
	String get groupAudio => 'Listen as one audiobook';

	/// en: 'Combines the audio files currently loaded in this folder. Load all pages first.'
	String get groupHint => 'Combines the audio files currently loaded in this folder. Load all pages first.';

	/// en: 'File order'
	String get order => 'File order';

	/// en: 'Move up'
	String get moveUp => 'Move up';

	/// en: 'Move down'
	String get moveDown => 'Move down';

	/// en: 'Playback speed'
	String get speed => 'Playback speed';

	/// en: 'Sleep timer'
	String get sleep => 'Sleep timer';

	/// en: 'Off'
	String get sleepOff => 'Off';

	/// en: 'End of chapter'
	String get endChapter => 'End of chapter';

	/// en: '(other) {${count: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} minutes} (one) {${count: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} minute}'
	String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutes',
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minute',
	);

	/// en: 'Skip back'
	String get skipBack => 'Skip back';

	/// en: 'Skip forward'
	String get skipForward => 'Skip forward';

	/// en: 'Smart rewind after a pause'
	String get smartRewind => 'Smart rewind after a pause';

	/// en: 'Listening options'
	String get playbackOptions => 'Listening options';

	/// en: '${time} remaining'
	String remaining({required Object time}) => '${time} remaining';

	/// en: 'Contents'
	String get contents => 'Contents';

	/// en: 'Reading settings'
	String get readerSettings => 'Reading settings';

	/// en: 'Text size'
	String get fontSize => 'Text size';

	/// en: 'Line spacing'
	String get lineHeight => 'Line spacing';

	/// en: 'Margins'
	String get margin => 'Margins';

	/// en: 'Typeface'
	String get font => 'Typeface';

	/// en: 'Serif'
	String get serif => 'Serif';

	/// en: 'Sans serif'
	String get sans => 'Sans serif';

	/// en: 'Monospace'
	String get mono => 'Monospace';

	/// en: 'Columns'
	String get columns => 'Columns';

	/// en: 'Scroll vertically'
	String get scroll => 'Scroll vertically';

	/// en: 'Justify text'
	String get justify => 'Justify text';

	/// en: 'Page appearance'
	String get readerTheme => 'Page appearance';

	/// en: 'Follow app theme'
	String get appTheme => 'Follow app theme';

	/// en: 'Paper'
	String get paper => 'Paper';

	/// en: 'Sepia'
	String get sepia => 'Sepia';

	/// en: 'Night'
	String get night => 'Night';

	/// en: 'Read this page aloud'
	String get readAloud => 'Read this page aloud';

	/// en: 'Read along'
	String get readAlong => 'Read along';

	/// en: 'Stop narration'
	String get stopReading => 'Stop narration';

	/// en: 'Search in book'
	String get searchBook => 'Search in book';

	/// en: 'No matches'
	String get noMatches => 'No matches';

	/// en: 'Previous page'
	String get previousPage => 'Previous page';

	/// en: 'Next page'
	String get nextPage => 'Next page';

	/// en: 'Page ${number}'
	String page({required Object number}) => 'Page ${number}';

	/// en: 'External book links are disabled in the reader.'
	String get externalBlocked => 'External book links are disabled in the reader.';

	/// en: 'Opening…'
	String get loading => 'Opening…';

	/// en: 'Narrator'
	String get narrator => 'Narrator';

	/// en: 'Audio'
	String get audio => 'Audio';

	/// en: 'Video'
	String get video => 'Video';

	/// en: 'Ebooks'
	String get ebooks => 'Ebooks';

	/// en: 'All'
	String get all => 'All';

	/// en: 'Offline files'
	String get downloads => 'Offline files';

	/// en: 'Remove the selected offline copy? Your position and notes will stay.'
	String get confirmDelete => 'Remove the selected offline copy? Your position and notes will stay.';

	/// en: 'Sign in again to reconnect this source.'
	String get errorAuthentication => 'Sign in again to reconnect this source.';

	/// en: 'This source did not grant access to the requested file.'
	String get errorPermission => 'This source did not grant access to the requested file.';

	/// en: 'The source is unavailable. Try again, or open an offline copy.'
	String get errorUnavailable => 'The source is unavailable. Try again, or open an offline copy.';

	/// en: 'This format or connection is not supported on this device. Check the source setup guide.'
	String get errorUnsupported => 'This format or connection is not supported on this device. Check the source setup guide.';

	/// en: 'This file or server response could not be read safely.'
	String get errorInvalidData => 'This file or server response could not be read safely.';

	/// en: 'The operation was cancelled.'
	String get errorCancelled => 'The operation was cancelled.';

	/// en: 'The position changed in another session. Reopen the item to choose a position.'
	String get errorConflict => 'The position changed in another session. Reopen the item to choose a position.';

	/// en: 'Sign in'
	String get signIn => 'Sign in';

	/// en: 'Reconnect'
	String get reconnect => 'Reconnect';

	/// en: 'Leave blank to start at the source root. S3 URLs include the bucket.'
	String get folderHelp => 'Leave blank to start at the source root. S3 URLs include the bucket.';

	/// en: 'Preferences'
	String get preferences => 'Preferences';

	/// en: 'Position'
	String get timePosition => 'Position';

	/// en: 'Audio track'
	String get audioTrack => 'Audio track';

	/// en: 'Subtitle track'
	String get subtitleTrack => 'Subtitle track';

	/// en: 'None'
	String get none => 'None';

	/// en: 'Full screen'
	String get fullscreen => 'Full screen';

	/// en: 'Progress sync folder (optional)'
	String get syncLocation => 'Progress sync folder (optional)';

	/// en: 'A dedicated WebDAV folder for PlezyNG state. Uses conditional writes; media stays unchanged.'
	String get syncLocationHint => 'A dedicated WebDAV folder for PlezyNG state. Uses conditional writes; media stays unchanged.';

	/// en: 'Audiobooks'
	String get audiobooks => 'Audiobooks';

	/// en: 'Comics'
	String get comics => 'Comics';

	/// en: 'Scan for books and media'
	String get scan => 'Scan for books and media';

	/// en: 'Open reader'
	String get browserReader => 'Open reader';

	/// en: 'The reader is open in your browser. Keep PlezyNG open to save your place and notes.'
	String get browserReaderHelp => 'The reader is open in your browser. Keep PlezyNG open to save your place and notes.';

	/// en: 'On'
	String get on => 'On';

	/// en: 'App registration'
	String get advancedSetup => 'App registration';

	/// en: 'Sign in with Microsoft'
	String get microsoftSignIn => 'Sign in with Microsoft';

	/// en: 'Zoom in'
	String get zoomIn => 'Zoom in';

	/// en: 'Zoom out'
	String get zoomOut => 'Zoom out';

	/// en: 'Fit page'
	String get fitPage => 'Fit page';

	/// en: 'Fit width'
	String get fitWidth => 'Fit width';

	/// en: 'Actual size'
	String get actualSize => 'Actual size';

	/// en: 'Go to page'
	String get goToPage => 'Go to page';

	/// en: 'Go to chapter'
	String get goToSection => 'Go to chapter';

	/// en: 'Enter a number from 1 to $count'
	String pageRange({required Object count}) => 'Enter a number from 1 to ${count}';

	/// en: 'Page layout'
	String get pageLayout => 'Page layout';

	/// en: 'Automatic'
	String get automatic => 'Automatic';

	/// en: 'Single page'
	String get singlePage => 'Single page';

	/// en: 'Two pages'
	String get twoPages => 'Two pages';

	/// en: 'Reading direction'
	String get readingDirection => 'Reading direction';

	/// en: 'Left to right'
	String get leftToRight => 'Left to right';

	/// en: 'Right to left'
	String get rightToLeft => 'Right to left';

	/// en: 'Letter spacing'
	String get letterSpacing => 'Letter spacing';

	/// en: 'Word spacing'
	String get wordSpacing => 'Word spacing';

	/// en: 'Pinch or use zoom controls to enlarge pages. Drag to pan. Ctrl/⌘ + or − adjusts zoom; Ctrl/⌘ 0 resets it. Page Up and Page Down turn pages.'
	String get readerControlsHelp => 'Pinch or use zoom controls to enlarge pages. Drag to pan. Ctrl/⌘ + or − adjusts zoom; Ctrl/⌘ 0 resets it. Page Up and Page Down turn pages.';

	/// en: 'Comic page'
	String get imagePage => 'Comic page';

	/// en: 'Reset reading preferences'
	String get resetReader => 'Reset reading preferences';

	/// en: 'Zoom'
	String get zoom => 'Zoom';

	/// en: 'Use files and books'
	String get useFiles => 'Use files and books';

	/// en: 'Cancel scan'
	String get cancelScan => 'Cancel scan';

	/// en: 'Google Drive'
	String get googleDrive => 'Google Drive';

	/// en: 'Offline download limit'
	String get offlineQuota => 'Offline download limit';

	/// en: 'Set the maximum space used by offline copies, imported files, and queued downloads. Lowering the limit does not remove existing copies.'
	String get offlineQuotaHelp => 'Set the maximum space used by offline copies, imported files, and queued downloads. Lowering the limit does not remove existing copies.';

	/// en: 'Offline storage'
	String get offlineStorageUsage => 'Offline storage';

	/// en: 'reserved'
	String get reservedStorage => 'reserved';

	/// en: 'Download queue'
	String get downloadQueue => 'Download queue';

	/// en: 'Downloading'
	String get downloadRunning => 'Downloading';

	/// en: 'Waiting'
	String get downloadQueued => 'Waiting';

	/// en: 'Paused'
	String get downloadPaused => 'Paused';

	/// en: 'Needs retry'
	String get downloadFailed => 'Needs retry';

	/// en: 'Importing'
	String get importing => 'Importing';

	/// en: 'Import interrupted · remove to clear'
	String get importInterrupted => 'Import interrupted · remove to clear';

	/// en: 'The offline storage limit was reached. Raise the limit or remove a downloaded copy.'
	String get errorQuotaExceeded => 'The offline storage limit was reached. Raise the limit or remove a downloaded copy.';

	/// en: 'There is not enough free device storage to keep the protected reserve.'
	String get errorStorageLow => 'There is not enough free device storage to keep the protected reserve.';

	/// en: 'PlezyNG could not check free device storage, so the write was stopped.'
	String get errorStorageUnavailable => 'PlezyNG could not check free device storage, so the write was stopped.';

	/// en: 'Remove download'
	String get removeDownloadJob => 'Remove download';

	/// en: 'This download finished before it could be removed. The item is now available offline.'
	String get downloadAlreadyComplete => 'This download finished before it could be removed. The item is now available offline.';

	/// en: 'Remove this download and discard any partially downloaded data? Your position and notes will stay.'
	String get confirmRemoveDownloadJob => 'Remove this download and discard any partially downloaded data? Your position and notes will stay.';
}

// Path: lending
class Translations$lending$en {
	Translations$lending$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Public libraries'
	String get title => 'Public libraries';

	/// en: 'Add a library'
	String get add => 'Add a library';

	/// en: 'Another library'
	String get other => 'Another library';

	/// en: 'Library name'
	String get libraryName => 'Library name';

	/// en: 'Library website'
	String get libraryUrl => 'Library website';

	/// en: 'Use your library’s catalogue or sign-in page.'
	String get libraryUrlHint => 'Use your library’s catalogue or sign-in page.';

	/// en: 'Borrow from your library. Keep your books close.'
	String get intro => 'Borrow from your library. Keep your books close.';

	/// en: 'Sign in, borrow and read securely with your library’s own service.'
	String get handoff => 'Sign in, borrow and read securely with your library’s own service.';

	/// en: 'Open library'
	String get openService => 'Open library';

	/// en: 'Find a library'
	String get findLibrary => 'Find a library';

	/// en: 'Search books and authors'
	String get search => 'Search books and authors';

	/// en: 'Catalogue'
	String get catalogue => 'Catalogue';

	/// en: 'Loans'
	String get loans => 'Loans';

	/// en: 'Holds'
	String get holds => 'Holds';

	/// en: 'Sign in with your library'
	String get signIn => 'Sign in with your library';

	/// en: 'Finish signing in in your browser, then return here.'
	String get waiting => 'Finish signing in in your browser, then return here.';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Remove library'
	String get disconnect => 'Remove library';

	/// en: 'Remove this library from this profile? Your loans and holds stay with your library.'
	String get disconnectMessage => 'Remove this library from this profile? Your loans and holds stay with your library.';

	/// en: 'Get book'
	String get getBook => 'Get book';

	/// en: 'Check availability'
	String get checkAvailability => 'Check availability';

	/// en: 'Available to borrow'
	String get available => 'Available to borrow';

	/// en: 'Currently unavailable'
	String get unavailable => 'Currently unavailable';

	/// en: 'Borrow'
	String get borrow => 'Borrow';

	/// en: 'Place hold'
	String get placeHold => 'Place hold';

	/// en: 'Return early'
	String get returnBook => 'Return early';

	/// en: 'Cancel hold'
	String get cancelHold => 'Cancel hold';

	/// en: 'Borrow this title from your library?'
	String get confirmBorrow => 'Borrow this title from your library?';

	/// en: 'Return this title now? You may need to borrow it again to continue.'
	String get confirmReturn => 'Return this title now? You may need to borrow it again to continue.';

	/// en: 'Remove your hold on this title?'
	String get confirmCancelHold => 'Remove your hold on this title?';

	/// en: 'Hold notification email'
	String get email => 'Hold notification email';

	/// en: 'Due $date'
	String due({required Object date}) => 'Due ${date}';

	/// en: 'Position $position in line'
	String queue({required Object position}) => 'Position ${position} in line';

	/// en: 'No titles here yet.'
	String get empty => 'No titles here yet.';

	/// en: 'Explore Open Library’s catalogue. Reading and borrowing options are shown on each title’s page.'
	String get openLibraryNote => 'Explore Open Library’s catalogue. Reading and borrowing options are shown on each title’s page.';

	/// en: 'Load more'
	String get more => 'Load more';

	/// en: 'Library sign-in service'
	String get gateway => 'Library sign-in service';

	/// en: 'Provided by your library or the PlezyNG administrator.'
	String get gatewayHint => 'Provided by your library or the PlezyNG administrator.';

	/// en: 'Library integration'
	String get advanced => 'Library integration';

	/// en: 'Choose your library'
	String get loadLibraries => 'Choose your library';

	/// en: 'This loan has expired.'
	String get expired => 'This loan has expired.';

	/// en: 'Library updated'
	String get updated => 'Library updated';

	/// en: 'Continue in service'
	String get continueService => 'Continue in service';

	/// en: 'In-app borrowing · Coming soon'
	String get comingSoon => 'In-app borrowing · Coming soon';

	/// en: 'Libby integration is on its way. You can use your library in Libby while we finish connecting it.'
	String get comingSoonDescription => 'Libby integration is on its way. You can use your library in Libby while we finish connecting it.';

	/// en: 'Suspend hold'
	String get suspendHold => 'Suspend hold';

	/// en: 'Resume hold'
	String get resumeHold => 'Resume hold';

	/// en: 'Keep your place in line and let the next reader borrow this copy? You can resume the hold later.'
	String get suspendMessage => 'Keep your place in line and let the next reader borrow this copy? You can resume the hold later.';

	/// en: 'Resume this hold so your library can offer you the next available copy?'
	String get resumeMessage => 'Resume this hold so your library can offer you the next available copy?';

	/// en: 'Change notification email'
	String get editEmail => 'Change notification email';
}

// Path: audiobook
class Translations$audiobook$en {
	Translations$audiobook$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Reading & listening sync'
	String get syncTitle => 'Reading & listening sync';

	/// en: 'Keep reading positions, listening positions, completion state, bookmarks and notes across your devices. Choose an attached storage account and use the same sync code on each device. Reading and listening remain separate.'
	String get syncHelp => 'Keep reading positions, listening positions, completion state, bookmarks and notes across your devices. Choose an attached storage account and use the same sync code on each device. Reading and listening remain separate.';

	/// en: 'Add Google Drive, OneDrive, Dropbox, WebDAV or S3 in Files & books first.'
	String get addSyncSource => 'Add Google Drive, OneDrive, Dropbox, WebDAV or S3 in Files & books first.';

	/// en: 'Sync storage account'
	String get syncDestination => 'Sync storage account';

	/// en: 'Sync folder or prefix'
	String get syncFolder => 'Sync folder or prefix';

	/// en: 'Choose a separate existing WebDAV folder or a dedicated S3 prefix for app-owned state files. Playback media is never uploaded, replaced, renamed or deleted.'
	String get syncFolderHelp => 'Choose a separate existing WebDAV folder or a dedicated S3 prefix for app-owned state files. Playback media is never uploaded, replaced, renamed or deleted.';

	/// en: 'Private sync code'
	String get syncCode => 'Private sync code';

	/// en: 'Create a code on your first device, then enter that code on your other devices. Keep a private copy: it is the key to your encrypted state. Use a different code for each person.'
	String get syncCodeHelp => 'Create a code on your first device, then enter that code on your other devices. Keep a private copy: it is the key to your encrypted state. Use a different code for each person.';

	/// en: 'Show or hide sync code'
	String get showCode => 'Show or hide sync code';

	/// en: 'Create a new sync code'
	String get newSyncCode => 'Create a new sync code';

	/// en: 'Save and sync'
	String get saveSync => 'Save and sync';

	/// en: 'Turn off sync on this device'
	String get disableSync => 'Turn off sync on this device';

	/// en: 'Removing this source will turn off reading and listening sync here. Encrypted sync files will remain in the provider.'
	String get syncSourceDisconnect => 'Removing this source will turn off reading and listening sync here. Encrypted sync files will remain in the provider.';

	/// en: 'Reconnect storage account'
	String get syncReconnect => 'Reconnect storage account';

	/// en: 'Last synced at $time'
	String lastSynced({required Object time}) => 'Last synced at ${time}';

	/// en: 'Cloud sync writes encrypted progress, completion, bookmark and note data to app-owned sync files. Playback media is never uploaded, replaced, renamed or deleted. Account tokens and passwords are not uploaded. Google Drive and OneDrive use app storage; Dropbox uses PlezyNG Sync; WebDAV and S3 use the chosen folder or prefix. Enabling sync may require provider write permission, but the app writes only those state files. Cloud sync and compatible server progress/bookmark sync run independently with separate retries. Conflicts are shown for you to resolve. Turning sync off keeps local history and remote state.'
	String get syncPrivacy => 'Cloud sync writes encrypted progress, completion, bookmark and note data to app-owned sync files. Playback media is never uploaded, replaced, renamed or deleted. Account tokens and passwords are not uploaded. Google Drive and OneDrive use app storage; Dropbox uses PlezyNG Sync; WebDAV and S3 use the chosen folder or prefix. Enabling sync may require provider write permission, but the app writes only those state files. Cloud sync and compatible server progress/bookmark sync run independently with separate retries. Conflicts are shown for you to resolve. Turning sync off keeps local history and remote state.';

	/// en: 'Choose where to resume'
	String get syncConflicts => 'Choose where to resume';

	/// en: 'These changes were made independently. Choose the position or bookmark version to keep. A later timestamp or a higher percentage does not automatically win.'
	String get conflictHelp => 'These changes were made independently. Choose the position or bookmark version to keep. A later timestamp or a higher percentage does not automatically win.';

	/// en: 'Device $device'
	String syncDevice({required Object device}) => 'Device ${device}';

	/// en: 'unknown device'
	String get syncUnknownDevice => 'unknown device';

	/// en: 'Deleted bookmark'
	String get deletedBookmark => 'Deleted bookmark';

	/// en: 'Finished'
	String get finished => 'Finished';

	/// en: 'Reading · $percent%'
	String readingPosition({required Object percent}) => 'Reading · ${percent}%';

	/// en: 'Chapter progress'
	String get chapterTimeline => 'Chapter progress';

	/// en: 'Whole book progress'
	String get bookTimeline => 'Whole book progress';

	/// en: 'Time remaining in this book: ${time}'
	String bookRemaining({required Object time}) => 'Time remaining in this book: ${time}';

	/// en: 'Time remaining in this chapter: ${time}'
	String chapterRemaining({required Object time}) => 'Time remaining in this chapter: ${time}';

	/// en: 'Total time available as parts are played'
	String get unknownRemaining => 'Total time available as parts are played';

	/// en: 'Undo last seek'
	String get undoSeek => 'Undo last seek';

	/// en: 'Custom playback speed'
	String get customSpeed => 'Custom playback speed';

	/// en: 'Choose a speed from 0.25× to 4×.'
	String get speedHelp => 'Choose a speed from 0.25× to 4×.';

	/// en: 'Apply'
	String get apply => 'Apply';

	/// en: 'Custom sleep timer'
	String get customSleep => 'Custom sleep timer';

	/// en: 'Minutes (1–1440)'
	String get sleepMinutes => 'Minutes (1–1440)';

	/// en: 'Stop after $count chapters'
	String sleepChapters({required Object count}) => 'Stop after ${count} chapters';

	/// en: 'Add 5 minutes'
	String get extendSleep => 'Add 5 minutes';

	/// en: 'Sleep timer: $time'
	String sleepRemaining({required Object time}) => 'Sleep timer: ${time}';

	/// en: 'Use these listening controls for new books'
	String get useDefaults => 'Use these listening controls for new books';

	/// en: 'Sort books'
	String get librarySort => 'Sort books';

	/// en: 'Title'
	String get sortTitle => 'Title';

	/// en: 'Author'
	String get sortAuthor => 'Author';

	/// en: 'Narrator'
	String get sortNarrator => 'Narrator';

	/// en: 'Series order'
	String get sortSeries => 'Series order';

	/// en: 'Recently opened'
	String get sortRecent => 'Recently opened';

	/// en: 'Reading status'
	String get statusFilter => 'Reading status';

	/// en: 'All books'
	String get statusAll => 'All books';

	/// en: 'Not started'
	String get statusNew => 'Not started';

	/// en: 'In progress'
	String get statusProgress => 'In progress';

	/// en: 'Finished'
	String get statusFinished => 'Finished';

	/// en: 'Go to time'
	String get goToTime => 'Go to time';

	/// en: 'Hours:minutes:seconds, or minutes:seconds'
	String get timeHelp => 'Hours:minutes:seconds, or minutes:seconds';

	/// en: 'Export a recent encrypted copy before moving or repairing sync data. Imports merge with current state; they never replace local sync history. Keep the sync code separately.'
	String get recoveryHelp => 'Export a recent encrypted copy before moving or repairing sync data. Imports merge with current state; they never replace local sync history. Keep the sync code separately.';

	/// en: 'Export encrypted recovery file'
	String get recoveryExport => 'Export encrypted recovery file';

	/// en: 'Import encrypted recovery file'
	String get recoveryImport => 'Import encrypted recovery file';

	/// en: 'Merge this encrypted recovery file with current reading positions and notes? Existing history will be retained. Shared library and item IDs are not included; set matching IDs on every device before importing.'
	String get recoveryImportConfirm => 'Merge this encrypted recovery file with current reading positions and notes? Existing history will be retained. Shared library and item IDs are not included; set matching IDs on every device before importing.';

	/// en: 'Encrypted recovery file saved.'
	String get recoveryExported => 'Encrypted recovery file saved.';

	/// en: 'Recovery data merged.'
	String get recoveryImported => 'Recovery data merged.';
}

// Path: sourceSetup
class Translations$sourceSetup$en {
	Translations$sourceSetup$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Saved server certificate'
	String get savedCertificate => 'Saved server certificate';

	/// en: 'Project Gutenberg'
	String get projectGutenberg => 'Project Gutenberg';

	/// en: 'Enter an NFS URL such as nfs://nas:2049/export.'
	String get nfsEndpointInvalid => 'Enter an NFS URL such as nfs://nas:2049/export.';

	/// en: 'No DLNA servers found. Enter the device description URL manually.'
	String get dlnaNone => 'No DLNA servers found. Enter the device description URL manually.';

	/// en: 'DLNA media servers'
	String get dlnaServers => 'DLNA media servers';

	/// en: 'DLNA discovery is unavailable on this network. Enter the device description URL manually.'
	String get dlnaUnavailable => 'DLNA discovery is unavailable on this network. Enter the device description URL manually.';

	/// en: 'Searching local network for DLNA servers'
	String get dlnaSearching => 'Searching local network for DLNA servers';

	/// en: 'Searching local network…'
	String get networkSearching => 'Searching local network…';

	/// en: 'Discover DLNA servers'
	String get dlnaDiscover => 'Discover DLNA servers';

	/// en: 'Discovery depends on local-network multicast. If no server appears, enter its device description URL above.'
	String get dlnaHelp => 'Discovery depends on local-network multicast. If no server appears, enter its device description URL above.';

	/// en: 'DLNA object ID; blank uses the device root.'
	String get dlnaRoot => 'DLNA object ID; blank uses the device root.';

	/// en: 'Enter a password or add a private key below.'
	String get passwordOrKey => 'Enter a password or add a private key below.';

	/// en: 'SSH host key SHA256 fingerprint'
	String get sshFingerprint => 'SSH host key SHA256 fingerprint';

	/// en: 'Verify with the server administrator. On the server, run ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub and use its SHA256 value.'
	String get sshFingerprintHelp => 'Verify with the server administrator. On the server, run ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub and use its SHA256 value.';

	/// en: 'Leave blank to keep the current pin, or enter a new server fingerprint.'
	String get sshFingerprintKeep => 'Leave blank to keep the current pin, or enter a new server fingerprint.';

	/// en: 'SSH public key authentication'
	String get sshAuthentication => 'SSH public key authentication';

	/// en: 'Optional; password authentication is also supported.'
	String get sshAuthenticationHelp => 'Optional; password authentication is also supported.';

	/// en: 'Private key (PEM or OpenSSH format)'
	String get privateKey => 'Private key (PEM or OpenSSH format)';

	/// en: 'Private key passphrase'
	String get privateKeyPassphrase => 'Private key passphrase';

	/// en: 'NFS mount service TCP port'
	String get nfsMountPort => 'NFS mount service TCP port';

	/// en: 'Default: 20048'
	String get nfsMountPortHelp => 'Default: 20048';

	/// en: 'NFS user ID (AUTH_SYS)'
	String get nfsUserId => 'NFS user ID (AUTH_SYS)';

	/// en: 'Default: 1000. Use the ID the NAS export allows.'
	String get nfsUserIdHelp => 'Default: 1000. Use the ID the NAS export allows.';

	/// en: 'NFS group ID (AUTH_SYS)'
	String get nfsGroupId => 'NFS group ID (AUTH_SYS)';

	/// en: 'Default: 1000. Use the group ID the NAS export allows.'
	String get nfsGroupIdHelp => 'Default: 1000. Use the group ID the NAS export allows.';

	/// en: 'Require encrypted NFS (RPC-with-TLS)'
	String get nfsEncryption => 'Require encrypted NFS (RPC-with-TLS)';

	/// en: 'Require TLS 1.3 for NFS and the mount service. Connections fail closed if the NAS does not support it.'
	String get nfsEncryptionHelp => 'Require TLS 1.3 for NFS and the mount service. Connections fail closed if the NAS does not support it.';

	/// en: 'Custom NFS CA or server certificate (PEM, optional)'
	String get nfsTrustCertificate => 'Custom NFS CA or server certificate (PEM, optional)';

	/// en: 'Leave blank for certificates trusted by this device. Add a private CA or self-signed server certificate when needed; its names must match the NFS URL host.'
	String get nfsTrustHelp => 'Leave blank for certificates trusted by this device. Add a private CA or self-signed server certificate when needed; its names must match the NFS URL host.';

	/// en: 'Use a CA or server certificate in PEM format. Do not include a private key.'
	String get nfsTrustInvalid => 'Use a CA or server certificate in PEM format. Do not include a private key.';

	/// en: 'Add custom trust certificate'
	String get addTrustCertificate => 'Add custom trust certificate';

	/// en: 'Replace saved custom certificate'
	String get replaceTrustCertificate => 'Replace saved custom certificate';

	/// en: 'RPC-with-TLS uses the usual NFS and mount service ports and requires NAS support for RFC 9289. TLS 1.3 is required. The host name or IP must match the certificate. AUTH_SYS UID/GID still apply inside the encrypted channel.'
	String get nfsTlsHelp => 'RPC-with-TLS uses the usual NFS and mount service ports and requires NAS support for RFC 9289. TLS 1.3 is required. The host name or IP must match the certificate. AUTH_SYS UID/GID still apply inside the encrypted channel.';

	/// en: 'Client certificate (optional)'
	String get clientCertificate => 'Client certificate (optional)';

	/// en: 'Lets the NAS authenticate this client; AUTH_SYS IDs still depend on NAS export policy.'
	String get clientCertificateHelp => 'Lets the NAS authenticate this client; AUTH_SYS IDs still depend on NAS export policy.';

	/// en: 'A saved client identity will be used.'
	String get savedIdentity => 'A saved client identity will be used.';

	/// en: 'Replace saved client identity'
	String get replaceIdentity => 'Replace saved client identity';

	/// en: 'Choose PKCS#12 client identity'
	String get chooseIdentity => 'Choose PKCS#12 client identity';

	/// en: 'Client identity passphrase'
	String get identityPassphrase => 'Client identity passphrase';

	/// en: 'Leave blank if the file has no passphrase.'
	String get identityPassphraseHelp => 'Leave blank if the file has no passphrase.';

	/// en: 'Remove any saved client identity'
	String get removeIdentity => 'Remove any saved client identity';

	/// en: 'Client identities are saved in the encrypted source credential store. Leave this section unchanged to keep the saved identity.'
	String get identityStorageHelp => 'Client identities are saved in the encrypted source credential store. Leave this section unchanged to keep the saved identity.';

	/// en: 'Read-only NFSv3 over TCP. Without RPC-with-TLS, NFS traffic is unencrypted. The NAS must allow the selected AUTH_SYS IDs and unprivileged client ports (often called the “insecure” export option). NFSv4 and UDP are not supported.'
	String get nfsLimitations => 'Read-only NFSv3 over TCP. Without RPC-with-TLS, NFS traffic is unencrypted. The NAS must allow the selected AUTH_SYS IDs and unprivileged client ports (often called the “insecure” export option). NFSv4 and UDP are not supported.';

	/// en: 'NFS setup help'
	String get nfsSetupHelp => 'NFS setup help';

	/// en: 'Check these settings if the connection does not open.'
	String get nfsSetupHint => 'Check these settings if the connection does not open.';

	/// en: 'Use an NFSv3 TCP export. The NFS service and mount service must both support RPC-with-TLS when encryption is required. Leave the custom certificate blank for a server certificate trusted by this device, or add the NAS CA/self-signed certificate. The certificate name must match the host in the endpoint. If the NAS asks for mutual TLS, add its PKCS#12 client identity. Finally, confirm the export allows the configured AUTH_SYS UID/GID and the client port policy.'
	String get nfsSetupDetails => 'Use an NFSv3 TCP export. The NFS service and mount service must both support RPC-with-TLS when encryption is required. Leave the custom certificate blank for a server certificate trusted by this device, or add the NAS CA/self-signed certificate. The certificate name must match the host in the endpoint. If the NAS asks for mutual TLS, add its PKCS#12 client identity. Finally, confirm the export allows the configured AUTH_SYS UID/GID and the client port policy.';

	/// en: 'FTP uses passive mode. Use ftp:// for plain FTP, ftpes:// for explicit TLS, or ftps:// for TLS (implicit on port 990; explicit on other ports).'
	String get ftpHelp => 'FTP uses passive mode. Use ftp:// for plain FTP, ftpes:// for explicit TLS, or ftps:// for TLS (implicit on port 990; explicit on other ports).';

	/// en: 'OpenSubtitles'
	String get openSubtitles => 'OpenSubtitles';

	/// en: 'Optional subtitle search for standalone videos.'
	String get subtitleSetup => 'Optional subtitle search for standalone videos.';

	/// en: 'API key'
	String get apiKey => 'API key';

	/// en: 'Account username (optional)'
	String get optionalUsername => 'Account username (optional)';

	/// en: 'Account password (optional)'
	String get optionalPassword => 'Account password (optional)';

	/// en: 'Get an API key from opensubtitles.com. Search sends the video title and available IMDb/TMDB IDs, never the video file. The key and optional account credentials are encrypted with this source.'
	String get subtitlePrivacy => 'Get an API key from opensubtitles.com. Search sends the video title and available IMDb/TMDB IDs, never the video file. The key and optional account credentials are encrypted with this source.';

	/// en: 'Automatic online video metadata'
	String get automaticMetadata => 'Automatic online video metadata';

	/// en: 'Sends only filename title/year and episode numbers or an NFO ID, never media or credentials. NFO fields stay authoritative.'
	String get metadataPrivacy => 'Sends only filename title/year and episode numbers or an NFO ID, never media or credentials. NFO fields stay authoritative.';

	/// en: 'For encrypted NFS, check RFC 9289 and TLS 1.3 support on both NAS services, the certificate name, and the export UID/GID. PlezyNG will not retry this connection without encryption.'
	String get nfsEncryptionFailure => 'For encrypted NFS, check RFC 9289 and TLS 1.3 support on both NAS services, the certificate name, and the export UID/GID. PlezyNG will not retry this connection without encryption.';

	/// en: 'Connecting to source'
	String get sourceConnecting => 'Connecting to source';

	/// en: 'This title search goes to Trakt. It sends the title you enter, not the video or source credentials.'
	String get metadataSearchPrivacy => 'This title search goes to Trakt. It sends the title you enter, not the video or source credentials.';

	/// en: 'Choose a match'
	String get chooseMatch => 'Choose a match';

	/// en: 'Review the title and year before choosing. Trakt receives the search title; the video stays on its source.'
	String get metadataMatchHelp => 'Review the title and year before choosing. Trakt receives the search title; the video stays on its source.';

	/// en: 'No online title matches were found. Try a different title.'
	String get metadataNoMatches => 'No online title matches were found. Try a different title.';

	/// en: 'Search online metadata'
	String get metadataSearch => 'Search online metadata';

	/// en: 'Looking up online movie and TV details…'
	String get metadataLoading => 'Looking up online movie and TV details…';

	/// en: 'Online metadata from Trakt'
	String get metadataFromTrakt => 'Online metadata from Trakt';

	/// en: 'No automatic title match was found. Search for the title to choose a match.'
	String get metadataNoAutomaticMatch => 'No automatic title match was found. Search for the title to choose a match.';

	/// en: 'Online metadata could not be loaded. Playback and local details are still available.'
	String get metadataFailed => 'Online metadata could not be loaded. Playback and local details are still available.';

	/// en: 'Loading video details'
	String get videoDetailsLoading => 'Loading video details';

	/// en: 'OpenSubtitles API key required'
	String get subtitleKeyRequired => 'OpenSubtitles API key required';

	/// en: 'Edit this file source and add an OpenSubtitles API key in its optional subtitle settings.'
	String get subtitleKeyHelp => 'Edit this file source and add an OpenSubtitles API key in its optional subtitle settings.';

	/// en: 'Subtitle search failed. Check the API key, connection, and service access.'
	String get subtitleSearchFailed => 'Subtitle search failed. Check the API key, connection, and service access.';

	/// en: 'Could not download or apply this subtitle. Check your connection and try another result.'
	String get subtitleApplyFailed => 'Could not download or apply this subtitle. Check your connection and try another result.';

	/// en: 'Search OpenSubtitles'
	String get subtitleSearch => 'Search OpenSubtitles';

	/// en: 'Search uses the title and available IMDb/TMDB IDs. The video file stays on its source. Check language, forced or hearing-impaired flags, and rating before choosing.'
	String get subtitleSearchPrivacy => 'Search uses the title and available IMDb/TMDB IDs. The video file stays on its source. Check language, forced or hearing-impaired flags, and rating before choosing.';

	/// en: 'Movie or show'
	String get movieOrShow => 'Movie or show';

	/// en: 'Enter a title to refine results'
	String get subtitleTitleHint => 'Enter a title to refine results';

	/// en: 'Subtitle language'
	String get subtitleLanguage => 'Subtitle language';

	/// en: 'Searching OpenSubtitles'
	String get subtitleSearching => 'Searching OpenSubtitles';

	/// en: 'No matching subtitles found. Try a different title or language.'
	String get subtitleNoMatches => 'No matching subtitles found. Try a different title or language.';

	/// en: 'Download subtitle'
	String get downloadSubtitle => 'Download subtitle';

	/// en: 'Subtitle'
	String get subtitle => 'Subtitle';

	/// en: 'RPC-with-TLS required'
	String get nfsTlsRequired => 'RPC-with-TLS required';

	/// en: 'Unencrypted NFS'
	String get nfsUnencrypted => 'Unencrypted NFS';

	/// en: 'TLS encrypted'
	String get tlsEncrypted => 'TLS encrypted';

	/// en: 'Plain FTP'
	String get ftpPlain => 'Plain FTP';

	/// en: 'SSH encrypted · host key pinned'
	String get sshPinned => 'SSH encrypted · host key pinned';

	/// en: 'SMB3 encryption on'
	String get smbEncrypted => 'SMB3 encryption on';

	/// en: 'SMB3 encryption off'
	String get smbUnencrypted => 'SMB3 encryption off';

	/// en: 'HTTP without transport encryption'
	String get httpUnencrypted => 'HTTP without transport encryption';

	/// en: 'Check endpoint security'
	String get checkEndpointSecurity => 'Check endpoint security';

	/// en: '${label} is required.'
	String fieldRequired({required Object label}) => '${label} is required.';

	/// en: 'Enter ${label} from ${min} to ${max}.'
	String integerRange({required Object label, required Object min, required Object max}) => 'Enter ${label} from ${min} to ${max}.';

	/// en: 'Replace ${name}'
	String replaceFile({required Object name}) => 'Replace ${name}';

	/// en: 'Selected client identity: ${name}'
	String selectedIdentity({required Object name}) => 'Selected client identity: ${name}';

	/// en: 'Rating ${rating}'
	String subtitleRating({required Object rating}) => 'Rating ${rating}';

	/// en: 'Downloading subtitle: ${title}'
	String subtitleDownloading({required Object title}) => 'Downloading subtitle: ${title}';

	/// en: 'Pair this item'
	String get sharedEntryPair => 'Pair this item';

	/// en: 'Enter the same ID for this item on each device. Use a stable shared identifier or generate one and copy it to the matching item. Progress pairs only when the edition file types, sizes, and order match. Blank removes this mapping.'
	String get sharedEntryPairHelp => 'Enter the same ID for this item on each device. Use a stable shared identifier or generate one and copy it to the matching item. Progress pairs only when the edition file types, sizes, and order match. Blank removes this mapping.';

	/// en: 'Shared item ID'
	String get sharedEntryId => 'Shared item ID';

	/// en: 'Generate shared item ID'
	String get generateSharedEntryId => 'Generate shared item ID';

	/// en: 'Shared library ID (optional)'
	String get sharedLibraryId => 'Shared library ID (optional)';

	/// en: 'Use the same ID on devices that open the same library. This public ID helps carry reading progress and notes across different source connections; it is not a password. When providers use different item IDs, pair those items from their detail screens.'
	String get sharedLibraryHelp => 'Use the same ID on devices that open the same library. This public ID helps carry reading progress and notes across different source connections; it is not a password. When providers use different item IDs, pair those items from their detail screens.';

	/// en: 'Use 8–100 letters, numbers, dots, underscores or hyphens.'
	String get sharedLibraryInvalid => 'Use 8–100 letters, numbers, dots, underscores or hyphens.';

	/// en: 'Generate a shared library ID'
	String get generateSharedLibraryId => 'Generate a shared library ID';

	/// en: 'NFS read-ahead requests'
	String get nfsReadAhead => 'NFS read-ahead requests';

	/// en: 'More parallel reads can improve throughput on a fast NAS or network. Use 1 if the server limits concurrent requests.'
	String get nfsReadAheadHelp => 'More parallel reads can improve throughput on a fast NAS or network. Use 1 if the server limits concurrent requests.';

	/// en: 'Measure NFS read performance'
	String get nfsReadTest => 'Measure NFS read performance';

	/// en: 'Reads up to 64 MiB from the largest file to measure this NAS connection. This uses network bandwidth.'
	String get nfsReadTestHelp => 'Reads up to 64 MiB from the largest file to measure this NAS connection. This uses network bandwidth.';

	/// en: 'NFS read measurement'
	String get nfsQualificationResult => 'NFS read measurement';

	/// en: 'Data read'
	String get nfsReadBytes => 'Data read';

	/// en: 'Measured speed'
	String get nfsReadSpeed => 'Measured speed';

	/// en: 'Read requests'
	String get nfsReadRequests => 'Read requests';

	/// en: 'This shared item ID is already paired with another item in this library. Choose a different ID.'
	String get sharedEntryConflict => 'This shared item ID is already paired with another item in this library. Choose a different ID.';
}

// Path: comics
class Translations$comics$en {
	Translations$comics$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Fit height'
	String get fitHeight => 'Fit height';

	/// en: 'Reading mode'
	String get readingMode => 'Reading mode';

	/// en: 'Pages'
	String get paged => 'Pages';

	/// en: 'Continuous scroll'
	String get webtoon => 'Continuous scroll';

	/// en: 'Show cover on its own'
	String get coverAlone => 'Show cover on its own';

	/// en: 'Split wide pages'
	String get splitWide => 'Split wide pages';

	/// en: 'Show each half separately, in reading order. Double-page pairing is paused while this is on.'
	String get splitWideHelp => 'Show each half separately, in reading order. Double-page pairing is paused while this is on.';

	/// en: 'Page thumbnails'
	String get thumbnails => 'Page thumbnails';

	/// en: 'Swipe to turn pages. Double-tap to change fit. In continuous scroll, swipe vertically or use Page Up and Page Down.'
	String get controlsHelp => 'Swipe to turn pages. Double-tap to change fit. In continuous scroll, swipe vertically or use Page Up and Page Down.';

	/// en: 'Display settings are remembered for this comic in this profile.'
	String get savedForComic => 'Display settings are remembered for this comic in this profile.';

	/// en: 'Reading lists'
	String get readLists => 'Reading lists';

	/// en: 'Collections'
	String get collections => 'Collections';
}

// Path: games
class Translations$games$en {
	Translations$games$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Games'
	String get title => 'Games';

	/// en: 'Show Games for this profile'
	String get enable => 'Show Games for this profile';

	/// en: 'Browse your games and connect gaming computers. In-app playback depends on this device’s streaming support.'
	String get enableDescription => 'Browse your games and connect gaming computers. In-app playback depends on this device’s streaming support.';

	/// en: 'Your games, from your computers.'
	String get subtitle => 'Your games, from your computers.';

	/// en: 'Your computers'
	String get computers => 'Your computers';

	/// en: 'Nearby computers'
	String get nearby => 'Nearby computers';

	/// en: 'Find computers'
	String get findComputers => 'Find computers';

	/// en: 'Add computer'
	String get addComputer => 'Add computer';

	/// en: 'Keep Steam Remote Play or Sunshine running on the same network. VPNs and guest networks may need a manual address.'
	String get scanHint => 'Keep Steam Remote Play or Sunshine running on the same network. VPNs and guest networks may need a manual address.';

	/// en: 'Add your gaming computer to get started.'
	String get empty => 'Add your gaming computer to get started.';

	/// en: 'No computers found on this network. You can enter an address manually.'
	String get noNearby => 'No computers found on this network. You can enter an address manually.';

	/// en: 'Computer name'
	String get name => 'Computer name';

	/// en: 'IP address or hostname'
	String get address => 'IP address or hostname';

	/// en: 'Service port'
	String get port => 'Service port';

	/// en: 'Streaming service'
	String get protocol => 'Streaming service';

	/// en: 'Sunshine / Moonlight'
	String get moonlight => 'Sunshine / Moonlight';

	/// en: 'Steam Remote Play'
	String get steam => 'Steam Remote Play';

	/// en: 'Save computer'
	String get save => 'Save computer';

	/// en: 'Enter a valid hostname or IP address, without a URL, and a port from 1 to 65534.'
	String get invalidAddress => 'Enter a valid hostname or IP address, without a URL, and a port from 1 to 65534.';

	/// en: 'Connect computer'
	String get pair => 'Connect computer';

	/// en: 'Approve this device'
	String get pairTitle => 'Approve this device';

	/// en: 'Enter this code in the host’s pairing prompt. For Sunshine, use the PIN page below. Keep this screen open until the computer approves.'
	String get pairInstructions => 'Enter this code in the host’s pairing prompt. For Sunshine, use the PIN page below. Keep this screen open until the computer approves.';

	/// en: 'Connect this computer again to approve or renew pairing.'
	String get pairHelp => 'Connect this computer again to approve or renew pairing.';

	/// en: 'Open Sunshine PIN page'
	String get openPairingPage => 'Open Sunshine PIN page';

	/// en: 'Scan to open the PIN page. The QR code contains only the computer address, never a password or pairing credential.'
	String get qrHelp => 'Scan to open the PIN page. The QR code contains only the computer address, never a password or pairing credential.';

	/// en: 'Refresh games'
	String get refreshGames => 'Refresh games';

	/// en: 'Play'
	String get play => 'Play';

	/// en: 'Recently played'
	String get recent => 'Recently played';

	/// en: 'Favorites'
	String get favorites => 'Favorites';

	/// en: 'All games'
	String get allGames => 'All games';

	/// en: 'Find a game'
	String get search => 'Find a game';

	/// en: 'No games match this search.'
	String get noMatches => 'No games match this search.';

	/// en: 'Save favorite'
	String get favorite => 'Save favorite';

	/// en: 'Remove favorite'
	String get unfavorite => 'Remove favorite';

	/// en: 'Forget computer'
	String get forget => 'Forget computer';

	/// en: 'Remove this computer and its game shortcuts from this profile? To revoke this device’s authorization, remove it from the host’s paired devices.'
	String get forgetDescription => 'Remove this computer and its game shortcuts from this profile? To revoke this device’s authorization, remove it from the host’s paired devices.';

	/// en: 'The connection could not complete. Check that the computer is awake and paired, then try again.'
	String get unavailable => 'The connection could not complete. Check that the computer is awake and paired, then try again.';

	/// en: 'Connection timed out. Check the computer, pairing code and network before trying again.'
	String get timeout => 'Connection timed out. Check the computer, pairing code and network before trying again.';

	/// en: 'Choose a computer to connect and load its games. Once connected, choose a game to play inside PlezyNG.'
	String get libraryHint => 'Choose a computer to connect and load its games. Once connected, choose a game to play inside PlezyNG.';

	/// en: 'On-screen controller'
	String get touchControls => 'On-screen controller';

	/// en: 'Show the native controller during a stream. It supports multiple fingers, sticks, buttons and triggers.'
	String get touchDescription => 'Show the native controller during a stream. It supports multiple fingers, sticks, buttons and triggers.';

	/// en: 'On-screen controls'
	String get touchSetup => 'On-screen controls';

	/// en: 'Moonlight’s controller settings support position and opacity changes. During a Steam stream, open the stream menu to toggle its controller. Bluetooth or USB input is also supported.'
	String get touchSetupHint => 'Moonlight’s controller settings support position and opacity changes. During a Steam stream, open the stream menu to toggle its controller. Bluetooth or USB input is also supported.';

	/// en: 'Add game shortcut'
	String get addGame => 'Add game shortcut';

	/// en: 'Game name'
	String get gameName => 'Game name';

	/// en: 'Host application ID'
	String get gameId => 'Host application ID';

	/// en: 'Enter a game name and a positive numeric host application ID.'
	String get invalidGame => 'Enter a game name and a positive numeric host application ID.';

	/// en: 'Wake computer'
	String get wake => 'Wake computer';

	/// en: 'Wake request sent. The computer must support Wake-on-LAN on this network.'
	String get wakeSent => 'Wake request sent. The computer must support Wake-on-LAN on this network.';

	/// en: 'MAC address (optional)'
	String get mac => 'MAC address (optional)';

	/// en: 'Games help'
	String get help => 'Games help';

	/// en: 'Enable Games for your profile, choose a computer and approve the first connection. Sunshine-compatible hosts load their app list into the game grid. On Android, Steam pairing opens Big Picture inside PlezyNG; saved Steam app-ID shortcuts launch directly. Steam pairing does not grant access to a private account library. Both Android engines include touch controls and gamepad input. Pyrowave is an experimental Android option; other native platforms remain in development. Pairing requires the host’s approval. Sunshine QR codes open its PIN page without carrying credentials. For access away from home, use the computer’s VPN address. Automatic discovery normally stays on the local network. Disconnecting leaves the game running on the computer.'
	String get helpBody => 'Enable Games for your profile, choose a computer and approve the first connection. Sunshine-compatible hosts load their app list into the game grid. On Android, Steam pairing opens Big Picture inside PlezyNG; saved Steam app-ID shortcuts launch directly. Steam pairing does not grant access to a private account library.\n\nBoth Android engines include touch controls and gamepad input. Pyrowave is an experimental Android option; other native platforms remain in development.\n\nPairing requires the host’s approval. Sunshine QR codes open its PIN page without carrying credentials. For access away from home, use the computer’s VPN address. Automatic discovery normally stays on the local network.\n\nDisconnecting leaves the game running on the computer.';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Looking for computers…'
	String get scanning => 'Looking for computers…';

	/// en: 'Save shortcut'
	String get saveShortcut => 'Save shortcut';

	/// en: 'For Moonlight use the host’s GameStream HTTP port (usually 47989), not its web settings port. Steam normally advertises on 27036.'
	String get manualHint => 'For Moonlight use the host’s GameStream HTTP port (usually 47989), not its web settings port. Steam normally advertises on 27036.';

	/// en: 'In-app streaming is not available here yet'
	String get engineUnavailable => 'In-app streaming is not available here yet';

	/// en: 'This build does not include a streaming engine for this platform. You can save the computer, but it cannot play here yet.'
	String get nativeEnginePending => 'This build does not include a streaming engine for this platform. You can save the computer, but it cannot play here yet.';

	/// en: 'This build does not include the embedded Steam engine. Android builds with Games enabled bundle device pairing and in-app H.264/HEVC playback. Pyrowave is experimental on Android; other platforms remain under development.'
	String get steamEnginePending => 'This build does not include the embedded Steam engine. Android builds with Games enabled bundle device pairing and in-app H.264/HEVC playback. Pyrowave is experimental on Android; other platforms remain under development.';

	/// en: 'Pyrowave · experimental'
	String get steamBetaTitle => 'Pyrowave · experimental';

	/// en: 'Try Steam’s low-latency codec on a fast wired network. Uses substantially more bandwidth. If it cannot start, PlezyNG reconnects using a compatible codec.'
	String get steamBetaDescription => 'Try Steam’s low-latency codec on a fast wired network. Uses substantially more bandwidth. If it cannot start, PlezyNG reconnects using a compatible codec.';

	/// en: 'Steam library'
	String get steamLibrary => 'Steam library';

	/// en: 'Link Steam account'
	String get linkSteamAccount => 'Link Steam account';

	/// en: 'Refresh Steam account'
	String get refreshSteamAccount => 'Refresh Steam account';

	/// en: 'Unlink Steam account'
	String get unlinkSteamAccount => 'Unlink Steam account';

	/// en: 'Remove this account and its imported catalog from this profile? Your paired computers and shortcuts stay available.'
	String get unlinkSteamAccountConfirm => 'Remove this account and its imported catalog from this profile? Your paired computers and shortcuts stay available.';

	/// en: 'Steam account linked. Games imported.'
	String get steamAccountLinked => 'Steam account linked. Games imported.';

	/// en: 'Steam account linked. Its library is private or unavailable, so no games were imported.'
	String get steamLibraryPrivate => 'Steam account linked. Its library is private or unavailable, so no games were imported.';

	/// en: 'Steam could not refresh the library. Showing the last available catalog.'
	String get steamLibraryStale => 'Steam could not refresh the library. Showing the last available catalog.';

	/// en: 'Showing up to 2,000 games. The Steam catalog was truncated.'
	String get steamLibraryTruncated => 'Showing up to 2,000 games. The Steam catalog was truncated.';

	/// en: 'Connecting…'
	String get connecting => 'Connecting…';

	/// en: 'Disconnect'
	String get disconnect => 'Disconnect';

	/// en: 'Stream controls'
	String get streamControls => 'Stream controls';

	/// en: 'Enter this code in Steam’s Remote Play pairing prompt on your computer. Keep this screen open until Steam approves.'
	String get steamPairInstructions => 'Enter this code in Steam’s Remote Play pairing prompt on your computer. Keep this screen open until Steam approves.';

	/// en: 'Game details'
	String get gameDetails => 'Game details';

	/// en: 'Choose computer'
	String get chooseComputer => 'Choose computer';

	/// en: 'Connect a computer'
	String get connectComputer => 'Connect a computer';

	/// en: 'Connect a gaming computer to play this game inside PlezyNG.'
	String get connectToPlay => 'Connect a gaming computer to play this game inside PlezyNG.';

	/// en: 'Steam on your computer checks installation, access and cloud saves when you connect. A saved game or computer does not mean it is available now.'
	String get availabilityHint => 'Steam on your computer checks installation, access and cloud saves when you connect. A saved game or computer does not mean it is available now.';

	/// en: 'From Steam'
	String get steamSource => 'From Steam';

	/// en: 'Disconnected'
	String get disconnected => 'Disconnected';

	/// en: 'Installed'
	String get installed => 'Installed';

	/// en: 'Installation incomplete'
	String get installationIncomplete => 'Installation incomplete';

	/// en: 'Not in the last inventory'
	String get notInstalled => 'Not in the last inventory';

	/// en: 'Installation not checked'
	String get installationUnknown => 'Installation not checked';

	/// en: 'All computers'
	String get allComputers => 'All computers';

	/// en: 'Import installed games'
	String get importInstalledGames => 'Import installed games';

	/// en: 'Connect to this computer with Companion Remote, and enable “Share installed Steam games” in its Games settings. Both devices need a version that supports library sharing.'
	String get inventoryConnectHelp => 'Connect to this computer with Companion Remote, and enable “Share installed Steam games” in its Games settings. Both devices need a version that supports library sharing.';

	/// en: 'Use the installed games reported by ${peer} for ${computer}? Only link them if they are the same computer.'
	String inventoryConfirm({required Object peer, required Object computer}) => 'Use the installed games reported by ${peer} for ${computer}? Only link them if they are the same computer.';

	/// en: 'Installed games updated.'
	String get inventoryImported => 'Installed games updated.';

	/// en: 'Last checked ${date}'
	String inventoryChecked({required Object date}) => 'Last checked ${date}';

	/// en: 'Share installed Steam games'
	String get shareLibrary => 'Share installed Steam games';

	/// en: 'Allow paired Companion Remote devices in this profile to read the names and installation state of games on this computer. Steam sign-in data and file paths stay here. Enable the Companion Remote server to connect.'
	String get shareLibraryHelp => 'Allow paired Companion Remote devices in this profile to read the names and installation state of games on this computer. Steam sign-in data and file paths stay here. Enable the Companion Remote server to connect.';

	/// en: 'Steam installation folder'
	String get steamInstallFolder => 'Steam installation folder';

	/// en: 'Find automatically'
	String get automaticFolder => 'Find automatically';

	/// en: 'Steam stream quality'
	String get streamQuality => 'Steam stream quality';

	/// en: 'Steam controllers'
	String get controllerSeats => 'Steam controllers';

	/// en: 'Allow companion game session controls'
	String get allowSessionControl => 'Allow companion game session controls';

	/// en: 'Let your authenticated companion view active game titles, choose game audio, show a stream fullscreen or disconnect it. Disconnecting leaves the game running on its computer. Off by default for each profile.'
	String get allowSessionControlHelp => 'Let your authenticated companion view active game titles, choose game audio, show a stream fullscreen or disconnect it. Disconnecting leaves the game running on its computer. Off by default for each profile.';

	/// en: 'Game sessions'
	String get remoteSessions => 'Game sessions';

	/// en: 'Control streams inside PlezyNG on the connected device. This does not quit games on their computers or send gamepad input.'
	String get remoteSessionsHelp => 'Control streams inside PlezyNG on the connected device. This does not quit games on their computers or send gamepad input.';

	/// en: 'Enable companion game session controls in Games settings on the connected device.'
	String get remoteSessionsDenied => 'Enable companion game session controls in Games settings on the connected device.';

	/// en: 'Game session controls are unavailable. Reconnect or refresh to try again.'
	String get remoteSessionsUnavailable => 'Game session controls are unavailable. Reconnect or refresh to try again.';

	/// en: 'The request was accepted. Refresh to check the current sessions.'
	String get remoteSessionSubmitted => 'The request was accepted. Refresh to check the current sessions.';

	/// en: 'No active game streams are available on this device.'
	String get noRemoteSessions => 'No active game streams are available on this device.';

	/// en: 'Game audio is selected'
	String get remoteSessionAudible => 'Game audio is selected';

	/// en: 'Game audio is not selected'
	String get remoteSessionMuted => 'Game audio is not selected';

	/// en: 'Game session actions'
	String get remoteSessionActions => 'Game session actions';

	/// en: 'Listen to this game'
	String get remoteSessionListen => 'Listen to this game';

	/// en: 'Mute this game'
	String get remoteSessionMute => 'Mute this game';

	/// en: 'Refresh sessions'
	String get remoteSessionsRefresh => 'Refresh sessions';

	/// en: 'Steam connection details'
	String get streamDetails => 'Steam connection details';

	/// en: 'Steam can adapt its bitrate and frame rate using receiver feedback. Your stream quality setting supplies the requested limits.'
	String get streamFeedbackHelp => 'Steam can adapt its bitrate and frame rate using receiver feedback. Your stream quality setting supplies the requested limits.';

	/// en: 'Receiver measurements'
	String get streamMeasurements => 'Receiver measurements';

	/// en: 'Not available yet'
	String get streamMeasurementsUnavailable => 'Not available yet';

	/// en: 'Video format'
	String get streamVideo => 'Video format';

	/// en: 'Decoder'
	String get streamDecoder => 'Decoder';

	/// en: 'Hardware'
	String get streamHardwareDecoder => 'Hardware';

	/// en: 'Software'
	String get streamSoftwareDecoder => 'Software';

	/// en: 'Vulkan with CPU readback'
	String get streamReadbackDecoder => 'Vulkan with CPU readback';

	/// en: 'Host frame rate target'
	String get streamHostFps => 'Host frame rate target';

	/// en: 'Host bitrate target'
	String get streamHostBitrate => 'Host bitrate target';

	/// en: 'Host-reported frame rate limits'
	String get streamLimits => 'Host-reported frame rate limits';

	/// en: 'Host capture or encoder'
	String get streamLimitHost => 'Host capture or encoder';

	/// en: 'Network'
	String get streamLimitNetwork => 'Network';

	/// en: 'Receiver decoder'
	String get streamLimitDecoder => 'Receiver decoder';

	/// en: 'Burst throttling'
	String get streamLimitBurst => 'Burst throttling';

	/// en: 'Frames submitted to the display'
	String get streamPresentedFps => 'Frames submitted to the display';

	/// en: 'Received video payload'
	String get streamReceivedBitrate => 'Received video payload';

	/// en: 'Average receiver frame completion'
	String get streamCompletionTime => 'Average receiver frame completion';

	/// en: 'Receiver-dropped frames this session'
	String get streamDroppedFrames => 'Receiver-dropped frames this session';

	/// en: 'Video queue'
	String get streamVideoQueue => 'Video queue';

	/// en: 'Audio queue'
	String get streamAudioQueue => 'Audio queue';

	/// en: 'Audio channels'
	String get streamAudioChannels => 'Audio channels';

	/// en: 'Input packets queued + awaiting confirmation'
	String get streamInputBacklog => 'Input packets queued + awaiting confirmation';

	/// en: 'Reliable packet retries this session'
	String get streamReliableRetries => 'Reliable packet retries this session';

	/// en: 'Reliable packets abandoned this session'
	String get streamReliableGiveUps => 'Reliable packets abandoned this session';

	/// en: 'Longest reliable packet acknowledgement'
	String get streamMaxAck => 'Longest reliable packet acknowledgement';

	/// en: 'Updated once a second while this view is open. Video bitrate excludes network overhead. Frame completion includes receiver queuing, decoding and submission to the display; it does not measure network latency or screen scanout. Packet acknowledgement includes retries and is not RTT. Measurements stay on this device.'
	String get streamMeasurementsHelp => 'Updated once a second while this view is open. Video bitrate excludes network overhead. Frame completion includes receiver queuing, decoding and submission to the display; it does not measure network latency or screen scanout. Packet acknowledgement includes retries and is not RTT. Measurements stay on this device.';

	/// en: 'Applies to new connections. Up to four controllers, assigned in order of first input. Touch controls share player one. Extra controllers are ignored; game support varies.'
	String get controllerSeatsHelp => 'Applies to new connections. Up to four controllers, assigned in order of first input. Touch controls share player one. Extra controllers are ignored; game support varies.';

	/// en: 'Applies to new Steam connections. These are requested limits; the host and receiver decide the actual stream. Pyrowave may use more bandwidth than the bitrate limit.'
	String get streamQualityHelp => 'Applies to new Steam connections. These are requested limits; the host and receiver decide the actual stream. Pyrowave may use more bandwidth than the bitrate limit.';

	/// en: 'Steam video codec'
	String get streamCodec => 'Steam video codec';

	/// en: 'Automatic allows HEVC on compatible receivers. Choose H.264 for compatibility. Also applies when experimental Pyrowave falls back. Changes apply to new connections.'
	String get streamCodecHelp => 'Automatic allows HEVC on compatible receivers. Choose H.264 for compatibility. Also applies when experimental Pyrowave falls back. Changes apply to new connections.';

	/// en: 'Automatic · H.264 / HEVC'
	String get codecAutomatic => 'Automatic · H.264 / HEVC';

	/// en: 'Balanced'
	String get qualityBalanced => 'Balanced';

	/// en: 'Lower bandwidth'
	String get qualityReducedBandwidth => 'Lower bandwidth';

	/// en: 'Sharper picture'
	String get qualitySharperPicture => 'Sharper picture';

	/// en: 'Lower frame rate'
	String get qualityReducedFrameRate => 'Lower frame rate';

	/// en: 'Reconnect'
	String get reconnect => 'Reconnect';

	/// en: 'Reconnecting…'
	String get reconnecting => 'Reconnecting…';

	/// en: 'Disconnecting leaves the game running on the computer.'
	String get disconnectHelp => 'Disconnecting leaves the game running on the computer.';

	/// en: 'The stream stopped. Check that the computer is reachable and Steam Remote Play is enabled.'
	String get streamFailed => 'The stream stopped. Check that the computer is reachable and Steam Remote Play is enabled.';

	/// en: 'Steam activity'
	String get steamActivity => 'Steam activity';

	/// en: 'Load news and achievements for your linked account. Activity is kept only while these details are open.'
	String get steamActivityHelp => 'Load news and achievements for your linked account. Activity is kept only while these details are open.';

	/// en: 'Include friends playing'
	String get includeFriends => 'Include friends playing';

	/// en: 'Also ask Steam which friends are playing this game. Respects Steam privacy settings. Off by default.'
	String get includeFriendsHelp => 'Also ask Steam which friends are playing this game. Respects Steam privacy settings. Off by default.';

	/// en: 'Load Steam activity'
	String get loadSteamActivity => 'Load Steam activity';

	/// en: 'Loading Steam activity…'
	String get activityLoading => 'Loading Steam activity…';

	/// en: 'Steam activity is unavailable. Try again shortly.'
	String get activityUnavailable => 'Steam activity is unavailable. Try again shortly.';

	/// en: 'Private or unavailable from Steam.'
	String get activityPrivate => 'Private or unavailable from Steam.';

	/// en: 'Achievements'
	String get achievements => 'Achievements';

	/// en: '$unlocked of $total unlocked'
	String achievementProgress({required Object unlocked, required Object total}) => '${unlocked} of ${total} unlocked';

	/// en: 'Hidden achievement'
	String get hiddenAchievement => 'Hidden achievement';

	/// en: 'Details appear after you unlock it.'
	String get hiddenAchievementHelp => 'Details appear after you unlock it.';

	/// en: 'Unlocked'
	String get achievementUnlocked => 'Unlocked';

	/// en: 'Locked'
	String get achievementLocked => 'Locked';

	/// en: 'Show more achievements'
	String get moreAchievements => 'Show more achievements';

	/// en: 'Game news'
	String get gameNews => 'Game news';

	/// en: 'No recent news available.'
	String get noGameNews => 'No recent news available.';

	/// en: 'Friends playing this game'
	String get friendsPlaying => 'Friends playing this game';

	/// en: 'No friends are reported playing in this snapshot.'
	String get noFriendsPlaying => 'No friends are reported playing in this snapshot.';

	/// en: 'This snapshot is limited; some achievements or friends may not be included.'
	String get activityTruncated => 'This snapshot is limited; some achievements or friends may not be included.';

	/// en: 'Steam store'
	String get steamStore => 'Steam store';

	/// en: 'Community'
	String get steamCommunity => 'Community';

	/// en: 'Workshop'
	String get steamWorkshop => 'Workshop';

	/// en: 'Open Steam page'
	String get openSteamPage => 'Open Steam page';

	/// en: 'Open this game’s Steam page in your browser? Your browser’s Steam sign-in and privacy settings apply.'
	String get openSteamPageHelp => 'Open this game’s Steam page in your browser? Your browser’s Steam sign-in and privacy settings apply.';

	/// en: 'Computer actions'
	String get hostActions => 'Computer actions';

	/// en: 'Launch on computer'
	String get launchOnComputer => 'Launch on computer';

	/// en: 'Install on computer'
	String get installOnComputer => 'Install on computer';

	/// en: 'Open Steam on computer'
	String get hostLibrary => 'Open Steam on computer';

	/// en: 'Open downloads on computer'
	String get hostDownloads => 'Open downloads on computer';

	/// en: 'Send this action to $computer? Steam on that computer handles ownership, downloads, family availability and any cloud-save prompts. This does not start a stream.'
	String hostActionConfirm({required Object computer}) => 'Send this action to ${computer}? Steam on that computer handles ownership, downloads, family availability and any cloud-save prompts. This does not start a stream.';

	/// en: 'Pair with this computer through Companion Remote and import its installed games first. The authenticated computer identity must match.'
	String get hostActionPairingHelp => 'Pair with this computer through Companion Remote and import its installed games first. The authenticated computer identity must match.';

	/// en: 'Request handed to Steam on the computer. Check Steam for the result or any prompts.'
	String get hostActionSubmitted => 'Request handed to Steam on the computer. Check Steam for the result or any prompts.';

	/// en: 'This computer has not allowed that Steam action. Enable the corresponding permission in its Games settings.'
	String get hostActionDenied => 'This computer has not allowed that Steam action. Enable the corresponding permission in its Games settings.';

	/// en: 'Allow paired remotes to control Steam'
	String get allowHostActions => 'Allow paired remotes to control Steam';

	/// en: 'Paired Companion Remotes may launch installed games and open Steam or downloads on this computer. Off by default; separate from library sharing.'
	String get allowHostActionsHelp => 'Paired Companion Remotes may launch installed games and open Steam or downloads on this computer. Off by default; separate from library sharing.';

	/// en: 'Allow Steam install requests'
	String get allowHostInstall => 'Allow Steam install requests';

	/// en: 'Also allow paired remotes to send installation requests to Steam. Requires Steam control above. Steam handles disk space, ownership and prompts. Off by default.'
	String get allowHostInstallHelp => 'Also allow paired remotes to send installation requests to Steam. Requires Steam control above. Steam handles disk space, ownership and prompts. Off by default.';

	/// en: 'Steam audio'
	String get streamAudio => 'Steam audio';

	/// en: 'Request stereo, quad or 5.1 audio for new streams. Surround needs a compatible host and speaker output. If the channel layout or output is unsupported, PlezyNG retries in stereo. Stream details show the negotiated channel count.'
	String get streamAudioHelp => 'Request stereo, quad or 5.1 audio for new streams. Surround needs a compatible host and speaker output. If the channel layout or output is unsupported, PlezyNG retries in stereo. Stream details show the negotiated channel count.';

	/// en: 'Stereo'
	String get audioStereo => 'Stereo';

	/// en: 'Quad (4 speakers)'
	String get audioQuad => 'Quad (4 speakers)';

	/// en: 'Surround (5.1)'
	String get audioSurround51 => 'Surround (5.1)';
}

// Path: deepLinks
class Translations$deepLinks$en {
	Translations$deepLinks$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'This Plezy link isn't valid.'
	String get invalid => 'This Plezy link isn\'t valid.';

	/// en: 'No profile matches "${profile}".'
	String profileNotFound({required Object profile}) => 'No profile matches "${profile}".';

	/// en: 'Couldn't reach the server for this link.'
	String get serverUnavailable => 'Couldn\'t reach the server for this link.';

	/// en: 'Couldn't find this title in your libraries.'
	String get notFound => 'Couldn\'t find this title in your libraries.';

	/// en: 'This link can't be played.'
	String get unsupportedItem => 'This link can\'t be played.';

	/// en: 'No Live TV server is available for this link.'
	String get noLiveTv => 'No Live TV server is available for this link.';

	/// en: 'Couldn't find channel "${channel}".'
	String channelNotFound({required Object channel}) => 'Couldn\'t find channel "${channel}".';

	/// en: 'Show link'
	String get showLink => 'Show link';

	/// en: 'Show profile link'
	String get showProfileLink => 'Show profile link';

	/// en: 'Link'
	String get dialogTitle => 'Link';

	/// en: 'Opening this link plays the next episode. Add &mode=shuffle to play the show on shuffle.'
	String get showHint => 'Opening this link plays the next episode. Add &mode=shuffle to play the show on shuffle.';

	/// en: 'Opening this link plays the movie.'
	String get movieHint => 'Opening this link plays the movie.';

	/// en: 'Opening this link plays this episode.'
	String get episodeHint => 'Opening this link plays this episode.';

	/// en: 'Opening this link switches to this profile.'
	String get profileHint => 'Opening this link switches to this profile.';

	/// en: 'Open as ${name}'
	String openAsProfile({required Object name}) => 'Open as ${name}';

	/// en: 'Copy'
	String get copy => 'Copy';

	/// en: 'Link copied'
	String get copied => 'Link copied';
}

// Path: householdSetup
class Translations$householdSetup$en {
	Translations$householdSetup$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Household setup'
	String get title => 'Household setup';
}

// Path: issueReport
class Translations$issueReport$en {
	Translations$issueReport$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Report a problem'
	String get title => 'Report a problem';

	/// en: 'Scan the QR code to open a prefilled GitHub draft. Review it and submit only when you are ready.'
	String get instructions => 'Scan the QR code to open a prefilled GitHub draft. Review it and submit only when you are ready.';

	/// en: 'The draft includes app version, platform, and connection counts. It excludes server addresses, account and profile names, media titles, and file paths.'
	String get privacy => 'The draft includes app version, platform, and connection counts. It excludes server addresses, account and profile names, media titles, and file paths.';

	/// en: 'Logs are optional. Review them before uploading. Their ID is added to the draft, which may be public.'
	String get logPrivacy => 'Logs are optional. Review them before uploading. Their ID is added to the draft, which may be public.';

	/// en: 'Open GitHub draft'
	String get openDraft => 'Open GitHub draft';
}

// Path: appIcon.names
class Translations$appIcon$names$en {
	Translations$appIcon$names$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Midnight'
	String get midnight => 'Midnight';

	/// en: 'Ember'
	String get ember => 'Ember';

	/// en: 'Paper'
	String get paper => 'Paper';

	/// en: 'OLED'
	String get oled => 'OLED';

	/// en: 'Line'
	String get line => 'Line';

	/// en: 'Ocean'
	String get ocean => 'Ocean';

	/// en: 'Ultraviolet'
	String get ultraviolet => 'Ultraviolet';

	/// en: 'Matcha'
	String get matcha => 'Matcha';

	/// en: 'Sunset'
	String get sunset => 'Sunset';

	/// en: 'Gold'
	String get gold => 'Gold';

	/// en: 'Titanium'
	String get titanium => 'Titanium';

	/// en: 'Glass'
	String get glass => 'Glass';

	/// en: 'CRT'
	String get crt => 'CRT';

	/// en: 'VHS'
	String get vhs => 'VHS';

	/// en: 'Synthwave'
	String get synthwave => 'Synthwave';

	/// en: 'Pixel'
	String get pixel => 'Pixel';

	/// en: 'Neon'
	String get neon => 'Neon';

	/// en: 'Sticker'
	String get sticker => 'Sticker';

	/// en: 'Ticket'
	String get ticket => 'Ticket';

	/// en: 'Pop'
	String get pop => 'Pop';

	/// en: 'Strata'
	String get strata => 'Strata';

	/// en: 'Facet'
	String get facet => 'Facet';

	/// en: 'Tilde'
	String get tilde => 'Tilde';
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

	/// en: 'Metacritic'
	String get metacritic => 'Metacritic';

	/// en: 'Letterboxd'
	String get letterboxd => 'Letterboxd';
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

// Path: settings.startupSectionOptions
class Translations$settings$startupSectionOptions$en {
	Translations$settings$startupSectionOptions$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Open recommendations and items from connected discovery sources.'
	String get discover => 'Open recommendations and items from connected discovery sources.';

	/// en: 'Open your connected media libraries.'
	String get libraries => 'Open your connected media libraries.';

	/// en: 'Open Live TV when a server provides it; otherwise startup falls back to Home.'
	String get liveTv => 'Open Live TV when a server provides it; otherwise startup falls back to Home.';

	/// en: 'Open media search.'
	String get search => 'Open media search.';
}

// Path: themeEditor.slots
class Translations$themeEditor$slots$en {
	Translations$themeEditor$slots$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Background'
	String get bg => 'Background';

	/// en: 'Surface'
	String get surface => 'Surface';

	/// en: 'Outline'
	String get outline => 'Outline';

	/// en: 'Text'
	String get text => 'Text';

	/// en: 'Secondary text'
	String get textMuted => 'Secondary text';

	/// en: 'Accent'
	String get accent => 'Accent';
}

// Path: themeEditor.contrast
class Translations$themeEditor$contrast$en {
	Translations$themeEditor$contrast$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Text on background'
	String get textOnBg => 'Text on background';

	/// en: 'Text on surface'
	String get textOnSurface => 'Text on surface';

	/// en: 'Secondary text on background'
	String get textMutedOnBg => 'Secondary text on background';

	/// en: 'Secondary text on surface'
	String get textMutedOnSurface => 'Secondary text on surface';

	/// en: 'Accent on background'
	String get accentOnBg => 'Accent on background';

	/// en: 'Accent on surface'
	String get accentOnSurface => 'Accent on surface';

	/// en: 'Button label on accent'
	String get labelOnAccent => 'Button label on accent';
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

	/// en: 'Delay Subtitles'
	String get subtitleDelayIncrease => 'Delay Subtitles';

	/// en: 'Advance Subtitles'
	String get subtitleDelayDecrease => 'Advance Subtitles';

	/// en: 'Toggle Shaders'
	String get shaderToggle => 'Toggle Shaders';

	/// en: 'Skip Intro/Credits'
	String get skipMarker => 'Skip Intro/Credits';

	/// en: 'Take Screenshot'
	String get screenshot => 'Take Screenshot';

	/// en: 'Previous Frame'
	String get framePrevious => 'Previous Frame';

	/// en: 'Next Frame'
	String get frameNext => 'Next Frame';
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

// Path: subtitlingStyling.assOverrideOptions
class Translations$subtitlingStyling$assOverrideOptions$en {
	Translations$subtitlingStyling$assOverrideOptions$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Keep the fonts, colors, sizes, and placement authored in the subtitle file.'
	String get no => 'Keep the fonts, colors, sizes, and placement authored in the subtitle file.';

	/// en: 'Allow the player’s subtitle style settings to adjust ASS subtitles.'
	String get yes => 'Allow the player’s subtitle style settings to adjust ASS subtitles.';

	/// en: 'Apply player styling and scale embedded sizes to match the video dimensions.'
	String get scale => 'Apply player styling and scale embedded sizes to match the video dimensions.';

	/// en: 'Replace embedded ASS styles with the player’s subtitle style.'
	String get force => 'Replace embedded ASS styles with the player’s subtitle style.';

	/// en: 'Remove embedded ASS formatting and render the subtitle text plainly.'
	String get strip => 'Remove embedded ASS formatting and render the subtitle text plainly.';
}

// Path: subtitlingStyling.renderResolutionOptions
class Translations$subtitlingStyling$renderResolutionOptions$en {
	Translations$subtitlingStyling$renderResolutionOptions$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Render at the full display surface resolution for the sharpest result.'
	String get screen => 'Render at the full display surface resolution for the sharpest result.';

	/// en: 'Render using the video resolution as the reference, which can reduce work on high-resolution displays.'
	String get video => 'Render using the video resolution as the reference, which can reduce work on high-resolution displays.';

	/// en: 'Render at 75% of the display surface resolution for a modest performance saving.'
	String get threeQuarter => 'Render at 75% of the display surface resolution for a modest performance saving.';

	/// en: 'Render at 50% of the display surface resolution to reduce work, with softer edges.'
	String get half => 'Render at 50% of the display surface resolution to reduce work, with softer edges.';

	/// en: 'Render at one-third of the display surface resolution to reduce work, with softer edges.'
	String get third => 'Render at one-third of the display surface resolution to reduce work, with softer edges.';

	/// en: 'Render at one-quarter of the display surface resolution to reduce work, with the softest result.'
	String get quarter => 'Render at one-quarter of the display surface resolution to reduce work, with the softest result.';
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

	/// en: 'Prefer standard subtitles when both standard and SDH versions are available.'
	String get preferNonSdhDescription => 'Prefer standard subtitles when both standard and SDH versions are available.';

	/// en: 'Prefer SDH subtitles when available, but allow standard subtitles as a fallback.'
	String get preferSdhDescription => 'Prefer SDH subtitles when available, but allow standard subtitles as a fallback.';

	/// en: 'Use SDH subtitles only; do not fall back to standard subtitles.'
	String get onlySdhDescription => 'Use SDH subtitles only; do not fall back to standard subtitles.';

	/// en: 'Use standard subtitles only; exclude SDH subtitles.'
	String get onlyNonSdhDescription => 'Use standard subtitles only; exclude SDH subtitles.';
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

	/// en: 'Prefer regular subtitles, but allow forced tracks as a fallback.'
	String get preferNonForcedDescription => 'Prefer regular subtitles, but allow forced tracks as a fallback.';

	/// en: 'Prefer forced tracks when available, but allow regular subtitles as a fallback.'
	String get preferForcedDescription => 'Prefer forced tracks when available, but allow regular subtitles as a fallback.';

	/// en: 'Use only tracks marked as forced.'
	String get onlyForcedDescription => 'Use only tracks marked as forced.';

	/// en: 'Exclude tracks marked as forced.'
	String get onlyNonForcedDescription => 'Exclude tracks marked as forced.';
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

	/// en: 'Do not show watched checkmarks.'
	String get noneDescription => 'Do not show watched checkmarks.';

	/// en: 'Show watched checkmarks for movies and TV shows.'
	String get moviesAndShowsDescription => 'Show watched checkmarks for movies and TV shows.';

	/// en: 'Show watched checkmarks for movies only.'
	String get moviesDescription => 'Show watched checkmarks for movies only.';

	/// en: 'Show watched checkmarks for TV shows only.'
	String get showsDescription => 'Show watched checkmarks for TV shows only.';
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

	/// en: 'Show both user ratings and critic ratings.'
	String get usersAndCriticsDescription => 'Show both user ratings and critic ratings.';

	/// en: 'Show ratings and reviews submitted by users.'
	String get usersOnlyDescription => 'Show ratings and reviews submitted by users.';

	/// en: 'Show critic ratings and reviews.'
	String get criticsOnlyDescription => 'Show critic ratings and reviews.';

	/// en: 'Hide ratings and reviews.'
	String get nobodyDescription => 'Hide ratings and reviews.';
}

// Path: discover.findNext
class Translations$discover$findNext$en {
	Translations$discover$findNext$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Find your next'
	String get title => 'Find your next';

	/// en: 'Find your next'
	String get open => 'Find your next';

	/// en: 'Any time'
	String get anyTime => 'Any time';

	/// en: 'How much time do you have?'
	String get timeAvailable => 'How much time do you have?';

	/// en: 'Choose the moment'
	String get filters => 'Choose the moment';

	/// en: 'Mood'
	String get mood => 'Mood';

	/// en: 'Mood filters use mood tags supplied by your media server; some picks do not have them.'
	String get moodMetadataHint => 'Mood filters use mood tags supplied by your media server; some picks do not have them.';

	/// en: 'Familiarity'
	String get familiarity => 'Familiarity';

	/// en: 'Any familiarity'
	String get familiarityAny => 'Any familiarity';

	/// en: 'New to me'
	String get newToMe => 'New to me';

	/// en: 'Already started'
	String get inProgress => 'Already started';

	/// en: 'Revisit'
	String get revisit => 'Revisit';

	/// en: 'Taste controls'
	String get tasteControls => 'Taste controls';

	/// en: 'Choose styles to bring forward or gently push back. Not now never changes these preferences.'
	String get tasteControlsHelp => 'Choose styles to bring forward or gently push back. Not now never changes these preferences.';

	/// en: 'Bring forward'
	String get preferMore => 'Bring forward';

	/// en: 'Show less'
	String get showLess => 'Show less';

	/// en: 'Hide this pick'
	String get hideFromDiscovery => 'Hide this pick';

	/// en: 'Hidden picks'
	String get hiddenPicks => 'Hidden picks';

	/// en: 'No hidden picks'
	String get noHiddenPicks => 'No hidden picks';

	/// en: 'Reset taste and hidden picks'
	String get resetTaste => 'Reset taste and hidden picks';

	/// en: 'Clear genre preferences and restore every hidden pick?'
	String get resetTasteConfirm => 'Clear genre preferences and restore every hidden pick?';

	/// en: 'Choose together'
	String get chooseTogether => 'Choose together';

	/// en: 'Make a shortlist decision together'
	String get voteSetup => 'Make a shortlist decision together';

	/// en: 'Each guest votes privately on this device. Completed ballots stay covered; no votes or guest identities are saved.'
	String get votePrivacy => 'Each guest votes privately on this device. Completed ballots stay covered; no votes or guest identities are saved.';

	/// en: 'How many guests?'
	String get guestCount => 'How many guests?';

	/// en: 'Start private voting'
	String get beginVoting => 'Start private voting';

	/// en: 'Guest ${guest} of ${count}'
	String guestProgress({required Object guest, required Object count}) => 'Guest ${guest} of ${count}';

	/// en: 'Maybe'
	String get maybe => 'Maybe';

	/// en: 'Not tonight'
	String get notTonight => 'Not tonight';

	/// en: 'Pass the device'
	String get passDevice => 'Pass the device';

	/// en: 'The previous guest’s choices are covered. Hand the device to the next guest when ready.'
	String get passDeviceHint => 'The previous guest’s choices are covered. Hand the device to the next guest when ready.';

	/// en: 'Ready for next guest'
	String get readyNextGuest => 'Ready for next guest';

	/// en: 'No shared pick yet'
	String get noSharedPick => 'No shared pick yet';

	/// en: 'Every pick received at least one “Not tonight” vote. Widen the shortlist and try again.'
	String get noSharedPickHint => 'Every pick received at least one “Not tonight” vote. Widen the shortlist and try again.';

	/// en: 'You found a shared pick'
	String get sharedPick => 'You found a shared pick';

	/// en: '${title} received the strongest shared approval.'
	String sharedPickHint({required Object title}) => '${title} received the strongest shared approval.';

	/// en: 'Put this pick on the deck'
	String get useSharedPick => 'Put this pick on the deck';

	/// en: 'Widen the shortlist'
	String get widenShortlist => 'Widen the shortlist';

	/// en: 'Choose picks to vote on'
	String get selectToVote => 'Choose picks to vote on';

	/// en: 'Start voting'
	String get startVote => 'Start voting';

	/// en: 'Choose between 2 and 12 picks.'
	String get voteLimit => 'Choose between 2 and 12 picks.';

	/// en: 'Availability'
	String get availability => 'Availability';

	/// en: 'Check again when opened'
	String get availabilityNotChecked => 'Check again when opened';

	/// en: 'Find a library catalog pick'
	String get libraryCatalog => 'Find a library catalog pick';

	/// en: 'Search Open Library by this title. A catalog match is not proof that your local library owns or can lend it.'
	String get libraryCatalogHint => 'Search Open Library by this title. A catalog match is not proof that your local library owns or can lend it.';

	/// en: 'Open Library'
	String get openLibraryName => 'Open Library';

	/// en: 'Catalog record · availability not checked'
	String get catalogOnly => 'Catalog record · availability not checked';

	/// en: 'Optional AI ranking'
	String get aiRanking => 'Optional AI ranking';

	/// en: 'An external or loopback OpenAI-compatible service may reorder up to 24 eligible picks. The ordinary deck stays usable if it is off or unavailable.'
	String get aiRankingHelp => 'An external or loopback OpenAI-compatible service may reorder up to 24 eligible picks. The ordinary deck stays usable if it is off or unavailable.';

	/// en: 'Service URL'
	String get aiEndpoint => 'Service URL';

	/// en: 'Model name'
	String get aiModel => 'Model name';

	/// en: 'API key (optional for local services)'
	String get aiApiKey => 'API key (optional for local services)';

	/// en: 'Enable AI ranking'
	String get aiEnabled => 'Enable AI ranking';

	/// en: 'Review AI ranking data'
	String get aiConsentTitle => 'Review AI ranking data';

	/// en: 'When enabled, the configured service receives up to 24 picks with temporary IDs, title, media type, genre tags, metadata mood tags and your selected moment filters for media, time, genre, mood and familiarity. It receives no server or source IDs, URLs, filenames, playback history, account data, notes, credentials or content. Results can only reorder picks already eligible on this device.'
	String get aiConsentBody => 'When enabled, the configured service receives up to 24 picks with temporary IDs, title, media type, genre tags, metadata mood tags and your selected moment filters for media, time, genre, mood and familiarity. It receives no server or source IDs, URLs, filenames, playback history, account data, notes, credentials or content. Results can only reorder picks already eligible on this device.';

	/// en: 'AI ranking settings saved'
	String get aiSaved => 'AI ranking settings saved';

	/// en: 'Enter a model and a valid HTTPS URL, or use HTTP on this device only.'
	String get aiInvalidConfig => 'Enter a model and a valid HTTPS URL, or use HTTP on this device only.';

	/// en: 'A key is saved securely'
	String get aiSavedKey => 'A key is saved securely';

	/// en: 'Remove saved API key'
	String get aiClearKey => 'Remove saved API key';

	/// en: 'AI ranking was unavailable. Your usual discovery order is still active.'
	String get aiError => 'AI ranking was unavailable. Your usual discovery order is still active.';

	/// en: 'Watch'
	String get watch => 'Watch';

	/// en: 'Listen'
	String get listen => 'Listen';

	/// en: 'Read'
	String get read => 'Read';

	/// en: 'Finish in ${duration}'
	String finishable({required Object duration}) => 'Finish in ${duration}';

	/// en: 'About ${duration}'
	String aboutDuration({required Object duration}) => 'About ${duration}';

	/// en: 'Next chapter · ${duration}'
	String nextUnit({required Object duration}) => 'Next chapter · ${duration}';

	/// en: '${duration} total'
	String totalDuration({required Object duration}) => '${duration} total';

	/// en: 'Timing varies'
	String get timingVaries => 'Timing varies';

	/// en: 'Not now'
	String get notNow => 'Not now';

	/// en: 'Swipe the cover toward an arrow, or use the buttons below.'
	String get swipeHint => 'Swipe the cover toward an arrow, or use the buttons below.';

	/// en: 'Saved picks'
	String get saved => 'Saved picks';

	/// en: 'Select picks to compare'
	String get selectToCompare => 'Select picks to compare';

	/// en: 'Compare up to three picks at a time.'
	String get compareLimit => 'Compare up to three picks at a time.';

	/// en: 'Choose at least two saved picks to compare.'
	String get compareNeedsTwo => 'Choose at least two saved picks to compare.';

	/// en: 'On this device'
	String get localOnly => 'On this device';

	/// en: 'Sync Saved picks across devices'
	String get syncSavedPicks => 'Sync Saved picks across devices';

	/// en: 'Optional. Shares saved titles and public catalog IDs using your existing encrypted sync code. Server IDs, source addresses, credentials, playback history and previews are never included.'
	String get syncSavedPicksHelp => 'Optional. Shares saved titles and public catalog IDs using your existing encrypted sync code. Server IDs, source addresses, credentials, playback history and previews are never included.';

	/// en: 'These devices changed this saved pick independently. Choose which saved state to keep.'
	String get savedPickConflict => 'These devices changed this saved pick independently. Choose which saved state to keep.';

	/// en: 'Use this version'
	String get useThisVersion => 'Use this version';

	/// en: 'Saved picks · ${count}'
	String savedCount({required Object count}) => 'Saved picks · ${count}';

	/// en: 'Undo'
	String get undo => 'Undo';

	/// en: 'Details'
	String get details => 'Details';

	/// en: 'Nothing to choose from yet'
	String get noPicks => 'Nothing to choose from yet';

	/// en: 'Connect a library or add a media source to get started.'
	String get noPicksHint => 'Connect a library or add a media source to get started.';

	/// en: 'Nothing fits this moment'
	String get noMatches => 'Nothing fits this moment';

	/// en: 'Try another format or give yourself more time.'
	String get noMatchesHint => 'Try another format or give yourself more time.';

	/// en: 'You’re all caught up'
	String get allDone => 'You’re all caught up';

	/// en: 'Start a fresh mix to see these choices again.'
	String get allDoneHint => 'Start a fresh mix to see these choices again.';

	/// en: 'Find another mix'
	String get refresh => 'Find another mix';

	/// en: 'From ${source}'
	String sourceReason({required Object source}) => 'From ${source}';

	/// en: 'From ${library}'
	String libraryReason({required Object library}) => 'From ${library}';

	/// en: 'From your library'
	String get ownedReason => 'From your library';

	/// en: 'On now'
	String get liveNow => 'On now';

	/// en: 'Watch live'
	String get watchLive => 'Watch live';

	/// en: 'Anything'
	String get filterAnything => 'Anything';

	/// en: 'Watch'
	String get filterWatch => 'Watch';

	/// en: 'Listen'
	String get filterListen => 'Listen';

	/// en: 'Read'
	String get filterRead => 'Read';

	/// en: '20 min'
	String get twentyMinutes => '20 min';

	/// en: '45 min'
	String get fortyFiveMinutes => '45 min';

	/// en: '90 min'
	String get ninetyMinutes => '90 min';

	/// en: 'Apply'
	String get apply => 'Apply';

	/// en: 'This choice is no longer available. Refresh to check again.'
	String get openFailed => 'This choice is no longer available. Refresh to check again.';

	/// en: 'Could not save that change. Try again.'
	String get changeFailed => 'Could not save that change. Try again.';

	/// en: 'Saved picks is full. Remove a pick to save another.'
	String get savedLimit => 'Saved picks is full. Remove a pick to save another.';

	/// en: 'Open a pick, save it for later, or skip it.'
	String get chooseHint => 'Open a pick, save it for later, or skip it.';

	/// en: 'How it works'
	String get howItWorks => 'How it works';

	/// en: 'Skip this pick for now. It stays in your library.'
	String get notNowHelp => 'Skip this pick for now. It stays in your library.';

	/// en: 'Keep it in Saved picks for this profile on this device. Saving does not download it.'
	String get saveHelp => 'Keep it in Saved picks for this profile on this device. Saving does not download it.';

	/// en: 'Select the cover for details. Use the main action to play, read or open the title.'
	String get openHelp => 'Select the cover for details. Use the main action to play, read or open the title.';

	/// en: 'Keyboard or remote: focus a button, then press Enter or Select. Undo restores your last choice.'
	String get controlsHelp => 'Keyboard or remote: focus a button, then press Enter or Select. Undo restores your last choice.';

	/// en: 'Loading artwork…'
	String get artworkLoading => 'Loading artwork…';

	/// en: 'Artwork unavailable'
	String get artworkUnavailable => 'Artwork unavailable';

	/// en: 'Saved to Saved picks'
	String get savedFeedback => 'Saved to Saved picks';

	/// en: 'Skipped for now'
	String get skippedFeedback => 'Skipped for now';

	/// en: 'Release to confirm'
	String get releaseToConfirm => 'Release to confirm';

	/// en: 'Cover focused: ← / → choose · Select opens details · ↑ / ↓ moves focus'
	String get remoteHint => 'Cover focused: ← / → choose · Select opens details · ↑ / ↓ moves focus';
}

// Path: discover.person
class Translations$discover$person$en {
	Translations$discover$person$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Born'
	String get born => 'Born';

	/// en: 'Died'
	String get died => 'Died';

	/// en: 'Birthplace'
	String get birthplace => 'Birthplace';

	/// en: '${date} (age ${age})'
	String dateWithAge({required Object date, required Object age}) => '${date} (age ${age})';

	/// en: '${date} (aged ${age})'
	String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (aged ${age})';
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

	/// en: 'File Path'
	String get filePath => 'File Path';
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

	/// en: 'Date Downloaded'
	String get dateDownloaded => 'Date Downloaded';

	/// en: 'Size'
	String get size => 'Size';

	/// en: 'Library'
	String get library => 'Library';
}

// Path: libraries.advancedFilters
class Translations$libraries$advancedFilters$en {
	Translations$libraries$advancedFilters$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Include'
	String get include => 'Include';

	/// en: 'Exclude'
	String get exclude => 'Exclude';

	/// en: 'Any'
	String get any => 'Any';

	/// en: 'Yes'
	String get yes => 'Yes';

	/// en: 'No'
	String get no => 'No';

	/// en: 'Not ${value}'
	String not({required Object value}) => 'Not ${value}';

	/// en: '${count} selected'
	String valueCount({required Object count}) => '${count} selected';

	/// en: '${count} excluded'
	String valueCountExcluded({required Object count}) => '${count} excluded';

	/// en: 'Search values'
	String get searchValues => 'Search values';

	/// en: 'No values'
	String get noValues => 'No values';

	/// en: 'Contains'
	String get matchContains => 'Contains';

	/// en: 'Does not contain'
	String get matchNotContains => 'Does not contain';

	/// en: 'Is'
	String get matchIs => 'Is';

	/// en: 'Is not'
	String get matchIsNot => 'Is not';

	/// en: 'Begins with'
	String get matchBeginsWith => 'Begins with';

	/// en: 'Ends with'
	String get matchEndsWith => 'Ends with';

	/// en: 'Type to match'
	String get textHint => 'Type to match';

	/// en: 'From'
	String get from => 'From';

	/// en: 'To'
	String get to => 'To';

	/// en: '${from} to ${to}'
	String range({required Object from, required Object to}) => '${from} to ${to}';

	/// en: '${value} and up'
	String atLeast({required Object value}) => '${value} and up';

	/// en: 'Up to ${value}'
	String atMost({required Object value}) => 'Up to ${value}';

	/// en: 'Last ${count} days'
	String dateLastDays({required Object count}) => 'Last ${count} days';

	/// en: 'Past year'
	String get dateLastYear => 'Past year';

	/// en: 'Older than ${count} days'
	String dateOlderThanDays({required Object count}) => 'Older than ${count} days';

	/// en: 'Older than a year'
	String get dateOlderThanYear => 'Older than a year';
}

// Path: libraries.selection
class Translations$libraries$selection$en {
	Translations$libraries$selection$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Select items'
	String get selectItems => 'Select items';

	/// en: '${count} selected'
	String selectedCount({required Object count}) => '${count} selected';

	/// en: 'Selection actions'
	String get actions => 'Selection actions';

	/// en: 'This changes all episodes in the selected shows and seasons.'
	String get confirmDescendants => 'This changes all episodes in the selected shows and seasons.';

	/// en: 'This also clears playback progress for the selected items.'
	String get confirmUnwatched => 'This also clears playback progress for the selected items.';

	/// en: 'Selected items: ${count}.'
	String confirmCount({required Object count}) => 'Selected items: ${count}.';

	/// en: 'Items updated: ${count}.'
	String completed({required Object count}) => 'Items updated: ${count}.';

	/// en: 'Updated ${succeeded}; failed ${failed}. Failed items remain selected.'
	String partialFailure({required Object succeeded, required Object failed}) => 'Updated ${succeeded}; failed ${failed}. Failed items remain selected.';
}

// Path: explore.mdblistShelves
class Translations$explore$mdblistShelves$en {
	Translations$explore$mdblistShelves$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Manage Explore shelves'
	String get manage => 'Manage Explore shelves';

	/// en: 'Choose and arrange lists from your MDBList account'
	String get manageDescription => 'Choose and arrange lists from your MDBList account';

	/// en: 'Choose public movie and TV lists from your MDBList account. Create or copy lists on MDBList, then refresh.'
	String get description => 'Choose public movie and TV lists from your MDBList account. Create or copy lists on MDBList, then refresh.';

	/// en: 'Selected shelves'
	String get selected => 'Selected shelves';

	/// en: 'Available account lists'
	String get available => 'Available account lists';

	/// en: 'No public movie or TV lists returned. Create or copy a list on MDBList, then refresh.'
	String get noLists => 'No public movie or TV lists returned. Create or copy a list on MDBList, then refresh.';

	/// en: 'Shelf display name'
	String get displayName => 'Shelf display name';

	/// en: 'Leave blank to use the source list name.'
	String get nameHint => 'Leave blank to use the source list name.';

	/// en: 'Add shelf'
	String get add => 'Add shelf';

	/// en: 'Save shelves'
	String get save => 'Save shelves';

	/// en: 'Move ${title} up'
	String moveUp({required Object title}) => 'Move ${title} up';

	/// en: 'Move ${title} down'
	String moveDown({required Object title}) => 'Move ${title} down';

	/// en: 'This list is unavailable. Retry or remove its shelf in settings.'
	String get unavailable => 'This list is unavailable. Retry or remove its shelf in settings.';

	/// en: 'MDBList request limit reached. Please retry later.'
	String get rateLimited => 'MDBList request limit reached. Please retry later.';

	/// en: 'Could not load shelves. Check your connection and retry.'
	String get loadFailed => 'Could not load shelves. Check your connection and retry.';

	/// en: 'Could not save shelves. Please retry.'
	String get saveFailed => 'Could not save shelves. Please retry.';

	/// en: 'The account or profile changed. Reopen these settings.'
	String get accountChanged => 'The account or profile changed. Reopen these settings.';

	/// en: 'Saved shelves could not be read. Select your lists again to replace these settings.'
	String get settingsUnreadable => 'Saved shelves could not be read. Select your lists again to replace these settings.';
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

	/// en: '(one) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} comment} (other) {${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} comments}'
	String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} comment',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} comments',
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

	/// en: 'Actor'
	String get actor => 'Actor';

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

	/// en: '(one) {Recommended by ${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} user} (other) {Recommended by ${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} users}'
	String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'Recommended by ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} user',
		other: 'Recommended by ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} users',
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

// Path: watchTogether.notices
class Translations$watchTogether$notices$en {
	Translations$watchTogether$notices$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: '${name} pressed play'
	String pressedPlay({required Object name}) => '${name} pressed play';

	/// en: 'Playback started'
	String get playbackStarted => 'Playback started';

	/// en: '${name} paused'
	String paused({required Object name}) => '${name} paused';

	/// en: 'Playback paused'
	String get playbackPaused => 'Playback paused';

	/// en: '${name} jumped to ${position}'
	String jumpedTo({required Object name, required Object position}) => '${name} jumped to ${position}';

	/// en: 'Jumped to ${position}'
	String roomJumpedTo({required Object position}) => 'Jumped to ${position}';

	/// en: '${name} set the speed to ${speed}'
	String changedSpeed({required Object name, required Object speed}) => '${name} set the speed to ${speed}';

	/// en: 'Speed set to ${speed}'
	String speedChanged({required Object speed}) => 'Speed set to ${speed}';

	/// en: '${name} started ${title}'
	String startedMedia({required Object name, required Object title}) => '${name} started ${title}';

	/// en: 'Now playing ${title}'
	String mediaStarted({required Object title}) => 'Now playing ${title}';

	/// en: '${name} stopped the video'
	String stoppedMedia({required Object name}) => '${name} stopped the video';

	/// en: 'The video stopped'
	String get mediaStopped => 'The video stopped';

	/// en: 'Waiting for ${name}...'
	String waitingFor({required Object name}) => 'Waiting for ${name}...';

	/// en: 'Waiting for someone to catch up...'
	String get waitingForSomeone => 'Waiting for someone to catch up...';

	/// en: 'Finished'
	String get finished => 'Finished';

	/// en: '${name} is now the host'
	String hostChangedTo({required Object name}) => '${name} is now the host';

	/// en: 'You are now the host'
	String get youAreNowHost => 'You are now the host';

	/// en: '${name} joined'
	String joined({required Object name}) => '${name} joined';

	/// en: '${name} left'
	String left({required Object name}) => '${name} left';

	/// en: 'Only the host can control playback'
	String get controlRefused => 'Only the host can control playback';

	/// en: 'Some servers couldn't be searched for the room's video'
	String get searchFailed => 'Some servers couldn\'t be searched for the room\'s video';

	/// en: 'Press play to start'
	String get playBlocked => 'Press play to start';

	/// en: 'Couldn't share this video with the room'
	String get shareFailed => 'Couldn\'t share this video with the room';

	/// en: 'Downloads aren't shared with the room while their server is offline'
	String get downloadNotShared => 'Downloads aren\'t shared with the room while their server is offline';

	/// en: 'Couldn't open the room's video'
	String get openFailed => 'Couldn\'t open the room\'s video';
}

// Path: watchTogether.ended
class Translations$watchTogether$ended$en {
	Translations$watchTogether$ended$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'The host ended the room'
	String get ended => 'The host ended the room';

	/// en: 'You were removed from the room'
	String get kicked => 'You were removed from the room';

	/// en: 'The room expired'
	String get expired => 'The room expired';

	/// en: 'You joined this room on another device'
	String get replaced => 'You joined this room on another device';

	/// en: 'Lost the connection to the room'
	String get lost => 'Lost the connection to the room';
}

// Path: watchTogether.errors
class Translations$watchTogether$errors$en {
	Translations$watchTogether$errors$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'That isn't a room code. Codes have 6 letters and digits, without 0, 1, I, L or O.'
	String get invalidCode => 'That isn\'t a room code. Codes have 6 letters and digits, without 0, 1, I, L or O.';

	/// en: 'No room has that code. It may have ended.'
	String get roomNotFound => 'No room has that code. It may have ended.';

	/// en: 'That room is full.'
	String get roomFull => 'That room is full.';

	/// en: 'The host locked that room.'
	String get roomLocked => 'The host locked that room.';

	/// en: 'Watch Together is busy right now. Try again later.'
	String get relayFull => 'Watch Together is busy right now. Try again later.';

	/// en: 'Couldn't reach the Watch Together relay. Check your connection.'
	String get unreachable => 'Couldn\'t reach the Watch Together relay. Check your connection.';

	/// en: 'Too many attempts. Wait a moment and try again.'
	String get rateLimited => 'Too many attempts. Wait a moment and try again.';

	/// en: 'This version of PlezyNG can't use the relay. Update the app.'
	String get clientBlocked => 'This version of PlezyNG can\'t use the relay. Update the app.';

	/// en: 'Only the host can do that.'
	String get forbidden => 'Only the host can do that.';

	/// en: 'You're not in a room.'
	String get notInRoom => 'You\'re not in a room.';

	/// en: 'You're already in a room.'
	String get alreadyInRoom => 'You\'re already in a room.';

	/// en: 'Couldn't rejoin the room.'
	String get resumeFailed => 'Couldn\'t rejoin the room.';

	/// en: 'The relay doesn't support this.'
	String get unsupported => 'The relay doesn\'t support this.';

	/// en: 'Something went wrong. Try again.'
	String get generic => 'Something went wrong. Try again.';
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

	/// en: 'Android is preventing PlezyNG from downloading reliably in the background.'
	String get sheetIntro => 'Android is preventing PlezyNG from downloading reliably in the background.';

	/// en: 'Your device is limiting when PlezyNG can download in the background.'
	String get sheetIntroDegraded => 'Your device is limiting when PlezyNG can download in the background.';

	/// en: 'PlezyNG's background usage is restricted. Set its battery or background usage to "Unrestricted".'
	String get reasonBackgroundRestricted => 'PlezyNG\'s background usage is restricted. Set its battery or background usage to "Unrestricted".';

	/// en: 'Android has put PlezyNG in a restricted standby state. Set its battery usage to "Unrestricted".'
	String get reasonStandbyRestricted => 'Android has put PlezyNG in a restricted standby state. Set its battery usage to "Unrestricted".';

	/// en: 'Download notifications are turned off, so progress and controls may be unavailable.'
	String get reasonDownloadChannelBlocked => 'Download notifications are turned off, so progress and controls may be unavailable.';

	/// en: 'Notifications are turned off. On Android 13 or newer, they are required for long background downloads.'
	String get reasonNotificationsDisabled => 'Notifications are turned off. On Android 13 or newer, they are required for long background downloads.';

	/// en: 'Data Saver is on, which blocks background downloads on mobile data. Downloads should still run on Wi-Fi.'
	String get reasonDataSaver => 'Data Saver is on, which blocks background downloads on mobile data. Downloads should still run on Wi-Fi.';

	/// en: 'Downloads repeatedly stopped while PlezyNG was in the background. Check PlezyNG's battery or background usage settings.'
	String get reasonOemUnknown => 'Downloads repeatedly stopped while PlezyNG was in the background. Check PlezyNG\'s battery or background usage settings.';

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

// Path: downloads.groupings
class Translations$downloads$groupings$en {
	Translations$downloads$groupings$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Library'
	String get library => 'Library';

	/// en: 'Collections'
	String get collections => 'Collections';
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

	/// en: 'PlezyNG devices with the same Plex account appear here'
	String get discoveryDescription => 'PlezyNG devices with the same Plex account appear here';

	/// en: '192.168.1.100:48632'
	String get hostAddressHint => '192.168.1.100:48632';

	/// en: 'Connecting...'
	String get connecting => 'Connecting...';

	/// en: 'Looking for devices...'
	String get searchingForDevices => 'Looking for devices...';

	/// en: 'No devices found on your network'
	String get noDevicesFound => 'No devices found on your network';

	/// en: 'Open PlezyNG on desktop and use the same Wi-Fi'
	String get noDevicesHint => 'Open PlezyNG on desktop and use the same Wi-Fi';

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

	/// en: 'Device not found. Make sure PlezyNG is running on the host.'
	String get sessionNotFound => 'Device not found. Make sure PlezyNG is running on the host.';

	/// en: 'Authentication failed. Both devices need the same Plex account.'
	String get authFailed => 'Authentication failed. Both devices need the same Plex account.';

	/// en: 'Failed to connect: ${error}'
	String failedToConnect({required Object error}) => 'Failed to connect: ${error}';

	/// en: 'Pairing code'
	String get codeTitle => 'Pairing code';

	/// en: 'Enter the code shown in Companion Remote on the host device. Both devices must use a version that supports secure pairing.'
	String get codeDescription => 'Enter the code shown in Companion Remote on the host device. Both devices must use a version that supports secure pairing.';

	/// en: 'Enter all 32 letters and numbers from the host code.'
	String get codeInvalid => 'Enter all 32 letters and numbers from the host code.';

	/// en: 'Update both devices to a version that supports secure pairing.'
	String get updateRequired => 'Update both devices to a version that supports secure pairing.';

	/// en: 'Enter this code once on each remote. Keep it private: it grants control of this profile.'
	String get hostDescription => 'Enter this code once on each remote. Keep it private: it grants control of this profile.';

	/// en: 'Reset pairing code'
	String get resetCode => 'Reset pairing code';

	/// en: 'Disconnect all remotes and create a new code. Every remote will need to pair again.'
	String get resetDescription => 'Disconnect all remotes and create a new code. Every remote will need to pair again.';
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

// Path: services.simklReconnect
class Translations$services$simklReconnect$en {
	Translations$services$simklReconnect$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Reconnect Simkl'
	String get title => 'Reconnect Simkl';

	/// en: 'Simkl is retiring the sign-in method this connection uses. Reconnecting opens simkl.com to approve PlezyNG — PlezyNG never sees your password. Your watch history stays on Simkl.'
	String get subtitle => 'Simkl is retiring the sign-in method this connection uses. Reconnecting opens simkl.com to approve PlezyNG — PlezyNG never sees your password. Your watch history stays on Simkl.';
}

// Path: services.deviceCode
class Translations$services$deviceCode$en {
	Translations$services$deviceCode$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Activate PlezyNG on ${service}'
	String title({required Object service}) => 'Activate PlezyNG on ${service}';

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

	/// en: 'Choose whether the checked libraries are blocked from syncing or are the only libraries that sync.'
	String get modeDescription => 'Choose whether the checked libraries are blocked from syncing or are the only libraries that sync.';
}

// Path: services.trackerDescriptions
class Translations$services$trackerDescriptions$en {
	Translations$services$trackerDescriptions$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Sync watched episodes and movies with your Trakt account.'
	String get trakt => 'Sync watched episodes and movies with your Trakt account.';

	/// en: 'Sync anime lists and watch progress with MyAnimeList.'
	String get mal => 'Sync anime lists and watch progress with MyAnimeList.';

	/// en: 'Sync anime lists and watch progress with AniList.'
	String get anilist => 'Sync anime lists and watch progress with AniList.';

	/// en: 'Sync watched movies, TV shows, and anime with Simkl.'
	String get simkl => 'Sync watched movies, TV shows, and anime with Simkl.';

	/// en: 'Show MDBList ratings and lists in recommendations and Explore.'
	String get mdblist => 'Show MDBList ratings and lists in recommendations and Explore.';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'appIcon.title' => 'App icon',
			'appIcon.defaultIcon' => 'Default',
			'appIcon.current' => 'Current icon',
			'appIcon.locked' => 'Lifetime access required',
			'appIcon.lockedHint' => 'Start your 7-day trial or unlock PlezyNG for life to use alternate icons.',
			'appIcon.changeFailed' => 'Couldn\'t change the app icon',
			'appIcon.launcherHint' => 'The new icon appears on your home screen once you leave PlezyNG.',
			'appIcon.tvLauncherHint' => 'The new banner appears once you leave PlezyNG. Android TV can keep showing the old one until the TV restarts.',
			'appIcon.names.midnight' => 'Midnight',
			'appIcon.names.ember' => 'Ember',
			'appIcon.names.paper' => 'Paper',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => 'Line',
			'appIcon.names.ocean' => 'Ocean',
			'appIcon.names.ultraviolet' => 'Ultraviolet',
			'appIcon.names.matcha' => 'Matcha',
			'appIcon.names.sunset' => 'Sunset',
			'appIcon.names.gold' => 'Gold',
			'appIcon.names.titanium' => 'Titanium',
			'appIcon.names.glass' => 'Glass',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => 'Synthwave',
			'appIcon.names.pixel' => 'Pixel',
			'appIcon.names.neon' => 'Neon',
			'appIcon.names.sticker' => 'Sticker',
			'appIcon.names.ticket' => 'Ticket',
			'appIcon.names.pop' => 'Pop',
			'appIcon.names.strata' => 'Strata',
			'appIcon.names.facet' => 'Facet',
			'appIcon.names.tilde' => 'Tilde',
			'appIcon.description' => 'Choose the icon shown by your device launcher. The previews show how each option looks.',
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
			'auth.localDataRecoveryRequired' => 'PlezyNG could not safely recover local sign-in and pending playback data. Please sign in again.',
			'auth.pinCheckRejected' => 'The Plex PIN check was rejected',
			'auth.connectToDirectPlex' => 'Connect to local Plex server',
			'common.cancel' => 'Cancel',
			'common.save' => 'Save',
			'common.close' => 'Close',
			'common.closeMiniPlayer' => 'Close mini player',
			'common.closeWorkspaceWindow' => 'Close window',
			'common.returnToFullView' => 'Return to full view',
			'common.manageMediaSessions' => 'Manage media sessions',
			'common.hideMediaSessions' => 'Hide media sessions',
			'common.mediaSessions' => 'Media sessions',
			'common.mediaSessionsHint' => 'Select to bring a session forward. Park hides its window but keeps it open. Return opens it in full view; close ends it.',
			'common.sessionInWorkspace' => 'In workspace',
			'common.sessionParked' => 'Parked',
			'common.sessionFullscreen' => 'Full screen',
			'common.switchToNextWindow' => 'Swap with next window',
			'common.moveWindow' => 'Move window',
			'common.finishMovingWindow' => 'Finish moving window',
			'common.moveWindowHint' => 'Long-press and drag the window to move it. This control also enables arrow-key movement.',
			'common.movingWindowHelp' => 'Drag to move · Arrow keys adjust · Enter saves · Escape cancels',
			'common.resizeWindow' => 'Resize window',
			'common.resizeWindowHint' => 'Drag this handle or use the arrow keys to resize the window.',
			'common.workspaceWindowHint' => 'Use the move control or long-press and drag to move. Use the resize handle to resize.',
			'common.workspacePaneHint' => 'Select this pane to focus it. Use its fullscreen control to expand.',
			'common.workspaceWindowLabel' => ({required Object title}) => 'Session window: ${title}',
			'common.workspaceTitleHint' => 'Select to focus. Drag the title bar to move; use the fullscreen button to expand.',
			'common.moveToSessionTray' => 'Move to session tray',
			'common.moveToSessionTrayHint' => 'Keeps this session available without showing its window.',
			'common.closeSessionHint' => 'Closes this window and ends its session.',
			'common.sideBySideLayout' => 'Switch to side-by-side layout',
			'common.floatingWindows' => 'Switch to floating windows',
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
			'common.compare' => 'Compare',
			'common.addTo' => 'Add to...',
			'common.createNew' => 'Create new',
			'common.connect' => 'Connect',
			'common.disconnect' => 'Disconnect',
			'common.play' => 'Play',
			'common.pause' => 'Pause',
			'common.resume' => 'Resume',
			'common.error' => 'Error',
			'common.search' => 'Search',
			'common.preview' => 'Preview',
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
			'common.ratingSource.metacritic' => 'Metacritic',
			'common.ratingSource.letterboxd' => 'Letterboxd',
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
			'settings.supportDeveloper' => 'Support PlezyNG',
			'settings.supportDeveloperDescription' => 'Donate to support development',
			'settings.lifetimeAccess' => 'PlezyNG lifetime access',
			'settings.language' => 'Language',
			'settings.theme' => 'Theme',
			'settings.appearance' => 'Appearance',
			'settings.detailPage' => 'Detail Page',
			'settings.themeSongsEnabled' => 'Play Theme Songs',
			'settings.themeSongsEnabledDescription' => 'Play available theme songs while viewing media details.',
			'settings.themeSongVolume' => 'Theme Song Volume',
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
			'settings.durationHint' => ({required Object min, required Object max}) => 'Enter a value (${min}-${max})',
			'settings.systemTheme' => 'System',
			'settings.lightTheme' => 'Light',
			'settings.darkTheme' => 'Dark',
			'settings.oledTheme' => 'OLED',
			'settings.emberTheme' => 'Ember',
			'settings.glacierTheme' => 'Glacier',
			'settings.forestTheme' => 'Forest',
			'settings.plumTheme' => 'Plum',
			'settings.paperTheme' => 'Paper',
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
			'settings.showHomeBackdrop' => 'Show home backdrop artwork',
			'settings.showHomeBackdropDescription' => 'Show large artwork behind featured Home rows',
			'settings.contentScreensaverEnabled' => 'Content screensaver',
			'settings.contentScreensaverEnabledDescription' => 'Show full-screen artwork after the app has been idle',
			'settings.contentScreensaverDelay' => 'Start screensaver after',
			'settings.contentScreensaverLibraries' => 'Screensaver libraries',
			'settings.contentScreensaverLibrariesDescription' => 'Choose which libraries provide screensaver artwork. If none are selected, artwork from all libraries is used.',
			'settings.contentScreensaverAllLibraries' => 'All libraries',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} libraries selected',
			'settings.contentScreensaverNoLibraries' => 'No connected media libraries are available.',
			'settings.contentScreensaverDismissHint' => 'Press any button or tap to dismiss',
			'settings.newEpisodeNotifications' => 'New episode notifications',
			'settings.newEpisodeNotificationsDescription' => 'Alert when a new episode is added to a show you are caught up on. Checks while Plezy is open.',
			'settings.continueWatchingRowSize' => 'Continue Watching row size',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => '${label} cards',
			'settings.rowSizeCompact' => 'Compact',
			'settings.rowSizeStandard' => 'Standard',
			'settings.rowSizeLarge' => 'Large',
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
			'settings.streamBufferSize' => 'Buffer Size',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} MB',
			'settings.streamBufferSizeDescription' => 'How much video to load ahead when direct playing. Transcodes stop at the server\'s own transcode buffer. 0 = Auto',
			'settings.streamBufferSizeExoNote' => 'Replaces Playback Buffer when set, capped at half of the app\'s memory limit',
			'settings.streamBufferMegabytes' => 'Megabytes',
			'settings.defaultQualityTitle' => 'Default Quality',
			'settings.cellularQualityTitle' => 'Default Quality on Cellular',
			'settings.remoteQualityTitle' => 'Remote Streaming Quality',
			'settings.remoteQualitySameAsDefault' => 'Same as default quality',
			'settings.cellularQualitySameAsDefault' => 'Same as Default Quality',
			'settings.directPlayCoveredQuality' => 'Play Smaller Videos at Original Quality',
			'settings.directPlayCoveredQualityDescription' => 'Direct play videos already within the quality limit instead of transcoding them',
			'settings.videoCodecs' => 'Video Codecs',
			'settings.videoCodecsDescription' => 'Unchecked codecs are transcoded by the server',
			'settings.videoCodecsAlwaysAccepted' => 'Always accepted',
			'settings.musicQualityTitle' => 'Music Quality',
			'settings.subtitleStyling' => 'Subtitle Styling',
			'settings.subtitleStylingDescription' => 'Customize subtitle appearance',
			'settings.smallSkipDuration' => 'Small Skip Duration',
			'settings.largeSkipDuration' => 'Large Skip Duration',
			'settings.rewindOnResume' => 'Rewind on Resume',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(seconds, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} seconds', one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} second', ), 
			'settings.defaultSleepTimer' => 'Default Sleep Timer',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(minutes, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutes', one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minute', ), 
			'settings.rememberTrackSelections' => 'Remember track selections per show/movie',
			'settings.chooseTracksBeforePlayback' => 'Choose audio and subtitles before playback',
			'settings.chooseTracksBeforePlaybackDescription' => 'Pick the source audio and subtitle tracks before each video starts.',
			'settings.alwaysShowSubtitlesOnDevice' => 'Always show subtitles on this device',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => 'When the server has no subtitle selected, choose a track locally. This never changes the server\'s preference.',
			'settings.autoDownloadPreferredSubtitle' => 'Fetch missing preferred-language subtitles',
			'settings.autoDownloadPreferredSubtitleDescription' => 'Select an available subtitle in your preferred language locally. If none exists, ask the server to fetch one when supported. The selection stays on this device.',
			'settings.rememberTrackSelectionsDescription' => 'Store audio and subtitle choices by show or movie on this device',
			'settings.rememberTrackSelectionsBackendRule' => 'Works locally with Plex, Jellyfin, and Emby; Plex and Jellyfin can also save selections on the server',
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
			'settings.watchTogetherRelayDescription' => 'Public Open Watch Party relays unless you set your own',
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
			'settings.importSettingsInvalidFile' => 'This file isn\'t a valid PlezyNG settings export',
			'settings.importSettingsNoUser' => 'Sign in before importing settings',
			'settings.cloudBackup' => 'Cloud Backup',
			'settings.cloudBackupDescription' => 'Back up portable settings to a WebDAV endpoint over HTTPS. Server connections and credentials stay on this device.',
			'settings.cloudBackupUrl' => 'WebDAV JSON file URL',
			'settings.cloudBackupUsername' => 'Username',
			'settings.cloudBackupPassword' => 'Password',
			'settings.cloudBackupSaved' => 'Cloud backup destination saved',
			'settings.cloudBackupNow' => 'Back Up Now',
			'settings.cloudBackupComplete' => 'Settings backup uploaded',
			'settings.cloudBackupRestore' => 'Restore Backup',
			'settings.cloudBackupRestoreConfirm' => 'This will replace matching portable settings on this device. Continue?',
			'settings.cloudBackupRestored' => 'Settings restored from cloud backup',
			'settings.shortcutsReset' => 'Shortcuts reset to defaults',
			'settings.resetShortcutsConfirm' => 'This will replace your custom shortcuts with the defaults. Continue?',
			'settings.about' => 'About',
			'settings.aboutDescription' => 'App information and licenses',
			'settings.updates' => 'Updates',
			'settings.updateAvailable' => 'Update Available',
			'settings.checkForUpdates' => 'Check for Updates',
			'settings.autoCheckUpdatesOnStartup' => 'Automatically check for updates on startup',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Notify when an update is available at launch',
			'settings.validationErrorEnterNumber' => 'Please enter a valid number',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Must be between ${min} and ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Shortcut already assigned to ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Shortcut updated for ${action}',
			'settings.saveFailed' => 'Could not save changes. Try again.',
			'settings.autoPlayAndSkip' => 'Auto-Play & Skip',
			'settings.autoPlayNextEpisode' => 'Auto-Play Next Episode',
			'settings.autoPlayNextEpisodeDescription' => 'Start the next episode automatically when one ends',
			'settings.shuffleStartsFromBeginning' => 'Shuffle Starts at Beginning',
			'settings.shuffleStartsFromBeginningDescription' => 'Start each episode at the beginning when shuffling instead of resuming',
			'settings.plexCinemaPreRoll' => 'Use server cinema intros',
			'settings.plexCinemaPreRollDescription' => 'Play configured Plex pre-rolls or Jellyfin and Emby intros before a movie starts.',
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
			'settings.skipAdsMode' => 'Skip Ads',
			'settings.skipAdsModeOffDescription' => 'Play detected ads normally without a skip button',
			'settings.skipAdsModeButtonDescription' => 'Show a skip button when Plex detects an ad',
			'settings.skipAdsModeAutoDescription' => 'Skip detected ads automatically after the delay below',
			'settings.musicPlayback' => 'Music Playback',
			'settings.musicSweetFades' => 'Sweet Fades',
			'settings.musicSweetFadesDescription' => 'Fade music at track edges when Plex has loudness data. Album playback stays unchanged.',
			'settings.skipMarkerModeOff' => 'Off',
			'settings.skipMarkerModeButton' => 'Show button',
			'settings.skipMarkerModeAuto' => 'Automatic',
			'settings.forceSkipMarkerFallback' => 'Force Fallback Markers',
			'settings.forceSkipMarkerFallbackDescription' => 'Use chapter title patterns even when Plex has markers',
			'settings.theIntroDbFallback' => 'Use TheIntroDB as an intro fallback',
			'settings.theIntroDbFallbackDescription' => 'Use community timings only when the server has no intro marker. Matches can vary by release.',
			'settings.autoSkipDelay' => 'Auto Skip Delay',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Wait ${seconds} seconds before auto-skipping',
			'settings.introPattern' => 'Intro Marker Pattern',
			'settings.introPatternDescription' => 'Regex pattern to match intro markers in chapter titles',
			'settings.creditsPattern' => 'Credits Marker Pattern',
			'settings.creditsPatternDescription' => 'Regex pattern to match credits markers in chapter titles',
			'settings.prerolls' => 'Prerolls',
			'settings.playPrerollsBeforeMovies' => 'Play prerolls before movies',
			'settings.playPrerollsBeforeMoviesDescription' => 'Plays a random clip from your selection below before each movie. Press back to skip.',
			'settings.prerollLibrary' => 'Preroll library',
			'settings.prerollLibraryNotSet' => 'Not set',
			'settings.prerollLibraryNoneFound' => 'No libraries found on your servers.',
			'settings.prerollSelection' => 'Selected prerolls',
			'settings.prerollSelectionPickLibraryFirst' => 'Pick a library first',
			'settings.prerollSelectionNoneSelected' => 'No prerolls selected',
			'settings.prerollSelectionCount' => ({required Object count}) => '${count} selected',
			'settings.prerollItemPicker' => 'Select prerolls',
			'settings.prerollItemPickerLoadFailed' => 'Couldn\'t load items from this library.',
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
			'settings.autoDownloadContinueWatching' => 'Auto-download Continue Watching',
			'settings.autoDownloadContinueWatchingDescription' => 'Keep items on your Continue Watching shelf downloaded, and remove them once they leave the shelf',
			'settings.downloadQuality' => 'Download quality',
			'settings.downloadQualityDescription' => 'Plex prepares a converted copy in its download queue. Jellyfin and Emby transcode while the file downloads; interrupted transfers may need to restart.',
			'settings.askDownloadQualityEachTime' => 'Choose quality for each download',
			'settings.askDownloadQualityEachTimeDescription' => 'Show the quality picker before queueing each video download',
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
			'settings.companionRemoteServerStartFailed' => 'Couldn\'t start the companion server',
			'settings.companionRemoteServerStopFailed' => 'Couldn\'t stop the companion server',
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
			'settings.audioPassthroughDescriptionApple' => 'Use Apple\'s native Dolby decoder for Dolby Digital Plus, including Atmos. DTS and TrueHD still play as multichannel PCM. Turn off if you have no sound.',
			'settings.audioPassthroughDescriptionAppleSpatial' => 'Use Apple\'s native Dolby decoder for Dolby Digital Plus, including Atmos. On iOS, iPadOS and tvOS 26 or later, TrueHD Atmos and DTS:X play as spatial audio. Other DTS and TrueHD tracks play as multichannel PCM. Turn off if you have no sound.',
			'settings.audioPassthroughOverriddenByNormalization' => 'Off while loudness normalization is on',
			'settings.audioChannelLimit' => 'Audio Channels',
			'settings.audioChannelLimitDescription' => 'Mix decoded audio down for speakers, headphones, or HDMI setups that cannot play every channel',
			'settings.audioChannelLimitOriginal' => 'Original',
			'settings.audioChannelLimitOriginalDescription' => 'Play every channel in the track',
			'settings.audioChannelLimitSurround51' => 'Up to 5.1',
			'settings.audioChannelLimitSurround51Description' => 'Mix 7.1 down to 5.1 for TVs and receivers that only take 5.1 PCM. Passthrough is unaffected.',
			'settings.audioChannelLimitStereo' => 'Stereo',
			'settings.audioChannelLimitStereoDescription' => 'Mix down to two channels for stereo speakers or headphones. Turns passthrough off.',
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
			'settings.experimentalDolbyVision' => 'Experimental Dolby Vision',
			'settings.experimentalDolbyVisionDescription' => 'Use the experimental FEL renderer on the next playback. Requires a separate engine build.',
			'settings.dvExperimentUnavailableDescription' => 'This experiment is currently available on Linux only.',
			'settings.dvCompatibilityFallback' => 'Compatibility fallback',
			'settings.dvCompatibilityFallbackDescription' => 'Use the standard renderer if the experiment cannot start. FEL data may be lost.',
			'settings.dvExperimentDiagnostics' => 'Video experiment logging',
			'settings.dvExperimentDiagnosticsDescription' => 'Enable detailed player logs on the next playback.',
			'settings.disableDolbyVision' => 'Disable Dolby Vision',
			'settings.disableDolbyVisionDescription' => 'Play the file\'s HDR10 or HLG layer instead of Dolby Vision, when it has one',
			_ => null,
		} ?? switch (path) {
			'settings.hdrSdrConversion' => 'HDR to SDR Conversion',
			'settings.hdrSdrConversionDescription' => 'Choose what converts HDR video when the display can\'t show HDR.',
			'settings.hdrSdrConversionAuto' => 'Auto',
			'settings.hdrSdrConversionAutoDescription' => 'Device on Android 9 and later, player on older versions',
			'settings.hdrSdrConversionDevice' => 'Device',
			'settings.hdrSdrConversionDeviceDescription' => 'Your device\'s video hardware converts it. Fastest, but colors depend on the device',
			'settings.hdrSdrConversionPlayer' => 'Player',
			'settings.hdrSdrConversionPlayerDescription' => 'The player converts it. Consistent colors, but 4K may stutter on low-end TV boxes',
			'settings.deinterlace' => 'Deinterlacing',
			'settings.deinterlaceDescription' => 'Remove combing artifacts from interlaced video (mpv player only)',
			'settings.deinterlaceOff' => 'Off',
			'settings.deinterlaceOffDescription' => 'Show interlaced video as it is decoded',
			'settings.deinterlaceVideo' => 'Video',
			'settings.deinterlaceVideoDescription' => 'Turn each field into a full frame. For video shot for TV, like sports, news, and concerts',
			'settings.deinterlaceFilm' => 'Film',
			'settings.deinterlaceFilmDescription' => 'Restore the original frames of film and animation telecined to 29.97 fps, common on NTSC DVDs. Video shot for TV stutters. Live TV uses Video',
			'settings.requireProfileSelectionOnOpen' => 'Ask for profile on app open',
			'settings.requireProfileSelectionOnOpenDescription' => 'Show profile selection every time the app is opened',
			'settings.forceTvMode' => 'Force TV mode',
			'settings.forceTvModeDescription' => 'Force TV layout. For devices that don\'t auto-detect. Requires restart.',
			'settings.startInFullscreen' => 'Start in fullscreen',
			'settings.startInFullscreenDescription' => 'Open PlezyNG in fullscreen mode at launch',
			'settings.exitFullscreenOnPlayerClose' => 'Exit fullscreen on player close',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Automatically exit fullscreen when closing the video player',
			'settings.autoHidePerformanceOverlay' => 'Auto-Hide Performance Overlay',
			'settings.autoHidePerformanceOverlayDescription' => 'Fade the performance overlay with the playback controls',
			'settings.showNavBarLabels' => 'Show Navigation Bar Labels',
			'settings.showNavBarLabelsDescription' => 'Display text labels under navigation bar icons',
			'settings.startupSection' => 'Startup Section',
			'settings.preferredServer' => 'Preferred Server',
			'settings.preferredServerDescription' => 'Prioritize this server\'s results while keeping every connected server available.',
			'settings.preferredServerAutomatic' => 'Automatic',
			'settings.showExploreTab' => 'Show Explore Tab',
			'settings.showExploreTabDescription' => 'Display the Explore tab with content from Plex Discover and connected trackers',
			'settings.hideEmptyLibraries' => 'Hide empty libraries',
			'settings.hideEmptyLibrariesDescription' => 'Remove libraries with a server-reported item count of zero from navigation.',
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
			'settings.gestureSeekSwipe' => 'Seek Swipe',
			'settings.gestureSeekSwipeDescription' => 'Swipe left or right anywhere on the video to seek; release to jump',
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
			'settings.exportDialogTitle' => 'Export PlezyNG settings',
			'settings.followSystem' => 'Follow system',
			'settings.followAppLanguage' => 'Match interface language',
			'settings.regionFormat' => 'Regional formats',
			'settings.regionFormatDescription' => 'Choose how dates, numbers and measurements appear.',
			'settings.metadataLanguage' => 'Metadata language',
			'settings.metadataLanguageDescription' => 'Preferred titles and descriptions where the server supports it. Audio and subtitle preferences stay separate.',
			'settings.enterFullscreenOnPlaybackStart' => 'Enter fullscreen when playback starts',
			'settings.enterFullscreenOnPlaybackStartDescription' => 'Open desktop video in fullscreen when playback starts',
			'settings.extendVideoIntoDisplayCutout' => 'Extend video into display cutout',
			'settings.extendVideoIntoDisplayCutoutDescription' => 'Let fullscreen video use the camera cutout on Android phones',
			'settings.languageDescription' => 'Choose the language used for PlezyNG controls and messages. Follow system tracks your device language.',
			'settings.themeDescription' => 'Choose the colors and contrast used throughout the app.',
			'settings.libraryDensityDescription' => 'Change how many library cards fit in each row.',
			'settings.displayScaleDescription' => 'Resize the interface on this car display without changing your device-wide text size.',
			'settings.themeSongVolumeDescription' => 'Set the volume of theme songs relative to other audio.',
			'settings.viewModeDescription' => 'Choose whether library items appear as posters in a grid or as a compact list.',
			'settings.gridViewDescription' => 'Arrange library items in rows and columns of posters.',
			'settings.listViewDescription' => 'Show library items in a vertical list with more text per item.',
			'settings.gridSpacingDescription' => 'Set the gap between posters in library grids.',
			'settings.gridSpacingTightDescription' => 'Fit more posters across the screen with smaller gaps.',
			'settings.gridSpacingNormalDescription' => 'Use the standard gap between posters.',
			'settings.gridSpacingSpaciousDescription' => 'Add larger gaps between posters for more separation.',
			'settings.episodePosterModeDescription' => 'Choose which artwork appears on episode cards.',
			'settings.seriesPosterDescription' => 'Use the show’s series poster for every episode.',
			'settings.seasonPosterDescription' => 'Use the season poster for each episode when available.',
			'settings.episodeThumbnailDescription' => 'Use a frame from the episode when available.',
			'settings.continueWatchingActionDescription' => 'Choose what happens when you activate a Continue Watching card.',
			'settings.continueWatchingPlayDescription' => 'Start the movie or episode immediately.',
			'settings.continueWatchingDetailsDescription' => 'Open the title page first so you can review details and choose an action.',
			'settings.episodeActionDescription' => 'Choose what happens when you activate an episode card.',
			'settings.episodePlayDescription' => 'Start the episode immediately.',
			'settings.episodeDetailsDescription' => 'Open the episode page before playback.',
			'settings.contentScreensaverDelayDescription' => 'Choose how long PlezyNG waits without input before showing artwork.',
			'settings.continueWatchingRowSizeDescription' => 'Choose how large the cards are in the Continue Watching row.',
			'settings.rowSizeCompactDescription' => 'Show smaller cards so more items fit across the row.',
			'settings.rowSizeStandardDescription' => 'Use the standard card size.',
			'settings.rowSizeLargeDescription' => 'Show larger cards with more artwork detail.',
			'settings.visualEffectsDescription' => 'Choose the animation and artwork effects budget for this device.',
			'settings.visualEffectsFullDescription' => 'Use the full animation and artwork effects on every device.',
			'settings.startupSectionDescription' => 'Choose which section opens when PlezyNG starts.',
			'settings.startupSectionOptions.discover' => 'Open recommendations and items from connected discovery sources.',
			'settings.startupSectionOptions.libraries' => 'Open your connected media libraries.',
			'settings.startupSectionOptions.liveTv' => 'Open Live TV when a server provides it; otherwise startup falls back to Home.',
			'settings.startupSectionOptions.search' => 'Open media search.',
			'settings.smallSkipDurationDescription' => 'Set the distance moved by the short backward and forward seek controls.',
			'settings.largeSkipDurationDescription' => 'Set the distance moved by the long backward and forward seek controls.',
			'settings.rewindOnResumeDescription' => 'Move playback back by this amount when resuming a video.',
			'settings.defaultSleepTimerDescription' => 'Set the initial duration used when you start the sleep timer.',
			'settings.playNextCountdownDescription' => 'Wait this long before starting the next episode. Set to 0 to start immediately.',
			'settings.autoSkipDelaySettingDescription' => 'Applies when an intro, credits, or ad is set to skip automatically.',
			'settings.downmixCenterBoostDescription' => 'Raise dialogue in the center channel when surround audio is mixed down to stereo.',
			'settings.displaySwitchDelayDescription' => 'Wait before changing display mode so the TV or receiver can finish its previous switch.',
			'settings.playerBackendDescription' => 'Choose which playback engine decodes and renders video on this device.',
			'settings.exoPlayerDescription' => 'Use Android’s native Media3-based player and supported hardware paths.',
			'settings.mpvDescription' => 'Use mpv, which exposes additional playback, subtitle, and video processing controls.',
			'settings.scopeOffDescription' => 'Keep changes for the current playback session only.',
			'settings.scopeGlobalDescription' => 'Reuse the same value for every library and title.',
			'settings.scopeLibraryDescription' => 'Remember a separate value for each library.',
			'settings.scopeTitleDescription' => 'Remember a separate value for each show or movie.',
			'settings.specialsOrderingServerDescription' => 'Keep the episode order supplied by the media server.',
			'settings.specialsOrderingAirDateDescription' => 'Place specials among regular episodes by their air date.',
			'settings.specialsOrderingLastDescription' => 'Place every special after the regular seasons.',
			'settings.skipIntroModeDescription' => 'Choose whether intro markers play normally, show a skip button, or skip automatically.',
			'settings.skipCreditsModeDescription' => 'Choose whether credits play normally, show a skip button, or skip automatically.',
			'settings.skipAdsModeDescription' => 'Choose whether detected ads play normally, show a skip button, or skip automatically.',
			'settings.playbackBufferAutoDescription' => 'Let the active player choose its normal buffer size.',
			'settings.playbackBufferLargeDescription' => 'Keep more media ready ahead of playback; this uses more memory.',
			'settings.playbackBufferExtraLargeDescription' => 'Keep the largest read-ahead buffer; this uses the most memory.',
			'settings.defaultQualityDescription' => 'Set the default video resolution and bitrate ceiling for streams that the server transcodes.',
			'settings.cellularQualityDescription' => 'Override Default Quality when the device is using a cellular-only connection.',
			'settings.remoteQualityDescription' => 'Override Default Quality when connecting to a server over a remote connection.',
			'settings.qualityPresetOriginalDescription' => 'Play the source at its available quality without asking the server to transcode it.',
			'settings.qualityPresetTranscodeOptionDescription' => 'Ask the server for a converted stream using the resolution and bitrate shown above.',
			'settings.qualityPresetSameAsDefaultDescription' => 'Use the quality selected in Default Quality.',
			'settings.musicQualityDescription' => 'Set the maximum audio bitrate requested from the server; Original keeps the source stream.',
			'settings.musicQualityOriginalDescription' => 'Play the source audio without a bitrate-capped transcode.',
			'settings.musicQualityTranscodeOptionDescription' => 'Request a server transcode capped near the bitrate shown above; the actual output can vary.',
			'settings.maxVolumeInputLabel' => 'Maximum volume (%)',
			'settings.checkForUpdatesDescription' => 'Check now whether a newer version of PlezyNG is available.',
			'settings.appearanceDescription' => 'Choose the app theme and adjust library cards, Home rows, and navigation.',
			'settings.prerollLibraryDescription' => 'Choose the library that contains the clips available as movie pre-rolls.',
			'settings.prerollSelectionDescription' => 'Choose which clips from the selected library can play before movies.',
			'settings.contentScreensaverDelayOptionDescription' => 'Wait this many minutes without input before showing screensaver artwork.',
			'settings.videoCodecOptionDescription' => 'Allow direct playback for this codec when supported. Unchecked codecs are transcoded by the media server.',
			'themeEditor.builtIn' => 'Built-in',
			'themeEditor.presets' => 'Presets',
			'themeEditor.custom' => 'Custom',
			'themeEditor.customEmpty' => 'Not created yet',
			'themeEditor.editCustom' => 'Edit custom theme',
			'themeEditor.editCustomDescription' => 'Choose every color yourself',
			'themeEditor.locked' => 'Lifetime access required',
			'themeEditor.savedLocked' => 'Saved — available with lifetime access',
			'themeEditor.title' => 'Custom Theme',
			'themeEditor.startFrom' => 'Start from',
			'themeEditor.startFromDescription' => 'Copy all colors from another theme',
			'themeEditor.colors' => 'Colors',
			'themeEditor.preview' => 'Preview',
			'themeEditor.slots.bg' => 'Background',
			'themeEditor.slots.surface' => 'Surface',
			'themeEditor.slots.outline' => 'Outline',
			'themeEditor.slots.text' => 'Text',
			'themeEditor.slots.textMuted' => 'Secondary text',
			'themeEditor.slots.accent' => 'Accent',
			'themeEditor.opacity' => 'Opacity',
			'themeEditor.hexHint' => '#RRGGBB or #AARRGGBB',
			'themeEditor.fromOtherThemes' => 'From other themes',
			'themeEditor.swatchLabel' => ({required Object theme, required Object color}) => '${theme} ${color}',
			'themeEditor.contrast.textOnBg' => 'Text on background',
			'themeEditor.contrast.textOnSurface' => 'Text on surface',
			'themeEditor.contrast.textMutedOnBg' => 'Secondary text on background',
			'themeEditor.contrast.textMutedOnSurface' => 'Secondary text on surface',
			'themeEditor.contrast.accentOnBg' => 'Accent on background',
			'themeEditor.contrast.accentOnSurface' => 'Accent on surface',
			'themeEditor.contrast.labelOnAccent' => 'Button label on accent',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, below the recommended ${minimum}:1',
			'themeEditor.discardTitle' => 'Discard changes?',
			'themeEditor.discardMessage' => 'Your unsaved color changes will be lost.',
			'themeEditor.discard' => 'Discard',
			'themeEditor.previewCardTitle' => ({required Object number}) => 'Episode ${number}',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => '${minutes} min left',
			'themeEditor.previewSwitch' => 'Autoplay',
			'themeEditor.previewMutedText' => 'Secondary text reads like this',
			'themeEditor.themeSystemDescription' => 'Follow your device appearance and switch between light and dark automatically.',
			'themeEditor.themeLightDescription' => 'Use a bright background with dark text.',
			'themeEditor.themeDarkDescription' => 'Use a dark background with light text.',
			'themeEditor.themeOledDescription' => 'Use near-black surfaces that reduce light on OLED screens.',
			'themeEditor.themeEmberDescription' => 'Use warm red and amber accent colors.',
			'themeEditor.themeGlacierDescription' => 'Use cool blue accent colors.',
			'themeEditor.themeForestDescription' => 'Use muted green and natural accent colors.',
			'themeEditor.themePlumDescription' => 'Use violet and plum accent colors.',
			'themeEditor.themePaperDescription' => 'Use warm paper-like surfaces and ink-inspired colors.',
			'themeEditor.themeCustomDescription' => 'Use the color palette you created in the custom theme editor.',
			'themeEditor.editorDescription' => 'Choose a palette color, adjust its hue, saturation, brightness, or opacity, and see the preview update before saving. You can also enter a hex color.',
			'search.hint' => 'Search movies, shows, music...',
			'search.tryDifferentTerm' => 'Try a different search term',
			'search.searchYourMedia' => 'Search your media',
			'search.enterTitleActorOrKeyword' => 'Enter a title, actor, or keyword',
			'search.people' => 'People',
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
			'hotkeys.actions.subtitleDelayIncrease' => 'Delay Subtitles',
			'hotkeys.actions.subtitleDelayDecrease' => 'Advance Subtitles',
			'hotkeys.actions.shaderToggle' => 'Toggle Shaders',
			'hotkeys.actions.skipMarker' => 'Skip Intro/Credits',
			'hotkeys.actions.screenshot' => 'Take Screenshot',
			'hotkeys.actions.framePrevious' => 'Previous Frame',
			'hotkeys.actions.frameNext' => 'Next Frame',
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
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'This deletes the ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episode it contains and its file.', other: 'This deletes all ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodes in it, and their files.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'This item is stored as ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} file, which will be deleted.', other: 'This item is stored across ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} files, and all of them will be deleted.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} other episode is stored in the same file and will be deleted too:', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} other episodes are stored in the same file and will be deleted too:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'PlezyNG could not check which files this will remove, so it may delete more than the item named above. Cancel and try again, or delete anyway.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'Your server did not provide file details for this item, so PlezyNG cannot check which files this will remove. It may delete more than the item named above.',
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
			'accessibility.red' => 'Red',
			'accessibility.green' => 'Green',
			'accessibility.blue' => 'Blue',
			'accessibility.redShort' => 'R',
			'accessibility.greenShort' => 'G',
			'accessibility.blueShort' => 'B',
			'accessibility.colorModeHsv' => 'HSV',
			'accessibility.colorModeRgb' => 'RGB',
			'accessibility.title' => 'Accessibility',
			'accessibility.summary' => 'Text, contrast, motion and controls',
			'accessibility.systemHint' => 'Your device’s accessibility settings always apply. These options add adjustments throughout PlezyNG.',
			'accessibility.readability' => 'Reading and visibility',
			'accessibility.textSize' => 'Additional text size',
			'accessibility.preview' => 'Find your next story. Read, listen and watch at your own pace.',
			'accessibility.boldText' => 'Bold interface text',
			'accessibility.highContrast' => 'High contrast',
			'accessibility.highContrastHint' => 'Stronger text, outlines and focus indicators on light or dark surfaces.',
			'accessibility.interaction' => 'Motion and interaction',
			'accessibility.reduceMotion' => 'Reduce motion',
			'accessibility.reduceMotionHint' => 'Keep focus, page transitions and decorative effects still.',
			'accessibility.largeTargets' => 'Larger touch targets',
			'accessibility.largeTargetsHint' => 'Give shared controls more room for touch and assistive navigation.',
			'accessibility.navigationHint' => 'Use Tab and Shift+Tab to move between controls, Enter or Space to activate, and Escape or Back to close. Reader zoom and reading preferences are available while a book is open.',
			'accessibility.textSizeDescription' => 'Scale interface text in PlezyNG in addition to your device’s system text-size setting.',
			'accessibility.boldTextHint' => 'Use a heavier weight for interface labels and messages to make them easier to distinguish.',
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
			'videoControls.segmentLoopHelp' => 'Loop a section during this playback. Set A, then set B later in the timeline.',
			'videoControls.setLoopStart' => 'Set loop start (A)',
			'videoControls.setLoopEnd' => 'Set loop end (B)',
			'videoControls.clearSegmentLoop' => 'Clear segment loop',
			'videoControls.setLoopStartFirst' => 'Set loop start (A) before the end (B).',
			'videoControls.loopEndAfterStart' => 'The loop end must be later than the start.',
			'videoControls.segmentLoopUnavailable' => 'Segment looping isn\'t available for this playback.',
			'videoControls.loopPointNotSet' => 'Not set',
			'videoControls.bookmarksHelp' => 'Bookmarks are saved on this device. Select one to go to that time.',
			'videoControls.bookmarksButton' => 'Bookmarks',
			'videoControls.chaptersAndBookmarks' => 'Chapters and bookmarks',
			'videoControls.segmentLoop' => 'Segment loop',
			_ => null,
		} ?? switch (path) {
			'videoControls.addBookmark' => 'Add bookmark',
			'videoControls.bookmarkName' => 'Bookmark name',
			'videoControls.bookmarkNameHint' => 'For example, Opening scene',
			'videoControls.bookmarkDefaultName' => ({required Object n}) => 'Bookmark ${n}',
			'videoControls.bookmarkNameRequired' => 'Enter a name for this bookmark.',
			'videoControls.deleteBookmark' => 'Delete bookmark',
			'videoControls.bookmarkLimitReached' => 'This item already has 100 bookmarks.',
			'videoControls.bookmarkUnavailable' => 'Couldn\'t save or remove this bookmark.',
			'videoControls.bookmarkSaved' => 'Bookmark saved.',
			'videoControls.bookmarkDeleted' => 'Bookmark deleted.',
			'videoControls.loopPointSet' => ({required Object point, required Object time}) => 'Loop point ${point} set at ${time}.',
			'videoControls.noChaptersOrBookmarks' => 'No chapters or bookmarks available.',
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
			'videoControls.timelineSlider' => 'Video timeline',
			'videoControls.volumeSlider' => 'Volume level',
			'videoControls.endsAt' => ({required Object time}) => 'Ends at ${time}',
			'videoControls.pipActive' => 'Playing in Picture-in-Picture',
			'videoControls.pipFailed' => 'Picture-in-picture failed to start',
			'videoControls.screenshotSaved' => 'Screenshot saved',
			'videoControls.screenshotFailed' => 'Couldn\'t take a screenshot',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Zoom ${percent}%',
			'videoControls.volumePercent' => ({required Object percent}) => 'Volume ${percent}%',
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
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} frame', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} frames', ), 
			'videoControls.trackSelectionTitle' => 'Choose tracks before playback',
			'videoControls.trackSelectionAuto' => 'Automatic selection',
			'videoControls.openMiniPlayer' => 'Open mini player',
			'videoControls.returnToFullPlayer' => 'Return to full player',
			'videoControls.loadSubtitleFile' => 'Load subtitle file…',
			'videoControls.subtitleLoadFailed' => 'Failed to load subtitle file',
			'videoControls.skipAds' => 'Skip Ads',
			'videoControls.tapToUnlock' => 'Tap to unlock',
			'videoControls.tapAgainToUnlock' => 'Tap again to unlock',
			'messages.markedAsWatched' => 'Marked as watched',
			'messages.markedAsUnwatched' => 'Marked as unwatched',
			'messages.markedAsWatchedOffline' => 'Marked as watched (will sync when online)',
			'messages.markedAsUnwatchedOffline' => 'Marked as unwatched (will sync when online)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Auto-removed: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'Auto-removed ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} watched download', other: 'Auto-removed ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} watched downloads', ), 
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
			'messages.playbackFailedDetail' => ({required Object error}) => 'Playback could not be started: ${error}',
			'messages.audioOutputFailed' => 'The audio output stopped responding. Check the TV or receiver\'s audio connection; if other apps have no sound either, restart the device.',
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
			'messages.playbackNotAllowedTitle' => 'Playback not allowed',
			'messages.playbackNotAllowedBody' => 'The server refused to stream this item (HTTP 403). Your account may not have permission to play it, or the server may only allow playback on its local network.',
			'messages.logsUploaded' => 'Logs uploaded',
			'messages.logsUploadFailed' => 'Failed to upload logs',
			'messages.logId' => 'Log ID',
			'messages.burnedSubtitlesUseMenu' => 'Subtitles are burned into this stream. Change them from the subtitle menu.',
			'messages.noVideoUrl' => 'No video URL available',
			'messages.playbackNoMediaSources' => 'The server returned no playable media sources',
			'messages.playbackDataNotPrepared' => 'Playback was started before its data was ready',
			'messages.streamSelectionUnavailable' => 'Stream selection is not available for this source',
			'messages.streamSelectionFailed' => 'Could not apply the selected streams',
			'messages.trackSelectionNotRemembered' => 'This track choice applies to the current playback only.',
			'messages.serverUnavailableForProfile' => 'No server is available for the active profile',
			'subtitlingStyling.previewSample' => 'The quick brown fox jumps over the lazy dog',
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
			'subtitlingStyling.useMargins' => 'Use margins',
			'subtitlingStyling.useMarginsDescription' => 'Allow text subtitles in the space outside the video. Styled subtitles may keep their original placement.',
			'subtitlingStyling.anchorToScreen' => 'Anchor to Screen',
			'subtitlingStyling.anchorToScreenDescription' => 'Show text subtitles in the black bars below widescreen video',
			'subtitlingStyling.bold' => 'Bold',
			'subtitlingStyling.italic' => 'Italic',
			'subtitlingStyling.renderResolution' => 'Render Resolution',
			'subtitlingStyling.renderResolutionScreen' => 'Screen resolution',
			'subtitlingStyling.renderResolutionVideo' => 'Video resolution',
			'subtitlingStyling.fontSizeDescription' => 'Set the subtitle text size on this device.',
			'subtitlingStyling.textColorDescription' => 'Choose the color used for subtitle text.',
			'subtitlingStyling.borderSizeDescription' => 'Set the thickness of the outline around subtitle text.',
			'subtitlingStyling.borderColorDescription' => 'Choose the color used for the subtitle outline.',
			'subtitlingStyling.backgroundColorDescription' => 'Choose the color behind subtitle text.',
			'subtitlingStyling.backgroundOpacityDescription' => 'Set how transparent the subtitle background is: 0% is clear and 100% is solid.',
			'subtitlingStyling.positionDescription' => 'Move subtitles vertically. 0% is the top of the video and 100% is the bottom.',
			'subtitlingStyling.assOverrideDescription' => 'Choose whether the player follows, adjusts, replaces, or removes styling embedded in ASS subtitles.',
			'subtitlingStyling.assOverrideOptions.no' => 'Keep the fonts, colors, sizes, and placement authored in the subtitle file.',
			'subtitlingStyling.assOverrideOptions.yes' => 'Allow the player’s subtitle style settings to adjust ASS subtitles.',
			'subtitlingStyling.assOverrideOptions.scale' => 'Apply player styling and scale embedded sizes to match the video dimensions.',
			'subtitlingStyling.assOverrideOptions.force' => 'Replace embedded ASS styles with the player’s subtitle style.',
			'subtitlingStyling.assOverrideOptions.strip' => 'Remove embedded ASS formatting and render the subtitle text plainly.',
			'subtitlingStyling.renderResolutionDescription' => 'Choose the resolution used to rasterize image and ASS subtitles. Lower Android scales can reduce rendering work but look softer.',
			'subtitlingStyling.renderResolutionOptions.screen' => 'Render at the full display surface resolution for the sharpest result.',
			'subtitlingStyling.renderResolutionOptions.video' => 'Render using the video resolution as the reference, which can reduce work on high-resolution displays.',
			'subtitlingStyling.renderResolutionOptions.threeQuarter' => 'Render at 75% of the display surface resolution for a modest performance saving.',
			'subtitlingStyling.renderResolutionOptions.half' => 'Render at 50% of the display surface resolution to reduce work, with softer edges.',
			'subtitlingStyling.renderResolutionOptions.third' => 'Render at one-third of the display surface resolution to reduce work, with softer edges.',
			'subtitlingStyling.renderResolutionOptions.quarter' => 'Render at one-quarter of the display surface resolution to reduce work, with the softest result.',
			'subtitlingStyling.boldDescription' => 'Draw subtitle text in a heavier weight.',
			'subtitlingStyling.italicDescription' => 'Draw subtitle text in italics.',
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
			'profiles.addPlezyProfile' => 'Add PlezyNG profile',
			'profiles.switchingProfile' => 'Switching profile…',
			'profiles.deleteThisProfileTitle' => 'Delete this profile?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'Remove ${displayName}. Connections aren\'t affected.',
			'profiles.active' => 'Active',
			'profiles.manage' => 'Manage',
			'profiles.delete' => 'Delete',
			'profiles.signOut' => 'Sign out',
			'profiles.signOutPlexTitle' => 'Sign out of Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'Remove ${displayName} and all Plex Home users? Sign back in anytime.',
			'profiles.signOutPlexDeleteDownloads' => 'Also delete downloads',
			'profiles.signOutPlexDeleteDownloadsDescription' => 'Otherwise they stay on this device and come back when you sign back in to this account.',
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
			'profiles.copyAutomationLink' => 'Copy Android automation link',
			'profiles.copyAutomationLinkDescription' => 'Select this profile from an Android intent or automation. Profile PIN checks still apply.',
			'profiles.automationLinkCopied' => 'Profile automation link copied.',
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
			'profiles.settingsLocked' => 'Settings are locked for this profile.',
			'profiles.unlockSettings' => 'Unlock settings',
			'profiles.showExploreForProfile' => 'Show Explore for this profile',
			'profiles.showExploreForProfileDescription' => 'Turn off to remove Explore from this profile’s navigation.',
			'connections.sectionTitle' => 'Connections',
			'connections.addConnection' => 'Add connection',
			'connections.addConnectionSubtitleNoProfile' => 'Sign in with Plex or connect a Jellyfin or Emby server',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Add to ${displayName}: Plex, Jellyfin, Emby, or another profile connection',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Session expired for ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Session expired for ${count} servers',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} refused access for this account',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} servers refused access for this account',
			'connections.signInAgain' => 'Sign in again',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'Edit ${product} connection',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'Add or remove URLs for ${serverName}. PlezyNG will use the reachable URL with the lowest latency.',
			'accountPreferences.sectionTitle' => 'Account preferences',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => 'Audio, subtitle and library options saved on ${account}',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => 'Audio, subtitle and library options saved on ${count} accounts',
			'accountPreferences.pickAccount' => 'Every account stores its own preferences. Pick the one to edit.',
			'accountPreferences.storedOnAccount' => 'These options are saved on the account itself, so every app signed in to it uses them — including PlezyNG on your other devices.',
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
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdhDescription' => 'Prefer standard subtitles when both standard and SDH versions are available.',
			'accountPreferences.subtitleAccessibilityOptions.preferSdhDescription' => 'Prefer SDH subtitles when available, but allow standard subtitles as a fallback.',
			'accountPreferences.subtitleAccessibilityOptions.onlySdhDescription' => 'Use SDH subtitles only; do not fall back to standard subtitles.',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdhDescription' => 'Use standard subtitles only; exclude SDH subtitles.',
			'accountPreferences.forcedSubtitles' => 'Forced subtitles',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'Prefer non-forced subtitles',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'Prefer forced subtitles',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'Only forced subtitles',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'Only non-forced subtitles',
			'accountPreferences.forcedSubtitleOptions.preferNonForcedDescription' => 'Prefer regular subtitles, but allow forced tracks as a fallback.',
			'accountPreferences.forcedSubtitleOptions.preferForcedDescription' => 'Prefer forced tracks when available, but allow regular subtitles as a fallback.',
			'accountPreferences.forcedSubtitleOptions.onlyForcedDescription' => 'Use only tracks marked as forced.',
			'accountPreferences.forcedSubtitleOptions.onlyNonForcedDescription' => 'Exclude tracks marked as forced.',
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
			'accountPreferences.watchedIndicatorOptions.noneDescription' => 'Do not show watched checkmarks.',
			'accountPreferences.watchedIndicatorOptions.moviesAndShowsDescription' => 'Show watched checkmarks for movies and TV shows.',
			'accountPreferences.watchedIndicatorOptions.moviesDescription' => 'Show watched checkmarks for movies only.',
			'accountPreferences.watchedIndicatorOptions.showsDescription' => 'Show watched checkmarks for TV shows only.',
			'accountPreferences.mediaReviewsVisibility' => 'Ratings & reviews',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'Users and critics',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'Users only',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'Critics only',
			'accountPreferences.mediaReviewsOptions.nobody' => 'Hidden',
			'accountPreferences.mediaReviewsOptions.usersAndCriticsDescription' => 'Show both user ratings and critic ratings.',
			'accountPreferences.mediaReviewsOptions.usersOnlyDescription' => 'Show ratings and reviews submitted by users.',
			'accountPreferences.mediaReviewsOptions.criticsOnlyDescription' => 'Show critic ratings and reviews.',
			'accountPreferences.mediaReviewsOptions.nobodyDescription' => 'Hide ratings and reviews.',
			'accountPreferences.preferredAudioLanguageDescription' => 'Prefer audio tracks in this language when the server or player selects a track automatically.',
			'accountPreferences.preferredSubtitleLanguageDescription' => 'Prefer subtitle tracks in this language when subtitles are selected automatically.',
			'accountPreferences.subtitleAccessibilityDescription' => 'Choose whether SDH captions are preferred or required during automatic subtitle selection.',
			'accountPreferences.forcedSubtitleDescription' => 'Choose whether forced subtitle tracks are preferred or required during automatic selection.',
			'accountPreferences.watchedIndicatorDescription' => 'Choose which media types receive a watched checkmark in the server interface.',
			'accountPreferences.mediaReviewsVisibilityDescription' => 'Choose which audience and critic ratings the server shows on media pages.',
			'accountPreferences.subtitleModeDescription' => 'Choose when subtitles turn on automatically for this server account.',
			'accountPreferences.hubDescription' => 'These preferences are stored on your media-server account and may apply on other clients too.',
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
			'discover.findNext.title' => 'Find your next',
			'discover.findNext.open' => 'Find your next',
			'discover.findNext.anyTime' => 'Any time',
			'discover.findNext.timeAvailable' => 'How much time do you have?',
			'discover.findNext.filters' => 'Choose the moment',
			'discover.findNext.mood' => 'Mood',
			'discover.findNext.moodMetadataHint' => 'Mood filters use mood tags supplied by your media server; some picks do not have them.',
			'discover.findNext.familiarity' => 'Familiarity',
			'discover.findNext.familiarityAny' => 'Any familiarity',
			'discover.findNext.newToMe' => 'New to me',
			'discover.findNext.inProgress' => 'Already started',
			'discover.findNext.revisit' => 'Revisit',
			'discover.findNext.tasteControls' => 'Taste controls',
			'discover.findNext.tasteControlsHelp' => 'Choose styles to bring forward or gently push back. Not now never changes these preferences.',
			'discover.findNext.preferMore' => 'Bring forward',
			'discover.findNext.showLess' => 'Show less',
			'discover.findNext.hideFromDiscovery' => 'Hide this pick',
			'discover.findNext.hiddenPicks' => 'Hidden picks',
			'discover.findNext.noHiddenPicks' => 'No hidden picks',
			'discover.findNext.resetTaste' => 'Reset taste and hidden picks',
			'discover.findNext.resetTasteConfirm' => 'Clear genre preferences and restore every hidden pick?',
			'discover.findNext.chooseTogether' => 'Choose together',
			'discover.findNext.voteSetup' => 'Make a shortlist decision together',
			'discover.findNext.votePrivacy' => 'Each guest votes privately on this device. Completed ballots stay covered; no votes or guest identities are saved.',
			'discover.findNext.guestCount' => 'How many guests?',
			'discover.findNext.beginVoting' => 'Start private voting',
			'discover.findNext.guestProgress' => ({required Object guest, required Object count}) => 'Guest ${guest} of ${count}',
			'discover.findNext.maybe' => 'Maybe',
			'discover.findNext.notTonight' => 'Not tonight',
			'discover.findNext.passDevice' => 'Pass the device',
			'discover.findNext.passDeviceHint' => 'The previous guest’s choices are covered. Hand the device to the next guest when ready.',
			'discover.findNext.readyNextGuest' => 'Ready for next guest',
			'discover.findNext.noSharedPick' => 'No shared pick yet',
			'discover.findNext.noSharedPickHint' => 'Every pick received at least one “Not tonight” vote. Widen the shortlist and try again.',
			'discover.findNext.sharedPick' => 'You found a shared pick',
			'discover.findNext.sharedPickHint' => ({required Object title}) => '${title} received the strongest shared approval.',
			'discover.findNext.useSharedPick' => 'Put this pick on the deck',
			'discover.findNext.widenShortlist' => 'Widen the shortlist',
			'discover.findNext.selectToVote' => 'Choose picks to vote on',
			'discover.findNext.startVote' => 'Start voting',
			'discover.findNext.voteLimit' => 'Choose between 2 and 12 picks.',
			'discover.findNext.availability' => 'Availability',
			'discover.findNext.availabilityNotChecked' => 'Check again when opened',
			'discover.findNext.libraryCatalog' => 'Find a library catalog pick',
			'discover.findNext.libraryCatalogHint' => 'Search Open Library by this title. A catalog match is not proof that your local library owns or can lend it.',
			'discover.findNext.openLibraryName' => 'Open Library',
			'discover.findNext.catalogOnly' => 'Catalog record · availability not checked',
			'discover.findNext.aiRanking' => 'Optional AI ranking',
			'discover.findNext.aiRankingHelp' => 'An external or loopback OpenAI-compatible service may reorder up to 24 eligible picks. The ordinary deck stays usable if it is off or unavailable.',
			'discover.findNext.aiEndpoint' => 'Service URL',
			'discover.findNext.aiModel' => 'Model name',
			'discover.findNext.aiApiKey' => 'API key (optional for local services)',
			'discover.findNext.aiEnabled' => 'Enable AI ranking',
			'discover.findNext.aiConsentTitle' => 'Review AI ranking data',
			'discover.findNext.aiConsentBody' => 'When enabled, the configured service receives up to 24 picks with temporary IDs, title, media type, genre tags, metadata mood tags and your selected moment filters for media, time, genre, mood and familiarity. It receives no server or source IDs, URLs, filenames, playback history, account data, notes, credentials or content. Results can only reorder picks already eligible on this device.',
			'discover.findNext.aiSaved' => 'AI ranking settings saved',
			'discover.findNext.aiInvalidConfig' => 'Enter a model and a valid HTTPS URL, or use HTTP on this device only.',
			'discover.findNext.aiSavedKey' => 'A key is saved securely',
			'discover.findNext.aiClearKey' => 'Remove saved API key',
			'discover.findNext.aiError' => 'AI ranking was unavailable. Your usual discovery order is still active.',
			'discover.findNext.watch' => 'Watch',
			'discover.findNext.listen' => 'Listen',
			'discover.findNext.read' => 'Read',
			'discover.findNext.finishable' => ({required Object duration}) => 'Finish in ${duration}',
			'discover.findNext.aboutDuration' => ({required Object duration}) => 'About ${duration}',
			'discover.findNext.nextUnit' => ({required Object duration}) => 'Next chapter · ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => '${duration} total',
			'discover.findNext.timingVaries' => 'Timing varies',
			'discover.findNext.notNow' => 'Not now',
			'discover.findNext.swipeHint' => 'Swipe the cover toward an arrow, or use the buttons below.',
			'discover.findNext.saved' => 'Saved picks',
			'discover.findNext.selectToCompare' => 'Select picks to compare',
			'discover.findNext.compareLimit' => 'Compare up to three picks at a time.',
			'discover.findNext.compareNeedsTwo' => 'Choose at least two saved picks to compare.',
			'discover.findNext.localOnly' => 'On this device',
			'discover.findNext.syncSavedPicks' => 'Sync Saved picks across devices',
			'discover.findNext.syncSavedPicksHelp' => 'Optional. Shares saved titles and public catalog IDs using your existing encrypted sync code. Server IDs, source addresses, credentials, playback history and previews are never included.',
			'discover.findNext.savedPickConflict' => 'These devices changed this saved pick independently. Choose which saved state to keep.',
			'discover.findNext.useThisVersion' => 'Use this version',
			'discover.findNext.savedCount' => ({required Object count}) => 'Saved picks · ${count}',
			'discover.findNext.undo' => 'Undo',
			'discover.findNext.details' => 'Details',
			'discover.findNext.noPicks' => 'Nothing to choose from yet',
			'discover.findNext.noPicksHint' => 'Connect a library or add a media source to get started.',
			'discover.findNext.noMatches' => 'Nothing fits this moment',
			'discover.findNext.noMatchesHint' => 'Try another format or give yourself more time.',
			'discover.findNext.allDone' => 'You’re all caught up',
			'discover.findNext.allDoneHint' => 'Start a fresh mix to see these choices again.',
			'discover.findNext.refresh' => 'Find another mix',
			'discover.findNext.sourceReason' => ({required Object source}) => 'From ${source}',
			'discover.findNext.libraryReason' => ({required Object library}) => 'From ${library}',
			'discover.findNext.ownedReason' => 'From your library',
			'discover.findNext.liveNow' => 'On now',
			'discover.findNext.watchLive' => 'Watch live',
			'discover.findNext.filterAnything' => 'Anything',
			'discover.findNext.filterWatch' => 'Watch',
			'discover.findNext.filterListen' => 'Listen',
			'discover.findNext.filterRead' => 'Read',
			'discover.findNext.twentyMinutes' => '20 min',
			'discover.findNext.fortyFiveMinutes' => '45 min',
			'discover.findNext.ninetyMinutes' => '90 min',
			'discover.findNext.apply' => 'Apply',
			'discover.findNext.openFailed' => 'This choice is no longer available. Refresh to check again.',
			'discover.findNext.changeFailed' => 'Could not save that change. Try again.',
			'discover.findNext.savedLimit' => 'Saved picks is full. Remove a pick to save another.',
			'discover.findNext.chooseHint' => 'Open a pick, save it for later, or skip it.',
			'discover.findNext.howItWorks' => 'How it works',
			'discover.findNext.notNowHelp' => 'Skip this pick for now. It stays in your library.',
			'discover.findNext.saveHelp' => 'Keep it in Saved picks for this profile on this device. Saving does not download it.',
			'discover.findNext.openHelp' => 'Select the cover for details. Use the main action to play, read or open the title.',
			'discover.findNext.controlsHelp' => 'Keyboard or remote: focus a button, then press Enter or Select. Undo restores your last choice.',
			'discover.findNext.artworkLoading' => 'Loading artwork…',
			'discover.findNext.artworkUnavailable' => 'Artwork unavailable',
			'discover.findNext.savedFeedback' => 'Saved to Saved picks',
			'discover.findNext.skippedFeedback' => 'Skipped for now',
			'discover.findNext.releaseToConfirm' => 'Release to confirm',
			'discover.findNext.remoteHint' => 'Cover focused: ← / → choose · Select opens details · ↑ / ↓ moves focus',
			'discover.extras' => 'Trailers & Extras',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Rating',
			'discover.director' => 'Director',
			'discover.directors' => 'Directors',
			'discover.movie' => 'Movie',
			_ => null,
		} ?? switch (path) {
			'discover.tvShow' => 'TV Show',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} min left',
			'discover.moreLikeThis' => 'More Like This',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} title', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} titles', ), 
			'discover.person.born' => 'Born',
			'discover.person.died' => 'Died',
			'discover.person.birthplace' => 'Birthplace',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date} (age ${age})',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date} (aged ${age})',
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
			'errors.reasonTimedOut' => 'the connection timed out',
			'errors.reasonUnreachable' => 'the server could not be reached',
			'errors.reasonRefused' => 'the server refused the request',
			'errors.reasonNotFound' => 'the item is no longer on the server',
			'errors.reasonServerError' => 'the server reported an error',
			'errors.reasonCancelled' => 'the request was cancelled',
			'errors.reasonUnexpected' => 'an unexpected error occurred',
			'libraries.playRandomMovie' => 'Play a random movie',
			'libraries.randomPickFailed' => 'Could not choose a random movie from this library.',
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
			'libraries.filterCategories.filePath' => 'File Path',
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
			'libraries.sortLabels.dateDownloaded' => 'Date Downloaded',
			'libraries.sortLabels.size' => 'Size',
			'libraries.sortLabels.library' => 'Library',
			'libraries.advancedFilters.include' => 'Include',
			'libraries.advancedFilters.exclude' => 'Exclude',
			'libraries.advancedFilters.any' => 'Any',
			'libraries.advancedFilters.yes' => 'Yes',
			'libraries.advancedFilters.no' => 'No',
			'libraries.advancedFilters.not' => ({required Object value}) => 'Not ${value}',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '${count} selected',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '${count} excluded',
			'libraries.advancedFilters.searchValues' => 'Search values',
			'libraries.advancedFilters.noValues' => 'No values',
			'libraries.advancedFilters.matchContains' => 'Contains',
			'libraries.advancedFilters.matchNotContains' => 'Does not contain',
			'libraries.advancedFilters.matchIs' => 'Is',
			'libraries.advancedFilters.matchIsNot' => 'Is not',
			'libraries.advancedFilters.matchBeginsWith' => 'Begins with',
			'libraries.advancedFilters.matchEndsWith' => 'Ends with',
			'libraries.advancedFilters.textHint' => 'Type to match',
			'libraries.advancedFilters.from' => 'From',
			'libraries.advancedFilters.to' => 'To',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from} to ${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value} and up',
			'libraries.advancedFilters.atMost' => ({required Object value}) => 'Up to ${value}',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => 'Last ${count} days',
			'libraries.advancedFilters.dateLastYear' => 'Past year',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => 'Older than ${count} days',
			'libraries.advancedFilters.dateOlderThanYear' => 'Older than a year',
			'libraries.selection.selectItems' => 'Select items',
			'libraries.selection.selectedCount' => ({required Object count}) => '${count} selected',
			'libraries.selection.actions' => 'Selection actions',
			'libraries.selection.confirmDescendants' => 'This changes all episodes in the selected shows and seasons.',
			'libraries.selection.confirmUnwatched' => 'This also clears playback progress for the selected items.',
			'libraries.selection.confirmCount' => ({required Object count}) => 'Selected items: ${count}.',
			'libraries.selection.completed' => ({required Object count}) => 'Items updated: ${count}.',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => 'Updated ${succeeded}; failed ${failed}. Failed items remain selected.',
			'about.title' => 'About',
			'about.openSourceLicenses' => 'Open Source Licenses',
			'about.versionLabel' => ({required Object version}) => 'Version ${version}',
			'about.appDescription' => 'A beautiful Plex, Jellyfin, and Emby client for Flutter',
			'about.viewLicensesDescription' => 'View licenses of third-party libraries',
			'about.privacyPolicy' => 'Privacy Policy',
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
			'logs.saveLogs' => 'Save Logs to File',
			'logs.logsSaved' => ({required Object path}) => 'Logs saved to ${path}',
			'logs.saveLogsFailed' => 'Could not save the log file.',
			'startup.failedTitle' => 'PlezyNG could not start',
			'startup.failedBody' => 'Something went wrong during startup. The details below identify what failed.',
			'startup.failedBodyRepairable' => 'PlezyNG\'s saved settings file is damaged and has to be rebuilt before PlezyNG can start. Retrying will not help — choose Repair storage.',
			'startup.phaseLabel' => 'Step',
			'startup.showDetails' => 'Show details',
			'startup.hideDetails' => 'Hide details',
			'startup.copyDetails' => 'Copy details',
			'startup.detailsCopied' => 'Details copied to clipboard',
			'startup.uploadDetails' => 'Upload details',
			'startup.repairStorage' => 'Repair storage',
			'startup.repairTitle' => 'Repair stored data?',
			'startup.repairBodyCommon' => 'PlezyNG\'s settings file is damaged and cannot be read. Repairing resets every setting to its default.',
			'startup.repairBodyOneCredential' => 'One saved sign-in is damaged and cannot be read. Repairing removes just that one; your other settings are left alone.',
			'startup.repairBodySignInsKept' => 'Your servers and profiles should stay signed in.',
			'startup.repairBodySignInsLost' => 'The key protecting your saved sign-ins cannot be recovered from this file, so you will have to sign in to every server and profile again. Nothing on your media server is affected.',
			'startup.repairBodySessionsUncertain' => 'Trackers (MAL, AniList, Simkl, Trakt) and Seerr are stored separately and may or may not survive. PlezyNG will tell you exactly what it kept.',
			'startup.repairConfirm' => 'Repair',
			'startup.repairSucceeded' => 'Storage repaired',
			'startup.repairNeedsRestart' => 'Storage repaired — restart required',
			'startup.restartRequiredBody' => 'Your data was repaired, but PlezyNG has to start fresh before it can use it. Close PlezyNG and open it again.',
			'startup.quitPlezy' => 'Quit PlezyNG',
			'startup.repairFailed' => 'Repair failed',
			'startup.repairKeptSignIns' => 'Your servers and profiles are still signed in.',
			'startup.repairLostSignIns' => 'The key protecting your saved sign-ins could not be recovered. You will have to sign in to every server and profile again.',
			'startup.repairLostSessions' => 'At least one tracker or Seerr connection was lost and has to be reconnected.',
			'startup.backupTitle' => 'A copy of the damaged file was kept',
			'startup.backupWarning' => 'It contains your sign-in credentials. Do not upload or share it.',
			'startup.deleteBackup' => 'Delete copy',
			'startup.backupDeleted' => 'Copy deleted.',
			'startup.previousFailureTitle' => 'PlezyNG failed to start last time',
			'licenses.relatedPackages' => 'Related Packages',
			'licenses.license' => 'License',
			'licenses.licenseNumber' => ({required Object number}) => 'License ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licenses',
			'navigation.libraries' => 'Libraries',
			'navigation.downloads' => 'Downloads',
			'navigation.liveTv' => 'Live TV',
			'navigation.explore' => 'Explore',
			'explore.mdblistShelves.manage' => 'Manage Explore shelves',
			'explore.mdblistShelves.manageDescription' => 'Choose and arrange lists from your MDBList account',
			'explore.mdblistShelves.description' => 'Choose public movie and TV lists from your MDBList account. Create or copy lists on MDBList, then refresh.',
			'explore.mdblistShelves.selected' => 'Selected shelves',
			'explore.mdblistShelves.available' => 'Available account lists',
			'explore.mdblistShelves.noLists' => 'No public movie or TV lists returned. Create or copy a list on MDBList, then refresh.',
			'explore.mdblistShelves.displayName' => 'Shelf display name',
			'explore.mdblistShelves.nameHint' => 'Leave blank to use the source list name.',
			'explore.mdblistShelves.add' => 'Add shelf',
			'explore.mdblistShelves.save' => 'Save shelves',
			'explore.mdblistShelves.moveUp' => ({required Object title}) => 'Move ${title} up',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => 'Move ${title} down',
			'explore.mdblistShelves.unavailable' => 'This list is unavailable. Retry or remove its shelf in settings.',
			'explore.mdblistShelves.rateLimited' => 'MDBList request limit reached. Please retry later.',
			'explore.mdblistShelves.loadFailed' => 'Could not load shelves. Check your connection and retry.',
			'explore.mdblistShelves.saveFailed' => 'Could not save shelves. Please retry.',
			'explore.mdblistShelves.accountChanged' => 'The account or profile changed. Reopen these settings.',
			'explore.mdblistShelves.settingsUnreadable' => 'Saved shelves could not be read. Select your lists again to replace these settings.',
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
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episode', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodes', ), 
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
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'Couldn\'t check ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} server', other: 'Couldn\'t check ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} servers', ), 
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
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} comment', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} comments', ), 
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
			'explore.creditRole.actor' => 'Actor',
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
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'Recommended by ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} user', other: 'Recommended by ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} users', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'Recommended by ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'Favorited by ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} not aired yet',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'Recommended by ${percent} of viewers',
			'explore.detail.relatedTitles' => 'Related titles',
			'explore.detail.background' => 'Background',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} result', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} results', ), 
			'liveTv.title' => 'Live TV',
			'liveTv.guide' => 'Guide',
			'liveTv.noChannels' => 'No channels available',
			'liveTv.noDvr' => 'No DVR configured on any server',
			'liveTv.serverUnavailable' => 'Live TV server is not available.',
			'liveTv.serverNotConnected' => 'Live TV server is not connected.',
			'liveTv.noPrograms' => 'No program data available',
			'liveTv.liveStreamFailed' => 'Live stream failed',
			'liveTv.unknownProgram' => 'Unknown Program',
			'liveTv.timelineLiveProgram' => 'Live program (playback may be outside this program)',
			'liveTv.timelineBuffer' => 'Buffer timeline',
			'liveTv.timelineUnavailable' => 'Timeline unavailable',
			'liveTv.timelineEstimated' => 'Estimated playback',
			'liveTv.timelinePending' => 'Pending seek',
			'liveTv.timelineStale' => 'Schedule may be outdated',
			'liveTv.unknownHub' => 'Unknown',
			'liveTv.unknownError' => 'Unknown error',
			'liveTv.channelNumber' => ({required Object number}) => 'Channel ${number}',
			'liveTv.unknownChannel' => 'Unknown channel',
			'liveTv.live' => 'LIVE',
			'liveTv.premiereBadge' => 'NEW',
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
			'liveTv.guideReloadFailed' => 'Couldn\'t refresh the guide',
			'liveTv.rulesProcessRequested' => 'Rule re-evaluation requested',
			'liveTv.rulesProcessFailed' => 'Couldn\'t re-evaluate recording rules',
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
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'Couldn\'t start the channel: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'Couldn\'t switch channel: ${reason}',
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
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} item', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} items', ), 
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
			_ => null,
		} ?? switch (path) {
			'playlists.errorReordering' => 'Failed to reorder playlist item',
			'playlists.errorRemoving' => 'Failed to remove from playlist',
			'music.goToAlbum' => 'Go to album',
			'music.goToArtist' => 'Go to artist',
			'music.instantMix' => 'Instant Mix',
			'music.playNext' => 'Play next',
			'music.addToQueue' => 'Add to queue',
			'music.discNumber' => ({required Object n}) => 'Disc ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} track', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tracks', ), 
			'music.nowPlaying' => 'Now Playing',
			'music.playingFrom' => ({required Object title}) => 'Playing from ${title}',
			'music.queue' => 'Queue',
			'music.clearQueue' => 'Clear queue',
			'music.lyrics' => 'Lyrics',
			'music.visualizer' => 'Visualizer',
			'music.visualizerProfileLoading' => 'Reading track analysis…',
			'music.visualizerAmbientMotion' => 'Ambient motion',
			'music.visualizerPlexLoudness' => 'Plex loudness',
			'music.visualizerLiveAudio' => 'Live audio analysis',
			'music.visualizerPreviousPreset' => 'Previous visual style',
			'music.visualizerNextPreset' => 'Next visual style',
			'music.visualizerPresetAurora' => 'Aurora',
			'music.visualizerPresetBloom' => 'Bloom',
			'music.visualizerPresetOrbitals' => 'Orbitals',
			'music.visualizerPresetPrism' => 'Prism',
			'music.visualizerPresetTunnel' => 'Tunnel',
			'music.visualizerPresetTrackMap' => 'Track map',
			'music.noLyrics' => 'No lyrics available',
			'music.sleepTimer' => 'Sleep timer',
			'music.sleepTimerEndOfTrack' => 'End of track',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutes', one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minute', ), 
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
			'watchTogether.createRoom' => 'Create Room',
			'watchTogether.creatingRoom' => 'Creating room...',
			'watchTogether.joinRoom' => 'Join Room',
			'watchTogether.joiningRoom' => 'Joining room...',
			'watchTogether.connecting' => 'Connecting...',
			'watchTogether.relayPublic' => 'Rooms use the public Open Watch Party relays.',
			'watchTogether.relayCustom' => ({required Object url}) => 'Rooms use your relay at ${url}.',
			'watchTogether.recentRooms' => 'Recent Rooms',
			'watchTogether.roomActions' => 'Room actions',
			'watchTogether.renameRoom' => 'Rename Room',
			'watchTogether.removeRoom' => 'Remove',
			'watchTogether.enterRoomCode' => 'Enter the 6-character code from the host.',
			'watchTogether.roomCode' => 'Room Code',
			'watchTogether.paste' => 'Paste',
			'watchTogether.noCodeInClipboard' => 'The clipboard doesn\'t contain a room code',
			'watchTogether.copyCode' => 'Copy Code',
			'watchTogether.codeCopied' => 'Room code copied',
			'watchTogether.shareInvite' => 'Share Invite',
			'watchTogether.inviteCopied' => 'Invite copied. Paste it into a message.',
			'watchTogether.inviteMessage' => ({required Object code}) => 'Join my Watch Together room in PlezyNG: open Watch Together, choose Join Room and enter ${code}.',
			'watchTogether.openSessionControls' => 'Open Watch Together session controls',
			'watchTogether.reconnecting' => 'Reconnecting...',
			'watchTogether.reconnectingDescription' => 'The connection dropped. You rejoin the room automatically.',
			'watchTogether.connected' => 'Connected',
			'watchTogether.disconnected' => 'Disconnected',
			'watchTogether.youAreHost' => 'You are the host',
			'watchTogether.hostedBy' => ({required Object name}) => 'Hosted by ${name}',
			'watchTogether.hostControlsPlayback' => 'Host controls playback',
			'watchTogether.anyoneCanControl' => 'Anyone can control playback',
			'watchTogether.roomLocked' => 'Room locked',
			'watchTogether.nowPlaying' => 'Now Playing',
			'watchTogether.nothingPlaying' => 'Nothing playing',
			'watchTogether.nothingPlayingHost' => 'Play something from any library to share it with the room.',
			'watchTogether.nothingPlayingGuest' => 'When the host plays something, it opens here.',
			'watchTogether.notShareable' => 'This video has no catalogue match, so only people with access to the same server can play it.',
			'watchTogether.searching' => 'Looking for this video in your libraries...',
			'watchTogether.yourCopy' => 'Your copy',
			'watchTogether.sharingYourCopy' => 'You\'re sharing your copy',
			'watchTogether.playingOtherLength' => ({required Object difference}) => 'Playing your copy, ${difference}',
			'watchTogether.mismatchTitle' => 'Your Copy Is a Different Length',
			'watchTogether.mismatchDescription' => ({required Object difference}) => 'Your closest copy is ${difference} than the room\'s video. It may be another cut or version.',
			'watchTogether.playAnyway' => 'Play Anyway',
			'watchTogether.chooseAnotherCopy' => 'Choose Another Copy',
			'watchTogether.dontPlay' => 'Don\'t Play',
			'watchTogether.unavailableTitle' => 'You don\'t have this video',
			'watchTogether.unavailableDescription' => 'PlezyNG couldn\'t find it in your libraries. Pick a copy yourself or search again.',
			'watchTogether.chooseCopy' => 'Choose a Copy',
			'watchTogether.searchAgain' => 'Search Again',
			'watchTogether.noCandidates' => 'No copies found in your libraries.',
			'watchTogether.choiceFailed' => 'Couldn\'t play this copy for the room',
			'watchTogether.lengthLonger' => ({required Object duration}) => '${duration} longer',
			'watchTogether.lengthShorter' => ({required Object duration}) => '${duration} shorter',
			'watchTogether.lengthSame' => 'Same length',
			'watchTogether.lengthUnknown' => 'Length unknown',
			'watchTogether.joinCurrentPlayback' => 'Join Current Playback',
			'watchTogether.joinCurrentPlaybackDescription' => 'Jump back into what the host is currently watching',
			'watchTogether.stopMedia' => 'Stop Video for Everyone',
			'watchTogether.syncOffset' => 'Sync Offset',
			'watchTogether.syncOffsetDescription' => 'Shift your video if it runs ahead of or behind the room.',
			'watchTogether.offsetHint' => ({required Object difference}) => 'Your copy is ${difference} than the room\'s video.',
			'watchTogether.applyDifference' => ({required Object offset}) => 'Use ${offset}',
			'watchTogether.offsetMinusSecond' => '-1 s',
			'watchTogether.offsetMinusTenth' => '-100 ms',
			'watchTogether.offsetPlusTenth' => '+100 ms',
			'watchTogether.offsetPlusSecond' => '+1 s',
			'watchTogether.participants' => 'Participants',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} participant', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} participants', ), 
			'watchTogether.hostBadge' => 'HOST',
			'watchTogether.nameYou' => ({required Object name}) => '${name} (You)',
			'watchTogether.playerIdle' => 'Idle',
			'watchTogether.playerLoading' => 'Loading',
			'watchTogether.playerReady' => 'Ready',
			'watchTogether.playerBuffering' => 'Buffering',
			'watchTogether.matchSearching' => 'Searching',
			'watchTogether.matchMatched' => 'Has the video',
			'watchTogether.matchMismatched' => 'Different length',
			'watchTogether.matchUnavailable' => 'Doesn\'t have the video',
			'watchTogether.participantOffset' => ({required Object offset}) => 'Offset ${offset}',
			'watchTogether.makeHost' => 'Make host',
			'watchTogether.makeHostQuestion' => 'Transfer host?',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} will control playback and drive the session for everyone.',
			'watchTogether.transfer' => 'Transfer',
			'watchTogether.removeParticipant' => 'Remove from Room',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => 'Remove ${name}?',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} leaves the room. They can join again with the code unless you lock the room.',
			'watchTogether.remove' => 'Remove',
			'watchTogether.roomSettings' => 'Room Settings',
			'watchTogether.letEveryoneControl' => 'Let Everyone Control Playback',
			'watchTogether.lockRoom' => 'Lock Room',
			'watchTogether.lockRoomDescription' => 'Nobody new can join',
			'watchTogether.leaveRoom' => 'Leave Room',
			'watchTogether.leaveRoomQuestion' => 'Leave Room?',
			'watchTogether.leaveRoomConfirm' => 'You can join again with the room code.',
			'watchTogether.leave' => 'Leave',
			'watchTogether.endRoom' => 'End Room',
			'watchTogether.endRoomQuestion' => 'End Room?',
			'watchTogether.endRoomConfirm' => 'This ends the room for everyone.',
			'watchTogether.end' => 'End',
			'watchTogether.playBlockedTitle' => 'Playback didn\'t start',
			'watchTogether.playBlockedDescription' => 'Press play to start watching with the room.',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} pressed play',
			'watchTogether.notices.playbackStarted' => 'Playback started',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} paused',
			'watchTogether.notices.playbackPaused' => 'Playback paused',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} jumped to ${position}',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => 'Jumped to ${position}',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} set the speed to ${speed}',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => 'Speed set to ${speed}',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} started ${title}',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => 'Now playing ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} stopped the video',
			'watchTogether.notices.mediaStopped' => 'The video stopped',
			'watchTogether.notices.waitingFor' => ({required Object name}) => 'Waiting for ${name}...',
			'watchTogether.notices.waitingForSomeone' => 'Waiting for someone to catch up...',
			'watchTogether.notices.finished' => 'Finished',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} is now the host',
			'watchTogether.notices.youAreNowHost' => 'You are now the host',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} joined',
			'watchTogether.notices.left' => ({required Object name}) => '${name} left',
			'watchTogether.notices.controlRefused' => 'Only the host can control playback',
			'watchTogether.notices.searchFailed' => 'Some servers couldn\'t be searched for the room\'s video',
			'watchTogether.notices.playBlocked' => 'Press play to start',
			'watchTogether.notices.shareFailed' => 'Couldn\'t share this video with the room',
			'watchTogether.notices.downloadNotShared' => 'Downloads aren\'t shared with the room while their server is offline',
			'watchTogether.notices.openFailed' => 'Couldn\'t open the room\'s video',
			'watchTogether.ended.ended' => 'The host ended the room',
			'watchTogether.ended.kicked' => 'You were removed from the room',
			'watchTogether.ended.expired' => 'The room expired',
			'watchTogether.ended.replaced' => 'You joined this room on another device',
			'watchTogether.ended.lost' => 'Lost the connection to the room',
			'watchTogether.errors.invalidCode' => 'That isn\'t a room code. Codes have 6 letters and digits, without 0, 1, I, L or O.',
			'watchTogether.errors.roomNotFound' => 'No room has that code. It may have ended.',
			'watchTogether.errors.roomFull' => 'That room is full.',
			'watchTogether.errors.roomLocked' => 'The host locked that room.',
			'watchTogether.errors.relayFull' => 'Watch Together is busy right now. Try again later.',
			'watchTogether.errors.unreachable' => 'Couldn\'t reach the Watch Together relay. Check your connection.',
			'watchTogether.errors.rateLimited' => 'Too many attempts. Wait a moment and try again.',
			'watchTogether.errors.clientBlocked' => 'This version of PlezyNG can\'t use the relay. Update the app.',
			'watchTogether.errors.forbidden' => 'Only the host can do that.',
			'watchTogether.errors.notInRoom' => 'You\'re not in a room.',
			'watchTogether.errors.alreadyInRoom' => 'You\'re already in a room.',
			'watchTogether.errors.resumeFailed' => 'Couldn\'t rejoin the room.',
			'watchTogether.errors.unsupported' => 'The relay doesn\'t support this.',
			'watchTogether.errors.generic' => 'Something went wrong. Try again.',
			'watchTogether.untitledEpisode' => ({required Object number}) => 'Episode ${number}',
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
			'downloads.storageFull' => 'Downloads stopped to protect available storage. Free some space or choose another download location, then retry.',
			'downloads.storageUnavailable' => 'Downloads stopped because available storage could not be checked. Check the download location, then retry.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} episodes queued for download',
			'downloads.downloadDeleted' => 'Download deleted',
			'downloads.deleteConfirm' => ({required Object title}) => 'Delete "${title}" from this device?',
			'downloads.deleteCollectionDownloads' => 'Delete downloads',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => 'Delete every download in "${title}" from this device?',
			'downloads.collectionDownloadsDeleted' => 'Downloads deleted',
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
			'downloads.resumeAll' => 'Resume all',
			'downloads.retryAll' => 'Retry all',
			'downloads.retryFailed' => 'Retry failed downloads',
			'downloads.deleteAll' => 'Delete all',
			'downloads.selectVersion' => 'Select Version',
			'downloads.allEpisodes' => 'All episodes',
			'downloads.unwatchedOnly' => 'Unwatched only',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Next ${count} unwatched',
			'downloads.customAmount' => 'Custom amount...',
			'downloads.customAmountAny' => 'Custom amount (any)...',
			'downloads.randomEpisodes' => 'Random episodes',
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
			'downloads.syncNow' => 'Sync now',
			'downloads.downloadsUpToDate' => 'Downloads are up to date',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => 'Sync complete · ${queued} queued, ${removed} removed',
			'downloads.activeSyncRules' => 'Sync rules',
			'downloads.reviewOrphanFiles' => 'Review orphaned downloads',
			'downloads.orphanReviewTitle' => 'Review orphaned downloads',
			'downloads.orphanReviewDescription' => 'These tagged files are in PlezyNG\'s default app-managed download folders and have no matching download record or active task. Check the list before deleting them.',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count} files · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => 'Delete ${count} files',
			'downloads.orphanCleanupNone' => 'No orphaned download files found',
			'downloads.orphanCleanupFailed' => 'PlezyNG could not safely scan the managed downloads folder. No files were deleted.',
			'downloads.orphanCleanupChanged' => 'The download list changed during review. Review the files again before cleaning.',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => 'Deleted ${count} orphaned files · ${size} freed',
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
			'downloads.syncRuleAccessDenied' => 'Access denied',
			'downloads.syncRuleNotAvailableForProfile' => 'Not available for current profile',
			'downloads.syncRuleUnknownServer' => 'Unknown server',
			'downloads.syncRuleListCreated' => 'Sync rule created',
			'downloads.backgroundWarning.bannerBlocked' => 'Downloads will stop when you leave the app',
			'downloads.backgroundWarning.bannerDegraded' => 'Background downloads may be limited',
			'downloads.backgroundWarning.bannerAction' => 'Details',
			'downloads.backgroundWarning.sheetTitle' => 'Background downloads are blocked',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Background downloads may be limited',
			'downloads.backgroundWarning.sheetIntro' => 'Android is preventing PlezyNG from downloading reliably in the background.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Your device is limiting when PlezyNG can download in the background.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'PlezyNG\'s background usage is restricted. Set its battery or background usage to "Unrestricted".',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android has put PlezyNG in a restricted standby state. Set its battery usage to "Unrestricted".',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Download notifications are turned off, so progress and controls may be unavailable.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Notifications are turned off. On Android 13 or newer, they are required for long background downloads.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Data Saver is on, which blocks background downloads on mobile data. Downloads should still run on Wi-Fi.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Downloads repeatedly stopped while PlezyNG was in the background. Check PlezyNG\'s battery or background usage settings.',
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
			'downloads.options' => 'Downloads options',
			'downloads.groupings.library' => 'Library',
			'downloads.groupings.collections' => 'Collections',
			'downloads.unknownLibrary' => 'Unknown library',
			'downloads.unknownShow' => 'Unknown Show',
			'downloads.unknownSeason' => 'Unknown Season',
			'downloads.unknownAlbum' => 'Unknown Album',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} completed',
			'downloads.storageUsed' => ({required Object size}) => 'Storage used: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} download', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} downloads', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} show', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} shows', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} movie', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} movies', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} album', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} albums', ), 
			'downloads.errorFileNotFound' => 'File not found (404)',
			'downloads.errorDownloadNotAllowed' => 'Download not allowed by the server (403)',
			'downloads.errorDownloadFailed' => 'Download failed',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'Download failed: ${reason}',
			'downloads.convertingOnServer' => 'Converting on server…',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => 'Converting on server · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => 'Download failed (HTTP ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => 'Post-processing failed: ${reason}',
			'downloads.reasonFileNotSaved' => 'the file could not be saved on this device',
			'downloads.reasonCannotResume' => 'the partial download could not be resumed',
			'downloads.reasonDeviceStorageFull' => 'this device is out of storage',
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
			'companionRemote.pairing.discoveryDescription' => 'PlezyNG devices with the same Plex account appear here',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Connecting...',
			'companionRemote.pairing.searchingForDevices' => 'Looking for devices...',
			'companionRemote.pairing.noDevicesFound' => 'No devices found on your network',
			'companionRemote.pairing.noDevicesHint' => 'Open PlezyNG on desktop and use the same Wi-Fi',
			'companionRemote.pairing.availableDevices' => 'Available Devices',
			'companionRemote.pairing.manualConnection' => 'Manual Connection',
			'companionRemote.pairing.cryptoInitFailed' => 'Couldn\'t start secure connection. Sign in to Plex first.',
			'companionRemote.pairing.validationHostRequired' => 'Please enter host address',
			'companionRemote.pairing.validationHostFormat' => 'Format must be IP:port (e.g., 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Connection timed out. Use the same network on both devices.',
			'companionRemote.pairing.sessionNotFound' => 'Device not found. Make sure PlezyNG is running on the host.',
			'companionRemote.pairing.authFailed' => 'Authentication failed. Both devices need the same Plex account.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Failed to connect: ${error}',
			'companionRemote.pairing.codeTitle' => 'Pairing code',
			'companionRemote.pairing.codeDescription' => 'Enter the code shown in Companion Remote on the host device. Both devices must use a version that supports secure pairing.',
			'companionRemote.pairing.codeInvalid' => 'Enter all 32 letters and numbers from the host code.',
			'companionRemote.pairing.updateRequired' => 'Update both devices to a version that supports secure pairing.',
			'companionRemote.pairing.hostDescription' => 'Enter this code once on each remote. Keep it private: it grants control of this profile.',
			'companionRemote.pairing.resetCode' => 'Reset pairing code',
			'companionRemote.pairing.resetDescription' => 'Disconnect all remotes and create a new code. Every remote will need to pair again.',
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
			'videoSettings.videoTrack' => 'Video Track',
			'videoSettings.videoTrackDescription' => 'Choose which video stream to display. Available on MPV playback when a file contains alternate video tracks.',
			'videoSettings.videoTrackDefault' => 'Default',
			'videoSettings.videoTrackUnavailable' => 'No alternate video tracks are available.',
			'videoSettings.videoTrackFailed' => 'Could not change the video track.',
			'videoSettings.videoTrackNumber' => ({required Object id}) => 'Track ${id}',
			'videoSettings.performanceOverlay' => 'Performance Overlay',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'Surround',
			'videoSettings.audioOutputSpatial' => 'Spatial Audio',
			'videoSettings.audioOutputStereo' => 'Stereo',
			'videoSettings.audioEqualizer' => 'Audio Equalizer',
			'videoSettings.audioEqualizerDescription' => '10-band equalizer for MPV. Audio filters use decoded audio and turn off passthrough.',
			'videoSettings.audioEqualizerFlat' => 'Flat',
			'videoSettings.audioEqualizerActive' => 'Custom',
			'videoSettings.audioEqualizerSaveFailed' => 'Couldn\'t save audio equalizer settings.',
			'videoSettings.audioEffectsDescription' => 'Effects use decoded audio, so passthrough turns off. Room ambience and stereo widening depend on the MPV build and track.',
			'videoSettings.audioStereoWidth' => 'Stereo widening',
			'videoSettings.audioSpatializer' => 'Room ambience',
			'videoSettings.audioSpatializerDescription' => 'Add quiet room reflections.',
			'videoSettings.audioPitch' => 'Pitch shift',
			'videoSettings.audioPitchDescription' => 'Change pitch without changing speed. The MPV build must include Rubber Band.',
			'videoSettings.audioEffectUnavailable' => 'This effect isn\'t available for this track or MPV build.',
			'videoSettings.backgroundVideoAudio' => 'Background Video Audio',
			'videoSettings.backgroundVideoAudioDescription' => 'Keep video audio playing when you leave the player; the picture is hidden until you return. Android uses a media playback notification.',
			'videoSettings.audioNormalization' => 'Normalize Loudness',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'Decodes audio to PCM; passthrough is off while this is on',
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
			'performanceOverlay.dvRouteDecoder' => 'Dolby Vision decoder',
			'performanceOverlay.dvRouteDecoderP81' => 'Dolby Vision decoder (P7→8.1)',
			'performanceOverlay.dvRouteBaseLayer' => 'Base layer',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'HDR10 base layer',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'HLG base layer',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'SDR base layer',
			'performanceOverlay.dvRouteReshaped' => 'RPU reshaped (gpu-next)',
			'performanceOverlay.dvRouteFelGraphActive' => 'Experimental P7 FEL graph (unqualified)',
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
			_ => null,
		} ?? switch (path) {
			'performanceOverlay.player' => 'Player',
			'performanceOverlay.playMethod' => 'Play Method',
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
			'externalPlayer.description' => 'Choose another app to open videos in. Available players depend on your device and installed apps.',
			'externalPlayer.systemDefaultDescription' => 'Let the operating system open the video with its default app.',
			'externalPlayer.playerOptionDescription' => ({required Object player}) => 'Open videos with ${player}.',
			'externalPlayer.playerNameDescription' => 'The label shown in the player list.',
			'externalPlayer.playerPackageDescription' => 'Enter the Android package name of the player app, such as com.example.player.',
			'externalPlayer.playerCommandDescription' => 'Enter the installed player command or executable path for this device.',
			'externalPlayer.playerUrlSchemeDescription' => 'Enter the URL scheme and optional URL template used to launch the player.',
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
			'metadataEdit.quickTag' => 'Quick Tag...',
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
			'matchScreen.plexDiscover' => 'Plex Discover',
			'matchScreen.plexLibrary' => 'Plex library',
			'matchScreen.jellyfinLibrary' => 'Jellyfin library',
			'matchScreen.embyLibrary' => 'Emby library',
			'serverTasks.title' => 'Server Tasks',
			'serverTasks.failedToLoad' => 'Failed to load tasks',
			'serverTasks.noTasks' => 'No tasks running',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Connected',
			'trakt.connectedAs' => ({required Object username}) => 'Connected as @${username}',
			'trakt.disconnectConfirm' => 'Disconnect Trakt account?',
			'trakt.disconnectConfirmBody' => 'PlezyNG will stop sending events to Trakt. You can reconnect any time.',
			'trakt.scrobble' => 'Real-time scrobbling',
			'trakt.scrobbleDescription' => 'Send play, pause, and stop events to Trakt during playback.',
			'trakt.watchedSync' => 'Sync watched status',
			'trakt.watchedSyncDescription' => 'When you mark items as watched in PlezyNG, they are also marked as watched on Trakt.',
			'trakt.historyExport' => 'Export to Letterboxd',
			'trakt.historyExportDescription' => 'Create a local CSV from Trakt movie history. Nothing is uploaded.',
			'trakt.historyExportLoading' => 'Loading Trakt movie history…',
			'trakt.historyExportReviewTitle' => 'Export movie history',
			'trakt.historyExportReview' => ({required Object plays, required Object movies, required Object files}) => 'This will save ${plays} movie watch entries covering ${movies} movies in ${files} Letterboxd import CSV file(s). Files include available TMDB/IMDb IDs, titles, years, and watched dates using this device\'s local calendar date. TV episodes and ratings are excluded; nothing is uploaded. Letterboxd may combine repeat watches on the same date. Each file stays below Letterboxd\'s 1 MB import limit.',
			'trakt.historyExportSkipped' => ({required Object count}) => '${count} incomplete entries could not be included.',
			'trakt.historyExportNoHistory' => 'No exportable movie history was found in Trakt.',
			'trakt.historyExportFailed' => 'Couldn\'t load Trakt movie history. Try again.',
			'trakt.historyExportSave' => 'Save CSV',
			'trakt.historyExportPart' => ({required Object part, required Object total}) => 'Save Letterboxd file ${part} of ${total}',
			'trakt.historyExportSaved' => ({required Object count}) => 'Saved ${count} Letterboxd CSV file(s).',
			'trakt.historyExportPartial' => ({required Object saved, required Object total}) => 'Export stopped after saving ${saved} of ${total} files.',
			'trakt.historyExportSaveFailed' => 'Couldn\'t save the CSV file. Try again.',
			'trakt.historyExportTooLarge' => 'This history is too large to package here. Use Trakt\'s own data export to split very large histories.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Connect Seerr',
			'seerr.serverUrl' => 'Server URL',
			'seerr.serverUrlHelper' => 'The address of your Seerr instance',
			'seerr.checkServer' => 'Continue',
			'seerr.signInWithJellyfin' => 'Sign in with Jellyfin',
			'seerr.signInWithEmby' => 'Sign in with Emby',
			'seerr.signInWithLocal' => 'Use a local account',
			'seerr.email' => 'Email',
			'seerr.noSignInMethods' => 'This Seerr instance offers no sign-in method PlezyNG supports.',
			'seerr.instance' => 'Instance',
			'seerr.disconnectConfirm' => 'Disconnect Seerr?',
			'seerr.disconnectConfirmBody' => 'PlezyNG will forget this Seerr instance. Reconnect any time.',
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
			'seerr.behindAuthProxy' => 'An authenticating reverse proxy (SSO or HTTP auth) answered instead of Seerr. PlezyNG cannot sign in through it: let Seerr\'s /api/v1 path bypass the proxy for this app, or use an address that reaches Seerr directly.',
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
			'services.hardcover' => 'Hardcover',
			'services.linkedCatalogTitles' => 'Linked catalog titles',
			'services.planNote' => 'Optional plan note. This label is only for you; PlezyNG does not verify account access.',
			'services.planLabel' => 'Plan label',
			'services.setPlanLabel' => 'Set plan label',
			'services.commissionDisclosure' => 'PlezyNG may earn a commission from some links.',
			'services.notConnected' => 'Not connected',
			'services.connectedAs' => ({required Object username}) => 'Connected as @${username}',
			'services.scrobble' => 'Track progress automatically',
			'services.scrobbleDescription' => 'Update your list when you finish an episode or movie.',
			'services.disconnectConfirm' => ({required Object service}) => 'Disconnect ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'PlezyNG will stop updating ${service}. Reconnect any time.',
			'services.connectFailed' => ({required Object service}) => 'Couldn\'t connect to ${service}. Try again.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'Reconnect Simkl',
			'services.simklReconnect.subtitle' => 'Simkl is retiring the sign-in method this connection uses. Reconnecting opens simkl.com to approve PlezyNG — PlezyNG never sees your password. Your watch history stays on Simkl.',
			'services.deviceCode.title' => ({required Object service}) => 'Activate PlezyNG on ${service}',
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
			'services.libraryFilter.modeDescription' => 'Choose whether the checked libraries are blocked from syncing or are the only libraries that sync.',
			'services.seerrDescription' => 'Connect to Seerr or Overseerr to search for titles and submit media requests.',
			'services.trackerDescriptions.trakt' => 'Sync watched episodes and movies with your Trakt account.',
			'services.trackerDescriptions.mal' => 'Sync anime lists and watch progress with MyAnimeList.',
			'services.trackerDescriptions.anilist' => 'Sync anime lists and watch progress with AniList.',
			'services.trackerDescriptions.simkl' => 'Sync watched movies, TV shows, and anime with Simkl.',
			'services.trackerDescriptions.mdblist' => 'Show MDBList ratings and lists in recommendations and Explore.',
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
			'addServer.directPlexServerUrl' => 'Plex server URL',
			'addServer.directPlexServerUrlHelper' => 'Enter the local IP and port of your Plex Media Server.',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex Token (optional)',
			'addServer.plexTokenHelper' => 'Leave blank if access without auth is allowed on this server.',
			'addServer.plexTokenRequired' => 'Authentication required. Please enter your Plex token (X-Plex-Token).',
			'addServer.connectDirectPlexCard' => 'Plex Media Server (Direct / Local)',
			'addServer.connectDirectPlexCardSubtitle' => 'Connect directly using local IP or URL without plex.tv account.',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => 'Connect directly using local IP or URL. Binds to ${name}.',
			'addServer.insecureTitle' => 'Unencrypted connection',
			'addServer.insecureDescription' => ({required Object url}) => '${url} uses HTTP. People on the network may read or change your password, tokens and media. Use HTTPS when available. Only continue if you trust this network and accept the risk.',
			'addServer.allowHttp' => 'Allow HTTP',
			'addServer.httpsRequired' => 'Use HTTPS or explicitly allow an unencrypted connection.',
			'cast.chooseDevice' => 'Cast to a device',
			'cast.searching' => 'Searching for Cast devices…',
			'cast.connectedTo' => ({required Object device}) => 'Connected to ${device}',
			'cast.device' => 'Cast device',
			'cast.readyToCast' => 'Ready to cast',
			'cast.subtitle' => 'Subtitles',
			'cast.serverNotAvailable' => 'The media server is not available.',
			'cast.stopCasting' => 'Stop casting',
			'cast.castToDevice' => 'Cast to device',
			'cast.noEpisodeAvailable' => 'There is no episode available to cast.',
			'cast.startFailed' => 'Could not start casting. Check the server and try again.',
			'automation.noActivePlayback' => 'There is no active video session to control.',
			'notifications.newEpisodeTitle' => 'New episode',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appAccess.title' => 'Try every feature free for 7 days',
			'appAccess.description' => 'Start a seven-day trial with full access to every PlezyNG feature. There is no charge during the trial and no subscription. After the trial, one lifetime purchase at your store\'s price unlocks PlezyNG for life.',
			'appAccess.trialEndedDescription' => 'Unlock every feature in PlezyNG for life with one purchase at your store\'s price. There is no subscription.',
			'appAccess.startTrial' => 'Start my 7-day free trial',
			'appAccess.trialActive' => 'Your 7-day full-feature trial is active.',
			'appAccess.trialEnded' => 'Your 7-day trial has ended',
			'appAccess.trialStartFailed' => 'Couldn\'t save the trial on this device. Please try again.',
			'appAccess.lifetimeTitle' => 'PlezyNG unlocked for life',
			'appAccess.lifetimeBody' => 'Thanks! You have lifetime access to every PlezyNG feature.',
			'appAccess.manageTitle' => 'PlezyNG lifetime access',
			'appAccess.manageDescription' => 'Try every feature free for 7 days, then unlock everything for life with one payment at your store\'s price.',
			'appAccess.buy' => ({required Object price}) => 'Unlock every feature for ${price}',
			'appAccess.loadingPrice' => 'Loading store price...',
			'appAccess.retryPrice' => 'Retry price lookup',
			'appAccess.restore' => 'Restore lifetime purchase',
			'appAccess.pending' => 'Your purchase is waiting for payment or approval. Lifetime access unlocks as soon as the store completes it.',
			'appAccess.storeUnavailable' => 'Purchases aren\'t available. Check that you\'re signed in to the store and purchases are allowed on this device.',
			'appAccess.productNotFound' => 'The PlezyNG lifetime unlock isn\'t available in this store yet.',
			'appAccess.productQueryFailed' => 'Couldn\'t load the store price. Check your connection and try again.',
			'appAccess.purchaseFailed' => 'The purchase didn\'t go through. Try again.',
			'appAccess.restoreFailed' => 'Couldn\'t reach the store to restore your purchase. Try again.',
			'appAccess.nothingToRestore' => 'No PlezyNG lifetime purchase was found for this store account.',
			'detail.endsAt' => ({required Object time}) => 'Ends at ${time}',
			'watchLink.serverUnavailable' => 'Couldn\'t reach a Plex server for this link.',
			'watchLink.notFound' => 'Couldn\'t find this show or movie on your Plex servers.',
			'watchLink.ambiguous' => 'This link matches items on more than one server. Add a server to the link.',
			'watchLink.plexOnly' => 'Watch links currently support Plex servers only.',
			'watchLink.unsupportedItem' => 'Watch links can only open a show or a movie.',
			'watchLink.menuItem' => 'Show watch link',
			'watchLink.dialogTitle' => 'Watch link',
			'watchLink.dialogShowHint' => 'Opening this link plays the next episode. Add &mode=shuffle to the end to play the show on shuffle.',
			'watchLink.dialogMovieHint' => 'Opening this link plays the movie.',
			'watchLink.copy' => 'Copy',
			'watchLink.copied' => 'Link copied',
			'homeLayout.title' => 'Home layout',
			'homeLayout.resetToast' => 'Home reset to the original Plezy hero layout',
			'homeLayout.resetHeroTitle' => 'Reset hero layout to stock Plezy?',
			'homeLayout.resetHeroBody' => 'Turns off every row\'s hero setting and brings back the single rotating banner at the top of Home, like before hero rows existed. Row order and which rows are shown are not affected.',
			'homeLayout.removeRowTitle' => 'Remove Home row?',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} will be deleted. This can\'t be undone.',
			'homeLayout.sync' => 'Sync',
			'homeLayout.syncAccountTitle' => 'Sync layout with your Plex account',
			'homeLayout.syncAccountOn' => 'On: this device shares row order, rows, Hero and Auto-slide with your other devices.',
			'homeLayout.syncAccountOff' => 'Off: this device keeps its own layout.',
			'homeLayout.syncNow' => 'Sync now',
			'homeLayout.plexHomeManager' => 'Plex Home manager',
			'homeLayout.managePlexRows' => 'Manage Plex rows in Plezy',
			'homeLayout.managePlexRowsDescription' => 'Open to organize the Home-selected rows',
			'homeLayout.organizeHomeRows' => 'Organize Home rows',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} rows: move, Hero, Auto-slide, remove',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => 'Organize ${library} rows',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => 'Continue Watching + ${n} rows: move, Library, Home, Hero, Auto-slide',
			'homeLayout.renderAsHero' => 'Render as a hero card',
			'homeLayout.heroOnlySingleCollection' => 'Only available when this row resolves to a single collection\'s actual titles',
			'homeLayout.hero' => 'Hero',
			'homeLayout.autoSlide' => 'Auto-slide',
			'homeLayout.autoSlideDescription' => 'Also slides on its own every few seconds. Arrows (PC) and d-pad (TV) always work and restart the timer.',
			'homeLayout.autoSlideEditDescription' => 'Also slides on its own every few seconds. Off: only moves when you click an arrow (PC) or press left/right on the remote (TV). Arrows and d-pad always work either way.',
			'homeLayout.enableHeroFirst' => 'Enable Hero first',
			'homeLayout.showOnHome' => 'Show on Home screen',
			'homeLayout.home' => 'Home',
			'homeLayout.removeFromHome' => 'Remove from Home',
			'homeLayout.selectRowsFirst' => 'Select Home rows below first.',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} Plex-managed rows',
			'homeLayout.continueWatching' => 'Continue Watching',
			'homeLayout.continueWatchingLibraryDescription' => 'This library\'s own resume-progress row',
			'homeLayout.continueWatchingHomeDescription' => 'The resume-progress row shown on Home',
			'homeLayout.nextUpHomeDescription' => 'The next unwatched episode row shown separately on Home',
			'homeLayout.library' => 'Library',
			'homeLayout.showInRecommended' => 'Show in Library Recommended',
			'homeLayout.customPlexRow' => 'Custom Plex row',
			'homeLayout.heroNeedsLibrary' => 'Check Library first — Hero needs somewhere to show',
			'homeLayout.heroNeedsSurface' => 'Check Library or Home first — Hero needs somewhere to show',
			'homeLayout.removeHub' => 'Remove Hub',
			'homeLayout.noPlexRows' => 'No Plex-managed rows returned for this library.',
			'homeLayout.openDetails' => 'Open details',
			'homeLayout.heroCards' => 'Hero cards',
			'homeLayout.tapHeroCard' => 'Tapping a hero card',
			'homeLayout.tvPlayFocus' => 'TV remote: highlight Play button',
			'homeLayout.tvPlayFocusDescription' => 'D-pad down stops on the Play button before moving to the next row. Off skips straight to the next row.',
			'homeLayout.tvWrap' => 'TV remote: loop hero cards',
			'homeLayout.tvWrapDescription' => 'Right on the last card goes back to the first. Off stops at the last card. Left on the first card always goes to the sidebar.',
			'homeLayout.castOnHero' => 'Cast on hero banners',
			'homeLayout.castOnHeroDescription' => 'Shows the cast along the bottom of a hero banner. Off keeps just the title and summary.',
			'homeLayout.customRows' => 'Custom rows',
			'homeLayout.loading' => 'Loading home layout…',
			'homeLayout.noCustomRows' => 'No custom rows yet',
			'homeLayout.addRowHint' => 'Use Add Home row to create one.',
			'homeLayout.addHomeRow' => 'Add Home row',
			'homeLayout.addHomeRowDescription' => 'Choose a category; the new row is added to Organizer automatically',
			'homeLayout.removeRow' => 'Remove row',
			'homeLayout.recentlyAdded' => 'Recently Added',
			'homeLayout.recentlyReleased' => 'Recently Released',
			'homeLayout.movieCollections' => 'Movie Collections',
			'homeLayout.showCollections' => 'Show Collections',
			'homeLayout.rowTitle' => 'Row title',
			'homeLayout.content' => 'Content',
			'homeLayout.showThisRowIn' => 'Show this row in:',
			'homeLayout.libraryRecommended' => 'Library Recommended',
			'homeLayout.heroCard' => 'Hero card',
			'homeLayout.heroCardDescription' => 'Shows as one full-width rotating card instead of a poster shelf.',
			'homeLayout.heroUnavailableDescription' => 'Only available when this row resolves to a single collection\'s actual titles — with more than one collection selected there is no single title to rotate through.',
			'homeLayout.librariesSelection' => 'Libraries (leave all unchecked to include every library)',
			'homeLayout.librariesMergedDescription' => 'Every library checked here is merged into this one row.',
			'homeLayout.movieCollectionsSelection' => 'Movie collections (leave all unchecked for every selected library)',
			'homeLayout.showCollectionsSelection' => 'Show collections (leave all unchecked for every selected library)',
			'homeLayout.collectionRowsDescription' => 'If exactly one collection matches, its titles show directly in the row. If more than one matches, each collection shows as a single poster — tap it to open that collection.',
			'homeLayout.allCollections' => 'All collections',
			'homeLayout.noRowsHere' => 'No rows here yet.',
			'homeLayout.hideWatchedRows' => 'Hide watched items in rows',
			'homeLayout.hideWatchedRowsDescription' => 'Fully watched titles leave Home and library Recommended rows. In-progress ones stay.',
			'homeLayout.untitledCollection' => 'Untitled collection',
			'homeLayout.moveRowHint' => 'Up/Down: move row · Select: drop it here · Back: cancel',
			'homeLayout.organizeRowsHint' => 'Select on a row (or hold Select): move it · Left/Right: row options · Back: done',
			'homeLayout.layoutNavDescription' => 'Choose rows, libraries, and collection categories',
			'homeLayout.editHomeRow' => 'Edit Home row',
			'homeLayout.resetHeroButton' => 'Reset hero layout to stock Plezy',
			'homeLayout.reorderingUnlocked' => 'Reordering unlocked',
			'homeLayout.reorderingLocked' => 'Reordering locked',
			'homeLayout.rowsCanBeDragged' => 'Rows can be dragged — tap the lock to prevent that',
			'homeLayout.tapLockToDrag' => 'Tap the lock to drag rows',
			'homeLayout.customRowLabel' => ({required Object title}) => 'Custom: ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => 'Hide',
			'homeLayout.remove' => 'Remove',
			'homeLayout.libraryResumeRow' => 'This library\'s resume row',
			'homeLayout.pressAgainToDelete' => 'Press again to delete',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => 'On',
			'homeLayout.resetHeroButtonDescription' => 'Turns off every row\'s hero setting and brings back the single rotating banner at the top, like before hero rows existed. Row order is kept.',
			'homeLayout.tapHeroCardDescription' => 'Choose whether tapping or selecting a Hero card starts playback or opens its details.',
			'homeLayout.heroTapPlayDescription' => 'Start the selected item right away.',
			'homeLayout.heroTapDetailsDescription' => 'Open the selected item’s details before choosing an action.',
			'platform.localNetworkPermission' => 'PlezyNG connects to your media servers and playback devices on your local network.',
			'platform.locationPermission' => 'PlezyNG uses location access when iOS requires it to detect your local network and connect to your media servers.',
			'platform.photoLibraryPermission' => 'Choose images from your photo library to use as media artwork.',
			'platform.cameraPermission' => 'Scan QR codes to pair a Companion Remote.',
			'universalMedia.title' => 'Open media',
			'universalMedia.shortcutHelp' => 'Play a link, playlist, or file for this session.',
			'universalMedia.intro' => 'Open a link, playlist, or file. Playback uses PlezyNG’s standard player and does not add history to your library.',
			'universalMedia.openWhat' => 'What would you like to open?',
			'universalMedia.stream' => 'Stream address',
			'universalMedia.playlist' => 'Playlist',
			'universalMedia.files' => 'Device files',
			'universalMedia.favorites' => 'Saved stream favorites',
			'universalMedia.address' => 'Media address',
			'universalMedia.addressHelp' => 'HTTPS is preferred. URLs with recognized credential or signature parameters are used only for this session and cannot be saved as favorites.',
			'universalMedia.displayName' => 'Display name (optional)',
			'universalMedia.displayNameHelp' => 'Choose a short name for the player and system media controls.',
			'universalMedia.allowHttp' => 'Allow an unencrypted HTTP connection',
			'universalMedia.allowHttpHelp' => 'HTTP does not encrypt the connection. Allow it only on a trusted network. Use HTTPS when possible.',
			'universalMedia.advancedProtocols' => 'MPV only: enter an RTSP, RTMP/RTMPS, UDP, or RTP address. These addresses cannot be saved as favorites.',
			'universalMedia.liveStream' => 'Treat as live',
			'universalMedia.liveStreamHelp' => 'Use this for live video or radio. The app hides the time bar, skip buttons, and go-to-time option. Turn it off for a recording.',
			'universalMedia.privateSession' => 'Only this playback uses the address. Save an eligible stream favorite to keep it in this profile.',
			'universalMedia.saveFavorite' => 'Save favorite',
			'universalMedia.playNow' => 'Play now',
			'universalMedia.favoriteSaved' => 'Stream favorite saved to this profile',
			'universalMedia.skippedEntries' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'Skipped ${count} unsupported or unsafe playlist entry.', other: 'Skipped ${count} unsupported or unsafe playlist entries.', ), 
			'universalMedia.playlistAddress' => 'Playlist address',
			'universalMedia.playlistAddressHelp' => 'Open an M3U, M3U8, or PLS playlist from a web address. Direct stream links do not save the playlist.',
			'universalMedia.choosePlaylist' => 'Choose playlist file',
			'universalMedia.openPlaylist' => 'Open playlist',
			'universalMedia.playlistFormatsHelp' => 'A playlist can contain at most 1,000 items and 2 MB. HLS manifests open as streams so the player can choose a quality.',
			'universalMedia.saveQueuePlaylist' => 'Save queue as playlist',
			'universalMedia.queuePlaylistSaved' => 'Playlist saved beside the media files.',
			'universalMedia.queuePlaylistUnavailable' => 'This queue can’t be saved as a reusable local playlist.',
			'universalMedia.queuePlaylistFolderRequired' => 'Choose a save location in the same folder as the queued files.',
			'universalMedia.noFavorites' => 'No saved stream favorites yet. Favorites stay in this profile.',
			'universalMedia.removeFavorite' => 'Remove stream favorite',
			'universalMedia.filesHelp' => 'Choose audio, video, or ISO files for a temporary queue. Files and URLs are not added to library history.',
			'universalMedia.chooseFiles' => 'Choose files',
			'universalMedia.fileQueue' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '1 selected file', other: '${count} selected files', ), 
			'universalMedia.wifiTransfer' => 'Send files over Wi-Fi',
			'universalMedia.wifiTransferHelp' => 'Transfer supported files from a browser on the same trusted network.',
			'universalMedia.wifiTransferIntro' => 'Open this address in a browser on another device. Choose files to add them to this device’s Files and books library.',
			'universalMedia.wifiTransferPrivacy' => 'This device receives files over your local network. Anyone who knows this address can send files until you stop the transfer or the address expires after 15 minutes. Maximum: 100 files, 4 GiB per file, 10 GiB total.',
			'universalMedia.wifiTransferStarting' => 'Preparing a private, time-limited transfer…',
			'universalMedia.wifiTransferUnavailable' => 'Could not start the transfer. Check local-network access and try again.',
			'universalMedia.openThisAddress' => 'Open one of these addresses on the sending device',
			'universalMedia.copyAddress' => 'Copy transfer address',
			_ => null,
		} ?? switch (path) {
			'universalMedia.addressCopied' => 'Transfer address copied',
			'universalMedia.transferExpires' => ({required Object time}) => 'This address expires in ${time}.',
			'universalMedia.uploadCount' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${count} file received', other: '${count} files received', ), 
			'universalMedia.uploadedData' => ({required Object size}) => 'Received ${size}',
			'universalMedia.stopTransfer' => 'Stop transfer and invalidate address',
			'universalMedia.startTransfer' => 'Start transfer',
			'universalMedia.wifiImportedFiles' => 'Wi-Fi transfer',
			'universalMedia.wifiBrowserTitle' => 'Send files to PlezyNG',
			'universalMedia.wifiBrowserIntro' => 'Choose audio, video, ebook, or comic files to send. The files are saved in this device’s Files and books library. Maximum: 100 files, 4 GiB per file, 10 GiB total.',
			'universalMedia.uploadFilesLabel' => 'Files to send',
			'universalMedia.uploadSelected' => 'Upload selected files',
			'universalMedia.uploadSelectFirst' => 'Choose one or more files first.',
			'universalMedia.uploading' => 'Sending',
			'universalMedia.uploadComplete' => 'File added to PlezyNG.',
			'universalMedia.uploadFailed' => 'The file could not be added. Keep this page open and try again.',
			'universalMedia.liveCue' => 'LIVE',
			'universalMedia.liveSession' => 'Live stream',
			'universalMedia.liveCueHelp' => 'For live video or radio, the app hides the time bar and skip buttons. It does not save the address or watch history.',
			'universalMedia.sessionOnly' => 'This playback is session-only',
			'universalMedia.sessionOnlyHelp' => 'Playback never saves progress or history. Save the stream as a favorite to keep it in this profile if it is eligible.',
			'universalMedia.pictureAdjustments' => 'Picture adjustments',
			'universalMedia.pictureHelp' => 'These picture changes affect only this playback. They reset when playback ends.',
			'universalMedia.resetPicture' => 'Reset picture',
			'universalMedia.brightness' => 'Brightness',
			'universalMedia.contrast' => 'Contrast',
			'universalMedia.gamma' => 'Gamma',
			'universalMedia.hue' => 'Hue',
			'universalMedia.saturation' => 'Saturation',
			'universalMedia.view360' => 'Flat view for 360° video',
			'universalMedia.view360Help' => 'Use this for equirectangular 360° video. MPV needs FFmpeg’s v360 filter for this view.',
			'universalMedia.view360Unavailable' => 'This mpv build could not apply the 360° filter.',
			'universalMedia.view360Yaw' => 'Horizontal view',
			'universalMedia.view360Pitch' => 'Vertical view',
			'universalMedia.view360FieldOfView' => 'Field of view',
			'universalMedia.recordStream' => 'Record live stream',
			'universalMedia.stopRecording' => 'Stop and save recording',
			'universalMedia.recordingStarted' => 'Recording is active. Leaving playback stops and saves the recording.',
			'universalMedia.recordingSaved' => 'Recording finalized and saved.',
			'universalMedia.recordingActive' => 'Recording to this device. Leaving playback stops and saves it.',
			'universalMedia.recordingFormatHelp' => 'For video, choose MKV or MPEG-TS. For audio, choose MKA or MKV.',
			'universalMedia.replaceRecordingTitle' => 'Replace this recording?',
			'universalMedia.replaceRecordingHelp' => 'PlezyNG backs up the existing file while recording. If it cannot save the new recording, PlezyNG restores the backup.',
			'universalMedia.replaceRecording' => 'Replace file',
			'universalMedia.discHelp' => 'Open a disc in this computer’s optical drive. You can also open an ISO image from Device files.',
			'universalMedia.discs' => 'Optical disc',
			'universalMedia.editionOrTitle' => 'Edition or disc title',
			'universalMedia.dvd' => 'DVD',
			'universalMedia.bluray' => 'Blu-ray',
			'universalMedia.audioCd' => 'Audio CD',
			'universalMedia.discAvailability' => 'Disc playback needs a compatible MPV build, supported drive, and operating-system permission. It cannot bypass commercial disc protection.',
			'universalMedia.converterTitle' => 'Convert a local media file',
			'universalMedia.converterHelp' => 'Convert a local file or remux it with FFmpeg.',
			'universalMedia.converterIntro' => 'Convert a local audio or video file to a format that works on more devices.',
			'universalMedia.converterPrivacy' => 'FFmpeg must be installed on this computer. Conversion reads local files only. It does not download streams or remove DRM.',
			'universalMedia.converterChooseInput' => 'Choose a local media file',
			'universalMedia.converterFormat' => 'Output format',
			'universalMedia.converterMp4' => 'MP4 · H.264 and AAC',
			'universalMedia.converterM4a' => 'M4A · AAC audio',
			'universalMedia.converterMp3' => 'MP3 · audio',
			'universalMedia.allowFtp' => 'Allow FTP',
			'universalMedia.allowFtpHelp' => 'FTP sends media without encryption. Use only on trusted networks.',
			'universalMedia.converterSaveAs' => 'Save converted media as',
			'universalMedia.converterExtensionMismatch' => 'Choose a filename with the selected output extension.',
			'universalMedia.converterUnsupportedInput' => 'Choose an audio or video file.',
			'universalMedia.converterLocalOnly' => 'The selected file is not available as a local device path.',
			'universalMedia.converterReplaceTitle' => 'Replace this file?',
			'universalMedia.converterReplaceHelp' => 'PlezyNG backs up the existing file until the converted copy is saved.',
			'universalMedia.converterStarting' => 'Starting FFmpeg…',
			'universalMedia.converterProgress' => 'Converting on this computer…',
			'universalMedia.converterComplete' => 'Conversion complete. The new file is ready.',
			'universalMedia.converterFfmpegMissing' => 'FFmpeg is missing or does not support this format.',
			'universalMedia.converterFailed' => 'Conversion failed. Check that the source file can be read and the destination has enough free space.',
			'universalMedia.converterCancelled' => 'Conversion cancelled. The incomplete output was removed.',
			'universalMedia.converterDesktopOnly' => 'Local conversion is available on desktop computers with FFmpeg installed.',
			'universalMedia.converterStart' => 'Convert file',
			'universalMedia.mediaToolsTitle' => 'Media tools',
			'universalMedia.mediaToolsShortcut' => 'Capture or share media, add search extensions, or use the command line.',
			'universalMedia.mediaToolsIntro' => 'Choose a focused tool. Capture and stream-out use FFmpeg installed on this desktop. Extensions and CLI commands use bounded HTTPS requests and the existing Open media flow.',
			'universalMedia.mediaToolsAccessibility' => 'Tool choices and controls work with touch, pointer, keyboard, and D-pad focus. Recording, sharing, and search status changes are announced.',
			'universalMedia.mediaTool' => 'Media tool',
			'universalMedia.captureIntro' => 'Record your screen or a camera to an MP4 file, or preview a live input in the player. FFmpeg must be installed and include the H.264 encoder for recording.',
			'universalMedia.captureNoDevices' => 'No screen or camera was found. Check FFmpeg capture support and operating-system privacy permissions.',
			'universalMedia.captureSource' => 'Screen or camera',
			'universalMedia.captureScreen' => 'Screen',
			'universalMedia.captureAudioSource' => 'Audio input (optional)',
			'universalMedia.captureAudioHelp' => 'Add audio from a microphone or available input. Device choices depend on FFmpeg and system permissions.',
			'universalMedia.captureAudioNone' => 'No audio',
			'universalMedia.captureDefaultAudio' => 'Default audio input',
			'universalMedia.captureWaylandHelp' => 'Wayland limits this XWayland capture to the X display. Windows outside XWayland may not appear.',
			'universalMedia.captureFrameRate' => 'Capture frame rate',
			'universalMedia.capturePrivacy' => 'The recording is saved only to the file you choose. Microphone capture is optional. PlezyNG does not upload the recording.',
			'universalMedia.captureSaveAs' => 'Save screen recording as',
			'universalMedia.captureExtensionMismatch' => 'Choose a filename ending in .mp4.',
			'universalMedia.captureFfmpegMissing' => 'FFmpeg or the H.264 video encoder is unavailable. Install a supported FFmpeg build, then try again.',
			'universalMedia.captureFailed' => 'The recording could not be saved. Check device permission, available storage, and FFmpeg support.',
			'universalMedia.captureSaved' => 'Screen recording saved.',
			'universalMedia.captureElapsedLabel' => 'Recording time',
			'universalMedia.captureStart' => 'Start recording',
			'universalMedia.capturePreview' => 'Preview in player',
			'universalMedia.capturePreviewHelp' => 'Preview the selected source in the standard player. It is session-only and does not save a recording. Device support and permissions depend on MPV and the operating system. The preview uses video only; optional audio is included in saved recordings.',
			'universalMedia.capturePreviewActive' => 'Live preview · not recording',
			'universalMedia.captureStop' => 'Stop and save',
			'universalMedia.captureMode' => 'Capture',
			'universalMedia.shareMode' => 'Share',
			'universalMedia.shareIntro' => 'Send a local media file to another device on your private network. PlezyNG creates a temporary HLS stream.',
			'universalMedia.sharePrivacy' => 'Anyone on your local network who receives the private link can watch while it is active. The link expires after 60 minutes. Stop sharing to close the server and invalidate the link.',
			'universalMedia.shareChooseFile' => 'Choose media file',
			'universalMedia.shareChooseHelp' => 'Select a local audio or video file. The file stays on this computer.',
			'universalMedia.shareFfmpegMissing' => 'FFmpeg or the H.264/AAC encoders are unavailable. Install FFmpeg with H.264 and AAC encoder support.',
			'universalMedia.shareFailed' => 'The stream could not start or stopped unexpectedly. Check FFmpeg and network access.',
			'universalMedia.shareActive' => 'The stream is ready on your private network.',
			'universalMedia.shareEnded' => 'The media reached the end and is no longer being shared.',
			'universalMedia.shareStopped' => 'Sharing stopped. The temporary link is no longer valid.',
			'universalMedia.shareUrlCopied' => 'Stream address copied.',
			'universalMedia.shareOpenUrl' => 'Open this address in a player on the other device',
			'universalMedia.shareQrLabel' => 'QR code for the temporary stream address',
			'universalMedia.shareQrHelp' => 'Scan with a compatible player connected to the same private network.',
			'universalMedia.shareHttpHint' => 'This stream uses unencrypted HTTP. In PlezyNG, allow HTTP before opening it.',
			'universalMedia.shareCopyUrl' => 'Copy stream address',
			'universalMedia.shareExpiresLabel' => 'Link expires at',
			'universalMedia.shareStarting' => 'Preparing the stream…',
			'universalMedia.shareStart' => 'Start sharing',
			'universalMedia.shareStop' => 'Stop sharing',
			'universalMedia.extensionsMode' => 'Extensions and CLI',
			'universalMedia.extensionsIntro' => 'Add a data-only search extension to find media. Choose a result to load it into the familiar Open media form.',
			'universalMedia.extensionsPrivacy' => 'A manifest can define one HTTPS search endpoint and map response fields. It cannot run code, add request headers, read files, or launch shell commands.',
			'universalMedia.extensionImport' => 'Add extension manifest',
			'universalMedia.extensionEmpty' => 'No search services yet. Choose a trusted manifest JSON file to add one.',
			'universalMedia.extensionChoose' => 'Search service',
			'universalMedia.extensionSearchConsent' => 'Each search sends your words to this HTTPS service. Results open only after you select one.',
			'universalMedia.extensionSearchLabel' => 'Search media',
			'universalMedia.extensionSearch' => 'Search',
			'universalMedia.extensionSearching' => 'Searching…',
			'universalMedia.extensionNoResults' => 'No safe media results were returned. Try another search.',
			'universalMedia.extensionInstallTitle' => 'Add this search service?',
			'universalMedia.extensionReplaceTitle' => 'Update this search service?',
			'universalMedia.extensionService' => 'Service',
			'universalMedia.extensionEndpoint' => 'HTTPS endpoint',
			'universalMedia.extensionConsent' => 'Your search text is sent to this service. The manifest contains no executable code. Continue only if you trust this endpoint.',
			'universalMedia.extensionInstall' => 'Add service',
			'universalMedia.extensionReplace' => 'Update service',
			'universalMedia.extensionRemoveTitle' => 'Remove this search service?',
			'universalMedia.extensionRemoveHelp' => 'This removes the service from this profile. PlezyNG does not contact its endpoint.',
			'universalMedia.extensionRemove' => 'Remove service',
			'universalMedia.extensionInvalidManifest' => 'This file is not a supported extension manifest. See the Open media guide for the format.',
			'universalMedia.extensionSaveFailed' => 'The extension could not be saved to the active profile.',
			'universalMedia.extensionSearchFailed' => 'The search service did not return a valid response. Check the endpoint and try again.',
			'universalMedia.cliTitle' => 'Command line',
			'universalMedia.cliHelp' => 'Use the plezyctl guide to validate a manifest or search the same extension. Review its HTTPS service before each search. Results open in the existing media form; choose the playback button to start.',
			'universalMedia.cliCopyExample' => 'Copy command example',
			'universalMedia.cliCopied' => 'Command example copied.',
			'fileSources.title' => 'Files and books',
			'fileSources.subtitle' => 'Read, listen, and watch from your own files.',
			'fileSources.add' => 'Add source',
			'fileSources.importFiles' => 'Import files',
			'fileSources.localFiles' => 'On this device',
			'fileSources.source' => 'Source',
			'fileSources.name' => 'Name',
			'fileSources.endpoint' => 'Server URL',
			'fileSources.smbEndpointHint' => 'Example: smb://nas/Movies',
			'fileSources.smbEndpointInvalid' => 'Enter an SMB server and one share.',
			'fileSources.root' => 'Folder or prefix',
			'fileSources.smbFolderHelp' => 'Leave blank to use the whole share, or enter a folder within it.',
			'fileSources.username' => 'Username',
			'fileSources.smbDomain' => 'Domain (optional)',
			'fileSources.password' => 'Password',
			'fileSources.token' => 'API token',
			'fileSources.accessKey' => 'Access key ID',
			'fileSources.secretKey' => 'Secret access key',
			'fileSources.sessionToken' => 'Session token (optional)',
			'fileSources.region' => 'Region',
			'fileSources.clientId' => 'OAuth client ID',
			'fileSources.clientSecret' => 'OAuth client secret (desktop Google only)',
			'fileSources.allowHttp' => 'Allow unencrypted HTTP on a trusted network',
			'fileSources.smbEncryption' => 'Encrypt SMB3 connection',
			'fileSources.smbEncryptionHint' => 'Use SMB3 encryption when the NAS supports it.',
			'fileSources.connect' => 'Connect',
			'fileSources.cancel' => 'Cancel',
			'fileSources.save' => 'Save',
			'fileSources.close' => 'Close',
			'fileSources.removeSource' => 'Disconnect source',
			'fileSources.disconnectMessage' => 'Disconnect this source? Downloaded files and your reading and listening history will stay on this device.',
			'fileSources.localFolder' => 'Choose folder',
			'fileSources.empty' => 'Nothing here yet',
			'fileSources.emptyHint' => 'Add a source or import a book, audiobook, music, or video.',
			'fileSources.search' => 'Search this folder',
			'fileSources.searchCached' => 'Search saved library',
			'fileSources.refresh' => 'Refresh',
			'fileSources.loadMore' => 'Load more',
			'fileSources.offline' => 'Available offline',
			'fileSources.download' => 'Keep offline',
			'fileSources.removeDownload' => 'Remove offline copy',
			'fileSources.continueReading' => 'Continue reading',
			'fileSources.continueListening' => 'Continue listening',
			'fileSources.continueWatching' => 'Continue watching',
			'fileSources.read' => 'Read',
			'fileSources.listen' => 'Listen',
			'fileSources.play' => 'Play',
			'fileSources.pause' => 'Pause',
			'fileSources.stop' => 'Stop',
			'fileSources.startOver' => 'Start over',
			'fileSources.finished' => 'Finished',
			'fileSources.markFinished' => 'Mark finished',
			'fileSources.markUnfinished' => 'Mark unfinished',
			'fileSources.editions' => 'Editions and files',
			'fileSources.chapters' => 'Chapters',
			'fileSources.bookmarks' => 'Bookmarks and notes',
			'fileSources.bookmark' => 'Add bookmark',
			'fileSources.highlight' => 'Highlight',
			'fileSources.note' => 'Note',
			'fileSources.delete' => 'Delete',
			'fileSources.export' => 'Export notes',
			'fileSources.exported' => 'Notes exported',
			'fileSources.sync' => 'Sync progress',
			'fileSources.synced' => 'Progress synced',
			'fileSources.conflict' => 'Another device has a different position. Choose where to continue.',
			'fileSources.useLocal' => 'Use this device',
			'fileSources.useRemote' => 'Use other device',
			'fileSources.history' => 'Position history',
			'fileSources.groupAudio' => 'Listen as one audiobook',
			'fileSources.groupHint' => 'Combines the audio files currently loaded in this folder. Load all pages first.',
			'fileSources.order' => 'File order',
			'fileSources.moveUp' => 'Move up',
			'fileSources.moveDown' => 'Move down',
			'fileSources.speed' => 'Playback speed',
			'fileSources.sleep' => 'Sleep timer',
			'fileSources.sleepOff' => 'Off',
			'fileSources.endChapter' => 'End of chapter',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutes', one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minute', ), 
			'fileSources.skipBack' => 'Skip back',
			'fileSources.skipForward' => 'Skip forward',
			'fileSources.smartRewind' => 'Smart rewind after a pause',
			'fileSources.playbackOptions' => 'Listening options',
			'fileSources.remaining' => ({required Object time}) => '${time} remaining',
			'fileSources.contents' => 'Contents',
			'fileSources.readerSettings' => 'Reading settings',
			'fileSources.fontSize' => 'Text size',
			'fileSources.lineHeight' => 'Line spacing',
			'fileSources.margin' => 'Margins',
			'fileSources.font' => 'Typeface',
			'fileSources.serif' => 'Serif',
			'fileSources.sans' => 'Sans serif',
			'fileSources.mono' => 'Monospace',
			'fileSources.columns' => 'Columns',
			'fileSources.scroll' => 'Scroll vertically',
			'fileSources.justify' => 'Justify text',
			'fileSources.readerTheme' => 'Page appearance',
			'fileSources.appTheme' => 'Follow app theme',
			'fileSources.paper' => 'Paper',
			'fileSources.sepia' => 'Sepia',
			'fileSources.night' => 'Night',
			'fileSources.readAloud' => 'Read this page aloud',
			'fileSources.readAlong' => 'Read along',
			'fileSources.stopReading' => 'Stop narration',
			'fileSources.searchBook' => 'Search in book',
			'fileSources.noMatches' => 'No matches',
			'fileSources.previousPage' => 'Previous page',
			'fileSources.nextPage' => 'Next page',
			'fileSources.page' => ({required Object number}) => 'Page ${number}',
			'fileSources.externalBlocked' => 'External book links are disabled in the reader.',
			'fileSources.loading' => 'Opening…',
			'fileSources.narrator' => 'Narrator',
			'fileSources.audio' => 'Audio',
			'fileSources.video' => 'Video',
			'fileSources.ebooks' => 'Ebooks',
			'fileSources.all' => 'All',
			'fileSources.downloads' => 'Offline files',
			'fileSources.confirmDelete' => 'Remove the selected offline copy? Your position and notes will stay.',
			'fileSources.errorAuthentication' => 'Sign in again to reconnect this source.',
			'fileSources.errorPermission' => 'This source did not grant access to the requested file.',
			'fileSources.errorUnavailable' => 'The source is unavailable. Try again, or open an offline copy.',
			'fileSources.errorUnsupported' => 'This format or connection is not supported on this device. Check the source setup guide.',
			'fileSources.errorInvalidData' => 'This file or server response could not be read safely.',
			'fileSources.errorCancelled' => 'The operation was cancelled.',
			'fileSources.errorConflict' => 'The position changed in another session. Reopen the item to choose a position.',
			'fileSources.signIn' => 'Sign in',
			'fileSources.reconnect' => 'Reconnect',
			'fileSources.folderHelp' => 'Leave blank to start at the source root. S3 URLs include the bucket.',
			'fileSources.preferences' => 'Preferences',
			'fileSources.timePosition' => 'Position',
			'fileSources.audioTrack' => 'Audio track',
			'fileSources.subtitleTrack' => 'Subtitle track',
			'fileSources.none' => 'None',
			'fileSources.fullscreen' => 'Full screen',
			'fileSources.syncLocation' => 'Progress sync folder (optional)',
			'fileSources.syncLocationHint' => 'A dedicated WebDAV folder for PlezyNG state. Uses conditional writes; media stays unchanged.',
			'fileSources.audiobooks' => 'Audiobooks',
			'fileSources.comics' => 'Comics',
			'fileSources.scan' => 'Scan for books and media',
			'fileSources.browserReader' => 'Open reader',
			'fileSources.browserReaderHelp' => 'The reader is open in your browser. Keep PlezyNG open to save your place and notes.',
			'fileSources.on' => 'On',
			'fileSources.advancedSetup' => 'App registration',
			'fileSources.microsoftSignIn' => 'Sign in with Microsoft',
			'fileSources.zoomIn' => 'Zoom in',
			'fileSources.zoomOut' => 'Zoom out',
			'fileSources.fitPage' => 'Fit page',
			'fileSources.fitWidth' => 'Fit width',
			'fileSources.actualSize' => 'Actual size',
			'fileSources.goToPage' => 'Go to page',
			'fileSources.goToSection' => 'Go to chapter',
			'fileSources.pageRange' => ({required Object count}) => 'Enter a number from 1 to ${count}',
			'fileSources.pageLayout' => 'Page layout',
			'fileSources.automatic' => 'Automatic',
			'fileSources.singlePage' => 'Single page',
			'fileSources.twoPages' => 'Two pages',
			'fileSources.readingDirection' => 'Reading direction',
			'fileSources.leftToRight' => 'Left to right',
			'fileSources.rightToLeft' => 'Right to left',
			'fileSources.letterSpacing' => 'Letter spacing',
			'fileSources.wordSpacing' => 'Word spacing',
			'fileSources.readerControlsHelp' => 'Pinch or use zoom controls to enlarge pages. Drag to pan. Ctrl/⌘ + or − adjusts zoom; Ctrl/⌘ 0 resets it. Page Up and Page Down turn pages.',
			'fileSources.imagePage' => 'Comic page',
			'fileSources.resetReader' => 'Reset reading preferences',
			'fileSources.zoom' => 'Zoom',
			'fileSources.useFiles' => 'Use files and books',
			'fileSources.cancelScan' => 'Cancel scan',
			'fileSources.googleDrive' => 'Google Drive',
			'fileSources.offlineQuota' => 'Offline download limit',
			'fileSources.offlineQuotaHelp' => 'Set the maximum space used by offline copies, imported files, and queued downloads. Lowering the limit does not remove existing copies.',
			'fileSources.offlineStorageUsage' => 'Offline storage',
			'fileSources.reservedStorage' => 'reserved',
			'fileSources.downloadQueue' => 'Download queue',
			'fileSources.downloadRunning' => 'Downloading',
			'fileSources.downloadQueued' => 'Waiting',
			'fileSources.downloadPaused' => 'Paused',
			'fileSources.downloadFailed' => 'Needs retry',
			'fileSources.importing' => 'Importing',
			'fileSources.importInterrupted' => 'Import interrupted · remove to clear',
			'fileSources.errorQuotaExceeded' => 'The offline storage limit was reached. Raise the limit or remove a downloaded copy.',
			'fileSources.errorStorageLow' => 'There is not enough free device storage to keep the protected reserve.',
			'fileSources.errorStorageUnavailable' => 'PlezyNG could not check free device storage, so the write was stopped.',
			'fileSources.removeDownloadJob' => 'Remove download',
			'fileSources.downloadAlreadyComplete' => 'This download finished before it could be removed. The item is now available offline.',
			'fileSources.confirmRemoveDownloadJob' => 'Remove this download and discard any partially downloaded data? Your position and notes will stay.',
			'lending.title' => 'Public libraries',
			'lending.add' => 'Add a library',
			'lending.other' => 'Another library',
			'lending.libraryName' => 'Library name',
			'lending.libraryUrl' => 'Library website',
			'lending.libraryUrlHint' => 'Use your library’s catalogue or sign-in page.',
			'lending.intro' => 'Borrow from your library. Keep your books close.',
			'lending.handoff' => 'Sign in, borrow and read securely with your library’s own service.',
			'lending.openService' => 'Open library',
			'lending.findLibrary' => 'Find a library',
			'lending.search' => 'Search books and authors',
			'lending.catalogue' => 'Catalogue',
			'lending.loans' => 'Loans',
			'lending.holds' => 'Holds',
			'lending.signIn' => 'Sign in with your library',
			'lending.waiting' => 'Finish signing in in your browser, then return here.',
			'lending.cancel' => 'Cancel',
			'lending.disconnect' => 'Remove library',
			'lending.disconnectMessage' => 'Remove this library from this profile? Your loans and holds stay with your library.',
			'lending.getBook' => 'Get book',
			'lending.checkAvailability' => 'Check availability',
			'lending.available' => 'Available to borrow',
			'lending.unavailable' => 'Currently unavailable',
			'lending.borrow' => 'Borrow',
			'lending.placeHold' => 'Place hold',
			'lending.returnBook' => 'Return early',
			'lending.cancelHold' => 'Cancel hold',
			'lending.confirmBorrow' => 'Borrow this title from your library?',
			'lending.confirmReturn' => 'Return this title now? You may need to borrow it again to continue.',
			'lending.confirmCancelHold' => 'Remove your hold on this title?',
			'lending.email' => 'Hold notification email',
			'lending.due' => ({required Object date}) => 'Due ${date}',
			'lending.queue' => ({required Object position}) => 'Position ${position} in line',
			'lending.empty' => 'No titles here yet.',
			'lending.openLibraryNote' => 'Explore Open Library’s catalogue. Reading and borrowing options are shown on each title’s page.',
			'lending.more' => 'Load more',
			'lending.gateway' => 'Library sign-in service',
			'lending.gatewayHint' => 'Provided by your library or the PlezyNG administrator.',
			'lending.advanced' => 'Library integration',
			'lending.loadLibraries' => 'Choose your library',
			'lending.expired' => 'This loan has expired.',
			'lending.updated' => 'Library updated',
			'lending.continueService' => 'Continue in service',
			'lending.comingSoon' => 'In-app borrowing · Coming soon',
			'lending.comingSoonDescription' => 'Libby integration is on its way. You can use your library in Libby while we finish connecting it.',
			'lending.suspendHold' => 'Suspend hold',
			'lending.resumeHold' => 'Resume hold',
			'lending.suspendMessage' => 'Keep your place in line and let the next reader borrow this copy? You can resume the hold later.',
			'lending.resumeMessage' => 'Resume this hold so your library can offer you the next available copy?',
			'lending.editEmail' => 'Change notification email',
			'audiobook.syncTitle' => 'Reading & listening sync',
			'audiobook.syncHelp' => 'Keep reading positions, listening positions, completion state, bookmarks and notes across your devices. Choose an attached storage account and use the same sync code on each device. Reading and listening remain separate.',
			'audiobook.addSyncSource' => 'Add Google Drive, OneDrive, Dropbox, WebDAV or S3 in Files & books first.',
			'audiobook.syncDestination' => 'Sync storage account',
			'audiobook.syncFolder' => 'Sync folder or prefix',
			'audiobook.syncFolderHelp' => 'Choose a separate existing WebDAV folder or a dedicated S3 prefix for app-owned state files. Playback media is never uploaded, replaced, renamed or deleted.',
			'audiobook.syncCode' => 'Private sync code',
			'audiobook.syncCodeHelp' => 'Create a code on your first device, then enter that code on your other devices. Keep a private copy: it is the key to your encrypted state. Use a different code for each person.',
			'audiobook.showCode' => 'Show or hide sync code',
			'audiobook.newSyncCode' => 'Create a new sync code',
			'audiobook.saveSync' => 'Save and sync',
			'audiobook.disableSync' => 'Turn off sync on this device',
			'audiobook.syncSourceDisconnect' => 'Removing this source will turn off reading and listening sync here. Encrypted sync files will remain in the provider.',
			'audiobook.syncReconnect' => 'Reconnect storage account',
			'audiobook.lastSynced' => ({required Object time}) => 'Last synced at ${time}',
			'audiobook.syncPrivacy' => 'Cloud sync writes encrypted progress, completion, bookmark and note data to app-owned sync files. Playback media is never uploaded, replaced, renamed or deleted. Account tokens and passwords are not uploaded. Google Drive and OneDrive use app storage; Dropbox uses PlezyNG Sync; WebDAV and S3 use the chosen folder or prefix. Enabling sync may require provider write permission, but the app writes only those state files. Cloud sync and compatible server progress/bookmark sync run independently with separate retries. Conflicts are shown for you to resolve. Turning sync off keeps local history and remote state.',
			'audiobook.syncConflicts' => 'Choose where to resume',
			'audiobook.conflictHelp' => 'These changes were made independently. Choose the position or bookmark version to keep. A later timestamp or a higher percentage does not automatically win.',
			'audiobook.syncDevice' => ({required Object device}) => 'Device ${device}',
			'audiobook.syncUnknownDevice' => 'unknown device',
			'audiobook.deletedBookmark' => 'Deleted bookmark',
			'audiobook.finished' => 'Finished',
			'audiobook.readingPosition' => ({required Object percent}) => 'Reading · ${percent}%',
			'audiobook.chapterTimeline' => 'Chapter progress',
			'audiobook.bookTimeline' => 'Whole book progress',
			'audiobook.bookRemaining' => ({required Object time}) => 'Time remaining in this book: ${time}',
			'audiobook.chapterRemaining' => ({required Object time}) => 'Time remaining in this chapter: ${time}',
			'audiobook.unknownRemaining' => 'Total time available as parts are played',
			'audiobook.undoSeek' => 'Undo last seek',
			'audiobook.customSpeed' => 'Custom playback speed',
			'audiobook.speedHelp' => 'Choose a speed from 0.25× to 4×.',
			'audiobook.apply' => 'Apply',
			'audiobook.customSleep' => 'Custom sleep timer',
			'audiobook.sleepMinutes' => 'Minutes (1–1440)',
			'audiobook.sleepChapters' => ({required Object count}) => 'Stop after ${count} chapters',
			'audiobook.extendSleep' => 'Add 5 minutes',
			'audiobook.sleepRemaining' => ({required Object time}) => 'Sleep timer: ${time}',
			'audiobook.useDefaults' => 'Use these listening controls for new books',
			'audiobook.librarySort' => 'Sort books',
			'audiobook.sortTitle' => 'Title',
			'audiobook.sortAuthor' => 'Author',
			'audiobook.sortNarrator' => 'Narrator',
			'audiobook.sortSeries' => 'Series order',
			'audiobook.sortRecent' => 'Recently opened',
			'audiobook.statusFilter' => 'Reading status',
			'audiobook.statusAll' => 'All books',
			'audiobook.statusNew' => 'Not started',
			'audiobook.statusProgress' => 'In progress',
			'audiobook.statusFinished' => 'Finished',
			'audiobook.goToTime' => 'Go to time',
			'audiobook.timeHelp' => 'Hours:minutes:seconds, or minutes:seconds',
			'audiobook.recoveryHelp' => 'Export a recent encrypted copy before moving or repairing sync data. Imports merge with current state; they never replace local sync history. Keep the sync code separately.',
			'audiobook.recoveryExport' => 'Export encrypted recovery file',
			'audiobook.recoveryImport' => 'Import encrypted recovery file',
			'audiobook.recoveryImportConfirm' => 'Merge this encrypted recovery file with current reading positions and notes? Existing history will be retained. Shared library and item IDs are not included; set matching IDs on every device before importing.',
			'audiobook.recoveryExported' => 'Encrypted recovery file saved.',
			'audiobook.recoveryImported' => 'Recovery data merged.',
			'sourceSetup.savedCertificate' => 'Saved server certificate',
			'sourceSetup.projectGutenberg' => 'Project Gutenberg',
			'sourceSetup.nfsEndpointInvalid' => 'Enter an NFS URL such as nfs://nas:2049/export.',
			'sourceSetup.dlnaNone' => 'No DLNA servers found. Enter the device description URL manually.',
			'sourceSetup.dlnaServers' => 'DLNA media servers',
			'sourceSetup.dlnaUnavailable' => 'DLNA discovery is unavailable on this network. Enter the device description URL manually.',
			'sourceSetup.dlnaSearching' => 'Searching local network for DLNA servers',
			'sourceSetup.networkSearching' => 'Searching local network…',
			'sourceSetup.dlnaDiscover' => 'Discover DLNA servers',
			'sourceSetup.dlnaHelp' => 'Discovery depends on local-network multicast. If no server appears, enter its device description URL above.',
			'sourceSetup.dlnaRoot' => 'DLNA object ID; blank uses the device root.',
			'sourceSetup.passwordOrKey' => 'Enter a password or add a private key below.',
			'sourceSetup.sshFingerprint' => 'SSH host key SHA256 fingerprint',
			'sourceSetup.sshFingerprintHelp' => 'Verify with the server administrator. On the server, run ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub and use its SHA256 value.',
			'sourceSetup.sshFingerprintKeep' => 'Leave blank to keep the current pin, or enter a new server fingerprint.',
			'sourceSetup.sshAuthentication' => 'SSH public key authentication',
			'sourceSetup.sshAuthenticationHelp' => 'Optional; password authentication is also supported.',
			'sourceSetup.privateKey' => 'Private key (PEM or OpenSSH format)',
			'sourceSetup.privateKeyPassphrase' => 'Private key passphrase',
			'sourceSetup.nfsMountPort' => 'NFS mount service TCP port',
			'sourceSetup.nfsMountPortHelp' => 'Default: 20048',
			'sourceSetup.nfsUserId' => 'NFS user ID (AUTH_SYS)',
			'sourceSetup.nfsUserIdHelp' => 'Default: 1000. Use the ID the NAS export allows.',
			'sourceSetup.nfsGroupId' => 'NFS group ID (AUTH_SYS)',
			'sourceSetup.nfsGroupIdHelp' => 'Default: 1000. Use the group ID the NAS export allows.',
			'sourceSetup.nfsEncryption' => 'Require encrypted NFS (RPC-with-TLS)',
			'sourceSetup.nfsEncryptionHelp' => 'Require TLS 1.3 for NFS and the mount service. Connections fail closed if the NAS does not support it.',
			'sourceSetup.nfsTrustCertificate' => 'Custom NFS CA or server certificate (PEM, optional)',
			'sourceSetup.nfsTrustHelp' => 'Leave blank for certificates trusted by this device. Add a private CA or self-signed server certificate when needed; its names must match the NFS URL host.',
			'sourceSetup.nfsTrustInvalid' => 'Use a CA or server certificate in PEM format. Do not include a private key.',
			'sourceSetup.addTrustCertificate' => 'Add custom trust certificate',
			'sourceSetup.replaceTrustCertificate' => 'Replace saved custom certificate',
			'sourceSetup.nfsTlsHelp' => 'RPC-with-TLS uses the usual NFS and mount service ports and requires NAS support for RFC 9289. TLS 1.3 is required. The host name or IP must match the certificate. AUTH_SYS UID/GID still apply inside the encrypted channel.',
			'sourceSetup.clientCertificate' => 'Client certificate (optional)',
			'sourceSetup.clientCertificateHelp' => 'Lets the NAS authenticate this client; AUTH_SYS IDs still depend on NAS export policy.',
			'sourceSetup.savedIdentity' => 'A saved client identity will be used.',
			'sourceSetup.replaceIdentity' => 'Replace saved client identity',
			'sourceSetup.chooseIdentity' => 'Choose PKCS#12 client identity',
			'sourceSetup.identityPassphrase' => 'Client identity passphrase',
			'sourceSetup.identityPassphraseHelp' => 'Leave blank if the file has no passphrase.',
			'sourceSetup.removeIdentity' => 'Remove any saved client identity',
			'sourceSetup.identityStorageHelp' => 'Client identities are saved in the encrypted source credential store. Leave this section unchanged to keep the saved identity.',
			'sourceSetup.nfsLimitations' => 'Read-only NFSv3 over TCP. Without RPC-with-TLS, NFS traffic is unencrypted. The NAS must allow the selected AUTH_SYS IDs and unprivileged client ports (often called the “insecure” export option). NFSv4 and UDP are not supported.',
			'sourceSetup.nfsSetupHelp' => 'NFS setup help',
			'sourceSetup.nfsSetupHint' => 'Check these settings if the connection does not open.',
			'sourceSetup.nfsSetupDetails' => 'Use an NFSv3 TCP export. The NFS service and mount service must both support RPC-with-TLS when encryption is required. Leave the custom certificate blank for a server certificate trusted by this device, or add the NAS CA/self-signed certificate. The certificate name must match the host in the endpoint. If the NAS asks for mutual TLS, add its PKCS#12 client identity. Finally, confirm the export allows the configured AUTH_SYS UID/GID and the client port policy.',
			'sourceSetup.ftpHelp' => 'FTP uses passive mode. Use ftp:// for plain FTP, ftpes:// for explicit TLS, or ftps:// for TLS (implicit on port 990; explicit on other ports).',
			'sourceSetup.openSubtitles' => 'OpenSubtitles',
			'sourceSetup.subtitleSetup' => 'Optional subtitle search for standalone videos.',
			'sourceSetup.apiKey' => 'API key',
			'sourceSetup.optionalUsername' => 'Account username (optional)',
			'sourceSetup.optionalPassword' => 'Account password (optional)',
			'sourceSetup.subtitlePrivacy' => 'Get an API key from opensubtitles.com. Search sends the video title and available IMDb/TMDB IDs, never the video file. The key and optional account credentials are encrypted with this source.',
			'sourceSetup.automaticMetadata' => 'Automatic online video metadata',
			'sourceSetup.metadataPrivacy' => 'Sends only filename title/year and episode numbers or an NFO ID, never media or credentials. NFO fields stay authoritative.',
			'sourceSetup.nfsEncryptionFailure' => 'For encrypted NFS, check RFC 9289 and TLS 1.3 support on both NAS services, the certificate name, and the export UID/GID. PlezyNG will not retry this connection without encryption.',
			'sourceSetup.sourceConnecting' => 'Connecting to source',
			'sourceSetup.metadataSearchPrivacy' => 'This title search goes to Trakt. It sends the title you enter, not the video or source credentials.',
			'sourceSetup.chooseMatch' => 'Choose a match',
			'sourceSetup.metadataMatchHelp' => 'Review the title and year before choosing. Trakt receives the search title; the video stays on its source.',
			'sourceSetup.metadataNoMatches' => 'No online title matches were found. Try a different title.',
			'sourceSetup.metadataSearch' => 'Search online metadata',
			'sourceSetup.metadataLoading' => 'Looking up online movie and TV details…',
			'sourceSetup.metadataFromTrakt' => 'Online metadata from Trakt',
			'sourceSetup.metadataNoAutomaticMatch' => 'No automatic title match was found. Search for the title to choose a match.',
			'sourceSetup.metadataFailed' => 'Online metadata could not be loaded. Playback and local details are still available.',
			'sourceSetup.videoDetailsLoading' => 'Loading video details',
			'sourceSetup.subtitleKeyRequired' => 'OpenSubtitles API key required',
			'sourceSetup.subtitleKeyHelp' => 'Edit this file source and add an OpenSubtitles API key in its optional subtitle settings.',
			'sourceSetup.subtitleSearchFailed' => 'Subtitle search failed. Check the API key, connection, and service access.',
			_ => null,
		} ?? switch (path) {
			'sourceSetup.subtitleApplyFailed' => 'Could not download or apply this subtitle. Check your connection and try another result.',
			'sourceSetup.subtitleSearch' => 'Search OpenSubtitles',
			'sourceSetup.subtitleSearchPrivacy' => 'Search uses the title and available IMDb/TMDB IDs. The video file stays on its source. Check language, forced or hearing-impaired flags, and rating before choosing.',
			'sourceSetup.movieOrShow' => 'Movie or show',
			'sourceSetup.subtitleTitleHint' => 'Enter a title to refine results',
			'sourceSetup.subtitleLanguage' => 'Subtitle language',
			'sourceSetup.subtitleSearching' => 'Searching OpenSubtitles',
			'sourceSetup.subtitleNoMatches' => 'No matching subtitles found. Try a different title or language.',
			'sourceSetup.downloadSubtitle' => 'Download subtitle',
			'sourceSetup.subtitle' => 'Subtitle',
			'sourceSetup.nfsTlsRequired' => 'RPC-with-TLS required',
			'sourceSetup.nfsUnencrypted' => 'Unencrypted NFS',
			'sourceSetup.tlsEncrypted' => 'TLS encrypted',
			'sourceSetup.ftpPlain' => 'Plain FTP',
			'sourceSetup.sshPinned' => 'SSH encrypted · host key pinned',
			'sourceSetup.smbEncrypted' => 'SMB3 encryption on',
			'sourceSetup.smbUnencrypted' => 'SMB3 encryption off',
			'sourceSetup.httpUnencrypted' => 'HTTP without transport encryption',
			'sourceSetup.checkEndpointSecurity' => 'Check endpoint security',
			'sourceSetup.fieldRequired' => ({required Object label}) => '${label} is required.',
			'sourceSetup.integerRange' => ({required Object label, required Object min, required Object max}) => 'Enter ${label} from ${min} to ${max}.',
			'sourceSetup.replaceFile' => ({required Object name}) => 'Replace ${name}',
			'sourceSetup.selectedIdentity' => ({required Object name}) => 'Selected client identity: ${name}',
			'sourceSetup.subtitleRating' => ({required Object rating}) => 'Rating ${rating}',
			'sourceSetup.subtitleDownloading' => ({required Object title}) => 'Downloading subtitle: ${title}',
			'sourceSetup.sharedEntryPair' => 'Pair this item',
			'sourceSetup.sharedEntryPairHelp' => 'Enter the same ID for this item on each device. Use a stable shared identifier or generate one and copy it to the matching item. Progress pairs only when the edition file types, sizes, and order match. Blank removes this mapping.',
			'sourceSetup.sharedEntryId' => 'Shared item ID',
			'sourceSetup.generateSharedEntryId' => 'Generate shared item ID',
			'sourceSetup.sharedLibraryId' => 'Shared library ID (optional)',
			'sourceSetup.sharedLibraryHelp' => 'Use the same ID on devices that open the same library. This public ID helps carry reading progress and notes across different source connections; it is not a password. When providers use different item IDs, pair those items from their detail screens.',
			'sourceSetup.sharedLibraryInvalid' => 'Use 8–100 letters, numbers, dots, underscores or hyphens.',
			'sourceSetup.generateSharedLibraryId' => 'Generate a shared library ID',
			'sourceSetup.nfsReadAhead' => 'NFS read-ahead requests',
			'sourceSetup.nfsReadAheadHelp' => 'More parallel reads can improve throughput on a fast NAS or network. Use 1 if the server limits concurrent requests.',
			'sourceSetup.nfsReadTest' => 'Measure NFS read performance',
			'sourceSetup.nfsReadTestHelp' => 'Reads up to 64 MiB from the largest file to measure this NAS connection. This uses network bandwidth.',
			'sourceSetup.nfsQualificationResult' => 'NFS read measurement',
			'sourceSetup.nfsReadBytes' => 'Data read',
			'sourceSetup.nfsReadSpeed' => 'Measured speed',
			'sourceSetup.nfsReadRequests' => 'Read requests',
			'sourceSetup.sharedEntryConflict' => 'This shared item ID is already paired with another item in this library. Choose a different ID.',
			'comics.fitHeight' => 'Fit height',
			'comics.readingMode' => 'Reading mode',
			'comics.paged' => 'Pages',
			'comics.webtoon' => 'Continuous scroll',
			'comics.coverAlone' => 'Show cover on its own',
			'comics.splitWide' => 'Split wide pages',
			'comics.splitWideHelp' => 'Show each half separately, in reading order. Double-page pairing is paused while this is on.',
			'comics.thumbnails' => 'Page thumbnails',
			'comics.controlsHelp' => 'Swipe to turn pages. Double-tap to change fit. In continuous scroll, swipe vertically or use Page Up and Page Down.',
			'comics.savedForComic' => 'Display settings are remembered for this comic in this profile.',
			'comics.readLists' => 'Reading lists',
			'comics.collections' => 'Collections',
			'games.title' => 'Games',
			'games.enable' => 'Show Games for this profile',
			'games.enableDescription' => 'Browse your games and connect gaming computers. In-app playback depends on this device’s streaming support.',
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
			'games.recent' => 'Recently played',
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
			'games.steamBetaTitle' => 'Pyrowave · experimental',
			'games.steamBetaDescription' => 'Try Steam’s low-latency codec on a fast wired network. Uses substantially more bandwidth. If it cannot start, PlezyNG reconnects using a compatible codec.',
			'games.steamLibrary' => 'Steam library',
			'games.linkSteamAccount' => 'Link Steam account',
			'games.refreshSteamAccount' => 'Refresh Steam account',
			'games.unlinkSteamAccount' => 'Unlink Steam account',
			'games.unlinkSteamAccountConfirm' => 'Remove this account and its imported catalog from this profile? Your paired computers and shortcuts stay available.',
			'games.steamAccountLinked' => 'Steam account linked. Games imported.',
			'games.steamLibraryPrivate' => 'Steam account linked. Its library is private or unavailable, so no games were imported.',
			'games.steamLibraryStale' => 'Steam could not refresh the library. Showing the last available catalog.',
			'games.steamLibraryTruncated' => 'Showing up to 2,000 games. The Steam catalog was truncated.',
			'games.connecting' => 'Connecting…',
			'games.disconnect' => 'Disconnect',
			'games.streamControls' => 'Stream controls',
			'games.steamPairInstructions' => 'Enter this code in Steam’s Remote Play pairing prompt on your computer. Keep this screen open until Steam approves.',
			'games.gameDetails' => 'Game details',
			'games.chooseComputer' => 'Choose computer',
			'games.connectComputer' => 'Connect a computer',
			'games.connectToPlay' => 'Connect a gaming computer to play this game inside PlezyNG.',
			'games.availabilityHint' => 'Steam on your computer checks installation, access and cloud saves when you connect. A saved game or computer does not mean it is available now.',
			'games.steamSource' => 'From Steam',
			'games.disconnected' => 'Disconnected',
			'games.installed' => 'Installed',
			'games.installationIncomplete' => 'Installation incomplete',
			'games.notInstalled' => 'Not in the last inventory',
			'games.installationUnknown' => 'Installation not checked',
			'games.allComputers' => 'All computers',
			'games.importInstalledGames' => 'Import installed games',
			'games.inventoryConnectHelp' => 'Connect to this computer with Companion Remote, and enable “Share installed Steam games” in its Games settings. Both devices need a version that supports library sharing.',
			'games.inventoryConfirm' => ({required Object peer, required Object computer}) => 'Use the installed games reported by ${peer} for ${computer}? Only link them if they are the same computer.',
			'games.inventoryImported' => 'Installed games updated.',
			'games.inventoryChecked' => ({required Object date}) => 'Last checked ${date}',
			'games.shareLibrary' => 'Share installed Steam games',
			'games.shareLibraryHelp' => 'Allow paired Companion Remote devices in this profile to read the names and installation state of games on this computer. Steam sign-in data and file paths stay here. Enable the Companion Remote server to connect.',
			'games.steamInstallFolder' => 'Steam installation folder',
			'games.automaticFolder' => 'Find automatically',
			'games.streamQuality' => 'Steam stream quality',
			'games.controllerSeats' => 'Steam controllers',
			'games.allowSessionControl' => 'Allow companion game session controls',
			'games.allowSessionControlHelp' => 'Let your authenticated companion view active game titles, choose game audio, show a stream fullscreen or disconnect it. Disconnecting leaves the game running on its computer. Off by default for each profile.',
			'games.remoteSessions' => 'Game sessions',
			'games.remoteSessionsHelp' => 'Control streams inside PlezyNG on the connected device. This does not quit games on their computers or send gamepad input.',
			'games.remoteSessionsDenied' => 'Enable companion game session controls in Games settings on the connected device.',
			'games.remoteSessionsUnavailable' => 'Game session controls are unavailable. Reconnect or refresh to try again.',
			'games.remoteSessionSubmitted' => 'The request was accepted. Refresh to check the current sessions.',
			'games.noRemoteSessions' => 'No active game streams are available on this device.',
			'games.remoteSessionAudible' => 'Game audio is selected',
			'games.remoteSessionMuted' => 'Game audio is not selected',
			'games.remoteSessionActions' => 'Game session actions',
			'games.remoteSessionListen' => 'Listen to this game',
			'games.remoteSessionMute' => 'Mute this game',
			'games.remoteSessionsRefresh' => 'Refresh sessions',
			'games.streamDetails' => 'Steam connection details',
			'games.streamFeedbackHelp' => 'Steam can adapt its bitrate and frame rate using receiver feedback. Your stream quality setting supplies the requested limits.',
			'games.streamMeasurements' => 'Receiver measurements',
			'games.streamMeasurementsUnavailable' => 'Not available yet',
			'games.streamVideo' => 'Video format',
			'games.streamDecoder' => 'Decoder',
			'games.streamHardwareDecoder' => 'Hardware',
			'games.streamSoftwareDecoder' => 'Software',
			'games.streamReadbackDecoder' => 'Vulkan with CPU readback',
			'games.streamHostFps' => 'Host frame rate target',
			'games.streamHostBitrate' => 'Host bitrate target',
			'games.streamLimits' => 'Host-reported frame rate limits',
			'games.streamLimitHost' => 'Host capture or encoder',
			'games.streamLimitNetwork' => 'Network',
			'games.streamLimitDecoder' => 'Receiver decoder',
			'games.streamLimitBurst' => 'Burst throttling',
			'games.streamPresentedFps' => 'Frames submitted to the display',
			'games.streamReceivedBitrate' => 'Received video payload',
			'games.streamCompletionTime' => 'Average receiver frame completion',
			'games.streamDroppedFrames' => 'Receiver-dropped frames this session',
			'games.streamVideoQueue' => 'Video queue',
			'games.streamAudioQueue' => 'Audio queue',
			'games.streamAudioChannels' => 'Audio channels',
			'games.streamInputBacklog' => 'Input packets queued + awaiting confirmation',
			'games.streamReliableRetries' => 'Reliable packet retries this session',
			'games.streamReliableGiveUps' => 'Reliable packets abandoned this session',
			'games.streamMaxAck' => 'Longest reliable packet acknowledgement',
			'games.streamMeasurementsHelp' => 'Updated once a second while this view is open. Video bitrate excludes network overhead. Frame completion includes receiver queuing, decoding and submission to the display; it does not measure network latency or screen scanout. Packet acknowledgement includes retries and is not RTT. Measurements stay on this device.',
			'games.controllerSeatsHelp' => 'Applies to new connections. Up to four controllers, assigned in order of first input. Touch controls share player one. Extra controllers are ignored; game support varies.',
			'games.streamQualityHelp' => 'Applies to new Steam connections. These are requested limits; the host and receiver decide the actual stream. Pyrowave may use more bandwidth than the bitrate limit.',
			'games.streamCodec' => 'Steam video codec',
			'games.streamCodecHelp' => 'Automatic allows HEVC on compatible receivers. Choose H.264 for compatibility. Also applies when experimental Pyrowave falls back. Changes apply to new connections.',
			'games.codecAutomatic' => 'Automatic · H.264 / HEVC',
			'games.qualityBalanced' => 'Balanced',
			'games.qualityReducedBandwidth' => 'Lower bandwidth',
			'games.qualitySharperPicture' => 'Sharper picture',
			'games.qualityReducedFrameRate' => 'Lower frame rate',
			'games.reconnect' => 'Reconnect',
			'games.reconnecting' => 'Reconnecting…',
			'games.disconnectHelp' => 'Disconnecting leaves the game running on the computer.',
			'games.streamFailed' => 'The stream stopped. Check that the computer is reachable and Steam Remote Play is enabled.',
			'games.steamActivity' => 'Steam activity',
			'games.steamActivityHelp' => 'Load news and achievements for your linked account. Activity is kept only while these details are open.',
			'games.includeFriends' => 'Include friends playing',
			'games.includeFriendsHelp' => 'Also ask Steam which friends are playing this game. Respects Steam privacy settings. Off by default.',
			'games.loadSteamActivity' => 'Load Steam activity',
			'games.activityLoading' => 'Loading Steam activity…',
			'games.activityUnavailable' => 'Steam activity is unavailable. Try again shortly.',
			'games.activityPrivate' => 'Private or unavailable from Steam.',
			'games.achievements' => 'Achievements',
			'games.achievementProgress' => ({required Object unlocked, required Object total}) => '${unlocked} of ${total} unlocked',
			'games.hiddenAchievement' => 'Hidden achievement',
			'games.hiddenAchievementHelp' => 'Details appear after you unlock it.',
			'games.achievementUnlocked' => 'Unlocked',
			'games.achievementLocked' => 'Locked',
			'games.moreAchievements' => 'Show more achievements',
			'games.gameNews' => 'Game news',
			'games.noGameNews' => 'No recent news available.',
			'games.friendsPlaying' => 'Friends playing this game',
			'games.noFriendsPlaying' => 'No friends are reported playing in this snapshot.',
			'games.activityTruncated' => 'This snapshot is limited; some achievements or friends may not be included.',
			'games.steamStore' => 'Steam store',
			'games.steamCommunity' => 'Community',
			'games.steamWorkshop' => 'Workshop',
			'games.openSteamPage' => 'Open Steam page',
			'games.openSteamPageHelp' => 'Open this game’s Steam page in your browser? Your browser’s Steam sign-in and privacy settings apply.',
			'games.hostActions' => 'Computer actions',
			'games.launchOnComputer' => 'Launch on computer',
			'games.installOnComputer' => 'Install on computer',
			'games.hostLibrary' => 'Open Steam on computer',
			'games.hostDownloads' => 'Open downloads on computer',
			'games.hostActionConfirm' => ({required Object computer}) => 'Send this action to ${computer}? Steam on that computer handles ownership, downloads, family availability and any cloud-save prompts. This does not start a stream.',
			'games.hostActionPairingHelp' => 'Pair with this computer through Companion Remote and import its installed games first. The authenticated computer identity must match.',
			'games.hostActionSubmitted' => 'Request handed to Steam on the computer. Check Steam for the result or any prompts.',
			'games.hostActionDenied' => 'This computer has not allowed that Steam action. Enable the corresponding permission in its Games settings.',
			'games.allowHostActions' => 'Allow paired remotes to control Steam',
			'games.allowHostActionsHelp' => 'Paired Companion Remotes may launch installed games and open Steam or downloads on this computer. Off by default; separate from library sharing.',
			'games.allowHostInstall' => 'Allow Steam install requests',
			'games.allowHostInstallHelp' => 'Also allow paired remotes to send installation requests to Steam. Requires Steam control above. Steam handles disk space, ownership and prompts. Off by default.',
			'games.streamAudio' => 'Steam audio',
			'games.streamAudioHelp' => 'Request stereo, quad or 5.1 audio for new streams. Surround needs a compatible host and speaker output. If the channel layout or output is unsupported, PlezyNG retries in stereo. Stream details show the negotiated channel count.',
			'games.audioStereo' => 'Stereo',
			'games.audioQuad' => 'Quad (4 speakers)',
			'games.audioSurround51' => 'Surround (5.1)',
			'deepLinks.invalid' => 'This Plezy link isn\'t valid.',
			'deepLinks.profileNotFound' => ({required Object profile}) => 'No profile matches "${profile}".',
			'deepLinks.serverUnavailable' => 'Couldn\'t reach the server for this link.',
			'deepLinks.notFound' => 'Couldn\'t find this title in your libraries.',
			'deepLinks.unsupportedItem' => 'This link can\'t be played.',
			'deepLinks.noLiveTv' => 'No Live TV server is available for this link.',
			'deepLinks.channelNotFound' => ({required Object channel}) => 'Couldn\'t find channel "${channel}".',
			'deepLinks.showLink' => 'Show link',
			'deepLinks.showProfileLink' => 'Show profile link',
			'deepLinks.dialogTitle' => 'Link',
			'deepLinks.showHint' => 'Opening this link plays the next episode. Add &mode=shuffle to play the show on shuffle.',
			'deepLinks.movieHint' => 'Opening this link plays the movie.',
			'deepLinks.episodeHint' => 'Opening this link plays this episode.',
			'deepLinks.profileHint' => 'Opening this link switches to this profile.',
			'deepLinks.openAsProfile' => ({required Object name}) => 'Open as ${name}',
			'deepLinks.copy' => 'Copy',
			'deepLinks.copied' => 'Link copied',
			'householdSetup.title' => 'Household setup',
			'issueReport.title' => 'Report a problem',
			'issueReport.instructions' => 'Scan the QR code to open a prefilled GitHub draft. Review it and submit only when you are ready.',
			'issueReport.privacy' => 'The draft includes app version, platform, and connection counts. It excludes server addresses, account and profile names, media titles, and file paths.',
			'issueReport.logPrivacy' => 'Logs are optional. Review them before uploading. Their ID is added to the draft, which may be public.',
			'issueReport.openDraft' => 'Open GitHub draft',
			_ => null,
		};
	}
}
