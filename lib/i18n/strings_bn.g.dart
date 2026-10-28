///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:plezy/i18n/locale_preferences.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsBn extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsBn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.bn,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <bn>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsBn _root = this; // ignore: unused_field

	@override 
	TranslationsBn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsBn(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$bn app = _Translations$app$bn._(_root);
	@override late final _Translations$appIcon$bn appIcon = _Translations$appIcon$bn._(_root);
	@override late final _Translations$auth$bn auth = _Translations$auth$bn._(_root);
	@override late final _Translations$common$bn common = _Translations$common$bn._(_root);
	@override late final _Translations$screens$bn screens = _Translations$screens$bn._(_root);
	@override late final _Translations$update$bn update = _Translations$update$bn._(_root);
	@override late final _Translations$settings$bn settings = _Translations$settings$bn._(_root);
	@override late final _Translations$themeEditor$bn themeEditor = _Translations$themeEditor$bn._(_root);
	@override late final _Translations$search$bn search = _Translations$search$bn._(_root);
	@override late final _Translations$hotkeys$bn hotkeys = _Translations$hotkeys$bn._(_root);
	@override late final _Translations$fileInfo$bn fileInfo = _Translations$fileInfo$bn._(_root);
	@override late final _Translations$mediaMenu$bn mediaMenu = _Translations$mediaMenu$bn._(_root);
	@override late final _Translations$rateSheet$bn rateSheet = _Translations$rateSheet$bn._(_root);
	@override late final _Translations$accessibility$bn accessibility = _Translations$accessibility$bn._(_root);
	@override late final _Translations$tooltips$bn tooltips = _Translations$tooltips$bn._(_root);
	@override late final _Translations$audioTracks$bn audioTracks = _Translations$audioTracks$bn._(_root);
	@override late final _Translations$videoControls$bn videoControls = _Translations$videoControls$bn._(_root);
	@override late final _Translations$messages$bn messages = _Translations$messages$bn._(_root);
	@override late final _Translations$subtitlingStyling$bn subtitlingStyling = _Translations$subtitlingStyling$bn._(_root);
	@override late final _Translations$mpvConfig$bn mpvConfig = _Translations$mpvConfig$bn._(_root);
	@override late final _Translations$dialog$bn dialog = _Translations$dialog$bn._(_root);
	@override late final _Translations$profiles$bn profiles = _Translations$profiles$bn._(_root);
	@override late final _Translations$connections$bn connections = _Translations$connections$bn._(_root);
	@override late final _Translations$accountPreferences$bn accountPreferences = _Translations$accountPreferences$bn._(_root);
	@override late final _Translations$discover$bn discover = _Translations$discover$bn._(_root);
	@override late final _Translations$errors$bn errors = _Translations$errors$bn._(_root);
	@override late final _Translations$libraries$bn libraries = _Translations$libraries$bn._(_root);
	@override late final _Translations$about$bn about = _Translations$about$bn._(_root);
	@override late final _Translations$serverSelection$bn serverSelection = _Translations$serverSelection$bn._(_root);
	@override late final _Translations$hubDetail$bn hubDetail = _Translations$hubDetail$bn._(_root);
	@override late final _Translations$logs$bn logs = _Translations$logs$bn._(_root);
	@override late final _Translations$startup$bn startup = _Translations$startup$bn._(_root);
	@override late final _Translations$licenses$bn licenses = _Translations$licenses$bn._(_root);
	@override late final _Translations$navigation$bn navigation = _Translations$navigation$bn._(_root);
	@override late final _Translations$explore$bn explore = _Translations$explore$bn._(_root);
	@override late final _Translations$liveTv$bn liveTv = _Translations$liveTv$bn._(_root);
	@override late final _Translations$collections$bn collections = _Translations$collections$bn._(_root);
	@override late final _Translations$playlists$bn playlists = _Translations$playlists$bn._(_root);
	@override late final _Translations$music$bn music = _Translations$music$bn._(_root);
	@override late final _Translations$watchTogether$bn watchTogether = _Translations$watchTogether$bn._(_root);
	@override late final _Translations$downloads$bn downloads = _Translations$downloads$bn._(_root);
	@override late final _Translations$shaders$bn shaders = _Translations$shaders$bn._(_root);
	@override late final _Translations$companionRemote$bn companionRemote = _Translations$companionRemote$bn._(_root);
	@override late final _Translations$videoSettings$bn videoSettings = _Translations$videoSettings$bn._(_root);
	@override late final _Translations$performanceOverlay$bn performanceOverlay = _Translations$performanceOverlay$bn._(_root);
	@override late final _Translations$externalPlayer$bn externalPlayer = _Translations$externalPlayer$bn._(_root);
	@override late final _Translations$metadataEdit$bn metadataEdit = _Translations$metadataEdit$bn._(_root);
	@override late final _Translations$matchScreen$bn matchScreen = _Translations$matchScreen$bn._(_root);
	@override late final _Translations$serverTasks$bn serverTasks = _Translations$serverTasks$bn._(_root);
	@override late final _Translations$trakt$bn trakt = _Translations$trakt$bn._(_root);
	@override late final _Translations$seerr$bn seerr = _Translations$seerr$bn._(_root);
	@override late final _Translations$services$bn services = _Translations$services$bn._(_root);
	@override late final _Translations$addServer$bn addServer = _Translations$addServer$bn._(_root);
	@override late final _Translations$cast$bn cast = _Translations$cast$bn._(_root);
	@override late final _Translations$automation$bn automation = _Translations$automation$bn._(_root);
	@override late final _Translations$notifications$bn notifications = _Translations$notifications$bn._(_root);
	@override late final _Translations$appAccess$bn appAccess = _Translations$appAccess$bn._(_root);
	@override late final _Translations$detail$bn detail = _Translations$detail$bn._(_root);
	@override late final _Translations$watchLink$bn watchLink = _Translations$watchLink$bn._(_root);
	@override late final _Translations$homeLayout$bn homeLayout = _Translations$homeLayout$bn._(_root);
	@override late final _Translations$platform$bn platform = _Translations$platform$bn._(_root);
	@override late final _Translations$universalMedia$bn universalMedia = _Translations$universalMedia$bn._(_root);
	@override late final _Translations$fileSources$bn fileSources = _Translations$fileSources$bn._(_root);
	@override late final _Translations$lending$bn lending = _Translations$lending$bn._(_root);
	@override late final _Translations$audiobook$bn audiobook = _Translations$audiobook$bn._(_root);
	@override late final _Translations$sourceSetup$bn sourceSetup = _Translations$sourceSetup$bn._(_root);
	@override late final _Translations$comics$bn comics = _Translations$comics$bn._(_root);
	@override late final _Translations$games$bn games = _Translations$games$bn._(_root);
	@override late final _Translations$deepLinks$bn deepLinks = _Translations$deepLinks$bn._(_root);
}

// Path: app
class _Translations$app$bn extends Translations$app$en {
	_Translations$app$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: appIcon
class _Translations$appIcon$bn extends Translations$appIcon$en {
	_Translations$appIcon$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'আইকোন আইকোন';
	@override String get defaultIcon => 'প্রত্যাশিত';
	@override String get current => 'বর্তমান আইকোন';
	@override String get locked => 'জীবনযাপন প্রয়োজনীয়';
	@override String get lockedHint => 'আপনার 7 দিনের পরীক্ষা শুরু করুন অথবা বিকল্প আইকোনগুলি ব্যবহার করার জন্য PlezyNG লাইভের জন্য অলোক করুন।';
	@override String get changeFailed => 'অ্যাপ আইকন পরিবর্তন করতে পারবেন না';
	@override String get launcherHint => 'নতুন আইকন আপনার বাড়ি স্ক্রিনে প্রদর্শিত হবে একবার আপনি PlezyNG ছেড়ে যান।';
	@override String get tvLauncherHint => 'নতুন ব্যানারটি আপনাকে PlezyNG ছেড়ে দেওয়ার পর দেখা যায়। Android TV টেলিভিশন আবার শুরু হওয়ার পর্যন্ত পুরনো ব্যানারটি প্রদর্শন করতে পারবেন।';
	@override late final _Translations$appIcon$names$bn names = _Translations$appIcon$names$bn._(_root);
	@override String get description => 'আপনার ডিভাইসের লঞ্চারে কোন আইকন দেখানো হবে তা বেছে নিন। প্রিভিউতে প্রতিটি বিকল্প কেমন দেখায় তা দেখতে পারবেন।';
}

// Path: auth
class _Translations$auth$bn extends Translations$auth$en {
	_Translations$auth$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'সাইন আপ করুন Plex';
	@override String get showQRCode => 'QR কোড দেখুন';
	@override String get authenticate => 'সত্যতা';
	@override String get authenticationTimeout => 'সনাক্তকরণ সময়সীমা শেষ, আবারও চেষ্টা করুন।';
	@override String get scanQRToSignIn => 'এই QR কোডটি স্ক্যান করুন';
	@override String get waitingForAuth => 'সনাক্তকরণের জন্য অপেক্ষায়... আপনার ব্রাউজার থেকে সাইন আপ করুন।';
	@override String get useBrowser => 'ব্রাউজার ব্যবহার';
	@override String get or => 'অথবা';
	@override String connectToMediaBrowser({required Object product}) => 'সংযোগ ${product}';
	@override String get quickConnect => 'Quick Connect';
	@override String get useQuickConnect => 'কুইক কানেক্ট ব্যবহার করুন';
	@override String get quickConnectInstructions => 'Jellyfin এর পৃষ্ঠায় Quick Connect খোলা এবং এই কোডটি প্রদান করুন।';
	@override String get quickConnectWaiting => 'অনুমোদনের জন্য অপেক্ষা...';
	@override String get quickConnectCancel => 'বাতিল';
	@override String get quickConnectExpired => 'দ্রুত সংযোগের মেয়াদ শেষ হয়েছে। আবার চেষ্টা করুন।';
	@override String get localDataRecoveryRequired => 'PlezyNG স্থানীয় সাইন-ইনের তথ্য ও অপেক্ষমাণ প্লেব্যাকের তথ্য নিরাপদে পুনরুদ্ধার করতে পারেনি। আবার সাইন ইন করুন।';
	@override String get pinCheckRejected => 'Plex PIN চেক বাতিল করা হয়েছে';
	@override String get connectToDirectPlex => 'স্থানীয় সার্ভার Plex এর সাথে সংযোগ';
}

// Path: common
class _Translations$common$bn extends Translations$common$en {
	_Translations$common$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'বাতিল';
	@override String get save => 'সুরক্ষা';
	@override String get close => 'বন্ধ';
	@override String get closeMiniPlayer => 'মিনি খেলোয়াড়';
	@override String get closeWorkspaceWindow => 'দীর্ঘ উইন্ডো';
	@override String get returnToFullView => 'পুরো দৃষ্টিতে ফিরে আসুন';
	@override String get manageMediaSessions => 'মিডিয়া সেশন পরিচালনা';
	@override String get hideMediaSessions => 'গণমাধ্যম সন্ধান';
	@override String get mediaSessions => 'মিডিয়া সিনেমা';
	@override String get mediaSessionsHint => 'পার্ক তার উইন্ডোকে লুকিয়ে রাখে কিন্তু এটি খুলে রাখে. ফেরত পুরো ভিউতে এটি খুলবে; নীচে এটি শেষ করে।';
	@override String get sessionInWorkspace => 'কর্মস্থানে';
	@override String get sessionParked => 'পার্কিং';
	@override String get sessionFullscreen => 'পুরো স্ক্রিন';
	@override String get switchToNextWindow => 'Next উইন্ডোজের সাথে বিনিময় করুন';
	@override String get moveWindow => 'বাইরের ভ্রমণ';
	@override String get finishMovingWindow => 'ফাইনাল ভ্রমণ উইন্ডো';
	@override String get moveWindowHint => 'দীর্ঘ চাপ করুন এবং ফাঁকটি এগিয়ে রাখুন. এই নিয়ন্ত্রন প্ল্যান-চিঠি গতিও অনুমোদিত করে।';
	@override String get movingWindowHelp => 'সরাতে টেনে আনুন · তীর কীগুলো দিয়ে সামঞ্জস্য করুন · Enter সংরক্ষণ করে · Escape বাতিল করে';
	@override String get resizeWindow => 'পুনরাবৃত্তি উইন্ডো';
	@override String get resizeWindowHint => 'এই হ্যান্ডেলটি চাপ করুন বা ফাঁসের পুনরাবৃত্তি করার জন্য পাখি খোলাগুলি ব্যবহার করুন।';
	@override String get workspaceWindowHint => 'গাড়ি নিয়ন্ত্রণ বা দীর্ঘ চাপ ব্যবহার করুন এবং গাড়ির জন্য ড্রাইভ করুন।';
	@override String get workspacePaneHint => 'ফোকাস করতে এই প্যানেলটি নির্বাচন করুন। বড় করতে এর ফুলস্ক্রিন নিয়ন্ত্রণ ব্যবহার করুন।';
	@override String workspaceWindowLabel({required Object title}) => 'সেশন উইন্ডো: ${title}';
	@override String get workspaceTitleHint => 'ফোকাস করতে নির্বাচন করুন। সরাতে শিরোনাম বার টেনে ধরুন; বড় করতে ফুলস্ক্রিন বোতাম ব্যবহার করুন।';
	@override String get moveToSessionTray => 'সিনিয়াম ট্রাই';
	@override String get moveToSessionTrayHint => 'এই সেশনটি তার উইন্ডো দেখানোর জন্য উপলব্ধ নয়।';
	@override String get closeSessionHint => 'এই উইন্ডোটি বন্ধ করুন এবং তার সেশন শেষ হবে।';
	@override String get sideBySideLayout => 'Side-by-side layout এর জন্য সুইচ';
	@override String get floatingWindows => 'উইন্ডোজ ফ্লাইট করার জন্য সুইচ';
	@override String get clear => 'স্পষ্ট';
	@override String get reset => 'পুনরাবৃত্তি';
	@override String get later => 'পরে';
	@override String get submit => 'জমা দিন';
	@override String get confirm => 'নিশ্চিত করুন';
	@override String get retry => 'ফেরত';
	@override String get logout => 'ডাউনলোড করুন';
	@override String get unknown => 'অজানা';
	@override String get refresh => 'ফ্রিজ করুন';
	@override String get yes => 'হ্যাঁ';
	@override String get no => 'না';
	@override String get delete => 'মুছে ফেলুন';
	@override String get edit => 'এডিট';
	@override String get shuffle => 'এলোমেলোভাবে চালান';
	@override String get addTo => 'যোগ করুন...';
	@override String get createNew => 'নতুন তৈরি করুন';
	@override String get connect => 'কানেক্ট';
	@override String get disconnect => 'ডিসকানেক্ট';
	@override String get play => 'চালান';
	@override String get pause => 'বিরতি';
	@override String get resume => 'আবার চালান';
	@override String get error => 'ভুল';
	@override String get search => 'অনুসন্ধান';
	@override String get home => 'বাড়ি';
	@override String get back => 'অনগ্রসর';
	@override String get settings => 'সিস্টেম';
	@override String get mute => 'মুটি';
	@override String get ok => 'আচ্ছা';
	@override String get off => 'বন্ধ';
	@override String get options => 'অপশন';
	@override String seasonNumber({required Object number}) => 'সপ্তাহ ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'আয়াত ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'পৃষ্ঠা ${number}';
	@override String get reconnect => 'আবার সংযোগ';
	@override String get viewAll => 'দেখুন সব';
	@override String get checkingNetwork => 'নেটওয়ার্ক চেক...';
	@override String get loadingServers => 'লোডিং সার্ভার...';
	@override String get connectingToServers => 'সার্ভারদের সাথে সংযোগ...';
	@override String get startingOfflineMode => 'অফলফোন মডিও শুরু...';
	@override String get loading => 'লোডিং...';
	@override String get fullscreen => 'ফুলস্ক্রিন';
	@override String get exitFullscreen => 'পুরো স্ক্রিনের বাইরে';
	@override String get pressBackAgainToExit => 'ফেরত ফিরে চাপ করুন';
	@override late final _Translations$common$ratingSource$bn ratingSource = _Translations$common$ratingSource$bn._(_root);
	@override String get notAvailable => 'ন/এ';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
	@override late final _Translations$common$mediaKind$bn mediaKind = _Translations$common$mediaKind$bn._(_root);
}

// Path: screens
class _Translations$screens$bn extends Translations$screens$en {
	_Translations$screens$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'লাইসেন্স';
	@override String get switchProfile => 'সুইচ প্রোফাইল';
	@override String get subtitleStyling => 'Subtitle স্টাইলিং';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'লগ';
}

// Path: update
class _Translations$update$bn extends Translations$update$en {
	_Translations$update$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get available => 'আপডেট পাওয়া যায়';
	@override String versionAvailable({required Object version}) => 'সংস্করণ ${version} পাওয়া যায়';
	@override String currentVersion({required Object version}) => 'বর্তমান: ${version}';
	@override String get skipVersion => 'এই সংস্করণ থেকে বের করুন';
	@override String get viewRelease => 'দেখুন Release';
	@override String get latestVersion => 'আপনি সর্বশেষ সংস্করণে আছেন';
	@override String get checkFailed => 'আপডেটের জন্য চেক করতে পারিনি';
}

// Path: settings
class _Translations$settings$bn extends Translations$settings$en {
	_Translations$settings$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'সিস্টেম';
	@override String get supportDeveloper => 'সমর্থন PlezyNG';
	@override String get supportDeveloperDescription => 'উন্নয়নকে সহায়তা দেওয়ার জন্য';
	@override String get lifetimeAccess => 'PlezyNG জীবনের অ্যাক্সেস';
	@override String get language => 'ভাষা';
	@override String get theme => 'বিষয়';
	@override String get appearance => 'প্রদর্শন';
	@override String get detailPage => 'বিস্তারিত পাতা';
	@override String get themeSongsEnabled => 'গান খেলতে থেম';
	@override String get themeSongsEnabledDescription => 'মিডিয়া ডেটা দেখার সময় উপলব্ধ থিম গান খেলুন।';
	@override String get themeSongVolume => 'Song Volume গান';
	@override String get videoPlayback => 'ভিডিও Playback';
	@override String get videoPlaybackDescription => 'Playback অনুভূতি নির্ধারণ করুন';
	@override String get advanced => 'উন্নত';
	@override String get episodePosterMode => 'পোস্টার স্টাইল';
	@override String get seriesPoster => 'সিরিজ পোস্টার';
	@override String get seasonPoster => 'সপ্তাহের পোস্টার';
	@override String get episodeThumbnail => 'টম্বা';
	@override String get showHeroSectionDescription => 'বাড়ি স্ক্রিনে ক্যারুসেল প্রদর্শন';
	@override String get secondsLabel => 'সেকেন্ড';
	@override String get minutesLabel => 'মিনিট';
	@override String get secondsShort => 'স';
	@override String get minutesShort => 'ম';
	@override String durationHint({required Object min, required Object max}) => 'একটি মূল্য লিখুন (${min}-${max})';
	@override String get systemTheme => 'সিস্টেম';
	@override String get lightTheme => 'আলো';
	@override String get darkTheme => 'অন্ধকার';
	@override String get oledTheme => 'OLED';
	@override String get emberTheme => 'মানুষ';
	@override String get glacierTheme => 'গ্রীষ্ম';
	@override String get forestTheme => 'গাছ';
	@override String get plumTheme => 'প্লাম';
	@override String get paperTheme => 'কাবার';
	@override String get libraryDensity => 'লাইব্রেরি গভীরতা';
	@override String get displayScale => 'ডিজেল স্কুল';
	@override String get compact => 'কম্প্যাক্ট';
	@override String get comfortable => 'সুবিধা';
	@override String get gridSpacing => 'গ্রিড স্পেসিং';
	@override String get gridSpacingTight => 'টাইট';
	@override String get gridSpacingNormal => 'স্বাভাবিক';
	@override String get gridSpacingSpacious => 'জায়গা';
	@override String get tvCornerSpotlightBackdrop => 'কোরন স্পটলাইট ফ্যাকেট';
	@override String get tvCornerSpotlightBackdropDescription => 'স্ক্রিন পূরণের পরিবর্তে সঠিক দিকে চিত্রকর্ম প্রদর্শন';
	@override String get viewMode => 'মডিও দেখুন';
	@override String get gridView => 'গ্রিড';
	@override String get listView => 'তালিকা';
	@override String get showHeroSection => 'হেরো বিভাগ দেখুন';
	@override String get showHomeBackdrop => 'Home Backdrop শিল্প প্রদর্শন';
	@override String get showHomeBackdropDescription => 'বাড়ির পিছনে বড় শিল্পকর্ম দেখুন';
	@override String get contentScreensaverEnabled => 'স্ক্রিন সার্ভার';
	@override String get contentScreensaverEnabledDescription => 'অ্যাপটি অদ্ভুত হয়ে গেল পরে পুরো স্ক্রিনের শিল্প কাজ দেখুন';
	@override String get contentScreensaverDelay => 'স্ক্রিন সার্ভার শুরু';
	@override String get contentScreensaverLibraries => 'স্ক্রেনসভার লাইব্রেরি';
	@override String get contentScreensaverLibrariesDescription => 'কোন লাইব্রেরি স্ক্রিন সার্ভার শিল্পকর্ম সরবরাহ করে তা নির্বাচন করুন. যদি কোনটি নির্বাচন করা হয় না, তাহলে সব লাইব্রেরি থেকে শিল্পকর্ম ব্যবহার করা হয়।';
	@override String get contentScreensaverAllLibraries => 'সব লাইব্রেরি';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} বিবেকগুলি নির্বাচিত';
	@override String get contentScreensaverNoLibraries => 'কোন সংযুক্ত মিডিয়া লাইব্রেরি পাওয়া যায় না।';
	@override String get contentScreensaverDismissHint => 'কোনও বোতাম বা বাতিল করতে চাপ করুন';
	@override String get newEpisodeNotifications => 'নতুন পরিস্থিতি বিজ্ঞাপন';
	@override String get newEpisodeNotificationsDescription => 'একটি প্রদর্শনে একটি নতুন প্রদর্শন যোগ করা হলে সতর্ক করুন আপনি একটি প্রদর্শন পেয়েছেন. সতর্ক করুন যখন Plezy খোলা হয়.';
	@override String get continueWatchingRowSize => 'Continue reading রানী আকার দেখুন';
	@override String continueWatchingRowSizeValue({required Object label}) => '${label} কার্ড';
	@override String get rowSizeCompact => 'কম্প্যাক্ট';
	@override String get rowSizeStandard => 'স্ট্যান্ডার্ড';
	@override String get rowSizeLarge => 'বড়';
	@override String get continueWatchingAction => 'চলুন আক্রমণ দেখুন';
	@override String get continueWatchingPlay => 'খেলা';
	@override String get continueWatchingDetails => 'খোলা Details';
	@override String get episodeAction => 'আক্রমণ আক্রমণ';
	@override String get episodePlay => 'খেলা';
	@override String get episodeDetails => 'খোলা Details';
	@override String get useGlobalHubs => 'Home Layout ব্যবহার করুন';
	@override String get useGlobalHubsDescription => 'একমাত্র হোম হাবগুলি দেখুন. অন্যথায় লাইব্রেরি পরামর্শগুলি ব্যবহার করুন।';
	@override String get showServerNameOnHubs => 'সার্ভার নাম দেখুন Hubs';
	@override String get showServerNameOnHubsDescription => 'সবসময় হাব টাইমগুলিতে সার্ভার নামগুলি প্রদর্শন করুন।';
	@override String get groupLibrariesByServer => 'সার্ভার দ্বারা গ্রুপ লাইব্রেরি';
	@override String get groupLibrariesByServerDescription => 'প্রতিটি মিডিয়া সার্ভারে গ্রুপ পৃষ্ঠা লাইব্রেরি।';
	@override String get alwaysKeepSidebarOpen => 'সবসময় সাইডবার্ক খোলা রাখুন';
	@override String get alwaysKeepSidebarOpenDescription => 'সাইডবার্ক বিস্তারিত থাকবে এবং সামগ্রী এলাকায় সংশোধন করা হবে';
	@override String get showUnwatchedCount => 'দেখুন অদৃশ্যক কন্টেন্ট';
	@override String get showUnwatchedCountDescription => 'প্রদর্শন অবিশ্বাসিত আয়াতগুলি প্রদর্শন এবং সপ্তাহগুলিতে সংখ্যা';
	@override String get showWatchedIndicators => 'দেখে দেখে দেখে দেখে দেখে দেখে';
	@override String get showWatchedIndicatorsDescription => 'দেখুন দেখানো চলচ্চিত্র, প্রদর্শন এবং epizodes উপর একটি চেকমার্ক';
	@override String get showEpisodeNumberOnCards => 'কার্ডের উপর Episode Number প্রদর্শন';
	@override String get showEpisodeNumberOnCardsDescription => 'প্রদর্শন সপ্তাহ এবং আঞ্চলিক সংখ্যা আঞ্চলিক কার্ডে';
	@override String get showSeasonPostersOnTabs => 'ট্যাবের উপর সপ্তাহের পোস্টার দেখুন';
	@override String get showSeasonPostersOnTabsDescription => 'প্রতিটি সপ্তাহের পোস্টার তার ট্যাগের উপর দেখুন';
	@override String get tvFullCardLayout => 'Full টেলিভিশন কার্ড';
	@override String get tvFullCardLayoutDescription => 'অভিনেতা নামের সাথে ছবি-মাত্র টেলিভিশন কার্ড ব্যবহার করুন';
	@override String get focusGlow => 'ফোকাস Glow';
	@override String get focusGlowDescription => 'ফোর্সিং কার্ডের চারপাশে একটি মধুর আলো ড্রাইভ করুন';
	@override String get visualEffects => 'ভিসুয়াল প্রভাব';
	@override String get visualEffectsAuto => 'অটো';
	@override String get visualEffectsAutoDescription => 'কম ক্ষমতার ডিভাইসগুলিতে স্বয়ংক্রিয়ভাবে প্রভাব কমাতে';
	@override String get visualEffectsFull => 'পূর্ণ';
	@override String get visualEffectsReduced => 'কমেছে';
	@override String get visualEffectsReducedDescription => 'কম অ্যানিমেশন এবং কম সনাক্ততা শিল্প কাজ';
	@override String get hideSpoilers => 'অবিশ্বাস্য অ্যাপিজডের জন্য স্পাইলার লুকানো';
	@override String get hideSpoilersDescription => 'Blur টম্বালাল এবং অদৃশ্যক epizodes জন্য বর্ণনা';
	@override String get playerBackend => 'খেলোয়াড় Backend';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'হার্ডওয়ার্ক ডকোডিং';
	@override String get hardwareDecodingDescription => 'যখন উপলব্ধ হয় তখন হার্ডওয়্যার দ্রুততা ব্যবহার করুন';
	@override String get playbackBuffer => 'Playback বাফার';
	@override String get playbackBufferAuto => 'গাড়ি (প্রদর্শিত )';
	@override String get playbackBufferLarge => 'বড়';
	@override String get playbackBufferExtraLarge => 'সবচেয়ে বড়';
	@override String get playbackBufferDescription => 'অবিশ্বাস্য সংযোগের বিরুদ্ধে আরো বউফার. এছাড়াও বউফার আকার দ্বারা সীমিত।';
	@override String get streamBufferSize => 'বাফার আকার';
	@override String streamBufferSizeValue({required Object size}) => '${size} মবি';
	@override String get streamBufferSizeDescription => 'কত ভিডিও সরাসরি খেলতে আগ্রহে লোড করতে হবে. সার্ভারের নিজস্ব ট্রান্সকোড বাফারে ট্রান্সকোড বন্ধ করে।';
	@override String get streamBufferSizeExoNote => 'Playback বাফার পরিবর্তন করে, অ্যাপের মেমরি সীমাবদ্ধির অর্ধেকে ক্যাপিত';
	@override String get streamBufferMegabytes => 'মেগাবাইট';
	@override String get defaultQualityTitle => 'ভুল মান';
	@override String get cellularQualityTitle => 'সেলের মানের ভুল';
	@override String get remoteQualityTitle => 'দূরবর্তী স্রিমিং মান';
	@override String get remoteQualitySameAsDefault => 'ডিফল্ট মানের মতোই';
	@override String get cellularQualitySameAsDefault => 'ডিফল্ট মানের মতোই';
	@override String get directPlayCoveredQuality => 'মূল মানে ছোট ভিডিও খেলুন';
	@override String get directPlayCoveredQualityDescription => 'সরাসরি ভিডিওগুলি সরাসরি কডিং করার পরিবর্তে মানের সীমাবদ্ধির ভেতরে ইতিমধ্যে খেলা';
	@override String get videoCodecs => 'ভিডিও কোডেক';
	@override String get videoCodecsDescription => 'সার্ভার দ্বারা অচেক করা কোডেকগুলি ট্রান্সকড করা হয়';
	@override String get videoCodecsAlwaysAccepted => 'সবসময় গ্রহণ';
	@override String get musicQualityTitle => 'গানের মান';
	@override String get subtitleStyling => 'Subtitle স্টাইলিং';
	@override String get subtitleStylingDescription => 'Subtitle অনুভূতি অনুভূতি';
	@override String get smallSkipDuration => 'ছোট স্কিপ দীর্ঘদিন';
	@override String get largeSkipDuration => 'দীর্ঘ স্কাইপ';
	@override String get rewindOnResume => 'সুনির্দিষ্ট সমাধান';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(seconds,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} সেকেন্ড',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} সেকেন্ড',
	);
	@override String get defaultSleepTimer => 'ডিফল্ট ঘুম টাইম';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(minutes,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} মিনিট',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} মিনিট',
	);
	@override String get rememberTrackSelections => 'সিনেমা / সিনেমা / সিনেমা / সিনেমা / সিনেমা';
	@override String get chooseTracksBeforePlayback => 'Playback এর আগে অডিও এবং সাব্টিটিস নির্বাচন করুন';
	@override String get chooseTracksBeforePlaybackDescription => 'প্রত্যেক ভিডিও শুরু করার আগে উৎস অডিও এবং সাব্টিট ট্র্যাক নির্বাচন করুন।';
	@override String get alwaysShowSubtitlesOnDevice => 'সবসময় এই ডিভাইসের উপর সাব্টিটি প্রদর্শন করুন';
	@override String get alwaysShowSubtitlesOnDeviceDescription => 'যখন সার্ভারের কোন সাব্টিটি নির্বাচন করা হয় না, তখন স্থানীয়ভাবে একটি পাসপোর্ট নির্বাচন করুন. এই কখনো সার্ভারের প্রিয়তা পরিবর্তন করে না।';
	@override String get autoDownloadPreferredSubtitle => 'পছন্দের ভাষা-পছন্দের ভাষা-পছন্দের ভাষা';
	@override String get autoDownloadPreferredSubtitleDescription => 'আপনার প্রিয় ভাষায় স্থানীয়ভাবে একটি উপ-টাইটিল নির্বাচন করুন. যদি কোনটি নেই, তাহলে সার্ভারকে সমর্থিত হলে একটি ফিট করার জন্য অনুরোধ করুন. নির্বাচন এই ডিভাইসে থাকবে.';
	@override String get rememberTrackSelectionsDescription => 'এই ডিভাইসে সিনেমা বা প্রদর্শন দ্বারা অডিও এবং সাবট্রেট নির্বাচন সংরক্ষণ করুন';
	@override String get rememberTrackSelectionsBackendRule => 'স্থানীয়ভাবে Plex, Jellyfin, এবং Emby; Plex এবং Jellyfin এর সাথে কাজ করে, সার্ভারে নির্বাচন সংরক্ষণ করতে পারেন';
	@override String get followServerTrackSelections => 'সার্ভারের পৃথিবীর পৃথিবীর পৃথিবীর পৃথিবীর পৃথিবীর পৃথিবীর পছন্দ';
	@override String get followServerTrackSelectionsDescription => 'epizode change এরপর, সার্ভার উপর নির্বাচিত অডিও এবং সাবটাইটলগুলি প্রয়োগ করুন, বর্তমান পছন্দের উপর বহন করার পরিবর্তে';
	@override String get resumeMusicOnLaunch => 'সিনেমা সিনেমা সিনেমা';
	@override String get resumeMusicOnLaunchDescription => 'শেষ গানটি পুনরায় খোলা যায় যেখানে এটি অ্যাপটি শুরু করার সময় বন্ধ হয়ে যায়';
	@override String get showChapterMarkersOnTimeline => 'পৃথিবী পৃথিবী পৃথিবী পৃথিবী পৃথিবী পৃথিবী পৃথিবী পৃথিবী';
	@override String get showChapterMarkersOnTimelineDescription => 'চিঠির সীমানাগুলিতে চিঠির সীমানাগুলিতে চিঠির সীমানা';
	@override String get specialsOrdering => 'আয়াত আদেশে বিশেষ';
	@override String get specialsOrderingDescription => 'কোথায় বিশেষ খেলছে একটি প্রদর্শনের ঘড়ি আদেশে';
	@override String get specialsOrderingServer => 'সার্ভার আদেশ অনুসরণ';
	@override String get specialsOrderingAirDate => 'বিমানের ডেটা অনুযায়ী';
	@override String get specialsOrderingLast => 'নিয়মিত পরিস্থিতিতে';
	@override String get clickVideoTogglesPlayback => 'ভিডিও ক্লিক করুন খেলতে / পাস করতে';
	@override String get clickVideoTogglesPlaybackDescription => 'ভিডিওটি ক্লিক করুন/পাস করার পরিবর্তে নিয়ন্ত্রণ দেখান।';
	@override String get videoPlayerControls => 'ভিডিও খেলোয়াড় নিয়ন্ত্রণ';
	@override String get keyboardShortcuts => 'ট্যাবলেট Shortcuts';
	@override String get keyboardShortcutsDescription => 'কাস্টমাইজ করুন ট্যাবলেট কুরআন';
	@override String get videoPlayerNavigation => 'ভিডিও খেলোয়াড় নৌকা';
	@override String get videoPlayerNavigationDescription => 'ভিডিও খেলোয়াড় নিয়ন্ত্রনগুলি নৌকা করার জন্য প্লাইট ক্লিক ব্যবহার করুন';
	@override String get watchTogetherRelay => 'একসাথে রেলি দেখুন';
	@override String get watchTogetherRelayDescription => 'খোলা খোলা খোলা খোলা খোলা খোলা খোলা খোলা খোলা খোলা খোলা';
	@override String get watchTogetherRelayHint => 'https://my-relay.example.com';
	@override String get watchTogetherRelayInvalid => 'রিলের জন্য একটি বৈধ HTTP বা HTTPS বেস URL লিখুন।';
	@override String get crashReporting => 'দুর্ঘটনা রিপোর্ট';
	@override String get crashReportingDescription => 'অ্যাপটি উন্নত করতে সাহায্য করার জন্য দুর্ঘটনা রিপোর্ট পাঠান';
	@override String get debugLogging => 'ডেবুগ লগিং';
	@override String get debugLoggingDescription => 'সমস্যা সমাধানের জন্য বিস্তারিত লগিং সক্ষম';
	@override String get viewLogs => 'দেখুন লগ';
	@override String get viewLogsDescription => 'প্রোগ্রামের লগ দেখুন';
	@override String get clearImageCache => 'সঠিক ছবি Cache';
	@override String get clearImageCacheDescription => 'চিহ্নিত ক্যাচিং শিল্প এবং ছোট ছবির. ছবিগুলি আবার ডাউনলোড করা পর্যন্ত দ্রুত লোড করা যেতে পারে।';
	@override String get clearImageCacheSuccess => 'Image Cache সফলভাবে পরিষ্কার';
	@override String get resetSettings => 'পুনরাবৃত্তি Settings';
	@override String get resetSettingsDescription => 'ডিফল্ট সিস্টেমগুলি পুনরায় রাখুন. এটি অস্বীকার করা যাবে না।';
	@override String get resetSettingsSuccess => 'সফলভাবে পুনরাবৃত্তি';
	@override String get backup => 'সাবস্ক্রিপ';
	@override String get exportSettings => 'বিতরণের পরিসংখ্যান';
	@override String get exportSettingsDescription => 'একটি ফাইলের জন্য আপনার পছন্দ সংরক্ষণ করুন';
	@override String get exportSettingsSuccess => 'নির্দেশনা বিতরণ';
	@override String get importSettings => 'Import Settings প্রদর্শন';
	@override String get importSettingsDescription => 'একটি ফাইল থেকে পছন্দ ফেরত';
	@override String get importSettingsConfirm => 'এটাই আপনাকে বর্তমান পরামর্শগুলি বদলে দেবে।';
	@override String get importSettingsSuccess => 'আউটডোজ করা';
	@override String get importSettingsInvalidFile => 'এই ফাইলটি একটি সঠিক PlezyNG সেটিংগুলি অ্যাক্সেস নয়';
	@override String get importSettingsNoUser => 'প্রদর্শন করার আগে সাইন করুন';
	@override String get cloudBackup => 'ক্লাউড সার্ভিস';
	@override String get cloudBackupDescription => 'HTTPS-এর মাধ্যমে WebDAV ঠিকানায় বহনযোগ্য সেটিংসের ব্যাকআপ রাখুন। সার্ভার সংযোগ ও শংসাপত্র এই ডিভাইসেই থাকবে।';
	@override String get cloudBackupUrl => 'WebDAV JSON ফাইল URL';
	@override String get cloudBackupUsername => 'ব্যবহারকারী নাম';
	@override String get cloudBackupPassword => 'পাসওয়ার্ড';
	@override String get cloudBackupSaved => 'Cloud Backup ডিজিটাল সংরক্ষিত';
	@override String get cloudBackupNow => 'ফিরে আসুন এখন';
	@override String get cloudBackupComplete => 'আপলোড করা Backup Settings';
	@override String get cloudBackupRestore => 'Backup পুনরাবৃত্তি';
	@override String get cloudBackupRestoreConfirm => 'এই ডিভাইসের পোর্টেবল সিস্টেমগুলি সমাধান করবে. চলুন?';
	@override String get cloudBackupRestored => 'Cloud Backup থেকে পুনরাবৃত্তি';
	@override String get shortcutsReset => 'দূতাবাসের জন্য দূতাবাস ফিরে আসুন';
	@override String get resetShortcutsConfirm => 'এটি আপনার কাস্টম কুরআনগুলি ভিত্তিতে বদলে দেবে।';
	@override String get about => 'সম্পর্কে';
	@override String get aboutDescription => 'অ্যাপ তথ্য এবং লাইসেন্স';
	@override String get updates => 'আপডেট';
	@override String get updateAvailable => 'আপডেট পাওয়া যায়';
	@override String get checkForUpdates => 'আপডেট দেখুন';
	@override String get autoCheckUpdatesOnStartup => 'Startup এর আপডেটগুলি স্বয়ংক্রিয়ভাবে চেক করুন';
	@override String get autoCheckUpdatesOnStartupDescription => 'আপডেট চালু করার সময় আপডেট পাওয়া যাবে';
	@override String get validationErrorEnterNumber => 'দয়া করে একটি সঠিক নম্বর প্রদান করুন';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => '${min} এবং ${max} ${unit} এর মধ্যে থাকতে হবে।';
	@override String shortcutAlreadyAssigned({required Object action}) => 'এখনও ${action} এর জন্য নির্দিষ্ট কুরআন';
	@override String shortcutUpdated({required Object action}) => 'ছোট ছোট আপডেট ${action}';
	@override String get saveFailed => 'পরিবর্তন করতে পারবেন না, আবার চেষ্টা করুন।';
	@override String get autoPlayAndSkip => 'অটো-প্লে & স্কিপ';
	@override String get autoPlayNextEpisode => 'Auto-Play পরবর্তী প্রজেক্ট';
	@override String get autoPlayNextEpisodeDescription => 'পরবর্তী অধ্যায়টি স্বয়ংক্রিয়ভাবে শুরু করে যখন একটি শেষ হয়';
	@override String get shuffleStartsFromBeginning => 'শফল শুরু করে';
	@override String get shuffleStartsFromBeginningDescription => 'প্রতিটি অধ্যায় শুরু করার পরিবর্তে শুরু করার সময় শুরু করুন।';
	@override String get plexCinemaPreRoll => 'সার্ভার সিনেমা ইনট্রো ব্যবহার করুন';
	@override String get plexCinemaPreRollDescription => 'একটি চলচ্চিত্র শুরু করার আগে Plex প্রেরো-রল বা Jellyfin এবং Emby প্রেরো-রল সংগঠিত খেলুন।';
	@override String get playNextCountdown => 'পরবর্তী কন্টডাউন খেলা';
	@override String get playNextCountdownImmediate => 'তাড়াতাড়ি খেলুন';
	@override String get skipIntroMode => 'সিন্ট্রো';
	@override String get skipIntroModeOffDescription => 'খেলুন অভিনেতা সাধারণত একটি স্কাইপ বোতাম ছাড়া';
	@override String get skipIntroModeButtonDescription => 'প্রদর্শন করুন একটি স্কাইপ বোতাম যখন একটি intro শুরু হয়';
	@override String get skipIntroModeAutoDescription => 'নীচের দেরি পরে স্বয়ংক্রিয়ভাবে ইনস্ট্রুস স্কিপ করুন';
	@override String get skipCreditsMode => 'ক্রেডিট স্কাইপ';
	@override String get skipCreditsModeOffDescription => 'ক্রেডিট খেলুন স্বাভাবিকভাবে একটি স্কাইপ বোতাম ছাড়া';
	@override String get skipCreditsModeButtonDescription => 'ক্রেডিট শুরু করার সময় একটি স্কাইপ বোতাম দেখুন';
	@override String get skipCreditsModeAutoDescription => 'ক্রেডিটগুলি স্বয়ংক্রিয়ভাবে বের করুন এবং পরবর্তী অধ্যায় খেলুন';
	@override String get skipAdsMode => 'হাঁটান Ads';
	@override String get skipAdsModeOffDescription => 'একটি স্কাইপ বোতাম ছাড়া স্বাভাবিকভাবে প্রদর্শিত বিজ্ঞাপন খেলুন';
	@override String get skipAdsModeButtonDescription => 'একটি বিজ্ঞাপন দেখান যখন Plex একটি বিজ্ঞাপন দেখান';
	@override String get skipAdsModeAutoDescription => 'নিচের দুর্বলতা পরে স্বয়ংক্রিয়ভাবে প্রদর্শন করা বিজ্ঞাপনগুলি বের করুন';
	@override String get musicPlayback => 'গান Playback';
	@override String get musicSweetFades => 'সুতরাং ফ্যাড';
	@override String get musicSweetFadesDescription => 'ফ্যাড সঙ্গীত ট্র্যাক এগিয়ে যখন Plex এর শব্দ ডেটা আছে।';
	@override String get skipMarkerModeOff => 'বন্ধ';
	@override String get skipMarkerModeButton => 'বোতাম দেখুন';
	@override String get skipMarkerModeAuto => 'স্বয়ংক্রিয়';
	@override String get forceSkipMarkerFallback => 'ফ্যালব্যাক মার্কেট';
	@override String get forceSkipMarkerFallbackDescription => 'পৃথিবীর টাইম প্যাটার্ন ব্যবহার করুন, এমনকি যদি Plex প্যাকেজ আছে';
	@override String get theIntroDbFallback => 'intro fallback হিসাবে ব্যবহার করুন';
	@override String get theIntroDbFallbackDescription => 'সম্প্রদায় সময়সীমাগুলি শুধুমাত্র ব্যবহার করুন যখন সার্ভারে intro markers নেই. Matchs can vary by release.';
	@override String get autoSkipDelay => 'গাড়ি দেরি';
	@override String autoSkipDelayDescription({required Object seconds}) => 'অপেক্ষা করুন ${seconds} সেকেন্ড আগে গাড়ি-সিকপিং';
	@override String get introPattern => 'ইন্ট্রো মার্কেট প্যাটার্ন';
	@override String get introPatternDescription => 'Regex মডেল চিঠির টাইমগুলিতে intro markers সঙ্গে জড়িত';
	@override String get creditsPattern => 'ক্রেডিট মার্কেট প্যাটার্ন';
	@override String get creditsPatternDescription => 'ক্যাপ্টার টাইমগুলিতে ক্রেডিট ম্যাকারগুলি ম্যাকার করার জন্য Regex প্যাটার্ন';
	@override String get prerolls => 'পূর্বাভাস';
	@override String get playPrerollsBeforeMovies => 'চলচ্চিত্রের আগে প্রেরোল খেলুন';
	@override String get playPrerollsBeforeMoviesDescription => 'প্রতিটি চলচ্চিত্রের আগে আপনার নিচের নির্বাচন থেকে একটি random ক্লিপ খেলুন।';
	@override String get prerollLibrary => 'প্রেরোল লাইব্রেরি';
	@override String get prerollLibraryNotSet => 'সিস্টেম না';
	@override String get prerollLibraryNoneFound => 'আপনার সার্ভারগুলিতে কোন লাইব্রেরি পাওয়া যায় না।';
	@override String get prerollSelection => 'নির্বাচিত প্রেরোল';
	@override String get prerollSelectionPickLibraryFirst => 'প্রথমে একটি লাইব্রেরি নির্বাচন করুন';
	@override String get prerollSelectionNoneSelected => 'কোন প্রেরোল নির্বাচন হয় না';
	@override String prerollSelectionCount({required Object count}) => '${count} নির্বাচিত';
	@override String get prerollItemPicker => 'প্রেরোলস নির্বাচন';
	@override String get prerollItemPickerLoadFailed => 'এই লাইব্রেরি থেকে পণ্য লোড করতে পারেনি।';
	@override String get invalidRegex => 'নিয়মিত বক্তব্যের অভাব';
	@override String get regex => 'নিয়মিত বক্তব্য';
	@override String get downloads => 'ডাউনলোড';
	@override String get downloadLocationDescription => 'ডাউনলোড করা বিষয়বস্তু সংরক্ষণ করার কোথায় নির্বাচন করুন';
	@override String get downloadLocationDefault => 'অ্যাপ স্টোরেজ (App Storage)';
	@override String get downloadLocationCustom => 'কাস্টম অবস্থান';
	@override String get selectFolder => 'ফোল্ডার নির্বাচন';
	@override String get resetToDefault => 'ডিফল্টে ফিরে আসুন';
	@override String currentPath({required Object path}) => 'বর্তমান: ${path}';
	@override String get downloadLocationChanged => 'ডাউনলোড স্থান পরিবর্তন';
	@override String get downloadLocationReset => 'ডাউনলোড করুন অবস্থান reset to default';
	@override String get downloadLocationInvalid => 'নির্বাচিত ফোলার লিখতে পারে না';
	@override String get downloadLocationPickerUnavailable => 'ফোল্ডার নির্বাচন এই ডিভাইসে পাওয়া যায় না';
	@override String get downloadOnWifiOnly => 'ডাউনলোড করুন Wi-Fi কেবল';
	@override String get downloadOnWifiOnlyDescription => 'মোবাইল ডেটাতে ডাউনলোড বন্ধ করুন';
	@override String get autoRemoveWatchedDownloads => 'Auto-Remove দেখানো ডাউনলোড';
	@override String get autoRemoveWatchedDownloadsDescription => 'স্বয়ংক্রিয়ভাবে দেখানো ডাউনলোড মুছে ফেলুন';
	@override String get autoDownloadContinueWatching => 'Auto-Download চলুন দেখুন';
	@override String get autoDownloadContinueWatchingDescription => 'আপনার Continue Watch শিলিং পণ্যগুলি ডাউনলোড করে রাখুন এবং তারা শিলিং থেকে বের হওয়ার পরে তাদের মুছে ফেলুন';
	@override String get downloadQuality => 'ডাউনলোড মান';
	@override String get downloadQualityDescription => 'Plex তার ডাউনলোড কোডে একটি পরিদর্শন কপি তৈরি করে. Jellyfin এবং Emby ফাইল ডাউনলোড করার সময় ট্রান্সকোড; বন্ধ ট্রান্সকোডগুলি পুনরায় চালু করতে হবে।';
	@override String get askDownloadQualityEachTime => 'প্রতিটি ডাউনলোডের জন্য মানের নির্বাচন করুন';
	@override String get askDownloadQualityEachTimeDescription => 'প্রতিটি ভিডিও ডাউনলোড করার আগে মান পিকার দেখুন';
	@override String get cellularDownloadBlocked => 'ডাউনলোডগুলি সেলের উপর ব্লক করা হয়. Wi-Fi ব্যবহার করুন বা সিস্টেম পরিবর্তন করুন.';
	@override String get maxVolume => 'সর্বোচ্চ শব্দের মাত্রা';
	@override String get maxVolumeDescription => 'কম শব্দের মিডিয়ার জন্য শব্দের মাত্রা 100%-এর বেশি বাড়ানোর অনুমতি দিন';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'ধনী উপস্থিতি';
	@override String get discordRichPresenceDescription => 'দেখুন আপনি কি দেখছেন Discord';
	@override String get services => 'পরিষেবা';
	@override String get servicesDescription => 'সংযোগ Trakt, MyAnimeList, Seerr, এবং আরও';
	@override String get manageLibrariesDescription => 'লাইব্রেরি রেকর্ড করুন এবং লুকিয়ে রাখুন';
	@override String get companionRemoteServer => 'Remote সার্ভার';
	@override String get companionRemoteServerDescription => 'আপনার নেটওয়ার্কের মোবাইল ডিভাইসগুলি এই অ্যাপটি নিয়ন্ত্রণ করার অনুমতি দেয়';
	@override String get companionRemoteServerStartFailed => 'সার্ভার সার্ভার শুরু করতে পারেনি।';
	@override String get companionRemoteServerStopFailed => 'সার্ভার বন্ধ করতে পারত না।';
	@override String get autoPip => 'Auto Picture-in-Picture গাড়ি';
	@override String get autoPipDescription => 'আপনি Playback সময় অ্যাপটি ছেড়ে যখন স্বয়ংক্রিয়ভাবে ছবি-এ-ফটো প্রবেশ করুন';
	@override String get matchContentFrameRate => 'ফ্রেম ফ্রেম ফ্রেম ফ্রেম ফ্রেম';
	@override String get matchContentFrameRateDescription => 'ভিডিও প্রদর্শন ফ্রেসিং রেস্টুরেন্ট ফ্রেসিং রেস্টুরেন্ট';
	@override String get matchContentResolution => 'Match Content সংশ্লিষ্ট';
	@override String get matchContentResolutionDescription => 'ভিডিওটির স্বাগত রেজিউশনে ডিভাইস পরিবর্তন করুন ताकि আপনার টিভি উপসকালিং কাজ করে।';
	@override String get matchRefreshRate => 'ফ্রিজ ফ্রিজ ফ্রিজ';
	@override String get matchRefreshRateDescription => 'পুরো স্ক্রিনে ফ্রিজ ফ্রিজ ফ্রিজ ফ্রিজ ফ্রিজ';
	@override String get matchDynamicRange => 'জায়গা জায়গা জায়গা';
	@override String get matchDynamicRangeDescription => 'HDR-এর জন্য ডাউনলোড করুন, তারপর SDR-এর জন্য ফিরে আসুন';
	@override String get displaySwitchDelay => 'ডাউনলোড সুইচ দেরি';
	@override String get tunneledPlayback => 'টনেল Playback';
	@override String get tunneledPlaybackDescription => 'ভিডিও টুনেলিং ব্যবহার করুন. HDR প্লাইবক কালো ভিডিও বা মোট স্টুটার প্রদর্শন করে যদি অ্যাক্সেস করা হয়.';
	@override String get audioPassthrough => 'অডিও পাস্ট্রোগ';
	@override String get audioPassthroughDescription => 'ডলবি / ডিটিএস অডিও আপনার রিপোর্টার বা টেলিভিশনে রেকর্ডিং ছাড়া পাঠান, পরিবেশের শব্দ সংরক্ষণ করুন. শব্দ না হলে বন্ধ করুন.';
	@override String get audioPassthroughDescriptionApple => 'Atmos সহ Dolby Digital Plus-এর জন্য Apple-এর নিজস্ব Dolby ডিকোডার ব্যবহার করুন। DTS ও TrueHD মাল্টিচ্যানেল PCM হিসেবেই চলবে। শব্দ না শুনলে এটি বন্ধ করুন।';
	@override String get audioPassthroughDescriptionAppleSpatial => 'ডলবি ডিজিটাল প্লাস জন্য Apple এর প্রাকৃতিক ডলবি ডকোডার ব্যবহার করুন, অথবা Atmos. iOS, iPadOS এবং tvOS 26 বা তারপর, TrueHD Atmos এবং DTS:X স্পেশাল অডিও হিসাবে খেলতে হবে. অন্যান্য DTS এবং TrueHD ট্র্যাক multichannel PCM হিসাবে খেলতে হবে. আপনি কোন শব্দ না থাকলে বন্ধ করুন.';
	@override String get audioPassthroughOverriddenByNormalization => 'যদিও শব্দের স্বাভাবিকতা থাকে, তখন';
	@override String get audioChannelLimit => 'অডিও চ্যানেল';
	@override String get audioChannelLimitDescription => 'ডাউনলোড করা অডিও মিশ্র করুন শব্দ, হোডফোন, বা HDMI সেটপগুলিতে যা কোনও চ্যানেল খেলতে পারে না';
	@override String get audioChannelLimitOriginal => 'মূল';
	@override String get audioChannelLimitOriginalDescription => 'প্রতিটি চ্যানেলটি ট্র্যাকে খেলুন';
	@override String get audioChannelLimitSurround51 => '5.1 পর্যন্ত';
	@override String get audioChannelLimitSurround51Description => 'মিশ্র 7.1 থেকে 5.1 পর্যন্ত টেলিভিশন এবং রেকর্ডারগুলির জন্য যারা কেবল 5.1 PCM গ্রহণ করে।';
	@override String get audioChannelLimitStereo => 'স্টেরিও';
	@override String get audioChannelLimitStereoDescription => 'স্টেরিও শব্দক বা হোডফোনের জন্য দুটি চ্যানেলের মধ্যে মিশ্রণ করুন।';
	@override String get downmixCenterBoost => 'চ্যানেল বোস্ট';
	@override String downmixCenterBoostValue({required Object db}) => '${db} ডিবি';
	@override String get downmixCenterBoostLabel => 'ডিপি (ডিপি )';
	@override String get downmixCenterBoostShort => 'ডিবি';
	@override String get audioDownmixNormalize => 'ডাউন মিক্সিকায় ভোল্টুম স্বাভাবিক করুন';
	@override String get audioDownmixNormalizeDescription => 'ক্লাইপিং বন্ধ করার জন্য মিশ্রণটি নিচে রাখুন. মূল টুমেন্ট রাখতে বন্ধ করুন (হয়তততততততততততততততততততততততততততততততততততত।';
	@override String get dvConversionMode => 'Dolby Vision সংকট';
	@override String get dvConversionModeDescription => 'Dolby Vision প্রোফাইল 7 ফাইলগুলি কীভাবে পরিচালিত হয় তা নির্বাচন করুন।';
	@override String get dvConversionAuto => 'অটো';
	@override String get dvConversionNative => 'অভ্যন্তরীণ / অভ্যন্তরীণ';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'ডিভাইস ক্ষমতা ডেটাং এবং স্বাভাবিক Fallback আচরণ ব্যবহার';
	@override String get dvConversionNativeDescription => 'শক্তি প্রাকৃতিক DV7 এবং ডিভি পরিদর্শন রিট্রি প্রত্যাহার';
	@override String get dvConversionDv81Description => 'শক্তি ইনলাইন RPU পৃষ্ঠা Dolby Vision প্রোফাইল 8.1';
	@override String get dvConversionHevcStripDescription => 'স্ট্রিপ Dolby Vision RPU/EL layers এবং বর্তমান প্লাইন HEVC';
	@override String get experimentalDolbyVision => 'পরীক্ষামূলক Dolby Vision';
	@override String get experimentalDolbyVisionDescription => 'পরবর্তী প্লেব্যাকে পরীক্ষামূলক FEL রেন্ডারার ব্যবহার করুন। ইঞ্জিনের আলাদা বিল্ড প্রয়োজন।';
	@override String get dvExperimentUnavailableDescription => 'এই পরীক্ষা বর্তমানে শুধু Linux-এ উপলব্ধ।';
	@override String get dvCompatibilityFallback => 'সামঞ্জস্যপূর্ণ বিকল্প';
	@override String get dvCompatibilityFallbackDescription => 'পরীক্ষা শুরু না হলে সাধারণ রেন্ডারার ব্যবহার করুন। FEL তথ্য হারিয়ে যেতে পারে।';
	@override String get dvExperimentDiagnostics => 'ভিডিও পরীক্ষার লগ';
	@override String get dvExperimentDiagnosticsDescription => 'পরবর্তী প্লেব্যাকে প্লেয়ারের বিস্তারিত লগ চালু করুন।';
	@override String get disableDolbyVision => 'অস্বাভাবিক Dolby Vision';
	@override String get disableDolbyVisionDescription => 'ফাইলের HDR10 বা HLG স্তরের পরিবর্তে Dolby Vision খেলুন, যখন এটি একটি আছে';
	@override String get hdrSdrConversion => 'HDR থেকে SDR সংকট';
	@override String get hdrSdrConversionDescription => 'HDR ভিডিও কনভার্ট করে যা নির্বাচন করুন, যখন ডিভাইস HDR দেখতে পারবে না।';
	@override String get hdrSdrConversionAuto => 'অটো';
	@override String get hdrSdrConversionAutoDescription => 'ডিভাইস Android 9 এবং তারপর, পুরনো সংস্করণগুলিতে খেলা';
	@override String get hdrSdrConversionDevice => 'ডিভাইস';
	@override String get hdrSdrConversionDeviceDescription => 'আপনার ডিভাইসের ভিডিও হার্ভিড এটি পরিদর্শন করে. সবচেয়ে দ্রুত, কিন্তু রঙগুলি ডিভাইসের উপর নির্ভর করে';
	@override String get hdrSdrConversionPlayer => 'প্লেয়ার';
	@override String get hdrSdrConversionPlayerDescription => 'খেলোয়াড়টি এটি পরিদর্শন করে. সংশ্লিষ্ট রঙ, কিন্তু 4K নিম্ন ফ্যান্ড টেলিভিশন বক্সগুলিতে লড়াই করতে পারে';
	@override String get deinterlace => 'ডেটিং';
	@override String get deinterlaceDescription => 'interlaced ভিডিও থেকে সংযুক্ত অ্যাকাউন্ট মুছে ফেলুন (mpv খেলোয়াড় কেবল)';
	@override String get deinterlaceOff => 'বন্ধ';
	@override String get deinterlaceOffDescription => 'ডাউনলোড করা হয় যখন এটি ডাউনলোড করা হয়';
	@override String get deinterlaceVideo => 'ভিডিও';
	@override String get deinterlaceVideoDescription => 'প্রত্যেক ফ্যাকেটকে একটি সম্পূর্ণ ফ্যাকেটে পরিদর্শন করুন. টিভি জন্য ভিডিও শটের জন্য, যেমন খেলা, সংবাদ, এবং কনসার্ট';
	@override String get deinterlaceFilm => 'চলচ্চিত্র';
	@override String get deinterlaceFilmDescription => 'চলচ্চিত্র এবং অ্যানিমেশন এর মূল ফ্রেমগুলি 2.97 fps, NTSC ডিভিডিগুলিতে সাধারণ করে ফিরে আসুন. টিভি স্টুটারদের জন্য ভিডিও ফ্রেম।';
	@override String get requireProfileSelectionOnOpen => 'অ্যাপটি খোলা প্রোফাইলের জন্য অনুরোধ';
	@override String get requireProfileSelectionOnOpenDescription => 'প্রোগ্রাম খুললে প্রতিবার প্রোগ্রামের পছন্দ দেখুন';
	@override String get forceTvMode => 'টেলিভিশন মডেল';
	@override String get forceTvModeDescription => 'টেলিভিশন সিস্টেম শক্তিশালী. যেসব ডিভাইসগুলি স্বয়ংক্রিয়ভাবে ডেটিং না করে, তাদের জন্য আবার শুরু করতে হবে।';
	@override String get startInFullscreen => 'পুরো স্ক্রিনে শুরু';
	@override String get startInFullscreenDescription => 'ফুল স্ক্রিন মোডে PlezyNG খোলা';
	@override String get exitFullscreenOnPlayerClose => 'খেলোয়াড় বন্ধে Full Screen Exit';
	@override String get exitFullscreenOnPlayerCloseDescription => 'ভিডিও খেলোয়াড় বন্ধ করার সময় স্বয়ংক্রিয়ভাবে পুরো স্ক্রিন থেকে বের করে';
	@override String get autoHidePerformanceOverlay => 'অটো-হাইড অ্যাপ্লিকেশন Overlay';
	@override String get autoHidePerformanceOverlayDescription => 'Playback নিয়ন্ত্রণে অগ্রগতি ফ্যাড করুন';
	@override String get showNavBarLabels => 'দেখুন ন্যাভাইজেশন বার Labels';
	@override String get showNavBarLabelsDescription => 'নৌকা প্যার আইকোনগুলির মধ্যে টেক্সট লেগেলগুলি দেখুন';
	@override String get startupSection => 'Startup বিভাগ';
	@override String get preferredServer => 'প্রিয় সার্ভার';
	@override String get preferredServerDescription => 'এই সার্ভারের ফলাফলগুলি মূল্যায়ন করুন, যখন প্রতিটি সংযোগিত সার্ভার উপলব্ধ রাখুন।';
	@override String get preferredServerAutomatic => 'স্বয়ংক্রিয়';
	@override String get showExploreTab => 'ট্যাব দেখুন';
	@override String get showExploreTabDescription => 'আবিষ্কারের প্যাকেটি দেখুন Plex থেকে উপাদান সঙ্গে আবিষ্কার এবং সংযুক্ত ট্র্যাকার';
	@override String get hideEmptyLibraries => 'ভুল লাইব্রেরি';
	@override String get hideEmptyLibrariesDescription => 'সার্ভার দ্বারা রিপোর্ট করা পণ্য সংখ্যা সূত্রের সাথে লাইব্রেরিগুলি নৌকা থেকে মুছে ফেলুন।';
	@override String get liveTvDefaultFavorites => 'প্রিয় চ্যানেলগুলির জন্য ডিফল';
	@override String get liveTvDefaultFavoritesDescription => 'শুধুমাত্র প্রিয় চ্যানেলগুলি দেখুন Live TV খুলতে';
	@override String get general => 'সাধারণ';
	@override String get generalDescription => 'ভাষা, স্টার্টপোর্ট এবং উইন্ডো ভেতর';
	@override String get languageAndRegion => 'ভাষা ও অঞ্চল';
	@override String get startup => 'স্টার্টপ';
	@override String get display => 'ডিসপ্লে';
	@override String get libraryAndCards => 'লাইব্রেরি & কার্ড';
	@override String get homeScreen => 'Home স্ক্রিন';
	@override String get navigation => 'নৌকা';
	@override String get window => 'উইন্ডোজ';
	@override String get liveTv => 'লাইভ টিভি';
	@override String get player => 'প্লেয়ার';
	@override String get videoAndDisplay => 'ভিডিও & Display';
	@override String get audio => 'অডিও';
	@override String get quality => 'মানের';
	@override String get subtitles => 'সাবটাইটেল';
	@override String get seekAndTiming => 'সন্ধান & টাইমিং';
	@override String get behavior => 'আচরণ';
	@override String get gestures => 'গ্যাস';
	@override String get gestureBrightnessSwipe => 'সূর্য বিলুপ্ত';
	@override String get gestureBrightnessSwipeDescription => 'বাম দিকে উড়ে বা নিচে বাইরে বাইরে বাইরে বাইরে বাইরে বাইরে বাইরে বাইরে';
	@override String get gestureVolumeSwipe => 'পরিমাণ সুইপ';
	@override String get gestureVolumeSwipeDescription => 'ডান দিকে উড়ে বা নিচের দিকে ঘুরে বের করুন, পরিমাণ সংশোধন করার জন্য';
	@override String get gesturePinchToZoom => 'পিনচ থেকে Zoom';
	@override String get gesturePinchToZoomDescription => 'ভিডিওটিতে জুোম করুন বা ফাঁস করুন।';
	@override String get gestureSeekSwipe => 'সুইপ খুঁজুন';
	@override String get gestureSeekSwipeDescription => 'ভিডিওটি অনুসন্ধানের কোথাও বাম বা ডান বাইরে বাইরে; ফেরত হাঁটতে';
	@override String get rememberBrightnessLevel => 'উজ্জ্বলতা তাপমাত্রা';
	@override String get rememberBrightnessLevelDescription => 'শেষ সুইপ দ্বারা নির্ধারিত উজ্জ্বলতা থেকে playback শুরু করুন';
	@override String get controls => 'নিয়ন্ত্রণ';
	@override String get rememberPlayerChanges => 'খেলোয়াড়ের পরিবর্তন';
	@override String get rememberPlayerChangesDescription => 'যেখানে একটি পরিবর্তন Playback সময় সংরক্ষণ করা হয় এবং আবার প্রয়োগ করা হয়';
	@override String get scopePlaybackSpeed => 'গতি Playback';
	@override String get scopeShaderPreset => 'শারীরিক প্রসেস্ট';
	@override String get scopeAspectRatio => 'এস্পেক্ট রেসিও';
	@override String get scopeSyncOffsets => 'অডিও & Subtitle Sync';
	@override String get playerScopeOff => 'বাঁচান না';
	@override String get playerScopeGlobal => 'যেখানে';
	@override String get playerScopeLibrary => 'লাইব্রেরি থেকে';
	@override String get playerScopeTitle => 'সিনেমা বা সিনেমা';
	@override String get exportDialogTitle => 'উত্পাদন PlezyNG সিস্টেমগুলি';
	@override String get followSystem => 'সিস্টেমের ভাষা অনুসরণ করুন';
	@override String get followAppLanguage => 'ইন্টারফেসের ভাষা ব্যবহার করুন';
	@override String get regionFormat => 'আঞ্চলিক বিন্যাস';
	@override String get regionFormatDescription => 'তারিখ, সংখ্যা ও পরিমাপ কীভাবে দেখানো হবে তা বেছে নিন।';
	@override String get metadataLanguage => 'মিডিয়ার তথ্যের ভাষা';
	@override String get metadataLanguageDescription => 'সার্ভার সমর্থন করলে শিরোনাম ও বিবরণের পছন্দের ভাষা। অডিও ও সাবটাইটেলের পছন্দ আলাদাভাবে নির্ধারিত হয়।';
	@override String get enterFullscreenOnPlaybackStart => 'পুরো স্ক্রিনে প্রবেশ করুন যখন Playback শুরু হয়';
	@override String get enterFullscreenOnPlaybackStartDescription => 'পুরো স্ক্রিনে ডেস্কটপ ভিডিও খুলে যখন Playback শুরু হয়';
	@override String get extendVideoIntoDisplayCutout => 'ভিডিও প্রদর্শন Cutoutতে বিস্তারিত';
	@override String get extendVideoIntoDisplayCutoutDescription => 'Fullscreen ভিডিও অ্যান্ড্রয়েড ফোনগুলিতে ক্যামেরার Cutout ব্যবহার করুন';
	@override String get languageDescription => 'PlezyNG-এর নিয়ন্ত্রণ ও বার্তায় ব্যবহৃত ভাষা বেছে নিন। সিস্টেম অনুসরণ করলে ডিভাইসের ভাষা ব্যবহৃত হবে।';
	@override String get themeDescription => 'প্রোগ্রামটিতে ব্যবহৃত রঙ এবং প্রতিরোধ নির্বাচন করুন।';
	@override String get libraryDensityDescription => 'প্রতিটি লাইব্রেরি কার্ডের সংখ্যা পরিবর্তন করুন।';
	@override String get displayScaleDescription => 'এই গাড়ি ডিভাইসের ইন্টারফেসটি পরিবর্তন না করে আপনার ডিভিশনে টেক্সট মাত্রা পরিবর্তন করুন।';
	@override String get themeSongVolumeDescription => 'অন্যান্য অডিওের সাথে সম্পর্কিত থিম গানগুলির পরিমাণ নির্ধারণ করুন।';
	@override String get viewModeDescription => 'লাইব্রেরি পণ্যগুলি একটি নেটওয়ার্কে পোস্টার হিসাবে বা কম্প্যাক্ট তালিকা হিসেবে প্রদর্শিত হয় কিনা নির্বাচন করুন।';
	@override String get gridViewDescription => 'লাইব্রেরি পণ্যগুলি পোস্টারগুলির তালিকায় এবং পর্যায়ে সংস্থা করুন।';
	@override String get listViewDescription => 'লাইব্রেরি পণ্যগুলি একটি ভার্চিক তালিকাতে প্রদর্শন করুন, প্রতিটি পণ্যের জন্য আরো টেক্সট।';
	@override String get gridSpacingDescription => 'লাইব্রেরি নেটওয়ার্কগুলিতে পোস্টারগুলির মধ্যে দূরত্ব স্থাপন করুন।';
	@override String get gridSpacingTightDescription => 'স্ক্রিনের পৃথিবীতে ছোট ছোঁয়াগুলি দিয়ে আরো পোস্টার উপস্থাপন করুন।';
	@override String get gridSpacingNormalDescription => 'পোস্টারগুলির মধ্যে স্ট্যান্ডার্ড ভাগ ব্যবহার করুন।';
	@override String get gridSpacingSpaciousDescription => 'আরও বিচ্ছিন্নতার জন্য পোস্টারগুলির মধ্যে বৃহত্তম ভেতর যোগ করুন।';
	@override String get episodePosterModeDescription => 'কোন শিল্পকর্মটি কার্ডগুলিতে প্রদর্শন করা হবে তা নির্বাচন করুন।';
	@override String get seriesPosterDescription => 'প্রত্যেক পরিস্থিতিতে সারিজের পোস্টার ব্যবহার করুন।';
	@override String get seasonPosterDescription => 'প্রত্যেক পরিসংখ্যানের জন্য সপ্তাহ পোস্টার ব্যবহার করুন যখন উপলব্ধ।';
	@override String get episodeThumbnailDescription => 'যখন উপলব্ধ হয় তখন একটি ফ্রেম ব্যবহার করুন।';
	@override String get continueWatchingActionDescription => 'আপনি একটি Continue Watching কার্ড সক্রিয় করার সময় কী ঘটবে তা নির্বাচন করুন।';
	@override String get continueWatchingPlayDescription => 'দ্রুত চলচ্চিত্র বা প্রদর্শন শুরু করুন।';
	@override String get continueWatchingDetailsDescription => 'প্রথমে চিঠির পৃষ্ঠা খুলুন যাতে আপনি বিস্তারিত দেখতে এবং একটি পদক্ষেপ নির্বাচন করতে পারেন।';
	@override String get episodeActionDescription => 'আপনি একটি epizode কার্ড সক্রিয় করার সময় কী ঘটবে তা নির্বাচন করুন।';
	@override String get episodePlayDescription => 'অবিলম্বে এই ঘটনাটি শুরু করুন।';
	@override String get episodeDetailsDescription => 'Playback এর আগে পৃষ্ঠাটি খুলুন।';
	@override String get contentScreensaverDelayDescription => 'প্রদর্শন করার আগে অন্তর্ভুক্ত PlezyNG কতদিন অপেক্ষা করে।';
	@override String get continueWatchingRowSizeDescription => 'সিদ্ধান্ত করুন যে কার্ডগুলি কতটা বড় থাকে Continue Watching রানায়।';
	@override String get rowSizeCompactDescription => 'ছোট কার্ডগুলি দেখুন, যাতে আরও পণ্য লাইন সীমাবদ্ধ করে।';
	@override String get rowSizeStandardDescription => 'কার্ডের স্ট্যান্ডার্ড আকার ব্যবহার করুন।';
	@override String get rowSizeLargeDescription => 'আরও বড় কার্ডগুলি দেখুন আরেকটি শিল্পকর্মের বিস্তারিত';
	@override String get visualEffectsDescription => 'এই ডিভাইসের জন্য অ্যানিমেশন এবং শিল্প কার্যকলাপ বাজেট নির্বাচন করুন।';
	@override String get visualEffectsFullDescription => 'প্রতিটি ডিভাইসে সম্পূর্ণ অ্যানিমেশন এবং শিল্প কাজের প্রভাব ব্যবহার করুন।';
	@override String get startupSectionDescription => 'কখন PlezyNG শুরু হয় তাহলে কোন বিভাগটি খুলবে তা নির্বাচন করুন।';
	@override late final _Translations$settings$startupSectionOptions$bn startupSectionOptions = _Translations$settings$startupSectionOptions$bn._(_root);
	@override String get smallSkipDurationDescription => 'দূরত্ব নির্ধারণ করুন, যা দ্রুত পিছনে এবং সামনের পাশে নিয়ন্ত্রণ অনুসন্ধান করে।';
	@override String get largeSkipDurationDescription => 'দীর্ঘ পিছনে যাওয়া দূরে নির্ধারণ করুন এবং সামনের দিকে নিয়ন্ত্রণ খুঁজুন।';
	@override String get rewindOnResumeDescription => 'একটি ভিডিও পুনরাবৃত্তি করার সময় এই সংখ্যা দ্বারা ফেরত Playback মুদ্রিত করুন।';
	@override String get defaultSleepTimerDescription => 'আপনি ঘুম টাইমার শুরু করার সময় ব্যবহৃত প্রথম দীর্ঘতা নির্ধারণ করুন।';
	@override String get playNextCountdownDescription => 'পরবর্তী epizode শুরু করার আগে এটি অনেক সময় অপেক্ষা করুন. 0 থেকে সিদ্ধান্ত নিতে অবিলম্বে শুরু করতে হবে।';
	@override String get autoSkipDelaySettingDescription => 'এটি যখন একটি intro, ক্রেডিট বা বিজ্ঞাপন স্বয়ংক্রিয়ভাবে বের করার জন্য নির্ধারণ করা হয়।';
	@override String get downmixCenterBoostDescription => 'সারাউন্ড অডিও স্টেরিওতে মিক্স ডাউন হলে সেন্টার চ্যানেলের সংলাপের মাত্রা বাড়ান।';
	@override String get displaySwitchDelayDescription => 'ডিসপ্লে মোড বদলানোর আগে অপেক্ষা করুন, যাতে টিভি বা রিসিভার আগের সুইচটি শেষ করতে পারে।';
	@override String get playerBackendDescription => 'এই ডিভাইসটিতে কোন প্লেব্যাক ইঞ্জিন ডকোড করে এবং ভিডিও ফেরত দেয় তা নির্বাচন করুন।';
	@override String get exoPlayerDescription => 'অ্যান্ড্রয়েডের মিডিয়া3-এ ভিত্তিক খেলোয়াড় এবং সমর্থিত হার্ডওয়্যার পথগুলি ব্যবহার করুন।';
	@override String get mpvDescription => 'MPV ব্যবহার করুন, যা আরও Playback, Subtitle এবং ভিডিও প্রক্রিয়াকরণ কন্ট্রোলগুলি প্রকাশ করে।';
	@override String get scopeOffDescription => 'শুধুমাত্র বর্তমান প্লেব্যাক সেশন জন্য পরিবর্তন রাখুন।';
	@override String get scopeGlobalDescription => 'প্রতিটি লাইব্রেরি এবং টাইটার জন্য একই মূল্য পুনরায় ব্যবহার করুন।';
	@override String get scopeLibraryDescription => 'প্রতিটি লাইব্রেরির জন্য একটি নির্দিষ্ট মূল্য মনে রাখুন।';
	@override String get scopeTitleDescription => 'প্রতিটি প্রদর্শন বা চলচ্চিত্রের জন্য একটি নির্দিষ্ট মূল্য মনে রাখুন।';
	@override String get specialsOrderingServerDescription => 'মিডিয়া সার্ভার দ্বারা সরবরাহ করা Episode Order রাখুন।';
	@override String get specialsOrderingAirDateDescription => 'নিয়মিত পরিস্থিতিগুলির মধ্যে বিশেষ জায়গাগুলি তাদের বিমান ডেটা দ্বারা স্থাপন করুন।';
	@override String get specialsOrderingLastDescription => 'নিয়মিত সপ্তাহের পর প্রতিটি বিশেষ স্থাপন করুন।';
	@override String get skipIntroModeDescription => 'ইন্ট্রো মার্কেটগুলি স্বাভাবিকভাবে খেলবে কিনা নির্বাচন করুন, একটি স্কাইপ बटन প্রদর্শন করুন, অথবা স্বয়ংক্রিয়ভাবে স্কাইভ করুন।';
	@override String get skipCreditsModeDescription => 'ক্রেডিটগুলি স্বাভাবিকভাবে খেলবে কিনা নির্বাচন করুন, একটি স্কাইপ बटन প্রদর্শন করুন, অথবা স্বয়ংক্রিয়ভাবে স্টাইপ করুন।';
	@override String get skipAdsModeDescription => 'শনাক্ত করা বিজ্ঞাপন স্বাভাবিকভাবে চলবে, স্কিপ বোতাম দেখাবে, নাকি নিজে থেকেই এড়িয়ে যাবে তা বেছে নিন।';
	@override String get playbackBufferAutoDescription => 'সক্রিয় খেলোয়াড়কে তার স্বাভাবিক বাফার আকার নির্বাচন করুন।';
	@override String get playbackBufferLargeDescription => 'Playback এর আগে আরো মিডিয়া প্রস্তুত রাখুন; এটি আরও স্মৃতি ব্যবহার করে।';
	@override String get playbackBufferExtraLargeDescription => 'সবচেয়ে বড় পড়া-হাইড বাফার রাখুন; এটি সর্বাধিক স্মৃতি ব্যবহার করে।';
	@override String get defaultQualityDescription => 'ডিফল্ট ভিডিও রেজিউশন এবং সার্ভারটি ট্রান্সকোড করার জন্য টাইমগুলি বিট্রেট করুন।';
	@override String get cellularQualityDescription => 'যখন ডিভাইস একটি সেলের একক সংযোগ ব্যবহার করে থাকে, তখন ভিত্তিতে মানের অতিক্রম করুন।';
	@override String get remoteQualityDescription => 'রিমোট সংযোগে সার্ভারের সঙ্গে যুক্ত হলে ডিফল্ট কোয়ালিটির বদলে এই মান ব্যবহার করুন।';
	@override String get qualityPresetOriginalDescription => 'সার্ভারকে এটি ট্রান্সকোড করার জন্য অনুরোধ না করে তার উপলব্ধ মানে ফরাস খেলুন।';
	@override String get qualityPresetTranscodeOptionDescription => 'উপরে দেখানো রেজোলিউশন ও বিটরেট ব্যবহার করে রূপান্তরিত স্ট্রিম দিতে সার্ভারকে বলুন।';
	@override String get qualityPresetSameAsDefaultDescription => 'Default Quality এর মধ্যে নির্বাচিত মান ব্যবহার করুন।';
	@override String get musicQualityDescription => 'সার্ভার থেকে অনুরোধ করা সর্বোচ্চ অডিও বিট্রেট সেট করুন; মূল শূন্য প্রদর্শন রাখে।';
	@override String get musicQualityOriginalDescription => 'Bitrate-capped transcode ছাড়া সূত্র অডিও খেলুন।';
	@override String get musicQualityTranscodeOptionDescription => 'উপরে দেখানো বিটরেটের কাছাকাছি সীমা রেখে সার্ভারকে ট্রান্সকোড করতে বলুন; প্রকৃত আউটপুট ভিন্ন হতে পারে।';
	@override String get maxVolumeInputLabel => 'সর্বোচ্চ পরিমাণ (%)';
	@override String get checkForUpdatesDescription => 'এখন দেখুন কি PlezyNG এর নতুন সংস্করণ পাওয়া যায় কিনা।';
	@override String get appearanceDescription => 'অ্যাপটি থেমা নির্বাচন করুন এবং লাইব্রেরি কার্ড, হোম রান এবং ন্যাভাইজেশন সংশোধন করুন।';
	@override String get prerollLibraryDescription => 'সিনেমা pre-rolls হিসাবে উপলব্ধ ক্লিপগুলি প্রন্তর্ভুক্ত লাইব্রেরি নির্বাচন করুন।';
	@override String get prerollSelectionDescription => 'নির্বাচিত লাইব্রেরির কোন ক্লিপগুলো সিনেমার আগে চলতে পারবে তা বেছে নিন।';
	@override String get contentScreensaverDelayOptionDescription => 'স্ক্রিন সার্ভার শিল্প প্রদর্শন করার আগে এই অনেক মিনিট অন্তর্ভুক্ত অপেক্ষা করুন।';
	@override String get videoCodecOptionDescription => 'সমর্থিত হলে এই কোডেক সরাসরি চালাতে দিন। চেক না করা কোডেকগুলো মিডিয়া সার্ভার ট্রান্সকোড করবে।';
}

// Path: themeEditor
class _Translations$themeEditor$bn extends Translations$themeEditor$en {
	_Translations$themeEditor$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get builtIn => 'ভিত্তিতে';
	@override String get presets => 'প্রজাতন';
	@override String get custom => 'কাস্টম';
	@override String get customEmpty => 'এখনো সৃষ্টি হয়নি';
	@override String get editCustom => 'Edit কাস্টম টেমা';
	@override String get editCustomDescription => 'প্রতিটি রঙ নিজেকে বেছে নিন';
	@override String get locked => 'জীবনযাপন প্রয়োজনীয়';
	@override String get savedLocked => 'সংরক্ষিত - জীবনের জন্য অ্যাক্সেসের সাথে পাওয়া যায়';
	@override String get title => 'কাস্টম থেম';
	@override String get startFrom => 'শুরু থেকে';
	@override String get startFromDescription => 'অন্য বিষয় থেকে সব রঙ কপি করুন';
	@override String get colors => 'রঙ';
	@override String get preview => 'পূর্বাভাস';
	@override late final _Translations$themeEditor$slots$bn slots = _Translations$themeEditor$slots$bn._(_root);
	@override String get opacity => 'অপারেশন';
	@override String get hexHint => '#RRGGBB বা #AARRGGBB';
	@override String get fromOtherThemes => 'অন্যান্য বিষয় থেকে';
	@override String swatchLabel({required Object theme, required Object color}) => '${theme} ${color}';
	@override late final _Translations$themeEditor$contrast$bn contrast = _Translations$themeEditor$contrast$bn._(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, উপদেশিত ${minimum}:1 এর নিচে';
	@override String get discardTitle => 'পরিবর্তন ভাবছেন?';
	@override String get discardMessage => 'আপনার সংরক্ষণ না করা রঙের পরিবর্তনগুলি হারিয়ে যাবে।';
	@override String get discard => 'বিতর্ক';
	@override String previewCardTitle({required Object number}) => 'আয়াত ${number}';
	@override String previewCardSubtitle({required Object minutes}) => '${minutes} মিনিট left';
	@override String get previewSwitch => 'Autoplay গাড়ি';
	@override String get previewMutedText => 'দ্বিতীয় লেখা এভাবে পড়বে।';
	@override String get themeSystemDescription => 'আপনার ডিভাইসের প্রদর্শন অনুসরণ করুন এবং স্বয়ংক্রিয়ভাবে আলো ও অন্ধকার মধ্যে পরিবর্তন করুন।';
	@override String get themeLightDescription => 'অন্ধকার টেক্সটের সাথে একটি উজ্জ্বল ফাউন্ড ব্যবহার করুন।';
	@override String get themeDarkDescription => 'আলো টেক্সটের সাথে একটি অন্ধকার ফলাফল ব্যবহার করুন।';
	@override String get themeOledDescription => 'অর্থাৎ কালো পৃথিবীগুলি ব্যবহার করুন যা OLED স্ক্রিনগুলিতে আলো কমে যায়।';
	@override String get themeEmberDescription => 'গরম লাল এবং আকর্ষণ রঙ ব্যবহার করুন।';
	@override String get themeGlacierDescription => 'নীল অ্যাক্সেন্ট রঙ ব্যবহার করুন।';
	@override String get themeForestDescription => 'সবুজ এবং প্রাকৃতিক অ্যাক্সেন্ট রঙ ব্যবহার করুন।';
	@override String get themePlumDescription => 'প্লাম ও ভোল্ট অ্যাক্সেন্ট রঙ ব্যবহার করুন।';
	@override String get themePaperDescription => 'গরম কাগজের মতো পৃথিবী এবং ইঙ্ক-প্রভিত্তিক রঙ ব্যবহার করুন।';
	@override String get themeCustomDescription => 'আপনি কাস্টম থেম এডিটারে সৃষ্টি করেছেন রঙ প্যালেট ব্যবহার করুন।';
	@override String get editorDescription => 'একটি প্যালেটের রং বেছে নিয়ে তার hue, saturation, brightness বা opacity বদলান; সংরক্ষণের আগে প্রিভিউতে পরিবর্তন দেখুন। চাইলে একটি hex রংও লিখতে পারেন।';
}

// Path: search
class _Translations$search$bn extends Translations$search$en {
	_Translations$search$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get hint => 'সিনেমা, সিনেমা, সিনেমা, সিনেমা...';
	@override String get tryDifferentTerm => 'একটি ভিন্ন অনুসন্ধান সূত্র চেষ্টা করুন';
	@override String get searchYourMedia => 'আপনার মিডিয়া অনুসন্ধান';
	@override String get enterTitleActorOrKeyword => 'Title, Actor বা Keyword লিখুন';
	@override String get people => 'জনগণ';
}

// Path: hotkeys
class _Translations$hotkeys$bn extends Translations$hotkeys$en {
	_Translations$hotkeys$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'সেট Shortcut জন্য ${actionName}';
	@override String get clearShortcut => 'কঠিন কঠিন';
	@override String get noShortcutSet => 'কোন ছোট্ট সেট';
	@override String get currentShortcut => 'বর্তমান কুরআন :';
	@override String get pressToRecord => 'একটি কুরআন রেকর্ড করার জন্য নির্বাচন করুন';
	@override String get recordingShortcut => 'এখন কুরআন চাপ করুন';
	@override late final _Translations$hotkeys$actions$bn actions = _Translations$hotkeys$actions$bn._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$bn extends Translations$fileInfo$en {
	_Translations$fileInfo$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'ফাইল তথ্য';
	@override String get overview => 'বিবরণ';
	@override String get video => 'ভিডিও';
	@override String get audio => 'অডিও';
	@override String get subtitles => 'সাবটাইটেল';
	@override String get images => 'ভিত্তিতে ছবি';
	@override String get dataStreams => 'ডাটা স্ট্রিম';
	@override String get lyrics => 'গানের কথা';
	@override String get file => 'ফাইল';
	@override String get attachments => 'আটকেল';
	@override String get delivery => 'প্রদান';
	@override String versionCounter({required Object index, required Object count}) => 'সংস্করণ ${index} এর ${count}';
	@override String fileCounter({required Object index, required Object count}) => 'ফাইল ${index} এর ${count}';
	@override String get noStreams => 'সার্ভার এই ফাইলের জন্য কোন প্রদর্শন না জানিয়েছে।';
	@override String get copyPath => 'পথ কপি';
	@override String get pathCopied => 'ফাইল পথ কপি';
	@override String get codec => 'কোডেক';
	@override String get codecTag => 'কোডেক Tag';
	@override String get resolution => 'সিদ্ধান্ত';
	@override String get codedResolution => 'কোডিং রসিলেশন';
	@override String get bitrate => 'বিট্রেট';
	@override String get frameRate => 'ফ্রেম রেট';
	@override String get rotation => 'রোটেশন';
	@override String get comment => 'কিভাবে';
	@override String get audioDescription => 'অডিও Description';
	@override String get headerCompression => 'হেডার কোম্পানি';
	@override String get sidecarFile => 'সিডেকার ফাইল';
	@override String get transportTimestamp => 'ট্রাফিক টাইম';
	@override String get displayOffset => 'ডাউনলোড Offset';
	@override String get previewFailureCode => 'ভুল কোড';
	@override String get previewRetries => 'পূর্বাভাস Retries';
	@override String get aspectRatio => 'এস্পেক্ট রেসিও';
	@override String get pixelAspectRatio => 'পিক্সেল Aspect Ratio';
	@override String get profile => 'প্রোফাইল';
	@override String get level => 'স্তর';
	@override String get bitDepth => 'গভীরতা';
	@override String get pixelFormat => 'পিক্সেল ফরম্যাট';
	@override String get colorSpace => 'কালার স্পেস';
	@override String get colorRange => 'রঙ রান্না';
	@override String get colorPrimaries => 'কালার প্রাইমারি';
	@override String get colorTransfer => 'কালার ট্রান্সফার';
	@override String get chromaSubsampling => 'ক্রোম Subsampling';
	@override String get chromaLocation => 'ক্রোম অবস্থান';
	@override String get scanType => 'স্ক্যান টাইপ';
	@override String get interlaced => 'Interlink করা';
	@override String get anamorphic => 'অ্যানামর্ফিক';
	@override String get referenceFrames => 'Reference ফ্রেম';
	@override String get dynamicRange => 'ডিনামিনিক রান্না';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Dolby Vision নম্বর';
	@override String get dolbyVisionVersion => 'Dolby Vision সংস্করণ';
	@override String get dolbyVisionLayers => 'Dolby Vision তালিকা';
	@override String get baseLayerCompatibility => 'Base Layer সংযুক্ততা';
	@override String get avcBitstream => 'AVC বিট্রেম';
	@override String get nalLengthSize => 'নল দীর্ঘতা';
	@override String get scalingMatrix => 'কাস্টম Scaling Matrix';
	@override String get streamIdentifier => 'প্রদর্শন Identifier';
	@override String get streamIndex => 'প্রদর্শন Index';
	@override String get streamId => 'স্ট্রিম ID';
	@override String get language => 'ভাষা';
	@override String get languageCode => 'ভাষা কোড';
	@override String get streamTitle => 'ট্র্যাক টাইম';
	@override String get channels => 'চ্যানেলগুলো';
	@override String get sampleRate => 'নমুনা হার';
	@override String get spatialAudio => 'স্পেশাল অডিও';
	@override String get textBased => 'টেক্সট ভিত্তি';
	@override String get subtitleFormat => 'সিডেকার ফর্মেট';
	@override String get provider => 'সরবরাহকারী';
	@override String get matchScore => 'Match Score খেলা';
	@override String get externalDelivery => 'আলাদাভাবে সেবা করা যায়।';
	@override String get sidecarPath => 'সিডেকার পথ';
	@override String get sourceStream => 'কপি থেকে';
	@override String get temporary => 'সময়কালীন';
	@override String get timeBase => 'সময় Base';
	@override String get overallBitrate => 'মোট বিট্রেট';
	@override String get path => 'পথ';
	@override String get fileName => 'ফাইল নাম';
	@override String get size => 'বড়';
	@override String get totalSize => 'মোট আকার';
	@override String get container => 'কন্টিনার';
	@override String get duration => 'দীর্ঘদিন';
	@override String get previewThumbnails => 'পূর্ববর্তী টমিনাল';
	@override String get previewIndex => 'পূর্বাভাস Index';
	@override String get packetLength => 'প্যাকেটের দীর্ঘতা';
	@override String get filePresent => 'ফাইল উপস্থিতি';
	@override String get fileReadable => 'সার্ভার দ্বারা পড়া';
	@override String get streamPath => 'পথ প্রদর্শন';
	@override String get optimizedForStreaming => 'Streaming জন্য Optimized';
	@override String get has64bitOffsets => '64 বিট অফসেট';
	@override String get protocol => 'প্রোটোটোকল';
	@override String get mediaType => 'মিডিয়া টাইপ';
	@override String get sourceKind => 'সূত্র কেমন';
	@override String get optimizedVersion => 'Optimized সংস্করণ';
	@override String get optimizationTarget => 'সেরা লক্ষ্য';
	@override String get deletedAt => '삭제';
	@override String get remoteSource => 'দূরবর্তী সূত্র';
	@override String get infiniteStream => 'infinite প্রদর্শন';
	@override String get directPlay => 'সরাসরি খেলা';
	@override String get directStream => 'সরাসরি প্রদর্শন';
	@override String get transcoding => 'ট্রানকডিং';
	@override String get etag => 'ETag';
	@override String get versionId => 'সংস্করণ ID';
	@override String get fileId => 'ফাইল ID';
	@override String get defaultAudioTrack => 'অডিও ট্র্যাক';
	@override String get defaultSubtitleTrack => 'ডিফল্ট Subtitle Track';
	@override String get subtitlesOff => 'বন্ধ';
	@override String get flagDefault => 'প্রত্যাশিত';
	@override String get flagForced => 'বাধ্য';
	@override String get flagSelected => 'নির্বাচিত';
	@override String get flagExternal => 'বিদেশি';
	@override String get flagHearingImpaired => 'শুনতে অসুবিধা';
	@override String get flagDub => 'ডাব';
	@override String get flagOriginal => 'মূল';
	@override String get channelsMono => 'মোনো';
	@override String dolbyVisionProfile({required Object profile}) => 'প্রোফাইল ${profile}';
}

// Path: mediaMenu
class _Translations$mediaMenu$bn extends Translations$mediaMenu$en {
	_Translations$mediaMenu$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'মারি দেখে';
	@override String get markAsUnwatched => 'মারি অদৃশ্য';
	@override String get removeFromContinueWatching => 'চলুন দেখতে থেকে বের করুন';
	@override String get viewDetails => 'বিস্তারিত দেখুন';
	@override String get goToSeries => 'সিরিজে যান';
	@override String get shufflePlay => 'খেলা শফল';
	@override String get shuffleNotAvailableOffline => 'শফল অফলি পাওয়া যায় না';
	@override String get fileInfo => 'ফাইল তথ্য';
	@override String get deleteEpisodeFromServer => 'সার্ভার থেকে এজেস্ট 삭제 করুন';
	@override String get deleteSeasonFromServer => 'সার্ভার থেকে সপ্তাহ মুছে ফেলা';
	@override String get deleteShowFromServer => 'সার্ভার থেকে প্রদর্শন মুছে ফেলুন';
	@override String get deleteMovieFromServer => 'সার্ভার থেকে ভিডিও মুছে ফেলুন';
	@override String get deleteEpisodeTitle => 'এই অধ্যায়টি কি মুছে ফেলবে?';
	@override String get deleteSeasonTitle => 'এই সপ্তাহে নেমে যাবে?';
	@override String get deleteShowTitle => 'এই প্রদর্শনটি কি মুছে ফেলবে?';
	@override String get deleteMovieTitle => 'এই চলচ্চিত্রটি কি মুছে ফেলবে?';
	@override String get deleteEpisodeConfirm => 'মুছে ফেলুন epizode';
	@override String get deleteSeasonConfirm => 'মুছে ফেলুন সপ্তাহ';
	@override String get deleteShowConfirm => 'মুছে ফেলুন প্রদর্শনী';
	@override String get deleteMovieConfirm => 'সিনেমা মুছে ফেলুন';
	@override String get deleteAnyway => 'যদিও মুছে ফেলুন';
	@override String confirmDeleteTarget({required Object title}) => 'আপনার সার্ভার থেকে স্থায়ীভাবে ${title} মুছে ফেলুন?';
	@override String get deleteMultipleWarning => 'এতে সব পর্ব এবং সেগুলির ফাইল অন্তর্ভুক্ত রয়েছে।';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n,
		one: 'এতে থাকা ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}টি পর্ব এবং তার ফাইল মুছে যাবে।',
		other: 'এতে থাকা সব ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}টি পর্ব এবং সেগুলির ফাইল মুছে যাবে।',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n,
		one: 'এই আইটেমটি ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}টি ফাইলে সংরক্ষিত আছে, যা মুছে যাবে।',
		other: 'এই আইটেমটি ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}টি ফাইল জুড়ে সংরক্ষিত আছে এবং সবগুলি মুছে যাবে।',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n,
		one: 'একই ফাইলে আরও ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}টি পর্ব সংরক্ষিত আছে এবং সেটিও মুছে যাবে:',
		other: 'একই ফাইলে আরও ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}টি পর্ব সংরক্ষিত আছে এবং সেগুলিও মুছে যাবে:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'PlezyNG কোন ফাইলটি মুছে ফেলবে তা নিশ্চিত করতে পারেন না, তাই এটি উপরে নামিত পণ্যের চেয়ে বেশি মুছে ফেলতে পারে. বাতিল করুন এবং আবারও চেষ্টা করুন, অথবা কোনওভাবে মুছে ফেলুন।';
	@override String get deleteScopeUnverifiedNoFileInfo => 'আপনার সার্ভার এই আইটেমের ফাইলের বিবরণ দেয়নি, তাই PlezyNG কোন ফাইলগুলি মুছে যাবে তা পরীক্ষা করতে পারছে না। উপরে উল্লেখ করা আইটেম ছাড়াও আরও কিছু মুছে যেতে পারে।';
	@override String get mediaDeletedSuccessfully => 'সফলভাবে মুছে ফেলেন মিডিয়া';
	@override String get mediaFailedToDelete => 'মিডিয়া পণ্য মুছে ফেলে না';
	@override String get rate => 'রাত';
	@override String get playFromBeginning => 'শুরু থেকে খেলা';
	@override String get playVersion => 'গেম সংস্করণ...';
}

// Path: rateSheet
class _Translations$rateSheet$bn extends Translations$rateSheet$en {
	_Translations$rateSheet$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'রাত';
	@override String get server => 'সার্ভার';
	@override String get favorite => 'পছন্দ';
	@override String get favorited => 'প্রিয়';
	@override String get saved => 'বাঁচানো';
	@override String get notAvailable => 'খেলা পাওয়া যায়নি';
	@override String get noConnectedServices => 'সেখান থেকে সেবা সংযোগ করতে Settings এর একটি পরিষেবা যোগ করুন।';
}

// Path: accessibility
class _Translations$accessibility$bn extends Translations$accessibility$en {
	_Translations$accessibility$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, সিনেমা';
	@override String mediaCardShow({required Object title}) => '${title}, টিভি প্রদর্শন';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'দেখানো';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent}% দেখানো';
	@override String get mediaCardUnwatched => 'দেখা হয়নি';
	@override String get tapToPlay => 'খেলতে ট্যাপ';
	@override String get decrease => 'কমে';
	@override String get increase => 'বৃদ্ধি';
	@override String decreaseValue({required Object label}) => 'কমে যাওয়া ${label}';
	@override String increaseValue({required Object label}) => 'সংখ্যা: ${label}';
	@override String get hue => 'হুই';
	@override String get saturation => 'সুরতান';
	@override String get brightness => 'সূর্য';
	@override String get hexColor => 'হেক্স রঙ';
	@override String get expandText => 'টেক্সট বিস্তারিত';
	@override String get collapseText => 'ভেঙে পড়েন টেক্সট';
	@override String get alphabetNavigation => 'অ্যালবাম navigation';
	@override String get alphabetScrollHint => 'এগিয়ে বা নিচের দিকে চলে যাওয়ার জন্য লিখে';
	@override String rowColumnPosition({required Object rowCount, required Object row, required Object columnCount, required Object column}) => '${rowCount}টি সারির মধ্যে ${row} নম্বর সারি, ${columnCount}টি কলামের মধ্যে ${column} নম্বর কলাম';
	@override String rowPosition({required Object row, required Object rowCount}) => 'রান ${row} এর ${rowCount}';
	@override String get autoScrollPlay => 'Auto-Scroll খেলা';
	@override String get autoScrollPause => 'স্বয়ংক্রিয় স্ক্রল';
	@override String get hueShort => 'H';
	@override String get saturationShort => 'S';
	@override String get valueShort => 'V';
	@override String get red => 'লাল';
	@override String get green => 'সবুজ';
	@override String get blue => 'নীল';
	@override String get redShort => 'R';
	@override String get greenShort => 'জি';
	@override String get blueShort => 'বি';
	@override String get colorModeHsv => 'HSV';
	@override String get colorModeRgb => 'RGB';
	@override String get title => 'অ্যাক্সেসযোগ্যতা';
	@override String get summary => 'টেক্সট, কন্ট্রোস্ট, মোট এবং নিয়ন্ত্রণ';
	@override String get systemHint => 'আপনার ডিভাইসের অ্যাক্সেসযোগ্যতা সেটস সবসময় প্রয়োগ করা হয়. এই পছন্দগুলি PlezyNG সারা সময় সমাধানগুলি যোগ করে।';
	@override String get readability => 'পড়া ও দেখার সুযোগ';
	@override String get textSize => 'টেক্সটের বড়';
	@override String get preview => 'আপনার পরবর্তী গল্পটি খুঁজে পেতে. পড়ুন, শুনুন এবং আপনার নিজের ধাপে দেখুন।';
	@override String get boldText => 'কঠিন ইন্টারফেস টেক্সট';
	@override String get highContrast => 'উচ্চ প্রতিরোধ';
	@override String get highContrastHint => 'হালকা বা গাঢ় পটভূমিতে আরও স্পষ্ট লেখা, সীমানার রেখা ও ফোকাস নির্দেশক।';
	@override String get interaction => 'ইন্টারফেস ও ইন্টারফেশন';
	@override String get reduceMotion => 'মোটর কমাতে';
	@override String get reduceMotionHint => 'ফোকাসের নির্দেশক, পৃষ্ঠা পরিবর্তন ও সাজসজ্জার প্রভাবগুলির নড়াচড়া বন্ধ রাখুন।';
	@override String get largeTargets => 'বড় ট্যাক্স টার্গেট';
	@override String get largeTargetsHint => 'স্পর্শ ও সহায়ক প্রযুক্তির মাধ্যমে চলাচল সহজ করতে সাধারণ নিয়ন্ত্রণগুলির জায়গা বড় করুন।';
	@override String get navigationHint => 'নিয়ন্ত্রণগুলির মধ্যে যেতে Tab ও Shift+Tab, সক্রিয় করতে Enter বা Space এবং বন্ধ করতে Escape বা ফিরে যাওয়ার বোতাম ব্যবহার করুন। বই খোলা থাকলে জুম ও পড়ার পছন্দগুলি বদলানো যায়।';
	@override String get textSizeDescription => 'আপনার ডিভাইসের সিস্টেম টেক্সটের আকারের সেটিংয়ের পাশাপাশি PlezyNG ইন্টারফেসের লেখার আকারও পরিবর্তন করুন।';
	@override String get boldTextHint => 'ইন্টারফেস ট্যাগ এবং বার্তাগুলির জন্য একটি গভীর ওজন ব্যবহার করুন যা তাদের বিতর্ক করা সহজ করে।';
}

// Path: tooltips
class _Translations$tooltips$bn extends Translations$tooltips$en {
	_Translations$tooltips$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'শফল খেলা';
	@override String get playTrailer => 'ট্র্যালার খেলুন';
	@override String get markAsWatched => 'মার্ক দেখে';
	@override String get markAsUnwatched => 'মার্ক অবিশ্বাসিত';
}

// Path: audioTracks
class _Translations$audioTracks$bn extends Translations$audioTracks$en {
	_Translations$audioTracks$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'অডিও ট্র্যাক ${n}';
}

// Path: videoControls
class _Translations$videoControls$bn extends Translations$videoControls$en {
	_Translations$videoControls$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'অডিও';
	@override String get subtitlesLabel => 'সাবটাইটেল';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String get letterbox => 'বাক্স';
	@override String get fillScreen => 'স্ক্রিন পূরণ';
	@override String get stretch => 'বিস্তারিত';
	@override String get lockRotation => 'লক রটেশন';
	@override String get unlockRotation => 'রটিং অসুবিধা';
	@override String get timerActive => 'টাইমিং সক্রিয়';
	@override String playbackWillPauseIn({required Object duration}) => 'প্লাইব্যাক ${duration} সালে দাঁড়িয়ে যাবে';
	@override String get sleepTimerEndOfVideo => 'বর্তমান ভিডিও শেষ';
	@override String get sleepTimerStopAtHeader => 'থেমে যায়';
	@override String get sleepTimerDurationHeader => 'টাইম';
	@override String get playbackWillPauseAtEnd => 'এই ভিডিও শেষে Playback বন্ধ হবে';
	@override String get stillWatching => 'এখনও দেখতে চান?';
	@override String pausingIn({required Object seconds}) => '${seconds} সেকেন্ড পরে বিরতি দেওয়া হবে';
	@override String get continueWatching => 'চলুন';
	@override String get autoPlayNext => 'Next গাড়ি খেলা';
	@override String get playNext => 'Next খেলুন';
	@override String get playButton => 'খেলা';
	@override String get pauseButton => 'বিরতি';
	@override String get playbackPaused => 'দাঁড়িয়ে';
	@override String get playbackResumed => 'খেলতে';
	@override String get loadingVideo => 'ভিডিও ডাউনলোড';
	@override String get showPlaybackControls => 'Playback নিয়ন্ত্রণ দেখুন';
	@override String get hidePlaybackControls => 'Playback নিয়ন্ত্রণ';
	@override String seekBackwardButton({required Object seconds}) => 'ফেরত খুঁজুন ${seconds} সেকেন্ড';
	@override String seekForwardButton({required Object seconds}) => 'পূর্ববর্তী অনুসন্ধান ${seconds} সেকেন্ড';
	@override String get previousButton => 'পূর্ববর্তী epizode';
	@override String get nextButton => 'পরবর্তী epizode';
	@override String get previousChapterButton => 'পূর্ববর্তী চিঠি';
	@override String get nextChapterButton => 'পরবর্তী চিঠি';
	@override String get muteButton => 'মুটি';
	@override String get unmuteButton => 'অসংখ্য';
	@override String get settingsButton => 'Playback সিস্টেম';
	@override String get tracksButton => 'অডিও & সাবটাইটল';
	@override String get chaptersButton => 'চিঠি';
	@override String get segmentLoopHelp => 'এই প্লেব্যাকের সময় একটি বিভাগ চালু করুন. A সিস্টেম, তারপর পরবর্তী সময়ের মধ্যে B সিস্টেট করুন.';
	@override String get setLoopStart => 'সেন্ট লোভ শুরু (এ)';
	@override String get setLoopEnd => 'সেন্ট লোভ শেষ (B)';
	@override String get clearSegmentLoop => 'স্পষ্ট সেক্টর লুক';
	@override String get setLoopStartFirst => 'শুরু (এ) এর আগে শেষ (বি) সিস্টেম করুন।';
	@override String get loopEndAfterStart => 'শুরু থেকে পরবর্তী সূচনা হতে হবে।';
	@override String get segmentLoopUnavailable => 'এই প্লাইবের জন্য সেকেন্ড লুপিং পাওয়া যায় না।';
	@override String get loopPointNotSet => 'সিস্টেম না';
	@override String get bookmarksHelp => 'এই ডিভাইসে বুকমার্ক সংরক্ষণ করা হয়. সেই সময়ের জন্য একটি নির্বাচন করুন।';
	@override String get bookmarksButton => 'বুকমার্ক';
	@override String get chaptersAndBookmarks => 'বিভাগ ও বইমেলা';
	@override String get segmentLoop => 'সেগেট লোভ';
	@override String get addBookmark => 'Bookmark যোগ করুন';
	@override String get bookmarkName => 'Bookmark নাম';
	@override String get bookmarkNameHint => 'উদাহরণস্বরূপ, দৃশ্য খোলা';
	@override String bookmarkDefaultName({required Object n}) => 'বইমার্ক ${n}';
	@override String get bookmarkNameRequired => 'এ বইয়ের জন্য একটি নাম লিখুন।';
	@override String get deleteBookmark => 'বুকমার্ক 삭제';
	@override String get bookmarkLimitReached => 'এই পণ্যটি এখন 100 বইমেলা আছে।';
	@override String get bookmarkUnavailable => 'আমি এই বইমেলাটি সংরক্ষণ বা মুছে ফেলতে পারতাম না।';
	@override String get bookmarkSaved => 'বুকমার্ক উদ্ধার করা হয়েছে।';
	@override String get bookmarkDeleted => 'Bookmark মুছে ফেলা হয়েছে।';
	@override String loopPointSet({required Object point, required Object time}) => 'লোপ পয়েন্ট ${point} সেট করুন ${time}.';
	@override String get noChaptersOrBookmarks => 'কোন বই বা চিঠি পাওয়া যায় না।';
	@override String get versionQualityButton => 'সংস্করণ & মান';
	@override String get versionColumnHeader => 'সংস্করণ';
	@override String get qualityColumnHeader => 'মানের';
	@override String get qualityOriginal => 'মূল';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} এমবিএস';
	@override String get transcodeUnavailableFallback => 'Transcoding unavailable — খেলতে মূল মান';
	@override String get subtitleUnavailableFallback => 'নির্বাচিত সাবটাইটলগুলি লোড করা যাবে না - সাবটাইটল ছাড়া চলতে পারে';
	@override String get pipButton => 'ছবি-ন-পিক্টার মোড';
	@override String get aspectRatioButton => 'এস্পেক্ট রেসিও';
	@override String get ambientLighting => 'পরিবেশ আলো';
	@override String get fullscreenButton => 'পুরো স্ক্রিনে প্রবেশ';
	@override String get exitFullscreenButton => 'পুরো স্ক্রিনের বাইরে';
	@override String get alwaysOnTopButton => 'সবসময় শীর্ষে';
	@override String get rotationLockButton => 'রটিং লক';
	@override String get lockScreen => 'স্ক্রিন লক';
	@override String get screenLockButton => 'স্ক্রিন লক';
	@override String get timelineSlider => 'ভিডিও টাইমলাইন';
	@override String get volumeSlider => 'পরিমাণ স্তর';
	@override String endsAt({required Object time}) => 'ফাইনাল ${time}';
	@override String get pipActive => 'ছবি-ন-পিক্টার মধ্যে খেলা';
	@override String get pipFailed => 'ছবি-ন-ফিল্টার শুরু হয়নি';
	@override String get screenshotSaved => 'স্ক্রিন ফটো সুরক্ষিত';
	@override String get screenshotFailed => 'স্ক্রিন ফটো করতে পারত না';
	@override String zoomPercent({required Object percent}) => 'জুম ${percent}%';
	@override String volumePercent({required Object percent}) => 'শব্দের মাত্রা ${percent}%';
	@override late final _Translations$videoControls$pipErrors$bn pipErrors = _Translations$videoControls$pipErrors$bn._(_root);
	@override String get chapters => 'চিঠি';
	@override String get noChaptersAvailable => 'কোন বিভাগ নেই';
	@override String get queue => 'কুরআন';
	@override String get noQueueItems => 'কোন পণ্য নেই কুকুরে';
	@override String get noAudioDevicesAvailable => 'কোন অডিও ডিভাইস পাওয়া যায় না';
	@override String get searchSubtitles => 'অনুসন্ধান Subtitles';
	@override String get language => 'ভাষা';
	@override String get noSubtitlesFound => 'কোন সূত্র পাওয়া যায়নি';
	@override String get subtitleDownloaded => 'Subtitle ডাউনলোড';
	@override String get subtitleDownloadedNotApplied => 'ডাউনলোড করা হয়েছে, কিন্তু এটি নির্বাচন করা যায়নি';
	@override String get subtitleDownloadFailed => 'Subtitle ডাউনলোড করতে পারেননি';
	@override String get searchLanguages => 'ভাষা অনুসন্ধান...';
	@override String get skipIntro => 'সিন্ট্রো';
	@override String get skipCredits => 'ক্রেডিট স্কাইপ';
	@override String get nextEpisode => 'পরবর্তী Episode';
	@override String subtitleTrack({required Object n}) => 'ট্র্যাক ${n}';
	@override String subtitleFile({required Object name}) => 'পৃথিবী ${name}';
	@override String forcedTrack({required Object label}) => '${label} (প্রত্যাশিত)';
	@override String get osdSubtitlesOff => 'টাইপ: বেরিয়ে';
	@override String osdSubtitles({required Object track}) => 'সংখ্যা: ${track}';
	@override String osdAudio({required Object track}) => 'অডিও: ${track}';
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ফ্রেম',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ফ্রেম',
	);
	@override String get trackSelectionTitle => 'Playback এর আগে ট্র্যাক নির্বাচন করুন';
	@override String get trackSelectionAuto => 'স্বয়ংক্রিয় নির্বাচন';
	@override String get openMiniPlayer => 'খোলা মিনি খেলোয়াড়';
	@override String get returnToFullPlayer => 'পুরো খেলোয়াড়কে ফিরে আসুন';
	@override String get loadSubtitleFile => 'Subtitle ফাইলের জন্য...';
	@override String get subtitleLoadFailed => 'Subtitle ফাইল লোড করতে পারিনি';
	@override String get skipAds => 'হাঁটান Ads';
	@override String get tapToUnlock => 'আনলক করতে ট্যাপ করুন';
	@override String get tapAgainToUnlock => 'আনলক করতে আবার ট্যাপ করুন';
}

// Path: messages
class _Translations$messages$bn extends Translations$messages$en {
	_Translations$messages$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'দেখানো হয়েছে যেমন';
	@override String get markedAsUnwatched => 'অবিশ্বাসিত হিসাবে চিহ্নিত';
	@override String get markedAsWatchedOffline => 'দেখানো হিসাবে মার্কিত (এখন অনলাইনে সনাক্ত করা হবে)';
	@override String get markedAsUnwatchedOffline => 'নজরদারি হিসাবে চিহ্নিত (এখন অনলাইনে সিন্ক করা হবে)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'স্বয়ংক্রিয় ড্রাইভ: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n,
		one: 'গাড়ি-অটোমোড ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} দেখানো ডাউনলোড',
		other: 'Auto-remote ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} দেখানো ডাউনলোড',
	);
	@override String get removedFromContinueWatching => 'চলুন দেখার থেকে বের করা';
	@override String errorLoading({required Object error}) => 'ভুল: ${error}';
	@override String get searchPartialResults => 'কিছু মিডিয়া সার্ভারগুলি অনুসন্ধান করা যাবে না. उपलब्ध ফলাফল দেখানোর জন্য।';
	@override String get streamInterrupted => 'ফ্রান্স বন্ধ হয়ে গেল, প্রচার খেলতে বা ফেরার চেষ্টা করতে।';
	@override String get liveStreamInterrupted => 'লাইভ প্রদর্শন বন্ধ হয়েছিল. প্রচার খেলতে পেরেছিল।';
	@override String get fileInfoNotAvailable => 'ফাইল তথ্য পাওয়া যায় না';
	@override String get playbackAuthenticationRequired => 'এই পণ্যটি খেলতে আবার মিডিয়া সার্ভারে প্রবেশ করুন।';
	@override String get playbackServerUnavailable => 'মিডিয়া সার্ভার পাওয়া যায় না, পরে আবার চেষ্টা করুন।';
	@override String get playbackDataInvalid => 'সার্ভারটি অস্বীকার Playback তথ্য ফিরিয়ে দেয়।';
	@override String get playbackCancelled => 'Playback বাতিল করা হয়েছে।';
	@override String get playbackFailed => 'Playback শুরু করা যাবে না।';
	@override String playbackFailedDetail({required Object error}) => 'Playback শুরু করা যায় না: ${error}';
	@override String get audioOutputFailed => 'টেলিভিশন বা রেকর্ডার এর অডিও সংযোগ চেক করুন; অন্য অ্যাপগুলির কোনও অডিও নেই যদি, ডিভাইসটি পুনরায় শুরু করুন।';
	@override String get mediaUnavailable => 'এই বিষয়বস্তু এখন আর পাওয়া যায় না।';
	@override String errorLoadingFileInfo({required Object error}) => 'ভুল লোড ফাইল তথ্য: ${error}';
	@override String get errorLoadingSeries => 'ভুল লোডিং সিরিজ';
	@override String get musicNotSupported => 'Music Playback এখনো সমর্থিত হয় না';
	@override String get noDescriptionAvailable => 'কোন বিবরণ পাওয়া যায় না';
	@override String get noProfilesAvailable => 'কোন প্রোফাইল পাওয়া যায় না';
	@override String get contactAdminForProfiles => 'আপনার সার্ভার প্রশাসককে যোগাযোগ করুন প্রোফাইল যোগ করার জন্য';
	@override String get unableToDetermineLibrarySection => 'এই পণ্যের জন্য লাইব্রেরি বিভাগ নির্ধারণ করতে পারেন না';
	@override String get logsCleared => 'লগ পরিষ্কার';
	@override String get logsCopied => 'ক্লাববোর্ডে কপি করা';
	@override String get noLogsAvailable => 'কোন লগ পাওয়া যায় না';
	@override String libraryScanning({required Object title}) => 'স্ক্যানিং “${title}” ...';
	@override String libraryScanStarted({required Object title}) => 'লাইব্রেরি স্ক্যান শুরু হয় "${title}" জন্য';
	@override String libraryScanFailed({required Object error}) => 'স্ক্যান করতে পারিনি লাইব্রেরি: ${error}';
	@override String metadataRefreshing({required Object title}) => '“${title}” এর জন্য ফ্রেসিং মেটাদেট...';
	@override String metadataRefreshStarted({required Object title}) => 'মেটা ডেটা ফ্রিজ শুরু হয় "${title}" জন্য';
	@override String metadataRefreshFailed({required Object error}) => 'ম্যাটা ডেটা আপডেট করতে পারিনি: ${error}';
	@override String get logoutConfirm => 'আপনি কি নিশ্চিত যে আপনি ডাউনলোড করতে চান?';
	@override String get noSeasonsFound => 'কোন季節 পাওয়া যায় না';
	@override String get seasonsLoadFailed => 'সপ্তাহের লোড করতে পারবেন না';
	@override String get noEpisodesFound => 'প্রথম সপ্তাহে কোন ঘটনা পাওয়া যায়নি।';
	@override String get noEpisodesFoundGeneral => 'কোন ঘটনা পাওয়া যায়নি';
	@override String get episodesLoadFailed => 'এজিসগুলি লোড করতে পারবেন না';
	@override String get noResultsFound => 'কোন ফলাফল পাওয়া যায় না';
	@override String sleepTimerSet({required Object label}) => 'ঘুম টাইমার্ক ${label}';
	@override String get noItemsAvailable => 'কোন পণ্য পাওয়া যায় না';
	@override String get failedToCreatePlayQueueNoItems => 'একটি খেলা কুকুর তৈরি করতে পারতেন না - কোন পণ্য নেই';
	@override String failedPlayback({required Object action, required Object error}) => 'অসম্ভব ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'সমন্বয়যোগ্য খেলোয়াড়ের জন্য বিনিময় ...';
	@override String get serverLimitTitle => 'Playback হারিয়েছে';
	@override String get serverLimitBody => 'সার্ভার ভুল (HTTP 500). একটি প্যাডবাইড / ট্রান্সকডিং সীমাবদ্ধতা সম্ভবত এই সেশনকে প্রত্যাহার করেছিল।';
	@override String get mediaUnreadableTitle => 'ফাইল অসম্ভব';
	@override String get mediaUnreadableBody => 'সার্ভারটি এই পণ্যটি খুঁজে পেয়েছিল কিন্তু তার ফাইলটি পড়তে পারতেন না (HTTP 404). ফাইলটি সম্ভবত স্থানান্তর করা হয়, মুছে ফেলিত হয়, অথবা তার স্টোরেজ অঅফলি।';
	@override String get serverBusyTitle => 'অসম্ভব প্রদর্শন';
	@override String get serverBusyBody => 'সার্ভার এই ফাইলটি প্রদর্শন করতে বাধ্য করেছিল (HTTP 503). এটি আবার শুরু হতে পারে, व्यस्त, অথবা ফাইলের স্টোরেজ অফলি হতে পারে. এক মুহূর্তে আবার চেষ্টা করুন - যদি এটি চলছে, সার্ভার মালিককে সার্ভার এবং ফাইলের স্টোরেজ চেক করতে বলুন।';
	@override String get playbackNotAllowedTitle => 'Playback অনুমোদিত নয়';
	@override String get playbackNotAllowedBody => 'সার্ভার এই আইটেমটি স্ট্রিম করতে অস্বীকার করেছে (HTTP 403)। আপনার অ্যাকাউন্টে এটি চালানোর অনুমতি নাও থাকতে পারে, অথবা সার্ভার শুধু তার স্থানীয় নেটওয়ার্কে চালানোর অনুমতি দিতে পারে।';
	@override String get logsUploaded => 'লগ আপলোড';
	@override String get logsUploadFailed => 'লোগো আপলোড করতে পারিনি';
	@override String get logId => 'লগ ID';
	@override String get burnedSubtitlesUseMenu => 'এই প্রদর্শনে সাবটাইটিস জ্বালিত হয়. সাবটাইটিস মেনু থেকে তাদের পরিবর্তন করুন.';
	@override String get noVideoUrl => 'কোন ভিডিও URL নেই';
	@override String get playbackNoMediaSources => 'সার্ভার কোন খেলোয়াড় মিডিয়া সূত্র ফিরে দেয় না';
	@override String get playbackDataNotPrepared => 'Playback শুরু হয় তার ডেটা প্রস্তুত হওয়ার আগে';
	@override String get streamSelectionUnavailable => 'এই সূত্রের জন্য স্ট্রিম নির্বাচন পাওয়া যায় না';
	@override String get streamSelectionFailed => 'নির্বাচিত প্রদর্শনগুলি প্রয়োগ করতে পারবেন না';
	@override String get trackSelectionNotRemembered => 'এই প্লাস্টিক নির্বাচন শুধুমাত্র বর্তমান প্লাস্টিকের জন্য প্রযুক্ত।';
	@override String get serverUnavailableForProfile => 'কোন সার্ভার সক্রিয় প্রোফাইলের জন্য উপলব্ধ নয়';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$bn extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get previewSample => 'দ্রুত ব্রোড ফক্স পাখি পাখি পাখি পাখি পাখি পাখি';
	@override String get text => 'টেক্ট';
	@override String get border => 'সীমানা';
	@override String get background => 'ফাউন্ডেশন';
	@override String get fontSize => 'ফটন মাত্রা';
	@override String get textColor => 'টেক্সট রঙ';
	@override String get borderSize => 'সীমানা বড়';
	@override String get borderColor => 'সীমানা রঙ';
	@override String get backgroundOpacity => 'ফাউন্ডেশন অপসারণতা';
	@override String get backgroundColor => 'পৃথিবী রঙ';
	@override String get position => 'অবস্থান';
	@override String get assOverride => 'ASS অতিরিক্ত';
	@override String get overrideScale => 'স্কুল';
	@override String get overrideForce => 'শক্তি';
	@override String get overrideStrip => 'স্টাইলিং মুছে ফেলুন';
	@override String get positionTop => 'শীর্ষ';
	@override String get positionBottom => 'নম্বরে';
	@override String get useMargins => 'Margin ব্যবহার করুন';
	@override String get useMarginsDescription => 'ভিডিওের বাইরে ভিত্তিতে টেক্সট সাবটাইটগুলি অনুমতি দিন. স্টাইলিত সাবটাইটগুলি তাদের মূল স্থাপন রাখতে পারে।';
	@override String get anchorToScreen => 'স্ক্রিনের জন্য Anchor';
	@override String get anchorToScreenDescription => 'বিল্ড স্ক্রিন ভিডিও এর নীচে ব্ল্যাক বারগুলিতে টেক্সট সাবটাইটগুলি দেখুন';
	@override String get bold => 'সাহসী';
	@override String get italic => 'ইতালিক';
	@override String get renderResolution => 'রেন্ডার রেজলিউশন';
	@override String get renderResolutionScreen => 'স্ক্রিন রেজুলেশন';
	@override String get renderResolutionVideo => 'ভিডিও রেজুলেশন';
	@override String get fontSizeDescription => 'এই ডিভাইসে নম্বর টেক্সট মাত্রা নির্ধারণ করুন।';
	@override String get textColorDescription => 'Subtitle টেক্সটের জন্য ব্যবহৃত রঙ নির্বাচন করুন।';
	@override String get borderSizeDescription => 'Subtitle টেক্সটের চারপাশে উত্পাদন গভীরতা স্থাপন করুন।';
	@override String get borderColorDescription => 'নম্বরের জন্য ব্যবহৃত রঙ নির্বাচন করুন।';
	@override String get backgroundColorDescription => 'পৃথিবীর পিছনে রঙ নির্বাচন করুন।';
	@override String get backgroundOpacityDescription => 'সীমাবদ্ধ করুন কতটুকু দৃঢ়: 0 শতাংশ পরিষ্কার এবং 100% স্থিতিশীল।';
	@override String get positionDescription => '0 শতাংশ ভিডিওের শীর্ষ এবং 100% ডান।';
	@override String get assOverrideDescription => 'খেলোয়াড়টি অনুসরণ, সংশোধন, পরিবর্তন বা ASS সাবটাইটে ভিত্তিতে স্টাইলিং মুছে ফেলে কিনা নির্বাচন করুন।';
	@override late final _Translations$subtitlingStyling$assOverrideOptions$bn assOverrideOptions = _Translations$subtitlingStyling$assOverrideOptions$bn._(_root);
	@override String get renderResolutionDescription => 'চিত্র ও ASS সাবটাইটেলকে পিক্সেলে রূপান্তরের জন্য ব্যবহৃত রেজোলিউশন বেছে নিন। অ্যান্ড্রয়েডে কম স্কেল রেন্ডারিং কমাতে পারে, তবে ছবি কিছুটা নরম দেখাবে।';
	@override late final _Translations$subtitlingStyling$renderResolutionOptions$bn renderResolutionOptions = _Translations$subtitlingStyling$renderResolutionOptions$bn._(_root);
	@override String get boldDescription => 'একটি গুরুতর ওজনে subtitle টেক্সট ড্রাইভ করুন।';
	@override String get italicDescription => 'ইতালিক ভাষায় টেক্সট ড্রাইভ করুন।';
}

// Path: mpvConfig
class _Translations$mpvConfig$bn extends Translations$mpvConfig$en {
	_Translations$mpvConfig$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'উন্নত ভিডিও খেলোয়াড় সেটিংস';
	@override String get presets => 'প্রজাতন';
	@override String get noPresets => 'সুরক্ষিত প্রজাতন নেই';
	@override String get saveAsPreset => 'প্রসেস্ট হিসেবে রক্ষা করুন।';
	@override String get presetName => 'প্রজেক্ট নাম';
	@override String get presetNameHint => 'এই প্রসেস্টের জন্য একটি নাম লিখুন';
	@override String get loadPreset => 'লোড';
	@override String get deletePreset => 'মুছে ফেলুন';
	@override String get presetSaved => 'সুরক্ষিত';
	@override String get presetLoaded => 'পূর্বাভাস লোড';
	@override String get presetDeleted => 'পূর্বাভাস 삭제';
	@override String get confirmDeletePreset => 'আপনি কি নিশ্চিত যে আপনি এই প্রসেস্ট মুছে ফেলতে চান?';
	@override String get configPlaceholder => 'gpu-api=vulkan hwdec=auto # মন্তব্য';
	@override String get lineHint => 'option=value';
	@override String get addLine => 'লাইন যোগ করুন';
	@override String get removeLine => 'লাইন মুছে ফেলে';
	@override String get embeddedVoHint => 'vo, gpu-context এবং gpu-api Linux এর উপর ignored: ভিত্তিক ভিডিও সবসময় ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তি।';
}

// Path: dialog
class _Translations$dialog$bn extends Translations$dialog$en {
	_Translations$dialog$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'কার্যক্রম নিশ্চিত করুন';
}

// Path: profiles
class _Translations$profiles$bn extends Translations$profiles$en {
	_Translations$profiles$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'PlezyNG প্রোফাইল যোগ করুন';
	@override String get switchingProfile => 'ফোফাইল পরিবর্তন...';
	@override String get deleteThisProfileTitle => 'এই প্রোফাইলটি মুছে ফেলুন?';
	@override String deleteThisProfileMessage({required Object displayName}) => '${displayName} সরিয়ে দিন। সংযোগগুলি প্রভাবিত হবে না।';
	@override String get active => 'আক্রমণ';
	@override String get manage => 'পরিচালনা';
	@override String get delete => 'মুছে ফেলুন';
	@override String get signOut => 'সাইন আউট';
	@override String get signOutPlexTitle => 'Plex এর নামে চিহ্নিত করুন।';
	@override String signOutPlexMessage({required Object displayName}) => 'মুছে ফেলুন ${displayName} এবং সব Plex Home ব্যবহারকারীদের? কোনও সময়ে ফিরে সাইন আপ করুন।';
	@override String get signOutPlexDeleteDownloads => 'ডাউনলোড করুনও';
	@override String get signOutPlexDeleteDownloadsDescription => 'অন্যথায়, তারা এই ডিভাইসে থাকবে এবং আপনি এই অ্যাকাউন্টে ফিরে যখন ফিরে যান।';
	@override String get signedOutPlex => 'সেখানে আবেদন করা হয়েছে Plex।';
	@override String get signOutFailed => 'হঠাৎ হঠাৎ হঠাৎ হঠাৎ।';
	@override String get sectionTitle => 'প্রোফাইল';
	@override String get summarySingle => 'পরিচালিত ব্যবহারকারীদের এবং স্থানীয় পরিচয়গুলি মিশে প্রোফাইল যোগ করুন';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} প্রোফাইল · কার্যকর: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} প্রোফাইল';
	@override String get removeConnectionTitle => 'সংযোগ বন্ধ করুন ?';
	@override String removeConnectionMessage({required Object connectionLabel, required Object displayName}) => '${connectionLabel}-এ ${displayName}-এর অ্যাক্সেস সরিয়ে দিন। অন্য প্রোফাইলগুলির অ্যাক্সেস থাকবে।';
	@override String get deleteProfileTitle => 'প্রোফাইল ভেঙে?';
	@override String deleteProfileMessage({required Object displayName}) => '${displayName} এবং তার সংযোগগুলি মুছে ফেলুন. সার্ভারগুলি পাওয়া যায়।';
	@override String get profileNameLabel => 'প্রোফাইল নাম';
	@override String get pinProtectionLabel => 'PIN সুরক্ষা';
	@override String get copyAutomationLink => 'কপি Android স্বয়ংক্রিয় লিঙ্ক';
	@override String get copyAutomationLinkDescription => 'এই প্রোফাইলটি Android ইন্টেন্ট বা অটোমেশন থেকে নির্বাচন করুন. প্রোফাইল পিন চেক এখনও প্রয়োগ করা হয়.';
	@override String get automationLinkCopied => 'প্রোফাইল স্বয়ংক্রিয় লিঙ্ক কপি করা হয়েছে।';
	@override String get pinManagedByPlex => 'পিন Plex দ্বারা পরিচালিত হয় Edit on plex.tv.';
	@override String get noPinSetEditOnPlex => 'কোন PIN সেট নেই. একটি প্রয়োজন হলে, plex.tv-এ হোম ব্যবহারকারীটি সংশোধন করুন।';
	@override String get setPin => 'PIN সিস্টেম';
	@override String get setPinTitle => 'PIN সিস্টেম';
	@override String get confirmPinTitle => 'PIN সনাক্ত করুন';
	@override String get pinSet => 'পিন সেট';
	@override String get changePin => 'পরিবর্তন';
	@override String get removePin => 'সরান';
	@override String get connectionsLabel => 'সংযোগ';
	@override String get add => 'যোগ';
	@override String get deleteProfileButton => 'প্রোফাইল মুছে ফেলে';
	@override String get noConnectionsHint => 'কোন সংযোগ নেই — এই প্রোফাইল ব্যবহার করার জন্য একটি যোগ করুন।';
	@override String get noConnections => 'কোন সংযোগ নেই';
	@override String get plexHomeAccount => 'Plex বাড়ি অ্যাকাউন্ট';
	@override String plexAccountChip({required Object account}) => 'Plex অ্যাকাউন্ট: ${account}';
	@override String plexAccountUserChip({required Object user, required Object account}) => '${user} এর মাধ্যমে ${account}';
	@override String get connectionDefault => 'প্রত্যাশিত';
	@override String connectionAs({required Object displayName}) => '${displayName} হিসেবে';
	@override String get makeDefault => 'ভেঙে ফেলুন';
	@override String get removeConnection => 'সরান';
	@override String get profileRenamed => 'প্রোফাইলের নাম।';
	@override String borrowAddTo({required Object displayName}) => '${displayName} এর জন্য যোগ করুন';
	@override String get borrowExplain => 'অন্য প্রোফাইলের সংযোগের লেনদেন করুন. PIN-প্রোফাইলগুলি একটি PIN প্রয়োজন।';
	@override String get borrowEmpty => 'এখনো কোনও টাকা না δανειστεί করতে হবে।';
	@override String get borrowEmptySubtitle => 'Plex, Jellyfin বা Emby এর সাথে অন্য প্রোফাইলের সাথে প্রথম যোগাযোগ করুন।';
	@override String get borrowLoadFailed => 'এখানে কোনো সংযোগ চালানো যাবে না, আবার চেষ্টা করুন।';
	@override String borrowFromProfile({required Object displayName}) => '${displayName} থেকে';
	@override String get borrowConnectionBorrowed => 'লেনদেন করা হয়েছে।';
	@override String get borrowFailed => 'লেনদেনের সংযোগটি অসম্ভব।';
	@override String get incorrectPin => 'পিন ভুল।';
	@override String get incorrectPinTryAgain => 'পিনটি ভুল করে, আবারও চেষ্টা করুন।';
	@override String get sourceProfileMissingParentAccount => 'পৃথিবীর পৃথিবীর পৃথিবীর পৃথিবীর পৃথিবীর পৃথিবীর পৃথিবীর পৃথিবীর পৃথিবীর পৃথিবীর পৃথিবীর পৃথিবী।';
	@override String get failedToLoadHomeUsers => 'আপনার Plex Home ব্যবহারকারীদের লোড করতে পারেন না. আপনার সংযোগ চেক করুন এবং আবার চেষ্টা করুন.';
	@override String get failedToVerifyPin => 'পিন সনাক্ত করতে পারিনি।';
	@override String get newProfile => 'নতুন প্রোফাইল';
	@override String get profileNameHint => 'উদাহরণস্বরূপ, গ্রাহক, শিশু, পরিবার রুম';
	@override String get pinProtectionOptional => 'PIN সুরক্ষা (অন্যাশনাল)';
	@override String get pinExplain => '4 ডিগ্রী পিন ব্যবহার করতে হবে।';
	@override String get continueButton => 'চলুন';
	@override String get pinsDontMatch => 'পিনস পেমেন্ট নয়';
	@override String get tokenIdentityMismatch => 'Plex প্রোফাইল টকেন অপেক্ষা সার্ভারের জন্য সমাধান';
	@override String get settingsLocked => 'এই প্রোফাইলের জন্য সেটিংস বন্ধ করা হয়।';
	@override String get unlockSettings => 'ডাউনলোড সিস্টেম';
	@override String get showExploreForProfile => 'দেখুন এই প্রোফাইলের জন্য গবেষণা';
	@override String get showExploreForProfileDescription => 'এই প্রোফাইলের নৌকা থেকে Explore মুছে ফেলতে বন্ধ করুন।';
}

// Path: connections
class _Translations$connections$bn extends Translations$connections$en {
	_Translations$connections$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'সংযোগ';
	@override String get addConnection => 'সংযোগ যোগ করুন';
	@override String get addConnectionSubtitleNoProfile => 'Plex এর সাথে সাইন আপ করুন বা Jellyfin বা Emby সার্ভারের সাথে সংযোগ করুন';
	@override String addConnectionSubtitleScoped({required Object displayName}) => '${displayName}: Plex, Jellyfin, Emby, বা অন্য প্রোফাইল সংযোগে যোগ করুন';
	@override String sessionExpiredOne({required Object name}) => 'সংখ্যা: ${name}';
	@override String sessionExpiredMany({required Object count}) => 'সার্ভার ${count} জন্য সেশন শেষ';
	@override String accessDeniedOne({required Object name}) => '${name} এই অ্যাকাউন্টের জন্য অ্যাক্সেস বাতিল';
	@override String accessDeniedMany({required Object count}) => '${count} সার্ভার এই অ্যাকাউন্টের জন্য অ্যাক্সেস বাতিল';
	@override String get signInAgain => 'আবার লিখুন';
	@override String editMediaBrowserTitle({required Object product}) => 'Edit ${product} সংযোগ';
	@override String editMediaBrowserIntro({required Object serverName}) => '${serverName} এর জন্য URLগুলি যোগ করুন বা মুছে ফেলুন. PlezyNG সবচেয়ে কম ল্যাটিংসের সাথে পৌঁছাতে পারে URLগুলি ব্যবহার করবে।';
}

// Path: accountPreferences
class _Translations$accountPreferences$bn extends Translations$accountPreferences$en {
	_Translations$accountPreferences$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'অ্যাকাউন্ট পছন্দ';
	@override String hubSubtitleSingle({required Object account}) => 'অডিও, সাবটাইট এবং লাইব্রেরি বিকল্পগুলি ${account} এ সংরক্ষিত';
	@override String hubSubtitleMultiple({required Object count}) => 'অডিও, সাবটাইট এবং লাইব্রেরি বিকল্পগুলি ${count} অ্যাকাউন্টগুলিতে সংরক্ষিত';
	@override String get pickAccount => 'প্রতিটি অ্যাকাউন্ট তার নিজের প্রিয়মেন্টগুলি সংরক্ষণ করে. সংশোধন করার জন্য একটি নির্বাচন করুন.';
	@override String get storedOnAccount => 'এই অ্যাকাউন্টের নিজে থেকে এই অ্যাকাউন্টগুলি সংরক্ষণ করা হয়, তাই এতে প্রবেশিত প্রতিটি অ্যাপটি তাদের ব্যবহার করে - আপনার অন্যান্য ডিভাইসগুলিতে PlezyNG অন্তর্ভুক্ত।';
	@override String get noAccounts => 'কোন অ্যাকাউন্ট সংগঠন করা যায় না';
	@override String get noAccountsHint => 'Plex এ প্রবেশ করুন, অথবা Jellyfin বা Emby সার্ভারের সাথে সংযোগ করুন, এবং এই অ্যাকাউন্টে সংরক্ষিত পছন্দগুলি এখানে প্রদর্শন করা হয়।';
	@override String get unavailable => 'এই অ্যাকাউন্টে পৌঁছাতে পারবেন না';
	@override String get loadFailed => 'এই পছন্দগুলি আপলোড করতে পারবেন না';
	@override String get noPreference => 'কোন প্রিয়তা নেই';
	@override String get notSet => 'সিস্টেম না';
	@override late final _Translations$accountPreferences$groups$bn groups = _Translations$accountPreferences$groups$bn._(_root);
	@override String get preferredAudioLanguage => 'অডিও ভাষা প্রিয়';
	@override String get autoSelectAudio => 'ভাষা অনুযায়ী অডিও নির্বাচন করুন';
	@override String get autoSelectAudioDescription => 'কোনও অডিও ট্র্যাক ফাইলটি ডিফল্ট হিসাবে চিহ্নিত রাখে।';
	@override String get preferredSubtitleLanguage => 'পছন্দের ভাষা Subtitle';
	@override String get subtitleMode => 'Subtitles এর উপর';
	@override late final _Translations$accountPreferences$subtitleModes$bn subtitleModes = _Translations$accountPreferences$subtitleModes$bn._(_root);
	@override String get subtitleAccessibility => 'SDH সাব্টিটিস';
	@override late final _Translations$accountPreferences$subtitleAccessibilityOptions$bn subtitleAccessibilityOptions = _Translations$accountPreferences$subtitleAccessibilityOptions$bn._(_root);
	@override String get forcedSubtitles => 'নির্যাতন সূত্র';
	@override late final _Translations$accountPreferences$forcedSubtitleOptions$bn forcedSubtitleOptions = _Translations$accountPreferences$forcedSubtitleOptions$bn._(_root);
	@override String get displayMissingEpisodes => 'হারিয়ে যাওয়া ঘটনা দেখুন';
	@override String get displayMissingEpisodesDescription => 'তালিকাভুক্ত পরিস্থিতিগুলি সার্ভার সম্পর্কে জানে কিন্তু ফাইল নেই।';
	@override String get hidePlayedInLatest => 'সর্বশেষ নিবন্ধে দেখানো পণ্য মেরে';
	@override String get hidePlayedInLatestDescription => 'আপনি সার্ভার সর্বশেষ রানগুলি থেকে আগেই দেখেছেন পণ্যগুলি বের করুন।';
	@override String get displayCollectionsView => 'সংগ্রহের দৃশ্য দেখুন';
	@override String get displayCollectionsViewDescription => 'সার্ভারের সংগ্রহগুলি দেখার জন্য আপনার লাইব্রেরিগুলির পাশে সরবরাহ করুন।';
	@override String get rewatchingInNextUp => 'পরবর্তী পরবর্তী পরবর্তী পরবর্তী পরবর্তী পরবর্তী';
	@override String get rewatchingInNextUpDescription => 'একবার আপনি একটি প্রদর্শন শেষ করে, এটি আবার শুরু করুন এবং পরবর্তী প্রদর্শনের পরিবর্তে পরবর্তী প্রদর্শন অনুসরণ করে।';
	@override String get watchedIndicator => 'দেখে নিন প্রদর্শক';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$bn watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$bn._(_root);
	@override String get mediaReviewsVisibility => 'রিটিং & বিবেচনা';
	@override late final _Translations$accountPreferences$mediaReviewsOptions$bn mediaReviewsOptions = _Translations$accountPreferences$mediaReviewsOptions$bn._(_root);
	@override String get preferredAudioLanguageDescription => 'সার্ভার বা প্লেয়ার স্বয়ংক্রিয়ভাবে ট্র্যাক বেছে নিলে এই ভাষার অডিও ট্র্যাককে অগ্রাধিকার দিন।';
	@override String get preferredSubtitleLanguageDescription => 'স্বয়ংক্রিয়ভাবে নিম্নলিখিত অনুসরণগুলি এই ভাষায় পছন্দ করা হয়, যখন নিম্নিটিগুলি নির্বাচন করা হয়।';
	@override String get subtitleAccessibilityDescription => 'স্বয়ংক্রিয় সাব্টাইট নির্বাচন করার সময় SDH ক্যাপশনগুলি পছন্দ করা হয় বা প্রয়োজন হয় কিনা সিদ্ধান্ত নিতে হবে।';
	@override String get forcedSubtitleDescription => 'স্বয়ংক্রিয়ভাবে ট্র্যাক বেছে নেওয়ার সময় ফোর্সড সাবটাইটেল পছন্দ হবে নাকি অবশ্যই ব্যবহার করতে হবে, তা বেছে নিন।';
	@override String get watchedIndicatorDescription => 'সার্ভার ইন্টারফেসে কোন মিডিয়া টাইপগুলি একটি অনুসন্ধানিত চেকমার্ক পাবেন নির্বাচন করুন।';
	@override String get mediaReviewsVisibilityDescription => 'নির্বাচন করুন যে সার্ভার মিডিয়া পৃষ্ঠাগুলিতে প্রদর্শিত аудитории এবং মূল্যায়ন।';
	@override String get subtitleModeDescription => 'এই সার্ভার অ্যাকাউন্টের জন্য স্বয়ংক্রিয়ভাবে কখন উপ-টাইটিল চালু হয় তা নির্বাচন করুন।';
	@override String get hubDescription => 'এই পছন্দগুলো আপনার মিডিয়া সার্ভার অ্যাকাউন্টে সংরক্ষিত থাকে এবং অন্যান্য ক্লায়েন্টেও প্রযোজ্য হতে পারে।';
}

// Path: discover
class _Translations$discover$bn extends Translations$discover$en {
	_Translations$discover$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'খোঁজ';
	@override String get noContentAvailable => 'কোন উপাদান পাওয়া যায় না';
	@override String get addMediaToLibraries => 'আপনার লাইব্রেরিতে কিছু মিডিয়া যোগ করুন';
	@override String get continueWatching => 'দেখা অব্যাহত রাখুন';
	@override String continueWatchingIn({required Object library}) => 'এখনও দেখুন ${library}';
	@override String get nextUp => 'পরবর্তী';
	@override String nextUpIn({required Object library}) => 'পরবর্তী সংবাদ ${library}';
	@override String get recentlyAdded => 'সম্প্রতি যোগ করা';
	@override String recentlyAddedIn({required Object library}) => 'সম্প্রতি যোগ করা হয়েছে ${library}';
	@override String latestAlbumsIn({required Object library}) => 'সর্বশেষ অ্যালবামগুলি ${library}';
	@override String recentlyPlayedIn({required Object library}) => 'সম্প্রতি খেলা ${library}';
	@override String mostPlayedIn({required Object library}) => 'সবচেয়ে বেশি খেলা ${library}';
	@override String playEpisode({required Object season, required Object episode}) => 'সিজন ${season} পর্ব ${episode}';
	@override String get overview => 'বিবরণ';
	@override String get cast => 'কাস্ট';
	@override late final _Translations$discover$findNext$bn findNext = _Translations$discover$findNext$bn._(_root);
	@override String get extras => 'ট্রাইলিং & অতিরিক্ত';
	@override String get studio => 'স্টুডিও';
	@override String get rating => 'রেটিং';
	@override String get director => 'পরিচালক';
	@override String get directors => 'পরিচালকবৃন্দ';
	@override String get movie => 'চলচ্চিত্র';
	@override String get tvShow => 'টেলিভিশন প্রদর্শন';
	@override String minutesLeft({required Object minutes}) => '${minutes} মিনিট left';
	@override String get moreLikeThis => 'এ ধরনের আরও';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} নাম',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} টাইম',
	);
	@override late final _Translations$discover$person$bn person = _Translations$discover$person$bn._(_root);
}

// Path: errors
class _Translations$errors$bn extends Translations$errors$en {
	_Translations$errors$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'অনুসন্ধান ভুল হয়েছে: ${error}';
	@override String get searchUnavailable => 'কোন মিডিয়া সার্ভারে অনুসন্ধান পাওয়া যায়নি।';
	@override String connectionTimeout({required Object context}) => 'লোডিং সময়মাত্রা ${context}';
	@override String get connectionFailed => 'মিডিয়া সার্ভারের সাথে যোগাযোগ করতে পারবেন না';
	@override String unableToLoad({required Object context}) => '${context} পুনরায় চেষ্টা করুন।';
	@override String get noClientAvailable => 'কোন গ্রাহক পাওয়া যায় না';
	@override String get pleaseEnterToken => 'দয়া করে একটি টকেন লিখুন';
	@override String get invalidToken => 'অসুবিধা টকেন';
	@override String failedToVerifyToken({required Object error}) => 'টকেন সনাক্ত করতে পারিনি: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'পাশাপাশি পাশাপাশি পাশাপাশি ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'অপসারণ করা হয় না ${displayName}';
	@override String get failedToRate => 'Rating আপডেট করতে পারবেন না';
	@override String get reasonTimedOut => 'সংযোগের সময় বের করা হয়েছে';
	@override String get reasonUnreachable => 'সার্ভার পৌঁছাতে পারিনি।';
	@override String get reasonRefused => 'সার্ভার এই অনুরোধটি অস্বীকার করেছে।';
	@override String get reasonNotFound => 'আর সার্ভারে থাকে না।';
	@override String get reasonServerError => 'সার্ভারটি ভুল জানায়';
	@override String get reasonCancelled => 'অনুরোধ বাতিল করা হয়েছে';
	@override String get reasonUnexpected => 'অপ্রত্যাশিত ভুল ঘটেছে।';
}

// Path: libraries
class _Translations$libraries$bn extends Translations$libraries$en {
	_Translations$libraries$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => 'একটি random movie খেলুন';
	@override String get randomPickFailed => 'এই লাইব্রেরি থেকে একটি অসাধারণ সিনেমা নির্বাচন করতে পারবেন না।';
	@override String get title => 'বইয়েরা';
	@override String get fallbackTitle => 'লাইব্রেরি';
	@override String get scanLibraryFiles => 'স্ক্যান লাইব্রেরি ফাইল';
	@override String get scanLibrary => 'স্ক্যান লাইব্রেরি';
	@override String get analyze => 'বিশ্লেষণ';
	@override String get analyzeLibrary => 'বিবেচনা লাইব্রেরি';
	@override String get refreshMetadata => 'মেটাদাডেট ফ্রিজ করুন';
	@override String get emptyTrash => 'ভূষণ ট্রাস';
	@override String emptyingTrash({required Object title}) => '“${title}” এর জন্য মুক্ত পুষ্টি...';
	@override String trashEmptied({required Object title}) => '‘${title}’ এর জন্য ট্র্যাশ প্রচারিত';
	@override String failedToEmptyTrash({required Object error}) => 'ভেঙে ফাঁস করতে পারিনি: ${error}';
	@override String analyzing({required Object title}) => '‘${title}’ তালিকাভুক্ত';
	@override String analysisStarted({required Object title}) => '"${title}" জন্য বিশ্লেষণ শুরু';
	@override String failedToAnalyze({required Object error}) => 'লাইব্রেরি বিশ্লেষণ করতে পারিনি: ${error}';
	@override String get noLibrariesFound => 'কোন লাইব্রেরি পাওয়া যায়নি';
	@override String get allLibrariesHidden => 'সব লাইব্রেরি ভেঙে গেছে';
	@override String hiddenLibrariesCount({required Object count}) => 'লুকানো লাইব্রেরি (${count})';
	@override String get thisLibraryIsEmpty => 'এই লাইব্রেরি ভেঙে গেছে';
	@override String get noItemsMatchFilters => 'কোন পণ্য সক্রিয় ফিল্টার সমাধান না';
	@override String get resetFilters => 'ফিল্টার ফিল্টার';
	@override String get all => 'সবগুলি';
	@override String get clearAll => 'সবকিছু পরিষ্কার';
	@override String scanLibraryConfirm({required Object title}) => 'আপনি কি নিশ্চিত যে আপনি "${title}" স্ক্যান করতে চান?';
	@override String analyzeLibraryConfirm({required Object title}) => 'আপনি কি নিশ্চিত যে আপনি "${title}" বিশ্লেষণ করতে চান?';
	@override String refreshMetadataConfirm({required Object title}) => 'আপনি কি "${title}" জন্য metadata আপডেট করতে চান তা নিশ্চিত?';
	@override String emptyTrashConfirm({required Object title}) => 'আপনি কি "${title}" এর জন্য শূন্য বর্জ্য খুঁজে পেতে চান?';
	@override String get manageLibraries => 'লাইব্রেরি পরিচালনা';
	@override String get sort => 'সারাদেশ';
	@override String get sortBy => 'সারাদেশে';
	@override String get filters => 'ফিল্টারগুলি';
	@override String get confirmActionMessage => 'আপনি কি নিশ্চিত যে আপনি এই কাজটি করতে চান?';
	@override String get showLibrary => 'লাইব্রেরি দেখুন';
	@override String get hideLibrary => 'কবর লাইব্রেরি';
	@override String get libraryOptions => 'লাইব্রেরি বিকল্প';
	@override String get content => 'লাইব্রেরি বিষয়বস্তু';
	@override String get selectLibrary => 'লাইব্রেরি নির্বাচন';
	@override String filtersWithCount({required Object count}) => 'ফিল্টার (${count})';
	@override String get noRecommendations => 'উপলব্ধি নেই';
	@override String get noCollections => 'এই লাইব্রেরিতে কোন সংগ্রহ নেই';
	@override String get noFoldersFound => 'কোন ফাইল পাওয়া যায়নি';
	@override String get folders => 'ফোল্ডার';
	@override late final _Translations$libraries$tabs$bn tabs = _Translations$libraries$tabs$bn._(_root);
	@override late final _Translations$libraries$groupings$bn groupings = _Translations$libraries$groupings$bn._(_root);
	@override late final _Translations$libraries$filterCategories$bn filterCategories = _Translations$libraries$filterCategories$bn._(_root);
	@override late final _Translations$libraries$sortLabels$bn sortLabels = _Translations$libraries$sortLabels$bn._(_root);
	@override late final _Translations$libraries$advancedFilters$bn advancedFilters = _Translations$libraries$advancedFilters$bn._(_root);
	@override late final _Translations$libraries$selection$bn selection = _Translations$libraries$selection$bn._(_root);
}

// Path: about
class _Translations$about$bn extends Translations$about$en {
	_Translations$about$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'সম্পর্কে';
	@override String get openSourceLicenses => 'খোলা সূত্র লাইসেন্স';
	@override String versionLabel({required Object version}) => 'সংস্করণ ${version}';
	@override String get appDescription => 'Flutter জন্য একটি সুন্দর Plex, Jellyfin, এবং Emby গ্রাহক';
	@override String get viewLicensesDescription => 'তৃতীয় পক্ষের লাইসেন্সগুলি দেখুন';
	@override String get privacyPolicy => 'গোপনীয়তা নীতি';
}

// Path: serverSelection
class _Translations$serverSelection$bn extends Translations$serverSelection$en {
	_Translations$serverSelection$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'কোন সার্ভার পাওয়া যায় না ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'সার্ভারগুলি লোড করতে পারেনি: ${error}';
	@override String get noValidServers => 'এই অ্যাকাউন্টে কোন ব্যবহারযোগ্য সার্ভার পাওয়া যায়নি';
}

// Path: hubDetail
class _Translations$hubDetail$bn extends Translations$hubDetail$en {
	_Translations$hubDetail$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Title নাম';
	@override String get releaseYear => 'মুক্তিযোদ্ধা বছর';
	@override String get dateAdded => 'তারিখে এসেছে';
	@override String get rating => 'রেটিং';
	@override String get noItemsFound => 'খুঁজে পাওয়া যায় না পণ্য';
}

// Path: logs
class _Translations$logs$bn extends Translations$logs$en {
	_Translations$logs$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'স্পষ্ট লগ';
	@override String get copyLogs => 'লগ কপি';
	@override String get uploadLogs => 'লগ আপলোড';
	@override String get saveLogs => 'ফাইলে লগ সুরক্ষা করুন';
	@override String logsSaved({required Object path}) => 'লগগুলি সংরক্ষিত হয়েছে ${path}';
	@override String get saveLogsFailed => 'লগ ফাইল সংরক্ষণ করতে পারেনি।';
}

// Path: startup
class _Translations$startup$bn extends Translations$startup$en {
	_Translations$startup$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'PlezyNG শুরু করতে পারেনি';
	@override String get failedBody => 'স্টার্টপোর্টের সময় কিছু ভুল হয়েছিল. নিচের বিস্তারিতগুলি কী ভুল হয়েছে তা সংজ্ঞা করে।';
	@override String get failedBodyRepairable => 'PlezyNG-এর সংরক্ষিত সেটিংস ফাইলটি ক্ষতিগ্রস্ত। অ্যাপ চালুর আগে এটি আবার তৈরি করতে হবে। আবার চেষ্টা করলে কাজ হবে না — স্টোরেজ মেরামতের বিকল্পটি বেছে নিন।';
	@override String get phaseLabel => 'পদক্ষেপ';
	@override String get showDetails => 'বিস্তারিত দেখুন';
	@override String get hideDetails => 'গোপন বিস্তারিত';
	@override String get copyDetails => 'কপি ডেটা';
	@override String get detailsCopied => 'ক্লিপবোর্ডে কপি করা তথ্য';
	@override String get uploadDetails => 'আপলোড ডেটা';
	@override String get repairStorage => 'পুনরাবৃত্তি সংরক্ষণ';
	@override String get repairTitle => 'রক্ষা করা ডেটা কি?';
	@override String get repairBodyCommon => 'PlezyNG-এর সেটিংস ফাইলটি ক্ষতিগ্রস্ত এবং পড়া যাচ্ছে না। মেরামত করলে সব সেটিংস ডিফল্ট মানে ফিরে যাবে।';
	@override String get repairBodyOneCredential => 'সংরক্ষিত সাইন-ইনের একটি তথ্য ক্ষতিগ্রস্ত এবং পড়া যাচ্ছে না। মেরামত করলে শুধু সেটিই মুছে যাবে; অন্য সেটিংস বদলাবে না।';
	@override String get repairBodySignInsKept => 'আপনার সার্ভার ও প্রোফাইলগুলিতে সাইন-ইন অবস্থা বজায় থাকার কথা।';
	@override String get repairBodySignInsLost => 'সংরক্ষিত সাইন-ইনের তথ্য রক্ষা করার চাবিটি এই ফাইল থেকে পুনরুদ্ধার করা যাচ্ছে না। তাই প্রতিটি সার্ভার ও প্রোফাইলে আবার সাইন ইন করতে হবে। মিডিয়া সার্ভারে কিছুই প্রভাবিত হবে না।';
	@override String get repairBodySessionsUncertain => 'ট্র্যাকার (MAL, AniList, Simkl, Trakt) এবং Seerr-এর তথ্য আলাদাভাবে সংরক্ষিত থাকে এবং তা অক্ষত থাকতেও পারে, নাও পারে। PlezyNG ঠিক কোন তথ্য রেখেছে তা আপনাকে জানাবে।';
	@override String get repairConfirm => 'পুনরায়';
	@override String get repairSucceeded => 'রেকর্ড করা হয়েছে';
	@override String get repairNeedsRestart => 'পুনরাবৃত্তি প্রয়োজন – Repair Required';
	@override String get restartRequiredBody => 'আপনার তথ্য মেরামত করা হয়েছে, তবে তা ব্যবহার করতে PlezyNG আবার চালু করতে হবে। PlezyNG বন্ধ করে আবার খুলুন।';
	@override String get quitPlezy => 'ফাঁস PlezyNG';
	@override String get repairFailed => 'পুনরাবৃত্তি ভুল';
	@override String get repairKeptSignIns => 'আপনার সার্ভার ও প্রোফাইলগুলিতে এখনও সাইন ইন করা আছে।';
	@override String get repairLostSignIns => 'আপনার সুরক্ষিত সাইন ইন সুরক্ষার চিঠি পুনরাবৃত্তি করা যাবে না. আপনাকে প্রতিটি সার্ভার এবং প্রোফাইলে আবার সাইন আপ করতে হবে।';
	@override String get repairLostSessions => 'কমপক্ষে একটি ট্র্যাকার বা Seerr সংযোগ হারিয়ে গেছে এবং আবার সংযোগ করতে হবে।';
	@override String get backupTitle => 'ক্ষতিগ্রস্ত ফাইলের একটি কপি সংরক্ষণ করা হয়েছে';
	@override String get backupWarning => 'এতে আপনার সাইন-ইন তথ্য রয়েছে। এটি আপলোড বা শেয়ার করবেন না।';
	@override String get deleteBackup => 'কপি মুছে ফেলুন';
	@override String get backupDeleted => 'কপি মুছে ফেলুন';
	@override String get previousFailureTitle => 'PlezyNG শেষবার শুরু করতে পারিনি';
}

// Path: licenses
class _Translations$licenses$bn extends Translations$licenses$en {
	_Translations$licenses$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'সম্পর্কিত প্যাকেজ';
	@override String get license => 'লাইসেন্স';
	@override String licenseNumber({required Object number}) => 'লাইসেন্স ${number}';
	@override String licensesCount({required Object count}) => '${count} লাইসেন্স';
}

// Path: navigation
class _Translations$navigation$bn extends Translations$navigation$en {
	_Translations$navigation$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'বইয়েরা';
	@override String get downloads => 'ডাউনলোড';
	@override String get liveTv => 'লাইভ টিভি';
	@override String get explore => 'গবেষণা';
}

// Path: explore
class _Translations$explore$bn extends Translations$explore$en {
	_Translations$explore$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$explore$mdblistShelves$bn mdblistShelves = _Translations$explore$mdblistShelves$bn._(_root);
	@override String get title => 'গবেষণা';
	@override String get selectSource => 'সূত্র নির্বাচন';
	@override late final _Translations$explore$rows$bn rows = _Translations$explore$rows$bn._(_root);
	@override late final _Translations$explore$status$bn status = _Translations$explore$status$bn._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} আয়াত',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} প্রদর্শন',
	);
	@override String get cast => 'কাস্ট';
	@override String get characters => 'চরিত্র';
	@override String get addToWatchlist => 'Watchlist এ যোগ করুন';
	@override String get removeFromWatchlist => 'Watchlist থেকে মুছে ফেলুন';
	@override String get addedToWatchlist => 'Watchlist এ যোগ করা';
	@override String get removedFromWatchlist => 'Watchlist থেকে মুছে ফেলুন';
	@override String get watchlistUpdateFailed => 'Watchlist আপডেট করতে পারবেন না';
	@override String get watchlistNoMatch => 'এই পণ্যটি একটি চোখের তালিকাতে সমন্বয় করতে পারবে না';
	@override String get notInLibrary => 'আপনার লাইব্রেরিতে নয়';
	@override String get inTheseLibraries => 'এই লাইব্রেরিতে';
	@override String get checkingLibrary => 'আপনার লাইব্রেরি চেক করুন';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} সার্ভার চেক করতে পারবেন না',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} সার্ভারগুলি চেক করতে পারেনি',
	);
	@override String get emptyTitle => 'এখনো এখানে কিছু নেই';
	@override String emptyMessage({required Object source}) => '${source} এর রুটিগুলি একবার এখানে প্রদর্শন করা হবে।';
	@override String searchHint({required Object source}) => 'খুঁজে পেতে ${source}';
	@override String searchEmpty({required Object query}) => '"${query}" এর জন্য কোন ফলাফল নেই';
	@override String searchPrompt({required Object source}) => 'সিনেমা ও প্রদর্শনীগুলি খুঁজে পেতে ${source} এর মাধ্যমে।';
	@override String get searchFailed => 'অনুসন্ধান ভুল হয়ে গেছে. আপনার সংযোগ চেক করুন এবং আবার চেষ্টা করুন.';
	@override late final _Translations$explore$badge$bn badge = _Translations$explore$badge$bn._(_root);
	@override late final _Translations$explore$stats$bn stats = _Translations$explore$stats$bn._(_root);
	@override late final _Translations$explore$season$bn season = _Translations$explore$season$bn._(_root);
	@override late final _Translations$explore$format$bn format = _Translations$explore$format$bn._(_root);
	@override late final _Translations$explore$sourceMaterial$bn sourceMaterial = _Translations$explore$sourceMaterial$bn._(_root);
	@override late final _Translations$explore$creditRole$bn creditRole = _Translations$explore$creditRole$bn._(_root);
	@override late final _Translations$explore$relation$bn relation = _Translations$explore$relation$bn._(_root);
	@override String broadcast({required Object day, required Object time}) => 'Airs ${day} এ ${time}';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => '${day} ${time} ${timezone}-এ প্রচারিত হয়';
	@override late final _Translations$explore$detail$bn detail = _Translations$explore$detail$bn._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ফলাফল',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ফলাফল',
	);
}

// Path: liveTv
class _Translations$liveTv$bn extends Translations$liveTv$en {
	_Translations$liveTv$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'লাইভ টিভি';
	@override String get guide => 'গাইড';
	@override String get noChannels => 'কোন চ্যানেল পাওয়া যায় না';
	@override String get noDvr => 'কোন সার্ভারে DVR সংগঠিত হয় না';
	@override String get serverUnavailable => 'লাইভ টিভি সার্ভার পাওয়া যায় না।';
	@override String get serverNotConnected => 'লাইভ টিভি সার্ভার সংযুক্ত নয়।';
	@override String get noPrograms => 'কোন প্রোগ্রাম ডেটা পাওয়া যায় না';
	@override String get liveStreamFailed => 'Live Stream হারিয়েছে';
	@override String get unknownProgram => 'অজ্ঞাত প্রোগ্রাম';
	@override String get timelineLiveProgram => 'Live প্রোগ্রাম (Playback এই প্রোগ্রামের বাইরে হতে পারে)';
	@override String get timelineBuffer => 'টাইমলাইন বাফার';
	@override String get timelineUnavailable => 'টাইম লাইন অসম্ভব';
	@override String get timelineEstimated => 'বিবেচনা Playback';
	@override String get timelinePending => 'খুঁজে বের';
	@override String get timelineStale => 'পরিস্থিতি অতীত হতে পারে';
	@override String get unknownHub => 'অজানা';
	@override String get unknownError => 'অজ্ঞাত ভুল';
	@override String channelNumber({required Object number}) => 'চ্যানেল ${number}';
	@override String get unknownChannel => 'অজ্ঞাত চ্যানেল';
	@override String get live => 'লাইভ';
	@override String get premiereBadge => 'নতুন';
	@override String get reloadGuide => 'রেলোড গাইড';
	@override String get searchGuide => 'অনুসন্ধান গাইড';
	@override String get searchHint => 'চ্যানেল এবং প্রোগ্রাম';
	@override String searchNoResults({required Object query}) => '‘${query}’ এর জন্য কোন খেলা নেই';
	@override String get channelsSection => 'চ্যানেলগুলো';
	@override String get programsSection => 'প্রোগ্রাম';
	@override String get now => 'এখন';
	@override String get today => 'আজ';
	@override String get tomorrow => 'আগামীকাল';
	@override String get midnight => 'মধ্য রাতে';
	@override String get overnight => 'রাতে';
	@override String get morning => 'সকালে';
	@override String get daytime => 'দিনের সময়';
	@override String get evening => 'রাতে';
	@override String get lateNight => 'দীর্ঘ রাতে';
	@override String get whatsOn => 'কী আছে';
	@override String get watchChannel => 'চ্যানেল দেখুন';
	@override String get favorites => 'পছন্দগুলি';
	@override String get reorderFavorites => 'পছন্দের রেকর্ড';
	@override String get noFavoriteChannels => 'প্রিয় চ্যানেল নেই';
	@override String get noFavoriteChannelsHint => 'সব চ্যানেলগুলি দেখুন, তারপর একটি চ্যানেলটি দীর্ঘ চ্যানেলে প্রদর্শন করুন যাতে আপনার প্রিয়দের সাথে যোগ করুন।';
	@override String get showAllChannels => 'সব চ্যানেল দেখুন';
	@override String get favoritesLoadFailed => 'আপনি পছন্দ করতে পারেন না. আপনার সংযোগ চেক করুন এবং আবার চেষ্টা করুন.';
	@override String get favoritesUpdateFailed => 'আপডেট করতে পারেন না প্রিয়. আপনার সংযোগ চেক করুন এবং আবার চেষ্টা করুন।';
	@override String get joinSession => 'প্রসেসে অংশগ্রহণ';
	@override String watchFromStart({required Object minutes}) => 'শুরু থেকে দেখুন (${minutes} মিনিট আগে)';
	@override String get watchLive => 'দেখুন Live';
	@override String get goToLive => 'বেঁচে থাকুন';
	@override String get record => 'রেকর্ড';
	@override String get recordEpisode => 'রেকর্ড এজেন্ট';
	@override String get recordSeries => 'রেকর্ড সিরিজ';
	@override String get recordOptions => 'রেকর্ড বিকল্প';
	@override String get saveTo => 'সুরক্ষা';
	@override String get recordings => 'রেকর্ডিং';
	@override String get scheduledRecordings => 'পরিকল্পনা';
	@override String get recordingRules => 'রেকর্ডিং নিয়ম';
	@override String get noScheduledRecordings => 'রেকর্ড করার জন্য কিছুই না';
	@override String get manageRecording => 'রেকর্ড পরিচালনা';
	@override String get cancelRecording => 'রেকর্ড বন্ধ করুন';
	@override String get cancelRecordingTitle => 'এই রেকর্ডটি বাতিল করবেন?';
	@override String cancelRecordingMessage({required Object title}) => '${title} এখন আর রেকর্ড করা হবে না।';
	@override String get deleteRule => 'নিয়ম মুছে ফেলুন';
	@override String get deleteRuleTitle => 'রেকর্ডিং নিয়ম কি মুছে ফেলবে?';
	@override String deleteRuleMessage({required Object title}) => '${title}-এর পরবর্তী পর্বগুলি রেকর্ড করা হবে না।';
	@override String get recordingScheduled => 'রেকর্ডার পরিকল্পনা';
	@override String get alreadyScheduled => 'এই প্রোগ্রামটি এখনও পরিকল্পিত';
	@override String get dvrAdminRequired => 'DVR সিস্টেমগুলি একটি admin অ্যাকাউন্ট প্রয়োজন';
	@override String get recordingFailed => 'রেকর্ড করতে পারিনি';
	@override String get recordingTargetMissing => 'রেকর্ডিং লাইব্রেরি নির্ধারণ করতে পারত না';
	@override String get recordNotAvailable => 'এই প্রোগ্রামের জন্য রেকর্ড পাওয়া যায় না';
	@override String get recordingCancelled => 'রেকর্ড বাতিল';
	@override String get recordingRuleDeleted => 'রেকর্ড নিয়ম মুছে ফেলেন';
	@override String get processRecordingRules => 'নিয়মের পুনরায় মূল্যায়ন';
	@override String get recordingInProgress => 'এখন রেকর্ড করুন';
	@override String recordingsCount({required Object count}) => '${count} পরিকল্পনা';
	@override String get editRule => 'Edit নিয়ম';
	@override String get editRuleAction => 'এডিট';
	@override String get recordingRuleUpdated => 'রেকর্ড নিয়ম আপডেট';
	@override String get guideReloadRequested => 'গাইড ফ্রিজ অনুরোধ';
	@override String get guideReloadFailed => 'গাইড খুন করতে পারিনি।';
	@override String get rulesProcessRequested => 'পরবর্তী নিয়ম বিবেচনার দাবি';
	@override String get rulesProcessFailed => 'রেকর্ডিং নিয়মগুলি পুনরায় মূল্যায়ন করতে পারবেন না';
	@override String get recordShow => 'রেকর্ড প্রদর্শন';
	@override late final _Translations$liveTv$recordSettings$bn recordSettings = _Translations$liveTv$recordSettings$bn._(_root);
	@override String startingInMinutes({required Object minutes}) => 'শুরু হয় ${minutes} মিনিট';
	@override String dayAtTime({required Object day, required Object time}) => '${day} এ ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} অনিবার্য লাইভ টেলিভিশন প্লাইব্যাক ডেটা ফেরত';
	@override String get failedToStartChannel => 'লাইভ চ্যানেল শুরু করতে পারবেন না।';
	@override String get failedToBuildStreamUrl => 'URL এর প্রদর্শন করতে পারবেন না';
	@override String playbackStartFailed({required Object reason}) => 'চ্যানেলটি শুরু করতে পারেনি: ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'চ্যানেল পরিবর্তন করতে পারবেন না: ${reason}';
}

// Path: collections
class _Translations$collections$bn extends Translations$collections$en {
	_Translations$collections$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'কালেকশন';
	@override String get collection => 'সংগ্রহ';
	@override String get empty => 'সংগ্রহ ভূষণ';
	@override String get deleteCollection => 'রেকর্ড 삭제';
	@override String deleteConfirm({required Object title}) => '"${title}" মুছে ফেলবেন? এই কাজ আর পূর্বাবস্থায় ফেরানো যাবে না।';
	@override String get deleted => 'সংগ্রহ 삭제';
	@override String get deleteFailed => 'সংগ্রহের অপসারণ করতে পারেনি';
	@override String deleteFailedWithError({required Object error}) => 'সংগ্রহের অপসারণ করা হয় না: ${error}';
	@override String get selectCollection => 'ক্যালেকশন নির্বাচন';
	@override String get collectionName => 'সংগ্রহ নাম';
	@override String get enterCollectionName => 'সংগ্রহ নাম লিখুন';
	@override String get addedToCollection => 'সংগ্রহে যোগ করা';
	@override String get errorAddingToCollection => 'সংগ্রহে যোগ করতে পারিনি';
	@override String get created => 'সংগ্রহ তৈরি';
	@override String get removeFromCollection => 'সংগ্রহ থেকে বের করুন';
	@override String removeFromCollectionConfirm({required Object title}) => 'এই সংগ্রহ থেকে "${title}" মুছে ফেলুন?';
	@override String get removedFromCollection => 'সংগ্রহ থেকে বের করা';
	@override String get removeFromCollectionFailed => 'সংগ্রহ থেকে বের করা যায়নি';
	@override String removeFromCollectionError({required Object error}) => 'সংগ্রহ থেকে তুলনা ভুল: ${error}';
	@override String get searchCollections => 'খুঁজে পাওয়া সংগ্রহ...';
}

// Path: playlists
class _Translations$playlists$bn extends Translations$playlists$en {
	_Translations$playlists$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'খেলোয়াড়';
	@override String get playlist => 'প্লেলিস্ট';
	@override String get noPlaylists => 'খেলোয়াড় পাওয়া যায়নি';
	@override String get create => 'Playlist তৈরি করুন';
	@override String get playlistName => 'Playlist নাম';
	@override String get enterPlaylistName => 'Playlist নাম লিখুন';
	@override String get delete => 'Playlist খেলা';
	@override String get removeItem => 'Playlist থেকে মুছে ফেলুন';
	@override String get smartPlaylist => 'স্মার্ট Playlist';
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)}টি আইটেম',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)}টি আইটেম',
	);
	@override String get emptyPlaylist => 'এই খেলাটি खाली';
	@override String get deleteConfirm => 'Playlist খেলা?';
	@override String deleteMessage({required Object name}) => 'আপনি কি নিশ্চিত যে আপনি "${name}" মুছে ফেলতে চান?';
	@override String get created => 'Playlist তৈরি';
	@override String get deleted => 'Playlist 삭제';
	@override String get itemAdded => 'Playlist এ যোগ করা';
	@override String get itemRemoved => 'Playlist থেকে মুছে ফেলুন';
	@override String get selectPlaylist => 'Playlist নির্বাচন করুন';
	@override String get searchPlaylists => 'খেলা খেলা খেলা খেলা...';
	@override String get errorCreating => 'খেলা তালিকা তৈরি করতে পারিনি';
	@override String get errorDeleting => 'খেলা লিস্ট মুছে ফেলতে পারিনি';
	@override String get errorLoading => 'খেলনা লাইসেন্সগুলি লোড করতে পারিনি';
	@override String get errorAdding => 'খেলা লিস্টে যোগ করতে পারিনি';
	@override String get errorReordering => 'খেলা তালিকা পণ্য পুনরায় সংস্থা করতে পারেনি';
	@override String get errorRemoving => 'Playlist থেকে ফেরত না';
}

// Path: music
class _Translations$music$bn extends Translations$music$en {
	_Translations$music$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'অ্যালবামে যান';
	@override String get goToArtist => 'শিল্পীকে যান';
	@override String get instantMix => 'দ্রুত মিশন';
	@override String get playNext => 'Next খেলুন';
	@override String get addToQueue => 'কুকুরে যোগ করুন';
	@override String discNumber({required Object n}) => 'ডিজিটাল ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ট্র্যাক',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} পাসপোর্ট',
	);
	@override String get nowPlaying => 'এখন খেলতে';
	@override String playingFrom({required Object title}) => 'খেলা ${title} থেকে';
	@override String get queue => 'কুরআন';
	@override String get clearQueue => 'কিউগুলো মুছুন';
	@override String get lyrics => 'গানের কথা';
	@override String get visualizer => 'Visualizator';
	@override String get visualizerProfileLoading => 'Read track বিশ্লেষণ ...';
	@override String get visualizerAmbientMotion => 'পরিবেশ মোকাবিলা';
	@override String get visualizerPlexLoudness => 'Plex শব্দ';
	@override String get visualizerLiveAudio => 'লাইভ অডিও বিশ্লেষণ';
	@override String get visualizerPreviousPreset => 'পূর্ববর্তী চিত্র';
	@override String get visualizerNextPreset => 'পরবর্তী ভিজুয়াল স্টাইল';
	@override String get visualizerPresetAurora => 'অুরোরা';
	@override String get visualizerPresetBloom => 'ব্লম';
	@override String get visualizerPresetOrbitals => 'কক্ষপথ';
	@override String get visualizerPresetPrism => 'পুরস্কার';
	@override String get visualizerPresetTunnel => 'টুনেল';
	@override String get visualizerPresetTrackMap => 'ট্র্যাক ম্যাপ';
	@override String get noLyrics => 'কোন পাঠ্য নেই';
	@override String get sleepTimer => 'ঘুমের টাইম';
	@override String get sleepTimerEndOfTrack => 'ট্র্যাকের শেষ';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} মিনিট',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} মিনিট',
	);
	@override String get stopPlayback => 'Playback বন্ধ করুন';
	@override String get previousTrack => 'পূর্ববর্তী ট্র্যাক';
	@override String get nextTrack => 'পরবর্তী ট্র্যাক';
	@override String get repeat => 'বার্তা';
	@override String get repeatAll => 'প্রতিটি বার্তা';
	@override String get repeatOne => 'এক বার বার';
	@override String get instantMixNoServer => 'কোন সার্ভার অন্তত মিশ্রণ জন্য উপলব্ধ নয়';
	@override String get instantMixFailed => 'অন্তত মিশ্রণ করতে পারেনি।';
	@override String get instantMixEmpty => 'ফেরত এসেছিলেন ফেরত এসেছিলেন কোন পাসপোর্ট নেই।';
	@override String noAudioUrl({required Object track}) => 'কোন অডিও ইউরলি পাওয়া যায় না ${track}';
	@override late final _Translations$music$discography$bn discography = _Translations$music$discography$bn._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$bn extends Translations$watchTogether$en {
	_Translations$watchTogether$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'একসঙ্গে দেখুন';
	@override String get description => 'বন্ধু ও পরিবারের সাথে সিন্কের সাথে সামগ্রী দেখুন';
	@override String get createRoom => 'রুম তৈরি করুন';
	@override String get creatingRoom => 'রুম তৈরি করে...';
	@override String get joinRoom => 'ঘরে যোগ';
	@override String get joiningRoom => 'একত্রিত রুম...';
	@override String get connecting => 'সংযোগ...';
	@override String get relayPublic => 'রুমগুলি খোলা চোখের পার্থ রেলি ব্যবহার করে।';
	@override String relayCustom({required Object url}) => 'রুমগুলি আপনার রেলিটি ${url} এ ব্যবহার করে।';
	@override String get recentRooms => 'সাম্প্রতিক রুম';
	@override String get roomActions => 'রুম কার্যক্রম';
	@override String get renameRoom => 'রুমের নাম';
	@override String get removeRoom => 'সরান';
	@override String get enterRoomCode => 'হোস্ট থেকে 6 চরিত্র কোড প্রদান করুন।';
	@override String get roomCode => 'রুম কোড';
	@override String get paste => 'পেস্ট';
	@override String get noCodeInClipboard => 'ক্লাববের কোডে রুম কোড নেই।';
	@override String get copyCode => 'কপি কোড';
	@override String get codeCopied => 'রুম কোড কপি';
	@override String get shareInvite => 'বিতর্ক invitaciones';
	@override String get inviteCopied => 'কপি করুন, এটি একটি বার্তাে প্রবেশ করুন।';
	@override String inviteMessage({required Object code}) => 'PlezyNG: খুলুন ঘোড়ি একসাথে, চিহ্ন করুন ঘোড়ি একসাথে এবং ${code} এ প্রবেশ করুন।';
	@override String get openSessionControls => 'Open Watch Together সেশন কন্ট্রোল';
	@override String get reconnecting => 'আবার সংযোগ...';
	@override String get reconnectingDescription => 'সংযোগ বন্ধ হয়ে গেছে. আপনি স্বয়ংক্রিয়ভাবে রুমে যোগ দেবেন।';
	@override String get connected => 'সংযুক্ত';
	@override String get disconnected => 'বিচ্ছিন্ন';
	@override String get youAreHost => 'আপনি হোস্ট';
	@override String hostedBy({required Object name}) => 'হোস্ট করা হয়েছে ${name}';
	@override String get hostControlsPlayback => 'হোস্ট কন্ট্রোল Playback';
	@override String get anyoneCanControl => 'কেউ Playback নিয়ন্ত্রণ করতে পারেন';
	@override String get roomLocked => 'রুম বন্ধ';
	@override String get nowPlaying => 'এখন খেলতে';
	@override String get nothingPlaying => 'খেলতে কিছুই নেই';
	@override String get nothingPlayingHost => 'যে কোনো লাইব্রেরি থেকে কিছু খেলুন, এটি রুমের সাথে শেয়ার করুন।';
	@override String get nothingPlayingGuest => 'যখন হোস্ট কিছু খেলতে পারে, তখন এটি এখানে খোলা যায়।';
	@override String get notShareable => 'এই ভিডিওটি ক্যাটাগোজ ম্যাক নেই, তাই একই সার্ভার অ্যাক্সেসের সাথে কেবল মানুষ এটি খেলতে পারে।';
	@override String get searching => 'এই ভিডিওটি আপনার লাইব্রেরিতে খুঁজে পেয়ে...';
	@override String get yourCopy => 'আপনার কপি';
	@override String get sharingYourCopy => 'আপনি আপনার কপি শেয়ার করছেন';
	@override String playingOtherLength({required Object difference}) => 'আপনার কপি খেলতে, ${difference}';
	@override String get mismatchTitle => 'আপনার কপিটি ভিন্ন দীর্ঘতা।';
	@override String mismatchDescription({required Object difference}) => 'আপনার সবচেয়ে কাছাকাছি কপিটি রুমের ভিডিও থেকে ${difference}। এটি অন্য কেট বা সংস্করণ হতে পারে।';
	@override String get playAnyway => 'খেলুন যেকোনো';
	@override String get chooseAnotherCopy => 'অন্য কপি নির্বাচন করুন';
	@override String get dontPlay => 'খেলবেন না';
	@override String get unavailableTitle => 'আপনি এই ভিডিও নেই';
	@override String get unavailableDescription => 'PlezyNG আপনার লাইব্রেরিতে এটি খুঁজে পাওয়া যায়নি. নিজের জন্য একটি কপি বা আবার খুঁজে পেতে পারেন।';
	@override String get chooseCopy => 'একটি কপি নির্বাচন করুন';
	@override String get searchAgain => 'আবার খোঁজ';
	@override String get noCandidates => 'আপনার লাইব্রেরিতে কোন কপি পাওয়া যায়নি।';
	@override String get choiceFailed => 'রুমের জন্য এই কপি খেলতে পারত না';
	@override String lengthLonger({required Object duration}) => '${duration} আরও';
	@override String lengthShorter({required Object duration}) => '${duration} ছোট';
	@override String get lengthSame => 'একই দীর্ঘতা';
	@override String get lengthUnknown => 'অজানা দীর্ঘতা';
	@override String get joinCurrentPlayback => 'বর্তমান Playback';
	@override String get joinCurrentPlaybackDescription => 'ঘরবাড়ি ফিরে যান যা ঘরবাড়ি বর্তমানে দেখছে';
	@override String get stopMedia => 'সবাইকে ভিডিও বন্ধ করুন';
	@override String get syncOffset => 'সনাক্ত Offset';
	@override String get syncOffsetDescription => 'আপনার ভিডিওটি পরিবর্তন করুন যদি এটি রুমের সামনে বা পিছনে চলছে।';
	@override String offsetHint({required Object difference}) => 'আপনার কপিটি রুমের ভিডিও থেকে ${difference}।';
	@override String applyDifference({required Object offset}) => 'ব্যবহার করুন ${offset}';
	@override String get offsetMinusSecond => '1 স';
	@override String get offsetMinusTenth => '100 মিসি';
	@override String get offsetPlusTenth => '+100 মিসি';
	@override String get offsetPlusSecond => '+1 স';
	@override String get participants => 'অংশগ্রহণকারী';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} অংশগ্রহণকারী',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} অংশগ্রহণকারী',
	);
	@override String get hostBadge => 'হেস্ট';
	@override String nameYou({required Object name}) => '${name} (আপনি)';
	@override String get playerIdle => 'আইডেল';
	@override String get playerLoading => 'লোড';
	@override String get playerReady => 'প্রস্তুত';
	@override String get playerBuffering => 'বাফারিং';
	@override String get matchSearching => 'খোঁজ';
	@override String get matchMatched => 'ভিডিও আছে';
	@override String get matchMismatched => 'আলাদা দীর্ঘতা';
	@override String get matchUnavailable => 'ভিডিও নেই';
	@override String participantOffset({required Object offset}) => 'অফসেট ${offset}';
	@override String get makeHost => 'হেস্ট করুন';
	@override String get makeHostQuestion => 'স্থানান্তর হোস্ট?';
	@override String makeHostConfirm({required Object name}) => '${name} Playback নিয়ন্ত্রণ করবে এবং সেশনটি সবাইকে পরিচালনা করবে।';
	@override String get transfer => 'ট্রান্সফার';
	@override String get removeParticipant => 'রুম থেকে বের করুন';
	@override String removeParticipantQuestion({required Object name}) => '${name} রক্ষা করা?';
	@override String removeParticipantConfirm({required Object name}) => '${name} রুম ছেড়ে যায়. আপনি রুম বন্ধ না হলে তারা কোডের সাথে আবার যোগ করতে পারেন।';
	@override String get remove => 'সরান';
	@override String get roomSettings => 'রুমের সিস্টেম';
	@override String get letEveryoneControl => 'সবাই Playback নিয়ন্ত্রণ করুন';
	@override String get lockRoom => 'লক রুম';
	@override String get lockRoomDescription => 'নতুন কেউ যোগ দিতে পারে না।';
	@override String get leaveRoom => 'রুম ছেড়ে';
	@override String get leaveRoomQuestion => 'রুম ছেড়ে দেয়?';
	@override String get leaveRoomConfirm => 'আপনি আবারও রুম কোডের সাথে যোগ করতে পারেন।';
	@override String get leave => 'ছেড়ে';
	@override String get endRoom => 'শেষ রুম';
	@override String get endRoomQuestion => 'শেষ রুম?';
	@override String get endRoomConfirm => 'এতে সবাইকে রুমের শেষ হবে।';
	@override String get end => 'শেষ';
	@override String get playBlockedTitle => 'Playback শুরু হয়নি';
	@override String get playBlockedDescription => 'খেলা শুরু করে ঘর থেকে দেখতে চান।';
	@override late final _Translations$watchTogether$notices$bn notices = _Translations$watchTogether$notices$bn._(_root);
	@override late final _Translations$watchTogether$ended$bn ended = _Translations$watchTogether$ended$bn._(_root);
	@override late final _Translations$watchTogether$errors$bn errors = _Translations$watchTogether$errors$bn._(_root);
	@override String untitledEpisode({required Object number}) => 'আয়াত ${number}';
}

// Path: downloads
class _Translations$downloads$bn extends Translations$downloads$en {
	_Translations$downloads$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'ডাউনলোড';
	@override String get manage => 'পরিচালনা';
	@override String get tvShows => 'টেলিভিশন প্রদর্শন';
	@override String get movies => 'চলচ্চিত্র';
	@override String get music => 'সঙ্গীত';
	@override String tracksQueued({required Object count}) => '${count} ট্র্যাক ডাউনলোডের জন্য';
	@override String get noDownloads => 'এখনো ডাউনলোড নেই';
	@override String get noDownloadsDescription => 'ডাউনলোড করা বিষয়বস্তু এখানে অফলি দেখার জন্য দেখা যাবে';
	@override String get downloadNow => 'ডাউনলোড';
	@override String get deleteDownload => 'ডাউনলোড করুন';
	@override String get retryDownload => 'ডাউনলোড করুন';
	@override String get downloadQueued => 'ডাউনলোড করি';
	@override String get downloadResumed => 'ডাউনলোড আবার';
	@override String get serverErrorBitrate => 'সার্ভার ভুল: ফাইলটি দূরবর্তী বিট্রেটের সীমাবদ্ধতা অতিক্রম করতে পারে';
	@override String get storageFull => 'ডাউনলোডগুলি সংরক্ষণ করার জন্য বন্ধ হয়ে যায়. কিছু স্থান বিনামূল্যে বা অন্য ডাউনলোড অবস্থান নির্বাচন করুন, তারপর ফেরত।';
	@override String get storageUnavailable => 'ডাউনলোড বন্ধ হয়ে গেছে কারণ उपलब्ध স্টোরেজ চেক করা যাবে না. ডাউনলোড অবস্থান চেক করুন, তারপর ফেরত।';
	@override String episodesQueued({required Object count}) => '${count} পরিসংখ্যানগুলি ডাউনলোড করার জন্য';
	@override String get downloadDeleted => 'ডাউনলোড 삭제';
	@override String deleteConfirm({required Object title}) => 'এই ডিভাইস থেকে "${title}" মুছে ফেলুন?';
	@override String get deleteCollectionDownloads => 'ডাউনলোড করুন';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => 'এই ডিভাইস থেকে "${title}" এর প্রতিটি ডাউনলোড মুছে ফেলুন?';
	@override String get collectionDownloadsDeleted => 'ডাউনলোড 삭제';
	@override String get cancelledDownloadTitle => 'বাতিল করা Download';
	@override String get cancelledDownloadMessage => 'এই ডাউনলোডটি বাতিল করা হয়েছে. আপনি কি করতে চান?';
	@override String get allEpisodesAlreadyDownloaded => 'সব ঘটনা এখন ডাউনলোড করা হয়েছে';
	@override String get resumeDownload => 'ডাউনলোড করুন';
	@override String get cancelledDownload => 'বাতিল ডাউনলোড';
	@override String syncingFile({required Object file, required Object status}) => '${file} (সিন্সিং ${status})';
	@override String downloadedFileClickToComplete({required Object file}) => 'ডাউনলোড করা হয়েছে ${file} - সম্পূর্ণ করতে ক্লিক করুন';
	@override String get partialDownloadClickToComplete => 'সম্পূর্ণভাবে ডাউনলোড - ক্লিক করুন';
	@override String get deleting => 'মুছে ফেলা...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'মুছে ফেলুন ${title}... (${current} এর ${total})';
	@override String get queuedTooltip => 'কুরআন';
	@override String queuedFilesTooltip({required Object files}) => 'মৌসুম ${files}';
	@override String get downloadingTooltip => 'ডাউনলোড...';
	@override String downloadingFilesTooltip({required Object files}) => 'ডাউনলোড ${files}';
	@override String get noDownloadsTree => 'ডাউনলোড নেই';
	@override String get pauseAll => 'সবার paus';
	@override String get resumeAll => 'সমস্ত সমাধান';
	@override String get retryAll => 'সবাই ফিরে';
	@override String get retryFailed => 'ফেরত ফেরত ফেরত ফেরত ফেরত';
	@override String get deleteAll => 'সব মুছুন';
	@override String get selectVersion => 'নির্বাচন Version';
	@override String get allEpisodes => 'সব এপিসোড';
	@override String get unwatchedOnly => 'শুধুমাত্র চিন্তিত';
	@override String nextNUnwatched({required Object count}) => 'পরবর্তী ${count} অপেক্ষা';
	@override String get customAmount => 'কাস্টম কমানো...';
	@override String get customAmountAny => 'কাস্টম সংখ্যা (একটি)';
	@override String get randomEpisodes => 'পরিস্থিতি';
	@override String get includeSpecials => 'বিশেষ বিশেষ';
	@override String get howManyEpisodes => 'কতটি ঘটনা?';
	@override String get invalidEpisodeCount => 'একটি সঠিক অধ্যায় সংখ্যা লিখুন।';
	@override String get keepSynced => 'সিনেমা রাখুন';
	@override String get downloadOnce => 'একবার ডাউনলোড';
	@override String keepNUnwatched({required Object count}) => '${count} অদৃশ্য রাখুন';
	@override String get editSyncRule => 'সিনক নিয়ম';
	@override String get removeSyncRule => 'সিনক নিয়ম মুছে ফেলুন';
	@override String removeSyncRuleConfirm({required Object title}) => '"${title}" সিঙ্ক করা বন্ধ করবেন? ডাউনলোড করা পর্বগুলি সংরক্ষিত থাকবে।';
	@override String removeListSyncRuleConfirm({required Object title}) => '“${title}” সিন্সিং বন্ধ করুন?';
	@override String get deleteSyncRuleDownloads => 'সংযুক্ত ডাউনলোডও মুছে ফেলুন';
	@override String get deleteSyncRuleDownloadsDescription => 'অন্য সনাক্স নিয়ম বা প্রোফাইল দ্বারা ব্যবহৃত ডাউনলোডগুলি সংরক্ষিত হবে।';
	@override String syncRuleCreated({required Object count}) => 'সিনক নিয়ম তৈরি — ${count} অদৃশ্যক epizodes সংরক্ষণ';
	@override String get syncRuleUpdated => 'সিন্ক নিয়ম আপডেট';
	@override String get syncRuleRemoved => 'সিন্ক নিয়ম মুছে ফেলুন';
	@override String get syncRuleAndDownloadsRemoved => 'Sync নিয়ম এবং সংযুক্ত ডাউনলোড মুছে ফেলুন';
	@override String get syncRuleCleanupBusy => 'সিন্ক নিয়ম বর্তমানে আপডেট করা হচ্ছে. এক মুহূর্তে আবার চেষ্টা করুন.';
	@override String get syncRuleCleanupUnavailable => 'সংযুক্ত ডাউনলোড নিরাপদভাবে চিহ্নিত হতে পারে না. সার্ভার আবার সংযুক্ত করুন এবং আবার চেষ্টা করুন, বা ডাউনলোড মুছে ফেলে না নিয়মটি মুছে ফেলুন.';
	@override String syncedNewEpisodes({required Object count, required Object title}) => 'সিন্সেস ${count} নতুন অধ্যায় ${title} জন্য';
	@override String get syncNow => 'এখন সিনক';
	@override String get downloadsUpToDate => 'ডাউনলোড আপডেট';
	@override String syncComplete({required Object queued, required Object removed}) => 'Sync complete · ${queued} queued, ${removed} মুছে ফেলা';
	@override String get activeSyncRules => 'সিনক নিয়ম';
	@override String get reviewOrphanFiles => 'ডাউনলোড করুন অর্পানড';
	@override String get orphanReviewTitle => 'ডাউনলোড করুন অর্পানড';
	@override String get orphanReviewDescription => 'এই ট্যাগ ফাইলগুলি PlezyNG এর ভিত্তিক অ্যাপ-ম্যানেজিত ডাউনলোড ফাইলগুলিতে রয়েছে এবং ডাউনলোড রেকর্ড বা কার্যকর কাজের সাথে সমাধান নেই।';
	@override String orphanReviewCount({required Object count, required Object size}) => '${count} ফাইল · ${size}';
	@override String orphanDeleteFiles({required Object count}) => '${count} ফাইল মুছে ফেলুন';
	@override String get orphanCleanupNone => 'কোন ডাউনলোড ফাইল পাওয়া যায় না';
	@override String get orphanCleanupFailed => 'PlezyNG নিরাপদভাবে পরিচালিত ডাউনলোড ফোডার স্ক্যান করতে পারেনি. কোন ফাইলটি মুছে ফেলেনি।';
	@override String get orphanCleanupChanged => 'ডাউনলোডের তালিকা বিবেচনার সময় পরিবর্তিত হয়. ফাইলগুলি আবারও পরিষ্কার করার আগে বিবেচনা করুন.';
	@override String orphanCleanupComplete({required Object count, required Object size}) => 'মুছে ফেলেন ${count} অন্তর্ভুক্ত ফাইল · ${size} বিনামূল্যে';
	@override String get noSyncRules => 'কোন সিনক নিয়ম';
	@override String get manageSyncRule => 'সিনাক্স সিনাক্স';
	@override String get editEpisodeCount => 'Episode সংখ্যা';
	@override String get editSyncFilter => 'ফিল্টার Sync';
	@override String get syncAllItems => 'সব পণ্য সিন্সিকেশন';
	@override String get syncUnwatchedItems => 'অবিশ্বাসিত পণ্য সিন্সিং';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'সার্ভার: ${server} • ${status}';
	@override String get syncRuleAvailable => 'পাওয়া';
	@override String get syncRuleOffline => 'অফলিন';
	@override String get syncRuleSignInRequired => 'চিহ্নিত প্রয়োজনীয়';
	@override String get syncRuleAccessDenied => 'অ্যাক্সেস অনুরোধ';
	@override String get syncRuleNotAvailableForProfile => 'বর্তমান প্রোফাইলের জন্য পাওয়া যায় না';
	@override String get syncRuleUnknownServer => 'অজ্ঞাত সার্ভার';
	@override String get syncRuleListCreated => 'সিনক নিয়ম তৈরি';
	@override late final _Translations$downloads$backgroundWarning$bn backgroundWarning = _Translations$downloads$backgroundWarning$bn._(_root);
	@override String get options => 'ডাউনলোড বিকল্প';
	@override late final _Translations$downloads$groupings$bn groupings = _Translations$downloads$groupings$bn._(_root);
	@override String get unknownLibrary => 'অজানা লাইব্রেরি';
	@override String get unknownShow => 'অজ্ঞাত প্রদর্শনী';
	@override String get unknownSeason => 'অজানা সপ্তাহ';
	@override String get unknownAlbum => 'অজ্ঞাত অ্যালবাম';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} সম্পন্ন';
	@override String storageUsed({required Object size}) => 'ব্যবহৃত স্টোরেজ: ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ডাউনলোড',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ডাউনলোড',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} প্রদর্শন',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} দেখুন',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} সিনেমা',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} চলচ্চিত্র',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} অ্যালবাম',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} অ্যালবাম',
	);
	@override String get errorFileNotFound => 'ফাইল পাওয়া যায় না (404)';
	@override String get errorDownloadNotAllowed => 'ডাউনলোড সার্ভার দ্বারা অনুমোদিত নয় (403)';
	@override String get errorDownloadFailed => 'ডাউনলোড ভুল';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'ডাউনলোড ভুল: ${reason}';
	@override String get convertingOnServer => 'সার্ভারের মাধ্যমে পরিদর্শন...';
	@override String convertingOnServerPercent({required Object percent}) => 'সার্ভার উপর পরিদর্শন · ${percent}%';
	@override String errorHttpStatus({required Object status}) => 'ডাউনলোড ভুল (HTTP ${status})';
	@override String errorPostProcessing({required Object reason}) => 'পদ্ধতি অনুসন্ধানের পর ভুল: ${reason}';
	@override String get reasonFileNotSaved => 'এই ডিভাইসে ফাইল সংরক্ষণ করা যায় না';
	@override String get reasonCannotResume => 'পৃথিবী ডাউনলোড করা সম্ভব নয়';
	@override String get reasonDeviceStorageFull => 'এই ডিভাইসটি স্টোরেজ থেকে বের হয়।';
	@override String get notificationDownloading => 'ডাউনলোড...';
	@override String get notificationComplete => 'সম্পূর্ণ ডাউনলোড';
	@override String get notificationPaused => 'ডাউনলোড বন্ধ';
}

// Path: shaders
class _Translations$shaders$bn extends Translations$shaders$en {
	_Translations$shaders$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'ছায়া';
	@override String get noShaderDescription => 'কোন ভিডিও উন্নয়ন';
	@override String get nvscalerDescription => 'নভিডিয়া ইমেজ স্ক্যানিং আরও দৃঢ় ভিডিও জন্য';
	@override String get artcnnVariantNeutral => 'নির্যাতন';
	@override String get artcnnVariantDenoise => 'ডেনোজ';
	@override String get artcnnVariantDenoiseSharpen => 'ডেনোইজ + শার্পেন';
	@override String get qualityFast => 'দ্রুত';
	@override String get qualityHQ => 'উচ্চ মানের';
	@override String get mode => 'মডিও';
	@override String get importShader => 'শারীরিক আমদানি';
	@override String get customShaderDescription => 'কাস্টম GLSL Shader';
	@override String get shaderImported => 'শারীরিক আমদানি';
	@override String get shaderImportFailed => 'শারীরিক অস্ত্র সরবরাহ করতে পারেনি';
	@override String get deleteShader => 'ছায়া ছাদ';
	@override String deleteShaderConfirm({required Object name}) => '‘${name}’ নামের সংখ্যাটি মুছে ফেলুন';
}

// Path: companionRemote
class _Translations$companionRemote$bn extends Translations$companionRemote$en {
	_Translations$companionRemote$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'সহায়ক রিমোট';
	@override String connectedTo({required Object name}) => 'সংযোগ ${name}';
	@override String get unknownDevice => 'অজ্ঞাত ডিভাইস';
	@override late final _Translations$companionRemote$session$bn session = _Translations$companionRemote$session$bn._(_root);
	@override late final _Translations$companionRemote$pairing$bn pairing = _Translations$companionRemote$pairing$bn._(_root);
	@override late final _Translations$companionRemote$remote$bn remote = _Translations$companionRemote$remote$bn._(_root);
	@override late final _Translations$companionRemote$errors$bn errors = _Translations$companionRemote$errors$bn._(_root);
	@override String get closedBeforeAuth => 'সনাক্তকরণের আগে বন্ধ করা';
}

// Path: videoSettings
class _Translations$videoSettings$bn extends Translations$videoSettings$en {
	_Translations$videoSettings$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'গতি Playback';
	@override String get normalSpeed => 'স্বাভাবিক';
	@override String sleepTimerActive({required Object duration}) => 'সক্রিয় (${duration})';
	@override String get zoom => 'জুম';
	@override String get sleepTimer => 'ঘুমের সময়';
	@override String get audioSync => 'অডিও সিনক';
	@override String get subtitleSync => 'Subtitle সিনাক্স';
	@override String get hdr => 'HDR';
	@override String get hdrUnsupported => 'এখানে HDR পাওয়া যায় না - এই ডেভিসপ কম্পিউটার বা ভিডিও উত্পাদন এটি নিতে পারে না।';
	@override String get hdrToneMapping => 'HDR টন ম্যাপিং';
	@override String get hdrToneMappingCompositor => 'কম্পিউটার';
	@override String get hdrToneMappingCompositorDescription => 'উৎসের HDR ম্যাটা ডেটাগুলির মাধ্যমে প্রবেশ করুন এবং ডেটাবেট কম্পিউটর ম্যাপের মাধ্যমে এটি ছেড়ে দিন।';
	@override String get hdrToneMappingPlayer => 'প্লেয়ার';
	@override String get hdrToneMappingPlayerDescription => 'খেলোয়াড়ে ডিভাইসের পাইকেল সূর্যকে ম্যাপ করুন, তারপর ফলাফলটি কম্পিউটারকে বলুন।';
	@override String get hdrToneMappingFailed => 'HDR টন ম্যাপিং পরিবর্তন করা যায় না - পূর্ববর্তী মডিট এখনও সক্রিয়।';
	@override String get audioOutput => 'অডিও উৎস';
	@override String get videoTrack => 'ভিডিও ট্র্যাক';
	@override String get videoTrackDescription => 'কোন ভিডিও স্ট্রিম দেখানো হবে তা বেছে নিন। ফাইলে বিকল্প ভিডিও ট্র্যাক থাকলে MPV প্লেব্যাকে এটি পাওয়া যায়।';
	@override String get videoTrackDefault => 'ডিফল্ট';
	@override String get videoTrackUnavailable => 'কোনো বিকল্প ভিডিও ট্র্যাক নেই।';
	@override String get videoTrackFailed => 'ভিডিও ট্র্যাক পরিবর্তন করা যায়নি।';
	@override String videoTrackNumber({required Object id}) => 'ট্র্যাক ${id}';
	@override String get performanceOverlay => 'অভ্যন্তরীণ Overlay';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'ঘরে';
	@override String get audioOutputSpatial => 'স্পেশাল অডিও';
	@override String get audioOutputStereo => 'স্টেরিও';
	@override String get audioEqualizer => 'Audio Equalizer অডিও equalizer';
	@override String get audioEqualizerDescription => '10-ব্যান্ড Equalizer এর জন্য MPV. অডিও ফিল্টার decoded আউডিও ব্যবহার করে এবং passthrough বন্ধ করে।';
	@override String get audioEqualizerFlat => 'ফ্লাইট';
	@override String get audioEqualizerActive => 'কাস্টম';
	@override String get audioEqualizerSaveFailed => 'Audio Equalizer সেটগুলি সংরক্ষণ করতে পারবেন না।';
	@override String get audioEffectsDescription => 'প্রভাব decoded অডিও ব্যবহার করে, তাই passthrough বের হয়. রুম পরিবেশ এবং স্টেয়েও বিতরণ নির্ভর করে MPV গঠন ও ট্র্যাক';
	@override String get audioStereoWidth => 'Stereo বিতর্ক';
	@override String get audioSpatializer => 'রুম পরিবেশ';
	@override String get audioSpatializerDescription => 'শান্ত রুমের প্রতিশ্রুতি যোগ করুন।';
	@override String get audioPitch => 'Pitch পরিবর্তন';
	@override String get audioPitchDescription => 'দ্রুত পরিবর্তন ছাড়া পাইচ পরিবর্তন করুন। MPV নির্মাণ করা উচিত Rubber Band.';
	@override String get audioEffectUnavailable => 'এই পথের জন্য এই প্রভাব পাওয়া যায় না অথবা MPV গঠন';
	@override String get backgroundVideoAudio => 'ভিডিও অডিও ফাউন্ডেশন';
	@override String get backgroundVideoAudioDescription => 'আপনি খেলোয়াড়কে ছেড়ে যখন ভিডিও অডিও খেলতে থাকেন; আপনি ফিরে যখন পর্যন্ত ছবি छिपा रहती है. Android একটি মিডিয়া প্লাইবক নীতি ব্যবহার করে।';
	@override String get audioNormalization => 'স্বাভাবিক শব্দ';
	@override String get audioNormalizationDisablesPassthrough => 'অডিও ডকোড করুন PCM; passthrough বন্ধ হয়ে থাকে যখন এটি';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$bn extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get color => 'রঙ';
	@override String get performance => 'কর্মক্ষমতা';
	@override String get buffer => 'বাফার';
	@override String get app => 'অ্যাপ';
	@override String get decoder => 'ডকোডার';
	@override String get rawDecoder => 'ডেকডার';
	@override String get tunneling => 'টুইটার';
	@override String get passthrough => 'পাস্টরো';
	@override String get aspect => 'দৃষ্টি';
	@override String get rotation => 'রোটেশন';
	@override String get dvSource => 'ডি উৎস';
	@override String get dvPath => 'ডি পথ';
	@override String get dvRouteDecoder => 'Dolby Vision ডকোডার';
	@override String get dvRouteDecoderP81 => 'Dolby Vision ডকোডার (P7→8.1)';
	@override String get dvRouteBaseLayer => 'Base স্তর';
	@override String get dvRouteBaseLayerHdr10 => 'HDR10 ভিত্তিক স্তর';
	@override String get dvRouteBaseLayerHlg => 'HLG Base ল্যাগ';
	@override String get dvRouteBaseLayerSdr => 'SDR ভিত্তিক স্তর';
	@override String get dvRouteReshaped => 'RPU রেসিপি (GPU পরবর্তী)';
	@override String get dvRouteFelGraphActive => 'পরীক্ষামূলক P7 FEL গ্রাফ (অসম্ভব)';
	@override String get p7Conversion => 'P7 কনভ';
	@override String get sampleRate => 'নমুনা হার';
	@override String get pixelFormat => 'পিক্সেল Fmt';
	@override String get hwFormat => 'ফিএমএফ';
	@override String get matrix => 'ম্যাট্রিক্স';
	@override String get primaries => 'প্রাথমিক';
	@override String get transfer => 'ট্রান্সফার';
	@override String get renderFps => 'ফিপিএস ফিপিএস';
	@override String get displayFps => 'ফিপিএস প্রদর্শন';
	@override String get avSync => 'A/V সিন্ক';
	@override String get dropped => 'ধ্বংস';
	@override String get dvRpus => 'ডিপিএল';
	@override String get dvRpuAverage => 'ডিপিএল এভগ';
	@override String get dvSampleAverage => 'ডিএসএইচএইচএইচ';
	@override String get maxLuma => 'ম্যাক্স লুমা';
	@override String get minLuma => 'মিন লুমা';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'ক্যাশ ব্যবহার';
	@override String get cacheLimit => 'ক্যাশি সীমা';
	@override String get speed => 'গতি';
	@override String get player => 'প্লেয়ার';
	@override String get playMethod => 'খেলা পদ্ধতি';
	@override String get memory => 'স্মৃতি';
	@override String get uiFps => 'ফিপিএস';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Android HW';
	@override String get decoderNvidiaHw => 'Nvidia HW';
	@override String get decoderQualcommHw => 'কোলকোম HW';
	@override String get decoderMediatekHw => 'মিডিয়াম HW';
	@override String get decoderExynosHw => 'হ্যাঁ হ্যাঁ';
	@override String get decoderSoftware => 'সফটওয়্যার';
	@override String get decoderHardware => 'হার্ডওয়ার্ক';
	@override String get tunnelingActive => 'আক্রমণ';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted} (${failures} অসম্ভব)';
}

// Path: externalPlayer
class _Translations$externalPlayer$bn extends Translations$externalPlayer$en {
	_Translations$externalPlayer$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'বিদেশী খেলোয়াড়';
	@override String get useExternalPlayer => 'বাইরের খেলোয়াড় ব্যবহার';
	@override String get useExternalPlayerDescription => 'অন্য অ্যাপে ভিডিও খোলা';
	@override String get selectPlayer => 'খেলোয়াড় নির্বাচন';
	@override String get customPlayers => 'কাস্টম খেলোয়াড়';
	@override String get systemDefault => 'সিস্টেম ভুল';
	@override String get addCustomPlayer => 'কাস্টম খেলোয়াড়';
	@override String get playerName => 'খেলোয়াড় নাম';
	@override String get playerNameHint => 'আমার খেলোয়াড়';
	@override String get playerCommand => 'অর্ডার';
	@override String get playerPackage => 'প্যাকেজ নাম';
	@override String get playerUrlScheme => 'URL সিস্টেম';
	@override String get off => 'বন্ধ';
	@override String get launchFailed => 'খোলা খোলা খোলা খোলা খোলা খোলা';
	@override String appNotInstalled({required Object name}) => '${name} ইনস্টল করা হয় না';
	@override String get playInExternalPlayer => 'বাইরের খেলোয়াড়ে খেলুন';
	@override String get description => 'ভিডিও খুলতে অন্য অ্যাপটি নির্বাচন করুন. উপলব্ধ খেলোয়াড়গুলি আপনার ডিভাইস এবং ইনস্টলেড অ্যাপগুলির উপর নির্ভর করে।';
	@override String get systemDefaultDescription => 'অপারেটিং সিস্টেম তার ডিফল্ট অ্যাপ্লিকেশন দিয়ে ভিডিও খুলবেন।';
	@override String playerOptionDescription({required Object player}) => '${player} সঙ্গে ভিডিও খুলুন।';
	@override String get playerNameDescription => 'খেলোয়াড়ের তালিকায় উল্লেখিত ট্যাগ।';
	@override String get playerPackageDescription => 'অ্যাপের Android প্যাকেজ নাম লিখুন, যেমন com.example.player।';
	@override String get playerCommandDescription => 'এই ডিভাইসের জন্য ইনস্টল করা খেলোয়াড় কমান্ড বা executable পথ লিখুন।';
	@override String get playerUrlSchemeDescription => 'ড্রাইভার চালু করার জন্য ব্যবহৃত URL নম্বর এবং পছন্দীয় URL নেম্বরে প্রদান করুন।';
}

// Path: metadataEdit
class _Translations$metadataEdit$bn extends Translations$metadataEdit$en {
	_Translations$metadataEdit$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'এডিট';
	@override String get screenTitle => 'মেটাডেটা এডিট করুন';
	@override String get basicInfo => 'মৌলিক তথ্য';
	@override String get artwork => 'শিল্প';
	@override String get advancedSettings => 'উন্নত সিস্টেম';
	@override String get title => 'Title নাম';
	@override String get sortTitle => 'নামের তুলনা';
	@override String get originalTitle => 'মূল নাম';
	@override String get releaseDate => 'Release তারিখ';
	@override String get contentRating => 'বিষয়বস্তু Rating';
	@override String get studio => 'স্টুডিও';
	@override String get tagline => 'সংক্ষিপ্ত পরিচিতি';
	@override String get summary => 'সাবধান';
	@override String get poster => 'পোস্টার';
	@override String get background => 'ফাউন্ডেশন';
	@override String get logo => 'লোগো';
	@override String get squareArt => 'স্ক্রা শিল্প';
	@override String get selectPoster => 'পোস্টার নির্বাচন';
	@override String get selectBackground => 'ফাউন্ডেশন নির্বাচন করুন';
	@override String get selectLogo => 'লোগো নির্বাচন করুন';
	@override String get selectSquareArt => 'পৃথিবী শিল্প নির্বাচন';
	@override String get fromUrl => 'URL থেকে';
	@override String get uploadFile => 'ফাইল আপলোড';
	@override String get enterImageUrl => 'ইমেজ URL লিখুন';
	@override String get imageUrl => 'ইমেজ URL';
	@override String get metadataUpdated => 'মেটাদাডেট আপডেট';
	@override String get metadataUpdateFailed => 'মেটাদাটা আপডেট করতে পারেনি';
	@override String get artworkUpdated => 'অ্যাকাউন্ট আপডেট';
	@override String get artworkUpdateFailed => 'শিল্প কাজ আপডেট করতে পারিনি';
	@override String get noArtworkAvailable => 'কোন শিল্প কাজ পাওয়া যায় না';
	@override String artworkOption({required Object index}) => 'শিল্প বিকল্প ${index}';
	@override String selectedArtworkOption({required Object index}) => 'ছবির বিকল্প ${index}, নির্বাচিত';
	@override String get notSet => 'সিস্টেম না';
	@override String get libraryDefault => 'লাইব্রেরি ভুল';
	@override String get accountDefault => 'অ্যাকাউন্ট ভুল';
	@override String get seriesDefault => 'সিরিজ ভেঙে';
	@override String get episodeSorting => 'আলাদা আলাদা';
	@override String get oldestFirst => 'প্রথমে পুরাতন';
	@override String get newestFirst => 'প্রথম নতুন';
	@override String get keep => 'রাখুন';
	@override String get allEpisodes => 'সব এপিসোড';
	@override String latestEpisodes({required Object count}) => '${count} সর্বশেষ পরিস্থিতি';
	@override String get latestEpisode => 'সর্বশেষ epizode';
	@override String episodesAddedPastDays({required Object count}) => 'গত ${count} দিনের মধ্যে প্রদর্শন করা হয়েছে';
	@override String get deleteAfterPlaying => 'খেলাধুলা পরে খেলাধুলা';
	@override String get never => 'কখনো';
	@override String get afterADay => 'একদিন পরে';
	@override String get afterAWeek => 'এক সপ্তাহ পরে';
	@override String get afterAMonth => 'এক মাস পরে';
	@override String get onNextRefresh => 'পরবর্তী ফ্রিজ';
	@override String get seasons => 'সপ্তাহ';
	@override String get show => 'প্রদর্শন';
	@override String get hide => 'লুকিয়ে';
	@override String get episodeOrdering => 'অর্ডার পরিস্থিতি';
	@override String get tmdbAiring => 'সিনেমা ডেটাবেস (Aired)';
	@override String get tvdbAiring => 'টেবিট ডেভেল (আরড)';
	@override String get tvdbAbsolute => 'ট্যাগটি (Absolute )';
	@override String get metadataLanguage => 'মেটাদাডেট ভাষা';
	@override String get useOriginalTitle => 'মূল নাম ব্যবহার করুন';
	@override String get preferredAudioLanguage => 'অডিও ভাষা প্রিয়';
	@override String get preferredSubtitleLanguage => 'প্রিয় ভাষা Subtitle';
	@override String get subtitleMode => 'Auto-Select Subtitle পদ্ধতি';
	@override String get manuallySelected => 'ম্যানুয়াল নির্বাচন';
	@override String get shownWithForeignAudio => 'বিদেশী অডিও সঙ্গে সনাক্ত';
	@override String get alwaysEnabled => 'সবসময় অনুমোদিত';
	@override String get tags => 'ট্যাগ';
	@override String get addTag => 'Add ট্যাগ';
	@override String get genre => 'ধরণ';
	@override String get director => 'পরিচালক';
	@override String get writer => 'লেখক';
	@override String get producer => 'উৎপাদনকারী';
	@override String get country => 'দেশ';
	@override String get collection => 'সংগ্রহ';
	@override String get label => 'লেবেল';
	@override String get quickTag => 'দ্রুত Tag...';
}

// Path: matchScreen
class _Translations$matchScreen$bn extends Translations$matchScreen$en {
	_Translations$matchScreen$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get match => 'খেলা...';
	@override String get fixMatch => 'খেলা ফ্যাক্ট...';
	@override String get unmatch => 'খেলা';
	@override String get unmatchConfirm => 'এই ম্যাচটি পরিষ্কার করে? Plex এটি শেষ পর্যন্ত অসম্ভব হিসাবে আলাদা করে।';
	@override String get unmatchSuccess => 'অসম্ভব পণ্য';
	@override String get unmatchFailed => 'অসুবিধা অসুবিধা অসুবিধা';
	@override String get matchApplied => 'খেলায় প্রযোজ্য';
	@override String get matchFailed => 'খেলাটি অর্জন করতে পারেনি';
	@override String get titleHint => 'Title নাম';
	@override String get yearHint => 'বছর';
	@override String get search => 'অনুসন্ধান';
	@override String get noMatchesFound => 'খেলা খুঁজে পাওয়া যায় না';
}

// Path: serverTasks
class _Translations$serverTasks$bn extends Translations$serverTasks$en {
	_Translations$serverTasks$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'সার্ভার কাজ';
	@override String get failedToLoad => 'চাকরির লোড করতে পারেনি';
	@override String get noTasks => 'কোন কাজ চলবে না';
}

// Path: trakt
class _Translations$trakt$bn extends Translations$trakt$en {
	_Translations$trakt$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'সংযুক্ত';
	@override String connectedAs({required Object username}) => 'সংযুক্ত @${username}';
	@override String get disconnectConfirm => 'Trakt অ্যাকাউন্ট বন্ধ করুন?';
	@override String get disconnectConfirmBody => 'PlezyNG এর মাধ্যমে ঘটনাবলীগুলি পাঠানোর সময় থেমে যাবে Trakt. আপনি যেকোনো সময়ে আবার সংযোগ করতে পারেন।';
	@override String get scrobble => 'বাস্তব সময়ের স্ক্রোবিলিং';
	@override String get scrobbleDescription => 'খেলা, pause, এবং stop events পাঠান Trakt Playback সময়।';
	@override String get watchedSync => 'সিন্ক দেখানো অবস্থা';
	@override String get watchedSyncDescription => 'যখন আপনি PlezyNG এর অনুসন্ধানের মত পণ্যগুলি চিহ্নিত করেন, তখন তারা Trakt এর অনুসন্ধানের মতও চিহ্নিত হয়।';
}

// Path: seerr
class _Translations$seerr$bn extends Translations$seerr$en {
	_Translations$seerr$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'সংযোগ Seerr';
	@override String get serverUrl => 'URL সার্ভার';
	@override String get serverUrlHelper => 'আপনার সার্ভিসের ঠিকানা';
	@override String get checkServer => 'চলুন';
	@override String get signInWithJellyfin => 'সাইন আপ করুন Jellyfin';
	@override String get signInWithEmby => 'সাইন আপ করুন Emby';
	@override String get signInWithLocal => 'স্থানীয় অ্যাকাউন্ট ব্যবহার করুন';
	@override String get email => 'ইমেইল';
	@override String get noSignInMethods => 'এই Seerr উদাহরণ কোন সাইন-ইন পদ্ধতি PlezyNG সমর্থন দেয় না।';
	@override String get instance => 'আয়াত';
	@override String get disconnectConfirm => 'চিঠি বন্ধ করুন?';
	@override String get disconnectConfirmBody => 'PlezyNG এই Seerr উদাহরণ ভুলে যাবে. প্রতিটি সময়ে আবার সংযোগ করুন.';
	@override String get request => 'অনুরোধ';
	@override String get request4k => '4K অনুসন্ধান';
	@override String get seasons => 'সপ্তাহ';
	@override String get allSeasons => 'সব সপ্তাহ';
	@override String get advancedOptions => 'উন্নত';
	@override String get destinationServer => 'ডিজিটাল সার্ভার';
	@override String get qualityProfile => 'মানের প্রোফাইল';
	@override String get rootFolder => 'রুট ফোলার';
	@override String get languageProfile => 'ভাষা প্রোফাইল';
	@override String get tags => 'ট্যাগ';
	@override String get noTags => 'কোন ট্যাগ';
	@override String defaultOption({required Object name}) => '${name} (প্রধান)';
	@override String get animeNote => 'এই সিরিজটি একটি অ্যানিমি।';
	@override String get requestSubmitted => 'আবেদন প্রদান';
	@override String requestFailed({required Object error}) => 'অনুরোধ ভুল হয়েছে: ${error}';
	@override String get requestsLoadFailed => 'অনুরোধের বিকল্পগুলি লোড করতে পারবেন না';
	@override String get nothingToRequest => 'সবকিছু এখনই পাওয়া যায় বা অনুরোধ করা যায়।';
	@override String get statusAvailable => 'পাওয়া';
	@override String get statusPartiallyAvailable => 'অংশগ্রহণযোগ্য';
	@override String get statusRequested => 'অনুরোধ';
	@override String get statusProcessing => 'প্রক্রিয়া';
	@override String get statusBlocklisted => 'ব্লক করা';
	@override String couldNotReach({required Object url, required Object error}) => '${url}: ${error} পৌঁছাতে পারে না';
	@override String noInstanceAtUrl({required Object url, required Object status}) => 'নো Seerr আবেদন ${url} (HTTP ${status})';
	@override String get behindAuthProxy => 'একটি সত্যি প্রাক্সি (SSO বা HTTP auth) Seerr পরিবর্তে উত্তর দেয়. PlezyNG এর মাধ্যমে নিবন্ধন করা যায় না: Seerr এর /api/v1 পথটি এই অ্যাপের জন্য প্রাক্সি অতিক্রম করে, অথবা একটি ঠিকানা ব্যবহার করুন যা সরাসরি Seerr পৌঁছায়।';
	@override String get invalidUrl => 'একটি সার্ভার ঠিকানা লিখুন, যেমন https://seerr.example.com';
	@override String get quickConnectUnsupported => 'এই Seerr প্রদর্শনটি Quick Connect সমর্থন করে না।';
	@override String get notInitialized => 'এই Seerr ইনস্টেশন প্রথম চালু সিস্টেমটি সম্পন্ন করেনি';
	@override String get noPlexTokenForReauth => 'নম্বর Plex টকেন আবারও নিবন্ধন করতে পাওয়া যায়';
	@override String get noStoredCredentials => 'আবার সাইন ইন করার জন্য সংরক্ষিত সাইন-ইন তথ্য পাওয়া যাচ্ছে না';
	@override String get signInRejected => 'সাইন-ইন ফাঁস করা হয়েছে';
	@override String get noSessionCookie => 'Seerr একটি সেশন কুকি প্রকাশ করেনি';
	@override String get freshCookieRejected => 'Seerr নতুন সেশন কুকি প্রত্যাহার করেছে';
	@override String get noUserInformation => 'Seerr ব্যবহারকারীর তথ্য ফিরিয়ে দেয়নি';
	@override String get sessionRejectedAfterReauth => 'পুনরাবৃত্তি পরে চিঠি বাতিল করা হয়।';
	@override String get permissionDenied => 'Seerr এই পদক্ষেপটি প্রত্যাখ্যান করেছে: আপনার অ্যাকাউন্টের প্রয়োজনীয় অনুমতি নেই';
	@override String get permissionRevoked => 'আপনি এখন আর এ ব্যাপারে অনুরোধ করার অনুমতি নেই।';
}

// Path: services
class _Translations$services$bn extends Translations$services$en {
	_Translations$services$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'পরিষেবা';
	@override String get hubSubtitle => 'সিনক উন্নয়ন দেখুন এবং নতুন টাইমের জন্য অনুরোধ করুন।';
	@override String get integrations => 'ইন্টারফেস';
	@override String get notConnected => 'সংযুক্ত না';
	@override String connectedAs({required Object username}) => 'সংযুক্ত @${username}';
	@override String get scrobble => 'স্বয়ংক্রিয়ভাবে উন্নয়ন ট্র্যাক করুন';
	@override String get scrobbleDescription => 'আপডেট করুন আপনার তালিকায় যখন আপনি একটি epizode বা সিনেমা শেষ করেন।';
	@override String disconnectConfirm({required Object service}) => 'ডাউনলোড করুন ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'PlezyNG আপডেট বন্ধ করবে ${service}. প্রতিটি সময়ে আবার সংযোগ করুন।';
	@override String connectFailed({required Object service}) => '${service} এর সাথে যোগাযোগ করতে পারবেন না।';
	@override late final _Translations$services$names$bn names = _Translations$services$names$bn._(_root);
	@override late final _Translations$services$simklReconnect$bn simklReconnect = _Translations$services$simklReconnect$bn._(_root);
	@override late final _Translations$services$deviceCode$bn deviceCode = _Translations$services$deviceCode$bn._(_root);
	@override late final _Translations$services$oauthProxy$bn oauthProxy = _Translations$services$oauthProxy$bn._(_root);
	@override late final _Translations$services$pendingAuth$bn pendingAuth = _Translations$services$pendingAuth$bn._(_root);
	@override late final _Translations$services$libraryFilter$bn libraryFilter = _Translations$services$libraryFilter$bn._(_root);
	@override String get seerrDescription => 'Seerr বা Overseerr এর সাথে সংযোগ করুন এবং মিডিয়া অনুরোধের জন্য টাইমগুলি খুঁজে পেতে।';
	@override late final _Translations$services$trackerDescriptions$bn trackerDescriptions = _Translations$services$trackerDescriptions$bn._(_root);
}

// Path: addServer
class _Translations$addServer$bn extends Translations$addServer$en {
	_Translations$addServer$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => 'যোগ করুন ${product} সার্ভার';
	@override String get serverUrls => 'URL সার্ভার';
	@override String get serverUrlsHelper => 'কয়েকটি ইউরলি অনুমোদিত, কোমাস দ্বারা আলাদা।';
	@override String get findServer => 'সার্ভার খুঁজুন';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'স্থানীয় সার্ভার ${product} খুঁজছেন ...';
	@override String localMediaBrowserServers({required Object product}) => 'স্থানীয় সার্ভার ${product}';
	@override String get username => 'ব্যবহারকারী নাম';
	@override String get password => 'পাসওয়ার্ড';
	@override String get signIn => 'সাইন ইন করুন';
	@override String get change => 'পরিবর্তন';
	@override String get required => 'প্রয়োজনীয়';
	@override String couldNotReachServer({required Object error}) => 'সার্ভার পৌঁছাতে পারবেন না: ${error}';
	@override String signInFailed({required Object error}) => 'অ্যাকাউন্ট ভুল: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect অসম্ভব: ${error}';
	@override String get addPlexTitle => 'সাইন আপ করুন Plex';
	@override String get pinExpired => 'PIN-টি অন্তর্ভুক্ত হওয়ার আগে শেষ হয়ে গেছে, আবারও চেষ্টা করুন।';
	@override String failedToRegisterAccount({required Object error}) => 'অ্যাকাউন্ট নিবন্ধন করতে পারিনি: ${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => 'আপনার ${product} সার্ভার URL লিখুন';
	@override String get addConnectionTitle => 'সংযোগ যোগ করুন';
	@override String addConnectionTitleScoped({required Object name}) => '${name} এর জন্য যোগ করুন';
	@override String get signInWithPlexCard => 'সাইন আপ করুন Plex';
	@override String get signInWithPlexCardSubtitle => 'এই ডিভাইসটি অনুমোদন করুন. শেয়ার সার্ভার যোগ করা হয়।';
	@override String get signInWithPlexCardSubtitleScoped => 'একটি অ্যাকাউন্ট Plex অনুমোদন করুন. বাড়ি ব্যবহারকারীদের প্রোফাইল হয়ে যায়।';
	@override String connectToMediaBrowserCard({required Object product}) => 'সংযোগ ${product}';
	@override String get connectToMediaBrowserCardSubtitle => 'আপনার সার্ভার URL, ব্যবহারকারীর নাম এবং পাসওয়ার্ড লিখুন।';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => 'আপনার সার্ভার ${product} সার্ভারে প্রবেশ করুন. ${name} সার্ভারে সংযোগ করুন.';
	@override String get borrowFromAnotherProfile => 'অন্য প্রোফাইল থেকে ডাউনলোড';
	@override String get borrowFromAnotherProfileSubtitle => 'পিন সুরক্ষিত প্রোফাইলগুলি একটি পিন প্রয়োজন।';
	@override String get invalidCredentials => 'ভুল ব্যবহারকারীর নাম বা পাসওয়ার্ড';
	@override String get authResponseNotJson => 'সনাক্তকরণ উত্তর সঠিক ছিল না JSON';
	@override String get authResponseIncomplete => 'সার্ভার থেকে sign-in উত্তর অসম্পূর্ণ ছিল';
	@override String get quickConnectRejected => 'Quick Connect সার্ভার দ্বারা বাতিল করা হয়';
	@override String get quickConnectNotJson => 'Quick Connect উত্তরটি সঠিক ছিল না JSON';
	@override String get quickConnectMissingFields => 'উত্তর Quick Connect একটি কোড বা গোপনতা অল্প';
	@override String get quickConnectPollRejected => 'Quick Connect সার্ভার দ্বারা অনুরোধ করা হয়';
	@override String get serverTimedOut => 'সার্ভার সঠিক সময়ে উত্তর দেয়নি।';
	@override String get responseNotJson => 'সার্ভার প্রতিক্রিয়া সঠিক ছিল না JSON';
	@override String responseMissingIdentity({required Object product}) => 'উত্তর একটি ID বা সার্ভার নামের অভাব - এটি একটি সার্ভার ${product}?';
	@override String probeFailed({required Object error}) => 'সার্ভার পৌঁছাতে পারবেন না: ${error}';
	@override String enterAtLeastOneUrl({required Object product}) => 'সার্ভার URL ${product} এর জন্য কমপক্ষে একটি প্রদান করুন';
	@override String noReachableServer({required Object product}) => 'পাওয়া যায় না ${product} সার্ভার';
	@override String urlsPointToDifferentServers({required Object product}) => 'এই URLগুলি বিভিন্ন ${product} সার্ভারগুলিকে লক্ষ্য করে';
	@override String urlDoesNotMatchServer({required Object product}) => 'এই URLটি সার্ভার ${product} এর সাথে সংযুক্ত নয়';
	@override String get redirectUnsupported => 'সার্ভার একটি সমর্থিত URL-এর জন্য পুনরায় পরিচালিত';
	@override String redirectDifferentHost({required Object product}) => 'সার্ভারটি অন্য হোস্টের জন্য রেকর্ড করা হয়. শেষ URL ${product} সরাসরি প্রদান করুন.';
	@override String get redirectInsecure => 'সার্ভারটি HTTPS থেকে নিরাপদ URL-এর জন্য রেকর্ড করা হয়';
	@override String redirectUnsupportedEnterFinal({required Object product}) => 'সার্ভারটি একটি সমর্থিত URL-এর জন্য পুনরায় পরিচালিত হয়. শেষ URL ${product} সরাসরি প্রদান করুন.';
	@override String get directPlexServerUrl => 'Plex সার্ভার URL';
	@override String get directPlexServerUrlHelper => 'আপনার Plex মিডিয়া সার্ভারের স্থানীয় আইপি এবং পোর্ট প্রদান করুন।';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex টোকেন (অন্যাশনাল)';
	@override String get plexTokenHelper => 'এই সার্ভারে AUTH ছাড়া অ্যাক্সেস অনুমোদিত হয় যদি এটি অ্যাক্সেস করা হয়।';
	@override String get plexTokenRequired => 'আপনার টোকেন Plex (X-Plex-Token) লিখুন।';
	@override String get connectDirectPlexCard => 'Plex মিডিয়া সার্ভার (প্রাস্তিক / স্থানীয়)';
	@override String get connectDirectPlexCardSubtitle => 'স্থানীয় আইপি বা URL ব্যবহার করে সরাসরি সংযোগ করুন plex.tv অ্যাকাউন্ট ছাড়া।';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => 'স্থানীয় আইপি বা URL ব্যবহার করে সরাসরি সংযোগ করুন. ${name} এর সাথে সংযোগ করুন.';
	@override String get insecureTitle => 'অক্রিপ্ট সংযোগ';
	@override String insecureDescription({required Object url}) => '${url} HTTP ব্যবহার করে। নেটওয়ার্কের অন্যরা আপনার পাসওয়ার্ড, টোকেন ও মিডিয়া পড়তে বা পরিবর্তন করতে পারে। সম্ভব হলে HTTPS ব্যবহার করুন। এই নেটওয়ার্ককে বিশ্বাস করলে এবং ঝুঁকি মেনে নিলেই কেবল এগিয়ে যান।';
	@override String get allowHttp => 'HTTP-এর অনুমতি দিন';
	@override String get httpsRequired => 'HTTPS ব্যবহার করুন বা স্পষ্টভাবে একটি অক্রিপ্ট সংযোগ অনুমতি দেয়।';
}

// Path: cast
class _Translations$cast$bn extends Translations$cast$en {
	_Translations$cast$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => 'কোনো ডিভাইসে কাস্ট করুন';
	@override String get searching => 'খুঁজে বের করতে গিয়েছে ক্যাস্ট ডিভাইস...';
	@override String connectedTo({required Object device}) => 'সংযোগ ${device}';
	@override String get device => 'কাস্ট ডিভাইস';
	@override String get readyToCast => 'কাস্ট করার জন্য প্রস্তুত';
	@override String get subtitle => 'সাবটাইটেল';
	@override String get serverNotAvailable => 'মিডিয়া সার্ভার পাওয়া যায় না।';
	@override String get stopCasting => 'কাস্ট করা বন্ধ করুন';
	@override String get castToDevice => 'ডিভাইসে কাস্ট করুন';
	@override String get noEpisodeAvailable => 'খেলাটি খেলতে পাওয়া যায় না।';
	@override String get startFailed => 'সার্ভার দেখুন এবং আবার চেষ্টা করুন।';
}

// Path: automation
class _Translations$automation$bn extends Translations$automation$en {
	_Translations$automation$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => 'নিয়ন্ত্রণ করার জন্য কোন সক্রিয় ভিডিও সেশন নেই।';
}

// Path: notifications
class _Translations$notifications$bn extends Translations$notifications$en {
	_Translations$notifications$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => 'নতুন epizode';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appAccess
class _Translations$appAccess$bn extends Translations$appAccess$en {
	_Translations$appAccess$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'সাত দিনের জন্য প্রতিটি ফ্রি ফাইনাল চেষ্টা করুন।';
	@override String get description => 'সাত দিনের একটি পরীক্ষা শুরু করুন, প্রতিটি PlezyNG বৈশিষ্ট্যগুলির পূর্ণ অ্যাক্সেসের সাথে. পরীক্ষার সময় কোন ফরজ নেই এবং কোন অ্যাকাউন্ট নেই. পরীক্ষার পরে, আপনার দোকানের মূল্যতে একটি জীবন-যাত্রা কিনা PlezyNG জীবন-যাত্রা জন্য লুকিয়ে দেয়।';
	@override String get trialEndedDescription => 'আপনার দোকানের মূল্যতে একটি কেনার সাথে জীবনযাপনের জন্য PlezyNG এর প্রতিটি বৈশিষ্ট্য বন্ধ করুন।';
	@override String get startTrial => 'সাত দিনের বিনামূল্যে পরীক্ষা শুরু করুন';
	@override String get trialActive => 'আপনার সাত দিনের full-feature পরীক্ষা কার্যকর।';
	@override String get trialEnded => 'সাত দিনের মামলা শেষ হয়েছে।';
	@override String get trialStartFailed => 'এই ডিভাইসে পরীক্ষা সংরক্ষণ করতে পারিনি, कृपया আবারও চেষ্টা করুন।';
	@override String get lifetimeTitle => 'PlezyNG জীবনের জন্য অপসারণ';
	@override String get lifetimeBody => 'ধন্যবাদ! আপনি প্রতিটি PlezyNG বৈশিষ্ট্যে জীবনযাপন করতে পারেন।';
	@override String get manageTitle => 'PlezyNG জীবনের অ্যাক্সেস';
	@override String get manageDescription => 'প্রতিটি বৈশিষ্ট্যটি সাত দিনের জন্য বিনামূল্যে চেষ্টা করুন, তারপর আপনার দোকানের মূল্যে এক টাকা দিয়ে জীবনের জন্য সবকিছু খোঁজে ফেলুন।';
	@override String buy({required Object price}) => '${price} এর জন্য প্রতিটি বৈশিষ্ট্য খোলা';
	@override String get loadingPrice => 'লোডিং দোকান মূল্য...';
	@override String get retryPrice => 'ফেরতের মূল্য অনুসরণ';
	@override String get restore => 'জীবনযাত্রা খরচ পুনরায়';
	@override String get pending => 'আপনার কেনা भुगतान বা অনুমোদন অপেক্ষায় থাকে. লাইফ টাইম অ্যাক্সেস বন্ধ হয়ে যায় যখন স্টোর এটি সম্পূর্ণ করে।';
	@override String get storeUnavailable => 'কেনাকাটা পাওয়া যায় না. দেখুন যে আপনি স্টোরে স্বাক্ষর করা হয়েছে এবং কেনাকাটা এই ডিভাইসে অনুমোদিত হয়।';
	@override String get productNotFound => 'এই স্টোরে এখনো PlezyNG লাইভ লাইভ লক পাওয়া যায় না।';
	@override String get productQueryFailed => 'দোকান মূল্য লোড করতে পারবেন না. আপনার সংযোগ চেক করুন এবং আবার চেষ্টা করুন।';
	@override String get purchaseFailed => 'কেনাকাটা শেষ হয়নি, আবারও চেষ্টা করুন।';
	@override String get restoreFailed => 'আপনি আপনার কেনাকাটা ফিরিয়ে দিতে দোকান পৌঁছাতে পারবেন না. আবার চেষ্টা করুন.';
	@override String get nothingToRestore => 'এই স্টোর অ্যাকাউন্টের জন্য নম্বর PlezyNG লাইভ লাইভ ক্রয় পাওয়া যায়।';
}

// Path: detail
class _Translations$detail$bn extends Translations$detail$en {
	_Translations$detail$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => 'ফাইনাল ${time}';
}

// Path: watchLink
class _Translations$watchLink$bn extends Translations$watchLink$en {
	_Translations$watchLink$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => 'এই লিঙ্কের জন্য Plex সার্ভার পৌঁছাতে পারিনি।';
	@override String get notFound => 'আপনার সার্ভারগুলিতে এই প্রদর্শন বা ভিডিওটি পাওয়া যায় না Plex।';
	@override String get ambiguous => 'এই লিঙ্কটি একটি সার্ভারের বেশি পণ্যগুলির সাথে সমাধান করে. লিঙ্কটিতে সার্ভার যোগ করুন.';
	@override String get plexOnly => 'দেখুন লিঙ্কগুলি বর্তমানে শুধুমাত্র Plex সার্ভারগুলি সমর্থন করে।';
	@override String get unsupportedItem => 'দেখুন লিঙ্কগুলি শুধুমাত্র একটি প্রদর্শনী বা একটি চলচ্চিত্র খুলতে পারে।';
	@override String get menuItem => 'দেখুন লিঙ্ক';
	@override String get dialogTitle => 'দেখুন লিঙ্ক';
	@override String get dialogShowHint => 'এই লিঙ্কটি খুলতে পরবর্তী অধ্যায় খেলবে. শফলে शो খেলতে শেষ পর্যন্ত &mode=shuffle যোগ করুন।';
	@override String get dialogMovieHint => 'এই লিঙ্কটি খুলে চলচ্চিত্রটি খেলবে।';
	@override String get copy => 'কপি';
	@override String get copied => 'লিঙ্ক কপি';
}

// Path: homeLayout
class _Translations$homeLayout$bn extends Translations$homeLayout$en {
	_Translations$homeLayout$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Home লিওট';
	@override String get resetToast => 'Home Reset to the original Plezy হেরো layout';
	@override String get resetHeroTitle => 'হ্যারি ল্যাগিংটি পুনরায় স্টক Plezyতে ফেরত?';
	@override String get resetHeroBody => 'প্রতিটি রানের হেরো সিস্টেম বন্ধ করে এবং হোমের শীর্ষে একমাত্র রুটিং ব্যানার ফেরত দেয়, যেমন হেরো রানগুলি আগে ছিল।';
	@override String get removeRowTitle => 'Home রান্না বন্ধ করুন?';
	@override String removeRowBody({required Object title}) => '${title} মুছে ফেলবে. এটি অস্বীকার করা যাবে না।';
	@override String get sync => 'সিনক';
	@override String get syncAccountTitle => 'আপনার অ্যাকাউন্ট Plex সঙ্গে সিনিক্রেশন layout';
	@override String get syncAccountOn => 'এ: এই ডিভাইস আপনার অন্যান্য ডিভাইসের সাথে পরিকল্পনা, পরিকল্পনা, হেরো এবং অটো-স্লাইড শেয়ার করে।';
	@override String get syncAccountOff => 'ডাউনলোড: এই ডিভাইস নিজের লাইজিং রাখে।';
	@override String get syncNow => 'এখন সিনক';
	@override String get plexHomeManager => 'Plex হোম ম্যানেজার';
	@override String get managePlexRows => 'পরিচালনা Plex লাইন Plezy';
	@override String get managePlexRowsDescription => 'Home-Selected রানগুলি সংগঠন করার জন্য খোলা';
	@override String get organizeHomeRows => 'Home রানার সংগঠন';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} লাইন: গাড়ি, হেরো, অটো-স্লাইড, মুছে ফেলুন';
	@override String organizeLibraryRows({required Object library}) => 'সংগঠন ${library} লাইন';
	@override String organizeLibraryRowsDescription({required Object n}) => 'Continue Watching + ${n} লাইন: গাড়ি, লাইব্রেরি, বাড়ি, হেরো, অটো-স্লাইড';
	@override String get renderAsHero => 'কার্ডের হেয়ার হিসাবে রেন্ডার';
	@override String get heroOnlySingleCollection => 'শুধুমাত্র এই পর্যায়ে একক সংগ্রহের বাস্তব টাইমগুলিতে সমাধান করা হয়';
	@override String get hero => 'হেরো';
	@override String get autoSlide => 'অটো-স্লাইড';
	@override String get autoSlideDescription => 'এছাড়াও প্রতি কয়েক সেকেন্ডে নিজেদের সাথে স্লাইড করে. লোড (PC) এবং ড-প্যাড (TV) সবসময় কাজ করে এবং টাইমারটি পুনরায় চালু করে।';
	@override String get autoSlideEditDescription => 'এছাড়াও প্রতি কয়েক সেকেন্ডে নিজে থেকে স্লাইড করে. অটো: শুধুমাত্র একটি প্লাইড (PC) ক্লিক করে বা দূরে (TV) বাম / ডান চাপ করে যখন移動 করে. প্লাইড এবং d-প্যাড সবসময় উভয়ভাবে কাজ করে।';
	@override String get enableHeroFirst => 'প্রথমে হেরো';
	@override String get showOnHome => 'Home Screen দেখুন';
	@override String get home => 'বাড়ি';
	@override String get removeFromHome => 'বাড়ি থেকে বের করা';
	@override String get selectRowsFirst => 'প্রথমে নিচে হোম রানগুলি নির্বাচন করুন।';
	@override String plexManagedRows({required Object n}) => '${n} Plex পরিচালিত লাইন';
	@override String get continueWatching => 'দেখা অব্যাহত রাখুন';
	@override String get continueWatchingLibraryDescription => 'এই লাইব্রেরির নিজস্ব পুনরাবৃত্তি-প্রগ্রেস লাইন';
	@override String get continueWatchingHomeDescription => 'বাড়িতে প্রদর্শনিত পুনরাবৃত্তি-প্রদর্শন পর্যায়ে';
	@override String get nextUpHomeDescription => 'Next Unwatched Episode পরবর্তী পরিস্থিতি নির্দিষ্টভাবে দেখানো হয় Home';
	@override String get library => 'লাইব্রেরি';
	@override String get showInRecommended => 'লাইব্রেরিতে প্রদর্শন করা উচিত';
	@override String get customPlexRow => 'কাস্টম Plex রান';
	@override String get heroNeedsLibrary => 'প্রথমে লাইব্রেরি চেক করুন — হ্যারো দেখার জন্য কোথাও প্রয়োজন';
	@override String get heroNeedsSurface => 'প্রথমে লাইব্রেরি বা হোম দেখুন — হেরো দেখার জন্য কোথাও প্রয়োজন';
	@override String get removeHub => 'হাব থেকে বের করুন';
	@override String get noPlexRows => 'নম্বর Plex পরিচালিত লাইন এই লাইব্রেরি জন্য ফিরে এসেছে।';
	@override String get openDetails => 'খোলা বিস্তারিত';
	@override String get heroCards => 'হেরো কার্ড';
	@override String get tapHeroCard => 'হ্যারিয়ার কার্ড খুঁজে বের';
	@override String get tvPlayFocus => 'টেলিভিশন দূরে: উচ্চ আলো Play बटन';
	@override String get tvPlayFocusDescription => 'ড-প্যাড ডাউনলোড খেলা বোতামটি বন্ধ করে, পরবর্তী লাইন থেকে চলে যাওয়ার আগে।';
	@override String get tvWrap => 'টেলিভিশন দূরে: লপ হেরো কার্ড';
	@override String get tvWrapDescription => 'শেষ কার্ডের দিকে প্রথম কার্ডের দিকে ফিরে যায়. শেষ কার্ডের দিকে বন্ধ থাকে. প্রথম কার্ডের দিকে সবসময় পাশের দিকে যায়.';
	@override String get castOnHero => 'হ্যারি ব্যানার';
	@override String get castOnHeroDescription => 'একটি হ্যারি ব্যানারের নম্বরে চিঠি প্রদর্শন করুন. অন্তর্ভুক্ত রাখে শুধুমাত্র शीर्षक এবং সংখ্যা।';
	@override String get customRows => 'কাস্টম রাস্তায়';
	@override String get loading => 'Home Layout লোডিং...';
	@override String get noCustomRows => 'এখনো কোন কাস্টম রাইড নেই';
	@override String get addRowHint => 'একটি তৈরি করার জন্য বাড়ি লাইন যোগ করুন।';
	@override String get addHomeRow => 'বাড়ি রান করুন';
	@override String get addHomeRowDescription => 'একটি বিভাগ নির্বাচন করুন; নতুন পর্যায়ে স্বয়ংক্রিয়ভাবে সংস্থার যোগ করা হয়';
	@override String get removeRow => 'রানী মুছে ফেলে';
	@override String get recentlyAdded => 'সম্প্রতি যোগ করা';
	@override String get recentlyReleased => 'সম্প্রতি মুক্তি';
	@override String get movieCollections => 'চলচ্চিত্র সংগ্রহ';
	@override String get showCollections => 'সংগ্রহ দেখুন';
	@override String get rowTitle => 'রু টাইম';
	@override String get content => 'উপভোগ';
	@override String get showThisRowIn => 'এই রান দেখুন:';
	@override String get libraryRecommended => 'লাইব্রেরি প্রস্তাব';
	@override String get heroCard => 'হেরো কার্ড';
	@override String get heroCardDescription => 'একটি পেস্টের ছাপের পরিবর্তে একটি পুরো ব্যাগ রুটিং কার্ড হিসাবে প্রদর্শন করা হয়।';
	@override String get heroUnavailableDescription => 'শুধুমাত্র এই পর্যায়ে একক সংগ্রহের বাস্তব টাইমগুলির জন্য সমাধান করা হয় - একটি সংগ্রহের বেশি নির্বাচন করা হয়, কোন একটি টাইম ঘুরতে হবে না।';
	@override String get librariesSelection => 'লাইব্রেরি (একটি লাইব্রেরি প্রত্যেকের জন্য চেক না করে রাখুন)';
	@override String get librariesMergedDescription => 'এখানে চেক করা প্রতিটি লাইব্রেরি এই এক লাইনে যোগ করা হয়।';
	@override String get movieCollectionsSelection => 'চলচ্চিত্র সংগ্রহ (প্রত্যেক নির্বাচিত লাইব্রেরি জন্য সব অচেনা রাখুন)';
	@override String get showCollectionsSelection => 'সংগ্রহগুলি দেখুন (প্রত্যেকটি নির্বাচিত লাইব্রেরি জন্য সমস্ত চেক না রাখুন)';
	@override String get collectionRowsDescription => 'যদি একটি সংগ্রহ একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু';
	@override String get allCollections => 'সকল সংগ্রহ';
	@override String get noRowsHere => 'এখনো এখানে কোন রান নেই।';
	@override String get hideWatchedRows => 'চিহ্নিত পণ্যগুলি সুরক্ষিত';
	@override String get hideWatchedRowsDescription => 'পুরোপুরি দেখানো টাইম বাড়ি এবং লাইব্রেরি রিপোর্টের লাইন ছেড়ে দেয়।';
	@override String get untitledCollection => 'অথিত সংগ্রহ';
	@override String get moveRowHint => 'আপ/ডাউন: লাইন বের করুন · Select: drop it here · Back: cancel';
	@override String get organizeRowsHint => 'একটি পর্যায়ে নির্বাচন করুন (অথবা রাখুন Select): move it · Left/Right: line options · Back: done';
	@override String get layoutNavDescription => 'লাইব্রেরি, লাইব্রেরি এবং সংগ্রহ বিভাগগুলি নির্বাচন করুন';
	@override String get editHomeRow => 'Edit Home রান';
	@override String get resetHeroButton => 'হ্যারি রেজিস্ট্রেশন পুনরায় স্টক Plezy';
	@override String get reorderingUnlocked => 'অ্যাক্সেস অ্যাক্সেস';
	@override String get reorderingLocked => 'লুকিয়ে রাখা';
	@override String get rowsCanBeDragged => 'চুলগুলি চাপ করা যেতে পারে - এই অ্যাক্সেসের জন্য লকটি চাপ করুন';
	@override String get tapLockToDrag => 'লকটি চাপিয়ে চাপিয়ে রাখুন';
	@override String customRowLabel({required Object title}) => 'কাস্টম: ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => 'লুকিয়ে';
	@override String get remove => 'সরান';
	@override String get libraryResumeRow => 'এই লাইব্রেরি রেজিস্ট্রেশন';
	@override String get pressAgainToDelete => 'আবারও চাপ করুন মুছে ফেলুন';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => 'এতে';
	@override String get resetHeroButtonDescription => 'প্রতিটি রানের হেরো সিস্টেম বন্ধ করে এবং হেরো রানগুলি অস্তিত্বের আগের মতো একটি রুটিং ব্যানার পেরিয়ে দেয়।';
	@override String get tapHeroCardDescription => 'সিদ্ধান্ত করুন যে একটি হেরো কার্ডটি ট্যাপিং বা নির্বাচন করে Playback শুরু হয় কিংবা তার ডেটা খুলে যায়।';
	@override String get heroTapPlayDescription => 'দ্রুত নির্বাচন করা পণ্য শুরু করুন।';
	@override String get heroTapDetailsDescription => 'একটি পদক্ষেপ নির্বাচন করার আগে নির্বাচিত পণ্যের বিস্তারিত খুলুন।';
}

// Path: platform
class _Translations$platform$bn extends Translations$platform$en {
	_Translations$platform$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'PlezyNG আপনার স্থানীয় নেটওয়ার্কে আপনার মিডিয়া সার্ভার এবং প্লেব্যাক ডিভাইসের সাথে সংযোগ করে।';
	@override String get locationPermission => 'PlezyNG আপনার স্থানীয় নেটওয়ার্ক এবং আপনার মিডিয়া সার্ভারগুলিতে সংযোগ করার জন্য iOS এর প্রয়োজনীয় অবস্থান অ্যাক্সেস ব্যবহার করে।';
	@override String get photoLibraryPermission => 'আপনার ফটো লাইব্রেরি থেকে ছবিগুলি মিডিয়া শিল্প হিসেবে ব্যবহার করার জন্য নির্বাচন করুন।';
	@override String get cameraPermission => 'Companion Remote জোড়া লাগাতে QR কোড স্ক্যান করুন।';
}

// Path: universalMedia
class _Translations$universalMedia$bn extends Translations$universalMedia$en {
	_Translations$universalMedia$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'খোলা মিডিয়া';
	@override String get shortcutHelp => 'এই session জন্য একটি লিঙ্ক, Playlist বা ফাইল খেলুন।';
	@override String get intro => 'একটি লিঙ্ক, Playlist বা ফাইল খোলা. Playback PlezyNG এর স্ট্যান্ডার্ড প্লেয়ার ব্যবহার করে এবং আপনার লাইব্রেরিতে ইতিহাস যোগ করেন না।';
	@override String get openWhat => 'আপনি কী খুলে দিতে চান?';
	@override String get stream => 'স্ট্রিম ঠিকানা';
	@override String get playlist => 'Playlist খেলা';
	@override String get files => 'ডিভাইস ফাইল';
	@override String get favorites => 'সুরক্ষিত প্রদর্শন পছন্দ';
	@override String get address => 'মিডিয়া ঠিকানা';
	@override String get addressHelp => 'HTTPS preferred. recognized credential বা signature parameters সঙ্গে URLs শুধুমাত্র এই session জন্য ব্যবহার করা হয় এবং পছন্দ হিসাবে সংরক্ষণ করা যাবে না।';
	@override String get displayName => 'ডাউনলোড নাম (অ্যাপ্লিকেশন)';
	@override String get displayNameHelp => 'খেলোয়াড় এবং সিস্টেম মিডিয়া কন্ট্রোলগুলির জন্য একটি ছোট নাম নির্বাচন করুন।';
	@override String get allowHttp => 'একটি অক্রিপ্ট HTTP সংযোগ অনুমোদন';
	@override String get allowHttpHelp => 'HTTP সংযোগটি সক্রিপ্ট করে না. এটি শুধুমাত্র একটি বিশ্বাসযোগ্য নেটওয়ার্কে অনুমতি দেয়. সম্ভবত HTTPS ব্যবহার করুন.';
	@override String get advancedProtocols => 'MPV শুধুমাত্র: একটি RTSP, RTMP/RTMPS, UDP বা RTP ঠিকানা লিখুন. এই ঠিকানাগুলি প্রিয় হিসাবে সংরক্ষণ করা যাবে না।';
	@override String get liveStream => 'বেঁচে থাকার মতো আচরণ';
	@override String get liveStreamHelp => 'এটি লাইভ ভিডিও বা রেডিও জন্য ব্যবহার করুন. অ্যাপটি টাইম বার, স্কপ বোতল এবং গিয়ে-টাইম অপশনকে ঘুরে রাখে. একটি রেকর্ড করার জন্য এটি বন্ধ করে।';
	@override String get privateSession => 'শুধুমাত্র এই প্লেব্যাক ঠিকানা ব্যবহার করে. এই প্রোফাইলে রাখার জন্য একটি অনুমোদিত স্ট্রিম প্রিয় সংরক্ষণ করুন.';
	@override String get saveFavorite => 'পছন্দ সংরক্ষণ';
	@override String get playNow => 'এখন খেলুন';
	@override String get favoriteSaved => 'এই প্রোফাইলে সুরক্ষিত পছন্দ স্ট্রিম';
	@override String skippedEntries({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n,
		one: '${count} অসহায় বা নিরাপদ Playlist প্রবেশ।',
		other: '${count} সমর্থিত বা নিরাপদ Playlist অন্তর্ভুক্ত।',
	);
	@override String get playlistAddress => 'Playlist ঠিকানা';
	@override String get playlistAddressHelp => 'একটি ওয়েব ঠিকানা থেকে একটি M3U, M3u8, বা PLS প্লেলিস্ট খোঁজ করুন. সরাসরি প্রদর্শন লিঙ্কগুলি প্লেলেস্ট সংরক্ষণ করে না।';
	@override String get choosePlaylist => 'Playlist ফাইল নির্বাচন করুন';
	@override String get openPlaylist => 'খোলা Playlist';
	@override String get playlistFormatsHelp => 'একটি খেলা লিস্টে সর্বাধিক 1,000 পণ্য এবং 2 মিবি রয়েছে. HLS স্ট্রিম হিসাবে খোলা হয়, তাই খেলোয়াড় একটি মান নির্বাচন করতে পারেন।';
	@override String get saveQueuePlaylist => 'কিউ প্লেলিস্ট হিসেবে সংরক্ষণ করুন';
	@override String get queuePlaylistSaved => 'মিডিয়া ফাইলগুলোর পাশে প্লেলিস্ট সংরক্ষিত হয়েছে।';
	@override String get queuePlaylistUnavailable => 'এই কিউ পুনরায় ব্যবহারযোগ্য স্থানীয় প্লেলিস্ট হিসেবে সংরক্ষণ করা যাবে না।';
	@override String get queuePlaylistFolderRequired => 'কিউতে থাকা ফাইলগুলোর একই ফোল্ডারে সংরক্ষণের স্থান বেছে নিন।';
	@override String get noFavorites => 'এখনো কোন প্রেমের পছন্দ সংরক্ষণ করা হয় না. পছন্দের এই प्रोফাইলে থাকুন।';
	@override String get removeFavorite => 'প্রিয় স্ট্রিম মুছে ফেলুন';
	@override String get filesHelp => 'অডিও, ভিডিও বা আইএসও ফাইলগুলি একটি temporary quue জন্য নির্বাচন করুন. ফাইল এবং URLs লাইব্রেরির ইতিহাসে যোগ করা হয় না।';
	@override String get chooseFiles => 'ফাইল নির্বাচন';
	@override String fileQueue({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n,
		one: '1 নির্বাচিত ফাইল',
		other: '${count} নির্বাচিত ফাইল',
	);
	@override String get wifiTransfer => 'Wi-Fi এর মাধ্যমে ফাইল পাঠান';
	@override String get wifiTransferHelp => 'সমর্থিত ফাইলগুলি এক ব্রাউজার থেকে একই বিশ্বাসযোগ্য নেটওয়ার্কে স্থানান্তর করুন।';
	@override String get wifiTransferIntro => 'অন্য ডিভাইসের একটি ব্রাউজারে এই ঠিকানা খোঁজ করুন. ফাইলগুলি নির্বাচন করে এই ডিভিশনের ফাইল এবং বই লাইব্রিয়ামে যোগ করুন.';
	@override String get wifiTransferPrivacy => 'এই ডিভাইস আপনার স্থানীয় নেটওয়ার্কের মাধ্যমে ফাইল গ্রহণ করে. যে কেউ এই ঠিকানা জানে, আপনি ট্রান্সফার বন্ধ করা পর্যন্ত ফাইল পাঠাতে পারেন বা ঠিকানা 15 মিনিট পরে শেষ হয়. সর্বোচ্চ: 100 ফাইল, 4 জিবি প্রতি ফিল, 10 জিबी মোট।';
	@override String get wifiTransferStarting => 'একটি ব্যক্তিগত, সময় সীমিত স্থানান্তর প্রস্তুত ...';
	@override String get wifiTransferUnavailable => 'স্থানীয় নেটওয়ার্ক অ্যাক্সেস চেক করুন এবং আবার চেষ্টা করুন।';
	@override String get openThisAddress => 'এই ডিভাইসের একটি ঠিকানা খুলুন';
	@override String get copyAddress => 'কপি Transfer Address';
	@override String get addressCopied => 'প্রদর্শন ঠিকানা কপি';
	@override String transferExpires({required Object time}) => 'এই ঠিকানাটি ${time} এর মধ্যে শেষ হয়।';
	@override String uploadCount({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n,
		one: '${count} ফাইল গ্রহণ',
		other: '${count} ফাইল গ্রহণ',
	);
	@override String uploadedData({required Object size}) => '${size} পেয়েছেন';
	@override String get stopTransfer => 'স্থানান্তর বন্ধ করুন এবং ঠিকানা বাতিল করুন';
	@override String get startTransfer => 'ট্রেডিং শুরু';
	@override String get wifiImportedFiles => 'Wi-Fi ট্রান্সফার';
	@override String get wifiBrowserTitle => 'ফাইল পাঠান PlezyNG';
	@override String get wifiBrowserIntro => 'অডিও, ভিডিও, ইবুক বা কমিক ফাইলগুলি পাঠানোর জন্য নির্বাচন করুন. ফাইলগুলো এই ডিভাইসের ফাইল এবং বই লাইব্রিয়ামে সংরক্ষণ করা হয়. সর্বোচ্চ: 100 ফাইল, 1 ফাইল প্রতি 4 জিবি, 10 জিबी মোট।';
	@override String get uploadFilesLabel => 'ফাইল পাঠানো';
	@override String get uploadSelected => 'নির্বাচিত ফাইল আপলোড করুন';
	@override String get uploadSelectFirst => 'প্রথমে একটি বা বেশী ফাইল নির্বাচন করুন।';
	@override String get uploading => 'পাঠান';
	@override String get uploadComplete => 'ফাইলটি PlezyNGে যোগ করা হয়।';
	@override String get uploadFailed => 'ফাইলটি যোগ করা যায় না. এই পৃষ্ঠা খোলা রাখুন এবং আবার চেষ্টা করুন।';
	@override String get liveCue => 'লাইভ';
	@override String get liveSession => 'লাইভ স্ট্রিম';
	@override String get liveCueHelp => 'লাইভ ভিডিও বা রেডিও জন্য, অ্যাপটি সময় প্যাকেট সুরক্ষা করে এবং হ্রাস बटन. এটি ঠিকানা সংরক্ষণ করেন না বা ইতিহাস দেখেনি।';
	@override String get sessionOnly => 'এই গেমটি শুধু সেশন-এই।';
	@override String get sessionOnlyHelp => 'Playback কখনো উন্নয়ন বা ইতিহাস সংরক্ষণ করে না. এই প্রোফাইলে রাখার জন্য পছন্দ হিসাবে স্ট্রিম সংরক্ষণ করুন, যদি এটি অনুমোদিত হয়।';
	@override String get pictureAdjustments => 'ছবি সংশোধন';
	@override String get pictureHelp => 'এই ছবি পরিবর্তনগুলি শুধুমাত্র এই প্লেব্যাককে প্রভাবিত করে. তারা প্লেবেক শেষ হওয়ার পর আবারও স্থাপন করে।';
	@override String get resetPicture => 'পুনরায় ছবি';
	@override String get brightness => 'উজ্জ্বল';
	@override String get contrast => 'প্রতিরোধ';
	@override String get gamma => 'গেম';
	@override String get hue => 'হুই';
	@override String get saturation => 'সুরআন';
	@override String get view360 => '360° ভিডিও জন্য ফ্ল্যাট প্রদর্শন';
	@override String get view360Help => 'এছাড়াও 360° ভিডিও ব্যবহার করুন. MPV এর জন্য FFmpeg\'s v360 ফিল্টার প্রয়োজন।';
	@override String get view360Unavailable => 'এই MPV গঠন 360° ফিল্টার ব্যবহার করতে পারে না।';
	@override String get view360Yaw => 'Horizontal ভাবনা';
	@override String get view360Pitch => 'ভার্চিক দৃষ্টিভঙ্গি';
	@override String get view360FieldOfView => 'দৃষ্টিভঙ্গি জায়গা';
	@override String get recordStream => 'Live Stream রেকর্ড';
	@override String get stopRecording => 'রেকর্ডিং বন্ধ এবং সংরক্ষণ করুন';
	@override String get recordingStarted => 'রেকর্ডিং সক্রিয়. Playback বন্ধ করে এবং রেকডিং সংরক্ষণ করে।';
	@override String get recordingSaved => 'রেকর্ড শেষ এবং সংরক্ষিত।';
	@override String get recordingActive => 'এই ডিভাইস থেকে রেকর্ড করুন. Playback বন্ধ করে এবং এটি সংরক্ষণ করে।';
	@override String get recordingFormatHelp => 'ভিডিও জন্য, MKV বা MPEG-TS নির্বাচন করুন. অডিও জন্য, MKA বা MKV নির্বাচন করুন।';
	@override String get replaceRecordingTitle => 'এই রেকর্ড পরিবর্তন করবেন?';
	@override String get replaceRecordingHelp => 'রেকর্ডিংয়ের সময় PlezyNG বর্তমান ফাইলটি পিছিয়ে রাখে. যদি এটি নতুন রেকার্ড সংরক্ষণ করতে পারে না, তাহলে plezyNG সাপোর্ট পুনরাবৃত্তি করে।';
	@override String get replaceRecording => 'ফাইল পরিবর্তন';
	@override String get discHelp => 'এই কম্পিউটারের অপটিক ড্রাইভে একটি ডিস্ক খুলুন. আপনি ডিভাইস ফাইল থেকে আইএসও ইমেজ খুলতে পারেন।';
	@override String get discs => 'অপটিক্যাল ডিভাইস';
	@override String get editionOrTitle => 'সংস্করণ বা ডিস্কের শিরোনাম';
	@override String get dvd => 'ডিভিডি';
	@override String get bluray => 'ব্লু-রাই';
	@override String get audioCd => 'অডিও সিডি';
	@override String get discAvailability => 'ডিভাইস প্লেব্যাক একটি সামঞ্জস্যপূর্ণ MPV গঠন, সমর্থিত ড্রাইভ এবং অপারেটিং সিস্টেম অনুমতি প্রয়োজন. এটি বাণিজ্যিক ডিভিডি রক্ষা অতিক্রম করতে পারে না।';
	@override String get converterTitle => 'স্থানীয় গণমাধ্যম ফাইল পরিবর্তন';
	@override String get converterHelp => 'একটি স্থানীয় ফাইল পরিদর্শন করুন অথবা এটি রেমুশ করতে FFmpeg.';
	@override String get converterIntro => 'একটি স্থানীয় অডিও বা ভিডিও ফাইলটি একাধিক ডিভাইসের উপর কাজ করে ফর্মটামে পরিদর্শন করুন।';
	@override String get converterPrivacy => 'FFmpeg এই কম্পিউটারে ইনস্টল করা উচিত. Conversion শুধুমাত্র স্থানীয় ফাইলগুলি পড়বে. এটি স্ট্রিম ডাউনলোড করে না বা DRM মুছে নেয় না।';
	@override String get converterChooseInput => 'স্থানীয় মিডিয়া ফাইল নির্বাচন করুন';
	@override String get converterFormat => 'উত্পাদন ফরম্যাট';
	@override String get converterMp4 => 'MP4 · H.264 এবং AAC';
	@override String get converterM4a => 'M4A · AAC অডিও';
	@override String get converterMp3 => 'MP3 অডিও';
	@override String get allowFtp => 'FTP অনুমোদন';
	@override String get allowFtpHelp => 'FTP ক্রিপ্টিং ছাড়া মিডিয়া পাঠায়. শুধুমাত্র বিশ্বাসযোগ্য নেটওয়ার্কগুলিতে ব্যবহার করুন।';
	@override String get converterSaveAs => 'পরিদর্শন মিডিয়ার হিসাবে সংরক্ষণ করুন';
	@override String get converterExtensionMismatch => 'নির্বাচিত উত্পাদন প্রদর্শন সঙ্গে একটি ফাইল নাম নির্বাচন করুন।';
	@override String get converterUnsupportedInput => 'একটি অডিও বা ভিডিও ফাইল নির্বাচন করুন।';
	@override String get converterLocalOnly => 'নির্বাচিত ফাইল একটি স্থানীয় ডিভাইস পথ হিসাবে পাওয়া যায় না।';
	@override String get converterReplaceTitle => 'এই ফাইলটি পরিবর্তন করবেন?';
	@override String get converterReplaceHelp => 'PlezyNG বর্তমান ফাইলটি সংরক্ষণ করা পর্যন্ত রেকর্ড করে।';
	@override String get converterStarting => 'শুরু করে ফিপিএফ...';
	@override String get converterProgress => 'এই কম্পিউটারের মাধ্যমে পরিদর্শন ...';
	@override String get converterComplete => 'নতুন ফাইল প্রস্তুত।';
	@override String get converterFfmpegMissing => 'FFmpeg অথবা এই ফর্মটি সমর্থন করে না।';
	@override String get converterFailed => 'ফাইলটি পড়তে পারে এবং উদ্দেশ্য पर्याप्त বিনামূল্যে স্থান আছে কিনা নিশ্চিত করুন।';
	@override String get converterCancelled => 'অসম্পূর্ণ উৎপাদন বাতিল করা হয়েছে।';
	@override String get converterDesktopOnly => 'স্থানীয় পরিদর্শন FFmpeg ইনস্টল করা হয় ডেস্টো কম্পিউটারগুলিতে পাওয়া যায়।';
	@override String get converterStart => 'ফাইল পরিবর্তন';
	@override String get mediaToolsTitle => 'মিডিয়া সরঞ্জাম';
	@override String get mediaToolsShortcut => 'ফ্যাক্ট বা মিডিয়া শেয়ার করুন, অনুসন্ধান প্রদর্শনগুলি যোগ করুন, অথবা কমান্ড লাইন ব্যবহার করুন।';
	@override String get mediaToolsIntro => 'একটি কেন্দ্রীয় সরঞ্জাম নির্বাচন করুন. ফ্যাক্টর এবং স্ট্রিম-উট ব্যবহার করুন FFmpeg এই ডেভিসপে ইনস্টল করা হয়. Extensions এবং CLI অর্ডারগুলি সীমাবদ্ধ HTTPS অনুরোধগুলি এবং বর্তমান Open media অর্ডারগুলি ব্যবহার করে।';
	@override String get mediaToolsAccessibility => 'সরঞ্জাম নির্বাচন এবং নিয়ন্ত্রনগুলি ট্যাক্স, পয়েন্টার, ট্যাবলেট এবং D-pad ফোকসের সাথে কাজ করে। রেকর্ডিং, শেয়ার এবং অনুসন্ধান অবস্থা পরিবর্তন ঘোষণা করা হয়।';
	@override String get mediaTool => 'মিডিয়া টুল';
	@override String get captureIntro => 'আপনার স্ক্রিন বা ক্যামেরাটি এই কম্পিউটারে একটি MP4 ফাইলে রেকর্ড করুন. FFmpeg ইনস্টল করা উচিত এবং H.264 কোডার অন্তর্ভুক্ত করা উচিত।';
	@override String get captureNoDevices => 'কোন স্ক্রিন বা ক্যামেরা পাওয়া যায়নি. FFmpeg ফ্যাক্টর সাপোর্ট এবং অপারেটিং সিস্টেম গোপনীয়তা অনুমতিগুলি চেক করুন.';
	@override String get captureSource => 'স্ক্রিন বা ক্যামেরা';
	@override String get captureScreen => 'স্ক্রিন';
	@override String get captureAudioSource => 'অডিও ইনপোর্ট (অন্যাশনাল)';
	@override String get captureAudioHelp => 'একটি মাইক্রোফোন থেকে অডিও অন্তর্ভুক্ত করুন. ডিভাইস নির্বাচন FFmpeg এবং সিস্টেম অনুমতিগুলি উপর নির্ভর করে।';
	@override String get captureAudioNone => 'অডিও নেই';
	@override String get captureDefaultAudio => 'অডিও ইনপোর্ট';
	@override String get captureWaylandHelp => 'Wayland limits this XWayland capture to the X display. Windows outside XWayland may not appear.';
	@override String get captureFrameRate => 'রেকর্ড ফ্রেম ফ্রেম';
	@override String get capturePrivacy => 'রেকর্ডিংটি শুধুমাত্র আপনার বেছে নেওয়া ফাইলের জন্য সংরক্ষণ করা হয়. মাইক্রোফোন ফ্যাক্টরি অপশনীয়. PlezyNG রেকর্ডিংটি আপলোড করে না।';
	@override String get captureSaveAs => 'স্ক্রিন রেকর্ডিং রেকর্ডিং';
	@override String get captureExtensionMismatch => '.mp4 এর মধ্যে শেষ একটি ফাইল নাম নির্বাচন করুন।';
	@override String get captureFfmpegMissing => 'FFmpeg বা H.264 ভিডিও কোডার পাওয়া যায় না. একটি সমর্থিত FFmpeg নির্মাণ ইনস্টল করুন, তারপর আবার চেষ্টা করুন.';
	@override String get captureFailed => 'ডিভাইস লাইসেন্স চেক করুন, उपलब्ध স্টোরেজ, এবং FFmpeg সমর্থন।';
	@override String get captureSaved => 'স্ক্রিন রেকর্ড সংরক্ষিত।';
	@override String get captureElapsedLabel => 'রেকর্ড সময়';
	@override String get captureStart => 'রেকর্ডিং শুরু';
	@override String get capturePreview => 'প্লেয়ারে প্রিভিউ';
	@override String get capturePreviewHelp => 'নির্বাচিত উৎসটি সাধারণ প্লেয়ারে দেখুন। এটি শুধু এই সেশনের জন্য এবং কোনো রেকর্ডিং সংরক্ষণ করে না। ডিভাইস সমর্থন ও অনুমতি MPV এবং অপারেটিং সিস্টেমের ওপর নির্ভর করে। প্রিভিউতে শুধু ভিডিও থাকে; সংরক্ষিত রেকর্ডিংয়ে ঐচ্ছিক অডিও যোগ করা যায়।';
	@override String get capturePreviewActive => 'লাইভ প্রিভিউ · রেকর্ড হচ্ছে না';
	@override String get captureStop => 'বন্ধ এবং বাঁচান';
	@override String get captureMode => 'আঘাত';
	@override String get shareMode => 'শেয়ার করুন';
	@override String get shareIntro => 'আপনার ব্যক্তিগত নেটওয়ার্কের অন্য ডিভাইসে একটি স্থানীয় মিডিয়া ফাইল পাঠান. PlezyNG একটি temporary HLS স্ট্রিম তৈরি করে।';
	@override String get sharePrivacy => 'আপনার স্থানীয় নেটওয়ার্কের কেউ যারা ব্যক্তিগত লিঙ্ক পেয়েছেন, সেটি সক্রিয় থাকলেও দেখতে পারেন. লিঙ্ক 60 মিনিটের পর শেষ হয়. সার্ভার বন্ধ করতে এবং লিঙ্কটি অ্যাক্টল করতে শেয়ারিং বন্ধ করুন.';
	@override String get shareChooseFile => 'মিডিয়া ফাইল নির্বাচন';
	@override String get shareChooseHelp => 'একটি স্থানীয় অডিও বা ভিডিও ফাইল নির্বাচন করুন. ফাইলটি এই কম্পিউটারে থাকবে।';
	@override String get shareFfmpegMissing => 'FFmpeg বা H.264/AAC কোডার পাওয়া যায় না. FFmpeg ইনস্টল করুন H.264 এবং AAC কোডার সমর্থন সঙ্গে।';
	@override String get shareFailed => 'প্রদর্শন অপ্রত্যাশিতভাবে শুরু বা বন্ধ হতে পারে না. FFmpeg এবং নেটওয়ার্ক অ্যাক্সেস চেক করুন.';
	@override String get shareActive => 'আপনার ব্যক্তিগত নেটওয়ার্ক থেকে সঠিক প্রদর্শন করা হয়েছে।';
	@override String get shareEnded => 'মিডিয়া শেষ পর্যন্ত পৌঁছায় এবং এখন আর শেয়ার করা হয় না।';
	@override String get shareStopped => 'বিতর্ক বন্ধ হয়ে গেছে. সময়সীমা লিঙ্ক এখন আর সঠিক নয়।';
	@override String get shareUrlCopied => 'পুনরায় পুনরায় পুনরায় পুনরায় পুনরায় পুনরায় পুনরায়';
	@override String get shareOpenUrl => 'অন্য ডিভাইসের একটি খেলোয়াড়ে এই ঠিকানা খোলা';
	@override String get shareQrLabel => 'QR কোড temporary stream ঠিকানা';
	@override String get shareQrHelp => 'একই ব্যক্তিগত নেটওয়ার্কের সাথে সংযোগিত একটি সহযোগী খেলোয়াড়ের সাথে স্ক্যান করুন।';
	@override String get shareHttpHint => 'এই প্রদর্শনটি অক্রিপ্ট HTTP ব্যবহার করে. PlezyNGতে, HTTP খুলে যাওয়ার আগে অনুমতি দেয়।';
	@override String get shareCopyUrl => 'প্রদর্শন ঠিকানা কপি';
	@override String get shareExpiresLabel => 'লিঙ্ক শেষ হয়';
	@override String get shareStarting => 'প্রদর্শনের প্রস্তুতি...';
	@override String get shareStart => 'শেয়ার শুরু';
	@override String get shareStop => 'বিতরণ বন্ধ করুন';
	@override String get extensionsMode => 'বিতর্ক এবং CLI';
	@override String get extensionsIntro => 'মিডিয়া খুঁজে পেতে একটি ডাটা-একটি অনুসন্ধান প্রদর্শন যোগ করুন. একটি ফলাফল নির্বাচন করুন এবং এটি পরিচিত Open media ফর্মে লোড করুন.';
	@override String get extensionsPrivacy => 'একটি ম্যানজিন একটি HTTPS অনুসন্ধান শেষ পয়েন্ট এবং ম্যাপ উত্তর পৃষ্ঠাগুলি নির্ধারণ করতে পারে. এটি কোড চালান, অনুরোধ হেডার যোগ করতে পারে, ফাইলগুলি পড়তে পারে, অথবা চালু শেল নির্দেশনা.';
	@override String get extensionImport => 'বিতর্ক ম্যানেজমেন্ট যোগ';
	@override String get extensionEmpty => 'এখনো কোন অনুসন্ধান পরিষেবা নেই. একটি যোগ করার জন্য একটি নির্ভরযোগ্য প্রদর্শন JSON ফাইল নির্বাচন করুন.';
	@override String get extensionChoose => 'অনুসন্ধান সেবা';
	@override String get extensionSearchConsent => 'প্রতিটি অনুসন্ধান এই HTTPS পরিষেবাতে আপনার শব্দগুলি পাঠিয়ে দেয়. ফলাফলগুলি শুধুমাত্র একটি নির্বাচন করার পর খোলা হয়।';
	@override String get extensionSearchLabel => 'মিডিয়া অনুসন্ধান';
	@override String get extensionSearch => 'অনুসন্ধান';
	@override String get extensionSearching => 'খুঁজে...';
	@override String get extensionNoResults => 'কোন নিরাপদ মিডিয়া ফলাফল ফিরে আসেনি. আরও একটি অনুসন্ধান চেষ্টা করুন.';
	@override String get extensionInstallTitle => 'এই অনুসন্ধান পরিষেবা যোগ করুন?';
	@override String get extensionReplaceTitle => 'এই অনুসন্ধান পরিষেবা আপডেট?';
	@override String get extensionService => 'পরিষেবা';
	@override String get extensionEndpoint => 'HTTPS endpoint';
	@override String get extensionConsent => 'আপনার অনুসন্ধান টেক্সটটি এই পরিষেবাকে পাঠানো হয়. ম্যানেজিনটি কোন executable কোড নেই. Continue only if you trust this endpoint.';
	@override String get extensionInstall => 'পরিষেবা যোগ করুন';
	@override String get extensionReplace => 'আপডেট পরিষেবা';
	@override String get extensionRemoveTitle => 'এই অনুসন্ধান পরিষেবাটি মুছে ফেলুন?';
	@override String get extensionRemoveHelp => 'এতে এই প্রোফাইল থেকে পরিষেবাを取り除きます. PlezyNG তার শেষ পয়েন্টের সাথে যোগাযোগ করে না।';
	@override String get extensionRemove => 'সরবরাহ';
	@override String get extensionInvalidManifest => 'এই ফাইলটি একটি সমর্থিত প্রদর্শন ম্যানেজমেন্ট নয়. ফরম্যাটের জন্য Open media গাইড দেখুন.';
	@override String get extensionSaveFailed => 'অ্যাক্টিভ প্রোফাইলের জন্য এই প্রদর্শন সংরক্ষণ করা যায়নি।';
	@override String get extensionSearchFailed => 'অনুসন্ধান পরিষেবা একটি সঠিক উত্তর ফেরত দেয় না. শেষ পয়েন্টটি চেক করুন এবং আবার চেষ্টা করুন.';
	@override String get cliTitle => 'কমান্ড লাইন';
	@override String get cliHelp => 'plezyctl গাইড ব্যবহার করুন একটি ম্যানেজি সনাক্ত করার জন্য বা একই প্রদর্শন অনুসন্ধান করুন. প্রতিটি অনুসন্ধানের আগে তার HTTPS পরিষেবাটি দেখুন. ফলাফল বর্তমান মিডিয়া ফর্মে খোলা; শুরু করার জন্য পুনরাবৃত্তি बटन নির্বাচন করুন.';
	@override String get cliCopyExample => 'কপি কমান্ড উদাহরণ';
	@override String get cliCopied => 'উদাহরণ কপি করা হয়েছে।';
}

// Path: fileSources
class _Translations$fileSources$bn extends Translations$fileSources$en {
	_Translations$fileSources$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'ফাইল ও বই';
	@override String get subtitle => 'পড়ুন, শুনুন এবং নিজের ফাইল থেকে দেখুন।';
	@override String get add => 'উৎস যোগ করুন';
	@override String get importFiles => 'ফাইলের আমদানি';
	@override String get localFiles => 'এই ডিভাইসের';
	@override String get source => 'উৎস';
	@override String get name => 'নাম';
	@override String get endpoint => 'URL সার্ভার';
	@override String get smbEndpointHint => 'উদাহরণ: smb://nas/Movies';
	@override String get smbEndpointInvalid => 'একটি SMB সার্ভার এবং একটি শেয়ার করা ফোল্ডার লিখুন।';
	@override String get root => 'ফোল্ডার বা উপসর্গ';
	@override String get smbFolderHelp => 'পুরো শেয়ার করা ফোল্ডার ব্যবহার করতে ফাঁকা রাখুন, অথবা তার ভেতরের কোনো ফোল্ডার লিখুন।';
	@override String get username => 'ব্যবহারকারী নাম';
	@override String get smbDomain => 'ডোমেইন (ঐচ্ছিক)';
	@override String get password => 'পাসওয়ার্ড';
	@override String get token => 'API টকেন';
	@override String get accessKey => 'অ্যাক্সেস ক্লাই ID';
	@override String get secretKey => 'গোপন অ্যাক্সেস ক্লাই';
	@override String get sessionToken => 'সেশন টকেন (অন্যাশনাল)';
	@override String get region => 'এলাকা';
	@override String get clientId => 'OAuth ক্লায়েন্ট ID';
	@override String get clientSecret => 'OAuth ক্লায়েন্ট সার্ভিস (সুধুমাত্র Google ডেস্টো)';
	@override String get allowHttp => 'বিশ্বস্ত নেটওয়ার্কে এনক্রিপশনবিহীন HTTP সংযোগের অনুমতি দিন';
	@override String get smbEncryption => 'SMB3 সংযোগ এনক্রিপ্ট করুন';
	@override String get smbEncryptionHint => 'NAS সমর্থন করলে SMB3 এনক্রিপশন ব্যবহার করুন।';
	@override String get connect => 'কানেক্ট';
	@override String get cancel => 'বাতিল';
	@override String get save => 'সুরক্ষা';
	@override String get close => 'বন্ধ';
	@override String get removeSource => 'সংযোগ বন্ধ';
	@override String get disconnectMessage => 'এই উৎসের সংযোগ বিচ্ছিন্ন করবেন? ডাউনলোড করা ফাইল এবং আপনার পড়া ও শোনার ইতিহাস এই ডিভাইসে থেকে যাবে।';
	@override String get localFolder => 'ফোলার নির্বাচন';
	@override String get empty => 'এখনো এখানে কিছু নেই';
	@override String get emptyHint => 'একটি উৎস যোগ করুন বা একটি বই, অডিওবুক, গান বা ভিডিও import করুন।';
	@override String get search => 'এই ফোলার খুঁজে নিন';
	@override String get searchCached => 'সুরক্ষিত লাইব্রেরি';
	@override String get refresh => 'ফ্রিজ করুন';
	@override String get loadMore => 'আরো লোড';
	@override String get offline => 'অফলি অ্যাক্সেস';
	@override String get download => 'অফলি রাখুন';
	@override String get removeDownload => 'অফলি কপি মুছে ফেলুন';
	@override String get continueReading => 'Continue Reading পড়ুন';
	@override String get continueListening => 'শুনতে চলুন';
	@override String get continueWatching => 'দেখা অব্যাহত রাখুন';
	@override String get read => 'পড়ুন';
	@override String get listen => 'শুনুন';
	@override String get play => 'খেলা';
	@override String get pause => 'বিরতি';
	@override String get stop => 'থামুন';
	@override String get startOver => 'শুরু করে';
	@override String get finished => 'শেষ';
	@override String get markFinished => 'মারি শেষ';
	@override String get markUnfinished => 'অসম্ভব মারি';
	@override String get editions => 'সংস্করণ ও ফাইল';
	@override String get chapters => 'চিঠি';
	@override String get bookmarks => 'বইমেলা ও নোট';
	@override String get bookmark => 'Bookmark যোগ করুন';
	@override String get highlight => 'উচ্চতা';
	@override String get note => 'নোট';
	@override String get delete => 'মুছে ফেলুন';
	@override String get export => 'বিতরণ নোট';
	@override String get exported => 'বিতরণের নোট';
	@override String get sync => 'সিনক প্রসেস';
	@override String get synced => 'প্রসারিত সিন্সেস';
	@override String get conflict => 'অন্য ডিভাইসের একটি পদ্ধতি আছে. কোথায় চলতে চান তা নির্বাচন করুন.';
	@override String get useLocal => 'এই সরঞ্জাম ব্যবহার করুন';
	@override String get useRemote => 'অন্য সরঞ্জাম ব্যবহার করুন';
	@override String get history => 'অবস্থান ইতিহাস';
	@override String get groupAudio => 'শুনুন এক অডিওবুক';
	@override String get groupHint => 'এই ফোডার মধ্যে বর্তমানে লোড করা অডিও ফাইলগুলি সংযুক্ত করুন. প্রথমেই সব পৃষ্ঠা লোড করুন.';
	@override String get order => 'ফাইল আদেশ';
	@override String get moveUp => 'উড়ে উঠে';
	@override String get moveDown => 'নিচে গিয়ে';
	@override String get speed => 'গতি Playback';
	@override String get sleep => 'ঘুমের টাইম';
	@override String get sleepOff => 'বন্ধ';
	@override String get endChapter => 'চাবার শেষ';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} মিনিট',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} মিনিট',
	);
	@override String get skipBack => 'ফিরে আসুন';
	@override String get skipForward => 'এগিয়ে যান';
	@override String get smartRewind => 'একটি পাসের পর স্মার্ট ফেরত';
	@override String get playbackOptions => 'শুনতে পছন্দ';
	@override String remaining({required Object time}) => '${time} বাকি';
	@override String get contents => 'বিষয়বস্তু';
	@override String get readerSettings => 'পড়ুন সিস্টেম';
	@override String get fontSize => 'টেক্সট মাত্রা';
	@override String get lineHeight => 'লাইন স্পেসিং';
	@override String get margin => 'মারগিন';
	@override String get font => 'টাইপফেস';
	@override String get serif => 'সেরিফ';
	@override String get sans => 'সেরিফবিহীন';
	@override String get mono => 'সমপ্রস্থ';
	@override String get columns => 'কোম্পানী';
	@override String get scroll => 'ভার্চালিকভাবে স্রোল';
	@override String get justify => 'লেখা দুই পাশে সমানভাবে সাজান';
	@override String get readerTheme => 'পৃষ্ঠা প্রদর্শনী';
	@override String get appTheme => 'অ্যাপ টেমপ অনুসরণ';
	@override String get paper => 'কাবার';
	@override String get sepia => 'সাবিয়া';
	@override String get night => 'রাতে';
	@override String get readAloud => 'এই পৃষ্ঠাটি জোরে পড়ুন';
	@override String get readAlong => 'শুনতে শুনতে পড়ুন';
	@override String get stopReading => 'পড়ে শোনানো বন্ধ করুন';
	@override String get searchBook => 'বইয়ের খোঁজ';
	@override String get noMatches => 'খেলা না';
	@override String get previousPage => 'পূর্ববর্তী পাতা';
	@override String get nextPage => 'পরবর্তী পাতা';
	@override String page({required Object number}) => 'পাতা ${number}';
	@override String get externalBlocked => 'রিডারে বইয়ের বাহ্যিক লিঙ্কগুলি নিষ্ক্রিয় রয়েছে।';
	@override String get loading => 'খোলা...';
	@override String get narrator => 'ন্যাগারেট';
	@override String get audio => 'অডিও';
	@override String get video => 'ভিডিও';
	@override String get ebooks => 'ইবুক';
	@override String get all => 'সবগুলি';
	@override String get downloads => 'অফফল ফাইল';
	@override String get confirmDelete => 'নির্বাচিত অফলাইন কপিটি সরাবেন? আপনার পড়া বা শোনার অবস্থান এবং নোটগুলি সংরক্ষিত থাকবে।';
	@override String get errorAuthentication => 'আবারও এই পণ্য সংযোগ করতে চান।';
	@override String get errorPermission => 'এই উৎস অনুরোধ করা ফাইলটি ব্যবহারের অনুমতি দেয়নি।';
	@override String get errorUnavailable => 'পুনরায় চেষ্টা করুন, অথবা অফলিন কপি খুলুন।';
	@override String get errorUnsupported => 'এই ফর্মেট বা সংযোগ এই ডিভাইসে সমর্থিত হয় না. সূত্র সিস্টেম গাইড দেখুন.';
	@override String get errorInvalidData => 'এই ফাইল বা সার্ভার উত্তর নিরাপদভাবে পড়তে পারে না।';
	@override String get errorCancelled => 'অপারেশন বাতিল করা হয়েছে।';
	@override String get errorConflict => 'পরবর্তী সেশনে অবস্থান পরিবর্তন করা হয়. একটি অবস্থান নির্বাচন করার জন্য পণ্যটি আবার খোলা।';
	@override String get signIn => 'সাইন ইন করুন';
	@override String get reconnect => 'আবার সংযোগ';
	@override String get folderHelp => 'সূত্র রয়ে শুরু করতে বাদ রাখুন. S3 URLs মধ্যে বুকটি রয়েছে।';
	@override String get preferences => 'প্রিয়ম';
	@override String get timePosition => 'অবস্থান';
	@override String get audioTrack => 'Audio ট্র্যাক';
	@override String get subtitleTrack => 'Subtitle ট্র্যাক';
	@override String get none => 'কোন';
	@override String get fullscreen => 'ফুল-স্ক্রিন';
	@override String get syncLocation => 'প্রসেস সিন্ক ফোলার (অন্যাশনাল)';
	@override String get syncLocationHint => 'একটি নির্দিষ্ট WebDAV ফোডার PlezyNG অবস্থা. শর্তাবলী লিখুন ব্যবহার; মিডিয়া পরিবর্তন না থাকবে.';
	@override String get audiobooks => 'অডিও বই';
	@override String get comics => 'কমিকস';
	@override String get scan => 'বই ও মিডিয়া জন্য স্ক্যানিং';
	@override String get browserReader => 'খোলা পাঠক';
	@override String get browserReaderHelp => 'আপনার ব্রাউজারে পাঠক খোলা থাকে. আপনার স্থান এবং নোট সংরক্ষণ করার জন্য PlezyNG খোলা রাখুন.';
	@override String get on => 'এতে';
	@override String get advancedSetup => 'App নিবন্ধন';
	@override String get microsoftSignIn => 'Microsoft সঙ্গে সাইন আপ করুন';
	@override String get zoomIn => 'Zoom এর মধ্যে';
	@override String get zoomOut => 'জোম';
	@override String get fitPage => 'পৃষ্ঠা';
	@override String get fitWidth => 'পাশাপাশি';
	@override String get actualSize => 'বর্তমান আকার';
	@override String get goToPage => 'পৃষ্ঠা থেকে যান';
	@override String get goToSection => 'চাবি থেকে যান';
	@override String pageRange({required Object count}) => '1 থেকে ${count} পর্যন্ত একটি নম্বর প্রদান করুন';
	@override String get pageLayout => 'Page লিওট';
	@override String get automatic => 'স্বয়ংক্রিয়';
	@override String get singlePage => 'একক পাতা';
	@override String get twoPages => 'দুই পৃষ্ঠা';
	@override String get readingDirection => 'পড়ার দিক';
	@override String get leftToRight => 'বাম থেকে ডানে';
	@override String get rightToLeft => 'ডান থেকে বামে';
	@override String get letterSpacing => 'স্পেসিং চিঠি';
	@override String get wordSpacing => 'শব্দ স্পেসিং';
	@override String get readerControlsHelp => 'পৃষ্ঠা বড় করতে দুই আঙুল ছড়িয়ে দিন বা জুম নিয়ন্ত্রণ ব্যবহার করুন। সরাতে টেনে আনুন। Ctrl/⌘ + বা − দিয়ে জুম বদলান; Ctrl/⌘ 0 দিয়ে আগের মাপে ফিরুন। Page Up ও Page Down দিয়ে পৃষ্ঠা বদলান।';
	@override String get imagePage => 'কমিকসের পৃষ্ঠা';
	@override String get resetReader => 'Read Preferences পুনরায়';
	@override String get zoom => 'জুম';
	@override String get useFiles => 'ফাইল এবং বই ব্যবহার করুন';
	@override String get cancelScan => 'স্ক্যান বাতিল';
	@override String get googleDrive => 'Google Drive';
	@override String get offlineQuota => 'ডাউনলোড সীমাবদ্ধ';
	@override String get offlineQuotaHelp => 'অoffline কপি, imported ফাইল এবং quued ডাউনলোড দ্বারা ব্যবহৃত সর্বোচ্চ স্থান নির্ধারণ করুন. সীমাবদ্ধতা কমাতে বর্তমান কপিগুলি মুছে দেয় না।';
	@override String get offlineStorageUsage => 'অফলিন স্টোরেজ';
	@override String get reservedStorage => 'সংরক্ষিত';
	@override String get downloadQueue => 'ডাউনলোড করুন Queue';
	@override String get downloadRunning => 'ডাউনলোড';
	@override String get downloadQueued => 'অপেক্ষা';
	@override String get downloadPaused => 'ছুটি';
	@override String get downloadFailed => 'পেরিয়ে যাওয়ার প্রয়োজন';
	@override String get importing => 'আমদানি';
	@override String get importInterrupted => 'উৎপাদন বাতিল · মুছে ফেলুন';
	@override String get errorQuotaExceeded => 'অ্যাপ্লিকেল স্টোরেজ সীমাবদ্ধতা পৌঁছানো হয়েছে. সীমানা উচ্চ করা বা একটি ডাউনলোড কপি মুছে ফেলা।';
	@override String get errorStorageLow => 'সুরক্ষিত রেকর্ড রাখার জন্য যথেষ্ট বিনামূল্যে ডিভাইস স্টোরেজ নেই।';
	@override String get errorStorageUnavailable => 'PlezyNG বিনামূল্যে ডিভাইস স্টোরেজ চেক করতে পারেনি, তাই লিখা বন্ধ করা হয়।';
	@override String get removeDownloadJob => 'Download ডাউনলোড';
	@override String get downloadAlreadyComplete => 'এই ডাউনলোড শেষ হয়, আগে এটি মুছে ফেলতে পারে. পণ্য এখন অ্যাপ্লিকেটে পাওয়া যায়।';
	@override String get confirmRemoveDownloadJob => 'এই ডাউনলোডটি মুছে ফেলুন এবং অংশীদারভাবে ডাউনের কোনও তথ্য দূর করুন? আপনার অবস্থান এবং নোট থাকবে।';
}

// Path: lending
class _Translations$lending$bn extends Translations$lending$en {
	_Translations$lending$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'জনব্যাপী লাইব্রেরি';
	@override String get add => 'একটি লাইব্রেরি যোগ করুন';
	@override String get other => 'আরেকটি লাইব্রেরি';
	@override String get libraryName => 'বইয়ের নাম';
	@override String get libraryUrl => 'লাইব্রেরি ওয়েবসাইট';
	@override String get libraryUrlHint => 'আপনার লাইব্রেরির ক্যাটাগোজ বা সাইন-এ-পেজ ব্যবহার করুন।';
	@override String get intro => 'আপনার লাইব্রেরি থেকে বই ধার নিন। বই রাখুন হাতের কাছেই।';
	@override String get handoff => 'আপনার লাইব্রেরি নিজের পরিষেবা দিয়ে সুরক্ষিতভাবে নিবন্ধন, লেনদেন এবং পড়ুন।';
	@override String get openService => 'খোলা লাইব্রেরি';
	@override String get findLibrary => 'একটি লাইব্রেরি খুঁজে পেতে';
	@override String get search => 'বই ও লেখকদের খুঁজে পেতে';
	@override String get catalogue => 'ক্যাটাগো';
	@override String get loans => 'ধার নেওয়া বই';
	@override String get holds => 'রিজার্ভেশন';
	@override String get signIn => 'আপনার লাইব্রেরি নিয়ে সাইন আপ করুন';
	@override String get waiting => 'আপনার ব্রাউজারে সাইন আপ শেষ করুন, তারপর এখানে ফিরে আসুন।';
	@override String get cancel => 'বাতিল';
	@override String get disconnect => 'লাইব্রেরি বের করুন';
	@override String get disconnectMessage => 'এই প্রোফাইল থেকে এই লাইব্রেরি সরাবেন? ধার নেওয়া বই ও রিজার্ভেশনগুলি আপনার লাইব্রেরিতে থাকবে।';
	@override String get getBook => 'বই পেয়ে';
	@override String get checkAvailability => 'সনাক্ত করা উপলব্ধতা';
	@override String get available => 'ধার নেওয়া যাবে';
	@override String get unavailable => 'বর্তমানে অসম্ভব';
	@override String get borrow => 'ধার নিন';
	@override String get placeHold => 'রিজার্ভ করুন';
	@override String get returnBook => 'দ্রুত ফিরে আসুন';
	@override String get cancelHold => 'রিজার্ভেশন বাতিল করুন';
	@override String get confirmBorrow => 'আপনার লাইব্রেরি থেকে এই টাইটটি লেনদেন করুন?';
	@override String get confirmReturn => 'এই বইটি এখন ফেরত দেবেন? পড়া চালিয়ে যেতে আবার ধার নিতে হতে পারে।';
	@override String get confirmCancelHold => 'এই বইয়ের জন্য আপনার রিজার্ভেশন বাতিল করবেন?';
	@override String get email => 'ইমেলের বিজ্ঞাপন রাখুন';
	@override String due({required Object date}) => 'ফেরত দেওয়ার তারিখ: ${date}';
	@override String queue({required Object position}) => 'পয়েন্ট ${position} লাইনে';
	@override String get empty => 'এখনো এখানে কোন টাইম নেই।';
	@override String get openLibraryNote => 'Open Library-এর ক্যাটালগ দেখুন। প্রতিটি বইয়ের পাতায় পড়া ও ধার নেওয়ার বিকল্পগুলি দেখানো হয়।';
	@override String get more => 'আরো লোড';
	@override String get gateway => 'লাইব্রেরি সাইন-ইন সেবা';
	@override String get gatewayHint => 'আপনার লাইব্রেরি বা প্রশাসক PlezyNG দ্বারা সরবরাহ করা হয়।';
	@override String get advanced => 'লাইব্রেরি ইন্টারফেস';
	@override String get loadLibraries => 'আপনার লাইব্রেরি নির্বাচন করুন';
	@override String get expired => 'এই বই ধার নেওয়ার মেয়াদ শেষ হয়েছে।';
	@override String get updated => 'সংস্করণ আপডেট';
	@override String get continueService => 'সেবা চালু করুন';
	@override String get comingSoon => 'অ্যাপে ডাউনলোড · শীঘ্রই আসে';
	@override String get comingSoonDescription => 'আপনি আপনার লাইব্রেরি ব্যবহার করতে পারেন লিবি যখন আমরা এটি সংযোগ শেষ করি।';
	@override String get suspendHold => 'রিজার্ভেশন সাময়িক বন্ধ করুন';
	@override String get resumeHold => 'রিজার্ভেশন আবার চালু করুন';
	@override String get suspendMessage => 'লাইনে নিজের জায়গা রেখে পরের পাঠককে এই কপিটি ধার নিতে দেবেন? পরে রিজার্ভেশনটি আবার চালু করতে পারবেন।';
	@override String get resumeMessage => 'এই রিজার্ভেশনটি আবার চালু করবেন, যাতে লাইব্রেরি পরবর্তী উপলব্ধ কপিটি আপনাকে দিতে পারে?';
	@override String get editEmail => 'ইমেলের বিজ্ঞাপন পরিবর্তন';
}

// Path: audiobook
class _Translations$audiobook$bn extends Translations$audiobook$en {
	_Translations$audiobook$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get syncTitle => 'Read & Listening সিনক';
	@override String get syncHelp => 'আপনার ডিভাইসের মধ্যেই পড়ার অবস্থান, শুনার অবস্থান, সম্পূর্ণন অবস্থান, বুকমার্ক এবং নোট রাখুন. একটি সংযুক্ত স্টোরিং অ্যাকাউন্ট নির্বাচন করুন এবং প্রতিটি ডিভাইসে একই সিন্ক কোড ব্যবহার করুন. পড়ার এবং শুনার অবস্থান আলাদা থাকবে.';
	@override String get addSyncSource => 'প্রথমেই ফাইল এবং বইগুলিতে Google ড্রাইভ, OneDrive, ড্রপবক্স, WebDAV বা S3 যোগ করুন।';
	@override String get syncDestination => 'সিনক স্টোরেজ অ্যাকাউন্ট';
	@override String get syncFolder => 'সিন্ক ফোল্ডার বা প্রফেক্স';
	@override String get syncFolderHelp => 'আপনার WebDAV সূত্রের মধ্যে একটি নির্দিষ্ট অ্যাপ্লিকেশন ব্যবহার করুন, অথবা একটি নির্দিষ্ট S3 পূর্বাভাস ব্যবহার করুন. বই ফাইলগুলি কখনো পরিবর্তন হয় না।';
	@override String get syncCode => 'ব্যক্তিগত সিন্ক কোড';
	@override String get syncCodeHelp => 'আপনার প্রথম ডিভাইসে একটি কোড তৈরি করুন, তারপর আপনার অন্যান্য ডিভাইসে সেই কোড লিখুন. একটি ব্যক্তিগত কপি রাখুন: এটি আপনার সক্রিপ্ট অবস্থার চিঠি।';
	@override String get showCode => 'সিন্ক কোড প্রদর্শন বা লুকিয়ে রাখুন';
	@override String get newSyncCode => 'নতুন সিন্ক কোড তৈরি করুন';
	@override String get saveSync => 'সিনক এবং সিনক';
	@override String get disableSync => 'এই ডিভাইসে সিন্ক বন্ধ করুন';
	@override String get syncSourceDisconnect => 'এই সূত্রটি মুছে ফেলুন, এখানে পড়ার এবং শুনার সনাকশন বন্ধ হবে. ক্রিপ্ট সনাকশন ফাইলগুলি সরবরাহকারী মধ্যে থাকবে।';
	@override String get syncReconnect => 'সংরক্ষণ অ্যাকাউন্ট পুনরায়';
	@override String lastSynced({required Object time}) => 'শেষ সমন্বয় ${time}';
	@override String get syncPrivacy => 'শুধু সক্রিপ্ট প্রসেস এবং নোট সংরক্ষণ করা হয়. অডিও এবং ইবুক ফাইল, অ্যাকাউন্ট টোকেন এবং পাসওয়ার্ড আপলোড করা হয় না. Google ড্রাইভ এবং OneDrive অ্যাপ স্টোরেজ ব্যবহার করে; ড্রপবক্স PlezyNG সিন্ক ব্যবহার করে. সিন্ক অনুমোদন আরও লিখিত অ্যাক্সেস প্রয়োজন হতে পারে. সক্রিপ্ট করা হলেও, এই লক্ষ্য প্রসেস সিন্ক মালিক; সার্ভার প্রসেস আলাদা থাকে. সিন্ক বন্ধ করে স্থানীয় ইতিহাস এবং আলাদা অবস্থা সংরক্ষণ করে।';
	@override String get syncConflicts => 'জেনে নিন কোথায় ফিরে আসতে হবে';
	@override String get conflictHelp => 'এই পরিবর্তনগুলি স্বাধীনভাবে করা হয়. রাখার জন্য অবস্থান বা বুকমার্ক সংস্করণ নির্বাচন করুন. একটি পরবর্তী সময়সীমা বা একটি উচ্চ প্রয়োগ স্বয়ংক্রিয়ভাবে জিতবে না।';
	@override String syncDevice({required Object device}) => 'ডিভাইস ${device}';
	@override String get syncUnknownDevice => 'অজ্ঞাত ডিভাইস';
	@override String get deletedBookmark => 'মুছে ফেলা বইমেলা';
	@override String get finished => 'শেষ';
	@override String readingPosition({required Object percent}) => 'পড়ুন · ${percent}%';
	@override String get chapterTimeline => 'চিঠি উন্নয়ন';
	@override String get bookTimeline => 'পুরো বই উন্নতি';
	@override String bookRemaining({required Object time}) => 'এই বইতে বাকি সময়: ${time}';
	@override String chapterRemaining({required Object time}) => 'এই বিভাগে বাকি সময়: ${time}';
	@override String get unknownRemaining => 'সম্পূর্ণ সময় খেলা হয় যখন অংশগুলি খেলা হয়';
	@override String get undoSeek => 'শেষ অনুসন্ধান';
	@override String get customSpeed => 'কাস্টম Playback গতি';
	@override String get speedHelp => '0.25× থেকে 4× পর্যন্ত গতি নির্বাচন করুন।';
	@override String get apply => 'প্রয়োগ করুন';
	@override String get customSleep => 'কাস্টম Sleep Timer';
	@override String get sleepMinutes => 'মিনিট (1–1440)';
	@override String sleepChapters({required Object count}) => '${count} বিভাগের পর বন্ধ';
	@override String get extendSleep => '৫ মিনিট যোগ করুন';
	@override String sleepRemaining({required Object time}) => 'ঘুম টাইমার: ${time}';
	@override String get useDefaults => 'নতুন বইয়ের জন্য এই শোনা নিয়ন্ত্রণগুলি ব্যবহার করুন';
	@override String get librarySort => 'কঠিন বই';
	@override String get sortTitle => 'Title নাম';
	@override String get sortAuthor => 'লেখক';
	@override String get sortNarrator => 'ন্যায়ক';
	@override String get sortSeries => 'সিরিজ আদেশ';
	@override String get sortRecent => 'সম্প্রতি খোলা';
	@override String get statusFilter => 'পড়ার অবস্থা';
	@override String get statusAll => 'সব বই';
	@override String get statusNew => 'শুরু না';
	@override String get statusProgress => 'প্রদর্শন';
	@override String get statusFinished => 'শেষ';
	@override String get goToTime => 'সময় নিয়ে যান';
	@override String get timeHelp => 'ঘণ্টা : মিনিট : সেকেন্ড বা মিনিট : সেকেন্ড';
	@override String get recoveryHelp => 'সিঙ্ক ডেটা সরানোর বা মেরামত করার আগে সাম্প্রতিক এনক্রিপ্ট করা কপি রপ্তানি করুন। আমদানি করলে বর্তমান অবস্থার সঙ্গে ডেটা মিশে যাবে; স্থানীয় সিঙ্ক ইতিহাস কখনো প্রতিস্থাপিত হবে না। সিঙ্ক কোড আলাদা করে রাখুন।';
	@override String get recoveryExport => 'ডাউনলোড সক্রিপ্ট ফাইল';
	@override String get recoveryImport => 'ডাউনলোড সক্রিপ্ট ফাইল';
	@override String get recoveryImportConfirm => 'এই এনক্রিপ্ট করা পুনরুদ্ধার ফাইলটি বর্তমান পড়ার অবস্থান ও নোটের সঙ্গে মেশাবেন? আগের ইতিহাস থাকবে। শেয়ার করা লাইব্রেরি ও আইটেম ID এতে নেই; আমদানির আগে প্রতিটি ডিভাইসে একই ID সেট করুন।';
	@override String get recoveryExported => 'সক্রিপ্ট ফাইল পুনরায় সংরক্ষণ করা হয়েছে।';
	@override String get recoveryImported => 'রেকর্ড ডেটা একত্রিত।';
}

// Path: sourceSetup
class _Translations$sourceSetup$bn extends Translations$sourceSetup$en {
	_Translations$sourceSetup$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get savedCertificate => 'সংরক্ষিত সার্ভার সার্টিফিকেট';
	@override String get nfsEndpointInvalid => 'nfs://nas:2049/export-এর মতো একটি NFS URL লিখুন।';
	@override String get dlnaNone => 'কোনো DLNA সার্ভার পাওয়া যায়নি। ডিভাইসের বিবরণের URL নিজে লিখুন।';
	@override String get dlnaServers => 'DLNA মিডিয়া সার্ভার';
	@override String get dlnaUnavailable => 'এই নেটওয়ার্কে DLNA ডিভাইস খোঁজা যাচ্ছে না। ডিভাইসের বিবরণের URL নিজে লিখুন।';
	@override String get dlnaSearching => 'স্থানীয় নেটওয়ার্কে DLNA সার্ভার খোঁজা হচ্ছে';
	@override String get networkSearching => 'স্থানীয় নেটওয়ার্কে খোঁজা হচ্ছে…';
	@override String get dlnaDiscover => 'DLNA সার্ভার খুঁজুন';
	@override String get dlnaHelp => 'ডিভাইস খুঁজতে স্থানীয় নেটওয়ার্কে মাল্টিকাস্ট প্রয়োজন। কোনো সার্ভার না দেখালে উপরে তার ডিভাইসের বিবরণের URL লিখুন।';
	@override String get dlnaRoot => 'DLNA অবজেক্ট ID; ডিভাইসের রুট ব্যবহার করতে ফাঁকা রাখুন।';
	@override String get passwordOrKey => 'পাসওয়ার্ড লিখুন অথবা নিচে একটি ব্যক্তিগত কী যোগ করুন।';
	@override String get sshFingerprint => 'SSH হোস্ট কী-এর SHA256 ফিঙ্গারপ্রিন্ট';
	@override String get sshFingerprintHelp => 'সার্ভারের প্রশাসকের কাছে যাচাই করুন। সার্ভারে ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub চালিয়ে পাওয়া SHA256 মানটি ব্যবহার করুন।';
	@override String get sshFingerprintKeep => 'বর্তমানে পিন করা ফিঙ্গারপ্রিন্ট রাখতে ফাঁকা রাখুন, অথবা সার্ভারের নতুন ফিঙ্গারপ্রিন্ট লিখুন।';
	@override String get sshAuthentication => 'SSH পাবলিক কী দিয়ে পরিচয় যাচাই';
	@override String get sshAuthenticationHelp => 'ঐচ্ছিক; পাসওয়ার্ড দিয়েও পরিচয় যাচাই করা যায়।';
	@override String get privateKey => 'ব্যক্তিগত কী (PEM বা OpenSSH ফরম্যাট)';
	@override String get privateKeyPassphrase => 'ব্যক্তিগত কী-এর পাসফ্রেজ';
	@override String get nfsMountPort => 'NFS মাউন্ট সেবার TCP পোর্ট';
	@override String get nfsMountPortHelp => 'ডিফল্ট: 20048';
	@override String get nfsUserId => 'NFS ব্যবহারকারী ID (AUTH_SYS)';
	@override String get nfsUserIdHelp => 'ডিফল্ট: 1000। NAS এক্সপোর্টে অনুমোদিত ID ব্যবহার করুন।';
	@override String get nfsGroupId => 'NFS গ্রুপ ID (AUTH_SYS)';
	@override String get nfsGroupIdHelp => 'ডিফল্ট: 1000। NAS এক্সপোর্টে অনুমোদিত গ্রুপ ID ব্যবহার করুন।';
	@override String get nfsEncryption => 'এনক্রিপ্ট করা NFS বাধ্যতামূলক করুন (RPC-with-TLS)';
	@override String get nfsEncryptionHelp => 'NFS ও মাউন্ট সেবার জন্য TLS 1.3 বাধ্যতামূলক করুন। NAS এটি সমর্থন না করলে সংযোগ প্রত্যাখ্যান করা হবে।';
	@override String get nfsTrustCertificate => 'কাস্টম NFS CA বা সার্ভার সার্টিফিকেট (PEM, ঐচ্ছিক)';
	@override String get nfsTrustHelp => 'এই ডিভাইসের বিশ্বস্ত সার্টিফিকেটের জন্য ফাঁকা রাখুন। প্রয়োজনে ব্যক্তিগত CA বা স্ব-স্বাক্ষরিত সার্ভার সার্টিফিকেট যোগ করুন; এর নামগুলো NFS URL-এর হোস্টের সঙ্গে মিলতে হবে।';
	@override String get nfsTrustInvalid => 'PEM ফরম্যাটে CA বা সার্ভার সার্টিফিকেট ব্যবহার করুন। ব্যক্তিগত কী অন্তর্ভুক্ত করবেন না।';
	@override String get addTrustCertificate => 'কাস্টম বিশ্বস্ত সার্টিফিকেট যোগ করুন';
	@override String get replaceTrustCertificate => 'সংরক্ষিত কাস্টম সার্টিফিকেট প্রতিস্থাপন করুন';
	@override String get nfsTlsHelp => 'RPC-with-TLS সাধারণ NFS ও মাউন্ট সেবার পোর্ট ব্যবহার করে এবং NAS-এ RFC 9289 সমর্থন থাকা প্রয়োজন। TLS 1.3 বাধ্যতামূলক। হোস্টের নাম বা IP সার্টিফিকেটের সঙ্গে মিলতে হবে। এনক্রিপ্ট করা চ্যানেলের ভেতরেও AUTH_SYS UID/GID প্রযোজ্য থাকে।';
	@override String get clientCertificate => 'ক্লায়েন্ট সার্টিফিকেট (ঐচ্ছিক)';
	@override String get clientCertificateHelp => 'NAS-কে এই ক্লায়েন্টের পরিচয় যাচাই করতে দেয়; AUTH_SYS ID এখনো NAS এক্সপোর্টের নীতির ওপর নির্ভর করে।';
	@override String get savedIdentity => 'ক্লায়েন্টের সংরক্ষিত পরিচয়পত্র ব্যবহার করা হবে।';
	@override String get replaceIdentity => 'ক্লায়েন্টের সংরক্ষিত পরিচয়পত্র প্রতিস্থাপন করুন';
	@override String get chooseIdentity => 'PKCS#12 ক্লায়েন্ট পরিচয়পত্র বেছে নিন';
	@override String get identityPassphrase => 'ক্লায়েন্ট পরিচয়পত্রের পাসফ্রেজ';
	@override String get identityPassphraseHelp => 'ফাইলে পাসফ্রেজ না থাকলে ফাঁকা রাখুন।';
	@override String get removeIdentity => 'ক্লায়েন্টের সংরক্ষিত পরিচয়পত্র সরান';
	@override String get identityStorageHelp => 'ক্লায়েন্টের পরিচয়পত্র উৎসের এনক্রিপ্ট করা প্রবেশতথ্যের ভান্ডারে রাখা হয়। সংরক্ষিত পরিচয়পত্র রাখতে এই অংশ অপরিবর্তিত রাখুন।';
	@override String get nfsLimitations => 'TCP-এর মাধ্যমে শুধু পড়ার জন্য NFSv3। RPC-with-TLS ছাড়া NFS ট্র্যাফিক এনক্রিপ্ট করা হয় না। NAS-এ নির্বাচিত AUTH_SYS ID এবং বিশেষ অধিকার প্রয়োজন হয় না এমন ক্লায়েন্ট পোর্টের অনুমতি থাকতে হবে (এক্সপোর্টের এই বিকল্পকে সাধারণত “insecure” বলা হয়)। NFSv4 ও UDP সমর্থিত নয়।';
	@override String get nfsSetupHelp => 'NFS সেটআপ সহায়তা';
	@override String get nfsSetupHint => 'সংযোগ না খুললে এই সেটিংগুলো পরীক্ষা করুন।';
	@override String get nfsSetupDetails => 'TCP-ভিত্তিক NFSv3 এক্সপোর্ট ব্যবহার করুন। এনক্রিপশন বাধ্যতামূলক হলে NFS ও মাউন্ট সেবা—দুটিকেই RPC-with-TLS সমর্থন করতে হবে। এই ডিভাইস সার্ভার সার্টিফিকেটকে বিশ্বাস করলে কাস্টম সার্টিফিকেট ফাঁকা রাখুন; অন্যথায় NAS-এর CA বা স্ব-স্বাক্ষরিত সার্টিফিকেট যোগ করুন। সার্টিফিকেটের নাম এন্ডপয়েন্টের হোস্টের সঙ্গে মিলতে হবে। NAS পারস্পরিক TLS চাইলে তার PKCS#12 ক্লায়েন্ট পরিচয়পত্র যোগ করুন। শেষে নিশ্চিত করুন, এক্সপোর্টে নির্ধারিত AUTH_SYS UID/GID ও ক্লায়েন্ট পোর্ট নীতির অনুমতি আছে।';
	@override String get ftpHelp => 'FTP প্যাসিভ মোড ব্যবহার করে। এনক্রিপশন ছাড়া FTP-এর জন্য ftp://, আলাদা কমান্ড দিয়ে TLS চালু করতে ftpes://, অথবা TLS-এর জন্য ftps:// ব্যবহার করুন (পোর্ট 990-এ TLS সঙ্গে সঙ্গে চালু হয়; অন্য পোর্টে আলাদা কমান্ড দিয়ে চালু হয়)।';
	@override String get openSubtitles => 'OpenSubtitles';
	@override String get subtitleSetup => 'স্বতন্ত্র ভিডিও ফাইলের জন্য ঐচ্ছিক সাবটাইটেল অনুসন্ধান।';
	@override String get apiKey => 'API কী';
	@override String get optionalUsername => 'অ্যাকাউন্টের ব্যবহারকারীর নাম (ঐচ্ছিক)';
	@override String get optionalPassword => 'অ্যাকাউন্টের পাসওয়ার্ড (ঐচ্ছিক)';
	@override String get subtitlePrivacy => 'opensubtitles.com থেকে API কী নিন। অনুসন্ধানে ভিডিওর শিরোনাম ও উপলব্ধ IMDb/TMDB ID পাঠানো হয়, ভিডিও ফাইল কখনোই পাঠানো হয় না। কী ও ঐচ্ছিক অ্যাকাউন্টের প্রবেশতথ্য এই উৎসের সঙ্গে এনক্রিপ্ট করে রাখা হয়।';
	@override String get automaticMetadata => 'স্বয়ংক্রিয়ভাবে অনলাইন ভিডিও মেটাডেটা পান';
	@override String get metadataPrivacy => 'শুধু ফাইলের নাম থেকে শিরোনাম, বছর ও পর্বের নম্বর অথবা NFO ID পাঠানো হয়; মিডিয়া বা প্রবেশতথ্য কখনো পাঠানো হয় না। NFO ফিল্ড সবসময় অগ্রাধিকার পায়।';
	@override String get nfsEncryptionFailure => 'এনক্রিপ্ট করা NFS-এর জন্য NAS-এর দুই সেবায় RFC 9289 ও TLS 1.3 সমর্থন, সার্টিফিকেটের নাম এবং এক্সপোর্টের UID/GID পরীক্ষা করুন। PlezyNG এনক্রিপশন ছাড়া এই সংযোগ আবার চেষ্টা করবে না।';
	@override String get sourceConnecting => 'উৎসের সঙ্গে সংযোগ করা হচ্ছে';
	@override String get metadataSearchPrivacy => 'এই শিরোনাম অনুসন্ধান Trakt-এ পাঠানো হয়। শুধু আপনার লেখা শিরোনাম পাঠানো হয়, ভিডিও বা উৎসের প্রবেশতথ্য নয়।';
	@override String get chooseMatch => 'মিল পাওয়া ফলাফল বেছে নিন';
	@override String get metadataMatchHelp => 'বেছে নেওয়ার আগে শিরোনাম ও বছর পরীক্ষা করুন। Trakt অনুসন্ধানের শিরোনাম পায়; ভিডিও তার উৎসেই থাকে।';
	@override String get metadataNoMatches => 'অনলাইনে মিলে যায় এমন কোনো শিরোনাম পাওয়া যায়নি। অন্য শিরোনাম দিয়ে চেষ্টা করুন।';
	@override String get metadataSearch => 'অনলাইন মেটাডেটা খুঁজুন';
	@override String get metadataLoading => 'সিনেমা ও টিভি অনুষ্ঠানের তথ্য অনলাইনে খোঁজা হচ্ছে…';
	@override String get metadataFromTrakt => 'Trakt থেকে অনলাইন মেটাডেটা';
	@override String get metadataNoAutomaticMatch => 'স্বয়ংক্রিয়ভাবে কোনো শিরোনামের মিল পাওয়া যায়নি। শিরোনাম খুঁজে সঠিক ফলাফল বেছে নিন।';
	@override String get metadataFailed => 'অনলাইন মেটাডেটা লোড করা যায়নি। প্লেব্যাক ও স্থানীয় তথ্য এখনো পাওয়া যাবে।';
	@override String get videoDetailsLoading => 'ভিডিওর তথ্য লোড হচ্ছে';
	@override String get subtitleKeyRequired => 'OpenSubtitles API কী প্রয়োজন';
	@override String get subtitleKeyHelp => 'এই ফাইল উৎসটি সম্পাদনা করে তার ঐচ্ছিক সাবটাইটেল সেটিংসে OpenSubtitles API কী যোগ করুন।';
	@override String get subtitleSearchFailed => 'সাবটাইটেল অনুসন্ধান ব্যর্থ হয়েছে। API কী, সংযোগ ও সেবায় প্রবেশাধিকার পরীক্ষা করুন।';
	@override String get subtitleApplyFailed => 'এই সাবটাইটেল ডাউনলোড বা প্রয়োগ করা যায়নি। সংযোগ পরীক্ষা করে অন্য ফলাফল দিয়ে চেষ্টা করুন।';
	@override String get subtitleSearch => 'OpenSubtitles-এ খুঁজুন';
	@override String get subtitleSearchPrivacy => 'অনুসন্ধানে শিরোনাম ও উপলব্ধ IMDb/TMDB ID ব্যবহার করা হয়। ভিডিও ফাইল তার উৎসেই থাকে। বেছে নেওয়ার আগে ভাষা, বাধ্যতামূলকভাবে দেখানো বা শ্রবণপ্রতিবন্ধীদের উপযোগী সাবটাইটেলের চিহ্ন এবং রেটিং পরীক্ষা করুন।';
	@override String get movieOrShow => 'সিনেমা বা টিভি অনুষ্ঠান';
	@override String get subtitleTitleHint => 'ফলাফল সীমিত করতে শিরোনাম লিখুন';
	@override String get subtitleLanguage => 'সাবটাইটেলের ভাষা';
	@override String get subtitleSearching => 'OpenSubtitles-এ খোঁজা হচ্ছে';
	@override String get subtitleNoMatches => 'কোনো মিল পাওয়া সাবটাইটেল নেই। অন্য শিরোনাম বা ভাষা দিয়ে চেষ্টা করুন।';
	@override String get downloadSubtitle => 'সাবটাইটেল ডাউনলোড করুন';
	@override String get subtitle => 'সাবটাইটেল';
	@override String get nfsTlsRequired => 'RPC-with-TLS বাধ্যতামূলক';
	@override String get nfsUnencrypted => 'এনক্রিপশন ছাড়া NFS';
	@override String get tlsEncrypted => 'TLS দিয়ে এনক্রিপ্ট করা';
	@override String get ftpPlain => 'এনক্রিপশন ছাড়া FTP';
	@override String get sshPinned => 'SSH দিয়ে এনক্রিপ্ট করা · হোস্ট কী পিন করা আছে';
	@override String get smbEncrypted => 'SMB3 এনক্রিপশন চালু';
	@override String get smbUnencrypted => 'SMB3 এনক্রিপশন বন্ধ';
	@override String get httpUnencrypted => 'পরিবহন এনক্রিপশন ছাড়া HTTP';
	@override String get checkEndpointSecurity => 'এন্ডপয়েন্টের নিরাপত্তা পরীক্ষা করুন';
	@override String fieldRequired({required Object label}) => '${label} লেখা আবশ্যক।';
	@override String integerRange({required Object label, required Object min, required Object max}) => '${label}-এর মান ${min} থেকে ${max}-এর মধ্যে লিখুন।';
	@override String replaceFile({required Object name}) => '${name} প্রতিস্থাপন করুন';
	@override String selectedIdentity({required Object name}) => 'ক্লায়েন্টের নির্বাচিত পরিচয়পত্র: ${name}';
	@override String subtitleRating({required Object rating}) => 'রেটিং ${rating}';
	@override String subtitleDownloading({required Object title}) => 'সাবটাইটেল ডাউনলোড হচ্ছে: ${title}';
	@override String get sharedEntryPair => 'এই জিনিসকে প্যারি করুন';
	@override String get sharedEntryPairHelp => 'প্রতিটি ডিভাইসে এই আইটেমের জন্য একই ID লিখুন। স্থায়ী শেয়ার করা শনাক্তকারী ব্যবহার করুন অথবা একটি তৈরি করে সংশ্লিষ্ট আইটেমে কপি করুন। সংস্করণের ফাইলের ধরন, আকার ও ক্রম মিললেই অগ্রগতি যুক্ত হবে। ফাঁকা রাখলে এই ম্যাপিং মুছে যাবে।';
	@override String get sharedEntryId => 'শেয়ার আইটেম ID';
	@override String get generateSharedEntryId => 'শেয়ার আইটেম ID তৈরি করুন';
	@override String get sharedLibraryId => 'বিতরণিত লাইব্রেরি ID (অন্যাশনাল)';
	@override String get sharedLibraryHelp => 'একই লাইব্রেরি খোলা ডিভাইসগুলোতে একই ID ব্যবহার করুন। এই পাবলিক ID বিভিন্ন সোর্স সংযোগে পড়ার অগ্রগতি ও নোট বহন করতে সাহায্য করে; এটি পাসওয়ার্ড নয়। প্রোভাইডার ভিন্ন আইটেম ID ব্যবহার করলে, আইটেমের বিস্তারিত স্ক্রিনে সেগুলো জুড়ুন।';
	@override String get sharedLibraryInvalid => '8-100 বাক্স, নম্বর, পয়েন্ট, সাবস্কোর বা হাইফেন্স ব্যবহার করুন।';
	@override String get generateSharedLibraryId => 'একটি বিতর্কিত লাইব্রেরি ID তৈরি করুন';
	@override String get nfsReadAhead => 'NFS Read-ahead অনুরোধ';
	@override String get nfsReadAheadHelp => 'দ্রুত NAS বা নেটওয়ার্কে আরও সমান্তরাল রিড থ্রুপুট বাড়াতে পারে। সার্ভার একসঙ্গে অনুরোধ সীমিত করলে 1 ব্যবহার করুন।';
	@override String get nfsReadTest => 'NFS পড়া দক্ষতা মাত্রা';
	@override String get nfsReadTestHelp => 'এই NAS সংযোগকে মাত্রা করার জন্য সবচেয়ে বড় ফাইল থেকে 64 MiB পর্যন্ত পড়তে পারে।';
	@override String get nfsQualificationResult => 'NFS পড়ুন মাত্রা';
	@override String get nfsReadBytes => 'ডাটা পড়ুন';
	@override String get nfsReadSpeed => 'গতি মাত্রা';
	@override String get nfsReadRequests => 'অনুরোধ পড়ুন';
	@override String get sharedEntryConflict => 'এই শেয়ার করা আইটেম ID ইতিমধ্যে এই লাইব্রেরির অন্য আইটেমের সঙ্গে যুক্ত। অন্য ID বেছে নিন।';
}

// Path: comics
class _Translations$comics$bn extends Translations$comics$en {
	_Translations$comics$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get fitHeight => 'উচ্চতা অনুযায়ী মানানসই';
	@override String get readingMode => 'পড়ার ধরন';
	@override String get paged => 'পৃষ্ঠা';
	@override String get webtoon => 'একটানা স্ক্রল';
	@override String get coverAlone => 'প্রচ্ছদ আলাদা করে দেখান';
	@override String get splitWide => 'চওড়া পৃষ্ঠা ভাগ করুন';
	@override String get splitWideHelp => 'পড়ার ক্রম অনুযায়ী প্রতিটি অর্ধেক আলাদা করে দেখান। এটি চালু থাকলে পাশাপাশি দুটি পৃষ্ঠা দেখানো বন্ধ থাকে।';
	@override String get thumbnails => 'পৃষ্ঠার থাম্বনেইল';
	@override String get controlsHelp => 'পৃষ্ঠা ওল্টাতে সোয়াইপ করুন। মানানসই আকার বদলাতে দুবার ট্যাপ করুন। একটানা স্ক্রলে উল্লম্বভাবে সোয়াইপ করুন বা Page Up ও Page Down ব্যবহার করুন।';
	@override String get savedForComic => 'এই প্রোফাইলে এই কমিকের প্রদর্শন সেটিংস মনে রাখা হয়।';
	@override String get readLists => 'পড়ার তালিকা';
	@override String get collections => 'সংগ্রহ';
}

// Path: games
class _Translations$games$bn extends Translations$games$en {
	_Translations$games$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Games';
	@override String get enable => 'Show Games for this profile';
	@override String get enableDescription => 'Discover your gaming computers and play with an embedded streaming engine.';
	@override String get subtitle => 'Your games, from your computers.';
	@override String get computers => 'Your computers';
	@override String get nearby => 'Nearby computers';
	@override String get findComputers => 'Find computers';
	@override String get addComputer => 'Add computer';
	@override String get scanHint => 'Keep Steam Remote Play or Sunshine running on the same network. VPNs and guest networks may need a manual address.';
	@override String get empty => 'Add your gaming computer to get started.';
	@override String get noNearby => 'No computers found on this network. You can enter an address manually.';
	@override String get name => 'Computer name';
	@override String get address => 'IP address or hostname';
	@override String get port => 'Service port';
	@override String get protocol => 'Streaming service';
	@override String get moonlight => 'Sunshine / Moonlight';
	@override String get steam => 'Steam Remote Play';
	@override String get save => 'Save computer';
	@override String get invalidAddress => 'Enter a valid hostname or IP address, without a URL, and a port from 1 to 65534.';
	@override String get pair => 'Connect computer';
	@override String get pairTitle => 'Approve this device';
	@override String get pairInstructions => 'Enter this code in the host’s pairing prompt. For Sunshine, use the PIN page below. Keep this screen open until the computer approves.';
	@override String get pairHelp => 'Connect this computer again to approve or renew pairing.';
	@override String get openPairingPage => 'Open Sunshine PIN page';
	@override String get qrHelp => 'Scan to open the PIN page. The QR code contains only the computer address, never a password or pairing credential.';
	@override String get refreshGames => 'Refresh games';
	@override String get play => 'Play';
	@override String get recent => 'Recently opened';
	@override String get favorites => 'Favorites';
	@override String get allGames => 'All games';
	@override String get search => 'Find a game';
	@override String get noMatches => 'No games match this search.';
	@override String get favorite => 'Save favorite';
	@override String get unfavorite => 'Remove favorite';
	@override String get forget => 'Forget computer';
	@override String get forgetDescription => 'Remove this computer and its game shortcuts from this profile? To revoke this device’s authorization, remove it from the host’s paired devices.';
	@override String get unavailable => 'The connection could not complete. Check that the computer is awake and paired, then try again.';
	@override String get timeout => 'Connection timed out. Check the computer, pairing code and network before trying again.';
	@override String get libraryHint => 'Choose a computer to connect and load its games. Once connected, choose a game to play inside PlezyNG.';
	@override String get touchControls => 'On-screen controller';
	@override String get touchDescription => 'Show the native controller during a stream. It supports multiple fingers, sticks, buttons and triggers.';
	@override String get touchSetup => 'On-screen controls';
	@override String get touchSetupHint => 'Moonlight’s controller settings support position and opacity changes. During a Steam stream, open the stream menu to toggle its controller. Bluetooth or USB input is also supported.';
	@override String get addGame => 'Add game shortcut';
	@override String get gameName => 'Game name';
	@override String get gameId => 'Host application ID';
	@override String get invalidGame => 'Enter a game name and a positive numeric host application ID.';
	@override String get wake => 'Wake computer';
	@override String get wakeSent => 'Wake request sent. The computer must support Wake-on-LAN on this network.';
	@override String get mac => 'MAC address (optional)';
	@override String get help => 'Games help';
	@override String get helpBody => 'Enable Games for your profile, choose a computer and approve the first connection. Sunshine-compatible hosts load their app list into the game grid. On Android, Steam pairing opens Big Picture inside PlezyNG; saved Steam app-ID shortcuts launch directly. Steam pairing does not grant access to a private account library.\n\nBoth Android engines include touch controls and gamepad input. Pyrowave is an experimental Android option; other native platforms remain in development.\n\nPairing requires the host’s approval. Sunshine QR codes open its PIN page without carrying credentials. For access away from home, use the computer’s VPN address. Automatic discovery normally stays on the local network.\n\nDisconnecting leaves the game running on the computer.';
	@override String get cancel => 'Cancel';
	@override String get scanning => 'Looking for computers…';
	@override String get saveShortcut => 'Save shortcut';
	@override String get manualHint => 'For Moonlight use the host’s GameStream HTTP port (usually 47989), not its web settings port. Steam normally advertises on 27036.';
	@override String get engineUnavailable => 'In-app streaming is not available here yet';
	@override String get nativeEnginePending => 'This build does not include a streaming engine for this platform. You can save the computer, but it cannot play here yet.';
	@override String get steamEnginePending => 'This build does not include the embedded Steam engine. Android builds with Games enabled bundle device pairing and in-app H.264/HEVC playback. Pyrowave is experimental on Android; other platforms remain under development.';
	@override String get steamBetaTitle => 'Steam beta · Pyrowave';
	@override String get steamBetaDescription => 'Experimental Steam beta codec. Off by default; it uses 5–10× more bandwidth than H.264/HEVC, and Valve recommends gigabit Ethernet. Android playback is limited to SDR 4:2:0 with CPU readback and has not been device-qualified.';
	@override String get steamLibrary => 'Steam library';
	@override String get linkSteamAccount => 'Link Steam account';
	@override String get refreshSteamAccount => 'Refresh Steam account';
	@override String get unlinkSteamAccount => 'Unlink Steam account';
	@override String get unlinkSteamAccountConfirm => 'Remove this account and its imported catalog from this profile? Your paired computers and shortcuts stay available.';
	@override String get steamAccountLinked => 'Steam account linked. Games imported.';
	@override String get steamLibraryPrivate => 'Steam account linked. Its library is private or unavailable, so no games were imported.';
	@override String get steamAppId => 'Steam App ID';
	@override String get steamLibraryStale => 'Steam could not refresh the library. Showing the last available catalog.';
	@override String get steamLibraryTruncated => 'Showing up to 2,000 games. The Steam catalog was truncated.';
	@override String get connecting => 'Connecting…';
	@override String get disconnect => 'Disconnect';
	@override String get streamControls => 'Stream controls';
	@override String get steamPairInstructions => 'Enter this code in Steam’s Remote Play pairing prompt on your computer. Keep this screen open until Steam approves.';
	@override String get steamLibraryHint => 'Steam device pairing opens its library inside the stream. Add a shortcut with a Steam app ID for direct launch. Importing a private account library as game cards requires a separate authenticated catalog connection.';
}

// Path: deepLinks
class _Translations$deepLinks$bn extends Translations$deepLinks$en {
	_Translations$deepLinks$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get invalid => 'এই Plezy লিঙ্ক সঠিক নয়।';
	@override String profileNotFound({required Object profile}) => 'কোন প্রোফাইল "${profile}" সঙ্গে জড়িত না।';
	@override String get serverUnavailable => 'আমি এই লিঙ্কের জন্য সার্ভার পৌঁছাতে পারিনি।';
	@override String get notFound => 'আপনার লাইব্রেরিতে এই নামটি পাওয়া যায় না।';
	@override String get unsupportedItem => 'এই লিঙ্ক খেলতে পারে না।';
	@override String get noLiveTv => 'এই লিঙ্ক জন্য কোন লাইভ টিভি সার্ভার পাওয়া যায় না।';
	@override String channelNotFound({required Object channel}) => 'আমি চ্যানেল "${channel}" খুঁজতে পারিনি।';
	@override String get showLink => 'দেখুন লিঙ্ক';
	@override String get showProfileLink => 'প্রোফাইল লিঙ্ক';
	@override String get dialogTitle => 'লিঙ্ক';
	@override String get showHint => 'এই লিংক খুললে পরের পর্বটি চলবে। সিরিজটি এলোমেলোভাবে চালাতে শেষে &mode=shuffle যোগ করুন.';
	@override String get movieHint => 'এই লিঙ্ক খুলে চলচ্চিত্রটি খেলবে।';
	@override String get episodeHint => 'এই লিঙ্কটি খোঁজে এ епизодটি খেলতে হবে।';
	@override String get profileHint => 'এই লিঙ্কটি খুলতে, এই প্রোফাইলের জন্য বিনিময় করা হয়।';
	@override String openAsProfile({required Object name}) => '${name} হিসাবে খোলা';
	@override String get copy => 'কপি';
	@override String get copied => 'লিঙ্ক কপি';
}

// Path: appIcon.names
class _Translations$appIcon$names$bn extends Translations$appIcon$names$en {
	_Translations$appIcon$names$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get midnight => 'মধ্য রাতে';
	@override String get ember => 'মানুষ';
	@override String get paper => 'কাবার';
	@override String get oled => 'OLED';
	@override String get line => 'লাইন';
	@override String get ocean => 'আকাশ';
	@override String get ultraviolet => 'অলিট্রোভিয়াল';
	@override String get matcha => 'ম্যাচ';
	@override String get sunset => 'সূর্য';
	@override String get gold => 'অলিন';
	@override String get titanium => 'টাইটানিয়াম';
	@override String get glass => 'গ্লাস';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => 'সিন্টওয়াই';
	@override String get pixel => 'পিক্সেল';
	@override String get neon => 'নিয়েন';
	@override String get sticker => 'স্টিকার';
	@override String get ticket => 'টিকিট';
	@override String get pop => 'পপ';
	@override String get strata => 'বিপর্যয়';
	@override String get facet => 'মুখ';
	@override String get tilde => 'টাইম';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$bn extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get critic => 'Critics';
	@override String get audience => 'Audience';
	@override String get imdb => 'IMDb';
	@override String get tmdb => 'TMDB';
	@override String get rottenTomatoes => 'Rotten Tomatoes';
	@override String get simkl => 'Simkl';
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get trakt => 'Trakt';
	@override String get rottenTomatoesCritic => 'Rotten Tomatoes critics';
	@override String get rottenTomatoesAudience => 'Rotten Tomatoes audience';
	@override String get metacritic => 'Metacritic';
	@override String get letterboxd => 'Letterboxd';
}

// Path: common.mediaKind
class _Translations$common$mediaKind$bn extends Translations$common$mediaKind$en {
	_Translations$common$mediaKind$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get movie => 'চলচ্চিত্র';
	@override String get show => 'প্রদর্শন';
	@override String get season => 'সপ্তাহ';
	@override String get episode => 'পর্ব';
	@override String get artist => 'শিল্পী';
	@override String get album => 'অ্যালবাম';
	@override String get track => 'ট্র্যাক';
	@override String get collection => 'সংগ্রহ';
	@override String get playlist => 'প্লেলিস্ট';
	@override String get clip => 'ক্লিপ';
	@override String get photo => 'ছবি';
	@override String get folder => 'ফোল্ডার';
}

// Path: settings.startupSectionOptions
class _Translations$settings$startupSectionOptions$bn extends Translations$settings$startupSectionOptions$en {
	_Translations$settings$startupSectionOptions$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get discover => 'সম্পর্কিত গবেষণার সূত্র থেকে উন্মুক্ত প্রস্তাব এবং পণ্য।';
	@override String get libraries => 'আপনার সংযুক্ত মিডিয়া লাইব্রেরি খুলুন।';
	@override String get liveTv => 'একটি সার্ভার এটি সরবরাহ করলে লাইভ টিভি খুলুন; অন্যথায় স্টার্টপেট বাড়িতে ফিরে আসবে।';
	@override String get search => 'খোলা মিডিয়া অনুসন্ধান';
}

// Path: themeEditor.slots
class _Translations$themeEditor$slots$bn extends Translations$themeEditor$slots$en {
	_Translations$themeEditor$slots$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get bg => 'ফাউন্ডেশন';
	@override String get surface => 'সারফেস';
	@override String get outline => 'বাইরে';
	@override String get text => 'টেক্ট';
	@override String get textMuted => 'দ্বিতীয় লেখা';
	@override String get accent => 'অ্যাক্সেস';
}

// Path: themeEditor.contrast
class _Translations$themeEditor$contrast$bn extends Translations$themeEditor$contrast$en {
	_Translations$themeEditor$contrast$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => 'ভিত্তিতে লেখা';
	@override String get textOnSurface => 'পৃথিবীতে লেখা';
	@override String get textMutedOnBg => 'ভিত্তিতে দ্বিতীয় লেখা';
	@override String get textMutedOnSurface => 'পৃথিবীর দ্বিতীয় তালিকা';
	@override String get accentOnBg => 'ফাঁসের উপর মনোযোগ';
	@override String get accentOnSurface => 'পৃথিবীতে উত্থান';
	@override String get labelOnAccent => 'অ্যাক্সেন্টের উপর বোতাম লেগেট';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$bn extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'খেলা / পাস';
	@override String get volumeUp => 'ওভেনমেন্ট';
	@override String get volumeDown => 'ভোল্ডা Down';
	@override String seekForward({required Object seconds}) => 'ফেরত খুঁজুন (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'ফেরত চলে যাওয়ার জন্য (${seconds}s)';
	@override String get fullscreenToggle => 'ফুল স্ক্রিন';
	@override String get muteToggle => 'একসাথে মুটি';
	@override String get subtitleToggle => 'Subtitles সহজ';
	@override String get audioTrackNext => 'পরবর্তী Audio Track';
	@override String get subtitleTrackNext => 'পরবর্তী সাব্টাইট ট্র্যাক';
	@override String get chapterNext => 'পরবর্তী চিঠি';
	@override String get chapterPrevious => 'পূর্ববর্তী চিঠি';
	@override String get episodeNext => 'পরবর্তী Episode';
	@override String get episodePrevious => 'পূর্ববর্তী epizode';
	@override String get speedIncrease => 'দ্রুত বাড়ান';
	@override String get speedDecrease => 'গতি কমে';
	@override String get speedReset => 'দ্রুত রেসেট';
	@override String get zoomIn => 'Zoom ইন';
	@override String get zoomOut => 'Zoom বাইরে';
	@override String get zoomReset => 'রেস্টো Zoom';
	@override String get subSeekNext => 'পরবর্তী Subtitle অনুসরণ করুন';
	@override String get subSeekPrev => 'Previous Subtitle অনুসন্ধান করুন';
	@override String get subtitleDelayIncrease => 'দেরি Subtitles';
	@override String get subtitleDelayDecrease => 'উন্নয়ন Subtitles';
	@override String get shaderToggle => 'ছায়া দিয়ে';
	@override String get skipMarker => 'ক্রেডিট / ক্রেডিট / ক্রেডিট';
	@override String get screenshot => 'স্ক্রিন ফটো';
	@override String get framePrevious => 'পূর্ববর্তী ফ্রেম';
	@override String get frameNext => 'পরবর্তী ফ্রেম';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$bn extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'প্রয়োজনীয়তা Android 8.0 বা নতুন';
	@override String get iosVersion => 'প্রয়োজন iOS 15.0 বা নতুন';
	@override String get permissionDisabled => 'Image-in-picture অ্যাক্সেস করা হয়. সিস্টেম সেটগুলিতে এটি অ্যাক্সেস করা হয়.';
	@override String get notSupported => 'ডিভাইস Image-in-Picture মোড সমর্থন করে না';
	@override String get voSwitchFailed => 'ভিডিও উত্পাদন পরিবর্তন করতে পারিনি ছবি-ন-ফটো';
	@override String get failed => 'ছবি-ন-ফিল্টার শুরু হয়নি';
	@override String get prepareFailed => 'ছবি-ন-পিত্র তৈরি করা যাবে না';
	@override String unknown({required Object error}) => 'একটি ভুল ঘটেছে: ${error}';
}

// Path: subtitlingStyling.assOverrideOptions
class _Translations$subtitlingStyling$assOverrideOptions$bn extends Translations$subtitlingStyling$assOverrideOptions$en {
	_Translations$subtitlingStyling$assOverrideOptions$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get no => 'ফটোগুলি, রঙ, আকার এবং স্থানান্তর লিখিত রাখুন subtitle ফাইলে।';
	@override String get yes => 'খেলোয়াড়ের subtitle স্টাইল সেটিংগুলি ASS subtitles সংশোধন করার অনুমতি দেয়।';
	@override String get scale => 'ভিডিও মাত্রা পূরণ করার জন্য খেলোয়াড় স্টাইলিং এবং ভেঙে গঠিত আকারগুলি প্রয়োগ করুন।';
	@override String get force => 'অভ্যন্তরীণ ASS স্টাইলগুলি খেলোয়াড়ের subtitle স্টাইল দ্বারা পরিবর্তন করুন।';
	@override String get strip => 'ভিত্তিতে ASS ফর্মেটিং সরবরাহ করুন এবং সাব্টিটি টেক্সট পরিষ্কারভাবে রূপান্তর করুন।';
}

// Path: subtitlingStyling.renderResolutionOptions
class _Translations$subtitlingStyling$renderResolutionOptions$bn extends Translations$subtitlingStyling$renderResolutionOptions$en {
	_Translations$subtitlingStyling$renderResolutionOptions$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get screen => 'সবচেয়ে উজ্জ্বল ফলাফলের জন্য পুরো প্রদর্শন পৃথিবী রেজুলেশনতে রেন্ডার।';
	@override String get video => 'ভিডিও রেজিউশন ব্যবহার করে ফ্রেন্ড, যা উচ্চ সনাক্ততা ডিভাইসগুলিতে কাজ কমাতে পারে।';
	@override String get threeQuarter => 'প্রদর্শন পৃথিবীর সনাক্ততা 75 শতাংশের জন্য নিম্ন কর্মক্ষমতা সংরক্ষণ।';
	@override String get half => '50 শতাংশ প্রদর্শনের পৃথিবী রেজুলেশনের জন্য কাজ কমাতে, মধুর দিকগুলি সঙ্গে।';
	@override String get third => 'একটি তৃতীয়াংশ প্রদর্শনের পৃথিবী রেজুল্যকরণের জন্য কাজ কমাতে, মধুর দিকে।';
	@override String get quarter => 'দৃশ্য পৃথিবীর রেজুলেশন একটি তৃতীয়াংশের জন্য কাজ কমাতে, সবচেয়ে মধুর ফলাফল সঙ্গে।';
}

// Path: accountPreferences.groups
class _Translations$accountPreferences$groups$bn extends Translations$accountPreferences$groups$en {
	_Translations$accountPreferences$groups$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => 'অডিও & Subtitles';
	@override String get libraryDisplay => 'লাইব্রেরি';
	@override String get personalMedia => 'ব্যক্তিগত মিডিয়া';
}

// Path: accountPreferences.subtitleModes
class _Translations$accountPreferences$subtitleModes$bn extends Translations$accountPreferences$subtitleModes$en {
	_Translations$accountPreferences$subtitleModes$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get none => 'ম্যানুয়াল নির্বাচন';
	@override String get noneDescription => 'কখনো নিজেদের উপর সাবতিটার ফাঁস করবেন না।';
	@override String get defaultMode => 'ট্র্যাক ফ্যাগ অনুসরণ করুন';
	@override String get defaultModeDescription => 'প্রত্যেক সাব্টাইট ট্র্যাকে সংরক্ষিত ডিফল্ট এবং জরুরি ফ্যাগ ব্যবহার করুন।';
	@override String get always => 'সবসময় অনুমোদিত';
	@override String get alwaysDescription => 'প্রিয় ভাষায় একটি সাব্টাইট ট্র্যাকে যখন কোনটি থাকে তখন বের করুন।';
	@override String get onlyForced => 'শুধুমাত্র নির্যাতন টাইম';
	@override String get onlyForcedDescription => 'শুধুমাত্র জরুরি হিসাবে চিহ্নিত পথগুলি লোড করুন।';
	@override String get smart => 'বিদেশী অডিও সঙ্গে সনাক্ত';
	@override String get smartDescription => 'শুধুমাত্র অডিওটি অন্য ভাষায় থাকলে সাবটাইটগুলি পুনরাবৃত্তি করুন।';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class _Translations$accountPreferences$subtitleAccessibilityOptions$bn extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	_Translations$accountPreferences$subtitleAccessibilityOptions$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'অ-এসডিএইচ সাব্টিটিস প্রিয়';
	@override String get preferSdh => 'SDH সাব্টিটিস প্রিয়';
	@override String get onlySdh => 'শুধুমাত্র SDH সাব্টিটিল';
	@override String get onlyNonSdh => 'শুধু অ-SDH সাব্টিটিল';
	@override String get preferNonSdhDescription => 'Standard subtitles পছন্দ করে যখন স্ট্যান্ডার্ড এবং SDH সংস্করণগুলি উভয় পাওয়া যায়।';
	@override String get preferSdhDescription => 'SDH সাবটাইটিলগুলি পছন্দ করে যখন পাওয়া যায়, তবে একটি Fallback হিসাবে স্ট্যান্ডার্ড সাবিটাইলগুলি অনুমতি দেয়।';
	@override String get onlySdhDescription => 'শুধুমাত্র SDH সাবটাইটিল ব্যবহার করুন; স্ট্যান্ডার্ড সাব্টিটেলগুলিতে ফিরে আসবেন না।';
	@override String get onlyNonSdhDescription => 'শুধুমাত্র স্ট্যান্ডার্ড সাবটাইটিল ব্যবহার করুন; SDH সাব্টিটেলগুলি বাদ দেবেন।';
}

// Path: accountPreferences.forcedSubtitleOptions
class _Translations$accountPreferences$forcedSubtitleOptions$bn extends Translations$accountPreferences$forcedSubtitleOptions$en {
	_Translations$accountPreferences$forcedSubtitleOptions$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => 'অস্বীকারিত সূত্রগুলি পছন্দ করি';
	@override String get preferForced => 'জরুরি টাইমগুলি পছন্দ';
	@override String get onlyForced => 'শুধুমাত্র নির্যাতন টাইম';
	@override String get onlyNonForced => 'শুধুমাত্র নির্যাতন সূত্র';
	@override String get preferNonForcedDescription => 'নিয়মিত সাবটাইটিলগুলি পছন্দ করে, কিন্তু ফাঁসের হিসাবে জরুরি ট্র্যাক অনুমতি দেয়।';
	@override String get preferForcedDescription => 'যখন উপলব্ধ হয়, তখন জরুরি ট্র্যাকগুলি পছন্দ করে, কিন্তু একটি Fallback হিসাবে নিয়মিত নীতিগুলি অনুমতি দেয়।';
	@override String get onlyForcedDescription => 'শুধুমাত্র জরুরি হিসাবে চিহ্নিত ট্র্যাক ব্যবহার করুন।';
	@override String get onlyNonForcedDescription => 'বাধ্যতামূলক হিসাবে চিহ্নিত রাস্তার বাইরে রাখুন।';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$bn extends Translations$accountPreferences$watchedIndicatorOptions$en {
	_Translations$accountPreferences$watchedIndicatorOptions$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get none => 'কখনো';
	@override String get moviesAndShows => 'চলচ্চিত্র ও টেলিভিশন প্রদর্শন';
	@override String get movies => 'শুধু চলচ্চিত্র';
	@override String get shows => 'টেলিভিশন শুধু';
	@override String get noneDescription => 'দেখানো চেকমার্ক দেখান না।';
	@override String get moviesAndShowsDescription => 'চলচ্চিত্র এবং টেলিভিশন প্রদর্শনের জন্য দেখানো চেকমার্ক।';
	@override String get moviesDescription => 'শুধুমাত্র চলচ্চিত্রের জন্য চেকমার্ক দেখুন।';
	@override String get showsDescription => 'শুধু টেলিভিশন প্রদর্শনের জন্য দেখানো চেকমার্ক।';
}

// Path: accountPreferences.mediaReviewsOptions
class _Translations$accountPreferences$mediaReviewsOptions$bn extends Translations$accountPreferences$mediaReviewsOptions$en {
	_Translations$accountPreferences$mediaReviewsOptions$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'ব্যবহারকারী এবং সমালোচনাকারী';
	@override String get usersOnly => 'শুধু ব্যবহারকারী';
	@override String get criticsOnly => 'শুধু সমালোচনা';
	@override String get nobody => 'গোপন';
	@override String get usersAndCriticsDescription => 'ব্যবহারকারীর তদন্ত এবং সমালোচক তালিকা প্রদর্শন করুন।';
	@override String get usersOnlyDescription => 'ব্যবহারকারীদের দ্বারা প্রদান করা রেটিং এবং বিশ্লেষণ দেখুন।';
	@override String get criticsOnlyDescription => 'সমালোচনীয় তদন্ত এবং বিশ্লেষণ দেখুন।';
	@override String get nobodyDescription => 'তদন্ত ও বিশ্লেষণ ঘুরে রাখুন।';
}

// Path: discover.findNext
class _Translations$discover$findNext$bn extends Translations$discover$findNext$en {
	_Translations$discover$findNext$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'পরের পছন্দটি খুঁজুন';
	@override String get open => 'পরের পছন্দটি খুঁজুন';
	@override String get anyTime => 'সময়ের সীমা নেই';
	@override String get timeAvailable => 'আপনার হাতে কতটা সময় আছে?';
	@override String get filters => 'এই মুহূর্তের জন্য বেছে নিন';
	@override String get watch => 'দেখুন';
	@override String get listen => 'শুনুন';
	@override String get read => 'পড়ুন';
	@override String finishable({required Object duration}) => '${duration}-এর মধ্যে শেষ করা যাবে';
	@override String aboutDuration({required Object duration}) => 'প্রায় ${duration}';
	@override String nextUnit({required Object duration}) => 'পরের অধ্যায় · ${duration}';
	@override String totalDuration({required Object duration}) => 'মোট ${duration}';
	@override String get timingVaries => 'সময় কমবেশি হতে পারে';
	@override String get notNow => 'এখন নয়';
	@override String get swipeHint => 'প্রচ্ছদটি কোনো তিরের দিকে সোয়াইপ করুন বা নিচের বোতাম ব্যবহার করুন।';
	@override String get saved => 'সংরক্ষিত পছন্দ';
	@override String savedCount({required Object count}) => 'সংরক্ষিত পছন্দ · ${count}';
	@override String get undo => 'পূর্বাবস্থায় ফেরান';
	@override String get details => 'বিস্তারিত';
	@override String get noPicks => 'বেছে নেওয়ার মতো কিছু এখনো নেই';
	@override String get noPicksHint => 'শুরু করতে একটি লাইব্রেরি সংযুক্ত করুন অথবা মিডিয়ার উৎস যোগ করুন।';
	@override String get noMatches => 'এই মুহূর্তের জন্য উপযুক্ত কিছু নেই';
	@override String get noMatchesHint => 'অন্য ধরনের মিডিয়া বেছে নিন অথবা আরও কিছুটা সময় রাখুন।';
	@override String get allDone => 'সব প্রস্তাব দেখা হয়ে গেছে';
	@override String get allDoneHint => 'এই পছন্দগুলো আবার দেখতে নতুন একটি তালিকা তৈরি করুন।';
	@override String get refresh => 'আরেকটি তালিকা খুঁজুন';
	@override String sourceReason({required Object source}) => 'উৎস: ${source}';
	@override String libraryReason({required Object library}) => 'লাইব্রেরি: ${library}';
	@override String get ownedReason => 'আপনার লাইব্রেরি থেকে';
	@override String get liveNow => 'এখন সম্প্রচারিত হচ্ছে';
	@override String get watchLive => 'সরাসরি দেখুন';
	@override String get filterAnything => 'যেকোনোটি';
	@override String get filterWatch => 'দেখুন';
	@override String get filterListen => 'শুনুন';
	@override String get filterRead => 'পড়ুন';
	@override String get twentyMinutes => '২০ মিনিট';
	@override String get fortyFiveMinutes => '৪৫ মিনিট';
	@override String get ninetyMinutes => '৯০ মিনিট';
	@override String get apply => 'প্রয়োগ করুন';
	@override String get openFailed => 'এই পছন্দটি আর পাওয়া যাচ্ছে না। আবার যাচাই করতে রিফ্রেশ করুন।';
	@override String get changeFailed => 'পরিবর্তনটি সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।';
	@override String get savedLimit => 'সংরক্ষিত পছন্দের তালিকা পূর্ণ। আরেকটি সংরক্ষণ করতে একটি পছন্দ সরিয়ে দিন।';
	@override String get chooseHint => 'কোনো শিরোনাম খুলুন, পরের জন্য সংরক্ষণ করুন বা এড়িয়ে যান।';
	@override String get howItWorks => 'ব্যবহারের নিয়ম';
	@override String get notNowHelp => 'এই শিরোনামটি আপাতত এড়িয়ে যান। এটি আপনার লাইব্রেরিতে থাকবে।';
	@override String get saveHelp => 'এই ডিভাইসে এই প্রোফাইলের সংরক্ষিত পছন্দে রাখুন। সংরক্ষণ করলে ডাউনলোড হয় না।';
	@override String get openHelp => 'বিস্তারিত দেখতে প্রচ্ছদ নির্বাচন করুন। চালানো, পড়া বা খোলার জন্য প্রধান বোতাম ব্যবহার করুন।';
	@override String get controlsHelp => 'কীবোর্ড বা রিমোট: একটি বোতামে যান, তারপর Enter বা নির্বাচন বোতাম চাপুন। পূর্বাবস্থায় ফেরালে শেষ পছন্দটি ফিরে আসে।';
	@override String get artworkLoading => 'ছবি লোড হচ্ছে…';
	@override String get artworkUnavailable => 'ছবি উপলব্ধ নয়';
	@override String get savedFeedback => 'সংরক্ষিত পছন্দে যোগ করা হয়েছে';
	@override String get skippedFeedback => 'আপাতত এড়িয়ে যাওয়া হয়েছে';
	@override String get releaseToConfirm => 'নিশ্চিত করতে ছেড়ে দিন';
	@override String get remoteHint => 'প্রচ্ছদে ফোকাস: ← / → বেছে নিন · নির্বাচন বোতাম: বিস্তারিত · ↑ / ↓ ফোকাস বদলান';
}

// Path: discover.person
class _Translations$discover$person$bn extends Translations$discover$person$en {
	_Translations$discover$person$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get born => 'জন্ম';
	@override String get died => 'মৃত্যুর';
	@override String get birthplace => 'জন্মস্থান';
	@override String dateWithAge({required Object date, required Object age}) => '${date} (আজ ${age})';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (আজ ${age})';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$bn extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'পরামর্শ';
	@override String get browse => 'ব্রাউজ';
	@override String get collections => 'কালেকশন';
	@override String get playlists => 'খেলোয়াড়';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$bn extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'গ্রুপিং';
	@override String get all => 'সবগুলি';
	@override String get movies => 'চলচ্চিত্র';
	@override String get shows => 'টেলিভিশন প্রদর্শন';
	@override String get seasons => 'সপ্তাহ';
	@override String get episodes => 'পর্বগুলি';
	@override String get artists => 'শিল্পীবৃন্দ';
	@override String get albums => 'অ্যালবাম সমূহ';
	@override String get tracks => 'ট্র্যাক';
	@override String get folders => 'ফোল্ডার';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$bn extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get genre => 'ধরণ';
	@override String get year => 'বছর';
	@override String get contentRating => 'বিষয়বস্তু Rating';
	@override String get tag => 'Tag';
	@override String get unwatched => 'অপসারণ';
	@override String get unplayed => 'খেলা না';
	@override String get favorites => 'পছন্দগুলি';
	@override String get filePath => 'ফাইল পথ';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$bn extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Title নাম';
	@override String get dateAdded => 'তারিখে এসেছে';
	@override String get releaseDate => 'Release তারিখ';
	@override String get rating => 'রেটিং';
	@override String get communityRating => 'জনসাধারনের রেটিং';
	@override String get criticRating => 'ক্রিটিক রেটিং';
	@override String get userRating => 'ব্যবহারকারীর Rating';
	@override String get datePlayed => 'তারিখে চলেছে';
	@override String get playCount => 'খেলা কন্ট';
	@override String get productionYear => 'উৎপাদন বছর';
	@override String get runtime => 'রান্টি';
	@override String get officialRating => 'অফিসিয়াল Rating';
	@override String get premiereDate => 'প্রথম ডেটা';
	@override String get startDate => 'শুরু তারিখ';
	@override String get airTime => 'বিমান সময়';
	@override String get studio => 'স্টুডিও';
	@override String get random => 'পরিস্থিতি';
	@override String get dateShared => 'ডেটা শেয়ার';
	@override String get latestEpisodeAirDate => 'সর্বশেষ আঞ্চলিক ডেটিং';
	@override String get lastEpisodeDateAdded => 'শেষ পরিস্থিতি Date Added';
	@override String get dateDownloaded => 'ডাউনলোডের দিন';
	@override String get size => 'বড়';
	@override String get library => 'লাইব্রেরি';
}

// Path: libraries.advancedFilters
class _Translations$libraries$advancedFilters$bn extends Translations$libraries$advancedFilters$en {
	_Translations$libraries$advancedFilters$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get include => 'অন্তর্ভুক্ত';
	@override String get exclude => 'বের করা';
	@override String get any => 'কোনও';
	@override String get yes => 'হ্যাঁ';
	@override String get no => 'না';
	@override String not({required Object value}) => '${value} নয়';
	@override String valueCount({required Object count}) => '${count} নির্বাচিত';
	@override String valueCountExcluded({required Object count}) => '${count} অস্বীকার';
	@override String get searchValues => 'অনুসন্ধান মূল্য';
	@override String get noValues => 'কোন মূল্য';
	@override String get matchContains => 'কন্টেন্ট';
	@override String get matchNotContains => 'অন্তর্ভুক্ত নয়';
	@override String get matchIs => 'এতে';
	@override String get matchIsNot => 'নাই';
	@override String get matchBeginsWith => 'শুরু করে';
	@override String get matchEndsWith => 'শেষ হয় সঙ্গে';
	@override String get textHint => 'টাইপ খেলা';
	@override String get from => 'থেকে';
	@override String get to => 'টো';
	@override String range({required Object from, required Object to}) => '${from} থেকে ${to}';
	@override String atLeast({required Object value}) => '${value} এবং ওপরে';
	@override String atMost({required Object value}) => 'সর্বোচ্চ ${value}';
	@override String dateLastDays({required Object count}) => 'গত ${count} দিন';
	@override String get dateLastYear => 'গত বছর';
	@override String dateOlderThanDays({required Object count}) => 'বয়স ${count} দিন';
	@override String get dateOlderThanYear => 'এক বছর বয়সী';
}

// Path: libraries.selection
class _Translations$libraries$selection$bn extends Translations$libraries$selection$en {
	_Translations$libraries$selection$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get selectItems => 'পণ্য নির্বাচন';
	@override String selectedCount({required Object count}) => '${count} নির্বাচিত';
	@override String get actions => 'নির্বাচন কার্যক্রম';
	@override String get confirmDescendants => 'এই পরিবর্তন প্রত্যেকটি প্রদর্শন এবং নির্বাচিত সপ্তাহগুলিতে প্রদর্শন পরিবর্তন করে।';
	@override String get confirmUnwatched => 'এতে নির্বাচিত আইটেমগুলির প্লেব্যাকের অগ্রগতিও মুছে যাবে।';
	@override String confirmCount({required Object count}) => 'নির্বাচিত পণ্য: ${count}';
	@override String completed({required Object count}) => 'আপডেট পণ্য: ${count}';
	@override String partialFailure({required Object succeeded, required Object failed}) => 'আপডেট ${succeeded}; ভুল ${failed}. ভুল পণ্যগুলি বেছে নিতে থাকে।';
}

// Path: explore.mdblistShelves
class _Translations$explore$mdblistShelves$bn extends Translations$explore$mdblistShelves$en {
	_Translations$explore$mdblistShelves$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get manage => 'ম্যানেজারি গবেষণার উপাদান';
	@override String get manageDescription => 'আপনার অ্যাকাউন্ট MDBList থেকে তালিকা নির্বাচন করুন এবং সংস্থা করুন';
	@override String get description => 'আপনার অ্যাকাউন্ট MDBList থেকে জনপ্রিয় চলচ্চিত্র এবং টিভি তালিকা নির্বাচন করুন. তাহলে MDBList তালিকা তৈরি করুন বা কপি করুন.';
	@override String get selected => 'বেছে নেওয়া ক্লাস';
	@override String get available => 'উপলব্ধ অ্যাকাউন্টের তালিকা';
	@override String get noLists => 'কোন জনপ্রিয় চলচ্চিত্র বা টিভি তালিকা ফিরে আসেনি. MDBList এর একটি তালিকা তৈরি করুন বা কপি করুন, তারপর আপডেট করুন।';
	@override String get displayName => 'শেলফের নাম';
	@override String get nameHint => 'সূত্র তালিকা নাম ব্যবহার করার জন্য বাদ রাখুন।';
	@override String get add => 'শেলি যোগ করুন';
	@override String get save => 'শিগগির সংরক্ষণ';
	@override String moveUp({required Object title}) => 'মোট ${title} আপ';
	@override String moveDown({required Object title}) => 'ফাঁস করুন ${title}';
	@override String get unavailable => 'এই তালিকা পাওয়া যায় না. সেটিংসগুলিতে তার স্কেল ফেরত বা মুছে ফেলুন.';
	@override String get rateLimited => 'MDBList অনুরোধের সীমাবদ্ধতা পৌঁছানো হয়েছে. পরে দয়া করে ফেরত দাও।';
	@override String get loadFailed => 'আপনার সংযোগ এবং ফেরত চেক করতে পারবেন না।';
	@override String get saveFailed => 'পাশাপাশি পাশাপাশি পাশাপাশি পাশাপাশি পাশাপাশি পাশাপাশি পাশাপাশি পাশাপাশি পাশাপাশি পাশাপাশি পাশাপাশি।';
	@override String get accountChanged => 'অ্যাকাউন্ট বা প্রোফাইল পরিবর্তন করা হয়েছে. এই পরামর্শগুলি আবার খোলা।';
	@override String get settingsUnreadable => 'সংরক্ষিত স্ক্রিনগুলি পড়তে পারে না. এই পরামর্শগুলি পরিবর্তন করার জন্য আপনার তালিকাগুলি আবার নির্বাচন করুন.';
}

// Path: explore.rows
class _Translations$explore$rows$bn extends Translations$explore$rows$en {
	_Translations$explore$rows$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'চোখের তালিকা';
	@override String get recommendedMovies => 'প্রস্তাবিত চলচ্চিত্র';
	@override String get recommendedShows => 'প্রস্তাবিত প্রদর্শন';
	@override String get trendingMovies => 'ট্রেনিং সিনেমা';
	@override String get trendingShows => 'ট্রেন্ডিং প্রদর্শনী';
	@override String get popularMovies => 'জনপ্রিয় চলচ্চিত্র';
	@override String get popularShows => 'জনপ্রিয় প্রদর্শনী';
	@override String get trendingAnime => 'ট্রেনিং অ্যানিম';
	@override String get suggestedAnime => 'অ্যানিমের প্রস্তাব';
	@override String get airingAnime => 'অ্যানিমেটিক অ্যানিমেটিক';
	@override String get popularAnime => 'সবচেয়ে জনপ্রিয় অ্যানিম';
	@override String get trending => 'ট্রেন্ডিং';
	@override String get upcomingMovies => 'আগামী চলচ্চিত্র';
	@override String get upcomingShows => 'আগামী প্রদর্শনী';
}

// Path: explore.status
class _Translations$explore$status$bn extends Translations$explore$status$en {
	_Translations$explore$status$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get airing => 'এয়ারিং';
	@override String get ended => 'শেষ হয়েছে';
	@override String get canceled => 'বাতিল';
	@override String get upcoming => 'আসছে';
}

// Path: explore.badge
class _Translations$explore$badge$bn extends Translations$explore$badge$en {
	_Translations$explore$badge$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} জনপ্রিয়';
	@override String rankAiring({required Object n}) => '#${n} সার্ভিস';
	@override String rankRated({required Object n}) => '#${n} রেকর্ড';
	@override String rankTrending({required Object n}) => '#${n} ট্রেনিং';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} মধ্যে ${season}';
	@override String watchingNow({required Object n}) => '${n} দেখুন';
	@override String get available => 'পাওয়া';
	@override String get partiallyAvailable => 'অংশে পাওয়া যায়';
	@override String get availableIn4k => '4K উপলক্ষে';
	@override String get requested => 'অনুরোধ';
	@override String get pendingApproval => 'অনুমোদনের সময়';
	@override String get processing => 'প্রক্রিয়া';
	@override String get declined => 'দুর্বল';
	@override String get requestFailed => 'অনুরোধ ভুল';
	@override String get requested4k => '4K অনুরোধ';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} সপ্তাহ';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => 'Ep ${episode} মধ্যে ${duration}';
	@override String nextAiringIn({required Object duration}) => 'পরবর্তী নিবন্ধ ${duration}';
	@override String episodesShort({required Object n}) => '${n} ইপিএস';
	@override String minutesPerEpisode({required Object n}) => '${n} মিনিট/এপি';
	@override String get adult => '18+';
}

// Path: explore.stats
class _Translations$explore$stats$bn extends Translations$explore$stats$en {
	_Translations$explore$stats$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} তালিকাভুক্ত';
	@override String viewersDay({required Object n}) => 'আজ ${n} জন দেখেছেন';
	@override String viewersWeek({required Object n}) => 'এই সপ্তাহে ${n} জন দেখেছেন';
	@override String viewersMonth({required Object n}) => 'এই মাসে ${n} জন দেখেছেন';
	@override String viewersYear({required Object n}) => 'এই বছরে ${n} জন দেখেছেন';
	@override String viewersAllTime({required Object n}) => '${n} ভিউ';
	@override String planning({required Object n}) => '${n} দেখতে চান';
	@override String favorited({required Object n}) => '${n} পছন্দ';
	@override String dropRate({required Object percent}) => '${percent} একেবারে ফেরত';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} মন্তব্য',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} মন্তব্য',
	);
	@override String votes({required Object n}) => '${n}টি ভোট';
	@override String watching({required Object n}) => '${n} দেখুন';
	@override String completed({required Object n}) => '${n} সম্পন্ন';
	@override String onHold({required Object n}) => '${n} হাতে';
	@override String dropped({required Object n}) => '${n} জন দেখা বন্ধ করেছেন';
}

// Path: explore.season
class _Translations$explore$season$bn extends Translations$explore$season$en {
	_Translations$explore$season$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get winter => 'শীতের';
	@override String get spring => 'শতাব্দী';
	@override String get summer => 'গ্রীষ্ম';
	@override String get fall => 'হাঁটতে';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class _Translations$explore$format$bn extends Translations$explore$format$en {
	_Translations$explore$format$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get tv => 'টেলিভিশন';
	@override String get tvShort => 'টেলিভিশন ছোট';
	@override String get movie => 'চলচ্চিত্র';
	@override String get special => 'বিশেষ';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => 'সঙ্গীত';
	@override String get other => 'অন্য';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$bn extends Translations$explore$sourceMaterial$en {
	_Translations$explore$sourceMaterial$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get original => 'মূল';
	@override String get manga => 'ম্যানেজমেন্ট';
	@override String get lightNovel => 'আলো গল্প';
	@override String get novel => 'গল্প';
	@override String get visualNovel => 'ভিসুয়াল রোবট';
	@override String get game => 'খেলা';
	@override String get webComic => 'ওয়েবসাইট কমিক';
	@override String get musicRelease => 'সঙ্গীত';
	@override String get otherMedia => 'অন্য';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$bn extends Translations$explore$creditRole$en {
	_Translations$explore$creditRole$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get actor => 'অভিনেতা';
	@override String get director => 'পরিচালক';
	@override String get writer => 'লেখক';
	@override String get producer => 'উৎপাদনকারী';
	@override String get creator => 'সৃষ্টি';
	@override String get composer => 'সুরকার';
}

// Path: explore.relation
class _Translations$explore$relation$bn extends Translations$explore$relation$en {
	_Translations$explore$relation$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get prequel => 'পূর্বাভাস';
	@override String get sequel => 'সেকেন্ড';
	@override String get sideStory => 'Side গল্প';
	@override String get spinOff => 'স্পিন-অফ';
	@override String get alternativeVersion => 'Alternative সংস্করণ';
	@override String get summary => 'সাবধান';
	@override String get parentStory => 'বাবা-মা গল্প';
	@override String get adaptation => 'adaptation সংশ্লিষ্ট';
	@override String get other => 'সম্পর্কিত';
}

// Path: explore.detail
class _Translations$explore$detail$bn extends Translations$explore$detail$en {
	_Translations$explore$detail$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'মূল নাম';
	@override String get alsoKnownAs => 'এছাড়াও পরিচিত যে';
	@override String get studios => 'স্টুডিও';
	@override String get country => 'দেশ';
	@override String get language => 'ভাষা';
	@override String get released => 'মুক্তি';
	@override String get physicalRelease => 'ডিজিটাল';
	@override String get ended => 'শেষ হয়েছে';
	@override String addedOn({required Object date}) => 'যোগ করা ${date}';
	@override String get yourRating => 'আপনার Rating';
	@override String get budget => 'বাজেট';
	@override String get revenue => 'বক্স অফিস';
	@override String get contentAdvisory => 'বয়স গাইডিং';
	@override String get tags => 'ট্যাগ';
	@override String get revealSpoilerTags => 'স্পোিলার ট্যাগ';
	@override String get links => 'বামদিকে';
	@override String get watchOn => 'দেখুন';
	@override String get watchTrailer => 'ট্র্যালার দেখুন';
	@override String openOn({required Object site}) => 'খোলা ${site}';
	@override String get crew => 'ক্লাব';
	@override String get ratings => 'রেটিং';
	@override String get schedule => 'পরিকল্পনা';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n,
		one: 'ব্যবহারকারী ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} দ্বারা পরামর্শ',
		other: 'সংশোধন করা হয়েছে ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ব্যবহারকারীদের',
	);
	@override String recommendedBy({required Object who}) => 'সংখ্যা: ${who}';
	@override String favoritedBy({required Object who}) => 'পছন্দ করা হয়েছে ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} এখনো প্রদর্শিত হয়নি';
	@override String recommendedByPercent({required Object percent}) => 'সংশোধন করা হয়েছে ${percent} জনের জন্য';
	@override String get relatedTitles => 'সম্পর্কিত টাইম';
	@override String get background => 'ফাউন্ডেশন';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$bn extends Translations$liveTv$recordSettings$en {
	_Translations$liveTv$recordSettings$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get startEarly => 'দীর্ঘদিনের শুরু (2 সেকেন্ড)';
	@override String get endLate => 'দেরি শেষ (2 সেকেন্ড)';
	@override String get newOnly => 'শুধু নতুন ঘটনা';
	@override String get anyChannel => 'প্রতিটি চ্যানেলের রেকর্ড';
	@override String get anyTime => 'প্রতিটি সময় রেকর্ড';
	@override String get skipInLibrary => 'লাইব্রেরিতে ইতিমধ্যে অ্যাপিগারেটস';
	@override String get keepUpTo => 'চলতে যাওয়ার ঘটনা';
	@override String get keepUpToHint => '0 প্রতিটি অধ্যায়';
}

// Path: music.discography
class _Translations$music$discography$bn extends Translations$music$discography$en {
	_Translations$music$discography$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'Singles ও EPs';
	@override String get live => 'জীবনযাপন';
	@override String get compilations => 'কম্পিউটার';
}

// Path: watchTogether.notices
class _Translations$watchTogether$notices$bn extends Translations$watchTogether$notices$en {
	_Translations$watchTogether$notices$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name} প্রচুর খেলা';
	@override String get playbackStarted => 'Playback শুরু';
	@override String paused({required Object name}) => '${name} পাস';
	@override String get playbackPaused => 'Playback বন্ধ';
	@override String jumpedTo({required Object name, required Object position}) => '${name} ${position} পর্যন্ত গিয়েছে';
	@override String roomJumpedTo({required Object position}) => 'পাশাপাশি ${position}';
	@override String changedSpeed({required Object name, required Object speed}) => '${name} গতিটি ${speed} পর্যন্ত নির্ধারণ করুন';
	@override String speedChanged({required Object speed}) => 'গতি সংশোধন ${speed}';
	@override String startedMedia({required Object name, required Object title}) => '${name} শুরু ${title}';
	@override String mediaStarted({required Object title}) => 'এখন খেলতে ${title}';
	@override String stoppedMedia({required Object name}) => '${name} ভিডিও বন্ধ';
	@override String get mediaStopped => 'ভিডিও বন্ধ';
	@override String waitingFor({required Object name}) => '${name} এর জন্য অপেক্ষা করছি।';
	@override String get waitingForSomeone => 'অপেক্ষা করলে কেউ চাপে পড়বে...';
	@override String get finished => 'শেষ';
	@override String hostChangedTo({required Object name}) => '${name} এখন হোস্ট';
	@override String get youAreNowHost => 'আপনি এখন হোস্ট';
	@override String joined({required Object name}) => '${name} যোগ করা';
	@override String left({required Object name}) => '${name} চলে গেছেন';
	@override String get controlRefused => 'শুধুমাত্র হোস্ট Playback নিয়ন্ত্রণ করতে পারেন';
	@override String get searchFailed => 'কিছু সার্ভার রুমের ভিডিও জন্য খুঁজে পেতে পারেননি';
	@override String get playBlocked => 'শুরু করতে চান প্রেস খেলা';
	@override String get shareFailed => 'এই ভিডিওটি রুমের সাথে শেয়ার করতে পারতাম না';
	@override String get downloadNotShared => 'ডাউনলোডগুলি তাদের সার্ভার অফলি থাকলেও রুমের সাথে শেয়ার করা হয় না';
	@override String get openFailed => 'রুমের ভিডিও খুলতে পারত না';
}

// Path: watchTogether.ended
class _Translations$watchTogether$ended$bn extends Translations$watchTogether$ended$en {
	_Translations$watchTogether$ended$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get ended => 'হেস্টরুম শেষ করেছিলেন';
	@override String get kicked => 'তুমি রুম থেকে বের হয়ে গেলো।';
	@override String get expired => 'রুম শেষ হয়েছে';
	@override String get replaced => 'আপনি অন্য ডিভাইসে এই রুমে যোগ করেন';
	@override String get lost => 'রুমের সাথে সংযোগ হারিয়ে';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$bn extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => 'কোডগুলির মধ্যে 6 চিঠি এবং ডিগ্রী আছে, 0, 1, I, L বা O ছাড়া।';
	@override String get roomNotFound => 'এই কোডের কোন রুম নেই, এটি শেষ হতে পারে।';
	@override String get roomFull => 'সেই রুমটা পুরোপুরি।';
	@override String get roomLocked => 'হেস্টরটি ওই রুমকে বন্ধ করে দিয়েছিল।';
	@override String get relayFull => 'এখন কাজে লাগে, পরে আবার চেষ্টা করুন।';
	@override String get unreachable => 'ঘন্টা একসাথে relay পৌঁছাতে পারত না. আপনার সংযোগ চেক করুন.';
	@override String get rateLimited => 'একটু অপেক্ষা করুন এবং আবার চেষ্টা করুন।';
	@override String get clientBlocked => 'এই সংস্করণ PlezyNG relay ব্যবহার করতে পারেন না. অ্যাপটি আপডেট করুন.';
	@override String get forbidden => 'শুধুমাত্র হেস্টারই সেটা করতে পারেন।';
	@override String get notInRoom => 'আপনি একটি রুমে নেই।';
	@override String get alreadyInRoom => 'আপনি এখন একটি রুমে আছেন।';
	@override String get resumeFailed => 'রুমে আসতে পারত না।';
	@override String get unsupported => 'রেলিও এ ব্যাপারে সমর্থন করেনি।';
	@override String get generic => 'কিছুটা ভুল হয়েছে, আবারও চেষ্টা করুন।';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$bn extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'অ্যাপটি ছেড়ে গেলে ডাউনলোড বন্ধ হবে';
	@override String get bannerDegraded => 'ডাউনলোড সীমিত হতে পারে';
	@override String get bannerAction => 'বিস্তারিত';
	@override String get sheetTitle => 'ডাউনলোড করা হয় ব্লক';
	@override String get sheetTitleDegraded => 'ডাউনলোড সীমিত হতে পারে';
	@override String get sheetIntro => 'Android সূত্রে নির্ভরযোগ্যভাবে ডাউনলোড করার জন্য PlezyNG বাধা দেয়।';
	@override String get sheetIntroDegraded => 'আপনার ডিভাইস যখন PlezyNG ফাউনলোড করতে পারেন তখন সীমিত।';
	@override String get reasonBackgroundRestricted => 'PlezyNG এর ফাউন্ডেশন ব্যবহার সীমিত. তার ব্যাটারি বা ফাউন্ডেশন ব্যবহারকে "অনীমিত" হিসাবে সীমিত করুন।';
	@override String get reasonStandbyRestricted => 'Android একটি সীমিত স্থিতিশীল অবস্থায় PlezyNG রাখা হয়েছে. তার ব্যাটারি ব্যবহারকে "অীমিত" হিসাবে স্থিতিশীল করুন।';
	@override String get reasonDownloadChannelBlocked => 'ডাউনলোড通知গুলি বন্ধ করা হয়, তাই প্রদর্শন এবং নিয়ন্ত্রণ পাওয়া যায় না।';
	@override String get reasonNotificationsDisabled => 'Notifications are turned off. On Android 13 or later, they are required for long background downloads. এগুলি দীর্ঘ পর্যায়ে ডাউনলোডের জন্য প্রয়োজনীয়।';
	@override String get reasonDataSaver => 'ডেটা সেভার চালু থাকায় মোবাইল ডেটায় পটভূমিতে ডাউনলোড বন্ধ আছে। Wi-Fi-এ ডাউনলোড চলার কথা।';
	@override String get reasonOemUnknown => 'ডাউনলোডগুলি বারবার বন্ধ হয়েছিল যখন PlezyNG ফাউনলোডে ছিল। PlezyNG এর ব্যাটারি বা ফাউনলোড ব্যবহারের পরামর্শগুলি দেখুন।';
	@override String get openSettings => 'খোলা সিস্টেম';
	@override String get stillNotWorking => 'ডিভাইস-সpecific সহায়তা';
	@override String get stillNotWorkingDescription => 'আপনার ডিভাইসের জন্য পদক্ষেপ দেখুন, অথবা সমস্যা চলছে যদি Settings › View Logs থেকে একটি লগ পাঠান।';
	@override String get dialogTitle => 'ডাউনলোড শেষ হতে পারে না';
	@override String get dialogDownloadAnyway => 'ডাউনলোড করুন যেকোনো';
	@override String get dialogFixFirst => 'প্রথমেই এটি ঠিক করুন';
	@override String get statusTile => 'ডাউনলোড ফাউনলোড';
	@override String get statusOk => 'ফলাফলে চালু হতে পারে';
	@override String get statusBlocked => 'সিস্টেম সিস্টেম সিস্টেম সিস্টেম সিস্টেম';
	@override String get statusDegraded => 'সিস্টেম সীমিত';
	@override String get statusUnknown => 'এখনো চেক করা হয়নি';
	@override String get settingsUnavailable => 'এই ডিভাইসে সিস্টেম সেটিং খোলা যায় না';
	@override String get linkUnavailable => 'এই ডিভাইসে dontkillmyapp.com খোলা যায় না';
}

// Path: downloads.groupings
class _Translations$downloads$groupings$bn extends Translations$downloads$groupings$en {
	_Translations$downloads$groupings$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get library => 'লাইব্রেরি';
	@override String get collections => 'কালেকশন';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$bn extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'দূরবর্তী সার্ভার চালানোর...';
	@override String get hostAddress => 'হোস্ট ঠিকানা';
	@override String get connected => 'সংযুক্ত';
	@override String get serverRunning => 'Remote Server সার্ভার';
	@override String get serverStopped => 'দূরবর্তী সার্ভার বন্ধ';
	@override String get serverRunningDescription => 'আপনার নেটওয়ার্কের মোবাইল ডিভাইস এই অ্যাপের সাথে সংযোগ করতে পারে';
	@override String get serverStoppedDescription => 'সার্ভার চালু করুন যাতে মোবাইল ডিভাইসগুলি সংযোগ করতে পারে';
	@override String get usePhoneToControl => 'এই অ্যাপটি নিয়ন্ত্রণ করতে আপনার মোবাইল ডিভাইস ব্যবহার করুন';
	@override String get startServer => 'সার্ভার শুরু';
	@override String get stopServer => 'সার্ভার বন্ধ';
	@override String get minimize => 'কমপক্ষে';
	@override String get manualAddressHint => 'ম্যানুয়াল সংযোগ ঠিকানা:';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$bn extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'একই অ্যাকাউন্ট Plex সঙ্গে PlezyNG ডিভাইস এখানে দেখা যায়';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'সংযোগ...';
	@override String get searchingForDevices => 'সরঞ্জাম খুঁজছেন...';
	@override String get noDevicesFound => 'আপনার নেটওয়ার্কে কোন ডিভাইস পাওয়া যায়নি';
	@override String get noDevicesHint => 'ডেস্টোভে PlezyNG খুলুন এবং একই Wi-Fi ব্যবহার করুন';
	@override String get availableDevices => 'উপলব্ধ ডিভাইস';
	@override String get manualConnection => 'ম্যানুয়াল সংযোগ';
	@override String get cryptoInitFailed => 'নিরাপদ সংযোগ শুরু করতে পারবেন না. প্রথমে Plex এর সাথে সাইন আপ করুন।';
	@override String get validationHostRequired => 'দয়া করে হোস্ট ঠিকানা লিখুন';
	@override String get validationHostFormat => 'ফরম্যাটটি আইপি:পোর্ট (যেমন, 192.168.1.100:48632) হতে হবে।';
	@override String get connectionTimedOut => 'একই নেটওয়ার্ক ব্যবহার করুন, দুটি ডিভাইসে একই নেটওয়ার্ক ব্যবহার করুন।';
	@override String get sessionNotFound => 'ডিভাইস পাওয়া যায় না. নিশ্চিত করুন যে PlezyNG হোস্টারে চালু হয়।';
	@override String get authFailed => 'সনাক্তকরণ ভুল হয়েছে. দুটি ডিভাইসের একই অ্যাকাউন্ট Plex প্রয়োজন।';
	@override String failedToConnect({required Object error}) => 'সংযোগ করতে পারিনি: ${error}';
	@override String get codeTitle => 'প্যারিস কোড';
	@override String get codeDescription => 'হোস্ট ডিভাইসে Companion Remote-তে প্রদর্শিত কোডটি প্রদর্শন করুন. দুটি ডিভাইস একটি সংস্করণ ব্যবহার করতে হবে যা নিরাপদ প্যারিয়ারি সমর্থন করে।';
	@override String get codeInvalid => 'হোস্ট কোড থেকে সব 32 বাক্স এবং নম্বর লিখুন।';
	@override String get updateRequired => 'উভয় ডিভাইসগুলি একটি সংস্করণে আপডেট করুন যা নিরাপদ প্যারিয়ারি সমর্থন করে।';
	@override String get hostDescription => 'এই কোডটি একবার প্রত্যেকটি দূরে প্রদান করুন. এটি গোপন রাখুন: এটি এই প্রোফাইলের নিয়ন্ত্রণ দেয়।';
	@override String get resetCode => 'প্যারিয়ার কোড পুনরায়';
	@override String get resetDescription => 'সমস্ত রিমোট বন্ধ করুন এবং একটি নতুন কোড তৈরি করুন. প্রতিটি রিমোটকে আবার প্যারি করতে হবে।';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$bn extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'আপনি কি দূরবর্তী সেশন থেকে ডাউনলোড করতে চান?';
	@override String get reconnecting => 'আবার সংযোগ...';
	@override String attemptOf({required Object current}) => 'সন্ধান ${current} এর মধ্যে 5';
	@override String get retryNow => 'ফিরে আসুন এখন';
	@override String get tabRemote => 'দূরত্ব';
	@override String get tabPlay => 'খেলা';
	@override String get tabMore => 'আরও';
	@override String get menu => 'মেনু';
	@override String get tabNavigation => 'ট্যাব ন্যাভাইজেশন';
	@override String get tabDiscover => 'খোঁজ';
	@override String get tabLibraries => 'বইয়েরা';
	@override String get tabSearch => 'অনুসন্ধান';
	@override String get tabDownloads => 'ডাউনলোড';
	@override String get tabSettings => 'সিস্টেম';
	@override String get previous => 'পূর্ববর্তী';
	@override String get playPause => 'খেলা / পাস';
	@override String get next => 'পরবর্তী';
	@override String get seekBack => 'ফেরত খুঁজুন';
	@override String get stop => 'থামুন';
	@override String get seekForward => 'FWD খুঁজে পেতে';
	@override String get volume => 'পরিমাণ';
	@override String get volumeDown => 'নিচে';
	@override String get volumeUp => 'উড়ে';
	@override String get fullscreen => 'ফুলস্ক্রিন';
	@override String get subtitles => 'সাবটাইটেল';
	@override String get audio => 'অডিও';
	@override String get searchHint => 'ডেস্টোভে অনুসন্ধান...';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$bn extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'কোন নেটওয়ার্ক ইন্টারফেস পাওয়া যায় না';
	@override String get authenticationFailed => 'সনাক্তকরণ ভুল';
	@override String serverStartFailed({required Object error}) => 'দূরে সার্ভার চালু করতে পারিনি: ${error}';
	@override String commandFailed({required Object error}) => 'দূরে অর্ডার পাঠানোর ক্ষমতা: ${error}';
	@override String get joinTimedOut => 'সাক্ষাৎকারে অংশগ্রহণ করার সময়';
	@override String get failedToConnectAnyAddress => 'কোনও ঠিকানা থেকে যোগাযোগ করতে পারিনি';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'সংযোগ হারিয়েছে ${attempts} চেষ্টা';
	@override String get connectionLost => 'সংযোগ হারিয়ে গেছে';
}

// Path: services.names
class _Translations$services$names$bn extends Translations$services$names$en {
	_Translations$services$names$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class _Translations$services$simklReconnect$bn extends Translations$services$simklReconnect$en {
	_Translations$services$simklReconnect$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'সংযোগ Simkl';
	@override String get subtitle => 'এই সংযোগে ব্যবহৃত সাইন-ইন পদ্ধতি Simkl বন্ধ করে দিচ্ছে। পুনরায় সংযোগ করলে PlezyNG-কে অনুমোদন দিতে simkl.com খুলবে — PlezyNG কখনো আপনার পাসওয়ার্ড দেখতে পায় না। আপনার দেখার ইতিহাস Simkl-এ থাকবে।';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$bn extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '${service} এর উপর PlezyNG সক্রিয় করুন';
	@override String get instructions => 'QR কোড স্ক্যান করুন, অথবা নিচের ঠিকানা দেখুন এবং এই কোডটি প্রদান করুন:';
	@override String openToActivate({required Object service}) => '${service} সক্রিয় করতে খোলা';
	@override String get copyCode => 'সক্রিয় কোড কপি করুন';
	@override String get waitingForAuthorization => 'অনুমোদনের জন্য অপেক্ষা...';
	@override String get codeCopied => 'কোড কপি';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$bn extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'সাইন আপ করুন ${service}';
	@override String get body => 'এই QR কোড স্ক্যান করুন বা কোন ডিভাইসের URL খুলুন।';
	@override String openToSignIn({required Object service}) => 'খোলা ${service} নিবন্ধন করতে';
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$bn extends Translations$services$pendingAuth$en {
	_Translations$services$pendingAuth$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'কপি sign-in URL';
	@override String get urlCopied => 'URL কপি';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$bn extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'লাইব্রেরি ফিল্টার';
	@override String get subtitleAllSyncing => 'সকল লাইব্রেরি সিন্সিং';
	@override String get subtitleNoneSyncing => 'কিছুই সিন্সিং';
	@override String subtitleBlocked({required Object count}) => '${count} অবরোধ';
	@override String subtitleAllowed({required Object count}) => '${count} অনুমোদিত';
	@override String get mode => 'ফিল্টার মডেল';
	@override String get modeBlacklist => 'নিষিদ্ধ তালিকা';
	@override String get modeWhitelist => 'সাদা';
	@override String get modeHintBlacklist => 'নিচে চেক করাগুলি ছাড়া প্রতিটি লাইব্রেরি সনাক্ত করুন।';
	@override String get modeHintWhitelist => 'শুধুমাত্র নিচের লাইব্রেরিগুলি সিনক করুন।';
	@override String get libraries => 'বইয়েরা';
	@override String get noLibraries => 'কোন লাইব্রেরি নেই';
	@override String get modeDescription => 'চেক করা লাইব্রেরিগুলো সিঙ্ক হওয়া থেকে আটকানো হবে নাকি শুধু সেগুলোই সিঙ্ক হবে, তা বেছে নিন।';
}

// Path: services.trackerDescriptions
class _Translations$services$trackerDescriptions$bn extends Translations$services$trackerDescriptions$en {
	_Translations$services$trackerDescriptions$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get trakt => 'আপনার ট্র্যাক্ট অ্যাকাউন্টের সাথে সিনেমা দেখানো epizodes এবং মুভি।';
	@override String get mal => 'অ্যানিমি তালিকা সনাক্ত করুন এবং MyAnimeList এর সাথে উন্নয়ন দেখুন।';
	@override String get anilist => 'অ্যানিমি তালিকা সনাক্ত করুন এবং AniList এর সাথে উন্নয়ন দেখুন।';
	@override String get simkl => 'সিন্ক চলচ্চিত্র, টেলিভিশন প্রদর্শন এবং অ্যানিমি দেখে Simkl সঙ্গে।';
	@override String get mdblist => 'MDBList রিটার এবং তালিকায় পরামর্শগুলি দেখুন এবং অনুসন্ধান করুন।';
}

/// The flat map containing all translations for locale <bn>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsBn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'appIcon.title' => 'আইকোন আইকোন',
			'appIcon.defaultIcon' => 'প্রত্যাশিত',
			'appIcon.current' => 'বর্তমান আইকোন',
			'appIcon.locked' => 'জীবনযাপন প্রয়োজনীয়',
			'appIcon.lockedHint' => 'আপনার 7 দিনের পরীক্ষা শুরু করুন অথবা বিকল্প আইকোনগুলি ব্যবহার করার জন্য PlezyNG লাইভের জন্য অলোক করুন।',
			'appIcon.changeFailed' => 'অ্যাপ আইকন পরিবর্তন করতে পারবেন না',
			'appIcon.launcherHint' => 'নতুন আইকন আপনার বাড়ি স্ক্রিনে প্রদর্শিত হবে একবার আপনি PlezyNG ছেড়ে যান।',
			'appIcon.tvLauncherHint' => 'নতুন ব্যানারটি আপনাকে PlezyNG ছেড়ে দেওয়ার পর দেখা যায়। Android TV টেলিভিশন আবার শুরু হওয়ার পর্যন্ত পুরনো ব্যানারটি প্রদর্শন করতে পারবেন।',
			'appIcon.names.midnight' => 'মধ্য রাতে',
			'appIcon.names.ember' => 'মানুষ',
			'appIcon.names.paper' => 'কাবার',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => 'লাইন',
			'appIcon.names.ocean' => 'আকাশ',
			'appIcon.names.ultraviolet' => 'অলিট্রোভিয়াল',
			'appIcon.names.matcha' => 'ম্যাচ',
			'appIcon.names.sunset' => 'সূর্য',
			'appIcon.names.gold' => 'অলিন',
			'appIcon.names.titanium' => 'টাইটানিয়াম',
			'appIcon.names.glass' => 'গ্লাস',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => 'সিন্টওয়াই',
			'appIcon.names.pixel' => 'পিক্সেল',
			'appIcon.names.neon' => 'নিয়েন',
			'appIcon.names.sticker' => 'স্টিকার',
			'appIcon.names.ticket' => 'টিকিট',
			'appIcon.names.pop' => 'পপ',
			'appIcon.names.strata' => 'বিপর্যয়',
			'appIcon.names.facet' => 'মুখ',
			'appIcon.names.tilde' => 'টাইম',
			'appIcon.description' => 'আপনার ডিভাইসের লঞ্চারে কোন আইকন দেখানো হবে তা বেছে নিন। প্রিভিউতে প্রতিটি বিকল্প কেমন দেখায় তা দেখতে পারবেন।',
			'auth.signInWithPlex' => 'সাইন আপ করুন Plex',
			'auth.showQRCode' => 'QR কোড দেখুন',
			'auth.authenticate' => 'সত্যতা',
			'auth.authenticationTimeout' => 'সনাক্তকরণ সময়সীমা শেষ, আবারও চেষ্টা করুন।',
			'auth.scanQRToSignIn' => 'এই QR কোডটি স্ক্যান করুন',
			'auth.waitingForAuth' => 'সনাক্তকরণের জন্য অপেক্ষায়... আপনার ব্রাউজার থেকে সাইন আপ করুন।',
			'auth.useBrowser' => 'ব্রাউজার ব্যবহার',
			'auth.or' => 'অথবা',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'সংযোগ ${product}',
			'auth.quickConnect' => 'Quick Connect',
			'auth.useQuickConnect' => 'কুইক কানেক্ট ব্যবহার করুন',
			'auth.quickConnectInstructions' => 'Jellyfin এর পৃষ্ঠায় Quick Connect খোলা এবং এই কোডটি প্রদান করুন।',
			'auth.quickConnectWaiting' => 'অনুমোদনের জন্য অপেক্ষা...',
			'auth.quickConnectCancel' => 'বাতিল',
			'auth.quickConnectExpired' => 'দ্রুত সংযোগের মেয়াদ শেষ হয়েছে। আবার চেষ্টা করুন।',
			'auth.localDataRecoveryRequired' => 'PlezyNG স্থানীয় সাইন-ইনের তথ্য ও অপেক্ষমাণ প্লেব্যাকের তথ্য নিরাপদে পুনরুদ্ধার করতে পারেনি। আবার সাইন ইন করুন।',
			'auth.pinCheckRejected' => 'Plex PIN চেক বাতিল করা হয়েছে',
			'auth.connectToDirectPlex' => 'স্থানীয় সার্ভার Plex এর সাথে সংযোগ',
			'common.cancel' => 'বাতিল',
			'common.save' => 'সুরক্ষা',
			'common.close' => 'বন্ধ',
			'common.closeMiniPlayer' => 'মিনি খেলোয়াড়',
			'common.closeWorkspaceWindow' => 'দীর্ঘ উইন্ডো',
			'common.returnToFullView' => 'পুরো দৃষ্টিতে ফিরে আসুন',
			'common.manageMediaSessions' => 'মিডিয়া সেশন পরিচালনা',
			'common.hideMediaSessions' => 'গণমাধ্যম সন্ধান',
			'common.mediaSessions' => 'মিডিয়া সিনেমা',
			'common.mediaSessionsHint' => 'পার্ক তার উইন্ডোকে লুকিয়ে রাখে কিন্তু এটি খুলে রাখে. ফেরত পুরো ভিউতে এটি খুলবে; নীচে এটি শেষ করে।',
			'common.sessionInWorkspace' => 'কর্মস্থানে',
			'common.sessionParked' => 'পার্কিং',
			'common.sessionFullscreen' => 'পুরো স্ক্রিন',
			'common.switchToNextWindow' => 'Next উইন্ডোজের সাথে বিনিময় করুন',
			'common.moveWindow' => 'বাইরের ভ্রমণ',
			'common.finishMovingWindow' => 'ফাইনাল ভ্রমণ উইন্ডো',
			'common.moveWindowHint' => 'দীর্ঘ চাপ করুন এবং ফাঁকটি এগিয়ে রাখুন. এই নিয়ন্ত্রন প্ল্যান-চিঠি গতিও অনুমোদিত করে।',
			'common.movingWindowHelp' => 'সরাতে টেনে আনুন · তীর কীগুলো দিয়ে সামঞ্জস্য করুন · Enter সংরক্ষণ করে · Escape বাতিল করে',
			'common.resizeWindow' => 'পুনরাবৃত্তি উইন্ডো',
			'common.resizeWindowHint' => 'এই হ্যান্ডেলটি চাপ করুন বা ফাঁসের পুনরাবৃত্তি করার জন্য পাখি খোলাগুলি ব্যবহার করুন।',
			'common.workspaceWindowHint' => 'গাড়ি নিয়ন্ত্রণ বা দীর্ঘ চাপ ব্যবহার করুন এবং গাড়ির জন্য ড্রাইভ করুন।',
			'common.workspacePaneHint' => 'ফোকাস করতে এই প্যানেলটি নির্বাচন করুন। বড় করতে এর ফুলস্ক্রিন নিয়ন্ত্রণ ব্যবহার করুন।',
			'common.workspaceWindowLabel' => ({required Object title}) => 'সেশন উইন্ডো: ${title}',
			'common.workspaceTitleHint' => 'ফোকাস করতে নির্বাচন করুন। সরাতে শিরোনাম বার টেনে ধরুন; বড় করতে ফুলস্ক্রিন বোতাম ব্যবহার করুন।',
			'common.moveToSessionTray' => 'সিনিয়াম ট্রাই',
			'common.moveToSessionTrayHint' => 'এই সেশনটি তার উইন্ডো দেখানোর জন্য উপলব্ধ নয়।',
			'common.closeSessionHint' => 'এই উইন্ডোটি বন্ধ করুন এবং তার সেশন শেষ হবে।',
			'common.sideBySideLayout' => 'Side-by-side layout এর জন্য সুইচ',
			'common.floatingWindows' => 'উইন্ডোজ ফ্লাইট করার জন্য সুইচ',
			'common.clear' => 'স্পষ্ট',
			'common.reset' => 'পুনরাবৃত্তি',
			'common.later' => 'পরে',
			'common.submit' => 'জমা দিন',
			'common.confirm' => 'নিশ্চিত করুন',
			'common.retry' => 'ফেরত',
			'common.logout' => 'ডাউনলোড করুন',
			'common.unknown' => 'অজানা',
			'common.refresh' => 'ফ্রিজ করুন',
			'common.yes' => 'হ্যাঁ',
			'common.no' => 'না',
			'common.delete' => 'মুছে ফেলুন',
			'common.edit' => 'এডিট',
			'common.shuffle' => 'এলোমেলোভাবে চালান',
			'common.addTo' => 'যোগ করুন...',
			'common.createNew' => 'নতুন তৈরি করুন',
			'common.connect' => 'কানেক্ট',
			'common.disconnect' => 'ডিসকানেক্ট',
			'common.play' => 'চালান',
			'common.pause' => 'বিরতি',
			'common.resume' => 'আবার চালান',
			'common.error' => 'ভুল',
			'common.search' => 'অনুসন্ধান',
			'common.home' => 'বাড়ি',
			'common.back' => 'অনগ্রসর',
			'common.settings' => 'সিস্টেম',
			'common.mute' => 'মুটি',
			'common.ok' => 'আচ্ছা',
			'common.off' => 'বন্ধ',
			'common.options' => 'অপশন',
			'common.seasonNumber' => ({required Object number}) => 'সপ্তাহ ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'আয়াত ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'পৃষ্ঠা ${number}',
			'common.reconnect' => 'আবার সংযোগ',
			'common.viewAll' => 'দেখুন সব',
			'common.checkingNetwork' => 'নেটওয়ার্ক চেক...',
			'common.loadingServers' => 'লোডিং সার্ভার...',
			'common.connectingToServers' => 'সার্ভারদের সাথে সংযোগ...',
			'common.startingOfflineMode' => 'অফলফোন মডিও শুরু...',
			'common.loading' => 'লোডিং...',
			'common.fullscreen' => 'ফুলস্ক্রিন',
			'common.exitFullscreen' => 'পুরো স্ক্রিনের বাইরে',
			'common.pressBackAgainToExit' => 'ফেরত ফিরে চাপ করুন',
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
			'common.notAvailable' => 'ন/এ',
			'common.url' => 'URL',
			'common.letterKeys' => 'ABC',
			'common.mediaKind.movie' => 'চলচ্চিত্র',
			'common.mediaKind.show' => 'প্রদর্শন',
			'common.mediaKind.season' => 'সপ্তাহ',
			'common.mediaKind.episode' => 'পর্ব',
			'common.mediaKind.artist' => 'শিল্পী',
			'common.mediaKind.album' => 'অ্যালবাম',
			'common.mediaKind.track' => 'ট্র্যাক',
			'common.mediaKind.collection' => 'সংগ্রহ',
			'common.mediaKind.playlist' => 'প্লেলিস্ট',
			'common.mediaKind.clip' => 'ক্লিপ',
			'common.mediaKind.photo' => 'ছবি',
			'common.mediaKind.folder' => 'ফোল্ডার',
			'screens.licenses' => 'লাইসেন্স',
			'screens.switchProfile' => 'সুইচ প্রোফাইল',
			'screens.subtitleStyling' => 'Subtitle স্টাইলিং',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'লগ',
			'update.available' => 'আপডেট পাওয়া যায়',
			'update.versionAvailable' => ({required Object version}) => 'সংস্করণ ${version} পাওয়া যায়',
			'update.currentVersion' => ({required Object version}) => 'বর্তমান: ${version}',
			'update.skipVersion' => 'এই সংস্করণ থেকে বের করুন',
			'update.viewRelease' => 'দেখুন Release',
			'update.latestVersion' => 'আপনি সর্বশেষ সংস্করণে আছেন',
			'update.checkFailed' => 'আপডেটের জন্য চেক করতে পারিনি',
			'settings.title' => 'সিস্টেম',
			'settings.supportDeveloper' => 'সমর্থন PlezyNG',
			'settings.supportDeveloperDescription' => 'উন্নয়নকে সহায়তা দেওয়ার জন্য',
			'settings.lifetimeAccess' => 'PlezyNG জীবনের অ্যাক্সেস',
			'settings.language' => 'ভাষা',
			'settings.theme' => 'বিষয়',
			'settings.appearance' => 'প্রদর্শন',
			'settings.detailPage' => 'বিস্তারিত পাতা',
			'settings.themeSongsEnabled' => 'গান খেলতে থেম',
			'settings.themeSongsEnabledDescription' => 'মিডিয়া ডেটা দেখার সময় উপলব্ধ থিম গান খেলুন।',
			'settings.themeSongVolume' => 'Song Volume গান',
			'settings.videoPlayback' => 'ভিডিও Playback',
			'settings.videoPlaybackDescription' => 'Playback অনুভূতি নির্ধারণ করুন',
			'settings.advanced' => 'উন্নত',
			'settings.episodePosterMode' => 'পোস্টার স্টাইল',
			'settings.seriesPoster' => 'সিরিজ পোস্টার',
			'settings.seasonPoster' => 'সপ্তাহের পোস্টার',
			'settings.episodeThumbnail' => 'টম্বা',
			'settings.showHeroSectionDescription' => 'বাড়ি স্ক্রিনে ক্যারুসেল প্রদর্শন',
			'settings.secondsLabel' => 'সেকেন্ড',
			'settings.minutesLabel' => 'মিনিট',
			'settings.secondsShort' => 'স',
			'settings.minutesShort' => 'ম',
			'settings.durationHint' => ({required Object min, required Object max}) => 'একটি মূল্য লিখুন (${min}-${max})',
			'settings.systemTheme' => 'সিস্টেম',
			'settings.lightTheme' => 'আলো',
			'settings.darkTheme' => 'অন্ধকার',
			'settings.oledTheme' => 'OLED',
			'settings.emberTheme' => 'মানুষ',
			'settings.glacierTheme' => 'গ্রীষ্ম',
			'settings.forestTheme' => 'গাছ',
			'settings.plumTheme' => 'প্লাম',
			'settings.paperTheme' => 'কাবার',
			'settings.libraryDensity' => 'লাইব্রেরি গভীরতা',
			'settings.displayScale' => 'ডিজেল স্কুল',
			'settings.compact' => 'কম্প্যাক্ট',
			'settings.comfortable' => 'সুবিধা',
			'settings.gridSpacing' => 'গ্রিড স্পেসিং',
			'settings.gridSpacingTight' => 'টাইট',
			'settings.gridSpacingNormal' => 'স্বাভাবিক',
			'settings.gridSpacingSpacious' => 'জায়গা',
			'settings.tvCornerSpotlightBackdrop' => 'কোরন স্পটলাইট ফ্যাকেট',
			'settings.tvCornerSpotlightBackdropDescription' => 'স্ক্রিন পূরণের পরিবর্তে সঠিক দিকে চিত্রকর্ম প্রদর্শন',
			'settings.viewMode' => 'মডিও দেখুন',
			'settings.gridView' => 'গ্রিড',
			'settings.listView' => 'তালিকা',
			'settings.showHeroSection' => 'হেরো বিভাগ দেখুন',
			'settings.showHomeBackdrop' => 'Home Backdrop শিল্প প্রদর্শন',
			'settings.showHomeBackdropDescription' => 'বাড়ির পিছনে বড় শিল্পকর্ম দেখুন',
			'settings.contentScreensaverEnabled' => 'স্ক্রিন সার্ভার',
			'settings.contentScreensaverEnabledDescription' => 'অ্যাপটি অদ্ভুত হয়ে গেল পরে পুরো স্ক্রিনের শিল্প কাজ দেখুন',
			'settings.contentScreensaverDelay' => 'স্ক্রিন সার্ভার শুরু',
			'settings.contentScreensaverLibraries' => 'স্ক্রেনসভার লাইব্রেরি',
			'settings.contentScreensaverLibrariesDescription' => 'কোন লাইব্রেরি স্ক্রিন সার্ভার শিল্পকর্ম সরবরাহ করে তা নির্বাচন করুন. যদি কোনটি নির্বাচন করা হয় না, তাহলে সব লাইব্রেরি থেকে শিল্পকর্ম ব্যবহার করা হয়।',
			'settings.contentScreensaverAllLibraries' => 'সব লাইব্রেরি',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} বিবেকগুলি নির্বাচিত',
			'settings.contentScreensaverNoLibraries' => 'কোন সংযুক্ত মিডিয়া লাইব্রেরি পাওয়া যায় না।',
			'settings.contentScreensaverDismissHint' => 'কোনও বোতাম বা বাতিল করতে চাপ করুন',
			'settings.newEpisodeNotifications' => 'নতুন পরিস্থিতি বিজ্ঞাপন',
			'settings.newEpisodeNotificationsDescription' => 'একটি প্রদর্শনে একটি নতুন প্রদর্শন যোগ করা হলে সতর্ক করুন আপনি একটি প্রদর্শন পেয়েছেন. সতর্ক করুন যখন Plezy খোলা হয়.',
			'settings.continueWatchingRowSize' => 'Continue reading রানী আকার দেখুন',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => '${label} কার্ড',
			'settings.rowSizeCompact' => 'কম্প্যাক্ট',
			'settings.rowSizeStandard' => 'স্ট্যান্ডার্ড',
			'settings.rowSizeLarge' => 'বড়',
			'settings.continueWatchingAction' => 'চলুন আক্রমণ দেখুন',
			'settings.continueWatchingPlay' => 'খেলা',
			'settings.continueWatchingDetails' => 'খোলা Details',
			'settings.episodeAction' => 'আক্রমণ আক্রমণ',
			'settings.episodePlay' => 'খেলা',
			'settings.episodeDetails' => 'খোলা Details',
			'settings.useGlobalHubs' => 'Home Layout ব্যবহার করুন',
			'settings.useGlobalHubsDescription' => 'একমাত্র হোম হাবগুলি দেখুন. অন্যথায় লাইব্রেরি পরামর্শগুলি ব্যবহার করুন।',
			'settings.showServerNameOnHubs' => 'সার্ভার নাম দেখুন Hubs',
			'settings.showServerNameOnHubsDescription' => 'সবসময় হাব টাইমগুলিতে সার্ভার নামগুলি প্রদর্শন করুন।',
			'settings.groupLibrariesByServer' => 'সার্ভার দ্বারা গ্রুপ লাইব্রেরি',
			'settings.groupLibrariesByServerDescription' => 'প্রতিটি মিডিয়া সার্ভারে গ্রুপ পৃষ্ঠা লাইব্রেরি।',
			'settings.alwaysKeepSidebarOpen' => 'সবসময় সাইডবার্ক খোলা রাখুন',
			'settings.alwaysKeepSidebarOpenDescription' => 'সাইডবার্ক বিস্তারিত থাকবে এবং সামগ্রী এলাকায় সংশোধন করা হবে',
			'settings.showUnwatchedCount' => 'দেখুন অদৃশ্যক কন্টেন্ট',
			'settings.showUnwatchedCountDescription' => 'প্রদর্শন অবিশ্বাসিত আয়াতগুলি প্রদর্শন এবং সপ্তাহগুলিতে সংখ্যা',
			'settings.showWatchedIndicators' => 'দেখে দেখে দেখে দেখে দেখে দেখে',
			'settings.showWatchedIndicatorsDescription' => 'দেখুন দেখানো চলচ্চিত্র, প্রদর্শন এবং epizodes উপর একটি চেকমার্ক',
			'settings.showEpisodeNumberOnCards' => 'কার্ডের উপর Episode Number প্রদর্শন',
			'settings.showEpisodeNumberOnCardsDescription' => 'প্রদর্শন সপ্তাহ এবং আঞ্চলিক সংখ্যা আঞ্চলিক কার্ডে',
			'settings.showSeasonPostersOnTabs' => 'ট্যাবের উপর সপ্তাহের পোস্টার দেখুন',
			'settings.showSeasonPostersOnTabsDescription' => 'প্রতিটি সপ্তাহের পোস্টার তার ট্যাগের উপর দেখুন',
			'settings.tvFullCardLayout' => 'Full টেলিভিশন কার্ড',
			'settings.tvFullCardLayoutDescription' => 'অভিনেতা নামের সাথে ছবি-মাত্র টেলিভিশন কার্ড ব্যবহার করুন',
			'settings.focusGlow' => 'ফোকাস Glow',
			'settings.focusGlowDescription' => 'ফোর্সিং কার্ডের চারপাশে একটি মধুর আলো ড্রাইভ করুন',
			'settings.visualEffects' => 'ভিসুয়াল প্রভাব',
			'settings.visualEffectsAuto' => 'অটো',
			'settings.visualEffectsAutoDescription' => 'কম ক্ষমতার ডিভাইসগুলিতে স্বয়ংক্রিয়ভাবে প্রভাব কমাতে',
			'settings.visualEffectsFull' => 'পূর্ণ',
			'settings.visualEffectsReduced' => 'কমেছে',
			'settings.visualEffectsReducedDescription' => 'কম অ্যানিমেশন এবং কম সনাক্ততা শিল্প কাজ',
			'settings.hideSpoilers' => 'অবিশ্বাস্য অ্যাপিজডের জন্য স্পাইলার লুকানো',
			'settings.hideSpoilersDescription' => 'Blur টম্বালাল এবং অদৃশ্যক epizodes জন্য বর্ণনা',
			'settings.playerBackend' => 'খেলোয়াড় Backend',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'হার্ডওয়ার্ক ডকোডিং',
			'settings.hardwareDecodingDescription' => 'যখন উপলব্ধ হয় তখন হার্ডওয়্যার দ্রুততা ব্যবহার করুন',
			'settings.playbackBuffer' => 'Playback বাফার',
			'settings.playbackBufferAuto' => 'গাড়ি (প্রদর্শিত )',
			'settings.playbackBufferLarge' => 'বড়',
			'settings.playbackBufferExtraLarge' => 'সবচেয়ে বড়',
			'settings.playbackBufferDescription' => 'অবিশ্বাস্য সংযোগের বিরুদ্ধে আরো বউফার. এছাড়াও বউফার আকার দ্বারা সীমিত।',
			'settings.streamBufferSize' => 'বাফার আকার',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} মবি',
			'settings.streamBufferSizeDescription' => 'কত ভিডিও সরাসরি খেলতে আগ্রহে লোড করতে হবে. সার্ভারের নিজস্ব ট্রান্সকোড বাফারে ট্রান্সকোড বন্ধ করে।',
			'settings.streamBufferSizeExoNote' => 'Playback বাফার পরিবর্তন করে, অ্যাপের মেমরি সীমাবদ্ধির অর্ধেকে ক্যাপিত',
			'settings.streamBufferMegabytes' => 'মেগাবাইট',
			'settings.defaultQualityTitle' => 'ভুল মান',
			'settings.cellularQualityTitle' => 'সেলের মানের ভুল',
			'settings.remoteQualityTitle' => 'দূরবর্তী স্রিমিং মান',
			'settings.remoteQualitySameAsDefault' => 'ডিফল্ট মানের মতোই',
			'settings.cellularQualitySameAsDefault' => 'ডিফল্ট মানের মতোই',
			'settings.directPlayCoveredQuality' => 'মূল মানে ছোট ভিডিও খেলুন',
			'settings.directPlayCoveredQualityDescription' => 'সরাসরি ভিডিওগুলি সরাসরি কডিং করার পরিবর্তে মানের সীমাবদ্ধির ভেতরে ইতিমধ্যে খেলা',
			'settings.videoCodecs' => 'ভিডিও কোডেক',
			'settings.videoCodecsDescription' => 'সার্ভার দ্বারা অচেক করা কোডেকগুলি ট্রান্সকড করা হয়',
			'settings.videoCodecsAlwaysAccepted' => 'সবসময় গ্রহণ',
			'settings.musicQualityTitle' => 'গানের মান',
			'settings.subtitleStyling' => 'Subtitle স্টাইলিং',
			'settings.subtitleStylingDescription' => 'Subtitle অনুভূতি অনুভূতি',
			'settings.smallSkipDuration' => 'ছোট স্কিপ দীর্ঘদিন',
			'settings.largeSkipDuration' => 'দীর্ঘ স্কাইপ',
			'settings.rewindOnResume' => 'সুনির্দিষ্ট সমাধান',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(seconds, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} সেকেন্ড', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} সেকেন্ড', ), 
			'settings.defaultSleepTimer' => 'ডিফল্ট ঘুম টাইম',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(minutes, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} মিনিট', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} মিনিট', ), 
			'settings.rememberTrackSelections' => 'সিনেমা / সিনেমা / সিনেমা / সিনেমা / সিনেমা',
			'settings.chooseTracksBeforePlayback' => 'Playback এর আগে অডিও এবং সাব্টিটিস নির্বাচন করুন',
			'settings.chooseTracksBeforePlaybackDescription' => 'প্রত্যেক ভিডিও শুরু করার আগে উৎস অডিও এবং সাব্টিট ট্র্যাক নির্বাচন করুন।',
			'settings.alwaysShowSubtitlesOnDevice' => 'সবসময় এই ডিভাইসের উপর সাব্টিটি প্রদর্শন করুন',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => 'যখন সার্ভারের কোন সাব্টিটি নির্বাচন করা হয় না, তখন স্থানীয়ভাবে একটি পাসপোর্ট নির্বাচন করুন. এই কখনো সার্ভারের প্রিয়তা পরিবর্তন করে না।',
			'settings.autoDownloadPreferredSubtitle' => 'পছন্দের ভাষা-পছন্দের ভাষা-পছন্দের ভাষা',
			'settings.autoDownloadPreferredSubtitleDescription' => 'আপনার প্রিয় ভাষায় স্থানীয়ভাবে একটি উপ-টাইটিল নির্বাচন করুন. যদি কোনটি নেই, তাহলে সার্ভারকে সমর্থিত হলে একটি ফিট করার জন্য অনুরোধ করুন. নির্বাচন এই ডিভাইসে থাকবে.',
			'settings.rememberTrackSelectionsDescription' => 'এই ডিভাইসে সিনেমা বা প্রদর্শন দ্বারা অডিও এবং সাবট্রেট নির্বাচন সংরক্ষণ করুন',
			'settings.rememberTrackSelectionsBackendRule' => 'স্থানীয়ভাবে Plex, Jellyfin, এবং Emby; Plex এবং Jellyfin এর সাথে কাজ করে, সার্ভারে নির্বাচন সংরক্ষণ করতে পারেন',
			'settings.followServerTrackSelections' => 'সার্ভারের পৃথিবীর পৃথিবীর পৃথিবীর পৃথিবীর পৃথিবীর পৃথিবীর পছন্দ',
			'settings.followServerTrackSelectionsDescription' => 'epizode change এরপর, সার্ভার উপর নির্বাচিত অডিও এবং সাবটাইটলগুলি প্রয়োগ করুন, বর্তমান পছন্দের উপর বহন করার পরিবর্তে',
			'settings.resumeMusicOnLaunch' => 'সিনেমা সিনেমা সিনেমা',
			'settings.resumeMusicOnLaunchDescription' => 'শেষ গানটি পুনরায় খোলা যায় যেখানে এটি অ্যাপটি শুরু করার সময় বন্ধ হয়ে যায়',
			'settings.showChapterMarkersOnTimeline' => 'পৃথিবী পৃথিবী পৃথিবী পৃথিবী পৃথিবী পৃথিবী পৃথিবী পৃথিবী',
			'settings.showChapterMarkersOnTimelineDescription' => 'চিঠির সীমানাগুলিতে চিঠির সীমানাগুলিতে চিঠির সীমানা',
			'settings.specialsOrdering' => 'আয়াত আদেশে বিশেষ',
			'settings.specialsOrderingDescription' => 'কোথায় বিশেষ খেলছে একটি প্রদর্শনের ঘড়ি আদেশে',
			'settings.specialsOrderingServer' => 'সার্ভার আদেশ অনুসরণ',
			'settings.specialsOrderingAirDate' => 'বিমানের ডেটা অনুযায়ী',
			'settings.specialsOrderingLast' => 'নিয়মিত পরিস্থিতিতে',
			'settings.clickVideoTogglesPlayback' => 'ভিডিও ক্লিক করুন খেলতে / পাস করতে',
			'settings.clickVideoTogglesPlaybackDescription' => 'ভিডিওটি ক্লিক করুন/পাস করার পরিবর্তে নিয়ন্ত্রণ দেখান।',
			'settings.videoPlayerControls' => 'ভিডিও খেলোয়াড় নিয়ন্ত্রণ',
			'settings.keyboardShortcuts' => 'ট্যাবলেট Shortcuts',
			'settings.keyboardShortcutsDescription' => 'কাস্টমাইজ করুন ট্যাবলেট কুরআন',
			'settings.videoPlayerNavigation' => 'ভিডিও খেলোয়াড় নৌকা',
			'settings.videoPlayerNavigationDescription' => 'ভিডিও খেলোয়াড় নিয়ন্ত্রনগুলি নৌকা করার জন্য প্লাইট ক্লিক ব্যবহার করুন',
			'settings.watchTogetherRelay' => 'একসাথে রেলি দেখুন',
			'settings.watchTogetherRelayDescription' => 'খোলা খোলা খোলা খোলা খোলা খোলা খোলা খোলা খোলা খোলা খোলা',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.watchTogetherRelayInvalid' => 'রিলের জন্য একটি বৈধ HTTP বা HTTPS বেস URL লিখুন।',
			'settings.crashReporting' => 'দুর্ঘটনা রিপোর্ট',
			'settings.crashReportingDescription' => 'অ্যাপটি উন্নত করতে সাহায্য করার জন্য দুর্ঘটনা রিপোর্ট পাঠান',
			'settings.debugLogging' => 'ডেবুগ লগিং',
			'settings.debugLoggingDescription' => 'সমস্যা সমাধানের জন্য বিস্তারিত লগিং সক্ষম',
			'settings.viewLogs' => 'দেখুন লগ',
			'settings.viewLogsDescription' => 'প্রোগ্রামের লগ দেখুন',
			'settings.clearImageCache' => 'সঠিক ছবি Cache',
			'settings.clearImageCacheDescription' => 'চিহ্নিত ক্যাচিং শিল্প এবং ছোট ছবির. ছবিগুলি আবার ডাউনলোড করা পর্যন্ত দ্রুত লোড করা যেতে পারে।',
			'settings.clearImageCacheSuccess' => 'Image Cache সফলভাবে পরিষ্কার',
			'settings.resetSettings' => 'পুনরাবৃত্তি Settings',
			'settings.resetSettingsDescription' => 'ডিফল্ট সিস্টেমগুলি পুনরায় রাখুন. এটি অস্বীকার করা যাবে না।',
			'settings.resetSettingsSuccess' => 'সফলভাবে পুনরাবৃত্তি',
			'settings.backup' => 'সাবস্ক্রিপ',
			'settings.exportSettings' => 'বিতরণের পরিসংখ্যান',
			'settings.exportSettingsDescription' => 'একটি ফাইলের জন্য আপনার পছন্দ সংরক্ষণ করুন',
			'settings.exportSettingsSuccess' => 'নির্দেশনা বিতরণ',
			'settings.importSettings' => 'Import Settings প্রদর্শন',
			'settings.importSettingsDescription' => 'একটি ফাইল থেকে পছন্দ ফেরত',
			'settings.importSettingsConfirm' => 'এটাই আপনাকে বর্তমান পরামর্শগুলি বদলে দেবে।',
			'settings.importSettingsSuccess' => 'আউটডোজ করা',
			'settings.importSettingsInvalidFile' => 'এই ফাইলটি একটি সঠিক PlezyNG সেটিংগুলি অ্যাক্সেস নয়',
			'settings.importSettingsNoUser' => 'প্রদর্শন করার আগে সাইন করুন',
			'settings.cloudBackup' => 'ক্লাউড সার্ভিস',
			'settings.cloudBackupDescription' => 'HTTPS-এর মাধ্যমে WebDAV ঠিকানায় বহনযোগ্য সেটিংসের ব্যাকআপ রাখুন। সার্ভার সংযোগ ও শংসাপত্র এই ডিভাইসেই থাকবে।',
			'settings.cloudBackupUrl' => 'WebDAV JSON ফাইল URL',
			'settings.cloudBackupUsername' => 'ব্যবহারকারী নাম',
			'settings.cloudBackupPassword' => 'পাসওয়ার্ড',
			'settings.cloudBackupSaved' => 'Cloud Backup ডিজিটাল সংরক্ষিত',
			'settings.cloudBackupNow' => 'ফিরে আসুন এখন',
			'settings.cloudBackupComplete' => 'আপলোড করা Backup Settings',
			'settings.cloudBackupRestore' => 'Backup পুনরাবৃত্তি',
			'settings.cloudBackupRestoreConfirm' => 'এই ডিভাইসের পোর্টেবল সিস্টেমগুলি সমাধান করবে. চলুন?',
			'settings.cloudBackupRestored' => 'Cloud Backup থেকে পুনরাবৃত্তি',
			'settings.shortcutsReset' => 'দূতাবাসের জন্য দূতাবাস ফিরে আসুন',
			'settings.resetShortcutsConfirm' => 'এটি আপনার কাস্টম কুরআনগুলি ভিত্তিতে বদলে দেবে।',
			'settings.about' => 'সম্পর্কে',
			'settings.aboutDescription' => 'অ্যাপ তথ্য এবং লাইসেন্স',
			'settings.updates' => 'আপডেট',
			'settings.updateAvailable' => 'আপডেট পাওয়া যায়',
			'settings.checkForUpdates' => 'আপডেট দেখুন',
			'settings.autoCheckUpdatesOnStartup' => 'Startup এর আপডেটগুলি স্বয়ংক্রিয়ভাবে চেক করুন',
			'settings.autoCheckUpdatesOnStartupDescription' => 'আপডেট চালু করার সময় আপডেট পাওয়া যাবে',
			'settings.validationErrorEnterNumber' => 'দয়া করে একটি সঠিক নম্বর প্রদান করুন',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => '${min} এবং ${max} ${unit} এর মধ্যে থাকতে হবে।',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'এখনও ${action} এর জন্য নির্দিষ্ট কুরআন',
			'settings.shortcutUpdated' => ({required Object action}) => 'ছোট ছোট আপডেট ${action}',
			'settings.saveFailed' => 'পরিবর্তন করতে পারবেন না, আবার চেষ্টা করুন।',
			'settings.autoPlayAndSkip' => 'অটো-প্লে & স্কিপ',
			'settings.autoPlayNextEpisode' => 'Auto-Play পরবর্তী প্রজেক্ট',
			'settings.autoPlayNextEpisodeDescription' => 'পরবর্তী অধ্যায়টি স্বয়ংক্রিয়ভাবে শুরু করে যখন একটি শেষ হয়',
			'settings.shuffleStartsFromBeginning' => 'শফল শুরু করে',
			'settings.shuffleStartsFromBeginningDescription' => 'প্রতিটি অধ্যায় শুরু করার পরিবর্তে শুরু করার সময় শুরু করুন।',
			'settings.plexCinemaPreRoll' => 'সার্ভার সিনেমা ইনট্রো ব্যবহার করুন',
			'settings.plexCinemaPreRollDescription' => 'একটি চলচ্চিত্র শুরু করার আগে Plex প্রেরো-রল বা Jellyfin এবং Emby প্রেরো-রল সংগঠিত খেলুন।',
			'settings.playNextCountdown' => 'পরবর্তী কন্টডাউন খেলা',
			'settings.playNextCountdownImmediate' => 'তাড়াতাড়ি খেলুন',
			'settings.skipIntroMode' => 'সিন্ট্রো',
			'settings.skipIntroModeOffDescription' => 'খেলুন অভিনেতা সাধারণত একটি স্কাইপ বোতাম ছাড়া',
			'settings.skipIntroModeButtonDescription' => 'প্রদর্শন করুন একটি স্কাইপ বোতাম যখন একটি intro শুরু হয়',
			'settings.skipIntroModeAutoDescription' => 'নীচের দেরি পরে স্বয়ংক্রিয়ভাবে ইনস্ট্রুস স্কিপ করুন',
			'settings.skipCreditsMode' => 'ক্রেডিট স্কাইপ',
			'settings.skipCreditsModeOffDescription' => 'ক্রেডিট খেলুন স্বাভাবিকভাবে একটি স্কাইপ বোতাম ছাড়া',
			'settings.skipCreditsModeButtonDescription' => 'ক্রেডিট শুরু করার সময় একটি স্কাইপ বোতাম দেখুন',
			'settings.skipCreditsModeAutoDescription' => 'ক্রেডিটগুলি স্বয়ংক্রিয়ভাবে বের করুন এবং পরবর্তী অধ্যায় খেলুন',
			'settings.skipAdsMode' => 'হাঁটান Ads',
			'settings.skipAdsModeOffDescription' => 'একটি স্কাইপ বোতাম ছাড়া স্বাভাবিকভাবে প্রদর্শিত বিজ্ঞাপন খেলুন',
			'settings.skipAdsModeButtonDescription' => 'একটি বিজ্ঞাপন দেখান যখন Plex একটি বিজ্ঞাপন দেখান',
			'settings.skipAdsModeAutoDescription' => 'নিচের দুর্বলতা পরে স্বয়ংক্রিয়ভাবে প্রদর্শন করা বিজ্ঞাপনগুলি বের করুন',
			'settings.musicPlayback' => 'গান Playback',
			'settings.musicSweetFades' => 'সুতরাং ফ্যাড',
			'settings.musicSweetFadesDescription' => 'ফ্যাড সঙ্গীত ট্র্যাক এগিয়ে যখন Plex এর শব্দ ডেটা আছে।',
			'settings.skipMarkerModeOff' => 'বন্ধ',
			'settings.skipMarkerModeButton' => 'বোতাম দেখুন',
			'settings.skipMarkerModeAuto' => 'স্বয়ংক্রিয়',
			'settings.forceSkipMarkerFallback' => 'ফ্যালব্যাক মার্কেট',
			'settings.forceSkipMarkerFallbackDescription' => 'পৃথিবীর টাইম প্যাটার্ন ব্যবহার করুন, এমনকি যদি Plex প্যাকেজ আছে',
			'settings.theIntroDbFallback' => 'intro fallback হিসাবে ব্যবহার করুন',
			'settings.theIntroDbFallbackDescription' => 'সম্প্রদায় সময়সীমাগুলি শুধুমাত্র ব্যবহার করুন যখন সার্ভারে intro markers নেই. Matchs can vary by release.',
			'settings.autoSkipDelay' => 'গাড়ি দেরি',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'অপেক্ষা করুন ${seconds} সেকেন্ড আগে গাড়ি-সিকপিং',
			'settings.introPattern' => 'ইন্ট্রো মার্কেট প্যাটার্ন',
			'settings.introPatternDescription' => 'Regex মডেল চিঠির টাইমগুলিতে intro markers সঙ্গে জড়িত',
			'settings.creditsPattern' => 'ক্রেডিট মার্কেট প্যাটার্ন',
			'settings.creditsPatternDescription' => 'ক্যাপ্টার টাইমগুলিতে ক্রেডিট ম্যাকারগুলি ম্যাকার করার জন্য Regex প্যাটার্ন',
			'settings.prerolls' => 'পূর্বাভাস',
			'settings.playPrerollsBeforeMovies' => 'চলচ্চিত্রের আগে প্রেরোল খেলুন',
			'settings.playPrerollsBeforeMoviesDescription' => 'প্রতিটি চলচ্চিত্রের আগে আপনার নিচের নির্বাচন থেকে একটি random ক্লিপ খেলুন।',
			'settings.prerollLibrary' => 'প্রেরোল লাইব্রেরি',
			'settings.prerollLibraryNotSet' => 'সিস্টেম না',
			'settings.prerollLibraryNoneFound' => 'আপনার সার্ভারগুলিতে কোন লাইব্রেরি পাওয়া যায় না।',
			'settings.prerollSelection' => 'নির্বাচিত প্রেরোল',
			'settings.prerollSelectionPickLibraryFirst' => 'প্রথমে একটি লাইব্রেরি নির্বাচন করুন',
			'settings.prerollSelectionNoneSelected' => 'কোন প্রেরোল নির্বাচন হয় না',
			'settings.prerollSelectionCount' => ({required Object count}) => '${count} নির্বাচিত',
			'settings.prerollItemPicker' => 'প্রেরোলস নির্বাচন',
			'settings.prerollItemPickerLoadFailed' => 'এই লাইব্রেরি থেকে পণ্য লোড করতে পারেনি।',
			'settings.invalidRegex' => 'নিয়মিত বক্তব্যের অভাব',
			'settings.regex' => 'নিয়মিত বক্তব্য',
			'settings.downloads' => 'ডাউনলোড',
			'settings.downloadLocationDescription' => 'ডাউনলোড করা বিষয়বস্তু সংরক্ষণ করার কোথায় নির্বাচন করুন',
			'settings.downloadLocationDefault' => 'অ্যাপ স্টোরেজ (App Storage)',
			'settings.downloadLocationCustom' => 'কাস্টম অবস্থান',
			'settings.selectFolder' => 'ফোল্ডার নির্বাচন',
			'settings.resetToDefault' => 'ডিফল্টে ফিরে আসুন',
			'settings.currentPath' => ({required Object path}) => 'বর্তমান: ${path}',
			'settings.downloadLocationChanged' => 'ডাউনলোড স্থান পরিবর্তন',
			'settings.downloadLocationReset' => 'ডাউনলোড করুন অবস্থান reset to default',
			'settings.downloadLocationInvalid' => 'নির্বাচিত ফোলার লিখতে পারে না',
			'settings.downloadLocationPickerUnavailable' => 'ফোল্ডার নির্বাচন এই ডিভাইসে পাওয়া যায় না',
			'settings.downloadOnWifiOnly' => 'ডাউনলোড করুন Wi-Fi কেবল',
			'settings.downloadOnWifiOnlyDescription' => 'মোবাইল ডেটাতে ডাউনলোড বন্ধ করুন',
			'settings.autoRemoveWatchedDownloads' => 'Auto-Remove দেখানো ডাউনলোড',
			'settings.autoRemoveWatchedDownloadsDescription' => 'স্বয়ংক্রিয়ভাবে দেখানো ডাউনলোড মুছে ফেলুন',
			'settings.autoDownloadContinueWatching' => 'Auto-Download চলুন দেখুন',
			'settings.autoDownloadContinueWatchingDescription' => 'আপনার Continue Watch শিলিং পণ্যগুলি ডাউনলোড করে রাখুন এবং তারা শিলিং থেকে বের হওয়ার পরে তাদের মুছে ফেলুন',
			'settings.downloadQuality' => 'ডাউনলোড মান',
			'settings.downloadQualityDescription' => 'Plex তার ডাউনলোড কোডে একটি পরিদর্শন কপি তৈরি করে. Jellyfin এবং Emby ফাইল ডাউনলোড করার সময় ট্রান্সকোড; বন্ধ ট্রান্সকোডগুলি পুনরায় চালু করতে হবে।',
			'settings.askDownloadQualityEachTime' => 'প্রতিটি ডাউনলোডের জন্য মানের নির্বাচন করুন',
			'settings.askDownloadQualityEachTimeDescription' => 'প্রতিটি ভিডিও ডাউনলোড করার আগে মান পিকার দেখুন',
			'settings.cellularDownloadBlocked' => 'ডাউনলোডগুলি সেলের উপর ব্লক করা হয়. Wi-Fi ব্যবহার করুন বা সিস্টেম পরিবর্তন করুন.',
			'settings.maxVolume' => 'সর্বোচ্চ শব্দের মাত্রা',
			'settings.maxVolumeDescription' => 'কম শব্দের মিডিয়ার জন্য শব্দের মাত্রা 100%-এর বেশি বাড়ানোর অনুমতি দিন',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'ধনী উপস্থিতি',
			'settings.discordRichPresenceDescription' => 'দেখুন আপনি কি দেখছেন Discord',
			'settings.services' => 'পরিষেবা',
			'settings.servicesDescription' => 'সংযোগ Trakt, MyAnimeList, Seerr, এবং আরও',
			'settings.manageLibrariesDescription' => 'লাইব্রেরি রেকর্ড করুন এবং লুকিয়ে রাখুন',
			'settings.companionRemoteServer' => 'Remote সার্ভার',
			'settings.companionRemoteServerDescription' => 'আপনার নেটওয়ার্কের মোবাইল ডিভাইসগুলি এই অ্যাপটি নিয়ন্ত্রণ করার অনুমতি দেয়',
			'settings.companionRemoteServerStartFailed' => 'সার্ভার সার্ভার শুরু করতে পারেনি।',
			'settings.companionRemoteServerStopFailed' => 'সার্ভার বন্ধ করতে পারত না।',
			'settings.autoPip' => 'Auto Picture-in-Picture গাড়ি',
			'settings.autoPipDescription' => 'আপনি Playback সময় অ্যাপটি ছেড়ে যখন স্বয়ংক্রিয়ভাবে ছবি-এ-ফটো প্রবেশ করুন',
			'settings.matchContentFrameRate' => 'ফ্রেম ফ্রেম ফ্রেম ফ্রেম ফ্রেম',
			'settings.matchContentFrameRateDescription' => 'ভিডিও প্রদর্শন ফ্রেসিং রেস্টুরেন্ট ফ্রেসিং রেস্টুরেন্ট',
			'settings.matchContentResolution' => 'Match Content সংশ্লিষ্ট',
			'settings.matchContentResolutionDescription' => 'ভিডিওটির স্বাগত রেজিউশনে ডিভাইস পরিবর্তন করুন ताकि আপনার টিভি উপসকালিং কাজ করে।',
			'settings.matchRefreshRate' => 'ফ্রিজ ফ্রিজ ফ্রিজ',
			'settings.matchRefreshRateDescription' => 'পুরো স্ক্রিনে ফ্রিজ ফ্রিজ ফ্রিজ ফ্রিজ ফ্রিজ',
			'settings.matchDynamicRange' => 'জায়গা জায়গা জায়গা',
			'settings.matchDynamicRangeDescription' => 'HDR-এর জন্য ডাউনলোড করুন, তারপর SDR-এর জন্য ফিরে আসুন',
			'settings.displaySwitchDelay' => 'ডাউনলোড সুইচ দেরি',
			'settings.tunneledPlayback' => 'টনেল Playback',
			'settings.tunneledPlaybackDescription' => 'ভিডিও টুনেলিং ব্যবহার করুন. HDR প্লাইবক কালো ভিডিও বা মোট স্টুটার প্রদর্শন করে যদি অ্যাক্সেস করা হয়.',
			'settings.audioPassthrough' => 'অডিও পাস্ট্রোগ',
			'settings.audioPassthroughDescription' => 'ডলবি / ডিটিএস অডিও আপনার রিপোর্টার বা টেলিভিশনে রেকর্ডিং ছাড়া পাঠান, পরিবেশের শব্দ সংরক্ষণ করুন. শব্দ না হলে বন্ধ করুন.',
			'settings.audioPassthroughDescriptionApple' => 'Atmos সহ Dolby Digital Plus-এর জন্য Apple-এর নিজস্ব Dolby ডিকোডার ব্যবহার করুন। DTS ও TrueHD মাল্টিচ্যানেল PCM হিসেবেই চলবে। শব্দ না শুনলে এটি বন্ধ করুন।',
			'settings.audioPassthroughDescriptionAppleSpatial' => 'ডলবি ডিজিটাল প্লাস জন্য Apple এর প্রাকৃতিক ডলবি ডকোডার ব্যবহার করুন, অথবা Atmos. iOS, iPadOS এবং tvOS 26 বা তারপর, TrueHD Atmos এবং DTS:X স্পেশাল অডিও হিসাবে খেলতে হবে. অন্যান্য DTS এবং TrueHD ট্র্যাক multichannel PCM হিসাবে খেলতে হবে. আপনি কোন শব্দ না থাকলে বন্ধ করুন.',
			'settings.audioPassthroughOverriddenByNormalization' => 'যদিও শব্দের স্বাভাবিকতা থাকে, তখন',
			'settings.audioChannelLimit' => 'অডিও চ্যানেল',
			'settings.audioChannelLimitDescription' => 'ডাউনলোড করা অডিও মিশ্র করুন শব্দ, হোডফোন, বা HDMI সেটপগুলিতে যা কোনও চ্যানেল খেলতে পারে না',
			'settings.audioChannelLimitOriginal' => 'মূল',
			'settings.audioChannelLimitOriginalDescription' => 'প্রতিটি চ্যানেলটি ট্র্যাকে খেলুন',
			'settings.audioChannelLimitSurround51' => '5.1 পর্যন্ত',
			'settings.audioChannelLimitSurround51Description' => 'মিশ্র 7.1 থেকে 5.1 পর্যন্ত টেলিভিশন এবং রেকর্ডারগুলির জন্য যারা কেবল 5.1 PCM গ্রহণ করে।',
			'settings.audioChannelLimitStereo' => 'স্টেরিও',
			'settings.audioChannelLimitStereoDescription' => 'স্টেরিও শব্দক বা হোডফোনের জন্য দুটি চ্যানেলের মধ্যে মিশ্রণ করুন।',
			'settings.downmixCenterBoost' => 'চ্যানেল বোস্ট',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} ডিবি',
			'settings.downmixCenterBoostLabel' => 'ডিপি (ডিপি )',
			'settings.downmixCenterBoostShort' => 'ডিবি',
			'settings.audioDownmixNormalize' => 'ডাউন মিক্সিকায় ভোল্টুম স্বাভাবিক করুন',
			'settings.audioDownmixNormalizeDescription' => 'ক্লাইপিং বন্ধ করার জন্য মিশ্রণটি নিচে রাখুন. মূল টুমেন্ট রাখতে বন্ধ করুন (হয়তততততততততততততততততততততততততততততততততততত।',
			'settings.dvConversionMode' => 'Dolby Vision সংকট',
			'settings.dvConversionModeDescription' => 'Dolby Vision প্রোফাইল 7 ফাইলগুলি কীভাবে পরিচালিত হয় তা নির্বাচন করুন।',
			'settings.dvConversionAuto' => 'অটো',
			'settings.dvConversionNative' => 'অভ্যন্তরীণ / অভ্যন্তরীণ',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'ডিভাইস ক্ষমতা ডেটাং এবং স্বাভাবিক Fallback আচরণ ব্যবহার',
			'settings.dvConversionNativeDescription' => 'শক্তি প্রাকৃতিক DV7 এবং ডিভি পরিদর্শন রিট্রি প্রত্যাহার',
			'settings.dvConversionDv81Description' => 'শক্তি ইনলাইন RPU পৃষ্ঠা Dolby Vision প্রোফাইল 8.1',
			'settings.dvConversionHevcStripDescription' => 'স্ট্রিপ Dolby Vision RPU/EL layers এবং বর্তমান প্লাইন HEVC',
			'settings.experimentalDolbyVision' => 'পরীক্ষামূলক Dolby Vision',
			'settings.experimentalDolbyVisionDescription' => 'পরবর্তী প্লেব্যাকে পরীক্ষামূলক FEL রেন্ডারার ব্যবহার করুন। ইঞ্জিনের আলাদা বিল্ড প্রয়োজন।',
			'settings.dvExperimentUnavailableDescription' => 'এই পরীক্ষা বর্তমানে শুধু Linux-এ উপলব্ধ।',
			'settings.dvCompatibilityFallback' => 'সামঞ্জস্যপূর্ণ বিকল্প',
			'settings.dvCompatibilityFallbackDescription' => 'পরীক্ষা শুরু না হলে সাধারণ রেন্ডারার ব্যবহার করুন। FEL তথ্য হারিয়ে যেতে পারে।',
			'settings.dvExperimentDiagnostics' => 'ভিডিও পরীক্ষার লগ',
			'settings.dvExperimentDiagnosticsDescription' => 'পরবর্তী প্লেব্যাকে প্লেয়ারের বিস্তারিত লগ চালু করুন।',
			'settings.disableDolbyVision' => 'অস্বাভাবিক Dolby Vision',
			'settings.disableDolbyVisionDescription' => 'ফাইলের HDR10 বা HLG স্তরের পরিবর্তে Dolby Vision খেলুন, যখন এটি একটি আছে',
			'settings.hdrSdrConversion' => 'HDR থেকে SDR সংকট',
			'settings.hdrSdrConversionDescription' => 'HDR ভিডিও কনভার্ট করে যা নির্বাচন করুন, যখন ডিভাইস HDR দেখতে পারবে না।',
			_ => null,
		} ?? switch (path) {
			'settings.hdrSdrConversionAuto' => 'অটো',
			'settings.hdrSdrConversionAutoDescription' => 'ডিভাইস Android 9 এবং তারপর, পুরনো সংস্করণগুলিতে খেলা',
			'settings.hdrSdrConversionDevice' => 'ডিভাইস',
			'settings.hdrSdrConversionDeviceDescription' => 'আপনার ডিভাইসের ভিডিও হার্ভিড এটি পরিদর্শন করে. সবচেয়ে দ্রুত, কিন্তু রঙগুলি ডিভাইসের উপর নির্ভর করে',
			'settings.hdrSdrConversionPlayer' => 'প্লেয়ার',
			'settings.hdrSdrConversionPlayerDescription' => 'খেলোয়াড়টি এটি পরিদর্শন করে. সংশ্লিষ্ট রঙ, কিন্তু 4K নিম্ন ফ্যান্ড টেলিভিশন বক্সগুলিতে লড়াই করতে পারে',
			'settings.deinterlace' => 'ডেটিং',
			'settings.deinterlaceDescription' => 'interlaced ভিডিও থেকে সংযুক্ত অ্যাকাউন্ট মুছে ফেলুন (mpv খেলোয়াড় কেবল)',
			'settings.deinterlaceOff' => 'বন্ধ',
			'settings.deinterlaceOffDescription' => 'ডাউনলোড করা হয় যখন এটি ডাউনলোড করা হয়',
			'settings.deinterlaceVideo' => 'ভিডিও',
			'settings.deinterlaceVideoDescription' => 'প্রত্যেক ফ্যাকেটকে একটি সম্পূর্ণ ফ্যাকেটে পরিদর্শন করুন. টিভি জন্য ভিডিও শটের জন্য, যেমন খেলা, সংবাদ, এবং কনসার্ট',
			'settings.deinterlaceFilm' => 'চলচ্চিত্র',
			'settings.deinterlaceFilmDescription' => 'চলচ্চিত্র এবং অ্যানিমেশন এর মূল ফ্রেমগুলি 2.97 fps, NTSC ডিভিডিগুলিতে সাধারণ করে ফিরে আসুন. টিভি স্টুটারদের জন্য ভিডিও ফ্রেম।',
			'settings.requireProfileSelectionOnOpen' => 'অ্যাপটি খোলা প্রোফাইলের জন্য অনুরোধ',
			'settings.requireProfileSelectionOnOpenDescription' => 'প্রোগ্রাম খুললে প্রতিবার প্রোগ্রামের পছন্দ দেখুন',
			'settings.forceTvMode' => 'টেলিভিশন মডেল',
			'settings.forceTvModeDescription' => 'টেলিভিশন সিস্টেম শক্তিশালী. যেসব ডিভাইসগুলি স্বয়ংক্রিয়ভাবে ডেটিং না করে, তাদের জন্য আবার শুরু করতে হবে।',
			'settings.startInFullscreen' => 'পুরো স্ক্রিনে শুরু',
			'settings.startInFullscreenDescription' => 'ফুল স্ক্রিন মোডে PlezyNG খোলা',
			'settings.exitFullscreenOnPlayerClose' => 'খেলোয়াড় বন্ধে Full Screen Exit',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'ভিডিও খেলোয়াড় বন্ধ করার সময় স্বয়ংক্রিয়ভাবে পুরো স্ক্রিন থেকে বের করে',
			'settings.autoHidePerformanceOverlay' => 'অটো-হাইড অ্যাপ্লিকেশন Overlay',
			'settings.autoHidePerformanceOverlayDescription' => 'Playback নিয়ন্ত্রণে অগ্রগতি ফ্যাড করুন',
			'settings.showNavBarLabels' => 'দেখুন ন্যাভাইজেশন বার Labels',
			'settings.showNavBarLabelsDescription' => 'নৌকা প্যার আইকোনগুলির মধ্যে টেক্সট লেগেলগুলি দেখুন',
			'settings.startupSection' => 'Startup বিভাগ',
			'settings.preferredServer' => 'প্রিয় সার্ভার',
			'settings.preferredServerDescription' => 'এই সার্ভারের ফলাফলগুলি মূল্যায়ন করুন, যখন প্রতিটি সংযোগিত সার্ভার উপলব্ধ রাখুন।',
			'settings.preferredServerAutomatic' => 'স্বয়ংক্রিয়',
			'settings.showExploreTab' => 'ট্যাব দেখুন',
			'settings.showExploreTabDescription' => 'আবিষ্কারের প্যাকেটি দেখুন Plex থেকে উপাদান সঙ্গে আবিষ্কার এবং সংযুক্ত ট্র্যাকার',
			'settings.hideEmptyLibraries' => 'ভুল লাইব্রেরি',
			'settings.hideEmptyLibrariesDescription' => 'সার্ভার দ্বারা রিপোর্ট করা পণ্য সংখ্যা সূত্রের সাথে লাইব্রেরিগুলি নৌকা থেকে মুছে ফেলুন।',
			'settings.liveTvDefaultFavorites' => 'প্রিয় চ্যানেলগুলির জন্য ডিফল',
			'settings.liveTvDefaultFavoritesDescription' => 'শুধুমাত্র প্রিয় চ্যানেলগুলি দেখুন Live TV খুলতে',
			'settings.general' => 'সাধারণ',
			'settings.generalDescription' => 'ভাষা, স্টার্টপোর্ট এবং উইন্ডো ভেতর',
			'settings.languageAndRegion' => 'ভাষা ও অঞ্চল',
			'settings.startup' => 'স্টার্টপ',
			'settings.display' => 'ডিসপ্লে',
			'settings.libraryAndCards' => 'লাইব্রেরি & কার্ড',
			'settings.homeScreen' => 'Home স্ক্রিন',
			'settings.navigation' => 'নৌকা',
			'settings.window' => 'উইন্ডোজ',
			'settings.liveTv' => 'লাইভ টিভি',
			'settings.player' => 'প্লেয়ার',
			'settings.videoAndDisplay' => 'ভিডিও & Display',
			'settings.audio' => 'অডিও',
			'settings.quality' => 'মানের',
			'settings.subtitles' => 'সাবটাইটেল',
			'settings.seekAndTiming' => 'সন্ধান & টাইমিং',
			'settings.behavior' => 'আচরণ',
			'settings.gestures' => 'গ্যাস',
			'settings.gestureBrightnessSwipe' => 'সূর্য বিলুপ্ত',
			'settings.gestureBrightnessSwipeDescription' => 'বাম দিকে উড়ে বা নিচে বাইরে বাইরে বাইরে বাইরে বাইরে বাইরে বাইরে বাইরে',
			'settings.gestureVolumeSwipe' => 'পরিমাণ সুইপ',
			'settings.gestureVolumeSwipeDescription' => 'ডান দিকে উড়ে বা নিচের দিকে ঘুরে বের করুন, পরিমাণ সংশোধন করার জন্য',
			'settings.gesturePinchToZoom' => 'পিনচ থেকে Zoom',
			'settings.gesturePinchToZoomDescription' => 'ভিডিওটিতে জুোম করুন বা ফাঁস করুন।',
			'settings.gestureSeekSwipe' => 'সুইপ খুঁজুন',
			'settings.gestureSeekSwipeDescription' => 'ভিডিওটি অনুসন্ধানের কোথাও বাম বা ডান বাইরে বাইরে; ফেরত হাঁটতে',
			'settings.rememberBrightnessLevel' => 'উজ্জ্বলতা তাপমাত্রা',
			'settings.rememberBrightnessLevelDescription' => 'শেষ সুইপ দ্বারা নির্ধারিত উজ্জ্বলতা থেকে playback শুরু করুন',
			'settings.controls' => 'নিয়ন্ত্রণ',
			'settings.rememberPlayerChanges' => 'খেলোয়াড়ের পরিবর্তন',
			'settings.rememberPlayerChangesDescription' => 'যেখানে একটি পরিবর্তন Playback সময় সংরক্ষণ করা হয় এবং আবার প্রয়োগ করা হয়',
			'settings.scopePlaybackSpeed' => 'গতি Playback',
			'settings.scopeShaderPreset' => 'শারীরিক প্রসেস্ট',
			'settings.scopeAspectRatio' => 'এস্পেক্ট রেসিও',
			'settings.scopeSyncOffsets' => 'অডিও & Subtitle Sync',
			'settings.playerScopeOff' => 'বাঁচান না',
			'settings.playerScopeGlobal' => 'যেখানে',
			'settings.playerScopeLibrary' => 'লাইব্রেরি থেকে',
			'settings.playerScopeTitle' => 'সিনেমা বা সিনেমা',
			'settings.exportDialogTitle' => 'উত্পাদন PlezyNG সিস্টেমগুলি',
			'settings.followSystem' => 'সিস্টেমের ভাষা অনুসরণ করুন',
			'settings.followAppLanguage' => 'ইন্টারফেসের ভাষা ব্যবহার করুন',
			'settings.regionFormat' => 'আঞ্চলিক বিন্যাস',
			'settings.regionFormatDescription' => 'তারিখ, সংখ্যা ও পরিমাপ কীভাবে দেখানো হবে তা বেছে নিন।',
			'settings.metadataLanguage' => 'মিডিয়ার তথ্যের ভাষা',
			'settings.metadataLanguageDescription' => 'সার্ভার সমর্থন করলে শিরোনাম ও বিবরণের পছন্দের ভাষা। অডিও ও সাবটাইটেলের পছন্দ আলাদাভাবে নির্ধারিত হয়।',
			'settings.enterFullscreenOnPlaybackStart' => 'পুরো স্ক্রিনে প্রবেশ করুন যখন Playback শুরু হয়',
			'settings.enterFullscreenOnPlaybackStartDescription' => 'পুরো স্ক্রিনে ডেস্কটপ ভিডিও খুলে যখন Playback শুরু হয়',
			'settings.extendVideoIntoDisplayCutout' => 'ভিডিও প্রদর্শন Cutoutতে বিস্তারিত',
			'settings.extendVideoIntoDisplayCutoutDescription' => 'Fullscreen ভিডিও অ্যান্ড্রয়েড ফোনগুলিতে ক্যামেরার Cutout ব্যবহার করুন',
			'settings.languageDescription' => 'PlezyNG-এর নিয়ন্ত্রণ ও বার্তায় ব্যবহৃত ভাষা বেছে নিন। সিস্টেম অনুসরণ করলে ডিভাইসের ভাষা ব্যবহৃত হবে।',
			'settings.themeDescription' => 'প্রোগ্রামটিতে ব্যবহৃত রঙ এবং প্রতিরোধ নির্বাচন করুন।',
			'settings.libraryDensityDescription' => 'প্রতিটি লাইব্রেরি কার্ডের সংখ্যা পরিবর্তন করুন।',
			'settings.displayScaleDescription' => 'এই গাড়ি ডিভাইসের ইন্টারফেসটি পরিবর্তন না করে আপনার ডিভিশনে টেক্সট মাত্রা পরিবর্তন করুন।',
			'settings.themeSongVolumeDescription' => 'অন্যান্য অডিওের সাথে সম্পর্কিত থিম গানগুলির পরিমাণ নির্ধারণ করুন।',
			'settings.viewModeDescription' => 'লাইব্রেরি পণ্যগুলি একটি নেটওয়ার্কে পোস্টার হিসাবে বা কম্প্যাক্ট তালিকা হিসেবে প্রদর্শিত হয় কিনা নির্বাচন করুন।',
			'settings.gridViewDescription' => 'লাইব্রেরি পণ্যগুলি পোস্টারগুলির তালিকায় এবং পর্যায়ে সংস্থা করুন।',
			'settings.listViewDescription' => 'লাইব্রেরি পণ্যগুলি একটি ভার্চিক তালিকাতে প্রদর্শন করুন, প্রতিটি পণ্যের জন্য আরো টেক্সট।',
			'settings.gridSpacingDescription' => 'লাইব্রেরি নেটওয়ার্কগুলিতে পোস্টারগুলির মধ্যে দূরত্ব স্থাপন করুন।',
			'settings.gridSpacingTightDescription' => 'স্ক্রিনের পৃথিবীতে ছোট ছোঁয়াগুলি দিয়ে আরো পোস্টার উপস্থাপন করুন।',
			'settings.gridSpacingNormalDescription' => 'পোস্টারগুলির মধ্যে স্ট্যান্ডার্ড ভাগ ব্যবহার করুন।',
			'settings.gridSpacingSpaciousDescription' => 'আরও বিচ্ছিন্নতার জন্য পোস্টারগুলির মধ্যে বৃহত্তম ভেতর যোগ করুন।',
			'settings.episodePosterModeDescription' => 'কোন শিল্পকর্মটি কার্ডগুলিতে প্রদর্শন করা হবে তা নির্বাচন করুন।',
			'settings.seriesPosterDescription' => 'প্রত্যেক পরিস্থিতিতে সারিজের পোস্টার ব্যবহার করুন।',
			'settings.seasonPosterDescription' => 'প্রত্যেক পরিসংখ্যানের জন্য সপ্তাহ পোস্টার ব্যবহার করুন যখন উপলব্ধ।',
			'settings.episodeThumbnailDescription' => 'যখন উপলব্ধ হয় তখন একটি ফ্রেম ব্যবহার করুন।',
			'settings.continueWatchingActionDescription' => 'আপনি একটি Continue Watching কার্ড সক্রিয় করার সময় কী ঘটবে তা নির্বাচন করুন।',
			'settings.continueWatchingPlayDescription' => 'দ্রুত চলচ্চিত্র বা প্রদর্শন শুরু করুন।',
			'settings.continueWatchingDetailsDescription' => 'প্রথমে চিঠির পৃষ্ঠা খুলুন যাতে আপনি বিস্তারিত দেখতে এবং একটি পদক্ষেপ নির্বাচন করতে পারেন।',
			'settings.episodeActionDescription' => 'আপনি একটি epizode কার্ড সক্রিয় করার সময় কী ঘটবে তা নির্বাচন করুন।',
			'settings.episodePlayDescription' => 'অবিলম্বে এই ঘটনাটি শুরু করুন।',
			'settings.episodeDetailsDescription' => 'Playback এর আগে পৃষ্ঠাটি খুলুন।',
			'settings.contentScreensaverDelayDescription' => 'প্রদর্শন করার আগে অন্তর্ভুক্ত PlezyNG কতদিন অপেক্ষা করে।',
			'settings.continueWatchingRowSizeDescription' => 'সিদ্ধান্ত করুন যে কার্ডগুলি কতটা বড় থাকে Continue Watching রানায়।',
			'settings.rowSizeCompactDescription' => 'ছোট কার্ডগুলি দেখুন, যাতে আরও পণ্য লাইন সীমাবদ্ধ করে।',
			'settings.rowSizeStandardDescription' => 'কার্ডের স্ট্যান্ডার্ড আকার ব্যবহার করুন।',
			'settings.rowSizeLargeDescription' => 'আরও বড় কার্ডগুলি দেখুন আরেকটি শিল্পকর্মের বিস্তারিত',
			'settings.visualEffectsDescription' => 'এই ডিভাইসের জন্য অ্যানিমেশন এবং শিল্প কার্যকলাপ বাজেট নির্বাচন করুন।',
			'settings.visualEffectsFullDescription' => 'প্রতিটি ডিভাইসে সম্পূর্ণ অ্যানিমেশন এবং শিল্প কাজের প্রভাব ব্যবহার করুন।',
			'settings.startupSectionDescription' => 'কখন PlezyNG শুরু হয় তাহলে কোন বিভাগটি খুলবে তা নির্বাচন করুন।',
			'settings.startupSectionOptions.discover' => 'সম্পর্কিত গবেষণার সূত্র থেকে উন্মুক্ত প্রস্তাব এবং পণ্য।',
			'settings.startupSectionOptions.libraries' => 'আপনার সংযুক্ত মিডিয়া লাইব্রেরি খুলুন।',
			'settings.startupSectionOptions.liveTv' => 'একটি সার্ভার এটি সরবরাহ করলে লাইভ টিভি খুলুন; অন্যথায় স্টার্টপেট বাড়িতে ফিরে আসবে।',
			'settings.startupSectionOptions.search' => 'খোলা মিডিয়া অনুসন্ধান',
			'settings.smallSkipDurationDescription' => 'দূরত্ব নির্ধারণ করুন, যা দ্রুত পিছনে এবং সামনের পাশে নিয়ন্ত্রণ অনুসন্ধান করে।',
			'settings.largeSkipDurationDescription' => 'দীর্ঘ পিছনে যাওয়া দূরে নির্ধারণ করুন এবং সামনের দিকে নিয়ন্ত্রণ খুঁজুন।',
			'settings.rewindOnResumeDescription' => 'একটি ভিডিও পুনরাবৃত্তি করার সময় এই সংখ্যা দ্বারা ফেরত Playback মুদ্রিত করুন।',
			'settings.defaultSleepTimerDescription' => 'আপনি ঘুম টাইমার শুরু করার সময় ব্যবহৃত প্রথম দীর্ঘতা নির্ধারণ করুন।',
			'settings.playNextCountdownDescription' => 'পরবর্তী epizode শুরু করার আগে এটি অনেক সময় অপেক্ষা করুন. 0 থেকে সিদ্ধান্ত নিতে অবিলম্বে শুরু করতে হবে।',
			'settings.autoSkipDelaySettingDescription' => 'এটি যখন একটি intro, ক্রেডিট বা বিজ্ঞাপন স্বয়ংক্রিয়ভাবে বের করার জন্য নির্ধারণ করা হয়।',
			'settings.downmixCenterBoostDescription' => 'সারাউন্ড অডিও স্টেরিওতে মিক্স ডাউন হলে সেন্টার চ্যানেলের সংলাপের মাত্রা বাড়ান।',
			'settings.displaySwitchDelayDescription' => 'ডিসপ্লে মোড বদলানোর আগে অপেক্ষা করুন, যাতে টিভি বা রিসিভার আগের সুইচটি শেষ করতে পারে।',
			'settings.playerBackendDescription' => 'এই ডিভাইসটিতে কোন প্লেব্যাক ইঞ্জিন ডকোড করে এবং ভিডিও ফেরত দেয় তা নির্বাচন করুন।',
			'settings.exoPlayerDescription' => 'অ্যান্ড্রয়েডের মিডিয়া3-এ ভিত্তিক খেলোয়াড় এবং সমর্থিত হার্ডওয়্যার পথগুলি ব্যবহার করুন।',
			'settings.mpvDescription' => 'MPV ব্যবহার করুন, যা আরও Playback, Subtitle এবং ভিডিও প্রক্রিয়াকরণ কন্ট্রোলগুলি প্রকাশ করে।',
			'settings.scopeOffDescription' => 'শুধুমাত্র বর্তমান প্লেব্যাক সেশন জন্য পরিবর্তন রাখুন।',
			'settings.scopeGlobalDescription' => 'প্রতিটি লাইব্রেরি এবং টাইটার জন্য একই মূল্য পুনরায় ব্যবহার করুন।',
			'settings.scopeLibraryDescription' => 'প্রতিটি লাইব্রেরির জন্য একটি নির্দিষ্ট মূল্য মনে রাখুন।',
			'settings.scopeTitleDescription' => 'প্রতিটি প্রদর্শন বা চলচ্চিত্রের জন্য একটি নির্দিষ্ট মূল্য মনে রাখুন।',
			'settings.specialsOrderingServerDescription' => 'মিডিয়া সার্ভার দ্বারা সরবরাহ করা Episode Order রাখুন।',
			'settings.specialsOrderingAirDateDescription' => 'নিয়মিত পরিস্থিতিগুলির মধ্যে বিশেষ জায়গাগুলি তাদের বিমান ডেটা দ্বারা স্থাপন করুন।',
			'settings.specialsOrderingLastDescription' => 'নিয়মিত সপ্তাহের পর প্রতিটি বিশেষ স্থাপন করুন।',
			'settings.skipIntroModeDescription' => 'ইন্ট্রো মার্কেটগুলি স্বাভাবিকভাবে খেলবে কিনা নির্বাচন করুন, একটি স্কাইপ बटन প্রদর্শন করুন, অথবা স্বয়ংক্রিয়ভাবে স্কাইভ করুন।',
			'settings.skipCreditsModeDescription' => 'ক্রেডিটগুলি স্বাভাবিকভাবে খেলবে কিনা নির্বাচন করুন, একটি স্কাইপ बटन প্রদর্শন করুন, অথবা স্বয়ংক্রিয়ভাবে স্টাইপ করুন।',
			'settings.skipAdsModeDescription' => 'শনাক্ত করা বিজ্ঞাপন স্বাভাবিকভাবে চলবে, স্কিপ বোতাম দেখাবে, নাকি নিজে থেকেই এড়িয়ে যাবে তা বেছে নিন।',
			'settings.playbackBufferAutoDescription' => 'সক্রিয় খেলোয়াড়কে তার স্বাভাবিক বাফার আকার নির্বাচন করুন।',
			'settings.playbackBufferLargeDescription' => 'Playback এর আগে আরো মিডিয়া প্রস্তুত রাখুন; এটি আরও স্মৃতি ব্যবহার করে।',
			'settings.playbackBufferExtraLargeDescription' => 'সবচেয়ে বড় পড়া-হাইড বাফার রাখুন; এটি সর্বাধিক স্মৃতি ব্যবহার করে।',
			'settings.defaultQualityDescription' => 'ডিফল্ট ভিডিও রেজিউশন এবং সার্ভারটি ট্রান্সকোড করার জন্য টাইমগুলি বিট্রেট করুন।',
			'settings.cellularQualityDescription' => 'যখন ডিভাইস একটি সেলের একক সংযোগ ব্যবহার করে থাকে, তখন ভিত্তিতে মানের অতিক্রম করুন।',
			'settings.remoteQualityDescription' => 'রিমোট সংযোগে সার্ভারের সঙ্গে যুক্ত হলে ডিফল্ট কোয়ালিটির বদলে এই মান ব্যবহার করুন।',
			'settings.qualityPresetOriginalDescription' => 'সার্ভারকে এটি ট্রান্সকোড করার জন্য অনুরোধ না করে তার উপলব্ধ মানে ফরাস খেলুন।',
			'settings.qualityPresetTranscodeOptionDescription' => 'উপরে দেখানো রেজোলিউশন ও বিটরেট ব্যবহার করে রূপান্তরিত স্ট্রিম দিতে সার্ভারকে বলুন।',
			'settings.qualityPresetSameAsDefaultDescription' => 'Default Quality এর মধ্যে নির্বাচিত মান ব্যবহার করুন।',
			'settings.musicQualityDescription' => 'সার্ভার থেকে অনুরোধ করা সর্বোচ্চ অডিও বিট্রেট সেট করুন; মূল শূন্য প্রদর্শন রাখে।',
			'settings.musicQualityOriginalDescription' => 'Bitrate-capped transcode ছাড়া সূত্র অডিও খেলুন।',
			'settings.musicQualityTranscodeOptionDescription' => 'উপরে দেখানো বিটরেটের কাছাকাছি সীমা রেখে সার্ভারকে ট্রান্সকোড করতে বলুন; প্রকৃত আউটপুট ভিন্ন হতে পারে।',
			'settings.maxVolumeInputLabel' => 'সর্বোচ্চ পরিমাণ (%)',
			'settings.checkForUpdatesDescription' => 'এখন দেখুন কি PlezyNG এর নতুন সংস্করণ পাওয়া যায় কিনা।',
			'settings.appearanceDescription' => 'অ্যাপটি থেমা নির্বাচন করুন এবং লাইব্রেরি কার্ড, হোম রান এবং ন্যাভাইজেশন সংশোধন করুন।',
			'settings.prerollLibraryDescription' => 'সিনেমা pre-rolls হিসাবে উপলব্ধ ক্লিপগুলি প্রন্তর্ভুক্ত লাইব্রেরি নির্বাচন করুন।',
			'settings.prerollSelectionDescription' => 'নির্বাচিত লাইব্রেরির কোন ক্লিপগুলো সিনেমার আগে চলতে পারবে তা বেছে নিন।',
			'settings.contentScreensaverDelayOptionDescription' => 'স্ক্রিন সার্ভার শিল্প প্রদর্শন করার আগে এই অনেক মিনিট অন্তর্ভুক্ত অপেক্ষা করুন।',
			'settings.videoCodecOptionDescription' => 'সমর্থিত হলে এই কোডেক সরাসরি চালাতে দিন। চেক না করা কোডেকগুলো মিডিয়া সার্ভার ট্রান্সকোড করবে।',
			'themeEditor.builtIn' => 'ভিত্তিতে',
			'themeEditor.presets' => 'প্রজাতন',
			'themeEditor.custom' => 'কাস্টম',
			'themeEditor.customEmpty' => 'এখনো সৃষ্টি হয়নি',
			'themeEditor.editCustom' => 'Edit কাস্টম টেমা',
			'themeEditor.editCustomDescription' => 'প্রতিটি রঙ নিজেকে বেছে নিন',
			'themeEditor.locked' => 'জীবনযাপন প্রয়োজনীয়',
			'themeEditor.savedLocked' => 'সংরক্ষিত - জীবনের জন্য অ্যাক্সেসের সাথে পাওয়া যায়',
			'themeEditor.title' => 'কাস্টম থেম',
			'themeEditor.startFrom' => 'শুরু থেকে',
			'themeEditor.startFromDescription' => 'অন্য বিষয় থেকে সব রঙ কপি করুন',
			'themeEditor.colors' => 'রঙ',
			'themeEditor.preview' => 'পূর্বাভাস',
			'themeEditor.slots.bg' => 'ফাউন্ডেশন',
			'themeEditor.slots.surface' => 'সারফেস',
			'themeEditor.slots.outline' => 'বাইরে',
			'themeEditor.slots.text' => 'টেক্ট',
			'themeEditor.slots.textMuted' => 'দ্বিতীয় লেখা',
			'themeEditor.slots.accent' => 'অ্যাক্সেস',
			'themeEditor.opacity' => 'অপারেশন',
			'themeEditor.hexHint' => '#RRGGBB বা #AARRGGBB',
			'themeEditor.fromOtherThemes' => 'অন্যান্য বিষয় থেকে',
			'themeEditor.swatchLabel' => ({required Object theme, required Object color}) => '${theme} ${color}',
			'themeEditor.contrast.textOnBg' => 'ভিত্তিতে লেখা',
			'themeEditor.contrast.textOnSurface' => 'পৃথিবীতে লেখা',
			'themeEditor.contrast.textMutedOnBg' => 'ভিত্তিতে দ্বিতীয় লেখা',
			'themeEditor.contrast.textMutedOnSurface' => 'পৃথিবীর দ্বিতীয় তালিকা',
			'themeEditor.contrast.accentOnBg' => 'ফাঁসের উপর মনোযোগ',
			'themeEditor.contrast.accentOnSurface' => 'পৃথিবীতে উত্থান',
			'themeEditor.contrast.labelOnAccent' => 'অ্যাক্সেন্টের উপর বোতাম লেগেট',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, উপদেশিত ${minimum}:1 এর নিচে',
			'themeEditor.discardTitle' => 'পরিবর্তন ভাবছেন?',
			'themeEditor.discardMessage' => 'আপনার সংরক্ষণ না করা রঙের পরিবর্তনগুলি হারিয়ে যাবে।',
			'themeEditor.discard' => 'বিতর্ক',
			'themeEditor.previewCardTitle' => ({required Object number}) => 'আয়াত ${number}',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => '${minutes} মিনিট left',
			'themeEditor.previewSwitch' => 'Autoplay গাড়ি',
			'themeEditor.previewMutedText' => 'দ্বিতীয় লেখা এভাবে পড়বে।',
			'themeEditor.themeSystemDescription' => 'আপনার ডিভাইসের প্রদর্শন অনুসরণ করুন এবং স্বয়ংক্রিয়ভাবে আলো ও অন্ধকার মধ্যে পরিবর্তন করুন।',
			'themeEditor.themeLightDescription' => 'অন্ধকার টেক্সটের সাথে একটি উজ্জ্বল ফাউন্ড ব্যবহার করুন।',
			'themeEditor.themeDarkDescription' => 'আলো টেক্সটের সাথে একটি অন্ধকার ফলাফল ব্যবহার করুন।',
			'themeEditor.themeOledDescription' => 'অর্থাৎ কালো পৃথিবীগুলি ব্যবহার করুন যা OLED স্ক্রিনগুলিতে আলো কমে যায়।',
			'themeEditor.themeEmberDescription' => 'গরম লাল এবং আকর্ষণ রঙ ব্যবহার করুন।',
			'themeEditor.themeGlacierDescription' => 'নীল অ্যাক্সেন্ট রঙ ব্যবহার করুন।',
			'themeEditor.themeForestDescription' => 'সবুজ এবং প্রাকৃতিক অ্যাক্সেন্ট রঙ ব্যবহার করুন।',
			'themeEditor.themePlumDescription' => 'প্লাম ও ভোল্ট অ্যাক্সেন্ট রঙ ব্যবহার করুন।',
			'themeEditor.themePaperDescription' => 'গরম কাগজের মতো পৃথিবী এবং ইঙ্ক-প্রভিত্তিক রঙ ব্যবহার করুন।',
			'themeEditor.themeCustomDescription' => 'আপনি কাস্টম থেম এডিটারে সৃষ্টি করেছেন রঙ প্যালেট ব্যবহার করুন।',
			'themeEditor.editorDescription' => 'একটি প্যালেটের রং বেছে নিয়ে তার hue, saturation, brightness বা opacity বদলান; সংরক্ষণের আগে প্রিভিউতে পরিবর্তন দেখুন। চাইলে একটি hex রংও লিখতে পারেন।',
			'search.hint' => 'সিনেমা, সিনেমা, সিনেমা, সিনেমা...',
			'search.tryDifferentTerm' => 'একটি ভিন্ন অনুসন্ধান সূত্র চেষ্টা করুন',
			'search.searchYourMedia' => 'আপনার মিডিয়া অনুসন্ধান',
			'search.enterTitleActorOrKeyword' => 'Title, Actor বা Keyword লিখুন',
			'search.people' => 'জনগণ',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'সেট Shortcut জন্য ${actionName}',
			'hotkeys.clearShortcut' => 'কঠিন কঠিন',
			'hotkeys.noShortcutSet' => 'কোন ছোট্ট সেট',
			'hotkeys.currentShortcut' => 'বর্তমান কুরআন :',
			'hotkeys.pressToRecord' => 'একটি কুরআন রেকর্ড করার জন্য নির্বাচন করুন',
			'hotkeys.recordingShortcut' => 'এখন কুরআন চাপ করুন',
			'hotkeys.actions.playPause' => 'খেলা / পাস',
			'hotkeys.actions.volumeUp' => 'ওভেনমেন্ট',
			'hotkeys.actions.volumeDown' => 'ভোল্ডা Down',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'ফেরত খুঁজুন (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'ফেরত চলে যাওয়ার জন্য (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'ফুল স্ক্রিন',
			'hotkeys.actions.muteToggle' => 'একসাথে মুটি',
			'hotkeys.actions.subtitleToggle' => 'Subtitles সহজ',
			'hotkeys.actions.audioTrackNext' => 'পরবর্তী Audio Track',
			'hotkeys.actions.subtitleTrackNext' => 'পরবর্তী সাব্টাইট ট্র্যাক',
			'hotkeys.actions.chapterNext' => 'পরবর্তী চিঠি',
			'hotkeys.actions.chapterPrevious' => 'পূর্ববর্তী চিঠি',
			'hotkeys.actions.episodeNext' => 'পরবর্তী Episode',
			'hotkeys.actions.episodePrevious' => 'পূর্ববর্তী epizode',
			'hotkeys.actions.speedIncrease' => 'দ্রুত বাড়ান',
			'hotkeys.actions.speedDecrease' => 'গতি কমে',
			'hotkeys.actions.speedReset' => 'দ্রুত রেসেট',
			'hotkeys.actions.zoomIn' => 'Zoom ইন',
			'hotkeys.actions.zoomOut' => 'Zoom বাইরে',
			'hotkeys.actions.zoomReset' => 'রেস্টো Zoom',
			'hotkeys.actions.subSeekNext' => 'পরবর্তী Subtitle অনুসরণ করুন',
			'hotkeys.actions.subSeekPrev' => 'Previous Subtitle অনুসন্ধান করুন',
			'hotkeys.actions.subtitleDelayIncrease' => 'দেরি Subtitles',
			'hotkeys.actions.subtitleDelayDecrease' => 'উন্নয়ন Subtitles',
			'hotkeys.actions.shaderToggle' => 'ছায়া দিয়ে',
			'hotkeys.actions.skipMarker' => 'ক্রেডিট / ক্রেডিট / ক্রেডিট',
			'hotkeys.actions.screenshot' => 'স্ক্রিন ফটো',
			'hotkeys.actions.framePrevious' => 'পূর্ববর্তী ফ্রেম',
			'hotkeys.actions.frameNext' => 'পরবর্তী ফ্রেম',
			'fileInfo.title' => 'ফাইল তথ্য',
			'fileInfo.overview' => 'বিবরণ',
			'fileInfo.video' => 'ভিডিও',
			'fileInfo.audio' => 'অডিও',
			'fileInfo.subtitles' => 'সাবটাইটেল',
			'fileInfo.images' => 'ভিত্তিতে ছবি',
			'fileInfo.dataStreams' => 'ডাটা স্ট্রিম',
			'fileInfo.lyrics' => 'গানের কথা',
			'fileInfo.file' => 'ফাইল',
			'fileInfo.attachments' => 'আটকেল',
			'fileInfo.delivery' => 'প্রদান',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => 'সংস্করণ ${index} এর ${count}',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => 'ফাইল ${index} এর ${count}',
			'fileInfo.noStreams' => 'সার্ভার এই ফাইলের জন্য কোন প্রদর্শন না জানিয়েছে।',
			'fileInfo.copyPath' => 'পথ কপি',
			'fileInfo.pathCopied' => 'ফাইল পথ কপি',
			'fileInfo.codec' => 'কোডেক',
			'fileInfo.codecTag' => 'কোডেক Tag',
			'fileInfo.resolution' => 'সিদ্ধান্ত',
			'fileInfo.codedResolution' => 'কোডিং রসিলেশন',
			'fileInfo.bitrate' => 'বিট্রেট',
			'fileInfo.frameRate' => 'ফ্রেম রেট',
			'fileInfo.rotation' => 'রোটেশন',
			'fileInfo.comment' => 'কিভাবে',
			'fileInfo.audioDescription' => 'অডিও Description',
			'fileInfo.headerCompression' => 'হেডার কোম্পানি',
			'fileInfo.sidecarFile' => 'সিডেকার ফাইল',
			'fileInfo.transportTimestamp' => 'ট্রাফিক টাইম',
			'fileInfo.displayOffset' => 'ডাউনলোড Offset',
			'fileInfo.previewFailureCode' => 'ভুল কোড',
			'fileInfo.previewRetries' => 'পূর্বাভাস Retries',
			'fileInfo.aspectRatio' => 'এস্পেক্ট রেসিও',
			'fileInfo.pixelAspectRatio' => 'পিক্সেল Aspect Ratio',
			'fileInfo.profile' => 'প্রোফাইল',
			'fileInfo.level' => 'স্তর',
			'fileInfo.bitDepth' => 'গভীরতা',
			'fileInfo.pixelFormat' => 'পিক্সেল ফরম্যাট',
			'fileInfo.colorSpace' => 'কালার স্পেস',
			'fileInfo.colorRange' => 'রঙ রান্না',
			'fileInfo.colorPrimaries' => 'কালার প্রাইমারি',
			'fileInfo.colorTransfer' => 'কালার ট্রান্সফার',
			'fileInfo.chromaSubsampling' => 'ক্রোম Subsampling',
			'fileInfo.chromaLocation' => 'ক্রোম অবস্থান',
			'fileInfo.scanType' => 'স্ক্যান টাইপ',
			'fileInfo.interlaced' => 'Interlink করা',
			'fileInfo.anamorphic' => 'অ্যানামর্ফিক',
			'fileInfo.referenceFrames' => 'Reference ফ্রেম',
			'fileInfo.dynamicRange' => 'ডিনামিনিক রান্না',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Dolby Vision নম্বর',
			'fileInfo.dolbyVisionVersion' => 'Dolby Vision সংস্করণ',
			'fileInfo.dolbyVisionLayers' => 'Dolby Vision তালিকা',
			'fileInfo.baseLayerCompatibility' => 'Base Layer সংযুক্ততা',
			'fileInfo.avcBitstream' => 'AVC বিট্রেম',
			'fileInfo.nalLengthSize' => 'নল দীর্ঘতা',
			'fileInfo.scalingMatrix' => 'কাস্টম Scaling Matrix',
			'fileInfo.streamIdentifier' => 'প্রদর্শন Identifier',
			'fileInfo.streamIndex' => 'প্রদর্শন Index',
			'fileInfo.streamId' => 'স্ট্রিম ID',
			'fileInfo.language' => 'ভাষা',
			'fileInfo.languageCode' => 'ভাষা কোড',
			'fileInfo.streamTitle' => 'ট্র্যাক টাইম',
			'fileInfo.channels' => 'চ্যানেলগুলো',
			'fileInfo.sampleRate' => 'নমুনা হার',
			'fileInfo.spatialAudio' => 'স্পেশাল অডিও',
			'fileInfo.textBased' => 'টেক্সট ভিত্তি',
			'fileInfo.subtitleFormat' => 'সিডেকার ফর্মেট',
			'fileInfo.provider' => 'সরবরাহকারী',
			'fileInfo.matchScore' => 'Match Score খেলা',
			'fileInfo.externalDelivery' => 'আলাদাভাবে সেবা করা যায়।',
			'fileInfo.sidecarPath' => 'সিডেকার পথ',
			'fileInfo.sourceStream' => 'কপি থেকে',
			'fileInfo.temporary' => 'সময়কালীন',
			'fileInfo.timeBase' => 'সময় Base',
			'fileInfo.overallBitrate' => 'মোট বিট্রেট',
			'fileInfo.path' => 'পথ',
			'fileInfo.fileName' => 'ফাইল নাম',
			'fileInfo.size' => 'বড়',
			'fileInfo.totalSize' => 'মোট আকার',
			'fileInfo.container' => 'কন্টিনার',
			'fileInfo.duration' => 'দীর্ঘদিন',
			'fileInfo.previewThumbnails' => 'পূর্ববর্তী টমিনাল',
			'fileInfo.previewIndex' => 'পূর্বাভাস Index',
			'fileInfo.packetLength' => 'প্যাকেটের দীর্ঘতা',
			'fileInfo.filePresent' => 'ফাইল উপস্থিতি',
			'fileInfo.fileReadable' => 'সার্ভার দ্বারা পড়া',
			'fileInfo.streamPath' => 'পথ প্রদর্শন',
			'fileInfo.optimizedForStreaming' => 'Streaming জন্য Optimized',
			'fileInfo.has64bitOffsets' => '64 বিট অফসেট',
			'fileInfo.protocol' => 'প্রোটোটোকল',
			'fileInfo.mediaType' => 'মিডিয়া টাইপ',
			'fileInfo.sourceKind' => 'সূত্র কেমন',
			'fileInfo.optimizedVersion' => 'Optimized সংস্করণ',
			'fileInfo.optimizationTarget' => 'সেরা লক্ষ্য',
			'fileInfo.deletedAt' => '삭제',
			'fileInfo.remoteSource' => 'দূরবর্তী সূত্র',
			'fileInfo.infiniteStream' => 'infinite প্রদর্শন',
			'fileInfo.directPlay' => 'সরাসরি খেলা',
			'fileInfo.directStream' => 'সরাসরি প্রদর্শন',
			'fileInfo.transcoding' => 'ট্রানকডিং',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'সংস্করণ ID',
			'fileInfo.fileId' => 'ফাইল ID',
			'fileInfo.defaultAudioTrack' => 'অডিও ট্র্যাক',
			'fileInfo.defaultSubtitleTrack' => 'ডিফল্ট Subtitle Track',
			'fileInfo.subtitlesOff' => 'বন্ধ',
			'fileInfo.flagDefault' => 'প্রত্যাশিত',
			'fileInfo.flagForced' => 'বাধ্য',
			'fileInfo.flagSelected' => 'নির্বাচিত',
			'fileInfo.flagExternal' => 'বিদেশি',
			'fileInfo.flagHearingImpaired' => 'শুনতে অসুবিধা',
			'fileInfo.flagDub' => 'ডাব',
			'fileInfo.flagOriginal' => 'মূল',
			'fileInfo.channelsMono' => 'মোনো',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'প্রোফাইল ${profile}',
			'mediaMenu.markAsWatched' => 'মারি দেখে',
			'mediaMenu.markAsUnwatched' => 'মারি অদৃশ্য',
			'mediaMenu.removeFromContinueWatching' => 'চলুন দেখতে থেকে বের করুন',
			'mediaMenu.viewDetails' => 'বিস্তারিত দেখুন',
			'mediaMenu.goToSeries' => 'সিরিজে যান',
			'mediaMenu.shufflePlay' => 'খেলা শফল',
			'mediaMenu.shuffleNotAvailableOffline' => 'শফল অফলি পাওয়া যায় না',
			'mediaMenu.fileInfo' => 'ফাইল তথ্য',
			'mediaMenu.deleteEpisodeFromServer' => 'সার্ভার থেকে এজেস্ট 삭제 করুন',
			'mediaMenu.deleteSeasonFromServer' => 'সার্ভার থেকে সপ্তাহ মুছে ফেলা',
			'mediaMenu.deleteShowFromServer' => 'সার্ভার থেকে প্রদর্শন মুছে ফেলুন',
			'mediaMenu.deleteMovieFromServer' => 'সার্ভার থেকে ভিডিও মুছে ফেলুন',
			'mediaMenu.deleteEpisodeTitle' => 'এই অধ্যায়টি কি মুছে ফেলবে?',
			'mediaMenu.deleteSeasonTitle' => 'এই সপ্তাহে নেমে যাবে?',
			'mediaMenu.deleteShowTitle' => 'এই প্রদর্শনটি কি মুছে ফেলবে?',
			'mediaMenu.deleteMovieTitle' => 'এই চলচ্চিত্রটি কি মুছে ফেলবে?',
			'mediaMenu.deleteEpisodeConfirm' => 'মুছে ফেলুন epizode',
			'mediaMenu.deleteSeasonConfirm' => 'মুছে ফেলুন সপ্তাহ',
			'mediaMenu.deleteShowConfirm' => 'মুছে ফেলুন প্রদর্শনী',
			'mediaMenu.deleteMovieConfirm' => 'সিনেমা মুছে ফেলুন',
			'mediaMenu.deleteAnyway' => 'যদিও মুছে ফেলুন',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => 'আপনার সার্ভার থেকে স্থায়ীভাবে ${title} মুছে ফেলুন?',
			'mediaMenu.deleteMultipleWarning' => 'এতে সব পর্ব এবং সেগুলির ফাইল অন্তর্ভুক্ত রয়েছে।',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n, one: 'এতে থাকা ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}টি পর্ব এবং তার ফাইল মুছে যাবে।', other: 'এতে থাকা সব ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}টি পর্ব এবং সেগুলির ফাইল মুছে যাবে।', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n, one: 'এই আইটেমটি ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}টি ফাইলে সংরক্ষিত আছে, যা মুছে যাবে।', other: 'এই আইটেমটি ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}টি ফাইল জুড়ে সংরক্ষিত আছে এবং সবগুলি মুছে যাবে।', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n, one: 'একই ফাইলে আরও ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}টি পর্ব সংরক্ষিত আছে এবং সেটিও মুছে যাবে:', other: 'একই ফাইলে আরও ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}টি পর্ব সংরক্ষিত আছে এবং সেগুলিও মুছে যাবে:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'PlezyNG কোন ফাইলটি মুছে ফেলবে তা নিশ্চিত করতে পারেন না, তাই এটি উপরে নামিত পণ্যের চেয়ে বেশি মুছে ফেলতে পারে. বাতিল করুন এবং আবারও চেষ্টা করুন, অথবা কোনওভাবে মুছে ফেলুন।',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'আপনার সার্ভার এই আইটেমের ফাইলের বিবরণ দেয়নি, তাই PlezyNG কোন ফাইলগুলি মুছে যাবে তা পরীক্ষা করতে পারছে না। উপরে উল্লেখ করা আইটেম ছাড়াও আরও কিছু মুছে যেতে পারে।',
			'mediaMenu.mediaDeletedSuccessfully' => 'সফলভাবে মুছে ফেলেন মিডিয়া',
			'mediaMenu.mediaFailedToDelete' => 'মিডিয়া পণ্য মুছে ফেলে না',
			'mediaMenu.rate' => 'রাত',
			'mediaMenu.playFromBeginning' => 'শুরু থেকে খেলা',
			'mediaMenu.playVersion' => 'গেম সংস্করণ...',
			'rateSheet.title' => 'রাত',
			'rateSheet.server' => 'সার্ভার',
			'rateSheet.favorite' => 'পছন্দ',
			'rateSheet.favorited' => 'প্রিয়',
			'rateSheet.saved' => 'বাঁচানো',
			'rateSheet.notAvailable' => 'খেলা পাওয়া যায়নি',
			'rateSheet.noConnectedServices' => 'সেখান থেকে সেবা সংযোগ করতে Settings এর একটি পরিষেবা যোগ করুন।',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, সিনেমা',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, টিভি প্রদর্শন',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'দেখানো',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent}% দেখানো',
			'accessibility.mediaCardUnwatched' => 'দেখা হয়নি',
			'accessibility.tapToPlay' => 'খেলতে ট্যাপ',
			'accessibility.decrease' => 'কমে',
			'accessibility.increase' => 'বৃদ্ধি',
			'accessibility.decreaseValue' => ({required Object label}) => 'কমে যাওয়া ${label}',
			'accessibility.increaseValue' => ({required Object label}) => 'সংখ্যা: ${label}',
			'accessibility.hue' => 'হুই',
			'accessibility.saturation' => 'সুরতান',
			'accessibility.brightness' => 'সূর্য',
			'accessibility.hexColor' => 'হেক্স রঙ',
			'accessibility.expandText' => 'টেক্সট বিস্তারিত',
			'accessibility.collapseText' => 'ভেঙে পড়েন টেক্সট',
			'accessibility.alphabetNavigation' => 'অ্যালবাম navigation',
			'accessibility.alphabetScrollHint' => 'এগিয়ে বা নিচের দিকে চলে যাওয়ার জন্য লিখে',
			'accessibility.rowColumnPosition' => ({required Object rowCount, required Object row, required Object columnCount, required Object column}) => '${rowCount}টি সারির মধ্যে ${row} নম্বর সারি, ${columnCount}টি কলামের মধ্যে ${column} নম্বর কলাম',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'রান ${row} এর ${rowCount}',
			'accessibility.autoScrollPlay' => 'Auto-Scroll খেলা',
			'accessibility.autoScrollPause' => 'স্বয়ংক্রিয় স্ক্রল',
			'accessibility.hueShort' => 'H',
			'accessibility.saturationShort' => 'S',
			'accessibility.valueShort' => 'V',
			'accessibility.red' => 'লাল',
			'accessibility.green' => 'সবুজ',
			'accessibility.blue' => 'নীল',
			'accessibility.redShort' => 'R',
			'accessibility.greenShort' => 'জি',
			'accessibility.blueShort' => 'বি',
			'accessibility.colorModeHsv' => 'HSV',
			'accessibility.colorModeRgb' => 'RGB',
			'accessibility.title' => 'অ্যাক্সেসযোগ্যতা',
			'accessibility.summary' => 'টেক্সট, কন্ট্রোস্ট, মোট এবং নিয়ন্ত্রণ',
			'accessibility.systemHint' => 'আপনার ডিভাইসের অ্যাক্সেসযোগ্যতা সেটস সবসময় প্রয়োগ করা হয়. এই পছন্দগুলি PlezyNG সারা সময় সমাধানগুলি যোগ করে।',
			'accessibility.readability' => 'পড়া ও দেখার সুযোগ',
			'accessibility.textSize' => 'টেক্সটের বড়',
			'accessibility.preview' => 'আপনার পরবর্তী গল্পটি খুঁজে পেতে. পড়ুন, শুনুন এবং আপনার নিজের ধাপে দেখুন।',
			'accessibility.boldText' => 'কঠিন ইন্টারফেস টেক্সট',
			'accessibility.highContrast' => 'উচ্চ প্রতিরোধ',
			'accessibility.highContrastHint' => 'হালকা বা গাঢ় পটভূমিতে আরও স্পষ্ট লেখা, সীমানার রেখা ও ফোকাস নির্দেশক।',
			'accessibility.interaction' => 'ইন্টারফেস ও ইন্টারফেশন',
			'accessibility.reduceMotion' => 'মোটর কমাতে',
			'accessibility.reduceMotionHint' => 'ফোকাসের নির্দেশক, পৃষ্ঠা পরিবর্তন ও সাজসজ্জার প্রভাবগুলির নড়াচড়া বন্ধ রাখুন।',
			'accessibility.largeTargets' => 'বড় ট্যাক্স টার্গেট',
			'accessibility.largeTargetsHint' => 'স্পর্শ ও সহায়ক প্রযুক্তির মাধ্যমে চলাচল সহজ করতে সাধারণ নিয়ন্ত্রণগুলির জায়গা বড় করুন।',
			'accessibility.navigationHint' => 'নিয়ন্ত্রণগুলির মধ্যে যেতে Tab ও Shift+Tab, সক্রিয় করতে Enter বা Space এবং বন্ধ করতে Escape বা ফিরে যাওয়ার বোতাম ব্যবহার করুন। বই খোলা থাকলে জুম ও পড়ার পছন্দগুলি বদলানো যায়।',
			'accessibility.textSizeDescription' => 'আপনার ডিভাইসের সিস্টেম টেক্সটের আকারের সেটিংয়ের পাশাপাশি PlezyNG ইন্টারফেসের লেখার আকারও পরিবর্তন করুন।',
			'accessibility.boldTextHint' => 'ইন্টারফেস ট্যাগ এবং বার্তাগুলির জন্য একটি গভীর ওজন ব্যবহার করুন যা তাদের বিতর্ক করা সহজ করে।',
			'tooltips.shufflePlay' => 'শফল খেলা',
			'tooltips.playTrailer' => 'ট্র্যালার খেলুন',
			'tooltips.markAsWatched' => 'মার্ক দেখে',
			'tooltips.markAsUnwatched' => 'মার্ক অবিশ্বাসিত',
			'audioTracks.track' => ({required Object n}) => 'অডিও ট্র্যাক ${n}',
			'videoControls.audioLabel' => 'অডিও',
			'videoControls.subtitlesLabel' => 'সাবটাইটেল',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => 'বাক্স',
			'videoControls.fillScreen' => 'স্ক্রিন পূরণ',
			'videoControls.stretch' => 'বিস্তারিত',
			'videoControls.lockRotation' => 'লক রটেশন',
			'videoControls.unlockRotation' => 'রটিং অসুবিধা',
			'videoControls.timerActive' => 'টাইমিং সক্রিয়',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'প্লাইব্যাক ${duration} সালে দাঁড়িয়ে যাবে',
			'videoControls.sleepTimerEndOfVideo' => 'বর্তমান ভিডিও শেষ',
			'videoControls.sleepTimerStopAtHeader' => 'থেমে যায়',
			'videoControls.sleepTimerDurationHeader' => 'টাইম',
			'videoControls.playbackWillPauseAtEnd' => 'এই ভিডিও শেষে Playback বন্ধ হবে',
			'videoControls.stillWatching' => 'এখনও দেখতে চান?',
			'videoControls.pausingIn' => ({required Object seconds}) => '${seconds} সেকেন্ড পরে বিরতি দেওয়া হবে',
			'videoControls.continueWatching' => 'চলুন',
			'videoControls.autoPlayNext' => 'Next গাড়ি খেলা',
			'videoControls.playNext' => 'Next খেলুন',
			'videoControls.playButton' => 'খেলা',
			'videoControls.pauseButton' => 'বিরতি',
			'videoControls.playbackPaused' => 'দাঁড়িয়ে',
			'videoControls.playbackResumed' => 'খেলতে',
			'videoControls.loadingVideo' => 'ভিডিও ডাউনলোড',
			'videoControls.showPlaybackControls' => 'Playback নিয়ন্ত্রণ দেখুন',
			'videoControls.hidePlaybackControls' => 'Playback নিয়ন্ত্রণ',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'ফেরত খুঁজুন ${seconds} সেকেন্ড',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'পূর্ববর্তী অনুসন্ধান ${seconds} সেকেন্ড',
			'videoControls.previousButton' => 'পূর্ববর্তী epizode',
			'videoControls.nextButton' => 'পরবর্তী epizode',
			'videoControls.previousChapterButton' => 'পূর্ববর্তী চিঠি',
			'videoControls.nextChapterButton' => 'পরবর্তী চিঠি',
			'videoControls.muteButton' => 'মুটি',
			'videoControls.unmuteButton' => 'অসংখ্য',
			'videoControls.settingsButton' => 'Playback সিস্টেম',
			'videoControls.tracksButton' => 'অডিও & সাবটাইটল',
			'videoControls.chaptersButton' => 'চিঠি',
			'videoControls.segmentLoopHelp' => 'এই প্লেব্যাকের সময় একটি বিভাগ চালু করুন. A সিস্টেম, তারপর পরবর্তী সময়ের মধ্যে B সিস্টেট করুন.',
			'videoControls.setLoopStart' => 'সেন্ট লোভ শুরু (এ)',
			'videoControls.setLoopEnd' => 'সেন্ট লোভ শেষ (B)',
			'videoControls.clearSegmentLoop' => 'স্পষ্ট সেক্টর লুক',
			'videoControls.setLoopStartFirst' => 'শুরু (এ) এর আগে শেষ (বি) সিস্টেম করুন।',
			'videoControls.loopEndAfterStart' => 'শুরু থেকে পরবর্তী সূচনা হতে হবে।',
			'videoControls.segmentLoopUnavailable' => 'এই প্লাইবের জন্য সেকেন্ড লুপিং পাওয়া যায় না।',
			'videoControls.loopPointNotSet' => 'সিস্টেম না',
			'videoControls.bookmarksHelp' => 'এই ডিভাইসে বুকমার্ক সংরক্ষণ করা হয়. সেই সময়ের জন্য একটি নির্বাচন করুন।',
			'videoControls.bookmarksButton' => 'বুকমার্ক',
			'videoControls.chaptersAndBookmarks' => 'বিভাগ ও বইমেলা',
			'videoControls.segmentLoop' => 'সেগেট লোভ',
			'videoControls.addBookmark' => 'Bookmark যোগ করুন',
			'videoControls.bookmarkName' => 'Bookmark নাম',
			_ => null,
		} ?? switch (path) {
			'videoControls.bookmarkNameHint' => 'উদাহরণস্বরূপ, দৃশ্য খোলা',
			'videoControls.bookmarkDefaultName' => ({required Object n}) => 'বইমার্ক ${n}',
			'videoControls.bookmarkNameRequired' => 'এ বইয়ের জন্য একটি নাম লিখুন।',
			'videoControls.deleteBookmark' => 'বুকমার্ক 삭제',
			'videoControls.bookmarkLimitReached' => 'এই পণ্যটি এখন 100 বইমেলা আছে।',
			'videoControls.bookmarkUnavailable' => 'আমি এই বইমেলাটি সংরক্ষণ বা মুছে ফেলতে পারতাম না।',
			'videoControls.bookmarkSaved' => 'বুকমার্ক উদ্ধার করা হয়েছে।',
			'videoControls.bookmarkDeleted' => 'Bookmark মুছে ফেলা হয়েছে।',
			'videoControls.loopPointSet' => ({required Object point, required Object time}) => 'লোপ পয়েন্ট ${point} সেট করুন ${time}.',
			'videoControls.noChaptersOrBookmarks' => 'কোন বই বা চিঠি পাওয়া যায় না।',
			'videoControls.versionQualityButton' => 'সংস্করণ & মান',
			'videoControls.versionColumnHeader' => 'সংস্করণ',
			'videoControls.qualityColumnHeader' => 'মানের',
			'videoControls.qualityOriginal' => 'মূল',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} এমবিএস',
			'videoControls.transcodeUnavailableFallback' => 'Transcoding unavailable — খেলতে মূল মান',
			'videoControls.subtitleUnavailableFallback' => 'নির্বাচিত সাবটাইটলগুলি লোড করা যাবে না - সাবটাইটল ছাড়া চলতে পারে',
			'videoControls.pipButton' => 'ছবি-ন-পিক্টার মোড',
			'videoControls.aspectRatioButton' => 'এস্পেক্ট রেসিও',
			'videoControls.ambientLighting' => 'পরিবেশ আলো',
			'videoControls.fullscreenButton' => 'পুরো স্ক্রিনে প্রবেশ',
			'videoControls.exitFullscreenButton' => 'পুরো স্ক্রিনের বাইরে',
			'videoControls.alwaysOnTopButton' => 'সবসময় শীর্ষে',
			'videoControls.rotationLockButton' => 'রটিং লক',
			'videoControls.lockScreen' => 'স্ক্রিন লক',
			'videoControls.screenLockButton' => 'স্ক্রিন লক',
			'videoControls.timelineSlider' => 'ভিডিও টাইমলাইন',
			'videoControls.volumeSlider' => 'পরিমাণ স্তর',
			'videoControls.endsAt' => ({required Object time}) => 'ফাইনাল ${time}',
			'videoControls.pipActive' => 'ছবি-ন-পিক্টার মধ্যে খেলা',
			'videoControls.pipFailed' => 'ছবি-ন-ফিল্টার শুরু হয়নি',
			'videoControls.screenshotSaved' => 'স্ক্রিন ফটো সুরক্ষিত',
			'videoControls.screenshotFailed' => 'স্ক্রিন ফটো করতে পারত না',
			'videoControls.zoomPercent' => ({required Object percent}) => 'জুম ${percent}%',
			'videoControls.volumePercent' => ({required Object percent}) => 'শব্দের মাত্রা ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'প্রয়োজনীয়তা Android 8.0 বা নতুন',
			'videoControls.pipErrors.iosVersion' => 'প্রয়োজন iOS 15.0 বা নতুন',
			'videoControls.pipErrors.permissionDisabled' => 'Image-in-picture অ্যাক্সেস করা হয়. সিস্টেম সেটগুলিতে এটি অ্যাক্সেস করা হয়.',
			'videoControls.pipErrors.notSupported' => 'ডিভাইস Image-in-Picture মোড সমর্থন করে না',
			'videoControls.pipErrors.voSwitchFailed' => 'ভিডিও উত্পাদন পরিবর্তন করতে পারিনি ছবি-ন-ফটো',
			'videoControls.pipErrors.failed' => 'ছবি-ন-ফিল্টার শুরু হয়নি',
			'videoControls.pipErrors.prepareFailed' => 'ছবি-ন-পিত্র তৈরি করা যাবে না',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'একটি ভুল ঘটেছে: ${error}',
			'videoControls.chapters' => 'চিঠি',
			'videoControls.noChaptersAvailable' => 'কোন বিভাগ নেই',
			'videoControls.queue' => 'কুরআন',
			'videoControls.noQueueItems' => 'কোন পণ্য নেই কুকুরে',
			'videoControls.noAudioDevicesAvailable' => 'কোন অডিও ডিভাইস পাওয়া যায় না',
			'videoControls.searchSubtitles' => 'অনুসন্ধান Subtitles',
			'videoControls.language' => 'ভাষা',
			'videoControls.noSubtitlesFound' => 'কোন সূত্র পাওয়া যায়নি',
			'videoControls.subtitleDownloaded' => 'Subtitle ডাউনলোড',
			'videoControls.subtitleDownloadedNotApplied' => 'ডাউনলোড করা হয়েছে, কিন্তু এটি নির্বাচন করা যায়নি',
			'videoControls.subtitleDownloadFailed' => 'Subtitle ডাউনলোড করতে পারেননি',
			'videoControls.searchLanguages' => 'ভাষা অনুসন্ধান...',
			'videoControls.skipIntro' => 'সিন্ট্রো',
			'videoControls.skipCredits' => 'ক্রেডিট স্কাইপ',
			'videoControls.nextEpisode' => 'পরবর্তী Episode',
			'videoControls.subtitleTrack' => ({required Object n}) => 'ট্র্যাক ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => 'পৃথিবী ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (প্রত্যাশিত)',
			'videoControls.osdSubtitlesOff' => 'টাইপ: বেরিয়ে',
			'videoControls.osdSubtitles' => ({required Object track}) => 'সংখ্যা: ${track}',
			'videoControls.osdAudio' => ({required Object track}) => 'অডিও: ${track}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ফ্রেম', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ফ্রেম', ), 
			'videoControls.trackSelectionTitle' => 'Playback এর আগে ট্র্যাক নির্বাচন করুন',
			'videoControls.trackSelectionAuto' => 'স্বয়ংক্রিয় নির্বাচন',
			'videoControls.openMiniPlayer' => 'খোলা মিনি খেলোয়াড়',
			'videoControls.returnToFullPlayer' => 'পুরো খেলোয়াড়কে ফিরে আসুন',
			'videoControls.loadSubtitleFile' => 'Subtitle ফাইলের জন্য...',
			'videoControls.subtitleLoadFailed' => 'Subtitle ফাইল লোড করতে পারিনি',
			'videoControls.skipAds' => 'হাঁটান Ads',
			'videoControls.tapToUnlock' => 'আনলক করতে ট্যাপ করুন',
			'videoControls.tapAgainToUnlock' => 'আনলক করতে আবার ট্যাপ করুন',
			'messages.markedAsWatched' => 'দেখানো হয়েছে যেমন',
			'messages.markedAsUnwatched' => 'অবিশ্বাসিত হিসাবে চিহ্নিত',
			'messages.markedAsWatchedOffline' => 'দেখানো হিসাবে মার্কিত (এখন অনলাইনে সনাক্ত করা হবে)',
			'messages.markedAsUnwatchedOffline' => 'নজরদারি হিসাবে চিহ্নিত (এখন অনলাইনে সিন্ক করা হবে)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'স্বয়ংক্রিয় ড্রাইভ: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n, one: 'গাড়ি-অটোমোড ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} দেখানো ডাউনলোড', other: 'Auto-remote ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} দেখানো ডাউনলোড', ), 
			'messages.removedFromContinueWatching' => 'চলুন দেখার থেকে বের করা',
			'messages.errorLoading' => ({required Object error}) => 'ভুল: ${error}',
			'messages.searchPartialResults' => 'কিছু মিডিয়া সার্ভারগুলি অনুসন্ধান করা যাবে না. उपलब्ध ফলাফল দেখানোর জন্য।',
			'messages.streamInterrupted' => 'ফ্রান্স বন্ধ হয়ে গেল, প্রচার খেলতে বা ফেরার চেষ্টা করতে।',
			'messages.liveStreamInterrupted' => 'লাইভ প্রদর্শন বন্ধ হয়েছিল. প্রচার খেলতে পেরেছিল।',
			'messages.fileInfoNotAvailable' => 'ফাইল তথ্য পাওয়া যায় না',
			'messages.playbackAuthenticationRequired' => 'এই পণ্যটি খেলতে আবার মিডিয়া সার্ভারে প্রবেশ করুন।',
			'messages.playbackServerUnavailable' => 'মিডিয়া সার্ভার পাওয়া যায় না, পরে আবার চেষ্টা করুন।',
			'messages.playbackDataInvalid' => 'সার্ভারটি অস্বীকার Playback তথ্য ফিরিয়ে দেয়।',
			'messages.playbackCancelled' => 'Playback বাতিল করা হয়েছে।',
			'messages.playbackFailed' => 'Playback শুরু করা যাবে না।',
			'messages.playbackFailedDetail' => ({required Object error}) => 'Playback শুরু করা যায় না: ${error}',
			'messages.audioOutputFailed' => 'টেলিভিশন বা রেকর্ডার এর অডিও সংযোগ চেক করুন; অন্য অ্যাপগুলির কোনও অডিও নেই যদি, ডিভাইসটি পুনরায় শুরু করুন।',
			'messages.mediaUnavailable' => 'এই বিষয়বস্তু এখন আর পাওয়া যায় না।',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'ভুল লোড ফাইল তথ্য: ${error}',
			'messages.errorLoadingSeries' => 'ভুল লোডিং সিরিজ',
			'messages.musicNotSupported' => 'Music Playback এখনো সমর্থিত হয় না',
			'messages.noDescriptionAvailable' => 'কোন বিবরণ পাওয়া যায় না',
			'messages.noProfilesAvailable' => 'কোন প্রোফাইল পাওয়া যায় না',
			'messages.contactAdminForProfiles' => 'আপনার সার্ভার প্রশাসককে যোগাযোগ করুন প্রোফাইল যোগ করার জন্য',
			'messages.unableToDetermineLibrarySection' => 'এই পণ্যের জন্য লাইব্রেরি বিভাগ নির্ধারণ করতে পারেন না',
			'messages.logsCleared' => 'লগ পরিষ্কার',
			'messages.logsCopied' => 'ক্লাববোর্ডে কপি করা',
			'messages.noLogsAvailable' => 'কোন লগ পাওয়া যায় না',
			'messages.libraryScanning' => ({required Object title}) => 'স্ক্যানিং “${title}” ...',
			'messages.libraryScanStarted' => ({required Object title}) => 'লাইব্রেরি স্ক্যান শুরু হয় "${title}" জন্য',
			'messages.libraryScanFailed' => ({required Object error}) => 'স্ক্যান করতে পারিনি লাইব্রেরি: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => '“${title}” এর জন্য ফ্রেসিং মেটাদেট...',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'মেটা ডেটা ফ্রিজ শুরু হয় "${title}" জন্য',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'ম্যাটা ডেটা আপডেট করতে পারিনি: ${error}',
			'messages.logoutConfirm' => 'আপনি কি নিশ্চিত যে আপনি ডাউনলোড করতে চান?',
			'messages.noSeasonsFound' => 'কোন季節 পাওয়া যায় না',
			'messages.seasonsLoadFailed' => 'সপ্তাহের লোড করতে পারবেন না',
			'messages.noEpisodesFound' => 'প্রথম সপ্তাহে কোন ঘটনা পাওয়া যায়নি।',
			'messages.noEpisodesFoundGeneral' => 'কোন ঘটনা পাওয়া যায়নি',
			'messages.episodesLoadFailed' => 'এজিসগুলি লোড করতে পারবেন না',
			'messages.noResultsFound' => 'কোন ফলাফল পাওয়া যায় না',
			'messages.sleepTimerSet' => ({required Object label}) => 'ঘুম টাইমার্ক ${label}',
			'messages.noItemsAvailable' => 'কোন পণ্য পাওয়া যায় না',
			'messages.failedToCreatePlayQueueNoItems' => 'একটি খেলা কুকুর তৈরি করতে পারতেন না - কোন পণ্য নেই',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'অসম্ভব ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'সমন্বয়যোগ্য খেলোয়াড়ের জন্য বিনিময় ...',
			'messages.serverLimitTitle' => 'Playback হারিয়েছে',
			'messages.serverLimitBody' => 'সার্ভার ভুল (HTTP 500). একটি প্যাডবাইড / ট্রান্সকডিং সীমাবদ্ধতা সম্ভবত এই সেশনকে প্রত্যাহার করেছিল।',
			'messages.mediaUnreadableTitle' => 'ফাইল অসম্ভব',
			'messages.mediaUnreadableBody' => 'সার্ভারটি এই পণ্যটি খুঁজে পেয়েছিল কিন্তু তার ফাইলটি পড়তে পারতেন না (HTTP 404). ফাইলটি সম্ভবত স্থানান্তর করা হয়, মুছে ফেলিত হয়, অথবা তার স্টোরেজ অঅফলি।',
			'messages.serverBusyTitle' => 'অসম্ভব প্রদর্শন',
			'messages.serverBusyBody' => 'সার্ভার এই ফাইলটি প্রদর্শন করতে বাধ্য করেছিল (HTTP 503). এটি আবার শুরু হতে পারে, व्यस्त, অথবা ফাইলের স্টোরেজ অফলি হতে পারে. এক মুহূর্তে আবার চেষ্টা করুন - যদি এটি চলছে, সার্ভার মালিককে সার্ভার এবং ফাইলের স্টোরেজ চেক করতে বলুন।',
			'messages.playbackNotAllowedTitle' => 'Playback অনুমোদিত নয়',
			'messages.playbackNotAllowedBody' => 'সার্ভার এই আইটেমটি স্ট্রিম করতে অস্বীকার করেছে (HTTP 403)। আপনার অ্যাকাউন্টে এটি চালানোর অনুমতি নাও থাকতে পারে, অথবা সার্ভার শুধু তার স্থানীয় নেটওয়ার্কে চালানোর অনুমতি দিতে পারে।',
			'messages.logsUploaded' => 'লগ আপলোড',
			'messages.logsUploadFailed' => 'লোগো আপলোড করতে পারিনি',
			'messages.logId' => 'লগ ID',
			'messages.burnedSubtitlesUseMenu' => 'এই প্রদর্শনে সাবটাইটিস জ্বালিত হয়. সাবটাইটিস মেনু থেকে তাদের পরিবর্তন করুন.',
			'messages.noVideoUrl' => 'কোন ভিডিও URL নেই',
			'messages.playbackNoMediaSources' => 'সার্ভার কোন খেলোয়াড় মিডিয়া সূত্র ফিরে দেয় না',
			'messages.playbackDataNotPrepared' => 'Playback শুরু হয় তার ডেটা প্রস্তুত হওয়ার আগে',
			'messages.streamSelectionUnavailable' => 'এই সূত্রের জন্য স্ট্রিম নির্বাচন পাওয়া যায় না',
			'messages.streamSelectionFailed' => 'নির্বাচিত প্রদর্শনগুলি প্রয়োগ করতে পারবেন না',
			'messages.trackSelectionNotRemembered' => 'এই প্লাস্টিক নির্বাচন শুধুমাত্র বর্তমান প্লাস্টিকের জন্য প্রযুক্ত।',
			'messages.serverUnavailableForProfile' => 'কোন সার্ভার সক্রিয় প্রোফাইলের জন্য উপলব্ধ নয়',
			'subtitlingStyling.previewSample' => 'দ্রুত ব্রোড ফক্স পাখি পাখি পাখি পাখি পাখি পাখি',
			'subtitlingStyling.text' => 'টেক্ট',
			'subtitlingStyling.border' => 'সীমানা',
			'subtitlingStyling.background' => 'ফাউন্ডেশন',
			'subtitlingStyling.fontSize' => 'ফটন মাত্রা',
			'subtitlingStyling.textColor' => 'টেক্সট রঙ',
			'subtitlingStyling.borderSize' => 'সীমানা বড়',
			'subtitlingStyling.borderColor' => 'সীমানা রঙ',
			'subtitlingStyling.backgroundOpacity' => 'ফাউন্ডেশন অপসারণতা',
			'subtitlingStyling.backgroundColor' => 'পৃথিবী রঙ',
			'subtitlingStyling.position' => 'অবস্থান',
			'subtitlingStyling.assOverride' => 'ASS অতিরিক্ত',
			'subtitlingStyling.overrideScale' => 'স্কুল',
			'subtitlingStyling.overrideForce' => 'শক্তি',
			'subtitlingStyling.overrideStrip' => 'স্টাইলিং মুছে ফেলুন',
			'subtitlingStyling.positionTop' => 'শীর্ষ',
			'subtitlingStyling.positionBottom' => 'নম্বরে',
			'subtitlingStyling.useMargins' => 'Margin ব্যবহার করুন',
			'subtitlingStyling.useMarginsDescription' => 'ভিডিওের বাইরে ভিত্তিতে টেক্সট সাবটাইটগুলি অনুমতি দিন. স্টাইলিত সাবটাইটগুলি তাদের মূল স্থাপন রাখতে পারে।',
			'subtitlingStyling.anchorToScreen' => 'স্ক্রিনের জন্য Anchor',
			'subtitlingStyling.anchorToScreenDescription' => 'বিল্ড স্ক্রিন ভিডিও এর নীচে ব্ল্যাক বারগুলিতে টেক্সট সাবটাইটগুলি দেখুন',
			'subtitlingStyling.bold' => 'সাহসী',
			'subtitlingStyling.italic' => 'ইতালিক',
			'subtitlingStyling.renderResolution' => 'রেন্ডার রেজলিউশন',
			'subtitlingStyling.renderResolutionScreen' => 'স্ক্রিন রেজুলেশন',
			'subtitlingStyling.renderResolutionVideo' => 'ভিডিও রেজুলেশন',
			'subtitlingStyling.fontSizeDescription' => 'এই ডিভাইসে নম্বর টেক্সট মাত্রা নির্ধারণ করুন।',
			'subtitlingStyling.textColorDescription' => 'Subtitle টেক্সটের জন্য ব্যবহৃত রঙ নির্বাচন করুন।',
			'subtitlingStyling.borderSizeDescription' => 'Subtitle টেক্সটের চারপাশে উত্পাদন গভীরতা স্থাপন করুন।',
			'subtitlingStyling.borderColorDescription' => 'নম্বরের জন্য ব্যবহৃত রঙ নির্বাচন করুন।',
			'subtitlingStyling.backgroundColorDescription' => 'পৃথিবীর পিছনে রঙ নির্বাচন করুন।',
			'subtitlingStyling.backgroundOpacityDescription' => 'সীমাবদ্ধ করুন কতটুকু দৃঢ়: 0 শতাংশ পরিষ্কার এবং 100% স্থিতিশীল।',
			'subtitlingStyling.positionDescription' => '0 শতাংশ ভিডিওের শীর্ষ এবং 100% ডান।',
			'subtitlingStyling.assOverrideDescription' => 'খেলোয়াড়টি অনুসরণ, সংশোধন, পরিবর্তন বা ASS সাবটাইটে ভিত্তিতে স্টাইলিং মুছে ফেলে কিনা নির্বাচন করুন।',
			'subtitlingStyling.assOverrideOptions.no' => 'ফটোগুলি, রঙ, আকার এবং স্থানান্তর লিখিত রাখুন subtitle ফাইলে।',
			'subtitlingStyling.assOverrideOptions.yes' => 'খেলোয়াড়ের subtitle স্টাইল সেটিংগুলি ASS subtitles সংশোধন করার অনুমতি দেয়।',
			'subtitlingStyling.assOverrideOptions.scale' => 'ভিডিও মাত্রা পূরণ করার জন্য খেলোয়াড় স্টাইলিং এবং ভেঙে গঠিত আকারগুলি প্রয়োগ করুন।',
			'subtitlingStyling.assOverrideOptions.force' => 'অভ্যন্তরীণ ASS স্টাইলগুলি খেলোয়াড়ের subtitle স্টাইল দ্বারা পরিবর্তন করুন।',
			'subtitlingStyling.assOverrideOptions.strip' => 'ভিত্তিতে ASS ফর্মেটিং সরবরাহ করুন এবং সাব্টিটি টেক্সট পরিষ্কারভাবে রূপান্তর করুন।',
			'subtitlingStyling.renderResolutionDescription' => 'চিত্র ও ASS সাবটাইটেলকে পিক্সেলে রূপান্তরের জন্য ব্যবহৃত রেজোলিউশন বেছে নিন। অ্যান্ড্রয়েডে কম স্কেল রেন্ডারিং কমাতে পারে, তবে ছবি কিছুটা নরম দেখাবে।',
			'subtitlingStyling.renderResolutionOptions.screen' => 'সবচেয়ে উজ্জ্বল ফলাফলের জন্য পুরো প্রদর্শন পৃথিবী রেজুলেশনতে রেন্ডার।',
			'subtitlingStyling.renderResolutionOptions.video' => 'ভিডিও রেজিউশন ব্যবহার করে ফ্রেন্ড, যা উচ্চ সনাক্ততা ডিভাইসগুলিতে কাজ কমাতে পারে।',
			'subtitlingStyling.renderResolutionOptions.threeQuarter' => 'প্রদর্শন পৃথিবীর সনাক্ততা 75 শতাংশের জন্য নিম্ন কর্মক্ষমতা সংরক্ষণ।',
			'subtitlingStyling.renderResolutionOptions.half' => '50 শতাংশ প্রদর্শনের পৃথিবী রেজুলেশনের জন্য কাজ কমাতে, মধুর দিকগুলি সঙ্গে।',
			'subtitlingStyling.renderResolutionOptions.third' => 'একটি তৃতীয়াংশ প্রদর্শনের পৃথিবী রেজুল্যকরণের জন্য কাজ কমাতে, মধুর দিকে।',
			'subtitlingStyling.renderResolutionOptions.quarter' => 'দৃশ্য পৃথিবীর রেজুলেশন একটি তৃতীয়াংশের জন্য কাজ কমাতে, সবচেয়ে মধুর ফলাফল সঙ্গে।',
			'subtitlingStyling.boldDescription' => 'একটি গুরুতর ওজনে subtitle টেক্সট ড্রাইভ করুন।',
			'subtitlingStyling.italicDescription' => 'ইতালিক ভাষায় টেক্সট ড্রাইভ করুন।',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'উন্নত ভিডিও খেলোয়াড় সেটিংস',
			'mpvConfig.presets' => 'প্রজাতন',
			'mpvConfig.noPresets' => 'সুরক্ষিত প্রজাতন নেই',
			'mpvConfig.saveAsPreset' => 'প্রসেস্ট হিসেবে রক্ষা করুন।',
			'mpvConfig.presetName' => 'প্রজেক্ট নাম',
			'mpvConfig.presetNameHint' => 'এই প্রসেস্টের জন্য একটি নাম লিখুন',
			'mpvConfig.loadPreset' => 'লোড',
			'mpvConfig.deletePreset' => 'মুছে ফেলুন',
			'mpvConfig.presetSaved' => 'সুরক্ষিত',
			'mpvConfig.presetLoaded' => 'পূর্বাভাস লোড',
			'mpvConfig.presetDeleted' => 'পূর্বাভাস 삭제',
			'mpvConfig.confirmDeletePreset' => 'আপনি কি নিশ্চিত যে আপনি এই প্রসেস্ট মুছে ফেলতে চান?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan hwdec=auto # মন্তব্য',
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => 'লাইন যোগ করুন',
			'mpvConfig.removeLine' => 'লাইন মুছে ফেলে',
			'mpvConfig.embeddedVoHint' => 'vo, gpu-context এবং gpu-api Linux এর উপর ignored: ভিত্তিক ভিডিও সবসময় ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তিক ভিত্তি।',
			'dialog.confirmAction' => 'কার্যক্রম নিশ্চিত করুন',
			'profiles.addPlezyProfile' => 'PlezyNG প্রোফাইল যোগ করুন',
			'profiles.switchingProfile' => 'ফোফাইল পরিবর্তন...',
			'profiles.deleteThisProfileTitle' => 'এই প্রোফাইলটি মুছে ফেলুন?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => '${displayName} সরিয়ে দিন। সংযোগগুলি প্রভাবিত হবে না।',
			'profiles.active' => 'আক্রমণ',
			'profiles.manage' => 'পরিচালনা',
			'profiles.delete' => 'মুছে ফেলুন',
			'profiles.signOut' => 'সাইন আউট',
			'profiles.signOutPlexTitle' => 'Plex এর নামে চিহ্নিত করুন।',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'মুছে ফেলুন ${displayName} এবং সব Plex Home ব্যবহারকারীদের? কোনও সময়ে ফিরে সাইন আপ করুন।',
			'profiles.signOutPlexDeleteDownloads' => 'ডাউনলোড করুনও',
			'profiles.signOutPlexDeleteDownloadsDescription' => 'অন্যথায়, তারা এই ডিভাইসে থাকবে এবং আপনি এই অ্যাকাউন্টে ফিরে যখন ফিরে যান।',
			'profiles.signedOutPlex' => 'সেখানে আবেদন করা হয়েছে Plex।',
			'profiles.signOutFailed' => 'হঠাৎ হঠাৎ হঠাৎ হঠাৎ।',
			'profiles.sectionTitle' => 'প্রোফাইল',
			'profiles.summarySingle' => 'পরিচালিত ব্যবহারকারীদের এবং স্থানীয় পরিচয়গুলি মিশে প্রোফাইল যোগ করুন',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} প্রোফাইল · কার্যকর: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} প্রোফাইল',
			'profiles.removeConnectionTitle' => 'সংযোগ বন্ধ করুন ?',
			'profiles.removeConnectionMessage' => ({required Object connectionLabel, required Object displayName}) => '${connectionLabel}-এ ${displayName}-এর অ্যাক্সেস সরিয়ে দিন। অন্য প্রোফাইলগুলির অ্যাক্সেস থাকবে।',
			'profiles.deleteProfileTitle' => 'প্রোফাইল ভেঙে?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => '${displayName} এবং তার সংযোগগুলি মুছে ফেলুন. সার্ভারগুলি পাওয়া যায়।',
			'profiles.profileNameLabel' => 'প্রোফাইল নাম',
			'profiles.pinProtectionLabel' => 'PIN সুরক্ষা',
			'profiles.copyAutomationLink' => 'কপি Android স্বয়ংক্রিয় লিঙ্ক',
			'profiles.copyAutomationLinkDescription' => 'এই প্রোফাইলটি Android ইন্টেন্ট বা অটোমেশন থেকে নির্বাচন করুন. প্রোফাইল পিন চেক এখনও প্রয়োগ করা হয়.',
			'profiles.automationLinkCopied' => 'প্রোফাইল স্বয়ংক্রিয় লিঙ্ক কপি করা হয়েছে।',
			'profiles.pinManagedByPlex' => 'পিন Plex দ্বারা পরিচালিত হয় Edit on plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'কোন PIN সেট নেই. একটি প্রয়োজন হলে, plex.tv-এ হোম ব্যবহারকারীটি সংশোধন করুন।',
			'profiles.setPin' => 'PIN সিস্টেম',
			'profiles.setPinTitle' => 'PIN সিস্টেম',
			'profiles.confirmPinTitle' => 'PIN সনাক্ত করুন',
			'profiles.pinSet' => 'পিন সেট',
			'profiles.changePin' => 'পরিবর্তন',
			'profiles.removePin' => 'সরান',
			'profiles.connectionsLabel' => 'সংযোগ',
			'profiles.add' => 'যোগ',
			'profiles.deleteProfileButton' => 'প্রোফাইল মুছে ফেলে',
			'profiles.noConnectionsHint' => 'কোন সংযোগ নেই — এই প্রোফাইল ব্যবহার করার জন্য একটি যোগ করুন।',
			'profiles.noConnections' => 'কোন সংযোগ নেই',
			'profiles.plexHomeAccount' => 'Plex বাড়ি অ্যাকাউন্ট',
			'profiles.plexAccountChip' => ({required Object account}) => 'Plex অ্যাকাউন্ট: ${account}',
			'profiles.plexAccountUserChip' => ({required Object user, required Object account}) => '${user} এর মাধ্যমে ${account}',
			'profiles.connectionDefault' => 'প্রত্যাশিত',
			'profiles.connectionAs' => ({required Object displayName}) => '${displayName} হিসেবে',
			'profiles.makeDefault' => 'ভেঙে ফেলুন',
			'profiles.removeConnection' => 'সরান',
			'profiles.profileRenamed' => 'প্রোফাইলের নাম।',
			'profiles.borrowAddTo' => ({required Object displayName}) => '${displayName} এর জন্য যোগ করুন',
			'profiles.borrowExplain' => 'অন্য প্রোফাইলের সংযোগের লেনদেন করুন. PIN-প্রোফাইলগুলি একটি PIN প্রয়োজন।',
			'profiles.borrowEmpty' => 'এখনো কোনও টাকা না δανειστεί করতে হবে।',
			'profiles.borrowEmptySubtitle' => 'Plex, Jellyfin বা Emby এর সাথে অন্য প্রোফাইলের সাথে প্রথম যোগাযোগ করুন।',
			'profiles.borrowLoadFailed' => 'এখানে কোনো সংযোগ চালানো যাবে না, আবার চেষ্টা করুন।',
			'profiles.borrowFromProfile' => ({required Object displayName}) => '${displayName} থেকে',
			'profiles.borrowConnectionBorrowed' => 'লেনদেন করা হয়েছে।',
			'profiles.borrowFailed' => 'লেনদেনের সংযোগটি অসম্ভব।',
			'profiles.incorrectPin' => 'পিন ভুল।',
			'profiles.incorrectPinTryAgain' => 'পিনটি ভুল করে, আবারও চেষ্টা করুন।',
			'profiles.sourceProfileMissingParentAccount' => 'পৃথিবীর পৃথিবীর পৃথিবীর পৃথিবীর পৃথিবীর পৃথিবীর পৃথিবীর পৃথিবীর পৃথিবীর পৃথিবীর পৃথিবীর পৃথিবী।',
			'profiles.failedToLoadHomeUsers' => 'আপনার Plex Home ব্যবহারকারীদের লোড করতে পারেন না. আপনার সংযোগ চেক করুন এবং আবার চেষ্টা করুন.',
			'profiles.failedToVerifyPin' => 'পিন সনাক্ত করতে পারিনি।',
			'profiles.newProfile' => 'নতুন প্রোফাইল',
			'profiles.profileNameHint' => 'উদাহরণস্বরূপ, গ্রাহক, শিশু, পরিবার রুম',
			'profiles.pinProtectionOptional' => 'PIN সুরক্ষা (অন্যাশনাল)',
			'profiles.pinExplain' => '4 ডিগ্রী পিন ব্যবহার করতে হবে।',
			'profiles.continueButton' => 'চলুন',
			'profiles.pinsDontMatch' => 'পিনস পেমেন্ট নয়',
			'profiles.tokenIdentityMismatch' => 'Plex প্রোফাইল টকেন অপেক্ষা সার্ভারের জন্য সমাধান',
			'profiles.settingsLocked' => 'এই প্রোফাইলের জন্য সেটিংস বন্ধ করা হয়।',
			'profiles.unlockSettings' => 'ডাউনলোড সিস্টেম',
			'profiles.showExploreForProfile' => 'দেখুন এই প্রোফাইলের জন্য গবেষণা',
			'profiles.showExploreForProfileDescription' => 'এই প্রোফাইলের নৌকা থেকে Explore মুছে ফেলতে বন্ধ করুন।',
			'connections.sectionTitle' => 'সংযোগ',
			'connections.addConnection' => 'সংযোগ যোগ করুন',
			'connections.addConnectionSubtitleNoProfile' => 'Plex এর সাথে সাইন আপ করুন বা Jellyfin বা Emby সার্ভারের সাথে সংযোগ করুন',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => '${displayName}: Plex, Jellyfin, Emby, বা অন্য প্রোফাইল সংযোগে যোগ করুন',
			'connections.sessionExpiredOne' => ({required Object name}) => 'সংখ্যা: ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'সার্ভার ${count} জন্য সেশন শেষ',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} এই অ্যাকাউন্টের জন্য অ্যাক্সেস বাতিল',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} সার্ভার এই অ্যাকাউন্টের জন্য অ্যাক্সেস বাতিল',
			'connections.signInAgain' => 'আবার লিখুন',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'Edit ${product} সংযোগ',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => '${serverName} এর জন্য URLগুলি যোগ করুন বা মুছে ফেলুন. PlezyNG সবচেয়ে কম ল্যাটিংসের সাথে পৌঁছাতে পারে URLগুলি ব্যবহার করবে।',
			'accountPreferences.sectionTitle' => 'অ্যাকাউন্ট পছন্দ',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => 'অডিও, সাবটাইট এবং লাইব্রেরি বিকল্পগুলি ${account} এ সংরক্ষিত',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => 'অডিও, সাবটাইট এবং লাইব্রেরি বিকল্পগুলি ${count} অ্যাকাউন্টগুলিতে সংরক্ষিত',
			'accountPreferences.pickAccount' => 'প্রতিটি অ্যাকাউন্ট তার নিজের প্রিয়মেন্টগুলি সংরক্ষণ করে. সংশোধন করার জন্য একটি নির্বাচন করুন.',
			'accountPreferences.storedOnAccount' => 'এই অ্যাকাউন্টের নিজে থেকে এই অ্যাকাউন্টগুলি সংরক্ষণ করা হয়, তাই এতে প্রবেশিত প্রতিটি অ্যাপটি তাদের ব্যবহার করে - আপনার অন্যান্য ডিভাইসগুলিতে PlezyNG অন্তর্ভুক্ত।',
			'accountPreferences.noAccounts' => 'কোন অ্যাকাউন্ট সংগঠন করা যায় না',
			'accountPreferences.noAccountsHint' => 'Plex এ প্রবেশ করুন, অথবা Jellyfin বা Emby সার্ভারের সাথে সংযোগ করুন, এবং এই অ্যাকাউন্টে সংরক্ষিত পছন্দগুলি এখানে প্রদর্শন করা হয়।',
			'accountPreferences.unavailable' => 'এই অ্যাকাউন্টে পৌঁছাতে পারবেন না',
			'accountPreferences.loadFailed' => 'এই পছন্দগুলি আপলোড করতে পারবেন না',
			'accountPreferences.noPreference' => 'কোন প্রিয়তা নেই',
			'accountPreferences.notSet' => 'সিস্টেম না',
			'accountPreferences.groups.audioAndSubtitles' => 'অডিও & Subtitles',
			'accountPreferences.groups.libraryDisplay' => 'লাইব্রেরি',
			'accountPreferences.groups.personalMedia' => 'ব্যক্তিগত মিডিয়া',
			'accountPreferences.preferredAudioLanguage' => 'অডিও ভাষা প্রিয়',
			'accountPreferences.autoSelectAudio' => 'ভাষা অনুযায়ী অডিও নির্বাচন করুন',
			'accountPreferences.autoSelectAudioDescription' => 'কোনও অডিও ট্র্যাক ফাইলটি ডিফল্ট হিসাবে চিহ্নিত রাখে।',
			'accountPreferences.preferredSubtitleLanguage' => 'পছন্দের ভাষা Subtitle',
			'accountPreferences.subtitleMode' => 'Subtitles এর উপর',
			'accountPreferences.subtitleModes.none' => 'ম্যানুয়াল নির্বাচন',
			'accountPreferences.subtitleModes.noneDescription' => 'কখনো নিজেদের উপর সাবতিটার ফাঁস করবেন না।',
			'accountPreferences.subtitleModes.defaultMode' => 'ট্র্যাক ফ্যাগ অনুসরণ করুন',
			'accountPreferences.subtitleModes.defaultModeDescription' => 'প্রত্যেক সাব্টাইট ট্র্যাকে সংরক্ষিত ডিফল্ট এবং জরুরি ফ্যাগ ব্যবহার করুন।',
			'accountPreferences.subtitleModes.always' => 'সবসময় অনুমোদিত',
			'accountPreferences.subtitleModes.alwaysDescription' => 'প্রিয় ভাষায় একটি সাব্টাইট ট্র্যাকে যখন কোনটি থাকে তখন বের করুন।',
			'accountPreferences.subtitleModes.onlyForced' => 'শুধুমাত্র নির্যাতন টাইম',
			'accountPreferences.subtitleModes.onlyForcedDescription' => 'শুধুমাত্র জরুরি হিসাবে চিহ্নিত পথগুলি লোড করুন।',
			'accountPreferences.subtitleModes.smart' => 'বিদেশী অডিও সঙ্গে সনাক্ত',
			'accountPreferences.subtitleModes.smartDescription' => 'শুধুমাত্র অডিওটি অন্য ভাষায় থাকলে সাবটাইটগুলি পুনরাবৃত্তি করুন।',
			'accountPreferences.subtitleAccessibility' => 'SDH সাব্টিটিস',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'অ-এসডিএইচ সাব্টিটিস প্রিয়',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'SDH সাব্টিটিস প্রিয়',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'শুধুমাত্র SDH সাব্টিটিল',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'শুধু অ-SDH সাব্টিটিল',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdhDescription' => 'Standard subtitles পছন্দ করে যখন স্ট্যান্ডার্ড এবং SDH সংস্করণগুলি উভয় পাওয়া যায়।',
			'accountPreferences.subtitleAccessibilityOptions.preferSdhDescription' => 'SDH সাবটাইটিলগুলি পছন্দ করে যখন পাওয়া যায়, তবে একটি Fallback হিসাবে স্ট্যান্ডার্ড সাবিটাইলগুলি অনুমতি দেয়।',
			'accountPreferences.subtitleAccessibilityOptions.onlySdhDescription' => 'শুধুমাত্র SDH সাবটাইটিল ব্যবহার করুন; স্ট্যান্ডার্ড সাব্টিটেলগুলিতে ফিরে আসবেন না।',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdhDescription' => 'শুধুমাত্র স্ট্যান্ডার্ড সাবটাইটিল ব্যবহার করুন; SDH সাব্টিটেলগুলি বাদ দেবেন।',
			'accountPreferences.forcedSubtitles' => 'নির্যাতন সূত্র',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'অস্বীকারিত সূত্রগুলি পছন্দ করি',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'জরুরি টাইমগুলি পছন্দ',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'শুধুমাত্র নির্যাতন টাইম',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'শুধুমাত্র নির্যাতন সূত্র',
			'accountPreferences.forcedSubtitleOptions.preferNonForcedDescription' => 'নিয়মিত সাবটাইটিলগুলি পছন্দ করে, কিন্তু ফাঁসের হিসাবে জরুরি ট্র্যাক অনুমতি দেয়।',
			'accountPreferences.forcedSubtitleOptions.preferForcedDescription' => 'যখন উপলব্ধ হয়, তখন জরুরি ট্র্যাকগুলি পছন্দ করে, কিন্তু একটি Fallback হিসাবে নিয়মিত নীতিগুলি অনুমতি দেয়।',
			'accountPreferences.forcedSubtitleOptions.onlyForcedDescription' => 'শুধুমাত্র জরুরি হিসাবে চিহ্নিত ট্র্যাক ব্যবহার করুন।',
			'accountPreferences.forcedSubtitleOptions.onlyNonForcedDescription' => 'বাধ্যতামূলক হিসাবে চিহ্নিত রাস্তার বাইরে রাখুন।',
			'accountPreferences.displayMissingEpisodes' => 'হারিয়ে যাওয়া ঘটনা দেখুন',
			'accountPreferences.displayMissingEpisodesDescription' => 'তালিকাভুক্ত পরিস্থিতিগুলি সার্ভার সম্পর্কে জানে কিন্তু ফাইল নেই।',
			'accountPreferences.hidePlayedInLatest' => 'সর্বশেষ নিবন্ধে দেখানো পণ্য মেরে',
			'accountPreferences.hidePlayedInLatestDescription' => 'আপনি সার্ভার সর্বশেষ রানগুলি থেকে আগেই দেখেছেন পণ্যগুলি বের করুন।',
			'accountPreferences.displayCollectionsView' => 'সংগ্রহের দৃশ্য দেখুন',
			'accountPreferences.displayCollectionsViewDescription' => 'সার্ভারের সংগ্রহগুলি দেখার জন্য আপনার লাইব্রেরিগুলির পাশে সরবরাহ করুন।',
			'accountPreferences.rewatchingInNextUp' => 'পরবর্তী পরবর্তী পরবর্তী পরবর্তী পরবর্তী পরবর্তী',
			'accountPreferences.rewatchingInNextUpDescription' => 'একবার আপনি একটি প্রদর্শন শেষ করে, এটি আবার শুরু করুন এবং পরবর্তী প্রদর্শনের পরিবর্তে পরবর্তী প্রদর্শন অনুসরণ করে।',
			'accountPreferences.watchedIndicator' => 'দেখে নিন প্রদর্শক',
			'accountPreferences.watchedIndicatorOptions.none' => 'কখনো',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => 'চলচ্চিত্র ও টেলিভিশন প্রদর্শন',
			'accountPreferences.watchedIndicatorOptions.movies' => 'শুধু চলচ্চিত্র',
			'accountPreferences.watchedIndicatorOptions.shows' => 'টেলিভিশন শুধু',
			'accountPreferences.watchedIndicatorOptions.noneDescription' => 'দেখানো চেকমার্ক দেখান না।',
			'accountPreferences.watchedIndicatorOptions.moviesAndShowsDescription' => 'চলচ্চিত্র এবং টেলিভিশন প্রদর্শনের জন্য দেখানো চেকমার্ক।',
			'accountPreferences.watchedIndicatorOptions.moviesDescription' => 'শুধুমাত্র চলচ্চিত্রের জন্য চেকমার্ক দেখুন।',
			'accountPreferences.watchedIndicatorOptions.showsDescription' => 'শুধু টেলিভিশন প্রদর্শনের জন্য দেখানো চেকমার্ক।',
			'accountPreferences.mediaReviewsVisibility' => 'রিটিং & বিবেচনা',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'ব্যবহারকারী এবং সমালোচনাকারী',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'শুধু ব্যবহারকারী',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'শুধু সমালোচনা',
			'accountPreferences.mediaReviewsOptions.nobody' => 'গোপন',
			'accountPreferences.mediaReviewsOptions.usersAndCriticsDescription' => 'ব্যবহারকারীর তদন্ত এবং সমালোচক তালিকা প্রদর্শন করুন।',
			'accountPreferences.mediaReviewsOptions.usersOnlyDescription' => 'ব্যবহারকারীদের দ্বারা প্রদান করা রেটিং এবং বিশ্লেষণ দেখুন।',
			'accountPreferences.mediaReviewsOptions.criticsOnlyDescription' => 'সমালোচনীয় তদন্ত এবং বিশ্লেষণ দেখুন।',
			'accountPreferences.mediaReviewsOptions.nobodyDescription' => 'তদন্ত ও বিশ্লেষণ ঘুরে রাখুন।',
			'accountPreferences.preferredAudioLanguageDescription' => 'সার্ভার বা প্লেয়ার স্বয়ংক্রিয়ভাবে ট্র্যাক বেছে নিলে এই ভাষার অডিও ট্র্যাককে অগ্রাধিকার দিন।',
			'accountPreferences.preferredSubtitleLanguageDescription' => 'স্বয়ংক্রিয়ভাবে নিম্নলিখিত অনুসরণগুলি এই ভাষায় পছন্দ করা হয়, যখন নিম্নিটিগুলি নির্বাচন করা হয়।',
			'accountPreferences.subtitleAccessibilityDescription' => 'স্বয়ংক্রিয় সাব্টাইট নির্বাচন করার সময় SDH ক্যাপশনগুলি পছন্দ করা হয় বা প্রয়োজন হয় কিনা সিদ্ধান্ত নিতে হবে।',
			'accountPreferences.forcedSubtitleDescription' => 'স্বয়ংক্রিয়ভাবে ট্র্যাক বেছে নেওয়ার সময় ফোর্সড সাবটাইটেল পছন্দ হবে নাকি অবশ্যই ব্যবহার করতে হবে, তা বেছে নিন।',
			'accountPreferences.watchedIndicatorDescription' => 'সার্ভার ইন্টারফেসে কোন মিডিয়া টাইপগুলি একটি অনুসন্ধানিত চেকমার্ক পাবেন নির্বাচন করুন।',
			'accountPreferences.mediaReviewsVisibilityDescription' => 'নির্বাচন করুন যে সার্ভার মিডিয়া পৃষ্ঠাগুলিতে প্রদর্শিত аудитории এবং মূল্যায়ন।',
			'accountPreferences.subtitleModeDescription' => 'এই সার্ভার অ্যাকাউন্টের জন্য স্বয়ংক্রিয়ভাবে কখন উপ-টাইটিল চালু হয় তা নির্বাচন করুন।',
			'accountPreferences.hubDescription' => 'এই পছন্দগুলো আপনার মিডিয়া সার্ভার অ্যাকাউন্টে সংরক্ষিত থাকে এবং অন্যান্য ক্লায়েন্টেও প্রযোজ্য হতে পারে।',
			'discover.title' => 'খোঁজ',
			'discover.noContentAvailable' => 'কোন উপাদান পাওয়া যায় না',
			'discover.addMediaToLibraries' => 'আপনার লাইব্রেরিতে কিছু মিডিয়া যোগ করুন',
			'discover.continueWatching' => 'দেখা অব্যাহত রাখুন',
			'discover.continueWatchingIn' => ({required Object library}) => 'এখনও দেখুন ${library}',
			'discover.nextUp' => 'পরবর্তী',
			'discover.nextUpIn' => ({required Object library}) => 'পরবর্তী সংবাদ ${library}',
			'discover.recentlyAdded' => 'সম্প্রতি যোগ করা',
			'discover.recentlyAddedIn' => ({required Object library}) => 'সম্প্রতি যোগ করা হয়েছে ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => 'সর্বশেষ অ্যালবামগুলি ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'সম্প্রতি খেলা ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'সবচেয়ে বেশি খেলা ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'সিজন ${season} পর্ব ${episode}',
			'discover.overview' => 'বিবরণ',
			'discover.cast' => 'কাস্ট',
			'discover.findNext.title' => 'পরের পছন্দটি খুঁজুন',
			'discover.findNext.open' => 'পরের পছন্দটি খুঁজুন',
			'discover.findNext.anyTime' => 'সময়ের সীমা নেই',
			'discover.findNext.timeAvailable' => 'আপনার হাতে কতটা সময় আছে?',
			'discover.findNext.filters' => 'এই মুহূর্তের জন্য বেছে নিন',
			'discover.findNext.watch' => 'দেখুন',
			'discover.findNext.listen' => 'শুনুন',
			'discover.findNext.read' => 'পড়ুন',
			'discover.findNext.finishable' => ({required Object duration}) => '${duration}-এর মধ্যে শেষ করা যাবে',
			'discover.findNext.aboutDuration' => ({required Object duration}) => 'প্রায় ${duration}',
			'discover.findNext.nextUnit' => ({required Object duration}) => 'পরের অধ্যায় · ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => 'মোট ${duration}',
			'discover.findNext.timingVaries' => 'সময় কমবেশি হতে পারে',
			'discover.findNext.notNow' => 'এখন নয়',
			'discover.findNext.swipeHint' => 'প্রচ্ছদটি কোনো তিরের দিকে সোয়াইপ করুন বা নিচের বোতাম ব্যবহার করুন।',
			'discover.findNext.saved' => 'সংরক্ষিত পছন্দ',
			'discover.findNext.savedCount' => ({required Object count}) => 'সংরক্ষিত পছন্দ · ${count}',
			'discover.findNext.undo' => 'পূর্বাবস্থায় ফেরান',
			'discover.findNext.details' => 'বিস্তারিত',
			'discover.findNext.noPicks' => 'বেছে নেওয়ার মতো কিছু এখনো নেই',
			'discover.findNext.noPicksHint' => 'শুরু করতে একটি লাইব্রেরি সংযুক্ত করুন অথবা মিডিয়ার উৎস যোগ করুন।',
			'discover.findNext.noMatches' => 'এই মুহূর্তের জন্য উপযুক্ত কিছু নেই',
			'discover.findNext.noMatchesHint' => 'অন্য ধরনের মিডিয়া বেছে নিন অথবা আরও কিছুটা সময় রাখুন।',
			'discover.findNext.allDone' => 'সব প্রস্তাব দেখা হয়ে গেছে',
			'discover.findNext.allDoneHint' => 'এই পছন্দগুলো আবার দেখতে নতুন একটি তালিকা তৈরি করুন।',
			'discover.findNext.refresh' => 'আরেকটি তালিকা খুঁজুন',
			'discover.findNext.sourceReason' => ({required Object source}) => 'উৎস: ${source}',
			'discover.findNext.libraryReason' => ({required Object library}) => 'লাইব্রেরি: ${library}',
			'discover.findNext.ownedReason' => 'আপনার লাইব্রেরি থেকে',
			'discover.findNext.liveNow' => 'এখন সম্প্রচারিত হচ্ছে',
			'discover.findNext.watchLive' => 'সরাসরি দেখুন',
			'discover.findNext.filterAnything' => 'যেকোনোটি',
			'discover.findNext.filterWatch' => 'দেখুন',
			'discover.findNext.filterListen' => 'শুনুন',
			'discover.findNext.filterRead' => 'পড়ুন',
			'discover.findNext.twentyMinutes' => '২০ মিনিট',
			'discover.findNext.fortyFiveMinutes' => '৪৫ মিনিট',
			'discover.findNext.ninetyMinutes' => '৯০ মিনিট',
			'discover.findNext.apply' => 'প্রয়োগ করুন',
			'discover.findNext.openFailed' => 'এই পছন্দটি আর পাওয়া যাচ্ছে না। আবার যাচাই করতে রিফ্রেশ করুন।',
			'discover.findNext.changeFailed' => 'পরিবর্তনটি সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।',
			'discover.findNext.savedLimit' => 'সংরক্ষিত পছন্দের তালিকা পূর্ণ। আরেকটি সংরক্ষণ করতে একটি পছন্দ সরিয়ে দিন।',
			'discover.findNext.chooseHint' => 'কোনো শিরোনাম খুলুন, পরের জন্য সংরক্ষণ করুন বা এড়িয়ে যান।',
			'discover.findNext.howItWorks' => 'ব্যবহারের নিয়ম',
			'discover.findNext.notNowHelp' => 'এই শিরোনামটি আপাতত এড়িয়ে যান। এটি আপনার লাইব্রেরিতে থাকবে।',
			'discover.findNext.saveHelp' => 'এই ডিভাইসে এই প্রোফাইলের সংরক্ষিত পছন্দে রাখুন। সংরক্ষণ করলে ডাউনলোড হয় না।',
			'discover.findNext.openHelp' => 'বিস্তারিত দেখতে প্রচ্ছদ নির্বাচন করুন। চালানো, পড়া বা খোলার জন্য প্রধান বোতাম ব্যবহার করুন।',
			'discover.findNext.controlsHelp' => 'কীবোর্ড বা রিমোট: একটি বোতামে যান, তারপর Enter বা নির্বাচন বোতাম চাপুন। পূর্বাবস্থায় ফেরালে শেষ পছন্দটি ফিরে আসে।',
			'discover.findNext.artworkLoading' => 'ছবি লোড হচ্ছে…',
			'discover.findNext.artworkUnavailable' => 'ছবি উপলব্ধ নয়',
			'discover.findNext.savedFeedback' => 'সংরক্ষিত পছন্দে যোগ করা হয়েছে',
			'discover.findNext.skippedFeedback' => 'আপাতত এড়িয়ে যাওয়া হয়েছে',
			'discover.findNext.releaseToConfirm' => 'নিশ্চিত করতে ছেড়ে দিন',
			'discover.findNext.remoteHint' => 'প্রচ্ছদে ফোকাস: ← / → বেছে নিন · নির্বাচন বোতাম: বিস্তারিত · ↑ / ↓ ফোকাস বদলান',
			'discover.extras' => 'ট্রাইলিং & অতিরিক্ত',
			'discover.studio' => 'স্টুডিও',
			'discover.rating' => 'রেটিং',
			'discover.director' => 'পরিচালক',
			'discover.directors' => 'পরিচালকবৃন্দ',
			'discover.movie' => 'চলচ্চিত্র',
			'discover.tvShow' => 'টেলিভিশন প্রদর্শন',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} মিনিট left',
			'discover.moreLikeThis' => 'এ ধরনের আরও',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} নাম', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} টাইম', ), 
			'discover.person.born' => 'জন্ম',
			'discover.person.died' => 'মৃত্যুর',
			'discover.person.birthplace' => 'জন্মস্থান',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date} (আজ ${age})',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date} (আজ ${age})',
			'errors.searchFailed' => ({required Object error}) => 'অনুসন্ধান ভুল হয়েছে: ${error}',
			'errors.searchUnavailable' => 'কোন মিডিয়া সার্ভারে অনুসন্ধান পাওয়া যায়নি।',
			'errors.connectionTimeout' => ({required Object context}) => 'লোডিং সময়মাত্রা ${context}',
			'errors.connectionFailed' => 'মিডিয়া সার্ভারের সাথে যোগাযোগ করতে পারবেন না',
			'errors.unableToLoad' => ({required Object context}) => '${context} পুনরায় চেষ্টা করুন।',
			'errors.noClientAvailable' => 'কোন গ্রাহক পাওয়া যায় না',
			'errors.pleaseEnterToken' => 'দয়া করে একটি টকেন লিখুন',
			'errors.invalidToken' => 'অসুবিধা টকেন',
			'errors.failedToVerifyToken' => ({required Object error}) => 'টকেন সনাক্ত করতে পারিনি: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'পাশাপাশি পাশাপাশি পাশাপাশি ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'অপসারণ করা হয় না ${displayName}',
			'errors.failedToRate' => 'Rating আপডেট করতে পারবেন না',
			'errors.reasonTimedOut' => 'সংযোগের সময় বের করা হয়েছে',
			'errors.reasonUnreachable' => 'সার্ভার পৌঁছাতে পারিনি।',
			'errors.reasonRefused' => 'সার্ভার এই অনুরোধটি অস্বীকার করেছে।',
			'errors.reasonNotFound' => 'আর সার্ভারে থাকে না।',
			'errors.reasonServerError' => 'সার্ভারটি ভুল জানায়',
			'errors.reasonCancelled' => 'অনুরোধ বাতিল করা হয়েছে',
			'errors.reasonUnexpected' => 'অপ্রত্যাশিত ভুল ঘটেছে।',
			'libraries.playRandomMovie' => 'একটি random movie খেলুন',
			'libraries.randomPickFailed' => 'এই লাইব্রেরি থেকে একটি অসাধারণ সিনেমা নির্বাচন করতে পারবেন না।',
			'libraries.title' => 'বইয়েরা',
			'libraries.fallbackTitle' => 'লাইব্রেরি',
			'libraries.scanLibraryFiles' => 'স্ক্যান লাইব্রেরি ফাইল',
			'libraries.scanLibrary' => 'স্ক্যান লাইব্রেরি',
			'libraries.analyze' => 'বিশ্লেষণ',
			'libraries.analyzeLibrary' => 'বিবেচনা লাইব্রেরি',
			'libraries.refreshMetadata' => 'মেটাদাডেট ফ্রিজ করুন',
			'libraries.emptyTrash' => 'ভূষণ ট্রাস',
			'libraries.emptyingTrash' => ({required Object title}) => '“${title}” এর জন্য মুক্ত পুষ্টি...',
			'libraries.trashEmptied' => ({required Object title}) => '‘${title}’ এর জন্য ট্র্যাশ প্রচারিত',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'ভেঙে ফাঁস করতে পারিনি: ${error}',
			'libraries.analyzing' => ({required Object title}) => '‘${title}’ তালিকাভুক্ত',
			'libraries.analysisStarted' => ({required Object title}) => '"${title}" জন্য বিশ্লেষণ শুরু',
			'libraries.failedToAnalyze' => ({required Object error}) => 'লাইব্রেরি বিশ্লেষণ করতে পারিনি: ${error}',
			'libraries.noLibrariesFound' => 'কোন লাইব্রেরি পাওয়া যায়নি',
			'libraries.allLibrariesHidden' => 'সব লাইব্রেরি ভেঙে গেছে',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'লুকানো লাইব্রেরি (${count})',
			'libraries.thisLibraryIsEmpty' => 'এই লাইব্রেরি ভেঙে গেছে',
			'libraries.noItemsMatchFilters' => 'কোন পণ্য সক্রিয় ফিল্টার সমাধান না',
			'libraries.resetFilters' => 'ফিল্টার ফিল্টার',
			'libraries.all' => 'সবগুলি',
			'libraries.clearAll' => 'সবকিছু পরিষ্কার',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'আপনি কি নিশ্চিত যে আপনি "${title}" স্ক্যান করতে চান?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'আপনি কি নিশ্চিত যে আপনি "${title}" বিশ্লেষণ করতে চান?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'আপনি কি "${title}" জন্য metadata আপডেট করতে চান তা নিশ্চিত?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'আপনি কি "${title}" এর জন্য শূন্য বর্জ্য খুঁজে পেতে চান?',
			'libraries.manageLibraries' => 'লাইব্রেরি পরিচালনা',
			'libraries.sort' => 'সারাদেশ',
			'libraries.sortBy' => 'সারাদেশে',
			'libraries.filters' => 'ফিল্টারগুলি',
			'libraries.confirmActionMessage' => 'আপনি কি নিশ্চিত যে আপনি এই কাজটি করতে চান?',
			'libraries.showLibrary' => 'লাইব্রেরি দেখুন',
			'libraries.hideLibrary' => 'কবর লাইব্রেরি',
			'libraries.libraryOptions' => 'লাইব্রেরি বিকল্প',
			'libraries.content' => 'লাইব্রেরি বিষয়বস্তু',
			_ => null,
		} ?? switch (path) {
			'libraries.selectLibrary' => 'লাইব্রেরি নির্বাচন',
			'libraries.filtersWithCount' => ({required Object count}) => 'ফিল্টার (${count})',
			'libraries.noRecommendations' => 'উপলব্ধি নেই',
			'libraries.noCollections' => 'এই লাইব্রেরিতে কোন সংগ্রহ নেই',
			'libraries.noFoldersFound' => 'কোন ফাইল পাওয়া যায়নি',
			'libraries.folders' => 'ফোল্ডার',
			'libraries.tabs.recommended' => 'পরামর্শ',
			'libraries.tabs.browse' => 'ব্রাউজ',
			'libraries.tabs.collections' => 'কালেকশন',
			'libraries.tabs.playlists' => 'খেলোয়াড়',
			'libraries.groupings.title' => 'গ্রুপিং',
			'libraries.groupings.all' => 'সবগুলি',
			'libraries.groupings.movies' => 'চলচ্চিত্র',
			'libraries.groupings.shows' => 'টেলিভিশন প্রদর্শন',
			'libraries.groupings.seasons' => 'সপ্তাহ',
			'libraries.groupings.episodes' => 'পর্বগুলি',
			'libraries.groupings.artists' => 'শিল্পীবৃন্দ',
			'libraries.groupings.albums' => 'অ্যালবাম সমূহ',
			'libraries.groupings.tracks' => 'ট্র্যাক',
			'libraries.groupings.folders' => 'ফোল্ডার',
			'libraries.filterCategories.genre' => 'ধরণ',
			'libraries.filterCategories.year' => 'বছর',
			'libraries.filterCategories.contentRating' => 'বিষয়বস্তু Rating',
			'libraries.filterCategories.tag' => 'Tag',
			'libraries.filterCategories.unwatched' => 'অপসারণ',
			'libraries.filterCategories.unplayed' => 'খেলা না',
			'libraries.filterCategories.favorites' => 'পছন্দগুলি',
			'libraries.filterCategories.filePath' => 'ফাইল পথ',
			'libraries.sortLabels.title' => 'Title নাম',
			'libraries.sortLabels.dateAdded' => 'তারিখে এসেছে',
			'libraries.sortLabels.releaseDate' => 'Release তারিখ',
			'libraries.sortLabels.rating' => 'রেটিং',
			'libraries.sortLabels.communityRating' => 'জনসাধারনের রেটিং',
			'libraries.sortLabels.criticRating' => 'ক্রিটিক রেটিং',
			'libraries.sortLabels.userRating' => 'ব্যবহারকারীর Rating',
			'libraries.sortLabels.datePlayed' => 'তারিখে চলেছে',
			'libraries.sortLabels.playCount' => 'খেলা কন্ট',
			'libraries.sortLabels.productionYear' => 'উৎপাদন বছর',
			'libraries.sortLabels.runtime' => 'রান্টি',
			'libraries.sortLabels.officialRating' => 'অফিসিয়াল Rating',
			'libraries.sortLabels.premiereDate' => 'প্রথম ডেটা',
			'libraries.sortLabels.startDate' => 'শুরু তারিখ',
			'libraries.sortLabels.airTime' => 'বিমান সময়',
			'libraries.sortLabels.studio' => 'স্টুডিও',
			'libraries.sortLabels.random' => 'পরিস্থিতি',
			'libraries.sortLabels.dateShared' => 'ডেটা শেয়ার',
			'libraries.sortLabels.latestEpisodeAirDate' => 'সর্বশেষ আঞ্চলিক ডেটিং',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'শেষ পরিস্থিতি Date Added',
			'libraries.sortLabels.dateDownloaded' => 'ডাউনলোডের দিন',
			'libraries.sortLabels.size' => 'বড়',
			'libraries.sortLabels.library' => 'লাইব্রেরি',
			'libraries.advancedFilters.include' => 'অন্তর্ভুক্ত',
			'libraries.advancedFilters.exclude' => 'বের করা',
			'libraries.advancedFilters.any' => 'কোনও',
			'libraries.advancedFilters.yes' => 'হ্যাঁ',
			'libraries.advancedFilters.no' => 'না',
			'libraries.advancedFilters.not' => ({required Object value}) => '${value} নয়',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '${count} নির্বাচিত',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '${count} অস্বীকার',
			'libraries.advancedFilters.searchValues' => 'অনুসন্ধান মূল্য',
			'libraries.advancedFilters.noValues' => 'কোন মূল্য',
			'libraries.advancedFilters.matchContains' => 'কন্টেন্ট',
			'libraries.advancedFilters.matchNotContains' => 'অন্তর্ভুক্ত নয়',
			'libraries.advancedFilters.matchIs' => 'এতে',
			'libraries.advancedFilters.matchIsNot' => 'নাই',
			'libraries.advancedFilters.matchBeginsWith' => 'শুরু করে',
			'libraries.advancedFilters.matchEndsWith' => 'শেষ হয় সঙ্গে',
			'libraries.advancedFilters.textHint' => 'টাইপ খেলা',
			'libraries.advancedFilters.from' => 'থেকে',
			'libraries.advancedFilters.to' => 'টো',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from} থেকে ${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value} এবং ওপরে',
			'libraries.advancedFilters.atMost' => ({required Object value}) => 'সর্বোচ্চ ${value}',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => 'গত ${count} দিন',
			'libraries.advancedFilters.dateLastYear' => 'গত বছর',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => 'বয়স ${count} দিন',
			'libraries.advancedFilters.dateOlderThanYear' => 'এক বছর বয়সী',
			'libraries.selection.selectItems' => 'পণ্য নির্বাচন',
			'libraries.selection.selectedCount' => ({required Object count}) => '${count} নির্বাচিত',
			'libraries.selection.actions' => 'নির্বাচন কার্যক্রম',
			'libraries.selection.confirmDescendants' => 'এই পরিবর্তন প্রত্যেকটি প্রদর্শন এবং নির্বাচিত সপ্তাহগুলিতে প্রদর্শন পরিবর্তন করে।',
			'libraries.selection.confirmUnwatched' => 'এতে নির্বাচিত আইটেমগুলির প্লেব্যাকের অগ্রগতিও মুছে যাবে।',
			'libraries.selection.confirmCount' => ({required Object count}) => 'নির্বাচিত পণ্য: ${count}',
			'libraries.selection.completed' => ({required Object count}) => 'আপডেট পণ্য: ${count}',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => 'আপডেট ${succeeded}; ভুল ${failed}. ভুল পণ্যগুলি বেছে নিতে থাকে।',
			'about.title' => 'সম্পর্কে',
			'about.openSourceLicenses' => 'খোলা সূত্র লাইসেন্স',
			'about.versionLabel' => ({required Object version}) => 'সংস্করণ ${version}',
			'about.appDescription' => 'Flutter জন্য একটি সুন্দর Plex, Jellyfin, এবং Emby গ্রাহক',
			'about.viewLicensesDescription' => 'তৃতীয় পক্ষের লাইসেন্সগুলি দেখুন',
			'about.privacyPolicy' => 'গোপনীয়তা নীতি',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'কোন সার্ভার পাওয়া যায় না ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'সার্ভারগুলি লোড করতে পারেনি: ${error}',
			'serverSelection.noValidServers' => 'এই অ্যাকাউন্টে কোন ব্যবহারযোগ্য সার্ভার পাওয়া যায়নি',
			'hubDetail.title' => 'Title নাম',
			'hubDetail.releaseYear' => 'মুক্তিযোদ্ধা বছর',
			'hubDetail.dateAdded' => 'তারিখে এসেছে',
			'hubDetail.rating' => 'রেটিং',
			'hubDetail.noItemsFound' => 'খুঁজে পাওয়া যায় না পণ্য',
			'logs.clearLogs' => 'স্পষ্ট লগ',
			'logs.copyLogs' => 'লগ কপি',
			'logs.uploadLogs' => 'লগ আপলোড',
			'logs.saveLogs' => 'ফাইলে লগ সুরক্ষা করুন',
			'logs.logsSaved' => ({required Object path}) => 'লগগুলি সংরক্ষিত হয়েছে ${path}',
			'logs.saveLogsFailed' => 'লগ ফাইল সংরক্ষণ করতে পারেনি।',
			'startup.failedTitle' => 'PlezyNG শুরু করতে পারেনি',
			'startup.failedBody' => 'স্টার্টপোর্টের সময় কিছু ভুল হয়েছিল. নিচের বিস্তারিতগুলি কী ভুল হয়েছে তা সংজ্ঞা করে।',
			'startup.failedBodyRepairable' => 'PlezyNG-এর সংরক্ষিত সেটিংস ফাইলটি ক্ষতিগ্রস্ত। অ্যাপ চালুর আগে এটি আবার তৈরি করতে হবে। আবার চেষ্টা করলে কাজ হবে না — স্টোরেজ মেরামতের বিকল্পটি বেছে নিন।',
			'startup.phaseLabel' => 'পদক্ষেপ',
			'startup.showDetails' => 'বিস্তারিত দেখুন',
			'startup.hideDetails' => 'গোপন বিস্তারিত',
			'startup.copyDetails' => 'কপি ডেটা',
			'startup.detailsCopied' => 'ক্লিপবোর্ডে কপি করা তথ্য',
			'startup.uploadDetails' => 'আপলোড ডেটা',
			'startup.repairStorage' => 'পুনরাবৃত্তি সংরক্ষণ',
			'startup.repairTitle' => 'রক্ষা করা ডেটা কি?',
			'startup.repairBodyCommon' => 'PlezyNG-এর সেটিংস ফাইলটি ক্ষতিগ্রস্ত এবং পড়া যাচ্ছে না। মেরামত করলে সব সেটিংস ডিফল্ট মানে ফিরে যাবে।',
			'startup.repairBodyOneCredential' => 'সংরক্ষিত সাইন-ইনের একটি তথ্য ক্ষতিগ্রস্ত এবং পড়া যাচ্ছে না। মেরামত করলে শুধু সেটিই মুছে যাবে; অন্য সেটিংস বদলাবে না।',
			'startup.repairBodySignInsKept' => 'আপনার সার্ভার ও প্রোফাইলগুলিতে সাইন-ইন অবস্থা বজায় থাকার কথা।',
			'startup.repairBodySignInsLost' => 'সংরক্ষিত সাইন-ইনের তথ্য রক্ষা করার চাবিটি এই ফাইল থেকে পুনরুদ্ধার করা যাচ্ছে না। তাই প্রতিটি সার্ভার ও প্রোফাইলে আবার সাইন ইন করতে হবে। মিডিয়া সার্ভারে কিছুই প্রভাবিত হবে না।',
			'startup.repairBodySessionsUncertain' => 'ট্র্যাকার (MAL, AniList, Simkl, Trakt) এবং Seerr-এর তথ্য আলাদাভাবে সংরক্ষিত থাকে এবং তা অক্ষত থাকতেও পারে, নাও পারে। PlezyNG ঠিক কোন তথ্য রেখেছে তা আপনাকে জানাবে।',
			'startup.repairConfirm' => 'পুনরায়',
			'startup.repairSucceeded' => 'রেকর্ড করা হয়েছে',
			'startup.repairNeedsRestart' => 'পুনরাবৃত্তি প্রয়োজন – Repair Required',
			'startup.restartRequiredBody' => 'আপনার তথ্য মেরামত করা হয়েছে, তবে তা ব্যবহার করতে PlezyNG আবার চালু করতে হবে। PlezyNG বন্ধ করে আবার খুলুন।',
			'startup.quitPlezy' => 'ফাঁস PlezyNG',
			'startup.repairFailed' => 'পুনরাবৃত্তি ভুল',
			'startup.repairKeptSignIns' => 'আপনার সার্ভার ও প্রোফাইলগুলিতে এখনও সাইন ইন করা আছে।',
			'startup.repairLostSignIns' => 'আপনার সুরক্ষিত সাইন ইন সুরক্ষার চিঠি পুনরাবৃত্তি করা যাবে না. আপনাকে প্রতিটি সার্ভার এবং প্রোফাইলে আবার সাইন আপ করতে হবে।',
			'startup.repairLostSessions' => 'কমপক্ষে একটি ট্র্যাকার বা Seerr সংযোগ হারিয়ে গেছে এবং আবার সংযোগ করতে হবে।',
			'startup.backupTitle' => 'ক্ষতিগ্রস্ত ফাইলের একটি কপি সংরক্ষণ করা হয়েছে',
			'startup.backupWarning' => 'এতে আপনার সাইন-ইন তথ্য রয়েছে। এটি আপলোড বা শেয়ার করবেন না।',
			'startup.deleteBackup' => 'কপি মুছে ফেলুন',
			'startup.backupDeleted' => 'কপি মুছে ফেলুন',
			'startup.previousFailureTitle' => 'PlezyNG শেষবার শুরু করতে পারিনি',
			'licenses.relatedPackages' => 'সম্পর্কিত প্যাকেজ',
			'licenses.license' => 'লাইসেন্স',
			'licenses.licenseNumber' => ({required Object number}) => 'লাইসেন্স ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} লাইসেন্স',
			'navigation.libraries' => 'বইয়েরা',
			'navigation.downloads' => 'ডাউনলোড',
			'navigation.liveTv' => 'লাইভ টিভি',
			'navigation.explore' => 'গবেষণা',
			'explore.mdblistShelves.manage' => 'ম্যানেজারি গবেষণার উপাদান',
			'explore.mdblistShelves.manageDescription' => 'আপনার অ্যাকাউন্ট MDBList থেকে তালিকা নির্বাচন করুন এবং সংস্থা করুন',
			'explore.mdblistShelves.description' => 'আপনার অ্যাকাউন্ট MDBList থেকে জনপ্রিয় চলচ্চিত্র এবং টিভি তালিকা নির্বাচন করুন. তাহলে MDBList তালিকা তৈরি করুন বা কপি করুন.',
			'explore.mdblistShelves.selected' => 'বেছে নেওয়া ক্লাস',
			'explore.mdblistShelves.available' => 'উপলব্ধ অ্যাকাউন্টের তালিকা',
			'explore.mdblistShelves.noLists' => 'কোন জনপ্রিয় চলচ্চিত্র বা টিভি তালিকা ফিরে আসেনি. MDBList এর একটি তালিকা তৈরি করুন বা কপি করুন, তারপর আপডেট করুন।',
			'explore.mdblistShelves.displayName' => 'শেলফের নাম',
			'explore.mdblistShelves.nameHint' => 'সূত্র তালিকা নাম ব্যবহার করার জন্য বাদ রাখুন।',
			'explore.mdblistShelves.add' => 'শেলি যোগ করুন',
			'explore.mdblistShelves.save' => 'শিগগির সংরক্ষণ',
			'explore.mdblistShelves.moveUp' => ({required Object title}) => 'মোট ${title} আপ',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => 'ফাঁস করুন ${title}',
			'explore.mdblistShelves.unavailable' => 'এই তালিকা পাওয়া যায় না. সেটিংসগুলিতে তার স্কেল ফেরত বা মুছে ফেলুন.',
			'explore.mdblistShelves.rateLimited' => 'MDBList অনুরোধের সীমাবদ্ধতা পৌঁছানো হয়েছে. পরে দয়া করে ফেরত দাও।',
			'explore.mdblistShelves.loadFailed' => 'আপনার সংযোগ এবং ফেরত চেক করতে পারবেন না।',
			'explore.mdblistShelves.saveFailed' => 'পাশাপাশি পাশাপাশি পাশাপাশি পাশাপাশি পাশাপাশি পাশাপাশি পাশাপাশি পাশাপাশি পাশাপাশি পাশাপাশি পাশাপাশি।',
			'explore.mdblistShelves.accountChanged' => 'অ্যাকাউন্ট বা প্রোফাইল পরিবর্তন করা হয়েছে. এই পরামর্শগুলি আবার খোলা।',
			'explore.mdblistShelves.settingsUnreadable' => 'সংরক্ষিত স্ক্রিনগুলি পড়তে পারে না. এই পরামর্শগুলি পরিবর্তন করার জন্য আপনার তালিকাগুলি আবার নির্বাচন করুন.',
			'explore.title' => 'গবেষণা',
			'explore.selectSource' => 'সূত্র নির্বাচন',
			'explore.rows.watchlist' => 'চোখের তালিকা',
			'explore.rows.recommendedMovies' => 'প্রস্তাবিত চলচ্চিত্র',
			'explore.rows.recommendedShows' => 'প্রস্তাবিত প্রদর্শন',
			'explore.rows.trendingMovies' => 'ট্রেনিং সিনেমা',
			'explore.rows.trendingShows' => 'ট্রেন্ডিং প্রদর্শনী',
			'explore.rows.popularMovies' => 'জনপ্রিয় চলচ্চিত্র',
			'explore.rows.popularShows' => 'জনপ্রিয় প্রদর্শনী',
			'explore.rows.trendingAnime' => 'ট্রেনিং অ্যানিম',
			'explore.rows.suggestedAnime' => 'অ্যানিমের প্রস্তাব',
			'explore.rows.airingAnime' => 'অ্যানিমেটিক অ্যানিমেটিক',
			'explore.rows.popularAnime' => 'সবচেয়ে জনপ্রিয় অ্যানিম',
			'explore.rows.trending' => 'ট্রেন্ডিং',
			'explore.rows.upcomingMovies' => 'আগামী চলচ্চিত্র',
			'explore.rows.upcomingShows' => 'আগামী প্রদর্শনী',
			'explore.status.airing' => 'এয়ারিং',
			'explore.status.ended' => 'শেষ হয়েছে',
			'explore.status.canceled' => 'বাতিল',
			'explore.status.upcoming' => 'আসছে',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} আয়াত', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} প্রদর্শন', ), 
			'explore.cast' => 'কাস্ট',
			'explore.characters' => 'চরিত্র',
			'explore.addToWatchlist' => 'Watchlist এ যোগ করুন',
			'explore.removeFromWatchlist' => 'Watchlist থেকে মুছে ফেলুন',
			'explore.addedToWatchlist' => 'Watchlist এ যোগ করা',
			'explore.removedFromWatchlist' => 'Watchlist থেকে মুছে ফেলুন',
			'explore.watchlistUpdateFailed' => 'Watchlist আপডেট করতে পারবেন না',
			'explore.watchlistNoMatch' => 'এই পণ্যটি একটি চোখের তালিকাতে সমন্বয় করতে পারবে না',
			'explore.notInLibrary' => 'আপনার লাইব্রেরিতে নয়',
			'explore.inTheseLibraries' => 'এই লাইব্রেরিতে',
			'explore.checkingLibrary' => 'আপনার লাইব্রেরি চেক করুন',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} সার্ভার চেক করতে পারবেন না', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} সার্ভারগুলি চেক করতে পারেনি', ), 
			'explore.emptyTitle' => 'এখনো এখানে কিছু নেই',
			'explore.emptyMessage' => ({required Object source}) => '${source} এর রুটিগুলি একবার এখানে প্রদর্শন করা হবে।',
			'explore.searchHint' => ({required Object source}) => 'খুঁজে পেতে ${source}',
			'explore.searchEmpty' => ({required Object query}) => '"${query}" এর জন্য কোন ফলাফল নেই',
			'explore.searchPrompt' => ({required Object source}) => 'সিনেমা ও প্রদর্শনীগুলি খুঁজে পেতে ${source} এর মাধ্যমে।',
			'explore.searchFailed' => 'অনুসন্ধান ভুল হয়ে গেছে. আপনার সংযোগ চেক করুন এবং আবার চেষ্টা করুন.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} জনপ্রিয়',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} সার্ভিস',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} রেকর্ড',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} ট্রেনিং',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} মধ্যে ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} দেখুন',
			'explore.badge.available' => 'পাওয়া',
			'explore.badge.partiallyAvailable' => 'অংশে পাওয়া যায়',
			'explore.badge.availableIn4k' => '4K উপলক্ষে',
			'explore.badge.requested' => 'অনুরোধ',
			'explore.badge.pendingApproval' => 'অনুমোদনের সময়',
			'explore.badge.processing' => 'প্রক্রিয়া',
			'explore.badge.declined' => 'দুর্বল',
			'explore.badge.requestFailed' => 'অনুরোধ ভুল',
			'explore.badge.requested4k' => '4K অনুরোধ',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} সপ্তাহ',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => 'Ep ${episode} মধ্যে ${duration}',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'পরবর্তী নিবন্ধ ${duration}',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} ইপিএস',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} মিনিট/এপি',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} তালিকাভুক্ত',
			'explore.stats.viewersDay' => ({required Object n}) => 'আজ ${n} জন দেখেছেন',
			'explore.stats.viewersWeek' => ({required Object n}) => 'এই সপ্তাহে ${n} জন দেখেছেন',
			'explore.stats.viewersMonth' => ({required Object n}) => 'এই মাসে ${n} জন দেখেছেন',
			'explore.stats.viewersYear' => ({required Object n}) => 'এই বছরে ${n} জন দেখেছেন',
			'explore.stats.viewersAllTime' => ({required Object n}) => '${n} ভিউ',
			'explore.stats.planning' => ({required Object n}) => '${n} দেখতে চান',
			'explore.stats.favorited' => ({required Object n}) => '${n} পছন্দ',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} একেবারে ফেরত',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} মন্তব্য', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} মন্তব্য', ), 
			'explore.stats.votes' => ({required Object n}) => '${n}টি ভোট',
			'explore.stats.watching' => ({required Object n}) => '${n} দেখুন',
			'explore.stats.completed' => ({required Object n}) => '${n} সম্পন্ন',
			'explore.stats.onHold' => ({required Object n}) => '${n} হাতে',
			'explore.stats.dropped' => ({required Object n}) => '${n} জন দেখা বন্ধ করেছেন',
			'explore.season.winter' => 'শীতের',
			'explore.season.spring' => 'শতাব্দী',
			'explore.season.summer' => 'গ্রীষ্ম',
			'explore.season.fall' => 'হাঁটতে',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'টেলিভিশন',
			'explore.format.tvShort' => 'টেলিভিশন ছোট',
			'explore.format.movie' => 'চলচ্চিত্র',
			'explore.format.special' => 'বিশেষ',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => 'সঙ্গীত',
			'explore.format.other' => 'অন্য',
			'explore.sourceMaterial.original' => 'মূল',
			'explore.sourceMaterial.manga' => 'ম্যানেজমেন্ট',
			'explore.sourceMaterial.lightNovel' => 'আলো গল্প',
			'explore.sourceMaterial.novel' => 'গল্প',
			'explore.sourceMaterial.visualNovel' => 'ভিসুয়াল রোবট',
			'explore.sourceMaterial.game' => 'খেলা',
			'explore.sourceMaterial.webComic' => 'ওয়েবসাইট কমিক',
			'explore.sourceMaterial.musicRelease' => 'সঙ্গীত',
			'explore.sourceMaterial.otherMedia' => 'অন্য',
			'explore.creditRole.actor' => 'অভিনেতা',
			'explore.creditRole.director' => 'পরিচালক',
			'explore.creditRole.writer' => 'লেখক',
			'explore.creditRole.producer' => 'উৎপাদনকারী',
			'explore.creditRole.creator' => 'সৃষ্টি',
			'explore.creditRole.composer' => 'সুরকার',
			'explore.relation.prequel' => 'পূর্বাভাস',
			'explore.relation.sequel' => 'সেকেন্ড',
			'explore.relation.sideStory' => 'Side গল্প',
			'explore.relation.spinOff' => 'স্পিন-অফ',
			'explore.relation.alternativeVersion' => 'Alternative সংস্করণ',
			'explore.relation.summary' => 'সাবধান',
			'explore.relation.parentStory' => 'বাবা-মা গল্প',
			'explore.relation.adaptation' => 'adaptation সংশ্লিষ্ট',
			'explore.relation.other' => 'সম্পর্কিত',
			'explore.broadcast' => ({required Object day, required Object time}) => 'Airs ${day} এ ${time}',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => '${day} ${time} ${timezone}-এ প্রচারিত হয়',
			'explore.detail.originalTitle' => 'মূল নাম',
			'explore.detail.alsoKnownAs' => 'এছাড়াও পরিচিত যে',
			'explore.detail.studios' => 'স্টুডিও',
			'explore.detail.country' => 'দেশ',
			'explore.detail.language' => 'ভাষা',
			'explore.detail.released' => 'মুক্তি',
			'explore.detail.physicalRelease' => 'ডিজিটাল',
			'explore.detail.ended' => 'শেষ হয়েছে',
			'explore.detail.addedOn' => ({required Object date}) => 'যোগ করা ${date}',
			'explore.detail.yourRating' => 'আপনার Rating',
			'explore.detail.budget' => 'বাজেট',
			'explore.detail.revenue' => 'বক্স অফিস',
			'explore.detail.contentAdvisory' => 'বয়স গাইডিং',
			'explore.detail.tags' => 'ট্যাগ',
			'explore.detail.revealSpoilerTags' => 'স্পোিলার ট্যাগ',
			'explore.detail.links' => 'বামদিকে',
			'explore.detail.watchOn' => 'দেখুন',
			'explore.detail.watchTrailer' => 'ট্র্যালার দেখুন',
			'explore.detail.openOn' => ({required Object site}) => 'খোলা ${site}',
			'explore.detail.crew' => 'ক্লাব',
			'explore.detail.ratings' => 'রেটিং',
			'explore.detail.schedule' => 'পরিকল্পনা',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n, one: 'ব্যবহারকারী ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} দ্বারা পরামর্শ', other: 'সংশোধন করা হয়েছে ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ব্যবহারকারীদের', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'সংখ্যা: ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'পছন্দ করা হয়েছে ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} এখনো প্রদর্শিত হয়নি',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'সংশোধন করা হয়েছে ${percent} জনের জন্য',
			'explore.detail.relatedTitles' => 'সম্পর্কিত টাইম',
			'explore.detail.background' => 'ফাউন্ডেশন',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ফলাফল', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ফলাফল', ), 
			'liveTv.title' => 'লাইভ টিভি',
			'liveTv.guide' => 'গাইড',
			'liveTv.noChannels' => 'কোন চ্যানেল পাওয়া যায় না',
			'liveTv.noDvr' => 'কোন সার্ভারে DVR সংগঠিত হয় না',
			'liveTv.serverUnavailable' => 'লাইভ টিভি সার্ভার পাওয়া যায় না।',
			'liveTv.serverNotConnected' => 'লাইভ টিভি সার্ভার সংযুক্ত নয়।',
			'liveTv.noPrograms' => 'কোন প্রোগ্রাম ডেটা পাওয়া যায় না',
			'liveTv.liveStreamFailed' => 'Live Stream হারিয়েছে',
			'liveTv.unknownProgram' => 'অজ্ঞাত প্রোগ্রাম',
			'liveTv.timelineLiveProgram' => 'Live প্রোগ্রাম (Playback এই প্রোগ্রামের বাইরে হতে পারে)',
			'liveTv.timelineBuffer' => 'টাইমলাইন বাফার',
			'liveTv.timelineUnavailable' => 'টাইম লাইন অসম্ভব',
			'liveTv.timelineEstimated' => 'বিবেচনা Playback',
			'liveTv.timelinePending' => 'খুঁজে বের',
			'liveTv.timelineStale' => 'পরিস্থিতি অতীত হতে পারে',
			'liveTv.unknownHub' => 'অজানা',
			'liveTv.unknownError' => 'অজ্ঞাত ভুল',
			'liveTv.channelNumber' => ({required Object number}) => 'চ্যানেল ${number}',
			'liveTv.unknownChannel' => 'অজ্ঞাত চ্যানেল',
			'liveTv.live' => 'লাইভ',
			'liveTv.premiereBadge' => 'নতুন',
			'liveTv.reloadGuide' => 'রেলোড গাইড',
			'liveTv.searchGuide' => 'অনুসন্ধান গাইড',
			'liveTv.searchHint' => 'চ্যানেল এবং প্রোগ্রাম',
			'liveTv.searchNoResults' => ({required Object query}) => '‘${query}’ এর জন্য কোন খেলা নেই',
			'liveTv.channelsSection' => 'চ্যানেলগুলো',
			'liveTv.programsSection' => 'প্রোগ্রাম',
			'liveTv.now' => 'এখন',
			'liveTv.today' => 'আজ',
			'liveTv.tomorrow' => 'আগামীকাল',
			'liveTv.midnight' => 'মধ্য রাতে',
			'liveTv.overnight' => 'রাতে',
			'liveTv.morning' => 'সকালে',
			'liveTv.daytime' => 'দিনের সময়',
			'liveTv.evening' => 'রাতে',
			'liveTv.lateNight' => 'দীর্ঘ রাতে',
			'liveTv.whatsOn' => 'কী আছে',
			'liveTv.watchChannel' => 'চ্যানেল দেখুন',
			'liveTv.favorites' => 'পছন্দগুলি',
			'liveTv.reorderFavorites' => 'পছন্দের রেকর্ড',
			'liveTv.noFavoriteChannels' => 'প্রিয় চ্যানেল নেই',
			'liveTv.noFavoriteChannelsHint' => 'সব চ্যানেলগুলি দেখুন, তারপর একটি চ্যানেলটি দীর্ঘ চ্যানেলে প্রদর্শন করুন যাতে আপনার প্রিয়দের সাথে যোগ করুন।',
			'liveTv.showAllChannels' => 'সব চ্যানেল দেখুন',
			'liveTv.favoritesLoadFailed' => 'আপনি পছন্দ করতে পারেন না. আপনার সংযোগ চেক করুন এবং আবার চেষ্টা করুন.',
			'liveTv.favoritesUpdateFailed' => 'আপডেট করতে পারেন না প্রিয়. আপনার সংযোগ চেক করুন এবং আবার চেষ্টা করুন।',
			'liveTv.joinSession' => 'প্রসেসে অংশগ্রহণ',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'শুরু থেকে দেখুন (${minutes} মিনিট আগে)',
			'liveTv.watchLive' => 'দেখুন Live',
			'liveTv.goToLive' => 'বেঁচে থাকুন',
			'liveTv.record' => 'রেকর্ড',
			'liveTv.recordEpisode' => 'রেকর্ড এজেন্ট',
			'liveTv.recordSeries' => 'রেকর্ড সিরিজ',
			'liveTv.recordOptions' => 'রেকর্ড বিকল্প',
			'liveTv.saveTo' => 'সুরক্ষা',
			'liveTv.recordings' => 'রেকর্ডিং',
			'liveTv.scheduledRecordings' => 'পরিকল্পনা',
			'liveTv.recordingRules' => 'রেকর্ডিং নিয়ম',
			'liveTv.noScheduledRecordings' => 'রেকর্ড করার জন্য কিছুই না',
			'liveTv.manageRecording' => 'রেকর্ড পরিচালনা',
			'liveTv.cancelRecording' => 'রেকর্ড বন্ধ করুন',
			'liveTv.cancelRecordingTitle' => 'এই রেকর্ডটি বাতিল করবেন?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} এখন আর রেকর্ড করা হবে না।',
			'liveTv.deleteRule' => 'নিয়ম মুছে ফেলুন',
			'liveTv.deleteRuleTitle' => 'রেকর্ডিং নিয়ম কি মুছে ফেলবে?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => '${title}-এর পরবর্তী পর্বগুলি রেকর্ড করা হবে না।',
			'liveTv.recordingScheduled' => 'রেকর্ডার পরিকল্পনা',
			'liveTv.alreadyScheduled' => 'এই প্রোগ্রামটি এখনও পরিকল্পিত',
			'liveTv.dvrAdminRequired' => 'DVR সিস্টেমগুলি একটি admin অ্যাকাউন্ট প্রয়োজন',
			'liveTv.recordingFailed' => 'রেকর্ড করতে পারিনি',
			'liveTv.recordingTargetMissing' => 'রেকর্ডিং লাইব্রেরি নির্ধারণ করতে পারত না',
			'liveTv.recordNotAvailable' => 'এই প্রোগ্রামের জন্য রেকর্ড পাওয়া যায় না',
			'liveTv.recordingCancelled' => 'রেকর্ড বাতিল',
			'liveTv.recordingRuleDeleted' => 'রেকর্ড নিয়ম মুছে ফেলেন',
			'liveTv.processRecordingRules' => 'নিয়মের পুনরায় মূল্যায়ন',
			'liveTv.recordingInProgress' => 'এখন রেকর্ড করুন',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} পরিকল্পনা',
			'liveTv.editRule' => 'Edit নিয়ম',
			'liveTv.editRuleAction' => 'এডিট',
			'liveTv.recordingRuleUpdated' => 'রেকর্ড নিয়ম আপডেট',
			'liveTv.guideReloadRequested' => 'গাইড ফ্রিজ অনুরোধ',
			'liveTv.guideReloadFailed' => 'গাইড খুন করতে পারিনি।',
			'liveTv.rulesProcessRequested' => 'পরবর্তী নিয়ম বিবেচনার দাবি',
			'liveTv.rulesProcessFailed' => 'রেকর্ডিং নিয়মগুলি পুনরায় মূল্যায়ন করতে পারবেন না',
			'liveTv.recordShow' => 'রেকর্ড প্রদর্শন',
			'liveTv.recordSettings.startEarly' => 'দীর্ঘদিনের শুরু (2 সেকেন্ড)',
			'liveTv.recordSettings.endLate' => 'দেরি শেষ (2 সেকেন্ড)',
			'liveTv.recordSettings.newOnly' => 'শুধু নতুন ঘটনা',
			'liveTv.recordSettings.anyChannel' => 'প্রতিটি চ্যানেলের রেকর্ড',
			'liveTv.recordSettings.anyTime' => 'প্রতিটি সময় রেকর্ড',
			'liveTv.recordSettings.skipInLibrary' => 'লাইব্রেরিতে ইতিমধ্যে অ্যাপিগারেটস',
			'liveTv.recordSettings.keepUpTo' => 'চলতে যাওয়ার ঘটনা',
			'liveTv.recordSettings.keepUpToHint' => '0 প্রতিটি অধ্যায়',
			'liveTv.startingInMinutes' => ({required Object minutes}) => 'শুরু হয় ${minutes} মিনিট',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} এ ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product} অনিবার্য লাইভ টেলিভিশন প্লাইব্যাক ডেটা ফেরত',
			'liveTv.failedToStartChannel' => 'লাইভ চ্যানেল শুরু করতে পারবেন না।',
			'liveTv.failedToBuildStreamUrl' => 'URL এর প্রদর্শন করতে পারবেন না',
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'চ্যানেলটি শুরু করতে পারেনি: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'চ্যানেল পরিবর্তন করতে পারবেন না: ${reason}',
			'collections.title' => 'কালেকশন',
			'collections.collection' => 'সংগ্রহ',
			'collections.empty' => 'সংগ্রহ ভূষণ',
			'collections.deleteCollection' => 'রেকর্ড 삭제',
			'collections.deleteConfirm' => ({required Object title}) => '"${title}" মুছে ফেলবেন? এই কাজ আর পূর্বাবস্থায় ফেরানো যাবে না।',
			'collections.deleted' => 'সংগ্রহ 삭제',
			'collections.deleteFailed' => 'সংগ্রহের অপসারণ করতে পারেনি',
			'collections.deleteFailedWithError' => ({required Object error}) => 'সংগ্রহের অপসারণ করা হয় না: ${error}',
			'collections.selectCollection' => 'ক্যালেকশন নির্বাচন',
			'collections.collectionName' => 'সংগ্রহ নাম',
			'collections.enterCollectionName' => 'সংগ্রহ নাম লিখুন',
			'collections.addedToCollection' => 'সংগ্রহে যোগ করা',
			'collections.errorAddingToCollection' => 'সংগ্রহে যোগ করতে পারিনি',
			'collections.created' => 'সংগ্রহ তৈরি',
			'collections.removeFromCollection' => 'সংগ্রহ থেকে বের করুন',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => 'এই সংগ্রহ থেকে "${title}" মুছে ফেলুন?',
			'collections.removedFromCollection' => 'সংগ্রহ থেকে বের করা',
			'collections.removeFromCollectionFailed' => 'সংগ্রহ থেকে বের করা যায়নি',
			'collections.removeFromCollectionError' => ({required Object error}) => 'সংগ্রহ থেকে তুলনা ভুল: ${error}',
			'collections.searchCollections' => 'খুঁজে পাওয়া সংগ্রহ...',
			'playlists.title' => 'খেলোয়াড়',
			'playlists.playlist' => 'প্লেলিস্ট',
			'playlists.noPlaylists' => 'খেলোয়াড় পাওয়া যায়নি',
			'playlists.create' => 'Playlist তৈরি করুন',
			'playlists.playlistName' => 'Playlist নাম',
			'playlists.enterPlaylistName' => 'Playlist নাম লিখুন',
			'playlists.delete' => 'Playlist খেলা',
			'playlists.removeItem' => 'Playlist থেকে মুছে ফেলুন',
			'playlists.smartPlaylist' => 'স্মার্ট Playlist',
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)}টি আইটেম', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)}টি আইটেম', ), 
			'playlists.emptyPlaylist' => 'এই খেলাটি खाली',
			'playlists.deleteConfirm' => 'Playlist খেলা?',
			'playlists.deleteMessage' => ({required Object name}) => 'আপনি কি নিশ্চিত যে আপনি "${name}" মুছে ফেলতে চান?',
			'playlists.created' => 'Playlist তৈরি',
			'playlists.deleted' => 'Playlist 삭제',
			'playlists.itemAdded' => 'Playlist এ যোগ করা',
			'playlists.itemRemoved' => 'Playlist থেকে মুছে ফেলুন',
			'playlists.selectPlaylist' => 'Playlist নির্বাচন করুন',
			'playlists.searchPlaylists' => 'খেলা খেলা খেলা খেলা...',
			'playlists.errorCreating' => 'খেলা তালিকা তৈরি করতে পারিনি',
			'playlists.errorDeleting' => 'খেলা লিস্ট মুছে ফেলতে পারিনি',
			'playlists.errorLoading' => 'খেলনা লাইসেন্সগুলি লোড করতে পারিনি',
			'playlists.errorAdding' => 'খেলা লিস্টে যোগ করতে পারিনি',
			'playlists.errorReordering' => 'খেলা তালিকা পণ্য পুনরায় সংস্থা করতে পারেনি',
			'playlists.errorRemoving' => 'Playlist থেকে ফেরত না',
			'music.goToAlbum' => 'অ্যালবামে যান',
			'music.goToArtist' => 'শিল্পীকে যান',
			'music.instantMix' => 'দ্রুত মিশন',
			'music.playNext' => 'Next খেলুন',
			'music.addToQueue' => 'কুকুরে যোগ করুন',
			'music.discNumber' => ({required Object n}) => 'ডিজিটাল ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ট্র্যাক', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} পাসপোর্ট', ), 
			'music.nowPlaying' => 'এখন খেলতে',
			'music.playingFrom' => ({required Object title}) => 'খেলা ${title} থেকে',
			'music.queue' => 'কুরআন',
			'music.clearQueue' => 'কিউগুলো মুছুন',
			'music.lyrics' => 'গানের কথা',
			'music.visualizer' => 'Visualizator',
			'music.visualizerProfileLoading' => 'Read track বিশ্লেষণ ...',
			'music.visualizerAmbientMotion' => 'পরিবেশ মোকাবিলা',
			'music.visualizerPlexLoudness' => 'Plex শব্দ',
			'music.visualizerLiveAudio' => 'লাইভ অডিও বিশ্লেষণ',
			'music.visualizerPreviousPreset' => 'পূর্ববর্তী চিত্র',
			'music.visualizerNextPreset' => 'পরবর্তী ভিজুয়াল স্টাইল',
			'music.visualizerPresetAurora' => 'অুরোরা',
			'music.visualizerPresetBloom' => 'ব্লম',
			'music.visualizerPresetOrbitals' => 'কক্ষপথ',
			'music.visualizerPresetPrism' => 'পুরস্কার',
			'music.visualizerPresetTunnel' => 'টুনেল',
			'music.visualizerPresetTrackMap' => 'ট্র্যাক ম্যাপ',
			'music.noLyrics' => 'কোন পাঠ্য নেই',
			'music.sleepTimer' => 'ঘুমের টাইম',
			'music.sleepTimerEndOfTrack' => 'ট্র্যাকের শেষ',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} মিনিট', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} মিনিট', ), 
			'music.stopPlayback' => 'Playback বন্ধ করুন',
			'music.previousTrack' => 'পূর্ববর্তী ট্র্যাক',
			'music.nextTrack' => 'পরবর্তী ট্র্যাক',
			'music.repeat' => 'বার্তা',
			'music.repeatAll' => 'প্রতিটি বার্তা',
			'music.repeatOne' => 'এক বার বার',
			'music.instantMixNoServer' => 'কোন সার্ভার অন্তত মিশ্রণ জন্য উপলব্ধ নয়',
			'music.instantMixFailed' => 'অন্তত মিশ্রণ করতে পারেনি।',
			'music.instantMixEmpty' => 'ফেরত এসেছিলেন ফেরত এসেছিলেন কোন পাসপোর্ট নেই।',
			'music.noAudioUrl' => ({required Object track}) => 'কোন অডিও ইউরলি পাওয়া যায় না ${track}',
			'music.discography.singlesAndEps' => 'Singles ও EPs',
			'music.discography.live' => 'জীবনযাপন',
			'music.discography.compilations' => 'কম্পিউটার',
			'watchTogether.title' => 'একসঙ্গে দেখুন',
			'watchTogether.description' => 'বন্ধু ও পরিবারের সাথে সিন্কের সাথে সামগ্রী দেখুন',
			'watchTogether.createRoom' => 'রুম তৈরি করুন',
			'watchTogether.creatingRoom' => 'রুম তৈরি করে...',
			'watchTogether.joinRoom' => 'ঘরে যোগ',
			'watchTogether.joiningRoom' => 'একত্রিত রুম...',
			'watchTogether.connecting' => 'সংযোগ...',
			'watchTogether.relayPublic' => 'রুমগুলি খোলা চোখের পার্থ রেলি ব্যবহার করে।',
			'watchTogether.relayCustom' => ({required Object url}) => 'রুমগুলি আপনার রেলিটি ${url} এ ব্যবহার করে।',
			'watchTogether.recentRooms' => 'সাম্প্রতিক রুম',
			'watchTogether.roomActions' => 'রুম কার্যক্রম',
			'watchTogether.renameRoom' => 'রুমের নাম',
			'watchTogether.removeRoom' => 'সরান',
			'watchTogether.enterRoomCode' => 'হোস্ট থেকে 6 চরিত্র কোড প্রদান করুন।',
			'watchTogether.roomCode' => 'রুম কোড',
			'watchTogether.paste' => 'পেস্ট',
			'watchTogether.noCodeInClipboard' => 'ক্লাববের কোডে রুম কোড নেই।',
			'watchTogether.copyCode' => 'কপি কোড',
			'watchTogether.codeCopied' => 'রুম কোড কপি',
			'watchTogether.shareInvite' => 'বিতর্ক invitaciones',
			'watchTogether.inviteCopied' => 'কপি করুন, এটি একটি বার্তাে প্রবেশ করুন।',
			_ => null,
		} ?? switch (path) {
			'watchTogether.inviteMessage' => ({required Object code}) => 'PlezyNG: খুলুন ঘোড়ি একসাথে, চিহ্ন করুন ঘোড়ি একসাথে এবং ${code} এ প্রবেশ করুন।',
			'watchTogether.openSessionControls' => 'Open Watch Together সেশন কন্ট্রোল',
			'watchTogether.reconnecting' => 'আবার সংযোগ...',
			'watchTogether.reconnectingDescription' => 'সংযোগ বন্ধ হয়ে গেছে. আপনি স্বয়ংক্রিয়ভাবে রুমে যোগ দেবেন।',
			'watchTogether.connected' => 'সংযুক্ত',
			'watchTogether.disconnected' => 'বিচ্ছিন্ন',
			'watchTogether.youAreHost' => 'আপনি হোস্ট',
			'watchTogether.hostedBy' => ({required Object name}) => 'হোস্ট করা হয়েছে ${name}',
			'watchTogether.hostControlsPlayback' => 'হোস্ট কন্ট্রোল Playback',
			'watchTogether.anyoneCanControl' => 'কেউ Playback নিয়ন্ত্রণ করতে পারেন',
			'watchTogether.roomLocked' => 'রুম বন্ধ',
			'watchTogether.nowPlaying' => 'এখন খেলতে',
			'watchTogether.nothingPlaying' => 'খেলতে কিছুই নেই',
			'watchTogether.nothingPlayingHost' => 'যে কোনো লাইব্রেরি থেকে কিছু খেলুন, এটি রুমের সাথে শেয়ার করুন।',
			'watchTogether.nothingPlayingGuest' => 'যখন হোস্ট কিছু খেলতে পারে, তখন এটি এখানে খোলা যায়।',
			'watchTogether.notShareable' => 'এই ভিডিওটি ক্যাটাগোজ ম্যাক নেই, তাই একই সার্ভার অ্যাক্সেসের সাথে কেবল মানুষ এটি খেলতে পারে।',
			'watchTogether.searching' => 'এই ভিডিওটি আপনার লাইব্রেরিতে খুঁজে পেয়ে...',
			'watchTogether.yourCopy' => 'আপনার কপি',
			'watchTogether.sharingYourCopy' => 'আপনি আপনার কপি শেয়ার করছেন',
			'watchTogether.playingOtherLength' => ({required Object difference}) => 'আপনার কপি খেলতে, ${difference}',
			'watchTogether.mismatchTitle' => 'আপনার কপিটি ভিন্ন দীর্ঘতা।',
			'watchTogether.mismatchDescription' => ({required Object difference}) => 'আপনার সবচেয়ে কাছাকাছি কপিটি রুমের ভিডিও থেকে ${difference}। এটি অন্য কেট বা সংস্করণ হতে পারে।',
			'watchTogether.playAnyway' => 'খেলুন যেকোনো',
			'watchTogether.chooseAnotherCopy' => 'অন্য কপি নির্বাচন করুন',
			'watchTogether.dontPlay' => 'খেলবেন না',
			'watchTogether.unavailableTitle' => 'আপনি এই ভিডিও নেই',
			'watchTogether.unavailableDescription' => 'PlezyNG আপনার লাইব্রেরিতে এটি খুঁজে পাওয়া যায়নি. নিজের জন্য একটি কপি বা আবার খুঁজে পেতে পারেন।',
			'watchTogether.chooseCopy' => 'একটি কপি নির্বাচন করুন',
			'watchTogether.searchAgain' => 'আবার খোঁজ',
			'watchTogether.noCandidates' => 'আপনার লাইব্রেরিতে কোন কপি পাওয়া যায়নি।',
			'watchTogether.choiceFailed' => 'রুমের জন্য এই কপি খেলতে পারত না',
			'watchTogether.lengthLonger' => ({required Object duration}) => '${duration} আরও',
			'watchTogether.lengthShorter' => ({required Object duration}) => '${duration} ছোট',
			'watchTogether.lengthSame' => 'একই দীর্ঘতা',
			'watchTogether.lengthUnknown' => 'অজানা দীর্ঘতা',
			'watchTogether.joinCurrentPlayback' => 'বর্তমান Playback',
			'watchTogether.joinCurrentPlaybackDescription' => 'ঘরবাড়ি ফিরে যান যা ঘরবাড়ি বর্তমানে দেখছে',
			'watchTogether.stopMedia' => 'সবাইকে ভিডিও বন্ধ করুন',
			'watchTogether.syncOffset' => 'সনাক্ত Offset',
			'watchTogether.syncOffsetDescription' => 'আপনার ভিডিওটি পরিবর্তন করুন যদি এটি রুমের সামনে বা পিছনে চলছে।',
			'watchTogether.offsetHint' => ({required Object difference}) => 'আপনার কপিটি রুমের ভিডিও থেকে ${difference}।',
			'watchTogether.applyDifference' => ({required Object offset}) => 'ব্যবহার করুন ${offset}',
			'watchTogether.offsetMinusSecond' => '1 স',
			'watchTogether.offsetMinusTenth' => '100 মিসি',
			'watchTogether.offsetPlusTenth' => '+100 মিসি',
			'watchTogether.offsetPlusSecond' => '+1 স',
			'watchTogether.participants' => 'অংশগ্রহণকারী',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} অংশগ্রহণকারী', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} অংশগ্রহণকারী', ), 
			'watchTogether.hostBadge' => 'হেস্ট',
			'watchTogether.nameYou' => ({required Object name}) => '${name} (আপনি)',
			'watchTogether.playerIdle' => 'আইডেল',
			'watchTogether.playerLoading' => 'লোড',
			'watchTogether.playerReady' => 'প্রস্তুত',
			'watchTogether.playerBuffering' => 'বাফারিং',
			'watchTogether.matchSearching' => 'খোঁজ',
			'watchTogether.matchMatched' => 'ভিডিও আছে',
			'watchTogether.matchMismatched' => 'আলাদা দীর্ঘতা',
			'watchTogether.matchUnavailable' => 'ভিডিও নেই',
			'watchTogether.participantOffset' => ({required Object offset}) => 'অফসেট ${offset}',
			'watchTogether.makeHost' => 'হেস্ট করুন',
			'watchTogether.makeHostQuestion' => 'স্থানান্তর হোস্ট?',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} Playback নিয়ন্ত্রণ করবে এবং সেশনটি সবাইকে পরিচালনা করবে।',
			'watchTogether.transfer' => 'ট্রান্সফার',
			'watchTogether.removeParticipant' => 'রুম থেকে বের করুন',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => '${name} রক্ষা করা?',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} রুম ছেড়ে যায়. আপনি রুম বন্ধ না হলে তারা কোডের সাথে আবার যোগ করতে পারেন।',
			'watchTogether.remove' => 'সরান',
			'watchTogether.roomSettings' => 'রুমের সিস্টেম',
			'watchTogether.letEveryoneControl' => 'সবাই Playback নিয়ন্ত্রণ করুন',
			'watchTogether.lockRoom' => 'লক রুম',
			'watchTogether.lockRoomDescription' => 'নতুন কেউ যোগ দিতে পারে না।',
			'watchTogether.leaveRoom' => 'রুম ছেড়ে',
			'watchTogether.leaveRoomQuestion' => 'রুম ছেড়ে দেয়?',
			'watchTogether.leaveRoomConfirm' => 'আপনি আবারও রুম কোডের সাথে যোগ করতে পারেন।',
			'watchTogether.leave' => 'ছেড়ে',
			'watchTogether.endRoom' => 'শেষ রুম',
			'watchTogether.endRoomQuestion' => 'শেষ রুম?',
			'watchTogether.endRoomConfirm' => 'এতে সবাইকে রুমের শেষ হবে।',
			'watchTogether.end' => 'শেষ',
			'watchTogether.playBlockedTitle' => 'Playback শুরু হয়নি',
			'watchTogether.playBlockedDescription' => 'খেলা শুরু করে ঘর থেকে দেখতে চান।',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} প্রচুর খেলা',
			'watchTogether.notices.playbackStarted' => 'Playback শুরু',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} পাস',
			'watchTogether.notices.playbackPaused' => 'Playback বন্ধ',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} ${position} পর্যন্ত গিয়েছে',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => 'পাশাপাশি ${position}',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} গতিটি ${speed} পর্যন্ত নির্ধারণ করুন',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => 'গতি সংশোধন ${speed}',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} শুরু ${title}',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => 'এখন খেলতে ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} ভিডিও বন্ধ',
			'watchTogether.notices.mediaStopped' => 'ভিডিও বন্ধ',
			'watchTogether.notices.waitingFor' => ({required Object name}) => '${name} এর জন্য অপেক্ষা করছি।',
			'watchTogether.notices.waitingForSomeone' => 'অপেক্ষা করলে কেউ চাপে পড়বে...',
			'watchTogether.notices.finished' => 'শেষ',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} এখন হোস্ট',
			'watchTogether.notices.youAreNowHost' => 'আপনি এখন হোস্ট',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} যোগ করা',
			'watchTogether.notices.left' => ({required Object name}) => '${name} চলে গেছেন',
			'watchTogether.notices.controlRefused' => 'শুধুমাত্র হোস্ট Playback নিয়ন্ত্রণ করতে পারেন',
			'watchTogether.notices.searchFailed' => 'কিছু সার্ভার রুমের ভিডিও জন্য খুঁজে পেতে পারেননি',
			'watchTogether.notices.playBlocked' => 'শুরু করতে চান প্রেস খেলা',
			'watchTogether.notices.shareFailed' => 'এই ভিডিওটি রুমের সাথে শেয়ার করতে পারতাম না',
			'watchTogether.notices.downloadNotShared' => 'ডাউনলোডগুলি তাদের সার্ভার অফলি থাকলেও রুমের সাথে শেয়ার করা হয় না',
			'watchTogether.notices.openFailed' => 'রুমের ভিডিও খুলতে পারত না',
			'watchTogether.ended.ended' => 'হেস্টরুম শেষ করেছিলেন',
			'watchTogether.ended.kicked' => 'তুমি রুম থেকে বের হয়ে গেলো।',
			'watchTogether.ended.expired' => 'রুম শেষ হয়েছে',
			'watchTogether.ended.replaced' => 'আপনি অন্য ডিভাইসে এই রুমে যোগ করেন',
			'watchTogether.ended.lost' => 'রুমের সাথে সংযোগ হারিয়ে',
			'watchTogether.errors.invalidCode' => 'কোডগুলির মধ্যে 6 চিঠি এবং ডিগ্রী আছে, 0, 1, I, L বা O ছাড়া।',
			'watchTogether.errors.roomNotFound' => 'এই কোডের কোন রুম নেই, এটি শেষ হতে পারে।',
			'watchTogether.errors.roomFull' => 'সেই রুমটা পুরোপুরি।',
			'watchTogether.errors.roomLocked' => 'হেস্টরটি ওই রুমকে বন্ধ করে দিয়েছিল।',
			'watchTogether.errors.relayFull' => 'এখন কাজে লাগে, পরে আবার চেষ্টা করুন।',
			'watchTogether.errors.unreachable' => 'ঘন্টা একসাথে relay পৌঁছাতে পারত না. আপনার সংযোগ চেক করুন.',
			'watchTogether.errors.rateLimited' => 'একটু অপেক্ষা করুন এবং আবার চেষ্টা করুন।',
			'watchTogether.errors.clientBlocked' => 'এই সংস্করণ PlezyNG relay ব্যবহার করতে পারেন না. অ্যাপটি আপডেট করুন.',
			'watchTogether.errors.forbidden' => 'শুধুমাত্র হেস্টারই সেটা করতে পারেন।',
			'watchTogether.errors.notInRoom' => 'আপনি একটি রুমে নেই।',
			'watchTogether.errors.alreadyInRoom' => 'আপনি এখন একটি রুমে আছেন।',
			'watchTogether.errors.resumeFailed' => 'রুমে আসতে পারত না।',
			'watchTogether.errors.unsupported' => 'রেলিও এ ব্যাপারে সমর্থন করেনি।',
			'watchTogether.errors.generic' => 'কিছুটা ভুল হয়েছে, আবারও চেষ্টা করুন।',
			'watchTogether.untitledEpisode' => ({required Object number}) => 'আয়াত ${number}',
			'downloads.title' => 'ডাউনলোড',
			'downloads.manage' => 'পরিচালনা',
			'downloads.tvShows' => 'টেলিভিশন প্রদর্শন',
			'downloads.movies' => 'চলচ্চিত্র',
			'downloads.music' => 'সঙ্গীত',
			'downloads.tracksQueued' => ({required Object count}) => '${count} ট্র্যাক ডাউনলোডের জন্য',
			'downloads.noDownloads' => 'এখনো ডাউনলোড নেই',
			'downloads.noDownloadsDescription' => 'ডাউনলোড করা বিষয়বস্তু এখানে অফলি দেখার জন্য দেখা যাবে',
			'downloads.downloadNow' => 'ডাউনলোড',
			'downloads.deleteDownload' => 'ডাউনলোড করুন',
			'downloads.retryDownload' => 'ডাউনলোড করুন',
			'downloads.downloadQueued' => 'ডাউনলোড করি',
			'downloads.downloadResumed' => 'ডাউনলোড আবার',
			'downloads.serverErrorBitrate' => 'সার্ভার ভুল: ফাইলটি দূরবর্তী বিট্রেটের সীমাবদ্ধতা অতিক্রম করতে পারে',
			'downloads.storageFull' => 'ডাউনলোডগুলি সংরক্ষণ করার জন্য বন্ধ হয়ে যায়. কিছু স্থান বিনামূল্যে বা অন্য ডাউনলোড অবস্থান নির্বাচন করুন, তারপর ফেরত।',
			'downloads.storageUnavailable' => 'ডাউনলোড বন্ধ হয়ে গেছে কারণ उपलब्ध স্টোরেজ চেক করা যাবে না. ডাউনলোড অবস্থান চেক করুন, তারপর ফেরত।',
			'downloads.episodesQueued' => ({required Object count}) => '${count} পরিসংখ্যানগুলি ডাউনলোড করার জন্য',
			'downloads.downloadDeleted' => 'ডাউনলোড 삭제',
			'downloads.deleteConfirm' => ({required Object title}) => 'এই ডিভাইস থেকে "${title}" মুছে ফেলুন?',
			'downloads.deleteCollectionDownloads' => 'ডাউনলোড করুন',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => 'এই ডিভাইস থেকে "${title}" এর প্রতিটি ডাউনলোড মুছে ফেলুন?',
			'downloads.collectionDownloadsDeleted' => 'ডাউনলোড 삭제',
			'downloads.cancelledDownloadTitle' => 'বাতিল করা Download',
			'downloads.cancelledDownloadMessage' => 'এই ডাউনলোডটি বাতিল করা হয়েছে. আপনি কি করতে চান?',
			'downloads.allEpisodesAlreadyDownloaded' => 'সব ঘটনা এখন ডাউনলোড করা হয়েছে',
			'downloads.resumeDownload' => 'ডাউনলোড করুন',
			'downloads.cancelledDownload' => 'বাতিল ডাউনলোড',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (সিন্সিং ${status})',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => 'ডাউনলোড করা হয়েছে ${file} - সম্পূর্ণ করতে ক্লিক করুন',
			'downloads.partialDownloadClickToComplete' => 'সম্পূর্ণভাবে ডাউনলোড - ক্লিক করুন',
			'downloads.deleting' => 'মুছে ফেলা...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'মুছে ফেলুন ${title}... (${current} এর ${total})',
			'downloads.queuedTooltip' => 'কুরআন',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'মৌসুম ${files}',
			'downloads.downloadingTooltip' => 'ডাউনলোড...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'ডাউনলোড ${files}',
			'downloads.noDownloadsTree' => 'ডাউনলোড নেই',
			'downloads.pauseAll' => 'সবার paus',
			'downloads.resumeAll' => 'সমস্ত সমাধান',
			'downloads.retryAll' => 'সবাই ফিরে',
			'downloads.retryFailed' => 'ফেরত ফেরত ফেরত ফেরত ফেরত',
			'downloads.deleteAll' => 'সব মুছুন',
			'downloads.selectVersion' => 'নির্বাচন Version',
			'downloads.allEpisodes' => 'সব এপিসোড',
			'downloads.unwatchedOnly' => 'শুধুমাত্র চিন্তিত',
			'downloads.nextNUnwatched' => ({required Object count}) => 'পরবর্তী ${count} অপেক্ষা',
			'downloads.customAmount' => 'কাস্টম কমানো...',
			'downloads.customAmountAny' => 'কাস্টম সংখ্যা (একটি)',
			'downloads.randomEpisodes' => 'পরিস্থিতি',
			'downloads.includeSpecials' => 'বিশেষ বিশেষ',
			'downloads.howManyEpisodes' => 'কতটি ঘটনা?',
			'downloads.invalidEpisodeCount' => 'একটি সঠিক অধ্যায় সংখ্যা লিখুন।',
			'downloads.keepSynced' => 'সিনেমা রাখুন',
			'downloads.downloadOnce' => 'একবার ডাউনলোড',
			'downloads.keepNUnwatched' => ({required Object count}) => '${count} অদৃশ্য রাখুন',
			'downloads.editSyncRule' => 'সিনক নিয়ম',
			'downloads.removeSyncRule' => 'সিনক নিয়ম মুছে ফেলুন',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => '"${title}" সিঙ্ক করা বন্ধ করবেন? ডাউনলোড করা পর্বগুলি সংরক্ষিত থাকবে।',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => '“${title}” সিন্সিং বন্ধ করুন?',
			'downloads.deleteSyncRuleDownloads' => 'সংযুক্ত ডাউনলোডও মুছে ফেলুন',
			'downloads.deleteSyncRuleDownloadsDescription' => 'অন্য সনাক্স নিয়ম বা প্রোফাইল দ্বারা ব্যবহৃত ডাউনলোডগুলি সংরক্ষিত হবে।',
			'downloads.syncRuleCreated' => ({required Object count}) => 'সিনক নিয়ম তৈরি — ${count} অদৃশ্যক epizodes সংরক্ষণ',
			'downloads.syncRuleUpdated' => 'সিন্ক নিয়ম আপডেট',
			'downloads.syncRuleRemoved' => 'সিন্ক নিয়ম মুছে ফেলুন',
			'downloads.syncRuleAndDownloadsRemoved' => 'Sync নিয়ম এবং সংযুক্ত ডাউনলোড মুছে ফেলুন',
			'downloads.syncRuleCleanupBusy' => 'সিন্ক নিয়ম বর্তমানে আপডেট করা হচ্ছে. এক মুহূর্তে আবার চেষ্টা করুন.',
			'downloads.syncRuleCleanupUnavailable' => 'সংযুক্ত ডাউনলোড নিরাপদভাবে চিহ্নিত হতে পারে না. সার্ভার আবার সংযুক্ত করুন এবং আবার চেষ্টা করুন, বা ডাউনলোড মুছে ফেলে না নিয়মটি মুছে ফেলুন.',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => 'সিন্সেস ${count} নতুন অধ্যায় ${title} জন্য',
			'downloads.syncNow' => 'এখন সিনক',
			'downloads.downloadsUpToDate' => 'ডাউনলোড আপডেট',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => 'Sync complete · ${queued} queued, ${removed} মুছে ফেলা',
			'downloads.activeSyncRules' => 'সিনক নিয়ম',
			'downloads.reviewOrphanFiles' => 'ডাউনলোড করুন অর্পানড',
			'downloads.orphanReviewTitle' => 'ডাউনলোড করুন অর্পানড',
			'downloads.orphanReviewDescription' => 'এই ট্যাগ ফাইলগুলি PlezyNG এর ভিত্তিক অ্যাপ-ম্যানেজিত ডাউনলোড ফাইলগুলিতে রয়েছে এবং ডাউনলোড রেকর্ড বা কার্যকর কাজের সাথে সমাধান নেই।',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count} ফাইল · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => '${count} ফাইল মুছে ফেলুন',
			'downloads.orphanCleanupNone' => 'কোন ডাউনলোড ফাইল পাওয়া যায় না',
			'downloads.orphanCleanupFailed' => 'PlezyNG নিরাপদভাবে পরিচালিত ডাউনলোড ফোডার স্ক্যান করতে পারেনি. কোন ফাইলটি মুছে ফেলেনি।',
			'downloads.orphanCleanupChanged' => 'ডাউনলোডের তালিকা বিবেচনার সময় পরিবর্তিত হয়. ফাইলগুলি আবারও পরিষ্কার করার আগে বিবেচনা করুন.',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => 'মুছে ফেলেন ${count} অন্তর্ভুক্ত ফাইল · ${size} বিনামূল্যে',
			'downloads.noSyncRules' => 'কোন সিনক নিয়ম',
			'downloads.manageSyncRule' => 'সিনাক্স সিনাক্স',
			'downloads.editEpisodeCount' => 'Episode সংখ্যা',
			'downloads.editSyncFilter' => 'ফিল্টার Sync',
			'downloads.syncAllItems' => 'সব পণ্য সিন্সিকেশন',
			'downloads.syncUnwatchedItems' => 'অবিশ্বাসিত পণ্য সিন্সিং',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'সার্ভার: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'পাওয়া',
			'downloads.syncRuleOffline' => 'অফলিন',
			'downloads.syncRuleSignInRequired' => 'চিহ্নিত প্রয়োজনীয়',
			'downloads.syncRuleAccessDenied' => 'অ্যাক্সেস অনুরোধ',
			'downloads.syncRuleNotAvailableForProfile' => 'বর্তমান প্রোফাইলের জন্য পাওয়া যায় না',
			'downloads.syncRuleUnknownServer' => 'অজ্ঞাত সার্ভার',
			'downloads.syncRuleListCreated' => 'সিনক নিয়ম তৈরি',
			'downloads.backgroundWarning.bannerBlocked' => 'অ্যাপটি ছেড়ে গেলে ডাউনলোড বন্ধ হবে',
			'downloads.backgroundWarning.bannerDegraded' => 'ডাউনলোড সীমিত হতে পারে',
			'downloads.backgroundWarning.bannerAction' => 'বিস্তারিত',
			'downloads.backgroundWarning.sheetTitle' => 'ডাউনলোড করা হয় ব্লক',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'ডাউনলোড সীমিত হতে পারে',
			'downloads.backgroundWarning.sheetIntro' => 'Android সূত্রে নির্ভরযোগ্যভাবে ডাউনলোড করার জন্য PlezyNG বাধা দেয়।',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'আপনার ডিভাইস যখন PlezyNG ফাউনলোড করতে পারেন তখন সীমিত।',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'PlezyNG এর ফাউন্ডেশন ব্যবহার সীমিত. তার ব্যাটারি বা ফাউন্ডেশন ব্যবহারকে "অনীমিত" হিসাবে সীমিত করুন।',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android একটি সীমিত স্থিতিশীল অবস্থায় PlezyNG রাখা হয়েছে. তার ব্যাটারি ব্যবহারকে "অীমিত" হিসাবে স্থিতিশীল করুন।',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'ডাউনলোড通知গুলি বন্ধ করা হয়, তাই প্রদর্শন এবং নিয়ন্ত্রণ পাওয়া যায় না।',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Notifications are turned off. On Android 13 or later, they are required for long background downloads. এগুলি দীর্ঘ পর্যায়ে ডাউনলোডের জন্য প্রয়োজনীয়।',
			'downloads.backgroundWarning.reasonDataSaver' => 'ডেটা সেভার চালু থাকায় মোবাইল ডেটায় পটভূমিতে ডাউনলোড বন্ধ আছে। Wi-Fi-এ ডাউনলোড চলার কথা।',
			'downloads.backgroundWarning.reasonOemUnknown' => 'ডাউনলোডগুলি বারবার বন্ধ হয়েছিল যখন PlezyNG ফাউনলোডে ছিল। PlezyNG এর ব্যাটারি বা ফাউনলোড ব্যবহারের পরামর্শগুলি দেখুন।',
			'downloads.backgroundWarning.openSettings' => 'খোলা সিস্টেম',
			'downloads.backgroundWarning.stillNotWorking' => 'ডিভাইস-সpecific সহায়তা',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'আপনার ডিভাইসের জন্য পদক্ষেপ দেখুন, অথবা সমস্যা চলছে যদি Settings › View Logs থেকে একটি লগ পাঠান।',
			'downloads.backgroundWarning.dialogTitle' => 'ডাউনলোড শেষ হতে পারে না',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'ডাউনলোড করুন যেকোনো',
			'downloads.backgroundWarning.dialogFixFirst' => 'প্রথমেই এটি ঠিক করুন',
			'downloads.backgroundWarning.statusTile' => 'ডাউনলোড ফাউনলোড',
			'downloads.backgroundWarning.statusOk' => 'ফলাফলে চালু হতে পারে',
			'downloads.backgroundWarning.statusBlocked' => 'সিস্টেম সিস্টেম সিস্টেম সিস্টেম সিস্টেম',
			'downloads.backgroundWarning.statusDegraded' => 'সিস্টেম সীমিত',
			'downloads.backgroundWarning.statusUnknown' => 'এখনো চেক করা হয়নি',
			'downloads.backgroundWarning.settingsUnavailable' => 'এই ডিভাইসে সিস্টেম সেটিং খোলা যায় না',
			'downloads.backgroundWarning.linkUnavailable' => 'এই ডিভাইসে dontkillmyapp.com খোলা যায় না',
			'downloads.options' => 'ডাউনলোড বিকল্প',
			'downloads.groupings.library' => 'লাইব্রেরি',
			'downloads.groupings.collections' => 'কালেকশন',
			'downloads.unknownLibrary' => 'অজানা লাইব্রেরি',
			'downloads.unknownShow' => 'অজ্ঞাত প্রদর্শনী',
			'downloads.unknownSeason' => 'অজানা সপ্তাহ',
			'downloads.unknownAlbum' => 'অজ্ঞাত অ্যালবাম',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} সম্পন্ন',
			'downloads.storageUsed' => ({required Object size}) => 'ব্যবহৃত স্টোরেজ: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ডাউনলোড', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ডাউনলোড', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} প্রদর্শন', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} দেখুন', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} সিনেমা', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} চলচ্চিত্র', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} অ্যালবাম', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} অ্যালবাম', ), 
			'downloads.errorFileNotFound' => 'ফাইল পাওয়া যায় না (404)',
			'downloads.errorDownloadNotAllowed' => 'ডাউনলোড সার্ভার দ্বারা অনুমোদিত নয় (403)',
			'downloads.errorDownloadFailed' => 'ডাউনলোড ভুল',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'ডাউনলোড ভুল: ${reason}',
			'downloads.convertingOnServer' => 'সার্ভারের মাধ্যমে পরিদর্শন...',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => 'সার্ভার উপর পরিদর্শন · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => 'ডাউনলোড ভুল (HTTP ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => 'পদ্ধতি অনুসন্ধানের পর ভুল: ${reason}',
			'downloads.reasonFileNotSaved' => 'এই ডিভাইসে ফাইল সংরক্ষণ করা যায় না',
			'downloads.reasonCannotResume' => 'পৃথিবী ডাউনলোড করা সম্ভব নয়',
			'downloads.reasonDeviceStorageFull' => 'এই ডিভাইসটি স্টোরেজ থেকে বের হয়।',
			'downloads.notificationDownloading' => 'ডাউনলোড...',
			'downloads.notificationComplete' => 'সম্পূর্ণ ডাউনলোড',
			'downloads.notificationPaused' => 'ডাউনলোড বন্ধ',
			'shaders.title' => 'ছায়া',
			'shaders.noShaderDescription' => 'কোন ভিডিও উন্নয়ন',
			'shaders.nvscalerDescription' => 'নভিডিয়া ইমেজ স্ক্যানিং আরও দৃঢ় ভিডিও জন্য',
			'shaders.artcnnVariantNeutral' => 'নির্যাতন',
			'shaders.artcnnVariantDenoise' => 'ডেনোজ',
			'shaders.artcnnVariantDenoiseSharpen' => 'ডেনোইজ + শার্পেন',
			'shaders.qualityFast' => 'দ্রুত',
			'shaders.qualityHQ' => 'উচ্চ মানের',
			'shaders.mode' => 'মডিও',
			'shaders.importShader' => 'শারীরিক আমদানি',
			'shaders.customShaderDescription' => 'কাস্টম GLSL Shader',
			'shaders.shaderImported' => 'শারীরিক আমদানি',
			'shaders.shaderImportFailed' => 'শারীরিক অস্ত্র সরবরাহ করতে পারেনি',
			'shaders.deleteShader' => 'ছায়া ছাদ',
			'shaders.deleteShaderConfirm' => ({required Object name}) => '‘${name}’ নামের সংখ্যাটি মুছে ফেলুন',
			'companionRemote.title' => 'সহায়ক রিমোট',
			'companionRemote.connectedTo' => ({required Object name}) => 'সংযোগ ${name}',
			'companionRemote.unknownDevice' => 'অজ্ঞাত ডিভাইস',
			'companionRemote.session.startingServer' => 'দূরবর্তী সার্ভার চালানোর...',
			'companionRemote.session.hostAddress' => 'হোস্ট ঠিকানা',
			'companionRemote.session.connected' => 'সংযুক্ত',
			'companionRemote.session.serverRunning' => 'Remote Server সার্ভার',
			'companionRemote.session.serverStopped' => 'দূরবর্তী সার্ভার বন্ধ',
			'companionRemote.session.serverRunningDescription' => 'আপনার নেটওয়ার্কের মোবাইল ডিভাইস এই অ্যাপের সাথে সংযোগ করতে পারে',
			'companionRemote.session.serverStoppedDescription' => 'সার্ভার চালু করুন যাতে মোবাইল ডিভাইসগুলি সংযোগ করতে পারে',
			'companionRemote.session.usePhoneToControl' => 'এই অ্যাপটি নিয়ন্ত্রণ করতে আপনার মোবাইল ডিভাইস ব্যবহার করুন',
			'companionRemote.session.startServer' => 'সার্ভার শুরু',
			'companionRemote.session.stopServer' => 'সার্ভার বন্ধ',
			'companionRemote.session.minimize' => 'কমপক্ষে',
			'companionRemote.session.manualAddressHint' => 'ম্যানুয়াল সংযোগ ঠিকানা:',
			'companionRemote.pairing.discoveryDescription' => 'একই অ্যাকাউন্ট Plex সঙ্গে PlezyNG ডিভাইস এখানে দেখা যায়',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'সংযোগ...',
			'companionRemote.pairing.searchingForDevices' => 'সরঞ্জাম খুঁজছেন...',
			'companionRemote.pairing.noDevicesFound' => 'আপনার নেটওয়ার্কে কোন ডিভাইস পাওয়া যায়নি',
			'companionRemote.pairing.noDevicesHint' => 'ডেস্টোভে PlezyNG খুলুন এবং একই Wi-Fi ব্যবহার করুন',
			'companionRemote.pairing.availableDevices' => 'উপলব্ধ ডিভাইস',
			'companionRemote.pairing.manualConnection' => 'ম্যানুয়াল সংযোগ',
			'companionRemote.pairing.cryptoInitFailed' => 'নিরাপদ সংযোগ শুরু করতে পারবেন না. প্রথমে Plex এর সাথে সাইন আপ করুন।',
			'companionRemote.pairing.validationHostRequired' => 'দয়া করে হোস্ট ঠিকানা লিখুন',
			'companionRemote.pairing.validationHostFormat' => 'ফরম্যাটটি আইপি:পোর্ট (যেমন, 192.168.1.100:48632) হতে হবে।',
			'companionRemote.pairing.connectionTimedOut' => 'একই নেটওয়ার্ক ব্যবহার করুন, দুটি ডিভাইসে একই নেটওয়ার্ক ব্যবহার করুন।',
			'companionRemote.pairing.sessionNotFound' => 'ডিভাইস পাওয়া যায় না. নিশ্চিত করুন যে PlezyNG হোস্টারে চালু হয়।',
			'companionRemote.pairing.authFailed' => 'সনাক্তকরণ ভুল হয়েছে. দুটি ডিভাইসের একই অ্যাকাউন্ট Plex প্রয়োজন।',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'সংযোগ করতে পারিনি: ${error}',
			'companionRemote.pairing.codeTitle' => 'প্যারিস কোড',
			'companionRemote.pairing.codeDescription' => 'হোস্ট ডিভাইসে Companion Remote-তে প্রদর্শিত কোডটি প্রদর্শন করুন. দুটি ডিভাইস একটি সংস্করণ ব্যবহার করতে হবে যা নিরাপদ প্যারিয়ারি সমর্থন করে।',
			'companionRemote.pairing.codeInvalid' => 'হোস্ট কোড থেকে সব 32 বাক্স এবং নম্বর লিখুন।',
			'companionRemote.pairing.updateRequired' => 'উভয় ডিভাইসগুলি একটি সংস্করণে আপডেট করুন যা নিরাপদ প্যারিয়ারি সমর্থন করে।',
			'companionRemote.pairing.hostDescription' => 'এই কোডটি একবার প্রত্যেকটি দূরে প্রদান করুন. এটি গোপন রাখুন: এটি এই প্রোফাইলের নিয়ন্ত্রণ দেয়।',
			'companionRemote.pairing.resetCode' => 'প্যারিয়ার কোড পুনরায়',
			'companionRemote.pairing.resetDescription' => 'সমস্ত রিমোট বন্ধ করুন এবং একটি নতুন কোড তৈরি করুন. প্রতিটি রিমোটকে আবার প্যারি করতে হবে।',
			'companionRemote.remote.disconnectConfirm' => 'আপনি কি দূরবর্তী সেশন থেকে ডাউনলোড করতে চান?',
			'companionRemote.remote.reconnecting' => 'আবার সংযোগ...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'সন্ধান ${current} এর মধ্যে 5',
			'companionRemote.remote.retryNow' => 'ফিরে আসুন এখন',
			'companionRemote.remote.tabRemote' => 'দূরত্ব',
			'companionRemote.remote.tabPlay' => 'খেলা',
			'companionRemote.remote.tabMore' => 'আরও',
			'companionRemote.remote.menu' => 'মেনু',
			'companionRemote.remote.tabNavigation' => 'ট্যাব ন্যাভাইজেশন',
			'companionRemote.remote.tabDiscover' => 'খোঁজ',
			'companionRemote.remote.tabLibraries' => 'বইয়েরা',
			'companionRemote.remote.tabSearch' => 'অনুসন্ধান',
			'companionRemote.remote.tabDownloads' => 'ডাউনলোড',
			'companionRemote.remote.tabSettings' => 'সিস্টেম',
			'companionRemote.remote.previous' => 'পূর্ববর্তী',
			'companionRemote.remote.playPause' => 'খেলা / পাস',
			'companionRemote.remote.next' => 'পরবর্তী',
			'companionRemote.remote.seekBack' => 'ফেরত খুঁজুন',
			'companionRemote.remote.stop' => 'থামুন',
			'companionRemote.remote.seekForward' => 'FWD খুঁজে পেতে',
			'companionRemote.remote.volume' => 'পরিমাণ',
			'companionRemote.remote.volumeDown' => 'নিচে',
			'companionRemote.remote.volumeUp' => 'উড়ে',
			'companionRemote.remote.fullscreen' => 'ফুলস্ক্রিন',
			'companionRemote.remote.subtitles' => 'সাবটাইটেল',
			'companionRemote.remote.audio' => 'অডিও',
			'companionRemote.remote.searchHint' => 'ডেস্টোভে অনুসন্ধান...',
			'companionRemote.errors.noNetworkInterface' => 'কোন নেটওয়ার্ক ইন্টারফেস পাওয়া যায় না',
			'companionRemote.errors.authenticationFailed' => 'সনাক্তকরণ ভুল',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'দূরে সার্ভার চালু করতে পারিনি: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'দূরে অর্ডার পাঠানোর ক্ষমতা: ${error}',
			'companionRemote.errors.joinTimedOut' => 'সাক্ষাৎকারে অংশগ্রহণ করার সময়',
			'companionRemote.errors.failedToConnectAnyAddress' => 'কোনও ঠিকানা থেকে যোগাযোগ করতে পারিনি',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'সংযোগ হারিয়েছে ${attempts} চেষ্টা',
			'companionRemote.errors.connectionLost' => 'সংযোগ হারিয়ে গেছে',
			'companionRemote.closedBeforeAuth' => 'সনাক্তকরণের আগে বন্ধ করা',
			'videoSettings.playbackSpeed' => 'গতি Playback',
			'videoSettings.normalSpeed' => 'স্বাভাবিক',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'সক্রিয় (${duration})',
			'videoSettings.zoom' => 'জুম',
			'videoSettings.sleepTimer' => 'ঘুমের সময়',
			'videoSettings.audioSync' => 'অডিও সিনক',
			'videoSettings.subtitleSync' => 'Subtitle সিনাক্স',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'এখানে HDR পাওয়া যায় না - এই ডেভিসপ কম্পিউটার বা ভিডিও উত্পাদন এটি নিতে পারে না।',
			'videoSettings.hdrToneMapping' => 'HDR টন ম্যাপিং',
			'videoSettings.hdrToneMappingCompositor' => 'কম্পিউটার',
			'videoSettings.hdrToneMappingCompositorDescription' => 'উৎসের HDR ম্যাটা ডেটাগুলির মাধ্যমে প্রবেশ করুন এবং ডেটাবেট কম্পিউটর ম্যাপের মাধ্যমে এটি ছেড়ে দিন।',
			'videoSettings.hdrToneMappingPlayer' => 'প্লেয়ার',
			'videoSettings.hdrToneMappingPlayerDescription' => 'খেলোয়াড়ে ডিভাইসের পাইকেল সূর্যকে ম্যাপ করুন, তারপর ফলাফলটি কম্পিউটারকে বলুন।',
			'videoSettings.hdrToneMappingFailed' => 'HDR টন ম্যাপিং পরিবর্তন করা যায় না - পূর্ববর্তী মডিট এখনও সক্রিয়।',
			'videoSettings.audioOutput' => 'অডিও উৎস',
			'videoSettings.videoTrack' => 'ভিডিও ট্র্যাক',
			'videoSettings.videoTrackDescription' => 'কোন ভিডিও স্ট্রিম দেখানো হবে তা বেছে নিন। ফাইলে বিকল্প ভিডিও ট্র্যাক থাকলে MPV প্লেব্যাকে এটি পাওয়া যায়।',
			'videoSettings.videoTrackDefault' => 'ডিফল্ট',
			'videoSettings.videoTrackUnavailable' => 'কোনো বিকল্প ভিডিও ট্র্যাক নেই।',
			'videoSettings.videoTrackFailed' => 'ভিডিও ট্র্যাক পরিবর্তন করা যায়নি।',
			'videoSettings.videoTrackNumber' => ({required Object id}) => 'ট্র্যাক ${id}',
			'videoSettings.performanceOverlay' => 'অভ্যন্তরীণ Overlay',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'ঘরে',
			'videoSettings.audioOutputSpatial' => 'স্পেশাল অডিও',
			'videoSettings.audioOutputStereo' => 'স্টেরিও',
			'videoSettings.audioEqualizer' => 'Audio Equalizer অডিও equalizer',
			'videoSettings.audioEqualizerDescription' => '10-ব্যান্ড Equalizer এর জন্য MPV. অডিও ফিল্টার decoded আউডিও ব্যবহার করে এবং passthrough বন্ধ করে।',
			'videoSettings.audioEqualizerFlat' => 'ফ্লাইট',
			'videoSettings.audioEqualizerActive' => 'কাস্টম',
			'videoSettings.audioEqualizerSaveFailed' => 'Audio Equalizer সেটগুলি সংরক্ষণ করতে পারবেন না।',
			'videoSettings.audioEffectsDescription' => 'প্রভাব decoded অডিও ব্যবহার করে, তাই passthrough বের হয়. রুম পরিবেশ এবং স্টেয়েও বিতরণ নির্ভর করে MPV গঠন ও ট্র্যাক',
			'videoSettings.audioStereoWidth' => 'Stereo বিতর্ক',
			'videoSettings.audioSpatializer' => 'রুম পরিবেশ',
			'videoSettings.audioSpatializerDescription' => 'শান্ত রুমের প্রতিশ্রুতি যোগ করুন।',
			'videoSettings.audioPitch' => 'Pitch পরিবর্তন',
			'videoSettings.audioPitchDescription' => 'দ্রুত পরিবর্তন ছাড়া পাইচ পরিবর্তন করুন। MPV নির্মাণ করা উচিত Rubber Band.',
			'videoSettings.audioEffectUnavailable' => 'এই পথের জন্য এই প্রভাব পাওয়া যায় না অথবা MPV গঠন',
			'videoSettings.backgroundVideoAudio' => 'ভিডিও অডিও ফাউন্ডেশন',
			'videoSettings.backgroundVideoAudioDescription' => 'আপনি খেলোয়াড়কে ছেড়ে যখন ভিডিও অডিও খেলতে থাকেন; আপনি ফিরে যখন পর্যন্ত ছবি छिपा रहती है. Android একটি মিডিয়া প্লাইবক নীতি ব্যবহার করে।',
			'videoSettings.audioNormalization' => 'স্বাভাবিক শব্দ',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'অডিও ডকোড করুন PCM; passthrough বন্ধ হয়ে থাকে যখন এটি',
			'performanceOverlay.color' => 'রঙ',
			'performanceOverlay.performance' => 'কর্মক্ষমতা',
			'performanceOverlay.buffer' => 'বাফার',
			'performanceOverlay.app' => 'অ্যাপ',
			'performanceOverlay.decoder' => 'ডকোডার',
			'performanceOverlay.rawDecoder' => 'ডেকডার',
			'performanceOverlay.tunneling' => 'টুইটার',
			'performanceOverlay.passthrough' => 'পাস্টরো',
			'performanceOverlay.aspect' => 'দৃষ্টি',
			'performanceOverlay.rotation' => 'রোটেশন',
			'performanceOverlay.dvSource' => 'ডি উৎস',
			'performanceOverlay.dvPath' => 'ডি পথ',
			'performanceOverlay.dvRouteDecoder' => 'Dolby Vision ডকোডার',
			'performanceOverlay.dvRouteDecoderP81' => 'Dolby Vision ডকোডার (P7→8.1)',
			'performanceOverlay.dvRouteBaseLayer' => 'Base স্তর',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'HDR10 ভিত্তিক স্তর',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'HLG Base ল্যাগ',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'SDR ভিত্তিক স্তর',
			'performanceOverlay.dvRouteReshaped' => 'RPU রেসিপি (GPU পরবর্তী)',
			'performanceOverlay.dvRouteFelGraphActive' => 'পরীক্ষামূলক P7 FEL গ্রাফ (অসম্ভব)',
			'performanceOverlay.p7Conversion' => 'P7 কনভ',
			'performanceOverlay.sampleRate' => 'নমুনা হার',
			'performanceOverlay.pixelFormat' => 'পিক্সেল Fmt',
			'performanceOverlay.hwFormat' => 'ফিএমএফ',
			'performanceOverlay.matrix' => 'ম্যাট্রিক্স',
			'performanceOverlay.primaries' => 'প্রাথমিক',
			'performanceOverlay.transfer' => 'ট্রান্সফার',
			'performanceOverlay.renderFps' => 'ফিপিএস ফিপিএস',
			'performanceOverlay.displayFps' => 'ফিপিএস প্রদর্শন',
			'performanceOverlay.avSync' => 'A/V সিন্ক',
			'performanceOverlay.dropped' => 'ধ্বংস',
			'performanceOverlay.dvRpus' => 'ডিপিএল',
			'performanceOverlay.dvRpuAverage' => 'ডিপিএল এভগ',
			'performanceOverlay.dvSampleAverage' => 'ডিএসএইচএইচএইচ',
			'performanceOverlay.maxLuma' => 'ম্যাক্স লুমা',
			'performanceOverlay.minLuma' => 'মিন লুমা',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'ক্যাশ ব্যবহার',
			'performanceOverlay.cacheLimit' => 'ক্যাশি সীমা',
			'performanceOverlay.speed' => 'গতি',
			'performanceOverlay.player' => 'প্লেয়ার',
			'performanceOverlay.playMethod' => 'খেলা পদ্ধতি',
			'performanceOverlay.memory' => 'স্মৃতি',
			'performanceOverlay.uiFps' => 'ফিপিএস',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android HW',
			'performanceOverlay.decoderNvidiaHw' => 'Nvidia HW',
			'performanceOverlay.decoderQualcommHw' => 'কোলকোম HW',
			'performanceOverlay.decoderMediatekHw' => 'মিডিয়াম HW',
			'performanceOverlay.decoderExynosHw' => 'হ্যাঁ হ্যাঁ',
			'performanceOverlay.decoderSoftware' => 'সফটওয়্যার',
			'performanceOverlay.decoderHardware' => 'হার্ডওয়ার্ক',
			'performanceOverlay.tunnelingActive' => 'আক্রমণ',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted} (${failures} অসম্ভব)',
			'externalPlayer.title' => 'বিদেশী খেলোয়াড়',
			'externalPlayer.useExternalPlayer' => 'বাইরের খেলোয়াড় ব্যবহার',
			'externalPlayer.useExternalPlayerDescription' => 'অন্য অ্যাপে ভিডিও খোলা',
			'externalPlayer.selectPlayer' => 'খেলোয়াড় নির্বাচন',
			'externalPlayer.customPlayers' => 'কাস্টম খেলোয়াড়',
			'externalPlayer.systemDefault' => 'সিস্টেম ভুল',
			'externalPlayer.addCustomPlayer' => 'কাস্টম খেলোয়াড়',
			'externalPlayer.playerName' => 'খেলোয়াড় নাম',
			'externalPlayer.playerNameHint' => 'আমার খেলোয়াড়',
			'externalPlayer.playerCommand' => 'অর্ডার',
			'externalPlayer.playerPackage' => 'প্যাকেজ নাম',
			'externalPlayer.playerUrlScheme' => 'URL সিস্টেম',
			'externalPlayer.off' => 'বন্ধ',
			'externalPlayer.launchFailed' => 'খোলা খোলা খোলা খোলা খোলা খোলা',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} ইনস্টল করা হয় না',
			'externalPlayer.playInExternalPlayer' => 'বাইরের খেলোয়াড়ে খেলুন',
			'externalPlayer.description' => 'ভিডিও খুলতে অন্য অ্যাপটি নির্বাচন করুন. উপলব্ধ খেলোয়াড়গুলি আপনার ডিভাইস এবং ইনস্টলেড অ্যাপগুলির উপর নির্ভর করে।',
			'externalPlayer.systemDefaultDescription' => 'অপারেটিং সিস্টেম তার ডিফল্ট অ্যাপ্লিকেশন দিয়ে ভিডিও খুলবেন।',
			'externalPlayer.playerOptionDescription' => ({required Object player}) => '${player} সঙ্গে ভিডিও খুলুন।',
			'externalPlayer.playerNameDescription' => 'খেলোয়াড়ের তালিকায় উল্লেখিত ট্যাগ।',
			'externalPlayer.playerPackageDescription' => 'অ্যাপের Android প্যাকেজ নাম লিখুন, যেমন com.example.player।',
			'externalPlayer.playerCommandDescription' => 'এই ডিভাইসের জন্য ইনস্টল করা খেলোয়াড় কমান্ড বা executable পথ লিখুন।',
			'externalPlayer.playerUrlSchemeDescription' => 'ড্রাইভার চালু করার জন্য ব্যবহৃত URL নম্বর এবং পছন্দীয় URL নেম্বরে প্রদান করুন।',
			'metadataEdit.editMetadata' => 'এডিট',
			'metadataEdit.screenTitle' => 'মেটাডেটা এডিট করুন',
			'metadataEdit.basicInfo' => 'মৌলিক তথ্য',
			'metadataEdit.artwork' => 'শিল্প',
			'metadataEdit.advancedSettings' => 'উন্নত সিস্টেম',
			'metadataEdit.title' => 'Title নাম',
			'metadataEdit.sortTitle' => 'নামের তুলনা',
			'metadataEdit.originalTitle' => 'মূল নাম',
			'metadataEdit.releaseDate' => 'Release তারিখ',
			'metadataEdit.contentRating' => 'বিষয়বস্তু Rating',
			'metadataEdit.studio' => 'স্টুডিও',
			'metadataEdit.tagline' => 'সংক্ষিপ্ত পরিচিতি',
			'metadataEdit.summary' => 'সাবধান',
			'metadataEdit.poster' => 'পোস্টার',
			'metadataEdit.background' => 'ফাউন্ডেশন',
			'metadataEdit.logo' => 'লোগো',
			'metadataEdit.squareArt' => 'স্ক্রা শিল্প',
			'metadataEdit.selectPoster' => 'পোস্টার নির্বাচন',
			'metadataEdit.selectBackground' => 'ফাউন্ডেশন নির্বাচন করুন',
			'metadataEdit.selectLogo' => 'লোগো নির্বাচন করুন',
			'metadataEdit.selectSquareArt' => 'পৃথিবী শিল্প নির্বাচন',
			'metadataEdit.fromUrl' => 'URL থেকে',
			'metadataEdit.uploadFile' => 'ফাইল আপলোড',
			'metadataEdit.enterImageUrl' => 'ইমেজ URL লিখুন',
			'metadataEdit.imageUrl' => 'ইমেজ URL',
			'metadataEdit.metadataUpdated' => 'মেটাদাডেট আপডেট',
			'metadataEdit.metadataUpdateFailed' => 'মেটাদাটা আপডেট করতে পারেনি',
			'metadataEdit.artworkUpdated' => 'অ্যাকাউন্ট আপডেট',
			_ => null,
		} ?? switch (path) {
			'metadataEdit.artworkUpdateFailed' => 'শিল্প কাজ আপডেট করতে পারিনি',
			'metadataEdit.noArtworkAvailable' => 'কোন শিল্প কাজ পাওয়া যায় না',
			'metadataEdit.artworkOption' => ({required Object index}) => 'শিল্প বিকল্প ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'ছবির বিকল্প ${index}, নির্বাচিত',
			'metadataEdit.notSet' => 'সিস্টেম না',
			'metadataEdit.libraryDefault' => 'লাইব্রেরি ভুল',
			'metadataEdit.accountDefault' => 'অ্যাকাউন্ট ভুল',
			'metadataEdit.seriesDefault' => 'সিরিজ ভেঙে',
			'metadataEdit.episodeSorting' => 'আলাদা আলাদা',
			'metadataEdit.oldestFirst' => 'প্রথমে পুরাতন',
			'metadataEdit.newestFirst' => 'প্রথম নতুন',
			'metadataEdit.keep' => 'রাখুন',
			'metadataEdit.allEpisodes' => 'সব এপিসোড',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} সর্বশেষ পরিস্থিতি',
			'metadataEdit.latestEpisode' => 'সর্বশেষ epizode',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'গত ${count} দিনের মধ্যে প্রদর্শন করা হয়েছে',
			'metadataEdit.deleteAfterPlaying' => 'খেলাধুলা পরে খেলাধুলা',
			'metadataEdit.never' => 'কখনো',
			'metadataEdit.afterADay' => 'একদিন পরে',
			'metadataEdit.afterAWeek' => 'এক সপ্তাহ পরে',
			'metadataEdit.afterAMonth' => 'এক মাস পরে',
			'metadataEdit.onNextRefresh' => 'পরবর্তী ফ্রিজ',
			'metadataEdit.seasons' => 'সপ্তাহ',
			'metadataEdit.show' => 'প্রদর্শন',
			'metadataEdit.hide' => 'লুকিয়ে',
			'metadataEdit.episodeOrdering' => 'অর্ডার পরিস্থিতি',
			'metadataEdit.tmdbAiring' => 'সিনেমা ডেটাবেস (Aired)',
			'metadataEdit.tvdbAiring' => 'টেবিট ডেভেল (আরড)',
			'metadataEdit.tvdbAbsolute' => 'ট্যাগটি (Absolute )',
			'metadataEdit.metadataLanguage' => 'মেটাদাডেট ভাষা',
			'metadataEdit.useOriginalTitle' => 'মূল নাম ব্যবহার করুন',
			'metadataEdit.preferredAudioLanguage' => 'অডিও ভাষা প্রিয়',
			'metadataEdit.preferredSubtitleLanguage' => 'প্রিয় ভাষা Subtitle',
			'metadataEdit.subtitleMode' => 'Auto-Select Subtitle পদ্ধতি',
			'metadataEdit.manuallySelected' => 'ম্যানুয়াল নির্বাচন',
			'metadataEdit.shownWithForeignAudio' => 'বিদেশী অডিও সঙ্গে সনাক্ত',
			'metadataEdit.alwaysEnabled' => 'সবসময় অনুমোদিত',
			'metadataEdit.tags' => 'ট্যাগ',
			'metadataEdit.addTag' => 'Add ট্যাগ',
			'metadataEdit.genre' => 'ধরণ',
			'metadataEdit.director' => 'পরিচালক',
			'metadataEdit.writer' => 'লেখক',
			'metadataEdit.producer' => 'উৎপাদনকারী',
			'metadataEdit.country' => 'দেশ',
			'metadataEdit.collection' => 'সংগ্রহ',
			'metadataEdit.label' => 'লেবেল',
			'metadataEdit.quickTag' => 'দ্রুত Tag...',
			'matchScreen.match' => 'খেলা...',
			'matchScreen.fixMatch' => 'খেলা ফ্যাক্ট...',
			'matchScreen.unmatch' => 'খেলা',
			'matchScreen.unmatchConfirm' => 'এই ম্যাচটি পরিষ্কার করে? Plex এটি শেষ পর্যন্ত অসম্ভব হিসাবে আলাদা করে।',
			'matchScreen.unmatchSuccess' => 'অসম্ভব পণ্য',
			'matchScreen.unmatchFailed' => 'অসুবিধা অসুবিধা অসুবিধা',
			'matchScreen.matchApplied' => 'খেলায় প্রযোজ্য',
			'matchScreen.matchFailed' => 'খেলাটি অর্জন করতে পারেনি',
			'matchScreen.titleHint' => 'Title নাম',
			'matchScreen.yearHint' => 'বছর',
			'matchScreen.search' => 'অনুসন্ধান',
			'matchScreen.noMatchesFound' => 'খেলা খুঁজে পাওয়া যায় না',
			'serverTasks.title' => 'সার্ভার কাজ',
			'serverTasks.failedToLoad' => 'চাকরির লোড করতে পারেনি',
			'serverTasks.noTasks' => 'কোন কাজ চলবে না',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'সংযুক্ত',
			'trakt.connectedAs' => ({required Object username}) => 'সংযুক্ত @${username}',
			'trakt.disconnectConfirm' => 'Trakt অ্যাকাউন্ট বন্ধ করুন?',
			'trakt.disconnectConfirmBody' => 'PlezyNG এর মাধ্যমে ঘটনাবলীগুলি পাঠানোর সময় থেমে যাবে Trakt. আপনি যেকোনো সময়ে আবার সংযোগ করতে পারেন।',
			'trakt.scrobble' => 'বাস্তব সময়ের স্ক্রোবিলিং',
			'trakt.scrobbleDescription' => 'খেলা, pause, এবং stop events পাঠান Trakt Playback সময়।',
			'trakt.watchedSync' => 'সিন্ক দেখানো অবস্থা',
			'trakt.watchedSyncDescription' => 'যখন আপনি PlezyNG এর অনুসন্ধানের মত পণ্যগুলি চিহ্নিত করেন, তখন তারা Trakt এর অনুসন্ধানের মতও চিহ্নিত হয়।',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'সংযোগ Seerr',
			'seerr.serverUrl' => 'URL সার্ভার',
			'seerr.serverUrlHelper' => 'আপনার সার্ভিসের ঠিকানা',
			'seerr.checkServer' => 'চলুন',
			'seerr.signInWithJellyfin' => 'সাইন আপ করুন Jellyfin',
			'seerr.signInWithEmby' => 'সাইন আপ করুন Emby',
			'seerr.signInWithLocal' => 'স্থানীয় অ্যাকাউন্ট ব্যবহার করুন',
			'seerr.email' => 'ইমেইল',
			'seerr.noSignInMethods' => 'এই Seerr উদাহরণ কোন সাইন-ইন পদ্ধতি PlezyNG সমর্থন দেয় না।',
			'seerr.instance' => 'আয়াত',
			'seerr.disconnectConfirm' => 'চিঠি বন্ধ করুন?',
			'seerr.disconnectConfirmBody' => 'PlezyNG এই Seerr উদাহরণ ভুলে যাবে. প্রতিটি সময়ে আবার সংযোগ করুন.',
			'seerr.request' => 'অনুরোধ',
			'seerr.request4k' => '4K অনুসন্ধান',
			'seerr.seasons' => 'সপ্তাহ',
			'seerr.allSeasons' => 'সব সপ্তাহ',
			'seerr.advancedOptions' => 'উন্নত',
			'seerr.destinationServer' => 'ডিজিটাল সার্ভার',
			'seerr.qualityProfile' => 'মানের প্রোফাইল',
			'seerr.rootFolder' => 'রুট ফোলার',
			'seerr.languageProfile' => 'ভাষা প্রোফাইল',
			'seerr.tags' => 'ট্যাগ',
			'seerr.noTags' => 'কোন ট্যাগ',
			'seerr.defaultOption' => ({required Object name}) => '${name} (প্রধান)',
			'seerr.animeNote' => 'এই সিরিজটি একটি অ্যানিমি।',
			'seerr.requestSubmitted' => 'আবেদন প্রদান',
			'seerr.requestFailed' => ({required Object error}) => 'অনুরোধ ভুল হয়েছে: ${error}',
			'seerr.requestsLoadFailed' => 'অনুরোধের বিকল্পগুলি লোড করতে পারবেন না',
			'seerr.nothingToRequest' => 'সবকিছু এখনই পাওয়া যায় বা অনুরোধ করা যায়।',
			'seerr.statusAvailable' => 'পাওয়া',
			'seerr.statusPartiallyAvailable' => 'অংশগ্রহণযোগ্য',
			'seerr.statusRequested' => 'অনুরোধ',
			'seerr.statusProcessing' => 'প্রক্রিয়া',
			'seerr.statusBlocklisted' => 'ব্লক করা',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => '${url}: ${error} পৌঁছাতে পারে না',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => 'নো Seerr আবেদন ${url} (HTTP ${status})',
			'seerr.behindAuthProxy' => 'একটি সত্যি প্রাক্সি (SSO বা HTTP auth) Seerr পরিবর্তে উত্তর দেয়. PlezyNG এর মাধ্যমে নিবন্ধন করা যায় না: Seerr এর /api/v1 পথটি এই অ্যাপের জন্য প্রাক্সি অতিক্রম করে, অথবা একটি ঠিকানা ব্যবহার করুন যা সরাসরি Seerr পৌঁছায়।',
			'seerr.invalidUrl' => 'একটি সার্ভার ঠিকানা লিখুন, যেমন https://seerr.example.com',
			'seerr.quickConnectUnsupported' => 'এই Seerr প্রদর্শনটি Quick Connect সমর্থন করে না।',
			'seerr.notInitialized' => 'এই Seerr ইনস্টেশন প্রথম চালু সিস্টেমটি সম্পন্ন করেনি',
			'seerr.noPlexTokenForReauth' => 'নম্বর Plex টকেন আবারও নিবন্ধন করতে পাওয়া যায়',
			'seerr.noStoredCredentials' => 'আবার সাইন ইন করার জন্য সংরক্ষিত সাইন-ইন তথ্য পাওয়া যাচ্ছে না',
			'seerr.signInRejected' => 'সাইন-ইন ফাঁস করা হয়েছে',
			'seerr.noSessionCookie' => 'Seerr একটি সেশন কুকি প্রকাশ করেনি',
			'seerr.freshCookieRejected' => 'Seerr নতুন সেশন কুকি প্রত্যাহার করেছে',
			'seerr.noUserInformation' => 'Seerr ব্যবহারকারীর তথ্য ফিরিয়ে দেয়নি',
			'seerr.sessionRejectedAfterReauth' => 'পুনরাবৃত্তি পরে চিঠি বাতিল করা হয়।',
			'seerr.permissionDenied' => 'Seerr এই পদক্ষেপটি প্রত্যাখ্যান করেছে: আপনার অ্যাকাউন্টের প্রয়োজনীয় অনুমতি নেই',
			'seerr.permissionRevoked' => 'আপনি এখন আর এ ব্যাপারে অনুরোধ করার অনুমতি নেই।',
			'services.title' => 'পরিষেবা',
			'services.hubSubtitle' => 'সিনক উন্নয়ন দেখুন এবং নতুন টাইমের জন্য অনুরোধ করুন।',
			'services.integrations' => 'ইন্টারফেস',
			'services.notConnected' => 'সংযুক্ত না',
			'services.connectedAs' => ({required Object username}) => 'সংযুক্ত @${username}',
			'services.scrobble' => 'স্বয়ংক্রিয়ভাবে উন্নয়ন ট্র্যাক করুন',
			'services.scrobbleDescription' => 'আপডেট করুন আপনার তালিকায় যখন আপনি একটি epizode বা সিনেমা শেষ করেন।',
			'services.disconnectConfirm' => ({required Object service}) => 'ডাউনলোড করুন ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'PlezyNG আপডেট বন্ধ করবে ${service}. প্রতিটি সময়ে আবার সংযোগ করুন।',
			'services.connectFailed' => ({required Object service}) => '${service} এর সাথে যোগাযোগ করতে পারবেন না।',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'সংযোগ Simkl',
			'services.simklReconnect.subtitle' => 'এই সংযোগে ব্যবহৃত সাইন-ইন পদ্ধতি Simkl বন্ধ করে দিচ্ছে। পুনরায় সংযোগ করলে PlezyNG-কে অনুমোদন দিতে simkl.com খুলবে — PlezyNG কখনো আপনার পাসওয়ার্ড দেখতে পায় না। আপনার দেখার ইতিহাস Simkl-এ থাকবে।',
			'services.deviceCode.title' => ({required Object service}) => '${service} এর উপর PlezyNG সক্রিয় করুন',
			'services.deviceCode.instructions' => 'QR কোড স্ক্যান করুন, অথবা নিচের ঠিকানা দেখুন এবং এই কোডটি প্রদান করুন:',
			'services.deviceCode.openToActivate' => ({required Object service}) => '${service} সক্রিয় করতে খোলা',
			'services.deviceCode.copyCode' => 'সক্রিয় কোড কপি করুন',
			'services.deviceCode.waitingForAuthorization' => 'অনুমোদনের জন্য অপেক্ষা...',
			'services.deviceCode.codeCopied' => 'কোড কপি',
			'services.oauthProxy.title' => ({required Object service}) => 'সাইন আপ করুন ${service}',
			'services.oauthProxy.body' => 'এই QR কোড স্ক্যান করুন বা কোন ডিভাইসের URL খুলুন।',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'খোলা ${service} নিবন্ধন করতে',
			'services.pendingAuth.copyUrl' => 'কপি sign-in URL',
			'services.pendingAuth.urlCopied' => 'URL কপি',
			'services.libraryFilter.title' => 'লাইব্রেরি ফিল্টার',
			'services.libraryFilter.subtitleAllSyncing' => 'সকল লাইব্রেরি সিন্সিং',
			'services.libraryFilter.subtitleNoneSyncing' => 'কিছুই সিন্সিং',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} অবরোধ',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} অনুমোদিত',
			'services.libraryFilter.mode' => 'ফিল্টার মডেল',
			'services.libraryFilter.modeBlacklist' => 'নিষিদ্ধ তালিকা',
			'services.libraryFilter.modeWhitelist' => 'সাদা',
			'services.libraryFilter.modeHintBlacklist' => 'নিচে চেক করাগুলি ছাড়া প্রতিটি লাইব্রেরি সনাক্ত করুন।',
			'services.libraryFilter.modeHintWhitelist' => 'শুধুমাত্র নিচের লাইব্রেরিগুলি সিনক করুন।',
			'services.libraryFilter.libraries' => 'বইয়েরা',
			'services.libraryFilter.noLibraries' => 'কোন লাইব্রেরি নেই',
			'services.libraryFilter.modeDescription' => 'চেক করা লাইব্রেরিগুলো সিঙ্ক হওয়া থেকে আটকানো হবে নাকি শুধু সেগুলোই সিঙ্ক হবে, তা বেছে নিন।',
			'services.seerrDescription' => 'Seerr বা Overseerr এর সাথে সংযোগ করুন এবং মিডিয়া অনুরোধের জন্য টাইমগুলি খুঁজে পেতে।',
			'services.trackerDescriptions.trakt' => 'আপনার ট্র্যাক্ট অ্যাকাউন্টের সাথে সিনেমা দেখানো epizodes এবং মুভি।',
			'services.trackerDescriptions.mal' => 'অ্যানিমি তালিকা সনাক্ত করুন এবং MyAnimeList এর সাথে উন্নয়ন দেখুন।',
			'services.trackerDescriptions.anilist' => 'অ্যানিমি তালিকা সনাক্ত করুন এবং AniList এর সাথে উন্নয়ন দেখুন।',
			'services.trackerDescriptions.simkl' => 'সিন্ক চলচ্চিত্র, টেলিভিশন প্রদর্শন এবং অ্যানিমি দেখে Simkl সঙ্গে।',
			'services.trackerDescriptions.mdblist' => 'MDBList রিটার এবং তালিকায় পরামর্শগুলি দেখুন এবং অনুসন্ধান করুন।',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => 'যোগ করুন ${product} সার্ভার',
			'addServer.serverUrls' => 'URL সার্ভার',
			'addServer.serverUrlsHelper' => 'কয়েকটি ইউরলি অনুমোদিত, কোমাস দ্বারা আলাদা।',
			'addServer.findServer' => 'সার্ভার খুঁজুন',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'স্থানীয় সার্ভার ${product} খুঁজছেন ...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'স্থানীয় সার্ভার ${product}',
			'addServer.username' => 'ব্যবহারকারী নাম',
			'addServer.password' => 'পাসওয়ার্ড',
			'addServer.signIn' => 'সাইন ইন করুন',
			'addServer.change' => 'পরিবর্তন',
			'addServer.required' => 'প্রয়োজনীয়',
			'addServer.couldNotReachServer' => ({required Object error}) => 'সার্ভার পৌঁছাতে পারবেন না: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'অ্যাকাউন্ট ভুল: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect অসম্ভব: ${error}',
			'addServer.addPlexTitle' => 'সাইন আপ করুন Plex',
			'addServer.pinExpired' => 'PIN-টি অন্তর্ভুক্ত হওয়ার আগে শেষ হয়ে গেছে, আবারও চেষ্টা করুন।',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'অ্যাকাউন্ট নিবন্ধন করতে পারিনি: ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => 'আপনার ${product} সার্ভার URL লিখুন',
			'addServer.addConnectionTitle' => 'সংযোগ যোগ করুন',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => '${name} এর জন্য যোগ করুন',
			'addServer.signInWithPlexCard' => 'সাইন আপ করুন Plex',
			'addServer.signInWithPlexCardSubtitle' => 'এই ডিভাইসটি অনুমোদন করুন. শেয়ার সার্ভার যোগ করা হয়।',
			'addServer.signInWithPlexCardSubtitleScoped' => 'একটি অ্যাকাউন্ট Plex অনুমোদন করুন. বাড়ি ব্যবহারকারীদের প্রোফাইল হয়ে যায়।',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => 'সংযোগ ${product}',
			'addServer.connectToMediaBrowserCardSubtitle' => 'আপনার সার্ভার URL, ব্যবহারকারীর নাম এবং পাসওয়ার্ড লিখুন।',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => 'আপনার সার্ভার ${product} সার্ভারে প্রবেশ করুন. ${name} সার্ভারে সংযোগ করুন.',
			'addServer.borrowFromAnotherProfile' => 'অন্য প্রোফাইল থেকে ডাউনলোড',
			'addServer.borrowFromAnotherProfileSubtitle' => 'পিন সুরক্ষিত প্রোফাইলগুলি একটি পিন প্রয়োজন।',
			'addServer.invalidCredentials' => 'ভুল ব্যবহারকারীর নাম বা পাসওয়ার্ড',
			'addServer.authResponseNotJson' => 'সনাক্তকরণ উত্তর সঠিক ছিল না JSON',
			'addServer.authResponseIncomplete' => 'সার্ভার থেকে sign-in উত্তর অসম্পূর্ণ ছিল',
			'addServer.quickConnectRejected' => 'Quick Connect সার্ভার দ্বারা বাতিল করা হয়',
			'addServer.quickConnectNotJson' => 'Quick Connect উত্তরটি সঠিক ছিল না JSON',
			'addServer.quickConnectMissingFields' => 'উত্তর Quick Connect একটি কোড বা গোপনতা অল্প',
			'addServer.quickConnectPollRejected' => 'Quick Connect সার্ভার দ্বারা অনুরোধ করা হয়',
			'addServer.serverTimedOut' => 'সার্ভার সঠিক সময়ে উত্তর দেয়নি।',
			'addServer.responseNotJson' => 'সার্ভার প্রতিক্রিয়া সঠিক ছিল না JSON',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'উত্তর একটি ID বা সার্ভার নামের অভাব - এটি একটি সার্ভার ${product}?',
			'addServer.probeFailed' => ({required Object error}) => 'সার্ভার পৌঁছাতে পারবেন না: ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => 'সার্ভার URL ${product} এর জন্য কমপক্ষে একটি প্রদান করুন',
			'addServer.noReachableServer' => ({required Object product}) => 'পাওয়া যায় না ${product} সার্ভার',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'এই URLগুলি বিভিন্ন ${product} সার্ভারগুলিকে লক্ষ্য করে',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'এই URLটি সার্ভার ${product} এর সাথে সংযুক্ত নয়',
			'addServer.redirectUnsupported' => 'সার্ভার একটি সমর্থিত URL-এর জন্য পুনরায় পরিচালিত',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'সার্ভারটি অন্য হোস্টের জন্য রেকর্ড করা হয়. শেষ URL ${product} সরাসরি প্রদান করুন.',
			'addServer.redirectInsecure' => 'সার্ভারটি HTTPS থেকে নিরাপদ URL-এর জন্য রেকর্ড করা হয়',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'সার্ভারটি একটি সমর্থিত URL-এর জন্য পুনরায় পরিচালিত হয়. শেষ URL ${product} সরাসরি প্রদান করুন.',
			'addServer.directPlexServerUrl' => 'Plex সার্ভার URL',
			'addServer.directPlexServerUrlHelper' => 'আপনার Plex মিডিয়া সার্ভারের স্থানীয় আইপি এবং পোর্ট প্রদান করুন।',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex টোকেন (অন্যাশনাল)',
			'addServer.plexTokenHelper' => 'এই সার্ভারে AUTH ছাড়া অ্যাক্সেস অনুমোদিত হয় যদি এটি অ্যাক্সেস করা হয়।',
			'addServer.plexTokenRequired' => 'আপনার টোকেন Plex (X-Plex-Token) লিখুন।',
			'addServer.connectDirectPlexCard' => 'Plex মিডিয়া সার্ভার (প্রাস্তিক / স্থানীয়)',
			'addServer.connectDirectPlexCardSubtitle' => 'স্থানীয় আইপি বা URL ব্যবহার করে সরাসরি সংযোগ করুন plex.tv অ্যাকাউন্ট ছাড়া।',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => 'স্থানীয় আইপি বা URL ব্যবহার করে সরাসরি সংযোগ করুন. ${name} এর সাথে সংযোগ করুন.',
			'addServer.insecureTitle' => 'অক্রিপ্ট সংযোগ',
			'addServer.insecureDescription' => ({required Object url}) => '${url} HTTP ব্যবহার করে। নেটওয়ার্কের অন্যরা আপনার পাসওয়ার্ড, টোকেন ও মিডিয়া পড়তে বা পরিবর্তন করতে পারে। সম্ভব হলে HTTPS ব্যবহার করুন। এই নেটওয়ার্ককে বিশ্বাস করলে এবং ঝুঁকি মেনে নিলেই কেবল এগিয়ে যান।',
			'addServer.allowHttp' => 'HTTP-এর অনুমতি দিন',
			'addServer.httpsRequired' => 'HTTPS ব্যবহার করুন বা স্পষ্টভাবে একটি অক্রিপ্ট সংযোগ অনুমতি দেয়।',
			'cast.chooseDevice' => 'কোনো ডিভাইসে কাস্ট করুন',
			'cast.searching' => 'খুঁজে বের করতে গিয়েছে ক্যাস্ট ডিভাইস...',
			'cast.connectedTo' => ({required Object device}) => 'সংযোগ ${device}',
			'cast.device' => 'কাস্ট ডিভাইস',
			'cast.readyToCast' => 'কাস্ট করার জন্য প্রস্তুত',
			'cast.subtitle' => 'সাবটাইটেল',
			'cast.serverNotAvailable' => 'মিডিয়া সার্ভার পাওয়া যায় না।',
			'cast.stopCasting' => 'কাস্ট করা বন্ধ করুন',
			'cast.castToDevice' => 'ডিভাইসে কাস্ট করুন',
			'cast.noEpisodeAvailable' => 'খেলাটি খেলতে পাওয়া যায় না।',
			'cast.startFailed' => 'সার্ভার দেখুন এবং আবার চেষ্টা করুন।',
			'automation.noActivePlayback' => 'নিয়ন্ত্রণ করার জন্য কোন সক্রিয় ভিডিও সেশন নেই।',
			'notifications.newEpisodeTitle' => 'নতুন epizode',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appAccess.title' => 'সাত দিনের জন্য প্রতিটি ফ্রি ফাইনাল চেষ্টা করুন।',
			'appAccess.description' => 'সাত দিনের একটি পরীক্ষা শুরু করুন, প্রতিটি PlezyNG বৈশিষ্ট্যগুলির পূর্ণ অ্যাক্সেসের সাথে. পরীক্ষার সময় কোন ফরজ নেই এবং কোন অ্যাকাউন্ট নেই. পরীক্ষার পরে, আপনার দোকানের মূল্যতে একটি জীবন-যাত্রা কিনা PlezyNG জীবন-যাত্রা জন্য লুকিয়ে দেয়।',
			'appAccess.trialEndedDescription' => 'আপনার দোকানের মূল্যতে একটি কেনার সাথে জীবনযাপনের জন্য PlezyNG এর প্রতিটি বৈশিষ্ট্য বন্ধ করুন।',
			'appAccess.startTrial' => 'সাত দিনের বিনামূল্যে পরীক্ষা শুরু করুন',
			'appAccess.trialActive' => 'আপনার সাত দিনের full-feature পরীক্ষা কার্যকর।',
			'appAccess.trialEnded' => 'সাত দিনের মামলা শেষ হয়েছে।',
			'appAccess.trialStartFailed' => 'এই ডিভাইসে পরীক্ষা সংরক্ষণ করতে পারিনি, कृपया আবারও চেষ্টা করুন।',
			'appAccess.lifetimeTitle' => 'PlezyNG জীবনের জন্য অপসারণ',
			'appAccess.lifetimeBody' => 'ধন্যবাদ! আপনি প্রতিটি PlezyNG বৈশিষ্ট্যে জীবনযাপন করতে পারেন।',
			'appAccess.manageTitle' => 'PlezyNG জীবনের অ্যাক্সেস',
			'appAccess.manageDescription' => 'প্রতিটি বৈশিষ্ট্যটি সাত দিনের জন্য বিনামূল্যে চেষ্টা করুন, তারপর আপনার দোকানের মূল্যে এক টাকা দিয়ে জীবনের জন্য সবকিছু খোঁজে ফেলুন।',
			'appAccess.buy' => ({required Object price}) => '${price} এর জন্য প্রতিটি বৈশিষ্ট্য খোলা',
			'appAccess.loadingPrice' => 'লোডিং দোকান মূল্য...',
			'appAccess.retryPrice' => 'ফেরতের মূল্য অনুসরণ',
			'appAccess.restore' => 'জীবনযাত্রা খরচ পুনরায়',
			'appAccess.pending' => 'আপনার কেনা भुगतान বা অনুমোদন অপেক্ষায় থাকে. লাইফ টাইম অ্যাক্সেস বন্ধ হয়ে যায় যখন স্টোর এটি সম্পূর্ণ করে।',
			'appAccess.storeUnavailable' => 'কেনাকাটা পাওয়া যায় না. দেখুন যে আপনি স্টোরে স্বাক্ষর করা হয়েছে এবং কেনাকাটা এই ডিভাইসে অনুমোদিত হয়।',
			'appAccess.productNotFound' => 'এই স্টোরে এখনো PlezyNG লাইভ লাইভ লক পাওয়া যায় না।',
			'appAccess.productQueryFailed' => 'দোকান মূল্য লোড করতে পারবেন না. আপনার সংযোগ চেক করুন এবং আবার চেষ্টা করুন।',
			'appAccess.purchaseFailed' => 'কেনাকাটা শেষ হয়নি, আবারও চেষ্টা করুন।',
			'appAccess.restoreFailed' => 'আপনি আপনার কেনাকাটা ফিরিয়ে দিতে দোকান পৌঁছাতে পারবেন না. আবার চেষ্টা করুন.',
			'appAccess.nothingToRestore' => 'এই স্টোর অ্যাকাউন্টের জন্য নম্বর PlezyNG লাইভ লাইভ ক্রয় পাওয়া যায়।',
			'detail.endsAt' => ({required Object time}) => 'ফাইনাল ${time}',
			'watchLink.serverUnavailable' => 'এই লিঙ্কের জন্য Plex সার্ভার পৌঁছাতে পারিনি।',
			'watchLink.notFound' => 'আপনার সার্ভারগুলিতে এই প্রদর্শন বা ভিডিওটি পাওয়া যায় না Plex।',
			'watchLink.ambiguous' => 'এই লিঙ্কটি একটি সার্ভারের বেশি পণ্যগুলির সাথে সমাধান করে. লিঙ্কটিতে সার্ভার যোগ করুন.',
			'watchLink.plexOnly' => 'দেখুন লিঙ্কগুলি বর্তমানে শুধুমাত্র Plex সার্ভারগুলি সমর্থন করে।',
			'watchLink.unsupportedItem' => 'দেখুন লিঙ্কগুলি শুধুমাত্র একটি প্রদর্শনী বা একটি চলচ্চিত্র খুলতে পারে।',
			'watchLink.menuItem' => 'দেখুন লিঙ্ক',
			'watchLink.dialogTitle' => 'দেখুন লিঙ্ক',
			'watchLink.dialogShowHint' => 'এই লিঙ্কটি খুলতে পরবর্তী অধ্যায় খেলবে. শফলে शो খেলতে শেষ পর্যন্ত &mode=shuffle যোগ করুন।',
			'watchLink.dialogMovieHint' => 'এই লিঙ্কটি খুলে চলচ্চিত্রটি খেলবে।',
			'watchLink.copy' => 'কপি',
			'watchLink.copied' => 'লিঙ্ক কপি',
			'homeLayout.title' => 'Home লিওট',
			'homeLayout.resetToast' => 'Home Reset to the original Plezy হেরো layout',
			'homeLayout.resetHeroTitle' => 'হ্যারি ল্যাগিংটি পুনরায় স্টক Plezyতে ফেরত?',
			'homeLayout.resetHeroBody' => 'প্রতিটি রানের হেরো সিস্টেম বন্ধ করে এবং হোমের শীর্ষে একমাত্র রুটিং ব্যানার ফেরত দেয়, যেমন হেরো রানগুলি আগে ছিল।',
			'homeLayout.removeRowTitle' => 'Home রান্না বন্ধ করুন?',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} মুছে ফেলবে. এটি অস্বীকার করা যাবে না।',
			'homeLayout.sync' => 'সিনক',
			'homeLayout.syncAccountTitle' => 'আপনার অ্যাকাউন্ট Plex সঙ্গে সিনিক্রেশন layout',
			'homeLayout.syncAccountOn' => 'এ: এই ডিভাইস আপনার অন্যান্য ডিভাইসের সাথে পরিকল্পনা, পরিকল্পনা, হেরো এবং অটো-স্লাইড শেয়ার করে।',
			'homeLayout.syncAccountOff' => 'ডাউনলোড: এই ডিভাইস নিজের লাইজিং রাখে।',
			'homeLayout.syncNow' => 'এখন সিনক',
			'homeLayout.plexHomeManager' => 'Plex হোম ম্যানেজার',
			'homeLayout.managePlexRows' => 'পরিচালনা Plex লাইন Plezy',
			'homeLayout.managePlexRowsDescription' => 'Home-Selected রানগুলি সংগঠন করার জন্য খোলা',
			'homeLayout.organizeHomeRows' => 'Home রানার সংগঠন',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} লাইন: গাড়ি, হেরো, অটো-স্লাইড, মুছে ফেলুন',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => 'সংগঠন ${library} লাইন',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => 'Continue Watching + ${n} লাইন: গাড়ি, লাইব্রেরি, বাড়ি, হেরো, অটো-স্লাইড',
			'homeLayout.renderAsHero' => 'কার্ডের হেয়ার হিসাবে রেন্ডার',
			'homeLayout.heroOnlySingleCollection' => 'শুধুমাত্র এই পর্যায়ে একক সংগ্রহের বাস্তব টাইমগুলিতে সমাধান করা হয়',
			'homeLayout.hero' => 'হেরো',
			'homeLayout.autoSlide' => 'অটো-স্লাইড',
			'homeLayout.autoSlideDescription' => 'এছাড়াও প্রতি কয়েক সেকেন্ডে নিজেদের সাথে স্লাইড করে. লোড (PC) এবং ড-প্যাড (TV) সবসময় কাজ করে এবং টাইমারটি পুনরায় চালু করে।',
			'homeLayout.autoSlideEditDescription' => 'এছাড়াও প্রতি কয়েক সেকেন্ডে নিজে থেকে স্লাইড করে. অটো: শুধুমাত্র একটি প্লাইড (PC) ক্লিক করে বা দূরে (TV) বাম / ডান চাপ করে যখন移動 করে. প্লাইড এবং d-প্যাড সবসময় উভয়ভাবে কাজ করে।',
			'homeLayout.enableHeroFirst' => 'প্রথমে হেরো',
			'homeLayout.showOnHome' => 'Home Screen দেখুন',
			'homeLayout.home' => 'বাড়ি',
			'homeLayout.removeFromHome' => 'বাড়ি থেকে বের করা',
			'homeLayout.selectRowsFirst' => 'প্রথমে নিচে হোম রানগুলি নির্বাচন করুন।',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} Plex পরিচালিত লাইন',
			'homeLayout.continueWatching' => 'দেখা অব্যাহত রাখুন',
			'homeLayout.continueWatchingLibraryDescription' => 'এই লাইব্রেরির নিজস্ব পুনরাবৃত্তি-প্রগ্রেস লাইন',
			'homeLayout.continueWatchingHomeDescription' => 'বাড়িতে প্রদর্শনিত পুনরাবৃত্তি-প্রদর্শন পর্যায়ে',
			'homeLayout.nextUpHomeDescription' => 'Next Unwatched Episode পরবর্তী পরিস্থিতি নির্দিষ্টভাবে দেখানো হয় Home',
			'homeLayout.library' => 'লাইব্রেরি',
			'homeLayout.showInRecommended' => 'লাইব্রেরিতে প্রদর্শন করা উচিত',
			'homeLayout.customPlexRow' => 'কাস্টম Plex রান',
			'homeLayout.heroNeedsLibrary' => 'প্রথমে লাইব্রেরি চেক করুন — হ্যারো দেখার জন্য কোথাও প্রয়োজন',
			'homeLayout.heroNeedsSurface' => 'প্রথমে লাইব্রেরি বা হোম দেখুন — হেরো দেখার জন্য কোথাও প্রয়োজন',
			'homeLayout.removeHub' => 'হাব থেকে বের করুন',
			'homeLayout.noPlexRows' => 'নম্বর Plex পরিচালিত লাইন এই লাইব্রেরি জন্য ফিরে এসেছে।',
			'homeLayout.openDetails' => 'খোলা বিস্তারিত',
			'homeLayout.heroCards' => 'হেরো কার্ড',
			'homeLayout.tapHeroCard' => 'হ্যারিয়ার কার্ড খুঁজে বের',
			'homeLayout.tvPlayFocus' => 'টেলিভিশন দূরে: উচ্চ আলো Play बटन',
			'homeLayout.tvPlayFocusDescription' => 'ড-প্যাড ডাউনলোড খেলা বোতামটি বন্ধ করে, পরবর্তী লাইন থেকে চলে যাওয়ার আগে।',
			'homeLayout.tvWrap' => 'টেলিভিশন দূরে: লপ হেরো কার্ড',
			'homeLayout.tvWrapDescription' => 'শেষ কার্ডের দিকে প্রথম কার্ডের দিকে ফিরে যায়. শেষ কার্ডের দিকে বন্ধ থাকে. প্রথম কার্ডের দিকে সবসময় পাশের দিকে যায়.',
			'homeLayout.castOnHero' => 'হ্যারি ব্যানার',
			'homeLayout.castOnHeroDescription' => 'একটি হ্যারি ব্যানারের নম্বরে চিঠি প্রদর্শন করুন. অন্তর্ভুক্ত রাখে শুধুমাত্র शीर्षक এবং সংখ্যা।',
			'homeLayout.customRows' => 'কাস্টম রাস্তায়',
			'homeLayout.loading' => 'Home Layout লোডিং...',
			'homeLayout.noCustomRows' => 'এখনো কোন কাস্টম রাইড নেই',
			'homeLayout.addRowHint' => 'একটি তৈরি করার জন্য বাড়ি লাইন যোগ করুন।',
			'homeLayout.addHomeRow' => 'বাড়ি রান করুন',
			'homeLayout.addHomeRowDescription' => 'একটি বিভাগ নির্বাচন করুন; নতুন পর্যায়ে স্বয়ংক্রিয়ভাবে সংস্থার যোগ করা হয়',
			'homeLayout.removeRow' => 'রানী মুছে ফেলে',
			'homeLayout.recentlyAdded' => 'সম্প্রতি যোগ করা',
			'homeLayout.recentlyReleased' => 'সম্প্রতি মুক্তি',
			'homeLayout.movieCollections' => 'চলচ্চিত্র সংগ্রহ',
			'homeLayout.showCollections' => 'সংগ্রহ দেখুন',
			'homeLayout.rowTitle' => 'রু টাইম',
			'homeLayout.content' => 'উপভোগ',
			'homeLayout.showThisRowIn' => 'এই রান দেখুন:',
			'homeLayout.libraryRecommended' => 'লাইব্রেরি প্রস্তাব',
			'homeLayout.heroCard' => 'হেরো কার্ড',
			'homeLayout.heroCardDescription' => 'একটি পেস্টের ছাপের পরিবর্তে একটি পুরো ব্যাগ রুটিং কার্ড হিসাবে প্রদর্শন করা হয়।',
			'homeLayout.heroUnavailableDescription' => 'শুধুমাত্র এই পর্যায়ে একক সংগ্রহের বাস্তব টাইমগুলির জন্য সমাধান করা হয় - একটি সংগ্রহের বেশি নির্বাচন করা হয়, কোন একটি টাইম ঘুরতে হবে না।',
			'homeLayout.librariesSelection' => 'লাইব্রেরি (একটি লাইব্রেরি প্রত্যেকের জন্য চেক না করে রাখুন)',
			'homeLayout.librariesMergedDescription' => 'এখানে চেক করা প্রতিটি লাইব্রেরি এই এক লাইনে যোগ করা হয়।',
			'homeLayout.movieCollectionsSelection' => 'চলচ্চিত্র সংগ্রহ (প্রত্যেক নির্বাচিত লাইব্রেরি জন্য সব অচেনা রাখুন)',
			'homeLayout.showCollectionsSelection' => 'সংগ্রহগুলি দেখুন (প্রত্যেকটি নির্বাচিত লাইব্রেরি জন্য সমস্ত চেক না রাখুন)',
			'homeLayout.collectionRowsDescription' => 'যদি একটি সংগ্রহ একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু একটু',
			'homeLayout.allCollections' => 'সকল সংগ্রহ',
			'homeLayout.noRowsHere' => 'এখনো এখানে কোন রান নেই।',
			'homeLayout.hideWatchedRows' => 'চিহ্নিত পণ্যগুলি সুরক্ষিত',
			'homeLayout.hideWatchedRowsDescription' => 'পুরোপুরি দেখানো টাইম বাড়ি এবং লাইব্রেরি রিপোর্টের লাইন ছেড়ে দেয়।',
			'homeLayout.untitledCollection' => 'অথিত সংগ্রহ',
			'homeLayout.moveRowHint' => 'আপ/ডাউন: লাইন বের করুন · Select: drop it here · Back: cancel',
			'homeLayout.organizeRowsHint' => 'একটি পর্যায়ে নির্বাচন করুন (অথবা রাখুন Select): move it · Left/Right: line options · Back: done',
			'homeLayout.layoutNavDescription' => 'লাইব্রেরি, লাইব্রেরি এবং সংগ্রহ বিভাগগুলি নির্বাচন করুন',
			'homeLayout.editHomeRow' => 'Edit Home রান',
			'homeLayout.resetHeroButton' => 'হ্যারি রেজিস্ট্রেশন পুনরায় স্টক Plezy',
			'homeLayout.reorderingUnlocked' => 'অ্যাক্সেস অ্যাক্সেস',
			'homeLayout.reorderingLocked' => 'লুকিয়ে রাখা',
			'homeLayout.rowsCanBeDragged' => 'চুলগুলি চাপ করা যেতে পারে - এই অ্যাক্সেসের জন্য লকটি চাপ করুন',
			'homeLayout.tapLockToDrag' => 'লকটি চাপিয়ে চাপিয়ে রাখুন',
			'homeLayout.customRowLabel' => ({required Object title}) => 'কাস্টম: ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => 'লুকিয়ে',
			'homeLayout.remove' => 'সরান',
			'homeLayout.libraryResumeRow' => 'এই লাইব্রেরি রেজিস্ট্রেশন',
			'homeLayout.pressAgainToDelete' => 'আবারও চাপ করুন মুছে ফেলুন',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => 'এতে',
			'homeLayout.resetHeroButtonDescription' => 'প্রতিটি রানের হেরো সিস্টেম বন্ধ করে এবং হেরো রানগুলি অস্তিত্বের আগের মতো একটি রুটিং ব্যানার পেরিয়ে দেয়।',
			'homeLayout.tapHeroCardDescription' => 'সিদ্ধান্ত করুন যে একটি হেরো কার্ডটি ট্যাপিং বা নির্বাচন করে Playback শুরু হয় কিংবা তার ডেটা খুলে যায়।',
			'homeLayout.heroTapPlayDescription' => 'দ্রুত নির্বাচন করা পণ্য শুরু করুন।',
			'homeLayout.heroTapDetailsDescription' => 'একটি পদক্ষেপ নির্বাচন করার আগে নির্বাচিত পণ্যের বিস্তারিত খুলুন।',
			'platform.localNetworkPermission' => 'PlezyNG আপনার স্থানীয় নেটওয়ার্কে আপনার মিডিয়া সার্ভার এবং প্লেব্যাক ডিভাইসের সাথে সংযোগ করে।',
			'platform.locationPermission' => 'PlezyNG আপনার স্থানীয় নেটওয়ার্ক এবং আপনার মিডিয়া সার্ভারগুলিতে সংযোগ করার জন্য iOS এর প্রয়োজনীয় অবস্থান অ্যাক্সেস ব্যবহার করে।',
			'platform.photoLibraryPermission' => 'আপনার ফটো লাইব্রেরি থেকে ছবিগুলি মিডিয়া শিল্প হিসেবে ব্যবহার করার জন্য নির্বাচন করুন।',
			'platform.cameraPermission' => 'Companion Remote জোড়া লাগাতে QR কোড স্ক্যান করুন।',
			'universalMedia.title' => 'খোলা মিডিয়া',
			'universalMedia.shortcutHelp' => 'এই session জন্য একটি লিঙ্ক, Playlist বা ফাইল খেলুন।',
			'universalMedia.intro' => 'একটি লিঙ্ক, Playlist বা ফাইল খোলা. Playback PlezyNG এর স্ট্যান্ডার্ড প্লেয়ার ব্যবহার করে এবং আপনার লাইব্রেরিতে ইতিহাস যোগ করেন না।',
			'universalMedia.openWhat' => 'আপনি কী খুলে দিতে চান?',
			'universalMedia.stream' => 'স্ট্রিম ঠিকানা',
			'universalMedia.playlist' => 'Playlist খেলা',
			'universalMedia.files' => 'ডিভাইস ফাইল',
			'universalMedia.favorites' => 'সুরক্ষিত প্রদর্শন পছন্দ',
			'universalMedia.address' => 'মিডিয়া ঠিকানা',
			'universalMedia.addressHelp' => 'HTTPS preferred. recognized credential বা signature parameters সঙ্গে URLs শুধুমাত্র এই session জন্য ব্যবহার করা হয় এবং পছন্দ হিসাবে সংরক্ষণ করা যাবে না।',
			'universalMedia.displayName' => 'ডাউনলোড নাম (অ্যাপ্লিকেশন)',
			'universalMedia.displayNameHelp' => 'খেলোয়াড় এবং সিস্টেম মিডিয়া কন্ট্রোলগুলির জন্য একটি ছোট নাম নির্বাচন করুন।',
			'universalMedia.allowHttp' => 'একটি অক্রিপ্ট HTTP সংযোগ অনুমোদন',
			'universalMedia.allowHttpHelp' => 'HTTP সংযোগটি সক্রিপ্ট করে না. এটি শুধুমাত্র একটি বিশ্বাসযোগ্য নেটওয়ার্কে অনুমতি দেয়. সম্ভবত HTTPS ব্যবহার করুন.',
			'universalMedia.advancedProtocols' => 'MPV শুধুমাত্র: একটি RTSP, RTMP/RTMPS, UDP বা RTP ঠিকানা লিখুন. এই ঠিকানাগুলি প্রিয় হিসাবে সংরক্ষণ করা যাবে না।',
			'universalMedia.liveStream' => 'বেঁচে থাকার মতো আচরণ',
			'universalMedia.liveStreamHelp' => 'এটি লাইভ ভিডিও বা রেডিও জন্য ব্যবহার করুন. অ্যাপটি টাইম বার, স্কপ বোতল এবং গিয়ে-টাইম অপশনকে ঘুরে রাখে. একটি রেকর্ড করার জন্য এটি বন্ধ করে।',
			'universalMedia.privateSession' => 'শুধুমাত্র এই প্লেব্যাক ঠিকানা ব্যবহার করে. এই প্রোফাইলে রাখার জন্য একটি অনুমোদিত স্ট্রিম প্রিয় সংরক্ষণ করুন.',
			'universalMedia.saveFavorite' => 'পছন্দ সংরক্ষণ',
			'universalMedia.playNow' => 'এখন খেলুন',
			'universalMedia.favoriteSaved' => 'এই প্রোফাইলে সুরক্ষিত পছন্দ স্ট্রিম',
			'universalMedia.skippedEntries' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n, one: '${count} অসহায় বা নিরাপদ Playlist প্রবেশ।', other: '${count} সমর্থিত বা নিরাপদ Playlist অন্তর্ভুক্ত।', ), 
			'universalMedia.playlistAddress' => 'Playlist ঠিকানা',
			'universalMedia.playlistAddressHelp' => 'একটি ওয়েব ঠিকানা থেকে একটি M3U, M3u8, বা PLS প্লেলিস্ট খোঁজ করুন. সরাসরি প্রদর্শন লিঙ্কগুলি প্লেলেস্ট সংরক্ষণ করে না।',
			'universalMedia.choosePlaylist' => 'Playlist ফাইল নির্বাচন করুন',
			'universalMedia.openPlaylist' => 'খোলা Playlist',
			'universalMedia.playlistFormatsHelp' => 'একটি খেলা লিস্টে সর্বাধিক 1,000 পণ্য এবং 2 মিবি রয়েছে. HLS স্ট্রিম হিসাবে খোলা হয়, তাই খেলোয়াড় একটি মান নির্বাচন করতে পারেন।',
			'universalMedia.saveQueuePlaylist' => 'কিউ প্লেলিস্ট হিসেবে সংরক্ষণ করুন',
			'universalMedia.queuePlaylistSaved' => 'মিডিয়া ফাইলগুলোর পাশে প্লেলিস্ট সংরক্ষিত হয়েছে।',
			'universalMedia.queuePlaylistUnavailable' => 'এই কিউ পুনরায় ব্যবহারযোগ্য স্থানীয় প্লেলিস্ট হিসেবে সংরক্ষণ করা যাবে না।',
			'universalMedia.queuePlaylistFolderRequired' => 'কিউতে থাকা ফাইলগুলোর একই ফোল্ডারে সংরক্ষণের স্থান বেছে নিন।',
			'universalMedia.noFavorites' => 'এখনো কোন প্রেমের পছন্দ সংরক্ষণ করা হয় না. পছন্দের এই प्रोফাইলে থাকুন।',
			'universalMedia.removeFavorite' => 'প্রিয় স্ট্রিম মুছে ফেলুন',
			'universalMedia.filesHelp' => 'অডিও, ভিডিও বা আইএসও ফাইলগুলি একটি temporary quue জন্য নির্বাচন করুন. ফাইল এবং URLs লাইব্রেরির ইতিহাসে যোগ করা হয় না।',
			'universalMedia.chooseFiles' => 'ফাইল নির্বাচন',
			'universalMedia.fileQueue' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n, one: '1 নির্বাচিত ফাইল', other: '${count} নির্বাচিত ফাইল', ), 
			'universalMedia.wifiTransfer' => 'Wi-Fi এর মাধ্যমে ফাইল পাঠান',
			'universalMedia.wifiTransferHelp' => 'সমর্থিত ফাইলগুলি এক ব্রাউজার থেকে একই বিশ্বাসযোগ্য নেটওয়ার্কে স্থানান্তর করুন।',
			'universalMedia.wifiTransferIntro' => 'অন্য ডিভাইসের একটি ব্রাউজারে এই ঠিকানা খোঁজ করুন. ফাইলগুলি নির্বাচন করে এই ডিভিশনের ফাইল এবং বই লাইব্রিয়ামে যোগ করুন.',
			'universalMedia.wifiTransferPrivacy' => 'এই ডিভাইস আপনার স্থানীয় নেটওয়ার্কের মাধ্যমে ফাইল গ্রহণ করে. যে কেউ এই ঠিকানা জানে, আপনি ট্রান্সফার বন্ধ করা পর্যন্ত ফাইল পাঠাতে পারেন বা ঠিকানা 15 মিনিট পরে শেষ হয়. সর্বোচ্চ: 100 ফাইল, 4 জিবি প্রতি ফিল, 10 জিबी মোট।',
			'universalMedia.wifiTransferStarting' => 'একটি ব্যক্তিগত, সময় সীমিত স্থানান্তর প্রস্তুত ...',
			'universalMedia.wifiTransferUnavailable' => 'স্থানীয় নেটওয়ার্ক অ্যাক্সেস চেক করুন এবং আবার চেষ্টা করুন।',
			'universalMedia.openThisAddress' => 'এই ডিভাইসের একটি ঠিকানা খুলুন',
			'universalMedia.copyAddress' => 'কপি Transfer Address',
			'universalMedia.addressCopied' => 'প্রদর্শন ঠিকানা কপি',
			'universalMedia.transferExpires' => ({required Object time}) => 'এই ঠিকানাটি ${time} এর মধ্যে শেষ হয়।',
			'universalMedia.uploadCount' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(n, one: '${count} ফাইল গ্রহণ', other: '${count} ফাইল গ্রহণ', ), 
			'universalMedia.uploadedData' => ({required Object size}) => '${size} পেয়েছেন',
			'universalMedia.stopTransfer' => 'স্থানান্তর বন্ধ করুন এবং ঠিকানা বাতিল করুন',
			'universalMedia.startTransfer' => 'ট্রেডিং শুরু',
			'universalMedia.wifiImportedFiles' => 'Wi-Fi ট্রান্সফার',
			'universalMedia.wifiBrowserTitle' => 'ফাইল পাঠান PlezyNG',
			'universalMedia.wifiBrowserIntro' => 'অডিও, ভিডিও, ইবুক বা কমিক ফাইলগুলি পাঠানোর জন্য নির্বাচন করুন. ফাইলগুলো এই ডিভাইসের ফাইল এবং বই লাইব্রিয়ামে সংরক্ষণ করা হয়. সর্বোচ্চ: 100 ফাইল, 1 ফাইল প্রতি 4 জিবি, 10 জিबी মোট।',
			'universalMedia.uploadFilesLabel' => 'ফাইল পাঠানো',
			'universalMedia.uploadSelected' => 'নির্বাচিত ফাইল আপলোড করুন',
			'universalMedia.uploadSelectFirst' => 'প্রথমে একটি বা বেশী ফাইল নির্বাচন করুন।',
			'universalMedia.uploading' => 'পাঠান',
			'universalMedia.uploadComplete' => 'ফাইলটি PlezyNGে যোগ করা হয়।',
			'universalMedia.uploadFailed' => 'ফাইলটি যোগ করা যায় না. এই পৃষ্ঠা খোলা রাখুন এবং আবার চেষ্টা করুন।',
			'universalMedia.liveCue' => 'লাইভ',
			'universalMedia.liveSession' => 'লাইভ স্ট্রিম',
			'universalMedia.liveCueHelp' => 'লাইভ ভিডিও বা রেডিও জন্য, অ্যাপটি সময় প্যাকেট সুরক্ষা করে এবং হ্রাস बटन. এটি ঠিকানা সংরক্ষণ করেন না বা ইতিহাস দেখেনি।',
			'universalMedia.sessionOnly' => 'এই গেমটি শুধু সেশন-এই।',
			'universalMedia.sessionOnlyHelp' => 'Playback কখনো উন্নয়ন বা ইতিহাস সংরক্ষণ করে না. এই প্রোফাইলে রাখার জন্য পছন্দ হিসাবে স্ট্রিম সংরক্ষণ করুন, যদি এটি অনুমোদিত হয়।',
			'universalMedia.pictureAdjustments' => 'ছবি সংশোধন',
			'universalMedia.pictureHelp' => 'এই ছবি পরিবর্তনগুলি শুধুমাত্র এই প্লেব্যাককে প্রভাবিত করে. তারা প্লেবেক শেষ হওয়ার পর আবারও স্থাপন করে।',
			'universalMedia.resetPicture' => 'পুনরায় ছবি',
			'universalMedia.brightness' => 'উজ্জ্বল',
			'universalMedia.contrast' => 'প্রতিরোধ',
			'universalMedia.gamma' => 'গেম',
			'universalMedia.hue' => 'হুই',
			'universalMedia.saturation' => 'সুরআন',
			'universalMedia.view360' => '360° ভিডিও জন্য ফ্ল্যাট প্রদর্শন',
			'universalMedia.view360Help' => 'এছাড়াও 360° ভিডিও ব্যবহার করুন. MPV এর জন্য FFmpeg\'s v360 ফিল্টার প্রয়োজন।',
			'universalMedia.view360Unavailable' => 'এই MPV গঠন 360° ফিল্টার ব্যবহার করতে পারে না।',
			'universalMedia.view360Yaw' => 'Horizontal ভাবনা',
			'universalMedia.view360Pitch' => 'ভার্চিক দৃষ্টিভঙ্গি',
			'universalMedia.view360FieldOfView' => 'দৃষ্টিভঙ্গি জায়গা',
			'universalMedia.recordStream' => 'Live Stream রেকর্ড',
			'universalMedia.stopRecording' => 'রেকর্ডিং বন্ধ এবং সংরক্ষণ করুন',
			'universalMedia.recordingStarted' => 'রেকর্ডিং সক্রিয়. Playback বন্ধ করে এবং রেকডিং সংরক্ষণ করে।',
			'universalMedia.recordingSaved' => 'রেকর্ড শেষ এবং সংরক্ষিত।',
			'universalMedia.recordingActive' => 'এই ডিভাইস থেকে রেকর্ড করুন. Playback বন্ধ করে এবং এটি সংরক্ষণ করে।',
			'universalMedia.recordingFormatHelp' => 'ভিডিও জন্য, MKV বা MPEG-TS নির্বাচন করুন. অডিও জন্য, MKA বা MKV নির্বাচন করুন।',
			'universalMedia.replaceRecordingTitle' => 'এই রেকর্ড পরিবর্তন করবেন?',
			'universalMedia.replaceRecordingHelp' => 'রেকর্ডিংয়ের সময় PlezyNG বর্তমান ফাইলটি পিছিয়ে রাখে. যদি এটি নতুন রেকার্ড সংরক্ষণ করতে পারে না, তাহলে plezyNG সাপোর্ট পুনরাবৃত্তি করে।',
			'universalMedia.replaceRecording' => 'ফাইল পরিবর্তন',
			'universalMedia.discHelp' => 'এই কম্পিউটারের অপটিক ড্রাইভে একটি ডিস্ক খুলুন. আপনি ডিভাইস ফাইল থেকে আইএসও ইমেজ খুলতে পারেন।',
			'universalMedia.discs' => 'অপটিক্যাল ডিভাইস',
			'universalMedia.editionOrTitle' => 'সংস্করণ বা ডিস্কের শিরোনাম',
			'universalMedia.dvd' => 'ডিভিডি',
			'universalMedia.bluray' => 'ব্লু-রাই',
			'universalMedia.audioCd' => 'অডিও সিডি',
			'universalMedia.discAvailability' => 'ডিভাইস প্লেব্যাক একটি সামঞ্জস্যপূর্ণ MPV গঠন, সমর্থিত ড্রাইভ এবং অপারেটিং সিস্টেম অনুমতি প্রয়োজন. এটি বাণিজ্যিক ডিভিডি রক্ষা অতিক্রম করতে পারে না।',
			'universalMedia.converterTitle' => 'স্থানীয় গণমাধ্যম ফাইল পরিবর্তন',
			'universalMedia.converterHelp' => 'একটি স্থানীয় ফাইল পরিদর্শন করুন অথবা এটি রেমুশ করতে FFmpeg.',
			'universalMedia.converterIntro' => 'একটি স্থানীয় অডিও বা ভিডিও ফাইলটি একাধিক ডিভাইসের উপর কাজ করে ফর্মটামে পরিদর্শন করুন।',
			'universalMedia.converterPrivacy' => 'FFmpeg এই কম্পিউটারে ইনস্টল করা উচিত. Conversion শুধুমাত্র স্থানীয় ফাইলগুলি পড়বে. এটি স্ট্রিম ডাউনলোড করে না বা DRM মুছে নেয় না।',
			'universalMedia.converterChooseInput' => 'স্থানীয় মিডিয়া ফাইল নির্বাচন করুন',
			'universalMedia.converterFormat' => 'উত্পাদন ফরম্যাট',
			'universalMedia.converterMp4' => 'MP4 · H.264 এবং AAC',
			'universalMedia.converterM4a' => 'M4A · AAC অডিও',
			'universalMedia.converterMp3' => 'MP3 অডিও',
			'universalMedia.allowFtp' => 'FTP অনুমোদন',
			'universalMedia.allowFtpHelp' => 'FTP ক্রিপ্টিং ছাড়া মিডিয়া পাঠায়. শুধুমাত্র বিশ্বাসযোগ্য নেটওয়ার্কগুলিতে ব্যবহার করুন।',
			'universalMedia.converterSaveAs' => 'পরিদর্শন মিডিয়ার হিসাবে সংরক্ষণ করুন',
			'universalMedia.converterExtensionMismatch' => 'নির্বাচিত উত্পাদন প্রদর্শন সঙ্গে একটি ফাইল নাম নির্বাচন করুন।',
			'universalMedia.converterUnsupportedInput' => 'একটি অডিও বা ভিডিও ফাইল নির্বাচন করুন।',
			'universalMedia.converterLocalOnly' => 'নির্বাচিত ফাইল একটি স্থানীয় ডিভাইস পথ হিসাবে পাওয়া যায় না।',
			'universalMedia.converterReplaceTitle' => 'এই ফাইলটি পরিবর্তন করবেন?',
			'universalMedia.converterReplaceHelp' => 'PlezyNG বর্তমান ফাইলটি সংরক্ষণ করা পর্যন্ত রেকর্ড করে।',
			'universalMedia.converterStarting' => 'শুরু করে ফিপিএফ...',
			'universalMedia.converterProgress' => 'এই কম্পিউটারের মাধ্যমে পরিদর্শন ...',
			'universalMedia.converterComplete' => 'নতুন ফাইল প্রস্তুত।',
			'universalMedia.converterFfmpegMissing' => 'FFmpeg অথবা এই ফর্মটি সমর্থন করে না।',
			'universalMedia.converterFailed' => 'ফাইলটি পড়তে পারে এবং উদ্দেশ্য पर्याप्त বিনামূল্যে স্থান আছে কিনা নিশ্চিত করুন।',
			'universalMedia.converterCancelled' => 'অসম্পূর্ণ উৎপাদন বাতিল করা হয়েছে।',
			'universalMedia.converterDesktopOnly' => 'স্থানীয় পরিদর্শন FFmpeg ইনস্টল করা হয় ডেস্টো কম্পিউটারগুলিতে পাওয়া যায়।',
			'universalMedia.converterStart' => 'ফাইল পরিবর্তন',
			'universalMedia.mediaToolsTitle' => 'মিডিয়া সরঞ্জাম',
			'universalMedia.mediaToolsShortcut' => 'ফ্যাক্ট বা মিডিয়া শেয়ার করুন, অনুসন্ধান প্রদর্শনগুলি যোগ করুন, অথবা কমান্ড লাইন ব্যবহার করুন।',
			'universalMedia.mediaToolsIntro' => 'একটি কেন্দ্রীয় সরঞ্জাম নির্বাচন করুন. ফ্যাক্টর এবং স্ট্রিম-উট ব্যবহার করুন FFmpeg এই ডেভিসপে ইনস্টল করা হয়. Extensions এবং CLI অর্ডারগুলি সীমাবদ্ধ HTTPS অনুরোধগুলি এবং বর্তমান Open media অর্ডারগুলি ব্যবহার করে।',
			'universalMedia.mediaToolsAccessibility' => 'সরঞ্জাম নির্বাচন এবং নিয়ন্ত্রনগুলি ট্যাক্স, পয়েন্টার, ট্যাবলেট এবং D-pad ফোকসের সাথে কাজ করে। রেকর্ডিং, শেয়ার এবং অনুসন্ধান অবস্থা পরিবর্তন ঘোষণা করা হয়।',
			'universalMedia.mediaTool' => 'মিডিয়া টুল',
			'universalMedia.captureIntro' => 'আপনার স্ক্রিন বা ক্যামেরাটি এই কম্পিউটারে একটি MP4 ফাইলে রেকর্ড করুন. FFmpeg ইনস্টল করা উচিত এবং H.264 কোডার অন্তর্ভুক্ত করা উচিত।',
			'universalMedia.captureNoDevices' => 'কোন স্ক্রিন বা ক্যামেরা পাওয়া যায়নি. FFmpeg ফ্যাক্টর সাপোর্ট এবং অপারেটিং সিস্টেম গোপনীয়তা অনুমতিগুলি চেক করুন.',
			'universalMedia.captureSource' => 'স্ক্রিন বা ক্যামেরা',
			'universalMedia.captureScreen' => 'স্ক্রিন',
			'universalMedia.captureAudioSource' => 'অডিও ইনপোর্ট (অন্যাশনাল)',
			'universalMedia.captureAudioHelp' => 'একটি মাইক্রোফোন থেকে অডিও অন্তর্ভুক্ত করুন. ডিভাইস নির্বাচন FFmpeg এবং সিস্টেম অনুমতিগুলি উপর নির্ভর করে।',
			'universalMedia.captureAudioNone' => 'অডিও নেই',
			'universalMedia.captureDefaultAudio' => 'অডিও ইনপোর্ট',
			'universalMedia.captureWaylandHelp' => 'Wayland limits this XWayland capture to the X display. Windows outside XWayland may not appear.',
			_ => null,
		} ?? switch (path) {
			'universalMedia.captureFrameRate' => 'রেকর্ড ফ্রেম ফ্রেম',
			'universalMedia.capturePrivacy' => 'রেকর্ডিংটি শুধুমাত্র আপনার বেছে নেওয়া ফাইলের জন্য সংরক্ষণ করা হয়. মাইক্রোফোন ফ্যাক্টরি অপশনীয়. PlezyNG রেকর্ডিংটি আপলোড করে না।',
			'universalMedia.captureSaveAs' => 'স্ক্রিন রেকর্ডিং রেকর্ডিং',
			'universalMedia.captureExtensionMismatch' => '.mp4 এর মধ্যে শেষ একটি ফাইল নাম নির্বাচন করুন।',
			'universalMedia.captureFfmpegMissing' => 'FFmpeg বা H.264 ভিডিও কোডার পাওয়া যায় না. একটি সমর্থিত FFmpeg নির্মাণ ইনস্টল করুন, তারপর আবার চেষ্টা করুন.',
			'universalMedia.captureFailed' => 'ডিভাইস লাইসেন্স চেক করুন, उपलब्ध স্টোরেজ, এবং FFmpeg সমর্থন।',
			'universalMedia.captureSaved' => 'স্ক্রিন রেকর্ড সংরক্ষিত।',
			'universalMedia.captureElapsedLabel' => 'রেকর্ড সময়',
			'universalMedia.captureStart' => 'রেকর্ডিং শুরু',
			'universalMedia.capturePreview' => 'প্লেয়ারে প্রিভিউ',
			'universalMedia.capturePreviewHelp' => 'নির্বাচিত উৎসটি সাধারণ প্লেয়ারে দেখুন। এটি শুধু এই সেশনের জন্য এবং কোনো রেকর্ডিং সংরক্ষণ করে না। ডিভাইস সমর্থন ও অনুমতি MPV এবং অপারেটিং সিস্টেমের ওপর নির্ভর করে। প্রিভিউতে শুধু ভিডিও থাকে; সংরক্ষিত রেকর্ডিংয়ে ঐচ্ছিক অডিও যোগ করা যায়।',
			'universalMedia.capturePreviewActive' => 'লাইভ প্রিভিউ · রেকর্ড হচ্ছে না',
			'universalMedia.captureStop' => 'বন্ধ এবং বাঁচান',
			'universalMedia.captureMode' => 'আঘাত',
			'universalMedia.shareMode' => 'শেয়ার করুন',
			'universalMedia.shareIntro' => 'আপনার ব্যক্তিগত নেটওয়ার্কের অন্য ডিভাইসে একটি স্থানীয় মিডিয়া ফাইল পাঠান. PlezyNG একটি temporary HLS স্ট্রিম তৈরি করে।',
			'universalMedia.sharePrivacy' => 'আপনার স্থানীয় নেটওয়ার্কের কেউ যারা ব্যক্তিগত লিঙ্ক পেয়েছেন, সেটি সক্রিয় থাকলেও দেখতে পারেন. লিঙ্ক 60 মিনিটের পর শেষ হয়. সার্ভার বন্ধ করতে এবং লিঙ্কটি অ্যাক্টল করতে শেয়ারিং বন্ধ করুন.',
			'universalMedia.shareChooseFile' => 'মিডিয়া ফাইল নির্বাচন',
			'universalMedia.shareChooseHelp' => 'একটি স্থানীয় অডিও বা ভিডিও ফাইল নির্বাচন করুন. ফাইলটি এই কম্পিউটারে থাকবে।',
			'universalMedia.shareFfmpegMissing' => 'FFmpeg বা H.264/AAC কোডার পাওয়া যায় না. FFmpeg ইনস্টল করুন H.264 এবং AAC কোডার সমর্থন সঙ্গে।',
			'universalMedia.shareFailed' => 'প্রদর্শন অপ্রত্যাশিতভাবে শুরু বা বন্ধ হতে পারে না. FFmpeg এবং নেটওয়ার্ক অ্যাক্সেস চেক করুন.',
			'universalMedia.shareActive' => 'আপনার ব্যক্তিগত নেটওয়ার্ক থেকে সঠিক প্রদর্শন করা হয়েছে।',
			'universalMedia.shareEnded' => 'মিডিয়া শেষ পর্যন্ত পৌঁছায় এবং এখন আর শেয়ার করা হয় না।',
			'universalMedia.shareStopped' => 'বিতর্ক বন্ধ হয়ে গেছে. সময়সীমা লিঙ্ক এখন আর সঠিক নয়।',
			'universalMedia.shareUrlCopied' => 'পুনরায় পুনরায় পুনরায় পুনরায় পুনরায় পুনরায় পুনরায়',
			'universalMedia.shareOpenUrl' => 'অন্য ডিভাইসের একটি খেলোয়াড়ে এই ঠিকানা খোলা',
			'universalMedia.shareQrLabel' => 'QR কোড temporary stream ঠিকানা',
			'universalMedia.shareQrHelp' => 'একই ব্যক্তিগত নেটওয়ার্কের সাথে সংযোগিত একটি সহযোগী খেলোয়াড়ের সাথে স্ক্যান করুন।',
			'universalMedia.shareHttpHint' => 'এই প্রদর্শনটি অক্রিপ্ট HTTP ব্যবহার করে. PlezyNGতে, HTTP খুলে যাওয়ার আগে অনুমতি দেয়।',
			'universalMedia.shareCopyUrl' => 'প্রদর্শন ঠিকানা কপি',
			'universalMedia.shareExpiresLabel' => 'লিঙ্ক শেষ হয়',
			'universalMedia.shareStarting' => 'প্রদর্শনের প্রস্তুতি...',
			'universalMedia.shareStart' => 'শেয়ার শুরু',
			'universalMedia.shareStop' => 'বিতরণ বন্ধ করুন',
			'universalMedia.extensionsMode' => 'বিতর্ক এবং CLI',
			'universalMedia.extensionsIntro' => 'মিডিয়া খুঁজে পেতে একটি ডাটা-একটি অনুসন্ধান প্রদর্শন যোগ করুন. একটি ফলাফল নির্বাচন করুন এবং এটি পরিচিত Open media ফর্মে লোড করুন.',
			'universalMedia.extensionsPrivacy' => 'একটি ম্যানজিন একটি HTTPS অনুসন্ধান শেষ পয়েন্ট এবং ম্যাপ উত্তর পৃষ্ঠাগুলি নির্ধারণ করতে পারে. এটি কোড চালান, অনুরোধ হেডার যোগ করতে পারে, ফাইলগুলি পড়তে পারে, অথবা চালু শেল নির্দেশনা.',
			'universalMedia.extensionImport' => 'বিতর্ক ম্যানেজমেন্ট যোগ',
			'universalMedia.extensionEmpty' => 'এখনো কোন অনুসন্ধান পরিষেবা নেই. একটি যোগ করার জন্য একটি নির্ভরযোগ্য প্রদর্শন JSON ফাইল নির্বাচন করুন.',
			'universalMedia.extensionChoose' => 'অনুসন্ধান সেবা',
			'universalMedia.extensionSearchConsent' => 'প্রতিটি অনুসন্ধান এই HTTPS পরিষেবাতে আপনার শব্দগুলি পাঠিয়ে দেয়. ফলাফলগুলি শুধুমাত্র একটি নির্বাচন করার পর খোলা হয়।',
			'universalMedia.extensionSearchLabel' => 'মিডিয়া অনুসন্ধান',
			'universalMedia.extensionSearch' => 'অনুসন্ধান',
			'universalMedia.extensionSearching' => 'খুঁজে...',
			'universalMedia.extensionNoResults' => 'কোন নিরাপদ মিডিয়া ফলাফল ফিরে আসেনি. আরও একটি অনুসন্ধান চেষ্টা করুন.',
			'universalMedia.extensionInstallTitle' => 'এই অনুসন্ধান পরিষেবা যোগ করুন?',
			'universalMedia.extensionReplaceTitle' => 'এই অনুসন্ধান পরিষেবা আপডেট?',
			'universalMedia.extensionService' => 'পরিষেবা',
			'universalMedia.extensionEndpoint' => 'HTTPS endpoint',
			'universalMedia.extensionConsent' => 'আপনার অনুসন্ধান টেক্সটটি এই পরিষেবাকে পাঠানো হয়. ম্যানেজিনটি কোন executable কোড নেই. Continue only if you trust this endpoint.',
			'universalMedia.extensionInstall' => 'পরিষেবা যোগ করুন',
			'universalMedia.extensionReplace' => 'আপডেট পরিষেবা',
			'universalMedia.extensionRemoveTitle' => 'এই অনুসন্ধান পরিষেবাটি মুছে ফেলুন?',
			'universalMedia.extensionRemoveHelp' => 'এতে এই প্রোফাইল থেকে পরিষেবাを取り除きます. PlezyNG তার শেষ পয়েন্টের সাথে যোগাযোগ করে না।',
			'universalMedia.extensionRemove' => 'সরবরাহ',
			'universalMedia.extensionInvalidManifest' => 'এই ফাইলটি একটি সমর্থিত প্রদর্শন ম্যানেজমেন্ট নয়. ফরম্যাটের জন্য Open media গাইড দেখুন.',
			'universalMedia.extensionSaveFailed' => 'অ্যাক্টিভ প্রোফাইলের জন্য এই প্রদর্শন সংরক্ষণ করা যায়নি।',
			'universalMedia.extensionSearchFailed' => 'অনুসন্ধান পরিষেবা একটি সঠিক উত্তর ফেরত দেয় না. শেষ পয়েন্টটি চেক করুন এবং আবার চেষ্টা করুন.',
			'universalMedia.cliTitle' => 'কমান্ড লাইন',
			'universalMedia.cliHelp' => 'plezyctl গাইড ব্যবহার করুন একটি ম্যানেজি সনাক্ত করার জন্য বা একই প্রদর্শন অনুসন্ধান করুন. প্রতিটি অনুসন্ধানের আগে তার HTTPS পরিষেবাটি দেখুন. ফলাফল বর্তমান মিডিয়া ফর্মে খোলা; শুরু করার জন্য পুনরাবৃত্তি बटन নির্বাচন করুন.',
			'universalMedia.cliCopyExample' => 'কপি কমান্ড উদাহরণ',
			'universalMedia.cliCopied' => 'উদাহরণ কপি করা হয়েছে।',
			'fileSources.title' => 'ফাইল ও বই',
			'fileSources.subtitle' => 'পড়ুন, শুনুন এবং নিজের ফাইল থেকে দেখুন।',
			'fileSources.add' => 'উৎস যোগ করুন',
			'fileSources.importFiles' => 'ফাইলের আমদানি',
			'fileSources.localFiles' => 'এই ডিভাইসের',
			'fileSources.source' => 'উৎস',
			'fileSources.name' => 'নাম',
			'fileSources.endpoint' => 'URL সার্ভার',
			'fileSources.smbEndpointHint' => 'উদাহরণ: smb://nas/Movies',
			'fileSources.smbEndpointInvalid' => 'একটি SMB সার্ভার এবং একটি শেয়ার করা ফোল্ডার লিখুন।',
			'fileSources.root' => 'ফোল্ডার বা উপসর্গ',
			'fileSources.smbFolderHelp' => 'পুরো শেয়ার করা ফোল্ডার ব্যবহার করতে ফাঁকা রাখুন, অথবা তার ভেতরের কোনো ফোল্ডার লিখুন।',
			'fileSources.username' => 'ব্যবহারকারী নাম',
			'fileSources.smbDomain' => 'ডোমেইন (ঐচ্ছিক)',
			'fileSources.password' => 'পাসওয়ার্ড',
			'fileSources.token' => 'API টকেন',
			'fileSources.accessKey' => 'অ্যাক্সেস ক্লাই ID',
			'fileSources.secretKey' => 'গোপন অ্যাক্সেস ক্লাই',
			'fileSources.sessionToken' => 'সেশন টকেন (অন্যাশনাল)',
			'fileSources.region' => 'এলাকা',
			'fileSources.clientId' => 'OAuth ক্লায়েন্ট ID',
			'fileSources.clientSecret' => 'OAuth ক্লায়েন্ট সার্ভিস (সুধুমাত্র Google ডেস্টো)',
			'fileSources.allowHttp' => 'বিশ্বস্ত নেটওয়ার্কে এনক্রিপশনবিহীন HTTP সংযোগের অনুমতি দিন',
			'fileSources.smbEncryption' => 'SMB3 সংযোগ এনক্রিপ্ট করুন',
			'fileSources.smbEncryptionHint' => 'NAS সমর্থন করলে SMB3 এনক্রিপশন ব্যবহার করুন।',
			'fileSources.connect' => 'কানেক্ট',
			'fileSources.cancel' => 'বাতিল',
			'fileSources.save' => 'সুরক্ষা',
			'fileSources.close' => 'বন্ধ',
			'fileSources.removeSource' => 'সংযোগ বন্ধ',
			'fileSources.disconnectMessage' => 'এই উৎসের সংযোগ বিচ্ছিন্ন করবেন? ডাউনলোড করা ফাইল এবং আপনার পড়া ও শোনার ইতিহাস এই ডিভাইসে থেকে যাবে।',
			'fileSources.localFolder' => 'ফোলার নির্বাচন',
			'fileSources.empty' => 'এখনো এখানে কিছু নেই',
			'fileSources.emptyHint' => 'একটি উৎস যোগ করুন বা একটি বই, অডিওবুক, গান বা ভিডিও import করুন।',
			'fileSources.search' => 'এই ফোলার খুঁজে নিন',
			'fileSources.searchCached' => 'সুরক্ষিত লাইব্রেরি',
			'fileSources.refresh' => 'ফ্রিজ করুন',
			'fileSources.loadMore' => 'আরো লোড',
			'fileSources.offline' => 'অফলি অ্যাক্সেস',
			'fileSources.download' => 'অফলি রাখুন',
			'fileSources.removeDownload' => 'অফলি কপি মুছে ফেলুন',
			'fileSources.continueReading' => 'Continue Reading পড়ুন',
			'fileSources.continueListening' => 'শুনতে চলুন',
			'fileSources.continueWatching' => 'দেখা অব্যাহত রাখুন',
			'fileSources.read' => 'পড়ুন',
			'fileSources.listen' => 'শুনুন',
			'fileSources.play' => 'খেলা',
			'fileSources.pause' => 'বিরতি',
			'fileSources.stop' => 'থামুন',
			'fileSources.startOver' => 'শুরু করে',
			'fileSources.finished' => 'শেষ',
			'fileSources.markFinished' => 'মারি শেষ',
			'fileSources.markUnfinished' => 'অসম্ভব মারি',
			'fileSources.editions' => 'সংস্করণ ও ফাইল',
			'fileSources.chapters' => 'চিঠি',
			'fileSources.bookmarks' => 'বইমেলা ও নোট',
			'fileSources.bookmark' => 'Bookmark যোগ করুন',
			'fileSources.highlight' => 'উচ্চতা',
			'fileSources.note' => 'নোট',
			'fileSources.delete' => 'মুছে ফেলুন',
			'fileSources.export' => 'বিতরণ নোট',
			'fileSources.exported' => 'বিতরণের নোট',
			'fileSources.sync' => 'সিনক প্রসেস',
			'fileSources.synced' => 'প্রসারিত সিন্সেস',
			'fileSources.conflict' => 'অন্য ডিভাইসের একটি পদ্ধতি আছে. কোথায় চলতে চান তা নির্বাচন করুন.',
			'fileSources.useLocal' => 'এই সরঞ্জাম ব্যবহার করুন',
			'fileSources.useRemote' => 'অন্য সরঞ্জাম ব্যবহার করুন',
			'fileSources.history' => 'অবস্থান ইতিহাস',
			'fileSources.groupAudio' => 'শুনুন এক অডিওবুক',
			'fileSources.groupHint' => 'এই ফোডার মধ্যে বর্তমানে লোড করা অডিও ফাইলগুলি সংযুক্ত করুন. প্রথমেই সব পৃষ্ঠা লোড করুন.',
			'fileSources.order' => 'ফাইল আদেশ',
			'fileSources.moveUp' => 'উড়ে উঠে',
			'fileSources.moveDown' => 'নিচে গিয়ে',
			'fileSources.speed' => 'গতি Playback',
			'fileSources.sleep' => 'ঘুমের টাইম',
			'fileSources.sleepOff' => 'বন্ধ',
			'fileSources.endChapter' => 'চাবার শেষ',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bn'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} মিনিট', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} মিনিট', ), 
			'fileSources.skipBack' => 'ফিরে আসুন',
			'fileSources.skipForward' => 'এগিয়ে যান',
			'fileSources.smartRewind' => 'একটি পাসের পর স্মার্ট ফেরত',
			'fileSources.playbackOptions' => 'শুনতে পছন্দ',
			'fileSources.remaining' => ({required Object time}) => '${time} বাকি',
			'fileSources.contents' => 'বিষয়বস্তু',
			'fileSources.readerSettings' => 'পড়ুন সিস্টেম',
			'fileSources.fontSize' => 'টেক্সট মাত্রা',
			'fileSources.lineHeight' => 'লাইন স্পেসিং',
			'fileSources.margin' => 'মারগিন',
			'fileSources.font' => 'টাইপফেস',
			'fileSources.serif' => 'সেরিফ',
			'fileSources.sans' => 'সেরিফবিহীন',
			'fileSources.mono' => 'সমপ্রস্থ',
			'fileSources.columns' => 'কোম্পানী',
			'fileSources.scroll' => 'ভার্চালিকভাবে স্রোল',
			'fileSources.justify' => 'লেখা দুই পাশে সমানভাবে সাজান',
			'fileSources.readerTheme' => 'পৃষ্ঠা প্রদর্শনী',
			'fileSources.appTheme' => 'অ্যাপ টেমপ অনুসরণ',
			'fileSources.paper' => 'কাবার',
			'fileSources.sepia' => 'সাবিয়া',
			'fileSources.night' => 'রাতে',
			'fileSources.readAloud' => 'এই পৃষ্ঠাটি জোরে পড়ুন',
			'fileSources.readAlong' => 'শুনতে শুনতে পড়ুন',
			'fileSources.stopReading' => 'পড়ে শোনানো বন্ধ করুন',
			'fileSources.searchBook' => 'বইয়ের খোঁজ',
			'fileSources.noMatches' => 'খেলা না',
			'fileSources.previousPage' => 'পূর্ববর্তী পাতা',
			'fileSources.nextPage' => 'পরবর্তী পাতা',
			'fileSources.page' => ({required Object number}) => 'পাতা ${number}',
			'fileSources.externalBlocked' => 'রিডারে বইয়ের বাহ্যিক লিঙ্কগুলি নিষ্ক্রিয় রয়েছে।',
			'fileSources.loading' => 'খোলা...',
			'fileSources.narrator' => 'ন্যাগারেট',
			'fileSources.audio' => 'অডিও',
			'fileSources.video' => 'ভিডিও',
			'fileSources.ebooks' => 'ইবুক',
			'fileSources.all' => 'সবগুলি',
			'fileSources.downloads' => 'অফফল ফাইল',
			'fileSources.confirmDelete' => 'নির্বাচিত অফলাইন কপিটি সরাবেন? আপনার পড়া বা শোনার অবস্থান এবং নোটগুলি সংরক্ষিত থাকবে।',
			'fileSources.errorAuthentication' => 'আবারও এই পণ্য সংযোগ করতে চান।',
			'fileSources.errorPermission' => 'এই উৎস অনুরোধ করা ফাইলটি ব্যবহারের অনুমতি দেয়নি।',
			'fileSources.errorUnavailable' => 'পুনরায় চেষ্টা করুন, অথবা অফলিন কপি খুলুন।',
			'fileSources.errorUnsupported' => 'এই ফর্মেট বা সংযোগ এই ডিভাইসে সমর্থিত হয় না. সূত্র সিস্টেম গাইড দেখুন.',
			'fileSources.errorInvalidData' => 'এই ফাইল বা সার্ভার উত্তর নিরাপদভাবে পড়তে পারে না।',
			'fileSources.errorCancelled' => 'অপারেশন বাতিল করা হয়েছে।',
			'fileSources.errorConflict' => 'পরবর্তী সেশনে অবস্থান পরিবর্তন করা হয়. একটি অবস্থান নির্বাচন করার জন্য পণ্যটি আবার খোলা।',
			'fileSources.signIn' => 'সাইন ইন করুন',
			'fileSources.reconnect' => 'আবার সংযোগ',
			'fileSources.folderHelp' => 'সূত্র রয়ে শুরু করতে বাদ রাখুন. S3 URLs মধ্যে বুকটি রয়েছে।',
			'fileSources.preferences' => 'প্রিয়ম',
			'fileSources.timePosition' => 'অবস্থান',
			'fileSources.audioTrack' => 'Audio ট্র্যাক',
			'fileSources.subtitleTrack' => 'Subtitle ট্র্যাক',
			'fileSources.none' => 'কোন',
			'fileSources.fullscreen' => 'ফুল-স্ক্রিন',
			'fileSources.syncLocation' => 'প্রসেস সিন্ক ফোলার (অন্যাশনাল)',
			'fileSources.syncLocationHint' => 'একটি নির্দিষ্ট WebDAV ফোডার PlezyNG অবস্থা. শর্তাবলী লিখুন ব্যবহার; মিডিয়া পরিবর্তন না থাকবে.',
			'fileSources.audiobooks' => 'অডিও বই',
			'fileSources.comics' => 'কমিকস',
			'fileSources.scan' => 'বই ও মিডিয়া জন্য স্ক্যানিং',
			'fileSources.browserReader' => 'খোলা পাঠক',
			'fileSources.browserReaderHelp' => 'আপনার ব্রাউজারে পাঠক খোলা থাকে. আপনার স্থান এবং নোট সংরক্ষণ করার জন্য PlezyNG খোলা রাখুন.',
			'fileSources.on' => 'এতে',
			'fileSources.advancedSetup' => 'App নিবন্ধন',
			'fileSources.microsoftSignIn' => 'Microsoft সঙ্গে সাইন আপ করুন',
			'fileSources.zoomIn' => 'Zoom এর মধ্যে',
			'fileSources.zoomOut' => 'জোম',
			'fileSources.fitPage' => 'পৃষ্ঠা',
			'fileSources.fitWidth' => 'পাশাপাশি',
			'fileSources.actualSize' => 'বর্তমান আকার',
			'fileSources.goToPage' => 'পৃষ্ঠা থেকে যান',
			'fileSources.goToSection' => 'চাবি থেকে যান',
			'fileSources.pageRange' => ({required Object count}) => '1 থেকে ${count} পর্যন্ত একটি নম্বর প্রদান করুন',
			'fileSources.pageLayout' => 'Page লিওট',
			'fileSources.automatic' => 'স্বয়ংক্রিয়',
			'fileSources.singlePage' => 'একক পাতা',
			'fileSources.twoPages' => 'দুই পৃষ্ঠা',
			'fileSources.readingDirection' => 'পড়ার দিক',
			'fileSources.leftToRight' => 'বাম থেকে ডানে',
			'fileSources.rightToLeft' => 'ডান থেকে বামে',
			'fileSources.letterSpacing' => 'স্পেসিং চিঠি',
			'fileSources.wordSpacing' => 'শব্দ স্পেসিং',
			'fileSources.readerControlsHelp' => 'পৃষ্ঠা বড় করতে দুই আঙুল ছড়িয়ে দিন বা জুম নিয়ন্ত্রণ ব্যবহার করুন। সরাতে টেনে আনুন। Ctrl/⌘ + বা − দিয়ে জুম বদলান; Ctrl/⌘ 0 দিয়ে আগের মাপে ফিরুন। Page Up ও Page Down দিয়ে পৃষ্ঠা বদলান।',
			'fileSources.imagePage' => 'কমিকসের পৃষ্ঠা',
			'fileSources.resetReader' => 'Read Preferences পুনরায়',
			'fileSources.zoom' => 'জুম',
			'fileSources.useFiles' => 'ফাইল এবং বই ব্যবহার করুন',
			'fileSources.cancelScan' => 'স্ক্যান বাতিল',
			'fileSources.googleDrive' => 'Google Drive',
			'fileSources.offlineQuota' => 'ডাউনলোড সীমাবদ্ধ',
			'fileSources.offlineQuotaHelp' => 'অoffline কপি, imported ফাইল এবং quued ডাউনলোড দ্বারা ব্যবহৃত সর্বোচ্চ স্থান নির্ধারণ করুন. সীমাবদ্ধতা কমাতে বর্তমান কপিগুলি মুছে দেয় না।',
			'fileSources.offlineStorageUsage' => 'অফলিন স্টোরেজ',
			'fileSources.reservedStorage' => 'সংরক্ষিত',
			'fileSources.downloadQueue' => 'ডাউনলোড করুন Queue',
			'fileSources.downloadRunning' => 'ডাউনলোড',
			'fileSources.downloadQueued' => 'অপেক্ষা',
			'fileSources.downloadPaused' => 'ছুটি',
			'fileSources.downloadFailed' => 'পেরিয়ে যাওয়ার প্রয়োজন',
			'fileSources.importing' => 'আমদানি',
			'fileSources.importInterrupted' => 'উৎপাদন বাতিল · মুছে ফেলুন',
			'fileSources.errorQuotaExceeded' => 'অ্যাপ্লিকেল স্টোরেজ সীমাবদ্ধতা পৌঁছানো হয়েছে. সীমানা উচ্চ করা বা একটি ডাউনলোড কপি মুছে ফেলা।',
			'fileSources.errorStorageLow' => 'সুরক্ষিত রেকর্ড রাখার জন্য যথেষ্ট বিনামূল্যে ডিভাইস স্টোরেজ নেই।',
			'fileSources.errorStorageUnavailable' => 'PlezyNG বিনামূল্যে ডিভাইস স্টোরেজ চেক করতে পারেনি, তাই লিখা বন্ধ করা হয়।',
			'fileSources.removeDownloadJob' => 'Download ডাউনলোড',
			'fileSources.downloadAlreadyComplete' => 'এই ডাউনলোড শেষ হয়, আগে এটি মুছে ফেলতে পারে. পণ্য এখন অ্যাপ্লিকেটে পাওয়া যায়।',
			'fileSources.confirmRemoveDownloadJob' => 'এই ডাউনলোডটি মুছে ফেলুন এবং অংশীদারভাবে ডাউনের কোনও তথ্য দূর করুন? আপনার অবস্থান এবং নোট থাকবে।',
			'lending.title' => 'জনব্যাপী লাইব্রেরি',
			'lending.add' => 'একটি লাইব্রেরি যোগ করুন',
			'lending.other' => 'আরেকটি লাইব্রেরি',
			'lending.libraryName' => 'বইয়ের নাম',
			'lending.libraryUrl' => 'লাইব্রেরি ওয়েবসাইট',
			'lending.libraryUrlHint' => 'আপনার লাইব্রেরির ক্যাটাগোজ বা সাইন-এ-পেজ ব্যবহার করুন।',
			'lending.intro' => 'আপনার লাইব্রেরি থেকে বই ধার নিন। বই রাখুন হাতের কাছেই।',
			'lending.handoff' => 'আপনার লাইব্রেরি নিজের পরিষেবা দিয়ে সুরক্ষিতভাবে নিবন্ধন, লেনদেন এবং পড়ুন।',
			'lending.openService' => 'খোলা লাইব্রেরি',
			'lending.findLibrary' => 'একটি লাইব্রেরি খুঁজে পেতে',
			'lending.search' => 'বই ও লেখকদের খুঁজে পেতে',
			'lending.catalogue' => 'ক্যাটাগো',
			'lending.loans' => 'ধার নেওয়া বই',
			'lending.holds' => 'রিজার্ভেশন',
			'lending.signIn' => 'আপনার লাইব্রেরি নিয়ে সাইন আপ করুন',
			'lending.waiting' => 'আপনার ব্রাউজারে সাইন আপ শেষ করুন, তারপর এখানে ফিরে আসুন।',
			'lending.cancel' => 'বাতিল',
			'lending.disconnect' => 'লাইব্রেরি বের করুন',
			'lending.disconnectMessage' => 'এই প্রোফাইল থেকে এই লাইব্রেরি সরাবেন? ধার নেওয়া বই ও রিজার্ভেশনগুলি আপনার লাইব্রেরিতে থাকবে।',
			'lending.getBook' => 'বই পেয়ে',
			'lending.checkAvailability' => 'সনাক্ত করা উপলব্ধতা',
			'lending.available' => 'ধার নেওয়া যাবে',
			'lending.unavailable' => 'বর্তমানে অসম্ভব',
			'lending.borrow' => 'ধার নিন',
			'lending.placeHold' => 'রিজার্ভ করুন',
			'lending.returnBook' => 'দ্রুত ফিরে আসুন',
			'lending.cancelHold' => 'রিজার্ভেশন বাতিল করুন',
			'lending.confirmBorrow' => 'আপনার লাইব্রেরি থেকে এই টাইটটি লেনদেন করুন?',
			'lending.confirmReturn' => 'এই বইটি এখন ফেরত দেবেন? পড়া চালিয়ে যেতে আবার ধার নিতে হতে পারে।',
			'lending.confirmCancelHold' => 'এই বইয়ের জন্য আপনার রিজার্ভেশন বাতিল করবেন?',
			'lending.email' => 'ইমেলের বিজ্ঞাপন রাখুন',
			'lending.due' => ({required Object date}) => 'ফেরত দেওয়ার তারিখ: ${date}',
			'lending.queue' => ({required Object position}) => 'পয়েন্ট ${position} লাইনে',
			'lending.empty' => 'এখনো এখানে কোন টাইম নেই।',
			'lending.openLibraryNote' => 'Open Library-এর ক্যাটালগ দেখুন। প্রতিটি বইয়ের পাতায় পড়া ও ধার নেওয়ার বিকল্পগুলি দেখানো হয়।',
			'lending.more' => 'আরো লোড',
			'lending.gateway' => 'লাইব্রেরি সাইন-ইন সেবা',
			'lending.gatewayHint' => 'আপনার লাইব্রেরি বা প্রশাসক PlezyNG দ্বারা সরবরাহ করা হয়।',
			'lending.advanced' => 'লাইব্রেরি ইন্টারফেস',
			'lending.loadLibraries' => 'আপনার লাইব্রেরি নির্বাচন করুন',
			'lending.expired' => 'এই বই ধার নেওয়ার মেয়াদ শেষ হয়েছে।',
			'lending.updated' => 'সংস্করণ আপডেট',
			'lending.continueService' => 'সেবা চালু করুন',
			'lending.comingSoon' => 'অ্যাপে ডাউনলোড · শীঘ্রই আসে',
			'lending.comingSoonDescription' => 'আপনি আপনার লাইব্রেরি ব্যবহার করতে পারেন লিবি যখন আমরা এটি সংযোগ শেষ করি।',
			'lending.suspendHold' => 'রিজার্ভেশন সাময়িক বন্ধ করুন',
			'lending.resumeHold' => 'রিজার্ভেশন আবার চালু করুন',
			'lending.suspendMessage' => 'লাইনে নিজের জায়গা রেখে পরের পাঠককে এই কপিটি ধার নিতে দেবেন? পরে রিজার্ভেশনটি আবার চালু করতে পারবেন।',
			'lending.resumeMessage' => 'এই রিজার্ভেশনটি আবার চালু করবেন, যাতে লাইব্রেরি পরবর্তী উপলব্ধ কপিটি আপনাকে দিতে পারে?',
			'lending.editEmail' => 'ইমেলের বিজ্ঞাপন পরিবর্তন',
			'audiobook.syncTitle' => 'Read & Listening সিনক',
			'audiobook.syncHelp' => 'আপনার ডিভাইসের মধ্যেই পড়ার অবস্থান, শুনার অবস্থান, সম্পূর্ণন অবস্থান, বুকমার্ক এবং নোট রাখুন. একটি সংযুক্ত স্টোরিং অ্যাকাউন্ট নির্বাচন করুন এবং প্রতিটি ডিভাইসে একই সিন্ক কোড ব্যবহার করুন. পড়ার এবং শুনার অবস্থান আলাদা থাকবে.',
			'audiobook.addSyncSource' => 'প্রথমেই ফাইল এবং বইগুলিতে Google ড্রাইভ, OneDrive, ড্রপবক্স, WebDAV বা S3 যোগ করুন।',
			'audiobook.syncDestination' => 'সিনক স্টোরেজ অ্যাকাউন্ট',
			'audiobook.syncFolder' => 'সিন্ক ফোল্ডার বা প্রফেক্স',
			'audiobook.syncFolderHelp' => 'আপনার WebDAV সূত্রের মধ্যে একটি নির্দিষ্ট অ্যাপ্লিকেশন ব্যবহার করুন, অথবা একটি নির্দিষ্ট S3 পূর্বাভাস ব্যবহার করুন. বই ফাইলগুলি কখনো পরিবর্তন হয় না।',
			'audiobook.syncCode' => 'ব্যক্তিগত সিন্ক কোড',
			'audiobook.syncCodeHelp' => 'আপনার প্রথম ডিভাইসে একটি কোড তৈরি করুন, তারপর আপনার অন্যান্য ডিভাইসে সেই কোড লিখুন. একটি ব্যক্তিগত কপি রাখুন: এটি আপনার সক্রিপ্ট অবস্থার চিঠি।',
			'audiobook.showCode' => 'সিন্ক কোড প্রদর্শন বা লুকিয়ে রাখুন',
			'audiobook.newSyncCode' => 'নতুন সিন্ক কোড তৈরি করুন',
			'audiobook.saveSync' => 'সিনক এবং সিনক',
			'audiobook.disableSync' => 'এই ডিভাইসে সিন্ক বন্ধ করুন',
			'audiobook.syncSourceDisconnect' => 'এই সূত্রটি মুছে ফেলুন, এখানে পড়ার এবং শুনার সনাকশন বন্ধ হবে. ক্রিপ্ট সনাকশন ফাইলগুলি সরবরাহকারী মধ্যে থাকবে।',
			'audiobook.syncReconnect' => 'সংরক্ষণ অ্যাকাউন্ট পুনরায়',
			'audiobook.lastSynced' => ({required Object time}) => 'শেষ সমন্বয় ${time}',
			'audiobook.syncPrivacy' => 'শুধু সক্রিপ্ট প্রসেস এবং নোট সংরক্ষণ করা হয়. অডিও এবং ইবুক ফাইল, অ্যাকাউন্ট টোকেন এবং পাসওয়ার্ড আপলোড করা হয় না. Google ড্রাইভ এবং OneDrive অ্যাপ স্টোরেজ ব্যবহার করে; ড্রপবক্স PlezyNG সিন্ক ব্যবহার করে. সিন্ক অনুমোদন আরও লিখিত অ্যাক্সেস প্রয়োজন হতে পারে. সক্রিপ্ট করা হলেও, এই লক্ষ্য প্রসেস সিন্ক মালিক; সার্ভার প্রসেস আলাদা থাকে. সিন্ক বন্ধ করে স্থানীয় ইতিহাস এবং আলাদা অবস্থা সংরক্ষণ করে।',
			'audiobook.syncConflicts' => 'জেনে নিন কোথায় ফিরে আসতে হবে',
			'audiobook.conflictHelp' => 'এই পরিবর্তনগুলি স্বাধীনভাবে করা হয়. রাখার জন্য অবস্থান বা বুকমার্ক সংস্করণ নির্বাচন করুন. একটি পরবর্তী সময়সীমা বা একটি উচ্চ প্রয়োগ স্বয়ংক্রিয়ভাবে জিতবে না।',
			'audiobook.syncDevice' => ({required Object device}) => 'ডিভাইস ${device}',
			'audiobook.syncUnknownDevice' => 'অজ্ঞাত ডিভাইস',
			'audiobook.deletedBookmark' => 'মুছে ফেলা বইমেলা',
			'audiobook.finished' => 'শেষ',
			'audiobook.readingPosition' => ({required Object percent}) => 'পড়ুন · ${percent}%',
			'audiobook.chapterTimeline' => 'চিঠি উন্নয়ন',
			'audiobook.bookTimeline' => 'পুরো বই উন্নতি',
			'audiobook.bookRemaining' => ({required Object time}) => 'এই বইতে বাকি সময়: ${time}',
			'audiobook.chapterRemaining' => ({required Object time}) => 'এই বিভাগে বাকি সময়: ${time}',
			'audiobook.unknownRemaining' => 'সম্পূর্ণ সময় খেলা হয় যখন অংশগুলি খেলা হয়',
			'audiobook.undoSeek' => 'শেষ অনুসন্ধান',
			'audiobook.customSpeed' => 'কাস্টম Playback গতি',
			'audiobook.speedHelp' => '0.25× থেকে 4× পর্যন্ত গতি নির্বাচন করুন।',
			'audiobook.apply' => 'প্রয়োগ করুন',
			'audiobook.customSleep' => 'কাস্টম Sleep Timer',
			'audiobook.sleepMinutes' => 'মিনিট (1–1440)',
			'audiobook.sleepChapters' => ({required Object count}) => '${count} বিভাগের পর বন্ধ',
			'audiobook.extendSleep' => '৫ মিনিট যোগ করুন',
			'audiobook.sleepRemaining' => ({required Object time}) => 'ঘুম টাইমার: ${time}',
			'audiobook.useDefaults' => 'নতুন বইয়ের জন্য এই শোনা নিয়ন্ত্রণগুলি ব্যবহার করুন',
			'audiobook.librarySort' => 'কঠিন বই',
			'audiobook.sortTitle' => 'Title নাম',
			'audiobook.sortAuthor' => 'লেখক',
			'audiobook.sortNarrator' => 'ন্যায়ক',
			'audiobook.sortSeries' => 'সিরিজ আদেশ',
			'audiobook.sortRecent' => 'সম্প্রতি খোলা',
			'audiobook.statusFilter' => 'পড়ার অবস্থা',
			'audiobook.statusAll' => 'সব বই',
			'audiobook.statusNew' => 'শুরু না',
			'audiobook.statusProgress' => 'প্রদর্শন',
			'audiobook.statusFinished' => 'শেষ',
			'audiobook.goToTime' => 'সময় নিয়ে যান',
			'audiobook.timeHelp' => 'ঘণ্টা : মিনিট : সেকেন্ড বা মিনিট : সেকেন্ড',
			'audiobook.recoveryHelp' => 'সিঙ্ক ডেটা সরানোর বা মেরামত করার আগে সাম্প্রতিক এনক্রিপ্ট করা কপি রপ্তানি করুন। আমদানি করলে বর্তমান অবস্থার সঙ্গে ডেটা মিশে যাবে; স্থানীয় সিঙ্ক ইতিহাস কখনো প্রতিস্থাপিত হবে না। সিঙ্ক কোড আলাদা করে রাখুন।',
			'audiobook.recoveryExport' => 'ডাউনলোড সক্রিপ্ট ফাইল',
			'audiobook.recoveryImport' => 'ডাউনলোড সক্রিপ্ট ফাইল',
			'audiobook.recoveryImportConfirm' => 'এই এনক্রিপ্ট করা পুনরুদ্ধার ফাইলটি বর্তমান পড়ার অবস্থান ও নোটের সঙ্গে মেশাবেন? আগের ইতিহাস থাকবে। শেয়ার করা লাইব্রেরি ও আইটেম ID এতে নেই; আমদানির আগে প্রতিটি ডিভাইসে একই ID সেট করুন।',
			'audiobook.recoveryExported' => 'সক্রিপ্ট ফাইল পুনরায় সংরক্ষণ করা হয়েছে।',
			'audiobook.recoveryImported' => 'রেকর্ড ডেটা একত্রিত।',
			'sourceSetup.savedCertificate' => 'সংরক্ষিত সার্ভার সার্টিফিকেট',
			'sourceSetup.nfsEndpointInvalid' => 'nfs://nas:2049/export-এর মতো একটি NFS URL লিখুন।',
			'sourceSetup.dlnaNone' => 'কোনো DLNA সার্ভার পাওয়া যায়নি। ডিভাইসের বিবরণের URL নিজে লিখুন।',
			'sourceSetup.dlnaServers' => 'DLNA মিডিয়া সার্ভার',
			'sourceSetup.dlnaUnavailable' => 'এই নেটওয়ার্কে DLNA ডিভাইস খোঁজা যাচ্ছে না। ডিভাইসের বিবরণের URL নিজে লিখুন।',
			'sourceSetup.dlnaSearching' => 'স্থানীয় নেটওয়ার্কে DLNA সার্ভার খোঁজা হচ্ছে',
			'sourceSetup.networkSearching' => 'স্থানীয় নেটওয়ার্কে খোঁজা হচ্ছে…',
			'sourceSetup.dlnaDiscover' => 'DLNA সার্ভার খুঁজুন',
			'sourceSetup.dlnaHelp' => 'ডিভাইস খুঁজতে স্থানীয় নেটওয়ার্কে মাল্টিকাস্ট প্রয়োজন। কোনো সার্ভার না দেখালে উপরে তার ডিভাইসের বিবরণের URL লিখুন।',
			'sourceSetup.dlnaRoot' => 'DLNA অবজেক্ট ID; ডিভাইসের রুট ব্যবহার করতে ফাঁকা রাখুন।',
			'sourceSetup.passwordOrKey' => 'পাসওয়ার্ড লিখুন অথবা নিচে একটি ব্যক্তিগত কী যোগ করুন।',
			'sourceSetup.sshFingerprint' => 'SSH হোস্ট কী-এর SHA256 ফিঙ্গারপ্রিন্ট',
			'sourceSetup.sshFingerprintHelp' => 'সার্ভারের প্রশাসকের কাছে যাচাই করুন। সার্ভারে ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub চালিয়ে পাওয়া SHA256 মানটি ব্যবহার করুন।',
			'sourceSetup.sshFingerprintKeep' => 'বর্তমানে পিন করা ফিঙ্গারপ্রিন্ট রাখতে ফাঁকা রাখুন, অথবা সার্ভারের নতুন ফিঙ্গারপ্রিন্ট লিখুন।',
			'sourceSetup.sshAuthentication' => 'SSH পাবলিক কী দিয়ে পরিচয় যাচাই',
			'sourceSetup.sshAuthenticationHelp' => 'ঐচ্ছিক; পাসওয়ার্ড দিয়েও পরিচয় যাচাই করা যায়।',
			'sourceSetup.privateKey' => 'ব্যক্তিগত কী (PEM বা OpenSSH ফরম্যাট)',
			'sourceSetup.privateKeyPassphrase' => 'ব্যক্তিগত কী-এর পাসফ্রেজ',
			'sourceSetup.nfsMountPort' => 'NFS মাউন্ট সেবার TCP পোর্ট',
			'sourceSetup.nfsMountPortHelp' => 'ডিফল্ট: 20048',
			'sourceSetup.nfsUserId' => 'NFS ব্যবহারকারী ID (AUTH_SYS)',
			'sourceSetup.nfsUserIdHelp' => 'ডিফল্ট: 1000। NAS এক্সপোর্টে অনুমোদিত ID ব্যবহার করুন।',
			'sourceSetup.nfsGroupId' => 'NFS গ্রুপ ID (AUTH_SYS)',
			'sourceSetup.nfsGroupIdHelp' => 'ডিফল্ট: 1000। NAS এক্সপোর্টে অনুমোদিত গ্রুপ ID ব্যবহার করুন।',
			'sourceSetup.nfsEncryption' => 'এনক্রিপ্ট করা NFS বাধ্যতামূলক করুন (RPC-with-TLS)',
			'sourceSetup.nfsEncryptionHelp' => 'NFS ও মাউন্ট সেবার জন্য TLS 1.3 বাধ্যতামূলক করুন। NAS এটি সমর্থন না করলে সংযোগ প্রত্যাখ্যান করা হবে।',
			'sourceSetup.nfsTrustCertificate' => 'কাস্টম NFS CA বা সার্ভার সার্টিফিকেট (PEM, ঐচ্ছিক)',
			'sourceSetup.nfsTrustHelp' => 'এই ডিভাইসের বিশ্বস্ত সার্টিফিকেটের জন্য ফাঁকা রাখুন। প্রয়োজনে ব্যক্তিগত CA বা স্ব-স্বাক্ষরিত সার্ভার সার্টিফিকেট যোগ করুন; এর নামগুলো NFS URL-এর হোস্টের সঙ্গে মিলতে হবে।',
			'sourceSetup.nfsTrustInvalid' => 'PEM ফরম্যাটে CA বা সার্ভার সার্টিফিকেট ব্যবহার করুন। ব্যক্তিগত কী অন্তর্ভুক্ত করবেন না।',
			'sourceSetup.addTrustCertificate' => 'কাস্টম বিশ্বস্ত সার্টিফিকেট যোগ করুন',
			'sourceSetup.replaceTrustCertificate' => 'সংরক্ষিত কাস্টম সার্টিফিকেট প্রতিস্থাপন করুন',
			'sourceSetup.nfsTlsHelp' => 'RPC-with-TLS সাধারণ NFS ও মাউন্ট সেবার পোর্ট ব্যবহার করে এবং NAS-এ RFC 9289 সমর্থন থাকা প্রয়োজন। TLS 1.3 বাধ্যতামূলক। হোস্টের নাম বা IP সার্টিফিকেটের সঙ্গে মিলতে হবে। এনক্রিপ্ট করা চ্যানেলের ভেতরেও AUTH_SYS UID/GID প্রযোজ্য থাকে।',
			'sourceSetup.clientCertificate' => 'ক্লায়েন্ট সার্টিফিকেট (ঐচ্ছিক)',
			'sourceSetup.clientCertificateHelp' => 'NAS-কে এই ক্লায়েন্টের পরিচয় যাচাই করতে দেয়; AUTH_SYS ID এখনো NAS এক্সপোর্টের নীতির ওপর নির্ভর করে।',
			'sourceSetup.savedIdentity' => 'ক্লায়েন্টের সংরক্ষিত পরিচয়পত্র ব্যবহার করা হবে।',
			'sourceSetup.replaceIdentity' => 'ক্লায়েন্টের সংরক্ষিত পরিচয়পত্র প্রতিস্থাপন করুন',
			'sourceSetup.chooseIdentity' => 'PKCS#12 ক্লায়েন্ট পরিচয়পত্র বেছে নিন',
			'sourceSetup.identityPassphrase' => 'ক্লায়েন্ট পরিচয়পত্রের পাসফ্রেজ',
			'sourceSetup.identityPassphraseHelp' => 'ফাইলে পাসফ্রেজ না থাকলে ফাঁকা রাখুন।',
			'sourceSetup.removeIdentity' => 'ক্লায়েন্টের সংরক্ষিত পরিচয়পত্র সরান',
			'sourceSetup.identityStorageHelp' => 'ক্লায়েন্টের পরিচয়পত্র উৎসের এনক্রিপ্ট করা প্রবেশতথ্যের ভান্ডারে রাখা হয়। সংরক্ষিত পরিচয়পত্র রাখতে এই অংশ অপরিবর্তিত রাখুন।',
			'sourceSetup.nfsLimitations' => 'TCP-এর মাধ্যমে শুধু পড়ার জন্য NFSv3। RPC-with-TLS ছাড়া NFS ট্র্যাফিক এনক্রিপ্ট করা হয় না। NAS-এ নির্বাচিত AUTH_SYS ID এবং বিশেষ অধিকার প্রয়োজন হয় না এমন ক্লায়েন্ট পোর্টের অনুমতি থাকতে হবে (এক্সপোর্টের এই বিকল্পকে সাধারণত “insecure” বলা হয়)। NFSv4 ও UDP সমর্থিত নয়।',
			'sourceSetup.nfsSetupHelp' => 'NFS সেটআপ সহায়তা',
			'sourceSetup.nfsSetupHint' => 'সংযোগ না খুললে এই সেটিংগুলো পরীক্ষা করুন।',
			'sourceSetup.nfsSetupDetails' => 'TCP-ভিত্তিক NFSv3 এক্সপোর্ট ব্যবহার করুন। এনক্রিপশন বাধ্যতামূলক হলে NFS ও মাউন্ট সেবা—দুটিকেই RPC-with-TLS সমর্থন করতে হবে। এই ডিভাইস সার্ভার সার্টিফিকেটকে বিশ্বাস করলে কাস্টম সার্টিফিকেট ফাঁকা রাখুন; অন্যথায় NAS-এর CA বা স্ব-স্বাক্ষরিত সার্টিফিকেট যোগ করুন। সার্টিফিকেটের নাম এন্ডপয়েন্টের হোস্টের সঙ্গে মিলতে হবে। NAS পারস্পরিক TLS চাইলে তার PKCS#12 ক্লায়েন্ট পরিচয়পত্র যোগ করুন। শেষে নিশ্চিত করুন, এক্সপোর্টে নির্ধারিত AUTH_SYS UID/GID ও ক্লায়েন্ট পোর্ট নীতির অনুমতি আছে।',
			'sourceSetup.ftpHelp' => 'FTP প্যাসিভ মোড ব্যবহার করে। এনক্রিপশন ছাড়া FTP-এর জন্য ftp://, আলাদা কমান্ড দিয়ে TLS চালু করতে ftpes://, অথবা TLS-এর জন্য ftps:// ব্যবহার করুন (পোর্ট 990-এ TLS সঙ্গে সঙ্গে চালু হয়; অন্য পোর্টে আলাদা কমান্ড দিয়ে চালু হয়)।',
			'sourceSetup.openSubtitles' => 'OpenSubtitles',
			'sourceSetup.subtitleSetup' => 'স্বতন্ত্র ভিডিও ফাইলের জন্য ঐচ্ছিক সাবটাইটেল অনুসন্ধান।',
			'sourceSetup.apiKey' => 'API কী',
			'sourceSetup.optionalUsername' => 'অ্যাকাউন্টের ব্যবহারকারীর নাম (ঐচ্ছিক)',
			'sourceSetup.optionalPassword' => 'অ্যাকাউন্টের পাসওয়ার্ড (ঐচ্ছিক)',
			'sourceSetup.subtitlePrivacy' => 'opensubtitles.com থেকে API কী নিন। অনুসন্ধানে ভিডিওর শিরোনাম ও উপলব্ধ IMDb/TMDB ID পাঠানো হয়, ভিডিও ফাইল কখনোই পাঠানো হয় না। কী ও ঐচ্ছিক অ্যাকাউন্টের প্রবেশতথ্য এই উৎসের সঙ্গে এনক্রিপ্ট করে রাখা হয়।',
			'sourceSetup.automaticMetadata' => 'স্বয়ংক্রিয়ভাবে অনলাইন ভিডিও মেটাডেটা পান',
			'sourceSetup.metadataPrivacy' => 'শুধু ফাইলের নাম থেকে শিরোনাম, বছর ও পর্বের নম্বর অথবা NFO ID পাঠানো হয়; মিডিয়া বা প্রবেশতথ্য কখনো পাঠানো হয় না। NFO ফিল্ড সবসময় অগ্রাধিকার পায়।',
			'sourceSetup.nfsEncryptionFailure' => 'এনক্রিপ্ট করা NFS-এর জন্য NAS-এর দুই সেবায় RFC 9289 ও TLS 1.3 সমর্থন, সার্টিফিকেটের নাম এবং এক্সপোর্টের UID/GID পরীক্ষা করুন। PlezyNG এনক্রিপশন ছাড়া এই সংযোগ আবার চেষ্টা করবে না।',
			'sourceSetup.sourceConnecting' => 'উৎসের সঙ্গে সংযোগ করা হচ্ছে',
			'sourceSetup.metadataSearchPrivacy' => 'এই শিরোনাম অনুসন্ধান Trakt-এ পাঠানো হয়। শুধু আপনার লেখা শিরোনাম পাঠানো হয়, ভিডিও বা উৎসের প্রবেশতথ্য নয়।',
			'sourceSetup.chooseMatch' => 'মিল পাওয়া ফলাফল বেছে নিন',
			'sourceSetup.metadataMatchHelp' => 'বেছে নেওয়ার আগে শিরোনাম ও বছর পরীক্ষা করুন। Trakt অনুসন্ধানের শিরোনাম পায়; ভিডিও তার উৎসেই থাকে।',
			'sourceSetup.metadataNoMatches' => 'অনলাইনে মিলে যায় এমন কোনো শিরোনাম পাওয়া যায়নি। অন্য শিরোনাম দিয়ে চেষ্টা করুন।',
			'sourceSetup.metadataSearch' => 'অনলাইন মেটাডেটা খুঁজুন',
			'sourceSetup.metadataLoading' => 'সিনেমা ও টিভি অনুষ্ঠানের তথ্য অনলাইনে খোঁজা হচ্ছে…',
			'sourceSetup.metadataFromTrakt' => 'Trakt থেকে অনলাইন মেটাডেটা',
			'sourceSetup.metadataNoAutomaticMatch' => 'স্বয়ংক্রিয়ভাবে কোনো শিরোনামের মিল পাওয়া যায়নি। শিরোনাম খুঁজে সঠিক ফলাফল বেছে নিন।',
			'sourceSetup.metadataFailed' => 'অনলাইন মেটাডেটা লোড করা যায়নি। প্লেব্যাক ও স্থানীয় তথ্য এখনো পাওয়া যাবে।',
			'sourceSetup.videoDetailsLoading' => 'ভিডিওর তথ্য লোড হচ্ছে',
			'sourceSetup.subtitleKeyRequired' => 'OpenSubtitles API কী প্রয়োজন',
			'sourceSetup.subtitleKeyHelp' => 'এই ফাইল উৎসটি সম্পাদনা করে তার ঐচ্ছিক সাবটাইটেল সেটিংসে OpenSubtitles API কী যোগ করুন।',
			'sourceSetup.subtitleSearchFailed' => 'সাবটাইটেল অনুসন্ধান ব্যর্থ হয়েছে। API কী, সংযোগ ও সেবায় প্রবেশাধিকার পরীক্ষা করুন।',
			'sourceSetup.subtitleApplyFailed' => 'এই সাবটাইটেল ডাউনলোড বা প্রয়োগ করা যায়নি। সংযোগ পরীক্ষা করে অন্য ফলাফল দিয়ে চেষ্টা করুন।',
			'sourceSetup.subtitleSearch' => 'OpenSubtitles-এ খুঁজুন',
			'sourceSetup.subtitleSearchPrivacy' => 'অনুসন্ধানে শিরোনাম ও উপলব্ধ IMDb/TMDB ID ব্যবহার করা হয়। ভিডিও ফাইল তার উৎসেই থাকে। বেছে নেওয়ার আগে ভাষা, বাধ্যতামূলকভাবে দেখানো বা শ্রবণপ্রতিবন্ধীদের উপযোগী সাবটাইটেলের চিহ্ন এবং রেটিং পরীক্ষা করুন।',
			'sourceSetup.movieOrShow' => 'সিনেমা বা টিভি অনুষ্ঠান',
			'sourceSetup.subtitleTitleHint' => 'ফলাফল সীমিত করতে শিরোনাম লিখুন',
			'sourceSetup.subtitleLanguage' => 'সাবটাইটেলের ভাষা',
			'sourceSetup.subtitleSearching' => 'OpenSubtitles-এ খোঁজা হচ্ছে',
			'sourceSetup.subtitleNoMatches' => 'কোনো মিল পাওয়া সাবটাইটেল নেই। অন্য শিরোনাম বা ভাষা দিয়ে চেষ্টা করুন।',
			'sourceSetup.downloadSubtitle' => 'সাবটাইটেল ডাউনলোড করুন',
			'sourceSetup.subtitle' => 'সাবটাইটেল',
			'sourceSetup.nfsTlsRequired' => 'RPC-with-TLS বাধ্যতামূলক',
			'sourceSetup.nfsUnencrypted' => 'এনক্রিপশন ছাড়া NFS',
			'sourceSetup.tlsEncrypted' => 'TLS দিয়ে এনক্রিপ্ট করা',
			'sourceSetup.ftpPlain' => 'এনক্রিপশন ছাড়া FTP',
			'sourceSetup.sshPinned' => 'SSH দিয়ে এনক্রিপ্ট করা · হোস্ট কী পিন করা আছে',
			'sourceSetup.smbEncrypted' => 'SMB3 এনক্রিপশন চালু',
			'sourceSetup.smbUnencrypted' => 'SMB3 এনক্রিপশন বন্ধ',
			'sourceSetup.httpUnencrypted' => 'পরিবহন এনক্রিপশন ছাড়া HTTP',
			'sourceSetup.checkEndpointSecurity' => 'এন্ডপয়েন্টের নিরাপত্তা পরীক্ষা করুন',
			'sourceSetup.fieldRequired' => ({required Object label}) => '${label} লেখা আবশ্যক।',
			'sourceSetup.integerRange' => ({required Object label, required Object min, required Object max}) => '${label}-এর মান ${min} থেকে ${max}-এর মধ্যে লিখুন।',
			'sourceSetup.replaceFile' => ({required Object name}) => '${name} প্রতিস্থাপন করুন',
			'sourceSetup.selectedIdentity' => ({required Object name}) => 'ক্লায়েন্টের নির্বাচিত পরিচয়পত্র: ${name}',
			'sourceSetup.subtitleRating' => ({required Object rating}) => 'রেটিং ${rating}',
			'sourceSetup.subtitleDownloading' => ({required Object title}) => 'সাবটাইটেল ডাউনলোড হচ্ছে: ${title}',
			'sourceSetup.sharedEntryPair' => 'এই জিনিসকে প্যারি করুন',
			'sourceSetup.sharedEntryPairHelp' => 'প্রতিটি ডিভাইসে এই আইটেমের জন্য একই ID লিখুন। স্থায়ী শেয়ার করা শনাক্তকারী ব্যবহার করুন অথবা একটি তৈরি করে সংশ্লিষ্ট আইটেমে কপি করুন। সংস্করণের ফাইলের ধরন, আকার ও ক্রম মিললেই অগ্রগতি যুক্ত হবে। ফাঁকা রাখলে এই ম্যাপিং মুছে যাবে।',
			'sourceSetup.sharedEntryId' => 'শেয়ার আইটেম ID',
			'sourceSetup.generateSharedEntryId' => 'শেয়ার আইটেম ID তৈরি করুন',
			'sourceSetup.sharedLibraryId' => 'বিতরণিত লাইব্রেরি ID (অন্যাশনাল)',
			'sourceSetup.sharedLibraryHelp' => 'একই লাইব্রেরি খোলা ডিভাইসগুলোতে একই ID ব্যবহার করুন। এই পাবলিক ID বিভিন্ন সোর্স সংযোগে পড়ার অগ্রগতি ও নোট বহন করতে সাহায্য করে; এটি পাসওয়ার্ড নয়। প্রোভাইডার ভিন্ন আইটেম ID ব্যবহার করলে, আইটেমের বিস্তারিত স্ক্রিনে সেগুলো জুড়ুন।',
			'sourceSetup.sharedLibraryInvalid' => '8-100 বাক্স, নম্বর, পয়েন্ট, সাবস্কোর বা হাইফেন্স ব্যবহার করুন।',
			'sourceSetup.generateSharedLibraryId' => 'একটি বিতর্কিত লাইব্রেরি ID তৈরি করুন',
			'sourceSetup.nfsReadAhead' => 'NFS Read-ahead অনুরোধ',
			'sourceSetup.nfsReadAheadHelp' => 'দ্রুত NAS বা নেটওয়ার্কে আরও সমান্তরাল রিড থ্রুপুট বাড়াতে পারে। সার্ভার একসঙ্গে অনুরোধ সীমিত করলে 1 ব্যবহার করুন।',
			'sourceSetup.nfsReadTest' => 'NFS পড়া দক্ষতা মাত্রা',
			'sourceSetup.nfsReadTestHelp' => 'এই NAS সংযোগকে মাত্রা করার জন্য সবচেয়ে বড় ফাইল থেকে 64 MiB পর্যন্ত পড়তে পারে।',
			'sourceSetup.nfsQualificationResult' => 'NFS পড়ুন মাত্রা',
			'sourceSetup.nfsReadBytes' => 'ডাটা পড়ুন',
			'sourceSetup.nfsReadSpeed' => 'গতি মাত্রা',
			'sourceSetup.nfsReadRequests' => 'অনুরোধ পড়ুন',
			'sourceSetup.sharedEntryConflict' => 'এই শেয়ার করা আইটেম ID ইতিমধ্যে এই লাইব্রেরির অন্য আইটেমের সঙ্গে যুক্ত। অন্য ID বেছে নিন।',
			'comics.fitHeight' => 'উচ্চতা অনুযায়ী মানানসই',
			'comics.readingMode' => 'পড়ার ধরন',
			'comics.paged' => 'পৃষ্ঠা',
			'comics.webtoon' => 'একটানা স্ক্রল',
			'comics.coverAlone' => 'প্রচ্ছদ আলাদা করে দেখান',
			'comics.splitWide' => 'চওড়া পৃষ্ঠা ভাগ করুন',
			'comics.splitWideHelp' => 'পড়ার ক্রম অনুযায়ী প্রতিটি অর্ধেক আলাদা করে দেখান। এটি চালু থাকলে পাশাপাশি দুটি পৃষ্ঠা দেখানো বন্ধ থাকে।',
			'comics.thumbnails' => 'পৃষ্ঠার থাম্বনেইল',
			'comics.controlsHelp' => 'পৃষ্ঠা ওল্টাতে সোয়াইপ করুন। মানানসই আকার বদলাতে দুবার ট্যাপ করুন। একটানা স্ক্রলে উল্লম্বভাবে সোয়াইপ করুন বা Page Up ও Page Down ব্যবহার করুন।',
			'comics.savedForComic' => 'এই প্রোফাইলে এই কমিকের প্রদর্শন সেটিংস মনে রাখা হয়।',
			'comics.readLists' => 'পড়ার তালিকা',
			'comics.collections' => 'সংগ্রহ',
			'games.title' => 'Games',
			'games.enable' => 'Show Games for this profile',
			'games.enableDescription' => 'Discover your gaming computers and play with an embedded streaming engine.',
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
			'games.recent' => 'Recently opened',
			'games.favorites' => 'Favorites',
			'games.allGames' => 'All games',
			'games.search' => 'Find a game',
			'games.noMatches' => 'No games match this search.',
			'games.favorite' => 'Save favorite',
			'games.unfavorite' => 'Remove favorite',
			'games.forget' => 'Forget computer',
			'games.forgetDescription' => 'Remove this computer and its game shortcuts from this profile? To revoke this device’s authorization, remove it from the host’s paired devices.',
			_ => null,
		} ?? switch (path) {
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
			'games.steamBetaTitle' => 'Steam beta · Pyrowave',
			'games.steamBetaDescription' => 'Experimental Steam beta codec. Off by default; it uses 5–10× more bandwidth than H.264/HEVC, and Valve recommends gigabit Ethernet. Android playback is limited to SDR 4:2:0 with CPU readback and has not been device-qualified.',
			'games.steamLibrary' => 'Steam library',
			'games.linkSteamAccount' => 'Link Steam account',
			'games.refreshSteamAccount' => 'Refresh Steam account',
			'games.unlinkSteamAccount' => 'Unlink Steam account',
			'games.unlinkSteamAccountConfirm' => 'Remove this account and its imported catalog from this profile? Your paired computers and shortcuts stay available.',
			'games.steamAccountLinked' => 'Steam account linked. Games imported.',
			'games.steamLibraryPrivate' => 'Steam account linked. Its library is private or unavailable, so no games were imported.',
			'games.steamAppId' => 'Steam App ID',
			'games.steamLibraryStale' => 'Steam could not refresh the library. Showing the last available catalog.',
			'games.steamLibraryTruncated' => 'Showing up to 2,000 games. The Steam catalog was truncated.',
			'games.connecting' => 'Connecting…',
			'games.disconnect' => 'Disconnect',
			'games.streamControls' => 'Stream controls',
			'games.steamPairInstructions' => 'Enter this code in Steam’s Remote Play pairing prompt on your computer. Keep this screen open until Steam approves.',
			'games.steamLibraryHint' => 'Steam device pairing opens its library inside the stream. Add a shortcut with a Steam app ID for direct launch. Importing a private account library as game cards requires a separate authenticated catalog connection.',
			'deepLinks.invalid' => 'এই Plezy লিঙ্ক সঠিক নয়।',
			'deepLinks.profileNotFound' => ({required Object profile}) => 'কোন প্রোফাইল "${profile}" সঙ্গে জড়িত না।',
			'deepLinks.serverUnavailable' => 'আমি এই লিঙ্কের জন্য সার্ভার পৌঁছাতে পারিনি।',
			'deepLinks.notFound' => 'আপনার লাইব্রেরিতে এই নামটি পাওয়া যায় না।',
			'deepLinks.unsupportedItem' => 'এই লিঙ্ক খেলতে পারে না।',
			'deepLinks.noLiveTv' => 'এই লিঙ্ক জন্য কোন লাইভ টিভি সার্ভার পাওয়া যায় না।',
			'deepLinks.channelNotFound' => ({required Object channel}) => 'আমি চ্যানেল "${channel}" খুঁজতে পারিনি।',
			'deepLinks.showLink' => 'দেখুন লিঙ্ক',
			'deepLinks.showProfileLink' => 'প্রোফাইল লিঙ্ক',
			'deepLinks.dialogTitle' => 'লিঙ্ক',
			'deepLinks.showHint' => 'এই লিংক খুললে পরের পর্বটি চলবে। সিরিজটি এলোমেলোভাবে চালাতে শেষে &mode=shuffle যোগ করুন.',
			'deepLinks.movieHint' => 'এই লিঙ্ক খুলে চলচ্চিত্রটি খেলবে।',
			'deepLinks.episodeHint' => 'এই লিঙ্কটি খোঁজে এ епизодটি খেলতে হবে।',
			'deepLinks.profileHint' => 'এই লিঙ্কটি খুলতে, এই প্রোফাইলের জন্য বিনিময় করা হয়।',
			'deepLinks.openAsProfile' => ({required Object name}) => '${name} হিসাবে খোলা',
			'deepLinks.copy' => 'কপি',
			'deepLinks.copied' => 'লিঙ্ক কপি',
			_ => null,
		};
	}
}
