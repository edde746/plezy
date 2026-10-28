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
class TranslationsFa extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsFa({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.fa,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <fa>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsFa _root = this; // ignore: unused_field

	@override 
	TranslationsFa $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsFa(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$fa app = _Translations$app$fa._(_root);
	@override late final _Translations$appIcon$fa appIcon = _Translations$appIcon$fa._(_root);
	@override late final _Translations$auth$fa auth = _Translations$auth$fa._(_root);
	@override late final _Translations$common$fa common = _Translations$common$fa._(_root);
	@override late final _Translations$screens$fa screens = _Translations$screens$fa._(_root);
	@override late final _Translations$update$fa update = _Translations$update$fa._(_root);
	@override late final _Translations$settings$fa settings = _Translations$settings$fa._(_root);
	@override late final _Translations$themeEditor$fa themeEditor = _Translations$themeEditor$fa._(_root);
	@override late final _Translations$search$fa search = _Translations$search$fa._(_root);
	@override late final _Translations$hotkeys$fa hotkeys = _Translations$hotkeys$fa._(_root);
	@override late final _Translations$fileInfo$fa fileInfo = _Translations$fileInfo$fa._(_root);
	@override late final _Translations$mediaMenu$fa mediaMenu = _Translations$mediaMenu$fa._(_root);
	@override late final _Translations$rateSheet$fa rateSheet = _Translations$rateSheet$fa._(_root);
	@override late final _Translations$accessibility$fa accessibility = _Translations$accessibility$fa._(_root);
	@override late final _Translations$tooltips$fa tooltips = _Translations$tooltips$fa._(_root);
	@override late final _Translations$audioTracks$fa audioTracks = _Translations$audioTracks$fa._(_root);
	@override late final _Translations$videoControls$fa videoControls = _Translations$videoControls$fa._(_root);
	@override late final _Translations$messages$fa messages = _Translations$messages$fa._(_root);
	@override late final _Translations$subtitlingStyling$fa subtitlingStyling = _Translations$subtitlingStyling$fa._(_root);
	@override late final _Translations$mpvConfig$fa mpvConfig = _Translations$mpvConfig$fa._(_root);
	@override late final _Translations$dialog$fa dialog = _Translations$dialog$fa._(_root);
	@override late final _Translations$profiles$fa profiles = _Translations$profiles$fa._(_root);
	@override late final _Translations$connections$fa connections = _Translations$connections$fa._(_root);
	@override late final _Translations$accountPreferences$fa accountPreferences = _Translations$accountPreferences$fa._(_root);
	@override late final _Translations$discover$fa discover = _Translations$discover$fa._(_root);
	@override late final _Translations$errors$fa errors = _Translations$errors$fa._(_root);
	@override late final _Translations$libraries$fa libraries = _Translations$libraries$fa._(_root);
	@override late final _Translations$about$fa about = _Translations$about$fa._(_root);
	@override late final _Translations$serverSelection$fa serverSelection = _Translations$serverSelection$fa._(_root);
	@override late final _Translations$hubDetail$fa hubDetail = _Translations$hubDetail$fa._(_root);
	@override late final _Translations$logs$fa logs = _Translations$logs$fa._(_root);
	@override late final _Translations$startup$fa startup = _Translations$startup$fa._(_root);
	@override late final _Translations$licenses$fa licenses = _Translations$licenses$fa._(_root);
	@override late final _Translations$navigation$fa navigation = _Translations$navigation$fa._(_root);
	@override late final _Translations$explore$fa explore = _Translations$explore$fa._(_root);
	@override late final _Translations$liveTv$fa liveTv = _Translations$liveTv$fa._(_root);
	@override late final _Translations$collections$fa collections = _Translations$collections$fa._(_root);
	@override late final _Translations$playlists$fa playlists = _Translations$playlists$fa._(_root);
	@override late final _Translations$music$fa music = _Translations$music$fa._(_root);
	@override late final _Translations$watchTogether$fa watchTogether = _Translations$watchTogether$fa._(_root);
	@override late final _Translations$downloads$fa downloads = _Translations$downloads$fa._(_root);
	@override late final _Translations$shaders$fa shaders = _Translations$shaders$fa._(_root);
	@override late final _Translations$companionRemote$fa companionRemote = _Translations$companionRemote$fa._(_root);
	@override late final _Translations$videoSettings$fa videoSettings = _Translations$videoSettings$fa._(_root);
	@override late final _Translations$performanceOverlay$fa performanceOverlay = _Translations$performanceOverlay$fa._(_root);
	@override late final _Translations$externalPlayer$fa externalPlayer = _Translations$externalPlayer$fa._(_root);
	@override late final _Translations$metadataEdit$fa metadataEdit = _Translations$metadataEdit$fa._(_root);
	@override late final _Translations$matchScreen$fa matchScreen = _Translations$matchScreen$fa._(_root);
	@override late final _Translations$serverTasks$fa serverTasks = _Translations$serverTasks$fa._(_root);
	@override late final _Translations$trakt$fa trakt = _Translations$trakt$fa._(_root);
	@override late final _Translations$seerr$fa seerr = _Translations$seerr$fa._(_root);
	@override late final _Translations$services$fa services = _Translations$services$fa._(_root);
	@override late final _Translations$addServer$fa addServer = _Translations$addServer$fa._(_root);
	@override late final _Translations$cast$fa cast = _Translations$cast$fa._(_root);
	@override late final _Translations$automation$fa automation = _Translations$automation$fa._(_root);
	@override late final _Translations$notifications$fa notifications = _Translations$notifications$fa._(_root);
	@override late final _Translations$appAccess$fa appAccess = _Translations$appAccess$fa._(_root);
	@override late final _Translations$detail$fa detail = _Translations$detail$fa._(_root);
	@override late final _Translations$watchLink$fa watchLink = _Translations$watchLink$fa._(_root);
	@override late final _Translations$homeLayout$fa homeLayout = _Translations$homeLayout$fa._(_root);
	@override late final _Translations$platform$fa platform = _Translations$platform$fa._(_root);
	@override late final _Translations$universalMedia$fa universalMedia = _Translations$universalMedia$fa._(_root);
	@override late final _Translations$fileSources$fa fileSources = _Translations$fileSources$fa._(_root);
	@override late final _Translations$lending$fa lending = _Translations$lending$fa._(_root);
	@override late final _Translations$audiobook$fa audiobook = _Translations$audiobook$fa._(_root);
	@override late final _Translations$sourceSetup$fa sourceSetup = _Translations$sourceSetup$fa._(_root);
	@override late final _Translations$comics$fa comics = _Translations$comics$fa._(_root);
	@override late final _Translations$games$fa games = _Translations$games$fa._(_root);
	@override late final _Translations$deepLinks$fa deepLinks = _Translations$deepLinks$fa._(_root);
	@override late final _Translations$householdSetup$fa householdSetup = _Translations$householdSetup$fa._(_root);
	@override late final _Translations$issueReport$fa issueReport = _Translations$issueReport$fa._(_root);
}

// Path: app
class _Translations$app$fa extends Translations$app$en {
	_Translations$app$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: appIcon
class _Translations$appIcon$fa extends Translations$appIcon$en {
	_Translations$appIcon$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'آیکون اپ';
	@override String get defaultIcon => 'پیشفرض';
	@override String get current => 'آیکون فعلی';
	@override String get locked => 'دسترسی طول عمر مورد نیاز';
	@override String get lockedHint => '7-روز آزمایشی خود را شروع کنید یا برای مدت طولانی PlezyNG را برای استفاده از آیکون های جایگزین باز کنید.';
	@override String get changeFailed => 'امکان تغییر آیکون اپلیکیشن';
	@override String get launcherHint => 'آیکون جدید در صفحه اصلی شما ظاهر می شود هنگامی که شما PlezyNG را ترک می کنید.';
	@override String get tvLauncherHint => 'بنر جدید پس از ترک PlezyNG ظاهر می شود. Android TV می تواند تا زمانی که تلویزیون دوباره راه اندازی شود، به نمایش قدیمی ادامه دهد.';
	@override late final _Translations$appIcon$names$fa names = _Translations$appIcon$names$fa._(_root);
	@override String get description => 'آیکون نمایش داده شده توسط راه اندازی دستگاه خود را انتخاب کنید پیش بینی ها نشان می دهد که چگونه هر گزینه به نظر می رسد.';
}

// Path: auth
class _Translations$auth$fa extends Translations$auth$en {
	_Translations$auth$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'ثبت نام با شماره Plex';
	@override String get showQRCode => 'کد QR را نشان دهید';
	@override String get authenticate => 'معتبر';
	@override String get authenticationTimeout => 'تاریخ ثبت نام به پایان رسیده است لطفا دوباره امتحان کنید';
	@override String get scanQRToSignIn => 'این کد QR را برای ثبت نام در';
	@override String get waitingForAuth => 'منتظر صدور گواهینامه ... از مرورگر خود وارد شوید.';
	@override String get useBrowser => 'استفاده از مرورگر';
	@override String get or => 'یا';
	@override String connectToMediaBrowser({required Object product}) => 'تماس با ${product}';
	@override String get quickConnect => 'اتصال سریع';
	@override String get useQuickConnect => 'از اتصال سریع استفاده کنید';
	@override String get quickConnectInstructions => 'اتصال سریع را در Jellyfin باز کنید و این کد را وارد کنید.';
	@override String get quickConnectWaiting => 'منتظر تصویب...';
	@override String get quickConnectCancel => 'لغو کردن';
	@override String get quickConnectExpired => 'مهلت اتصال سریع تمام شد. دوباره تلاش کنید.';
	@override String get localDataRecoveryRequired => 'PlezyNG نتوانست اطلاعات ورود محلی و داده‌های پخشِ در انتظار را به‌طور ایمن بازیابی کند. لطفاً دوباره وارد حساب شوید.';
	@override String get pinCheckRejected => 'چک PIN Plex رد شد';
	@override String get connectToDirectPlex => 'اتصال به سرور محلی Plex';
}

// Path: common
class _Translations$common$fa extends Translations$common$en {
	_Translations$common$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'لغو کردن';
	@override String get save => 'ذخیره';
	@override String get close => 'بستن';
	@override String get closeMiniPlayer => 'بازی مینی نزدیک';
	@override String get closeWorkspaceWindow => 'پنجره نزدیک';
	@override String get returnToFullView => 'بازگشت به دید کامل';
	@override String get manageMediaSessions => 'مدیریت جلسات رسانه ای';
	@override String get hideMediaSessions => 'جلسات رسانه ای پنهان';
	@override String get mediaSessions => 'جلسات رسانه ای';
	@override String get mediaSessionsHint => 'پارک پنجره خود را پنهان می کند اما آن را باز نگه می دارد بازگشت آن را در نمایش کامل باز می کند؛ نزدیک آن را به پایان می رساند.';
	@override String get sessionInWorkspace => 'در کارگاه';
	@override String get sessionParked => 'پارکینگ';
	@override String get sessionFullscreen => 'صفحه نمایش کامل';
	@override String get switchToNextWindow => 'تعویض با پنجره بعدی';
	@override String get moveWindow => 'حرکت پنجره';
	@override String get finishMovingWindow => 'پایان پنجره حرکت';
	@override String get moveWindowHint => 'فشار طولانی و کشیدن پنجره برای حرکت آن. این کنترل همچنین اجازه می دهد تا حرکت کلید شلیک.';
	@override String get movingWindowHelp => 'کشیدن به حرکت · تنظیم کلیدهای کشیدن · وارد کردن ذخایر · فرار لغو';
	@override String get resizeWindow => 'بازسازی پنجره';
	@override String get resizeWindowHint => 'این دستبند را بردارید یا از کلیدهای گلوله برای بازسازی پنجره استفاده کنید.';
	@override String get workspaceWindowHint => 'از کنترل حرکت یا فشار طولانی و کشیدن برای حرکت استفاده کنید.';
	@override String get workspacePaneHint => 'این پانل را انتخاب کنید تا روی آن تمرکز کند.استفاده از کنترل صفحه نمایش کامل برای گسترش.';
	@override String workspaceWindowLabel({required Object title}) => 'پنجره جلسه: ${title}';
	@override String get workspaceTitleHint => 'برای حرکت، نوار عنوان را کشید؛ از دکمه صفحه نمایش کامل برای گسترش استفاده کنید.';
	@override String get moveToSessionTray => 'حرکت به جلسه تری';
	@override String get moveToSessionTrayHint => 'این جلسه را بدون نشان دادن پنجره در دسترس قرار دهید.';
	@override String get closeSessionHint => 'این پنجره را ببندید و جلسه آن به پایان می رسد.';
	@override String get sideBySideLayout => 'سوئیچ به ترتیب جانبی';
	@override String get floatingWindows => 'سوئیچ برای پرواز پنجره ها';
	@override String get clear => 'روشن';
	@override String get reset => 'بازسازی';
	@override String get later => 'بعداً';
	@override String get submit => 'تایید';
	@override String get confirm => 'تایید';
	@override String get retry => 'تلاش مجدد';
	@override String get logout => 'ثبت نام کنید';
	@override String get unknown => 'ناشناخته';
	@override String get refresh => 'به‌روز‌رسانی';
	@override String get yes => 'بلی';
	@override String get no => 'خیر';
	@override String get delete => 'حذف';
	@override String get edit => 'ویرایش';
	@override String get shuffle => 'پخش تصادفی';
	@override String get addTo => 'اضافه کردن به...';
	@override String get createNew => 'ایجاد جدید';
	@override String get connect => 'اتصال';
	@override String get disconnect => 'قطع اتصال';
	@override String get play => 'اجرا کردن';
	@override String get pause => 'مکث';
	@override String get resume => 'ادامهٔ پخش';
	@override String get error => 'خطا';
	@override String get search => 'جستجو کردن';
	@override String get home => 'خانه';
	@override String get back => 'بازگشت';
	@override String get settings => 'تنظیمات';
	@override String get mute => 'سکوت';
	@override String get ok => 'خوب';
	@override String get off => 'خاموش';
	@override String get options => 'گزینه ها';
	@override String seasonNumber({required Object number}) => 'فصل ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'قسمت ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'فصل ${number}';
	@override String get reconnect => 'دوباره متصل';
	@override String get viewAll => 'مشاهده همه';
	@override String get checkingNetwork => 'بررسی شبکه...';
	@override String get loadingServers => 'سرورهای بارگذاری...';
	@override String get connectingToServers => 'اتصال به سرورها';
	@override String get startingOfflineMode => 'در حالت offline...';
	@override String get loading => 'بارگذاری...';
	@override String get fullscreen => 'تمام صفحه';
	@override String get exitFullscreen => 'خروجی صفحه نمایش کامل';
	@override String get pressBackAgainToExit => 'دوباره فشار دهید تا خارج شوید.';
	@override late final _Translations$common$ratingSource$fa ratingSource = _Translations$common$ratingSource$fa._(_root);
	@override String get notAvailable => 'N / A';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
	@override late final _Translations$common$mediaKind$fa mediaKind = _Translations$common$mediaKind$fa._(_root);
}

// Path: screens
class _Translations$screens$fa extends Translations$screens$en {
	_Translations$screens$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'مجوز';
	@override String get switchProfile => 'سوئیچ پروفایل';
	@override String get subtitleStyling => 'زیرنویس سبک';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'گزارش ها';
}

// Path: update
class _Translations$update$fa extends Translations$update$en {
	_Translations$update$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get available => 'Update در دسترس';
	@override String versionAvailable({required Object version}) => 'نسخه ${version} در دسترس است';
	@override String currentVersion({required Object version}) => 'در حال حاضر: ${version}';
	@override String get skipVersion => 'دانلود این نسخه';
	@override String get viewRelease => 'مشاهده انتشارات';
	@override String get latestVersion => 'شما در آخرین نسخه هستید';
	@override String get checkFailed => 'نتوانستیم به روز رسانی ها را بررسی کنیم';
}

// Path: settings
class _Translations$settings$fa extends Translations$settings$en {
	_Translations$settings$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'تنظیمات';
	@override String get supportDeveloper => 'پشتیبانی PlezyNG';
	@override String get supportDeveloperDescription => 'کمک های مالی برای حمایت از توسعه';
	@override String get lifetimeAccess => 'PlezyNG دسترسی طول عمر';
	@override String get language => 'زبان';
	@override String get theme => 'قالب';
	@override String get appearance => 'ظهور';
	@override String get detailPage => 'جزئیات صفحه';
	@override String get themeSongsEnabled => 'دانلود آهنگ های موضوعی';
	@override String get themeSongsEnabledDescription => 'پخش آهنگ های موضوعی در دسترس در حالی که مشاهده جزئیات رسانه ها.';
	@override String get themeSongVolume => 'موضوع آهنگ حجم';
	@override String get videoPlayback => 'ویدئو Playback';
	@override String get videoPlaybackDescription => 'تنظیم رفتار playback';
	@override String get advanced => 'پیشرفته';
	@override String get episodePosterMode => 'برچسب های ارشیو Poster Style';
	@override String get seriesPoster => 'سری پوستر';
	@override String get seasonPoster => 'فصل پوستر';
	@override String get episodeThumbnail => 'تامبیا';
	@override String get showHeroSectionDescription => 'صفحه نمایش محتوای کارواش در صفحه نمایش خانگی';
	@override String get secondsLabel => 'ثانیه ها';
	@override String get minutesLabel => 'دقیقه ها';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'م';
	@override String durationHint({required Object min, required Object max}) => 'مقدار را وارد کنید (${min}-${max})';
	@override String get systemTheme => 'سیستم';
	@override String get lightTheme => 'نور';
	@override String get darkTheme => 'تاریکی';
	@override String get oledTheme => 'OLED';
	@override String get emberTheme => 'مرد';
	@override String get glacierTheme => 'یخ';
	@override String get forestTheme => 'جنگل';
	@override String get plumTheme => 'آلویی';
	@override String get paperTheme => 'کاغذ';
	@override String get libraryDensity => 'تراکم کتابخانه';
	@override String get displayScale => 'نمایش مقیاس';
	@override String get compact => 'کمپیکت';
	@override String get comfortable => 'راحتی';
	@override String get gridSpacing => 'شبکه فضایی';
	@override String get gridSpacingTight => 'تیتا';
	@override String get gridSpacingNormal => 'طبیعی';
	@override String get gridSpacingSpacious => 'فضایی';
	@override String get tvCornerSpotlightBackdrop => 'زاویه Spotlight Backdrop';
	@override String get tvCornerSpotlightBackdropDescription => 'نمایش آثار هنری در گوشه سمت راست بالا به جای پر کردن صفحه نمایش';
	@override String get viewMode => 'دیدن مد';
	@override String get gridView => 'شبکه';
	@override String get listView => 'لیست';
	@override String get showHeroSection => 'نمایش قسمت قهرمان';
	@override String get showHomeBackdrop => 'خانه » آرشیوهای برچسب: Backdrop Artwork';
	@override String get showHomeBackdropDescription => 'نمایش آثار هنری بزرگ در پشت خطوط خانگی';
	@override String get contentScreensaverEnabled => 'محتوای صفحه نمایش';
	@override String get contentScreensaverEnabledDescription => 'نمایش آثار هنری با صفحه نمایش کامل پس از آن که اپلیکیشن idle بوده است';
	@override String get contentScreensaverDelay => 'صفحه نمایش پس از شروع';
	@override String get contentScreensaverLibraries => 'صفحه نمایش کتابخانه ها';
	@override String get contentScreensaverLibrariesDescription => 'انتخاب کنید که کدام کتابخانه ها کار هنری ذخیره صفحه نمایش را ارائه می دهند.اگر هیچ کدام از آنها انتخاب نشده است، کار هنری از تمام کتابخانه ها استفاده می شود.';
	@override String get contentScreensaverAllLibraries => 'تمام کتابخانه‌ها';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} کتابخانه های انتخاب شده';
	@override String get contentScreensaverNoLibraries => 'هیچ کتابخانه رسانه ای متصل در دسترس نیست.';
	@override String get contentScreensaverDismissHint => 'هر دکمه یا دکمه را فشار دهید تا حذف شود.';
	@override String get newEpisodeNotifications => 'خبرهای جدید قسمت';
	@override String get newEpisodeNotificationsDescription => 'هشدار هنگامی که یک قسمت جدید به یک نمایش اضافه می شود که شما در آن قرار گرفته اید. چک در حالی که Plezy باز است.';
	@override String get continueWatchingRowSize => 'ادامه مشاهده اندازه خط';
	@override String continueWatchingRowSizeValue({required Object label}) => '${label} کارت';
	@override String get rowSizeCompact => 'کمپیکت';
	@override String get rowSizeStandard => 'استاندارد';
	@override String get rowSizeLarge => 'بزرگ';
	@override String get continueWatchingAction => 'ادامه فعالیت های نظارت';
	@override String get continueWatchingPlay => 'اجرا کردن';
	@override String get continueWatchingDetails => 'جزئیات باز';
	@override String get episodeAction => 'قسمت اکشن';
	@override String get episodePlay => 'اجرا کردن';
	@override String get episodeDetails => 'جزئیات باز';
	@override String get useGlobalHubs => 'استفاده از Home Layout';
	@override String get useGlobalHubsDescription => 'صفحه اصلی » کتابخانه » کتابخانه » کتابخانه » کتابخانه » کتابخانه » کتابخانه » کتابخانه » کتابخانه » کتابخانه » کتابخانه » کتابخانه';
	@override String get showServerNameOnHubs => 'نمایش نام سرور در Hubs';
	@override String get showServerNameOnHubsDescription => 'همیشه نام سرورها را در عنوان های هاب نشان دهید.';
	@override String get groupLibrariesByServer => 'کتابخانه های گروهی توسط سرور';
	@override String get groupLibrariesByServerDescription => 'کتابخانه های گروهی در زیر هر سرور رسانه ای';
	@override String get alwaysKeepSidebarOpen => 'همیشه دایره باز نگه دارید';
	@override String get alwaysKeepSidebarOpenDescription => 'صفحه پشتی گسترش می یابد و محدوده محتوا به حالت مناسب تنظیم می شود.';
	@override String get showUnwatchedCount => 'نمایش نامنظری';
	@override String get showUnwatchedCountDescription => 'نمایش قسمت های ناشناخته شمارش در نمایش ها و فصل ها';
	@override String get showWatchedIndicators => 'نمایش شاخص های مشاهده شده';
	@override String get showWatchedIndicatorsDescription => 'نشان دادن یک چک بر روی فیلم ها، نمایش ها و قسمت های تماشا شده';
	@override String get showEpisodeNumberOnCards => 'نمایش قسمت شماره در نقشه ها';
	@override String get showEpisodeNumberOnCardsDescription => 'نمایش فصل و شماره قسمت در کارت های قسمت';
	@override String get showSeasonPostersOnTabs => 'نمایش پوستر های فصل در Tabs';
	@override String get showSeasonPostersOnTabsDescription => 'نمایش پوستر هر فصل در بالای برچسب آن';
	@override String get tvFullCardLayout => 'کارت های تلویزیونی کامل';
	@override String get tvFullCardLayoutDescription => 'استفاده از کارت های تلویزیونی فقط با نام های بازیگر';
	@override String get focusGlow => 'تمرکز گلو';
	@override String get focusGlowDescription => 'یک نور نرم را در اطراف کارت تمرکز کنید.';
	@override String get visualEffects => 'اثرات بصری';
	@override String get visualEffectsAuto => 'خودکار';
	@override String get visualEffectsAutoDescription => 'کاهش اثر به طور خودکار بر روی دستگاه های کم قدرت';
	@override String get visualEffectsFull => 'کامل';
	@override String get visualEffectsReduced => 'کاهش یافته';
	@override String get visualEffectsReducedDescription => 'کمتر انیمیشن ها و هنرهای با رزولوشن پایین تر';
	@override String get hideSpoilers => 'مخفی کردن اسپویلرها برای قسمت های ناشناخته';
	@override String get hideSpoilersDescription => 'خلاصه ای و توصیفات برای قسمت های ناشناخته';
	@override String get playerBackend => 'بازی Backend';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'دکوراسیون سخت افزاری';
	@override String get hardwareDecodingDescription => 'استفاده از سرعت سخت افزاری هنگامی که در دسترس';
	@override String get playbackBuffer => 'بایگانی برچسب ها: playback buffer';
	@override String get playbackBufferAuto => 'اتومبیل ( توصیه می شود )';
	@override String get playbackBufferLarge => 'بزرگ';
	@override String get playbackBufferExtraLarge => 'فوق العاده بزرگ';
	@override String get playbackBufferDescription => 'بوفری بیشتر در برابر اتصالات نامناسب محدود به اندازه بوفری.';
	@override String get streamBufferSize => 'حجم بوفری';
	@override String streamBufferSizeValue({required Object size}) => '${size} مگابایت';
	@override String get streamBufferSizeDescription => 'چه مقدار ویدئو برای بارگذاری به جلو در هنگام پخش مستقیم. ترانسکود ها در خروجی ترانسکود خود سرور متوقف می شوند. 0 = اتوماتیک';
	@override String get streamBufferSizeExoNote => 'جایگزین کردن Playback Buffer در هنگام تنظیم، در نیمی از محدودیت حافظه برنامه';
	@override String get streamBufferMegabytes => 'مگابیت ها';
	@override String get defaultQualityTitle => 'کیفیت پیش فرض';
	@override String get cellularQualityTitle => 'کیفیت پیش فرض در سلول ها';
	@override String get remoteQualityTitle => 'کیفیت پخش از راه دور';
	@override String get remoteQualitySameAsDefault => 'همانند کیفیت پیش فرض';
	@override String get cellularQualitySameAsDefault => 'همانند کیفیت پیش فرض';
	@override String get directPlayCoveredQuality => 'بازی ویدئوهای کوچک تر با کیفیت اصلی';
	@override String get directPlayCoveredQualityDescription => 'پخش مستقیم ویدئوها در محدوده کیفیت به جای آنکه آنها را رمزگذاری کنند';
	@override String get videoCodecs => 'ویدئو کدک';
	@override String get videoCodecsDescription => 'کدک های غیرقابل بررسی توسط سرور رمزگذاری می شوند';
	@override String get videoCodecsAlwaysAccepted => 'همیشه پذیرفته شده';
	@override String get musicQualityTitle => 'کیفیت آهنگ';
	@override String get subtitleStyling => 'زیرنویس سبک';
	@override String get subtitleStylingDescription => 'ظاهر زیرنویس را مشخص کنید';
	@override String get smallSkipDuration => 'مدت زمان اسکایک';
	@override String get largeSkipDuration => 'مدت زمان اسکایپ';
	@override String get rewindOnResume => 'بازگشت به خلاصه';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(seconds,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} ثانیه',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} ثانیه',
	);
	@override String get defaultSleepTimer => 'زمان خواب پیش فرض';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(minutes,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} دقیقه',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} دقیقه',
	);
	@override String get rememberTrackSelections => 'به یاد داشته باشید انتخاب مسیر در هر نمایش / فیلم';
	@override String get chooseTracksBeforePlayback => 'صدا و زیرنویس ها را قبل از پخش انتخاب کنید.';
	@override String get chooseTracksBeforePlaybackDescription => 'صدا منبع و زیرنویس را قبل از شروع هر ویدئو انتخاب کنید.';
	@override String get alwaysShowSubtitlesOnDevice => 'همیشه زیرنویس ها را در این دستگاه نشان دهید';
	@override String get alwaysShowSubtitlesOnDeviceDescription => 'هنگامی که سرور هیچ زیرنویس انتخاب نشده است، یک ردیف را به صورت محلی انتخاب کنید.این هرگز ترجیحات سرور را تغییر نمی دهد.';
	@override String get autoDownloadPreferredSubtitle => 'فیتچ از دست دادن زیرنویس های زبان مورد علاقه';
	@override String get autoDownloadPreferredSubtitleDescription => 'یک زیرنویس در دسترس را در زبان مورد علاقه خود به صورت محلی انتخاب کنید.اگر هیچ کدام وجود ندارد، از سرور بخواهید که یک زیرنویس را در هنگام پشتیبانی دریافت کند.';
	@override String get rememberTrackSelectionsDescription => 'ذخیره کردن گزینه های صوتی و زیرنویس با نمایش یا فیلم در این دستگاه';
	@override String get rememberTrackSelectionsBackendRule => 'در محل کار با Plex، Jellyfin و Emby؛ Plex و Jellyfin نیز می تواند انتخاب ها را در سرور ذخیره کند.';
	@override String get followServerTrackSelections => 'استفاده از گزینه های ردیابی سرور برای هر قسمت';
	@override String get followServerTrackSelectionsDescription => 'در تغییر قسمت، صدا و زیرنویس های انتخاب شده را در سرور اعمال کنید به جای اینکه بر روی گزینه فعلی حرکت کنید.';
	@override String get resumeMusicOnLaunch => 'یادآوری جلسه موسیقی';
	@override String get resumeMusicOnLaunchDescription => 'باز کردن آخرین آهنگ استراحت که در آن آن را ترک زمانی که برنامه شروع می شود';
	@override String get showChapterMarkersOnTimeline => 'نمایش شاخص ها در جستجو بار';
	@override String get showChapterMarkersOnTimelineDescription => 'دسته بندی نوار جستجو در مرزهای فصل';
	@override String get specialsOrdering => 'مشخصات ویژه در قسمت';
	@override String get specialsOrderingDescription => 'کجا بازی های ویژه در یک ساعت نمایش';
	@override String get specialsOrderingServer => 'دستور سرور را دنبال کنید';
	@override String get specialsOrderingAirDate => 'تاریخ پرواز با هوا';
	@override String get specialsOrderingLast => 'بعد از فصل های عادی';
	@override String get clickVideoTogglesPlayback => 'روی ویدئو کلیک کنید تا بازی / استراحت کنید';
	@override String get clickVideoTogglesPlaybackDescription => 'ویدئو را کلیک کنید تا به جای نمایش کنترل ها، پخش/توقف کنید.';
	@override String get videoPlayerControls => 'کنترل ویدئو بازیکن';
	@override String get keyboardShortcuts => 'کلید کوتاه';
	@override String get keyboardShortcutsDescription => 'تگ های کوتاه صفحه کلید';
	@override String get videoPlayerNavigation => 'بازی های ویدئویی Navigation';
	@override String get videoPlayerNavigationDescription => 'استفاده از کلیدهای گلوله برای ناوبری کنترل های پخش ویدئو';
	@override String get watchTogetherRelay => 'با هم رله را ببینید';
	@override String get watchTogetherRelayDescription => 'پخش عمومی Open Watch Party مگر اینکه خودتان را تنظیم کنید';
	@override String get watchTogetherRelayHint => 'https://my-relay.example.com';
	@override String get watchTogetherRelayInvalid => 'نشانی پایهٔ معتبر HTTP یا HTTPS برای سرور واسط وارد کنید.';
	@override String get crashReporting => 'گزارش تصادف';
	@override String get crashReportingDescription => 'ارسال گزارش های تصادف برای کمک به بهبود برنامه';
	@override String get debugLogging => 'ثبت گزارش اشکال‌زدایی';
	@override String get debugLoggingDescription => 'امکان ثبت نام دقیق برای حل مشکلات';
	@override String get viewLogs => 'مشاهده Logs';
	@override String get viewLogsDescription => 'مشاهده نرم افزار Logs';
	@override String get clearImageCache => 'تصویر شفاف Cache';
	@override String get clearImageCacheDescription => 'آینه ها را می توان آهسته تر بارگذاری کرد تا دوباره دانلود شود.';
	@override String get clearImageCacheSuccess => 'تصویر کاسه با موفقیت پاک شد';
	@override String get resetSettings => 'تنظیمات مجدد';
	@override String get resetSettingsDescription => 'تنظیمات پیش فرض را بازگردانید.این نمی تواند غیر قابل اجرا باشد.';
	@override String get resetSettingsSuccess => 'تنظیمات با موفقیت بازگردانید';
	@override String get backup => 'پشتیبان';
	@override String get exportSettings => 'تنظیمات صادرات';
	@override String get exportSettingsDescription => 'ذخیره ترجیحات خود را به یک فایل';
	@override String get exportSettingsSuccess => 'تنظیمات صادرات';
	@override String get importSettings => 'تنظیمات واردات';
	@override String get importSettingsDescription => 'بازگرداندن ترجیحات از یک فایل';
	@override String get importSettingsConfirm => 'این کار جایگزین تنظیمات فعلی شما خواهد شد. ادامه دهید؟';
	@override String get importSettingsSuccess => 'تنظیمات وارداتی';
	@override String get importSettingsInvalidFile => 'این فایل معتبر نیست PlezyNG تنظیمات صادرات';
	@override String get importSettingsNoUser => 'قبل از واردات تنظیمات را وارد کنید';
	@override String get cloudBackup => 'Cloud پشتیبان';
	@override String get cloudBackupDescription => 'پشتیبان گیری تنظیمات قابل حمل به یک نقطه نهایی WebDAV بیش از HTTPS. اتصالات سرور و اعتبارات در این دستگاه باقی می ماند.';
	@override String get cloudBackupUrl => 'WebDAV JSON فایل URL';
	@override String get cloudBackupUsername => 'نام کاربری';
	@override String get cloudBackupPassword => 'گذرواژه';
	@override String get cloudBackupSaved => 'Cloud Backup مقصد نجات یافته است';
	@override String get cloudBackupNow => 'بازگشت به حال';
	@override String get cloudBackupComplete => 'تنظیمات پشتیبان بارگذاری شده';
	@override String get cloudBackupRestore => 'بازگرداندن Backup';
	@override String get cloudBackupRestoreConfirm => 'این جایگزین تنظیمات قابل حمل مطابقت در این دستگاه خواهد بود.';
	@override String get cloudBackupRestored => 'تنظیمات بازگردانده شده از پشتیبان ابر';
	@override String get shortcutsReset => 'تعویض کوتاه به تعویضات';
	@override String get resetShortcutsConfirm => 'این کار کوتاه کردن های سفارشی شما را با کوتاه کردن های پیش فرض جایگزین می کند.';
	@override String get about => 'درباره';
	@override String get aboutDescription => 'اپلیکیشن اطلاعات و مجوزها';
	@override String get updates => 'به روز رسانی';
	@override String get updateAvailable => 'Update در دسترس';
	@override String get checkForUpdates => 'بررسی به روز رسانی ها';
	@override String get autoCheckUpdatesOnStartup => 'به طور خودکار برای به روز رسانی در استارتاپ چک کنید';
	@override String get autoCheckUpdatesOnStartupDescription => 'هنگامی که یک به روز رسانی در راه اندازی در دسترس است، اطلاع دهید.';
	@override String get validationErrorEnterNumber => 'لطفا شماره معتبر را وارد کنید.';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'باید بین ${min} و ${max} ${unit} باشد.';
	@override String shortcutAlreadyAssigned({required Object action}) => 'کوتاه مدت در حال حاضر به ${action} اختصاص داده شده است';
	@override String shortcutUpdated({required Object action}) => 'بایگانی برچسب ها: ${action}';
	@override String get saveFailed => 'تغییراتی که نمی توانم انجام دهم، دوباره امتحان کنید.';
	@override String get autoPlayAndSkip => 'دانلود بازی Auto-Play & Skip';
	@override String get autoPlayNextEpisode => 'بازی اتوماتیک قسمت بعدی';
	@override String get autoPlayNextEpisodeDescription => 'قسمت بعدی را به صورت اتوماتیک شروع کنید، زمانی که یک قسمت به پایان می رسد.';
	@override String get shuffleStartsFromBeginning => 'شوفلی در ابتدا شروع کرد';
	@override String get shuffleStartsFromBeginningDescription => 'هر قسمت را در ابتدا شروع کنید، زمانی که به جای تکرار آن، در حال چرخش هستید.';
	@override String get plexCinemaPreRoll => 'استفاده از سرور سینما';
	@override String get plexCinemaPreRollDescription => 'بازی پیش نمایش Plex یا Jellyfin و Emby قبل از شروع یک فیلم.';
	@override String get playNextCountdown => 'دانلود بازی Next Countdown';
	@override String get playNextCountdownImmediate => 'بازی بلافاصله';
	@override String get skipIntroMode => 'کشتی وارد';
	@override String get skipIntroModeOffDescription => 'به طور معمول بدون یک دکمه اسکایپ بازی کنید';
	@override String get skipIntroModeButtonDescription => 'نشان دادن یک دکمه اسکایپ هنگامی که یک ورودی شروع می شود';
	@override String get skipIntroModeAutoDescription => 'به صورت اتوماتیک پس از تاخیر زیر وارد شوید.';
	@override String get skipCreditsMode => 'کپی اعتبارات';
	@override String get skipCreditsModeOffDescription => 'بازی اعتبارات به طور معمول بدون یک دکمه اسکایپ';
	@override String get skipCreditsModeButtonDescription => 'نمایش دکمه اسکایپ هنگامی که اعتبارات شروع می شود';
	@override String get skipCreditsModeAutoDescription => 'اعتبارات خودکار را بردارید و قسمت بعدی را بازی کنید';
	@override String get skipAdsMode => 'آگهی های اسکایپ';
	@override String get skipAdsModeOffDescription => 'پخش آگهی های شناسایی شده به طور معمول بدون یک دکمه اسکایپ';
	@override String get skipAdsModeButtonDescription => 'یک دکمه اسکایپ را هنگامی که Plex یک آگهی را تشخیص می دهد نشان دهید';
	@override String get skipAdsModeAutoDescription => 'حذف آگهی های شناسایی شده به طور خودکار پس از تاخیر زیر';
	@override String get musicPlayback => 'موسیقی Playback';
	@override String get musicSweetFades => 'شیرین فید';
	@override String get musicSweetFadesDescription => 'دانلود موسیقی در لبه های ردیابی زمانی که Plex دارای داده های صدا است.';
	@override String get skipMarkerModeOff => 'خاموش';
	@override String get skipMarkerModeButton => 'نمایش دکمه';
	@override String get skipMarkerModeAuto => 'اتوماتیک';
	@override String get forceSkipMarkerFallback => 'برچسب های ارشیو: Fallback Markers';
	@override String get forceSkipMarkerFallbackDescription => 'استفاده از الگوهای عنوان فصل حتی زمانی که Plex دارای برچسب ها است';
	@override String get theIntroDbFallback => 'استفاده از TheIntroDB به عنوان یک ورودی ورودی';
	@override String get theIntroDbFallbackDescription => 'از زمان بندی های جامعه فقط زمانی استفاده کنید که سرور دارای علامت ورودی نیست.';
	@override String get autoSkipDelay => 'اتومبیل اسکای دیر';
	@override String autoSkipDelayDescription({required Object seconds}) => 'انتظار ${seconds} ثانیه قبل از سوار شدن';
	@override String get introPattern => 'مدل مارکر';
	@override String get introPatternDescription => 'الگوی Regex برای مطابقت با مارک های ورودی در عنوان های فصل';
	@override String get creditsPattern => 'برچسب های ارشیو برچسب ها';
	@override String get creditsPatternDescription => 'الگوی Regex برای مطابقت با برچسب های اعتباری در عنوان های فصل';
	@override String get prerolls => 'پیشگویی';
	@override String get playPrerollsBeforeMovies => 'بازی قبل از فیلم ها';
	@override String get playPrerollsBeforeMoviesDescription => 'بازی یک کلیپ تصادفی از انتخاب زیر قبل از هر فیلم.';
	@override String get prerollLibrary => 'کتابخانه Preroll';
	@override String get prerollLibraryNotSet => 'نه تنظیم';
	@override String get prerollLibraryNoneFound => 'هیچ کتابخانه ای در سرورهای شما یافت نشد.';
	@override String get prerollSelection => 'انتخاب نمایندگان';
	@override String get prerollSelectionPickLibraryFirst => 'کتابخانه را اول انتخاب کنید';
	@override String get prerollSelectionNoneSelected => 'هیچ انتخابی انتخاب نشده';
	@override String prerollSelectionCount({required Object count}) => '${count} انتخاب شده';
	@override String get prerollItemPicker => 'انتخاب امتیازات';
	@override String get prerollItemPickerLoadFailed => 'نمی توانم از این کتابخانه استفاده کنم.';
	@override String get invalidRegex => 'اختلال در بیان عادی';
	@override String get regex => 'بیان منظم';
	@override String get downloads => 'بارگیری‌ها';
	@override String get downloadLocationDescription => 'انتخاب جایی که محتوای دانلود شده را ذخیره کنید';
	@override String get downloadLocationDefault => 'ذخیره سازی اپلیکیشن (App Storage)';
	@override String get downloadLocationCustom => 'مکان سفارشی';
	@override String get selectFolder => 'انتخاب پوشه';
	@override String get resetToDefault => 'بازگشت به حالت پیش فرض';
	@override String currentPath({required Object path}) => 'در حال حاضر: ${path}';
	@override String get downloadLocationChanged => 'دانلود محل تغییر';
	@override String get downloadLocationReset => 'دانلود مجدد مکان به حالت پیش فرض';
	@override String get downloadLocationInvalid => 'پوشه های انتخاب شده قابل نوشتن نیستند';
	@override String get downloadLocationPickerUnavailable => 'انتخاب پوشه در این دستگاه در دسترس نیست';
	@override String get downloadOnWifiOnly => 'دانلود در Wi-Fi فقط';
	@override String get downloadOnWifiOnlyDescription => 'جلوگیری از بارگذاری در هنگام استفاده از داده های سلولی';
	@override String get autoRemoveWatchedDownloads => 'حذف خودکار دانلود های مشاهده شده';
	@override String get autoRemoveWatchedDownloadsDescription => 'حذف دانلود های مشاهده شده به طور خودکار';
	@override String get autoDownloadContinueWatching => 'دانلود خودکار ادامه مطلب';
	@override String get autoDownloadContinueWatchingDescription => 'نگه داشتن آیتم ها در صفحه نمایش ادامه دانلود، و حذف آنها پس از آنها را ترک صفحه نمایش';
	@override String get downloadQuality => 'دانلود کیفیت';
	@override String get downloadQualityDescription => 'Plex یک کپی تبدیل شده را در محدوده دانلود آن آماده می کند. Jellyfin و Emby transcode در حالی که فایل دانلود می شود؛ انتقال متوقف شده ممکن است نیاز به راه اندازی مجدد داشته باشد.';
	@override String get askDownloadQualityEachTime => 'انتخاب کیفیت برای هر دانلود';
	@override String get askDownloadQualityEachTimeDescription => 'نمایش پیکر کیفیت قبل از هر دانلود ویدئو';
	@override String get cellularDownloadBlocked => 'دانلود ها در تلفن همراه مسدود شده است.استفاده از Wi-Fi یا تنظیمات را تغییر دهید.';
	@override String get maxVolume => 'بیشترین بلندی صدا';
	@override String get maxVolumeDescription => 'اجازهٔ تقویت صدا بیش از 100٪ برای رسانه‌های کم‌صدا';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'غنی غنی غنی';
	@override String get discordRichPresenceDescription => 'نشان دهید چه چیزی در Discord تماشا می کنید';
	@override String get services => 'خدمات';
	@override String get servicesDescription => 'اتصال Trakt، MyAnimeList، Seerr، و بیشتر';
	@override String get manageLibrariesDescription => 'کتابخانه ها را ذخیره و پنهان کنید';
	@override String get companionRemoteServer => 'سرورهای از راه دور';
	@override String get companionRemoteServerDescription => 'اجازه دهید دستگاه های تلفن همراه در شبکه شما این برنامه را کنترل کنند';
	@override String get companionRemoteServerStartFailed => 'نمی توانم سرور همراه را راه اندازی کنم.';
	@override String get companionRemoteServerStopFailed => 'نمی توانم سرور همراه را متوقف کنم.';
	@override String get autoPip => 'عکس های خودکار در تصویر';
	@override String get autoPipDescription => 'به طور خودکار تصویر-در-تصویر را وارد کنید هنگامی که برنامه را در طول پخش ترک می کنید';
	@override String get matchContentFrameRate => 'مسابقه محتوای فریم نرخ';
	@override String get matchContentFrameRateDescription => 'بازی نمایش نرخ بازسازی به محتوای ویدئویی';
	@override String get matchContentResolution => 'حل محتوای مسابقه';
	@override String get matchContentResolutionDescription => 'صفحه نمایش را به رزولوشن بومی ویدئو تغییر دهید تا تلویزیون شما به حالت بالا حرکت کند.منوها و زیرنویس ها نیز در هنگام پخش به حالت بالا حرکت می کنند.';
	@override String get matchRefreshRate => 'مسابقه تمیز کردن نرخ';
	@override String get matchRefreshRateDescription => 'بازی نمایش نرخ تازه در صفحه نمایش کامل';
	@override String get matchDynamicRange => 'بازی Dynamic Range';
	@override String get matchDynamicRangeDescription => 'HDR را برای محتوای HDR تغییر دهید و سپس به SDR برگردید.';
	@override String get displaySwitchDelay => 'نمایش سوئیچ دیر';
	@override String get tunneledPlayback => 'بازی های تونل';
	@override String get tunneledPlaybackDescription => 'استفاده از تونل ویدئویی غیرفعال می شود اگر پخش HDR ویدئو سیاه یا حرکت استوتری ها را نشان می دهد.';
	@override String get audioPassthrough => 'صدا درخشان';
	@override String get audioPassthroughDescription => 'ارسال صدا Dolby/DTS به گیرنده یا تلویزیون بدون رمزگذاری مجدد، حفظ صدا اطراف.';
	@override String get audioPassthroughDescriptionApple => 'از دکوراسیون دلفی بومی Apple برای دلفی دیجیتال پلاس، از جمله Atmos استفاده کنید. DTS و TrueHD هنوز هم به عنوان PCM چند کانال بازی می کنند.';
	@override String get audioPassthroughDescriptionAppleSpatial => 'از دکوراسیون دلفی بومی Apple برای Dolby Digital Plus، از جمله Atmos استفاده کنید.در iOS، iPadOS و tvOS 26 یا بعد، TrueHD Atmos و DTS:X به عنوان صدا فضایی پخش می شود.در سایر ردیف های DTS و TrueHD به عنوان PCM چند کانال پخش می شود.';
	@override String get audioPassthroughOverriddenByNormalization => 'در حالی که صداها به حالت عادی می رسند';
	@override String get audioChannelLimit => 'کانال های صوتی';
	@override String get audioChannelLimitDescription => 'مخلوط کردن صدا رمزگذاری شده برای بلندگوها، گوشی های هوشمند و یا تنظیمات HDMI که نمی تواند هر کانال پخش';
	@override String get audioChannelLimitOriginal => 'اصلی';
	@override String get audioChannelLimitOriginalDescription => 'بازی هر کانال در مسیر';
	@override String get audioChannelLimitSurround51 => 'تا 5.1';
	@override String get audioChannelLimitSurround51Description => 'مخلوط 7.1 به 5.1 برای تلویزیون ها و گیرنده هایی که فقط 5.1 PCM را می گیرند.';
	@override String get audioChannelLimitStereo => 'استریو';
	@override String get audioChannelLimitStereoDescription => 'مخلوط کردن به دو کانال برای بلندگوهای استریو یا گوشی های هوشمند.';
	@override String get downmixCenterBoost => 'مرکز کانال بوست';
	@override String downmixCenterBoostValue({required Object db}) => '${db} دبی';
	@override String get downmixCenterBoostLabel => 'افزایش (dB )';
	@override String get downmixCenterBoostShort => 'دبی';
	@override String get audioDownmixNormalize => 'دانلود بازی Downmix';
	@override String get audioDownmixNormalizeDescription => 'مخلوط را پایین بیاورید تا از چرخش جلوگیری شود.برای حفظ حجم اصلی (ممکن است صحنه های بلند را مختل کند) خاموش کنید.';
	@override String get dvConversionMode => 'Dolby Vision تبدیل';
	@override String get dvConversionModeDescription => 'انتخاب کنید که چگونه فایل های پروفایل 7 Dolby Vision پردازش می شوند.';
	@override String get dvConversionAuto => 'خودکار';
	@override String get dvConversionNative => 'معلول / معلول';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'استفاده از قابلیت تشخیص دستگاه و رفتار سقوط عادی';
	@override String get dvConversionNativeDescription => 'قدرت نادر DV7 و سرکوب DV تبدیل عقب نشینی';
	@override String get dvConversionDv81Description => 'تبدیل RPU به پروفایل Dolby Vision 8.1';
	@override String get dvConversionHevcStripDescription => 'نوار Dolby Vision لایه های RPU/EL و سطح فعلی HEVC';
	@override String get experimentalDolbyVision => 'Dolby Vision آزمایشی';
	@override String get experimentalDolbyVisionDescription => 'در پخش بعدی از رندرکنندهٔ آزمایشی FEL استفاده شود. به ساخت جداگانهٔ موتور نیاز دارد.';
	@override String get dvExperimentUnavailableDescription => 'این آزمایش فعلاً فقط در Linux در دسترس است.';
	@override String get dvCompatibilityFallback => 'گزینهٔ جایگزین سازگار';
	@override String get dvCompatibilityFallbackDescription => 'اگر آزمایش شروع نشد، از رندرکنندهٔ استاندارد استفاده شود. ممکن است داده‌های FEL از دست بروند.';
	@override String get dvExperimentDiagnostics => 'ثبت رویدادهای آزمایش ویدیو';
	@override String get dvExperimentDiagnosticsDescription => 'در پخش بعدی گزارش‌های دقیق پخش‌کننده فعال شوند.';
	@override String get disableDolbyVision => 'غیر قابل اجرا Dolby Vision';
	@override String get disableDolbyVisionDescription => 'در فایل HDR10 یا لایه HLG به جای Dolby Vision بازی کنید، زمانی که یک';
	@override String get hdrSdrConversion => 'HDR به SDR تبدیل';
	@override String get hdrSdrConversionDescription => 'انتخاب کنید که چه چیزی ویدئو HDR را تبدیل می کند زمانی که صفحه نمایش نمی تواند HDR را نشان دهد.';
	@override String get hdrSdrConversionAuto => 'خودکار';
	@override String get hdrSdrConversionAutoDescription => 'دستگاه در Android 9 و بالاتر، پخش کننده در نسخه های قدیمی تر';
	@override String get hdrSdrConversionDevice => 'دستگاه';
	@override String get hdrSdrConversionDeviceDescription => 'سخت افزار ویدئویی دستگاه شما آن را تبدیل می کند سریع ترین، اما رنگ ها بستگی به دستگاه دارد';
	@override String get hdrSdrConversionPlayer => 'پخش‌کننده';
	@override String get hdrSdrConversionPlayerDescription => 'رنگ های سازگار، اما 4K می تواند بر روی جعبه های تلویزیونی پایین';
	@override String get deinterlace => 'دایناسور';
	@override String get deinterlaceDescription => 'آثار شانه‌ای ویدیوی درهم‌بافته را حذف کنید (فقط پخش‌کنندهٔ mpv)';
	@override String get deinterlaceOff => 'خاموش';
	@override String get deinterlaceOffDescription => 'نمایش ویدئو متصل به عنوان آن را رمزگذاری شده است';
	@override String get deinterlaceVideo => 'ویدئو';
	@override String get deinterlaceVideoDescription => 'برای فیلم برداری ویدئویی برای تلویزیون، مانند ورزش، اخبار و کنسرت ها';
	@override String get deinterlaceFilm => 'فیلم';
	@override String get deinterlaceFilmDescription => 'بازگرداندن چارچوب های اصلی فیلم و انیمیشن به 29.97 fps، رایج در DVD های NTSC. فیلمبرداری ویدئویی برای فیلمبرداران.';
	@override String get requireProfileSelectionOnOpen => 'درخواست پروفایل در اپلیکیشن باز';
	@override String get requireProfileSelectionOnOpenDescription => 'نمایش انتخاب پروفایل هر بار که اپلیکیشن باز می شود';
	@override String get forceTvMode => 'حالت تلویزیون قدرت';
	@override String get forceTvModeDescription => 'برای دستگاه هایی که خود شناسایی نمی کنند، نیاز به راه اندازی مجدد دارد.';
	@override String get startInFullscreen => 'شروع در صفحه نمایش کامل';
	@override String get startInFullscreenDescription => 'باز کردن PlezyNG در حالت صفحه نمایش کامل در راه اندازی';
	@override String get exitFullscreenOnPlayerClose => 'خروجی صفحه نمایش کامل در بازیکن بسته';
	@override String get exitFullscreenOnPlayerCloseDescription => 'خروجی خودکار صفحه نمایش کامل در هنگام بستن پخش کننده ویدئویی';
	@override String get autoHidePerformanceOverlay => 'اتومبیل های خودکار';
	@override String get autoHidePerformanceOverlayDescription => 'عملکرد را با کنترل های بازسازی از بین ببرید';
	@override String get showNavBarLabels => 'نشان دادن برچسب ها Navigation Bar';
	@override String get showNavBarLabelsDescription => 'نمایش برچسب های متن در زیر آیکون های نوار ناوبری';
	@override String get startupSection => 'بخش Startup';
	@override String get preferredServer => 'ترجیح سرور';
	@override String get preferredServerDescription => 'اولویت بندی نتایج این سرور در حالی که حفظ هر سرور متصل در دسترس است.';
	@override String get preferredServerAutomatic => 'اتوماتیک';
	@override String get showExploreTab => 'نمایش تگ ها';
	@override String get showExploreTabDescription => 'نمایش برگه اکتشاف با محتوای Plex اکتشاف و ردیاب های متصل';
	@override String get hideEmptyLibraries => 'کتابخانه های خالی را پنهان کنید';
	@override String get hideEmptyLibrariesDescription => 'حذف کتابخانه ها با تعداد آیتم های گزارش شده توسط سرور از صفر از ناوبری.';
	@override String get liveTvDefaultFavorites => 'کانال های مورد علاقه';
	@override String get liveTvDefaultFavoritesDescription => 'نمایش تنها کانال های مورد علاقه در هنگام باز کردن تلویزیون زنده';
	@override String get general => 'عمومی';
	@override String get generalDescription => 'زبان، راه اندازی و رفتار پنجره';
	@override String get languageAndRegion => 'زبان و منطقه';
	@override String get startup => 'راه‌اندازی';
	@override String get display => 'نمایش';
	@override String get libraryAndCards => 'کتابخانه و کارت';
	@override String get homeScreen => 'صفحه اصلی صفحه نمایش';
	@override String get navigation => 'جهت یابی';
	@override String get window => 'پنجره';
	@override String get liveTv => 'تلویزیون زنده';
	@override String get player => 'پخش‌کننده';
	@override String get videoAndDisplay => 'ویدئو و نمایش';
	@override String get audio => 'صدا';
	@override String get quality => 'کیفیت';
	@override String get subtitles => 'زیرنویس‌ها';
	@override String get seekAndTiming => 'جستجو و زمان بندی';
	@override String get behavior => 'رفتار';
	@override String get gestures => 'راهپیمایی';
	@override String get gestureBrightnessSwipe => 'روشنایی سوئیپ';
	@override String get gestureBrightnessSwipeDescription => 'بالا یا پایین را روی لبه چپ بپوشانید تا روشنایی را تنظیم کنید.';
	@override String get gestureVolumeSwipe => 'حجم سوئیپ';
	@override String get gestureVolumeSwipeDescription => 'بالا یا پایین را در لبه راست حرکت دهید تا حجم را تنظیم کنید.';
	@override String get gesturePinchToZoom => 'پینچ به زوم';
	@override String get gesturePinchToZoomDescription => 'بر روی ویدئو کلیک کنید تا وارد یا خارج شود.';
	@override String get gestureSeekSwipe => 'جستجو برای Swipe';
	@override String get gestureSeekSwipeDescription => 'سمت چپ یا راست را در هر نقطه از ویدئو برای جستجو تغییر دهید؛ آزاد کردن برای پرش';
	@override String get rememberBrightnessLevel => 'سطح روشنایی را به یاد داشته باشید';
	@override String get rememberBrightnessLevelDescription => 'شروع بازی در روشنایی تعیین شده توسط آخرین سوئیپ';
	@override String get controls => 'کنترل ها';
	@override String get rememberPlayerChanges => 'تغییرات بازیکنان را به یاد داشته باشید';
	@override String get rememberPlayerChangesDescription => 'جایی که تغییراتی که در طول بازیابی انجام می شود ذخیره و دوباره اعمال می شود';
	@override String get scopePlaybackSpeed => 'سرعت پخش';
	@override String get scopeShaderPreset => 'شیراز پیش بینی';
	@override String get scopeAspectRatio => 'نسبت تصویر';
	@override String get scopeSyncOffsets => 'Audio & Subtitle همگام سازی';
	@override String get playerScopeOff => 'نجات ندهید';
	@override String get playerScopeGlobal => 'همه جا';
	@override String get playerScopeLibrary => 'در کتابخانه';
	@override String get playerScopeTitle => 'برای نمایش یا فیلم';
	@override String get exportDialogTitle => 'صادرات PlezyNG تنظیمات';
	@override String get followSystem => 'پیروی از سیستم';
	@override String get followAppLanguage => 'مطابق زبان رابط کاربری';
	@override String get regionFormat => 'قالب‌های منطقه‌ای';
	@override String get regionFormatDescription => 'نحوهٔ نمایش تاریخ‌ها، اعداد و واحدهای اندازه‌گیری را انتخاب کنید.';
	@override String get metadataLanguage => 'زبان فراداده';
	@override String get metadataLanguageDescription => 'زبان دلخواه عنوان‌ها و توضیحات، در صورت پشتیبانی سرور. تنظیمات زبان صدا و زیرنویس مستقل هستند.';
	@override String get enterFullscreenOnPlaybackStart => 'صفحه نمایش کامل هنگامی که playback شروع می شود';
	@override String get enterFullscreenOnPlaybackStartDescription => 'باز کردن ویدئو دسکتاپ در صفحه نمایش کامل هنگامی که پخش شروع می شود';
	@override String get extendVideoIntoDisplayCutout => 'اضافه کردن ویدئو به صفحه نمایش';
	@override String get extendVideoIntoDisplayCutoutDescription => 'اجازه دهید ویدئوی صفحه نمایش کامل از دوربین بر روی گوشی های اندرویدی استفاده کند';
	@override String get languageDescription => 'زبان مورد استفاده برای کنترل ها و پیام های PlezyNG را انتخاب کنید سیستم ردیابی زبان دستگاه شما را دنبال می کند.';
	@override String get themeDescription => 'رنگ ها و کنتراست های مورد استفاده در سراسر برنامه را انتخاب کنید.';
	@override String get libraryDensityDescription => 'تغییر تعداد کارت های کتابخانه در هر ردیف.';
	@override String get displayScaleDescription => 'رابط کاربری را در این صفحه نمایش اتومبیل بازگردانید بدون تغییر اندازه متن دستگاه شما.';
	@override String get themeSongVolumeDescription => 'حجم آهنگ های موضوعی را نسبت به سایر صداها تنظیم کنید.';
	@override String get viewModeDescription => 'انتخاب کنید که آیا آیتم های کتابخانه به عنوان پوستر در یک شبکه یا به عنوان یک لیست کوچک ظاهر می شوند.';
	@override String get gridViewDescription => 'آیتم های کتابخانه را در ردیف ها و ستون های پوستر مرتب کنید.';
	@override String get listViewDescription => 'نمایش آیتم های کتابخانه در یک لیست عمودی با متن بیشتر برای هر آیتم.';
	@override String get gridSpacingDescription => 'فاصله بین پوسترها را در شبکه های کتابخانه تنظیم کنید.';
	@override String get gridSpacingTightDescription => 'پوستر های بیشتری را در سراسر صفحه نمایش با شکاف های کوچکتر قرار دهید.';
	@override String get gridSpacingNormalDescription => 'استفاده از فاصله استاندارد بین پوسترها';
	@override String get gridSpacingSpaciousDescription => 'فاصله های بزرگتر بین پوسترها را برای جداسازی بیشتر اضافه کنید.';
	@override String get episodePosterModeDescription => 'انتخاب کنید که کدام آثار هنری بر روی کارت های قسمت نمایش داده می شود.';
	@override String get seriesPosterDescription => 'از پوستر سریال برای هر قسمت استفاده کنید.';
	@override String get seasonPosterDescription => 'استفاده از پوستر فصل برای هر قسمت زمانی که در دسترس است.';
	@override String get episodeThumbnailDescription => 'استفاده از یک چارچوب از قسمت زمانی که در دسترس است.';
	@override String get continueWatchingActionDescription => 'انتخاب کنید که چه اتفاقی می افتد هنگامی که یک کارت نظارت مداوم را فعال می کنید.';
	@override String get continueWatchingPlayDescription => 'فیلم یا قسمت را بلافاصله شروع کنید.';
	@override String get continueWatchingDetailsDescription => 'صفحه عنوان را ابتدا باز کنید تا بتوانید جزئیات را بررسی کنید و یک اقدام را انتخاب کنید.';
	@override String get episodeActionDescription => 'انتخاب کنید که چه اتفاقی می افتد هنگامی که شما یک کارت قسمت را فعال می کنید.';
	@override String get episodePlayDescription => 'قسمت را بلافاصله شروع کنید.';
	@override String get episodeDetailsDescription => 'صفحه قسمت را قبل از پخش باز کنید.';
	@override String get contentScreensaverDelayDescription => 'انتخاب کنید که چقدر طول می کشد PlezyNG بدون ورودی قبل از نمایش آثار هنری منتظر بماند.';
	@override String get continueWatchingRowSizeDescription => 'انتخاب کنید که کارت ها در ردیف ادامه تماشای چقدر بزرگ هستند.';
	@override String get rowSizeCompactDescription => 'نشان دادن کارت های کوچکتر به طوری که عناصر بیشتر در سراسر ردیف مناسب است.';
	@override String get rowSizeStandardDescription => 'از اندازه کارت استاندارد استفاده کنید.';
	@override String get rowSizeLargeDescription => 'نمایش کارت های بزرگتر با جزئیات هنری بیشتر.';
	@override String get visualEffectsDescription => 'بودجه انیمیشن و اثر هنری را برای این دستگاه انتخاب کنید.';
	@override String get visualEffectsFullDescription => 'از اثرات کامل انیمیشن و هنری در هر دستگاه استفاده کنید.';
	@override String get startupSectionDescription => 'انتخاب کنید که کدام بخش در هنگام شروع PlezyNG باز می شود.';
	@override late final _Translations$settings$startupSectionOptions$fa startupSectionOptions = _Translations$settings$startupSectionOptions$fa._(_root);
	@override String get smallSkipDurationDescription => 'تنظیم فاصله حرکت شده توسط کوتاه عقب و جلو به دنبال کنترل.';
	@override String get largeSkipDurationDescription => 'فاصله را که به عقب و جلو حرکت می کند تنظیم کنید، کنترل ها را جستجو کنید.';
	@override String get rewindOnResumeDescription => 'بازگرداندن بازی با این مقدار هنگامی که یک ویدئو را دوباره پخش می کنید.';
	@override String get defaultSleepTimerDescription => 'مدت زمان اولیه استفاده شده در هنگام شروع ساعت خواب را تنظیم کنید.';
	@override String get playNextCountdownDescription => 'این مطلب را قبل از شروع قسمت بعدی به مدت طولانی منتظر بمانید تا بلافاصله شروع شود.';
	@override String get autoSkipDelaySettingDescription => 'زمانی اعمال می شود که یک ورودی، اعتبار یا آگهی به طور خودکار تنظیم شده است.';
	@override String get downmixCenterBoostDescription => 'افزایش گفتگو در کانال مرکزی هنگامی که صدا اطراف به استریو مخلوط می شود.';
	@override String get displaySwitchDelayDescription => 'قبل از تغییر حالت نمایش منتظر بمانید تا تلویزیون یا گیرنده بتواند سوئیچ قبلی خود را به پایان برساند.';
	@override String get playerBackendDescription => 'انتخاب کنید که کدام موتور پخش ویدئو را بر روی این دستگاه دکوراسیون و بازگرداند.';
	@override String get exoPlayerDescription => 'از پخش کننده مادری آندروید مبتنی بر Media3 و مسیرهای سخت افزاری پشتیبانی شده استفاده کنید.';
	@override String get mpvDescription => 'از mpv استفاده کنید، که بازتاب اضافی، زیرنویس و کنترل های پردازش ویدئو را نشان می دهد.';
	@override String get scopeOffDescription => 'فقط تغییرات مربوط به جلسه پخش فعلی را حفظ کنید.';
	@override String get scopeGlobalDescription => 'همان مقدار را برای هر کتابخانه و عنوان تکرار کنید.';
	@override String get scopeLibraryDescription => 'به یاد داشته باشید که ارزش جداگانه ای برای هر کتابخانه وجود دارد.';
	@override String get scopeTitleDescription => 'به یاد داشته باشید یک مقدار جداگانه برای هر نمایش یا فیلم.';
	@override String get specialsOrderingServerDescription => 'سفارش قسمت را که توسط سرور رسانه ها ارائه می شود حفظ کنید.';
	@override String get specialsOrderingAirDateDescription => 'قرار دادن ویژه ها در میان قسمت های منظم با توجه به تاریخ هوایی آنها.';
	@override String get specialsOrderingLastDescription => 'قرار دادن هر خاص پس از فصل های معمولی.';
	@override String get skipIntroModeDescription => 'انتخاب کنید که آیا مارک های ورودی به طور معمول بازی می کنند، یک دکمه اسکایپ را نشان می دهند یا به صورت اتوماتیک.';
	@override String get skipCreditsModeDescription => 'انتخاب کنید که آیا اعتبارات به طور معمول بازی می کنند، یک دکمه اسکایپ را نشان می دهند یا به طور خودکار اسکایپا می کنند.';
	@override String get skipAdsModeDescription => 'انتخاب کنید که آیا آگهی های شناسایی شده به طور معمول پخش می شوند، یک دکمه اسکایپ را نشان می دهند یا به طور خودکار اسکایپا می کنند.';
	@override String get playbackBufferAutoDescription => 'اجازه دهید بازیکن فعال اندازه بوفری معمولی خود را انتخاب کند.';
	@override String get playbackBufferLargeDescription => 'رسانه های بیشتری را قبل از پخش آماده نگه دارید؛ این از حافظه بیشتر استفاده می کند.';
	@override String get playbackBufferExtraLargeDescription => 'بزرگترین حافظه خواندن را نگه دارید؛ این بیشترین حافظ را به دست می آورد.';
	@override String get defaultQualityDescription => 'رزولوشن ویدئویی پیش فرض را تنظیم کنید و سقف بیترات را برای جریان هایی که سرور از آن عبور می کند، تنظیم کنید.';
	@override String get cellularQualityDescription => 'بر روی کیفیت پیش فرض هنگامی که دستگاه از یک اتصال سلولی استفاده می کند.';
	@override String get remoteQualityDescription => 'بر روی کیفیت پیش فرض هنگام اتصال به یک سرور از طریق یک اتصال از راه دور.';
	@override String get qualityPresetOriginalDescription => 'منبع را با کیفیت در دسترس خود بازی کنید بدون اینکه از سرور بخواهید آن را رمزگذاری کند.';
	@override String get qualityPresetTranscodeOptionDescription => 'از سرور برای یک جریان تبدیل شده با استفاده از رزولوشن و bitrate نشان داده شده در بالا بپرسید.';
	@override String get qualityPresetSameAsDefaultDescription => 'استفاده از کیفیت انتخاب شده در کیفیت پیش فرض.';
	@override String get musicQualityDescription => 'حداکثر بیتی صدا را که از سرور خواسته می شود تنظیم کنید؛ اصلی جریان منبع را حفظ می کند.';
	@override String get musicQualityOriginalDescription => 'پخش صدا منبع بدون یک ترانسکد بیتی.';
	@override String get musicQualityTranscodeOptionDescription => 'درخواست یک ترانسکود سرور در نزدیکی نرخ بیتی که در بالا نشان داده شده است؛ خروجی واقعی می تواند متفاوت باشد.';
	@override String get maxVolumeInputLabel => 'حداکثر حجم ( % )';
	@override String get checkForUpdatesDescription => 'در حال حاضر بررسی کنید که آیا نسخه جدیدتر از PlezyNG در دسترس است یا خیر.';
	@override String get appearanceDescription => 'موضوع برنامه را انتخاب کنید و کارت های کتابخانه، خطوط خانه و ناوبری را تنظیم کنید.';
	@override String get prerollLibraryDescription => 'کتابخانه ای را انتخاب کنید که شامل کلیپ های موجود به عنوان پیش نمایش فیلم است.';
	@override String get prerollSelectionDescription => 'انتخاب کنید که کدام کلیپ ها از کتابخانه انتخاب شده می توانند قبل از فیلم بازی کنند.';
	@override String get contentScreensaverDelayOptionDescription => 'منتظر این چند دقیقه بدون ورودی قبل از نمایش کار هنری ذخیره صفحه نمایش باشید.';
	@override String get videoCodecOptionDescription => 'اجازه پخش مستقیم برای این کدک زمانی که پشتیبانی می شود. کدک های غیر چک شده توسط سرور رسانه ها رمزگذاری می شوند.';
}

// Path: themeEditor
class _Translations$themeEditor$fa extends Translations$themeEditor$en {
	_Translations$themeEditor$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get builtIn => 'ساخته شده';
	@override String get presets => 'پیشگویی';
	@override String get custom => 'سفارشی';
	@override String get customEmpty => 'هنوز ساخته نشده';
	@override String get editCustom => 'ویرایش موضوعات';
	@override String get editCustomDescription => 'هر رنگ را خودتان انتخاب کنید';
	@override String get locked => 'دسترسی طول عمر مورد نیاز';
	@override String get savedLocked => 'ذخیره شده – در دسترس با دسترسی ابدی';
	@override String get title => 'موضوعات شخصی';
	@override String get startFrom => 'شروع از';
	@override String get startFromDescription => 'کپی کردن تمام رنگ ها از موضوع دیگری';
	@override String get colors => 'رنگ ها';
	@override String get preview => 'پیش نمایش';
	@override late final _Translations$themeEditor$slots$fa slots = _Translations$themeEditor$slots$fa._(_root);
	@override String get opacity => 'ناخودآگاه';
	@override String get hexHint => '#RRGGBB یا #AARRGGBB';
	@override String get fromOtherThemes => 'از موضوعات دیگر';
	@override String swatchLabel({required Object theme, required Object color}) => '${theme} ${color}';
	@override late final _Translations$themeEditor$contrast$fa contrast = _Translations$themeEditor$contrast$fa._(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, زیر توصیه شده ${minimum}:1';
	@override String get discardTitle => 'تغییرات را نادیده بگیرید؟';
	@override String get discardMessage => 'تغییرات ذخیره‌نشدهٔ رنگ از دست می‌روند.';
	@override String get discard => 'نادیده گرفتن';
	@override String previewCardTitle({required Object number}) => 'صفحه اصلی ${number}';
	@override String previewCardSubtitle({required Object minutes}) => '${minutes} دقیقه باقی مانده';
	@override String get previewSwitch => 'اتوبوس';
	@override String get previewMutedText => 'متن دوم این گونه خوانده می شود.';
	@override String get themeSystemDescription => 'ظاهر دستگاه خود را دنبال کنید و به طور خودکار بین نور و تاریکی تغییر دهید.';
	@override String get themeLightDescription => 'از یک پس زمینه روشن با متن تاریک استفاده کنید.';
	@override String get themeDarkDescription => 'از یک پس زمینه تاریک با متن روشن استفاده کنید.';
	@override String get themeOledDescription => 'از سطوح نزدیک سیاه استفاده کنید که نور را در صفحه نمایش های OLED کاهش می دهند.';
	@override String get themeEmberDescription => 'از رنگ های گرم قرمز و آمبر استفاده کنید.';
	@override String get themeGlacierDescription => 'از رنگ های آبی رنگ استفاده کنید.';
	@override String get themeForestDescription => 'از رنگ های سبز و طبیعی استفاده کنید.';
	@override String get themePlumDescription => 'از رنگ های ویولیت و پلوم استفاده کنید.';
	@override String get themePaperDescription => 'از سطوح گرم مانند کاغذ و رنگ های الهام گرفته از نقاشی استفاده کنید.';
	@override String get themeCustomDescription => 'از پالت رنگی که در ویرایشگر موضوعی سفارشی ایجاد کرده اید استفاده کنید.';
	@override String get editorDescription => 'یک رنگ پالت را انتخاب کنید، رنگ آن را تنظیم کنید، اشباع، روشنایی یا نابینایی، و قبل از صرفه جویی به روز رسانی پیش نمایش را ببینید.';
}

// Path: search
class _Translations$search$fa extends Translations$search$en {
	_Translations$search$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get hint => 'جستجو برای فیلم ها، نمایش ها، موسیقی...';
	@override String get tryDifferentTerm => 'یک اصطلاح جستجو متفاوت را امتحان کنید';
	@override String get searchYourMedia => 'رسانه های خود را جستجو کنید';
	@override String get enterTitleActorOrKeyword => 'عنوان، بازیگر یا کلمه کلیدی را وارد کنید.';
	@override String get people => 'افراد';
}

// Path: hotkeys
class _Translations$hotkeys$fa extends Translations$hotkeys$en {
	_Translations$hotkeys$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'تنظیم کوتاه برای ${actionName}';
	@override String get clearShortcut => 'کوتاه کردن شفاف';
	@override String get noShortcutSet => 'بدون کوتاه کردن';
	@override String get currentShortcut => 'کوتاه مدت فعلی :';
	@override String get pressToRecord => 'انتخاب کنید برای ضبط یک کوتاه';
	@override String get recordingShortcut => 'اکنون کوتاه را فشار دهید';
	@override late final _Translations$hotkeys$actions$fa actions = _Translations$hotkeys$actions$fa._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$fa extends Translations$fileInfo$en {
	_Translations$fileInfo$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'فایل اطلاعات';
	@override String get overview => 'نمای کلی';
	@override String get video => 'ویدئو';
	@override String get audio => 'صدا';
	@override String get subtitles => 'زیرنویس‌ها';
	@override String get images => 'تصاویر درگیر';
	@override String get dataStreams => 'جریان داده ها';
	@override String get lyrics => 'متن ترانه';
	@override String get file => 'فایل';
	@override String get attachments => 'اتصال';
	@override String get delivery => 'تحویل';
	@override String versionCounter({required Object index, required Object count}) => 'نسخه ${index} از ${count}';
	@override String fileCounter({required Object index, required Object count}) => 'فایل ${index} از ${count}';
	@override String get noStreams => 'سرور اعلام کرد که هیچ جریان برای این فایل وجود ندارد.';
	@override String get copyPath => 'کپی مسیر';
	@override String get pathCopied => 'فایل مسیر کپی شده';
	@override String get codec => 'کدک';
	@override String get codecTag => 'برچسب کدک';
	@override String get resolution => 'وضوح تصویر';
	@override String get codedResolution => 'راه حل کدگذاری شده';
	@override String get bitrate => 'نرخ جریان';
	@override String get frameRate => 'فریم نرخ';
	@override String get rotation => 'چرخش';
	@override String get comment => 'چگونه';
	@override String get audioDescription => 'شرح صوتی';
	@override String get headerCompression => 'سرکوب سرکوب';
	@override String get sidecarFile => 'فایلهای Sidecar';
	@override String get transportTimestamp => 'زمان حمل و نقل';
	@override String get displayOffset => 'نمایش Offset';
	@override String get previewFailureCode => 'پیش بینی کد شکست';
	@override String get previewRetries => 'پیش بینی بازگشت';
	@override String get aspectRatio => 'نسبت تصویر';
	@override String get pixelAspectRatio => 'Pixel Aspect نسبت';
	@override String get profile => 'نمایه';
	@override String get level => 'سطح';
	@override String get bitDepth => 'عمق بیت';
	@override String get pixelFormat => 'فرمت پیکسل';
	@override String get colorSpace => 'فضای رنگی';
	@override String get colorRange => 'رنگ رینگ';
	@override String get colorPrimaries => 'مقدمات رنگی';
	@override String get colorTransfer => 'انتقال رنگ';
	@override String get chromaSubsampling => 'کروم زیرمجموعه';
	@override String get chromaLocation => 'موقعیت کروم';
	@override String get scanType => 'نوع اسکن';
	@override String get interlaced => 'درهم آمیخته';
	@override String get anamorphic => 'آنامورفیک';
	@override String get referenceFrames => 'چارچوب های مرجع';
	@override String get dynamicRange => 'محدوده دینامیک';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Dolby Vision سطح';
	@override String get dolbyVisionVersion => 'Dolby Vision نسخه';
	@override String get dolbyVisionLayers => 'Dolby Vision لایه ها';
	@override String get baseLayerCompatibility => 'سازگاری لایه پایه';
	@override String get avcBitstream => 'جریان بیت AVC';
	@override String get nalLengthSize => 'اندازه طول نال';
	@override String get scalingMatrix => 'ماتریکس مقیاس سفارشی';
	@override String get streamIdentifier => 'جریان شناسایی';
	@override String get streamIndex => 'شاخص جریان';
	@override String get streamId => 'جریان ID';
	@override String get language => 'زبان';
	@override String get languageCode => 'کد زبان';
	@override String get streamTitle => 'تریلر تریلر';
	@override String get channels => 'کانالها';
	@override String get sampleRate => 'نرخ نمونه';
	@override String get spatialAudio => 'فضای صوتی';
	@override String get textBased => 'متن مبتنی بر';
	@override String get subtitleFormat => 'فرمت سیداکار';
	@override String get provider => 'ارائه دهنده';
	@override String get matchScore => 'بازی نمره';
	@override String get externalDelivery => 'می توان به صورت جداگانه خدمت کرد';
	@override String get sidecarPath => 'راه شیشه ای';
	@override String get sourceStream => 'کپی شده از';
	@override String get temporary => 'موقت';
	@override String get timeBase => 'پایه زمان';
	@override String get overallBitrate => 'کل بیت کوین';
	@override String get path => '‏‏مسیر';
	@override String get fileName => 'نام فایل';
	@override String get size => 'سایز';
	@override String get totalSize => 'حجم کل';
	@override String get container => 'محفظه';
	@override String get duration => 'مدت زمان';
	@override String get previewThumbnails => 'پیش نمایش تامپین';
	@override String get previewIndex => 'پیش نمایش شاخص';
	@override String get packetLength => 'طول بسته';
	@override String get filePresent => 'فایلهای موجود';
	@override String get fileReadable => 'قابل خواندن توسط سرور';
	@override String get streamPath => 'جریان مسیر';
	@override String get optimizedForStreaming => 'بهینه سازی برای پخش';
	@override String get has64bitOffsets => '64 بیتی Offsets';
	@override String get protocol => 'پروتکل';
	@override String get mediaType => 'نوع رسانه ها';
	@override String get sourceKind => 'منبع خوب';
	@override String get optimizedVersion => 'نسخه بهینه سازی شده';
	@override String get optimizationTarget => 'هدف بهینه سازی';
	@override String get deletedAt => 'حذف شده';
	@override String get remoteSource => 'منبع دور';
	@override String get infiniteStream => 'جریان بی نهایت';
	@override String get directPlay => 'بازی مستقیم';
	@override String get directStream => 'جریان مستقیم';
	@override String get transcoding => 'کدگذاری';
	@override String get etag => 'ETag';
	@override String get versionId => 'نسخه ID';
	@override String get fileId => 'فایل ID';
	@override String get defaultAudioTrack => 'تریلر Audio Track';
	@override String get defaultSubtitleTrack => 'ترک زیرنویس پیش‌فرض';
	@override String get subtitlesOff => 'خاموش';
	@override String get flagDefault => 'پیشفرض';
	@override String get flagForced => 'اجباری';
	@override String get flagSelected => 'انتخاب شده';
	@override String get flagExternal => 'خارجی';
	@override String get flagHearingImpaired => 'شنیدن ضعیف';
	@override String get flagDub => 'دبی';
	@override String get flagOriginal => 'اصلی';
	@override String get channelsMono => 'مونو';
	@override String dolbyVisionProfile({required Object profile}) => 'پروفایل ${profile}';
}

// Path: mediaMenu
class _Translations$mediaMenu$fa extends Translations$mediaMenu$en {
	_Translations$mediaMenu$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'مارک به نظر می رسد';
	@override String get markAsUnwatched => 'مارک ناشناخته';
	@override String get removeFromContinueWatching => 'حذف از ادامه مشاهده';
	@override String get viewDetails => 'مشاهده جزئیات';
	@override String get goToSeries => 'به سری بروید';
	@override String get shufflePlay => 'بازی شوفلی';
	@override String get shuffleNotAvailableOffline => 'دانلود بازی Shuffle در دسترس نیست';
	@override String get fileInfo => 'فایل اطلاعات';
	@override String get deleteEpisodeFromServer => 'حذف قسمت از سرور';
	@override String get deleteSeasonFromServer => 'حذف فصل از سرور';
	@override String get deleteShowFromServer => 'حذف نمایش از سرور';
	@override String get deleteMovieFromServer => 'حذف فیلم از سرور';
	@override String get deleteEpisodeTitle => 'این قسمت را حذف کنید؟';
	@override String get deleteSeasonTitle => 'این فصل را حذف کنید؟';
	@override String get deleteShowTitle => 'این نمایش را حذف کنید؟';
	@override String get deleteMovieTitle => 'این فیلم را حذف کنید؟';
	@override String get deleteEpisodeConfirm => 'حذف قسمت';
	@override String get deleteSeasonConfirm => 'فصل حذف';
	@override String get deleteShowConfirm => 'نمایش حذف';
	@override String get deleteMovieConfirm => 'حذف فیلم';
	@override String get deleteAnyway => 'حذف به هر حال';
	@override String confirmDeleteTarget({required Object title}) => '«${title}» برای همیشه از سرور شما حذف شود؟';
	@override String get deleteMultipleWarning => 'این شامل تمام قسمت ها و فایل های آنها است.';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n,
		one: 'با این کار، ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} قسمت موجود در آن و فایل آن حذف می‌شود.',
		other: 'با این کار، همهٔ ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} قسمت موجود در آن و فایل‌های آن‌ها حذف می‌شوند.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n,
		one: 'این مورد در ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} فایل ذخیره شده است و آن فایل حذف خواهد شد.',
		other: 'این مورد در ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} فایل ذخیره شده است و همهٔ آن‌ها حذف خواهند شد.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} قسمت دیگر در همین فایل ذخیره شده است و آن هم حذف خواهد شد:',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} قسمت دیگر در همین فایل ذخیره شده‌اند و آن‌ها هم حذف خواهند شد:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'PlezyNG نتوانست بررسی کند کدام فایل‌ها حذف می‌شوند؛ بنابراین ممکن است مواردی بیش از مورد بالا حذف شوند. لغو کنید و دوباره تلاش کنید، یا در هر صورت حذف کنید.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'سرور شما جزئیات فایل‌های این مورد را ارائه نکرده است، بنابراین PlezyNG نمی‌تواند بررسی کند کدام فایل‌ها حذف می‌شوند. ممکن است مواردی بیش از مورد بالا حذف شوند.';
	@override String get mediaDeletedSuccessfully => 'موضوع رسانه ها با موفقیت حذف شد';
	@override String get mediaFailedToDelete => 'ناپدید شدن حذف رسانه ها';
	@override String get rate => 'ارزیابی کن';
	@override String get playFromBeginning => 'از ابتدا اجرا کن';
	@override String get playVersion => 'بازی نسخه...';
}

// Path: rateSheet
class _Translations$rateSheet$fa extends Translations$rateSheet$en {
	_Translations$rateSheet$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'ارزیابی کن';
	@override String get server => 'سرور';
	@override String get favorite => 'مورد علاقه';
	@override String get favorited => 'مورد علاقه';
	@override String get saved => 'نجات یافته';
	@override String get notAvailable => 'هیچ مسابقه ای یافت نشد';
	@override String get noConnectedServices => 'یک سرویس را در تنظیمات متصل کنید تا در آن رتبه بندی شود.';
}

// Path: accessibility
class _Translations$accessibility$fa extends Translations$accessibility$en {
	_Translations$accessibility$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title} فیلم';
	@override String mediaCardShow({required Object title}) => '${title} نمایش تلویزیونی';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'مشاهده شده';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} درصد بازدید';
	@override String get mediaCardUnwatched => 'تماشا نشده';
	@override String get tapToPlay => 'برای پخش ضربه بزنید';
	@override String get decrease => 'کاهش';
	@override String get increase => 'افزایش';
	@override String decreaseValue({required Object label}) => 'کمبود ${label}';
	@override String increaseValue({required Object label}) => 'افزایش ${label}';
	@override String get hue => 'هوی';
	@override String get saturation => 'اشباع رنگ';
	@override String get brightness => 'روشنایی';
	@override String get hexColor => 'رنگ Hex';
	@override String get expandText => 'گسترش متن';
	@override String get collapseText => 'متن خراب';
	@override String get alphabetNavigation => 'آلبوم ناوبری';
	@override String get alphabetScrollHint => 'برای جابه‌جایی بر اساس حروف، انگشت خود را به بالا یا پایین بکشید';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'ردیف ${row} از ${rowCount}، ستون ${column} از ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'خط ${row} از ${rowCount}';
	@override String get autoScrollPlay => 'بازی خودکار اسکرول';
	@override String get autoScrollPause => 'استراحت اتوماتیک';
	@override String get hueShort => 'H';
	@override String get saturationShort => 'S';
	@override String get valueShort => 'V';
	@override String get red => 'قرمز';
	@override String get green => 'سبز';
	@override String get blue => 'آبی';
	@override String get redShort => 'R';
	@override String get greenShort => 'G';
	@override String get blueShort => 'ب';
	@override String get colorModeHsv => 'HSV';
	@override String get colorModeRgb => 'RGB';
	@override String get title => 'دسترسی';
	@override String get summary => 'متن، کنتراست، حرکت و کنترل';
	@override String get systemHint => 'تنظیمات دسترسی دستگاه شما همیشه اعمال می شود این گزینه ها تنظیمات را در طول PlezyNG اضافه می کنند.';
	@override String get readability => 'خواندن و دیدن';
	@override String get textSize => 'اضافه کردن متن';
	@override String get preview => 'داستان بعدی خود را پیدا کنید، بخوانید، گوش دهید و در سرعت خود تماشا کنید.';
	@override String get boldText => 'متن رابط کاربری';
	@override String get highContrast => 'تناقض بالا';
	@override String get highContrastHint => 'متن قوی تر، شاخص های برجسته و تمرکز بر روی سطوح روشن یا تاریک.';
	@override String get interaction => 'حرکت و تعامل';
	@override String get reduceMotion => 'کاهش حرکت';
	@override String get reduceMotionHint => 'حرکت نشانگر تمرکز، گذارهای صفحه و جلوه‌های تزئینی را متوقف کنید.';
	@override String get largeTargets => 'هدف های لمسی بزرگتر';
	@override String get largeTargetsHint => 'کنترل های به اشتراک گذاشته شده را برای لمس و ناوبری کمک کننده فضای بیشتری فراهم می کند.';
	@override String get navigationHint => 'برای جابه‌جایی بین کنترل‌ها از Tab و Shift+Tab، برای فعال‌سازی از Enter یا Space و برای بستن از Escape یا دکمهٔ بازگشت استفاده کنید. وقتی کتاب باز است، بزرگ‌نمایی و تنظیمات خواندن در دسترس‌اند.';
	@override String get textSizeDescription => 'متن رابط مقیاس در PlezyNG علاوه بر تنظیمات اندازه متن سیستم دستگاه شما.';
	@override String get boldTextHint => 'از یک وزن سنگین تر برای برچسب های رابط و پیام ها استفاده کنید تا آنها را آسان تر تشخیص دهند.';
}

// Path: tooltips
class _Translations$tooltips$fa extends Translations$tooltips$en {
	_Translations$tooltips$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'بازی شوفلی';
	@override String get playTrailer => 'بازی تریلر';
	@override String get markAsWatched => 'مارک به نظر می رسد';
	@override String get markAsUnwatched => 'مارک ناشناخته';
}

// Path: audioTracks
class _Translations$audioTracks$fa extends Translations$audioTracks$en {
	_Translations$audioTracks$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'ترافیک صوتی ${n}';
}

// Path: videoControls
class _Translations$videoControls$fa extends Translations$videoControls$en {
	_Translations$videoControls$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'صدا';
	@override String get subtitlesLabel => 'زیرنویس‌ها';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String get letterbox => 'نامه جعبه';
	@override String get fillScreen => 'صفحه نمایش پر';
	@override String get stretch => 'پر کنید';
	@override String get lockRotation => 'چرخش قفل';
	@override String get unlockRotation => 'باز کردن چرخش';
	@override String get timerActive => 'زمان فعال';
	@override String playbackWillPauseIn({required Object duration}) => 'باز کردن بازی در ${duration} استراحت می کند';
	@override String get sleepTimerEndOfVideo => 'پایان ویدئو فعلی';
	@override String get sleepTimerStopAtHeader => 'توقف در';
	@override String get sleepTimerDurationHeader => 'زمان';
	@override String get playbackWillPauseAtEnd => 'Playback در پایان این ویدئو تعطیل خواهد شد';
	@override String get stillWatching => 'هنوز هم تماشا می کنید؟';
	@override String pausingIn({required Object seconds}) => 'استراحت در ${seconds}s';
	@override String get continueWatching => 'ادامه مطلب';
	@override String get autoPlayNext => 'بازی اتوماتیک بعدی';
	@override String get playNext => 'بعدی را اجرا کن';
	@override String get playButton => 'اجرا کردن';
	@override String get pauseButton => 'مکث';
	@override String get playbackPaused => 'استراحت';
	@override String get playbackResumed => 'بازی کردن';
	@override String get loadingVideo => 'دانلود ویدئو';
	@override String get showPlaybackControls => 'نمایش کنترل های Playback';
	@override String get hidePlaybackControls => 'کنترل بازی های مخفی';
	@override String seekBackwardButton({required Object seconds}) => 'جستجو به عقب ${seconds} ثانیه';
	@override String seekForwardButton({required Object seconds}) => 'جستجو در آینده ${seconds} ثانیه';
	@override String get previousButton => 'قسمت قبلی';
	@override String get nextButton => 'قسمت بعد';
	@override String get previousChapterButton => 'بخش قبلی';
	@override String get nextChapterButton => 'بخش بعد';
	@override String get muteButton => 'سکوت';
	@override String get unmuteButton => 'صدادار';
	@override String get settingsButton => 'تنظیمات Playback';
	@override String get tracksButton => 'صدا و زیرنویس';
	@override String get chaptersButton => 'فصل ها';
	@override String get segmentLoopHelp => 'یک بخش را در طول این بازی باز کنید: A را تنظیم کنید، سپس B را بعداً در خط زمانی قرار دهید.';
	@override String get setLoopStart => 'راهکارهایی برای شروع (A)';
	@override String get setLoopEnd => 'تنظیم لوله پایان (ب)';
	@override String get clearSegmentLoop => 'مشخصات segment loop';
	@override String get setLoopStartFirst => 'شروع (A) را قبل از پایان (B) تنظیم کنید.';
	@override String get loopEndAfterStart => 'پایان حلقه باید بعد از شروع باشد.';
	@override String get segmentLoopUnavailable => 'لوله بندی بخش برای این بازی در دسترس نیست.';
	@override String get loopPointNotSet => 'نه تنظیم';
	@override String get bookmarksHelp => 'برچسب ها در این دستگاه ذخیره می شوند. یکی را انتخاب کنید تا به آن زمان بروید.';
	@override String get bookmarksButton => 'برچسب ها Bookmark';
	@override String get chaptersAndBookmarks => 'فصل ها و کتاب نشانه ها';
	@override String get segmentLoop => 'بخش لوله';
	@override String get addBookmark => 'اضافه کردن Bookmark';
	@override String get bookmarkName => 'Bookmark نام';
	@override String get bookmarkNameHint => 'به عنوان مثال، صحنه باز';
	@override String bookmarkDefaultName({required Object n}) => 'برچسب ها ${n}';
	@override String get bookmarkNameRequired => 'نام این کتاب را وارد کنید.';
	@override String get deleteBookmark => 'حذف Bookmark';
	@override String get bookmarkLimitReached => 'این مقاله در حال حاضر دارای 100 دفترچه یادداشت است.';
	@override String get bookmarkUnavailable => 'نمی توانم این کتاب را ذخیره یا حذف کنم.';
	@override String get bookmarkSaved => 'کتاب را نجات داد.';
	@override String get bookmarkDeleted => 'برچسب حذف شده است.';
	@override String loopPointSet({required Object point, required Object time}) => 'نقطه عطف ${point} تنظیم در ${time}.';
	@override String get noChaptersOrBookmarks => 'هیچ فصل و کتابی در دسترس نیست.';
	@override String get versionQualityButton => 'نسخه و کیفیت';
	@override String get versionColumnHeader => 'نسخه';
	@override String get qualityColumnHeader => 'کیفیت';
	@override String get qualityOriginal => 'اصلی';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} مگابایت در ثانیه';
	@override String get transcodeUnavailableFallback => 'Transcoding Unavailable – بازی با کیفیت اصلی';
	@override String get subtitleUnavailableFallback => 'زیرنویس های انتخاب شده نمی توانند بارگذاری شوند – ادامه بدون زیرنویس ها';
	@override String get pipButton => 'حالت تصویر در تصویر';
	@override String get aspectRatioButton => 'نسبت تصویر';
	@override String get ambientLighting => 'روشنایی محیط زیست';
	@override String get fullscreenButton => 'وارد صفحه نمایش کامل';
	@override String get exitFullscreenButton => 'خروجی صفحه نمایش کامل';
	@override String get alwaysOnTopButton => 'همیشه در بالای';
	@override String get rotationLockButton => 'قفل چرخشی';
	@override String get lockScreen => 'صفحه نمایش قفل';
	@override String get screenLockButton => 'صفحه نمایش قفل';
	@override String get timelineSlider => 'ویدئو زمان بندی';
	@override String get volumeSlider => 'حجم سطح';
	@override String endsAt({required Object time}) => 'در نهایت در ${time}';
	@override String get pipActive => 'بازی در Picture-in-Picture';
	@override String get pipFailed => 'نقاشی در نقاشی شروع نمی شود';
	@override String get screenshotSaved => 'صفحه نمایش ذخیره شده';
	@override String get screenshotFailed => 'نمی توانم یک عکس از صفحه نمایش داشته باشم';
	@override String zoomPercent({required Object percent}) => 'بزرگ‌نمایی ${percent}%';
	@override String volumePercent({required Object percent}) => 'بلندی صدا ${percent}%';
	@override late final _Translations$videoControls$pipErrors$fa pipErrors = _Translations$videoControls$pipErrors$fa._(_root);
	@override String get chapters => 'فصل ها';
	@override String get noChaptersAvailable => 'هیچ فصل در دسترس';
	@override String get queue => 'کوی';
	@override String get noQueueItems => 'هیچ موضوعی در قفسه';
	@override String get noAudioDevicesAvailable => 'هیچ دستگاه صوتی در دسترس نیست';
	@override String get searchSubtitles => 'جستجو زیرنویس';
	@override String get language => 'زبان';
	@override String get noSubtitlesFound => 'هیچ زیرنویس یافت نشد';
	@override String get subtitleDownloaded => 'دانلود زیرنویس';
	@override String get subtitleDownloadedNotApplied => 'زیرنویس دانلود شده اما انتخاب نشده است';
	@override String get subtitleDownloadFailed => 'دانلود زیرنویس را از دست ندهید';
	@override String get searchLanguages => 'زبان های جستجو...';
	@override String get skipIntro => 'کشتی وارد';
	@override String get skipCredits => 'کپی اعتبارات';
	@override String get nextEpisode => 'قسمت بعد';
	@override String subtitleTrack({required Object n}) => 'تریلر ${n}';
	@override String subtitleFile({required Object name}) => 'زیرنویس ${name}';
	@override String forcedTrack({required Object label}) => '${label} (مجاز)';
	@override String get osdSubtitlesOff => 'بایگانی برچسب ها: Off';
	@override String osdSubtitles({required Object track}) => 'برچسب ها: ${track}';
	@override String osdAudio({required Object track}) => 'صدا : ${track}';
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} فریم',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} فریم',
	);
	@override String get trackSelectionTitle => 'انتخاب مسیر قبل از بازی';
	@override String get trackSelectionAuto => 'انتخاب اتوماتیک';
	@override String get openMiniPlayer => 'باز کردن مینی بازیکن';
	@override String get returnToFullPlayer => 'بازگشت به بازیکن کامل';
	@override String get loadSubtitleFile => 'دانلود فایل زیرنویس';
	@override String get subtitleLoadFailed => 'دانلود فایل زیرنویس';
	@override String get skipAds => 'آگهی های اسکایپ';
	@override String get tapToUnlock => 'برای باز کردن قفل ضربه بزنید';
	@override String get tapAgainToUnlock => 'برای باز کردن قفل دوباره ضربه بزنید';
}

// Path: messages
class _Translations$messages$fa extends Translations$messages$en {
	_Translations$messages$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'مشخص شده به عنوان مشاهده شده';
	@override String get markedAsUnwatched => 'برچسب ها: ناشناخته';
	@override String get markedAsWatchedOffline => 'برچسب گذاری شده به عنوان مشاهده شده (در هنگام همگام سازی آنلاین)';
	@override String get markedAsUnwatchedOffline => 'علامت گذاری شده به عنوان ناشناخته (در هنگام آنلاین همگام می شود)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'اتوماتیک حذف: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} دانلود تماشاشده به‌طور خودکار حذف شد',
		other: 'دانلود رایگان دانلود رایگان دانلود رایگان دانلود رایگان ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}',
	);
	@override String get removedFromContinueWatching => 'حذف از ادامه مشاهده';
	@override String errorLoading({required Object error}) => 'خطا : ${error}';
	@override String get searchPartialResults => 'برخی از سرورهای رسانه ای نمی توانستند جستجو شوند نمایش نتایج در دسترس.';
	@override String get streamInterrupted => 'جریان متوقف شده است.بازی مطبوعاتی یا تلاش برای عقب نشینی.';
	@override String get liveStreamInterrupted => 'پخش زنده متوقف شد پخش مطبوعات به عقب نشینی.';
	@override String get fileInfoNotAvailable => 'اطلاعات فایل در دسترس نیست';
	@override String get playbackAuthenticationRequired => 'دوباره وارد سرور رسانه ها شوید تا این آیتم را بازی کنید.';
	@override String get playbackServerUnavailable => 'سرور رسانه ای در دسترس نیست، بعدا دوباره امتحان کنید.';
	@override String get playbackDataInvalid => 'سرور اطلاعات بازگردانی نادرست را بازگرداند.';
	@override String get playbackCancelled => 'Playback لغو شد';
	@override String get playbackFailed => 'بازی باز نمی تواند آغاز شود.';
	@override String playbackFailedDetail({required Object error}) => 'بازی باز نمی تواند شروع شود: ${error}';
	@override String get audioOutputFailed => 'اتصال صوتی تلویزیون یا گیرنده را بررسی کنید؛ اگر برنامه های دیگر صدا ندارند، دستگاه را دوباره راه اندازی کنید.';
	@override String get mediaUnavailable => 'این محتوا دیگر در دسترس نیست.';
	@override String errorLoadingFileInfo({required Object error}) => 'خطای بارگذاری فایل اطلاعات: ${error}';
	@override String get errorLoadingSeries => 'خطای شارژ سری';
	@override String get musicNotSupported => 'پخش موسیقی هنوز پشتیبانی نشده است';
	@override String get noDescriptionAvailable => 'هیچ توضیحی در دسترس نیست';
	@override String get noProfilesAvailable => 'هیچ پروفایل در دسترس';
	@override String get contactAdminForProfiles => 'تماس با مدیر سرور برای اضافه کردن پروفایل ها';
	@override String get unableToDetermineLibrarySection => 'نمی توانم بخش کتابخانه را برای این موضوع تعیین کنم';
	@override String get logsCleared => 'دایره ها پاک شد';
	@override String get logsCopied => 'کپی شده به clipboard';
	@override String get noLogsAvailable => 'بدون سوابق موجود';
	@override String libraryScanning({required Object title}) => 'اسکن «${title}»';
	@override String libraryScanStarted({required Object title}) => 'کتابخانه اسکن برای "${title}" آغاز شد';
	@override String libraryScanFailed({required Object error}) => 'کتابخانه را اسکن نکرد: ${error}';
	@override String metadataRefreshing({required Object title}) => 'فتوشاپ با «${title}»';
	@override String metadataRefreshStarted({required Object title}) => 'بازسازی داده های متا برای "${title}" آغاز شد';
	@override String metadataRefreshFailed({required Object error}) => 'عدم بازسازی داده های متا: ${error}';
	@override String get logoutConfirm => 'آیا مطمئن هستید که می خواهید خارج شوید؟';
	@override String get noSeasonsFound => 'هیچ فصل یافت نشد';
	@override String get seasonsLoadFailed => 'نمی توان فصل ها را بارگذاری کرد';
	@override String get noEpisodesFound => 'هیچ قسمت در فصل اول یافت نشد';
	@override String get noEpisodesFoundGeneral => 'هیچ حوادث یافت نشد';
	@override String get episodesLoadFailed => 'نمی توانم قسمت ها را شارژ کنم';
	@override String get noResultsFound => 'نتیجه‌ای یافت نشد.';
	@override String sleepTimerSet({required Object label}) => 'زمان خواب برای ${label} تنظیم شده است';
	@override String get noItemsAvailable => 'هیچ آیتم در دسترس نیست';
	@override String get failedToCreatePlayQueueNoItems => 'شکست در ایجاد یک قفسه بازی - هیچ آیتم';
	@override String failedPlayback({required Object action, required Object error}) => 'شکست خورده به ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'تغییر به یک بازیکن سازگار';
	@override String get serverLimitTitle => 'بازی شکست خورده';
	@override String get serverLimitBody => 'خطای سرور (HTTP 500) یک محدودیت پهنای باند / ترانسکود احتمالا این جلسه را رد کرده است.';
	@override String get mediaUnreadableTitle => 'فایلهای غیر قابل دسترس';
	@override String get mediaUnreadableBody => 'سرور این آیتم را پیدا کرد اما نمی توانست فایل آن را بخواند (HTTP 404). فایل احتمالا منتقل شده، حذف شده یا ذخیره آن غیرفعال است.';
	@override String get serverBusyTitle => 'جریان در دسترس نیست';
	@override String get serverBusyBody => 'سرور از پخش این فایل امتناع کرد (HTTP 503). ممکن است دوباره راه اندازی شود، شلوغ باشد، یا ذخیره سازی فایل ممکن است آفلاین باشد. دوباره در یک لحظه امتحان کنید - اگر این اتفاق می افتد، از صاحب سرور بخواهید که سرور و ذخیره سازی فایل را بررسی کند.';
	@override String get playbackNotAllowedTitle => 'Playback مجاز نیست';
	@override String get playbackNotAllowedBody => 'سرور از پخش این مورد خودداری کرد (HTTP 403). ممکن است حساب شما مجوز پخش آن را نداشته باشد، یا سرور فقط در شبکهٔ محلی خود اجازهٔ پخش بدهد.';
	@override String get logsUploaded => 'Logs بارگذاری';
	@override String get logsUploadFailed => 'شکست در بارگذاری مجلات';
	@override String get logId => 'ID ثبت نام';
	@override String get burnedSubtitlesUseMenu => 'زیرنویس ها در این جریان سوزانده می شوند. آنها را از منوی زیرنویس تغییر دهید.';
	@override String get noVideoUrl => 'هیچ URL ویدئویی در دسترس نیست';
	@override String get playbackNoMediaSources => 'سرور هیچ منبع پخش رسانه ای را بازگرداند';
	@override String get playbackDataNotPrepared => 'Playback قبل از اینکه داده های آن آماده باشد آغاز شد.';
	@override String get streamSelectionUnavailable => 'انتخاب جریان برای این منبع در دسترس نیست';
	@override String get streamSelectionFailed => 'امکان استفاده از جریان های انتخاب شده';
	@override String get trackSelectionNotRemembered => 'این گزینه فقط برای بازی های فعلی اعمال می شود.';
	@override String get serverUnavailableForProfile => 'هیچ سرور برای پروفایل فعال در دسترس نیست';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$fa extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get previewSample => 'فاکس قهوه ای سریع بر روی سگ خجالتی پرش می کند';
	@override String get text => 'متن';
	@override String get border => 'مرزها';
	@override String get background => 'پس زمینه';
	@override String get fontSize => 'حجم فونت';
	@override String get textColor => 'رنگ متن';
	@override String get borderSize => 'مرز اندازه';
	@override String get borderColor => 'مرز رنگ';
	@override String get backgroundOpacity => 'پس زمینه نابخردی';
	@override String get backgroundColor => 'رنگ پس زمینه';
	@override String get position => 'موقعیت';
	@override String get assOverride => 'ASS بیش از حد';
	@override String get overrideScale => 'مقیاس';
	@override String get overrideForce => 'نیروی';
	@override String get overrideStrip => 'حذف سبک';
	@override String get positionTop => 'بالا';
	@override String get positionBottom => 'پایین';
	@override String get useMargins => 'استفاده از مارجین';
	@override String get useMarginsDescription => 'اجازه دهید زیرنویس های متنی در فضای خارج از ویدئو قرار بگیرند. زیرنویس های سبک می توانند موقعیت اصلی خود را حفظ کنند.';
	@override String get anchorToScreen => 'آکاایران به صفحه نمایش';
	@override String get anchorToScreenDescription => 'نمایش زیرنویس های متن در نوار سیاه زیر ویدئو صفحه نمایش';
	@override String get bold => 'درشت';
	@override String get italic => 'ایتالیایی';
	@override String get renderResolution => 'رندر حل';
	@override String get renderResolutionScreen => 'صفحه نمایش رزولوشن';
	@override String get renderResolutionVideo => 'کیفیت ویدیو';
	@override String get fontSizeDescription => 'اندازه زیرنویس متن را در این دستگاه تنظیم کنید.';
	@override String get textColorDescription => 'رنگ مورد استفاده برای زیرنویس را انتخاب کنید.';
	@override String get borderSizeDescription => 'ضخامت خروجی را در اطراف متن زیرنویس تنظیم کنید.';
	@override String get borderColorDescription => 'رنگ مورد استفاده برای زیرنویس را انتخاب کنید.';
	@override String get backgroundColorDescription => 'رنگ پشت زیرنویس را انتخاب کنید.';
	@override String get backgroundOpacityDescription => 'تنظیم چگونگی شفاف بودن پس زمینه زیرنویس: 0٪ روشن است و 100٪ جامد است.';
	@override String get positionDescription => 'زیرنویس ها را به صورت عمودی حرکت دهید 0٪ در بالای ویدئو و 100٪ در پایین است.';
	@override String get assOverrideDescription => 'انتخاب کنید که آیا بازیکن به دنبال، تنظیم، جایگزین و یا حذف سبک در زیرنویس های ASS.';
	@override late final _Translations$subtitlingStyling$assOverrideOptions$fa assOverrideOptions = _Translations$subtitlingStyling$assOverrideOptions$fa._(_root);
	@override String get renderResolutionDescription => 'رزولوشن مورد استفاده برای rasterize تصویر و ASS زیرنویس ها را انتخاب کنید مقیاس های اندروید پایین تر می تواند کار راندینگ را کاهش دهد اما نرم تر به نظر می رسد.';
	@override late final _Translations$subtitlingStyling$renderResolutionOptions$fa renderResolutionOptions = _Translations$subtitlingStyling$renderResolutionOptions$fa._(_root);
	@override String get boldDescription => 'متن زیرنویس را در وزن سنگین تر بشویید.';
	@override String get italicDescription => 'متن زیرنویس را در ایتالیایی بنویسید.';
}

// Path: mpvConfig
class _Translations$mpvConfig$fa extends Translations$mpvConfig$en {
	_Translations$mpvConfig$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'تنظیمات پیشرفته پخش ویدئو';
	@override String get presets => 'پیشگویی';
	@override String get noPresets => 'هیچ پیشگویی نجات یافت';
	@override String get saveAsPreset => 'به عنوان پیش بینی...';
	@override String get presetName => 'نام پیشین';
	@override String get presetNameHint => 'یک نام برای این پیش فرض وارد کنید.';
	@override String get loadPreset => 'بارگذاری';
	@override String get deletePreset => 'حذف';
	@override String get presetSaved => 'پیشگام نجات یافت';
	@override String get presetLoaded => 'پیش فرض بارگذاری';
	@override String get presetDeleted => 'پیش بینی حذف';
	@override String get confirmDeletePreset => 'آیا مطمئن هستید که می خواهید این پیش فرض را حذف کنید؟';
	@override String get configPlaceholder => 'gpu-api=vulkan hwdec=auto # نظرات';
	@override String get lineHint => 'option=value';
	@override String get addLine => 'اضافه کردن خط';
	@override String get removeLine => 'حذف خط';
	@override String get embeddedVoHint => 'vo، gpu-context و gpu-api در Linux نادیده گرفته می شود: ویدئو درخشان همیشه از طریق vo=libmpv در برنامه ویدئویی پخش می شود و gpu-next (که سایه های محاسباتی مانند ArtCNN نیاز دارد) نمی تواند درخشان اجرا شود.';
}

// Path: dialog
class _Translations$dialog$fa extends Translations$dialog$en {
	_Translations$dialog$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'تأیید عمل';
}

// Path: profiles
class _Translations$profiles$fa extends Translations$profiles$en {
	_Translations$profiles$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'اضافه کردن پروفایل PlezyNG';
	@override String get switchingProfile => 'تغییر پروفایل...';
	@override String get deleteThisProfileTitle => 'این پروفایل را حذف کنید؟';
	@override String deleteThisProfileMessage({required Object displayName}) => 'حذف ${displayName}. اتصالات تحت تاثیر قرار نمی گیرد.';
	@override String get active => 'فعال';
	@override String get manage => 'مدیریت';
	@override String get delete => 'حذف';
	@override String get signOut => 'خارج شدن';
	@override String get signOutPlexTitle => 'ثبت نام از Plex؟';
	@override String signOutPlexMessage({required Object displayName}) => 'حذف ${displayName} و همه Plex کاربران خانگی؟ ثبت نام در هر زمان.';
	@override String get signOutPlexDeleteDownloads => 'همچنین دانلود دانلود ها';
	@override String get signOutPlexDeleteDownloadsDescription => 'در غیر این صورت آنها در این دستگاه باقی می مانند و زمانی که شما دوباره وارد این حساب می شوید، باز می گردند.';
	@override String get signedOutPlex => 'ثبت شده از Plex.';
	@override String get signOutFailed => 'ثبت نام شکست خورده';
	@override String get sectionTitle => 'پروفایل ها';
	@override String get summarySingle => 'اضافه کردن پروفایل ها برای مخلوط کردن کاربران مدیریت شده و هویت های محلی';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} پروفایل · فعال: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} مشخصات';
	@override String get removeConnectionTitle => 'اتصال را حذف کنید؟';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'حذف دسترسی ${displayName} به ${connectionLabel}. پروفایل های دیگر آن را نگه دارید.';
	@override String get deleteProfileTitle => 'پروفایل را حذف کنید؟';
	@override String deleteProfileMessage({required Object displayName}) => 'حذف ${displayName} و اتصالات آن. سرورها در دسترس باقی می ماند.';
	@override String get profileNameLabel => 'نام پروفایل';
	@override String get pinProtectionLabel => 'حفاظت PIN';
	@override String get copyAutomationLink => 'کپی Android اتوماسیون لینک';
	@override String get copyAutomationLinkDescription => 'این پروفایل را از یک هدف یا اتوماسیون Android انتخاب کنید.پروفیل PIN چک ها هنوز هم اعمال می شود.';
	@override String get automationLinkCopied => 'پروفایل اتوماسیون لینک کپی شده';
	@override String get pinManagedByPlex => 'PIN مدیریت شده توسط Plex. Edit on plex.tv.';
	@override String get noPinSetEditOnPlex => 'برای نیاز به یک، ویرایش کاربر خانگی در plex.tv.';
	@override String get setPin => 'PIN را تنظیم کنید';
	@override String get setPinTitle => 'PIN را تنظیم کنید';
	@override String get confirmPinTitle => 'تایید PIN';
	@override String get pinSet => 'PIN تنظیم شده';
	@override String get changePin => 'تغییر';
	@override String get removePin => 'حذف';
	@override String get connectionsLabel => 'ارتباطات';
	@override String get add => 'افزودن';
	@override String get deleteProfileButton => 'حذف پروفایل';
	@override String get noConnectionsHint => 'هیچ اتصال - اضافه کردن یکی برای استفاده از این پروفایل.';
	@override String get noConnections => 'هیچ ارتباطی';
	@override String get plexHomeAccount => 'Plex حساب خانگی';
	@override String plexAccountChip({required Object account}) => 'Plex حساب: ${account}';
	@override String plexAccountUserChip({required Object user, required Object account}) => '${user} از طریق ${account}';
	@override String get connectionDefault => 'پیشفرض';
	@override String connectionAs({required Object displayName}) => 'به عنوان ${displayName}';
	@override String get makeDefault => 'فایرفاکس';
	@override String get removeConnection => 'حذف';
	@override String get profileRenamed => 'نام پروفایل';
	@override String borrowAddTo({required Object displayName}) => 'اضافه کردن به ${displayName}';
	@override String get borrowExplain => 'وام دادن به یک پروفایل دیگر. پروفایل های محافظت شده از PIN نیاز به یک PIN.';
	@override String get borrowEmpty => 'هنوز چیزی برای وام گرفتن ندارم.';
	@override String get borrowEmptySubtitle => 'برای اولین بار Plex، Jellyfin یا Emby را به یک پروفایل دیگر متصل کنید.';
	@override String get borrowLoadFailed => 'اتصالات در دسترس نمی توانند بارگذاری شوند. دوباره امتحان کنید.';
	@override String borrowFromProfile({required Object displayName}) => 'از ${displayName}';
	@override String get borrowConnectionBorrowed => 'اتصال قرض گرفته شده است.';
	@override String get borrowFailed => 'وام گرفتن را شکست داد.';
	@override String get incorrectPin => 'PIN نادرست';
	@override String get incorrectPinTryAgain => 'PIN نادرست است لطفا دوباره امتحان کنید.';
	@override String get sourceProfileMissingParentAccount => 'منبع پروفایل خود را از دست داده است حساب مادر خود را.';
	@override String get failedToLoadHomeUsers => 'نمی توانم کاربران خانگی Plex خود را بارگذاری کنم. اتصال خود را بررسی کنید و دوباره امتحان کنید.';
	@override String get failedToVerifyPin => 'PIN را تایید نکردم';
	@override String get newProfile => 'پروفایل جدید';
	@override String get profileNameHint => 'به عنوان مثال: مهمانان، کودکان، اتاق های خانوادگی';
	@override String get pinProtectionOptional => 'حفاظت از PIN (اختیاری)';
	@override String get pinExplain => '4 عدد PIN برای تغییر پروفایل ها';
	@override String get continueButton => 'ادامه مطلب';
	@override String get pinsDontMatch => 'PIN ها مطابقت ندارند';
	@override String get tokenIdentityMismatch => 'سکه پروفایل Plex به یک سرور غیرمنتظره حل شد';
	@override String get settingsLocked => 'تنظیمات برای این پروفایل قفل شده است.';
	@override String get unlockSettings => 'تنظیمات Unlock';
	@override String get showExploreForProfile => 'نمایش جستجو برای این پروفایل';
	@override String get showExploreForProfileDescription => 'برای حذف Explore از ناوبری این پروفایل خاموش شوید.';
}

// Path: connections
class _Translations$connections$fa extends Translations$connections$en {
	_Translations$connections$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'ارتباطات';
	@override String get addConnection => 'اضافه کردن اتصال';
	@override String get addConnectionSubtitleNoProfile => 'با Plex وارد شوید یا به یک سرور Jellyfin یا Emby متصل شوید.';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'اضافه کردن به ${displayName}: Plex، Jellyfin، Emby، یا سایر لینک های پروفایل';
	@override String sessionExpiredOne({required Object name}) => 'تاریخ انقضا برای ${name}';
	@override String sessionExpiredMany({required Object count}) => 'جلسه برای سرورهای ${count} به پایان رسید';
	@override String accessDeniedOne({required Object name}) => '${name} دسترسی به این حساب را رد کرد';
	@override String accessDeniedMany({required Object count}) => '${count} سرورها دسترسی به این حساب را رد کردند';
	@override String get signInAgain => 'دوباره وارد شوید';
	@override String editMediaBrowserTitle({required Object product}) => 'ویرایش ${product} اتصال';
	@override String editMediaBrowserIntro({required Object serverName}) => 'اضافه کردن یا حذف URL برای ${serverName}. PlezyNG از URL قابل دسترسی با پایین ترین تاخیر استفاده می کند.';
}

// Path: accountPreferences
class _Translations$accountPreferences$fa extends Translations$accountPreferences$en {
	_Translations$accountPreferences$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'حسابداری ترجیحات';
	@override String hubSubtitleSingle({required Object account}) => 'گزینه های صوتی، زیرنویس و کتابخانه در ${account} ذخیره شده است';
	@override String hubSubtitleMultiple({required Object count}) => 'گزینه های صوتی، زیرنویس و کتابخانه در حساب های ${count} ذخیره شده است';
	@override String get pickAccount => 'هر حساب ذخیره ترجیحات خود را. انتخاب یکی برای ویرایش.';
	@override String get storedOnAccount => 'این گزینه ها در حساب خود ذخیره می شوند، بنابراین هر اپلیکیشن ثبت نام شده در آن از آنها استفاده می کند – از جمله PlezyNG در سایر دستگاه های شما.';
	@override String get noAccounts => 'هیچ حساب برای تنظیم';
	@override String get noAccountsHint => 'ثبت نام در Plex یا اتصال به یک سرور Jellyfin یا Emby، و ترجیحات ذخیره شده در آن حساب در اینجا نشان داده شده است.';
	@override String get unavailable => 'نمی توانم به این حساب دسترسی داشته باشم';
	@override String get loadFailed => 'نمی توانم این ترجیحات را بارگذاری کنم';
	@override String get noPreference => 'هیچ ترجیح';
	@override String get notSet => 'نه تنظیم';
	@override late final _Translations$accountPreferences$groups$fa groups = _Translations$accountPreferences$groups$fa._(_root);
	@override String get preferredAudioLanguage => 'اولویت زبان صدا';
	@override String get autoSelectAudio => 'صدا را با زبان انتخاب کنید';
	@override String get autoSelectAudioDescription => 'حذف هر گونه ردیابی صوتی فایل به عنوان پیش فرض نشان داده شده است.';
	@override String get preferredSubtitleLanguage => 'زبان زیرنویس ترجیحی';
	@override String get subtitleMode => 'زیرنویس ها را روی';
	@override late final _Translations$accountPreferences$subtitleModes$fa subtitleModes = _Translations$accountPreferences$subtitleModes$fa._(_root);
	@override String get subtitleAccessibility => 'SDH زیرنویس';
	@override late final _Translations$accountPreferences$subtitleAccessibilityOptions$fa subtitleAccessibilityOptions = _Translations$accountPreferences$subtitleAccessibilityOptions$fa._(_root);
	@override String get forcedSubtitles => 'زیرنویس های اجباری';
	@override late final _Translations$accountPreferences$forcedSubtitleOptions$fa forcedSubtitleOptions = _Translations$accountPreferences$forcedSubtitleOptions$fa._(_root);
	@override String get displayMissingEpisodes => 'نمایش قسمت های ناپدید شده';
	@override String get displayMissingEpisodesDescription => 'قسمت های لیست که سرور در مورد آن می داند اما هیچ فایل برای آن ندارد.';
	@override String get hidePlayedInLatest => 'پنهان کردن اشیاء مشاهده شده در آخرین';
	@override String get hidePlayedInLatestDescription => 'آیتم هایی را که قبلاً مشاهده کرده اید از آخرین ردیف های سرور خارج کنید.';
	@override String get displayCollectionsView => 'نمایش نمایش مجموعه ها';
	@override String get displayCollectionsViewDescription => 'نمایش مجموعه های سرور را در کنار کتابخانه های خود ارائه دهید.';
	@override String get rewatchingInNextUp => 'ادامه مطلب ادامه مطلب ادامه مطلب ادامه مطلب';
	@override String get rewatchingInNextUpDescription => 'هنگامی که یک نمایش را به پایان می رسانید، آن را دوباره شروع کنید و Next Up به جای اینکه نمایش را از بین ببرد، نظارت را دنبال می کند.';
	@override String get watchedIndicator => 'شاخص های مشاهده شده';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$fa watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$fa._(_root);
	@override String get mediaReviewsVisibility => 'رتبه بندی و بررسی';
	@override late final _Translations$accountPreferences$mediaReviewsOptions$fa mediaReviewsOptions = _Translations$accountPreferences$mediaReviewsOptions$fa._(_root);
	@override String get preferredAudioLanguageDescription => 'ترجیح می دهم ردیف های صوتی در این زبان زمانی که سرور یا پخش کننده به طور خودکار یک ردیف را انتخاب می کند.';
	@override String get preferredSubtitleLanguageDescription => 'ترجیح می دهم زیرنویس ها را در این زبان ردیابی کنید، زمانی که زیرنوی ها به طور خودکار انتخاب می شوند.';
	@override String get subtitleAccessibilityDescription => 'انتخاب کنید که آیا پوشش های SDH ترجیح داده شده یا مورد نیاز در هنگام انتخاب زیرنویس خودکار است.';
	@override String get forcedSubtitleDescription => 'انتخاب کنید که آیا ردیف های زیر عنوان اجباری ترجیح داده شده یا مورد نیاز در هنگام انتخاب اتوماتیک است.';
	@override String get watchedIndicatorDescription => 'انتخاب کنید که کدام نوع رسانه ها یک علامت چک مشاهده شده را در رابط سرور دریافت می کنند.';
	@override String get mediaReviewsVisibilityDescription => 'انتخاب کنید که کدام مخاطبان و رتبه های انتقادی سرور در صفحات رسانه ها نمایش داده می شود.';
	@override String get subtitleModeDescription => 'انتخاب زمانی که زیرنویس ها به طور خودکار برای این حساب سرور فعال می شوند.';
	@override String get hubDescription => 'این ترجیحات در حساب سرور رسانه شما ذخیره می شوند و ممکن است برای سایر مشتریان نیز اعمال شود.';
}

// Path: discover
class _Translations$discover$fa extends Translations$discover$en {
	_Translations$discover$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'کشف';
	@override String get noContentAvailable => 'بدون محتوای موجود';
	@override String get addMediaToLibraries => 'برخی از رسانه ها را به کتابخانه های خود اضافه کنید';
	@override String get continueWatching => 'ادامه تماشا';
	@override String continueWatchingIn({required Object library}) => 'ادامه مشاهده در ${library}';
	@override String get nextUp => 'بعدی چیه';
	@override String nextUpIn({required Object library}) => 'بعدی در ${library}';
	@override String get recentlyAdded => 'جدیدترین‌ها';
	@override String recentlyAddedIn({required Object library}) => 'به تازگی در ${library} اضافه شده است';
	@override String latestAlbumsIn({required Object library}) => 'آخرین آلبوم ها در ${library}';
	@override String recentlyPlayedIn({required Object library}) => 'بازی شده در ${library}';
	@override String mostPlayedIn({required Object library}) => 'بیشترین تعداد بازی ها در ${library}';
	@override String playEpisode({required Object season, required Object episode}) => 'ف${season} ق${episode}';
	@override String get overview => 'نمای کلی';
	@override String get cast => 'کاست';
	@override late final _Translations$discover$findNext$fa findNext = _Translations$discover$findNext$fa._(_root);
	@override String get extras => 'تریلر و اضافی';
	@override String get studio => 'استودیو';
	@override String get rating => 'رتبه بندی';
	@override String get director => 'کارگردان';
	@override String get directors => 'کارگردانان';
	@override String get movie => 'فیلم';
	@override String get tvShow => 'نمایش تلویزیونی';
	@override String minutesLeft({required Object minutes}) => '${minutes} دقیقه باقی مانده';
	@override String get moreLikeThis => 'موارد مشابه با این';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} عنوان',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} عنوان ها',
	);
	@override late final _Translations$discover$person$fa person = _Translations$discover$person$fa._(_root);
}

// Path: errors
class _Translations$errors$fa extends Translations$errors$en {
	_Translations$errors$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'جستجو شکست خورده: ${error}';
	@override String get searchUnavailable => 'جستجو نمی تواند به هیچ سرور رسانه ای دسترسی داشته باشد.';
	@override String connectionTimeout({required Object context}) => 'زمان اتصال در هنگام بارگذاری ${context}';
	@override String get connectionFailed => 'عدم امکان اتصال به سرورهای رسانه ای';
	@override String unableToLoad({required Object context}) => 'قابل بارگذاری نیست ${context}.لطفا دوباره امتحان کنید.';
	@override String get noClientAvailable => 'هیچ مشتری در دسترس نیست';
	@override String get pleaseEnterToken => 'لطفا یک توکن وارد کنید.';
	@override String get invalidToken => 'توکین نادرست';
	@override String failedToVerifyToken({required Object error}) => 'عدم تایید توکن: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'عدم تغییر به ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'حذف ناپذیر ${displayName}';
	@override String get failedToRate => 'نمی توانم رتبه بندی را به روز کنم';
	@override String get reasonTimedOut => 'اتصال به زمان مشخص شد';
	@override String get reasonUnreachable => 'سرور نمی تواند به دست آورد';
	@override String get reasonRefused => 'سرور درخواست را رد کرد';
	@override String get reasonNotFound => 'در حال حاضر در سرور نیست.';
	@override String get reasonServerError => 'سرور یک خطا را شناسایی کرد';
	@override String get reasonCancelled => 'درخواست لغو شد';
	@override String get reasonUnexpected => 'یک اشتباه غیرمنتظره رخ داد.';
}

// Path: libraries
class _Translations$libraries$fa extends Translations$libraries$en {
	_Translations$libraries$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => 'بازی یک فیلم تصادفی';
	@override String get randomPickFailed => 'من نمی توانم یک فیلم تصادفی را از این کتابخانه انتخاب کنم.';
	@override String get title => 'کتابخانه‌ها';
	@override String get fallbackTitle => 'کتابخانه';
	@override String get scanLibraryFiles => 'اسکن کتابخانه فایل ها';
	@override String get scanLibrary => 'کتابخانه را اسکن کنید';
	@override String get analyze => 'تحلیل';
	@override String get analyzeLibrary => 'تجزیه و تحلیل کتابخانه';
	@override String get refreshMetadata => 'تازه کردن متادیتا';
	@override String get emptyTrash => 'تریش خالی';
	@override String emptyingTrash({required Object title}) => 'در این مطلب به نقل از «${title}» می پردازیم.';
	@override String trashEmptied({required Object title}) => 'تریلر جدید «${title}»';
	@override String failedToEmptyTrash({required Object error}) => 'ناپدید شدن زباله خالی: ${error}';
	@override String analyzing({required Object title}) => 'در این مقاله به بررسی «${title}» می پردازیم.';
	@override String analysisStarted({required Object title}) => 'تحلیل برای "${title}" آغاز شد';
	@override String failedToAnalyze({required Object error}) => 'عدم تحلیل کتابخانه: ${error}';
	@override String get noLibrariesFound => 'هیچ کتابخانه ای یافت نشد';
	@override String get allLibrariesHidden => 'همه کتابخانه ها پنهان هستند';
	@override String hiddenLibrariesCount({required Object count}) => 'کتابخانه های پنهان (${count})';
	@override String get thisLibraryIsEmpty => 'این کتابخانه خالی است';
	@override String get noItemsMatchFilters => 'هیچ محصولی با فیلترهای فعال مطابقت ندارد';
	@override String get resetFilters => 'بازسازی فیلترها';
	@override String get all => 'همه';
	@override String get clearAll => 'همه چیز روشن';
	@override String scanLibraryConfirm({required Object title}) => 'آیا مطمئن هستید که می خواهید "${title}" را اسکن کنید؟';
	@override String analyzeLibraryConfirm({required Object title}) => 'آیا مطمئن هستید که می خواهید "${title}" را تجزیه و تحلیل کنید؟';
	@override String refreshMetadataConfirm({required Object title}) => 'آیا مطمئن هستید که می خواهید داده های متا را برای "${title}" به روز کنید؟';
	@override String emptyTrashConfirm({required Object title}) => 'آیا مطمئن هستید که می خواهید زباله خالی را برای "${title}" خالی کنید؟';
	@override String get manageLibraries => 'مدیریت کتابخانه ها';
	@override String get sort => 'مرتب سازی';
	@override String get sortBy => 'مسیر را انتخاب کنید';
	@override String get filters => 'صافی‌ها';
	@override String get confirmActionMessage => 'آیا مطمئن هستید که می خواهید این عمل را انجام دهید؟';
	@override String get showLibrary => 'نمایش کتابخانه';
	@override String get hideLibrary => 'کتابخانه پنهان';
	@override String get libraryOptions => 'گزینه های کتابخانه';
	@override String get content => 'محتوای کتابخانه';
	@override String get selectLibrary => 'انتخاب کتابخانه';
	@override String filtersWithCount({required Object count}) => 'فیلترها (${count})';
	@override String get noRecommendations => 'بدون توصیه در دسترس';
	@override String get noCollections => 'هیچ مجموعه ای در این کتابخانه وجود ندارد';
	@override String get noFoldersFound => 'هیچ پوشه ای یافت نشد';
	@override String get folders => 'پوشه‌ها';
	@override late final _Translations$libraries$tabs$fa tabs = _Translations$libraries$tabs$fa._(_root);
	@override late final _Translations$libraries$groupings$fa groupings = _Translations$libraries$groupings$fa._(_root);
	@override late final _Translations$libraries$filterCategories$fa filterCategories = _Translations$libraries$filterCategories$fa._(_root);
	@override late final _Translations$libraries$sortLabels$fa sortLabels = _Translations$libraries$sortLabels$fa._(_root);
	@override late final _Translations$libraries$advancedFilters$fa advancedFilters = _Translations$libraries$advancedFilters$fa._(_root);
	@override late final _Translations$libraries$selection$fa selection = _Translations$libraries$selection$fa._(_root);
}

// Path: about
class _Translations$about$fa extends Translations$about$en {
	_Translations$about$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'درباره';
	@override String get openSourceLicenses => 'مجوز منبع باز';
	@override String versionLabel({required Object version}) => 'نسخه ${version}';
	@override String get appDescription => 'یک مشتری زیبا Plex، Jellyfin و Emby برای Flutter';
	@override String get viewLicensesDescription => 'مشاهده مجوزهای کتابخانه های شخص ثالث';
	@override String get privacyPolicy => 'سیاست حفظ حریم خصوصی';
}

// Path: serverSelection
class _Translations$serverSelection$fa extends Translations$serverSelection$en {
	_Translations$serverSelection$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'هیچ سرور برای ${username} (${email}) یافت نشد';
	@override String failedToLoadServers({required Object error}) => 'سرورهای بارگذاری نشده: ${error}';
	@override String get noValidServers => 'هیچ سرور قابل استفاده در این حساب یافت نشد';
}

// Path: hubDetail
class _Translations$hubDetail$fa extends Translations$hubDetail$en {
	_Translations$hubDetail$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'عنوان';
	@override String get releaseYear => 'سال انتشار';
	@override String get dateAdded => 'تاریخ اضافه شده';
	@override String get rating => 'رتبه بندی';
	@override String get noItemsFound => 'هیچ آیتم یافت نشد';
}

// Path: logs
class _Translations$logs$fa extends Translations$logs$en {
	_Translations$logs$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'مشخصات Logs';
	@override String get copyLogs => 'کپی کردن Logs';
	@override String get uploadLogs => 'دانلود Logs';
	@override String get saveLogs => 'ذخیره فایل ها به فایل ها';
	@override String logsSaved({required Object path}) => 'ثبت نام در ${path}';
	@override String get saveLogsFailed => 'نمی توانم فایل را ذخیره کنم.';
}

// Path: startup
class _Translations$startup$fa extends Translations$startup$en {
	_Translations$startup$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'PlezyNG نمی تواند شروع شود';
	@override String get failedBody => 'چیزی در هنگام راه اندازی اشتباه شد. جزئیات زیر نشان می دهد که چه چیزی شکست خورده است.';
	@override String get failedBodyRepairable => 'فایل تنظیمات ذخیره‌شدهٔ PlezyNG آسیب دیده است و باید پیش از شروع برنامه بازسازی شود. تلاش دوباره کمکی نمی‌کند؛ «تعمیر فضای ذخیره‌سازی» را انتخاب کنید.';
	@override String get phaseLabel => 'قدم';
	@override String get showDetails => 'نمایش جزئیات';
	@override String get hideDetails => 'پنهان کردن جزئیات';
	@override String get copyDetails => 'کپی جزئیات';
	@override String get detailsCopied => 'جزئیات کپی شده به clipboard';
	@override String get uploadDetails => 'اضافه کردن جزئیات';
	@override String get repairStorage => 'تعمیر ذخیره سازی';
	@override String get repairTitle => 'اصلاح داده های ذخیره شده؟';
	@override String get repairBodyCommon => 'فایل تنظیمات PlezyNG آسیب دیده و قابل خواندن نیست. تعمیر، همهٔ تنظیمات را به مقدار پیش‌فرض برمی‌گرداند.';
	@override String get repairBodyOneCredential => 'اطلاعات یکی از ورودهای ذخیره‌شده آسیب دیده و قابل خواندن نیست. تعمیر فقط همان مورد را حذف می‌کند؛ سایر تنظیمات شما تغییر نمی‌کنند.';
	@override String get repairBodySignInsKept => 'ورود شما به سرورها و نمایه‌ها باید حفظ شود.';
	@override String get repairBodySignInsLost => 'کلیدی که از اطلاعات ورود ذخیره‌شده محافظت می‌کند از این فایل قابل بازیابی نیست، پس باید دوباره به هر سرور و نمایه وارد شوید. هیچ چیز در سرور رسانهٔ شما تغییر نمی‌کند.';
	@override String get repairBodySessionsUncertain => 'اطلاعات سرویس‌های پیگیری (MAL، AniList، Simkl، Trakt) و Seerr جداگانه ذخیره می‌شود و ممکن است باقی بماند یا از دست برود. PlezyNG دقیقاً به شما می‌گوید چه اطلاعاتی حفظ شده است.';
	@override String get repairConfirm => 'اصلاحات';
	@override String get repairSucceeded => 'ذخیره سازی اصلاح شده';
	@override String get repairNeedsRestart => 'ذخیره سازی اصلاح شده – نیاز به راه اندازی مجدد';
	@override String get restartRequiredBody => 'داده‌های شما تعمیر شد، اما برای استفاده از آن‌ها باید PlezyNG دوباره راه‌اندازی شود. PlezyNG را ببندید و دوباره باز کنید.';
	@override String get quitPlezy => 'آگهی PlezyNG';
	@override String get repairFailed => 'اصلاح شکست خورده';
	@override String get repairKeptSignIns => 'همچنان به سرورها و نمایه‌های خود وارد هستید.';
	@override String get repairLostSignIns => 'کلیدی که از اطلاعات ورود ذخیره‌شده محافظت می‌کند قابل بازیابی نیست. باید دوباره به هر سرور و نمایه وارد شوید.';
	@override String get repairLostSessions => 'حداقل یک ردیاب یا اتصال Seerr از دست رفته است و باید دوباره متصل شود.';
	@override String get backupTitle => 'یک کپی از فایل آسیب دیده حفظ شده است';
	@override String get backupWarning => 'این نسخه حاوی اطلاعات ورود شماست. آن را بارگذاری یا به اشتراک نگذارید.';
	@override String get deleteBackup => 'حذف کپی';
	@override String get backupDeleted => 'کپی حذف شده';
	@override String get previousFailureTitle => 'PlezyNG آخرین بار شروع نشد';
}

// Path: licenses
class _Translations$licenses$fa extends Translations$licenses$en {
	_Translations$licenses$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'بسته های مرتبط';
	@override String get license => 'مجوز';
	@override String licenseNumber({required Object number}) => 'مجوز ${number}';
	@override String licensesCount({required Object count}) => '${count} مجوز';
}

// Path: navigation
class _Translations$navigation$fa extends Translations$navigation$en {
	_Translations$navigation$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'کتابخانه‌ها';
	@override String get downloads => 'بارگیری‌ها';
	@override String get liveTv => 'تلویزیون زنده';
	@override String get explore => 'کشف';
}

// Path: explore
class _Translations$explore$fa extends Translations$explore$en {
	_Translations$explore$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override late final _Translations$explore$mdblistShelves$fa mdblistShelves = _Translations$explore$mdblistShelves$fa._(_root);
	@override String get title => 'کشف';
	@override String get selectSource => 'انتخاب منبع';
	@override late final _Translations$explore$rows$fa rows = _Translations$explore$rows$fa._(_root);
	@override late final _Translations$explore$status$fa status = _Translations$explore$status$fa._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} قسمت',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} قسمت ها',
	);
	@override String get cast => 'کاست';
	@override String get characters => 'شخصیت ها';
	@override String get addToWatchlist => 'اضافه کردن به Watchlist';
	@override String get removeFromWatchlist => 'حذف از Watchlist';
	@override String get addedToWatchlist => 'اضافه شده به watchlist';
	@override String get removedFromWatchlist => 'حذف از لیست نظارت';
	@override String get watchlistUpdateFailed => 'نمی توانم لیست نظارت را به روز کنم';
	@override String get watchlistNoMatch => 'نمی توانم این موضوع را با یک لیست تماشاگر مطابقت داشته باشم';
	@override String get notInLibrary => 'نه در کتابخانه شما';
	@override String get inTheseLibraries => 'در این کتابخانه ها';
	@override String get checkingLibrary => 'کتابخانه خود را بررسی کنید.';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n,
		one: 'نمی توانم سرور ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} را چک کنم',
		other: 'نمی توانم ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} سرورها را چک کنم',
	);
	@override String get emptyTitle => 'هنوز چیزی در اینجا نیست';
	@override String emptyMessage({required Object source}) => 'خطوط از ${source} در اینجا ظاهر خواهد شد هنگامی که آنها محتوا دارند.';
	@override String searchHint({required Object source}) => 'جستجو ${source}';
	@override String searchEmpty({required Object query}) => 'نتایج جستجو برای "${query}"';
	@override String searchPrompt({required Object source}) => 'جستجو برای فیلم ها و نمایش ها در ${source}';
	@override String get searchFailed => 'جستجو شکست خورده است، اتصال خود را بررسی کنید و دوباره امتحان کنید.';
	@override late final _Translations$explore$badge$fa badge = _Translations$explore$badge$fa._(_root);
	@override late final _Translations$explore$stats$fa stats = _Translations$explore$stats$fa._(_root);
	@override late final _Translations$explore$season$fa season = _Translations$explore$season$fa._(_root);
	@override late final _Translations$explore$format$fa format = _Translations$explore$format$fa._(_root);
	@override late final _Translations$explore$sourceMaterial$fa sourceMaterial = _Translations$explore$sourceMaterial$fa._(_root);
	@override late final _Translations$explore$creditRole$fa creditRole = _Translations$explore$creditRole$fa._(_root);
	@override late final _Translations$explore$relation$fa relation = _Translations$explore$relation$fa._(_root);
	@override String broadcast({required Object day, required Object time}) => 'Airs ${day} در ${time}';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => 'Airs ${day} در ${time} ${timezone}';
	@override late final _Translations$explore$detail$fa detail = _Translations$explore$detail$fa._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} نتیجه',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} نتایج',
	);
}

// Path: liveTv
class _Translations$liveTv$fa extends Translations$liveTv$en {
	_Translations$liveTv$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'تلویزیون زنده';
	@override String get guide => 'راهنما';
	@override String get noChannels => 'هیچ کانال در دسترس';
	@override String get noDvr => 'هیچ DVR در هر سرور تنظیم نشده است';
	@override String get serverUnavailable => 'سرور تلویزیون زنده در دسترس نیست.';
	@override String get serverNotConnected => 'سرور تلویزیون زنده متصل نیست.';
	@override String get noPrograms => 'هیچ اطلاعات برنامه در دسترس نیست';
	@override String get liveStreamFailed => 'جریان زنده شکست خورده';
	@override String get unknownProgram => 'برنامه ناشناخته';
	@override String get timelineLiveProgram => 'برنامه زنده (برای بازی ممکن است خارج از این برنامه باشد)';
	@override String get timelineBuffer => 'زمانبندی بوفر';
	@override String get timelineUnavailable => 'جدول زمانی در دسترس نیست';
	@override String get timelineEstimated => 'دانلود بازی Playback';
	@override String get timelinePending => 'در جستجوی';
	@override String get timelineStale => 'برنامه ممکن است قدیمی شود';
	@override String get unknownHub => 'ناشناخته';
	@override String get unknownError => 'اشتباه ناشناخته';
	@override String channelNumber({required Object number}) => 'کانال ${number}';
	@override String get unknownChannel => 'کانال ناشناخته';
	@override String get live => 'پخش زنده';
	@override String get premiereBadge => 'جدید';
	@override String get reloadGuide => 'راهنمای بارگذاری';
	@override String get searchGuide => 'راهنمای جستجو';
	@override String get searchHint => 'کانال ها و برنامه های جستجو';
	@override String searchNoResults({required Object query}) => 'هیچ مسابقه ای برای «${query}» وجود ندارد';
	@override String get channelsSection => 'کانالها';
	@override String get programsSection => 'برنامه ها';
	@override String get now => 'اکنون';
	@override String get today => 'امروز';
	@override String get tomorrow => 'فردا';
	@override String get midnight => 'نیمه شب';
	@override String get overnight => 'شب ها';
	@override String get morning => 'صبحگاهی';
	@override String get daytime => 'زمان روز';
	@override String get evening => 'شب ها';
	@override String get lateNight => 'شب دیر';
	@override String get whatsOn => 'چه چیزی در';
	@override String get watchChannel => 'تماشای کانال';
	@override String get favorites => 'مورد علاقه‌ها';
	@override String get reorderFavorites => 'دانلود محبوبیت ها';
	@override String get noFavoriteChannels => 'کانال های مورد علاقه';
	@override String get noFavoriteChannelsHint => 'تمام کانال ها را نشان دهید، سپس یک کانال را برای اضافه کردن آن به محبوبیت های خود فشار دهید.';
	@override String get showAllChannels => 'نمایش همه کانال ها';
	@override String get favoritesLoadFailed => 'نمی توانم مورد علاقه خود را بارگذاری کنم، اتصال خود را بررسی کنید و دوباره امتحان کنید.';
	@override String get favoritesUpdateFailed => 'نمی توانم مورد علاقه ها را به روز کنم، اتصال خود را بررسی کنید و دوباره امتحان کنید.';
	@override String get joinSession => 'جلسه در حال پیشرفت';
	@override String watchFromStart({required Object minutes}) => 'تماشای از ابتدا (${minutes} دقیقه پیش)';
	@override String get watchLive => 'تماشای زنده';
	@override String get goToLive => 'به زندگی برو';
	@override String get record => 'رکورد';
	@override String get recordEpisode => 'رکورد قسمت';
	@override String get recordSeries => 'ضبط کردن سریال ها';
	@override String get recordOptions => 'گزینه های ثبت نام';
	@override String get saveTo => 'نجات به';
	@override String get recordings => 'ضبط شده ها';
	@override String get scheduledRecordings => 'برنامه ریزی';
	@override String get recordingRules => 'قوانین ضبط';
	@override String get noScheduledRecordings => 'هیچ برنامه ای برای ضبط نیست';
	@override String get manageRecording => 'مدیریت ضبط';
	@override String get cancelRecording => 'لغو ضبط';
	@override String get cancelRecordingTitle => 'این ضبط را لغو کنید؟';
	@override String cancelRecordingMessage({required Object title}) => '${title} دیگر ثبت نخواهد شد.';
	@override String get deleteRule => 'حذف قانون';
	@override String get deleteRuleTitle => 'قانون ضبط را حذف کنید؟';
	@override String deleteRuleMessage({required Object title}) => 'قسمت های آینده ${title} ثبت نخواهد شد.';
	@override String get recordingScheduled => 'ضبط برنامه ریزی شد.';
	@override String get alreadyScheduled => 'این برنامه برنامه ریزی شده است.';
	@override String get dvrAdminRequired => 'تنظیمات DVR نیازمند یک حساب admin است';
	@override String get recordingFailed => 'نمی توانم ضبط را برنامه ریزی کنم';
	@override String get recordingTargetMissing => 'نمی توانم کتابخانه را ضبط کنم';
	@override String get recordNotAvailable => 'ثبت نام برای این برنامه در دسترس نیست';
	@override String get recordingCancelled => 'ضبط لغو شد';
	@override String get recordingRuleDeleted => 'قانون ضبط حذف شد';
	@override String get processRecordingRules => 'قوانین ارزیابی مجدد';
	@override String get recordingInProgress => 'ضبط در حال حاضر';
	@override String recordingsCount({required Object count}) => '${count} برنامه ریزی شده';
	@override String get editRule => 'تنظیم قوانین';
	@override String get editRuleAction => 'ویرایش';
	@override String get recordingRuleUpdated => 'قوانین ضبط به روز شده';
	@override String get guideReloadRequested => 'راهنمای تجدید نظر درخواست شده';
	@override String get guideReloadFailed => 'نمی توانم راهنمای را بازسازی کنم';
	@override String get rulesProcessRequested => 'بررسی مجدد قوانین مورد نیاز';
	@override String get rulesProcessFailed => 'نمی توانم قوانین ضبط را دوباره ارزیابی کنم';
	@override String get recordShow => 'نمایش رکورد';
	@override late final _Translations$liveTv$recordSettings$fa recordSettings = _Translations$liveTv$recordSettings$fa._(_root);
	@override String startingInMinutes({required Object minutes}) => 'شروع در ${minutes} دقیقه';
	@override String dayAtTime({required Object day, required Object time}) => '${day} در ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} بازگرداندن داده های پخش زنده تلویزیون نادرست';
	@override String get failedToStartChannel => 'کانال زنده را شروع نکردم';
	@override String get failedToBuildStreamUrl => 'نمی توانم URL جریان را بسازم';
	@override String playbackStartFailed({required Object reason}) => 'کانال را نمی توانم راه اندازی کنم: ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'نمی توانم کانال را تغییر دهم: ${reason}';
}

// Path: collections
class _Translations$collections$fa extends Translations$collections$en {
	_Translations$collections$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'مجموعه‌ها';
	@override String get collection => 'مجموعه';
	@override String get empty => 'مجموعه خالی است';
	@override String get deleteCollection => 'حذف مجموعه';
	@override String deleteConfirm({required Object title}) => '«${title}» حذف شود؟ این کار قابل بازگشت نیست.';
	@override String get deleted => 'جمع آوری حذف شده';
	@override String get deleteFailed => 'عدم حذف مجموعه';
	@override String deleteFailedWithError({required Object error}) => 'عدم حذف مجموعه: ${error}';
	@override String get selectCollection => 'انتخاب مجموعه';
	@override String get collectionName => 'نام جمع آوری';
	@override String get enterCollectionName => 'نام مجموعه را وارد کنید';
	@override String get addedToCollection => 'اضافه شده به مجموعه';
	@override String get errorAddingToCollection => 'عدم اضافه شدن به جمع آوری';
	@override String get created => 'جمع آوری ساخته شده';
	@override String get removeFromCollection => 'حذف از مجموعه';
	@override String removeFromCollectionConfirm({required Object title}) => '«${title}» از این مجموعه حذف شود؟';
	@override String get removedFromCollection => 'حذف از جمع آوری';
	@override String get removeFromCollectionFailed => 'از جمع آوری خارج نشود';
	@override String removeFromCollectionError({required Object error}) => 'خطای حذف از مجموعه: ${error}';
	@override String get searchCollections => 'جمع آوری جستجو...';
}

// Path: playlists
class _Translations$playlists$fa extends Translations$playlists$en {
	_Translations$playlists$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'لیست‌های پخش';
	@override String get playlist => 'لیست پخش';
	@override String get noPlaylists => 'هیچ بازیگر یافت نشد';
	@override String get create => 'ایجاد Playlist';
	@override String get playlistName => 'نام بازی';
	@override String get enterPlaylistName => 'نام بازی را وارد کنید';
	@override String get delete => 'حذف Playlist';
	@override String get removeItem => 'حذف از فهرست پخش';
	@override String get smartPlaylist => 'بازی هوشمند';
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} مورد',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} مورد',
	);
	@override String get emptyPlaylist => 'این لیست خالی است';
	@override String get deleteConfirm => 'لیست بازی را حذف کنید؟';
	@override String deleteMessage({required Object name}) => 'آیا مطمئن هستید که می خواهید "${name}" را حذف کنید؟';
	@override String get created => 'Playlist ایجاد شده';
	@override String get deleted => 'Playlist حذف شده';
	@override String get itemAdded => 'اضافه شده به playlist';
	@override String get itemRemoved => 'حذف از Playlist';
	@override String get selectPlaylist => 'Playlist انتخاب کنید';
	@override String get searchPlaylists => 'جستجو برای بازی ها...';
	@override String get errorCreating => 'شکست در ایجاد لیست بازی';
	@override String get errorDeleting => 'عدم حذف لیست بازی ها';
	@override String get errorLoading => 'شکست در بارگذاری لیست های بازی';
	@override String get errorAdding => 'عدم اضافه شدن به لیست بازی';
	@override String get errorReordering => 'شکست در بازگرداندن آیتم های لیست بازی';
	@override String get errorRemoving => 'نتوانست از لیست بازی خارج شود';
}

// Path: music
class _Translations$music$fa extends Translations$music$en {
	_Translations$music$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'به آلبوم برو';
	@override String get goToArtist => 'به هنرمند برو';
	@override String get instantMix => 'درهم کردن فوری';
	@override String get playNext => 'بعدی را اجرا کن';
	@override String get addToQueue => 'اضافه کردن به Queue';
	@override String discNumber({required Object n}) => 'دیسک ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مسیر',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ردیف ها',
	);
	@override String get nowPlaying => 'اکنون بازی';
	@override String playingFrom({required Object title}) => 'بازی از ${title}';
	@override String get queue => 'کوی';
	@override String get clearQueue => 'پاکسازی صف';
	@override String get lyrics => 'متن ترانه';
	@override String get visualizer => 'بصری';
	@override String get visualizerProfileLoading => 'در ادامه به بررسی تراکتور...';
	@override String get visualizerAmbientMotion => 'حرکات محیطی';
	@override String get visualizerPlexLoudness => 'Plex صدا';
	@override String get visualizerLiveAudio => 'تحلیل زندهٔ صدا';
	@override String get visualizerPreviousPreset => 'قبلی سبک بصری';
	@override String get visualizerNextPreset => 'بعدی سبک بصری';
	@override String get visualizerPresetAurora => 'آوریا';
	@override String get visualizerPresetBloom => 'بلوم';
	@override String get visualizerPresetOrbitals => 'مدار';
	@override String get visualizerPresetPrism => 'قیمت گذاری';
	@override String get visualizerPresetTunnel => 'تونل';
	@override String get visualizerPresetTrackMap => 'نقشه ردیابی';
	@override String get noLyrics => 'هیچ آلبوم در دسترس نیست';
	@override String get sleepTimer => 'زمان خواب';
	@override String get sleepTimerEndOfTrack => 'پایان مسیر';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} دقیقه',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} دقیقه',
	);
	@override String get stopPlayback => 'پخش را متوقف کنید';
	@override String get previousTrack => 'ترانه پیشین';
	@override String get nextTrack => 'ترانه پسین';
	@override String get repeat => 'تکرار';
	@override String get repeatAll => 'تکرار تمام بر';
	@override String get repeatOne => 'تکرار یک';
	@override String get instantMixNoServer => 'هیچ سرور برای یک مخلوط فوری در دسترس نیست';
	@override String get instantMixFailed => 'ناپدید شدن مخلوط فوری';
	@override String get instantMixEmpty => 'این ترکیب بلافاصله با هیچ ردیابی برنگشت.';
	@override String noAudioUrl({required Object track}) => 'هیچ URL صوتی در دسترس نیست برای ${track}';
	@override late final _Translations$music$discography$fa discography = _Translations$music$discography$fa._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$fa extends Translations$watchTogether$en {
	_Translations$watchTogether$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'تماشای گروهی';
	@override String get description => 'مشاهده محتوا در همزمان با دوستان و خانواده';
	@override String get createRoom => 'ایجاد اتاق';
	@override String get creatingRoom => 'ایجاد اتاق...';
	@override String get joinRoom => 'اتاق پیوست';
	@override String get joiningRoom => 'اتاق پیوستن...';
	@override String get connecting => 'اتصال...';
	@override String get relayPublic => 'اتاق ها از پخش عمومی Open Watch Party استفاده می کنند.';
	@override String relayCustom({required Object url}) => 'اتاق ها از رله شما در شماره ${url} استفاده می کنند.';
	@override String get recentRooms => 'اتاق های جدید';
	@override String get roomActions => 'فعالیت های اتاق';
	@override String get renameRoom => 'اتاق بازسازی';
	@override String get removeRoom => 'حذف';
	@override String get enterRoomCode => 'کد 6 کاراکتر را از میزبان وارد کنید.';
	@override String get roomCode => 'کد اتاق';
	@override String get paste => 'پستی';
	@override String get noCodeInClipboard => 'این صفحه شامل کد اتاق نیست.';
	@override String get copyCode => 'کپی کد';
	@override String get codeCopied => 'کد اتاق کپی شده';
	@override String get shareInvite => 'دعوت به اشتراک گذاری';
	@override String get inviteCopied => 'کپی کنید، آن را در یک پیام قرار دهید.';
	@override String inviteMessage({required Object code}) => 'به اتاق Watch Together من در PlezyNG بپیوندید، اتاق Watch Together را انتخاب کنید و به اتاق Watch Together ${code} وارد شوید.';
	@override String get openSessionControls => 'Open Watch با هم کنترل جلسه';
	@override String get reconnecting => 'دوباره اتصال...';
	@override String get reconnectingDescription => 'اتصال قطع شده است شما به طور خودکار به اتاق می روید.';
	@override String get connected => 'اتصال';
	@override String get disconnected => 'انحطاط';
	@override String get youAreHost => 'شما میزبان هستید';
	@override String hostedBy({required Object name}) => 'بازدید : ${name}';
	@override String get hostControlsPlayback => 'کنترل بازی ها Playback';
	@override String get anyoneCanControl => 'هر کسی می تواند بازی را کنترل کند';
	@override String get roomLocked => 'اتاق بسته';
	@override String get nowPlaying => 'اکنون بازی';
	@override String get nothingPlaying => 'بازی چیزی نیست';
	@override String get nothingPlayingHost => 'بازی چیزی از هر کتابخانه برای به اشتراک گذاشتن آن با اتاق.';
	@override String get nothingPlayingGuest => 'هنگامی که میزبان چیزی را بازی می کند، در اینجا باز می شود.';
	@override String get notShareable => 'این ویدئو هیچ ربطی به کاتالوگ ندارد، بنابراین تنها افرادی که به همان سرور دسترسی دارند می توانند آن را پخش کنند.';
	@override String get searching => 'در جستجوی این ویدئو در کتابخانه های شما...';
	@override String get yourCopy => 'کپی شما';
	@override String get sharingYourCopy => 'شما کپی خود را به اشتراک می گذارید';
	@override String playingOtherLength({required Object difference}) => 'بازی کپی خود را، ${difference}';
	@override String get mismatchTitle => 'کپی شما طول متفاوت است';
	@override String mismatchDescription({required Object difference}) => 'نزدیک ترین کپی شما ${difference} از ویدئو اتاق است.این می تواند یک برش یا نسخه دیگر باشد.';
	@override String get playAnyway => 'بازی به هر حال';
	@override String get chooseAnotherCopy => 'انتخاب کپی دیگر';
	@override String get dontPlay => 'بازی نکنید';
	@override String get unavailableTitle => 'شما این ویدئو را ندارید';
	@override String get unavailableDescription => 'PlezyNG نمی توانست آن را در کتابخانه های شما پیدا کند. یک کپی را خودتان انتخاب کنید یا دوباره جستجو کنید.';
	@override String get chooseCopy => 'انتخاب کپی';
	@override String get searchAgain => 'جستجو دوباره';
	@override String get noCandidates => 'هیچ کپی در کتابخانه های شما یافت نشد.';
	@override String get choiceFailed => 'نمی توانم این کپی را برای اتاق بازی کنم.';
	@override String lengthLonger({required Object duration}) => '${duration} بیشتر';
	@override String lengthShorter({required Object duration}) => '${duration} کوتاه تر';
	@override String get lengthSame => 'همان طول';
	@override String get lengthUnknown => 'طول ناشناخته';
	@override String get joinCurrentPlayback => 'دانلود بازی Current Playback';
	@override String get joinCurrentPlaybackDescription => 'بازگشت به آنچه میزبان در حال حاضر تماشا می کند';
	@override String get stopMedia => 'دانلود ویدئو برای همه';
	@override String get syncOffset => 'همگام سازی Offset';
	@override String get syncOffsetDescription => 'ویدئوی خود را تغییر دهید اگر در مقابل یا پشت اتاق اجرا شود.';
	@override String offsetHint({required Object difference}) => 'کپی شما ${difference} از ویدئو اتاق است.';
	@override String applyDifference({required Object offset}) => 'استفاده از ${offset}';
	@override String get offsetMinusSecond => '1 S';
	@override String get offsetMinusTenth => '100 مگابایت';
	@override String get offsetPlusTenth => '+ 100 مگابایت';
	@override String get offsetPlusSecond => '+ 1 S';
	@override String get participants => 'شرکت کنندگان';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} شرکت کنندگان',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} شرکت کنندگان',
	);
	@override String get hostBadge => 'میزبان';
	@override String nameYou({required Object name}) => '${name} (شما)';
	@override String get playerIdle => 'ایدل';
	@override String get playerLoading => 'بارگذاری';
	@override String get playerReady => 'آماده';
	@override String get playerBuffering => 'بوفری';
	@override String get matchSearching => 'جستجو';
	@override String get matchMatched => 'ویدئو را دارید';
	@override String get matchMismatched => 'طول متفاوت';
	@override String get matchUnavailable => 'ویدئو را ندارید';
	@override String participantOffset({required Object offset}) => 'آگهی ${offset}';
	@override String get makeHost => 'میزبانی کنید';
	@override String get makeHostQuestion => 'انتقال میزبان؟';
	@override String makeHostConfirm({required Object name}) => '${name} بازتاب را کنترل می کند و جلسه را برای همه اجرا می کند.';
	@override String get transfer => 'انتقال';
	@override String get removeParticipant => 'از اتاق خارج شوید';
	@override String removeParticipantQuestion({required Object name}) => 'حذف ${name}؟';
	@override String removeParticipantConfirm({required Object name}) => '${name} اتاق را ترک می کند.آنها می توانند دوباره با کد پیوستند مگر اینکه اتاق را قفل کنید.';
	@override String get remove => 'حذف';
	@override String get roomSettings => 'تنظیمات اتاق';
	@override String get letEveryoneControl => 'اجازه دهید همه کنترل Playback';
	@override String get lockRoom => 'اتاق قفل';
	@override String get lockRoomDescription => 'هیچ کس جدیدی نمی تواند به';
	@override String get leaveRoom => 'اتاق را ترک کنید';
	@override String get leaveRoomQuestion => 'اتاق را ترک کنید؟';
	@override String get leaveRoomConfirm => 'شما می توانید دوباره با کد اتاق وارد شوید.';
	@override String get leave => 'ترک کردن';
	@override String get endRoom => 'اتاق نهایی';
	@override String get endRoomQuestion => 'اتاق نهایی؟';
	@override String get endRoomConfirm => 'این پایان اتاق برای همه است.';
	@override String get end => 'پایان';
	@override String get playBlockedTitle => 'Playback شروع نمی شود';
	@override String get playBlockedDescription => 'برای شروع تماشای بازی با اتاق.';
	@override late final _Translations$watchTogether$notices$fa notices = _Translations$watchTogether$notices$fa._(_root);
	@override late final _Translations$watchTogether$ended$fa ended = _Translations$watchTogether$ended$fa._(_root);
	@override late final _Translations$watchTogether$errors$fa errors = _Translations$watchTogether$errors$fa._(_root);
	@override String untitledEpisode({required Object number}) => 'صفحه اصلی ${number}';
}

// Path: downloads
class _Translations$downloads$fa extends Translations$downloads$en {
	_Translations$downloads$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'بارگیری‌ها';
	@override String get manage => 'مدیریت';
	@override String get tvShows => 'تلویزیون نمایش';
	@override String get movies => 'فیلم ها';
	@override String get music => 'موسیقی‌ها';
	@override String tracksQueued({required Object count}) => '${count} ردیابی برای دانلود';
	@override String get noDownloads => 'هنوز دانلود نشده';
	@override String get noDownloadsDescription => 'محتوای دانلود شده برای مشاهده آفلاین در اینجا ظاهر خواهد شد.';
	@override String get downloadNow => 'بارگیری';
	@override String get deleteDownload => 'حذف دانلود';
	@override String get retryDownload => 'دانلود Retry';
	@override String get downloadQueued => 'دانلود به صف اضافه شد.';
	@override String get downloadResumed => 'دانلود مجدد';
	@override String get serverErrorBitrate => 'خطای سرور: فایل ها می توانند حد بیتی از راه دور را فراتر ببرند';
	@override String get storageFull => 'دانلود ها برای محافظت از ذخیره سازی در دسترس متوقف شده است. برخی از فضای را آزاد کنید یا محل دانلود دیگری را انتخاب کنید، سپس عقب نشینی کنید.';
	@override String get storageUnavailable => 'دانلود ها متوقف شد زیرا ذخیره سازی در دسترس نمی تواند بررسی شود.نگاه کنید به محل دانلود، سپس عقب نشینی.';
	@override String episodesQueued({required Object count}) => '${count} قسمت برای دانلود';
	@override String get downloadDeleted => 'دانلود حذف شده';
	@override String deleteConfirm({required Object title}) => 'حذف "${title}" از این دستگاه؟';
	@override String get deleteCollectionDownloads => 'حذف دانلود ها';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => 'همهٔ دانلودهای «${title}» از این دستگاه پاک شوند؟';
	@override String get collectionDownloadsDeleted => 'دانلود حذف شده';
	@override String get cancelledDownloadTitle => 'دانلود لغو';
	@override String get cancelledDownloadMessage => 'این دانلود لغو شده است چه کاری می خواهید انجام دهید؟';
	@override String get allEpisodesAlreadyDownloaded => 'همه قسمت ها دانلود شده است';
	@override String get resumeDownload => 'دانلود مجدد';
	@override String get cancelledDownload => 'دانلود لغو';
	@override String syncingFile({required Object file, required Object status}) => '${file} (تولید ${status})';
	@override String downloadedFileClickToComplete({required Object file}) => 'دانلود شده ${file} - کلیک کنید برای تکمیل';
	@override String get partialDownloadClickToComplete => 'دانلود جزئی - کلیک کنید برای تکمیل';
	@override String get deleting => 'حذف...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'حذف ${title}... (${current} از ${total})';
	@override String get queuedTooltip => 'کویت';
	@override String queuedFilesTooltip({required Object files}) => 'آگهی ${files}';
	@override String get downloadingTooltip => 'دانلود...';
	@override String downloadingFilesTooltip({required Object files}) => 'دانلود ${files}';
	@override String get noDownloadsTree => 'بدون دانلود';
	@override String get pauseAll => 'استراحت همه';
	@override String get resumeAll => 'خلاصه همه';
	@override String get retryAll => 'بازگشت همه';
	@override String get retryFailed => 'دانلود بازی های شکست خورده';
	@override String get deleteAll => 'حذف همه';
	@override String get selectVersion => 'انتخاب نسخه';
	@override String get allEpisodes => 'تمام قسمت‌ها';
	@override String get unwatchedOnly => 'فقط نادیده گرفته شده';
	@override String nextNUnwatched({required Object count}) => 'بعدی ${count} ناشناخته';
	@override String get customAmount => 'مقدار سفارشی...';
	@override String get customAmountAny => 'مقدار مشخصی (در هر...';
	@override String get randomEpisodes => 'حوادث تصادفی';
	@override String get includeSpecials => 'شامل ویژه ها';
	@override String get howManyEpisodes => 'چند قسمت است؟';
	@override String get invalidEpisodeCount => 'تعداد قسمت های معتبر را وارد کنید.';
	@override String get keepSynced => 'همگام نگه دارید';
	@override String get downloadOnce => 'دانلود یک بار';
	@override String keepNUnwatched({required Object count}) => '${count} را نادیده بگیرید';
	@override String get editSyncRule => 'ویرایش قوانین Sync';
	@override String get removeSyncRule => 'حذف قاعده سینک';
	@override String removeSyncRuleConfirm({required Object title}) => 'توقف همگام سازی "${title}"؟ قسمت های دانلود شده حفظ خواهد شد.';
	@override String removeListSyncRuleConfirm({required Object title}) => '«پایان» به «${title}» می رسد.';
	@override String get deleteSyncRuleDownloads => 'همچنین حذف دانلود های مرتبط';
	@override String get deleteSyncRuleDownloadsDescription => 'دانلود هایی که توسط یک قاعده یا پروفایل همگام سازی دیگر مورد استفاده قرار می گیرند، حفظ می شود.';
	@override String syncRuleCreated({required Object count}) => 'قاعده همگام سازی ایجاد شده – حفظ ${count} قسمت های ناشناخته';
	@override String get syncRuleUpdated => 'قانون همگام سازی به روز شده';
	@override String get syncRuleRemoved => 'قانون همگام حذف شد';
	@override String get syncRuleAndDownloadsRemoved => 'قانون همگام سازی و دانلود های مرتبط حذف شد';
	@override String get syncRuleCleanupBusy => 'قوانین همگام سازی در حال حاضر به روز شده است.در یک لحظه دوباره امتحان کنید.';
	@override String get syncRuleCleanupUnavailable => 'دانلود های مرتبط نمی تواند به طور ایمن شناسایی شود. دوباره سرور را به هم متصل کنید و دوباره آن را امتحان کنید، یا قاعده را بدون حذف دانلود ها حذف کنید.';
	@override String syncedNewEpisodes({required Object count, required Object title}) => 'همگام سازی ${count} قسمت های جدید برای ${title}';
	@override String get syncNow => 'همگام اکنون';
	@override String get downloadsUpToDate => 'دانلود ها به روز شده است';
	@override String syncComplete({required Object queued, required Object removed}) => 'همگام سازی کامل · ${queued} queued, ${removed} حذف شده';
	@override String get activeSyncRules => 'قوانین Sync';
	@override String get reviewOrphanFiles => 'دانلود دانلود بازی Orphaned';
	@override String get orphanReviewTitle => 'دانلود دانلود بازی Orphaned';
	@override String get orphanReviewDescription => 'این فایل های برچسب گذاری شده در پوشه های دانلود برنامه مدیریت شده پیش فرض PlezyNG هستند و هیچ رکورد دانلود یا کار فعال مطابقت ندارد.';
	@override String orphanReviewCount({required Object count, required Object size}) => '${count} فایل ها · ${size}';
	@override String orphanDeleteFiles({required Object count}) => 'حذف فایل ${count}';
	@override String get orphanCleanupNone => 'دانلود فایل های ارواح یافت نشد';
	@override String get orphanCleanupFailed => 'PlezyNG نمی توانست به طور ایمن اسکن پوشه دانلود های مدیریت شده.';
	@override String get orphanCleanupChanged => 'لیست دانلود در طول بررسی تغییر کرده است. بررسی فایل ها دوباره قبل از تمیز کردن.';
	@override String orphanCleanupComplete({required Object count, required Object size}) => 'حذف شده ${count} فایل های ارواح · ${size} آزاد';
	@override String get noSyncRules => 'هیچ قواعد همگام سازی';
	@override String get manageSyncRule => 'مدیریت Sync';
	@override String get editEpisodeCount => 'قسمت شمارش';
	@override String get editSyncFilter => 'فیلتر Sync';
	@override String get syncAllItems => 'جمع آوری همه اشیاء';
	@override String get syncUnwatchedItems => 'دسته بندی نکات ناشناخته';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'سرور: ${server} • ${status}';
	@override String get syncRuleAvailable => 'در دسترس';
	@override String get syncRuleOffline => 'آفلاین';
	@override String get syncRuleSignInRequired => 'ثبت نام در مورد نیاز';
	@override String get syncRuleAccessDenied => 'دسترسی رد شد';
	@override String get syncRuleNotAvailableForProfile => 'در حال حاضر در پروفایل موجود نیست';
	@override String get syncRuleUnknownServer => 'سرور ناشناخته';
	@override String get syncRuleListCreated => 'قاعده همگام سازی ایجاد شده';
	@override late final _Translations$downloads$backgroundWarning$fa backgroundWarning = _Translations$downloads$backgroundWarning$fa._(_root);
	@override String get options => 'گزینه های دانلود';
	@override late final _Translations$downloads$groupings$fa groupings = _Translations$downloads$groupings$fa._(_root);
	@override String get unknownLibrary => 'کتابخانه ناشناخته';
	@override String get unknownShow => 'نمایش ناشناخته';
	@override String get unknownSeason => 'فصل ناشناخته';
	@override String get unknownAlbum => 'آلبوم ناشناخته';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} تکمیل شده';
	@override String storageUsed({required Object size}) => 'ذخیره سازی مورد استفاده: ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} دانلود',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} دانلود',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} نمایش',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} نمایش',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} فیلم',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} فیلم ها',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} آلبوم',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} آلبوم',
	);
	@override String get errorFileNotFound => 'فایلهای یافت نشد (404)';
	@override String get errorDownloadNotAllowed => 'دانلود غیر مجاز توسط سرور (403)';
	@override String get errorDownloadFailed => 'دانلود شکست خورد';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'دانلود شکست خورده: ${reason}';
	@override String get convertingOnServer => 'تبدیل به سرور';
	@override String convertingOnServerPercent({required Object percent}) => 'تبدیل به سرور · ${percent}%';
	@override String errorHttpStatus({required Object status}) => 'دانلود شکست خورده (HTTP ${status})';
	@override String errorPostProcessing({required Object reason}) => 'پس از پردازش شکست خورده: ${reason}';
	@override String get reasonFileNotSaved => 'فایل ها را نمی توان در این دستگاه ذخیره کرد.';
	@override String get reasonCannotResume => 'دانلود جزئی نمی تواند تکرار شود';
	@override String get reasonDeviceStorageFull => 'این دستگاه از ذخیره سازی خارج می شود.';
	@override String get notificationDownloading => 'دانلود...';
	@override String get notificationComplete => 'دانلود کامل';
	@override String get notificationPaused => 'دانلود استراحت';
}

// Path: shaders
class _Translations$shaders$fa extends Translations$shaders$en {
	_Translations$shaders$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'سایه ها';
	@override String get noShaderDescription => 'بدون ویدئو بهبود';
	@override String get nvscalerDescription => 'NVIDIA تصویر اسکن برای ویدئو های تیز تر';
	@override String get artcnnVariantNeutral => 'بی طرف';
	@override String get artcnnVariantDenoise => 'دنو';
	@override String get artcnnVariantDenoiseSharpen => 'دایناسور + شارپن';
	@override String get qualityFast => 'سریع';
	@override String get qualityHQ => 'کیفیت بالا';
	@override String get mode => 'مد';
	@override String get importShader => 'واردات شیراز';
	@override String get customShaderDescription => 'تبلت های GLSL Shader';
	@override String get shaderImported => 'شیراز واردات';
	@override String get shaderImportFailed => 'شکست در واردات شیراز';
	@override String get deleteShader => 'حذف Shader';
	@override String deleteShaderConfirm({required Object name}) => 'حذف «${name}»؟';
}

// Path: companionRemote
class _Translations$companionRemote$fa extends Translations$companionRemote$en {
	_Translations$companionRemote$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'کنترل همراه';
	@override String connectedTo({required Object name}) => 'به ${name} متصل شده است.';
	@override String get unknownDevice => 'دستگاه ناشناخته';
	@override late final _Translations$companionRemote$session$fa session = _Translations$companionRemote$session$fa._(_root);
	@override late final _Translations$companionRemote$pairing$fa pairing = _Translations$companionRemote$pairing$fa._(_root);
	@override late final _Translations$companionRemote$remote$fa remote = _Translations$companionRemote$remote$fa._(_root);
	@override late final _Translations$companionRemote$errors$fa errors = _Translations$companionRemote$errors$fa._(_root);
	@override String get closedBeforeAuth => 'اتصال قبل از تأیید بسته شد';
}

// Path: videoSettings
class _Translations$videoSettings$fa extends Translations$videoSettings$en {
	_Translations$videoSettings$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'سرعت پخش';
	@override String get normalSpeed => 'طبیعی';
	@override String sleepTimerActive({required Object duration}) => 'فعال (${duration})';
	@override String get zoom => 'پوشش دادن';
	@override String get sleepTimer => 'زمان خواب';
	@override String get audioSync => 'صدا همگام';
	@override String get subtitleSync => 'زیرنویس Sync';
	@override String get hdr => 'HDR';
	@override String get hdrUnsupported => 'HDR در اینجا در دسترس نیست - این سازنده دسکتاپ یا خروجی ویدئویی نمی تواند آن را حمل کند.';
	@override String get hdrToneMapping => 'HDR Tone نقشه برداری';
	@override String get hdrToneMappingCompositor => 'سازنده';
	@override String get hdrToneMappingCompositorDescription => 'از طریق متادیت های HDR منبع عبور کنید و به نقشه سازنده دسکتاپ اجازه دهید.';
	@override String get hdrToneMappingPlayer => 'پخش‌کننده';
	@override String get hdrToneMappingPlayerDescription => 'نقشه تا درخشش بالای صفحه نمایش در بازیکن، سپس به آهنگساز نتیجه را بگویید.';
	@override String get hdrToneMappingFailed => 'نمی توانم نقشه برداری رنگ HDR را تغییر دهم - حالت قبلی هنوز فعال است.';
	@override String get audioOutput => 'صدا خروجی';
	@override String get videoTrack => 'مسیر ویدیو';
	@override String get videoTrackDescription => 'انتخاب کنید کدام جریان ویدیو نمایش داده شود. هنگام پخش با MPV، اگر فایل مسیرهای ویدیوی جایگزین داشته باشد، در دسترس است.';
	@override String get videoTrackDefault => 'پیش‌فرض';
	@override String get videoTrackUnavailable => 'مسیر ویدیوی جایگزینی در دسترس نیست.';
	@override String get videoTrackFailed => 'تغییر مسیر ویدیو ممکن نشد.';
	@override String videoTrackNumber({required Object id}) => 'مسیر ${id}';
	@override String get performanceOverlay => 'عملکرد Overlay';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'اطراف';
	@override String get audioOutputSpatial => 'فضای صوتی';
	@override String get audioOutputStereo => 'استریو';
	@override String get audioEqualizer => 'صدا معادل';
	@override String get audioEqualizerDescription => 'معادل 10 باند برای MPVفیلترهای صوتی از صدا های رمزگذاری شده استفاده می کنند و به طور مناسب خاموش می شوند.';
	@override String get audioEqualizerFlat => 'مسطح';
	@override String get audioEqualizerActive => 'سفارشی';
	@override String get audioEqualizerSaveFailed => 'نمی توانم تنظیمات معادل صوتی را ذخیره کنم.';
	@override String get audioEffectsDescription => 'اثرات از صدا رمزگذاری شده استفاده می کنند، بنابراین passthrough از بین می رود. فضای اتاق و گسترش استریو بستگی به MPV ساخت و ردیابی';
	@override String get audioStereoWidth => 'استریو گسترش';
	@override String get audioSpatializer => 'فضای اتاق';
	@override String get audioSpatializerDescription => 'بازخورد اتاق آرام را اضافه کنید.';
	@override String get audioPitch => 'پیتزا تغییر';
	@override String get audioPitchDescription => 'تغییر مسیر بدون تغییر سرعت MPV ساخت باید شامل Rubber Band.';
	@override String get audioEffectUnavailable => 'این اثر برای این مسیر در دسترس نیست یا MPV ساختن .';
	@override String get backgroundVideoAudio => 'ویدئو ویدئو صدا';
	@override String get backgroundVideoAudioDescription => 'بازی ویدئویی را در هنگام ترک پخش کننده نگه دارید؛ تصویر تا زمانی که بازگردید پنهان است. Android از یک اطلاعیه پخش رسانه استفاده می کند.';
	@override String get audioNormalization => 'صدا را عادی کنید';
	@override String get audioNormalizationDisablesPassthrough => 'دکود صوتی به PCM؛ passthrough در حالی که این در';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$fa extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get color => 'رنگ ها';
	@override String get performance => 'کارایی';
	@override String get buffer => 'بوفری';
	@override String get app => 'برنامه';
	@override String get decoder => 'دکوراسیون';
	@override String get rawDecoder => 'دکوراسیون خام';
	@override String get tunneling => 'تونل';
	@override String get passthrough => 'پازل';
	@override String get aspect => 'دیدگاه';
	@override String get rotation => 'چرخش';
	@override String get dvSource => 'منبع DV';
	@override String get dvPath => 'راه دو';
	@override String get dvRouteDecoder => 'Dolby Vision دکوراسیون';
	@override String get dvRouteDecoderP81 => 'Dolby Vision دکوراسیون (P7→8.1)';
	@override String get dvRouteBaseLayer => 'لایه پایه';
	@override String get dvRouteBaseLayerHdr10 => 'HDR10 لایه پایه';
	@override String get dvRouteBaseLayerHlg => 'لایه پایه HLG';
	@override String get dvRouteBaseLayerSdr => 'SDR لایه پایه';
	@override String get dvRouteReshaped => 'RPU بازسازی شده (gpu-next)';
	@override String get dvRouteFelGraphActive => 'گرافیک آزمایشی P7 FEL (غیر واجد شرایط)';
	@override String get p7Conversion => 'P7 کنف';
	@override String get sampleRate => 'نرخ نمونه';
	@override String get pixelFormat => 'پیکسل Fmt';
	@override String get hwFormat => 'فای فای فای';
	@override String get matrix => 'ماتریکس';
	@override String get primaries => 'اولویت ها';
	@override String get transfer => 'انتقال';
	@override String get renderFps => 'رندر FPS';
	@override String get displayFps => 'نمایش FPS';
	@override String get avSync => 'A / V همگام سازی';
	@override String get dropped => 'سقوط';
	@override String get dvRpus => 'DV RPU';
	@override String get dvRpuAverage => 'آرشیو برچسب: AVG';
	@override String get dvSampleAverage => 'نمونه های AVG';
	@override String get maxLuma => 'مکس لوما';
	@override String get minLuma => 'مینی لوما';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'استفاده از Cache';
	@override String get cacheLimit => 'محدودیت کاسه';
	@override String get speed => 'سرعت';
	@override String get player => 'پخش‌کننده';
	@override String get playMethod => 'نحوه پخش';
	@override String get memory => 'حافظه';
	@override String get uiFps => 'FPS FPS';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Android HW';
	@override String get decoderNvidiaHw => 'NVIDIA HW';
	@override String get decoderQualcommHw => 'کوالکام HW';
	@override String get decoderMediatekHw => 'رسانه ها HW';
	@override String get decoderExynosHw => 'بیوگرافی HW';
	@override String get decoderSoftware => 'نرم افزار';
	@override String get decoderHardware => 'سخت افزار';
	@override String get tunnelingActive => 'فعال';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted} (${failures} شکست خورده)';
}

// Path: externalPlayer
class _Translations$externalPlayer$fa extends Translations$externalPlayer$en {
	_Translations$externalPlayer$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'بازیکن خارجی';
	@override String get useExternalPlayer => 'استفاده از بازیکن خارجی';
	@override String get useExternalPlayerDescription => 'باز کردن ویدئوها در یک برنامه دیگر';
	@override String get selectPlayer => 'انتخاب بازیکن';
	@override String get customPlayers => 'بازیکنان سفارشی';
	@override String get systemDefault => 'سیستم پیش فرض';
	@override String get addCustomPlayer => 'اضافه کردن Custom Player';
	@override String get playerName => 'نام بازیکن';
	@override String get playerNameHint => 'بازیکن من';
	@override String get playerCommand => 'فرمانده';
	@override String get playerPackage => 'نام بسته';
	@override String get playerUrlScheme => 'برنامه URL';
	@override String get off => 'خاموش';
	@override String get launchFailed => 'عدم باز کردن بازیکن خارجی';
	@override String appNotInstalled({required Object name}) => '${name} نصب نشده است';
	@override String get playInExternalPlayer => 'بازی در بازیکن خارجی';
	@override String get description => 'برنامه دیگری را برای باز کردن ویدئوها انتخاب کنید بازیکنان در دسترس به دستگاه و برنامه های نصب شده شما بستگی دارند.';
	@override String get systemDefaultDescription => 'اجازه دهید سیستم عامل ویدئو را با برنامه پیش فرض خود باز کند.';
	@override String playerOptionDescription({required Object player}) => 'ویدئوها را با ${player} باز کنید.';
	@override String get playerNameDescription => 'برچسب نشان داده شده در لیست بازیکنان.';
	@override String get playerPackageDescription => 'نام بسته اندروید را از اپلیکیشن بازیکن وارد کنید، مانند com.example.player.';
	@override String get playerCommandDescription => 'دستور یا مسیر اجرا شده برای این دستگاه را وارد کنید.';
	@override String get playerUrlSchemeDescription => 'نمودار URL و قالب URL اختیاری مورد استفاده برای راه اندازی بازیکن را وارد کنید.';
}

// Path: metadataEdit
class _Translations$metadataEdit$fa extends Translations$metadataEdit$en {
	_Translations$metadataEdit$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'ویرایش';
	@override String get screenTitle => 'ویرایش فراداده';
	@override String get basicInfo => 'اطلاعات پایه';
	@override String get artwork => 'هنری';
	@override String get advancedSettings => 'تنظیمات پیشرفته';
	@override String get title => 'عنوان';
	@override String get sortTitle => 'مرتب‌سازی عنوان';
	@override String get originalTitle => 'عنوان اصلی';
	@override String get releaseDate => 'تاریخ انتشار';
	@override String get contentRating => 'محتوای رتبه بندی';
	@override String get studio => 'استودیو';
	@override String get tagline => 'تگ لاین';
	@override String get summary => 'خلاصه ای';
	@override String get poster => 'پوستر';
	@override String get background => 'پس زمینه';
	@override String get logo => 'لوگو';
	@override String get squareArt => 'میدان هنر';
	@override String get selectPoster => 'انتخاب پوستر';
	@override String get selectBackground => 'انتخاب پس زمینه';
	@override String get selectLogo => 'انتخاب لوگو';
	@override String get selectSquareArt => 'انتخاب میدان هنر';
	@override String get fromUrl => 'از URL';
	@override String get uploadFile => 'دانلود فایل';
	@override String get enterImageUrl => 'URL تصویر را وارد کنید';
	@override String get imageUrl => 'تصویر URL';
	@override String get metadataUpdated => 'Metadata به روز شده';
	@override String get metadataUpdateFailed => 'عدم به روز رسانی متا';
	@override String get artworkUpdated => 'هنر به روز شده';
	@override String get artworkUpdateFailed => 'به روز رسانی هنرهای هنری';
	@override String get noArtworkAvailable => 'هیچ هنری در دسترس نیست';
	@override String artworkOption({required Object index}) => 'گزینه هنری ${index}';
	@override String selectedArtworkOption({required Object index}) => 'گزینه هنری ${index} انتخاب شده';
	@override String get notSet => 'نه تنظیم';
	@override String get libraryDefault => 'کتابخانه های ناشناخته';
	@override String get accountDefault => 'حساب های جعلی';
	@override String get seriesDefault => 'سری دیپلماسی';
	@override String get episodeSorting => 'قسمت دسته بندی';
	@override String get oldestFirst => 'قدیمی ترین اول';
	@override String get newestFirst => 'جدیدترین اول';
	@override String get keep => 'نگه داشتن';
	@override String get allEpisodes => 'تمام قسمت‌ها';
	@override String latestEpisodes({required Object count}) => '${count} آخرین قسمت ها';
	@override String get latestEpisode => 'آخرین قسمت';
	@override String episodesAddedPastDays({required Object count}) => 'قسمت های اضافه شده در روزهای گذشته ${count}';
	@override String get deleteAfterPlaying => 'حذف قسمت ها پس از بازی';
	@override String get never => 'هرگز';
	@override String get afterADay => 'بعد از یک روز';
	@override String get afterAWeek => 'بعد از یک هفته';
	@override String get afterAMonth => 'پس از یک ماه';
	@override String get onNextRefresh => 'بعدی تمیز کردن';
	@override String get seasons => 'فصل ها';
	@override String get show => 'نمایش';
	@override String get hide => 'پنهان کردن';
	@override String get episodeOrdering => 'قسمت سفارش';
	@override String get tmdbAiring => 'پایگاه داده فیلم (Aired)';
	@override String get tvdbAiring => 'تئاتر دبی (Aired)';
	@override String get tvdbAbsolute => 'دانلود فیلم TheTVDB (Absolute)';
	@override String get metadataLanguage => 'زبان متا';
	@override String get useOriginalTitle => 'استفاده از عنوان اصلی';
	@override String get preferredAudioLanguage => 'اولویت زبان صدا';
	@override String get preferredSubtitleLanguage => 'زبان زیرنویس ترجیحی';
	@override String get subtitleMode => 'حالت انتخاب خودکار Subtitle';
	@override String get manuallySelected => 'انتخاب دستی';
	@override String get shownWithForeignAudio => 'نمایش با صدا خارجی';
	@override String get alwaysEnabled => 'همیشه امکان پذیر';
	@override String get tags => 'برچسب‌ها';
	@override String get addTag => 'اضافه کردن Tag';
	@override String get genre => 'ژانر';
	@override String get director => 'کارگردان';
	@override String get writer => 'نویسنده';
	@override String get producer => 'تولید کننده';
	@override String get country => 'کشور';
	@override String get collection => 'مجموعه';
	@override String get label => 'برچسب ها';
	@override String get quickTag => 'Tag سریع...';
}

// Path: matchScreen
class _Translations$matchScreen$fa extends Translations$matchScreen$en {
	_Translations$matchScreen$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get match => 'مسابقه...';
	@override String get fixMatch => 'مسابقه اصلاحی...';
	@override String get unmatch => 'عدم مسابقه';
	@override String get unmatchConfirm => 'این بازی را روشن کنید؟ Plex آن را به عنوان نامناسب تا به پایان رسید.';
	@override String get unmatchSuccess => 'موضوع ناخوشایند';
	@override String get unmatchFailed => 'شکست ناپذیر در بازی';
	@override String get matchApplied => 'مسابقه اعمال شد';
	@override String get matchFailed => 'شکست در اجرای بازی';
	@override String get titleHint => 'عنوان';
	@override String get yearHint => 'سال';
	@override String get search => 'جستجو کردن';
	@override String get noMatchesFound => 'هیچ مسابقه ای یافت نشد';
}

// Path: serverTasks
class _Translations$serverTasks$fa extends Translations$serverTasks$en {
	_Translations$serverTasks$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'کارهای سرور';
	@override String get failedToLoad => 'شکست در انجام وظایف';
	@override String get noTasks => 'هیچ وظیفه ای اجرا نمی شود';
}

// Path: trakt
class _Translations$trakt$fa extends Translations$trakt$en {
	_Translations$trakt$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'اتصال';
	@override String connectedAs({required Object username}) => 'به عنوان @${username} متصل شده است';
	@override String get disconnectConfirm => 'حساب کاربری Trakt را قطع کنید.';
	@override String get disconnectConfirmBody => 'PlezyNG ارسال رویدادها را به Trakt متوقف می کند.';
	@override String get scrobble => 'زمان واقعی Scrobbling';
	@override String get scrobbleDescription => 'ارسال بازی، استراحت و توقف رویدادهای به Trakt در هنگام پخش.';
	@override String get watchedSync => 'Sync وضعیت مشاهده شده';
	@override String get watchedSyncDescription => 'هنگامی که شما آیتم ها را به عنوان مشاهده شده در PlezyNG نشان می دهید، آنها نیز به عنوان مشاهده شده در Trakt نشان داده می شوند.';
}

// Path: seerr
class _Translations$seerr$fa extends Translations$seerr$en {
	_Translations$seerr$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'اتصال به Seerr';
	@override String get serverUrl => 'سرور URL';
	@override String get serverUrlHelper => 'آدرس مورد نظر شما';
	@override String get checkServer => 'ادامه مطلب';
	@override String get signInWithJellyfin => 'ثبت نام با شماره Jellyfin';
	@override String get signInWithEmby => 'ثبت نام با شماره Emby';
	@override String get signInWithLocal => 'استفاده از حساب محلی';
	@override String get email => 'ایمیل';
	@override String get noSignInMethods => 'این مثال Seerr هیچ پشتیبانی از روش ثبت نام PlezyNG را ارائه نمی دهد.';
	@override String get instance => 'مواردی';
	@override String get disconnectConfirm => 'از بین بردن سیم کارت؟';
	@override String get disconnectConfirmBody => 'PlezyNG این مثال را فراموش خواهد کرد.در هر زمان دوباره اتصال.';
	@override String get request => 'درخواست';
	@override String get request4k => 'درخواست در 4K';
	@override String get seasons => 'فصل ها';
	@override String get allSeasons => 'همه فصل ها';
	@override String get advancedOptions => 'پیشرفته';
	@override String get destinationServer => 'سرور مقصد';
	@override String get qualityProfile => 'پروفایل کیفیت';
	@override String get rootFolder => 'فاکتور ریشه';
	@override String get languageProfile => 'پروفایل زبان';
	@override String get tags => 'برچسب‌ها';
	@override String get noTags => 'هیچ تگ';
	@override String defaultOption({required Object name}) => '${name} (به طور پیش فرض)';
	@override String get animeNote => 'این سریال یک انیمه است.';
	@override String get requestSubmitted => 'درخواست ارسال شده';
	@override String requestFailed({required Object error}) => 'درخواست شکست خورده: ${error}';
	@override String get requestsLoadFailed => 'نمی توانم گزینه های درخواست را بارگذاری کنم';
	@override String get nothingToRequest => 'همه چیز در دسترس است یا درخواست شده است.';
	@override String get statusAvailable => 'در دسترس';
	@override String get statusPartiallyAvailable => 'به طور جزئی در دسترس';
	@override String get statusRequested => 'درخواست شده';
	@override String get statusProcessing => 'پردازش';
	@override String get statusBlocklisted => 'مسدود شده';
	@override String couldNotReach({required Object url, required Object error}) => 'نمی تواند به ${url} برسد: ${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => 'بدون درخواست Seerr در ${url} (HTTP ${status})';
	@override String get behindAuthProxy => 'یک پروکسی واقعی (SSO یا HTTP auth) به جای Seerr پاسخ داده شده است. PlezyNG نمی تواند از طریق آن ثبت نام کند: اجازه دهید مسیر /api/v1 Seerr از طریق پروکسی برای این برنامه عبور کند یا از یک آدرس که به طور مستقیم به Seerr می رسد استفاده کنید.';
	@override String get invalidUrl => 'آدرس سرور مانند https://seerr.example.com را وارد کنید';
	@override String get quickConnectUnsupported => 'این مثال Seerr از Quick Connect پشتیبانی نمی کند.این مثال نیاز به Seerr 3.4 یا جدیدتر دارد.';
	@override String get notInitialized => 'این حالت Seerr نصب اولیه را تکمیل نکرده است';
	@override String get noPlexTokenForReauth => 'شماره Plex توکن برای ثبت نام مجدد در دسترس است';
	@override String get noStoredCredentials => 'اطلاعات ورود ذخیره‌شده‌ای برای ورود دوباره در دسترس نیست';
	@override String get signInRejected => 'ثبت نام رد شد';
	@override String get noSessionCookie => 'Seerr یک کوکی جلسه را منتشر نکرده است';
	@override String get freshCookieRejected => 'Seerr کوکی جلسه جدید را رد کرد';
	@override String get noUserInformation => 'Seerr اطلاعات کاربر را بازگرداند';
	@override String get sessionRejectedAfterReauth => 'جلسه پس از امضای مجدد رد شد.';
	@override String get permissionDenied => 'Seerr این اقدام را رد کرد: حساب شما دیگر مجوز مورد نیاز را ندارد';
	@override String get permissionRevoked => 'شما دیگر اجازه درخواست این کار را ندارید.';
}

// Path: services
class _Translations$services$fa extends Translations$services$en {
	_Translations$services$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'خدمات';
	@override String get hubSubtitle => 'Sync پیشرفت را مشاهده می کند و از عنوان های جدید درخواست می کند.';
	@override String get integrations => 'ادغام';
	@override String get notConnected => 'نه متصل';
	@override String connectedAs({required Object username}) => 'به عنوان @${username} متصل شده است';
	@override String get scrobble => 'پیشرفت خودکار را ردیابی کنید';
	@override String get scrobbleDescription => 'لیست خود را به روز کنید زمانی که شما یک قسمت یا فیلم را به پایان می رسانید.';
	@override String disconnectConfirm({required Object service}) => 'اتصال به ${service}';
	@override String disconnectConfirmBody({required Object service}) => 'PlezyNG به روز رسانی را متوقف می کند ${service}.';
	@override String connectFailed({required Object service}) => 'من نمی توانم به ${service} متصل شوم.';
	@override late final _Translations$services$names$fa names = _Translations$services$names$fa._(_root);
	@override late final _Translations$services$simklReconnect$fa simklReconnect = _Translations$services$simklReconnect$fa._(_root);
	@override late final _Translations$services$deviceCode$fa deviceCode = _Translations$services$deviceCode$fa._(_root);
	@override late final _Translations$services$oauthProxy$fa oauthProxy = _Translations$services$oauthProxy$fa._(_root);
	@override late final _Translations$services$pendingAuth$fa pendingAuth = _Translations$services$pendingAuth$fa._(_root);
	@override late final _Translations$services$libraryFilter$fa libraryFilter = _Translations$services$libraryFilter$fa._(_root);
	@override String get seerrDescription => 'برای جستجوی عنوان ها و ارسال درخواست های رسانه ای به Seerr یا Overseerr متصل شوید.';
	@override late final _Translations$services$trackerDescriptions$fa trackerDescriptions = _Translations$services$trackerDescriptions$fa._(_root);
}

// Path: addServer
class _Translations$addServer$fa extends Translations$addServer$en {
	_Translations$addServer$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => 'اضافه کردن سرور ${product}';
	@override String get serverUrls => 'سرور URL';
	@override String get serverUrlsHelper => 'URL های چندگانه مجاز، جدا شده توسط commas.';
	@override String get findServer => 'سرور را پیدا کنید';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'در جستجوی سرورهای محلی ${product} ...';
	@override String localMediaBrowserServers({required Object product}) => 'سرورهای محلی ${product}';
	@override String get username => 'نام کاربری';
	@override String get password => 'گذرواژه';
	@override String get signIn => 'ورود';
	@override String get change => 'تغییر';
	@override String get required => 'نیاز به';
	@override String couldNotReachServer({required Object error}) => 'نمی توانم به سرور دسترسی داشته باشم: ${error}';
	@override String signInFailed({required Object error}) => 'ثبت نام شکست خورده: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect شکست خورده: ${error}';
	@override String get addPlexTitle => 'ثبت نام با شماره Plex';
	@override String get pinExpired => 'PIN قبل از ثبت نام به پایان رسیده است لطفا دوباره امتحان کنید.';
	@override String failedToRegisterAccount({required Object error}) => 'عدم ثبت حساب: ${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => 'URL سرور ${product} را وارد کنید.';
	@override String get addConnectionTitle => 'اضافه کردن اتصال';
	@override String addConnectionTitleScoped({required Object name}) => 'اضافه کردن به ${name}';
	@override String get signInWithPlexCard => 'ثبت نام با شماره Plex';
	@override String get signInWithPlexCardSubtitle => 'این دستگاه را مجاز کنید سرورهای به اشتراک گذاشته شده اضافه می شوند.';
	@override String get signInWithPlexCardSubtitleScoped => 'مجوز یک حساب Plex. کاربران خانگی تبدیل به پروفایل.';
	@override String connectToMediaBrowserCard({required Object product}) => 'تماس با ${product}';
	@override String get connectToMediaBrowserCardSubtitle => 'URL سرور، نام کاربری و رمز عبور خود را وارد کنید.';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => 'ثبت نام در سرور ${product} شما. اتصال به ${name}.';
	@override String get borrowFromAnotherProfile => 'وام از یک پروفایل دیگر';
	@override String get borrowFromAnotherProfileSubtitle => 'استفاده مجدد از اتصال پروفایل دیگری. پروفایل های محافظت شده از PIN نیاز به یک PIN دارند.';
	@override String get invalidCredentials => 'نام کاربری یا رمز عبور نادرست';
	@override String get authResponseNotJson => 'پاسخ صدور گواهینامه معتبر نبود JSON';
	@override String get authResponseIncomplete => 'پاسخ ورود از سرور نامناسب بود.';
	@override String get quickConnectRejected => 'Quick Connect توسط سرور رد شد';
	@override String get quickConnectNotJson => 'پاسخ Quick Connect معتبر نبود JSON';
	@override String get quickConnectMissingFields => 'پاسخ Quick Connect یک کد یا راز را از دست می دهد';
	@override String get quickConnectPollRejected => 'Quick Connect درخواست توسط سرور رد شد';
	@override String get serverTimedOut => 'سرور به موقع پاسخ نمی دهد';
	@override String get responseNotJson => 'پاسخ سرور معتبر نبود JSON';
	@override String responseMissingIdentity({required Object product}) => 'پاسخ یک شناسه یا نام سرور را از دست می دهد - آیا این یک سرور ${product} است؟';
	@override String probeFailed({required Object error}) => 'نمی توانم به سرور دسترسی داشته باشم: ${error}';
	@override String enterAtLeastOneUrl({required Object product}) => 'حداقل یک URL سرور ${product} را وارد کنید.';
	@override String noReachableServer({required Object product}) => 'هیچ سرور قابل دسترس ${product} یافت نشد';
	@override String urlsPointToDifferentServers({required Object product}) => 'این URL ها به سرورهای مختلف ${product} اشاره می کنند.';
	@override String urlDoesNotMatchServer({required Object product}) => 'این URL مطابق با سرور ${product} نیست.';
	@override String get redirectUnsupported => 'سرور به یک URL پشتیبانی نشده هدایت می شود';
	@override String redirectDifferentHost({required Object product}) => 'سرور به یک میزبان متفاوت هدایت شده است.در URL نهایی ${product} به طور مستقیم وارد کنید.';
	@override String get redirectInsecure => 'سرور از HTTPS به یک URL نامناسب هدایت شده است';
	@override String redirectUnsupportedEnterFinal({required Object product}) => 'سرور به یک URL پشتیبانی نشده هدایت شده است.در URL نهایی ${product} به طور مستقیم وارد کنید.';
	@override String get directPlexServerUrl => 'Plex سرور URL';
	@override String get directPlexServerUrlHelper => 'IP محلی و پورت سرور رسانه Plex را وارد کنید.';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex توکن (اختیاری)';
	@override String get plexTokenHelper => 'اگر دسترسی بدون auth در این سرور مجاز است، آن را خالی نگه دارید.';
	@override String get plexTokenRequired => 'لطفا توکن Plex خود را وارد کنید (X-Plex-Token).';
	@override String get connectDirectPlexCard => 'Plex سرور رسانه ای (مستقیم / محلی)';
	@override String get connectDirectPlexCardSubtitle => 'اتصال مستقیم با استفاده از IP یا URL محلی بدون حساب plex.tv.';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => 'با استفاده از IP یا URL محلی به طور مستقیم به آن متصل شوید.به ${name} متصل شوید.';
	@override String get insecureTitle => 'اتصال بدون رمزگذاری';
	@override String insecureDescription({required Object url}) => '${url} از HTTP استفاده می‌کند. افراد حاضر در شبکه ممکن است گذرواژه، توکن‌ها و رسانه‌های شما را بخوانند یا تغییر دهند. در صورت امکان از HTTPS استفاده کنید. فقط اگر به این شبکه اعتماد دارید و خطر را می‌پذیرید ادامه دهید.';
	@override String get allowHttp => 'اجازه دادن به HTTP';
	@override String get httpsRequired => 'استفاده از HTTPS یا به صراحت اجازه یک اتصال غیر رمزگذاری شده.';
}

// Path: cast
class _Translations$cast$fa extends Translations$cast$en {
	_Translations$cast$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => 'پخش روی دستگاه';
	@override String get searching => 'در جستجوی دستگاه های...';
	@override String connectedTo({required Object device}) => 'به ${device} متصل شده است.';
	@override String get device => 'دستگاه پخش';
	@override String get readyToCast => 'آمادهٔ پخش روی دستگاه';
	@override String get subtitle => 'زیرنویس‌ها';
	@override String get serverNotAvailable => 'سرور رسانه ای در دسترس نیست.';
	@override String get stopCasting => 'توقف پخش روی دستگاه';
	@override String get castToDevice => 'پخش روی دستگاه';
	@override String get noEpisodeAvailable => 'هیچ قسمت ای برای پخش در دسترس نیست.';
	@override String get startFailed => 'نمی توانم شروع به کاستینگ کنم، سرور را چک کنید و دوباره امتحان کنید.';
}

// Path: automation
class _Translations$automation$fa extends Translations$automation$en {
	_Translations$automation$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => 'هیچ جلسه ویدئویی فعال برای کنترل وجود ندارد.';
}

// Path: notifications
class _Translations$notifications$fa extends Translations$notifications$en {
	_Translations$notifications$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => 'قسمت جدید';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appAccess
class _Translations$appAccess$fa extends Translations$appAccess$en {
	_Translations$appAccess$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'سعی کنید هر ویژگی را به صورت رایگان برای 7 روز امتحان کنید';
	@override String get description => 'یک آزمون هفت روزه را با دسترسی کامل به هر ویژگی PlezyNG آغاز کنید.در طول آزمون هیچ هزینه ای وجود ندارد و هیچ اشتراک ای وجود ندارد.پس از آزمون، یک خرید عمر در قیمت فروشگاه شما PlezyNG را برای یک عمر باز می کند.';
	@override String get trialEndedDescription => 'باز کردن هر ویژگی در PlezyNG برای زندگی با یک خرید در قیمت فروشگاه شما.';
	@override String get startTrial => 'امتحان هفت روزه رایگان من را آغاز کنید';
	@override String get trialActive => 'آزمون 7 روزه شما فعال است.';
	@override String get trialEnded => 'دادگاه هفت روزه شما به پایان رسیده است';
	@override String get trialStartFailed => 'من نمی توانم آزمایش را در این دستگاه ذخیره کنم لطفا دوباره امتحان کنید.';
	@override String get lifetimeTitle => 'PlezyNG برای زندگی باز شده است';
	@override String get lifetimeBody => 'با تشکر از شما، شما دسترسی طول عمر به هر ویژگی PlezyNG دارید.';
	@override String get manageTitle => 'PlezyNG دسترسی طول عمر';
	@override String get manageDescription => 'سعی کنید هر ویژگی را به مدت 7 روز رایگان کنید، سپس همه چیز را برای زندگی با یک پرداخت در قیمت فروشگاه خود باز کنید.';
	@override String buy({required Object price}) => 'باز کردن هر ویژگی برای ${price}';
	@override String get loadingPrice => 'قیمت فروشگاه...';
	@override String get retryPrice => 'بازگشت قیمت جستجو';
	@override String get restore => 'بازگرداندن خرید عمر';
	@override String get pending => 'خرید شما در انتظار پرداخت یا تایید است. دسترسی طول عمر بلافاصله پس از فروشگاه آن را تکمیل می کند.';
	@override String get storeUnavailable => 'خرید در دسترس نیست چک کنید که شما در فروشگاه ثبت نام کرده اید و خرید در این دستگاه مجاز است.';
	@override String get productNotFound => 'خرید دسترسی مادام‌العمر PlezyNG هنوز در این فروشگاه موجود نیست.';
	@override String get productQueryFailed => 'نمی توانم قیمت فروشگاه را بارگذاری کنم، اتصال خود را بررسی کنید و دوباره امتحان کنید.';
	@override String get purchaseFailed => 'خرید به پایان نرسید، دوباره امتحان کنید.';
	@override String get restoreFailed => 'من نمی توانستم به فروشگاه بروم تا خرید خود را بازگردانم.';
	@override String get nothingToRestore => 'شماره PlezyNG خرید طول عمر برای این حساب فروشگاه یافت شد.';
}

// Path: detail
class _Translations$detail$fa extends Translations$detail$en {
	_Translations$detail$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => 'در نهایت در ${time}';
}

// Path: watchLink
class _Translations$watchLink$fa extends Translations$watchLink$en {
	_Translations$watchLink$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => 'من نمی توانستم به یک سرور Plex برای این لینک دسترسی داشته باشم.';
	@override String get notFound => 'من نمی توانم این نمایش یا فیلم را در سرورهای Plex خود پیدا کنم.';
	@override String get ambiguous => 'این لینک با عناصر در بیش از یک سرور مطابقت دارد. اضافه کردن یک سرور به لینک.';
	@override String get plexOnly => 'مشاهده لینک ها در حال حاضر تنها از سرورهای Plex پشتیبانی می کند.';
	@override String get unsupportedItem => 'لینک های تماشا فقط می تواند یک نمایش یا یک فیلم را باز کند.';
	@override String get menuItem => 'مشاهده لینک';
	@override String get dialogTitle => 'نگاهی به لینک';
	@override String get dialogShowHint => 'با باز کردن این لینک، قسمت بعدی بازی می شود. &mode=shuffle را به پایان اضافه کنید تا نمایش را در shuffle بازی کنید.';
	@override String get dialogMovieHint => 'باز کردن این لینک فیلم را بازی می کند.';
	@override String get copy => 'کپی';
	@override String get copied => 'لینک کپی شده';
}

// Path: homeLayout
class _Translations$homeLayout$fa extends Translations$homeLayout$en {
	_Translations$homeLayout$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'خانه لایو';
	@override String get resetToast => 'خانه بازگرداندن به طرح اصلی Plezy قهرمان';
	@override String get resetHeroTitle => 'بازگرداندن طرح قهرمان به ذخیره سازی Plezy؟';
	@override String get resetHeroBody => 'تنظیمات قهرمان هر ردیف را از بین می برد و یک بنر چرخشی را در بالای خانه باز می گرداند، همانطور که قبل از اینکه ردیف های قهرمان وجود داشته باشد.';
	@override String get removeRowTitle => 'خانه را رها کنید؟';
	@override String removeRowBody({required Object title}) => '${title} حذف خواهد شد.این نمی تواند بدون آن باشد.';
	@override String get sync => 'همگام سازی';
	@override String get syncAccountTitle => 'طرح همگام سازی با حساب Plex شما';
	@override String get syncAccountOn => 'در: این دستگاه به اشتراک گذاری ترتیب ردیف، ردیف ها، قهرمان و اتوماتیک اسلاید با دستگاه های دیگر شما.';
	@override String get syncAccountOff => 'خاموش: این دستگاه طرح خود را حفظ می کند.';
	@override String get syncNow => 'همگام اکنون';
	@override String get plexHomeManager => 'Plex مدیر خانه';
	@override String get managePlexRows => 'مدیریت Plex ردیف در Plezy';
	@override String get managePlexRowsDescription => 'باز برای سازماندهی خطوط انتخاب شده در خانه';
	@override String get organizeHomeRows => 'سازماندهی خطوط خانگی';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} ردیف: حرکت، قهرمان، اتوماتیک، حذف';
	@override String organizeLibraryRows({required Object library}) => 'سازماندهی ${library} خطوط';
	@override String organizeLibraryRowsDescription({required Object n}) => 'ادامه تماشای + ${n} خطوط: حرکت, کتابخانه, خانه, قهرمان, اسلاید خودکار';
	@override String get renderAsHero => 'به عنوان یک کارت قهرمان';
	@override String get heroOnlySingleCollection => 'تنها زمانی در دسترس است که این ردیف به عنوان واقعی یک مجموعه حل می شود.';
	@override String get hero => 'قهرمان';
	@override String get autoSlide => 'اتومبیل اسلاید';
	@override String get autoSlideDescription => 'همچنین هر چند ثانیه به خودی خود اسلاید می کند. Arrows (PC) و d-pad (TV) همیشه کار می کنند و تایمر را دوباره راه اندازی می کنند.';
	@override String get autoSlideEditDescription => 'همچنین هر چند ثانیه به خودی خود اسلاید می کند. خاموش: فقط زمانی که بر روی یک شلیک (PC) کلیک کنید یا چپ / راست را روی دوربین (TV) فشار دهید حرکت می کند.';
	@override String get enableHeroFirst => 'قهرمانان اول';
	@override String get showOnHome => 'نمایش در صفحه اصلی';
	@override String get home => 'خانه';
	@override String get removeFromHome => 'حذف از خانه';
	@override String get selectRowsFirst => 'گزینه های زیر را انتخاب کنید.';
	@override String plexManagedRows({required Object n}) => '${n} Plex خطوط مدیریت شده';
	@override String get continueWatching => 'ادامه تماشا';
	@override String get continueWatchingLibraryDescription => 'این کتابخانه در حال پیشرفت است.';
	@override String get continueWatchingHomeDescription => 'روند پیشرفت مجدد نشان داده شده در خانه';
	@override String get nextUpHomeDescription => 'قسمت بعدی ناشناخته سریال به صورت جداگانه در خانه نمایش داده می شود';
	@override String get library => 'کتابخانه';
	@override String get showInRecommended => 'نمایش در کتابخانه توصیه شده';
	@override String get customPlexRow => 'مشخصات Plex خط';
	@override String get heroNeedsLibrary => 'نگاهی به کتابخانه اول – قهرمان نیاز به جایی برای نشان دادن';
	@override String get heroNeedsSurface => 'کتابخانه یا خانه را اول ببینید – قهرمان باید جایی برای نشان دادن';
	@override String get removeHub => 'حذف هاب';
	@override String get noPlexRows => 'شماره Plex ردیف های مدیریت شده برای این کتابخانه بازگردانده شده است.';
	@override String get openDetails => 'جزئیات باز';
	@override String get heroCards => 'کارت های قهرمان';
	@override String get tapHeroCard => 'دانلود کارت قهرمان';
	@override String get tvPlayFocus => 'تلویزیون از راه دور: برجسته دکمه بازی';
	@override String get tvPlayFocusDescription => 'D-pad down در دکمه Play متوقف می شود قبل از حرکت به ردیف بعدی.';
	@override String get tvWrap => 'برچسب های ارشیو: کارت های قهرمان';
	@override String get tvWrapDescription => 'فشردن چپ روی آخرین کارت، شما را به کارت اول برمی‌گرداند. با خاموش کردن این گزینه، حرکت در آخرین کارت متوقف می‌شود. فشردن راست روی کارت اول همیشه به نوار کناری می‌رود.';
	@override String get castOnHero => 'بازی بر روی باند های قهرمان';
	@override String get castOnHeroDescription => 'نشان دادن پرتاب در امتداد پایین یک بنر قهرمان.';
	@override String get customRows => 'سفارشی';
	@override String get loading => 'دانلود خانه لایه...';
	@override String get noCustomRows => 'هنوز هیچ خطوط معمولی';
	@override String get addRowHint => 'از اضافه کردن خانه برای ایجاد یکی استفاده کنید.';
	@override String get addHomeRow => 'اضافه کردن خانه راوی';
	@override String get addHomeRowDescription => 'یک دسته را انتخاب کنید؛ ردیف جدید به ترتیب به ترتیب به ترتیب اضافه می شود.';
	@override String get removeRow => 'حذف ردیف';
	@override String get recentlyAdded => 'جدیدترین‌ها';
	@override String get recentlyReleased => 'اخیرا منتشر شد';
	@override String get movieCollections => 'مجموعه فیلم ها';
	@override String get showCollections => 'نمایش مجموعه ها';
	@override String get rowTitle => 'راوی عنوان';
	@override String get content => 'محتوای';
	@override String get showThisRowIn => 'این ردیف را در:';
	@override String get libraryRecommended => 'کتابخانه توصیه می شود';
	@override String get heroCard => 'کارت قهرمان';
	@override String get heroCardDescription => 'نشان می دهد به عنوان یک کارت چرخش کامل به جای یک پوستر شیل.';
	@override String get heroUnavailableDescription => 'تنها زمانی در دسترس است که این ردیف به عنوان عنوان های واقعی یک مجموعه حل می شود – با بیش از یک مجموعه انتخاب شده، هیچ عنوانی برای چرخش وجود ندارد.';
	@override String get librariesSelection => 'کتابخانه ها (همه کتابخانه ها را بدون چک قرار دهید)';
	@override String get librariesMergedDescription => 'هر کتابخانه ای که در اینجا بررسی می شود در این یک ردیف ادغام می شود.';
	@override String get movieCollectionsSelection => 'مجموعه های فیلم (برای هر کتابخانه انتخاب شده همه غیرقابل بررسی را رها کنید)';
	@override String get showCollectionsSelection => 'نمایش مجموعه ها (برای هر کتابخانه ای که انتخاب کرده اید، همه آنها را بدون بررسی رها کنید)';
	@override String get collectionRowsDescription => 'اگر دقیقاً یک مجموعه با هم بازی می کند، عنوان های آن به طور مستقیم در ردیف نمایش داده می شود.اگر بیش از یک مجموعه با هم بازی می کند، هر مجموعه به عنوان یک پوستر نمایش داده می شود – برای باز کردن آن مجموعه آن را کلیک کنید.';
	@override String get allCollections => 'همه مجموعه ها';
	@override String get noRowsHere => 'هنوز هیچ خطی در اینجا وجود ندارد.';
	@override String get hideWatchedRows => 'پنهان کردن اشیاء مشاهده شده در ردیف ها';
	@override String get hideWatchedRowsDescription => 'عنوان های مشاهده شده به طور کامل خانه و کتابخانه را ترک می کنند ردیف های توصیه شده.';
	@override String get untitledCollection => 'جمع آوری نامناسب';
	@override String get moveRowHint => 'Up/Down: حرکت ردیف · انتخاب کنید: آن را در اینجا · بازگشت: لغو';
	@override String get organizeRowsHint => 'بر روی یک ردیف انتخاب کنید (یا نگه دارید انتخاب کنید): حرکت آن · چپ / راست: گزینه های ردیف · بازگشت: انجام شده';
	@override String get layoutNavDescription => 'انتخاب خطوط، کتابخانه ها و دسته های جمع آوری';
	@override String get editHomeRow => 'ویرایش خانه راوی';
	@override String get resetHeroButton => 'بازگرداندن طرح قهرمان به انبار Plezy';
	@override String get reorderingUnlocked => 'بازگرداندن مجدد';
	@override String get reorderingLocked => 'بازسازی قفل';
	@override String get rowsCanBeDragged => 'قفسه ها را می توان کشید – برای جلوگیری از آن قفل را تایپ کنید';
	@override String get tapLockToDrag => 'قفل را فشار دهید تا ردیف ها را کشید';
	@override String customRowLabel({required Object title}) => 'مشخصات : ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => 'پنهان کردن';
	@override String get remove => 'حذف';
	@override String get libraryResumeRow => 'این کتابخانه به صورت مجدد';
	@override String get pressAgainToDelete => 'فشار دوباره برای حذف';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => 'در';
	@override String get resetHeroButtonDescription => 'تنظیمات قهرمان هر ردیف را از بین می برد و یک بنر چرخشی را به بالا باز می گرداند، همانطور که قبل از اینکه ردیف های قهرمان وجود داشته باشد.';
	@override String get tapHeroCardDescription => 'انتخاب کنید که آیا تایپ کردن یا انتخاب یک کارت قهرمان شروع به پخش و یا باز کردن جزئیات آن.';
	@override String get heroTapPlayDescription => 'گزینه انتخاب شده را بلافاصله شروع کنید.';
	@override String get heroTapDetailsDescription => 'جزئیات مورد انتخاب را قبل از انتخاب یک عمل باز کنید.';
}

// Path: platform
class _Translations$platform$fa extends Translations$platform$en {
	_Translations$platform$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'PlezyNG به سرورهای رسانه ای و دستگاه های پخش در شبکه محلی شما متصل می شود.';
	@override String get locationPermission => 'PlezyNG از دسترسی مکان استفاده می کند زمانی که iOS آن را برای شناسایی شبکه محلی شما و اتصال به سرورهای رسانه ای شما نیاز دارد.';
	@override String get photoLibraryPermission => 'تصاویر را از کتابخانه عکس خود انتخاب کنید تا به عنوان آثار هنری رسانه ای مورد استفاده قرار گیرد.';
	@override String get cameraPermission => 'اسکن کدهای QR برای جفت کردن یک Companion Remote.';
}

// Path: universalMedia
class _Translations$universalMedia$fa extends Translations$universalMedia$en {
	_Translations$universalMedia$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'رسانه های باز';
	@override String get shortcutHelp => 'یک لینک، لیست پخش یا فایل برای این جلسه بازی کنید.';
	@override String get intro => 'لینک، لیست پخش یا فایل را باز کنید Playback از بازیکن استاندارد PlezyNG استفاده می کند و تاریخچه را به کتابخانه شما اضافه نمی کند.';
	@override String get openWhat => 'چه چیزی را دوست دارید باز کنید؟';
	@override String get stream => 'آدرس جریان';
	@override String get playlist => 'بازی لیست';
	@override String get files => 'فایل های دستگاه';
	@override String get favorites => 'ذخیره جریان مورد علاقه';
	@override String get address => 'آدرس رسانه ها';
	@override String get addressHelp => 'URL ها با پارامترهای اعتباربخشی یا امضای شناخته شده تنها برای این جلسه مورد استفاده قرار می گیرند و نمی توانند به عنوان محبوب ذخیره شوند.';
	@override String get displayName => 'نام نمایش (اختیاری)';
	@override String get displayNameHelp => 'یک نام کوتاه برای بازیکن و کنترل های رسانه سیستم را انتخاب کنید.';
	@override String get allowHttp => 'اجازه دادن به یک اتصال HTTP غیر رمزگذاری شده';
	@override String get allowHttpHelp => 'HTTP اتصال را رمزگذاری نمی کند. فقط در یک شبکه قابل اعتماد اجازه دهید. هنگامی که ممکن است از HTTPS استفاده کنید.';
	@override String get advancedProtocols => 'فقط MPV: یک آدرس RTSP، RTMP/RTMPS، UDP یا RTP را وارد کنید.این آدرس ها نمی توانند به عنوان محبوب ذخیره شوند.';
	@override String get liveStream => 'رفتار به عنوان زنده';
	@override String get liveStreamHelp => 'از این برای ویدئو یا رادیو زنده استفاده کنید.این برنامه نوار زمان، دکمه ها را پنهان می کند و گزینه Go-to-Time را انتخاب می کند.';
	@override String get privateSession => 'فقط این پخش از آدرس استفاده می کند. ذخیره یک جریان واجد شرایط مورد علاقه برای نگه داشتن آن در این پروفایل.';
	@override String get saveFavorite => 'ذخیره محبوب';
	@override String get playNow => 'اکنون بازی کنید';
	@override String get favoriteSaved => 'جریان محبوب به این پروفایل ذخیره شده است';
	@override String skippedEntries({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n,
		one: '${count} بدون پشتیبانی یا ورود نامناسب به لیست پخش.',
		other: '${count} بدون پشتیبانی و یا ورود نامناسب به لیست پخش.',
	);
	@override String get playlistAddress => 'آدرس Playlist';
	@override String get playlistAddressHelp => 'یک لیست پخش M3U، M3u8 یا PLS را از یک آدرس وب باز کنید لینک های جریان مستقیم لیست پخش را ذخیره نمی کنند.';
	@override String get choosePlaylist => 'انتخاب فایل playlist';
	@override String get openPlaylist => 'باز کردن playlist';
	@override String get playlistFormatsHelp => 'یک لیست پخش می تواند حاوی حداکثر 1000 آیتم و 2 مگابایت باشد.HLS به عنوان جریان ها باز می شود تا بازیکن بتواند کیفیت را انتخاب کند.';
	@override String get saveQueuePlaylist => 'ذخیره صف به‌صورت فهرست پخش';
	@override String get queuePlaylistSaved => 'فهرست پخش کنار فایل‌های رسانه ذخیره شد.';
	@override String get queuePlaylistUnavailable => 'این صف را نمی‌توان به‌صورت فهرست پخش محلی و قابل استفادهٔ دوباره ذخیره کرد.';
	@override String get queuePlaylistFolderRequired => 'محلی برای ذخیره در همان پوشهٔ فایل‌های صف انتخاب کنید.';
	@override String get noFavorites => 'در حال حاضر هیچ مورد علاقه ذخیره نشده است.Favorites در این پروفایل باقی بماند.';
	@override String get removeFavorite => 'حذف جریان مورد علاقه';
	@override String get filesHelp => 'فایل های صوتی، ویدئویی یا ISO را برای یک دوره موقت انتخاب کنید.فایلهای و URL ها به تاریخچه کتابخانه اضافه نمی شوند.';
	@override String get chooseFiles => 'انتخاب فایل ها';
	@override String fileQueue({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n,
		one: '1 فایل انتخاب شده',
		other: '${count} فایل های انتخاب شده',
	);
	@override String get wifiTransfer => 'ارسال فایل ها از طریق Wi-Fi';
	@override String get wifiTransferHelp => 'انتقال فایل های پشتیبانی شده از یک مرورگر در همان شبکه قابل اعتماد.';
	@override String get wifiTransferIntro => 'این آدرس را در یک مرورگر در دستگاه دیگری باز کنید فایل ها را انتخاب کنید تا آنها را به کتابخانه فایل ها و کتاب های این دستگاه اضافه کنید.';
	@override String get wifiTransferPrivacy => 'این دستگاه فایل ها را از طریق شبکه محلی شما دریافت می کند.هر کسی که این آدرس را می داند، می تواند تا زمانی که انتقال را متوقف کنید یا آدرس پس از 15 دقیقه به پایان برسد، فایل های خود را ارسال کند. حداکثر: 100 فایل، 4 GiB در هر فایل، 10 GiB کل.';
	@override String get wifiTransferStarting => 'در حال آماده سازی یک انتقال خصوصی و محدود به زمان ...';
	@override String get wifiTransferUnavailable => 'انتقال را نمی توان شروع کرد. دسترسی به شبکه محلی را بررسی کنید و دوباره آن را امتحان کنید.';
	@override String get openThisAddress => 'یکی از این آدرس ها را در دستگاه ارسال باز کنید.';
	@override String get copyAddress => 'کپی آدرس انتقال';
	@override String get addressCopied => 'آدرس انتقال کپی شده';
	@override String transferExpires({required Object time}) => 'این آدرس در ${time} به پایان می رسد.';
	@override String uploadCount({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n,
		one: '${count} فایل دریافت شده',
		other: 'فایل های ${count} دریافت شده',
	);
	@override String uploadedData({required Object size}) => 'دانلود ${size}';
	@override String get stopTransfer => 'توقف انتقال و نامناسب کردن آدرس';
	@override String get startTransfer => 'شروع انتقال';
	@override String get wifiImportedFiles => 'انتقال Wi-Fi';
	@override String get wifiBrowserTitle => 'ارسال فایل ها به PlezyNG';
	@override String get wifiBrowserIntro => 'فایل ها در کتابخانه فایل ها و کتاب های این دستگاه ذخیره می شوند حداکثر: 100 فایل، 4 GiB برای هر فایل، 10 GiB کل.';
	@override String get uploadFilesLabel => 'فایل ها برای ارسال';
	@override String get uploadSelected => 'دانلود فایل های انتخاب شده';
	@override String get uploadSelectFirst => 'اول یک یا چند فایل را انتخاب کنید.';
	@override String get uploading => 'ارسال';
	@override String get uploadComplete => 'فایل اضافه شده به PlezyNG.';
	@override String get uploadFailed => 'این صفحه را باز نگه دارید و دوباره آن را امتحان کنید.';
	@override String get liveCue => 'زنده';
	@override String get liveSession => 'جریان زنده';
	@override String get liveCueHelp => 'برای ویدئو یا رادیو زنده، اپلیکیشن نوار زمان را پنهان می کند و دکمه ها را از بین می برد.';
	@override String get sessionOnly => 'این بازی فقط یک جلسه است.';
	@override String get sessionOnlyHelp => 'Playback هرگز پیشرفت یا تاریخچه را ذخیره نمی کند.Save the stream as a favorite to keep it in this profile if it is eligible.';
	@override String get pictureAdjustments => 'تصحیح تصویر';
	@override String get pictureHelp => 'این تغییرات تصویر فقط بر این بازتاب تاثیر می گذارد.آنها زمانی که بازتاب به پایان می رسد، دوباره تنظیم می شوند.';
	@override String get resetPicture => 'بازگرداندن تصویر';
	@override String get brightness => 'روشنایی';
	@override String get contrast => 'تناقض';
	@override String get gamma => 'گاما';
	@override String get hue => 'هوی';
	@override String get saturation => 'Saturation';
	@override String get view360 => 'صفحه نمایش برای ویدئو 360 درجه';
	@override String get view360Help => 'استفاده از این برای ویدئو 360 درجه مساوی. MPV نیاز به فیلتر v360 FFmpeg برای این نمایش دارد.';
	@override String get view360Unavailable => 'این ساختار MPV نمی تواند فیلتر 360 درجه را اعمال کند.';
	@override String get view360Yaw => 'چشم انداز افقی';
	@override String get view360Pitch => 'دیدگاه عمودی';
	@override String get view360FieldOfView => 'زمینه دیدگاه';
	@override String get recordStream => 'رکورد جریان زنده';
	@override String get stopRecording => 'توقف و ذخیره ضبط';
	@override String get recordingStarted => 'ضبط فعال است.Leaving playback متوقف می شود و ضبط را ذخیره می کند.';
	@override String get recordingSaved => 'ضبط تمام شد و نجات یافت.';
	@override String get recordingActive => 'با استفاده از این دستگاه، اجازه دادن به پخش متوقف می شود و آن را ذخیره می کند.';
	@override String get recordingFormatHelp => 'برای ویدئو، MKV یا MPEG-TS را انتخاب کنید.';
	@override String get replaceRecordingTitle => 'این ضبط را جایگزین کنید؟';
	@override String get replaceRecordingHelp => 'PlezyNG در هنگام ضبط فایل فعلی را پشتیبان گیری می کند.اگر نتواند ضبط جدید را ذخیره کند، plezyNG پشتیبت را بازگرداند.';
	@override String get replaceRecording => 'جایگزین فایل';
	@override String get discHelp => 'یک دیسک را در درایو نوری این کامپیوتر باز کنید شما همچنین می توانید یک تصویر ISO از فایل های دستگاه را باز کنید.';
	@override String get discs => 'دیسک های نوری';
	@override String get editionOrTitle => 'نسخه یا عنوان دیسک';
	@override String get dvd => 'DVD';
	@override String get bluray => 'دانلود Blu-ray';
	@override String get audioCd => 'CD صوتی';
	@override String get discAvailability => 'پخش دیسک نیاز به ساخت MPV سازگار، درایو پشتیبانی شده و مجوز سیستم عامل دارد.';
	@override String get converterTitle => 'تبدیل یک فایل رسانه محلی';
	@override String get converterHelp => 'یک فایل محلی را تبدیل کنید یا آن را با FFmpeg.';
	@override String get converterIntro => 'تبدیل یک فایل صوتی یا ویدئویی محلی به فرمتی که بر روی دستگاه های مختلف کار می کند.';
	@override String get converterPrivacy => 'FFmpeg باید بر روی این کامپیوتر نصب شود.Conversion فقط فایل های محلی را می خواند.این جریان ها را دانلود نمی کند یا DRM را حذف نمی کند.';
	@override String get converterChooseInput => 'انتخاب فایل رسانه ای محلی';
	@override String get converterFormat => 'فرمت خروجی';
	@override String get converterMp4 => 'MP4 · H.264 و AAC';
	@override String get converterM4a => 'M4A · AAC صدا';
	@override String get converterMp3 => 'MP3 - صدا';
	@override String get allowFtp => 'اجازه FTP';
	@override String get allowFtpHelp => 'FTP رسانه ها را بدون رمزگذاری ارسال می کند.فقط در شبکه های قابل اعتماد استفاده کنید.';
	@override String get converterSaveAs => 'حفظ رسانه های تبدیل شده به عنوان';
	@override String get converterExtensionMismatch => 'یک فیل نام با افزونه خروجی انتخاب شده را انتخاب کنید.';
	@override String get converterUnsupportedInput => 'یک فایل صوتی یا ویدئویی را انتخاب کنید.';
	@override String get converterLocalOnly => 'فایل انتخاب شده به عنوان یک مسیر دستگاه محلی در دسترس نیست.';
	@override String get converterReplaceTitle => 'این فایل را جایگزین کنید؟';
	@override String get converterReplaceHelp => 'PlezyNG فایل موجود را تا زمانی که کپی تبدیل شده ذخیره شود، پشتیبان گیری می کند.';
	@override String get converterStarting => 'شروع به استفاده از FFmpeg...';
	@override String get converterProgress => 'با استفاده از این کامپیوتر...';
	@override String get converterComplete => 'فایلهای جدید آماده است.';
	@override String get converterFfmpegMissing => 'FFmpeg از دست رفته است یا از این فرمت پشتیبانی نمی کند.';
	@override String get converterFailed => 'بررسی کنید که فایل منبع قابل خواندن است و مقصد به اندازه کافی فضای رایگان دارد.';
	@override String get converterCancelled => 'تبدیل لغو شد خروجی نامناسب حذف شد.';
	@override String get converterDesktopOnly => 'تبدیل محلی در کامپیوترهای دسکتاپ با نصب FFmpeg در دسترس است.';
	@override String get converterStart => 'تبدیل فایل';
	@override String get mediaToolsTitle => 'ابزار رسانه ای';
	@override String get mediaToolsShortcut => 'ضبط و یا به اشتراک گذاری رسانه ها، اضافه کردن افزونه های جستجو، و یا استفاده از خط فرمان.';
	@override String get mediaToolsIntro => 'یک ابزار متمرکز را انتخاب کنید. ضبط و جریان خارج از استفاده از FFmpeg نصب شده در این دسکتاپ. افزونه ها و فرمان های CLI استفاده از درخواست های HTTPS محدود و جریان Open media موجود.';
	@override String get mediaToolsAccessibility => 'گزینه های ابزار و کنترل ها با تمرکز لمسی، شاخص، صفحه کلید و D-pad کار می کنند. ضبط، به اشتراک گذاری و تغییرات وضعیت جستجو اعلام می شود.';
	@override String get mediaTool => 'ابزار رسانه ای';
	@override String get captureIntro => 'صفحه نمایش یا دوربین خود را به یک فایل MP4 در این کامپیوتر ضبط کنید. FFmpeg باید نصب شود و کدگذاری H.264 را شامل شود.';
	@override String get captureNoDevices => 'هیچ صفحه نمایش و یا دوربین یافت نشد. بررسی FFmpeg پشتیبانی از ضبط و اجازه های حفظ حریم خصوصی سیستم عامل.';
	@override String get captureSource => 'صفحه نمایش یا دوربین';
	@override String get captureScreen => 'صفحه نمایش';
	@override String get captureAudioSource => 'ورودی صوتی (اختیاری)';
	@override String get captureAudioHelp => 'اضافه کردن صدا از یک میکروفون یا ورودی در دسترس. انتخاب دستگاه بستگی به FFmpeg و مجوزهای سیستم دارد.';
	@override String get captureAudioNone => 'بدون صدا';
	@override String get captureDefaultAudio => 'واردات صوتی پیش فرض';
	@override String get captureWaylandHelp => 'Wayland limits this XWayland capture to the X display. Windows outside XWayland may not appear.';
	@override String get captureFrameRate => 'نرخ ضبط فریم';
	@override String get capturePrivacy => 'ضبط فقط به فایل انتخاب شده ذخیره می شود. ضبط میکروفون اختیاری است. PlezyNG ضبط را بارگذاری نمی کند.';
	@override String get captureSaveAs => 'ضبط صفحه نمایش به عنوان';
	@override String get captureExtensionMismatch => 'انتخاب یک نام فیل که در .mp4 به پایان می رسد.';
	@override String get captureFfmpegMissing => 'FFmpeg یا کدگذاری ویدئویی H.264 در دسترس نیست. نصب یک ساختار FFmpeg پشتیبانی شده، سپس دوباره امتحان کنید.';
	@override String get captureFailed => 'ضبط نمی تواند ذخیره شود. بررسی اجازه دستگاه، ذخیره سازی در دسترس، و پشتیبانی از FFmpeg.';
	@override String get captureSaved => 'ضبط صفحه نمایش نجات یافت';
	@override String get captureElapsedLabel => 'زمان ضبط';
	@override String get captureStart => 'شروع ضبط';
	@override String get capturePreview => 'پیش‌نمایش در پخش‌کننده';
	@override String get capturePreviewHelp => 'منبع انتخاب‌شده را در پخش‌کنندهٔ استاندارد پیش‌نمایش کنید. این پیش‌نمایش فقط برای همین نشست است و ضبطی ذخیره نمی‌کند. پشتیبانی دستگاه و مجوزها به MPV و سیستم‌عامل بستگی دارد. پیش‌نمایش فقط از ویدیو استفاده می‌کند؛ ضبط‌های ذخیره‌شده می‌توانند صدای اختیاری داشته باشند.';
	@override String get capturePreviewActive => 'پیش‌نمایش زنده · بدون ضبط';
	@override String get captureStop => 'توقف و نجات';
	@override String get captureMode => 'دستگیری';
	@override String get shareMode => 'به اشتراک گذاری';
	@override String get shareIntro => 'ارسال یک فایل رسانه محلی به دستگاه دیگری در شبکه خصوصی خود.PlezyNG یک جریان موقت HLS ایجاد می کند.';
	@override String get sharePrivacy => 'هر کسی در شبکه محلی شما که لینک خصوصی را دریافت می کند می تواند در حالی که فعال است تماشا کند. لینک پس از 60 دقیقه به پایان می رسد. توقف به اشتراک گذاری برای بستن سرور و لغو لینک.';
	@override String get shareChooseFile => 'انتخاب فایل های رسانه ای';
	@override String get shareChooseHelp => 'یک فایل صوتی یا ویدئویی محلی را انتخاب کنید.این فایل در این کامپیوتر باقی می ماند.';
	@override String get shareFfmpegMissing => 'FFmpeg یا رمزگذاری های H.264/AAC در دسترس نیست. نصب FFmpeg با پشتیبانی از رمزگذاری H.264 و AAC.';
	@override String get shareFailed => 'جریان نمی توانست به طور غیرمنتظره شروع یا متوقف شود. بررسی FFmpeg و دسترسی به شبکه.';
	@override String get shareActive => 'جریان در شبکه خصوصی شما آماده است.';
	@override String get shareEnded => 'رسانه ها به پایان رسیدند و دیگر به اشتراک نمی گذارند.';
	@override String get shareStopped => 'به اشتراک گذاری متوقف شده است لینک موقت دیگر معتبر نیست.';
	@override String get shareUrlCopied => 'آدرس جریان کپی شده است';
	@override String get shareOpenUrl => 'این آدرس را در یک بازیکن در دستگاه دیگر باز کنید.';
	@override String get shareQrLabel => 'کد QR برای آدرس جریان موقت';
	@override String get shareQrHelp => 'اسکن با یک بازیکن سازگار متصل به همان شبکه خصوصی.';
	@override String get shareHttpHint => 'This stream uses unencrypted HTTP. In PlezyNG, allow HTTP before opening it.';
	@override String get shareCopyUrl => 'کپی آدرس جریان';
	@override String get shareExpiresLabel => 'لینک به پایان می رسد';
	@override String get shareStarting => 'در حال آماده سازی جریان...';
	@override String get shareStart => 'شروع به اشتراک گذاری';
	@override String get shareStop => 'توقف به اشتراک گذاری';
	@override String get extensionsMode => 'تمدید و CLI';
	@override String get extensionsIntro => 'برای یافتن رسانه ها یک افزونه جستجو داده اضافه کنید.نتیجه را انتخاب کنید تا آن را در فرم آشنا Open media بارگذاری کنید.';
	@override String get extensionsPrivacy => 'یک مانیفست می تواند یک نقطه جستجو HTTPS و میدان های پاسخ نقشه را تعریف کند. آن را نمی تواند کد را اجرا کند، عنوان درخواست را اضافه کند، فایل ها را بخواند، یا دستورالعمل های شل را راه اندازی کند.';
	@override String get extensionImport => 'اضافه کردن Manifesto';
	@override String get extensionEmpty => 'هنوز هیچ سرویس جستجو وجود ندارد. انتخاب یک فایل قابل اعتماد آشکار JSON برای اضافه کردن یکی.';
	@override String get extensionChoose => 'خدمات جستجو';
	@override String get extensionSearchConsent => 'هر جستجو کلمات خود را به این سرویس HTTPS ارسال می کند.نتایج تنها پس از انتخاب یکی باز می شود.';
	@override String get extensionSearchLabel => 'جستجو رسانه ها';
	@override String get extensionSearch => 'جستجو';
	@override String get extensionSearching => 'جستجو...';
	@override String get extensionNoResults => 'نتایج رسانه های امن بازگردانده نشده است.مطالعه دیگری را امتحان کنید.';
	@override String get extensionInstallTitle => 'این سرویس جستجو را اضافه کنید؟';
	@override String get extensionReplaceTitle => 'این سرویس جستجو را به روز کنید؟';
	@override String get extensionService => 'خدمات';
	@override String get extensionEndpoint => 'HTTPS نقطه نهایی';
	@override String get extensionConsent => 'متن جستجوی شما به این سرویس ارسال می شود.این مانیفست هیچ کد اجرا نمی شود.با ادامه فقط اگر به این نقطه نهایی اعتماد کنید.';
	@override String get extensionInstall => 'اضافه کردن خدمات';
	@override String get extensionReplace => 'خدمات به روز رسانی';
	@override String get extensionRemoveTitle => 'این سرویس جستجو را حذف کنید؟';
	@override String get extensionRemoveHelp => 'این سرویس را از این پروفایل حذف می کند.PlezyNG با نقطه نهایی آن تماس نمی گیرد.';
	@override String get extensionRemove => 'حذف خدمات';
	@override String get extensionInvalidManifest => 'این فایل یک مانیفست افزونه پشتیبانی نشده است.نگاه کنید به راهنمای Open media برای فرمت.';
	@override String get extensionSaveFailed => 'این افزونه نمی تواند به پروفایل فعال ذخیره شود.';
	@override String get extensionSearchFailed => 'سرویس جستجو پاسخ معتبر را بازگردانده است.نقطه نهایی را بررسی کنید و دوباره امتحان کنید.';
	@override String get cliTitle => 'خط فرمان';
	@override String get cliHelp => 'از راهنمای plezyctl برای تأیید یک مانیفست یا جستجو برای همان افزونه استفاده کنید. قبل از هر جستجو، خدمات HTTPS خود را بررسی کنید. نتایج در فرم رسانه های موجود باز می شود.';
	@override String get cliCopyExample => 'کپی دستور نمونه';
	@override String get cliCopied => 'دستور نمونه کپی شده است.';
}

// Path: fileSources
class _Translations$fileSources$fa extends Translations$fileSources$en {
	_Translations$fileSources$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'فایل ها و کتاب ها';
	@override String get subtitle => 'خواندن، گوش دادن و تماشای از فایل های خود را.';
	@override String get add => 'منبع اضافه کنید';
	@override String get importFiles => 'واردات فایل ها';
	@override String get localFiles => 'در این دستگاه';
	@override String get source => 'منبع';
	@override String get name => 'نام';
	@override String get endpoint => 'سرور URL';
	@override String get smbEndpointHint => 'مثال: smb://nas/Movies';
	@override String get smbEndpointInvalid => 'یک سرور SMB و یک پوشهٔ اشتراکی وارد کنید.';
	@override String get root => 'پوشه یا پیشوند';
	@override String get smbFolderHelp => 'برای استفاده از کل پوشهٔ اشتراکی، خالی بگذارید؛ یا پوشه‌ای درون آن وارد کنید.';
	@override String get username => 'نام کاربری';
	@override String get smbDomain => 'دامنه (اختیاری)';
	@override String get password => 'گذرواژه';
	@override String get token => 'API توکن';
	@override String get accessKey => 'دسترسی کلید ID';
	@override String get secretKey => 'کلید دسترسی مخفی';
	@override String get sessionToken => 'تگ های جلسه (اختیاری)';
	@override String get region => 'منطقه';
	@override String get clientId => 'OAuth مشتری ID';
	@override String get clientSecret => 'OAuth Client Secret (فقط Google Desktop)';
	@override String get allowHttp => 'اجازهٔ اتصال HTTP بدون رمزگذاری در یک شبکهٔ مورد اعتماد';
	@override String get smbEncryption => 'رمزگذاری اتصال SMB3';
	@override String get smbEncryptionHint => 'اگر دستگاه NAS پشتیبانی می‌کند، از رمزگذاری SMB3 استفاده کنید.';
	@override String get connect => 'اتصال';
	@override String get cancel => 'لغو کردن';
	@override String get save => 'ذخیره';
	@override String get close => 'بستن';
	@override String get removeSource => 'منبع ناپایدار';
	@override String get disconnectMessage => 'اتصال به این منبع قطع شود؟ فایل‌های دانلودشده و سابقهٔ خواندن و شنیدن شما در این دستگاه باقی می‌مانند.';
	@override String get localFolder => 'انتخاب پوشه';
	@override String get empty => 'هنوز چیزی در اینجا نیست';
	@override String get emptyHint => 'منبع را اضافه کنید یا یک کتاب، کتاب صوتی، موسیقی یا ویدئو وارد کنید.';
	@override String get search => 'جستجو برای این پوشه';
	@override String get searchCached => 'کتابخانه نجات یافت';
	@override String get refresh => 'به‌روز‌رسانی';
	@override String get loadMore => 'بار بیشتر';
	@override String get offline => 'در دسترس offline';
	@override String get download => 'بایگانی Offline';
	@override String get removeDownload => 'حذف کپی آفلاین';
	@override String get continueReading => 'به خواندن ادامه دهید';
	@override String get continueListening => 'به گوش دادن ادامه دهید';
	@override String get continueWatching => 'ادامه تماشا';
	@override String get read => 'خواندن';
	@override String get listen => 'گوش دادن';
	@override String get play => 'اجرا کردن';
	@override String get pause => 'مکث';
	@override String get stop => 'توقف';
	@override String get startOver => 'شروع به';
	@override String get finished => 'پایان یافت';
	@override String get markFinished => 'مارک به پایان رسید';
	@override String get markUnfinished => 'مارک بی نهایت';
	@override String get editions => 'نسخه ها و فایل ها';
	@override String get chapters => 'فصل ها';
	@override String get bookmarks => 'کتاب ها و یادداشت ها';
	@override String get bookmark => 'اضافه کردن کتاب';
	@override String get highlight => 'برجسته';
	@override String get note => 'یادداشت';
	@override String get delete => 'حذف';
	@override String get export => 'صادرات یادداشت';
	@override String get exported => 'برچسب ها صادرات';
	@override String get sync => 'پیشرفت همگام';
	@override String get synced => 'پیشرفت های همگام';
	@override String get conflict => 'دستگاه دیگری دارای موقعیت متفاوت است. انتخاب کنید که کجا ادامه دهید.';
	@override String get useLocal => 'استفاده از این دستگاه';
	@override String get useRemote => 'استفاده از دستگاه های دیگر';
	@override String get history => 'تاریخچه موقعیت';
	@override String get groupAudio => 'گوش دادن به عنوان یک کتاب صوتی';
	@override String get groupHint => 'فایل های صوتی که در حال حاضر در این پوشه بارگذاری می شوند را ترکیب کنید.اول تمام صفحات را بارگذاری کنید.';
	@override String get order => 'دستور فایل';
	@override String get moveUp => 'حرکت بالا';
	@override String get moveDown => 'حرکت به پایین';
	@override String get speed => 'سرعت پخش';
	@override String get sleep => 'زمان خواب';
	@override String get sleepOff => 'خاموش';
	@override String get endChapter => 'پایان فصل';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} دقیقه',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} دقیقه',
	);
	@override String get skipBack => 'بازگشت به Sk';
	@override String get skipForward => 'کشتی جلو';
	@override String get smartRewind => 'بازگشت هوشمند پس از استراحت';
	@override String get playbackOptions => 'گزینه های گوش دادن';
	@override String remaining({required Object time}) => '${time} باقی مانده';
	@override String get contents => 'محتوای';
	@override String get readerSettings => 'خواندن تنظیمات';
	@override String get fontSize => 'اندازه متن';
	@override String get lineHeight => 'خط فضایی';
	@override String get margin => 'مارگین';
	@override String get font => 'نوع چهره';
	@override String get serif => 'سریف';
	@override String get sans => 'بدون سریف';
	@override String get mono => 'تک‌فاصله';
	@override String get columns => 'ستون ها';
	@override String get scroll => 'چرخش عمودی';
	@override String get justify => 'تراز دوطرفهٔ متن';
	@override String get readerTheme => 'صفحه ظاهر';
	@override String get appTheme => 'پیگیری برنامه های کاربردی';
	@override String get paper => 'کاغذ';
	@override String get sepia => 'سپیا';
	@override String get night => 'شب';
	@override String get readAloud => 'این صفحه را با صدای بلند بخوانید';
	@override String get readAlong => 'خواندن همراه با صدا';
	@override String get stopReading => 'توقف خواندن با صدا';
	@override String get searchBook => 'جستجو در کتاب';
	@override String get noMatches => 'هیچ بازی';
	@override String get previousPage => 'صفحه قبلی';
	@override String get nextPage => 'صفحه بعدی';
	@override String page({required Object number}) => 'صفحه ${number}';
	@override String get externalBlocked => 'لینک های کتاب خارجی در خواننده غیرفعال می شوند.';
	@override String get loading => 'باز کردن...';
	@override String get narrator => 'داستان نویس';
	@override String get audio => 'صدا';
	@override String get video => 'ویدئو';
	@override String get ebooks => 'کتاب Ebook';
	@override String get all => 'همه';
	@override String get downloads => 'فایل های غیر آنلاین';
	@override String get confirmDelete => 'نسخهٔ آفلاین انتخاب‌شده حذف شود؟ موقعیت خواندن یا شنیدن و یادداشت‌های شما حفظ می‌شوند.';
	@override String get errorAuthentication => 'برای اتصال دوباره به این منبع، دوباره وارد حساب شوید.';
	@override String get errorPermission => 'این منبع دسترسی به فایل مورد نظر را فراهم نکرده است.';
	@override String get errorUnavailable => 'منبع در دسترس نیست. دوباره امتحان کنید یا یک کپی غیر آنلاین را باز کنید.';
	@override String get errorUnsupported => 'این فرمت یا اتصال در این دستگاه پشتیبانی نمی شود.در راهنمای تنظیم منبع بررسی کنید.';
	@override String get errorInvalidData => 'این فایل یا پاسخ سرور نمی تواند به طور ایمن خوانده شود.';
	@override String get errorCancelled => 'این عملیات لغو شد.';
	@override String get errorConflict => 'موقعیت در جلسه دیگری تغییر کرده است.نمایش را برای انتخاب موقعیت دوباره باز کنید.';
	@override String get signIn => 'ورود';
	@override String get reconnect => 'دوباره متصل';
	@override String get folderHelp => 'برای شروع از پوشهٔ ریشهٔ منبع، این قسمت را خالی بگذارید. نشانی‌های S3 شامل نام باکت هستند.';
	@override String get preferences => 'ترجیحات';
	@override String get timePosition => 'موقعیت';
	@override String get audioTrack => 'Audio Track';
	@override String get subtitleTrack => 'زیرنویس Track';
	@override String get none => 'هیچکدام';
	@override String get fullscreen => 'تمام صفحه';
	@override String get syncLocation => 'فاکتور پیشرفت (اختیاری)';
	@override String get syncLocationHint => 'یک پوشه اختصاص داده شده WebDAV برای PlezyNG وضعیت. استفاده از نوشتن مشروط؛ رسانه ها تغییر نمی کند.';
	@override String get audiobooks => 'کتاب های صوتی';
	@override String get comics => 'کمیک‌ها';
	@override String get scan => 'اسکن برای کتاب ها و رسانه ها';
	@override String get browserReader => 'خواننده باز';
	@override String get browserReaderHelp => 'خواننده در مرورگر شما باز است. PlezyNG را باز نگه دارید تا محل و یادداشت های خود را ذخیره کنید.';
	@override String get on => 'در';
	@override String get advancedSetup => 'App ثبت نام';
	@override String get microsoftSignIn => 'ثبت نام با مایکروسافت';
	@override String get zoomIn => 'زوم در';
	@override String get zoomOut => 'زوم بیرون';
	@override String get fitPage => 'صفحه مناسب';
	@override String get fitWidth => 'مناسب پهنای باند';
	@override String get actualSize => 'حجم فعلی';
	@override String get goToPage => 'به صفحه برو';
	@override String get goToSection => 'به فصل بروید';
	@override String pageRange({required Object count}) => 'عددی از ۱ تا ${count} وارد کنید';
	@override String get pageLayout => 'صفحه Layout';
	@override String get automatic => 'اتوماتیک';
	@override String get singlePage => 'صفحه تک';
	@override String get twoPages => '2 صفحه';
	@override String get readingDirection => 'خواندن جهت';
	@override String get leftToRight => 'سمت چپ به سمت راست';
	@override String get rightToLeft => 'از راست به چپ';
	@override String get letterSpacing => 'نامه فضایی';
	@override String get wordSpacing => 'کلمه فضا';
	@override String get readerControlsHelp => 'برای بزرگ‌کردن صفحه‌ها، دو انگشت را از هم باز کنید یا از کنترل‌های بزرگ‌نمایی استفاده کنید. برای جابه‌جایی صفحه بکشید. Ctrl/⌘ همراه + یا − بزرگ‌نمایی را تنظیم می‌کند؛ Ctrl/⌘ همراه 0 آن را بازنشانی می‌کند. Page Up و Page Down صفحه را عوض می‌کنند.';
	@override String get imagePage => 'صفحه کمیک';
	@override String get resetReader => 'تنظیم مجدد ترجیحات خواندن';
	@override String get zoom => 'پوشش دادن';
	@override String get useFiles => 'استفاده از فایل ها و کتاب ها';
	@override String get cancelScan => 'حذف اسکن';
	@override String get googleDrive => 'Google Drive';
	@override String get offlineQuota => 'محدودیت دانلود Offline';
	@override String get offlineQuotaHelp => 'حداکثر فضای مورد استفاده برای کپی های آفلاین، فایل های وارد شده و دانلود ها را تنظیم کنید. کاهش محدودیت کپی موجود را حذف نمی کند.';
	@override String get offlineStorageUsage => 'ذخیره سازی آفلاین';
	@override String get reservedStorage => 'ذخیره شده';
	@override String get downloadQueue => 'دانلود Queue';
	@override String get downloadRunning => 'دانلود';
	@override String get downloadQueued => 'منتظر';
	@override String get downloadPaused => 'استراحت';
	@override String get downloadFailed => 'نیاز به عقب نشینی';
	@override String get importing => 'واردات';
	@override String get importInterrupted => 'واردات متوقف شد · حذف به روشن';
	@override String get errorQuotaExceeded => 'محدودیت ذخیره سازی آفلاین به دست آمده است. بالا بردن محدودیت یا حذف یک کپی دانلود شده.';
	@override String get errorStorageLow => 'ذخیره سازی رایگان دستگاه به اندازه کافی برای حفظ ذخایر محافظت نشده است.';
	@override String get errorStorageUnavailable => 'PlezyNG نمی توانست ذخیره سازی رایگان دستگاه را بررسی کند، بنابراین نوشتن متوقف شد.';
	@override String get removeDownloadJob => 'دانلود حذف';
	@override String get downloadAlreadyComplete => 'این دانلود قبل از اینکه بتواند حذف شود به پایان رسید.این آیتم اکنون در دسترس است آفلاین.';
	@override String get confirmRemoveDownloadJob => 'این دانلود را حذف کنید و هر گونه داده ای که به طور جزئی دانلود شده است، حذف کنید؟ موقعیت و یادداشت های شما باقی خواهد ماند.';
}

// Path: lending
class _Translations$lending$fa extends Translations$lending$en {
	_Translations$lending$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'کتابخانه های عمومی';
	@override String get add => 'اضافه کردن کتابخانه';
	@override String get other => 'کتابخانه دیگری';
	@override String get libraryName => 'نام کتابخانه';
	@override String get libraryUrl => 'وبسایت کتابخانه';
	@override String get libraryUrlHint => 'از فهرست کتابخانه یا صفحهٔ ورود آن استفاده کنید.';
	@override String get intro => 'کتاب را از کتابخانه خود قرض بگیرید کتاب های خود را در نزدیکی خود نگه دارید.';
	@override String get handoff => 'با سرویس خود کتابخانه، وارد حساب شوید، کتاب امانت بگیرید و با امنیت بخوانید.';
	@override String get openService => 'کتابخانه باز';
	@override String get findLibrary => 'پیدا کردن کتابخانه';
	@override String get search => 'جستجو برای کتاب ها و نویسندگان';
	@override String get catalogue => 'کاتالوگ';
	@override String get loans => 'امانت‌ها';
	@override String get holds => 'رزروها';
	@override String get signIn => 'ثبت نام با کتابخانه خود';
	@override String get waiting => 'ثبت نام را در مرورگر خود به پایان برسانید و سپس به اینجا برگردید.';
	@override String get cancel => 'لغو کردن';
	@override String get disconnect => 'حذف کتابخانه';
	@override String get disconnectMessage => 'این کتابخانه از این نمایه حذف شود؟ امانت‌ها و رزروهای شما در کتابخانه باقی می‌مانند.';
	@override String get getBook => 'کتاب را بخوانید';
	@override String get checkAvailability => 'بررسی در دسترس بودن';
	@override String get available => 'آمادهٔ امانت گرفتن';
	@override String get unavailable => 'در حال حاضر در دسترس نیست';
	@override String get borrow => 'امانت گرفتن';
	@override String get placeHold => 'رزرو کردن';
	@override String get returnBook => 'بازگرداندن پیش از موعد';
	@override String get cancelHold => 'لغو رزرو';
	@override String get confirmBorrow => 'این کتاب را از کتابخانه خود قرض می دهید؟';
	@override String get confirmReturn => 'این عنوان اکنون بازگردانده شود؟ برای ادامه ممکن است لازم باشد دوباره آن را امانت بگیرید.';
	@override String get confirmCancelHold => 'رزرو شما برای این عنوان لغو شود؟';
	@override String get email => 'ارسال ایمیل اطلاع رسانی';
	@override String due({required Object date}) => 'موعد بازگشت: ${date}';
	@override String queue({required Object position}) => 'موقعیت ${position} در خط';
	@override String get empty => 'هنوز هیچ عنوانی در اینجا وجود ندارد.';
	@override String get openLibraryNote => 'فهرست Open Library را مرور کنید. گزینه‌های خواندن و امانت گرفتن در صفحهٔ هر عنوان نمایش داده می‌شوند.';
	@override String get more => 'بار بیشتر';
	@override String get gateway => 'کتابخانه ثبت نام در سرویس';
	@override String get gatewayHint => 'توسط کتابخانه یا مدیر PlezyNG ارائه شده است.';
	@override String get advanced => 'کتابخانه ادغام';
	@override String get loadLibraries => 'کتابخانه خود را انتخاب کنید';
	@override String get expired => 'مدت این امانت به پایان رسیده است.';
	@override String get updated => 'کتابخانه به روز شده';
	@override String get continueService => 'ادامه خدمت';
	@override String get comingSoon => 'وام های جدید در آینده ای نزدیک';
	@override String get comingSoonDescription => 'شما می توانید از کتابخانه خود در Libby استفاده کنید در حالی که ما آن را به اتصال می رسانیم.';
	@override String get suspendHold => 'تعلیق رزرو';
	@override String get resumeHold => 'ازسرگیری رزرو';
	@override String get suspendMessage => 'جای خود را در صف حفظ کنید و اجازه دهید خوانندهٔ بعدی این نسخه را امانت بگیرد؟ می‌توانید بعداً رزرو را از سر بگیرید.';
	@override String get resumeMessage => 'این رزرو از سر گرفته شود تا کتابخانه بتواند نسخهٔ بعدیِ موجود را به شما پیشنهاد دهد؟';
	@override String get editEmail => 'تغییر ایمیل اطلاع رسانی';
}

// Path: audiobook
class _Translations$audiobook$fa extends Translations$audiobook$en {
	_Translations$audiobook$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get syncTitle => 'خواندن و گوش دادن Sync';
	@override String get syncHelp => 'موقعیت های خواندن، موقعیت های گوش دادن، وضعیت تکمیل، برچسب ها و یادداشت ها را در سراسر دستگاه های خود نگه دارید.یک حساب ذخیره سازی پیوسته را انتخاب کنید و از همان کد همگام سازی در هر دستگاه استفاده کنید.خواندن و گوش دادن جداگانه باقی می ماند.';
	@override String get addSyncSource => 'در ابتدا Google Drive، OneDrive، Dropbox، WebDAV یا S3 را به فایل ها و کتاب ها اضافه کنید.';
	@override String get syncDestination => 'حساب ذخیره سازی Sync';
	@override String get syncFolder => 'فاکتور یا پیش فرض';
	@override String get syncCode => 'کد همگام خصوصی';
	@override String get syncCodeHelp => 'یک کد را در دستگاه اول خود ایجاد کنید، سپس آن کد را در دستگاه های دیگر خود وارد کنید. یک کپی خصوصی نگه دارید: این کلید وضعیت رمزگذاری شده شماست.';
	@override String get showCode => 'نمایش یا پنهان کردن کد همگام سازی';
	@override String get newSyncCode => 'ایجاد کد جدید همگام سازی';
	@override String get saveSync => 'حفظ و همگام سازی';
	@override String get disableSync => 'در این دستگاه همگام سازی را خاموش کنید.';
	@override String get syncSourceDisconnect => 'حذف این منبع در اینجا خواندن و گوش دادن به همگام سازی را خاموش می کند.فایلهای همگام سازی رمزگذاری شده در ارائه دهنده باقی می ماند.';
	@override String get syncReconnect => 'بازگرداندن حساب ذخیره سازی';
	@override String lastSynced({required Object time}) => 'آخرین ارسال شده در ${time}';
	@override String get syncConflicts => 'انتخاب کنید که کجا بازگردانید';
	@override String get conflictHelp => 'این تغییرات به صورت مستقل انجام شده است. گزینه ای را انتخاب کنید که موقعیت یا نسخه برچسب را برای نگه داشتن داشته باشید. یک زمان بندی بعدی یا درصد بالاتر به طور خودکار برنده نمی شود.';
	@override String syncDevice({required Object device}) => 'تجهیزات ${device}';
	@override String get syncUnknownDevice => 'دستگاه ناشناخته';
	@override String get deletedBookmark => 'برچسب حذف شده';
	@override String get finished => 'به پایان رسید';
	@override String readingPosition({required Object percent}) => 'خواندن · ${percent}%';
	@override String get chapterTimeline => 'فصل پیشرفت';
	@override String get bookTimeline => 'کتاب کامل پیشرفت';
	@override String bookRemaining({required Object time}) => 'زمان باقی مانده در این کتاب: ${time}';
	@override String chapterRemaining({required Object time}) => 'زمان باقی مانده در این فصل: ${time}';
	@override String get unknownRemaining => 'تمام زمان در دسترس به عنوان قطعات بازی می شود';
	@override String get undoSeek => 'آخرین جستجو';
	@override String get customSpeed => 'سرعت بازی Custom Playback';
	@override String get speedHelp => 'سرعت را از 0.25× تا 4× انتخاب کنید.';
	@override String get apply => 'اعمال';
	@override String get customSleep => 'زمان خواب شخصی';
	@override String get sleepMinutes => '۱ تا ۱۴۴۰ دقیقه';
	@override String sleepChapters({required Object count}) => 'دانلود بازی ${count}';
	@override String get extendSleep => 'اضافه کردن 5 دقیقه';
	@override String sleepRemaining({required Object time}) => 'زمان خواب: ${time}';
	@override String get useDefaults => 'از این کنترل های گوش دادن برای کتاب های جدید استفاده کنید';
	@override String get librarySort => 'انواع کتاب ها';
	@override String get sortTitle => 'عنوان';
	@override String get sortAuthor => 'نویسنده';
	@override String get sortNarrator => 'سخنران';
	@override String get sortSeries => 'سری سفارش';
	@override String get sortRecent => 'اخیرا باز شد';
	@override String get statusFilter => 'وضعیت خواندن';
	@override String get statusAll => 'همه کتاب ها';
	@override String get statusNew => 'شروع نمی شود';
	@override String get statusProgress => 'در پیشرفت';
	@override String get statusFinished => 'به پایان رسید';
	@override String get goToTime => 'به زمان برو';
	@override String get timeHelp => 'ساعت: دقیقه ها: ثانیه ها یا دقیقه ها: ثانیه ها';
	@override String get recoveryHelp => 'یک کپی رمزگذاری شده اخیر را قبل از حرکت یا اصلاح داده های همگام سازی صادر کنید. واردات با وضعیت فعلی ادغام می شود؛ آنها هرگز تاریخچه همگامه محلی را جایگزین نمی کنند.';
	@override String get recoveryExport => 'صادرات رمزگذاری شده بازگرداندن فایل';
	@override String get recoveryImport => 'واردات فایل های رمزگذاری شده';
	@override String get recoveryImportConfirm => 'آیا این فایل بازگرداندن رمزگذاری شده با موقعیت های خواندن فعلی و یادداشت ها ترکیب می شود؟ تاریخچه موجود حفظ خواهد شد. کتابخانه به اشتراک گذاشته شده و شناسه آیتم شامل نمی شود؛ قبل از واردات، شناسه های مطابقت را بر روی هر دستگاه تنظیم کنید.';
	@override String get recoveryExported => 'فایل بازگرداندن رمزگذاری شده ذخیره شده است.';
	@override String get recoveryImported => 'بازگرداندن اطلاعات جمع آوری شده است.';
}

// Path: sourceSetup
class _Translations$sourceSetup$fa extends Translations$sourceSetup$en {
	_Translations$sourceSetup$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get savedCertificate => 'گواهی ذخیره‌شدهٔ سرور';
	@override String get nfsEndpointInvalid => 'یک نشانی NFS مانند nfs://nas:2049/export وارد کنید.';
	@override String get dlnaNone => 'سرور DLNA پیدا نشد. نشانی توضیحات دستگاه را دستی وارد کنید.';
	@override String get dlnaServers => 'سرورهای رسانهٔ DLNA';
	@override String get dlnaUnavailable => 'کشف DLNA در این شبکه در دسترس نیست. نشانی توضیحات دستگاه را دستی وارد کنید.';
	@override String get dlnaSearching => 'در حال جست‌وجوی سرورهای DLNA در شبکهٔ محلی';
	@override String get networkSearching => 'در حال جست‌وجو در شبکهٔ محلی…';
	@override String get dlnaDiscover => 'یافتن سرورهای DLNA';
	@override String get dlnaHelp => 'کشف دستگاه به چندپخشی در شبکهٔ محلی وابسته است. اگر سروری ظاهر نشد، نشانی توضیحات دستگاه را در بالا وارد کنید.';
	@override String get dlnaRoot => 'شناسهٔ شیء DLNA؛ برای استفاده از ریشهٔ دستگاه، خالی بگذارید.';
	@override String get passwordOrKey => 'گذرواژه وارد کنید یا در پایین یک کلید خصوصی اضافه کنید.';
	@override String get sshFingerprint => 'اثر انگشت SHA256 کلید میزبان SSH';
	@override String get sshFingerprintHelp => 'با مدیر سرور تأیید کنید. روی سرور، دستور ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub را اجرا کنید و از مقدار SHA256 آن استفاده کنید.';
	@override String get sshFingerprintKeep => 'برای حفظ اثر انگشت تثبیت‌شدهٔ فعلی خالی بگذارید، یا اثر انگشت جدید سرور را وارد کنید.';
	@override String get sshAuthentication => 'احراز هویت با کلید عمومی SSH';
	@override String get sshAuthenticationHelp => 'اختیاری است؛ احراز هویت با گذرواژه نیز پشتیبانی می‌شود.';
	@override String get privateKey => 'کلید خصوصی (با قالب PEM یا OpenSSH)';
	@override String get privateKeyPassphrase => 'عبارت عبور کلید خصوصی';
	@override String get nfsMountPort => 'درگاه TCP سرویس mount NFS';
	@override String get nfsMountPortHelp => 'پیش‌فرض: 20048';
	@override String get nfsUserId => 'شناسهٔ کاربر NFS ‏(AUTH_SYS)';
	@override String get nfsUserIdHelp => 'پیش‌فرض: 1000. از شناسه‌ای استفاده کنید که در تنظیمات اشتراک NFS روی NAS مجاز است.';
	@override String get nfsGroupId => 'شناسهٔ گروه NFS ‏(AUTH_SYS)';
	@override String get nfsGroupIdHelp => 'پیش‌فرض: 1000. از شناسهٔ گروهی استفاده کنید که در تنظیمات اشتراک NFS روی NAS مجاز است.';
	@override String get nfsEncryption => 'الزام رمزگذاری NFS ‏(RPC-with-TLS)';
	@override String get nfsEncryptionHelp => 'TLS 1.3 را برای NFS و سرویس mount الزامی می‌کند. اگر NAS پشتیبانی نکند، اتصال رد می‌شود.';
	@override String get nfsTrustCertificate => 'گواهی سفارشی CA یا سرور NFS ‏(PEM، اختیاری)';
	@override String get nfsTrustHelp => 'برای گواهی‌های مورد اعتماد این دستگاه، خالی بگذارید. در صورت نیاز، گواهی CA خصوصی یا گواهی خودامضای سرور را اضافه کنید؛ نام‌های آن باید با میزبان نشانی NFS مطابقت داشته باشند.';
	@override String get nfsTrustInvalid => 'از گواهی CA یا سرور با قالب PEM استفاده کنید. کلید خصوصی را در آن قرار ندهید.';
	@override String get addTrustCertificate => 'افزودن گواهی اعتماد سفارشی';
	@override String get replaceTrustCertificate => 'جایگزینی گواهی سفارشی ذخیره‌شده';
	@override String get nfsTlsHelp => 'RPC-with-TLS از درگاه‌های معمول NFS و سرویس mount استفاده می‌کند و به پشتیبانی NAS از RFC 9289 نیاز دارد. TLS 1.3 الزامی است. نام میزبان یا IP باید با گواهی مطابقت داشته باشد. AUTH_SYS UID/GID در کانال رمزگذاری‌شده نیز اعمال می‌شوند.';
	@override String get clientCertificate => 'گواهی کارخواه (اختیاری)';
	@override String get clientCertificateHelp => 'به NAS اجازه می‌دهد هویت این کارخواه را تأیید کند؛ شناسه‌های AUTH_SYS همچنان تابع سیاست اشتراک‌گذاری NAS هستند.';
	@override String get savedIdentity => 'از هویت ذخیره‌شدهٔ کارخواه استفاده می‌شود.';
	@override String get replaceIdentity => 'جایگزینی هویت ذخیره‌شدهٔ کارخواه';
	@override String get chooseIdentity => 'انتخاب هویت کارخواه PKCS#12';
	@override String get identityPassphrase => 'عبارت عبور هویت کارخواه';
	@override String get identityPassphraseHelp => 'اگر فایل عبارت عبور ندارد، خالی بگذارید.';
	@override String get removeIdentity => 'حذف هویت ذخیره‌شدهٔ کارخواه';
	@override String get identityStorageHelp => 'هویت‌های کارخواه در مخزن رمزگذاری‌شدهٔ اطلاعات ورود منابع ذخیره می‌شوند. برای حفظ هویت ذخیره‌شده، این بخش را تغییر ندهید.';
	@override String get nfsLimitations => 'NFSv3 فقط‌خواندنی روی TCP. بدون RPC-with-TLS، ترافیک NFS رمزگذاری نمی‌شود. NAS باید شناسه‌های AUTH_SYS انتخاب‌شده و درگاه‌های بدون امتیاز ویژهٔ کارخواه را مجاز بداند (این گزینهٔ اشتراک‌گذاری معمولاً «insecure» نام دارد). NFSv4 و UDP پشتیبانی نمی‌شوند.';
	@override String get nfsSetupHelp => 'راهنمای تنظیم NFS';
	@override String get nfsSetupHint => 'اگر اتصال برقرار نمی‌شود، این تنظیمات را بررسی کنید.';
	@override String get nfsSetupDetails => 'از یک اشتراک NFSv3 روی TCP استفاده کنید. اگر رمزگذاری الزامی است، NFS و سرویس mount باید هر دو از RPC-with-TLS پشتیبانی کنند. برای گواهی سروری که این دستگاه به آن اعتماد دارد، گواهی سفارشی را خالی بگذارید؛ یا گواهی CA یا خودامضای NAS را اضافه کنید. نام گواهی باید با میزبان نشانی اتصال مطابقت داشته باشد. اگر NAS به TLS متقابل نیاز دارد، هویت کارخواه PKCS#12 آن را اضافه کنید. در پایان، تأیید کنید که تنظیمات اشتراک، AUTH_SYS UID/GID تعیین‌شده و سیاست درگاه‌های کارخواه را مجاز می‌داند.';
	@override String get ftpHelp => 'FTP از حالت پسیو (Passive) استفاده می‌کند. برای FTP بدون رمزگذاری از ftp://، برای فعال‌سازی TLS با فرمان جداگانه از ftpes:// و برای TLS از ftps:// استفاده کنید (روی درگاه 990، TLS بلافاصله آغاز می‌شود؛ روی سایر درگاه‌ها با فرمان جداگانه فعال می‌شود).';
	@override String get openSubtitles => 'OpenSubtitles';
	@override String get subtitleSetup => 'جست‌وجوی اختیاری زیرنویس برای فایل‌های ویدیویی مستقل.';
	@override String get apiKey => 'کلید API';
	@override String get optionalUsername => 'نام کاربری حساب (اختیاری)';
	@override String get optionalPassword => 'گذرواژهٔ حساب (اختیاری)';
	@override String get subtitlePrivacy => 'کلید API را از opensubtitles.com بگیرید. جست‌وجو، عنوان ویدیو و شناسه‌های موجود IMDb/TMDB را ارسال می‌کند، اما هرگز فایل ویدیو را نمی‌فرستد. کلید و اطلاعات ورود اختیاری حساب، همراه این منبع به‌صورت رمزگذاری‌شده ذخیره می‌شوند.';
	@override String get automaticMetadata => 'دریافت خودکار فرادادهٔ آنلاین ویدیو';
	@override String get metadataPrivacy => 'فقط عنوان، سال و شمارهٔ قسمت از نام فایل یا شناسهٔ NFO ارسال می‌شود؛ رسانه و اطلاعات ورود هرگز ارسال نمی‌شوند. فیلدهای NFO همیشه اولویت دارند.';
	@override String get nfsEncryptionFailure => 'برای NFS رمزگذاری‌شده، پشتیبانی هر دو سرویس NAS از RFC 9289 و TLS 1.3، نام گواهی و UID/GID اشتراک را بررسی کنید. PlezyNG این اتصال را بدون رمزگذاری دوباره امتحان نمی‌کند.';
	@override String get sourceConnecting => 'در حال اتصال به منبع';
	@override String get metadataSearchPrivacy => 'این جست‌وجوی عنوان به Trakt فرستاده می‌شود. فقط عنوانی که وارد می‌کنید ارسال می‌شود، نه ویدیو یا اطلاعات ورود منبع.';
	@override String get chooseMatch => 'انتخاب نتیجهٔ مطابق';
	@override String get metadataMatchHelp => 'پیش از انتخاب، عنوان و سال را بررسی کنید. Trakt عنوان جست‌وجو را دریافت می‌کند؛ ویدیو در منبع خود باقی می‌ماند.';
	@override String get metadataNoMatches => 'عنوان مطابقی در اینترنت پیدا نشد. عنوان دیگری را امتحان کنید.';
	@override String get metadataSearch => 'جست‌وجوی فرادادهٔ آنلاین';
	@override String get metadataLoading => 'در حال جست‌وجوی آنلاین اطلاعات فیلم و سریال…';
	@override String get metadataFromTrakt => 'فرادادهٔ آنلاین از Trakt';
	@override String get metadataNoAutomaticMatch => 'عنوان مطابقی به‌صورت خودکار پیدا نشد. عنوان را جست‌وجو کنید تا نتیجهٔ مطابق را انتخاب کنید.';
	@override String get metadataFailed => 'فرادادهٔ آنلاین بارگیری نشد. پخش و اطلاعات محلی همچنان در دسترس هستند.';
	@override String get videoDetailsLoading => 'در حال بارگیری اطلاعات ویدیو';
	@override String get subtitleKeyRequired => 'کلید API سرویس OpenSubtitles لازم است';
	@override String get subtitleKeyHelp => 'این منبع فایل را ویرایش کنید و در تنظیمات اختیاری زیرنویس، کلید API سرویس OpenSubtitles را اضافه کنید.';
	@override String get subtitleSearchFailed => 'جست‌وجوی زیرنویس ناموفق بود. کلید API، اتصال و دسترسی به سرویس را بررسی کنید.';
	@override String get subtitleApplyFailed => 'دریافت یا اعمال این زیرنویس ممکن نشد. اتصال را بررسی کنید و نتیجهٔ دیگری را امتحان کنید.';
	@override String get subtitleSearch => 'جست‌وجو در OpenSubtitles';
	@override String get subtitleSearchPrivacy => 'جست‌وجو از عنوان و شناسه‌های موجود IMDb/TMDB استفاده می‌کند. فایل ویدیو در منبع خود باقی می‌ماند. پیش از انتخاب، زبان، نشان زیرنویس اجباری یا ویژهٔ کم‌شنوایان و امتیاز را بررسی کنید.';
	@override String get movieOrShow => 'فیلم یا سریال';
	@override String get subtitleTitleHint => 'برای محدود کردن نتایج، عنوانی وارد کنید';
	@override String get subtitleLanguage => 'زبان زیرنویس';
	@override String get subtitleSearching => 'در حال جست‌وجو در OpenSubtitles';
	@override String get subtitleNoMatches => 'زیرنویس مطابقی پیدا نشد. عنوان یا زبان دیگری را امتحان کنید.';
	@override String get downloadSubtitle => 'دریافت زیرنویس';
	@override String get subtitle => 'زیرنویس';
	@override String get nfsTlsRequired => 'RPC-with-TLS الزامی است';
	@override String get nfsUnencrypted => 'NFS بدون رمزگذاری';
	@override String get tlsEncrypted => 'رمزگذاری‌شده با TLS';
	@override String get ftpPlain => 'FTP بدون رمزگذاری';
	@override String get sshPinned => 'رمزگذاری SSH · کلید میزبان تثبیت‌شده';
	@override String get smbEncrypted => 'رمزگذاری SMB3 روشن است';
	@override String get smbUnencrypted => 'رمزگذاری SMB3 خاموش است';
	@override String get httpUnencrypted => 'HTTP بدون رمزگذاری انتقال';
	@override String get checkEndpointSecurity => 'امنیت نشانی اتصال را بررسی کنید';
	@override String fieldRequired({required Object label}) => 'وارد کردن ${label} الزامی است.';
	@override String integerRange({required Object label, required Object min, required Object max}) => '${label} را بین ${min} و ${max} وارد کنید.';
	@override String replaceFile({required Object name}) => 'جایگزینی ${name}';
	@override String selectedIdentity({required Object name}) => 'هویت کارخواه انتخاب‌شده: ${name}';
	@override String subtitleRating({required Object rating}) => 'امتیاز ${rating}';
	@override String subtitleDownloading({required Object title}) => 'در حال دریافت زیرنویس: ${title}';
	@override String get sharedEntryPair => 'این آیتم را بپوشانید';
	@override String get sharedEntryPairHelp => 'همان ID برای این آیتم را در هر دستگاه وارد کنید.با استفاده از یک شناسه به اشتراک گذاری پایدار یا ایجاد یکی و کپی آن را به آیتم مطابقت.پیشرفت فقط زمانی که نسخه فایل انواع، اندازه ها و سفارش مطابقه است.';
	@override String get sharedEntryId => 'به اشتراک گذاری آیتم ID';
	@override String get generateSharedEntryId => 'به اشتراک گذاری آیتم ID';
	@override String get sharedLibraryId => 'ID کتابخانه به اشتراک گذاشته (اختیاری)';
	@override String get sharedLibraryHelp => 'استفاده از همان شناسه در دستگاه هایی که همان کتابخانه را باز می کنند.این شناسه عمومی کمک می کند تا پیشرفت خواندن و یادداشت ها را در سراسر اتصالات منبع مختلف انجام دهد؛ این یک رمز عبور نیست.هنگامی که ارائه دهندگان از شناسه های آیتم های مختلف استفاده می کنند، آن آیتم ها را از صفحه نمایش جزئیات خود جفت کنید.';
	@override String get sharedLibraryInvalid => 'از 8 تا 100 حروف، اعداد، نقطه ها، زیرنویس ها یا هیفن استفاده کنید.';
	@override String get generateSharedLibraryId => 'ایجاد یک ID کتابخانه مشترک';
	@override String get nfsReadAhead => 'درخواست های NFS Read-ahead';
	@override String get nfsReadAheadHelp => 'بیشتر خواندن موازی می تواند پهنای باند را در یک NAS یا شبکه سریع بهبود بخشد.استفاده از 1 اگر سرور تقاضای همزمان را محدود می کند.';
	@override String get nfsReadTest => 'اندازه گیری عملکرد NFS خواندن';
	@override String get nfsReadTestHelp => 'خواندن تا 64 مگابایت از بزرگترین فایل برای اندازه گیری این اتصال NAS.';
	@override String get nfsQualificationResult => 'NFS مطالعه اندازه گیری';
	@override String get nfsReadBytes => 'اطلاعات خواندن';
	@override String get nfsReadSpeed => 'سرعت اندازه گیری';
	@override String get nfsReadRequests => 'خواندن درخواست ها';
	@override String get sharedEntryConflict => 'این ID آیتم به اشتراک گذاشته شده در حال حاضر با یک آیتم دیگر در این کتابخانه ترکیب شده است.';
}

// Path: comics
class _Translations$comics$fa extends Translations$comics$en {
	_Translations$comics$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get fitHeight => 'اندازه بر اساس ارتفاع';
	@override String get readingMode => 'حالت مطالعه';
	@override String get paged => 'صفحه‌ها';
	@override String get webtoon => 'پیمایش پیوسته';
	@override String get coverAlone => 'نمایش جلد به‌تنهایی';
	@override String get splitWide => 'تقسیم صفحه‌های عریض';
	@override String get splitWideHelp => 'هر نیمه را جداگانه و به ترتیب مطالعه نشان می‌دهد. با فعال بودن این گزینه، نمایش دو صفحه کنار هم متوقف می‌شود.';
	@override String get thumbnails => 'تصاویر بندانگشتی صفحه‌ها';
	@override String get controlsHelp => 'برای ورق زدن بکشید. برای تغییر اندازهٔ نمایش دو بار ضربه بزنید. در پیمایش پیوسته، عمودی بکشید یا از Page Up و Page Down استفاده کنید.';
	@override String get savedForComic => 'تنظیمات نمایش این کمیک در این نمایه ذخیره می‌شود.';
	@override String get readLists => 'فهرست‌های مطالعه';
	@override String get collections => 'مجموعه‌ها';
}

// Path: games
class _Translations$games$fa extends Translations$games$en {
	_Translations$games$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Games';
	@override String get enable => 'Show Games for this profile';
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
	@override String get steamLibrary => 'Steam library';
	@override String get linkSteamAccount => 'Link Steam account';
	@override String get refreshSteamAccount => 'Refresh Steam account';
	@override String get unlinkSteamAccount => 'Unlink Steam account';
	@override String get unlinkSteamAccountConfirm => 'Remove this account and its imported catalog from this profile? Your paired computers and shortcuts stay available.';
	@override String get steamAccountLinked => 'Steam account linked. Games imported.';
	@override String get steamLibraryPrivate => 'Steam account linked. Its library is private or unavailable, so no games were imported.';
	@override String get steamLibraryStale => 'Steam could not refresh the library. Showing the last available catalog.';
	@override String get steamLibraryTruncated => 'Showing up to 2,000 games. The Steam catalog was truncated.';
	@override String get connecting => 'Connecting…';
	@override String get disconnect => 'Disconnect';
	@override String get streamControls => 'Stream controls';
	@override String get steamPairInstructions => 'Enter this code in Steam’s Remote Play pairing prompt on your computer. Keep this screen open until Steam approves.';
}

// Path: deepLinks
class _Translations$deepLinks$fa extends Translations$deepLinks$en {
	_Translations$deepLinks$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get invalid => 'این لینک Plezy معتبر نیست.';
	@override String profileNotFound({required Object profile}) => 'هیچ پروفایل با "${profile}" مطابقت ندارد.';
	@override String get serverUnavailable => 'من نمی توانستم به سرور برای این لینک دسترسی داشته باشم.';
	@override String get notFound => 'من نمی توانم این عنوان را در کتابخانه های شما پیدا کنم.';
	@override String get unsupportedItem => 'این لینک بازی نمی شود.';
	@override String get noLiveTv => 'هیچ سرور تلویزیونی زنده برای این لینک در دسترس نیست.';
	@override String channelNotFound({required Object channel}) => 'من نمی توانم کانال "${channel}" پیدا کنم.';
	@override String get showLink => 'نمایش لینک';
	@override String get showProfileLink => 'نمایش پروفایل لینک';
	@override String get dialogTitle => 'لینک';
	@override String get showHint => 'باز کردن این لینک قسمت بعدی را بازی می کند. اضافه کنید &mode=shuffle برای پخش نمایش در shuffle.';
	@override String get movieHint => 'باز کردن این لینک فیلم را بازی می کند.';
	@override String get episodeHint => 'باز کردن این لینک این قسمت را بازی می کند.';
	@override String get profileHint => 'باز کردن این لینک به این پروفایل تبدیل می شود.';
	@override String openAsProfile({required Object name}) => 'باز کردن به عنوان ${name}';
	@override String get copy => 'کپی';
	@override String get copied => 'لینک کپی شده';
}

// Path: householdSetup
class _Translations$householdSetup$fa extends Translations$householdSetup$en {
	_Translations$householdSetup$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'راه‌اندازی خانه';
}

// Path: issueReport
class _Translations$issueReport$fa extends Translations$issueReport$en {
	_Translations$issueReport$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'گزارش مشکل';
	@override String get instructions => 'برای باز کردن پیش‌نویس ازپیش‌پرشده GitHub، کد QR را اسکن کنید. آن را بررسی کنید و فقط وقتی آماده‌اید ارسال کنید.';
	@override String get privacy => 'پیش‌نویس نسخه برنامه، پلتفرم و تعداد اتصال‌ها را دارد. نشانی سرورها، نام حساب‌ها و پروفایل‌ها، عنوان رسانه‌ها و مسیر فایل‌ها در آن نیست.';
	@override String get logPrivacy => 'گزارش‌ها اختیاری‌اند. پیش از بارگذاری آن‌ها را بررسی کنید. شناسه گزارش به پیش‌نویس اضافه می‌شود و ممکن است عمومی باشد.';
	@override String get openDraft => 'باز کردن پیش‌نویس GitHub';
}

// Path: appIcon.names
class _Translations$appIcon$names$fa extends Translations$appIcon$names$en {
	_Translations$appIcon$names$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get midnight => 'نیمه شب';
	@override String get ember => 'مرد';
	@override String get paper => 'کاغذ';
	@override String get oled => 'OLED';
	@override String get line => 'خط';
	@override String get ocean => 'اقیانوس';
	@override String get ultraviolet => 'اولتراویول';
	@override String get matcha => 'مسابقه';
	@override String get sunset => 'خورشید';
	@override String get gold => 'طلا';
	@override String get titanium => 'تیتانیوم';
	@override String get glass => 'شیشه';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => 'Synthwave';
	@override String get pixel => 'پیکسل';
	@override String get neon => 'نئون';
	@override String get sticker => 'برچسب ها';
	@override String get ticket => 'بلیط';
	@override String get pop => 'پاپ';
	@override String get strata => 'خیابان';
	@override String get facet => 'چهره';
	@override String get tilde => 'تایلند';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$fa extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

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
class _Translations$common$mediaKind$fa extends Translations$common$mediaKind$en {
	_Translations$common$mediaKind$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get movie => 'فیلم';
	@override String get show => 'نمایش';
	@override String get season => 'فصل';
	@override String get episode => 'قسمت سریال';
	@override String get artist => 'هنرمند';
	@override String get album => 'آلبوم';
	@override String get track => 'قطعه';
	@override String get collection => 'مجموعه';
	@override String get playlist => 'لیست پخش';
	@override String get clip => 'فیلم کوتاه';
	@override String get photo => 'عکس';
	@override String get folder => 'پوشه';
}

// Path: settings.startupSectionOptions
class _Translations$settings$startupSectionOptions$fa extends Translations$settings$startupSectionOptions$en {
	_Translations$settings$startupSectionOptions$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get discover => 'توصیه ها و موارد را از منابع کشف مرتبط باز کنید.';
	@override String get libraries => 'کتابخانه های رسانه های متصل خود را باز کنید.';
	@override String get liveTv => 'تلویزیون زنده را هنگامی که یک سرور آن را ارائه می دهد باز کنید؛ در غیر این صورت استارتاپ به خانه باز می گردد.';
	@override String get search => 'جستجوی رسانه های باز';
}

// Path: themeEditor.slots
class _Translations$themeEditor$slots$fa extends Translations$themeEditor$slots$en {
	_Translations$themeEditor$slots$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get bg => 'پس زمینه';
	@override String get surface => 'سطح';
	@override String get outline => 'خط دور';
	@override String get text => 'متن';
	@override String get textMuted => 'متن ثانویه';
	@override String get accent => 'تمرکز';
}

// Path: themeEditor.contrast
class _Translations$themeEditor$contrast$fa extends Translations$themeEditor$contrast$en {
	_Translations$themeEditor$contrast$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => 'متن در پس زمینه';
	@override String get textOnSurface => 'متن در سطح';
	@override String get textMutedOnBg => 'متن دوم در پس زمینه';
	@override String get textMutedOnSurface => 'متن ثانویه در سطح';
	@override String get accentOnBg => 'تمرکز بر پس زمینه';
	@override String get accentOnSurface => 'تمرکز بر سطح';
	@override String get labelOnAccent => 'برچسب ها بر روی تمرکز';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$fa extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'بازی / استراحت';
	@override String get volumeUp => 'حجم بالا';
	@override String get volumeDown => 'حجم پایین';
	@override String seekForward({required Object seconds}) => 'جستجو به جلو (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'جستجو برای بازگشت (${seconds}s)';
	@override String get fullscreenToggle => 'با صفحه نمایش کامل';
	@override String get muteToggle => 'همبستگی موتی';
	@override String get subtitleToggle => 'با هم زیرنویس';
	@override String get audioTrackNext => 'بعدی Audio Track';
	@override String get subtitleTrackNext => 'بعدی زیرنویس زیرنویس';
	@override String get chapterNext => 'بخش بعد';
	@override String get chapterPrevious => 'بخش قبلی';
	@override String get episodeNext => 'قسمت بعد';
	@override String get episodePrevious => 'قسمت قبلی';
	@override String get speedIncrease => 'افزایش سرعت';
	@override String get speedDecrease => 'کاهش سرعت';
	@override String get speedReset => 'سرعت بازگشت';
	@override String get zoomIn => 'زوم در';
	@override String get zoomOut => 'زوم بیرون';
	@override String get zoomReset => 'بازسازی zoom';
	@override String get subSeekNext => 'جستجو برای زیرنویس بعدی';
	@override String get subSeekPrev => 'جستجو برای قبلی Subtitle';
	@override String get subtitleDelayIncrease => 'تاخیر زیرنویس';
	@override String get subtitleDelayDecrease => 'زیرنویس های پیشرفته';
	@override String get shaderToggle => 'سایه ها را جمع کنید';
	@override String get skipMarker => 'بایگانی برچسب ها: Intro/Credit';
	@override String get screenshot => 'عکس های صفحه نمایش';
	@override String get framePrevious => 'قبلی چارچوب';
	@override String get frameNext => 'بعدی چارچوب';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$fa extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'نیاز به Android 8.0 یا جدیدتر';
	@override String get iosVersion => 'نیاز به iOS 15.0 یا جدیدتر';
	@override String get permissionDisabled => 'Image-in-picture غیرفعال شده است.این را در تنظیمات سیستم فعال کنید.';
	@override String get notSupported => 'دستگاه پشتیبانی از حالت تصویر در تصویر ندارد';
	@override String get voSwitchFailed => 'عدم تغییر خروجی ویدئو برای تصویر در تصویر';
	@override String get failed => 'نقاشی در نقاشی شروع نمی شود';
	@override String get prepareFailed => 'نقاشی در نقاشی آماده نمی شود';
	@override String unknown({required Object error}) => 'خطای ناشی از: ${error}';
}

// Path: subtitlingStyling.assOverrideOptions
class _Translations$subtitlingStyling$assOverrideOptions$fa extends Translations$subtitlingStyling$assOverrideOptions$en {
	_Translations$subtitlingStyling$assOverrideOptions$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get no => 'حروف، رنگ ها، اندازه ها و قرار دادن نوشته شده را در فایل زیر عنوان نگه دارید.';
	@override String get yes => 'اجازه دهید تنظیمات سبک زیر عنوان بازیکن برای تنظیم زیر عنوان ASS.';
	@override String get scale => 'استفاده از سبک بازیکن و مقیاس اندازه های ساخته شده برای مطابقت با ابعاد ویدئو.';
	@override String get force => 'سبک های ASS را با سبک زیرنویس بازیکن جایگزین کنید.';
	@override String get strip => 'حذف فرمت ASS ساخته شده و متن زیرنویس را به وضوح انجام دهید.';
}

// Path: subtitlingStyling.renderResolutionOptions
class _Translations$subtitlingStyling$renderResolutionOptions$fa extends Translations$subtitlingStyling$renderResolutionOptions$en {
	_Translations$subtitlingStyling$renderResolutionOptions$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get screen => 'رندر در رزولوشن کامل صفحه نمایش برای سریع ترین نتیجه.';
	@override String get video => 'رندر با استفاده از رزولوشن ویدئویی به عنوان مرجع، که می تواند کار بر روی صفحه نمایش های رزولوژیکی بالا را کاهش دهد.';
	@override String get threeQuarter => 'رندر در 75٪ از رزولوشن سطح نمایش برای صرفه جویی در عملکرد خفیف.';
	@override String get half => 'رندر در 50٪ از رزولوشن سطح نمایش برای کاهش کار، با لبه های نرم تر.';
	@override String get third => 'رندر در یک سوم از رزولوشن سطح نمایش برای کاهش کار، با لبه های نرم تر.';
	@override String get quarter => 'رندر در یک چهارم از رزولوشن سطح صفحه نمایش برای کاهش کار، با نرم ترین نتیجه.';
}

// Path: accountPreferences.groups
class _Translations$accountPreferences$groups$fa extends Translations$accountPreferences$groups$en {
	_Translations$accountPreferences$groups$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => 'صدا و زیرنویس';
	@override String get libraryDisplay => 'کتابخانه';
	@override String get personalMedia => 'رسانه های شخصی';
}

// Path: accountPreferences.subtitleModes
class _Translations$accountPreferences$subtitleModes$fa extends Translations$accountPreferences$subtitleModes$en {
	_Translations$accountPreferences$subtitleModes$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get none => 'انتخاب دستی';
	@override String get noneDescription => 'هرگز زیرنویس ها را به خودی خود تغییر ندهید.';
	@override String get defaultMode => 'ردیابی پرچم های مسیر';
	@override String get defaultModeDescription => 'از پرچم های پیش فرض و اجباری ذخیره شده در هر ردیف زیر عنوان استفاده کنید.';
	@override String get always => 'همیشه امکان پذیر';
	@override String get alwaysDescription => 'هر زمان که یک زیرنویس در زبان مورد علاقه وجود داشته باشد بر روی یک زیرنویس حرکت کنید.';
	@override String get onlyForced => 'فقط زیرنویس های اجباری';
	@override String get onlyForcedDescription => 'فقط مسیرهای مشخص شده به عنوان اجباری را بارگذاری کنید.';
	@override String get smart => 'نمایش با صدا خارجی';
	@override String get smartDescription => 'زیرنویس ها را فقط هنگامی که صدا در زبان دیگری قرار دارد بر روی آن قرار دهید.';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class _Translations$accountPreferences$subtitleAccessibilityOptions$fa extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	_Translations$accountPreferences$subtitleAccessibilityOptions$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'ترجیح دادن زیرنویس های غیر SDH';
	@override String get preferSdh => 'ترجیح دادن زیرنویس های SDH';
	@override String get onlySdh => 'فقط زیرنویس های SDH';
	@override String get onlyNonSdh => 'فقط زیرنویس های غیر SDH';
	@override String get preferNonSdhDescription => 'ترجیح می دهم زیرنویس های استاندارد زمانی که هر دو نسخه استاندارد و SDH در دسترس هستند.';
	@override String get preferSdhDescription => 'ترجیح می دهم زیرنویس های SDH زمانی که در دسترس هستند، اما اجازه می دهد تا زیرنوی استاندارد به عنوان یک سقوط.';
	@override String get onlySdhDescription => 'فقط از زیرنویس های SDH استفاده کنید؛ به زیرنوی استاندارد برگردید.';
	@override String get onlyNonSdhDescription => 'فقط از زیرنویس های استاندارد استفاده کنید؛ زیرنوی SDH را حذف کنید.';
}

// Path: accountPreferences.forcedSubtitleOptions
class _Translations$accountPreferences$forcedSubtitleOptions$fa extends Translations$accountPreferences$forcedSubtitleOptions$en {
	_Translations$accountPreferences$forcedSubtitleOptions$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => 'ترجیح دادن زیرنویس های غیرقانونی';
	@override String get preferForced => 'ترجیح می دهم زیرنویس های اجباری';
	@override String get onlyForced => 'فقط زیرنویس های اجباری';
	@override String get onlyNonForced => 'فقط زیرنویس های غیر اجباری';
	@override String get preferNonForcedDescription => 'ترجیح می دهم زیرنویس های منظم، اما اجازه می دهد تا مسیرهای اجباری به عنوان یک سقوط.';
	@override String get preferForcedDescription => 'ترجیح می دهم مسیرهای اجباری زمانی که در دسترس است، اما اجازه می دهد تا زیرنویس های منظم به عنوان یک عقب نشینی.';
	@override String get onlyForcedDescription => 'استفاده فقط از مسیرهای مشخص شده به عنوان اجباری.';
	@override String get onlyNonForcedDescription => 'ردیاب ها به عنوان اجباری مشخص شده است.';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$fa extends Translations$accountPreferences$watchedIndicatorOptions$en {
	_Translations$accountPreferences$watchedIndicatorOptions$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get none => 'هرگز';
	@override String get moviesAndShows => 'فیلم ها و نمایش های تلویزیونی';
	@override String get movies => 'فقط فیلم ها';
	@override String get shows => 'نمایش های تلویزیونی فقط';
	@override String get noneDescription => 'چک های مشاهده شده را نشان ندهید.';
	@override String get moviesAndShowsDescription => 'نمایش چک های تماشا شده برای فیلم ها و برنامه های تلویزیونی.';
	@override String get moviesDescription => 'نشان دادن چک های مشاهده شده فقط برای فیلم ها.';
	@override String get showsDescription => 'نمایش شاخص های تماشا شده فقط برای برنامه های تلویزیونی.';
}

// Path: accountPreferences.mediaReviewsOptions
class _Translations$accountPreferences$mediaReviewsOptions$fa extends Translations$accountPreferences$mediaReviewsOptions$en {
	_Translations$accountPreferences$mediaReviewsOptions$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'کاربران و منتقدان';
	@override String get usersOnly => 'فقط کاربران';
	@override String get criticsOnly => 'انتقاد فقط';
	@override String get nobody => 'پنهان';
	@override String get usersAndCriticsDescription => 'نشان دادن هر دو رتبه بندی کاربران و رتبه های انتقادی.';
	@override String get usersOnlyDescription => 'رتبه بندی ها و نظرات ارائه شده توسط کاربران را نشان دهید.';
	@override String get criticsOnlyDescription => 'بررسی ها و ارزیابی های انتقادی را نشان دهید.';
	@override String get nobodyDescription => 'پنهان کردن امتیازات و بررسی ها.';
}

// Path: discover.findNext
class _Translations$discover$findNext$fa extends Translations$discover$findNext$en {
	_Translations$discover$findNext$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'انتخاب بعدی‌تان را پیدا کنید';
	@override String get open => 'انتخاب بعدی‌تان را پیدا کنید';
	@override String get anyTime => 'بدون محدودیت زمانی';
	@override String get timeAvailable => 'چقدر وقت دارید؟';
	@override String get filters => 'برای این لحظه انتخاب کنید';
	@override String get watch => 'تماشا';
	@override String get listen => 'گوش دادن';
	@override String get read => 'خواندن';
	@override String finishable({required Object duration}) => 'قابل اتمام در ${duration}';
	@override String aboutDuration({required Object duration}) => 'حدود ${duration}';
	@override String nextUnit({required Object duration}) => 'فصل بعدی · ${duration}';
	@override String totalDuration({required Object duration}) => 'در مجموع ${duration}';
	@override String get timingVaries => 'مدت‌زمان متفاوت است';
	@override String get notNow => 'الان نه';
	@override String get swipeHint => 'جلد را به سمت یکی از پیکان‌ها بکشید یا از دکمه‌های زیر استفاده کنید.';
	@override String get saved => 'پیشنهادهای ذخیره‌شده';
	@override String savedCount({required Object count}) => 'پیشنهادهای ذخیره‌شده · ${count}';
	@override String get undo => 'واگرد';
	@override String get details => 'جزئیات';
	@override String get noPicks => 'هنوز چیزی برای انتخاب وجود ندارد';
	@override String get noPicksHint => 'برای شروع، یک کتابخانه متصل کنید یا یک منبع رسانه اضافه کنید.';
	@override String get noMatches => 'چیزی مناسب این لحظه پیدا نشد';
	@override String get noMatchesHint => 'نوع دیگری از رسانه را امتحان کنید یا زمان بیشتری در نظر بگیرید.';
	@override String get allDone => 'همهٔ پیشنهادها را دیدید';
	@override String get allDoneHint => 'برای دیدن دوبارهٔ این گزینه‌ها، مجموعهٔ تازه‌ای از پیشنهادها را شروع کنید.';
	@override String get refresh => 'پیشنهادهای دیگری پیدا کنید';
	@override String sourceReason({required Object source}) => 'از ${source}';
	@override String libraryReason({required Object library}) => 'از ${library}';
	@override String get ownedReason => 'از کتابخانهٔ شما';
	@override String get liveNow => 'در حال پخش';
	@override String get watchLive => 'تماشای زنده';
	@override String get filterAnything => 'هر نوعی';
	@override String get filterWatch => 'تماشا';
	@override String get filterListen => 'گوش دادن';
	@override String get filterRead => 'خواندن';
	@override String get twentyMinutes => '۲۰ دقیقه';
	@override String get fortyFiveMinutes => '۴۵ دقیقه';
	@override String get ninetyMinutes => '۹۰ دقیقه';
	@override String get apply => 'اعمال';
	@override String get openFailed => 'این گزینه دیگر در دسترس نیست. برای بررسی دوباره، تازه‌سازی کنید.';
	@override String get changeFailed => 'این تغییر ذخیره نشد. دوباره تلاش کنید.';
	@override String get savedLimit => 'فهرست پیشنهادهای ذخیره‌شده پر است. برای ذخیرهٔ پیشنهادی دیگر، یکی را حذف کنید.';
	@override String get chooseHint => 'عنوانی را باز کنید، برای بعد ذخیره کنید یا از آن بگذرید.';
	@override String get howItWorks => 'روش استفاده';
	@override String get notNowHelp => 'فعلاً از این عنوان بگذرید. در کتابخانه شما باقی می‌ماند.';
	@override String get saveHelp => 'آن را در انتخاب‌های ذخیره‌شده این نمایه روی این دستگاه نگه دارید. ذخیره کردن باعث دانلود نمی‌شود.';
	@override String get openHelp => 'برای دیدن جزئیات، جلد را انتخاب کنید. از دکمه اصلی برای پخش، خواندن یا باز کردن عنوان استفاده کنید.';
	@override String get controlsHelp => 'صفحه‌کلید یا کنترل: روی یک دکمه بروید و Enter یا دکمه انتخاب را بزنید. واگرد آخرین انتخاب شما را برمی‌گرداند.';
	@override String get artworkLoading => 'در حال بارگیری تصویر…';
	@override String get artworkUnavailable => 'تصویر در دسترس نیست';
	@override String get savedFeedback => 'به انتخاب‌های ذخیره‌شده افزوده شد';
	@override String get skippedFeedback => 'فعلاً رد شد';
	@override String get releaseToConfirm => 'برای تأیید رها کنید';
	@override String get remoteHint => 'با تمرکز روی جلد: ← / → انتخاب · دکمه انتخاب: جزئیات · ↑ / ↓ جابه‌جایی تمرکز';
}

// Path: discover.person
class _Translations$discover$person$fa extends Translations$discover$person$en {
	_Translations$discover$person$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get born => 'متولد شد';
	@override String get died => 'مرده';
	@override String get birthplace => 'محل تولد';
	@override String dateWithAge({required Object date, required Object age}) => '${date} (سن ${age})';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (سال ${age})';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$fa extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'توصیه شده';
	@override String get browse => 'مرور کردن';
	@override String get collections => 'مجموعه‌ها';
	@override String get playlists => 'لیست‌های پخش';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$fa extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'گروه بندی';
	@override String get all => 'همه';
	@override String get movies => 'فیلم ها';
	@override String get shows => 'تلویزیون نمایش';
	@override String get seasons => 'فصل ها';
	@override String get episodes => 'قسمت‌ها';
	@override String get artists => 'هنرمندان';
	@override String get albums => 'آلبوم‌ها';
	@override String get tracks => 'شیار';
	@override String get folders => 'پوشه‌ها';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$fa extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get genre => 'ژانر';
	@override String get year => 'سال';
	@override String get contentRating => 'محتوای رتبه بندی';
	@override String get tag => 'برچسب';
	@override String get unwatched => 'ناشناخته';
	@override String get unplayed => 'پخش نشده';
	@override String get favorites => 'مورد علاقه‌ها';
	@override String get filePath => 'فایل مسیر';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$fa extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'عنوان';
	@override String get dateAdded => 'تاریخ اضافه شده';
	@override String get releaseDate => 'تاریخ انتشار';
	@override String get rating => 'رتبه بندی';
	@override String get communityRating => 'امتیاز عمومی';
	@override String get criticRating => 'رتبه بندی انتقادی';
	@override String get userRating => 'رتبه بندی کاربر';
	@override String get datePlayed => 'تاریخ پخش شده';
	@override String get playCount => 'تعداد پخش';
	@override String get productionYear => 'سال تولید';
	@override String get runtime => 'زمان اجرا';
	@override String get officialRating => 'رتبه بندی رسمی';
	@override String get premiereDate => 'تاریخ پخش';
	@override String get startDate => 'تاریخ شروع';
	@override String get airTime => 'زمان پخش';
	@override String get studio => 'استودیو';
	@override String get random => 'تصادفی';
	@override String get dateShared => 'تاریخ به اشتراک گذاری';
	@override String get latestEpisodeAirDate => 'آخرین قسمت تاریخ هوا';
	@override String get lastEpisodeDateAdded => 'آخرین قسمت تاریخ اضافه شده';
	@override String get dateDownloaded => 'تاریخ دانلود';
	@override String get size => 'سایز';
	@override String get library => 'کتابخانه';
}

// Path: libraries.advancedFilters
class _Translations$libraries$advancedFilters$fa extends Translations$libraries$advancedFilters$en {
	_Translations$libraries$advancedFilters$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get include => 'شامل';
	@override String get exclude => 'حذف';
	@override String get any => 'هر چیزی';
	@override String get yes => 'بلی';
	@override String get no => 'خیر';
	@override String not({required Object value}) => '${value}';
	@override String valueCount({required Object count}) => '${count} انتخاب شده';
	@override String valueCountExcluded({required Object count}) => '${count} حذف شده';
	@override String get searchValues => 'ارزش های جستجو';
	@override String get noValues => 'هیچ ارزش';
	@override String get matchContains => 'حاوی';
	@override String get matchNotContains => 'شامل نمی شود';
	@override String get matchIs => 'این است';
	@override String get matchIsNot => 'نه است';
	@override String get matchBeginsWith => 'با شروع با';
	@override String get matchEndsWith => 'پایان با';
	@override String get textHint => 'نوع برای مسابقه';
	@override String get from => 'از';
	@override String get to => 'برای';
	@override String range({required Object from, required Object to}) => '${from} تا ${to}';
	@override String atLeast({required Object value}) => '${value} و بالا';
	@override String atMost({required Object value}) => 'تا ${value}';
	@override String dateLastDays({required Object count}) => '${count} روز گذشته';
	@override String get dateLastYear => 'سال گذشته';
	@override String dateOlderThanDays({required Object count}) => 'سن و سال ${count} روز';
	@override String get dateOlderThanYear => 'بزرگتر از یک سال';
}

// Path: libraries.selection
class _Translations$libraries$selection$fa extends Translations$libraries$selection$en {
	_Translations$libraries$selection$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get selectItems => 'انتخاب آیتم ها';
	@override String selectedCount({required Object count}) => '${count} انتخاب شده';
	@override String get actions => 'فعالیت های انتخابی';
	@override String get confirmDescendants => 'این تغییرات تمام قسمت ها را در نمایش ها و فصل های انتخاب شده تغییر می دهد.';
	@override String get confirmUnwatched => 'این کار پیشرفت پخش موارد انتخاب‌شده را نیز پاک می‌کند.';
	@override String confirmCount({required Object count}) => 'تعداد بازدید : ${count}';
	@override String completed({required Object count}) => 'بایگانی برچسب ها: ${count}';
	@override String partialFailure({required Object succeeded, required Object failed}) => 'به روز شده ${succeeded}؛ شکست خورده ${failed}.نمونه های شکست خورده باقی می ماند.';
}

// Path: explore.mdblistShelves
class _Translations$explore$mdblistShelves$fa extends Translations$explore$mdblistShelves$en {
	_Translations$explore$mdblistShelves$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get manage => 'راهنمای جستجو برای کشتی ها';
	@override String get manageDescription => 'انتخاب و ترتیب لیست ها از حساب MDBList خود را';
	@override String get description => 'لیست های فیلم و تلویزیون عمومی را از حساب MDBList خود انتخاب کنید و سپس لیست ها را در MDBList ایجاد یا کپی کنید.';
	@override String get selected => 'شلوار انتخاب شده';
	@override String get available => 'لیست حساب های موجود';
	@override String get noLists => 'هیچ فیلم عمومی یا لیست های تلویزیونی بازگردانده نشده است. ایجاد یا کپی یک لیست در MDBList، سپس آن را بازسازی کنید.';
	@override String get displayName => 'نام نمایش Shelf';
	@override String get nameHint => 'اجازه دهید نام لیست منبع را خالی کنید.';
	@override String get add => 'اضافه کردن شیل';
	@override String get save => 'ذخیره شلوارها';
	@override String moveUp({required Object title}) => 'حرکت ${title} بالا';
	@override String moveDown({required Object title}) => 'حرکت ${title} به پایین';
	@override String get unavailable => 'این لیست در دسترس نیست.در تنظیمات، اسلاید خود را بازگردانید یا حذف کنید.';
	@override String get rateLimited => 'MDBList درخواست محدود به دست آمده است لطفا بعدا عقب نشینی کنید.';
	@override String get loadFailed => 'نمی توانم شلوارها را بارگذاری کنم، اتصال خود را بررسی کنید و عقب نشینی کنید.';
	@override String get saveFailed => 'من نمی توانم از دستمزدها استفاده کنم لطفا از دستمزدها استفاده کنید.';
	@override String get accountChanged => 'حساب یا پروفایل تغییر کرده است.این تنظیمات را دوباره باز کنید.';
	@override String get settingsUnreadable => 'صفحه های ذخیره شده را نمی توان خوانده شد. لیست های خود را دوباره انتخاب کنید تا این تنظیمات را جایگزین کنید.';
}

// Path: explore.rows
class _Translations$explore$rows$fa extends Translations$explore$rows$en {
	_Translations$explore$rows$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'لیست نظارت';
	@override String get recommendedMovies => 'فیلم های توصیه شده';
	@override String get recommendedShows => 'نمایش های توصیه شده';
	@override String get trendingMovies => 'فیلم های روندی';
	@override String get trendingShows => 'نمایش های روندی';
	@override String get popularMovies => 'فیلم های محبوب';
	@override String get popularShows => 'نمایش های محبوب';
	@override String get trendingAnime => 'انیمه روند';
	@override String get suggestedAnime => 'پیشنهاد انیمه';
	@override String get airingAnime => 'دانلود انیمیشن Airing Anime';
	@override String get popularAnime => 'محبوب ترین انیمه ها';
	@override String get trending => 'روند';
	@override String get upcomingMovies => 'فیلم های آینده';
	@override String get upcomingShows => 'نمایش های آینده';
}

// Path: explore.status
class _Translations$explore$status$fa extends Translations$explore$status$en {
	_Translations$explore$status$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get airing => 'هواشناسی';
	@override String get ended => 'تمام شده';
	@override String get canceled => 'لغو';
	@override String get upcoming => 'بزودی';
}

// Path: explore.badge
class _Translations$explore$badge$fa extends Translations$explore$badge$en {
	_Translations$explore$badge$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} محبوب';
	@override String rankAiring({required Object n}) => '#${n} هواشناسی';
	@override String rankRated({required Object n}) => '#${n} رتبه بندی';
	@override String rankTrending({required Object n}) => '#${n} روند';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} در ${season}';
	@override String watchingNow({required Object n}) => '${n} بازدید';
	@override String get available => 'در دسترس';
	@override String get partiallyAvailable => 'در دسترس جزئی';
	@override String get availableIn4k => '4K در دسترس';
	@override String get requested => 'درخواست شده';
	@override String get pendingApproval => 'مدت زمان تایید';
	@override String get processing => 'پردازش';
	@override String get declined => 'تخریب';
	@override String get requestFailed => 'درخواست شکست خورده';
	@override String get requested4k => '4K درخواست شده';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available} / ${total} فصل';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => '${episode} در ${duration}';
	@override String nextAiringIn({required Object duration}) => 'بعدی در ${duration}';
	@override String episodesShort({required Object n}) => '${n} EPS';
	@override String minutesPerEpisode({required Object n}) => '${n} دقیقه/بخش';
	@override String get adult => '18+';
}

// Path: explore.stats
class _Translations$explore$stats$fa extends Translations$explore$stats$en {
	_Translations$explore$stats$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} ثبت شده';
	@override String viewersDay({required Object n}) => '${n} بازدید امروز';
	@override String viewersWeek({required Object n}) => 'این هفته ${n} نفر تماشا کردند';
	@override String viewersMonth({required Object n}) => 'این ماه ${n} نفر تماشا کردند';
	@override String viewersYear({required Object n}) => '${n} بازدید در این سال';
	@override String viewersAllTime({required Object n}) => '${n} بیننده';
	@override String planning({required Object n}) => '${n} برنامه ریزی برای مشاهده';
	@override String favorited({required Object n}) => '${n} مورد علاقه';
	@override String dropRate({required Object percent}) => '${percent} آن را از دست داد';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} دیدگاه ها',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} دیدگاه ها',
	);
	@override String votes({required Object n}) => '${n} رای';
	@override String watching({required Object n}) => '${n} بازدید';
	@override String completed({required Object n}) => '${n} تکمیل شده';
	@override String onHold({required Object n}) => '${n} در دسترس';
	@override String dropped({required Object n}) => '${n} از دست رفته';
}

// Path: explore.season
class _Translations$explore$season$fa extends Translations$explore$season$en {
	_Translations$explore$season$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get winter => 'زمستان';
	@override String get spring => 'بهار';
	@override String get summer => 'تابستان';
	@override String get fall => 'سقوط';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class _Translations$explore$format$fa extends Translations$explore$format$en {
	_Translations$explore$format$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get tv => 'تلویزیون';
	@override String get tvShort => 'تلویزیون کوتاه';
	@override String get movie => 'فیلم';
	@override String get special => 'ویژه';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => 'موسیقی‌ها';
	@override String get other => 'دیگر';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$fa extends Translations$explore$sourceMaterial$en {
	_Translations$explore$sourceMaterial$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get original => 'اصلی';
	@override String get manga => 'مانگا';
	@override String get lightNovel => 'نور رمان';
	@override String get novel => 'رمان';
	@override String get visualNovel => 'رمان بصری';
	@override String get game => 'بازی';
	@override String get webComic => 'وبسایت کمدی';
	@override String get musicRelease => 'موسیقی‌ها';
	@override String get otherMedia => 'دیگر';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$fa extends Translations$explore$creditRole$en {
	_Translations$explore$creditRole$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get actor => 'بازیگر';
	@override String get director => 'کارگردان';
	@override String get writer => 'نویسنده';
	@override String get producer => 'تولید کننده';
	@override String get creator => 'خالق';
	@override String get composer => 'آهنگساز';
}

// Path: explore.relation
class _Translations$explore$relation$fa extends Translations$explore$relation$en {
	_Translations$explore$relation$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get prequel => 'پیشگویی';
	@override String get sequel => 'بعدی';
	@override String get sideStory => 'داستان جانبی';
	@override String get spinOff => 'اسپین آف';
	@override String get alternativeVersion => 'نسخه ی جایگزین';
	@override String get summary => 'خلاصه ای';
	@override String get parentStory => 'داستان پدر';
	@override String get adaptation => 'انطباق';
	@override String get other => 'مرتبط';
}

// Path: explore.detail
class _Translations$explore$detail$fa extends Translations$explore$detail$en {
	_Translations$explore$detail$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'عنوان اصلی';
	@override String get alsoKnownAs => 'همچنین شناخته شده به عنوان';
	@override String get studios => 'استودیو‌ها';
	@override String get country => 'کشور';
	@override String get language => 'زبان';
	@override String get released => 'آزاد شد';
	@override String get physicalRelease => 'در دیسک';
	@override String get ended => 'تمام شده';
	@override String addedOn({required Object date}) => 'اضافه شده ${date}';
	@override String get yourRating => 'رتبه بندی شما';
	@override String get budget => 'بودجه';
	@override String get revenue => 'جعبه دفتر';
	@override String get contentAdvisory => 'راهنمای سن';
	@override String get tags => 'برچسب‌ها';
	@override String get revealSpoilerTags => 'برچسب های Spoiler';
	@override String get links => 'چپ ها';
	@override String get watchOn => 'نگاهی به';
	@override String get watchTrailer => 'تماشای تریلر';
	@override String openOn({required Object site}) => 'باز شده در ${site}';
	@override String get crew => 'خدمه';
	@override String get ratings => 'رتبه بندی';
	@override String get schedule => 'برنامه زمانی';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n,
		one: 'توصیه شده توسط ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} کاربر',
		other: 'توصیه شده توسط ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} کاربران',
	);
	@override String recommendedBy({required Object who}) => 'توصیه شده توسط ${who}';
	@override String favoritedBy({required Object who}) => 'محبوب شده توسط ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} هنوز ارسال نشده';
	@override String recommendedByPercent({required Object percent}) => 'توصیه شده توسط ${percent} بازدید کنندگان';
	@override String get relatedTitles => 'عنوان های مرتبط';
	@override String get background => 'پس زمینه';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$fa extends Translations$liveTv$recordSettings$en {
	_Translations$liveTv$recordSettings$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get startEarly => 'شروع زود (دوره های اول)';
	@override String get endLate => 'تاخیر در پایان (دقیقه ها)';
	@override String get newOnly => 'فقط قسمت های جدید';
	@override String get anyChannel => 'ثبت نام در هر کانال';
	@override String get anyTime => 'ثبت نام در هر زمان';
	@override String get skipInLibrary => 'قسمت ها را در حال حاضر در کتابخانه';
	@override String get keepUpTo => 'حوادثی که باید حفظ شود';
	@override String get keepUpToHint => '0 در هر قسمت';
}

// Path: music.discography
class _Translations$music$discography$fa extends Translations$music$discography$en {
	_Translations$music$discography$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'تک آهنگ ها و EPs';
	@override String get live => 'پخش زنده';
	@override String get compilations => 'جمع آوری';
}

// Path: watchTogether.notices
class _Translations$watchTogether$notices$fa extends Translations$watchTogether$notices$en {
	_Translations$watchTogether$notices$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name} بازی فشار داده شده';
	@override String get playbackStarted => 'Playback آغاز شد';
	@override String paused({required Object name}) => '${name} استراحت';
	@override String get playbackPaused => 'بازی با استراحت';
	@override String jumpedTo({required Object name, required Object position}) => '${name} پرش به ${position}';
	@override String roomJumpedTo({required Object position}) => 'به شماره ${position} رسید.';
	@override String changedSpeed({required Object name, required Object speed}) => '${name} سرعت را به ${speed} تنظیم کنید';
	@override String speedChanged({required Object speed}) => 'سرعت تنظیم شده به ${speed}';
	@override String startedMedia({required Object name, required Object title}) => '${name} شروع ${title}';
	@override String mediaStarted({required Object title}) => 'در حال حاضر بازی ${title}';
	@override String stoppedMedia({required Object name}) => '${name} این ویدئو را متوقف کرد';
	@override String get mediaStopped => 'ویدئو متوقف شد';
	@override String waitingFor({required Object name}) => 'در انتظار ${name} ...';
	@override String get waitingForSomeone => 'منتظر کسی هستم که آن را بگیرد...';
	@override String get finished => 'پایان یافت';
	@override String hostChangedTo({required Object name}) => '${name} در حال حاضر میزبان';
	@override String get youAreNowHost => 'شما میزبان هستید';
	@override String joined({required Object name}) => '${name} پیوست';
	@override String left({required Object name}) => '${name} بازه';
	@override String get controlRefused => 'تنها میزبان می تواند بازی را کنترل کند.';
	@override String get searchFailed => 'برخی از سرورها نمی توانستند برای ویدئو اتاق جستجو کنند.';
	@override String get playBlocked => 'بازی مطبوعاتی برای شروع';
	@override String get shareFailed => 'نمی توانم این ویدئو را با اتاق به اشتراک بگذارم';
	@override String get downloadNotShared => 'دانلود ها با اتاق به اشتراک نمی گذارند در حالی که سرور آنها آفلاین است';
	@override String get openFailed => 'نمی توانم ویدئوی اتاق را باز کنم';
}

// Path: watchTogether.ended
class _Translations$watchTogether$ended$fa extends Translations$watchTogether$ended$en {
	_Translations$watchTogether$ended$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get ended => 'میزبان اتاق را به پایان رساند';
	@override String get kicked => 'شما از اتاق خارج شده اید.';
	@override String get expired => 'اتاق تمام شد';
	@override String get replaced => 'شما این اتاق را در دستگاه دیگری قرار داده اید.';
	@override String get lost => 'از دست دادن اتصال به اتاق';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$fa extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => 'کدها دارای 6 حرف و اعداد هستند، بدون 0، 1، I، L یا O.';
	@override String get roomNotFound => 'هیچ کدام از این اتاق ها این کد را ندارند، ممکن است به پایان برسد.';
	@override String get roomFull => 'این اتاق پر است.';
	@override String get roomLocked => 'میزبان این اتاق را بسته بود.';
	@override String get relayFull => 'در حال حاضر شلوغ است.بعدی دوباره امتحان کنید.';
	@override String get unreachable => 'نمی توانم به ساعت با هم رله برسم.نگاه کنید به اتصال خود را.';
	@override String get rateLimited => 'خیلی تلاش کنید، یک لحظه صبر کنید و دوباره امتحان کنید.';
	@override String get clientBlocked => 'این نسخه از PlezyNG نمی تواند از رله استفاده کند.';
	@override String get forbidden => 'تنها میزبان می تواند این کار را انجام دهد.';
	@override String get notInRoom => 'شما در یک اتاق نیستید.';
	@override String get alreadyInRoom => 'شما در حال حاضر در یک اتاق هستید.';
	@override String get resumeFailed => 'نمی توانستم به اتاق بروم.';
	@override String get unsupported => 'رله ها از این موضوع حمایت نمی کنند.';
	@override String get generic => 'چیزی اشتباه کرد، دوباره امتحان کنید.';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$fa extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'دانلود ها وقتی برنامه را ترک می کنید متوقف می شوند';
	@override String get bannerDegraded => 'دانلود های پس زمینه ممکن است محدود باشد';
	@override String get bannerAction => 'جزئیات';
	@override String get sheetTitle => 'دانلود های پس زمینه مسدود شده اند';
	@override String get sheetTitleDegraded => 'دانلود های پس زمینه ممکن است محدود باشد';
	@override String get sheetIntro => 'Android جلوگیری می کند PlezyNG از دانلود قابل اعتماد در پس زمینه.';
	@override String get sheetIntroDegraded => 'دستگاه شما محدود می کند زمانی که PlezyNG می تواند در پس زمینه دانلود شود.';
	@override String get reasonBackgroundRestricted => 'استفاده از پس زمینه PlezyNG محدود است و استفاده از باتری یا پس زمینه آن را به "غیر محدود" تنظیم کنید.';
	@override String get reasonStandbyRestricted => 'Android PlezyNG را در حالت ایستادگی محدود قرار داده است. استفاده از باتری را به "غیر محدود" تنظیم کنید.';
	@override String get reasonDownloadChannelBlocked => 'اطلاعیه های دانلود غیرفعال می شوند، بنابراین پیشرفت و کنترل ها ممکن است در دسترس نباشد.';
	@override String get reasonNotificationsDisabled => 'در Android 13 یا جدیدتر، آنها برای دانلود های پس زمینه طولانی مورد نیاز است.';
	@override String get reasonDataSaver => 'Data Saver در حال اجرا است، که بلاک دانلود های پس زمینه در داده های تلفن همراه است. دانلود ها باید هنوز هم در Wi-Fi اجرا می شود.';
	@override String get reasonOemUnknown => 'وقتی PlezyNG در پس‌زمینه بود، دانلودها چند بار متوقف شدند. تنظیمات باتری یا فعالیت پس‌زمینهٔ PlezyNG را بررسی کنید.';
	@override String get openSettings => 'تنظیمات باز';
	@override String get stillNotWorking => 'کمک های خاص دستگاه';
	@override String get stillNotWorkingDescription => 'مشاهده مراحل برای دستگاه شما، یا ارسال یک سوابق از تنظیمات › مشاهده سوابق اگر مشکل ادامه دارد.';
	@override String get dialogTitle => 'دانلود ها ممکن است به پایان نرسند';
	@override String get dialogDownloadAnyway => 'دانلود به هر حال';
	@override String get dialogFixFirst => 'اول این را اصلاح کنید';
	@override String get statusTile => 'دانلود پس زمینه';
	@override String get statusOk => 'اجازه اجرا در پس زمینه';
	@override String get statusBlocked => 'مسدود شده توسط تنظیمات سیستم';
	@override String get statusDegraded => 'محدود به تنظیمات سیستم';
	@override String get statusUnknown => 'هنوز بررسی نشده';
	@override String get settingsUnavailable => 'امکان باز کردن تنظیمات سیستم در این دستگاه وجود ندارد.';
	@override String get linkUnavailable => 'نمی توانم dontkillmyapp.com را در این دستگاه باز کنم';
}

// Path: downloads.groupings
class _Translations$downloads$groupings$fa extends Translations$downloads$groupings$en {
	_Translations$downloads$groupings$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get library => 'کتابخانه';
	@override String get collections => 'مجموعه‌ها';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$fa extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'راه اندازی سرورهای از راه دور';
	@override String get hostAddress => 'آدرس میزبان';
	@override String get connected => 'اتصال';
	@override String get serverRunning => 'سرورهای از راه دور فعال';
	@override String get serverStopped => 'سرور از راه دور متوقف شد';
	@override String get serverRunningDescription => 'دستگاه های تلفن همراه در شبکه شما می توانند به این برنامه متصل شوند';
	@override String get serverStoppedDescription => 'سرور را راه اندازی کنید تا دستگاه های تلفن همراه بتوانند به';
	@override String get usePhoneToControl => 'از دستگاه موبایل خود برای کنترل این برنامه استفاده کنید.';
	@override String get startServer => 'شروع سرور';
	@override String get stopServer => 'توقف سرور';
	@override String get minimize => 'حداقل';
	@override String get manualAddressHint => 'آدرس اتصال دستی :';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$fa extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'دستگاه های PlezyNG با همان حساب Plex در اینجا ظاهر می شوند';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'اتصال...';
	@override String get searchingForDevices => 'در جستجوی تجهیزات...';
	@override String get noDevicesFound => 'هیچ دستگاهی در شبکه شما یافت نشد';
	@override String get noDevicesHint => 'PlezyNG را در دسکتاپ باز کنید و از همان Wi-Fi استفاده کنید.';
	@override String get availableDevices => 'تجهیزات موجود';
	@override String get manualConnection => 'اتصال دستی';
	@override String get cryptoInitFailed => 'امکان اتصال امن را شروع نکنید.اول با شماره Plex ثبت نام کنید.';
	@override String get validationHostRequired => 'لطفا آدرس میزبان را وارد کنید';
	@override String get validationHostFormat => 'فرمت باید IP:port باشد (به عنوان مثال 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'استفاده از شبکه در هر دو دستگاه';
	@override String get sessionNotFound => 'دستگاه یافت نشد اطمینان حاصل کنید که PlezyNG در میزبان اجرا می شود.';
	@override String get authFailed => 'هر دو دستگاه به همان حساب Plex نیاز دارند.';
	@override String failedToConnect({required Object error}) => 'عدم اتصال: ${error}';
	@override String get codeTitle => 'کد زوجی';
	@override String get codeDescription => 'کد نمایش داده شده در Companion Remote را در دستگاه میزبان وارد کنید.هر دو دستگاه باید از نسخه ای استفاده کنند که از یک جفت امن پشتیبانی می کند.';
	@override String get codeInvalid => 'تمام 32 حرف و اعداد را از کد میزبان وارد کنید.';
	@override String get updateRequired => 'به روز رسانی هر دو دستگاه به نسخه ای که از پیوند امن پشتیبانی می کند.';
	@override String get hostDescription => 'این کد را یک بار در هر ردیف وارد کنید.این کد را خصوصی نگه دارید: کنترل این پروفایل را فراهم می کند.';
	@override String get resetCode => 'بازگرداندن کد زوج';
	@override String get resetDescription => 'تمام فاصله ها را قطع کنید و یک کد جدید ایجاد کنید.هر فاصله باید دوباره با هم ارتباط برقرار کند.';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$fa extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'آیا می خواهید از جلسه از راه دور خارج شوید؟';
	@override String get reconnecting => 'دوباره اتصال...';
	@override String attemptOf({required Object current}) => 'تلاش ${current} از 5';
	@override String get retryNow => 'بازگشت اکنون';
	@override String get tabRemote => 'فاصله';
	@override String get tabPlay => 'اجرا کردن';
	@override String get tabMore => 'بیشتر';
	@override String get menu => 'فهرست';
	@override String get tabNavigation => 'برچسب ها Navigation';
	@override String get tabDiscover => 'کشف';
	@override String get tabLibraries => 'کتابخانه‌ها';
	@override String get tabSearch => 'جستجو کردن';
	@override String get tabDownloads => 'بارگیری‌ها';
	@override String get tabSettings => 'تنظیمات';
	@override String get previous => 'قبلی';
	@override String get playPause => 'بازی / استراحت';
	@override String get next => 'بعدی';
	@override String get seekBack => 'بازگشت جستجو';
	@override String get stop => 'توقف';
	@override String get seekForward => 'جستجو FWD';
	@override String get volume => 'حجم';
	@override String get volumeDown => 'پایین';
	@override String get volumeUp => 'بالا';
	@override String get fullscreen => 'تمام صفحه';
	@override String get subtitles => 'زیرنویس‌ها';
	@override String get audio => 'صدا';
	@override String get searchHint => 'جستجو در دسکتاپ';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$fa extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'هیچ رابط شبکه یافت نشد';
	@override String get authenticationFailed => 'تصدیق شکست خورد';
	@override String serverStartFailed({required Object error}) => 'عدم راه اندازی سرور از راه دور: ${error}';
	@override String commandFailed({required Object error}) => 'عدم ارسال دستور از راه دور: ${error}';
	@override String get joinTimedOut => 'زمان ورود به جلسه';
	@override String get failedToConnectAnyAddress => 'عدم دسترسی به هر آدرس';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'اتصال از دست رفته پس از تلاش های ${attempts}';
	@override String get connectionLost => 'اتصال از دست رفته';
}

// Path: services.names
class _Translations$services$names$fa extends Translations$services$names$en {
	_Translations$services$names$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class _Translations$services$simklReconnect$fa extends Translations$services$simklReconnect$en {
	_Translations$services$simklReconnect$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'اتصال مجدد Simkl';
	@override String get subtitle => 'Simkl از روش ثبت نام خارج می شود این اتصال استفاده می کند. دوباره اتصال simkl.com را برای تایید PlezyNG - PlezyNG هرگز رمز عبور شما را نمی بیند. تاریخچه ساعت شما در Simkl باقی می ماند.';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$fa extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'فعال کردن PlezyNG در ${service}';
	@override String get instructions => 'کد QR را اسکن کنید یا به آدرس زیر مراجعه کنید و این کد را وارد کنید:';
	@override String openToActivate({required Object service}) => '${service} را برای فعال کردن باز کنید';
	@override String get copyCode => 'کپی کد فعال سازی';
	@override String get waitingForAuthorization => 'منتظر صدور مجوز...';
	@override String get codeCopied => 'کد کپی شده';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$fa extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'ثبت نام در ${service}';
	@override String get body => 'این کد QR را اسکن کنید یا URL را در هر دستگاه باز کنید.';
	@override String openToSignIn({required Object service}) => '${service} را برای ثبت نام باز کنید';
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$fa extends Translations$services$pendingAuth$en {
	_Translations$services$pendingAuth$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'کپی کردن Sign-in URL';
	@override String get urlCopied => 'URL کپی شده';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$fa extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get title => 'کتابخانه فیلتر';
	@override String get subtitleAllSyncing => 'همگام سازی تمام کتابخانه ها';
	@override String get subtitleNoneSyncing => 'هیچ چیز همگام نمی شود';
	@override String subtitleBlocked({required Object count}) => '${count} مسدود شده';
	@override String subtitleAllowed({required Object count}) => '${count} مجاز است';
	@override String get mode => 'فیلتر حالت';
	@override String get modeBlacklist => 'لیست سیاه';
	@override String get modeWhitelist => 'لیست سفید';
	@override String get modeHintBlacklist => 'همه کتابخانه ها را به جز کتابخانه های زیر همگام کنید.';
	@override String get modeHintWhitelist => 'فقط کتابخانه هایی که در زیر بررسی شده اند را همگام کنید.';
	@override String get libraries => 'کتابخانه‌ها';
	@override String get noLibraries => 'هیچ کتابخانه ای در دسترس نیست';
	@override String get modeDescription => 'انتخاب کنید که آیا کتابخانه های چک شده از همگام سازی مسدود شده اند یا تنها کتابخانه هایی هستند که همگامه می کنند.';
}

// Path: services.trackerDescriptions
class _Translations$services$trackerDescriptions$fa extends Translations$services$trackerDescriptions$en {
	_Translations$services$trackerDescriptions$fa._(TranslationsFa root) : this._root = root, super.internal(root);

	final TranslationsFa _root; // ignore: unused_field

	// Translations
	@override String get trakt => 'همگام سازی قسمت ها و فیلم های تماشا شده با حساب تراکت شما.';
	@override String get mal => 'همگام سازی لیست های انیمه و تماشای پیشرفت با MyAnimeList.';
	@override String get anilist => 'همگام سازی لیست های انیمه و تماشای پیشرفت با AniList.';
	@override String get simkl => 'سینک فیلم ها، نمایش های تلویزیونی و انیمه را با Simkl تماشا کرد.';
	@override String get mdblist => 'نمایش رتبه های MDBList و لیست ها در توصیه ها و کشف.';
}

/// The flat map containing all translations for locale <fa>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsFa {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'appIcon.title' => 'آیکون اپ',
			'appIcon.defaultIcon' => 'پیشفرض',
			'appIcon.current' => 'آیکون فعلی',
			'appIcon.locked' => 'دسترسی طول عمر مورد نیاز',
			'appIcon.lockedHint' => '7-روز آزمایشی خود را شروع کنید یا برای مدت طولانی PlezyNG را برای استفاده از آیکون های جایگزین باز کنید.',
			'appIcon.changeFailed' => 'امکان تغییر آیکون اپلیکیشن',
			'appIcon.launcherHint' => 'آیکون جدید در صفحه اصلی شما ظاهر می شود هنگامی که شما PlezyNG را ترک می کنید.',
			'appIcon.tvLauncherHint' => 'بنر جدید پس از ترک PlezyNG ظاهر می شود. Android TV می تواند تا زمانی که تلویزیون دوباره راه اندازی شود، به نمایش قدیمی ادامه دهد.',
			'appIcon.names.midnight' => 'نیمه شب',
			'appIcon.names.ember' => 'مرد',
			'appIcon.names.paper' => 'کاغذ',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => 'خط',
			'appIcon.names.ocean' => 'اقیانوس',
			'appIcon.names.ultraviolet' => 'اولتراویول',
			'appIcon.names.matcha' => 'مسابقه',
			'appIcon.names.sunset' => 'خورشید',
			'appIcon.names.gold' => 'طلا',
			'appIcon.names.titanium' => 'تیتانیوم',
			'appIcon.names.glass' => 'شیشه',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => 'Synthwave',
			'appIcon.names.pixel' => 'پیکسل',
			'appIcon.names.neon' => 'نئون',
			'appIcon.names.sticker' => 'برچسب ها',
			'appIcon.names.ticket' => 'بلیط',
			'appIcon.names.pop' => 'پاپ',
			'appIcon.names.strata' => 'خیابان',
			'appIcon.names.facet' => 'چهره',
			'appIcon.names.tilde' => 'تایلند',
			'appIcon.description' => 'آیکون نمایش داده شده توسط راه اندازی دستگاه خود را انتخاب کنید پیش بینی ها نشان می دهد که چگونه هر گزینه به نظر می رسد.',
			'auth.signInWithPlex' => 'ثبت نام با شماره Plex',
			'auth.showQRCode' => 'کد QR را نشان دهید',
			'auth.authenticate' => 'معتبر',
			'auth.authenticationTimeout' => 'تاریخ ثبت نام به پایان رسیده است لطفا دوباره امتحان کنید',
			'auth.scanQRToSignIn' => 'این کد QR را برای ثبت نام در',
			'auth.waitingForAuth' => 'منتظر صدور گواهینامه ... از مرورگر خود وارد شوید.',
			'auth.useBrowser' => 'استفاده از مرورگر',
			'auth.or' => 'یا',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'تماس با ${product}',
			'auth.quickConnect' => 'اتصال سریع',
			'auth.useQuickConnect' => 'از اتصال سریع استفاده کنید',
			'auth.quickConnectInstructions' => 'اتصال سریع را در Jellyfin باز کنید و این کد را وارد کنید.',
			'auth.quickConnectWaiting' => 'منتظر تصویب...',
			'auth.quickConnectCancel' => 'لغو کردن',
			'auth.quickConnectExpired' => 'مهلت اتصال سریع تمام شد. دوباره تلاش کنید.',
			'auth.localDataRecoveryRequired' => 'PlezyNG نتوانست اطلاعات ورود محلی و داده‌های پخشِ در انتظار را به‌طور ایمن بازیابی کند. لطفاً دوباره وارد حساب شوید.',
			'auth.pinCheckRejected' => 'چک PIN Plex رد شد',
			'auth.connectToDirectPlex' => 'اتصال به سرور محلی Plex',
			'common.cancel' => 'لغو کردن',
			'common.save' => 'ذخیره',
			'common.close' => 'بستن',
			'common.closeMiniPlayer' => 'بازی مینی نزدیک',
			'common.closeWorkspaceWindow' => 'پنجره نزدیک',
			'common.returnToFullView' => 'بازگشت به دید کامل',
			'common.manageMediaSessions' => 'مدیریت جلسات رسانه ای',
			'common.hideMediaSessions' => 'جلسات رسانه ای پنهان',
			'common.mediaSessions' => 'جلسات رسانه ای',
			'common.mediaSessionsHint' => 'پارک پنجره خود را پنهان می کند اما آن را باز نگه می دارد بازگشت آن را در نمایش کامل باز می کند؛ نزدیک آن را به پایان می رساند.',
			'common.sessionInWorkspace' => 'در کارگاه',
			'common.sessionParked' => 'پارکینگ',
			'common.sessionFullscreen' => 'صفحه نمایش کامل',
			'common.switchToNextWindow' => 'تعویض با پنجره بعدی',
			'common.moveWindow' => 'حرکت پنجره',
			'common.finishMovingWindow' => 'پایان پنجره حرکت',
			'common.moveWindowHint' => 'فشار طولانی و کشیدن پنجره برای حرکت آن. این کنترل همچنین اجازه می دهد تا حرکت کلید شلیک.',
			'common.movingWindowHelp' => 'کشیدن به حرکت · تنظیم کلیدهای کشیدن · وارد کردن ذخایر · فرار لغو',
			'common.resizeWindow' => 'بازسازی پنجره',
			'common.resizeWindowHint' => 'این دستبند را بردارید یا از کلیدهای گلوله برای بازسازی پنجره استفاده کنید.',
			'common.workspaceWindowHint' => 'از کنترل حرکت یا فشار طولانی و کشیدن برای حرکت استفاده کنید.',
			'common.workspacePaneHint' => 'این پانل را انتخاب کنید تا روی آن تمرکز کند.استفاده از کنترل صفحه نمایش کامل برای گسترش.',
			'common.workspaceWindowLabel' => ({required Object title}) => 'پنجره جلسه: ${title}',
			'common.workspaceTitleHint' => 'برای حرکت، نوار عنوان را کشید؛ از دکمه صفحه نمایش کامل برای گسترش استفاده کنید.',
			'common.moveToSessionTray' => 'حرکت به جلسه تری',
			'common.moveToSessionTrayHint' => 'این جلسه را بدون نشان دادن پنجره در دسترس قرار دهید.',
			'common.closeSessionHint' => 'این پنجره را ببندید و جلسه آن به پایان می رسد.',
			'common.sideBySideLayout' => 'سوئیچ به ترتیب جانبی',
			'common.floatingWindows' => 'سوئیچ برای پرواز پنجره ها',
			'common.clear' => 'روشن',
			'common.reset' => 'بازسازی',
			'common.later' => 'بعداً',
			'common.submit' => 'تایید',
			'common.confirm' => 'تایید',
			'common.retry' => 'تلاش مجدد',
			'common.logout' => 'ثبت نام کنید',
			'common.unknown' => 'ناشناخته',
			'common.refresh' => 'به‌روز‌رسانی',
			'common.yes' => 'بلی',
			'common.no' => 'خیر',
			'common.delete' => 'حذف',
			'common.edit' => 'ویرایش',
			'common.shuffle' => 'پخش تصادفی',
			'common.addTo' => 'اضافه کردن به...',
			'common.createNew' => 'ایجاد جدید',
			'common.connect' => 'اتصال',
			'common.disconnect' => 'قطع اتصال',
			'common.play' => 'اجرا کردن',
			'common.pause' => 'مکث',
			'common.resume' => 'ادامهٔ پخش',
			'common.error' => 'خطا',
			'common.search' => 'جستجو کردن',
			'common.home' => 'خانه',
			'common.back' => 'بازگشت',
			'common.settings' => 'تنظیمات',
			'common.mute' => 'سکوت',
			'common.ok' => 'خوب',
			'common.off' => 'خاموش',
			'common.options' => 'گزینه ها',
			'common.seasonNumber' => ({required Object number}) => 'فصل ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'قسمت ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'فصل ${number}',
			'common.reconnect' => 'دوباره متصل',
			'common.viewAll' => 'مشاهده همه',
			'common.checkingNetwork' => 'بررسی شبکه...',
			'common.loadingServers' => 'سرورهای بارگذاری...',
			'common.connectingToServers' => 'اتصال به سرورها',
			'common.startingOfflineMode' => 'در حالت offline...',
			'common.loading' => 'بارگذاری...',
			'common.fullscreen' => 'تمام صفحه',
			'common.exitFullscreen' => 'خروجی صفحه نمایش کامل',
			'common.pressBackAgainToExit' => 'دوباره فشار دهید تا خارج شوید.',
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
			'common.mediaKind.movie' => 'فیلم',
			'common.mediaKind.show' => 'نمایش',
			'common.mediaKind.season' => 'فصل',
			'common.mediaKind.episode' => 'قسمت سریال',
			'common.mediaKind.artist' => 'هنرمند',
			'common.mediaKind.album' => 'آلبوم',
			'common.mediaKind.track' => 'قطعه',
			'common.mediaKind.collection' => 'مجموعه',
			'common.mediaKind.playlist' => 'لیست پخش',
			'common.mediaKind.clip' => 'فیلم کوتاه',
			'common.mediaKind.photo' => 'عکس',
			'common.mediaKind.folder' => 'پوشه',
			'screens.licenses' => 'مجوز',
			'screens.switchProfile' => 'سوئیچ پروفایل',
			'screens.subtitleStyling' => 'زیرنویس سبک',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'گزارش ها',
			'update.available' => 'Update در دسترس',
			'update.versionAvailable' => ({required Object version}) => 'نسخه ${version} در دسترس است',
			'update.currentVersion' => ({required Object version}) => 'در حال حاضر: ${version}',
			'update.skipVersion' => 'دانلود این نسخه',
			'update.viewRelease' => 'مشاهده انتشارات',
			'update.latestVersion' => 'شما در آخرین نسخه هستید',
			'update.checkFailed' => 'نتوانستیم به روز رسانی ها را بررسی کنیم',
			'settings.title' => 'تنظیمات',
			'settings.supportDeveloper' => 'پشتیبانی PlezyNG',
			'settings.supportDeveloperDescription' => 'کمک های مالی برای حمایت از توسعه',
			'settings.lifetimeAccess' => 'PlezyNG دسترسی طول عمر',
			'settings.language' => 'زبان',
			'settings.theme' => 'قالب',
			'settings.appearance' => 'ظهور',
			'settings.detailPage' => 'جزئیات صفحه',
			'settings.themeSongsEnabled' => 'دانلود آهنگ های موضوعی',
			'settings.themeSongsEnabledDescription' => 'پخش آهنگ های موضوعی در دسترس در حالی که مشاهده جزئیات رسانه ها.',
			'settings.themeSongVolume' => 'موضوع آهنگ حجم',
			'settings.videoPlayback' => 'ویدئو Playback',
			'settings.videoPlaybackDescription' => 'تنظیم رفتار playback',
			'settings.advanced' => 'پیشرفته',
			'settings.episodePosterMode' => 'برچسب های ارشیو Poster Style',
			'settings.seriesPoster' => 'سری پوستر',
			'settings.seasonPoster' => 'فصل پوستر',
			'settings.episodeThumbnail' => 'تامبیا',
			'settings.showHeroSectionDescription' => 'صفحه نمایش محتوای کارواش در صفحه نمایش خانگی',
			'settings.secondsLabel' => 'ثانیه ها',
			'settings.minutesLabel' => 'دقیقه ها',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'م',
			'settings.durationHint' => ({required Object min, required Object max}) => 'مقدار را وارد کنید (${min}-${max})',
			'settings.systemTheme' => 'سیستم',
			'settings.lightTheme' => 'نور',
			'settings.darkTheme' => 'تاریکی',
			'settings.oledTheme' => 'OLED',
			'settings.emberTheme' => 'مرد',
			'settings.glacierTheme' => 'یخ',
			'settings.forestTheme' => 'جنگل',
			'settings.plumTheme' => 'آلویی',
			'settings.paperTheme' => 'کاغذ',
			'settings.libraryDensity' => 'تراکم کتابخانه',
			'settings.displayScale' => 'نمایش مقیاس',
			'settings.compact' => 'کمپیکت',
			'settings.comfortable' => 'راحتی',
			'settings.gridSpacing' => 'شبکه فضایی',
			'settings.gridSpacingTight' => 'تیتا',
			'settings.gridSpacingNormal' => 'طبیعی',
			'settings.gridSpacingSpacious' => 'فضایی',
			'settings.tvCornerSpotlightBackdrop' => 'زاویه Spotlight Backdrop',
			'settings.tvCornerSpotlightBackdropDescription' => 'نمایش آثار هنری در گوشه سمت راست بالا به جای پر کردن صفحه نمایش',
			'settings.viewMode' => 'دیدن مد',
			'settings.gridView' => 'شبکه',
			'settings.listView' => 'لیست',
			'settings.showHeroSection' => 'نمایش قسمت قهرمان',
			'settings.showHomeBackdrop' => 'خانه » آرشیوهای برچسب: Backdrop Artwork',
			'settings.showHomeBackdropDescription' => 'نمایش آثار هنری بزرگ در پشت خطوط خانگی',
			'settings.contentScreensaverEnabled' => 'محتوای صفحه نمایش',
			'settings.contentScreensaverEnabledDescription' => 'نمایش آثار هنری با صفحه نمایش کامل پس از آن که اپلیکیشن idle بوده است',
			'settings.contentScreensaverDelay' => 'صفحه نمایش پس از شروع',
			'settings.contentScreensaverLibraries' => 'صفحه نمایش کتابخانه ها',
			'settings.contentScreensaverLibrariesDescription' => 'انتخاب کنید که کدام کتابخانه ها کار هنری ذخیره صفحه نمایش را ارائه می دهند.اگر هیچ کدام از آنها انتخاب نشده است، کار هنری از تمام کتابخانه ها استفاده می شود.',
			'settings.contentScreensaverAllLibraries' => 'تمام کتابخانه‌ها',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} کتابخانه های انتخاب شده',
			'settings.contentScreensaverNoLibraries' => 'هیچ کتابخانه رسانه ای متصل در دسترس نیست.',
			'settings.contentScreensaverDismissHint' => 'هر دکمه یا دکمه را فشار دهید تا حذف شود.',
			'settings.newEpisodeNotifications' => 'خبرهای جدید قسمت',
			'settings.newEpisodeNotificationsDescription' => 'هشدار هنگامی که یک قسمت جدید به یک نمایش اضافه می شود که شما در آن قرار گرفته اید. چک در حالی که Plezy باز است.',
			'settings.continueWatchingRowSize' => 'ادامه مشاهده اندازه خط',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => '${label} کارت',
			'settings.rowSizeCompact' => 'کمپیکت',
			'settings.rowSizeStandard' => 'استاندارد',
			'settings.rowSizeLarge' => 'بزرگ',
			'settings.continueWatchingAction' => 'ادامه فعالیت های نظارت',
			'settings.continueWatchingPlay' => 'اجرا کردن',
			'settings.continueWatchingDetails' => 'جزئیات باز',
			'settings.episodeAction' => 'قسمت اکشن',
			'settings.episodePlay' => 'اجرا کردن',
			'settings.episodeDetails' => 'جزئیات باز',
			'settings.useGlobalHubs' => 'استفاده از Home Layout',
			'settings.useGlobalHubsDescription' => 'صفحه اصلی » کتابخانه » کتابخانه » کتابخانه » کتابخانه » کتابخانه » کتابخانه » کتابخانه » کتابخانه » کتابخانه » کتابخانه » کتابخانه',
			'settings.showServerNameOnHubs' => 'نمایش نام سرور در Hubs',
			'settings.showServerNameOnHubsDescription' => 'همیشه نام سرورها را در عنوان های هاب نشان دهید.',
			'settings.groupLibrariesByServer' => 'کتابخانه های گروهی توسط سرور',
			'settings.groupLibrariesByServerDescription' => 'کتابخانه های گروهی در زیر هر سرور رسانه ای',
			'settings.alwaysKeepSidebarOpen' => 'همیشه دایره باز نگه دارید',
			'settings.alwaysKeepSidebarOpenDescription' => 'صفحه پشتی گسترش می یابد و محدوده محتوا به حالت مناسب تنظیم می شود.',
			'settings.showUnwatchedCount' => 'نمایش نامنظری',
			'settings.showUnwatchedCountDescription' => 'نمایش قسمت های ناشناخته شمارش در نمایش ها و فصل ها',
			'settings.showWatchedIndicators' => 'نمایش شاخص های مشاهده شده',
			'settings.showWatchedIndicatorsDescription' => 'نشان دادن یک چک بر روی فیلم ها، نمایش ها و قسمت های تماشا شده',
			'settings.showEpisodeNumberOnCards' => 'نمایش قسمت شماره در نقشه ها',
			'settings.showEpisodeNumberOnCardsDescription' => 'نمایش فصل و شماره قسمت در کارت های قسمت',
			'settings.showSeasonPostersOnTabs' => 'نمایش پوستر های فصل در Tabs',
			'settings.showSeasonPostersOnTabsDescription' => 'نمایش پوستر هر فصل در بالای برچسب آن',
			'settings.tvFullCardLayout' => 'کارت های تلویزیونی کامل',
			'settings.tvFullCardLayoutDescription' => 'استفاده از کارت های تلویزیونی فقط با نام های بازیگر',
			'settings.focusGlow' => 'تمرکز گلو',
			'settings.focusGlowDescription' => 'یک نور نرم را در اطراف کارت تمرکز کنید.',
			'settings.visualEffects' => 'اثرات بصری',
			'settings.visualEffectsAuto' => 'خودکار',
			'settings.visualEffectsAutoDescription' => 'کاهش اثر به طور خودکار بر روی دستگاه های کم قدرت',
			'settings.visualEffectsFull' => 'کامل',
			'settings.visualEffectsReduced' => 'کاهش یافته',
			'settings.visualEffectsReducedDescription' => 'کمتر انیمیشن ها و هنرهای با رزولوشن پایین تر',
			'settings.hideSpoilers' => 'مخفی کردن اسپویلرها برای قسمت های ناشناخته',
			'settings.hideSpoilersDescription' => 'خلاصه ای و توصیفات برای قسمت های ناشناخته',
			'settings.playerBackend' => 'بازی Backend',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'دکوراسیون سخت افزاری',
			'settings.hardwareDecodingDescription' => 'استفاده از سرعت سخت افزاری هنگامی که در دسترس',
			'settings.playbackBuffer' => 'بایگانی برچسب ها: playback buffer',
			'settings.playbackBufferAuto' => 'اتومبیل ( توصیه می شود )',
			'settings.playbackBufferLarge' => 'بزرگ',
			'settings.playbackBufferExtraLarge' => 'فوق العاده بزرگ',
			'settings.playbackBufferDescription' => 'بوفری بیشتر در برابر اتصالات نامناسب محدود به اندازه بوفری.',
			'settings.streamBufferSize' => 'حجم بوفری',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} مگابایت',
			'settings.streamBufferSizeDescription' => 'چه مقدار ویدئو برای بارگذاری به جلو در هنگام پخش مستقیم. ترانسکود ها در خروجی ترانسکود خود سرور متوقف می شوند. 0 = اتوماتیک',
			'settings.streamBufferSizeExoNote' => 'جایگزین کردن Playback Buffer در هنگام تنظیم، در نیمی از محدودیت حافظه برنامه',
			'settings.streamBufferMegabytes' => 'مگابیت ها',
			'settings.defaultQualityTitle' => 'کیفیت پیش فرض',
			'settings.cellularQualityTitle' => 'کیفیت پیش فرض در سلول ها',
			'settings.remoteQualityTitle' => 'کیفیت پخش از راه دور',
			'settings.remoteQualitySameAsDefault' => 'همانند کیفیت پیش فرض',
			'settings.cellularQualitySameAsDefault' => 'همانند کیفیت پیش فرض',
			'settings.directPlayCoveredQuality' => 'بازی ویدئوهای کوچک تر با کیفیت اصلی',
			'settings.directPlayCoveredQualityDescription' => 'پخش مستقیم ویدئوها در محدوده کیفیت به جای آنکه آنها را رمزگذاری کنند',
			'settings.videoCodecs' => 'ویدئو کدک',
			'settings.videoCodecsDescription' => 'کدک های غیرقابل بررسی توسط سرور رمزگذاری می شوند',
			'settings.videoCodecsAlwaysAccepted' => 'همیشه پذیرفته شده',
			'settings.musicQualityTitle' => 'کیفیت آهنگ',
			'settings.subtitleStyling' => 'زیرنویس سبک',
			'settings.subtitleStylingDescription' => 'ظاهر زیرنویس را مشخص کنید',
			'settings.smallSkipDuration' => 'مدت زمان اسکایک',
			'settings.largeSkipDuration' => 'مدت زمان اسکایپ',
			'settings.rewindOnResume' => 'بازگشت به خلاصه',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(seconds, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} ثانیه', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} ثانیه', ), 
			'settings.defaultSleepTimer' => 'زمان خواب پیش فرض',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(minutes, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} دقیقه', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} دقیقه', ), 
			'settings.rememberTrackSelections' => 'به یاد داشته باشید انتخاب مسیر در هر نمایش / فیلم',
			'settings.chooseTracksBeforePlayback' => 'صدا و زیرنویس ها را قبل از پخش انتخاب کنید.',
			'settings.chooseTracksBeforePlaybackDescription' => 'صدا منبع و زیرنویس را قبل از شروع هر ویدئو انتخاب کنید.',
			'settings.alwaysShowSubtitlesOnDevice' => 'همیشه زیرنویس ها را در این دستگاه نشان دهید',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => 'هنگامی که سرور هیچ زیرنویس انتخاب نشده است، یک ردیف را به صورت محلی انتخاب کنید.این هرگز ترجیحات سرور را تغییر نمی دهد.',
			'settings.autoDownloadPreferredSubtitle' => 'فیتچ از دست دادن زیرنویس های زبان مورد علاقه',
			'settings.autoDownloadPreferredSubtitleDescription' => 'یک زیرنویس در دسترس را در زبان مورد علاقه خود به صورت محلی انتخاب کنید.اگر هیچ کدام وجود ندارد، از سرور بخواهید که یک زیرنویس را در هنگام پشتیبانی دریافت کند.',
			'settings.rememberTrackSelectionsDescription' => 'ذخیره کردن گزینه های صوتی و زیرنویس با نمایش یا فیلم در این دستگاه',
			'settings.rememberTrackSelectionsBackendRule' => 'در محل کار با Plex، Jellyfin و Emby؛ Plex و Jellyfin نیز می تواند انتخاب ها را در سرور ذخیره کند.',
			'settings.followServerTrackSelections' => 'استفاده از گزینه های ردیابی سرور برای هر قسمت',
			'settings.followServerTrackSelectionsDescription' => 'در تغییر قسمت، صدا و زیرنویس های انتخاب شده را در سرور اعمال کنید به جای اینکه بر روی گزینه فعلی حرکت کنید.',
			'settings.resumeMusicOnLaunch' => 'یادآوری جلسه موسیقی',
			'settings.resumeMusicOnLaunchDescription' => 'باز کردن آخرین آهنگ استراحت که در آن آن را ترک زمانی که برنامه شروع می شود',
			'settings.showChapterMarkersOnTimeline' => 'نمایش شاخص ها در جستجو بار',
			'settings.showChapterMarkersOnTimelineDescription' => 'دسته بندی نوار جستجو در مرزهای فصل',
			'settings.specialsOrdering' => 'مشخصات ویژه در قسمت',
			'settings.specialsOrderingDescription' => 'کجا بازی های ویژه در یک ساعت نمایش',
			'settings.specialsOrderingServer' => 'دستور سرور را دنبال کنید',
			'settings.specialsOrderingAirDate' => 'تاریخ پرواز با هوا',
			'settings.specialsOrderingLast' => 'بعد از فصل های عادی',
			'settings.clickVideoTogglesPlayback' => 'روی ویدئو کلیک کنید تا بازی / استراحت کنید',
			'settings.clickVideoTogglesPlaybackDescription' => 'ویدئو را کلیک کنید تا به جای نمایش کنترل ها، پخش/توقف کنید.',
			'settings.videoPlayerControls' => 'کنترل ویدئو بازیکن',
			'settings.keyboardShortcuts' => 'کلید کوتاه',
			'settings.keyboardShortcutsDescription' => 'تگ های کوتاه صفحه کلید',
			'settings.videoPlayerNavigation' => 'بازی های ویدئویی Navigation',
			'settings.videoPlayerNavigationDescription' => 'استفاده از کلیدهای گلوله برای ناوبری کنترل های پخش ویدئو',
			'settings.watchTogetherRelay' => 'با هم رله را ببینید',
			'settings.watchTogetherRelayDescription' => 'پخش عمومی Open Watch Party مگر اینکه خودتان را تنظیم کنید',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.watchTogetherRelayInvalid' => 'نشانی پایهٔ معتبر HTTP یا HTTPS برای سرور واسط وارد کنید.',
			'settings.crashReporting' => 'گزارش تصادف',
			'settings.crashReportingDescription' => 'ارسال گزارش های تصادف برای کمک به بهبود برنامه',
			'settings.debugLogging' => 'ثبت گزارش اشکال‌زدایی',
			'settings.debugLoggingDescription' => 'امکان ثبت نام دقیق برای حل مشکلات',
			'settings.viewLogs' => 'مشاهده Logs',
			'settings.viewLogsDescription' => 'مشاهده نرم افزار Logs',
			'settings.clearImageCache' => 'تصویر شفاف Cache',
			'settings.clearImageCacheDescription' => 'آینه ها را می توان آهسته تر بارگذاری کرد تا دوباره دانلود شود.',
			'settings.clearImageCacheSuccess' => 'تصویر کاسه با موفقیت پاک شد',
			'settings.resetSettings' => 'تنظیمات مجدد',
			'settings.resetSettingsDescription' => 'تنظیمات پیش فرض را بازگردانید.این نمی تواند غیر قابل اجرا باشد.',
			'settings.resetSettingsSuccess' => 'تنظیمات با موفقیت بازگردانید',
			'settings.backup' => 'پشتیبان',
			'settings.exportSettings' => 'تنظیمات صادرات',
			'settings.exportSettingsDescription' => 'ذخیره ترجیحات خود را به یک فایل',
			'settings.exportSettingsSuccess' => 'تنظیمات صادرات',
			'settings.importSettings' => 'تنظیمات واردات',
			'settings.importSettingsDescription' => 'بازگرداندن ترجیحات از یک فایل',
			'settings.importSettingsConfirm' => 'این کار جایگزین تنظیمات فعلی شما خواهد شد. ادامه دهید؟',
			'settings.importSettingsSuccess' => 'تنظیمات وارداتی',
			'settings.importSettingsInvalidFile' => 'این فایل معتبر نیست PlezyNG تنظیمات صادرات',
			'settings.importSettingsNoUser' => 'قبل از واردات تنظیمات را وارد کنید',
			'settings.cloudBackup' => 'Cloud پشتیبان',
			'settings.cloudBackupDescription' => 'پشتیبان گیری تنظیمات قابل حمل به یک نقطه نهایی WebDAV بیش از HTTPS. اتصالات سرور و اعتبارات در این دستگاه باقی می ماند.',
			'settings.cloudBackupUrl' => 'WebDAV JSON فایل URL',
			'settings.cloudBackupUsername' => 'نام کاربری',
			'settings.cloudBackupPassword' => 'گذرواژه',
			'settings.cloudBackupSaved' => 'Cloud Backup مقصد نجات یافته است',
			'settings.cloudBackupNow' => 'بازگشت به حال',
			'settings.cloudBackupComplete' => 'تنظیمات پشتیبان بارگذاری شده',
			'settings.cloudBackupRestore' => 'بازگرداندن Backup',
			'settings.cloudBackupRestoreConfirm' => 'این جایگزین تنظیمات قابل حمل مطابقت در این دستگاه خواهد بود.',
			'settings.cloudBackupRestored' => 'تنظیمات بازگردانده شده از پشتیبان ابر',
			'settings.shortcutsReset' => 'تعویض کوتاه به تعویضات',
			'settings.resetShortcutsConfirm' => 'این کار کوتاه کردن های سفارشی شما را با کوتاه کردن های پیش فرض جایگزین می کند.',
			'settings.about' => 'درباره',
			'settings.aboutDescription' => 'اپلیکیشن اطلاعات و مجوزها',
			'settings.updates' => 'به روز رسانی',
			'settings.updateAvailable' => 'Update در دسترس',
			'settings.checkForUpdates' => 'بررسی به روز رسانی ها',
			'settings.autoCheckUpdatesOnStartup' => 'به طور خودکار برای به روز رسانی در استارتاپ چک کنید',
			'settings.autoCheckUpdatesOnStartupDescription' => 'هنگامی که یک به روز رسانی در راه اندازی در دسترس است، اطلاع دهید.',
			'settings.validationErrorEnterNumber' => 'لطفا شماره معتبر را وارد کنید.',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'باید بین ${min} و ${max} ${unit} باشد.',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'کوتاه مدت در حال حاضر به ${action} اختصاص داده شده است',
			'settings.shortcutUpdated' => ({required Object action}) => 'بایگانی برچسب ها: ${action}',
			'settings.saveFailed' => 'تغییراتی که نمی توانم انجام دهم، دوباره امتحان کنید.',
			'settings.autoPlayAndSkip' => 'دانلود بازی Auto-Play & Skip',
			'settings.autoPlayNextEpisode' => 'بازی اتوماتیک قسمت بعدی',
			'settings.autoPlayNextEpisodeDescription' => 'قسمت بعدی را به صورت اتوماتیک شروع کنید، زمانی که یک قسمت به پایان می رسد.',
			'settings.shuffleStartsFromBeginning' => 'شوفلی در ابتدا شروع کرد',
			'settings.shuffleStartsFromBeginningDescription' => 'هر قسمت را در ابتدا شروع کنید، زمانی که به جای تکرار آن، در حال چرخش هستید.',
			'settings.plexCinemaPreRoll' => 'استفاده از سرور سینما',
			'settings.plexCinemaPreRollDescription' => 'بازی پیش نمایش Plex یا Jellyfin و Emby قبل از شروع یک فیلم.',
			'settings.playNextCountdown' => 'دانلود بازی Next Countdown',
			'settings.playNextCountdownImmediate' => 'بازی بلافاصله',
			'settings.skipIntroMode' => 'کشتی وارد',
			'settings.skipIntroModeOffDescription' => 'به طور معمول بدون یک دکمه اسکایپ بازی کنید',
			'settings.skipIntroModeButtonDescription' => 'نشان دادن یک دکمه اسکایپ هنگامی که یک ورودی شروع می شود',
			'settings.skipIntroModeAutoDescription' => 'به صورت اتوماتیک پس از تاخیر زیر وارد شوید.',
			'settings.skipCreditsMode' => 'کپی اعتبارات',
			'settings.skipCreditsModeOffDescription' => 'بازی اعتبارات به طور معمول بدون یک دکمه اسکایپ',
			'settings.skipCreditsModeButtonDescription' => 'نمایش دکمه اسکایپ هنگامی که اعتبارات شروع می شود',
			'settings.skipCreditsModeAutoDescription' => 'اعتبارات خودکار را بردارید و قسمت بعدی را بازی کنید',
			'settings.skipAdsMode' => 'آگهی های اسکایپ',
			'settings.skipAdsModeOffDescription' => 'پخش آگهی های شناسایی شده به طور معمول بدون یک دکمه اسکایپ',
			'settings.skipAdsModeButtonDescription' => 'یک دکمه اسکایپ را هنگامی که Plex یک آگهی را تشخیص می دهد نشان دهید',
			'settings.skipAdsModeAutoDescription' => 'حذف آگهی های شناسایی شده به طور خودکار پس از تاخیر زیر',
			'settings.musicPlayback' => 'موسیقی Playback',
			'settings.musicSweetFades' => 'شیرین فید',
			'settings.musicSweetFadesDescription' => 'دانلود موسیقی در لبه های ردیابی زمانی که Plex دارای داده های صدا است.',
			'settings.skipMarkerModeOff' => 'خاموش',
			'settings.skipMarkerModeButton' => 'نمایش دکمه',
			'settings.skipMarkerModeAuto' => 'اتوماتیک',
			'settings.forceSkipMarkerFallback' => 'برچسب های ارشیو: Fallback Markers',
			'settings.forceSkipMarkerFallbackDescription' => 'استفاده از الگوهای عنوان فصل حتی زمانی که Plex دارای برچسب ها است',
			'settings.theIntroDbFallback' => 'استفاده از TheIntroDB به عنوان یک ورودی ورودی',
			'settings.theIntroDbFallbackDescription' => 'از زمان بندی های جامعه فقط زمانی استفاده کنید که سرور دارای علامت ورودی نیست.',
			'settings.autoSkipDelay' => 'اتومبیل اسکای دیر',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'انتظار ${seconds} ثانیه قبل از سوار شدن',
			'settings.introPattern' => 'مدل مارکر',
			'settings.introPatternDescription' => 'الگوی Regex برای مطابقت با مارک های ورودی در عنوان های فصل',
			'settings.creditsPattern' => 'برچسب های ارشیو برچسب ها',
			'settings.creditsPatternDescription' => 'الگوی Regex برای مطابقت با برچسب های اعتباری در عنوان های فصل',
			'settings.prerolls' => 'پیشگویی',
			'settings.playPrerollsBeforeMovies' => 'بازی قبل از فیلم ها',
			'settings.playPrerollsBeforeMoviesDescription' => 'بازی یک کلیپ تصادفی از انتخاب زیر قبل از هر فیلم.',
			'settings.prerollLibrary' => 'کتابخانه Preroll',
			'settings.prerollLibraryNotSet' => 'نه تنظیم',
			'settings.prerollLibraryNoneFound' => 'هیچ کتابخانه ای در سرورهای شما یافت نشد.',
			'settings.prerollSelection' => 'انتخاب نمایندگان',
			'settings.prerollSelectionPickLibraryFirst' => 'کتابخانه را اول انتخاب کنید',
			'settings.prerollSelectionNoneSelected' => 'هیچ انتخابی انتخاب نشده',
			'settings.prerollSelectionCount' => ({required Object count}) => '${count} انتخاب شده',
			'settings.prerollItemPicker' => 'انتخاب امتیازات',
			'settings.prerollItemPickerLoadFailed' => 'نمی توانم از این کتابخانه استفاده کنم.',
			'settings.invalidRegex' => 'اختلال در بیان عادی',
			'settings.regex' => 'بیان منظم',
			'settings.downloads' => 'بارگیری‌ها',
			'settings.downloadLocationDescription' => 'انتخاب جایی که محتوای دانلود شده را ذخیره کنید',
			'settings.downloadLocationDefault' => 'ذخیره سازی اپلیکیشن (App Storage)',
			'settings.downloadLocationCustom' => 'مکان سفارشی',
			'settings.selectFolder' => 'انتخاب پوشه',
			'settings.resetToDefault' => 'بازگشت به حالت پیش فرض',
			'settings.currentPath' => ({required Object path}) => 'در حال حاضر: ${path}',
			'settings.downloadLocationChanged' => 'دانلود محل تغییر',
			'settings.downloadLocationReset' => 'دانلود مجدد مکان به حالت پیش فرض',
			'settings.downloadLocationInvalid' => 'پوشه های انتخاب شده قابل نوشتن نیستند',
			'settings.downloadLocationPickerUnavailable' => 'انتخاب پوشه در این دستگاه در دسترس نیست',
			'settings.downloadOnWifiOnly' => 'دانلود در Wi-Fi فقط',
			'settings.downloadOnWifiOnlyDescription' => 'جلوگیری از بارگذاری در هنگام استفاده از داده های سلولی',
			'settings.autoRemoveWatchedDownloads' => 'حذف خودکار دانلود های مشاهده شده',
			'settings.autoRemoveWatchedDownloadsDescription' => 'حذف دانلود های مشاهده شده به طور خودکار',
			'settings.autoDownloadContinueWatching' => 'دانلود خودکار ادامه مطلب',
			'settings.autoDownloadContinueWatchingDescription' => 'نگه داشتن آیتم ها در صفحه نمایش ادامه دانلود، و حذف آنها پس از آنها را ترک صفحه نمایش',
			'settings.downloadQuality' => 'دانلود کیفیت',
			'settings.downloadQualityDescription' => 'Plex یک کپی تبدیل شده را در محدوده دانلود آن آماده می کند. Jellyfin و Emby transcode در حالی که فایل دانلود می شود؛ انتقال متوقف شده ممکن است نیاز به راه اندازی مجدد داشته باشد.',
			'settings.askDownloadQualityEachTime' => 'انتخاب کیفیت برای هر دانلود',
			'settings.askDownloadQualityEachTimeDescription' => 'نمایش پیکر کیفیت قبل از هر دانلود ویدئو',
			'settings.cellularDownloadBlocked' => 'دانلود ها در تلفن همراه مسدود شده است.استفاده از Wi-Fi یا تنظیمات را تغییر دهید.',
			'settings.maxVolume' => 'بیشترین بلندی صدا',
			'settings.maxVolumeDescription' => 'اجازهٔ تقویت صدا بیش از 100٪ برای رسانه‌های کم‌صدا',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'غنی غنی غنی',
			'settings.discordRichPresenceDescription' => 'نشان دهید چه چیزی در Discord تماشا می کنید',
			'settings.services' => 'خدمات',
			'settings.servicesDescription' => 'اتصال Trakt، MyAnimeList، Seerr، و بیشتر',
			'settings.manageLibrariesDescription' => 'کتابخانه ها را ذخیره و پنهان کنید',
			'settings.companionRemoteServer' => 'سرورهای از راه دور',
			'settings.companionRemoteServerDescription' => 'اجازه دهید دستگاه های تلفن همراه در شبکه شما این برنامه را کنترل کنند',
			'settings.companionRemoteServerStartFailed' => 'نمی توانم سرور همراه را راه اندازی کنم.',
			'settings.companionRemoteServerStopFailed' => 'نمی توانم سرور همراه را متوقف کنم.',
			'settings.autoPip' => 'عکس های خودکار در تصویر',
			'settings.autoPipDescription' => 'به طور خودکار تصویر-در-تصویر را وارد کنید هنگامی که برنامه را در طول پخش ترک می کنید',
			'settings.matchContentFrameRate' => 'مسابقه محتوای فریم نرخ',
			'settings.matchContentFrameRateDescription' => 'بازی نمایش نرخ بازسازی به محتوای ویدئویی',
			'settings.matchContentResolution' => 'حل محتوای مسابقه',
			'settings.matchContentResolutionDescription' => 'صفحه نمایش را به رزولوشن بومی ویدئو تغییر دهید تا تلویزیون شما به حالت بالا حرکت کند.منوها و زیرنویس ها نیز در هنگام پخش به حالت بالا حرکت می کنند.',
			'settings.matchRefreshRate' => 'مسابقه تمیز کردن نرخ',
			'settings.matchRefreshRateDescription' => 'بازی نمایش نرخ تازه در صفحه نمایش کامل',
			'settings.matchDynamicRange' => 'بازی Dynamic Range',
			'settings.matchDynamicRangeDescription' => 'HDR را برای محتوای HDR تغییر دهید و سپس به SDR برگردید.',
			'settings.displaySwitchDelay' => 'نمایش سوئیچ دیر',
			'settings.tunneledPlayback' => 'بازی های تونل',
			'settings.tunneledPlaybackDescription' => 'استفاده از تونل ویدئویی غیرفعال می شود اگر پخش HDR ویدئو سیاه یا حرکت استوتری ها را نشان می دهد.',
			'settings.audioPassthrough' => 'صدا درخشان',
			'settings.audioPassthroughDescription' => 'ارسال صدا Dolby/DTS به گیرنده یا تلویزیون بدون رمزگذاری مجدد، حفظ صدا اطراف.',
			'settings.audioPassthroughDescriptionApple' => 'از دکوراسیون دلفی بومی Apple برای دلفی دیجیتال پلاس، از جمله Atmos استفاده کنید. DTS و TrueHD هنوز هم به عنوان PCM چند کانال بازی می کنند.',
			'settings.audioPassthroughDescriptionAppleSpatial' => 'از دکوراسیون دلفی بومی Apple برای Dolby Digital Plus، از جمله Atmos استفاده کنید.در iOS، iPadOS و tvOS 26 یا بعد، TrueHD Atmos و DTS:X به عنوان صدا فضایی پخش می شود.در سایر ردیف های DTS و TrueHD به عنوان PCM چند کانال پخش می شود.',
			'settings.audioPassthroughOverriddenByNormalization' => 'در حالی که صداها به حالت عادی می رسند',
			'settings.audioChannelLimit' => 'کانال های صوتی',
			'settings.audioChannelLimitDescription' => 'مخلوط کردن صدا رمزگذاری شده برای بلندگوها، گوشی های هوشمند و یا تنظیمات HDMI که نمی تواند هر کانال پخش',
			'settings.audioChannelLimitOriginal' => 'اصلی',
			'settings.audioChannelLimitOriginalDescription' => 'بازی هر کانال در مسیر',
			'settings.audioChannelLimitSurround51' => 'تا 5.1',
			'settings.audioChannelLimitSurround51Description' => 'مخلوط 7.1 به 5.1 برای تلویزیون ها و گیرنده هایی که فقط 5.1 PCM را می گیرند.',
			'settings.audioChannelLimitStereo' => 'استریو',
			'settings.audioChannelLimitStereoDescription' => 'مخلوط کردن به دو کانال برای بلندگوهای استریو یا گوشی های هوشمند.',
			'settings.downmixCenterBoost' => 'مرکز کانال بوست',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} دبی',
			'settings.downmixCenterBoostLabel' => 'افزایش (dB )',
			'settings.downmixCenterBoostShort' => 'دبی',
			'settings.audioDownmixNormalize' => 'دانلود بازی Downmix',
			'settings.audioDownmixNormalizeDescription' => 'مخلوط را پایین بیاورید تا از چرخش جلوگیری شود.برای حفظ حجم اصلی (ممکن است صحنه های بلند را مختل کند) خاموش کنید.',
			'settings.dvConversionMode' => 'Dolby Vision تبدیل',
			'settings.dvConversionModeDescription' => 'انتخاب کنید که چگونه فایل های پروفایل 7 Dolby Vision پردازش می شوند.',
			'settings.dvConversionAuto' => 'خودکار',
			'settings.dvConversionNative' => 'معلول / معلول',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'استفاده از قابلیت تشخیص دستگاه و رفتار سقوط عادی',
			'settings.dvConversionNativeDescription' => 'قدرت نادر DV7 و سرکوب DV تبدیل عقب نشینی',
			'settings.dvConversionDv81Description' => 'تبدیل RPU به پروفایل Dolby Vision 8.1',
			'settings.dvConversionHevcStripDescription' => 'نوار Dolby Vision لایه های RPU/EL و سطح فعلی HEVC',
			'settings.experimentalDolbyVision' => 'Dolby Vision آزمایشی',
			'settings.experimentalDolbyVisionDescription' => 'در پخش بعدی از رندرکنندهٔ آزمایشی FEL استفاده شود. به ساخت جداگانهٔ موتور نیاز دارد.',
			'settings.dvExperimentUnavailableDescription' => 'این آزمایش فعلاً فقط در Linux در دسترس است.',
			'settings.dvCompatibilityFallback' => 'گزینهٔ جایگزین سازگار',
			'settings.dvCompatibilityFallbackDescription' => 'اگر آزمایش شروع نشد، از رندرکنندهٔ استاندارد استفاده شود. ممکن است داده‌های FEL از دست بروند.',
			'settings.dvExperimentDiagnostics' => 'ثبت رویدادهای آزمایش ویدیو',
			'settings.dvExperimentDiagnosticsDescription' => 'در پخش بعدی گزارش‌های دقیق پخش‌کننده فعال شوند.',
			'settings.disableDolbyVision' => 'غیر قابل اجرا Dolby Vision',
			'settings.disableDolbyVisionDescription' => 'در فایل HDR10 یا لایه HLG به جای Dolby Vision بازی کنید، زمانی که یک',
			'settings.hdrSdrConversion' => 'HDR به SDR تبدیل',
			'settings.hdrSdrConversionDescription' => 'انتخاب کنید که چه چیزی ویدئو HDR را تبدیل می کند زمانی که صفحه نمایش نمی تواند HDR را نشان دهد.',
			_ => null,
		} ?? switch (path) {
			'settings.hdrSdrConversionAuto' => 'خودکار',
			'settings.hdrSdrConversionAutoDescription' => 'دستگاه در Android 9 و بالاتر، پخش کننده در نسخه های قدیمی تر',
			'settings.hdrSdrConversionDevice' => 'دستگاه',
			'settings.hdrSdrConversionDeviceDescription' => 'سخت افزار ویدئویی دستگاه شما آن را تبدیل می کند سریع ترین، اما رنگ ها بستگی به دستگاه دارد',
			'settings.hdrSdrConversionPlayer' => 'پخش‌کننده',
			'settings.hdrSdrConversionPlayerDescription' => 'رنگ های سازگار، اما 4K می تواند بر روی جعبه های تلویزیونی پایین',
			'settings.deinterlace' => 'دایناسور',
			'settings.deinterlaceDescription' => 'آثار شانه‌ای ویدیوی درهم‌بافته را حذف کنید (فقط پخش‌کنندهٔ mpv)',
			'settings.deinterlaceOff' => 'خاموش',
			'settings.deinterlaceOffDescription' => 'نمایش ویدئو متصل به عنوان آن را رمزگذاری شده است',
			'settings.deinterlaceVideo' => 'ویدئو',
			'settings.deinterlaceVideoDescription' => 'برای فیلم برداری ویدئویی برای تلویزیون، مانند ورزش، اخبار و کنسرت ها',
			'settings.deinterlaceFilm' => 'فیلم',
			'settings.deinterlaceFilmDescription' => 'بازگرداندن چارچوب های اصلی فیلم و انیمیشن به 29.97 fps، رایج در DVD های NTSC. فیلمبرداری ویدئویی برای فیلمبرداران.',
			'settings.requireProfileSelectionOnOpen' => 'درخواست پروفایل در اپلیکیشن باز',
			'settings.requireProfileSelectionOnOpenDescription' => 'نمایش انتخاب پروفایل هر بار که اپلیکیشن باز می شود',
			'settings.forceTvMode' => 'حالت تلویزیون قدرت',
			'settings.forceTvModeDescription' => 'برای دستگاه هایی که خود شناسایی نمی کنند، نیاز به راه اندازی مجدد دارد.',
			'settings.startInFullscreen' => 'شروع در صفحه نمایش کامل',
			'settings.startInFullscreenDescription' => 'باز کردن PlezyNG در حالت صفحه نمایش کامل در راه اندازی',
			'settings.exitFullscreenOnPlayerClose' => 'خروجی صفحه نمایش کامل در بازیکن بسته',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'خروجی خودکار صفحه نمایش کامل در هنگام بستن پخش کننده ویدئویی',
			'settings.autoHidePerformanceOverlay' => 'اتومبیل های خودکار',
			'settings.autoHidePerformanceOverlayDescription' => 'عملکرد را با کنترل های بازسازی از بین ببرید',
			'settings.showNavBarLabels' => 'نشان دادن برچسب ها Navigation Bar',
			'settings.showNavBarLabelsDescription' => 'نمایش برچسب های متن در زیر آیکون های نوار ناوبری',
			'settings.startupSection' => 'بخش Startup',
			'settings.preferredServer' => 'ترجیح سرور',
			'settings.preferredServerDescription' => 'اولویت بندی نتایج این سرور در حالی که حفظ هر سرور متصل در دسترس است.',
			'settings.preferredServerAutomatic' => 'اتوماتیک',
			'settings.showExploreTab' => 'نمایش تگ ها',
			'settings.showExploreTabDescription' => 'نمایش برگه اکتشاف با محتوای Plex اکتشاف و ردیاب های متصل',
			'settings.hideEmptyLibraries' => 'کتابخانه های خالی را پنهان کنید',
			'settings.hideEmptyLibrariesDescription' => 'حذف کتابخانه ها با تعداد آیتم های گزارش شده توسط سرور از صفر از ناوبری.',
			'settings.liveTvDefaultFavorites' => 'کانال های مورد علاقه',
			'settings.liveTvDefaultFavoritesDescription' => 'نمایش تنها کانال های مورد علاقه در هنگام باز کردن تلویزیون زنده',
			'settings.general' => 'عمومی',
			'settings.generalDescription' => 'زبان، راه اندازی و رفتار پنجره',
			'settings.languageAndRegion' => 'زبان و منطقه',
			'settings.startup' => 'راه‌اندازی',
			'settings.display' => 'نمایش',
			'settings.libraryAndCards' => 'کتابخانه و کارت',
			'settings.homeScreen' => 'صفحه اصلی صفحه نمایش',
			'settings.navigation' => 'جهت یابی',
			'settings.window' => 'پنجره',
			'settings.liveTv' => 'تلویزیون زنده',
			'settings.player' => 'پخش‌کننده',
			'settings.videoAndDisplay' => 'ویدئو و نمایش',
			'settings.audio' => 'صدا',
			'settings.quality' => 'کیفیت',
			'settings.subtitles' => 'زیرنویس‌ها',
			'settings.seekAndTiming' => 'جستجو و زمان بندی',
			'settings.behavior' => 'رفتار',
			'settings.gestures' => 'راهپیمایی',
			'settings.gestureBrightnessSwipe' => 'روشنایی سوئیپ',
			'settings.gestureBrightnessSwipeDescription' => 'بالا یا پایین را روی لبه چپ بپوشانید تا روشنایی را تنظیم کنید.',
			'settings.gestureVolumeSwipe' => 'حجم سوئیپ',
			'settings.gestureVolumeSwipeDescription' => 'بالا یا پایین را در لبه راست حرکت دهید تا حجم را تنظیم کنید.',
			'settings.gesturePinchToZoom' => 'پینچ به زوم',
			'settings.gesturePinchToZoomDescription' => 'بر روی ویدئو کلیک کنید تا وارد یا خارج شود.',
			'settings.gestureSeekSwipe' => 'جستجو برای Swipe',
			'settings.gestureSeekSwipeDescription' => 'سمت چپ یا راست را در هر نقطه از ویدئو برای جستجو تغییر دهید؛ آزاد کردن برای پرش',
			'settings.rememberBrightnessLevel' => 'سطح روشنایی را به یاد داشته باشید',
			'settings.rememberBrightnessLevelDescription' => 'شروع بازی در روشنایی تعیین شده توسط آخرین سوئیپ',
			'settings.controls' => 'کنترل ها',
			'settings.rememberPlayerChanges' => 'تغییرات بازیکنان را به یاد داشته باشید',
			'settings.rememberPlayerChangesDescription' => 'جایی که تغییراتی که در طول بازیابی انجام می شود ذخیره و دوباره اعمال می شود',
			'settings.scopePlaybackSpeed' => 'سرعت پخش',
			'settings.scopeShaderPreset' => 'شیراز پیش بینی',
			'settings.scopeAspectRatio' => 'نسبت تصویر',
			'settings.scopeSyncOffsets' => 'Audio & Subtitle همگام سازی',
			'settings.playerScopeOff' => 'نجات ندهید',
			'settings.playerScopeGlobal' => 'همه جا',
			'settings.playerScopeLibrary' => 'در کتابخانه',
			'settings.playerScopeTitle' => 'برای نمایش یا فیلم',
			'settings.exportDialogTitle' => 'صادرات PlezyNG تنظیمات',
			'settings.followSystem' => 'پیروی از سیستم',
			'settings.followAppLanguage' => 'مطابق زبان رابط کاربری',
			'settings.regionFormat' => 'قالب‌های منطقه‌ای',
			'settings.regionFormatDescription' => 'نحوهٔ نمایش تاریخ‌ها، اعداد و واحدهای اندازه‌گیری را انتخاب کنید.',
			'settings.metadataLanguage' => 'زبان فراداده',
			'settings.metadataLanguageDescription' => 'زبان دلخواه عنوان‌ها و توضیحات، در صورت پشتیبانی سرور. تنظیمات زبان صدا و زیرنویس مستقل هستند.',
			'settings.enterFullscreenOnPlaybackStart' => 'صفحه نمایش کامل هنگامی که playback شروع می شود',
			'settings.enterFullscreenOnPlaybackStartDescription' => 'باز کردن ویدئو دسکتاپ در صفحه نمایش کامل هنگامی که پخش شروع می شود',
			'settings.extendVideoIntoDisplayCutout' => 'اضافه کردن ویدئو به صفحه نمایش',
			'settings.extendVideoIntoDisplayCutoutDescription' => 'اجازه دهید ویدئوی صفحه نمایش کامل از دوربین بر روی گوشی های اندرویدی استفاده کند',
			'settings.languageDescription' => 'زبان مورد استفاده برای کنترل ها و پیام های PlezyNG را انتخاب کنید سیستم ردیابی زبان دستگاه شما را دنبال می کند.',
			'settings.themeDescription' => 'رنگ ها و کنتراست های مورد استفاده در سراسر برنامه را انتخاب کنید.',
			'settings.libraryDensityDescription' => 'تغییر تعداد کارت های کتابخانه در هر ردیف.',
			'settings.displayScaleDescription' => 'رابط کاربری را در این صفحه نمایش اتومبیل بازگردانید بدون تغییر اندازه متن دستگاه شما.',
			'settings.themeSongVolumeDescription' => 'حجم آهنگ های موضوعی را نسبت به سایر صداها تنظیم کنید.',
			'settings.viewModeDescription' => 'انتخاب کنید که آیا آیتم های کتابخانه به عنوان پوستر در یک شبکه یا به عنوان یک لیست کوچک ظاهر می شوند.',
			'settings.gridViewDescription' => 'آیتم های کتابخانه را در ردیف ها و ستون های پوستر مرتب کنید.',
			'settings.listViewDescription' => 'نمایش آیتم های کتابخانه در یک لیست عمودی با متن بیشتر برای هر آیتم.',
			'settings.gridSpacingDescription' => 'فاصله بین پوسترها را در شبکه های کتابخانه تنظیم کنید.',
			'settings.gridSpacingTightDescription' => 'پوستر های بیشتری را در سراسر صفحه نمایش با شکاف های کوچکتر قرار دهید.',
			'settings.gridSpacingNormalDescription' => 'استفاده از فاصله استاندارد بین پوسترها',
			'settings.gridSpacingSpaciousDescription' => 'فاصله های بزرگتر بین پوسترها را برای جداسازی بیشتر اضافه کنید.',
			'settings.episodePosterModeDescription' => 'انتخاب کنید که کدام آثار هنری بر روی کارت های قسمت نمایش داده می شود.',
			'settings.seriesPosterDescription' => 'از پوستر سریال برای هر قسمت استفاده کنید.',
			'settings.seasonPosterDescription' => 'استفاده از پوستر فصل برای هر قسمت زمانی که در دسترس است.',
			'settings.episodeThumbnailDescription' => 'استفاده از یک چارچوب از قسمت زمانی که در دسترس است.',
			'settings.continueWatchingActionDescription' => 'انتخاب کنید که چه اتفاقی می افتد هنگامی که یک کارت نظارت مداوم را فعال می کنید.',
			'settings.continueWatchingPlayDescription' => 'فیلم یا قسمت را بلافاصله شروع کنید.',
			'settings.continueWatchingDetailsDescription' => 'صفحه عنوان را ابتدا باز کنید تا بتوانید جزئیات را بررسی کنید و یک اقدام را انتخاب کنید.',
			'settings.episodeActionDescription' => 'انتخاب کنید که چه اتفاقی می افتد هنگامی که شما یک کارت قسمت را فعال می کنید.',
			'settings.episodePlayDescription' => 'قسمت را بلافاصله شروع کنید.',
			'settings.episodeDetailsDescription' => 'صفحه قسمت را قبل از پخش باز کنید.',
			'settings.contentScreensaverDelayDescription' => 'انتخاب کنید که چقدر طول می کشد PlezyNG بدون ورودی قبل از نمایش آثار هنری منتظر بماند.',
			'settings.continueWatchingRowSizeDescription' => 'انتخاب کنید که کارت ها در ردیف ادامه تماشای چقدر بزرگ هستند.',
			'settings.rowSizeCompactDescription' => 'نشان دادن کارت های کوچکتر به طوری که عناصر بیشتر در سراسر ردیف مناسب است.',
			'settings.rowSizeStandardDescription' => 'از اندازه کارت استاندارد استفاده کنید.',
			'settings.rowSizeLargeDescription' => 'نمایش کارت های بزرگتر با جزئیات هنری بیشتر.',
			'settings.visualEffectsDescription' => 'بودجه انیمیشن و اثر هنری را برای این دستگاه انتخاب کنید.',
			'settings.visualEffectsFullDescription' => 'از اثرات کامل انیمیشن و هنری در هر دستگاه استفاده کنید.',
			'settings.startupSectionDescription' => 'انتخاب کنید که کدام بخش در هنگام شروع PlezyNG باز می شود.',
			'settings.startupSectionOptions.discover' => 'توصیه ها و موارد را از منابع کشف مرتبط باز کنید.',
			'settings.startupSectionOptions.libraries' => 'کتابخانه های رسانه های متصل خود را باز کنید.',
			'settings.startupSectionOptions.liveTv' => 'تلویزیون زنده را هنگامی که یک سرور آن را ارائه می دهد باز کنید؛ در غیر این صورت استارتاپ به خانه باز می گردد.',
			'settings.startupSectionOptions.search' => 'جستجوی رسانه های باز',
			'settings.smallSkipDurationDescription' => 'تنظیم فاصله حرکت شده توسط کوتاه عقب و جلو به دنبال کنترل.',
			'settings.largeSkipDurationDescription' => 'فاصله را که به عقب و جلو حرکت می کند تنظیم کنید، کنترل ها را جستجو کنید.',
			'settings.rewindOnResumeDescription' => 'بازگرداندن بازی با این مقدار هنگامی که یک ویدئو را دوباره پخش می کنید.',
			'settings.defaultSleepTimerDescription' => 'مدت زمان اولیه استفاده شده در هنگام شروع ساعت خواب را تنظیم کنید.',
			'settings.playNextCountdownDescription' => 'این مطلب را قبل از شروع قسمت بعدی به مدت طولانی منتظر بمانید تا بلافاصله شروع شود.',
			'settings.autoSkipDelaySettingDescription' => 'زمانی اعمال می شود که یک ورودی، اعتبار یا آگهی به طور خودکار تنظیم شده است.',
			'settings.downmixCenterBoostDescription' => 'افزایش گفتگو در کانال مرکزی هنگامی که صدا اطراف به استریو مخلوط می شود.',
			'settings.displaySwitchDelayDescription' => 'قبل از تغییر حالت نمایش منتظر بمانید تا تلویزیون یا گیرنده بتواند سوئیچ قبلی خود را به پایان برساند.',
			'settings.playerBackendDescription' => 'انتخاب کنید که کدام موتور پخش ویدئو را بر روی این دستگاه دکوراسیون و بازگرداند.',
			'settings.exoPlayerDescription' => 'از پخش کننده مادری آندروید مبتنی بر Media3 و مسیرهای سخت افزاری پشتیبانی شده استفاده کنید.',
			'settings.mpvDescription' => 'از mpv استفاده کنید، که بازتاب اضافی، زیرنویس و کنترل های پردازش ویدئو را نشان می دهد.',
			'settings.scopeOffDescription' => 'فقط تغییرات مربوط به جلسه پخش فعلی را حفظ کنید.',
			'settings.scopeGlobalDescription' => 'همان مقدار را برای هر کتابخانه و عنوان تکرار کنید.',
			'settings.scopeLibraryDescription' => 'به یاد داشته باشید که ارزش جداگانه ای برای هر کتابخانه وجود دارد.',
			'settings.scopeTitleDescription' => 'به یاد داشته باشید یک مقدار جداگانه برای هر نمایش یا فیلم.',
			'settings.specialsOrderingServerDescription' => 'سفارش قسمت را که توسط سرور رسانه ها ارائه می شود حفظ کنید.',
			'settings.specialsOrderingAirDateDescription' => 'قرار دادن ویژه ها در میان قسمت های منظم با توجه به تاریخ هوایی آنها.',
			'settings.specialsOrderingLastDescription' => 'قرار دادن هر خاص پس از فصل های معمولی.',
			'settings.skipIntroModeDescription' => 'انتخاب کنید که آیا مارک های ورودی به طور معمول بازی می کنند، یک دکمه اسکایپ را نشان می دهند یا به صورت اتوماتیک.',
			'settings.skipCreditsModeDescription' => 'انتخاب کنید که آیا اعتبارات به طور معمول بازی می کنند، یک دکمه اسکایپ را نشان می دهند یا به طور خودکار اسکایپا می کنند.',
			'settings.skipAdsModeDescription' => 'انتخاب کنید که آیا آگهی های شناسایی شده به طور معمول پخش می شوند، یک دکمه اسکایپ را نشان می دهند یا به طور خودکار اسکایپا می کنند.',
			'settings.playbackBufferAutoDescription' => 'اجازه دهید بازیکن فعال اندازه بوفری معمولی خود را انتخاب کند.',
			'settings.playbackBufferLargeDescription' => 'رسانه های بیشتری را قبل از پخش آماده نگه دارید؛ این از حافظه بیشتر استفاده می کند.',
			'settings.playbackBufferExtraLargeDescription' => 'بزرگترین حافظه خواندن را نگه دارید؛ این بیشترین حافظ را به دست می آورد.',
			'settings.defaultQualityDescription' => 'رزولوشن ویدئویی پیش فرض را تنظیم کنید و سقف بیترات را برای جریان هایی که سرور از آن عبور می کند، تنظیم کنید.',
			'settings.cellularQualityDescription' => 'بر روی کیفیت پیش فرض هنگامی که دستگاه از یک اتصال سلولی استفاده می کند.',
			'settings.remoteQualityDescription' => 'بر روی کیفیت پیش فرض هنگام اتصال به یک سرور از طریق یک اتصال از راه دور.',
			'settings.qualityPresetOriginalDescription' => 'منبع را با کیفیت در دسترس خود بازی کنید بدون اینکه از سرور بخواهید آن را رمزگذاری کند.',
			'settings.qualityPresetTranscodeOptionDescription' => 'از سرور برای یک جریان تبدیل شده با استفاده از رزولوشن و bitrate نشان داده شده در بالا بپرسید.',
			'settings.qualityPresetSameAsDefaultDescription' => 'استفاده از کیفیت انتخاب شده در کیفیت پیش فرض.',
			'settings.musicQualityDescription' => 'حداکثر بیتی صدا را که از سرور خواسته می شود تنظیم کنید؛ اصلی جریان منبع را حفظ می کند.',
			'settings.musicQualityOriginalDescription' => 'پخش صدا منبع بدون یک ترانسکد بیتی.',
			'settings.musicQualityTranscodeOptionDescription' => 'درخواست یک ترانسکود سرور در نزدیکی نرخ بیتی که در بالا نشان داده شده است؛ خروجی واقعی می تواند متفاوت باشد.',
			'settings.maxVolumeInputLabel' => 'حداکثر حجم ( % )',
			'settings.checkForUpdatesDescription' => 'در حال حاضر بررسی کنید که آیا نسخه جدیدتر از PlezyNG در دسترس است یا خیر.',
			'settings.appearanceDescription' => 'موضوع برنامه را انتخاب کنید و کارت های کتابخانه، خطوط خانه و ناوبری را تنظیم کنید.',
			'settings.prerollLibraryDescription' => 'کتابخانه ای را انتخاب کنید که شامل کلیپ های موجود به عنوان پیش نمایش فیلم است.',
			'settings.prerollSelectionDescription' => 'انتخاب کنید که کدام کلیپ ها از کتابخانه انتخاب شده می توانند قبل از فیلم بازی کنند.',
			'settings.contentScreensaverDelayOptionDescription' => 'منتظر این چند دقیقه بدون ورودی قبل از نمایش کار هنری ذخیره صفحه نمایش باشید.',
			'settings.videoCodecOptionDescription' => 'اجازه پخش مستقیم برای این کدک زمانی که پشتیبانی می شود. کدک های غیر چک شده توسط سرور رسانه ها رمزگذاری می شوند.',
			'themeEditor.builtIn' => 'ساخته شده',
			'themeEditor.presets' => 'پیشگویی',
			'themeEditor.custom' => 'سفارشی',
			'themeEditor.customEmpty' => 'هنوز ساخته نشده',
			'themeEditor.editCustom' => 'ویرایش موضوعات',
			'themeEditor.editCustomDescription' => 'هر رنگ را خودتان انتخاب کنید',
			'themeEditor.locked' => 'دسترسی طول عمر مورد نیاز',
			'themeEditor.savedLocked' => 'ذخیره شده – در دسترس با دسترسی ابدی',
			'themeEditor.title' => 'موضوعات شخصی',
			'themeEditor.startFrom' => 'شروع از',
			'themeEditor.startFromDescription' => 'کپی کردن تمام رنگ ها از موضوع دیگری',
			'themeEditor.colors' => 'رنگ ها',
			'themeEditor.preview' => 'پیش نمایش',
			'themeEditor.slots.bg' => 'پس زمینه',
			'themeEditor.slots.surface' => 'سطح',
			'themeEditor.slots.outline' => 'خط دور',
			'themeEditor.slots.text' => 'متن',
			'themeEditor.slots.textMuted' => 'متن ثانویه',
			'themeEditor.slots.accent' => 'تمرکز',
			'themeEditor.opacity' => 'ناخودآگاه',
			'themeEditor.hexHint' => '#RRGGBB یا #AARRGGBB',
			'themeEditor.fromOtherThemes' => 'از موضوعات دیگر',
			'themeEditor.swatchLabel' => ({required Object theme, required Object color}) => '${theme} ${color}',
			'themeEditor.contrast.textOnBg' => 'متن در پس زمینه',
			'themeEditor.contrast.textOnSurface' => 'متن در سطح',
			'themeEditor.contrast.textMutedOnBg' => 'متن دوم در پس زمینه',
			'themeEditor.contrast.textMutedOnSurface' => 'متن ثانویه در سطح',
			'themeEditor.contrast.accentOnBg' => 'تمرکز بر پس زمینه',
			'themeEditor.contrast.accentOnSurface' => 'تمرکز بر سطح',
			'themeEditor.contrast.labelOnAccent' => 'برچسب ها بر روی تمرکز',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, زیر توصیه شده ${minimum}:1',
			'themeEditor.discardTitle' => 'تغییرات را نادیده بگیرید؟',
			'themeEditor.discardMessage' => 'تغییرات ذخیره‌نشدهٔ رنگ از دست می‌روند.',
			'themeEditor.discard' => 'نادیده گرفتن',
			'themeEditor.previewCardTitle' => ({required Object number}) => 'صفحه اصلی ${number}',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => '${minutes} دقیقه باقی مانده',
			'themeEditor.previewSwitch' => 'اتوبوس',
			'themeEditor.previewMutedText' => 'متن دوم این گونه خوانده می شود.',
			'themeEditor.themeSystemDescription' => 'ظاهر دستگاه خود را دنبال کنید و به طور خودکار بین نور و تاریکی تغییر دهید.',
			'themeEditor.themeLightDescription' => 'از یک پس زمینه روشن با متن تاریک استفاده کنید.',
			'themeEditor.themeDarkDescription' => 'از یک پس زمینه تاریک با متن روشن استفاده کنید.',
			'themeEditor.themeOledDescription' => 'از سطوح نزدیک سیاه استفاده کنید که نور را در صفحه نمایش های OLED کاهش می دهند.',
			'themeEditor.themeEmberDescription' => 'از رنگ های گرم قرمز و آمبر استفاده کنید.',
			'themeEditor.themeGlacierDescription' => 'از رنگ های آبی رنگ استفاده کنید.',
			'themeEditor.themeForestDescription' => 'از رنگ های سبز و طبیعی استفاده کنید.',
			'themeEditor.themePlumDescription' => 'از رنگ های ویولیت و پلوم استفاده کنید.',
			'themeEditor.themePaperDescription' => 'از سطوح گرم مانند کاغذ و رنگ های الهام گرفته از نقاشی استفاده کنید.',
			'themeEditor.themeCustomDescription' => 'از پالت رنگی که در ویرایشگر موضوعی سفارشی ایجاد کرده اید استفاده کنید.',
			'themeEditor.editorDescription' => 'یک رنگ پالت را انتخاب کنید، رنگ آن را تنظیم کنید، اشباع، روشنایی یا نابینایی، و قبل از صرفه جویی به روز رسانی پیش نمایش را ببینید.',
			'search.hint' => 'جستجو برای فیلم ها، نمایش ها، موسیقی...',
			'search.tryDifferentTerm' => 'یک اصطلاح جستجو متفاوت را امتحان کنید',
			'search.searchYourMedia' => 'رسانه های خود را جستجو کنید',
			'search.enterTitleActorOrKeyword' => 'عنوان، بازیگر یا کلمه کلیدی را وارد کنید.',
			'search.people' => 'افراد',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'تنظیم کوتاه برای ${actionName}',
			'hotkeys.clearShortcut' => 'کوتاه کردن شفاف',
			'hotkeys.noShortcutSet' => 'بدون کوتاه کردن',
			'hotkeys.currentShortcut' => 'کوتاه مدت فعلی :',
			'hotkeys.pressToRecord' => 'انتخاب کنید برای ضبط یک کوتاه',
			'hotkeys.recordingShortcut' => 'اکنون کوتاه را فشار دهید',
			'hotkeys.actions.playPause' => 'بازی / استراحت',
			'hotkeys.actions.volumeUp' => 'حجم بالا',
			'hotkeys.actions.volumeDown' => 'حجم پایین',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'جستجو به جلو (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'جستجو برای بازگشت (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'با صفحه نمایش کامل',
			'hotkeys.actions.muteToggle' => 'همبستگی موتی',
			'hotkeys.actions.subtitleToggle' => 'با هم زیرنویس',
			'hotkeys.actions.audioTrackNext' => 'بعدی Audio Track',
			'hotkeys.actions.subtitleTrackNext' => 'بعدی زیرنویس زیرنویس',
			'hotkeys.actions.chapterNext' => 'بخش بعد',
			'hotkeys.actions.chapterPrevious' => 'بخش قبلی',
			'hotkeys.actions.episodeNext' => 'قسمت بعد',
			'hotkeys.actions.episodePrevious' => 'قسمت قبلی',
			'hotkeys.actions.speedIncrease' => 'افزایش سرعت',
			'hotkeys.actions.speedDecrease' => 'کاهش سرعت',
			'hotkeys.actions.speedReset' => 'سرعت بازگشت',
			'hotkeys.actions.zoomIn' => 'زوم در',
			'hotkeys.actions.zoomOut' => 'زوم بیرون',
			'hotkeys.actions.zoomReset' => 'بازسازی zoom',
			'hotkeys.actions.subSeekNext' => 'جستجو برای زیرنویس بعدی',
			'hotkeys.actions.subSeekPrev' => 'جستجو برای قبلی Subtitle',
			'hotkeys.actions.subtitleDelayIncrease' => 'تاخیر زیرنویس',
			'hotkeys.actions.subtitleDelayDecrease' => 'زیرنویس های پیشرفته',
			'hotkeys.actions.shaderToggle' => 'سایه ها را جمع کنید',
			'hotkeys.actions.skipMarker' => 'بایگانی برچسب ها: Intro/Credit',
			'hotkeys.actions.screenshot' => 'عکس های صفحه نمایش',
			'hotkeys.actions.framePrevious' => 'قبلی چارچوب',
			'hotkeys.actions.frameNext' => 'بعدی چارچوب',
			'fileInfo.title' => 'فایل اطلاعات',
			'fileInfo.overview' => 'نمای کلی',
			'fileInfo.video' => 'ویدئو',
			'fileInfo.audio' => 'صدا',
			'fileInfo.subtitles' => 'زیرنویس‌ها',
			'fileInfo.images' => 'تصاویر درگیر',
			'fileInfo.dataStreams' => 'جریان داده ها',
			'fileInfo.lyrics' => 'متن ترانه',
			'fileInfo.file' => 'فایل',
			'fileInfo.attachments' => 'اتصال',
			'fileInfo.delivery' => 'تحویل',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => 'نسخه ${index} از ${count}',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => 'فایل ${index} از ${count}',
			'fileInfo.noStreams' => 'سرور اعلام کرد که هیچ جریان برای این فایل وجود ندارد.',
			'fileInfo.copyPath' => 'کپی مسیر',
			'fileInfo.pathCopied' => 'فایل مسیر کپی شده',
			'fileInfo.codec' => 'کدک',
			'fileInfo.codecTag' => 'برچسب کدک',
			'fileInfo.resolution' => 'وضوح تصویر',
			'fileInfo.codedResolution' => 'راه حل کدگذاری شده',
			'fileInfo.bitrate' => 'نرخ جریان',
			'fileInfo.frameRate' => 'فریم نرخ',
			'fileInfo.rotation' => 'چرخش',
			'fileInfo.comment' => 'چگونه',
			'fileInfo.audioDescription' => 'شرح صوتی',
			'fileInfo.headerCompression' => 'سرکوب سرکوب',
			'fileInfo.sidecarFile' => 'فایلهای Sidecar',
			'fileInfo.transportTimestamp' => 'زمان حمل و نقل',
			'fileInfo.displayOffset' => 'نمایش Offset',
			'fileInfo.previewFailureCode' => 'پیش بینی کد شکست',
			'fileInfo.previewRetries' => 'پیش بینی بازگشت',
			'fileInfo.aspectRatio' => 'نسبت تصویر',
			'fileInfo.pixelAspectRatio' => 'Pixel Aspect نسبت',
			'fileInfo.profile' => 'نمایه',
			'fileInfo.level' => 'سطح',
			'fileInfo.bitDepth' => 'عمق بیت',
			'fileInfo.pixelFormat' => 'فرمت پیکسل',
			'fileInfo.colorSpace' => 'فضای رنگی',
			'fileInfo.colorRange' => 'رنگ رینگ',
			'fileInfo.colorPrimaries' => 'مقدمات رنگی',
			'fileInfo.colorTransfer' => 'انتقال رنگ',
			'fileInfo.chromaSubsampling' => 'کروم زیرمجموعه',
			'fileInfo.chromaLocation' => 'موقعیت کروم',
			'fileInfo.scanType' => 'نوع اسکن',
			'fileInfo.interlaced' => 'درهم آمیخته',
			'fileInfo.anamorphic' => 'آنامورفیک',
			'fileInfo.referenceFrames' => 'چارچوب های مرجع',
			'fileInfo.dynamicRange' => 'محدوده دینامیک',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Dolby Vision سطح',
			'fileInfo.dolbyVisionVersion' => 'Dolby Vision نسخه',
			'fileInfo.dolbyVisionLayers' => 'Dolby Vision لایه ها',
			'fileInfo.baseLayerCompatibility' => 'سازگاری لایه پایه',
			'fileInfo.avcBitstream' => 'جریان بیت AVC',
			'fileInfo.nalLengthSize' => 'اندازه طول نال',
			'fileInfo.scalingMatrix' => 'ماتریکس مقیاس سفارشی',
			'fileInfo.streamIdentifier' => 'جریان شناسایی',
			'fileInfo.streamIndex' => 'شاخص جریان',
			'fileInfo.streamId' => 'جریان ID',
			'fileInfo.language' => 'زبان',
			'fileInfo.languageCode' => 'کد زبان',
			'fileInfo.streamTitle' => 'تریلر تریلر',
			'fileInfo.channels' => 'کانالها',
			'fileInfo.sampleRate' => 'نرخ نمونه',
			'fileInfo.spatialAudio' => 'فضای صوتی',
			'fileInfo.textBased' => 'متن مبتنی بر',
			'fileInfo.subtitleFormat' => 'فرمت سیداکار',
			'fileInfo.provider' => 'ارائه دهنده',
			'fileInfo.matchScore' => 'بازی نمره',
			'fileInfo.externalDelivery' => 'می توان به صورت جداگانه خدمت کرد',
			'fileInfo.sidecarPath' => 'راه شیشه ای',
			'fileInfo.sourceStream' => 'کپی شده از',
			'fileInfo.temporary' => 'موقت',
			'fileInfo.timeBase' => 'پایه زمان',
			'fileInfo.overallBitrate' => 'کل بیت کوین',
			'fileInfo.path' => '‏‏مسیر',
			'fileInfo.fileName' => 'نام فایل',
			'fileInfo.size' => 'سایز',
			'fileInfo.totalSize' => 'حجم کل',
			'fileInfo.container' => 'محفظه',
			'fileInfo.duration' => 'مدت زمان',
			'fileInfo.previewThumbnails' => 'پیش نمایش تامپین',
			'fileInfo.previewIndex' => 'پیش نمایش شاخص',
			'fileInfo.packetLength' => 'طول بسته',
			'fileInfo.filePresent' => 'فایلهای موجود',
			'fileInfo.fileReadable' => 'قابل خواندن توسط سرور',
			'fileInfo.streamPath' => 'جریان مسیر',
			'fileInfo.optimizedForStreaming' => 'بهینه سازی برای پخش',
			'fileInfo.has64bitOffsets' => '64 بیتی Offsets',
			'fileInfo.protocol' => 'پروتکل',
			'fileInfo.mediaType' => 'نوع رسانه ها',
			'fileInfo.sourceKind' => 'منبع خوب',
			'fileInfo.optimizedVersion' => 'نسخه بهینه سازی شده',
			'fileInfo.optimizationTarget' => 'هدف بهینه سازی',
			'fileInfo.deletedAt' => 'حذف شده',
			'fileInfo.remoteSource' => 'منبع دور',
			'fileInfo.infiniteStream' => 'جریان بی نهایت',
			'fileInfo.directPlay' => 'بازی مستقیم',
			'fileInfo.directStream' => 'جریان مستقیم',
			'fileInfo.transcoding' => 'کدگذاری',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'نسخه ID',
			'fileInfo.fileId' => 'فایل ID',
			'fileInfo.defaultAudioTrack' => 'تریلر Audio Track',
			'fileInfo.defaultSubtitleTrack' => 'ترک زیرنویس پیش‌فرض',
			'fileInfo.subtitlesOff' => 'خاموش',
			'fileInfo.flagDefault' => 'پیشفرض',
			'fileInfo.flagForced' => 'اجباری',
			'fileInfo.flagSelected' => 'انتخاب شده',
			'fileInfo.flagExternal' => 'خارجی',
			'fileInfo.flagHearingImpaired' => 'شنیدن ضعیف',
			'fileInfo.flagDub' => 'دبی',
			'fileInfo.flagOriginal' => 'اصلی',
			'fileInfo.channelsMono' => 'مونو',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'پروفایل ${profile}',
			'mediaMenu.markAsWatched' => 'مارک به نظر می رسد',
			'mediaMenu.markAsUnwatched' => 'مارک ناشناخته',
			'mediaMenu.removeFromContinueWatching' => 'حذف از ادامه مشاهده',
			'mediaMenu.viewDetails' => 'مشاهده جزئیات',
			'mediaMenu.goToSeries' => 'به سری بروید',
			'mediaMenu.shufflePlay' => 'بازی شوفلی',
			'mediaMenu.shuffleNotAvailableOffline' => 'دانلود بازی Shuffle در دسترس نیست',
			'mediaMenu.fileInfo' => 'فایل اطلاعات',
			'mediaMenu.deleteEpisodeFromServer' => 'حذف قسمت از سرور',
			'mediaMenu.deleteSeasonFromServer' => 'حذف فصل از سرور',
			'mediaMenu.deleteShowFromServer' => 'حذف نمایش از سرور',
			'mediaMenu.deleteMovieFromServer' => 'حذف فیلم از سرور',
			'mediaMenu.deleteEpisodeTitle' => 'این قسمت را حذف کنید؟',
			'mediaMenu.deleteSeasonTitle' => 'این فصل را حذف کنید؟',
			'mediaMenu.deleteShowTitle' => 'این نمایش را حذف کنید؟',
			'mediaMenu.deleteMovieTitle' => 'این فیلم را حذف کنید؟',
			'mediaMenu.deleteEpisodeConfirm' => 'حذف قسمت',
			'mediaMenu.deleteSeasonConfirm' => 'فصل حذف',
			'mediaMenu.deleteShowConfirm' => 'نمایش حذف',
			'mediaMenu.deleteMovieConfirm' => 'حذف فیلم',
			'mediaMenu.deleteAnyway' => 'حذف به هر حال',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => '«${title}» برای همیشه از سرور شما حذف شود؟',
			'mediaMenu.deleteMultipleWarning' => 'این شامل تمام قسمت ها و فایل های آنها است.',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n, one: 'با این کار، ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} قسمت موجود در آن و فایل آن حذف می‌شود.', other: 'با این کار، همهٔ ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} قسمت موجود در آن و فایل‌های آن‌ها حذف می‌شوند.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n, one: 'این مورد در ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} فایل ذخیره شده است و آن فایل حذف خواهد شد.', other: 'این مورد در ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} فایل ذخیره شده است و همهٔ آن‌ها حذف خواهند شد.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} قسمت دیگر در همین فایل ذخیره شده است و آن هم حذف خواهد شد:', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} قسمت دیگر در همین فایل ذخیره شده‌اند و آن‌ها هم حذف خواهند شد:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'PlezyNG نتوانست بررسی کند کدام فایل‌ها حذف می‌شوند؛ بنابراین ممکن است مواردی بیش از مورد بالا حذف شوند. لغو کنید و دوباره تلاش کنید، یا در هر صورت حذف کنید.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'سرور شما جزئیات فایل‌های این مورد را ارائه نکرده است، بنابراین PlezyNG نمی‌تواند بررسی کند کدام فایل‌ها حذف می‌شوند. ممکن است مواردی بیش از مورد بالا حذف شوند.',
			'mediaMenu.mediaDeletedSuccessfully' => 'موضوع رسانه ها با موفقیت حذف شد',
			'mediaMenu.mediaFailedToDelete' => 'ناپدید شدن حذف رسانه ها',
			'mediaMenu.rate' => 'ارزیابی کن',
			'mediaMenu.playFromBeginning' => 'از ابتدا اجرا کن',
			'mediaMenu.playVersion' => 'بازی نسخه...',
			'rateSheet.title' => 'ارزیابی کن',
			'rateSheet.server' => 'سرور',
			'rateSheet.favorite' => 'مورد علاقه',
			'rateSheet.favorited' => 'مورد علاقه',
			'rateSheet.saved' => 'نجات یافته',
			'rateSheet.notAvailable' => 'هیچ مسابقه ای یافت نشد',
			'rateSheet.noConnectedServices' => 'یک سرویس را در تنظیمات متصل کنید تا در آن رتبه بندی شود.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title} فیلم',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title} نمایش تلویزیونی',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'مشاهده شده',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} درصد بازدید',
			'accessibility.mediaCardUnwatched' => 'تماشا نشده',
			'accessibility.tapToPlay' => 'برای پخش ضربه بزنید',
			'accessibility.decrease' => 'کاهش',
			'accessibility.increase' => 'افزایش',
			'accessibility.decreaseValue' => ({required Object label}) => 'کمبود ${label}',
			'accessibility.increaseValue' => ({required Object label}) => 'افزایش ${label}',
			'accessibility.hue' => 'هوی',
			'accessibility.saturation' => 'اشباع رنگ',
			'accessibility.brightness' => 'روشنایی',
			'accessibility.hexColor' => 'رنگ Hex',
			'accessibility.expandText' => 'گسترش متن',
			'accessibility.collapseText' => 'متن خراب',
			'accessibility.alphabetNavigation' => 'آلبوم ناوبری',
			'accessibility.alphabetScrollHint' => 'برای جابه‌جایی بر اساس حروف، انگشت خود را به بالا یا پایین بکشید',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'ردیف ${row} از ${rowCount}، ستون ${column} از ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'خط ${row} از ${rowCount}',
			'accessibility.autoScrollPlay' => 'بازی خودکار اسکرول',
			'accessibility.autoScrollPause' => 'استراحت اتوماتیک',
			'accessibility.hueShort' => 'H',
			'accessibility.saturationShort' => 'S',
			'accessibility.valueShort' => 'V',
			'accessibility.red' => 'قرمز',
			'accessibility.green' => 'سبز',
			'accessibility.blue' => 'آبی',
			'accessibility.redShort' => 'R',
			'accessibility.greenShort' => 'G',
			'accessibility.blueShort' => 'ب',
			'accessibility.colorModeHsv' => 'HSV',
			'accessibility.colorModeRgb' => 'RGB',
			'accessibility.title' => 'دسترسی',
			'accessibility.summary' => 'متن، کنتراست، حرکت و کنترل',
			'accessibility.systemHint' => 'تنظیمات دسترسی دستگاه شما همیشه اعمال می شود این گزینه ها تنظیمات را در طول PlezyNG اضافه می کنند.',
			'accessibility.readability' => 'خواندن و دیدن',
			'accessibility.textSize' => 'اضافه کردن متن',
			'accessibility.preview' => 'داستان بعدی خود را پیدا کنید، بخوانید، گوش دهید و در سرعت خود تماشا کنید.',
			'accessibility.boldText' => 'متن رابط کاربری',
			'accessibility.highContrast' => 'تناقض بالا',
			'accessibility.highContrastHint' => 'متن قوی تر، شاخص های برجسته و تمرکز بر روی سطوح روشن یا تاریک.',
			'accessibility.interaction' => 'حرکت و تعامل',
			'accessibility.reduceMotion' => 'کاهش حرکت',
			'accessibility.reduceMotionHint' => 'حرکت نشانگر تمرکز، گذارهای صفحه و جلوه‌های تزئینی را متوقف کنید.',
			'accessibility.largeTargets' => 'هدف های لمسی بزرگتر',
			'accessibility.largeTargetsHint' => 'کنترل های به اشتراک گذاشته شده را برای لمس و ناوبری کمک کننده فضای بیشتری فراهم می کند.',
			'accessibility.navigationHint' => 'برای جابه‌جایی بین کنترل‌ها از Tab و Shift+Tab، برای فعال‌سازی از Enter یا Space و برای بستن از Escape یا دکمهٔ بازگشت استفاده کنید. وقتی کتاب باز است، بزرگ‌نمایی و تنظیمات خواندن در دسترس‌اند.',
			'accessibility.textSizeDescription' => 'متن رابط مقیاس در PlezyNG علاوه بر تنظیمات اندازه متن سیستم دستگاه شما.',
			'accessibility.boldTextHint' => 'از یک وزن سنگین تر برای برچسب های رابط و پیام ها استفاده کنید تا آنها را آسان تر تشخیص دهند.',
			'tooltips.shufflePlay' => 'بازی شوفلی',
			'tooltips.playTrailer' => 'بازی تریلر',
			'tooltips.markAsWatched' => 'مارک به نظر می رسد',
			'tooltips.markAsUnwatched' => 'مارک ناشناخته',
			'audioTracks.track' => ({required Object n}) => 'ترافیک صوتی ${n}',
			'videoControls.audioLabel' => 'صدا',
			'videoControls.subtitlesLabel' => 'زیرنویس‌ها',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => 'نامه جعبه',
			'videoControls.fillScreen' => 'صفحه نمایش پر',
			'videoControls.stretch' => 'پر کنید',
			'videoControls.lockRotation' => 'چرخش قفل',
			'videoControls.unlockRotation' => 'باز کردن چرخش',
			'videoControls.timerActive' => 'زمان فعال',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'باز کردن بازی در ${duration} استراحت می کند',
			'videoControls.sleepTimerEndOfVideo' => 'پایان ویدئو فعلی',
			'videoControls.sleepTimerStopAtHeader' => 'توقف در',
			'videoControls.sleepTimerDurationHeader' => 'زمان',
			'videoControls.playbackWillPauseAtEnd' => 'Playback در پایان این ویدئو تعطیل خواهد شد',
			'videoControls.stillWatching' => 'هنوز هم تماشا می کنید؟',
			'videoControls.pausingIn' => ({required Object seconds}) => 'استراحت در ${seconds}s',
			'videoControls.continueWatching' => 'ادامه مطلب',
			'videoControls.autoPlayNext' => 'بازی اتوماتیک بعدی',
			'videoControls.playNext' => 'بعدی را اجرا کن',
			'videoControls.playButton' => 'اجرا کردن',
			'videoControls.pauseButton' => 'مکث',
			'videoControls.playbackPaused' => 'استراحت',
			'videoControls.playbackResumed' => 'بازی کردن',
			'videoControls.loadingVideo' => 'دانلود ویدئو',
			'videoControls.showPlaybackControls' => 'نمایش کنترل های Playback',
			'videoControls.hidePlaybackControls' => 'کنترل بازی های مخفی',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'جستجو به عقب ${seconds} ثانیه',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'جستجو در آینده ${seconds} ثانیه',
			'videoControls.previousButton' => 'قسمت قبلی',
			'videoControls.nextButton' => 'قسمت بعد',
			'videoControls.previousChapterButton' => 'بخش قبلی',
			'videoControls.nextChapterButton' => 'بخش بعد',
			'videoControls.muteButton' => 'سکوت',
			'videoControls.unmuteButton' => 'صدادار',
			'videoControls.settingsButton' => 'تنظیمات Playback',
			'videoControls.tracksButton' => 'صدا و زیرنویس',
			'videoControls.chaptersButton' => 'فصل ها',
			'videoControls.segmentLoopHelp' => 'یک بخش را در طول این بازی باز کنید: A را تنظیم کنید، سپس B را بعداً در خط زمانی قرار دهید.',
			'videoControls.setLoopStart' => 'راهکارهایی برای شروع (A)',
			'videoControls.setLoopEnd' => 'تنظیم لوله پایان (ب)',
			'videoControls.clearSegmentLoop' => 'مشخصات segment loop',
			'videoControls.setLoopStartFirst' => 'شروع (A) را قبل از پایان (B) تنظیم کنید.',
			'videoControls.loopEndAfterStart' => 'پایان حلقه باید بعد از شروع باشد.',
			'videoControls.segmentLoopUnavailable' => 'لوله بندی بخش برای این بازی در دسترس نیست.',
			'videoControls.loopPointNotSet' => 'نه تنظیم',
			'videoControls.bookmarksHelp' => 'برچسب ها در این دستگاه ذخیره می شوند. یکی را انتخاب کنید تا به آن زمان بروید.',
			'videoControls.bookmarksButton' => 'برچسب ها Bookmark',
			'videoControls.chaptersAndBookmarks' => 'فصل ها و کتاب نشانه ها',
			'videoControls.segmentLoop' => 'بخش لوله',
			'videoControls.addBookmark' => 'اضافه کردن Bookmark',
			'videoControls.bookmarkName' => 'Bookmark نام',
			_ => null,
		} ?? switch (path) {
			'videoControls.bookmarkNameHint' => 'به عنوان مثال، صحنه باز',
			'videoControls.bookmarkDefaultName' => ({required Object n}) => 'برچسب ها ${n}',
			'videoControls.bookmarkNameRequired' => 'نام این کتاب را وارد کنید.',
			'videoControls.deleteBookmark' => 'حذف Bookmark',
			'videoControls.bookmarkLimitReached' => 'این مقاله در حال حاضر دارای 100 دفترچه یادداشت است.',
			'videoControls.bookmarkUnavailable' => 'نمی توانم این کتاب را ذخیره یا حذف کنم.',
			'videoControls.bookmarkSaved' => 'کتاب را نجات داد.',
			'videoControls.bookmarkDeleted' => 'برچسب حذف شده است.',
			'videoControls.loopPointSet' => ({required Object point, required Object time}) => 'نقطه عطف ${point} تنظیم در ${time}.',
			'videoControls.noChaptersOrBookmarks' => 'هیچ فصل و کتابی در دسترس نیست.',
			'videoControls.versionQualityButton' => 'نسخه و کیفیت',
			'videoControls.versionColumnHeader' => 'نسخه',
			'videoControls.qualityColumnHeader' => 'کیفیت',
			'videoControls.qualityOriginal' => 'اصلی',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} مگابایت در ثانیه',
			'videoControls.transcodeUnavailableFallback' => 'Transcoding Unavailable – بازی با کیفیت اصلی',
			'videoControls.subtitleUnavailableFallback' => 'زیرنویس های انتخاب شده نمی توانند بارگذاری شوند – ادامه بدون زیرنویس ها',
			'videoControls.pipButton' => 'حالت تصویر در تصویر',
			'videoControls.aspectRatioButton' => 'نسبت تصویر',
			'videoControls.ambientLighting' => 'روشنایی محیط زیست',
			'videoControls.fullscreenButton' => 'وارد صفحه نمایش کامل',
			'videoControls.exitFullscreenButton' => 'خروجی صفحه نمایش کامل',
			'videoControls.alwaysOnTopButton' => 'همیشه در بالای',
			'videoControls.rotationLockButton' => 'قفل چرخشی',
			'videoControls.lockScreen' => 'صفحه نمایش قفل',
			'videoControls.screenLockButton' => 'صفحه نمایش قفل',
			'videoControls.timelineSlider' => 'ویدئو زمان بندی',
			'videoControls.volumeSlider' => 'حجم سطح',
			'videoControls.endsAt' => ({required Object time}) => 'در نهایت در ${time}',
			'videoControls.pipActive' => 'بازی در Picture-in-Picture',
			'videoControls.pipFailed' => 'نقاشی در نقاشی شروع نمی شود',
			'videoControls.screenshotSaved' => 'صفحه نمایش ذخیره شده',
			'videoControls.screenshotFailed' => 'نمی توانم یک عکس از صفحه نمایش داشته باشم',
			'videoControls.zoomPercent' => ({required Object percent}) => 'بزرگ‌نمایی ${percent}%',
			'videoControls.volumePercent' => ({required Object percent}) => 'بلندی صدا ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'نیاز به Android 8.0 یا جدیدتر',
			'videoControls.pipErrors.iosVersion' => 'نیاز به iOS 15.0 یا جدیدتر',
			'videoControls.pipErrors.permissionDisabled' => 'Image-in-picture غیرفعال شده است.این را در تنظیمات سیستم فعال کنید.',
			'videoControls.pipErrors.notSupported' => 'دستگاه پشتیبانی از حالت تصویر در تصویر ندارد',
			'videoControls.pipErrors.voSwitchFailed' => 'عدم تغییر خروجی ویدئو برای تصویر در تصویر',
			'videoControls.pipErrors.failed' => 'نقاشی در نقاشی شروع نمی شود',
			'videoControls.pipErrors.prepareFailed' => 'نقاشی در نقاشی آماده نمی شود',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'خطای ناشی از: ${error}',
			'videoControls.chapters' => 'فصل ها',
			'videoControls.noChaptersAvailable' => 'هیچ فصل در دسترس',
			'videoControls.queue' => 'کوی',
			'videoControls.noQueueItems' => 'هیچ موضوعی در قفسه',
			'videoControls.noAudioDevicesAvailable' => 'هیچ دستگاه صوتی در دسترس نیست',
			'videoControls.searchSubtitles' => 'جستجو زیرنویس',
			'videoControls.language' => 'زبان',
			'videoControls.noSubtitlesFound' => 'هیچ زیرنویس یافت نشد',
			'videoControls.subtitleDownloaded' => 'دانلود زیرنویس',
			'videoControls.subtitleDownloadedNotApplied' => 'زیرنویس دانلود شده اما انتخاب نشده است',
			'videoControls.subtitleDownloadFailed' => 'دانلود زیرنویس را از دست ندهید',
			'videoControls.searchLanguages' => 'زبان های جستجو...',
			'videoControls.skipIntro' => 'کشتی وارد',
			'videoControls.skipCredits' => 'کپی اعتبارات',
			'videoControls.nextEpisode' => 'قسمت بعد',
			'videoControls.subtitleTrack' => ({required Object n}) => 'تریلر ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => 'زیرنویس ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (مجاز)',
			'videoControls.osdSubtitlesOff' => 'بایگانی برچسب ها: Off',
			'videoControls.osdSubtitles' => ({required Object track}) => 'برچسب ها: ${track}',
			'videoControls.osdAudio' => ({required Object track}) => 'صدا : ${track}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} فریم', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} فریم', ), 
			'videoControls.trackSelectionTitle' => 'انتخاب مسیر قبل از بازی',
			'videoControls.trackSelectionAuto' => 'انتخاب اتوماتیک',
			'videoControls.openMiniPlayer' => 'باز کردن مینی بازیکن',
			'videoControls.returnToFullPlayer' => 'بازگشت به بازیکن کامل',
			'videoControls.loadSubtitleFile' => 'دانلود فایل زیرنویس',
			'videoControls.subtitleLoadFailed' => 'دانلود فایل زیرنویس',
			'videoControls.skipAds' => 'آگهی های اسکایپ',
			'videoControls.tapToUnlock' => 'برای باز کردن قفل ضربه بزنید',
			'videoControls.tapAgainToUnlock' => 'برای باز کردن قفل دوباره ضربه بزنید',
			'messages.markedAsWatched' => 'مشخص شده به عنوان مشاهده شده',
			'messages.markedAsUnwatched' => 'برچسب ها: ناشناخته',
			'messages.markedAsWatchedOffline' => 'برچسب گذاری شده به عنوان مشاهده شده (در هنگام همگام سازی آنلاین)',
			'messages.markedAsUnwatchedOffline' => 'علامت گذاری شده به عنوان ناشناخته (در هنگام آنلاین همگام می شود)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'اتوماتیک حذف: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} دانلود تماشاشده به‌طور خودکار حذف شد', other: 'دانلود رایگان دانلود رایگان دانلود رایگان دانلود رایگان ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}', ), 
			'messages.removedFromContinueWatching' => 'حذف از ادامه مشاهده',
			'messages.errorLoading' => ({required Object error}) => 'خطا : ${error}',
			'messages.searchPartialResults' => 'برخی از سرورهای رسانه ای نمی توانستند جستجو شوند نمایش نتایج در دسترس.',
			'messages.streamInterrupted' => 'جریان متوقف شده است.بازی مطبوعاتی یا تلاش برای عقب نشینی.',
			'messages.liveStreamInterrupted' => 'پخش زنده متوقف شد پخش مطبوعات به عقب نشینی.',
			'messages.fileInfoNotAvailable' => 'اطلاعات فایل در دسترس نیست',
			'messages.playbackAuthenticationRequired' => 'دوباره وارد سرور رسانه ها شوید تا این آیتم را بازی کنید.',
			'messages.playbackServerUnavailable' => 'سرور رسانه ای در دسترس نیست، بعدا دوباره امتحان کنید.',
			'messages.playbackDataInvalid' => 'سرور اطلاعات بازگردانی نادرست را بازگرداند.',
			'messages.playbackCancelled' => 'Playback لغو شد',
			'messages.playbackFailed' => 'بازی باز نمی تواند آغاز شود.',
			'messages.playbackFailedDetail' => ({required Object error}) => 'بازی باز نمی تواند شروع شود: ${error}',
			'messages.audioOutputFailed' => 'اتصال صوتی تلویزیون یا گیرنده را بررسی کنید؛ اگر برنامه های دیگر صدا ندارند، دستگاه را دوباره راه اندازی کنید.',
			'messages.mediaUnavailable' => 'این محتوا دیگر در دسترس نیست.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'خطای بارگذاری فایل اطلاعات: ${error}',
			'messages.errorLoadingSeries' => 'خطای شارژ سری',
			'messages.musicNotSupported' => 'پخش موسیقی هنوز پشتیبانی نشده است',
			'messages.noDescriptionAvailable' => 'هیچ توضیحی در دسترس نیست',
			'messages.noProfilesAvailable' => 'هیچ پروفایل در دسترس',
			'messages.contactAdminForProfiles' => 'تماس با مدیر سرور برای اضافه کردن پروفایل ها',
			'messages.unableToDetermineLibrarySection' => 'نمی توانم بخش کتابخانه را برای این موضوع تعیین کنم',
			'messages.logsCleared' => 'دایره ها پاک شد',
			'messages.logsCopied' => 'کپی شده به clipboard',
			'messages.noLogsAvailable' => 'بدون سوابق موجود',
			'messages.libraryScanning' => ({required Object title}) => 'اسکن «${title}»',
			'messages.libraryScanStarted' => ({required Object title}) => 'کتابخانه اسکن برای "${title}" آغاز شد',
			'messages.libraryScanFailed' => ({required Object error}) => 'کتابخانه را اسکن نکرد: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'فتوشاپ با «${title}»',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'بازسازی داده های متا برای "${title}" آغاز شد',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'عدم بازسازی داده های متا: ${error}',
			'messages.logoutConfirm' => 'آیا مطمئن هستید که می خواهید خارج شوید؟',
			'messages.noSeasonsFound' => 'هیچ فصل یافت نشد',
			'messages.seasonsLoadFailed' => 'نمی توان فصل ها را بارگذاری کرد',
			'messages.noEpisodesFound' => 'هیچ قسمت در فصل اول یافت نشد',
			'messages.noEpisodesFoundGeneral' => 'هیچ حوادث یافت نشد',
			'messages.episodesLoadFailed' => 'نمی توانم قسمت ها را شارژ کنم',
			'messages.noResultsFound' => 'نتیجه‌ای یافت نشد.',
			'messages.sleepTimerSet' => ({required Object label}) => 'زمان خواب برای ${label} تنظیم شده است',
			'messages.noItemsAvailable' => 'هیچ آیتم در دسترس نیست',
			'messages.failedToCreatePlayQueueNoItems' => 'شکست در ایجاد یک قفسه بازی - هیچ آیتم',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'شکست خورده به ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'تغییر به یک بازیکن سازگار',
			'messages.serverLimitTitle' => 'بازی شکست خورده',
			'messages.serverLimitBody' => 'خطای سرور (HTTP 500) یک محدودیت پهنای باند / ترانسکود احتمالا این جلسه را رد کرده است.',
			'messages.mediaUnreadableTitle' => 'فایلهای غیر قابل دسترس',
			'messages.mediaUnreadableBody' => 'سرور این آیتم را پیدا کرد اما نمی توانست فایل آن را بخواند (HTTP 404). فایل احتمالا منتقل شده، حذف شده یا ذخیره آن غیرفعال است.',
			'messages.serverBusyTitle' => 'جریان در دسترس نیست',
			'messages.serverBusyBody' => 'سرور از پخش این فایل امتناع کرد (HTTP 503). ممکن است دوباره راه اندازی شود، شلوغ باشد، یا ذخیره سازی فایل ممکن است آفلاین باشد. دوباره در یک لحظه امتحان کنید - اگر این اتفاق می افتد، از صاحب سرور بخواهید که سرور و ذخیره سازی فایل را بررسی کند.',
			'messages.playbackNotAllowedTitle' => 'Playback مجاز نیست',
			'messages.playbackNotAllowedBody' => 'سرور از پخش این مورد خودداری کرد (HTTP 403). ممکن است حساب شما مجوز پخش آن را نداشته باشد، یا سرور فقط در شبکهٔ محلی خود اجازهٔ پخش بدهد.',
			'messages.logsUploaded' => 'Logs بارگذاری',
			'messages.logsUploadFailed' => 'شکست در بارگذاری مجلات',
			'messages.logId' => 'ID ثبت نام',
			'messages.burnedSubtitlesUseMenu' => 'زیرنویس ها در این جریان سوزانده می شوند. آنها را از منوی زیرنویس تغییر دهید.',
			'messages.noVideoUrl' => 'هیچ URL ویدئویی در دسترس نیست',
			'messages.playbackNoMediaSources' => 'سرور هیچ منبع پخش رسانه ای را بازگرداند',
			'messages.playbackDataNotPrepared' => 'Playback قبل از اینکه داده های آن آماده باشد آغاز شد.',
			'messages.streamSelectionUnavailable' => 'انتخاب جریان برای این منبع در دسترس نیست',
			'messages.streamSelectionFailed' => 'امکان استفاده از جریان های انتخاب شده',
			'messages.trackSelectionNotRemembered' => 'این گزینه فقط برای بازی های فعلی اعمال می شود.',
			'messages.serverUnavailableForProfile' => 'هیچ سرور برای پروفایل فعال در دسترس نیست',
			'subtitlingStyling.previewSample' => 'فاکس قهوه ای سریع بر روی سگ خجالتی پرش می کند',
			'subtitlingStyling.text' => 'متن',
			'subtitlingStyling.border' => 'مرزها',
			'subtitlingStyling.background' => 'پس زمینه',
			'subtitlingStyling.fontSize' => 'حجم فونت',
			'subtitlingStyling.textColor' => 'رنگ متن',
			'subtitlingStyling.borderSize' => 'مرز اندازه',
			'subtitlingStyling.borderColor' => 'مرز رنگ',
			'subtitlingStyling.backgroundOpacity' => 'پس زمینه نابخردی',
			'subtitlingStyling.backgroundColor' => 'رنگ پس زمینه',
			'subtitlingStyling.position' => 'موقعیت',
			'subtitlingStyling.assOverride' => 'ASS بیش از حد',
			'subtitlingStyling.overrideScale' => 'مقیاس',
			'subtitlingStyling.overrideForce' => 'نیروی',
			'subtitlingStyling.overrideStrip' => 'حذف سبک',
			'subtitlingStyling.positionTop' => 'بالا',
			'subtitlingStyling.positionBottom' => 'پایین',
			'subtitlingStyling.useMargins' => 'استفاده از مارجین',
			'subtitlingStyling.useMarginsDescription' => 'اجازه دهید زیرنویس های متنی در فضای خارج از ویدئو قرار بگیرند. زیرنویس های سبک می توانند موقعیت اصلی خود را حفظ کنند.',
			'subtitlingStyling.anchorToScreen' => 'آکاایران به صفحه نمایش',
			'subtitlingStyling.anchorToScreenDescription' => 'نمایش زیرنویس های متن در نوار سیاه زیر ویدئو صفحه نمایش',
			'subtitlingStyling.bold' => 'درشت',
			'subtitlingStyling.italic' => 'ایتالیایی',
			'subtitlingStyling.renderResolution' => 'رندر حل',
			'subtitlingStyling.renderResolutionScreen' => 'صفحه نمایش رزولوشن',
			'subtitlingStyling.renderResolutionVideo' => 'کیفیت ویدیو',
			'subtitlingStyling.fontSizeDescription' => 'اندازه زیرنویس متن را در این دستگاه تنظیم کنید.',
			'subtitlingStyling.textColorDescription' => 'رنگ مورد استفاده برای زیرنویس را انتخاب کنید.',
			'subtitlingStyling.borderSizeDescription' => 'ضخامت خروجی را در اطراف متن زیرنویس تنظیم کنید.',
			'subtitlingStyling.borderColorDescription' => 'رنگ مورد استفاده برای زیرنویس را انتخاب کنید.',
			'subtitlingStyling.backgroundColorDescription' => 'رنگ پشت زیرنویس را انتخاب کنید.',
			'subtitlingStyling.backgroundOpacityDescription' => 'تنظیم چگونگی شفاف بودن پس زمینه زیرنویس: 0٪ روشن است و 100٪ جامد است.',
			'subtitlingStyling.positionDescription' => 'زیرنویس ها را به صورت عمودی حرکت دهید 0٪ در بالای ویدئو و 100٪ در پایین است.',
			'subtitlingStyling.assOverrideDescription' => 'انتخاب کنید که آیا بازیکن به دنبال، تنظیم، جایگزین و یا حذف سبک در زیرنویس های ASS.',
			'subtitlingStyling.assOverrideOptions.no' => 'حروف، رنگ ها، اندازه ها و قرار دادن نوشته شده را در فایل زیر عنوان نگه دارید.',
			'subtitlingStyling.assOverrideOptions.yes' => 'اجازه دهید تنظیمات سبک زیر عنوان بازیکن برای تنظیم زیر عنوان ASS.',
			'subtitlingStyling.assOverrideOptions.scale' => 'استفاده از سبک بازیکن و مقیاس اندازه های ساخته شده برای مطابقت با ابعاد ویدئو.',
			'subtitlingStyling.assOverrideOptions.force' => 'سبک های ASS را با سبک زیرنویس بازیکن جایگزین کنید.',
			'subtitlingStyling.assOverrideOptions.strip' => 'حذف فرمت ASS ساخته شده و متن زیرنویس را به وضوح انجام دهید.',
			'subtitlingStyling.renderResolutionDescription' => 'رزولوشن مورد استفاده برای rasterize تصویر و ASS زیرنویس ها را انتخاب کنید مقیاس های اندروید پایین تر می تواند کار راندینگ را کاهش دهد اما نرم تر به نظر می رسد.',
			'subtitlingStyling.renderResolutionOptions.screen' => 'رندر در رزولوشن کامل صفحه نمایش برای سریع ترین نتیجه.',
			'subtitlingStyling.renderResolutionOptions.video' => 'رندر با استفاده از رزولوشن ویدئویی به عنوان مرجع، که می تواند کار بر روی صفحه نمایش های رزولوژیکی بالا را کاهش دهد.',
			'subtitlingStyling.renderResolutionOptions.threeQuarter' => 'رندر در 75٪ از رزولوشن سطح نمایش برای صرفه جویی در عملکرد خفیف.',
			'subtitlingStyling.renderResolutionOptions.half' => 'رندر در 50٪ از رزولوشن سطح نمایش برای کاهش کار، با لبه های نرم تر.',
			'subtitlingStyling.renderResolutionOptions.third' => 'رندر در یک سوم از رزولوشن سطح نمایش برای کاهش کار، با لبه های نرم تر.',
			'subtitlingStyling.renderResolutionOptions.quarter' => 'رندر در یک چهارم از رزولوشن سطح صفحه نمایش برای کاهش کار، با نرم ترین نتیجه.',
			'subtitlingStyling.boldDescription' => 'متن زیرنویس را در وزن سنگین تر بشویید.',
			'subtitlingStyling.italicDescription' => 'متن زیرنویس را در ایتالیایی بنویسید.',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'تنظیمات پیشرفته پخش ویدئو',
			'mpvConfig.presets' => 'پیشگویی',
			'mpvConfig.noPresets' => 'هیچ پیشگویی نجات یافت',
			'mpvConfig.saveAsPreset' => 'به عنوان پیش بینی...',
			'mpvConfig.presetName' => 'نام پیشین',
			'mpvConfig.presetNameHint' => 'یک نام برای این پیش فرض وارد کنید.',
			'mpvConfig.loadPreset' => 'بارگذاری',
			'mpvConfig.deletePreset' => 'حذف',
			'mpvConfig.presetSaved' => 'پیشگام نجات یافت',
			'mpvConfig.presetLoaded' => 'پیش فرض بارگذاری',
			'mpvConfig.presetDeleted' => 'پیش بینی حذف',
			'mpvConfig.confirmDeletePreset' => 'آیا مطمئن هستید که می خواهید این پیش فرض را حذف کنید؟',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan hwdec=auto # نظرات',
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => 'اضافه کردن خط',
			'mpvConfig.removeLine' => 'حذف خط',
			'mpvConfig.embeddedVoHint' => 'vo، gpu-context و gpu-api در Linux نادیده گرفته می شود: ویدئو درخشان همیشه از طریق vo=libmpv در برنامه ویدئویی پخش می شود و gpu-next (که سایه های محاسباتی مانند ArtCNN نیاز دارد) نمی تواند درخشان اجرا شود.',
			'dialog.confirmAction' => 'تأیید عمل',
			'profiles.addPlezyProfile' => 'اضافه کردن پروفایل PlezyNG',
			'profiles.switchingProfile' => 'تغییر پروفایل...',
			'profiles.deleteThisProfileTitle' => 'این پروفایل را حذف کنید؟',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'حذف ${displayName}. اتصالات تحت تاثیر قرار نمی گیرد.',
			'profiles.active' => 'فعال',
			'profiles.manage' => 'مدیریت',
			'profiles.delete' => 'حذف',
			'profiles.signOut' => 'خارج شدن',
			'profiles.signOutPlexTitle' => 'ثبت نام از Plex؟',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'حذف ${displayName} و همه Plex کاربران خانگی؟ ثبت نام در هر زمان.',
			'profiles.signOutPlexDeleteDownloads' => 'همچنین دانلود دانلود ها',
			'profiles.signOutPlexDeleteDownloadsDescription' => 'در غیر این صورت آنها در این دستگاه باقی می مانند و زمانی که شما دوباره وارد این حساب می شوید، باز می گردند.',
			'profiles.signedOutPlex' => 'ثبت شده از Plex.',
			'profiles.signOutFailed' => 'ثبت نام شکست خورده',
			'profiles.sectionTitle' => 'پروفایل ها',
			'profiles.summarySingle' => 'اضافه کردن پروفایل ها برای مخلوط کردن کاربران مدیریت شده و هویت های محلی',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} پروفایل · فعال: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} مشخصات',
			'profiles.removeConnectionTitle' => 'اتصال را حذف کنید؟',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'حذف دسترسی ${displayName} به ${connectionLabel}. پروفایل های دیگر آن را نگه دارید.',
			'profiles.deleteProfileTitle' => 'پروفایل را حذف کنید؟',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'حذف ${displayName} و اتصالات آن. سرورها در دسترس باقی می ماند.',
			'profiles.profileNameLabel' => 'نام پروفایل',
			'profiles.pinProtectionLabel' => 'حفاظت PIN',
			'profiles.copyAutomationLink' => 'کپی Android اتوماسیون لینک',
			'profiles.copyAutomationLinkDescription' => 'این پروفایل را از یک هدف یا اتوماسیون Android انتخاب کنید.پروفیل PIN چک ها هنوز هم اعمال می شود.',
			'profiles.automationLinkCopied' => 'پروفایل اتوماسیون لینک کپی شده',
			'profiles.pinManagedByPlex' => 'PIN مدیریت شده توسط Plex. Edit on plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'برای نیاز به یک، ویرایش کاربر خانگی در plex.tv.',
			'profiles.setPin' => 'PIN را تنظیم کنید',
			'profiles.setPinTitle' => 'PIN را تنظیم کنید',
			'profiles.confirmPinTitle' => 'تایید PIN',
			'profiles.pinSet' => 'PIN تنظیم شده',
			'profiles.changePin' => 'تغییر',
			'profiles.removePin' => 'حذف',
			'profiles.connectionsLabel' => 'ارتباطات',
			'profiles.add' => 'افزودن',
			'profiles.deleteProfileButton' => 'حذف پروفایل',
			'profiles.noConnectionsHint' => 'هیچ اتصال - اضافه کردن یکی برای استفاده از این پروفایل.',
			'profiles.noConnections' => 'هیچ ارتباطی',
			'profiles.plexHomeAccount' => 'Plex حساب خانگی',
			'profiles.plexAccountChip' => ({required Object account}) => 'Plex حساب: ${account}',
			'profiles.plexAccountUserChip' => ({required Object user, required Object account}) => '${user} از طریق ${account}',
			'profiles.connectionDefault' => 'پیشفرض',
			'profiles.connectionAs' => ({required Object displayName}) => 'به عنوان ${displayName}',
			'profiles.makeDefault' => 'فایرفاکس',
			'profiles.removeConnection' => 'حذف',
			'profiles.profileRenamed' => 'نام پروفایل',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'اضافه کردن به ${displayName}',
			'profiles.borrowExplain' => 'وام دادن به یک پروفایل دیگر. پروفایل های محافظت شده از PIN نیاز به یک PIN.',
			'profiles.borrowEmpty' => 'هنوز چیزی برای وام گرفتن ندارم.',
			'profiles.borrowEmptySubtitle' => 'برای اولین بار Plex، Jellyfin یا Emby را به یک پروفایل دیگر متصل کنید.',
			'profiles.borrowLoadFailed' => 'اتصالات در دسترس نمی توانند بارگذاری شوند. دوباره امتحان کنید.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'از ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'اتصال قرض گرفته شده است.',
			'profiles.borrowFailed' => 'وام گرفتن را شکست داد.',
			'profiles.incorrectPin' => 'PIN نادرست',
			'profiles.incorrectPinTryAgain' => 'PIN نادرست است لطفا دوباره امتحان کنید.',
			'profiles.sourceProfileMissingParentAccount' => 'منبع پروفایل خود را از دست داده است حساب مادر خود را.',
			'profiles.failedToLoadHomeUsers' => 'نمی توانم کاربران خانگی Plex خود را بارگذاری کنم. اتصال خود را بررسی کنید و دوباره امتحان کنید.',
			'profiles.failedToVerifyPin' => 'PIN را تایید نکردم',
			'profiles.newProfile' => 'پروفایل جدید',
			'profiles.profileNameHint' => 'به عنوان مثال: مهمانان، کودکان، اتاق های خانوادگی',
			'profiles.pinProtectionOptional' => 'حفاظت از PIN (اختیاری)',
			'profiles.pinExplain' => '4 عدد PIN برای تغییر پروفایل ها',
			'profiles.continueButton' => 'ادامه مطلب',
			'profiles.pinsDontMatch' => 'PIN ها مطابقت ندارند',
			'profiles.tokenIdentityMismatch' => 'سکه پروفایل Plex به یک سرور غیرمنتظره حل شد',
			'profiles.settingsLocked' => 'تنظیمات برای این پروفایل قفل شده است.',
			'profiles.unlockSettings' => 'تنظیمات Unlock',
			'profiles.showExploreForProfile' => 'نمایش جستجو برای این پروفایل',
			'profiles.showExploreForProfileDescription' => 'برای حذف Explore از ناوبری این پروفایل خاموش شوید.',
			'connections.sectionTitle' => 'ارتباطات',
			'connections.addConnection' => 'اضافه کردن اتصال',
			'connections.addConnectionSubtitleNoProfile' => 'با Plex وارد شوید یا به یک سرور Jellyfin یا Emby متصل شوید.',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'اضافه کردن به ${displayName}: Plex، Jellyfin، Emby، یا سایر لینک های پروفایل',
			'connections.sessionExpiredOne' => ({required Object name}) => 'تاریخ انقضا برای ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'جلسه برای سرورهای ${count} به پایان رسید',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} دسترسی به این حساب را رد کرد',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} سرورها دسترسی به این حساب را رد کردند',
			'connections.signInAgain' => 'دوباره وارد شوید',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'ویرایش ${product} اتصال',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'اضافه کردن یا حذف URL برای ${serverName}. PlezyNG از URL قابل دسترسی با پایین ترین تاخیر استفاده می کند.',
			'accountPreferences.sectionTitle' => 'حسابداری ترجیحات',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => 'گزینه های صوتی، زیرنویس و کتابخانه در ${account} ذخیره شده است',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => 'گزینه های صوتی، زیرنویس و کتابخانه در حساب های ${count} ذخیره شده است',
			'accountPreferences.pickAccount' => 'هر حساب ذخیره ترجیحات خود را. انتخاب یکی برای ویرایش.',
			'accountPreferences.storedOnAccount' => 'این گزینه ها در حساب خود ذخیره می شوند، بنابراین هر اپلیکیشن ثبت نام شده در آن از آنها استفاده می کند – از جمله PlezyNG در سایر دستگاه های شما.',
			'accountPreferences.noAccounts' => 'هیچ حساب برای تنظیم',
			'accountPreferences.noAccountsHint' => 'ثبت نام در Plex یا اتصال به یک سرور Jellyfin یا Emby، و ترجیحات ذخیره شده در آن حساب در اینجا نشان داده شده است.',
			'accountPreferences.unavailable' => 'نمی توانم به این حساب دسترسی داشته باشم',
			'accountPreferences.loadFailed' => 'نمی توانم این ترجیحات را بارگذاری کنم',
			'accountPreferences.noPreference' => 'هیچ ترجیح',
			'accountPreferences.notSet' => 'نه تنظیم',
			'accountPreferences.groups.audioAndSubtitles' => 'صدا و زیرنویس',
			'accountPreferences.groups.libraryDisplay' => 'کتابخانه',
			'accountPreferences.groups.personalMedia' => 'رسانه های شخصی',
			'accountPreferences.preferredAudioLanguage' => 'اولویت زبان صدا',
			'accountPreferences.autoSelectAudio' => 'صدا را با زبان انتخاب کنید',
			'accountPreferences.autoSelectAudioDescription' => 'حذف هر گونه ردیابی صوتی فایل به عنوان پیش فرض نشان داده شده است.',
			'accountPreferences.preferredSubtitleLanguage' => 'زبان زیرنویس ترجیحی',
			'accountPreferences.subtitleMode' => 'زیرنویس ها را روی',
			'accountPreferences.subtitleModes.none' => 'انتخاب دستی',
			'accountPreferences.subtitleModes.noneDescription' => 'هرگز زیرنویس ها را به خودی خود تغییر ندهید.',
			'accountPreferences.subtitleModes.defaultMode' => 'ردیابی پرچم های مسیر',
			'accountPreferences.subtitleModes.defaultModeDescription' => 'از پرچم های پیش فرض و اجباری ذخیره شده در هر ردیف زیر عنوان استفاده کنید.',
			'accountPreferences.subtitleModes.always' => 'همیشه امکان پذیر',
			'accountPreferences.subtitleModes.alwaysDescription' => 'هر زمان که یک زیرنویس در زبان مورد علاقه وجود داشته باشد بر روی یک زیرنویس حرکت کنید.',
			'accountPreferences.subtitleModes.onlyForced' => 'فقط زیرنویس های اجباری',
			'accountPreferences.subtitleModes.onlyForcedDescription' => 'فقط مسیرهای مشخص شده به عنوان اجباری را بارگذاری کنید.',
			'accountPreferences.subtitleModes.smart' => 'نمایش با صدا خارجی',
			'accountPreferences.subtitleModes.smartDescription' => 'زیرنویس ها را فقط هنگامی که صدا در زبان دیگری قرار دارد بر روی آن قرار دهید.',
			'accountPreferences.subtitleAccessibility' => 'SDH زیرنویس',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'ترجیح دادن زیرنویس های غیر SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'ترجیح دادن زیرنویس های SDH',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'فقط زیرنویس های SDH',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'فقط زیرنویس های غیر SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdhDescription' => 'ترجیح می دهم زیرنویس های استاندارد زمانی که هر دو نسخه استاندارد و SDH در دسترس هستند.',
			'accountPreferences.subtitleAccessibilityOptions.preferSdhDescription' => 'ترجیح می دهم زیرنویس های SDH زمانی که در دسترس هستند، اما اجازه می دهد تا زیرنوی استاندارد به عنوان یک سقوط.',
			'accountPreferences.subtitleAccessibilityOptions.onlySdhDescription' => 'فقط از زیرنویس های SDH استفاده کنید؛ به زیرنوی استاندارد برگردید.',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdhDescription' => 'فقط از زیرنویس های استاندارد استفاده کنید؛ زیرنوی SDH را حذف کنید.',
			'accountPreferences.forcedSubtitles' => 'زیرنویس های اجباری',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'ترجیح دادن زیرنویس های غیرقانونی',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'ترجیح می دهم زیرنویس های اجباری',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'فقط زیرنویس های اجباری',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'فقط زیرنویس های غیر اجباری',
			'accountPreferences.forcedSubtitleOptions.preferNonForcedDescription' => 'ترجیح می دهم زیرنویس های منظم، اما اجازه می دهد تا مسیرهای اجباری به عنوان یک سقوط.',
			'accountPreferences.forcedSubtitleOptions.preferForcedDescription' => 'ترجیح می دهم مسیرهای اجباری زمانی که در دسترس است، اما اجازه می دهد تا زیرنویس های منظم به عنوان یک عقب نشینی.',
			'accountPreferences.forcedSubtitleOptions.onlyForcedDescription' => 'استفاده فقط از مسیرهای مشخص شده به عنوان اجباری.',
			'accountPreferences.forcedSubtitleOptions.onlyNonForcedDescription' => 'ردیاب ها به عنوان اجباری مشخص شده است.',
			'accountPreferences.displayMissingEpisodes' => 'نمایش قسمت های ناپدید شده',
			'accountPreferences.displayMissingEpisodesDescription' => 'قسمت های لیست که سرور در مورد آن می داند اما هیچ فایل برای آن ندارد.',
			'accountPreferences.hidePlayedInLatest' => 'پنهان کردن اشیاء مشاهده شده در آخرین',
			'accountPreferences.hidePlayedInLatestDescription' => 'آیتم هایی را که قبلاً مشاهده کرده اید از آخرین ردیف های سرور خارج کنید.',
			'accountPreferences.displayCollectionsView' => 'نمایش نمایش مجموعه ها',
			'accountPreferences.displayCollectionsViewDescription' => 'نمایش مجموعه های سرور را در کنار کتابخانه های خود ارائه دهید.',
			'accountPreferences.rewatchingInNextUp' => 'ادامه مطلب ادامه مطلب ادامه مطلب ادامه مطلب',
			'accountPreferences.rewatchingInNextUpDescription' => 'هنگامی که یک نمایش را به پایان می رسانید، آن را دوباره شروع کنید و Next Up به جای اینکه نمایش را از بین ببرد، نظارت را دنبال می کند.',
			'accountPreferences.watchedIndicator' => 'شاخص های مشاهده شده',
			'accountPreferences.watchedIndicatorOptions.none' => 'هرگز',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => 'فیلم ها و نمایش های تلویزیونی',
			'accountPreferences.watchedIndicatorOptions.movies' => 'فقط فیلم ها',
			'accountPreferences.watchedIndicatorOptions.shows' => 'نمایش های تلویزیونی فقط',
			'accountPreferences.watchedIndicatorOptions.noneDescription' => 'چک های مشاهده شده را نشان ندهید.',
			'accountPreferences.watchedIndicatorOptions.moviesAndShowsDescription' => 'نمایش چک های تماشا شده برای فیلم ها و برنامه های تلویزیونی.',
			'accountPreferences.watchedIndicatorOptions.moviesDescription' => 'نشان دادن چک های مشاهده شده فقط برای فیلم ها.',
			'accountPreferences.watchedIndicatorOptions.showsDescription' => 'نمایش شاخص های تماشا شده فقط برای برنامه های تلویزیونی.',
			'accountPreferences.mediaReviewsVisibility' => 'رتبه بندی و بررسی',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'کاربران و منتقدان',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'فقط کاربران',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'انتقاد فقط',
			'accountPreferences.mediaReviewsOptions.nobody' => 'پنهان',
			'accountPreferences.mediaReviewsOptions.usersAndCriticsDescription' => 'نشان دادن هر دو رتبه بندی کاربران و رتبه های انتقادی.',
			'accountPreferences.mediaReviewsOptions.usersOnlyDescription' => 'رتبه بندی ها و نظرات ارائه شده توسط کاربران را نشان دهید.',
			'accountPreferences.mediaReviewsOptions.criticsOnlyDescription' => 'بررسی ها و ارزیابی های انتقادی را نشان دهید.',
			'accountPreferences.mediaReviewsOptions.nobodyDescription' => 'پنهان کردن امتیازات و بررسی ها.',
			'accountPreferences.preferredAudioLanguageDescription' => 'ترجیح می دهم ردیف های صوتی در این زبان زمانی که سرور یا پخش کننده به طور خودکار یک ردیف را انتخاب می کند.',
			'accountPreferences.preferredSubtitleLanguageDescription' => 'ترجیح می دهم زیرنویس ها را در این زبان ردیابی کنید، زمانی که زیرنوی ها به طور خودکار انتخاب می شوند.',
			'accountPreferences.subtitleAccessibilityDescription' => 'انتخاب کنید که آیا پوشش های SDH ترجیح داده شده یا مورد نیاز در هنگام انتخاب زیرنویس خودکار است.',
			'accountPreferences.forcedSubtitleDescription' => 'انتخاب کنید که آیا ردیف های زیر عنوان اجباری ترجیح داده شده یا مورد نیاز در هنگام انتخاب اتوماتیک است.',
			'accountPreferences.watchedIndicatorDescription' => 'انتخاب کنید که کدام نوع رسانه ها یک علامت چک مشاهده شده را در رابط سرور دریافت می کنند.',
			'accountPreferences.mediaReviewsVisibilityDescription' => 'انتخاب کنید که کدام مخاطبان و رتبه های انتقادی سرور در صفحات رسانه ها نمایش داده می شود.',
			'accountPreferences.subtitleModeDescription' => 'انتخاب زمانی که زیرنویس ها به طور خودکار برای این حساب سرور فعال می شوند.',
			'accountPreferences.hubDescription' => 'این ترجیحات در حساب سرور رسانه شما ذخیره می شوند و ممکن است برای سایر مشتریان نیز اعمال شود.',
			'discover.title' => 'کشف',
			'discover.noContentAvailable' => 'بدون محتوای موجود',
			'discover.addMediaToLibraries' => 'برخی از رسانه ها را به کتابخانه های خود اضافه کنید',
			'discover.continueWatching' => 'ادامه تماشا',
			'discover.continueWatchingIn' => ({required Object library}) => 'ادامه مشاهده در ${library}',
			'discover.nextUp' => 'بعدی چیه',
			'discover.nextUpIn' => ({required Object library}) => 'بعدی در ${library}',
			'discover.recentlyAdded' => 'جدیدترین‌ها',
			'discover.recentlyAddedIn' => ({required Object library}) => 'به تازگی در ${library} اضافه شده است',
			'discover.latestAlbumsIn' => ({required Object library}) => 'آخرین آلبوم ها در ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'بازی شده در ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'بیشترین تعداد بازی ها در ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'ف${season} ق${episode}',
			'discover.overview' => 'نمای کلی',
			'discover.cast' => 'کاست',
			'discover.findNext.title' => 'انتخاب بعدی‌تان را پیدا کنید',
			'discover.findNext.open' => 'انتخاب بعدی‌تان را پیدا کنید',
			'discover.findNext.anyTime' => 'بدون محدودیت زمانی',
			'discover.findNext.timeAvailable' => 'چقدر وقت دارید؟',
			'discover.findNext.filters' => 'برای این لحظه انتخاب کنید',
			'discover.findNext.watch' => 'تماشا',
			'discover.findNext.listen' => 'گوش دادن',
			'discover.findNext.read' => 'خواندن',
			'discover.findNext.finishable' => ({required Object duration}) => 'قابل اتمام در ${duration}',
			'discover.findNext.aboutDuration' => ({required Object duration}) => 'حدود ${duration}',
			'discover.findNext.nextUnit' => ({required Object duration}) => 'فصل بعدی · ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => 'در مجموع ${duration}',
			'discover.findNext.timingVaries' => 'مدت‌زمان متفاوت است',
			'discover.findNext.notNow' => 'الان نه',
			'discover.findNext.swipeHint' => 'جلد را به سمت یکی از پیکان‌ها بکشید یا از دکمه‌های زیر استفاده کنید.',
			'discover.findNext.saved' => 'پیشنهادهای ذخیره‌شده',
			'discover.findNext.savedCount' => ({required Object count}) => 'پیشنهادهای ذخیره‌شده · ${count}',
			'discover.findNext.undo' => 'واگرد',
			'discover.findNext.details' => 'جزئیات',
			'discover.findNext.noPicks' => 'هنوز چیزی برای انتخاب وجود ندارد',
			'discover.findNext.noPicksHint' => 'برای شروع، یک کتابخانه متصل کنید یا یک منبع رسانه اضافه کنید.',
			'discover.findNext.noMatches' => 'چیزی مناسب این لحظه پیدا نشد',
			'discover.findNext.noMatchesHint' => 'نوع دیگری از رسانه را امتحان کنید یا زمان بیشتری در نظر بگیرید.',
			'discover.findNext.allDone' => 'همهٔ پیشنهادها را دیدید',
			'discover.findNext.allDoneHint' => 'برای دیدن دوبارهٔ این گزینه‌ها، مجموعهٔ تازه‌ای از پیشنهادها را شروع کنید.',
			'discover.findNext.refresh' => 'پیشنهادهای دیگری پیدا کنید',
			'discover.findNext.sourceReason' => ({required Object source}) => 'از ${source}',
			'discover.findNext.libraryReason' => ({required Object library}) => 'از ${library}',
			'discover.findNext.ownedReason' => 'از کتابخانهٔ شما',
			'discover.findNext.liveNow' => 'در حال پخش',
			'discover.findNext.watchLive' => 'تماشای زنده',
			'discover.findNext.filterAnything' => 'هر نوعی',
			'discover.findNext.filterWatch' => 'تماشا',
			'discover.findNext.filterListen' => 'گوش دادن',
			'discover.findNext.filterRead' => 'خواندن',
			'discover.findNext.twentyMinutes' => '۲۰ دقیقه',
			'discover.findNext.fortyFiveMinutes' => '۴۵ دقیقه',
			'discover.findNext.ninetyMinutes' => '۹۰ دقیقه',
			'discover.findNext.apply' => 'اعمال',
			'discover.findNext.openFailed' => 'این گزینه دیگر در دسترس نیست. برای بررسی دوباره، تازه‌سازی کنید.',
			'discover.findNext.changeFailed' => 'این تغییر ذخیره نشد. دوباره تلاش کنید.',
			'discover.findNext.savedLimit' => 'فهرست پیشنهادهای ذخیره‌شده پر است. برای ذخیرهٔ پیشنهادی دیگر، یکی را حذف کنید.',
			'discover.findNext.chooseHint' => 'عنوانی را باز کنید، برای بعد ذخیره کنید یا از آن بگذرید.',
			'discover.findNext.howItWorks' => 'روش استفاده',
			'discover.findNext.notNowHelp' => 'فعلاً از این عنوان بگذرید. در کتابخانه شما باقی می‌ماند.',
			'discover.findNext.saveHelp' => 'آن را در انتخاب‌های ذخیره‌شده این نمایه روی این دستگاه نگه دارید. ذخیره کردن باعث دانلود نمی‌شود.',
			'discover.findNext.openHelp' => 'برای دیدن جزئیات، جلد را انتخاب کنید. از دکمه اصلی برای پخش، خواندن یا باز کردن عنوان استفاده کنید.',
			'discover.findNext.controlsHelp' => 'صفحه‌کلید یا کنترل: روی یک دکمه بروید و Enter یا دکمه انتخاب را بزنید. واگرد آخرین انتخاب شما را برمی‌گرداند.',
			'discover.findNext.artworkLoading' => 'در حال بارگیری تصویر…',
			'discover.findNext.artworkUnavailable' => 'تصویر در دسترس نیست',
			'discover.findNext.savedFeedback' => 'به انتخاب‌های ذخیره‌شده افزوده شد',
			'discover.findNext.skippedFeedback' => 'فعلاً رد شد',
			'discover.findNext.releaseToConfirm' => 'برای تأیید رها کنید',
			'discover.findNext.remoteHint' => 'با تمرکز روی جلد: ← / → انتخاب · دکمه انتخاب: جزئیات · ↑ / ↓ جابه‌جایی تمرکز',
			'discover.extras' => 'تریلر و اضافی',
			'discover.studio' => 'استودیو',
			'discover.rating' => 'رتبه بندی',
			'discover.director' => 'کارگردان',
			'discover.directors' => 'کارگردانان',
			'discover.movie' => 'فیلم',
			'discover.tvShow' => 'نمایش تلویزیونی',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} دقیقه باقی مانده',
			'discover.moreLikeThis' => 'موارد مشابه با این',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} عنوان', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} عنوان ها', ), 
			'discover.person.born' => 'متولد شد',
			'discover.person.died' => 'مرده',
			'discover.person.birthplace' => 'محل تولد',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date} (سن ${age})',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date} (سال ${age})',
			'errors.searchFailed' => ({required Object error}) => 'جستجو شکست خورده: ${error}',
			'errors.searchUnavailable' => 'جستجو نمی تواند به هیچ سرور رسانه ای دسترسی داشته باشد.',
			'errors.connectionTimeout' => ({required Object context}) => 'زمان اتصال در هنگام بارگذاری ${context}',
			'errors.connectionFailed' => 'عدم امکان اتصال به سرورهای رسانه ای',
			'errors.unableToLoad' => ({required Object context}) => 'قابل بارگذاری نیست ${context}.لطفا دوباره امتحان کنید.',
			'errors.noClientAvailable' => 'هیچ مشتری در دسترس نیست',
			'errors.pleaseEnterToken' => 'لطفا یک توکن وارد کنید.',
			'errors.invalidToken' => 'توکین نادرست',
			'errors.failedToVerifyToken' => ({required Object error}) => 'عدم تایید توکن: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'عدم تغییر به ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'حذف ناپذیر ${displayName}',
			'errors.failedToRate' => 'نمی توانم رتبه بندی را به روز کنم',
			'errors.reasonTimedOut' => 'اتصال به زمان مشخص شد',
			'errors.reasonUnreachable' => 'سرور نمی تواند به دست آورد',
			'errors.reasonRefused' => 'سرور درخواست را رد کرد',
			'errors.reasonNotFound' => 'در حال حاضر در سرور نیست.',
			'errors.reasonServerError' => 'سرور یک خطا را شناسایی کرد',
			'errors.reasonCancelled' => 'درخواست لغو شد',
			'errors.reasonUnexpected' => 'یک اشتباه غیرمنتظره رخ داد.',
			'libraries.playRandomMovie' => 'بازی یک فیلم تصادفی',
			'libraries.randomPickFailed' => 'من نمی توانم یک فیلم تصادفی را از این کتابخانه انتخاب کنم.',
			'libraries.title' => 'کتابخانه‌ها',
			'libraries.fallbackTitle' => 'کتابخانه',
			'libraries.scanLibraryFiles' => 'اسکن کتابخانه فایل ها',
			'libraries.scanLibrary' => 'کتابخانه را اسکن کنید',
			'libraries.analyze' => 'تحلیل',
			'libraries.analyzeLibrary' => 'تجزیه و تحلیل کتابخانه',
			'libraries.refreshMetadata' => 'تازه کردن متادیتا',
			'libraries.emptyTrash' => 'تریش خالی',
			'libraries.emptyingTrash' => ({required Object title}) => 'در این مطلب به نقل از «${title}» می پردازیم.',
			'libraries.trashEmptied' => ({required Object title}) => 'تریلر جدید «${title}»',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'ناپدید شدن زباله خالی: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'در این مقاله به بررسی «${title}» می پردازیم.',
			'libraries.analysisStarted' => ({required Object title}) => 'تحلیل برای "${title}" آغاز شد',
			'libraries.failedToAnalyze' => ({required Object error}) => 'عدم تحلیل کتابخانه: ${error}',
			'libraries.noLibrariesFound' => 'هیچ کتابخانه ای یافت نشد',
			'libraries.allLibrariesHidden' => 'همه کتابخانه ها پنهان هستند',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'کتابخانه های پنهان (${count})',
			'libraries.thisLibraryIsEmpty' => 'این کتابخانه خالی است',
			'libraries.noItemsMatchFilters' => 'هیچ محصولی با فیلترهای فعال مطابقت ندارد',
			'libraries.resetFilters' => 'بازسازی فیلترها',
			'libraries.all' => 'همه',
			'libraries.clearAll' => 'همه چیز روشن',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'آیا مطمئن هستید که می خواهید "${title}" را اسکن کنید؟',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'آیا مطمئن هستید که می خواهید "${title}" را تجزیه و تحلیل کنید؟',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'آیا مطمئن هستید که می خواهید داده های متا را برای "${title}" به روز کنید؟',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'آیا مطمئن هستید که می خواهید زباله خالی را برای "${title}" خالی کنید؟',
			'libraries.manageLibraries' => 'مدیریت کتابخانه ها',
			'libraries.sort' => 'مرتب سازی',
			'libraries.sortBy' => 'مسیر را انتخاب کنید',
			'libraries.filters' => 'صافی‌ها',
			'libraries.confirmActionMessage' => 'آیا مطمئن هستید که می خواهید این عمل را انجام دهید؟',
			'libraries.showLibrary' => 'نمایش کتابخانه',
			'libraries.hideLibrary' => 'کتابخانه پنهان',
			'libraries.libraryOptions' => 'گزینه های کتابخانه',
			'libraries.content' => 'محتوای کتابخانه',
			_ => null,
		} ?? switch (path) {
			'libraries.selectLibrary' => 'انتخاب کتابخانه',
			'libraries.filtersWithCount' => ({required Object count}) => 'فیلترها (${count})',
			'libraries.noRecommendations' => 'بدون توصیه در دسترس',
			'libraries.noCollections' => 'هیچ مجموعه ای در این کتابخانه وجود ندارد',
			'libraries.noFoldersFound' => 'هیچ پوشه ای یافت نشد',
			'libraries.folders' => 'پوشه‌ها',
			'libraries.tabs.recommended' => 'توصیه شده',
			'libraries.tabs.browse' => 'مرور کردن',
			'libraries.tabs.collections' => 'مجموعه‌ها',
			'libraries.tabs.playlists' => 'لیست‌های پخش',
			'libraries.groupings.title' => 'گروه بندی',
			'libraries.groupings.all' => 'همه',
			'libraries.groupings.movies' => 'فیلم ها',
			'libraries.groupings.shows' => 'تلویزیون نمایش',
			'libraries.groupings.seasons' => 'فصل ها',
			'libraries.groupings.episodes' => 'قسمت‌ها',
			'libraries.groupings.artists' => 'هنرمندان',
			'libraries.groupings.albums' => 'آلبوم‌ها',
			'libraries.groupings.tracks' => 'شیار',
			'libraries.groupings.folders' => 'پوشه‌ها',
			'libraries.filterCategories.genre' => 'ژانر',
			'libraries.filterCategories.year' => 'سال',
			'libraries.filterCategories.contentRating' => 'محتوای رتبه بندی',
			'libraries.filterCategories.tag' => 'برچسب',
			'libraries.filterCategories.unwatched' => 'ناشناخته',
			'libraries.filterCategories.unplayed' => 'پخش نشده',
			'libraries.filterCategories.favorites' => 'مورد علاقه‌ها',
			'libraries.filterCategories.filePath' => 'فایل مسیر',
			'libraries.sortLabels.title' => 'عنوان',
			'libraries.sortLabels.dateAdded' => 'تاریخ اضافه شده',
			'libraries.sortLabels.releaseDate' => 'تاریخ انتشار',
			'libraries.sortLabels.rating' => 'رتبه بندی',
			'libraries.sortLabels.communityRating' => 'امتیاز عمومی',
			'libraries.sortLabels.criticRating' => 'رتبه بندی انتقادی',
			'libraries.sortLabels.userRating' => 'رتبه بندی کاربر',
			'libraries.sortLabels.datePlayed' => 'تاریخ پخش شده',
			'libraries.sortLabels.playCount' => 'تعداد پخش',
			'libraries.sortLabels.productionYear' => 'سال تولید',
			'libraries.sortLabels.runtime' => 'زمان اجرا',
			'libraries.sortLabels.officialRating' => 'رتبه بندی رسمی',
			'libraries.sortLabels.premiereDate' => 'تاریخ پخش',
			'libraries.sortLabels.startDate' => 'تاریخ شروع',
			'libraries.sortLabels.airTime' => 'زمان پخش',
			'libraries.sortLabels.studio' => 'استودیو',
			'libraries.sortLabels.random' => 'تصادفی',
			'libraries.sortLabels.dateShared' => 'تاریخ به اشتراک گذاری',
			'libraries.sortLabels.latestEpisodeAirDate' => 'آخرین قسمت تاریخ هوا',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'آخرین قسمت تاریخ اضافه شده',
			'libraries.sortLabels.dateDownloaded' => 'تاریخ دانلود',
			'libraries.sortLabels.size' => 'سایز',
			'libraries.sortLabels.library' => 'کتابخانه',
			'libraries.advancedFilters.include' => 'شامل',
			'libraries.advancedFilters.exclude' => 'حذف',
			'libraries.advancedFilters.any' => 'هر چیزی',
			'libraries.advancedFilters.yes' => 'بلی',
			'libraries.advancedFilters.no' => 'خیر',
			'libraries.advancedFilters.not' => ({required Object value}) => '${value}',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '${count} انتخاب شده',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '${count} حذف شده',
			'libraries.advancedFilters.searchValues' => 'ارزش های جستجو',
			'libraries.advancedFilters.noValues' => 'هیچ ارزش',
			'libraries.advancedFilters.matchContains' => 'حاوی',
			'libraries.advancedFilters.matchNotContains' => 'شامل نمی شود',
			'libraries.advancedFilters.matchIs' => 'این است',
			'libraries.advancedFilters.matchIsNot' => 'نه است',
			'libraries.advancedFilters.matchBeginsWith' => 'با شروع با',
			'libraries.advancedFilters.matchEndsWith' => 'پایان با',
			'libraries.advancedFilters.textHint' => 'نوع برای مسابقه',
			'libraries.advancedFilters.from' => 'از',
			'libraries.advancedFilters.to' => 'برای',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from} تا ${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value} و بالا',
			'libraries.advancedFilters.atMost' => ({required Object value}) => 'تا ${value}',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => '${count} روز گذشته',
			'libraries.advancedFilters.dateLastYear' => 'سال گذشته',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => 'سن و سال ${count} روز',
			'libraries.advancedFilters.dateOlderThanYear' => 'بزرگتر از یک سال',
			'libraries.selection.selectItems' => 'انتخاب آیتم ها',
			'libraries.selection.selectedCount' => ({required Object count}) => '${count} انتخاب شده',
			'libraries.selection.actions' => 'فعالیت های انتخابی',
			'libraries.selection.confirmDescendants' => 'این تغییرات تمام قسمت ها را در نمایش ها و فصل های انتخاب شده تغییر می دهد.',
			'libraries.selection.confirmUnwatched' => 'این کار پیشرفت پخش موارد انتخاب‌شده را نیز پاک می‌کند.',
			'libraries.selection.confirmCount' => ({required Object count}) => 'تعداد بازدید : ${count}',
			'libraries.selection.completed' => ({required Object count}) => 'بایگانی برچسب ها: ${count}',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => 'به روز شده ${succeeded}؛ شکست خورده ${failed}.نمونه های شکست خورده باقی می ماند.',
			'about.title' => 'درباره',
			'about.openSourceLicenses' => 'مجوز منبع باز',
			'about.versionLabel' => ({required Object version}) => 'نسخه ${version}',
			'about.appDescription' => 'یک مشتری زیبا Plex، Jellyfin و Emby برای Flutter',
			'about.viewLicensesDescription' => 'مشاهده مجوزهای کتابخانه های شخص ثالث',
			'about.privacyPolicy' => 'سیاست حفظ حریم خصوصی',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'هیچ سرور برای ${username} (${email}) یافت نشد',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'سرورهای بارگذاری نشده: ${error}',
			'serverSelection.noValidServers' => 'هیچ سرور قابل استفاده در این حساب یافت نشد',
			'hubDetail.title' => 'عنوان',
			'hubDetail.releaseYear' => 'سال انتشار',
			'hubDetail.dateAdded' => 'تاریخ اضافه شده',
			'hubDetail.rating' => 'رتبه بندی',
			'hubDetail.noItemsFound' => 'هیچ آیتم یافت نشد',
			'logs.clearLogs' => 'مشخصات Logs',
			'logs.copyLogs' => 'کپی کردن Logs',
			'logs.uploadLogs' => 'دانلود Logs',
			'logs.saveLogs' => 'ذخیره فایل ها به فایل ها',
			'logs.logsSaved' => ({required Object path}) => 'ثبت نام در ${path}',
			'logs.saveLogsFailed' => 'نمی توانم فایل را ذخیره کنم.',
			'startup.failedTitle' => 'PlezyNG نمی تواند شروع شود',
			'startup.failedBody' => 'چیزی در هنگام راه اندازی اشتباه شد. جزئیات زیر نشان می دهد که چه چیزی شکست خورده است.',
			'startup.failedBodyRepairable' => 'فایل تنظیمات ذخیره‌شدهٔ PlezyNG آسیب دیده است و باید پیش از شروع برنامه بازسازی شود. تلاش دوباره کمکی نمی‌کند؛ «تعمیر فضای ذخیره‌سازی» را انتخاب کنید.',
			'startup.phaseLabel' => 'قدم',
			'startup.showDetails' => 'نمایش جزئیات',
			'startup.hideDetails' => 'پنهان کردن جزئیات',
			'startup.copyDetails' => 'کپی جزئیات',
			'startup.detailsCopied' => 'جزئیات کپی شده به clipboard',
			'startup.uploadDetails' => 'اضافه کردن جزئیات',
			'startup.repairStorage' => 'تعمیر ذخیره سازی',
			'startup.repairTitle' => 'اصلاح داده های ذخیره شده؟',
			'startup.repairBodyCommon' => 'فایل تنظیمات PlezyNG آسیب دیده و قابل خواندن نیست. تعمیر، همهٔ تنظیمات را به مقدار پیش‌فرض برمی‌گرداند.',
			'startup.repairBodyOneCredential' => 'اطلاعات یکی از ورودهای ذخیره‌شده آسیب دیده و قابل خواندن نیست. تعمیر فقط همان مورد را حذف می‌کند؛ سایر تنظیمات شما تغییر نمی‌کنند.',
			'startup.repairBodySignInsKept' => 'ورود شما به سرورها و نمایه‌ها باید حفظ شود.',
			'startup.repairBodySignInsLost' => 'کلیدی که از اطلاعات ورود ذخیره‌شده محافظت می‌کند از این فایل قابل بازیابی نیست، پس باید دوباره به هر سرور و نمایه وارد شوید. هیچ چیز در سرور رسانهٔ شما تغییر نمی‌کند.',
			'startup.repairBodySessionsUncertain' => 'اطلاعات سرویس‌های پیگیری (MAL، AniList، Simkl، Trakt) و Seerr جداگانه ذخیره می‌شود و ممکن است باقی بماند یا از دست برود. PlezyNG دقیقاً به شما می‌گوید چه اطلاعاتی حفظ شده است.',
			'startup.repairConfirm' => 'اصلاحات',
			'startup.repairSucceeded' => 'ذخیره سازی اصلاح شده',
			'startup.repairNeedsRestart' => 'ذخیره سازی اصلاح شده – نیاز به راه اندازی مجدد',
			'startup.restartRequiredBody' => 'داده‌های شما تعمیر شد، اما برای استفاده از آن‌ها باید PlezyNG دوباره راه‌اندازی شود. PlezyNG را ببندید و دوباره باز کنید.',
			'startup.quitPlezy' => 'آگهی PlezyNG',
			'startup.repairFailed' => 'اصلاح شکست خورده',
			'startup.repairKeptSignIns' => 'همچنان به سرورها و نمایه‌های خود وارد هستید.',
			'startup.repairLostSignIns' => 'کلیدی که از اطلاعات ورود ذخیره‌شده محافظت می‌کند قابل بازیابی نیست. باید دوباره به هر سرور و نمایه وارد شوید.',
			'startup.repairLostSessions' => 'حداقل یک ردیاب یا اتصال Seerr از دست رفته است و باید دوباره متصل شود.',
			'startup.backupTitle' => 'یک کپی از فایل آسیب دیده حفظ شده است',
			'startup.backupWarning' => 'این نسخه حاوی اطلاعات ورود شماست. آن را بارگذاری یا به اشتراک نگذارید.',
			'startup.deleteBackup' => 'حذف کپی',
			'startup.backupDeleted' => 'کپی حذف شده',
			'startup.previousFailureTitle' => 'PlezyNG آخرین بار شروع نشد',
			'licenses.relatedPackages' => 'بسته های مرتبط',
			'licenses.license' => 'مجوز',
			'licenses.licenseNumber' => ({required Object number}) => 'مجوز ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} مجوز',
			'navigation.libraries' => 'کتابخانه‌ها',
			'navigation.downloads' => 'بارگیری‌ها',
			'navigation.liveTv' => 'تلویزیون زنده',
			'navigation.explore' => 'کشف',
			'explore.mdblistShelves.manage' => 'راهنمای جستجو برای کشتی ها',
			'explore.mdblistShelves.manageDescription' => 'انتخاب و ترتیب لیست ها از حساب MDBList خود را',
			'explore.mdblistShelves.description' => 'لیست های فیلم و تلویزیون عمومی را از حساب MDBList خود انتخاب کنید و سپس لیست ها را در MDBList ایجاد یا کپی کنید.',
			'explore.mdblistShelves.selected' => 'شلوار انتخاب شده',
			'explore.mdblistShelves.available' => 'لیست حساب های موجود',
			'explore.mdblistShelves.noLists' => 'هیچ فیلم عمومی یا لیست های تلویزیونی بازگردانده نشده است. ایجاد یا کپی یک لیست در MDBList، سپس آن را بازسازی کنید.',
			'explore.mdblistShelves.displayName' => 'نام نمایش Shelf',
			'explore.mdblistShelves.nameHint' => 'اجازه دهید نام لیست منبع را خالی کنید.',
			'explore.mdblistShelves.add' => 'اضافه کردن شیل',
			'explore.mdblistShelves.save' => 'ذخیره شلوارها',
			'explore.mdblistShelves.moveUp' => ({required Object title}) => 'حرکت ${title} بالا',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => 'حرکت ${title} به پایین',
			'explore.mdblistShelves.unavailable' => 'این لیست در دسترس نیست.در تنظیمات، اسلاید خود را بازگردانید یا حذف کنید.',
			'explore.mdblistShelves.rateLimited' => 'MDBList درخواست محدود به دست آمده است لطفا بعدا عقب نشینی کنید.',
			'explore.mdblistShelves.loadFailed' => 'نمی توانم شلوارها را بارگذاری کنم، اتصال خود را بررسی کنید و عقب نشینی کنید.',
			'explore.mdblistShelves.saveFailed' => 'من نمی توانم از دستمزدها استفاده کنم لطفا از دستمزدها استفاده کنید.',
			'explore.mdblistShelves.accountChanged' => 'حساب یا پروفایل تغییر کرده است.این تنظیمات را دوباره باز کنید.',
			'explore.mdblistShelves.settingsUnreadable' => 'صفحه های ذخیره شده را نمی توان خوانده شد. لیست های خود را دوباره انتخاب کنید تا این تنظیمات را جایگزین کنید.',
			'explore.title' => 'کشف',
			'explore.selectSource' => 'انتخاب منبع',
			'explore.rows.watchlist' => 'لیست نظارت',
			'explore.rows.recommendedMovies' => 'فیلم های توصیه شده',
			'explore.rows.recommendedShows' => 'نمایش های توصیه شده',
			'explore.rows.trendingMovies' => 'فیلم های روندی',
			'explore.rows.trendingShows' => 'نمایش های روندی',
			'explore.rows.popularMovies' => 'فیلم های محبوب',
			'explore.rows.popularShows' => 'نمایش های محبوب',
			'explore.rows.trendingAnime' => 'انیمه روند',
			'explore.rows.suggestedAnime' => 'پیشنهاد انیمه',
			'explore.rows.airingAnime' => 'دانلود انیمیشن Airing Anime',
			'explore.rows.popularAnime' => 'محبوب ترین انیمه ها',
			'explore.rows.trending' => 'روند',
			'explore.rows.upcomingMovies' => 'فیلم های آینده',
			'explore.rows.upcomingShows' => 'نمایش های آینده',
			'explore.status.airing' => 'هواشناسی',
			'explore.status.ended' => 'تمام شده',
			'explore.status.canceled' => 'لغو',
			'explore.status.upcoming' => 'بزودی',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} قسمت', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} قسمت ها', ), 
			'explore.cast' => 'کاست',
			'explore.characters' => 'شخصیت ها',
			'explore.addToWatchlist' => 'اضافه کردن به Watchlist',
			'explore.removeFromWatchlist' => 'حذف از Watchlist',
			'explore.addedToWatchlist' => 'اضافه شده به watchlist',
			'explore.removedFromWatchlist' => 'حذف از لیست نظارت',
			'explore.watchlistUpdateFailed' => 'نمی توانم لیست نظارت را به روز کنم',
			'explore.watchlistNoMatch' => 'نمی توانم این موضوع را با یک لیست تماشاگر مطابقت داشته باشم',
			'explore.notInLibrary' => 'نه در کتابخانه شما',
			'explore.inTheseLibraries' => 'در این کتابخانه ها',
			'explore.checkingLibrary' => 'کتابخانه خود را بررسی کنید.',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n, one: 'نمی توانم سرور ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} را چک کنم', other: 'نمی توانم ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} سرورها را چک کنم', ), 
			'explore.emptyTitle' => 'هنوز چیزی در اینجا نیست',
			'explore.emptyMessage' => ({required Object source}) => 'خطوط از ${source} در اینجا ظاهر خواهد شد هنگامی که آنها محتوا دارند.',
			'explore.searchHint' => ({required Object source}) => 'جستجو ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'نتایج جستجو برای "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'جستجو برای فیلم ها و نمایش ها در ${source}',
			'explore.searchFailed' => 'جستجو شکست خورده است، اتصال خود را بررسی کنید و دوباره امتحان کنید.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} محبوب',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} هواشناسی',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} رتبه بندی',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} روند',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} در ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} بازدید',
			'explore.badge.available' => 'در دسترس',
			'explore.badge.partiallyAvailable' => 'در دسترس جزئی',
			'explore.badge.availableIn4k' => '4K در دسترس',
			'explore.badge.requested' => 'درخواست شده',
			'explore.badge.pendingApproval' => 'مدت زمان تایید',
			'explore.badge.processing' => 'پردازش',
			'explore.badge.declined' => 'تخریب',
			'explore.badge.requestFailed' => 'درخواست شکست خورده',
			'explore.badge.requested4k' => '4K درخواست شده',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available} / ${total} فصل',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => '${episode} در ${duration}',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'بعدی در ${duration}',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} EPS',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} دقیقه/بخش',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} ثبت شده',
			'explore.stats.viewersDay' => ({required Object n}) => '${n} بازدید امروز',
			'explore.stats.viewersWeek' => ({required Object n}) => 'این هفته ${n} نفر تماشا کردند',
			'explore.stats.viewersMonth' => ({required Object n}) => 'این ماه ${n} نفر تماشا کردند',
			'explore.stats.viewersYear' => ({required Object n}) => '${n} بازدید در این سال',
			'explore.stats.viewersAllTime' => ({required Object n}) => '${n} بیننده',
			'explore.stats.planning' => ({required Object n}) => '${n} برنامه ریزی برای مشاهده',
			'explore.stats.favorited' => ({required Object n}) => '${n} مورد علاقه',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} آن را از دست داد',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} دیدگاه ها', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} دیدگاه ها', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} رای',
			'explore.stats.watching' => ({required Object n}) => '${n} بازدید',
			'explore.stats.completed' => ({required Object n}) => '${n} تکمیل شده',
			'explore.stats.onHold' => ({required Object n}) => '${n} در دسترس',
			'explore.stats.dropped' => ({required Object n}) => '${n} از دست رفته',
			'explore.season.winter' => 'زمستان',
			'explore.season.spring' => 'بهار',
			'explore.season.summer' => 'تابستان',
			'explore.season.fall' => 'سقوط',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'تلویزیون',
			'explore.format.tvShort' => 'تلویزیون کوتاه',
			'explore.format.movie' => 'فیلم',
			'explore.format.special' => 'ویژه',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => 'موسیقی‌ها',
			'explore.format.other' => 'دیگر',
			'explore.sourceMaterial.original' => 'اصلی',
			'explore.sourceMaterial.manga' => 'مانگا',
			'explore.sourceMaterial.lightNovel' => 'نور رمان',
			'explore.sourceMaterial.novel' => 'رمان',
			'explore.sourceMaterial.visualNovel' => 'رمان بصری',
			'explore.sourceMaterial.game' => 'بازی',
			'explore.sourceMaterial.webComic' => 'وبسایت کمدی',
			'explore.sourceMaterial.musicRelease' => 'موسیقی‌ها',
			'explore.sourceMaterial.otherMedia' => 'دیگر',
			'explore.creditRole.actor' => 'بازیگر',
			'explore.creditRole.director' => 'کارگردان',
			'explore.creditRole.writer' => 'نویسنده',
			'explore.creditRole.producer' => 'تولید کننده',
			'explore.creditRole.creator' => 'خالق',
			'explore.creditRole.composer' => 'آهنگساز',
			'explore.relation.prequel' => 'پیشگویی',
			'explore.relation.sequel' => 'بعدی',
			'explore.relation.sideStory' => 'داستان جانبی',
			'explore.relation.spinOff' => 'اسپین آف',
			'explore.relation.alternativeVersion' => 'نسخه ی جایگزین',
			'explore.relation.summary' => 'خلاصه ای',
			'explore.relation.parentStory' => 'داستان پدر',
			'explore.relation.adaptation' => 'انطباق',
			'explore.relation.other' => 'مرتبط',
			'explore.broadcast' => ({required Object day, required Object time}) => 'Airs ${day} در ${time}',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => 'Airs ${day} در ${time} ${timezone}',
			'explore.detail.originalTitle' => 'عنوان اصلی',
			'explore.detail.alsoKnownAs' => 'همچنین شناخته شده به عنوان',
			'explore.detail.studios' => 'استودیو‌ها',
			'explore.detail.country' => 'کشور',
			'explore.detail.language' => 'زبان',
			'explore.detail.released' => 'آزاد شد',
			'explore.detail.physicalRelease' => 'در دیسک',
			'explore.detail.ended' => 'تمام شده',
			'explore.detail.addedOn' => ({required Object date}) => 'اضافه شده ${date}',
			'explore.detail.yourRating' => 'رتبه بندی شما',
			'explore.detail.budget' => 'بودجه',
			'explore.detail.revenue' => 'جعبه دفتر',
			'explore.detail.contentAdvisory' => 'راهنمای سن',
			'explore.detail.tags' => 'برچسب‌ها',
			'explore.detail.revealSpoilerTags' => 'برچسب های Spoiler',
			'explore.detail.links' => 'چپ ها',
			'explore.detail.watchOn' => 'نگاهی به',
			'explore.detail.watchTrailer' => 'تماشای تریلر',
			'explore.detail.openOn' => ({required Object site}) => 'باز شده در ${site}',
			'explore.detail.crew' => 'خدمه',
			'explore.detail.ratings' => 'رتبه بندی',
			'explore.detail.schedule' => 'برنامه زمانی',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n, one: 'توصیه شده توسط ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} کاربر', other: 'توصیه شده توسط ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} کاربران', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'توصیه شده توسط ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'محبوب شده توسط ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} هنوز ارسال نشده',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'توصیه شده توسط ${percent} بازدید کنندگان',
			'explore.detail.relatedTitles' => 'عنوان های مرتبط',
			'explore.detail.background' => 'پس زمینه',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} نتیجه', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} نتایج', ), 
			'liveTv.title' => 'تلویزیون زنده',
			'liveTv.guide' => 'راهنما',
			'liveTv.noChannels' => 'هیچ کانال در دسترس',
			'liveTv.noDvr' => 'هیچ DVR در هر سرور تنظیم نشده است',
			'liveTv.serverUnavailable' => 'سرور تلویزیون زنده در دسترس نیست.',
			'liveTv.serverNotConnected' => 'سرور تلویزیون زنده متصل نیست.',
			'liveTv.noPrograms' => 'هیچ اطلاعات برنامه در دسترس نیست',
			'liveTv.liveStreamFailed' => 'جریان زنده شکست خورده',
			'liveTv.unknownProgram' => 'برنامه ناشناخته',
			'liveTv.timelineLiveProgram' => 'برنامه زنده (برای بازی ممکن است خارج از این برنامه باشد)',
			'liveTv.timelineBuffer' => 'زمانبندی بوفر',
			'liveTv.timelineUnavailable' => 'جدول زمانی در دسترس نیست',
			'liveTv.timelineEstimated' => 'دانلود بازی Playback',
			'liveTv.timelinePending' => 'در جستجوی',
			'liveTv.timelineStale' => 'برنامه ممکن است قدیمی شود',
			'liveTv.unknownHub' => 'ناشناخته',
			'liveTv.unknownError' => 'اشتباه ناشناخته',
			'liveTv.channelNumber' => ({required Object number}) => 'کانال ${number}',
			'liveTv.unknownChannel' => 'کانال ناشناخته',
			'liveTv.live' => 'پخش زنده',
			'liveTv.premiereBadge' => 'جدید',
			'liveTv.reloadGuide' => 'راهنمای بارگذاری',
			'liveTv.searchGuide' => 'راهنمای جستجو',
			'liveTv.searchHint' => 'کانال ها و برنامه های جستجو',
			'liveTv.searchNoResults' => ({required Object query}) => 'هیچ مسابقه ای برای «${query}» وجود ندارد',
			'liveTv.channelsSection' => 'کانالها',
			'liveTv.programsSection' => 'برنامه ها',
			'liveTv.now' => 'اکنون',
			'liveTv.today' => 'امروز',
			'liveTv.tomorrow' => 'فردا',
			'liveTv.midnight' => 'نیمه شب',
			'liveTv.overnight' => 'شب ها',
			'liveTv.morning' => 'صبحگاهی',
			'liveTv.daytime' => 'زمان روز',
			'liveTv.evening' => 'شب ها',
			'liveTv.lateNight' => 'شب دیر',
			'liveTv.whatsOn' => 'چه چیزی در',
			'liveTv.watchChannel' => 'تماشای کانال',
			'liveTv.favorites' => 'مورد علاقه‌ها',
			'liveTv.reorderFavorites' => 'دانلود محبوبیت ها',
			'liveTv.noFavoriteChannels' => 'کانال های مورد علاقه',
			'liveTv.noFavoriteChannelsHint' => 'تمام کانال ها را نشان دهید، سپس یک کانال را برای اضافه کردن آن به محبوبیت های خود فشار دهید.',
			'liveTv.showAllChannels' => 'نمایش همه کانال ها',
			'liveTv.favoritesLoadFailed' => 'نمی توانم مورد علاقه خود را بارگذاری کنم، اتصال خود را بررسی کنید و دوباره امتحان کنید.',
			'liveTv.favoritesUpdateFailed' => 'نمی توانم مورد علاقه ها را به روز کنم، اتصال خود را بررسی کنید و دوباره امتحان کنید.',
			'liveTv.joinSession' => 'جلسه در حال پیشرفت',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'تماشای از ابتدا (${minutes} دقیقه پیش)',
			'liveTv.watchLive' => 'تماشای زنده',
			'liveTv.goToLive' => 'به زندگی برو',
			'liveTv.record' => 'رکورد',
			'liveTv.recordEpisode' => 'رکورد قسمت',
			'liveTv.recordSeries' => 'ضبط کردن سریال ها',
			'liveTv.recordOptions' => 'گزینه های ثبت نام',
			'liveTv.saveTo' => 'نجات به',
			'liveTv.recordings' => 'ضبط شده ها',
			'liveTv.scheduledRecordings' => 'برنامه ریزی',
			'liveTv.recordingRules' => 'قوانین ضبط',
			'liveTv.noScheduledRecordings' => 'هیچ برنامه ای برای ضبط نیست',
			'liveTv.manageRecording' => 'مدیریت ضبط',
			'liveTv.cancelRecording' => 'لغو ضبط',
			'liveTv.cancelRecordingTitle' => 'این ضبط را لغو کنید؟',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} دیگر ثبت نخواهد شد.',
			'liveTv.deleteRule' => 'حذف قانون',
			'liveTv.deleteRuleTitle' => 'قانون ضبط را حذف کنید؟',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'قسمت های آینده ${title} ثبت نخواهد شد.',
			'liveTv.recordingScheduled' => 'ضبط برنامه ریزی شد.',
			'liveTv.alreadyScheduled' => 'این برنامه برنامه ریزی شده است.',
			'liveTv.dvrAdminRequired' => 'تنظیمات DVR نیازمند یک حساب admin است',
			'liveTv.recordingFailed' => 'نمی توانم ضبط را برنامه ریزی کنم',
			'liveTv.recordingTargetMissing' => 'نمی توانم کتابخانه را ضبط کنم',
			'liveTv.recordNotAvailable' => 'ثبت نام برای این برنامه در دسترس نیست',
			'liveTv.recordingCancelled' => 'ضبط لغو شد',
			'liveTv.recordingRuleDeleted' => 'قانون ضبط حذف شد',
			'liveTv.processRecordingRules' => 'قوانین ارزیابی مجدد',
			'liveTv.recordingInProgress' => 'ضبط در حال حاضر',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} برنامه ریزی شده',
			'liveTv.editRule' => 'تنظیم قوانین',
			'liveTv.editRuleAction' => 'ویرایش',
			'liveTv.recordingRuleUpdated' => 'قوانین ضبط به روز شده',
			'liveTv.guideReloadRequested' => 'راهنمای تجدید نظر درخواست شده',
			'liveTv.guideReloadFailed' => 'نمی توانم راهنمای را بازسازی کنم',
			'liveTv.rulesProcessRequested' => 'بررسی مجدد قوانین مورد نیاز',
			'liveTv.rulesProcessFailed' => 'نمی توانم قوانین ضبط را دوباره ارزیابی کنم',
			'liveTv.recordShow' => 'نمایش رکورد',
			'liveTv.recordSettings.startEarly' => 'شروع زود (دوره های اول)',
			'liveTv.recordSettings.endLate' => 'تاخیر در پایان (دقیقه ها)',
			'liveTv.recordSettings.newOnly' => 'فقط قسمت های جدید',
			'liveTv.recordSettings.anyChannel' => 'ثبت نام در هر کانال',
			'liveTv.recordSettings.anyTime' => 'ثبت نام در هر زمان',
			'liveTv.recordSettings.skipInLibrary' => 'قسمت ها را در حال حاضر در کتابخانه',
			'liveTv.recordSettings.keepUpTo' => 'حوادثی که باید حفظ شود',
			'liveTv.recordSettings.keepUpToHint' => '0 در هر قسمت',
			'liveTv.startingInMinutes' => ({required Object minutes}) => 'شروع در ${minutes} دقیقه',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} در ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product} بازگرداندن داده های پخش زنده تلویزیون نادرست',
			'liveTv.failedToStartChannel' => 'کانال زنده را شروع نکردم',
			'liveTv.failedToBuildStreamUrl' => 'نمی توانم URL جریان را بسازم',
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'کانال را نمی توانم راه اندازی کنم: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'نمی توانم کانال را تغییر دهم: ${reason}',
			'collections.title' => 'مجموعه‌ها',
			'collections.collection' => 'مجموعه',
			'collections.empty' => 'مجموعه خالی است',
			'collections.deleteCollection' => 'حذف مجموعه',
			'collections.deleteConfirm' => ({required Object title}) => '«${title}» حذف شود؟ این کار قابل بازگشت نیست.',
			'collections.deleted' => 'جمع آوری حذف شده',
			'collections.deleteFailed' => 'عدم حذف مجموعه',
			'collections.deleteFailedWithError' => ({required Object error}) => 'عدم حذف مجموعه: ${error}',
			'collections.selectCollection' => 'انتخاب مجموعه',
			'collections.collectionName' => 'نام جمع آوری',
			'collections.enterCollectionName' => 'نام مجموعه را وارد کنید',
			'collections.addedToCollection' => 'اضافه شده به مجموعه',
			'collections.errorAddingToCollection' => 'عدم اضافه شدن به جمع آوری',
			'collections.created' => 'جمع آوری ساخته شده',
			'collections.removeFromCollection' => 'حذف از مجموعه',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => '«${title}» از این مجموعه حذف شود؟',
			'collections.removedFromCollection' => 'حذف از جمع آوری',
			'collections.removeFromCollectionFailed' => 'از جمع آوری خارج نشود',
			'collections.removeFromCollectionError' => ({required Object error}) => 'خطای حذف از مجموعه: ${error}',
			'collections.searchCollections' => 'جمع آوری جستجو...',
			'playlists.title' => 'لیست‌های پخش',
			'playlists.playlist' => 'لیست پخش',
			'playlists.noPlaylists' => 'هیچ بازیگر یافت نشد',
			'playlists.create' => 'ایجاد Playlist',
			'playlists.playlistName' => 'نام بازی',
			'playlists.enterPlaylistName' => 'نام بازی را وارد کنید',
			'playlists.delete' => 'حذف Playlist',
			'playlists.removeItem' => 'حذف از فهرست پخش',
			'playlists.smartPlaylist' => 'بازی هوشمند',
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} مورد', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} مورد', ), 
			'playlists.emptyPlaylist' => 'این لیست خالی است',
			'playlists.deleteConfirm' => 'لیست بازی را حذف کنید؟',
			'playlists.deleteMessage' => ({required Object name}) => 'آیا مطمئن هستید که می خواهید "${name}" را حذف کنید؟',
			'playlists.created' => 'Playlist ایجاد شده',
			'playlists.deleted' => 'Playlist حذف شده',
			'playlists.itemAdded' => 'اضافه شده به playlist',
			'playlists.itemRemoved' => 'حذف از Playlist',
			'playlists.selectPlaylist' => 'Playlist انتخاب کنید',
			'playlists.searchPlaylists' => 'جستجو برای بازی ها...',
			'playlists.errorCreating' => 'شکست در ایجاد لیست بازی',
			'playlists.errorDeleting' => 'عدم حذف لیست بازی ها',
			'playlists.errorLoading' => 'شکست در بارگذاری لیست های بازی',
			'playlists.errorAdding' => 'عدم اضافه شدن به لیست بازی',
			'playlists.errorReordering' => 'شکست در بازگرداندن آیتم های لیست بازی',
			'playlists.errorRemoving' => 'نتوانست از لیست بازی خارج شود',
			'music.goToAlbum' => 'به آلبوم برو',
			'music.goToArtist' => 'به هنرمند برو',
			'music.instantMix' => 'درهم کردن فوری',
			'music.playNext' => 'بعدی را اجرا کن',
			'music.addToQueue' => 'اضافه کردن به Queue',
			'music.discNumber' => ({required Object n}) => 'دیسک ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مسیر', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ردیف ها', ), 
			'music.nowPlaying' => 'اکنون بازی',
			'music.playingFrom' => ({required Object title}) => 'بازی از ${title}',
			'music.queue' => 'کوی',
			'music.clearQueue' => 'پاکسازی صف',
			'music.lyrics' => 'متن ترانه',
			'music.visualizer' => 'بصری',
			'music.visualizerProfileLoading' => 'در ادامه به بررسی تراکتور...',
			'music.visualizerAmbientMotion' => 'حرکات محیطی',
			'music.visualizerPlexLoudness' => 'Plex صدا',
			'music.visualizerLiveAudio' => 'تحلیل زندهٔ صدا',
			'music.visualizerPreviousPreset' => 'قبلی سبک بصری',
			'music.visualizerNextPreset' => 'بعدی سبک بصری',
			'music.visualizerPresetAurora' => 'آوریا',
			'music.visualizerPresetBloom' => 'بلوم',
			'music.visualizerPresetOrbitals' => 'مدار',
			'music.visualizerPresetPrism' => 'قیمت گذاری',
			'music.visualizerPresetTunnel' => 'تونل',
			'music.visualizerPresetTrackMap' => 'نقشه ردیابی',
			'music.noLyrics' => 'هیچ آلبوم در دسترس نیست',
			'music.sleepTimer' => 'زمان خواب',
			'music.sleepTimerEndOfTrack' => 'پایان مسیر',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} دقیقه', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} دقیقه', ), 
			'music.stopPlayback' => 'پخش را متوقف کنید',
			'music.previousTrack' => 'ترانه پیشین',
			'music.nextTrack' => 'ترانه پسین',
			'music.repeat' => 'تکرار',
			'music.repeatAll' => 'تکرار تمام بر',
			'music.repeatOne' => 'تکرار یک',
			'music.instantMixNoServer' => 'هیچ سرور برای یک مخلوط فوری در دسترس نیست',
			'music.instantMixFailed' => 'ناپدید شدن مخلوط فوری',
			'music.instantMixEmpty' => 'این ترکیب بلافاصله با هیچ ردیابی برنگشت.',
			'music.noAudioUrl' => ({required Object track}) => 'هیچ URL صوتی در دسترس نیست برای ${track}',
			'music.discography.singlesAndEps' => 'تک آهنگ ها و EPs',
			'music.discography.live' => 'پخش زنده',
			'music.discography.compilations' => 'جمع آوری',
			'watchTogether.title' => 'تماشای گروهی',
			'watchTogether.description' => 'مشاهده محتوا در همزمان با دوستان و خانواده',
			'watchTogether.createRoom' => 'ایجاد اتاق',
			'watchTogether.creatingRoom' => 'ایجاد اتاق...',
			'watchTogether.joinRoom' => 'اتاق پیوست',
			'watchTogether.joiningRoom' => 'اتاق پیوستن...',
			'watchTogether.connecting' => 'اتصال...',
			'watchTogether.relayPublic' => 'اتاق ها از پخش عمومی Open Watch Party استفاده می کنند.',
			'watchTogether.relayCustom' => ({required Object url}) => 'اتاق ها از رله شما در شماره ${url} استفاده می کنند.',
			'watchTogether.recentRooms' => 'اتاق های جدید',
			'watchTogether.roomActions' => 'فعالیت های اتاق',
			'watchTogether.renameRoom' => 'اتاق بازسازی',
			'watchTogether.removeRoom' => 'حذف',
			'watchTogether.enterRoomCode' => 'کد 6 کاراکتر را از میزبان وارد کنید.',
			'watchTogether.roomCode' => 'کد اتاق',
			'watchTogether.paste' => 'پستی',
			'watchTogether.noCodeInClipboard' => 'این صفحه شامل کد اتاق نیست.',
			'watchTogether.copyCode' => 'کپی کد',
			'watchTogether.codeCopied' => 'کد اتاق کپی شده',
			'watchTogether.shareInvite' => 'دعوت به اشتراک گذاری',
			'watchTogether.inviteCopied' => 'کپی کنید، آن را در یک پیام قرار دهید.',
			_ => null,
		} ?? switch (path) {
			'watchTogether.inviteMessage' => ({required Object code}) => 'به اتاق Watch Together من در PlezyNG بپیوندید، اتاق Watch Together را انتخاب کنید و به اتاق Watch Together ${code} وارد شوید.',
			'watchTogether.openSessionControls' => 'Open Watch با هم کنترل جلسه',
			'watchTogether.reconnecting' => 'دوباره اتصال...',
			'watchTogether.reconnectingDescription' => 'اتصال قطع شده است شما به طور خودکار به اتاق می روید.',
			'watchTogether.connected' => 'اتصال',
			'watchTogether.disconnected' => 'انحطاط',
			'watchTogether.youAreHost' => 'شما میزبان هستید',
			'watchTogether.hostedBy' => ({required Object name}) => 'بازدید : ${name}',
			'watchTogether.hostControlsPlayback' => 'کنترل بازی ها Playback',
			'watchTogether.anyoneCanControl' => 'هر کسی می تواند بازی را کنترل کند',
			'watchTogether.roomLocked' => 'اتاق بسته',
			'watchTogether.nowPlaying' => 'اکنون بازی',
			'watchTogether.nothingPlaying' => 'بازی چیزی نیست',
			'watchTogether.nothingPlayingHost' => 'بازی چیزی از هر کتابخانه برای به اشتراک گذاشتن آن با اتاق.',
			'watchTogether.nothingPlayingGuest' => 'هنگامی که میزبان چیزی را بازی می کند، در اینجا باز می شود.',
			'watchTogether.notShareable' => 'این ویدئو هیچ ربطی به کاتالوگ ندارد، بنابراین تنها افرادی که به همان سرور دسترسی دارند می توانند آن را پخش کنند.',
			'watchTogether.searching' => 'در جستجوی این ویدئو در کتابخانه های شما...',
			'watchTogether.yourCopy' => 'کپی شما',
			'watchTogether.sharingYourCopy' => 'شما کپی خود را به اشتراک می گذارید',
			'watchTogether.playingOtherLength' => ({required Object difference}) => 'بازی کپی خود را، ${difference}',
			'watchTogether.mismatchTitle' => 'کپی شما طول متفاوت است',
			'watchTogether.mismatchDescription' => ({required Object difference}) => 'نزدیک ترین کپی شما ${difference} از ویدئو اتاق است.این می تواند یک برش یا نسخه دیگر باشد.',
			'watchTogether.playAnyway' => 'بازی به هر حال',
			'watchTogether.chooseAnotherCopy' => 'انتخاب کپی دیگر',
			'watchTogether.dontPlay' => 'بازی نکنید',
			'watchTogether.unavailableTitle' => 'شما این ویدئو را ندارید',
			'watchTogether.unavailableDescription' => 'PlezyNG نمی توانست آن را در کتابخانه های شما پیدا کند. یک کپی را خودتان انتخاب کنید یا دوباره جستجو کنید.',
			'watchTogether.chooseCopy' => 'انتخاب کپی',
			'watchTogether.searchAgain' => 'جستجو دوباره',
			'watchTogether.noCandidates' => 'هیچ کپی در کتابخانه های شما یافت نشد.',
			'watchTogether.choiceFailed' => 'نمی توانم این کپی را برای اتاق بازی کنم.',
			'watchTogether.lengthLonger' => ({required Object duration}) => '${duration} بیشتر',
			'watchTogether.lengthShorter' => ({required Object duration}) => '${duration} کوتاه تر',
			'watchTogether.lengthSame' => 'همان طول',
			'watchTogether.lengthUnknown' => 'طول ناشناخته',
			'watchTogether.joinCurrentPlayback' => 'دانلود بازی Current Playback',
			'watchTogether.joinCurrentPlaybackDescription' => 'بازگشت به آنچه میزبان در حال حاضر تماشا می کند',
			'watchTogether.stopMedia' => 'دانلود ویدئو برای همه',
			'watchTogether.syncOffset' => 'همگام سازی Offset',
			'watchTogether.syncOffsetDescription' => 'ویدئوی خود را تغییر دهید اگر در مقابل یا پشت اتاق اجرا شود.',
			'watchTogether.offsetHint' => ({required Object difference}) => 'کپی شما ${difference} از ویدئو اتاق است.',
			'watchTogether.applyDifference' => ({required Object offset}) => 'استفاده از ${offset}',
			'watchTogether.offsetMinusSecond' => '1 S',
			'watchTogether.offsetMinusTenth' => '100 مگابایت',
			'watchTogether.offsetPlusTenth' => '+ 100 مگابایت',
			'watchTogether.offsetPlusSecond' => '+ 1 S',
			'watchTogether.participants' => 'شرکت کنندگان',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} شرکت کنندگان', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} شرکت کنندگان', ), 
			'watchTogether.hostBadge' => 'میزبان',
			'watchTogether.nameYou' => ({required Object name}) => '${name} (شما)',
			'watchTogether.playerIdle' => 'ایدل',
			'watchTogether.playerLoading' => 'بارگذاری',
			'watchTogether.playerReady' => 'آماده',
			'watchTogether.playerBuffering' => 'بوفری',
			'watchTogether.matchSearching' => 'جستجو',
			'watchTogether.matchMatched' => 'ویدئو را دارید',
			'watchTogether.matchMismatched' => 'طول متفاوت',
			'watchTogether.matchUnavailable' => 'ویدئو را ندارید',
			'watchTogether.participantOffset' => ({required Object offset}) => 'آگهی ${offset}',
			'watchTogether.makeHost' => 'میزبانی کنید',
			'watchTogether.makeHostQuestion' => 'انتقال میزبان؟',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} بازتاب را کنترل می کند و جلسه را برای همه اجرا می کند.',
			'watchTogether.transfer' => 'انتقال',
			'watchTogether.removeParticipant' => 'از اتاق خارج شوید',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => 'حذف ${name}؟',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} اتاق را ترک می کند.آنها می توانند دوباره با کد پیوستند مگر اینکه اتاق را قفل کنید.',
			'watchTogether.remove' => 'حذف',
			'watchTogether.roomSettings' => 'تنظیمات اتاق',
			'watchTogether.letEveryoneControl' => 'اجازه دهید همه کنترل Playback',
			'watchTogether.lockRoom' => 'اتاق قفل',
			'watchTogether.lockRoomDescription' => 'هیچ کس جدیدی نمی تواند به',
			'watchTogether.leaveRoom' => 'اتاق را ترک کنید',
			'watchTogether.leaveRoomQuestion' => 'اتاق را ترک کنید؟',
			'watchTogether.leaveRoomConfirm' => 'شما می توانید دوباره با کد اتاق وارد شوید.',
			'watchTogether.leave' => 'ترک کردن',
			'watchTogether.endRoom' => 'اتاق نهایی',
			'watchTogether.endRoomQuestion' => 'اتاق نهایی؟',
			'watchTogether.endRoomConfirm' => 'این پایان اتاق برای همه است.',
			'watchTogether.end' => 'پایان',
			'watchTogether.playBlockedTitle' => 'Playback شروع نمی شود',
			'watchTogether.playBlockedDescription' => 'برای شروع تماشای بازی با اتاق.',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} بازی فشار داده شده',
			'watchTogether.notices.playbackStarted' => 'Playback آغاز شد',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} استراحت',
			'watchTogether.notices.playbackPaused' => 'بازی با استراحت',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} پرش به ${position}',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => 'به شماره ${position} رسید.',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} سرعت را به ${speed} تنظیم کنید',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => 'سرعت تنظیم شده به ${speed}',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} شروع ${title}',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => 'در حال حاضر بازی ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} این ویدئو را متوقف کرد',
			'watchTogether.notices.mediaStopped' => 'ویدئو متوقف شد',
			'watchTogether.notices.waitingFor' => ({required Object name}) => 'در انتظار ${name} ...',
			'watchTogether.notices.waitingForSomeone' => 'منتظر کسی هستم که آن را بگیرد...',
			'watchTogether.notices.finished' => 'پایان یافت',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} در حال حاضر میزبان',
			'watchTogether.notices.youAreNowHost' => 'شما میزبان هستید',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} پیوست',
			'watchTogether.notices.left' => ({required Object name}) => '${name} بازه',
			'watchTogether.notices.controlRefused' => 'تنها میزبان می تواند بازی را کنترل کند.',
			'watchTogether.notices.searchFailed' => 'برخی از سرورها نمی توانستند برای ویدئو اتاق جستجو کنند.',
			'watchTogether.notices.playBlocked' => 'بازی مطبوعاتی برای شروع',
			'watchTogether.notices.shareFailed' => 'نمی توانم این ویدئو را با اتاق به اشتراک بگذارم',
			'watchTogether.notices.downloadNotShared' => 'دانلود ها با اتاق به اشتراک نمی گذارند در حالی که سرور آنها آفلاین است',
			'watchTogether.notices.openFailed' => 'نمی توانم ویدئوی اتاق را باز کنم',
			'watchTogether.ended.ended' => 'میزبان اتاق را به پایان رساند',
			'watchTogether.ended.kicked' => 'شما از اتاق خارج شده اید.',
			'watchTogether.ended.expired' => 'اتاق تمام شد',
			'watchTogether.ended.replaced' => 'شما این اتاق را در دستگاه دیگری قرار داده اید.',
			'watchTogether.ended.lost' => 'از دست دادن اتصال به اتاق',
			'watchTogether.errors.invalidCode' => 'کدها دارای 6 حرف و اعداد هستند، بدون 0، 1، I، L یا O.',
			'watchTogether.errors.roomNotFound' => 'هیچ کدام از این اتاق ها این کد را ندارند، ممکن است به پایان برسد.',
			'watchTogether.errors.roomFull' => 'این اتاق پر است.',
			'watchTogether.errors.roomLocked' => 'میزبان این اتاق را بسته بود.',
			'watchTogether.errors.relayFull' => 'در حال حاضر شلوغ است.بعدی دوباره امتحان کنید.',
			'watchTogether.errors.unreachable' => 'نمی توانم به ساعت با هم رله برسم.نگاه کنید به اتصال خود را.',
			'watchTogether.errors.rateLimited' => 'خیلی تلاش کنید، یک لحظه صبر کنید و دوباره امتحان کنید.',
			'watchTogether.errors.clientBlocked' => 'این نسخه از PlezyNG نمی تواند از رله استفاده کند.',
			'watchTogether.errors.forbidden' => 'تنها میزبان می تواند این کار را انجام دهد.',
			'watchTogether.errors.notInRoom' => 'شما در یک اتاق نیستید.',
			'watchTogether.errors.alreadyInRoom' => 'شما در حال حاضر در یک اتاق هستید.',
			'watchTogether.errors.resumeFailed' => 'نمی توانستم به اتاق بروم.',
			'watchTogether.errors.unsupported' => 'رله ها از این موضوع حمایت نمی کنند.',
			'watchTogether.errors.generic' => 'چیزی اشتباه کرد، دوباره امتحان کنید.',
			'watchTogether.untitledEpisode' => ({required Object number}) => 'صفحه اصلی ${number}',
			'downloads.title' => 'بارگیری‌ها',
			'downloads.manage' => 'مدیریت',
			'downloads.tvShows' => 'تلویزیون نمایش',
			'downloads.movies' => 'فیلم ها',
			'downloads.music' => 'موسیقی‌ها',
			'downloads.tracksQueued' => ({required Object count}) => '${count} ردیابی برای دانلود',
			'downloads.noDownloads' => 'هنوز دانلود نشده',
			'downloads.noDownloadsDescription' => 'محتوای دانلود شده برای مشاهده آفلاین در اینجا ظاهر خواهد شد.',
			'downloads.downloadNow' => 'بارگیری',
			'downloads.deleteDownload' => 'حذف دانلود',
			'downloads.retryDownload' => 'دانلود Retry',
			'downloads.downloadQueued' => 'دانلود به صف اضافه شد.',
			'downloads.downloadResumed' => 'دانلود مجدد',
			'downloads.serverErrorBitrate' => 'خطای سرور: فایل ها می توانند حد بیتی از راه دور را فراتر ببرند',
			'downloads.storageFull' => 'دانلود ها برای محافظت از ذخیره سازی در دسترس متوقف شده است. برخی از فضای را آزاد کنید یا محل دانلود دیگری را انتخاب کنید، سپس عقب نشینی کنید.',
			'downloads.storageUnavailable' => 'دانلود ها متوقف شد زیرا ذخیره سازی در دسترس نمی تواند بررسی شود.نگاه کنید به محل دانلود، سپس عقب نشینی.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} قسمت برای دانلود',
			'downloads.downloadDeleted' => 'دانلود حذف شده',
			'downloads.deleteConfirm' => ({required Object title}) => 'حذف "${title}" از این دستگاه؟',
			'downloads.deleteCollectionDownloads' => 'حذف دانلود ها',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => 'همهٔ دانلودهای «${title}» از این دستگاه پاک شوند؟',
			'downloads.collectionDownloadsDeleted' => 'دانلود حذف شده',
			'downloads.cancelledDownloadTitle' => 'دانلود لغو',
			'downloads.cancelledDownloadMessage' => 'این دانلود لغو شده است چه کاری می خواهید انجام دهید؟',
			'downloads.allEpisodesAlreadyDownloaded' => 'همه قسمت ها دانلود شده است',
			'downloads.resumeDownload' => 'دانلود مجدد',
			'downloads.cancelledDownload' => 'دانلود لغو',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (تولید ${status})',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => 'دانلود شده ${file} - کلیک کنید برای تکمیل',
			'downloads.partialDownloadClickToComplete' => 'دانلود جزئی - کلیک کنید برای تکمیل',
			'downloads.deleting' => 'حذف...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'حذف ${title}... (${current} از ${total})',
			'downloads.queuedTooltip' => 'کویت',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'آگهی ${files}',
			'downloads.downloadingTooltip' => 'دانلود...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'دانلود ${files}',
			'downloads.noDownloadsTree' => 'بدون دانلود',
			'downloads.pauseAll' => 'استراحت همه',
			'downloads.resumeAll' => 'خلاصه همه',
			'downloads.retryAll' => 'بازگشت همه',
			'downloads.retryFailed' => 'دانلود بازی های شکست خورده',
			'downloads.deleteAll' => 'حذف همه',
			'downloads.selectVersion' => 'انتخاب نسخه',
			'downloads.allEpisodes' => 'تمام قسمت‌ها',
			'downloads.unwatchedOnly' => 'فقط نادیده گرفته شده',
			'downloads.nextNUnwatched' => ({required Object count}) => 'بعدی ${count} ناشناخته',
			'downloads.customAmount' => 'مقدار سفارشی...',
			'downloads.customAmountAny' => 'مقدار مشخصی (در هر...',
			'downloads.randomEpisodes' => 'حوادث تصادفی',
			'downloads.includeSpecials' => 'شامل ویژه ها',
			'downloads.howManyEpisodes' => 'چند قسمت است؟',
			'downloads.invalidEpisodeCount' => 'تعداد قسمت های معتبر را وارد کنید.',
			'downloads.keepSynced' => 'همگام نگه دارید',
			'downloads.downloadOnce' => 'دانلود یک بار',
			'downloads.keepNUnwatched' => ({required Object count}) => '${count} را نادیده بگیرید',
			'downloads.editSyncRule' => 'ویرایش قوانین Sync',
			'downloads.removeSyncRule' => 'حذف قاعده سینک',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'توقف همگام سازی "${title}"؟ قسمت های دانلود شده حفظ خواهد شد.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => '«پایان» به «${title}» می رسد.',
			'downloads.deleteSyncRuleDownloads' => 'همچنین حذف دانلود های مرتبط',
			'downloads.deleteSyncRuleDownloadsDescription' => 'دانلود هایی که توسط یک قاعده یا پروفایل همگام سازی دیگر مورد استفاده قرار می گیرند، حفظ می شود.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'قاعده همگام سازی ایجاد شده – حفظ ${count} قسمت های ناشناخته',
			'downloads.syncRuleUpdated' => 'قانون همگام سازی به روز شده',
			'downloads.syncRuleRemoved' => 'قانون همگام حذف شد',
			'downloads.syncRuleAndDownloadsRemoved' => 'قانون همگام سازی و دانلود های مرتبط حذف شد',
			'downloads.syncRuleCleanupBusy' => 'قوانین همگام سازی در حال حاضر به روز شده است.در یک لحظه دوباره امتحان کنید.',
			'downloads.syncRuleCleanupUnavailable' => 'دانلود های مرتبط نمی تواند به طور ایمن شناسایی شود. دوباره سرور را به هم متصل کنید و دوباره آن را امتحان کنید، یا قاعده را بدون حذف دانلود ها حذف کنید.',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => 'همگام سازی ${count} قسمت های جدید برای ${title}',
			'downloads.syncNow' => 'همگام اکنون',
			'downloads.downloadsUpToDate' => 'دانلود ها به روز شده است',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => 'همگام سازی کامل · ${queued} queued, ${removed} حذف شده',
			'downloads.activeSyncRules' => 'قوانین Sync',
			'downloads.reviewOrphanFiles' => 'دانلود دانلود بازی Orphaned',
			'downloads.orphanReviewTitle' => 'دانلود دانلود بازی Orphaned',
			'downloads.orphanReviewDescription' => 'این فایل های برچسب گذاری شده در پوشه های دانلود برنامه مدیریت شده پیش فرض PlezyNG هستند و هیچ رکورد دانلود یا کار فعال مطابقت ندارد.',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count} فایل ها · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => 'حذف فایل ${count}',
			'downloads.orphanCleanupNone' => 'دانلود فایل های ارواح یافت نشد',
			'downloads.orphanCleanupFailed' => 'PlezyNG نمی توانست به طور ایمن اسکن پوشه دانلود های مدیریت شده.',
			'downloads.orphanCleanupChanged' => 'لیست دانلود در طول بررسی تغییر کرده است. بررسی فایل ها دوباره قبل از تمیز کردن.',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => 'حذف شده ${count} فایل های ارواح · ${size} آزاد',
			'downloads.noSyncRules' => 'هیچ قواعد همگام سازی',
			'downloads.manageSyncRule' => 'مدیریت Sync',
			'downloads.editEpisodeCount' => 'قسمت شمارش',
			'downloads.editSyncFilter' => 'فیلتر Sync',
			'downloads.syncAllItems' => 'جمع آوری همه اشیاء',
			'downloads.syncUnwatchedItems' => 'دسته بندی نکات ناشناخته',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'سرور: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'در دسترس',
			'downloads.syncRuleOffline' => 'آفلاین',
			'downloads.syncRuleSignInRequired' => 'ثبت نام در مورد نیاز',
			'downloads.syncRuleAccessDenied' => 'دسترسی رد شد',
			'downloads.syncRuleNotAvailableForProfile' => 'در حال حاضر در پروفایل موجود نیست',
			'downloads.syncRuleUnknownServer' => 'سرور ناشناخته',
			'downloads.syncRuleListCreated' => 'قاعده همگام سازی ایجاد شده',
			'downloads.backgroundWarning.bannerBlocked' => 'دانلود ها وقتی برنامه را ترک می کنید متوقف می شوند',
			'downloads.backgroundWarning.bannerDegraded' => 'دانلود های پس زمینه ممکن است محدود باشد',
			'downloads.backgroundWarning.bannerAction' => 'جزئیات',
			'downloads.backgroundWarning.sheetTitle' => 'دانلود های پس زمینه مسدود شده اند',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'دانلود های پس زمینه ممکن است محدود باشد',
			'downloads.backgroundWarning.sheetIntro' => 'Android جلوگیری می کند PlezyNG از دانلود قابل اعتماد در پس زمینه.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'دستگاه شما محدود می کند زمانی که PlezyNG می تواند در پس زمینه دانلود شود.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'استفاده از پس زمینه PlezyNG محدود است و استفاده از باتری یا پس زمینه آن را به "غیر محدود" تنظیم کنید.',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android PlezyNG را در حالت ایستادگی محدود قرار داده است. استفاده از باتری را به "غیر محدود" تنظیم کنید.',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'اطلاعیه های دانلود غیرفعال می شوند، بنابراین پیشرفت و کنترل ها ممکن است در دسترس نباشد.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'در Android 13 یا جدیدتر، آنها برای دانلود های پس زمینه طولانی مورد نیاز است.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Data Saver در حال اجرا است، که بلاک دانلود های پس زمینه در داده های تلفن همراه است. دانلود ها باید هنوز هم در Wi-Fi اجرا می شود.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'وقتی PlezyNG در پس‌زمینه بود، دانلودها چند بار متوقف شدند. تنظیمات باتری یا فعالیت پس‌زمینهٔ PlezyNG را بررسی کنید.',
			'downloads.backgroundWarning.openSettings' => 'تنظیمات باز',
			'downloads.backgroundWarning.stillNotWorking' => 'کمک های خاص دستگاه',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'مشاهده مراحل برای دستگاه شما، یا ارسال یک سوابق از تنظیمات › مشاهده سوابق اگر مشکل ادامه دارد.',
			'downloads.backgroundWarning.dialogTitle' => 'دانلود ها ممکن است به پایان نرسند',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'دانلود به هر حال',
			'downloads.backgroundWarning.dialogFixFirst' => 'اول این را اصلاح کنید',
			'downloads.backgroundWarning.statusTile' => 'دانلود پس زمینه',
			'downloads.backgroundWarning.statusOk' => 'اجازه اجرا در پس زمینه',
			'downloads.backgroundWarning.statusBlocked' => 'مسدود شده توسط تنظیمات سیستم',
			'downloads.backgroundWarning.statusDegraded' => 'محدود به تنظیمات سیستم',
			'downloads.backgroundWarning.statusUnknown' => 'هنوز بررسی نشده',
			'downloads.backgroundWarning.settingsUnavailable' => 'امکان باز کردن تنظیمات سیستم در این دستگاه وجود ندارد.',
			'downloads.backgroundWarning.linkUnavailable' => 'نمی توانم dontkillmyapp.com را در این دستگاه باز کنم',
			'downloads.options' => 'گزینه های دانلود',
			'downloads.groupings.library' => 'کتابخانه',
			'downloads.groupings.collections' => 'مجموعه‌ها',
			'downloads.unknownLibrary' => 'کتابخانه ناشناخته',
			'downloads.unknownShow' => 'نمایش ناشناخته',
			'downloads.unknownSeason' => 'فصل ناشناخته',
			'downloads.unknownAlbum' => 'آلبوم ناشناخته',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} تکمیل شده',
			'downloads.storageUsed' => ({required Object size}) => 'ذخیره سازی مورد استفاده: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} دانلود', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} دانلود', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} نمایش', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} نمایش', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} فیلم', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} فیلم ها', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} آلبوم', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} آلبوم', ), 
			'downloads.errorFileNotFound' => 'فایلهای یافت نشد (404)',
			'downloads.errorDownloadNotAllowed' => 'دانلود غیر مجاز توسط سرور (403)',
			'downloads.errorDownloadFailed' => 'دانلود شکست خورد',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'دانلود شکست خورده: ${reason}',
			'downloads.convertingOnServer' => 'تبدیل به سرور',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => 'تبدیل به سرور · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => 'دانلود شکست خورده (HTTP ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => 'پس از پردازش شکست خورده: ${reason}',
			'downloads.reasonFileNotSaved' => 'فایل ها را نمی توان در این دستگاه ذخیره کرد.',
			'downloads.reasonCannotResume' => 'دانلود جزئی نمی تواند تکرار شود',
			'downloads.reasonDeviceStorageFull' => 'این دستگاه از ذخیره سازی خارج می شود.',
			'downloads.notificationDownloading' => 'دانلود...',
			'downloads.notificationComplete' => 'دانلود کامل',
			'downloads.notificationPaused' => 'دانلود استراحت',
			'shaders.title' => 'سایه ها',
			'shaders.noShaderDescription' => 'بدون ویدئو بهبود',
			'shaders.nvscalerDescription' => 'NVIDIA تصویر اسکن برای ویدئو های تیز تر',
			'shaders.artcnnVariantNeutral' => 'بی طرف',
			'shaders.artcnnVariantDenoise' => 'دنو',
			'shaders.artcnnVariantDenoiseSharpen' => 'دایناسور + شارپن',
			'shaders.qualityFast' => 'سریع',
			'shaders.qualityHQ' => 'کیفیت بالا',
			'shaders.mode' => 'مد',
			'shaders.importShader' => 'واردات شیراز',
			'shaders.customShaderDescription' => 'تبلت های GLSL Shader',
			'shaders.shaderImported' => 'شیراز واردات',
			'shaders.shaderImportFailed' => 'شکست در واردات شیراز',
			'shaders.deleteShader' => 'حذف Shader',
			'shaders.deleteShaderConfirm' => ({required Object name}) => 'حذف «${name}»؟',
			'companionRemote.title' => 'کنترل همراه',
			'companionRemote.connectedTo' => ({required Object name}) => 'به ${name} متصل شده است.',
			'companionRemote.unknownDevice' => 'دستگاه ناشناخته',
			'companionRemote.session.startingServer' => 'راه اندازی سرورهای از راه دور',
			'companionRemote.session.hostAddress' => 'آدرس میزبان',
			'companionRemote.session.connected' => 'اتصال',
			'companionRemote.session.serverRunning' => 'سرورهای از راه دور فعال',
			'companionRemote.session.serverStopped' => 'سرور از راه دور متوقف شد',
			'companionRemote.session.serverRunningDescription' => 'دستگاه های تلفن همراه در شبکه شما می توانند به این برنامه متصل شوند',
			'companionRemote.session.serverStoppedDescription' => 'سرور را راه اندازی کنید تا دستگاه های تلفن همراه بتوانند به',
			'companionRemote.session.usePhoneToControl' => 'از دستگاه موبایل خود برای کنترل این برنامه استفاده کنید.',
			'companionRemote.session.startServer' => 'شروع سرور',
			'companionRemote.session.stopServer' => 'توقف سرور',
			'companionRemote.session.minimize' => 'حداقل',
			'companionRemote.session.manualAddressHint' => 'آدرس اتصال دستی :',
			'companionRemote.pairing.discoveryDescription' => 'دستگاه های PlezyNG با همان حساب Plex در اینجا ظاهر می شوند',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'اتصال...',
			'companionRemote.pairing.searchingForDevices' => 'در جستجوی تجهیزات...',
			'companionRemote.pairing.noDevicesFound' => 'هیچ دستگاهی در شبکه شما یافت نشد',
			'companionRemote.pairing.noDevicesHint' => 'PlezyNG را در دسکتاپ باز کنید و از همان Wi-Fi استفاده کنید.',
			'companionRemote.pairing.availableDevices' => 'تجهیزات موجود',
			'companionRemote.pairing.manualConnection' => 'اتصال دستی',
			'companionRemote.pairing.cryptoInitFailed' => 'امکان اتصال امن را شروع نکنید.اول با شماره Plex ثبت نام کنید.',
			'companionRemote.pairing.validationHostRequired' => 'لطفا آدرس میزبان را وارد کنید',
			'companionRemote.pairing.validationHostFormat' => 'فرمت باید IP:port باشد (به عنوان مثال 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'استفاده از شبکه در هر دو دستگاه',
			'companionRemote.pairing.sessionNotFound' => 'دستگاه یافت نشد اطمینان حاصل کنید که PlezyNG در میزبان اجرا می شود.',
			'companionRemote.pairing.authFailed' => 'هر دو دستگاه به همان حساب Plex نیاز دارند.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'عدم اتصال: ${error}',
			'companionRemote.pairing.codeTitle' => 'کد زوجی',
			'companionRemote.pairing.codeDescription' => 'کد نمایش داده شده در Companion Remote را در دستگاه میزبان وارد کنید.هر دو دستگاه باید از نسخه ای استفاده کنند که از یک جفت امن پشتیبانی می کند.',
			'companionRemote.pairing.codeInvalid' => 'تمام 32 حرف و اعداد را از کد میزبان وارد کنید.',
			'companionRemote.pairing.updateRequired' => 'به روز رسانی هر دو دستگاه به نسخه ای که از پیوند امن پشتیبانی می کند.',
			'companionRemote.pairing.hostDescription' => 'این کد را یک بار در هر ردیف وارد کنید.این کد را خصوصی نگه دارید: کنترل این پروفایل را فراهم می کند.',
			'companionRemote.pairing.resetCode' => 'بازگرداندن کد زوج',
			'companionRemote.pairing.resetDescription' => 'تمام فاصله ها را قطع کنید و یک کد جدید ایجاد کنید.هر فاصله باید دوباره با هم ارتباط برقرار کند.',
			'companionRemote.remote.disconnectConfirm' => 'آیا می خواهید از جلسه از راه دور خارج شوید؟',
			'companionRemote.remote.reconnecting' => 'دوباره اتصال...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'تلاش ${current} از 5',
			'companionRemote.remote.retryNow' => 'بازگشت اکنون',
			'companionRemote.remote.tabRemote' => 'فاصله',
			'companionRemote.remote.tabPlay' => 'اجرا کردن',
			'companionRemote.remote.tabMore' => 'بیشتر',
			'companionRemote.remote.menu' => 'فهرست',
			'companionRemote.remote.tabNavigation' => 'برچسب ها Navigation',
			'companionRemote.remote.tabDiscover' => 'کشف',
			'companionRemote.remote.tabLibraries' => 'کتابخانه‌ها',
			'companionRemote.remote.tabSearch' => 'جستجو کردن',
			'companionRemote.remote.tabDownloads' => 'بارگیری‌ها',
			'companionRemote.remote.tabSettings' => 'تنظیمات',
			'companionRemote.remote.previous' => 'قبلی',
			'companionRemote.remote.playPause' => 'بازی / استراحت',
			'companionRemote.remote.next' => 'بعدی',
			'companionRemote.remote.seekBack' => 'بازگشت جستجو',
			'companionRemote.remote.stop' => 'توقف',
			'companionRemote.remote.seekForward' => 'جستجو FWD',
			'companionRemote.remote.volume' => 'حجم',
			'companionRemote.remote.volumeDown' => 'پایین',
			'companionRemote.remote.volumeUp' => 'بالا',
			'companionRemote.remote.fullscreen' => 'تمام صفحه',
			'companionRemote.remote.subtitles' => 'زیرنویس‌ها',
			'companionRemote.remote.audio' => 'صدا',
			'companionRemote.remote.searchHint' => 'جستجو در دسکتاپ',
			'companionRemote.errors.noNetworkInterface' => 'هیچ رابط شبکه یافت نشد',
			'companionRemote.errors.authenticationFailed' => 'تصدیق شکست خورد',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'عدم راه اندازی سرور از راه دور: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'عدم ارسال دستور از راه دور: ${error}',
			'companionRemote.errors.joinTimedOut' => 'زمان ورود به جلسه',
			'companionRemote.errors.failedToConnectAnyAddress' => 'عدم دسترسی به هر آدرس',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'اتصال از دست رفته پس از تلاش های ${attempts}',
			'companionRemote.errors.connectionLost' => 'اتصال از دست رفته',
			'companionRemote.closedBeforeAuth' => 'اتصال قبل از تأیید بسته شد',
			'videoSettings.playbackSpeed' => 'سرعت پخش',
			'videoSettings.normalSpeed' => 'طبیعی',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'فعال (${duration})',
			'videoSettings.zoom' => 'پوشش دادن',
			'videoSettings.sleepTimer' => 'زمان خواب',
			'videoSettings.audioSync' => 'صدا همگام',
			'videoSettings.subtitleSync' => 'زیرنویس Sync',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'HDR در اینجا در دسترس نیست - این سازنده دسکتاپ یا خروجی ویدئویی نمی تواند آن را حمل کند.',
			'videoSettings.hdrToneMapping' => 'HDR Tone نقشه برداری',
			'videoSettings.hdrToneMappingCompositor' => 'سازنده',
			'videoSettings.hdrToneMappingCompositorDescription' => 'از طریق متادیت های HDR منبع عبور کنید و به نقشه سازنده دسکتاپ اجازه دهید.',
			'videoSettings.hdrToneMappingPlayer' => 'پخش‌کننده',
			'videoSettings.hdrToneMappingPlayerDescription' => 'نقشه تا درخشش بالای صفحه نمایش در بازیکن، سپس به آهنگساز نتیجه را بگویید.',
			'videoSettings.hdrToneMappingFailed' => 'نمی توانم نقشه برداری رنگ HDR را تغییر دهم - حالت قبلی هنوز فعال است.',
			'videoSettings.audioOutput' => 'صدا خروجی',
			'videoSettings.videoTrack' => 'مسیر ویدیو',
			'videoSettings.videoTrackDescription' => 'انتخاب کنید کدام جریان ویدیو نمایش داده شود. هنگام پخش با MPV، اگر فایل مسیرهای ویدیوی جایگزین داشته باشد، در دسترس است.',
			'videoSettings.videoTrackDefault' => 'پیش‌فرض',
			'videoSettings.videoTrackUnavailable' => 'مسیر ویدیوی جایگزینی در دسترس نیست.',
			'videoSettings.videoTrackFailed' => 'تغییر مسیر ویدیو ممکن نشد.',
			'videoSettings.videoTrackNumber' => ({required Object id}) => 'مسیر ${id}',
			'videoSettings.performanceOverlay' => 'عملکرد Overlay',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'اطراف',
			'videoSettings.audioOutputSpatial' => 'فضای صوتی',
			'videoSettings.audioOutputStereo' => 'استریو',
			'videoSettings.audioEqualizer' => 'صدا معادل',
			'videoSettings.audioEqualizerDescription' => 'معادل 10 باند برای MPVفیلترهای صوتی از صدا های رمزگذاری شده استفاده می کنند و به طور مناسب خاموش می شوند.',
			'videoSettings.audioEqualizerFlat' => 'مسطح',
			'videoSettings.audioEqualizerActive' => 'سفارشی',
			'videoSettings.audioEqualizerSaveFailed' => 'نمی توانم تنظیمات معادل صوتی را ذخیره کنم.',
			'videoSettings.audioEffectsDescription' => 'اثرات از صدا رمزگذاری شده استفاده می کنند، بنابراین passthrough از بین می رود. فضای اتاق و گسترش استریو بستگی به MPV ساخت و ردیابی',
			'videoSettings.audioStereoWidth' => 'استریو گسترش',
			'videoSettings.audioSpatializer' => 'فضای اتاق',
			'videoSettings.audioSpatializerDescription' => 'بازخورد اتاق آرام را اضافه کنید.',
			'videoSettings.audioPitch' => 'پیتزا تغییر',
			'videoSettings.audioPitchDescription' => 'تغییر مسیر بدون تغییر سرعت MPV ساخت باید شامل Rubber Band.',
			'videoSettings.audioEffectUnavailable' => 'این اثر برای این مسیر در دسترس نیست یا MPV ساختن .',
			'videoSettings.backgroundVideoAudio' => 'ویدئو ویدئو صدا',
			'videoSettings.backgroundVideoAudioDescription' => 'بازی ویدئویی را در هنگام ترک پخش کننده نگه دارید؛ تصویر تا زمانی که بازگردید پنهان است. Android از یک اطلاعیه پخش رسانه استفاده می کند.',
			'videoSettings.audioNormalization' => 'صدا را عادی کنید',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'دکود صوتی به PCM؛ passthrough در حالی که این در',
			'performanceOverlay.color' => 'رنگ ها',
			'performanceOverlay.performance' => 'کارایی',
			'performanceOverlay.buffer' => 'بوفری',
			'performanceOverlay.app' => 'برنامه',
			'performanceOverlay.decoder' => 'دکوراسیون',
			'performanceOverlay.rawDecoder' => 'دکوراسیون خام',
			'performanceOverlay.tunneling' => 'تونل',
			'performanceOverlay.passthrough' => 'پازل',
			'performanceOverlay.aspect' => 'دیدگاه',
			'performanceOverlay.rotation' => 'چرخش',
			'performanceOverlay.dvSource' => 'منبع DV',
			'performanceOverlay.dvPath' => 'راه دو',
			'performanceOverlay.dvRouteDecoder' => 'Dolby Vision دکوراسیون',
			'performanceOverlay.dvRouteDecoderP81' => 'Dolby Vision دکوراسیون (P7→8.1)',
			'performanceOverlay.dvRouteBaseLayer' => 'لایه پایه',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'HDR10 لایه پایه',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'لایه پایه HLG',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'SDR لایه پایه',
			'performanceOverlay.dvRouteReshaped' => 'RPU بازسازی شده (gpu-next)',
			'performanceOverlay.dvRouteFelGraphActive' => 'گرافیک آزمایشی P7 FEL (غیر واجد شرایط)',
			'performanceOverlay.p7Conversion' => 'P7 کنف',
			'performanceOverlay.sampleRate' => 'نرخ نمونه',
			'performanceOverlay.pixelFormat' => 'پیکسل Fmt',
			'performanceOverlay.hwFormat' => 'فای فای فای',
			'performanceOverlay.matrix' => 'ماتریکس',
			'performanceOverlay.primaries' => 'اولویت ها',
			'performanceOverlay.transfer' => 'انتقال',
			'performanceOverlay.renderFps' => 'رندر FPS',
			'performanceOverlay.displayFps' => 'نمایش FPS',
			'performanceOverlay.avSync' => 'A / V همگام سازی',
			'performanceOverlay.dropped' => 'سقوط',
			'performanceOverlay.dvRpus' => 'DV RPU',
			'performanceOverlay.dvRpuAverage' => 'آرشیو برچسب: AVG',
			'performanceOverlay.dvSampleAverage' => 'نمونه های AVG',
			'performanceOverlay.maxLuma' => 'مکس لوما',
			'performanceOverlay.minLuma' => 'مینی لوما',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'استفاده از Cache',
			'performanceOverlay.cacheLimit' => 'محدودیت کاسه',
			'performanceOverlay.speed' => 'سرعت',
			'performanceOverlay.player' => 'پخش‌کننده',
			'performanceOverlay.playMethod' => 'نحوه پخش',
			'performanceOverlay.memory' => 'حافظه',
			'performanceOverlay.uiFps' => 'FPS FPS',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android HW',
			'performanceOverlay.decoderNvidiaHw' => 'NVIDIA HW',
			'performanceOverlay.decoderQualcommHw' => 'کوالکام HW',
			'performanceOverlay.decoderMediatekHw' => 'رسانه ها HW',
			'performanceOverlay.decoderExynosHw' => 'بیوگرافی HW',
			'performanceOverlay.decoderSoftware' => 'نرم افزار',
			'performanceOverlay.decoderHardware' => 'سخت افزار',
			'performanceOverlay.tunnelingActive' => 'فعال',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted} (${failures} شکست خورده)',
			'externalPlayer.title' => 'بازیکن خارجی',
			'externalPlayer.useExternalPlayer' => 'استفاده از بازیکن خارجی',
			'externalPlayer.useExternalPlayerDescription' => 'باز کردن ویدئوها در یک برنامه دیگر',
			'externalPlayer.selectPlayer' => 'انتخاب بازیکن',
			'externalPlayer.customPlayers' => 'بازیکنان سفارشی',
			'externalPlayer.systemDefault' => 'سیستم پیش فرض',
			'externalPlayer.addCustomPlayer' => 'اضافه کردن Custom Player',
			'externalPlayer.playerName' => 'نام بازیکن',
			'externalPlayer.playerNameHint' => 'بازیکن من',
			'externalPlayer.playerCommand' => 'فرمانده',
			'externalPlayer.playerPackage' => 'نام بسته',
			'externalPlayer.playerUrlScheme' => 'برنامه URL',
			'externalPlayer.off' => 'خاموش',
			'externalPlayer.launchFailed' => 'عدم باز کردن بازیکن خارجی',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} نصب نشده است',
			'externalPlayer.playInExternalPlayer' => 'بازی در بازیکن خارجی',
			'externalPlayer.description' => 'برنامه دیگری را برای باز کردن ویدئوها انتخاب کنید بازیکنان در دسترس به دستگاه و برنامه های نصب شده شما بستگی دارند.',
			'externalPlayer.systemDefaultDescription' => 'اجازه دهید سیستم عامل ویدئو را با برنامه پیش فرض خود باز کند.',
			'externalPlayer.playerOptionDescription' => ({required Object player}) => 'ویدئوها را با ${player} باز کنید.',
			'externalPlayer.playerNameDescription' => 'برچسب نشان داده شده در لیست بازیکنان.',
			'externalPlayer.playerPackageDescription' => 'نام بسته اندروید را از اپلیکیشن بازیکن وارد کنید، مانند com.example.player.',
			'externalPlayer.playerCommandDescription' => 'دستور یا مسیر اجرا شده برای این دستگاه را وارد کنید.',
			'externalPlayer.playerUrlSchemeDescription' => 'نمودار URL و قالب URL اختیاری مورد استفاده برای راه اندازی بازیکن را وارد کنید.',
			'metadataEdit.editMetadata' => 'ویرایش',
			'metadataEdit.screenTitle' => 'ویرایش فراداده',
			'metadataEdit.basicInfo' => 'اطلاعات پایه',
			'metadataEdit.artwork' => 'هنری',
			'metadataEdit.advancedSettings' => 'تنظیمات پیشرفته',
			'metadataEdit.title' => 'عنوان',
			'metadataEdit.sortTitle' => 'مرتب‌سازی عنوان',
			'metadataEdit.originalTitle' => 'عنوان اصلی',
			'metadataEdit.releaseDate' => 'تاریخ انتشار',
			'metadataEdit.contentRating' => 'محتوای رتبه بندی',
			'metadataEdit.studio' => 'استودیو',
			'metadataEdit.tagline' => 'تگ لاین',
			'metadataEdit.summary' => 'خلاصه ای',
			'metadataEdit.poster' => 'پوستر',
			'metadataEdit.background' => 'پس زمینه',
			'metadataEdit.logo' => 'لوگو',
			'metadataEdit.squareArt' => 'میدان هنر',
			'metadataEdit.selectPoster' => 'انتخاب پوستر',
			'metadataEdit.selectBackground' => 'انتخاب پس زمینه',
			'metadataEdit.selectLogo' => 'انتخاب لوگو',
			'metadataEdit.selectSquareArt' => 'انتخاب میدان هنر',
			'metadataEdit.fromUrl' => 'از URL',
			'metadataEdit.uploadFile' => 'دانلود فایل',
			'metadataEdit.enterImageUrl' => 'URL تصویر را وارد کنید',
			'metadataEdit.imageUrl' => 'تصویر URL',
			'metadataEdit.metadataUpdated' => 'Metadata به روز شده',
			'metadataEdit.metadataUpdateFailed' => 'عدم به روز رسانی متا',
			'metadataEdit.artworkUpdated' => 'هنر به روز شده',
			_ => null,
		} ?? switch (path) {
			'metadataEdit.artworkUpdateFailed' => 'به روز رسانی هنرهای هنری',
			'metadataEdit.noArtworkAvailable' => 'هیچ هنری در دسترس نیست',
			'metadataEdit.artworkOption' => ({required Object index}) => 'گزینه هنری ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'گزینه هنری ${index} انتخاب شده',
			'metadataEdit.notSet' => 'نه تنظیم',
			'metadataEdit.libraryDefault' => 'کتابخانه های ناشناخته',
			'metadataEdit.accountDefault' => 'حساب های جعلی',
			'metadataEdit.seriesDefault' => 'سری دیپلماسی',
			'metadataEdit.episodeSorting' => 'قسمت دسته بندی',
			'metadataEdit.oldestFirst' => 'قدیمی ترین اول',
			'metadataEdit.newestFirst' => 'جدیدترین اول',
			'metadataEdit.keep' => 'نگه داشتن',
			'metadataEdit.allEpisodes' => 'تمام قسمت‌ها',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} آخرین قسمت ها',
			'metadataEdit.latestEpisode' => 'آخرین قسمت',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'قسمت های اضافه شده در روزهای گذشته ${count}',
			'metadataEdit.deleteAfterPlaying' => 'حذف قسمت ها پس از بازی',
			'metadataEdit.never' => 'هرگز',
			'metadataEdit.afterADay' => 'بعد از یک روز',
			'metadataEdit.afterAWeek' => 'بعد از یک هفته',
			'metadataEdit.afterAMonth' => 'پس از یک ماه',
			'metadataEdit.onNextRefresh' => 'بعدی تمیز کردن',
			'metadataEdit.seasons' => 'فصل ها',
			'metadataEdit.show' => 'نمایش',
			'metadataEdit.hide' => 'پنهان کردن',
			'metadataEdit.episodeOrdering' => 'قسمت سفارش',
			'metadataEdit.tmdbAiring' => 'پایگاه داده فیلم (Aired)',
			'metadataEdit.tvdbAiring' => 'تئاتر دبی (Aired)',
			'metadataEdit.tvdbAbsolute' => 'دانلود فیلم TheTVDB (Absolute)',
			'metadataEdit.metadataLanguage' => 'زبان متا',
			'metadataEdit.useOriginalTitle' => 'استفاده از عنوان اصلی',
			'metadataEdit.preferredAudioLanguage' => 'اولویت زبان صدا',
			'metadataEdit.preferredSubtitleLanguage' => 'زبان زیرنویس ترجیحی',
			'metadataEdit.subtitleMode' => 'حالت انتخاب خودکار Subtitle',
			'metadataEdit.manuallySelected' => 'انتخاب دستی',
			'metadataEdit.shownWithForeignAudio' => 'نمایش با صدا خارجی',
			'metadataEdit.alwaysEnabled' => 'همیشه امکان پذیر',
			'metadataEdit.tags' => 'برچسب‌ها',
			'metadataEdit.addTag' => 'اضافه کردن Tag',
			'metadataEdit.genre' => 'ژانر',
			'metadataEdit.director' => 'کارگردان',
			'metadataEdit.writer' => 'نویسنده',
			'metadataEdit.producer' => 'تولید کننده',
			'metadataEdit.country' => 'کشور',
			'metadataEdit.collection' => 'مجموعه',
			'metadataEdit.label' => 'برچسب ها',
			'metadataEdit.quickTag' => 'Tag سریع...',
			'matchScreen.match' => 'مسابقه...',
			'matchScreen.fixMatch' => 'مسابقه اصلاحی...',
			'matchScreen.unmatch' => 'عدم مسابقه',
			'matchScreen.unmatchConfirm' => 'این بازی را روشن کنید؟ Plex آن را به عنوان نامناسب تا به پایان رسید.',
			'matchScreen.unmatchSuccess' => 'موضوع ناخوشایند',
			'matchScreen.unmatchFailed' => 'شکست ناپذیر در بازی',
			'matchScreen.matchApplied' => 'مسابقه اعمال شد',
			'matchScreen.matchFailed' => 'شکست در اجرای بازی',
			'matchScreen.titleHint' => 'عنوان',
			'matchScreen.yearHint' => 'سال',
			'matchScreen.search' => 'جستجو کردن',
			'matchScreen.noMatchesFound' => 'هیچ مسابقه ای یافت نشد',
			'serverTasks.title' => 'کارهای سرور',
			'serverTasks.failedToLoad' => 'شکست در انجام وظایف',
			'serverTasks.noTasks' => 'هیچ وظیفه ای اجرا نمی شود',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'اتصال',
			'trakt.connectedAs' => ({required Object username}) => 'به عنوان @${username} متصل شده است',
			'trakt.disconnectConfirm' => 'حساب کاربری Trakt را قطع کنید.',
			'trakt.disconnectConfirmBody' => 'PlezyNG ارسال رویدادها را به Trakt متوقف می کند.',
			'trakt.scrobble' => 'زمان واقعی Scrobbling',
			'trakt.scrobbleDescription' => 'ارسال بازی، استراحت و توقف رویدادهای به Trakt در هنگام پخش.',
			'trakt.watchedSync' => 'Sync وضعیت مشاهده شده',
			'trakt.watchedSyncDescription' => 'هنگامی که شما آیتم ها را به عنوان مشاهده شده در PlezyNG نشان می دهید، آنها نیز به عنوان مشاهده شده در Trakt نشان داده می شوند.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'اتصال به Seerr',
			'seerr.serverUrl' => 'سرور URL',
			'seerr.serverUrlHelper' => 'آدرس مورد نظر شما',
			'seerr.checkServer' => 'ادامه مطلب',
			'seerr.signInWithJellyfin' => 'ثبت نام با شماره Jellyfin',
			'seerr.signInWithEmby' => 'ثبت نام با شماره Emby',
			'seerr.signInWithLocal' => 'استفاده از حساب محلی',
			'seerr.email' => 'ایمیل',
			'seerr.noSignInMethods' => 'این مثال Seerr هیچ پشتیبانی از روش ثبت نام PlezyNG را ارائه نمی دهد.',
			'seerr.instance' => 'مواردی',
			'seerr.disconnectConfirm' => 'از بین بردن سیم کارت؟',
			'seerr.disconnectConfirmBody' => 'PlezyNG این مثال را فراموش خواهد کرد.در هر زمان دوباره اتصال.',
			'seerr.request' => 'درخواست',
			'seerr.request4k' => 'درخواست در 4K',
			'seerr.seasons' => 'فصل ها',
			'seerr.allSeasons' => 'همه فصل ها',
			'seerr.advancedOptions' => 'پیشرفته',
			'seerr.destinationServer' => 'سرور مقصد',
			'seerr.qualityProfile' => 'پروفایل کیفیت',
			'seerr.rootFolder' => 'فاکتور ریشه',
			'seerr.languageProfile' => 'پروفایل زبان',
			'seerr.tags' => 'برچسب‌ها',
			'seerr.noTags' => 'هیچ تگ',
			'seerr.defaultOption' => ({required Object name}) => '${name} (به طور پیش فرض)',
			'seerr.animeNote' => 'این سریال یک انیمه است.',
			'seerr.requestSubmitted' => 'درخواست ارسال شده',
			'seerr.requestFailed' => ({required Object error}) => 'درخواست شکست خورده: ${error}',
			'seerr.requestsLoadFailed' => 'نمی توانم گزینه های درخواست را بارگذاری کنم',
			'seerr.nothingToRequest' => 'همه چیز در دسترس است یا درخواست شده است.',
			'seerr.statusAvailable' => 'در دسترس',
			'seerr.statusPartiallyAvailable' => 'به طور جزئی در دسترس',
			'seerr.statusRequested' => 'درخواست شده',
			'seerr.statusProcessing' => 'پردازش',
			'seerr.statusBlocklisted' => 'مسدود شده',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => 'نمی تواند به ${url} برسد: ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => 'بدون درخواست Seerr در ${url} (HTTP ${status})',
			'seerr.behindAuthProxy' => 'یک پروکسی واقعی (SSO یا HTTP auth) به جای Seerr پاسخ داده شده است. PlezyNG نمی تواند از طریق آن ثبت نام کند: اجازه دهید مسیر /api/v1 Seerr از طریق پروکسی برای این برنامه عبور کند یا از یک آدرس که به طور مستقیم به Seerr می رسد استفاده کنید.',
			'seerr.invalidUrl' => 'آدرس سرور مانند https://seerr.example.com را وارد کنید',
			'seerr.quickConnectUnsupported' => 'این مثال Seerr از Quick Connect پشتیبانی نمی کند.این مثال نیاز به Seerr 3.4 یا جدیدتر دارد.',
			'seerr.notInitialized' => 'این حالت Seerr نصب اولیه را تکمیل نکرده است',
			'seerr.noPlexTokenForReauth' => 'شماره Plex توکن برای ثبت نام مجدد در دسترس است',
			'seerr.noStoredCredentials' => 'اطلاعات ورود ذخیره‌شده‌ای برای ورود دوباره در دسترس نیست',
			'seerr.signInRejected' => 'ثبت نام رد شد',
			'seerr.noSessionCookie' => 'Seerr یک کوکی جلسه را منتشر نکرده است',
			'seerr.freshCookieRejected' => 'Seerr کوکی جلسه جدید را رد کرد',
			'seerr.noUserInformation' => 'Seerr اطلاعات کاربر را بازگرداند',
			'seerr.sessionRejectedAfterReauth' => 'جلسه پس از امضای مجدد رد شد.',
			'seerr.permissionDenied' => 'Seerr این اقدام را رد کرد: حساب شما دیگر مجوز مورد نیاز را ندارد',
			'seerr.permissionRevoked' => 'شما دیگر اجازه درخواست این کار را ندارید.',
			'services.title' => 'خدمات',
			'services.hubSubtitle' => 'Sync پیشرفت را مشاهده می کند و از عنوان های جدید درخواست می کند.',
			'services.integrations' => 'ادغام',
			'services.notConnected' => 'نه متصل',
			'services.connectedAs' => ({required Object username}) => 'به عنوان @${username} متصل شده است',
			'services.scrobble' => 'پیشرفت خودکار را ردیابی کنید',
			'services.scrobbleDescription' => 'لیست خود را به روز کنید زمانی که شما یک قسمت یا فیلم را به پایان می رسانید.',
			'services.disconnectConfirm' => ({required Object service}) => 'اتصال به ${service}',
			'services.disconnectConfirmBody' => ({required Object service}) => 'PlezyNG به روز رسانی را متوقف می کند ${service}.',
			'services.connectFailed' => ({required Object service}) => 'من نمی توانم به ${service} متصل شوم.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'اتصال مجدد Simkl',
			'services.simklReconnect.subtitle' => 'Simkl از روش ثبت نام خارج می شود این اتصال استفاده می کند. دوباره اتصال simkl.com را برای تایید PlezyNG - PlezyNG هرگز رمز عبور شما را نمی بیند. تاریخچه ساعت شما در Simkl باقی می ماند.',
			'services.deviceCode.title' => ({required Object service}) => 'فعال کردن PlezyNG در ${service}',
			'services.deviceCode.instructions' => 'کد QR را اسکن کنید یا به آدرس زیر مراجعه کنید و این کد را وارد کنید:',
			'services.deviceCode.openToActivate' => ({required Object service}) => '${service} را برای فعال کردن باز کنید',
			'services.deviceCode.copyCode' => 'کپی کد فعال سازی',
			'services.deviceCode.waitingForAuthorization' => 'منتظر صدور مجوز...',
			'services.deviceCode.codeCopied' => 'کد کپی شده',
			'services.oauthProxy.title' => ({required Object service}) => 'ثبت نام در ${service}',
			'services.oauthProxy.body' => 'این کد QR را اسکن کنید یا URL را در هر دستگاه باز کنید.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => '${service} را برای ثبت نام باز کنید',
			'services.pendingAuth.copyUrl' => 'کپی کردن Sign-in URL',
			'services.pendingAuth.urlCopied' => 'URL کپی شده',
			'services.libraryFilter.title' => 'کتابخانه فیلتر',
			'services.libraryFilter.subtitleAllSyncing' => 'همگام سازی تمام کتابخانه ها',
			'services.libraryFilter.subtitleNoneSyncing' => 'هیچ چیز همگام نمی شود',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} مسدود شده',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} مجاز است',
			'services.libraryFilter.mode' => 'فیلتر حالت',
			'services.libraryFilter.modeBlacklist' => 'لیست سیاه',
			'services.libraryFilter.modeWhitelist' => 'لیست سفید',
			'services.libraryFilter.modeHintBlacklist' => 'همه کتابخانه ها را به جز کتابخانه های زیر همگام کنید.',
			'services.libraryFilter.modeHintWhitelist' => 'فقط کتابخانه هایی که در زیر بررسی شده اند را همگام کنید.',
			'services.libraryFilter.libraries' => 'کتابخانه‌ها',
			'services.libraryFilter.noLibraries' => 'هیچ کتابخانه ای در دسترس نیست',
			'services.libraryFilter.modeDescription' => 'انتخاب کنید که آیا کتابخانه های چک شده از همگام سازی مسدود شده اند یا تنها کتابخانه هایی هستند که همگامه می کنند.',
			'services.seerrDescription' => 'برای جستجوی عنوان ها و ارسال درخواست های رسانه ای به Seerr یا Overseerr متصل شوید.',
			'services.trackerDescriptions.trakt' => 'همگام سازی قسمت ها و فیلم های تماشا شده با حساب تراکت شما.',
			'services.trackerDescriptions.mal' => 'همگام سازی لیست های انیمه و تماشای پیشرفت با MyAnimeList.',
			'services.trackerDescriptions.anilist' => 'همگام سازی لیست های انیمه و تماشای پیشرفت با AniList.',
			'services.trackerDescriptions.simkl' => 'سینک فیلم ها، نمایش های تلویزیونی و انیمه را با Simkl تماشا کرد.',
			'services.trackerDescriptions.mdblist' => 'نمایش رتبه های MDBList و لیست ها در توصیه ها و کشف.',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => 'اضافه کردن سرور ${product}',
			'addServer.serverUrls' => 'سرور URL',
			'addServer.serverUrlsHelper' => 'URL های چندگانه مجاز، جدا شده توسط commas.',
			'addServer.findServer' => 'سرور را پیدا کنید',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'در جستجوی سرورهای محلی ${product} ...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'سرورهای محلی ${product}',
			'addServer.username' => 'نام کاربری',
			'addServer.password' => 'گذرواژه',
			'addServer.signIn' => 'ورود',
			'addServer.change' => 'تغییر',
			'addServer.required' => 'نیاز به',
			'addServer.couldNotReachServer' => ({required Object error}) => 'نمی توانم به سرور دسترسی داشته باشم: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'ثبت نام شکست خورده: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect شکست خورده: ${error}',
			'addServer.addPlexTitle' => 'ثبت نام با شماره Plex',
			'addServer.pinExpired' => 'PIN قبل از ثبت نام به پایان رسیده است لطفا دوباره امتحان کنید.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'عدم ثبت حساب: ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => 'URL سرور ${product} را وارد کنید.',
			'addServer.addConnectionTitle' => 'اضافه کردن اتصال',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'اضافه کردن به ${name}',
			'addServer.signInWithPlexCard' => 'ثبت نام با شماره Plex',
			'addServer.signInWithPlexCardSubtitle' => 'این دستگاه را مجاز کنید سرورهای به اشتراک گذاشته شده اضافه می شوند.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'مجوز یک حساب Plex. کاربران خانگی تبدیل به پروفایل.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => 'تماس با ${product}',
			'addServer.connectToMediaBrowserCardSubtitle' => 'URL سرور، نام کاربری و رمز عبور خود را وارد کنید.',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => 'ثبت نام در سرور ${product} شما. اتصال به ${name}.',
			'addServer.borrowFromAnotherProfile' => 'وام از یک پروفایل دیگر',
			'addServer.borrowFromAnotherProfileSubtitle' => 'استفاده مجدد از اتصال پروفایل دیگری. پروفایل های محافظت شده از PIN نیاز به یک PIN دارند.',
			'addServer.invalidCredentials' => 'نام کاربری یا رمز عبور نادرست',
			'addServer.authResponseNotJson' => 'پاسخ صدور گواهینامه معتبر نبود JSON',
			'addServer.authResponseIncomplete' => 'پاسخ ورود از سرور نامناسب بود.',
			'addServer.quickConnectRejected' => 'Quick Connect توسط سرور رد شد',
			'addServer.quickConnectNotJson' => 'پاسخ Quick Connect معتبر نبود JSON',
			'addServer.quickConnectMissingFields' => 'پاسخ Quick Connect یک کد یا راز را از دست می دهد',
			'addServer.quickConnectPollRejected' => 'Quick Connect درخواست توسط سرور رد شد',
			'addServer.serverTimedOut' => 'سرور به موقع پاسخ نمی دهد',
			'addServer.responseNotJson' => 'پاسخ سرور معتبر نبود JSON',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'پاسخ یک شناسه یا نام سرور را از دست می دهد - آیا این یک سرور ${product} است؟',
			'addServer.probeFailed' => ({required Object error}) => 'نمی توانم به سرور دسترسی داشته باشم: ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => 'حداقل یک URL سرور ${product} را وارد کنید.',
			'addServer.noReachableServer' => ({required Object product}) => 'هیچ سرور قابل دسترس ${product} یافت نشد',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'این URL ها به سرورهای مختلف ${product} اشاره می کنند.',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'این URL مطابق با سرور ${product} نیست.',
			'addServer.redirectUnsupported' => 'سرور به یک URL پشتیبانی نشده هدایت می شود',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'سرور به یک میزبان متفاوت هدایت شده است.در URL نهایی ${product} به طور مستقیم وارد کنید.',
			'addServer.redirectInsecure' => 'سرور از HTTPS به یک URL نامناسب هدایت شده است',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'سرور به یک URL پشتیبانی نشده هدایت شده است.در URL نهایی ${product} به طور مستقیم وارد کنید.',
			'addServer.directPlexServerUrl' => 'Plex سرور URL',
			'addServer.directPlexServerUrlHelper' => 'IP محلی و پورت سرور رسانه Plex را وارد کنید.',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex توکن (اختیاری)',
			'addServer.plexTokenHelper' => 'اگر دسترسی بدون auth در این سرور مجاز است، آن را خالی نگه دارید.',
			'addServer.plexTokenRequired' => 'لطفا توکن Plex خود را وارد کنید (X-Plex-Token).',
			'addServer.connectDirectPlexCard' => 'Plex سرور رسانه ای (مستقیم / محلی)',
			'addServer.connectDirectPlexCardSubtitle' => 'اتصال مستقیم با استفاده از IP یا URL محلی بدون حساب plex.tv.',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => 'با استفاده از IP یا URL محلی به طور مستقیم به آن متصل شوید.به ${name} متصل شوید.',
			'addServer.insecureTitle' => 'اتصال بدون رمزگذاری',
			'addServer.insecureDescription' => ({required Object url}) => '${url} از HTTP استفاده می‌کند. افراد حاضر در شبکه ممکن است گذرواژه، توکن‌ها و رسانه‌های شما را بخوانند یا تغییر دهند. در صورت امکان از HTTPS استفاده کنید. فقط اگر به این شبکه اعتماد دارید و خطر را می‌پذیرید ادامه دهید.',
			'addServer.allowHttp' => 'اجازه دادن به HTTP',
			'addServer.httpsRequired' => 'استفاده از HTTPS یا به صراحت اجازه یک اتصال غیر رمزگذاری شده.',
			'cast.chooseDevice' => 'پخش روی دستگاه',
			'cast.searching' => 'در جستجوی دستگاه های...',
			'cast.connectedTo' => ({required Object device}) => 'به ${device} متصل شده است.',
			'cast.device' => 'دستگاه پخش',
			'cast.readyToCast' => 'آمادهٔ پخش روی دستگاه',
			'cast.subtitle' => 'زیرنویس‌ها',
			'cast.serverNotAvailable' => 'سرور رسانه ای در دسترس نیست.',
			'cast.stopCasting' => 'توقف پخش روی دستگاه',
			'cast.castToDevice' => 'پخش روی دستگاه',
			'cast.noEpisodeAvailable' => 'هیچ قسمت ای برای پخش در دسترس نیست.',
			'cast.startFailed' => 'نمی توانم شروع به کاستینگ کنم، سرور را چک کنید و دوباره امتحان کنید.',
			'automation.noActivePlayback' => 'هیچ جلسه ویدئویی فعال برای کنترل وجود ندارد.',
			'notifications.newEpisodeTitle' => 'قسمت جدید',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appAccess.title' => 'سعی کنید هر ویژگی را به صورت رایگان برای 7 روز امتحان کنید',
			'appAccess.description' => 'یک آزمون هفت روزه را با دسترسی کامل به هر ویژگی PlezyNG آغاز کنید.در طول آزمون هیچ هزینه ای وجود ندارد و هیچ اشتراک ای وجود ندارد.پس از آزمون، یک خرید عمر در قیمت فروشگاه شما PlezyNG را برای یک عمر باز می کند.',
			'appAccess.trialEndedDescription' => 'باز کردن هر ویژگی در PlezyNG برای زندگی با یک خرید در قیمت فروشگاه شما.',
			'appAccess.startTrial' => 'امتحان هفت روزه رایگان من را آغاز کنید',
			'appAccess.trialActive' => 'آزمون 7 روزه شما فعال است.',
			'appAccess.trialEnded' => 'دادگاه هفت روزه شما به پایان رسیده است',
			'appAccess.trialStartFailed' => 'من نمی توانم آزمایش را در این دستگاه ذخیره کنم لطفا دوباره امتحان کنید.',
			'appAccess.lifetimeTitle' => 'PlezyNG برای زندگی باز شده است',
			'appAccess.lifetimeBody' => 'با تشکر از شما، شما دسترسی طول عمر به هر ویژگی PlezyNG دارید.',
			'appAccess.manageTitle' => 'PlezyNG دسترسی طول عمر',
			'appAccess.manageDescription' => 'سعی کنید هر ویژگی را به مدت 7 روز رایگان کنید، سپس همه چیز را برای زندگی با یک پرداخت در قیمت فروشگاه خود باز کنید.',
			'appAccess.buy' => ({required Object price}) => 'باز کردن هر ویژگی برای ${price}',
			'appAccess.loadingPrice' => 'قیمت فروشگاه...',
			'appAccess.retryPrice' => 'بازگشت قیمت جستجو',
			'appAccess.restore' => 'بازگرداندن خرید عمر',
			'appAccess.pending' => 'خرید شما در انتظار پرداخت یا تایید است. دسترسی طول عمر بلافاصله پس از فروشگاه آن را تکمیل می کند.',
			'appAccess.storeUnavailable' => 'خرید در دسترس نیست چک کنید که شما در فروشگاه ثبت نام کرده اید و خرید در این دستگاه مجاز است.',
			'appAccess.productNotFound' => 'خرید دسترسی مادام‌العمر PlezyNG هنوز در این فروشگاه موجود نیست.',
			'appAccess.productQueryFailed' => 'نمی توانم قیمت فروشگاه را بارگذاری کنم، اتصال خود را بررسی کنید و دوباره امتحان کنید.',
			'appAccess.purchaseFailed' => 'خرید به پایان نرسید، دوباره امتحان کنید.',
			'appAccess.restoreFailed' => 'من نمی توانستم به فروشگاه بروم تا خرید خود را بازگردانم.',
			'appAccess.nothingToRestore' => 'شماره PlezyNG خرید طول عمر برای این حساب فروشگاه یافت شد.',
			'detail.endsAt' => ({required Object time}) => 'در نهایت در ${time}',
			'watchLink.serverUnavailable' => 'من نمی توانستم به یک سرور Plex برای این لینک دسترسی داشته باشم.',
			'watchLink.notFound' => 'من نمی توانم این نمایش یا فیلم را در سرورهای Plex خود پیدا کنم.',
			'watchLink.ambiguous' => 'این لینک با عناصر در بیش از یک سرور مطابقت دارد. اضافه کردن یک سرور به لینک.',
			'watchLink.plexOnly' => 'مشاهده لینک ها در حال حاضر تنها از سرورهای Plex پشتیبانی می کند.',
			'watchLink.unsupportedItem' => 'لینک های تماشا فقط می تواند یک نمایش یا یک فیلم را باز کند.',
			'watchLink.menuItem' => 'مشاهده لینک',
			'watchLink.dialogTitle' => 'نگاهی به لینک',
			'watchLink.dialogShowHint' => 'با باز کردن این لینک، قسمت بعدی بازی می شود. &mode=shuffle را به پایان اضافه کنید تا نمایش را در shuffle بازی کنید.',
			'watchLink.dialogMovieHint' => 'باز کردن این لینک فیلم را بازی می کند.',
			'watchLink.copy' => 'کپی',
			'watchLink.copied' => 'لینک کپی شده',
			'homeLayout.title' => 'خانه لایو',
			'homeLayout.resetToast' => 'خانه بازگرداندن به طرح اصلی Plezy قهرمان',
			'homeLayout.resetHeroTitle' => 'بازگرداندن طرح قهرمان به ذخیره سازی Plezy؟',
			'homeLayout.resetHeroBody' => 'تنظیمات قهرمان هر ردیف را از بین می برد و یک بنر چرخشی را در بالای خانه باز می گرداند، همانطور که قبل از اینکه ردیف های قهرمان وجود داشته باشد.',
			'homeLayout.removeRowTitle' => 'خانه را رها کنید؟',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} حذف خواهد شد.این نمی تواند بدون آن باشد.',
			'homeLayout.sync' => 'همگام سازی',
			'homeLayout.syncAccountTitle' => 'طرح همگام سازی با حساب Plex شما',
			'homeLayout.syncAccountOn' => 'در: این دستگاه به اشتراک گذاری ترتیب ردیف، ردیف ها، قهرمان و اتوماتیک اسلاید با دستگاه های دیگر شما.',
			'homeLayout.syncAccountOff' => 'خاموش: این دستگاه طرح خود را حفظ می کند.',
			'homeLayout.syncNow' => 'همگام اکنون',
			'homeLayout.plexHomeManager' => 'Plex مدیر خانه',
			'homeLayout.managePlexRows' => 'مدیریت Plex ردیف در Plezy',
			'homeLayout.managePlexRowsDescription' => 'باز برای سازماندهی خطوط انتخاب شده در خانه',
			'homeLayout.organizeHomeRows' => 'سازماندهی خطوط خانگی',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} ردیف: حرکت، قهرمان، اتوماتیک، حذف',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => 'سازماندهی ${library} خطوط',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => 'ادامه تماشای + ${n} خطوط: حرکت, کتابخانه, خانه, قهرمان, اسلاید خودکار',
			'homeLayout.renderAsHero' => 'به عنوان یک کارت قهرمان',
			'homeLayout.heroOnlySingleCollection' => 'تنها زمانی در دسترس است که این ردیف به عنوان واقعی یک مجموعه حل می شود.',
			'homeLayout.hero' => 'قهرمان',
			'homeLayout.autoSlide' => 'اتومبیل اسلاید',
			'homeLayout.autoSlideDescription' => 'همچنین هر چند ثانیه به خودی خود اسلاید می کند. Arrows (PC) و d-pad (TV) همیشه کار می کنند و تایمر را دوباره راه اندازی می کنند.',
			'homeLayout.autoSlideEditDescription' => 'همچنین هر چند ثانیه به خودی خود اسلاید می کند. خاموش: فقط زمانی که بر روی یک شلیک (PC) کلیک کنید یا چپ / راست را روی دوربین (TV) فشار دهید حرکت می کند.',
			'homeLayout.enableHeroFirst' => 'قهرمانان اول',
			'homeLayout.showOnHome' => 'نمایش در صفحه اصلی',
			'homeLayout.home' => 'خانه',
			'homeLayout.removeFromHome' => 'حذف از خانه',
			'homeLayout.selectRowsFirst' => 'گزینه های زیر را انتخاب کنید.',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} Plex خطوط مدیریت شده',
			'homeLayout.continueWatching' => 'ادامه تماشا',
			'homeLayout.continueWatchingLibraryDescription' => 'این کتابخانه در حال پیشرفت است.',
			'homeLayout.continueWatchingHomeDescription' => 'روند پیشرفت مجدد نشان داده شده در خانه',
			'homeLayout.nextUpHomeDescription' => 'قسمت بعدی ناشناخته سریال به صورت جداگانه در خانه نمایش داده می شود',
			'homeLayout.library' => 'کتابخانه',
			'homeLayout.showInRecommended' => 'نمایش در کتابخانه توصیه شده',
			'homeLayout.customPlexRow' => 'مشخصات Plex خط',
			'homeLayout.heroNeedsLibrary' => 'نگاهی به کتابخانه اول – قهرمان نیاز به جایی برای نشان دادن',
			'homeLayout.heroNeedsSurface' => 'کتابخانه یا خانه را اول ببینید – قهرمان باید جایی برای نشان دادن',
			'homeLayout.removeHub' => 'حذف هاب',
			'homeLayout.noPlexRows' => 'شماره Plex ردیف های مدیریت شده برای این کتابخانه بازگردانده شده است.',
			'homeLayout.openDetails' => 'جزئیات باز',
			'homeLayout.heroCards' => 'کارت های قهرمان',
			'homeLayout.tapHeroCard' => 'دانلود کارت قهرمان',
			'homeLayout.tvPlayFocus' => 'تلویزیون از راه دور: برجسته دکمه بازی',
			'homeLayout.tvPlayFocusDescription' => 'D-pad down در دکمه Play متوقف می شود قبل از حرکت به ردیف بعدی.',
			'homeLayout.tvWrap' => 'برچسب های ارشیو: کارت های قهرمان',
			'homeLayout.tvWrapDescription' => 'فشردن چپ روی آخرین کارت، شما را به کارت اول برمی‌گرداند. با خاموش کردن این گزینه، حرکت در آخرین کارت متوقف می‌شود. فشردن راست روی کارت اول همیشه به نوار کناری می‌رود.',
			'homeLayout.castOnHero' => 'بازی بر روی باند های قهرمان',
			'homeLayout.castOnHeroDescription' => 'نشان دادن پرتاب در امتداد پایین یک بنر قهرمان.',
			'homeLayout.customRows' => 'سفارشی',
			'homeLayout.loading' => 'دانلود خانه لایه...',
			'homeLayout.noCustomRows' => 'هنوز هیچ خطوط معمولی',
			'homeLayout.addRowHint' => 'از اضافه کردن خانه برای ایجاد یکی استفاده کنید.',
			'homeLayout.addHomeRow' => 'اضافه کردن خانه راوی',
			'homeLayout.addHomeRowDescription' => 'یک دسته را انتخاب کنید؛ ردیف جدید به ترتیب به ترتیب به ترتیب اضافه می شود.',
			'homeLayout.removeRow' => 'حذف ردیف',
			'homeLayout.recentlyAdded' => 'جدیدترین‌ها',
			'homeLayout.recentlyReleased' => 'اخیرا منتشر شد',
			'homeLayout.movieCollections' => 'مجموعه فیلم ها',
			'homeLayout.showCollections' => 'نمایش مجموعه ها',
			'homeLayout.rowTitle' => 'راوی عنوان',
			'homeLayout.content' => 'محتوای',
			'homeLayout.showThisRowIn' => 'این ردیف را در:',
			'homeLayout.libraryRecommended' => 'کتابخانه توصیه می شود',
			'homeLayout.heroCard' => 'کارت قهرمان',
			'homeLayout.heroCardDescription' => 'نشان می دهد به عنوان یک کارت چرخش کامل به جای یک پوستر شیل.',
			'homeLayout.heroUnavailableDescription' => 'تنها زمانی در دسترس است که این ردیف به عنوان عنوان های واقعی یک مجموعه حل می شود – با بیش از یک مجموعه انتخاب شده، هیچ عنوانی برای چرخش وجود ندارد.',
			'homeLayout.librariesSelection' => 'کتابخانه ها (همه کتابخانه ها را بدون چک قرار دهید)',
			'homeLayout.librariesMergedDescription' => 'هر کتابخانه ای که در اینجا بررسی می شود در این یک ردیف ادغام می شود.',
			'homeLayout.movieCollectionsSelection' => 'مجموعه های فیلم (برای هر کتابخانه انتخاب شده همه غیرقابل بررسی را رها کنید)',
			'homeLayout.showCollectionsSelection' => 'نمایش مجموعه ها (برای هر کتابخانه ای که انتخاب کرده اید، همه آنها را بدون بررسی رها کنید)',
			'homeLayout.collectionRowsDescription' => 'اگر دقیقاً یک مجموعه با هم بازی می کند، عنوان های آن به طور مستقیم در ردیف نمایش داده می شود.اگر بیش از یک مجموعه با هم بازی می کند، هر مجموعه به عنوان یک پوستر نمایش داده می شود – برای باز کردن آن مجموعه آن را کلیک کنید.',
			'homeLayout.allCollections' => 'همه مجموعه ها',
			'homeLayout.noRowsHere' => 'هنوز هیچ خطی در اینجا وجود ندارد.',
			'homeLayout.hideWatchedRows' => 'پنهان کردن اشیاء مشاهده شده در ردیف ها',
			'homeLayout.hideWatchedRowsDescription' => 'عنوان های مشاهده شده به طور کامل خانه و کتابخانه را ترک می کنند ردیف های توصیه شده.',
			'homeLayout.untitledCollection' => 'جمع آوری نامناسب',
			'homeLayout.moveRowHint' => 'Up/Down: حرکت ردیف · انتخاب کنید: آن را در اینجا · بازگشت: لغو',
			'homeLayout.organizeRowsHint' => 'بر روی یک ردیف انتخاب کنید (یا نگه دارید انتخاب کنید): حرکت آن · چپ / راست: گزینه های ردیف · بازگشت: انجام شده',
			'homeLayout.layoutNavDescription' => 'انتخاب خطوط، کتابخانه ها و دسته های جمع آوری',
			'homeLayout.editHomeRow' => 'ویرایش خانه راوی',
			'homeLayout.resetHeroButton' => 'بازگرداندن طرح قهرمان به انبار Plezy',
			'homeLayout.reorderingUnlocked' => 'بازگرداندن مجدد',
			'homeLayout.reorderingLocked' => 'بازسازی قفل',
			'homeLayout.rowsCanBeDragged' => 'قفسه ها را می توان کشید – برای جلوگیری از آن قفل را تایپ کنید',
			'homeLayout.tapLockToDrag' => 'قفل را فشار دهید تا ردیف ها را کشید',
			'homeLayout.customRowLabel' => ({required Object title}) => 'مشخصات : ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => 'پنهان کردن',
			'homeLayout.remove' => 'حذف',
			'homeLayout.libraryResumeRow' => 'این کتابخانه به صورت مجدد',
			'homeLayout.pressAgainToDelete' => 'فشار دوباره برای حذف',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => 'در',
			'homeLayout.resetHeroButtonDescription' => 'تنظیمات قهرمان هر ردیف را از بین می برد و یک بنر چرخشی را به بالا باز می گرداند، همانطور که قبل از اینکه ردیف های قهرمان وجود داشته باشد.',
			'homeLayout.tapHeroCardDescription' => 'انتخاب کنید که آیا تایپ کردن یا انتخاب یک کارت قهرمان شروع به پخش و یا باز کردن جزئیات آن.',
			'homeLayout.heroTapPlayDescription' => 'گزینه انتخاب شده را بلافاصله شروع کنید.',
			'homeLayout.heroTapDetailsDescription' => 'جزئیات مورد انتخاب را قبل از انتخاب یک عمل باز کنید.',
			'platform.localNetworkPermission' => 'PlezyNG به سرورهای رسانه ای و دستگاه های پخش در شبکه محلی شما متصل می شود.',
			'platform.locationPermission' => 'PlezyNG از دسترسی مکان استفاده می کند زمانی که iOS آن را برای شناسایی شبکه محلی شما و اتصال به سرورهای رسانه ای شما نیاز دارد.',
			'platform.photoLibraryPermission' => 'تصاویر را از کتابخانه عکس خود انتخاب کنید تا به عنوان آثار هنری رسانه ای مورد استفاده قرار گیرد.',
			'platform.cameraPermission' => 'اسکن کدهای QR برای جفت کردن یک Companion Remote.',
			'universalMedia.title' => 'رسانه های باز',
			'universalMedia.shortcutHelp' => 'یک لینک، لیست پخش یا فایل برای این جلسه بازی کنید.',
			'universalMedia.intro' => 'لینک، لیست پخش یا فایل را باز کنید Playback از بازیکن استاندارد PlezyNG استفاده می کند و تاریخچه را به کتابخانه شما اضافه نمی کند.',
			'universalMedia.openWhat' => 'چه چیزی را دوست دارید باز کنید؟',
			'universalMedia.stream' => 'آدرس جریان',
			'universalMedia.playlist' => 'بازی لیست',
			'universalMedia.files' => 'فایل های دستگاه',
			'universalMedia.favorites' => 'ذخیره جریان مورد علاقه',
			'universalMedia.address' => 'آدرس رسانه ها',
			'universalMedia.addressHelp' => 'URL ها با پارامترهای اعتباربخشی یا امضای شناخته شده تنها برای این جلسه مورد استفاده قرار می گیرند و نمی توانند به عنوان محبوب ذخیره شوند.',
			'universalMedia.displayName' => 'نام نمایش (اختیاری)',
			'universalMedia.displayNameHelp' => 'یک نام کوتاه برای بازیکن و کنترل های رسانه سیستم را انتخاب کنید.',
			'universalMedia.allowHttp' => 'اجازه دادن به یک اتصال HTTP غیر رمزگذاری شده',
			'universalMedia.allowHttpHelp' => 'HTTP اتصال را رمزگذاری نمی کند. فقط در یک شبکه قابل اعتماد اجازه دهید. هنگامی که ممکن است از HTTPS استفاده کنید.',
			'universalMedia.advancedProtocols' => 'فقط MPV: یک آدرس RTSP، RTMP/RTMPS، UDP یا RTP را وارد کنید.این آدرس ها نمی توانند به عنوان محبوب ذخیره شوند.',
			'universalMedia.liveStream' => 'رفتار به عنوان زنده',
			'universalMedia.liveStreamHelp' => 'از این برای ویدئو یا رادیو زنده استفاده کنید.این برنامه نوار زمان، دکمه ها را پنهان می کند و گزینه Go-to-Time را انتخاب می کند.',
			'universalMedia.privateSession' => 'فقط این پخش از آدرس استفاده می کند. ذخیره یک جریان واجد شرایط مورد علاقه برای نگه داشتن آن در این پروفایل.',
			'universalMedia.saveFavorite' => 'ذخیره محبوب',
			'universalMedia.playNow' => 'اکنون بازی کنید',
			'universalMedia.favoriteSaved' => 'جریان محبوب به این پروفایل ذخیره شده است',
			'universalMedia.skippedEntries' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n, one: '${count} بدون پشتیبانی یا ورود نامناسب به لیست پخش.', other: '${count} بدون پشتیبانی و یا ورود نامناسب به لیست پخش.', ), 
			'universalMedia.playlistAddress' => 'آدرس Playlist',
			'universalMedia.playlistAddressHelp' => 'یک لیست پخش M3U، M3u8 یا PLS را از یک آدرس وب باز کنید لینک های جریان مستقیم لیست پخش را ذخیره نمی کنند.',
			'universalMedia.choosePlaylist' => 'انتخاب فایل playlist',
			'universalMedia.openPlaylist' => 'باز کردن playlist',
			'universalMedia.playlistFormatsHelp' => 'یک لیست پخش می تواند حاوی حداکثر 1000 آیتم و 2 مگابایت باشد.HLS به عنوان جریان ها باز می شود تا بازیکن بتواند کیفیت را انتخاب کند.',
			'universalMedia.saveQueuePlaylist' => 'ذخیره صف به‌صورت فهرست پخش',
			'universalMedia.queuePlaylistSaved' => 'فهرست پخش کنار فایل‌های رسانه ذخیره شد.',
			'universalMedia.queuePlaylistUnavailable' => 'این صف را نمی‌توان به‌صورت فهرست پخش محلی و قابل استفادهٔ دوباره ذخیره کرد.',
			'universalMedia.queuePlaylistFolderRequired' => 'محلی برای ذخیره در همان پوشهٔ فایل‌های صف انتخاب کنید.',
			'universalMedia.noFavorites' => 'در حال حاضر هیچ مورد علاقه ذخیره نشده است.Favorites در این پروفایل باقی بماند.',
			'universalMedia.removeFavorite' => 'حذف جریان مورد علاقه',
			'universalMedia.filesHelp' => 'فایل های صوتی، ویدئویی یا ISO را برای یک دوره موقت انتخاب کنید.فایلهای و URL ها به تاریخچه کتابخانه اضافه نمی شوند.',
			'universalMedia.chooseFiles' => 'انتخاب فایل ها',
			'universalMedia.fileQueue' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n, one: '1 فایل انتخاب شده', other: '${count} فایل های انتخاب شده', ), 
			'universalMedia.wifiTransfer' => 'ارسال فایل ها از طریق Wi-Fi',
			'universalMedia.wifiTransferHelp' => 'انتقال فایل های پشتیبانی شده از یک مرورگر در همان شبکه قابل اعتماد.',
			'universalMedia.wifiTransferIntro' => 'این آدرس را در یک مرورگر در دستگاه دیگری باز کنید فایل ها را انتخاب کنید تا آنها را به کتابخانه فایل ها و کتاب های این دستگاه اضافه کنید.',
			'universalMedia.wifiTransferPrivacy' => 'این دستگاه فایل ها را از طریق شبکه محلی شما دریافت می کند.هر کسی که این آدرس را می داند، می تواند تا زمانی که انتقال را متوقف کنید یا آدرس پس از 15 دقیقه به پایان برسد، فایل های خود را ارسال کند. حداکثر: 100 فایل، 4 GiB در هر فایل، 10 GiB کل.',
			'universalMedia.wifiTransferStarting' => 'در حال آماده سازی یک انتقال خصوصی و محدود به زمان ...',
			'universalMedia.wifiTransferUnavailable' => 'انتقال را نمی توان شروع کرد. دسترسی به شبکه محلی را بررسی کنید و دوباره آن را امتحان کنید.',
			'universalMedia.openThisAddress' => 'یکی از این آدرس ها را در دستگاه ارسال باز کنید.',
			'universalMedia.copyAddress' => 'کپی آدرس انتقال',
			'universalMedia.addressCopied' => 'آدرس انتقال کپی شده',
			'universalMedia.transferExpires' => ({required Object time}) => 'این آدرس در ${time} به پایان می رسد.',
			'universalMedia.uploadCount' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(n, one: '${count} فایل دریافت شده', other: 'فایل های ${count} دریافت شده', ), 
			'universalMedia.uploadedData' => ({required Object size}) => 'دانلود ${size}',
			'universalMedia.stopTransfer' => 'توقف انتقال و نامناسب کردن آدرس',
			'universalMedia.startTransfer' => 'شروع انتقال',
			'universalMedia.wifiImportedFiles' => 'انتقال Wi-Fi',
			'universalMedia.wifiBrowserTitle' => 'ارسال فایل ها به PlezyNG',
			'universalMedia.wifiBrowserIntro' => 'فایل ها در کتابخانه فایل ها و کتاب های این دستگاه ذخیره می شوند حداکثر: 100 فایل، 4 GiB برای هر فایل، 10 GiB کل.',
			'universalMedia.uploadFilesLabel' => 'فایل ها برای ارسال',
			'universalMedia.uploadSelected' => 'دانلود فایل های انتخاب شده',
			'universalMedia.uploadSelectFirst' => 'اول یک یا چند فایل را انتخاب کنید.',
			'universalMedia.uploading' => 'ارسال',
			'universalMedia.uploadComplete' => 'فایل اضافه شده به PlezyNG.',
			'universalMedia.uploadFailed' => 'این صفحه را باز نگه دارید و دوباره آن را امتحان کنید.',
			'universalMedia.liveCue' => 'زنده',
			'universalMedia.liveSession' => 'جریان زنده',
			'universalMedia.liveCueHelp' => 'برای ویدئو یا رادیو زنده، اپلیکیشن نوار زمان را پنهان می کند و دکمه ها را از بین می برد.',
			'universalMedia.sessionOnly' => 'این بازی فقط یک جلسه است.',
			'universalMedia.sessionOnlyHelp' => 'Playback هرگز پیشرفت یا تاریخچه را ذخیره نمی کند.Save the stream as a favorite to keep it in this profile if it is eligible.',
			'universalMedia.pictureAdjustments' => 'تصحیح تصویر',
			'universalMedia.pictureHelp' => 'این تغییرات تصویر فقط بر این بازتاب تاثیر می گذارد.آنها زمانی که بازتاب به پایان می رسد، دوباره تنظیم می شوند.',
			'universalMedia.resetPicture' => 'بازگرداندن تصویر',
			'universalMedia.brightness' => 'روشنایی',
			'universalMedia.contrast' => 'تناقض',
			'universalMedia.gamma' => 'گاما',
			'universalMedia.hue' => 'هوی',
			'universalMedia.saturation' => 'Saturation',
			'universalMedia.view360' => 'صفحه نمایش برای ویدئو 360 درجه',
			'universalMedia.view360Help' => 'استفاده از این برای ویدئو 360 درجه مساوی. MPV نیاز به فیلتر v360 FFmpeg برای این نمایش دارد.',
			'universalMedia.view360Unavailable' => 'این ساختار MPV نمی تواند فیلتر 360 درجه را اعمال کند.',
			'universalMedia.view360Yaw' => 'چشم انداز افقی',
			'universalMedia.view360Pitch' => 'دیدگاه عمودی',
			'universalMedia.view360FieldOfView' => 'زمینه دیدگاه',
			'universalMedia.recordStream' => 'رکورد جریان زنده',
			'universalMedia.stopRecording' => 'توقف و ذخیره ضبط',
			'universalMedia.recordingStarted' => 'ضبط فعال است.Leaving playback متوقف می شود و ضبط را ذخیره می کند.',
			'universalMedia.recordingSaved' => 'ضبط تمام شد و نجات یافت.',
			'universalMedia.recordingActive' => 'با استفاده از این دستگاه، اجازه دادن به پخش متوقف می شود و آن را ذخیره می کند.',
			'universalMedia.recordingFormatHelp' => 'برای ویدئو، MKV یا MPEG-TS را انتخاب کنید.',
			'universalMedia.replaceRecordingTitle' => 'این ضبط را جایگزین کنید؟',
			'universalMedia.replaceRecordingHelp' => 'PlezyNG در هنگام ضبط فایل فعلی را پشتیبان گیری می کند.اگر نتواند ضبط جدید را ذخیره کند، plezyNG پشتیبت را بازگرداند.',
			'universalMedia.replaceRecording' => 'جایگزین فایل',
			'universalMedia.discHelp' => 'یک دیسک را در درایو نوری این کامپیوتر باز کنید شما همچنین می توانید یک تصویر ISO از فایل های دستگاه را باز کنید.',
			'universalMedia.discs' => 'دیسک های نوری',
			'universalMedia.editionOrTitle' => 'نسخه یا عنوان دیسک',
			'universalMedia.dvd' => 'DVD',
			'universalMedia.bluray' => 'دانلود Blu-ray',
			'universalMedia.audioCd' => 'CD صوتی',
			'universalMedia.discAvailability' => 'پخش دیسک نیاز به ساخت MPV سازگار، درایو پشتیبانی شده و مجوز سیستم عامل دارد.',
			'universalMedia.converterTitle' => 'تبدیل یک فایل رسانه محلی',
			'universalMedia.converterHelp' => 'یک فایل محلی را تبدیل کنید یا آن را با FFmpeg.',
			'universalMedia.converterIntro' => 'تبدیل یک فایل صوتی یا ویدئویی محلی به فرمتی که بر روی دستگاه های مختلف کار می کند.',
			'universalMedia.converterPrivacy' => 'FFmpeg باید بر روی این کامپیوتر نصب شود.Conversion فقط فایل های محلی را می خواند.این جریان ها را دانلود نمی کند یا DRM را حذف نمی کند.',
			'universalMedia.converterChooseInput' => 'انتخاب فایل رسانه ای محلی',
			'universalMedia.converterFormat' => 'فرمت خروجی',
			'universalMedia.converterMp4' => 'MP4 · H.264 و AAC',
			'universalMedia.converterM4a' => 'M4A · AAC صدا',
			'universalMedia.converterMp3' => 'MP3 - صدا',
			'universalMedia.allowFtp' => 'اجازه FTP',
			'universalMedia.allowFtpHelp' => 'FTP رسانه ها را بدون رمزگذاری ارسال می کند.فقط در شبکه های قابل اعتماد استفاده کنید.',
			'universalMedia.converterSaveAs' => 'حفظ رسانه های تبدیل شده به عنوان',
			'universalMedia.converterExtensionMismatch' => 'یک فیل نام با افزونه خروجی انتخاب شده را انتخاب کنید.',
			'universalMedia.converterUnsupportedInput' => 'یک فایل صوتی یا ویدئویی را انتخاب کنید.',
			'universalMedia.converterLocalOnly' => 'فایل انتخاب شده به عنوان یک مسیر دستگاه محلی در دسترس نیست.',
			'universalMedia.converterReplaceTitle' => 'این فایل را جایگزین کنید؟',
			'universalMedia.converterReplaceHelp' => 'PlezyNG فایل موجود را تا زمانی که کپی تبدیل شده ذخیره شود، پشتیبان گیری می کند.',
			'universalMedia.converterStarting' => 'شروع به استفاده از FFmpeg...',
			'universalMedia.converterProgress' => 'با استفاده از این کامپیوتر...',
			'universalMedia.converterComplete' => 'فایلهای جدید آماده است.',
			'universalMedia.converterFfmpegMissing' => 'FFmpeg از دست رفته است یا از این فرمت پشتیبانی نمی کند.',
			'universalMedia.converterFailed' => 'بررسی کنید که فایل منبع قابل خواندن است و مقصد به اندازه کافی فضای رایگان دارد.',
			'universalMedia.converterCancelled' => 'تبدیل لغو شد خروجی نامناسب حذف شد.',
			'universalMedia.converterDesktopOnly' => 'تبدیل محلی در کامپیوترهای دسکتاپ با نصب FFmpeg در دسترس است.',
			'universalMedia.converterStart' => 'تبدیل فایل',
			'universalMedia.mediaToolsTitle' => 'ابزار رسانه ای',
			'universalMedia.mediaToolsShortcut' => 'ضبط و یا به اشتراک گذاری رسانه ها، اضافه کردن افزونه های جستجو، و یا استفاده از خط فرمان.',
			'universalMedia.mediaToolsIntro' => 'یک ابزار متمرکز را انتخاب کنید. ضبط و جریان خارج از استفاده از FFmpeg نصب شده در این دسکتاپ. افزونه ها و فرمان های CLI استفاده از درخواست های HTTPS محدود و جریان Open media موجود.',
			'universalMedia.mediaToolsAccessibility' => 'گزینه های ابزار و کنترل ها با تمرکز لمسی، شاخص، صفحه کلید و D-pad کار می کنند. ضبط، به اشتراک گذاری و تغییرات وضعیت جستجو اعلام می شود.',
			'universalMedia.mediaTool' => 'ابزار رسانه ای',
			'universalMedia.captureIntro' => 'صفحه نمایش یا دوربین خود را به یک فایل MP4 در این کامپیوتر ضبط کنید. FFmpeg باید نصب شود و کدگذاری H.264 را شامل شود.',
			'universalMedia.captureNoDevices' => 'هیچ صفحه نمایش و یا دوربین یافت نشد. بررسی FFmpeg پشتیبانی از ضبط و اجازه های حفظ حریم خصوصی سیستم عامل.',
			'universalMedia.captureSource' => 'صفحه نمایش یا دوربین',
			'universalMedia.captureScreen' => 'صفحه نمایش',
			'universalMedia.captureAudioSource' => 'ورودی صوتی (اختیاری)',
			'universalMedia.captureAudioHelp' => 'اضافه کردن صدا از یک میکروفون یا ورودی در دسترس. انتخاب دستگاه بستگی به FFmpeg و مجوزهای سیستم دارد.',
			'universalMedia.captureAudioNone' => 'بدون صدا',
			'universalMedia.captureDefaultAudio' => 'واردات صوتی پیش فرض',
			'universalMedia.captureWaylandHelp' => 'Wayland limits this XWayland capture to the X display. Windows outside XWayland may not appear.',
			_ => null,
		} ?? switch (path) {
			'universalMedia.captureFrameRate' => 'نرخ ضبط فریم',
			'universalMedia.capturePrivacy' => 'ضبط فقط به فایل انتخاب شده ذخیره می شود. ضبط میکروفون اختیاری است. PlezyNG ضبط را بارگذاری نمی کند.',
			'universalMedia.captureSaveAs' => 'ضبط صفحه نمایش به عنوان',
			'universalMedia.captureExtensionMismatch' => 'انتخاب یک نام فیل که در .mp4 به پایان می رسد.',
			'universalMedia.captureFfmpegMissing' => 'FFmpeg یا کدگذاری ویدئویی H.264 در دسترس نیست. نصب یک ساختار FFmpeg پشتیبانی شده، سپس دوباره امتحان کنید.',
			'universalMedia.captureFailed' => 'ضبط نمی تواند ذخیره شود. بررسی اجازه دستگاه، ذخیره سازی در دسترس، و پشتیبانی از FFmpeg.',
			'universalMedia.captureSaved' => 'ضبط صفحه نمایش نجات یافت',
			'universalMedia.captureElapsedLabel' => 'زمان ضبط',
			'universalMedia.captureStart' => 'شروع ضبط',
			'universalMedia.capturePreview' => 'پیش‌نمایش در پخش‌کننده',
			'universalMedia.capturePreviewHelp' => 'منبع انتخاب‌شده را در پخش‌کنندهٔ استاندارد پیش‌نمایش کنید. این پیش‌نمایش فقط برای همین نشست است و ضبطی ذخیره نمی‌کند. پشتیبانی دستگاه و مجوزها به MPV و سیستم‌عامل بستگی دارد. پیش‌نمایش فقط از ویدیو استفاده می‌کند؛ ضبط‌های ذخیره‌شده می‌توانند صدای اختیاری داشته باشند.',
			'universalMedia.capturePreviewActive' => 'پیش‌نمایش زنده · بدون ضبط',
			'universalMedia.captureStop' => 'توقف و نجات',
			'universalMedia.captureMode' => 'دستگیری',
			'universalMedia.shareMode' => 'به اشتراک گذاری',
			'universalMedia.shareIntro' => 'ارسال یک فایل رسانه محلی به دستگاه دیگری در شبکه خصوصی خود.PlezyNG یک جریان موقت HLS ایجاد می کند.',
			'universalMedia.sharePrivacy' => 'هر کسی در شبکه محلی شما که لینک خصوصی را دریافت می کند می تواند در حالی که فعال است تماشا کند. لینک پس از 60 دقیقه به پایان می رسد. توقف به اشتراک گذاری برای بستن سرور و لغو لینک.',
			'universalMedia.shareChooseFile' => 'انتخاب فایل های رسانه ای',
			'universalMedia.shareChooseHelp' => 'یک فایل صوتی یا ویدئویی محلی را انتخاب کنید.این فایل در این کامپیوتر باقی می ماند.',
			'universalMedia.shareFfmpegMissing' => 'FFmpeg یا رمزگذاری های H.264/AAC در دسترس نیست. نصب FFmpeg با پشتیبانی از رمزگذاری H.264 و AAC.',
			'universalMedia.shareFailed' => 'جریان نمی توانست به طور غیرمنتظره شروع یا متوقف شود. بررسی FFmpeg و دسترسی به شبکه.',
			'universalMedia.shareActive' => 'جریان در شبکه خصوصی شما آماده است.',
			'universalMedia.shareEnded' => 'رسانه ها به پایان رسیدند و دیگر به اشتراک نمی گذارند.',
			'universalMedia.shareStopped' => 'به اشتراک گذاری متوقف شده است لینک موقت دیگر معتبر نیست.',
			'universalMedia.shareUrlCopied' => 'آدرس جریان کپی شده است',
			'universalMedia.shareOpenUrl' => 'این آدرس را در یک بازیکن در دستگاه دیگر باز کنید.',
			'universalMedia.shareQrLabel' => 'کد QR برای آدرس جریان موقت',
			'universalMedia.shareQrHelp' => 'اسکن با یک بازیکن سازگار متصل به همان شبکه خصوصی.',
			'universalMedia.shareHttpHint' => 'This stream uses unencrypted HTTP. In PlezyNG, allow HTTP before opening it.',
			'universalMedia.shareCopyUrl' => 'کپی آدرس جریان',
			'universalMedia.shareExpiresLabel' => 'لینک به پایان می رسد',
			'universalMedia.shareStarting' => 'در حال آماده سازی جریان...',
			'universalMedia.shareStart' => 'شروع به اشتراک گذاری',
			'universalMedia.shareStop' => 'توقف به اشتراک گذاری',
			'universalMedia.extensionsMode' => 'تمدید و CLI',
			'universalMedia.extensionsIntro' => 'برای یافتن رسانه ها یک افزونه جستجو داده اضافه کنید.نتیجه را انتخاب کنید تا آن را در فرم آشنا Open media بارگذاری کنید.',
			'universalMedia.extensionsPrivacy' => 'یک مانیفست می تواند یک نقطه جستجو HTTPS و میدان های پاسخ نقشه را تعریف کند. آن را نمی تواند کد را اجرا کند، عنوان درخواست را اضافه کند، فایل ها را بخواند، یا دستورالعمل های شل را راه اندازی کند.',
			'universalMedia.extensionImport' => 'اضافه کردن Manifesto',
			'universalMedia.extensionEmpty' => 'هنوز هیچ سرویس جستجو وجود ندارد. انتخاب یک فایل قابل اعتماد آشکار JSON برای اضافه کردن یکی.',
			'universalMedia.extensionChoose' => 'خدمات جستجو',
			'universalMedia.extensionSearchConsent' => 'هر جستجو کلمات خود را به این سرویس HTTPS ارسال می کند.نتایج تنها پس از انتخاب یکی باز می شود.',
			'universalMedia.extensionSearchLabel' => 'جستجو رسانه ها',
			'universalMedia.extensionSearch' => 'جستجو',
			'universalMedia.extensionSearching' => 'جستجو...',
			'universalMedia.extensionNoResults' => 'نتایج رسانه های امن بازگردانده نشده است.مطالعه دیگری را امتحان کنید.',
			'universalMedia.extensionInstallTitle' => 'این سرویس جستجو را اضافه کنید؟',
			'universalMedia.extensionReplaceTitle' => 'این سرویس جستجو را به روز کنید؟',
			'universalMedia.extensionService' => 'خدمات',
			'universalMedia.extensionEndpoint' => 'HTTPS نقطه نهایی',
			'universalMedia.extensionConsent' => 'متن جستجوی شما به این سرویس ارسال می شود.این مانیفست هیچ کد اجرا نمی شود.با ادامه فقط اگر به این نقطه نهایی اعتماد کنید.',
			'universalMedia.extensionInstall' => 'اضافه کردن خدمات',
			'universalMedia.extensionReplace' => 'خدمات به روز رسانی',
			'universalMedia.extensionRemoveTitle' => 'این سرویس جستجو را حذف کنید؟',
			'universalMedia.extensionRemoveHelp' => 'این سرویس را از این پروفایل حذف می کند.PlezyNG با نقطه نهایی آن تماس نمی گیرد.',
			'universalMedia.extensionRemove' => 'حذف خدمات',
			'universalMedia.extensionInvalidManifest' => 'این فایل یک مانیفست افزونه پشتیبانی نشده است.نگاه کنید به راهنمای Open media برای فرمت.',
			'universalMedia.extensionSaveFailed' => 'این افزونه نمی تواند به پروفایل فعال ذخیره شود.',
			'universalMedia.extensionSearchFailed' => 'سرویس جستجو پاسخ معتبر را بازگردانده است.نقطه نهایی را بررسی کنید و دوباره امتحان کنید.',
			'universalMedia.cliTitle' => 'خط فرمان',
			'universalMedia.cliHelp' => 'از راهنمای plezyctl برای تأیید یک مانیفست یا جستجو برای همان افزونه استفاده کنید. قبل از هر جستجو، خدمات HTTPS خود را بررسی کنید. نتایج در فرم رسانه های موجود باز می شود.',
			'universalMedia.cliCopyExample' => 'کپی دستور نمونه',
			'universalMedia.cliCopied' => 'دستور نمونه کپی شده است.',
			'fileSources.title' => 'فایل ها و کتاب ها',
			'fileSources.subtitle' => 'خواندن، گوش دادن و تماشای از فایل های خود را.',
			'fileSources.add' => 'منبع اضافه کنید',
			'fileSources.importFiles' => 'واردات فایل ها',
			'fileSources.localFiles' => 'در این دستگاه',
			'fileSources.source' => 'منبع',
			'fileSources.name' => 'نام',
			'fileSources.endpoint' => 'سرور URL',
			'fileSources.smbEndpointHint' => 'مثال: smb://nas/Movies',
			'fileSources.smbEndpointInvalid' => 'یک سرور SMB و یک پوشهٔ اشتراکی وارد کنید.',
			'fileSources.root' => 'پوشه یا پیشوند',
			'fileSources.smbFolderHelp' => 'برای استفاده از کل پوشهٔ اشتراکی، خالی بگذارید؛ یا پوشه‌ای درون آن وارد کنید.',
			'fileSources.username' => 'نام کاربری',
			'fileSources.smbDomain' => 'دامنه (اختیاری)',
			'fileSources.password' => 'گذرواژه',
			'fileSources.token' => 'API توکن',
			'fileSources.accessKey' => 'دسترسی کلید ID',
			'fileSources.secretKey' => 'کلید دسترسی مخفی',
			'fileSources.sessionToken' => 'تگ های جلسه (اختیاری)',
			'fileSources.region' => 'منطقه',
			'fileSources.clientId' => 'OAuth مشتری ID',
			'fileSources.clientSecret' => 'OAuth Client Secret (فقط Google Desktop)',
			'fileSources.allowHttp' => 'اجازهٔ اتصال HTTP بدون رمزگذاری در یک شبکهٔ مورد اعتماد',
			'fileSources.smbEncryption' => 'رمزگذاری اتصال SMB3',
			'fileSources.smbEncryptionHint' => 'اگر دستگاه NAS پشتیبانی می‌کند، از رمزگذاری SMB3 استفاده کنید.',
			'fileSources.connect' => 'اتصال',
			'fileSources.cancel' => 'لغو کردن',
			'fileSources.save' => 'ذخیره',
			'fileSources.close' => 'بستن',
			'fileSources.removeSource' => 'منبع ناپایدار',
			'fileSources.disconnectMessage' => 'اتصال به این منبع قطع شود؟ فایل‌های دانلودشده و سابقهٔ خواندن و شنیدن شما در این دستگاه باقی می‌مانند.',
			'fileSources.localFolder' => 'انتخاب پوشه',
			'fileSources.empty' => 'هنوز چیزی در اینجا نیست',
			'fileSources.emptyHint' => 'منبع را اضافه کنید یا یک کتاب، کتاب صوتی، موسیقی یا ویدئو وارد کنید.',
			'fileSources.search' => 'جستجو برای این پوشه',
			'fileSources.searchCached' => 'کتابخانه نجات یافت',
			'fileSources.refresh' => 'به‌روز‌رسانی',
			'fileSources.loadMore' => 'بار بیشتر',
			'fileSources.offline' => 'در دسترس offline',
			'fileSources.download' => 'بایگانی Offline',
			'fileSources.removeDownload' => 'حذف کپی آفلاین',
			'fileSources.continueReading' => 'به خواندن ادامه دهید',
			'fileSources.continueListening' => 'به گوش دادن ادامه دهید',
			'fileSources.continueWatching' => 'ادامه تماشا',
			'fileSources.read' => 'خواندن',
			'fileSources.listen' => 'گوش دادن',
			'fileSources.play' => 'اجرا کردن',
			'fileSources.pause' => 'مکث',
			'fileSources.stop' => 'توقف',
			'fileSources.startOver' => 'شروع به',
			'fileSources.finished' => 'پایان یافت',
			'fileSources.markFinished' => 'مارک به پایان رسید',
			'fileSources.markUnfinished' => 'مارک بی نهایت',
			'fileSources.editions' => 'نسخه ها و فایل ها',
			'fileSources.chapters' => 'فصل ها',
			'fileSources.bookmarks' => 'کتاب ها و یادداشت ها',
			'fileSources.bookmark' => 'اضافه کردن کتاب',
			'fileSources.highlight' => 'برجسته',
			'fileSources.note' => 'یادداشت',
			'fileSources.delete' => 'حذف',
			'fileSources.export' => 'صادرات یادداشت',
			'fileSources.exported' => 'برچسب ها صادرات',
			'fileSources.sync' => 'پیشرفت همگام',
			'fileSources.synced' => 'پیشرفت های همگام',
			'fileSources.conflict' => 'دستگاه دیگری دارای موقعیت متفاوت است. انتخاب کنید که کجا ادامه دهید.',
			'fileSources.useLocal' => 'استفاده از این دستگاه',
			'fileSources.useRemote' => 'استفاده از دستگاه های دیگر',
			'fileSources.history' => 'تاریخچه موقعیت',
			'fileSources.groupAudio' => 'گوش دادن به عنوان یک کتاب صوتی',
			'fileSources.groupHint' => 'فایل های صوتی که در حال حاضر در این پوشه بارگذاری می شوند را ترکیب کنید.اول تمام صفحات را بارگذاری کنید.',
			'fileSources.order' => 'دستور فایل',
			'fileSources.moveUp' => 'حرکت بالا',
			'fileSources.moveDown' => 'حرکت به پایین',
			'fileSources.speed' => 'سرعت پخش',
			'fileSources.sleep' => 'زمان خواب',
			'fileSources.sleepOff' => 'خاموش',
			'fileSources.endChapter' => 'پایان فصل',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fa'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} دقیقه', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} دقیقه', ), 
			'fileSources.skipBack' => 'بازگشت به Sk',
			'fileSources.skipForward' => 'کشتی جلو',
			'fileSources.smartRewind' => 'بازگشت هوشمند پس از استراحت',
			'fileSources.playbackOptions' => 'گزینه های گوش دادن',
			'fileSources.remaining' => ({required Object time}) => '${time} باقی مانده',
			'fileSources.contents' => 'محتوای',
			'fileSources.readerSettings' => 'خواندن تنظیمات',
			'fileSources.fontSize' => 'اندازه متن',
			'fileSources.lineHeight' => 'خط فضایی',
			'fileSources.margin' => 'مارگین',
			'fileSources.font' => 'نوع چهره',
			'fileSources.serif' => 'سریف',
			'fileSources.sans' => 'بدون سریف',
			'fileSources.mono' => 'تک‌فاصله',
			'fileSources.columns' => 'ستون ها',
			'fileSources.scroll' => 'چرخش عمودی',
			'fileSources.justify' => 'تراز دوطرفهٔ متن',
			'fileSources.readerTheme' => 'صفحه ظاهر',
			'fileSources.appTheme' => 'پیگیری برنامه های کاربردی',
			'fileSources.paper' => 'کاغذ',
			'fileSources.sepia' => 'سپیا',
			'fileSources.night' => 'شب',
			'fileSources.readAloud' => 'این صفحه را با صدای بلند بخوانید',
			'fileSources.readAlong' => 'خواندن همراه با صدا',
			'fileSources.stopReading' => 'توقف خواندن با صدا',
			'fileSources.searchBook' => 'جستجو در کتاب',
			'fileSources.noMatches' => 'هیچ بازی',
			'fileSources.previousPage' => 'صفحه قبلی',
			'fileSources.nextPage' => 'صفحه بعدی',
			'fileSources.page' => ({required Object number}) => 'صفحه ${number}',
			'fileSources.externalBlocked' => 'لینک های کتاب خارجی در خواننده غیرفعال می شوند.',
			'fileSources.loading' => 'باز کردن...',
			'fileSources.narrator' => 'داستان نویس',
			'fileSources.audio' => 'صدا',
			'fileSources.video' => 'ویدئو',
			'fileSources.ebooks' => 'کتاب Ebook',
			'fileSources.all' => 'همه',
			'fileSources.downloads' => 'فایل های غیر آنلاین',
			'fileSources.confirmDelete' => 'نسخهٔ آفلاین انتخاب‌شده حذف شود؟ موقعیت خواندن یا شنیدن و یادداشت‌های شما حفظ می‌شوند.',
			'fileSources.errorAuthentication' => 'برای اتصال دوباره به این منبع، دوباره وارد حساب شوید.',
			'fileSources.errorPermission' => 'این منبع دسترسی به فایل مورد نظر را فراهم نکرده است.',
			'fileSources.errorUnavailable' => 'منبع در دسترس نیست. دوباره امتحان کنید یا یک کپی غیر آنلاین را باز کنید.',
			'fileSources.errorUnsupported' => 'این فرمت یا اتصال در این دستگاه پشتیبانی نمی شود.در راهنمای تنظیم منبع بررسی کنید.',
			'fileSources.errorInvalidData' => 'این فایل یا پاسخ سرور نمی تواند به طور ایمن خوانده شود.',
			'fileSources.errorCancelled' => 'این عملیات لغو شد.',
			'fileSources.errorConflict' => 'موقعیت در جلسه دیگری تغییر کرده است.نمایش را برای انتخاب موقعیت دوباره باز کنید.',
			'fileSources.signIn' => 'ورود',
			'fileSources.reconnect' => 'دوباره متصل',
			'fileSources.folderHelp' => 'برای شروع از پوشهٔ ریشهٔ منبع، این قسمت را خالی بگذارید. نشانی‌های S3 شامل نام باکت هستند.',
			'fileSources.preferences' => 'ترجیحات',
			'fileSources.timePosition' => 'موقعیت',
			'fileSources.audioTrack' => 'Audio Track',
			'fileSources.subtitleTrack' => 'زیرنویس Track',
			'fileSources.none' => 'هیچکدام',
			'fileSources.fullscreen' => 'تمام صفحه',
			'fileSources.syncLocation' => 'فاکتور پیشرفت (اختیاری)',
			'fileSources.syncLocationHint' => 'یک پوشه اختصاص داده شده WebDAV برای PlezyNG وضعیت. استفاده از نوشتن مشروط؛ رسانه ها تغییر نمی کند.',
			'fileSources.audiobooks' => 'کتاب های صوتی',
			'fileSources.comics' => 'کمیک‌ها',
			'fileSources.scan' => 'اسکن برای کتاب ها و رسانه ها',
			'fileSources.browserReader' => 'خواننده باز',
			'fileSources.browserReaderHelp' => 'خواننده در مرورگر شما باز است. PlezyNG را باز نگه دارید تا محل و یادداشت های خود را ذخیره کنید.',
			'fileSources.on' => 'در',
			'fileSources.advancedSetup' => 'App ثبت نام',
			'fileSources.microsoftSignIn' => 'ثبت نام با مایکروسافت',
			'fileSources.zoomIn' => 'زوم در',
			'fileSources.zoomOut' => 'زوم بیرون',
			'fileSources.fitPage' => 'صفحه مناسب',
			'fileSources.fitWidth' => 'مناسب پهنای باند',
			'fileSources.actualSize' => 'حجم فعلی',
			'fileSources.goToPage' => 'به صفحه برو',
			'fileSources.goToSection' => 'به فصل بروید',
			'fileSources.pageRange' => ({required Object count}) => 'عددی از ۱ تا ${count} وارد کنید',
			'fileSources.pageLayout' => 'صفحه Layout',
			'fileSources.automatic' => 'اتوماتیک',
			'fileSources.singlePage' => 'صفحه تک',
			'fileSources.twoPages' => '2 صفحه',
			'fileSources.readingDirection' => 'خواندن جهت',
			'fileSources.leftToRight' => 'سمت چپ به سمت راست',
			'fileSources.rightToLeft' => 'از راست به چپ',
			'fileSources.letterSpacing' => 'نامه فضایی',
			'fileSources.wordSpacing' => 'کلمه فضا',
			'fileSources.readerControlsHelp' => 'برای بزرگ‌کردن صفحه‌ها، دو انگشت را از هم باز کنید یا از کنترل‌های بزرگ‌نمایی استفاده کنید. برای جابه‌جایی صفحه بکشید. Ctrl/⌘ همراه + یا − بزرگ‌نمایی را تنظیم می‌کند؛ Ctrl/⌘ همراه 0 آن را بازنشانی می‌کند. Page Up و Page Down صفحه را عوض می‌کنند.',
			'fileSources.imagePage' => 'صفحه کمیک',
			'fileSources.resetReader' => 'تنظیم مجدد ترجیحات خواندن',
			'fileSources.zoom' => 'پوشش دادن',
			'fileSources.useFiles' => 'استفاده از فایل ها و کتاب ها',
			'fileSources.cancelScan' => 'حذف اسکن',
			'fileSources.googleDrive' => 'Google Drive',
			'fileSources.offlineQuota' => 'محدودیت دانلود Offline',
			'fileSources.offlineQuotaHelp' => 'حداکثر فضای مورد استفاده برای کپی های آفلاین، فایل های وارد شده و دانلود ها را تنظیم کنید. کاهش محدودیت کپی موجود را حذف نمی کند.',
			'fileSources.offlineStorageUsage' => 'ذخیره سازی آفلاین',
			'fileSources.reservedStorage' => 'ذخیره شده',
			'fileSources.downloadQueue' => 'دانلود Queue',
			'fileSources.downloadRunning' => 'دانلود',
			'fileSources.downloadQueued' => 'منتظر',
			'fileSources.downloadPaused' => 'استراحت',
			'fileSources.downloadFailed' => 'نیاز به عقب نشینی',
			'fileSources.importing' => 'واردات',
			'fileSources.importInterrupted' => 'واردات متوقف شد · حذف به روشن',
			'fileSources.errorQuotaExceeded' => 'محدودیت ذخیره سازی آفلاین به دست آمده است. بالا بردن محدودیت یا حذف یک کپی دانلود شده.',
			'fileSources.errorStorageLow' => 'ذخیره سازی رایگان دستگاه به اندازه کافی برای حفظ ذخایر محافظت نشده است.',
			'fileSources.errorStorageUnavailable' => 'PlezyNG نمی توانست ذخیره سازی رایگان دستگاه را بررسی کند، بنابراین نوشتن متوقف شد.',
			'fileSources.removeDownloadJob' => 'دانلود حذف',
			'fileSources.downloadAlreadyComplete' => 'این دانلود قبل از اینکه بتواند حذف شود به پایان رسید.این آیتم اکنون در دسترس است آفلاین.',
			'fileSources.confirmRemoveDownloadJob' => 'این دانلود را حذف کنید و هر گونه داده ای که به طور جزئی دانلود شده است، حذف کنید؟ موقعیت و یادداشت های شما باقی خواهد ماند.',
			'lending.title' => 'کتابخانه های عمومی',
			'lending.add' => 'اضافه کردن کتابخانه',
			'lending.other' => 'کتابخانه دیگری',
			'lending.libraryName' => 'نام کتابخانه',
			'lending.libraryUrl' => 'وبسایت کتابخانه',
			'lending.libraryUrlHint' => 'از فهرست کتابخانه یا صفحهٔ ورود آن استفاده کنید.',
			'lending.intro' => 'کتاب را از کتابخانه خود قرض بگیرید کتاب های خود را در نزدیکی خود نگه دارید.',
			'lending.handoff' => 'با سرویس خود کتابخانه، وارد حساب شوید، کتاب امانت بگیرید و با امنیت بخوانید.',
			'lending.openService' => 'کتابخانه باز',
			'lending.findLibrary' => 'پیدا کردن کتابخانه',
			'lending.search' => 'جستجو برای کتاب ها و نویسندگان',
			'lending.catalogue' => 'کاتالوگ',
			'lending.loans' => 'امانت‌ها',
			'lending.holds' => 'رزروها',
			'lending.signIn' => 'ثبت نام با کتابخانه خود',
			'lending.waiting' => 'ثبت نام را در مرورگر خود به پایان برسانید و سپس به اینجا برگردید.',
			'lending.cancel' => 'لغو کردن',
			'lending.disconnect' => 'حذف کتابخانه',
			'lending.disconnectMessage' => 'این کتابخانه از این نمایه حذف شود؟ امانت‌ها و رزروهای شما در کتابخانه باقی می‌مانند.',
			'lending.getBook' => 'کتاب را بخوانید',
			'lending.checkAvailability' => 'بررسی در دسترس بودن',
			'lending.available' => 'آمادهٔ امانت گرفتن',
			'lending.unavailable' => 'در حال حاضر در دسترس نیست',
			'lending.borrow' => 'امانت گرفتن',
			'lending.placeHold' => 'رزرو کردن',
			'lending.returnBook' => 'بازگرداندن پیش از موعد',
			'lending.cancelHold' => 'لغو رزرو',
			'lending.confirmBorrow' => 'این کتاب را از کتابخانه خود قرض می دهید؟',
			'lending.confirmReturn' => 'این عنوان اکنون بازگردانده شود؟ برای ادامه ممکن است لازم باشد دوباره آن را امانت بگیرید.',
			'lending.confirmCancelHold' => 'رزرو شما برای این عنوان لغو شود؟',
			'lending.email' => 'ارسال ایمیل اطلاع رسانی',
			'lending.due' => ({required Object date}) => 'موعد بازگشت: ${date}',
			'lending.queue' => ({required Object position}) => 'موقعیت ${position} در خط',
			'lending.empty' => 'هنوز هیچ عنوانی در اینجا وجود ندارد.',
			'lending.openLibraryNote' => 'فهرست Open Library را مرور کنید. گزینه‌های خواندن و امانت گرفتن در صفحهٔ هر عنوان نمایش داده می‌شوند.',
			'lending.more' => 'بار بیشتر',
			'lending.gateway' => 'کتابخانه ثبت نام در سرویس',
			'lending.gatewayHint' => 'توسط کتابخانه یا مدیر PlezyNG ارائه شده است.',
			'lending.advanced' => 'کتابخانه ادغام',
			'lending.loadLibraries' => 'کتابخانه خود را انتخاب کنید',
			'lending.expired' => 'مدت این امانت به پایان رسیده است.',
			'lending.updated' => 'کتابخانه به روز شده',
			'lending.continueService' => 'ادامه خدمت',
			'lending.comingSoon' => 'وام های جدید در آینده ای نزدیک',
			'lending.comingSoonDescription' => 'شما می توانید از کتابخانه خود در Libby استفاده کنید در حالی که ما آن را به اتصال می رسانیم.',
			'lending.suspendHold' => 'تعلیق رزرو',
			'lending.resumeHold' => 'ازسرگیری رزرو',
			'lending.suspendMessage' => 'جای خود را در صف حفظ کنید و اجازه دهید خوانندهٔ بعدی این نسخه را امانت بگیرد؟ می‌توانید بعداً رزرو را از سر بگیرید.',
			'lending.resumeMessage' => 'این رزرو از سر گرفته شود تا کتابخانه بتواند نسخهٔ بعدیِ موجود را به شما پیشنهاد دهد؟',
			'lending.editEmail' => 'تغییر ایمیل اطلاع رسانی',
			'audiobook.syncTitle' => 'خواندن و گوش دادن Sync',
			'audiobook.syncHelp' => 'موقعیت های خواندن، موقعیت های گوش دادن، وضعیت تکمیل، برچسب ها و یادداشت ها را در سراسر دستگاه های خود نگه دارید.یک حساب ذخیره سازی پیوسته را انتخاب کنید و از همان کد همگام سازی در هر دستگاه استفاده کنید.خواندن و گوش دادن جداگانه باقی می ماند.',
			'audiobook.addSyncSource' => 'در ابتدا Google Drive، OneDrive، Dropbox، WebDAV یا S3 را به فایل ها و کتاب ها اضافه کنید.',
			'audiobook.syncDestination' => 'حساب ذخیره سازی Sync',
			'audiobook.syncFolder' => 'فاکتور یا پیش فرض',
			'audiobook.syncCode' => 'کد همگام خصوصی',
			'audiobook.syncCodeHelp' => 'یک کد را در دستگاه اول خود ایجاد کنید، سپس آن کد را در دستگاه های دیگر خود وارد کنید. یک کپی خصوصی نگه دارید: این کلید وضعیت رمزگذاری شده شماست.',
			'audiobook.showCode' => 'نمایش یا پنهان کردن کد همگام سازی',
			'audiobook.newSyncCode' => 'ایجاد کد جدید همگام سازی',
			'audiobook.saveSync' => 'حفظ و همگام سازی',
			'audiobook.disableSync' => 'در این دستگاه همگام سازی را خاموش کنید.',
			'audiobook.syncSourceDisconnect' => 'حذف این منبع در اینجا خواندن و گوش دادن به همگام سازی را خاموش می کند.فایلهای همگام سازی رمزگذاری شده در ارائه دهنده باقی می ماند.',
			'audiobook.syncReconnect' => 'بازگرداندن حساب ذخیره سازی',
			'audiobook.lastSynced' => ({required Object time}) => 'آخرین ارسال شده در ${time}',
			'audiobook.syncConflicts' => 'انتخاب کنید که کجا بازگردانید',
			'audiobook.conflictHelp' => 'این تغییرات به صورت مستقل انجام شده است. گزینه ای را انتخاب کنید که موقعیت یا نسخه برچسب را برای نگه داشتن داشته باشید. یک زمان بندی بعدی یا درصد بالاتر به طور خودکار برنده نمی شود.',
			'audiobook.syncDevice' => ({required Object device}) => 'تجهیزات ${device}',
			'audiobook.syncUnknownDevice' => 'دستگاه ناشناخته',
			'audiobook.deletedBookmark' => 'برچسب حذف شده',
			'audiobook.finished' => 'به پایان رسید',
			'audiobook.readingPosition' => ({required Object percent}) => 'خواندن · ${percent}%',
			'audiobook.chapterTimeline' => 'فصل پیشرفت',
			'audiobook.bookTimeline' => 'کتاب کامل پیشرفت',
			'audiobook.bookRemaining' => ({required Object time}) => 'زمان باقی مانده در این کتاب: ${time}',
			'audiobook.chapterRemaining' => ({required Object time}) => 'زمان باقی مانده در این فصل: ${time}',
			'audiobook.unknownRemaining' => 'تمام زمان در دسترس به عنوان قطعات بازی می شود',
			'audiobook.undoSeek' => 'آخرین جستجو',
			'audiobook.customSpeed' => 'سرعت بازی Custom Playback',
			'audiobook.speedHelp' => 'سرعت را از 0.25× تا 4× انتخاب کنید.',
			'audiobook.apply' => 'اعمال',
			'audiobook.customSleep' => 'زمان خواب شخصی',
			'audiobook.sleepMinutes' => '۱ تا ۱۴۴۰ دقیقه',
			'audiobook.sleepChapters' => ({required Object count}) => 'دانلود بازی ${count}',
			'audiobook.extendSleep' => 'اضافه کردن 5 دقیقه',
			'audiobook.sleepRemaining' => ({required Object time}) => 'زمان خواب: ${time}',
			'audiobook.useDefaults' => 'از این کنترل های گوش دادن برای کتاب های جدید استفاده کنید',
			'audiobook.librarySort' => 'انواع کتاب ها',
			'audiobook.sortTitle' => 'عنوان',
			'audiobook.sortAuthor' => 'نویسنده',
			'audiobook.sortNarrator' => 'سخنران',
			'audiobook.sortSeries' => 'سری سفارش',
			'audiobook.sortRecent' => 'اخیرا باز شد',
			'audiobook.statusFilter' => 'وضعیت خواندن',
			'audiobook.statusAll' => 'همه کتاب ها',
			'audiobook.statusNew' => 'شروع نمی شود',
			'audiobook.statusProgress' => 'در پیشرفت',
			'audiobook.statusFinished' => 'به پایان رسید',
			'audiobook.goToTime' => 'به زمان برو',
			'audiobook.timeHelp' => 'ساعت: دقیقه ها: ثانیه ها یا دقیقه ها: ثانیه ها',
			'audiobook.recoveryHelp' => 'یک کپی رمزگذاری شده اخیر را قبل از حرکت یا اصلاح داده های همگام سازی صادر کنید. واردات با وضعیت فعلی ادغام می شود؛ آنها هرگز تاریخچه همگامه محلی را جایگزین نمی کنند.',
			'audiobook.recoveryExport' => 'صادرات رمزگذاری شده بازگرداندن فایل',
			'audiobook.recoveryImport' => 'واردات فایل های رمزگذاری شده',
			'audiobook.recoveryImportConfirm' => 'آیا این فایل بازگرداندن رمزگذاری شده با موقعیت های خواندن فعلی و یادداشت ها ترکیب می شود؟ تاریخچه موجود حفظ خواهد شد. کتابخانه به اشتراک گذاشته شده و شناسه آیتم شامل نمی شود؛ قبل از واردات، شناسه های مطابقت را بر روی هر دستگاه تنظیم کنید.',
			'audiobook.recoveryExported' => 'فایل بازگرداندن رمزگذاری شده ذخیره شده است.',
			'audiobook.recoveryImported' => 'بازگرداندن اطلاعات جمع آوری شده است.',
			'sourceSetup.savedCertificate' => 'گواهی ذخیره‌شدهٔ سرور',
			'sourceSetup.nfsEndpointInvalid' => 'یک نشانی NFS مانند nfs://nas:2049/export وارد کنید.',
			'sourceSetup.dlnaNone' => 'سرور DLNA پیدا نشد. نشانی توضیحات دستگاه را دستی وارد کنید.',
			'sourceSetup.dlnaServers' => 'سرورهای رسانهٔ DLNA',
			'sourceSetup.dlnaUnavailable' => 'کشف DLNA در این شبکه در دسترس نیست. نشانی توضیحات دستگاه را دستی وارد کنید.',
			'sourceSetup.dlnaSearching' => 'در حال جست‌وجوی سرورهای DLNA در شبکهٔ محلی',
			'sourceSetup.networkSearching' => 'در حال جست‌وجو در شبکهٔ محلی…',
			'sourceSetup.dlnaDiscover' => 'یافتن سرورهای DLNA',
			'sourceSetup.dlnaHelp' => 'کشف دستگاه به چندپخشی در شبکهٔ محلی وابسته است. اگر سروری ظاهر نشد، نشانی توضیحات دستگاه را در بالا وارد کنید.',
			'sourceSetup.dlnaRoot' => 'شناسهٔ شیء DLNA؛ برای استفاده از ریشهٔ دستگاه، خالی بگذارید.',
			'sourceSetup.passwordOrKey' => 'گذرواژه وارد کنید یا در پایین یک کلید خصوصی اضافه کنید.',
			'sourceSetup.sshFingerprint' => 'اثر انگشت SHA256 کلید میزبان SSH',
			'sourceSetup.sshFingerprintHelp' => 'با مدیر سرور تأیید کنید. روی سرور، دستور ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub را اجرا کنید و از مقدار SHA256 آن استفاده کنید.',
			'sourceSetup.sshFingerprintKeep' => 'برای حفظ اثر انگشت تثبیت‌شدهٔ فعلی خالی بگذارید، یا اثر انگشت جدید سرور را وارد کنید.',
			'sourceSetup.sshAuthentication' => 'احراز هویت با کلید عمومی SSH',
			'sourceSetup.sshAuthenticationHelp' => 'اختیاری است؛ احراز هویت با گذرواژه نیز پشتیبانی می‌شود.',
			'sourceSetup.privateKey' => 'کلید خصوصی (با قالب PEM یا OpenSSH)',
			'sourceSetup.privateKeyPassphrase' => 'عبارت عبور کلید خصوصی',
			'sourceSetup.nfsMountPort' => 'درگاه TCP سرویس mount NFS',
			'sourceSetup.nfsMountPortHelp' => 'پیش‌فرض: 20048',
			'sourceSetup.nfsUserId' => 'شناسهٔ کاربر NFS ‏(AUTH_SYS)',
			'sourceSetup.nfsUserIdHelp' => 'پیش‌فرض: 1000. از شناسه‌ای استفاده کنید که در تنظیمات اشتراک NFS روی NAS مجاز است.',
			'sourceSetup.nfsGroupId' => 'شناسهٔ گروه NFS ‏(AUTH_SYS)',
			'sourceSetup.nfsGroupIdHelp' => 'پیش‌فرض: 1000. از شناسهٔ گروهی استفاده کنید که در تنظیمات اشتراک NFS روی NAS مجاز است.',
			'sourceSetup.nfsEncryption' => 'الزام رمزگذاری NFS ‏(RPC-with-TLS)',
			'sourceSetup.nfsEncryptionHelp' => 'TLS 1.3 را برای NFS و سرویس mount الزامی می‌کند. اگر NAS پشتیبانی نکند، اتصال رد می‌شود.',
			'sourceSetup.nfsTrustCertificate' => 'گواهی سفارشی CA یا سرور NFS ‏(PEM، اختیاری)',
			'sourceSetup.nfsTrustHelp' => 'برای گواهی‌های مورد اعتماد این دستگاه، خالی بگذارید. در صورت نیاز، گواهی CA خصوصی یا گواهی خودامضای سرور را اضافه کنید؛ نام‌های آن باید با میزبان نشانی NFS مطابقت داشته باشند.',
			'sourceSetup.nfsTrustInvalid' => 'از گواهی CA یا سرور با قالب PEM استفاده کنید. کلید خصوصی را در آن قرار ندهید.',
			'sourceSetup.addTrustCertificate' => 'افزودن گواهی اعتماد سفارشی',
			'sourceSetup.replaceTrustCertificate' => 'جایگزینی گواهی سفارشی ذخیره‌شده',
			'sourceSetup.nfsTlsHelp' => 'RPC-with-TLS از درگاه‌های معمول NFS و سرویس mount استفاده می‌کند و به پشتیبانی NAS از RFC 9289 نیاز دارد. TLS 1.3 الزامی است. نام میزبان یا IP باید با گواهی مطابقت داشته باشد. AUTH_SYS UID/GID در کانال رمزگذاری‌شده نیز اعمال می‌شوند.',
			'sourceSetup.clientCertificate' => 'گواهی کارخواه (اختیاری)',
			'sourceSetup.clientCertificateHelp' => 'به NAS اجازه می‌دهد هویت این کارخواه را تأیید کند؛ شناسه‌های AUTH_SYS همچنان تابع سیاست اشتراک‌گذاری NAS هستند.',
			'sourceSetup.savedIdentity' => 'از هویت ذخیره‌شدهٔ کارخواه استفاده می‌شود.',
			'sourceSetup.replaceIdentity' => 'جایگزینی هویت ذخیره‌شدهٔ کارخواه',
			'sourceSetup.chooseIdentity' => 'انتخاب هویت کارخواه PKCS#12',
			'sourceSetup.identityPassphrase' => 'عبارت عبور هویت کارخواه',
			'sourceSetup.identityPassphraseHelp' => 'اگر فایل عبارت عبور ندارد، خالی بگذارید.',
			'sourceSetup.removeIdentity' => 'حذف هویت ذخیره‌شدهٔ کارخواه',
			'sourceSetup.identityStorageHelp' => 'هویت‌های کارخواه در مخزن رمزگذاری‌شدهٔ اطلاعات ورود منابع ذخیره می‌شوند. برای حفظ هویت ذخیره‌شده، این بخش را تغییر ندهید.',
			'sourceSetup.nfsLimitations' => 'NFSv3 فقط‌خواندنی روی TCP. بدون RPC-with-TLS، ترافیک NFS رمزگذاری نمی‌شود. NAS باید شناسه‌های AUTH_SYS انتخاب‌شده و درگاه‌های بدون امتیاز ویژهٔ کارخواه را مجاز بداند (این گزینهٔ اشتراک‌گذاری معمولاً «insecure» نام دارد). NFSv4 و UDP پشتیبانی نمی‌شوند.',
			'sourceSetup.nfsSetupHelp' => 'راهنمای تنظیم NFS',
			'sourceSetup.nfsSetupHint' => 'اگر اتصال برقرار نمی‌شود، این تنظیمات را بررسی کنید.',
			'sourceSetup.nfsSetupDetails' => 'از یک اشتراک NFSv3 روی TCP استفاده کنید. اگر رمزگذاری الزامی است، NFS و سرویس mount باید هر دو از RPC-with-TLS پشتیبانی کنند. برای گواهی سروری که این دستگاه به آن اعتماد دارد، گواهی سفارشی را خالی بگذارید؛ یا گواهی CA یا خودامضای NAS را اضافه کنید. نام گواهی باید با میزبان نشانی اتصال مطابقت داشته باشد. اگر NAS به TLS متقابل نیاز دارد، هویت کارخواه PKCS#12 آن را اضافه کنید. در پایان، تأیید کنید که تنظیمات اشتراک، AUTH_SYS UID/GID تعیین‌شده و سیاست درگاه‌های کارخواه را مجاز می‌داند.',
			'sourceSetup.ftpHelp' => 'FTP از حالت پسیو (Passive) استفاده می‌کند. برای FTP بدون رمزگذاری از ftp://، برای فعال‌سازی TLS با فرمان جداگانه از ftpes:// و برای TLS از ftps:// استفاده کنید (روی درگاه 990، TLS بلافاصله آغاز می‌شود؛ روی سایر درگاه‌ها با فرمان جداگانه فعال می‌شود).',
			'sourceSetup.openSubtitles' => 'OpenSubtitles',
			'sourceSetup.subtitleSetup' => 'جست‌وجوی اختیاری زیرنویس برای فایل‌های ویدیویی مستقل.',
			'sourceSetup.apiKey' => 'کلید API',
			'sourceSetup.optionalUsername' => 'نام کاربری حساب (اختیاری)',
			'sourceSetup.optionalPassword' => 'گذرواژهٔ حساب (اختیاری)',
			'sourceSetup.subtitlePrivacy' => 'کلید API را از opensubtitles.com بگیرید. جست‌وجو، عنوان ویدیو و شناسه‌های موجود IMDb/TMDB را ارسال می‌کند، اما هرگز فایل ویدیو را نمی‌فرستد. کلید و اطلاعات ورود اختیاری حساب، همراه این منبع به‌صورت رمزگذاری‌شده ذخیره می‌شوند.',
			'sourceSetup.automaticMetadata' => 'دریافت خودکار فرادادهٔ آنلاین ویدیو',
			'sourceSetup.metadataPrivacy' => 'فقط عنوان، سال و شمارهٔ قسمت از نام فایل یا شناسهٔ NFO ارسال می‌شود؛ رسانه و اطلاعات ورود هرگز ارسال نمی‌شوند. فیلدهای NFO همیشه اولویت دارند.',
			'sourceSetup.nfsEncryptionFailure' => 'برای NFS رمزگذاری‌شده، پشتیبانی هر دو سرویس NAS از RFC 9289 و TLS 1.3، نام گواهی و UID/GID اشتراک را بررسی کنید. PlezyNG این اتصال را بدون رمزگذاری دوباره امتحان نمی‌کند.',
			'sourceSetup.sourceConnecting' => 'در حال اتصال به منبع',
			'sourceSetup.metadataSearchPrivacy' => 'این جست‌وجوی عنوان به Trakt فرستاده می‌شود. فقط عنوانی که وارد می‌کنید ارسال می‌شود، نه ویدیو یا اطلاعات ورود منبع.',
			'sourceSetup.chooseMatch' => 'انتخاب نتیجهٔ مطابق',
			'sourceSetup.metadataMatchHelp' => 'پیش از انتخاب، عنوان و سال را بررسی کنید. Trakt عنوان جست‌وجو را دریافت می‌کند؛ ویدیو در منبع خود باقی می‌ماند.',
			'sourceSetup.metadataNoMatches' => 'عنوان مطابقی در اینترنت پیدا نشد. عنوان دیگری را امتحان کنید.',
			'sourceSetup.metadataSearch' => 'جست‌وجوی فرادادهٔ آنلاین',
			'sourceSetup.metadataLoading' => 'در حال جست‌وجوی آنلاین اطلاعات فیلم و سریال…',
			'sourceSetup.metadataFromTrakt' => 'فرادادهٔ آنلاین از Trakt',
			'sourceSetup.metadataNoAutomaticMatch' => 'عنوان مطابقی به‌صورت خودکار پیدا نشد. عنوان را جست‌وجو کنید تا نتیجهٔ مطابق را انتخاب کنید.',
			'sourceSetup.metadataFailed' => 'فرادادهٔ آنلاین بارگیری نشد. پخش و اطلاعات محلی همچنان در دسترس هستند.',
			'sourceSetup.videoDetailsLoading' => 'در حال بارگیری اطلاعات ویدیو',
			'sourceSetup.subtitleKeyRequired' => 'کلید API سرویس OpenSubtitles لازم است',
			'sourceSetup.subtitleKeyHelp' => 'این منبع فایل را ویرایش کنید و در تنظیمات اختیاری زیرنویس، کلید API سرویس OpenSubtitles را اضافه کنید.',
			'sourceSetup.subtitleSearchFailed' => 'جست‌وجوی زیرنویس ناموفق بود. کلید API، اتصال و دسترسی به سرویس را بررسی کنید.',
			'sourceSetup.subtitleApplyFailed' => 'دریافت یا اعمال این زیرنویس ممکن نشد. اتصال را بررسی کنید و نتیجهٔ دیگری را امتحان کنید.',
			'sourceSetup.subtitleSearch' => 'جست‌وجو در OpenSubtitles',
			'sourceSetup.subtitleSearchPrivacy' => 'جست‌وجو از عنوان و شناسه‌های موجود IMDb/TMDB استفاده می‌کند. فایل ویدیو در منبع خود باقی می‌ماند. پیش از انتخاب، زبان، نشان زیرنویس اجباری یا ویژهٔ کم‌شنوایان و امتیاز را بررسی کنید.',
			'sourceSetup.movieOrShow' => 'فیلم یا سریال',
			'sourceSetup.subtitleTitleHint' => 'برای محدود کردن نتایج، عنوانی وارد کنید',
			'sourceSetup.subtitleLanguage' => 'زبان زیرنویس',
			'sourceSetup.subtitleSearching' => 'در حال جست‌وجو در OpenSubtitles',
			'sourceSetup.subtitleNoMatches' => 'زیرنویس مطابقی پیدا نشد. عنوان یا زبان دیگری را امتحان کنید.',
			'sourceSetup.downloadSubtitle' => 'دریافت زیرنویس',
			'sourceSetup.subtitle' => 'زیرنویس',
			'sourceSetup.nfsTlsRequired' => 'RPC-with-TLS الزامی است',
			'sourceSetup.nfsUnencrypted' => 'NFS بدون رمزگذاری',
			'sourceSetup.tlsEncrypted' => 'رمزگذاری‌شده با TLS',
			'sourceSetup.ftpPlain' => 'FTP بدون رمزگذاری',
			'sourceSetup.sshPinned' => 'رمزگذاری SSH · کلید میزبان تثبیت‌شده',
			'sourceSetup.smbEncrypted' => 'رمزگذاری SMB3 روشن است',
			'sourceSetup.smbUnencrypted' => 'رمزگذاری SMB3 خاموش است',
			'sourceSetup.httpUnencrypted' => 'HTTP بدون رمزگذاری انتقال',
			'sourceSetup.checkEndpointSecurity' => 'امنیت نشانی اتصال را بررسی کنید',
			'sourceSetup.fieldRequired' => ({required Object label}) => 'وارد کردن ${label} الزامی است.',
			'sourceSetup.integerRange' => ({required Object label, required Object min, required Object max}) => '${label} را بین ${min} و ${max} وارد کنید.',
			'sourceSetup.replaceFile' => ({required Object name}) => 'جایگزینی ${name}',
			'sourceSetup.selectedIdentity' => ({required Object name}) => 'هویت کارخواه انتخاب‌شده: ${name}',
			'sourceSetup.subtitleRating' => ({required Object rating}) => 'امتیاز ${rating}',
			'sourceSetup.subtitleDownloading' => ({required Object title}) => 'در حال دریافت زیرنویس: ${title}',
			'sourceSetup.sharedEntryPair' => 'این آیتم را بپوشانید',
			'sourceSetup.sharedEntryPairHelp' => 'همان ID برای این آیتم را در هر دستگاه وارد کنید.با استفاده از یک شناسه به اشتراک گذاری پایدار یا ایجاد یکی و کپی آن را به آیتم مطابقت.پیشرفت فقط زمانی که نسخه فایل انواع، اندازه ها و سفارش مطابقه است.',
			'sourceSetup.sharedEntryId' => 'به اشتراک گذاری آیتم ID',
			'sourceSetup.generateSharedEntryId' => 'به اشتراک گذاری آیتم ID',
			'sourceSetup.sharedLibraryId' => 'ID کتابخانه به اشتراک گذاشته (اختیاری)',
			'sourceSetup.sharedLibraryHelp' => 'استفاده از همان شناسه در دستگاه هایی که همان کتابخانه را باز می کنند.این شناسه عمومی کمک می کند تا پیشرفت خواندن و یادداشت ها را در سراسر اتصالات منبع مختلف انجام دهد؛ این یک رمز عبور نیست.هنگامی که ارائه دهندگان از شناسه های آیتم های مختلف استفاده می کنند، آن آیتم ها را از صفحه نمایش جزئیات خود جفت کنید.',
			'sourceSetup.sharedLibraryInvalid' => 'از 8 تا 100 حروف، اعداد، نقطه ها، زیرنویس ها یا هیفن استفاده کنید.',
			'sourceSetup.generateSharedLibraryId' => 'ایجاد یک ID کتابخانه مشترک',
			'sourceSetup.nfsReadAhead' => 'درخواست های NFS Read-ahead',
			'sourceSetup.nfsReadAheadHelp' => 'بیشتر خواندن موازی می تواند پهنای باند را در یک NAS یا شبکه سریع بهبود بخشد.استفاده از 1 اگر سرور تقاضای همزمان را محدود می کند.',
			'sourceSetup.nfsReadTest' => 'اندازه گیری عملکرد NFS خواندن',
			'sourceSetup.nfsReadTestHelp' => 'خواندن تا 64 مگابایت از بزرگترین فایل برای اندازه گیری این اتصال NAS.',
			'sourceSetup.nfsQualificationResult' => 'NFS مطالعه اندازه گیری',
			'sourceSetup.nfsReadBytes' => 'اطلاعات خواندن',
			'sourceSetup.nfsReadSpeed' => 'سرعت اندازه گیری',
			'sourceSetup.nfsReadRequests' => 'خواندن درخواست ها',
			'sourceSetup.sharedEntryConflict' => 'این ID آیتم به اشتراک گذاشته شده در حال حاضر با یک آیتم دیگر در این کتابخانه ترکیب شده است.',
			'comics.fitHeight' => 'اندازه بر اساس ارتفاع',
			'comics.readingMode' => 'حالت مطالعه',
			'comics.paged' => 'صفحه‌ها',
			'comics.webtoon' => 'پیمایش پیوسته',
			'comics.coverAlone' => 'نمایش جلد به‌تنهایی',
			'comics.splitWide' => 'تقسیم صفحه‌های عریض',
			'comics.splitWideHelp' => 'هر نیمه را جداگانه و به ترتیب مطالعه نشان می‌دهد. با فعال بودن این گزینه، نمایش دو صفحه کنار هم متوقف می‌شود.',
			'comics.thumbnails' => 'تصاویر بندانگشتی صفحه‌ها',
			'comics.controlsHelp' => 'برای ورق زدن بکشید. برای تغییر اندازهٔ نمایش دو بار ضربه بزنید. در پیمایش پیوسته، عمودی بکشید یا از Page Up و Page Down استفاده کنید.',
			'comics.savedForComic' => 'تنظیمات نمایش این کمیک در این نمایه ذخیره می‌شود.',
			'comics.readLists' => 'فهرست‌های مطالعه',
			'comics.collections' => 'مجموعه‌ها',
			'games.title' => 'Games',
			'games.enable' => 'Show Games for this profile',
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
			_ => null,
		} ?? switch (path) {
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
			'deepLinks.invalid' => 'این لینک Plezy معتبر نیست.',
			'deepLinks.profileNotFound' => ({required Object profile}) => 'هیچ پروفایل با "${profile}" مطابقت ندارد.',
			'deepLinks.serverUnavailable' => 'من نمی توانستم به سرور برای این لینک دسترسی داشته باشم.',
			'deepLinks.notFound' => 'من نمی توانم این عنوان را در کتابخانه های شما پیدا کنم.',
			'deepLinks.unsupportedItem' => 'این لینک بازی نمی شود.',
			'deepLinks.noLiveTv' => 'هیچ سرور تلویزیونی زنده برای این لینک در دسترس نیست.',
			'deepLinks.channelNotFound' => ({required Object channel}) => 'من نمی توانم کانال "${channel}" پیدا کنم.',
			'deepLinks.showLink' => 'نمایش لینک',
			'deepLinks.showProfileLink' => 'نمایش پروفایل لینک',
			'deepLinks.dialogTitle' => 'لینک',
			'deepLinks.showHint' => 'باز کردن این لینک قسمت بعدی را بازی می کند. اضافه کنید &mode=shuffle برای پخش نمایش در shuffle.',
			'deepLinks.movieHint' => 'باز کردن این لینک فیلم را بازی می کند.',
			'deepLinks.episodeHint' => 'باز کردن این لینک این قسمت را بازی می کند.',
			'deepLinks.profileHint' => 'باز کردن این لینک به این پروفایل تبدیل می شود.',
			'deepLinks.openAsProfile' => ({required Object name}) => 'باز کردن به عنوان ${name}',
			'deepLinks.copy' => 'کپی',
			'deepLinks.copied' => 'لینک کپی شده',
			'householdSetup.title' => 'راه‌اندازی خانه',
			'issueReport.title' => 'گزارش مشکل',
			'issueReport.instructions' => 'برای باز کردن پیش‌نویس ازپیش‌پرشده GitHub، کد QR را اسکن کنید. آن را بررسی کنید و فقط وقتی آماده‌اید ارسال کنید.',
			'issueReport.privacy' => 'پیش‌نویس نسخه برنامه، پلتفرم و تعداد اتصال‌ها را دارد. نشانی سرورها، نام حساب‌ها و پروفایل‌ها، عنوان رسانه‌ها و مسیر فایل‌ها در آن نیست.',
			'issueReport.logPrivacy' => 'گزارش‌ها اختیاری‌اند. پیش از بارگذاری آن‌ها را بررسی کنید. شناسه گزارش به پیش‌نویس اضافه می‌شود و ممکن است عمومی باشد.',
			'issueReport.openDraft' => 'باز کردن پیش‌نویس GitHub',
			_ => null,
		};
	}
}
