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
class TranslationsHe extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsHe({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.he,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <he>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsHe _root = this; // ignore: unused_field

	@override 
	TranslationsHe $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsHe(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$he app = _Translations$app$he._(_root);
	@override late final _Translations$cast$he cast = _Translations$cast$he._(_root);
	@override late final _Translations$automation$he automation = _Translations$automation$he._(_root);
	@override late final _Translations$notifications$he notifications = _Translations$notifications$he._(_root);
	@override late final _Translations$appIcon$he appIcon = _Translations$appIcon$he._(_root);
	@override late final _Translations$auth$he auth = _Translations$auth$he._(_root);
	@override late final _Translations$common$he common = _Translations$common$he._(_root);
	@override late final _Translations$screens$he screens = _Translations$screens$he._(_root);
	@override late final _Translations$update$he update = _Translations$update$he._(_root);
	@override late final _Translations$appAccess$he appAccess = _Translations$appAccess$he._(_root);
	@override late final _Translations$settings$he settings = _Translations$settings$he._(_root);
	@override late final _Translations$themeEditor$he themeEditor = _Translations$themeEditor$he._(_root);
	@override late final _Translations$search$he search = _Translations$search$he._(_root);
	@override late final _Translations$hotkeys$he hotkeys = _Translations$hotkeys$he._(_root);
	@override late final _Translations$fileInfo$he fileInfo = _Translations$fileInfo$he._(_root);
	@override late final _Translations$mediaMenu$he mediaMenu = _Translations$mediaMenu$he._(_root);
	@override late final _Translations$rateSheet$he rateSheet = _Translations$rateSheet$he._(_root);
	@override late final _Translations$accessibility$he accessibility = _Translations$accessibility$he._(_root);
	@override late final _Translations$tooltips$he tooltips = _Translations$tooltips$he._(_root);
	@override late final _Translations$audioTracks$he audioTracks = _Translations$audioTracks$he._(_root);
	@override late final _Translations$videoControls$he videoControls = _Translations$videoControls$he._(_root);
	@override late final _Translations$messages$he messages = _Translations$messages$he._(_root);
	@override late final _Translations$subtitlingStyling$he subtitlingStyling = _Translations$subtitlingStyling$he._(_root);
	@override late final _Translations$mpvConfig$he mpvConfig = _Translations$mpvConfig$he._(_root);
	@override late final _Translations$dialog$he dialog = _Translations$dialog$he._(_root);
	@override late final _Translations$profiles$he profiles = _Translations$profiles$he._(_root);
	@override late final _Translations$connections$he connections = _Translations$connections$he._(_root);
	@override late final _Translations$accountPreferences$he accountPreferences = _Translations$accountPreferences$he._(_root);
	@override late final _Translations$discover$he discover = _Translations$discover$he._(_root);
	@override late final _Translations$errors$he errors = _Translations$errors$he._(_root);
	@override late final _Translations$libraries$he libraries = _Translations$libraries$he._(_root);
	@override late final _Translations$about$he about = _Translations$about$he._(_root);
	@override late final _Translations$serverSelection$he serverSelection = _Translations$serverSelection$he._(_root);
	@override late final _Translations$hubDetail$he hubDetail = _Translations$hubDetail$he._(_root);
	@override late final _Translations$logs$he logs = _Translations$logs$he._(_root);
	@override late final _Translations$detail$he detail = _Translations$detail$he._(_root);
	@override late final _Translations$startup$he startup = _Translations$startup$he._(_root);
	@override late final _Translations$licenses$he licenses = _Translations$licenses$he._(_root);
	@override late final _Translations$navigation$he navigation = _Translations$navigation$he._(_root);
	@override late final _Translations$explore$he explore = _Translations$explore$he._(_root);
	@override late final _Translations$liveTv$he liveTv = _Translations$liveTv$he._(_root);
	@override late final _Translations$collections$he collections = _Translations$collections$he._(_root);
	@override late final _Translations$playlists$he playlists = _Translations$playlists$he._(_root);
	@override late final _Translations$music$he music = _Translations$music$he._(_root);
	@override late final _Translations$watchTogether$he watchTogether = _Translations$watchTogether$he._(_root);
	@override late final _Translations$downloads$he downloads = _Translations$downloads$he._(_root);
	@override late final _Translations$shaders$he shaders = _Translations$shaders$he._(_root);
	@override late final _Translations$companionRemote$he companionRemote = _Translations$companionRemote$he._(_root);
	@override late final _Translations$videoSettings$he videoSettings = _Translations$videoSettings$he._(_root);
	@override late final _Translations$performanceOverlay$he performanceOverlay = _Translations$performanceOverlay$he._(_root);
	@override late final _Translations$externalPlayer$he externalPlayer = _Translations$externalPlayer$he._(_root);
	@override late final _Translations$metadataEdit$he metadataEdit = _Translations$metadataEdit$he._(_root);
	@override late final _Translations$matchScreen$he matchScreen = _Translations$matchScreen$he._(_root);
	@override late final _Translations$serverTasks$he serverTasks = _Translations$serverTasks$he._(_root);
	@override late final _Translations$trakt$he trakt = _Translations$trakt$he._(_root);
	@override late final _Translations$seerr$he seerr = _Translations$seerr$he._(_root);
	@override late final _Translations$services$he services = _Translations$services$he._(_root);
	@override late final _Translations$addServer$he addServer = _Translations$addServer$he._(_root);
	@override late final _Translations$watchLink$he watchLink = _Translations$watchLink$he._(_root);
	@override late final _Translations$homeLayout$he homeLayout = _Translations$homeLayout$he._(_root);
	@override late final _Translations$platform$he platform = _Translations$platform$he._(_root);
	@override late final _Translations$fileSources$he fileSources = _Translations$fileSources$he._(_root);
	@override late final _Translations$lending$he lending = _Translations$lending$he._(_root);
	@override late final _Translations$audiobook$he audiobook = _Translations$audiobook$he._(_root);
	@override late final _Translations$sourceSetup$he sourceSetup = _Translations$sourceSetup$he._(_root);
	@override late final _Translations$games$he games = _Translations$games$he._(_root);
}

// Path: app
class _Translations$app$he extends Translations$app$en {
	_Translations$app$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: cast
class _Translations$cast$he extends Translations$cast$en {
	_Translations$cast$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => 'שידור למכשיר';
	@override String get searching => 'מחפשים מכשירים לגידול...';
	@override String connectedTo({required Object device}) => 'חיבור ל- ${device}';
	@override String get device => 'מכשיר לשידור';
	@override String get readyToCast => 'מוכן לשידור';
	@override String get subtitle => 'כתוביות';
	@override String get serverNotAvailable => 'שרת התקשורת אינו זמין.';
	@override String get stopCasting => 'הפסקת השידור';
	@override String get castToDevice => 'שידור למכשיר';
	@override String get noEpisodeAvailable => 'אין פרקים זמינים להורדה.';
	@override String get startFailed => 'לא יכול להתחיל לגרד.בדוק את השרת ולנסות שוב.';
}

// Path: automation
class _Translations$automation$he extends Translations$automation$en {
	_Translations$automation$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => 'אין וידאו פעיל כדי לשלוט.';
	@override String get profileNotFound => 'לא ניתן היה למצוא את הפרופיל Plezy.';
}

// Path: notifications
class _Translations$notifications$he extends Translations$notifications$en {
	_Translations$notifications$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => 'פרק חדש';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appIcon
class _Translations$appIcon$he extends Translations$appIcon$en {
	_Translations$appIcon$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'אפליקציה icon';
	@override String get defaultIcon => 'ברירת מחדל';
	@override String get current => 'אייקון הנוכחי';
	@override String get locked => 'גישה לכל החיים נדרשת';
	@override String get lockedHint => 'התחל את הניסיון של 7 ימים או לפתוח את PlezyNG לכל החיים כדי להשתמש בסמלים חלופיים.';
	@override String get changeFailed => 'לא ניתן לשנות את האייקון של האפליקציה';
	@override String get launcherHint => 'האייקון החדש מופיע על המסך הבית שלך ברגע שאתה עוזב PlezyNG.';
	@override String get tvLauncherHint => 'הפאנר החדש מופיע ברגע שאתה עוזב PlezyNG. Android TV יכול להמשיך להציג את הפאנר הישן עד הטלוויזיה מתחילה מחדש.';
	@override late final _Translations$appIcon$names$he names = _Translations$appIcon$names$he._(_root);
}

// Path: auth
class _Translations$auth$he extends Translations$auth$en {
	_Translations$auth$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'הצטרפו ל- Plex';
	@override String get showQRCode => 'הצג קוד QR';
	@override String get authenticate => 'אמיתי';
	@override String get authenticationTimeout => 'התגובה נמשכת, בבקשה נסה שוב.';
	@override String get scanQRToSignIn => 'סורק את קוד ה-QR הזה כדי להירשם';
	@override String get waitingForAuth => 'מחכה לאותיות... היכנס מהדפדפן שלך.';
	@override String get useBrowser => 'שימוש ב-Browser';
	@override String get or => 'או';
	@override String connectToMediaBrowser({required Object product}) => 'חיבור ל- ${product}';
	@override String get quickConnect => 'חיבור-מהיר';
	@override String get useQuickConnect => 'השתמש בQuick Connect';
	@override String get quickConnectInstructions => 'פתח את Quick Connect ב- Jellyfin והזין קוד זה.';
	@override String get quickConnectWaiting => 'מחכה לאישור...';
	@override String get quickConnectCancel => 'בטל';
	@override String get quickConnectExpired => 'תוקף החיבור המהיר פג. יש לנסות שוב.';
	@override String get localDataRecoveryRequired => 'PlezyNG לא הצליח לשחזר בבטחה את פרטי ההתחברות המקומיים ואת נתוני הניגון הממתינים. יש להתחבר שוב.';
	@override String get pinCheckRejected => 'בדיקת ה-PIN Plex נדחתה';
	@override String get connectToDirectPlex => 'חיבור לשרת מקומי Plex';
}

// Path: common
class _Translations$common$he extends Translations$common$en {
	_Translations$common$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'בטל';
	@override String get save => 'שמור';
	@override String get close => 'סגור';
	@override String get clear => 'ברור';
	@override String get reset => 'איתחול';
	@override String get later => 'מאוחר';
	@override String get submit => 'שלח';
	@override String get confirm => 'אישור';
	@override String get retry => 'נסה שנית';
	@override String get logout => 'להירשם';
	@override String get unknown => 'לא ידוע';
	@override String get refresh => 'רענון';
	@override String get yes => 'כן';
	@override String get no => 'לא';
	@override String get delete => 'מחק';
	@override String get edit => 'ערוך';
	@override String get shuffle => 'ערבוב';
	@override String get addTo => 'הוסף ל...';
	@override String get createNew => 'יצירת חדש';
	@override String get connect => 'התחבר';
	@override String get disconnect => 'התנתק';
	@override String get play => 'נגן';
	@override String get pause => 'השהה';
	@override String get resume => 'המשך ניגון';
	@override String get error => 'שגיאה';
	@override String get search => 'חיפוש';
	@override String get home => 'בית';
	@override String get back => 'חזרה';
	@override String get settings => 'הגדרות';
	@override String get mute => 'השתק';
	@override String get ok => 'בסדר';
	@override String get off => 'כבוי';
	@override String get options => 'אפשרויות';
	@override String seasonNumber({required Object number}) => 'עונה ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'פרק ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'סעיף ${number}';
	@override String get reconnect => 'מחדש';
	@override String get viewAll => 'ראה הכל';
	@override String get checkingNetwork => 'בדק את הרשת';
	@override String get loadingServers => 'שרתים מחוברים...';
	@override String get connectingToServers => 'חיבור לשרתים...';
	@override String get startingOfflineMode => 'התחלנו במצב offline.';
	@override String get loading => 'טעינה...';
	@override String get fullscreen => 'מסך מלא';
	@override String get exitFullscreen => 'יוצא מלא מסך';
	@override String get pressBackAgainToExit => 'לחצו שוב כדי לצאת';
	@override late final _Translations$common$ratingSource$he ratingSource = _Translations$common$ratingSource$he._(_root);
	@override String get notAvailable => 'N / A';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
	@override late final _Translations$common$mediaKind$he mediaKind = _Translations$common$mediaKind$he._(_root);
}

// Path: screens
class _Translations$screens$he extends Translations$screens$en {
	_Translations$screens$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'רישיונות';
	@override String get switchProfile => 'פרופיל Switch';
	@override String get subtitleStyling => 'עיצוב כתוביות';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'יומני רישום';
}

// Path: update
class _Translations$update$he extends Translations$update$en {
	_Translations$update$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get available => 'עדכון זמין';
	@override String versionAvailable({required Object version}) => 'גרסה ${version} זמינה';
	@override String currentVersion({required Object version}) => 'תגית: ${version}';
	@override String get skipVersion => 'לגרד את הגירסה הזו';
	@override String get viewRelease => 'ראה שחרור';
	@override String get latestVersion => 'אתם נמצאים בגרסה האחרונה';
	@override String get checkFailed => 'לא הצלחתי לבדוק עדכונים';
}

// Path: appAccess
class _Translations$appAccess$he extends Translations$appAccess$en {
	_Translations$appAccess$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'נסה כל תכונה בחינם במשך 7 ימים';
	@override String get description => 'התחל ניסיון של שבעה ימים עם גישה מלאה לכל תכונה PlezyNG.אין תשלום במהלך ניסיון ואין מנוי.אחרי ניסיון, רכישה אחת לכל החיים במחיר החנות שלך פותחת PlezyNG לכל החיים.';
	@override String get trialEndedDescription => 'לחסום כל תכונה ב- PlezyNG לחיים עם רכישה אחת במחיר החנות שלך.';
	@override String get startTrial => 'התחל את הניסוי החופשי שלי 7 ימים';
	@override String get trialActive => 'המבחן המלא של 7 הימים שלך הוא פעיל.';
	@override String get trialEnded => 'התביעה של 7 ימים הסתיימה';
	@override String get trialStartFailed => 'לא הצלחתי לשמור את הניסוי על המכשיר הזה, בבקשה נסה שוב.';
	@override String get lifetimeTitle => 'PlezyNG פתוח לכל החיים';
	@override String get lifetimeBody => 'יש לך גישה לכל החיים לכל תכונה PlezyNG.';
	@override String get manageTitle => 'PlezyNG גישה לכל החיים';
	@override String get manageDescription => 'נסה כל תכונה בחינם במשך 7 ימים, ולאחר מכן לפתוח הכל לכל החיים עם תשלום אחד במחיר החנות שלך.';
	@override String buy({required Object price}) => 'לחסום כל תכונה עבור ${price}';
	@override String get loadingPrice => 'מחירים של חנות ...';
	@override String get retryPrice => 'מחיר החזר מחפש';
	@override String get restore => 'החזרת רכישות לכל החיים';
	@override String get pending => 'הרכישה שלך מחכה לתשלום או אישור.הגישה לכל החיים פוגעת ברגע שהחנות ממלאת אותה.';
	@override String get storeUnavailable => 'קניות אינן זמינות.בדוק שאתה נרשם לחנות והקניות מותרות על מכשיר זה.';
	@override String get productNotFound => 'הפסקת החיים PlezyNG עדיין לא זמינה בחנות זו.';
	@override String get productQueryFailed => 'לא יכולתי להעלות את מחיר החנות.בדוק את החיבור שלך ולנסות שוב.';
	@override String get purchaseFailed => 'הקנייה לא עברה, נסה שוב.';
	@override String get restoreFailed => 'לא יכולתי להגיע לחנות כדי להחזיר את הרכישה שלך.';
	@override String get nothingToRestore => 'מספר PlezyNG רכישה לכל החיים נמצאה עבור חשבון החנות הזה.';
}

// Path: settings
class _Translations$settings$he extends Translations$settings$en {
	_Translations$settings$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'הגדרות';
	@override String get supportDeveloper => 'תמיכה PlezyNG';
	@override String get supportDeveloperDescription => 'תרומות לתמיכה בפיתוח';
	@override String get lifetimeAccess => 'PlezyNG גישה לכל החיים';
	@override String get language => 'שפה';
	@override String get theme => 'ערכת נושא';
	@override String get appearance => 'הופעות';
	@override String get detailPage => 'פרטים דף';
	@override String get themeSongsEnabled => 'לשחק שירים נושאים';
	@override String get themeSongsEnabledDescription => 'לשחק שירים נושאים זמינים תוך צפייה בפרטים של התקשורת.';
	@override String get themeSongVolume => 'שירים מאת Volume';
	@override String get videoPlayback => 'וידאו Playback';
	@override String get videoPlaybackDescription => 'הגדרת התנהגות playback';
	@override String get advanced => 'מתקדם';
	@override String get episodePosterMode => 'סגנון פוסטר';
	@override String get seriesPoster => 'סדרת פוסטרים';
	@override String get seasonPoster => 'עונה פוסטר';
	@override String get episodeThumbnail => 'טומבניה';
	@override String get showHeroSectionDescription => 'תצוגה עם תוכן קרוסל על המסך הבית';
	@override String get secondsLabel => 'שניות';
	@override String get minutesLabel => 'דקות';
	@override String get secondsShort => 'ס';
	@override String get minutesShort => 'M';
	@override String durationHint({required Object min, required Object max}) => 'הקלד ערך (${min}-${max})';
	@override String get systemTheme => 'מערכת';
	@override String get lightTheme => 'אור';
	@override String get darkTheme => 'חשוך';
	@override String get oledTheme => 'OLED';
	@override String get emberTheme => 'אדם';
	@override String get glacierTheme => 'גלידה';
	@override String get forestTheme => 'יערות';
	@override String get plumTheme => 'פלום';
	@override String get paperTheme => 'נייר';
	@override String get libraryDensity => 'ספרייה עבה';
	@override String get displayScale => 'מצגת Scale';
	@override String get compact => 'קומפקטי';
	@override String get comfortable => 'נוח';
	@override String get gridSpacing => 'רשת Spacing';
	@override String get gridSpacingTight => 'טייק';
	@override String get gridSpacingNormal => 'רגיל';
	@override String get gridSpacingSpacious => 'חלל';
	@override String get tvCornerSpotlightBackdrop => 'תגית: Spotlight Backdrop';
	@override String get tvCornerSpotlightBackdropDescription => 'הצג יצירות אמנות באור הימני העליון במקום למלא את המסך';
	@override String get viewMode => 'צפו במצב';
	@override String get gridView => 'רשת';
	@override String get listView => 'רשימה';
	@override String get showHeroSection => 'תגית: Hero Section';
	@override String get showHomeBackdrop => 'תגית: backdrop artwork';
	@override String get showHomeBackdropDescription => 'מציג יצירות אמנות גדולות מאחורי שורות הבית';
	@override String get contentScreensaverEnabled => 'תגית: Screensaver';
	@override String get contentScreensaverEnabledDescription => 'הצג יצירות אמנות במלוא המסך לאחר שהאפליקציה הפכה ל-IDLE';
	@override String get contentScreensaverDelay => 'הפעל את המסך לאחר';
	@override String get contentScreensaverLibraries => 'ספרייה Screensaver';
	@override String get contentScreensaverLibrariesDescription => 'בחר איזה ספרייה מספקת עבודת אמנות שמירה על מסך.אם לא נבחרה אחת, עבודת אמנות מכל הספרייה משתמשת.';
	@override String get contentScreensaverAllLibraries => 'כל הספריות';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} ספרייה נבחרה';
	@override String get contentScreensaverNoLibraries => 'אין ספריית מדיה מקושרת.';
	@override String get contentScreensaverDismissHint => 'לחץ על כל כפתור או לחץ כדי להסיר';
	@override String get newEpisodeNotifications => 'הודעות פרק חדש';
	@override String get newEpisodeNotificationsDescription => 'קבלת התראה כשנוסף פרק חדש לסדרה שצפית בה עד הפרק האחרון. הבדיקה מתבצעת בזמן ש-Plezy פתוח.';
	@override String get continueWatchingRowSize => 'להמשיך לצפות בגודל שורה';
	@override String continueWatchingRowSizeValue({required Object label}) => '${label} כרטיסים';
	@override String get rowSizeCompact => 'קומפקטי';
	@override String get rowSizeStandard => 'סטנדרטי';
	@override String get rowSizeLarge => 'גדול';
	@override String get continueWatchingAction => 'להמשיך לצפות בפעולה';
	@override String get continueWatchingPlay => 'נגן';
	@override String get continueWatchingDetails => 'פרטים פתוחים';
	@override String get episodeAction => 'פרק פעולה';
	@override String get episodePlay => 'נגן';
	@override String get episodeDetails => 'פרטים פתוחים';
	@override String get useGlobalHubs => 'שימוש בבית Layout';
	@override String get useGlobalHubsDescription => 'הצג חביות בית מאוחדות. אחרת השתמשו בהמלצות ספרייה.';
	@override String get showServerNameOnHubs => 'הצג שם שרת ב- Hubs';
	@override String get showServerNameOnHubsDescription => 'תמיד להציג את שמות השרתים בשמות ה- hub.';
	@override String get groupLibrariesByServer => 'ספריות קבוצתיות לפי שרת';
	@override String get groupLibrariesByServerDescription => 'ספריית צד קבוצתי מתחת לכל שרת מדיה.';
	@override String get alwaysKeepSidebarOpen => 'תמיד שמור את הדף פתוח';
	@override String get alwaysKeepSidebarOpenDescription => 'שורת צד נשארת מורחבת ומחוז התוכן מתאים לתאימות';
	@override String get showUnwatchedCount => 'הצג חשבונות בלתי צפויים';
	@override String get showUnwatchedCountDescription => 'הצג פרק לא צופה מספר על מופעים ועונות';
	@override String get showWatchedIndicators => 'הצג אינדיקטורים שנצפו';
	@override String get showWatchedIndicatorsDescription => 'הצג סימן בדיקת סרטים, הופעות ופרקים שנצפו';
	@override String get showEpisodeNumberOnCards => 'הצג מספר פרק על כרטיסים';
	@override String get showEpisodeNumberOnCardsDescription => 'הצג את מספר העונה ואת מספר הפרקים על כרטיסי הפרקים';
	@override String get showSeasonPostersOnTabs => 'הצג פוסטרים עונתיים על Tabs';
	@override String get showSeasonPostersOnTabsDescription => 'הצג את הפוסט של כל עונה מעל הכרטיסייה שלה';
	@override String get tvFullCardLayout => 'כרטיסי טלוויזיה מלאים';
	@override String get tvFullCardLayoutDescription => 'השתמש בתמונה בלבד כרטיסי טלוויזיה עם שמות שחקנים מוגזמים';
	@override String get focusGlow => 'פוקוס גלובוס';
	@override String get focusGlowDescription => 'צייר אור רך סביב כרטיס המוקד';
	@override String get visualEffects => 'אפקטים חזותיים';
	@override String get visualEffectsAuto => 'אוטומטי';
	@override String get visualEffectsAutoDescription => 'הפחתת השפעות באופן אוטומטי על מכשירים בעלי כוח נמוך';
	@override String get visualEffectsFull => 'מלא';
	@override String get visualEffectsReduced => 'ירידה';
	@override String get visualEffectsReducedDescription => 'פחות אנמיה ועבודות אמנות ברזולוציה נמוכה יותר';
	@override String get hideSpoilers => 'הסתיר ספוילרים עבור פרקים לא נצפו';
	@override String get hideSpoilersDescription => 'תסמינים וסיפורים של פרקים לא נצפו';
	@override String get playerBackend => 'שחקן Backend';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'דקורטיבי חומרה';
	@override String get hardwareDecodingDescription => 'השתמש בהאיץ חומרה כאשר זמין';
	@override String get playbackBuffer => 'Playback בופר';
	@override String get playbackBufferAuto => 'מכוניות (מומלץ)';
	@override String get playbackBufferLarge => 'גדול';
	@override String get playbackBufferExtraLarge => 'גדול מאוד';
	@override String get playbackBufferDescription => 'בופר יותר נגד חיבורים לא יציבים.גם מוגבל על ידי גודל בופר.';
	@override String get streamBufferSize => 'גודל בופר';
	@override String streamBufferSizeValue({required Object size}) => '${size} MB';
	@override String get streamBufferSizeDescription => 'כמה וידאו יש להעלות קדימה בעת משחק ישיר.Transcodes stop at the server\'s own transcode buffer. 0 = Auto';
	@override String get streamBufferSizeExoNote => 'להחליף את Playback Buffer בעת הגדרת, קפס בחצי הגבול של הזיכרון של האפליקציה';
	@override String get streamBufferMegabytes => 'מגבייטים';
	@override String get defaultQualityTitle => 'איכות מזויפת';
	@override String get cellularQualityTitle => 'איכות מוגבלת על תאים';
	@override String get remoteQualityTitle => 'איכות רדיו מרחוק';
	@override String get remoteQualitySameAsDefault => 'כמו איכות מזויפת';
	@override String get cellularQualitySameAsDefault => 'כמו איכות מזויפת';
	@override String get directPlayCoveredQuality => 'לצלם קטעי וידאו קטנים באיכות מקורית';
	@override String get directPlayCoveredQualityDescription => 'משחק וידאו ישיר כבר בתוך הגבול איכות במקום להעתיק אותם';
	@override String get videoCodecs => 'וידאו קודיק';
	@override String get videoCodecsDescription => 'הקודקים שאינם נבדקים מועברים על ידי השרת';
	@override String get videoCodecsAlwaysAccepted => 'תמיד מקובל';
	@override String get musicQualityTitle => 'איכות מוזיקה';
	@override String get subtitleStyling => 'עיצוב כתוביות';
	@override String get subtitleStylingDescription => 'להגדיר את המראה של subtitle';
	@override String get smallSkipDuration => 'קפיצה קצרה';
	@override String get largeSkipDuration => 'תקופת הנחיתה הגדולה';
	@override String get rewindOnResume => 'מחדש על סיכום';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(seconds,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} שניה',
		two: 'שתי שניות',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} שניות',
	);
	@override String get defaultSleepTimer => 'זמן שינה מוגדר';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(minutes,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} דקה',
		two: 'שתי דקות',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} דקות',
	);
	@override String get rememberTrackSelections => 'זכרו את הבחירה של שורות לפי הצגה/סרט';
	@override String get chooseTracksBeforePlayback => 'בחר את האודיו ואת התת-כותרות לפני המשחק';
	@override String get chooseTracksBeforePlaybackDescription => 'בחר את המקור של אודיו ותת-תגית רצועות לפני כל וידאו מתחיל.';
	@override String get alwaysShowSubtitlesOnDevice => 'תמיד להציג תת-כותרות על מכשיר זה';
	@override String get alwaysShowSubtitlesOnDeviceDescription => 'כאשר לשרת אין תת-כותרת שנבחרה, בחר שורה מקומית.';
	@override String get autoDownloadPreferredSubtitle => 'תגית: חסר תגיות שפה מועדפת';
	@override String get autoDownloadPreferredSubtitleDescription => 'בחר תת-תואר זמין בשפה המועדפת שלך באופן מקומי.אם אין אחד, בבקשה מהשרת להשיג אחד כאשר תומך.';
	@override String get rememberTrackSelectionsDescription => 'שמור אפשרויות אודיו וסובייטים לפי הצגה או סרט במכשיר זה';
	@override String get rememberTrackSelectionsBackendRule => 'לעבוד מקומי עם Plex, Jellyfin, ו Emby; Plex ו Jellyfin יכול גם לשמור בחירות על השרת';
	@override String get followServerTrackSelections => 'השתמש בחירות מסלול לפי פרק של השרת';
	@override String get followServerTrackSelectionsDescription => 'על שינוי פרק, ליישם את האודיו ואת הכותרות הנבחרות על השרת במקום לשאת את הבחירה הנוכחית';
	@override String get resumeMusicOnLaunch => 'זכרו את ישיבת המוזיקה';
	@override String get resumeMusicOnLaunchDescription => 'פתח מחדש את השיר האחרון הפסיק איפה זה נעלם כאשר האפליקציה מתחילה';
	@override String get showChapterMarkersOnTimeline => 'הצג תוויות פרק ב- Search Bar';
	@override String get showChapterMarkersOnTimelineDescription => 'סגנון הבר החיפוש בגבולות הפרק';
	@override String get specialsOrdering => 'מיוחד בסדר פרק';
	@override String get specialsOrderingDescription => 'איפה מיוחדים משחקים בסדר השעון של מופע';
	@override String get specialsOrderingServer => 'עקבו אחרי server order';
	@override String get specialsOrderingAirDate => 'תאריכים לפי תאריך אוויר';
	@override String get specialsOrderingLast => 'אחרי עונות רגילות';
	@override String get clickVideoTogglesPlayback => 'לחצו על הווידאו כדי לשחק / לפסח';
	@override String get clickVideoTogglesPlaybackDescription => 'לחצו על וידאו כדי לשחק/פסיקה במקום להציג שליטה.';
	@override String get videoPlayerControls => 'בקרת וידאו';
	@override String get keyboardShortcuts => 'קצוות מפתח';
	@override String get keyboardShortcutsDescription => 'התאמה אישית של קצוות המקלדת';
	@override String get videoPlayerNavigation => 'וידאו Player Navigation';
	@override String get videoPlayerNavigationDescription => 'השתמש במפתחות אקדח כדי לעקוב אחר בקרת וידאו שחקן';
	@override String get watchTogetherRelay => 'צפו יחד רלי';
	@override String get watchTogetherRelayDescription => 'פסטיבל הפתיחה הציבורית מתפרסם, אלא אם כן אתה מגדיר את עצמך';
	@override String get watchTogetherRelayHint => 'https://my-relay.example.com';
	@override String get watchTogetherRelayInvalid => 'יש להזין כתובת בסיס תקינה של שרת הממסר בפרוטוקול HTTP או HTTPS.';
	@override String get crashReporting => 'דיווח תאונה';
	@override String get crashReportingDescription => 'לשלוח דיווחים על תאונות כדי לעזור לשפר את האפליקציה';
	@override String get debugLogging => 'דבק לוגינג';
	@override String get debugLoggingDescription => 'אפשרות לגישה מפורטת לפתרון בעיות';
	@override String get viewLogs => 'ראה לוג';
	@override String get viewLogsDescription => 'צפו ב-LOGS של יישום';
	@override String get clearImageCache => 'צילום Cache';
	@override String get clearImageCacheDescription => 'תמונות יכולות להעלות לאט יותר עד להורדה מחדש.';
	@override String get clearImageCacheSuccess => 'תמונת ה-Cache הוסרה בהצלחה';
	@override String get resetSettings => 'הגדרות מחדש';
	@override String get resetSettingsDescription => 'לשחזר את ההגדרות הבסיסיות.זה לא יכול להימנע.';
	@override String get resetSettingsSuccess => 'הגדרות מחדש בהצלחה';
	@override String get backup => 'גיבוי';
	@override String get exportSettings => 'הגדרות ייצוא';
	@override String get exportSettingsDescription => 'שמור את ההעדפות שלך לקובץ';
	@override String get exportSettingsSuccess => 'הגדרות ייצוא';
	@override String get importSettings => 'הגדרות ייבוא';
	@override String get importSettingsDescription => 'לשחזר העדפות מתוך קובץ';
	@override String get importSettingsConfirm => 'זה יחליף את ההגדרות הנוכחיות שלך.';
	@override String get importSettingsSuccess => 'הגדרות ייבוא';
	@override String get importSettingsInvalidFile => 'קובץ זה אינו ייצוא של הגדרות PlezyNG בתוקף';
	@override String get importSettingsNoUser => 'הקלד לפני ייבוא ההגדרות';
	@override String get cloudBackup => 'ענן גיבוי';
	@override String get cloudBackupDescription => 'גיבוי הגדרות הניתנות להעברה לנקודת קצה של WebDAV דרך HTTPS. חיבורי השרתים ופרטי ההתחברות נשארים במכשיר הזה.';
	@override String get cloudBackupUrl => 'WebDAV JSON קובץ URL';
	@override String get cloudBackupUsername => 'שם משתמש';
	@override String get cloudBackupPassword => 'סיסמה';
	@override String get cloudBackupSaved => 'Cloud Backup Destination נשמר';
	@override String get cloudBackupNow => 'בחזרה עכשיו';
	@override String get cloudBackupComplete => 'הגדרות גיבוי הועלה';
	@override String get cloudBackupRestore => 'לשחזר גיבוי';
	@override String get cloudBackupRestoreConfirm => 'זה יחליף את ההגדרות הניידות המתאימות במכשיר זה.';
	@override String get cloudBackupRestored => 'הגדרות שחוזרות מענן גיבוי';
	@override String get shortcutsReset => 'קצוות מחדש לתוך הפסקות';
	@override String get resetShortcutsConfirm => 'זה יחליף את הקצוות המותאמים אישית שלך עם הפסקות.';
	@override String get about => 'אודות';
	@override String get aboutDescription => 'מידע על אפליקציות ורישיונות';
	@override String get updates => 'עדכונים';
	@override String get updateAvailable => 'עדכון זמין';
	@override String get checkForUpdates => 'בדוק עדכונים';
	@override String get autoCheckUpdatesOnStartup => 'בדוק באופן אוטומטי עדכונים על סטארט-אפ';
	@override String get autoCheckUpdatesOnStartupDescription => 'הודעה כאשר עדכון זמין בעת ההשקה';
	@override String get validationErrorEnterNumber => 'אנא הקלד מספר תקינה';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'חייב להיות בין ${min} ו ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'קצר שנקבע כבר ל- ${action}';
	@override String shortcutUpdated({required Object action}) => 'קצר עדכון עבור ${action}';
	@override String get saveFailed => 'אני לא יכול לשמור שינויים, נסה שוב.';
	@override String get autoPlayAndSkip => 'משחק אוטומטי & Skip';
	@override String get autoPlayNextEpisode => 'משחק אוטומטי - פרק הבא';
	@override String get autoPlayNextEpisodeDescription => 'התחל את הפרק הבא באופן אוטומטי כאשר אחד נגמר';
	@override String get shuffleStartsFromBeginning => 'שושן מתחיל בהתחלה';
	@override String get shuffleStartsFromBeginningDescription => 'התחל כל פרק בהתחלה, כאשר צחצוח במקום לחזור';
	@override String get plexCinemaPreRoll => 'שימוש ב-Server Cinema';
	@override String get plexCinemaPreRollDescription => 'לשחק Plex מראש או Jellyfin ו Emby כניסות לפני הסרט מתחיל.';
	@override String get playNextCountdown => 'המשחק הבא Countdown';
	@override String get playNextCountdownImmediate => 'לשחק מיד';
	@override String get skipIntroMode => 'ספין Intro';
	@override String get skipIntroModeOffDescription => 'לשחק כניסות בדרך כלל ללא כפתור סקי';
	@override String get skipIntroModeButtonDescription => 'הצג כפתור ספיג כאשר מתחיל אינטרו';
	@override String get skipIntroModeAutoDescription => 'לגרד את הכניסה באופן אוטומטי לאחר האיחור למטה';
	@override String get skipCreditsMode => 'ספין אשראי';
	@override String get skipCreditsModeOffDescription => 'משחק אשראי בדרך כלל ללא כפתור סקי';
	@override String get skipCreditsModeButtonDescription => 'הצג כפתור ספיג כאשר ההלוואות מתחילות';
	@override String get skipCreditsModeAutoDescription => 'לגרד את הכרטיסים באופן אוטומטי ולשחק את הפרק הבא';
	@override String get skipAdsMode => 'סקי Ads';
	@override String get skipAdsModeOffDescription => 'לשחק את הפרסומות שנמצאו בדרך כלל ללא כפתור הפסקה';
	@override String get skipAdsModeButtonDescription => 'הצג כפתור ספיג כאשר Plex מזהה פרסום';
	@override String get skipAdsModeAutoDescription => 'הפעל את הפרסומות שנמצאו באופן אוטומטי לאחר האיחור למטה';
	@override String get musicPlayback => 'מוזיקה Playback';
	@override String get musicSweetFades => 'פטריות מתוקות';
	@override String get musicSweetFadesDescription => 'מוסיקה נופלת על גבולות המסלול כאשר Plex יש נתוני רעש.';
	@override String get skipMarkerModeOff => 'כבוי';
	@override String get skipMarkerModeButton => 'הצג כפתור';
	@override String get skipMarkerModeAuto => 'אוטומטית';
	@override String get forceSkipMarkerFallback => 'כוח Fallback Markers';
	@override String get forceSkipMarkerFallbackDescription => 'השתמש בדפוסים כותרת פרק גם כאשר Plex יש סימנים';
	@override String get theIntroDbFallback => 'השתמש ב-TheIntroDB כפליטה intro';
	@override String get theIntroDbFallbackDescription => 'השתמש בזמן הקהילה רק כאשר לשרת אין סימן intro.';
	@override String get autoSkipDelay => 'טיסה לטיסה מאוחרת';
	@override String autoSkipDelayDescription({required Object seconds}) => 'מחכה ${seconds} שניות לפני הפריצה עצמית';
	@override String get introPattern => 'תבנית מארק';
	@override String get introPatternDescription => 'דפוס Regex כדי להתאים את המדענים intro בשמות פרקים';
	@override String get creditsPattern => 'דוגמאות ל-Credit Marker';
	@override String get creditsPatternDescription => 'דפוס Regex כדי להתאים מדגימות אשראי בכותרות פרקים';
	@override String get prerolls => 'פרולס';
	@override String get playPrerollsBeforeMovies => 'משחקים לפני הסרטים';
	@override String get playPrerollsBeforeMoviesDescription => 'לשחק קליפ אקראי מתוך הבחירה שלך למטה לפני כל סרט.';
	@override String get prerollLibrary => 'ספריית Preroll';
	@override String get prerollLibraryNotSet => 'לא קבע';
	@override String get prerollLibraryNoneFound => 'לא נמצאו ספרייה בשרתים שלך.';
	@override String get prerollSelection => 'נבחרת פרלמנט';
	@override String get prerollSelectionPickLibraryFirst => 'בחר ספרייה קודם';
	@override String get prerollSelectionNoneSelected => 'לא נבחרו משרדים';
	@override String prerollSelectionCount({required Object count}) => '${count} נבחר';
	@override String get prerollItemPicker => 'בחר את הפרוול';
	@override String get prerollItemPickerLoadFailed => 'לא יכולתי להעלות פריטים מהספרייה הזו.';
	@override String get invalidRegex => 'חוסר ביטוי רגיל';
	@override String get regex => 'ביטוי רגיל';
	@override String get downloads => 'הורדות';
	@override String get downloadLocationDescription => 'בחר איפה לאחסן תוכן הורד';
	@override String get downloadLocationDefault => 'תצוגה של App Storage (App Storage)';
	@override String get downloadLocationCustom => 'מיקום קבוע';
	@override String get selectFolder => 'בחר קובץ';
	@override String get resetToDefault => 'מחדש למונח';
	@override String currentPath({required Object path}) => 'תגית: ${path}';
	@override String get downloadLocationChanged => 'מיקום הורדה משתנה';
	@override String get downloadLocationReset => 'הורד את המיקום מחדש ל- default';
	@override String get downloadLocationInvalid => 'תיקיה שנבחרה אינה כתובה';
	@override String get downloadLocationPickerUnavailable => 'בחירת תיקיות אינה זמינה במכשיר זה';
	@override String get downloadOnWifiOnly => 'הורד רק על Wi-Fi';
	@override String get downloadOnWifiOnlyDescription => 'מניעת הורדות כאשר נתונים סלולריים';
	@override String get autoRemoveWatchedDownloads => 'Auto-Remove צפו בהורדות';
	@override String get autoRemoveWatchedDownloadsDescription => 'הורד את ההורדות הנצפות באופן אוטומטי';
	@override String get autoDownloadContinueWatching => 'הורדה אוטומטית המשך צפייה';
	@override String get autoDownloadContinueWatchingDescription => 'שמור את הפריטים על המאגר המשך שלך הורד, ולסגור אותם ברגע שהם עוזבים את המאגר';
	@override String get downloadQuality => 'הורד איכות';
	@override String get downloadQualityDescription => 'Plex מכין עותק המופנה בקובץ ההורדה שלה. Jellyfin ו Emby טרנסקוד בזמן שהקובץ הורד; העברות הפסקות עשויות להיות נדרשות להתחיל מחדש.';
	@override String get askDownloadQualityEachTime => 'בחר איכות עבור כל הורדה';
	@override String get askDownloadQualityEachTimeDescription => 'הצג את פיקר האיכות לפני הצגת כל הורדה וידאו';
	@override String get cellularDownloadBlocked => 'הורדות חסמו על הטלפון הנייד.השתמש Wi-Fi או לשנות את ההגדרה.';
	@override String get maxVolume => 'עוצמת קול מרבית';
	@override String get maxVolumeDescription => 'לאפשר הגברת עוצמת הקול מעל 100% עבור מדיה עם קול חלש';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'נוכחות עשירה';
	@override String get discordRichPresenceDescription => 'הצג מה שאתה צופה ב- Discord';
	@override String get services => 'שירותים';
	@override String get servicesDescription => 'חיבור Trakt, MyAnimeList, Seerr, ועוד';
	@override String get manageLibrariesDescription => 'מחזירים ומסתירים ספרייה';
	@override String get companionRemoteServer => 'שרת מרחוק';
	@override String get companionRemoteServerDescription => 'תאפשר למכשירים ניידים ברשת שלך לשלוט באפליקציה זו';
	@override String get companionRemoteServerStartFailed => 'לא יכולתי להתחיל את שרת החברות';
	@override String get companionRemoteServerStopFailed => 'לא יכולתי לעצור את שרת החברות.';
	@override String get autoPip => 'צילום: Auto Picture in Picture';
	@override String get autoPipDescription => 'כניסת תמונה בתמונה באופן אוטומטי כאשר אתה עוזב את האפליקציה במהלך הצגת';
	@override String get matchContentFrameRate => 'תחרות תוכן Frame';
	@override String get matchContentFrameRateDescription => 'משחק תצוגה שיעור חידוש לתוכן וידאו';
	@override String get matchContentResolution => 'פתרון תוכן Match';
	@override String get matchContentResolutionDescription => 'הפוך את המסך להורדה המקומית של הווידאו כך הטלוויזיה שלך מתנהלת על-ידי.';
	@override String get matchRefreshRate => 'משחק ריחני ריחני';
	@override String get matchRefreshRateDescription => 'תצוגת תחרות שיעור ההתחדשות בתצוגה מלאה';
	@override String get matchDynamicRange => 'משחק דינמי Range';
	@override String get matchDynamicRangeDescription => 'הפעל את HDR עבור תוכן HDR, ולאחר מכן לחזור ל- SDR';
	@override String get displaySwitchDelay => 'דחיסה של Switch Delay';
	@override String get tunneledPlayback => 'טונל Playback';
	@override String get tunneledPlaybackDescription => 'הפעל אם HDR playback מראה וידאו שחור או תנועות סטוטרים.';
	@override String get audioPassthrough => 'אודיו פסטה';
	@override String get audioPassthroughDescription => 'שלח קול Dolby/DTS למקבל או לטלוויזיה שלך ללא הקוד מחדש, שמירה על הקול הסובב.';
	@override String get audioPassthroughDescriptionApple => 'השתמש ב-Dolby Decoder המקומי של Apple עבור Dolby Digital Plus, כולל Atmos. DTS ו-TrueHD עדיין משחקים כ-PCM רב ערוצים.';
	@override String get audioPassthroughDescriptionAppleSpatial => 'השתמש ב-Dolby Decoder המקומי של Apple עבור Dolby Digital Plus, כולל Atmos. ב- iOS, iPadOS ו- tvOS 26 או מאוחר יותר, TrueHD Atmos ו- DTS:X משחקים כאודיו חלקי.';
	@override String get audioPassthroughOverriddenByNormalization => 'כשמדובר בנורמליזציה של צליל';
	@override String get audioChannelLimit => 'ערוצי שמע';
	@override String get audioChannelLimitDescription => 'לערבב את האודיו המודפס למטה עבור שמיעה, אוזניות, או HDMI הגדרות שאינן יכולות לשחק כל ערוץ';
	@override String get audioChannelLimitOriginal => 'מקורי';
	@override String get audioChannelLimitOriginalDescription => 'לשחק בכל ערוץ בשורה';
	@override String get audioChannelLimitSurround51 => 'עד 5.1';
	@override String get audioChannelLimitSurround51Description => 'מעורב 7.1 למטה 5.1 עבור טלוויזיות ומקבלים אשר לוקחים רק 5.1 PCM.';
	@override String get audioChannelLimitStereo => 'סטריאו';
	@override String get audioChannelLimitStereoDescription => 'לערבב עד שני ערוצים עבור רמקולים סטריאו או אוזניות.';
	@override String get downmixCenterBoost => 'ערוץ שיפור ערוץ שיפור ערוץ שיפור ערוץ שיפור ערוץ שיפור ערוץ שיפור ערוץ שיפור ערוץ שיפור ערוץ שיפור ערוץ שיפור ערוץ שיפור ערוץ שיפור ערוץ שיפור ערוץ שיפור ערוץ';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'קידום (dB)';
	@override String get downmixCenterBoostShort => 'דב';
	@override String get audioDownmixNormalize => 'נורמליזת טמפרטורה על Downmix';
	@override String get audioDownmixNormalizeDescription => 'להוריד את התערובת כדי למנוע קליפ. סגור כדי לשמור על הטמפרטורה המקורית (אולי להפריע סצנות חזקות).';
	@override String get dvConversionMode => 'Dolby Vision הפוך';
	@override String get dvConversionModeDescription => 'בחר כיצד Dolby Vision פרופיל 7 קבצים מתבצעים.';
	@override String get dvConversionAuto => 'אוטומטי';
	@override String get dvConversionNative => 'נוער / נכים';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'שימוש ביכולת זיהוי המכשיר והתנהגות נורמלית';
	@override String get dvConversionNativeDescription => 'כוח מולד DV7 ומניעת DV הפוך חזרה';
	@override String get dvConversionDv81Description => 'כוח רצועה RPU הפוך ל Dolby Vision פרופיל 8.1';
	@override String get dvConversionHevcStripDescription => 'רצועה Dolby Vision שכבות RPU/EL ושטח הנוכחי HEVC';
	@override String get disableDolbyVision => 'חסר תועלת Dolby Vision';
	@override String get disableDolbyVisionDescription => 'לשחק את שכבת הקובץ HDR10 או HLG במקום Dolby Vision, כאשר יש';
	@override String get hdrSdrConversion => 'HDR ל- SDR Conversion';
	@override String get hdrSdrConversionDescription => 'בחר מה מחליף וידאו HDR כאשר המסך לא יכול להציג HDR.';
	@override String get hdrSdrConversionAuto => 'אוטומטי';
	@override String get hdrSdrConversionAutoDescription => 'מכשיר ב- Android 9 ומאוחר יותר, שחקן בגרסאות ישנות יותר';
	@override String get hdrSdrConversionDevice => 'מכשיר';
	@override String get hdrSdrConversionDeviceDescription => 'חומרה וידאו של המכשיר שלך מחליפה אותו מהיר ביותר, אבל הצבעים תלויים במכשיר';
	@override String get hdrSdrConversionPlayer => 'נגן';
	@override String get hdrSdrConversionPlayerDescription => 'צבעים עקביים, אבל 4K עשוי להסתובב על תיבות טלוויזיה ברמה נמוכה';
	@override String get deinterlace => 'דיינטראסינג';
	@override String get deinterlaceDescription => 'להסיר יצירות מעורבות מהסרטון מעורבב (mpv שחקנים בלבד)';
	@override String get deinterlaceOff => 'כבוי';
	@override String get deinterlaceOffDescription => 'הצג וידאו מעורב כפי שהוא מופשט';
	@override String get deinterlaceVideo => 'וידאו';
	@override String get deinterlaceVideoDescription => 'עבור צילום וידאו עבור טלוויזיה, כגון ספורט, חדשות, וקונצרטים';
	@override String get deinterlaceFilm => 'סרטים';
	@override String get deinterlaceFilmDescription => 'לשחזר את הקלטות המקוריות של סרטים ואנימציה טלצ\'נינג ל 29.97 fps, נפוץ על DVDs NTSC. וידאו צילום עבור סטוטרים טלוויזיה.';
	@override String get requireProfileSelectionOnOpen => 'בקשה לפרופיל באפליקציה פתוחה';
	@override String get requireProfileSelectionOnOpenDescription => 'הצג את בחירת הפרופיל בכל פעם שהאפליקציה נפתחת';
	@override String get forceTvMode => 'מצב טלוויזיה כוח';
	@override String get forceTvModeDescription => 'כוח טלוויזיה הפריסה. עבור מכשירים שאינם לזהות באופן אוטומטי.';
	@override String get startInFullscreen => 'התחל עם מסך מלא';
	@override String get startInFullscreenDescription => 'פתיחת PlezyNG במצב מסך מלא';
	@override String get exitFullscreenOnPlayerClose => 'יצוא מסך מלא על שחקן סגור';
	@override String get exitFullscreenOnPlayerCloseDescription => 'יוצא באופן אוטומטי מסך מלא בעת סגירת שחקן הווידאו';
	@override String get autoHidePerformanceOverlay => 'Auto-Hide ביצועים Overlay';
	@override String get autoHidePerformanceOverlayDescription => 'הפסד את הביצועים עם בקרת המשחקים';
	@override String get showNavBarLabels => 'הצג מפת ניווט בר תגיות';
	@override String get showNavBarLabelsDescription => 'הצג תוויות טקסט תחת סרגל הניווט';
	@override String get startupSection => 'סעיף Startup';
	@override String get preferredServer => 'מעדיפים שרתים';
	@override String get preferredServerDescription => 'עדיף את התוצאות של שרת זה תוך שמירה על כל שרת מחובר זמין.';
	@override String get preferredServerAutomatic => 'אוטומטית';
	@override String get showExploreTab => 'הצג חקר טב';
	@override String get showExploreTabDescription => 'הצג את הכרטיסייה Explore עם תוכן מ- Plex Discover and connected tracker';
	@override String get hideEmptyLibraries => 'להסתיר ספרייה ריקה';
	@override String get hideEmptyLibrariesDescription => 'להסיר ספריות עם מספר פריטים שדווח על ידי השרת של אפס מן הניווט.';
	@override String get liveTvDefaultFavorites => 'תגיות: ערוצים מועדפים';
	@override String get liveTvDefaultFavoritesDescription => 'הצג רק את הערוצים האהובים עליך בעת פתיחת הטלוויזיה חיה';
	@override String get general => 'כללי';
	@override String get generalDescription => 'שפה, סטארט-אפ ותנהגות חלון';
	@override String get languageAndRegion => 'שפה ואזור';
	@override String get startup => 'סטארטאפ';
	@override String get display => 'תצוגה';
	@override String get libraryAndCards => 'ספרייה & כרטיסים';
	@override String get homeScreen => 'Home מסך';
	@override String get navigation => 'ניווט';
	@override String get window => 'חלון';
	@override String get liveTv => 'טלוויזיה בשידור חי';
	@override String get player => 'נגן';
	@override String get videoAndDisplay => 'וידאו & תצוגה';
	@override String get audio => 'שמע';
	@override String get quality => 'איכות';
	@override String get subtitles => 'כתוביות';
	@override String get seekAndTiming => 'חיפוש & זמן';
	@override String get behavior => 'התנהגות';
	@override String get gestures => 'גישה';
	@override String get gestureBrightnessSwipe => 'אור סוויפ';
	@override String get gestureBrightnessSwipeDescription => 'סובב למעלה או למטה על הקצה השמאלי כדי להתאים את הבהירות';
	@override String get gestureVolumeSwipe => 'כמות Swipe';
	@override String get gestureVolumeSwipeDescription => 'סובב למעלה או למטה על הגבול הימני כדי להתאים את הטמפרטורה';
	@override String get gesturePinchToZoom => 'פינק ל-Zoom';
	@override String get gesturePinchToZoomDescription => 'לחצו על הווידאו כדי לזום פנימה או בחוץ';
	@override String get gestureSeekSwipe => 'חיפוש Swipe';
	@override String get gestureSeekSwipeDescription => 'סובב שמאל או ישר בכל מקום בסרטון כדי לחפש; שחרור כדי לקפוץ';
	@override String get rememberBrightnessLevel => 'זכרו את רמת הבהירות';
	@override String get rememberBrightnessLevelDescription => 'התחל את המשחק בהירות שנקבעה על-ידי הסוויפ האחרון';
	@override String get controls => 'פקדים';
	@override String get rememberPlayerChanges => 'זוכרים את השינויים של השחקנים';
	@override String get rememberPlayerChangesDescription => 'כאשר שינוי שנעשה במהלך המשחק נשמר וניתן להחיל מחדש';
	@override String get scopePlaybackSpeed => 'מהירות ניגון';
	@override String get scopeShaderPreset => 'שארד Preset';
	@override String get scopeAspectRatio => 'יחס גובה-רוחב';
	@override String get scopeSyncOffsets => 'תגית: Audio & Subtitle Sync';
	@override String get playerScopeOff => 'אל תציל';
	@override String get playerScopeGlobal => 'בכל מקום';
	@override String get playerScopeLibrary => 'לפי ספרייה';
	@override String get playerScopeTitle => 'לפי מופע או סרט';
	@override String get exportDialogTitle => 'ייצוא PlezyNG הגדרות';
	@override String get followSystem => 'לפי שפת המערכת';
	@override String get followAppLanguage => 'כמו שפת הממשק';
	@override String get regionFormat => 'תבניות אזוריות';
	@override String get regionFormatDescription => 'בחירת אופן ההצגה של תאריכים, מספרים ויחידות מידה.';
	@override String get metadataLanguage => 'שפת פרטי המדיה';
	@override String get metadataLanguageDescription => 'השפה המועדפת לשמות ולתיאורים, כשהשרת תומך בה. העדפות השמע והכתוביות מוגדרות בנפרד.';
	@override String get experimentalDolbyVision => 'Dolby Vision ניסיוני';
	@override String get experimentalDolbyVisionDescription => 'שימוש במנוע הרינדור הניסיוני של FEL בהפעלה הבאה. נדרשת בנייה נפרדת של המנוע.';
	@override String get dvExperimentUnavailableDescription => 'הניסוי הזה זמין כרגע רק ב-Linux.';
	@override String get dvCompatibilityFallback => 'חלופת תאימות';
	@override String get dvCompatibilityFallbackDescription => 'שימוש במנוע הרינדור הרגיל אם הניסוי לא מצליח להתחיל. נתוני FEL עלולים ללכת לאיבוד.';
	@override String get dvExperimentDiagnostics => 'רישום יומן לניסוי הווידאו';
	@override String get dvExperimentDiagnosticsDescription => 'הפעלת יומנים מפורטים של הנגן בהפעלה הבאה.';
}

// Path: themeEditor
class _Translations$themeEditor$he extends Translations$themeEditor$en {
	_Translations$themeEditor$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get builtIn => 'בנוי';
	@override String get presets => 'נציגים';
	@override String get custom => 'מותאם אישית';
	@override String get customEmpty => 'עדיין לא נוצר';
	@override String get editCustom => 'תגית: Edit Theme';
	@override String get editCustomDescription => 'בחר את כל הצבעים בעצמך';
	@override String get locked => 'גישה לכל החיים נדרשת';
	@override String get savedLocked => 'חסכון – זמין עם גישה לכל החיים';
	@override String get title => 'נושא מותאם';
	@override String get startFrom => 'מתחילים מ';
	@override String get startFromDescription => 'העתק את כל הצבעים מתוך נושא אחר';
	@override String get colors => 'צבעים';
	@override String get preview => 'תצוגה מקדימה';
	@override late final _Translations$themeEditor$slots$he slots = _Translations$themeEditor$slots$he._(_root);
	@override String get opacity => 'אופטימיות';
	@override String get hexHint => '#RRGGBB או #AARRGGBB';
	@override String get fromOtherThemes => 'מתוך נושאים אחרים';
	@override String swatchLabel({required Object theme, required Object color}) => '${theme} ${color}';
	@override late final _Translations$themeEditor$contrast$he contrast = _Translations$themeEditor$contrast$he._(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, מתחת ל ${minimum} המומלץ: 1';
	@override String get discardTitle => 'מתעלמים מהשינויים?';
	@override String get discardMessage => 'שינויי הצבע שלא נשמרו יאבדו.';
	@override String get discard => 'דיסקרד';
	@override String previewCardTitle({required Object number}) => 'פרק ${number}';
	@override String previewCardSubtitle({required Object minutes}) => '${minutes} דקות נותרה';
	@override String get previewSwitch => 'אוטופל';
	@override String get previewMutedText => 'הקוד השני קורא ככה';
}

// Path: search
class _Translations$search$he extends Translations$search$en {
	_Translations$search$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get hint => 'מחפשים סרטים, מופעים, מוזיקה...';
	@override String get tryDifferentTerm => 'נסה מונח חיפוש שונה';
	@override String get searchYourMedia => 'לחפש את התקשורת שלך';
	@override String get enterTitleActorOrKeyword => 'הקלד שם, שחקן או מילת מפתח';
	@override String get people => 'אנשים';
}

// Path: hotkeys
class _Translations$hotkeys$he extends Translations$hotkeys$en {
	_Translations$hotkeys$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'קצר קצר עבור ${actionName}';
	@override String get clearShortcut => 'קצר ברור';
	@override String get noShortcutSet => 'אין קצר קצר';
	@override String get currentShortcut => 'הקצר הנוכחי:';
	@override String get pressToRecord => 'בחר כדי להקליט קצר';
	@override String get recordingShortcut => 'לחץ על הקצר עכשיו';
	@override late final _Translations$hotkeys$actions$he actions = _Translations$hotkeys$actions$he._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$he extends Translations$fileInfo$en {
	_Translations$fileInfo$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'מידע קובץ';
	@override String get overview => 'סקירה כללית';
	@override String get video => 'וידאו';
	@override String get audio => 'שמע';
	@override String get subtitles => 'כתוביות';
	@override String get images => 'תמונות מעורבות';
	@override String get dataStreams => 'זרימת נתונים';
	@override String get lyrics => 'מילות השיר';
	@override String get file => 'קובץ';
	@override String get attachments => 'אטרקציות';
	@override String get delivery => 'משלוח';
	@override String versionCounter({required Object index, required Object count}) => 'גרסה ${index} של ${count}';
	@override String fileCounter({required Object index, required Object count}) => 'קובץ ${index} מתוך ${count}';
	@override String get noStreams => 'השרת לא דיווח על זרמים עבור קובץ זה.';
	@override String get copyPath => 'עותק של מסלול';
	@override String get pathCopied => 'קובץ מסלול עותק';
	@override String get codec => 'מפענח';
	@override String get codecTag => 'תגית הקודק';
	@override String get resolution => 'רזולוציה';
	@override String get codedResolution => 'פתרון קוד';
	@override String get bitrate => 'קצב סיביות';
	@override String get frameRate => 'שיעור מסגרת';
	@override String get rotation => 'סיבוב';
	@override String get comment => 'איך';
	@override String get audioDescription => 'תיאור אודיו';
	@override String get headerCompression => 'כותרת Compression';
	@override String get sidecarFile => 'קובץ Sidecar';
	@override String get transportTimestamp => 'שעות תחבורה';
	@override String get displayOffset => 'תצוגה Offset';
	@override String get previewFailureCode => 'קוד הפגיעה';
	@override String get previewRetries => 'תחזית Retries';
	@override String get aspectRatio => 'יחס גובה-רוחב';
	@override String get pixelAspectRatio => 'פיקסל Aspect Ratio';
	@override String get profile => 'פרופיל';
	@override String get level => 'רמה';
	@override String get bitDepth => 'עומק ביטים';
	@override String get pixelFormat => 'פורמט הפיקסלים';
	@override String get colorSpace => 'מרחב צבע';
	@override String get colorRange => 'מגוון צבעים';
	@override String get colorPrimaries => 'צבעים ראשיים';
	@override String get colorTransfer => 'העברת צבע';
	@override String get chromaSubsampling => 'כרומה Subsampling';
	@override String get chromaLocation => 'מיקום Chroma';
	@override String get scanType => 'סוג הסריקה';
	@override String get interlaced => 'שזור';
	@override String get anamorphic => 'אנאמורפי';
	@override String get referenceFrames => 'מסגרת התייחסות';
	@override String get dynamicRange => 'מגוון דינמי';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Dolby Vision רמה';
	@override String get dolbyVisionVersion => 'Dolby Vision גרסה';
	@override String get dolbyVisionLayers => 'Dolby Vision מדרגות';
	@override String get baseLayerCompatibility => 'תאימות בסיס';
	@override String get avcBitstream => 'זרם סיביות AVC';
	@override String get nalLengthSize => 'גודל NAL';
	@override String get scalingMatrix => 'תגיות Scaling Matrix';
	@override String get streamIdentifier => 'זיהוי זרם';
	@override String get streamIndex => 'אינדיקטור זרם';
	@override String get streamId => 'זרם ID';
	@override String get language => 'שפה';
	@override String get languageCode => 'קוד שפה';
	@override String get streamTitle => 'עקבו אחרי Track Title';
	@override String get channels => 'ערוצים';
	@override String get sampleRate => 'קצב דגימה';
	@override String get spatialAudio => 'חלל אודיו';
	@override String get textBased => 'מבוסס טקסט';
	@override String get subtitleFormat => 'פורמט Sidecar';
	@override String get provider => 'הספק';
	@override String get matchScore => 'משחק נקודות';
	@override String get externalDelivery => 'ניתן לשרת בנפרד';
	@override String get sidecarPath => 'מסע סידקר';
	@override String get sourceStream => 'עותק מתוך';
	@override String get temporary => 'זמנית';
	@override String get timeBase => 'בסיס זמן';
	@override String get overallBitrate => 'כללי Bitrate';
	@override String get path => 'נתיב';
	@override String get fileName => 'שם קובץ';
	@override String get size => 'גודל';
	@override String get totalSize => 'גודל כללי';
	@override String get container => 'מכולה';
	@override String get duration => 'משך';
	@override String get previewThumbnails => 'תגית: Thumbnails';
	@override String get previewIndex => 'Preview מדד';
	@override String get packetLength => 'אורך החבילה';
	@override String get filePresent => 'הקובץ הנוכחי';
	@override String get fileReadable => 'ניתן לקרוא על ידי שרת';
	@override String get streamPath => 'זרימת דרכים';
	@override String get optimizedForStreaming => 'אופטימיזציה עבור Streaming';
	@override String get has64bitOffsets => 'היסטים של 64 סיביות';
	@override String get protocol => 'פרוטוקול';
	@override String get mediaType => 'סוג התקשורת';
	@override String get sourceKind => 'מקור טוב';
	@override String get optimizedVersion => 'גרסה אופטימלית';
	@override String get optimizationTarget => 'מטרות אופטימיזציה';
	@override String get deletedAt => 'מוחלף';
	@override String get remoteSource => 'מקור מרחוק';
	@override String get infiniteStream => 'זרם אינסופי';
	@override String get directPlay => 'משחק ישיר';
	@override String get directStream => 'זרם ישיר';
	@override String get transcoding => 'התמרה';
	@override String get etag => 'ETag';
	@override String get versionId => 'גרסה ID';
	@override String get fileId => 'קובץ ID';
	@override String get defaultAudioTrack => 'עקבו אחרי Audio Track Audio Track';
	@override String get defaultSubtitleTrack => 'תגית: Subtitle Track';
	@override String get subtitlesOff => 'כבוי';
	@override String get flagDefault => 'ברירת מחדל';
	@override String get flagForced => 'מאולץ';
	@override String get flagSelected => 'נבחר';
	@override String get flagExternal => 'חיצוני';
	@override String get flagHearingImpaired => 'שמיעה פגום';
	@override String get flagDub => 'דב';
	@override String get flagOriginal => 'מקורי';
	@override String get channelsMono => 'מונו';
	@override String dolbyVisionProfile({required Object profile}) => 'פרופיל ${profile}';
}

// Path: mediaMenu
class _Translations$mediaMenu$he extends Translations$mediaMenu$en {
	_Translations$mediaMenu$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'מארק כפי שנצפה';
	@override String get markAsUnwatched => 'מארק כבלתי צפוי';
	@override String get removeFromContinueWatching => 'להסיר ממשיך לצפות';
	@override String get viewDetails => 'ראה פרטים';
	@override String get goToSeries => 'ללכת לסדרה';
	@override String get shufflePlay => 'שוודיה Play';
	@override String get shuffleNotAvailableOffline => 'שוודיה לא זמינה offline';
	@override String get fileInfo => 'מידע קובץ';
	@override String get deleteEpisodeFromServer => 'הורד את הפרק מהשרת';
	@override String get deleteSeasonFromServer => 'הסרת עונה מהשרת';
	@override String get deleteShowFromServer => 'הורד את ההצגה מהשרת';
	@override String get deleteMovieFromServer => 'הסרת סרטים מהשרת';
	@override String get deleteEpisodeTitle => 'תסיר את הפרק הזה?';
	@override String get deleteSeasonTitle => 'מורידים את העונה הזו?';
	@override String get deleteShowTitle => 'תסיר את ההצגה הזאת?';
	@override String get deleteMovieTitle => 'תסיר את הסרט הזה?';
	@override String get deleteEpisodeConfirm => 'מחיקת פרק';
	@override String get deleteSeasonConfirm => 'עונת הפסקה';
	@override String get deleteShowConfirm => 'הורד את המופע';
	@override String get deleteMovieConfirm => 'הורד סרט';
	@override String get deleteAnyway => 'שחרור בכל מקרה';
	@override String confirmDeleteTarget({required Object title}) => 'האם יש למחוק באופן קבוע את ${title} מהשרת שלך?';
	@override String get deleteMultipleWarning => 'זה כולל את כל הפרקים ואת הקבצים שלהם.';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n,
		one: 'פעולה זו תמחק ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} פרק מתוכו ואת הקובץ שלו.',
		other: 'פעולה זו תמחק את כל ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} הפרקים שבתוכו ואת הקבצים שלהם.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n,
		one: 'פריט זה מאוחסן ב־${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} קובץ, שיימחק.',
		other: 'פריט זה מאוחסן ב־${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} קבצים, וכולם יימחקו.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n,
		one: 'באותו קובץ מאוחסן ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} פרק נוסף, שגם הוא יימחק:',
		other: 'באותו קובץ מאוחסנים ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} פרקים נוספים, שגם הם יימחקו:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'PlezyNG לא הצליח לבדוק אילו קבצים יימחקו, ולכן ייתכן שיימחקו קבצים נוספים מעבר לפריט שצוין למעלה. אפשר לבטל ולנסות שוב, או למחוק בכל זאת.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'השרת לא סיפק פרטי קבצים עבור הפריט הזה, ולכן PlezyNG לא יכול לבדוק אילו קבצים יימחקו. ייתכן שיימחקו קבצים נוספים מעבר לפריט שצוין למעלה.';
	@override String get mediaDeletedSuccessfully => 'התקשורת הוסרה בהצלחה';
	@override String get mediaFailedToDelete => 'לא הצלחתי למחוק את התקשורת';
	@override String get rate => 'דירוג';
	@override String get playFromBeginning => 'נגן מהתחלה';
	@override String get playVersion => 'לשחק גרסה...';
}

// Path: rateSheet
class _Translations$rateSheet$he extends Translations$rateSheet$en {
	_Translations$rateSheet$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'דירוג';
	@override String get server => 'שרת';
	@override String get favorite => 'מועדף';
	@override String get favorited => 'האהוב';
	@override String get saved => 'הצלחה';
	@override String get notAvailable => 'לא נמצאו משחקים';
	@override String get noConnectedServices => 'לחבר שירות בהגדרות כדי להעריך שם.';
}

// Path: accessibility
class _Translations$accessibility$he extends Translations$accessibility$en {
	_Translations$accessibility$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, סרטים';
	@override String mediaCardShow({required Object title}) => '${title}, תוכנית טלוויזיה';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'נצפה';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} אחוז צפיות';
	@override String get mediaCardUnwatched => 'לא נצפה';
	@override String get tapToPlay => 'יש להקיש כדי לנגן';
	@override String get decrease => 'ירידה';
	@override String get increase => 'הגדלת';
	@override String decreaseValue({required Object label}) => 'ירידה ${label}';
	@override String increaseValue({required Object label}) => 'הגדלת ${label}';
	@override String get hue => 'הו';
	@override String get saturation => 'רוויה';
	@override String get brightness => 'אור';
	@override String get hexColor => 'Hex צבע';
	@override String get expandText => 'להרחיב את הטקסט';
	@override String get collapseText => 'התמוטטות טקסט';
	@override String get alphabetNavigation => 'ניווט אלפבית';
	@override String get alphabetScrollHint => 'יש להחליק למעלה או למטה כדי לנווט לפי אותיות';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'שורה ${row} מתוך ${rowCount}, עמודה ${column} מתוך ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'שורה ${row} מתוך ${rowCount}';
	@override String get autoScrollPlay => 'משחק Auto-Scroll';
	@override String get autoScrollPause => 'הפסקה אוטומטית';
	@override String get hueShort => 'H';
	@override String get saturationShort => 'S';
	@override String get valueShort => 'V';
	@override String get red => 'אדום';
	@override String get green => 'ירוק';
	@override String get blue => 'כחול';
	@override String get redShort => 'R';
	@override String get greenShort => 'G';
	@override String get blueShort => 'ב';
	@override String get colorModeHsv => 'HSV';
	@override String get colorModeRgb => 'RGB';
	@override String get title => 'גישה';
	@override String get summary => 'טקסט, קונפסט, תנועה ושליטה';
	@override String get systemHint => 'הגדרות הגישה של המכשיר שלך תמיד חל.אפשרויות אלה להוסיף התאמות לאורך PlezyNG.';
	@override String get readability => 'קריאה וראייה';
	@override String get textSize => 'גודל טקסט נוסף';
	@override String get preview => 'קרא, הקשיב והצפה בקצב שלך.';
	@override String get boldText => 'טקסט אינטראקציה';
	@override String get highContrast => 'ניגוד גבוה';
	@override String get highContrastHint => 'טקסט, קווי מתאר וסימוני מיקוד בולטים יותר על רקע בהיר או כהה.';
	@override String get interaction => 'תנועה ואינטראקציה';
	@override String get reduceMotion => 'הפחתת התנועה';
	@override String get reduceMotionHint => 'להפסיק את התנועה של סימון המיקוד, מעברי העמודים והאפקטים הדקורטיביים.';
	@override String get largeTargets => 'מטרות מגע גדולות';
	@override String get largeTargetsHint => 'להגדיל את השטח של הפקדים המשותפים כדי להקל על מגע ועל ניווט בעזרת טכנולוגיות מסייעות.';
	@override String get navigationHint => 'אפשר להשתמש ב-Tab וב-Shift+Tab כדי לעבור בין הפקדים, ב-Enter או ב-Space כדי להפעיל, וב-Escape או בכפתור החזרה כדי לסגור. כשספר פתוח, אפשר לשנות את הזום ואת העדפות הקריאה.';
}

// Path: tooltips
class _Translations$tooltips$he extends Translations$tooltips$en {
	_Translations$tooltips$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'שושן משחק';
	@override String get playTrailer => 'משחק טריילר';
	@override String get markAsWatched => 'מארק כפי שנצפה';
	@override String get markAsUnwatched => 'מארק כבלתי צפוי';
}

// Path: audioTracks
class _Translations$audioTracks$he extends Translations$audioTracks$en {
	_Translations$audioTracks$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'אודיו טרק ${n}';
}

// Path: videoControls
class _Translations$videoControls$he extends Translations$videoControls$en {
	_Translations$videoControls$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} מסגרת',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} פרמטרים',
	);
	@override String get audioLabel => 'שמע';
	@override String get subtitlesLabel => 'כתוביות';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String get letterbox => 'תיבת הדואר';
	@override String get fillScreen => 'מלא מסך';
	@override String get stretch => 'מתיחה';
	@override String get lockRotation => 'סגור סיבוב';
	@override String get unlockRotation => 'פתיחת סיבוב';
	@override String get timerActive => 'זמן פעיל';
	@override String playbackWillPauseIn({required Object duration}) => 'המשחק יפסיק ב-${duration}';
	@override String get sleepTimerEndOfVideo => 'סוף הסרטון הנוכחי';
	@override String get sleepTimerStopAtHeader => 'להפסיק';
	@override String get sleepTimerDurationHeader => 'זמן';
	@override String get playbackWillPauseAtEnd => 'Playback יפסיק בסוף הסרטון';
	@override String get stillWatching => 'עדיין לצפות?';
	@override String pausingIn({required Object seconds}) => 'הפסקה ב ${seconds}s';
	@override String get continueWatching => 'המשך';
	@override String get autoPlayNext => 'המשחק הבא';
	@override String get playNext => 'נגן את הבא';
	@override String get playButton => 'נגן';
	@override String get pauseButton => 'השהה';
	@override String get playbackPaused => 'הפסקה';
	@override String get playbackResumed => 'לשחק';
	@override String get loadingVideo => 'טעינה וידאו';
	@override String get showPlaybackControls => 'הצגת משחקים Playback';
	@override String get hidePlaybackControls => 'עקבו אחרי playback playback';
	@override String seekBackwardButton({required Object seconds}) => 'חיפוש אחורה ${seconds} שניות';
	@override String seekForwardButton({required Object seconds}) => 'חיפוש קדימה ${seconds} שניות';
	@override String get previousButton => 'פרק קודם';
	@override String get nextButton => 'הפרק הבא';
	@override String get previousChapterButton => 'הפרק הקודם';
	@override String get nextChapterButton => 'פרק הבא';
	@override String get muteButton => 'השתק';
	@override String get unmuteButton => 'ביטול השתקה';
	@override String get settingsButton => 'תגית: Playback Settings';
	@override String get tracksButton => 'אודיו & תת-כותרות';
	@override String get trackSelectionTitle => 'בחר רצועות לפני המשחק';
	@override String get trackSelectionAuto => 'בחירה אוטומטית';
	@override String get chaptersButton => 'פרק';
	@override String get versionQualityButton => 'גרסה ואיכות';
	@override String get versionColumnHeader => 'גרסה';
	@override String get qualityColumnHeader => 'איכות';
	@override String get qualityOriginal => 'מקורי';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'טרנסקוד לא זמין - לשחק באיכות מקורית';
	@override String get subtitleUnavailableFallback => 'תחתונים שנבחרו לא ניתן להעלות — המשך ללא תחתונים';
	@override String get pipButton => 'מצלמת תמונה-in-Picture';
	@override String get aspectRatioButton => 'יחס גובה-רוחב';
	@override String get ambientLighting => 'תאורה סביבתית';
	@override String get fullscreenButton => 'כניסה למסך מלא';
	@override String get exitFullscreenButton => 'יוצא מלא מסך';
	@override String get alwaysOnTopButton => 'תמיד בראש';
	@override String get rotationLockButton => 'מקלדת סיבוב';
	@override String get lockScreen => 'מסך סגור';
	@override String get screenLockButton => 'מסך סגור';
	@override String get longPressToUnlock => 'לחץ ארוך כדי לפתוח';
	@override String get timelineSlider => 'וידאו Timeline';
	@override String get volumeSlider => 'רמת נפח';
	@override String endsAt({required Object time}) => 'תגיות קשורות ${time}';
	@override String get pipActive => 'משחקים ב Picture-in-Picture';
	@override String get pipFailed => 'תמונה בתמונה לא התחילה';
	@override String get screenshotSaved => 'צילום מסך נשמר';
	@override String get screenshotFailed => 'לא יכולתי לצלם מסך';
	@override String zoomPercent({required Object percent}) => 'זום ${percent}%';
	@override String volumePercent({required Object percent}) => 'עוצמת קול ${percent}%';
	@override late final _Translations$videoControls$pipErrors$he pipErrors = _Translations$videoControls$pipErrors$he._(_root);
	@override String get chapters => 'פרק';
	@override String get noChaptersAvailable => 'אין פרקים זמינים';
	@override String get queue => 'קווי';
	@override String get noQueueItems => 'אין פריטים ב- Queue';
	@override String get noAudioDevicesAvailable => 'אין מכשירים אודיו זמינים';
	@override String get searchSubtitles => 'חיפוש תת-כותרות';
	@override String get loadSubtitleFile => 'הורד את הקובץ Subtitle';
	@override String get subtitleLoadFailed => 'לא הצלחתי להעלות את הקובץ תחת הכותרת';
	@override String get language => 'שפה';
	@override String get noSubtitlesFound => 'לא נמצאו תת-כותרות';
	@override String get subtitleDownloaded => 'Subtitle הורדה';
	@override String get subtitleDownloadedNotApplied => 'תחתון הורד, אבל לא ניתן לבחור';
	@override String get subtitleDownloadFailed => 'לא הצלחתי להוריד את התחתון';
	@override String get searchLanguages => 'חיפוש שפות';
	@override String get skipIntro => 'ספין Intro';
	@override String get skipCredits => 'ספין אשראי';
	@override String get skipAds => 'סקי Ads';
	@override String get nextEpisode => 'הפרק הבא';
	@override String subtitleTrack({required Object n}) => 'רצועה ${n}';
	@override String subtitleFile({required Object name}) => 'תגית: ${name}';
	@override String forcedTrack({required Object label}) => '${label} (החובה)';
	@override String get osdSubtitlesOff => 'תגית: Off';
	@override String osdSubtitles({required Object track}) => 'תגית: ${track}';
	@override String osdAudio({required Object track}) => 'אודיו: ${track}';
}

// Path: messages
class _Translations$messages$he extends Translations$messages$en {
	_Translations$messages$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'מסומן כפי שנצפה';
	@override String get markedAsUnwatched => 'מסומנים כבלתי צפויים';
	@override String get markedAsWatchedOffline => 'מסומן כפי שנצפה (סנכרן כאשר באינטרנט)';
	@override String get markedAsUnwatchedOffline => 'מסומן כבלתי צפוי (סנכרן כאשר באינטרנט)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'מנעול אוטומטי: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n,
		one: 'הורד את ה- ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} צפיות',
		other: 'Auto-removed ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} צפיות הורדות',
	);
	@override String get removedFromContinueWatching => 'הוסרה ממשיכה לצפות';
	@override String errorLoading({required Object error}) => 'שגיאה: ${error}';
	@override String get searchPartialResults => 'כמה שרתים מדיה לא יכול להיות מחפש. מציג תוצאות זמינות.';
	@override String get streamInterrupted => 'התנועה הופסקה, התקשורת משחקת או מנסה להחזיר.';
	@override String get liveStreamInterrupted => 'הפסקת ההפעלה הפסיקה, משחק הדו"ח נמשך.';
	@override String get fileInfoNotAvailable => 'מידע קובץ לא זמין';
	@override String get playbackAuthenticationRequired => 'היכנס שוב לשרת התקשורת כדי לשחק את הפריט הזה.';
	@override String get playbackServerUnavailable => 'השרת לא זמין, נסה שוב מאוחר יותר.';
	@override String get playbackDataInvalid => 'השרת החזיר את המידע המשחק הלא חוקי.';
	@override String get playbackCancelled => 'Playback בוטל.';
	@override String get playbackFailed => 'המשחק לא יכול להתחיל.';
	@override String playbackFailedDetail({required Object error}) => 'Playback לא יכול להתחיל: ${error}';
	@override String get audioOutputFailed => 'בדוק את חיבור הקול של הטלוויזיה או של הקבלן; אם אפליקציות אחרות גם אין קול, הפעל מחדש את המכשיר.';
	@override String get mediaUnavailable => 'תוכן זה כבר לא זמין.';
	@override String errorLoadingFileInfo({required Object error}) => 'טעות טעינה קובץ מידע: ${error}';
	@override String get errorLoadingSeries => 'שגיאות סדרת טעינה';
	@override String get musicNotSupported => 'שחקני מוסיקה עדיין לא נתמכים';
	@override String get noDescriptionAvailable => 'אין תיאור זמין';
	@override String get noProfilesAvailable => 'אין פרופיל זמין';
	@override String get contactAdminForProfiles => 'צור קשר עם מנהל השרת שלך כדי להוסיף פרופיל';
	@override String get unableToDetermineLibrarySection => 'אי אפשר לקבוע את סעיף הספרייה עבור פריט זה';
	@override String get logsCleared => 'לוגים נקיים';
	@override String get logsCopied => 'קובץ העתקה ל-Clipboard';
	@override String get noLogsAvailable => 'אין לוגים זמינים';
	@override String libraryScanning({required Object title}) => 'סריקה "${title}"';
	@override String libraryScanStarted({required Object title}) => 'סריקת הספרייה החלה עבור "${title}"';
	@override String libraryScanFailed({required Object error}) => 'לא הצליח לסרוק את הספרייה: ${error}';
	@override String metadataRefreshing({required Object title}) => 'נתונים מטא-נתונים עבור "${title}..."';
	@override String metadataRefreshStarted({required Object title}) => 'מחדש נתונים מתחיל עבור "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'לא הצליח לשחזר נתונים מטאוגרפיים: ${error}';
	@override String get logoutConfirm => 'אתה בטוח שאתה רוצה להיכנס?';
	@override String get noSeasonsFound => 'לא נמצאו עונות';
	@override String get seasonsLoadFailed => 'לא יכול להיות עונות';
	@override String get noEpisodesFound => 'לא נמצאו פרקים בעונה הראשונה';
	@override String get noEpisodesFoundGeneral => 'לא נמצאו פרקים';
	@override String get episodesLoadFailed => 'אי אפשר להעלות את הפרקים';
	@override String get noResultsFound => 'לא נמצאו תוצאות.';
	@override String sleepTimerSet({required Object label}) => 'זמן שינה מוגדר עבור ${label}';
	@override String get noItemsAvailable => 'אין פריטים זמינים';
	@override String get failedToCreatePlayQueueNoItems => 'לא הצלחתי ליצור קווי משחק - אין פריטים';
	@override String failedPlayback({required Object action, required Object error}) => 'נכשל ל ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'הפוך לשחקן תואם ...';
	@override String get serverLimitTitle => 'Playback נכשל';
	@override String get serverLimitBody => 'שגיאה בשרת (HTTP 500).גבול רוחב הפס / העברת קוד כנראה דחה את הפגישה הזו.';
	@override String get mediaUnreadableTitle => 'קובץ לא זמין';
	@override String get mediaUnreadableBody => 'השרת מצא את הפריט הזה אך לא יכול לקרוא את הקובץ שלו (HTTP 404).הקובץ כנראה הועבר, נמחק, או אחסוןו אינו מקוון.';
	@override String get serverBusyTitle => 'זרם לא זמין';
	@override String get serverBusyBody => 'השרת סירב לשדר את הקובץ הזה (HTTP 503).הוא עשוי להיות מחדש, עסוק, או אחסון הקובץ עשוי להיות לא מקוון.תנסה שוב ברגע - אם זה ממשיך לקרות, לבקש מהבעלים של השרת לבדוק את השרת ואת אחסון הקובץ.';
	@override String get playbackNotAllowedTitle => 'Playback לא מותר';
	@override String get playbackNotAllowedBody => 'השרת סירב להזרים את הפריט הזה (HTTP 403). ייתכן שלחשבון שלך אין הרשאה לנגן אותו, או שהשרת מאפשר ניגון רק ברשת המקומית שלו.';
	@override String get logsUploaded => 'לוגים הועלו';
	@override String get logsUploadFailed => 'לא הצלחתי להעלות לוגו';
	@override String get logId => 'לוג ID';
	@override String get burnedSubtitlesUseMenu => 'תת-כותרות נשרפות לתוך זרם זה.שינוי אותם מן התפריט תת-כותרות.';
	@override String get noVideoUrl => 'אין URL וידאו';
	@override String get playbackNoMediaSources => 'השרת לא החזיר מקורות מדיה משחק';
	@override String get playbackDataNotPrepared => 'Playback התחיל לפני שהנתונים שלו היו מוכנים';
	@override String get streamSelectionUnavailable => 'בחירת זרם אינה זמינה למקור זה';
	@override String get streamSelectionFailed => 'לא ניתן להשתמש בתהליכים שנבחרו';
	@override String get trackSelectionNotRemembered => 'בחירה זו חל רק על המשחק הנוכחי.';
	@override String get serverUnavailableForProfile => 'אין שרתים זמינים עבור הפרופיל הפעיל';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$he extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get previewSample => 'החתול הצהוב המהיר קופץ מעל הכלב המטומטם';
	@override String get text => 'טקסט';
	@override String get border => 'הגבול';
	@override String get background => 'רקע';
	@override String get fontSize => 'גודל הפורט';
	@override String get textColor => 'צבע טקסט';
	@override String get borderSize => 'גבול גודל';
	@override String get borderColor => 'גבול צבע';
	@override String get backgroundOpacity => 'רקע Opacity';
	@override String get backgroundColor => 'צבע רקע';
	@override String get position => 'עמדה';
	@override String get assOverride => 'ASS סה"כ';
	@override String get overrideScale => 'סולם';
	@override String get overrideForce => 'כוח';
	@override String get overrideStrip => 'להסיר סגנון';
	@override String get positionTop => 'Top';
	@override String get positionBottom => 'תחתון';
	@override String get useMargins => 'שימוש במגוון';
	@override String get useMarginsDescription => 'מותר תת-טקסטים בחלל מחוץ לווידאו.תת-טקסטים בסגנון יכולים לשמור על המיקום המקורי שלהם.';
	@override String get anchorToScreen => 'אנקור לסרטון';
	@override String get anchorToScreenDescription => 'הצג תת-כותרות טקסט בשורות שחורות מתחת לווידאו עם מסך רחב';
	@override String get bold => 'מודגש';
	@override String get italic => 'איטלקית';
	@override String get renderResolution => 'רנדה פתרון';
	@override String get renderResolutionScreen => 'רזולוציית מסך';
	@override String get renderResolutionVideo => 'רזולוציית הוידיאו';
}

// Path: mpvConfig
class _Translations$mpvConfig$he extends Translations$mpvConfig$en {
	_Translations$mpvConfig$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'הגדרות מתקדמות של שחקן וידאו';
	@override String get presets => 'נציגים';
	@override String get noPresets => 'אין חסד';
	@override String get saveAsPreset => 'שמור את זה כראשון...';
	@override String get presetName => 'שמות מראש';
	@override String get presetNameHint => 'הקלד שם עבור הפוסט הזה';
	@override String get loadPreset => 'משקל';
	@override String get deletePreset => 'מחק';
	@override String get presetSaved => 'הנסיך הציל';
	@override String get presetLoaded => 'מראש מחוברים';
	@override String get presetDeleted => 'כתיבה מוחלפת';
	@override String get confirmDeletePreset => 'האם אתה בטוח שאתה רוצה למחוק את הפוסט הזה?';
	@override String get configPlaceholder => 'gpu-api=vulkan hwdec=auto # comment';
	@override String get lineHint => 'option=value';
	@override String get addLine => 'להוסיף קו';
	@override String get removeLine => 'להסיר קו';
	@override String get embeddedVoHint => 'vo, gpu-context ו- gpu-api מתעלמים ב- Linux: וידאו מובנה תמיד משוחרר דרך vo=libmpv על מטוס הווידאו, ו- gpu-next (מה צללים מחשב כמו ArtCNN צריך) לא יכול לרוץ מובנה.';
}

// Path: dialog
class _Translations$dialog$he extends Translations$dialog$en {
	_Translations$dialog$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'אישור פעולה';
}

// Path: profiles
class _Translations$profiles$he extends Translations$profiles$en {
	_Translations$profiles$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'הוסף פרופיל PlezyNG';
	@override String get switchingProfile => 'הפרופיל המשתנה';
	@override String get deleteThisProfileTitle => 'מורידים את הפרופיל הזה?';
	@override String deleteThisProfileMessage({required Object displayName}) => 'הסר ${displayName}.החיבור אינו מושפע.';
	@override String get active => 'פעיל';
	@override String get manage => 'ניהול';
	@override String get delete => 'מחק';
	@override String get signOut => 'התנתק';
	@override String get signOutPlexTitle => 'נרשם על ידי Plex?';
	@override String signOutPlexMessage({required Object displayName}) => 'להסיר ${displayName} וכל Plex משתמשי הבית?';
	@override String get signOutPlexDeleteDownloads => 'הורד גם הורדות';
	@override String get signOutPlexDeleteDownloadsDescription => 'אחרת הם יישארו על המכשיר הזה ויחזרו כאשר אתה מחדש להיכנס לחשבון זה.';
	@override String get signedOutPlex => 'נחתם על ידי Plex.';
	@override String get signOutFailed => 'הצהרת כישלון';
	@override String get sectionTitle => 'פרופיל';
	@override String get summarySingle => 'הוספת פרופילים כדי לערבב משתמשים המנוהלים וזהות מקומית';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} פרופילים · פעיל: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} פרופיל';
	@override String get removeConnectionTitle => 'להסיר את הקשר?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'הסר את הגישה של ${displayName} ל- ${connectionLabel}. פרופילים אחרים שמרו את זה.';
	@override String get deleteProfileTitle => 'מחיקת פרופיל ?';
	@override String deleteProfileMessage({required Object displayName}) => 'להסיר את ${displayName} ואת החיבורים שלו. השרתים יישארו זמינים.';
	@override String get profileNameLabel => 'שם פרופיל';
	@override String get pinProtectionLabel => 'הגנה PIN';
	@override String get copyAutomationLink => 'עותק Android קישור אוטומציה';
	@override String get copyAutomationLinkDescription => 'בחר את הפרופיל הזה מתוך כוונה או אוטומציה Android.';
	@override String get automationLinkCopied => 'פרופיל אוטומציה קישור עותק.';
	@override String get pinManagedByPlex => 'PIN מנוהל על ידי Plex. Edit on plex.tv.';
	@override String get noPinSetEditOnPlex => 'כדי לבקש אחד, לערוך את המשתמש המקומי ב plex.tv.';
	@override String get setPin => 'פין';
	@override String get setPinTitle => 'פין';
	@override String get confirmPinTitle => 'אישור PIN';
	@override String get pinSet => 'פין Set';
	@override String get changePin => 'שינוי';
	@override String get removePin => 'הסר';
	@override String get connectionsLabel => 'קישורים';
	@override String get add => 'הוספה';
	@override String get deleteProfileButton => 'הורד פרופיל';
	@override String get noConnectionsHint => 'אין קישורים – הוסף אחד כדי להשתמש בפרופיל זה.';
	@override String get noConnections => 'אין קשרים';
	@override String get plexHomeAccount => 'Plex חשבון הבית';
	@override String plexAccountChip({required Object account}) => 'Plex חשבון: ${account}';
	@override String plexAccountUserChip({required Object user, required Object account}) => '${user} דרך ${account}';
	@override String get connectionDefault => 'ברירת מחדל';
	@override String connectionAs({required Object displayName}) => 'תגית: ${displayName}';
	@override String get makeDefault => 'לעשות דפדפן';
	@override String get removeConnection => 'הסר';
	@override String get profileRenamed => 'הפרופיל מחדש';
	@override String borrowAddTo({required Object displayName}) => 'הוסף ל ${displayName}';
	@override String get borrowExplain => 'להשאיל את החיבור של פרופיל אחר. פרופילים מוגנים ב-PIN דורשים PIN.';
	@override String get borrowEmpty => 'אין עוד מה להשאיל.';
	@override String get borrowEmptySubtitle => 'התחבר Plex, Jellyfin, או Emby לפרופיל אחר קודם.';
	@override String get borrowLoadFailed => 'לא ניתן להעלות את הקשרים הזמינים, נסה שוב.';
	@override String borrowFromProfile({required Object displayName}) => 'מתוך ${displayName}';
	@override String get borrowConnectionBorrowed => 'חיבור הלוואה';
	@override String get borrowFailed => 'לא הצלחתי להשאיל קשר.';
	@override String get incorrectPin => 'PIN לא נכון';
	@override String get incorrectPinTryAgain => 'שגיאה ב-PIN, בבקשה תנסה שוב';
	@override String get sourceProfileMissingParentAccount => 'פרופיל המקור חסר את חשבון הוריו.';
	@override String get failedToLoadHomeUsers => 'לא יכול להעלות את המשתמשים הבית Plex .בדוק את החיבור שלך ולנסות שוב.';
	@override String get failedToVerifyPin => 'לא הצלחתי לבדוק את ה-PIN.';
	@override String get newProfile => 'פרופיל חדש';
	@override String get profileNameHint => 'דוגמה: אורחים, ילדים, חדרי משפחה';
	@override String get pinProtectionOptional => 'הגנה PIN (אופציונלית)';
	@override String get pinExplain => 'יש צורך ב-PIN 4 דיגיטלי כדי לשנות את הפרופיל.';
	@override String get continueButton => 'המשך';
	@override String get pinsDontMatch => 'PINs לא מתאימים';
	@override String get tokenIdentityMismatch => 'טוקן הפרופיל Plex נפתרה לשרת בלתי צפוי';
	@override String get settingsLocked => 'הגדרות נעולות עבור פרופיל זה.';
	@override String get unlockSettings => 'פתיחת הגדרות';
	@override String get showExploreForProfile => 'הצג חקר עבור פרופיל זה';
	@override String get showExploreForProfileDescription => 'סגור כדי להסיר Explore מן הניווט של פרופיל זה.';
}

// Path: connections
class _Translations$connections$he extends Translations$connections$en {
	_Translations$connections$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'קישורים';
	@override String get addConnection => 'להוסיף חיבור';
	@override String get addConnectionSubtitleNoProfile => 'היכנס עם Plex או להתחבר לשרת Jellyfin או Emby';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'הוסף ל- ${displayName}: Plex, Jellyfin, Emby, או חיבור פרופיל אחר';
	@override String sessionExpiredOne({required Object name}) => 'הפגישה נגמרה עבור ${name}';
	@override String sessionExpiredMany({required Object count}) => 'הפגישה נגמרה עבור ${count} שרתים';
	@override String accessDeniedOne({required Object name}) => '${name} סירב גישה לחשבון זה';
	@override String accessDeniedMany({required Object count}) => '${count} שרתים סירבו לגשת לחשבון זה';
	@override String get signInAgain => 'הצטרפו שוב';
	@override String editMediaBrowserTitle({required Object product}) => 'תגית: Edit ${product} connection';
	@override String editMediaBrowserIntro({required Object serverName}) => 'הוספת או הסרת כתובת URL עבור ${serverName}. PlezyNG ישתמש כתובת URL הנגיעה עם הריבית הנמוכה ביותר.';
}

// Path: accountPreferences
class _Translations$accountPreferences$he extends Translations$accountPreferences$en {
	_Translations$accountPreferences$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'העדפות חשבון';
	@override String hubSubtitleSingle({required Object account}) => 'אפשרויות אודיו, תת-כותרת וספריה נשמרו ב- ${account}';
	@override String hubSubtitleMultiple({required Object count}) => 'אפשרויות אודיו, תת-כותרת וספריה מאוחסנות על ${count} חשבונות';
	@override String get pickAccount => 'כל חשבון מחזיק את ההעדפות שלו.קח את אחד כדי לערוך.';
	@override String get storedOnAccount => 'אפשרויות אלה מאוחסנות בחשבון עצמו, ולכן כל אפליקציה שנרשמה אליו משתמשת בהן – כולל PlezyNG במכשירים האחרים שלך.';
	@override String get noAccounts => 'אין חשבונות להגדיר';
	@override String get noAccountsHint => 'היכנס ל- Plex, או להתחבר ל- Jellyfin או ל- Emby שרת, וההעדפות שנשמרו בחשבון זה מופיעות כאן.';
	@override String get unavailable => 'לא ניתן להגיע לחשבון זה';
	@override String get loadFailed => 'לא ניתן להעלות את ההעדפות האלה';
	@override String get noPreference => 'אין עדיפות';
	@override String get notSet => 'לא קבע';
	@override late final _Translations$accountPreferences$groups$he groups = _Translations$accountPreferences$groups$he._(_root);
	@override String get preferredAudioLanguage => 'שפת קול מועדפת';
	@override String get autoSelectAudio => 'בחר אודיו לפי שפה';
	@override String get autoSelectAudioDescription => 'מחוץ לשמור כל אודיו מעקב את הקובץ מסמן כברירת מחדל.';
	@override String get preferredSubtitleLanguage => 'שפת כתוביות מועדפת';
	@override String get subtitleMode => 'הפוך את התחתונים';
	@override late final _Translations$accountPreferences$subtitleModes$he subtitleModes = _Translations$accountPreferences$subtitleModes$he._(_root);
	@override String get subtitleAccessibility => 'תגיות SDH';
	@override late final _Translations$accountPreferences$subtitleAccessibilityOptions$he subtitleAccessibilityOptions = _Translations$accountPreferences$subtitleAccessibilityOptions$he._(_root);
	@override String get forcedSubtitles => 'כפייתי תחתונים';
	@override late final _Translations$accountPreferences$forcedSubtitleOptions$he forcedSubtitleOptions = _Translations$accountPreferences$forcedSubtitleOptions$he._(_root);
	@override String get displayMissingEpisodes => 'הצג אירועים חסרים';
	@override String get displayMissingEpisodesDescription => 'רשימה של פרקים ששרת יודע על אבל אין קבצים עבור.';
	@override String get hidePlayedInLatest => 'הסתיר פריטים שנצפו בחדשות האחרונות';
	@override String get hidePlayedInLatestDescription => 'השאירו פריטים שכבר צפיתם מחוץ לשורות האחרונות של השרת.';
	@override String get displayCollectionsView => 'הצג את הצג האוסף';
	@override String get displayCollectionsViewDescription => 'מציעים את תצוגת הקולקציות של השרת לצד הספרייה שלך.';
	@override String get rewatchingInNextUp => 'להמשיך את ההופעות שנצפו מחדש ב- Next Up';
	@override String get rewatchingInNextUpDescription => 'ברגע שאתה מסיים את ההצגה, להתחיל מחדש, ו Next Up עוקב אחר ההצגה מחדש במקום להוריד את ההצגה.';
	@override String get watchedIndicator => 'אינדיקטורים שנצפו';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$he watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$he._(_root);
	@override String get mediaReviewsVisibility => 'דירוג & ביקורות';
	@override late final _Translations$accountPreferences$mediaReviewsOptions$he mediaReviewsOptions = _Translations$accountPreferences$mediaReviewsOptions$he._(_root);
}

// Path: discover
class _Translations$discover$he extends Translations$discover$en {
	_Translations$discover$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'גילוי';
	@override String get noContentAvailable => 'אין תוכן זמין';
	@override String get addMediaToLibraries => 'הוסף כמה מדיה לספריות שלך';
	@override String get continueWatching => 'המשך צפייה';
	@override String continueWatchingIn({required Object library}) => 'להמשיך לצפות ב ${library}';
	@override String get nextUp => 'הבא בתור';
	@override String nextUpIn({required Object library}) => 'תגיות קשורות ${library}';
	@override String get recentlyAdded => 'אחרון';
	@override String recentlyAddedIn({required Object library}) => 'הוספת לאחרונה ב ${library}';
	@override String latestAlbumsIn({required Object library}) => 'האלבומים האחרונים ב- ${library}';
	@override String recentlyPlayedIn({required Object library}) => 'שחק לאחרונה ב ${library}';
	@override String mostPlayedIn({required Object library}) => 'הכי משחק ב ${library}';
	@override String playEpisode({required Object season, required Object episode}) => 'ע${season} פ${episode}';
	@override String get overview => 'סקירה כללית';
	@override String get cast => 'קסט';
	@override late final _Translations$discover$findNext$he findNext = _Translations$discover$findNext$he._(_root);
	@override String get extras => 'טריילר & Extras';
	@override String get studio => 'סטודיו';
	@override String get rating => 'דירוג';
	@override String get director => 'במאי';
	@override String get directors => 'במאים';
	@override String get movie => 'סרט';
	@override String get tvShow => 'תוכנית טלוויזיה';
	@override String minutesLeft({required Object minutes}) => '${minutes} דקות נותרה';
	@override String get moreLikeThis => 'עוד כמו זה';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} כותרת',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} כותרות',
	);
	@override late final _Translations$discover$person$he person = _Translations$discover$person$he._(_root);
}

// Path: errors
class _Translations$errors$he extends Translations$errors$en {
	_Translations$errors$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'חיפוש לא הצליח: ${error}';
	@override String get searchUnavailable => 'החיפוש לא יכול להגיע לשירותי התקשורת.';
	@override String connectionTimeout({required Object context}) => 'זמן חיבור בזמן הטעינה ${context}';
	@override String get connectionFailed => 'אי אפשר להתחבר לשרת מדיה';
	@override String unableToLoad({required Object context}) => 'אין אפשרות להעלות ${context}.';
	@override String get noClientAvailable => 'אין לקוחות זמינים';
	@override String get pleaseEnterToken => 'אנא הקלד טוקן';
	@override String get invalidToken => 'טוקיו חסר תועלת';
	@override String failedToVerifyToken({required Object error}) => 'לא ניתן לבדוק טוקן: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'לא הצלחתי לעבור ל- ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'לא הצלחתי למחוק ${displayName}';
	@override String get failedToRate => 'לא ניתן לשדרג את הדירוג';
	@override String get reasonTimedOut => 'הקשר נעלם בזמן';
	@override String get reasonUnreachable => 'לא ניתן להגיע לשרת';
	@override String get reasonRefused => 'המשתמש דחה את הבקשה';
	@override String get reasonNotFound => 'המוצר כבר לא נמצא בשרת.';
	@override String get reasonServerError => 'השרת מצא שגיאה';
	@override String get reasonCancelled => 'הבקשה בוטלה';
	@override String get reasonUnexpected => 'שגיאה בלתי צפויה התרחשה';
}

// Path: libraries
class _Translations$libraries$he extends Translations$libraries$en {
	_Translations$libraries$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => 'צפו בסרט אקראי';
	@override String get randomPickFailed => 'לא יכולתי לבחור סרט אקראי מהספרייה הזאת.';
	@override String get title => 'ספריות';
	@override String get fallbackTitle => 'ספרייה';
	@override String get scanLibraryFiles => 'סריקת קבצים ספרייה';
	@override String get scanLibrary => 'סרוק ספרייה';
	@override String get analyze => 'ניתוח';
	@override String get analyzeLibrary => 'ניתוח הספרייה';
	@override String get refreshMetadata => 'רענון מטא-דאטה';
	@override String get emptyTrash => 'ריק טראש';
	@override String emptyingTrash({required Object title}) => 'פטריות ריקות עבור "${title}..."';
	@override String trashEmptied({required Object title}) => 'תגיות קשורות "${title}"';
	@override String failedToEmptyTrash({required Object error}) => 'לא הצליח לשפוך את השחיתות ריקה: ${error}';
	@override String analyzing({required Object title}) => 'תגית: ${title}';
	@override String analysisStarted({required Object title}) => 'ניתוח מתחיל עבור "${title}"';
	@override String failedToAnalyze({required Object error}) => 'לא הצליח לנתח ספרייה: ${error}';
	@override String get noLibrariesFound => 'לא נמצאו ספרייה';
	@override String get allLibrariesHidden => 'כל הספרייה מסתתרת';
	@override String hiddenLibrariesCount({required Object count}) => 'ספריות מוסתרים (${count})';
	@override String get thisLibraryIsEmpty => 'הספרייה הזאת ריקה';
	@override String get noItemsMatchFilters => 'אין פריטים המתאימים לסנרטורים פעילים';
	@override String get resetFilters => 'איפוס מסננים';
	@override String get all => 'הכול';
	@override String get clearAll => 'ברור הכל';
	@override String scanLibraryConfirm({required Object title}) => 'האם אתה בטוח שאתה רוצה לסרוק "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => 'האם אתה בטוח שאתה רוצה לנתח "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => 'האם אתה בטוח שאתה רוצה לשדרג את הנתונים המטאוגרפיים עבור "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'האם אתה בטוח שאתה רוצה לשחרר את השטויות עבור "${title}"?';
	@override String get manageLibraries => 'ניהול ספרייה';
	@override String get sort => 'מיון';
	@override String get sortBy => 'מיין לפי';
	@override String get filters => 'מסננים';
	@override String get confirmActionMessage => 'האם אתה בטוח שאתה רוצה לבצע את הפעולה הזאת?';
	@override String get showLibrary => 'מציג ספרייה';
	@override String get hideLibrary => 'להסתיר את הספרייה';
	@override String get libraryOptions => 'אפשרויות ספרייה';
	@override String get content => 'ספרייה תוכן';
	@override String get selectLibrary => 'בחר ספרייה';
	@override String filtersWithCount({required Object count}) => 'מסננים (${count})';
	@override String get noRecommendations => 'אין המלצות זמינות';
	@override String get noCollections => 'אין אוסף בספריה זו';
	@override String get noFoldersFound => 'לא נמצאו קבצים';
	@override String get folders => 'תיקיות';
	@override late final _Translations$libraries$tabs$he tabs = _Translations$libraries$tabs$he._(_root);
	@override late final _Translations$libraries$groupings$he groupings = _Translations$libraries$groupings$he._(_root);
	@override late final _Translations$libraries$filterCategories$he filterCategories = _Translations$libraries$filterCategories$he._(_root);
	@override late final _Translations$libraries$sortLabels$he sortLabels = _Translations$libraries$sortLabels$he._(_root);
	@override late final _Translations$libraries$advancedFilters$he advancedFilters = _Translations$libraries$advancedFilters$he._(_root);
	@override late final _Translations$libraries$selection$he selection = _Translations$libraries$selection$he._(_root);
}

// Path: about
class _Translations$about$he extends Translations$about$en {
	_Translations$about$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'אודות';
	@override String get openSourceLicenses => 'רישיונות קוד פתוח';
	@override String versionLabel({required Object version}) => 'גרסה ${version}';
	@override String get appDescription => 'לקוח יפה Plex, Jellyfin, ו Emby עבור Flutter';
	@override String get viewLicensesDescription => 'ראה רישיונות של ספריות של צד שלישי';
	@override String get privacyPolicy => 'מדיניות פרטיות';
}

// Path: serverSelection
class _Translations$serverSelection$he extends Translations$serverSelection$en {
	_Translations$serverSelection$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'לא נמצאו שרתים עבור ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'שרתים לא מצליחים להעלות: ${error}';
	@override String get noValidServers => 'לא נמצאו שרתים שימושיים בחשבון זה';
}

// Path: hubDetail
class _Translations$hubDetail$he extends Translations$hubDetail$en {
	_Translations$hubDetail$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'כותרת';
	@override String get releaseYear => 'שנת שחרור';
	@override String get dateAdded => 'תאריך הוספה';
	@override String get rating => 'דירוג';
	@override String get noItemsFound => 'לא נמצאו פריטים';
}

// Path: logs
class _Translations$logs$he extends Translations$logs$en {
	_Translations$logs$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'לוג ברור';
	@override String get copyLogs => 'לוגו לוגו';
	@override String get uploadLogs => 'להעלות לוג';
	@override String get saveLogs => 'שמור לוגים ל-File';
	@override String logsSaved({required Object path}) => 'רשומות שנשמרו ל- ${path}';
	@override String get saveLogsFailed => 'לא הצלחתי לשמור את קובץ ה-LOG.';
}

// Path: detail
class _Translations$detail$he extends Translations$detail$en {
	_Translations$detail$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => 'תגיות קשורות ${time}';
}

// Path: startup
class _Translations$startup$he extends Translations$startup$en {
	_Translations$startup$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'PlezyNG לא יכול להתחיל';
	@override String get failedBody => 'משהו לא בסדר במהלך ההתחלה.הפרטים למטה מזהים מה נכשל.';
	@override String get failedBodyRepairable => 'קובץ ההגדרות השמור של PlezyNG פגום וצריך ליצור אותו מחדש לפני שהיישום יוכל לפעול. ניסיון נוסף לא יעזור — יש לבחור בתיקון האחסון.';
	@override String get phaseLabel => 'צעד';
	@override String get showDetails => 'הצג פרטים';
	@override String get hideDetails => 'להסתיר פרטים';
	@override String get copyDetails => 'עותק פרטים';
	@override String get detailsCopied => 'פרטים מפורטים ב-Clipboard';
	@override String get uploadDetails => 'להעלות פרטים';
	@override String get repairStorage => 'תיקון אחסון';
	@override String get repairTitle => 'לתקן את הנתונים שנשמרו?';
	@override String get repairBodyCommon => 'קובץ ההגדרות של PlezyNG פגום ולא ניתן לקרוא אותו. התיקון מאפס את כל ההגדרות לברירות המחדל.';
	@override String get repairBodyOneCredential => 'אחד מפרטי ההתחברות השמורים פגום ולא ניתן לקרוא אותו. התיקון מסיר רק אותו; שאר ההגדרות נשארות ללא שינוי.';
	@override String get repairBodySignInsKept => 'ההתחברות לשרתים ולפרופילים אמורה להישמר.';
	@override String get repairBodySignInsLost => 'לא ניתן לשחזר מהקובץ הזה את המפתח שמגן על פרטי ההתחברות השמורים, ולכן יהיה צורך להתחבר שוב לכל שרת ופרופיל. דבר בשרת המדיה לא יושפע.';
	@override String get repairBodySessionsUncertain => 'הנתונים של שירותי המעקב (MAL, AniList, Simkl, Trakt) ושל Seerr נשמרים בנפרד, וייתכן שיישמרו וייתכן שלא. PlezyNG יציג בדיוק מה נשמר.';
	@override String get repairConfirm => 'תיקון';
	@override String get repairSucceeded => 'אחסון מתוקן';
	@override String get repairNeedsRestart => 'תיקון אחסון – מחדש נדרש';
	@override String get restartRequiredBody => 'הנתונים שלך תוקנו, אך צריך להפעיל מחדש את PlezyNG כדי להשתמש בהם. יש לסגור את PlezyNG ולפתוח אותו שוב.';
	@override String get quitPlezy => 'סה"כ PlezyNG';
	@override String get repairFailed => 'תיקון נכשל';
	@override String get repairKeptSignIns => 'ההתחברות לשרתים ולפרופילים עדיין פעילה.';
	@override String get repairLostSignIns => 'לא ניתן לשחזר את המפתח שמגן על פרטי ההתחברות השמורים. יהיה צורך להתחבר שוב לכל שרת ופרופיל.';
	@override String get repairLostSessions => 'לפחות אחד מעקב או חיבור Seerr אבד וצריך להתחבר מחדש.';
	@override String get backupTitle => 'עותק של הקובץ הנגוע נשמר';
	@override String get backupWarning => 'העותק מכיל את פרטי ההתחברות שלך. אין להעלות או לשתף אותו.';
	@override String get deleteBackup => 'הורד עותק';
	@override String get backupDeleted => 'עותק מוחלף';
	@override String get previousFailureTitle => 'PlezyNG לא התחיל בפעם האחרונה';
}

// Path: licenses
class _Translations$licenses$he extends Translations$licenses$en {
	_Translations$licenses$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'חבילות קשורות';
	@override String get license => 'רישיון';
	@override String licenseNumber({required Object number}) => 'רישיון ${number}';
	@override String licensesCount({required Object count}) => '${count} רישיונות';
}

// Path: navigation
class _Translations$navigation$he extends Translations$navigation$en {
	_Translations$navigation$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'ספריות';
	@override String get downloads => 'הורדות';
	@override String get liveTv => 'טלוויזיה בשידור חי';
	@override String get explore => 'לחקור';
}

// Path: explore
class _Translations$explore$he extends Translations$explore$en {
	_Translations$explore$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$explore$mdblistShelves$he mdblistShelves = _Translations$explore$mdblistShelves$he._(_root);
	@override String get title => 'לחקור';
	@override String get selectSource => 'בחר מקור';
	@override late final _Translations$explore$rows$he rows = _Translations$explore$rows$he._(_root);
	@override late final _Translations$explore$status$he status = _Translations$explore$status$he._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} פרק',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} פרקים',
	);
	@override String get cast => 'קסט';
	@override String get characters => 'דמויות';
	@override String get addToWatchlist => 'הוסף ל Watchlist';
	@override String get removeFromWatchlist => 'להסיר מ- Watchlist';
	@override String get addedToWatchlist => 'הוספת ל watchlist';
	@override String get removedFromWatchlist => 'הוסרה מ- watchlist';
	@override String get watchlistUpdateFailed => 'לא ניתן לשדרג את רשימת השמועות';
	@override String get watchlistNoMatch => 'לא יכולתי להתאים את הפריט הזה לרשימת שומרים';
	@override String get notInLibrary => 'לא בספריה שלך';
	@override String get inTheseLibraries => 'בספריות אלה';
	@override String get checkingLibrary => 'בדוק את הספרייה שלך';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n,
		one: 'לא ניתן לבדוק את השרת ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}',
		other: 'לא ניתן לבדוק את השרתים ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}',
	);
	@override String get emptyTitle => 'שום דבר כאן עדיין';
	@override String emptyMessage({required Object source}) => 'שורות מ- ${source} יופיעו כאן ברגע שיש להם תוכן.';
	@override String searchHint({required Object source}) => 'חיפוש ${source}';
	@override String searchEmpty({required Object query}) => 'אין תוצאות עבור "${query}"';
	@override String searchPrompt({required Object source}) => 'לחפש סרטים ותצוגות ב- ${source}.';
	@override String get searchFailed => 'החיפוש נכשל, בדוק את החיבור שלך ונסו שוב.';
	@override late final _Translations$explore$badge$he badge = _Translations$explore$badge$he._(_root);
	@override late final _Translations$explore$stats$he stats = _Translations$explore$stats$he._(_root);
	@override late final _Translations$explore$season$he season = _Translations$explore$season$he._(_root);
	@override late final _Translations$explore$format$he format = _Translations$explore$format$he._(_root);
	@override late final _Translations$explore$sourceMaterial$he sourceMaterial = _Translations$explore$sourceMaterial$he._(_root);
	@override late final _Translations$explore$creditRole$he creditRole = _Translations$explore$creditRole$he._(_root);
	@override late final _Translations$explore$relation$he relation = _Translations$explore$relation$he._(_root);
	@override String broadcast({required Object day, required Object time}) => 'איירס ${day} ב- ${time}';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => 'איירס ${day} ב- ${time} ${timezone}';
	@override late final _Translations$explore$detail$he detail = _Translations$explore$detail$he._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} תוצאות',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} תוצאות',
	);
}

// Path: liveTv
class _Translations$liveTv$he extends Translations$liveTv$en {
	_Translations$liveTv$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'טלוויזיה בשידור חי';
	@override String get guide => 'מדריך';
	@override String get noChannels => 'אין ערוצים זמינים';
	@override String get noDvr => 'אין DVR מוגדר על כל שרת';
	@override String get serverUnavailable => 'שרת טלוויזיה חי אינו זמין.';
	@override String get serverNotConnected => 'שרת הטלוויזיה החי אינו מחובר.';
	@override String get noPrograms => 'אין נתוני תוכנית זמינים';
	@override String get liveStreamFailed => 'Live Stream נכשל';
	@override String get unknownProgram => 'תוכנית לא ידועה';
	@override String get timelineLiveProgram => 'תוכנית חיה (תוכנית משחק עשויה להיות מחוץ לתוכנית זו)';
	@override String get timelineBuffer => 'לוח זמנים של בופר';
	@override String get timelineUnavailable => 'לוח זמנים לא זמין';
	@override String get timelineEstimated => 'משחק חיובי';
	@override String get timelinePending => 'מחפשים';
	@override String get timelineStale => 'לוח הזמנים עשוי להיות מוגזם';
	@override String get unknownHub => 'לא ידוע';
	@override String get unknownError => 'שגיאה לא ידועה';
	@override String channelNumber({required Object number}) => 'ערוץ ${number}';
	@override String get unknownChannel => 'ערוץ לא ידוע';
	@override String get live => 'שידור חי';
	@override String get premiereBadge => 'חדש';
	@override String get reloadGuide => 'מחדש מדריך';
	@override String get searchGuide => 'מדריך חיפוש';
	@override String get searchHint => 'ערוצי חיפוש ותוכניות';
	@override String searchNoResults({required Object query}) => 'אין משחקים עבור "${query}"';
	@override String get channelsSection => 'ערוצים';
	@override String get programsSection => 'תוכניות';
	@override String get now => 'עכשיו';
	@override String get today => 'היום';
	@override String get tomorrow => 'מחר';
	@override String get midnight => 'חצות';
	@override String get overnight => 'לילה';
	@override String get morning => 'בוקר';
	@override String get daytime => 'יום';
	@override String get evening => 'לילה';
	@override String get lateNight => 'לילה מאוחר';
	@override String get whatsOn => 'מה זה על';
	@override String get watchChannel => 'צפו בערוץ';
	@override String get favorites => 'מועדפים';
	@override String get reorderFavorites => 'תגית: Favorites';
	@override String get noFavoriteChannels => 'אין ערוצים מועדפים';
	@override String get noFavoriteChannelsHint => 'הצג את כל הערוצים, ולאחר מכן לחץ על ערוץ כדי להוסיף אותו לאהובים שלך.';
	@override String get showAllChannels => 'הצג את כל הערוצים';
	@override String get favoritesLoadFailed => 'לא יכול להעלות את האהובים.בדוק את החיבור שלך ולנסות שוב.';
	@override String get favoritesUpdateFailed => 'לא ניתן לעדכן את האהובים.בדוק את החיבור שלך ולנסות שוב.';
	@override String get joinSession => 'הצטרפו לפגישה בתקדמות';
	@override String watchFromStart({required Object minutes}) => 'לצפות מההתחלה (לפני ${minutes} דקות)';
	@override String get watchLive => 'צפו בחיים';
	@override String get goToLive => 'ללכת לחיות';
	@override String get record => 'הקלטה';
	@override String get recordEpisode => 'פרק רשום';
	@override String get recordSeries => 'הקלט סדרה';
	@override String get recordOptions => 'אפשרויות רישום';
	@override String get saveTo => 'להציל את';
	@override String get recordings => 'הקלטות';
	@override String get scheduledRecordings => 'לוח זמנים';
	@override String get recordingRules => 'חוקי ההקלטה';
	@override String get noScheduledRecordings => 'שום דבר לא מתוכנן להקליט';
	@override String get manageRecording => 'ניהול הקלטות';
	@override String get cancelRecording => 'ביטול הקלטה';
	@override String get cancelRecordingTitle => 'לבטל את ההקלטה הזו?';
	@override String cancelRecordingMessage({required Object title}) => '${title} כבר לא יירשם.';
	@override String get deleteRule => 'הורדת חוק';
	@override String get deleteRuleTitle => 'הורד את חוק ההקלטה?';
	@override String deleteRuleMessage({required Object title}) => 'הפרקים העתידיים של ${title} לא יירשמו.';
	@override String get recordingScheduled => 'ההקלטה מתוזמנת.';
	@override String get alreadyScheduled => 'תוכנית זו כבר מתוכננת.';
	@override String get dvrAdminRequired => 'הגדרות DVR דורשות חשבון מנהל';
	@override String get recordingFailed => 'לא יכולתי לתכנן את ההקלטה';
	@override String get recordingTargetMissing => 'לא יכולתי לקבוע את הקלטת הספרייה';
	@override String get recordNotAvailable => 'הקלטות שאינן זמינות לתוכנית זו';
	@override String get recordingCancelled => 'ההקלטה בוטלה';
	@override String get recordingRuleDeleted => 'חוק ההקלטה מוחק';
	@override String get processRecordingRules => 'הערכה מחדש של הכללים';
	@override String get recordingInProgress => 'להקליט עכשיו';
	@override String recordingsCount({required Object count}) => '${count} מתוכנן';
	@override String get editRule => 'Edit כללים';
	@override String get editRuleAction => 'ערוך';
	@override String get recordingRuleUpdated => 'חוק ההקלטה מתעדכן';
	@override String get guideReloadRequested => 'מדריך חידוש נדרש';
	@override String get guideReloadFailed => 'לא יכולתי לחדש את המדריך';
	@override String get rulesProcessRequested => 'בקשה להערכה מחדש';
	@override String get rulesProcessFailed => 'לא ניתן להעריך מחדש את חוקי ההקלטה';
	@override String get recordShow => 'הצגת רשומות';
	@override late final _Translations$liveTv$recordSettings$he recordSettings = _Translations$liveTv$recordSettings$he._(_root);
	@override String startingInMinutes({required Object minutes}) => 'מתחיל ב ${minutes} דקות';
	@override String dayAtTime({required Object day, required Object time}) => '${day} ב ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} החזיר נתונים לא חוקיים Live TV playback';
	@override String get failedToStartChannel => 'לא יכולתי להתחיל את ערוץ החי';
	@override String get failedToBuildStreamUrl => 'לא יכולתי לבנות את ה-URL הזרם';
	@override String playbackStartFailed({required Object reason}) => 'לא יכולתי להתחיל את הערוץ: ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'לא יכול לשנות את הערוץ: ${reason}';
}

// Path: collections
class _Translations$collections$he extends Translations$collections$en {
	_Translations$collections$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'אוספים';
	@override String get collection => 'אוספים';
	@override String get empty => 'הקולקציה ריקה';
	@override String get deleteCollection => 'מחיקת אוסף';
	@override String deleteConfirm({required Object title}) => 'למחוק את "${title}"? לא ניתן לבטל את הפעולה לאחר מכן.';
	@override String get deleted => 'אוסף מוחק';
	@override String get deleteFailed => 'לא הצלחתי למחוק את האוסף';
	@override String deleteFailedWithError({required Object error}) => 'לא הצליח למחוק את האוסף: ${error}';
	@override String get selectCollection => 'בחר אוסף';
	@override String get collectionName => 'שם האוסף';
	@override String get enterCollectionName => 'כניסת שם האוסף';
	@override String get addedToCollection => 'הוספת לקהילה';
	@override String get errorAddingToCollection => 'לא הצלחתי להוסיף לאוסף';
	@override String get created => 'אוסף שנוצר';
	@override String get removeFromCollection => 'הסר מאוספים';
	@override String removeFromCollectionConfirm({required Object title}) => 'להסיר את „${title}” מהאוסף הזה?';
	@override String get removedFromCollection => 'הוסר מהאוסף';
	@override String get removeFromCollectionFailed => 'לא הצליחו להסיר מהאוסף';
	@override String removeFromCollectionError({required Object error}) => 'שגיאה להסרת מתוך הקולקציה: ${error}';
	@override String get searchCollections => 'חיפוש אוסף...';
}

// Path: playlists
class _Translations$playlists$he extends Translations$playlists$en {
	_Translations$playlists$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'רשימות נגינה';
	@override String get playlist => 'רשימת ניגון';
	@override String get noPlaylists => 'לא נמצאו רשימות משחקים';
	@override String get create => 'יצירת Playlist';
	@override String get playlistName => 'שם המשחק';
	@override String get enterPlaylistName => 'כניסת שם playlist';
	@override String get delete => 'מחיקת רשימת השמעה';
	@override String get removeItem => 'הסר מרשימת הניגון';
	@override String get smartPlaylist => 'חכמה Playlist';
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} פריט',
		two: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} פריטים',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} פריטים',
	);
	@override String get emptyPlaylist => 'רשימת המשחקים הזאת ריקה';
	@override String get deleteConfirm => 'לשחרר את Playlist?';
	@override String deleteMessage({required Object name}) => 'האם אתה בטוח שאתה רוצה למחוק את "${name}"?';
	@override String get created => 'Playlist שנוצר';
	@override String get deleted => 'Playlist מוחלף';
	@override String get itemAdded => 'הוספת ל playlist';
	@override String get itemRemoved => 'הוסרו מהפלאי';
	@override String get selectPlaylist => 'בחר Playlist';
	@override String get searchPlaylists => 'מחפשים רשימת משחקים';
	@override String get errorCreating => 'לא הצלחתי ליצור רשימת משחקים';
	@override String get errorDeleting => 'לא הצלחתי למחוק את רשימת המשחקים';
	@override String get errorLoading => 'לא הצלחתי להעלות את רשימת המשחקים';
	@override String get errorAdding => 'לא הצלחתי להוסיף ל playlist';
	@override String get errorReordering => 'לא הצלחתי להזמין מחדש את פריט playlist';
	@override String get errorRemoving => 'לא הצלחתי להסיר אותו מהרשימה';
}

// Path: music
class _Translations$music$he extends Translations$music$en {
	_Translations$music$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'ללכת אל אלבום';
	@override String get goToArtist => 'ללכת לאמן';
	@override String get instantMix => 'מיקס מיידי';
	@override String get playNext => 'נגן את הבא';
	@override String get addToQueue => 'הוסף ל- Queue';
	@override String discNumber({required Object n}) => 'דיסק ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} מסלול',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} רצועות',
	);
	@override String get nowPlaying => 'משחק עכשיו';
	@override String playingFrom({required Object title}) => 'משחקים מתוך ${title}';
	@override String get queue => 'קווי';
	@override String get clearQueue => 'נקה תור';
	@override String get lyrics => 'מילות השיר';
	@override String get visualizer => 'ויזואלי';
	@override String get visualizerProfileLoading => 'קריאת רצועת ניתוח';
	@override String get visualizerAmbientMotion => 'תנועת הסביבה';
	@override String get visualizerPlexLoudness => 'Plex צליל';
	@override String get visualizerPreviousPreset => 'סגנון חזותי קודם';
	@override String get visualizerNextPreset => 'סגנון חזותי הבא';
	@override String get visualizerPresetAurora => 'אווררה';
	@override String get visualizerPresetBloom => 'בלום';
	@override String get visualizerPresetOrbitals => 'אורביטים';
	@override String get visualizerPresetPrism => 'מנסרה';
	@override String get visualizerPresetTunnel => 'מנהרה';
	@override String get visualizerPresetTrackMap => 'עקבו אחרי map';
	@override String get noLyrics => 'אין מילים זמינות';
	@override String get sleepTimer => 'שעות שינה';
	@override String get sleepTimerEndOfTrack => 'סוף מסלול';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} דקה',
		two: 'שתי דקות',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} דקות',
	);
	@override String get stopPlayback => 'הפסק הפעלה';
	@override String get previousTrack => 'הרצועה הקודמת';
	@override String get nextTrack => 'הרצועה הבאה';
	@override String get repeat => 'חזרה';
	@override String get repeatAll => 'חזרה על הכל';
	@override String get repeatOne => 'חזרה פעם אחת';
	@override String get instantMixNoServer => 'אין שרתים זמינים עבור מיזוג מיידי';
	@override String get instantMixFailed => 'לא הצלחתי להעלות את המערב המיידי';
	@override String get instantMixEmpty => 'התערובת החזרה ללא עקבות';
	@override String noAudioUrl({required Object track}) => 'אין כתובת אודיו זמינה עבור ${track}';
	@override late final _Translations$music$discography$he discography = _Translations$music$discography$he._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$he extends Translations$watchTogether$en {
	_Translations$watchTogether$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'צפייה משותפת';
	@override String get description => 'צפו בתוכן ב-Sync עם חברים ומשפחה';
	@override String get createRoom => 'יצירת חדר';
	@override String get creatingRoom => 'יצירת חדר...';
	@override String get joinRoom => 'הצטרפו לחדר';
	@override String get joiningRoom => 'חדר הצטרפות...';
	@override String get connecting => 'חיבור...';
	@override String get relayPublic => 'החדרים משתמשים ברדיו הציבורי של מפלגת השעון הפתוח.';
	@override String relayCustom({required Object url}) => 'החדרים משתמשים ברשת שלך ב- ${url}.';
	@override String get recentRooms => 'החדרים האחרונים';
	@override String get roomActions => 'חדר פעולות';
	@override String get renameRoom => 'שם חדר';
	@override String get removeRoom => 'הסר';
	@override String get enterRoomCode => 'הקלד את הקוד של 6 תווים מהארח.';
	@override String get roomCode => 'קוד חדר';
	@override String get paste => 'פסטה';
	@override String get noCodeInClipboard => 'הקליפ לא מכיל קוד חדר';
	@override String get copyCode => 'עותק קוד';
	@override String get codeCopied => 'קוד חדר עותק';
	@override String get shareInvite => 'שיתוף הזמנה';
	@override String get inviteCopied => 'תנו לו להוסיף את ההודעה, תנו לו להוסיף הודעה.';
	@override String inviteMessage({required Object code}) => 'הצטרף לחדר השעון שלי ב- PlezyNG: פתח את השעון יחד, בחר לחדר השעון הצטרף והכנס ל- ${code}.';
	@override String get openSessionControls => 'Open Watch יחד בדיקת ישיבה';
	@override String get reconnecting => 'חיבור מחדש...';
	@override String get reconnectingDescription => 'הקשר נעלם, אתה נכנס לחדר באופן אוטומטי.';
	@override String get connected => 'מחוברים';
	@override String get disconnected => 'נפרד';
	@override String get youAreHost => 'אתה האורח';
	@override String hostedBy({required Object name}) => 'פורסם על ידי ${name}';
	@override String get hostControlsPlayback => 'עקבו אחרי playback playback';
	@override String get anyoneCanControl => 'כל אחד יכול לשלוט ב-Playback';
	@override String get roomLocked => 'חדר סגור';
	@override String get nowPlaying => 'משחק עכשיו';
	@override String get nothingPlaying => 'לא משחק';
	@override String get nothingPlayingHost => 'לשחק משהו מכל ספרייה כדי לשתף אותו עם החדר.';
	@override String get nothingPlayingGuest => 'כאשר המארח משחק משהו, הוא פותח כאן.';
	@override String get notShareable => 'וידאו זה אינו מתאים לקטלוג, ולכן רק אנשים עם גישה לאותו שרת יכולים לשחק אותו.';
	@override String get searching => 'מחפשים את הסרטון הזה בספריות שלכם...';
	@override String get yourCopy => 'העתק שלך';
	@override String get sharingYourCopy => 'אתם חולקים את העתק שלכם';
	@override String playingOtherLength({required Object difference}) => 'לשחק את העתק שלך, ${difference}';
	@override String get mismatchTitle => 'העתק שלך הוא אורך שונה';
	@override String mismatchDescription({required Object difference}) => 'העתק הקרוב ביותר שלך הוא ${difference} מהסרטון של החדר.';
	@override String get playAnyway => 'לשחק בכל מקרה';
	@override String get chooseAnotherCopy => 'בחר עותק נוסף';
	@override String get dontPlay => 'אל תשחק';
	@override String get unavailableTitle => 'אין לך וידאו זה';
	@override String get unavailableDescription => 'PlezyNG לא מצא את זה בספריות שלך.קח עותק בעצמך או לחפש שוב.';
	@override String get chooseCopy => 'בחר עותק';
	@override String get searchAgain => 'מחפשים שוב';
	@override String get noCandidates => 'אין עותקים שנמצאו בספריות שלך.';
	@override String get choiceFailed => 'לא יכולתי לשחק את העתק הזה לחדר';
	@override String lengthLonger({required Object duration}) => '${duration} עוד';
	@override String lengthShorter({required Object duration}) => '${duration} קצר יותר';
	@override String get lengthSame => 'אותו אורך';
	@override String get lengthUnknown => 'אורך לא ידוע';
	@override String get joinCurrentPlayback => 'הצטרפו ל-Playback';
	@override String get joinCurrentPlaybackDescription => 'לחזור למה שהארח עוקב אחר';
	@override String get stopMedia => 'הפסקת וידאו לכולם';
	@override String get syncOffset => 'סינכרון Offset';
	@override String get syncOffsetDescription => 'שימו את הווידאו שלכם אם הוא פועל מול או מאחורי החדר.';
	@override String offsetHint({required Object difference}) => 'העתק שלך הוא ${difference} מהסרטון של החדר.';
	@override String applyDifference({required Object offset}) => 'שימוש ${offset}';
	@override String get offsetMinusSecond => '1 ס';
	@override String get offsetMinusTenth => '100 מ"ס';
	@override String get offsetPlusTenth => '+ 100 מ"ס';
	@override String get offsetPlusSecond => '+1 ס';
	@override String get participants => 'משתתפים';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} משתתפים',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} משתתפים',
	);
	@override String get hostBadge => 'מארח';
	@override String nameYou({required Object name}) => '${name} (אתה)';
	@override String get playerIdle => 'זמן פנוי';
	@override String get playerLoading => 'טעינה';
	@override String get playerReady => 'מוכנים';
	@override String get playerBuffering => 'בוקינג';
	@override String get matchSearching => 'חיפוש';
	@override String get matchMatched => 'יש את הווידאו';
	@override String get matchMismatched => 'אורך שונה';
	@override String get matchUnavailable => 'אין לך את הווידאו';
	@override String participantOffset({required Object offset}) => 'סה"כ ${offset}';
	@override String get makeHost => 'להפוך את המארח';
	@override String get makeHostQuestion => 'הועברה של המארח?';
	@override String makeHostConfirm({required Object name}) => '${name} ינהל את ההפעלה וינהל את הפגישה עבור כולם.';
	@override String get transfer => 'העברה';
	@override String get removeParticipant => 'להסיר מהחדר';
	@override String removeParticipantQuestion({required Object name}) => 'הורד ${name}?';
	@override String removeParticipantConfirm({required Object name}) => '${name} עוזב את החדר.הם יכולים להצטרף שוב עם הקוד אלא אם כן אתה סגור את החדר.';
	@override String get remove => 'הסר';
	@override String get roomSettings => 'הגדרות חדרים';
	@override String get letEveryoneControl => 'תנו לכולם לשלוט ב-Playback';
	@override String get lockRoom => 'חדר סגור';
	@override String get lockRoomDescription => 'אף אחד לא יכול להצטרף';
	@override String get leaveRoom => 'עזוב את החדר';
	@override String get leaveRoomQuestion => 'עזוב את החדר?';
	@override String get leaveRoomConfirm => 'אתה יכול להצטרף שוב עם קוד החדר.';
	@override String get leave => 'שחרור';
	@override String get endRoom => 'חדר סוף';
	@override String get endRoomQuestion => 'חדר סוף ?';
	@override String get endRoomConfirm => 'זה סיים את החדר לכולם.';
	@override String get end => 'סוף';
	@override String get playBlockedTitle => 'Playback לא התחיל';
	@override String get playBlockedDescription => 'מתחילים לשחק כדי להתחיל לצפות בחדר.';
	@override late final _Translations$watchTogether$notices$he notices = _Translations$watchTogether$notices$he._(_root);
	@override late final _Translations$watchTogether$ended$he ended = _Translations$watchTogether$ended$he._(_root);
	@override late final _Translations$watchTogether$errors$he errors = _Translations$watchTogether$errors$he._(_root);
	@override String untitledEpisode({required Object number}) => 'פרק ${number}';
}

// Path: downloads
class _Translations$downloads$he extends Translations$downloads$en {
	_Translations$downloads$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'הורדות';
	@override String get manage => 'ניהול';
	@override String get tvShows => 'סדרות טלוויזיה';
	@override String get movies => 'סרטים';
	@override String get music => 'מוסיקה';
	@override String tracksQueued({required Object count}) => '${count} עקבות שנקבעו להורדה';
	@override String get noDownloads => 'עדיין לא הורד';
	@override String get noDownloadsDescription => 'התוכן שנרשם יופיע כאן לצפייה לא מקוונת';
	@override String get downloadNow => 'הורדה';
	@override String get deleteDownload => 'הורד Download';
	@override String get retryDownload => 'הורד Retry';
	@override String get downloadQueued => 'הורדה נוספה לתור.';
	@override String get downloadResumed => 'הורד מחדש';
	@override String get serverErrorBitrate => 'שגיאה בשרת: קובץ עשוי לעבור את הגבול של שיעור ביט מרחוק';
	@override String get storageFull => 'הורדות נעצרו כדי להגן על אחסון זמין.חופשי קצת שטח או בחר מיקום הורדה אחר, ולאחר מכן להחזיר.';
	@override String get storageUnavailable => 'הורדות נעצרו כי לא ניתן לבדוק את אחסון הזמינות.בדוק את מיקום ההורדה, ולאחר מכן לחזור.';
	@override String episodesQueued({required Object count}) => '${count} פרקים שנרשמו להורדה';
	@override String get downloadDeleted => 'הורדה מוחלפת';
	@override String deleteConfirm({required Object title}) => 'האם ניתן למחוק את "${title}" מהמכשיר הזה?';
	@override String get deleteCollectionDownloads => 'הורדת הורדות';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => 'למחוק מהמכשיר הזה את כל ההורדות שב„${title}”?';
	@override String get collectionDownloadsDeleted => 'הורדות נמחקו';
	@override String get cancelledDownloadTitle => 'ביטול הורדה';
	@override String get cancelledDownloadMessage => 'הורדה זו בוטלה, מה היית רוצה לעשות?';
	@override String get allEpisodesAlreadyDownloaded => 'כל הפרקים כבר הורדו';
	@override String get resumeDownload => 'תגית: download';
	@override String get cancelledDownload => 'ביטול הורדות';
	@override String syncingFile({required Object file, required Object status}) => '${file} (סנצ\'ינג ${status})';
	@override String downloadedFileClickToComplete({required Object file}) => 'הורד ${file} - לחצו כדי להשלים';
	@override String get partialDownloadClickToComplete => 'הורדה חלקית - לחצו כדי להשלים';
	@override String get deleting => 'הסרת...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'הסרת ${title}... (${current} מתוך ${total})';
	@override String get queuedTooltip => 'קוויד';
	@override String queuedFilesTooltip({required Object files}) => 'שוטף ${files}';
	@override String get downloadingTooltip => 'להורדה...';
	@override String downloadingFilesTooltip({required Object files}) => 'הורדה ${files}';
	@override String get noDownloadsTree => 'אין הורדות';
	@override String get pauseAll => 'הפסקה הכול';
	@override String get resumeAll => 'סיכום הכול';
	@override String get retryAll => 'להחזיר את כולם';
	@override String get retryFailed => 'הורדות נכשלות';
	@override String get deleteAll => 'מחק הכל';
	@override String get selectVersion => 'בחר גרסה';
	@override String get allEpisodes => 'כל הפרקים';
	@override String get unwatchedOnly => 'לא נצפה רק';
	@override String nextNUnwatched({required Object count}) => 'הבא ${count} לא נצפה';
	@override String get customAmount => 'כמות מותאמת...';
	@override String get customAmountAny => 'כל סכום (כל סכום)';
	@override String get randomEpisodes => 'אירועים אקראיים';
	@override String get includeSpecials => 'כולל מיוחד';
	@override String get howManyEpisodes => 'כמה פרקים יש?';
	@override String get invalidEpisodeCount => 'הקלד מספר של פרקים.';
	@override String get keepSynced => 'להישאר סינכרון';
	@override String get downloadOnce => 'הורד פעם אחת';
	@override String keepNUnwatched({required Object count}) => 'שמור ${count} לא צופה';
	@override String get editSyncRule => 'עקבו אחרי sync sync sync';
	@override String get removeSyncRule => 'להסיר סינכרון';
	@override String removeSyncRuleConfirm({required Object title}) => 'הפסיק לסנכרן "${title}"?הפרקים שהורדו יישמרו.';
	@override String removeListSyncRuleConfirm({required Object title}) => 'הפסקת סינכרון "${title}"?';
	@override String get deleteSyncRuleDownloads => 'הורד גם הורדות קשורות';
	@override String get deleteSyncRuleDownloadsDescription => 'הורדות המשמשות על ידי כלל סינכרון אחר או פרופיל יישמרו.';
	@override String syncRuleCreated({required Object count}) => 'סינכרון שנוצרה — שמירה על ${count} פרקים לא נצפו';
	@override String get syncRuleUpdated => 'סינכרון חוק עדכון';
	@override String get syncRuleRemoved => 'הוראות סינכרון הוסר';
	@override String get syncRuleAndDownloadsRemoved => 'הורדת סינכרון ותקופות הקשורות להסרה';
	@override String get syncRuleCleanupBusy => 'חוקי סינכרון מתעדכנים כעת, נסה שוב ברגע.';
	@override String get syncRuleCleanupUnavailable => 'מחדש את השרת ולנסות שוב, או להסיר את הכלל בלי למחוק את ההורדות.';
	@override String syncedNewEpisodes({required Object count, required Object title}) => 'סינכרון ${count} פרקים חדשים עבור ${title}';
	@override String get syncNow => 'סינכרון עכשיו';
	@override String get downloadsUpToDate => 'הורדות עד כה';
	@override String syncComplete({required Object queued, required Object removed}) => 'סינכרון מלא · ${queued} queued, ${removed} removed';
	@override String get activeSyncRules => 'סינכרון כללים';
	@override String get reviewOrphanFiles => 'תגית: הורדות עופות';
	@override String get orphanReviewTitle => 'תגית: הורדות עופות';
	@override String get orphanReviewDescription => 'קבצי תוויות אלה נמצאים בתיקיות הורדה המנוהלות על-ידי אפליקציית PlezyNG כברירת מחדל ואין להם רשומות הורדה או משימות פעילות.';
	@override String orphanReviewCount({required Object count, required Object size}) => '${count} קבצים · ${size}';
	@override String orphanDeleteFiles({required Object count}) => 'הסרת קבצים ${count}';
	@override String get orphanCleanupNone => 'לא נמצאו קבצי הורדה';
	@override String get orphanCleanupFailed => 'PlezyNG לא הצליח לסרוק בבטחה את תיקיית ההורדות המנוהלת.';
	@override String get orphanCleanupChanged => 'רשימת ההורדות השתנתה במהלך הביקורת.הבדוק שוב את הקבצים לפני ניקוי.';
	@override String orphanCleanupComplete({required Object count, required Object size}) => 'הורד ${count} קבצים עתיקים · ${size} שוחרר';
	@override String get noSyncRules => 'אין כללים סינכרון';
	@override String get manageSyncRule => 'ניהול Sync';
	@override String get editEpisodeCount => 'פרק מספר';
	@override String get editSyncFilter => 'סינכרון Filter';
	@override String get syncAllItems => 'סינכרון כל הפריטים';
	@override String get syncUnwatchedItems => 'סינכרון פריטים לא נבדקים';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'שרת: ${server} • ${status}';
	@override String get syncRuleAvailable => 'זמין';
	@override String get syncRuleOffline => 'לא מקוון';
	@override String get syncRuleSignInRequired => 'הצהרת הדרישה';
	@override String get syncRuleAccessDenied => 'גישה נדחתה';
	@override String get syncRuleNotAvailableForProfile => 'לא זמין עבור הפרופיל הנוכחי';
	@override String get syncRuleUnknownServer => 'שרת לא ידוע';
	@override String get syncRuleListCreated => 'עקרונות סינכרון נוצר';
	@override late final _Translations$downloads$backgroundWarning$he backgroundWarning = _Translations$downloads$backgroundWarning$he._(_root);
	@override String get options => 'אפשרויות הורדה';
	@override late final _Translations$downloads$groupings$he groupings = _Translations$downloads$groupings$he._(_root);
	@override String get unknownLibrary => 'ספרייה לא ידועה';
	@override String get unknownShow => 'מופע לא ידוע';
	@override String get unknownSeason => 'עונה לא ידועה';
	@override String get unknownAlbum => 'אלבום לא ידוע';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} הושלמה';
	@override String storageUsed({required Object size}) => 'אחסון משתמש: ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} להורדה',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} הורדות',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} תצוגה',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} תצוגה',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} סרטים',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} סרטים',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} אלבום',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} אלבומים',
	);
	@override String get errorFileNotFound => 'קובץ לא נמצא (404)';
	@override String get errorDownloadNotAllowed => 'הורדות שאינן מותרות על ידי השרת (403)';
	@override String get errorDownloadFailed => 'הורדה נכשלה';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'הורדה נכשלה: ${reason}';
	@override String get convertingOnServer => 'הפוך לשרת...';
	@override String convertingOnServerPercent({required Object percent}) => 'הפוך לשרת · ${percent}%';
	@override String errorHttpStatus({required Object status}) => 'הורדה נכשלה (HTTP ${status})';
	@override String errorPostProcessing({required Object reason}) => 'תוצאות חיפוש: ${reason}';
	@override String get reasonFileNotSaved => 'לא ניתן לשמור את הקובץ במכשיר זה.';
	@override String get reasonCannotResume => 'הורדה חלקית לא יכולה להיחזר';
	@override String get reasonDeviceStorageFull => 'מכשיר זה לא נשמר.';
	@override String get notificationDownloading => 'להורדה...';
	@override String get notificationComplete => 'הורדה מלאה';
	@override String get notificationPaused => 'הורד הפסקה';
}

// Path: shaders
class _Translations$shaders$he extends Translations$shaders$en {
	_Translations$shaders$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'מצללים';
	@override String get noShaderDescription => 'אין שיפור וידאו';
	@override String get nvscalerDescription => 'NVIDIA תמונה סקלינג עבור וידאו בהיר יותר';
	@override String get artcnnVariantNeutral => 'נייטרלי';
	@override String get artcnnVariantDenoise => 'דניאל';
	@override String get artcnnVariantDenoiseSharpen => 'דנואיס + Sharpen';
	@override String get qualityFast => 'מהיר';
	@override String get qualityHQ => 'איכות גבוהה';
	@override String get mode => 'אופנה';
	@override String get importShader => 'ייבוא Shader';
	@override String get customShaderDescription => 'תגית: GLSL Shader';
	@override String get shaderImported => 'Shader ייבוא';
	@override String get shaderImportFailed => 'לא הצלחתי לייבא את ה-Shader';
	@override String get deleteShader => 'הורד Shader';
	@override String deleteShaderConfirm({required Object name}) => 'הסרת "${name}" ?';
}

// Path: companionRemote
class _Translations$companionRemote$he extends Translations$companionRemote$en {
	_Translations$companionRemote$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'שלט נלווה';
	@override String connectedTo({required Object name}) => 'חיבור ל- ${name}';
	@override String get unknownDevice => 'מכשיר לא ידוע';
	@override late final _Translations$companionRemote$session$he session = _Translations$companionRemote$session$he._(_root);
	@override late final _Translations$companionRemote$pairing$he pairing = _Translations$companionRemote$pairing$he._(_root);
	@override late final _Translations$companionRemote$remote$he remote = _Translations$companionRemote$remote$he._(_root);
	@override late final _Translations$companionRemote$errors$he errors = _Translations$companionRemote$errors$he._(_root);
	@override String get closedBeforeAuth => 'הקשר סגור לפני האמת';
}

// Path: videoSettings
class _Translations$videoSettings$he extends Translations$videoSettings$en {
	_Translations$videoSettings$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'מהירות ניגון';
	@override String get normalSpeed => 'רגיל';
	@override String sleepTimerActive({required Object duration}) => 'פעיל (${duration})';
	@override String get zoom => 'זום';
	@override String get sleepTimer => 'שעות שינה';
	@override String get audioSync => 'אודיו Sync';
	@override String get subtitleSync => 'תגית: Sync';
	@override String get hdr => 'HDR';
	@override String get hdrUnsupported => 'HDR אינו זמין כאן – מחבר שולחן העבודה או יצוא וידאו זה לא יכול לשאת אותו.';
	@override String get hdrToneMapping => 'HDR טון מפה';
	@override String get hdrToneMappingCompositor => 'קומפוזיציה';
	@override String get hdrToneMappingCompositorDescription => 'עובר את הנתונים המוטאדיים HDR של המקור והניח את המפה של שולחן העבודה.';
	@override String get hdrToneMappingPlayer => 'נגן';
	@override String get hdrToneMappingPlayerDescription => 'מפה לנקודת המבט הגבוהה של המסך בשחקן, ואז לספר למפיק את התוצאה.';
	@override String get hdrToneMappingFailed => 'לא ניתן לשנות את מפת הטון HDR - המצב הקודם עדיין פעיל.';
	@override String get audioOutput => 'אודיו יוצא';
	@override String get performanceOverlay => 'ביצועים Overlay';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'סביב';
	@override String get audioOutputSpatial => 'חלל אודיו';
	@override String get audioOutputStereo => 'סטריאו';
	@override String get audioEqualizer => 'אודיו Equalizer';
	@override String get audioEqualizerDescription => 'זמין ב- mpv; EQ פעיל מעודד אודיו ומפחיד את התאמה.';
	@override String get audioEqualizerFlat => 'שטוח';
	@override String get audioEqualizerActive => 'מותאם אישית';
	@override String get audioEqualizerSaveFailed => 'לא יכולתי לשמור את ההגדרות של שווה אודיו.';
	@override String get backgroundVideoAudio => 'רקע וידאו אודיו';
	@override String get backgroundVideoAudioDescription => 'שמור על שידור אודיו וידאו כאשר אתה עוזב את השחקן; התמונה מוסתרת עד שאתה חוזר. Android משתמש בהודעה לשחק מדיה.';
	@override String get audioNormalization => 'נורמליזציה צליל';
	@override String get audioNormalizationDisablesPassthrough => 'להוריד את האודיו ל- PCM; passthrough נעלם בעוד זה';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$he extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get color => 'צבע';
	@override String get performance => 'ביצועים';
	@override String get buffer => 'בופר';
	@override String get app => 'אפליקציה';
	@override String get decoder => 'דקורטיבי';
	@override String get rawDecoder => 'דקורטיבי Raw';
	@override String get tunneling => 'טונל';
	@override String get passthrough => 'פסטהרו';
	@override String get aspect => 'מבט';
	@override String get rotation => 'סיבוב';
	@override String get dvSource => 'מקור DV';
	@override String get dvPath => 'דרכים DV';
	@override String get dvRouteDecoder => 'Dolby Vision דקודר';
	@override String get dvRouteDecoderP81 => 'Dolby Vision דקודר (P7→8.1)';
	@override String get dvRouteBaseLayer => 'מבנה בסיס';
	@override String get dvRouteBaseLayerHdr10 => 'HDR10 שכבת בסיס';
	@override String get dvRouteBaseLayerHlg => 'מדרגות בסיס HLG';
	@override String get dvRouteBaseLayerSdr => 'SDR מסגרת בסיס';
	@override String get dvRouteReshaped => 'RPU מחדש (gpu-next)';
	@override String get p7Conversion => 'P7 קונב';
	@override String get sampleRate => 'קצב דגימה';
	@override String get pixelFormat => 'פיקסל Fmt';
	@override String get hwFormat => 'ה-Fmt';
	@override String get matrix => 'מתיקס';
	@override String get primaries => 'ראשוני';
	@override String get transfer => 'העברה';
	@override String get renderFps => 'רנדה FPS';
	@override String get displayFps => 'תצוגה FPS';
	@override String get avSync => 'A/V סינכרון';
	@override String get dropped => 'נופל';
	@override String get dvRpus => 'דב RPU';
	@override String get dvRpuAverage => 'ה-RPU AVG';
	@override String get dvSampleAverage => 'דוגמאות AVG';
	@override String get maxLuma => 'מקס לומה';
	@override String get minLuma => 'לומא';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Cache משתמשים';
	@override String get cacheLimit => 'הגבלת Cache';
	@override String get speed => 'מהירות';
	@override String get player => 'נגן';
	@override String get playMethod => 'שיטת נגינה';
	@override String get memory => 'זיכרון';
	@override String get uiFps => 'תגית FPS';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Android HW';
	@override String get decoderNvidiaHw => 'NVIDIA HW';
	@override String get decoderQualcommHw => 'Qualcomm HW';
	@override String get decoderMediatekHw => 'מיקרוסופט HW';
	@override String get decoderExynosHw => 'יונייטד HW';
	@override String get decoderSoftware => 'תוכנה';
	@override String get decoderHardware => 'חומרה';
	@override String get tunnelingActive => 'פעיל';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted} (${failures} נכשל)';
}

// Path: externalPlayer
class _Translations$externalPlayer$he extends Translations$externalPlayer$en {
	_Translations$externalPlayer$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'שחקן חיצוני';
	@override String get useExternalPlayer => 'שימוש ב-Player חיצוני';
	@override String get useExternalPlayerDescription => 'פתח וידאו באפליקציה אחרת';
	@override String get selectPlayer => 'בחר שחקן';
	@override String get customPlayers => 'שחקנים מותאמים';
	@override String get systemDefault => 'מערכת מזויפת';
	@override String get addCustomPlayer => 'להוסיף שחקן מותאם אישית';
	@override String get playerName => 'שם שחקן';
	@override String get playerNameHint => 'השחקן שלי';
	@override String get playerCommand => 'מפקד';
	@override String get playerPackage => 'שם החבילה';
	@override String get playerUrlScheme => 'תבנית URL';
	@override String get off => 'כבוי';
	@override String get launchFailed => 'לא פתח שחקן חיצוני';
	@override String appNotInstalled({required Object name}) => '${name} לא מותקן';
	@override String get playInExternalPlayer => 'לשחק במשחק חיצוני';
}

// Path: metadataEdit
class _Translations$metadataEdit$he extends Translations$metadataEdit$en {
	_Translations$metadataEdit$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'ערוך';
	@override String get screenTitle => 'ערוך מטא-דאטה';
	@override String get basicInfo => 'מידע בסיסי';
	@override String get artwork => 'אמנות';
	@override String get advancedSettings => 'הגדרות מתקדמות';
	@override String get title => 'כותרת';
	@override String get sortTitle => 'מיין כותרת';
	@override String get originalTitle => 'כותרת מקורית';
	@override String get releaseDate => 'תאריך הוצאה';
	@override String get contentRating => 'תוכן דירוג';
	@override String get studio => 'סטודיו';
	@override String get tagline => 'שורת תיוג';
	@override String get summary => 'סיכום';
	@override String get poster => 'כרזה';
	@override String get background => 'רקע';
	@override String get logo => 'לוגו';
	@override String get squareArt => 'Square אמנות';
	@override String get selectPoster => 'בחר פוסטר';
	@override String get selectBackground => 'בחר רקע';
	@override String get selectLogo => 'בחר את הלוגו';
	@override String get selectSquareArt => 'בחר Square Art';
	@override String get fromUrl => 'מתוך URL';
	@override String get uploadFile => 'להעלות קובץ';
	@override String get enterImageUrl => 'כניסת תמונה URL';
	@override String get imageUrl => 'תמונה URL';
	@override String get metadataUpdated => 'נתונים מתעדכנים';
	@override String get metadataUpdateFailed => 'לא הצלחתי לעדכן את הנתונים';
	@override String get artworkUpdated => 'ארכיון עדכונים';
	@override String get artworkUpdateFailed => 'לא הצלחתי לעדכן את האמנות';
	@override String get noArtworkAvailable => 'אין יצירות אמנות זמינות';
	@override String artworkOption({required Object index}) => 'האפשרות האמנותית ${index}';
	@override String selectedArtworkOption({required Object index}) => 'האפשרות האמנותית ${index}, נבחר';
	@override String get notSet => 'לא קבע';
	@override String get libraryDefault => 'ספרייה פגום';
	@override String get accountDefault => 'חשבונאות מזויפת';
	@override String get seriesDefault => 'סדרת דפוק';
	@override String get episodeSorting => 'סדרה פרק';
	@override String get oldestFirst => 'ראשונים ישנים';
	@override String get newestFirst => 'החדשות הראשונות';
	@override String get keep => 'שמור';
	@override String get allEpisodes => 'כל הפרקים';
	@override String latestEpisodes({required Object count}) => '${count} פרקים אחרונים';
	@override String get latestEpisode => 'פרק אחרון';
	@override String episodesAddedPastDays({required Object count}) => 'פרקים הוספו בימים האחרונים ${count}';
	@override String get deleteAfterPlaying => 'הסרת פרקים לאחר המשחק';
	@override String get never => 'אף פעם';
	@override String get afterADay => 'אחרי יום אחד';
	@override String get afterAWeek => 'אחרי שבוע';
	@override String get afterAMonth => 'אחרי חודש';
	@override String get onNextRefresh => 'הבא הפריחה';
	@override String get seasons => 'עונות';
	@override String get show => 'תצוגה';
	@override String get hide => 'הסתרה';
	@override String get episodeOrdering => 'פרק הזמנה';
	@override String get tmdbAiring => 'The Movie Database (בסיס הנתונים של הסרט)';
	@override String get tvdbAiring => 'TheTVDB (אירד)';
	@override String get tvdbAbsolute => 'TheTVDB (אופולארי)';
	@override String get metadataLanguage => 'שפת Metadata';
	@override String get useOriginalTitle => 'שימוש בכותרת מקורית';
	@override String get preferredAudioLanguage => 'שפת קול מועדפת';
	@override String get preferredSubtitleLanguage => 'שפת כתוביות מועדפת';
	@override String get subtitleMode => 'אופטימלי Subtitle Mode';
	@override String get manuallySelected => 'בחירה ידנית';
	@override String get shownWithForeignAudio => 'תגיות: אודיו זר';
	@override String get alwaysEnabled => 'תמיד אפשרי';
	@override String get tags => 'מילות מפתח';
	@override String get addTag => 'הוסף תגית';
	@override String get genre => 'ז\'אנר';
	@override String get director => 'במאי';
	@override String get writer => 'כותב';
	@override String get producer => 'במאי';
	@override String get country => 'ארץ';
	@override String get collection => 'אוספים';
	@override String get label => 'תווית';
	@override String get quickTag => 'Tag מהיר';
}

// Path: matchScreen
class _Translations$matchScreen$he extends Translations$matchScreen$en {
	_Translations$matchScreen$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get match => 'משחק ...';
	@override String get fixMatch => 'קבע את המשחק';
	@override String get unmatch => 'ביטול התאמה';
	@override String get unmatchConfirm => 'Plex מתייחס אליו כאילו הוא לא נלחם עד לסיום.';
	@override String get unmatchSuccess => 'פריט לא מתאים';
	@override String get unmatchFailed => 'לא הצלחתי להשיג פריט לא מתאים';
	@override String get matchApplied => 'משחק יישום';
	@override String get matchFailed => 'לא הצלחתי להשיג את המשחק';
	@override String get titleHint => 'כותרת';
	@override String get yearHint => 'שנה';
	@override String get search => 'חיפוש';
	@override String get noMatchesFound => 'לא נמצאו משחקים';
}

// Path: serverTasks
class _Translations$serverTasks$he extends Translations$serverTasks$en {
	_Translations$serverTasks$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'משימות שרת';
	@override String get failedToLoad => 'לא הצליחו להעלות את המשימות';
	@override String get noTasks => 'אין משימות מתבצעות';
}

// Path: trakt
class _Translations$trakt$he extends Translations$trakt$en {
	_Translations$trakt$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'מחוברים';
	@override String connectedAs({required Object username}) => 'קישור כ @${username}';
	@override String get disconnectConfirm => 'הפסקת חיבור לחשבון Trakt?';
	@override String get disconnectConfirmBody => 'PlezyNG יפסיק לשלוח אירועים ל- Trakt.';
	@override String get scrobble => 'זמן אמיתי Scrobbling';
	@override String get scrobbleDescription => 'שלח משחקים, הפסקות, ולעצור אירועים ל- Trakt במהלך הצפייה.';
	@override String get watchedSync => 'סינכרון מצב צופה';
	@override String get watchedSyncDescription => 'כאשר אתה מסמן פריטים כפי שנצפה ב- PlezyNG, הם מסומנים גם כפי שנצפה ב- Trakt.';
}

// Path: seerr
class _Translations$seerr$he extends Translations$seerr$en {
	_Translations$seerr$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'חיבור Seerr';
	@override String get serverUrl => 'כתובת URL';
	@override String get serverUrlHelper => 'כתובת האישום של ה-Seerr';
	@override String get checkServer => 'המשך';
	@override String get signInWithJellyfin => 'הצטרפו ל- Jellyfin';
	@override String get signInWithEmby => 'הצטרפו ל- Emby';
	@override String get signInWithLocal => 'השתמש בחשבון מקומי';
	@override String get email => 'דואר אלקטרוני';
	@override String get noSignInMethods => 'דוגמה זו של Seerr אינה מציעה תמיכה בשיטת ההרשמה PlezyNG.';
	@override String get instance => 'אינסטנט';
	@override String get disconnectConfirm => 'הפסקת חיבור ל-Seerr?';
	@override String get disconnectConfirmBody => 'PlezyNG תשכח את התגובה הזאת של Seerr.';
	@override String get request => 'בקשה';
	@override String get request4k => 'בקשה 4K';
	@override String get seasons => 'עונות';
	@override String get allSeasons => 'כל העונות';
	@override String get advancedOptions => 'מתקדם';
	@override String get destinationServer => 'שרת היעד';
	@override String get qualityProfile => 'פרופיל איכות';
	@override String get rootFolder => 'שורש קובץ';
	@override String get languageProfile => 'פרופיל שפה';
	@override String get tags => 'מילות מפתח';
	@override String get noTags => 'אין תגיות';
	@override String defaultOption({required Object name}) => '${name} (התכונה המוגדרת)';
	@override String get animeNote => 'הסדרה הזו היא אנמיה.';
	@override String get requestSubmitted => 'בקשה שהוגשה';
	@override String requestFailed({required Object error}) => 'בקשה נכשלה: ${error}';
	@override String get requestsLoadFailed => 'לא ניתן להעלות את אפשרויות הבקשה';
	@override String get nothingToRequest => 'הכל כבר זמין או מבקש.';
	@override String get statusAvailable => 'זמין';
	@override String get statusPartiallyAvailable => 'זמינים חלקית';
	@override String get statusRequested => 'ביקוש';
	@override String get statusProcessing => 'עיבוד';
	@override String get statusBlocklisted => 'חסום';
	@override String couldNotReach({required Object url, required Object error}) => 'לא יכול להגיע ${url}: ${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => 'אין דרישה של Seerr ב- ${url} (HTTP ${status})';
	@override String get behindAuthProxy => 'שרת Proxy הפוך שדורש אימות (SSO או אימות HTTP) ענה במקום Seerr. PlezyNG לא יכול להתחבר דרכו: יש לאפשר לנתיב /api/v1 של Seerr לעקוף את ה-Proxy עבור היישום, או להשתמש בכתובת שמגיעה ישירות ל-Seerr.';
	@override String get invalidUrl => 'הקלד כתובת שרת כגון https://seerr.example.com';
	@override String get quickConnectUnsupported => 'דוגמה זו של Seerr אינה תומכת ב- Quick Connect.זה זקוק ל- Seerr 3.4 או יותר.';
	@override String get notInitialized => 'מקרה זה של Seerr לא השלים את ההגדרה הראשונה';
	@override String get noPlexTokenForReauth => 'מספר Plex טוקן זמין להירשם מחדש';
	@override String get noStoredCredentials => 'אין פרטי התחברות שמורים הזמינים להתחברות מחדש';
	@override String get signInRejected => 'סינגפור נדחתה';
	@override String get noSessionCookie => 'Seerr לא הוציאה קובץ cookie ישיבה';
	@override String get freshCookieRejected => 'Seerr סירבה את קובץ העת החדש';
	@override String get noUserInformation => 'Seerr לא החזיר מידע משתמש';
	@override String get sessionRejectedAfterReauth => 'ההרשמה נדחתה לאחר חתימה נוספת.';
	@override String get permissionDenied => 'Seerr הכחישה את הפעולה הזאת: החשבון שלך כבר אין את הרשאה הנדרשת';
	@override String get permissionRevoked => 'אין לך יותר רשות לבקש זאת.';
}

// Path: services
class _Translations$services$he extends Translations$services$en {
	_Translations$services$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'שירותים';
	@override String get hubSubtitle => 'סינכרון עוקב אחר ההתקדמות ולבקש כותרות חדשות.';
	@override String get integrations => 'אינטגרציה';
	@override String get notConnected => 'לא מחוברים';
	@override String connectedAs({required Object username}) => 'קישור כ @${username}';
	@override String get scrobble => 'עקוב אחר ההתקדמות באופן אוטומטי';
	@override String get scrobbleDescription => 'עדכון הרשימה שלך כאשר אתה מסיים פרק או סרט.';
	@override String disconnectConfirm({required Object service}) => 'הפסקת חיבור ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'PlezyNG יפסיק לעדכן ${service}.';
	@override String connectFailed({required Object service}) => 'לא יכולתי להתחבר ל- ${service}.';
	@override late final _Translations$services$names$he names = _Translations$services$names$he._(_root);
	@override late final _Translations$services$simklReconnect$he simklReconnect = _Translations$services$simklReconnect$he._(_root);
	@override late final _Translations$services$deviceCode$he deviceCode = _Translations$services$deviceCode$he._(_root);
	@override late final _Translations$services$oauthProxy$he oauthProxy = _Translations$services$oauthProxy$he._(_root);
	@override late final _Translations$services$pendingAuth$he pendingAuth = _Translations$services$pendingAuth$he._(_root);
	@override late final _Translations$services$libraryFilter$he libraryFilter = _Translations$services$libraryFilter$he._(_root);
}

// Path: addServer
class _Translations$addServer$he extends Translations$addServer$en {
	_Translations$addServer$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => 'הוסף ${product} שרת';
	@override String get serverUrls => 'שרת URL';
	@override String get serverUrlsHelper => 'URLים מרובים מותרים, נפרדים על ידי commas.';
	@override String get findServer => 'מצא את השרת';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'מחפשים שרתים מקומיים ${product} ...';
	@override String localMediaBrowserServers({required Object product}) => 'שרתים מקומיים ${product}';
	@override String get username => 'שם משתמש';
	@override String get password => 'סיסמה';
	@override String get signIn => 'היכנס';
	@override String get change => 'שינוי';
	@override String get required => 'נדרש';
	@override String couldNotReachServer({required Object error}) => 'לא יכול להגיע לשרת: ${error}';
	@override String signInFailed({required Object error}) => 'הצטרפות לא מוצלחת: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect נכשל: ${error}';
	@override String get addPlexTitle => 'הצטרפו ל- Plex';
	@override String get pinExpired => 'ה-PIN נגמר לפני ההרשמה, אנא נסה שוב.';
	@override String failedToRegisterAccount({required Object error}) => 'חשבונית לא נרשמה: ${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => 'הקלד את כתובת ה-URL של השרת שלך ${product}';
	@override String get addConnectionTitle => 'להוסיף חיבור';
	@override String addConnectionTitleScoped({required Object name}) => 'הוסף ל ${name}';
	@override String get signInWithPlexCard => 'הצטרפו ל- Plex';
	@override String get signInWithPlexCardSubtitle => 'אישור מכשיר זה.השרתים המשותפים מוסיפים.';
	@override String get signInWithPlexCardSubtitleScoped => 'אישור חשבון Plex משתמשים מקומיים הופכים פרופילים.';
	@override String connectToMediaBrowserCard({required Object product}) => 'חיבור ל- ${product}';
	@override String get connectToMediaBrowserCardSubtitle => 'הקלד את כתובת ה-URL, שם המשתמש ואת הסיסמה שלך.';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => 'הצטרפו לשרת ${product}.חברים ל- ${name}.';
	@override String get borrowFromAnotherProfile => 'הלוואה מפרט אחר';
	@override String get borrowFromAnotherProfileSubtitle => 'השתמש מחדש בקשר של פרופיל אחר.פרופילים מוגנים ב-PIN דורשים PIN.';
	@override String get invalidCredentials => 'שם משתמש או סיסמה בלתי חוקיים';
	@override String get authResponseNotJson => 'התגובה לאמת לא הייתה שווה JSON';
	@override String get authResponseIncomplete => 'התגובה של השרת הייתה לא שלמה.';
	@override String get quickConnectRejected => 'Quick Connect נדחה על ידי השרת';
	@override String get quickConnectNotJson => 'התשובה Quick Connect לא הייתה שווה JSON';
	@override String get quickConnectMissingFields => 'התשובה Quick Connect חסרה קוד או סוד';
	@override String get quickConnectPollRejected => 'Quick Connect בקשה נדחתה על ידי השרת';
	@override String get serverTimedOut => 'השרת לא הגיב בזמן';
	@override String get responseNotJson => 'התגובה לשירות לא הייתה שווה JSON';
	@override String responseMissingIdentity({required Object product}) => 'התשובה חסרה מזהה או שם שרת - האם זה שרת ${product}?';
	@override String probeFailed({required Object error}) => 'לא יכול להגיע לשרת: ${error}';
	@override String enterAtLeastOneUrl({required Object product}) => 'הקלד לפחות כתובת URL אחת של השרת ${product}';
	@override String noReachableServer({required Object product}) => 'לא נמצאו שרתים זמינים ${product}';
	@override String urlsPointToDifferentServers({required Object product}) => 'כתובות URL אלה מתייחסים לשרתים שונים ${product}';
	@override String urlDoesNotMatchServer({required Object product}) => 'כתובת URL זו אינה תואמת לשרת ${product}';
	@override String get redirectUnsupported => 'השרת הועבר ל-URL שאינו נתמך';
	@override String redirectDifferentHost({required Object product}) => 'השרת הועבר למארח שונה.הכנס את כתובת ה-URL הסופית ${product} ישירות.';
	@override String get redirectInsecure => 'השרת הועבר מ- HTTPS ל- URL לא בטוח';
	@override String redirectUnsupportedEnterFinal({required Object product}) => 'השרת הועבר ל-URL שאינו נתמך, הקלד את כתובת ה-URL הסופית ${product} ישירות.';
	@override String get directPlexServerUrl => 'Plex כתובת השרת';
	@override String get directPlexServerUrlHelper => 'הקלד את ה- IP המקומי ואת הפורט של Plex Media Server שלך.';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex טוקן (אופציונלי)';
	@override String get plexTokenHelper => 'השאירו ריק אם גישה ללא auth מותרת בשרת זה.';
	@override String get plexTokenRequired => 'אנא הקלד את טוקן Plex שלך (X-Plex-Token).';
	@override String get connectDirectPlexCard => 'Plex שרת מדיה (מיד / מקומי)';
	@override String get connectDirectPlexCardSubtitle => 'חיבור ישיר באמצעות IP או כתובת URL מקומית ללא חשבון plex.tv.';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => 'חיבור ישיר באמצעות IP מקומי או כתובת URL. חיבור ל- ${name}.';
	@override String get insecureTitle => 'חיבור לא מוצפן';
	@override String insecureDescription({required Object url}) => '${url} משתמש ב-HTTP. אנשים ברשת עלולים לקרוא או לשנות את הסיסמה, האסימונים והמדיה שלך. יש להשתמש ב-HTTPS כשהוא זמין. יש להמשיך רק אם הרשת אמינה בעיניך והסיכון מקובל עליך.';
	@override String get allowHttp => 'לאפשר HTTP';
	@override String get httpsRequired => 'שימוש ב- HTTPS או מאפשר באופן מפורש חיבור לא מוצפן.';
}

// Path: watchLink
class _Translations$watchLink$he extends Translations$watchLink$en {
	_Translations$watchLink$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => 'לא יכולתי להגיע לשרת Plex עבור קישור זה.';
	@override String get notFound => 'לא מצאתי את ההצגה או הסרט הזה בשרתים שלך Plex.';
	@override String get ambiguous => 'קישור זה תואם פריטים על יותר ממשרת אחד.';
	@override String get plexOnly => 'קישורים לצפייה תומכים כיום רק בשרתים Plex.';
	@override String get unsupportedItem => 'קישורים לצפייה יכולים לפתוח רק מופע או סרט.';
	@override String get menuItem => 'צפו בקישור';
	@override String get dialogTitle => 'צפו בקישור';
	@override String get dialogShowHint => 'פתיחת הקישור הזה משחק את הפרק הבא. Add &mode=shuffle to the end to play the show on shuffle.';
	@override String get dialogMovieHint => 'פתיחת הקישור הזה משחק את הסרט.';
	@override String get copy => 'העתק';
	@override String get copied => 'קישור עותק';
}

// Path: homeLayout
class _Translations$homeLayout$he extends Translations$homeLayout$en {
	_Translations$homeLayout$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'בית Layout';
	@override String get resetToast => 'בית מחדש לרישום הגיבור המקורי Plezy';
	@override String get resetHeroTitle => 'להגדיר מחדש את הפריסה של הגיבור למלאי Plezy?';
	@override String get resetHeroBody => 'הפוך את הגדרת הגיבור של כל שורה ומביא בחזרה את הבאנר הסיבוב היחיד בחלק העליון של הבית, כמו לפני שורות הגיבורים היו קיימים.';
	@override String get removeRowTitle => 'להסיר את הבית?';
	@override String removeRowBody({required Object title}) => '${title} יימחק, זה לא יכול להימנע.';
	@override String get sync => 'סנכרון';
	@override String get syncAccountTitle => 'סינכרון הפריסה עם החשבון שלך Plex';
	@override String get syncAccountOn => 'על: מכשיר זה חולק סדר שורות, שורות, גיבור ו- Auto-slide עם המכשירים האחרים שלך.';
	@override String get syncAccountOff => 'סגור: המכשיר הזה שומר על הפריסה שלו.';
	@override String get syncNow => 'סינכרון עכשיו';
	@override String get plexHomeManager => 'Plex מנהל בית';
	@override String get managePlexRows => 'ניהול Plex שורות ב Plezy';
	@override String get managePlexRowsDescription => 'פתוח לארגן את השורות שנבחרו בבית';
	@override String get organizeHomeRows => 'ארגון שורות בית';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} שורות: זז, גיבור, אוטומטית, להסיר';
	@override String organizeLibraryRows({required Object library}) => 'ארגון ${library} שורות';
	@override String organizeLibraryRowsDescription({required Object n}) => 'המשך צפייה + ${n} שורות: תנועה, ספרייה, בית, גיבור, אוטומטית';
	@override String get renderAsHero => 'רנדה ככרטיס גיבור';
	@override String get heroOnlySingleCollection => 'זמין רק כאשר שורה זו מתפתחת לכותרות אמיתיות של אוסף יחיד';
	@override String get hero => 'גיבור';
	@override String get autoSlide => 'אוטומטי Slide';
	@override String get autoSlideDescription => 'גם סליטה על עצמה בכל כמה שניות.Arrows (PC) ו-d-pad (TV) תמיד עובדים ומתחילים מחדש את השעון.';
	@override String get autoSlideEditDescription => 'הוא גם זורם בעצמו כל כמה שניות. off: זורם רק כאשר אתה לוחץ על אקדח (מחשב) או לחץ שמאל / ימין על הרחוק (טלוויזיה).';
	@override String get enableHeroFirst => 'תנו לגיבור ראשון';
	@override String get showOnHome => 'הצג על המסך הבית';
	@override String get home => 'בית';
	@override String get removeFromHome => 'להסיר מהבית';
	@override String get selectRowsFirst => 'בחר את שורות הבית למטה קודם.';
	@override String plexManagedRows({required Object n}) => '${n} Plex שורות מנוהלות';
	@override String get continueWatching => 'המשך צפייה';
	@override String get continueWatchingLibraryDescription => 'ספריית התקדמות עצמית של הספרייה';
	@override String get continueWatchingHomeDescription => 'רצועת ההתקדמות המוצגת בבית';
	@override String get nextUpHomeDescription => 'השורה הבאה של הפרק לא נצפה הוצגה בנפרד בבית';
	@override String get library => 'ספרייה';
	@override String get showInRecommended => 'תגית: הספרייה המומלצת';
	@override String get customPlexRow => 'אישית Plex שורה';
	@override String get heroNeedsLibrary => 'ראשית, בדוק את הספרייה – גיבור צריך איפשהו להראות';
	@override String get heroNeedsSurface => 'ראשית בדוק את הספרייה או הבית – גיבור צריך איפשהו להראות';
	@override String get removeHub => 'להסיר Hub';
	@override String get noPlexRows => 'מספר Plex שורות המנוהלות חזרה לספריה זו.';
	@override String get openDetails => 'פרטים פתוחים';
	@override String get heroCards => 'כרטיסי גיבור';
	@override String get tapHeroCard => 'להדביק כרטיס גיבור';
	@override String get tvPlayFocus => 'טלוויזיה מרחוק: כפתור Play';
	@override String get tvPlayFocusDescription => 'D-pad למטה עוצר על כפתור המשחק לפני העברת השורה הבאה.';
	@override String get tvWrap => 'טלוויזיה מרחוק: כרטיסי גיבור לופ';
	@override String get tvWrapDescription => 'לחיצה שמאלה בכרטיס האחרון מחזירה לכרטיס הראשון. כשהאפשרות כבויה, הניווט נעצר בכרטיס האחרון. לחיצה ימינה בכרטיס הראשון תמיד עוברת לסרגל הצד.';
	@override String get castOnHero => 'תגיות קשורות Hero Banner';
	@override String get castOnHeroDescription => 'מציג את ההצגה לאורך החלק התחתון של הלוח הגיבור. off שמור רק את הכותרת ואת הסיכום.';
	@override String get customRows => 'עקבות מותאמות';
	@override String get loading => 'תגית: Home Layout';
	@override String get noCustomRows => 'עדיין אין שורות קבועות';
	@override String get addRowHint => 'השתמשו בסדרת הוספת הבית כדי ליצור אחד.';
	@override String get addHomeRow => 'להוסיף Home Row';
	@override String get addHomeRowDescription => 'בחר קטגוריה; השורה החדשה מוסיפה באופן אוטומטי למארגן';
	@override String get removeRow => 'להסיר שורה';
	@override String get recentlyAdded => 'אחרון';
	@override String get recentlyReleased => 'שוחרר לאחרונה';
	@override String get movieCollections => 'קולקציות סרטים';
	@override String get showCollections => 'הצג אוסף';
	@override String get rowTitle => 'כותרת Row';
	@override String get content => 'תוכן';
	@override String get showThisRowIn => 'הצג את השורה הזאת ב:';
	@override String get libraryRecommended => 'הספרייה המומלצת';
	@override String get heroCard => 'כרטיס גיבור';
	@override String get heroCardDescription => 'מציג כרטיס סיבוב אחד רחב מלא במקום מפתח פוסטר.';
	@override String get heroUnavailableDescription => 'זמין רק כאשר שורה זו מתייחסת לכותרות האמיתיות של אוסף יחיד – עם יותר מאחד אוספים שנבחרו, אין כותרת יחידה להסתובב.';
	@override String get librariesSelection => 'ספריות (לשחרר את כל הבלתי נבדקים לכל ספרייה)';
	@override String get librariesMergedDescription => 'כל ספרייה שנבדקה כאן מתמזגת בשורה אחת זו.';
	@override String get movieCollectionsSelection => 'אוסף סרטים (שחרר את כל הבלתי נבדק עבור כל ספרייה שנבחרה)';
	@override String get showCollectionsSelection => 'הצג אוסף (לשחרר את כל הבלתי נבדק עבור כל ספרייה שנבחרה)';
	@override String get collectionRowsDescription => 'אם בדיוק אוסף אחד מתאים, הכותרות שלו מופיעות ישירות ברציפות.אם יותר מאחד מתאים, כל אוסף מופיע כפוסט יחיד – הקלד אותו כדי לפתוח את האוסף.';
	@override String get allCollections => 'כל הקולקציות';
	@override String get noRowsHere => 'עדיין אין שורות כאן.';
	@override String get hideWatchedRows => 'להסתיר פריטים שנצפו בשורות';
	@override String get hideWatchedRowsDescription => 'כותרות צפייה מלאה עוזבות בית וספריה שורות מומלצות.';
	@override String get untitledCollection => 'אוסף ללא שם';
	@override String get moveRowHint => 'למעלה/למטה: לעבור שורה · בחר: להוריד כאן · בחזרה: לבטל';
	@override String get organizeRowsHint => 'בחר על שורה (או להחזיק בחר): לעבור אותה · שמאל/מימין: אפשרויות שורה · בחזרה: נעשה';
	@override String get layoutNavDescription => 'בחר שורות, ספריות וקטגוריות אוסף';
	@override String get editHomeRow => 'תגית: Home Row';
	@override String get resetHeroButton => 'מחדש את הפריסה של הגיבור למלאי Plezy';
	@override String get reorderingUnlocked => 'מחדש מחוץ לנעול';
	@override String get reorderingLocked => 'מחדש סגור';
	@override String get rowsCanBeDragged => 'ניתן לגרד את החוטים - לחץ על המנעול כדי למנוע זאת.';
	@override String get tapLockToDrag => 'לחצו על המנעול כדי לגרור שורות';
	@override String customRowLabel({required Object title}) => 'תגית: ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => 'הסתרה';
	@override String get remove => 'הסר';
	@override String get libraryResumeRow => 'הספרייה מחדש של הספרייה';
	@override String get pressAgainToDelete => 'לחץ שוב כדי למחוק';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => 'על';
	@override String get resetHeroButtonDescription => 'הפוך את הגדרת הגיבור של כל שורה ומביא בחזרה את הבאנר היחיד מסתובב בחלק העליון, כמו לפני שורות הגיבורים היו קיימים.';
}

// Path: platform
class _Translations$platform$he extends Translations$platform$en {
	_Translations$platform$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'PlezyNG מתחבר לשרתי המדיה ולמכשירי הניגון ברשת המקומית שלך.';
	@override String get locationPermission => 'PlezyNG משתמשת בגישה למיקום כאשר iOS דורש גישה כדי לזהות את הרשת המקומית שלך ולהתחבר לשרתי התקשורת שלך.';
	@override String get photoLibraryPermission => 'בחר תמונות מתוך ספריית התמונות שלך לשימוש כאמנות מדיה.';
	@override String get cameraPermission => 'סריקת קודי QR לצימוד שלט Companion Remote.';
}

// Path: fileSources
class _Translations$fileSources$he extends Translations$fileSources$en {
	_Translations$fileSources$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'קבצים וספרים';
	@override String get subtitle => 'קרא, הקשיב, והצפה מהקבצים שלך.';
	@override String get add => 'הוסף מקור';
	@override String get importFiles => 'קבצים ייבוא';
	@override String get localFiles => 'על המכשיר הזה';
	@override String get source => 'מקור';
	@override String get name => 'שם';
	@override String get endpoint => 'כתובת URL';
	@override String get root => 'תיקייה או קידומת';
	@override String get username => 'שם משתמש';
	@override String get password => 'סיסמה';
	@override String get token => 'API טוקן';
	@override String get accessKey => 'גישה מפתח ID';
	@override String get secretKey => 'מפתח גישה סודי';
	@override String get sessionToken => 'ישיבה טוקן (אופציונלי)';
	@override String get region => 'אזור';
	@override String get clientId => 'ה-OAuth Client ID';
	@override String get clientSecret => 'OAuth Client Secret (משרד Google בלבד)';
	@override String get allowHttp => 'לאפשר HTTP ללא הצפנה ברשת מהימנה';
	@override String get connect => 'התחבר';
	@override String get cancel => 'בטל';
	@override String get save => 'שמור';
	@override String get close => 'סגור';
	@override String get removeSource => 'מקור מחוץ למקור';
	@override String get disconnectMessage => 'לנתק את המקור הזה? הקבצים שהורדו והיסטוריית הקריאה וההאזנה שלך יישארו במכשיר הזה.';
	@override String get localFolder => 'בחר תיקיה';
	@override String get empty => 'שום דבר כאן עדיין';
	@override String get emptyHint => 'להוסיף מקור או לייבא ספר, ספר שמע, מוזיקה או וידאו.';
	@override String get search => 'לחפש את המאמר הזה';
	@override String get searchCached => 'חיפוש ספרייה שנשמרה';
	@override String get refresh => 'רענון';
	@override String get loadMore => 'להעלות יותר';
	@override String get offline => 'זמין offline';
	@override String get download => 'להישאר offline';
	@override String get removeDownload => 'להסיר offline copy';
	@override String get continueReading => 'המשך קריאה';
	@override String get continueListening => 'המשך להאזין';
	@override String get continueWatching => 'המשך צפייה';
	@override String get read => 'קראו';
	@override String get listen => 'לשמוע';
	@override String get play => 'נגן';
	@override String get pause => 'השהה';
	@override String get stop => 'עצור';
	@override String get startOver => 'התחל על';
	@override String get finished => 'הסתיימה';
	@override String get markFinished => 'מארק הסתיים';
	@override String get markUnfinished => 'מארק בלתי נגמר';
	@override String get editions => 'עיתונים וארכיונים';
	@override String get chapters => 'פרק';
	@override String get bookmarks => 'ספרות ומזכירות';
	@override String get bookmark => 'הוסף Bookmark';
	@override String get highlight => 'להדגיש';
	@override String get note => 'הערה';
	@override String get delete => 'מחק';
	@override String get export => 'הערות ייצוא';
	@override String get exported => 'הערות ייצוא';
	@override String get sync => 'סינכרון התקדמות';
	@override String get synced => 'התקדמות סינכרון';
	@override String get conflict => 'מכשיר אחר יש עמדה שונה.בחור איפה להמשיך.';
	@override String get useLocal => 'השתמש במכשיר זה';
	@override String get useRemote => 'שימוש במכשיר אחר';
	@override String get history => 'היסטוריה של עמדה';
	@override String get groupAudio => 'להקשיב כספר אודיו';
	@override String get groupHint => 'משלב את קובצי השמע שנטענו כרגע בתיקייה הזאת. יש לטעון קודם את כל העמודים.';
	@override String get order => 'צו קובץ';
	@override String get moveUp => 'תנועות למעלה';
	@override String get moveDown => 'תנו למטה';
	@override String get speed => 'מהירות ניגון';
	@override String get sleep => 'שעות שינה';
	@override String get sleepOff => 'כבוי';
	@override String get endChapter => 'סוף פרק';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} דקה',
		two: 'שתי דקות',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} דקות',
	);
	@override String get skipBack => 'סקי בחזרה';
	@override String get skipForward => 'קפיצה קדימה';
	@override String get smartRewind => 'חכמה לאחר הפסקה';
	@override String get playbackOptions => 'אפשרויות האזנה';
	@override String remaining({required Object time}) => '${time} שאר';
	@override String get contents => 'תוכן';
	@override String get readerSettings => 'קראת ההגדרות';
	@override String get fontSize => 'גודל טקסט';
	@override String get lineHeight => 'קו חלל';
	@override String get margin => 'מרג\'ינס';
	@override String get font => 'סוג';
	@override String get serif => 'סריף';
	@override String get sans => 'ללא סריף';
	@override String get mono => 'מונוספייס';
	@override String get columns => 'עמודים';
	@override String get scroll => 'סורק לעקוב';
	@override String get justify => 'יישור טקסט לשני הצדדים';
	@override String get readerTheme => 'דף מראה';
	@override String get appTheme => 'עקבו אחרי app theme app theme';
	@override String get paper => 'נייר';
	@override String get sepia => 'ספיא';
	@override String get night => 'לילה';
	@override String get readAloud => 'להקריא את העמוד הזה בקול';
	@override String get readAlong => 'לקרוא עם ההקראה';
	@override String get stopReading => 'להפסיק את ההקראה';
	@override String get searchBook => 'חיפוש בספר';
	@override String get noMatches => 'אין משחקים';
	@override String get previousPage => 'עמוד קודם';
	@override String get nextPage => 'עמוד הבא';
	@override String page({required Object number}) => 'עמוד ${number}';
	@override String get externalBlocked => 'קישורים חיצוניים בספרים מושבתים בקורא.';
	@override String get loading => 'פתיחת...';
	@override String get narrator => 'נרצחים';
	@override String get audio => 'שמע';
	@override String get video => 'וידאו';
	@override String get ebooks => 'ספרים אלקטרוניים';
	@override String get all => 'הכול';
	@override String get downloads => 'קבצים Offline';
	@override String get confirmDelete => 'להסיר את העותק שנבחר לשימוש לא מקוון? מיקום הקריאה או ההאזנה וההערות שלך יישמרו.';
	@override String get errorAuthentication => 'יש להתחבר שוב כדי לחבר מחדש את המקור.';
	@override String get errorPermission => 'מקור זה לא נתן גישה לקובץ הנדרש.';
	@override String get errorUnavailable => 'המקור אינו זמין, נסה שוב או פתח עותק לא מקוון.';
	@override String get errorUnsupported => 'פורמט זה או חיבור זה אינם נתמכים במכשיר זה.הצג את מדריך ההגדרה של המקור.';
	@override String get errorInvalidData => 'קובץ זה או התגובה של השרת לא ניתן לקרוא בבטחה.';
	@override String get errorCancelled => 'המבצע בוטל.';
	@override String get errorConflict => 'מיקום הקריאה או ההאזנה השתנה בהפעלה אחרת. יש לפתוח שוב את הפריט כדי לבחור מיקום.';
	@override String get signIn => 'היכנס';
	@override String get reconnect => 'מחדש';
	@override String get folderHelp => 'יש להשאיר ריק כדי להתחיל בתיקיית השורש של המקור. כתובות S3 כוללות את שם ה-bucket.';
	@override String get preferences => 'העדפות';
	@override String get timePosition => 'עמדה';
	@override String get audioTrack => 'אודיו טרק';
	@override String get subtitleTrack => 'תגית: track';
	@override String get none => 'אין';
	@override String get fullscreen => 'מסך מלא';
	@override String get syncLocation => 'תיבת ה-Progress Sync (אופציונלית)';
	@override String get syncLocationHint => 'תיקיית WebDAV ייעודית לשמירת מצב PlezyNG. משתמש בכתיבה מותנית; קובצי המדיה נשארים ללא שינוי.';
	@override String get audiobooks => 'ספרים מוקלטים';
	@override String get comics => 'קומיקס';
	@override String get scan => 'סריקה עבור ספרים ותקשורת';
	@override String get browserReader => 'פתוח קורא';
	@override String get browserReaderHelp => 'הקורא פתוח בדפדפן שלך. שמור PlezyNG פתוח כדי לשמור את המיקום שלך ואת הערות.';
	@override String get on => 'על';
	@override String get advancedSetup => 'App רישום';
	@override String get microsoftSignIn => 'הצטרפו ל-Microsoft';
	@override String get zoomIn => 'זום ב';
	@override String get zoomOut => 'זום יוצא';
	@override String get fitPage => 'דף מתאים';
	@override String get fitWidth => 'מתאים לרוחב';
	@override String get actualSize => 'גודל אמיתי';
	@override String get goToPage => 'ללכת לדף';
	@override String get goToSection => 'ללכת לפסוק';
	@override String pageRange({required Object count}) => 'הקלד מספר מ 1 ל ${count}';
	@override String get pageLayout => 'דף Layout';
	@override String get automatic => 'אוטומטית';
	@override String get singlePage => 'דף יחיד';
	@override String get twoPages => '2 עמודים';
	@override String get readingDirection => 'קריאה בכיוון';
	@override String get leftToRight => 'שמאל ימינה';
	@override String get rightToLeft => 'מימין לשמאל';
	@override String get letterSpacing => 'ספר חלל';
	@override String get wordSpacing => 'מילה חלל';
	@override String get readerControlsHelp => 'כדי להגדיל עמודים, אפשר להרחיק שתי אצבעות זו מזו או להשתמש בפקדי הזום. יש לגרור כדי להזיז את העמוד. Ctrl/⌘ יחד עם + או − משנה את הזום; Ctrl/⌘ יחד עם 0 מאפס אותו. Page Up ו-Page Down מדפדפים בין העמודים.';
	@override String get imagePage => 'דף קומדיה';
	@override String get resetReader => 'איפוס העדפות הקריאה';
	@override String get zoom => 'זום';
	@override String get useFiles => 'שימוש בקבצים ובספרים';
	@override String get cancelScan => 'ביטול סריקה';
	@override String get googleDrive => 'Google Drive';
	@override String get smbEndpointHint => 'לדוגמה: smb://nas/Movies';
	@override String get smbEndpointInvalid => 'יש להזין שרת SMB ותיקייה משותפת אחת.';
	@override String get smbFolderHelp => 'יש להשאיר ריק כדי להשתמש בכל התיקייה המשותפת, או להזין תיקייה בתוכה.';
	@override String get smbDomain => 'תחום (רשות)';
	@override String get smbEncryption => 'הצפנת חיבור SMB3';
	@override String get smbEncryptionHint => 'שימוש בהצפנת SMB3 כאשר התקן ה־NAS תומך בכך.';
}

// Path: lending
class _Translations$lending$he extends Translations$lending$en {
	_Translations$lending$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'ספרייה ציבורית';
	@override String get add => 'הוסף ספרייה';
	@override String get other => 'ספרייה נוספת';
	@override String get libraryName => 'שם הספרייה';
	@override String get libraryUrl => 'אתר הספרייה';
	@override String get libraryUrlHint => 'יש להשתמש בקטלוג של הספרייה או בעמוד ההתחברות שלה.';
	@override String get intro => 'לשאול ספרים מהספרייה שלך ולהשאיר אותם קרוב אליך.';
	@override String get handoff => 'להתחבר, לשאול ספרים ולקרוא בבטחה באמצעות השירות של הספרייה שלך.';
	@override String get openService => 'ספרייה פתוחה';
	@override String get findLibrary => 'מצא ספרייה';
	@override String get search => 'חיפוש ספרים וסופרים';
	@override String get catalogue => 'קטגוריה';
	@override String get loans => 'השאלות';
	@override String get holds => 'הזמנות';
	@override String get signIn => 'הצטרפו לספריה שלכם';
	@override String get waiting => 'הסתיימו את ההרשמה בדפדפן שלכם, ואז תחזרו לכאן.';
	@override String get cancel => 'בטל';
	@override String get disconnect => 'הסרת ספרייה';
	@override String get disconnectMessage => 'להסיר את הספרייה הזאת מהפרופיל הזה? ההשאלות וההזמנות שלך יישארו בספרייה.';
	@override String get getBook => 'קבל ספר';
	@override String get checkAvailability => 'בדוק את זמינות';
	@override String get available => 'זמין להשאלה';
	@override String get unavailable => 'כרגע לא זמין';
	@override String get borrow => 'לשאול';
	@override String get placeHold => 'להזמין';
	@override String get returnBook => 'החזרה לפני המועד';
	@override String get cancelHold => 'לבטל הזמנה';
	@override String get confirmBorrow => 'האם אתה משלם את הכותרת הזו מהספרייה שלך?';
	@override String get confirmReturn => 'להחזיר את הכותר הזה עכשיו? ייתכן שיהיה צורך לשאול אותו שוב כדי להמשיך.';
	@override String get confirmCancelHold => 'לבטל את ההזמנה שלך לכותר הזה?';
	@override String get email => 'שמור הודעה בדואר אלקטרוני';
	@override String due({required Object date}) => 'מועד החזרה: ${date}';
	@override String queue({required Object position}) => 'מקום ${position} בתור';
	@override String get empty => 'אין שם עדיין כאן.';
	@override String get openLibraryNote => 'אפשר לעיין בקטלוג של Open Library. אפשרויות הקריאה וההשאלה מוצגות בעמוד של כל כותר.';
	@override String get more => 'להעלות יותר';
	@override String get gateway => 'ספרייה שירות חתימה';
	@override String get gatewayHint => 'מסופק על ידי הספרייה שלך או המנהל PlezyNG.';
	@override String get advanced => 'אינטגרציה ספרייה';
	@override String get loadLibraries => 'בחר את הספרייה שלך';
	@override String get expired => 'תקופת ההשאלה הסתיימה.';
	@override String get updated => 'ספרייה עדכנה';
	@override String get continueService => 'להמשיך בשירות';
	@override String get comingSoon => 'הלוואות ב-App · מגיע בקרוב';
	@override String get comingSoonDescription => 'אתה יכול להשתמש בספריה שלך ב- Libby בזמן שאנחנו מסיימים את חיבורו.';
	@override String get suspendHold => 'להשהות הזמנה';
	@override String get resumeHold => 'לחדש הזמנה';
	@override String get suspendMessage => 'לשמור על מקומך בתור ולאפשר לקורא הבא לשאול את העותק הזה? אפשר לחדש את ההזמנה בהמשך.';
	@override String get resumeMessage => 'לחדש את ההזמנה כדי שהספרייה תוכל להציע לך את העותק הזמין הבא?';
	@override String get editEmail => 'שינוי הודעת דואר אלקטרוני';
}

// Path: audiobook
class _Translations$audiobook$he extends Translations$audiobook$en {
	_Translations$audiobook$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get syncTitle => 'קריאה ושמיעה Sync';
	@override String get syncHelp => 'שמור על עמדות קריאה, עמדות הקשבה, מצב השלמת, תוויות ספרים והערות בכל המכשירים שלך.בחור חשבון אחסון מקושר ולהשתמש באותו קוד סינכרון בכל מכשיר.קריאה ושמיעה נשארים נפרדים.';
	@override String get addSyncSource => 'הוסף Google Drive, OneDrive, Dropbox, WebDAV או S3 בקבצים וספרים קודם.';
	@override String get syncDestination => 'חשבונות אחסון Sync';
	@override String get syncFolder => 'סינכרון קובץ או Prefix';
	@override String get syncFolderHelp => 'השתמש בתיקיה קיימת נפרדת בתוך מקור WebDAV שלך, או תיקיה מוקדמת S3.';
	@override String get syncCode => 'קוד סינכרון פרטי';
	@override String get syncCodeHelp => 'יצירת קוד על המכשיר הראשון שלך, ולאחר מכן הקלד את הקוד על המכשירים האחרים שלך.שמור עותק פרטי: זה המפתח למצב הצפנה שלך.';
	@override String get showCode => 'הצג או להסתיר קוד סינכרון';
	@override String get newSyncCode => 'יצירת קוד סינכרון חדש';
	@override String get saveSync => 'שמור וסינכרון';
	@override String get disableSync => 'הפסקת סינכרון במכשיר זה';
	@override String get syncSourceDisconnect => 'הסרת מקור זה יפסיק לקרוא ולהקשיב סינכרון כאן.';
	@override String get syncReconnect => 'חיבור מחדש לחשבון אחסון';
	@override String lastSynced({required Object time}) => 'תגית: ${time}';
	@override String get syncPrivacy => 'רק התקדמות מוצפנת והערות מאוחסנות. קבצי אודיו וספרים אלקטרוניים, טוקנים של חשבון וסיסמאות אינם מועברים. Google Drive ו- OneDrive משתמשים אחסון אפליקציות; Dropbox משתמשת ב- PlezyNG Sync. מאפשרת סינקה עשויה לבקש גישה כתיבה נוספת. בעוד מאוחסנת, יעד זה מחזיק ב- Progress Sync; התקדמות השרת נשארת נפרדת.';
	@override String get syncConflicts => 'בחר איפה להחזיר';
	@override String get conflictHelp => 'שינויים אלה נעשו באופן עצמאי.בחרו את המיקום או גרסת הסימון כדי לשמור.זמן מאוחר יותר או אחוז גבוה יותר לא מנצח באופן אוטומטי.';
	@override String syncDevice({required Object device}) => 'מכשיר ${device}';
	@override String get syncUnknownDevice => 'מכשיר לא ידוע';
	@override String get deletedBookmark => 'ספריה שנמחקו';
	@override String get finished => 'הסתיימה';
	@override String readingPosition({required Object percent}) => 'קריאה · ${percent}%';
	@override String get chapterTimeline => 'פרק התקדמות';
	@override String get bookTimeline => 'כל הספר התקדמות';
	@override String bookRemaining({required Object time}) => 'זמן שנשאר בספר זה: ${time}';
	@override String chapterRemaining({required Object time}) => 'זמן שנשאר בפרק זה: ${time}';
	@override String get unknownRemaining => 'זמן מלא זמין כאשר חלקים משחקים';
	@override String get undoSeek => 'לאחרונה מחפשים';
	@override String get customSpeed => 'מהירות Playback Custom';
	@override String get speedHelp => 'בחר מהירות של 0.25× עד 4×.';
	@override String get apply => 'יישום';
	@override String get customSleep => 'שעות שינה מותאמות אישית';
	@override String get sleepMinutes => 'דקות (1 – 1440)';
	@override String sleepChapters({required Object count}) => 'עקבו אחרי ${count}';
	@override String get extendSleep => 'להוסיף 5 דקות';
	@override String sleepRemaining({required Object time}) => 'זמן שינה: ${time}';
	@override String get useDefaults => 'השתמש בקונסולות האזנה אלה עבור ספרים חדשים';
	@override String get librarySort => 'ספרים מגוונים';
	@override String get sortTitle => 'כותרת';
	@override String get sortAuthor => 'סופר';
	@override String get sortNarrator => 'סיפורי';
	@override String get sortSeries => 'סדרת הוראות';
	@override String get sortRecent => 'נפתח לאחרונה';
	@override String get statusFilter => 'מצב קריאה';
	@override String get statusAll => 'כל הספרים';
	@override String get statusNew => 'לא התחיל';
	@override String get statusProgress => 'התקדמות';
	@override String get statusFinished => 'הסתיימה';
	@override String get goToTime => 'ללכת בזמן';
	@override String get timeHelp => 'שעות: דקות: שניות או דקות: שניות';
}

// Path: sourceSetup
class _Translations$sourceSetup$he extends Translations$sourceSetup$en {
	_Translations$sourceSetup$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get savedCertificate => 'אישור השרת השמור';
	@override String get nfsEndpointInvalid => 'יש להזין כתובת NFS, למשל nfs://nas:2049/export.';
	@override String get dlnaNone => 'לא נמצאו שרתי DLNA. יש להזין ידנית את כתובת תיאור ההתקן.';
	@override String get dlnaServers => 'שרתי מדיה של DLNA';
	@override String get dlnaUnavailable => 'גילוי DLNA אינו זמין ברשת הזו. יש להזין ידנית את כתובת תיאור ההתקן.';
	@override String get dlnaSearching => 'מתבצע חיפוש שרתי DLNA ברשת המקומית';
	@override String get networkSearching => 'מתבצע חיפוש ברשת המקומית…';
	@override String get dlnaDiscover => 'גילוי שרתי DLNA';
	@override String get dlnaHelp => 'הגילוי תלוי בשידור מרובה יעדים ברשת המקומית. אם לא מופיע שרת, יש להזין למעלה את כתובת תיאור ההתקן שלו.';
	@override String get dlnaRoot => 'מזהה אובייקט DLNA; יש להשאיר ריק כדי להשתמש בתיקיית השורש של ההתקן.';
	@override String get passwordOrKey => 'יש להזין סיסמה או להוסיף מפתח פרטי למטה.';
	@override String get sshFingerprint => 'טביעת אצבע SHA256 של מפתח מארח SSH';
	@override String get sshFingerprintHelp => 'יש לאמת מול מנהל השרת. בשרת, יש להריץ ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub ולהשתמש בערך SHA256 שמתקבל.';
	@override String get sshFingerprintKeep => 'יש להשאיר ריק כדי לשמור על טביעת האצבע המקובעת הנוכחית, או להזין טביעת אצבע חדשה של השרת.';
	@override String get sshAuthentication => 'אימות באמצעות מפתח ציבורי של SSH';
	@override String get sshAuthenticationHelp => 'לא חובה; אפשר גם לבצע אימות באמצעות סיסמה.';
	@override String get privateKey => 'מפתח פרטי (בפורמט PEM או OpenSSH)';
	@override String get privateKeyPassphrase => 'סיסמה להגנת המפתח הפרטי';
	@override String get nfsMountPort => 'יציאת TCP של שירות העיגון של NFS';
	@override String get nfsMountPortHelp => 'ברירת מחדל: 20048';
	@override String get nfsUserId => 'מזהה משתמש NFS ‏(AUTH_SYS)';
	@override String get nfsUserIdHelp => 'ברירת מחדל: 1000. יש להשתמש במזהה המותר בהגדרות ייצוא NFS של ה־NAS.';
	@override String get nfsGroupId => 'מזהה קבוצת NFS ‏(AUTH_SYS)';
	@override String get nfsGroupIdHelp => 'ברירת מחדל: 1000. יש להשתמש במזהה הקבוצה המותר בהגדרות ייצוא NFS של ה־NAS.';
	@override String get nfsEncryption => 'דרישת NFS מוצפן (RPC-with-TLS)';
	@override String get nfsEncryptionHelp => 'מחייב TLS 1.3 עבור NFS ושירות העיגון. אם ה־NAS אינו תומך בכך, החיבור יידחה.';
	@override String get nfsTrustCertificate => 'אישור CA או שרת NFS מותאם אישית (PEM, רשות)';
	@override String get nfsTrustHelp => 'יש להשאיר ריק לאישורים שהתקן זה נותן בהם אמון. לפי הצורך, אפשר להוסיף אישור CA פרטי או אישור שרת בחתימה עצמית; השמות בו חייבים להתאים למארח שבכתובת NFS.';
	@override String get nfsTrustInvalid => 'יש להשתמש באישור CA או שרת בפורמט PEM. אין לכלול מפתח פרטי.';
	@override String get addTrustCertificate => 'הוספת אישור אמון מותאם אישית';
	@override String get replaceTrustCertificate => 'החלפת האישור המותאם אישית השמור';
	@override String get nfsTlsHelp => 'RPC-with-TLS משתמש ביציאות הרגילות של NFS ושירות העיגון, ודורש תמיכה ב־RFC 9289 מצד ה־NAS. נדרש TLS 1.3. שם המארח או כתובת ה־IP חייבים להתאים לאישור. מזהי AUTH_SYS UID/GID עדיין חלים בתוך הערוץ המוצפן.';
	@override String get clientCertificate => 'אישור לקוח (רשות)';
	@override String get clientCertificateHelp => 'מאפשר ל־NAS לאמת את הלקוח הזה; מזהי AUTH_SYS עדיין כפופים למדיניות הייצוא של ה־NAS.';
	@override String get savedIdentity => 'ייעשה שימוש בפרטי הזיהוי השמורים של הלקוח.';
	@override String get replaceIdentity => 'החלפת פרטי הזיהוי השמורים של הלקוח';
	@override String get chooseIdentity => 'בחירת פרטי זיהוי לקוח בפורמט PKCS#12';
	@override String get identityPassphrase => 'סיסמה להגנת פרטי הזיהוי של הלקוח';
	@override String get identityPassphraseHelp => 'יש להשאיר ריק אם לקובץ אין סיסמה.';
	@override String get removeIdentity => 'הסרת פרטי זיהוי לקוח שמורים';
	@override String get identityStorageHelp => 'פרטי הזיהוי של הלקוחות נשמרים במאגר המוצפן של פרטי הגישה למקורות. כדי לשמור על פרטי הזיהוי הקיימים, יש להשאיר את הסעיף הזה ללא שינוי.';
	@override String get nfsLimitations => 'NFSv3 לקריאה בלבד דרך TCP. ללא RPC-with-TLS, תעבורת NFS אינה מוצפנת. ה־NAS חייב לאפשר את מזהי AUTH_SYS שנבחרו ואת יציאות הלקוח שאינן דורשות הרשאות מיוחדות (אפשרות ייצוא שנקראת בדרך כלל “insecure”). אין תמיכה ב־NFSv4 וב־UDP.';
	@override String get nfsSetupHelp => 'עזרה בהגדרת NFS';
	@override String get nfsSetupHint => 'אם החיבור לא נפתח, כדאי לבדוק את ההגדרות האלה.';
	@override String get nfsSetupDetails => 'יש להשתמש בייצוא NFSv3 דרך TCP. כשנדרשת הצפנה, גם שירות NFS וגם שירות העיגון חייבים לתמוך ב־RPC-with-TLS. אם התקן זה נותן אמון באישור השרת, יש להשאיר את האישור המותאם אישית ריק; אחרת, יש להוסיף אישור CA או אישור בחתימה עצמית של ה־NAS. שם האישור חייב להתאים למארח שבכתובת החיבור. אם ה־NAS דורש TLS הדדי, יש להוסיף את פרטי זיהוי הלקוח שלו בפורמט PKCS#12. לבסוף, יש לוודא שהייצוא מאפשר את מזהי AUTH_SYS UID/GID שהוגדרו ואת מדיניות יציאות הלקוח.';
	@override String get ftpHelp => 'FTP משתמש במצב פסיבי. עבור FTP ללא הצפנה יש להשתמש ב־ftp://, להפעלת TLS באמצעות פקודה נפרדת ב־ftpes://, או ב־ftps:// עבור TLS (ביציאה 990, TLS מתחיל מיד; ביציאות אחרות הוא מופעל באמצעות פקודה נפרדת).';
	@override String get openSubtitles => 'OpenSubtitles';
	@override String get subtitleSetup => 'חיפוש כתוביות אופציונלי לקובצי וידאו עצמאיים.';
	@override String get apiKey => 'מפתח API';
	@override String get optionalUsername => 'שם המשתמש בחשבון (רשות)';
	@override String get optionalPassword => 'סיסמת החשבון (רשות)';
	@override String get subtitlePrivacy => 'אפשר לקבל מפתח API מ־opensubtitles.com. החיפוש שולח את שם הווידאו ואת מזהי IMDb/TMDB הזמינים, ולעולם לא את קובץ הווידאו. המפתח ופרטי החשבון האופציונליים נשמרים בהצפנה עם המקור הזה.';
	@override String get automaticMetadata => 'אחזור אוטומטי של מטא־נתוני וידאו מקוונים';
	@override String get metadataPrivacy => 'נשלחים רק שם היצירה, השנה ומספרי הפרקים מתוך שם הקובץ, או מזהה NFO. מדיה ופרטי גישה לעולם אינם נשלחים. לשדות NFO נשמרת עדיפות.';
	@override String get nfsEncryptionFailure => 'עבור NFS מוצפן, יש לבדוק תמיכה ב־RFC 9289 וב־TLS 1.3 בשני שירותי ה־NAS, את שם האישור ואת מזהי UID/GID של הייצוא. PlezyNG לא ינסה שוב את החיבור הזה ללא הצפנה.';
	@override String get sourceConnecting => 'מתבצע חיבור למקור';
	@override String get metadataSearchPrivacy => 'חיפוש השם הזה נשלח ל־Trakt. נשלח רק השם שהוזן, ולא הווידאו או פרטי הגישה למקור.';
	@override String get chooseMatch => 'בחירת תוצאה תואמת';
	@override String get metadataMatchHelp => 'לפני הבחירה, יש לבדוק את השם והשנה. Trakt מקבל את שם החיפוש; הווידאו נשאר במקור שלו.';
	@override String get metadataNoMatches => 'לא נמצאו שמות תואמים בחיפוש המקוון. כדאי לנסות שם אחר.';
	@override String get metadataSearch => 'חיפוש מטא־נתונים מקוונים';
	@override String get metadataLoading => 'מתבצע חיפוש מקוון של פרטי סרטים וסדרות…';
	@override String get metadataFromTrakt => 'מטא־נתונים מקוונים מ־Trakt';
	@override String get metadataNoAutomaticMatch => 'לא נמצאה התאמה אוטומטית לשם. יש לחפש את השם כדי לבחור תוצאה תואמת.';
	@override String get metadataFailed => 'לא ניתן לטעון מטא־נתונים מקוונים. ההפעלה והפרטים המקומיים עדיין זמינים.';
	@override String get videoDetailsLoading => 'פרטי הווידאו נטענים';
	@override String get subtitleKeyRequired => 'נדרש מפתח API של OpenSubtitles';
	@override String get subtitleKeyHelp => 'יש לערוך את מקור הקבצים הזה ולהוסיף מפתח API של OpenSubtitles בהגדרות הכתוביות האופציונליות שלו.';
	@override String get subtitleSearchFailed => 'חיפוש הכתוביות נכשל. יש לבדוק את מפתח ה־API, את החיבור ואת הגישה לשירות.';
	@override String get subtitleApplyFailed => 'לא ניתן להוריד או להחיל את הכתוביות האלה. יש לבדוק את החיבור ולנסות תוצאה אחרת.';
	@override String get subtitleSearch => 'חיפוש ב־OpenSubtitles';
	@override String get subtitleSearchPrivacy => 'החיפוש משתמש בשם ובמזהי IMDb/TMDB הזמינים. קובץ הווידאו נשאר במקור שלו. לפני הבחירה, יש לבדוק את השפה, את סימוני הכתוביות הכפויות או המותאמות לכבדי שמיעה, ואת הדירוג.';
	@override String get movieOrShow => 'סרט או סדרה';
	@override String get subtitleTitleHint => 'יש להזין שם כדי לצמצם את התוצאות';
	@override String get subtitleLanguage => 'שפת הכתוביות';
	@override String get subtitleSearching => 'מתבצע חיפוש ב־OpenSubtitles';
	@override String get subtitleNoMatches => 'לא נמצאו כתוביות תואמות. כדאי לנסות שם או שפה אחרים.';
	@override String get downloadSubtitle => 'הורדת כתוביות';
	@override String get subtitle => 'כתוביות';
	@override String get nfsTlsRequired => 'נדרש RPC-with-TLS';
	@override String get nfsUnencrypted => 'NFS לא מוצפן';
	@override String get tlsEncrypted => 'מוצפן באמצעות TLS';
	@override String get ftpPlain => 'FTP לא מוצפן';
	@override String get sshPinned => 'הצפנת SSH · מפתח המארח מקובע';
	@override String get smbEncrypted => 'הצפנת SMB3 מופעלת';
	@override String get smbUnencrypted => 'הצפנת SMB3 כבויה';
	@override String get httpUnencrypted => 'HTTP ללא הצפנת תעבורה';
	@override String get checkEndpointSecurity => 'יש לבדוק את אבטחת כתובת החיבור';
	@override String fieldRequired({required Object label}) => 'חובה למלא את השדה ${label}.';
	@override String integerRange({required Object label, required Object min, required Object max}) => 'יש להזין עבור ${label} ערך בין ${min} ל־${max}.';
	@override String replaceFile({required Object name}) => 'החלפת ${name}';
	@override String selectedIdentity({required Object name}) => 'פרטי זיהוי הלקוח שנבחרו: ${name}';
	@override String subtitleRating({required Object rating}) => 'דירוג ${rating}';
	@override String subtitleDownloading({required Object title}) => 'הכתוביות בהורדה: ${title}';
}

// Path: games
class _Translations$games$he extends Translations$games$en {
	_Translations$games$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

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
	@override String get helpBody => 'Enable Games for your profile, choose a computer and approve the first connection. Sunshine-compatible hosts load their app list into the game grid. On Android, Steam pairing opens Big Picture inside PlezyNG; saved Steam app-ID shortcuts launch directly. Steam pairing does not grant access to a private account library.\n\nBoth Android engines include touch controls and gamepad input. Other native platforms and the Pyrowave decoder are still in development.\n\nPairing requires the host’s approval. Sunshine QR codes open its PIN page without carrying credentials. For access away from home, use the computer’s VPN address. Automatic discovery normally stays on the local network.\n\nDisconnecting leaves the game running on the computer.';
	@override String get cancel => 'Cancel';
	@override String get scanning => 'Looking for computers…';
	@override String get saveShortcut => 'Save shortcut';
	@override String get manualHint => 'For Moonlight use the host’s GameStream HTTP port (usually 47989), not its web settings port. Steam normally advertises on 27036.';
	@override String get engineUnavailable => 'In-app streaming is not available here yet';
	@override String get nativeEnginePending => 'This build does not include a streaming engine for this platform. You can save the computer, but it cannot play here yet.';
	@override String get steamEnginePending => 'This build does not include the embedded Steam engine. Android builds with Games enabled bundle device pairing and in-app H.264/HEVC playback. Other platforms and Pyrowave remain under development.';
	@override String get steamBetaTitle => 'Steam beta · Pyrowave';
	@override String get steamBetaDescription => 'Steam’s Pyrowave beta is a GPU-decoded video codec. It is not enabled in this build: Steam packet framing and GPU presentation still need integration and host validation. The embedded Android Steam player currently requests H.264 or HEVC.';
	@override String get steamLibrary => 'Steam library';
	@override String get connecting => 'Connecting…';
	@override String get disconnect => 'Disconnect';
	@override String get streamControls => 'Stream controls';
	@override String get steamPairInstructions => 'Enter this code in Steam’s Remote Play pairing prompt on your computer. Keep this screen open until Steam approves.';
	@override String get steamLibraryHint => 'Steam device pairing opens its library inside the stream. Add a shortcut with a Steam app ID for direct launch. Importing a private account library as game cards requires a separate authenticated catalog connection.';
}

// Path: appIcon.names
class _Translations$appIcon$names$he extends Translations$appIcon$names$en {
	_Translations$appIcon$names$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get midnight => 'חצות';
	@override String get ember => 'אדם';
	@override String get paper => 'נייר';
	@override String get oled => 'OLED';
	@override String get line => 'קו';
	@override String get ocean => 'אוקיינוס';
	@override String get ultraviolet => 'אולטרסאונד';
	@override String get matcha => 'תחרות';
	@override String get sunset => 'שקיעה';
	@override String get gold => 'זהב';
	@override String get titanium => 'טיטניום';
	@override String get glass => 'זכוכית';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => 'סינתזה';
	@override String get pixel => 'פיקסל';
	@override String get neon => 'ניון';
	@override String get sticker => 'סטייקר';
	@override String get ticket => 'כרטיסים';
	@override String get pop => 'פופ';
	@override String get strata => 'רחוב';
	@override String get facet => 'פנים';
	@override String get tilde => 'טילד';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$he extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

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
class _Translations$common$mediaKind$he extends Translations$common$mediaKind$en {
	_Translations$common$mediaKind$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get movie => 'סרט';
	@override String get show => 'תצוגה';
	@override String get season => 'עונה';
	@override String get episode => 'פרק';
	@override String get artist => 'אמן';
	@override String get album => 'אלבום';
	@override String get track => 'רצועה';
	@override String get collection => 'אוספים';
	@override String get playlist => 'רשימת ניגון';
	@override String get clip => 'קליפ';
	@override String get photo => 'תמונה';
	@override String get folder => 'תיקייה';
}

// Path: themeEditor.slots
class _Translations$themeEditor$slots$he extends Translations$themeEditor$slots$en {
	_Translations$themeEditor$slots$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get bg => 'רקע';
	@override String get surface => 'משטח';
	@override String get outline => 'outline';
	@override String get text => 'טקסט';
	@override String get textMuted => 'טקסט שנתי';
	@override String get accent => 'הדגש';
}

// Path: themeEditor.contrast
class _Translations$themeEditor$contrast$he extends Translations$themeEditor$contrast$en {
	_Translations$themeEditor$contrast$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => 'טקסט על רקע';
	@override String get textOnSurface => 'טקסט על פני השטח';
	@override String get textMutedOnBg => 'טקסט אחר על רקע';
	@override String get textMutedOnSurface => 'טקסט שנייה על פני השטח';
	@override String get accentOnBg => 'הדגש על רקע';
	@override String get accentOnSurface => 'הדגש על פני השטח';
	@override String get labelOnAccent => 'תגית: כפתור על הדגש';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$he extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'משחק / הפסקה';
	@override String get volumeUp => 'Volume למעלה';
	@override String get volumeDown => 'Volume למטה';
	@override String seekForward({required Object seconds}) => 'מחפש קדימה (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'מחפש בחזרה (${seconds}s)';
	@override String get fullscreenToggle => 'עקבו אחרי Fullscreen Fullscreen';
	@override String get muteToggle => 'יחד עם מוט';
	@override String get subtitleToggle => 'עקבו אחרי subtitles subtitles';
	@override String get audioTrackNext => 'הבא ה-Audio Track';
	@override String get subtitleTrackNext => 'הבא תגית: Track';
	@override String get chapterNext => 'פרק הבא';
	@override String get chapterPrevious => 'הפרק הקודם';
	@override String get episodeNext => 'הפרק הבא';
	@override String get episodePrevious => 'פרק קודם';
	@override String get speedIncrease => 'הגדלת מהירות';
	@override String get speedDecrease => 'ירידה במהירות';
	@override String get speedReset => 'מחדש מהירות';
	@override String get zoomIn => 'זום ב';
	@override String get zoomOut => 'זומבים Out';
	@override String get zoomReset => 'מחדש Zoom';
	@override String get subSeekNext => 'לחפש את התחתון הבא';
	@override String get subSeekPrev => 'לחפש את התחתון הקודם';
	@override String get subtitleDelayIncrease => 'עיכוב תת-כותרות';
	@override String get subtitleDelayDecrease => 'תת-כותרות מתקדמות';
	@override String get shaderToggle => 'יחד עם Shaders';
	@override String get skipMarker => 'ספין כניסה / אשראי';
	@override String get screenshot => 'צילומי מסך';
	@override String get framePrevious => 'הקודם Frame';
	@override String get frameNext => 'הבא מסגרת';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$he extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'דרושים Android 8.0 או יותר';
	@override String get iosVersion => 'דרישות iOS 15.0 או יותר';
	@override String get permissionDisabled => 'תמונה-בתמונה מופעלת.אפשר את זה בהגדרות המערכת.';
	@override String get notSupported => 'המכשיר אינו תומך במצב תמונה בתמונה';
	@override String get voSwitchFailed => 'לא הצליח לשנות את תוצרת הווידאו לתמונה-בתמונה';
	@override String get failed => 'תמונה בתמונה לא התחילה';
	@override String get prepareFailed => 'תמונה בתמונה לא ניתן להכין';
	@override String unknown({required Object error}) => 'שגיאה התרחשה: ${error}';
}

// Path: accountPreferences.groups
class _Translations$accountPreferences$groups$he extends Translations$accountPreferences$groups$en {
	_Translations$accountPreferences$groups$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => 'אודיו & תת-כותרות';
	@override String get libraryDisplay => 'ספרייה';
	@override String get personalMedia => 'מדיה אישית';
}

// Path: accountPreferences.subtitleModes
class _Translations$accountPreferences$subtitleModes$he extends Translations$accountPreferences$subtitleModes$en {
	_Translations$accountPreferences$subtitleModes$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get none => 'בחירה ידנית';
	@override String get noneDescription => 'לעולם אל תחליף את הכותרות בעצמך.';
	@override String get defaultMode => 'עקבו אחרי track flags';
	@override String get defaultModeDescription => 'השתמש בדגלים ברירת המחדל והכפייתיים המאוחסנים על כל מסלול תת-כותרת.';
	@override String get always => 'תמיד אפשרי';
	@override String get alwaysDescription => 'סובב את שורת התחתון בשפה המועדפת בכל פעם שיש.';
	@override String get onlyForced => 'רק תת-כותרות כפייתיות';
	@override String get onlyForcedDescription => 'להעלות רק את המסלולים מסומנים ככפייתיים.';
	@override String get smart => 'תגיות: אודיו זר';
	@override String get smartDescription => 'הפוך את הכותרות רק כאשר האודיו נמצא בשפה אחרת.';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class _Translations$accountPreferences$subtitleAccessibilityOptions$he extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	_Translations$accountPreferences$subtitleAccessibilityOptions$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'מעדיפים תת-תגיות שאינן SDH';
	@override String get preferSdh => 'מעדיפים תוויות SDH';
	@override String get onlySdh => 'רק תת-כותרות SDH';
	@override String get onlyNonSdh => 'רק תת-תגיות שאינן SDH';
}

// Path: accountPreferences.forcedSubtitleOptions
class _Translations$accountPreferences$forcedSubtitleOptions$he extends Translations$accountPreferences$forcedSubtitleOptions$en {
	_Translations$accountPreferences$forcedSubtitleOptions$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => 'מעדיפים כותרות לא כפייתיות';
	@override String get preferForced => 'מעדיפים כותרות כפייתיות';
	@override String get onlyForced => 'רק תת-כותרות כפייתיות';
	@override String get onlyNonForced => 'רק כותרות לא כפייתיות';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$he extends Translations$accountPreferences$watchedIndicatorOptions$en {
	_Translations$accountPreferences$watchedIndicatorOptions$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get none => 'אף פעם';
	@override String get moviesAndShows => 'סרטים ותוכניות טלוויזיה';
	@override String get movies => 'רק סרטים';
	@override String get shows => 'רק תוכניות טלוויזיה';
}

// Path: accountPreferences.mediaReviewsOptions
class _Translations$accountPreferences$mediaReviewsOptions$he extends Translations$accountPreferences$mediaReviewsOptions$en {
	_Translations$accountPreferences$mediaReviewsOptions$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'משתמשים ומבקרים';
	@override String get usersOnly => 'משתמשים בלבד';
	@override String get criticsOnly => 'ביקורת בלבד';
	@override String get nobody => 'הסתתר';
}

// Path: discover.findNext
class _Translations$discover$findNext$he extends Translations$discover$findNext$en {
	_Translations$discover$findNext$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'מצאו את הבחירה הבאה שלכם';
	@override String get open => 'מצאו את הבחירה הבאה שלכם';
	@override String get anyTime => 'ללא הגבלת זמן';
	@override String get timeAvailable => 'כמה זמן יש לכם?';
	@override String get filters => 'בחרו מה מתאים לרגע הזה';
	@override String get watch => 'צפייה';
	@override String get listen => 'האזנה';
	@override String get read => 'קריאה';
	@override String finishable({required Object duration}) => 'אפשר לסיים בתוך ${duration}';
	@override String aboutDuration({required Object duration}) => 'כ־${duration}';
	@override String nextUnit({required Object duration}) => 'הפרק הבא · ${duration}';
	@override String totalDuration({required Object duration}) => '${duration} בסך הכול';
	@override String get timingVaries => 'משך הזמן משתנה';
	@override String get notNow => 'לא עכשיו';
	@override String get swipeHint => 'החליקו את העטיפה לכיוון אחד החצים או השתמשו בכפתורים למטה.';
	@override String get saved => 'המלצות שמורות';
	@override String savedCount({required Object count}) => 'המלצות שמורות · ${count}';
	@override String get undo => 'ביטול הפעולה האחרונה';
	@override String get details => 'פרטים';
	@override String get noPicks => 'עדיין אין אפשרויות לבחירה';
	@override String get noPicksHint => 'חברו ספרייה או הוסיפו מקור מדיה כדי להתחיל.';
	@override String get noMatches => 'אין כרגע משהו שמתאים';
	@override String get noMatchesHint => 'נסו סוג מדיה אחר או הקצו לעצמכם יותר זמן.';
	@override String get allDone => 'עברתם על כל ההמלצות';
	@override String get allDoneHint => 'התחילו מקבץ חדש כדי לראות את האפשרויות האלה שוב.';
	@override String get refresh => 'מצאו מקבץ אחר';
	@override String sourceReason({required Object source}) => 'מתוך ${source}';
	@override String libraryReason({required Object library}) => 'מתוך ${library}';
	@override String get ownedReason => 'מהספרייה שלכם';
	@override String get liveNow => 'משודר עכשיו';
	@override String get watchLive => 'צפייה בשידור חי';
	@override String get filterAnything => 'כל סוג';
	@override String get filterWatch => 'צפייה';
	@override String get filterListen => 'האזנה';
	@override String get filterRead => 'קריאה';
	@override String get twentyMinutes => '20 דקות';
	@override String get fortyFiveMinutes => '45 דקות';
	@override String get ninetyMinutes => '90 דקות';
	@override String get apply => 'החלה';
	@override String get openFailed => 'האפשרות הזו כבר לא זמינה. רעננו כדי לבדוק שוב.';
	@override String get changeFailed => 'לא ניתן לשמור את השינוי. נסו שוב.';
	@override String get savedLimit => 'רשימת ההמלצות השמורות מלאה. הסירו המלצה כדי לשמור אחרת.';
	@override String get chooseHint => 'פתחו כותר, שמרו אותו להמשך או דלגו עליו.';
	@override String get howItWorks => 'איך זה עובד';
	@override String get notNowHelp => 'דלגו על הכותר הזה כרגע. הוא יישאר בספרייה שלכם.';
	@override String get saveHelp => 'שמרו אותו בבחירות השמורות של הפרופיל הזה במכשיר הזה. השמירה אינה מורידה את התוכן.';
	@override String get openHelp => 'בחרו בעטיפה להצגת פרטים. השתמשו בפעולה הראשית כדי לנגן, לקרוא או לפתוח את הכותר.';
	@override String get controlsHelp => 'מקלדת או שלט: עברו לכפתור ולחצו על Enter או על בחירה. ביטול מחזיר את הבחירה האחרונה.';
	@override String get artworkLoading => 'טוען תמונה…';
	@override String get artworkUnavailable => 'התמונה אינה זמינה';
	@override String get savedFeedback => 'נוסף לבחירות השמורות';
	@override String get skippedFeedback => 'דולג לעת עתה';
	@override String get releaseToConfirm => 'שחררו לאישור';
	@override String get remoteHint => 'כשהעטיפה במיקוד: ← / → בחירה · לחצן בחירה: פרטים · ↑ / ↓ העברת מיקוד';
}

// Path: discover.person
class _Translations$discover$person$he extends Translations$discover$person$en {
	_Translations$discover$person$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get born => 'נולד';
	@override String get died => 'מת';
	@override String get birthplace => 'מקום לידה';
	@override String dateWithAge({required Object date, required Object age}) => '${date} (גיל ${age})';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (בגיל ${age})';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$he extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'מומלץ';
	@override String get browse => 'עיין';
	@override String get collections => 'אוספים';
	@override String get playlists => 'רשימות נגינה';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$he extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'קבוצות';
	@override String get all => 'הכול';
	@override String get movies => 'סרטים';
	@override String get shows => 'סדרות טלוויזיה';
	@override String get seasons => 'עונות';
	@override String get episodes => 'פרקים';
	@override String get artists => 'אומנים';
	@override String get albums => 'אלבומים';
	@override String get tracks => 'רצועות';
	@override String get folders => 'תיקיות';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$he extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get genre => 'ז\'אנר';
	@override String get year => 'שנה';
	@override String get contentRating => 'תוכן דירוג';
	@override String get tag => 'תגית';
	@override String get unwatched => 'לא צופה';
	@override String get unplayed => 'לא נוגן';
	@override String get favorites => 'מועדפים';
	@override String get filePath => 'מסלול קובץ';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$he extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'כותרת';
	@override String get dateAdded => 'תאריך הוספה';
	@override String get releaseDate => 'תאריך הוצאה';
	@override String get rating => 'דירוג';
	@override String get communityRating => 'דירוג קהילה';
	@override String get criticRating => 'ביקורת קריטית';
	@override String get userRating => 'שיעור המשתמש';
	@override String get datePlayed => 'תאריך ניגון';
	@override String get playCount => 'כמות ניגונים';
	@override String get productionYear => 'שנת הייצור';
	@override String get runtime => 'זמן ריצה';
	@override String get officialRating => 'דירוג רשמי';
	@override String get premiereDate => 'תאריך בכורה';
	@override String get startDate => 'תאריך התחלה';
	@override String get airTime => 'זמן אוויר';
	@override String get studio => 'סטודיו';
	@override String get random => 'אקראי';
	@override String get dateShared => 'תאריך משותף';
	@override String get latestEpisodeAirDate => 'פרק אחרון תאריך אוויר';
	@override String get lastEpisodeDateAdded => 'פרק אחרון תאריך הוספת';
	@override String get dateDownloaded => 'תאריך הורדה';
	@override String get size => 'גודל';
	@override String get library => 'ספרייה';
}

// Path: libraries.advancedFilters
class _Translations$libraries$advancedFilters$he extends Translations$libraries$advancedFilters$en {
	_Translations$libraries$advancedFilters$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get include => 'כולל';
	@override String get exclude => 'ביטול';
	@override String get any => 'כל אחד';
	@override String get yes => 'כן';
	@override String get no => 'לא';
	@override String not({required Object value}) => 'לא ${value}';
	@override String valueCount({required Object count}) => '${count} נבחר';
	@override String valueCountExcluded({required Object count}) => '${count} נמנע';
	@override String get searchValues => 'חיפוש ערכים';
	@override String get noValues => 'אין ערכים';
	@override String get matchContains => 'תוכן';
	@override String get matchNotContains => 'לא מכיל';
	@override String get matchIs => 'הוא';
	@override String get matchIsNot => 'האם לא';
	@override String get matchBeginsWith => 'מתחילים עם';
	@override String get matchEndsWith => 'הסתיימה עם';
	@override String get textHint => 'סוג למתחרים';
	@override String get from => 'מתוך';
	@override String get to => 'ל';
	@override String range({required Object from, required Object to}) => '${from} עד ${to}';
	@override String atLeast({required Object value}) => '${value} ומעלה';
	@override String atMost({required Object value}) => 'עד ${value}';
	@override String dateLastDays({required Object count}) => '${count} ימים אחרונים';
	@override String get dateLastYear => 'בשנה האחרונה';
	@override String dateOlderThanDays({required Object count}) => 'מבוגר יותר מ ${count} ימים';
	@override String get dateOlderThanYear => 'מבוגר יותר משנה אחת';
}

// Path: libraries.selection
class _Translations$libraries$selection$he extends Translations$libraries$selection$en {
	_Translations$libraries$selection$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get selectItems => 'בחירת פריטים';
	@override String selectedCount({required Object count}) => '${count} נבחר';
	@override String get actions => 'פעולות בחירה';
	@override String get confirmDescendants => 'זה משנה את כל הפרקים בתערוכות ובעונות שנבחרו.';
	@override String get confirmUnwatched => 'הפעולה גם מאפסת את התקדמות הניגון של הפריטים שנבחרו.';
	@override String confirmCount({required Object count}) => 'סכום הנבחרים: ${count}';
	@override String completed({required Object count}) => 'פריטים מעודכנים: ${count}.';
	@override String partialFailure({required Object succeeded, required Object failed}) => 'עדכון ${succeeded}; נכשל ${failed}. פריטים נכשלו נשארים נבחרים.';
}

// Path: explore.mdblistShelves
class _Translations$explore$mdblistShelves$he extends Translations$explore$mdblistShelves$en {
	_Translations$explore$mdblistShelves$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get manage => 'ניהול חקירה מדרגות';
	@override String get manageDescription => 'בחר וארגן רשימות מהחשבון שלך MDBList';
	@override String get description => 'בחירת רשימות ציבוריות של סרטים וסדרות מחשבון MDBList שלך. יש ליצור או להעתיק רשימות ב-MDBList ואז לרענן.';
	@override String get selected => 'מדרגות שנבחרו';
	@override String get available => 'רשימות חשבונות זמינות';
	@override String get noLists => 'לא הוחזרו רשימות סרטים או טלוויזיה ציבוריות. יצירת או העתק רשימה ב- MDBList, ולאחר מכן לחדש.';
	@override String get displayName => 'שמו של Shelf Display';
	@override String get nameHint => 'השאירו את השם ללימודי המקור.';
	@override String get add => 'להוסיף Shelf';
	@override String get save => 'הציל את המדרגות';
	@override String moveUp({required Object title}) => 'זורק ${title} למעלה';
	@override String moveDown({required Object title}) => 'מוריד ${title} למטה';
	@override String get unavailable => 'רשימה זו אינה זמינה.חזיר או להסיר את המאגר שלה בהגדרות.';
	@override String get rateLimited => 'MDBList הגבלת בקשה הושגה בבקשה להחזיר מאוחר יותר.';
	@override String get loadFailed => 'לא ניתן להעלות את השטיח.בדוק את החיבור שלך ואת החזרה.';
	@override String get saveFailed => 'אני לא יכול לחסוך את הכרטיסים, בבקשה תתפטר.';
	@override String get accountChanged => 'החשבון או הפרופיל השתנו; פתח מחדש את ההגדרות האלה.';
	@override String get settingsUnreadable => 'לא ניתן לקרוא שדות שנשמרו.בחרו את הרשימות שלכם שוב כדי להחליף את ההגדרות האלה.';
}

// Path: explore.rows
class _Translations$explore$rows$he extends Translations$explore$rows$en {
	_Translations$explore$rows$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'שומרים';
	@override String get recommendedMovies => 'סרטים מומלצים';
	@override String get recommendedShows => 'הצגות מומלצות';
	@override String get trendingMovies => 'סרטים טרנדים';
	@override String get trendingShows => 'תצוגות טרנד';
	@override String get popularMovies => 'סרטים פופולריים';
	@override String get popularShows => 'הופעות פופולריות';
	@override String get trendingAnime => 'אנמיה טרנד';
	@override String get suggestedAnime => 'אנמיה מומלצת';
	@override String get airingAnime => 'האנימציה העליונה';
	@override String get popularAnime => 'האנימציה הפופולרית ביותר';
	@override String get trending => 'טרנד';
	@override String get upcomingMovies => 'הסרטים הקרובים';
	@override String get upcomingShows => 'הופעות הקרובות';
}

// Path: explore.status
class _Translations$explore$status$he extends Translations$explore$status$en {
	_Translations$explore$status$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get airing => 'אוויר';
	@override String get ended => 'הסתיים';
	@override String get canceled => 'ביטול';
	@override String get upcoming => 'בקרוב';
}

// Path: explore.badge
class _Translations$explore$badge$he extends Translations$explore$badge$en {
	_Translations$explore$badge$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} פופולרי';
	@override String rankAiring({required Object n}) => '#${n} אוויר';
	@override String rankRated({required Object n}) => '#${n} דירוג';
	@override String rankTrending({required Object n}) => '#${n} טרנדים';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} ב ${season}';
	@override String watchingNow({required Object n}) => '${n} צפייה';
	@override String get available => 'זמין';
	@override String get partiallyAvailable => 'חלקית זמינה';
	@override String get availableIn4k => '4K זמין';
	@override String get requested => 'ביקוש';
	@override String get pendingApproval => 'עד אישור';
	@override String get processing => 'עיבוד';
	@override String get declined => 'דלקת';
	@override String get requestFailed => 'בקשה נכשלה';
	@override String get requested4k => '4K מבקשת';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} עונות';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => 'Ep ${episode} ב ${duration}';
	@override String nextAiringIn({required Object duration}) => 'תגית: ${duration}';
	@override String episodesShort({required Object n}) => '${n} EPS';
	@override String minutesPerEpisode({required Object n}) => '${n} דקות / דקה';
	@override String get adult => '18+';
}

// Path: explore.stats
class _Translations$explore$stats$he extends Translations$explore$stats$en {
	_Translations$explore$stats$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} רשימה';
	@override String viewersDay({required Object n}) => '${n} צפיות היום';
	@override String viewersWeek({required Object n}) => 'השבוע צפו: ${n}';
	@override String viewersMonth({required Object n}) => 'החודש צפו: ${n}';
	@override String viewersYear({required Object n}) => 'השנה צפו: ${n}';
	@override String viewersAllTime({required Object n}) => '${n} צופים';
	@override String planning({required Object n}) => '${n} תכנון לצפות';
	@override String favorited({required Object n}) => '${n} אהובים';
	@override String dropRate({required Object percent}) => '${percent} הורידו את זה';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} תגובות',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} תגובות',
	);
	@override String votes({required Object n}) => '${n} הצבעה';
	@override String watching({required Object n}) => '${n} צפו בו';
	@override String completed({required Object n}) => '${n} הושלמה';
	@override String onHold({required Object n}) => '${n} על שמירה';
	@override String dropped({required Object n}) => '${n} נעלם';
}

// Path: explore.season
class _Translations$explore$season$he extends Translations$explore$season$en {
	_Translations$explore$season$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get winter => 'חורף';
	@override String get spring => 'האביב';
	@override String get summer => 'קיץ';
	@override String get fall => 'נופל';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class _Translations$explore$format$he extends Translations$explore$format$en {
	_Translations$explore$format$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get tv => 'טלוויזיה';
	@override String get tvShort => 'טלוויזיה קצרה';
	@override String get movie => 'סרט';
	@override String get special => 'מיוחד';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => 'מוסיקה';
	@override String get other => 'אחר';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$he extends Translations$explore$sourceMaterial$en {
	_Translations$explore$sourceMaterial$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get original => 'מקורי';
	@override String get manga => 'מנגו';
	@override String get lightNovel => 'רומן אור';
	@override String get novel => 'רומן';
	@override String get visualNovel => 'רומן חזותי';
	@override String get game => 'משחק';
	@override String get webComic => 'WEB קומדיה';
	@override String get musicRelease => 'מוסיקה';
	@override String get otherMedia => 'אחר';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$he extends Translations$explore$creditRole$en {
	_Translations$explore$creditRole$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get actor => 'שחקן';
	@override String get director => 'במאי';
	@override String get writer => 'כותב';
	@override String get producer => 'במאי';
	@override String get creator => 'יוצר';
	@override String get composer => 'מלחין';
}

// Path: explore.relation
class _Translations$explore$relation$he extends Translations$explore$relation$en {
	_Translations$explore$relation$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get prequel => 'יצירה מקדימה';
	@override String get sequel => 'עקבו אחרי';
	@override String get sideStory => 'סיפור צד';
	@override String get spinOff => 'ספין-off';
	@override String get alternativeVersion => 'גרסה אלטרנטיבית';
	@override String get summary => 'סיכום';
	@override String get parentStory => 'סיפור ההורים';
	@override String get adaptation => 'התאמה';
	@override String get other => 'הקשורים';
}

// Path: explore.detail
class _Translations$explore$detail$he extends Translations$explore$detail$en {
	_Translations$explore$detail$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'כותרת מקורית';
	@override String get alsoKnownAs => 'ידוע גם כ';
	@override String get studios => 'אולפני';
	@override String get country => 'ארץ';
	@override String get language => 'שפה';
	@override String get released => 'שחרור';
	@override String get physicalRelease => 'על דיסק';
	@override String get ended => 'הסתיים';
	@override String addedOn({required Object date}) => 'הוספת ${date}';
	@override String get yourRating => 'הדירוג שלך';
	@override String get budget => 'תקציב';
	@override String get revenue => 'משרד הבוקס';
	@override String get contentAdvisory => 'עידן הדרכה';
	@override String get tags => 'מילות מפתח';
	@override String get revealSpoilerTags => 'תגיות spoiler tags';
	@override String get links => 'שמאל';
	@override String get watchOn => 'צפו ב';
	@override String get watchTrailer => 'צפו בטריילר';
	@override String openOn({required Object site}) => 'פתוח ב ${site}';
	@override String get crew => 'צוות';
	@override String get ratings => 'דירוג';
	@override String get schedule => 'לו״ז';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n,
		one: 'מומלץ על ידי ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} משתמשים',
		other: 'הומלץ על ידי ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} משתמשים',
	);
	@override String recommendedBy({required Object who}) => 'הוצג על ידי ${who}';
	@override String favoritedBy({required Object who}) => 'אהוב על ידי ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} עדיין לא פורסם';
	@override String recommendedByPercent({required Object percent}) => 'מומלץ על ידי ${percent} צופים';
	@override String get relatedTitles => 'כותרות קשורות';
	@override String get background => 'רקע';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$he extends Translations$liveTv$recordSettings$en {
	_Translations$liveTv$recordSettings$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get startEarly => 'מתחילים מוקדם (שניות)';
	@override String get endLate => 'סוף סוף מאוחר (שניות)';
	@override String get newOnly => 'רק פרקים חדשים';
	@override String get anyChannel => 'רשום בכל ערוץ';
	@override String get anyTime => 'רשומה בכל עת';
	@override String get skipInLibrary => 'קפיצה של פרקים כבר בספריה';
	@override String get keepUpTo => 'אירועים שצריך לשמור';
	@override String get keepUpToHint => '0 שומרים על כל פרק';
}

// Path: music.discography
class _Translations$music$discography$he extends Translations$music$discography$en {
	_Translations$music$discography$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'סינגלים & EPs';
	@override String get live => 'שידור חי';
	@override String get compilations => 'קומפוזיציה';
}

// Path: watchTogether.notices
class _Translations$watchTogether$notices$he extends Translations$watchTogether$notices$en {
	_Translations$watchTogether$notices$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name} משחק דחיסה';
	@override String get playbackStarted => 'Playback מתחיל';
	@override String paused({required Object name}) => '${name} הפסקה';
	@override String get playbackPaused => 'Playback הפסקה';
	@override String jumpedTo({required Object name, required Object position}) => '${name} קפץ ל ${position}';
	@override String roomJumpedTo({required Object position}) => 'צעד אחר צעד ${position}';
	@override String changedSpeed({required Object name, required Object speed}) => '${name} קבע את המהירות ל- ${speed}';
	@override String speedChanged({required Object speed}) => 'מהירות מוגדרת ל- ${speed}';
	@override String startedMedia({required Object name, required Object title}) => '${name} התחיל ${title}';
	@override String mediaStarted({required Object title}) => 'עכשיו לשחק ${title}';
	@override String stoppedMedia({required Object name}) => '${name} עצר את הסרטון';
	@override String get mediaStopped => 'וידאו נעצר';
	@override String waitingFor({required Object name}) => 'מחכה ל- ${name} ...';
	@override String get waitingForSomeone => 'מחכה שמישהו יתפס...';
	@override String get finished => 'הסתיימה';
	@override String hostChangedTo({required Object name}) => '${name} הוא עכשיו המארח';
	@override String get youAreNowHost => 'עכשיו אתה המארח';
	@override String joined({required Object name}) => '${name} הצטרף';
	@override String left({required Object name}) => '${name} שחרור';
	@override String get controlRefused => 'רק המארח יכול לשלוט ב-Playback';
	@override String get searchFailed => 'חלק מהשרתים לא יכלו לחפש את הסרטון של החדר';
	@override String get playBlocked => 'משחק הדפסה מתחיל';
	@override String get shareFailed => 'לא יכולתי לשתף את הסרטון הזה עם החדר';
	@override String get downloadNotShared => 'הורדות אינן משותפות עם החדר בעוד השרת שלהם הוא לא מקוון';
	@override String get openFailed => 'לא יכולתי לפתוח את הסרטון של החדר';
}

// Path: watchTogether.ended
class _Translations$watchTogether$ended$he extends Translations$watchTogether$ended$en {
	_Translations$watchTogether$ended$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get ended => 'האורח סיים את החדר';
	@override String get kicked => 'הוסרו מהחדר';
	@override String get expired => 'החדר נגמר';
	@override String get replaced => 'הצטרפו לחדר זה על מכשיר אחר';
	@override String get lost => 'איבד את הקשר לחדר';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$he extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => 'קודים יש 6 אותיות וסימנים, ללא 0, 1, I, L או O.';
	@override String get roomNotFound => 'אין שם את הקוד הזה, אולי זה נגמר.';
	@override String get roomFull => 'החדר הזה מלא.';
	@override String get roomLocked => 'המארחת סגרה את החדר.';
	@override String get relayFull => 'עכשיו זה עסוק, אז בואו ננסה שוב.';
	@override String get unreachable => 'לא יכולתי להגיע לשעון יחד רדיו.';
	@override String get rateLimited => 'כל כך הרבה ניסיונות, לחכות לרגע ולנסות שוב.';
	@override String get clientBlocked => 'גרסה זו של PlezyNG לא יכולה להשתמש ברדיו.';
	@override String get forbidden => 'רק המארח יכול לעשות את זה.';
	@override String get notInRoom => 'אתה לא בחדר.';
	@override String get alreadyInRoom => 'אתה כבר בחדר.';
	@override String get resumeFailed => 'לא יכולתי להיכנס לחדר.';
	@override String get unsupported => 'הרדיו לא תומך בזה.';
	@override String get generic => 'משהו לא בסדר, נסה שוב.';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$he extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'הורדות יפסיקו כאשר תצא מהאפליקציה';
	@override String get bannerDegraded => 'הורדות רקע עשויות להיות מוגבלות';
	@override String get bannerAction => 'פרטים';
	@override String get sheetTitle => 'הורדות רקע נעצרו';
	@override String get sheetTitleDegraded => 'הורדות רקע עשויות להיות מוגבלות';
	@override String get sheetIntro => 'Android מונע PlezyNG להוריד אמין ברקע.';
	@override String get sheetIntroDegraded => 'המכשיר שלך מגביל כאשר PlezyNG ניתן להוריד ברקע.';
	@override String get reasonBackgroundRestricted => 'השימוש ברקע של PlezyNG מוגבל.הגדר את השימוש באטריה או ברקע ל"לא מוגבל".';
	@override String get reasonStandbyRestricted => 'Android הוציא PlezyNG במצב מוגבל.';
	@override String get reasonDownloadChannelBlocked => 'הודעות הורדה מופעלות, כך התקדמות ובקרים עשויים להיות לא זמינים.';
	@override String get reasonNotificationsDisabled => 'על Android 13 או יותר, הם נדרשים עבור הורדות רקע ארוך.';
	@override String get reasonDataSaver => 'Data Saver הוא ב, אשר חסום הורדות רקע על נתונים ניידים. הורדות עדיין צריך להתבצע על Wi-Fi.';
	@override String get reasonOemUnknown => 'ההורדות נעצרו שוב ושוב כאשר PlezyNG פעל ברקע. יש לבדוק את הגדרות הסוללה או השימוש ברקע של PlezyNG.';
	@override String get openSettings => 'פתיחת הגדרות';
	@override String get stillNotWorking => 'עזרה ספציפית למכשיר';
	@override String get stillNotWorkingDescription => 'ראה שלבים עבור המכשיר שלך, או לשלוח יומן מתוך Settings › View Logs אם הבעיה ממשיכה.';
	@override String get dialogTitle => 'הורדות לא יכלו להסתיים';
	@override String get dialogDownloadAnyway => 'הורד בכל מקרה';
	@override String get dialogFixFirst => 'קבע את זה קודם';
	@override String get statusTile => 'רקע הורדות';
	@override String get statusOk => 'מותר לרוץ ברקע';
	@override String get statusBlocked => 'חסום על ידי הגדרות המערכת';
	@override String get statusDegraded => 'מוגבלת לפי הגדרות המערכת';
	@override String get statusUnknown => 'עדיין לא בדקתי';
	@override String get settingsUnavailable => 'לא ניתן לפתוח הגדרות מערכת במכשיר זה';
	@override String get linkUnavailable => 'לא יכולתי לפתוח dontkillmyapp.com במכשיר זה';
}

// Path: downloads.groupings
class _Translations$downloads$groupings$he extends Translations$downloads$groupings$en {
	_Translations$downloads$groupings$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get library => 'ספרייה';
	@override String get collections => 'אוספים';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$he extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'התחל את השרת הרחוק';
	@override String get hostAddress => 'כתובת האורחים';
	@override String get connected => 'מחוברים';
	@override String get serverRunning => 'שרת מרחוק פעיל';
	@override String get serverStopped => 'שרת מרחוק נעצר';
	@override String get serverRunningDescription => 'מכשירים ניידים ברשת שלך יכולים להתחבר לאפליקציה זו';
	@override String get serverStoppedDescription => 'הפעל את השרת כדי לאפשר למכשירים ניידים להתחבר';
	@override String get usePhoneToControl => 'השתמש במכשיר הנייד שלך כדי לשלוט באפליקציה זו';
	@override String get startServer => 'התחל את השרת';
	@override String get stopServer => 'הפסקת שרת';
	@override String get minimize => 'מינימום';
	@override String get manualAddressHint => 'כתובת חיבור ידנית:';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$he extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'מכשירים PlezyNG עם אותו חשבון Plex מופיעים כאן';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'חיבור...';
	@override String get searchingForDevices => 'מחפשים מכשירים...';
	@override String get noDevicesFound => 'אין מכשירים שנמצאו ברשת שלך';
	@override String get noDevicesHint => 'פתח PlezyNG על שולחן העבודה ושימוש באותו Wi-Fi';
	@override String get availableDevices => 'ציוד זמין';
	@override String get manualConnection => 'חיבור ידני';
	@override String get cryptoInitFailed => 'לא ניתן להתחיל חיבור מאובטח.התחבר ל- Plex קודם.';
	@override String get validationHostRequired => 'אנא הקלד את כתובת המארח';
	@override String get validationHostFormat => 'הפורמט חייב להיות IP:port (לדוגמה, 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'שימוש באותו רשת על שני המכשירים.';
	@override String get sessionNotFound => 'המכשיר לא נמצא. ודא כי PlezyNG פועל על המארח.';
	@override String get authFailed => 'שני המכשירים זקוקים לאותו חשבון Plex.';
	@override String failedToConnect({required Object error}) => 'לא הצלחתי להתחבר: ${error}';
	@override String get codeTitle => 'זוג קוד';
	@override String get codeDescription => 'הקלד את הקוד המוצג ב- Companion Remote במכשיר המארח.שני המכשירים חייבים להשתמש בגרסה שתומכת בשילוב בטוח.';
	@override String get codeInvalid => 'הקלד את כל 32 אותיות ומספרים מהקוד המארח.';
	@override String get updateRequired => 'עדכון שני המכשירים לגרסה שתומכת בשילוב בטוח.';
	@override String get hostDescription => 'הקלד את הקוד הזה פעם אחת בכל מרחוק.שמור אותו פרטי: הוא מספק שליטה על הפרופיל הזה.';
	@override String get resetCode => 'מחדש קוד זוג';
	@override String get resetDescription => 'הפסק את כל הרחובות ויוצר קוד חדש.כל הרחוב יהיה צריך להתחבר שוב.';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$he extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'רוצים להתנתק מהפגישה הרחוקה?';
	@override String get reconnecting => 'חיבור מחדש...';
	@override String attemptOf({required Object current}) => 'ניסיון ${current} מתוך 5';
	@override String get retryNow => 'החזרה עכשיו';
	@override String get tabRemote => 'מרחוק';
	@override String get tabPlay => 'נגן';
	@override String get tabMore => 'עוד';
	@override String get menu => 'תפריט';
	@override String get tabNavigation => 'Tab ניווט';
	@override String get tabDiscover => 'גילוי';
	@override String get tabLibraries => 'ספריות';
	@override String get tabSearch => 'חיפוש';
	@override String get tabDownloads => 'הורדות';
	@override String get tabSettings => 'הגדרות';
	@override String get previous => 'הקודם';
	@override String get playPause => 'משחק / הפסקה';
	@override String get next => 'הבא';
	@override String get seekBack => 'מחפשים בחזרה';
	@override String get stop => 'עצור';
	@override String get seekForward => 'חיפוש FWD';
	@override String get volume => 'מגוון';
	@override String get volumeDown => 'למטה';
	@override String get volumeUp => 'למעלה';
	@override String get fullscreen => 'מסך מלא';
	@override String get subtitles => 'כתוביות';
	@override String get audio => 'שמע';
	@override String get searchHint => 'חיפוש על שולחן העבודה';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$he extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'לא נמצאו ממשקי רשת';
	@override String get authenticationFailed => 'אימות נכשל';
	@override String serverStartFailed({required Object error}) => 'לא הצליח להתחיל שרת מרחוק: ${error}';
	@override String commandFailed({required Object error}) => 'לא הצליח לשלוח את הפקודה מרחוק: ${error}';
	@override String get joinTimedOut => 'זמן קצר להצטרף לפגישה';
	@override String get failedToConnectAnyAddress => 'לא הצלחתי להתחבר לכל כתובת';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'חיבור אבוד לאחר ניסיונות ${attempts}';
	@override String get connectionLost => 'חיבור אבוד';
}

// Path: services.names
class _Translations$services$names$he extends Translations$services$names$en {
	_Translations$services$names$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class _Translations$services$simklReconnect$he extends Translations$services$simklReconnect$en {
	_Translations$services$simklReconnect$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'מחדש Simkl';
	@override String get subtitle => 'Simkl הוא להסיר את שיטת ההרשמה באמצעות חיבור זה.התחברות מחדש פותחת simkl.com כדי לאשר PlezyNG — PlezyNG לעולם לא רואה את הסיסמה שלך.היסטוריה השעון שלך נשארת על Simkl.';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$he extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'הפעל PlezyNG על ${service}';
	@override String get instructions => 'סורק את קוד ה-QR, או תבקר בכתובת למטה ותכנס קוד זה:';
	@override String openToActivate({required Object service}) => 'פתח ${service} כדי להפעיל';
	@override String get copyCode => 'העתק קוד הפעולה';
	@override String get waitingForAuthorization => 'מחכה לאישור...';
	@override String get codeCopied => 'קוד עותק';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$he extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'הצטרפו ל- ${service}';
	@override String get body => 'סורק את קוד ה-QR הזה או פותח את ה-URL בכל מכשיר.';
	@override String openToSignIn({required Object service}) => 'פתח ${service} כדי להירשם';
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$he extends Translations$services$pendingAuth$en {
	_Translations$services$pendingAuth$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'העתק את כתובת URL';
	@override String get urlCopied => 'URL עותק';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$he extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$he._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String get title => 'ספרייה Filter';
	@override String get subtitleAllSyncing => 'סינכרון כל הספרייה';
	@override String get subtitleNoneSyncing => 'אין סינכרון';
	@override String subtitleBlocked({required Object count}) => '${count} חסום';
	@override String subtitleAllowed({required Object count}) => '${count} מותר';
	@override String get mode => 'פילטר אופנה';
	@override String get modeBlacklist => 'רשימה שחורה';
	@override String get modeWhitelist => 'מותרים';
	@override String get modeHintBlacklist => 'סינכרון כל ספרייה מלבד אלה שנבדקו למטה.';
	@override String get modeHintWhitelist => 'סנכרן רק את הספרייה שנבדקה למטה.';
	@override String get libraries => 'ספריות';
	@override String get noLibraries => 'אין ספרייה זמינה';
}

/// The flat map containing all translations for locale <he>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsHe {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'cast.chooseDevice' => 'שידור למכשיר',
			'cast.searching' => 'מחפשים מכשירים לגידול...',
			'cast.connectedTo' => ({required Object device}) => 'חיבור ל- ${device}',
			'cast.device' => 'מכשיר לשידור',
			'cast.readyToCast' => 'מוכן לשידור',
			'cast.subtitle' => 'כתוביות',
			'cast.serverNotAvailable' => 'שרת התקשורת אינו זמין.',
			'cast.stopCasting' => 'הפסקת השידור',
			'cast.castToDevice' => 'שידור למכשיר',
			'cast.noEpisodeAvailable' => 'אין פרקים זמינים להורדה.',
			'cast.startFailed' => 'לא יכול להתחיל לגרד.בדוק את השרת ולנסות שוב.',
			'automation.noActivePlayback' => 'אין וידאו פעיל כדי לשלוט.',
			'automation.profileNotFound' => 'לא ניתן היה למצוא את הפרופיל Plezy.',
			'notifications.newEpisodeTitle' => 'פרק חדש',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appIcon.title' => 'אפליקציה icon',
			'appIcon.defaultIcon' => 'ברירת מחדל',
			'appIcon.current' => 'אייקון הנוכחי',
			'appIcon.locked' => 'גישה לכל החיים נדרשת',
			'appIcon.lockedHint' => 'התחל את הניסיון של 7 ימים או לפתוח את PlezyNG לכל החיים כדי להשתמש בסמלים חלופיים.',
			'appIcon.changeFailed' => 'לא ניתן לשנות את האייקון של האפליקציה',
			'appIcon.launcherHint' => 'האייקון החדש מופיע על המסך הבית שלך ברגע שאתה עוזב PlezyNG.',
			'appIcon.tvLauncherHint' => 'הפאנר החדש מופיע ברגע שאתה עוזב PlezyNG. Android TV יכול להמשיך להציג את הפאנר הישן עד הטלוויזיה מתחילה מחדש.',
			'appIcon.names.midnight' => 'חצות',
			'appIcon.names.ember' => 'אדם',
			'appIcon.names.paper' => 'נייר',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => 'קו',
			'appIcon.names.ocean' => 'אוקיינוס',
			'appIcon.names.ultraviolet' => 'אולטרסאונד',
			'appIcon.names.matcha' => 'תחרות',
			'appIcon.names.sunset' => 'שקיעה',
			'appIcon.names.gold' => 'זהב',
			'appIcon.names.titanium' => 'טיטניום',
			'appIcon.names.glass' => 'זכוכית',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => 'סינתזה',
			'appIcon.names.pixel' => 'פיקסל',
			'appIcon.names.neon' => 'ניון',
			'appIcon.names.sticker' => 'סטייקר',
			'appIcon.names.ticket' => 'כרטיסים',
			'appIcon.names.pop' => 'פופ',
			'appIcon.names.strata' => 'רחוב',
			'appIcon.names.facet' => 'פנים',
			'appIcon.names.tilde' => 'טילד',
			'auth.signInWithPlex' => 'הצטרפו ל- Plex',
			'auth.showQRCode' => 'הצג קוד QR',
			'auth.authenticate' => 'אמיתי',
			'auth.authenticationTimeout' => 'התגובה נמשכת, בבקשה נסה שוב.',
			'auth.scanQRToSignIn' => 'סורק את קוד ה-QR הזה כדי להירשם',
			'auth.waitingForAuth' => 'מחכה לאותיות... היכנס מהדפדפן שלך.',
			'auth.useBrowser' => 'שימוש ב-Browser',
			'auth.or' => 'או',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'חיבור ל- ${product}',
			'auth.quickConnect' => 'חיבור-מהיר',
			'auth.useQuickConnect' => 'השתמש בQuick Connect',
			'auth.quickConnectInstructions' => 'פתח את Quick Connect ב- Jellyfin והזין קוד זה.',
			'auth.quickConnectWaiting' => 'מחכה לאישור...',
			'auth.quickConnectCancel' => 'בטל',
			'auth.quickConnectExpired' => 'תוקף החיבור המהיר פג. יש לנסות שוב.',
			'auth.localDataRecoveryRequired' => 'PlezyNG לא הצליח לשחזר בבטחה את פרטי ההתחברות המקומיים ואת נתוני הניגון הממתינים. יש להתחבר שוב.',
			'auth.pinCheckRejected' => 'בדיקת ה-PIN Plex נדחתה',
			'auth.connectToDirectPlex' => 'חיבור לשרת מקומי Plex',
			'common.cancel' => 'בטל',
			'common.save' => 'שמור',
			'common.close' => 'סגור',
			'common.clear' => 'ברור',
			'common.reset' => 'איתחול',
			'common.later' => 'מאוחר',
			'common.submit' => 'שלח',
			'common.confirm' => 'אישור',
			'common.retry' => 'נסה שנית',
			'common.logout' => 'להירשם',
			'common.unknown' => 'לא ידוע',
			'common.refresh' => 'רענון',
			'common.yes' => 'כן',
			'common.no' => 'לא',
			'common.delete' => 'מחק',
			'common.edit' => 'ערוך',
			'common.shuffle' => 'ערבוב',
			'common.addTo' => 'הוסף ל...',
			'common.createNew' => 'יצירת חדש',
			'common.connect' => 'התחבר',
			'common.disconnect' => 'התנתק',
			'common.play' => 'נגן',
			'common.pause' => 'השהה',
			'common.resume' => 'המשך ניגון',
			'common.error' => 'שגיאה',
			'common.search' => 'חיפוש',
			'common.home' => 'בית',
			'common.back' => 'חזרה',
			'common.settings' => 'הגדרות',
			'common.mute' => 'השתק',
			'common.ok' => 'בסדר',
			'common.off' => 'כבוי',
			'common.options' => 'אפשרויות',
			'common.seasonNumber' => ({required Object number}) => 'עונה ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'פרק ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'סעיף ${number}',
			'common.reconnect' => 'מחדש',
			'common.viewAll' => 'ראה הכל',
			'common.checkingNetwork' => 'בדק את הרשת',
			'common.loadingServers' => 'שרתים מחוברים...',
			'common.connectingToServers' => 'חיבור לשרתים...',
			'common.startingOfflineMode' => 'התחלנו במצב offline.',
			'common.loading' => 'טעינה...',
			'common.fullscreen' => 'מסך מלא',
			'common.exitFullscreen' => 'יוצא מלא מסך',
			'common.pressBackAgainToExit' => 'לחצו שוב כדי לצאת',
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
			'common.notAvailable' => 'N / A',
			'common.url' => 'URL',
			'common.letterKeys' => 'ABC',
			'common.mediaKind.movie' => 'סרט',
			'common.mediaKind.show' => 'תצוגה',
			'common.mediaKind.season' => 'עונה',
			'common.mediaKind.episode' => 'פרק',
			'common.mediaKind.artist' => 'אמן',
			'common.mediaKind.album' => 'אלבום',
			'common.mediaKind.track' => 'רצועה',
			'common.mediaKind.collection' => 'אוספים',
			'common.mediaKind.playlist' => 'רשימת ניגון',
			'common.mediaKind.clip' => 'קליפ',
			'common.mediaKind.photo' => 'תמונה',
			'common.mediaKind.folder' => 'תיקייה',
			'screens.licenses' => 'רישיונות',
			'screens.switchProfile' => 'פרופיל Switch',
			'screens.subtitleStyling' => 'עיצוב כתוביות',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'יומני רישום',
			'update.available' => 'עדכון זמין',
			'update.versionAvailable' => ({required Object version}) => 'גרסה ${version} זמינה',
			'update.currentVersion' => ({required Object version}) => 'תגית: ${version}',
			'update.skipVersion' => 'לגרד את הגירסה הזו',
			'update.viewRelease' => 'ראה שחרור',
			'update.latestVersion' => 'אתם נמצאים בגרסה האחרונה',
			'update.checkFailed' => 'לא הצלחתי לבדוק עדכונים',
			'appAccess.title' => 'נסה כל תכונה בחינם במשך 7 ימים',
			'appAccess.description' => 'התחל ניסיון של שבעה ימים עם גישה מלאה לכל תכונה PlezyNG.אין תשלום במהלך ניסיון ואין מנוי.אחרי ניסיון, רכישה אחת לכל החיים במחיר החנות שלך פותחת PlezyNG לכל החיים.',
			'appAccess.trialEndedDescription' => 'לחסום כל תכונה ב- PlezyNG לחיים עם רכישה אחת במחיר החנות שלך.',
			'appAccess.startTrial' => 'התחל את הניסוי החופשי שלי 7 ימים',
			'appAccess.trialActive' => 'המבחן המלא של 7 הימים שלך הוא פעיל.',
			'appAccess.trialEnded' => 'התביעה של 7 ימים הסתיימה',
			'appAccess.trialStartFailed' => 'לא הצלחתי לשמור את הניסוי על המכשיר הזה, בבקשה נסה שוב.',
			'appAccess.lifetimeTitle' => 'PlezyNG פתוח לכל החיים',
			'appAccess.lifetimeBody' => 'יש לך גישה לכל החיים לכל תכונה PlezyNG.',
			'appAccess.manageTitle' => 'PlezyNG גישה לכל החיים',
			'appAccess.manageDescription' => 'נסה כל תכונה בחינם במשך 7 ימים, ולאחר מכן לפתוח הכל לכל החיים עם תשלום אחד במחיר החנות שלך.',
			'appAccess.buy' => ({required Object price}) => 'לחסום כל תכונה עבור ${price}',
			'appAccess.loadingPrice' => 'מחירים של חנות ...',
			'appAccess.retryPrice' => 'מחיר החזר מחפש',
			'appAccess.restore' => 'החזרת רכישות לכל החיים',
			'appAccess.pending' => 'הרכישה שלך מחכה לתשלום או אישור.הגישה לכל החיים פוגעת ברגע שהחנות ממלאת אותה.',
			'appAccess.storeUnavailable' => 'קניות אינן זמינות.בדוק שאתה נרשם לחנות והקניות מותרות על מכשיר זה.',
			'appAccess.productNotFound' => 'הפסקת החיים PlezyNG עדיין לא זמינה בחנות זו.',
			'appAccess.productQueryFailed' => 'לא יכולתי להעלות את מחיר החנות.בדוק את החיבור שלך ולנסות שוב.',
			'appAccess.purchaseFailed' => 'הקנייה לא עברה, נסה שוב.',
			'appAccess.restoreFailed' => 'לא יכולתי להגיע לחנות כדי להחזיר את הרכישה שלך.',
			'appAccess.nothingToRestore' => 'מספר PlezyNG רכישה לכל החיים נמצאה עבור חשבון החנות הזה.',
			'settings.title' => 'הגדרות',
			'settings.supportDeveloper' => 'תמיכה PlezyNG',
			'settings.supportDeveloperDescription' => 'תרומות לתמיכה בפיתוח',
			'settings.lifetimeAccess' => 'PlezyNG גישה לכל החיים',
			'settings.language' => 'שפה',
			'settings.theme' => 'ערכת נושא',
			'settings.appearance' => 'הופעות',
			'settings.detailPage' => 'פרטים דף',
			'settings.themeSongsEnabled' => 'לשחק שירים נושאים',
			'settings.themeSongsEnabledDescription' => 'לשחק שירים נושאים זמינים תוך צפייה בפרטים של התקשורת.',
			'settings.themeSongVolume' => 'שירים מאת Volume',
			'settings.videoPlayback' => 'וידאו Playback',
			'settings.videoPlaybackDescription' => 'הגדרת התנהגות playback',
			'settings.advanced' => 'מתקדם',
			'settings.episodePosterMode' => 'סגנון פוסטר',
			'settings.seriesPoster' => 'סדרת פוסטרים',
			'settings.seasonPoster' => 'עונה פוסטר',
			'settings.episodeThumbnail' => 'טומבניה',
			'settings.showHeroSectionDescription' => 'תצוגה עם תוכן קרוסל על המסך הבית',
			'settings.secondsLabel' => 'שניות',
			'settings.minutesLabel' => 'דקות',
			'settings.secondsShort' => 'ס',
			'settings.minutesShort' => 'M',
			'settings.durationHint' => ({required Object min, required Object max}) => 'הקלד ערך (${min}-${max})',
			'settings.systemTheme' => 'מערכת',
			'settings.lightTheme' => 'אור',
			'settings.darkTheme' => 'חשוך',
			'settings.oledTheme' => 'OLED',
			'settings.emberTheme' => 'אדם',
			'settings.glacierTheme' => 'גלידה',
			'settings.forestTheme' => 'יערות',
			'settings.plumTheme' => 'פלום',
			'settings.paperTheme' => 'נייר',
			'settings.libraryDensity' => 'ספרייה עבה',
			'settings.displayScale' => 'מצגת Scale',
			'settings.compact' => 'קומפקטי',
			'settings.comfortable' => 'נוח',
			'settings.gridSpacing' => 'רשת Spacing',
			'settings.gridSpacingTight' => 'טייק',
			'settings.gridSpacingNormal' => 'רגיל',
			'settings.gridSpacingSpacious' => 'חלל',
			'settings.tvCornerSpotlightBackdrop' => 'תגית: Spotlight Backdrop',
			'settings.tvCornerSpotlightBackdropDescription' => 'הצג יצירות אמנות באור הימני העליון במקום למלא את המסך',
			'settings.viewMode' => 'צפו במצב',
			'settings.gridView' => 'רשת',
			'settings.listView' => 'רשימה',
			'settings.showHeroSection' => 'תגית: Hero Section',
			'settings.showHomeBackdrop' => 'תגית: backdrop artwork',
			'settings.showHomeBackdropDescription' => 'מציג יצירות אמנות גדולות מאחורי שורות הבית',
			'settings.contentScreensaverEnabled' => 'תגית: Screensaver',
			'settings.contentScreensaverEnabledDescription' => 'הצג יצירות אמנות במלוא המסך לאחר שהאפליקציה הפכה ל-IDLE',
			'settings.contentScreensaverDelay' => 'הפעל את המסך לאחר',
			'settings.contentScreensaverLibraries' => 'ספרייה Screensaver',
			'settings.contentScreensaverLibrariesDescription' => 'בחר איזה ספרייה מספקת עבודת אמנות שמירה על מסך.אם לא נבחרה אחת, עבודת אמנות מכל הספרייה משתמשת.',
			'settings.contentScreensaverAllLibraries' => 'כל הספריות',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} ספרייה נבחרה',
			'settings.contentScreensaverNoLibraries' => 'אין ספריית מדיה מקושרת.',
			'settings.contentScreensaverDismissHint' => 'לחץ על כל כפתור או לחץ כדי להסיר',
			'settings.newEpisodeNotifications' => 'הודעות פרק חדש',
			'settings.newEpisodeNotificationsDescription' => 'קבלת התראה כשנוסף פרק חדש לסדרה שצפית בה עד הפרק האחרון. הבדיקה מתבצעת בזמן ש-Plezy פתוח.',
			'settings.continueWatchingRowSize' => 'להמשיך לצפות בגודל שורה',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => '${label} כרטיסים',
			'settings.rowSizeCompact' => 'קומפקטי',
			'settings.rowSizeStandard' => 'סטנדרטי',
			'settings.rowSizeLarge' => 'גדול',
			'settings.continueWatchingAction' => 'להמשיך לצפות בפעולה',
			'settings.continueWatchingPlay' => 'נגן',
			'settings.continueWatchingDetails' => 'פרטים פתוחים',
			'settings.episodeAction' => 'פרק פעולה',
			'settings.episodePlay' => 'נגן',
			'settings.episodeDetails' => 'פרטים פתוחים',
			'settings.useGlobalHubs' => 'שימוש בבית Layout',
			'settings.useGlobalHubsDescription' => 'הצג חביות בית מאוחדות. אחרת השתמשו בהמלצות ספרייה.',
			'settings.showServerNameOnHubs' => 'הצג שם שרת ב- Hubs',
			'settings.showServerNameOnHubsDescription' => 'תמיד להציג את שמות השרתים בשמות ה- hub.',
			'settings.groupLibrariesByServer' => 'ספריות קבוצתיות לפי שרת',
			'settings.groupLibrariesByServerDescription' => 'ספריית צד קבוצתי מתחת לכל שרת מדיה.',
			'settings.alwaysKeepSidebarOpen' => 'תמיד שמור את הדף פתוח',
			'settings.alwaysKeepSidebarOpenDescription' => 'שורת צד נשארת מורחבת ומחוז התוכן מתאים לתאימות',
			'settings.showUnwatchedCount' => 'הצג חשבונות בלתי צפויים',
			'settings.showUnwatchedCountDescription' => 'הצג פרק לא צופה מספר על מופעים ועונות',
			'settings.showWatchedIndicators' => 'הצג אינדיקטורים שנצפו',
			'settings.showWatchedIndicatorsDescription' => 'הצג סימן בדיקת סרטים, הופעות ופרקים שנצפו',
			'settings.showEpisodeNumberOnCards' => 'הצג מספר פרק על כרטיסים',
			'settings.showEpisodeNumberOnCardsDescription' => 'הצג את מספר העונה ואת מספר הפרקים על כרטיסי הפרקים',
			'settings.showSeasonPostersOnTabs' => 'הצג פוסטרים עונתיים על Tabs',
			'settings.showSeasonPostersOnTabsDescription' => 'הצג את הפוסט של כל עונה מעל הכרטיסייה שלה',
			'settings.tvFullCardLayout' => 'כרטיסי טלוויזיה מלאים',
			'settings.tvFullCardLayoutDescription' => 'השתמש בתמונה בלבד כרטיסי טלוויזיה עם שמות שחקנים מוגזמים',
			'settings.focusGlow' => 'פוקוס גלובוס',
			'settings.focusGlowDescription' => 'צייר אור רך סביב כרטיס המוקד',
			'settings.visualEffects' => 'אפקטים חזותיים',
			'settings.visualEffectsAuto' => 'אוטומטי',
			'settings.visualEffectsAutoDescription' => 'הפחתת השפעות באופן אוטומטי על מכשירים בעלי כוח נמוך',
			'settings.visualEffectsFull' => 'מלא',
			'settings.visualEffectsReduced' => 'ירידה',
			'settings.visualEffectsReducedDescription' => 'פחות אנמיה ועבודות אמנות ברזולוציה נמוכה יותר',
			'settings.hideSpoilers' => 'הסתיר ספוילרים עבור פרקים לא נצפו',
			'settings.hideSpoilersDescription' => 'תסמינים וסיפורים של פרקים לא נצפו',
			'settings.playerBackend' => 'שחקן Backend',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'דקורטיבי חומרה',
			'settings.hardwareDecodingDescription' => 'השתמש בהאיץ חומרה כאשר זמין',
			'settings.playbackBuffer' => 'Playback בופר',
			'settings.playbackBufferAuto' => 'מכוניות (מומלץ)',
			'settings.playbackBufferLarge' => 'גדול',
			'settings.playbackBufferExtraLarge' => 'גדול מאוד',
			'settings.playbackBufferDescription' => 'בופר יותר נגד חיבורים לא יציבים.גם מוגבל על ידי גודל בופר.',
			'settings.streamBufferSize' => 'גודל בופר',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} MB',
			'settings.streamBufferSizeDescription' => 'כמה וידאו יש להעלות קדימה בעת משחק ישיר.Transcodes stop at the server\'s own transcode buffer. 0 = Auto',
			'settings.streamBufferSizeExoNote' => 'להחליף את Playback Buffer בעת הגדרת, קפס בחצי הגבול של הזיכרון של האפליקציה',
			'settings.streamBufferMegabytes' => 'מגבייטים',
			'settings.defaultQualityTitle' => 'איכות מזויפת',
			'settings.cellularQualityTitle' => 'איכות מוגבלת על תאים',
			'settings.remoteQualityTitle' => 'איכות רדיו מרחוק',
			'settings.remoteQualitySameAsDefault' => 'כמו איכות מזויפת',
			'settings.cellularQualitySameAsDefault' => 'כמו איכות מזויפת',
			'settings.directPlayCoveredQuality' => 'לצלם קטעי וידאו קטנים באיכות מקורית',
			'settings.directPlayCoveredQualityDescription' => 'משחק וידאו ישיר כבר בתוך הגבול איכות במקום להעתיק אותם',
			'settings.videoCodecs' => 'וידאו קודיק',
			'settings.videoCodecsDescription' => 'הקודקים שאינם נבדקים מועברים על ידי השרת',
			'settings.videoCodecsAlwaysAccepted' => 'תמיד מקובל',
			'settings.musicQualityTitle' => 'איכות מוזיקה',
			'settings.subtitleStyling' => 'עיצוב כתוביות',
			'settings.subtitleStylingDescription' => 'להגדיר את המראה של subtitle',
			'settings.smallSkipDuration' => 'קפיצה קצרה',
			'settings.largeSkipDuration' => 'תקופת הנחיתה הגדולה',
			'settings.rewindOnResume' => 'מחדש על סיכום',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(seconds, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} שניה', two: 'שתי שניות', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} שניות', ), 
			'settings.defaultSleepTimer' => 'זמן שינה מוגדר',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(minutes, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} דקה', two: 'שתי דקות', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} דקות', ), 
			'settings.rememberTrackSelections' => 'זכרו את הבחירה של שורות לפי הצגה/סרט',
			'settings.chooseTracksBeforePlayback' => 'בחר את האודיו ואת התת-כותרות לפני המשחק',
			'settings.chooseTracksBeforePlaybackDescription' => 'בחר את המקור של אודיו ותת-תגית רצועות לפני כל וידאו מתחיל.',
			'settings.alwaysShowSubtitlesOnDevice' => 'תמיד להציג תת-כותרות על מכשיר זה',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => 'כאשר לשרת אין תת-כותרת שנבחרה, בחר שורה מקומית.',
			'settings.autoDownloadPreferredSubtitle' => 'תגית: חסר תגיות שפה מועדפת',
			'settings.autoDownloadPreferredSubtitleDescription' => 'בחר תת-תואר זמין בשפה המועדפת שלך באופן מקומי.אם אין אחד, בבקשה מהשרת להשיג אחד כאשר תומך.',
			'settings.rememberTrackSelectionsDescription' => 'שמור אפשרויות אודיו וסובייטים לפי הצגה או סרט במכשיר זה',
			'settings.rememberTrackSelectionsBackendRule' => 'לעבוד מקומי עם Plex, Jellyfin, ו Emby; Plex ו Jellyfin יכול גם לשמור בחירות על השרת',
			'settings.followServerTrackSelections' => 'השתמש בחירות מסלול לפי פרק של השרת',
			'settings.followServerTrackSelectionsDescription' => 'על שינוי פרק, ליישם את האודיו ואת הכותרות הנבחרות על השרת במקום לשאת את הבחירה הנוכחית',
			'settings.resumeMusicOnLaunch' => 'זכרו את ישיבת המוזיקה',
			'settings.resumeMusicOnLaunchDescription' => 'פתח מחדש את השיר האחרון הפסיק איפה זה נעלם כאשר האפליקציה מתחילה',
			'settings.showChapterMarkersOnTimeline' => 'הצג תוויות פרק ב- Search Bar',
			'settings.showChapterMarkersOnTimelineDescription' => 'סגנון הבר החיפוש בגבולות הפרק',
			'settings.specialsOrdering' => 'מיוחד בסדר פרק',
			'settings.specialsOrderingDescription' => 'איפה מיוחדים משחקים בסדר השעון של מופע',
			'settings.specialsOrderingServer' => 'עקבו אחרי server order',
			'settings.specialsOrderingAirDate' => 'תאריכים לפי תאריך אוויר',
			'settings.specialsOrderingLast' => 'אחרי עונות רגילות',
			'settings.clickVideoTogglesPlayback' => 'לחצו על הווידאו כדי לשחק / לפסח',
			'settings.clickVideoTogglesPlaybackDescription' => 'לחצו על וידאו כדי לשחק/פסיקה במקום להציג שליטה.',
			'settings.videoPlayerControls' => 'בקרת וידאו',
			'settings.keyboardShortcuts' => 'קצוות מפתח',
			'settings.keyboardShortcutsDescription' => 'התאמה אישית של קצוות המקלדת',
			'settings.videoPlayerNavigation' => 'וידאו Player Navigation',
			'settings.videoPlayerNavigationDescription' => 'השתמש במפתחות אקדח כדי לעקוב אחר בקרת וידאו שחקן',
			'settings.watchTogetherRelay' => 'צפו יחד רלי',
			'settings.watchTogetherRelayDescription' => 'פסטיבל הפתיחה הציבורית מתפרסם, אלא אם כן אתה מגדיר את עצמך',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.watchTogetherRelayInvalid' => 'יש להזין כתובת בסיס תקינה של שרת הממסר בפרוטוקול HTTP או HTTPS.',
			'settings.crashReporting' => 'דיווח תאונה',
			'settings.crashReportingDescription' => 'לשלוח דיווחים על תאונות כדי לעזור לשפר את האפליקציה',
			'settings.debugLogging' => 'דבק לוגינג',
			'settings.debugLoggingDescription' => 'אפשרות לגישה מפורטת לפתרון בעיות',
			'settings.viewLogs' => 'ראה לוג',
			'settings.viewLogsDescription' => 'צפו ב-LOGS של יישום',
			'settings.clearImageCache' => 'צילום Cache',
			'settings.clearImageCacheDescription' => 'תמונות יכולות להעלות לאט יותר עד להורדה מחדש.',
			'settings.clearImageCacheSuccess' => 'תמונת ה-Cache הוסרה בהצלחה',
			'settings.resetSettings' => 'הגדרות מחדש',
			'settings.resetSettingsDescription' => 'לשחזר את ההגדרות הבסיסיות.זה לא יכול להימנע.',
			'settings.resetSettingsSuccess' => 'הגדרות מחדש בהצלחה',
			'settings.backup' => 'גיבוי',
			'settings.exportSettings' => 'הגדרות ייצוא',
			'settings.exportSettingsDescription' => 'שמור את ההעדפות שלך לקובץ',
			'settings.exportSettingsSuccess' => 'הגדרות ייצוא',
			'settings.importSettings' => 'הגדרות ייבוא',
			'settings.importSettingsDescription' => 'לשחזר העדפות מתוך קובץ',
			'settings.importSettingsConfirm' => 'זה יחליף את ההגדרות הנוכחיות שלך.',
			'settings.importSettingsSuccess' => 'הגדרות ייבוא',
			'settings.importSettingsInvalidFile' => 'קובץ זה אינו ייצוא של הגדרות PlezyNG בתוקף',
			'settings.importSettingsNoUser' => 'הקלד לפני ייבוא ההגדרות',
			'settings.cloudBackup' => 'ענן גיבוי',
			'settings.cloudBackupDescription' => 'גיבוי הגדרות הניתנות להעברה לנקודת קצה של WebDAV דרך HTTPS. חיבורי השרתים ופרטי ההתחברות נשארים במכשיר הזה.',
			'settings.cloudBackupUrl' => 'WebDAV JSON קובץ URL',
			'settings.cloudBackupUsername' => 'שם משתמש',
			'settings.cloudBackupPassword' => 'סיסמה',
			'settings.cloudBackupSaved' => 'Cloud Backup Destination נשמר',
			'settings.cloudBackupNow' => 'בחזרה עכשיו',
			'settings.cloudBackupComplete' => 'הגדרות גיבוי הועלה',
			'settings.cloudBackupRestore' => 'לשחזר גיבוי',
			'settings.cloudBackupRestoreConfirm' => 'זה יחליף את ההגדרות הניידות המתאימות במכשיר זה.',
			'settings.cloudBackupRestored' => 'הגדרות שחוזרות מענן גיבוי',
			'settings.shortcutsReset' => 'קצוות מחדש לתוך הפסקות',
			'settings.resetShortcutsConfirm' => 'זה יחליף את הקצוות המותאמים אישית שלך עם הפסקות.',
			'settings.about' => 'אודות',
			'settings.aboutDescription' => 'מידע על אפליקציות ורישיונות',
			'settings.updates' => 'עדכונים',
			'settings.updateAvailable' => 'עדכון זמין',
			'settings.checkForUpdates' => 'בדוק עדכונים',
			'settings.autoCheckUpdatesOnStartup' => 'בדוק באופן אוטומטי עדכונים על סטארט-אפ',
			'settings.autoCheckUpdatesOnStartupDescription' => 'הודעה כאשר עדכון זמין בעת ההשקה',
			'settings.validationErrorEnterNumber' => 'אנא הקלד מספר תקינה',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'חייב להיות בין ${min} ו ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'קצר שנקבע כבר ל- ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'קצר עדכון עבור ${action}',
			'settings.saveFailed' => 'אני לא יכול לשמור שינויים, נסה שוב.',
			'settings.autoPlayAndSkip' => 'משחק אוטומטי & Skip',
			'settings.autoPlayNextEpisode' => 'משחק אוטומטי - פרק הבא',
			'settings.autoPlayNextEpisodeDescription' => 'התחל את הפרק הבא באופן אוטומטי כאשר אחד נגמר',
			'settings.shuffleStartsFromBeginning' => 'שושן מתחיל בהתחלה',
			'settings.shuffleStartsFromBeginningDescription' => 'התחל כל פרק בהתחלה, כאשר צחצוח במקום לחזור',
			'settings.plexCinemaPreRoll' => 'שימוש ב-Server Cinema',
			'settings.plexCinemaPreRollDescription' => 'לשחק Plex מראש או Jellyfin ו Emby כניסות לפני הסרט מתחיל.',
			'settings.playNextCountdown' => 'המשחק הבא Countdown',
			'settings.playNextCountdownImmediate' => 'לשחק מיד',
			'settings.skipIntroMode' => 'ספין Intro',
			'settings.skipIntroModeOffDescription' => 'לשחק כניסות בדרך כלל ללא כפתור סקי',
			'settings.skipIntroModeButtonDescription' => 'הצג כפתור ספיג כאשר מתחיל אינטרו',
			'settings.skipIntroModeAutoDescription' => 'לגרד את הכניסה באופן אוטומטי לאחר האיחור למטה',
			'settings.skipCreditsMode' => 'ספין אשראי',
			'settings.skipCreditsModeOffDescription' => 'משחק אשראי בדרך כלל ללא כפתור סקי',
			'settings.skipCreditsModeButtonDescription' => 'הצג כפתור ספיג כאשר ההלוואות מתחילות',
			'settings.skipCreditsModeAutoDescription' => 'לגרד את הכרטיסים באופן אוטומטי ולשחק את הפרק הבא',
			'settings.skipAdsMode' => 'סקי Ads',
			'settings.skipAdsModeOffDescription' => 'לשחק את הפרסומות שנמצאו בדרך כלל ללא כפתור הפסקה',
			'settings.skipAdsModeButtonDescription' => 'הצג כפתור ספיג כאשר Plex מזהה פרסום',
			'settings.skipAdsModeAutoDescription' => 'הפעל את הפרסומות שנמצאו באופן אוטומטי לאחר האיחור למטה',
			'settings.musicPlayback' => 'מוזיקה Playback',
			'settings.musicSweetFades' => 'פטריות מתוקות',
			'settings.musicSweetFadesDescription' => 'מוסיקה נופלת על גבולות המסלול כאשר Plex יש נתוני רעש.',
			'settings.skipMarkerModeOff' => 'כבוי',
			'settings.skipMarkerModeButton' => 'הצג כפתור',
			'settings.skipMarkerModeAuto' => 'אוטומטית',
			'settings.forceSkipMarkerFallback' => 'כוח Fallback Markers',
			'settings.forceSkipMarkerFallbackDescription' => 'השתמש בדפוסים כותרת פרק גם כאשר Plex יש סימנים',
			'settings.theIntroDbFallback' => 'השתמש ב-TheIntroDB כפליטה intro',
			'settings.theIntroDbFallbackDescription' => 'השתמש בזמן הקהילה רק כאשר לשרת אין סימן intro.',
			'settings.autoSkipDelay' => 'טיסה לטיסה מאוחרת',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'מחכה ${seconds} שניות לפני הפריצה עצמית',
			'settings.introPattern' => 'תבנית מארק',
			'settings.introPatternDescription' => 'דפוס Regex כדי להתאים את המדענים intro בשמות פרקים',
			'settings.creditsPattern' => 'דוגמאות ל-Credit Marker',
			'settings.creditsPatternDescription' => 'דפוס Regex כדי להתאים מדגימות אשראי בכותרות פרקים',
			'settings.prerolls' => 'פרולס',
			'settings.playPrerollsBeforeMovies' => 'משחקים לפני הסרטים',
			'settings.playPrerollsBeforeMoviesDescription' => 'לשחק קליפ אקראי מתוך הבחירה שלך למטה לפני כל סרט.',
			'settings.prerollLibrary' => 'ספריית Preroll',
			'settings.prerollLibraryNotSet' => 'לא קבע',
			'settings.prerollLibraryNoneFound' => 'לא נמצאו ספרייה בשרתים שלך.',
			'settings.prerollSelection' => 'נבחרת פרלמנט',
			'settings.prerollSelectionPickLibraryFirst' => 'בחר ספרייה קודם',
			'settings.prerollSelectionNoneSelected' => 'לא נבחרו משרדים',
			'settings.prerollSelectionCount' => ({required Object count}) => '${count} נבחר',
			'settings.prerollItemPicker' => 'בחר את הפרוול',
			'settings.prerollItemPickerLoadFailed' => 'לא יכולתי להעלות פריטים מהספרייה הזו.',
			'settings.invalidRegex' => 'חוסר ביטוי רגיל',
			'settings.regex' => 'ביטוי רגיל',
			'settings.downloads' => 'הורדות',
			'settings.downloadLocationDescription' => 'בחר איפה לאחסן תוכן הורד',
			'settings.downloadLocationDefault' => 'תצוגה של App Storage (App Storage)',
			'settings.downloadLocationCustom' => 'מיקום קבוע',
			'settings.selectFolder' => 'בחר קובץ',
			'settings.resetToDefault' => 'מחדש למונח',
			'settings.currentPath' => ({required Object path}) => 'תגית: ${path}',
			'settings.downloadLocationChanged' => 'מיקום הורדה משתנה',
			'settings.downloadLocationReset' => 'הורד את המיקום מחדש ל- default',
			'settings.downloadLocationInvalid' => 'תיקיה שנבחרה אינה כתובה',
			'settings.downloadLocationPickerUnavailable' => 'בחירת תיקיות אינה זמינה במכשיר זה',
			'settings.downloadOnWifiOnly' => 'הורד רק על Wi-Fi',
			'settings.downloadOnWifiOnlyDescription' => 'מניעת הורדות כאשר נתונים סלולריים',
			'settings.autoRemoveWatchedDownloads' => 'Auto-Remove צפו בהורדות',
			'settings.autoRemoveWatchedDownloadsDescription' => 'הורד את ההורדות הנצפות באופן אוטומטי',
			'settings.autoDownloadContinueWatching' => 'הורדה אוטומטית המשך צפייה',
			'settings.autoDownloadContinueWatchingDescription' => 'שמור את הפריטים על המאגר המשך שלך הורד, ולסגור אותם ברגע שהם עוזבים את המאגר',
			'settings.downloadQuality' => 'הורד איכות',
			'settings.downloadQualityDescription' => 'Plex מכין עותק המופנה בקובץ ההורדה שלה. Jellyfin ו Emby טרנסקוד בזמן שהקובץ הורד; העברות הפסקות עשויות להיות נדרשות להתחיל מחדש.',
			'settings.askDownloadQualityEachTime' => 'בחר איכות עבור כל הורדה',
			'settings.askDownloadQualityEachTimeDescription' => 'הצג את פיקר האיכות לפני הצגת כל הורדה וידאו',
			'settings.cellularDownloadBlocked' => 'הורדות חסמו על הטלפון הנייד.השתמש Wi-Fi או לשנות את ההגדרה.',
			'settings.maxVolume' => 'עוצמת קול מרבית',
			'settings.maxVolumeDescription' => 'לאפשר הגברת עוצמת הקול מעל 100% עבור מדיה עם קול חלש',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'נוכחות עשירה',
			'settings.discordRichPresenceDescription' => 'הצג מה שאתה צופה ב- Discord',
			'settings.services' => 'שירותים',
			'settings.servicesDescription' => 'חיבור Trakt, MyAnimeList, Seerr, ועוד',
			'settings.manageLibrariesDescription' => 'מחזירים ומסתירים ספרייה',
			'settings.companionRemoteServer' => 'שרת מרחוק',
			'settings.companionRemoteServerDescription' => 'תאפשר למכשירים ניידים ברשת שלך לשלוט באפליקציה זו',
			'settings.companionRemoteServerStartFailed' => 'לא יכולתי להתחיל את שרת החברות',
			'settings.companionRemoteServerStopFailed' => 'לא יכולתי לעצור את שרת החברות.',
			'settings.autoPip' => 'צילום: Auto Picture in Picture',
			'settings.autoPipDescription' => 'כניסת תמונה בתמונה באופן אוטומטי כאשר אתה עוזב את האפליקציה במהלך הצגת',
			'settings.matchContentFrameRate' => 'תחרות תוכן Frame',
			'settings.matchContentFrameRateDescription' => 'משחק תצוגה שיעור חידוש לתוכן וידאו',
			'settings.matchContentResolution' => 'פתרון תוכן Match',
			'settings.matchContentResolutionDescription' => 'הפוך את המסך להורדה המקומית של הווידאו כך הטלוויזיה שלך מתנהלת על-ידי.',
			'settings.matchRefreshRate' => 'משחק ריחני ריחני',
			'settings.matchRefreshRateDescription' => 'תצוגת תחרות שיעור ההתחדשות בתצוגה מלאה',
			'settings.matchDynamicRange' => 'משחק דינמי Range',
			'settings.matchDynamicRangeDescription' => 'הפעל את HDR עבור תוכן HDR, ולאחר מכן לחזור ל- SDR',
			'settings.displaySwitchDelay' => 'דחיסה של Switch Delay',
			'settings.tunneledPlayback' => 'טונל Playback',
			'settings.tunneledPlaybackDescription' => 'הפעל אם HDR playback מראה וידאו שחור או תנועות סטוטרים.',
			'settings.audioPassthrough' => 'אודיו פסטה',
			'settings.audioPassthroughDescription' => 'שלח קול Dolby/DTS למקבל או לטלוויזיה שלך ללא הקוד מחדש, שמירה על הקול הסובב.',
			'settings.audioPassthroughDescriptionApple' => 'השתמש ב-Dolby Decoder המקומי של Apple עבור Dolby Digital Plus, כולל Atmos. DTS ו-TrueHD עדיין משחקים כ-PCM רב ערוצים.',
			'settings.audioPassthroughDescriptionAppleSpatial' => 'השתמש ב-Dolby Decoder המקומי של Apple עבור Dolby Digital Plus, כולל Atmos. ב- iOS, iPadOS ו- tvOS 26 או מאוחר יותר, TrueHD Atmos ו- DTS:X משחקים כאודיו חלקי.',
			'settings.audioPassthroughOverriddenByNormalization' => 'כשמדובר בנורמליזציה של צליל',
			'settings.audioChannelLimit' => 'ערוצי שמע',
			'settings.audioChannelLimitDescription' => 'לערבב את האודיו המודפס למטה עבור שמיעה, אוזניות, או HDMI הגדרות שאינן יכולות לשחק כל ערוץ',
			'settings.audioChannelLimitOriginal' => 'מקורי',
			'settings.audioChannelLimitOriginalDescription' => 'לשחק בכל ערוץ בשורה',
			'settings.audioChannelLimitSurround51' => 'עד 5.1',
			'settings.audioChannelLimitSurround51Description' => 'מעורב 7.1 למטה 5.1 עבור טלוויזיות ומקבלים אשר לוקחים רק 5.1 PCM.',
			'settings.audioChannelLimitStereo' => 'סטריאו',
			'settings.audioChannelLimitStereoDescription' => 'לערבב עד שני ערוצים עבור רמקולים סטריאו או אוזניות.',
			'settings.downmixCenterBoost' => 'ערוץ שיפור ערוץ שיפור ערוץ שיפור ערוץ שיפור ערוץ שיפור ערוץ שיפור ערוץ שיפור ערוץ שיפור ערוץ שיפור ערוץ שיפור ערוץ שיפור ערוץ שיפור ערוץ שיפור ערוץ שיפור ערוץ',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'קידום (dB)',
			'settings.downmixCenterBoostShort' => 'דב',
			'settings.audioDownmixNormalize' => 'נורמליזת טמפרטורה על Downmix',
			'settings.audioDownmixNormalizeDescription' => 'להוריד את התערובת כדי למנוע קליפ. סגור כדי לשמור על הטמפרטורה המקורית (אולי להפריע סצנות חזקות).',
			'settings.dvConversionMode' => 'Dolby Vision הפוך',
			'settings.dvConversionModeDescription' => 'בחר כיצד Dolby Vision פרופיל 7 קבצים מתבצעים.',
			'settings.dvConversionAuto' => 'אוטומטי',
			'settings.dvConversionNative' => 'נוער / נכים',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'שימוש ביכולת זיהוי המכשיר והתנהגות נורמלית',
			'settings.dvConversionNativeDescription' => 'כוח מולד DV7 ומניעת DV הפוך חזרה',
			'settings.dvConversionDv81Description' => 'כוח רצועה RPU הפוך ל Dolby Vision פרופיל 8.1',
			'settings.dvConversionHevcStripDescription' => 'רצועה Dolby Vision שכבות RPU/EL ושטח הנוכחי HEVC',
			'settings.disableDolbyVision' => 'חסר תועלת Dolby Vision',
			_ => null,
		} ?? switch (path) {
			'settings.disableDolbyVisionDescription' => 'לשחק את שכבת הקובץ HDR10 או HLG במקום Dolby Vision, כאשר יש',
			'settings.hdrSdrConversion' => 'HDR ל- SDR Conversion',
			'settings.hdrSdrConversionDescription' => 'בחר מה מחליף וידאו HDR כאשר המסך לא יכול להציג HDR.',
			'settings.hdrSdrConversionAuto' => 'אוטומטי',
			'settings.hdrSdrConversionAutoDescription' => 'מכשיר ב- Android 9 ומאוחר יותר, שחקן בגרסאות ישנות יותר',
			'settings.hdrSdrConversionDevice' => 'מכשיר',
			'settings.hdrSdrConversionDeviceDescription' => 'חומרה וידאו של המכשיר שלך מחליפה אותו מהיר ביותר, אבל הצבעים תלויים במכשיר',
			'settings.hdrSdrConversionPlayer' => 'נגן',
			'settings.hdrSdrConversionPlayerDescription' => 'צבעים עקביים, אבל 4K עשוי להסתובב על תיבות טלוויזיה ברמה נמוכה',
			'settings.deinterlace' => 'דיינטראסינג',
			'settings.deinterlaceDescription' => 'להסיר יצירות מעורבות מהסרטון מעורבב (mpv שחקנים בלבד)',
			'settings.deinterlaceOff' => 'כבוי',
			'settings.deinterlaceOffDescription' => 'הצג וידאו מעורב כפי שהוא מופשט',
			'settings.deinterlaceVideo' => 'וידאו',
			'settings.deinterlaceVideoDescription' => 'עבור צילום וידאו עבור טלוויזיה, כגון ספורט, חדשות, וקונצרטים',
			'settings.deinterlaceFilm' => 'סרטים',
			'settings.deinterlaceFilmDescription' => 'לשחזר את הקלטות המקוריות של סרטים ואנימציה טלצ\'נינג ל 29.97 fps, נפוץ על DVDs NTSC. וידאו צילום עבור סטוטרים טלוויזיה.',
			'settings.requireProfileSelectionOnOpen' => 'בקשה לפרופיל באפליקציה פתוחה',
			'settings.requireProfileSelectionOnOpenDescription' => 'הצג את בחירת הפרופיל בכל פעם שהאפליקציה נפתחת',
			'settings.forceTvMode' => 'מצב טלוויזיה כוח',
			'settings.forceTvModeDescription' => 'כוח טלוויזיה הפריסה. עבור מכשירים שאינם לזהות באופן אוטומטי.',
			'settings.startInFullscreen' => 'התחל עם מסך מלא',
			'settings.startInFullscreenDescription' => 'פתיחת PlezyNG במצב מסך מלא',
			'settings.exitFullscreenOnPlayerClose' => 'יצוא מסך מלא על שחקן סגור',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'יוצא באופן אוטומטי מסך מלא בעת סגירת שחקן הווידאו',
			'settings.autoHidePerformanceOverlay' => 'Auto-Hide ביצועים Overlay',
			'settings.autoHidePerformanceOverlayDescription' => 'הפסד את הביצועים עם בקרת המשחקים',
			'settings.showNavBarLabels' => 'הצג מפת ניווט בר תגיות',
			'settings.showNavBarLabelsDescription' => 'הצג תוויות טקסט תחת סרגל הניווט',
			'settings.startupSection' => 'סעיף Startup',
			'settings.preferredServer' => 'מעדיפים שרתים',
			'settings.preferredServerDescription' => 'עדיף את התוצאות של שרת זה תוך שמירה על כל שרת מחובר זמין.',
			'settings.preferredServerAutomatic' => 'אוטומטית',
			'settings.showExploreTab' => 'הצג חקר טב',
			'settings.showExploreTabDescription' => 'הצג את הכרטיסייה Explore עם תוכן מ- Plex Discover and connected tracker',
			'settings.hideEmptyLibraries' => 'להסתיר ספרייה ריקה',
			'settings.hideEmptyLibrariesDescription' => 'להסיר ספריות עם מספר פריטים שדווח על ידי השרת של אפס מן הניווט.',
			'settings.liveTvDefaultFavorites' => 'תגיות: ערוצים מועדפים',
			'settings.liveTvDefaultFavoritesDescription' => 'הצג רק את הערוצים האהובים עליך בעת פתיחת הטלוויזיה חיה',
			'settings.general' => 'כללי',
			'settings.generalDescription' => 'שפה, סטארט-אפ ותנהגות חלון',
			'settings.languageAndRegion' => 'שפה ואזור',
			'settings.startup' => 'סטארטאפ',
			'settings.display' => 'תצוגה',
			'settings.libraryAndCards' => 'ספרייה & כרטיסים',
			'settings.homeScreen' => 'Home מסך',
			'settings.navigation' => 'ניווט',
			'settings.window' => 'חלון',
			'settings.liveTv' => 'טלוויזיה בשידור חי',
			'settings.player' => 'נגן',
			'settings.videoAndDisplay' => 'וידאו & תצוגה',
			'settings.audio' => 'שמע',
			'settings.quality' => 'איכות',
			'settings.subtitles' => 'כתוביות',
			'settings.seekAndTiming' => 'חיפוש & זמן',
			'settings.behavior' => 'התנהגות',
			'settings.gestures' => 'גישה',
			'settings.gestureBrightnessSwipe' => 'אור סוויפ',
			'settings.gestureBrightnessSwipeDescription' => 'סובב למעלה או למטה על הקצה השמאלי כדי להתאים את הבהירות',
			'settings.gestureVolumeSwipe' => 'כמות Swipe',
			'settings.gestureVolumeSwipeDescription' => 'סובב למעלה או למטה על הגבול הימני כדי להתאים את הטמפרטורה',
			'settings.gesturePinchToZoom' => 'פינק ל-Zoom',
			'settings.gesturePinchToZoomDescription' => 'לחצו על הווידאו כדי לזום פנימה או בחוץ',
			'settings.gestureSeekSwipe' => 'חיפוש Swipe',
			'settings.gestureSeekSwipeDescription' => 'סובב שמאל או ישר בכל מקום בסרטון כדי לחפש; שחרור כדי לקפוץ',
			'settings.rememberBrightnessLevel' => 'זכרו את רמת הבהירות',
			'settings.rememberBrightnessLevelDescription' => 'התחל את המשחק בהירות שנקבעה על-ידי הסוויפ האחרון',
			'settings.controls' => 'פקדים',
			'settings.rememberPlayerChanges' => 'זוכרים את השינויים של השחקנים',
			'settings.rememberPlayerChangesDescription' => 'כאשר שינוי שנעשה במהלך המשחק נשמר וניתן להחיל מחדש',
			'settings.scopePlaybackSpeed' => 'מהירות ניגון',
			'settings.scopeShaderPreset' => 'שארד Preset',
			'settings.scopeAspectRatio' => 'יחס גובה-רוחב',
			'settings.scopeSyncOffsets' => 'תגית: Audio & Subtitle Sync',
			'settings.playerScopeOff' => 'אל תציל',
			'settings.playerScopeGlobal' => 'בכל מקום',
			'settings.playerScopeLibrary' => 'לפי ספרייה',
			'settings.playerScopeTitle' => 'לפי מופע או סרט',
			'settings.exportDialogTitle' => 'ייצוא PlezyNG הגדרות',
			'settings.followSystem' => 'לפי שפת המערכת',
			'settings.followAppLanguage' => 'כמו שפת הממשק',
			'settings.regionFormat' => 'תבניות אזוריות',
			'settings.regionFormatDescription' => 'בחירת אופן ההצגה של תאריכים, מספרים ויחידות מידה.',
			'settings.metadataLanguage' => 'שפת פרטי המדיה',
			'settings.metadataLanguageDescription' => 'השפה המועדפת לשמות ולתיאורים, כשהשרת תומך בה. העדפות השמע והכתוביות מוגדרות בנפרד.',
			'settings.experimentalDolbyVision' => 'Dolby Vision ניסיוני',
			'settings.experimentalDolbyVisionDescription' => 'שימוש במנוע הרינדור הניסיוני של FEL בהפעלה הבאה. נדרשת בנייה נפרדת של המנוע.',
			'settings.dvExperimentUnavailableDescription' => 'הניסוי הזה זמין כרגע רק ב-Linux.',
			'settings.dvCompatibilityFallback' => 'חלופת תאימות',
			'settings.dvCompatibilityFallbackDescription' => 'שימוש במנוע הרינדור הרגיל אם הניסוי לא מצליח להתחיל. נתוני FEL עלולים ללכת לאיבוד.',
			'settings.dvExperimentDiagnostics' => 'רישום יומן לניסוי הווידאו',
			'settings.dvExperimentDiagnosticsDescription' => 'הפעלת יומנים מפורטים של הנגן בהפעלה הבאה.',
			'themeEditor.builtIn' => 'בנוי',
			'themeEditor.presets' => 'נציגים',
			'themeEditor.custom' => 'מותאם אישית',
			'themeEditor.customEmpty' => 'עדיין לא נוצר',
			'themeEditor.editCustom' => 'תגית: Edit Theme',
			'themeEditor.editCustomDescription' => 'בחר את כל הצבעים בעצמך',
			'themeEditor.locked' => 'גישה לכל החיים נדרשת',
			'themeEditor.savedLocked' => 'חסכון – זמין עם גישה לכל החיים',
			'themeEditor.title' => 'נושא מותאם',
			'themeEditor.startFrom' => 'מתחילים מ',
			'themeEditor.startFromDescription' => 'העתק את כל הצבעים מתוך נושא אחר',
			'themeEditor.colors' => 'צבעים',
			'themeEditor.preview' => 'תצוגה מקדימה',
			'themeEditor.slots.bg' => 'רקע',
			'themeEditor.slots.surface' => 'משטח',
			'themeEditor.slots.outline' => 'outline',
			'themeEditor.slots.text' => 'טקסט',
			'themeEditor.slots.textMuted' => 'טקסט שנתי',
			'themeEditor.slots.accent' => 'הדגש',
			'themeEditor.opacity' => 'אופטימיות',
			'themeEditor.hexHint' => '#RRGGBB או #AARRGGBB',
			'themeEditor.fromOtherThemes' => 'מתוך נושאים אחרים',
			'themeEditor.swatchLabel' => ({required Object theme, required Object color}) => '${theme} ${color}',
			'themeEditor.contrast.textOnBg' => 'טקסט על רקע',
			'themeEditor.contrast.textOnSurface' => 'טקסט על פני השטח',
			'themeEditor.contrast.textMutedOnBg' => 'טקסט אחר על רקע',
			'themeEditor.contrast.textMutedOnSurface' => 'טקסט שנייה על פני השטח',
			'themeEditor.contrast.accentOnBg' => 'הדגש על רקע',
			'themeEditor.contrast.accentOnSurface' => 'הדגש על פני השטח',
			'themeEditor.contrast.labelOnAccent' => 'תגית: כפתור על הדגש',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, מתחת ל ${minimum} המומלץ: 1',
			'themeEditor.discardTitle' => 'מתעלמים מהשינויים?',
			'themeEditor.discardMessage' => 'שינויי הצבע שלא נשמרו יאבדו.',
			'themeEditor.discard' => 'דיסקרד',
			'themeEditor.previewCardTitle' => ({required Object number}) => 'פרק ${number}',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => '${minutes} דקות נותרה',
			'themeEditor.previewSwitch' => 'אוטופל',
			'themeEditor.previewMutedText' => 'הקוד השני קורא ככה',
			'search.hint' => 'מחפשים סרטים, מופעים, מוזיקה...',
			'search.tryDifferentTerm' => 'נסה מונח חיפוש שונה',
			'search.searchYourMedia' => 'לחפש את התקשורת שלך',
			'search.enterTitleActorOrKeyword' => 'הקלד שם, שחקן או מילת מפתח',
			'search.people' => 'אנשים',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'קצר קצר עבור ${actionName}',
			'hotkeys.clearShortcut' => 'קצר ברור',
			'hotkeys.noShortcutSet' => 'אין קצר קצר',
			'hotkeys.currentShortcut' => 'הקצר הנוכחי:',
			'hotkeys.pressToRecord' => 'בחר כדי להקליט קצר',
			'hotkeys.recordingShortcut' => 'לחץ על הקצר עכשיו',
			'hotkeys.actions.playPause' => 'משחק / הפסקה',
			'hotkeys.actions.volumeUp' => 'Volume למעלה',
			'hotkeys.actions.volumeDown' => 'Volume למטה',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'מחפש קדימה (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'מחפש בחזרה (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'עקבו אחרי Fullscreen Fullscreen',
			'hotkeys.actions.muteToggle' => 'יחד עם מוט',
			'hotkeys.actions.subtitleToggle' => 'עקבו אחרי subtitles subtitles',
			'hotkeys.actions.audioTrackNext' => 'הבא ה-Audio Track',
			'hotkeys.actions.subtitleTrackNext' => 'הבא תגית: Track',
			'hotkeys.actions.chapterNext' => 'פרק הבא',
			'hotkeys.actions.chapterPrevious' => 'הפרק הקודם',
			'hotkeys.actions.episodeNext' => 'הפרק הבא',
			'hotkeys.actions.episodePrevious' => 'פרק קודם',
			'hotkeys.actions.speedIncrease' => 'הגדלת מהירות',
			'hotkeys.actions.speedDecrease' => 'ירידה במהירות',
			'hotkeys.actions.speedReset' => 'מחדש מהירות',
			'hotkeys.actions.zoomIn' => 'זום ב',
			'hotkeys.actions.zoomOut' => 'זומבים Out',
			'hotkeys.actions.zoomReset' => 'מחדש Zoom',
			'hotkeys.actions.subSeekNext' => 'לחפש את התחתון הבא',
			'hotkeys.actions.subSeekPrev' => 'לחפש את התחתון הקודם',
			'hotkeys.actions.subtitleDelayIncrease' => 'עיכוב תת-כותרות',
			'hotkeys.actions.subtitleDelayDecrease' => 'תת-כותרות מתקדמות',
			'hotkeys.actions.shaderToggle' => 'יחד עם Shaders',
			'hotkeys.actions.skipMarker' => 'ספין כניסה / אשראי',
			'hotkeys.actions.screenshot' => 'צילומי מסך',
			'hotkeys.actions.framePrevious' => 'הקודם Frame',
			'hotkeys.actions.frameNext' => 'הבא מסגרת',
			'fileInfo.title' => 'מידע קובץ',
			'fileInfo.overview' => 'סקירה כללית',
			'fileInfo.video' => 'וידאו',
			'fileInfo.audio' => 'שמע',
			'fileInfo.subtitles' => 'כתוביות',
			'fileInfo.images' => 'תמונות מעורבות',
			'fileInfo.dataStreams' => 'זרימת נתונים',
			'fileInfo.lyrics' => 'מילות השיר',
			'fileInfo.file' => 'קובץ',
			'fileInfo.attachments' => 'אטרקציות',
			'fileInfo.delivery' => 'משלוח',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => 'גרסה ${index} של ${count}',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => 'קובץ ${index} מתוך ${count}',
			'fileInfo.noStreams' => 'השרת לא דיווח על זרמים עבור קובץ זה.',
			'fileInfo.copyPath' => 'עותק של מסלול',
			'fileInfo.pathCopied' => 'קובץ מסלול עותק',
			'fileInfo.codec' => 'מפענח',
			'fileInfo.codecTag' => 'תגית הקודק',
			'fileInfo.resolution' => 'רזולוציה',
			'fileInfo.codedResolution' => 'פתרון קוד',
			'fileInfo.bitrate' => 'קצב סיביות',
			'fileInfo.frameRate' => 'שיעור מסגרת',
			'fileInfo.rotation' => 'סיבוב',
			'fileInfo.comment' => 'איך',
			'fileInfo.audioDescription' => 'תיאור אודיו',
			'fileInfo.headerCompression' => 'כותרת Compression',
			'fileInfo.sidecarFile' => 'קובץ Sidecar',
			'fileInfo.transportTimestamp' => 'שעות תחבורה',
			'fileInfo.displayOffset' => 'תצוגה Offset',
			'fileInfo.previewFailureCode' => 'קוד הפגיעה',
			'fileInfo.previewRetries' => 'תחזית Retries',
			'fileInfo.aspectRatio' => 'יחס גובה-רוחב',
			'fileInfo.pixelAspectRatio' => 'פיקסל Aspect Ratio',
			'fileInfo.profile' => 'פרופיל',
			'fileInfo.level' => 'רמה',
			'fileInfo.bitDepth' => 'עומק ביטים',
			'fileInfo.pixelFormat' => 'פורמט הפיקסלים',
			'fileInfo.colorSpace' => 'מרחב צבע',
			'fileInfo.colorRange' => 'מגוון צבעים',
			'fileInfo.colorPrimaries' => 'צבעים ראשיים',
			'fileInfo.colorTransfer' => 'העברת צבע',
			'fileInfo.chromaSubsampling' => 'כרומה Subsampling',
			'fileInfo.chromaLocation' => 'מיקום Chroma',
			'fileInfo.scanType' => 'סוג הסריקה',
			'fileInfo.interlaced' => 'שזור',
			'fileInfo.anamorphic' => 'אנאמורפי',
			'fileInfo.referenceFrames' => 'מסגרת התייחסות',
			'fileInfo.dynamicRange' => 'מגוון דינמי',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Dolby Vision רמה',
			'fileInfo.dolbyVisionVersion' => 'Dolby Vision גרסה',
			'fileInfo.dolbyVisionLayers' => 'Dolby Vision מדרגות',
			'fileInfo.baseLayerCompatibility' => 'תאימות בסיס',
			'fileInfo.avcBitstream' => 'זרם סיביות AVC',
			'fileInfo.nalLengthSize' => 'גודל NAL',
			'fileInfo.scalingMatrix' => 'תגיות Scaling Matrix',
			'fileInfo.streamIdentifier' => 'זיהוי זרם',
			'fileInfo.streamIndex' => 'אינדיקטור זרם',
			'fileInfo.streamId' => 'זרם ID',
			'fileInfo.language' => 'שפה',
			'fileInfo.languageCode' => 'קוד שפה',
			'fileInfo.streamTitle' => 'עקבו אחרי Track Title',
			'fileInfo.channels' => 'ערוצים',
			'fileInfo.sampleRate' => 'קצב דגימה',
			'fileInfo.spatialAudio' => 'חלל אודיו',
			'fileInfo.textBased' => 'מבוסס טקסט',
			'fileInfo.subtitleFormat' => 'פורמט Sidecar',
			'fileInfo.provider' => 'הספק',
			'fileInfo.matchScore' => 'משחק נקודות',
			'fileInfo.externalDelivery' => 'ניתן לשרת בנפרד',
			'fileInfo.sidecarPath' => 'מסע סידקר',
			'fileInfo.sourceStream' => 'עותק מתוך',
			'fileInfo.temporary' => 'זמנית',
			'fileInfo.timeBase' => 'בסיס זמן',
			'fileInfo.overallBitrate' => 'כללי Bitrate',
			'fileInfo.path' => 'נתיב',
			'fileInfo.fileName' => 'שם קובץ',
			'fileInfo.size' => 'גודל',
			'fileInfo.totalSize' => 'גודל כללי',
			'fileInfo.container' => 'מכולה',
			'fileInfo.duration' => 'משך',
			'fileInfo.previewThumbnails' => 'תגית: Thumbnails',
			'fileInfo.previewIndex' => 'Preview מדד',
			'fileInfo.packetLength' => 'אורך החבילה',
			'fileInfo.filePresent' => 'הקובץ הנוכחי',
			'fileInfo.fileReadable' => 'ניתן לקרוא על ידי שרת',
			'fileInfo.streamPath' => 'זרימת דרכים',
			'fileInfo.optimizedForStreaming' => 'אופטימיזציה עבור Streaming',
			'fileInfo.has64bitOffsets' => 'היסטים של 64 סיביות',
			'fileInfo.protocol' => 'פרוטוקול',
			'fileInfo.mediaType' => 'סוג התקשורת',
			'fileInfo.sourceKind' => 'מקור טוב',
			'fileInfo.optimizedVersion' => 'גרסה אופטימלית',
			'fileInfo.optimizationTarget' => 'מטרות אופטימיזציה',
			'fileInfo.deletedAt' => 'מוחלף',
			'fileInfo.remoteSource' => 'מקור מרחוק',
			'fileInfo.infiniteStream' => 'זרם אינסופי',
			'fileInfo.directPlay' => 'משחק ישיר',
			'fileInfo.directStream' => 'זרם ישיר',
			'fileInfo.transcoding' => 'התמרה',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'גרסה ID',
			'fileInfo.fileId' => 'קובץ ID',
			'fileInfo.defaultAudioTrack' => 'עקבו אחרי Audio Track Audio Track',
			'fileInfo.defaultSubtitleTrack' => 'תגית: Subtitle Track',
			'fileInfo.subtitlesOff' => 'כבוי',
			'fileInfo.flagDefault' => 'ברירת מחדל',
			'fileInfo.flagForced' => 'מאולץ',
			'fileInfo.flagSelected' => 'נבחר',
			'fileInfo.flagExternal' => 'חיצוני',
			'fileInfo.flagHearingImpaired' => 'שמיעה פגום',
			'fileInfo.flagDub' => 'דב',
			'fileInfo.flagOriginal' => 'מקורי',
			'fileInfo.channelsMono' => 'מונו',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'פרופיל ${profile}',
			'mediaMenu.markAsWatched' => 'מארק כפי שנצפה',
			'mediaMenu.markAsUnwatched' => 'מארק כבלתי צפוי',
			'mediaMenu.removeFromContinueWatching' => 'להסיר ממשיך לצפות',
			'mediaMenu.viewDetails' => 'ראה פרטים',
			'mediaMenu.goToSeries' => 'ללכת לסדרה',
			'mediaMenu.shufflePlay' => 'שוודיה Play',
			'mediaMenu.shuffleNotAvailableOffline' => 'שוודיה לא זמינה offline',
			'mediaMenu.fileInfo' => 'מידע קובץ',
			'mediaMenu.deleteEpisodeFromServer' => 'הורד את הפרק מהשרת',
			'mediaMenu.deleteSeasonFromServer' => 'הסרת עונה מהשרת',
			'mediaMenu.deleteShowFromServer' => 'הורד את ההצגה מהשרת',
			'mediaMenu.deleteMovieFromServer' => 'הסרת סרטים מהשרת',
			'mediaMenu.deleteEpisodeTitle' => 'תסיר את הפרק הזה?',
			'mediaMenu.deleteSeasonTitle' => 'מורידים את העונה הזו?',
			'mediaMenu.deleteShowTitle' => 'תסיר את ההצגה הזאת?',
			'mediaMenu.deleteMovieTitle' => 'תסיר את הסרט הזה?',
			'mediaMenu.deleteEpisodeConfirm' => 'מחיקת פרק',
			'mediaMenu.deleteSeasonConfirm' => 'עונת הפסקה',
			'mediaMenu.deleteShowConfirm' => 'הורד את המופע',
			'mediaMenu.deleteMovieConfirm' => 'הורד סרט',
			'mediaMenu.deleteAnyway' => 'שחרור בכל מקרה',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => 'האם יש למחוק באופן קבוע את ${title} מהשרת שלך?',
			'mediaMenu.deleteMultipleWarning' => 'זה כולל את כל הפרקים ואת הקבצים שלהם.',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n, one: 'פעולה זו תמחק ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} פרק מתוכו ואת הקובץ שלו.', other: 'פעולה זו תמחק את כל ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} הפרקים שבתוכו ואת הקבצים שלהם.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n, one: 'פריט זה מאוחסן ב־${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} קובץ, שיימחק.', other: 'פריט זה מאוחסן ב־${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} קבצים, וכולם יימחקו.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n, one: 'באותו קובץ מאוחסן ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} פרק נוסף, שגם הוא יימחק:', other: 'באותו קובץ מאוחסנים ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} פרקים נוספים, שגם הם יימחקו:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'PlezyNG לא הצליח לבדוק אילו קבצים יימחקו, ולכן ייתכן שיימחקו קבצים נוספים מעבר לפריט שצוין למעלה. אפשר לבטל ולנסות שוב, או למחוק בכל זאת.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'השרת לא סיפק פרטי קבצים עבור הפריט הזה, ולכן PlezyNG לא יכול לבדוק אילו קבצים יימחקו. ייתכן שיימחקו קבצים נוספים מעבר לפריט שצוין למעלה.',
			'mediaMenu.mediaDeletedSuccessfully' => 'התקשורת הוסרה בהצלחה',
			'mediaMenu.mediaFailedToDelete' => 'לא הצלחתי למחוק את התקשורת',
			'mediaMenu.rate' => 'דירוג',
			'mediaMenu.playFromBeginning' => 'נגן מהתחלה',
			'mediaMenu.playVersion' => 'לשחק גרסה...',
			'rateSheet.title' => 'דירוג',
			'rateSheet.server' => 'שרת',
			'rateSheet.favorite' => 'מועדף',
			'rateSheet.favorited' => 'האהוב',
			'rateSheet.saved' => 'הצלחה',
			'rateSheet.notAvailable' => 'לא נמצאו משחקים',
			'rateSheet.noConnectedServices' => 'לחבר שירות בהגדרות כדי להעריך שם.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, סרטים',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, תוכנית טלוויזיה',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'נצפה',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} אחוז צפיות',
			'accessibility.mediaCardUnwatched' => 'לא נצפה',
			'accessibility.tapToPlay' => 'יש להקיש כדי לנגן',
			'accessibility.decrease' => 'ירידה',
			'accessibility.increase' => 'הגדלת',
			'accessibility.decreaseValue' => ({required Object label}) => 'ירידה ${label}',
			'accessibility.increaseValue' => ({required Object label}) => 'הגדלת ${label}',
			'accessibility.hue' => 'הו',
			'accessibility.saturation' => 'רוויה',
			'accessibility.brightness' => 'אור',
			'accessibility.hexColor' => 'Hex צבע',
			'accessibility.expandText' => 'להרחיב את הטקסט',
			'accessibility.collapseText' => 'התמוטטות טקסט',
			'accessibility.alphabetNavigation' => 'ניווט אלפבית',
			'accessibility.alphabetScrollHint' => 'יש להחליק למעלה או למטה כדי לנווט לפי אותיות',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'שורה ${row} מתוך ${rowCount}, עמודה ${column} מתוך ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'שורה ${row} מתוך ${rowCount}',
			'accessibility.autoScrollPlay' => 'משחק Auto-Scroll',
			'accessibility.autoScrollPause' => 'הפסקה אוטומטית',
			'accessibility.hueShort' => 'H',
			'accessibility.saturationShort' => 'S',
			'accessibility.valueShort' => 'V',
			'accessibility.red' => 'אדום',
			'accessibility.green' => 'ירוק',
			'accessibility.blue' => 'כחול',
			'accessibility.redShort' => 'R',
			'accessibility.greenShort' => 'G',
			'accessibility.blueShort' => 'ב',
			'accessibility.colorModeHsv' => 'HSV',
			'accessibility.colorModeRgb' => 'RGB',
			'accessibility.title' => 'גישה',
			'accessibility.summary' => 'טקסט, קונפסט, תנועה ושליטה',
			'accessibility.systemHint' => 'הגדרות הגישה של המכשיר שלך תמיד חל.אפשרויות אלה להוסיף התאמות לאורך PlezyNG.',
			'accessibility.readability' => 'קריאה וראייה',
			'accessibility.textSize' => 'גודל טקסט נוסף',
			'accessibility.preview' => 'קרא, הקשיב והצפה בקצב שלך.',
			'accessibility.boldText' => 'טקסט אינטראקציה',
			'accessibility.highContrast' => 'ניגוד גבוה',
			'accessibility.highContrastHint' => 'טקסט, קווי מתאר וסימוני מיקוד בולטים יותר על רקע בהיר או כהה.',
			'accessibility.interaction' => 'תנועה ואינטראקציה',
			'accessibility.reduceMotion' => 'הפחתת התנועה',
			'accessibility.reduceMotionHint' => 'להפסיק את התנועה של סימון המיקוד, מעברי העמודים והאפקטים הדקורטיביים.',
			'accessibility.largeTargets' => 'מטרות מגע גדולות',
			'accessibility.largeTargetsHint' => 'להגדיל את השטח של הפקדים המשותפים כדי להקל על מגע ועל ניווט בעזרת טכנולוגיות מסייעות.',
			'accessibility.navigationHint' => 'אפשר להשתמש ב-Tab וב-Shift+Tab כדי לעבור בין הפקדים, ב-Enter או ב-Space כדי להפעיל, וב-Escape או בכפתור החזרה כדי לסגור. כשספר פתוח, אפשר לשנות את הזום ואת העדפות הקריאה.',
			'tooltips.shufflePlay' => 'שושן משחק',
			'tooltips.playTrailer' => 'משחק טריילר',
			'tooltips.markAsWatched' => 'מארק כפי שנצפה',
			'tooltips.markAsUnwatched' => 'מארק כבלתי צפוי',
			'audioTracks.track' => ({required Object n}) => 'אודיו טרק ${n}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} מסגרת', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} פרמטרים', ), 
			'videoControls.audioLabel' => 'שמע',
			'videoControls.subtitlesLabel' => 'כתוביות',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => 'תיבת הדואר',
			'videoControls.fillScreen' => 'מלא מסך',
			'videoControls.stretch' => 'מתיחה',
			'videoControls.lockRotation' => 'סגור סיבוב',
			'videoControls.unlockRotation' => 'פתיחת סיבוב',
			'videoControls.timerActive' => 'זמן פעיל',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'המשחק יפסיק ב-${duration}',
			'videoControls.sleepTimerEndOfVideo' => 'סוף הסרטון הנוכחי',
			'videoControls.sleepTimerStopAtHeader' => 'להפסיק',
			'videoControls.sleepTimerDurationHeader' => 'זמן',
			'videoControls.playbackWillPauseAtEnd' => 'Playback יפסיק בסוף הסרטון',
			'videoControls.stillWatching' => 'עדיין לצפות?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'הפסקה ב ${seconds}s',
			'videoControls.continueWatching' => 'המשך',
			'videoControls.autoPlayNext' => 'המשחק הבא',
			'videoControls.playNext' => 'נגן את הבא',
			'videoControls.playButton' => 'נגן',
			'videoControls.pauseButton' => 'השהה',
			'videoControls.playbackPaused' => 'הפסקה',
			'videoControls.playbackResumed' => 'לשחק',
			'videoControls.loadingVideo' => 'טעינה וידאו',
			'videoControls.showPlaybackControls' => 'הצגת משחקים Playback',
			'videoControls.hidePlaybackControls' => 'עקבו אחרי playback playback',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'חיפוש אחורה ${seconds} שניות',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'חיפוש קדימה ${seconds} שניות',
			'videoControls.previousButton' => 'פרק קודם',
			'videoControls.nextButton' => 'הפרק הבא',
			'videoControls.previousChapterButton' => 'הפרק הקודם',
			'videoControls.nextChapterButton' => 'פרק הבא',
			'videoControls.muteButton' => 'השתק',
			'videoControls.unmuteButton' => 'ביטול השתקה',
			'videoControls.settingsButton' => 'תגית: Playback Settings',
			'videoControls.tracksButton' => 'אודיו & תת-כותרות',
			'videoControls.trackSelectionTitle' => 'בחר רצועות לפני המשחק',
			'videoControls.trackSelectionAuto' => 'בחירה אוטומטית',
			'videoControls.chaptersButton' => 'פרק',
			'videoControls.versionQualityButton' => 'גרסה ואיכות',
			'videoControls.versionColumnHeader' => 'גרסה',
			'videoControls.qualityColumnHeader' => 'איכות',
			'videoControls.qualityOriginal' => 'מקורי',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'טרנסקוד לא זמין - לשחק באיכות מקורית',
			'videoControls.subtitleUnavailableFallback' => 'תחתונים שנבחרו לא ניתן להעלות — המשך ללא תחתונים',
			'videoControls.pipButton' => 'מצלמת תמונה-in-Picture',
			'videoControls.aspectRatioButton' => 'יחס גובה-רוחב',
			'videoControls.ambientLighting' => 'תאורה סביבתית',
			'videoControls.fullscreenButton' => 'כניסה למסך מלא',
			'videoControls.exitFullscreenButton' => 'יוצא מלא מסך',
			'videoControls.alwaysOnTopButton' => 'תמיד בראש',
			'videoControls.rotationLockButton' => 'מקלדת סיבוב',
			'videoControls.lockScreen' => 'מסך סגור',
			'videoControls.screenLockButton' => 'מסך סגור',
			'videoControls.longPressToUnlock' => 'לחץ ארוך כדי לפתוח',
			'videoControls.timelineSlider' => 'וידאו Timeline',
			'videoControls.volumeSlider' => 'רמת נפח',
			'videoControls.endsAt' => ({required Object time}) => 'תגיות קשורות ${time}',
			'videoControls.pipActive' => 'משחקים ב Picture-in-Picture',
			'videoControls.pipFailed' => 'תמונה בתמונה לא התחילה',
			'videoControls.screenshotSaved' => 'צילום מסך נשמר',
			'videoControls.screenshotFailed' => 'לא יכולתי לצלם מסך',
			'videoControls.zoomPercent' => ({required Object percent}) => 'זום ${percent}%',
			'videoControls.volumePercent' => ({required Object percent}) => 'עוצמת קול ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'דרושים Android 8.0 או יותר',
			'videoControls.pipErrors.iosVersion' => 'דרישות iOS 15.0 או יותר',
			'videoControls.pipErrors.permissionDisabled' => 'תמונה-בתמונה מופעלת.אפשר את זה בהגדרות המערכת.',
			'videoControls.pipErrors.notSupported' => 'המכשיר אינו תומך במצב תמונה בתמונה',
			'videoControls.pipErrors.voSwitchFailed' => 'לא הצליח לשנות את תוצרת הווידאו לתמונה-בתמונה',
			'videoControls.pipErrors.failed' => 'תמונה בתמונה לא התחילה',
			'videoControls.pipErrors.prepareFailed' => 'תמונה בתמונה לא ניתן להכין',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'שגיאה התרחשה: ${error}',
			'videoControls.chapters' => 'פרק',
			'videoControls.noChaptersAvailable' => 'אין פרקים זמינים',
			'videoControls.queue' => 'קווי',
			'videoControls.noQueueItems' => 'אין פריטים ב- Queue',
			'videoControls.noAudioDevicesAvailable' => 'אין מכשירים אודיו זמינים',
			'videoControls.searchSubtitles' => 'חיפוש תת-כותרות',
			'videoControls.loadSubtitleFile' => 'הורד את הקובץ Subtitle',
			'videoControls.subtitleLoadFailed' => 'לא הצלחתי להעלות את הקובץ תחת הכותרת',
			'videoControls.language' => 'שפה',
			'videoControls.noSubtitlesFound' => 'לא נמצאו תת-כותרות',
			'videoControls.subtitleDownloaded' => 'Subtitle הורדה',
			'videoControls.subtitleDownloadedNotApplied' => 'תחתון הורד, אבל לא ניתן לבחור',
			'videoControls.subtitleDownloadFailed' => 'לא הצלחתי להוריד את התחתון',
			'videoControls.searchLanguages' => 'חיפוש שפות',
			'videoControls.skipIntro' => 'ספין Intro',
			'videoControls.skipCredits' => 'ספין אשראי',
			'videoControls.skipAds' => 'סקי Ads',
			'videoControls.nextEpisode' => 'הפרק הבא',
			'videoControls.subtitleTrack' => ({required Object n}) => 'רצועה ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => 'תגית: ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (החובה)',
			'videoControls.osdSubtitlesOff' => 'תגית: Off',
			'videoControls.osdSubtitles' => ({required Object track}) => 'תגית: ${track}',
			'videoControls.osdAudio' => ({required Object track}) => 'אודיו: ${track}',
			'messages.markedAsWatched' => 'מסומן כפי שנצפה',
			'messages.markedAsUnwatched' => 'מסומנים כבלתי צפויים',
			'messages.markedAsWatchedOffline' => 'מסומן כפי שנצפה (סנכרן כאשר באינטרנט)',
			'messages.markedAsUnwatchedOffline' => 'מסומן כבלתי צפוי (סנכרן כאשר באינטרנט)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'מנעול אוטומטי: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n, one: 'הורד את ה- ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} צפיות', other: 'Auto-removed ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} צפיות הורדות', ), 
			'messages.removedFromContinueWatching' => 'הוסרה ממשיכה לצפות',
			'messages.errorLoading' => ({required Object error}) => 'שגיאה: ${error}',
			'messages.searchPartialResults' => 'כמה שרתים מדיה לא יכול להיות מחפש. מציג תוצאות זמינות.',
			'messages.streamInterrupted' => 'התנועה הופסקה, התקשורת משחקת או מנסה להחזיר.',
			'messages.liveStreamInterrupted' => 'הפסקת ההפעלה הפסיקה, משחק הדו"ח נמשך.',
			'messages.fileInfoNotAvailable' => 'מידע קובץ לא זמין',
			'messages.playbackAuthenticationRequired' => 'היכנס שוב לשרת התקשורת כדי לשחק את הפריט הזה.',
			'messages.playbackServerUnavailable' => 'השרת לא זמין, נסה שוב מאוחר יותר.',
			'messages.playbackDataInvalid' => 'השרת החזיר את המידע המשחק הלא חוקי.',
			'messages.playbackCancelled' => 'Playback בוטל.',
			'messages.playbackFailed' => 'המשחק לא יכול להתחיל.',
			'messages.playbackFailedDetail' => ({required Object error}) => 'Playback לא יכול להתחיל: ${error}',
			'messages.audioOutputFailed' => 'בדוק את חיבור הקול של הטלוויזיה או של הקבלן; אם אפליקציות אחרות גם אין קול, הפעל מחדש את המכשיר.',
			'messages.mediaUnavailable' => 'תוכן זה כבר לא זמין.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'טעות טעינה קובץ מידע: ${error}',
			'messages.errorLoadingSeries' => 'שגיאות סדרת טעינה',
			'messages.musicNotSupported' => 'שחקני מוסיקה עדיין לא נתמכים',
			'messages.noDescriptionAvailable' => 'אין תיאור זמין',
			'messages.noProfilesAvailable' => 'אין פרופיל זמין',
			'messages.contactAdminForProfiles' => 'צור קשר עם מנהל השרת שלך כדי להוסיף פרופיל',
			'messages.unableToDetermineLibrarySection' => 'אי אפשר לקבוע את סעיף הספרייה עבור פריט זה',
			'messages.logsCleared' => 'לוגים נקיים',
			'messages.logsCopied' => 'קובץ העתקה ל-Clipboard',
			'messages.noLogsAvailable' => 'אין לוגים זמינים',
			'messages.libraryScanning' => ({required Object title}) => 'סריקה "${title}"',
			'messages.libraryScanStarted' => ({required Object title}) => 'סריקת הספרייה החלה עבור "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'לא הצליח לסרוק את הספרייה: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'נתונים מטא-נתונים עבור "${title}..."',
			_ => null,
		} ?? switch (path) {
			'messages.metadataRefreshStarted' => ({required Object title}) => 'מחדש נתונים מתחיל עבור "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'לא הצליח לשחזר נתונים מטאוגרפיים: ${error}',
			'messages.logoutConfirm' => 'אתה בטוח שאתה רוצה להיכנס?',
			'messages.noSeasonsFound' => 'לא נמצאו עונות',
			'messages.seasonsLoadFailed' => 'לא יכול להיות עונות',
			'messages.noEpisodesFound' => 'לא נמצאו פרקים בעונה הראשונה',
			'messages.noEpisodesFoundGeneral' => 'לא נמצאו פרקים',
			'messages.episodesLoadFailed' => 'אי אפשר להעלות את הפרקים',
			'messages.noResultsFound' => 'לא נמצאו תוצאות.',
			'messages.sleepTimerSet' => ({required Object label}) => 'זמן שינה מוגדר עבור ${label}',
			'messages.noItemsAvailable' => 'אין פריטים זמינים',
			'messages.failedToCreatePlayQueueNoItems' => 'לא הצלחתי ליצור קווי משחק - אין פריטים',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'נכשל ל ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'הפוך לשחקן תואם ...',
			'messages.serverLimitTitle' => 'Playback נכשל',
			'messages.serverLimitBody' => 'שגיאה בשרת (HTTP 500).גבול רוחב הפס / העברת קוד כנראה דחה את הפגישה הזו.',
			'messages.mediaUnreadableTitle' => 'קובץ לא זמין',
			'messages.mediaUnreadableBody' => 'השרת מצא את הפריט הזה אך לא יכול לקרוא את הקובץ שלו (HTTP 404).הקובץ כנראה הועבר, נמחק, או אחסוןו אינו מקוון.',
			'messages.serverBusyTitle' => 'זרם לא זמין',
			'messages.serverBusyBody' => 'השרת סירב לשדר את הקובץ הזה (HTTP 503).הוא עשוי להיות מחדש, עסוק, או אחסון הקובץ עשוי להיות לא מקוון.תנסה שוב ברגע - אם זה ממשיך לקרות, לבקש מהבעלים של השרת לבדוק את השרת ואת אחסון הקובץ.',
			'messages.playbackNotAllowedTitle' => 'Playback לא מותר',
			'messages.playbackNotAllowedBody' => 'השרת סירב להזרים את הפריט הזה (HTTP 403). ייתכן שלחשבון שלך אין הרשאה לנגן אותו, או שהשרת מאפשר ניגון רק ברשת המקומית שלו.',
			'messages.logsUploaded' => 'לוגים הועלו',
			'messages.logsUploadFailed' => 'לא הצלחתי להעלות לוגו',
			'messages.logId' => 'לוג ID',
			'messages.burnedSubtitlesUseMenu' => 'תת-כותרות נשרפות לתוך זרם זה.שינוי אותם מן התפריט תת-כותרות.',
			'messages.noVideoUrl' => 'אין URL וידאו',
			'messages.playbackNoMediaSources' => 'השרת לא החזיר מקורות מדיה משחק',
			'messages.playbackDataNotPrepared' => 'Playback התחיל לפני שהנתונים שלו היו מוכנים',
			'messages.streamSelectionUnavailable' => 'בחירת זרם אינה זמינה למקור זה',
			'messages.streamSelectionFailed' => 'לא ניתן להשתמש בתהליכים שנבחרו',
			'messages.trackSelectionNotRemembered' => 'בחירה זו חל רק על המשחק הנוכחי.',
			'messages.serverUnavailableForProfile' => 'אין שרתים זמינים עבור הפרופיל הפעיל',
			'subtitlingStyling.previewSample' => 'החתול הצהוב המהיר קופץ מעל הכלב המטומטם',
			'subtitlingStyling.text' => 'טקסט',
			'subtitlingStyling.border' => 'הגבול',
			'subtitlingStyling.background' => 'רקע',
			'subtitlingStyling.fontSize' => 'גודל הפורט',
			'subtitlingStyling.textColor' => 'צבע טקסט',
			'subtitlingStyling.borderSize' => 'גבול גודל',
			'subtitlingStyling.borderColor' => 'גבול צבע',
			'subtitlingStyling.backgroundOpacity' => 'רקע Opacity',
			'subtitlingStyling.backgroundColor' => 'צבע רקע',
			'subtitlingStyling.position' => 'עמדה',
			'subtitlingStyling.assOverride' => 'ASS סה"כ',
			'subtitlingStyling.overrideScale' => 'סולם',
			'subtitlingStyling.overrideForce' => 'כוח',
			'subtitlingStyling.overrideStrip' => 'להסיר סגנון',
			'subtitlingStyling.positionTop' => 'Top',
			'subtitlingStyling.positionBottom' => 'תחתון',
			'subtitlingStyling.useMargins' => 'שימוש במגוון',
			'subtitlingStyling.useMarginsDescription' => 'מותר תת-טקסטים בחלל מחוץ לווידאו.תת-טקסטים בסגנון יכולים לשמור על המיקום המקורי שלהם.',
			'subtitlingStyling.anchorToScreen' => 'אנקור לסרטון',
			'subtitlingStyling.anchorToScreenDescription' => 'הצג תת-כותרות טקסט בשורות שחורות מתחת לווידאו עם מסך רחב',
			'subtitlingStyling.bold' => 'מודגש',
			'subtitlingStyling.italic' => 'איטלקית',
			'subtitlingStyling.renderResolution' => 'רנדה פתרון',
			'subtitlingStyling.renderResolutionScreen' => 'רזולוציית מסך',
			'subtitlingStyling.renderResolutionVideo' => 'רזולוציית הוידיאו',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'הגדרות מתקדמות של שחקן וידאו',
			'mpvConfig.presets' => 'נציגים',
			'mpvConfig.noPresets' => 'אין חסד',
			'mpvConfig.saveAsPreset' => 'שמור את זה כראשון...',
			'mpvConfig.presetName' => 'שמות מראש',
			'mpvConfig.presetNameHint' => 'הקלד שם עבור הפוסט הזה',
			'mpvConfig.loadPreset' => 'משקל',
			'mpvConfig.deletePreset' => 'מחק',
			'mpvConfig.presetSaved' => 'הנסיך הציל',
			'mpvConfig.presetLoaded' => 'מראש מחוברים',
			'mpvConfig.presetDeleted' => 'כתיבה מוחלפת',
			'mpvConfig.confirmDeletePreset' => 'האם אתה בטוח שאתה רוצה למחוק את הפוסט הזה?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan hwdec=auto # comment',
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => 'להוסיף קו',
			'mpvConfig.removeLine' => 'להסיר קו',
			'mpvConfig.embeddedVoHint' => 'vo, gpu-context ו- gpu-api מתעלמים ב- Linux: וידאו מובנה תמיד משוחרר דרך vo=libmpv על מטוס הווידאו, ו- gpu-next (מה צללים מחשב כמו ArtCNN צריך) לא יכול לרוץ מובנה.',
			'dialog.confirmAction' => 'אישור פעולה',
			'profiles.addPlezyProfile' => 'הוסף פרופיל PlezyNG',
			'profiles.switchingProfile' => 'הפרופיל המשתנה',
			'profiles.deleteThisProfileTitle' => 'מורידים את הפרופיל הזה?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'הסר ${displayName}.החיבור אינו מושפע.',
			'profiles.active' => 'פעיל',
			'profiles.manage' => 'ניהול',
			'profiles.delete' => 'מחק',
			'profiles.signOut' => 'התנתק',
			'profiles.signOutPlexTitle' => 'נרשם על ידי Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'להסיר ${displayName} וכל Plex משתמשי הבית?',
			'profiles.signOutPlexDeleteDownloads' => 'הורד גם הורדות',
			'profiles.signOutPlexDeleteDownloadsDescription' => 'אחרת הם יישארו על המכשיר הזה ויחזרו כאשר אתה מחדש להיכנס לחשבון זה.',
			'profiles.signedOutPlex' => 'נחתם על ידי Plex.',
			'profiles.signOutFailed' => 'הצהרת כישלון',
			'profiles.sectionTitle' => 'פרופיל',
			'profiles.summarySingle' => 'הוספת פרופילים כדי לערבב משתמשים המנוהלים וזהות מקומית',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} פרופילים · פעיל: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} פרופיל',
			'profiles.removeConnectionTitle' => 'להסיר את הקשר?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'הסר את הגישה של ${displayName} ל- ${connectionLabel}. פרופילים אחרים שמרו את זה.',
			'profiles.deleteProfileTitle' => 'מחיקת פרופיל ?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'להסיר את ${displayName} ואת החיבורים שלו. השרתים יישארו זמינים.',
			'profiles.profileNameLabel' => 'שם פרופיל',
			'profiles.pinProtectionLabel' => 'הגנה PIN',
			'profiles.copyAutomationLink' => 'עותק Android קישור אוטומציה',
			'profiles.copyAutomationLinkDescription' => 'בחר את הפרופיל הזה מתוך כוונה או אוטומציה Android.',
			'profiles.automationLinkCopied' => 'פרופיל אוטומציה קישור עותק.',
			'profiles.pinManagedByPlex' => 'PIN מנוהל על ידי Plex. Edit on plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'כדי לבקש אחד, לערוך את המשתמש המקומי ב plex.tv.',
			'profiles.setPin' => 'פין',
			'profiles.setPinTitle' => 'פין',
			'profiles.confirmPinTitle' => 'אישור PIN',
			'profiles.pinSet' => 'פין Set',
			'profiles.changePin' => 'שינוי',
			'profiles.removePin' => 'הסר',
			'profiles.connectionsLabel' => 'קישורים',
			'profiles.add' => 'הוספה',
			'profiles.deleteProfileButton' => 'הורד פרופיל',
			'profiles.noConnectionsHint' => 'אין קישורים – הוסף אחד כדי להשתמש בפרופיל זה.',
			'profiles.noConnections' => 'אין קשרים',
			'profiles.plexHomeAccount' => 'Plex חשבון הבית',
			'profiles.plexAccountChip' => ({required Object account}) => 'Plex חשבון: ${account}',
			'profiles.plexAccountUserChip' => ({required Object user, required Object account}) => '${user} דרך ${account}',
			'profiles.connectionDefault' => 'ברירת מחדל',
			'profiles.connectionAs' => ({required Object displayName}) => 'תגית: ${displayName}',
			'profiles.makeDefault' => 'לעשות דפדפן',
			'profiles.removeConnection' => 'הסר',
			'profiles.profileRenamed' => 'הפרופיל מחדש',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'הוסף ל ${displayName}',
			'profiles.borrowExplain' => 'להשאיל את החיבור של פרופיל אחר. פרופילים מוגנים ב-PIN דורשים PIN.',
			'profiles.borrowEmpty' => 'אין עוד מה להשאיל.',
			'profiles.borrowEmptySubtitle' => 'התחבר Plex, Jellyfin, או Emby לפרופיל אחר קודם.',
			'profiles.borrowLoadFailed' => 'לא ניתן להעלות את הקשרים הזמינים, נסה שוב.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'מתוך ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'חיבור הלוואה',
			'profiles.borrowFailed' => 'לא הצלחתי להשאיל קשר.',
			'profiles.incorrectPin' => 'PIN לא נכון',
			'profiles.incorrectPinTryAgain' => 'שגיאה ב-PIN, בבקשה תנסה שוב',
			'profiles.sourceProfileMissingParentAccount' => 'פרופיל המקור חסר את חשבון הוריו.',
			'profiles.failedToLoadHomeUsers' => 'לא יכול להעלות את המשתמשים הבית Plex .בדוק את החיבור שלך ולנסות שוב.',
			'profiles.failedToVerifyPin' => 'לא הצלחתי לבדוק את ה-PIN.',
			'profiles.newProfile' => 'פרופיל חדש',
			'profiles.profileNameHint' => 'דוגמה: אורחים, ילדים, חדרי משפחה',
			'profiles.pinProtectionOptional' => 'הגנה PIN (אופציונלית)',
			'profiles.pinExplain' => 'יש צורך ב-PIN 4 דיגיטלי כדי לשנות את הפרופיל.',
			'profiles.continueButton' => 'המשך',
			'profiles.pinsDontMatch' => 'PINs לא מתאימים',
			'profiles.tokenIdentityMismatch' => 'טוקן הפרופיל Plex נפתרה לשרת בלתי צפוי',
			'profiles.settingsLocked' => 'הגדרות נעולות עבור פרופיל זה.',
			'profiles.unlockSettings' => 'פתיחת הגדרות',
			'profiles.showExploreForProfile' => 'הצג חקר עבור פרופיל זה',
			'profiles.showExploreForProfileDescription' => 'סגור כדי להסיר Explore מן הניווט של פרופיל זה.',
			'connections.sectionTitle' => 'קישורים',
			'connections.addConnection' => 'להוסיף חיבור',
			'connections.addConnectionSubtitleNoProfile' => 'היכנס עם Plex או להתחבר לשרת Jellyfin או Emby',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'הוסף ל- ${displayName}: Plex, Jellyfin, Emby, או חיבור פרופיל אחר',
			'connections.sessionExpiredOne' => ({required Object name}) => 'הפגישה נגמרה עבור ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'הפגישה נגמרה עבור ${count} שרתים',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} סירב גישה לחשבון זה',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} שרתים סירבו לגשת לחשבון זה',
			'connections.signInAgain' => 'הצטרפו שוב',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'תגית: Edit ${product} connection',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'הוספת או הסרת כתובת URL עבור ${serverName}. PlezyNG ישתמש כתובת URL הנגיעה עם הריבית הנמוכה ביותר.',
			'accountPreferences.sectionTitle' => 'העדפות חשבון',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => 'אפשרויות אודיו, תת-כותרת וספריה נשמרו ב- ${account}',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => 'אפשרויות אודיו, תת-כותרת וספריה מאוחסנות על ${count} חשבונות',
			'accountPreferences.pickAccount' => 'כל חשבון מחזיק את ההעדפות שלו.קח את אחד כדי לערוך.',
			'accountPreferences.storedOnAccount' => 'אפשרויות אלה מאוחסנות בחשבון עצמו, ולכן כל אפליקציה שנרשמה אליו משתמשת בהן – כולל PlezyNG במכשירים האחרים שלך.',
			'accountPreferences.noAccounts' => 'אין חשבונות להגדיר',
			'accountPreferences.noAccountsHint' => 'היכנס ל- Plex, או להתחבר ל- Jellyfin או ל- Emby שרת, וההעדפות שנשמרו בחשבון זה מופיעות כאן.',
			'accountPreferences.unavailable' => 'לא ניתן להגיע לחשבון זה',
			'accountPreferences.loadFailed' => 'לא ניתן להעלות את ההעדפות האלה',
			'accountPreferences.noPreference' => 'אין עדיפות',
			'accountPreferences.notSet' => 'לא קבע',
			'accountPreferences.groups.audioAndSubtitles' => 'אודיו & תת-כותרות',
			'accountPreferences.groups.libraryDisplay' => 'ספרייה',
			'accountPreferences.groups.personalMedia' => 'מדיה אישית',
			'accountPreferences.preferredAudioLanguage' => 'שפת קול מועדפת',
			'accountPreferences.autoSelectAudio' => 'בחר אודיו לפי שפה',
			'accountPreferences.autoSelectAudioDescription' => 'מחוץ לשמור כל אודיו מעקב את הקובץ מסמן כברירת מחדל.',
			'accountPreferences.preferredSubtitleLanguage' => 'שפת כתוביות מועדפת',
			'accountPreferences.subtitleMode' => 'הפוך את התחתונים',
			'accountPreferences.subtitleModes.none' => 'בחירה ידנית',
			'accountPreferences.subtitleModes.noneDescription' => 'לעולם אל תחליף את הכותרות בעצמך.',
			'accountPreferences.subtitleModes.defaultMode' => 'עקבו אחרי track flags',
			'accountPreferences.subtitleModes.defaultModeDescription' => 'השתמש בדגלים ברירת המחדל והכפייתיים המאוחסנים על כל מסלול תת-כותרת.',
			'accountPreferences.subtitleModes.always' => 'תמיד אפשרי',
			'accountPreferences.subtitleModes.alwaysDescription' => 'סובב את שורת התחתון בשפה המועדפת בכל פעם שיש.',
			'accountPreferences.subtitleModes.onlyForced' => 'רק תת-כותרות כפייתיות',
			'accountPreferences.subtitleModes.onlyForcedDescription' => 'להעלות רק את המסלולים מסומנים ככפייתיים.',
			'accountPreferences.subtitleModes.smart' => 'תגיות: אודיו זר',
			'accountPreferences.subtitleModes.smartDescription' => 'הפוך את הכותרות רק כאשר האודיו נמצא בשפה אחרת.',
			'accountPreferences.subtitleAccessibility' => 'תגיות SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'מעדיפים תת-תגיות שאינן SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'מעדיפים תוויות SDH',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'רק תת-כותרות SDH',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'רק תת-תגיות שאינן SDH',
			'accountPreferences.forcedSubtitles' => 'כפייתי תחתונים',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'מעדיפים כותרות לא כפייתיות',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'מעדיפים כותרות כפייתיות',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'רק תת-כותרות כפייתיות',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'רק כותרות לא כפייתיות',
			'accountPreferences.displayMissingEpisodes' => 'הצג אירועים חסרים',
			'accountPreferences.displayMissingEpisodesDescription' => 'רשימה של פרקים ששרת יודע על אבל אין קבצים עבור.',
			'accountPreferences.hidePlayedInLatest' => 'הסתיר פריטים שנצפו בחדשות האחרונות',
			'accountPreferences.hidePlayedInLatestDescription' => 'השאירו פריטים שכבר צפיתם מחוץ לשורות האחרונות של השרת.',
			'accountPreferences.displayCollectionsView' => 'הצג את הצג האוסף',
			'accountPreferences.displayCollectionsViewDescription' => 'מציעים את תצוגת הקולקציות של השרת לצד הספרייה שלך.',
			'accountPreferences.rewatchingInNextUp' => 'להמשיך את ההופעות שנצפו מחדש ב- Next Up',
			'accountPreferences.rewatchingInNextUpDescription' => 'ברגע שאתה מסיים את ההצגה, להתחיל מחדש, ו Next Up עוקב אחר ההצגה מחדש במקום להוריד את ההצגה.',
			'accountPreferences.watchedIndicator' => 'אינדיקטורים שנצפו',
			'accountPreferences.watchedIndicatorOptions.none' => 'אף פעם',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => 'סרטים ותוכניות טלוויזיה',
			'accountPreferences.watchedIndicatorOptions.movies' => 'רק סרטים',
			'accountPreferences.watchedIndicatorOptions.shows' => 'רק תוכניות טלוויזיה',
			'accountPreferences.mediaReviewsVisibility' => 'דירוג & ביקורות',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'משתמשים ומבקרים',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'משתמשים בלבד',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'ביקורת בלבד',
			'accountPreferences.mediaReviewsOptions.nobody' => 'הסתתר',
			'discover.title' => 'גילוי',
			'discover.noContentAvailable' => 'אין תוכן זמין',
			'discover.addMediaToLibraries' => 'הוסף כמה מדיה לספריות שלך',
			'discover.continueWatching' => 'המשך צפייה',
			'discover.continueWatchingIn' => ({required Object library}) => 'להמשיך לצפות ב ${library}',
			'discover.nextUp' => 'הבא בתור',
			'discover.nextUpIn' => ({required Object library}) => 'תגיות קשורות ${library}',
			'discover.recentlyAdded' => 'אחרון',
			'discover.recentlyAddedIn' => ({required Object library}) => 'הוספת לאחרונה ב ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => 'האלבומים האחרונים ב- ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'שחק לאחרונה ב ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'הכי משחק ב ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'ע${season} פ${episode}',
			'discover.overview' => 'סקירה כללית',
			'discover.cast' => 'קסט',
			'discover.findNext.title' => 'מצאו את הבחירה הבאה שלכם',
			'discover.findNext.open' => 'מצאו את הבחירה הבאה שלכם',
			'discover.findNext.anyTime' => 'ללא הגבלת זמן',
			'discover.findNext.timeAvailable' => 'כמה זמן יש לכם?',
			'discover.findNext.filters' => 'בחרו מה מתאים לרגע הזה',
			'discover.findNext.watch' => 'צפייה',
			'discover.findNext.listen' => 'האזנה',
			'discover.findNext.read' => 'קריאה',
			'discover.findNext.finishable' => ({required Object duration}) => 'אפשר לסיים בתוך ${duration}',
			'discover.findNext.aboutDuration' => ({required Object duration}) => 'כ־${duration}',
			'discover.findNext.nextUnit' => ({required Object duration}) => 'הפרק הבא · ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => '${duration} בסך הכול',
			'discover.findNext.timingVaries' => 'משך הזמן משתנה',
			'discover.findNext.notNow' => 'לא עכשיו',
			'discover.findNext.swipeHint' => 'החליקו את העטיפה לכיוון אחד החצים או השתמשו בכפתורים למטה.',
			'discover.findNext.saved' => 'המלצות שמורות',
			'discover.findNext.savedCount' => ({required Object count}) => 'המלצות שמורות · ${count}',
			'discover.findNext.undo' => 'ביטול הפעולה האחרונה',
			'discover.findNext.details' => 'פרטים',
			'discover.findNext.noPicks' => 'עדיין אין אפשרויות לבחירה',
			'discover.findNext.noPicksHint' => 'חברו ספרייה או הוסיפו מקור מדיה כדי להתחיל.',
			'discover.findNext.noMatches' => 'אין כרגע משהו שמתאים',
			'discover.findNext.noMatchesHint' => 'נסו סוג מדיה אחר או הקצו לעצמכם יותר זמן.',
			'discover.findNext.allDone' => 'עברתם על כל ההמלצות',
			'discover.findNext.allDoneHint' => 'התחילו מקבץ חדש כדי לראות את האפשרויות האלה שוב.',
			'discover.findNext.refresh' => 'מצאו מקבץ אחר',
			'discover.findNext.sourceReason' => ({required Object source}) => 'מתוך ${source}',
			'discover.findNext.libraryReason' => ({required Object library}) => 'מתוך ${library}',
			'discover.findNext.ownedReason' => 'מהספרייה שלכם',
			'discover.findNext.liveNow' => 'משודר עכשיו',
			'discover.findNext.watchLive' => 'צפייה בשידור חי',
			'discover.findNext.filterAnything' => 'כל סוג',
			'discover.findNext.filterWatch' => 'צפייה',
			'discover.findNext.filterListen' => 'האזנה',
			'discover.findNext.filterRead' => 'קריאה',
			'discover.findNext.twentyMinutes' => '20 דקות',
			'discover.findNext.fortyFiveMinutes' => '45 דקות',
			'discover.findNext.ninetyMinutes' => '90 דקות',
			'discover.findNext.apply' => 'החלה',
			'discover.findNext.openFailed' => 'האפשרות הזו כבר לא זמינה. רעננו כדי לבדוק שוב.',
			'discover.findNext.changeFailed' => 'לא ניתן לשמור את השינוי. נסו שוב.',
			'discover.findNext.savedLimit' => 'רשימת ההמלצות השמורות מלאה. הסירו המלצה כדי לשמור אחרת.',
			'discover.findNext.chooseHint' => 'פתחו כותר, שמרו אותו להמשך או דלגו עליו.',
			'discover.findNext.howItWorks' => 'איך זה עובד',
			'discover.findNext.notNowHelp' => 'דלגו על הכותר הזה כרגע. הוא יישאר בספרייה שלכם.',
			'discover.findNext.saveHelp' => 'שמרו אותו בבחירות השמורות של הפרופיל הזה במכשיר הזה. השמירה אינה מורידה את התוכן.',
			'discover.findNext.openHelp' => 'בחרו בעטיפה להצגת פרטים. השתמשו בפעולה הראשית כדי לנגן, לקרוא או לפתוח את הכותר.',
			'discover.findNext.controlsHelp' => 'מקלדת או שלט: עברו לכפתור ולחצו על Enter או על בחירה. ביטול מחזיר את הבחירה האחרונה.',
			'discover.findNext.artworkLoading' => 'טוען תמונה…',
			'discover.findNext.artworkUnavailable' => 'התמונה אינה זמינה',
			'discover.findNext.savedFeedback' => 'נוסף לבחירות השמורות',
			'discover.findNext.skippedFeedback' => 'דולג לעת עתה',
			'discover.findNext.releaseToConfirm' => 'שחררו לאישור',
			'discover.findNext.remoteHint' => 'כשהעטיפה במיקוד: ← / → בחירה · לחצן בחירה: פרטים · ↑ / ↓ העברת מיקוד',
			'discover.extras' => 'טריילר & Extras',
			'discover.studio' => 'סטודיו',
			'discover.rating' => 'דירוג',
			'discover.director' => 'במאי',
			'discover.directors' => 'במאים',
			'discover.movie' => 'סרט',
			'discover.tvShow' => 'תוכנית טלוויזיה',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} דקות נותרה',
			'discover.moreLikeThis' => 'עוד כמו זה',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} כותרת', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} כותרות', ), 
			'discover.person.born' => 'נולד',
			'discover.person.died' => 'מת',
			'discover.person.birthplace' => 'מקום לידה',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date} (גיל ${age})',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date} (בגיל ${age})',
			'errors.searchFailed' => ({required Object error}) => 'חיפוש לא הצליח: ${error}',
			'errors.searchUnavailable' => 'החיפוש לא יכול להגיע לשירותי התקשורת.',
			'errors.connectionTimeout' => ({required Object context}) => 'זמן חיבור בזמן הטעינה ${context}',
			'errors.connectionFailed' => 'אי אפשר להתחבר לשרת מדיה',
			'errors.unableToLoad' => ({required Object context}) => 'אין אפשרות להעלות ${context}.',
			'errors.noClientAvailable' => 'אין לקוחות זמינים',
			'errors.pleaseEnterToken' => 'אנא הקלד טוקן',
			'errors.invalidToken' => 'טוקיו חסר תועלת',
			'errors.failedToVerifyToken' => ({required Object error}) => 'לא ניתן לבדוק טוקן: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'לא הצלחתי לעבור ל- ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'לא הצלחתי למחוק ${displayName}',
			'errors.failedToRate' => 'לא ניתן לשדרג את הדירוג',
			'errors.reasonTimedOut' => 'הקשר נעלם בזמן',
			'errors.reasonUnreachable' => 'לא ניתן להגיע לשרת',
			'errors.reasonRefused' => 'המשתמש דחה את הבקשה',
			'errors.reasonNotFound' => 'המוצר כבר לא נמצא בשרת.',
			'errors.reasonServerError' => 'השרת מצא שגיאה',
			'errors.reasonCancelled' => 'הבקשה בוטלה',
			'errors.reasonUnexpected' => 'שגיאה בלתי צפויה התרחשה',
			'libraries.playRandomMovie' => 'צפו בסרט אקראי',
			'libraries.randomPickFailed' => 'לא יכולתי לבחור סרט אקראי מהספרייה הזאת.',
			'libraries.title' => 'ספריות',
			'libraries.fallbackTitle' => 'ספרייה',
			'libraries.scanLibraryFiles' => 'סריקת קבצים ספרייה',
			'libraries.scanLibrary' => 'סרוק ספרייה',
			'libraries.analyze' => 'ניתוח',
			'libraries.analyzeLibrary' => 'ניתוח הספרייה',
			'libraries.refreshMetadata' => 'רענון מטא-דאטה',
			'libraries.emptyTrash' => 'ריק טראש',
			'libraries.emptyingTrash' => ({required Object title}) => 'פטריות ריקות עבור "${title}..."',
			'libraries.trashEmptied' => ({required Object title}) => 'תגיות קשורות "${title}"',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'לא הצליח לשפוך את השחיתות ריקה: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'תגית: ${title}',
			'libraries.analysisStarted' => ({required Object title}) => 'ניתוח מתחיל עבור "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'לא הצליח לנתח ספרייה: ${error}',
			'libraries.noLibrariesFound' => 'לא נמצאו ספרייה',
			'libraries.allLibrariesHidden' => 'כל הספרייה מסתתרת',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'ספריות מוסתרים (${count})',
			'libraries.thisLibraryIsEmpty' => 'הספרייה הזאת ריקה',
			'libraries.noItemsMatchFilters' => 'אין פריטים המתאימים לסנרטורים פעילים',
			'libraries.resetFilters' => 'איפוס מסננים',
			'libraries.all' => 'הכול',
			'libraries.clearAll' => 'ברור הכל',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'האם אתה בטוח שאתה רוצה לסרוק "${title}"?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'האם אתה בטוח שאתה רוצה לנתח "${title}"?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'האם אתה בטוח שאתה רוצה לשדרג את הנתונים המטאוגרפיים עבור "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'האם אתה בטוח שאתה רוצה לשחרר את השטויות עבור "${title}"?',
			'libraries.manageLibraries' => 'ניהול ספרייה',
			'libraries.sort' => 'מיון',
			'libraries.sortBy' => 'מיין לפי',
			'libraries.filters' => 'מסננים',
			'libraries.confirmActionMessage' => 'האם אתה בטוח שאתה רוצה לבצע את הפעולה הזאת?',
			'libraries.showLibrary' => 'מציג ספרייה',
			'libraries.hideLibrary' => 'להסתיר את הספרייה',
			'libraries.libraryOptions' => 'אפשרויות ספרייה',
			'libraries.content' => 'ספרייה תוכן',
			'libraries.selectLibrary' => 'בחר ספרייה',
			'libraries.filtersWithCount' => ({required Object count}) => 'מסננים (${count})',
			'libraries.noRecommendations' => 'אין המלצות זמינות',
			'libraries.noCollections' => 'אין אוסף בספריה זו',
			'libraries.noFoldersFound' => 'לא נמצאו קבצים',
			'libraries.folders' => 'תיקיות',
			'libraries.tabs.recommended' => 'מומלץ',
			'libraries.tabs.browse' => 'עיין',
			'libraries.tabs.collections' => 'אוספים',
			'libraries.tabs.playlists' => 'רשימות נגינה',
			'libraries.groupings.title' => 'קבוצות',
			'libraries.groupings.all' => 'הכול',
			'libraries.groupings.movies' => 'סרטים',
			'libraries.groupings.shows' => 'סדרות טלוויזיה',
			'libraries.groupings.seasons' => 'עונות',
			'libraries.groupings.episodes' => 'פרקים',
			'libraries.groupings.artists' => 'אומנים',
			'libraries.groupings.albums' => 'אלבומים',
			'libraries.groupings.tracks' => 'רצועות',
			'libraries.groupings.folders' => 'תיקיות',
			'libraries.filterCategories.genre' => 'ז\'אנר',
			'libraries.filterCategories.year' => 'שנה',
			'libraries.filterCategories.contentRating' => 'תוכן דירוג',
			'libraries.filterCategories.tag' => 'תגית',
			'libraries.filterCategories.unwatched' => 'לא צופה',
			'libraries.filterCategories.unplayed' => 'לא נוגן',
			'libraries.filterCategories.favorites' => 'מועדפים',
			'libraries.filterCategories.filePath' => 'מסלול קובץ',
			'libraries.sortLabels.title' => 'כותרת',
			'libraries.sortLabels.dateAdded' => 'תאריך הוספה',
			'libraries.sortLabels.releaseDate' => 'תאריך הוצאה',
			'libraries.sortLabels.rating' => 'דירוג',
			'libraries.sortLabels.communityRating' => 'דירוג קהילה',
			'libraries.sortLabels.criticRating' => 'ביקורת קריטית',
			'libraries.sortLabels.userRating' => 'שיעור המשתמש',
			'libraries.sortLabels.datePlayed' => 'תאריך ניגון',
			'libraries.sortLabels.playCount' => 'כמות ניגונים',
			'libraries.sortLabels.productionYear' => 'שנת הייצור',
			'libraries.sortLabels.runtime' => 'זמן ריצה',
			'libraries.sortLabels.officialRating' => 'דירוג רשמי',
			'libraries.sortLabels.premiereDate' => 'תאריך בכורה',
			'libraries.sortLabels.startDate' => 'תאריך התחלה',
			'libraries.sortLabels.airTime' => 'זמן אוויר',
			'libraries.sortLabels.studio' => 'סטודיו',
			'libraries.sortLabels.random' => 'אקראי',
			'libraries.sortLabels.dateShared' => 'תאריך משותף',
			'libraries.sortLabels.latestEpisodeAirDate' => 'פרק אחרון תאריך אוויר',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'פרק אחרון תאריך הוספת',
			'libraries.sortLabels.dateDownloaded' => 'תאריך הורדה',
			'libraries.sortLabels.size' => 'גודל',
			'libraries.sortLabels.library' => 'ספרייה',
			'libraries.advancedFilters.include' => 'כולל',
			'libraries.advancedFilters.exclude' => 'ביטול',
			'libraries.advancedFilters.any' => 'כל אחד',
			'libraries.advancedFilters.yes' => 'כן',
			'libraries.advancedFilters.no' => 'לא',
			'libraries.advancedFilters.not' => ({required Object value}) => 'לא ${value}',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '${count} נבחר',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '${count} נמנע',
			'libraries.advancedFilters.searchValues' => 'חיפוש ערכים',
			'libraries.advancedFilters.noValues' => 'אין ערכים',
			'libraries.advancedFilters.matchContains' => 'תוכן',
			'libraries.advancedFilters.matchNotContains' => 'לא מכיל',
			'libraries.advancedFilters.matchIs' => 'הוא',
			'libraries.advancedFilters.matchIsNot' => 'האם לא',
			'libraries.advancedFilters.matchBeginsWith' => 'מתחילים עם',
			'libraries.advancedFilters.matchEndsWith' => 'הסתיימה עם',
			'libraries.advancedFilters.textHint' => 'סוג למתחרים',
			'libraries.advancedFilters.from' => 'מתוך',
			'libraries.advancedFilters.to' => 'ל',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from} עד ${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value} ומעלה',
			'libraries.advancedFilters.atMost' => ({required Object value}) => 'עד ${value}',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => '${count} ימים אחרונים',
			'libraries.advancedFilters.dateLastYear' => 'בשנה האחרונה',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => 'מבוגר יותר מ ${count} ימים',
			'libraries.advancedFilters.dateOlderThanYear' => 'מבוגר יותר משנה אחת',
			'libraries.selection.selectItems' => 'בחירת פריטים',
			'libraries.selection.selectedCount' => ({required Object count}) => '${count} נבחר',
			'libraries.selection.actions' => 'פעולות בחירה',
			'libraries.selection.confirmDescendants' => 'זה משנה את כל הפרקים בתערוכות ובעונות שנבחרו.',
			'libraries.selection.confirmUnwatched' => 'הפעולה גם מאפסת את התקדמות הניגון של הפריטים שנבחרו.',
			'libraries.selection.confirmCount' => ({required Object count}) => 'סכום הנבחרים: ${count}',
			'libraries.selection.completed' => ({required Object count}) => 'פריטים מעודכנים: ${count}.',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => 'עדכון ${succeeded}; נכשל ${failed}. פריטים נכשלו נשארים נבחרים.',
			'about.title' => 'אודות',
			'about.openSourceLicenses' => 'רישיונות קוד פתוח',
			'about.versionLabel' => ({required Object version}) => 'גרסה ${version}',
			'about.appDescription' => 'לקוח יפה Plex, Jellyfin, ו Emby עבור Flutter',
			'about.viewLicensesDescription' => 'ראה רישיונות של ספריות של צד שלישי',
			'about.privacyPolicy' => 'מדיניות פרטיות',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'לא נמצאו שרתים עבור ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'שרתים לא מצליחים להעלות: ${error}',
			'serverSelection.noValidServers' => 'לא נמצאו שרתים שימושיים בחשבון זה',
			'hubDetail.title' => 'כותרת',
			'hubDetail.releaseYear' => 'שנת שחרור',
			'hubDetail.dateAdded' => 'תאריך הוספה',
			'hubDetail.rating' => 'דירוג',
			'hubDetail.noItemsFound' => 'לא נמצאו פריטים',
			'logs.clearLogs' => 'לוג ברור',
			'logs.copyLogs' => 'לוגו לוגו',
			'logs.uploadLogs' => 'להעלות לוג',
			'logs.saveLogs' => 'שמור לוגים ל-File',
			'logs.logsSaved' => ({required Object path}) => 'רשומות שנשמרו ל- ${path}',
			'logs.saveLogsFailed' => 'לא הצלחתי לשמור את קובץ ה-LOG.',
			'detail.endsAt' => ({required Object time}) => 'תגיות קשורות ${time}',
			'startup.failedTitle' => 'PlezyNG לא יכול להתחיל',
			'startup.failedBody' => 'משהו לא בסדר במהלך ההתחלה.הפרטים למטה מזהים מה נכשל.',
			'startup.failedBodyRepairable' => 'קובץ ההגדרות השמור של PlezyNG פגום וצריך ליצור אותו מחדש לפני שהיישום יוכל לפעול. ניסיון נוסף לא יעזור — יש לבחור בתיקון האחסון.',
			'startup.phaseLabel' => 'צעד',
			'startup.showDetails' => 'הצג פרטים',
			'startup.hideDetails' => 'להסתיר פרטים',
			'startup.copyDetails' => 'עותק פרטים',
			'startup.detailsCopied' => 'פרטים מפורטים ב-Clipboard',
			'startup.uploadDetails' => 'להעלות פרטים',
			'startup.repairStorage' => 'תיקון אחסון',
			'startup.repairTitle' => 'לתקן את הנתונים שנשמרו?',
			'startup.repairBodyCommon' => 'קובץ ההגדרות של PlezyNG פגום ולא ניתן לקרוא אותו. התיקון מאפס את כל ההגדרות לברירות המחדל.',
			'startup.repairBodyOneCredential' => 'אחד מפרטי ההתחברות השמורים פגום ולא ניתן לקרוא אותו. התיקון מסיר רק אותו; שאר ההגדרות נשארות ללא שינוי.',
			'startup.repairBodySignInsKept' => 'ההתחברות לשרתים ולפרופילים אמורה להישמר.',
			'startup.repairBodySignInsLost' => 'לא ניתן לשחזר מהקובץ הזה את המפתח שמגן על פרטי ההתחברות השמורים, ולכן יהיה צורך להתחבר שוב לכל שרת ופרופיל. דבר בשרת המדיה לא יושפע.',
			'startup.repairBodySessionsUncertain' => 'הנתונים של שירותי המעקב (MAL, AniList, Simkl, Trakt) ושל Seerr נשמרים בנפרד, וייתכן שיישמרו וייתכן שלא. PlezyNG יציג בדיוק מה נשמר.',
			'startup.repairConfirm' => 'תיקון',
			'startup.repairSucceeded' => 'אחסון מתוקן',
			'startup.repairNeedsRestart' => 'תיקון אחסון – מחדש נדרש',
			'startup.restartRequiredBody' => 'הנתונים שלך תוקנו, אך צריך להפעיל מחדש את PlezyNG כדי להשתמש בהם. יש לסגור את PlezyNG ולפתוח אותו שוב.',
			'startup.quitPlezy' => 'סה"כ PlezyNG',
			'startup.repairFailed' => 'תיקון נכשל',
			'startup.repairKeptSignIns' => 'ההתחברות לשרתים ולפרופילים עדיין פעילה.',
			'startup.repairLostSignIns' => 'לא ניתן לשחזר את המפתח שמגן על פרטי ההתחברות השמורים. יהיה צורך להתחבר שוב לכל שרת ופרופיל.',
			'startup.repairLostSessions' => 'לפחות אחד מעקב או חיבור Seerr אבד וצריך להתחבר מחדש.',
			'startup.backupTitle' => 'עותק של הקובץ הנגוע נשמר',
			'startup.backupWarning' => 'העותק מכיל את פרטי ההתחברות שלך. אין להעלות או לשתף אותו.',
			'startup.deleteBackup' => 'הורד עותק',
			'startup.backupDeleted' => 'עותק מוחלף',
			'startup.previousFailureTitle' => 'PlezyNG לא התחיל בפעם האחרונה',
			'licenses.relatedPackages' => 'חבילות קשורות',
			'licenses.license' => 'רישיון',
			'licenses.licenseNumber' => ({required Object number}) => 'רישיון ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} רישיונות',
			'navigation.libraries' => 'ספריות',
			'navigation.downloads' => 'הורדות',
			'navigation.liveTv' => 'טלוויזיה בשידור חי',
			'navigation.explore' => 'לחקור',
			'explore.mdblistShelves.manage' => 'ניהול חקירה מדרגות',
			'explore.mdblistShelves.manageDescription' => 'בחר וארגן רשימות מהחשבון שלך MDBList',
			'explore.mdblistShelves.description' => 'בחירת רשימות ציבוריות של סרטים וסדרות מחשבון MDBList שלך. יש ליצור או להעתיק רשימות ב-MDBList ואז לרענן.',
			'explore.mdblistShelves.selected' => 'מדרגות שנבחרו',
			'explore.mdblistShelves.available' => 'רשימות חשבונות זמינות',
			'explore.mdblistShelves.noLists' => 'לא הוחזרו רשימות סרטים או טלוויזיה ציבוריות. יצירת או העתק רשימה ב- MDBList, ולאחר מכן לחדש.',
			'explore.mdblistShelves.displayName' => 'שמו של Shelf Display',
			'explore.mdblistShelves.nameHint' => 'השאירו את השם ללימודי המקור.',
			'explore.mdblistShelves.add' => 'להוסיף Shelf',
			'explore.mdblistShelves.save' => 'הציל את המדרגות',
			_ => null,
		} ?? switch (path) {
			'explore.mdblistShelves.moveUp' => ({required Object title}) => 'זורק ${title} למעלה',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => 'מוריד ${title} למטה',
			'explore.mdblistShelves.unavailable' => 'רשימה זו אינה זמינה.חזיר או להסיר את המאגר שלה בהגדרות.',
			'explore.mdblistShelves.rateLimited' => 'MDBList הגבלת בקשה הושגה בבקשה להחזיר מאוחר יותר.',
			'explore.mdblistShelves.loadFailed' => 'לא ניתן להעלות את השטיח.בדוק את החיבור שלך ואת החזרה.',
			'explore.mdblistShelves.saveFailed' => 'אני לא יכול לחסוך את הכרטיסים, בבקשה תתפטר.',
			'explore.mdblistShelves.accountChanged' => 'החשבון או הפרופיל השתנו; פתח מחדש את ההגדרות האלה.',
			'explore.mdblistShelves.settingsUnreadable' => 'לא ניתן לקרוא שדות שנשמרו.בחרו את הרשימות שלכם שוב כדי להחליף את ההגדרות האלה.',
			'explore.title' => 'לחקור',
			'explore.selectSource' => 'בחר מקור',
			'explore.rows.watchlist' => 'שומרים',
			'explore.rows.recommendedMovies' => 'סרטים מומלצים',
			'explore.rows.recommendedShows' => 'הצגות מומלצות',
			'explore.rows.trendingMovies' => 'סרטים טרנדים',
			'explore.rows.trendingShows' => 'תצוגות טרנד',
			'explore.rows.popularMovies' => 'סרטים פופולריים',
			'explore.rows.popularShows' => 'הופעות פופולריות',
			'explore.rows.trendingAnime' => 'אנמיה טרנד',
			'explore.rows.suggestedAnime' => 'אנמיה מומלצת',
			'explore.rows.airingAnime' => 'האנימציה העליונה',
			'explore.rows.popularAnime' => 'האנימציה הפופולרית ביותר',
			'explore.rows.trending' => 'טרנד',
			'explore.rows.upcomingMovies' => 'הסרטים הקרובים',
			'explore.rows.upcomingShows' => 'הופעות הקרובות',
			'explore.status.airing' => 'אוויר',
			'explore.status.ended' => 'הסתיים',
			'explore.status.canceled' => 'ביטול',
			'explore.status.upcoming' => 'בקרוב',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} פרק', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} פרקים', ), 
			'explore.cast' => 'קסט',
			'explore.characters' => 'דמויות',
			'explore.addToWatchlist' => 'הוסף ל Watchlist',
			'explore.removeFromWatchlist' => 'להסיר מ- Watchlist',
			'explore.addedToWatchlist' => 'הוספת ל watchlist',
			'explore.removedFromWatchlist' => 'הוסרה מ- watchlist',
			'explore.watchlistUpdateFailed' => 'לא ניתן לשדרג את רשימת השמועות',
			'explore.watchlistNoMatch' => 'לא יכולתי להתאים את הפריט הזה לרשימת שומרים',
			'explore.notInLibrary' => 'לא בספריה שלך',
			'explore.inTheseLibraries' => 'בספריות אלה',
			'explore.checkingLibrary' => 'בדוק את הספרייה שלך',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n, one: 'לא ניתן לבדוק את השרת ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}', other: 'לא ניתן לבדוק את השרתים ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}', ), 
			'explore.emptyTitle' => 'שום דבר כאן עדיין',
			'explore.emptyMessage' => ({required Object source}) => 'שורות מ- ${source} יופיעו כאן ברגע שיש להם תוכן.',
			'explore.searchHint' => ({required Object source}) => 'חיפוש ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'אין תוצאות עבור "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'לחפש סרטים ותצוגות ב- ${source}.',
			'explore.searchFailed' => 'החיפוש נכשל, בדוק את החיבור שלך ונסו שוב.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} פופולרי',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} אוויר',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} דירוג',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} טרנדים',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} ב ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} צפייה',
			'explore.badge.available' => 'זמין',
			'explore.badge.partiallyAvailable' => 'חלקית זמינה',
			'explore.badge.availableIn4k' => '4K זמין',
			'explore.badge.requested' => 'ביקוש',
			'explore.badge.pendingApproval' => 'עד אישור',
			'explore.badge.processing' => 'עיבוד',
			'explore.badge.declined' => 'דלקת',
			'explore.badge.requestFailed' => 'בקשה נכשלה',
			'explore.badge.requested4k' => '4K מבקשת',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} עונות',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => 'Ep ${episode} ב ${duration}',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'תגית: ${duration}',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} EPS',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} דקות / דקה',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} רשימה',
			'explore.stats.viewersDay' => ({required Object n}) => '${n} צפיות היום',
			'explore.stats.viewersWeek' => ({required Object n}) => 'השבוע צפו: ${n}',
			'explore.stats.viewersMonth' => ({required Object n}) => 'החודש צפו: ${n}',
			'explore.stats.viewersYear' => ({required Object n}) => 'השנה צפו: ${n}',
			'explore.stats.viewersAllTime' => ({required Object n}) => '${n} צופים',
			'explore.stats.planning' => ({required Object n}) => '${n} תכנון לצפות',
			'explore.stats.favorited' => ({required Object n}) => '${n} אהובים',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} הורידו את זה',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} תגובות', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} תגובות', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} הצבעה',
			'explore.stats.watching' => ({required Object n}) => '${n} צפו בו',
			'explore.stats.completed' => ({required Object n}) => '${n} הושלמה',
			'explore.stats.onHold' => ({required Object n}) => '${n} על שמירה',
			'explore.stats.dropped' => ({required Object n}) => '${n} נעלם',
			'explore.season.winter' => 'חורף',
			'explore.season.spring' => 'האביב',
			'explore.season.summer' => 'קיץ',
			'explore.season.fall' => 'נופל',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'טלוויזיה',
			'explore.format.tvShort' => 'טלוויזיה קצרה',
			'explore.format.movie' => 'סרט',
			'explore.format.special' => 'מיוחד',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => 'מוסיקה',
			'explore.format.other' => 'אחר',
			'explore.sourceMaterial.original' => 'מקורי',
			'explore.sourceMaterial.manga' => 'מנגו',
			'explore.sourceMaterial.lightNovel' => 'רומן אור',
			'explore.sourceMaterial.novel' => 'רומן',
			'explore.sourceMaterial.visualNovel' => 'רומן חזותי',
			'explore.sourceMaterial.game' => 'משחק',
			'explore.sourceMaterial.webComic' => 'WEB קומדיה',
			'explore.sourceMaterial.musicRelease' => 'מוסיקה',
			'explore.sourceMaterial.otherMedia' => 'אחר',
			'explore.creditRole.actor' => 'שחקן',
			'explore.creditRole.director' => 'במאי',
			'explore.creditRole.writer' => 'כותב',
			'explore.creditRole.producer' => 'במאי',
			'explore.creditRole.creator' => 'יוצר',
			'explore.creditRole.composer' => 'מלחין',
			'explore.relation.prequel' => 'יצירה מקדימה',
			'explore.relation.sequel' => 'עקבו אחרי',
			'explore.relation.sideStory' => 'סיפור צד',
			'explore.relation.spinOff' => 'ספין-off',
			'explore.relation.alternativeVersion' => 'גרסה אלטרנטיבית',
			'explore.relation.summary' => 'סיכום',
			'explore.relation.parentStory' => 'סיפור ההורים',
			'explore.relation.adaptation' => 'התאמה',
			'explore.relation.other' => 'הקשורים',
			'explore.broadcast' => ({required Object day, required Object time}) => 'איירס ${day} ב- ${time}',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => 'איירס ${day} ב- ${time} ${timezone}',
			'explore.detail.originalTitle' => 'כותרת מקורית',
			'explore.detail.alsoKnownAs' => 'ידוע גם כ',
			'explore.detail.studios' => 'אולפני',
			'explore.detail.country' => 'ארץ',
			'explore.detail.language' => 'שפה',
			'explore.detail.released' => 'שחרור',
			'explore.detail.physicalRelease' => 'על דיסק',
			'explore.detail.ended' => 'הסתיים',
			'explore.detail.addedOn' => ({required Object date}) => 'הוספת ${date}',
			'explore.detail.yourRating' => 'הדירוג שלך',
			'explore.detail.budget' => 'תקציב',
			'explore.detail.revenue' => 'משרד הבוקס',
			'explore.detail.contentAdvisory' => 'עידן הדרכה',
			'explore.detail.tags' => 'מילות מפתח',
			'explore.detail.revealSpoilerTags' => 'תגיות spoiler tags',
			'explore.detail.links' => 'שמאל',
			'explore.detail.watchOn' => 'צפו ב',
			'explore.detail.watchTrailer' => 'צפו בטריילר',
			'explore.detail.openOn' => ({required Object site}) => 'פתוח ב ${site}',
			'explore.detail.crew' => 'צוות',
			'explore.detail.ratings' => 'דירוג',
			'explore.detail.schedule' => 'לו״ז',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n, one: 'מומלץ על ידי ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} משתמשים', other: 'הומלץ על ידי ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} משתמשים', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'הוצג על ידי ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'אהוב על ידי ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} עדיין לא פורסם',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'מומלץ על ידי ${percent} צופים',
			'explore.detail.relatedTitles' => 'כותרות קשורות',
			'explore.detail.background' => 'רקע',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} תוצאות', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} תוצאות', ), 
			'liveTv.title' => 'טלוויזיה בשידור חי',
			'liveTv.guide' => 'מדריך',
			'liveTv.noChannels' => 'אין ערוצים זמינים',
			'liveTv.noDvr' => 'אין DVR מוגדר על כל שרת',
			'liveTv.serverUnavailable' => 'שרת טלוויזיה חי אינו זמין.',
			'liveTv.serverNotConnected' => 'שרת הטלוויזיה החי אינו מחובר.',
			'liveTv.noPrograms' => 'אין נתוני תוכנית זמינים',
			'liveTv.liveStreamFailed' => 'Live Stream נכשל',
			'liveTv.unknownProgram' => 'תוכנית לא ידועה',
			'liveTv.timelineLiveProgram' => 'תוכנית חיה (תוכנית משחק עשויה להיות מחוץ לתוכנית זו)',
			'liveTv.timelineBuffer' => 'לוח זמנים של בופר',
			'liveTv.timelineUnavailable' => 'לוח זמנים לא זמין',
			'liveTv.timelineEstimated' => 'משחק חיובי',
			'liveTv.timelinePending' => 'מחפשים',
			'liveTv.timelineStale' => 'לוח הזמנים עשוי להיות מוגזם',
			'liveTv.unknownHub' => 'לא ידוע',
			'liveTv.unknownError' => 'שגיאה לא ידועה',
			'liveTv.channelNumber' => ({required Object number}) => 'ערוץ ${number}',
			'liveTv.unknownChannel' => 'ערוץ לא ידוע',
			'liveTv.live' => 'שידור חי',
			'liveTv.premiereBadge' => 'חדש',
			'liveTv.reloadGuide' => 'מחדש מדריך',
			'liveTv.searchGuide' => 'מדריך חיפוש',
			'liveTv.searchHint' => 'ערוצי חיפוש ותוכניות',
			'liveTv.searchNoResults' => ({required Object query}) => 'אין משחקים עבור "${query}"',
			'liveTv.channelsSection' => 'ערוצים',
			'liveTv.programsSection' => 'תוכניות',
			'liveTv.now' => 'עכשיו',
			'liveTv.today' => 'היום',
			'liveTv.tomorrow' => 'מחר',
			'liveTv.midnight' => 'חצות',
			'liveTv.overnight' => 'לילה',
			'liveTv.morning' => 'בוקר',
			'liveTv.daytime' => 'יום',
			'liveTv.evening' => 'לילה',
			'liveTv.lateNight' => 'לילה מאוחר',
			'liveTv.whatsOn' => 'מה זה על',
			'liveTv.watchChannel' => 'צפו בערוץ',
			'liveTv.favorites' => 'מועדפים',
			'liveTv.reorderFavorites' => 'תגית: Favorites',
			'liveTv.noFavoriteChannels' => 'אין ערוצים מועדפים',
			'liveTv.noFavoriteChannelsHint' => 'הצג את כל הערוצים, ולאחר מכן לחץ על ערוץ כדי להוסיף אותו לאהובים שלך.',
			'liveTv.showAllChannels' => 'הצג את כל הערוצים',
			'liveTv.favoritesLoadFailed' => 'לא יכול להעלות את האהובים.בדוק את החיבור שלך ולנסות שוב.',
			'liveTv.favoritesUpdateFailed' => 'לא ניתן לעדכן את האהובים.בדוק את החיבור שלך ולנסות שוב.',
			'liveTv.joinSession' => 'הצטרפו לפגישה בתקדמות',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'לצפות מההתחלה (לפני ${minutes} דקות)',
			'liveTv.watchLive' => 'צפו בחיים',
			'liveTv.goToLive' => 'ללכת לחיות',
			'liveTv.record' => 'הקלטה',
			'liveTv.recordEpisode' => 'פרק רשום',
			'liveTv.recordSeries' => 'הקלט סדרה',
			'liveTv.recordOptions' => 'אפשרויות רישום',
			'liveTv.saveTo' => 'להציל את',
			'liveTv.recordings' => 'הקלטות',
			'liveTv.scheduledRecordings' => 'לוח זמנים',
			'liveTv.recordingRules' => 'חוקי ההקלטה',
			'liveTv.noScheduledRecordings' => 'שום דבר לא מתוכנן להקליט',
			'liveTv.manageRecording' => 'ניהול הקלטות',
			'liveTv.cancelRecording' => 'ביטול הקלטה',
			'liveTv.cancelRecordingTitle' => 'לבטל את ההקלטה הזו?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} כבר לא יירשם.',
			'liveTv.deleteRule' => 'הורדת חוק',
			'liveTv.deleteRuleTitle' => 'הורד את חוק ההקלטה?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'הפרקים העתידיים של ${title} לא יירשמו.',
			'liveTv.recordingScheduled' => 'ההקלטה מתוזמנת.',
			'liveTv.alreadyScheduled' => 'תוכנית זו כבר מתוכננת.',
			'liveTv.dvrAdminRequired' => 'הגדרות DVR דורשות חשבון מנהל',
			'liveTv.recordingFailed' => 'לא יכולתי לתכנן את ההקלטה',
			'liveTv.recordingTargetMissing' => 'לא יכולתי לקבוע את הקלטת הספרייה',
			'liveTv.recordNotAvailable' => 'הקלטות שאינן זמינות לתוכנית זו',
			'liveTv.recordingCancelled' => 'ההקלטה בוטלה',
			'liveTv.recordingRuleDeleted' => 'חוק ההקלטה מוחק',
			'liveTv.processRecordingRules' => 'הערכה מחדש של הכללים',
			'liveTv.recordingInProgress' => 'להקליט עכשיו',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} מתוכנן',
			'liveTv.editRule' => 'Edit כללים',
			'liveTv.editRuleAction' => 'ערוך',
			'liveTv.recordingRuleUpdated' => 'חוק ההקלטה מתעדכן',
			'liveTv.guideReloadRequested' => 'מדריך חידוש נדרש',
			'liveTv.guideReloadFailed' => 'לא יכולתי לחדש את המדריך',
			'liveTv.rulesProcessRequested' => 'בקשה להערכה מחדש',
			'liveTv.rulesProcessFailed' => 'לא ניתן להעריך מחדש את חוקי ההקלטה',
			'liveTv.recordShow' => 'הצגת רשומות',
			'liveTv.recordSettings.startEarly' => 'מתחילים מוקדם (שניות)',
			'liveTv.recordSettings.endLate' => 'סוף סוף מאוחר (שניות)',
			'liveTv.recordSettings.newOnly' => 'רק פרקים חדשים',
			'liveTv.recordSettings.anyChannel' => 'רשום בכל ערוץ',
			'liveTv.recordSettings.anyTime' => 'רשומה בכל עת',
			'liveTv.recordSettings.skipInLibrary' => 'קפיצה של פרקים כבר בספריה',
			'liveTv.recordSettings.keepUpTo' => 'אירועים שצריך לשמור',
			'liveTv.recordSettings.keepUpToHint' => '0 שומרים על כל פרק',
			'liveTv.startingInMinutes' => ({required Object minutes}) => 'מתחיל ב ${minutes} דקות',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} ב ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product} החזיר נתונים לא חוקיים Live TV playback',
			'liveTv.failedToStartChannel' => 'לא יכולתי להתחיל את ערוץ החי',
			'liveTv.failedToBuildStreamUrl' => 'לא יכולתי לבנות את ה-URL הזרם',
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'לא יכולתי להתחיל את הערוץ: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'לא יכול לשנות את הערוץ: ${reason}',
			'collections.title' => 'אוספים',
			'collections.collection' => 'אוספים',
			'collections.empty' => 'הקולקציה ריקה',
			'collections.deleteCollection' => 'מחיקת אוסף',
			'collections.deleteConfirm' => ({required Object title}) => 'למחוק את "${title}"? לא ניתן לבטל את הפעולה לאחר מכן.',
			'collections.deleted' => 'אוסף מוחק',
			'collections.deleteFailed' => 'לא הצלחתי למחוק את האוסף',
			'collections.deleteFailedWithError' => ({required Object error}) => 'לא הצליח למחוק את האוסף: ${error}',
			'collections.selectCollection' => 'בחר אוסף',
			'collections.collectionName' => 'שם האוסף',
			'collections.enterCollectionName' => 'כניסת שם האוסף',
			'collections.addedToCollection' => 'הוספת לקהילה',
			'collections.errorAddingToCollection' => 'לא הצלחתי להוסיף לאוסף',
			'collections.created' => 'אוסף שנוצר',
			'collections.removeFromCollection' => 'הסר מאוספים',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => 'להסיר את „${title}” מהאוסף הזה?',
			'collections.removedFromCollection' => 'הוסר מהאוסף',
			'collections.removeFromCollectionFailed' => 'לא הצליחו להסיר מהאוסף',
			'collections.removeFromCollectionError' => ({required Object error}) => 'שגיאה להסרת מתוך הקולקציה: ${error}',
			'collections.searchCollections' => 'חיפוש אוסף...',
			'playlists.title' => 'רשימות נגינה',
			'playlists.playlist' => 'רשימת ניגון',
			'playlists.noPlaylists' => 'לא נמצאו רשימות משחקים',
			'playlists.create' => 'יצירת Playlist',
			'playlists.playlistName' => 'שם המשחק',
			'playlists.enterPlaylistName' => 'כניסת שם playlist',
			'playlists.delete' => 'מחיקת רשימת השמעה',
			'playlists.removeItem' => 'הסר מרשימת הניגון',
			'playlists.smartPlaylist' => 'חכמה Playlist',
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} פריט', two: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} פריטים', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} פריטים', ), 
			'playlists.emptyPlaylist' => 'רשימת המשחקים הזאת ריקה',
			'playlists.deleteConfirm' => 'לשחרר את Playlist?',
			'playlists.deleteMessage' => ({required Object name}) => 'האם אתה בטוח שאתה רוצה למחוק את "${name}"?',
			'playlists.created' => 'Playlist שנוצר',
			'playlists.deleted' => 'Playlist מוחלף',
			'playlists.itemAdded' => 'הוספת ל playlist',
			'playlists.itemRemoved' => 'הוסרו מהפלאי',
			'playlists.selectPlaylist' => 'בחר Playlist',
			'playlists.searchPlaylists' => 'מחפשים רשימת משחקים',
			'playlists.errorCreating' => 'לא הצלחתי ליצור רשימת משחקים',
			'playlists.errorDeleting' => 'לא הצלחתי למחוק את רשימת המשחקים',
			'playlists.errorLoading' => 'לא הצלחתי להעלות את רשימת המשחקים',
			'playlists.errorAdding' => 'לא הצלחתי להוסיף ל playlist',
			'playlists.errorReordering' => 'לא הצלחתי להזמין מחדש את פריט playlist',
			'playlists.errorRemoving' => 'לא הצלחתי להסיר אותו מהרשימה',
			'music.goToAlbum' => 'ללכת אל אלבום',
			'music.goToArtist' => 'ללכת לאמן',
			'music.instantMix' => 'מיקס מיידי',
			'music.playNext' => 'נגן את הבא',
			'music.addToQueue' => 'הוסף ל- Queue',
			'music.discNumber' => ({required Object n}) => 'דיסק ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} מסלול', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} רצועות', ), 
			'music.nowPlaying' => 'משחק עכשיו',
			'music.playingFrom' => ({required Object title}) => 'משחקים מתוך ${title}',
			'music.queue' => 'קווי',
			'music.clearQueue' => 'נקה תור',
			'music.lyrics' => 'מילות השיר',
			'music.visualizer' => 'ויזואלי',
			'music.visualizerProfileLoading' => 'קריאת רצועת ניתוח',
			'music.visualizerAmbientMotion' => 'תנועת הסביבה',
			'music.visualizerPlexLoudness' => 'Plex צליל',
			'music.visualizerPreviousPreset' => 'סגנון חזותי קודם',
			'music.visualizerNextPreset' => 'סגנון חזותי הבא',
			'music.visualizerPresetAurora' => 'אווררה',
			'music.visualizerPresetBloom' => 'בלום',
			'music.visualizerPresetOrbitals' => 'אורביטים',
			'music.visualizerPresetPrism' => 'מנסרה',
			'music.visualizerPresetTunnel' => 'מנהרה',
			'music.visualizerPresetTrackMap' => 'עקבו אחרי map',
			'music.noLyrics' => 'אין מילים זמינות',
			'music.sleepTimer' => 'שעות שינה',
			'music.sleepTimerEndOfTrack' => 'סוף מסלול',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} דקה', two: 'שתי דקות', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} דקות', ), 
			'music.stopPlayback' => 'הפסק הפעלה',
			'music.previousTrack' => 'הרצועה הקודמת',
			'music.nextTrack' => 'הרצועה הבאה',
			'music.repeat' => 'חזרה',
			'music.repeatAll' => 'חזרה על הכל',
			'music.repeatOne' => 'חזרה פעם אחת',
			'music.instantMixNoServer' => 'אין שרתים זמינים עבור מיזוג מיידי',
			'music.instantMixFailed' => 'לא הצלחתי להעלות את המערב המיידי',
			'music.instantMixEmpty' => 'התערובת החזרה ללא עקבות',
			'music.noAudioUrl' => ({required Object track}) => 'אין כתובת אודיו זמינה עבור ${track}',
			'music.discography.singlesAndEps' => 'סינגלים & EPs',
			'music.discography.live' => 'שידור חי',
			'music.discography.compilations' => 'קומפוזיציה',
			'watchTogether.title' => 'צפייה משותפת',
			'watchTogether.description' => 'צפו בתוכן ב-Sync עם חברים ומשפחה',
			'watchTogether.createRoom' => 'יצירת חדר',
			'watchTogether.creatingRoom' => 'יצירת חדר...',
			'watchTogether.joinRoom' => 'הצטרפו לחדר',
			'watchTogether.joiningRoom' => 'חדר הצטרפות...',
			'watchTogether.connecting' => 'חיבור...',
			'watchTogether.relayPublic' => 'החדרים משתמשים ברדיו הציבורי של מפלגת השעון הפתוח.',
			'watchTogether.relayCustom' => ({required Object url}) => 'החדרים משתמשים ברשת שלך ב- ${url}.',
			'watchTogether.recentRooms' => 'החדרים האחרונים',
			'watchTogether.roomActions' => 'חדר פעולות',
			'watchTogether.renameRoom' => 'שם חדר',
			'watchTogether.removeRoom' => 'הסר',
			'watchTogether.enterRoomCode' => 'הקלד את הקוד של 6 תווים מהארח.',
			'watchTogether.roomCode' => 'קוד חדר',
			'watchTogether.paste' => 'פסטה',
			'watchTogether.noCodeInClipboard' => 'הקליפ לא מכיל קוד חדר',
			'watchTogether.copyCode' => 'עותק קוד',
			'watchTogether.codeCopied' => 'קוד חדר עותק',
			'watchTogether.shareInvite' => 'שיתוף הזמנה',
			'watchTogether.inviteCopied' => 'תנו לו להוסיף את ההודעה, תנו לו להוסיף הודעה.',
			'watchTogether.inviteMessage' => ({required Object code}) => 'הצטרף לחדר השעון שלי ב- PlezyNG: פתח את השעון יחד, בחר לחדר השעון הצטרף והכנס ל- ${code}.',
			'watchTogether.openSessionControls' => 'Open Watch יחד בדיקת ישיבה',
			'watchTogether.reconnecting' => 'חיבור מחדש...',
			'watchTogether.reconnectingDescription' => 'הקשר נעלם, אתה נכנס לחדר באופן אוטומטי.',
			'watchTogether.connected' => 'מחוברים',
			'watchTogether.disconnected' => 'נפרד',
			'watchTogether.youAreHost' => 'אתה האורח',
			'watchTogether.hostedBy' => ({required Object name}) => 'פורסם על ידי ${name}',
			'watchTogether.hostControlsPlayback' => 'עקבו אחרי playback playback',
			'watchTogether.anyoneCanControl' => 'כל אחד יכול לשלוט ב-Playback',
			'watchTogether.roomLocked' => 'חדר סגור',
			'watchTogether.nowPlaying' => 'משחק עכשיו',
			'watchTogether.nothingPlaying' => 'לא משחק',
			'watchTogether.nothingPlayingHost' => 'לשחק משהו מכל ספרייה כדי לשתף אותו עם החדר.',
			'watchTogether.nothingPlayingGuest' => 'כאשר המארח משחק משהו, הוא פותח כאן.',
			'watchTogether.notShareable' => 'וידאו זה אינו מתאים לקטלוג, ולכן רק אנשים עם גישה לאותו שרת יכולים לשחק אותו.',
			'watchTogether.searching' => 'מחפשים את הסרטון הזה בספריות שלכם...',
			'watchTogether.yourCopy' => 'העתק שלך',
			'watchTogether.sharingYourCopy' => 'אתם חולקים את העתק שלכם',
			'watchTogether.playingOtherLength' => ({required Object difference}) => 'לשחק את העתק שלך, ${difference}',
			'watchTogether.mismatchTitle' => 'העתק שלך הוא אורך שונה',
			'watchTogether.mismatchDescription' => ({required Object difference}) => 'העתק הקרוב ביותר שלך הוא ${difference} מהסרטון של החדר.',
			'watchTogether.playAnyway' => 'לשחק בכל מקרה',
			'watchTogether.chooseAnotherCopy' => 'בחר עותק נוסף',
			'watchTogether.dontPlay' => 'אל תשחק',
			'watchTogether.unavailableTitle' => 'אין לך וידאו זה',
			'watchTogether.unavailableDescription' => 'PlezyNG לא מצא את זה בספריות שלך.קח עותק בעצמך או לחפש שוב.',
			'watchTogether.chooseCopy' => 'בחר עותק',
			'watchTogether.searchAgain' => 'מחפשים שוב',
			'watchTogether.noCandidates' => 'אין עותקים שנמצאו בספריות שלך.',
			'watchTogether.choiceFailed' => 'לא יכולתי לשחק את העתק הזה לחדר',
			'watchTogether.lengthLonger' => ({required Object duration}) => '${duration} עוד',
			'watchTogether.lengthShorter' => ({required Object duration}) => '${duration} קצר יותר',
			'watchTogether.lengthSame' => 'אותו אורך',
			'watchTogether.lengthUnknown' => 'אורך לא ידוע',
			'watchTogether.joinCurrentPlayback' => 'הצטרפו ל-Playback',
			'watchTogether.joinCurrentPlaybackDescription' => 'לחזור למה שהארח עוקב אחר',
			'watchTogether.stopMedia' => 'הפסקת וידאו לכולם',
			'watchTogether.syncOffset' => 'סינכרון Offset',
			'watchTogether.syncOffsetDescription' => 'שימו את הווידאו שלכם אם הוא פועל מול או מאחורי החדר.',
			'watchTogether.offsetHint' => ({required Object difference}) => 'העתק שלך הוא ${difference} מהסרטון של החדר.',
			'watchTogether.applyDifference' => ({required Object offset}) => 'שימוש ${offset}',
			'watchTogether.offsetMinusSecond' => '1 ס',
			'watchTogether.offsetMinusTenth' => '100 מ"ס',
			'watchTogether.offsetPlusTenth' => '+ 100 מ"ס',
			'watchTogether.offsetPlusSecond' => '+1 ס',
			'watchTogether.participants' => 'משתתפים',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} משתתפים', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} משתתפים', ), 
			'watchTogether.hostBadge' => 'מארח',
			'watchTogether.nameYou' => ({required Object name}) => '${name} (אתה)',
			'watchTogether.playerIdle' => 'זמן פנוי',
			'watchTogether.playerLoading' => 'טעינה',
			'watchTogether.playerReady' => 'מוכנים',
			'watchTogether.playerBuffering' => 'בוקינג',
			'watchTogether.matchSearching' => 'חיפוש',
			'watchTogether.matchMatched' => 'יש את הווידאו',
			'watchTogether.matchMismatched' => 'אורך שונה',
			'watchTogether.matchUnavailable' => 'אין לך את הווידאו',
			'watchTogether.participantOffset' => ({required Object offset}) => 'סה"כ ${offset}',
			'watchTogether.makeHost' => 'להפוך את המארח',
			'watchTogether.makeHostQuestion' => 'הועברה של המארח?',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} ינהל את ההפעלה וינהל את הפגישה עבור כולם.',
			'watchTogether.transfer' => 'העברה',
			'watchTogether.removeParticipant' => 'להסיר מהחדר',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => 'הורד ${name}?',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} עוזב את החדר.הם יכולים להצטרף שוב עם הקוד אלא אם כן אתה סגור את החדר.',
			'watchTogether.remove' => 'הסר',
			'watchTogether.roomSettings' => 'הגדרות חדרים',
			'watchTogether.letEveryoneControl' => 'תנו לכולם לשלוט ב-Playback',
			'watchTogether.lockRoom' => 'חדר סגור',
			'watchTogether.lockRoomDescription' => 'אף אחד לא יכול להצטרף',
			'watchTogether.leaveRoom' => 'עזוב את החדר',
			'watchTogether.leaveRoomQuestion' => 'עזוב את החדר?',
			'watchTogether.leaveRoomConfirm' => 'אתה יכול להצטרף שוב עם קוד החדר.',
			'watchTogether.leave' => 'שחרור',
			'watchTogether.endRoom' => 'חדר סוף',
			'watchTogether.endRoomQuestion' => 'חדר סוף ?',
			'watchTogether.endRoomConfirm' => 'זה סיים את החדר לכולם.',
			'watchTogether.end' => 'סוף',
			'watchTogether.playBlockedTitle' => 'Playback לא התחיל',
			'watchTogether.playBlockedDescription' => 'מתחילים לשחק כדי להתחיל לצפות בחדר.',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} משחק דחיסה',
			'watchTogether.notices.playbackStarted' => 'Playback מתחיל',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} הפסקה',
			'watchTogether.notices.playbackPaused' => 'Playback הפסקה',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} קפץ ל ${position}',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => 'צעד אחר צעד ${position}',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} קבע את המהירות ל- ${speed}',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => 'מהירות מוגדרת ל- ${speed}',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} התחיל ${title}',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => 'עכשיו לשחק ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} עצר את הסרטון',
			'watchTogether.notices.mediaStopped' => 'וידאו נעצר',
			'watchTogether.notices.waitingFor' => ({required Object name}) => 'מחכה ל- ${name} ...',
			'watchTogether.notices.waitingForSomeone' => 'מחכה שמישהו יתפס...',
			'watchTogether.notices.finished' => 'הסתיימה',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} הוא עכשיו המארח',
			'watchTogether.notices.youAreNowHost' => 'עכשיו אתה המארח',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} הצטרף',
			'watchTogether.notices.left' => ({required Object name}) => '${name} שחרור',
			'watchTogether.notices.controlRefused' => 'רק המארח יכול לשלוט ב-Playback',
			'watchTogether.notices.searchFailed' => 'חלק מהשרתים לא יכלו לחפש את הסרטון של החדר',
			'watchTogether.notices.playBlocked' => 'משחק הדפסה מתחיל',
			'watchTogether.notices.shareFailed' => 'לא יכולתי לשתף את הסרטון הזה עם החדר',
			'watchTogether.notices.downloadNotShared' => 'הורדות אינן משותפות עם החדר בעוד השרת שלהם הוא לא מקוון',
			'watchTogether.notices.openFailed' => 'לא יכולתי לפתוח את הסרטון של החדר',
			'watchTogether.ended.ended' => 'האורח סיים את החדר',
			'watchTogether.ended.kicked' => 'הוסרו מהחדר',
			'watchTogether.ended.expired' => 'החדר נגמר',
			'watchTogether.ended.replaced' => 'הצטרפו לחדר זה על מכשיר אחר',
			'watchTogether.ended.lost' => 'איבד את הקשר לחדר',
			'watchTogether.errors.invalidCode' => 'קודים יש 6 אותיות וסימנים, ללא 0, 1, I, L או O.',
			'watchTogether.errors.roomNotFound' => 'אין שם את הקוד הזה, אולי זה נגמר.',
			'watchTogether.errors.roomFull' => 'החדר הזה מלא.',
			'watchTogether.errors.roomLocked' => 'המארחת סגרה את החדר.',
			'watchTogether.errors.relayFull' => 'עכשיו זה עסוק, אז בואו ננסה שוב.',
			'watchTogether.errors.unreachable' => 'לא יכולתי להגיע לשעון יחד רדיו.',
			'watchTogether.errors.rateLimited' => 'כל כך הרבה ניסיונות, לחכות לרגע ולנסות שוב.',
			'watchTogether.errors.clientBlocked' => 'גרסה זו של PlezyNG לא יכולה להשתמש ברדיו.',
			'watchTogether.errors.forbidden' => 'רק המארח יכול לעשות את זה.',
			'watchTogether.errors.notInRoom' => 'אתה לא בחדר.',
			'watchTogether.errors.alreadyInRoom' => 'אתה כבר בחדר.',
			'watchTogether.errors.resumeFailed' => 'לא יכולתי להיכנס לחדר.',
			'watchTogether.errors.unsupported' => 'הרדיו לא תומך בזה.',
			'watchTogether.errors.generic' => 'משהו לא בסדר, נסה שוב.',
			'watchTogether.untitledEpisode' => ({required Object number}) => 'פרק ${number}',
			'downloads.title' => 'הורדות',
			'downloads.manage' => 'ניהול',
			'downloads.tvShows' => 'סדרות טלוויזיה',
			'downloads.movies' => 'סרטים',
			'downloads.music' => 'מוסיקה',
			'downloads.tracksQueued' => ({required Object count}) => '${count} עקבות שנקבעו להורדה',
			'downloads.noDownloads' => 'עדיין לא הורד',
			'downloads.noDownloadsDescription' => 'התוכן שנרשם יופיע כאן לצפייה לא מקוונת',
			'downloads.downloadNow' => 'הורדה',
			'downloads.deleteDownload' => 'הורד Download',
			'downloads.retryDownload' => 'הורד Retry',
			'downloads.downloadQueued' => 'הורדה נוספה לתור.',
			'downloads.downloadResumed' => 'הורד מחדש',
			'downloads.serverErrorBitrate' => 'שגיאה בשרת: קובץ עשוי לעבור את הגבול של שיעור ביט מרחוק',
			'downloads.storageFull' => 'הורדות נעצרו כדי להגן על אחסון זמין.חופשי קצת שטח או בחר מיקום הורדה אחר, ולאחר מכן להחזיר.',
			'downloads.storageUnavailable' => 'הורדות נעצרו כי לא ניתן לבדוק את אחסון הזמינות.בדוק את מיקום ההורדה, ולאחר מכן לחזור.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} פרקים שנרשמו להורדה',
			'downloads.downloadDeleted' => 'הורדה מוחלפת',
			'downloads.deleteConfirm' => ({required Object title}) => 'האם ניתן למחוק את "${title}" מהמכשיר הזה?',
			'downloads.deleteCollectionDownloads' => 'הורדת הורדות',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => 'למחוק מהמכשיר הזה את כל ההורדות שב„${title}”?',
			'downloads.collectionDownloadsDeleted' => 'הורדות נמחקו',
			'downloads.cancelledDownloadTitle' => 'ביטול הורדה',
			'downloads.cancelledDownloadMessage' => 'הורדה זו בוטלה, מה היית רוצה לעשות?',
			'downloads.allEpisodesAlreadyDownloaded' => 'כל הפרקים כבר הורדו',
			'downloads.resumeDownload' => 'תגית: download',
			'downloads.cancelledDownload' => 'ביטול הורדות',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (סנצ\'ינג ${status})',
			_ => null,
		} ?? switch (path) {
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => 'הורד ${file} - לחצו כדי להשלים',
			'downloads.partialDownloadClickToComplete' => 'הורדה חלקית - לחצו כדי להשלים',
			'downloads.deleting' => 'הסרת...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'הסרת ${title}... (${current} מתוך ${total})',
			'downloads.queuedTooltip' => 'קוויד',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'שוטף ${files}',
			'downloads.downloadingTooltip' => 'להורדה...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'הורדה ${files}',
			'downloads.noDownloadsTree' => 'אין הורדות',
			'downloads.pauseAll' => 'הפסקה הכול',
			'downloads.resumeAll' => 'סיכום הכול',
			'downloads.retryAll' => 'להחזיר את כולם',
			'downloads.retryFailed' => 'הורדות נכשלות',
			'downloads.deleteAll' => 'מחק הכל',
			'downloads.selectVersion' => 'בחר גרסה',
			'downloads.allEpisodes' => 'כל הפרקים',
			'downloads.unwatchedOnly' => 'לא נצפה רק',
			'downloads.nextNUnwatched' => ({required Object count}) => 'הבא ${count} לא נצפה',
			'downloads.customAmount' => 'כמות מותאמת...',
			'downloads.customAmountAny' => 'כל סכום (כל סכום)',
			'downloads.randomEpisodes' => 'אירועים אקראיים',
			'downloads.includeSpecials' => 'כולל מיוחד',
			'downloads.howManyEpisodes' => 'כמה פרקים יש?',
			'downloads.invalidEpisodeCount' => 'הקלד מספר של פרקים.',
			'downloads.keepSynced' => 'להישאר סינכרון',
			'downloads.downloadOnce' => 'הורד פעם אחת',
			'downloads.keepNUnwatched' => ({required Object count}) => 'שמור ${count} לא צופה',
			'downloads.editSyncRule' => 'עקבו אחרי sync sync sync',
			'downloads.removeSyncRule' => 'להסיר סינכרון',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'הפסיק לסנכרן "${title}"?הפרקים שהורדו יישמרו.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => 'הפסקת סינכרון "${title}"?',
			'downloads.deleteSyncRuleDownloads' => 'הורד גם הורדות קשורות',
			'downloads.deleteSyncRuleDownloadsDescription' => 'הורדות המשמשות על ידי כלל סינכרון אחר או פרופיל יישמרו.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'סינכרון שנוצרה — שמירה על ${count} פרקים לא נצפו',
			'downloads.syncRuleUpdated' => 'סינכרון חוק עדכון',
			'downloads.syncRuleRemoved' => 'הוראות סינכרון הוסר',
			'downloads.syncRuleAndDownloadsRemoved' => 'הורדת סינכרון ותקופות הקשורות להסרה',
			'downloads.syncRuleCleanupBusy' => 'חוקי סינכרון מתעדכנים כעת, נסה שוב ברגע.',
			'downloads.syncRuleCleanupUnavailable' => 'מחדש את השרת ולנסות שוב, או להסיר את הכלל בלי למחוק את ההורדות.',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => 'סינכרון ${count} פרקים חדשים עבור ${title}',
			'downloads.syncNow' => 'סינכרון עכשיו',
			'downloads.downloadsUpToDate' => 'הורדות עד כה',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => 'סינכרון מלא · ${queued} queued, ${removed} removed',
			'downloads.activeSyncRules' => 'סינכרון כללים',
			'downloads.reviewOrphanFiles' => 'תגית: הורדות עופות',
			'downloads.orphanReviewTitle' => 'תגית: הורדות עופות',
			'downloads.orphanReviewDescription' => 'קבצי תוויות אלה נמצאים בתיקיות הורדה המנוהלות על-ידי אפליקציית PlezyNG כברירת מחדל ואין להם רשומות הורדה או משימות פעילות.',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count} קבצים · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => 'הסרת קבצים ${count}',
			'downloads.orphanCleanupNone' => 'לא נמצאו קבצי הורדה',
			'downloads.orphanCleanupFailed' => 'PlezyNG לא הצליח לסרוק בבטחה את תיקיית ההורדות המנוהלת.',
			'downloads.orphanCleanupChanged' => 'רשימת ההורדות השתנתה במהלך הביקורת.הבדוק שוב את הקבצים לפני ניקוי.',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => 'הורד ${count} קבצים עתיקים · ${size} שוחרר',
			'downloads.noSyncRules' => 'אין כללים סינכרון',
			'downloads.manageSyncRule' => 'ניהול Sync',
			'downloads.editEpisodeCount' => 'פרק מספר',
			'downloads.editSyncFilter' => 'סינכרון Filter',
			'downloads.syncAllItems' => 'סינכרון כל הפריטים',
			'downloads.syncUnwatchedItems' => 'סינכרון פריטים לא נבדקים',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'שרת: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'זמין',
			'downloads.syncRuleOffline' => 'לא מקוון',
			'downloads.syncRuleSignInRequired' => 'הצהרת הדרישה',
			'downloads.syncRuleAccessDenied' => 'גישה נדחתה',
			'downloads.syncRuleNotAvailableForProfile' => 'לא זמין עבור הפרופיל הנוכחי',
			'downloads.syncRuleUnknownServer' => 'שרת לא ידוע',
			'downloads.syncRuleListCreated' => 'עקרונות סינכרון נוצר',
			'downloads.backgroundWarning.bannerBlocked' => 'הורדות יפסיקו כאשר תצא מהאפליקציה',
			'downloads.backgroundWarning.bannerDegraded' => 'הורדות רקע עשויות להיות מוגבלות',
			'downloads.backgroundWarning.bannerAction' => 'פרטים',
			'downloads.backgroundWarning.sheetTitle' => 'הורדות רקע נעצרו',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'הורדות רקע עשויות להיות מוגבלות',
			'downloads.backgroundWarning.sheetIntro' => 'Android מונע PlezyNG להוריד אמין ברקע.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'המכשיר שלך מגביל כאשר PlezyNG ניתן להוריד ברקע.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'השימוש ברקע של PlezyNG מוגבל.הגדר את השימוש באטריה או ברקע ל"לא מוגבל".',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android הוציא PlezyNG במצב מוגבל.',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'הודעות הורדה מופעלות, כך התקדמות ובקרים עשויים להיות לא זמינים.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'על Android 13 או יותר, הם נדרשים עבור הורדות רקע ארוך.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Data Saver הוא ב, אשר חסום הורדות רקע על נתונים ניידים. הורדות עדיין צריך להתבצע על Wi-Fi.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'ההורדות נעצרו שוב ושוב כאשר PlezyNG פעל ברקע. יש לבדוק את הגדרות הסוללה או השימוש ברקע של PlezyNG.',
			'downloads.backgroundWarning.openSettings' => 'פתיחת הגדרות',
			'downloads.backgroundWarning.stillNotWorking' => 'עזרה ספציפית למכשיר',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'ראה שלבים עבור המכשיר שלך, או לשלוח יומן מתוך Settings › View Logs אם הבעיה ממשיכה.',
			'downloads.backgroundWarning.dialogTitle' => 'הורדות לא יכלו להסתיים',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'הורד בכל מקרה',
			'downloads.backgroundWarning.dialogFixFirst' => 'קבע את זה קודם',
			'downloads.backgroundWarning.statusTile' => 'רקע הורדות',
			'downloads.backgroundWarning.statusOk' => 'מותר לרוץ ברקע',
			'downloads.backgroundWarning.statusBlocked' => 'חסום על ידי הגדרות המערכת',
			'downloads.backgroundWarning.statusDegraded' => 'מוגבלת לפי הגדרות המערכת',
			'downloads.backgroundWarning.statusUnknown' => 'עדיין לא בדקתי',
			'downloads.backgroundWarning.settingsUnavailable' => 'לא ניתן לפתוח הגדרות מערכת במכשיר זה',
			'downloads.backgroundWarning.linkUnavailable' => 'לא יכולתי לפתוח dontkillmyapp.com במכשיר זה',
			'downloads.options' => 'אפשרויות הורדה',
			'downloads.groupings.library' => 'ספרייה',
			'downloads.groupings.collections' => 'אוספים',
			'downloads.unknownLibrary' => 'ספרייה לא ידועה',
			'downloads.unknownShow' => 'מופע לא ידוע',
			'downloads.unknownSeason' => 'עונה לא ידועה',
			'downloads.unknownAlbum' => 'אלבום לא ידוע',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} הושלמה',
			'downloads.storageUsed' => ({required Object size}) => 'אחסון משתמש: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} להורדה', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} הורדות', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} תצוגה', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} תצוגה', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} סרטים', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} סרטים', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} אלבום', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} אלבומים', ), 
			'downloads.errorFileNotFound' => 'קובץ לא נמצא (404)',
			'downloads.errorDownloadNotAllowed' => 'הורדות שאינן מותרות על ידי השרת (403)',
			'downloads.errorDownloadFailed' => 'הורדה נכשלה',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'הורדה נכשלה: ${reason}',
			'downloads.convertingOnServer' => 'הפוך לשרת...',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => 'הפוך לשרת · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => 'הורדה נכשלה (HTTP ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => 'תוצאות חיפוש: ${reason}',
			'downloads.reasonFileNotSaved' => 'לא ניתן לשמור את הקובץ במכשיר זה.',
			'downloads.reasonCannotResume' => 'הורדה חלקית לא יכולה להיחזר',
			'downloads.reasonDeviceStorageFull' => 'מכשיר זה לא נשמר.',
			'downloads.notificationDownloading' => 'להורדה...',
			'downloads.notificationComplete' => 'הורדה מלאה',
			'downloads.notificationPaused' => 'הורד הפסקה',
			'shaders.title' => 'מצללים',
			'shaders.noShaderDescription' => 'אין שיפור וידאו',
			'shaders.nvscalerDescription' => 'NVIDIA תמונה סקלינג עבור וידאו בהיר יותר',
			'shaders.artcnnVariantNeutral' => 'נייטרלי',
			'shaders.artcnnVariantDenoise' => 'דניאל',
			'shaders.artcnnVariantDenoiseSharpen' => 'דנואיס + Sharpen',
			'shaders.qualityFast' => 'מהיר',
			'shaders.qualityHQ' => 'איכות גבוהה',
			'shaders.mode' => 'אופנה',
			'shaders.importShader' => 'ייבוא Shader',
			'shaders.customShaderDescription' => 'תגית: GLSL Shader',
			'shaders.shaderImported' => 'Shader ייבוא',
			'shaders.shaderImportFailed' => 'לא הצלחתי לייבא את ה-Shader',
			'shaders.deleteShader' => 'הורד Shader',
			'shaders.deleteShaderConfirm' => ({required Object name}) => 'הסרת "${name}" ?',
			'companionRemote.title' => 'שלט נלווה',
			'companionRemote.connectedTo' => ({required Object name}) => 'חיבור ל- ${name}',
			'companionRemote.unknownDevice' => 'מכשיר לא ידוע',
			'companionRemote.session.startingServer' => 'התחל את השרת הרחוק',
			'companionRemote.session.hostAddress' => 'כתובת האורחים',
			'companionRemote.session.connected' => 'מחוברים',
			'companionRemote.session.serverRunning' => 'שרת מרחוק פעיל',
			'companionRemote.session.serverStopped' => 'שרת מרחוק נעצר',
			'companionRemote.session.serverRunningDescription' => 'מכשירים ניידים ברשת שלך יכולים להתחבר לאפליקציה זו',
			'companionRemote.session.serverStoppedDescription' => 'הפעל את השרת כדי לאפשר למכשירים ניידים להתחבר',
			'companionRemote.session.usePhoneToControl' => 'השתמש במכשיר הנייד שלך כדי לשלוט באפליקציה זו',
			'companionRemote.session.startServer' => 'התחל את השרת',
			'companionRemote.session.stopServer' => 'הפסקת שרת',
			'companionRemote.session.minimize' => 'מינימום',
			'companionRemote.session.manualAddressHint' => 'כתובת חיבור ידנית:',
			'companionRemote.pairing.discoveryDescription' => 'מכשירים PlezyNG עם אותו חשבון Plex מופיעים כאן',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'חיבור...',
			'companionRemote.pairing.searchingForDevices' => 'מחפשים מכשירים...',
			'companionRemote.pairing.noDevicesFound' => 'אין מכשירים שנמצאו ברשת שלך',
			'companionRemote.pairing.noDevicesHint' => 'פתח PlezyNG על שולחן העבודה ושימוש באותו Wi-Fi',
			'companionRemote.pairing.availableDevices' => 'ציוד זמין',
			'companionRemote.pairing.manualConnection' => 'חיבור ידני',
			'companionRemote.pairing.cryptoInitFailed' => 'לא ניתן להתחיל חיבור מאובטח.התחבר ל- Plex קודם.',
			'companionRemote.pairing.validationHostRequired' => 'אנא הקלד את כתובת המארח',
			'companionRemote.pairing.validationHostFormat' => 'הפורמט חייב להיות IP:port (לדוגמה, 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'שימוש באותו רשת על שני המכשירים.',
			'companionRemote.pairing.sessionNotFound' => 'המכשיר לא נמצא. ודא כי PlezyNG פועל על המארח.',
			'companionRemote.pairing.authFailed' => 'שני המכשירים זקוקים לאותו חשבון Plex.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'לא הצלחתי להתחבר: ${error}',
			'companionRemote.pairing.codeTitle' => 'זוג קוד',
			'companionRemote.pairing.codeDescription' => 'הקלד את הקוד המוצג ב- Companion Remote במכשיר המארח.שני המכשירים חייבים להשתמש בגרסה שתומכת בשילוב בטוח.',
			'companionRemote.pairing.codeInvalid' => 'הקלד את כל 32 אותיות ומספרים מהקוד המארח.',
			'companionRemote.pairing.updateRequired' => 'עדכון שני המכשירים לגרסה שתומכת בשילוב בטוח.',
			'companionRemote.pairing.hostDescription' => 'הקלד את הקוד הזה פעם אחת בכל מרחוק.שמור אותו פרטי: הוא מספק שליטה על הפרופיל הזה.',
			'companionRemote.pairing.resetCode' => 'מחדש קוד זוג',
			'companionRemote.pairing.resetDescription' => 'הפסק את כל הרחובות ויוצר קוד חדש.כל הרחוב יהיה צריך להתחבר שוב.',
			'companionRemote.remote.disconnectConfirm' => 'רוצים להתנתק מהפגישה הרחוקה?',
			'companionRemote.remote.reconnecting' => 'חיבור מחדש...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'ניסיון ${current} מתוך 5',
			'companionRemote.remote.retryNow' => 'החזרה עכשיו',
			'companionRemote.remote.tabRemote' => 'מרחוק',
			'companionRemote.remote.tabPlay' => 'נגן',
			'companionRemote.remote.tabMore' => 'עוד',
			'companionRemote.remote.menu' => 'תפריט',
			'companionRemote.remote.tabNavigation' => 'Tab ניווט',
			'companionRemote.remote.tabDiscover' => 'גילוי',
			'companionRemote.remote.tabLibraries' => 'ספריות',
			'companionRemote.remote.tabSearch' => 'חיפוש',
			'companionRemote.remote.tabDownloads' => 'הורדות',
			'companionRemote.remote.tabSettings' => 'הגדרות',
			'companionRemote.remote.previous' => 'הקודם',
			'companionRemote.remote.playPause' => 'משחק / הפסקה',
			'companionRemote.remote.next' => 'הבא',
			'companionRemote.remote.seekBack' => 'מחפשים בחזרה',
			'companionRemote.remote.stop' => 'עצור',
			'companionRemote.remote.seekForward' => 'חיפוש FWD',
			'companionRemote.remote.volume' => 'מגוון',
			'companionRemote.remote.volumeDown' => 'למטה',
			'companionRemote.remote.volumeUp' => 'למעלה',
			'companionRemote.remote.fullscreen' => 'מסך מלא',
			'companionRemote.remote.subtitles' => 'כתוביות',
			'companionRemote.remote.audio' => 'שמע',
			'companionRemote.remote.searchHint' => 'חיפוש על שולחן העבודה',
			'companionRemote.errors.noNetworkInterface' => 'לא נמצאו ממשקי רשת',
			'companionRemote.errors.authenticationFailed' => 'אימות נכשל',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'לא הצליח להתחיל שרת מרחוק: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'לא הצליח לשלוח את הפקודה מרחוק: ${error}',
			'companionRemote.errors.joinTimedOut' => 'זמן קצר להצטרף לפגישה',
			'companionRemote.errors.failedToConnectAnyAddress' => 'לא הצלחתי להתחבר לכל כתובת',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'חיבור אבוד לאחר ניסיונות ${attempts}',
			'companionRemote.errors.connectionLost' => 'חיבור אבוד',
			'companionRemote.closedBeforeAuth' => 'הקשר סגור לפני האמת',
			'videoSettings.playbackSpeed' => 'מהירות ניגון',
			'videoSettings.normalSpeed' => 'רגיל',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'פעיל (${duration})',
			'videoSettings.zoom' => 'זום',
			'videoSettings.sleepTimer' => 'שעות שינה',
			'videoSettings.audioSync' => 'אודיו Sync',
			'videoSettings.subtitleSync' => 'תגית: Sync',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'HDR אינו זמין כאן – מחבר שולחן העבודה או יצוא וידאו זה לא יכול לשאת אותו.',
			'videoSettings.hdrToneMapping' => 'HDR טון מפה',
			'videoSettings.hdrToneMappingCompositor' => 'קומפוזיציה',
			'videoSettings.hdrToneMappingCompositorDescription' => 'עובר את הנתונים המוטאדיים HDR של המקור והניח את המפה של שולחן העבודה.',
			'videoSettings.hdrToneMappingPlayer' => 'נגן',
			'videoSettings.hdrToneMappingPlayerDescription' => 'מפה לנקודת המבט הגבוהה של המסך בשחקן, ואז לספר למפיק את התוצאה.',
			'videoSettings.hdrToneMappingFailed' => 'לא ניתן לשנות את מפת הטון HDR - המצב הקודם עדיין פעיל.',
			'videoSettings.audioOutput' => 'אודיו יוצא',
			'videoSettings.performanceOverlay' => 'ביצועים Overlay',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'סביב',
			'videoSettings.audioOutputSpatial' => 'חלל אודיו',
			'videoSettings.audioOutputStereo' => 'סטריאו',
			'videoSettings.audioEqualizer' => 'אודיו Equalizer',
			'videoSettings.audioEqualizerDescription' => 'זמין ב- mpv; EQ פעיל מעודד אודיו ומפחיד את התאמה.',
			'videoSettings.audioEqualizerFlat' => 'שטוח',
			'videoSettings.audioEqualizerActive' => 'מותאם אישית',
			'videoSettings.audioEqualizerSaveFailed' => 'לא יכולתי לשמור את ההגדרות של שווה אודיו.',
			'videoSettings.backgroundVideoAudio' => 'רקע וידאו אודיו',
			'videoSettings.backgroundVideoAudioDescription' => 'שמור על שידור אודיו וידאו כאשר אתה עוזב את השחקן; התמונה מוסתרת עד שאתה חוזר. Android משתמש בהודעה לשחק מדיה.',
			'videoSettings.audioNormalization' => 'נורמליזציה צליל',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'להוריד את האודיו ל- PCM; passthrough נעלם בעוד זה',
			'performanceOverlay.color' => 'צבע',
			'performanceOverlay.performance' => 'ביצועים',
			'performanceOverlay.buffer' => 'בופר',
			'performanceOverlay.app' => 'אפליקציה',
			'performanceOverlay.decoder' => 'דקורטיבי',
			'performanceOverlay.rawDecoder' => 'דקורטיבי Raw',
			'performanceOverlay.tunneling' => 'טונל',
			'performanceOverlay.passthrough' => 'פסטהרו',
			'performanceOverlay.aspect' => 'מבט',
			'performanceOverlay.rotation' => 'סיבוב',
			'performanceOverlay.dvSource' => 'מקור DV',
			'performanceOverlay.dvPath' => 'דרכים DV',
			'performanceOverlay.dvRouteDecoder' => 'Dolby Vision דקודר',
			'performanceOverlay.dvRouteDecoderP81' => 'Dolby Vision דקודר (P7→8.1)',
			'performanceOverlay.dvRouteBaseLayer' => 'מבנה בסיס',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'HDR10 שכבת בסיס',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'מדרגות בסיס HLG',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'SDR מסגרת בסיס',
			'performanceOverlay.dvRouteReshaped' => 'RPU מחדש (gpu-next)',
			'performanceOverlay.p7Conversion' => 'P7 קונב',
			'performanceOverlay.sampleRate' => 'קצב דגימה',
			'performanceOverlay.pixelFormat' => 'פיקסל Fmt',
			'performanceOverlay.hwFormat' => 'ה-Fmt',
			'performanceOverlay.matrix' => 'מתיקס',
			'performanceOverlay.primaries' => 'ראשוני',
			'performanceOverlay.transfer' => 'העברה',
			'performanceOverlay.renderFps' => 'רנדה FPS',
			'performanceOverlay.displayFps' => 'תצוגה FPS',
			'performanceOverlay.avSync' => 'A/V סינכרון',
			'performanceOverlay.dropped' => 'נופל',
			'performanceOverlay.dvRpus' => 'דב RPU',
			'performanceOverlay.dvRpuAverage' => 'ה-RPU AVG',
			'performanceOverlay.dvSampleAverage' => 'דוגמאות AVG',
			'performanceOverlay.maxLuma' => 'מקס לומה',
			'performanceOverlay.minLuma' => 'לומא',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Cache משתמשים',
			'performanceOverlay.cacheLimit' => 'הגבלת Cache',
			'performanceOverlay.speed' => 'מהירות',
			'performanceOverlay.player' => 'נגן',
			'performanceOverlay.playMethod' => 'שיטת נגינה',
			'performanceOverlay.memory' => 'זיכרון',
			'performanceOverlay.uiFps' => 'תגית FPS',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android HW',
			'performanceOverlay.decoderNvidiaHw' => 'NVIDIA HW',
			'performanceOverlay.decoderQualcommHw' => 'Qualcomm HW',
			'performanceOverlay.decoderMediatekHw' => 'מיקרוסופט HW',
			'performanceOverlay.decoderExynosHw' => 'יונייטד HW',
			'performanceOverlay.decoderSoftware' => 'תוכנה',
			'performanceOverlay.decoderHardware' => 'חומרה',
			'performanceOverlay.tunnelingActive' => 'פעיל',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted} (${failures} נכשל)',
			'externalPlayer.title' => 'שחקן חיצוני',
			'externalPlayer.useExternalPlayer' => 'שימוש ב-Player חיצוני',
			'externalPlayer.useExternalPlayerDescription' => 'פתח וידאו באפליקציה אחרת',
			'externalPlayer.selectPlayer' => 'בחר שחקן',
			'externalPlayer.customPlayers' => 'שחקנים מותאמים',
			'externalPlayer.systemDefault' => 'מערכת מזויפת',
			'externalPlayer.addCustomPlayer' => 'להוסיף שחקן מותאם אישית',
			'externalPlayer.playerName' => 'שם שחקן',
			'externalPlayer.playerNameHint' => 'השחקן שלי',
			'externalPlayer.playerCommand' => 'מפקד',
			'externalPlayer.playerPackage' => 'שם החבילה',
			'externalPlayer.playerUrlScheme' => 'תבנית URL',
			'externalPlayer.off' => 'כבוי',
			'externalPlayer.launchFailed' => 'לא פתח שחקן חיצוני',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} לא מותקן',
			'externalPlayer.playInExternalPlayer' => 'לשחק במשחק חיצוני',
			'metadataEdit.editMetadata' => 'ערוך',
			'metadataEdit.screenTitle' => 'ערוך מטא-דאטה',
			'metadataEdit.basicInfo' => 'מידע בסיסי',
			'metadataEdit.artwork' => 'אמנות',
			'metadataEdit.advancedSettings' => 'הגדרות מתקדמות',
			'metadataEdit.title' => 'כותרת',
			'metadataEdit.sortTitle' => 'מיין כותרת',
			'metadataEdit.originalTitle' => 'כותרת מקורית',
			'metadataEdit.releaseDate' => 'תאריך הוצאה',
			'metadataEdit.contentRating' => 'תוכן דירוג',
			'metadataEdit.studio' => 'סטודיו',
			'metadataEdit.tagline' => 'שורת תיוג',
			'metadataEdit.summary' => 'סיכום',
			'metadataEdit.poster' => 'כרזה',
			'metadataEdit.background' => 'רקע',
			'metadataEdit.logo' => 'לוגו',
			'metadataEdit.squareArt' => 'Square אמנות',
			'metadataEdit.selectPoster' => 'בחר פוסטר',
			'metadataEdit.selectBackground' => 'בחר רקע',
			'metadataEdit.selectLogo' => 'בחר את הלוגו',
			'metadataEdit.selectSquareArt' => 'בחר Square Art',
			'metadataEdit.fromUrl' => 'מתוך URL',
			'metadataEdit.uploadFile' => 'להעלות קובץ',
			'metadataEdit.enterImageUrl' => 'כניסת תמונה URL',
			'metadataEdit.imageUrl' => 'תמונה URL',
			'metadataEdit.metadataUpdated' => 'נתונים מתעדכנים',
			'metadataEdit.metadataUpdateFailed' => 'לא הצלחתי לעדכן את הנתונים',
			'metadataEdit.artworkUpdated' => 'ארכיון עדכונים',
			'metadataEdit.artworkUpdateFailed' => 'לא הצלחתי לעדכן את האמנות',
			'metadataEdit.noArtworkAvailable' => 'אין יצירות אמנות זמינות',
			'metadataEdit.artworkOption' => ({required Object index}) => 'האפשרות האמנותית ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'האפשרות האמנותית ${index}, נבחר',
			'metadataEdit.notSet' => 'לא קבע',
			'metadataEdit.libraryDefault' => 'ספרייה פגום',
			'metadataEdit.accountDefault' => 'חשבונאות מזויפת',
			'metadataEdit.seriesDefault' => 'סדרת דפוק',
			'metadataEdit.episodeSorting' => 'סדרה פרק',
			'metadataEdit.oldestFirst' => 'ראשונים ישנים',
			'metadataEdit.newestFirst' => 'החדשות הראשונות',
			'metadataEdit.keep' => 'שמור',
			'metadataEdit.allEpisodes' => 'כל הפרקים',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} פרקים אחרונים',
			'metadataEdit.latestEpisode' => 'פרק אחרון',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'פרקים הוספו בימים האחרונים ${count}',
			'metadataEdit.deleteAfterPlaying' => 'הסרת פרקים לאחר המשחק',
			'metadataEdit.never' => 'אף פעם',
			'metadataEdit.afterADay' => 'אחרי יום אחד',
			'metadataEdit.afterAWeek' => 'אחרי שבוע',
			'metadataEdit.afterAMonth' => 'אחרי חודש',
			'metadataEdit.onNextRefresh' => 'הבא הפריחה',
			'metadataEdit.seasons' => 'עונות',
			'metadataEdit.show' => 'תצוגה',
			'metadataEdit.hide' => 'הסתרה',
			'metadataEdit.episodeOrdering' => 'פרק הזמנה',
			'metadataEdit.tmdbAiring' => 'The Movie Database (בסיס הנתונים של הסרט)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (אירד)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (אופולארי)',
			'metadataEdit.metadataLanguage' => 'שפת Metadata',
			'metadataEdit.useOriginalTitle' => 'שימוש בכותרת מקורית',
			'metadataEdit.preferredAudioLanguage' => 'שפת קול מועדפת',
			'metadataEdit.preferredSubtitleLanguage' => 'שפת כתוביות מועדפת',
			'metadataEdit.subtitleMode' => 'אופטימלי Subtitle Mode',
			'metadataEdit.manuallySelected' => 'בחירה ידנית',
			'metadataEdit.shownWithForeignAudio' => 'תגיות: אודיו זר',
			'metadataEdit.alwaysEnabled' => 'תמיד אפשרי',
			'metadataEdit.tags' => 'מילות מפתח',
			'metadataEdit.addTag' => 'הוסף תגית',
			'metadataEdit.genre' => 'ז\'אנר',
			'metadataEdit.director' => 'במאי',
			'metadataEdit.writer' => 'כותב',
			'metadataEdit.producer' => 'במאי',
			'metadataEdit.country' => 'ארץ',
			'metadataEdit.collection' => 'אוספים',
			'metadataEdit.label' => 'תווית',
			'metadataEdit.quickTag' => 'Tag מהיר',
			'matchScreen.match' => 'משחק ...',
			'matchScreen.fixMatch' => 'קבע את המשחק',
			'matchScreen.unmatch' => 'ביטול התאמה',
			'matchScreen.unmatchConfirm' => 'Plex מתייחס אליו כאילו הוא לא נלחם עד לסיום.',
			'matchScreen.unmatchSuccess' => 'פריט לא מתאים',
			'matchScreen.unmatchFailed' => 'לא הצלחתי להשיג פריט לא מתאים',
			'matchScreen.matchApplied' => 'משחק יישום',
			'matchScreen.matchFailed' => 'לא הצלחתי להשיג את המשחק',
			'matchScreen.titleHint' => 'כותרת',
			'matchScreen.yearHint' => 'שנה',
			'matchScreen.search' => 'חיפוש',
			'matchScreen.noMatchesFound' => 'לא נמצאו משחקים',
			'serverTasks.title' => 'משימות שרת',
			'serverTasks.failedToLoad' => 'לא הצליחו להעלות את המשימות',
			'serverTasks.noTasks' => 'אין משימות מתבצעות',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'מחוברים',
			'trakt.connectedAs' => ({required Object username}) => 'קישור כ @${username}',
			'trakt.disconnectConfirm' => 'הפסקת חיבור לחשבון Trakt?',
			'trakt.disconnectConfirmBody' => 'PlezyNG יפסיק לשלוח אירועים ל- Trakt.',
			'trakt.scrobble' => 'זמן אמיתי Scrobbling',
			'trakt.scrobbleDescription' => 'שלח משחקים, הפסקות, ולעצור אירועים ל- Trakt במהלך הצפייה.',
			'trakt.watchedSync' => 'סינכרון מצב צופה',
			'trakt.watchedSyncDescription' => 'כאשר אתה מסמן פריטים כפי שנצפה ב- PlezyNG, הם מסומנים גם כפי שנצפה ב- Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'חיבור Seerr',
			'seerr.serverUrl' => 'כתובת URL',
			'seerr.serverUrlHelper' => 'כתובת האישום של ה-Seerr',
			'seerr.checkServer' => 'המשך',
			'seerr.signInWithJellyfin' => 'הצטרפו ל- Jellyfin',
			'seerr.signInWithEmby' => 'הצטרפו ל- Emby',
			'seerr.signInWithLocal' => 'השתמש בחשבון מקומי',
			'seerr.email' => 'דואר אלקטרוני',
			'seerr.noSignInMethods' => 'דוגמה זו של Seerr אינה מציעה תמיכה בשיטת ההרשמה PlezyNG.',
			'seerr.instance' => 'אינסטנט',
			'seerr.disconnectConfirm' => 'הפסקת חיבור ל-Seerr?',
			'seerr.disconnectConfirmBody' => 'PlezyNG תשכח את התגובה הזאת של Seerr.',
			'seerr.request' => 'בקשה',
			'seerr.request4k' => 'בקשה 4K',
			'seerr.seasons' => 'עונות',
			'seerr.allSeasons' => 'כל העונות',
			'seerr.advancedOptions' => 'מתקדם',
			'seerr.destinationServer' => 'שרת היעד',
			'seerr.qualityProfile' => 'פרופיל איכות',
			'seerr.rootFolder' => 'שורש קובץ',
			'seerr.languageProfile' => 'פרופיל שפה',
			'seerr.tags' => 'מילות מפתח',
			'seerr.noTags' => 'אין תגיות',
			'seerr.defaultOption' => ({required Object name}) => '${name} (התכונה המוגדרת)',
			'seerr.animeNote' => 'הסדרה הזו היא אנמיה.',
			'seerr.requestSubmitted' => 'בקשה שהוגשה',
			'seerr.requestFailed' => ({required Object error}) => 'בקשה נכשלה: ${error}',
			'seerr.requestsLoadFailed' => 'לא ניתן להעלות את אפשרויות הבקשה',
			'seerr.nothingToRequest' => 'הכל כבר זמין או מבקש.',
			'seerr.statusAvailable' => 'זמין',
			'seerr.statusPartiallyAvailable' => 'זמינים חלקית',
			'seerr.statusRequested' => 'ביקוש',
			'seerr.statusProcessing' => 'עיבוד',
			'seerr.statusBlocklisted' => 'חסום',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => 'לא יכול להגיע ${url}: ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => 'אין דרישה של Seerr ב- ${url} (HTTP ${status})',
			'seerr.behindAuthProxy' => 'שרת Proxy הפוך שדורש אימות (SSO או אימות HTTP) ענה במקום Seerr. PlezyNG לא יכול להתחבר דרכו: יש לאפשר לנתיב /api/v1 של Seerr לעקוף את ה-Proxy עבור היישום, או להשתמש בכתובת שמגיעה ישירות ל-Seerr.',
			'seerr.invalidUrl' => 'הקלד כתובת שרת כגון https://seerr.example.com',
			'seerr.quickConnectUnsupported' => 'דוגמה זו של Seerr אינה תומכת ב- Quick Connect.זה זקוק ל- Seerr 3.4 או יותר.',
			'seerr.notInitialized' => 'מקרה זה של Seerr לא השלים את ההגדרה הראשונה',
			'seerr.noPlexTokenForReauth' => 'מספר Plex טוקן זמין להירשם מחדש',
			'seerr.noStoredCredentials' => 'אין פרטי התחברות שמורים הזמינים להתחברות מחדש',
			'seerr.signInRejected' => 'סינגפור נדחתה',
			'seerr.noSessionCookie' => 'Seerr לא הוציאה קובץ cookie ישיבה',
			'seerr.freshCookieRejected' => 'Seerr סירבה את קובץ העת החדש',
			'seerr.noUserInformation' => 'Seerr לא החזיר מידע משתמש',
			'seerr.sessionRejectedAfterReauth' => 'ההרשמה נדחתה לאחר חתימה נוספת.',
			'seerr.permissionDenied' => 'Seerr הכחישה את הפעולה הזאת: החשבון שלך כבר אין את הרשאה הנדרשת',
			'seerr.permissionRevoked' => 'אין לך יותר רשות לבקש זאת.',
			'services.title' => 'שירותים',
			'services.hubSubtitle' => 'סינכרון עוקב אחר ההתקדמות ולבקש כותרות חדשות.',
			'services.integrations' => 'אינטגרציה',
			'services.notConnected' => 'לא מחוברים',
			'services.connectedAs' => ({required Object username}) => 'קישור כ @${username}',
			'services.scrobble' => 'עקוב אחר ההתקדמות באופן אוטומטי',
			'services.scrobbleDescription' => 'עדכון הרשימה שלך כאשר אתה מסיים פרק או סרט.',
			'services.disconnectConfirm' => ({required Object service}) => 'הפסקת חיבור ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'PlezyNG יפסיק לעדכן ${service}.',
			'services.connectFailed' => ({required Object service}) => 'לא יכולתי להתחבר ל- ${service}.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'מחדש Simkl',
			'services.simklReconnect.subtitle' => 'Simkl הוא להסיר את שיטת ההרשמה באמצעות חיבור זה.התחברות מחדש פותחת simkl.com כדי לאשר PlezyNG — PlezyNG לעולם לא רואה את הסיסמה שלך.היסטוריה השעון שלך נשארת על Simkl.',
			'services.deviceCode.title' => ({required Object service}) => 'הפעל PlezyNG על ${service}',
			'services.deviceCode.instructions' => 'סורק את קוד ה-QR, או תבקר בכתובת למטה ותכנס קוד זה:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'פתח ${service} כדי להפעיל',
			'services.deviceCode.copyCode' => 'העתק קוד הפעולה',
			'services.deviceCode.waitingForAuthorization' => 'מחכה לאישור...',
			'services.deviceCode.codeCopied' => 'קוד עותק',
			'services.oauthProxy.title' => ({required Object service}) => 'הצטרפו ל- ${service}',
			'services.oauthProxy.body' => 'סורק את קוד ה-QR הזה או פותח את ה-URL בכל מכשיר.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'פתח ${service} כדי להירשם',
			'services.pendingAuth.copyUrl' => 'העתק את כתובת URL',
			'services.pendingAuth.urlCopied' => 'URL עותק',
			'services.libraryFilter.title' => 'ספרייה Filter',
			'services.libraryFilter.subtitleAllSyncing' => 'סינכרון כל הספרייה',
			'services.libraryFilter.subtitleNoneSyncing' => 'אין סינכרון',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} חסום',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} מותר',
			'services.libraryFilter.mode' => 'פילטר אופנה',
			'services.libraryFilter.modeBlacklist' => 'רשימה שחורה',
			'services.libraryFilter.modeWhitelist' => 'מותרים',
			'services.libraryFilter.modeHintBlacklist' => 'סינכרון כל ספרייה מלבד אלה שנבדקו למטה.',
			'services.libraryFilter.modeHintWhitelist' => 'סנכרן רק את הספרייה שנבדקה למטה.',
			'services.libraryFilter.libraries' => 'ספריות',
			'services.libraryFilter.noLibraries' => 'אין ספרייה זמינה',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => 'הוסף ${product} שרת',
			'addServer.serverUrls' => 'שרת URL',
			'addServer.serverUrlsHelper' => 'URLים מרובים מותרים, נפרדים על ידי commas.',
			'addServer.findServer' => 'מצא את השרת',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'מחפשים שרתים מקומיים ${product} ...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'שרתים מקומיים ${product}',
			'addServer.username' => 'שם משתמש',
			'addServer.password' => 'סיסמה',
			'addServer.signIn' => 'היכנס',
			'addServer.change' => 'שינוי',
			'addServer.required' => 'נדרש',
			'addServer.couldNotReachServer' => ({required Object error}) => 'לא יכול להגיע לשרת: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'הצטרפות לא מוצלחת: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect נכשל: ${error}',
			_ => null,
		} ?? switch (path) {
			'addServer.addPlexTitle' => 'הצטרפו ל- Plex',
			'addServer.pinExpired' => 'ה-PIN נגמר לפני ההרשמה, אנא נסה שוב.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'חשבונית לא נרשמה: ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => 'הקלד את כתובת ה-URL של השרת שלך ${product}',
			'addServer.addConnectionTitle' => 'להוסיף חיבור',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'הוסף ל ${name}',
			'addServer.signInWithPlexCard' => 'הצטרפו ל- Plex',
			'addServer.signInWithPlexCardSubtitle' => 'אישור מכשיר זה.השרתים המשותפים מוסיפים.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'אישור חשבון Plex משתמשים מקומיים הופכים פרופילים.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => 'חיבור ל- ${product}',
			'addServer.connectToMediaBrowserCardSubtitle' => 'הקלד את כתובת ה-URL, שם המשתמש ואת הסיסמה שלך.',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => 'הצטרפו לשרת ${product}.חברים ל- ${name}.',
			'addServer.borrowFromAnotherProfile' => 'הלוואה מפרט אחר',
			'addServer.borrowFromAnotherProfileSubtitle' => 'השתמש מחדש בקשר של פרופיל אחר.פרופילים מוגנים ב-PIN דורשים PIN.',
			'addServer.invalidCredentials' => 'שם משתמש או סיסמה בלתי חוקיים',
			'addServer.authResponseNotJson' => 'התגובה לאמת לא הייתה שווה JSON',
			'addServer.authResponseIncomplete' => 'התגובה של השרת הייתה לא שלמה.',
			'addServer.quickConnectRejected' => 'Quick Connect נדחה על ידי השרת',
			'addServer.quickConnectNotJson' => 'התשובה Quick Connect לא הייתה שווה JSON',
			'addServer.quickConnectMissingFields' => 'התשובה Quick Connect חסרה קוד או סוד',
			'addServer.quickConnectPollRejected' => 'Quick Connect בקשה נדחתה על ידי השרת',
			'addServer.serverTimedOut' => 'השרת לא הגיב בזמן',
			'addServer.responseNotJson' => 'התגובה לשירות לא הייתה שווה JSON',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'התשובה חסרה מזהה או שם שרת - האם זה שרת ${product}?',
			'addServer.probeFailed' => ({required Object error}) => 'לא יכול להגיע לשרת: ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => 'הקלד לפחות כתובת URL אחת של השרת ${product}',
			'addServer.noReachableServer' => ({required Object product}) => 'לא נמצאו שרתים זמינים ${product}',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'כתובות URL אלה מתייחסים לשרתים שונים ${product}',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'כתובת URL זו אינה תואמת לשרת ${product}',
			'addServer.redirectUnsupported' => 'השרת הועבר ל-URL שאינו נתמך',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'השרת הועבר למארח שונה.הכנס את כתובת ה-URL הסופית ${product} ישירות.',
			'addServer.redirectInsecure' => 'השרת הועבר מ- HTTPS ל- URL לא בטוח',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'השרת הועבר ל-URL שאינו נתמך, הקלד את כתובת ה-URL הסופית ${product} ישירות.',
			'addServer.directPlexServerUrl' => 'Plex כתובת השרת',
			'addServer.directPlexServerUrlHelper' => 'הקלד את ה- IP המקומי ואת הפורט של Plex Media Server שלך.',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex טוקן (אופציונלי)',
			'addServer.plexTokenHelper' => 'השאירו ריק אם גישה ללא auth מותרת בשרת זה.',
			'addServer.plexTokenRequired' => 'אנא הקלד את טוקן Plex שלך (X-Plex-Token).',
			'addServer.connectDirectPlexCard' => 'Plex שרת מדיה (מיד / מקומי)',
			'addServer.connectDirectPlexCardSubtitle' => 'חיבור ישיר באמצעות IP או כתובת URL מקומית ללא חשבון plex.tv.',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => 'חיבור ישיר באמצעות IP מקומי או כתובת URL. חיבור ל- ${name}.',
			'addServer.insecureTitle' => 'חיבור לא מוצפן',
			'addServer.insecureDescription' => ({required Object url}) => '${url} משתמש ב-HTTP. אנשים ברשת עלולים לקרוא או לשנות את הסיסמה, האסימונים והמדיה שלך. יש להשתמש ב-HTTPS כשהוא זמין. יש להמשיך רק אם הרשת אמינה בעיניך והסיכון מקובל עליך.',
			'addServer.allowHttp' => 'לאפשר HTTP',
			'addServer.httpsRequired' => 'שימוש ב- HTTPS או מאפשר באופן מפורש חיבור לא מוצפן.',
			'watchLink.serverUnavailable' => 'לא יכולתי להגיע לשרת Plex עבור קישור זה.',
			'watchLink.notFound' => 'לא מצאתי את ההצגה או הסרט הזה בשרתים שלך Plex.',
			'watchLink.ambiguous' => 'קישור זה תואם פריטים על יותר ממשרת אחד.',
			'watchLink.plexOnly' => 'קישורים לצפייה תומכים כיום רק בשרתים Plex.',
			'watchLink.unsupportedItem' => 'קישורים לצפייה יכולים לפתוח רק מופע או סרט.',
			'watchLink.menuItem' => 'צפו בקישור',
			'watchLink.dialogTitle' => 'צפו בקישור',
			'watchLink.dialogShowHint' => 'פתיחת הקישור הזה משחק את הפרק הבא. Add &mode=shuffle to the end to play the show on shuffle.',
			'watchLink.dialogMovieHint' => 'פתיחת הקישור הזה משחק את הסרט.',
			'watchLink.copy' => 'העתק',
			'watchLink.copied' => 'קישור עותק',
			'homeLayout.title' => 'בית Layout',
			'homeLayout.resetToast' => 'בית מחדש לרישום הגיבור המקורי Plezy',
			'homeLayout.resetHeroTitle' => 'להגדיר מחדש את הפריסה של הגיבור למלאי Plezy?',
			'homeLayout.resetHeroBody' => 'הפוך את הגדרת הגיבור של כל שורה ומביא בחזרה את הבאנר הסיבוב היחיד בחלק העליון של הבית, כמו לפני שורות הגיבורים היו קיימים.',
			'homeLayout.removeRowTitle' => 'להסיר את הבית?',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} יימחק, זה לא יכול להימנע.',
			'homeLayout.sync' => 'סנכרון',
			'homeLayout.syncAccountTitle' => 'סינכרון הפריסה עם החשבון שלך Plex',
			'homeLayout.syncAccountOn' => 'על: מכשיר זה חולק סדר שורות, שורות, גיבור ו- Auto-slide עם המכשירים האחרים שלך.',
			'homeLayout.syncAccountOff' => 'סגור: המכשיר הזה שומר על הפריסה שלו.',
			'homeLayout.syncNow' => 'סינכרון עכשיו',
			'homeLayout.plexHomeManager' => 'Plex מנהל בית',
			'homeLayout.managePlexRows' => 'ניהול Plex שורות ב Plezy',
			'homeLayout.managePlexRowsDescription' => 'פתוח לארגן את השורות שנבחרו בבית',
			'homeLayout.organizeHomeRows' => 'ארגון שורות בית',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} שורות: זז, גיבור, אוטומטית, להסיר',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => 'ארגון ${library} שורות',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => 'המשך צפייה + ${n} שורות: תנועה, ספרייה, בית, גיבור, אוטומטית',
			'homeLayout.renderAsHero' => 'רנדה ככרטיס גיבור',
			'homeLayout.heroOnlySingleCollection' => 'זמין רק כאשר שורה זו מתפתחת לכותרות אמיתיות של אוסף יחיד',
			'homeLayout.hero' => 'גיבור',
			'homeLayout.autoSlide' => 'אוטומטי Slide',
			'homeLayout.autoSlideDescription' => 'גם סליטה על עצמה בכל כמה שניות.Arrows (PC) ו-d-pad (TV) תמיד עובדים ומתחילים מחדש את השעון.',
			'homeLayout.autoSlideEditDescription' => 'הוא גם זורם בעצמו כל כמה שניות. off: זורם רק כאשר אתה לוחץ על אקדח (מחשב) או לחץ שמאל / ימין על הרחוק (טלוויזיה).',
			'homeLayout.enableHeroFirst' => 'תנו לגיבור ראשון',
			'homeLayout.showOnHome' => 'הצג על המסך הבית',
			'homeLayout.home' => 'בית',
			'homeLayout.removeFromHome' => 'להסיר מהבית',
			'homeLayout.selectRowsFirst' => 'בחר את שורות הבית למטה קודם.',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} Plex שורות מנוהלות',
			'homeLayout.continueWatching' => 'המשך צפייה',
			'homeLayout.continueWatchingLibraryDescription' => 'ספריית התקדמות עצמית של הספרייה',
			'homeLayout.continueWatchingHomeDescription' => 'רצועת ההתקדמות המוצגת בבית',
			'homeLayout.nextUpHomeDescription' => 'השורה הבאה של הפרק לא נצפה הוצגה בנפרד בבית',
			'homeLayout.library' => 'ספרייה',
			'homeLayout.showInRecommended' => 'תגית: הספרייה המומלצת',
			'homeLayout.customPlexRow' => 'אישית Plex שורה',
			'homeLayout.heroNeedsLibrary' => 'ראשית, בדוק את הספרייה – גיבור צריך איפשהו להראות',
			'homeLayout.heroNeedsSurface' => 'ראשית בדוק את הספרייה או הבית – גיבור צריך איפשהו להראות',
			'homeLayout.removeHub' => 'להסיר Hub',
			'homeLayout.noPlexRows' => 'מספר Plex שורות המנוהלות חזרה לספריה זו.',
			'homeLayout.openDetails' => 'פרטים פתוחים',
			'homeLayout.heroCards' => 'כרטיסי גיבור',
			'homeLayout.tapHeroCard' => 'להדביק כרטיס גיבור',
			'homeLayout.tvPlayFocus' => 'טלוויזיה מרחוק: כפתור Play',
			'homeLayout.tvPlayFocusDescription' => 'D-pad למטה עוצר על כפתור המשחק לפני העברת השורה הבאה.',
			'homeLayout.tvWrap' => 'טלוויזיה מרחוק: כרטיסי גיבור לופ',
			'homeLayout.tvWrapDescription' => 'לחיצה שמאלה בכרטיס האחרון מחזירה לכרטיס הראשון. כשהאפשרות כבויה, הניווט נעצר בכרטיס האחרון. לחיצה ימינה בכרטיס הראשון תמיד עוברת לסרגל הצד.',
			'homeLayout.castOnHero' => 'תגיות קשורות Hero Banner',
			'homeLayout.castOnHeroDescription' => 'מציג את ההצגה לאורך החלק התחתון של הלוח הגיבור. off שמור רק את הכותרת ואת הסיכום.',
			'homeLayout.customRows' => 'עקבות מותאמות',
			'homeLayout.loading' => 'תגית: Home Layout',
			'homeLayout.noCustomRows' => 'עדיין אין שורות קבועות',
			'homeLayout.addRowHint' => 'השתמשו בסדרת הוספת הבית כדי ליצור אחד.',
			'homeLayout.addHomeRow' => 'להוסיף Home Row',
			'homeLayout.addHomeRowDescription' => 'בחר קטגוריה; השורה החדשה מוסיפה באופן אוטומטי למארגן',
			'homeLayout.removeRow' => 'להסיר שורה',
			'homeLayout.recentlyAdded' => 'אחרון',
			'homeLayout.recentlyReleased' => 'שוחרר לאחרונה',
			'homeLayout.movieCollections' => 'קולקציות סרטים',
			'homeLayout.showCollections' => 'הצג אוסף',
			'homeLayout.rowTitle' => 'כותרת Row',
			'homeLayout.content' => 'תוכן',
			'homeLayout.showThisRowIn' => 'הצג את השורה הזאת ב:',
			'homeLayout.libraryRecommended' => 'הספרייה המומלצת',
			'homeLayout.heroCard' => 'כרטיס גיבור',
			'homeLayout.heroCardDescription' => 'מציג כרטיס סיבוב אחד רחב מלא במקום מפתח פוסטר.',
			'homeLayout.heroUnavailableDescription' => 'זמין רק כאשר שורה זו מתייחסת לכותרות האמיתיות של אוסף יחיד – עם יותר מאחד אוספים שנבחרו, אין כותרת יחידה להסתובב.',
			'homeLayout.librariesSelection' => 'ספריות (לשחרר את כל הבלתי נבדקים לכל ספרייה)',
			'homeLayout.librariesMergedDescription' => 'כל ספרייה שנבדקה כאן מתמזגת בשורה אחת זו.',
			'homeLayout.movieCollectionsSelection' => 'אוסף סרטים (שחרר את כל הבלתי נבדק עבור כל ספרייה שנבחרה)',
			'homeLayout.showCollectionsSelection' => 'הצג אוסף (לשחרר את כל הבלתי נבדק עבור כל ספרייה שנבחרה)',
			'homeLayout.collectionRowsDescription' => 'אם בדיוק אוסף אחד מתאים, הכותרות שלו מופיעות ישירות ברציפות.אם יותר מאחד מתאים, כל אוסף מופיע כפוסט יחיד – הקלד אותו כדי לפתוח את האוסף.',
			'homeLayout.allCollections' => 'כל הקולקציות',
			'homeLayout.noRowsHere' => 'עדיין אין שורות כאן.',
			'homeLayout.hideWatchedRows' => 'להסתיר פריטים שנצפו בשורות',
			'homeLayout.hideWatchedRowsDescription' => 'כותרות צפייה מלאה עוזבות בית וספריה שורות מומלצות.',
			'homeLayout.untitledCollection' => 'אוסף ללא שם',
			'homeLayout.moveRowHint' => 'למעלה/למטה: לעבור שורה · בחר: להוריד כאן · בחזרה: לבטל',
			'homeLayout.organizeRowsHint' => 'בחר על שורה (או להחזיק בחר): לעבור אותה · שמאל/מימין: אפשרויות שורה · בחזרה: נעשה',
			'homeLayout.layoutNavDescription' => 'בחר שורות, ספריות וקטגוריות אוסף',
			'homeLayout.editHomeRow' => 'תגית: Home Row',
			'homeLayout.resetHeroButton' => 'מחדש את הפריסה של הגיבור למלאי Plezy',
			'homeLayout.reorderingUnlocked' => 'מחדש מחוץ לנעול',
			'homeLayout.reorderingLocked' => 'מחדש סגור',
			'homeLayout.rowsCanBeDragged' => 'ניתן לגרד את החוטים - לחץ על המנעול כדי למנוע זאת.',
			'homeLayout.tapLockToDrag' => 'לחצו על המנעול כדי לגרור שורות',
			'homeLayout.customRowLabel' => ({required Object title}) => 'תגית: ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => 'הסתרה',
			'homeLayout.remove' => 'הסר',
			'homeLayout.libraryResumeRow' => 'הספרייה מחדש של הספרייה',
			'homeLayout.pressAgainToDelete' => 'לחץ שוב כדי למחוק',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => 'על',
			'homeLayout.resetHeroButtonDescription' => 'הפוך את הגדרת הגיבור של כל שורה ומביא בחזרה את הבאנר היחיד מסתובב בחלק העליון, כמו לפני שורות הגיבורים היו קיימים.',
			'platform.localNetworkPermission' => 'PlezyNG מתחבר לשרתי המדיה ולמכשירי הניגון ברשת המקומית שלך.',
			'platform.locationPermission' => 'PlezyNG משתמשת בגישה למיקום כאשר iOS דורש גישה כדי לזהות את הרשת המקומית שלך ולהתחבר לשרתי התקשורת שלך.',
			'platform.photoLibraryPermission' => 'בחר תמונות מתוך ספריית התמונות שלך לשימוש כאמנות מדיה.',
			'platform.cameraPermission' => 'סריקת קודי QR לצימוד שלט Companion Remote.',
			'fileSources.title' => 'קבצים וספרים',
			'fileSources.subtitle' => 'קרא, הקשיב, והצפה מהקבצים שלך.',
			'fileSources.add' => 'הוסף מקור',
			'fileSources.importFiles' => 'קבצים ייבוא',
			'fileSources.localFiles' => 'על המכשיר הזה',
			'fileSources.source' => 'מקור',
			'fileSources.name' => 'שם',
			'fileSources.endpoint' => 'כתובת URL',
			'fileSources.root' => 'תיקייה או קידומת',
			'fileSources.username' => 'שם משתמש',
			'fileSources.password' => 'סיסמה',
			'fileSources.token' => 'API טוקן',
			'fileSources.accessKey' => 'גישה מפתח ID',
			'fileSources.secretKey' => 'מפתח גישה סודי',
			'fileSources.sessionToken' => 'ישיבה טוקן (אופציונלי)',
			'fileSources.region' => 'אזור',
			'fileSources.clientId' => 'ה-OAuth Client ID',
			'fileSources.clientSecret' => 'OAuth Client Secret (משרד Google בלבד)',
			'fileSources.allowHttp' => 'לאפשר HTTP ללא הצפנה ברשת מהימנה',
			'fileSources.connect' => 'התחבר',
			'fileSources.cancel' => 'בטל',
			'fileSources.save' => 'שמור',
			'fileSources.close' => 'סגור',
			'fileSources.removeSource' => 'מקור מחוץ למקור',
			'fileSources.disconnectMessage' => 'לנתק את המקור הזה? הקבצים שהורדו והיסטוריית הקריאה וההאזנה שלך יישארו במכשיר הזה.',
			'fileSources.localFolder' => 'בחר תיקיה',
			'fileSources.empty' => 'שום דבר כאן עדיין',
			'fileSources.emptyHint' => 'להוסיף מקור או לייבא ספר, ספר שמע, מוזיקה או וידאו.',
			'fileSources.search' => 'לחפש את המאמר הזה',
			'fileSources.searchCached' => 'חיפוש ספרייה שנשמרה',
			'fileSources.refresh' => 'רענון',
			'fileSources.loadMore' => 'להעלות יותר',
			'fileSources.offline' => 'זמין offline',
			'fileSources.download' => 'להישאר offline',
			'fileSources.removeDownload' => 'להסיר offline copy',
			'fileSources.continueReading' => 'המשך קריאה',
			'fileSources.continueListening' => 'המשך להאזין',
			'fileSources.continueWatching' => 'המשך צפייה',
			'fileSources.read' => 'קראו',
			'fileSources.listen' => 'לשמוע',
			'fileSources.play' => 'נגן',
			'fileSources.pause' => 'השהה',
			'fileSources.stop' => 'עצור',
			'fileSources.startOver' => 'התחל על',
			'fileSources.finished' => 'הסתיימה',
			'fileSources.markFinished' => 'מארק הסתיים',
			'fileSources.markUnfinished' => 'מארק בלתי נגמר',
			'fileSources.editions' => 'עיתונים וארכיונים',
			'fileSources.chapters' => 'פרק',
			'fileSources.bookmarks' => 'ספרות ומזכירות',
			'fileSources.bookmark' => 'הוסף Bookmark',
			'fileSources.highlight' => 'להדגיש',
			'fileSources.note' => 'הערה',
			'fileSources.delete' => 'מחק',
			'fileSources.export' => 'הערות ייצוא',
			'fileSources.exported' => 'הערות ייצוא',
			'fileSources.sync' => 'סינכרון התקדמות',
			'fileSources.synced' => 'התקדמות סינכרון',
			'fileSources.conflict' => 'מכשיר אחר יש עמדה שונה.בחור איפה להמשיך.',
			'fileSources.useLocal' => 'השתמש במכשיר זה',
			'fileSources.useRemote' => 'שימוש במכשיר אחר',
			'fileSources.history' => 'היסטוריה של עמדה',
			'fileSources.groupAudio' => 'להקשיב כספר אודיו',
			'fileSources.groupHint' => 'משלב את קובצי השמע שנטענו כרגע בתיקייה הזאת. יש לטעון קודם את כל העמודים.',
			'fileSources.order' => 'צו קובץ',
			'fileSources.moveUp' => 'תנועות למעלה',
			'fileSources.moveDown' => 'תנו למטה',
			'fileSources.speed' => 'מהירות ניגון',
			'fileSources.sleep' => 'שעות שינה',
			'fileSources.sleepOff' => 'כבוי',
			'fileSources.endChapter' => 'סוף פרק',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} דקה', two: 'שתי דקות', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} דקות', ), 
			'fileSources.skipBack' => 'סקי בחזרה',
			'fileSources.skipForward' => 'קפיצה קדימה',
			'fileSources.smartRewind' => 'חכמה לאחר הפסקה',
			'fileSources.playbackOptions' => 'אפשרויות האזנה',
			'fileSources.remaining' => ({required Object time}) => '${time} שאר',
			'fileSources.contents' => 'תוכן',
			'fileSources.readerSettings' => 'קראת ההגדרות',
			'fileSources.fontSize' => 'גודל טקסט',
			'fileSources.lineHeight' => 'קו חלל',
			'fileSources.margin' => 'מרג\'ינס',
			'fileSources.font' => 'סוג',
			'fileSources.serif' => 'סריף',
			'fileSources.sans' => 'ללא סריף',
			'fileSources.mono' => 'מונוספייס',
			'fileSources.columns' => 'עמודים',
			'fileSources.scroll' => 'סורק לעקוב',
			'fileSources.justify' => 'יישור טקסט לשני הצדדים',
			'fileSources.readerTheme' => 'דף מראה',
			'fileSources.appTheme' => 'עקבו אחרי app theme app theme',
			'fileSources.paper' => 'נייר',
			'fileSources.sepia' => 'ספיא',
			'fileSources.night' => 'לילה',
			'fileSources.readAloud' => 'להקריא את העמוד הזה בקול',
			'fileSources.readAlong' => 'לקרוא עם ההקראה',
			'fileSources.stopReading' => 'להפסיק את ההקראה',
			'fileSources.searchBook' => 'חיפוש בספר',
			'fileSources.noMatches' => 'אין משחקים',
			'fileSources.previousPage' => 'עמוד קודם',
			'fileSources.nextPage' => 'עמוד הבא',
			'fileSources.page' => ({required Object number}) => 'עמוד ${number}',
			'fileSources.externalBlocked' => 'קישורים חיצוניים בספרים מושבתים בקורא.',
			'fileSources.loading' => 'פתיחת...',
			'fileSources.narrator' => 'נרצחים',
			'fileSources.audio' => 'שמע',
			'fileSources.video' => 'וידאו',
			'fileSources.ebooks' => 'ספרים אלקטרוניים',
			'fileSources.all' => 'הכול',
			'fileSources.downloads' => 'קבצים Offline',
			'fileSources.confirmDelete' => 'להסיר את העותק שנבחר לשימוש לא מקוון? מיקום הקריאה או ההאזנה וההערות שלך יישמרו.',
			'fileSources.errorAuthentication' => 'יש להתחבר שוב כדי לחבר מחדש את המקור.',
			'fileSources.errorPermission' => 'מקור זה לא נתן גישה לקובץ הנדרש.',
			'fileSources.errorUnavailable' => 'המקור אינו זמין, נסה שוב או פתח עותק לא מקוון.',
			'fileSources.errorUnsupported' => 'פורמט זה או חיבור זה אינם נתמכים במכשיר זה.הצג את מדריך ההגדרה של המקור.',
			'fileSources.errorInvalidData' => 'קובץ זה או התגובה של השרת לא ניתן לקרוא בבטחה.',
			'fileSources.errorCancelled' => 'המבצע בוטל.',
			'fileSources.errorConflict' => 'מיקום הקריאה או ההאזנה השתנה בהפעלה אחרת. יש לפתוח שוב את הפריט כדי לבחור מיקום.',
			'fileSources.signIn' => 'היכנס',
			'fileSources.reconnect' => 'מחדש',
			'fileSources.folderHelp' => 'יש להשאיר ריק כדי להתחיל בתיקיית השורש של המקור. כתובות S3 כוללות את שם ה-bucket.',
			'fileSources.preferences' => 'העדפות',
			'fileSources.timePosition' => 'עמדה',
			'fileSources.audioTrack' => 'אודיו טרק',
			'fileSources.subtitleTrack' => 'תגית: track',
			'fileSources.none' => 'אין',
			'fileSources.fullscreen' => 'מסך מלא',
			'fileSources.syncLocation' => 'תיבת ה-Progress Sync (אופציונלית)',
			'fileSources.syncLocationHint' => 'תיקיית WebDAV ייעודית לשמירת מצב PlezyNG. משתמש בכתיבה מותנית; קובצי המדיה נשארים ללא שינוי.',
			'fileSources.audiobooks' => 'ספרים מוקלטים',
			'fileSources.comics' => 'קומיקס',
			'fileSources.scan' => 'סריקה עבור ספרים ותקשורת',
			'fileSources.browserReader' => 'פתוח קורא',
			'fileSources.browserReaderHelp' => 'הקורא פתוח בדפדפן שלך. שמור PlezyNG פתוח כדי לשמור את המיקום שלך ואת הערות.',
			'fileSources.on' => 'על',
			'fileSources.advancedSetup' => 'App רישום',
			'fileSources.microsoftSignIn' => 'הצטרפו ל-Microsoft',
			'fileSources.zoomIn' => 'זום ב',
			'fileSources.zoomOut' => 'זום יוצא',
			'fileSources.fitPage' => 'דף מתאים',
			'fileSources.fitWidth' => 'מתאים לרוחב',
			'fileSources.actualSize' => 'גודל אמיתי',
			'fileSources.goToPage' => 'ללכת לדף',
			'fileSources.goToSection' => 'ללכת לפסוק',
			'fileSources.pageRange' => ({required Object count}) => 'הקלד מספר מ 1 ל ${count}',
			'fileSources.pageLayout' => 'דף Layout',
			'fileSources.automatic' => 'אוטומטית',
			'fileSources.singlePage' => 'דף יחיד',
			'fileSources.twoPages' => '2 עמודים',
			'fileSources.readingDirection' => 'קריאה בכיוון',
			'fileSources.leftToRight' => 'שמאל ימינה',
			'fileSources.rightToLeft' => 'מימין לשמאל',
			'fileSources.letterSpacing' => 'ספר חלל',
			'fileSources.wordSpacing' => 'מילה חלל',
			'fileSources.readerControlsHelp' => 'כדי להגדיל עמודים, אפשר להרחיק שתי אצבעות זו מזו או להשתמש בפקדי הזום. יש לגרור כדי להזיז את העמוד. Ctrl/⌘ יחד עם + או − משנה את הזום; Ctrl/⌘ יחד עם 0 מאפס אותו. Page Up ו-Page Down מדפדפים בין העמודים.',
			'fileSources.imagePage' => 'דף קומדיה',
			'fileSources.resetReader' => 'איפוס העדפות הקריאה',
			'fileSources.zoom' => 'זום',
			'fileSources.useFiles' => 'שימוש בקבצים ובספרים',
			'fileSources.cancelScan' => 'ביטול סריקה',
			'fileSources.googleDrive' => 'Google Drive',
			'fileSources.smbEndpointHint' => 'לדוגמה: smb://nas/Movies',
			'fileSources.smbEndpointInvalid' => 'יש להזין שרת SMB ותיקייה משותפת אחת.',
			'fileSources.smbFolderHelp' => 'יש להשאיר ריק כדי להשתמש בכל התיקייה המשותפת, או להזין תיקייה בתוכה.',
			'fileSources.smbDomain' => 'תחום (רשות)',
			'fileSources.smbEncryption' => 'הצפנת חיבור SMB3',
			'fileSources.smbEncryptionHint' => 'שימוש בהצפנת SMB3 כאשר התקן ה־NAS תומך בכך.',
			'lending.title' => 'ספרייה ציבורית',
			'lending.add' => 'הוסף ספרייה',
			'lending.other' => 'ספרייה נוספת',
			'lending.libraryName' => 'שם הספרייה',
			'lending.libraryUrl' => 'אתר הספרייה',
			'lending.libraryUrlHint' => 'יש להשתמש בקטלוג של הספרייה או בעמוד ההתחברות שלה.',
			'lending.intro' => 'לשאול ספרים מהספרייה שלך ולהשאיר אותם קרוב אליך.',
			'lending.handoff' => 'להתחבר, לשאול ספרים ולקרוא בבטחה באמצעות השירות של הספרייה שלך.',
			'lending.openService' => 'ספרייה פתוחה',
			'lending.findLibrary' => 'מצא ספרייה',
			'lending.search' => 'חיפוש ספרים וסופרים',
			'lending.catalogue' => 'קטגוריה',
			'lending.loans' => 'השאלות',
			'lending.holds' => 'הזמנות',
			'lending.signIn' => 'הצטרפו לספריה שלכם',
			'lending.waiting' => 'הסתיימו את ההרשמה בדפדפן שלכם, ואז תחזרו לכאן.',
			'lending.cancel' => 'בטל',
			'lending.disconnect' => 'הסרת ספרייה',
			'lending.disconnectMessage' => 'להסיר את הספרייה הזאת מהפרופיל הזה? ההשאלות וההזמנות שלך יישארו בספרייה.',
			'lending.getBook' => 'קבל ספר',
			'lending.checkAvailability' => 'בדוק את זמינות',
			'lending.available' => 'זמין להשאלה',
			'lending.unavailable' => 'כרגע לא זמין',
			'lending.borrow' => 'לשאול',
			'lending.placeHold' => 'להזמין',
			'lending.returnBook' => 'החזרה לפני המועד',
			'lending.cancelHold' => 'לבטל הזמנה',
			'lending.confirmBorrow' => 'האם אתה משלם את הכותרת הזו מהספרייה שלך?',
			'lending.confirmReturn' => 'להחזיר את הכותר הזה עכשיו? ייתכן שיהיה צורך לשאול אותו שוב כדי להמשיך.',
			'lending.confirmCancelHold' => 'לבטל את ההזמנה שלך לכותר הזה?',
			'lending.email' => 'שמור הודעה בדואר אלקטרוני',
			'lending.due' => ({required Object date}) => 'מועד החזרה: ${date}',
			'lending.queue' => ({required Object position}) => 'מקום ${position} בתור',
			'lending.empty' => 'אין שם עדיין כאן.',
			'lending.openLibraryNote' => 'אפשר לעיין בקטלוג של Open Library. אפשרויות הקריאה וההשאלה מוצגות בעמוד של כל כותר.',
			'lending.more' => 'להעלות יותר',
			'lending.gateway' => 'ספרייה שירות חתימה',
			'lending.gatewayHint' => 'מסופק על ידי הספרייה שלך או המנהל PlezyNG.',
			'lending.advanced' => 'אינטגרציה ספרייה',
			'lending.loadLibraries' => 'בחר את הספרייה שלך',
			'lending.expired' => 'תקופת ההשאלה הסתיימה.',
			'lending.updated' => 'ספרייה עדכנה',
			'lending.continueService' => 'להמשיך בשירות',
			'lending.comingSoon' => 'הלוואות ב-App · מגיע בקרוב',
			'lending.comingSoonDescription' => 'אתה יכול להשתמש בספריה שלך ב- Libby בזמן שאנחנו מסיימים את חיבורו.',
			'lending.suspendHold' => 'להשהות הזמנה',
			'lending.resumeHold' => 'לחדש הזמנה',
			'lending.suspendMessage' => 'לשמור על מקומך בתור ולאפשר לקורא הבא לשאול את העותק הזה? אפשר לחדש את ההזמנה בהמשך.',
			'lending.resumeMessage' => 'לחדש את ההזמנה כדי שהספרייה תוכל להציע לך את העותק הזמין הבא?',
			'lending.editEmail' => 'שינוי הודעת דואר אלקטרוני',
			'audiobook.syncTitle' => 'קריאה ושמיעה Sync',
			'audiobook.syncHelp' => 'שמור על עמדות קריאה, עמדות הקשבה, מצב השלמת, תוויות ספרים והערות בכל המכשירים שלך.בחור חשבון אחסון מקושר ולהשתמש באותו קוד סינכרון בכל מכשיר.קריאה ושמיעה נשארים נפרדים.',
			'audiobook.addSyncSource' => 'הוסף Google Drive, OneDrive, Dropbox, WebDAV או S3 בקבצים וספרים קודם.',
			'audiobook.syncDestination' => 'חשבונות אחסון Sync',
			'audiobook.syncFolder' => 'סינכרון קובץ או Prefix',
			'audiobook.syncFolderHelp' => 'השתמש בתיקיה קיימת נפרדת בתוך מקור WebDAV שלך, או תיקיה מוקדמת S3.',
			'audiobook.syncCode' => 'קוד סינכרון פרטי',
			'audiobook.syncCodeHelp' => 'יצירת קוד על המכשיר הראשון שלך, ולאחר מכן הקלד את הקוד על המכשירים האחרים שלך.שמור עותק פרטי: זה המפתח למצב הצפנה שלך.',
			'audiobook.showCode' => 'הצג או להסתיר קוד סינכרון',
			'audiobook.newSyncCode' => 'יצירת קוד סינכרון חדש',
			'audiobook.saveSync' => 'שמור וסינכרון',
			'audiobook.disableSync' => 'הפסקת סינכרון במכשיר זה',
			'audiobook.syncSourceDisconnect' => 'הסרת מקור זה יפסיק לקרוא ולהקשיב סינכרון כאן.',
			'audiobook.syncReconnect' => 'חיבור מחדש לחשבון אחסון',
			'audiobook.lastSynced' => ({required Object time}) => 'תגית: ${time}',
			'audiobook.syncPrivacy' => 'רק התקדמות מוצפנת והערות מאוחסנות. קבצי אודיו וספרים אלקטרוניים, טוקנים של חשבון וסיסמאות אינם מועברים. Google Drive ו- OneDrive משתמשים אחסון אפליקציות; Dropbox משתמשת ב- PlezyNG Sync. מאפשרת סינקה עשויה לבקש גישה כתיבה נוספת. בעוד מאוחסנת, יעד זה מחזיק ב- Progress Sync; התקדמות השרת נשארת נפרדת.',
			'audiobook.syncConflicts' => 'בחר איפה להחזיר',
			'audiobook.conflictHelp' => 'שינויים אלה נעשו באופן עצמאי.בחרו את המיקום או גרסת הסימון כדי לשמור.זמן מאוחר יותר או אחוז גבוה יותר לא מנצח באופן אוטומטי.',
			'audiobook.syncDevice' => ({required Object device}) => 'מכשיר ${device}',
			'audiobook.syncUnknownDevice' => 'מכשיר לא ידוע',
			'audiobook.deletedBookmark' => 'ספריה שנמחקו',
			'audiobook.finished' => 'הסתיימה',
			'audiobook.readingPosition' => ({required Object percent}) => 'קריאה · ${percent}%',
			'audiobook.chapterTimeline' => 'פרק התקדמות',
			'audiobook.bookTimeline' => 'כל הספר התקדמות',
			'audiobook.bookRemaining' => ({required Object time}) => 'זמן שנשאר בספר זה: ${time}',
			'audiobook.chapterRemaining' => ({required Object time}) => 'זמן שנשאר בפרק זה: ${time}',
			'audiobook.unknownRemaining' => 'זמן מלא זמין כאשר חלקים משחקים',
			'audiobook.undoSeek' => 'לאחרונה מחפשים',
			'audiobook.customSpeed' => 'מהירות Playback Custom',
			'audiobook.speedHelp' => 'בחר מהירות של 0.25× עד 4×.',
			'audiobook.apply' => 'יישום',
			'audiobook.customSleep' => 'שעות שינה מותאמות אישית',
			'audiobook.sleepMinutes' => 'דקות (1 – 1440)',
			'audiobook.sleepChapters' => ({required Object count}) => 'עקבו אחרי ${count}',
			'audiobook.extendSleep' => 'להוסיף 5 דקות',
			'audiobook.sleepRemaining' => ({required Object time}) => 'זמן שינה: ${time}',
			'audiobook.useDefaults' => 'השתמש בקונסולות האזנה אלה עבור ספרים חדשים',
			'audiobook.librarySort' => 'ספרים מגוונים',
			'audiobook.sortTitle' => 'כותרת',
			'audiobook.sortAuthor' => 'סופר',
			'audiobook.sortNarrator' => 'סיפורי',
			'audiobook.sortSeries' => 'סדרת הוראות',
			'audiobook.sortRecent' => 'נפתח לאחרונה',
			'audiobook.statusFilter' => 'מצב קריאה',
			'audiobook.statusAll' => 'כל הספרים',
			'audiobook.statusNew' => 'לא התחיל',
			'audiobook.statusProgress' => 'התקדמות',
			'audiobook.statusFinished' => 'הסתיימה',
			'audiobook.goToTime' => 'ללכת בזמן',
			'audiobook.timeHelp' => 'שעות: דקות: שניות או דקות: שניות',
			'sourceSetup.savedCertificate' => 'אישור השרת השמור',
			'sourceSetup.nfsEndpointInvalid' => 'יש להזין כתובת NFS, למשל nfs://nas:2049/export.',
			'sourceSetup.dlnaNone' => 'לא נמצאו שרתי DLNA. יש להזין ידנית את כתובת תיאור ההתקן.',
			'sourceSetup.dlnaServers' => 'שרתי מדיה של DLNA',
			'sourceSetup.dlnaUnavailable' => 'גילוי DLNA אינו זמין ברשת הזו. יש להזין ידנית את כתובת תיאור ההתקן.',
			'sourceSetup.dlnaSearching' => 'מתבצע חיפוש שרתי DLNA ברשת המקומית',
			'sourceSetup.networkSearching' => 'מתבצע חיפוש ברשת המקומית…',
			'sourceSetup.dlnaDiscover' => 'גילוי שרתי DLNA',
			'sourceSetup.dlnaHelp' => 'הגילוי תלוי בשידור מרובה יעדים ברשת המקומית. אם לא מופיע שרת, יש להזין למעלה את כתובת תיאור ההתקן שלו.',
			'sourceSetup.dlnaRoot' => 'מזהה אובייקט DLNA; יש להשאיר ריק כדי להשתמש בתיקיית השורש של ההתקן.',
			'sourceSetup.passwordOrKey' => 'יש להזין סיסמה או להוסיף מפתח פרטי למטה.',
			'sourceSetup.sshFingerprint' => 'טביעת אצבע SHA256 של מפתח מארח SSH',
			'sourceSetup.sshFingerprintHelp' => 'יש לאמת מול מנהל השרת. בשרת, יש להריץ ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub ולהשתמש בערך SHA256 שמתקבל.',
			'sourceSetup.sshFingerprintKeep' => 'יש להשאיר ריק כדי לשמור על טביעת האצבע המקובעת הנוכחית, או להזין טביעת אצבע חדשה של השרת.',
			'sourceSetup.sshAuthentication' => 'אימות באמצעות מפתח ציבורי של SSH',
			'sourceSetup.sshAuthenticationHelp' => 'לא חובה; אפשר גם לבצע אימות באמצעות סיסמה.',
			'sourceSetup.privateKey' => 'מפתח פרטי (בפורמט PEM או OpenSSH)',
			'sourceSetup.privateKeyPassphrase' => 'סיסמה להגנת המפתח הפרטי',
			'sourceSetup.nfsMountPort' => 'יציאת TCP של שירות העיגון של NFS',
			'sourceSetup.nfsMountPortHelp' => 'ברירת מחדל: 20048',
			'sourceSetup.nfsUserId' => 'מזהה משתמש NFS ‏(AUTH_SYS)',
			'sourceSetup.nfsUserIdHelp' => 'ברירת מחדל: 1000. יש להשתמש במזהה המותר בהגדרות ייצוא NFS של ה־NAS.',
			'sourceSetup.nfsGroupId' => 'מזהה קבוצת NFS ‏(AUTH_SYS)',
			'sourceSetup.nfsGroupIdHelp' => 'ברירת מחדל: 1000. יש להשתמש במזהה הקבוצה המותר בהגדרות ייצוא NFS של ה־NAS.',
			'sourceSetup.nfsEncryption' => 'דרישת NFS מוצפן (RPC-with-TLS)',
			'sourceSetup.nfsEncryptionHelp' => 'מחייב TLS 1.3 עבור NFS ושירות העיגון. אם ה־NAS אינו תומך בכך, החיבור יידחה.',
			'sourceSetup.nfsTrustCertificate' => 'אישור CA או שרת NFS מותאם אישית (PEM, רשות)',
			'sourceSetup.nfsTrustHelp' => 'יש להשאיר ריק לאישורים שהתקן זה נותן בהם אמון. לפי הצורך, אפשר להוסיף אישור CA פרטי או אישור שרת בחתימה עצמית; השמות בו חייבים להתאים למארח שבכתובת NFS.',
			'sourceSetup.nfsTrustInvalid' => 'יש להשתמש באישור CA או שרת בפורמט PEM. אין לכלול מפתח פרטי.',
			'sourceSetup.addTrustCertificate' => 'הוספת אישור אמון מותאם אישית',
			'sourceSetup.replaceTrustCertificate' => 'החלפת האישור המותאם אישית השמור',
			'sourceSetup.nfsTlsHelp' => 'RPC-with-TLS משתמש ביציאות הרגילות של NFS ושירות העיגון, ודורש תמיכה ב־RFC 9289 מצד ה־NAS. נדרש TLS 1.3. שם המארח או כתובת ה־IP חייבים להתאים לאישור. מזהי AUTH_SYS UID/GID עדיין חלים בתוך הערוץ המוצפן.',
			'sourceSetup.clientCertificate' => 'אישור לקוח (רשות)',
			'sourceSetup.clientCertificateHelp' => 'מאפשר ל־NAS לאמת את הלקוח הזה; מזהי AUTH_SYS עדיין כפופים למדיניות הייצוא של ה־NAS.',
			'sourceSetup.savedIdentity' => 'ייעשה שימוש בפרטי הזיהוי השמורים של הלקוח.',
			'sourceSetup.replaceIdentity' => 'החלפת פרטי הזיהוי השמורים של הלקוח',
			'sourceSetup.chooseIdentity' => 'בחירת פרטי זיהוי לקוח בפורמט PKCS#12',
			'sourceSetup.identityPassphrase' => 'סיסמה להגנת פרטי הזיהוי של הלקוח',
			'sourceSetup.identityPassphraseHelp' => 'יש להשאיר ריק אם לקובץ אין סיסמה.',
			'sourceSetup.removeIdentity' => 'הסרת פרטי זיהוי לקוח שמורים',
			'sourceSetup.identityStorageHelp' => 'פרטי הזיהוי של הלקוחות נשמרים במאגר המוצפן של פרטי הגישה למקורות. כדי לשמור על פרטי הזיהוי הקיימים, יש להשאיר את הסעיף הזה ללא שינוי.',
			'sourceSetup.nfsLimitations' => 'NFSv3 לקריאה בלבד דרך TCP. ללא RPC-with-TLS, תעבורת NFS אינה מוצפנת. ה־NAS חייב לאפשר את מזהי AUTH_SYS שנבחרו ואת יציאות הלקוח שאינן דורשות הרשאות מיוחדות (אפשרות ייצוא שנקראת בדרך כלל “insecure”). אין תמיכה ב־NFSv4 וב־UDP.',
			'sourceSetup.nfsSetupHelp' => 'עזרה בהגדרת NFS',
			'sourceSetup.nfsSetupHint' => 'אם החיבור לא נפתח, כדאי לבדוק את ההגדרות האלה.',
			'sourceSetup.nfsSetupDetails' => 'יש להשתמש בייצוא NFSv3 דרך TCP. כשנדרשת הצפנה, גם שירות NFS וגם שירות העיגון חייבים לתמוך ב־RPC-with-TLS. אם התקן זה נותן אמון באישור השרת, יש להשאיר את האישור המותאם אישית ריק; אחרת, יש להוסיף אישור CA או אישור בחתימה עצמית של ה־NAS. שם האישור חייב להתאים למארח שבכתובת החיבור. אם ה־NAS דורש TLS הדדי, יש להוסיף את פרטי זיהוי הלקוח שלו בפורמט PKCS#12. לבסוף, יש לוודא שהייצוא מאפשר את מזהי AUTH_SYS UID/GID שהוגדרו ואת מדיניות יציאות הלקוח.',
			'sourceSetup.ftpHelp' => 'FTP משתמש במצב פסיבי. עבור FTP ללא הצפנה יש להשתמש ב־ftp://, להפעלת TLS באמצעות פקודה נפרדת ב־ftpes://, או ב־ftps:// עבור TLS (ביציאה 990, TLS מתחיל מיד; ביציאות אחרות הוא מופעל באמצעות פקודה נפרדת).',
			'sourceSetup.openSubtitles' => 'OpenSubtitles',
			'sourceSetup.subtitleSetup' => 'חיפוש כתוביות אופציונלי לקובצי וידאו עצמאיים.',
			'sourceSetup.apiKey' => 'מפתח API',
			'sourceSetup.optionalUsername' => 'שם המשתמש בחשבון (רשות)',
			'sourceSetup.optionalPassword' => 'סיסמת החשבון (רשות)',
			'sourceSetup.subtitlePrivacy' => 'אפשר לקבל מפתח API מ־opensubtitles.com. החיפוש שולח את שם הווידאו ואת מזהי IMDb/TMDB הזמינים, ולעולם לא את קובץ הווידאו. המפתח ופרטי החשבון האופציונליים נשמרים בהצפנה עם המקור הזה.',
			'sourceSetup.automaticMetadata' => 'אחזור אוטומטי של מטא־נתוני וידאו מקוונים',
			'sourceSetup.metadataPrivacy' => 'נשלחים רק שם היצירה, השנה ומספרי הפרקים מתוך שם הקובץ, או מזהה NFO. מדיה ופרטי גישה לעולם אינם נשלחים. לשדות NFO נשמרת עדיפות.',
			'sourceSetup.nfsEncryptionFailure' => 'עבור NFS מוצפן, יש לבדוק תמיכה ב־RFC 9289 וב־TLS 1.3 בשני שירותי ה־NAS, את שם האישור ואת מזהי UID/GID של הייצוא. PlezyNG לא ינסה שוב את החיבור הזה ללא הצפנה.',
			'sourceSetup.sourceConnecting' => 'מתבצע חיבור למקור',
			'sourceSetup.metadataSearchPrivacy' => 'חיפוש השם הזה נשלח ל־Trakt. נשלח רק השם שהוזן, ולא הווידאו או פרטי הגישה למקור.',
			'sourceSetup.chooseMatch' => 'בחירת תוצאה תואמת',
			'sourceSetup.metadataMatchHelp' => 'לפני הבחירה, יש לבדוק את השם והשנה. Trakt מקבל את שם החיפוש; הווידאו נשאר במקור שלו.',
			'sourceSetup.metadataNoMatches' => 'לא נמצאו שמות תואמים בחיפוש המקוון. כדאי לנסות שם אחר.',
			'sourceSetup.metadataSearch' => 'חיפוש מטא־נתונים מקוונים',
			'sourceSetup.metadataLoading' => 'מתבצע חיפוש מקוון של פרטי סרטים וסדרות…',
			'sourceSetup.metadataFromTrakt' => 'מטא־נתונים מקוונים מ־Trakt',
			'sourceSetup.metadataNoAutomaticMatch' => 'לא נמצאה התאמה אוטומטית לשם. יש לחפש את השם כדי לבחור תוצאה תואמת.',
			'sourceSetup.metadataFailed' => 'לא ניתן לטעון מטא־נתונים מקוונים. ההפעלה והפרטים המקומיים עדיין זמינים.',
			'sourceSetup.videoDetailsLoading' => 'פרטי הווידאו נטענים',
			'sourceSetup.subtitleKeyRequired' => 'נדרש מפתח API של OpenSubtitles',
			'sourceSetup.subtitleKeyHelp' => 'יש לערוך את מקור הקבצים הזה ולהוסיף מפתח API של OpenSubtitles בהגדרות הכתוביות האופציונליות שלו.',
			'sourceSetup.subtitleSearchFailed' => 'חיפוש הכתוביות נכשל. יש לבדוק את מפתח ה־API, את החיבור ואת הגישה לשירות.',
			'sourceSetup.subtitleApplyFailed' => 'לא ניתן להוריד או להחיל את הכתוביות האלה. יש לבדוק את החיבור ולנסות תוצאה אחרת.',
			'sourceSetup.subtitleSearch' => 'חיפוש ב־OpenSubtitles',
			'sourceSetup.subtitleSearchPrivacy' => 'החיפוש משתמש בשם ובמזהי IMDb/TMDB הזמינים. קובץ הווידאו נשאר במקור שלו. לפני הבחירה, יש לבדוק את השפה, את סימוני הכתוביות הכפויות או המותאמות לכבדי שמיעה, ואת הדירוג.',
			'sourceSetup.movieOrShow' => 'סרט או סדרה',
			'sourceSetup.subtitleTitleHint' => 'יש להזין שם כדי לצמצם את התוצאות',
			'sourceSetup.subtitleLanguage' => 'שפת הכתוביות',
			'sourceSetup.subtitleSearching' => 'מתבצע חיפוש ב־OpenSubtitles',
			'sourceSetup.subtitleNoMatches' => 'לא נמצאו כתוביות תואמות. כדאי לנסות שם או שפה אחרים.',
			'sourceSetup.downloadSubtitle' => 'הורדת כתוביות',
			'sourceSetup.subtitle' => 'כתוביות',
			'sourceSetup.nfsTlsRequired' => 'נדרש RPC-with-TLS',
			'sourceSetup.nfsUnencrypted' => 'NFS לא מוצפן',
			'sourceSetup.tlsEncrypted' => 'מוצפן באמצעות TLS',
			'sourceSetup.ftpPlain' => 'FTP לא מוצפן',
			'sourceSetup.sshPinned' => 'הצפנת SSH · מפתח המארח מקובע',
			'sourceSetup.smbEncrypted' => 'הצפנת SMB3 מופעלת',
			'sourceSetup.smbUnencrypted' => 'הצפנת SMB3 כבויה',
			'sourceSetup.httpUnencrypted' => 'HTTP ללא הצפנת תעבורה',
			_ => null,
		} ?? switch (path) {
			'sourceSetup.checkEndpointSecurity' => 'יש לבדוק את אבטחת כתובת החיבור',
			'sourceSetup.fieldRequired' => ({required Object label}) => 'חובה למלא את השדה ${label}.',
			'sourceSetup.integerRange' => ({required Object label, required Object min, required Object max}) => 'יש להזין עבור ${label} ערך בין ${min} ל־${max}.',
			'sourceSetup.replaceFile' => ({required Object name}) => 'החלפת ${name}',
			'sourceSetup.selectedIdentity' => ({required Object name}) => 'פרטי זיהוי הלקוח שנבחרו: ${name}',
			'sourceSetup.subtitleRating' => ({required Object rating}) => 'דירוג ${rating}',
			'sourceSetup.subtitleDownloading' => ({required Object title}) => 'הכתוביות בהורדה: ${title}',
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
			'games.touchSetupHint' => 'Moonlight’s controller settings support position and opacity changes. During a Steam stream, open the stream menu to toggle its controller. Bluetooth or USB input is also supported.',
			'games.addGame' => 'Add game shortcut',
			'games.gameName' => 'Game name',
			'games.gameId' => 'Host application ID',
			'games.invalidGame' => 'Enter a game name and a positive numeric host application ID.',
			'games.wake' => 'Wake computer',
			'games.wakeSent' => 'Wake request sent. The computer must support Wake-on-LAN on this network.',
			'games.mac' => 'MAC address (optional)',
			'games.help' => 'Games help',
			'games.helpBody' => 'Enable Games for your profile, choose a computer and approve the first connection. Sunshine-compatible hosts load their app list into the game grid. On Android, Steam pairing opens Big Picture inside PlezyNG; saved Steam app-ID shortcuts launch directly. Steam pairing does not grant access to a private account library.\n\nBoth Android engines include touch controls and gamepad input. Other native platforms and the Pyrowave decoder are still in development.\n\nPairing requires the host’s approval. Sunshine QR codes open its PIN page without carrying credentials. For access away from home, use the computer’s VPN address. Automatic discovery normally stays on the local network.\n\nDisconnecting leaves the game running on the computer.',
			'games.cancel' => 'Cancel',
			'games.scanning' => 'Looking for computers…',
			'games.saveShortcut' => 'Save shortcut',
			'games.manualHint' => 'For Moonlight use the host’s GameStream HTTP port (usually 47989), not its web settings port. Steam normally advertises on 27036.',
			'games.engineUnavailable' => 'In-app streaming is not available here yet',
			'games.nativeEnginePending' => 'This build does not include a streaming engine for this platform. You can save the computer, but it cannot play here yet.',
			'games.steamEnginePending' => 'This build does not include the embedded Steam engine. Android builds with Games enabled bundle device pairing and in-app H.264/HEVC playback. Other platforms and Pyrowave remain under development.',
			'games.steamBetaTitle' => 'Steam beta · Pyrowave',
			'games.steamBetaDescription' => 'Steam’s Pyrowave beta is a GPU-decoded video codec. It is not enabled in this build: Steam packet framing and GPU presentation still need integration and host validation. The embedded Android Steam player currently requests H.264 or HEVC.',
			'games.steamLibrary' => 'Steam library',
			'games.connecting' => 'Connecting…',
			'games.disconnect' => 'Disconnect',
			'games.streamControls' => 'Stream controls',
			'games.steamPairInstructions' => 'Enter this code in Steam’s Remote Play pairing prompt on your computer. Keep this screen open until Steam approves.',
			'games.steamLibraryHint' => 'Steam device pairing opens its library inside the stream. Add a shortcut with a Steam app ID for direct launch. Importing a private account library as game cards requires a separate authenticated catalog connection.',
			_ => null,
		};
	}
}
