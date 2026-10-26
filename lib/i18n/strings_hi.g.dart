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
class TranslationsHi extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsHi({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.hi,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <hi>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsHi _root = this; // ignore: unused_field

	@override 
	TranslationsHi $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsHi(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$hi app = _Translations$app$hi._(_root);
	@override late final _Translations$cast$hi cast = _Translations$cast$hi._(_root);
	@override late final _Translations$automation$hi automation = _Translations$automation$hi._(_root);
	@override late final _Translations$notifications$hi notifications = _Translations$notifications$hi._(_root);
	@override late final _Translations$appIcon$hi appIcon = _Translations$appIcon$hi._(_root);
	@override late final _Translations$auth$hi auth = _Translations$auth$hi._(_root);
	@override late final _Translations$common$hi common = _Translations$common$hi._(_root);
	@override late final _Translations$screens$hi screens = _Translations$screens$hi._(_root);
	@override late final _Translations$update$hi update = _Translations$update$hi._(_root);
	@override late final _Translations$appAccess$hi appAccess = _Translations$appAccess$hi._(_root);
	@override late final _Translations$settings$hi settings = _Translations$settings$hi._(_root);
	@override late final _Translations$themeEditor$hi themeEditor = _Translations$themeEditor$hi._(_root);
	@override late final _Translations$search$hi search = _Translations$search$hi._(_root);
	@override late final _Translations$hotkeys$hi hotkeys = _Translations$hotkeys$hi._(_root);
	@override late final _Translations$fileInfo$hi fileInfo = _Translations$fileInfo$hi._(_root);
	@override late final _Translations$mediaMenu$hi mediaMenu = _Translations$mediaMenu$hi._(_root);
	@override late final _Translations$rateSheet$hi rateSheet = _Translations$rateSheet$hi._(_root);
	@override late final _Translations$accessibility$hi accessibility = _Translations$accessibility$hi._(_root);
	@override late final _Translations$tooltips$hi tooltips = _Translations$tooltips$hi._(_root);
	@override late final _Translations$audioTracks$hi audioTracks = _Translations$audioTracks$hi._(_root);
	@override late final _Translations$videoControls$hi videoControls = _Translations$videoControls$hi._(_root);
	@override late final _Translations$messages$hi messages = _Translations$messages$hi._(_root);
	@override late final _Translations$subtitlingStyling$hi subtitlingStyling = _Translations$subtitlingStyling$hi._(_root);
	@override late final _Translations$mpvConfig$hi mpvConfig = _Translations$mpvConfig$hi._(_root);
	@override late final _Translations$dialog$hi dialog = _Translations$dialog$hi._(_root);
	@override late final _Translations$profiles$hi profiles = _Translations$profiles$hi._(_root);
	@override late final _Translations$connections$hi connections = _Translations$connections$hi._(_root);
	@override late final _Translations$accountPreferences$hi accountPreferences = _Translations$accountPreferences$hi._(_root);
	@override late final _Translations$discover$hi discover = _Translations$discover$hi._(_root);
	@override late final _Translations$errors$hi errors = _Translations$errors$hi._(_root);
	@override late final _Translations$libraries$hi libraries = _Translations$libraries$hi._(_root);
	@override late final _Translations$about$hi about = _Translations$about$hi._(_root);
	@override late final _Translations$serverSelection$hi serverSelection = _Translations$serverSelection$hi._(_root);
	@override late final _Translations$hubDetail$hi hubDetail = _Translations$hubDetail$hi._(_root);
	@override late final _Translations$logs$hi logs = _Translations$logs$hi._(_root);
	@override late final _Translations$detail$hi detail = _Translations$detail$hi._(_root);
	@override late final _Translations$startup$hi startup = _Translations$startup$hi._(_root);
	@override late final _Translations$licenses$hi licenses = _Translations$licenses$hi._(_root);
	@override late final _Translations$navigation$hi navigation = _Translations$navigation$hi._(_root);
	@override late final _Translations$explore$hi explore = _Translations$explore$hi._(_root);
	@override late final _Translations$liveTv$hi liveTv = _Translations$liveTv$hi._(_root);
	@override late final _Translations$collections$hi collections = _Translations$collections$hi._(_root);
	@override late final _Translations$playlists$hi playlists = _Translations$playlists$hi._(_root);
	@override late final _Translations$music$hi music = _Translations$music$hi._(_root);
	@override late final _Translations$watchTogether$hi watchTogether = _Translations$watchTogether$hi._(_root);
	@override late final _Translations$downloads$hi downloads = _Translations$downloads$hi._(_root);
	@override late final _Translations$shaders$hi shaders = _Translations$shaders$hi._(_root);
	@override late final _Translations$companionRemote$hi companionRemote = _Translations$companionRemote$hi._(_root);
	@override late final _Translations$videoSettings$hi videoSettings = _Translations$videoSettings$hi._(_root);
	@override late final _Translations$performanceOverlay$hi performanceOverlay = _Translations$performanceOverlay$hi._(_root);
	@override late final _Translations$externalPlayer$hi externalPlayer = _Translations$externalPlayer$hi._(_root);
	@override late final _Translations$metadataEdit$hi metadataEdit = _Translations$metadataEdit$hi._(_root);
	@override late final _Translations$matchScreen$hi matchScreen = _Translations$matchScreen$hi._(_root);
	@override late final _Translations$serverTasks$hi serverTasks = _Translations$serverTasks$hi._(_root);
	@override late final _Translations$trakt$hi trakt = _Translations$trakt$hi._(_root);
	@override late final _Translations$seerr$hi seerr = _Translations$seerr$hi._(_root);
	@override late final _Translations$services$hi services = _Translations$services$hi._(_root);
	@override late final _Translations$addServer$hi addServer = _Translations$addServer$hi._(_root);
	@override late final _Translations$watchLink$hi watchLink = _Translations$watchLink$hi._(_root);
	@override late final _Translations$homeLayout$hi homeLayout = _Translations$homeLayout$hi._(_root);
	@override late final _Translations$platform$hi platform = _Translations$platform$hi._(_root);
	@override late final _Translations$fileSources$hi fileSources = _Translations$fileSources$hi._(_root);
	@override late final _Translations$lending$hi lending = _Translations$lending$hi._(_root);
	@override late final _Translations$audiobook$hi audiobook = _Translations$audiobook$hi._(_root);
	@override late final _Translations$games$hi games = _Translations$games$hi._(_root);
}

// Path: app
class _Translations$app$hi extends Translations$app$en {
	_Translations$app$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: cast
class _Translations$cast$hi extends Translations$cast$en {
	_Translations$cast$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => 'किसी डिवाइस पर कास्ट करें';
	@override String get searching => 'कस्टम उपकरणों की तलाश में ...';
	@override String connectedTo({required Object device}) => '${device} पर कनेक्ट करें';
	@override String get device => 'कास्ट डिवाइस';
	@override String get readyToCast => 'कास्ट करने के लिए तैयार';
	@override String get subtitle => 'उपशीर्षक';
	@override String get serverNotAvailable => 'मीडिया सर्वर उपलब्ध नहीं है।';
	@override String get stopCasting => 'कास्ट करना बंद करें';
	@override String get castToDevice => 'डिवाइस पर कास्ट करें';
	@override String get noEpisodeAvailable => 'खेलने के लिए कोई एपिसोड उपलब्ध नहीं है।';
	@override String get startFailed => 'सर्वर की जांच करें और फिर से कोशिश करें।';
}

// Path: automation
class _Translations$automation$hi extends Translations$automation$en {
	_Translations$automation$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => 'नियंत्रित करने के लिए कोई सक्रिय वीडियो सत्र नहीं है।';
	@override String get profileNotFound => 'यह Plezy प्रोफ़ाइल नहीं पाया जा सकता था।';
}

// Path: notifications
class _Translations$notifications$hi extends Translations$notifications$en {
	_Translations$notifications$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => 'नए एपिसोड';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appIcon
class _Translations$appIcon$hi extends Translations$appIcon$en {
	_Translations$appIcon$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'एप्लिकेशन आइकन';
	@override String get defaultIcon => 'मूल';
	@override String get current => 'वर्तमान आइकन';
	@override String get locked => 'जीवन के लिए आवश्यक पहुंच';
	@override String get lockedHint => 'अपने 7 दिन के परीक्षण को शुरू करें या वैकल्पिक आइकन का उपयोग करने के लिए जीवन भर के लिए PlezyNG को अनलॉक करें।';
	@override String get changeFailed => 'ऐप आइकन नहीं बदल सकता';
	@override String get launcherHint => 'नया आइकन आपके होम स्क्रीन पर दिखाई देता है जब आप PlezyNG छोड़ देते हैं।';
	@override String get tvLauncherHint => 'नया बैनर दिखाई देता है जब आप छोड़ दें PlezyNG. Android TV टीवी को फिर से शुरू करने तक पुराने को प्रदर्शित करना जारी रख सकता है।';
	@override late final _Translations$appIcon$names$hi names = _Translations$appIcon$names$hi._(_root);
}

// Path: auth
class _Translations$auth$hi extends Translations$auth$en {
	_Translations$auth$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Plex के साथ साइन इन करें';
	@override String get showQRCode => 'QR कोड दिखाएं';
	@override String get authenticate => 'सच्चाई';
	@override String get authenticationTimeout => 'प्रमाणीकरण समय से समाप्त हो गया है. कृपया फिर से कोशिश करें.';
	@override String get scanQRToSignIn => 'इस QR कोड को स्कैन करने के लिए';
	@override String get waitingForAuth => 'प्रमाणीकरण के लिए इंतजार ... अपने ब्राउज़र से साइन इन करें।';
	@override String get useBrowser => 'ब्राउज़र का उपयोग';
	@override String get or => 'या';
	@override String connectToMediaBrowser({required Object product}) => 'कनेक्ट करें ${product}';
	@override String get quickConnect => 'Quick Connect';
	@override String get useQuickConnect => 'त्वरित कनेक्ट का उपयोग करें';
	@override String get quickConnectInstructions => 'Jellyfin में Quick Connect खोलें और इस कोड को दर्ज करें।';
	@override String get quickConnectWaiting => 'अनुमोदन के लिए इंतजार...';
	@override String get quickConnectCancel => 'रद्द करना';
	@override String get quickConnectExpired => 'त्वरित कनेक्ट की समय-सीमा समाप्त हो गई। फिर कोशिश करें।';
	@override String get localDataRecoveryRequired => 'PlezyNG स्थानीय साइन-इन जानकारी और लंबित प्लेबैक डेटा को सुरक्षित रूप से पुनर्प्राप्त नहीं कर सका। कृपया फिर से साइन इन करें।';
	@override String get pinCheckRejected => 'Plex PIN चेक को अस्वीकार कर दिया गया';
	@override String get connectToDirectPlex => 'स्थानीय सर्वर से कनेक्ट करें Plex';
}

// Path: common
class _Translations$common$hi extends Translations$common$en {
	_Translations$common$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'रद्द करना';
	@override String get save => 'बचाओ';
	@override String get close => 'बंद करें';
	@override String get clear => 'स्पष्ट';
	@override String get reset => 'पुनर्स्थापित';
	@override String get later => 'बाद में';
	@override String get submit => 'प्रस्तुत करें';
	@override String get confirm => 'पुष्टि करें';
	@override String get retry => 'वापसी';
	@override String get logout => 'लॉग बाहर';
	@override String get unknown => 'अज्ञात';
	@override String get refresh => 'ताज़ा';
	@override String get yes => 'हाँ';
	@override String get no => 'नहीं';
	@override String get delete => 'डिलीट';
	@override String get edit => 'संपादित करें';
	@override String get shuffle => 'फेरबदल करें';
	@override String get addTo => 'जोड़ें...';
	@override String get createNew => 'नया बनाएं';
	@override String get connect => 'कनेक्ट करें';
	@override String get disconnect => 'डिस्कनेक्ट';
	@override String get play => 'चलाएँ';
	@override String get pause => 'रोकें';
	@override String get resume => 'फिर से चलाएँ';
	@override String get error => 'गलती';
	@override String get search => 'खोज';
	@override String get home => 'घर';
	@override String get back => 'वापस';
	@override String get settings => 'सेटिंग्स';
	@override String get mute => 'मुट्ठी';
	@override String get ok => 'ठीक';
	@override String get off => 'बंद करें';
	@override String get options => 'विकल्पों';
	@override String seasonNumber({required Object number}) => 'सत्र ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'एपिसोड ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'पदों की संख्या ${number}';
	@override String get reconnect => 'फिर से जुड़ें';
	@override String get viewAll => 'सब देखो';
	@override String get checkingNetwork => 'नेटवर्क की जांच...';
	@override String get loadingServers => 'चार्जिंग सर्वर...';
	@override String get connectingToServers => 'सर्वर से कनेक्ट करने के लिए...';
	@override String get startingOfflineMode => 'ऑफ़लाइन मोड से शुरू...';
	@override String get loading => 'लोड...';
	@override String get fullscreen => 'पूर्ण स्क्रीन';
	@override String get exitFullscreen => 'पूर्ण स्क्रीन से बाहर';
	@override String get pressBackAgainToExit => 'बाहर निकलने के लिए फिर से दबाएं';
	@override late final _Translations$common$ratingSource$hi ratingSource = _Translations$common$ratingSource$hi._(_root);
	@override String get notAvailable => 'ए / ए';
	@override String get url => 'URL';
	@override String get letterKeys => 'एबीसी';
	@override late final _Translations$common$mediaKind$hi mediaKind = _Translations$common$mediaKind$hi._(_root);
}

// Path: screens
class _Translations$screens$hi extends Translations$screens$en {
	_Translations$screens$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'अनुमतिएँ';
	@override String get switchProfile => 'स्विच प्रोफ़ाइल';
	@override String get subtitleStyling => 'Subtitle स्टाइलिंग';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'लॉग';
}

// Path: update
class _Translations$update$hi extends Translations$update$en {
	_Translations$update$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get available => 'अपडेट उपलब्ध';
	@override String versionAvailable({required Object version}) => 'संस्करण ${version} उपलब्ध है';
	@override String currentVersion({required Object version}) => 'वर्तमान में: ${version}';
	@override String get skipVersion => 'इस संस्करण को छोड़ दें';
	@override String get viewRelease => 'देखें रिलीज';
	@override String get latestVersion => 'आप नवीनतम संस्करण पर हैं';
	@override String get checkFailed => 'अद्यतन की जांच नहीं कर पाया';
}

// Path: appAccess
class _Translations$appAccess$hi extends Translations$appAccess$en {
	_Translations$appAccess$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => '7 दिनों के लिए मुफ्त में हर फ़ंक्शन का प्रयास करें';
	@override String get description => 'सभी PlezyNG सुविधाओं के लिए पूर्ण पहुंच के साथ एक सात दिवसीय परीक्षण शुरू करें. परीक्षण के दौरान कोई शुल्क नहीं है और कोई सदस्यता नहीं है. परीक्षण के बाद, आपके स्टोर की कीमत पर एक जीवन भर खरीद PlezyNG जीवन भर लॉक करता है.';
	@override String get trialEndedDescription => 'अपने स्टोर की कीमत पर एक खरीद के साथ जीवन के लिए PlezyNG में प्रत्येक सुविधा को अनलॉक करें. कोई सदस्यता नहीं है.';
	@override String get startTrial => 'मेरे 7 दिन मुफ्त परीक्षण शुरू करें';
	@override String get trialActive => 'आपका 7 दिन का पूर्ण प्रदर्शन परीक्षण सक्रिय है।';
	@override String get trialEnded => '7 दिन का मुकदमा खत्म हो गया है।';
	@override String get trialStartFailed => 'मैं इस डिवाइस पर परीक्षण को बचाने में सक्षम नहीं था. कृपया फिर से कोशिश करें.';
	@override String get lifetimeTitle => 'PlezyNG जीवन के लिए अनलॉक';
	@override String get lifetimeBody => 'आपके पास हर PlezyNG फ़ंक्शन के लिए जीवन भर पहुंच है।';
	@override String get manageTitle => 'PlezyNG जीवन भर पहुंच';
	@override String get manageDescription => '7 दिनों के लिए प्रत्येक सुविधा को मुफ्त में आज़माएं, फिर अपनी दुकान की कीमत पर एक भुगतान के साथ जीवन के लिए सब कुछ लॉक करें।';
	@override String buy({required Object price}) => '${price} के लिए सभी सुविधाओं को अनलॉक करें';
	@override String get loadingPrice => 'दुकान की कीमत...';
	@override String get retryPrice => 'रिट्री की कीमत देखें';
	@override String get restore => 'जीवन भर खरीदें';
	@override String get pending => 'आपका खरीद भुगतान या अनुमोदन का इंतजार कर रहा है. लाइफ-टाइम एक्सेस तुरंत बंद हो जाता है जैसे ही स्टोर इसे पूरा करता है.';
	@override String get storeUnavailable => 'खरीदारी उपलब्ध नहीं है. सुनिश्चित करें कि आप स्टोर में साइन अप कर रहे हैं और इस डिवाइस पर खरीदारी की अनुमति है.';
	@override String get productNotFound => 'PlezyNG जीवन-जीवन अनलॉक अभी तक इस स्टोर में उपलब्ध नहीं है।';
	@override String get productQueryFailed => 'दुकान की कीमत पर लोड नहीं किया जा सकता. अपने कनेक्शन की जांच करें और फिर से कोशिश करें.';
	@override String get purchaseFailed => 'खरीदारी नहीं हुई. फिर से कोशिश करें.';
	@override String get restoreFailed => 'आप अपनी खरीद को पुनर्स्थापित करने के लिए दुकान तक नहीं पहुंच सकते. फिर से कोशिश करें.';
	@override String get nothingToRestore => 'इस स्टोर खाते के लिए PlezyNG जीवन भर खरीद पाया गया था।';
}

// Path: settings
class _Translations$settings$hi extends Translations$settings$en {
	_Translations$settings$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'सेटिंग्स';
	@override String get supportDeveloper => 'समर्थन PlezyNG';
	@override String get supportDeveloperDescription => 'विकास का समर्थन करने के लिए दान';
	@override String get lifetimeAccess => 'PlezyNG जीवन भर पहुंच';
	@override String get language => 'भाषा';
	@override String get theme => 'विषय';
	@override String get appearance => 'दिखाई';
	@override String get detailPage => 'विवरण पृष्ठ';
	@override String get themeSongsEnabled => 'विषय गीतों का खेल';
	@override String get themeSongsEnabledDescription => 'मीडिया विवरण देखने के दौरान उपलब्ध थीम गीत खेलें।';
	@override String get themeSongVolume => 'गीत वॉल्यूम';
	@override String get videoPlayback => 'वीडियो प्लेबैक';
	@override String get videoPlaybackDescription => 'Playback व्यवहार सेट करें';
	@override String get advanced => 'उन्नत';
	@override String get episodePosterMode => 'पोस्टर स्टाइल';
	@override String get seriesPoster => 'सीरीज पोस्टर';
	@override String get seasonPoster => 'मौसम पोस्टर';
	@override String get episodeThumbnail => 'ट्यूबनाइल';
	@override String get showHeroSectionDescription => 'घर स्क्रीन पर सामग्री कैरोसेल दिखाई देता है';
	@override String get secondsLabel => 'सेकंड';
	@override String get minutesLabel => 'मिनट';
	@override String get secondsShort => 'एस';
	@override String get minutesShort => 'एम';
	@override String durationHint({required Object min, required Object max}) => 'एक मूल्य दर्ज करें (${min}-${max})';
	@override String get systemTheme => 'प्रणाली';
	@override String get lightTheme => 'प्रकाश';
	@override String get darkTheme => 'अंधेरा';
	@override String get oledTheme => 'OLED';
	@override String get emberTheme => 'आदमी';
	@override String get glacierTheme => 'आइसक्रीम';
	@override String get forestTheme => 'जंगल';
	@override String get plumTheme => 'प्लम';
	@override String get paperTheme => 'कागज';
	@override String get libraryDensity => 'पुस्तकालय की दबाव';
	@override String get displayScale => 'डिस्प्ले स्केल';
	@override String get compact => 'कॉम्पैक्ट';
	@override String get comfortable => 'आरामदायक';
	@override String get gridSpacing => 'ग्रिड स्पेसिंग';
	@override String get gridSpacingTight => 'टॉयलेट';
	@override String get gridSpacingNormal => 'सामान्य';
	@override String get gridSpacingSpacious => 'अंतरिक्ष';
	@override String get tvCornerSpotlightBackdrop => 'कोर स्पॉटलाइट बैकड्रॉप';
	@override String get tvCornerSpotlightBackdropDescription => 'स्क्रीन भरने के बजाय शीर्ष दाहिने कोने में स्पॉटलाइट कलाकृति दिखाएं';
	@override String get viewMode => 'दृश्य मोड';
	@override String get gridView => 'ग्रिड';
	@override String get listView => 'सूची';
	@override String get showHeroSection => 'Hero सेक्शन दिखाएँ';
	@override String get showHomeBackdrop => 'Home Backdrop आर्टवर्क';
	@override String get showHomeBackdropDescription => 'दिखाए बड़े कलाकृति के पीछे दिखाए गए होम लाइनों';
	@override String get contentScreensaverEnabled => 'सामग्री स्क्रीन सहेजें';
	@override String get contentScreensaverEnabledDescription => 'पूर्ण स्क्रीन कलाकृति दिखाने के बाद ऐप आईडीएल हो गया है';
	@override String get contentScreensaverDelay => 'स्क्रीन सहेजने के बाद';
	@override String get contentScreensaverLibraries => 'Screensaver पुस्तकालय';
	@override String get contentScreensaverLibrariesDescription => 'चुनें कि कौन सी पुस्तकालय स्क्रीन सहेजक कलाकृति प्रदान करते हैं. यदि कोई नहीं चुना जाता है, तो सभी पुस्तकालयों से कलाकृति का उपयोग किया जाता है.';
	@override String get contentScreensaverAllLibraries => 'सभी संग्रह';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} पुस्तकालय चुने गए हैं';
	@override String get contentScreensaverNoLibraries => 'कोई कनेक्ट मीडिया लाइब्रेरी उपलब्ध नहीं है।';
	@override String get contentScreensaverDismissHint => 'किसी भी बटन दबाएं या हटाने के लिए टैप करें';
	@override String get newEpisodeNotifications => 'नए एपिसोड की सूचनाएं';
	@override String get newEpisodeNotificationsDescription => 'चेतावनी जब एक नए एपिसोड को एक शो में जोड़ा जाता है आप पकड़े गए हैं. चेक जब Plezy खुला है.';
	@override String get continueWatchingRowSize => 'आगे देखते हैं आकार की रेंज';
	@override String continueWatchingRowSizeValue({required Object label}) => '${label} कार्ड';
	@override String get rowSizeCompact => 'कॉम्पैक्ट';
	@override String get rowSizeStandard => 'मानक';
	@override String get rowSizeLarge => 'बड़ा';
	@override String get continueWatchingAction => 'आगे देखना कार्रवाई';
	@override String get continueWatchingPlay => 'खेलना';
	@override String get continueWatchingDetails => 'खुले विवरण';
	@override String get episodeAction => 'एपिसोड कार्रवाई';
	@override String get episodePlay => 'खेलना';
	@override String get episodeDetails => 'खुले विवरण';
	@override String get useGlobalHubs => 'Home Layout का उपयोग करें';
	@override String get useGlobalHubsDescription => 'एकीकृत होम हब दिखाएं. अन्यथा पुस्तकालय की सिफारिशों का उपयोग करें.';
	@override String get showServerNameOnHubs => 'Hubs पर सर्वर नाम दिखाएं';
	@override String get showServerNameOnHubsDescription => 'हमेशा हब शीर्षकों में सर्वर नाम दिखाएं।';
	@override String get groupLibrariesByServer => 'सर्वर पर समूह पुस्तकालय';
	@override String get groupLibrariesByServerDescription => 'प्रत्येक मीडिया सर्वर के नीचे समूह साइडबार लाइब्रेरी।';
	@override String get alwaysKeepSidebarOpen => 'हमेशा साइडबार खुले रखें';
	@override String get alwaysKeepSidebarOpenDescription => 'साइडबार विस्तारित रहता है और सामग्री क्षेत्र फिट करने के लिए समायोजित होता है';
	@override String get showUnwatchedCount => 'अनदेखा किए गए अंक';
	@override String get showUnwatchedCountDescription => 'प्रदर्शित अनदेखा एपिसोड शो और मौसमों पर गिनती';
	@override String get showWatchedIndicators => 'दिखाए गए संकेतक';
	@override String get showWatchedIndicatorsDescription => 'देखे गए फिल्मों, शो और एपिसोड पर एक चेकमार्क प्रदर्शित करें';
	@override String get showEpisodeNumberOnCards => 'कार्ड पर एपिसोड नंबर दिखाएं';
	@override String get showEpisodeNumberOnCardsDescription => 'एपिसोड कार्ड पर मौसम और एपिसोड नंबर दिखाएं';
	@override String get showSeasonPostersOnTabs => 'टैब पर मौसम पोस्टर दिखाएं';
	@override String get showSeasonPostersOnTabsDescription => 'प्रत्येक मौसम के पोस्टर को अपने टैब के ऊपर दिखाएं';
	@override String get tvFullCardLayout => 'पूर्ण टीवी कार्ड';
	@override String get tvFullCardLayoutDescription => 'चित्र-केवल टीवी कार्ड का उपयोग अभिनेता नामों के साथ';
	@override String get focusGlow => 'फोकस ग्लो';
	@override String get focusGlowDescription => 'केंद्रित कार्ड के चारों ओर एक नरम चमक डालें';
	@override String get visualEffects => 'दृश्य प्रभाव';
	@override String get visualEffectsAuto => 'ऑटो';
	@override String get visualEffectsAutoDescription => 'कम शक्ति वाले उपकरणों पर स्वचालित रूप से प्रभाव को कम करें';
	@override String get visualEffectsFull => 'पूर्ण';
	@override String get visualEffectsReduced => 'कम करें';
	@override String get visualEffectsReducedDescription => 'कम एनीमेशन और निचले संकल्प कलाकृति';
	@override String get hideSpoilers => 'अनदेखा किए गए एपिसोड के लिए छिपे हुए स्पॉलर';
	@override String get hideSpoilersDescription => 'Blur ट्यूमर और अनदेखा किए गए एपिसोड के लिए विवरण';
	@override String get playerBackend => 'बैकएंड खिलाड़ी';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'हार्डवेयर डिकोडिंग';
	@override String get hardwareDecodingDescription => 'जब उपलब्ध हो तो हार्डवेयर गति का उपयोग करें';
	@override String get playbackBuffer => 'Playback बफर';
	@override String get playbackBufferAuto => 'गाड़ी (अनुशंसित)';
	@override String get playbackBufferLarge => 'बड़ा';
	@override String get playbackBufferExtraLarge => 'अतिरिक्त बड़ा';
	@override String get playbackBufferDescription => 'अस्थिर कनेक्शन के खिलाफ अधिक बफर. बफर आकार द्वारा भी सीमित.';
	@override String get streamBufferSize => 'बफर आकार';
	@override String streamBufferSizeValue({required Object size}) => '${size} एमबी';
	@override String get streamBufferSizeDescription => 'सीधे खेलते समय कितना वीडियो आगे लोड करना है. ट्रांसकोड सर्वर के स्वयं के ट्रांसकोड बफर पर रुकता है. 0 = ऑटो';
	@override String get streamBufferSizeExoNote => 'Playback Buffer को स्थापित करते समय प्रतिस्थापित करता है, एप्लिकेशन की स्मृति सीमा के आधे हिस्से में कवर किया जाता है';
	@override String get streamBufferMegabytes => 'मेगाबाइट्स';
	@override String get defaultQualityTitle => 'डिफ़ॉल्ट गुणवत्ता';
	@override String get cellularQualityTitle => 'सेलुलर में डिफ़ॉल्ट गुणवत्ता';
	@override String get remoteQualityTitle => 'रिमोट स्ट्रीमिंग गुणवत्ता';
	@override String get remoteQualitySameAsDefault => 'डिफ़ॉल्ट गुणवत्ता के रूप में';
	@override String get cellularQualitySameAsDefault => 'डिफ़ॉल्ट गुणवत्ता के रूप में';
	@override String get directPlayCoveredQuality => 'मूल गुणवत्ता में छोटे वीडियो खेलें';
	@override String get directPlayCoveredQualityDescription => 'सीधे वीडियो को पहले से ही गुणवत्ता सीमा के भीतर चलाने के बजाय उन्हें ट्रांसकोड करने के लिए';
	@override String get videoCodecs => 'वीडियो कोडेक';
	@override String get videoCodecsDescription => 'अनदेखा किए गए कोडेक को सर्वर द्वारा ट्रांसकोड किया जाता है';
	@override String get videoCodecsAlwaysAccepted => 'हमेशा स्वीकार';
	@override String get musicQualityTitle => 'संगीत गुणवत्ता';
	@override String get subtitleStyling => 'Subtitle स्टाइलिंग';
	@override String get subtitleStylingDescription => 'Subtitle उपस्थिति के लिए अनुकूलित करें';
	@override String get smallSkipDuration => 'छोटे स्काइप लंबाई';
	@override String get largeSkipDuration => 'लंबी लंबी लंबी लंबी';
	@override String get rewindOnResume => 'पुनः संदर्भ में';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(seconds,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} सेकंड',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} सेकंड',
	);
	@override String get defaultSleepTimer => 'डिफ़ॉल्ट नींद टाइमर';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(minutes,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} मिनट',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} मिनट',
	);
	@override String get rememberTrackSelections => 'शो / फिल्म के लिए ट्रैक चयन याद रखें';
	@override String get chooseTracksBeforePlayback => 'Playback से पहले ऑडियो और उप शीर्षक का चयन करें';
	@override String get chooseTracksBeforePlaybackDescription => 'प्रत्येक वीडियो शुरू होने से पहले स्रोत ऑडियो और उप शीर्षक ट्रैक चुनें।';
	@override String get alwaysShowSubtitlesOnDevice => 'हमेशा इस डिवाइस पर उपनाम दिखाएं';
	@override String get alwaysShowSubtitlesOnDeviceDescription => 'जब सर्वर में कोई उप-टू-टू नहीं है, तो एक ट्रैक को स्थानीय रूप से चुनें. यह कभी भी सर्वर की पसंद को नहीं बदलता है.';
	@override String get autoDownloadPreferredSubtitle => 'फ्लेक्स पसंदीदा-भाषा उपनामों की कमी';
	@override String get autoDownloadPreferredSubtitleDescription => 'अपने पसंदीदा भाषा में एक उपलब्ध उपशीर्षक को स्थानीय रूप से चुनें. यदि कोई मौजूद नहीं है, तो सर्वर से पूछें कि जब समर्थित होता है तो एक को पकड़ लें. चयन इस डिवाइस पर रहता है.';
	@override String get rememberTrackSelectionsDescription => 'इस डिवाइस पर शो या फिल्म के माध्यम से ऑडियो और उपनाम विकल्प संग्रहीत करें';
	@override String get rememberTrackSelectionsBackendRule => 'Plex, Jellyfin, और Emby; Plex और Jellyfin के साथ स्थानीय रूप से काम करते हुए, सर्वर पर चयन भी संग्रहीत कर सकते हैं';
	@override String get followServerTrackSelections => 'सर्वर के प्रति-एपिसोड ट्रैक चयन का उपयोग करें';
	@override String get followServerTrackSelectionsDescription => 'एपिसोड परिवर्तन पर, सर्वर पर चुने गए ऑडियो और उप शीर्षक का उपयोग करें, वर्तमान विकल्प से ऊपर ले जाने के बजाय';
	@override String get resumeMusicOnLaunch => 'संगीत सत्र याद रखें';
	@override String get resumeMusicOnLaunchDescription => 'अंतिम गीत को फिर से खोलें जहां यह बंद हो गया जब एप्लिकेशन शुरू होता है';
	@override String get showChapterMarkersOnTimeline => 'खोज बार पर अध्याय चिह्नों को दिखाएं';
	@override String get showChapterMarkersOnTimelineDescription => 'श्रेणी की सीमाओं पर श्रेणी की सीमाओं पर श्रेणी की सीमाओं पर श्रेणी की सीमाएं';
	@override String get specialsOrdering => 'एपिसोड ऑर्डर में विशेष';
	@override String get specialsOrderingDescription => 'जहां विशेषताओं एक शो के घड़ी के आदेश में खेलते हैं';
	@override String get specialsOrderingServer => 'सर्वर आदेश का पालन करें';
	@override String get specialsOrderingAirDate => 'एयर डेटा के अनुसार अंतराल';
	@override String get specialsOrderingLast => 'नियमित मौसम के बाद';
	@override String get clickVideoTogglesPlayback => 'वीडियो पर क्लिक करें ताकि आप खेल सकें / आराम करें';
	@override String get clickVideoTogglesPlaybackDescription => 'वीडियो पर क्लिक करें और नियंत्रण प्रदर्शित करने के बजाय खेलने / रुकने के लिए।';
	@override String get videoPlayerControls => 'वीडियो प्लेयर नियंत्रण';
	@override String get keyboardShortcuts => 'कुंजीपटल Shortcuts';
	@override String get keyboardShortcutsDescription => 'Keyboard Shortcuts के लिए कस्टम करें';
	@override String get videoPlayerNavigation => 'वीडियो प्लेयर नेविगेशन';
	@override String get videoPlayerNavigationDescription => 'वीडियो प्लेयर नियंत्रण का उपयोग करने के लिए चाकू कुंजी का उपयोग करें';
	@override String get watchTogetherRelay => 'एक साथ रिलीज देखें';
	@override String get watchTogetherRelayDescription => 'सार्वजनिक ओपन वॉच पार्टी रिलीज है, जब तक कि आप अपने स्वयं के सेट नहीं';
	@override String get watchTogetherRelayHint => 'https://my-relay.example.com';
	@override String get watchTogetherRelayInvalid => 'रिले का मान्य HTTP या HTTPS बेस URL दर्ज करें।';
	@override String get crashReporting => 'दुर्घटना रिपोर्टिंग';
	@override String get crashReportingDescription => 'एप्लिकेशन को बेहतर बनाने में मदद करने के लिए दुर्घटना रिपोर्ट भेजें';
	@override String get debugLogging => 'डेब्यू लॉगिंग';
	@override String get debugLoggingDescription => 'समस्या हल करने के लिए विस्तृत लॉगिंग की अनुमति दें';
	@override String get viewLogs => 'लॉग देखें';
	@override String get viewLogsDescription => 'आवेदन लॉग देखें';
	@override String get clearImageCache => 'स्पष्ट छवि कैश';
	@override String get clearImageCacheDescription => 'स्पष्ट कचरे वाले कलाकृतियों और छोटे-छोटे चित्रों को फिर से डाउनलोड होने तक धीरे-धीरे लोड किया जा सकता है।';
	@override String get clearImageCacheSuccess => 'Image cache को सफलतापूर्वक हटा दिया गया';
	@override String get resetSettings => 'सेटिंग्स पुन:';
	@override String get resetSettingsDescription => 'डिफ़ॉल्ट सेटिंग्स को पुनर्स्थापित करें. यह अनदेखा नहीं किया जा सकता है.';
	@override String get resetSettingsSuccess => 'सेटिंग्स सफलतापूर्वक पुनर्स्थापित करें';
	@override String get backup => 'बैकअप';
	@override String get exportSettings => 'निर्यात सेटिंग्स';
	@override String get exportSettingsDescription => 'फ़ाइल के लिए अपनी प्राथमिकताओं को सहेजें';
	@override String get exportSettingsSuccess => 'सेटअप निर्यात';
	@override String get importSettings => 'आयात सेटिंग्स';
	@override String get importSettingsDescription => 'फ़ाइल से प्राथमिकताओं को पुनर्स्थापित करें';
	@override String get importSettingsConfirm => 'यह आपके वर्तमान सेटिंग्स को प्रतिस्थापित करेगा. आगे?';
	@override String get importSettingsSuccess => 'आयातित सेटिंग्स';
	@override String get importSettingsInvalidFile => 'यह फ़ाइल एक वैध PlezyNG सेटिंग्स निर्यात नहीं है';
	@override String get importSettingsNoUser => 'आयात से पहले इनपुट करें';
	@override String get cloudBackup => 'क्लाउड बैकअप';
	@override String get cloudBackupDescription => 'स्थानांतरित की जा सकने वाली सेटिंग्स का HTTPS के ज़रिए WebDAV पते पर बैकअप लें। सर्वर कनेक्शन और साइन-इन जानकारी इसी डिवाइस पर रहती है।';
	@override String get cloudBackupUrl => 'WebDAV JSON फ़ाइल URL';
	@override String get cloudBackupUsername => 'उपयोगकर्ता नाम';
	@override String get cloudBackupPassword => 'पासवर्ड';
	@override String get cloudBackupSaved => 'क्लाउड बैकअप डिज़ाइन बचाया';
	@override String get cloudBackupNow => 'अब वापस';
	@override String get cloudBackupComplete => 'Settings Backup अपलोड करें';
	@override String get cloudBackupRestore => 'बैकअप पुनर्स्थापित करें';
	@override String get cloudBackupRestoreConfirm => 'यह इस डिवाइस पर फिट पोर्टेबल सेटिंग्स को प्रतिस्थापित करेगा. आगे?';
	@override String get cloudBackupRestored => 'Cloud Backup से पुनर्स्थापित सेटिंग्स';
	@override String get shortcutsReset => 'डिफ़ॉल्ट में पुनर्स्थापित करें';
	@override String get resetShortcutsConfirm => 'यह आपके कस्टम छूट को डिफ़ॉल्ट के साथ प्रतिस्थापित करेगा. आगे?';
	@override String get about => 'के बारे';
	@override String get aboutDescription => 'एप्लिकेशन और लाइसेंस';
	@override String get updates => 'अद्यतन';
	@override String get updateAvailable => 'अपडेट उपलब्ध';
	@override String get checkForUpdates => 'Updates के लिए जांच करें';
	@override String get autoCheckUpdatesOnStartup => 'स्टार्टअप पर अपडेट के लिए स्वचालित रूप से जांच करें';
	@override String get autoCheckUpdatesOnStartupDescription => 'जब एक अद्यतन लॉन्च के लिए उपलब्ध है सूचना';
	@override String get validationErrorEnterNumber => 'कृपया एक वैध संख्या दर्ज करें';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => '${min} और ${max} ${unit} के बीच होना चाहिए';
	@override String shortcutAlreadyAssigned({required Object action}) => 'कटौती पहले से ही ${action} को सौंपा गया है';
	@override String shortcutUpdated({required Object action}) => 'संक्षिप्त अद्यतन के लिए ${action}';
	@override String get saveFailed => 'कोई बदलाव नहीं किया जा सकता. फिर से कोशिश करें.';
	@override String get autoPlayAndSkip => 'ऑटो-प्ले और स्काइप';
	@override String get autoPlayNextEpisode => 'अगला लेखअगला खेल';
	@override String get autoPlayNextEpisodeDescription => 'अगले एपिसोड को स्वचालित रूप से शुरू करें जब एक समाप्त हो जाता है';
	@override String get shuffleStartsFromBeginning => 'शुरुआत में शूफल शुरू होता है';
	@override String get shuffleStartsFromBeginningDescription => 'प्रत्येक एपिसोड को शुरू करने के बजाय शुरुआत में जब शॉफिंग';
	@override String get plexCinemaPreRoll => 'सर्वर फिल्म इंटीरियर का उपयोग करें';
	@override String get plexCinemaPreRollDescription => 'एक फिल्म शुरू होने से पहले Plex प्री-रॉल्स या Jellyfin और Emby इनपुट को कॉन्फ़िगर करें।';
	@override String get playNextCountdown => 'अगला लेखअगला गिनती';
	@override String get playNextCountdownImmediate => 'तुरंत खेलें';
	@override String get skipIntroMode => 'स्काइप इनट्रू';
	@override String get skipIntroModeOffDescription => 'एक स्काइप बटन के बिना सामान्य रूप से इन्रो खेलते हैं';
	@override String get skipIntroModeButtonDescription => 'एक स्काइप बटन दिखाएं जब एक इनपुट शुरू होता है';
	@override String get skipIntroModeAutoDescription => 'नीचे दिए गए देरी के बाद स्वचालित रूप से इनपुट स्काइप करें';
	@override String get skipCreditsMode => 'क्रेडिट स्केप';
	@override String get skipCreditsModeOffDescription => 'स्काइप बटन के बिना सामान्य रूप से क्रेडिट खेलते हैं';
	@override String get skipCreditsModeButtonDescription => 'क्रेडिट शुरू होने पर स्काइप बटन दिखाएं';
	@override String get skipCreditsModeAutoDescription => 'स्वचालित रूप से क्रेडिट स्काइप करें और अगले एपिसोड को खेलें';
	@override String get skipAdsMode => 'स्काइप विज्ञापन';
	@override String get skipAdsModeOffDescription => 'स्काइप बटन के बिना सामान्य रूप से पता लगाए गए विज्ञापन खेलें';
	@override String get skipAdsModeButtonDescription => 'एक स्काइप बटन दिखाएं जब Plex एक विज्ञापन का पता लगाता है';
	@override String get skipAdsModeAutoDescription => 'नीचे दिए गए देरी के बाद स्वचालित रूप से पता लगाए गए विज्ञापनों को हटा दें';
	@override String get musicPlayback => 'संगीत Playback';
	@override String get musicSweetFades => 'मिठाई फूड';
	@override String get musicSweetFadesDescription => 'ट्रैक किनारों पर फ़ैड संगीत जब Plex में शोर डेटा है. एल्बम प्लेबैक अपरिवर्तित रहता है.';
	@override String get skipMarkerModeOff => 'बंद करें';
	@override String get skipMarkerModeButton => 'बटन दिखाएं';
	@override String get skipMarkerModeAuto => 'स्वचालित';
	@override String get forceSkipMarkerFallback => 'फोर्स फेलबैक मार्कर';
	@override String get forceSkipMarkerFallbackDescription => 'अध्याय शीर्षक पैटर्न का उपयोग करें, भले ही Plex में मार्कर हों';
	@override String get theIntroDbFallback => 'एक intro fallback के रूप में TheIntroDB का उपयोग करें';
	@override String get theIntroDbFallbackDescription => 'सामुदायिक समय का उपयोग केवल तब करें जब सर्वर में कोई इनपुट मार्कर नहीं है. मैच रिलीज के आधार पर भिन्न हो सकते हैं.';
	@override String get autoSkipDelay => 'स्काइप देरी';
	@override String autoSkipDelayDescription({required Object seconds}) => '${seconds} सेकंड से पहले इंतजार करें';
	@override String get introPattern => 'मार्कर पैटर्न';
	@override String get introPatternDescription => 'Regex पैटर्न अध्याय शीर्षकों में intro markers के अनुरूप करने के लिए';
	@override String get creditsPattern => 'क्रेडिट मार्कर पैटर्न';
	@override String get creditsPatternDescription => 'Regex पैटर्न अध्याय शीर्षकों में क्रेडिट मार्करों को मिलाने के लिए';
	@override String get prerolls => 'प्रेरॉल्स';
	@override String get playPrerollsBeforeMovies => 'फिल्मों से पहले प्रेरॉल्स खेलना';
	@override String get playPrerollsBeforeMoviesDescription => 'प्रत्येक फिल्म से पहले नीचे दिए गए चयन से एक यादृच्छिक क्लिप खेलें. स्काइप करने के लिए वापस दबाएं.';
	@override String get prerollLibrary => 'प्रेरोल लाइब्रेरी';
	@override String get prerollLibraryNotSet => 'सेट नहीं';
	@override String get prerollLibraryNoneFound => 'आपके सर्वर पर कोई पुस्तकालय नहीं पाया गया है।';
	@override String get prerollSelection => 'चुने हुए प्रीमियम';
	@override String get prerollSelectionPickLibraryFirst => 'पहले एक पुस्तकालय चुनें';
	@override String get prerollSelectionNoneSelected => 'नहीं चुने गए प्रीमियम';
	@override String prerollSelectionCount({required Object count}) => '${count} चुने गए';
	@override String get prerollItemPicker => 'चुनें प्रीमियम';
	@override String get prerollItemPickerLoadFailed => 'मैं इस पुस्तकालय से वस्तुओं को लोड नहीं कर सकता था।';
	@override String get invalidRegex => 'नियमित अभिव्यक्ति की कमी';
	@override String get regex => 'नियमित अभिव्यक्ति';
	@override String get downloads => 'डाउनलोड';
	@override String get downloadLocationDescription => 'जहां डाउनलोड किए गए सामग्री को संग्रहीत करने के लिए चुनें';
	@override String get downloadLocationDefault => 'डिफ़ॉल्ट (App Storage)';
	@override String get downloadLocationCustom => 'कस्टम स्थान';
	@override String get selectFolder => 'फ़ोल्डर चुनें';
	@override String get resetToDefault => 'डिफ़ॉल्ट में पुनरारंभ';
	@override String currentPath({required Object path}) => 'वर्तमान में: ${path}';
	@override String get downloadLocationChanged => 'डाउनलोड स्थान बदल गया';
	@override String get downloadLocationReset => 'डाउनलोड करें स्थान reset to default';
	@override String get downloadLocationInvalid => 'चयनित फ़ोल्डर लिखने योग्य नहीं है';
	@override String get downloadLocationPickerUnavailable => 'फ़ोल्डर चयन इस डिवाइस पर उपलब्ध नहीं है';
	@override String get downloadOnWifiOnly => 'केवल Wi-Fi पर डाउनलोड करें';
	@override String get downloadOnWifiOnlyDescription => 'मोबाइल डेटा पर डाउनलोड करने से रोकें';
	@override String get autoRemoveWatchedDownloads => 'Auto-Remove देखने वाले डाउनलोड';
	@override String get autoRemoveWatchedDownloadsDescription => 'स्वचालित रूप से देखे गए डाउनलोड को हटा दें';
	@override String get autoDownloadContinueWatching => 'Auto-Download जारी रखें';
	@override String get autoDownloadContinueWatchingDescription => 'अपने निरंतर देखे जाने वाले ढाल पर आइटम डाउनलोड करें, और उन्हें हटा दें जब वे ढाल छोड़ देते हैं';
	@override String get downloadQuality => 'डाउनलोड गुणवत्ता';
	@override String get downloadQualityDescription => 'Plex अपने डाउनलोड क्वाउड में एक परिवर्तित प्रति तैयार करता है. Jellyfin और Emby ट्रांसकोड जब फ़ाइल डाउनलोड करता है; टूटे हुए ट्रांसफर को पुनरारंभ करने की आवश्यकता हो सकती है.';
	@override String get askDownloadQualityEachTime => 'प्रत्येक डाउनलोड के लिए गुणवत्ता का चयन करें';
	@override String get askDownloadQualityEachTimeDescription => 'प्रत्येक वीडियो डाउनलोड करने से पहले गुणवत्ता पिकर दिखाएं';
	@override String get cellularDownloadBlocked => 'डाउनलोड सेल पर ब्लॉक किए जाते हैं. Wi-Fi का उपयोग करें या सेटिंग्स को बदल दें.';
	@override String get maxVolume => 'अधिकतम वॉल्यूम';
	@override String get maxVolumeDescription => 'कम आवाज़ वाले मीडिया के लिए वॉल्यूम 100% से अधिक बढ़ाने दें';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'अमीर उपस्थिति';
	@override String get discordRichPresenceDescription => 'दिखाएं कि आप Discord पर क्या देख रहे हैं';
	@override String get services => 'सेवाएं';
	@override String get servicesDescription => 'कनेक्ट करें Trakt, MyAnimeList, Seerr, और अधिक';
	@override String get manageLibrariesDescription => 'पुस्तकालयों को रिकॉर्ड और छिपाना';
	@override String get companionRemoteServer => 'रिमोट सर्वर';
	@override String get companionRemoteServerDescription => 'अपने नेटवर्क पर मोबाइल उपकरणों को इस ऐप को नियंत्रित करने की अनुमति दें';
	@override String get companionRemoteServerStartFailed => 'साथी सर्वर शुरू नहीं किया जा सकता';
	@override String get companionRemoteServerStopFailed => 'साथी सर्वर को रोक नहीं पाया';
	@override String get autoPip => 'Auto Picture-in-Picture के बारे में टिप्पणियाँ';
	@override String get autoPipDescription => 'स्वचालित रूप से छवि-इन-चित्र दर्ज करें जब आप प्लेबैक के दौरान ऐप छोड़ देते हैं';
	@override String get matchContentFrameRate => 'मैच सामग्री फ्रेम दर';
	@override String get matchContentFrameRateDescription => 'मैच डिस्प्ले वीडियो सामग्री के लिए ताज़ा दर';
	@override String get matchContentResolution => 'मैच सामग्री संकल्प';
	@override String get matchContentResolutionDescription => 'डिस्प्ले को वीडियो के मूल रिज़ॉल्यूशन में स्विच करें ताकि आपका टीवी उस्स्केल हो. मेनू और उपनाम भी प्लेबैक के दौरान उस्केल हो जाते हैं';
	@override String get matchRefreshRate => 'मैच रिफ्रेश दर';
	@override String get matchRefreshRateDescription => 'मैच डिस्प्ले पूर्ण स्क्रीन में ताज़ा दर';
	@override String get matchDynamicRange => 'खेल गतिशील सीमा';
	@override String get matchDynamicRangeDescription => 'HDR को HDR सामग्री के लिए स्विच करें, फिर SDR पर वापस जाएं';
	@override String get displaySwitchDelay => 'स्विच देरी';
	@override String get tunneledPlayback => 'टनल प्लेबैक';
	@override String get tunneledPlaybackDescription => 'वीडियो टनलिंग का उपयोग करें. यदि HDR प्लेबैक काले वीडियो या मोशन स्टूटर प्रदर्शित करता है तो इसे अक्षम करें.';
	@override String get audioPassthrough => 'ध्वनि के साथ';
	@override String get audioPassthroughDescription => 'अपने रिसेप्टर या टीवी को फिर से एन्कोडिंग के बिना Dolby/DTS ऑडियो भेजें, आसपास के ध्वनि को बनाए रखें. यदि आपके पास कोई ध्वनि नहीं है तो बंद करें.';
	@override String get audioPassthroughDescriptionApple => 'Dolby Digital Plus के लिए मूल Dolby decoder Apple का उपयोग करें, जिसमें Atmos भी शामिल है. DTS और TrueHD अभी भी मल्टीचैनल पीसीएम के रूप में खेलते हैं. यदि आपके पास कोई ध्वनि नहीं है तो बंद करें.';
	@override String get audioPassthroughDescriptionAppleSpatial => 'डोलबी डिजिटल प्लस के लिए Apple के मूल डोलबी डिकोडर का उपयोग करें, जिसमें Atmos शामिल है. iOS, iPadOS और tvOS 26 या बाद में, TrueHD Atmos और DTS:X को अंतरिक्ष ऑडियो के रूप में खेला जाता है. अन्य DTS और TrueHD ट्रैक को मल्टीचैनल पीसीएम के रूप में खेला जाता है. बंद करें यदि आपके पास कोई ध्वनि नहीं है.';
	@override String get audioPassthroughOverriddenByNormalization => 'जबकि ध्वनि सामान्यीकरण के लिए बंद हो जाता है';
	@override String get audioChannelLimit => 'ऑडियो चैनल';
	@override String get audioChannelLimitDescription => 'स्पीकर, हेडफोन, या HDMI सेटिंग्स के लिए डिकोड ऑडियो डाउनलोड करें जो किसी भी चैनल को नहीं खेल सकते हैं';
	@override String get audioChannelLimitOriginal => 'मूल';
	@override String get audioChannelLimitOriginalDescription => 'ट्रैक में हर चैनल खेलें';
	@override String get audioChannelLimitSurround51 => '5.1 तक';
	@override String get audioChannelLimitSurround51Description => 'टीवी और रिसीवरों के लिए 7.1 से 5.1 तक मिश्रण करें जो केवल 5.1 पीसीएम लेते हैं।';
	@override String get audioChannelLimitStereo => 'स्टेनलेस';
	@override String get audioChannelLimitStereoDescription => 'स्टेरेओ स्पीकर या हेडफोन के लिए दो चैनलों में मिश्रण करें।';
	@override String get downmixCenterBoost => 'चैनल बूस्ट';
	@override String downmixCenterBoostValue({required Object db}) => '${db} डीबी';
	@override String get downmixCenterBoostLabel => 'बूस्ट ( डीबी)';
	@override String get downmixCenterBoostShort => 'डीबी';
	@override String get audioDownmixNormalize => 'Downmix पर वॉल्यूम को सामान्य करें';
	@override String get audioDownmixNormalizeDescription => 'मिश्रण को नीचे रखें ताकि क्लिपिंग को रोक दिया जा सके. मूल वॉल्यूम को बनाए रखने के लिए बंद करें (मैं जोर से दृश्यों को खराब कर सकता हूं)।';
	@override String get dvConversionMode => 'Dolby Vision परिवर्तित';
	@override String get dvConversionModeDescription => 'कैसे Dolby Vision प्रोफ़ाइल 7 फ़ाइलों को संभालने के लिए चुनें।';
	@override String get dvConversionAuto => 'ऑटो';
	@override String get dvConversionNative => 'Home / विकलांग';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'उपकरण क्षमता का पता लगाने और सामान्य Fallback व्यवहार का उपयोग करें';
	@override String get dvConversionNativeDescription => 'शक्ति मूल DV7 और डीवी रूपांतरण रिट्री को दबाने';
	@override String get dvConversionDv81Description => 'ताकत इनलाइन आरपीयू रूपांतरण Dolby Vision प्रोफ़ाइल 8.1';
	@override String get dvConversionHevcStripDescription => 'स्ट्रिप Dolby Vision आरपीयू / ईएल परतों और वर्तमान प्लेन HEVC';
	@override String get disableDolbyVision => 'अक्षम Dolby Vision';
	@override String get disableDolbyVisionDescription => 'फ़ाइल के HDR10 या HLG परत को Dolby Vision के बजाय खेलें, जब इसमें एक';
	@override String get hdrSdrConversion => 'HDR से SDR के लिए रूपांतरण';
	@override String get hdrSdrConversionDescription => 'चुनें कि HDR वीडियो को क्या रूपांतरित करता है जब डिस्प्ले HDR नहीं दिखा सकता है।';
	@override String get hdrSdrConversionAuto => 'ऑटो';
	@override String get hdrSdrConversionAutoDescription => 'डिवाइस पर Android 9 और बाद में, पुराने संस्करणों पर प्लेयर';
	@override String get hdrSdrConversionDevice => 'डिवाइस';
	@override String get hdrSdrConversionDeviceDescription => 'आपके डिवाइस का वीडियो हार्डवेयर इसे परिवर्तित करता है सबसे तेज़, लेकिन रंग डिवाइस पर निर्भर करता है';
	@override String get hdrSdrConversionPlayer => 'प्लेयर';
	@override String get hdrSdrConversionPlayerDescription => 'खिलाड़ी इसे परिवर्तित करता है. स्थिर रंग, लेकिन 4K कम अंत टीवी बॉक्स पर टूट सकता है';
	@override String get deinterlace => 'इंटरलेशन';
	@override String get deinterlaceDescription => 'इंटरलाइड वीडियो से कम्बिंग आइटम हटाएं (mpv खिलाड़ी केवल)';
	@override String get deinterlaceOff => 'बंद करें';
	@override String get deinterlaceOffDescription => 'इंटरलाइड वीडियो दिखाएं क्योंकि यह डिकोडिंग किया गया है';
	@override String get deinterlaceVideo => 'वीडियो';
	@override String get deinterlaceVideoDescription => 'टीवी के लिए वीडियो शॉट के लिए, जैसे खेल, समाचार, और संगीत समारोह';
	@override String get deinterlaceFilm => 'फिल्में';
	@override String get deinterlaceFilmDescription => 'फ़िल्म और एनीमेशन के मूल फ्रेम को पुनर्स्थापित करें, जो 29.97 एफपीएस तक टेलीसेन किया गया है, जो एनटीएससी डीवीडी पर आम है. टीवी स्टूटर के लिए वीडियो शॉट. लाइव टीवी का उपयोग वीडियो';
	@override String get requireProfileSelectionOnOpen => 'ऐप ओपन पर प्रोफ़ाइल पूछें';
	@override String get requireProfileSelectionOnOpenDescription => 'प्रोफ़ाइल चयन हर बार प्रदर्शित करें जब ऐप खुलता है';
	@override String get forceTvMode => 'टीवी मोड';
	@override String get forceTvModeDescription => 'मजबूत टीवी लेआउट. उपकरणों के लिए जो स्वचालित रूप से नहीं पता चलता. पुनरारंभ की आवश्यकता होती है.';
	@override String get startInFullscreen => 'पूर्ण स्क्रीन से शुरू करें';
	@override String get startInFullscreenDescription => 'लॉन्च पर पूर्ण स्क्रीन मोड में ओपन PlezyNG';
	@override String get exitFullscreenOnPlayerClose => 'बाहर निकलने के लिए पूर्ण स्क्रीन पर खिलाड़ी बंद';
	@override String get exitFullscreenOnPlayerCloseDescription => 'वीडियो प्लेयर को बंद करते समय स्वचालित रूप से पूर्ण स्क्रीन से बाहर निकलता है';
	@override String get autoHidePerformanceOverlay => 'ऑटो-हाइड प्रदर्शन ओवरले';
	@override String get autoHidePerformanceOverlayDescription => 'Playback नियंत्रण के साथ प्रदर्शन को कम करें';
	@override String get showNavBarLabels => 'दिखाएँ Navigation Bar Labels';
	@override String get showNavBarLabelsDescription => 'Navigation Bar Icon के तहत पाठ लेबल प्रदर्शित करें';
	@override String get startupSection => 'स्टार्टअप सेक्शन';
	@override String get preferredServer => 'पसंद सर्वर';
	@override String get preferredServerDescription => 'इस सर्वर के परिणामों को प्राथमिकता दें, जबकि प्रत्येक कनेक्ट सर्वर उपलब्ध रखें।';
	@override String get preferredServerAutomatic => 'स्वचालित';
	@override String get showExploreTab => 'टैब का पता लगाएं';
	@override String get showExploreTabDescription => 'Plex खोज और जुड़े ट्रैकर से सामग्री के साथ खोज टैब दिखाएं';
	@override String get hideEmptyLibraries => 'खाली पुस्तकालयों को छिपाना';
	@override String get hideEmptyLibrariesDescription => 'सर्वर द्वारा रिपोर्ट किए गए आइटम की संख्या के साथ पुस्तकालयों को नवाचार से शून्य से हटा दें।';
	@override String get liveTvDefaultFavorites => 'पसंदीदा चैनलों के लिए डिफ़ॉल्ट';
	@override String get liveTvDefaultFavoritesDescription => 'लाइव टीवी खोलने पर केवल पसंदीदा चैनलों को प्रदर्शित करें';
	@override String get general => 'सामान्य';
	@override String get generalDescription => 'भाषा, स्टार्टअप, और खिड़की व्यवहार';
	@override String get languageAndRegion => 'भाषा और क्षेत्र';
	@override String get startup => 'स्टार्टअप';
	@override String get display => 'प्रदर्शन';
	@override String get libraryAndCards => 'पुस्तकालय और कार्ड';
	@override String get homeScreen => 'Home स्क्रीन';
	@override String get navigation => 'नाविगेशन';
	@override String get window => 'खिड़की';
	@override String get liveTv => 'लाइव टीवी';
	@override String get player => 'प्लेयर';
	@override String get videoAndDisplay => 'वीडियो और डिस्प्ले';
	@override String get audio => 'ऑडियो';
	@override String get quality => 'गुणवत्ता';
	@override String get subtitles => 'उपशीर्षक';
	@override String get seekAndTiming => 'खोज और समय';
	@override String get behavior => 'व्यवहार';
	@override String get gestures => 'गेंदबाजी';
	@override String get gestureBrightnessSwipe => 'चमक स्विप';
	@override String get gestureBrightnessSwipeDescription => 'चमक को समायोजित करने के लिए बाएं किनारे पर ऊपर या नीचे स्विच करें';
	@override String get gestureVolumeSwipe => 'वॉल्यूम स्विप';
	@override String get gestureVolumeSwipeDescription => 'वॉल्यूम को समायोजित करने के लिए दाईं ओर ऊपर या नीचे स्विच करें';
	@override String get gesturePinchToZoom => 'ज़ूम के लिए पिंच';
	@override String get gesturePinchToZoomDescription => 'वीडियो में ज़ूम करने के लिए स्क्रॉल करें और ज़ूम करें';
	@override String get gestureSeekSwipe => 'स्विप खोजें';
	@override String get gestureSeekSwipeDescription => 'वीडियो में कहीं भी खोजने के लिए बाईं ओर या दाईं ओर स्विच करें; कूदने के लिए रिलीज करें';
	@override String get rememberBrightnessLevel => 'चमक के स्तर को याद रखें';
	@override String get rememberBrightnessLevelDescription => 'अंतिम स्विप द्वारा निर्धारित चमक पर प्लेबैक शुरू करें';
	@override String get controls => 'नियंत्रण';
	@override String get rememberPlayerChanges => 'खिलाड़ियों में बदलाव याद रखें';
	@override String get rememberPlayerChangesDescription => 'जहां प्लेबैक के दौरान किए गए परिवर्तन को बचाया जाता है और फिर से लागू किया जाता है';
	@override String get scopePlaybackSpeed => 'Playback गति';
	@override String get scopeShaderPreset => 'शेर प्रीसेट';
	@override String get scopeAspectRatio => 'आस्पेक्ट अनुपात';
	@override String get scopeSyncOffsets => 'Audio & Subtitle सिंक्रनाइज़ेशन';
	@override String get playerScopeOff => 'बचाओ नहीं';
	@override String get playerScopeGlobal => 'हर जगह';
	@override String get playerScopeLibrary => 'पुस्तकालय के लिए';
	@override String get playerScopeTitle => 'शो या फिल्म के लिए';
	@override String get exportDialogTitle => 'निर्यात PlezyNG सेटिंग्स';
	@override String get followSystem => 'सिस्टम की भाषा अपनाएँ';
	@override String get followAppLanguage => 'इंटरफ़ेस की भाषा अपनाएँ';
	@override String get regionFormat => 'क्षेत्रीय प्रारूप';
	@override String get regionFormatDescription => 'तारीखें, संख्याएँ और माप दिखाने का तरीका चुनें।';
	@override String get metadataLanguage => 'मीडिया विवरण की भाषा';
	@override String get metadataLanguageDescription => 'सर्वर के समर्थन के अनुसार शीर्षकों और विवरणों की पसंदीदा भाषा। ऑडियो और उपशीर्षक की प्राथमिकताएँ अलग रहती हैं।';
}

// Path: themeEditor
class _Translations$themeEditor$hi extends Translations$themeEditor$en {
	_Translations$themeEditor$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get builtIn => 'इमारत में';
	@override String get presets => 'उपन्यास';
	@override String get custom => 'कस्टम';
	@override String get customEmpty => 'अभी तक नहीं बनाया';
	@override String get editCustom => 'संपादित करें Custom theme';
	@override String get editCustomDescription => 'हर रंग को स्वयं चुनें';
	@override String get locked => 'जीवन के लिए आवश्यक पहुंच';
	@override String get savedLocked => 'बचाया - जीवन भर के लिए उपलब्ध है';
	@override String get title => 'कस्टम विषय';
	@override String get startFrom => 'से शुरू करें';
	@override String get startFromDescription => 'किसी अन्य विषय से सभी रंगों को कॉपी करें';
	@override String get colors => 'रंगों';
	@override String get preview => 'पूर्वावलोकन';
	@override late final _Translations$themeEditor$slots$hi slots = _Translations$themeEditor$slots$hi._(_root);
	@override String get opacity => 'अस्थिरता';
	@override String get hexHint => '#RRGGBB या #AARRGGBB';
	@override String get fromOtherThemes => 'अन्य विषयों से';
	@override String swatchLabel({required Object theme, required Object color}) => '${theme} ${color}';
	@override late final _Translations$themeEditor$contrast$hi contrast = _Translations$themeEditor$contrast$hi._(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, अनुशंसित ${minimum}:1 के नीचे';
	@override String get discardTitle => 'बदलावों को नजरअंदाज?';
	@override String get discardMessage => 'रंगों में किए गए ऐसे बदलाव खो जाएँगे जिन्हें आपने सहेजा नहीं है।';
	@override String get discard => 'डिस्काउंट';
	@override String previewCardTitle({required Object number}) => 'पदों की संख्या ${number}';
	@override String previewCardSubtitle({required Object minutes}) => '${minutes} मिनट छोड़ दिया';
	@override String get previewSwitch => 'Autoplay के लिए';
	@override String get previewMutedText => 'दूसरा पाठ इस तरह पढ़ता है';
}

// Path: search
class _Translations$search$hi extends Translations$search$en {
	_Translations$search$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get hint => 'फिल्मों, शो, संगीत की खोज';
	@override String get tryDifferentTerm => 'एक अलग खोज अवधि की कोशिश करें';
	@override String get searchYourMedia => 'अपने मीडिया की तलाश';
	@override String get enterTitleActorOrKeyword => 'एक शीर्षक, अभिनेता, या कुंजी शब्द दर्ज करें';
	@override String get people => 'लोग';
}

// Path: hotkeys
class _Translations$hotkeys$hi extends Translations$hotkeys$en {
	_Translations$hotkeys$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'सेट Shortcut के लिए ${actionName}';
	@override String get clearShortcut => 'स्पष्ट कटौती';
	@override String get noShortcutSet => 'कोई छोटी सी सीट नहीं';
	@override String get currentShortcut => 'वर्तमान संक्षिप्त:';
	@override String get pressToRecord => 'एक संक्षिप्त रिकॉर्ड करने के लिए चुनें';
	@override String get recordingShortcut => 'अब कटौती दबाएं';
	@override late final _Translations$hotkeys$actions$hi actions = _Translations$hotkeys$actions$hi._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$hi extends Translations$fileInfo$en {
	_Translations$fileInfo$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'फ़ाइल जानकारी';
	@override String get overview => 'समीक्षा';
	@override String get video => 'वीडियो';
	@override String get audio => 'ऑडियो';
	@override String get subtitles => 'उपशीर्षक';
	@override String get images => 'अंतर्निहित तस्वीरें';
	@override String get dataStreams => 'डेटा स्ट्रीम';
	@override String get lyrics => 'लिंग';
	@override String get file => 'फ़ाइल';
	@override String get attachments => 'अनुलग्नक';
	@override String get delivery => 'वितरण';
	@override String versionCounter({required Object index, required Object count}) => 'संस्करण ${index} से ${count}';
	@override String fileCounter({required Object index, required Object count}) => 'फ़ाइल ${index} से ${count}';
	@override String get noStreams => 'सर्वर ने इस फ़ाइल के लिए कोई स्ट्रीम नहीं बताया।';
	@override String get copyPath => 'रास्ता कॉपी करें';
	@override String get pathCopied => 'फ़ाइल मार्ग कॉपी';
	@override String get codec => 'कोडेक';
	@override String get codecTag => 'कोडेक टैग';
	@override String get resolution => 'संकल्प';
	@override String get codedResolution => 'कोड संकल्प';
	@override String get bitrate => 'बिटकॉइन';
	@override String get frameRate => 'फ्रेम दर';
	@override String get rotation => 'रोटेशन';
	@override String get comment => 'कैसे';
	@override String get audioDescription => 'ऑडियो विवरण';
	@override String get headerCompression => 'शीर्षक संपीड़न';
	@override String get sidecarFile => 'फ़ाइल सिडम';
	@override String get transportTimestamp => 'परिवहन टाइम्स';
	@override String get displayOffset => 'डिस्प्ले ऑफसेट';
	@override String get previewFailureCode => 'असफलता कोड';
	@override String get previewRetries => 'रिट्री से पहले';
	@override String get aspectRatio => 'आस्पेक्ट अनुपात';
	@override String get pixelAspectRatio => 'Pixel Aspect अनुपात';
	@override String get profile => 'प्रोफ़ाइल';
	@override String get level => 'स्तर';
	@override String get bitDepth => 'थोड़ा गहरा';
	@override String get pixelFormat => 'पिक्सेल प्रारूप';
	@override String get colorSpace => 'रंग स्थान';
	@override String get colorRange => 'रंग रेंज';
	@override String get colorPrimaries => 'कलर प्राइमरी';
	@override String get colorTransfer => 'रंग स्थानांतरण';
	@override String get chromaSubsampling => 'क्रोम Subsampling';
	@override String get chromaLocation => 'क्रॉम स्थान';
	@override String get scanType => 'स्कैनिंग प्रकार';
	@override String get interlaced => 'इंटरलेशन';
	@override String get anamorphic => 'एनामोरिक';
	@override String get referenceFrames => 'संदर्भ फ्रेम';
	@override String get dynamicRange => 'गतिशील सीमा';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Dolby Vision स्तर';
	@override String get dolbyVisionVersion => 'Dolby Vision संस्करण';
	@override String get dolbyVisionLayers => 'Dolby Vision स्लाइड्स';
	@override String get baseLayerCompatibility => 'आधार परत संगतता';
	@override String get avcBitstream => 'AVC बिटस्ट्रीम';
	@override String get nalLengthSize => 'लंबाई का आकार';
	@override String get scalingMatrix => 'स्केलिंग मैट्रिक्स';
	@override String get streamIdentifier => 'स्ट्रीम पहचानकर्ता';
	@override String get streamIndex => 'स्ट्रीम इंडेक्स';
	@override String get streamId => 'स्ट्रीम आईडी';
	@override String get language => 'भाषा';
	@override String get languageCode => 'भाषा कोड';
	@override String get streamTitle => 'ट्रैक शीर्षक';
	@override String get channels => 'चैनल';
	@override String get sampleRate => 'नमूना दर';
	@override String get spatialAudio => 'अंतरिक्ष ऑडियो';
	@override String get textBased => 'पाठ आधारित';
	@override String get subtitleFormat => 'साइडर फॉर्मेट';
	@override String get provider => 'प्रदाता';
	@override String get matchScore => 'मैच स्कोर';
	@override String get externalDelivery => 'अलग से सेवा की जा सकती है';
	@override String get sidecarPath => 'साइडर रास्ता';
	@override String get sourceStream => 'कॉपी से';
	@override String get temporary => 'अस्थायी';
	@override String get timeBase => 'समय आधार';
	@override String get overallBitrate => 'कुल बिटरेट';
	@override String get path => 'रास्ते';
	@override String get fileName => 'फ़ाइल नाम';
	@override String get size => 'आकार';
	@override String get totalSize => 'कुल आकार';
	@override String get container => 'कंटेनर';
	@override String get duration => 'लंबाई';
	@override String get previewThumbnails => 'उपन्यास ट्यूबनाइल';
	@override String get previewIndex => 'पूर्वावलोकन इंडेक्स';
	@override String get packetLength => 'पैकेज लंबाई';
	@override String get filePresent => 'फ़ाइल वर्तमान';
	@override String get fileReadable => 'सर्वर से पढ़ा जा सकता है';
	@override String get streamPath => 'प्रवाह मार्ग';
	@override String get optimizedForStreaming => 'Streaming के लिए अनुकूलित';
	@override String get has64bitOffsets => '64-बिट ऑफ़सेट';
	@override String get protocol => 'प्रोटोकॉल';
	@override String get mediaType => 'मीडिया प्रकार';
	@override String get sourceKind => 'स्रोत के प्रकार';
	@override String get optimizedVersion => 'अनुकूलित संस्करण';
	@override String get optimizationTarget => 'लक्ष्य अनुकूलन';
	@override String get deletedAt => 'हटाए गए';
	@override String get remoteSource => 'दूरस्थ स्रोत';
	@override String get infiniteStream => 'अंतहीन प्रवाह';
	@override String get directPlay => 'सीधे खेलना';
	@override String get directStream => 'सीधे प्रवाह';
	@override String get transcoding => 'ट्रांसकोडिंग';
	@override String get etag => 'ETag';
	@override String get versionId => 'संस्करण ID';
	@override String get fileId => 'फ़ाइल ID';
	@override String get defaultAudioTrack => 'ऑडियो ट्रैक';
	@override String get defaultSubtitleTrack => 'Subtitle ट्रैक';
	@override String get subtitlesOff => 'बंद करें';
	@override String get flagDefault => 'मूल';
	@override String get flagForced => 'मजबूर';
	@override String get flagSelected => 'चुने गए';
	@override String get flagExternal => 'बाहरी';
	@override String get flagHearingImpaired => 'सुनने में असफलता';
	@override String get flagDub => 'डब';
	@override String get flagOriginal => 'मूल';
	@override String get channelsMono => 'मोनो';
	@override String dolbyVisionProfile({required Object profile}) => 'प्रोफ़ाइल ${profile}';
}

// Path: mediaMenu
class _Translations$mediaMenu$hi extends Translations$mediaMenu$en {
	_Translations$mediaMenu$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'मार्क को देखते हुए';
	@override String get markAsUnwatched => 'अनदेखा के रूप में मार्क';
	@override String get removeFromContinueWatching => 'जारी रखने से हटाएँ';
	@override String get viewDetails => 'विवरण देखें';
	@override String get goToSeries => 'सीरीज में जाओ';
	@override String get shufflePlay => 'शूफ खेल';
	@override String get shuffleNotAvailableOffline => 'शूफल ऑफ़लाइन उपलब्ध नहीं है';
	@override String get fileInfo => 'फ़ाइल जानकारी';
	@override String get deleteEpisodeFromServer => 'सर्वर से एपिसोड हटाएं';
	@override String get deleteSeasonFromServer => 'सर्वर से सीजन हटाएं';
	@override String get deleteShowFromServer => 'सर्वर से प्रदर्शित करें';
	@override String get deleteMovieFromServer => 'सर्वर से फ़िल्म हटाएं';
	@override String get deleteEpisodeTitle => 'इस एपिसोड को हटाने के लिए?';
	@override String get deleteSeasonTitle => 'इस सीजन को हटाने के लिए?';
	@override String get deleteShowTitle => 'इस शो को हटा दें?';
	@override String get deleteMovieTitle => 'इस फिल्म को हटा दें?';
	@override String get deleteEpisodeConfirm => 'एपिसोड हटाएँ';
	@override String get deleteSeasonConfirm => 'सीजन हटाने';
	@override String get deleteShowConfirm => 'प्रदर्शनी हटाएँ';
	@override String get deleteMovieConfirm => 'फ़िल्म हटाएँ';
	@override String get deleteAnyway => 'किसी भी तरह से हटाएं';
	@override String confirmDeleteTarget({required Object title}) => 'अपने सर्वर से स्थायी रूप से ${title} को हटा दें?';
	@override String get deleteMultipleWarning => 'इसमें सभी एपिसोड और उनके फ़ाइल शामिल हैं।';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n,
		one: 'इससे इसमें मौजूद ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} एपिसोड और उसकी फ़ाइल मिट जाएँगे।',
		other: 'इससे इसमें मौजूद सभी ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} एपिसोड और उनकी फ़ाइलें मिट जाएँगे।',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n,
		one: 'यह आइटम ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} फ़ाइल में संग्रहीत है और वह फ़ाइल मिट जाएगी।',
		other: 'यह आइटम ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} फ़ाइलों में संग्रहीत है और वे सभी मिट जाएँगी।',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} अन्य एपिसोड उसी फ़ाइल में संग्रहीत है और वह भी मिट जाएगा:',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} अन्य एपिसोड उसी फ़ाइल में संग्रहीत हैं और वे भी मिट जाएँगे:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'PlezyNG यह जांच नहीं कर सकता है कि यह कौन से फ़ाइलों को हटा देगा, इसलिए यह ऊपर नामित आइटम से अधिक हटा सकता है. रद्द करें और फिर से कोशिश करें, या किसी भी तरह से हटा दें.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'आपके सर्वर ने इस आइटम के लिए फ़ाइल विवरण प्रदान नहीं किया है, इसलिए PlezyNG यह जांच नहीं कर सकता है कि यह किस फ़ाइल को हटा देगा. यह ऊपर नामित आइटम से अधिक हटा सकता है.';
	@override String get mediaDeletedSuccessfully => 'मीडिया के आइटम को सफलतापूर्वक हटा दिया गया';
	@override String get mediaFailedToDelete => 'मीडिया आइटम को हटाने में विफलता';
	@override String get rate => 'दरें';
	@override String get playFromBeginning => 'शुरुआत से खेलना';
	@override String get playVersion => 'खेल संस्करण ...';
}

// Path: rateSheet
class _Translations$rateSheet$hi extends Translations$rateSheet$en {
	_Translations$rateSheet$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'दरें';
	@override String get server => 'सर्वर';
	@override String get favorite => 'पसंद';
	@override String get favorited => 'पसंद';
	@override String get saved => 'बचाए गए';
	@override String get notAvailable => 'कोई मैच नहीं मिला';
	@override String get noConnectedServices => 'वहां रेट करने के लिए सेटिंग्स में एक सेवा कनेक्ट करें।';
}

// Path: accessibility
class _Translations$accessibility$hi extends Translations$accessibility$en {
	_Translations$accessibility$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, फिल्में';
	@override String mediaCardShow({required Object title}) => '${title}, टीवी शो';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'देखते हैं';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} प्रतिशत देखा गया';
	@override String get mediaCardUnwatched => 'अनदेखा';
	@override String get tapToPlay => 'खेलने के लिए टैप';
	@override String get decrease => 'कम';
	@override String get increase => 'बढ़ते';
	@override String decreaseValue({required Object label}) => 'गिरावट ${label}';
	@override String increaseValue({required Object label}) => 'बढ़ोतरी ${label}';
	@override String get hue => 'हाई';
	@override String get saturation => 'Saturation में';
	@override String get brightness => 'चमक';
	@override String get hexColor => 'हेक्स रंग';
	@override String get expandText => 'पाठ का विस्तार';
	@override String get collapseText => 'टूटने का पाठ';
	@override String get alphabetNavigation => 'अल्फाबेटिक नाविगेशन';
	@override String get alphabetScrollHint => 'ऊपर या नीचे स्विच करें ताकि पत्र के माध्यम से आगे बढ़ें';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'पंक्ति ${row} से ${rowCount}, स्तंभ ${column} से ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'लाइन ${row} से ${rowCount}';
	@override String get autoScrollPlay => 'Auto-Scroll के बारे में';
	@override String get autoScrollPause => 'स्क्रॉल ऑटो-स्क्रॉल';
	@override String get hueShort => 'H';
	@override String get saturationShort => 'एस';
	@override String get valueShort => 'V में';
	@override String get red => 'लाल';
	@override String get green => 'हरे रंग';
	@override String get blue => 'ब्लू';
	@override String get redShort => 'R';
	@override String get greenShort => 'जी';
	@override String get blueShort => 'बी';
	@override String get colorModeHsv => 'HSV';
	@override String get colorModeRgb => 'आरजीबी';
	@override String get title => 'पहुंच';
	@override String get summary => 'पाठ, विपरीत, आंदोलन और नियंत्रण';
	@override String get systemHint => 'आपके डिवाइस की पहुंच सेटिंग्स हमेशा लागू होती हैं. इन विकल्पों में PlezyNG के दौरान समायोजन जोड़े जाते हैं.';
	@override String get readability => 'पढ़ना और दृश्यता';
	@override String get textSize => 'अतिरिक्त पाठ आकार';
	@override String get preview => 'अपनी अगली कहानी खोजें. पढ़ें, सुनो और अपने स्वयं के गति से देखें.';
	@override String get boldText => 'बहादुर इंटरफ़ेस पाठ';
	@override String get highContrast => 'उच्च विरोधाभास';
	@override String get highContrastHint => 'मजबूत पाठ, आउटलिंग और प्रकाश या अंधेरे सतहों पर ध्यान केंद्रित करने वाले संकेतक।';
	@override String get interaction => 'आंदोलन और बातचीत';
	@override String get reduceMotion => 'आंदोलन को कम करें';
	@override String get reduceMotionHint => 'फ़ोकस संकेतक, पृष्ठ परिवर्तन और सजावटी प्रभावों की गति बंद रखें।';
	@override String get largeTargets => 'अधिक लक्षित लक्ष्य';
	@override String get largeTargetsHint => 'साझा नियंत्रण को स्पर्श और सहायक नेविगेशन के लिए अधिक स्थान दें।';
	@override String get navigationHint => 'नियंत्रणों के बीच जाने के लिए Tab और Shift+Tab, सक्रिय करने के लिए Enter या Space और बंद करने के लिए Escape या वापस जाने वाले बटन का उपयोग करें। किताब खुली होने पर ज़ूम और पढ़ने की प्राथमिकताएँ उपलब्ध रहती हैं।';
}

// Path: tooltips
class _Translations$tooltips$hi extends Translations$tooltips$en {
	_Translations$tooltips$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'शूफ खेल';
	@override String get playTrailer => 'ट्रेलर खेलना';
	@override String get markAsWatched => 'मार्क देखने के लिए';
	@override String get markAsUnwatched => 'अनदेखी के रूप में मार्क';
}

// Path: audioTracks
class _Translations$audioTracks$hi extends Translations$audioTracks$en {
	_Translations$audioTracks$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'ऑडियो ट्रैक ${n}';
}

// Path: videoControls
class _Translations$videoControls$hi extends Translations$videoControls$en {
	_Translations$videoControls$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} फ्रेम',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} फ्रेम',
	);
	@override String get audioLabel => 'ऑडियो';
	@override String get subtitlesLabel => 'उपशीर्षक';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String get letterbox => 'पत्रबॉक्स';
	@override String get fillScreen => 'स्क्रीन भरें';
	@override String get stretch => 'तंग';
	@override String get lockRotation => 'लॉक रोटेशन';
	@override String get unlockRotation => 'रोटेशन को खत्म करें';
	@override String get timerActive => 'टाइमर सक्रिय';
	@override String playbackWillPauseIn({required Object duration}) => 'प्लेबैक ${duration} में रुक जाएगा';
	@override String get sleepTimerEndOfVideo => 'वर्तमान वीडियो का अंत';
	@override String get sleepTimerStopAtHeader => 'रुकें';
	@override String get sleepTimerDurationHeader => 'टाइमर';
	@override String get playbackWillPauseAtEnd => 'Playback इस वीडियो के अंत में रुक जाएगा';
	@override String get stillWatching => 'अभी भी देखते हैं?';
	@override String pausingIn({required Object seconds}) => '${seconds} में आराम';
	@override String get continueWatching => 'जारी है';
	@override String get autoPlayNext => 'अगला Auto-Play';
	@override String get playNext => 'Next खेलना';
	@override String get playButton => 'खेलना';
	@override String get pauseButton => 'रोकें';
	@override String get playbackPaused => 'आराम';
	@override String get playbackResumed => 'खेलना';
	@override String get loadingVideo => 'वीडियो लोड';
	@override String get showPlaybackControls => 'Playback नियंत्रण दिखाएं';
	@override String get hidePlaybackControls => 'Playback नियंत्रण को छिपाएं';
	@override String seekBackwardButton({required Object seconds}) => 'पीछे की ओर खोजें ${seconds} सेकंड';
	@override String seekForwardButton({required Object seconds}) => 'आगे की तलाश ${seconds} सेकंड';
	@override String get previousButton => 'पिछला एपिसोड';
	@override String get nextButton => 'अगला एपिसोड';
	@override String get previousChapterButton => 'पिछला अध्याय';
	@override String get nextChapterButton => 'अगला अध्याय';
	@override String get muteButton => 'मुट्ठी';
	@override String get unmuteButton => 'अनमोल';
	@override String get settingsButton => 'Playback सेटिंग्स';
	@override String get tracksButton => 'ऑडियो और उपनाम';
	@override String get trackSelectionTitle => 'प्लेबैक से पहले ट्रैक चुनें';
	@override String get trackSelectionAuto => 'स्वचालित चयन';
	@override String get chaptersButton => 'अध्याय';
	@override String get versionQualityButton => 'संस्करण और गुणवत्ता';
	@override String get versionColumnHeader => 'संस्करण';
	@override String get qualityColumnHeader => 'गुणवत्ता';
	@override String get qualityOriginal => 'मूल';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} एमबीपीएस';
	@override String get transcodeUnavailableFallback => 'ट्रांसकोडिंग उपलब्ध नहीं है - मूल गुणवत्ता खेलने के लिए';
	@override String get subtitleUnavailableFallback => 'चुने हुए उप शीर्षक लोड नहीं किया जा सकता है — बिना उप शीर्षक जारी';
	@override String get pipButton => 'Image-in-Picture मोड';
	@override String get aspectRatioButton => 'आस्पेक्ट अनुपात';
	@override String get ambientLighting => 'पर्यावरण प्रकाश';
	@override String get fullscreenButton => 'पूर्ण स्क्रीन में प्रवेश';
	@override String get exitFullscreenButton => 'पूर्ण स्क्रीन से बाहर';
	@override String get alwaysOnTopButton => 'हमेशा शीर्ष पर';
	@override String get rotationLockButton => 'रोटेशन लॉक';
	@override String get lockScreen => 'लॉक स्क्रीन';
	@override String get screenLockButton => 'स्क्रीन लॉक';
	@override String get longPressToUnlock => 'लंबे समय तक दबाव में विघटित';
	@override String get timelineSlider => 'वीडियो टाइमलाइन';
	@override String get volumeSlider => 'वॉल्यूम स्तर';
	@override String endsAt({required Object time}) => '${time} पर समाप्त';
	@override String get pipActive => 'Picture-in-Picture में खेलना';
	@override String get pipFailed => 'फोटो-इन-चित्र शुरू नहीं हुआ';
	@override String get screenshotSaved => 'स्क्रीनशॉट बचाए गए';
	@override String get screenshotFailed => 'कोई स्क्रीनशॉट नहीं ले सकता';
	@override String zoomPercent({required Object percent}) => 'ज़ूम ${percent}%';
	@override String volumePercent({required Object percent}) => 'वॉल्यूम ${percent}%';
	@override late final _Translations$videoControls$pipErrors$hi pipErrors = _Translations$videoControls$pipErrors$hi._(_root);
	@override String get chapters => 'अध्याय';
	@override String get noChaptersAvailable => 'कोई अध्याय उपलब्ध नहीं';
	@override String get queue => 'क्यूए';
	@override String get noQueueItems => 'क्यूए में कोई आइटम नहीं';
	@override String get noAudioDevicesAvailable => 'कोई ऑडियो डिवाइस उपलब्ध नहीं है';
	@override String get searchSubtitles => 'Subtitles खोजें';
	@override String get loadSubtitleFile => 'Subtitle फ़ाइल डाउनलोड करें';
	@override String get subtitleLoadFailed => 'Subtitle फ़ाइल डाउनलोड करने में विफल';
	@override String get language => 'भाषा';
	@override String get noSubtitlesFound => 'कोई उपनाम नहीं मिला';
	@override String get subtitleDownloaded => 'Subtitle डाउनलोड करें';
	@override String get subtitleDownloadedNotApplied => 'Subtitle डाउनलोड किया गया, लेकिन इसे चुना नहीं जा सकता था';
	@override String get subtitleDownloadFailed => 'Subtitle डाउनलोड करने में असफल';
	@override String get searchLanguages => 'भाषाओं की खोज...';
	@override String get skipIntro => 'स्काइप इनट्रू';
	@override String get skipCredits => 'क्रेडिट स्केप';
	@override String get skipAds => 'स्काइप विज्ञापन';
	@override String get nextEpisode => 'अगला एपिसोड';
	@override String subtitleTrack({required Object n}) => 'ट्रैक ${n}';
	@override String subtitleFile({required Object name}) => 'पदों की संख्या ${name}';
	@override String forcedTrack({required Object label}) => '${label} (निरपेक्ष)';
	@override String get osdSubtitlesOff => 'पदों की सूची: Off';
	@override String osdSubtitles({required Object track}) => 'पदों की संख्या: ${track}';
	@override String osdAudio({required Object track}) => 'ऑडियो: ${track}';
}

// Path: messages
class _Translations$messages$hi extends Translations$messages$en {
	_Translations$messages$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'देखने के लिए मार्केटिंग';
	@override String get markedAsUnwatched => 'अनदेखा के रूप में चिह्नित';
	@override String get markedAsWatchedOffline => 'देखने के रूप में चिह्नित (जब ऑनलाइन सिंक्रनाइज़ किया जाएगा)';
	@override String get markedAsUnwatchedOffline => 'अनदेखा के रूप में चिह्नित (जब ऑनलाइन सिंक्रनाइज़ किया जाएगा)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'स्वचालित रूप से हटाया: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n,
		one: 'स्वचालित रूप से हटाया ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} डाउनलोड किया गया',
		other: 'स्वचालित रूप से हटाया ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} देखा डाउनलोड',
	);
	@override String get removedFromContinueWatching => 'जारी रखने से हटा दिया';
	@override String errorLoading({required Object error}) => 'त्रुटि: ${error}';
	@override String get searchPartialResults => 'कुछ मीडिया सर्वरों की खोज नहीं की जा सकती थी. उपलब्ध परिणाम दिखाते हैं.';
	@override String get streamInterrupted => 'प्रवाह बंद कर दिया गया था. प्रेस खेल या रिट्री करने की कोशिश करें.';
	@override String get liveStreamInterrupted => 'लाइव स्ट्रीम बंद कर दिया गया. प्रेस गेम रिट्री के लिए।';
	@override String get fileInfoNotAvailable => 'फ़ाइल जानकारी उपलब्ध नहीं';
	@override String get playbackAuthenticationRequired => 'इस आइटम को खेलने के लिए मीडिया सर्वर पर फिर से साइन इन करें।';
	@override String get playbackServerUnavailable => 'मीडिया सर्वर उपलब्ध नहीं है. बाद में फिर से कोशिश करें.';
	@override String get playbackDataInvalid => 'सर्वर ने नकारात्मक प्लेबैक जानकारी वापस कर दी।';
	@override String get playbackCancelled => 'Playback रद्द कर दिया गया है।';
	@override String get playbackFailed => 'प्लेबैक शुरू नहीं किया जा सकता था।';
	@override String playbackFailedDetail({required Object error}) => 'प्लेबैक शुरू नहीं किया जा सकता था: ${error}';
	@override String get audioOutputFailed => 'टीवी या रिसीवर के ऑडियो कनेक्शन की जांच करें; यदि अन्य ऐप्स में कोई ध्वनि नहीं है, तो डिवाइस को पुनरारंभ करें।';
	@override String get mediaUnavailable => 'यह सामग्री अब उपलब्ध नहीं है।';
	@override String errorLoadingFileInfo({required Object error}) => 'त्रुटि लोड फ़ाइल जानकारी: ${error}';
	@override String get errorLoadingSeries => 'त्रुटि चार्जिंग श्रृंखला';
	@override String get musicNotSupported => 'संगीत प्लेबैक अभी तक समर्थित नहीं है';
	@override String get noDescriptionAvailable => 'कोई विवरण उपलब्ध नहीं';
	@override String get noProfilesAvailable => 'कोई प्रोफ़ाइल उपलब्ध नहीं';
	@override String get contactAdminForProfiles => 'प्रोफ़ाइल जोड़ने के लिए अपने सर्वर व्यवस्थापक से संपर्क करें';
	@override String get unableToDetermineLibrarySection => 'इस आइटम के लिए पुस्तकालय अनुभाग निर्धारित करने में असमर्थ';
	@override String get logsCleared => 'लॉग साफ';
	@override String get logsCopied => 'क्लिपबोर्ड में कॉपी किए गए लॉग';
	@override String get noLogsAvailable => 'कोई लॉग उपलब्ध नहीं';
	@override String libraryScanning({required Object title}) => 'स्कैन करें "${title}" ...';
	@override String libraryScanStarted({required Object title}) => 'पुस्तकालय स्कैन "${title}" के लिए शुरू हुआ';
	@override String libraryScanFailed({required Object error}) => 'पुस्तकालय स्कैन करने में विफलता: ${error}';
	@override String metadataRefreshing({required Object title}) => '"${title}" के लिए ताज़ा मेटाडेटा ...';
	@override String metadataRefreshStarted({required Object title}) => '"${title}" के लिए मेटाडेटा रिफ्रेश शुरू हुआ';
	@override String metadataRefreshFailed({required Object error}) => 'मेटाडेटा को पुनर्जीवित करने में विफलता: ${error}';
	@override String get logoutConfirm => 'क्या आप निश्चित हैं कि आप लॉग इन करना चाहते हैं?';
	@override String get noSeasonsFound => 'कोई मौसम नहीं मिला';
	@override String get seasonsLoadFailed => 'मौसम नहीं ले सकते';
	@override String get noEpisodesFound => 'पहली सीजन में कोई घटना नहीं मिली';
	@override String get noEpisodesFoundGeneral => 'कोई घटना नहीं मिली';
	@override String get episodesLoadFailed => 'घटनाओं को लोड नहीं किया जा सकता';
	@override String get noResultsFound => 'कोई परिणाम नहीं मिला';
	@override String sleepTimerSet({required Object label}) => 'नींद टाइमर सेट ${label} के लिए';
	@override String get noItemsAvailable => 'कोई उपलब्ध वस्तु नहीं';
	@override String get failedToCreatePlayQueueNoItems => 'एक गेमिंग क्यूव बनाने में विफल रहा - कोई आइटम नहीं';
	@override String failedPlayback({required Object action, required Object error}) => 'असफल ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'संगत खिलाड़ी के लिए स्विच करने के लिए ...';
	@override String get serverLimitTitle => 'Playback असफल रहा';
	@override String get serverLimitBody => 'सर्वर त्रुटि (HTTP 500). बैंडविड्थ / ट्रांसकोडिंग सीमा शायद इस सत्र को खारिज कर दिया. मालिक से इसे समायोजित करने के लिए पूछें.';
	@override String get mediaUnreadableTitle => 'फ़ाइल उपलब्ध नहीं';
	@override String get mediaUnreadableBody => 'सर्वर ने इस आइटम को पाया लेकिन फ़ाइल को पढ़ने में असमर्थ था (HTTP 404). फ़ाइल को शायद स्थानांतरित किया गया था, हटा दिया गया था, या इसका स्टोरेज ऑफ़लाइन है. सर्वर के मालिक से फ़ाइल की जांच करने और पुस्तकालय को बचाने के लिए पूछें.';
	@override String get serverBusyTitle => 'अनावश्यक प्रवाह';
	@override String get serverBusyBody => 'सर्वर इस फ़ाइल को प्रसारित करने से इनकार कर रहा था (HTTP 503). यह पुनरारंभ हो सकता है, व्यस्त हो सकता है, या फ़ाइल का स्टोरेज ऑफ़लाइन हो सकता है. एक पल में फिर से कोशिश करें - यदि यह जारी रहता है, तो सर्वर के मालिक से पूछें कि सर्वर और फ़ाइल का स्टोरेज जांचें.';
	@override String get playbackNotAllowedTitle => 'Playback की अनुमति नहीं है';
	@override String get playbackNotAllowedBody => 'सर्वर ने इस आइटम को प्रसारित करने से इनकार कर दिया (HTTP 403). आपके खाते को इसे खेलने की अनुमति नहीं हो सकती है, या सर्वर केवल अपने स्थानीय नेटवर्क पर प्लेबैक की अनुमति दे सकता है.';
	@override String get logsUploaded => 'लॉग अपलोड';
	@override String get logsUploadFailed => 'लॉग अपलोड करने में विफल';
	@override String get logId => 'लॉग आईडी';
	@override String get burnedSubtitlesUseMenu => 'उपनाम इस प्रवाह में जलाए जाते हैं. उन्हें उपनाम मेनू से बदलें.';
	@override String get noVideoUrl => 'कोई वीडियो URL उपलब्ध नहीं है';
	@override String get playbackNoMediaSources => 'सर्वर को कोई खेलने योग्य मीडिया स्रोत नहीं लौटाया';
	@override String get playbackDataNotPrepared => 'Playback पहले शुरू किया गया था, इससे पहले कि डेटा तैयार हो गया था';
	@override String get streamSelectionUnavailable => 'स्ट्रीम चयन इस स्रोत के लिए उपलब्ध नहीं है';
	@override String get streamSelectionFailed => 'चुने हुए स्ट्रीम को लागू नहीं किया जा सकता';
	@override String get trackSelectionNotRemembered => 'यह ट्रैक विकल्प केवल वर्तमान प्लेबैक पर लागू होता है।';
	@override String get serverUnavailableForProfile => 'सक्रिय प्रोफ़ाइल के लिए कोई सर्वर उपलब्ध नहीं है';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$hi extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get previewSample => 'तेजी से भूरे रंग का फॉक्स कुत्ते के ऊपर कूदता है';
	@override String get text => 'पाठ';
	@override String get border => 'सीमा';
	@override String get background => 'पृष्ठभूमि';
	@override String get fontSize => 'फ़ॉन्ट आकार';
	@override String get textColor => 'पाठ रंग';
	@override String get borderSize => 'सीमा आकार';
	@override String get borderColor => 'सीमा रंग';
	@override String get backgroundOpacity => 'पृष्ठभूमि अस्थिरता';
	@override String get backgroundColor => 'पृष्ठभूमि रंग';
	@override String get position => 'स्थिति';
	@override String get assOverride => 'ASS अधिग्रहण';
	@override String get overrideScale => 'स्केल';
	@override String get overrideForce => 'ताकत';
	@override String get overrideStrip => 'स्टाइलिंग हटाएं';
	@override String get positionTop => 'शीर्ष';
	@override String get positionBottom => 'नीचे';
	@override String get useMargins => 'मार्जिन का उपयोग करें';
	@override String get useMarginsDescription => 'वीडियो के बाहर अंतरिक्ष में पाठ उपशीर्षक की अनुमति दें. स्टाइलिश उपशीर्षक अपनी मूल स्थिति बनाए रख सकते हैं.';
	@override String get anchorToScreen => 'स्क्रीन के लिए एन्कोर';
	@override String get anchorToScreenDescription => 'विस्तृत स्क्रीन वीडियो के नीचे काले पट्टी में पाठ उपशीर्षक दिखाएं';
	@override String get bold => 'साहसी';
	@override String get italic => 'इटली';
	@override String get renderResolution => 'रेंडर संकल्प';
	@override String get renderResolutionScreen => 'स्क्रीन संकल्प';
	@override String get renderResolutionVideo => 'वीडियो संकल्प';
}

// Path: mpvConfig
class _Translations$mpvConfig$hi extends Translations$mpvConfig$en {
	_Translations$mpvConfig$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'उन्नत वीडियो प्लेयर सेटिंग्स';
	@override String get presets => 'उपन्यास';
	@override String get noPresets => 'कोई बचाव नहीं';
	@override String get saveAsPreset => 'प्रीमियम के रूप में...';
	@override String get presetName => 'प्रीमियम नाम';
	@override String get presetNameHint => 'इस प्रीसेट के लिए एक नाम दर्ज करें';
	@override String get loadPreset => 'लोड';
	@override String get deletePreset => 'डिलीट';
	@override String get presetSaved => 'प्रीमियम बचाए गए';
	@override String get presetLoaded => 'प्रीमियम लोड';
	@override String get presetDeleted => 'प्रीमियम हटाया';
	@override String get confirmDeletePreset => 'क्या आप निश्चित हैं कि आप इस प्रीसेट को हटाना चाहते हैं?';
	@override String get configPlaceholder => 'gpu-api=vulkan hwdec=auto # टिप्पणी';
	@override String get lineHint => 'option=value';
	@override String get addLine => 'लाइन जोड़ें';
	@override String get removeLine => 'लाइन हटाएं';
	@override String get embeddedVoHint => 'vo, gpu-context और gpu-api Linux पर अनदेखा किया जाता है: अंतर्निहित वीडियो हमेशा वीडियो प्लेट पर vo=libmpv के माध्यम से रेंडर करता है, और gpu-next (जो ArtCNN की तरह कंप्यूटर छायाओं की आवश्यकता होती है) अंतर्निहित नहीं चल सकता है।';
}

// Path: dialog
class _Translations$dialog$hi extends Translations$dialog$en {
	_Translations$dialog$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'कार्य की पुष्टि करें';
}

// Path: profiles
class _Translations$profiles$hi extends Translations$profiles$en {
	_Translations$profiles$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'PlezyNG प्रोफ़ाइल जोड़ें';
	@override String get switchingProfile => 'प्रोफ़ाइल स्विच...';
	@override String get deleteThisProfileTitle => 'इस प्रोफ़ाइल को हटा दें?';
	@override String deleteThisProfileMessage({required Object displayName}) => 'हटाएँ ${displayName}. कनेक्शन प्रभावित नहीं होते हैं.';
	@override String get active => 'सक्रिय';
	@override String get manage => 'प्रबंधन';
	@override String get delete => 'डिलीट';
	@override String get signOut => 'Sign out';
	@override String get signOutPlexTitle => 'Plex पर हस्ताक्षर करें?';
	@override String signOutPlexMessage({required Object displayName}) => '${displayName} और सभी Plex होम उपयोगकर्ताओं को हटा दें? किसी भी समय वापस साइन अप करें.';
	@override String get signOutPlexDeleteDownloads => 'डाउनलोड भी करें';
	@override String get signOutPlexDeleteDownloadsDescription => 'अन्यथा वे इस डिवाइस पर रहते हैं और जब आप इस खाते में वापस साइन इन करते हैं तो वापस आते हैं।';
	@override String get signedOutPlex => 'Plex पर हस्ताक्षर किए गए हैं।';
	@override String get signOutFailed => 'असफल होने का संकेत';
	@override String get sectionTitle => 'प्रोफ़ाइल';
	@override String get summarySingle => 'प्रबंधित उपयोगकर्ताओं और स्थानीय पहचान को मिश्रित करने के लिए प्रोफाइल जोड़ें';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} प्रोफाइल · सक्रिय: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} प्रोफ़ाइल';
	@override String get removeConnectionTitle => 'कनेक्शन हटाने के लिए?';
	@override String removeConnectionMessage({required Object connectionLabel, required Object displayName}) => '${connectionLabel} के लिए ${displayName} का एक्सेस हटा दें. अन्य प्रोफाइल इसे रखते हैं.';
	@override String get deleteProfileTitle => 'प्रोफ़ाइल को हटाने के लिए?';
	@override String deleteProfileMessage({required Object displayName}) => '${displayName} और इसके कनेक्शन को हटा दें. सर्वर उपलब्ध रहें.';
	@override String get profileNameLabel => 'प्रोफ़ाइल नाम';
	@override String get pinProtectionLabel => 'PIN सुरक्षा';
	@override String get copyAutomationLink => 'कॉपी करें Android स्वचालित लिंक';
	@override String get copyAutomationLinkDescription => 'इस प्रोफ़ाइल को एक Android इंटेंट या स्वचालन से चुनें. प्रोफ़ाइल पीएन चेक अभी भी लागू होते हैं.';
	@override String get automationLinkCopied => 'प्रोफ़ाइल स्वचालन लिंक कॉपी किया गया है।';
	@override String get pinManagedByPlex => 'PIN द्वारा संचालित Plex. plex.tv पर संपादित करें.';
	@override String get noPinSetEditOnPlex => 'कोई पिन सेट नहीं. एक की आवश्यकता के लिए, plex.tv पर होम उपयोगकर्ता को संपादित करें.';
	@override String get setPin => 'PIN सेट करें';
	@override String get setPinTitle => 'PIN सेट करें';
	@override String get confirmPinTitle => 'PIN की पुष्टि करें';
	@override String get pinSet => 'PIN सेट';
	@override String get changePin => 'बदलाव';
	@override String get removePin => 'हटाना';
	@override String get connectionsLabel => 'कनेक्शन';
	@override String get add => 'जोड़ें';
	@override String get deleteProfileButton => 'प्रोफ़ाइल हटाएँ';
	@override String get noConnectionsHint => 'कोई कनेक्शन नहीं - इस प्रोफ़ाइल का उपयोग करने के लिए एक जोड़ें।';
	@override String get noConnections => 'कोई कनेक्शन';
	@override String get plexHomeAccount => 'Plex होम खाता';
	@override String plexAccountChip({required Object account}) => 'Plex खाता: ${account}';
	@override String plexAccountUserChip({required Object user, required Object account}) => '${user} पर ${account}';
	@override String get connectionDefault => 'मूल';
	@override String connectionAs({required Object displayName}) => 'के रूप में ${displayName}';
	@override String get makeDefault => 'डिफ़ॉल्ट करें';
	@override String get removeConnection => 'हटाना';
	@override String get profileRenamed => 'प्रोफ़ाइल नाम';
	@override String borrowAddTo({required Object displayName}) => '${displayName} पर जोड़ें';
	@override String get borrowExplain => 'एक और प्रोफ़ाइल के कनेक्शन को उधार दें. PIN-सुरक्षित प्रोफ़ाइलों को एक PIN की आवश्यकता होती है.';
	@override String get borrowEmpty => 'अभी तक ऋण देने के लिए कुछ भी नहीं है।';
	@override String get borrowEmptySubtitle => 'पहले Plex, Jellyfin, या Emby को किसी अन्य प्रोफ़ाइल से कनेक्ट करें।';
	@override String get borrowLoadFailed => 'उपलब्ध कनेक्शन लोड नहीं किया जा सकता. फिर से कोशिश करें.';
	@override String borrowFromProfile({required Object displayName}) => 'से ${displayName}';
	@override String get borrowConnectionBorrowed => 'कनेक्शन का ऋण';
	@override String get borrowFailed => 'ऋण कनेक्शन में असफल रहा।';
	@override String get incorrectPin => 'गलत पिन';
	@override String get incorrectPinTryAgain => 'गलत PIN. कृपया फिर से कोशिश करें.';
	@override String get sourceProfileMissingParentAccount => 'स्रोत प्रोफ़ाइल अपने माता-पिता खाते की कमी है।';
	@override String get failedToLoadHomeUsers => 'अपने Plex होम उपयोगकर्ताओं को लोड नहीं कर सकते. अपने कनेक्शन की जांच करें और फिर से कोशिश करें.';
	@override String get failedToVerifyPin => 'PIN की पुष्टि नहीं की गई।';
	@override String get newProfile => 'नया प्रोफ़ाइल';
	@override String get profileNameHint => 'उदाहरण के लिए, मेहमान, बच्चों, परिवार के कमरे';
	@override String get pinProtectionOptional => 'PIN सुरक्षा (वैकल्पिक)';
	@override String get pinExplain => 'प्रोफ़ाइल बदलने के लिए 4 डिजिटल पिन की आवश्यकता होती है।';
	@override String get continueButton => 'जारी है';
	@override String get pinsDontMatch => 'पिन नहीं मिलता';
	@override String get tokenIdentityMismatch => 'Plex प्रोफ़ाइल टोकन एक अप्रत्याशित सर्वर पर हल किया गया';
	@override String get settingsLocked => 'इस प्रोफ़ाइल के लिए सेटिंग्स बंद हैं।';
	@override String get unlockSettings => 'अनलॉक सेटिंग्स';
	@override String get showExploreForProfile => 'इस प्रोफ़ाइल के लिए खोजें';
	@override String get showExploreForProfileDescription => 'इस प्रोफ़ाइल के नवाचार से Explore को हटाने के लिए बंद करें।';
}

// Path: connections
class _Translations$connections$hi extends Translations$connections$en {
	_Translations$connections$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'कनेक्शन';
	@override String get addConnection => 'कनेक्शन जोड़ें';
	@override String get addConnectionSubtitleNoProfile => 'Plex के साथ साइन इन करें या Jellyfin या Emby सर्वर से कनेक्ट करें';
	@override String addConnectionSubtitleScoped({required Object displayName}) => '${displayName}: Plex, Jellyfin, Emby, या किसी अन्य प्रोफ़ाइल कनेक्शन में जोड़ें';
	@override String sessionExpiredOne({required Object name}) => 'सत्र समाप्त हो गया ${name}';
	@override String sessionExpiredMany({required Object count}) => '${count} सर्वरों के लिए सत्र समाप्त हो गया';
	@override String accessDeniedOne({required Object name}) => '${name} इस खाते के लिए पहुंच से इनकार कर दिया';
	@override String accessDeniedMany({required Object count}) => '${count} सर्वर इस खाते के लिए पहुंच से इनकार कर दिया';
	@override String get signInAgain => 'फिर से हस्ताक्षर करें';
	@override String editMediaBrowserTitle({required Object product}) => 'संपादित करें ${product} कनेक्शन';
	@override String editMediaBrowserIntro({required Object serverName}) => '${serverName} के लिए URL जोड़ें या हटा दें. PlezyNG सबसे कम देरी के साथ पहुंचने योग्य URL का उपयोग करेगा.';
}

// Path: accountPreferences
class _Translations$accountPreferences$hi extends Translations$accountPreferences$en {
	_Translations$accountPreferences$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'अकाउंट प्राथमिकताएं';
	@override String hubSubtitleSingle({required Object account}) => 'ऑडियो, उप शीर्षक और पुस्तकालय विकल्पों को सहेजा गया है ${account}';
	@override String hubSubtitleMultiple({required Object count}) => 'ऑडियो, उप शीर्षक और पुस्तकालय विकल्प ${count} खातों पर सहेजे गए हैं';
	@override String get pickAccount => 'प्रत्येक खाता अपने स्वयं के प्राथमिकताओं को संग्रहीत करता है. इसे संपादित करने के लिए चुनें.';
	@override String get storedOnAccount => 'इन विकल्पों को अपने खाते में सहेजा जाता है, इसलिए इसमें साइन अप करने वाले प्रत्येक ऐप उनका उपयोग करता है – इसके अलावा आपके अन्य उपकरणों पर PlezyNG।';
	@override String get noAccounts => 'कोई खाता नहीं बनाया जा सकता';
	@override String get noAccountsHint => 'Plex पर साइन इन करें, या Jellyfin या Emby सर्वर से कनेक्ट करें, और उस खाते पर संग्रहीत प्राथमिकताएं यहां दिखाई देती हैं।';
	@override String get unavailable => 'इस खाते तक नहीं पहुंच सकते';
	@override String get loadFailed => 'इन प्राथमिकताओं को लोड नहीं किया जा सकता';
	@override String get noPreference => 'कोई प्राथमिकता नहीं';
	@override String get notSet => 'सेट नहीं';
	@override late final _Translations$accountPreferences$groups$hi groups = _Translations$accountPreferences$groups$hi._(_root);
	@override String get preferredAudioLanguage => 'ऑडियो भाषा की पसंद';
	@override String get autoSelectAudio => 'भाषा के अनुसार ऑडियो का चयन करें';
	@override String get autoSelectAudioDescription => 'किसी भी ऑडियो ट्रैक को डिफ़ॉल्ट रूप से फ़ाइल चिह्नित रखता है।';
	@override String get preferredSubtitleLanguage => 'Subtitle भाषा के बारे में';
	@override String get subtitleMode => 'Subtitles के बारे में जानें';
	@override late final _Translations$accountPreferences$subtitleModes$hi subtitleModes = _Translations$accountPreferences$subtitleModes$hi._(_root);
	@override String get subtitleAccessibility => 'एसडीएच उपनाम';
	@override late final _Translations$accountPreferences$subtitleAccessibilityOptions$hi subtitleAccessibilityOptions = _Translations$accountPreferences$subtitleAccessibilityOptions$hi._(_root);
	@override String get forcedSubtitles => 'मजबूर subtitles';
	@override late final _Translations$accountPreferences$forcedSubtitleOptions$hi forcedSubtitleOptions = _Translations$accountPreferences$forcedSubtitleOptions$hi._(_root);
	@override String get displayMissingEpisodes => 'याद किए गए घटनाओं को दिखाएं';
	@override String get displayMissingEpisodesDescription => 'सर्वर के बारे में जानते हैं, लेकिन फ़ाइल के लिए नहीं है।';
	@override String get hidePlayedInLatest => 'अंतिम में देखे गए वस्तुओं को छिपाएं';
	@override String get hidePlayedInLatestDescription => 'उन आइटमों को छोड़ दें जिन्हें आपने पहले से ही सर्वर के नवीनतम पंक्तियों से बाहर देखा है।';
	@override String get displayCollectionsView => 'संग्रह दृश्य दिखाएं';
	@override String get displayCollectionsViewDescription => 'अपने पुस्तकालयों के बगल में सर्वर के संग्रह दृश्य की पेशकश करें।';
	@override String get rewatchingInNextUp => 'Next Up में देखे जाने वाले शो जारी रखें';
	@override String get rewatchingInNextUpDescription => 'एक बार जब आप एक शो खत्म करते हैं, तो इसे फिर से शुरू करें और Next Up शो को छोड़ने के बजाय पुनरावृत्ति का पालन करता है।';
	@override String get watchedIndicator => 'देखें संकेतक';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$hi watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$hi._(_root);
	@override String get mediaReviewsVisibility => 'रेटिंग और समीक्षा';
	@override late final _Translations$accountPreferences$mediaReviewsOptions$hi mediaReviewsOptions = _Translations$accountPreferences$mediaReviewsOptions$hi._(_root);
}

// Path: discover
class _Translations$discover$hi extends Translations$discover$en {
	_Translations$discover$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'खोजें';
	@override String get noContentAvailable => 'कोई सामग्री उपलब्ध नहीं';
	@override String get addMediaToLibraries => 'अपने पुस्तकालयों में कुछ मीडिया जोड़ें';
	@override String get continueWatching => 'देखना जारी रखें';
	@override String continueWatchingIn({required Object library}) => 'अब देखें ${library}';
	@override String get nextUp => 'अगला ऊपर';
	@override String nextUpIn({required Object library}) => 'अगले में ${library}';
	@override String get recentlyAdded => 'हाल ही में जोड़ा';
	@override String recentlyAddedIn({required Object library}) => 'हाल ही में जोड़ा गया ${library} में';
	@override String latestAlbumsIn({required Object library}) => '${library} में नवीनतम एल्बम';
	@override String recentlyPlayedIn({required Object library}) => 'हाल ही में खेले गए ${library} में';
	@override String mostPlayedIn({required Object library}) => 'सबसे ज्यादा खेले गए ${library} में';
	@override String playEpisode({required Object season, required Object episode}) => 'सीज़न ${season} एपिसोड ${episode}';
	@override String get overview => 'समीक्षा';
	@override String get cast => 'कास्टिंग';
	@override late final _Translations$discover$findNext$hi findNext = _Translations$discover$findNext$hi._(_root);
	@override String get extras => 'ट्रेलर और अतिरिक्त';
	@override String get studio => 'स्टूडियो';
	@override String get rating => 'रेटिंग';
	@override String get director => 'निर्देशक';
	@override String get directors => 'निर्देशक';
	@override String get movie => 'फिल्में';
	@override String get tvShow => 'टीवी शो';
	@override String minutesLeft({required Object minutes}) => '${minutes} मिनट छोड़ दिया';
	@override String get moreLikeThis => 'इस तरह से अधिक';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} पदों की सूची',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} पदों की सूची',
	);
	@override late final _Translations$discover$person$hi person = _Translations$discover$person$hi._(_root);
}

// Path: errors
class _Translations$errors$hi extends Translations$errors$en {
	_Translations$errors$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'खोज विफल: ${error}';
	@override String get searchUnavailable => 'किसी भी मीडिया सर्वर तक पहुंच नहीं पाया।';
	@override String connectionTimeout({required Object context}) => 'लोड करते समय कनेक्शन टाइम-आउट ${context}';
	@override String get connectionFailed => 'मीडिया सर्वर से कनेक्ट नहीं कर सकते';
	@override String unableToLoad({required Object context}) => '${context} लोड करने में असमर्थ है. कृपया फिर से कोशिश करें.';
	@override String get noClientAvailable => 'कोई ग्राहक उपलब्ध नहीं';
	@override String get pleaseEnterToken => 'कृपया एक टोकन दर्ज करें';
	@override String get invalidToken => 'अयोग्य टोकन';
	@override String failedToVerifyToken({required Object error}) => 'टोकन की पुष्टि नहीं की गई: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => '${displayName} पर स्विच करने में विफल';
	@override String failedToDeleteProfile({required Object displayName}) => '${displayName} को हटाने में विफलता';
	@override String get failedToRate => 'रेटिंग नहीं कर सकते';
	@override String get reasonTimedOut => 'कनेक्शन समय से बाहर';
	@override String get reasonUnreachable => 'सर्वर तक पहुंच नहीं पाया';
	@override String get reasonRefused => 'सर्वर ने अनुरोध को अस्वीकार कर दिया';
	@override String get reasonNotFound => 'अब सर्वर पर नहीं है।';
	@override String get reasonServerError => 'सर्वर ने एक त्रुटि की सूचना दी';
	@override String get reasonCancelled => 'अनुरोध रद्द कर दिया गया';
	@override String get reasonUnexpected => 'एक अप्रत्याशित गलती हुई';
}

// Path: libraries
class _Translations$libraries$hi extends Translations$libraries$en {
	_Translations$libraries$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => 'एक यादृच्छिक फिल्म खेलना';
	@override String get randomPickFailed => 'मैं इस पुस्तकालय से एक यादृच्छिक फिल्म नहीं चुन सकता था।';
	@override String get title => 'पुस्तकालय';
	@override String get fallbackTitle => 'लाइब्रेरी';
	@override String get scanLibraryFiles => 'पुस्तकालय फ़ाइलों का स्कैन';
	@override String get scanLibrary => 'पुस्तकालय स्कैन';
	@override String get analyze => 'विश्लेषण';
	@override String get analyzeLibrary => 'पुस्तकालय विश्लेषण';
	@override String get refreshMetadata => 'मेटाडेटा को ताज़ा करें';
	@override String get emptyTrash => 'खाली ट्रैश';
	@override String emptyingTrash({required Object title}) => '"${title}" के लिए खाली कचरा ...';
	@override String trashEmptied({required Object title}) => '"${title}" के लिए ट्रैश एम्टिड';
	@override String failedToEmptyTrash({required Object error}) => 'खाली कचरे में विफलता: ${error}';
	@override String analyzing({required Object title}) => '"${title}" का विश्लेषण करें।';
	@override String analysisStarted({required Object title}) => '"${title}" के लिए विश्लेषण शुरू हुआ';
	@override String failedToAnalyze({required Object error}) => 'पुस्तकालय का विश्लेषण करने में विफलता: ${error}';
	@override String get noLibrariesFound => 'कोई पुस्तकालय नहीं मिला';
	@override String get allLibrariesHidden => 'सभी पुस्तकालय छिपे हुए हैं';
	@override String hiddenLibrariesCount({required Object count}) => 'छिपे हुए पुस्तकालयों (${count})';
	@override String get thisLibraryIsEmpty => 'यह पुस्तकालय खाली है।';
	@override String get noItemsMatchFilters => 'कोई आइटम सक्रिय फ़िल्टर के अनुरूप नहीं है';
	@override String get resetFilters => 'फ़िल्टर पुनर्स्थापित करें';
	@override String get all => 'सारे';
	@override String get clearAll => 'सब स्पष्ट';
	@override String scanLibraryConfirm({required Object title}) => 'क्या आप निश्चित हैं कि आप "${title}" स्कैन करना चाहते हैं?';
	@override String analyzeLibraryConfirm({required Object title}) => 'क्या आप निश्चित हैं कि आप "${title}" का विश्लेषण करना चाहते हैं?';
	@override String refreshMetadataConfirm({required Object title}) => 'क्या आप निश्चित हैं कि आप "${title}" के लिए मेटाडेटा को नवीनीकृत करना चाहते हैं?';
	@override String emptyTrashConfirm({required Object title}) => 'क्या आप निश्चित हैं कि आप "${title}" के लिए खाली कचरा चाहते हैं?';
	@override String get manageLibraries => 'पुस्तकालयों का प्रबंधन';
	@override String get sort => 'Sort के लिए';
	@override String get sortBy => 'सेट करें';
	@override String get filters => 'फ़िल्टर';
	@override String get confirmActionMessage => 'क्या आप निश्चित हैं कि आप इस कार्रवाई को पूरा करना चाहते हैं?';
	@override String get showLibrary => 'पुस्तकालय दिखाएं';
	@override String get hideLibrary => 'पुस्तकालय छिपाना';
	@override String get libraryOptions => 'पुस्तकालय विकल्प';
	@override String get content => 'पुस्तकालय सामग्री';
	@override String get selectLibrary => 'पुस्तकालय चुनें';
	@override String filtersWithCount({required Object count}) => 'फ़िल्टर (${count})';
	@override String get noRecommendations => 'कोई प्रस्ताव उपलब्ध नहीं है';
	@override String get noCollections => 'इस पुस्तकालय में कोई संग्रह नहीं';
	@override String get noFoldersFound => 'कोई फ़ोल्डर नहीं मिला';
	@override String get folders => 'फ़ोल्डर';
	@override late final _Translations$libraries$tabs$hi tabs = _Translations$libraries$tabs$hi._(_root);
	@override late final _Translations$libraries$groupings$hi groupings = _Translations$libraries$groupings$hi._(_root);
	@override late final _Translations$libraries$filterCategories$hi filterCategories = _Translations$libraries$filterCategories$hi._(_root);
	@override late final _Translations$libraries$sortLabels$hi sortLabels = _Translations$libraries$sortLabels$hi._(_root);
	@override late final _Translations$libraries$advancedFilters$hi advancedFilters = _Translations$libraries$advancedFilters$hi._(_root);
	@override late final _Translations$libraries$selection$hi selection = _Translations$libraries$selection$hi._(_root);
}

// Path: about
class _Translations$about$hi extends Translations$about$en {
	_Translations$about$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'के बारे';
	@override String get openSourceLicenses => 'Open Source लाइसेंस';
	@override String versionLabel({required Object version}) => 'संस्करण ${version}';
	@override String get appDescription => 'फ्लोटर के लिए एक सुंदर Plex, Jellyfin, और Emby क्लाइंट';
	@override String get viewLicensesDescription => 'तीसरे पक्ष की पुस्तकालयों के लाइसेंस देखें';
	@override String get privacyPolicy => 'गोपनीयता नीति';
}

// Path: serverSelection
class _Translations$serverSelection$hi extends Translations$serverSelection$en {
	_Translations$serverSelection$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'कोई सर्वर नहीं मिला ${username} (${email}) के लिए';
	@override String failedToLoadServers({required Object error}) => 'सर्वरों को लोड करने में विफलता: ${error}';
	@override String get noValidServers => 'इस खाते में कोई उपयोगी सर्वर नहीं पाए गए';
}

// Path: hubDetail
class _Translations$hubDetail$hi extends Translations$hubDetail$en {
	_Translations$hubDetail$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'शीर्षक';
	@override String get releaseYear => 'रिलीज वर्ष';
	@override String get dateAdded => 'तिथि जोड़ी गई';
	@override String get rating => 'रेटिंग';
	@override String get noItemsFound => 'कोई आइटम नहीं मिला';
}

// Path: logs
class _Translations$logs$hi extends Translations$logs$en {
	_Translations$logs$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'स्पष्ट लॉग';
	@override String get copyLogs => 'लॉग कॉपी करें';
	@override String get uploadLogs => 'लॉग अपलोड करें';
	@override String get saveLogs => 'फ़ाइल में लॉग्स को सहेजें';
	@override String logsSaved({required Object path}) => 'लॉग ${path} पर संग्रहीत';
	@override String get saveLogsFailed => 'लॉग फ़ाइल को बचाने में सक्षम नहीं था।';
}

// Path: detail
class _Translations$detail$hi extends Translations$detail$en {
	_Translations$detail$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => '${time} पर समाप्त';
}

// Path: startup
class _Translations$startup$hi extends Translations$startup$en {
	_Translations$startup$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'PlezyNG शुरू नहीं किया जा सकता';
	@override String get failedBody => 'स्टार्टअप के दौरान कुछ गलत हो गया. नीचे दिए गए विवरण बताते हैं कि क्या विफल रहा।';
	@override String get failedBodyRepairable => 'PlezyNG की सहेजी हुई सेटिंग्स फ़ाइल क्षतिग्रस्त है। ऐप शुरू होने से पहले इसे फिर से बनाना होगा। दोबारा कोशिश करने से मदद नहीं मिलेगी — स्टोरेज की मरम्मत का विकल्प चुनें।';
	@override String get phaseLabel => 'कदम';
	@override String get showDetails => 'विवरण दिखाएं';
	@override String get hideDetails => 'विवरण छिपाएं';
	@override String get copyDetails => 'विवरण कॉपी करें';
	@override String get detailsCopied => 'Clipboard में कॉपी किए गए विवरण';
	@override String get uploadDetails => 'अपलोड करें विवरण';
	@override String get repairStorage => 'भंडारण की मरम्मत';
	@override String get repairTitle => 'संग्रहीत डेटा की मरम्मत?';
	@override String get repairBodyCommon => 'PlezyNG की सेटिंग्स फ़ाइल क्षतिग्रस्त है और इसे पढ़ा नहीं जा सकता है. मरम्मत प्रत्येक सेटिंग को डिफ़ॉल्ट रूप से पुनर्स्थापित करती है.';
	@override String get repairBodyOneCredential => 'एक सहेजा हुआ साइन-इन क्षतिग्रस्त है और पढ़ा नहीं जा सकता है. मरम्मत केवल उस एक को हटा देती है; आपके अन्य सेटिंग्स अकेले छोड़ दिए जाते हैं.';
	@override String get repairBodySignInsKept => 'आपके सर्वर और प्रोफ़ाइल में साइन-इन स्थिति बनी रहनी चाहिए।';
	@override String get repairBodySignInsLost => 'सहेजी गई साइन-इन जानकारी की सुरक्षा करने वाली कुंजी इस फ़ाइल से पुनर्प्राप्त नहीं हो सकती। इसलिए हर सर्वर और प्रोफ़ाइल में फिर से साइन इन करना होगा। आपके मीडिया सर्वर पर कुछ भी प्रभावित नहीं होगा।';
	@override String get repairBodySessionsUncertain => 'ट्रैकर (MAL, AniList, Simkl, Trakt) और Seerr को अलग से संग्रहीत किया जाता है और जीवित रह सकता है या नहीं हो सकता है. PlezyNG आपको सटीक रूप से बताएगा कि यह क्या रखता है.';
	@override String get repairConfirm => 'सुधार';
	@override String get repairSucceeded => 'भंडारण सुधार';
	@override String get repairNeedsRestart => 'भंडारण सुधार - पुनरारंभ आवश्यक';
	@override String get restartRequiredBody => 'आपका डेटा ठीक कर दिया गया है, लेकिन उसका उपयोग करने के लिए PlezyNG को फिर से चालू करना होगा। PlezyNG बंद करके दोबारा खोलें।';
	@override String get quitPlezy => 'क्यूट PlezyNG';
	@override String get repairFailed => 'मरम्मत असफल';
	@override String get repairKeptSignIns => 'आपके सर्वर और प्रोफ़ाइल में अभी भी साइन इन है।';
	@override String get repairLostSignIns => 'सहेजी गई साइन-इन जानकारी की सुरक्षा करने वाली कुंजी पुनर्प्राप्त नहीं हो सकी। हर सर्वर और प्रोफ़ाइल में फिर से साइन इन करना होगा।';
	@override String get repairLostSessions => 'कम से कम एक ट्रैकर या Seerr कनेक्शन खो गया है और फिर से कनेक्ट किया जाना चाहिए।';
	@override String get backupTitle => 'क्षतिग्रस्त फ़ाइल का एक प्रति बनाए रखा गया है';
	@override String get backupWarning => 'इसमें आपकी साइन-इन जानकारी है। इसे अपलोड या साझा न करें।';
	@override String get deleteBackup => 'कॉपी हटाएँ';
	@override String get backupDeleted => 'कॉपी हटा दी गई है।';
	@override String get previousFailureTitle => 'PlezyNG पिछली बार शुरू करने में विफल';
}

// Path: licenses
class _Translations$licenses$hi extends Translations$licenses$en {
	_Translations$licenses$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'संबंधित पैकेज';
	@override String get license => 'अनुमति';
	@override String licenseNumber({required Object number}) => 'लाइसेंस ${number}';
	@override String licensesCount({required Object count}) => '${count} अनुमतिएँ';
}

// Path: navigation
class _Translations$navigation$hi extends Translations$navigation$en {
	_Translations$navigation$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'पुस्तकालय';
	@override String get downloads => 'डाउनलोड';
	@override String get liveTv => 'लाइव टीवी';
	@override String get explore => 'खोजें';
}

// Path: explore
class _Translations$explore$hi extends Translations$explore$en {
	_Translations$explore$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override late final _Translations$explore$mdblistShelves$hi mdblistShelves = _Translations$explore$mdblistShelves$hi._(_root);
	@override String get title => 'खोजें';
	@override String get selectSource => 'स्रोत चुनें';
	@override late final _Translations$explore$rows$hi rows = _Translations$explore$rows$hi._(_root);
	@override late final _Translations$explore$status$hi status = _Translations$explore$status$hi._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} संस्करण',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} घटनाएं',
	);
	@override String get cast => 'कास्टिंग';
	@override String get characters => 'चरित्र';
	@override String get addToWatchlist => 'Watchlist में शामिल हों';
	@override String get removeFromWatchlist => 'Watchlist से हटाएँ';
	@override String get addedToWatchlist => 'watchlist में शामिल';
	@override String get removedFromWatchlist => 'watchlist से हटाए गए';
	@override String get watchlistUpdateFailed => 'watchlist को अपडेट नहीं किया जा सकता';
	@override String get watchlistNoMatch => 'इस आइटम को एक वॉचलिस्ट में फिट नहीं किया जा सकता';
	@override String get notInLibrary => 'अपनी पुस्तकालय में नहीं';
	@override String get inTheseLibraries => 'इन पुस्तकालयों';
	@override String get checkingLibrary => 'अपनी पुस्तकालय की जांच करें।';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} सर्वर की जांच नहीं की जा सकती',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} सर्वरों की जांच नहीं की जा सकती',
	);
	@override String get emptyTitle => 'यहाँ अभी तक कुछ नहीं';
	@override String emptyMessage({required Object source}) => '${source} से टुकड़े यहाँ दिखाई देंगे जब उनके पास सामग्री हो।';
	@override String searchHint({required Object source}) => 'खोज ${source}';
	@override String searchEmpty({required Object query}) => '"${query}" के लिए कोई परिणाम नहीं';
	@override String searchPrompt({required Object source}) => 'फिल्मों और शोों की खोज ${source} पर की जाती है।';
	@override String get searchFailed => 'खोज विफल हो गई. अपने कनेक्शन की जांच करें और फिर से कोशिश करें.';
	@override late final _Translations$explore$badge$hi badge = _Translations$explore$badge$hi._(_root);
	@override late final _Translations$explore$stats$hi stats = _Translations$explore$stats$hi._(_root);
	@override late final _Translations$explore$season$hi season = _Translations$explore$season$hi._(_root);
	@override late final _Translations$explore$format$hi format = _Translations$explore$format$hi._(_root);
	@override late final _Translations$explore$sourceMaterial$hi sourceMaterial = _Translations$explore$sourceMaterial$hi._(_root);
	@override late final _Translations$explore$creditRole$hi creditRole = _Translations$explore$creditRole$hi._(_root);
	@override late final _Translations$explore$relation$hi relation = _Translations$explore$relation$hi._(_root);
	@override String broadcast({required Object day, required Object time}) => 'Airs ${day} पर ${time}';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => 'Airs ${day} पर ${time} ${timezone}';
	@override late final _Translations$explore$detail$hi detail = _Translations$explore$detail$hi._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} परिणाम',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} परिणाम',
	);
}

// Path: liveTv
class _Translations$liveTv$hi extends Translations$liveTv$en {
	_Translations$liveTv$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'लाइव टीवी';
	@override String get guide => 'गाइड';
	@override String get noChannels => 'कोई चैनल उपलब्ध नहीं';
	@override String get noDvr => 'किसी भी सर्वर पर स्थापित कोई डीवीआर नहीं है';
	@override String get serverUnavailable => 'लाइव टीवी सर्वर उपलब्ध नहीं है।';
	@override String get serverNotConnected => 'लाइव टीवी सर्वर कनेक्ट नहीं है।';
	@override String get noPrograms => 'कोई प्रोग्राम डेटा उपलब्ध नहीं';
	@override String get liveStreamFailed => 'लाइव स्ट्रीम असफल';
	@override String get unknownProgram => 'अज्ञात कार्यक्रम';
	@override String get timelineLiveProgram => 'लाइव प्रोग्राम (प्लेबैक इस प्रोग्राम के बाहर हो सकता है)';
	@override String get timelineBuffer => 'बफर टाइमलाइन';
	@override String get timelineUnavailable => 'समय सीमा उपलब्ध नहीं';
	@override String get timelineEstimated => 'Playback के बारे में';
	@override String get timelinePending => 'तलाश में';
	@override String get timelineStale => 'समय निर्धारित किया जा सकता है';
	@override String get unknownHub => 'अज्ञात';
	@override String get unknownError => 'अज्ञात गलती';
	@override String channelNumber({required Object number}) => 'चैनल ${number}';
	@override String get unknownChannel => 'अज्ञात चैनल';
	@override String get live => 'लाइव';
	@override String get premiereBadge => 'नई';
	@override String get reloadGuide => 'Reload गाइड';
	@override String get searchGuide => 'खोज गाइड';
	@override String get searchHint => 'खोज चैनलों और प्रोग्राम';
	@override String searchNoResults({required Object query}) => '"${query}" के लिए कोई मैच नहीं';
	@override String get channelsSection => 'चैनल';
	@override String get programsSection => 'कार्यक्रमों';
	@override String get now => 'अब';
	@override String get today => 'आज';
	@override String get tomorrow => 'कल';
	@override String get midnight => 'आधी रात';
	@override String get overnight => 'रात में';
	@override String get morning => 'सुबह';
	@override String get daytime => 'दिन का समय';
	@override String get evening => 'शाम को';
	@override String get lateNight => 'देर रात';
	@override String get whatsOn => 'पर क्या है';
	@override String get watchChannel => 'चैनल देखें';
	@override String get favorites => 'पसंदीदा';
	@override String get reorderFavorites => 'पसंदीदा रिकॉर्ड';
	@override String get noFavoriteChannels => 'कोई पसंदीदा चैनल नहीं';
	@override String get noFavoriteChannelsHint => 'सभी चैनलों को दिखाएं, फिर लंबे समय तक एक चैनल दबाएं ताकि इसे अपने पसंदीदा में जोड़ा जा सके।';
	@override String get showAllChannels => 'सभी चैनलों को दिखाएं';
	@override String get favoritesLoadFailed => 'पसंदीदा लोड नहीं कर सकते. अपने कनेक्शन की जांच करें और फिर से कोशिश करें.';
	@override String get favoritesUpdateFailed => 'पसंदीदा अपडेट नहीं कर सकते. अपने कनेक्शन की जांच करें और फिर से कोशिश करें.';
	@override String get joinSession => 'प्रगति में सत्र में शामिल हों';
	@override String watchFromStart({required Object minutes}) => 'शुरुआत से देखो (${minutes} मिनट पहले)';
	@override String get watchLive => 'देखें लाइव';
	@override String get goToLive => 'जीने जाओ';
	@override String get record => 'रिकॉर्ड';
	@override String get recordEpisode => 'रिकॉर्ड एपिसोड';
	@override String get recordSeries => 'रिकॉर्ड सीरीज';
	@override String get recordOptions => 'रिकॉर्ड विकल्प';
	@override String get saveTo => 'बचाने के लिए';
	@override String get recordings => 'रिकॉर्ड';
	@override String get scheduledRecordings => 'कार्यक्रम';
	@override String get recordingRules => 'रिकॉर्डिंग नियम';
	@override String get noScheduledRecordings => 'रिकॉर्ड करने के लिए कोई योजना नहीं';
	@override String get manageRecording => 'रिकॉर्डिंग प्रबंधन';
	@override String get cancelRecording => 'रिकॉर्डिंग रद्द करें';
	@override String get cancelRecordingTitle => 'इस रिकॉर्डिंग को रद्द करें?';
	@override String cancelRecordingMessage({required Object title}) => '${title} अब रिकॉर्ड नहीं किया जाएगा।';
	@override String get deleteRule => 'नियम हटाएँ';
	@override String get deleteRuleTitle => 'रिकॉर्डिंग नियम को हटा दें?';
	@override String deleteRuleMessage({required Object title}) => '${title} के भविष्य के एपिसोडों को रिकॉर्ड नहीं किया जाएगा।';
	@override String get recordingScheduled => 'रिकॉर्डिंग योजना';
	@override String get alreadyScheduled => 'यह कार्यक्रम पहले से ही तैयार है।';
	@override String get dvrAdminRequired => 'डीवीआर सेटिंग्स को एक एडमैन खाता की आवश्यकता होती है';
	@override String get recordingFailed => 'रिकॉर्डिंग की योजना नहीं बना सकती';
	@override String get recordingTargetMissing => 'पुस्तकालय रिकॉर्डिंग का निर्धारण नहीं कर सकता';
	@override String get recordNotAvailable => 'रिकॉर्डिंग इस कार्यक्रम के लिए उपलब्ध नहीं है';
	@override String get recordingCancelled => 'रिकॉर्डिंग रद्द';
	@override String get recordingRuleDeleted => 'रिकॉर्डिंग नियम हटा दिया गया';
	@override String get processRecordingRules => 'नियमों का पुनर्विचार';
	@override String get recordingInProgress => 'अब रिकॉर्ड';
	@override String recordingsCount({required Object count}) => '${count} अनुसूचित';
	@override String get editRule => 'Edit नियम';
	@override String get editRuleAction => 'संपादित करें';
	@override String get recordingRuleUpdated => 'रिकॉर्डिंग नियम अद्यतन';
	@override String get guideReloadRequested => 'रेफ्रिजरेटर की मांग';
	@override String get guideReloadFailed => 'मार्गदर्शिका को साफ नहीं किया जा सकता';
	@override String get rulesProcessRequested => 'अनुरोध किया गया पुन: मूल्यांकन';
	@override String get rulesProcessFailed => 'रिकॉर्डिंग नियमों का पुन: मूल्यांकन नहीं किया जा सकता';
	@override String get recordShow => 'रिकॉर्ड शो';
	@override late final _Translations$liveTv$recordSettings$hi recordSettings = _Translations$liveTv$recordSettings$hi._(_root);
	@override String startingInMinutes({required Object minutes}) => '${minutes} मिनट में शुरू';
	@override String dayAtTime({required Object day, required Object time}) => '${day} पर ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} वापस अवास्तविक लाइव टीवी प्लेबैक डेटा';
	@override String get failedToStartChannel => 'लाइव चैनल शुरू नहीं किया जा सकता';
	@override String get failedToBuildStreamUrl => 'स्ट्रीम URL नहीं बना सकते';
	@override String playbackStartFailed({required Object reason}) => 'चैनल शुरू नहीं किया जा सकता: ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'चैनल नहीं बदल सकता: ${reason}';
}

// Path: collections
class _Translations$collections$hi extends Translations$collections$en {
	_Translations$collections$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'संग्रह';
	@override String get collection => 'संग्रह';
	@override String get empty => 'संग्रह खाली है';
	@override String get deleteCollection => 'संग्रह हटाएँ';
	@override String deleteConfirm({required Object title}) => '"${title}" मिटाएँ? इस कार्रवाई को वापस नहीं किया जा सकता।';
	@override String get deleted => 'संग्रह हटा दिया';
	@override String get deleteFailed => 'संग्रह को हटाने में विफलता';
	@override String deleteFailedWithError({required Object error}) => 'संग्रह को हटाने में विफलता: ${error}';
	@override String get selectCollection => 'चयनित संग्रह';
	@override String get collectionName => 'संग्रह का नाम';
	@override String get enterCollectionName => 'संग्रह का नाम दर्ज करें';
	@override String get addedToCollection => 'संग्रह में जोड़ा';
	@override String get errorAddingToCollection => 'संग्रह में जोड़ने में विफल';
	@override String get created => 'संग्रह बनाया';
	@override String get removeFromCollection => 'संग्रह से हटाएँ';
	@override String removeFromCollectionConfirm({required Object title}) => 'इस संग्रह से “${title}” हटाएँ?';
	@override String get removedFromCollection => 'संग्रह से हटाए गए';
	@override String get removeFromCollectionFailed => 'संग्रह से बाहर निकलने में विफलता';
	@override String removeFromCollectionError({required Object error}) => 'संग्रह से त्रुटि हटाने: ${error}';
	@override String get searchCollections => 'खोज संग्रह...';
}

// Path: playlists
class _Translations$playlists$hi extends Translations$playlists$en {
	_Translations$playlists$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'प्लेलिस्ट';
	@override String get playlist => 'प्लेलिस्ट';
	@override String get noPlaylists => 'कोई प्लेलिस्ट नहीं मिला';
	@override String get create => 'प्लेलिस्ट बनाएं';
	@override String get playlistName => 'Playlist नाम';
	@override String get enterPlaylistName => 'प्लेलिस्ट नाम दर्ज करें';
	@override String get delete => 'Playlist के बारे में';
	@override String get removeItem => 'Playlist से हटाएँ';
	@override String get smartPlaylist => 'स्मार्ट प्लेलिस्ट';
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} आइटम',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} आइटम',
	);
	@override String get emptyPlaylist => 'यह प्लेलिस्ट खाली है';
	@override String get deleteConfirm => 'प्लेलिस्ट को हटा दें?';
	@override String deleteMessage({required Object name}) => 'क्या आप निश्चित हैं कि आप "${name}" को हटाना चाहते हैं?';
	@override String get created => 'Playlist बनाया गया';
	@override String get deleted => 'Playlist हटा दिया गया';
	@override String get itemAdded => 'Playlist में शामिल';
	@override String get itemRemoved => 'Playlist से हटाए गए';
	@override String get selectPlaylist => 'Playlist का चयन करें';
	@override String get searchPlaylists => 'खेलों की खोज...';
	@override String get errorCreating => 'Playlist बनाने में असफल';
	@override String get errorDeleting => 'Playlist को हटाने में विफलता';
	@override String get errorLoading => 'प्लेलिस्ट लोड करने में विफल';
	@override String get errorAdding => 'Playlist में शामिल करने में असफल';
	@override String get errorReordering => 'प्लेलिस्ट आइटम को पुनर्स्थापित करने में विफलता';
	@override String get errorRemoving => 'Playlist से हटाने में असफल';
}

// Path: music
class _Translations$music$hi extends Translations$music$en {
	_Translations$music$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'एल्बम पर जाएं';
	@override String get goToArtist => 'कलाकार के लिए जाओ';
	@override String get instantMix => 'मिश्रण मिक्स';
	@override String get playNext => 'अगला खेल';
	@override String get addToQueue => 'क्यूए में जोड़ें';
	@override String discNumber({required Object n}) => 'डिस्क ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ट्रैक',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ट्रैक',
	);
	@override String get nowPlaying => 'अब खेलते हैं';
	@override String playingFrom({required Object title}) => 'खेलने के लिए ${title}';
	@override String get queue => 'क्यूए';
	@override String get clearQueue => 'कतार साफ़ करें';
	@override String get lyrics => 'लिंग';
	@override String get visualizer => 'दृश्य';
	@override String get visualizerProfileLoading => 'ट्रैक विश्लेषण पढ़ने के लिए ...';
	@override String get visualizerAmbientMotion => 'पर्यावरण आंदोलन';
	@override String get visualizerPlexLoudness => 'Plex ध्वनि';
	@override String get visualizerPreviousPreset => 'Previous दृश्य शैली';
	@override String get visualizerNextPreset => 'अगला दृश्य शैली';
	@override String get visualizerPresetAurora => 'Aurora के बारे में';
	@override String get visualizerPresetBloom => 'ब्लू';
	@override String get visualizerPresetOrbitals => 'Orbitals के बारे में';
	@override String get visualizerPresetPrism => 'प्रिस्म';
	@override String get visualizerPresetTunnel => 'टनल';
	@override String get visualizerPresetTrackMap => 'ट्रैक मैप';
	@override String get noLyrics => 'कोई लिंग उपलब्ध नहीं है';
	@override String get sleepTimer => 'नींद का समय';
	@override String get sleepTimerEndOfTrack => 'ट्रैक का अंत';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} मिनट',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} मिनट',
	);
	@override String get stopPlayback => 'प्लेबैक बंद करें';
	@override String get previousTrack => 'पिछला ट्रैक';
	@override String get nextTrack => 'आगे धावन पथ';
	@override String get repeat => 'बार-बार';
	@override String get repeatAll => 'सभी को दोहराएं';
	@override String get repeatOne => 'एक बार दोहराएं';
	@override String get instantMixNoServer => 'कोई सर्वर एक त्वरित मिश्रण के लिए उपलब्ध नहीं है';
	@override String get instantMixFailed => 'मिश्रण को लोड करने में विफलता';
	@override String get instantMixEmpty => 'तुरंत मिश्रण कोई ट्रैक के साथ वापस आया';
	@override String noAudioUrl({required Object track}) => 'कोई ऑडियो URL उपलब्ध नहीं है ${track} के लिए';
	@override late final _Translations$music$discography$hi discography = _Translations$music$discography$hi._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$hi extends Translations$watchTogether$en {
	_Translations$watchTogether$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'साथ देखें';
	@override String get description => 'दोस्तों और परिवार के साथ सिंक्रनाइज़ में सामग्री देखें';
	@override String get createRoom => 'कमरे बनाएं';
	@override String get creatingRoom => 'कमरे का निर्माण...';
	@override String get joinRoom => 'कमरे में शामिल';
	@override String get joiningRoom => 'कमरे में शामिल...';
	@override String get connecting => 'कनेक्ट...';
	@override String get relayPublic => 'कमरे सार्वजनिक Open Watch पार्टी रिलीज का उपयोग करते हैं।';
	@override String relayCustom({required Object url}) => 'कमरे ${url} पर अपने रिले का उपयोग करते हैं।';
	@override String get recentRooms => 'हाल के कमरे';
	@override String get roomActions => 'कमरे के कार्य';
	@override String get renameRoom => 'कमरे का नाम';
	@override String get removeRoom => 'हटाना';
	@override String get enterRoomCode => 'मेजबान से 6 अक्षर कोड दर्ज करें।';
	@override String get roomCode => 'कमरे का कोड';
	@override String get paste => 'पास्ता';
	@override String get noCodeInClipboard => 'क्लिपबोर्ड में कोई कमरे कोड नहीं है';
	@override String get copyCode => 'कॉपी कोड';
	@override String get codeCopied => 'कमरे का कोड कॉपी';
	@override String get shareInvite => 'आमंत्रण साझा';
	@override String get inviteCopied => 'इसे कॉपी करें. इसे एक संदेश में डालें.';
	@override String inviteMessage({required Object code}) => 'PlezyNG में मेरे घड़ी एक साथ कमरे में शामिल हों: घड़ी एक साथ खोलें, शामिल कमरे का चयन करें और ${code} में प्रवेश करें।';
	@override String get openSessionControls => 'Open Watch एक साथ सत्र नियंत्रण';
	@override String get reconnecting => 'फिर से कनेक्ट...';
	@override String get reconnectingDescription => 'कनेक्शन बंद हो गया. आप स्वचालित रूप से कमरे में प्रवेश करते हैं.';
	@override String get connected => 'कनेक्ट';
	@override String get disconnected => 'विघटित';
	@override String get youAreHost => 'आप होस्ट हैं';
	@override String hostedBy({required Object name}) => 'संपादित करें ${name}';
	@override String get hostControlsPlayback => 'होस्ट नियंत्रण Playback';
	@override String get anyoneCanControl => 'कोई भी Playback को नियंत्रित कर सकता है';
	@override String get roomLocked => 'कमरे बंद';
	@override String get nowPlaying => 'अब खेलते हैं';
	@override String get nothingPlaying => 'खेलने के लिए कुछ नहीं';
	@override String get nothingPlayingHost => 'किसी भी पुस्तकालय से कुछ खेलने के लिए इसे कमरे के साथ साझा करें।';
	@override String get nothingPlayingGuest => 'जब मेजबान कुछ खेलता है, तो यह यहां खुलता है।';
	@override String get notShareable => 'इस वीडियो में कोई कैटलॉग मैच नहीं है, इसलिए केवल एक ही सर्वर तक पहुंचने वाले लोग इसे खेल सकते हैं।';
	@override String get searching => 'अपने पुस्तकालयों में इस वीडियो की तलाश में...';
	@override String get yourCopy => 'आपकी कॉपी';
	@override String get sharingYourCopy => 'आप अपनी कॉपी साझा कर रहे हैं';
	@override String playingOtherLength({required Object difference}) => 'अपने कॉपी को खेलने के लिए, ${difference}';
	@override String get mismatchTitle => 'आपकी कॉपी एक अलग लंबाई है';
	@override String mismatchDescription({required Object difference}) => 'आपका निकटतम कॉपी कमरे के वीडियो की तुलना में ${difference} है. यह एक और कटौती या संस्करण हो सकता है.';
	@override String get playAnyway => 'किसी भी तरह से खेल';
	@override String get chooseAnotherCopy => 'एक और कॉपी चुनें';
	@override String get dontPlay => 'नहीं खेलें';
	@override String get unavailableTitle => 'आप इस वीडियो को नहीं रखते हैं';
	@override String get unavailableDescription => 'PlezyNG अपने पुस्तकालयों में इसे नहीं पाया. खुद को एक प्रति चुनें या फिर से खोजें.';
	@override String get chooseCopy => 'एक कॉपी चुनें';
	@override String get searchAgain => 'फिर से खोजें';
	@override String get noCandidates => 'आपके पुस्तकालयों में कोई प्रतियां नहीं मिलीं।';
	@override String get choiceFailed => 'कमरे के लिए इस प्रतिलिपि को नहीं खेला जा सकता';
	@override String lengthLonger({required Object duration}) => '${duration} अधिक';
	@override String lengthShorter({required Object duration}) => '${duration} छोटे';
	@override String get lengthSame => 'एक ही लंबाई';
	@override String get lengthUnknown => 'लंबाई अज्ञात';
	@override String get joinCurrentPlayback => 'वर्तमान Playback में शामिल हों';
	@override String get joinCurrentPlaybackDescription => 'होस्टिंग में वापस जाओ जो होस्टिंग वर्तमान में देख रहा है';
	@override String get stopMedia => 'हर किसी के लिए वीडियो बंद करें';
	@override String get syncOffset => 'सिंक्रनाइज़ेशन Offset';
	@override String get syncOffsetDescription => 'अपने वीडियो को स्थानांतरित करें यदि यह कमरे के सामने या पीछे चलता है।';
	@override String offsetHint({required Object difference}) => 'आपका कॉपी कमरे के वीडियो की तुलना में ${difference} है।';
	@override String applyDifference({required Object offset}) => 'उपयोग करें ${offset}';
	@override String get offsetMinusSecond => '1 एस';
	@override String get offsetMinusTenth => '100 एमएस';
	@override String get offsetPlusTenth => '+ 100 एमएस';
	@override String get offsetPlusSecond => '+ 1 एस';
	@override String get participants => 'प्रतिभागियों';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} प्रतिभागियों',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} प्रतिभागियों',
	);
	@override String get hostBadge => 'मेहमान';
	@override String nameYou({required Object name}) => '${name} (आप)';
	@override String get playerIdle => 'आईडीएल';
	@override String get playerLoading => 'लोड';
	@override String get playerReady => 'तैयार';
	@override String get playerBuffering => 'बफिंग';
	@override String get matchSearching => 'खोजें';
	@override String get matchMatched => 'वीडियो है';
	@override String get matchMismatched => 'अलग लंबाई';
	@override String get matchUnavailable => 'वीडियो नहीं है';
	@override String participantOffset({required Object offset}) => 'ऑफ़सेट ${offset}';
	@override String get makeHost => 'मेजबान बनाएं';
	@override String get makeHostQuestion => 'हस्तांतरण होस्ट?';
	@override String makeHostConfirm({required Object name}) => '${name} प्लेबैक को नियंत्रित करेगा और सत्र को हर किसी के लिए चलाएगा।';
	@override String get transfer => 'स्थानांतरण';
	@override String get removeParticipant => 'कमरे से बाहर निकलना';
	@override String removeParticipantQuestion({required Object name}) => '${name} को हटा दें।';
	@override String removeParticipantConfirm({required Object name}) => '${name} कमरे से बाहर निकलता है. वे कोड के साथ फिर से शामिल हो सकते हैं जब तक कि आप कमरे को बंद न करें.';
	@override String get remove => 'हटाना';
	@override String get roomSettings => 'कमरे सेटिंग्स';
	@override String get letEveryoneControl => 'हर कोई Playback को नियंत्रित करता है';
	@override String get lockRoom => 'लॉक रूम';
	@override String get lockRoomDescription => 'कोई नया नहीं शामिल हो सकता';
	@override String get leaveRoom => 'कमरे छोड़ें';
	@override String get leaveRoomQuestion => 'कमरे छोड़ने के लिए?';
	@override String get leaveRoomConfirm => 'आप कमरे कोड के साथ फिर से शामिल हो सकते हैं।';
	@override String get leave => 'छोड़ो';
	@override String get endRoom => 'अंतिम कमरे';
	@override String get endRoomQuestion => 'कमरे का अंत?';
	@override String get endRoomConfirm => 'यह हर किसी के लिए कमरे का अंत है।';
	@override String get end => 'अंत';
	@override String get playBlockedTitle => 'Playback शुरू नहीं हुआ';
	@override String get playBlockedDescription => 'कमरे के साथ देखने के लिए प्रिंट खेलना शुरू करें।';
	@override late final _Translations$watchTogether$notices$hi notices = _Translations$watchTogether$notices$hi._(_root);
	@override late final _Translations$watchTogether$ended$hi ended = _Translations$watchTogether$ended$hi._(_root);
	@override late final _Translations$watchTogether$errors$hi errors = _Translations$watchTogether$errors$hi._(_root);
	@override String untitledEpisode({required Object number}) => 'पदों की संख्या ${number}';
}

// Path: downloads
class _Translations$downloads$hi extends Translations$downloads$en {
	_Translations$downloads$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'डाउनलोड';
	@override String get manage => 'प्रबंधन';
	@override String get tvShows => 'टीवी शो';
	@override String get movies => 'फ़िल्में';
	@override String get music => 'संगीत';
	@override String tracksQueued({required Object count}) => '${count} ट्रैक डाउनलोड करने के लिए जोड़ा गया है';
	@override String get noDownloads => 'अभी तक डाउनलोड नहीं';
	@override String get noDownloadsDescription => 'डाउनलोड की गई सामग्री ऑफ़लाइन देखने के लिए यहां दिखाई देगी';
	@override String get downloadNow => 'डाउनलोड करें';
	@override String get deleteDownload => 'डाउनलोड करें';
	@override String get retryDownload => 'रिट्री डाउनलोड';
	@override String get downloadQueued => 'डाउनलोड करने के लिए Queued';
	@override String get downloadResumed => 'डाउनलोड करें पुनः';
	@override String get serverErrorBitrate => 'सर्वर त्रुटि: फ़ाइल रिमोट बिट्रेट सीमा से अधिक हो सकती है';
	@override String get storageFull => 'डाउनलोड उपलब्ध भंडारण की रक्षा करने के लिए बंद कर दिया. कुछ स्थान मुक्त करें या डाउनलोड स्थान का चयन करें, फिर रिटर्न करें.';
	@override String get storageUnavailable => 'डाउनलोड बंद हो गए क्योंकि उपलब्ध भंडारण की जांच नहीं की जा सकती थी. डाउनलोड स्थान की जांच करें, फिर वापस जाएं.';
	@override String episodesQueued({required Object count}) => '${count} एपिसोड डाउनलोड करने के लिए जोड़े गए';
	@override String get downloadDeleted => 'डाउनलोड करें हटाया';
	@override String deleteConfirm({required Object title}) => 'इस डिवाइस से "${title}" को हटा दें?';
	@override String get deleteCollectionDownloads => 'डाउनलोड करें';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => 'इस डिवाइस से “${title}” के सभी डाउनलोड मिटाएँ?';
	@override String get collectionDownloadsDeleted => 'डाउनलोड हटाए गए';
	@override String get cancelledDownloadTitle => 'डाउनलोड रद्द';
	@override String get cancelledDownloadMessage => 'यह डाउनलोड रद्द कर दिया गया है. आप क्या करना चाहते हैं?';
	@override String get allEpisodesAlreadyDownloaded => 'सभी घटनाएं अब डाउनलोड की गई हैं';
	@override String get resumeDownload => 'डाउनलोड करें';
	@override String get cancelledDownload => 'डाउनलोड रद्द';
	@override String syncingFile({required Object file, required Object status}) => '${file} (सेंसिंग ${status})';
	@override String downloadedFileClickToComplete({required Object file}) => 'डाउनलोड ${file} - पूरा करने के लिए क्लिक करें';
	@override String get partialDownloadClickToComplete => 'डाउनलोड करें - पूरा करने के लिए क्लिक करें';
	@override String get deleting => 'हटाने...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => '${title}... (${current} से ${total}) को हटाना';
	@override String get queuedTooltip => 'क्विड';
	@override String queuedFilesTooltip({required Object files}) => 'कुल पदों की संख्या ${files}';
	@override String get downloadingTooltip => 'डाउनलोड...';
	@override String downloadingFilesTooltip({required Object files}) => 'डाउनलोड करें ${files}';
	@override String get noDownloadsTree => 'कोई डाउनलोड नहीं';
	@override String get pauseAll => 'सबको आराम';
	@override String get resumeAll => 'सभी को संक्षेप में';
	@override String get retryAll => 'सबको वापस';
	@override String get retryFailed => 'असफल डाउनलोड करें';
	@override String get deleteAll => 'डिलीट सभी';
	@override String get selectVersion => 'चुनें संस्करण';
	@override String get allEpisodes => 'सभी प्रकरण';
	@override String get unwatchedOnly => 'अनदेखा केवल';
	@override String nextNUnwatched({required Object count}) => 'अगला ${count} अनदेखा किया गया';
	@override String get customAmount => 'कस्टम राशि...';
	@override String get customAmountAny => 'प्रत्येक व्यक्ति की मात्रा (प्रत्येक व्यक्ति)';
	@override String get randomEpisodes => 'यादृच्छिक घटनाएं';
	@override String get includeSpecials => 'विशेषताएं शामिल हैं';
	@override String get howManyEpisodes => 'कितने एपिसोड?';
	@override String get invalidEpisodeCount => 'एक वैध एपिसोड गिनती दर्ज करें।';
	@override String get keepSynced => 'सिंथेटिक रहें';
	@override String get downloadOnce => 'डाउनलोड करें एक बार';
	@override String keepNUnwatched({required Object count}) => '${count} अनदेखा किया गया है';
	@override String get editSyncRule => 'सिंक्रनाइज़ेशन नियम';
	@override String get removeSyncRule => 'सिंक्रनाइज़ेशन नियम हटाएँ';
	@override String removeSyncRuleConfirm({required Object title}) => '"${title}" सिंक्रनाइज़ करना बंद करें? डाउनलोड किए गए एपिसोड को रखा जाएगा.';
	@override String removeListSyncRuleConfirm({required Object title}) => '"${title}" सिंक्रनाइज़ करना बंद करें?';
	@override String get deleteSyncRuleDownloads => 'साथ ही संबंधित डाउनलोड को भी हटा दें';
	@override String get deleteSyncRuleDownloadsDescription => 'अन्य सिंक्रनाइज़ेशन नियम या प्रोफ़ाइल द्वारा उपयोग किए गए डाउनलोड को रखा जाएगा।';
	@override String syncRuleCreated({required Object count}) => 'सिंक्रनाइज़ेशन नियम बनाया — ${count} अनदेखा किए गए एपिसोड बनाए रखें';
	@override String get syncRuleUpdated => 'सिंक्रनाइज़ेशन नियम अपडेट';
	@override String get syncRuleRemoved => 'सिंक्रनाइज़ेशन का नियम हटा दिया गया';
	@override String get syncRuleAndDownloadsRemoved => 'सिंक्रनाइज़ेशन नियम और संबंधित डाउनलोड हटाए गए';
	@override String get syncRuleCleanupBusy => 'सिंक्रनाइज़ेशन नियम वर्तमान में अद्यतन कर रहे हैं. एक पल में फिर से कोशिश करें.';
	@override String get syncRuleCleanupUnavailable => 'सर्वर को फिर से कनेक्ट करें और फिर से कोशिश करें, या डाउनलोड को हटाने के बिना नियम को हटा दें।';
	@override String syncedNewEpisodes({required Object count, required Object title}) => '${count} के लिए नए एपिसोडों को सिंक्रनाइज़ किया गया ${title}';
	@override String get syncNow => 'अब सिंक्रनाइज़ेशन';
	@override String get downloadsUpToDate => 'डाउनलोड अभी तक जारी है';
	@override String syncComplete({required Object queued, required Object removed}) => 'Sync complete · ${queued} queued, ${removed} हटाया गया';
	@override String get activeSyncRules => 'Sync नियम';
	@override String get reviewOrphanFiles => 'डाउनलोड करें Orphaned Downloads';
	@override String get orphanReviewTitle => 'डाउनलोड करें Orphaned Downloads';
	@override String get orphanReviewDescription => 'टैग की गई ये फ़ाइलें PlezyNG के डिफ़ॉल्ट, ऐप द्वारा प्रबंधित डाउनलोड फ़ोल्डर में हैं। इनका कोई मेल खाता डाउनलोड रिकॉर्ड या सक्रिय कार्य नहीं है। इन्हें मिटाने से पहले सूची जाँचें।';
	@override String orphanReviewCount({required Object count, required Object size}) => '${count} फ़ाइलें · ${size}';
	@override String orphanDeleteFiles({required Object count}) => 'फ़ाइलों को हटाने के लिए ${count}';
	@override String get orphanCleanupNone => 'कोई डाउनलोड फ़ाइल नहीं मिला';
	@override String get orphanCleanupFailed => 'PlezyNG सुरक्षित रूप से प्रबंधित डाउनलोड फ़ोल्डर को स्कैन नहीं कर सकता. कोई फ़ाइल हटाया नहीं गया.';
	@override String get orphanCleanupChanged => 'डाउनलोड सूची समीक्षा के दौरान बदल गई. सफाई से पहले फ़ाइलों की समीक्षा करें.';
	@override String orphanCleanupComplete({required Object count, required Object size}) => 'फ़ाइलों को हटा दिया गया ${count} अनाथ · ${size} मुक्त';
	@override String get noSyncRules => 'कोई सिंक्रनाइज़ेशन नियम';
	@override String get manageSyncRule => 'सिंक्रनाइज़ेशन प्रबंधन';
	@override String get editEpisodeCount => 'एपिसोड गिनती';
	@override String get editSyncFilter => 'फ़िल्टर सिंक्रनाइज़';
	@override String get syncAllItems => 'सभी वस्तुओं को संकलित करें';
	@override String get syncUnwatchedItems => 'अनदेखा किए गए वस्तुओं को सिंक्रनाइज़ करना';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'सर्वर: ${server} • ${status}';
	@override String get syncRuleAvailable => 'उपलब्ध';
	@override String get syncRuleOffline => 'ऑफलाइन';
	@override String get syncRuleSignInRequired => 'जरूरत में हस्ताक्षर';
	@override String get syncRuleAccessDenied => 'पहुंच से इनकार';
	@override String get syncRuleNotAvailableForProfile => 'वर्तमान प्रोफ़ाइल के लिए उपलब्ध नहीं';
	@override String get syncRuleUnknownServer => 'अज्ञात सर्वर';
	@override String get syncRuleListCreated => 'सिंक्रनाइज़ेशन का नियम बनाया गया';
	@override late final _Translations$downloads$backgroundWarning$hi backgroundWarning = _Translations$downloads$backgroundWarning$hi._(_root);
	@override String get options => 'डाउनलोड विकल्प';
	@override late final _Translations$downloads$groupings$hi groupings = _Translations$downloads$groupings$hi._(_root);
	@override String get unknownLibrary => 'अज्ञात पुस्तकालय';
	@override String get unknownShow => 'अज्ञात शो';
	@override String get unknownSeason => 'अज्ञात मौसम';
	@override String get unknownAlbum => 'अज्ञात एल्बम';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} पूरा हो गया';
	@override String storageUsed({required Object size}) => 'उपयोग किए गए भंडारण: ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} डाउनलोड करें',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} डाउनलोड करें',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} प्रदर्शित करें',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} प्रदर्शित करें',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} फिल्में',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} फ़िल्में',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} एल्बम',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} एल्बम',
	);
	@override String get errorFileNotFound => 'फ़ाइल नहीं मिला (404)';
	@override String get errorDownloadNotAllowed => 'सर्वर द्वारा अनुमति नहीं दी गई डाउनलोड (403)';
	@override String get errorDownloadFailed => 'डाउनलोड असफल';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'डाउनलोड विफल: ${reason}';
	@override String get convertingOnServer => 'सर्वर पर स्थानांतरित करने के लिए ...';
	@override String convertingOnServerPercent({required Object percent}) => 'सर्वर पर रूपांतरण · ${percent}%';
	@override String errorHttpStatus({required Object status}) => 'डाउनलोड असफल (HTTP ${status})';
	@override String errorPostProcessing({required Object reason}) => 'प्रसंस्करण के बाद विफलता: ${reason}';
	@override String get reasonFileNotSaved => 'फ़ाइल को इस डिवाइस पर नहीं बचाया जा सकता है';
	@override String get reasonCannotResume => 'आंशिक डाउनलोड को फिर से नहीं किया जा सकता है';
	@override String get reasonDeviceStorageFull => 'यह डिवाइस भंडारण से बाहर है';
	@override String get notificationDownloading => 'डाउनलोड...';
	@override String get notificationComplete => 'डाउनलोड करें पूर्ण';
	@override String get notificationPaused => 'डाउनलोड करें ब्रेक';
}

// Path: shaders
class _Translations$shaders$hi extends Translations$shaders$en {
	_Translations$shaders$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'छाया';
	@override String get noShaderDescription => 'कोई वीडियो सुधार नहीं';
	@override String get nvscalerDescription => 'अधिक तेज वीडियो के लिए NVIDIA छवि स्केलिंग';
	@override String get artcnnVariantNeutral => 'तटस्थ';
	@override String get artcnnVariantDenoise => 'डेंगू';
	@override String get artcnnVariantDenoiseSharpen => 'डेंगू + शार्पन';
	@override String get qualityFast => 'जल्दी';
	@override String get qualityHQ => 'उच्च गुणवत्ता';
	@override String get mode => 'फैशन';
	@override String get importShader => 'आयात शेर';
	@override String get customShaderDescription => 'कस्टम GLSL शैडर';
	@override String get shaderImported => 'शेर आयात';
	@override String get shaderImportFailed => 'शेर का आयात करने में विफलता';
	@override String get deleteShader => 'Shader को हटा दें';
	@override String deleteShaderConfirm({required Object name}) => '"${name}" को हटाने के लिए?';
}

// Path: companionRemote
class _Translations$companionRemote$hi extends Translations$companionRemote$en {
	_Translations$companionRemote$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'सहायक रिमोट';
	@override String connectedTo({required Object name}) => '${name} पर कनेक्ट करें';
	@override String get unknownDevice => 'अज्ञात डिवाइस';
	@override late final _Translations$companionRemote$session$hi session = _Translations$companionRemote$session$hi._(_root);
	@override late final _Translations$companionRemote$pairing$hi pairing = _Translations$companionRemote$pairing$hi._(_root);
	@override late final _Translations$companionRemote$remote$hi remote = _Translations$companionRemote$remote$hi._(_root);
	@override late final _Translations$companionRemote$errors$hi errors = _Translations$companionRemote$errors$hi._(_root);
	@override String get closedBeforeAuth => 'पहचान से पहले कनेक्शन बंद';
}

// Path: videoSettings
class _Translations$videoSettings$hi extends Translations$videoSettings$en {
	_Translations$videoSettings$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Playback गति';
	@override String get normalSpeed => 'सामान्य';
	@override String sleepTimerActive({required Object duration}) => 'सक्रिय (${duration})';
	@override String get zoom => 'ज़ूम';
	@override String get sleepTimer => 'नींद का समय';
	@override String get audioSync => 'ऑडियो सिंक्रनाइज़ेशन';
	@override String get subtitleSync => 'Subtitle सिंक्रनाइज़';
	@override String get hdr => 'HDR';
	@override String get hdrUnsupported => 'HDR यहाँ उपलब्ध नहीं है - यह डेस्कटॉप कॉम्प्लेटर या वीडियो आउटपुट इसे ले जाने में सक्षम नहीं है।';
	@override String get hdrToneMapping => 'HDR टोन मैपिंग';
	@override String get hdrToneMappingCompositor => 'रचनाकार';
	@override String get hdrToneMappingCompositorDescription => 'स्रोत के एचडीआर मेटाडेटा के माध्यम से गुजरें और डेस्कटॉप कॉम्प्लेटर के नक्शे को छोड़ दें।';
	@override String get hdrToneMappingPlayer => 'प्लेयर';
	@override String get hdrToneMappingPlayerDescription => 'प्लेयर में डिस्प्ले की चोटी चमक के लिए नक्शा, फिर संगीतकार को परिणाम बताएं।';
	@override String get hdrToneMappingFailed => 'HDR टोन मैपिंग नहीं बदल सकता था - पिछले मोड अभी भी सक्रिय है।';
	@override String get audioOutput => 'ऑडियो आउटपुट';
	@override String get performanceOverlay => 'प्रदर्शन ओवरले';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'आसपास';
	@override String get audioOutputSpatial => 'अंतरिक्ष ऑडियो';
	@override String get audioOutputStereo => 'स्टेनलेस';
	@override String get audioEqualizer => 'ऑडियो इक्वाइज़र';
	@override String get audioEqualizerDescription => 'इस डिवाइस के लिए पांच आवृत्ति बैंड को समायोजित करें. mpv पर उपलब्ध; एक सक्रिय EQ ऑडियो को डिकोड करता है और फिस्टह्रो को अक्षम करता है.';
	@override String get audioEqualizerFlat => 'फ्लैट';
	@override String get audioEqualizerActive => 'कस्टम';
	@override String get audioEqualizerSaveFailed => 'ऑडियो इक्वालिज़र सेटिंग्स को बचाने में सक्षम नहीं था।';
	@override String get backgroundVideoAudio => 'पृष्ठभूमि Video Audio';
	@override String get backgroundVideoAudioDescription => 'जब आप प्लेयर छोड़ देते हैं तो वीडियो ऑडियो खेलना बनाए रखें; तस्वीर वापस आने तक छिपी हुई है. Android एक मीडिया प्लेबैक नोटिस का उपयोग करता है.';
	@override String get audioNormalization => 'ध्वनि को सामान्य करें';
	@override String get audioNormalizationDisablesPassthrough => 'पीसीएम में ऑडियो डिकोड करें; passthrough बंद हो जाता है जबकि यह';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$hi extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get color => 'रंग';
	@override String get performance => 'प्रदर्शन';
	@override String get buffer => 'बफर';
	@override String get app => 'एप्लिकेशन';
	@override String get decoder => 'डिकोडर';
	@override String get rawDecoder => 'रेड डिकोडर';
	@override String get tunneling => 'टनल';
	@override String get passthrough => 'पश्चाताप';
	@override String get aspect => 'दृष्टि';
	@override String get rotation => 'रोटेशन';
	@override String get dvSource => 'डीवी स्रोत';
	@override String get dvPath => 'डीवी मार्ग';
	@override String get dvRouteDecoder => 'Dolby Vision डिकोडर';
	@override String get dvRouteDecoderP81 => 'Dolby Vision डिकोडर (P7→8.1)';
	@override String get dvRouteBaseLayer => 'बेस लेयर';
	@override String get dvRouteBaseLayerHdr10 => 'HDR10 आधार परत';
	@override String get dvRouteBaseLayerHlg => 'HLG आधार परत';
	@override String get dvRouteBaseLayerSdr => 'एसडीआर आधार परत';
	@override String get dvRouteReshaped => 'आरपीयू पुनर्प्राप्त (जीपीयू-अगला)';
	@override String get p7Conversion => 'पी 7 कॉन्फ';
	@override String get sampleRate => 'नमूना दर';
	@override String get pixelFormat => 'पिक्सेल Fmt';
	@override String get hwFormat => 'एफएमटी';
	@override String get matrix => 'मैट्रिक्स';
	@override String get primaries => 'प्राथमिकताएं';
	@override String get transfer => 'स्थानांतरण';
	@override String get renderFps => 'एफपीएस';
	@override String get displayFps => 'FPS प्रदर्शित करें';
	@override String get avSync => 'A/V सिंक्रनाइज़ेशन';
	@override String get dropped => 'टूट गया';
	@override String get dvRpus => 'डीवी आरपीयू';
	@override String get dvRpuAverage => 'डीवी आरपीयू AVG';
	@override String get dvSampleAverage => 'डीवी नमूना AVG';
	@override String get maxLuma => 'मैक्स लूमा';
	@override String get minLuma => 'लूमा';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'कैश का इस्तेमाल';
	@override String get cacheLimit => 'Cache सीमा';
	@override String get speed => 'गति';
	@override String get player => 'प्लेयर';
	@override String get playMethod => 'खेलने का तरीका';
	@override String get memory => 'स्मृति';
	@override String get uiFps => 'एफपीएस';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Android एचडब्ल्यू';
	@override String get decoderNvidiaHw => 'NVIDIA HW के बारे में';
	@override String get decoderQualcommHw => 'क्लॉम HW';
	@override String get decoderMediatekHw => 'मीडिया एचएच';
	@override String get decoderExynosHw => 'एक्सिनोस एचड';
	@override String get decoderSoftware => 'सॉफ्टवेयर';
	@override String get decoderHardware => 'हार्डवेयर';
	@override String get tunnelingActive => 'सक्रिय';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted} (${failures} असफल)';
}

// Path: externalPlayer
class _Translations$externalPlayer$hi extends Translations$externalPlayer$en {
	_Translations$externalPlayer$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'बाहरी खिलाड़ी';
	@override String get useExternalPlayer => 'बाहरी खिलाड़ी का उपयोग करें';
	@override String get useExternalPlayerDescription => 'एक और ऐप में वीडियो खोलना';
	@override String get selectPlayer => 'खिलाड़ी चुनें';
	@override String get customPlayers => 'Custom खिलाड़ी';
	@override String get systemDefault => 'डिफ़ॉल्ट सिस्टम';
	@override String get addCustomPlayer => 'कस्टम प्लेयर';
	@override String get playerName => 'खिलाड़ी का नाम';
	@override String get playerNameHint => 'मेरे खिलाड़ी';
	@override String get playerCommand => 'कमांड';
	@override String get playerPackage => 'पैकेज नाम';
	@override String get playerUrlScheme => 'URL योजना';
	@override String get off => 'बंद करें';
	@override String get launchFailed => 'बाहरी खिलाड़ी खोलने में विफलता';
	@override String appNotInstalled({required Object name}) => '${name} स्थापित नहीं किया गया';
	@override String get playInExternalPlayer => 'बाहरी खिलाड़ी में खेलना';
}

// Path: metadataEdit
class _Translations$metadataEdit$hi extends Translations$metadataEdit$en {
	_Translations$metadataEdit$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'संपादित करें...';
	@override String get screenTitle => 'मेटाडेटा संपादन';
	@override String get basicInfo => 'बुनियादी जानकारी';
	@override String get artwork => 'कला कार्य';
	@override String get advancedSettings => 'उन्नत सेटिंग्स';
	@override String get title => 'शीर्षक';
	@override String get sortTitle => 'शीर्षक का चयन करें';
	@override String get originalTitle => 'मूल शीर्षक';
	@override String get releaseDate => 'रिलीज की तारीख';
	@override String get contentRating => 'सामग्री रेटिंग';
	@override String get studio => 'स्टूडियो';
	@override String get tagline => 'संक्षिप्त परिचय';
	@override String get summary => 'संक्षेप में';
	@override String get poster => 'पोस्टर';
	@override String get background => 'पृष्ठभूमि';
	@override String get logo => 'लोगो';
	@override String get squareArt => 'Square कला';
	@override String get selectPoster => 'पोस्टर चुनें';
	@override String get selectBackground => 'पृष्ठभूमि चुनें';
	@override String get selectLogo => 'लॉग चुनें';
	@override String get selectSquareArt => 'Square Art का चयन करें';
	@override String get fromUrl => 'URL से';
	@override String get uploadFile => 'फ़ाइल अपलोड करें';
	@override String get enterImageUrl => 'इमेज URL';
	@override String get imageUrl => 'इमेज URL';
	@override String get metadataUpdated => 'मेटाडेटा अपडेट';
	@override String get metadataUpdateFailed => 'मेटाडेटा अपडेट करने में असफल';
	@override String get artworkUpdated => 'Artwork अद्यतन';
	@override String get artworkUpdateFailed => 'कला के काम को अपडेट करने में विफलता';
	@override String get noArtworkAvailable => 'कोई कला उपलब्ध नहीं है';
	@override String artworkOption({required Object index}) => 'आर्टवर्क विकल्प ${index}';
	@override String selectedArtworkOption({required Object index}) => 'आर्टवर्क विकल्प ${index}, चुना गया';
	@override String get notSet => 'सेट नहीं';
	@override String get libraryDefault => 'लाइब्रेरी अभाव';
	@override String get accountDefault => 'अकाउंट डिफ़ॉल्ट';
	@override String get seriesDefault => 'श्रृंखला डिफ़ॉल्ट';
	@override String get episodeSorting => 'एपिसोड सेटअप';
	@override String get oldestFirst => 'सबसे पुराना पहले';
	@override String get newestFirst => 'नवीनतम प्रथम';
	@override String get keep => 'रखें';
	@override String get allEpisodes => 'सभी प्रकरण';
	@override String latestEpisodes({required Object count}) => '${count} नवीनतम एपिसोड';
	@override String get latestEpisode => 'अंतिम एपिसोड';
	@override String episodesAddedPastDays({required Object count}) => 'पिछले ${count} दिनों में जोड़े गए घटनाएँ';
	@override String get deleteAfterPlaying => 'खेलने के बाद एपिसोड को हटा दें';
	@override String get never => 'कभी नहीं';
	@override String get afterADay => 'एक दिन के बाद';
	@override String get afterAWeek => 'एक सप्ताह के बाद';
	@override String get afterAMonth => 'एक महीने के बाद';
	@override String get onNextRefresh => 'अगले रिफ्रेश';
	@override String get seasons => 'मौसम';
	@override String get show => 'शो';
	@override String get hide => 'छिपाना';
	@override String get episodeOrdering => 'एपिसोड ऑर्डर';
	@override String get tmdbAiring => 'फिल्म डेटाबेस (Aired)';
	@override String get tvdbAiring => 'टीवीडीबी (एरिड)';
	@override String get tvdbAbsolute => 'टीवीडीबी (असफल)';
	@override String get metadataLanguage => 'मेटाडेटा भाषा';
	@override String get useOriginalTitle => 'मूल शीर्षक का उपयोग करें';
	@override String get preferredAudioLanguage => 'ऑडियो भाषा की पसंद';
	@override String get preferredSubtitleLanguage => 'Subtitle भाषा के बारे में';
	@override String get subtitleMode => 'Auto-Select Subtitle मोड का चयन करें';
	@override String get manuallySelected => 'मैन्युअल रूप से चुने गए';
	@override String get shownWithForeignAudio => 'विदेशी ऑडियो के साथ प्रदर्शित';
	@override String get alwaysEnabled => 'हमेशा सक्षम';
	@override String get tags => 'टैग';
	@override String get addTag => 'टैग जोड़ें';
	@override String get genre => 'जीन';
	@override String get director => 'निर्देशक';
	@override String get writer => 'लेखक';
	@override String get producer => 'निर्माता';
	@override String get country => 'देश';
	@override String get collection => 'संग्रह';
	@override String get label => 'लेबल';
	@override String get quickTag => 'त्वरित टैग...';
}

// Path: matchScreen
class _Translations$matchScreen$hi extends Translations$matchScreen$en {
	_Translations$matchScreen$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get match => 'मैच...';
	@override String get fixMatch => 'फिक्स मैच...';
	@override String get unmatch => 'असंगत';
	@override String get unmatchConfirm => 'इस मैच को स्पष्ट करें? Plex इसे समाप्त होने तक असंगत के रूप में व्यवहार करता है।';
	@override String get unmatchSuccess => 'असंगत आइटम';
	@override String get unmatchFailed => 'असफलता से अनमोलता';
	@override String get matchApplied => 'मैच लागू';
	@override String get matchFailed => 'मैच में असफलता';
	@override String get titleHint => 'शीर्षक';
	@override String get yearHint => 'वर्ष';
	@override String get search => 'खोज';
	@override String get noMatchesFound => 'कोई मैच नहीं मिला';
}

// Path: serverTasks
class _Translations$serverTasks$hi extends Translations$serverTasks$en {
	_Translations$serverTasks$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'सर्वर कार्य';
	@override String get failedToLoad => 'कार्यों को लोड करने में विफलता';
	@override String get noTasks => 'कोई कार्य नहीं चल रहा है';
}

// Path: trakt
class _Translations$trakt$hi extends Translations$trakt$en {
	_Translations$trakt$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'कनेक्ट';
	@override String connectedAs({required Object username}) => '@${username} के रूप में कनेक्ट';
	@override String get disconnectConfirm => 'Trakt खाते से कनेक्ट करें?';
	@override String get disconnectConfirmBody => 'PlezyNG Trakt पर घटनाओं को भेजना बंद कर देगा. आप किसी भी समय फिर से कनेक्ट कर सकते हैं.';
	@override String get scrobble => 'वास्तविक समय स्क्रबबलिंग';
	@override String get scrobbleDescription => 'प्लेबैक के दौरान प्लेबैक, ब्रेक, और स्टॉप घटनाओं को Trakt पर भेजें।';
	@override String get watchedSync => 'सिंक्रनाइज़ेशन की स्थिति';
	@override String get watchedSyncDescription => 'जब आप PlezyNG में देखे गए आइटम को चिह्नित करते हैं, तो वे Trakt में देखे गए आइटम को भी चिह्नित करते हैं।';
}

// Path: seerr
class _Translations$seerr$hi extends Translations$seerr$en {
	_Translations$seerr$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'कनेक्ट करें Seerr';
	@override String get serverUrl => 'सर्वर URL';
	@override String get serverUrlHelper => 'आपके सीरियर के संदर्भ का पता';
	@override String get checkServer => 'जारी है';
	@override String get signInWithJellyfin => 'Jellyfin के साथ साइन इन करें';
	@override String get signInWithEmby => 'Emby के साथ साइन इन करें';
	@override String get signInWithLocal => 'एक स्थानीय खाता का उपयोग करें';
	@override String get email => 'ईमेल';
	@override String get noSignInMethods => 'यह Seerr उदाहरण कोई साइन इन विधि PlezyNG समर्थन प्रदान नहीं करता है।';
	@override String get instance => 'उदाहरण';
	@override String get disconnectConfirm => 'कनेक्ट हो जाओ?';
	@override String get disconnectConfirmBody => 'PlezyNG इस Seerr उदाहरण को भूल जाएगा. किसी भी समय फिर से कनेक्ट करें.';
	@override String get request => 'अनुरोध';
	@override String get request4k => '4K में अनुरोध';
	@override String get seasons => 'मौसम';
	@override String get allSeasons => 'सभी मौसम';
	@override String get advancedOptions => 'उन्नत';
	@override String get destinationServer => 'Destination सर्वर';
	@override String get qualityProfile => 'गुणवत्ता प्रोफ़ाइल';
	@override String get rootFolder => 'रूट फ़ोल्डर';
	@override String get languageProfile => 'भाषा प्रोफ़ाइल';
	@override String get tags => 'टैग';
	@override String get noTags => 'कोई टैग नहीं';
	@override String defaultOption({required Object name}) => '${name} (वैकल्पिक)';
	@override String get animeNote => 'यह श्रृंखला एक एनीम है।';
	@override String get requestSubmitted => 'अनुरोध प्रस्तुत';
	@override String requestFailed({required Object error}) => 'अनुरोध विफल: ${error}';
	@override String get requestsLoadFailed => 'अनुरोध विकल्पों को लोड नहीं किया जा सकता';
	@override String get nothingToRequest => 'सब कुछ पहले से ही उपलब्ध है या अनुरोध किया गया है।';
	@override String get statusAvailable => 'उपलब्ध';
	@override String get statusPartiallyAvailable => 'आंशिक उपलब्ध';
	@override String get statusRequested => 'अनुरोध';
	@override String get statusProcessing => 'प्रसंस्करण';
	@override String get statusBlocklisted => 'ब्लॉकअप';
	@override String couldNotReach({required Object url, required Object error}) => '${url}: ${error} तक नहीं पहुंच सकता';
	@override String noInstanceAtUrl({required Object url, required Object status}) => '${url} (HTTP ${status}) पर कोई Seerr मामला नहीं';
	@override String get behindAuthProxy => 'एक सत्यापित विपरीत प्रॉक्सी (एसएसओ या HTTP auth) ने Seerr के बजाय जवाब दिया. PlezyNG इसके माध्यम से साइन इन नहीं कर सकता: Seerr के /api/v1 मार्ग को इस एप्लिकेशन के लिए प्रॉक्सी पार कर दें, या एक पता का उपयोग करें जो सीधे Seerr तक पहुंचता है.';
	@override String get invalidUrl => 'एक सर्वर पता दर्ज करें जैसे https://seerr.example.com';
	@override String get quickConnectUnsupported => 'इस Seerr उदाहरण का समर्थन नहीं करता Quick Connect. यह Seerr 3.4 या उससे अधिक की आवश्यकता है.';
	@override String get notInitialized => 'यह Seerr उदाहरण पहली बार चलने वाले सेटअप को पूरा नहीं करता है';
	@override String get noPlexTokenForReauth => 'नंबर Plex टोकन फिर से साइन अप करने के लिए उपलब्ध है';
	@override String get noStoredCredentials => 'फिर से साइन इन करने के लिए कोई सहेजी हुई साइन-इन जानकारी उपलब्ध नहीं है';
	@override String get signInRejected => 'Sign-in को अस्वीकार कर दिया गया';
	@override String get noSessionCookie => 'Seerr ने कोई सत्र कुकी जारी नहीं की';
	@override String get freshCookieRejected => 'Seerr ने नए सत्र कुकी को खारिज कर दिया';
	@override String get noUserInformation => 'Seerr ने उपयोगकर्ता जानकारी वापस नहीं की';
	@override String get sessionRejectedAfterReauth => 'फिर से हस्ताक्षर करने के बाद बैठक को अस्वीकार कर दिया गया';
	@override String get permissionDenied => 'Seerr ने इस कार्रवाई को अस्वीकार कर दिया: आपके खाते में अब आवश्यक अनुमति नहीं है';
	@override String get permissionRevoked => 'अब आपके पास यह अनुरोध करने की अनुमति नहीं है';
}

// Path: services
class _Translations$services$hi extends Translations$services$en {
	_Translations$services$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'सेवाएं';
	@override String get hubSubtitle => 'सिंक्रनाइज़ेशन प्रगति की निगरानी करता है और नए शीर्षकों की मांग करता है।';
	@override String get integrations => 'एकीकरण';
	@override String get notConnected => 'नहीं जुड़े';
	@override String connectedAs({required Object username}) => '@${username} के रूप में कनेक्ट';
	@override String get scrobble => 'प्रगति को स्वचालित रूप से ट्रैक करें';
	@override String get scrobbleDescription => 'जब आप एक एपिसोड या फिल्म खत्म करते हैं तो अपनी सूची को अपडेट करें।';
	@override String disconnectConfirm({required Object service}) => 'कनेक्ट करें ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'PlezyNG किसी भी समय पुनः कनेक्ट करें. ${service} को अपडेट करना बंद कर दिया जाएगा.';
	@override String connectFailed({required Object service}) => '${service} पर कनेक्ट नहीं किया जा सकता।';
	@override late final _Translations$services$names$hi names = _Translations$services$names$hi._(_root);
	@override late final _Translations$services$simklReconnect$hi simklReconnect = _Translations$services$simklReconnect$hi._(_root);
	@override late final _Translations$services$deviceCode$hi deviceCode = _Translations$services$deviceCode$hi._(_root);
	@override late final _Translations$services$oauthProxy$hi oauthProxy = _Translations$services$oauthProxy$hi._(_root);
	@override late final _Translations$services$pendingAuth$hi pendingAuth = _Translations$services$pendingAuth$hi._(_root);
	@override late final _Translations$services$libraryFilter$hi libraryFilter = _Translations$services$libraryFilter$hi._(_root);
}

// Path: addServer
class _Translations$addServer$hi extends Translations$addServer$en {
	_Translations$addServer$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => '${product} सर्वर जोड़ें';
	@override String get serverUrls => 'सर्वर URL';
	@override String get serverUrlsHelper => 'कई यूआरएल अनुमति दी जाती है, कॉम्मा द्वारा अलग किया जाता है।';
	@override String get findServer => 'सर्वर खोजें';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'स्थानीय ${product} सर्वरों की तलाश में ...';
	@override String localMediaBrowserServers({required Object product}) => 'स्थानीय सर्वर ${product}';
	@override String get username => 'उपयोगकर्ता नाम';
	@override String get password => 'पासवर्ड';
	@override String get signIn => 'साइन इन';
	@override String get change => 'बदलाव';
	@override String get required => 'जरूरी';
	@override String couldNotReachServer({required Object error}) => 'सर्वर तक नहीं पहुंच सकता: ${error}';
	@override String signInFailed({required Object error}) => 'हस्ताक्षर विफल: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect असफल: ${error}';
	@override String get addPlexTitle => 'Plex के साथ साइन इन करें';
	@override String get pinExpired => 'पिन लॉग इन करने से पहले समाप्त हो गया है. कृपया फिर से कोशिश करें.';
	@override String failedToRegisterAccount({required Object error}) => 'अकाउंट रजिस्टर करने में विफल: ${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => 'अपने ${product} सर्वर URL दर्ज करें';
	@override String get addConnectionTitle => 'कनेक्शन जोड़ें';
	@override String addConnectionTitleScoped({required Object name}) => '${name} पर जोड़ें';
	@override String get signInWithPlexCard => 'Plex के साथ साइन इन करें';
	@override String get signInWithPlexCardSubtitle => 'इस डिवाइस को अनुमति दें. साझा सर्वर जोड़े जाते हैं.';
	@override String get signInWithPlexCardSubtitleScoped => 'एक Plex खाता सक्षम करें. होम उपयोगकर्ता प्रोफ़ाइल बन जाते हैं.';
	@override String connectToMediaBrowserCard({required Object product}) => 'कनेक्ट करें ${product}';
	@override String get connectToMediaBrowserCardSubtitle => 'अपने सर्वर URL, उपयोगकर्ता नाम और पासवर्ड दर्ज करें।';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => 'अपने सर्वर ${product} पर साइन इन करें. ${name} पर लिंक करें.';
	@override String get borrowFromAnotherProfile => 'एक और प्रोफ़ाइल से ऋण';
	@override String get borrowFromAnotherProfileSubtitle => 'एक और प्रोफ़ाइल कनेक्शन का पुन: उपयोग करें. PIN-सुरक्षित प्रोफ़ाइलों को एक PIN की आवश्यकता होती है.';
	@override String get invalidCredentials => 'अक्षम उपयोगकर्ता नाम या पासवर्ड';
	@override String get authResponseNotJson => 'सत्यापन प्रतिक्रिया वैध नहीं थी JSON';
	@override String get authResponseIncomplete => 'सर्वर से साइन-इन प्रतिक्रिया अपूर्ण थी';
	@override String get quickConnectRejected => 'Quick Connect सर्वर द्वारा अस्वीकार कर दिया गया था';
	@override String get quickConnectNotJson => 'Quick Connect जवाब JSON वैध नहीं था';
	@override String get quickConnectMissingFields => 'Quick Connect का जवाब एक कोड या रहस्य की कमी है';
	@override String get quickConnectPollRejected => 'Quick Connect पूछताछ सर्वर द्वारा अस्वीकार कर दिया गया था';
	@override String get serverTimedOut => 'सर्वर ने समय पर जवाब नहीं दिया';
	@override String get responseNotJson => 'सर्वर प्रतिक्रिया वैध नहीं थी JSON';
	@override String responseMissingIdentity({required Object product}) => 'जवाब एक आईडी या सर्वर नाम की कमी है - क्या यह एक सर्वर ${product} है?';
	@override String probeFailed({required Object error}) => 'सर्वर तक नहीं पहुंच सकता: ${error}';
	@override String enterAtLeastOneUrl({required Object product}) => 'कम से कम एक ${product} सर्वर URL दर्ज करें';
	@override String noReachableServer({required Object product}) => 'कोई पहुंच योग्य सर्वर ${product} नहीं मिला';
	@override String urlsPointToDifferentServers({required Object product}) => 'ये URL अलग-अलग ${product} सर्वरों को संदर्भित करते हैं';
	@override String urlDoesNotMatchServer({required Object product}) => 'यह URL ${product} सर्वर के अनुरूप नहीं है';
	@override String get redirectUnsupported => 'सर्वर को एक असहाय URL के लिए रीरेक्ट किया गया है';
	@override String redirectDifferentHost({required Object product}) => 'सर्वर को एक अलग होस्ट पर पुनर्निर्देशित किया गया है. अंतिम URL ${product} को सीधे दर्ज करें.';
	@override String get redirectInsecure => 'सर्वर को HTTPS से एक असुरक्षित URL पर पुनर्निर्देशित किया गया है';
	@override String redirectUnsupportedEnterFinal({required Object product}) => 'सर्वर को एक असहाय URL पर पुनर्निर्देशित किया गया है. अंतिम URL ${product} को सीधे दर्ज करें.';
	@override String get directPlexServerUrl => 'Plex सर्वर यूआरएल';
	@override String get directPlexServerUrlHelper => 'अपने Plex मीडिया सर्वर के स्थानीय आईपी और पोर्ट दर्ज करें।';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex टोकन (वैकल्पिक)';
	@override String get plexTokenHelper => 'इस सर्वर पर auth के बिना पहुंच की अनुमति है तो खाली छोड़ दें।';
	@override String get plexTokenRequired => 'कृपया अपना Plex टोकन (X-Plex-Token) दर्ज करें।';
	@override String get connectDirectPlexCard => 'Plex मीडिया सर्वर (प्रत्यक्ष / स्थानीय)';
	@override String get connectDirectPlexCardSubtitle => 'Plex.tv खाते के बिना स्थानीय IP या URL का उपयोग करके सीधे कनेक्ट करें।';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => 'सीधे स्थानीय आईपी या यूआरएल का उपयोग करके कनेक्ट करें. ${name} से कनेक्ट करें.';
	@override String get insecureTitle => 'अनगिनत कनेक्शन';
	@override String insecureDescription({required Object url}) => '${url} HTTP का उपयोग करता है। नेटवर्क पर मौजूद लोग आपका पासवर्ड, टोकन और मीडिया पढ़ या बदल सकते हैं। उपलब्ध होने पर HTTPS का उपयोग करें। केवल तभी जारी रखें जब आपको इस नेटवर्क पर भरोसा हो और आप जोखिम स्वीकार करते हों।';
	@override String get allowHttp => 'HTTP की अनुमति दें';
	@override String get httpsRequired => 'HTTPS का उपयोग करें या स्पष्ट रूप से एक अज्ञात कनेक्शन की अनुमति दें।';
}

// Path: watchLink
class _Translations$watchLink$hi extends Translations$watchLink$en {
	_Translations$watchLink$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => 'इस लिंक के लिए Plex सर्वर तक पहुंच नहीं पाया।';
	@override String get notFound => 'इस शो या फिल्म को आपके Plex सर्वर पर नहीं पाया जा सकता।';
	@override String get ambiguous => 'यह लिंक एक से अधिक सर्वर पर आइटम से मेल खाता है. लिंक में एक सर्वर जोड़ें.';
	@override String get plexOnly => 'वर्तमान में केवल Plex सर्वरों का समर्थन करता है।';
	@override String get unsupportedItem => 'देखने के लिए लिंक केवल एक शो या फिल्म खोल सकते हैं।';
	@override String get menuItem => 'देखें लिंक देखें';
	@override String get dialogTitle => 'देखें लिंक';
	@override String get dialogShowHint => 'इस लिंक को खोलने से अगले एपिसोड को खेला जाता है. &mode=shuffle जोड़ें shuffle पर शो को खेलने के लिए अंत में।';
	@override String get dialogMovieHint => 'इस लिंक को खोलने से फिल्म खेलती है।';
	@override String get copy => 'कॉपी';
	@override String get copied => 'लिंक कॉपी करें';
}

// Path: homeLayout
class _Translations$homeLayout$hi extends Translations$homeLayout$en {
	_Translations$homeLayout$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Home लेआउट';
	@override String get resetToast => 'Home Reset to the original Plezy नायक लेआउट';
	@override String get resetHeroTitle => 'स्टॉक Plezy में नायक लेआउट को पुनर्स्थापित करें?';
	@override String get resetHeroBody => 'यह प्रत्येक पंक्ति के नायक सेटिंग को खोलता है और घर के शीर्ष पर एकल घूमने वाले बैनर को वापस लाता है, जैसे कि पहले नायक पंक्तियां मौजूद थीं।';
	@override String get removeRowTitle => 'Home रीढ़ को हटाने के लिए?';
	@override String removeRowBody({required Object title}) => '${title} को हटा दिया जाएगा. यह अस्वीकार नहीं किया जा सकता.';
	@override String get sync => 'सिंक्रनाइज़';
	@override String get syncAccountTitle => 'अपने Plex खाते के साथ सिंक्रनाइज़ेशन';
	@override String get syncAccountOn => 'पर: यह डिवाइस आपके अन्य डिवाइसों के साथ पंक्ति आदेश, पंक्तियों, नायक और ऑटो-स्लाइड साझा करता है।';
	@override String get syncAccountOff => 'बंद: यह डिवाइस अपने स्वयं के लेआउट को बनाए रखता है।';
	@override String get syncNow => 'अब सिंक्रनाइज़ेशन';
	@override String get plexHomeManager => 'Plex होम मैनेजर';
	@override String get managePlexRows => 'Plezy में Plex पंक्तियों का प्रबंधन करें';
	@override String get managePlexRowsDescription => 'Home-Selected लाइनों को व्यवस्थित करने के लिए खुला';
	@override String get organizeHomeRows => 'Home रैखों का आयोजन';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} पंक्तियां: आंदोलन, नायक, स्वचालित स्लाइड, हटाने';
	@override String organizeLibraryRows({required Object library}) => '${library} पंक्तियों का आयोजन करें';
	@override String organizeLibraryRowsDescription({required Object n}) => 'जारी रखें + ${n} पंक्तियां: चलना, लाइब्रेरी, होम, नायक, ऑटो-स्लाइड';
	@override String get renderAsHero => 'एक नायक कार्ड के रूप में रेंडर';
	@override String get heroOnlySingleCollection => 'केवल तब उपलब्ध है जब यह पंक्ति एकल संग्रह के वास्तविक शीर्षकों के लिए हल हो जाती है';
	@override String get hero => 'नायक';
	@override String get autoSlide => 'स्वचालित स्लाइड';
	@override String get autoSlideDescription => 'लोड (पीसी) और डी-पैड (टीवी) हमेशा काम करते हैं और टाइमर को पुनरारंभ करते हैं।';
	@override String get autoSlideEditDescription => 'इसके अलावा, यह हर कुछ सेकंड में खुद पर स्लाइड करता है. बंद: केवल जब आप एक पंख (पीसी) पर क्लिक करते हैं या दूरस्थ (टीवी) पर बाईं ओर / दाईं ओर दबाते हैं तो चलता है. लहरें और डी-पैड हमेशा किसी भी तरह से काम करते हैं.';
	@override String get enableHeroFirst => 'पहले नायक को सक्षम करें';
	@override String get showOnHome => 'Home Screen पर दिखाएँ';
	@override String get home => 'घर';
	@override String get removeFromHome => 'घर से हटाना';
	@override String get selectRowsFirst => 'सबसे पहले नीचे दिए गए होम लाइनों का चयन करें।';
	@override String plexManagedRows({required Object n}) => '${n} Plex प्रबंधित पंक्तियां';
	@override String get continueWatching => 'देखना जारी रखें';
	@override String get continueWatchingLibraryDescription => 'इस पुस्तकालय के स्वयं के पुनरावृत्ति-प्रगति क्रम';
	@override String get continueWatchingHomeDescription => 'Home पर दिखाए गए पुनरावृत्ति-प्रगति की पंक्ति';
	@override String get nextUpHomeDescription => 'अगला अनदेखा किए गए एपिसोड की पंक्ति अलग से दिखाई देती है होम';
	@override String get library => 'लाइब्रेरी';
	@override String get showInRecommended => 'पुस्तकालय में प्रदर्शित की सिफारिश';
	@override String get customPlexRow => 'कस्टम Plex पंक्ति';
	@override String get heroNeedsLibrary => 'पहले पुस्तकालय की जांच करें - नायक को कहीं दिखाने की जरूरत है';
	@override String get heroNeedsSurface => 'पहले पुस्तकालय या होम की जांच करें — नायक को कहीं दिखाने की जरूरत है';
	@override String get removeHub => 'Hub को हटाने के लिए';
	@override String get noPlexRows => 'नंबर Plex-प्रबंधित पंक्तियां इस पुस्तकालय के लिए वापस आ गई हैं।';
	@override String get openDetails => 'खुले विवरण';
	@override String get heroCards => 'नायक कार्ड';
	@override String get tapHeroCard => 'एक नायक का कार्ड';
	@override String get tvPlayFocus => 'टीवी रिमोट: उच्चारण Play बटन';
	@override String get tvPlayFocusDescription => 'डी-पैड नीचे खेल बटन पर रुकता है, इससे पहले कि अगले पंक्ति में आगे बढ़ें।';
	@override String get tvWrap => 'टीवी रिमोट: लूप नायक कार्ड';
	@override String get tvWrapDescription => 'अंतिम कार्ड पर सीधे पहले कार्ड पर वापस जाता है. अंतिम कार्ड पर बंद रुक जाते हैं. पहले कार्ड पर बाईं ओर हमेशा साइडबार पर जाता है.';
	@override String get castOnHero => 'नायक बैनरों पर हमला';
	@override String get castOnHeroDescription => 'एक नायक बैनर के नीचे के साथ कटौती दिखाता है. बाहर केवल शीर्षक और सारांश रखता है.';
	@override String get customRows => 'कस्टम रेंज';
	@override String get loading => 'Home लैंडिंग लैंडिंग...';
	@override String get noCustomRows => 'अभी तक कोई कस्टम नहीं';
	@override String get addRowHint => 'एक को बनाने के लिए Home Range का उपयोग करें।';
	@override String get addHomeRow => 'होम लाइन जोड़ें';
	@override String get addHomeRowDescription => 'एक श्रेणी का चयन करें; नए पंक्ति को स्वचालित रूप से संगठित करने के लिए जोड़ा जाता है';
	@override String get removeRow => 'लाइन को हटा दें';
	@override String get recentlyAdded => 'हाल ही में जोड़ा';
	@override String get recentlyReleased => 'हाल ही में रिलीज';
	@override String get movieCollections => 'फिल्म संग्रह';
	@override String get showCollections => 'संग्रह दिखाएं';
	@override String get rowTitle => 'रॉ नाम';
	@override String get content => 'संतुष्टि';
	@override String get showThisRowIn => 'इस पंक्ति को दिखाएं:';
	@override String get libraryRecommended => 'पुस्तकालय की सिफारिश';
	@override String get heroCard => 'नायक कार्ड';
	@override String get heroCardDescription => 'एक पोस्टर शीट के बजाय एक पूर्ण चौड़ा रूटिंग कार्ड के रूप में प्रदर्शित करता है।';
	@override String get heroUnavailableDescription => 'केवल तभी उपलब्ध है जब यह पंक्ति एकल संग्रह के वास्तविक शीर्षकों के लिए हल हो जाती है - एक से अधिक संग्रह चुने हुए के साथ, कोई एकल शीर्षक पार नहीं होता है।';
	@override String get librariesSelection => 'पुस्तकालय (सभी पुस्तकालयों को शामिल करने के लिए अनियंत्रित छोड़ दें)';
	@override String get librariesMergedDescription => 'यहां देखे गए प्रत्येक पुस्तकालय इस एक पंक्ति में मिश्रित है।';
	@override String get movieCollectionsSelection => 'फिल्म संग्रह (प्रत्येक चयनित पुस्तकालय के लिए सभी अनियंत्रित छोड़ दें)';
	@override String get showCollectionsSelection => 'संग्रह प्रदर्शित करें (प्रत्येक चयनित पुस्तकालय के लिए सभी अनियंत्रित छोड़ दें)';
	@override String get collectionRowsDescription => 'यदि एक संग्रह के साथ एक ही मैच होता है, तो इसके शीर्षक सीधे पंक्ति में दिखाई देते हैं. यदि एक से अधिक मैच होते हैं, तो प्रत्येक संग्रह एकल पोस्टर के रूप में दिखाई देता है – उस संग्रह को खोलने के लिए इसे टैप करें.';
	@override String get allCollections => 'सभी संग्रह';
	@override String get noRowsHere => 'अभी तक कोई पंक्ति नहीं है।';
	@override String get hideWatchedRows => 'पंक्तियों में देखे गए वस्तुओं को छिपाना';
	@override String get hideWatchedRowsDescription => 'पूरी तरह से देखे गए शीर्षक घर और लाइब्रेरी छोड़ देते हैं अनुशंसित पंक्तियां. प्रगति में लोग रहते हैं.';
	@override String get untitledCollection => 'अनगिनत संग्रह';
	@override String get moveRowHint => 'Up/Down: move row · Select: drop it here · Back: cancell';
	@override String get organizeRowsHint => 'एक पंक्ति पर चुनें (या रखें चुनें): इसे स्थानांतरित करें · बाईं ओर / दाईं ओर: पंक्ति विकल्प · वापस: किया गया';
	@override String get layoutNavDescription => 'लाइनों, पुस्तकालयों और संग्रह श्रेणियों का चयन करें';
	@override String get editHomeRow => 'संपादित करें Home Row';
	@override String get resetHeroButton => 'स्टॉक के लिए नायक लेआउट रीसेट करें Plezy';
	@override String get reorderingUnlocked => 'रीसेट अनलॉक';
	@override String get reorderingLocked => 'रिकॉर्ड लॉक';
	@override String get rowsCanBeDragged => 'तारों को खींच लिया जा सकता है - इसे रोकने के लिए लॉक पर टैप करें';
	@override String get tapLockToDrag => 'लाइनों को खींचने के लिए लॉक दबाएं';
	@override String customRowLabel({required Object title}) => 'पदों की संख्या: ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => 'छिपाना';
	@override String get remove => 'हटाना';
	@override String get libraryResumeRow => 'इस पुस्तकालय की पुनरावृत्ति';
	@override String get pressAgainToDelete => 'इसे हटाने के लिए फिर से दबाएं';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => 'पर';
	@override String get resetHeroButtonDescription => 'यह प्रत्येक पंक्ति के नायक सेटिंग को बाहर करता है और शीर्ष पर एकल घूमने वाले बैनर को वापस लाता है, जैसे कि नायक पंक्तियों से पहले मौजूद था।';
}

// Path: platform
class _Translations$platform$hi extends Translations$platform$en {
	_Translations$platform$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'PlezyNG आपके स्थानीय नेटवर्क पर आपके मीडिया सर्वर और प्लेबैक उपकरणों से कनेक्ट करता है।';
	@override String get locationPermission => 'PlezyNG स्थान एक्सेस का उपयोग करता है जब iOS इसे अपने स्थानीय नेटवर्क का पता लगाने और अपने मीडिया सर्वर से कनेक्ट करने के लिए आवश्यक है।';
	@override String get photoLibraryPermission => 'मीडिया कला के रूप में उपयोग करने के लिए अपनी फोटो लाइब्रेरी से छवियों का चयन करें।';
	@override String get cameraPermission => 'QR कोड स्कैन करने के लिए एक साथी दूरस्थ जोड़ने के लिए।';
}

// Path: fileSources
class _Translations$fileSources$hi extends Translations$fileSources$en {
	_Translations$fileSources$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'फ़ाइल और किताबें';
	@override String get subtitle => 'पढ़ो, सुनो, और अपने स्वयं के फ़ाइलों से देखो।';
	@override String get add => 'स्रोत जोड़ें';
	@override String get importFiles => 'फ़ाइलों का आयात';
	@override String get localFiles => 'इस उपकरण पर';
	@override String get source => 'स्रोत';
	@override String get name => 'नाम';
	@override String get endpoint => 'सर्वर URL';
	@override String get root => 'फ़ोल्डर या Prefix';
	@override String get username => 'उपयोगकर्ता नाम';
	@override String get password => 'पासवर्ड';
	@override String get token => 'API टोकन';
	@override String get accessKey => 'Key ID के लिए';
	@override String get secretKey => 'रहस्यमय पहुंच कुंजी';
	@override String get sessionToken => 'सत्र टोकन (वैकल्पिक)';
	@override String get region => 'क्षेत्र';
	@override String get clientId => 'OAuth क्लाइंट आईडी';
	@override String get clientSecret => 'OAuth क्लाइंट रहस्य (केवल डेस्कटॉप Google)';
	@override String get allowHttp => 'विश्वसनीय नेटवर्क पर बिना एन्क्रिप्शन वाले HTTP की अनुमति दें';
	@override String get connect => 'कनेक्ट करें';
	@override String get cancel => 'रद्द करना';
	@override String get save => 'बचाओ';
	@override String get close => 'बंद करें';
	@override String get removeSource => 'स्रोत से बाहर';
	@override String get disconnectMessage => 'इस स्रोत का कनेक्शन हटाएँ? डाउनलोड की गई फ़ाइलें और आपके पढ़ने व सुनने का इतिहास इस डिवाइस पर बने रहेंगे।';
	@override String get localFolder => 'फ़ोल्डर चुनें';
	@override String get empty => 'यहाँ अभी तक कुछ नहीं';
	@override String get emptyHint => 'एक स्रोत जोड़ें या एक पुस्तक, ऑडियोबुक, संगीत या वीडियो आयात करें।';
	@override String get search => 'इस फ़ोल्डर की खोज करें';
	@override String get searchCached => 'खोज बचाया पुस्तकालय';
	@override String get refresh => 'ताज़ा';
	@override String get loadMore => 'अधिक लोड करें';
	@override String get offline => 'Offline के लिए उपलब्ध';
	@override String get download => 'Offline रखें';
	@override String get removeDownload => 'Offline कॉपी हटाने';
	@override String get continueReading => 'पढ़ना जारी रखें';
	@override String get continueListening => 'सुनना जारी रखें';
	@override String get continueWatching => 'देखना जारी रखें';
	@override String get read => 'पढ़ना';
	@override String get listen => 'सुनो';
	@override String get play => 'खेलना';
	@override String get pause => 'रोकें';
	@override String get stop => 'रोकें';
	@override String get startOver => 'शुरू करें';
	@override String get finished => 'समाप्त';
	@override String get markFinished => 'मार्क खत्म';
	@override String get markUnfinished => 'अनंत मार्क';
	@override String get editions => 'संस्करण और फ़ाइल';
	@override String get chapters => 'अध्याय';
	@override String get bookmarks => 'नोट्स और नोट्स';
	@override String get bookmark => 'Bookmark के लिए';
	@override String get highlight => 'उजागर';
	@override String get note => 'नोट';
	@override String get delete => 'डिलीट';
	@override String get export => 'नोट्स निर्यात';
	@override String get exported => 'नोटों का निर्यात';
	@override String get sync => 'प्रगति सिंक्रनाइज़ेशन';
	@override String get synced => 'प्रगति सिंथेटिक';
	@override String get conflict => 'एक और डिवाइस एक अलग स्थिति है. जहां आगे बढ़ने के लिए चुनें.';
	@override String get useLocal => 'इस उपकरण का उपयोग करें';
	@override String get useRemote => 'अन्य उपकरणों का उपयोग करें';
	@override String get history => 'स्थिति इतिहास';
	@override String get groupAudio => 'एक ऑडियो किताब के रूप में सुनो';
	@override String get groupHint => 'इस फ़ोल्डर में वर्तमान में लोड किए गए ऑडियो फ़ाइलों को जोड़ें. पहले सभी पृष्ठों को लोड करें.';
	@override String get order => 'फ़ाइल आदेश';
	@override String get moveUp => 'ऊपर चलना';
	@override String get moveDown => 'नीचे उतरना';
	@override String get speed => 'Playback गति';
	@override String get sleep => 'नींद का समय';
	@override String get sleepOff => 'बंद करें';
	@override String get endChapter => 'अध्याय का अंत';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} मिनट',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} मिनट',
	);
	@override String get skipBack => 'वापस स्काइप';
	@override String get skipForward => 'आगे बढ़ें';
	@override String get smartRewind => 'एक ब्रेक के बाद बुद्धिमान वापसी';
	@override String get playbackOptions => 'सुनने के विकल्प';
	@override String remaining({required Object time}) => '${time} शेष';
	@override String get contents => 'सामग्री';
	@override String get readerSettings => 'पढ़ने की व्यवस्था';
	@override String get fontSize => 'पाठ का आकार';
	@override String get lineHeight => 'लाइन स्पेसिंग';
	@override String get margin => 'मार्जिन';
	@override String get font => 'टाइपफैक्स';
	@override String get serif => 'सेरिफ़';
	@override String get sans => 'बिना सेरिफ़';
	@override String get mono => 'मॉनस्पेस';
	@override String get columns => 'कोलंबन';
	@override String get scroll => 'Vertical स्क्रॉल करें';
	@override String get justify => 'पाठ दोनों किनारों पर बराबर करें';
	@override String get readerTheme => 'पृष्ठ की उपस्थिति';
	@override String get appTheme => 'App Theme के बारे में टिप्पणियाँ';
	@override String get paper => 'कागज';
	@override String get sepia => 'सेप्पा';
	@override String get night => 'रात';
	@override String get readAloud => 'यह पृष्ठ ज़ोर से पढ़ें';
	@override String get readAlong => 'आवाज़ के साथ पढ़ें';
	@override String get stopReading => 'पढ़कर सुनाना बंद करें';
	@override String get searchBook => 'पुस्तक में खोज';
	@override String get noMatches => 'कोई मैच नहीं';
	@override String get previousPage => 'पिछला पृष्ठ';
	@override String get nextPage => 'अगला पृष्ठ';
	@override String page({required Object number}) => 'पृष्ठ ${number}';
	@override String get externalBlocked => 'बाहरी पुस्तक लिंक पाठक में अक्षम हैं।';
	@override String get loading => 'खुलने...';
	@override String get narrator => 'कथाकार';
	@override String get audio => 'ऑडियो';
	@override String get video => 'वीडियो';
	@override String get ebooks => 'ईबुक';
	@override String get all => 'सारे';
	@override String get downloads => 'फ़ाइलों के लिए Offline';
	@override String get confirmDelete => 'चुनी हुई ऑफ़लाइन प्रति हटाएँ? आपका पढ़ने या सुनने का स्थान और नोट्स सुरक्षित रहेंगे।';
	@override String get errorAuthentication => 'इस स्रोत को फिर से कनेक्ट करने के लिए साइन इन करें।';
	@override String get errorPermission => 'इस स्रोत ने अनुरोधित फ़ाइल तक पहुंच नहीं दी।';
	@override String get errorUnavailable => 'स्रोत उपलब्ध नहीं है. फिर से कोशिश करें, या एक ऑफ़लाइन प्रतिलिपि खोलें.';
	@override String get errorUnsupported => 'इस डिवाइस पर इस प्रारूप या कनेक्शन का समर्थन नहीं किया जाता है. स्रोत सेटअप गाइड देखें.';
	@override String get errorInvalidData => 'यह फ़ाइल या सर्वर प्रतिक्रिया सुरक्षित रूप से नहीं पढ़ी जा सकती है।';
	@override String get errorCancelled => 'ऑपरेशन रद्द कर दिया गया है।';
	@override String get errorConflict => 'स्थिति में परिवर्तन एक और सत्र में. एक स्थिति का चयन करने के लिए आइटम को फिर से खोलें.';
	@override String get signIn => 'साइन इन';
	@override String get reconnect => 'फिर से जुड़ें';
	@override String get folderHelp => 'स्रोत के मूल फ़ोल्डर से शुरू करने के लिए इसे खाली छोड़ें। S3 URL में बकेट का नाम शामिल होता है।';
	@override String get preferences => 'प्राथमिकताएं';
	@override String get timePosition => 'स्थिति';
	@override String get audioTrack => 'ऑडियो ट्रैक';
	@override String get subtitleTrack => 'Subtitle ट्रैक';
	@override String get none => 'कोई नहीं';
	@override String get fullscreen => 'पूर्ण स्क्रीन';
	@override String get syncLocation => 'प्रगति सिंक्रनाइज़ेशन फ़ोल्डर (वैकल्पिक)';
	@override String get syncLocationHint => 'PlezyNG की स्थिति के लिए एक अलग WebDAV फ़ोल्डर। डेटा शर्त पूरी होने पर लिखा जाता है; मीडिया में कोई बदलाव नहीं होता।';
	@override String get audiobooks => 'ऑडियोबुक';
	@override String get comics => 'कॉमिक्स';
	@override String get scan => 'पुस्तक और मीडिया के लिए स्कैन';
	@override String get browserReader => 'खुले पाठक';
	@override String get browserReaderHelp => 'अपने ब्राउज़र में पढ़ने वाला खुला है. अपने स्थान और नोट्स को बचाने के लिए PlezyNG खुला रखें.';
	@override String get on => 'पर';
	@override String get advancedSetup => 'App रजिस्ट्रेशन';
	@override String get microsoftSignIn => 'Microsoft के साथ साइन इन करें';
	@override String get zoomIn => 'ज़ूम में';
	@override String get zoomOut => 'ज़ूम आउट';
	@override String get fitPage => 'फिट पेज';
	@override String get fitWidth => 'फिट विंडो';
	@override String get actualSize => 'वर्तमान आकार';
	@override String get goToPage => 'पृष्ठ पर जाएं';
	@override String get goToSection => 'अध्याय में जाओ';
	@override String pageRange({required Object count}) => '1 से ${count} तक का नंबर दर्ज करें';
	@override String get pageLayout => 'Page Layout के बारे में';
	@override String get automatic => 'स्वचालित';
	@override String get singlePage => 'एकल पृष्ठ';
	@override String get twoPages => '2 पृष्ठ';
	@override String get readingDirection => 'पढ़ने की दिशा';
	@override String get leftToRight => 'बाएँ से दाएँ';
	@override String get rightToLeft => 'दाएँ से बाएँ';
	@override String get letterSpacing => 'पत्र स्पेस';
	@override String get wordSpacing => 'शब्द स्पेस';
	@override String get readerControlsHelp => 'पृष्ठ बड़ा करने के लिए दो उँगलियाँ फैलाएँ या ज़ूम नियंत्रण का उपयोग करें। पृष्ठ खिसकाने के लिए खींचें। Ctrl/⌘ के साथ + या − ज़ूम बदलता है; Ctrl/⌘ के साथ 0 उसे रीसेट करता है। Page Up और Page Down से पृष्ठ बदलें।';
	@override String get imagePage => 'कॉमिक्स पृष्ठ';
	@override String get resetReader => 'पढ़ने की पसंद को पुनर्स्थापित करें';
	@override String get zoom => 'ज़ूम';
	@override String get useFiles => 'फ़ाइलों और किताबों का उपयोग करें';
	@override String get cancelScan => 'स्कैनिंग रद्द करें';
	@override String get googleDrive => 'Google Drive';
}

// Path: lending
class _Translations$lending$hi extends Translations$lending$en {
	_Translations$lending$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'सार्वजनिक पुस्तकालय';
	@override String get add => 'एक पुस्तकालय जोड़ें';
	@override String get other => 'एक और पुस्तकालय';
	@override String get libraryName => 'पुस्तकालय का नाम';
	@override String get libraryUrl => 'पुस्तकालय वेबसाइट';
	@override String get libraryUrlHint => 'अपने पुस्तकालय के कैटलॉग या साइन-इन पेज का उपयोग करें।';
	@override String get intro => 'अपनी लाइब्रेरी से किताबें उधार लें और उन्हें अपने पास रखें।';
	@override String get handoff => 'साइन इन करें, उधार लें और अपनी पुस्तकालय की सेवा के साथ सुरक्षित रूप से पढ़ें।';
	@override String get openService => 'खुली पुस्तकालय';
	@override String get findLibrary => 'एक पुस्तकालय खोजें';
	@override String get search => 'किताबें और लेखकों की खोज';
	@override String get catalogue => 'कैटलॉग';
	@override String get loans => 'ऋण';
	@override String get holds => 'आरक्षण';
	@override String get signIn => 'अपनी पुस्तकालय के साथ साइन इन करें';
	@override String get waiting => 'अपने ब्राउज़र में साइन इन करना बंद करें, फिर यहां वापस जाएं।';
	@override String get cancel => 'रद्द करना';
	@override String get disconnect => 'पुस्तकालय को हटा दें';
	@override String get disconnectMessage => 'इस लाइब्रेरी को इस प्रोफ़ाइल से हटाएँ? उधार ली गई किताबें और आरक्षण आपकी लाइब्रेरी में बने रहेंगे।';
	@override String get getBook => 'किताबें प्राप्त करें';
	@override String get checkAvailability => 'उपलब्धता की जांच करें';
	@override String get available => 'ऋण के लिए उपलब्ध';
	@override String get unavailable => 'वर्तमान में उपलब्ध नहीं';
	@override String get borrow => 'उधार लें';
	@override String get placeHold => 'आरक्षित करें';
	@override String get returnBook => 'जल्दी लौटें';
	@override String get cancelHold => 'आरक्षण रद्द करें';
	@override String get confirmBorrow => 'क्या आप अपनी पुस्तकालय से इस शीर्षक को उधार लेते हैं?';
	@override String get confirmReturn => 'यह किताब अभी लौटाएँ? पढ़ना जारी रखने के लिए इसे फिर से उधार लेना पड़ सकता है।';
	@override String get confirmCancelHold => 'इस किताब का अपना आरक्षण रद्द करें?';
	@override String get email => 'ईमेल नोटिस रखें';
	@override String due({required Object date}) => 'लौटाने की तारीख: ${date}';
	@override String queue({required Object position}) => 'पद ${position} लाइन में';
	@override String get empty => 'अभी तक कोई शीर्षक नहीं है।';
	@override String get openLibraryNote => 'Open Library के कैटलॉग का पता लगाएं. पढ़ने और ऋण के विकल्प प्रत्येक शीर्षक के पृष्ठ पर दिखाई देते हैं.';
	@override String get more => 'अधिक लोड करें';
	@override String get gateway => 'पुस्तकालय सेवा में हस्ताक्षर';
	@override String get gatewayHint => 'आपके पुस्तकालय या व्यवस्थापक द्वारा प्रदान किया गया PlezyNG।';
	@override String get advanced => 'पुस्तकालयों का संचालन';
	@override String get loadLibraries => 'अपनी पुस्तकालय चुनें';
	@override String get expired => 'यह ऋण समाप्त हो गया है।';
	@override String get updated => 'पुस्तकालय अद्यतन';
	@override String get continueService => 'सेवा में जारी रखें';
	@override String get comingSoon => 'जल्द ही आने वाले ऋण';
	@override String get comingSoonDescription => 'आप Libby में अपनी पुस्तकालय का उपयोग कर सकते हैं जबकि हम इसे कनेक्ट करने के लिए समाप्त कर सकते हैं।';
	@override String get suspendHold => 'आरक्षण अस्थायी रूप से रोकें';
	@override String get resumeHold => 'आरक्षण फिर से चालू करें';
	@override String get suspendMessage => 'कतार में अपनी जगह बनाए रखकर अगले पाठक को यह प्रति उधार लेने दें? आप बाद में आरक्षण फिर से चालू कर सकते हैं।';
	@override String get resumeMessage => 'यह आरक्षण फिर से चालू करें ताकि लाइब्रेरी अगली उपलब्ध प्रति आपको दे सके?';
	@override String get editEmail => 'ईमेल नोटिस बदलना';
}

// Path: audiobook
class _Translations$audiobook$hi extends Translations$audiobook$en {
	_Translations$audiobook$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get syncTitle => 'पढ़ना और सुनना सिंक्रनाइज़ेशन';
	@override String get syncHelp => 'अपने डिवाइस के माध्यम से पढ़ने की स्थिति, सुनने की स्थिति, पूरा होने की स्थिति, बुकमार्क और नोट्स रखें. एक संलग्न स्टोरेज खाता चुनें और प्रत्येक डिवाइस पर एक ही सिंक्रनाइज़ेशन कोड का उपयोग करें. पढ़ना और सुनना अलग रहता है.';
	@override String get addSyncSource => 'पहले फ़ाइलों और किताबों में Google ड्राइव, OneDrive, Dropbox, WebDAV या S3 जोड़ें।';
	@override String get syncDestination => 'सिंक्रनाइज़ेशन खाता';
	@override String get syncFolder => 'फ़ोल्डर सिंक्रनाइज़ेशन या Prefix';
	@override String get syncFolderHelp => 'अपने WebDAV स्रोत के भीतर एक अलग मौजूदा फ़ोल्डर का उपयोग करें, या एक समर्पित S3 पूर्वावलोकन. पुस्तक फ़ाइलों को कभी नहीं बदला जाता है.';
	@override String get syncCode => 'निजी सिंक्रनाइज़ेशन कोड';
	@override String get syncCodeHelp => 'अपने पहले डिवाइस पर एक कोड बनाएं, फिर उस कोड को अपने अन्य डिवाइस पर दर्ज करें. एक निजी प्रति बनाए रखें: यह आपके एन्क्रिप्टेड स्टेट की कुंजी है. प्रत्येक व्यक्ति के लिए एक अलग कोड का उपयोग करें.';
	@override String get showCode => 'प्रदर्शित करें या सिंक्रनाइज़ेशन कोड छिपाएं';
	@override String get newSyncCode => 'एक नया सिंक्रनाइज़ेशन कोड बनाएं';
	@override String get saveSync => 'Save और Sync';
	@override String get disableSync => 'इस डिवाइस पर सिंक्रनाइज़ेशन बंद करें';
	@override String get syncSourceDisconnect => 'इस स्रोत को हटाने से यहां पढ़ने और सुनने के लिए सिंक्रनाइज़ेशन बंद हो जाएगा. एन्क्रिप्टेड सिंक्रनाइज़ेशन फ़ाइल प्रदाता में रहेंगे.';
	@override String get syncReconnect => 'भंडारण खाते को फिर से कनेक्ट करें';
	@override String lastSynced({required Object time}) => '${time} पर अंतिम संश्लेषण';
	@override String get syncPrivacy => 'केवल एन्क्रिप्टेड प्रगति और नोट्स संग्रहीत किए जाते हैं. ऑडियो और ई-पुस्तक फ़ाइलें, खाता टोकन और पासवर्ड अपलोड नहीं किए जाते हैं. Google ड्राइव और OneDrive ऐप स्टोरेज का उपयोग करते हैं; ड्रॉपबॉक्स PlezyNG सिंक्रनाइज़ेशन का उपयोग करता है. सिंक्रनाइज़ेशन को सक्षम करने के लिए अतिरिक्त लिखित पहुंच की आवश्यकता हो सकती है. जबकि सक्षम है, इस गंतव्य में प्रगति सिंक्रनाइज़ेशन होता है; सर्वर प्रगति अलग रहती है. स्विच सिंक्रनाइज़ेशन स्थानीय इतिहास और दूरस्थ स्थिति बनाए रखता है.';
	@override String get syncConflicts => 'कहां वापस जाने के लिए चुनना';
	@override String get conflictHelp => 'इन परिवर्तनों को स्वतंत्र रूप से किया गया था. रखने के लिए स्थिति या नोटबुक संस्करण का चयन करें. एक बाद में टाइमस्टैम्प या एक उच्च प्रतिशत स्वचालित रूप से जीतता नहीं है.';
	@override String syncDevice({required Object device}) => 'डिवाइस ${device}';
	@override String get syncUnknownDevice => 'अज्ञात उपकरण';
	@override String get deletedBookmark => 'हटाए गए नोटबुक';
	@override String get finished => 'समाप्त';
	@override String readingPosition({required Object percent}) => 'पढ़ने के लिए · ${percent}%';
	@override String get chapterTimeline => 'अध्याय प्रगति';
	@override String get bookTimeline => 'पुस्तक प्रगति';
	@override String bookRemaining({required Object time}) => 'इस पुस्तक में शेष समय: ${time}';
	@override String chapterRemaining({required Object time}) => 'इस अध्याय में शेष समय: ${time}';
	@override String get unknownRemaining => 'कुल समय उपलब्ध है जब भागों को खेला जाता है';
	@override String get undoSeek => 'आखिरी खोज';
	@override String get customSpeed => 'प्लेबैक की गति';
	@override String get speedHelp => '0.25× से 4× तक की गति का चयन करें।';
	@override String get apply => 'आवेदन करें';
	@override String get customSleep => 'कस्टम नींद टाइमर';
	@override String get sleepMinutes => 'मिनट (1–1440)';
	@override String sleepChapters({required Object count}) => '${count} अध्याय के बाद रुकें';
	@override String get extendSleep => '5 मिनट जोड़ें';
	@override String sleepRemaining({required Object time}) => 'नींद टाइमर: ${time}';
	@override String get useDefaults => 'नई किताबों के लिए इन सुनने नियंत्रण का उपयोग करें';
	@override String get librarySort => 'विभिन्न किताबें';
	@override String get sortTitle => 'शीर्षक';
	@override String get sortAuthor => 'लेखक';
	@override String get sortNarrator => 'कथाकार';
	@override String get sortSeries => 'श्रृंखला आदेश';
	@override String get sortRecent => 'हाल ही में खोला गया';
	@override String get statusFilter => 'पढ़ने की स्थिति';
	@override String get statusAll => 'सभी किताबें';
	@override String get statusNew => 'शुरू नहीं हुआ';
	@override String get statusProgress => 'प्रगति में';
	@override String get statusFinished => 'समाप्त';
	@override String get goToTime => 'समय के लिए जाओ';
	@override String get timeHelp => 'घंटे: मिनट: सेकंड, या मिनट: सेकंड';
}

// Path: games
class _Translations$games$hi extends Translations$games$en {
	_Translations$games$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

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
	@override String get touchSetupHint => 'In a stream, use the controller’s settings button to move controls and change opacity. A Bluetooth or USB controller also works.';
	@override String get addGame => 'Add game shortcut';
	@override String get gameName => 'Game name';
	@override String get gameId => 'Host application ID';
	@override String get invalidGame => 'Enter a game name and a positive numeric host application ID.';
	@override String get wake => 'Wake computer';
	@override String get wakeSent => 'Wake request sent. The computer must support Wake-on-LAN on this network.';
	@override String get mac => 'MAC address (optional)';
	@override String get help => 'Games help';
	@override String get helpBody => 'Enable Games for your profile, keep Sunshine or another compatible host running, then choose a discovered computer. Approve the first connection and choose a game. Pairing authorization belongs to this device; the saved library belongs to this PlezyNG profile.\n\nThe Android engine is bundled into PlezyNG and includes touch controls and gamepad support. Other native platforms and Steam playback are still being implemented. Steam discovery does not mean playback is available.\n\nSunshine, Apollo, Wolf and older GameStream hosts can expose different features. Pairing requires the host’s approval. QR codes open the Sunshine PIN page; they do not carry your credentials.\n\nFor access away from home, use the computer’s VPN address. Automatic discovery normally stays on the local network.\n\nLeaving a stream keeps the game running on the computer. Stop it from the stream menu when you want to end the host session.';
	@override String get cancel => 'Cancel';
	@override String get scanning => 'Looking for computers…';
	@override String get saveShortcut => 'Save shortcut';
	@override String get manualHint => 'For Moonlight use the host’s GameStream HTTP port (usually 47989), not its web settings port. Steam normally advertises on 27036.';
	@override String get engineUnavailable => 'In-app streaming is not available here yet';
	@override String get nativeEnginePending => 'This build does not include a streaming engine for this platform. You can save the computer, but it cannot play here yet.';
	@override String get steamEnginePending => 'Steam computers can be discovered and saved. Embedded Steam pairing and playback are still in development, including the Pyrowave beta codec.';
	@override String get steamBetaTitle => 'Steam beta · Pyrowave';
	@override String get steamBetaDescription => 'Pyrowave support is planned for the embedded Steam engine. Discovery alone cannot tell whether a computer or this device can use it. Playback remains unavailable until the engine has been integrated and tested.';
}

// Path: appIcon.names
class _Translations$appIcon$names$hi extends Translations$appIcon$names$en {
	_Translations$appIcon$names$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get midnight => 'आधी रात';
	@override String get ember => 'आदमी';
	@override String get paper => 'कागज';
	@override String get oled => 'OLED';
	@override String get line => 'लाइन';
	@override String get ocean => 'महासागर';
	@override String get ultraviolet => 'अल्ट्रासाउंड';
	@override String get matcha => 'मैच';
	@override String get sunset => 'सूरज';
	@override String get gold => 'सोने';
	@override String get titanium => 'टाइटेनियम';
	@override String get glass => 'ग्लास';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => 'सिंथेटिक';
	@override String get pixel => 'पिक्सेल';
	@override String get neon => 'नियोन';
	@override String get sticker => 'स्टिकर';
	@override String get ticket => 'टिकट';
	@override String get pop => 'पॉप';
	@override String get strata => 'सड़क';
	@override String get facet => 'चेहरे';
	@override String get tilde => 'टिल्डर';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$hi extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

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
class _Translations$common$mediaKind$hi extends Translations$common$mediaKind$en {
	_Translations$common$mediaKind$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get movie => 'फिल्में';
	@override String get show => 'शो';
	@override String get season => 'मौसम';
	@override String get episode => 'घटनाएँ';
	@override String get artist => 'कलाकार';
	@override String get album => 'एल्बम';
	@override String get track => 'ट्रैक';
	@override String get collection => 'संग्रह';
	@override String get playlist => 'प्लेलिस्ट';
	@override String get clip => 'क्लिप';
	@override String get photo => 'फोटो';
	@override String get folder => 'फ़ोल्डर';
}

// Path: themeEditor.slots
class _Translations$themeEditor$slots$hi extends Translations$themeEditor$slots$en {
	_Translations$themeEditor$slots$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get bg => 'पृष्ठभूमि';
	@override String get surface => 'सतह';
	@override String get outline => 'आउटलाइन';
	@override String get text => 'पाठ';
	@override String get textMuted => 'माध्यमिक पाठ';
	@override String get accent => 'ध्यान';
}

// Path: themeEditor.contrast
class _Translations$themeEditor$contrast$hi extends Translations$themeEditor$contrast$en {
	_Translations$themeEditor$contrast$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => 'पृष्ठभूमि पर पाठ';
	@override String get textOnSurface => 'सतह पर पाठ';
	@override String get textMutedOnBg => 'पृष्ठभूमि पर माध्यमिक पाठ';
	@override String get textMutedOnSurface => 'सतह पर माध्यमिक पाठ';
	@override String get accentOnBg => 'पृष्ठभूमि पर ध्यान दें';
	@override String get accentOnSurface => 'सतह पर ध्यान दें';
	@override String get labelOnAccent => 'बटन लेबल पर ध्यान केंद्रित करें';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$hi extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'खेल / आराम';
	@override String get volumeUp => 'वॉल्यूम ऊपर';
	@override String get volumeDown => 'वॉल्यूम नीचे';
	@override String seekForward({required Object seconds}) => 'आगे की तलाश करें (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'पीछे की ओर खोजें (${seconds}s)';
	@override String get fullscreenToggle => 'पूर्ण स्क्रीन';
	@override String get muteToggle => 'मिट्टी के साथ';
	@override String get subtitleToggle => 'Subtitles के बारे में';
	@override String get audioTrackNext => 'अगला Audio Track';
	@override String get subtitleTrackNext => 'अगला Subtitle ट्रैक';
	@override String get chapterNext => 'अगला अध्याय';
	@override String get chapterPrevious => 'पिछला अध्याय';
	@override String get episodeNext => 'अगला एपिसोड';
	@override String get episodePrevious => 'पिछला एपिसोड';
	@override String get speedIncrease => 'गति बढ़ाना';
	@override String get speedDecrease => 'गति कम';
	@override String get speedReset => 'पुन: गति';
	@override String get zoomIn => 'ज़ूम में';
	@override String get zoomOut => 'ज़ूम बाहर';
	@override String get zoomReset => 'ज़ूम पुन:';
	@override String get subSeekNext => 'Next Subtitle के लिए खोजें';
	@override String get subSeekPrev => 'Previous Subtitle के बारे में जानें';
	@override String get subtitleDelayIncrease => 'Subtitles देरी';
	@override String get subtitleDelayDecrease => 'आगे के विषय';
	@override String get shaderToggle => 'छाया के साथ';
	@override String get skipMarker => 'क्रेडिट / क्रेडिट';
	@override String get screenshot => 'स्क्रीनशॉट लेना';
	@override String get framePrevious => 'पिछला फ्रेम';
	@override String get frameNext => 'अगला फ्रेम';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$hi extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Android 8.0 या नए की आवश्यकता होती है';
	@override String get iosVersion => 'iOS 15.0 या उससे अधिक की आवश्यकता है';
	@override String get permissionDisabled => 'Image-in-picture अक्षम है. इसे सिस्टम सेटिंग्स में सक्षम करें.';
	@override String get notSupported => 'डिवाइस छवि-इन-चित्र मोड का समर्थन नहीं करता है';
	@override String get voSwitchFailed => 'वीडियो आउटपुट को छवि-इन-चित्र के लिए स्विच करने में विफल';
	@override String get failed => 'फोटो-इन-चित्र शुरू नहीं हुआ';
	@override String get prepareFailed => 'फोटो-इन-चित्र तैयार नहीं किया जा सकता था';
	@override String unknown({required Object error}) => 'एक त्रुटि हुई: ${error}';
}

// Path: accountPreferences.groups
class _Translations$accountPreferences$groups$hi extends Translations$accountPreferences$groups$en {
	_Translations$accountPreferences$groups$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => 'ऑडियो और उपशीर्षक';
	@override String get libraryDisplay => 'लाइब्रेरी';
	@override String get personalMedia => 'व्यक्तिगत मीडिया';
}

// Path: accountPreferences.subtitleModes
class _Translations$accountPreferences$subtitleModes$hi extends Translations$accountPreferences$subtitleModes$en {
	_Translations$accountPreferences$subtitleModes$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get none => 'मैन्युअल रूप से चुने गए';
	@override String get noneDescription => 'कभी भी अपने आप में उपनाम नहीं बनाएं।';
	@override String get defaultMode => 'ट्रैक फ्लैग का पालन करें';
	@override String get defaultModeDescription => 'प्रत्येक उपनाम ट्रैक पर संग्रहीत डिफ़ॉल्ट और मजबूर झंडे का उपयोग करें।';
	@override String get always => 'हमेशा सक्षम';
	@override String get alwaysDescription => 'जब भी कोई मौजूद होता है, तो पसंदीदा भाषा में एक उप-ट्रेक ट्रैक पर स्विच करें।';
	@override String get onlyForced => 'केवल मजबूर उपनाम';
	@override String get onlyForcedDescription => 'केवल मजबूर के रूप में चिह्नित ट्रैक लोड करें।';
	@override String get smart => 'विदेशी ऑडियो के साथ प्रदर्शित';
	@override String get smartDescription => 'केवल तभी उप शीर्षक पर स्विच करें जब ऑडियो किसी अन्य भाषा में है।';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class _Translations$accountPreferences$subtitleAccessibilityOptions$hi extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	_Translations$accountPreferences$subtitleAccessibilityOptions$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'गैर-एसडीएच उपशीर्षक पसंद';
	@override String get preferSdh => 'SDH उपनाम पसंद';
	@override String get onlySdh => 'केवल SDH उपनाम';
	@override String get onlyNonSdh => 'केवल गैर-एसडीएच उपनाम';
}

// Path: accountPreferences.forcedSubtitleOptions
class _Translations$accountPreferences$forcedSubtitleOptions$hi extends Translations$accountPreferences$forcedSubtitleOptions$en {
	_Translations$accountPreferences$forcedSubtitleOptions$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => 'अनियंत्रित उपनाम पसंद करें';
	@override String get preferForced => 'मजबूर subtitles पसंद करें';
	@override String get onlyForced => 'केवल मजबूर उपनाम';
	@override String get onlyNonForced => 'केवल अनियंत्रित उपनाम';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$hi extends Translations$accountPreferences$watchedIndicatorOptions$en {
	_Translations$accountPreferences$watchedIndicatorOptions$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get none => 'कभी नहीं';
	@override String get moviesAndShows => 'फिल्में और टीवी शो';
	@override String get movies => 'केवल फिल्में';
	@override String get shows => 'केवल टीवी शो';
}

// Path: accountPreferences.mediaReviewsOptions
class _Translations$accountPreferences$mediaReviewsOptions$hi extends Translations$accountPreferences$mediaReviewsOptions$en {
	_Translations$accountPreferences$mediaReviewsOptions$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'उपयोगकर्ताओं और आलोचकों';
	@override String get usersOnly => 'केवल उपयोगकर्ता';
	@override String get criticsOnly => 'केवल आलोचक';
	@override String get nobody => 'छिपा हुआ';
}

// Path: discover.findNext
class _Translations$discover$findNext$hi extends Translations$discover$findNext$en {
	_Translations$discover$findNext$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'अपने अगले को खोजें';
	@override String get open => 'अपने अगले को खोजें';
	@override String get anyTime => 'किसी भी समय';
	@override String get timeAvailable => 'आपके पास कितना समय है?';
	@override String get filters => 'क्षण चुनें';
	@override String get watch => 'देखें';
	@override String get listen => 'सुनो';
	@override String get read => 'पढ़ना';
	@override String finishable({required Object duration}) => '${duration} में समाप्त';
	@override String aboutDuration({required Object duration}) => 'के बारे में ${duration}';
	@override String nextUnit({required Object duration}) => 'अगले अध्याय · ${duration}';
	@override String totalDuration({required Object duration}) => '${duration} कुल';
	@override String get timingVaries => 'समय बदलता है';
	@override String get notNow => 'अब नहीं';
	@override String get swipeHint => 'स्विप करें, या नीचे दिए गए बटन का उपयोग करें';
	@override String get saved => 'बचाए गए पिक्से';
	@override String savedCount({required Object count}) => 'संपादित करें · ${count}';
	@override String get undo => 'और';
	@override String get details => 'विवरण';
	@override String get noPicks => 'अभी तक चुनने के लिए कुछ भी नहीं';
	@override String get noPicksHint => 'एक लाइब्रेरी से कनेक्ट करें या शुरू करने के लिए एक मीडिया स्रोत जोड़ें।';
	@override String get noMatches => 'इस क्षण के लिए कुछ भी नहीं है';
	@override String get noMatchesHint => 'एक और प्रारूप का प्रयास करें या खुद को अधिक समय दें।';
	@override String get allDone => 'आप सभी पकड़े गए हैं';
	@override String get allDoneHint => 'इन विकल्पों को फिर से देखने के लिए एक ताजा मिश्रण शुरू करें।';
	@override String get refresh => 'एक और मिश्रण खोजें';
	@override String sourceReason({required Object source}) => 'से ${source}';
	@override String libraryReason({required Object library}) => 'से ${library}';
	@override String get ownedReason => 'आपकी पुस्तकालय से';
	@override String get liveNow => 'अब में';
	@override String get watchLive => 'देखें लाइव';
	@override String get filterAnything => 'सब कुछ';
	@override String get filterWatch => 'देखें';
	@override String get filterListen => 'सुनो';
	@override String get filterRead => 'पढ़ना';
	@override String get twentyMinutes => '20 मिनट';
	@override String get fortyFiveMinutes => '45 मिनट';
	@override String get ninetyMinutes => '90 मिनट';
	@override String get apply => 'आवेदन करें';
	@override String get openFailed => 'यह विकल्प अब उपलब्ध नहीं है. फिर से जांच करने के लिए ताज़ा करें.';
	@override String get changeFailed => 'यह बदलाव नहीं किया जा सकता है. फिर से कोशिश करें.';
	@override String get savedLimit => 'बचाए गए पिक्स भरे हुए हैं. एक चयन को हटाने के लिए दूसरे को बचाने के लिए.';
}

// Path: discover.person
class _Translations$discover$person$hi extends Translations$discover$person$en {
	_Translations$discover$person$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get born => 'जन्म';
	@override String get died => 'मृत';
	@override String get birthplace => 'जन्म स्थान';
	@override String dateWithAge({required Object date, required Object age}) => '${date} (वय ${age})';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (वय ${age})';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$hi extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'अनुशंसित';
	@override String get browse => 'ब्राउज़';
	@override String get collections => 'संग्रह';
	@override String get playlists => 'प्लेलिस्ट';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$hi extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'समूह';
	@override String get all => 'सारे';
	@override String get movies => 'फ़िल्में';
	@override String get shows => 'टीवी शो';
	@override String get seasons => 'मौसम';
	@override String get episodes => 'एपिसोड';
	@override String get artists => 'कलाकार';
	@override String get albums => 'एल्बम';
	@override String get tracks => 'ट्रैक';
	@override String get folders => 'फ़ोल्डर';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$hi extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get genre => 'जीन';
	@override String get year => 'वर्ष';
	@override String get contentRating => 'सामग्री रेटिंग';
	@override String get tag => 'Tag';
	@override String get unwatched => 'अनदेखा';
	@override String get unplayed => 'अनदेखा';
	@override String get favorites => 'पसंदीदा';
	@override String get filePath => 'फ़ाइल मार्ग';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$hi extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'शीर्षक';
	@override String get dateAdded => 'तिथि जोड़ी गई';
	@override String get releaseDate => 'रिलीज की तारीख';
	@override String get rating => 'रेटिंग';
	@override String get communityRating => 'सामुदायिक रेटिंग';
	@override String get criticRating => 'महत्वपूर्ण रेटिंग';
	@override String get userRating => 'उपयोगकर्ता रेटिंग';
	@override String get datePlayed => 'प्ले करने की तिथि';
	@override String get playCount => 'खेलों की संख्या';
	@override String get productionYear => 'उत्पादन वर्ष';
	@override String get runtime => 'रनटाइम';
	@override String get officialRating => 'आधिकारिक रेटिंग';
	@override String get premiereDate => 'प्रारंभिक तारीख';
	@override String get startDate => 'शुरुआती तारीख';
	@override String get airTime => 'एयर टाइम';
	@override String get studio => 'स्टूडियो';
	@override String get random => 'संयोग';
	@override String get dateShared => 'तारीख साझा';
	@override String get latestEpisodeAirDate => 'अंतिम संस्करण एयर डेटा';
	@override String get lastEpisodeDateAdded => 'अंतिम संस्करण की तारीख जोड़ा गया';
	@override String get dateDownloaded => 'डाउनलोड की तारीख';
	@override String get size => 'आकार';
	@override String get library => 'लाइब्रेरी';
}

// Path: libraries.advancedFilters
class _Translations$libraries$advancedFilters$hi extends Translations$libraries$advancedFilters$en {
	_Translations$libraries$advancedFilters$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get include => 'शामिल है';
	@override String get exclude => 'बाहर';
	@override String get any => 'किसी भी';
	@override String get yes => 'हाँ';
	@override String get no => 'नहीं';
	@override String not({required Object value}) => 'नहीं ${value}';
	@override String valueCount({required Object count}) => '${count} चुने गए';
	@override String valueCountExcluded({required Object count}) => '${count} को छोड़ दिया गया';
	@override String get searchValues => 'खोज मूल्य';
	@override String get noValues => 'कोई मूल्य नहीं';
	@override String get matchContains => 'कंटेनर';
	@override String get matchNotContains => 'इसमें शामिल नहीं है';
	@override String get matchIs => 'है';
	@override String get matchIsNot => 'नहीं है';
	@override String get matchBeginsWith => 'शुरुआत के साथ';
	@override String get matchEndsWith => 'समाप्त होता है';
	@override String get textHint => 'मैच करने के लिए प्रकार';
	@override String get from => 'से';
	@override String get to => 'के लिए';
	@override String range({required Object from, required Object to}) => '${from} से ${to} तक';
	@override String atLeast({required Object value}) => '${value} और ऊपर';
	@override String atMost({required Object value}) => '${value} तक';
	@override String dateLastDays({required Object count}) => '${count} दिन पहले';
	@override String get dateLastYear => 'पिछले साल';
	@override String dateOlderThanDays({required Object count}) => '${count} दिनों से अधिक पुराना';
	@override String get dateOlderThanYear => 'एक साल से अधिक उम्र के';
}

// Path: libraries.selection
class _Translations$libraries$selection$hi extends Translations$libraries$selection$en {
	_Translations$libraries$selection$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get selectItems => 'आइटम चुनें';
	@override String selectedCount({required Object count}) => '${count} चुने गए';
	@override String get actions => 'चयन कार्य';
	@override String get confirmDescendants => 'यह चयनित शो और मौसमों में सभी एपिसोडों को बदलता है।';
	@override String get confirmUnwatched => 'यह भी चुने हुए आइटम के लिए प्लेबैक प्रगति को साफ करता है।';
	@override String confirmCount({required Object count}) => 'चयनित आइटम: ${count}.';
	@override String completed({required Object count}) => 'पदों की संख्या: ${count}';
	@override String partialFailure({required Object succeeded, required Object failed}) => 'अद्यतन ${succeeded}; असफल ${failed}. असफल आइटम चुने हुए रहते हैं।';
}

// Path: explore.mdblistShelves
class _Translations$explore$mdblistShelves$hi extends Translations$explore$mdblistShelves$en {
	_Translations$explore$mdblistShelves$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get manage => 'प्रबंधन ढांचे का पता लगाएं';
	@override String get manageDescription => 'अपने MDBList खाते से सूची चुनना और व्यवस्थित करना';
	@override String get description => 'अपने MDBList खाते से सार्वजनिक फिल्म और टीवी सूचियों का चयन करें. MDBList पर सूचियों को बनाएं या कॉपी करें, फिर ताज़ा करें.';
	@override String get selected => 'चुने हुए सीटें';
	@override String get available => 'उपलब्ध खातों की सूची';
	@override String get noLists => 'कोई सार्वजनिक फिल्म या टेलीविजन सूची वापस नहीं आई. एक सूची बनाएं या कॉपी करें MDBList, फिर ताज़ा करें.';
	@override String get displayName => 'शेल नाम प्रदर्शित';
	@override String get nameHint => 'स्रोत सूची नाम का उपयोग करने के लिए सफेद छोड़ दें।';
	@override String get add => 'शेल को जोड़ें';
	@override String get save => 'सीटों को बचाएं';
	@override String moveUp({required Object title}) => '${title} से ऊपर';
	@override String moveDown({required Object title}) => '${title} नीचे जाने के लिए';
	@override String get unavailable => 'यह सूची उपलब्ध नहीं है. सेटिंग्स में अपने शेल्फ को वापस या हटा दें.';
	@override String get rateLimited => 'MDBList अनुरोध सीमा तक पहुंच गया. कृपया बाद में वापस लौटें.';
	@override String get loadFailed => 'आप अपने कनेक्शन और रिट्री की जांच कर सकते हैं।';
	@override String get saveFailed => 'मैं नहीं चाहता कि आप अपने कैनवास को बचा सकें. कृपया वापस लौटें.';
	@override String get accountChanged => 'खाता या प्रोफ़ाइल बदल गया. इन सेटिंग्स को फिर से खोलें.';
	@override String get settingsUnreadable => 'बचाए गए शीटों को पढ़ा नहीं जा सकता. इन सेटिंग्स को बदलने के लिए अपनी सूची को फिर से चुनें.';
}

// Path: explore.rows
class _Translations$explore$rows$hi extends Translations$explore$rows$en {
	_Translations$explore$rows$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'चेकलिस्ट';
	@override String get recommendedMovies => 'अनुशंसित फिल्में';
	@override String get recommendedShows => 'अनुशंसित शो';
	@override String get trendingMovies => 'ट्रेंड फिल्में';
	@override String get trendingShows => 'ट्रेंड शो';
	@override String get popularMovies => 'लोकप्रिय फिल्में';
	@override String get popularShows => 'लोकप्रिय शो';
	@override String get trendingAnime => 'एनिमेटेड ट्रेंड';
	@override String get suggestedAnime => 'अनुशंसित एनीम';
	@override String get airingAnime => 'शीर्ष एनीमिया';
	@override String get popularAnime => 'सबसे लोकप्रिय एनीमिया';
	@override String get trending => 'रुझान';
	@override String get upcomingMovies => 'आने वाले फिल्मों';
	@override String get upcomingShows => 'आने वाले शो';
}

// Path: explore.status
class _Translations$explore$status$hi extends Translations$explore$status$en {
	_Translations$explore$status$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get airing => 'एयरिंग';
	@override String get ended => 'समाप्त';
	@override String get canceled => 'रद्द';
	@override String get upcoming => 'आने वाले';
}

// Path: explore.badge
class _Translations$explore$badge$hi extends Translations$explore$badge$en {
	_Translations$explore$badge$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} लोकप्रिय';
	@override String rankAiring({required Object n}) => '# ${n} एयरिंग';
	@override String rankRated({required Object n}) => '#${n} रेट किया गया';
	@override String rankTrending({required Object n}) => '#${n} ट्रेंडिंग';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} में ${season}';
	@override String watchingNow({required Object n}) => '${n} देखें';
	@override String get available => 'उपलब्ध';
	@override String get partiallyAvailable => 'आंशिक उपलब्ध';
	@override String get availableIn4k => '4K उपलब्ध है';
	@override String get requested => 'अनुरोध';
	@override String get pendingApproval => 'अनुमोदन के लिए';
	@override String get processing => 'प्रसंस्करण';
	@override String get declined => 'गिरावट';
	@override String get requestFailed => 'अनुरोध विफल';
	@override String get requested4k => '4K की मांग';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} मौसम';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => 'एप ${episode} में ${duration}';
	@override String nextAiringIn({required Object duration}) => 'अगले में ${duration}';
	@override String episodesShort({required Object n}) => '${n} ईपीएस';
	@override String minutesPerEpisode({required Object n}) => '${n} मिनट / एप';
	@override String get adult => '18+';
}

// Path: explore.stats
class _Translations$explore$stats$hi extends Translations$explore$stats$en {
	_Translations$explore$stats$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} सूचीबद्ध';
	@override String viewersDay({required Object n}) => '${n} आज देखा गया';
	@override String viewersWeek({required Object n}) => 'इस हफ्ते ${n} बार देखा गया';
	@override String viewersMonth({required Object n}) => 'इस महीने ${n} बार देखा गया';
	@override String viewersYear({required Object n}) => 'इस साल ${n} बार देखा गया';
	@override String viewersAllTime({required Object n}) => '${n} दर्शक';
	@override String planning({required Object n}) => '${n} देखने के लिए योजना';
	@override String favorited({required Object n}) => '${n} पसंद';
	@override String dropRate({required Object percent}) => '${percent} इसे छोड़ दिया';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} टिप्पणियाँ',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} टिप्पणियाँ',
	);
	@override String votes({required Object n}) => '${n} वोट';
	@override String watching({required Object n}) => '${n} इसे देखें';
	@override String completed({required Object n}) => '${n} पूरा हो गया';
	@override String onHold({required Object n}) => '${n} पर रखें';
	@override String dropped({required Object n}) => '${n} गिरावट';
}

// Path: explore.season
class _Translations$explore$season$hi extends Translations$explore$season$en {
	_Translations$explore$season$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get winter => 'सर्दियों';
	@override String get spring => 'वसंत';
	@override String get summer => 'ग्रीष्मकालीन';
	@override String get fall => 'गिरना';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class _Translations$explore$format$hi extends Translations$explore$format$en {
	_Translations$explore$format$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get tv => 'टीवी';
	@override String get tvShort => 'टीवी संक्षिप्त';
	@override String get movie => 'फिल्में';
	@override String get special => 'विशेष';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => 'संगीत';
	@override String get other => 'अन्य';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$hi extends Translations$explore$sourceMaterial$en {
	_Translations$explore$sourceMaterial$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get original => 'मूल';
	@override String get manga => 'मंगेशकर';
	@override String get lightNovel => 'प्रकाश की कहानी';
	@override String get novel => 'उपन्यास';
	@override String get visualNovel => 'दृश्य कथा';
	@override String get game => 'खेल';
	@override String get webComic => 'Web कॉमिक्स';
	@override String get musicRelease => 'संगीत';
	@override String get otherMedia => 'अन्य';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$hi extends Translations$explore$creditRole$en {
	_Translations$explore$creditRole$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get actor => 'अभिनेता';
	@override String get director => 'निर्देशक';
	@override String get writer => 'लेखक';
	@override String get producer => 'निर्माता';
	@override String get creator => 'निर्माता';
	@override String get composer => 'संगीतकार';
}

// Path: explore.relation
class _Translations$explore$relation$hi extends Translations$explore$relation$en {
	_Translations$explore$relation$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get prequel => 'प्रीमियम';
	@override String get sequel => 'सेक्युल';
	@override String get sideStory => 'साइड कहानी';
	@override String get spinOff => 'स्पिन-ऑफ';
	@override String get alternativeVersion => 'वैकल्पिक संस्करण';
	@override String get summary => 'संक्षेप में';
	@override String get parentStory => 'माता-पिता की कहानी';
	@override String get adaptation => 'अनुकूलन';
	@override String get other => 'संबंधित';
}

// Path: explore.detail
class _Translations$explore$detail$hi extends Translations$explore$detail$en {
	_Translations$explore$detail$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'मूल शीर्षक';
	@override String get alsoKnownAs => 'यह भी ज्ञात है कि';
	@override String get studios => 'अध्ययन';
	@override String get country => 'देश';
	@override String get language => 'भाषा';
	@override String get released => 'रिलीज';
	@override String get physicalRelease => 'डिस्क पर';
	@override String get ended => 'समाप्त';
	@override String addedOn({required Object date}) => 'पदों की संख्या ${date}';
	@override String get yourRating => 'आपकी रेटिंग';
	@override String get budget => 'बजट';
	@override String get revenue => 'बॉक्स ऑफिस';
	@override String get contentAdvisory => 'उम्र का मार्गदर्शन';
	@override String get tags => 'टैग';
	@override String get revealSpoilerTags => 'स्पॉलर टैग';
	@override String get links => 'बाएं';
	@override String get watchOn => 'देखें';
	@override String get watchTrailer => 'ट्रेलर देखें';
	@override String openOn({required Object site}) => 'पर खोला गया ${site}';
	@override String get crew => 'चालक दल';
	@override String get ratings => 'रेटिंग';
	@override String get schedule => 'कार्यक्रम';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n,
		one: 'अनुशंसित ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} उपयोगकर्ताओं द्वारा',
		other: 'अनुशंसित ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} उपयोगकर्ताओं द्वारा',
	);
	@override String recommendedBy({required Object who}) => '${who} द्वारा अनुशंसित';
	@override String favoritedBy({required Object who}) => 'पसंदीदा पृष्ठ ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} अभी तक प्रकाशित नहीं किया गया';
	@override String recommendedByPercent({required Object percent}) => 'अनुशंसित ${percent} दर्शकों द्वारा';
	@override String get relatedTitles => 'संबंधित शीर्षक';
	@override String get background => 'पृष्ठभूमि';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$hi extends Translations$liveTv$recordSettings$en {
	_Translations$liveTv$recordSettings$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get startEarly => 'शुरुआत जल्दी (सेकंड)';
	@override String get endLate => 'देर से समाप्त (अध्याय)';
	@override String get newOnly => 'केवल नई घटनाएं';
	@override String get anyChannel => 'किसी भी चैनल पर रिकॉर्ड';
	@override String get anyTime => 'किसी भी समय रिकॉर्ड';
	@override String get skipInLibrary => 'पुस्तकालय में पहले से ही एपिसोड को हटा दें';
	@override String get keepUpTo => 'बनाए रखने के लिए घटनाएं';
	@override String get keepUpToHint => '0 हर एपिसोड को बनाए रखें';
}

// Path: music.discography
class _Translations$music$discography$hi extends Translations$music$discography$en {
	_Translations$music$discography$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'सींग्स & EPs';
	@override String get live => 'जीवित';
	@override String get compilations => 'संकलित';
}

// Path: watchTogether.notices
class _Translations$watchTogether$notices$hi extends Translations$watchTogether$notices$en {
	_Translations$watchTogether$notices$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name} प्रिंट गेम';
	@override String get playbackStarted => 'Playback शुरू';
	@override String paused({required Object name}) => '${name} आउटपुट';
	@override String get playbackPaused => 'Playback बंद हो गया';
	@override String jumpedTo({required Object name, required Object position}) => '${name} ${position} पर कूद गया';
	@override String roomJumpedTo({required Object position}) => '${position} के बारे में जानकारी';
	@override String changedSpeed({required Object name, required Object speed}) => '${name} गति सेट करें ${speed}';
	@override String speedChanged({required Object speed}) => 'गति सेट ${speed}';
	@override String startedMedia({required Object name, required Object title}) => '${name} शुरू ${title}';
	@override String mediaStarted({required Object title}) => 'अब खेलने के लिए ${title}';
	@override String stoppedMedia({required Object name}) => '${name} वीडियो बंद कर दिया';
	@override String get mediaStopped => 'वीडियो बंद हो गया';
	@override String waitingFor({required Object name}) => '${name} के लिए इंतजार कर रहे हैं ...';
	@override String get waitingForSomeone => 'किसी को पकड़ने के लिए इंतजार कर रहे हैं ...';
	@override String get finished => 'समाप्त';
	@override String hostChangedTo({required Object name}) => '${name} अब होस्ट है';
	@override String get youAreNowHost => 'अब आप मेजबान हैं';
	@override String joined({required Object name}) => '${name} में शामिल';
	@override String left({required Object name}) => '${name} छोड़ दिया';
	@override String get controlRefused => 'केवल मेजबान प्लेबैक को नियंत्रित कर सकता है';
	@override String get searchFailed => 'कुछ सर्वरों को कमरे के वीडियो के लिए खोज नहीं की जा सकती थी';
	@override String get playBlocked => 'प्रिंट खेल शुरू करने के लिए';
	@override String get shareFailed => 'इस वीडियो को कमरे के साथ साझा नहीं किया जा सकता';
	@override String get downloadNotShared => 'डाउनलोड कमरे के साथ साझा नहीं होते हैं जबकि उनके सर्वर ऑफ़लाइन हैं';
	@override String get openFailed => 'कमरे का वीडियो नहीं खोल सकता था';
}

// Path: watchTogether.ended
class _Translations$watchTogether$ended$hi extends Translations$watchTogether$ended$en {
	_Translations$watchTogether$ended$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get ended => 'मेजबान ने कमरे को खत्म कर दिया';
	@override String get kicked => 'आपको कमरे से बाहर निकाला गया था।';
	@override String get expired => 'कमरे खत्म हो गए';
	@override String get replaced => 'आपने इस कमरे को किसी अन्य डिवाइस पर जोड़ा है';
	@override String get lost => 'कमरे से कनेक्शन खोना';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$hi extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => 'कोड में 6 अक्षर और अंक होते हैं, बिना 0, 1, I, L या O के।';
	@override String get roomNotFound => 'इस कोड में कोई कमरा नहीं है. यह समाप्त हो सकता है.';
	@override String get roomFull => 'यह कमरा भरा हुआ है।';
	@override String get roomLocked => 'मेजबान ने उस कमरे को बंद कर दिया।';
	@override String get relayFull => 'देखो एक साथ अब व्यस्त है. बाद में फिर से कोशिश करें.';
	@override String get unreachable => 'मैं घड़ी को एक साथ रिलीज नहीं कर सकता था. अपने कनेक्शन की जांच करें.';
	@override String get rateLimited => 'थोड़ी देर इंतजार करें और फिर से कोशिश करें।';
	@override String get clientBlocked => 'इस संस्करण PlezyNG रिले का उपयोग नहीं कर सकता. ऐप को अपडेट करें.';
	@override String get forbidden => 'केवल मेजबान ही ऐसा कर सकते हैं।';
	@override String get notInRoom => 'आप एक कमरे में नहीं हैं।';
	@override String get alreadyInRoom => 'आप पहले से ही एक कमरे में हैं।';
	@override String get resumeFailed => 'कमरे में नहीं आ सकता था।';
	@override String get unsupported => 'रिलीज इस बात का समर्थन नहीं करती है।';
	@override String get generic => 'कुछ गलत हो गया, फिर से कोशिश करें।';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$hi extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'डाउनलोड बंद हो जाएगा जब आप ऐप छोड़ देंगे';
	@override String get bannerDegraded => 'पृष्ठभूमि डाउनलोड सीमित हो सकते हैं';
	@override String get bannerAction => 'विवरण';
	@override String get sheetTitle => 'पृष्ठभूमि डाउनलोड ब्लॉक किया गया है';
	@override String get sheetTitleDegraded => 'पृष्ठभूमि डाउनलोड सीमित हो सकते हैं';
	@override String get sheetIntro => 'Android पृष्ठभूमि में विश्वसनीय रूप से डाउनलोड करने से PlezyNG को रोकता है।';
	@override String get sheetIntroDegraded => 'आपका डिवाइस तब सीमित है जब PlezyNG पृष्ठभूमि में डाउनलोड किया जा सकता है।';
	@override String get reasonBackgroundRestricted => 'PlezyNG का पृष्ठभूमि उपयोग सीमित है. बैटरी या पृष्ठभूमि उपयोग को "असीमित" पर सेट करें.';
	@override String get reasonStandbyRestricted => 'Android ने PlezyNG को एक सीमित स्टैंडबी स्थिति में रखा है. बैटरी का उपयोग "असीमित" पर सेट करें.';
	@override String get reasonDownloadChannelBlocked => 'डाउनलोड सूचनाएं बंद हो जाती हैं, इसलिए प्रगति और नियंत्रण उपलब्ध नहीं हो सकते हैं।';
	@override String get reasonNotificationsDisabled => 'नोटिस बंद हो जाते हैं. Android 13 या बाद में, वे लंबी पृष्ठभूमि डाउनलोड के लिए आवश्यक हैं.';
	@override String get reasonDataSaver => 'डेटा सहेजने पर है, जो मोबाइल डेटा पर पृष्ठभूमि डाउनलोड ब्लॉक करता है. डाउनलोड अभी भी Wi-Fi पर चलना चाहिए.';
	@override String get reasonOemUnknown => 'डाउनलोड बार-बार बंद हो गए जबकि PlezyNG पृष्ठभूमि में था. PlezyNG की बैटरी या पृष्ठभूमि उपयोग सेटिंग्स की जांच करें.';
	@override String get openSettings => 'खुले सेटिंग्स';
	@override String get stillNotWorking => 'उपकरण-विशिष्ट सहायता';
	@override String get stillNotWorkingDescription => 'अपने डिवाइस के लिए कदम देखें, या यदि समस्या जारी है तो सेटिंग्स › लॉग देखें से एक लॉग भेजें।';
	@override String get dialogTitle => 'डाउनलोड समाप्त नहीं हो सकता है';
	@override String get dialogDownloadAnyway => 'किसी भी तरह डाउनलोड करें';
	@override String get dialogFixFirst => 'इसे पहले ठीक करें';
	@override String get statusTile => 'पृष्ठभूमि डाउनलोड';
	@override String get statusOk => 'पृष्ठभूमि में चलने की अनुमति';
	@override String get statusBlocked => 'सिस्टम सेटिंग्स द्वारा अवरुद्ध';
	@override String get statusDegraded => 'सिस्टम सेटिंग्स से सीमित';
	@override String get statusUnknown => 'अभी तक जांच नहीं';
	@override String get settingsUnavailable => 'इस डिवाइस पर सिस्टम सेटिंग्स नहीं खोला जा सकता';
	@override String get linkUnavailable => 'इस डिवाइस पर dontkillmyapp.com नहीं खोला जा सकता';
}

// Path: downloads.groupings
class _Translations$downloads$groupings$hi extends Translations$downloads$groupings$en {
	_Translations$downloads$groupings$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get library => 'लाइब्रेरी';
	@override String get collections => 'संग्रह';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$hi extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'दूरस्थ सर्वर से शुरू करें';
	@override String get hostAddress => 'मेजबान का पता';
	@override String get connected => 'कनेक्ट';
	@override String get serverRunning => 'Remote Server सक्रिय';
	@override String get serverStopped => 'दूरस्थ सर्वर बंद';
	@override String get serverRunningDescription => 'आपके नेटवर्क पर मोबाइल उपकरण इस ऐप से कनेक्ट कर सकते हैं';
	@override String get serverStoppedDescription => 'सर्वर शुरू करें ताकि मोबाइल उपकरणों को कनेक्ट करने की अनुमति मिल सके';
	@override String get usePhoneToControl => 'इस एप्लिकेशन को नियंत्रित करने के लिए अपने मोबाइल डिवाइस का उपयोग करें';
	@override String get startServer => 'सर्वर शुरू करें';
	@override String get stopServer => 'सर्वर बंद करें';
	@override String get minimize => 'कम से कम';
	@override String get manualAddressHint => 'मैनुअल कनेक्शन पता:';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$hi extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'PlezyNG उपकरणों के साथ एक ही Plex खाता यहाँ दिखाई देता है';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'कनेक्ट...';
	@override String get searchingForDevices => 'उपकरणों की तलाश में...';
	@override String get noDevicesFound => 'आपके नेटवर्क पर कोई उपकरण नहीं मिला';
	@override String get noDevicesHint => 'डेस्कटॉप पर PlezyNG खोलें और उसी Wi-Fi का उपयोग करें';
	@override String get availableDevices => 'उपलब्ध उपकरण';
	@override String get manualConnection => 'मैनुअल कनेक्शन';
	@override String get cryptoInitFailed => 'सुरक्षित कनेक्शन शुरू नहीं किया जा सकता. पहले Plex पर साइन इन करें.';
	@override String get validationHostRequired => 'कृपया होस्ट एड्रेस दर्ज करें';
	@override String get validationHostFormat => 'प्रारूप IP:port होना चाहिए (उदाहरण के लिए, 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'दोनों उपकरणों पर एक ही नेटवर्क का उपयोग करें।';
	@override String get sessionNotFound => 'डिवाइस नहीं मिला. सुनिश्चित करें कि PlezyNG होस्ट पर चल रहा है.';
	@override String get authFailed => 'दोनों डिवाइसों को एक ही Plex खाता की आवश्यकता होती है।';
	@override String failedToConnect({required Object error}) => 'कनेक्ट करने में विफल: ${error}';
	@override String get codeTitle => 'जोड़े कोड';
	@override String get codeDescription => 'होस्ट डिवाइस पर Companion Remote में दिखाए गए कोड दर्ज करें. दोनों डिवाइसों को एक संस्करण का उपयोग करना होगा जो सुरक्षित जोड़ का समर्थन करता है.';
	@override String get codeInvalid => 'होस्ट कोड से सभी 32 अक्षरों और संख्याओं को दर्ज करें।';
	@override String get updateRequired => 'दोनों डिवाइसों को एक संस्करण में अपडेट करें जो सुरक्षित जोड़ का समर्थन करता है।';
	@override String get hostDescription => 'प्रत्येक रिमोट पर एक बार इस कोड दर्ज करें. इसे गोपनीय रखें: यह इस प्रोफ़ाइल का नियंत्रण प्रदान करता है.';
	@override String get resetCode => 'पुन: पेरिंग कोड';
	@override String get resetDescription => 'सभी रिमोट्स को कनेक्ट करें और एक नया कोड बनाएं. प्रत्येक रिमोट को फिर से जोड़ने की आवश्यकता होगी.';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$hi extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'क्या आप दूरस्थ सत्र से कनेक्ट करना चाहते हैं?';
	@override String get reconnecting => 'फिर से कनेक्ट...';
	@override String attemptOf({required Object current}) => 'अनुच्छेद ${current} में से 5';
	@override String get retryNow => 'अब वापस';
	@override String get tabRemote => 'दूर';
	@override String get tabPlay => 'खेलना';
	@override String get tabMore => 'अधिक';
	@override String get menu => 'मेनू';
	@override String get tabNavigation => 'टैब नेविगेशन';
	@override String get tabDiscover => 'खोजें';
	@override String get tabLibraries => 'पुस्तकालय';
	@override String get tabSearch => 'खोज';
	@override String get tabDownloads => 'डाउनलोड';
	@override String get tabSettings => 'सेटिंग्स';
	@override String get previous => 'पिछला';
	@override String get playPause => 'खेल / आराम';
	@override String get next => 'अगला';
	@override String get seekBack => 'वापस खोजें';
	@override String get stop => 'रोकें';
	@override String get seekForward => 'FWD की खोज';
	@override String get volume => 'वॉल्यूम';
	@override String get volumeDown => 'नीचे';
	@override String get volumeUp => 'ऊपर';
	@override String get fullscreen => 'पूर्ण स्क्रीन';
	@override String get subtitles => 'उपशीर्षक';
	@override String get audio => 'ऑडियो';
	@override String get searchHint => 'डेस्कटॉप पर खोज...';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$hi extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'कोई नेटवर्क इंटरफ़ेस नहीं मिला';
	@override String get authenticationFailed => 'असफलता की पुष्टि';
	@override String serverStartFailed({required Object error}) => 'रिमोट सर्वर शुरू करने में विफलता: ${error}';
	@override String commandFailed({required Object error}) => 'दूरस्थ कमांड भेजने में विफलता: ${error}';
	@override String get joinTimedOut => 'सत्र में शामिल होने के लिए समय';
	@override String get failedToConnectAnyAddress => 'किसी भी पते से कनेक्ट करने में असमर्थ';
	@override String connectionLostAfterAttempts({required Object attempts}) => '${attempts} प्रयासों के बाद कनेक्शन खो गया';
	@override String get connectionLost => 'कनेक्शन खो गया';
}

// Path: services.names
class _Translations$services$names$hi extends Translations$services$names$en {
	_Translations$services$names$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class _Translations$services$simklReconnect$hi extends Translations$services$simklReconnect$en {
	_Translations$services$simklReconnect$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'पुनः कनेक्ट Simkl';
	@override String get subtitle => 'Simkl इस कनेक्शन का उपयोग करने के लिए साइन इन विधि को हटा रहा है. पुन: कनेक्ट करने के लिए simkl.com को अनुमोदित करने के लिए खुलता है PlezyNG — PlezyNG कभी भी अपना पासवर्ड नहीं देखता है. आपका घड़ी इतिहास Simkl पर रहता है.';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$hi extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'PlezyNG पर ${service} को सक्रिय करें';
	@override String get instructions => 'QR कोड स्कैन करें, या नीचे दिए गए पते पर जाएं और इस कोड को दर्ज करें:';
	@override String openToActivate({required Object service}) => '${service} को सक्रिय करने के लिए खोलें';
	@override String get copyCode => 'सक्रियण कोड को कॉपी करें';
	@override String get waitingForAuthorization => 'अनुमति के लिए इंतजार...';
	@override String get codeCopied => 'कोड कॉपी करें';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$hi extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '${service} पर साइन इन करें';
	@override String get body => 'इस QR कोड को स्कैन करें या किसी भी डिवाइस पर URL खोलें।';
	@override String openToSignIn({required Object service}) => '${service} पर हस्ताक्षर करने के लिए खोलें';
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$hi extends Translations$services$pendingAuth$en {
	_Translations$services$pendingAuth$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'साइन-इन URL को कॉपी करें';
	@override String get urlCopied => 'URL को कॉपी करें';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$hi extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'पुस्तकालय फ़िल्टर';
	@override String get subtitleAllSyncing => 'सभी पुस्तकालयों को संकलित करें';
	@override String get subtitleNoneSyncing => 'कोई सिंथेटिक नहीं';
	@override String subtitleBlocked({required Object count}) => '${count} अवरुद्ध';
	@override String subtitleAllowed({required Object count}) => '${count} अनुमति';
	@override String get mode => 'फ़िल्टर मोड';
	@override String get modeBlacklist => 'काला सूची में डालना';
	@override String get modeWhitelist => 'सफेद';
	@override String get modeHintBlacklist => 'प्रत्येक पुस्तकालय को सिंक्रनाइज़ करें, नीचे देखे गए पुस्तकालयों को छोड़कर।';
	@override String get modeHintWhitelist => 'केवल नीचे की जांच की गई पुस्तकालयों को सिंक्रनाइज़ करें।';
	@override String get libraries => 'पुस्तकालय';
	@override String get noLibraries => 'कोई पुस्तकालय उपलब्ध नहीं';
}

/// The flat map containing all translations for locale <hi>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsHi {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'cast.chooseDevice' => 'किसी डिवाइस पर कास्ट करें',
			'cast.searching' => 'कस्टम उपकरणों की तलाश में ...',
			'cast.connectedTo' => ({required Object device}) => '${device} पर कनेक्ट करें',
			'cast.device' => 'कास्ट डिवाइस',
			'cast.readyToCast' => 'कास्ट करने के लिए तैयार',
			'cast.subtitle' => 'उपशीर्षक',
			'cast.serverNotAvailable' => 'मीडिया सर्वर उपलब्ध नहीं है।',
			'cast.stopCasting' => 'कास्ट करना बंद करें',
			'cast.castToDevice' => 'डिवाइस पर कास्ट करें',
			'cast.noEpisodeAvailable' => 'खेलने के लिए कोई एपिसोड उपलब्ध नहीं है।',
			'cast.startFailed' => 'सर्वर की जांच करें और फिर से कोशिश करें।',
			'automation.noActivePlayback' => 'नियंत्रित करने के लिए कोई सक्रिय वीडियो सत्र नहीं है।',
			'automation.profileNotFound' => 'यह Plezy प्रोफ़ाइल नहीं पाया जा सकता था।',
			'notifications.newEpisodeTitle' => 'नए एपिसोड',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appIcon.title' => 'एप्लिकेशन आइकन',
			'appIcon.defaultIcon' => 'मूल',
			'appIcon.current' => 'वर्तमान आइकन',
			'appIcon.locked' => 'जीवन के लिए आवश्यक पहुंच',
			'appIcon.lockedHint' => 'अपने 7 दिन के परीक्षण को शुरू करें या वैकल्पिक आइकन का उपयोग करने के लिए जीवन भर के लिए PlezyNG को अनलॉक करें।',
			'appIcon.changeFailed' => 'ऐप आइकन नहीं बदल सकता',
			'appIcon.launcherHint' => 'नया आइकन आपके होम स्क्रीन पर दिखाई देता है जब आप PlezyNG छोड़ देते हैं।',
			'appIcon.tvLauncherHint' => 'नया बैनर दिखाई देता है जब आप छोड़ दें PlezyNG. Android TV टीवी को फिर से शुरू करने तक पुराने को प्रदर्शित करना जारी रख सकता है।',
			'appIcon.names.midnight' => 'आधी रात',
			'appIcon.names.ember' => 'आदमी',
			'appIcon.names.paper' => 'कागज',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => 'लाइन',
			'appIcon.names.ocean' => 'महासागर',
			'appIcon.names.ultraviolet' => 'अल्ट्रासाउंड',
			'appIcon.names.matcha' => 'मैच',
			'appIcon.names.sunset' => 'सूरज',
			'appIcon.names.gold' => 'सोने',
			'appIcon.names.titanium' => 'टाइटेनियम',
			'appIcon.names.glass' => 'ग्लास',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => 'सिंथेटिक',
			'appIcon.names.pixel' => 'पिक्सेल',
			'appIcon.names.neon' => 'नियोन',
			'appIcon.names.sticker' => 'स्टिकर',
			'appIcon.names.ticket' => 'टिकट',
			'appIcon.names.pop' => 'पॉप',
			'appIcon.names.strata' => 'सड़क',
			'appIcon.names.facet' => 'चेहरे',
			'appIcon.names.tilde' => 'टिल्डर',
			'auth.signInWithPlex' => 'Plex के साथ साइन इन करें',
			'auth.showQRCode' => 'QR कोड दिखाएं',
			'auth.authenticate' => 'सच्चाई',
			'auth.authenticationTimeout' => 'प्रमाणीकरण समय से समाप्त हो गया है. कृपया फिर से कोशिश करें.',
			'auth.scanQRToSignIn' => 'इस QR कोड को स्कैन करने के लिए',
			'auth.waitingForAuth' => 'प्रमाणीकरण के लिए इंतजार ... अपने ब्राउज़र से साइन इन करें।',
			'auth.useBrowser' => 'ब्राउज़र का उपयोग',
			'auth.or' => 'या',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'कनेक्ट करें ${product}',
			'auth.quickConnect' => 'Quick Connect',
			'auth.useQuickConnect' => 'त्वरित कनेक्ट का उपयोग करें',
			'auth.quickConnectInstructions' => 'Jellyfin में Quick Connect खोलें और इस कोड को दर्ज करें।',
			'auth.quickConnectWaiting' => 'अनुमोदन के लिए इंतजार...',
			'auth.quickConnectCancel' => 'रद्द करना',
			'auth.quickConnectExpired' => 'त्वरित कनेक्ट की समय-सीमा समाप्त हो गई। फिर कोशिश करें।',
			'auth.localDataRecoveryRequired' => 'PlezyNG स्थानीय साइन-इन जानकारी और लंबित प्लेबैक डेटा को सुरक्षित रूप से पुनर्प्राप्त नहीं कर सका। कृपया फिर से साइन इन करें।',
			'auth.pinCheckRejected' => 'Plex PIN चेक को अस्वीकार कर दिया गया',
			'auth.connectToDirectPlex' => 'स्थानीय सर्वर से कनेक्ट करें Plex',
			'common.cancel' => 'रद्द करना',
			'common.save' => 'बचाओ',
			'common.close' => 'बंद करें',
			'common.clear' => 'स्पष्ट',
			'common.reset' => 'पुनर्स्थापित',
			'common.later' => 'बाद में',
			'common.submit' => 'प्रस्तुत करें',
			'common.confirm' => 'पुष्टि करें',
			'common.retry' => 'वापसी',
			'common.logout' => 'लॉग बाहर',
			'common.unknown' => 'अज्ञात',
			'common.refresh' => 'ताज़ा',
			'common.yes' => 'हाँ',
			'common.no' => 'नहीं',
			'common.delete' => 'डिलीट',
			'common.edit' => 'संपादित करें',
			'common.shuffle' => 'फेरबदल करें',
			'common.addTo' => 'जोड़ें...',
			'common.createNew' => 'नया बनाएं',
			'common.connect' => 'कनेक्ट करें',
			'common.disconnect' => 'डिस्कनेक्ट',
			'common.play' => 'चलाएँ',
			'common.pause' => 'रोकें',
			'common.resume' => 'फिर से चलाएँ',
			'common.error' => 'गलती',
			'common.search' => 'खोज',
			'common.home' => 'घर',
			'common.back' => 'वापस',
			'common.settings' => 'सेटिंग्स',
			'common.mute' => 'मुट्ठी',
			'common.ok' => 'ठीक',
			'common.off' => 'बंद करें',
			'common.options' => 'विकल्पों',
			'common.seasonNumber' => ({required Object number}) => 'सत्र ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'एपिसोड ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'पदों की संख्या ${number}',
			'common.reconnect' => 'फिर से जुड़ें',
			'common.viewAll' => 'सब देखो',
			'common.checkingNetwork' => 'नेटवर्क की जांच...',
			'common.loadingServers' => 'चार्जिंग सर्वर...',
			'common.connectingToServers' => 'सर्वर से कनेक्ट करने के लिए...',
			'common.startingOfflineMode' => 'ऑफ़लाइन मोड से शुरू...',
			'common.loading' => 'लोड...',
			'common.fullscreen' => 'पूर्ण स्क्रीन',
			'common.exitFullscreen' => 'पूर्ण स्क्रीन से बाहर',
			'common.pressBackAgainToExit' => 'बाहर निकलने के लिए फिर से दबाएं',
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
			'common.notAvailable' => 'ए / ए',
			'common.url' => 'URL',
			'common.letterKeys' => 'एबीसी',
			'common.mediaKind.movie' => 'फिल्में',
			'common.mediaKind.show' => 'शो',
			'common.mediaKind.season' => 'मौसम',
			'common.mediaKind.episode' => 'घटनाएँ',
			'common.mediaKind.artist' => 'कलाकार',
			'common.mediaKind.album' => 'एल्बम',
			'common.mediaKind.track' => 'ट्रैक',
			'common.mediaKind.collection' => 'संग्रह',
			'common.mediaKind.playlist' => 'प्लेलिस्ट',
			'common.mediaKind.clip' => 'क्लिप',
			'common.mediaKind.photo' => 'फोटो',
			'common.mediaKind.folder' => 'फ़ोल्डर',
			'screens.licenses' => 'अनुमतिएँ',
			'screens.switchProfile' => 'स्विच प्रोफ़ाइल',
			'screens.subtitleStyling' => 'Subtitle स्टाइलिंग',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'लॉग',
			'update.available' => 'अपडेट उपलब्ध',
			'update.versionAvailable' => ({required Object version}) => 'संस्करण ${version} उपलब्ध है',
			'update.currentVersion' => ({required Object version}) => 'वर्तमान में: ${version}',
			'update.skipVersion' => 'इस संस्करण को छोड़ दें',
			'update.viewRelease' => 'देखें रिलीज',
			'update.latestVersion' => 'आप नवीनतम संस्करण पर हैं',
			'update.checkFailed' => 'अद्यतन की जांच नहीं कर पाया',
			'appAccess.title' => '7 दिनों के लिए मुफ्त में हर फ़ंक्शन का प्रयास करें',
			'appAccess.description' => 'सभी PlezyNG सुविधाओं के लिए पूर्ण पहुंच के साथ एक सात दिवसीय परीक्षण शुरू करें. परीक्षण के दौरान कोई शुल्क नहीं है और कोई सदस्यता नहीं है. परीक्षण के बाद, आपके स्टोर की कीमत पर एक जीवन भर खरीद PlezyNG जीवन भर लॉक करता है.',
			'appAccess.trialEndedDescription' => 'अपने स्टोर की कीमत पर एक खरीद के साथ जीवन के लिए PlezyNG में प्रत्येक सुविधा को अनलॉक करें. कोई सदस्यता नहीं है.',
			'appAccess.startTrial' => 'मेरे 7 दिन मुफ्त परीक्षण शुरू करें',
			'appAccess.trialActive' => 'आपका 7 दिन का पूर्ण प्रदर्शन परीक्षण सक्रिय है।',
			'appAccess.trialEnded' => '7 दिन का मुकदमा खत्म हो गया है।',
			'appAccess.trialStartFailed' => 'मैं इस डिवाइस पर परीक्षण को बचाने में सक्षम नहीं था. कृपया फिर से कोशिश करें.',
			'appAccess.lifetimeTitle' => 'PlezyNG जीवन के लिए अनलॉक',
			'appAccess.lifetimeBody' => 'आपके पास हर PlezyNG फ़ंक्शन के लिए जीवन भर पहुंच है।',
			'appAccess.manageTitle' => 'PlezyNG जीवन भर पहुंच',
			'appAccess.manageDescription' => '7 दिनों के लिए प्रत्येक सुविधा को मुफ्त में आज़माएं, फिर अपनी दुकान की कीमत पर एक भुगतान के साथ जीवन के लिए सब कुछ लॉक करें।',
			'appAccess.buy' => ({required Object price}) => '${price} के लिए सभी सुविधाओं को अनलॉक करें',
			'appAccess.loadingPrice' => 'दुकान की कीमत...',
			'appAccess.retryPrice' => 'रिट्री की कीमत देखें',
			'appAccess.restore' => 'जीवन भर खरीदें',
			'appAccess.pending' => 'आपका खरीद भुगतान या अनुमोदन का इंतजार कर रहा है. लाइफ-टाइम एक्सेस तुरंत बंद हो जाता है जैसे ही स्टोर इसे पूरा करता है.',
			'appAccess.storeUnavailable' => 'खरीदारी उपलब्ध नहीं है. सुनिश्चित करें कि आप स्टोर में साइन अप कर रहे हैं और इस डिवाइस पर खरीदारी की अनुमति है.',
			'appAccess.productNotFound' => 'PlezyNG जीवन-जीवन अनलॉक अभी तक इस स्टोर में उपलब्ध नहीं है।',
			'appAccess.productQueryFailed' => 'दुकान की कीमत पर लोड नहीं किया जा सकता. अपने कनेक्शन की जांच करें और फिर से कोशिश करें.',
			'appAccess.purchaseFailed' => 'खरीदारी नहीं हुई. फिर से कोशिश करें.',
			'appAccess.restoreFailed' => 'आप अपनी खरीद को पुनर्स्थापित करने के लिए दुकान तक नहीं पहुंच सकते. फिर से कोशिश करें.',
			'appAccess.nothingToRestore' => 'इस स्टोर खाते के लिए PlezyNG जीवन भर खरीद पाया गया था।',
			'settings.title' => 'सेटिंग्स',
			'settings.supportDeveloper' => 'समर्थन PlezyNG',
			'settings.supportDeveloperDescription' => 'विकास का समर्थन करने के लिए दान',
			'settings.lifetimeAccess' => 'PlezyNG जीवन भर पहुंच',
			'settings.language' => 'भाषा',
			'settings.theme' => 'विषय',
			'settings.appearance' => 'दिखाई',
			'settings.detailPage' => 'विवरण पृष्ठ',
			'settings.themeSongsEnabled' => 'विषय गीतों का खेल',
			'settings.themeSongsEnabledDescription' => 'मीडिया विवरण देखने के दौरान उपलब्ध थीम गीत खेलें।',
			'settings.themeSongVolume' => 'गीत वॉल्यूम',
			'settings.videoPlayback' => 'वीडियो प्लेबैक',
			'settings.videoPlaybackDescription' => 'Playback व्यवहार सेट करें',
			'settings.advanced' => 'उन्नत',
			'settings.episodePosterMode' => 'पोस्टर स्टाइल',
			'settings.seriesPoster' => 'सीरीज पोस्टर',
			'settings.seasonPoster' => 'मौसम पोस्टर',
			'settings.episodeThumbnail' => 'ट्यूबनाइल',
			'settings.showHeroSectionDescription' => 'घर स्क्रीन पर सामग्री कैरोसेल दिखाई देता है',
			'settings.secondsLabel' => 'सेकंड',
			'settings.minutesLabel' => 'मिनट',
			'settings.secondsShort' => 'एस',
			'settings.minutesShort' => 'एम',
			'settings.durationHint' => ({required Object min, required Object max}) => 'एक मूल्य दर्ज करें (${min}-${max})',
			'settings.systemTheme' => 'प्रणाली',
			'settings.lightTheme' => 'प्रकाश',
			'settings.darkTheme' => 'अंधेरा',
			'settings.oledTheme' => 'OLED',
			'settings.emberTheme' => 'आदमी',
			'settings.glacierTheme' => 'आइसक्रीम',
			'settings.forestTheme' => 'जंगल',
			'settings.plumTheme' => 'प्लम',
			'settings.paperTheme' => 'कागज',
			'settings.libraryDensity' => 'पुस्तकालय की दबाव',
			'settings.displayScale' => 'डिस्प्ले स्केल',
			'settings.compact' => 'कॉम्पैक्ट',
			'settings.comfortable' => 'आरामदायक',
			'settings.gridSpacing' => 'ग्रिड स्पेसिंग',
			'settings.gridSpacingTight' => 'टॉयलेट',
			'settings.gridSpacingNormal' => 'सामान्य',
			'settings.gridSpacingSpacious' => 'अंतरिक्ष',
			'settings.tvCornerSpotlightBackdrop' => 'कोर स्पॉटलाइट बैकड्रॉप',
			'settings.tvCornerSpotlightBackdropDescription' => 'स्क्रीन भरने के बजाय शीर्ष दाहिने कोने में स्पॉटलाइट कलाकृति दिखाएं',
			'settings.viewMode' => 'दृश्य मोड',
			'settings.gridView' => 'ग्रिड',
			'settings.listView' => 'सूची',
			'settings.showHeroSection' => 'Hero सेक्शन दिखाएँ',
			'settings.showHomeBackdrop' => 'Home Backdrop आर्टवर्क',
			'settings.showHomeBackdropDescription' => 'दिखाए बड़े कलाकृति के पीछे दिखाए गए होम लाइनों',
			'settings.contentScreensaverEnabled' => 'सामग्री स्क्रीन सहेजें',
			'settings.contentScreensaverEnabledDescription' => 'पूर्ण स्क्रीन कलाकृति दिखाने के बाद ऐप आईडीएल हो गया है',
			'settings.contentScreensaverDelay' => 'स्क्रीन सहेजने के बाद',
			'settings.contentScreensaverLibraries' => 'Screensaver पुस्तकालय',
			'settings.contentScreensaverLibrariesDescription' => 'चुनें कि कौन सी पुस्तकालय स्क्रीन सहेजक कलाकृति प्रदान करते हैं. यदि कोई नहीं चुना जाता है, तो सभी पुस्तकालयों से कलाकृति का उपयोग किया जाता है.',
			'settings.contentScreensaverAllLibraries' => 'सभी संग्रह',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} पुस्तकालय चुने गए हैं',
			'settings.contentScreensaverNoLibraries' => 'कोई कनेक्ट मीडिया लाइब्रेरी उपलब्ध नहीं है।',
			'settings.contentScreensaverDismissHint' => 'किसी भी बटन दबाएं या हटाने के लिए टैप करें',
			'settings.newEpisodeNotifications' => 'नए एपिसोड की सूचनाएं',
			'settings.newEpisodeNotificationsDescription' => 'चेतावनी जब एक नए एपिसोड को एक शो में जोड़ा जाता है आप पकड़े गए हैं. चेक जब Plezy खुला है.',
			'settings.continueWatchingRowSize' => 'आगे देखते हैं आकार की रेंज',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => '${label} कार्ड',
			'settings.rowSizeCompact' => 'कॉम्पैक्ट',
			'settings.rowSizeStandard' => 'मानक',
			'settings.rowSizeLarge' => 'बड़ा',
			'settings.continueWatchingAction' => 'आगे देखना कार्रवाई',
			'settings.continueWatchingPlay' => 'खेलना',
			'settings.continueWatchingDetails' => 'खुले विवरण',
			'settings.episodeAction' => 'एपिसोड कार्रवाई',
			'settings.episodePlay' => 'खेलना',
			'settings.episodeDetails' => 'खुले विवरण',
			'settings.useGlobalHubs' => 'Home Layout का उपयोग करें',
			'settings.useGlobalHubsDescription' => 'एकीकृत होम हब दिखाएं. अन्यथा पुस्तकालय की सिफारिशों का उपयोग करें.',
			'settings.showServerNameOnHubs' => 'Hubs पर सर्वर नाम दिखाएं',
			'settings.showServerNameOnHubsDescription' => 'हमेशा हब शीर्षकों में सर्वर नाम दिखाएं।',
			'settings.groupLibrariesByServer' => 'सर्वर पर समूह पुस्तकालय',
			'settings.groupLibrariesByServerDescription' => 'प्रत्येक मीडिया सर्वर के नीचे समूह साइडबार लाइब्रेरी।',
			'settings.alwaysKeepSidebarOpen' => 'हमेशा साइडबार खुले रखें',
			'settings.alwaysKeepSidebarOpenDescription' => 'साइडबार विस्तारित रहता है और सामग्री क्षेत्र फिट करने के लिए समायोजित होता है',
			'settings.showUnwatchedCount' => 'अनदेखा किए गए अंक',
			'settings.showUnwatchedCountDescription' => 'प्रदर्शित अनदेखा एपिसोड शो और मौसमों पर गिनती',
			'settings.showWatchedIndicators' => 'दिखाए गए संकेतक',
			'settings.showWatchedIndicatorsDescription' => 'देखे गए फिल्मों, शो और एपिसोड पर एक चेकमार्क प्रदर्शित करें',
			'settings.showEpisodeNumberOnCards' => 'कार्ड पर एपिसोड नंबर दिखाएं',
			'settings.showEpisodeNumberOnCardsDescription' => 'एपिसोड कार्ड पर मौसम और एपिसोड नंबर दिखाएं',
			'settings.showSeasonPostersOnTabs' => 'टैब पर मौसम पोस्टर दिखाएं',
			'settings.showSeasonPostersOnTabsDescription' => 'प्रत्येक मौसम के पोस्टर को अपने टैब के ऊपर दिखाएं',
			'settings.tvFullCardLayout' => 'पूर्ण टीवी कार्ड',
			'settings.tvFullCardLayoutDescription' => 'चित्र-केवल टीवी कार्ड का उपयोग अभिनेता नामों के साथ',
			'settings.focusGlow' => 'फोकस ग्लो',
			'settings.focusGlowDescription' => 'केंद्रित कार्ड के चारों ओर एक नरम चमक डालें',
			'settings.visualEffects' => 'दृश्य प्रभाव',
			'settings.visualEffectsAuto' => 'ऑटो',
			'settings.visualEffectsAutoDescription' => 'कम शक्ति वाले उपकरणों पर स्वचालित रूप से प्रभाव को कम करें',
			'settings.visualEffectsFull' => 'पूर्ण',
			'settings.visualEffectsReduced' => 'कम करें',
			'settings.visualEffectsReducedDescription' => 'कम एनीमेशन और निचले संकल्प कलाकृति',
			'settings.hideSpoilers' => 'अनदेखा किए गए एपिसोड के लिए छिपे हुए स्पॉलर',
			'settings.hideSpoilersDescription' => 'Blur ट्यूमर और अनदेखा किए गए एपिसोड के लिए विवरण',
			'settings.playerBackend' => 'बैकएंड खिलाड़ी',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'हार्डवेयर डिकोडिंग',
			'settings.hardwareDecodingDescription' => 'जब उपलब्ध हो तो हार्डवेयर गति का उपयोग करें',
			'settings.playbackBuffer' => 'Playback बफर',
			'settings.playbackBufferAuto' => 'गाड़ी (अनुशंसित)',
			'settings.playbackBufferLarge' => 'बड़ा',
			'settings.playbackBufferExtraLarge' => 'अतिरिक्त बड़ा',
			'settings.playbackBufferDescription' => 'अस्थिर कनेक्शन के खिलाफ अधिक बफर. बफर आकार द्वारा भी सीमित.',
			'settings.streamBufferSize' => 'बफर आकार',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} एमबी',
			'settings.streamBufferSizeDescription' => 'सीधे खेलते समय कितना वीडियो आगे लोड करना है. ट्रांसकोड सर्वर के स्वयं के ट्रांसकोड बफर पर रुकता है. 0 = ऑटो',
			'settings.streamBufferSizeExoNote' => 'Playback Buffer को स्थापित करते समय प्रतिस्थापित करता है, एप्लिकेशन की स्मृति सीमा के आधे हिस्से में कवर किया जाता है',
			'settings.streamBufferMegabytes' => 'मेगाबाइट्स',
			'settings.defaultQualityTitle' => 'डिफ़ॉल्ट गुणवत्ता',
			'settings.cellularQualityTitle' => 'सेलुलर में डिफ़ॉल्ट गुणवत्ता',
			'settings.remoteQualityTitle' => 'रिमोट स्ट्रीमिंग गुणवत्ता',
			'settings.remoteQualitySameAsDefault' => 'डिफ़ॉल्ट गुणवत्ता के रूप में',
			'settings.cellularQualitySameAsDefault' => 'डिफ़ॉल्ट गुणवत्ता के रूप में',
			'settings.directPlayCoveredQuality' => 'मूल गुणवत्ता में छोटे वीडियो खेलें',
			'settings.directPlayCoveredQualityDescription' => 'सीधे वीडियो को पहले से ही गुणवत्ता सीमा के भीतर चलाने के बजाय उन्हें ट्रांसकोड करने के लिए',
			'settings.videoCodecs' => 'वीडियो कोडेक',
			'settings.videoCodecsDescription' => 'अनदेखा किए गए कोडेक को सर्वर द्वारा ट्रांसकोड किया जाता है',
			'settings.videoCodecsAlwaysAccepted' => 'हमेशा स्वीकार',
			'settings.musicQualityTitle' => 'संगीत गुणवत्ता',
			'settings.subtitleStyling' => 'Subtitle स्टाइलिंग',
			'settings.subtitleStylingDescription' => 'Subtitle उपस्थिति के लिए अनुकूलित करें',
			'settings.smallSkipDuration' => 'छोटे स्काइप लंबाई',
			'settings.largeSkipDuration' => 'लंबी लंबी लंबी लंबी',
			'settings.rewindOnResume' => 'पुनः संदर्भ में',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(seconds, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} सेकंड', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} सेकंड', ), 
			'settings.defaultSleepTimer' => 'डिफ़ॉल्ट नींद टाइमर',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(minutes, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} मिनट', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} मिनट', ), 
			'settings.rememberTrackSelections' => 'शो / फिल्म के लिए ट्रैक चयन याद रखें',
			'settings.chooseTracksBeforePlayback' => 'Playback से पहले ऑडियो और उप शीर्षक का चयन करें',
			'settings.chooseTracksBeforePlaybackDescription' => 'प्रत्येक वीडियो शुरू होने से पहले स्रोत ऑडियो और उप शीर्षक ट्रैक चुनें।',
			'settings.alwaysShowSubtitlesOnDevice' => 'हमेशा इस डिवाइस पर उपनाम दिखाएं',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => 'जब सर्वर में कोई उप-टू-टू नहीं है, तो एक ट्रैक को स्थानीय रूप से चुनें. यह कभी भी सर्वर की पसंद को नहीं बदलता है.',
			'settings.autoDownloadPreferredSubtitle' => 'फ्लेक्स पसंदीदा-भाषा उपनामों की कमी',
			'settings.autoDownloadPreferredSubtitleDescription' => 'अपने पसंदीदा भाषा में एक उपलब्ध उपशीर्षक को स्थानीय रूप से चुनें. यदि कोई मौजूद नहीं है, तो सर्वर से पूछें कि जब समर्थित होता है तो एक को पकड़ लें. चयन इस डिवाइस पर रहता है.',
			'settings.rememberTrackSelectionsDescription' => 'इस डिवाइस पर शो या फिल्म के माध्यम से ऑडियो और उपनाम विकल्प संग्रहीत करें',
			'settings.rememberTrackSelectionsBackendRule' => 'Plex, Jellyfin, और Emby; Plex और Jellyfin के साथ स्थानीय रूप से काम करते हुए, सर्वर पर चयन भी संग्रहीत कर सकते हैं',
			'settings.followServerTrackSelections' => 'सर्वर के प्रति-एपिसोड ट्रैक चयन का उपयोग करें',
			'settings.followServerTrackSelectionsDescription' => 'एपिसोड परिवर्तन पर, सर्वर पर चुने गए ऑडियो और उप शीर्षक का उपयोग करें, वर्तमान विकल्प से ऊपर ले जाने के बजाय',
			'settings.resumeMusicOnLaunch' => 'संगीत सत्र याद रखें',
			'settings.resumeMusicOnLaunchDescription' => 'अंतिम गीत को फिर से खोलें जहां यह बंद हो गया जब एप्लिकेशन शुरू होता है',
			'settings.showChapterMarkersOnTimeline' => 'खोज बार पर अध्याय चिह्नों को दिखाएं',
			'settings.showChapterMarkersOnTimelineDescription' => 'श्रेणी की सीमाओं पर श्रेणी की सीमाओं पर श्रेणी की सीमाओं पर श्रेणी की सीमाएं',
			'settings.specialsOrdering' => 'एपिसोड ऑर्डर में विशेष',
			'settings.specialsOrderingDescription' => 'जहां विशेषताओं एक शो के घड़ी के आदेश में खेलते हैं',
			'settings.specialsOrderingServer' => 'सर्वर आदेश का पालन करें',
			'settings.specialsOrderingAirDate' => 'एयर डेटा के अनुसार अंतराल',
			'settings.specialsOrderingLast' => 'नियमित मौसम के बाद',
			'settings.clickVideoTogglesPlayback' => 'वीडियो पर क्लिक करें ताकि आप खेल सकें / आराम करें',
			'settings.clickVideoTogglesPlaybackDescription' => 'वीडियो पर क्लिक करें और नियंत्रण प्रदर्शित करने के बजाय खेलने / रुकने के लिए।',
			'settings.videoPlayerControls' => 'वीडियो प्लेयर नियंत्रण',
			'settings.keyboardShortcuts' => 'कुंजीपटल Shortcuts',
			'settings.keyboardShortcutsDescription' => 'Keyboard Shortcuts के लिए कस्टम करें',
			'settings.videoPlayerNavigation' => 'वीडियो प्लेयर नेविगेशन',
			'settings.videoPlayerNavigationDescription' => 'वीडियो प्लेयर नियंत्रण का उपयोग करने के लिए चाकू कुंजी का उपयोग करें',
			'settings.watchTogetherRelay' => 'एक साथ रिलीज देखें',
			'settings.watchTogetherRelayDescription' => 'सार्वजनिक ओपन वॉच पार्टी रिलीज है, जब तक कि आप अपने स्वयं के सेट नहीं',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.watchTogetherRelayInvalid' => 'रिले का मान्य HTTP या HTTPS बेस URL दर्ज करें।',
			'settings.crashReporting' => 'दुर्घटना रिपोर्टिंग',
			'settings.crashReportingDescription' => 'एप्लिकेशन को बेहतर बनाने में मदद करने के लिए दुर्घटना रिपोर्ट भेजें',
			'settings.debugLogging' => 'डेब्यू लॉगिंग',
			'settings.debugLoggingDescription' => 'समस्या हल करने के लिए विस्तृत लॉगिंग की अनुमति दें',
			'settings.viewLogs' => 'लॉग देखें',
			'settings.viewLogsDescription' => 'आवेदन लॉग देखें',
			'settings.clearImageCache' => 'स्पष्ट छवि कैश',
			'settings.clearImageCacheDescription' => 'स्पष्ट कचरे वाले कलाकृतियों और छोटे-छोटे चित्रों को फिर से डाउनलोड होने तक धीरे-धीरे लोड किया जा सकता है।',
			'settings.clearImageCacheSuccess' => 'Image cache को सफलतापूर्वक हटा दिया गया',
			'settings.resetSettings' => 'सेटिंग्स पुन:',
			'settings.resetSettingsDescription' => 'डिफ़ॉल्ट सेटिंग्स को पुनर्स्थापित करें. यह अनदेखा नहीं किया जा सकता है.',
			'settings.resetSettingsSuccess' => 'सेटिंग्स सफलतापूर्वक पुनर्स्थापित करें',
			'settings.backup' => 'बैकअप',
			'settings.exportSettings' => 'निर्यात सेटिंग्स',
			'settings.exportSettingsDescription' => 'फ़ाइल के लिए अपनी प्राथमिकताओं को सहेजें',
			'settings.exportSettingsSuccess' => 'सेटअप निर्यात',
			'settings.importSettings' => 'आयात सेटिंग्स',
			'settings.importSettingsDescription' => 'फ़ाइल से प्राथमिकताओं को पुनर्स्थापित करें',
			'settings.importSettingsConfirm' => 'यह आपके वर्तमान सेटिंग्स को प्रतिस्थापित करेगा. आगे?',
			'settings.importSettingsSuccess' => 'आयातित सेटिंग्स',
			'settings.importSettingsInvalidFile' => 'यह फ़ाइल एक वैध PlezyNG सेटिंग्स निर्यात नहीं है',
			'settings.importSettingsNoUser' => 'आयात से पहले इनपुट करें',
			'settings.cloudBackup' => 'क्लाउड बैकअप',
			'settings.cloudBackupDescription' => 'स्थानांतरित की जा सकने वाली सेटिंग्स का HTTPS के ज़रिए WebDAV पते पर बैकअप लें। सर्वर कनेक्शन और साइन-इन जानकारी इसी डिवाइस पर रहती है।',
			'settings.cloudBackupUrl' => 'WebDAV JSON फ़ाइल URL',
			'settings.cloudBackupUsername' => 'उपयोगकर्ता नाम',
			'settings.cloudBackupPassword' => 'पासवर्ड',
			'settings.cloudBackupSaved' => 'क्लाउड बैकअप डिज़ाइन बचाया',
			'settings.cloudBackupNow' => 'अब वापस',
			'settings.cloudBackupComplete' => 'Settings Backup अपलोड करें',
			'settings.cloudBackupRestore' => 'बैकअप पुनर्स्थापित करें',
			'settings.cloudBackupRestoreConfirm' => 'यह इस डिवाइस पर फिट पोर्टेबल सेटिंग्स को प्रतिस्थापित करेगा. आगे?',
			'settings.cloudBackupRestored' => 'Cloud Backup से पुनर्स्थापित सेटिंग्स',
			'settings.shortcutsReset' => 'डिफ़ॉल्ट में पुनर्स्थापित करें',
			'settings.resetShortcutsConfirm' => 'यह आपके कस्टम छूट को डिफ़ॉल्ट के साथ प्रतिस्थापित करेगा. आगे?',
			'settings.about' => 'के बारे',
			'settings.aboutDescription' => 'एप्लिकेशन और लाइसेंस',
			'settings.updates' => 'अद्यतन',
			'settings.updateAvailable' => 'अपडेट उपलब्ध',
			'settings.checkForUpdates' => 'Updates के लिए जांच करें',
			'settings.autoCheckUpdatesOnStartup' => 'स्टार्टअप पर अपडेट के लिए स्वचालित रूप से जांच करें',
			'settings.autoCheckUpdatesOnStartupDescription' => 'जब एक अद्यतन लॉन्च के लिए उपलब्ध है सूचना',
			'settings.validationErrorEnterNumber' => 'कृपया एक वैध संख्या दर्ज करें',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => '${min} और ${max} ${unit} के बीच होना चाहिए',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'कटौती पहले से ही ${action} को सौंपा गया है',
			'settings.shortcutUpdated' => ({required Object action}) => 'संक्षिप्त अद्यतन के लिए ${action}',
			'settings.saveFailed' => 'कोई बदलाव नहीं किया जा सकता. फिर से कोशिश करें.',
			'settings.autoPlayAndSkip' => 'ऑटो-प्ले और स्काइप',
			'settings.autoPlayNextEpisode' => 'अगला लेखअगला खेल',
			'settings.autoPlayNextEpisodeDescription' => 'अगले एपिसोड को स्वचालित रूप से शुरू करें जब एक समाप्त हो जाता है',
			'settings.shuffleStartsFromBeginning' => 'शुरुआत में शूफल शुरू होता है',
			'settings.shuffleStartsFromBeginningDescription' => 'प्रत्येक एपिसोड को शुरू करने के बजाय शुरुआत में जब शॉफिंग',
			'settings.plexCinemaPreRoll' => 'सर्वर फिल्म इंटीरियर का उपयोग करें',
			'settings.plexCinemaPreRollDescription' => 'एक फिल्म शुरू होने से पहले Plex प्री-रॉल्स या Jellyfin और Emby इनपुट को कॉन्फ़िगर करें।',
			'settings.playNextCountdown' => 'अगला लेखअगला गिनती',
			'settings.playNextCountdownImmediate' => 'तुरंत खेलें',
			'settings.skipIntroMode' => 'स्काइप इनट्रू',
			'settings.skipIntroModeOffDescription' => 'एक स्काइप बटन के बिना सामान्य रूप से इन्रो खेलते हैं',
			'settings.skipIntroModeButtonDescription' => 'एक स्काइप बटन दिखाएं जब एक इनपुट शुरू होता है',
			'settings.skipIntroModeAutoDescription' => 'नीचे दिए गए देरी के बाद स्वचालित रूप से इनपुट स्काइप करें',
			'settings.skipCreditsMode' => 'क्रेडिट स्केप',
			'settings.skipCreditsModeOffDescription' => 'स्काइप बटन के बिना सामान्य रूप से क्रेडिट खेलते हैं',
			'settings.skipCreditsModeButtonDescription' => 'क्रेडिट शुरू होने पर स्काइप बटन दिखाएं',
			'settings.skipCreditsModeAutoDescription' => 'स्वचालित रूप से क्रेडिट स्काइप करें और अगले एपिसोड को खेलें',
			'settings.skipAdsMode' => 'स्काइप विज्ञापन',
			'settings.skipAdsModeOffDescription' => 'स्काइप बटन के बिना सामान्य रूप से पता लगाए गए विज्ञापन खेलें',
			'settings.skipAdsModeButtonDescription' => 'एक स्काइप बटन दिखाएं जब Plex एक विज्ञापन का पता लगाता है',
			'settings.skipAdsModeAutoDescription' => 'नीचे दिए गए देरी के बाद स्वचालित रूप से पता लगाए गए विज्ञापनों को हटा दें',
			'settings.musicPlayback' => 'संगीत Playback',
			'settings.musicSweetFades' => 'मिठाई फूड',
			'settings.musicSweetFadesDescription' => 'ट्रैक किनारों पर फ़ैड संगीत जब Plex में शोर डेटा है. एल्बम प्लेबैक अपरिवर्तित रहता है.',
			'settings.skipMarkerModeOff' => 'बंद करें',
			'settings.skipMarkerModeButton' => 'बटन दिखाएं',
			'settings.skipMarkerModeAuto' => 'स्वचालित',
			'settings.forceSkipMarkerFallback' => 'फोर्स फेलबैक मार्कर',
			'settings.forceSkipMarkerFallbackDescription' => 'अध्याय शीर्षक पैटर्न का उपयोग करें, भले ही Plex में मार्कर हों',
			'settings.theIntroDbFallback' => 'एक intro fallback के रूप में TheIntroDB का उपयोग करें',
			'settings.theIntroDbFallbackDescription' => 'सामुदायिक समय का उपयोग केवल तब करें जब सर्वर में कोई इनपुट मार्कर नहीं है. मैच रिलीज के आधार पर भिन्न हो सकते हैं.',
			'settings.autoSkipDelay' => 'स्काइप देरी',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => '${seconds} सेकंड से पहले इंतजार करें',
			'settings.introPattern' => 'मार्कर पैटर्न',
			'settings.introPatternDescription' => 'Regex पैटर्न अध्याय शीर्षकों में intro markers के अनुरूप करने के लिए',
			'settings.creditsPattern' => 'क्रेडिट मार्कर पैटर्न',
			'settings.creditsPatternDescription' => 'Regex पैटर्न अध्याय शीर्षकों में क्रेडिट मार्करों को मिलाने के लिए',
			'settings.prerolls' => 'प्रेरॉल्स',
			'settings.playPrerollsBeforeMovies' => 'फिल्मों से पहले प्रेरॉल्स खेलना',
			'settings.playPrerollsBeforeMoviesDescription' => 'प्रत्येक फिल्म से पहले नीचे दिए गए चयन से एक यादृच्छिक क्लिप खेलें. स्काइप करने के लिए वापस दबाएं.',
			'settings.prerollLibrary' => 'प्रेरोल लाइब्रेरी',
			'settings.prerollLibraryNotSet' => 'सेट नहीं',
			'settings.prerollLibraryNoneFound' => 'आपके सर्वर पर कोई पुस्तकालय नहीं पाया गया है।',
			'settings.prerollSelection' => 'चुने हुए प्रीमियम',
			'settings.prerollSelectionPickLibraryFirst' => 'पहले एक पुस्तकालय चुनें',
			'settings.prerollSelectionNoneSelected' => 'नहीं चुने गए प्रीमियम',
			'settings.prerollSelectionCount' => ({required Object count}) => '${count} चुने गए',
			'settings.prerollItemPicker' => 'चुनें प्रीमियम',
			'settings.prerollItemPickerLoadFailed' => 'मैं इस पुस्तकालय से वस्तुओं को लोड नहीं कर सकता था।',
			'settings.invalidRegex' => 'नियमित अभिव्यक्ति की कमी',
			'settings.regex' => 'नियमित अभिव्यक्ति',
			'settings.downloads' => 'डाउनलोड',
			'settings.downloadLocationDescription' => 'जहां डाउनलोड किए गए सामग्री को संग्रहीत करने के लिए चुनें',
			'settings.downloadLocationDefault' => 'डिफ़ॉल्ट (App Storage)',
			'settings.downloadLocationCustom' => 'कस्टम स्थान',
			'settings.selectFolder' => 'फ़ोल्डर चुनें',
			'settings.resetToDefault' => 'डिफ़ॉल्ट में पुनरारंभ',
			'settings.currentPath' => ({required Object path}) => 'वर्तमान में: ${path}',
			'settings.downloadLocationChanged' => 'डाउनलोड स्थान बदल गया',
			'settings.downloadLocationReset' => 'डाउनलोड करें स्थान reset to default',
			'settings.downloadLocationInvalid' => 'चयनित फ़ोल्डर लिखने योग्य नहीं है',
			'settings.downloadLocationPickerUnavailable' => 'फ़ोल्डर चयन इस डिवाइस पर उपलब्ध नहीं है',
			'settings.downloadOnWifiOnly' => 'केवल Wi-Fi पर डाउनलोड करें',
			'settings.downloadOnWifiOnlyDescription' => 'मोबाइल डेटा पर डाउनलोड करने से रोकें',
			'settings.autoRemoveWatchedDownloads' => 'Auto-Remove देखने वाले डाउनलोड',
			'settings.autoRemoveWatchedDownloadsDescription' => 'स्वचालित रूप से देखे गए डाउनलोड को हटा दें',
			'settings.autoDownloadContinueWatching' => 'Auto-Download जारी रखें',
			'settings.autoDownloadContinueWatchingDescription' => 'अपने निरंतर देखे जाने वाले ढाल पर आइटम डाउनलोड करें, और उन्हें हटा दें जब वे ढाल छोड़ देते हैं',
			'settings.downloadQuality' => 'डाउनलोड गुणवत्ता',
			'settings.downloadQualityDescription' => 'Plex अपने डाउनलोड क्वाउड में एक परिवर्तित प्रति तैयार करता है. Jellyfin और Emby ट्रांसकोड जब फ़ाइल डाउनलोड करता है; टूटे हुए ट्रांसफर को पुनरारंभ करने की आवश्यकता हो सकती है.',
			'settings.askDownloadQualityEachTime' => 'प्रत्येक डाउनलोड के लिए गुणवत्ता का चयन करें',
			'settings.askDownloadQualityEachTimeDescription' => 'प्रत्येक वीडियो डाउनलोड करने से पहले गुणवत्ता पिकर दिखाएं',
			'settings.cellularDownloadBlocked' => 'डाउनलोड सेल पर ब्लॉक किए जाते हैं. Wi-Fi का उपयोग करें या सेटिंग्स को बदल दें.',
			'settings.maxVolume' => 'अधिकतम वॉल्यूम',
			'settings.maxVolumeDescription' => 'कम आवाज़ वाले मीडिया के लिए वॉल्यूम 100% से अधिक बढ़ाने दें',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'अमीर उपस्थिति',
			'settings.discordRichPresenceDescription' => 'दिखाएं कि आप Discord पर क्या देख रहे हैं',
			'settings.services' => 'सेवाएं',
			'settings.servicesDescription' => 'कनेक्ट करें Trakt, MyAnimeList, Seerr, और अधिक',
			'settings.manageLibrariesDescription' => 'पुस्तकालयों को रिकॉर्ड और छिपाना',
			'settings.companionRemoteServer' => 'रिमोट सर्वर',
			'settings.companionRemoteServerDescription' => 'अपने नेटवर्क पर मोबाइल उपकरणों को इस ऐप को नियंत्रित करने की अनुमति दें',
			'settings.companionRemoteServerStartFailed' => 'साथी सर्वर शुरू नहीं किया जा सकता',
			'settings.companionRemoteServerStopFailed' => 'साथी सर्वर को रोक नहीं पाया',
			'settings.autoPip' => 'Auto Picture-in-Picture के बारे में टिप्पणियाँ',
			'settings.autoPipDescription' => 'स्वचालित रूप से छवि-इन-चित्र दर्ज करें जब आप प्लेबैक के दौरान ऐप छोड़ देते हैं',
			'settings.matchContentFrameRate' => 'मैच सामग्री फ्रेम दर',
			'settings.matchContentFrameRateDescription' => 'मैच डिस्प्ले वीडियो सामग्री के लिए ताज़ा दर',
			'settings.matchContentResolution' => 'मैच सामग्री संकल्प',
			'settings.matchContentResolutionDescription' => 'डिस्प्ले को वीडियो के मूल रिज़ॉल्यूशन में स्विच करें ताकि आपका टीवी उस्स्केल हो. मेनू और उपनाम भी प्लेबैक के दौरान उस्केल हो जाते हैं',
			'settings.matchRefreshRate' => 'मैच रिफ्रेश दर',
			'settings.matchRefreshRateDescription' => 'मैच डिस्प्ले पूर्ण स्क्रीन में ताज़ा दर',
			'settings.matchDynamicRange' => 'खेल गतिशील सीमा',
			'settings.matchDynamicRangeDescription' => 'HDR को HDR सामग्री के लिए स्विच करें, फिर SDR पर वापस जाएं',
			'settings.displaySwitchDelay' => 'स्विच देरी',
			'settings.tunneledPlayback' => 'टनल प्लेबैक',
			'settings.tunneledPlaybackDescription' => 'वीडियो टनलिंग का उपयोग करें. यदि HDR प्लेबैक काले वीडियो या मोशन स्टूटर प्रदर्शित करता है तो इसे अक्षम करें.',
			'settings.audioPassthrough' => 'ध्वनि के साथ',
			'settings.audioPassthroughDescription' => 'अपने रिसेप्टर या टीवी को फिर से एन्कोडिंग के बिना Dolby/DTS ऑडियो भेजें, आसपास के ध्वनि को बनाए रखें. यदि आपके पास कोई ध्वनि नहीं है तो बंद करें.',
			'settings.audioPassthroughDescriptionApple' => 'Dolby Digital Plus के लिए मूल Dolby decoder Apple का उपयोग करें, जिसमें Atmos भी शामिल है. DTS और TrueHD अभी भी मल्टीचैनल पीसीएम के रूप में खेलते हैं. यदि आपके पास कोई ध्वनि नहीं है तो बंद करें.',
			'settings.audioPassthroughDescriptionAppleSpatial' => 'डोलबी डिजिटल प्लस के लिए Apple के मूल डोलबी डिकोडर का उपयोग करें, जिसमें Atmos शामिल है. iOS, iPadOS और tvOS 26 या बाद में, TrueHD Atmos और DTS:X को अंतरिक्ष ऑडियो के रूप में खेला जाता है. अन्य DTS और TrueHD ट्रैक को मल्टीचैनल पीसीएम के रूप में खेला जाता है. बंद करें यदि आपके पास कोई ध्वनि नहीं है.',
			'settings.audioPassthroughOverriddenByNormalization' => 'जबकि ध्वनि सामान्यीकरण के लिए बंद हो जाता है',
			'settings.audioChannelLimit' => 'ऑडियो चैनल',
			'settings.audioChannelLimitDescription' => 'स्पीकर, हेडफोन, या HDMI सेटिंग्स के लिए डिकोड ऑडियो डाउनलोड करें जो किसी भी चैनल को नहीं खेल सकते हैं',
			'settings.audioChannelLimitOriginal' => 'मूल',
			'settings.audioChannelLimitOriginalDescription' => 'ट्रैक में हर चैनल खेलें',
			'settings.audioChannelLimitSurround51' => '5.1 तक',
			'settings.audioChannelLimitSurround51Description' => 'टीवी और रिसीवरों के लिए 7.1 से 5.1 तक मिश्रण करें जो केवल 5.1 पीसीएम लेते हैं।',
			'settings.audioChannelLimitStereo' => 'स्टेनलेस',
			'settings.audioChannelLimitStereoDescription' => 'स्टेरेओ स्पीकर या हेडफोन के लिए दो चैनलों में मिश्रण करें।',
			'settings.downmixCenterBoost' => 'चैनल बूस्ट',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} डीबी',
			'settings.downmixCenterBoostLabel' => 'बूस्ट ( डीबी)',
			'settings.downmixCenterBoostShort' => 'डीबी',
			'settings.audioDownmixNormalize' => 'Downmix पर वॉल्यूम को सामान्य करें',
			'settings.audioDownmixNormalizeDescription' => 'मिश्रण को नीचे रखें ताकि क्लिपिंग को रोक दिया जा सके. मूल वॉल्यूम को बनाए रखने के लिए बंद करें (मैं जोर से दृश्यों को खराब कर सकता हूं)।',
			'settings.dvConversionMode' => 'Dolby Vision परिवर्तित',
			'settings.dvConversionModeDescription' => 'कैसे Dolby Vision प्रोफ़ाइल 7 फ़ाइलों को संभालने के लिए चुनें।',
			'settings.dvConversionAuto' => 'ऑटो',
			'settings.dvConversionNative' => 'Home / विकलांग',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'उपकरण क्षमता का पता लगाने और सामान्य Fallback व्यवहार का उपयोग करें',
			'settings.dvConversionNativeDescription' => 'शक्ति मूल DV7 और डीवी रूपांतरण रिट्री को दबाने',
			'settings.dvConversionDv81Description' => 'ताकत इनलाइन आरपीयू रूपांतरण Dolby Vision प्रोफ़ाइल 8.1',
			'settings.dvConversionHevcStripDescription' => 'स्ट्रिप Dolby Vision आरपीयू / ईएल परतों और वर्तमान प्लेन HEVC',
			'settings.disableDolbyVision' => 'अक्षम Dolby Vision',
			_ => null,
		} ?? switch (path) {
			'settings.disableDolbyVisionDescription' => 'फ़ाइल के HDR10 या HLG परत को Dolby Vision के बजाय खेलें, जब इसमें एक',
			'settings.hdrSdrConversion' => 'HDR से SDR के लिए रूपांतरण',
			'settings.hdrSdrConversionDescription' => 'चुनें कि HDR वीडियो को क्या रूपांतरित करता है जब डिस्प्ले HDR नहीं दिखा सकता है।',
			'settings.hdrSdrConversionAuto' => 'ऑटो',
			'settings.hdrSdrConversionAutoDescription' => 'डिवाइस पर Android 9 और बाद में, पुराने संस्करणों पर प्लेयर',
			'settings.hdrSdrConversionDevice' => 'डिवाइस',
			'settings.hdrSdrConversionDeviceDescription' => 'आपके डिवाइस का वीडियो हार्डवेयर इसे परिवर्तित करता है सबसे तेज़, लेकिन रंग डिवाइस पर निर्भर करता है',
			'settings.hdrSdrConversionPlayer' => 'प्लेयर',
			'settings.hdrSdrConversionPlayerDescription' => 'खिलाड़ी इसे परिवर्तित करता है. स्थिर रंग, लेकिन 4K कम अंत टीवी बॉक्स पर टूट सकता है',
			'settings.deinterlace' => 'इंटरलेशन',
			'settings.deinterlaceDescription' => 'इंटरलाइड वीडियो से कम्बिंग आइटम हटाएं (mpv खिलाड़ी केवल)',
			'settings.deinterlaceOff' => 'बंद करें',
			'settings.deinterlaceOffDescription' => 'इंटरलाइड वीडियो दिखाएं क्योंकि यह डिकोडिंग किया गया है',
			'settings.deinterlaceVideo' => 'वीडियो',
			'settings.deinterlaceVideoDescription' => 'टीवी के लिए वीडियो शॉट के लिए, जैसे खेल, समाचार, और संगीत समारोह',
			'settings.deinterlaceFilm' => 'फिल्में',
			'settings.deinterlaceFilmDescription' => 'फ़िल्म और एनीमेशन के मूल फ्रेम को पुनर्स्थापित करें, जो 29.97 एफपीएस तक टेलीसेन किया गया है, जो एनटीएससी डीवीडी पर आम है. टीवी स्टूटर के लिए वीडियो शॉट. लाइव टीवी का उपयोग वीडियो',
			'settings.requireProfileSelectionOnOpen' => 'ऐप ओपन पर प्रोफ़ाइल पूछें',
			'settings.requireProfileSelectionOnOpenDescription' => 'प्रोफ़ाइल चयन हर बार प्रदर्शित करें जब ऐप खुलता है',
			'settings.forceTvMode' => 'टीवी मोड',
			'settings.forceTvModeDescription' => 'मजबूत टीवी लेआउट. उपकरणों के लिए जो स्वचालित रूप से नहीं पता चलता. पुनरारंभ की आवश्यकता होती है.',
			'settings.startInFullscreen' => 'पूर्ण स्क्रीन से शुरू करें',
			'settings.startInFullscreenDescription' => 'लॉन्च पर पूर्ण स्क्रीन मोड में ओपन PlezyNG',
			'settings.exitFullscreenOnPlayerClose' => 'बाहर निकलने के लिए पूर्ण स्क्रीन पर खिलाड़ी बंद',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'वीडियो प्लेयर को बंद करते समय स्वचालित रूप से पूर्ण स्क्रीन से बाहर निकलता है',
			'settings.autoHidePerformanceOverlay' => 'ऑटो-हाइड प्रदर्शन ओवरले',
			'settings.autoHidePerformanceOverlayDescription' => 'Playback नियंत्रण के साथ प्रदर्शन को कम करें',
			'settings.showNavBarLabels' => 'दिखाएँ Navigation Bar Labels',
			'settings.showNavBarLabelsDescription' => 'Navigation Bar Icon के तहत पाठ लेबल प्रदर्शित करें',
			'settings.startupSection' => 'स्टार्टअप सेक्शन',
			'settings.preferredServer' => 'पसंद सर्वर',
			'settings.preferredServerDescription' => 'इस सर्वर के परिणामों को प्राथमिकता दें, जबकि प्रत्येक कनेक्ट सर्वर उपलब्ध रखें।',
			'settings.preferredServerAutomatic' => 'स्वचालित',
			'settings.showExploreTab' => 'टैब का पता लगाएं',
			'settings.showExploreTabDescription' => 'Plex खोज और जुड़े ट्रैकर से सामग्री के साथ खोज टैब दिखाएं',
			'settings.hideEmptyLibraries' => 'खाली पुस्तकालयों को छिपाना',
			'settings.hideEmptyLibrariesDescription' => 'सर्वर द्वारा रिपोर्ट किए गए आइटम की संख्या के साथ पुस्तकालयों को नवाचार से शून्य से हटा दें।',
			'settings.liveTvDefaultFavorites' => 'पसंदीदा चैनलों के लिए डिफ़ॉल्ट',
			'settings.liveTvDefaultFavoritesDescription' => 'लाइव टीवी खोलने पर केवल पसंदीदा चैनलों को प्रदर्शित करें',
			'settings.general' => 'सामान्य',
			'settings.generalDescription' => 'भाषा, स्टार्टअप, और खिड़की व्यवहार',
			'settings.languageAndRegion' => 'भाषा और क्षेत्र',
			'settings.startup' => 'स्टार्टअप',
			'settings.display' => 'प्रदर्शन',
			'settings.libraryAndCards' => 'पुस्तकालय और कार्ड',
			'settings.homeScreen' => 'Home स्क्रीन',
			'settings.navigation' => 'नाविगेशन',
			'settings.window' => 'खिड़की',
			'settings.liveTv' => 'लाइव टीवी',
			'settings.player' => 'प्लेयर',
			'settings.videoAndDisplay' => 'वीडियो और डिस्प्ले',
			'settings.audio' => 'ऑडियो',
			'settings.quality' => 'गुणवत्ता',
			'settings.subtitles' => 'उपशीर्षक',
			'settings.seekAndTiming' => 'खोज और समय',
			'settings.behavior' => 'व्यवहार',
			'settings.gestures' => 'गेंदबाजी',
			'settings.gestureBrightnessSwipe' => 'चमक स्विप',
			'settings.gestureBrightnessSwipeDescription' => 'चमक को समायोजित करने के लिए बाएं किनारे पर ऊपर या नीचे स्विच करें',
			'settings.gestureVolumeSwipe' => 'वॉल्यूम स्विप',
			'settings.gestureVolumeSwipeDescription' => 'वॉल्यूम को समायोजित करने के लिए दाईं ओर ऊपर या नीचे स्विच करें',
			'settings.gesturePinchToZoom' => 'ज़ूम के लिए पिंच',
			'settings.gesturePinchToZoomDescription' => 'वीडियो में ज़ूम करने के लिए स्क्रॉल करें और ज़ूम करें',
			'settings.gestureSeekSwipe' => 'स्विप खोजें',
			'settings.gestureSeekSwipeDescription' => 'वीडियो में कहीं भी खोजने के लिए बाईं ओर या दाईं ओर स्विच करें; कूदने के लिए रिलीज करें',
			'settings.rememberBrightnessLevel' => 'चमक के स्तर को याद रखें',
			'settings.rememberBrightnessLevelDescription' => 'अंतिम स्विप द्वारा निर्धारित चमक पर प्लेबैक शुरू करें',
			'settings.controls' => 'नियंत्रण',
			'settings.rememberPlayerChanges' => 'खिलाड़ियों में बदलाव याद रखें',
			'settings.rememberPlayerChangesDescription' => 'जहां प्लेबैक के दौरान किए गए परिवर्तन को बचाया जाता है और फिर से लागू किया जाता है',
			'settings.scopePlaybackSpeed' => 'Playback गति',
			'settings.scopeShaderPreset' => 'शेर प्रीसेट',
			'settings.scopeAspectRatio' => 'आस्पेक्ट अनुपात',
			'settings.scopeSyncOffsets' => 'Audio & Subtitle सिंक्रनाइज़ेशन',
			'settings.playerScopeOff' => 'बचाओ नहीं',
			'settings.playerScopeGlobal' => 'हर जगह',
			'settings.playerScopeLibrary' => 'पुस्तकालय के लिए',
			'settings.playerScopeTitle' => 'शो या फिल्म के लिए',
			'settings.exportDialogTitle' => 'निर्यात PlezyNG सेटिंग्स',
			'settings.followSystem' => 'सिस्टम की भाषा अपनाएँ',
			'settings.followAppLanguage' => 'इंटरफ़ेस की भाषा अपनाएँ',
			'settings.regionFormat' => 'क्षेत्रीय प्रारूप',
			'settings.regionFormatDescription' => 'तारीखें, संख्याएँ और माप दिखाने का तरीका चुनें।',
			'settings.metadataLanguage' => 'मीडिया विवरण की भाषा',
			'settings.metadataLanguageDescription' => 'सर्वर के समर्थन के अनुसार शीर्षकों और विवरणों की पसंदीदा भाषा। ऑडियो और उपशीर्षक की प्राथमिकताएँ अलग रहती हैं।',
			'themeEditor.builtIn' => 'इमारत में',
			'themeEditor.presets' => 'उपन्यास',
			'themeEditor.custom' => 'कस्टम',
			'themeEditor.customEmpty' => 'अभी तक नहीं बनाया',
			'themeEditor.editCustom' => 'संपादित करें Custom theme',
			'themeEditor.editCustomDescription' => 'हर रंग को स्वयं चुनें',
			'themeEditor.locked' => 'जीवन के लिए आवश्यक पहुंच',
			'themeEditor.savedLocked' => 'बचाया - जीवन भर के लिए उपलब्ध है',
			'themeEditor.title' => 'कस्टम विषय',
			'themeEditor.startFrom' => 'से शुरू करें',
			'themeEditor.startFromDescription' => 'किसी अन्य विषय से सभी रंगों को कॉपी करें',
			'themeEditor.colors' => 'रंगों',
			'themeEditor.preview' => 'पूर्वावलोकन',
			'themeEditor.slots.bg' => 'पृष्ठभूमि',
			'themeEditor.slots.surface' => 'सतह',
			'themeEditor.slots.outline' => 'आउटलाइन',
			'themeEditor.slots.text' => 'पाठ',
			'themeEditor.slots.textMuted' => 'माध्यमिक पाठ',
			'themeEditor.slots.accent' => 'ध्यान',
			'themeEditor.opacity' => 'अस्थिरता',
			'themeEditor.hexHint' => '#RRGGBB या #AARRGGBB',
			'themeEditor.fromOtherThemes' => 'अन्य विषयों से',
			'themeEditor.swatchLabel' => ({required Object theme, required Object color}) => '${theme} ${color}',
			'themeEditor.contrast.textOnBg' => 'पृष्ठभूमि पर पाठ',
			'themeEditor.contrast.textOnSurface' => 'सतह पर पाठ',
			'themeEditor.contrast.textMutedOnBg' => 'पृष्ठभूमि पर माध्यमिक पाठ',
			'themeEditor.contrast.textMutedOnSurface' => 'सतह पर माध्यमिक पाठ',
			'themeEditor.contrast.accentOnBg' => 'पृष्ठभूमि पर ध्यान दें',
			'themeEditor.contrast.accentOnSurface' => 'सतह पर ध्यान दें',
			'themeEditor.contrast.labelOnAccent' => 'बटन लेबल पर ध्यान केंद्रित करें',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, अनुशंसित ${minimum}:1 के नीचे',
			'themeEditor.discardTitle' => 'बदलावों को नजरअंदाज?',
			'themeEditor.discardMessage' => 'रंगों में किए गए ऐसे बदलाव खो जाएँगे जिन्हें आपने सहेजा नहीं है।',
			'themeEditor.discard' => 'डिस्काउंट',
			'themeEditor.previewCardTitle' => ({required Object number}) => 'पदों की संख्या ${number}',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => '${minutes} मिनट छोड़ दिया',
			'themeEditor.previewSwitch' => 'Autoplay के लिए',
			'themeEditor.previewMutedText' => 'दूसरा पाठ इस तरह पढ़ता है',
			'search.hint' => 'फिल्मों, शो, संगीत की खोज',
			'search.tryDifferentTerm' => 'एक अलग खोज अवधि की कोशिश करें',
			'search.searchYourMedia' => 'अपने मीडिया की तलाश',
			'search.enterTitleActorOrKeyword' => 'एक शीर्षक, अभिनेता, या कुंजी शब्द दर्ज करें',
			'search.people' => 'लोग',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'सेट Shortcut के लिए ${actionName}',
			'hotkeys.clearShortcut' => 'स्पष्ट कटौती',
			'hotkeys.noShortcutSet' => 'कोई छोटी सी सीट नहीं',
			'hotkeys.currentShortcut' => 'वर्तमान संक्षिप्त:',
			'hotkeys.pressToRecord' => 'एक संक्षिप्त रिकॉर्ड करने के लिए चुनें',
			'hotkeys.recordingShortcut' => 'अब कटौती दबाएं',
			'hotkeys.actions.playPause' => 'खेल / आराम',
			'hotkeys.actions.volumeUp' => 'वॉल्यूम ऊपर',
			'hotkeys.actions.volumeDown' => 'वॉल्यूम नीचे',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'आगे की तलाश करें (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'पीछे की ओर खोजें (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'पूर्ण स्क्रीन',
			'hotkeys.actions.muteToggle' => 'मिट्टी के साथ',
			'hotkeys.actions.subtitleToggle' => 'Subtitles के बारे में',
			'hotkeys.actions.audioTrackNext' => 'अगला Audio Track',
			'hotkeys.actions.subtitleTrackNext' => 'अगला Subtitle ट्रैक',
			'hotkeys.actions.chapterNext' => 'अगला अध्याय',
			'hotkeys.actions.chapterPrevious' => 'पिछला अध्याय',
			'hotkeys.actions.episodeNext' => 'अगला एपिसोड',
			'hotkeys.actions.episodePrevious' => 'पिछला एपिसोड',
			'hotkeys.actions.speedIncrease' => 'गति बढ़ाना',
			'hotkeys.actions.speedDecrease' => 'गति कम',
			'hotkeys.actions.speedReset' => 'पुन: गति',
			'hotkeys.actions.zoomIn' => 'ज़ूम में',
			'hotkeys.actions.zoomOut' => 'ज़ूम बाहर',
			'hotkeys.actions.zoomReset' => 'ज़ूम पुन:',
			'hotkeys.actions.subSeekNext' => 'Next Subtitle के लिए खोजें',
			'hotkeys.actions.subSeekPrev' => 'Previous Subtitle के बारे में जानें',
			'hotkeys.actions.subtitleDelayIncrease' => 'Subtitles देरी',
			'hotkeys.actions.subtitleDelayDecrease' => 'आगे के विषय',
			'hotkeys.actions.shaderToggle' => 'छाया के साथ',
			'hotkeys.actions.skipMarker' => 'क्रेडिट / क्रेडिट',
			'hotkeys.actions.screenshot' => 'स्क्रीनशॉट लेना',
			'hotkeys.actions.framePrevious' => 'पिछला फ्रेम',
			'hotkeys.actions.frameNext' => 'अगला फ्रेम',
			'fileInfo.title' => 'फ़ाइल जानकारी',
			'fileInfo.overview' => 'समीक्षा',
			'fileInfo.video' => 'वीडियो',
			'fileInfo.audio' => 'ऑडियो',
			'fileInfo.subtitles' => 'उपशीर्षक',
			'fileInfo.images' => 'अंतर्निहित तस्वीरें',
			'fileInfo.dataStreams' => 'डेटा स्ट्रीम',
			'fileInfo.lyrics' => 'लिंग',
			'fileInfo.file' => 'फ़ाइल',
			'fileInfo.attachments' => 'अनुलग्नक',
			'fileInfo.delivery' => 'वितरण',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => 'संस्करण ${index} से ${count}',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => 'फ़ाइल ${index} से ${count}',
			'fileInfo.noStreams' => 'सर्वर ने इस फ़ाइल के लिए कोई स्ट्रीम नहीं बताया।',
			'fileInfo.copyPath' => 'रास्ता कॉपी करें',
			'fileInfo.pathCopied' => 'फ़ाइल मार्ग कॉपी',
			'fileInfo.codec' => 'कोडेक',
			'fileInfo.codecTag' => 'कोडेक टैग',
			'fileInfo.resolution' => 'संकल्प',
			'fileInfo.codedResolution' => 'कोड संकल्प',
			'fileInfo.bitrate' => 'बिटकॉइन',
			'fileInfo.frameRate' => 'फ्रेम दर',
			'fileInfo.rotation' => 'रोटेशन',
			'fileInfo.comment' => 'कैसे',
			'fileInfo.audioDescription' => 'ऑडियो विवरण',
			'fileInfo.headerCompression' => 'शीर्षक संपीड़न',
			'fileInfo.sidecarFile' => 'फ़ाइल सिडम',
			'fileInfo.transportTimestamp' => 'परिवहन टाइम्स',
			'fileInfo.displayOffset' => 'डिस्प्ले ऑफसेट',
			'fileInfo.previewFailureCode' => 'असफलता कोड',
			'fileInfo.previewRetries' => 'रिट्री से पहले',
			'fileInfo.aspectRatio' => 'आस्पेक्ट अनुपात',
			'fileInfo.pixelAspectRatio' => 'Pixel Aspect अनुपात',
			'fileInfo.profile' => 'प्रोफ़ाइल',
			'fileInfo.level' => 'स्तर',
			'fileInfo.bitDepth' => 'थोड़ा गहरा',
			'fileInfo.pixelFormat' => 'पिक्सेल प्रारूप',
			'fileInfo.colorSpace' => 'रंग स्थान',
			'fileInfo.colorRange' => 'रंग रेंज',
			'fileInfo.colorPrimaries' => 'कलर प्राइमरी',
			'fileInfo.colorTransfer' => 'रंग स्थानांतरण',
			'fileInfo.chromaSubsampling' => 'क्रोम Subsampling',
			'fileInfo.chromaLocation' => 'क्रॉम स्थान',
			'fileInfo.scanType' => 'स्कैनिंग प्रकार',
			'fileInfo.interlaced' => 'इंटरलेशन',
			'fileInfo.anamorphic' => 'एनामोरिक',
			'fileInfo.referenceFrames' => 'संदर्भ फ्रेम',
			'fileInfo.dynamicRange' => 'गतिशील सीमा',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Dolby Vision स्तर',
			'fileInfo.dolbyVisionVersion' => 'Dolby Vision संस्करण',
			'fileInfo.dolbyVisionLayers' => 'Dolby Vision स्लाइड्स',
			'fileInfo.baseLayerCompatibility' => 'आधार परत संगतता',
			'fileInfo.avcBitstream' => 'AVC बिटस्ट्रीम',
			'fileInfo.nalLengthSize' => 'लंबाई का आकार',
			'fileInfo.scalingMatrix' => 'स्केलिंग मैट्रिक्स',
			'fileInfo.streamIdentifier' => 'स्ट्रीम पहचानकर्ता',
			'fileInfo.streamIndex' => 'स्ट्रीम इंडेक्स',
			'fileInfo.streamId' => 'स्ट्रीम आईडी',
			'fileInfo.language' => 'भाषा',
			'fileInfo.languageCode' => 'भाषा कोड',
			'fileInfo.streamTitle' => 'ट्रैक शीर्षक',
			'fileInfo.channels' => 'चैनल',
			'fileInfo.sampleRate' => 'नमूना दर',
			'fileInfo.spatialAudio' => 'अंतरिक्ष ऑडियो',
			'fileInfo.textBased' => 'पाठ आधारित',
			'fileInfo.subtitleFormat' => 'साइडर फॉर्मेट',
			'fileInfo.provider' => 'प्रदाता',
			'fileInfo.matchScore' => 'मैच स्कोर',
			'fileInfo.externalDelivery' => 'अलग से सेवा की जा सकती है',
			'fileInfo.sidecarPath' => 'साइडर रास्ता',
			'fileInfo.sourceStream' => 'कॉपी से',
			'fileInfo.temporary' => 'अस्थायी',
			'fileInfo.timeBase' => 'समय आधार',
			'fileInfo.overallBitrate' => 'कुल बिटरेट',
			'fileInfo.path' => 'रास्ते',
			'fileInfo.fileName' => 'फ़ाइल नाम',
			'fileInfo.size' => 'आकार',
			'fileInfo.totalSize' => 'कुल आकार',
			'fileInfo.container' => 'कंटेनर',
			'fileInfo.duration' => 'लंबाई',
			'fileInfo.previewThumbnails' => 'उपन्यास ट्यूबनाइल',
			'fileInfo.previewIndex' => 'पूर्वावलोकन इंडेक्स',
			'fileInfo.packetLength' => 'पैकेज लंबाई',
			'fileInfo.filePresent' => 'फ़ाइल वर्तमान',
			'fileInfo.fileReadable' => 'सर्वर से पढ़ा जा सकता है',
			'fileInfo.streamPath' => 'प्रवाह मार्ग',
			'fileInfo.optimizedForStreaming' => 'Streaming के लिए अनुकूलित',
			'fileInfo.has64bitOffsets' => '64-बिट ऑफ़सेट',
			'fileInfo.protocol' => 'प्रोटोकॉल',
			'fileInfo.mediaType' => 'मीडिया प्रकार',
			'fileInfo.sourceKind' => 'स्रोत के प्रकार',
			'fileInfo.optimizedVersion' => 'अनुकूलित संस्करण',
			'fileInfo.optimizationTarget' => 'लक्ष्य अनुकूलन',
			'fileInfo.deletedAt' => 'हटाए गए',
			'fileInfo.remoteSource' => 'दूरस्थ स्रोत',
			'fileInfo.infiniteStream' => 'अंतहीन प्रवाह',
			'fileInfo.directPlay' => 'सीधे खेलना',
			'fileInfo.directStream' => 'सीधे प्रवाह',
			'fileInfo.transcoding' => 'ट्रांसकोडिंग',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'संस्करण ID',
			'fileInfo.fileId' => 'फ़ाइल ID',
			'fileInfo.defaultAudioTrack' => 'ऑडियो ट्रैक',
			'fileInfo.defaultSubtitleTrack' => 'Subtitle ट्रैक',
			'fileInfo.subtitlesOff' => 'बंद करें',
			'fileInfo.flagDefault' => 'मूल',
			'fileInfo.flagForced' => 'मजबूर',
			'fileInfo.flagSelected' => 'चुने गए',
			'fileInfo.flagExternal' => 'बाहरी',
			'fileInfo.flagHearingImpaired' => 'सुनने में असफलता',
			'fileInfo.flagDub' => 'डब',
			'fileInfo.flagOriginal' => 'मूल',
			'fileInfo.channelsMono' => 'मोनो',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'प्रोफ़ाइल ${profile}',
			'mediaMenu.markAsWatched' => 'मार्क को देखते हुए',
			'mediaMenu.markAsUnwatched' => 'अनदेखा के रूप में मार्क',
			'mediaMenu.removeFromContinueWatching' => 'जारी रखने से हटाएँ',
			'mediaMenu.viewDetails' => 'विवरण देखें',
			'mediaMenu.goToSeries' => 'सीरीज में जाओ',
			'mediaMenu.shufflePlay' => 'शूफ खेल',
			'mediaMenu.shuffleNotAvailableOffline' => 'शूफल ऑफ़लाइन उपलब्ध नहीं है',
			'mediaMenu.fileInfo' => 'फ़ाइल जानकारी',
			'mediaMenu.deleteEpisodeFromServer' => 'सर्वर से एपिसोड हटाएं',
			'mediaMenu.deleteSeasonFromServer' => 'सर्वर से सीजन हटाएं',
			'mediaMenu.deleteShowFromServer' => 'सर्वर से प्रदर्शित करें',
			'mediaMenu.deleteMovieFromServer' => 'सर्वर से फ़िल्म हटाएं',
			'mediaMenu.deleteEpisodeTitle' => 'इस एपिसोड को हटाने के लिए?',
			'mediaMenu.deleteSeasonTitle' => 'इस सीजन को हटाने के लिए?',
			'mediaMenu.deleteShowTitle' => 'इस शो को हटा दें?',
			'mediaMenu.deleteMovieTitle' => 'इस फिल्म को हटा दें?',
			'mediaMenu.deleteEpisodeConfirm' => 'एपिसोड हटाएँ',
			'mediaMenu.deleteSeasonConfirm' => 'सीजन हटाने',
			'mediaMenu.deleteShowConfirm' => 'प्रदर्शनी हटाएँ',
			'mediaMenu.deleteMovieConfirm' => 'फ़िल्म हटाएँ',
			'mediaMenu.deleteAnyway' => 'किसी भी तरह से हटाएं',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => 'अपने सर्वर से स्थायी रूप से ${title} को हटा दें?',
			'mediaMenu.deleteMultipleWarning' => 'इसमें सभी एपिसोड और उनके फ़ाइल शामिल हैं।',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n, one: 'इससे इसमें मौजूद ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} एपिसोड और उसकी फ़ाइल मिट जाएँगे।', other: 'इससे इसमें मौजूद सभी ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} एपिसोड और उनकी फ़ाइलें मिट जाएँगे।', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n, one: 'यह आइटम ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} फ़ाइल में संग्रहीत है और वह फ़ाइल मिट जाएगी।', other: 'यह आइटम ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} फ़ाइलों में संग्रहीत है और वे सभी मिट जाएँगी।', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} अन्य एपिसोड उसी फ़ाइल में संग्रहीत है और वह भी मिट जाएगा:', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} अन्य एपिसोड उसी फ़ाइल में संग्रहीत हैं और वे भी मिट जाएँगे:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'PlezyNG यह जांच नहीं कर सकता है कि यह कौन से फ़ाइलों को हटा देगा, इसलिए यह ऊपर नामित आइटम से अधिक हटा सकता है. रद्द करें और फिर से कोशिश करें, या किसी भी तरह से हटा दें.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'आपके सर्वर ने इस आइटम के लिए फ़ाइल विवरण प्रदान नहीं किया है, इसलिए PlezyNG यह जांच नहीं कर सकता है कि यह किस फ़ाइल को हटा देगा. यह ऊपर नामित आइटम से अधिक हटा सकता है.',
			'mediaMenu.mediaDeletedSuccessfully' => 'मीडिया के आइटम को सफलतापूर्वक हटा दिया गया',
			'mediaMenu.mediaFailedToDelete' => 'मीडिया आइटम को हटाने में विफलता',
			'mediaMenu.rate' => 'दरें',
			'mediaMenu.playFromBeginning' => 'शुरुआत से खेलना',
			'mediaMenu.playVersion' => 'खेल संस्करण ...',
			'rateSheet.title' => 'दरें',
			'rateSheet.server' => 'सर्वर',
			'rateSheet.favorite' => 'पसंद',
			'rateSheet.favorited' => 'पसंद',
			'rateSheet.saved' => 'बचाए गए',
			'rateSheet.notAvailable' => 'कोई मैच नहीं मिला',
			'rateSheet.noConnectedServices' => 'वहां रेट करने के लिए सेटिंग्स में एक सेवा कनेक्ट करें।',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, फिल्में',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, टीवी शो',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'देखते हैं',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} प्रतिशत देखा गया',
			'accessibility.mediaCardUnwatched' => 'अनदेखा',
			'accessibility.tapToPlay' => 'खेलने के लिए टैप',
			'accessibility.decrease' => 'कम',
			'accessibility.increase' => 'बढ़ते',
			'accessibility.decreaseValue' => ({required Object label}) => 'गिरावट ${label}',
			'accessibility.increaseValue' => ({required Object label}) => 'बढ़ोतरी ${label}',
			'accessibility.hue' => 'हाई',
			'accessibility.saturation' => 'Saturation में',
			'accessibility.brightness' => 'चमक',
			'accessibility.hexColor' => 'हेक्स रंग',
			'accessibility.expandText' => 'पाठ का विस्तार',
			'accessibility.collapseText' => 'टूटने का पाठ',
			'accessibility.alphabetNavigation' => 'अल्फाबेटिक नाविगेशन',
			'accessibility.alphabetScrollHint' => 'ऊपर या नीचे स्विच करें ताकि पत्र के माध्यम से आगे बढ़ें',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'पंक्ति ${row} से ${rowCount}, स्तंभ ${column} से ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'लाइन ${row} से ${rowCount}',
			'accessibility.autoScrollPlay' => 'Auto-Scroll के बारे में',
			'accessibility.autoScrollPause' => 'स्क्रॉल ऑटो-स्क्रॉल',
			'accessibility.hueShort' => 'H',
			'accessibility.saturationShort' => 'एस',
			'accessibility.valueShort' => 'V में',
			'accessibility.red' => 'लाल',
			'accessibility.green' => 'हरे रंग',
			'accessibility.blue' => 'ब्लू',
			'accessibility.redShort' => 'R',
			'accessibility.greenShort' => 'जी',
			'accessibility.blueShort' => 'बी',
			'accessibility.colorModeHsv' => 'HSV',
			'accessibility.colorModeRgb' => 'आरजीबी',
			'accessibility.title' => 'पहुंच',
			'accessibility.summary' => 'पाठ, विपरीत, आंदोलन और नियंत्रण',
			'accessibility.systemHint' => 'आपके डिवाइस की पहुंच सेटिंग्स हमेशा लागू होती हैं. इन विकल्पों में PlezyNG के दौरान समायोजन जोड़े जाते हैं.',
			'accessibility.readability' => 'पढ़ना और दृश्यता',
			'accessibility.textSize' => 'अतिरिक्त पाठ आकार',
			'accessibility.preview' => 'अपनी अगली कहानी खोजें. पढ़ें, सुनो और अपने स्वयं के गति से देखें.',
			'accessibility.boldText' => 'बहादुर इंटरफ़ेस पाठ',
			'accessibility.highContrast' => 'उच्च विरोधाभास',
			'accessibility.highContrastHint' => 'मजबूत पाठ, आउटलिंग और प्रकाश या अंधेरे सतहों पर ध्यान केंद्रित करने वाले संकेतक।',
			'accessibility.interaction' => 'आंदोलन और बातचीत',
			'accessibility.reduceMotion' => 'आंदोलन को कम करें',
			'accessibility.reduceMotionHint' => 'फ़ोकस संकेतक, पृष्ठ परिवर्तन और सजावटी प्रभावों की गति बंद रखें।',
			'accessibility.largeTargets' => 'अधिक लक्षित लक्ष्य',
			'accessibility.largeTargetsHint' => 'साझा नियंत्रण को स्पर्श और सहायक नेविगेशन के लिए अधिक स्थान दें।',
			'accessibility.navigationHint' => 'नियंत्रणों के बीच जाने के लिए Tab और Shift+Tab, सक्रिय करने के लिए Enter या Space और बंद करने के लिए Escape या वापस जाने वाले बटन का उपयोग करें। किताब खुली होने पर ज़ूम और पढ़ने की प्राथमिकताएँ उपलब्ध रहती हैं।',
			'tooltips.shufflePlay' => 'शूफ खेल',
			'tooltips.playTrailer' => 'ट्रेलर खेलना',
			'tooltips.markAsWatched' => 'मार्क देखने के लिए',
			'tooltips.markAsUnwatched' => 'अनदेखी के रूप में मार्क',
			'audioTracks.track' => ({required Object n}) => 'ऑडियो ट्रैक ${n}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} फ्रेम', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} फ्रेम', ), 
			'videoControls.audioLabel' => 'ऑडियो',
			'videoControls.subtitlesLabel' => 'उपशीर्षक',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => 'पत्रबॉक्स',
			'videoControls.fillScreen' => 'स्क्रीन भरें',
			'videoControls.stretch' => 'तंग',
			'videoControls.lockRotation' => 'लॉक रोटेशन',
			'videoControls.unlockRotation' => 'रोटेशन को खत्म करें',
			'videoControls.timerActive' => 'टाइमर सक्रिय',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'प्लेबैक ${duration} में रुक जाएगा',
			'videoControls.sleepTimerEndOfVideo' => 'वर्तमान वीडियो का अंत',
			'videoControls.sleepTimerStopAtHeader' => 'रुकें',
			'videoControls.sleepTimerDurationHeader' => 'टाइमर',
			'videoControls.playbackWillPauseAtEnd' => 'Playback इस वीडियो के अंत में रुक जाएगा',
			'videoControls.stillWatching' => 'अभी भी देखते हैं?',
			'videoControls.pausingIn' => ({required Object seconds}) => '${seconds} में आराम',
			'videoControls.continueWatching' => 'जारी है',
			'videoControls.autoPlayNext' => 'अगला Auto-Play',
			'videoControls.playNext' => 'Next खेलना',
			'videoControls.playButton' => 'खेलना',
			'videoControls.pauseButton' => 'रोकें',
			'videoControls.playbackPaused' => 'आराम',
			'videoControls.playbackResumed' => 'खेलना',
			'videoControls.loadingVideo' => 'वीडियो लोड',
			'videoControls.showPlaybackControls' => 'Playback नियंत्रण दिखाएं',
			'videoControls.hidePlaybackControls' => 'Playback नियंत्रण को छिपाएं',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'पीछे की ओर खोजें ${seconds} सेकंड',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'आगे की तलाश ${seconds} सेकंड',
			'videoControls.previousButton' => 'पिछला एपिसोड',
			'videoControls.nextButton' => 'अगला एपिसोड',
			'videoControls.previousChapterButton' => 'पिछला अध्याय',
			'videoControls.nextChapterButton' => 'अगला अध्याय',
			'videoControls.muteButton' => 'मुट्ठी',
			'videoControls.unmuteButton' => 'अनमोल',
			'videoControls.settingsButton' => 'Playback सेटिंग्स',
			'videoControls.tracksButton' => 'ऑडियो और उपनाम',
			'videoControls.trackSelectionTitle' => 'प्लेबैक से पहले ट्रैक चुनें',
			'videoControls.trackSelectionAuto' => 'स्वचालित चयन',
			'videoControls.chaptersButton' => 'अध्याय',
			'videoControls.versionQualityButton' => 'संस्करण और गुणवत्ता',
			'videoControls.versionColumnHeader' => 'संस्करण',
			'videoControls.qualityColumnHeader' => 'गुणवत्ता',
			'videoControls.qualityOriginal' => 'मूल',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} एमबीपीएस',
			'videoControls.transcodeUnavailableFallback' => 'ट्रांसकोडिंग उपलब्ध नहीं है - मूल गुणवत्ता खेलने के लिए',
			'videoControls.subtitleUnavailableFallback' => 'चुने हुए उप शीर्षक लोड नहीं किया जा सकता है — बिना उप शीर्षक जारी',
			'videoControls.pipButton' => 'Image-in-Picture मोड',
			'videoControls.aspectRatioButton' => 'आस्पेक्ट अनुपात',
			'videoControls.ambientLighting' => 'पर्यावरण प्रकाश',
			'videoControls.fullscreenButton' => 'पूर्ण स्क्रीन में प्रवेश',
			'videoControls.exitFullscreenButton' => 'पूर्ण स्क्रीन से बाहर',
			'videoControls.alwaysOnTopButton' => 'हमेशा शीर्ष पर',
			'videoControls.rotationLockButton' => 'रोटेशन लॉक',
			'videoControls.lockScreen' => 'लॉक स्क्रीन',
			'videoControls.screenLockButton' => 'स्क्रीन लॉक',
			'videoControls.longPressToUnlock' => 'लंबे समय तक दबाव में विघटित',
			'videoControls.timelineSlider' => 'वीडियो टाइमलाइन',
			'videoControls.volumeSlider' => 'वॉल्यूम स्तर',
			'videoControls.endsAt' => ({required Object time}) => '${time} पर समाप्त',
			'videoControls.pipActive' => 'Picture-in-Picture में खेलना',
			'videoControls.pipFailed' => 'फोटो-इन-चित्र शुरू नहीं हुआ',
			'videoControls.screenshotSaved' => 'स्क्रीनशॉट बचाए गए',
			'videoControls.screenshotFailed' => 'कोई स्क्रीनशॉट नहीं ले सकता',
			'videoControls.zoomPercent' => ({required Object percent}) => 'ज़ूम ${percent}%',
			'videoControls.volumePercent' => ({required Object percent}) => 'वॉल्यूम ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Android 8.0 या नए की आवश्यकता होती है',
			'videoControls.pipErrors.iosVersion' => 'iOS 15.0 या उससे अधिक की आवश्यकता है',
			'videoControls.pipErrors.permissionDisabled' => 'Image-in-picture अक्षम है. इसे सिस्टम सेटिंग्स में सक्षम करें.',
			'videoControls.pipErrors.notSupported' => 'डिवाइस छवि-इन-चित्र मोड का समर्थन नहीं करता है',
			'videoControls.pipErrors.voSwitchFailed' => 'वीडियो आउटपुट को छवि-इन-चित्र के लिए स्विच करने में विफल',
			'videoControls.pipErrors.failed' => 'फोटो-इन-चित्र शुरू नहीं हुआ',
			'videoControls.pipErrors.prepareFailed' => 'फोटो-इन-चित्र तैयार नहीं किया जा सकता था',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'एक त्रुटि हुई: ${error}',
			'videoControls.chapters' => 'अध्याय',
			'videoControls.noChaptersAvailable' => 'कोई अध्याय उपलब्ध नहीं',
			'videoControls.queue' => 'क्यूए',
			'videoControls.noQueueItems' => 'क्यूए में कोई आइटम नहीं',
			'videoControls.noAudioDevicesAvailable' => 'कोई ऑडियो डिवाइस उपलब्ध नहीं है',
			'videoControls.searchSubtitles' => 'Subtitles खोजें',
			'videoControls.loadSubtitleFile' => 'Subtitle फ़ाइल डाउनलोड करें',
			'videoControls.subtitleLoadFailed' => 'Subtitle फ़ाइल डाउनलोड करने में विफल',
			'videoControls.language' => 'भाषा',
			'videoControls.noSubtitlesFound' => 'कोई उपनाम नहीं मिला',
			'videoControls.subtitleDownloaded' => 'Subtitle डाउनलोड करें',
			'videoControls.subtitleDownloadedNotApplied' => 'Subtitle डाउनलोड किया गया, लेकिन इसे चुना नहीं जा सकता था',
			'videoControls.subtitleDownloadFailed' => 'Subtitle डाउनलोड करने में असफल',
			'videoControls.searchLanguages' => 'भाषाओं की खोज...',
			'videoControls.skipIntro' => 'स्काइप इनट्रू',
			'videoControls.skipCredits' => 'क्रेडिट स्केप',
			'videoControls.skipAds' => 'स्काइप विज्ञापन',
			'videoControls.nextEpisode' => 'अगला एपिसोड',
			'videoControls.subtitleTrack' => ({required Object n}) => 'ट्रैक ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => 'पदों की संख्या ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (निरपेक्ष)',
			'videoControls.osdSubtitlesOff' => 'पदों की सूची: Off',
			'videoControls.osdSubtitles' => ({required Object track}) => 'पदों की संख्या: ${track}',
			'videoControls.osdAudio' => ({required Object track}) => 'ऑडियो: ${track}',
			'messages.markedAsWatched' => 'देखने के लिए मार्केटिंग',
			'messages.markedAsUnwatched' => 'अनदेखा के रूप में चिह्नित',
			'messages.markedAsWatchedOffline' => 'देखने के रूप में चिह्नित (जब ऑनलाइन सिंक्रनाइज़ किया जाएगा)',
			'messages.markedAsUnwatchedOffline' => 'अनदेखा के रूप में चिह्नित (जब ऑनलाइन सिंक्रनाइज़ किया जाएगा)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'स्वचालित रूप से हटाया: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n, one: 'स्वचालित रूप से हटाया ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} डाउनलोड किया गया', other: 'स्वचालित रूप से हटाया ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} देखा डाउनलोड', ), 
			'messages.removedFromContinueWatching' => 'जारी रखने से हटा दिया',
			'messages.errorLoading' => ({required Object error}) => 'त्रुटि: ${error}',
			'messages.searchPartialResults' => 'कुछ मीडिया सर्वरों की खोज नहीं की जा सकती थी. उपलब्ध परिणाम दिखाते हैं.',
			'messages.streamInterrupted' => 'प्रवाह बंद कर दिया गया था. प्रेस खेल या रिट्री करने की कोशिश करें.',
			'messages.liveStreamInterrupted' => 'लाइव स्ट्रीम बंद कर दिया गया. प्रेस गेम रिट्री के लिए।',
			'messages.fileInfoNotAvailable' => 'फ़ाइल जानकारी उपलब्ध नहीं',
			'messages.playbackAuthenticationRequired' => 'इस आइटम को खेलने के लिए मीडिया सर्वर पर फिर से साइन इन करें।',
			'messages.playbackServerUnavailable' => 'मीडिया सर्वर उपलब्ध नहीं है. बाद में फिर से कोशिश करें.',
			'messages.playbackDataInvalid' => 'सर्वर ने नकारात्मक प्लेबैक जानकारी वापस कर दी।',
			'messages.playbackCancelled' => 'Playback रद्द कर दिया गया है।',
			'messages.playbackFailed' => 'प्लेबैक शुरू नहीं किया जा सकता था।',
			'messages.playbackFailedDetail' => ({required Object error}) => 'प्लेबैक शुरू नहीं किया जा सकता था: ${error}',
			'messages.audioOutputFailed' => 'टीवी या रिसीवर के ऑडियो कनेक्शन की जांच करें; यदि अन्य ऐप्स में कोई ध्वनि नहीं है, तो डिवाइस को पुनरारंभ करें।',
			'messages.mediaUnavailable' => 'यह सामग्री अब उपलब्ध नहीं है।',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'त्रुटि लोड फ़ाइल जानकारी: ${error}',
			'messages.errorLoadingSeries' => 'त्रुटि चार्जिंग श्रृंखला',
			'messages.musicNotSupported' => 'संगीत प्लेबैक अभी तक समर्थित नहीं है',
			'messages.noDescriptionAvailable' => 'कोई विवरण उपलब्ध नहीं',
			'messages.noProfilesAvailable' => 'कोई प्रोफ़ाइल उपलब्ध नहीं',
			'messages.contactAdminForProfiles' => 'प्रोफ़ाइल जोड़ने के लिए अपने सर्वर व्यवस्थापक से संपर्क करें',
			'messages.unableToDetermineLibrarySection' => 'इस आइटम के लिए पुस्तकालय अनुभाग निर्धारित करने में असमर्थ',
			'messages.logsCleared' => 'लॉग साफ',
			'messages.logsCopied' => 'क्लिपबोर्ड में कॉपी किए गए लॉग',
			'messages.noLogsAvailable' => 'कोई लॉग उपलब्ध नहीं',
			'messages.libraryScanning' => ({required Object title}) => 'स्कैन करें "${title}" ...',
			'messages.libraryScanStarted' => ({required Object title}) => 'पुस्तकालय स्कैन "${title}" के लिए शुरू हुआ',
			'messages.libraryScanFailed' => ({required Object error}) => 'पुस्तकालय स्कैन करने में विफलता: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => '"${title}" के लिए ताज़ा मेटाडेटा ...',
			'messages.metadataRefreshStarted' => ({required Object title}) => '"${title}" के लिए मेटाडेटा रिफ्रेश शुरू हुआ',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'मेटाडेटा को पुनर्जीवित करने में विफलता: ${error}',
			'messages.logoutConfirm' => 'क्या आप निश्चित हैं कि आप लॉग इन करना चाहते हैं?',
			'messages.noSeasonsFound' => 'कोई मौसम नहीं मिला',
			'messages.seasonsLoadFailed' => 'मौसम नहीं ले सकते',
			'messages.noEpisodesFound' => 'पहली सीजन में कोई घटना नहीं मिली',
			'messages.noEpisodesFoundGeneral' => 'कोई घटना नहीं मिली',
			_ => null,
		} ?? switch (path) {
			'messages.episodesLoadFailed' => 'घटनाओं को लोड नहीं किया जा सकता',
			'messages.noResultsFound' => 'कोई परिणाम नहीं मिला',
			'messages.sleepTimerSet' => ({required Object label}) => 'नींद टाइमर सेट ${label} के लिए',
			'messages.noItemsAvailable' => 'कोई उपलब्ध वस्तु नहीं',
			'messages.failedToCreatePlayQueueNoItems' => 'एक गेमिंग क्यूव बनाने में विफल रहा - कोई आइटम नहीं',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'असफल ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'संगत खिलाड़ी के लिए स्विच करने के लिए ...',
			'messages.serverLimitTitle' => 'Playback असफल रहा',
			'messages.serverLimitBody' => 'सर्वर त्रुटि (HTTP 500). बैंडविड्थ / ट्रांसकोडिंग सीमा शायद इस सत्र को खारिज कर दिया. मालिक से इसे समायोजित करने के लिए पूछें.',
			'messages.mediaUnreadableTitle' => 'फ़ाइल उपलब्ध नहीं',
			'messages.mediaUnreadableBody' => 'सर्वर ने इस आइटम को पाया लेकिन फ़ाइल को पढ़ने में असमर्थ था (HTTP 404). फ़ाइल को शायद स्थानांतरित किया गया था, हटा दिया गया था, या इसका स्टोरेज ऑफ़लाइन है. सर्वर के मालिक से फ़ाइल की जांच करने और पुस्तकालय को बचाने के लिए पूछें.',
			'messages.serverBusyTitle' => 'अनावश्यक प्रवाह',
			'messages.serverBusyBody' => 'सर्वर इस फ़ाइल को प्रसारित करने से इनकार कर रहा था (HTTP 503). यह पुनरारंभ हो सकता है, व्यस्त हो सकता है, या फ़ाइल का स्टोरेज ऑफ़लाइन हो सकता है. एक पल में फिर से कोशिश करें - यदि यह जारी रहता है, तो सर्वर के मालिक से पूछें कि सर्वर और फ़ाइल का स्टोरेज जांचें.',
			'messages.playbackNotAllowedTitle' => 'Playback की अनुमति नहीं है',
			'messages.playbackNotAllowedBody' => 'सर्वर ने इस आइटम को प्रसारित करने से इनकार कर दिया (HTTP 403). आपके खाते को इसे खेलने की अनुमति नहीं हो सकती है, या सर्वर केवल अपने स्थानीय नेटवर्क पर प्लेबैक की अनुमति दे सकता है.',
			'messages.logsUploaded' => 'लॉग अपलोड',
			'messages.logsUploadFailed' => 'लॉग अपलोड करने में विफल',
			'messages.logId' => 'लॉग आईडी',
			'messages.burnedSubtitlesUseMenu' => 'उपनाम इस प्रवाह में जलाए जाते हैं. उन्हें उपनाम मेनू से बदलें.',
			'messages.noVideoUrl' => 'कोई वीडियो URL उपलब्ध नहीं है',
			'messages.playbackNoMediaSources' => 'सर्वर को कोई खेलने योग्य मीडिया स्रोत नहीं लौटाया',
			'messages.playbackDataNotPrepared' => 'Playback पहले शुरू किया गया था, इससे पहले कि डेटा तैयार हो गया था',
			'messages.streamSelectionUnavailable' => 'स्ट्रीम चयन इस स्रोत के लिए उपलब्ध नहीं है',
			'messages.streamSelectionFailed' => 'चुने हुए स्ट्रीम को लागू नहीं किया जा सकता',
			'messages.trackSelectionNotRemembered' => 'यह ट्रैक विकल्प केवल वर्तमान प्लेबैक पर लागू होता है।',
			'messages.serverUnavailableForProfile' => 'सक्रिय प्रोफ़ाइल के लिए कोई सर्वर उपलब्ध नहीं है',
			'subtitlingStyling.previewSample' => 'तेजी से भूरे रंग का फॉक्स कुत्ते के ऊपर कूदता है',
			'subtitlingStyling.text' => 'पाठ',
			'subtitlingStyling.border' => 'सीमा',
			'subtitlingStyling.background' => 'पृष्ठभूमि',
			'subtitlingStyling.fontSize' => 'फ़ॉन्ट आकार',
			'subtitlingStyling.textColor' => 'पाठ रंग',
			'subtitlingStyling.borderSize' => 'सीमा आकार',
			'subtitlingStyling.borderColor' => 'सीमा रंग',
			'subtitlingStyling.backgroundOpacity' => 'पृष्ठभूमि अस्थिरता',
			'subtitlingStyling.backgroundColor' => 'पृष्ठभूमि रंग',
			'subtitlingStyling.position' => 'स्थिति',
			'subtitlingStyling.assOverride' => 'ASS अधिग्रहण',
			'subtitlingStyling.overrideScale' => 'स्केल',
			'subtitlingStyling.overrideForce' => 'ताकत',
			'subtitlingStyling.overrideStrip' => 'स्टाइलिंग हटाएं',
			'subtitlingStyling.positionTop' => 'शीर्ष',
			'subtitlingStyling.positionBottom' => 'नीचे',
			'subtitlingStyling.useMargins' => 'मार्जिन का उपयोग करें',
			'subtitlingStyling.useMarginsDescription' => 'वीडियो के बाहर अंतरिक्ष में पाठ उपशीर्षक की अनुमति दें. स्टाइलिश उपशीर्षक अपनी मूल स्थिति बनाए रख सकते हैं.',
			'subtitlingStyling.anchorToScreen' => 'स्क्रीन के लिए एन्कोर',
			'subtitlingStyling.anchorToScreenDescription' => 'विस्तृत स्क्रीन वीडियो के नीचे काले पट्टी में पाठ उपशीर्षक दिखाएं',
			'subtitlingStyling.bold' => 'साहसी',
			'subtitlingStyling.italic' => 'इटली',
			'subtitlingStyling.renderResolution' => 'रेंडर संकल्प',
			'subtitlingStyling.renderResolutionScreen' => 'स्क्रीन संकल्प',
			'subtitlingStyling.renderResolutionVideo' => 'वीडियो संकल्प',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'उन्नत वीडियो प्लेयर सेटिंग्स',
			'mpvConfig.presets' => 'उपन्यास',
			'mpvConfig.noPresets' => 'कोई बचाव नहीं',
			'mpvConfig.saveAsPreset' => 'प्रीमियम के रूप में...',
			'mpvConfig.presetName' => 'प्रीमियम नाम',
			'mpvConfig.presetNameHint' => 'इस प्रीसेट के लिए एक नाम दर्ज करें',
			'mpvConfig.loadPreset' => 'लोड',
			'mpvConfig.deletePreset' => 'डिलीट',
			'mpvConfig.presetSaved' => 'प्रीमियम बचाए गए',
			'mpvConfig.presetLoaded' => 'प्रीमियम लोड',
			'mpvConfig.presetDeleted' => 'प्रीमियम हटाया',
			'mpvConfig.confirmDeletePreset' => 'क्या आप निश्चित हैं कि आप इस प्रीसेट को हटाना चाहते हैं?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan hwdec=auto # टिप्पणी',
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => 'लाइन जोड़ें',
			'mpvConfig.removeLine' => 'लाइन हटाएं',
			'mpvConfig.embeddedVoHint' => 'vo, gpu-context और gpu-api Linux पर अनदेखा किया जाता है: अंतर्निहित वीडियो हमेशा वीडियो प्लेट पर vo=libmpv के माध्यम से रेंडर करता है, और gpu-next (जो ArtCNN की तरह कंप्यूटर छायाओं की आवश्यकता होती है) अंतर्निहित नहीं चल सकता है।',
			'dialog.confirmAction' => 'कार्य की पुष्टि करें',
			'profiles.addPlezyProfile' => 'PlezyNG प्रोफ़ाइल जोड़ें',
			'profiles.switchingProfile' => 'प्रोफ़ाइल स्विच...',
			'profiles.deleteThisProfileTitle' => 'इस प्रोफ़ाइल को हटा दें?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'हटाएँ ${displayName}. कनेक्शन प्रभावित नहीं होते हैं.',
			'profiles.active' => 'सक्रिय',
			'profiles.manage' => 'प्रबंधन',
			'profiles.delete' => 'डिलीट',
			'profiles.signOut' => 'Sign out',
			'profiles.signOutPlexTitle' => 'Plex पर हस्ताक्षर करें?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => '${displayName} और सभी Plex होम उपयोगकर्ताओं को हटा दें? किसी भी समय वापस साइन अप करें.',
			'profiles.signOutPlexDeleteDownloads' => 'डाउनलोड भी करें',
			'profiles.signOutPlexDeleteDownloadsDescription' => 'अन्यथा वे इस डिवाइस पर रहते हैं और जब आप इस खाते में वापस साइन इन करते हैं तो वापस आते हैं।',
			'profiles.signedOutPlex' => 'Plex पर हस्ताक्षर किए गए हैं।',
			'profiles.signOutFailed' => 'असफल होने का संकेत',
			'profiles.sectionTitle' => 'प्रोफ़ाइल',
			'profiles.summarySingle' => 'प्रबंधित उपयोगकर्ताओं और स्थानीय पहचान को मिश्रित करने के लिए प्रोफाइल जोड़ें',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} प्रोफाइल · सक्रिय: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} प्रोफ़ाइल',
			'profiles.removeConnectionTitle' => 'कनेक्शन हटाने के लिए?',
			'profiles.removeConnectionMessage' => ({required Object connectionLabel, required Object displayName}) => '${connectionLabel} के लिए ${displayName} का एक्सेस हटा दें. अन्य प्रोफाइल इसे रखते हैं.',
			'profiles.deleteProfileTitle' => 'प्रोफ़ाइल को हटाने के लिए?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => '${displayName} और इसके कनेक्शन को हटा दें. सर्वर उपलब्ध रहें.',
			'profiles.profileNameLabel' => 'प्रोफ़ाइल नाम',
			'profiles.pinProtectionLabel' => 'PIN सुरक्षा',
			'profiles.copyAutomationLink' => 'कॉपी करें Android स्वचालित लिंक',
			'profiles.copyAutomationLinkDescription' => 'इस प्रोफ़ाइल को एक Android इंटेंट या स्वचालन से चुनें. प्रोफ़ाइल पीएन चेक अभी भी लागू होते हैं.',
			'profiles.automationLinkCopied' => 'प्रोफ़ाइल स्वचालन लिंक कॉपी किया गया है।',
			'profiles.pinManagedByPlex' => 'PIN द्वारा संचालित Plex. plex.tv पर संपादित करें.',
			'profiles.noPinSetEditOnPlex' => 'कोई पिन सेट नहीं. एक की आवश्यकता के लिए, plex.tv पर होम उपयोगकर्ता को संपादित करें.',
			'profiles.setPin' => 'PIN सेट करें',
			'profiles.setPinTitle' => 'PIN सेट करें',
			'profiles.confirmPinTitle' => 'PIN की पुष्टि करें',
			'profiles.pinSet' => 'PIN सेट',
			'profiles.changePin' => 'बदलाव',
			'profiles.removePin' => 'हटाना',
			'profiles.connectionsLabel' => 'कनेक्शन',
			'profiles.add' => 'जोड़ें',
			'profiles.deleteProfileButton' => 'प्रोफ़ाइल हटाएँ',
			'profiles.noConnectionsHint' => 'कोई कनेक्शन नहीं - इस प्रोफ़ाइल का उपयोग करने के लिए एक जोड़ें।',
			'profiles.noConnections' => 'कोई कनेक्शन',
			'profiles.plexHomeAccount' => 'Plex होम खाता',
			'profiles.plexAccountChip' => ({required Object account}) => 'Plex खाता: ${account}',
			'profiles.plexAccountUserChip' => ({required Object user, required Object account}) => '${user} पर ${account}',
			'profiles.connectionDefault' => 'मूल',
			'profiles.connectionAs' => ({required Object displayName}) => 'के रूप में ${displayName}',
			'profiles.makeDefault' => 'डिफ़ॉल्ट करें',
			'profiles.removeConnection' => 'हटाना',
			'profiles.profileRenamed' => 'प्रोफ़ाइल नाम',
			'profiles.borrowAddTo' => ({required Object displayName}) => '${displayName} पर जोड़ें',
			'profiles.borrowExplain' => 'एक और प्रोफ़ाइल के कनेक्शन को उधार दें. PIN-सुरक्षित प्रोफ़ाइलों को एक PIN की आवश्यकता होती है.',
			'profiles.borrowEmpty' => 'अभी तक ऋण देने के लिए कुछ भी नहीं है।',
			'profiles.borrowEmptySubtitle' => 'पहले Plex, Jellyfin, या Emby को किसी अन्य प्रोफ़ाइल से कनेक्ट करें।',
			'profiles.borrowLoadFailed' => 'उपलब्ध कनेक्शन लोड नहीं किया जा सकता. फिर से कोशिश करें.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'से ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'कनेक्शन का ऋण',
			'profiles.borrowFailed' => 'ऋण कनेक्शन में असफल रहा।',
			'profiles.incorrectPin' => 'गलत पिन',
			'profiles.incorrectPinTryAgain' => 'गलत PIN. कृपया फिर से कोशिश करें.',
			'profiles.sourceProfileMissingParentAccount' => 'स्रोत प्रोफ़ाइल अपने माता-पिता खाते की कमी है।',
			'profiles.failedToLoadHomeUsers' => 'अपने Plex होम उपयोगकर्ताओं को लोड नहीं कर सकते. अपने कनेक्शन की जांच करें और फिर से कोशिश करें.',
			'profiles.failedToVerifyPin' => 'PIN की पुष्टि नहीं की गई।',
			'profiles.newProfile' => 'नया प्रोफ़ाइल',
			'profiles.profileNameHint' => 'उदाहरण के लिए, मेहमान, बच्चों, परिवार के कमरे',
			'profiles.pinProtectionOptional' => 'PIN सुरक्षा (वैकल्पिक)',
			'profiles.pinExplain' => 'प्रोफ़ाइल बदलने के लिए 4 डिजिटल पिन की आवश्यकता होती है।',
			'profiles.continueButton' => 'जारी है',
			'profiles.pinsDontMatch' => 'पिन नहीं मिलता',
			'profiles.tokenIdentityMismatch' => 'Plex प्रोफ़ाइल टोकन एक अप्रत्याशित सर्वर पर हल किया गया',
			'profiles.settingsLocked' => 'इस प्रोफ़ाइल के लिए सेटिंग्स बंद हैं।',
			'profiles.unlockSettings' => 'अनलॉक सेटिंग्स',
			'profiles.showExploreForProfile' => 'इस प्रोफ़ाइल के लिए खोजें',
			'profiles.showExploreForProfileDescription' => 'इस प्रोफ़ाइल के नवाचार से Explore को हटाने के लिए बंद करें।',
			'connections.sectionTitle' => 'कनेक्शन',
			'connections.addConnection' => 'कनेक्शन जोड़ें',
			'connections.addConnectionSubtitleNoProfile' => 'Plex के साथ साइन इन करें या Jellyfin या Emby सर्वर से कनेक्ट करें',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => '${displayName}: Plex, Jellyfin, Emby, या किसी अन्य प्रोफ़ाइल कनेक्शन में जोड़ें',
			'connections.sessionExpiredOne' => ({required Object name}) => 'सत्र समाप्त हो गया ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => '${count} सर्वरों के लिए सत्र समाप्त हो गया',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} इस खाते के लिए पहुंच से इनकार कर दिया',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} सर्वर इस खाते के लिए पहुंच से इनकार कर दिया',
			'connections.signInAgain' => 'फिर से हस्ताक्षर करें',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'संपादित करें ${product} कनेक्शन',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => '${serverName} के लिए URL जोड़ें या हटा दें. PlezyNG सबसे कम देरी के साथ पहुंचने योग्य URL का उपयोग करेगा.',
			'accountPreferences.sectionTitle' => 'अकाउंट प्राथमिकताएं',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => 'ऑडियो, उप शीर्षक और पुस्तकालय विकल्पों को सहेजा गया है ${account}',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => 'ऑडियो, उप शीर्षक और पुस्तकालय विकल्प ${count} खातों पर सहेजे गए हैं',
			'accountPreferences.pickAccount' => 'प्रत्येक खाता अपने स्वयं के प्राथमिकताओं को संग्रहीत करता है. इसे संपादित करने के लिए चुनें.',
			'accountPreferences.storedOnAccount' => 'इन विकल्पों को अपने खाते में सहेजा जाता है, इसलिए इसमें साइन अप करने वाले प्रत्येक ऐप उनका उपयोग करता है – इसके अलावा आपके अन्य उपकरणों पर PlezyNG।',
			'accountPreferences.noAccounts' => 'कोई खाता नहीं बनाया जा सकता',
			'accountPreferences.noAccountsHint' => 'Plex पर साइन इन करें, या Jellyfin या Emby सर्वर से कनेक्ट करें, और उस खाते पर संग्रहीत प्राथमिकताएं यहां दिखाई देती हैं।',
			'accountPreferences.unavailable' => 'इस खाते तक नहीं पहुंच सकते',
			'accountPreferences.loadFailed' => 'इन प्राथमिकताओं को लोड नहीं किया जा सकता',
			'accountPreferences.noPreference' => 'कोई प्राथमिकता नहीं',
			'accountPreferences.notSet' => 'सेट नहीं',
			'accountPreferences.groups.audioAndSubtitles' => 'ऑडियो और उपशीर्षक',
			'accountPreferences.groups.libraryDisplay' => 'लाइब्रेरी',
			'accountPreferences.groups.personalMedia' => 'व्यक्तिगत मीडिया',
			'accountPreferences.preferredAudioLanguage' => 'ऑडियो भाषा की पसंद',
			'accountPreferences.autoSelectAudio' => 'भाषा के अनुसार ऑडियो का चयन करें',
			'accountPreferences.autoSelectAudioDescription' => 'किसी भी ऑडियो ट्रैक को डिफ़ॉल्ट रूप से फ़ाइल चिह्नित रखता है।',
			'accountPreferences.preferredSubtitleLanguage' => 'Subtitle भाषा के बारे में',
			'accountPreferences.subtitleMode' => 'Subtitles के बारे में जानें',
			'accountPreferences.subtitleModes.none' => 'मैन्युअल रूप से चुने गए',
			'accountPreferences.subtitleModes.noneDescription' => 'कभी भी अपने आप में उपनाम नहीं बनाएं।',
			'accountPreferences.subtitleModes.defaultMode' => 'ट्रैक फ्लैग का पालन करें',
			'accountPreferences.subtitleModes.defaultModeDescription' => 'प्रत्येक उपनाम ट्रैक पर संग्रहीत डिफ़ॉल्ट और मजबूर झंडे का उपयोग करें।',
			'accountPreferences.subtitleModes.always' => 'हमेशा सक्षम',
			'accountPreferences.subtitleModes.alwaysDescription' => 'जब भी कोई मौजूद होता है, तो पसंदीदा भाषा में एक उप-ट्रेक ट्रैक पर स्विच करें।',
			'accountPreferences.subtitleModes.onlyForced' => 'केवल मजबूर उपनाम',
			'accountPreferences.subtitleModes.onlyForcedDescription' => 'केवल मजबूर के रूप में चिह्नित ट्रैक लोड करें।',
			'accountPreferences.subtitleModes.smart' => 'विदेशी ऑडियो के साथ प्रदर्शित',
			'accountPreferences.subtitleModes.smartDescription' => 'केवल तभी उप शीर्षक पर स्विच करें जब ऑडियो किसी अन्य भाषा में है।',
			'accountPreferences.subtitleAccessibility' => 'एसडीएच उपनाम',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'गैर-एसडीएच उपशीर्षक पसंद',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'SDH उपनाम पसंद',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'केवल SDH उपनाम',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'केवल गैर-एसडीएच उपनाम',
			'accountPreferences.forcedSubtitles' => 'मजबूर subtitles',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'अनियंत्रित उपनाम पसंद करें',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'मजबूर subtitles पसंद करें',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'केवल मजबूर उपनाम',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'केवल अनियंत्रित उपनाम',
			'accountPreferences.displayMissingEpisodes' => 'याद किए गए घटनाओं को दिखाएं',
			'accountPreferences.displayMissingEpisodesDescription' => 'सर्वर के बारे में जानते हैं, लेकिन फ़ाइल के लिए नहीं है।',
			'accountPreferences.hidePlayedInLatest' => 'अंतिम में देखे गए वस्तुओं को छिपाएं',
			'accountPreferences.hidePlayedInLatestDescription' => 'उन आइटमों को छोड़ दें जिन्हें आपने पहले से ही सर्वर के नवीनतम पंक्तियों से बाहर देखा है।',
			'accountPreferences.displayCollectionsView' => 'संग्रह दृश्य दिखाएं',
			'accountPreferences.displayCollectionsViewDescription' => 'अपने पुस्तकालयों के बगल में सर्वर के संग्रह दृश्य की पेशकश करें।',
			'accountPreferences.rewatchingInNextUp' => 'Next Up में देखे जाने वाले शो जारी रखें',
			'accountPreferences.rewatchingInNextUpDescription' => 'एक बार जब आप एक शो खत्म करते हैं, तो इसे फिर से शुरू करें और Next Up शो को छोड़ने के बजाय पुनरावृत्ति का पालन करता है।',
			'accountPreferences.watchedIndicator' => 'देखें संकेतक',
			'accountPreferences.watchedIndicatorOptions.none' => 'कभी नहीं',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => 'फिल्में और टीवी शो',
			'accountPreferences.watchedIndicatorOptions.movies' => 'केवल फिल्में',
			'accountPreferences.watchedIndicatorOptions.shows' => 'केवल टीवी शो',
			'accountPreferences.mediaReviewsVisibility' => 'रेटिंग और समीक्षा',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'उपयोगकर्ताओं और आलोचकों',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'केवल उपयोगकर्ता',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'केवल आलोचक',
			'accountPreferences.mediaReviewsOptions.nobody' => 'छिपा हुआ',
			'discover.title' => 'खोजें',
			'discover.noContentAvailable' => 'कोई सामग्री उपलब्ध नहीं',
			'discover.addMediaToLibraries' => 'अपने पुस्तकालयों में कुछ मीडिया जोड़ें',
			'discover.continueWatching' => 'देखना जारी रखें',
			'discover.continueWatchingIn' => ({required Object library}) => 'अब देखें ${library}',
			'discover.nextUp' => 'अगला ऊपर',
			'discover.nextUpIn' => ({required Object library}) => 'अगले में ${library}',
			'discover.recentlyAdded' => 'हाल ही में जोड़ा',
			'discover.recentlyAddedIn' => ({required Object library}) => 'हाल ही में जोड़ा गया ${library} में',
			'discover.latestAlbumsIn' => ({required Object library}) => '${library} में नवीनतम एल्बम',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'हाल ही में खेले गए ${library} में',
			'discover.mostPlayedIn' => ({required Object library}) => 'सबसे ज्यादा खेले गए ${library} में',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'सीज़न ${season} एपिसोड ${episode}',
			'discover.overview' => 'समीक्षा',
			'discover.cast' => 'कास्टिंग',
			'discover.findNext.title' => 'अपने अगले को खोजें',
			'discover.findNext.open' => 'अपने अगले को खोजें',
			'discover.findNext.anyTime' => 'किसी भी समय',
			'discover.findNext.timeAvailable' => 'आपके पास कितना समय है?',
			'discover.findNext.filters' => 'क्षण चुनें',
			'discover.findNext.watch' => 'देखें',
			'discover.findNext.listen' => 'सुनो',
			'discover.findNext.read' => 'पढ़ना',
			'discover.findNext.finishable' => ({required Object duration}) => '${duration} में समाप्त',
			'discover.findNext.aboutDuration' => ({required Object duration}) => 'के बारे में ${duration}',
			'discover.findNext.nextUnit' => ({required Object duration}) => 'अगले अध्याय · ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => '${duration} कुल',
			'discover.findNext.timingVaries' => 'समय बदलता है',
			'discover.findNext.notNow' => 'अब नहीं',
			'discover.findNext.swipeHint' => 'स्विप करें, या नीचे दिए गए बटन का उपयोग करें',
			'discover.findNext.saved' => 'बचाए गए पिक्से',
			'discover.findNext.savedCount' => ({required Object count}) => 'संपादित करें · ${count}',
			'discover.findNext.undo' => 'और',
			'discover.findNext.details' => 'विवरण',
			'discover.findNext.noPicks' => 'अभी तक चुनने के लिए कुछ भी नहीं',
			'discover.findNext.noPicksHint' => 'एक लाइब्रेरी से कनेक्ट करें या शुरू करने के लिए एक मीडिया स्रोत जोड़ें।',
			'discover.findNext.noMatches' => 'इस क्षण के लिए कुछ भी नहीं है',
			'discover.findNext.noMatchesHint' => 'एक और प्रारूप का प्रयास करें या खुद को अधिक समय दें।',
			'discover.findNext.allDone' => 'आप सभी पकड़े गए हैं',
			'discover.findNext.allDoneHint' => 'इन विकल्पों को फिर से देखने के लिए एक ताजा मिश्रण शुरू करें।',
			'discover.findNext.refresh' => 'एक और मिश्रण खोजें',
			'discover.findNext.sourceReason' => ({required Object source}) => 'से ${source}',
			'discover.findNext.libraryReason' => ({required Object library}) => 'से ${library}',
			'discover.findNext.ownedReason' => 'आपकी पुस्तकालय से',
			'discover.findNext.liveNow' => 'अब में',
			'discover.findNext.watchLive' => 'देखें लाइव',
			'discover.findNext.filterAnything' => 'सब कुछ',
			'discover.findNext.filterWatch' => 'देखें',
			'discover.findNext.filterListen' => 'सुनो',
			'discover.findNext.filterRead' => 'पढ़ना',
			'discover.findNext.twentyMinutes' => '20 मिनट',
			'discover.findNext.fortyFiveMinutes' => '45 मिनट',
			'discover.findNext.ninetyMinutes' => '90 मिनट',
			'discover.findNext.apply' => 'आवेदन करें',
			'discover.findNext.openFailed' => 'यह विकल्प अब उपलब्ध नहीं है. फिर से जांच करने के लिए ताज़ा करें.',
			'discover.findNext.changeFailed' => 'यह बदलाव नहीं किया जा सकता है. फिर से कोशिश करें.',
			'discover.findNext.savedLimit' => 'बचाए गए पिक्स भरे हुए हैं. एक चयन को हटाने के लिए दूसरे को बचाने के लिए.',
			'discover.extras' => 'ट्रेलर और अतिरिक्त',
			'discover.studio' => 'स्टूडियो',
			'discover.rating' => 'रेटिंग',
			'discover.director' => 'निर्देशक',
			'discover.directors' => 'निर्देशक',
			'discover.movie' => 'फिल्में',
			'discover.tvShow' => 'टीवी शो',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} मिनट छोड़ दिया',
			'discover.moreLikeThis' => 'इस तरह से अधिक',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} पदों की सूची', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} पदों की सूची', ), 
			'discover.person.born' => 'जन्म',
			'discover.person.died' => 'मृत',
			'discover.person.birthplace' => 'जन्म स्थान',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date} (वय ${age})',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date} (वय ${age})',
			'errors.searchFailed' => ({required Object error}) => 'खोज विफल: ${error}',
			'errors.searchUnavailable' => 'किसी भी मीडिया सर्वर तक पहुंच नहीं पाया।',
			'errors.connectionTimeout' => ({required Object context}) => 'लोड करते समय कनेक्शन टाइम-आउट ${context}',
			'errors.connectionFailed' => 'मीडिया सर्वर से कनेक्ट नहीं कर सकते',
			'errors.unableToLoad' => ({required Object context}) => '${context} लोड करने में असमर्थ है. कृपया फिर से कोशिश करें.',
			'errors.noClientAvailable' => 'कोई ग्राहक उपलब्ध नहीं',
			'errors.pleaseEnterToken' => 'कृपया एक टोकन दर्ज करें',
			'errors.invalidToken' => 'अयोग्य टोकन',
			'errors.failedToVerifyToken' => ({required Object error}) => 'टोकन की पुष्टि नहीं की गई: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => '${displayName} पर स्विच करने में विफल',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => '${displayName} को हटाने में विफलता',
			'errors.failedToRate' => 'रेटिंग नहीं कर सकते',
			'errors.reasonTimedOut' => 'कनेक्शन समय से बाहर',
			'errors.reasonUnreachable' => 'सर्वर तक पहुंच नहीं पाया',
			'errors.reasonRefused' => 'सर्वर ने अनुरोध को अस्वीकार कर दिया',
			'errors.reasonNotFound' => 'अब सर्वर पर नहीं है।',
			'errors.reasonServerError' => 'सर्वर ने एक त्रुटि की सूचना दी',
			'errors.reasonCancelled' => 'अनुरोध रद्द कर दिया गया',
			'errors.reasonUnexpected' => 'एक अप्रत्याशित गलती हुई',
			'libraries.playRandomMovie' => 'एक यादृच्छिक फिल्म खेलना',
			'libraries.randomPickFailed' => 'मैं इस पुस्तकालय से एक यादृच्छिक फिल्म नहीं चुन सकता था।',
			'libraries.title' => 'पुस्तकालय',
			'libraries.fallbackTitle' => 'लाइब्रेरी',
			'libraries.scanLibraryFiles' => 'पुस्तकालय फ़ाइलों का स्कैन',
			'libraries.scanLibrary' => 'पुस्तकालय स्कैन',
			'libraries.analyze' => 'विश्लेषण',
			'libraries.analyzeLibrary' => 'पुस्तकालय विश्लेषण',
			'libraries.refreshMetadata' => 'मेटाडेटा को ताज़ा करें',
			'libraries.emptyTrash' => 'खाली ट्रैश',
			'libraries.emptyingTrash' => ({required Object title}) => '"${title}" के लिए खाली कचरा ...',
			'libraries.trashEmptied' => ({required Object title}) => '"${title}" के लिए ट्रैश एम्टिड',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'खाली कचरे में विफलता: ${error}',
			'libraries.analyzing' => ({required Object title}) => '"${title}" का विश्लेषण करें।',
			'libraries.analysisStarted' => ({required Object title}) => '"${title}" के लिए विश्लेषण शुरू हुआ',
			'libraries.failedToAnalyze' => ({required Object error}) => 'पुस्तकालय का विश्लेषण करने में विफलता: ${error}',
			'libraries.noLibrariesFound' => 'कोई पुस्तकालय नहीं मिला',
			'libraries.allLibrariesHidden' => 'सभी पुस्तकालय छिपे हुए हैं',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'छिपे हुए पुस्तकालयों (${count})',
			'libraries.thisLibraryIsEmpty' => 'यह पुस्तकालय खाली है।',
			'libraries.noItemsMatchFilters' => 'कोई आइटम सक्रिय फ़िल्टर के अनुरूप नहीं है',
			'libraries.resetFilters' => 'फ़िल्टर पुनर्स्थापित करें',
			'libraries.all' => 'सारे',
			'libraries.clearAll' => 'सब स्पष्ट',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'क्या आप निश्चित हैं कि आप "${title}" स्कैन करना चाहते हैं?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'क्या आप निश्चित हैं कि आप "${title}" का विश्लेषण करना चाहते हैं?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'क्या आप निश्चित हैं कि आप "${title}" के लिए मेटाडेटा को नवीनीकृत करना चाहते हैं?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'क्या आप निश्चित हैं कि आप "${title}" के लिए खाली कचरा चाहते हैं?',
			'libraries.manageLibraries' => 'पुस्तकालयों का प्रबंधन',
			'libraries.sort' => 'Sort के लिए',
			'libraries.sortBy' => 'सेट करें',
			'libraries.filters' => 'फ़िल्टर',
			'libraries.confirmActionMessage' => 'क्या आप निश्चित हैं कि आप इस कार्रवाई को पूरा करना चाहते हैं?',
			'libraries.showLibrary' => 'पुस्तकालय दिखाएं',
			'libraries.hideLibrary' => 'पुस्तकालय छिपाना',
			'libraries.libraryOptions' => 'पुस्तकालय विकल्प',
			'libraries.content' => 'पुस्तकालय सामग्री',
			'libraries.selectLibrary' => 'पुस्तकालय चुनें',
			'libraries.filtersWithCount' => ({required Object count}) => 'फ़िल्टर (${count})',
			'libraries.noRecommendations' => 'कोई प्रस्ताव उपलब्ध नहीं है',
			'libraries.noCollections' => 'इस पुस्तकालय में कोई संग्रह नहीं',
			'libraries.noFoldersFound' => 'कोई फ़ोल्डर नहीं मिला',
			'libraries.folders' => 'फ़ोल्डर',
			'libraries.tabs.recommended' => 'अनुशंसित',
			'libraries.tabs.browse' => 'ब्राउज़',
			'libraries.tabs.collections' => 'संग्रह',
			'libraries.tabs.playlists' => 'प्लेलिस्ट',
			'libraries.groupings.title' => 'समूह',
			'libraries.groupings.all' => 'सारे',
			'libraries.groupings.movies' => 'फ़िल्में',
			'libraries.groupings.shows' => 'टीवी शो',
			'libraries.groupings.seasons' => 'मौसम',
			'libraries.groupings.episodes' => 'एपिसोड',
			'libraries.groupings.artists' => 'कलाकार',
			'libraries.groupings.albums' => 'एल्बम',
			'libraries.groupings.tracks' => 'ट्रैक',
			'libraries.groupings.folders' => 'फ़ोल्डर',
			'libraries.filterCategories.genre' => 'जीन',
			'libraries.filterCategories.year' => 'वर्ष',
			'libraries.filterCategories.contentRating' => 'सामग्री रेटिंग',
			'libraries.filterCategories.tag' => 'Tag',
			'libraries.filterCategories.unwatched' => 'अनदेखा',
			'libraries.filterCategories.unplayed' => 'अनदेखा',
			'libraries.filterCategories.favorites' => 'पसंदीदा',
			'libraries.filterCategories.filePath' => 'फ़ाइल मार्ग',
			'libraries.sortLabels.title' => 'शीर्षक',
			'libraries.sortLabels.dateAdded' => 'तिथि जोड़ी गई',
			'libraries.sortLabels.releaseDate' => 'रिलीज की तारीख',
			'libraries.sortLabels.rating' => 'रेटिंग',
			'libraries.sortLabels.communityRating' => 'सामुदायिक रेटिंग',
			'libraries.sortLabels.criticRating' => 'महत्वपूर्ण रेटिंग',
			'libraries.sortLabels.userRating' => 'उपयोगकर्ता रेटिंग',
			'libraries.sortLabels.datePlayed' => 'प्ले करने की तिथि',
			'libraries.sortLabels.playCount' => 'खेलों की संख्या',
			'libraries.sortLabels.productionYear' => 'उत्पादन वर्ष',
			'libraries.sortLabels.runtime' => 'रनटाइम',
			'libraries.sortLabels.officialRating' => 'आधिकारिक रेटिंग',
			'libraries.sortLabels.premiereDate' => 'प्रारंभिक तारीख',
			'libraries.sortLabels.startDate' => 'शुरुआती तारीख',
			'libraries.sortLabels.airTime' => 'एयर टाइम',
			'libraries.sortLabels.studio' => 'स्टूडियो',
			'libraries.sortLabels.random' => 'संयोग',
			'libraries.sortLabels.dateShared' => 'तारीख साझा',
			'libraries.sortLabels.latestEpisodeAirDate' => 'अंतिम संस्करण एयर डेटा',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'अंतिम संस्करण की तारीख जोड़ा गया',
			'libraries.sortLabels.dateDownloaded' => 'डाउनलोड की तारीख',
			'libraries.sortLabels.size' => 'आकार',
			'libraries.sortLabels.library' => 'लाइब्रेरी',
			'libraries.advancedFilters.include' => 'शामिल है',
			'libraries.advancedFilters.exclude' => 'बाहर',
			'libraries.advancedFilters.any' => 'किसी भी',
			'libraries.advancedFilters.yes' => 'हाँ',
			'libraries.advancedFilters.no' => 'नहीं',
			'libraries.advancedFilters.not' => ({required Object value}) => 'नहीं ${value}',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '${count} चुने गए',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '${count} को छोड़ दिया गया',
			'libraries.advancedFilters.searchValues' => 'खोज मूल्य',
			'libraries.advancedFilters.noValues' => 'कोई मूल्य नहीं',
			'libraries.advancedFilters.matchContains' => 'कंटेनर',
			'libraries.advancedFilters.matchNotContains' => 'इसमें शामिल नहीं है',
			'libraries.advancedFilters.matchIs' => 'है',
			'libraries.advancedFilters.matchIsNot' => 'नहीं है',
			'libraries.advancedFilters.matchBeginsWith' => 'शुरुआत के साथ',
			'libraries.advancedFilters.matchEndsWith' => 'समाप्त होता है',
			'libraries.advancedFilters.textHint' => 'मैच करने के लिए प्रकार',
			'libraries.advancedFilters.from' => 'से',
			'libraries.advancedFilters.to' => 'के लिए',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from} से ${to} तक',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value} और ऊपर',
			'libraries.advancedFilters.atMost' => ({required Object value}) => '${value} तक',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => '${count} दिन पहले',
			'libraries.advancedFilters.dateLastYear' => 'पिछले साल',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => '${count} दिनों से अधिक पुराना',
			'libraries.advancedFilters.dateOlderThanYear' => 'एक साल से अधिक उम्र के',
			'libraries.selection.selectItems' => 'आइटम चुनें',
			'libraries.selection.selectedCount' => ({required Object count}) => '${count} चुने गए',
			'libraries.selection.actions' => 'चयन कार्य',
			'libraries.selection.confirmDescendants' => 'यह चयनित शो और मौसमों में सभी एपिसोडों को बदलता है।',
			'libraries.selection.confirmUnwatched' => 'यह भी चुने हुए आइटम के लिए प्लेबैक प्रगति को साफ करता है।',
			'libraries.selection.confirmCount' => ({required Object count}) => 'चयनित आइटम: ${count}.',
			'libraries.selection.completed' => ({required Object count}) => 'पदों की संख्या: ${count}',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => 'अद्यतन ${succeeded}; असफल ${failed}. असफल आइटम चुने हुए रहते हैं।',
			'about.title' => 'के बारे',
			'about.openSourceLicenses' => 'Open Source लाइसेंस',
			'about.versionLabel' => ({required Object version}) => 'संस्करण ${version}',
			'about.appDescription' => 'फ्लोटर के लिए एक सुंदर Plex, Jellyfin, और Emby क्लाइंट',
			'about.viewLicensesDescription' => 'तीसरे पक्ष की पुस्तकालयों के लाइसेंस देखें',
			'about.privacyPolicy' => 'गोपनीयता नीति',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'कोई सर्वर नहीं मिला ${username} (${email}) के लिए',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'सर्वरों को लोड करने में विफलता: ${error}',
			'serverSelection.noValidServers' => 'इस खाते में कोई उपयोगी सर्वर नहीं पाए गए',
			'hubDetail.title' => 'शीर्षक',
			'hubDetail.releaseYear' => 'रिलीज वर्ष',
			'hubDetail.dateAdded' => 'तिथि जोड़ी गई',
			'hubDetail.rating' => 'रेटिंग',
			'hubDetail.noItemsFound' => 'कोई आइटम नहीं मिला',
			'logs.clearLogs' => 'स्पष्ट लॉग',
			'logs.copyLogs' => 'लॉग कॉपी करें',
			'logs.uploadLogs' => 'लॉग अपलोड करें',
			'logs.saveLogs' => 'फ़ाइल में लॉग्स को सहेजें',
			'logs.logsSaved' => ({required Object path}) => 'लॉग ${path} पर संग्रहीत',
			'logs.saveLogsFailed' => 'लॉग फ़ाइल को बचाने में सक्षम नहीं था।',
			'detail.endsAt' => ({required Object time}) => '${time} पर समाप्त',
			'startup.failedTitle' => 'PlezyNG शुरू नहीं किया जा सकता',
			'startup.failedBody' => 'स्टार्टअप के दौरान कुछ गलत हो गया. नीचे दिए गए विवरण बताते हैं कि क्या विफल रहा।',
			'startup.failedBodyRepairable' => 'PlezyNG की सहेजी हुई सेटिंग्स फ़ाइल क्षतिग्रस्त है। ऐप शुरू होने से पहले इसे फिर से बनाना होगा। दोबारा कोशिश करने से मदद नहीं मिलेगी — स्टोरेज की मरम्मत का विकल्प चुनें।',
			'startup.phaseLabel' => 'कदम',
			'startup.showDetails' => 'विवरण दिखाएं',
			'startup.hideDetails' => 'विवरण छिपाएं',
			'startup.copyDetails' => 'विवरण कॉपी करें',
			'startup.detailsCopied' => 'Clipboard में कॉपी किए गए विवरण',
			'startup.uploadDetails' => 'अपलोड करें विवरण',
			'startup.repairStorage' => 'भंडारण की मरम्मत',
			'startup.repairTitle' => 'संग्रहीत डेटा की मरम्मत?',
			'startup.repairBodyCommon' => 'PlezyNG की सेटिंग्स फ़ाइल क्षतिग्रस्त है और इसे पढ़ा नहीं जा सकता है. मरम्मत प्रत्येक सेटिंग को डिफ़ॉल्ट रूप से पुनर्स्थापित करती है.',
			'startup.repairBodyOneCredential' => 'एक सहेजा हुआ साइन-इन क्षतिग्रस्त है और पढ़ा नहीं जा सकता है. मरम्मत केवल उस एक को हटा देती है; आपके अन्य सेटिंग्स अकेले छोड़ दिए जाते हैं.',
			'startup.repairBodySignInsKept' => 'आपके सर्वर और प्रोफ़ाइल में साइन-इन स्थिति बनी रहनी चाहिए।',
			'startup.repairBodySignInsLost' => 'सहेजी गई साइन-इन जानकारी की सुरक्षा करने वाली कुंजी इस फ़ाइल से पुनर्प्राप्त नहीं हो सकती। इसलिए हर सर्वर और प्रोफ़ाइल में फिर से साइन इन करना होगा। आपके मीडिया सर्वर पर कुछ भी प्रभावित नहीं होगा।',
			'startup.repairBodySessionsUncertain' => 'ट्रैकर (MAL, AniList, Simkl, Trakt) और Seerr को अलग से संग्रहीत किया जाता है और जीवित रह सकता है या नहीं हो सकता है. PlezyNG आपको सटीक रूप से बताएगा कि यह क्या रखता है.',
			'startup.repairConfirm' => 'सुधार',
			'startup.repairSucceeded' => 'भंडारण सुधार',
			'startup.repairNeedsRestart' => 'भंडारण सुधार - पुनरारंभ आवश्यक',
			'startup.restartRequiredBody' => 'आपका डेटा ठीक कर दिया गया है, लेकिन उसका उपयोग करने के लिए PlezyNG को फिर से चालू करना होगा। PlezyNG बंद करके दोबारा खोलें।',
			'startup.quitPlezy' => 'क्यूट PlezyNG',
			'startup.repairFailed' => 'मरम्मत असफल',
			'startup.repairKeptSignIns' => 'आपके सर्वर और प्रोफ़ाइल में अभी भी साइन इन है।',
			'startup.repairLostSignIns' => 'सहेजी गई साइन-इन जानकारी की सुरक्षा करने वाली कुंजी पुनर्प्राप्त नहीं हो सकी। हर सर्वर और प्रोफ़ाइल में फिर से साइन इन करना होगा।',
			'startup.repairLostSessions' => 'कम से कम एक ट्रैकर या Seerr कनेक्शन खो गया है और फिर से कनेक्ट किया जाना चाहिए।',
			'startup.backupTitle' => 'क्षतिग्रस्त फ़ाइल का एक प्रति बनाए रखा गया है',
			'startup.backupWarning' => 'इसमें आपकी साइन-इन जानकारी है। इसे अपलोड या साझा न करें।',
			'startup.deleteBackup' => 'कॉपी हटाएँ',
			'startup.backupDeleted' => 'कॉपी हटा दी गई है।',
			'startup.previousFailureTitle' => 'PlezyNG पिछली बार शुरू करने में विफल',
			'licenses.relatedPackages' => 'संबंधित पैकेज',
			'licenses.license' => 'अनुमति',
			'licenses.licenseNumber' => ({required Object number}) => 'लाइसेंस ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} अनुमतिएँ',
			'navigation.libraries' => 'पुस्तकालय',
			'navigation.downloads' => 'डाउनलोड',
			'navigation.liveTv' => 'लाइव टीवी',
			'navigation.explore' => 'खोजें',
			'explore.mdblistShelves.manage' => 'प्रबंधन ढांचे का पता लगाएं',
			'explore.mdblistShelves.manageDescription' => 'अपने MDBList खाते से सूची चुनना और व्यवस्थित करना',
			'explore.mdblistShelves.description' => 'अपने MDBList खाते से सार्वजनिक फिल्म और टीवी सूचियों का चयन करें. MDBList पर सूचियों को बनाएं या कॉपी करें, फिर ताज़ा करें.',
			'explore.mdblistShelves.selected' => 'चुने हुए सीटें',
			'explore.mdblistShelves.available' => 'उपलब्ध खातों की सूची',
			'explore.mdblistShelves.noLists' => 'कोई सार्वजनिक फिल्म या टेलीविजन सूची वापस नहीं आई. एक सूची बनाएं या कॉपी करें MDBList, फिर ताज़ा करें.',
			'explore.mdblistShelves.displayName' => 'शेल नाम प्रदर्शित',
			'explore.mdblistShelves.nameHint' => 'स्रोत सूची नाम का उपयोग करने के लिए सफेद छोड़ दें।',
			'explore.mdblistShelves.add' => 'शेल को जोड़ें',
			'explore.mdblistShelves.save' => 'सीटों को बचाएं',
			'explore.mdblistShelves.moveUp' => ({required Object title}) => '${title} से ऊपर',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => '${title} नीचे जाने के लिए',
			'explore.mdblistShelves.unavailable' => 'यह सूची उपलब्ध नहीं है. सेटिंग्स में अपने शेल्फ को वापस या हटा दें.',
			'explore.mdblistShelves.rateLimited' => 'MDBList अनुरोध सीमा तक पहुंच गया. कृपया बाद में वापस लौटें.',
			'explore.mdblistShelves.loadFailed' => 'आप अपने कनेक्शन और रिट्री की जांच कर सकते हैं।',
			'explore.mdblistShelves.saveFailed' => 'मैं नहीं चाहता कि आप अपने कैनवास को बचा सकें. कृपया वापस लौटें.',
			'explore.mdblistShelves.accountChanged' => 'खाता या प्रोफ़ाइल बदल गया. इन सेटिंग्स को फिर से खोलें.',
			'explore.mdblistShelves.settingsUnreadable' => 'बचाए गए शीटों को पढ़ा नहीं जा सकता. इन सेटिंग्स को बदलने के लिए अपनी सूची को फिर से चुनें.',
			'explore.title' => 'खोजें',
			'explore.selectSource' => 'स्रोत चुनें',
			'explore.rows.watchlist' => 'चेकलिस्ट',
			'explore.rows.recommendedMovies' => 'अनुशंसित फिल्में',
			'explore.rows.recommendedShows' => 'अनुशंसित शो',
			'explore.rows.trendingMovies' => 'ट्रेंड फिल्में',
			'explore.rows.trendingShows' => 'ट्रेंड शो',
			'explore.rows.popularMovies' => 'लोकप्रिय फिल्में',
			'explore.rows.popularShows' => 'लोकप्रिय शो',
			'explore.rows.trendingAnime' => 'एनिमेटेड ट्रेंड',
			'explore.rows.suggestedAnime' => 'अनुशंसित एनीम',
			_ => null,
		} ?? switch (path) {
			'explore.rows.airingAnime' => 'शीर्ष एनीमिया',
			'explore.rows.popularAnime' => 'सबसे लोकप्रिय एनीमिया',
			'explore.rows.trending' => 'रुझान',
			'explore.rows.upcomingMovies' => 'आने वाले फिल्मों',
			'explore.rows.upcomingShows' => 'आने वाले शो',
			'explore.status.airing' => 'एयरिंग',
			'explore.status.ended' => 'समाप्त',
			'explore.status.canceled' => 'रद्द',
			'explore.status.upcoming' => 'आने वाले',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} संस्करण', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} घटनाएं', ), 
			'explore.cast' => 'कास्टिंग',
			'explore.characters' => 'चरित्र',
			'explore.addToWatchlist' => 'Watchlist में शामिल हों',
			'explore.removeFromWatchlist' => 'Watchlist से हटाएँ',
			'explore.addedToWatchlist' => 'watchlist में शामिल',
			'explore.removedFromWatchlist' => 'watchlist से हटाए गए',
			'explore.watchlistUpdateFailed' => 'watchlist को अपडेट नहीं किया जा सकता',
			'explore.watchlistNoMatch' => 'इस आइटम को एक वॉचलिस्ट में फिट नहीं किया जा सकता',
			'explore.notInLibrary' => 'अपनी पुस्तकालय में नहीं',
			'explore.inTheseLibraries' => 'इन पुस्तकालयों',
			'explore.checkingLibrary' => 'अपनी पुस्तकालय की जांच करें।',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} सर्वर की जांच नहीं की जा सकती', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} सर्वरों की जांच नहीं की जा सकती', ), 
			'explore.emptyTitle' => 'यहाँ अभी तक कुछ नहीं',
			'explore.emptyMessage' => ({required Object source}) => '${source} से टुकड़े यहाँ दिखाई देंगे जब उनके पास सामग्री हो।',
			'explore.searchHint' => ({required Object source}) => 'खोज ${source}',
			'explore.searchEmpty' => ({required Object query}) => '"${query}" के लिए कोई परिणाम नहीं',
			'explore.searchPrompt' => ({required Object source}) => 'फिल्मों और शोों की खोज ${source} पर की जाती है।',
			'explore.searchFailed' => 'खोज विफल हो गई. अपने कनेक्शन की जांच करें और फिर से कोशिश करें.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} लोकप्रिय',
			'explore.badge.rankAiring' => ({required Object n}) => '# ${n} एयरिंग',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} रेट किया गया',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} ट्रेंडिंग',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} में ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} देखें',
			'explore.badge.available' => 'उपलब्ध',
			'explore.badge.partiallyAvailable' => 'आंशिक उपलब्ध',
			'explore.badge.availableIn4k' => '4K उपलब्ध है',
			'explore.badge.requested' => 'अनुरोध',
			'explore.badge.pendingApproval' => 'अनुमोदन के लिए',
			'explore.badge.processing' => 'प्रसंस्करण',
			'explore.badge.declined' => 'गिरावट',
			'explore.badge.requestFailed' => 'अनुरोध विफल',
			'explore.badge.requested4k' => '4K की मांग',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} मौसम',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => 'एप ${episode} में ${duration}',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'अगले में ${duration}',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} ईपीएस',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} मिनट / एप',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} सूचीबद्ध',
			'explore.stats.viewersDay' => ({required Object n}) => '${n} आज देखा गया',
			'explore.stats.viewersWeek' => ({required Object n}) => 'इस हफ्ते ${n} बार देखा गया',
			'explore.stats.viewersMonth' => ({required Object n}) => 'इस महीने ${n} बार देखा गया',
			'explore.stats.viewersYear' => ({required Object n}) => 'इस साल ${n} बार देखा गया',
			'explore.stats.viewersAllTime' => ({required Object n}) => '${n} दर्शक',
			'explore.stats.planning' => ({required Object n}) => '${n} देखने के लिए योजना',
			'explore.stats.favorited' => ({required Object n}) => '${n} पसंद',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} इसे छोड़ दिया',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} टिप्पणियाँ', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} टिप्पणियाँ', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} वोट',
			'explore.stats.watching' => ({required Object n}) => '${n} इसे देखें',
			'explore.stats.completed' => ({required Object n}) => '${n} पूरा हो गया',
			'explore.stats.onHold' => ({required Object n}) => '${n} पर रखें',
			'explore.stats.dropped' => ({required Object n}) => '${n} गिरावट',
			'explore.season.winter' => 'सर्दियों',
			'explore.season.spring' => 'वसंत',
			'explore.season.summer' => 'ग्रीष्मकालीन',
			'explore.season.fall' => 'गिरना',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'टीवी',
			'explore.format.tvShort' => 'टीवी संक्षिप्त',
			'explore.format.movie' => 'फिल्में',
			'explore.format.special' => 'विशेष',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => 'संगीत',
			'explore.format.other' => 'अन्य',
			'explore.sourceMaterial.original' => 'मूल',
			'explore.sourceMaterial.manga' => 'मंगेशकर',
			'explore.sourceMaterial.lightNovel' => 'प्रकाश की कहानी',
			'explore.sourceMaterial.novel' => 'उपन्यास',
			'explore.sourceMaterial.visualNovel' => 'दृश्य कथा',
			'explore.sourceMaterial.game' => 'खेल',
			'explore.sourceMaterial.webComic' => 'Web कॉमिक्स',
			'explore.sourceMaterial.musicRelease' => 'संगीत',
			'explore.sourceMaterial.otherMedia' => 'अन्य',
			'explore.creditRole.actor' => 'अभिनेता',
			'explore.creditRole.director' => 'निर्देशक',
			'explore.creditRole.writer' => 'लेखक',
			'explore.creditRole.producer' => 'निर्माता',
			'explore.creditRole.creator' => 'निर्माता',
			'explore.creditRole.composer' => 'संगीतकार',
			'explore.relation.prequel' => 'प्रीमियम',
			'explore.relation.sequel' => 'सेक्युल',
			'explore.relation.sideStory' => 'साइड कहानी',
			'explore.relation.spinOff' => 'स्पिन-ऑफ',
			'explore.relation.alternativeVersion' => 'वैकल्पिक संस्करण',
			'explore.relation.summary' => 'संक्षेप में',
			'explore.relation.parentStory' => 'माता-पिता की कहानी',
			'explore.relation.adaptation' => 'अनुकूलन',
			'explore.relation.other' => 'संबंधित',
			'explore.broadcast' => ({required Object day, required Object time}) => 'Airs ${day} पर ${time}',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => 'Airs ${day} पर ${time} ${timezone}',
			'explore.detail.originalTitle' => 'मूल शीर्षक',
			'explore.detail.alsoKnownAs' => 'यह भी ज्ञात है कि',
			'explore.detail.studios' => 'अध्ययन',
			'explore.detail.country' => 'देश',
			'explore.detail.language' => 'भाषा',
			'explore.detail.released' => 'रिलीज',
			'explore.detail.physicalRelease' => 'डिस्क पर',
			'explore.detail.ended' => 'समाप्त',
			'explore.detail.addedOn' => ({required Object date}) => 'पदों की संख्या ${date}',
			'explore.detail.yourRating' => 'आपकी रेटिंग',
			'explore.detail.budget' => 'बजट',
			'explore.detail.revenue' => 'बॉक्स ऑफिस',
			'explore.detail.contentAdvisory' => 'उम्र का मार्गदर्शन',
			'explore.detail.tags' => 'टैग',
			'explore.detail.revealSpoilerTags' => 'स्पॉलर टैग',
			'explore.detail.links' => 'बाएं',
			'explore.detail.watchOn' => 'देखें',
			'explore.detail.watchTrailer' => 'ट्रेलर देखें',
			'explore.detail.openOn' => ({required Object site}) => 'पर खोला गया ${site}',
			'explore.detail.crew' => 'चालक दल',
			'explore.detail.ratings' => 'रेटिंग',
			'explore.detail.schedule' => 'कार्यक्रम',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n, one: 'अनुशंसित ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} उपयोगकर्ताओं द्वारा', other: 'अनुशंसित ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} उपयोगकर्ताओं द्वारा', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => '${who} द्वारा अनुशंसित',
			'explore.detail.favoritedBy' => ({required Object who}) => 'पसंदीदा पृष्ठ ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} अभी तक प्रकाशित नहीं किया गया',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'अनुशंसित ${percent} दर्शकों द्वारा',
			'explore.detail.relatedTitles' => 'संबंधित शीर्षक',
			'explore.detail.background' => 'पृष्ठभूमि',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} परिणाम', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} परिणाम', ), 
			'liveTv.title' => 'लाइव टीवी',
			'liveTv.guide' => 'गाइड',
			'liveTv.noChannels' => 'कोई चैनल उपलब्ध नहीं',
			'liveTv.noDvr' => 'किसी भी सर्वर पर स्थापित कोई डीवीआर नहीं है',
			'liveTv.serverUnavailable' => 'लाइव टीवी सर्वर उपलब्ध नहीं है।',
			'liveTv.serverNotConnected' => 'लाइव टीवी सर्वर कनेक्ट नहीं है।',
			'liveTv.noPrograms' => 'कोई प्रोग्राम डेटा उपलब्ध नहीं',
			'liveTv.liveStreamFailed' => 'लाइव स्ट्रीम असफल',
			'liveTv.unknownProgram' => 'अज्ञात कार्यक्रम',
			'liveTv.timelineLiveProgram' => 'लाइव प्रोग्राम (प्लेबैक इस प्रोग्राम के बाहर हो सकता है)',
			'liveTv.timelineBuffer' => 'बफर टाइमलाइन',
			'liveTv.timelineUnavailable' => 'समय सीमा उपलब्ध नहीं',
			'liveTv.timelineEstimated' => 'Playback के बारे में',
			'liveTv.timelinePending' => 'तलाश में',
			'liveTv.timelineStale' => 'समय निर्धारित किया जा सकता है',
			'liveTv.unknownHub' => 'अज्ञात',
			'liveTv.unknownError' => 'अज्ञात गलती',
			'liveTv.channelNumber' => ({required Object number}) => 'चैनल ${number}',
			'liveTv.unknownChannel' => 'अज्ञात चैनल',
			'liveTv.live' => 'लाइव',
			'liveTv.premiereBadge' => 'नई',
			'liveTv.reloadGuide' => 'Reload गाइड',
			'liveTv.searchGuide' => 'खोज गाइड',
			'liveTv.searchHint' => 'खोज चैनलों और प्रोग्राम',
			'liveTv.searchNoResults' => ({required Object query}) => '"${query}" के लिए कोई मैच नहीं',
			'liveTv.channelsSection' => 'चैनल',
			'liveTv.programsSection' => 'कार्यक्रमों',
			'liveTv.now' => 'अब',
			'liveTv.today' => 'आज',
			'liveTv.tomorrow' => 'कल',
			'liveTv.midnight' => 'आधी रात',
			'liveTv.overnight' => 'रात में',
			'liveTv.morning' => 'सुबह',
			'liveTv.daytime' => 'दिन का समय',
			'liveTv.evening' => 'शाम को',
			'liveTv.lateNight' => 'देर रात',
			'liveTv.whatsOn' => 'पर क्या है',
			'liveTv.watchChannel' => 'चैनल देखें',
			'liveTv.favorites' => 'पसंदीदा',
			'liveTv.reorderFavorites' => 'पसंदीदा रिकॉर्ड',
			'liveTv.noFavoriteChannels' => 'कोई पसंदीदा चैनल नहीं',
			'liveTv.noFavoriteChannelsHint' => 'सभी चैनलों को दिखाएं, फिर लंबे समय तक एक चैनल दबाएं ताकि इसे अपने पसंदीदा में जोड़ा जा सके।',
			'liveTv.showAllChannels' => 'सभी चैनलों को दिखाएं',
			'liveTv.favoritesLoadFailed' => 'पसंदीदा लोड नहीं कर सकते. अपने कनेक्शन की जांच करें और फिर से कोशिश करें.',
			'liveTv.favoritesUpdateFailed' => 'पसंदीदा अपडेट नहीं कर सकते. अपने कनेक्शन की जांच करें और फिर से कोशिश करें.',
			'liveTv.joinSession' => 'प्रगति में सत्र में शामिल हों',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'शुरुआत से देखो (${minutes} मिनट पहले)',
			'liveTv.watchLive' => 'देखें लाइव',
			'liveTv.goToLive' => 'जीने जाओ',
			'liveTv.record' => 'रिकॉर्ड',
			'liveTv.recordEpisode' => 'रिकॉर्ड एपिसोड',
			'liveTv.recordSeries' => 'रिकॉर्ड सीरीज',
			'liveTv.recordOptions' => 'रिकॉर्ड विकल्प',
			'liveTv.saveTo' => 'बचाने के लिए',
			'liveTv.recordings' => 'रिकॉर्ड',
			'liveTv.scheduledRecordings' => 'कार्यक्रम',
			'liveTv.recordingRules' => 'रिकॉर्डिंग नियम',
			'liveTv.noScheduledRecordings' => 'रिकॉर्ड करने के लिए कोई योजना नहीं',
			'liveTv.manageRecording' => 'रिकॉर्डिंग प्रबंधन',
			'liveTv.cancelRecording' => 'रिकॉर्डिंग रद्द करें',
			'liveTv.cancelRecordingTitle' => 'इस रिकॉर्डिंग को रद्द करें?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} अब रिकॉर्ड नहीं किया जाएगा।',
			'liveTv.deleteRule' => 'नियम हटाएँ',
			'liveTv.deleteRuleTitle' => 'रिकॉर्डिंग नियम को हटा दें?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => '${title} के भविष्य के एपिसोडों को रिकॉर्ड नहीं किया जाएगा।',
			'liveTv.recordingScheduled' => 'रिकॉर्डिंग योजना',
			'liveTv.alreadyScheduled' => 'यह कार्यक्रम पहले से ही तैयार है।',
			'liveTv.dvrAdminRequired' => 'डीवीआर सेटिंग्स को एक एडमैन खाता की आवश्यकता होती है',
			'liveTv.recordingFailed' => 'रिकॉर्डिंग की योजना नहीं बना सकती',
			'liveTv.recordingTargetMissing' => 'पुस्तकालय रिकॉर्डिंग का निर्धारण नहीं कर सकता',
			'liveTv.recordNotAvailable' => 'रिकॉर्डिंग इस कार्यक्रम के लिए उपलब्ध नहीं है',
			'liveTv.recordingCancelled' => 'रिकॉर्डिंग रद्द',
			'liveTv.recordingRuleDeleted' => 'रिकॉर्डिंग नियम हटा दिया गया',
			'liveTv.processRecordingRules' => 'नियमों का पुनर्विचार',
			'liveTv.recordingInProgress' => 'अब रिकॉर्ड',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} अनुसूचित',
			'liveTv.editRule' => 'Edit नियम',
			'liveTv.editRuleAction' => 'संपादित करें',
			'liveTv.recordingRuleUpdated' => 'रिकॉर्डिंग नियम अद्यतन',
			'liveTv.guideReloadRequested' => 'रेफ्रिजरेटर की मांग',
			'liveTv.guideReloadFailed' => 'मार्गदर्शिका को साफ नहीं किया जा सकता',
			'liveTv.rulesProcessRequested' => 'अनुरोध किया गया पुन: मूल्यांकन',
			'liveTv.rulesProcessFailed' => 'रिकॉर्डिंग नियमों का पुन: मूल्यांकन नहीं किया जा सकता',
			'liveTv.recordShow' => 'रिकॉर्ड शो',
			'liveTv.recordSettings.startEarly' => 'शुरुआत जल्दी (सेकंड)',
			'liveTv.recordSettings.endLate' => 'देर से समाप्त (अध्याय)',
			'liveTv.recordSettings.newOnly' => 'केवल नई घटनाएं',
			'liveTv.recordSettings.anyChannel' => 'किसी भी चैनल पर रिकॉर्ड',
			'liveTv.recordSettings.anyTime' => 'किसी भी समय रिकॉर्ड',
			'liveTv.recordSettings.skipInLibrary' => 'पुस्तकालय में पहले से ही एपिसोड को हटा दें',
			'liveTv.recordSettings.keepUpTo' => 'बनाए रखने के लिए घटनाएं',
			'liveTv.recordSettings.keepUpToHint' => '0 हर एपिसोड को बनाए रखें',
			'liveTv.startingInMinutes' => ({required Object minutes}) => '${minutes} मिनट में शुरू',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} पर ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product} वापस अवास्तविक लाइव टीवी प्लेबैक डेटा',
			'liveTv.failedToStartChannel' => 'लाइव चैनल शुरू नहीं किया जा सकता',
			'liveTv.failedToBuildStreamUrl' => 'स्ट्रीम URL नहीं बना सकते',
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'चैनल शुरू नहीं किया जा सकता: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'चैनल नहीं बदल सकता: ${reason}',
			'collections.title' => 'संग्रह',
			'collections.collection' => 'संग्रह',
			'collections.empty' => 'संग्रह खाली है',
			'collections.deleteCollection' => 'संग्रह हटाएँ',
			'collections.deleteConfirm' => ({required Object title}) => '"${title}" मिटाएँ? इस कार्रवाई को वापस नहीं किया जा सकता।',
			'collections.deleted' => 'संग्रह हटा दिया',
			'collections.deleteFailed' => 'संग्रह को हटाने में विफलता',
			'collections.deleteFailedWithError' => ({required Object error}) => 'संग्रह को हटाने में विफलता: ${error}',
			'collections.selectCollection' => 'चयनित संग्रह',
			'collections.collectionName' => 'संग्रह का नाम',
			'collections.enterCollectionName' => 'संग्रह का नाम दर्ज करें',
			'collections.addedToCollection' => 'संग्रह में जोड़ा',
			'collections.errorAddingToCollection' => 'संग्रह में जोड़ने में विफल',
			'collections.created' => 'संग्रह बनाया',
			'collections.removeFromCollection' => 'संग्रह से हटाएँ',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => 'इस संग्रह से “${title}” हटाएँ?',
			'collections.removedFromCollection' => 'संग्रह से हटाए गए',
			'collections.removeFromCollectionFailed' => 'संग्रह से बाहर निकलने में विफलता',
			'collections.removeFromCollectionError' => ({required Object error}) => 'संग्रह से त्रुटि हटाने: ${error}',
			'collections.searchCollections' => 'खोज संग्रह...',
			'playlists.title' => 'प्लेलिस्ट',
			'playlists.playlist' => 'प्लेलिस्ट',
			'playlists.noPlaylists' => 'कोई प्लेलिस्ट नहीं मिला',
			'playlists.create' => 'प्लेलिस्ट बनाएं',
			'playlists.playlistName' => 'Playlist नाम',
			'playlists.enterPlaylistName' => 'प्लेलिस्ट नाम दर्ज करें',
			'playlists.delete' => 'Playlist के बारे में',
			'playlists.removeItem' => 'Playlist से हटाएँ',
			'playlists.smartPlaylist' => 'स्मार्ट प्लेलिस्ट',
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} आइटम', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} आइटम', ), 
			'playlists.emptyPlaylist' => 'यह प्लेलिस्ट खाली है',
			'playlists.deleteConfirm' => 'प्लेलिस्ट को हटा दें?',
			'playlists.deleteMessage' => ({required Object name}) => 'क्या आप निश्चित हैं कि आप "${name}" को हटाना चाहते हैं?',
			'playlists.created' => 'Playlist बनाया गया',
			'playlists.deleted' => 'Playlist हटा दिया गया',
			'playlists.itemAdded' => 'Playlist में शामिल',
			'playlists.itemRemoved' => 'Playlist से हटाए गए',
			'playlists.selectPlaylist' => 'Playlist का चयन करें',
			'playlists.searchPlaylists' => 'खेलों की खोज...',
			'playlists.errorCreating' => 'Playlist बनाने में असफल',
			'playlists.errorDeleting' => 'Playlist को हटाने में विफलता',
			'playlists.errorLoading' => 'प्लेलिस्ट लोड करने में विफल',
			'playlists.errorAdding' => 'Playlist में शामिल करने में असफल',
			'playlists.errorReordering' => 'प्लेलिस्ट आइटम को पुनर्स्थापित करने में विफलता',
			'playlists.errorRemoving' => 'Playlist से हटाने में असफल',
			'music.goToAlbum' => 'एल्बम पर जाएं',
			'music.goToArtist' => 'कलाकार के लिए जाओ',
			'music.instantMix' => 'मिश्रण मिक्स',
			'music.playNext' => 'अगला खेल',
			'music.addToQueue' => 'क्यूए में जोड़ें',
			'music.discNumber' => ({required Object n}) => 'डिस्क ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ट्रैक', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ट्रैक', ), 
			'music.nowPlaying' => 'अब खेलते हैं',
			'music.playingFrom' => ({required Object title}) => 'खेलने के लिए ${title}',
			'music.queue' => 'क्यूए',
			'music.clearQueue' => 'कतार साफ़ करें',
			'music.lyrics' => 'लिंग',
			'music.visualizer' => 'दृश्य',
			'music.visualizerProfileLoading' => 'ट्रैक विश्लेषण पढ़ने के लिए ...',
			'music.visualizerAmbientMotion' => 'पर्यावरण आंदोलन',
			'music.visualizerPlexLoudness' => 'Plex ध्वनि',
			'music.visualizerPreviousPreset' => 'Previous दृश्य शैली',
			'music.visualizerNextPreset' => 'अगला दृश्य शैली',
			'music.visualizerPresetAurora' => 'Aurora के बारे में',
			'music.visualizerPresetBloom' => 'ब्लू',
			'music.visualizerPresetOrbitals' => 'Orbitals के बारे में',
			'music.visualizerPresetPrism' => 'प्रिस्म',
			'music.visualizerPresetTunnel' => 'टनल',
			'music.visualizerPresetTrackMap' => 'ट्रैक मैप',
			'music.noLyrics' => 'कोई लिंग उपलब्ध नहीं है',
			'music.sleepTimer' => 'नींद का समय',
			'music.sleepTimerEndOfTrack' => 'ट्रैक का अंत',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} मिनट', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} मिनट', ), 
			'music.stopPlayback' => 'प्लेबैक बंद करें',
			'music.previousTrack' => 'पिछला ट्रैक',
			'music.nextTrack' => 'आगे धावन पथ',
			'music.repeat' => 'बार-बार',
			'music.repeatAll' => 'सभी को दोहराएं',
			'music.repeatOne' => 'एक बार दोहराएं',
			'music.instantMixNoServer' => 'कोई सर्वर एक त्वरित मिश्रण के लिए उपलब्ध नहीं है',
			'music.instantMixFailed' => 'मिश्रण को लोड करने में विफलता',
			'music.instantMixEmpty' => 'तुरंत मिश्रण कोई ट्रैक के साथ वापस आया',
			'music.noAudioUrl' => ({required Object track}) => 'कोई ऑडियो URL उपलब्ध नहीं है ${track} के लिए',
			'music.discography.singlesAndEps' => 'सींग्स & EPs',
			'music.discography.live' => 'जीवित',
			'music.discography.compilations' => 'संकलित',
			'watchTogether.title' => 'साथ देखें',
			'watchTogether.description' => 'दोस्तों और परिवार के साथ सिंक्रनाइज़ में सामग्री देखें',
			'watchTogether.createRoom' => 'कमरे बनाएं',
			'watchTogether.creatingRoom' => 'कमरे का निर्माण...',
			'watchTogether.joinRoom' => 'कमरे में शामिल',
			'watchTogether.joiningRoom' => 'कमरे में शामिल...',
			'watchTogether.connecting' => 'कनेक्ट...',
			'watchTogether.relayPublic' => 'कमरे सार्वजनिक Open Watch पार्टी रिलीज का उपयोग करते हैं।',
			'watchTogether.relayCustom' => ({required Object url}) => 'कमरे ${url} पर अपने रिले का उपयोग करते हैं।',
			'watchTogether.recentRooms' => 'हाल के कमरे',
			'watchTogether.roomActions' => 'कमरे के कार्य',
			'watchTogether.renameRoom' => 'कमरे का नाम',
			'watchTogether.removeRoom' => 'हटाना',
			'watchTogether.enterRoomCode' => 'मेजबान से 6 अक्षर कोड दर्ज करें।',
			'watchTogether.roomCode' => 'कमरे का कोड',
			'watchTogether.paste' => 'पास्ता',
			'watchTogether.noCodeInClipboard' => 'क्लिपबोर्ड में कोई कमरे कोड नहीं है',
			'watchTogether.copyCode' => 'कॉपी कोड',
			'watchTogether.codeCopied' => 'कमरे का कोड कॉपी',
			'watchTogether.shareInvite' => 'आमंत्रण साझा',
			'watchTogether.inviteCopied' => 'इसे कॉपी करें. इसे एक संदेश में डालें.',
			'watchTogether.inviteMessage' => ({required Object code}) => 'PlezyNG में मेरे घड़ी एक साथ कमरे में शामिल हों: घड़ी एक साथ खोलें, शामिल कमरे का चयन करें और ${code} में प्रवेश करें।',
			'watchTogether.openSessionControls' => 'Open Watch एक साथ सत्र नियंत्रण',
			'watchTogether.reconnecting' => 'फिर से कनेक्ट...',
			'watchTogether.reconnectingDescription' => 'कनेक्शन बंद हो गया. आप स्वचालित रूप से कमरे में प्रवेश करते हैं.',
			'watchTogether.connected' => 'कनेक्ट',
			'watchTogether.disconnected' => 'विघटित',
			'watchTogether.youAreHost' => 'आप होस्ट हैं',
			'watchTogether.hostedBy' => ({required Object name}) => 'संपादित करें ${name}',
			'watchTogether.hostControlsPlayback' => 'होस्ट नियंत्रण Playback',
			'watchTogether.anyoneCanControl' => 'कोई भी Playback को नियंत्रित कर सकता है',
			'watchTogether.roomLocked' => 'कमरे बंद',
			'watchTogether.nowPlaying' => 'अब खेलते हैं',
			'watchTogether.nothingPlaying' => 'खेलने के लिए कुछ नहीं',
			'watchTogether.nothingPlayingHost' => 'किसी भी पुस्तकालय से कुछ खेलने के लिए इसे कमरे के साथ साझा करें।',
			'watchTogether.nothingPlayingGuest' => 'जब मेजबान कुछ खेलता है, तो यह यहां खुलता है।',
			'watchTogether.notShareable' => 'इस वीडियो में कोई कैटलॉग मैच नहीं है, इसलिए केवल एक ही सर्वर तक पहुंचने वाले लोग इसे खेल सकते हैं।',
			'watchTogether.searching' => 'अपने पुस्तकालयों में इस वीडियो की तलाश में...',
			'watchTogether.yourCopy' => 'आपकी कॉपी',
			'watchTogether.sharingYourCopy' => 'आप अपनी कॉपी साझा कर रहे हैं',
			'watchTogether.playingOtherLength' => ({required Object difference}) => 'अपने कॉपी को खेलने के लिए, ${difference}',
			'watchTogether.mismatchTitle' => 'आपकी कॉपी एक अलग लंबाई है',
			'watchTogether.mismatchDescription' => ({required Object difference}) => 'आपका निकटतम कॉपी कमरे के वीडियो की तुलना में ${difference} है. यह एक और कटौती या संस्करण हो सकता है.',
			'watchTogether.playAnyway' => 'किसी भी तरह से खेल',
			'watchTogether.chooseAnotherCopy' => 'एक और कॉपी चुनें',
			'watchTogether.dontPlay' => 'नहीं खेलें',
			'watchTogether.unavailableTitle' => 'आप इस वीडियो को नहीं रखते हैं',
			'watchTogether.unavailableDescription' => 'PlezyNG अपने पुस्तकालयों में इसे नहीं पाया. खुद को एक प्रति चुनें या फिर से खोजें.',
			'watchTogether.chooseCopy' => 'एक कॉपी चुनें',
			'watchTogether.searchAgain' => 'फिर से खोजें',
			'watchTogether.noCandidates' => 'आपके पुस्तकालयों में कोई प्रतियां नहीं मिलीं।',
			'watchTogether.choiceFailed' => 'कमरे के लिए इस प्रतिलिपि को नहीं खेला जा सकता',
			'watchTogether.lengthLonger' => ({required Object duration}) => '${duration} अधिक',
			'watchTogether.lengthShorter' => ({required Object duration}) => '${duration} छोटे',
			'watchTogether.lengthSame' => 'एक ही लंबाई',
			'watchTogether.lengthUnknown' => 'लंबाई अज्ञात',
			'watchTogether.joinCurrentPlayback' => 'वर्तमान Playback में शामिल हों',
			'watchTogether.joinCurrentPlaybackDescription' => 'होस्टिंग में वापस जाओ जो होस्टिंग वर्तमान में देख रहा है',
			'watchTogether.stopMedia' => 'हर किसी के लिए वीडियो बंद करें',
			'watchTogether.syncOffset' => 'सिंक्रनाइज़ेशन Offset',
			'watchTogether.syncOffsetDescription' => 'अपने वीडियो को स्थानांतरित करें यदि यह कमरे के सामने या पीछे चलता है।',
			'watchTogether.offsetHint' => ({required Object difference}) => 'आपका कॉपी कमरे के वीडियो की तुलना में ${difference} है।',
			'watchTogether.applyDifference' => ({required Object offset}) => 'उपयोग करें ${offset}',
			'watchTogether.offsetMinusSecond' => '1 एस',
			'watchTogether.offsetMinusTenth' => '100 एमएस',
			'watchTogether.offsetPlusTenth' => '+ 100 एमएस',
			'watchTogether.offsetPlusSecond' => '+ 1 एस',
			'watchTogether.participants' => 'प्रतिभागियों',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} प्रतिभागियों', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} प्रतिभागियों', ), 
			'watchTogether.hostBadge' => 'मेहमान',
			'watchTogether.nameYou' => ({required Object name}) => '${name} (आप)',
			'watchTogether.playerIdle' => 'आईडीएल',
			'watchTogether.playerLoading' => 'लोड',
			'watchTogether.playerReady' => 'तैयार',
			'watchTogether.playerBuffering' => 'बफिंग',
			'watchTogether.matchSearching' => 'खोजें',
			'watchTogether.matchMatched' => 'वीडियो है',
			'watchTogether.matchMismatched' => 'अलग लंबाई',
			'watchTogether.matchUnavailable' => 'वीडियो नहीं है',
			'watchTogether.participantOffset' => ({required Object offset}) => 'ऑफ़सेट ${offset}',
			'watchTogether.makeHost' => 'मेजबान बनाएं',
			'watchTogether.makeHostQuestion' => 'हस्तांतरण होस्ट?',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} प्लेबैक को नियंत्रित करेगा और सत्र को हर किसी के लिए चलाएगा।',
			'watchTogether.transfer' => 'स्थानांतरण',
			'watchTogether.removeParticipant' => 'कमरे से बाहर निकलना',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => '${name} को हटा दें।',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} कमरे से बाहर निकलता है. वे कोड के साथ फिर से शामिल हो सकते हैं जब तक कि आप कमरे को बंद न करें.',
			'watchTogether.remove' => 'हटाना',
			'watchTogether.roomSettings' => 'कमरे सेटिंग्स',
			'watchTogether.letEveryoneControl' => 'हर कोई Playback को नियंत्रित करता है',
			'watchTogether.lockRoom' => 'लॉक रूम',
			'watchTogether.lockRoomDescription' => 'कोई नया नहीं शामिल हो सकता',
			'watchTogether.leaveRoom' => 'कमरे छोड़ें',
			'watchTogether.leaveRoomQuestion' => 'कमरे छोड़ने के लिए?',
			'watchTogether.leaveRoomConfirm' => 'आप कमरे कोड के साथ फिर से शामिल हो सकते हैं।',
			'watchTogether.leave' => 'छोड़ो',
			'watchTogether.endRoom' => 'अंतिम कमरे',
			'watchTogether.endRoomQuestion' => 'कमरे का अंत?',
			'watchTogether.endRoomConfirm' => 'यह हर किसी के लिए कमरे का अंत है।',
			'watchTogether.end' => 'अंत',
			'watchTogether.playBlockedTitle' => 'Playback शुरू नहीं हुआ',
			'watchTogether.playBlockedDescription' => 'कमरे के साथ देखने के लिए प्रिंट खेलना शुरू करें।',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} प्रिंट गेम',
			'watchTogether.notices.playbackStarted' => 'Playback शुरू',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} आउटपुट',
			'watchTogether.notices.playbackPaused' => 'Playback बंद हो गया',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} ${position} पर कूद गया',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => '${position} के बारे में जानकारी',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} गति सेट करें ${speed}',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => 'गति सेट ${speed}',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} शुरू ${title}',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => 'अब खेलने के लिए ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} वीडियो बंद कर दिया',
			'watchTogether.notices.mediaStopped' => 'वीडियो बंद हो गया',
			'watchTogether.notices.waitingFor' => ({required Object name}) => '${name} के लिए इंतजार कर रहे हैं ...',
			'watchTogether.notices.waitingForSomeone' => 'किसी को पकड़ने के लिए इंतजार कर रहे हैं ...',
			'watchTogether.notices.finished' => 'समाप्त',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} अब होस्ट है',
			'watchTogether.notices.youAreNowHost' => 'अब आप मेजबान हैं',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} में शामिल',
			'watchTogether.notices.left' => ({required Object name}) => '${name} छोड़ दिया',
			'watchTogether.notices.controlRefused' => 'केवल मेजबान प्लेबैक को नियंत्रित कर सकता है',
			'watchTogether.notices.searchFailed' => 'कुछ सर्वरों को कमरे के वीडियो के लिए खोज नहीं की जा सकती थी',
			'watchTogether.notices.playBlocked' => 'प्रिंट खेल शुरू करने के लिए',
			'watchTogether.notices.shareFailed' => 'इस वीडियो को कमरे के साथ साझा नहीं किया जा सकता',
			'watchTogether.notices.downloadNotShared' => 'डाउनलोड कमरे के साथ साझा नहीं होते हैं जबकि उनके सर्वर ऑफ़लाइन हैं',
			'watchTogether.notices.openFailed' => 'कमरे का वीडियो नहीं खोल सकता था',
			'watchTogether.ended.ended' => 'मेजबान ने कमरे को खत्म कर दिया',
			'watchTogether.ended.kicked' => 'आपको कमरे से बाहर निकाला गया था।',
			'watchTogether.ended.expired' => 'कमरे खत्म हो गए',
			'watchTogether.ended.replaced' => 'आपने इस कमरे को किसी अन्य डिवाइस पर जोड़ा है',
			'watchTogether.ended.lost' => 'कमरे से कनेक्शन खोना',
			'watchTogether.errors.invalidCode' => 'कोड में 6 अक्षर और अंक होते हैं, बिना 0, 1, I, L या O के।',
			'watchTogether.errors.roomNotFound' => 'इस कोड में कोई कमरा नहीं है. यह समाप्त हो सकता है.',
			'watchTogether.errors.roomFull' => 'यह कमरा भरा हुआ है।',
			'watchTogether.errors.roomLocked' => 'मेजबान ने उस कमरे को बंद कर दिया।',
			'watchTogether.errors.relayFull' => 'देखो एक साथ अब व्यस्त है. बाद में फिर से कोशिश करें.',
			'watchTogether.errors.unreachable' => 'मैं घड़ी को एक साथ रिलीज नहीं कर सकता था. अपने कनेक्शन की जांच करें.',
			'watchTogether.errors.rateLimited' => 'थोड़ी देर इंतजार करें और फिर से कोशिश करें।',
			'watchTogether.errors.clientBlocked' => 'इस संस्करण PlezyNG रिले का उपयोग नहीं कर सकता. ऐप को अपडेट करें.',
			'watchTogether.errors.forbidden' => 'केवल मेजबान ही ऐसा कर सकते हैं।',
			'watchTogether.errors.notInRoom' => 'आप एक कमरे में नहीं हैं।',
			'watchTogether.errors.alreadyInRoom' => 'आप पहले से ही एक कमरे में हैं।',
			'watchTogether.errors.resumeFailed' => 'कमरे में नहीं आ सकता था।',
			'watchTogether.errors.unsupported' => 'रिलीज इस बात का समर्थन नहीं करती है।',
			'watchTogether.errors.generic' => 'कुछ गलत हो गया, फिर से कोशिश करें।',
			'watchTogether.untitledEpisode' => ({required Object number}) => 'पदों की संख्या ${number}',
			'downloads.title' => 'डाउनलोड',
			'downloads.manage' => 'प्रबंधन',
			'downloads.tvShows' => 'टीवी शो',
			'downloads.movies' => 'फ़िल्में',
			'downloads.music' => 'संगीत',
			'downloads.tracksQueued' => ({required Object count}) => '${count} ट्रैक डाउनलोड करने के लिए जोड़ा गया है',
			'downloads.noDownloads' => 'अभी तक डाउनलोड नहीं',
			'downloads.noDownloadsDescription' => 'डाउनलोड की गई सामग्री ऑफ़लाइन देखने के लिए यहां दिखाई देगी',
			'downloads.downloadNow' => 'डाउनलोड करें',
			'downloads.deleteDownload' => 'डाउनलोड करें',
			'downloads.retryDownload' => 'रिट्री डाउनलोड',
			'downloads.downloadQueued' => 'डाउनलोड करने के लिए Queued',
			'downloads.downloadResumed' => 'डाउनलोड करें पुनः',
			'downloads.serverErrorBitrate' => 'सर्वर त्रुटि: फ़ाइल रिमोट बिट्रेट सीमा से अधिक हो सकती है',
			'downloads.storageFull' => 'डाउनलोड उपलब्ध भंडारण की रक्षा करने के लिए बंद कर दिया. कुछ स्थान मुक्त करें या डाउनलोड स्थान का चयन करें, फिर रिटर्न करें.',
			'downloads.storageUnavailable' => 'डाउनलोड बंद हो गए क्योंकि उपलब्ध भंडारण की जांच नहीं की जा सकती थी. डाउनलोड स्थान की जांच करें, फिर वापस जाएं.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} एपिसोड डाउनलोड करने के लिए जोड़े गए',
			'downloads.downloadDeleted' => 'डाउनलोड करें हटाया',
			'downloads.deleteConfirm' => ({required Object title}) => 'इस डिवाइस से "${title}" को हटा दें?',
			'downloads.deleteCollectionDownloads' => 'डाउनलोड करें',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => 'इस डिवाइस से “${title}” के सभी डाउनलोड मिटाएँ?',
			'downloads.collectionDownloadsDeleted' => 'डाउनलोड हटाए गए',
			'downloads.cancelledDownloadTitle' => 'डाउनलोड रद्द',
			'downloads.cancelledDownloadMessage' => 'यह डाउनलोड रद्द कर दिया गया है. आप क्या करना चाहते हैं?',
			'downloads.allEpisodesAlreadyDownloaded' => 'सभी घटनाएं अब डाउनलोड की गई हैं',
			'downloads.resumeDownload' => 'डाउनलोड करें',
			'downloads.cancelledDownload' => 'डाउनलोड रद्द',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (सेंसिंग ${status})',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => 'डाउनलोड ${file} - पूरा करने के लिए क्लिक करें',
			'downloads.partialDownloadClickToComplete' => 'डाउनलोड करें - पूरा करने के लिए क्लिक करें',
			'downloads.deleting' => 'हटाने...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => '${title}... (${current} से ${total}) को हटाना',
			'downloads.queuedTooltip' => 'क्विड',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'कुल पदों की संख्या ${files}',
			'downloads.downloadingTooltip' => 'डाउनलोड...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'डाउनलोड करें ${files}',
			'downloads.noDownloadsTree' => 'कोई डाउनलोड नहीं',
			'downloads.pauseAll' => 'सबको आराम',
			'downloads.resumeAll' => 'सभी को संक्षेप में',
			'downloads.retryAll' => 'सबको वापस',
			'downloads.retryFailed' => 'असफल डाउनलोड करें',
			'downloads.deleteAll' => 'डिलीट सभी',
			'downloads.selectVersion' => 'चुनें संस्करण',
			'downloads.allEpisodes' => 'सभी प्रकरण',
			'downloads.unwatchedOnly' => 'अनदेखा केवल',
			'downloads.nextNUnwatched' => ({required Object count}) => 'अगला ${count} अनदेखा किया गया',
			'downloads.customAmount' => 'कस्टम राशि...',
			_ => null,
		} ?? switch (path) {
			'downloads.customAmountAny' => 'प्रत्येक व्यक्ति की मात्रा (प्रत्येक व्यक्ति)',
			'downloads.randomEpisodes' => 'यादृच्छिक घटनाएं',
			'downloads.includeSpecials' => 'विशेषताएं शामिल हैं',
			'downloads.howManyEpisodes' => 'कितने एपिसोड?',
			'downloads.invalidEpisodeCount' => 'एक वैध एपिसोड गिनती दर्ज करें।',
			'downloads.keepSynced' => 'सिंथेटिक रहें',
			'downloads.downloadOnce' => 'डाउनलोड करें एक बार',
			'downloads.keepNUnwatched' => ({required Object count}) => '${count} अनदेखा किया गया है',
			'downloads.editSyncRule' => 'सिंक्रनाइज़ेशन नियम',
			'downloads.removeSyncRule' => 'सिंक्रनाइज़ेशन नियम हटाएँ',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => '"${title}" सिंक्रनाइज़ करना बंद करें? डाउनलोड किए गए एपिसोड को रखा जाएगा.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => '"${title}" सिंक्रनाइज़ करना बंद करें?',
			'downloads.deleteSyncRuleDownloads' => 'साथ ही संबंधित डाउनलोड को भी हटा दें',
			'downloads.deleteSyncRuleDownloadsDescription' => 'अन्य सिंक्रनाइज़ेशन नियम या प्रोफ़ाइल द्वारा उपयोग किए गए डाउनलोड को रखा जाएगा।',
			'downloads.syncRuleCreated' => ({required Object count}) => 'सिंक्रनाइज़ेशन नियम बनाया — ${count} अनदेखा किए गए एपिसोड बनाए रखें',
			'downloads.syncRuleUpdated' => 'सिंक्रनाइज़ेशन नियम अपडेट',
			'downloads.syncRuleRemoved' => 'सिंक्रनाइज़ेशन का नियम हटा दिया गया',
			'downloads.syncRuleAndDownloadsRemoved' => 'सिंक्रनाइज़ेशन नियम और संबंधित डाउनलोड हटाए गए',
			'downloads.syncRuleCleanupBusy' => 'सिंक्रनाइज़ेशन नियम वर्तमान में अद्यतन कर रहे हैं. एक पल में फिर से कोशिश करें.',
			'downloads.syncRuleCleanupUnavailable' => 'सर्वर को फिर से कनेक्ट करें और फिर से कोशिश करें, या डाउनलोड को हटाने के बिना नियम को हटा दें।',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => '${count} के लिए नए एपिसोडों को सिंक्रनाइज़ किया गया ${title}',
			'downloads.syncNow' => 'अब सिंक्रनाइज़ेशन',
			'downloads.downloadsUpToDate' => 'डाउनलोड अभी तक जारी है',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => 'Sync complete · ${queued} queued, ${removed} हटाया गया',
			'downloads.activeSyncRules' => 'Sync नियम',
			'downloads.reviewOrphanFiles' => 'डाउनलोड करें Orphaned Downloads',
			'downloads.orphanReviewTitle' => 'डाउनलोड करें Orphaned Downloads',
			'downloads.orphanReviewDescription' => 'टैग की गई ये फ़ाइलें PlezyNG के डिफ़ॉल्ट, ऐप द्वारा प्रबंधित डाउनलोड फ़ोल्डर में हैं। इनका कोई मेल खाता डाउनलोड रिकॉर्ड या सक्रिय कार्य नहीं है। इन्हें मिटाने से पहले सूची जाँचें।',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count} फ़ाइलें · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => 'फ़ाइलों को हटाने के लिए ${count}',
			'downloads.orphanCleanupNone' => 'कोई डाउनलोड फ़ाइल नहीं मिला',
			'downloads.orphanCleanupFailed' => 'PlezyNG सुरक्षित रूप से प्रबंधित डाउनलोड फ़ोल्डर को स्कैन नहीं कर सकता. कोई फ़ाइल हटाया नहीं गया.',
			'downloads.orphanCleanupChanged' => 'डाउनलोड सूची समीक्षा के दौरान बदल गई. सफाई से पहले फ़ाइलों की समीक्षा करें.',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => 'फ़ाइलों को हटा दिया गया ${count} अनाथ · ${size} मुक्त',
			'downloads.noSyncRules' => 'कोई सिंक्रनाइज़ेशन नियम',
			'downloads.manageSyncRule' => 'सिंक्रनाइज़ेशन प्रबंधन',
			'downloads.editEpisodeCount' => 'एपिसोड गिनती',
			'downloads.editSyncFilter' => 'फ़िल्टर सिंक्रनाइज़',
			'downloads.syncAllItems' => 'सभी वस्तुओं को संकलित करें',
			'downloads.syncUnwatchedItems' => 'अनदेखा किए गए वस्तुओं को सिंक्रनाइज़ करना',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'सर्वर: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'उपलब्ध',
			'downloads.syncRuleOffline' => 'ऑफलाइन',
			'downloads.syncRuleSignInRequired' => 'जरूरत में हस्ताक्षर',
			'downloads.syncRuleAccessDenied' => 'पहुंच से इनकार',
			'downloads.syncRuleNotAvailableForProfile' => 'वर्तमान प्रोफ़ाइल के लिए उपलब्ध नहीं',
			'downloads.syncRuleUnknownServer' => 'अज्ञात सर्वर',
			'downloads.syncRuleListCreated' => 'सिंक्रनाइज़ेशन का नियम बनाया गया',
			'downloads.backgroundWarning.bannerBlocked' => 'डाउनलोड बंद हो जाएगा जब आप ऐप छोड़ देंगे',
			'downloads.backgroundWarning.bannerDegraded' => 'पृष्ठभूमि डाउनलोड सीमित हो सकते हैं',
			'downloads.backgroundWarning.bannerAction' => 'विवरण',
			'downloads.backgroundWarning.sheetTitle' => 'पृष्ठभूमि डाउनलोड ब्लॉक किया गया है',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'पृष्ठभूमि डाउनलोड सीमित हो सकते हैं',
			'downloads.backgroundWarning.sheetIntro' => 'Android पृष्ठभूमि में विश्वसनीय रूप से डाउनलोड करने से PlezyNG को रोकता है।',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'आपका डिवाइस तब सीमित है जब PlezyNG पृष्ठभूमि में डाउनलोड किया जा सकता है।',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'PlezyNG का पृष्ठभूमि उपयोग सीमित है. बैटरी या पृष्ठभूमि उपयोग को "असीमित" पर सेट करें.',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android ने PlezyNG को एक सीमित स्टैंडबी स्थिति में रखा है. बैटरी का उपयोग "असीमित" पर सेट करें.',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'डाउनलोड सूचनाएं बंद हो जाती हैं, इसलिए प्रगति और नियंत्रण उपलब्ध नहीं हो सकते हैं।',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'नोटिस बंद हो जाते हैं. Android 13 या बाद में, वे लंबी पृष्ठभूमि डाउनलोड के लिए आवश्यक हैं.',
			'downloads.backgroundWarning.reasonDataSaver' => 'डेटा सहेजने पर है, जो मोबाइल डेटा पर पृष्ठभूमि डाउनलोड ब्लॉक करता है. डाउनलोड अभी भी Wi-Fi पर चलना चाहिए.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'डाउनलोड बार-बार बंद हो गए जबकि PlezyNG पृष्ठभूमि में था. PlezyNG की बैटरी या पृष्ठभूमि उपयोग सेटिंग्स की जांच करें.',
			'downloads.backgroundWarning.openSettings' => 'खुले सेटिंग्स',
			'downloads.backgroundWarning.stillNotWorking' => 'उपकरण-विशिष्ट सहायता',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'अपने डिवाइस के लिए कदम देखें, या यदि समस्या जारी है तो सेटिंग्स › लॉग देखें से एक लॉग भेजें।',
			'downloads.backgroundWarning.dialogTitle' => 'डाउनलोड समाप्त नहीं हो सकता है',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'किसी भी तरह डाउनलोड करें',
			'downloads.backgroundWarning.dialogFixFirst' => 'इसे पहले ठीक करें',
			'downloads.backgroundWarning.statusTile' => 'पृष्ठभूमि डाउनलोड',
			'downloads.backgroundWarning.statusOk' => 'पृष्ठभूमि में चलने की अनुमति',
			'downloads.backgroundWarning.statusBlocked' => 'सिस्टम सेटिंग्स द्वारा अवरुद्ध',
			'downloads.backgroundWarning.statusDegraded' => 'सिस्टम सेटिंग्स से सीमित',
			'downloads.backgroundWarning.statusUnknown' => 'अभी तक जांच नहीं',
			'downloads.backgroundWarning.settingsUnavailable' => 'इस डिवाइस पर सिस्टम सेटिंग्स नहीं खोला जा सकता',
			'downloads.backgroundWarning.linkUnavailable' => 'इस डिवाइस पर dontkillmyapp.com नहीं खोला जा सकता',
			'downloads.options' => 'डाउनलोड विकल्प',
			'downloads.groupings.library' => 'लाइब्रेरी',
			'downloads.groupings.collections' => 'संग्रह',
			'downloads.unknownLibrary' => 'अज्ञात पुस्तकालय',
			'downloads.unknownShow' => 'अज्ञात शो',
			'downloads.unknownSeason' => 'अज्ञात मौसम',
			'downloads.unknownAlbum' => 'अज्ञात एल्बम',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} पूरा हो गया',
			'downloads.storageUsed' => ({required Object size}) => 'उपयोग किए गए भंडारण: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} डाउनलोड करें', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} डाउनलोड करें', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} प्रदर्शित करें', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} प्रदर्शित करें', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} फिल्में', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} फ़िल्में', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} एल्बम', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} एल्बम', ), 
			'downloads.errorFileNotFound' => 'फ़ाइल नहीं मिला (404)',
			'downloads.errorDownloadNotAllowed' => 'सर्वर द्वारा अनुमति नहीं दी गई डाउनलोड (403)',
			'downloads.errorDownloadFailed' => 'डाउनलोड असफल',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'डाउनलोड विफल: ${reason}',
			'downloads.convertingOnServer' => 'सर्वर पर स्थानांतरित करने के लिए ...',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => 'सर्वर पर रूपांतरण · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => 'डाउनलोड असफल (HTTP ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => 'प्रसंस्करण के बाद विफलता: ${reason}',
			'downloads.reasonFileNotSaved' => 'फ़ाइल को इस डिवाइस पर नहीं बचाया जा सकता है',
			'downloads.reasonCannotResume' => 'आंशिक डाउनलोड को फिर से नहीं किया जा सकता है',
			'downloads.reasonDeviceStorageFull' => 'यह डिवाइस भंडारण से बाहर है',
			'downloads.notificationDownloading' => 'डाउनलोड...',
			'downloads.notificationComplete' => 'डाउनलोड करें पूर्ण',
			'downloads.notificationPaused' => 'डाउनलोड करें ब्रेक',
			'shaders.title' => 'छाया',
			'shaders.noShaderDescription' => 'कोई वीडियो सुधार नहीं',
			'shaders.nvscalerDescription' => 'अधिक तेज वीडियो के लिए NVIDIA छवि स्केलिंग',
			'shaders.artcnnVariantNeutral' => 'तटस्थ',
			'shaders.artcnnVariantDenoise' => 'डेंगू',
			'shaders.artcnnVariantDenoiseSharpen' => 'डेंगू + शार्पन',
			'shaders.qualityFast' => 'जल्दी',
			'shaders.qualityHQ' => 'उच्च गुणवत्ता',
			'shaders.mode' => 'फैशन',
			'shaders.importShader' => 'आयात शेर',
			'shaders.customShaderDescription' => 'कस्टम GLSL शैडर',
			'shaders.shaderImported' => 'शेर आयात',
			'shaders.shaderImportFailed' => 'शेर का आयात करने में विफलता',
			'shaders.deleteShader' => 'Shader को हटा दें',
			'shaders.deleteShaderConfirm' => ({required Object name}) => '"${name}" को हटाने के लिए?',
			'companionRemote.title' => 'सहायक रिमोट',
			'companionRemote.connectedTo' => ({required Object name}) => '${name} पर कनेक्ट करें',
			'companionRemote.unknownDevice' => 'अज्ञात डिवाइस',
			'companionRemote.session.startingServer' => 'दूरस्थ सर्वर से शुरू करें',
			'companionRemote.session.hostAddress' => 'मेजबान का पता',
			'companionRemote.session.connected' => 'कनेक्ट',
			'companionRemote.session.serverRunning' => 'Remote Server सक्रिय',
			'companionRemote.session.serverStopped' => 'दूरस्थ सर्वर बंद',
			'companionRemote.session.serverRunningDescription' => 'आपके नेटवर्क पर मोबाइल उपकरण इस ऐप से कनेक्ट कर सकते हैं',
			'companionRemote.session.serverStoppedDescription' => 'सर्वर शुरू करें ताकि मोबाइल उपकरणों को कनेक्ट करने की अनुमति मिल सके',
			'companionRemote.session.usePhoneToControl' => 'इस एप्लिकेशन को नियंत्रित करने के लिए अपने मोबाइल डिवाइस का उपयोग करें',
			'companionRemote.session.startServer' => 'सर्वर शुरू करें',
			'companionRemote.session.stopServer' => 'सर्वर बंद करें',
			'companionRemote.session.minimize' => 'कम से कम',
			'companionRemote.session.manualAddressHint' => 'मैनुअल कनेक्शन पता:',
			'companionRemote.pairing.discoveryDescription' => 'PlezyNG उपकरणों के साथ एक ही Plex खाता यहाँ दिखाई देता है',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'कनेक्ट...',
			'companionRemote.pairing.searchingForDevices' => 'उपकरणों की तलाश में...',
			'companionRemote.pairing.noDevicesFound' => 'आपके नेटवर्क पर कोई उपकरण नहीं मिला',
			'companionRemote.pairing.noDevicesHint' => 'डेस्कटॉप पर PlezyNG खोलें और उसी Wi-Fi का उपयोग करें',
			'companionRemote.pairing.availableDevices' => 'उपलब्ध उपकरण',
			'companionRemote.pairing.manualConnection' => 'मैनुअल कनेक्शन',
			'companionRemote.pairing.cryptoInitFailed' => 'सुरक्षित कनेक्शन शुरू नहीं किया जा सकता. पहले Plex पर साइन इन करें.',
			'companionRemote.pairing.validationHostRequired' => 'कृपया होस्ट एड्रेस दर्ज करें',
			'companionRemote.pairing.validationHostFormat' => 'प्रारूप IP:port होना चाहिए (उदाहरण के लिए, 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'दोनों उपकरणों पर एक ही नेटवर्क का उपयोग करें।',
			'companionRemote.pairing.sessionNotFound' => 'डिवाइस नहीं मिला. सुनिश्चित करें कि PlezyNG होस्ट पर चल रहा है.',
			'companionRemote.pairing.authFailed' => 'दोनों डिवाइसों को एक ही Plex खाता की आवश्यकता होती है।',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'कनेक्ट करने में विफल: ${error}',
			'companionRemote.pairing.codeTitle' => 'जोड़े कोड',
			'companionRemote.pairing.codeDescription' => 'होस्ट डिवाइस पर Companion Remote में दिखाए गए कोड दर्ज करें. दोनों डिवाइसों को एक संस्करण का उपयोग करना होगा जो सुरक्षित जोड़ का समर्थन करता है.',
			'companionRemote.pairing.codeInvalid' => 'होस्ट कोड से सभी 32 अक्षरों और संख्याओं को दर्ज करें।',
			'companionRemote.pairing.updateRequired' => 'दोनों डिवाइसों को एक संस्करण में अपडेट करें जो सुरक्षित जोड़ का समर्थन करता है।',
			'companionRemote.pairing.hostDescription' => 'प्रत्येक रिमोट पर एक बार इस कोड दर्ज करें. इसे गोपनीय रखें: यह इस प्रोफ़ाइल का नियंत्रण प्रदान करता है.',
			'companionRemote.pairing.resetCode' => 'पुन: पेरिंग कोड',
			'companionRemote.pairing.resetDescription' => 'सभी रिमोट्स को कनेक्ट करें और एक नया कोड बनाएं. प्रत्येक रिमोट को फिर से जोड़ने की आवश्यकता होगी.',
			'companionRemote.remote.disconnectConfirm' => 'क्या आप दूरस्थ सत्र से कनेक्ट करना चाहते हैं?',
			'companionRemote.remote.reconnecting' => 'फिर से कनेक्ट...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'अनुच्छेद ${current} में से 5',
			'companionRemote.remote.retryNow' => 'अब वापस',
			'companionRemote.remote.tabRemote' => 'दूर',
			'companionRemote.remote.tabPlay' => 'खेलना',
			'companionRemote.remote.tabMore' => 'अधिक',
			'companionRemote.remote.menu' => 'मेनू',
			'companionRemote.remote.tabNavigation' => 'टैब नेविगेशन',
			'companionRemote.remote.tabDiscover' => 'खोजें',
			'companionRemote.remote.tabLibraries' => 'पुस्तकालय',
			'companionRemote.remote.tabSearch' => 'खोज',
			'companionRemote.remote.tabDownloads' => 'डाउनलोड',
			'companionRemote.remote.tabSettings' => 'सेटिंग्स',
			'companionRemote.remote.previous' => 'पिछला',
			'companionRemote.remote.playPause' => 'खेल / आराम',
			'companionRemote.remote.next' => 'अगला',
			'companionRemote.remote.seekBack' => 'वापस खोजें',
			'companionRemote.remote.stop' => 'रोकें',
			'companionRemote.remote.seekForward' => 'FWD की खोज',
			'companionRemote.remote.volume' => 'वॉल्यूम',
			'companionRemote.remote.volumeDown' => 'नीचे',
			'companionRemote.remote.volumeUp' => 'ऊपर',
			'companionRemote.remote.fullscreen' => 'पूर्ण स्क्रीन',
			'companionRemote.remote.subtitles' => 'उपशीर्षक',
			'companionRemote.remote.audio' => 'ऑडियो',
			'companionRemote.remote.searchHint' => 'डेस्कटॉप पर खोज...',
			'companionRemote.errors.noNetworkInterface' => 'कोई नेटवर्क इंटरफ़ेस नहीं मिला',
			'companionRemote.errors.authenticationFailed' => 'असफलता की पुष्टि',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'रिमोट सर्वर शुरू करने में विफलता: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'दूरस्थ कमांड भेजने में विफलता: ${error}',
			'companionRemote.errors.joinTimedOut' => 'सत्र में शामिल होने के लिए समय',
			'companionRemote.errors.failedToConnectAnyAddress' => 'किसी भी पते से कनेक्ट करने में असमर्थ',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => '${attempts} प्रयासों के बाद कनेक्शन खो गया',
			'companionRemote.errors.connectionLost' => 'कनेक्शन खो गया',
			'companionRemote.closedBeforeAuth' => 'पहचान से पहले कनेक्शन बंद',
			'videoSettings.playbackSpeed' => 'Playback गति',
			'videoSettings.normalSpeed' => 'सामान्य',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'सक्रिय (${duration})',
			'videoSettings.zoom' => 'ज़ूम',
			'videoSettings.sleepTimer' => 'नींद का समय',
			'videoSettings.audioSync' => 'ऑडियो सिंक्रनाइज़ेशन',
			'videoSettings.subtitleSync' => 'Subtitle सिंक्रनाइज़',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'HDR यहाँ उपलब्ध नहीं है - यह डेस्कटॉप कॉम्प्लेटर या वीडियो आउटपुट इसे ले जाने में सक्षम नहीं है।',
			'videoSettings.hdrToneMapping' => 'HDR टोन मैपिंग',
			'videoSettings.hdrToneMappingCompositor' => 'रचनाकार',
			'videoSettings.hdrToneMappingCompositorDescription' => 'स्रोत के एचडीआर मेटाडेटा के माध्यम से गुजरें और डेस्कटॉप कॉम्प्लेटर के नक्शे को छोड़ दें।',
			'videoSettings.hdrToneMappingPlayer' => 'प्लेयर',
			'videoSettings.hdrToneMappingPlayerDescription' => 'प्लेयर में डिस्प्ले की चोटी चमक के लिए नक्शा, फिर संगीतकार को परिणाम बताएं।',
			'videoSettings.hdrToneMappingFailed' => 'HDR टोन मैपिंग नहीं बदल सकता था - पिछले मोड अभी भी सक्रिय है।',
			'videoSettings.audioOutput' => 'ऑडियो आउटपुट',
			'videoSettings.performanceOverlay' => 'प्रदर्शन ओवरले',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'आसपास',
			'videoSettings.audioOutputSpatial' => 'अंतरिक्ष ऑडियो',
			'videoSettings.audioOutputStereo' => 'स्टेनलेस',
			'videoSettings.audioEqualizer' => 'ऑडियो इक्वाइज़र',
			'videoSettings.audioEqualizerDescription' => 'इस डिवाइस के लिए पांच आवृत्ति बैंड को समायोजित करें. mpv पर उपलब्ध; एक सक्रिय EQ ऑडियो को डिकोड करता है और फिस्टह्रो को अक्षम करता है.',
			'videoSettings.audioEqualizerFlat' => 'फ्लैट',
			'videoSettings.audioEqualizerActive' => 'कस्टम',
			'videoSettings.audioEqualizerSaveFailed' => 'ऑडियो इक्वालिज़र सेटिंग्स को बचाने में सक्षम नहीं था।',
			'videoSettings.backgroundVideoAudio' => 'पृष्ठभूमि Video Audio',
			'videoSettings.backgroundVideoAudioDescription' => 'जब आप प्लेयर छोड़ देते हैं तो वीडियो ऑडियो खेलना बनाए रखें; तस्वीर वापस आने तक छिपी हुई है. Android एक मीडिया प्लेबैक नोटिस का उपयोग करता है.',
			'videoSettings.audioNormalization' => 'ध्वनि को सामान्य करें',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'पीसीएम में ऑडियो डिकोड करें; passthrough बंद हो जाता है जबकि यह',
			'performanceOverlay.color' => 'रंग',
			'performanceOverlay.performance' => 'प्रदर्शन',
			'performanceOverlay.buffer' => 'बफर',
			'performanceOverlay.app' => 'एप्लिकेशन',
			'performanceOverlay.decoder' => 'डिकोडर',
			'performanceOverlay.rawDecoder' => 'रेड डिकोडर',
			'performanceOverlay.tunneling' => 'टनल',
			'performanceOverlay.passthrough' => 'पश्चाताप',
			'performanceOverlay.aspect' => 'दृष्टि',
			'performanceOverlay.rotation' => 'रोटेशन',
			'performanceOverlay.dvSource' => 'डीवी स्रोत',
			'performanceOverlay.dvPath' => 'डीवी मार्ग',
			'performanceOverlay.dvRouteDecoder' => 'Dolby Vision डिकोडर',
			'performanceOverlay.dvRouteDecoderP81' => 'Dolby Vision डिकोडर (P7→8.1)',
			'performanceOverlay.dvRouteBaseLayer' => 'बेस लेयर',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'HDR10 आधार परत',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'HLG आधार परत',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'एसडीआर आधार परत',
			'performanceOverlay.dvRouteReshaped' => 'आरपीयू पुनर्प्राप्त (जीपीयू-अगला)',
			'performanceOverlay.p7Conversion' => 'पी 7 कॉन्फ',
			'performanceOverlay.sampleRate' => 'नमूना दर',
			'performanceOverlay.pixelFormat' => 'पिक्सेल Fmt',
			'performanceOverlay.hwFormat' => 'एफएमटी',
			'performanceOverlay.matrix' => 'मैट्रिक्स',
			'performanceOverlay.primaries' => 'प्राथमिकताएं',
			'performanceOverlay.transfer' => 'स्थानांतरण',
			'performanceOverlay.renderFps' => 'एफपीएस',
			'performanceOverlay.displayFps' => 'FPS प्रदर्शित करें',
			'performanceOverlay.avSync' => 'A/V सिंक्रनाइज़ेशन',
			'performanceOverlay.dropped' => 'टूट गया',
			'performanceOverlay.dvRpus' => 'डीवी आरपीयू',
			'performanceOverlay.dvRpuAverage' => 'डीवी आरपीयू AVG',
			'performanceOverlay.dvSampleAverage' => 'डीवी नमूना AVG',
			'performanceOverlay.maxLuma' => 'मैक्स लूमा',
			'performanceOverlay.minLuma' => 'लूमा',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'कैश का इस्तेमाल',
			'performanceOverlay.cacheLimit' => 'Cache सीमा',
			'performanceOverlay.speed' => 'गति',
			'performanceOverlay.player' => 'प्लेयर',
			'performanceOverlay.playMethod' => 'खेलने का तरीका',
			'performanceOverlay.memory' => 'स्मृति',
			'performanceOverlay.uiFps' => 'एफपीएस',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android एचडब्ल्यू',
			'performanceOverlay.decoderNvidiaHw' => 'NVIDIA HW के बारे में',
			'performanceOverlay.decoderQualcommHw' => 'क्लॉम HW',
			'performanceOverlay.decoderMediatekHw' => 'मीडिया एचएच',
			'performanceOverlay.decoderExynosHw' => 'एक्सिनोस एचड',
			'performanceOverlay.decoderSoftware' => 'सॉफ्टवेयर',
			'performanceOverlay.decoderHardware' => 'हार्डवेयर',
			'performanceOverlay.tunnelingActive' => 'सक्रिय',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted} (${failures} असफल)',
			'externalPlayer.title' => 'बाहरी खिलाड़ी',
			'externalPlayer.useExternalPlayer' => 'बाहरी खिलाड़ी का उपयोग करें',
			'externalPlayer.useExternalPlayerDescription' => 'एक और ऐप में वीडियो खोलना',
			'externalPlayer.selectPlayer' => 'खिलाड़ी चुनें',
			'externalPlayer.customPlayers' => 'Custom खिलाड़ी',
			'externalPlayer.systemDefault' => 'डिफ़ॉल्ट सिस्टम',
			'externalPlayer.addCustomPlayer' => 'कस्टम प्लेयर',
			'externalPlayer.playerName' => 'खिलाड़ी का नाम',
			'externalPlayer.playerNameHint' => 'मेरे खिलाड़ी',
			'externalPlayer.playerCommand' => 'कमांड',
			'externalPlayer.playerPackage' => 'पैकेज नाम',
			'externalPlayer.playerUrlScheme' => 'URL योजना',
			'externalPlayer.off' => 'बंद करें',
			'externalPlayer.launchFailed' => 'बाहरी खिलाड़ी खोलने में विफलता',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} स्थापित नहीं किया गया',
			'externalPlayer.playInExternalPlayer' => 'बाहरी खिलाड़ी में खेलना',
			'metadataEdit.editMetadata' => 'संपादित करें...',
			'metadataEdit.screenTitle' => 'मेटाडेटा संपादन',
			'metadataEdit.basicInfo' => 'बुनियादी जानकारी',
			'metadataEdit.artwork' => 'कला कार्य',
			'metadataEdit.advancedSettings' => 'उन्नत सेटिंग्स',
			'metadataEdit.title' => 'शीर्षक',
			'metadataEdit.sortTitle' => 'शीर्षक का चयन करें',
			'metadataEdit.originalTitle' => 'मूल शीर्षक',
			'metadataEdit.releaseDate' => 'रिलीज की तारीख',
			'metadataEdit.contentRating' => 'सामग्री रेटिंग',
			'metadataEdit.studio' => 'स्टूडियो',
			'metadataEdit.tagline' => 'संक्षिप्त परिचय',
			'metadataEdit.summary' => 'संक्षेप में',
			'metadataEdit.poster' => 'पोस्टर',
			'metadataEdit.background' => 'पृष्ठभूमि',
			'metadataEdit.logo' => 'लोगो',
			'metadataEdit.squareArt' => 'Square कला',
			'metadataEdit.selectPoster' => 'पोस्टर चुनें',
			'metadataEdit.selectBackground' => 'पृष्ठभूमि चुनें',
			'metadataEdit.selectLogo' => 'लॉग चुनें',
			'metadataEdit.selectSquareArt' => 'Square Art का चयन करें',
			'metadataEdit.fromUrl' => 'URL से',
			'metadataEdit.uploadFile' => 'फ़ाइल अपलोड करें',
			'metadataEdit.enterImageUrl' => 'इमेज URL',
			'metadataEdit.imageUrl' => 'इमेज URL',
			'metadataEdit.metadataUpdated' => 'मेटाडेटा अपडेट',
			'metadataEdit.metadataUpdateFailed' => 'मेटाडेटा अपडेट करने में असफल',
			'metadataEdit.artworkUpdated' => 'Artwork अद्यतन',
			'metadataEdit.artworkUpdateFailed' => 'कला के काम को अपडेट करने में विफलता',
			'metadataEdit.noArtworkAvailable' => 'कोई कला उपलब्ध नहीं है',
			'metadataEdit.artworkOption' => ({required Object index}) => 'आर्टवर्क विकल्प ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'आर्टवर्क विकल्प ${index}, चुना गया',
			'metadataEdit.notSet' => 'सेट नहीं',
			'metadataEdit.libraryDefault' => 'लाइब्रेरी अभाव',
			'metadataEdit.accountDefault' => 'अकाउंट डिफ़ॉल्ट',
			'metadataEdit.seriesDefault' => 'श्रृंखला डिफ़ॉल्ट',
			'metadataEdit.episodeSorting' => 'एपिसोड सेटअप',
			'metadataEdit.oldestFirst' => 'सबसे पुराना पहले',
			'metadataEdit.newestFirst' => 'नवीनतम प्रथम',
			'metadataEdit.keep' => 'रखें',
			'metadataEdit.allEpisodes' => 'सभी प्रकरण',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} नवीनतम एपिसोड',
			'metadataEdit.latestEpisode' => 'अंतिम एपिसोड',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'पिछले ${count} दिनों में जोड़े गए घटनाएँ',
			'metadataEdit.deleteAfterPlaying' => 'खेलने के बाद एपिसोड को हटा दें',
			'metadataEdit.never' => 'कभी नहीं',
			'metadataEdit.afterADay' => 'एक दिन के बाद',
			'metadataEdit.afterAWeek' => 'एक सप्ताह के बाद',
			'metadataEdit.afterAMonth' => 'एक महीने के बाद',
			'metadataEdit.onNextRefresh' => 'अगले रिफ्रेश',
			'metadataEdit.seasons' => 'मौसम',
			'metadataEdit.show' => 'शो',
			'metadataEdit.hide' => 'छिपाना',
			'metadataEdit.episodeOrdering' => 'एपिसोड ऑर्डर',
			'metadataEdit.tmdbAiring' => 'फिल्म डेटाबेस (Aired)',
			'metadataEdit.tvdbAiring' => 'टीवीडीबी (एरिड)',
			'metadataEdit.tvdbAbsolute' => 'टीवीडीबी (असफल)',
			'metadataEdit.metadataLanguage' => 'मेटाडेटा भाषा',
			'metadataEdit.useOriginalTitle' => 'मूल शीर्षक का उपयोग करें',
			'metadataEdit.preferredAudioLanguage' => 'ऑडियो भाषा की पसंद',
			'metadataEdit.preferredSubtitleLanguage' => 'Subtitle भाषा के बारे में',
			'metadataEdit.subtitleMode' => 'Auto-Select Subtitle मोड का चयन करें',
			'metadataEdit.manuallySelected' => 'मैन्युअल रूप से चुने गए',
			'metadataEdit.shownWithForeignAudio' => 'विदेशी ऑडियो के साथ प्रदर्शित',
			'metadataEdit.alwaysEnabled' => 'हमेशा सक्षम',
			'metadataEdit.tags' => 'टैग',
			'metadataEdit.addTag' => 'टैग जोड़ें',
			'metadataEdit.genre' => 'जीन',
			'metadataEdit.director' => 'निर्देशक',
			'metadataEdit.writer' => 'लेखक',
			'metadataEdit.producer' => 'निर्माता',
			'metadataEdit.country' => 'देश',
			'metadataEdit.collection' => 'संग्रह',
			'metadataEdit.label' => 'लेबल',
			'metadataEdit.quickTag' => 'त्वरित टैग...',
			'matchScreen.match' => 'मैच...',
			'matchScreen.fixMatch' => 'फिक्स मैच...',
			'matchScreen.unmatch' => 'असंगत',
			'matchScreen.unmatchConfirm' => 'इस मैच को स्पष्ट करें? Plex इसे समाप्त होने तक असंगत के रूप में व्यवहार करता है।',
			'matchScreen.unmatchSuccess' => 'असंगत आइटम',
			'matchScreen.unmatchFailed' => 'असफलता से अनमोलता',
			'matchScreen.matchApplied' => 'मैच लागू',
			'matchScreen.matchFailed' => 'मैच में असफलता',
			'matchScreen.titleHint' => 'शीर्षक',
			'matchScreen.yearHint' => 'वर्ष',
			'matchScreen.search' => 'खोज',
			'matchScreen.noMatchesFound' => 'कोई मैच नहीं मिला',
			'serverTasks.title' => 'सर्वर कार्य',
			'serverTasks.failedToLoad' => 'कार्यों को लोड करने में विफलता',
			'serverTasks.noTasks' => 'कोई कार्य नहीं चल रहा है',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'कनेक्ट',
			'trakt.connectedAs' => ({required Object username}) => '@${username} के रूप में कनेक्ट',
			'trakt.disconnectConfirm' => 'Trakt खाते से कनेक्ट करें?',
			'trakt.disconnectConfirmBody' => 'PlezyNG Trakt पर घटनाओं को भेजना बंद कर देगा. आप किसी भी समय फिर से कनेक्ट कर सकते हैं.',
			'trakt.scrobble' => 'वास्तविक समय स्क्रबबलिंग',
			'trakt.scrobbleDescription' => 'प्लेबैक के दौरान प्लेबैक, ब्रेक, और स्टॉप घटनाओं को Trakt पर भेजें।',
			'trakt.watchedSync' => 'सिंक्रनाइज़ेशन की स्थिति',
			'trakt.watchedSyncDescription' => 'जब आप PlezyNG में देखे गए आइटम को चिह्नित करते हैं, तो वे Trakt में देखे गए आइटम को भी चिह्नित करते हैं।',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'कनेक्ट करें Seerr',
			'seerr.serverUrl' => 'सर्वर URL',
			'seerr.serverUrlHelper' => 'आपके सीरियर के संदर्भ का पता',
			'seerr.checkServer' => 'जारी है',
			'seerr.signInWithJellyfin' => 'Jellyfin के साथ साइन इन करें',
			'seerr.signInWithEmby' => 'Emby के साथ साइन इन करें',
			'seerr.signInWithLocal' => 'एक स्थानीय खाता का उपयोग करें',
			'seerr.email' => 'ईमेल',
			'seerr.noSignInMethods' => 'यह Seerr उदाहरण कोई साइन इन विधि PlezyNG समर्थन प्रदान नहीं करता है।',
			'seerr.instance' => 'उदाहरण',
			'seerr.disconnectConfirm' => 'कनेक्ट हो जाओ?',
			'seerr.disconnectConfirmBody' => 'PlezyNG इस Seerr उदाहरण को भूल जाएगा. किसी भी समय फिर से कनेक्ट करें.',
			'seerr.request' => 'अनुरोध',
			'seerr.request4k' => '4K में अनुरोध',
			'seerr.seasons' => 'मौसम',
			'seerr.allSeasons' => 'सभी मौसम',
			'seerr.advancedOptions' => 'उन्नत',
			'seerr.destinationServer' => 'Destination सर्वर',
			'seerr.qualityProfile' => 'गुणवत्ता प्रोफ़ाइल',
			'seerr.rootFolder' => 'रूट फ़ोल्डर',
			'seerr.languageProfile' => 'भाषा प्रोफ़ाइल',
			'seerr.tags' => 'टैग',
			'seerr.noTags' => 'कोई टैग नहीं',
			'seerr.defaultOption' => ({required Object name}) => '${name} (वैकल्पिक)',
			'seerr.animeNote' => 'यह श्रृंखला एक एनीम है।',
			'seerr.requestSubmitted' => 'अनुरोध प्रस्तुत',
			'seerr.requestFailed' => ({required Object error}) => 'अनुरोध विफल: ${error}',
			'seerr.requestsLoadFailed' => 'अनुरोध विकल्पों को लोड नहीं किया जा सकता',
			'seerr.nothingToRequest' => 'सब कुछ पहले से ही उपलब्ध है या अनुरोध किया गया है।',
			'seerr.statusAvailable' => 'उपलब्ध',
			'seerr.statusPartiallyAvailable' => 'आंशिक उपलब्ध',
			'seerr.statusRequested' => 'अनुरोध',
			'seerr.statusProcessing' => 'प्रसंस्करण',
			'seerr.statusBlocklisted' => 'ब्लॉकअप',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => '${url}: ${error} तक नहीं पहुंच सकता',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => '${url} (HTTP ${status}) पर कोई Seerr मामला नहीं',
			'seerr.behindAuthProxy' => 'एक सत्यापित विपरीत प्रॉक्सी (एसएसओ या HTTP auth) ने Seerr के बजाय जवाब दिया. PlezyNG इसके माध्यम से साइन इन नहीं कर सकता: Seerr के /api/v1 मार्ग को इस एप्लिकेशन के लिए प्रॉक्सी पार कर दें, या एक पता का उपयोग करें जो सीधे Seerr तक पहुंचता है.',
			'seerr.invalidUrl' => 'एक सर्वर पता दर्ज करें जैसे https://seerr.example.com',
			'seerr.quickConnectUnsupported' => 'इस Seerr उदाहरण का समर्थन नहीं करता Quick Connect. यह Seerr 3.4 या उससे अधिक की आवश्यकता है.',
			'seerr.notInitialized' => 'यह Seerr उदाहरण पहली बार चलने वाले सेटअप को पूरा नहीं करता है',
			'seerr.noPlexTokenForReauth' => 'नंबर Plex टोकन फिर से साइन अप करने के लिए उपलब्ध है',
			'seerr.noStoredCredentials' => 'फिर से साइन इन करने के लिए कोई सहेजी हुई साइन-इन जानकारी उपलब्ध नहीं है',
			'seerr.signInRejected' => 'Sign-in को अस्वीकार कर दिया गया',
			'seerr.noSessionCookie' => 'Seerr ने कोई सत्र कुकी जारी नहीं की',
			'seerr.freshCookieRejected' => 'Seerr ने नए सत्र कुकी को खारिज कर दिया',
			'seerr.noUserInformation' => 'Seerr ने उपयोगकर्ता जानकारी वापस नहीं की',
			'seerr.sessionRejectedAfterReauth' => 'फिर से हस्ताक्षर करने के बाद बैठक को अस्वीकार कर दिया गया',
			'seerr.permissionDenied' => 'Seerr ने इस कार्रवाई को अस्वीकार कर दिया: आपके खाते में अब आवश्यक अनुमति नहीं है',
			'seerr.permissionRevoked' => 'अब आपके पास यह अनुरोध करने की अनुमति नहीं है',
			'services.title' => 'सेवाएं',
			'services.hubSubtitle' => 'सिंक्रनाइज़ेशन प्रगति की निगरानी करता है और नए शीर्षकों की मांग करता है।',
			'services.integrations' => 'एकीकरण',
			'services.notConnected' => 'नहीं जुड़े',
			'services.connectedAs' => ({required Object username}) => '@${username} के रूप में कनेक्ट',
			'services.scrobble' => 'प्रगति को स्वचालित रूप से ट्रैक करें',
			'services.scrobbleDescription' => 'जब आप एक एपिसोड या फिल्म खत्म करते हैं तो अपनी सूची को अपडेट करें।',
			'services.disconnectConfirm' => ({required Object service}) => 'कनेक्ट करें ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'PlezyNG किसी भी समय पुनः कनेक्ट करें. ${service} को अपडेट करना बंद कर दिया जाएगा.',
			'services.connectFailed' => ({required Object service}) => '${service} पर कनेक्ट नहीं किया जा सकता।',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'पुनः कनेक्ट Simkl',
			'services.simklReconnect.subtitle' => 'Simkl इस कनेक्शन का उपयोग करने के लिए साइन इन विधि को हटा रहा है. पुन: कनेक्ट करने के लिए simkl.com को अनुमोदित करने के लिए खुलता है PlezyNG — PlezyNG कभी भी अपना पासवर्ड नहीं देखता है. आपका घड़ी इतिहास Simkl पर रहता है.',
			'services.deviceCode.title' => ({required Object service}) => 'PlezyNG पर ${service} को सक्रिय करें',
			'services.deviceCode.instructions' => 'QR कोड स्कैन करें, या नीचे दिए गए पते पर जाएं और इस कोड को दर्ज करें:',
			'services.deviceCode.openToActivate' => ({required Object service}) => '${service} को सक्रिय करने के लिए खोलें',
			'services.deviceCode.copyCode' => 'सक्रियण कोड को कॉपी करें',
			'services.deviceCode.waitingForAuthorization' => 'अनुमति के लिए इंतजार...',
			'services.deviceCode.codeCopied' => 'कोड कॉपी करें',
			'services.oauthProxy.title' => ({required Object service}) => '${service} पर साइन इन करें',
			'services.oauthProxy.body' => 'इस QR कोड को स्कैन करें या किसी भी डिवाइस पर URL खोलें।',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => '${service} पर हस्ताक्षर करने के लिए खोलें',
			'services.pendingAuth.copyUrl' => 'साइन-इन URL को कॉपी करें',
			'services.pendingAuth.urlCopied' => 'URL को कॉपी करें',
			'services.libraryFilter.title' => 'पुस्तकालय फ़िल्टर',
			'services.libraryFilter.subtitleAllSyncing' => 'सभी पुस्तकालयों को संकलित करें',
			'services.libraryFilter.subtitleNoneSyncing' => 'कोई सिंथेटिक नहीं',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} अवरुद्ध',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} अनुमति',
			'services.libraryFilter.mode' => 'फ़िल्टर मोड',
			'services.libraryFilter.modeBlacklist' => 'काला सूची में डालना',
			'services.libraryFilter.modeWhitelist' => 'सफेद',
			'services.libraryFilter.modeHintBlacklist' => 'प्रत्येक पुस्तकालय को सिंक्रनाइज़ करें, नीचे देखे गए पुस्तकालयों को छोड़कर।',
			'services.libraryFilter.modeHintWhitelist' => 'केवल नीचे की जांच की गई पुस्तकालयों को सिंक्रनाइज़ करें।',
			'services.libraryFilter.libraries' => 'पुस्तकालय',
			'services.libraryFilter.noLibraries' => 'कोई पुस्तकालय उपलब्ध नहीं',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => '${product} सर्वर जोड़ें',
			'addServer.serverUrls' => 'सर्वर URL',
			'addServer.serverUrlsHelper' => 'कई यूआरएल अनुमति दी जाती है, कॉम्मा द्वारा अलग किया जाता है।',
			'addServer.findServer' => 'सर्वर खोजें',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'स्थानीय ${product} सर्वरों की तलाश में ...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'स्थानीय सर्वर ${product}',
			'addServer.username' => 'उपयोगकर्ता नाम',
			'addServer.password' => 'पासवर्ड',
			'addServer.signIn' => 'साइन इन',
			'addServer.change' => 'बदलाव',
			'addServer.required' => 'जरूरी',
			'addServer.couldNotReachServer' => ({required Object error}) => 'सर्वर तक नहीं पहुंच सकता: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'हस्ताक्षर विफल: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect असफल: ${error}',
			'addServer.addPlexTitle' => 'Plex के साथ साइन इन करें',
			'addServer.pinExpired' => 'पिन लॉग इन करने से पहले समाप्त हो गया है. कृपया फिर से कोशिश करें.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'अकाउंट रजिस्टर करने में विफल: ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => 'अपने ${product} सर्वर URL दर्ज करें',
			'addServer.addConnectionTitle' => 'कनेक्शन जोड़ें',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => '${name} पर जोड़ें',
			'addServer.signInWithPlexCard' => 'Plex के साथ साइन इन करें',
			'addServer.signInWithPlexCardSubtitle' => 'इस डिवाइस को अनुमति दें. साझा सर्वर जोड़े जाते हैं.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'एक Plex खाता सक्षम करें. होम उपयोगकर्ता प्रोफ़ाइल बन जाते हैं.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => 'कनेक्ट करें ${product}',
			'addServer.connectToMediaBrowserCardSubtitle' => 'अपने सर्वर URL, उपयोगकर्ता नाम और पासवर्ड दर्ज करें।',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => 'अपने सर्वर ${product} पर साइन इन करें. ${name} पर लिंक करें.',
			'addServer.borrowFromAnotherProfile' => 'एक और प्रोफ़ाइल से ऋण',
			'addServer.borrowFromAnotherProfileSubtitle' => 'एक और प्रोफ़ाइल कनेक्शन का पुन: उपयोग करें. PIN-सुरक्षित प्रोफ़ाइलों को एक PIN की आवश्यकता होती है.',
			'addServer.invalidCredentials' => 'अक्षम उपयोगकर्ता नाम या पासवर्ड',
			'addServer.authResponseNotJson' => 'सत्यापन प्रतिक्रिया वैध नहीं थी JSON',
			'addServer.authResponseIncomplete' => 'सर्वर से साइन-इन प्रतिक्रिया अपूर्ण थी',
			'addServer.quickConnectRejected' => 'Quick Connect सर्वर द्वारा अस्वीकार कर दिया गया था',
			'addServer.quickConnectNotJson' => 'Quick Connect जवाब JSON वैध नहीं था',
			_ => null,
		} ?? switch (path) {
			'addServer.quickConnectMissingFields' => 'Quick Connect का जवाब एक कोड या रहस्य की कमी है',
			'addServer.quickConnectPollRejected' => 'Quick Connect पूछताछ सर्वर द्वारा अस्वीकार कर दिया गया था',
			'addServer.serverTimedOut' => 'सर्वर ने समय पर जवाब नहीं दिया',
			'addServer.responseNotJson' => 'सर्वर प्रतिक्रिया वैध नहीं थी JSON',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'जवाब एक आईडी या सर्वर नाम की कमी है - क्या यह एक सर्वर ${product} है?',
			'addServer.probeFailed' => ({required Object error}) => 'सर्वर तक नहीं पहुंच सकता: ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => 'कम से कम एक ${product} सर्वर URL दर्ज करें',
			'addServer.noReachableServer' => ({required Object product}) => 'कोई पहुंच योग्य सर्वर ${product} नहीं मिला',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'ये URL अलग-अलग ${product} सर्वरों को संदर्भित करते हैं',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'यह URL ${product} सर्वर के अनुरूप नहीं है',
			'addServer.redirectUnsupported' => 'सर्वर को एक असहाय URL के लिए रीरेक्ट किया गया है',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'सर्वर को एक अलग होस्ट पर पुनर्निर्देशित किया गया है. अंतिम URL ${product} को सीधे दर्ज करें.',
			'addServer.redirectInsecure' => 'सर्वर को HTTPS से एक असुरक्षित URL पर पुनर्निर्देशित किया गया है',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'सर्वर को एक असहाय URL पर पुनर्निर्देशित किया गया है. अंतिम URL ${product} को सीधे दर्ज करें.',
			'addServer.directPlexServerUrl' => 'Plex सर्वर यूआरएल',
			'addServer.directPlexServerUrlHelper' => 'अपने Plex मीडिया सर्वर के स्थानीय आईपी और पोर्ट दर्ज करें।',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex टोकन (वैकल्पिक)',
			'addServer.plexTokenHelper' => 'इस सर्वर पर auth के बिना पहुंच की अनुमति है तो खाली छोड़ दें।',
			'addServer.plexTokenRequired' => 'कृपया अपना Plex टोकन (X-Plex-Token) दर्ज करें।',
			'addServer.connectDirectPlexCard' => 'Plex मीडिया सर्वर (प्रत्यक्ष / स्थानीय)',
			'addServer.connectDirectPlexCardSubtitle' => 'Plex.tv खाते के बिना स्थानीय IP या URL का उपयोग करके सीधे कनेक्ट करें।',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => 'सीधे स्थानीय आईपी या यूआरएल का उपयोग करके कनेक्ट करें. ${name} से कनेक्ट करें.',
			'addServer.insecureTitle' => 'अनगिनत कनेक्शन',
			'addServer.insecureDescription' => ({required Object url}) => '${url} HTTP का उपयोग करता है। नेटवर्क पर मौजूद लोग आपका पासवर्ड, टोकन और मीडिया पढ़ या बदल सकते हैं। उपलब्ध होने पर HTTPS का उपयोग करें। केवल तभी जारी रखें जब आपको इस नेटवर्क पर भरोसा हो और आप जोखिम स्वीकार करते हों।',
			'addServer.allowHttp' => 'HTTP की अनुमति दें',
			'addServer.httpsRequired' => 'HTTPS का उपयोग करें या स्पष्ट रूप से एक अज्ञात कनेक्शन की अनुमति दें।',
			'watchLink.serverUnavailable' => 'इस लिंक के लिए Plex सर्वर तक पहुंच नहीं पाया।',
			'watchLink.notFound' => 'इस शो या फिल्म को आपके Plex सर्वर पर नहीं पाया जा सकता।',
			'watchLink.ambiguous' => 'यह लिंक एक से अधिक सर्वर पर आइटम से मेल खाता है. लिंक में एक सर्वर जोड़ें.',
			'watchLink.plexOnly' => 'वर्तमान में केवल Plex सर्वरों का समर्थन करता है।',
			'watchLink.unsupportedItem' => 'देखने के लिए लिंक केवल एक शो या फिल्म खोल सकते हैं।',
			'watchLink.menuItem' => 'देखें लिंक देखें',
			'watchLink.dialogTitle' => 'देखें लिंक',
			'watchLink.dialogShowHint' => 'इस लिंक को खोलने से अगले एपिसोड को खेला जाता है. &mode=shuffle जोड़ें shuffle पर शो को खेलने के लिए अंत में।',
			'watchLink.dialogMovieHint' => 'इस लिंक को खोलने से फिल्म खेलती है।',
			'watchLink.copy' => 'कॉपी',
			'watchLink.copied' => 'लिंक कॉपी करें',
			'homeLayout.title' => 'Home लेआउट',
			'homeLayout.resetToast' => 'Home Reset to the original Plezy नायक लेआउट',
			'homeLayout.resetHeroTitle' => 'स्टॉक Plezy में नायक लेआउट को पुनर्स्थापित करें?',
			'homeLayout.resetHeroBody' => 'यह प्रत्येक पंक्ति के नायक सेटिंग को खोलता है और घर के शीर्ष पर एकल घूमने वाले बैनर को वापस लाता है, जैसे कि पहले नायक पंक्तियां मौजूद थीं।',
			'homeLayout.removeRowTitle' => 'Home रीढ़ को हटाने के लिए?',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} को हटा दिया जाएगा. यह अस्वीकार नहीं किया जा सकता.',
			'homeLayout.sync' => 'सिंक्रनाइज़',
			'homeLayout.syncAccountTitle' => 'अपने Plex खाते के साथ सिंक्रनाइज़ेशन',
			'homeLayout.syncAccountOn' => 'पर: यह डिवाइस आपके अन्य डिवाइसों के साथ पंक्ति आदेश, पंक्तियों, नायक और ऑटो-स्लाइड साझा करता है।',
			'homeLayout.syncAccountOff' => 'बंद: यह डिवाइस अपने स्वयं के लेआउट को बनाए रखता है।',
			'homeLayout.syncNow' => 'अब सिंक्रनाइज़ेशन',
			'homeLayout.plexHomeManager' => 'Plex होम मैनेजर',
			'homeLayout.managePlexRows' => 'Plezy में Plex पंक्तियों का प्रबंधन करें',
			'homeLayout.managePlexRowsDescription' => 'Home-Selected लाइनों को व्यवस्थित करने के लिए खुला',
			'homeLayout.organizeHomeRows' => 'Home रैखों का आयोजन',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} पंक्तियां: आंदोलन, नायक, स्वचालित स्लाइड, हटाने',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => '${library} पंक्तियों का आयोजन करें',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => 'जारी रखें + ${n} पंक्तियां: चलना, लाइब्रेरी, होम, नायक, ऑटो-स्लाइड',
			'homeLayout.renderAsHero' => 'एक नायक कार्ड के रूप में रेंडर',
			'homeLayout.heroOnlySingleCollection' => 'केवल तब उपलब्ध है जब यह पंक्ति एकल संग्रह के वास्तविक शीर्षकों के लिए हल हो जाती है',
			'homeLayout.hero' => 'नायक',
			'homeLayout.autoSlide' => 'स्वचालित स्लाइड',
			'homeLayout.autoSlideDescription' => 'लोड (पीसी) और डी-पैड (टीवी) हमेशा काम करते हैं और टाइमर को पुनरारंभ करते हैं।',
			'homeLayout.autoSlideEditDescription' => 'इसके अलावा, यह हर कुछ सेकंड में खुद पर स्लाइड करता है. बंद: केवल जब आप एक पंख (पीसी) पर क्लिक करते हैं या दूरस्थ (टीवी) पर बाईं ओर / दाईं ओर दबाते हैं तो चलता है. लहरें और डी-पैड हमेशा किसी भी तरह से काम करते हैं.',
			'homeLayout.enableHeroFirst' => 'पहले नायक को सक्षम करें',
			'homeLayout.showOnHome' => 'Home Screen पर दिखाएँ',
			'homeLayout.home' => 'घर',
			'homeLayout.removeFromHome' => 'घर से हटाना',
			'homeLayout.selectRowsFirst' => 'सबसे पहले नीचे दिए गए होम लाइनों का चयन करें।',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} Plex प्रबंधित पंक्तियां',
			'homeLayout.continueWatching' => 'देखना जारी रखें',
			'homeLayout.continueWatchingLibraryDescription' => 'इस पुस्तकालय के स्वयं के पुनरावृत्ति-प्रगति क्रम',
			'homeLayout.continueWatchingHomeDescription' => 'Home पर दिखाए गए पुनरावृत्ति-प्रगति की पंक्ति',
			'homeLayout.nextUpHomeDescription' => 'अगला अनदेखा किए गए एपिसोड की पंक्ति अलग से दिखाई देती है होम',
			'homeLayout.library' => 'लाइब्रेरी',
			'homeLayout.showInRecommended' => 'पुस्तकालय में प्रदर्शित की सिफारिश',
			'homeLayout.customPlexRow' => 'कस्टम Plex पंक्ति',
			'homeLayout.heroNeedsLibrary' => 'पहले पुस्तकालय की जांच करें - नायक को कहीं दिखाने की जरूरत है',
			'homeLayout.heroNeedsSurface' => 'पहले पुस्तकालय या होम की जांच करें — नायक को कहीं दिखाने की जरूरत है',
			'homeLayout.removeHub' => 'Hub को हटाने के लिए',
			'homeLayout.noPlexRows' => 'नंबर Plex-प्रबंधित पंक्तियां इस पुस्तकालय के लिए वापस आ गई हैं।',
			'homeLayout.openDetails' => 'खुले विवरण',
			'homeLayout.heroCards' => 'नायक कार्ड',
			'homeLayout.tapHeroCard' => 'एक नायक का कार्ड',
			'homeLayout.tvPlayFocus' => 'टीवी रिमोट: उच्चारण Play बटन',
			'homeLayout.tvPlayFocusDescription' => 'डी-पैड नीचे खेल बटन पर रुकता है, इससे पहले कि अगले पंक्ति में आगे बढ़ें।',
			'homeLayout.tvWrap' => 'टीवी रिमोट: लूप नायक कार्ड',
			'homeLayout.tvWrapDescription' => 'अंतिम कार्ड पर सीधे पहले कार्ड पर वापस जाता है. अंतिम कार्ड पर बंद रुक जाते हैं. पहले कार्ड पर बाईं ओर हमेशा साइडबार पर जाता है.',
			'homeLayout.castOnHero' => 'नायक बैनरों पर हमला',
			'homeLayout.castOnHeroDescription' => 'एक नायक बैनर के नीचे के साथ कटौती दिखाता है. बाहर केवल शीर्षक और सारांश रखता है.',
			'homeLayout.customRows' => 'कस्टम रेंज',
			'homeLayout.loading' => 'Home लैंडिंग लैंडिंग...',
			'homeLayout.noCustomRows' => 'अभी तक कोई कस्टम नहीं',
			'homeLayout.addRowHint' => 'एक को बनाने के लिए Home Range का उपयोग करें।',
			'homeLayout.addHomeRow' => 'होम लाइन जोड़ें',
			'homeLayout.addHomeRowDescription' => 'एक श्रेणी का चयन करें; नए पंक्ति को स्वचालित रूप से संगठित करने के लिए जोड़ा जाता है',
			'homeLayout.removeRow' => 'लाइन को हटा दें',
			'homeLayout.recentlyAdded' => 'हाल ही में जोड़ा',
			'homeLayout.recentlyReleased' => 'हाल ही में रिलीज',
			'homeLayout.movieCollections' => 'फिल्म संग्रह',
			'homeLayout.showCollections' => 'संग्रह दिखाएं',
			'homeLayout.rowTitle' => 'रॉ नाम',
			'homeLayout.content' => 'संतुष्टि',
			'homeLayout.showThisRowIn' => 'इस पंक्ति को दिखाएं:',
			'homeLayout.libraryRecommended' => 'पुस्तकालय की सिफारिश',
			'homeLayout.heroCard' => 'नायक कार्ड',
			'homeLayout.heroCardDescription' => 'एक पोस्टर शीट के बजाय एक पूर्ण चौड़ा रूटिंग कार्ड के रूप में प्रदर्शित करता है।',
			'homeLayout.heroUnavailableDescription' => 'केवल तभी उपलब्ध है जब यह पंक्ति एकल संग्रह के वास्तविक शीर्षकों के लिए हल हो जाती है - एक से अधिक संग्रह चुने हुए के साथ, कोई एकल शीर्षक पार नहीं होता है।',
			'homeLayout.librariesSelection' => 'पुस्तकालय (सभी पुस्तकालयों को शामिल करने के लिए अनियंत्रित छोड़ दें)',
			'homeLayout.librariesMergedDescription' => 'यहां देखे गए प्रत्येक पुस्तकालय इस एक पंक्ति में मिश्रित है।',
			'homeLayout.movieCollectionsSelection' => 'फिल्म संग्रह (प्रत्येक चयनित पुस्तकालय के लिए सभी अनियंत्रित छोड़ दें)',
			'homeLayout.showCollectionsSelection' => 'संग्रह प्रदर्शित करें (प्रत्येक चयनित पुस्तकालय के लिए सभी अनियंत्रित छोड़ दें)',
			'homeLayout.collectionRowsDescription' => 'यदि एक संग्रह के साथ एक ही मैच होता है, तो इसके शीर्षक सीधे पंक्ति में दिखाई देते हैं. यदि एक से अधिक मैच होते हैं, तो प्रत्येक संग्रह एकल पोस्टर के रूप में दिखाई देता है – उस संग्रह को खोलने के लिए इसे टैप करें.',
			'homeLayout.allCollections' => 'सभी संग्रह',
			'homeLayout.noRowsHere' => 'अभी तक कोई पंक्ति नहीं है।',
			'homeLayout.hideWatchedRows' => 'पंक्तियों में देखे गए वस्तुओं को छिपाना',
			'homeLayout.hideWatchedRowsDescription' => 'पूरी तरह से देखे गए शीर्षक घर और लाइब्रेरी छोड़ देते हैं अनुशंसित पंक्तियां. प्रगति में लोग रहते हैं.',
			'homeLayout.untitledCollection' => 'अनगिनत संग्रह',
			'homeLayout.moveRowHint' => 'Up/Down: move row · Select: drop it here · Back: cancell',
			'homeLayout.organizeRowsHint' => 'एक पंक्ति पर चुनें (या रखें चुनें): इसे स्थानांतरित करें · बाईं ओर / दाईं ओर: पंक्ति विकल्प · वापस: किया गया',
			'homeLayout.layoutNavDescription' => 'लाइनों, पुस्तकालयों और संग्रह श्रेणियों का चयन करें',
			'homeLayout.editHomeRow' => 'संपादित करें Home Row',
			'homeLayout.resetHeroButton' => 'स्टॉक के लिए नायक लेआउट रीसेट करें Plezy',
			'homeLayout.reorderingUnlocked' => 'रीसेट अनलॉक',
			'homeLayout.reorderingLocked' => 'रिकॉर्ड लॉक',
			'homeLayout.rowsCanBeDragged' => 'तारों को खींच लिया जा सकता है - इसे रोकने के लिए लॉक पर टैप करें',
			'homeLayout.tapLockToDrag' => 'लाइनों को खींचने के लिए लॉक दबाएं',
			'homeLayout.customRowLabel' => ({required Object title}) => 'पदों की संख्या: ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => 'छिपाना',
			'homeLayout.remove' => 'हटाना',
			'homeLayout.libraryResumeRow' => 'इस पुस्तकालय की पुनरावृत्ति',
			'homeLayout.pressAgainToDelete' => 'इसे हटाने के लिए फिर से दबाएं',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => 'पर',
			'homeLayout.resetHeroButtonDescription' => 'यह प्रत्येक पंक्ति के नायक सेटिंग को बाहर करता है और शीर्ष पर एकल घूमने वाले बैनर को वापस लाता है, जैसे कि नायक पंक्तियों से पहले मौजूद था।',
			'platform.localNetworkPermission' => 'PlezyNG आपके स्थानीय नेटवर्क पर आपके मीडिया सर्वर और प्लेबैक उपकरणों से कनेक्ट करता है।',
			'platform.locationPermission' => 'PlezyNG स्थान एक्सेस का उपयोग करता है जब iOS इसे अपने स्थानीय नेटवर्क का पता लगाने और अपने मीडिया सर्वर से कनेक्ट करने के लिए आवश्यक है।',
			'platform.photoLibraryPermission' => 'मीडिया कला के रूप में उपयोग करने के लिए अपनी फोटो लाइब्रेरी से छवियों का चयन करें।',
			'platform.cameraPermission' => 'QR कोड स्कैन करने के लिए एक साथी दूरस्थ जोड़ने के लिए।',
			'fileSources.title' => 'फ़ाइल और किताबें',
			'fileSources.subtitle' => 'पढ़ो, सुनो, और अपने स्वयं के फ़ाइलों से देखो।',
			'fileSources.add' => 'स्रोत जोड़ें',
			'fileSources.importFiles' => 'फ़ाइलों का आयात',
			'fileSources.localFiles' => 'इस उपकरण पर',
			'fileSources.source' => 'स्रोत',
			'fileSources.name' => 'नाम',
			'fileSources.endpoint' => 'सर्वर URL',
			'fileSources.root' => 'फ़ोल्डर या Prefix',
			'fileSources.username' => 'उपयोगकर्ता नाम',
			'fileSources.password' => 'पासवर्ड',
			'fileSources.token' => 'API टोकन',
			'fileSources.accessKey' => 'Key ID के लिए',
			'fileSources.secretKey' => 'रहस्यमय पहुंच कुंजी',
			'fileSources.sessionToken' => 'सत्र टोकन (वैकल्पिक)',
			'fileSources.region' => 'क्षेत्र',
			'fileSources.clientId' => 'OAuth क्लाइंट आईडी',
			'fileSources.clientSecret' => 'OAuth क्लाइंट रहस्य (केवल डेस्कटॉप Google)',
			'fileSources.allowHttp' => 'विश्वसनीय नेटवर्क पर बिना एन्क्रिप्शन वाले HTTP की अनुमति दें',
			'fileSources.connect' => 'कनेक्ट करें',
			'fileSources.cancel' => 'रद्द करना',
			'fileSources.save' => 'बचाओ',
			'fileSources.close' => 'बंद करें',
			'fileSources.removeSource' => 'स्रोत से बाहर',
			'fileSources.disconnectMessage' => 'इस स्रोत का कनेक्शन हटाएँ? डाउनलोड की गई फ़ाइलें और आपके पढ़ने व सुनने का इतिहास इस डिवाइस पर बने रहेंगे।',
			'fileSources.localFolder' => 'फ़ोल्डर चुनें',
			'fileSources.empty' => 'यहाँ अभी तक कुछ नहीं',
			'fileSources.emptyHint' => 'एक स्रोत जोड़ें या एक पुस्तक, ऑडियोबुक, संगीत या वीडियो आयात करें।',
			'fileSources.search' => 'इस फ़ोल्डर की खोज करें',
			'fileSources.searchCached' => 'खोज बचाया पुस्तकालय',
			'fileSources.refresh' => 'ताज़ा',
			'fileSources.loadMore' => 'अधिक लोड करें',
			'fileSources.offline' => 'Offline के लिए उपलब्ध',
			'fileSources.download' => 'Offline रखें',
			'fileSources.removeDownload' => 'Offline कॉपी हटाने',
			'fileSources.continueReading' => 'पढ़ना जारी रखें',
			'fileSources.continueListening' => 'सुनना जारी रखें',
			'fileSources.continueWatching' => 'देखना जारी रखें',
			'fileSources.read' => 'पढ़ना',
			'fileSources.listen' => 'सुनो',
			'fileSources.play' => 'खेलना',
			'fileSources.pause' => 'रोकें',
			'fileSources.stop' => 'रोकें',
			'fileSources.startOver' => 'शुरू करें',
			'fileSources.finished' => 'समाप्त',
			'fileSources.markFinished' => 'मार्क खत्म',
			'fileSources.markUnfinished' => 'अनंत मार्क',
			'fileSources.editions' => 'संस्करण और फ़ाइल',
			'fileSources.chapters' => 'अध्याय',
			'fileSources.bookmarks' => 'नोट्स और नोट्स',
			'fileSources.bookmark' => 'Bookmark के लिए',
			'fileSources.highlight' => 'उजागर',
			'fileSources.note' => 'नोट',
			'fileSources.delete' => 'डिलीट',
			'fileSources.export' => 'नोट्स निर्यात',
			'fileSources.exported' => 'नोटों का निर्यात',
			'fileSources.sync' => 'प्रगति सिंक्रनाइज़ेशन',
			'fileSources.synced' => 'प्रगति सिंथेटिक',
			'fileSources.conflict' => 'एक और डिवाइस एक अलग स्थिति है. जहां आगे बढ़ने के लिए चुनें.',
			'fileSources.useLocal' => 'इस उपकरण का उपयोग करें',
			'fileSources.useRemote' => 'अन्य उपकरणों का उपयोग करें',
			'fileSources.history' => 'स्थिति इतिहास',
			'fileSources.groupAudio' => 'एक ऑडियो किताब के रूप में सुनो',
			'fileSources.groupHint' => 'इस फ़ोल्डर में वर्तमान में लोड किए गए ऑडियो फ़ाइलों को जोड़ें. पहले सभी पृष्ठों को लोड करें.',
			'fileSources.order' => 'फ़ाइल आदेश',
			'fileSources.moveUp' => 'ऊपर चलना',
			'fileSources.moveDown' => 'नीचे उतरना',
			'fileSources.speed' => 'Playback गति',
			'fileSources.sleep' => 'नींद का समय',
			'fileSources.sleepOff' => 'बंद करें',
			'fileSources.endChapter' => 'अध्याय का अंत',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hi'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} मिनट', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} मिनट', ), 
			'fileSources.skipBack' => 'वापस स्काइप',
			'fileSources.skipForward' => 'आगे बढ़ें',
			'fileSources.smartRewind' => 'एक ब्रेक के बाद बुद्धिमान वापसी',
			'fileSources.playbackOptions' => 'सुनने के विकल्प',
			'fileSources.remaining' => ({required Object time}) => '${time} शेष',
			'fileSources.contents' => 'सामग्री',
			'fileSources.readerSettings' => 'पढ़ने की व्यवस्था',
			'fileSources.fontSize' => 'पाठ का आकार',
			'fileSources.lineHeight' => 'लाइन स्पेसिंग',
			'fileSources.margin' => 'मार्जिन',
			'fileSources.font' => 'टाइपफैक्स',
			'fileSources.serif' => 'सेरिफ़',
			'fileSources.sans' => 'बिना सेरिफ़',
			'fileSources.mono' => 'मॉनस्पेस',
			'fileSources.columns' => 'कोलंबन',
			'fileSources.scroll' => 'Vertical स्क्रॉल करें',
			'fileSources.justify' => 'पाठ दोनों किनारों पर बराबर करें',
			'fileSources.readerTheme' => 'पृष्ठ की उपस्थिति',
			'fileSources.appTheme' => 'App Theme के बारे में टिप्पणियाँ',
			'fileSources.paper' => 'कागज',
			'fileSources.sepia' => 'सेप्पा',
			'fileSources.night' => 'रात',
			'fileSources.readAloud' => 'यह पृष्ठ ज़ोर से पढ़ें',
			'fileSources.readAlong' => 'आवाज़ के साथ पढ़ें',
			'fileSources.stopReading' => 'पढ़कर सुनाना बंद करें',
			'fileSources.searchBook' => 'पुस्तक में खोज',
			'fileSources.noMatches' => 'कोई मैच नहीं',
			'fileSources.previousPage' => 'पिछला पृष्ठ',
			'fileSources.nextPage' => 'अगला पृष्ठ',
			'fileSources.page' => ({required Object number}) => 'पृष्ठ ${number}',
			'fileSources.externalBlocked' => 'बाहरी पुस्तक लिंक पाठक में अक्षम हैं।',
			'fileSources.loading' => 'खुलने...',
			'fileSources.narrator' => 'कथाकार',
			'fileSources.audio' => 'ऑडियो',
			'fileSources.video' => 'वीडियो',
			'fileSources.ebooks' => 'ईबुक',
			'fileSources.all' => 'सारे',
			'fileSources.downloads' => 'फ़ाइलों के लिए Offline',
			'fileSources.confirmDelete' => 'चुनी हुई ऑफ़लाइन प्रति हटाएँ? आपका पढ़ने या सुनने का स्थान और नोट्स सुरक्षित रहेंगे।',
			'fileSources.errorAuthentication' => 'इस स्रोत को फिर से कनेक्ट करने के लिए साइन इन करें।',
			'fileSources.errorPermission' => 'इस स्रोत ने अनुरोधित फ़ाइल तक पहुंच नहीं दी।',
			'fileSources.errorUnavailable' => 'स्रोत उपलब्ध नहीं है. फिर से कोशिश करें, या एक ऑफ़लाइन प्रतिलिपि खोलें.',
			'fileSources.errorUnsupported' => 'इस डिवाइस पर इस प्रारूप या कनेक्शन का समर्थन नहीं किया जाता है. स्रोत सेटअप गाइड देखें.',
			'fileSources.errorInvalidData' => 'यह फ़ाइल या सर्वर प्रतिक्रिया सुरक्षित रूप से नहीं पढ़ी जा सकती है।',
			'fileSources.errorCancelled' => 'ऑपरेशन रद्द कर दिया गया है।',
			'fileSources.errorConflict' => 'स्थिति में परिवर्तन एक और सत्र में. एक स्थिति का चयन करने के लिए आइटम को फिर से खोलें.',
			'fileSources.signIn' => 'साइन इन',
			'fileSources.reconnect' => 'फिर से जुड़ें',
			'fileSources.folderHelp' => 'स्रोत के मूल फ़ोल्डर से शुरू करने के लिए इसे खाली छोड़ें। S3 URL में बकेट का नाम शामिल होता है।',
			'fileSources.preferences' => 'प्राथमिकताएं',
			'fileSources.timePosition' => 'स्थिति',
			'fileSources.audioTrack' => 'ऑडियो ट्रैक',
			'fileSources.subtitleTrack' => 'Subtitle ट्रैक',
			'fileSources.none' => 'कोई नहीं',
			'fileSources.fullscreen' => 'पूर्ण स्क्रीन',
			'fileSources.syncLocation' => 'प्रगति सिंक्रनाइज़ेशन फ़ोल्डर (वैकल्पिक)',
			'fileSources.syncLocationHint' => 'PlezyNG की स्थिति के लिए एक अलग WebDAV फ़ोल्डर। डेटा शर्त पूरी होने पर लिखा जाता है; मीडिया में कोई बदलाव नहीं होता।',
			'fileSources.audiobooks' => 'ऑडियोबुक',
			'fileSources.comics' => 'कॉमिक्स',
			'fileSources.scan' => 'पुस्तक और मीडिया के लिए स्कैन',
			'fileSources.browserReader' => 'खुले पाठक',
			'fileSources.browserReaderHelp' => 'अपने ब्राउज़र में पढ़ने वाला खुला है. अपने स्थान और नोट्स को बचाने के लिए PlezyNG खुला रखें.',
			'fileSources.on' => 'पर',
			'fileSources.advancedSetup' => 'App रजिस्ट्रेशन',
			'fileSources.microsoftSignIn' => 'Microsoft के साथ साइन इन करें',
			'fileSources.zoomIn' => 'ज़ूम में',
			'fileSources.zoomOut' => 'ज़ूम आउट',
			'fileSources.fitPage' => 'फिट पेज',
			'fileSources.fitWidth' => 'फिट विंडो',
			'fileSources.actualSize' => 'वर्तमान आकार',
			'fileSources.goToPage' => 'पृष्ठ पर जाएं',
			'fileSources.goToSection' => 'अध्याय में जाओ',
			'fileSources.pageRange' => ({required Object count}) => '1 से ${count} तक का नंबर दर्ज करें',
			'fileSources.pageLayout' => 'Page Layout के बारे में',
			'fileSources.automatic' => 'स्वचालित',
			'fileSources.singlePage' => 'एकल पृष्ठ',
			'fileSources.twoPages' => '2 पृष्ठ',
			'fileSources.readingDirection' => 'पढ़ने की दिशा',
			'fileSources.leftToRight' => 'बाएँ से दाएँ',
			'fileSources.rightToLeft' => 'दाएँ से बाएँ',
			'fileSources.letterSpacing' => 'पत्र स्पेस',
			'fileSources.wordSpacing' => 'शब्द स्पेस',
			'fileSources.readerControlsHelp' => 'पृष्ठ बड़ा करने के लिए दो उँगलियाँ फैलाएँ या ज़ूम नियंत्रण का उपयोग करें। पृष्ठ खिसकाने के लिए खींचें। Ctrl/⌘ के साथ + या − ज़ूम बदलता है; Ctrl/⌘ के साथ 0 उसे रीसेट करता है। Page Up और Page Down से पृष्ठ बदलें।',
			'fileSources.imagePage' => 'कॉमिक्स पृष्ठ',
			'fileSources.resetReader' => 'पढ़ने की पसंद को पुनर्स्थापित करें',
			'fileSources.zoom' => 'ज़ूम',
			'fileSources.useFiles' => 'फ़ाइलों और किताबों का उपयोग करें',
			'fileSources.cancelScan' => 'स्कैनिंग रद्द करें',
			'fileSources.googleDrive' => 'Google Drive',
			'lending.title' => 'सार्वजनिक पुस्तकालय',
			'lending.add' => 'एक पुस्तकालय जोड़ें',
			'lending.other' => 'एक और पुस्तकालय',
			'lending.libraryName' => 'पुस्तकालय का नाम',
			'lending.libraryUrl' => 'पुस्तकालय वेबसाइट',
			'lending.libraryUrlHint' => 'अपने पुस्तकालय के कैटलॉग या साइन-इन पेज का उपयोग करें।',
			'lending.intro' => 'अपनी लाइब्रेरी से किताबें उधार लें और उन्हें अपने पास रखें।',
			'lending.handoff' => 'साइन इन करें, उधार लें और अपनी पुस्तकालय की सेवा के साथ सुरक्षित रूप से पढ़ें।',
			'lending.openService' => 'खुली पुस्तकालय',
			'lending.findLibrary' => 'एक पुस्तकालय खोजें',
			'lending.search' => 'किताबें और लेखकों की खोज',
			'lending.catalogue' => 'कैटलॉग',
			'lending.loans' => 'ऋण',
			'lending.holds' => 'आरक्षण',
			'lending.signIn' => 'अपनी पुस्तकालय के साथ साइन इन करें',
			'lending.waiting' => 'अपने ब्राउज़र में साइन इन करना बंद करें, फिर यहां वापस जाएं।',
			'lending.cancel' => 'रद्द करना',
			'lending.disconnect' => 'पुस्तकालय को हटा दें',
			'lending.disconnectMessage' => 'इस लाइब्रेरी को इस प्रोफ़ाइल से हटाएँ? उधार ली गई किताबें और आरक्षण आपकी लाइब्रेरी में बने रहेंगे।',
			'lending.getBook' => 'किताबें प्राप्त करें',
			'lending.checkAvailability' => 'उपलब्धता की जांच करें',
			'lending.available' => 'ऋण के लिए उपलब्ध',
			'lending.unavailable' => 'वर्तमान में उपलब्ध नहीं',
			'lending.borrow' => 'उधार लें',
			'lending.placeHold' => 'आरक्षित करें',
			'lending.returnBook' => 'जल्दी लौटें',
			'lending.cancelHold' => 'आरक्षण रद्द करें',
			'lending.confirmBorrow' => 'क्या आप अपनी पुस्तकालय से इस शीर्षक को उधार लेते हैं?',
			'lending.confirmReturn' => 'यह किताब अभी लौटाएँ? पढ़ना जारी रखने के लिए इसे फिर से उधार लेना पड़ सकता है।',
			'lending.confirmCancelHold' => 'इस किताब का अपना आरक्षण रद्द करें?',
			'lending.email' => 'ईमेल नोटिस रखें',
			'lending.due' => ({required Object date}) => 'लौटाने की तारीख: ${date}',
			'lending.queue' => ({required Object position}) => 'पद ${position} लाइन में',
			'lending.empty' => 'अभी तक कोई शीर्षक नहीं है।',
			'lending.openLibraryNote' => 'Open Library के कैटलॉग का पता लगाएं. पढ़ने और ऋण के विकल्प प्रत्येक शीर्षक के पृष्ठ पर दिखाई देते हैं.',
			'lending.more' => 'अधिक लोड करें',
			'lending.gateway' => 'पुस्तकालय सेवा में हस्ताक्षर',
			'lending.gatewayHint' => 'आपके पुस्तकालय या व्यवस्थापक द्वारा प्रदान किया गया PlezyNG।',
			'lending.advanced' => 'पुस्तकालयों का संचालन',
			'lending.loadLibraries' => 'अपनी पुस्तकालय चुनें',
			'lending.expired' => 'यह ऋण समाप्त हो गया है।',
			'lending.updated' => 'पुस्तकालय अद्यतन',
			'lending.continueService' => 'सेवा में जारी रखें',
			'lending.comingSoon' => 'जल्द ही आने वाले ऋण',
			'lending.comingSoonDescription' => 'आप Libby में अपनी पुस्तकालय का उपयोग कर सकते हैं जबकि हम इसे कनेक्ट करने के लिए समाप्त कर सकते हैं।',
			'lending.suspendHold' => 'आरक्षण अस्थायी रूप से रोकें',
			'lending.resumeHold' => 'आरक्षण फिर से चालू करें',
			'lending.suspendMessage' => 'कतार में अपनी जगह बनाए रखकर अगले पाठक को यह प्रति उधार लेने दें? आप बाद में आरक्षण फिर से चालू कर सकते हैं।',
			'lending.resumeMessage' => 'यह आरक्षण फिर से चालू करें ताकि लाइब्रेरी अगली उपलब्ध प्रति आपको दे सके?',
			'lending.editEmail' => 'ईमेल नोटिस बदलना',
			'audiobook.syncTitle' => 'पढ़ना और सुनना सिंक्रनाइज़ेशन',
			'audiobook.syncHelp' => 'अपने डिवाइस के माध्यम से पढ़ने की स्थिति, सुनने की स्थिति, पूरा होने की स्थिति, बुकमार्क और नोट्स रखें. एक संलग्न स्टोरेज खाता चुनें और प्रत्येक डिवाइस पर एक ही सिंक्रनाइज़ेशन कोड का उपयोग करें. पढ़ना और सुनना अलग रहता है.',
			'audiobook.addSyncSource' => 'पहले फ़ाइलों और किताबों में Google ड्राइव, OneDrive, Dropbox, WebDAV या S3 जोड़ें।',
			'audiobook.syncDestination' => 'सिंक्रनाइज़ेशन खाता',
			'audiobook.syncFolder' => 'फ़ोल्डर सिंक्रनाइज़ेशन या Prefix',
			'audiobook.syncFolderHelp' => 'अपने WebDAV स्रोत के भीतर एक अलग मौजूदा फ़ोल्डर का उपयोग करें, या एक समर्पित S3 पूर्वावलोकन. पुस्तक फ़ाइलों को कभी नहीं बदला जाता है.',
			'audiobook.syncCode' => 'निजी सिंक्रनाइज़ेशन कोड',
			'audiobook.syncCodeHelp' => 'अपने पहले डिवाइस पर एक कोड बनाएं, फिर उस कोड को अपने अन्य डिवाइस पर दर्ज करें. एक निजी प्रति बनाए रखें: यह आपके एन्क्रिप्टेड स्टेट की कुंजी है. प्रत्येक व्यक्ति के लिए एक अलग कोड का उपयोग करें.',
			'audiobook.showCode' => 'प्रदर्शित करें या सिंक्रनाइज़ेशन कोड छिपाएं',
			'audiobook.newSyncCode' => 'एक नया सिंक्रनाइज़ेशन कोड बनाएं',
			'audiobook.saveSync' => 'Save और Sync',
			'audiobook.disableSync' => 'इस डिवाइस पर सिंक्रनाइज़ेशन बंद करें',
			'audiobook.syncSourceDisconnect' => 'इस स्रोत को हटाने से यहां पढ़ने और सुनने के लिए सिंक्रनाइज़ेशन बंद हो जाएगा. एन्क्रिप्टेड सिंक्रनाइज़ेशन फ़ाइल प्रदाता में रहेंगे.',
			'audiobook.syncReconnect' => 'भंडारण खाते को फिर से कनेक्ट करें',
			'audiobook.lastSynced' => ({required Object time}) => '${time} पर अंतिम संश्लेषण',
			'audiobook.syncPrivacy' => 'केवल एन्क्रिप्टेड प्रगति और नोट्स संग्रहीत किए जाते हैं. ऑडियो और ई-पुस्तक फ़ाइलें, खाता टोकन और पासवर्ड अपलोड नहीं किए जाते हैं. Google ड्राइव और OneDrive ऐप स्टोरेज का उपयोग करते हैं; ड्रॉपबॉक्स PlezyNG सिंक्रनाइज़ेशन का उपयोग करता है. सिंक्रनाइज़ेशन को सक्षम करने के लिए अतिरिक्त लिखित पहुंच की आवश्यकता हो सकती है. जबकि सक्षम है, इस गंतव्य में प्रगति सिंक्रनाइज़ेशन होता है; सर्वर प्रगति अलग रहती है. स्विच सिंक्रनाइज़ेशन स्थानीय इतिहास और दूरस्थ स्थिति बनाए रखता है.',
			'audiobook.syncConflicts' => 'कहां वापस जाने के लिए चुनना',
			'audiobook.conflictHelp' => 'इन परिवर्तनों को स्वतंत्र रूप से किया गया था. रखने के लिए स्थिति या नोटबुक संस्करण का चयन करें. एक बाद में टाइमस्टैम्प या एक उच्च प्रतिशत स्वचालित रूप से जीतता नहीं है.',
			'audiobook.syncDevice' => ({required Object device}) => 'डिवाइस ${device}',
			'audiobook.syncUnknownDevice' => 'अज्ञात उपकरण',
			'audiobook.deletedBookmark' => 'हटाए गए नोटबुक',
			'audiobook.finished' => 'समाप्त',
			'audiobook.readingPosition' => ({required Object percent}) => 'पढ़ने के लिए · ${percent}%',
			'audiobook.chapterTimeline' => 'अध्याय प्रगति',
			'audiobook.bookTimeline' => 'पुस्तक प्रगति',
			'audiobook.bookRemaining' => ({required Object time}) => 'इस पुस्तक में शेष समय: ${time}',
			'audiobook.chapterRemaining' => ({required Object time}) => 'इस अध्याय में शेष समय: ${time}',
			'audiobook.unknownRemaining' => 'कुल समय उपलब्ध है जब भागों को खेला जाता है',
			'audiobook.undoSeek' => 'आखिरी खोज',
			'audiobook.customSpeed' => 'प्लेबैक की गति',
			'audiobook.speedHelp' => '0.25× से 4× तक की गति का चयन करें।',
			'audiobook.apply' => 'आवेदन करें',
			'audiobook.customSleep' => 'कस्टम नींद टाइमर',
			'audiobook.sleepMinutes' => 'मिनट (1–1440)',
			'audiobook.sleepChapters' => ({required Object count}) => '${count} अध्याय के बाद रुकें',
			'audiobook.extendSleep' => '5 मिनट जोड़ें',
			'audiobook.sleepRemaining' => ({required Object time}) => 'नींद टाइमर: ${time}',
			'audiobook.useDefaults' => 'नई किताबों के लिए इन सुनने नियंत्रण का उपयोग करें',
			'audiobook.librarySort' => 'विभिन्न किताबें',
			'audiobook.sortTitle' => 'शीर्षक',
			'audiobook.sortAuthor' => 'लेखक',
			'audiobook.sortNarrator' => 'कथाकार',
			'audiobook.sortSeries' => 'श्रृंखला आदेश',
			'audiobook.sortRecent' => 'हाल ही में खोला गया',
			'audiobook.statusFilter' => 'पढ़ने की स्थिति',
			'audiobook.statusAll' => 'सभी किताबें',
			'audiobook.statusNew' => 'शुरू नहीं हुआ',
			'audiobook.statusProgress' => 'प्रगति में',
			'audiobook.statusFinished' => 'समाप्त',
			'audiobook.goToTime' => 'समय के लिए जाओ',
			'audiobook.timeHelp' => 'घंटे: मिनट: सेकंड, या मिनट: सेकंड',
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
			'games.unavailable' => 'The connection could not complete. Check that the computer is awake and paired, then try again.',
			'games.timeout' => 'Connection timed out. Check the computer, pairing code and network before trying again.',
			'games.libraryHint' => 'Choose a computer to connect and load its games. Once connected, choose a game to play inside PlezyNG.',
			'games.touchControls' => 'On-screen controller',
			'games.touchDescription' => 'Show the native controller during a stream. It supports multiple fingers, sticks, buttons and triggers.',
			'games.touchSetup' => 'On-screen controls',
			'games.touchSetupHint' => 'In a stream, use the controller’s settings button to move controls and change opacity. A Bluetooth or USB controller also works.',
			'games.addGame' => 'Add game shortcut',
			'games.gameName' => 'Game name',
			'games.gameId' => 'Host application ID',
			'games.invalidGame' => 'Enter a game name and a positive numeric host application ID.',
			'games.wake' => 'Wake computer',
			'games.wakeSent' => 'Wake request sent. The computer must support Wake-on-LAN on this network.',
			'games.mac' => 'MAC address (optional)',
			'games.help' => 'Games help',
			'games.helpBody' => 'Enable Games for your profile, keep Sunshine or another compatible host running, then choose a discovered computer. Approve the first connection and choose a game. Pairing authorization belongs to this device; the saved library belongs to this PlezyNG profile.\n\nThe Android engine is bundled into PlezyNG and includes touch controls and gamepad support. Other native platforms and Steam playback are still being implemented. Steam discovery does not mean playback is available.\n\nSunshine, Apollo, Wolf and older GameStream hosts can expose different features. Pairing requires the host’s approval. QR codes open the Sunshine PIN page; they do not carry your credentials.\n\nFor access away from home, use the computer’s VPN address. Automatic discovery normally stays on the local network.\n\nLeaving a stream keeps the game running on the computer. Stop it from the stream menu when you want to end the host session.',
			'games.cancel' => 'Cancel',
			'games.scanning' => 'Looking for computers…',
			'games.saveShortcut' => 'Save shortcut',
			'games.manualHint' => 'For Moonlight use the host’s GameStream HTTP port (usually 47989), not its web settings port. Steam normally advertises on 27036.',
			'games.engineUnavailable' => 'In-app streaming is not available here yet',
			'games.nativeEnginePending' => 'This build does not include a streaming engine for this platform. You can save the computer, but it cannot play here yet.',
			'games.steamEnginePending' => 'Steam computers can be discovered and saved. Embedded Steam pairing and playback are still in development, including the Pyrowave beta codec.',
			'games.steamBetaTitle' => 'Steam beta · Pyrowave',
			'games.steamBetaDescription' => 'Pyrowave support is planned for the embedded Steam engine. Discovery alone cannot tell whether a computer or this device can use it. Playback remains unavailable until the engine has been integrated and tested.',
			_ => null,
		};
	}
}
