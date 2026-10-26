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
class TranslationsAr extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsAr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ar,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ar>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsAr _root = this; // ignore: unused_field

	@override 
	TranslationsAr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsAr(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$ar app = _Translations$app$ar._(_root);
	@override late final _Translations$cast$ar cast = _Translations$cast$ar._(_root);
	@override late final _Translations$automation$ar automation = _Translations$automation$ar._(_root);
	@override late final _Translations$notifications$ar notifications = _Translations$notifications$ar._(_root);
	@override late final _Translations$appIcon$ar appIcon = _Translations$appIcon$ar._(_root);
	@override late final _Translations$auth$ar auth = _Translations$auth$ar._(_root);
	@override late final _Translations$common$ar common = _Translations$common$ar._(_root);
	@override late final _Translations$screens$ar screens = _Translations$screens$ar._(_root);
	@override late final _Translations$update$ar update = _Translations$update$ar._(_root);
	@override late final _Translations$appAccess$ar appAccess = _Translations$appAccess$ar._(_root);
	@override late final _Translations$settings$ar settings = _Translations$settings$ar._(_root);
	@override late final _Translations$themeEditor$ar themeEditor = _Translations$themeEditor$ar._(_root);
	@override late final _Translations$search$ar search = _Translations$search$ar._(_root);
	@override late final _Translations$hotkeys$ar hotkeys = _Translations$hotkeys$ar._(_root);
	@override late final _Translations$fileInfo$ar fileInfo = _Translations$fileInfo$ar._(_root);
	@override late final _Translations$mediaMenu$ar mediaMenu = _Translations$mediaMenu$ar._(_root);
	@override late final _Translations$rateSheet$ar rateSheet = _Translations$rateSheet$ar._(_root);
	@override late final _Translations$accessibility$ar accessibility = _Translations$accessibility$ar._(_root);
	@override late final _Translations$tooltips$ar tooltips = _Translations$tooltips$ar._(_root);
	@override late final _Translations$audioTracks$ar audioTracks = _Translations$audioTracks$ar._(_root);
	@override late final _Translations$videoControls$ar videoControls = _Translations$videoControls$ar._(_root);
	@override late final _Translations$messages$ar messages = _Translations$messages$ar._(_root);
	@override late final _Translations$subtitlingStyling$ar subtitlingStyling = _Translations$subtitlingStyling$ar._(_root);
	@override late final _Translations$mpvConfig$ar mpvConfig = _Translations$mpvConfig$ar._(_root);
	@override late final _Translations$dialog$ar dialog = _Translations$dialog$ar._(_root);
	@override late final _Translations$profiles$ar profiles = _Translations$profiles$ar._(_root);
	@override late final _Translations$connections$ar connections = _Translations$connections$ar._(_root);
	@override late final _Translations$accountPreferences$ar accountPreferences = _Translations$accountPreferences$ar._(_root);
	@override late final _Translations$discover$ar discover = _Translations$discover$ar._(_root);
	@override late final _Translations$errors$ar errors = _Translations$errors$ar._(_root);
	@override late final _Translations$libraries$ar libraries = _Translations$libraries$ar._(_root);
	@override late final _Translations$about$ar about = _Translations$about$ar._(_root);
	@override late final _Translations$serverSelection$ar serverSelection = _Translations$serverSelection$ar._(_root);
	@override late final _Translations$hubDetail$ar hubDetail = _Translations$hubDetail$ar._(_root);
	@override late final _Translations$logs$ar logs = _Translations$logs$ar._(_root);
	@override late final _Translations$detail$ar detail = _Translations$detail$ar._(_root);
	@override late final _Translations$startup$ar startup = _Translations$startup$ar._(_root);
	@override late final _Translations$licenses$ar licenses = _Translations$licenses$ar._(_root);
	@override late final _Translations$navigation$ar navigation = _Translations$navigation$ar._(_root);
	@override late final _Translations$explore$ar explore = _Translations$explore$ar._(_root);
	@override late final _Translations$liveTv$ar liveTv = _Translations$liveTv$ar._(_root);
	@override late final _Translations$collections$ar collections = _Translations$collections$ar._(_root);
	@override late final _Translations$playlists$ar playlists = _Translations$playlists$ar._(_root);
	@override late final _Translations$music$ar music = _Translations$music$ar._(_root);
	@override late final _Translations$watchTogether$ar watchTogether = _Translations$watchTogether$ar._(_root);
	@override late final _Translations$downloads$ar downloads = _Translations$downloads$ar._(_root);
	@override late final _Translations$shaders$ar shaders = _Translations$shaders$ar._(_root);
	@override late final _Translations$companionRemote$ar companionRemote = _Translations$companionRemote$ar._(_root);
	@override late final _Translations$videoSettings$ar videoSettings = _Translations$videoSettings$ar._(_root);
	@override late final _Translations$performanceOverlay$ar performanceOverlay = _Translations$performanceOverlay$ar._(_root);
	@override late final _Translations$externalPlayer$ar externalPlayer = _Translations$externalPlayer$ar._(_root);
	@override late final _Translations$metadataEdit$ar metadataEdit = _Translations$metadataEdit$ar._(_root);
	@override late final _Translations$matchScreen$ar matchScreen = _Translations$matchScreen$ar._(_root);
	@override late final _Translations$serverTasks$ar serverTasks = _Translations$serverTasks$ar._(_root);
	@override late final _Translations$trakt$ar trakt = _Translations$trakt$ar._(_root);
	@override late final _Translations$seerr$ar seerr = _Translations$seerr$ar._(_root);
	@override late final _Translations$services$ar services = _Translations$services$ar._(_root);
	@override late final _Translations$addServer$ar addServer = _Translations$addServer$ar._(_root);
	@override late final _Translations$watchLink$ar watchLink = _Translations$watchLink$ar._(_root);
	@override late final _Translations$homeLayout$ar homeLayout = _Translations$homeLayout$ar._(_root);
	@override late final _Translations$platform$ar platform = _Translations$platform$ar._(_root);
	@override late final _Translations$fileSources$ar fileSources = _Translations$fileSources$ar._(_root);
	@override late final _Translations$lending$ar lending = _Translations$lending$ar._(_root);
	@override late final _Translations$audiobook$ar audiobook = _Translations$audiobook$ar._(_root);
}

// Path: app
class _Translations$app$ar extends Translations$app$en {
	_Translations$app$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: cast
class _Translations$cast$ar extends Translations$cast$en {
	_Translations$cast$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => 'البث إلى جهاز';
	@override String get searching => 'جارٍ البحث عن أجهزة البث…';
	@override String connectedTo({required Object device}) => 'متصل بـ ${device}';
	@override String get device => 'جهاز البث';
	@override String get readyToCast => 'جاهز للبث';
	@override String get subtitle => 'الترجمة';
	@override String get serverNotAvailable => 'خادم الوسائط غير متاح.';
	@override String get stopCasting => 'إيقاف البث';
	@override String get castToDevice => 'البث إلى جهاز';
	@override String get noEpisodeAvailable => 'لا توجد حلقة متاحة للبث.';
	@override String get startFailed => 'تعذر بدء البث. تحقق من الخادم وحاول مرة أخرى.';
}

// Path: automation
class _Translations$automation$ar extends Translations$automation$en {
	_Translations$automation$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => 'لا يوجد جلسة فيديو نشطة للتحكم فيها.';
	@override String get profileNotFound => 'لم يتم العثور على هذا الملف Plezy.';
}

// Path: notifications
class _Translations$notifications$ar extends Translations$notifications$en {
	_Translations$notifications$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => 'الحلقة الجديدة';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appIcon
class _Translations$appIcon$ar extends Translations$appIcon$en {
	_Translations$appIcon$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'تطبيق icon';
	@override String get defaultIcon => 'الافتراضي';
	@override String get current => 'الرمز الحالي';
	@override String get locked => 'الوصول مدى الحياة مطلوب';
	@override String get lockedHint => 'ابدأ تجربة 7 أيام أو قم بإلغاء قفل PlezyNG مدى الحياة لاستخدام أيقونات بديلة.';
	@override String get changeFailed => 'لا يمكن تغيير أيقونة التطبيق';
	@override String get launcherHint => 'يظهر الرمز الجديد على الشاشة المنزلية الخاصة بك بمجرد مغادرتك PlezyNG.';
	@override String get tvLauncherHint => 'يظهر الشعار الجديد بمجرد مغادرتك PlezyNG. Android TV يمكن أن تستمر في عرض الشعار القديم حتى يبدأ التلفزيون مرة أخرى.';
	@override late final _Translations$appIcon$names$ar names = _Translations$appIcon$names$ar._(_root);
}

// Path: auth
class _Translations$auth$ar extends Translations$auth$en {
	_Translations$auth$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'تسجيل الدخول مع Plex';
	@override String get showQRCode => 'عرض الرمز QR';
	@override String get authenticate => 'الأصلي';
	@override String get authenticationTimeout => 'تأكيد موعد، يرجى المحاولة مرة أخرى.';
	@override String get scanQRToSignIn => 'قم بفحص هذا الرمز QR لتسجيل الدخول';
	@override String get waitingForAuth => 'الانتظار للحصول على مصداقية... تسجيل الدخول من المتصفح الخاص بك.';
	@override String get useBrowser => 'استخدام البريد الإلكتروني';
	@override String get or => 'أو';
	@override String connectToMediaBrowser({required Object product}) => 'الاتصال بـ ${product}';
	@override String get quickConnect => 'توصيل سريع';
	@override String get useQuickConnect => 'استخدام Quick Connect';
	@override String get quickConnectInstructions => 'افتح Quick Connect في Jellyfin واكتب هذا الرمز.';
	@override String get quickConnectWaiting => 'في انتظار الموافقة ..';
	@override String get quickConnectCancel => 'إلغاء';
	@override String get quickConnectExpired => 'انتهت صلاحية الاتصال السريع. حاول مرة أخرى.';
	@override String get localDataRecoveryRequired => 'تعذّر على PlezyNG استعادة بيانات تسجيل الدخول المحلية وبيانات التشغيل المعلّقة بأمان. يُرجى تسجيل الدخول مجددًا.';
	@override String get pinCheckRejected => 'تم رفض التحقق Plex PIN';
	@override String get connectToDirectPlex => 'الاتصال بالخادم المحلي Plex';
}

// Path: common
class _Translations$common$ar extends Translations$common$en {
	_Translations$common$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'إلغاء';
	@override String get save => 'حفظ';
	@override String get close => 'إغلاق';
	@override String get clear => 'واضحة';
	@override String get reset => 'إعادة تعيين';
	@override String get later => 'في وقت لاحق';
	@override String get submit => 'إرسال';
	@override String get confirm => 'تأكيد';
	@override String get retry => 'إعادة المحاولة';
	@override String get logout => 'تسجيل الخروج';
	@override String get unknown => 'غير معروف';
	@override String get refresh => 'تحديث';
	@override String get yes => 'نعم';
	@override String get no => 'لا';
	@override String get delete => 'حذف';
	@override String get edit => 'تعديل';
	@override String get shuffle => 'تشغيل عشوائي';
	@override String get addTo => 'أضف إلى...';
	@override String get createNew => 'خلق جديد';
	@override String get connect => 'اتصال';
	@override String get disconnect => 'قطع الاتصال';
	@override String get play => 'تشغيل';
	@override String get pause => 'إيقاف مؤقت';
	@override String get resume => 'استئناف';
	@override String get error => 'خطأ';
	@override String get search => 'بحث';
	@override String get home => 'الرئيسية';
	@override String get back => 'رجوع';
	@override String get settings => 'الإعدادات';
	@override String get mute => 'كتم الصوت';
	@override String get ok => 'حسنًا';
	@override String get off => 'إيقاف';
	@override String get options => 'الخيارات';
	@override String seasonNumber({required Object number}) => 'الموسم ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'الحلقة ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'الفصل ${number}';
	@override String get reconnect => 'إعادة الاتصال';
	@override String get viewAll => 'انظر كل';
	@override String get checkingNetwork => 'شبكة التحقق...';
	@override String get loadingServers => 'الخادم المحمول ...';
	@override String get connectingToServers => 'الاتصال بالخوادم ...';
	@override String get startingOfflineMode => 'بدء تشغيل الوضع غير المباشر ...';
	@override String get loading => 'تحميل...';
	@override String get fullscreen => 'ملء الشاشة';
	@override String get exitFullscreen => 'الخروج الشاشة الكاملة';
	@override String get pressBackAgainToExit => 'اضغط مرة أخرى للخروج';
	@override late final _Translations$common$ratingSource$ar ratingSource = _Translations$common$ratingSource$ar._(_root);
	@override String get notAvailable => 'N / A';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
	@override late final _Translations$common$mediaKind$ar mediaKind = _Translations$common$mediaKind$ar._(_root);
}

// Path: screens
class _Translations$screens$ar extends Translations$screens$en {
	_Translations$screens$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'التراخيص';
	@override String get switchProfile => 'الملف الشخصي Switch';
	@override String get subtitleStyling => 'تنسيق الترجمة';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'السجلات';
}

// Path: update
class _Translations$update$ar extends Translations$update$en {
	_Translations$update$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get available => 'التحديثات المتاحة';
	@override String versionAvailable({required Object version}) => 'الإصدار ${version} متوفر';
	@override String currentVersion({required Object version}) => 'الحالي: ${version}';
	@override String get skipVersion => 'إلغاء هذا النسخة';
	@override String get viewRelease => 'مشاهدة الإصدار';
	@override String get latestVersion => 'أنت في أحدث النسخة';
	@override String get checkFailed => 'فشل في التحقق من التحديثات';
}

// Path: appAccess
class _Translations$appAccess$ar extends Translations$appAccess$en {
	_Translations$appAccess$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'جرّب جميع الميزات مجانًا لمدة 7 أيام';
	@override String get description => 'ابدأ فترة تجريبية لمدة سبعة أيام مع إمكانية استخدام جميع ميزات PlezyNG. لا توجد رسوم خلال الفترة التجريبية ولا اشتراك. بعد انتهاء التجربة، يمكنك فتح PlezyNG مدى الحياة بدفعة واحدة بالسعر المعروض في متجرك.';
	@override String get trialEndedDescription => 'افتح جميع ميزات PlezyNG مدى الحياة بدفعة واحدة بالسعر المعروض في متجرك. لا يوجد اشتراك.';
	@override String get startTrial => 'بدء تجربتي المجانية لمدة 7 أيام';
	@override String get trialActive => 'تجربتك الكاملة لجميع الميزات لمدة 7 أيام نشطة.';
	@override String get trialEnded => 'انتهت تجربتك لمدة 7 أيام';
	@override String get trialStartFailed => 'تعذر حفظ الفترة التجريبية على هذا الجهاز. حاول مرة أخرى.';
	@override String get lifetimeTitle => 'تم فتح PlezyNG مدى الحياة';
	@override String get lifetimeBody => 'شكرًا لك! يمكنك الآن استخدام جميع ميزات PlezyNG مدى الحياة.';
	@override String get manageTitle => 'الوصول إلى PlezyNG مدى الحياة';
	@override String get manageDescription => 'جرّب جميع الميزات مجانًا لمدة 7 أيام، ثم افتحها مدى الحياة بدفعة واحدة بالسعر المعروض في متجرك.';
	@override String buy({required Object price}) => 'فتح جميع الميزات مقابل ${price}';
	@override String get loadingPrice => 'جارٍ تحميل السعر من المتجر…';
	@override String get retryPrice => 'إعادة محاولة جلب السعر';
	@override String get restore => 'استعادة عملية الشراء مدى الحياة';
	@override String get pending => 'عملية الشراء في انتظار الدفع أو الموافقة. سيُفعّل الوصول مدى الحياة فور إتمام المتجر للعملية.';
	@override String get storeUnavailable => 'عمليات الشراء غير متاحة. تحقق من تسجيل الدخول إلى المتجر ومن السماح بالشراء على هذا الجهاز.';
	@override String get productNotFound => 'شراء PlezyNG مدى الحياة غير متاح في هذا المتجر بعد.';
	@override String get productQueryFailed => 'تعذر تحميل السعر من المتجر. تحقق من اتصالك وحاول مرة أخرى.';
	@override String get purchaseFailed => 'لم تكتمل عملية الشراء. حاول مرة أخرى.';
	@override String get restoreFailed => 'تعذر الاتصال بالمتجر لاستعادة عملية الشراء. حاول مرة أخرى.';
	@override String get nothingToRestore => 'لم يُعثر على عملية شراء PlezyNG مدى الحياة لحساب المتجر هذا.';
}

// Path: settings
class _Translations$settings$ar extends Translations$settings$en {
	_Translations$settings$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'الإعدادات';
	@override String get supportDeveloper => 'دعم PlezyNG';
	@override String get supportDeveloperDescription => 'التبرع بدعم التنمية';
	@override String get lifetimeAccess => 'PlezyNG الوصول مدى الحياة';
	@override String get language => 'اللغة';
	@override String get theme => 'السمة';
	@override String get appearance => 'ظهور';
	@override String get detailPage => 'صفحة تفاصيل';
	@override String get themeSongsEnabled => 'لعب الأغاني الموضوعية';
	@override String get themeSongsEnabledDescription => 'تلعب الأغاني الموضوعية المتاحة أثناء مشاهدة تفاصيل وسائل الإعلام.';
	@override String get themeSongVolume => 'موضوع الأغنية حجم';
	@override String get videoPlayback => 'أشرطة الفيديو Playback';
	@override String get videoPlaybackDescription => 'إعداد سلوك playback';
	@override String get advanced => 'متقدم';
	@override String get episodePosterMode => 'مسلسل Poster Style';
	@override String get seriesPoster => 'سلسلة الملصقات';
	@override String get seasonPoster => 'الموسم الملصقات';
	@override String get episodeThumbnail => 'التوماني';
	@override String get showHeroSectionDescription => 'شاشة تحتوي على محتوى الكاروسيل على الشاشة المنزلية';
	@override String get secondsLabel => 'ثانية';
	@override String get minutesLabel => 'دقائق';
	@override String get secondsShort => 'س';
	@override String get minutesShort => 'م';
	@override String durationHint({required Object min, required Object max}) => 'إدخال قيمة (${min}-${max})';
	@override String get systemTheme => 'النظام';
	@override String get lightTheme => 'الضوء';
	@override String get darkTheme => 'الظلام';
	@override String get oledTheme => 'OLED';
	@override String get emberTheme => 'الناس';
	@override String get glacierTheme => 'الجليد';
	@override String get forestTheme => 'الغابات';
	@override String get plumTheme => 'PLUM';
	@override String get paperTheme => 'الورق';
	@override String get libraryDensity => 'الكتب المكتبية';
	@override String get displayScale => 'عرض مقياس';
	@override String get compact => 'كومباكت';
	@override String get comfortable => 'مريح';
	@override String get gridSpacing => 'شبكة الفضاء';
	@override String get gridSpacingTight => 'تيتا';
	@override String get gridSpacingNormal => 'عادي';
	@override String get gridSpacingSpacious => 'الفضاء';
	@override String get tvCornerSpotlightBackdrop => 'الضوء الخلفي Spotlight Backdrop';
	@override String get tvCornerSpotlightBackdropDescription => 'عرض أعمال الفن في الزاوية اليمنى العليا بدلاً من ملء الشاشة';
	@override String get viewMode => 'رؤية الأزياء';
	@override String get gridView => 'شبكة';
	@override String get listView => 'قائمة';
	@override String get showHeroSection => 'عرض قسم البطل';
	@override String get showHomeBackdrop => 'عرض الفنون المنزلية الخلفية';
	@override String get showHomeBackdropDescription => 'عرض أعمال فنية كبيرة وراء صفوف المنزل المميزة';
	@override String get contentScreensaverEnabled => 'محتوى الشاشة';
	@override String get contentScreensaverEnabledDescription => 'عرض أعمال الفن على الشاشة الكاملة بعد أن أصبحت التطبيق مجنون';
	@override String get contentScreensaverDelay => 'بدء تشغيل الشاشة بعد';
	@override String get contentScreensaverLibraries => 'الكتب المكتبية الشاشة';
	@override String get contentScreensaverLibrariesDescription => 'اختر أي مكتبات توفر عمل الفن الذي يحفظ الشاشة.إذا لم يتم اختيار أي منها، يتم استخدام عمل الفن من جميع المكتبات.';
	@override String get contentScreensaverAllLibraries => 'كل المكتبات';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} المكتبات المختارة';
	@override String get contentScreensaverNoLibraries => 'لا توجد مكتبات وسائل الإعلام المرتبطة.';
	@override String get contentScreensaverDismissHint => 'اضغط على أي زر أو اضغط على إلغاء';
	@override String get newEpisodeNotifications => 'إشعارات الحلقة الجديدة';
	@override String get newEpisodeNotificationsDescription => 'تحذير عندما يتم إضافة حلقة جديدة إلى عرض تم التقاطها. التحقق بينما Plezy مفتوحة.';
	@override String get continueWatchingRowSize => 'مواصلة مشاهدة حجم الخط';
	@override String continueWatchingRowSizeValue({required Object label}) => '${label} بطاقات';
	@override String get rowSizeCompact => 'كومباكت';
	@override String get rowSizeStandard => 'المعيار';
	@override String get rowSizeLarge => 'كبير';
	@override String get continueWatchingAction => 'مواصلة مراقبة العمل';
	@override String get continueWatchingPlay => 'تشغيل';
	@override String get continueWatchingDetails => 'التفاصيل المفتوحة';
	@override String get episodeAction => 'الحلقة العملية';
	@override String get episodePlay => 'تشغيل';
	@override String get episodeDetails => 'التفاصيل المفتوحة';
	@override String get useGlobalHubs => 'استخدام Home Layout';
	@override String get useGlobalHubsDescription => 'إظهار المراكز المنزلية الموحدة.إلا استخدم توصيات المكتبة.';
	@override String get showServerNameOnHubs => 'عرض اسم الخادم على Hubs';
	@override String get showServerNameOnHubsDescription => 'يظهر دائمًا أسماء الخوادم في عناوين hub.';
	@override String get groupLibrariesByServer => 'مكتبات المجموعات حسب الخادم';
	@override String get groupLibrariesByServerDescription => 'مكتبات صفحة المجموعة تحت كل خادم وسائل الإعلام.';
	@override String get alwaysKeepSidebarOpen => 'الحفاظ دائما على الجانب المفتوح';
	@override String get alwaysKeepSidebarOpenDescription => 'يبقى شريط الجانب واسع النطاق ويتم تعديل نطاق المحتوى لتناسب';
	@override String get showUnwatchedCount => 'إظهار عدد غير ملاحظ';
	@override String get showUnwatchedCountDescription => 'عرض الحلقة غير المشاهدة حساب على العروض والموسم';
	@override String get showWatchedIndicators => 'عرض المؤشرات الملاحظة';
	@override String get showWatchedIndicatorsDescription => 'إظهار علامة تحقق على الأفلام والمسرحيات والأحداث التي شاهدتها';
	@override String get showEpisodeNumberOnCards => 'عرض الحلقة رقم على البطاقات';
	@override String get showEpisodeNumberOnCardsDescription => 'عرض الموسم ورقم الحلقة على بطاقات الحلقة';
	@override String get showSeasonPostersOnTabs => 'عرض الملصقات الموسمية على Tabs';
	@override String get showSeasonPostersOnTabsDescription => 'عرض ملصقات كل موسم فوق علامة التبويب الخاصة به';
	@override String get tvFullCardLayout => 'بطاقات التلفزيون الكاملة';
	@override String get tvFullCardLayoutDescription => 'استخدم بطاقات التلفزيون الصورة فقط مع أسماء الممثلين';
	@override String get focusGlow => 'التركيز الضوء';
	@override String get focusGlowDescription => 'ضع ضوءًا ناعمًا حول بطاقة التركيز';
	@override String get visualEffects => 'التأثيرات البصرية';
	@override String get visualEffectsAuto => 'تلقائي';
	@override String get visualEffectsAutoDescription => 'تقليل الآثار تلقائيًا على أجهزة منخفضة الطاقة';
	@override String get visualEffectsFull => 'كاملة';
	@override String get visualEffectsReduced => 'انخفاض';
	@override String get visualEffectsReducedDescription => 'عدد أقل من الرسوم المتحركة والعمل الفني أدنى القرار';
	@override String get hideSpoilers => 'إخفاء البلاطات للمناقشات غير الملاحظة';
	@override String get hideSpoilersDescription => 'صور ووصفات للأحداث غير الملاحظة';
	@override String get playerBackend => 'اللاعب Backend';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'التخزين الصلب';
	@override String get hardwareDecodingDescription => 'استخدم تسارع الأجهزة عندما يكون متاحًا';
	@override String get playbackBuffer => 'لعبة Playback Buffer';
	@override String get playbackBufferAuto => 'السيارة (موصى بها )';
	@override String get playbackBufferLarge => 'كبير';
	@override String get playbackBufferExtraLarge => 'كبير جدًا';
	@override String get playbackBufferDescription => 'المزيد عن اتصالات غير مستقرة.المحدود أيضا بواسطة حجم البوفر.';
	@override String get streamBufferSize => 'حجم البوفر';
	@override String streamBufferSizeValue({required Object size}) => '${size} MB';
	@override String get streamBufferSizeDescription => 'كم عدد مقاطع الفيديو التي يجب تحميلها إلى الأمام عند اللعب المباشر.توقف ترانسكودات على خادم ترانسكود الخاص بك. 0 = التلقائي';
	@override String get streamBufferSizeExoNote => 'استبدال Playback Buffer عند إعدادها، مقطوعة إلى نصف حدود الذاكرة في التطبيق';
	@override String get streamBufferMegabytes => 'ميغابيت';
	@override String get defaultQualityTitle => 'الجودة الافتراضية';
	@override String get cellularQualityTitle => 'الجودة الافتراضية على الخلايا';
	@override String get remoteQualityTitle => 'جودة البث عن بعد';
	@override String get remoteQualitySameAsDefault => 'كما هو الحال مع الجودة الافتراضية';
	@override String get cellularQualitySameAsDefault => 'كما هو الحال مع الجودة الافتراضية';
	@override String get directPlayCoveredQuality => 'تلعب أشرطة الفيديو الصغيرة في الجودة الأصلية';
	@override String get directPlayCoveredQualityDescription => 'تشغيل الفيديو مباشرة بالفعل ضمن حدود الجودة بدلا من إعادة ترميزها';
	@override String get videoCodecs => 'فيديو كوديك';
	@override String get videoCodecsDescription => 'يتم ترتيب الرموز غير المختبرة من قبل الخادم';
	@override String get videoCodecsAlwaysAccepted => 'دائما مقبولة';
	@override String get musicQualityTitle => 'جودة الموسيقى';
	@override String get subtitleStyling => 'تنسيق الترجمة';
	@override String get subtitleStylingDescription => 'تخصيص مظهر العناوين';
	@override String get smallSkipDuration => 'قصة قصيرة طويلة';
	@override String get largeSkipDuration => 'طوله طوله طوله';
	@override String get rewindOnResume => 'عودة على المجلد';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(seconds,
		zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} ثانية',
		one: 'ثانية',
		two: 'ثانيتان',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} ثوان',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} ثانية',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} ثانية',
	);
	@override String get defaultSleepTimer => 'أوقات النوم الافتراضية';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(minutes,
		zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} دقيقة',
		one: 'دقيقة',
		two: 'دقيقتان',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} دقائق',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} دقيقة',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} دقيقة',
	);
	@override String get rememberTrackSelections => 'تذكر اختيارات المسارات حسب عرض/فيلم';
	@override String get chooseTracksBeforePlayback => 'اختيار الأصوات والأسماء الفرعية قبل تشغيل';
	@override String get chooseTracksBeforePlaybackDescription => 'اقرأ الصوت المصدر ومتابعة العناوين الفرعية قبل أن يبدأ كل مقطع فيديو.';
	@override String get alwaysShowSubtitlesOnDevice => 'إظهار دائمًا العناوين الفرعية على هذا الجهاز';
	@override String get alwaysShowSubtitlesOnDeviceDescription => 'إذا لم يكن الخادم لديه أي عنوان فرعي، اختر مسارًا محليًا، وهذا لا يغير أبدًا تفضيل الخادم.';
	@override String get autoDownloadPreferredSubtitle => 'فاتش يفتقر إلى عناوين اللغة المفضلة';
	@override String get autoDownloadPreferredSubtitleDescription => 'حدد علامة فرعية متوفرة في لغتك المفضلة محليًا.إذا لم تكن موجودة، اطلب من الخادم أن يلتقط علامة فرعية عند دعمها.';
	@override String get rememberTrackSelectionsDescription => 'تخزين خيارات الصوت والعلامات الفرعية حسب العرض أو الفيلم على هذا الجهاز';
	@override String get rememberTrackSelectionsBackendRule => 'يعمل محليًا مع Plex و Jellyfin و Emby و Plex و Jellyfin يمكن أيضًا حفظ الاختيارات على الخادم';
	@override String get followServerTrackSelections => 'استخدم اختيارات المسار لكل حلقة من الخادم';
	@override String get followServerTrackSelectionsDescription => 'عند تغيير الحلقة، قم بتطبيق الصوت والقبعات المختارة على الخادم بدلاً من إجراء الاختيار الحالي.';
	@override String get resumeMusicOnLaunch => 'تذكر جلسة الموسيقى';
	@override String get resumeMusicOnLaunchDescription => 'إعادة فتح الأغنية الأخيرة توقفت حيث غادرت عند بدء التطبيق';
	@override String get showChapterMarkersOnTimeline => 'عرض علامات الفصل على البحث البار';
	@override String get showChapterMarkersOnTimelineDescription => 'القسم البار البحث في حدود الفصل';
	@override String get specialsOrdering => 'مميزات في ترتيب الحلقة';
	@override String get specialsOrderingDescription => 'حيث يلعب المتخصصون في ترتيب الساعة في العرض';
	@override String get specialsOrderingServer => 'اتبع أوامر الخادم';
	@override String get specialsOrderingAirDate => 'التوقيت حسب تاريخ الهواء';
	@override String get specialsOrderingLast => 'بعد الموسم العادي';
	@override String get clickVideoTogglesPlayback => 'انقر على الفيديو لالتقاط اللعب/الراحة';
	@override String get clickVideoTogglesPlaybackDescription => 'انقر على الفيديو للعب/التوقف بدلاً من عرض التحكم.';
	@override String get videoPlayerControls => 'التحكم في ألعاب الفيديو';
	@override String get keyboardShortcuts => 'لوحة مفاتيح قصيرة';
	@override String get keyboardShortcutsDescription => 'تخصيص أقراص لوحة المفاتيح';
	@override String get videoPlayerNavigation => 'ألعاب الفيديو الملاحة';
	@override String get videoPlayerNavigationDescription => 'استخدم مفتاح الرصاص للتحكم في مشغل الفيديو';
	@override String get watchTogetherRelay => 'مشاهدة فيلم Relay';
	@override String get watchTogetherRelayDescription => 'الحفلات العامة المفتوحة تنشر ما لم تضع نفسك';
	@override String get watchTogetherRelayHint => 'https://my-relay.example.com';
	@override String get watchTogetherRelayInvalid => 'أدخل عنوان URL أساسيًا صالحًا لخادم الترحيل باستخدام HTTP أو HTTPS.';
	@override String get crashReporting => 'تقرير الكارثة';
	@override String get crashReportingDescription => 'إرسال تقارير عن الحوادث للمساعدة في تحسين التطبيق';
	@override String get debugLogging => 'دبي تسجيل الدخول';
	@override String get debugLoggingDescription => 'إمكانية تسجيل مفصل لحل المشكلات';
	@override String get viewLogs => 'مشاهدة Logs';
	@override String get viewLogsDescription => 'مشاهدة التطبيقات';
	@override String get clearImageCache => 'صورة واضحة';
	@override String get clearImageCacheDescription => 'يمكن تحميل الصور ببطء حتى يتم تنزيلها مرة أخرى.';
	@override String get clearImageCacheSuccess => 'تم إزالة الصور بنجاح';
	@override String get resetSettings => 'إعادة إعدادات';
	@override String get resetSettingsDescription => 'استعادة الإعدادات الافتراضية.هذا لا يمكن أن يكون دون.';
	@override String get resetSettingsSuccess => 'إعادة تعيين الإعدادات بنجاح';
	@override String get backup => 'النسخ الاحتياطي';
	@override String get exportSettings => 'إعدادات التصدير';
	@override String get exportSettingsDescription => 'حفظ تفضيلاتك إلى ملف';
	@override String get exportSettingsSuccess => 'الإعدادات المستوردة';
	@override String get importSettings => 'إعدادات الواردات';
	@override String get importSettingsDescription => 'استعادة تفضيلات من ملف';
	@override String get importSettingsConfirm => 'هذا سيحل محل إعداداتك الحالية.مواصلة؟';
	@override String get importSettingsSuccess => 'الإعدادات المستوردة';
	@override String get importSettingsInvalidFile => 'هذا الملف غير صالحة PlezyNG إعدادات تصدير';
	@override String get importSettingsNoUser => 'تسجيل الدخول قبل استيراد الإعدادات';
	@override String get cloudBackup => 'سحابة النسخ الاحتياطي';
	@override String get cloudBackupDescription => 'انسخ الإعدادات القابلة للنقل احتياطيًا إلى نقطة اتصال WebDAV عبر HTTPS. تبقى اتصالات الخادم وبيانات تسجيل الدخول على هذا الجهاز.';
	@override String get cloudBackupUrl => 'WebDAV JSON ملف URL';
	@override String get cloudBackupUsername => 'اسم المستخدم';
	@override String get cloudBackupPassword => 'كلمة المرور';
	@override String get cloudBackupSaved => 'سحابة النسخ الاحتياطي المستهدفة';
	@override String get cloudBackupNow => 'العودة الآن';
	@override String get cloudBackupComplete => 'إعدادات النسخ الاحتياطي تحميل';
	@override String get cloudBackupRestore => 'استعادة النسخ الاحتياطي';
	@override String get cloudBackupRestoreConfirm => 'هذا سوف يحل محل إعدادات المحمول المقابلة على هذا الجهاز.';
	@override String get cloudBackupRestored => 'إعدادات استعادة من النسخ الاحتياطي السحابية';
	@override String get shortcutsReset => 'إعادة تعيين القصص إلى الافتراضات';
	@override String get resetShortcutsConfirm => 'هذا سوف يحل محل اختصاراتك المخصصة مع الافتراضات.';
	@override String get about => 'حول';
	@override String get aboutDescription => 'تطبيق المعلومات والترخيص';
	@override String get updates => 'تحديثات';
	@override String get updateAvailable => 'التحديثات المتاحة';
	@override String get checkForUpdates => 'تحقق من التحديثات';
	@override String get autoCheckUpdatesOnStartup => 'التحقق تلقائيًا من التحديثات على Startup';
	@override String get autoCheckUpdatesOnStartupDescription => 'إشعار عندما يكون التحديث متاحًا عند الإطلاق';
	@override String get validationErrorEnterNumber => 'يرجى إدخال رقم صالح';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'يجب أن يكون بين ${min} و ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'القطع القصيرة المخصصة بالفعل لـ ${action}';
	@override String shortcutUpdated({required Object action}) => 'قصة قصيرة تم تحديثها لـ ${action}';
	@override String get saveFailed => 'لا يمكن حفظ التغييرات، حاول مرة أخرى.';
	@override String get autoPlayAndSkip => 'لعبة Auto-Play & Skip';
	@override String get autoPlayNextEpisode => 'أوتوماتيك الحلقة التالية';
	@override String get autoPlayNextEpisodeDescription => 'بدء الحلقة التالية تلقائيًا عندما تنتهي';
	@override String get shuffleStartsFromBeginning => 'شافلي يبدأ في البداية';
	@override String get shuffleStartsFromBeginningDescription => 'ابدأ كل حلقة في البداية عند التفريغ بدلاً من إعادة التفريغ';
	@override String get plexCinemaPreRoll => 'استخدام الخادم السينما داخل';
	@override String get plexCinemaPreRollDescription => 'تلعب إعداد Plex أو Jellyfin و Emby قبل بدء الفيلم.';
	@override String get playNextCountdown => 'اللعب التالي حساب';
	@override String get playNextCountdownImmediate => 'اللعب على الفور';
	@override String get skipIntroMode => 'سكاي إنترو';
	@override String get skipIntroModeOffDescription => 'لعب الدخول بشكل طبيعي دون زر التزلج';
	@override String get skipIntroModeButtonDescription => 'إظهار زر التزلج عند بدء إدخال';
	@override String get skipIntroModeAutoDescription => 'إسقاط الدخول تلقائيًا بعد التأخير أدناه';
	@override String get skipCreditsMode => 'سكاي الائتمان';
	@override String get skipCreditsModeOffDescription => 'لعب الائتمان عادة دون زر التزلج';
	@override String get skipCreditsModeButtonDescription => 'إظهار زر التزلج عند بدء الائتمان';
	@override String get skipCreditsModeAutoDescription => 'سحب الائتمان تلقائيًا وتلعب الحلقة التالية';
	@override String get skipAdsMode => 'إعلانات Skip';
	@override String get skipAdsModeOffDescription => 'تلعب الإعلانات التي تم اكتشافها بشكل طبيعي دون زر التزلج';
	@override String get skipAdsModeButtonDescription => 'إظهار زر التزلج عند اكتشاف إعلان Plex';
	@override String get skipAdsModeAutoDescription => 'إلغاء الإعلانات التي تم اكتشافها تلقائيًا بعد التأخير أدناه';
	@override String get musicPlayback => 'الموسيقى Playback';
	@override String get musicSweetFades => 'الحلوة الفاتحة';
	@override String get musicSweetFadesDescription => 'يضع الموسيقى في أطراف المسار عندما يحتوي Plex على بيانات الضوضاء.';
	@override String get skipMarkerModeOff => 'إيقاف';
	@override String get skipMarkerModeButton => 'عرض الزر';
	@override String get skipMarkerModeAuto => 'أوتوماتيك';
	@override String get forceSkipMarkerFallback => 'قوة Fallback Markers';
	@override String get forceSkipMarkerFallbackDescription => 'استخدم نماذج العنوان في الفصل حتى إذا كان Plex لديه علامات';
	@override String get theIntroDbFallback => 'استخدم TheIntroDB كإسقاط مقدمة';
	@override String get theIntroDbFallbackDescription => 'لا تستخدم مواعيد المجتمع إلا عندما لا يحتوي الخادم على علامة إدخال.';
	@override String get autoSkipDelay => 'تأخير السيارة';
	@override String autoSkipDelayDescription({required Object seconds}) => 'الانتظار ${seconds} ثانية قبل الانزلاق الذاتي';
	@override String get introPattern => 'نموذج علامة التبويب';
	@override String get introPatternDescription => 'نموذج Regex لتناسب علامات intro في عناوين الفصول';
	@override String get creditsPattern => 'الائتمان علامة نموذج';
	@override String get creditsPatternDescription => 'نموذج ريجكس لتناسب علامات الائتمان في عناوين الفصول';
	@override String get prerolls => 'البروتوكول';
	@override String get playPrerollsBeforeMovies => 'ألعاب الفيديو قبل الأفلام';
	@override String get playPrerollsBeforeMoviesDescription => 'لعب مقطع عشوائي من اختيارك أدناه قبل كل فيلم.';
	@override String get prerollLibrary => 'مكتبة Preroll';
	@override String get prerollLibraryNotSet => 'لا تضع';
	@override String get prerollLibraryNoneFound => 'لا توجد مكتبات على خادماتك.';
	@override String get prerollSelection => 'المختارين المختارين';
	@override String get prerollSelectionPickLibraryFirst => 'اقرأ المكتبة أولاً';
	@override String get prerollSelectionNoneSelected => 'لا توجد أطراف مختارة';
	@override String prerollSelectionCount({required Object count}) => '${count} تم اختيارها';
	@override String get prerollItemPicker => 'اختياره preroll';
	@override String get prerollItemPickerLoadFailed => 'لا يمكن تحميل العناصر من هذه المكتبة.';
	@override String get invalidRegex => 'تعبيرات غير منتظمة';
	@override String get regex => 'التعبير المنتظم';
	@override String get downloads => 'التنزيلات';
	@override String get downloadLocationDescription => 'اختيار المكان الذي يمكن تخزين المحتوى الذي تم تنزيله';
	@override String get downloadLocationDefault => 'التخزين الافتراضي (App Storage)';
	@override String get downloadLocationCustom => 'الموقع المخصص';
	@override String get selectFolder => 'اختيار المجلد';
	@override String get resetToDefault => 'إعادة تشغيل الافتراضي';
	@override String currentPath({required Object path}) => 'الحالي: ${path}';
	@override String get downloadLocationChanged => 'تحميل الموقع تغير';
	@override String get downloadLocationReset => 'تحميل موقع إعادة تعيين إلى الافتراض';
	@override String get downloadLocationInvalid => 'المجلد المختار غير قابل للكتابة';
	@override String get downloadLocationPickerUnavailable => 'لا توجد خيارات المجلدات متاحة على هذا الجهاز';
	@override String get downloadOnWifiOnly => 'تنزيل على Wi-Fi فقط';
	@override String get downloadOnWifiOnlyDescription => 'تجنب تنزيلات عند البيانات الخلوية';
	@override String get autoRemoveWatchedDownloads => 'إزالة السيارات مشاهدة تحميل';
	@override String get autoRemoveWatchedDownloadsDescription => 'إزالة النسخ التي تمت مشاهدتها تلقائيًا';
	@override String get autoDownloadContinueWatching => 'تحميل تلقائي مواصلة مشاهدة';
	@override String get autoDownloadContinueWatchingDescription => 'احفظ العناصر على قفص المتابعة المستمرة الخاص بك تحميل، وإزالتها بمجرد أن يغادروا قفص';
	@override String get downloadQuality => 'تحميل الجودة';
	@override String get downloadQualityDescription => 'Plex يعد نسخة محولة في سجل تنزيلها. Jellyfin و Emby ترانسكود بينما تنزيل الملف؛ قد تحتاج التحويلات المتوقفة إلى إعادة تشغيل.';
	@override String get askDownloadQualityEachTime => 'اختيار الجودة لكل تحميل';
	@override String get askDownloadQualityEachTimeDescription => 'إظهار الجودة الرائدة قبل إزالة كل تحميل الفيديو';
	@override String get cellularDownloadBlocked => 'يتم حظر التنزيلات على الهاتف المحمول.استخدم Wi-Fi أو تغيير الإعداد.';
	@override String get maxVolume => 'الحد الأقصى لمستوى الصوت';
	@override String get maxVolumeDescription => 'السماح برفع مستوى الصوت فوق 100% للمحتوى ذي الصوت المنخفض';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'ضعف غنية الحضور';
	@override String get discordRichPresenceDescription => 'إظهار ما تشاهده على Discord';
	@override String get services => 'الخدمات';
	@override String get servicesDescription => 'الاتصال Trakt, MyAnimeList, Seerr, وأكثر من ذلك';
	@override String get manageLibrariesDescription => 'إعادة ترتيب وإخفاء المكتبات';
	@override String get companionRemoteServer => 'الخادم عن بعد';
	@override String get companionRemoteServerDescription => 'السماح للأجهزة المحمولة على شبكتك بالتحكم في هذا التطبيق';
	@override String get companionRemoteServerStartFailed => 'لا يمكن إطلاق الخادم المرافق';
	@override String get companionRemoteServerStopFailed => 'لا يمكن إيقاف الخادم المرافق';
	@override String get autoPip => 'صورة في صورة Auto Picture';
	@override String get autoPipDescription => 'إدخال صورة في الصورة تلقائيًا عند مغادرة التطبيق أثناء تشغيل';
	@override String get matchContentFrameRate => 'مقارنة محتوى إطار معدل';
	@override String get matchContentFrameRateDescription => 'عرض المباراة معدل التجديد إلى محتوى الفيديو';
	@override String get matchContentResolution => 'حل المحتوى Match';
	@override String get matchContentResolutionDescription => 'قم بتحويل الشاشة إلى الدقة الأصلية للفيديو بحيث يتصرف التلفزيون الخاص بك بشكل متزايد.';
	@override String get matchRefreshRate => 'مسابقة التجديد معدل';
	@override String get matchRefreshRateDescription => 'عرض المباراة معدل التجديد على الشاشة الكاملة';
	@override String get matchDynamicRange => 'نطاق المنافسة الديناميكية';
	@override String get matchDynamicRangeDescription => 'تحويل HDR إلى محتوى HDR ثم العودة إلى SDR';
	@override String get displaySwitchDelay => 'عرض التبديل المتأخر';
	@override String get tunneledPlayback => 'لعبة النفق Playback';
	@override String get tunneledPlaybackDescription => 'إلغاء تشغيل HDR إذا عرض الفيديو الأسود أو أشرطة الفيديو الحركية.';
	@override String get audioPassthrough => 'الصوت المضغوط';
	@override String get audioPassthroughDescription => 'إرسال صوت Dolby/DTS إلى المستلم أو التلفزيون دون إعادة التشفير، والحفاظ على الصوت المحيط.';
	@override String get audioPassthroughDescriptionApple => 'استخدم محفز Dolby الأصلي من Apple لـ Dolby Digital Plus ، بما في ذلك Atmos. DTS و TrueHD لا تزال تلعب كPCM متعدد القنوات.';
	@override String get audioPassthroughDescriptionAppleSpatial => 'استخدم محفز Dolby الأصلي من Apple لـ Dolby Digital Plus ، بما في ذلك Atmos. على iOS ، iPadOS و tvOS 26 أو لاحقًا ، يلعب TrueHD Atmos و DTS:X كصوت فضاء.';
	@override String get audioPassthroughOverriddenByNormalization => 'انقطع أثناء تشغيل الضوضاء';
	@override String get audioChannelLimit => 'قنوات الصوت';
	@override String get audioChannelLimitDescription => 'يخلط الصوت المكسور إلى أسفل للمكبرات الصوتية أو سماعات الرأس أو إعدادات HDMI التي لا يمكن تشغيل كل قناة';
	@override String get audioChannelLimitOriginal => 'الأصلي';
	@override String get audioChannelLimitOriginalDescription => 'لعب كل قناة في المسار';
	@override String get audioChannelLimitSurround51 => 'حتى 5.1';
	@override String get audioChannelLimitSurround51Description => 'يخلط 7.1 إلى 5.1 بالنسبة للتلفزيونات والمستلمين الذين يستغرقون 5.1 PCM فقط.';
	@override String get audioChannelLimitStereo => 'ستيريو (Stereo)';
	@override String get audioChannelLimitStereoDescription => 'يخلط إلى اثنين من القنوات للمكبرات الصوتية الستيريو أو سماعات الرأس.';
	@override String get downmixCenterBoost => 'تعزيز القناة الوسطى';
	@override String downmixCenterBoostValue({required Object db}) => '${db} دبي';
	@override String get downmixCenterBoostLabel => 'الارتفاع (dB )';
	@override String get downmixCenterBoostShort => 'دبي';
	@override String get audioDownmixNormalize => 'تحديد الحجم على Downmix';
	@override String get audioDownmixNormalizeDescription => 'انخفاض المزيج لمنع الانحناء. انقطع للحفاظ على الحجم الأصلي (قد يفسد المشاهد الصاخبة).';
	@override String get dvConversionMode => 'Dolby Vision تحويل';
	@override String get dvConversionModeDescription => 'اختر كيفية التعامل مع ملفات Dolby Vision الملف 7.';
	@override String get dvConversionAuto => 'تلقائي';
	@override String get dvConversionNative => 'الأصلي / المعاق';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'استخدام الكشف عن القدرة على الجهاز والسلوك السقوط الطبيعي';
	@override String get dvConversionNativeDescription => 'القوة الأصلية DV7 و القمع DV التحويل الانسحاب';
	@override String get dvConversionDv81Description => 'تحويل قوة RPU إلى Dolby Vision ملف تعريف 8.1';
	@override String get dvConversionHevcStripDescription => 'شريط Dolby Vision طبقات RPU/EL والطابق الحالي HEVC';
	@override String get disableDolbyVision => 'غير قابلة للتطبيق Dolby Vision';
	@override String get disableDolbyVisionDescription => 'تلعب طبقة الملف HDR10 أو HLG بدلاً من Dolby Vision ، عندما يكون لديه طبقة واحدة';
	@override String get hdrSdrConversion => 'تحويل HDR إلى SDR';
	@override String get hdrSdrConversionDescription => 'اختر ما الذي يحول فيديو HDR عندما لا يمكن لعرض الشاشة عرض HDR.';
	@override String get hdrSdrConversionAuto => 'تلقائي';
	@override String get hdrSdrConversionAutoDescription => 'الأجهزة على Android 9 وما بعدها، اللاعب على الإصدارات القديمة';
	@override String get hdrSdrConversionDevice => 'الجهاز';
	@override String get hdrSdrConversionDeviceDescription => 'أجهزة الفيديو في جهازك تحولها.أسرع، ولكن الألوان تعتمد على الجهاز';
	@override String get hdrSdrConversionPlayer => 'المشغّل';
	@override String get hdrSdrConversionPlayerDescription => 'الألوان المتسقة، ولكن 4K يمكن أن يضرب على صناديق التلفزيون منخفضة النهاية';
	@override String get deinterlace => 'التفاوض';
	@override String get deinterlaceDescription => 'إزالة المكونات المختلطة من الفيديو المختلط (mpv لاعب فقط)';
	@override String get deinterlaceOff => 'إيقاف';
	@override String get deinterlaceOffDescription => 'عرض الفيديو المترابط كما هو مخفف';
	@override String get deinterlaceVideo => 'مرئي';
	@override String get deinterlaceVideoDescription => 'تحويل كل حقل إلى إطار كامل.للصور الفيديو للتلفزيون، مثل الرياضة والأخبار والمؤتمرات';
	@override String get deinterlaceFilm => 'فيلم';
	@override String get deinterlaceFilmDescription => 'استعادة الإطارات الأصلية للفيلم والرسوم المتحركة التلفزيونية إلى 29.97 fps، شائعة على أقراص NTSC DVDs.';
	@override String get requireProfileSelectionOnOpen => 'طلب الملف الشخصي على التطبيق المفتوح';
	@override String get requireProfileSelectionOnOpenDescription => 'إظهار اختيار الملف الشخصي في كل مرة يتم فتح التطبيق';
	@override String get forceTvMode => 'قوة التلفزيون';
	@override String get forceTvModeDescription => 'قوة التلفزيون ترتيب.للأجهزة التي لا تكتشف تلقائيا.يتطلب إعادة تشغيل.';
	@override String get startInFullscreen => 'بدءاً من الشاشة الكاملة';
	@override String get startInFullscreenDescription => 'فتح PlezyNG في وضع الشاشة الكاملة عند الإطلاق';
	@override String get exitFullscreenOnPlayerClose => 'الخروج الشاشة الكاملة على اللاعب مغلقة';
	@override String get exitFullscreenOnPlayerCloseDescription => 'يخرج الشاشة الكاملة تلقائيًا عند إغلاق مشغل الفيديو';
	@override String get autoHidePerformanceOverlay => 'أداء التخفيف التلقائي';
	@override String get autoHidePerformanceOverlayDescription => 'إزالة الأداء مع التحكم في التعبير';
	@override String get showNavBarLabels => 'إظهار علامات البار الملاحة';
	@override String get showNavBarLabelsDescription => 'عرض علامات النص تحت أيقونات شريط الملاحة';
	@override String get startupSection => 'القسم Startup';
	@override String get preferredServer => 'الخادم المفضل';
	@override String get preferredServerDescription => 'أولوية نتائج هذا الخادم مع الحفاظ على كل خادم متصل متاح.';
	@override String get preferredServerAutomatic => 'أوتوماتيك';
	@override String get showExploreTab => 'عرض البحث Tab';
	@override String get showExploreTabDescription => 'عرض علامة التبويب استكشاف مع المحتوى من Plex اكتشاف ومتابعي متصلة';
	@override String get hideEmptyLibraries => 'إخفاء المكتبات الفارغة';
	@override String get hideEmptyLibrariesDescription => 'إزالة المكتبات مع عدد العناصر التي تم الإبلاغ عنها من الخادم من الصفر من الملاحة.';
	@override String get liveTvDefaultFavorites => 'قناة المفضلة المفضلة';
	@override String get liveTvDefaultFavoritesDescription => 'عرض القنوات المفضلة فقط عند فتح التلفزيون المباشر';
	@override String get general => 'عام';
	@override String get generalDescription => 'اللغة والبدء والنافذة السلوك';
	@override String get languageAndRegion => 'اللغة والمنطقة';
	@override String get startup => 'بدء التشغيل';
	@override String get display => 'العرض';
	@override String get libraryAndCards => 'المكتبة والبطاقات';
	@override String get homeScreen => 'Home شاشة';
	@override String get navigation => 'التنقل';
	@override String get window => 'نافذة';
	@override String get liveTv => 'البث التلفزيوني المباشر';
	@override String get player => 'المشغّل';
	@override String get videoAndDisplay => 'الفيديو & عرض';
	@override String get audio => 'الصوت';
	@override String get quality => 'الجودة';
	@override String get subtitles => 'الترجمة';
	@override String get seekAndTiming => 'البحث والتوقيت';
	@override String get behavior => 'السلوك';
	@override String get gestures => 'الإيماءات';
	@override String get gestureBrightnessSwipe => 'الضوء يتلاشى';
	@override String get gestureBrightnessSwipeDescription => 'انحنى إلى الأعلى أو إلى الأسفل على الحافة اليسرى لتعديل الضوء';
	@override String get gestureVolumeSwipe => 'حجم Swipe';
	@override String get gestureVolumeSwipeDescription => 'انحنى إلى الأعلى أو إلى الأسفل على الحافة اليمنى لتعديل الحجم';
	@override String get gesturePinchToZoom => 'إرسال رسالة إلى Zoom';
	@override String get gesturePinchToZoomDescription => 'اضغط على الفيديو للزوم داخل أو خارج';
	@override String get gestureSeekSwipe => 'البحث عن Swipe';
	@override String get gestureSeekSwipeDescription => 'تحريك اليسار أو اليمين في أي مكان في الفيديو للبحث؛ إطلاق النار للقفز';
	@override String get rememberBrightnessLevel => 'تذكر مستوى الضوء';
	@override String get rememberBrightnessLevelDescription => 'بدء تشغيل على الضوء المحدد من قبل النسخ الأخير';
	@override String get controls => 'عناصر التحكم';
	@override String get rememberPlayerChanges => 'تذكر تغييرات اللاعبين';
	@override String get rememberPlayerChangesDescription => 'حيث يتم حفظ التغيير الذي تم إجراؤه أثناء اللعب وإعادة التطبيق من';
	@override String get scopePlaybackSpeed => 'سرعة التشغيل';
	@override String get scopeShaderPreset => 'شاتر Preset';
	@override String get scopeAspectRatio => 'نسبة العرض إلى الارتفاع';
	@override String get scopeSyncOffsets => 'الصوت و Subtitle Sync';
	@override String get playerScopeOff => 'لا ينقذ';
	@override String get playerScopeGlobal => 'في كل مكان';
	@override String get playerScopeLibrary => 'بواسطة المكتبة';
	@override String get playerScopeTitle => 'من خلال عرض أو فيلم';
	@override String get exportDialogTitle => 'تصدير PlezyNG إعدادات';
	@override String get followSystem => 'اتباع لغة النظام';
	@override String get followAppLanguage => 'مطابقة لغة الواجهة';
	@override String get regionFormat => 'التنسيقات الإقليمية';
	@override String get regionFormatDescription => 'اختر طريقة عرض التواريخ والأرقام ووحدات القياس.';
	@override String get metadataLanguage => 'لغة بيانات الوسائط';
	@override String get metadataLanguageDescription => 'لغة العناوين والأوصاف المفضلة عندما يدعمها الخادم. تُضبط تفضيلات الصوت والترجمة بشكل مستقل.';
	@override String get experimentalDolbyVision => 'Dolby Vision التجريبي';
	@override String get experimentalDolbyVisionDescription => 'استخدم عارض FEL التجريبي عند التشغيل التالي. يتطلب إصدارًا منفصلًا من المحرك.';
	@override String get dvExperimentUnavailableDescription => 'هذه التجربة متاحة حاليًا على Linux فقط.';
	@override String get dvCompatibilityFallback => 'الرجوع للتوافق';
	@override String get dvCompatibilityFallbackDescription => 'استخدم العارض القياسي إذا تعذر بدء التجربة. قد تُفقد بيانات FEL.';
	@override String get dvExperimentDiagnostics => 'تسجيل تجربة الفيديو';
	@override String get dvExperimentDiagnosticsDescription => 'فعّل سجلات المشغّل التفصيلية عند التشغيل التالي.';
}

// Path: themeEditor
class _Translations$themeEditor$ar extends Translations$themeEditor$en {
	_Translations$themeEditor$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get builtIn => 'بناء في';
	@override String get presets => 'الكهنوت';
	@override String get custom => 'مخصص';
	@override String get customEmpty => 'لم يخلق بعد';
	@override String get editCustom => 'تحرير الموضوع المخصص';
	@override String get editCustomDescription => 'اختر كل لون بنفسك';
	@override String get locked => 'الوصول مدى الحياة مطلوب';
	@override String get savedLocked => 'تم توفيرها - متوفرة مع الوصول مدى الحياة';
	@override String get title => 'موضوع مخصص';
	@override String get startFrom => 'بدءاً من';
	@override String get startFromDescription => 'نسخ جميع الألوان من موضوع آخر';
	@override String get colors => 'الألوان';
	@override String get preview => 'معاينة';
	@override late final _Translations$themeEditor$slots$ar slots = _Translations$themeEditor$slots$ar._(_root);
	@override String get opacity => 'التواضع';
	@override String get hexHint => '#RRGGBB أو #AARRGGBB';
	@override String get fromOtherThemes => 'من مواضيع أخرى';
	@override String swatchLabel({required Object theme, required Object color}) => '${theme} ${color}';
	@override late final _Translations$themeEditor$contrast$ar contrast = _Translations$themeEditor$contrast$ar._(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}: 1، أقل من الموصى به ${minimum}:1';
	@override String get discardTitle => 'هل تتجاهل التغييرات؟';
	@override String get discardMessage => 'سيتم فقدان تغييرات اللون غير المحفوظة.';
	@override String get discard => 'ديكارد';
	@override String previewCardTitle({required Object number}) => 'الحلقة ${number}';
	@override String previewCardSubtitle({required Object minutes}) => '${minutes} دقيقة متبقية';
	@override String get previewSwitch => 'التشغيل التلقائي';
	@override String get previewMutedText => 'النص الثانوي يقرأ هكذا';
}

// Path: search
class _Translations$search$ar extends Translations$search$en {
	_Translations$search$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get hint => 'البحث عن الأفلام، العروض، الموسيقى...';
	@override String get tryDifferentTerm => 'اختبر مصطلح بحث مختلف';
	@override String get searchYourMedia => 'البحث عن وسائل الإعلام الخاصة بك';
	@override String get enterTitleActorOrKeyword => 'أدخل عنوان أو ممثل أو كلمة مفتاحية';
	@override String get people => 'الأشخاص';
}

// Path: hotkeys
class _Translations$hotkeys$ar extends Translations$hotkeys$en {
	_Translations$hotkeys$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'إعداد القطع القصيرة لـ ${actionName}';
	@override String get clearShortcut => 'قصيرة واضحة';
	@override String get noShortcutSet => 'لا توجد مجموعة قصيرة';
	@override String get currentShortcut => 'القصير الحالي :';
	@override String get pressToRecord => 'اختار لتسجيل القصير';
	@override String get recordingShortcut => 'اضغط على القصير الآن';
	@override late final _Translations$hotkeys$actions$ar actions = _Translations$hotkeys$actions$ar._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$ar extends Translations$fileInfo$en {
	_Translations$fileInfo$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'ملف المعلومات';
	@override String get overview => 'نظرة عامة';
	@override String get video => 'مرئي';
	@override String get audio => 'الصوت';
	@override String get subtitles => 'الترجمة';
	@override String get images => 'صور مدمجة';
	@override String get dataStreams => 'تدفق البيانات';
	@override String get lyrics => 'الكلمات';
	@override String get file => 'ملف';
	@override String get attachments => 'الارتباطات';
	@override String get delivery => 'التسليم';
	@override String versionCounter({required Object index, required Object count}) => 'النسخة ${index} من ${count}';
	@override String fileCounter({required Object index, required Object count}) => 'ملف ${index} من ${count}';
	@override String get noStreams => 'لم يبلغ الخادم أي تدفقات لهذا الملف.';
	@override String get copyPath => 'نسخ المسار';
	@override String get pathCopied => 'مسار الملفات نسخة';
	@override String get codec => 'الترميز';
	@override String get codecTag => 'وسم الترميز';
	@override String get resolution => 'الدقة';
	@override String get codedResolution => 'القرار المعدل';
	@override String get bitrate => 'معدل البت';
	@override String get frameRate => 'إطار معدل';
	@override String get rotation => 'الدوران';
	@override String get comment => 'كيف';
	@override String get audioDescription => 'وصف الصوت';
	@override String get headerCompression => 'الرأس الضغط';
	@override String get sidecarFile => 'الملفات Sidecar';
	@override String get transportTimestamp => 'ساعات النقل';
	@override String get displayOffset => 'عرض Offset';
	@override String get previewFailureCode => 'كود الفشل السابق';
	@override String get previewRetries => 'التوقعات التراجع';
	@override String get aspectRatio => 'نسبة العرض إلى الارتفاع';
	@override String get pixelAspectRatio => 'نسبة Pixel Aspect';
	@override String get profile => 'الملف الشخصي';
	@override String get level => 'المستوى';
	@override String get bitDepth => 'عمق البت';
	@override String get pixelFormat => 'تنسيق البكسل';
	@override String get colorSpace => 'مساحة الألوان';
	@override String get colorRange => 'نطاق الألوان';
	@override String get colorPrimaries => 'الألوان الأساسية';
	@override String get colorTransfer => 'نقل الألوان';
	@override String get chromaSubsampling => 'كروم Subsampling';
	@override String get chromaLocation => 'موقع الكروم';
	@override String get scanType => 'نوع الفحص';
	@override String get interlaced => 'متشابك';
	@override String get anamorphic => 'مشوّه عدسيًا (Anamorphic)';
	@override String get referenceFrames => 'الإطار المرجعي';
	@override String get dynamicRange => 'نطاق ديناميكي';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Dolby Vision المستوى';
	@override String get dolbyVisionVersion => 'Dolby Vision النسخة';
	@override String get dolbyVisionLayers => 'Dolby Vision طبقات';
	@override String get baseLayerCompatibility => 'التوافق الأساسي';
	@override String get avcBitstream => 'تدفق بتات AVC';
	@override String get nalLengthSize => 'نال طول الحجم';
	@override String get scalingMatrix => 'المصفوفة المصفوفة المصفوفة';
	@override String get streamIdentifier => 'الهوية الهوية';
	@override String get streamIndex => 'مؤشر التدفق';
	@override String get streamId => 'معرّف التدفق';
	@override String get language => 'اللغة';
	@override String get languageCode => 'رمز اللغة';
	@override String get streamTitle => 'العنوان Track';
	@override String get channels => 'القنوات';
	@override String get sampleRate => 'معدل العينة';
	@override String get spatialAudio => 'الفضاء الصوت';
	@override String get textBased => 'النص القائم';
	@override String get subtitleFormat => 'صيغة';
	@override String get provider => 'المورد';
	@override String get matchScore => 'المباراة النتيجة';
	@override String get externalDelivery => 'يمكن تقديمها بشكل منفصل';
	@override String get sidecarPath => 'مسار سيديكار';
	@override String get sourceStream => 'نسخة من';
	@override String get temporary => 'مؤقتة';
	@override String get timeBase => 'قاعدة الزمن';
	@override String get overallBitrate => 'بطاقة كاملة';
	@override String get path => 'المسار';
	@override String get fileName => 'اسم الملف';
	@override String get size => 'الحجم';
	@override String get totalSize => 'الحجم الكلي';
	@override String get container => 'حاوية الملف الشخصي';
	@override String get duration => 'المدة';
	@override String get previewThumbnails => 'مسبق التمهيدات';
	@override String get previewIndex => 'مؤشر مقدمة';
	@override String get packetLength => 'طول الحزمة';
	@override String get filePresent => 'الملفات الحالية';
	@override String get fileReadable => 'قابلة للقراءة من قبل الخادم';
	@override String get streamPath => 'مسار التدفق';
	@override String get optimizedForStreaming => 'تحسينات البث';
	@override String get has64bitOffsets => '64 بت Offsets';
	@override String get protocol => 'البروتوكول';
	@override String get mediaType => 'نوع وسائل الإعلام';
	@override String get sourceKind => 'المصدر الصغير';
	@override String get optimizedVersion => 'النسخة المثلى';
	@override String get optimizationTarget => 'الهدف الأفضل';
	@override String get deletedAt => 'حذف';
	@override String get remoteSource => 'مصدر بعيد';
	@override String get infiniteStream => 'تدفق غير نهائي';
	@override String get directPlay => 'اللعب المباشر';
	@override String get directStream => 'البث المباشر';
	@override String get transcoding => 'تحويل الترميز';
	@override String get etag => 'ETag';
	@override String get versionId => 'نسخة ID';
	@override String get fileId => 'ملف ID';
	@override String get defaultAudioTrack => 'أداة Audio Track';
	@override String get defaultSubtitleTrack => 'أدنى Subtitle Track';
	@override String get subtitlesOff => 'إيقاف';
	@override String get flagDefault => 'الافتراضي';
	@override String get flagForced => 'إجباري';
	@override String get flagSelected => 'اختياري';
	@override String get flagExternal => 'خارجي';
	@override String get flagHearingImpaired => 'سماع ضعيف';
	@override String get flagDub => 'دبي';
	@override String get flagOriginal => 'الأصلي';
	@override String get channelsMono => 'أحادي (Mono)';
	@override String dolbyVisionProfile({required Object profile}) => 'الملف الشخصي ${profile}';
}

// Path: mediaMenu
class _Translations$mediaMenu$ar extends Translations$mediaMenu$en {
	_Translations$mediaMenu$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'مارك كما شاهدت';
	@override String get markAsUnwatched => 'مارك غير ملاحظة';
	@override String get removeFromContinueWatching => 'إزالة من مواصلة مراقبة';
	@override String get viewDetails => 'انظر التفاصيل';
	@override String get goToSeries => 'اذهب إلى سلسلة';
	@override String get shufflePlay => 'لعبة Shuffle Play';
	@override String get shuffleNotAvailableOffline => 'لا توجد متاجر غير متوفرة offline';
	@override String get fileInfo => 'ملف المعلومات';
	@override String get deleteEpisodeFromServer => 'إزالة الحلقة من الخادم';
	@override String get deleteSeasonFromServer => 'إزالة الموسم من الخادم';
	@override String get deleteShowFromServer => 'إزالة العرض من الخادم';
	@override String get deleteMovieFromServer => 'حذف الفيلم من الخادم';
	@override String get deleteEpisodeTitle => 'إلغاء هذا الحدث؟';
	@override String get deleteSeasonTitle => 'إلغاء الموسم؟';
	@override String get deleteShowTitle => 'إلغاء هذا العرض؟';
	@override String get deleteMovieTitle => 'هل تريد حذف هذا الفيلم؟';
	@override String get deleteEpisodeConfirm => 'حذف الحلقة';
	@override String get deleteSeasonConfirm => 'فصل القضاء';
	@override String get deleteShowConfirm => 'إزالة عرض';
	@override String get deleteMovieConfirm => 'حذف الفيلم';
	@override String get deleteAnyway => 'إزالة على أي حال';
	@override String confirmDeleteTarget({required Object title}) => 'إزالة ${title} بشكل دائم من خادمك؟';
	@override String get deleteMultipleWarning => 'هذا يشمل جميع الحلقات وملفاتها.';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: 'لن تُحذف أي حلقات.',
		one: 'سيُحذف جميع محتواها: حلقة واحدة وملفها.',
		two: 'سيُحذف جميع محتواها: حلقتان وملفاهما.',
		few: 'ستُحذف جميع الحلقات الموجودة فيها وعددها ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} حلقات، مع ملفاتها.',
		many: 'ستُحذف جميع الحلقات الموجودة فيها وعددها ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} حلقة، مع ملفاتها.',
		other: 'ستُحذف جميع الحلقات الموجودة فيها وعددها ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} حلقة، مع ملفاتها.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: 'لا توجد ملفات لهذا العنصر.',
		one: 'هذا العنصر محفوظ في ملف واحد سيُحذف.',
		two: 'هذا العنصر محفوظ في ملفين سيُحذفان.',
		few: 'هذا العنصر موزّع على ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ملفات، وستُحذف كلها.',
		many: 'هذا العنصر موزّع على ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ملفًا، وستُحذف كلها.',
		other: 'هذا العنصر موزّع على ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ملف، وستُحذف كلها.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: 'لا توجد حلقات أخرى في الملف نفسه.',
		one: 'توجد حلقة أخرى في الملف نفسه وستُحذف أيضًا:',
		two: 'توجد حلقتان أخريان في الملف نفسه وستُحذفان أيضًا:',
		few: 'توجد ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} حلقات أخرى في الملف نفسه وستُحذف أيضًا:',
		many: 'توجد ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} حلقة أخرى في الملف نفسه وستُحذف أيضًا:',
		other: 'توجد ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} حلقة أخرى في الملف نفسه وستُحذف أيضًا:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'تعذّر على PlezyNG التحقق من الملفات التي سيحذفها هذا الإجراء، لذلك قد يحذف أكثر من العنصر المذكور أعلاه. ألغِ الإجراء وحاول مجددًا، أو اختر الحذف على أي حال.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'لم يقدّم خادمك تفاصيل ملفات هذا العنصر، لذلك لا يستطيع PlezyNG التحقق من الملفات التي سيحذفها هذا الإجراء. قد تُحذف ملفات تتجاوز العنصر المذكور أعلاه.';
	@override String get mediaDeletedSuccessfully => 'تم حذف منتجات وسائل الإعلام بنجاح';
	@override String get mediaFailedToDelete => 'فشل في حذف موضوع وسائل الإعلام';
	@override String get rate => 'المعدل';
	@override String get playFromBeginning => 'تشغيل من البداية';
	@override String get playVersion => 'اللعب نسخة...';
}

// Path: rateSheet
class _Translations$rateSheet$ar extends Translations$rateSheet$en {
	_Translations$rateSheet$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'المعدل';
	@override String get server => 'الخادم';
	@override String get favorite => 'مفضل';
	@override String get favorited => 'المفضلة';
	@override String get saved => 'حفظه';
	@override String get notAvailable => 'لا توجد مباراة';
	@override String get noConnectedServices => 'قم بتوصيل خدمة في الإعدادات لتقييمها هناك.';
}

// Path: accessibility
class _Translations$accessibility$ar extends Translations$accessibility$en {
	_Translations$accessibility$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}، فيلم';
	@override String mediaCardShow({required Object title}) => '${title}، مسلسل تلفزيوني';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'شوهد';
	@override String mediaCardPartiallyWatched({required Object percent}) => 'تمت مشاهدة ${percent} بالمئة';
	@override String get mediaCardUnwatched => 'لم تتم مشاهدته';
	@override String get tapToPlay => 'اضغط للتشغيل';
	@override String get decrease => 'انخفاض';
	@override String get increase => 'زيادة';
	@override String decreaseValue({required Object label}) => 'انخفاض ${label}';
	@override String increaseValue({required Object label}) => 'زيادة ${label}';
	@override String get hue => 'هوي';
	@override String get saturation => 'التسمية';
	@override String get brightness => 'الضوء';
	@override String get hexColor => 'لون Hex';
	@override String get expandText => 'توسيع النص';
	@override String get collapseText => 'كسر النص';
	@override String get alphabetNavigation => 'الأبجدية الملاحة';
	@override String get alphabetScrollHint => 'مرّر لأعلى أو لأسفل للتنقل حسب الحرف';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'الصف ${row} من ${rowCount}، العمود ${column} من ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'صف ${row} من ${rowCount}';
	@override String get autoScrollPlay => 'لعبة Auto-Scroll';
	@override String get autoScrollPause => 'استراحة السيارات';
	@override String get hueShort => 'H';
	@override String get saturationShort => 'S';
	@override String get valueShort => 'في';
	@override String get red => 'أحمر';
	@override String get green => 'أخضر';
	@override String get blue => 'أزرق';
	@override String get redShort => 'R';
	@override String get greenShort => 'G';
	@override String get blueShort => 'ب';
	@override String get colorModeHsv => 'HSV';
	@override String get colorModeRgb => 'RGB';
	@override String get title => 'إمكانية الوصول';
	@override String get summary => 'النص والتباين والحركة وعناصر التحكم';
	@override String get systemHint => 'تظل إعدادات إمكانية الوصول في جهازك سارية دائمًا. تضيف هذه الخيارات تعديلات في جميع أنحاء PlezyNG.';
	@override String get readability => 'القراءة والرؤية';
	@override String get textSize => 'تكبير إضافي للنص';
	@override String get preview => 'اعثر على قصتك التالية. اقرأ واستمع وشاهد بالوتيرة التي تناسبك.';
	@override String get boldText => 'نص واجهة عريض';
	@override String get highContrast => 'تباين عالٍ';
	@override String get highContrastHint => 'نص وحدود ومؤشرات تركيز أوضح على الأسطح الفاتحة أو الداكنة.';
	@override String get interaction => 'الحركة والتفاعل';
	@override String get reduceMotion => 'تقليل الحركة';
	@override String get reduceMotionHint => 'إيقاف حركة التركيز وانتقالات الصفحات والمؤثرات الزخرفية.';
	@override String get largeTargets => 'مساحات لمس أكبر';
	@override String get largeTargetsHint => 'توفير مساحة أوسع لعناصر التحكم المشتركة للمس والتنقل باستخدام التقنيات المساعدة.';
	@override String get navigationHint => 'استخدم Tab وShift+Tab للتنقل بين عناصر التحكم، وEnter أو مفتاح المسافة لتفعيلها، وEscape أو زر الرجوع للإغلاق. تتوفر خيارات التكبير وتفضيلات القراءة أثناء فتح الكتاب.';
}

// Path: tooltips
class _Translations$tooltips$ar extends Translations$tooltips$en {
	_Translations$tooltips$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'لعبة Shuffle';
	@override String get playTrailer => 'لعبة تريلر';
	@override String get markAsWatched => 'مارك كما شاهدت';
	@override String get markAsUnwatched => 'مارك غير ملاحظة';
}

// Path: audioTracks
class _Translations$audioTracks$ar extends Translations$audioTracks$en {
	_Translations$audioTracks$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'سياق الصوت ${n}';
}

// Path: videoControls
class _Translations$videoControls$ar extends Translations$videoControls$en {
	_Translations$videoControls$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} إطار',
		one: 'إطار واحد',
		two: 'إطاران',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} إطارات',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} إطار',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} إطار',
	);
	@override String get audioLabel => 'الصوت';
	@override String get subtitlesLabel => 'الترجمة';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String get letterbox => 'الكتب';
	@override String get fillScreen => 'ملء الشاشة';
	@override String get stretch => 'تمديد';
	@override String get lockRotation => 'قفل الدوران';
	@override String get unlockRotation => 'إلغاء الدوران';
	@override String get timerActive => 'التوقيت النشط';
	@override String playbackWillPauseIn({required Object duration}) => 'لعبة Playback تتوقف في ${duration}';
	@override String get sleepTimerEndOfVideo => 'نهاية الفيديو الحالي';
	@override String get sleepTimerStopAtHeader => 'توقف عن';
	@override String get sleepTimerDurationHeader => 'تيمير';
	@override String get playbackWillPauseAtEnd => 'لعبة Playback ستتوقف في نهاية هذا الفيديو';
	@override String get stillWatching => 'لا يزال ينظر؟';
	@override String pausingIn({required Object seconds}) => 'استراحة في ${seconds}s';
	@override String get continueWatching => 'مواصلة';
	@override String get autoPlayNext => 'اللعب التالي';
	@override String get playNext => 'تشغيل التالي';
	@override String get playButton => 'تشغيل';
	@override String get pauseButton => 'إيقاف مؤقت';
	@override String get playbackPaused => 'استراحة';
	@override String get playbackResumed => 'اللعب';
	@override String get loadingVideo => 'تحميل الفيديو';
	@override String get showPlaybackControls => 'عرض التحكم في playback';
	@override String get hidePlaybackControls => 'إخفاء التحكم في playback';
	@override String seekBackwardButton({required Object seconds}) => 'البحث إلى الوراء ${seconds} ثانية';
	@override String seekForwardButton({required Object seconds}) => 'البحث إلى الأمام ${seconds} ثانية';
	@override String get previousButton => 'الحلقة السابقة';
	@override String get nextButton => 'الحلقة التالية';
	@override String get previousChapterButton => 'الفصل السابق';
	@override String get nextChapterButton => 'الفصل التالي';
	@override String get muteButton => 'كتم الصوت';
	@override String get unmuteButton => 'إلغاء كتم الصوت';
	@override String get settingsButton => 'إعدادات Playback';
	@override String get tracksButton => 'الأصوات & الأصوات';
	@override String get trackSelectionTitle => 'اختيار المسارات قبل اللعب';
	@override String get trackSelectionAuto => 'الاختيار التلقائي';
	@override String get chaptersButton => 'الفصول';
	@override String get versionQualityButton => 'النسخة والجودة';
	@override String get versionColumnHeader => 'الإصدار';
	@override String get qualityColumnHeader => 'الجودة';
	@override String get qualityOriginal => 'الأصلي';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} ميغابايت في الثانية';
	@override String get transcodeUnavailableFallback => 'التشفير غير متوفر - لعب الجودة الأصلية';
	@override String get subtitleUnavailableFallback => 'العناوين الفرعية المختارة لا يمكن تحميلها - الاستمرار دون العناوين الفرعية';
	@override String get pipButton => 'وضع التصوير في الصورة';
	@override String get aspectRatioButton => 'نسبة العرض إلى الارتفاع';
	@override String get ambientLighting => 'الإضاءة البيئية';
	@override String get fullscreenButton => 'إدخال الشاشة الكاملة';
	@override String get exitFullscreenButton => 'الخروج الشاشة الكاملة';
	@override String get alwaysOnTopButton => 'دائماً في الأعلى';
	@override String get rotationLockButton => 'قفل الدوران';
	@override String get lockScreen => 'شاشة قفل';
	@override String get screenLockButton => 'قفل الشاشة';
	@override String get longPressToUnlock => 'طويل الضغط لإلغاء القفل';
	@override String get timelineSlider => 'لعبة الفيديو';
	@override String get volumeSlider => 'حجم المستوى';
	@override String endsAt({required Object time}) => 'النهاية في ${time}';
	@override String get pipActive => 'فيديوهات متعلقة بـ “ Picture in Picture ”';
	@override String get pipFailed => 'صورة في الصورة فشلت في البدء';
	@override String get screenshotSaved => 'صورة شاشة تم حفظها';
	@override String get screenshotFailed => 'لا أستطيع التقاط صورة شاشة';
	@override String zoomPercent({required Object percent}) => 'التكبير ${percent}%';
	@override String volumePercent({required Object percent}) => 'مستوى الصوت ${percent}%';
	@override late final _Translations$videoControls$pipErrors$ar pipErrors = _Translations$videoControls$pipErrors$ar._(_root);
	@override String get chapters => 'الفصول';
	@override String get noChaptersAvailable => 'لا توجد فصول متاحة';
	@override String get queue => 'كوي';
	@override String get noQueueItems => 'لا توجد عناصر في كوشنر';
	@override String get noAudioDevicesAvailable => 'لا توجد أجهزة صوتية متاحة';
	@override String get searchSubtitles => 'البحث تحت عنوان';
	@override String get loadSubtitleFile => 'تحميل ملف Subtitle';
	@override String get subtitleLoadFailed => 'فشل في تحميل ملف Subtitle';
	@override String get language => 'اللغة';
	@override String get noSubtitlesFound => 'لا توجد عناوين';
	@override String get subtitleDownloaded => 'Subtitle تحميل';
	@override String get subtitleDownloadedNotApplied => 'Subtitle downloaded ولكن لم يتم اختيارها';
	@override String get subtitleDownloadFailed => 'فشل في تنزيل Subtitle';
	@override String get searchLanguages => 'البحث عن اللغات ..';
	@override String get skipIntro => 'سكاي إنترو';
	@override String get skipCredits => 'سكاي الائتمان';
	@override String get skipAds => 'إعلانات Skip';
	@override String get nextEpisode => 'الحلقة التالية';
	@override String subtitleTrack({required Object n}) => 'مسار ${n}';
	@override String subtitleFile({required Object name}) => 'موضوع ${name}';
	@override String forcedTrack({required Object label}) => '${label} (مجبرة)';
	@override String get osdSubtitlesOff => 'العنوان الأصلي: Off';
	@override String osdSubtitles({required Object track}) => 'الأرقام التالية: ${track}';
	@override String osdAudio({required Object track}) => 'الصوت: ${track}';
}

// Path: messages
class _Translations$messages$ar extends Translations$messages$en {
	_Translations$messages$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'علامة كما تم مشاهدتها';
	@override String get markedAsUnwatched => 'علامة غير مسبوقة';
	@override String get markedAsWatchedOffline => 'علامة كما تم مشاهدتها (سيتم مزامنة عند الإنترنت)';
	@override String get markedAsUnwatchedOffline => 'علامة غير مسبوقة (سيتم مزامنة عند الانترنت)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'إزالة السيارة: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: 'لم تُزل أي تنزيلات تمت مشاهدتها',
		one: 'أُزيل تنزيل واحد تمت مشاهدته تلقائيًا',
		two: 'أُزيل تنزيلان تمت مشاهدتهما تلقائيًا',
		few: 'أُزيلت ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} تنزيلات تمت مشاهدتها تلقائيًا',
		many: 'أُزيل ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} تنزيلًا تمت مشاهدته تلقائيًا',
		other: 'أُزيل ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} تنزيل تمت مشاهدته تلقائيًا',
	);
	@override String get removedFromContinueWatching => 'إزالة من مواصلة مراقبة';
	@override String errorLoading({required Object error}) => 'الخطأ: ${error}';
	@override String get searchPartialResults => 'بعض خوادم الوسائط لا يمكن البحث عنها.عرض النتائج المتاحة.';
	@override String get streamInterrupted => 'تم إيقاف التدفق.الضغط يلعب أو يحاول الانسحاب.';
	@override String get liveStreamInterrupted => 'تم إيقاف البث المباشر.الضغط يلعب إلى الانسحاب.';
	@override String get fileInfoNotAvailable => 'معلومات الملفات غير متوفرة';
	@override String get playbackAuthenticationRequired => 'اشترك في خادم الوسائط مرة أخرى للعب هذا العنصر.';
	@override String get playbackServerUnavailable => 'لا يوجد خادم وسائل الإعلام، حاول مرة أخرى في وقت لاحق.';
	@override String get playbackDataInvalid => 'وقد أعاد الخادم معلومات التدوين غير المباشرة.';
	@override String get playbackCancelled => 'تم إلغاء Playback';
	@override String get playbackFailed => 'لا يمكن بدء اللعب.';
	@override String playbackFailedDetail({required Object error}) => 'لا يمكن بدء تشغيل Playback: ${error}';
	@override String get audioOutputFailed => 'تحقق من اتصال الصوت التلفزيون أو المستلم ؛ إذا لم تكن التطبيقات الأخرى أي صوت ، قم بإعادة تشغيل الجهاز.';
	@override String get mediaUnavailable => 'هذا المحتوى لم يعد متاحا.';
	@override String errorLoadingFileInfo({required Object error}) => 'أخطاء تحميل ملف المعلومات: ${error}';
	@override String get errorLoadingSeries => 'خطأ سلسلة تحميل';
	@override String get musicNotSupported => 'لم يتم دعم Playback الموسيقي بعد';
	@override String get noDescriptionAvailable => 'لا توجد وصفات متاحة';
	@override String get noProfilesAvailable => 'لا توجد ملفات تعريف متاحة';
	@override String get contactAdminForProfiles => 'اتصل بمدير الخادم لإضافة ملفات تعريف';
	@override String get unableToDetermineLibrarySection => 'غير قادر على تحديد قسم المكتبة لهذا العنصر';
	@override String get logsCleared => 'اللوحات المطهرة';
	@override String get logsCopied => 'سجلات نسخة إلى clipboard';
	@override String get noLogsAvailable => 'لا توجد سجلات متاحة';
	@override String libraryScanning({required Object title}) => 'فحص "${title}" ...';
	@override String libraryScanStarted({required Object title}) => 'بدأت فحص المكتبة لـ "${title}"';
	@override String libraryScanFailed({required Object error}) => 'فشل في فحص المكتبة: ${error}';
	@override String metadataRefreshing({required Object title}) => 'إعادة تدوير البيانات الميتاتية لـ "${title}" ...';
	@override String metadataRefreshStarted({required Object title}) => 'بدأ تحديث البيانات الميتة لـ "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'لا يمكن تحديث البيانات الميتا: ${error}';
	@override String get logoutConfirm => 'هل أنت متأكد من أنك تريد الانسحاب؟';
	@override String get noSeasonsFound => 'لا توجد مواسم';
	@override String get seasonsLoadFailed => 'لا أستطيع تحميل الموسم';
	@override String get noEpisodesFound => 'لا توجد أحداث في الموسم الأول';
	@override String get noEpisodesFoundGeneral => 'لم يتم العثور على أحداث';
	@override String get episodesLoadFailed => 'لا يمكن تحميل الحوادث';
	@override String get noResultsFound => 'لم يتم العثور على نتائج.';
	@override String sleepTimerSet({required Object label}) => 'ساعة النوم المحددة ${label}';
	@override String get noItemsAvailable => 'لا توجد عناصر متاحة';
	@override String get failedToCreatePlayQueueNoItems => 'فشل في إنشاء لعبة - لا عناصر';
	@override String failedPlayback({required Object action, required Object error}) => 'فشل في ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'التبديل إلى لاعب متوافق ...';
	@override String get serverLimitTitle => 'لعبة Playback فاشلة';
	@override String get serverLimitBody => 'خطأ الخادم (HTTP 500). قد يرفض هذا الجلسة حد نطاق النطاق / التشفير.';
	@override String get mediaUnreadableTitle => 'ملف غير متوفر';
	@override String get mediaUnreadableBody => 'وجد الخادم هذا العنصر ولكن لم يكن قادرا على قراءة ملفها (HTTP 404). تم نقل الملف على الأرجح، وحذف، أو تخزين غير متصل.';
	@override String get serverBusyTitle => 'البث غير متوفر';
	@override String get serverBusyBody => 'لا يزال الخادم يرفض بث هذا الملف (HTTP 503).قد يكون إعادة تشغيل، مشغول، أو قد يكون تخزين الملف غير متصل.حاول مرة أخرى في لحظة - إذا كان لا يزال يحدث، اطلب من مالك الخادم التحقق من الخادم وتخزين الملف.';
	@override String get playbackNotAllowedTitle => 'لا يسمح لـ Playback';
	@override String get playbackNotAllowedBody => 'رفض الخادم بث هذا العنصر (HTTP 403). قد لا يملك حسابك صلاحية تشغيله، أو قد يسمح الخادم بالتشغيل على شبكته المحلية فقط.';
	@override String get logsUploaded => 'Logs تحميل';
	@override String get logsUploadFailed => 'فشل في تحميل اللوحات';
	@override String get logId => 'معرّف السجل';
	@override String get burnedSubtitlesUseMenu => 'يتم حرق العناوين في هذا التدفق.تغييرها من قائمة العناوين.';
	@override String get noVideoUrl => 'لا توجد URL الفيديو المتاحة';
	@override String get playbackNoMediaSources => 'الخادم لم يعيد أي مصادر وسائل الإعلام المباشرة';
	@override String get playbackDataNotPrepared => 'بدأت Playback قبل أن تكون بياناتها جاهزة';
	@override String get streamSelectionUnavailable => 'لا توجد خيارات البث المتاحة لهذا المصدر';
	@override String get streamSelectionFailed => 'لا يستطيع أن يستخدم التدفقات المختارة';
	@override String get trackSelectionNotRemembered => 'هذا الاختيار المسار ينطبق فقط على اللعب الحالي.';
	@override String get serverUnavailableForProfile => 'لا يوجد خادم متاح للملف النشط';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$ar extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get previewSample => 'الفوركس البني السريع يقفز فوق الكلب القبيح';
	@override String get text => 'النص';
	@override String get border => 'الحدود';
	@override String get background => 'الخلفية';
	@override String get fontSize => 'حجم الصورة';
	@override String get textColor => 'لون النص';
	@override String get borderSize => 'الحدود حجم';
	@override String get borderColor => 'اللون الحدودي';
	@override String get backgroundOpacity => 'الخلفية Opacity';
	@override String get backgroundColor => 'خلفية اللون';
	@override String get position => 'موقف';
	@override String get assOverride => 'ASS مبالغة';
	@override String get overrideScale => 'مقياس';
	@override String get overrideForce => 'القوة';
	@override String get overrideStrip => 'إزالة التصميم';
	@override String get positionTop => 'أعلى';
	@override String get positionBottom => 'أسفل';
	@override String get useMargins => 'استخدم المارغين';
	@override String get useMarginsDescription => 'السماح للقبول النصية في الفضاء خارج الفيديو.القبول النصية يمكن أن تحافظ على وضعها الأصلي.';
	@override String get anchorToScreen => 'Anchor إلى الشاشة';
	@override String get anchorToScreenDescription => 'عرض العناوين الفرعية النصية في الشرائح السوداء أدناه فيديو الشاشة العريضة';
	@override String get bold => 'غامق';
	@override String get italic => 'إيطاليا';
	@override String get renderResolution => 'رينتر القرار';
	@override String get renderResolutionScreen => 'دقة الشاشة';
	@override String get renderResolutionVideo => 'دقة الفيديو';
}

// Path: mpvConfig
class _Translations$mpvConfig$ar extends Translations$mpvConfig$en {
	_Translations$mpvConfig$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'إعدادات مشغل الفيديو المتقدمة';
	@override String get presets => 'الكهنوت';
	@override String get noPresets => 'لا توجد سلاحات';
	@override String get saveAsPreset => 'الحفاظ على كونك...';
	@override String get presetName => 'الاسم السابق';
	@override String get presetNameHint => 'أدخل اسمًا لهذا المجلد';
	@override String get loadPreset => 'تحميل';
	@override String get deletePreset => 'حذف';
	@override String get presetSaved => 'النصر ينقذ';
	@override String get presetLoaded => 'محرك محرك';
	@override String get presetDeleted => 'إلغاء Preset';
	@override String get confirmDeletePreset => 'هل أنت متأكد من أنك ترغب في إزالة هذا التوقيع؟';
	@override String get configPlaceholder => 'gpu-api=vulkan hwdec=auto # التعليق';
	@override String get lineHint => 'option=value';
	@override String get addLine => 'إضافة خط';
	@override String get removeLine => 'إزالة الخط';
	@override String get embeddedVoHint => 'يتم تجاهل vo، gpu-context و gpu-api على Linux: فيديو مدمج دائما يخرج من خلال vo=libmpv على مقطع الفيديو، و gpu-next (الذي يحتاج الظلال الحاسوبية مثل ArtCNN) لا يمكن تشغيل مدمج.';
}

// Path: dialog
class _Translations$dialog$ar extends Translations$dialog$en {
	_Translations$dialog$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'تأكيد العملية';
}

// Path: profiles
class _Translations$profiles$ar extends Translations$profiles$en {
	_Translations$profiles$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'إضافة PlezyNG ملف تعريف';
	@override String get switchingProfile => 'تبادل الملفات ...';
	@override String get deleteThisProfileTitle => 'إزالة هذا الملف الشخصي؟';
	@override String deleteThisProfileMessage({required Object displayName}) => 'إزالة ${displayName}.الاتصالات لا تتأثر.';
	@override String get active => 'نشطة';
	@override String get manage => 'إدارة';
	@override String get delete => 'حذف';
	@override String get signOut => 'تسجيل الخروج';
	@override String get signOutPlexTitle => 'تسجيل الدخول من Plex؟';
	@override String signOutPlexMessage({required Object displayName}) => 'إزالة ${displayName} وجميع Plex المستخدمين المنزليين؟ تسجيل الدخول في أي وقت.';
	@override String get signOutPlexDeleteDownloads => 'إزالة أيضًا تحميل';
	@override String get signOutPlexDeleteDownloadsDescription => 'وإلا فإنهم يبقون على هذا الجهاز ويعودون عندما تقوم بتسجيل الدخول مرة أخرى إلى هذا الحساب.';
	@override String get signedOutPlex => 'تم توقيعها من Plex.';
	@override String get signOutFailed => 'تسجيل فشل';
	@override String get sectionTitle => 'الملفات';
	@override String get summarySingle => 'إضافة ملفات تعريف لخلط المستخدمين المديرين والهوية المحلية';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} ملفات تعريف · نشطة: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} ملفات تعريف';
	@override String get removeConnectionTitle => 'إزالة الاتصال ؟';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'إزالة صلاحية وصول ${displayName} إلى ${connectionLabel}. تحتفظ الملفات الشخصية الأخرى بصلاحية الوصول.';
	@override String get deleteProfileTitle => 'إزالة الملف الشخصي؟';
	@override String deleteProfileMessage({required Object displayName}) => 'إزالة ${displayName} و اتصالاتها.الخوادم تبقى متاحة.';
	@override String get profileNameLabel => 'اسم الملف الشخصي';
	@override String get pinProtectionLabel => 'حماية PIN';
	@override String get copyAutomationLink => 'نسخة Android اتصال الأتمتة';
	@override String get copyAutomationLinkDescription => 'حدد هذا الملف الشخصي من إرادة Android أو الأتمتة.';
	@override String get automationLinkCopied => 'نسخ ملف تعريف الأتمتة.';
	@override String get pinManagedByPlex => 'قاعدة PIN التي تديرها Plex. Edit on plex.tv.';
	@override String get noPinSetEditOnPlex => 'لا إعداد PIN.للتطلب واحد، تحرير المستخدم المنزلي على plex.tv.';
	@override String get setPin => 'إعداد PIN';
	@override String get setPinTitle => 'إعداد PIN';
	@override String get confirmPinTitle => 'تأكيد PIN';
	@override String get pinSet => 'إعداد PIN';
	@override String get changePin => 'التغيير';
	@override String get removePin => 'إزالة';
	@override String get connectionsLabel => 'الاتصالات';
	@override String get add => 'إضافة';
	@override String get deleteProfileButton => 'حذف الملف الشخصي';
	@override String get noConnectionsHint => 'لا توجد اتصالات - أضف واحد لاستخدام هذا الملف الشخصي.';
	@override String get noConnections => 'لا اتصالات';
	@override String get plexHomeAccount => 'Plex الحساب المنزلي';
	@override String plexAccountChip({required Object account}) => 'Plex حساب: ${account}';
	@override String plexAccountUserChip({required Object user, required Object account}) => '${user} عن طريق ${account}';
	@override String get connectionDefault => 'الافتراضي';
	@override String connectionAs({required Object displayName}) => 'رقم ${displayName}';
	@override String get makeDefault => 'إلغاء الافتراض';
	@override String get removeConnection => 'إزالة';
	@override String get profileRenamed => 'إعادة تسمية الملف الشخصي';
	@override String borrowAddTo({required Object displayName}) => 'إضافة إلى ${displayName}';
	@override String get borrowExplain => 'قروض اتصال ملف تعريف آخر.الملفات المحمية PIN تتطلب PIN.';
	@override String get borrowEmpty => 'لا شيء للاستئجار بعد.';
	@override String get borrowEmptySubtitle => 'اتصل Plex أو Jellyfin أو Emby إلى ملف تعريف آخر أولاً.';
	@override String get borrowLoadFailed => 'لا يمكن تحميل الاتصالات المتاحة.محاولة مرة أخرى.';
	@override String borrowFromProfile({required Object displayName}) => 'من ${displayName}';
	@override String get borrowConnectionBorrowed => 'اتصال مستأجر';
	@override String get borrowFailed => 'فشل في الحصول على اتصال القرض.';
	@override String get incorrectPin => 'خطأ في PIN';
	@override String get incorrectPinTryAgain => 'إلغاء الخطأ، يرجى المحاولة مرة أخرى.';
	@override String get sourceProfileMissingParentAccount => 'الملف الشخصي يفتقر إلى حساب الوالدين.';
	@override String get failedToLoadHomeUsers => 'لا يمكن تحميل Plex المستخدمين المنزليين.تحقق من اتصالك ومحاولة مرة أخرى.';
	@override String get failedToVerifyPin => 'فشل في التحقق من PIN.';
	@override String get newProfile => 'ملف تعريف جديد';
	@override String get profileNameHint => 'ضيوف، أطفال، غرفة عائلية';
	@override String get pinProtectionOptional => 'حماية PIN (اختياري)';
	@override String get pinExplain => '4-الأرقام PIN مطلوب لتغيير الملفات.';
	@override String get continueButton => 'مواصلة';
	@override String get pinsDontMatch => 'PINs لا تتطابق';
	@override String get tokenIdentityMismatch => 'Plex سجل الملف الشخصي تم حلها إلى خادم غير متوقع';
	@override String get settingsLocked => 'يتم إغلاق الإعدادات لهذا الملف.';
	@override String get unlockSettings => 'إلغاء الإعدادات';
	@override String get showExploreForProfile => 'عرض البحث لهذا الملف الشخصي';
	@override String get showExploreForProfileDescription => 'انقر فوق إزالة Explore من الملاحة في هذا الملف الشخصي.';
}

// Path: connections
class _Translations$connections$ar extends Translations$connections$en {
	_Translations$connections$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'الاتصالات';
	@override String get addConnection => 'إضافة اتصال';
	@override String get addConnectionSubtitleNoProfile => 'تسجيل الدخول مع Plex أو الاتصال بخادم Jellyfin أو Emby';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'إضافة إلى ${displayName}: Plex، Jellyfin، Emby، أو أي اتصال ملف تعريف آخر';
	@override String sessionExpiredOne({required Object name}) => 'الجلسة انتهت لـ ${name}';
	@override String sessionExpiredMany({required Object count}) => 'انتهاء الجلسة لـ ${count} خادم';
	@override String accessDeniedOne({required Object name}) => '${name} رفض الوصول إلى هذا الحساب';
	@override String accessDeniedMany({required Object count}) => '${count} الخوادم رفضت الوصول إلى هذا الحساب';
	@override String get signInAgain => 'اكتب مرة أخرى';
	@override String editMediaBrowserTitle({required Object product}) => 'تحرير ${product} الاتصال';
	@override String editMediaBrowserIntro({required Object serverName}) => 'إضافة أو إزالة عناوين URL لـ ${serverName}. PlezyNG سوف تستخدم عناوين URL المتاحة مع أدنى تأخير.';
}

// Path: accountPreferences
class _Translations$accountPreferences$ar extends Translations$accountPreferences$en {
	_Translations$accountPreferences$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'تفضيلات الحساب';
	@override String hubSubtitleSingle({required Object account}) => 'تم حفظ خيارات الصوت والعنوان والمكتبة على ${account}';
	@override String hubSubtitleMultiple({required Object count}) => 'تم حفظ خيارات الصوت والعنوان والمكتبة على حسابات ${count}';
	@override String get pickAccount => 'كل حساب يحفظ تفضيلاته الخاصة.اختر واحد لتحرير.';
	@override String get storedOnAccount => 'يتم حفظ هذه الخيارات على الحساب نفسه، لذلك يستخدمها كل تطبيق تم تسجيله إليه – بما في ذلك PlezyNG على أجهزتك الأخرى.';
	@override String get noAccounts => 'لا حسابات لتحديد';
	@override String get noAccountsHint => 'تسجيل الدخول إلى Plex، أو الاتصال بخادم Jellyfin أو Emby، وتظهر التفضيلات المخزنة على هذا الحساب هنا.';
	@override String get unavailable => 'لا يمكن الوصول إلى هذا الحساب';
	@override String get loadFailed => 'لا يمكن تحميل هذه التفضيلات';
	@override String get noPreference => 'لا تفضيلات';
	@override String get notSet => 'لا تضع';
	@override late final _Translations$accountPreferences$groups$ar groups = _Translations$accountPreferences$groups$ar._(_root);
	@override String get preferredAudioLanguage => 'لغة الصوت المفضلة';
	@override String get autoSelectAudio => 'اختيار الصوت حسب اللغة';
	@override String get autoSelectAudioDescription => 'يبقى خارج أي صوت تتبع الملفات علامات الافتراضية.';
	@override String get preferredSubtitleLanguage => 'لغة الترجمة المفضلة';
	@override String get subtitleMode => 'تحويل العناوين إلى';
	@override late final _Translations$accountPreferences$subtitleModes$ar subtitleModes = _Translations$accountPreferences$subtitleModes$ar._(_root);
	@override String get subtitleAccessibility => 'SDH أسماء';
	@override late final _Translations$accountPreferences$subtitleAccessibilityOptions$ar subtitleAccessibilityOptions = _Translations$accountPreferences$subtitleAccessibilityOptions$ar._(_root);
	@override String get forcedSubtitles => 'القبض على العناوين';
	@override late final _Translations$accountPreferences$forcedSubtitleOptions$ar forcedSubtitleOptions = _Translations$accountPreferences$forcedSubtitleOptions$ar._(_root);
	@override String get displayMissingEpisodes => 'عرض الحوادث المفقودة';
	@override String get displayMissingEpisodesDescription => 'قائمة الحوادث التي يعرفها الخادم ولكن ليس لديه أي ملف.';
	@override String get hidePlayedInLatest => 'إخفاء العناصر التي تمت مشاهدتها في الأخير';
	@override String get hidePlayedInLatestDescription => 'اترك العناصر التي شاهدتها بالفعل من آخر صفوف الخادم.';
	@override String get displayCollectionsView => 'عرض عرض المجموعات';
	@override String get displayCollectionsViewDescription => 'عرض مجموعات الخادم بجانب المكتبات الخاصة بك.';
	@override String get rewatchingInNextUp => 'إعادة النظر في العروض في Next Up';
	@override String get rewatchingInNextUpDescription => 'بمجرد الانتهاء من العرض ، ابدأ من جديد و Next Up يتابع إعادة النظر بدلاً من إسقاط العرض.';
	@override String get watchedIndicator => 'المؤشرات المراقبة';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$ar watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$ar._(_root);
	@override String get mediaReviewsVisibility => 'تصنيفات & مراجعات';
	@override late final _Translations$accountPreferences$mediaReviewsOptions$ar mediaReviewsOptions = _Translations$accountPreferences$mediaReviewsOptions$ar._(_root);
}

// Path: discover
class _Translations$discover$ar extends Translations$discover$en {
	_Translations$discover$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'اكتشاف';
	@override String get noContentAvailable => 'لا محتوى متاح';
	@override String get addMediaToLibraries => 'إضافة بعض وسائل الإعلام إلى مكتباتك';
	@override String get continueWatching => 'متابعة المشاهدة';
	@override String continueWatchingIn({required Object library}) => 'مواصلة مشاهدة في ${library}';
	@override String get nextUp => 'القادم';
	@override String nextUpIn({required Object library}) => 'التالي في ${library}';
	@override String get recentlyAdded => 'أُضيف حديثًا';
	@override String recentlyAddedIn({required Object library}) => 'أضيف مؤخرا في ${library}';
	@override String latestAlbumsIn({required Object library}) => 'أحدث الألبومات في ${library}';
	@override String recentlyPlayedIn({required Object library}) => 'اللعب مؤخرا في ${library}';
	@override String mostPlayedIn({required Object library}) => 'الأكثر لعبًا في ${library}';
	@override String playEpisode({required Object season, required Object episode}) => 'م${season} ح${episode}';
	@override String get overview => 'نظرة عامة';
	@override String get cast => 'كاست';
	@override late final _Translations$discover$findNext$ar findNext = _Translations$discover$findNext$ar._(_root);
	@override String get extras => 'تريلر و إضافات';
	@override String get studio => 'الاستوديو';
	@override String get rating => 'تصنيف';
	@override String get director => 'المخرج';
	@override String get directors => 'المخرجون';
	@override String get movie => 'فيلم';
	@override String get tvShow => 'عرض التلفزيون';
	@override String minutesLeft({required Object minutes}) => '${minutes} دقيقة متبقية';
	@override String get moreLikeThis => 'مشابه لهذا';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} عنوان',
		one: 'عنوان واحد',
		two: 'عنوانان',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} عناوين',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} عنوان',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} عنوان',
	);
	@override late final _Translations$discover$person$ar person = _Translations$discover$person$ar._(_root);
}

// Path: errors
class _Translations$errors$ar extends Translations$errors$en {
	_Translations$errors$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'البحث فشل: ${error}';
	@override String get searchUnavailable => 'لم تتمكن البحث من الوصول إلى أي خادم وسائل الإعلام.';
	@override String connectionTimeout({required Object context}) => 'اتصال الوقت أثناء التحميل ${context}';
	@override String get connectionFailed => 'عدم القدرة على الاتصال بـ Media Server';
	@override String unableToLoad({required Object context}) => 'لا يمكن تحميل ${context}. يرجى المحاولة مرة أخرى.';
	@override String get noClientAvailable => 'لا يوجد عميل متاح';
	@override String get pleaseEnterToken => 'يرجى إدخال علامة';
	@override String get invalidToken => 'الرموز المعاقبة';
	@override String failedToVerifyToken({required Object error}) => 'عدم التحقق من الرموز: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'لم يتم تحويلها إلى ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'لم يتم حذف ${displayName}';
	@override String get failedToRate => 'لا يمكن تحديث التصنيف';
	@override String get reasonTimedOut => 'اتصال موقت';
	@override String get reasonUnreachable => 'لا يمكن الوصول إلى الخادم';
	@override String get reasonRefused => 'ورفض الخادم الطلب';
	@override String get reasonNotFound => 'لم يعد العنصر على الخادم';
	@override String get reasonServerError => 'الخادم يحدد خطأ';
	@override String get reasonCancelled => 'تم إلغاء الطلب';
	@override String get reasonUnexpected => 'حدث خطأ غير متوقع';
}

// Path: libraries
class _Translations$libraries$ar extends Translations$libraries$en {
	_Translations$libraries$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => 'لعب فيلم عشوائي';
	@override String get randomPickFailed => 'لا يمكن أن تختار فيلم عشوائي من هذه المكتبة.';
	@override String get title => 'المكتبات';
	@override String get fallbackTitle => 'المكتبة';
	@override String get scanLibraryFiles => 'فحص المكتبة الملفات';
	@override String get scanLibrary => 'فحص المكتبة';
	@override String get analyze => 'تحليل';
	@override String get analyzeLibrary => 'تحليل المكتبة';
	@override String get refreshMetadata => 'تحديث البيانات الوصفية';
	@override String get emptyTrash => 'الفراغ الفراغ';
	@override String emptyingTrash({required Object title}) => 'إزالة القمامة لـ "${title}" ...';
	@override String trashEmptied({required Object title}) => 'أضف تعليق حول "${title}"';
	@override String failedToEmptyTrash({required Object error}) => 'الفشل في إزالة القمامة الفارغة: ${error}';
	@override String analyzing({required Object title}) => 'تحليل "${title}" ...';
	@override String analysisStarted({required Object title}) => 'بدأت التحليلات لـ "${title}"';
	@override String failedToAnalyze({required Object error}) => 'فشل في تحليل المكتبة: ${error}';
	@override String get noLibrariesFound => 'لا توجد مكتبات';
	@override String get allLibrariesHidden => 'جميع المكتبات مخفية';
	@override String hiddenLibrariesCount({required Object count}) => 'المكتبات الخفية (${count})';
	@override String get thisLibraryIsEmpty => 'هذه المكتبة فارغة';
	@override String get noItemsMatchFilters => 'لا تتوافق العناصر مع الفلاتر النشطة';
	@override String get resetFilters => 'إعادة تعيين الفلاتر';
	@override String get all => 'الكل';
	@override String get clearAll => 'واضحة كل';
	@override String scanLibraryConfirm({required Object title}) => 'هل أنت متأكد من أنك تريد مسح "${title}"؟';
	@override String analyzeLibraryConfirm({required Object title}) => 'هل أنت متأكد من أنك تريد تحليل "${title}"؟';
	@override String refreshMetadataConfirm({required Object title}) => 'هل أنت متأكد من أنك تريد تحديث البيانات الميتا لـ "${title}"؟';
	@override String emptyTrashConfirm({required Object title}) => 'هل أنت متأكد من أنك تريد إفراغ القمامة لـ "${title}"؟';
	@override String get manageLibraries => 'إدارة المكتبات';
	@override String get sort => 'ترتيب';
	@override String get sortBy => 'ترتيب حسب';
	@override String get filters => 'الفلاتر';
	@override String get confirmActionMessage => 'هل أنت متأكد من أنك ترغب في تنفيذ هذا العمل؟';
	@override String get showLibrary => 'عرض المكتبة';
	@override String get hideLibrary => 'إخفاء المكتبة';
	@override String get libraryOptions => 'خيارات المكتبة';
	@override String get content => 'مكتبة المحتوى';
	@override String get selectLibrary => 'اختيار المكتبة';
	@override String filtersWithCount({required Object count}) => 'الفلاتر (${count})';
	@override String get noRecommendations => 'لا توجد توصيات متاحة';
	@override String get noCollections => 'لا توجد مجموعات في هذه المكتبة';
	@override String get noFoldersFound => 'لا توجد ملفات';
	@override String get folders => 'المجلدات';
	@override late final _Translations$libraries$tabs$ar tabs = _Translations$libraries$tabs$ar._(_root);
	@override late final _Translations$libraries$groupings$ar groupings = _Translations$libraries$groupings$ar._(_root);
	@override late final _Translations$libraries$filterCategories$ar filterCategories = _Translations$libraries$filterCategories$ar._(_root);
	@override late final _Translations$libraries$sortLabels$ar sortLabels = _Translations$libraries$sortLabels$ar._(_root);
	@override late final _Translations$libraries$advancedFilters$ar advancedFilters = _Translations$libraries$advancedFilters$ar._(_root);
	@override late final _Translations$libraries$selection$ar selection = _Translations$libraries$selection$ar._(_root);
}

// Path: about
class _Translations$about$ar extends Translations$about$en {
	_Translations$about$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'حول';
	@override String get openSourceLicenses => 'ترخيص المصدر المفتوح';
	@override String versionLabel({required Object version}) => 'النسخة ${version}';
	@override String get appDescription => 'عميل جميل Plex و Jellyfin و Emby لـ Flutter';
	@override String get viewLicensesDescription => 'عرض ترخيص المكتبات من طرف ثالث';
	@override String get privacyPolicy => 'سياسة الخصوصية';
}

// Path: serverSelection
class _Translations$serverSelection$ar extends Translations$serverSelection$en {
	_Translations$serverSelection$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'لا توجد خوادم تم العثور عليها في ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'الخوادم التي لم يتم تحميلها: ${error}';
	@override String get noValidServers => 'لم يتم العثور على خادمات قابلة للاستخدام في هذا الحساب';
}

// Path: hubDetail
class _Translations$hubDetail$ar extends Translations$hubDetail$en {
	_Translations$hubDetail$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'العنوان';
	@override String get releaseYear => 'إطلاق السنة';
	@override String get dateAdded => 'تاريخ الإضافة';
	@override String get rating => 'تصنيف';
	@override String get noItemsFound => 'لا توجد عناصر';
}

// Path: logs
class _Translations$logs$ar extends Translations$logs$en {
	_Translations$logs$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'سجلات واضحة';
	@override String get copyLogs => 'نسخة Logs';
	@override String get uploadLogs => 'تحميل اللوحات';
	@override String get saveLogs => 'حفظ اللوحات إلى الملفات';
	@override String logsSaved({required Object path}) => 'تسجيل الدخول إلى ${path}';
	@override String get saveLogsFailed => 'لا أستطيع حفظ ملف السجل.';
}

// Path: detail
class _Translations$detail$ar extends Translations$detail$en {
	_Translations$detail$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => 'النهاية في ${time}';
}

// Path: startup
class _Translations$startup$ar extends Translations$startup$en {
	_Translations$startup$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'PlezyNG لا يمكن أن تبدأ';
	@override String get failedBody => 'حدث شيء خاطئ أثناء بدء التشغيل، وتحدد التفاصيل أدناه ما فشلت.';
	@override String get failedBodyRepairable => 'ملف إعدادات PlezyNG المحفوظ تالف ويجب إعادة إنشائه قبل بدء التطبيق. لن تفيد إعادة المحاولة؛ اختر إصلاح التخزين.';
	@override String get phaseLabel => 'خطوة';
	@override String get showDetails => 'عرض التفاصيل';
	@override String get hideDetails => 'إخفاء التفاصيل';
	@override String get copyDetails => 'نسخ التفاصيل';
	@override String get detailsCopied => 'تفاصيل نسخها إلى clipboard';
	@override String get uploadDetails => 'تحميل التفاصيل';
	@override String get repairStorage => 'إصلاح التخزين';
	@override String get repairTitle => 'إصلاح البيانات المخزنة؟';
	@override String get repairBodyCommon => 'ملف إعدادات PlezyNG تالف ولا يمكن قراءته. تؤدي عملية الإصلاح إلى إعادة جميع الإعدادات إلى قيمها الافتراضية.';
	@override String get repairBodyOneCredential => 'تلفت بيانات إحدى عمليات تسجيل الدخول المحفوظة ولا يمكن قراءتها. يحذف الإصلاح هذه البيانات فقط، وتبقى إعداداتك الأخرى دون تغيير.';
	@override String get repairBodySignInsKept => 'يجب أن تبقى خادماتك وملفاتك الشخصية مسجلة.';
	@override String get repairBodySignInsLost => 'لا يمكن استعادة المفتاح الذي يحمي بيانات تسجيل الدخول المحفوظة من هذا الملف، لذلك ستحتاج إلى تسجيل الدخول إلى كل خادم وملف شخصي مجددًا. لن يتأثر أي شيء على خادم الوسائط.';
	@override String get repairBodySessionsUncertain => 'تُحفظ بيانات خدمات التتبع (MAL وAniList وSimkl وTrakt) وSeerr بشكل منفصل، وقد تبقى أو تُفقد. سيُطلعك PlezyNG على البيانات التي احتفظ بها بالضبط.';
	@override String get repairConfirm => 'إصلاح';
	@override String get repairSucceeded => 'التخزين إصلاح';
	@override String get repairNeedsRestart => 'التخزين إصلاح - إعادة تشغيل مطلوب';
	@override String get restartRequiredBody => 'تم إصلاح بياناتك، لكن يجب إعادة تشغيل PlezyNG قبل استخدامها. أغلق PlezyNG وافتحه مجددًا.';
	@override String get quitPlezy => 'إلغاء PlezyNG';
	@override String get repairFailed => 'إصلاح فشل';
	@override String get repairKeptSignIns => 'لا يزال الخوادم والملفات الشخصية الخاصة بك مسجلة.';
	@override String get repairLostSignIns => 'لا يمكن استرداد المفتاح الذي يحمي تسجيلاتك المحفوظة.سوف تحتاج إلى تسجيل الدخول إلى كل خادم وملف تعريف مرة أخرى.';
	@override String get repairLostSessions => 'فُقد اتصال واحد على الأقل بخدمة تتبّع أو بخدمة Seerr، ويجب إعادة الاتصال به.';
	@override String get backupTitle => 'تم الحفاظ على نسخة من الملف المتضرر';
	@override String get backupWarning => 'تحتوي هذه النسخة على بيانات تسجيل الدخول الخاصة بك. لا ترفعها أو تشاركها.';
	@override String get deleteBackup => 'حذف النسخة';
	@override String get backupDeleted => 'نسخة حذف';
	@override String get previousFailureTitle => 'PlezyNG فشل في البدء للمرة الأخيرة';
}

// Path: licenses
class _Translations$licenses$ar extends Translations$licenses$en {
	_Translations$licenses$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'الحزم ذات الصلة';
	@override String get license => 'الترخيص';
	@override String licenseNumber({required Object number}) => 'الترخيص ${number}';
	@override String licensesCount({required Object count}) => '${count} ترخيص';
}

// Path: navigation
class _Translations$navigation$ar extends Translations$navigation$en {
	_Translations$navigation$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'المكتبات';
	@override String get downloads => 'التنزيلات';
	@override String get liveTv => 'البث التلفزيوني المباشر';
	@override String get explore => 'استكشاف';
}

// Path: explore
class _Translations$explore$ar extends Translations$explore$en {
	_Translations$explore$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$explore$mdblistShelves$ar mdblistShelves = _Translations$explore$mdblistShelves$ar._(_root);
	@override String get title => 'استكشاف';
	@override String get selectSource => 'اختيار المصدر';
	@override late final _Translations$explore$rows$ar rows = _Translations$explore$rows$ar._(_root);
	@override late final _Translations$explore$status$ar status = _Translations$explore$status$ar._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} حلقة',
		one: 'حلقة واحدة',
		two: 'حلقتان',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} حلقات',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} حلقة',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} حلقة',
	);
	@override String get cast => 'كاست';
	@override String get characters => 'شخصيات';
	@override String get addToWatchlist => 'إضافة إلى Watchlist';
	@override String get removeFromWatchlist => 'إزالة من Watchlist';
	@override String get addedToWatchlist => 'إضافة إلى Watchlist';
	@override String get removedFromWatchlist => 'إزالة من قائمة المشاهدين';
	@override String get watchlistUpdateFailed => 'لا أستطيع تحديث قائمة المشاهدين';
	@override String get watchlistNoMatch => 'لا يمكن أن تتطابق هذه العنصر مع قائمة مراقبة';
	@override String get notInLibrary => 'لا في مكتبتك';
	@override String get inTheseLibraries => 'في هذه المكتبات';
	@override String get checkingLibrary => 'فحص مكتبتك ..';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: 'تعذر فحص أي خادم',
		one: 'تعذر فحص خادم واحد',
		two: 'تعذر فحص خادمين',
		few: 'تعذر فحص ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} خوادم',
		many: 'تعذر فحص ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} خادمًا',
		other: 'تعذر فحص ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} خادم',
	);
	@override String get emptyTitle => 'لا شيء هنا حتى الآن';
	@override String emptyMessage({required Object source}) => 'سيتم عرض الأقواس من ${source} هنا بمجرد أن يكون لديهم محتوى.';
	@override String searchHint({required Object source}) => 'البحث ${source}';
	@override String searchEmpty({required Object query}) => 'لا توجد نتائج لـ "${query}"';
	@override String searchPrompt({required Object source}) => 'البحث عن الأفلام والأحداث على ${source}.';
	@override String get searchFailed => 'فشل البحث، تحقق من اتصالك ومحاولة مرة أخرى.';
	@override late final _Translations$explore$badge$ar badge = _Translations$explore$badge$ar._(_root);
	@override late final _Translations$explore$stats$ar stats = _Translations$explore$stats$ar._(_root);
	@override late final _Translations$explore$season$ar season = _Translations$explore$season$ar._(_root);
	@override late final _Translations$explore$format$ar format = _Translations$explore$format$ar._(_root);
	@override late final _Translations$explore$sourceMaterial$ar sourceMaterial = _Translations$explore$sourceMaterial$ar._(_root);
	@override late final _Translations$explore$creditRole$ar creditRole = _Translations$explore$creditRole$ar._(_root);
	@override late final _Translations$explore$relation$ar relation = _Translations$explore$relation$ar._(_root);
	@override String broadcast({required Object day, required Object time}) => 'Airs ${day} عند ${time}';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => 'Airs ${day} عند ${time} ${timezone}';
	@override late final _Translations$explore$detail$ar detail = _Translations$explore$detail$ar._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} نتيجة',
		one: 'نتيجة واحدة',
		two: 'نتيجتان',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} نتائج',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} نتيجة',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} نتيجة',
	);
}

// Path: liveTv
class _Translations$liveTv$ar extends Translations$liveTv$en {
	_Translations$liveTv$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'البث التلفزيوني المباشر';
	@override String get guide => 'الدليل';
	@override String get noChannels => 'لا توجد قنوات متاحة';
	@override String get noDvr => 'لا يوجد DVR متوفر على أي خادم';
	@override String get serverUnavailable => 'لا يوجد خادم تلفزيون مباشر.';
	@override String get serverNotConnected => 'خادم التلفزيون المباشر غير متصل.';
	@override String get noPrograms => 'لا توجد بيانات البرنامج المتاحة';
	@override String get liveStreamFailed => 'البث المباشر فشل';
	@override String get unknownProgram => 'برنامج غير معروف';
	@override String get timelineLiveProgram => 'البرنامج الحي (يمكن أن يكون اللعب خارج هذا البرنامج)';
	@override String get timelineBuffer => 'بوفير الوقت';
	@override String get timelineUnavailable => 'الخطوط الزمنية غير متوفر';
	@override String get timelineEstimated => 'مشاهدة Playback';
	@override String get timelinePending => 'طوال البحث';
	@override String get timelineStale => 'قد يكون الجدول الزمني قد يكون قديمًا';
	@override String get unknownHub => 'غير معروف';
	@override String get unknownError => 'خطأ غير معروف';
	@override String channelNumber({required Object number}) => 'قناة ${number}';
	@override String get unknownChannel => 'قناة غير معروفة';
	@override String get live => 'مباشر';
	@override String get premiereBadge => 'جديد';
	@override String get reloadGuide => 'إعادة تحميل دليل';
	@override String get searchGuide => 'دليل البحث';
	@override String get searchHint => 'قنوات البحث والبرامج';
	@override String searchNoResults({required Object query}) => 'لا توجد مباريات لـ "${query}"';
	@override String get channelsSection => 'القنوات';
	@override String get programsSection => 'البرامج';
	@override String get now => 'الآن';
	@override String get today => 'اليوم';
	@override String get tomorrow => 'غداً';
	@override String get midnight => 'منتصف الليل';
	@override String get overnight => 'في الليل';
	@override String get morning => 'صباح';
	@override String get daytime => 'اليومية';
	@override String get evening => 'المساء';
	@override String get lateNight => 'في وقت متأخر من الليل';
	@override String get whatsOn => 'ما هو على';
	@override String get watchChannel => 'مشاهدة القناة';
	@override String get favorites => 'المفضلة';
	@override String get reorderFavorites => 'المفضلة المفضلة';
	@override String get noFavoriteChannels => 'لا قنوات مفضلة';
	@override String get noFavoriteChannelsHint => 'عرض جميع القنوات ، ثم اضغط طويلا على قناة لإضافتها إلى المفضلة لديك.';
	@override String get showAllChannels => 'عرض جميع القنوات';
	@override String get favoritesLoadFailed => 'لا يمكن تحميل المفضلة.تحقق من اتصالك ومحاولة مرة أخرى.';
	@override String get favoritesUpdateFailed => 'لا يمكن تحديث المفضلة.تحقق من اتصالك ومحاولة مرة أخرى.';
	@override String get joinSession => 'انضم إلى جلسة التقدم';
	@override String watchFromStart({required Object minutes}) => 'مشاهدة من البداية (${minutes} دقيقة مضت)';
	@override String get watchLive => 'مشاهدة Live';
	@override String get goToLive => 'اذهب إلى الحياة';
	@override String get record => 'تسجيل';
	@override String get recordEpisode => 'الحلقة التسجيلية';
	@override String get recordSeries => 'تسجيل المسلسل';
	@override String get recordOptions => 'خيارات التسجيل';
	@override String get saveTo => 'إنقاذ إلى';
	@override String get recordings => 'التسجيلات';
	@override String get scheduledRecordings => 'جدول زمني';
	@override String get recordingRules => 'قواعد التسجيل';
	@override String get noScheduledRecordings => 'لا شيء مخطط للتسجيل';
	@override String get manageRecording => 'إدارة التسجيل';
	@override String get cancelRecording => 'إلغاء التسجيل';
	@override String get cancelRecordingTitle => 'إلغاء هذا التسجيل؟';
	@override String cancelRecordingMessage({required Object title}) => '${title} لن يتم تسجيلها بعد الآن.';
	@override String get deleteRule => 'إلغاء القاعدة';
	@override String get deleteRuleTitle => 'إلغاء قاعدة التسجيل؟';
	@override String deleteRuleMessage({required Object title}) => 'لن يتم تسجيل الحلقات المستقبلية من ${title}.';
	@override String get recordingScheduled => 'تمت جدولة التسجيل.';
	@override String get alreadyScheduled => 'وقد تم التخطيط لهذا البرنامج بالفعل';
	@override String get dvrAdminRequired => 'إعدادات DVR تتطلب حساب admin';
	@override String get recordingFailed => 'لا أستطيع التخطيط للتسجيل';
	@override String get recordingTargetMissing => 'لا أستطيع تحديد تسجيل المكتبة';
	@override String get recordNotAvailable => 'التسجيل غير متوفر لهذا البرنامج';
	@override String get recordingCancelled => 'تسجيل إلغاء';
	@override String get recordingRuleDeleted => 'قاعدة تسجيل حذف';
	@override String get processRecordingRules => 'إعادة تقييم القواعد';
	@override String get recordingInProgress => 'تسجيل الآن';
	@override String recordingsCount({required Object count}) => '${count} مجدولة';
	@override String get editRule => 'قاعدة Edit';
	@override String get editRuleAction => 'تعديل';
	@override String get recordingRuleUpdated => 'قواعد التسجيل تحديث';
	@override String get guideReloadRequested => 'دليل التجديد المطلوب';
	@override String get guideReloadFailed => 'لا أستطيع تجديد الدليل';
	@override String get rulesProcessRequested => 'قواعد إعادة التقييم المطلوبة';
	@override String get rulesProcessFailed => 'لا يمكن إعادة تقييم قواعد التسجيل';
	@override String get recordShow => 'عرض السجلات';
	@override late final _Translations$liveTv$recordSettings$ar recordSettings = _Translations$liveTv$recordSettings$ar._(_root);
	@override String startingInMinutes({required Object minutes}) => 'بدءاً في ${minutes} دقيقة';
	@override String dayAtTime({required Object day, required Object time}) => '${day} في ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} أعيد بيانات تشغيل التلفزيون المباشر غير صحيحة';
	@override String get failedToStartChannel => 'لا أستطيع أن أبدأ القناة الحية';
	@override String get failedToBuildStreamUrl => 'لا أستطيع إنشاء URL';
	@override String playbackStartFailed({required Object reason}) => 'لا يمكن أن يبدأ القناة: ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'لا يمكن تغيير القناة: ${reason}';
}

// Path: collections
class _Translations$collections$ar extends Translations$collections$en {
	_Translations$collections$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'المجموعات';
	@override String get collection => 'مجموعة';
	@override String get empty => 'المجموعة فارغة';
	@override String get deleteCollection => 'حذف المجموعة';
	@override String deleteConfirm({required Object title}) => 'حذف «${title}»؟ لا يمكن التراجع عن هذا الإجراء.';
	@override String get deleted => 'جمع محذوف';
	@override String get deleteFailed => 'فشل في حذف المجموعة';
	@override String deleteFailedWithError({required Object error}) => 'لم يتم إزالة المجموعة: ${error}';
	@override String get selectCollection => 'اختيار مجموعة';
	@override String get collectionName => 'اسم جمع';
	@override String get enterCollectionName => 'إدخال اسم مجموعة';
	@override String get addedToCollection => 'إضافة إلى مجموعة';
	@override String get errorAddingToCollection => 'فشل في إضافة إلى المجموعة';
	@override String get created => 'مجموعة تم إنشاءها';
	@override String get removeFromCollection => 'إزالة من المجموعة';
	@override String removeFromCollectionConfirm({required Object title}) => 'هل تريد إزالة «${title}» من هذه المجموعة؟';
	@override String get removedFromCollection => 'إزالة من المجموعة';
	@override String get removeFromCollectionFailed => 'فشل في إزالتها من المجموعة';
	@override String removeFromCollectionError({required Object error}) => 'أخطاء إزالة من المجموعة: ${error}';
	@override String get searchCollections => 'البحث عن مجموعات...';
}

// Path: playlists
class _Translations$playlists$ar extends Translations$playlists$en {
	_Translations$playlists$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'قوائم التشغيل';
	@override String get playlist => 'قائمة التشغيل';
	@override String get noPlaylists => 'لا توجد لعبة';
	@override String get create => 'خلق قائمة اللعب';
	@override String get playlistName => 'لعبة الاسم';
	@override String get enterPlaylistName => 'إدخال اسم playlist';
	@override String get delete => 'حذف قائمة التشغيل';
	@override String get removeItem => 'إزالة من قائمة التشغيل';
	@override String get smartPlaylist => 'لعبة ذكية';
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} عنصر',
		one: 'عنصر واحد',
		two: 'عنصران',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} عناصر',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} عنصرًا',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} عنصر',
	);
	@override String get emptyPlaylist => 'هذه القائمة فارغة';
	@override String get deleteConfirm => 'إلغاء اللعب؟';
	@override String deleteMessage({required Object name}) => 'هل أنت متأكد من أنك تريد إزالة "${name}"؟';
	@override String get created => 'لعبة تم إنشاءها';
	@override String get deleted => 'Playlist حذف';
	@override String get itemAdded => 'إضافة إلى playlist';
	@override String get itemRemoved => 'إزالة من قائمة اللعب';
	@override String get selectPlaylist => 'اختيار Playlist';
	@override String get searchPlaylists => 'البحث عن ألعاب...';
	@override String get errorCreating => 'فشل في إنشاء قائمة اللعب';
	@override String get errorDeleting => 'فشل في إلغاء قائمة اللعب';
	@override String get errorLoading => 'فشل في تحميل قائمة الألعاب';
	@override String get errorAdding => 'فشل في إضافتها إلى قائمة اللعب';
	@override String get errorReordering => 'فشل في إعادة ترتيب العناصر في قائمة اللعب';
	@override String get errorRemoving => 'فشل في إزالتها من قائمة الألعاب';
}

// Path: music
class _Translations$music$ar extends Translations$music$en {
	_Translations$music$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'اذهب إلى الألبوم';
	@override String get goToArtist => 'الذهاب إلى الفنان';
	@override String get instantMix => 'مزيج فوري';
	@override String get playNext => 'تشغيل التالي';
	@override String get addToQueue => 'إضافة إلى كوشنر';
	@override String discNumber({required Object n}) => 'القرص ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مقطع',
		one: 'مقطع واحد',
		two: 'مقطعان',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مقاطع',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مقطع',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مقطع',
	);
	@override String get nowPlaying => 'اللعب الآن';
	@override String playingFrom({required Object title}) => 'اللعب من ${title}';
	@override String get queue => 'كوي';
	@override String get clearQueue => 'مسح قائمة التشغيل الحالية';
	@override String get lyrics => 'الكلمات';
	@override String get visualizer => 'التصور';
	@override String get visualizerProfileLoading => 'قراءة تحليل المسار ...';
	@override String get visualizerAmbientMotion => 'حركة البيئة';
	@override String get visualizerPlexLoudness => 'Plex الصوت';
	@override String get visualizerPreviousPreset => 'النمط البصري السابق';
	@override String get visualizerNextPreset => 'النمط البصري التالي';
	@override String get visualizerPresetAurora => 'أورورا';
	@override String get visualizerPresetBloom => 'بلوم';
	@override String get visualizerPresetOrbitals => 'أوربيتال';
	@override String get visualizerPresetPrism => 'الجائزة';
	@override String get visualizerPresetTunnel => 'النفق';
	@override String get visualizerPresetTrackMap => 'مسار الخريطة';
	@override String get noLyrics => 'لا توجد أغاني متوفرة';
	@override String get sleepTimer => 'ساعات النوم';
	@override String get sleepTimerEndOfTrack => 'نهاية المسار';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} دقيقة',
		one: 'دقيقة',
		two: 'دقيقتان',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} دقائق',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} دقيقة',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} دقيقة',
	);
	@override String get stopPlayback => 'إيقاف التشغيل';
	@override String get previousTrack => 'المسار السابق';
	@override String get nextTrack => 'المسار التالي';
	@override String get repeat => 'تكرار';
	@override String get repeatAll => 'تكرار الكل';
	@override String get repeatOne => 'تكرار واحد';
	@override String get instantMixNoServer => 'لا توجد خادم متاح لمزيج فوري';
	@override String get instantMixFailed => 'فشل في تحميل المزيج الفوري';
	@override String get instantMixEmpty => 'عودة المزيج الفوري دون أي مسارات';
	@override String noAudioUrl({required Object track}) => 'لا توجد عناوين URL الصوتية متوفرة على ${track}';
	@override late final _Translations$music$discography$ar discography = _Translations$music$discography$ar._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$ar extends Translations$watchTogether$en {
	_Translations$watchTogether$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'المشاهدة معًا';
	@override String get description => 'مشاهدة المحتوى في مزامنة مع الأصدقاء والعائلة';
	@override String get createRoom => 'خلق غرفة';
	@override String get creatingRoom => 'إنشاء غرفة...';
	@override String get joinRoom => 'انضم إلى الغرفة';
	@override String get joiningRoom => 'انضم إلى غرفة...';
	@override String get connecting => 'اتصال ...';
	@override String get relayPublic => 'تستخدم الغرف إعلانات الحزب المفتوح للجمهور.';
	@override String relayCustom({required Object url}) => 'تستخدم الغرف إرسالك على رقم ${url}.';
	@override String get recentRooms => 'غرف حديثة';
	@override String get roomActions => 'عمل الغرفة';
	@override String get renameRoom => 'غرفة رينامي';
	@override String get removeRoom => 'إزالة';
	@override String get enterRoomCode => 'أدخل رمز 6 أحرف من المضيف.';
	@override String get roomCode => 'رمز الغرفة';
	@override String get paste => 'كعكة';
	@override String get noCodeInClipboard => 'لا يحتوي الكليب على رمز غرفة';
	@override String get copyCode => 'نسخ الرمز';
	@override String get codeCopied => 'رمز الغرفة نسخة';
	@override String get shareInvite => 'مشاركة دعوة';
	@override String get inviteCopied => 'إرسال الرسالة - إرسال الرسالة إلى الرسالة';
	@override String inviteMessage({required Object code}) => 'انضم إلى غرفة Watch Together في PlezyNG: افتح غرفة Watch Together واختر انضم إلى غرفة وانضم إلى ${code}.';
	@override String get openSessionControls => 'Open Watch معا مراقبة الجلسة';
	@override String get reconnecting => 'إعادة الاتصال...';
	@override String get reconnectingDescription => 'انقطع الاتصال.تصل إلى الغرفة تلقائيًا.';
	@override String get connected => 'متصلة';
	@override String get disconnected => 'انقطاع الاتصال';
	@override String get youAreHost => 'أنت المضيف';
	@override String hostedBy({required Object name}) => 'استضافتها ${name}';
	@override String get hostControlsPlayback => 'أضف تعليق حول Playback';
	@override String get anyoneCanControl => 'يمكن لأي شخص التحكم في playback';
	@override String get roomLocked => 'غرفة مغلقة';
	@override String get nowPlaying => 'اللعب الآن';
	@override String get nothingPlaying => 'لا شيء يلعب';
	@override String get nothingPlayingHost => 'لعب شيء من أي مكتبة لتقاسمها مع الغرفة.';
	@override String get nothingPlayingGuest => 'عندما يلعب المضيف شيئًا ما ، يفتح هنا.';
	@override String get notShareable => 'هذا الفيديو ليس له مطابقة الكتالوج، لذلك فقط الأشخاص الذين لديهم إمكانية الوصول إلى نفس الخادم يمكن أن تلعب.';
	@override String get searching => 'إذا كنت تبحث عن هذا الفيديو في مكتباتك ...';
	@override String get yourCopy => 'نسخك';
	@override String get sharingYourCopy => 'أنت تشارك نسختك';
	@override String playingOtherLength({required Object difference}) => 'لعب النسخة الخاصة بك، ${difference}';
	@override String get mismatchTitle => 'النسخة الخاصة بك هي طوله مختلف';
	@override String mismatchDescription({required Object difference}) => 'أقرب نسخة هي ${difference} من الفيديو في الغرفة.';
	@override String get playAnyway => 'اللعب على أي حال';
	@override String get chooseAnotherCopy => 'اختر نسخة أخرى';
	@override String get dontPlay => 'لا تلعب';
	@override String get unavailableTitle => 'أنت لا تملك هذا الفيديو';
	@override String get unavailableDescription => 'PlezyNG لا يمكن العثور عليه في المكتبات الخاصة بك. احصل على نسخة لنفسك أو البحث مرة أخرى.';
	@override String get chooseCopy => 'اختر نسخة';
	@override String get searchAgain => 'البحث مرة أخرى';
	@override String get noCandidates => 'لا توجد نسخ في مكتباتك.';
	@override String get choiceFailed => 'لا أستطيع أن ألعب هذا النسخة لغرفة';
	@override String lengthLonger({required Object duration}) => '${duration} أطول';
	@override String lengthShorter({required Object duration}) => '${duration} أقصر';
	@override String get lengthSame => 'نفس الطول';
	@override String get lengthUnknown => 'الطول غير المعروف';
	@override String get joinCurrentPlayback => 'الانضمام إلى Playback';
	@override String get joinCurrentPlaybackDescription => 'ارجع إلى ما يراقبه المضيف حاليًا';
	@override String get stopMedia => 'توقف الفيديو للجميع';
	@override String get syncOffset => 'التعاقد Offset';
	@override String get syncOffsetDescription => 'تحويل الفيديو الخاص بك إذا كان يعمل أمام أو خلف الغرفة.';
	@override String offsetHint({required Object difference}) => 'نسختك ${difference} من الفيديو في الغرفة.';
	@override String applyDifference({required Object offset}) => 'الاستخدام ${offset}';
	@override String get offsetMinusSecond => '1 س';
	@override String get offsetMinusTenth => '- 100 ميغاواط';
	@override String get offsetPlusTenth => '+ 100 ميغاواط';
	@override String get offsetPlusSecond => '+1 س';
	@override String get participants => 'المشاركين';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مشارك',
		one: 'مشارك واحد',
		two: 'مشاركان',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مشاركين',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مشارك',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مشارك',
	);
	@override String get hostBadge => 'المضيف';
	@override String nameYou({required Object name}) => '${name} (أنت)';
	@override String get playerIdle => 'خاملة';
	@override String get playerLoading => 'تحميل';
	@override String get playerReady => 'جاهز';
	@override String get playerBuffering => 'بوفير';
	@override String get matchSearching => 'البحث';
	@override String get matchMatched => 'لديك الفيديو';
	@override String get matchMismatched => 'الطول المختلف';
	@override String get matchUnavailable => 'لا يوجد فيديو';
	@override String participantOffset({required Object offset}) => 'أوبسيت ${offset}';
	@override String get makeHost => 'جعل المضيف';
	@override String get makeHostQuestion => 'نقل المضيف؟';
	@override String makeHostConfirm({required Object name}) => '${name} سيسيطر على تشغيل وتشغيل الجلسة للجميع.';
	@override String get transfer => 'نقل';
	@override String get removeParticipant => 'إزالة من الغرفة';
	@override String removeParticipantQuestion({required Object name}) => 'إزالة ${name}؟';
	@override String removeParticipantConfirm({required Object name}) => '${name} يغادر الغرفة.يمكنهم الانضمام مرة أخرى مع الرمز ما لم تقم بإغلاق الغرفة.';
	@override String get remove => 'إزالة';
	@override String get roomSettings => 'إعدادات الغرفة';
	@override String get letEveryoneControl => 'دع الجميع يسيطرون على Playback';
	@override String get lockRoom => 'غرفة القفل';
	@override String get lockRoomDescription => 'لا أحد جديد يشارك';
	@override String get leaveRoom => 'غرفة مغادرة';
	@override String get leaveRoomQuestion => 'غرفة مغادرة؟';
	@override String get leaveRoomConfirm => 'يمكنك الانضمام مرة أخرى مع رمز الغرفة.';
	@override String get leave => 'تركها';
	@override String get endRoom => 'غرفة النهاية';
	@override String get endRoomQuestion => 'غرفة النهاية؟';
	@override String get endRoomConfirm => 'هذا هو نهاية الغرفة للجميع.';
	@override String get end => 'نهاية';
	@override String get playBlockedTitle => 'لعبة Playback لم تبدأ';
	@override String get playBlockedDescription => 'أضغط على اللعب للبدء في مشاهدة مع الغرفة.';
	@override late final _Translations$watchTogether$notices$ar notices = _Translations$watchTogether$notices$ar._(_root);
	@override late final _Translations$watchTogether$ended$ar ended = _Translations$watchTogether$ended$ar._(_root);
	@override late final _Translations$watchTogether$errors$ar errors = _Translations$watchTogether$errors$ar._(_root);
	@override String untitledEpisode({required Object number}) => 'الحلقة ${number}';
}

// Path: downloads
class _Translations$downloads$ar extends Translations$downloads$en {
	_Translations$downloads$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'التنزيلات';
	@override String get manage => 'إدارة';
	@override String get tvShows => 'مسلسلات تلفزيونية';
	@override String get movies => 'الأفلام';
	@override String get music => 'الموسيقى';
	@override String tracksQueued({required Object count}) => '${count} المسارات التي تم إدراجها للتنزيل';
	@override String get noDownloads => 'لا تنزيل بعد';
	@override String get noDownloadsDescription => 'سيتم عرض المحتوى الذي تم تنزيله هنا لمشاهدة خارج الإنترنت';
	@override String get downloadNow => 'تنزيل';
	@override String get deleteDownload => 'حذف download';
	@override String get retryDownload => 'Retry تحميل';
	@override String get downloadQueued => 'تم وضع التنزيل في قائمة الانتظار.';
	@override String get downloadResumed => 'تحميل مجدد';
	@override String get serverErrorBitrate => 'خطأ الخادم: قد يتجاوز الملف الحد الأقصى لمعدل النقاط عن بعد';
	@override String get storageFull => 'توقف التحميلات لحماية التخزين المتاحة.إعفاء بعض المساحة أو اختيار موقع آخر للتحميل، ثم الانسحاب.';
	@override String get storageUnavailable => 'توقفت التحميلات لأن التخزين المتاح لم يكن قادرا على التحقق.تحقق من موقع التحميل، ثم الانسحاب.';
	@override String episodesQueued({required Object count}) => '${count} الحلقة التي تم إرسالها للتنزيل';
	@override String get downloadDeleted => 'تحميل حذف';
	@override String deleteConfirm({required Object title}) => 'هل يمكن إزالة "${title}" من هذا الجهاز؟';
	@override String get deleteCollectionDownloads => 'حذف Downloads';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => 'هل تريد حذف جميع التنزيلات في «${title}» من هذا الجهاز؟';
	@override String get collectionDownloadsDeleted => 'تحميل حذف';
	@override String get cancelledDownloadTitle => 'إلغاء تحميل';
	@override String get cancelledDownloadMessage => 'تم إلغاء هذا التنزيل، ماذا تريد أن تفعل؟';
	@override String get allEpisodesAlreadyDownloaded => 'جميع الحلقات التي تم تنزيلها';
	@override String get resumeDownload => 'إعادة التدوير download';
	@override String get cancelledDownload => 'إلغاء تحميل';
	@override String syncingFile({required Object file, required Object status}) => '${file} (مزامنة ${status})';
	@override String downloadedFileClickToComplete({required Object file}) => 'تحميل ${file} - انقر للانتهاء';
	@override String get partialDownloadClickToComplete => 'تحميل جزئي - Click to complete';
	@override String get deleting => 'إلغاء...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'إزالة ${title}... (${current} من ${total})';
	@override String get queuedTooltip => 'كويد';
	@override String queuedFilesTooltip({required Object files}) => 'كويد ${files}';
	@override String get downloadingTooltip => 'تحميل...';
	@override String downloadingFilesTooltip({required Object files}) => 'تحميل ${files}';
	@override String get noDownloadsTree => 'لا تحميل';
	@override String get pauseAll => 'استراحة كل';
	@override String get resumeAll => 'قراءة كلها';
	@override String get retryAll => 'استرداد كل';
	@override String get retryFailed => 'إعادة التدوير الفشل تحميل';
	@override String get deleteAll => 'حذف الكل';
	@override String get selectVersion => 'اختيار النسخة';
	@override String get allEpisodes => 'كل الحلقات';
	@override String get unwatchedOnly => 'غير ملاحظة فقط';
	@override String nextNUnwatched({required Object count}) => '${count} غير مسبوق';
	@override String get customAmount => 'المبلغ المحدد ...';
	@override String get customAmountAny => 'المبلغ المحدد (كل ...';
	@override String get randomEpisodes => 'الحوادث العشوائية';
	@override String get includeSpecials => 'إدخال الخصائص';
	@override String get howManyEpisodes => 'كم عدد الحلقات؟';
	@override String get invalidEpisodeCount => 'إدخال عدد الحوادث الصحيح.';
	@override String get keepSynced => 'الحفاظ على التزامن';
	@override String get downloadOnce => 'تحميل مرة واحدة';
	@override String keepNUnwatched({required Object count}) => '${count} غير مسبوق';
	@override String get editSyncRule => 'تحرير قاعدة Sync';
	@override String get removeSyncRule => 'إزالة قاعدة Sync';
	@override String removeSyncRuleConfirm({required Object title}) => 'توقف عن مزامنة "${title}"؟ سيتم حفظ الحلقات التي تم تنزيلها.';
	@override String removeListSyncRuleConfirm({required Object title}) => 'توقف عن تصفية "${title}"؟';
	@override String get deleteSyncRuleDownloads => 'إزالة أيضًا النسخ المرتبطة';
	@override String get deleteSyncRuleDownloadsDescription => 'سيتم الاحتفاظ بالتحميلات المستخدمة من قبل قاعدة أو ملف تعريف آخر.';
	@override String syncRuleCreated({required Object count}) => 'قاعدة التزامن التي تم إنشاؤها – الحفاظ على ${count} الحوادث غير الملاحظة';
	@override String get syncRuleUpdated => 'قاعدة التزامن تحديث';
	@override String get syncRuleRemoved => 'قاعدة التزامن إزالة';
	@override String get syncRuleAndDownloadsRemoved => 'إزالة قاعدة التزامن والتحميلات المرتبطة';
	@override String get syncRuleCleanupBusy => 'قواعد التزامن حاليا تحديث.حاول مرة أخرى في لحظة.';
	@override String get syncRuleCleanupUnavailable => 'لا يمكن التعرف على التحميلات المرتبطة بأمان.إعادة توصيل الخادم ومحاولة مرة أخرى، أو إزالة القاعدة دون حذف التحميلات.';
	@override String syncedNewEpisodes({required Object count, required Object title}) => 'المزامنة ${count} أحداث جديدة ل ${title}';
	@override String get syncNow => 'Sync الآن';
	@override String get downloadsUpToDate => 'تحميلات متوفرة حتى الآن';
	@override String syncComplete({required Object queued, required Object removed}) => 'متزامنة كاملة · ${queued} queued, ${removed} إزالة';
	@override String get activeSyncRules => 'قواعد Sync';
	@override String get reviewOrphanFiles => 'مشاهدة فيلم Orphaned Downloads';
	@override String get orphanReviewTitle => 'مشاهدة فيلم Orphaned Downloads';
	@override String get orphanReviewDescription => 'هذه الملفات المسمى موجودة في مجلدات التحميل التي يتم إدارةها بواسطة التطبيق الافتراضي PlezyNG ولا تتوافق مع سجل التحميل أو المهمة النشطة.';
	@override String orphanReviewCount({required Object count, required Object size}) => '${count} ملفات · ${size}';
	@override String orphanDeleteFiles({required Object count}) => 'حذف ${count} الملفات';
	@override String get orphanCleanupNone => 'لا توجد ملفات تنزيل العنكبوت';
	@override String get orphanCleanupFailed => 'PlezyNG لم يتمكن من فحص مجلد التنزيلات التي تم إدارتها بأمان.';
	@override String get orphanCleanupChanged => 'تم تغيير قائمة التنزيل أثناء مراجعة.مراجعة الملفات مرة أخرى قبل التنظيف.';
	@override String orphanCleanupComplete({required Object count, required Object size}) => 'إزالة ${count} ملفات العذراء · ${size} إطلاق سراح';
	@override String get noSyncRules => 'لا توجد قواعد متزامنة';
	@override String get manageSyncRule => 'إدارة Sync';
	@override String get editEpisodeCount => 'الحلقة العد';
	@override String get editSyncFilter => 'تصفية Sync';
	@override String get syncAllItems => 'إزالة جميع العناصر';
	@override String get syncUnwatchedItems => 'تصنيف العناصر غير المراقبة';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'الخادم: ${server} • ${status}';
	@override String get syncRuleAvailable => 'متاح';
	@override String get syncRuleOffline => 'غير متصل';
	@override String get syncRuleSignInRequired => 'التوقيع في المطلوب';
	@override String get syncRuleAccessDenied => 'الوصول يرفض';
	@override String get syncRuleNotAvailableForProfile => 'غير متوفر للملف الحالي';
	@override String get syncRuleUnknownServer => 'الخادم المجهول';
	@override String get syncRuleListCreated => 'قاعدة التزام تم إنشاؤها';
	@override late final _Translations$downloads$backgroundWarning$ar backgroundWarning = _Translations$downloads$backgroundWarning$ar._(_root);
	@override String get options => 'خيارات التحميل';
	@override late final _Translations$downloads$groupings$ar groupings = _Translations$downloads$groupings$ar._(_root);
	@override String get unknownLibrary => 'مكتبة غير معروفة';
	@override String get unknownShow => 'عرض غير معروف';
	@override String get unknownSeason => 'الموسم المجهول';
	@override String get unknownAlbum => 'ألبوم غير معروف';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} تم الانتهاء منه';
	@override String storageUsed({required Object size}) => 'التخزين المستخدم: ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} تنزيل',
		one: 'تنزيل واحد',
		two: 'تنزيلان',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} تنزيلات',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} تنزيل',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} تنزيل',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مسلسل',
		one: 'مسلسل واحد',
		two: 'مسلسلان',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مسلسلات',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مسلسل',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مسلسل',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} فيلم',
		one: 'فيلم واحد',
		two: 'فيلمان',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} أفلام',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} فيلم',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} فيلم',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ألبوم',
		one: 'ألبوم واحد',
		two: 'ألبومان',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ألبومات',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ألبوم',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ألبوم',
	);
	@override String get errorFileNotFound => 'ملف غير موجود (404)';
	@override String get errorDownloadNotAllowed => 'تنزيل غير مسموح به الخادم (403)';
	@override String get errorDownloadFailed => 'تحميل فشل';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'تحميل فشل: ${reason}';
	@override String get convertingOnServer => 'تحويلها إلى خادم ..';
	@override String convertingOnServerPercent({required Object percent}) => 'التحويل على الخادم · ${percent}%';
	@override String errorHttpStatus({required Object status}) => 'تحميل فشل (HTTP ${status})';
	@override String errorPostProcessing({required Object reason}) => 'بعد المعالجة فشل: ${reason}';
	@override String get reasonFileNotSaved => 'لا يمكن حفظ الملف على هذا الجهاز';
	@override String get reasonCannotResume => 'لا يمكن إعادة تنزيل الجزئي';
	@override String get reasonDeviceStorageFull => 'هذا الجهاز خارج التخزين';
	@override String get notificationDownloading => 'تحميل...';
	@override String get notificationComplete => 'تحميل كامل';
	@override String get notificationPaused => 'تحميل استراحة';
}

// Path: shaders
class _Translations$shaders$ar extends Translations$shaders$en {
	_Translations$shaders$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'الظلال';
	@override String get noShaderDescription => 'لا تحسينات الفيديو';
	@override String get nvscalerDescription => 'مقياس الصورة NVIDIA للحصول على مقاطع فيديو أكثر وضوحا';
	@override String get artcnnVariantNeutral => 'محايد';
	@override String get artcnnVariantDenoise => 'ديني';
	@override String get artcnnVariantDenoiseSharpen => 'دينيس + شاربين';
	@override String get qualityFast => 'سريع';
	@override String get qualityHQ => 'الجودة العالية';
	@override String get mode => 'الأزياء';
	@override String get importShader => 'استيراد شاتر';
	@override String get customShaderDescription => 'تخصيص شاتر GLSL';
	@override String get shaderImported => 'شاتري المستوردة';
	@override String get shaderImportFailed => 'فشل في استيراد الشطرنج';
	@override String get deleteShader => 'إلغاء Shader';
	@override String deleteShaderConfirm({required Object name}) => 'إلغاء “${name}”؟';
}

// Path: companionRemote
class _Translations$companionRemote$ar extends Translations$companionRemote$en {
	_Translations$companionRemote$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'جهاز التحكم المرافق';
	@override String connectedTo({required Object name}) => 'الاتصال بـ ${name}';
	@override String get unknownDevice => 'جهاز غير معروف';
	@override late final _Translations$companionRemote$session$ar session = _Translations$companionRemote$session$ar._(_root);
	@override late final _Translations$companionRemote$pairing$ar pairing = _Translations$companionRemote$pairing$ar._(_root);
	@override late final _Translations$companionRemote$remote$ar remote = _Translations$companionRemote$remote$ar._(_root);
	@override late final _Translations$companionRemote$errors$ar errors = _Translations$companionRemote$errors$ar._(_root);
	@override String get closedBeforeAuth => 'إغلاق الاتصال قبل التحقق';
}

// Path: videoSettings
class _Translations$videoSettings$ar extends Translations$videoSettings$en {
	_Translations$videoSettings$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'سرعة التشغيل';
	@override String get normalSpeed => 'عادي';
	@override String sleepTimerActive({required Object duration}) => 'نشط (${duration})';
	@override String get zoom => 'تكبير (Cover)';
	@override String get sleepTimer => 'ساعة النوم';
	@override String get audioSync => 'الصوت Sync';
	@override String get subtitleSync => 'موضوع Sync';
	@override String get hdr => 'HDR';
	@override String get hdrUnsupported => 'HDR غير متوفر هنا - هذا الكمبيوتر المكتبي أو إنتاج الفيديو لا يمكن أن يحمل.';
	@override String get hdrToneMapping => 'خريطة HDR Tone';
	@override String get hdrToneMappingCompositor => 'المكونات';
	@override String get hdrToneMappingCompositorDescription => 'قم بمرور البيانات المعدلة HDR المصدر وترك خريطة مكون سطح المكتب.';
	@override String get hdrToneMappingPlayer => 'المشغّل';
	@override String get hdrToneMappingPlayerDescription => 'خريطة إلى أعلى ضوء الشاشة في اللاعب، ثم أخبر المؤلف النتيجة.';
	@override String get hdrToneMappingFailed => 'لا يمكن تغيير خرائط الأصوات HDR - الوضع السابق لا يزال نشطا.';
	@override String get audioOutput => 'أداة الصوت';
	@override String get performanceOverlay => 'أداء Overlay';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'حول';
	@override String get audioOutputSpatial => 'الفضاء الصوت';
	@override String get audioOutputStereo => 'ستيريو (Stereo)';
	@override String get audioEqualizer => 'الصوت المساواة';
	@override String get audioEqualizerDescription => 'تعديل خمسة شرائح التردد لهذا الجهاز. متوفر على mpv؛ EQ النشط يزيل الصوت ويمنع الارتباك.';
	@override String get audioEqualizerFlat => 'مسطحة';
	@override String get audioEqualizerActive => 'مخصص';
	@override String get audioEqualizerSaveFailed => 'لا يمكن حفظ إعدادات المساواة الصوتية.';
	@override String get backgroundVideoAudio => 'خلفية الفيديو الصوت';
	@override String get backgroundVideoAudioDescription => 'الحفاظ على تشغيل الفيديو الصوتي عند مغادرة المشغل؛ يتم إخفاء الصورة حتى تعود. Android يستخدم إشعار تشغيل الوسائط.';
	@override String get audioNormalization => 'استقرار الضوضاء';
	@override String get audioNormalizationDisablesPassthrough => 'إزالة الصوت إلى PCM؛ يغلق passthrough بينما يغلق';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$ar extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get color => 'اللون';
	@override String get performance => 'الأداء';
	@override String get buffer => 'بوفير';
	@override String get app => 'التطبيق';
	@override String get decoder => 'ديكودر';
	@override String get rawDecoder => 'أدوات التخفيف';
	@override String get tunneling => 'النفقات';
	@override String get passthrough => 'كسارة';
	@override String get aspect => 'وجهة نظر';
	@override String get rotation => 'الدوران';
	@override String get dvSource => 'مصدر DV';
	@override String get dvPath => 'الطريق DV';
	@override String get dvRouteDecoder => 'Dolby Vision الخصم';
	@override String get dvRouteDecoderP81 => 'Dolby Vision التخزين (P7→8.1)';
	@override String get dvRouteBaseLayer => 'طبقة قاعدة';
	@override String get dvRouteBaseLayerHdr10 => 'HDR10 طبقة أساسية';
	@override String get dvRouteBaseLayerHlg => 'طبقة قاعدة HLG';
	@override String get dvRouteBaseLayerSdr => 'SDR طبقة أساسية';
	@override String get dvRouteReshaped => 'إعادة تدوير RPU (gpu-next)';
	@override String get p7Conversion => 'P7 كونف';
	@override String get sampleRate => 'معدل العينة';
	@override String get pixelFormat => 'بيكسل Fmt';
	@override String get hwFormat => 'تنسيق العتاد';
	@override String get matrix => 'ماتريكس';
	@override String get primaries => 'الأوائل';
	@override String get transfer => 'نقل';
	@override String get renderFps => 'رينجر FPS';
	@override String get displayFps => 'عرض FPS';
	@override String get avSync => 'A / V التزامن';
	@override String get dropped => 'انقطاع';
	@override String get dvRpus => 'DV RPUs';
	@override String get dvRpuAverage => 'رويترز RPU Avg';
	@override String get dvSampleAverage => 'DV نموذج Avg';
	@override String get maxLuma => 'ماكس لوما';
	@override String get minLuma => 'لوميا';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'كاش المستخدم';
	@override String get cacheLimit => 'الحد الأدنى للكاش';
	@override String get speed => 'السرعة';
	@override String get player => 'المشغّل';
	@override String get playMethod => 'طريقة التشغيل';
	@override String get memory => 'الذاكرة';
	@override String get uiFps => 'فاي FPS';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Android HW';
	@override String get decoderNvidiaHw => 'NVIDIA HW';
	@override String get decoderQualcommHw => 'كوالكوم HW';
	@override String get decoderMediatekHw => 'الوسائط HW';
	@override String get decoderExynosHw => 'إكسينوس HW';
	@override String get decoderSoftware => 'البرمجة';
	@override String get decoderHardware => 'الأجهزة';
	@override String get tunnelingActive => 'نشطة';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted} (${failures} فاشلة)';
}

// Path: externalPlayer
class _Translations$externalPlayer$ar extends Translations$externalPlayer$en {
	_Translations$externalPlayer$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'اللاعب الخارجي';
	@override String get useExternalPlayer => 'استخدام اللاعب الخارجي';
	@override String get useExternalPlayerDescription => 'فتح الفيديوهات في تطبيق آخر';
	@override String get selectPlayer => 'اختيار اللاعب';
	@override String get customPlayers => 'اللاعبين المخصصين';
	@override String get systemDefault => 'نظام الافتراض';
	@override String get addCustomPlayer => 'إضافة اللاعب المخصص';
	@override String get playerName => 'اسم اللاعب';
	@override String get playerNameHint => 'لاعبنا';
	@override String get playerCommand => 'القيادة';
	@override String get playerPackage => 'اسم الحزمة';
	@override String get playerUrlScheme => 'نظام URL';
	@override String get off => 'إيقاف';
	@override String get launchFailed => 'فشل في فتح لاعب خارجي';
	@override String appNotInstalled({required Object name}) => '${name} لم يتم تثبيت';
	@override String get playInExternalPlayer => 'اللعب في اللاعب الخارجي';
}

// Path: metadataEdit
class _Translations$metadataEdit$ar extends Translations$metadataEdit$en {
	_Translations$metadataEdit$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'تعديل';
	@override String get screenTitle => 'تعديل البيانات الوصفية';
	@override String get basicInfo => 'معلومات أساسية';
	@override String get artwork => 'الفن';
	@override String get advancedSettings => 'الإعدادات المتقدمة';
	@override String get title => 'العنوان';
	@override String get sortTitle => 'عنوان الفرز';
	@override String get originalTitle => 'العنوان الأصلي';
	@override String get releaseDate => 'تاريخ الإصدار';
	@override String get contentRating => 'تصنيف المحتوى';
	@override String get studio => 'الاستوديو';
	@override String get tagline => 'الشعار النصي';
	@override String get summary => 'ملخص';
	@override String get poster => 'ملصق';
	@override String get background => 'الخلفية';
	@override String get logo => 'الشعار';
	@override String get squareArt => 'ميدان الفن';
	@override String get selectPoster => 'اختيار الملصقات';
	@override String get selectBackground => 'اختيار الخلفية';
	@override String get selectLogo => 'اختيار الشعار';
	@override String get selectSquareArt => 'اختيار الفنون الميدانية';
	@override String get fromUrl => 'من URL';
	@override String get uploadFile => 'تحميل الملفات';
	@override String get enterImageUrl => 'إدخال صورة URL';
	@override String get imageUrl => 'صورة URL';
	@override String get metadataUpdated => 'متاجدات تحديثات';
	@override String get metadataUpdateFailed => 'فشل في تحديث البيانات الميتا';
	@override String get artworkUpdated => 'الفنون المحدثة';
	@override String get artworkUpdateFailed => 'فشل في تحديث أعمال الفن';
	@override String get noArtworkAvailable => 'لا توجد أعمال فنية متاحة';
	@override String artworkOption({required Object index}) => 'الخيارات الفنية ${index}';
	@override String selectedArtworkOption({required Object index}) => 'الخيار الفن ${index}، اختياري';
	@override String get notSet => 'لا تضع';
	@override String get libraryDefault => 'مكتبة الافتراضية';
	@override String get accountDefault => 'الحساب الافتراضي';
	@override String get seriesDefault => 'سلسلة الافتراض';
	@override String get episodeSorting => 'الحلقة تصنيف';
	@override String get oldestFirst => 'أقدم أول';
	@override String get newestFirst => 'أحدث أولا';
	@override String get keep => 'الحفاظ على';
	@override String get allEpisodes => 'كل الحلقات';
	@override String latestEpisodes({required Object count}) => '${count} آخر الأحداث';
	@override String get latestEpisode => 'الحلقة الأخيرة';
	@override String episodesAddedPastDays({required Object count}) => 'إضافات في الأيام الماضية ${count}';
	@override String get deleteAfterPlaying => 'إزالة الحلقات بعد اللعب';
	@override String get never => 'أبدًا';
	@override String get afterADay => 'بعد يوم واحد';
	@override String get afterAWeek => 'بعد أسبوع';
	@override String get afterAMonth => 'بعد شهر واحد';
	@override String get onNextRefresh => 'في التجديد التالي';
	@override String get seasons => 'المواسم';
	@override String get show => 'عرض';
	@override String get hide => 'إخفاء';
	@override String get episodeOrdering => 'الحلقة الأوامر';
	@override String get tmdbAiring => 'قاعدة بيانات الأفلام (Aired)';
	@override String get tvdbAiring => 'TheTVDB (الإيرادات)';
	@override String get tvdbAbsolute => 'TheTVDB (المطلق )';
	@override String get metadataLanguage => 'لغة الميتايتات';
	@override String get useOriginalTitle => 'استخدم العنوان الأصلي';
	@override String get preferredAudioLanguage => 'لغة الصوت المفضلة';
	@override String get preferredSubtitleLanguage => 'لغة الترجمة المفضلة';
	@override String get subtitleMode => 'وضع Subtitle Auto-Select';
	@override String get manuallySelected => 'اختياري يدويا';
	@override String get shownWithForeignAudio => 'عرض مع الصوت الأجنبي';
	@override String get alwaysEnabled => 'إمكانية دائما';
	@override String get tags => 'الوسوم';
	@override String get addTag => 'إضافة tag';
	@override String get genre => 'النوع';
	@override String get director => 'المخرج';
	@override String get writer => 'الكاتب';
	@override String get producer => 'المنتج';
	@override String get country => 'البلد';
	@override String get collection => 'مجموعة';
	@override String get label => 'العلامة';
	@override String get quickTag => 'Tag سريع ..';
}

// Path: matchScreen
class _Translations$matchScreen$ar extends Translations$matchScreen$en {
	_Translations$matchScreen$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get match => 'المباراة...';
	@override String get fixMatch => 'إصلاح المباراة ..';
	@override String get unmatch => 'عدم المباراة';
	@override String get unmatchConfirm => 'ماذا تفعل هذه المباراة؟ Plex يعالجها كغير متنافسة حتى الانتهاء.';
	@override String get unmatchSuccess => 'موضوع غير متوافق';
	@override String get unmatchFailed => 'فشل في إلغاء النتيجة';
	@override String get matchApplied => 'المباراة تطبق';
	@override String get matchFailed => 'فشل في تطبيق المباراة';
	@override String get titleHint => 'العنوان';
	@override String get yearHint => 'السنة';
	@override String get search => 'بحث';
	@override String get noMatchesFound => 'لا توجد مباريات';
}

// Path: serverTasks
class _Translations$serverTasks$ar extends Translations$serverTasks$en {
	_Translations$serverTasks$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'وظائف الخادم';
	@override String get failedToLoad => 'فشل في تحميل المهام';
	@override String get noTasks => 'لا توجد مهام تسير';
}

// Path: trakt
class _Translations$trakt$ar extends Translations$trakt$en {
	_Translations$trakt$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'متصلة';
	@override String connectedAs({required Object username}) => 'اتصلت بـ @${username}';
	@override String get disconnectConfirm => 'إلغاء الاتصال Trakt حساب؟';
	@override String get disconnectConfirmBody => 'PlezyNG سوف تتوقف عن إرسال الأحداث إلى Trakt.';
	@override String get scrobble => 'في الوقت الحقيقي Scrobbling';
	@override String get scrobbleDescription => 'إرسال لعبة، وقف، وقف الأحداث إلى Trakt أثناء تشغيل.';
	@override String get watchedSync => 'سينك مراقبة الوضع';
	@override String get watchedSyncDescription => 'عند وضع علامة على العناصر كما تم مشاهدتها في PlezyNG، يتم وضع علامة على العناصر كما تم مشاهدتها في Trakt.';
}

// Path: seerr
class _Translations$seerr$ar extends Translations$seerr$en {
	_Translations$seerr$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'الاتصال Seerr';
	@override String get serverUrl => 'URL الخادم';
	@override String get serverUrlHelper => 'العنوان الخاص بك Seerr instance';
	@override String get checkServer => 'مواصلة';
	@override String get signInWithJellyfin => 'تسجيل الدخول مع Jellyfin';
	@override String get signInWithEmby => 'تسجيل الدخول مع Emby';
	@override String get signInWithLocal => 'استخدام حساب محلي';
	@override String get email => 'البريد الإلكتروني';
	@override String get noSignInMethods => 'هذه الحالة Seerr لا تقدم أي دعم طريقة تسجيل الدخول PlezyNG.';
	@override String get instance => 'الحالة';
	@override String get disconnectConfirm => 'إلغاء الاتصال بـ Seerr؟';
	@override String get disconnectConfirmBody => 'PlezyNG سوف تنسى هذه الحالة Seerr.';
	@override String get request => 'طلب';
	@override String get request4k => 'طلب في 4K';
	@override String get seasons => 'المواسم';
	@override String get allSeasons => 'جميع الموسم';
	@override String get advancedOptions => 'متقدم';
	@override String get destinationServer => 'مستخدم الوجهة';
	@override String get qualityProfile => 'ملف تعريف الجودة';
	@override String get rootFolder => 'مجلد الجذر';
	@override String get languageProfile => 'ملف تعريف اللغة';
	@override String get tags => 'الوسوم';
	@override String get noTags => 'لا توجد علامات';
	@override String defaultOption({required Object name}) => '${name} (المعيار الافتراضي)';
	@override String get animeNote => 'هذه السلسلة هي أنيمي.';
	@override String get requestSubmitted => 'الطلب المقدم';
	@override String requestFailed({required Object error}) => 'طلب فشل: ${error}';
	@override String get requestsLoadFailed => 'لا يمكن تحميل خيارات الطلب';
	@override String get nothingToRequest => 'كل شيء متاح أو مطلوب.';
	@override String get statusAvailable => 'متاح';
	@override String get statusPartiallyAvailable => 'متاحة جزئيا';
	@override String get statusRequested => 'المطالبة';
	@override String get statusProcessing => 'المعالجة';
	@override String get statusBlocklisted => 'محاصرة';
	@override String couldNotReach({required Object url, required Object error}) => 'لا يمكن أن تصل إلى ${url}: ${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => 'لا توجد حالة في Seerr عند ${url} (HTTP ${status})';
	@override String get behindAuthProxy => 'استجاب وكيل عكسي يتطلب المصادقة (SSO أو مصادقة HTTP) بدلًا من Seerr. لا يستطيع PlezyNG تسجيل الدخول من خلاله: اسمح لمسار /api/v1 الخاص بـ Seerr بتجاوز الوكيل لهذا التطبيق، أو استخدم عنوانًا يصل إلى Seerr مباشرةً.';
	@override String get invalidUrl => 'إدخال عنوان خادم مثل https://seerr.example.com';
	@override String get quickConnectUnsupported => 'هذا المثال لا يدعم Quick Connect.إنه يحتاج إلى Seerr 3.4 أو أحدث.';
	@override String get notInitialized => 'هذه الحالة Seerr لم تكتمل إعدادات أول تشغيل';
	@override String get noPlexTokenForReauth => 'رقم Plex توكن متاح للتسجيل مرة أخرى';
	@override String get noStoredCredentials => 'لا تتوفر بيانات تسجيل دخول محفوظة لتسجيل الدخول مجددًا';
	@override String get signInRejected => 'تم رفض التسجيل';
	@override String get noSessionCookie => 'لم تصدر شركة Seerr كوكيز الجلسة';
	@override String get freshCookieRejected => 'سييرر يرفض الكوكيز الجلسة الجديدة';
	@override String get noUserInformation => 'لم تعيد شركة Seerr معلومات المستخدم';
	@override String get sessionRejectedAfterReauth => 'تم رفض الجلسة بعد التوقيع مرة أخرى';
	@override String get permissionDenied => 'رفضت شركة Seerr هذا الإجراء: لم يعد حسابك لديه إذن مطلوب';
	@override String get permissionRevoked => 'لم يعد لديك إذن لطلب هذا';
}

// Path: services
class _Translations$services$ar extends Translations$services$en {
	_Translations$services$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'الخدمات';
	@override String get hubSubtitle => 'يراقب Sync التقدم و يطلب عناوين جديدة.';
	@override String get integrations => 'الاندماج';
	@override String get notConnected => 'غير متصل';
	@override String connectedAs({required Object username}) => 'اتصلت بـ @${username}';
	@override String get scrobble => 'تتبع التقدم تلقائيًا';
	@override String get scrobbleDescription => 'تحديث قائمتك عند الانتهاء من الحلقة أو الفيلم.';
	@override String disconnectConfirm({required Object service}) => 'إلغاء الاتصال ${service}؟';
	@override String disconnectConfirmBody({required Object service}) => 'PlezyNG سوف تتوقف عن التحديث ${service}.';
	@override String connectFailed({required Object service}) => 'لا أستطيع الاتصال بـ ${service}.';
	@override late final _Translations$services$names$ar names = _Translations$services$names$ar._(_root);
	@override late final _Translations$services$simklReconnect$ar simklReconnect = _Translations$services$simklReconnect$ar._(_root);
	@override late final _Translations$services$deviceCode$ar deviceCode = _Translations$services$deviceCode$ar._(_root);
	@override late final _Translations$services$oauthProxy$ar oauthProxy = _Translations$services$oauthProxy$ar._(_root);
	@override late final _Translations$services$pendingAuth$ar pendingAuth = _Translations$services$pendingAuth$ar._(_root);
	@override late final _Translations$services$libraryFilter$ar libraryFilter = _Translations$services$libraryFilter$ar._(_root);
}

// Path: addServer
class _Translations$addServer$ar extends Translations$addServer$en {
	_Translations$addServer$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => 'إضافة ${product} الخادم';
	@override String get serverUrls => 'URL الخادم';
	@override String get serverUrlsHelper => 'العديد من عناوين URL المسموح بها ، منفصلة بواسطة commas.';
	@override String get findServer => 'العثور على الخادم';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'البحث عن خادم محلي ${product} ...';
	@override String localMediaBrowserServers({required Object product}) => 'الخادم المحلي ${product}';
	@override String get username => 'اسم المستخدم';
	@override String get password => 'كلمة المرور';
	@override String get signIn => 'تسجيل الدخول';
	@override String get change => 'التغيير';
	@override String get required => 'مطلوب';
	@override String couldNotReachServer({required Object error}) => 'لا يمكن الوصول إلى الخادم: ${error}';
	@override String signInFailed({required Object error}) => 'تسجيل الدخول فاشلة: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect فشل: ${error}';
	@override String get addPlexTitle => 'تسجيل الدخول مع Plex';
	@override String get pinExpired => 'انتهاء صلاحية PIN قبل تسجيل الدخول، يرجى المحاولة مرة أخرى.';
	@override String failedToRegisterAccount({required Object error}) => 'فشل في تسجيل الحساب: ${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => 'إدخال عنوان URL الخاص بك ${product}';
	@override String get addConnectionTitle => 'إضافة اتصال';
	@override String addConnectionTitleScoped({required Object name}) => 'إضافة إلى ${name}';
	@override String get signInWithPlexCard => 'تسجيل الدخول مع Plex';
	@override String get signInWithPlexCardSubtitle => 'يُضاف هذا الجهاز، ويُضاف الخوادم المشتركة.';
	@override String get signInWithPlexCardSubtitleScoped => 'إمكانية الحصول على حساب Plex.المستخدمين المنزليين يصبحون ملفات تعريف.';
	@override String connectToMediaBrowserCard({required Object product}) => 'الاتصال بـ ${product}';
	@override String get connectToMediaBrowserCardSubtitle => 'أدخل عنوان URL، اسم المستخدم، وكلمة المرور.';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => 'تسجيل الدخول إلى خادم ${product}.ربط إلى ${name}.';
	@override String get borrowFromAnotherProfile => 'القروض من ملف تعريف آخر';
	@override String get borrowFromAnotherProfileSubtitle => 'إعادة استخدام اتصال ملف تعريف آخر.البروفيسور المحمية بـ PIN تتطلب PIN.';
	@override String get invalidCredentials => 'اسم المستخدم أو كلمة المرور غير صالحة';
	@override String get authResponseNotJson => 'رد التحقق غير صالح JSON';
	@override String get authResponseIncomplete => 'استجابة التسجيل من الخادم كانت غير كاملة';
	@override String get quickConnectRejected => 'Quick Connect تم رفضها من قبل الخادم';
	@override String get quickConnectNotJson => 'رد Quick Connect لم يكن صالحا JSON';
	@override String get quickConnectMissingFields => 'رد Quick Connect يفتقر إلى رمز أو سر';
	@override String get quickConnectPollRejected => 'Quick Connect استجواب تم رفضه من قبل الخادم';
	@override String get serverTimedOut => 'لم يستجيب الخادم في الوقت المناسب.';
	@override String get responseNotJson => 'رد الخادم غير صالح JSON';
	@override String responseMissingIdentity({required Object product}) => 'الإجابة تفتقر إلى معرف أو اسم الخادم - هل هذا هو الخادم ${product}؟';
	@override String probeFailed({required Object error}) => 'لا يمكن الوصول إلى الخادم: ${error}';
	@override String enterAtLeastOneUrl({required Object product}) => 'إدخال عنوان URL واحد على الأقل ${product}';
	@override String noReachableServer({required Object product}) => 'لم يتم العثور على خادم ${product} متاح';
	@override String urlsPointToDifferentServers({required Object product}) => 'هذه العناوين URL تشير إلى مختلف الخوادم ${product}';
	@override String urlDoesNotMatchServer({required Object product}) => 'هذا URL لا يتطابق مع ${product} الخادم';
	@override String get redirectUnsupported => 'إعادة توجيه الخادم إلى عنوان URL غير مدعوم';
	@override String redirectDifferentHost({required Object product}) => 'إعادة توجيه الخادم إلى مستودع مختلف.إدخال URL النهائي ${product} مباشرة.';
	@override String get redirectInsecure => 'إعادة توجيه الخادم من HTTPS إلى عنوان URL غير آمن';
	@override String redirectUnsupportedEnterFinal({required Object product}) => 'إعادة توجيه الخادم إلى عنوان URL غير مدعوم، أدخل عنوان URL ${product} النهائي مباشرة.';
	@override String get directPlexServerUrl => 'Plex URL الخادم';
	@override String get directPlexServerUrlHelper => 'أدخل IP المحلي وميناء Plex Media Server الخاص بك.';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex توكين (اختياري)';
	@override String get plexTokenHelper => 'اترك فارغا إذا تم السماح بالوصول دون auth على هذا الخادم.';
	@override String get plexTokenRequired => 'يرجى إدخال رمز Plex الخاص بك (X-Plex-Token).';
	@override String get connectDirectPlexCard => 'Plex خادم الوسائط (مباشر / محلي)';
	@override String get connectDirectPlexCardSubtitle => 'اتصل مباشرة باستخدام IP أو URL المحلي دون حساب plex.tv.';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => 'اتصل مباشرة باستخدام IP المحلي أو URL. اتصل ${name}.';
	@override String get insecureTitle => 'اتصال غير مشفر';
	@override String insecureDescription({required Object url}) => 'يستخدم ${url} بروتوكول HTTP. قد يتمكن أشخاص على الشبكة من قراءة كلمة مرورك ورموز الوصول والوسائط أو تغييرها. استخدم HTTPS عند توفره. لا تتابع إلا إذا كنت تثق بهذه الشبكة وتقبل هذه المخاطرة.';
	@override String get allowHttp => 'السماح باستخدام HTTP';
	@override String get httpsRequired => 'استخدام HTTPS أو يسمح صراحة بتوصيل غير مشفر.';
}

// Path: watchLink
class _Translations$watchLink$ar extends Translations$watchLink$en {
	_Translations$watchLink$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => 'لم أتمكن من الوصول إلى خادم Plex لهذا الرابط.';
	@override String get notFound => 'لم أتمكن من العثور على هذا العرض أو الفيلم على خادمات Plex الخاصة بك.';
	@override String get ambiguous => 'هذا الرابط يطابق العناصر على أكثر من خادم واحد.إضافة خادم إلى الرابط.';
	@override String get plexOnly => 'الرابطات المراقبة تدعم حاليا Plex الخوادم فقط.';
	@override String get unsupportedItem => 'يمكن مشاهدة الروابط فقط فتح عرض أو فيلم.';
	@override String get menuItem => 'مشاهدة الرابط';
	@override String get dialogTitle => 'مشاهدة الرابط';
	@override String get dialogShowHint => 'يفتح هذا الرابط يلعب الحلقة التالية.إضافة &mode=shuffle إلى النهاية للعب العرض على shuffle.';
	@override String get dialogMovieHint => 'فتح هذا الرابط يلعب الفيلم.';
	@override String get copy => 'نسخ';
	@override String get copied => 'Link نسخ';
}

// Path: homeLayout
class _Translations$homeLayout$ar extends Translations$homeLayout$en {
	_Translations$homeLayout$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'تخطيط الصفحة الرئيسية';
	@override String get resetToast => 'أُعيد تخطيط الصفحة الرئيسية إلى بانر Plezy الأصلي';
	@override String get resetHeroTitle => 'إعادة تخطيط البانر إلى إعداد Plezy الأصلي؟';
	@override String get resetHeroBody => 'يُوقف عرض كل الصفوف كبطاقات بارزة، ويُعيد البانر الدوّار الواحد إلى أعلى الصفحة الرئيسية كما كان سابقًا. يبقى ترتيب الصفوف وإعداد إظهارها كما هو.';
	@override String get removeRowTitle => 'إزالة صف من الصفحة الرئيسية؟';
	@override String removeRowBody({required Object title}) => 'سيُحذف ${title}. لا يمكن التراجع عن هذا الإجراء.';
	@override String get sync => 'مزامنة';
	@override String get syncAccountTitle => 'مزامنة التخطيط مع حساب Plex';
	@override String get syncAccountOn => 'مفعّل: يشارك هذا الجهاز ترتيب الصفوف والصفوف نفسها وإعدادات البطاقات البارزة والتنقّل التلقائي مع أجهزتك الأخرى.';
	@override String get syncAccountOff => 'متوقف: يحتفظ هذا الجهاز بتخطيطه الخاص.';
	@override String get syncNow => 'مزامنة الآن';
	@override String get plexHomeManager => 'إدارة الصفحة الرئيسية في Plex';
	@override String get managePlexRows => 'إدارة صفوف Plex في Plezy';
	@override String get managePlexRowsDescription => 'تنظيم الصفوف المختارة للصفحة الرئيسية';
	@override String get organizeHomeRows => 'تنظيم صفوف الصفحة الرئيسية';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} صفوف: نقل، بطاقة بارزة، تنقّل تلقائي، إزالة';
	@override String organizeLibraryRows({required Object library}) => 'تنظيم صفوف ${library}';
	@override String organizeLibraryRowsDescription({required Object n}) => 'متابعة المشاهدة و${n} صفوف: نقل، مكتبة، رئيسية، بطاقة بارزة، تنقّل تلقائي';
	@override String get renderAsHero => 'عرض كبطاقة بارزة';
	@override String get heroOnlySingleCollection => 'متاح فقط عندما يعرض هذا الصف عناوين مجموعة واحدة مباشرةً';
	@override String get hero => 'بطاقة بارزة';
	@override String get autoSlide => 'تنقّل تلقائي';
	@override String get autoSlideDescription => 'ينتقل أيضًا تلقائيًا كل بضع ثوانٍ. تعمل الأسهم على الكمبيوتر وأزرار الاتجاهات على التلفزيون دائمًا، وتعيد بدء المؤقّت.';
	@override String get autoSlideEditDescription => 'ينتقل أيضًا تلقائيًا كل بضع ثوانٍ. عند الإيقاف، يتنقّل فقط عند النقر على سهم في الكمبيوتر أو الضغط على اليمين أو اليسار في جهاز التحكم. تعمل الأسهم وأزرار الاتجاهات في الحالتين.';
	@override String get enableHeroFirst => 'فعّل البطاقة البارزة أولًا';
	@override String get showOnHome => 'إظهار في الصفحة الرئيسية';
	@override String get home => 'الرئيسية';
	@override String get removeFromHome => 'إزالة من الصفحة الرئيسية';
	@override String get selectRowsFirst => 'اختر صفوف الصفحة الرئيسية أدناه أولًا.';
	@override String plexManagedRows({required Object n}) => '${n} صفوف يديرها Plex';
	@override String get continueWatching => 'متابعة المشاهدة';
	@override String get continueWatchingLibraryDescription => 'صف استئناف المشاهدة الخاص بهذه المكتبة';
	@override String get continueWatchingHomeDescription => 'صف استئناف المشاهدة المعروض في الصفحة الرئيسية';
	@override String get nextUpHomeDescription => 'صف الحلقة التالية غير المشاهدة، ويظهر بشكل منفصل في الصفحة الرئيسية';
	@override String get library => 'المكتبة';
	@override String get showInRecommended => 'إظهار ضمن توصيات المكتبة';
	@override String get customPlexRow => 'صف Plex مخصّص';
	@override String get heroNeedsLibrary => 'حدّد المكتبة أولًا ليكون للبطاقة البارزة مكان تظهر فيه';
	@override String get heroNeedsSurface => 'حدّد المكتبة أو الصفحة الرئيسية أولًا ليكون للبطاقة البارزة مكان تظهر فيه';
	@override String get removeHub => 'إزالة قسم المحتوى';
	@override String get noPlexRows => 'لم يُرجع Plex أي صفوف يديرها لهذه المكتبة.';
	@override String get openDetails => 'فتح التفاصيل';
	@override String get heroCards => 'البطاقات البارزة';
	@override String get tapHeroCard => 'عند النقر على بطاقة بارزة';
	@override String get tvPlayFocus => 'جهاز التحكم: الانتقال إلى زر التشغيل';
	@override String get tvPlayFocusDescription => 'يتوقف التنقّل إلى الأسفل على زر التشغيل قبل الانتقال إلى الصف التالي. عند الإيقاف، ينتقل مباشرةً إلى الصف التالي.';
	@override String get tvWrap => 'جهاز التحكم: تكرار التنقّل بين البطاقات البارزة';
	@override String get tvWrapDescription => 'الضغط على اليسار عند البطاقة الأخيرة يعيدك إلى الأولى. عند إيقاف الخيار، يتوقف التنقل عند البطاقة الأخيرة. الضغط على اليمين عند البطاقة الأولى ينقلك دائمًا إلى الشريط الجانبي.';
	@override String get castOnHero => 'طاقم التمثيل في البطاقات البارزة';
	@override String get castOnHeroDescription => 'يعرض طاقم التمثيل أسفل البطاقة البارزة. عند الإيقاف، يظهر العنوان والملخّص فقط.';
	@override String get customRows => 'صفوف مخصّصة';
	@override String get loading => 'جارٍ تحميل تخطيط الصفحة الرئيسية…';
	@override String get noCustomRows => 'لا توجد صفوف مخصّصة بعد';
	@override String get addRowHint => 'اختر «إضافة صف إلى الرئيسية» لإنشاء صف.';
	@override String get addHomeRow => 'إضافة صف إلى الرئيسية';
	@override String get addHomeRowDescription => 'اختر فئة، وسيُضاف الصف الجديد إلى منظّم الصفوف تلقائيًا';
	@override String get removeRow => 'إزالة الصف';
	@override String get recentlyAdded => 'أُضيف مؤخرًا';
	@override String get recentlyReleased => 'صدر مؤخرًا';
	@override String get movieCollections => 'مجموعات الأفلام';
	@override String get showCollections => 'مجموعات المسلسلات';
	@override String get rowTitle => 'عنوان الصف';
	@override String get content => 'المحتوى';
	@override String get showThisRowIn => 'إظهار هذا الصف في:';
	@override String get libraryRecommended => 'توصيات المكتبة';
	@override String get heroCard => 'بطاقة بارزة';
	@override String get heroCardDescription => 'يعرض بطاقة دوّارة بعرض الشاشة بدلًا من صف الملصقات.';
	@override String get heroUnavailableDescription => 'متاح فقط عندما يعرض الصف عناوين مجموعة واحدة مباشرةً. عند اختيار أكثر من مجموعة، لا توجد مجموعة عناوين واحدة للتنقّل بينها.';
	@override String get librariesSelection => 'المكتبات (اتركها كلها دون تحديد لتضمين جميع المكتبات)';
	@override String get librariesMergedDescription => 'تُدمج كل المكتبات المحدّدة هنا في هذا الصف الواحد.';
	@override String get movieCollectionsSelection => 'مجموعات الأفلام (اتركها كلها دون تحديد لتضمين كل المجموعات في المكتبات المختارة)';
	@override String get showCollectionsSelection => 'مجموعات المسلسلات (اتركها كلها دون تحديد لتضمين كل المجموعات في المكتبات المختارة)';
	@override String get collectionRowsDescription => 'إذا طابقت مجموعة واحدة، تظهر عناوينها مباشرةً في الصف. وإذا طابقت عدة مجموعات، تظهر كل مجموعة كملصق واحد؛ انقر عليه لفتحها.';
	@override String get allCollections => 'كل المجموعات';
	@override String get noRowsHere => 'لا توجد صفوف هنا بعد.';
	@override String get hideWatchedRows => 'إخفاء العناصر المشاهدة من الصفوف';
	@override String get hideWatchedRowsDescription => 'تُزال العناوين التي شاهدتها بالكامل من صفوف الرئيسية وتوصيات المكتبة، وتبقى العناوين التي لا تزال تشاهدها.';
	@override String get untitledCollection => 'مجموعة بلا عنوان';
	@override String get moveRowHint => 'أعلى/أسفل: نقل الصف · اختيار: وضعه هنا · رجوع: إلغاء';
	@override String get organizeRowsHint => 'اختيار الصف أو الضغط المطوّل على اختيار: نقله · يمين/يسار: خيارات الصف · رجوع: إنهاء';
	@override String get layoutNavDescription => 'اختيار الصفوف والمكتبات وفئات المجموعات';
	@override String get editHomeRow => 'تعديل صف الصفحة الرئيسية';
	@override String get resetHeroButton => 'استعادة تخطيط بانر Plezy الأصلي';
	@override String get reorderingUnlocked => 'إعادة الترتيب متاحة';
	@override String get reorderingLocked => 'إعادة الترتيب مقفلة';
	@override String get rowsCanBeDragged => 'يمكن سحب الصفوف؛ انقر على القفل لمنع ذلك';
	@override String get tapLockToDrag => 'انقر على القفل لسحب الصفوف';
	@override String customRowLabel({required Object title}) => 'مخصّص: ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => 'إخفاء';
	@override String get remove => 'إزالة';
	@override String get libraryResumeRow => 'صف استئناف المشاهدة الخاص بهذه المكتبة';
	@override String get pressAgainToDelete => 'اضغط مرة أخرى للحذف';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => 'مفعّل';
	@override String get resetHeroButtonDescription => 'يُوقف عرض الصفوف كبطاقات بارزة، ويُعيد البانر الدوّار الواحد إلى الأعلى كما كان سابقًا. يبقى ترتيب الصفوف كما هو.';
}

// Path: platform
class _Translations$platform$ar extends Translations$platform$en {
	_Translations$platform$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'يتصل PlezyNG بخوادم الوسائط وأجهزة التشغيل على شبكتك المحلية.';
	@override String get locationPermission => 'يستخدم PlezyNG إذن الموقع عندما يتطلبه iOS للتعرف على شبكتك المحلية والاتصال بخوادم الوسائط.';
	@override String get photoLibraryPermission => 'اختر صورًا من مكتبة الصور لاستخدامها كصور للوسائط.';
	@override String get cameraPermission => 'امسح رموز QR لإقران جهاز تحكم مرافق.';
}

// Path: fileSources
class _Translations$fileSources$ar extends Translations$fileSources$en {
	_Translations$fileSources$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'الملفات والكتب';
	@override String get subtitle => 'اقرأ واستمع وشاهد من ملفاتك الخاصة.';
	@override String get add => 'إضافة مصدر';
	@override String get importFiles => 'استيراد ملفات';
	@override String get localFiles => 'على هذا الجهاز';
	@override String get source => 'المصدر';
	@override String get name => 'الاسم';
	@override String get endpoint => 'عنوان الخادم';
	@override String get root => 'المجلد أو بادئة المسار';
	@override String get username => 'اسم المستخدم';
	@override String get password => 'كلمة المرور';
	@override String get token => 'رمز API';
	@override String get accessKey => 'معرّف مفتاح الوصول';
	@override String get secretKey => 'مفتاح الوصول السري';
	@override String get sessionToken => 'رمز الجلسة (اختياري)';
	@override String get region => 'المنطقة';
	@override String get clientId => 'معرّف عميل OAuth';
	@override String get clientSecret => 'سر عميل OAuth (لـ Google على سطح المكتب فقط)';
	@override String get allowHttp => 'السماح باتصال HTTP غير المشفر على شبكة موثوقة';
	@override String get connect => 'اتصال';
	@override String get cancel => 'إلغاء';
	@override String get save => 'حفظ';
	@override String get close => 'إغلاق';
	@override String get removeSource => 'قطع اتصال المصدر';
	@override String get disconnectMessage => 'هل تريد قطع الاتصال بهذا المصدر؟ ستبقى الملفات المنزّلة وسجل القراءة والاستماع على هذا الجهاز.';
	@override String get localFolder => 'اختيار المجلد';
	@override String get empty => 'لا شيء هنا حتى الآن';
	@override String get emptyHint => 'أضف مصدرًا أو استورد كتابًا أو كتابًا صوتيًا أو موسيقى أو فيديو.';
	@override String get search => 'البحث في هذا المجلد';
	@override String get searchCached => 'البحث في المكتبة المحفوظة';
	@override String get refresh => 'تحديث';
	@override String get loadMore => 'تحميل المزيد';
	@override String get offline => 'متاح دون اتصال';
	@override String get download => 'حفظ للاستخدام دون اتصال';
	@override String get removeDownload => 'إزالة النسخة المحفوظة دون اتصال';
	@override String get continueReading => 'متابعة القراءة';
	@override String get continueListening => 'متابعة الاستماع';
	@override String get continueWatching => 'متابعة المشاهدة';
	@override String get read => 'قراءة';
	@override String get listen => 'الاستماع';
	@override String get play => 'تشغيل';
	@override String get pause => 'إيقاف مؤقت';
	@override String get stop => 'إيقاف';
	@override String get startOver => 'البدء من جديد';
	@override String get finished => 'مكتمل';
	@override String get markFinished => 'وضع علامة مكتمل';
	@override String get markUnfinished => 'وضع علامة غير مكتمل';
	@override String get editions => 'الإصدارات والملفات';
	@override String get chapters => 'الفصول';
	@override String get bookmarks => 'الإشارات المرجعية والملاحظات';
	@override String get bookmark => 'إضافة إشارة مرجعية';
	@override String get highlight => 'تمييز النص';
	@override String get note => 'ملاحظة';
	@override String get delete => 'حذف';
	@override String get export => 'تصدير الملاحظات';
	@override String get exported => 'تم تصدير الملاحظات';
	@override String get sync => 'مزامنة التقدم';
	@override String get synced => 'تمت مزامنة التقدم';
	@override String get conflict => 'موضع القراءة أو الاستماع مختلف على جهاز آخر. اختر الموضع الذي تريد المتابعة منه.';
	@override String get useLocal => 'استخدم هذا الجهاز';
	@override String get useRemote => 'استخدام موضع الجهاز الآخر';
	@override String get history => 'سجل المواضع';
	@override String get groupAudio => 'الاستماع ككتاب صوتي واحد';
	@override String get groupHint => 'يجمع الملفات الصوتية المحمّلة حاليًا في هذا المجلد. حمّل جميع الصفحات أولًا.';
	@override String get order => 'ترتيب الملفات';
	@override String get moveUp => 'تحرك إلى الأعلى';
	@override String get moveDown => 'تحرك إلى أسفل';
	@override String get speed => 'سرعة التشغيل';
	@override String get sleep => 'مؤقّت النوم';
	@override String get sleepOff => 'إيقاف';
	@override String get endChapter => 'نهاية الفصل';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} دقيقة',
		one: 'دقيقة',
		two: 'دقيقتان',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} دقائق',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} دقيقة',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} دقيقة',
	);
	@override String get skipBack => 'رجوع للخلف';
	@override String get skipForward => 'تقديم للأمام';
	@override String get smartRewind => 'الرجوع الذكي بعد الإيقاف المؤقت';
	@override String get playbackOptions => 'خيارات الاستماع';
	@override String remaining({required Object time}) => 'متبقٍ ${time}';
	@override String get contents => 'جدول المحتويات';
	@override String get readerSettings => 'إعدادات القراءة';
	@override String get fontSize => 'حجم النص';
	@override String get lineHeight => 'تباعد الأسطر';
	@override String get margin => 'الهوامش';
	@override String get font => 'نوع الخط';
	@override String get serif => 'خط ذو زوائد';
	@override String get sans => 'خط بلا زوائد';
	@override String get mono => 'خط ثابت العرض';
	@override String get columns => 'الأعمدة';
	@override String get scroll => 'التمرير عموديًا';
	@override String get justify => 'ضبط محاذاة النص';
	@override String get readerTheme => 'مظهر الصفحة';
	@override String get appTheme => 'اتباع سمة التطبيق';
	@override String get paper => 'الورق';
	@override String get sepia => 'بني فاتح';
	@override String get night => 'ليلي';
	@override String get readAloud => 'قراءة هذه الصفحة بصوت عالٍ';
	@override String get readAlong => 'متابعة القراءة مع الصوت';
	@override String get stopReading => 'إيقاف السرد';
	@override String get searchBook => 'البحث في الكتاب';
	@override String get noMatches => 'لا توجد نتائج مطابقة';
	@override String get previousPage => 'الصفحة السابقة';
	@override String get nextPage => 'الصفحة التالية';
	@override String page({required Object number}) => 'الصفحة ${number}';
	@override String get externalBlocked => 'يتم تعطيل الروابط الخارجية للكتاب في القارئ.';
	@override String get loading => 'فتح...';
	@override String get narrator => 'الراوي';
	@override String get audio => 'الصوت';
	@override String get video => 'فيديو';
	@override String get ebooks => 'كتب إلكترونية';
	@override String get all => 'الكل';
	@override String get downloads => 'الملفات المحفوظة دون اتصال';
	@override String get confirmDelete => 'هل تريد إزالة النسخة المحددة المحفوظة دون اتصال؟ سيبقى موضعك وملاحظاتك محفوظين.';
	@override String get errorAuthentication => 'سجّل الدخول مجددًا لإعادة الاتصال بهذا المصدر.';
	@override String get errorPermission => 'لم يمنح هذا المصدر إمكانية الوصول إلى الملف المطلوب.';
	@override String get errorUnavailable => 'المصدر غير متاح. حاول مجددًا أو افتح نسخة محفوظة دون اتصال.';
	@override String get errorUnsupported => 'هذه الصيغة أو طريقة الاتصال غير مدعومة على هذا الجهاز. راجع دليل إعداد المصدر.';
	@override String get errorInvalidData => 'لا يمكن قراءة هذا الملف أو استجابة الخادم بأمان.';
	@override String get errorCancelled => 'تم إلغاء العملية.';
	@override String get errorConflict => 'تغيّر الموضع في جلسة أخرى. أعد فتح العنصر لاختيار موضع المتابعة.';
	@override String get signIn => 'تسجيل الدخول';
	@override String get reconnect => 'إعادة الاتصال';
	@override String get folderHelp => 'اتركه فارغًا للبدء من جذر المصدر. تتضمن عناوين S3 اسم حاوية التخزين.';
	@override String get preferences => 'تفضيلات';
	@override String get timePosition => 'موضع التشغيل';
	@override String get audioTrack => 'المسار الصوتي';
	@override String get subtitleTrack => 'مسار الترجمة';
	@override String get none => 'لا شيء';
	@override String get fullscreen => 'ملء الشاشة';
	@override String get syncLocation => 'مجلد مزامنة التقدم (اختياري)';
	@override String get syncLocationHint => 'مجلد WebDAV مخصص لحالة PlezyNG. تُستخدم الكتابة المشروطة، وتبقى ملفات الوسائط دون تغيير.';
	@override String get audiobooks => 'كتب صوتية';
	@override String get comics => 'قصص مصوّرة';
	@override String get scan => 'البحث عن الكتب والوسائط';
	@override String get browserReader => 'فتح القارئ';
	@override String get browserReaderHelp => 'القارئ مفتوح في متصفحك. أبقِ PlezyNG مفتوحًا لحفظ موضعك وملاحظاتك.';
	@override String get on => 'تشغيل';
	@override String get advancedSetup => 'تسجيل التطبيق';
	@override String get microsoftSignIn => 'تسجيل الدخول باستخدام Microsoft';
	@override String get zoomIn => 'تكبير';
	@override String get zoomOut => 'تصغير';
	@override String get fitPage => 'ملاءمة الصفحة';
	@override String get fitWidth => 'ملاءمة العرض';
	@override String get actualSize => 'الحجم الأصلي';
	@override String get goToPage => 'الانتقال إلى صفحة';
	@override String get goToSection => 'الانتقال إلى فصل';
	@override String pageRange({required Object count}) => 'أدخل رقمًا من ١ إلى ${count}';
	@override String get pageLayout => 'تخطيط الصفحات';
	@override String get automatic => 'تلقائي';
	@override String get singlePage => 'صفحة واحدة';
	@override String get twoPages => 'صفحتان';
	@override String get readingDirection => 'اتجاه القراءة';
	@override String get leftToRight => 'من اليسار لليمين';
	@override String get rightToLeft => 'من اليمين لليسار';
	@override String get letterSpacing => 'تباعد الأحرف';
	@override String get wordSpacing => 'تباعد الكلمات';
	@override String get readerControlsHelp => 'استخدم إيماءة التكبير بإصبعين أو أزرار التكبير لتكبير الصفحات، واسحب لتحريكها. استخدم Ctrl/⌘ مع + أو − لضبط التكبير، وCtrl/⌘ مع 0 لإعادة ضبطه. استخدم Page Up وPage Down للتنقل بين الصفحات.';
	@override String get imagePage => 'صفحة قصة مصوّرة';
	@override String get resetReader => 'إعادة تعيين تفضيلات القراءة';
	@override String get zoom => 'التكبير';
	@override String get useFiles => 'استخدام الملفات والكتب';
	@override String get cancelScan => 'إلغاء الفحص';
	@override String get googleDrive => 'Google Drive';
}

// Path: lending
class _Translations$lending$ar extends Translations$lending$en {
	_Translations$lending$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'المكتبات العامة';
	@override String get add => 'إضافة مكتبة';
	@override String get other => 'مكتبة أخرى';
	@override String get libraryName => 'اسم المكتبة';
	@override String get libraryUrl => 'موقع المكتبة';
	@override String get libraryUrlHint => 'استخدم صفحة فهرس مكتبتك أو صفحة تسجيل الدخول.';
	@override String get intro => 'استعر من مكتبتك واحتفظ بكتبك في متناولك.';
	@override String get handoff => 'سجّل الدخول واستعر واقرأ بأمان عبر خدمة مكتبتك نفسها.';
	@override String get openService => 'فتح المكتبة';
	@override String get findLibrary => 'العثور على مكتبة';
	@override String get search => 'البحث عن كتب ومؤلفين';
	@override String get catalogue => 'الفهرس';
	@override String get loans => 'الاستعارات';
	@override String get holds => 'الحجوزات';
	@override String get signIn => 'تسجيل الدخول عبر مكتبتك';
	@override String get waiting => 'أكمل تسجيل الدخول في المتصفح، ثم عُد إلى هنا.';
	@override String get cancel => 'إلغاء';
	@override String get disconnect => 'إزالة المكتبة';
	@override String get disconnectMessage => 'هل تريد إزالة هذه المكتبة من هذا الملف الشخصي؟ ستبقى استعاراتك وحجوزاتك لدى المكتبة.';
	@override String get getBook => 'الحصول على الكتاب';
	@override String get checkAvailability => 'التحقق من التوفر';
	@override String get available => 'متاح للاستعارة';
	@override String get unavailable => 'غير متاح حاليًا';
	@override String get borrow => 'استعارة';
	@override String get placeHold => 'حجز';
	@override String get returnBook => 'إرجاع مبكر';
	@override String get cancelHold => 'إلغاء الحجز';
	@override String get confirmBorrow => 'هل تريد استعارة هذا العنوان من مكتبتك؟';
	@override String get confirmReturn => 'هل تريد إرجاع هذا العنوان الآن؟ قد تحتاج إلى استعارته مجددًا للمتابعة.';
	@override String get confirmCancelHold => 'هل تريد إلغاء حجزك لهذا العنوان؟';
	@override String get email => 'البريد الإلكتروني لإشعارات الحجز';
	@override String due({required Object date}) => 'موعد الإرجاع: ${date}';
	@override String queue({required Object position}) => 'ترتيبك في قائمة الانتظار: ${position}';
	@override String get empty => 'لا توجد عناوين هنا بعد.';
	@override String get openLibraryNote => 'استكشف فهرس Open Library. تظهر خيارات القراءة والاستعارة في صفحة كل عنوان.';
	@override String get more => 'تحميل المزيد';
	@override String get gateway => 'خدمة تسجيل الدخول إلى المكتبة';
	@override String get gatewayHint => 'توفرها مكتبتك أو مسؤول PlezyNG.';
	@override String get advanced => 'تكامل المكتبة';
	@override String get loadLibraries => 'اختيار مكتبتك';
	@override String get expired => 'انتهت مدة هذه الاستعارة.';
	@override String get updated => 'تم تحديث المكتبة';
	@override String get continueService => 'المتابعة في الخدمة';
	@override String get comingSoon => 'الاستعارة داخل التطبيق · قريبًا';
	@override String get comingSoonDescription => 'تكامل Libby قادم قريبًا. يمكنك استخدام مكتبتك في Libby بينما نكمل الربط.';
	@override String get suspendHold => 'تعليق الحجز';
	@override String get resumeHold => 'استئناف الحجز';
	@override String get suspendMessage => 'هل تريد الاحتفاظ بترتيبك في قائمة الانتظار والسماح للقارئ التالي باستعارة هذه النسخة؟ يمكنك استئناف الحجز لاحقًا.';
	@override String get resumeMessage => 'هل تريد استئناف هذا الحجز لتعرض عليك المكتبة النسخة التالية المتاحة؟';
	@override String get editEmail => 'تغيير البريد الإلكتروني للإشعارات';
}

// Path: audiobook
class _Translations$audiobook$ar extends Translations$audiobook$en {
	_Translations$audiobook$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get syncTitle => 'القراءة والاستماع Sync';
	@override String get syncHelp => 'الحفاظ على مواقف القراءة، ومواقف الاستماع، وحالة الانتهاء، والملاحظات والملاحظات عبر أجهزتك.اختر حساب التخزين المرفق واستخدم نفس رمز المزامنة على كل جهاز.';
	@override String get addSyncSource => 'إضافة Google Drive، OneDrive، Dropbox، WebDAV أو S3 في الملفات والكتب أولاً.';
	@override String get syncDestination => 'حساب التخزين المتزامن';
	@override String get syncFolder => 'المجلد أو المجلد السابق';
	@override String get syncFolderHelp => 'استخدم مجلدًا منفصلًا موجودًا داخل مصدر WebDAV الخاص بك، أو مقدمة S3 مخصصة.';
	@override String get syncCode => 'رمز المزامنة الخاص';
	@override String get syncCodeHelp => 'قم بإنشاء رمز على جهازك الأول، ثم أدخل هذا الرمز على أجهزتك الأخرى.حافظ على نسخة خاصة: هو المفتاح للحالة المشفرة الخاصة بك.استخدم رمزًا مختلفًا لكل شخص.';
	@override String get showCode => 'عرض أو إخفاء رمز التزامن';
	@override String get newSyncCode => 'إنشاء رمز مزامنة جديد';
	@override String get saveSync => 'حفظ وتزامن';
	@override String get disableSync => 'قم بإيقاف تشغيل Sync على هذا الجهاز';
	@override String get syncSourceDisconnect => 'إزالة هذا المصدر سيتم إيقاف القراءة والاستماع المزامنة هنا.';
	@override String get syncReconnect => 'إعادة توصيل حساب التخزين';
	@override String lastSynced({required Object time}) => 'آخر تصنيف في ${time}';
	@override String get syncPrivacy => 'يتم تخزين التقدم المشفر والملاحظات فقط. لا يتم تحميل ملفات الصوت والكتب الإلكترونية والرموز الحساب وكلمات المرور. يستخدم Google Drive و OneDrive تخزين التطبيقات؛ يستخدم Dropbox PlezyNG Sync. يسمح التزامن قد يطلب إضافية إمكانية الوصول إلى الكتابة. في حين تم تشغيله، هذا الوجهة يمتلك التقدم التزامن؛ يبقى التقدم الخادم منفصلة. يمنع التزامن يحافظ على التاريخ المحلي والحالة البعيدة.';
	@override String get syncConflicts => 'اقرأ أين تستعيد';
	@override String get conflictHelp => 'تم إجراء هذه التغييرات بشكل مستقل.اختر الموقف أو نسخة علامة التبويب للحفاظ عليها. لا تفوز تلقائيًا بضعة ساعات متأخرة أو نسبة أعلى.';
	@override String syncDevice({required Object device}) => 'جهاز ${device}';
	@override String get syncUnknownDevice => 'جهاز غير معروف';
	@override String get deletedBookmark => 'إلغاء الكتابة';
	@override String get finished => 'الانتهاء';
	@override String readingPosition({required Object percent}) => 'قراءة · ${percent}%';
	@override String get chapterTimeline => 'الفصل التقدم';
	@override String get bookTimeline => 'كتاب التقدم الكامل';
	@override String bookRemaining({required Object time}) => 'الوقت المتبقي في هذا الكتاب: ${time}';
	@override String chapterRemaining({required Object time}) => 'الوقت المتبقي في هذا الفصل: ${time}';
	@override String get unknownRemaining => 'إجمالي الوقت المتاحة كما يتم لعب الأجزاء';
	@override String get undoSeek => 'آخر البحث';
	@override String get customSpeed => 'سرعة اللعب المخصصة';
	@override String get speedHelp => 'اختر سرعة تتراوح بين 0.25 × إلى 4 ×.';
	@override String get apply => 'تطبيق';
	@override String get customSleep => 'ساعات النوم المخصصة';
	@override String get sleepMinutes => 'الدقائق (1 – 1440)';
	@override String sleepChapters({required Object count}) => 'توقف بعد ${count} الفصول';
	@override String get extendSleep => 'إضافة 5 دقائق';
	@override String sleepRemaining({required Object time}) => 'موعد النوم: ${time}';
	@override String get useDefaults => 'استخدم هذه التحكمات الاستماعية للكتب الجديدة';
	@override String get librarySort => 'الكتب المختلفة';
	@override String get sortTitle => 'العنوان';
	@override String get sortAuthor => 'الكاتب';
	@override String get sortNarrator => 'القارئ';
	@override String get sortSeries => 'سلسلة الأوامر';
	@override String get sortRecent => 'افتتح مؤخرا';
	@override String get statusFilter => 'حالة القراءة';
	@override String get statusAll => 'جميع الكتب';
	@override String get statusNew => 'لم يبدأ';
	@override String get statusProgress => 'في التقدم';
	@override String get statusFinished => 'الانتهاء';
	@override String get goToTime => 'اذهب إلى الزمن';
	@override String get timeHelp => 'ساعات: دقائق: ثواني، أو دقائق: ثواني';
}

// Path: appIcon.names
class _Translations$appIcon$names$ar extends Translations$appIcon$names$en {
	_Translations$appIcon$names$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get midnight => 'منتصف الليل';
	@override String get ember => 'الناس';
	@override String get paper => 'الورق';
	@override String get oled => 'OLED';
	@override String get line => 'الخطوط';
	@override String get ocean => 'المحيط';
	@override String get ultraviolet => 'فوق بنفسجي';
	@override String get matcha => 'ماتشا';
	@override String get sunset => 'الشمس';
	@override String get gold => 'الذهب';
	@override String get titanium => 'التيتانيوم';
	@override String get glass => 'الزجاج';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => 'الموجة';
	@override String get pixel => 'بيكسل';
	@override String get neon => 'نينوى';
	@override String get sticker => 'ملصق';
	@override String get ticket => 'تذاكر';
	@override String get pop => 'بوب';
	@override String get strata => 'الشارع';
	@override String get facet => 'الوجه';
	@override String get tilde => 'تيلد';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$ar extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

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
class _Translations$common$mediaKind$ar extends Translations$common$mediaKind$en {
	_Translations$common$mediaKind$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get movie => 'فيلم';
	@override String get show => 'عرض';
	@override String get season => 'الموسم';
	@override String get episode => 'حلقة';
	@override String get artist => 'فنان';
	@override String get album => 'ألبوم';
	@override String get track => 'مسار';
	@override String get collection => 'مجموعة';
	@override String get playlist => 'قائمة التشغيل';
	@override String get clip => 'مقطع';
	@override String get photo => 'صورة';
	@override String get folder => 'مجلد';
}

// Path: themeEditor.slots
class _Translations$themeEditor$slots$ar extends Translations$themeEditor$slots$en {
	_Translations$themeEditor$slots$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get bg => 'الخلفية';
	@override String get surface => 'السطح';
	@override String get outline => 'الخروج';
	@override String get text => 'النص';
	@override String get textMuted => 'النص الثانوي';
	@override String get accent => 'التركيز';
}

// Path: themeEditor.contrast
class _Translations$themeEditor$contrast$ar extends Translations$themeEditor$contrast$en {
	_Translations$themeEditor$contrast$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => 'النص على الخلفية';
	@override String get textOnSurface => 'النص على السطح';
	@override String get textMutedOnBg => 'النص الثانوي على الخلفية';
	@override String get textMutedOnSurface => 'النص الثانوي على السطح';
	@override String get accentOnBg => 'التركيز على الخلفية';
	@override String get accentOnSurface => 'التركيز على السطح';
	@override String get labelOnAccent => 'علامة الزر على التركيز';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$ar extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'لعبة / استراحة';
	@override String get volumeUp => 'حجم الأعلى';
	@override String get volumeDown => 'حجم أسفل';
	@override String seekForward({required Object seconds}) => 'البحث إلى الأمام (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'البحث عن الخلفية (${seconds}s)';
	@override String get fullscreenToggle => 'انضم إلى الشاشة الكاملة';
	@override String get muteToggle => 'الموت معاً';
	@override String get subtitleToggle => 'أضف تعليق حول Subtitles';
	@override String get audioTrackNext => 'المقالة القادمةأودي تريك';
	@override String get subtitleTrackNext => 'التالي Subtitle Track';
	@override String get chapterNext => 'الفصل التالي';
	@override String get chapterPrevious => 'الفصل السابق';
	@override String get episodeNext => 'الحلقة التالية';
	@override String get episodePrevious => 'الحلقة السابقة';
	@override String get speedIncrease => 'زيادة السرعة';
	@override String get speedDecrease => 'انخفاض السرعة';
	@override String get speedReset => 'إعادة سرعة';
	@override String get zoomIn => 'زوم في';
	@override String get zoomOut => 'زوم الخروج';
	@override String get zoomReset => 'إعادة تشغيل Zoom';
	@override String get subSeekNext => 'البحث عن الموضوع التالي';
	@override String get subSeekPrev => 'البحث عن العنوان السابق';
	@override String get subtitleDelayIncrease => 'تأخير أسماء';
	@override String get subtitleDelayDecrease => 'التقدم تحت عنوان';
	@override String get shaderToggle => 'اشترك في الظلال';
	@override String get skipMarker => 'إدخال / الائتمان';
	@override String get screenshot => 'أخذ شاشة';
	@override String get framePrevious => 'الإطار السابق';
	@override String get frameNext => 'التالي إطار';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$ar extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'مطلوب Android 8.0 أو أحدث';
	@override String get iosVersion => 'مطلوب iOS 15.0 أو أحدث';
	@override String get permissionDisabled => 'تم تعطيل صورة في صورة، وتتمكن من ذلك في إعدادات النظام.';
	@override String get notSupported => 'الجهاز لا يدعم وضع الصورة في الصورة';
	@override String get voSwitchFailed => 'فشل في تحويل إخراج الفيديو إلى صورة في صورة';
	@override String get failed => 'صورة في الصورة فشلت في البدء';
	@override String get prepareFailed => 'لا يمكن إعداد صورة في الصورة';
	@override String unknown({required Object error}) => 'حدث خطأ: ${error}';
}

// Path: accountPreferences.groups
class _Translations$accountPreferences$groups$ar extends Translations$accountPreferences$groups$en {
	_Translations$accountPreferences$groups$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => 'الأصوات و الأصوات';
	@override String get libraryDisplay => 'المكتبة';
	@override String get personalMedia => 'وسائل الإعلام الشخصية';
}

// Path: accountPreferences.subtitleModes
class _Translations$accountPreferences$subtitleModes$ar extends Translations$accountPreferences$subtitleModes$en {
	_Translations$accountPreferences$subtitleModes$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get none => 'اختياري يدويا';
	@override String get noneDescription => 'لا تحول أبداً العناوين الخاصة بك.';
	@override String get defaultMode => 'اتبع العلم المقطع';
	@override String get defaultModeDescription => 'استخدم الأعلام الافتراضية والقسرية المخزنة على كل مسار تحت عنوان.';
	@override String get always => 'إمكانية دائما';
	@override String get alwaysDescription => 'قم بتحريك مسار العنوان الفرعي في اللغة المفضلة في كل مرة يوجد فيها.';
	@override String get onlyForced => 'مجرد العناوين القسرية';
	@override String get onlyForcedDescription => 'تحميل فقط المسارات المحددة كإجبار.';
	@override String get smart => 'عرض مع الصوت الأجنبي';
	@override String get smartDescription => 'تحويل العناوين الفرعية فقط عندما يكون الصوت في لغة أخرى.';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class _Translations$accountPreferences$subtitleAccessibilityOptions$ar extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	_Translations$accountPreferences$subtitleAccessibilityOptions$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'أضف تعليق حول غير SDH subtitles';
	@override String get preferSdh => 'أولاً: أحب أرقام SDH';
	@override String get onlySdh => 'مجرد عناوين SDH';
	@override String get onlyNonSdh => 'مجرد أسماء غير SDH';
}

// Path: accountPreferences.forcedSubtitleOptions
class _Translations$accountPreferences$forcedSubtitleOptions$ar extends Translations$accountPreferences$forcedSubtitleOptions$en {
	_Translations$accountPreferences$forcedSubtitleOptions$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => 'أولاً: عدم إجبار العناوين';
	@override String get preferForced => 'تفضيل القواعد القسرية';
	@override String get onlyForced => 'مجرد العناوين القسرية';
	@override String get onlyNonForced => 'فقط العناوين غير القسرية';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$ar extends Translations$accountPreferences$watchedIndicatorOptions$en {
	_Translations$accountPreferences$watchedIndicatorOptions$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get none => 'أبدًا';
	@override String get moviesAndShows => 'الأفلام والتلفزيون';
	@override String get movies => 'الأفلام فقط';
	@override String get shows => 'عرض التلفزيون فقط';
}

// Path: accountPreferences.mediaReviewsOptions
class _Translations$accountPreferences$mediaReviewsOptions$ar extends Translations$accountPreferences$mediaReviewsOptions$en {
	_Translations$accountPreferences$mediaReviewsOptions$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'المستخدمين والنقاد';
	@override String get usersOnly => 'المستخدمين فقط';
	@override String get criticsOnly => 'انتقادات فقط';
	@override String get nobody => 'مخفية';
}

// Path: discover.findNext
class _Translations$discover$findNext$ar extends Translations$discover$findNext$en {
	_Translations$discover$findNext$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'العثور على التالي';
	@override String get open => 'العثور على التالي';
	@override String get anyTime => 'أي وقت';
	@override String get timeAvailable => 'كم من الوقت لديك؟';
	@override String get filters => 'واختر اللحظة';
	@override String get watch => 'مشاهدة';
	@override String get listen => 'الاستماع';
	@override String get read => 'قراءة';
	@override String finishable({required Object duration}) => 'انتهاء في ${duration}';
	@override String aboutDuration({required Object duration}) => 'حول ${duration}';
	@override String nextUnit({required Object duration}) => 'الفصل التالي · ${duration}';
	@override String totalDuration({required Object duration}) => '${duration} كاملة';
	@override String get timingVaries => 'التوقيت يختلف';
	@override String get notNow => 'لا الآن';
	@override String get swipeHint => 'تحريك أو استخدام الأزرار أدناه';
	@override String get saved => 'النقابات المحفوظة';
	@override String savedCount({required Object count}) => 'كلمات متعلقة ${count}';
	@override String get undo => 'وواو';
	@override String get details => 'تفاصيل';
	@override String get noPicks => 'لا شيء يختاره حتى الآن';
	@override String get noPicksHint => 'قم بتوصيل مكتبة أو إضافة مصدر وسائل الإعلام للبدء.';
	@override String get noMatches => 'لا شيء يناسب هذه اللحظة';
	@override String get noMatchesHint => 'حاول تنسيق آخر أو أعط نفسك المزيد من الوقت.';
	@override String get allDone => 'أنتم جميعا تم القبض عليكم';
	@override String get allDoneHint => 'ابدأ مزيجًا جديدًا لرؤية هذه الخيارات مرة أخرى.';
	@override String get refresh => 'العثور على مزيج آخر';
	@override String sourceReason({required Object source}) => 'من ${source}';
	@override String libraryReason({required Object library}) => 'من ${library}';
	@override String get ownedReason => 'من مكتبتك';
	@override String get liveNow => 'على الآن';
	@override String get watchLive => 'مشاهدة live';
	@override String get filterAnything => 'كل شيء';
	@override String get filterWatch => 'مشاهدة';
	@override String get filterListen => 'الاستماع';
	@override String get filterRead => 'قراءة';
	@override String get twentyMinutes => '20 دقيقة';
	@override String get fortyFiveMinutes => '45 دقيقة';
	@override String get ninetyMinutes => '90 دقيقة';
	@override String get apply => 'تطبيق';
	@override String get openFailed => 'هذا الخيار لم يعد متاحا.تجديد للتحقق مرة أخرى.';
	@override String get changeFailed => 'لا أستطيع أن أحفظ هذا التغيير، حاول مرة أخرى.';
	@override String get savedLimit => 'النقاط التي تم حفظها كاملة.إزالة اختيار واحد لإنقاذ آخر.';
}

// Path: discover.person
class _Translations$discover$person$ar extends Translations$discover$person$en {
	_Translations$discover$person$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get born => 'ولدت';
	@override String get died => 'الموت';
	@override String get birthplace => 'مكان الميلاد';
	@override String dateWithAge({required Object date, required Object age}) => '${date} (العمر ${age})';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (العمر ${age})';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$ar extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'الموصى بها';
	@override String get browse => 'استعراض';
	@override String get collections => 'المجموعات';
	@override String get playlists => 'قوائم التشغيل';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$ar extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'مجموعة';
	@override String get all => 'الكل';
	@override String get movies => 'الأفلام';
	@override String get shows => 'مسلسلات تلفزيونية';
	@override String get seasons => 'المواسم';
	@override String get episodes => 'الحلقات';
	@override String get artists => 'الفنانون';
	@override String get albums => 'الألبومات';
	@override String get tracks => 'المسارات';
	@override String get folders => 'المجلدات';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$ar extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get genre => 'النوع';
	@override String get year => 'السنة';
	@override String get contentRating => 'تصنيف المحتوى';
	@override String get tag => 'وسم';
	@override String get unwatched => 'غير ملاحظة';
	@override String get unplayed => 'غير مُشغّل';
	@override String get favorites => 'المفضلة';
	@override String get filePath => 'مسار الملفات';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$ar extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'العنوان';
	@override String get dateAdded => 'تاريخ الإضافة';
	@override String get releaseDate => 'تاريخ الإصدار';
	@override String get rating => 'تصنيف';
	@override String get communityRating => 'تقييم المجتمع';
	@override String get criticRating => 'التصنيف الحرص';
	@override String get userRating => 'تصنيف المستخدم';
	@override String get datePlayed => 'تاريخ التشغيل';
	@override String get playCount => 'عدد مرات التشغيل';
	@override String get productionYear => 'سنة الإنتاج';
	@override String get runtime => 'مدة التشغيل';
	@override String get officialRating => 'التصنيف الرسمي';
	@override String get premiereDate => 'تاريخ العرض الأول';
	@override String get startDate => 'تاريخ البدء';
	@override String get airTime => 'وقت العرض';
	@override String get studio => 'الاستوديو';
	@override String get random => 'عشوائي';
	@override String get dateShared => 'التاريخ المشترك';
	@override String get latestEpisodeAirDate => 'آخر الحلقة تاريخ الهواء';
	@override String get lastEpisodeDateAdded => 'الحلقة الأخيرة إضافات';
	@override String get dateDownloaded => 'تاريخ تنزيل';
	@override String get size => 'الحجم';
	@override String get library => 'المكتبة';
}

// Path: libraries.advancedFilters
class _Translations$libraries$advancedFilters$ar extends Translations$libraries$advancedFilters$en {
	_Translations$libraries$advancedFilters$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get include => 'إدراج';
	@override String get exclude => 'استبعاد';
	@override String get any => 'أي';
	@override String get yes => 'نعم';
	@override String get no => 'لا';
	@override String not({required Object value}) => 'لا ${value}';
	@override String valueCount({required Object count}) => '${count} تم اختيارها';
	@override String valueCountExcluded({required Object count}) => '${count} استبعاد';
	@override String get searchValues => 'قيمة البحث';
	@override String get noValues => 'لا قيمة';
	@override String get matchContains => 'حاوية';
	@override String get matchNotContains => 'لا يحتوي على';
	@override String get matchIs => 'هو';
	@override String get matchIsNot => 'لا يوجد';
	@override String get matchBeginsWith => 'يبدأ مع';
	@override String get matchEndsWith => 'تنتهي مع';
	@override String get textHint => 'النوع إلى المطابقة';
	@override String get from => 'من';
	@override String get to => 'إلى';
	@override String range({required Object from, required Object to}) => '${from} إلى ${to}';
	@override String atLeast({required Object value}) => '${value} وأعلى';
	@override String atMost({required Object value}) => 'تصل إلى ${value}';
	@override String dateLastDays({required Object count}) => 'آخر ${count} أيام';
	@override String get dateLastYear => 'العام الماضي';
	@override String dateOlderThanDays({required Object count}) => 'أقدم من ${count} أيام';
	@override String get dateOlderThanYear => 'أكبر من سنة واحدة';
}

// Path: libraries.selection
class _Translations$libraries$selection$ar extends Translations$libraries$selection$en {
	_Translations$libraries$selection$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get selectItems => 'اختيار العناصر';
	@override String selectedCount({required Object count}) => '${count} تم اختيارها';
	@override String get actions => 'إجراءات الاختيار';
	@override String get confirmDescendants => 'هذا يغير جميع الحلقات في العروض والموسم المحدد.';
	@override String get confirmUnwatched => 'يؤدي هذا أيضًا إلى مسح تقدّم التشغيل للعناصر المحددة.';
	@override String confirmCount({required Object count}) => 'العناصر المختارة: ${count}.';
	@override String completed({required Object count}) => 'تحديث العناصر: ${count}.';
	@override String partialFailure({required Object succeeded, required Object failed}) => 'تحديث ${succeeded}؛ فشل ${failed}. لا تزال العناصر المفقودة مختارة.';
}

// Path: explore.mdblistShelves
class _Translations$explore$mdblistShelves$ar extends Translations$explore$mdblistShelves$en {
	_Translations$explore$mdblistShelves$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get manage => 'البحث عن المراحيض';
	@override String get manageDescription => 'اختيار وترتيب القوائم من حسابك MDBList';
	@override String get description => 'اختر قوائم الأفلام والتلفزيون العامة من حسابك MDBList.إنشاء أو نسخ القوائم على MDBList, ثم تجديد.';
	@override String get selected => 'المراحيض المختارة';
	@override String get available => 'قائمة الحسابات المتاحة';
	@override String get noLists => 'لا يتم إرجاع أي أفلام عامة أو قوائم تلفزيونية.إنشاء أو نسخ قائمة على MDBList، ثم تحديث.';
	@override String get displayName => 'اسم شاشة Shelf';
	@override String get nameHint => 'اترك فارغا لاستخدام اسم قائمة المصدر.';
	@override String get add => 'إضافة شيلف';
	@override String get save => 'احفظ السترات';
	@override String moveUp({required Object title}) => 'تحريك ${title} إلى الأعلى';
	@override String moveDown({required Object title}) => 'تحريك ${title} إلى أسفل';
	@override String get unavailable => 'هذه القائمة غير متوفرة.إزالة أو إزالة الستار في الإعدادات.';
	@override String get rateLimited => 'MDBList حد الطلب قد وصل، يرجى الانسحاب في وقت لاحق.';
	@override String get loadFailed => 'لا يمكن تحميل الشرائح.تحقق من الاتصال الخاص بك والانسحاب.';
	@override String get saveFailed => 'لا أستطيع أن أحفظ الستائر، يرجى التراجع.';
	@override String get accountChanged => 'تم تغيير حسابك أو ملفك الشخصي.إعادة فتح هذه الإعدادات.';
	@override String get settingsUnreadable => 'لا يمكن قراءة الشرائح المحفوظة.اختر القوائم مرة أخرى لاستبدال هذه الإعدادات.';
}

// Path: explore.rows
class _Translations$explore$rows$ar extends Translations$explore$rows$en {
	_Translations$explore$rows$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'قائمة مراقبة';
	@override String get recommendedMovies => 'الأفلام الموصى بها';
	@override String get recommendedShows => 'العروض الموصى بها';
	@override String get trendingMovies => 'أفلام متطورة';
	@override String get trendingShows => 'عرض الاتجاهات';
	@override String get popularMovies => 'أفلام شعبية';
	@override String get popularShows => 'العروض الشعبية';
	@override String get trendingAnime => 'انيمات الاتجاهات';
	@override String get suggestedAnime => 'انيمو الموصى بها';
	@override String get airingAnime => 'أعلى الهواء Anime';
	@override String get popularAnime => 'الأنيمي الأكثر شعبية';
	@override String get trending => 'الاتجاهات';
	@override String get upcomingMovies => 'الأفلام القادمة';
	@override String get upcomingShows => 'العروض القادمة';
}

// Path: explore.status
class _Translations$explore$status$ar extends Translations$explore$status$en {
	_Translations$explore$status$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get airing => 'الهواء';
	@override String get ended => 'انتهى';
	@override String get canceled => 'إلغاء';
	@override String get upcoming => 'التالي';
}

// Path: explore.badge
class _Translations$explore$badge$ar extends Translations$explore$badge$en {
	_Translations$explore$badge$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} شعبية';
	@override String rankAiring({required Object n}) => '#${n} الهواء';
	@override String rankRated({required Object n}) => '#${n} تقييم';
	@override String rankTrending({required Object n}) => '#${n} الاتجاهات';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} في ${season}';
	@override String watchingNow({required Object n}) => '${n} مشاهدة';
	@override String get available => 'متاح';
	@override String get partiallyAvailable => 'المتاحة جزئيا';
	@override String get availableIn4k => '4K متوفر';
	@override String get requested => 'المطالبة';
	@override String get pendingApproval => 'الموافقة المتوقعة';
	@override String get processing => 'المعالجة';
	@override String get declined => 'انخفاض';
	@override String get requestFailed => 'طلب فشل';
	@override String get requested4k => '4K طلب';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} الموسم';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => 'Ep ${episode} في ${duration}';
	@override String nextAiringIn({required Object duration}) => 'التالي في ${duration}';
	@override String episodesShort({required Object n}) => '${n} إبس';
	@override String minutesPerEpisode({required Object n}) => '${n} دقيقة/أب';
	@override String get adult => '18+';
}

// Path: explore.stats
class _Translations$explore$stats$ar extends Translations$explore$stats$en {
	_Translations$explore$stats$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} مكتوبة';
	@override String viewersDay({required Object n}) => '${n} مشاهدة اليوم';
	@override String viewersWeek({required Object n}) => '${n} مشاهدة هذا الأسبوع';
	@override String viewersMonth({required Object n}) => '${n} مشاهدة هذا الشهر';
	@override String viewersYear({required Object n}) => '${n} مشاهدة هذا العام';
	@override String viewersAllTime({required Object n}) => '${n} المشاهدين';
	@override String planning({required Object n}) => '${n} التخطيط لمشاهدة';
	@override String favorited({required Object n}) => '${n} المفضلة';
	@override String dropRate({required Object percent}) => '${percent} ألغيت';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} تعليق',
		one: 'تعليق واحد',
		two: 'تعليقان',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} تعليقات',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} تعليق',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} تعليق',
	);
	@override String votes({required Object n}) => '${n} صوت';
	@override String watching({required Object n}) => '${n} مشاهدة';
	@override String completed({required Object n}) => '${n} إكمال';
	@override String onHold({required Object n}) => '${n} على الحصن';
	@override String dropped({required Object n}) => '${n} انخفاض';
}

// Path: explore.season
class _Translations$explore$season$ar extends Translations$explore$season$en {
	_Translations$explore$season$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get winter => 'الشتاء';
	@override String get spring => 'الربيع';
	@override String get summer => 'الصيف';
	@override String get fall => 'سقوط';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class _Translations$explore$format$ar extends Translations$explore$format$en {
	_Translations$explore$format$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get tv => 'تلفاز';
	@override String get tvShort => 'التلفزيون القصير';
	@override String get movie => 'فيلم';
	@override String get special => 'خاصة';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => 'الموسيقى';
	@override String get other => 'أخرى';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$ar extends Translations$explore$sourceMaterial$en {
	_Translations$explore$sourceMaterial$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get original => 'الأصلي';
	@override String get manga => 'مانغا';
	@override String get lightNovel => 'الضوء رواية';
	@override String get novel => 'روائي';
	@override String get visualNovel => 'الرواية البصرية';
	@override String get game => 'لعبة';
	@override String get webComic => 'WEB الكوميديا';
	@override String get musicRelease => 'الموسيقى';
	@override String get otherMedia => 'أخرى';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$ar extends Translations$explore$creditRole$en {
	_Translations$explore$creditRole$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get actor => 'ممثل';
	@override String get director => 'المخرج';
	@override String get writer => 'الكاتب';
	@override String get producer => 'المنتج';
	@override String get creator => 'المنشئ';
	@override String get composer => 'الملحن';
}

// Path: explore.relation
class _Translations$explore$relation$ar extends Translations$explore$relation$en {
	_Translations$explore$relation$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get prequel => 'البروتوكول';
	@override String get sequel => 'السلسلة';
	@override String get sideStory => 'قصة الجانب';
	@override String get spinOff => 'عمل مشتق';
	@override String get alternativeVersion => 'النسخة البديلة';
	@override String get summary => 'ملخص';
	@override String get parentStory => 'قصة الوالدين';
	@override String get adaptation => 'التكيف';
	@override String get other => 'مرتبطة';
}

// Path: explore.detail
class _Translations$explore$detail$ar extends Translations$explore$detail$en {
	_Translations$explore$detail$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'العنوان الأصلي';
	@override String get alsoKnownAs => 'المعروف أيضًا باسم';
	@override String get studios => 'الاستوديوهات';
	@override String get country => 'البلد';
	@override String get language => 'اللغة';
	@override String get released => 'إطلاق سراح';
	@override String get physicalRelease => 'على القرص';
	@override String get ended => 'انتهى';
	@override String addedOn({required Object date}) => 'أضيف ${date}';
	@override String get yourRating => 'تصنيفك';
	@override String get budget => 'الميزانية';
	@override String get revenue => 'مكتب البوكس';
	@override String get contentAdvisory => 'العمر التوجيه';
	@override String get tags => 'الوسوم';
	@override String get revealSpoilerTags => 'عرض العلامات spoiler';
	@override String get links => 'اليمين';
	@override String get watchOn => 'انظر إلى';
	@override String get watchTrailer => 'مشاهدة trailer';
	@override String openOn({required Object site}) => 'مفتوحة على ${site}';
	@override String get crew => 'الطاقم';
	@override String get ratings => 'تصنيف';
	@override String get schedule => 'جدولة';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: 'لا توجد توصيات من المستخدمين',
		one: 'أوصى به مستخدم واحد',
		two: 'أوصى به مستخدمان',
		few: 'أوصى به ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مستخدمين',
		many: 'أوصى به ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مستخدمًا',
		other: 'أوصى به ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مستخدم',
	);
	@override String recommendedBy({required Object who}) => 'الموصى بها من قبل ${who}';
	@override String favoritedBy({required Object who}) => 'المفضلة بواسطة ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} لم يتم نشره بعد';
	@override String recommendedByPercent({required Object percent}) => 'الموصى بها من قبل ${percent} من المشاهدين';
	@override String get relatedTitles => 'العناوين ذات الصلة';
	@override String get background => 'الخلفية';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$ar extends Translations$liveTv$recordSettings$en {
	_Translations$liveTv$recordSettings$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get startEarly => 'بدء مبكرا ( ثانية )';
	@override String get endLate => 'نهاية متأخرة ( ثواني )';
	@override String get newOnly => 'أحداث جديدة فقط';
	@override String get anyChannel => 'تسجيل في أي قناة';
	@override String get anyTime => 'تسجيل في أي وقت';
	@override String get skipInLibrary => 'إلقاء القفز على الحلقات بالفعل في المكتبة';
	@override String get keepUpTo => 'الحوادث التي يجب الحفاظ عليها';
	@override String get keepUpToHint => '0 يحافظ على كل حلقة';
}

// Path: music.discography
class _Translations$music$discography$ar extends Translations$music$discography$en {
	_Translations$music$discography$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'مجلدات & EPs';
	@override String get live => 'مباشر';
	@override String get compilations => 'المجموعات';
}

// Path: watchTogether.notices
class _Translations$watchTogether$notices$ar extends Translations$watchTogether$notices$en {
	_Translations$watchTogether$notices$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name} اللعب المضغوط';
	@override String get playbackStarted => 'بدأت Playback';
	@override String paused({required Object name}) => '${name} استراحة';
	@override String get playbackPaused => 'Playback استراحة';
	@override String jumpedTo({required Object name, required Object position}) => '${name} قفزت إلى ${position}';
	@override String roomJumpedTo({required Object position}) => 'تداول الخيارات الثنائية ${position}';
	@override String changedSpeed({required Object name, required Object speed}) => '${name} يحدد السرعة إلى ${speed}';
	@override String speedChanged({required Object speed}) => 'السرعة المحددة إلى ${speed}';
	@override String startedMedia({required Object name, required Object title}) => '${name} بدأت ${title}';
	@override String mediaStarted({required Object title}) => 'اللعب الآن ${title}';
	@override String stoppedMedia({required Object name}) => '${name} توقف الفيديو';
	@override String get mediaStopped => 'فيديو توقف';
	@override String waitingFor({required Object name}) => 'في انتظار ${name} ...';
	@override String get waitingForSomeone => 'وانتظر شخص ما يلتقط...';
	@override String get finished => 'الانتهاء';
	@override String hostChangedTo({required Object name}) => '${name} هو الآن المضيف';
	@override String get youAreNowHost => 'أنت الآن المضيف';
	@override String joined({required Object name}) => '${name} المشاركة';
	@override String left({required Object name}) => '${name} قليلا';
	@override String get controlRefused => 'لا يستطيع المضيف سوى التحكم في البث';
	@override String get searchFailed => 'بعض الخوادم لا يمكن البحث عن الفيديو في الغرفة';
	@override String get playBlocked => 'ألعاب الطباعة للبدء';
	@override String get shareFailed => 'لا أستطيع مشاركة هذا الفيديو مع الغرفة';
	@override String get downloadNotShared => 'لا يتم مشاركة التحميلات مع الغرفة بينما الخادم غير متصل';
	@override String get openFailed => 'لا أستطيع فتح الفيديو من الغرفة';
}

// Path: watchTogether.ended
class _Translations$watchTogether$ended$ar extends Translations$watchTogether$ended$en {
	_Translations$watchTogether$ended$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get ended => 'المضيف ينتهي الغرفة';
	@override String get kicked => 'تم إزالتك من الغرفة';
	@override String get expired => 'الغرفة قد انتهت';
	@override String get replaced => 'انضم إلى هذا الغرفة على جهاز آخر';
	@override String get lost => 'فقدت الاتصال بالغرفة';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$ar extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => 'الرموز لديها 6 أحرف والأرقام، دون 0.1، I، L أو O.';
	@override String get roomNotFound => 'لم يكن هناك أي غرفة لديها هذا الرمز، ربما انتهى.';
	@override String get roomFull => 'هذه الغرفة مليئة.';
	@override String get roomLocked => 'أغلقت المضيفة تلك الغرفة.';
	@override String get relayFull => 'مشاهدة معا مشغول الآن.محاولة مرة أخرى في وقت لاحق.';
	@override String get unreachable => 'لم أستطع الوصول إلى الساعة معا إرسال.تحقق من اتصالك.';
	@override String get rateLimited => 'الكثير من المحاولات.انتظر لحظة ومحاولة مرة أخرى.';
	@override String get clientBlocked => 'هذا الإصدار من PlezyNG لا يستطيع استخدام الإرسال.';
	@override String get forbidden => 'فقط المضيف يمكن أن يفعل ذلك.';
	@override String get notInRoom => 'أنت لست في غرفة.';
	@override String get alreadyInRoom => 'أنت الآن في غرفة.';
	@override String get resumeFailed => 'لا أستطيع أن أذهب إلى الغرفة.';
	@override String get unsupported => 'لا يدعم هذا الإذاعة.';
	@override String get generic => 'حدث خطأ، حاول مرة أخرى.';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$ar extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'سيتوقف التحميل عند مغادرتك التطبيق';
	@override String get bannerDegraded => 'يمكن أن تكون تنزيلات الخلفية محدودة';
	@override String get bannerAction => 'تفاصيل';
	@override String get sheetTitle => 'يتم حظر تنزيلات الخلفية';
	@override String get sheetTitleDegraded => 'يمكن أن تكون تنزيلات الخلفية محدودة';
	@override String get sheetIntro => 'Android يمنع PlezyNG من تنزيل موثوقة في الخلفية.';
	@override String get sheetIntroDegraded => 'جهازك يحدد عندما يمكن تحميل PlezyNG في الخلفية.';
	@override String get reasonBackgroundRestricted => 'استخدام الخلفية PlezyNG يقتصر.إعداد استخدام البطارية أو الخلفية إلى "غير محدود".';
	@override String get reasonStandbyRestricted => 'Android قد وضعت PlezyNG في حالة وقوف محدودة.';
	@override String get reasonDownloadChannelBlocked => 'يتم إيقاف تشغيل إشعارات التنزيل ، لذلك قد لا تكون التقدم والسيطرة متاحة.';
	@override String get reasonNotificationsDisabled => 'يتم إيقاف الإشعارات. على Android 13 أو أحدث، فهي مطلوبة للتنزيلات الخلفية الطويلة.';
	@override String get reasonDataSaver => 'توفير البيانات مفعّل، مما يمنع التنزيل في الخلفية عبر بيانات الجوّال. يُفترض أن تستمر التنزيلات عبر Wi-Fi.';
	@override String get reasonOemUnknown => 'توقفت التنزيلات عدة مرات أثناء عمل PlezyNG في الخلفية. تحقق من إعدادات البطارية أو استخدام الخلفية الخاصة بـ PlezyNG.';
	@override String get openSettings => 'إعدادات مفتوحة';
	@override String get stillNotWorking => 'مساعدة محددة الأجهزة';
	@override String get stillNotWorkingDescription => 'عرض الخطوات على جهازك، أو إرسال سجل من الإعدادات › عرض السجلات إذا استمرت المشكلة.';
	@override String get dialogTitle => 'تحميل قد لا ينتهي';
	@override String get dialogDownloadAnyway => 'تحميل على أي حال';
	@override String get dialogFixFirst => 'إصلاح هذا أولاً';
	@override String get statusTile => 'خلفية تحميل';
	@override String get statusOk => 'يسمح بالركض في الخلفية';
	@override String get statusBlocked => 'محظور من خلال إعدادات النظام';
	@override String get statusDegraded => 'الحد الأدنى من نظام الإعدادات';
	@override String get statusUnknown => 'لم يتم فحصها بعد';
	@override String get settingsUnavailable => 'لا يمكن فتح إعدادات النظام على هذا الجهاز';
	@override String get linkUnavailable => 'لا يمكن فتح dontkillmyapp.com على هذا الجهاز';
}

// Path: downloads.groupings
class _Translations$downloads$groupings$ar extends Translations$downloads$groupings$en {
	_Translations$downloads$groupings$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get library => 'المكتبة';
	@override String get collections => 'المجموعات';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$ar extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'بدء تشغيل الخادم عن بعد';
	@override String get hostAddress => 'العنوان المضيف';
	@override String get connected => 'متصلة';
	@override String get serverRunning => 'الخادم عن بعد نشط';
	@override String get serverStopped => 'توقف الخادم عن بعد';
	@override String get serverRunningDescription => 'الأجهزة المحمولة على شبكتك يمكن الاتصال بهذه التطبيق';
	@override String get serverStoppedDescription => 'بدء تشغيل الخادم لتمكين الأجهزة المحمولة من الاتصال';
	@override String get usePhoneToControl => 'استخدم جهازك المحمول للسيطرة على هذا التطبيق';
	@override String get startServer => 'بدء الخادم';
	@override String get stopServer => 'توقف الخادم';
	@override String get minimize => 'الحد الأدنى';
	@override String get manualAddressHint => 'عنوان الاتصال اليدوي :';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$ar extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'الأجهزة PlezyNG مع نفس الحساب Plex تظهر هنا';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'اتصال ...';
	@override String get searchingForDevices => 'البحث عن الأجهزة...';
	@override String get noDevicesFound => 'لا توجد أجهزة في شبكتك';
	@override String get noDevicesHint => 'افتح PlezyNG على سطح المكتب واستخدم نفس Wi-Fi';
	@override String get availableDevices => 'أجهزة متوفرة';
	@override String get manualConnection => 'الاتصال اليدوي';
	@override String get cryptoInitFailed => 'لا يمكن أن تبدأ اتصال آمن. تسجيل الدخول إلى Plex أولا.';
	@override String get validationHostRequired => 'يرجى إدخال عنوان المضيف';
	@override String get validationHostFormat => 'يجب أن يكون تنسيق IP:port (على سبيل المثال، 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'اتصال متأخر: استخدم نفس الشبكة على كلا الجهازين.';
	@override String get sessionNotFound => 'لا يوجد جهاز تم العثور عليه. تأكد من أن PlezyNG يعمل على المضيف.';
	@override String get authFailed => 'فشل التحقق: يحتاج كلا الجهازين إلى نفس الحساب Plex.';
	@override String failedToConnect({required Object error}) => 'عدم الاتصال: ${error}';
	@override String get codeTitle => 'الرمز المزدوج';
	@override String get codeDescription => 'أدخل الرمز الذي يظهر في Companion Remote على الجهاز المضيف.يجب على كلا الجهازين استخدام نسخة تدعم الارتباط الآمن.';
	@override String get codeInvalid => 'أدخل جميع الحروف والأرقام 32 من رمز المضيف.';
	@override String get updateRequired => 'تحديث كلا الجهازين إلى إصدار يدعم الارتباط الآمن.';
	@override String get hostDescription => 'أدخل هذا الرمز مرة واحدة على كل جهاز بعيد.حافظ على خصوصية: يمنح السيطرة على هذا الملف الشخصي.';
	@override String get resetCode => 'إعادة تعيين الرمز المزدوج';
	@override String get resetDescription => 'قم بإلغاء الاتصال بجميع الوسائل البعيدة وخلق رمز جديد.سيتعين على كل الوسائل البعيدة أن تتزوج مرة أخرى.';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$ar extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'هل ترغب في إلغاء الاتصال من الجلسة عن بعد؟';
	@override String get reconnecting => 'إعادة الاتصال...';
	@override String attemptOf({required Object current}) => 'حاول ${current} من 5';
	@override String get retryNow => 'العودة الآن';
	@override String get tabRemote => 'بعيد';
	@override String get tabPlay => 'تشغيل';
	@override String get tabMore => 'المزيد';
	@override String get menu => 'القائمة';
	@override String get tabNavigation => 'Tab الملاحة';
	@override String get tabDiscover => 'اكتشاف';
	@override String get tabLibraries => 'المكتبات';
	@override String get tabSearch => 'بحث';
	@override String get tabDownloads => 'التنزيلات';
	@override String get tabSettings => 'الإعدادات';
	@override String get previous => 'السابق';
	@override String get playPause => 'لعبة / استراحة';
	@override String get next => 'التالي';
	@override String get seekBack => 'البحث مرة أخرى';
	@override String get stop => 'إيقاف';
	@override String get seekForward => 'البحث FWD';
	@override String get volume => 'حجم';
	@override String get volumeDown => 'أسفل';
	@override String get volumeUp => 'أعلى';
	@override String get fullscreen => 'ملء الشاشة';
	@override String get subtitles => 'الترجمة';
	@override String get audio => 'الصوت';
	@override String get searchHint => 'البحث على سطح المكتب ..';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$ar extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'لا توجد واجهة شبكة';
	@override String get authenticationFailed => 'فشل التحقق';
	@override String serverStartFailed({required Object error}) => 'عدم تشغيل الخادم عن بعد: ${error}';
	@override String commandFailed({required Object error}) => 'فشل في إرسال الأمر عن بعد: ${error}';
	@override String get joinTimedOut => 'توقيت الانضمام إلى الجلسة';
	@override String get failedToConnectAnyAddress => 'فشل في الاتصال بأي عنوان';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'فقدت الاتصال بعد ${attempts} محاولة';
	@override String get connectionLost => 'الاتصال المفقود';
}

// Path: services.names
class _Translations$services$names$ar extends Translations$services$names$en {
	_Translations$services$names$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class _Translations$services$simklReconnect$ar extends Translations$services$simklReconnect$en {
	_Translations$services$simklReconnect$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'إعادة الاتصال Simkl';
	@override String get subtitle => 'توقف Simkl تدريجيًا دعم طريقة تسجيل الدخول المستخدمة في هذا الاتصال. تفتح إعادة الاتصال موقع simkl.com للموافقة على PlezyNG، ولا يطّلع PlezyNG على كلمة مرورك مطلقًا. يبقى سجل مشاهداتك محفوظًا في Simkl.';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$ar extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'تنشيط PlezyNG على ${service}';
	@override String get instructions => 'قم بفحص رمز QR، أو قم بزيارة العنوان أدناه وإدخال هذا الرمز:';
	@override String openToActivate({required Object service}) => 'فتح ${service} لتنشيط';
	@override String get copyCode => 'نسخ رمز التنشيط';
	@override String get waitingForAuthorization => 'وانتظروا الترخيص ..';
	@override String get codeCopied => 'الرمز النسخ';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$ar extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'تسجيل الدخول إلى ${service}';
	@override String get body => 'فحص هذا الرمز QR أو فتح URL على أي جهاز.';
	@override String openToSignIn({required Object service}) => 'فتح ${service} للتسجيل في';
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$ar extends Translations$services$pendingAuth$en {
	_Translations$services$pendingAuth$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'نسخة من URL';
	@override String get urlCopied => 'URL نسخة';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$ar extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'مكتبة الفلتر';
	@override String get subtitleAllSyncing => 'إعداد جميع المكتبات';
	@override String get subtitleNoneSyncing => 'لا شيء يتزامن';
	@override String subtitleBlocked({required Object count}) => '${count} محظور';
	@override String subtitleAllowed({required Object count}) => '${count} مسموح بها';
	@override String get mode => 'طريقة الفلتر';
	@override String get modeBlacklist => 'القائمة السوداء';
	@override String get modeWhitelist => 'القائمة البيضاء';
	@override String get modeHintBlacklist => 'تصفية كل مكتبة باستثناء تلك التي تم التحقق منها أدناه.';
	@override String get modeHintWhitelist => 'لا تتزامن إلا مع المكتبات التي تم التحقق منها أدناه.';
	@override String get libraries => 'المكتبات';
	@override String get noLibraries => 'لا توجد مكتبات متاحة';
}

/// The flat map containing all translations for locale <ar>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsAr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'cast.chooseDevice' => 'البث إلى جهاز',
			'cast.searching' => 'جارٍ البحث عن أجهزة البث…',
			'cast.connectedTo' => ({required Object device}) => 'متصل بـ ${device}',
			'cast.device' => 'جهاز البث',
			'cast.readyToCast' => 'جاهز للبث',
			'cast.subtitle' => 'الترجمة',
			'cast.serverNotAvailable' => 'خادم الوسائط غير متاح.',
			'cast.stopCasting' => 'إيقاف البث',
			'cast.castToDevice' => 'البث إلى جهاز',
			'cast.noEpisodeAvailable' => 'لا توجد حلقة متاحة للبث.',
			'cast.startFailed' => 'تعذر بدء البث. تحقق من الخادم وحاول مرة أخرى.',
			'automation.noActivePlayback' => 'لا يوجد جلسة فيديو نشطة للتحكم فيها.',
			'automation.profileNotFound' => 'لم يتم العثور على هذا الملف Plezy.',
			'notifications.newEpisodeTitle' => 'الحلقة الجديدة',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appIcon.title' => 'تطبيق icon',
			'appIcon.defaultIcon' => 'الافتراضي',
			'appIcon.current' => 'الرمز الحالي',
			'appIcon.locked' => 'الوصول مدى الحياة مطلوب',
			'appIcon.lockedHint' => 'ابدأ تجربة 7 أيام أو قم بإلغاء قفل PlezyNG مدى الحياة لاستخدام أيقونات بديلة.',
			'appIcon.changeFailed' => 'لا يمكن تغيير أيقونة التطبيق',
			'appIcon.launcherHint' => 'يظهر الرمز الجديد على الشاشة المنزلية الخاصة بك بمجرد مغادرتك PlezyNG.',
			'appIcon.tvLauncherHint' => 'يظهر الشعار الجديد بمجرد مغادرتك PlezyNG. Android TV يمكن أن تستمر في عرض الشعار القديم حتى يبدأ التلفزيون مرة أخرى.',
			'appIcon.names.midnight' => 'منتصف الليل',
			'appIcon.names.ember' => 'الناس',
			'appIcon.names.paper' => 'الورق',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => 'الخطوط',
			'appIcon.names.ocean' => 'المحيط',
			'appIcon.names.ultraviolet' => 'فوق بنفسجي',
			'appIcon.names.matcha' => 'ماتشا',
			'appIcon.names.sunset' => 'الشمس',
			'appIcon.names.gold' => 'الذهب',
			'appIcon.names.titanium' => 'التيتانيوم',
			'appIcon.names.glass' => 'الزجاج',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => 'الموجة',
			'appIcon.names.pixel' => 'بيكسل',
			'appIcon.names.neon' => 'نينوى',
			'appIcon.names.sticker' => 'ملصق',
			'appIcon.names.ticket' => 'تذاكر',
			'appIcon.names.pop' => 'بوب',
			'appIcon.names.strata' => 'الشارع',
			'appIcon.names.facet' => 'الوجه',
			'appIcon.names.tilde' => 'تيلد',
			'auth.signInWithPlex' => 'تسجيل الدخول مع Plex',
			'auth.showQRCode' => 'عرض الرمز QR',
			'auth.authenticate' => 'الأصلي',
			'auth.authenticationTimeout' => 'تأكيد موعد، يرجى المحاولة مرة أخرى.',
			'auth.scanQRToSignIn' => 'قم بفحص هذا الرمز QR لتسجيل الدخول',
			'auth.waitingForAuth' => 'الانتظار للحصول على مصداقية... تسجيل الدخول من المتصفح الخاص بك.',
			'auth.useBrowser' => 'استخدام البريد الإلكتروني',
			'auth.or' => 'أو',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'الاتصال بـ ${product}',
			'auth.quickConnect' => 'توصيل سريع',
			'auth.useQuickConnect' => 'استخدام Quick Connect',
			'auth.quickConnectInstructions' => 'افتح Quick Connect في Jellyfin واكتب هذا الرمز.',
			'auth.quickConnectWaiting' => 'في انتظار الموافقة ..',
			'auth.quickConnectCancel' => 'إلغاء',
			'auth.quickConnectExpired' => 'انتهت صلاحية الاتصال السريع. حاول مرة أخرى.',
			'auth.localDataRecoveryRequired' => 'تعذّر على PlezyNG استعادة بيانات تسجيل الدخول المحلية وبيانات التشغيل المعلّقة بأمان. يُرجى تسجيل الدخول مجددًا.',
			'auth.pinCheckRejected' => 'تم رفض التحقق Plex PIN',
			'auth.connectToDirectPlex' => 'الاتصال بالخادم المحلي Plex',
			'common.cancel' => 'إلغاء',
			'common.save' => 'حفظ',
			'common.close' => 'إغلاق',
			'common.clear' => 'واضحة',
			'common.reset' => 'إعادة تعيين',
			'common.later' => 'في وقت لاحق',
			'common.submit' => 'إرسال',
			'common.confirm' => 'تأكيد',
			'common.retry' => 'إعادة المحاولة',
			'common.logout' => 'تسجيل الخروج',
			'common.unknown' => 'غير معروف',
			'common.refresh' => 'تحديث',
			'common.yes' => 'نعم',
			'common.no' => 'لا',
			'common.delete' => 'حذف',
			'common.edit' => 'تعديل',
			'common.shuffle' => 'تشغيل عشوائي',
			'common.addTo' => 'أضف إلى...',
			'common.createNew' => 'خلق جديد',
			'common.connect' => 'اتصال',
			'common.disconnect' => 'قطع الاتصال',
			'common.play' => 'تشغيل',
			'common.pause' => 'إيقاف مؤقت',
			'common.resume' => 'استئناف',
			'common.error' => 'خطأ',
			'common.search' => 'بحث',
			'common.home' => 'الرئيسية',
			'common.back' => 'رجوع',
			'common.settings' => 'الإعدادات',
			'common.mute' => 'كتم الصوت',
			'common.ok' => 'حسنًا',
			'common.off' => 'إيقاف',
			'common.options' => 'الخيارات',
			'common.seasonNumber' => ({required Object number}) => 'الموسم ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'الحلقة ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'الفصل ${number}',
			'common.reconnect' => 'إعادة الاتصال',
			'common.viewAll' => 'انظر كل',
			'common.checkingNetwork' => 'شبكة التحقق...',
			'common.loadingServers' => 'الخادم المحمول ...',
			'common.connectingToServers' => 'الاتصال بالخوادم ...',
			'common.startingOfflineMode' => 'بدء تشغيل الوضع غير المباشر ...',
			'common.loading' => 'تحميل...',
			'common.fullscreen' => 'ملء الشاشة',
			'common.exitFullscreen' => 'الخروج الشاشة الكاملة',
			'common.pressBackAgainToExit' => 'اضغط مرة أخرى للخروج',
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
			'common.mediaKind.movie' => 'فيلم',
			'common.mediaKind.show' => 'عرض',
			'common.mediaKind.season' => 'الموسم',
			'common.mediaKind.episode' => 'حلقة',
			'common.mediaKind.artist' => 'فنان',
			'common.mediaKind.album' => 'ألبوم',
			'common.mediaKind.track' => 'مسار',
			'common.mediaKind.collection' => 'مجموعة',
			'common.mediaKind.playlist' => 'قائمة التشغيل',
			'common.mediaKind.clip' => 'مقطع',
			'common.mediaKind.photo' => 'صورة',
			'common.mediaKind.folder' => 'مجلد',
			'screens.licenses' => 'التراخيص',
			'screens.switchProfile' => 'الملف الشخصي Switch',
			'screens.subtitleStyling' => 'تنسيق الترجمة',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'السجلات',
			'update.available' => 'التحديثات المتاحة',
			'update.versionAvailable' => ({required Object version}) => 'الإصدار ${version} متوفر',
			'update.currentVersion' => ({required Object version}) => 'الحالي: ${version}',
			'update.skipVersion' => 'إلغاء هذا النسخة',
			'update.viewRelease' => 'مشاهدة الإصدار',
			'update.latestVersion' => 'أنت في أحدث النسخة',
			'update.checkFailed' => 'فشل في التحقق من التحديثات',
			'appAccess.title' => 'جرّب جميع الميزات مجانًا لمدة 7 أيام',
			'appAccess.description' => 'ابدأ فترة تجريبية لمدة سبعة أيام مع إمكانية استخدام جميع ميزات PlezyNG. لا توجد رسوم خلال الفترة التجريبية ولا اشتراك. بعد انتهاء التجربة، يمكنك فتح PlezyNG مدى الحياة بدفعة واحدة بالسعر المعروض في متجرك.',
			'appAccess.trialEndedDescription' => 'افتح جميع ميزات PlezyNG مدى الحياة بدفعة واحدة بالسعر المعروض في متجرك. لا يوجد اشتراك.',
			'appAccess.startTrial' => 'بدء تجربتي المجانية لمدة 7 أيام',
			'appAccess.trialActive' => 'تجربتك الكاملة لجميع الميزات لمدة 7 أيام نشطة.',
			'appAccess.trialEnded' => 'انتهت تجربتك لمدة 7 أيام',
			'appAccess.trialStartFailed' => 'تعذر حفظ الفترة التجريبية على هذا الجهاز. حاول مرة أخرى.',
			'appAccess.lifetimeTitle' => 'تم فتح PlezyNG مدى الحياة',
			'appAccess.lifetimeBody' => 'شكرًا لك! يمكنك الآن استخدام جميع ميزات PlezyNG مدى الحياة.',
			'appAccess.manageTitle' => 'الوصول إلى PlezyNG مدى الحياة',
			'appAccess.manageDescription' => 'جرّب جميع الميزات مجانًا لمدة 7 أيام، ثم افتحها مدى الحياة بدفعة واحدة بالسعر المعروض في متجرك.',
			'appAccess.buy' => ({required Object price}) => 'فتح جميع الميزات مقابل ${price}',
			'appAccess.loadingPrice' => 'جارٍ تحميل السعر من المتجر…',
			'appAccess.retryPrice' => 'إعادة محاولة جلب السعر',
			'appAccess.restore' => 'استعادة عملية الشراء مدى الحياة',
			'appAccess.pending' => 'عملية الشراء في انتظار الدفع أو الموافقة. سيُفعّل الوصول مدى الحياة فور إتمام المتجر للعملية.',
			'appAccess.storeUnavailable' => 'عمليات الشراء غير متاحة. تحقق من تسجيل الدخول إلى المتجر ومن السماح بالشراء على هذا الجهاز.',
			'appAccess.productNotFound' => 'شراء PlezyNG مدى الحياة غير متاح في هذا المتجر بعد.',
			'appAccess.productQueryFailed' => 'تعذر تحميل السعر من المتجر. تحقق من اتصالك وحاول مرة أخرى.',
			'appAccess.purchaseFailed' => 'لم تكتمل عملية الشراء. حاول مرة أخرى.',
			'appAccess.restoreFailed' => 'تعذر الاتصال بالمتجر لاستعادة عملية الشراء. حاول مرة أخرى.',
			'appAccess.nothingToRestore' => 'لم يُعثر على عملية شراء PlezyNG مدى الحياة لحساب المتجر هذا.',
			'settings.title' => 'الإعدادات',
			'settings.supportDeveloper' => 'دعم PlezyNG',
			'settings.supportDeveloperDescription' => 'التبرع بدعم التنمية',
			'settings.lifetimeAccess' => 'PlezyNG الوصول مدى الحياة',
			'settings.language' => 'اللغة',
			'settings.theme' => 'السمة',
			'settings.appearance' => 'ظهور',
			'settings.detailPage' => 'صفحة تفاصيل',
			'settings.themeSongsEnabled' => 'لعب الأغاني الموضوعية',
			'settings.themeSongsEnabledDescription' => 'تلعب الأغاني الموضوعية المتاحة أثناء مشاهدة تفاصيل وسائل الإعلام.',
			'settings.themeSongVolume' => 'موضوع الأغنية حجم',
			'settings.videoPlayback' => 'أشرطة الفيديو Playback',
			'settings.videoPlaybackDescription' => 'إعداد سلوك playback',
			'settings.advanced' => 'متقدم',
			'settings.episodePosterMode' => 'مسلسل Poster Style',
			'settings.seriesPoster' => 'سلسلة الملصقات',
			'settings.seasonPoster' => 'الموسم الملصقات',
			'settings.episodeThumbnail' => 'التوماني',
			'settings.showHeroSectionDescription' => 'شاشة تحتوي على محتوى الكاروسيل على الشاشة المنزلية',
			'settings.secondsLabel' => 'ثانية',
			'settings.minutesLabel' => 'دقائق',
			'settings.secondsShort' => 'س',
			'settings.minutesShort' => 'م',
			'settings.durationHint' => ({required Object min, required Object max}) => 'إدخال قيمة (${min}-${max})',
			'settings.systemTheme' => 'النظام',
			'settings.lightTheme' => 'الضوء',
			'settings.darkTheme' => 'الظلام',
			'settings.oledTheme' => 'OLED',
			'settings.emberTheme' => 'الناس',
			'settings.glacierTheme' => 'الجليد',
			'settings.forestTheme' => 'الغابات',
			'settings.plumTheme' => 'PLUM',
			'settings.paperTheme' => 'الورق',
			'settings.libraryDensity' => 'الكتب المكتبية',
			'settings.displayScale' => 'عرض مقياس',
			'settings.compact' => 'كومباكت',
			'settings.comfortable' => 'مريح',
			'settings.gridSpacing' => 'شبكة الفضاء',
			'settings.gridSpacingTight' => 'تيتا',
			'settings.gridSpacingNormal' => 'عادي',
			'settings.gridSpacingSpacious' => 'الفضاء',
			'settings.tvCornerSpotlightBackdrop' => 'الضوء الخلفي Spotlight Backdrop',
			'settings.tvCornerSpotlightBackdropDescription' => 'عرض أعمال الفن في الزاوية اليمنى العليا بدلاً من ملء الشاشة',
			'settings.viewMode' => 'رؤية الأزياء',
			'settings.gridView' => 'شبكة',
			'settings.listView' => 'قائمة',
			'settings.showHeroSection' => 'عرض قسم البطل',
			'settings.showHomeBackdrop' => 'عرض الفنون المنزلية الخلفية',
			'settings.showHomeBackdropDescription' => 'عرض أعمال فنية كبيرة وراء صفوف المنزل المميزة',
			'settings.contentScreensaverEnabled' => 'محتوى الشاشة',
			'settings.contentScreensaverEnabledDescription' => 'عرض أعمال الفن على الشاشة الكاملة بعد أن أصبحت التطبيق مجنون',
			'settings.contentScreensaverDelay' => 'بدء تشغيل الشاشة بعد',
			'settings.contentScreensaverLibraries' => 'الكتب المكتبية الشاشة',
			'settings.contentScreensaverLibrariesDescription' => 'اختر أي مكتبات توفر عمل الفن الذي يحفظ الشاشة.إذا لم يتم اختيار أي منها، يتم استخدام عمل الفن من جميع المكتبات.',
			'settings.contentScreensaverAllLibraries' => 'كل المكتبات',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} المكتبات المختارة',
			'settings.contentScreensaverNoLibraries' => 'لا توجد مكتبات وسائل الإعلام المرتبطة.',
			'settings.contentScreensaverDismissHint' => 'اضغط على أي زر أو اضغط على إلغاء',
			'settings.newEpisodeNotifications' => 'إشعارات الحلقة الجديدة',
			'settings.newEpisodeNotificationsDescription' => 'تحذير عندما يتم إضافة حلقة جديدة إلى عرض تم التقاطها. التحقق بينما Plezy مفتوحة.',
			'settings.continueWatchingRowSize' => 'مواصلة مشاهدة حجم الخط',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => '${label} بطاقات',
			'settings.rowSizeCompact' => 'كومباكت',
			'settings.rowSizeStandard' => 'المعيار',
			'settings.rowSizeLarge' => 'كبير',
			'settings.continueWatchingAction' => 'مواصلة مراقبة العمل',
			'settings.continueWatchingPlay' => 'تشغيل',
			'settings.continueWatchingDetails' => 'التفاصيل المفتوحة',
			'settings.episodeAction' => 'الحلقة العملية',
			'settings.episodePlay' => 'تشغيل',
			'settings.episodeDetails' => 'التفاصيل المفتوحة',
			'settings.useGlobalHubs' => 'استخدام Home Layout',
			'settings.useGlobalHubsDescription' => 'إظهار المراكز المنزلية الموحدة.إلا استخدم توصيات المكتبة.',
			'settings.showServerNameOnHubs' => 'عرض اسم الخادم على Hubs',
			'settings.showServerNameOnHubsDescription' => 'يظهر دائمًا أسماء الخوادم في عناوين hub.',
			'settings.groupLibrariesByServer' => 'مكتبات المجموعات حسب الخادم',
			'settings.groupLibrariesByServerDescription' => 'مكتبات صفحة المجموعة تحت كل خادم وسائل الإعلام.',
			'settings.alwaysKeepSidebarOpen' => 'الحفاظ دائما على الجانب المفتوح',
			'settings.alwaysKeepSidebarOpenDescription' => 'يبقى شريط الجانب واسع النطاق ويتم تعديل نطاق المحتوى لتناسب',
			'settings.showUnwatchedCount' => 'إظهار عدد غير ملاحظ',
			'settings.showUnwatchedCountDescription' => 'عرض الحلقة غير المشاهدة حساب على العروض والموسم',
			'settings.showWatchedIndicators' => 'عرض المؤشرات الملاحظة',
			'settings.showWatchedIndicatorsDescription' => 'إظهار علامة تحقق على الأفلام والمسرحيات والأحداث التي شاهدتها',
			'settings.showEpisodeNumberOnCards' => 'عرض الحلقة رقم على البطاقات',
			'settings.showEpisodeNumberOnCardsDescription' => 'عرض الموسم ورقم الحلقة على بطاقات الحلقة',
			'settings.showSeasonPostersOnTabs' => 'عرض الملصقات الموسمية على Tabs',
			'settings.showSeasonPostersOnTabsDescription' => 'عرض ملصقات كل موسم فوق علامة التبويب الخاصة به',
			'settings.tvFullCardLayout' => 'بطاقات التلفزيون الكاملة',
			'settings.tvFullCardLayoutDescription' => 'استخدم بطاقات التلفزيون الصورة فقط مع أسماء الممثلين',
			'settings.focusGlow' => 'التركيز الضوء',
			'settings.focusGlowDescription' => 'ضع ضوءًا ناعمًا حول بطاقة التركيز',
			'settings.visualEffects' => 'التأثيرات البصرية',
			'settings.visualEffectsAuto' => 'تلقائي',
			'settings.visualEffectsAutoDescription' => 'تقليل الآثار تلقائيًا على أجهزة منخفضة الطاقة',
			'settings.visualEffectsFull' => 'كاملة',
			'settings.visualEffectsReduced' => 'انخفاض',
			'settings.visualEffectsReducedDescription' => 'عدد أقل من الرسوم المتحركة والعمل الفني أدنى القرار',
			'settings.hideSpoilers' => 'إخفاء البلاطات للمناقشات غير الملاحظة',
			'settings.hideSpoilersDescription' => 'صور ووصفات للأحداث غير الملاحظة',
			'settings.playerBackend' => 'اللاعب Backend',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'التخزين الصلب',
			'settings.hardwareDecodingDescription' => 'استخدم تسارع الأجهزة عندما يكون متاحًا',
			'settings.playbackBuffer' => 'لعبة Playback Buffer',
			'settings.playbackBufferAuto' => 'السيارة (موصى بها )',
			'settings.playbackBufferLarge' => 'كبير',
			'settings.playbackBufferExtraLarge' => 'كبير جدًا',
			'settings.playbackBufferDescription' => 'المزيد عن اتصالات غير مستقرة.المحدود أيضا بواسطة حجم البوفر.',
			'settings.streamBufferSize' => 'حجم البوفر',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} MB',
			'settings.streamBufferSizeDescription' => 'كم عدد مقاطع الفيديو التي يجب تحميلها إلى الأمام عند اللعب المباشر.توقف ترانسكودات على خادم ترانسكود الخاص بك. 0 = التلقائي',
			'settings.streamBufferSizeExoNote' => 'استبدال Playback Buffer عند إعدادها، مقطوعة إلى نصف حدود الذاكرة في التطبيق',
			'settings.streamBufferMegabytes' => 'ميغابيت',
			'settings.defaultQualityTitle' => 'الجودة الافتراضية',
			'settings.cellularQualityTitle' => 'الجودة الافتراضية على الخلايا',
			'settings.remoteQualityTitle' => 'جودة البث عن بعد',
			'settings.remoteQualitySameAsDefault' => 'كما هو الحال مع الجودة الافتراضية',
			'settings.cellularQualitySameAsDefault' => 'كما هو الحال مع الجودة الافتراضية',
			'settings.directPlayCoveredQuality' => 'تلعب أشرطة الفيديو الصغيرة في الجودة الأصلية',
			'settings.directPlayCoveredQualityDescription' => 'تشغيل الفيديو مباشرة بالفعل ضمن حدود الجودة بدلا من إعادة ترميزها',
			'settings.videoCodecs' => 'فيديو كوديك',
			'settings.videoCodecsDescription' => 'يتم ترتيب الرموز غير المختبرة من قبل الخادم',
			'settings.videoCodecsAlwaysAccepted' => 'دائما مقبولة',
			'settings.musicQualityTitle' => 'جودة الموسيقى',
			'settings.subtitleStyling' => 'تنسيق الترجمة',
			'settings.subtitleStylingDescription' => 'تخصيص مظهر العناوين',
			'settings.smallSkipDuration' => 'قصة قصيرة طويلة',
			'settings.largeSkipDuration' => 'طوله طوله طوله',
			'settings.rewindOnResume' => 'عودة على المجلد',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(seconds, zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} ثانية', one: 'ثانية', two: 'ثانيتان', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} ثوان', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} ثانية', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} ثانية', ), 
			'settings.defaultSleepTimer' => 'أوقات النوم الافتراضية',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(minutes, zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} دقيقة', one: 'دقيقة', two: 'دقيقتان', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} دقائق', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} دقيقة', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} دقيقة', ), 
			'settings.rememberTrackSelections' => 'تذكر اختيارات المسارات حسب عرض/فيلم',
			'settings.chooseTracksBeforePlayback' => 'اختيار الأصوات والأسماء الفرعية قبل تشغيل',
			'settings.chooseTracksBeforePlaybackDescription' => 'اقرأ الصوت المصدر ومتابعة العناوين الفرعية قبل أن يبدأ كل مقطع فيديو.',
			'settings.alwaysShowSubtitlesOnDevice' => 'إظهار دائمًا العناوين الفرعية على هذا الجهاز',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => 'إذا لم يكن الخادم لديه أي عنوان فرعي، اختر مسارًا محليًا، وهذا لا يغير أبدًا تفضيل الخادم.',
			'settings.autoDownloadPreferredSubtitle' => 'فاتش يفتقر إلى عناوين اللغة المفضلة',
			'settings.autoDownloadPreferredSubtitleDescription' => 'حدد علامة فرعية متوفرة في لغتك المفضلة محليًا.إذا لم تكن موجودة، اطلب من الخادم أن يلتقط علامة فرعية عند دعمها.',
			'settings.rememberTrackSelectionsDescription' => 'تخزين خيارات الصوت والعلامات الفرعية حسب العرض أو الفيلم على هذا الجهاز',
			'settings.rememberTrackSelectionsBackendRule' => 'يعمل محليًا مع Plex و Jellyfin و Emby و Plex و Jellyfin يمكن أيضًا حفظ الاختيارات على الخادم',
			'settings.followServerTrackSelections' => 'استخدم اختيارات المسار لكل حلقة من الخادم',
			'settings.followServerTrackSelectionsDescription' => 'عند تغيير الحلقة، قم بتطبيق الصوت والقبعات المختارة على الخادم بدلاً من إجراء الاختيار الحالي.',
			'settings.resumeMusicOnLaunch' => 'تذكر جلسة الموسيقى',
			'settings.resumeMusicOnLaunchDescription' => 'إعادة فتح الأغنية الأخيرة توقفت حيث غادرت عند بدء التطبيق',
			'settings.showChapterMarkersOnTimeline' => 'عرض علامات الفصل على البحث البار',
			'settings.showChapterMarkersOnTimelineDescription' => 'القسم البار البحث في حدود الفصل',
			'settings.specialsOrdering' => 'مميزات في ترتيب الحلقة',
			'settings.specialsOrderingDescription' => 'حيث يلعب المتخصصون في ترتيب الساعة في العرض',
			'settings.specialsOrderingServer' => 'اتبع أوامر الخادم',
			'settings.specialsOrderingAirDate' => 'التوقيت حسب تاريخ الهواء',
			'settings.specialsOrderingLast' => 'بعد الموسم العادي',
			'settings.clickVideoTogglesPlayback' => 'انقر على الفيديو لالتقاط اللعب/الراحة',
			'settings.clickVideoTogglesPlaybackDescription' => 'انقر على الفيديو للعب/التوقف بدلاً من عرض التحكم.',
			'settings.videoPlayerControls' => 'التحكم في ألعاب الفيديو',
			'settings.keyboardShortcuts' => 'لوحة مفاتيح قصيرة',
			'settings.keyboardShortcutsDescription' => 'تخصيص أقراص لوحة المفاتيح',
			'settings.videoPlayerNavigation' => 'ألعاب الفيديو الملاحة',
			'settings.videoPlayerNavigationDescription' => 'استخدم مفتاح الرصاص للتحكم في مشغل الفيديو',
			'settings.watchTogetherRelay' => 'مشاهدة فيلم Relay',
			'settings.watchTogetherRelayDescription' => 'الحفلات العامة المفتوحة تنشر ما لم تضع نفسك',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.watchTogetherRelayInvalid' => 'أدخل عنوان URL أساسيًا صالحًا لخادم الترحيل باستخدام HTTP أو HTTPS.',
			'settings.crashReporting' => 'تقرير الكارثة',
			'settings.crashReportingDescription' => 'إرسال تقارير عن الحوادث للمساعدة في تحسين التطبيق',
			'settings.debugLogging' => 'دبي تسجيل الدخول',
			'settings.debugLoggingDescription' => 'إمكانية تسجيل مفصل لحل المشكلات',
			'settings.viewLogs' => 'مشاهدة Logs',
			'settings.viewLogsDescription' => 'مشاهدة التطبيقات',
			'settings.clearImageCache' => 'صورة واضحة',
			'settings.clearImageCacheDescription' => 'يمكن تحميل الصور ببطء حتى يتم تنزيلها مرة أخرى.',
			'settings.clearImageCacheSuccess' => 'تم إزالة الصور بنجاح',
			'settings.resetSettings' => 'إعادة إعدادات',
			'settings.resetSettingsDescription' => 'استعادة الإعدادات الافتراضية.هذا لا يمكن أن يكون دون.',
			'settings.resetSettingsSuccess' => 'إعادة تعيين الإعدادات بنجاح',
			'settings.backup' => 'النسخ الاحتياطي',
			'settings.exportSettings' => 'إعدادات التصدير',
			'settings.exportSettingsDescription' => 'حفظ تفضيلاتك إلى ملف',
			'settings.exportSettingsSuccess' => 'الإعدادات المستوردة',
			'settings.importSettings' => 'إعدادات الواردات',
			'settings.importSettingsDescription' => 'استعادة تفضيلات من ملف',
			'settings.importSettingsConfirm' => 'هذا سيحل محل إعداداتك الحالية.مواصلة؟',
			'settings.importSettingsSuccess' => 'الإعدادات المستوردة',
			'settings.importSettingsInvalidFile' => 'هذا الملف غير صالحة PlezyNG إعدادات تصدير',
			'settings.importSettingsNoUser' => 'تسجيل الدخول قبل استيراد الإعدادات',
			'settings.cloudBackup' => 'سحابة النسخ الاحتياطي',
			'settings.cloudBackupDescription' => 'انسخ الإعدادات القابلة للنقل احتياطيًا إلى نقطة اتصال WebDAV عبر HTTPS. تبقى اتصالات الخادم وبيانات تسجيل الدخول على هذا الجهاز.',
			'settings.cloudBackupUrl' => 'WebDAV JSON ملف URL',
			'settings.cloudBackupUsername' => 'اسم المستخدم',
			'settings.cloudBackupPassword' => 'كلمة المرور',
			'settings.cloudBackupSaved' => 'سحابة النسخ الاحتياطي المستهدفة',
			'settings.cloudBackupNow' => 'العودة الآن',
			'settings.cloudBackupComplete' => 'إعدادات النسخ الاحتياطي تحميل',
			'settings.cloudBackupRestore' => 'استعادة النسخ الاحتياطي',
			'settings.cloudBackupRestoreConfirm' => 'هذا سوف يحل محل إعدادات المحمول المقابلة على هذا الجهاز.',
			'settings.cloudBackupRestored' => 'إعدادات استعادة من النسخ الاحتياطي السحابية',
			'settings.shortcutsReset' => 'إعادة تعيين القصص إلى الافتراضات',
			'settings.resetShortcutsConfirm' => 'هذا سوف يحل محل اختصاراتك المخصصة مع الافتراضات.',
			'settings.about' => 'حول',
			'settings.aboutDescription' => 'تطبيق المعلومات والترخيص',
			'settings.updates' => 'تحديثات',
			'settings.updateAvailable' => 'التحديثات المتاحة',
			'settings.checkForUpdates' => 'تحقق من التحديثات',
			'settings.autoCheckUpdatesOnStartup' => 'التحقق تلقائيًا من التحديثات على Startup',
			'settings.autoCheckUpdatesOnStartupDescription' => 'إشعار عندما يكون التحديث متاحًا عند الإطلاق',
			'settings.validationErrorEnterNumber' => 'يرجى إدخال رقم صالح',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'يجب أن يكون بين ${min} و ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'القطع القصيرة المخصصة بالفعل لـ ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'قصة قصيرة تم تحديثها لـ ${action}',
			'settings.saveFailed' => 'لا يمكن حفظ التغييرات، حاول مرة أخرى.',
			'settings.autoPlayAndSkip' => 'لعبة Auto-Play & Skip',
			'settings.autoPlayNextEpisode' => 'أوتوماتيك الحلقة التالية',
			'settings.autoPlayNextEpisodeDescription' => 'بدء الحلقة التالية تلقائيًا عندما تنتهي',
			'settings.shuffleStartsFromBeginning' => 'شافلي يبدأ في البداية',
			'settings.shuffleStartsFromBeginningDescription' => 'ابدأ كل حلقة في البداية عند التفريغ بدلاً من إعادة التفريغ',
			'settings.plexCinemaPreRoll' => 'استخدام الخادم السينما داخل',
			'settings.plexCinemaPreRollDescription' => 'تلعب إعداد Plex أو Jellyfin و Emby قبل بدء الفيلم.',
			'settings.playNextCountdown' => 'اللعب التالي حساب',
			'settings.playNextCountdownImmediate' => 'اللعب على الفور',
			'settings.skipIntroMode' => 'سكاي إنترو',
			'settings.skipIntroModeOffDescription' => 'لعب الدخول بشكل طبيعي دون زر التزلج',
			'settings.skipIntroModeButtonDescription' => 'إظهار زر التزلج عند بدء إدخال',
			'settings.skipIntroModeAutoDescription' => 'إسقاط الدخول تلقائيًا بعد التأخير أدناه',
			'settings.skipCreditsMode' => 'سكاي الائتمان',
			'settings.skipCreditsModeOffDescription' => 'لعب الائتمان عادة دون زر التزلج',
			'settings.skipCreditsModeButtonDescription' => 'إظهار زر التزلج عند بدء الائتمان',
			'settings.skipCreditsModeAutoDescription' => 'سحب الائتمان تلقائيًا وتلعب الحلقة التالية',
			'settings.skipAdsMode' => 'إعلانات Skip',
			'settings.skipAdsModeOffDescription' => 'تلعب الإعلانات التي تم اكتشافها بشكل طبيعي دون زر التزلج',
			'settings.skipAdsModeButtonDescription' => 'إظهار زر التزلج عند اكتشاف إعلان Plex',
			'settings.skipAdsModeAutoDescription' => 'إلغاء الإعلانات التي تم اكتشافها تلقائيًا بعد التأخير أدناه',
			'settings.musicPlayback' => 'الموسيقى Playback',
			'settings.musicSweetFades' => 'الحلوة الفاتحة',
			'settings.musicSweetFadesDescription' => 'يضع الموسيقى في أطراف المسار عندما يحتوي Plex على بيانات الضوضاء.',
			'settings.skipMarkerModeOff' => 'إيقاف',
			'settings.skipMarkerModeButton' => 'عرض الزر',
			'settings.skipMarkerModeAuto' => 'أوتوماتيك',
			'settings.forceSkipMarkerFallback' => 'قوة Fallback Markers',
			'settings.forceSkipMarkerFallbackDescription' => 'استخدم نماذج العنوان في الفصل حتى إذا كان Plex لديه علامات',
			'settings.theIntroDbFallback' => 'استخدم TheIntroDB كإسقاط مقدمة',
			'settings.theIntroDbFallbackDescription' => 'لا تستخدم مواعيد المجتمع إلا عندما لا يحتوي الخادم على علامة إدخال.',
			'settings.autoSkipDelay' => 'تأخير السيارة',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'الانتظار ${seconds} ثانية قبل الانزلاق الذاتي',
			'settings.introPattern' => 'نموذج علامة التبويب',
			'settings.introPatternDescription' => 'نموذج Regex لتناسب علامات intro في عناوين الفصول',
			'settings.creditsPattern' => 'الائتمان علامة نموذج',
			'settings.creditsPatternDescription' => 'نموذج ريجكس لتناسب علامات الائتمان في عناوين الفصول',
			'settings.prerolls' => 'البروتوكول',
			'settings.playPrerollsBeforeMovies' => 'ألعاب الفيديو قبل الأفلام',
			'settings.playPrerollsBeforeMoviesDescription' => 'لعب مقطع عشوائي من اختيارك أدناه قبل كل فيلم.',
			'settings.prerollLibrary' => 'مكتبة Preroll',
			'settings.prerollLibraryNotSet' => 'لا تضع',
			'settings.prerollLibraryNoneFound' => 'لا توجد مكتبات على خادماتك.',
			'settings.prerollSelection' => 'المختارين المختارين',
			'settings.prerollSelectionPickLibraryFirst' => 'اقرأ المكتبة أولاً',
			'settings.prerollSelectionNoneSelected' => 'لا توجد أطراف مختارة',
			'settings.prerollSelectionCount' => ({required Object count}) => '${count} تم اختيارها',
			'settings.prerollItemPicker' => 'اختياره preroll',
			'settings.prerollItemPickerLoadFailed' => 'لا يمكن تحميل العناصر من هذه المكتبة.',
			'settings.invalidRegex' => 'تعبيرات غير منتظمة',
			'settings.regex' => 'التعبير المنتظم',
			'settings.downloads' => 'التنزيلات',
			'settings.downloadLocationDescription' => 'اختيار المكان الذي يمكن تخزين المحتوى الذي تم تنزيله',
			'settings.downloadLocationDefault' => 'التخزين الافتراضي (App Storage)',
			'settings.downloadLocationCustom' => 'الموقع المخصص',
			'settings.selectFolder' => 'اختيار المجلد',
			'settings.resetToDefault' => 'إعادة تشغيل الافتراضي',
			'settings.currentPath' => ({required Object path}) => 'الحالي: ${path}',
			'settings.downloadLocationChanged' => 'تحميل الموقع تغير',
			'settings.downloadLocationReset' => 'تحميل موقع إعادة تعيين إلى الافتراض',
			'settings.downloadLocationInvalid' => 'المجلد المختار غير قابل للكتابة',
			'settings.downloadLocationPickerUnavailable' => 'لا توجد خيارات المجلدات متاحة على هذا الجهاز',
			'settings.downloadOnWifiOnly' => 'تنزيل على Wi-Fi فقط',
			'settings.downloadOnWifiOnlyDescription' => 'تجنب تنزيلات عند البيانات الخلوية',
			'settings.autoRemoveWatchedDownloads' => 'إزالة السيارات مشاهدة تحميل',
			'settings.autoRemoveWatchedDownloadsDescription' => 'إزالة النسخ التي تمت مشاهدتها تلقائيًا',
			'settings.autoDownloadContinueWatching' => 'تحميل تلقائي مواصلة مشاهدة',
			'settings.autoDownloadContinueWatchingDescription' => 'احفظ العناصر على قفص المتابعة المستمرة الخاص بك تحميل، وإزالتها بمجرد أن يغادروا قفص',
			'settings.downloadQuality' => 'تحميل الجودة',
			'settings.downloadQualityDescription' => 'Plex يعد نسخة محولة في سجل تنزيلها. Jellyfin و Emby ترانسكود بينما تنزيل الملف؛ قد تحتاج التحويلات المتوقفة إلى إعادة تشغيل.',
			'settings.askDownloadQualityEachTime' => 'اختيار الجودة لكل تحميل',
			'settings.askDownloadQualityEachTimeDescription' => 'إظهار الجودة الرائدة قبل إزالة كل تحميل الفيديو',
			'settings.cellularDownloadBlocked' => 'يتم حظر التنزيلات على الهاتف المحمول.استخدم Wi-Fi أو تغيير الإعداد.',
			'settings.maxVolume' => 'الحد الأقصى لمستوى الصوت',
			'settings.maxVolumeDescription' => 'السماح برفع مستوى الصوت فوق 100% للمحتوى ذي الصوت المنخفض',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'ضعف غنية الحضور',
			'settings.discordRichPresenceDescription' => 'إظهار ما تشاهده على Discord',
			'settings.services' => 'الخدمات',
			'settings.servicesDescription' => 'الاتصال Trakt, MyAnimeList, Seerr, وأكثر من ذلك',
			'settings.manageLibrariesDescription' => 'إعادة ترتيب وإخفاء المكتبات',
			'settings.companionRemoteServer' => 'الخادم عن بعد',
			'settings.companionRemoteServerDescription' => 'السماح للأجهزة المحمولة على شبكتك بالتحكم في هذا التطبيق',
			'settings.companionRemoteServerStartFailed' => 'لا يمكن إطلاق الخادم المرافق',
			'settings.companionRemoteServerStopFailed' => 'لا يمكن إيقاف الخادم المرافق',
			'settings.autoPip' => 'صورة في صورة Auto Picture',
			'settings.autoPipDescription' => 'إدخال صورة في الصورة تلقائيًا عند مغادرة التطبيق أثناء تشغيل',
			'settings.matchContentFrameRate' => 'مقارنة محتوى إطار معدل',
			'settings.matchContentFrameRateDescription' => 'عرض المباراة معدل التجديد إلى محتوى الفيديو',
			'settings.matchContentResolution' => 'حل المحتوى Match',
			'settings.matchContentResolutionDescription' => 'قم بتحويل الشاشة إلى الدقة الأصلية للفيديو بحيث يتصرف التلفزيون الخاص بك بشكل متزايد.',
			'settings.matchRefreshRate' => 'مسابقة التجديد معدل',
			'settings.matchRefreshRateDescription' => 'عرض المباراة معدل التجديد على الشاشة الكاملة',
			'settings.matchDynamicRange' => 'نطاق المنافسة الديناميكية',
			'settings.matchDynamicRangeDescription' => 'تحويل HDR إلى محتوى HDR ثم العودة إلى SDR',
			'settings.displaySwitchDelay' => 'عرض التبديل المتأخر',
			'settings.tunneledPlayback' => 'لعبة النفق Playback',
			'settings.tunneledPlaybackDescription' => 'إلغاء تشغيل HDR إذا عرض الفيديو الأسود أو أشرطة الفيديو الحركية.',
			'settings.audioPassthrough' => 'الصوت المضغوط',
			'settings.audioPassthroughDescription' => 'إرسال صوت Dolby/DTS إلى المستلم أو التلفزيون دون إعادة التشفير، والحفاظ على الصوت المحيط.',
			'settings.audioPassthroughDescriptionApple' => 'استخدم محفز Dolby الأصلي من Apple لـ Dolby Digital Plus ، بما في ذلك Atmos. DTS و TrueHD لا تزال تلعب كPCM متعدد القنوات.',
			'settings.audioPassthroughDescriptionAppleSpatial' => 'استخدم محفز Dolby الأصلي من Apple لـ Dolby Digital Plus ، بما في ذلك Atmos. على iOS ، iPadOS و tvOS 26 أو لاحقًا ، يلعب TrueHD Atmos و DTS:X كصوت فضاء.',
			'settings.audioPassthroughOverriddenByNormalization' => 'انقطع أثناء تشغيل الضوضاء',
			'settings.audioChannelLimit' => 'قنوات الصوت',
			'settings.audioChannelLimitDescription' => 'يخلط الصوت المكسور إلى أسفل للمكبرات الصوتية أو سماعات الرأس أو إعدادات HDMI التي لا يمكن تشغيل كل قناة',
			'settings.audioChannelLimitOriginal' => 'الأصلي',
			'settings.audioChannelLimitOriginalDescription' => 'لعب كل قناة في المسار',
			'settings.audioChannelLimitSurround51' => 'حتى 5.1',
			'settings.audioChannelLimitSurround51Description' => 'يخلط 7.1 إلى 5.1 بالنسبة للتلفزيونات والمستلمين الذين يستغرقون 5.1 PCM فقط.',
			'settings.audioChannelLimitStereo' => 'ستيريو (Stereo)',
			'settings.audioChannelLimitStereoDescription' => 'يخلط إلى اثنين من القنوات للمكبرات الصوتية الستيريو أو سماعات الرأس.',
			'settings.downmixCenterBoost' => 'تعزيز القناة الوسطى',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} دبي',
			'settings.downmixCenterBoostLabel' => 'الارتفاع (dB )',
			'settings.downmixCenterBoostShort' => 'دبي',
			'settings.audioDownmixNormalize' => 'تحديد الحجم على Downmix',
			'settings.audioDownmixNormalizeDescription' => 'انخفاض المزيج لمنع الانحناء. انقطع للحفاظ على الحجم الأصلي (قد يفسد المشاهد الصاخبة).',
			'settings.dvConversionMode' => 'Dolby Vision تحويل',
			'settings.dvConversionModeDescription' => 'اختر كيفية التعامل مع ملفات Dolby Vision الملف 7.',
			'settings.dvConversionAuto' => 'تلقائي',
			'settings.dvConversionNative' => 'الأصلي / المعاق',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'استخدام الكشف عن القدرة على الجهاز والسلوك السقوط الطبيعي',
			'settings.dvConversionNativeDescription' => 'القوة الأصلية DV7 و القمع DV التحويل الانسحاب',
			'settings.dvConversionDv81Description' => 'تحويل قوة RPU إلى Dolby Vision ملف تعريف 8.1',
			'settings.dvConversionHevcStripDescription' => 'شريط Dolby Vision طبقات RPU/EL والطابق الحالي HEVC',
			'settings.disableDolbyVision' => 'غير قابلة للتطبيق Dolby Vision',
			_ => null,
		} ?? switch (path) {
			'settings.disableDolbyVisionDescription' => 'تلعب طبقة الملف HDR10 أو HLG بدلاً من Dolby Vision ، عندما يكون لديه طبقة واحدة',
			'settings.hdrSdrConversion' => 'تحويل HDR إلى SDR',
			'settings.hdrSdrConversionDescription' => 'اختر ما الذي يحول فيديو HDR عندما لا يمكن لعرض الشاشة عرض HDR.',
			'settings.hdrSdrConversionAuto' => 'تلقائي',
			'settings.hdrSdrConversionAutoDescription' => 'الأجهزة على Android 9 وما بعدها، اللاعب على الإصدارات القديمة',
			'settings.hdrSdrConversionDevice' => 'الجهاز',
			'settings.hdrSdrConversionDeviceDescription' => 'أجهزة الفيديو في جهازك تحولها.أسرع، ولكن الألوان تعتمد على الجهاز',
			'settings.hdrSdrConversionPlayer' => 'المشغّل',
			'settings.hdrSdrConversionPlayerDescription' => 'الألوان المتسقة، ولكن 4K يمكن أن يضرب على صناديق التلفزيون منخفضة النهاية',
			'settings.deinterlace' => 'التفاوض',
			'settings.deinterlaceDescription' => 'إزالة المكونات المختلطة من الفيديو المختلط (mpv لاعب فقط)',
			'settings.deinterlaceOff' => 'إيقاف',
			'settings.deinterlaceOffDescription' => 'عرض الفيديو المترابط كما هو مخفف',
			'settings.deinterlaceVideo' => 'مرئي',
			'settings.deinterlaceVideoDescription' => 'تحويل كل حقل إلى إطار كامل.للصور الفيديو للتلفزيون، مثل الرياضة والأخبار والمؤتمرات',
			'settings.deinterlaceFilm' => 'فيلم',
			'settings.deinterlaceFilmDescription' => 'استعادة الإطارات الأصلية للفيلم والرسوم المتحركة التلفزيونية إلى 29.97 fps، شائعة على أقراص NTSC DVDs.',
			'settings.requireProfileSelectionOnOpen' => 'طلب الملف الشخصي على التطبيق المفتوح',
			'settings.requireProfileSelectionOnOpenDescription' => 'إظهار اختيار الملف الشخصي في كل مرة يتم فتح التطبيق',
			'settings.forceTvMode' => 'قوة التلفزيون',
			'settings.forceTvModeDescription' => 'قوة التلفزيون ترتيب.للأجهزة التي لا تكتشف تلقائيا.يتطلب إعادة تشغيل.',
			'settings.startInFullscreen' => 'بدءاً من الشاشة الكاملة',
			'settings.startInFullscreenDescription' => 'فتح PlezyNG في وضع الشاشة الكاملة عند الإطلاق',
			'settings.exitFullscreenOnPlayerClose' => 'الخروج الشاشة الكاملة على اللاعب مغلقة',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'يخرج الشاشة الكاملة تلقائيًا عند إغلاق مشغل الفيديو',
			'settings.autoHidePerformanceOverlay' => 'أداء التخفيف التلقائي',
			'settings.autoHidePerformanceOverlayDescription' => 'إزالة الأداء مع التحكم في التعبير',
			'settings.showNavBarLabels' => 'إظهار علامات البار الملاحة',
			'settings.showNavBarLabelsDescription' => 'عرض علامات النص تحت أيقونات شريط الملاحة',
			'settings.startupSection' => 'القسم Startup',
			'settings.preferredServer' => 'الخادم المفضل',
			'settings.preferredServerDescription' => 'أولوية نتائج هذا الخادم مع الحفاظ على كل خادم متصل متاح.',
			'settings.preferredServerAutomatic' => 'أوتوماتيك',
			'settings.showExploreTab' => 'عرض البحث Tab',
			'settings.showExploreTabDescription' => 'عرض علامة التبويب استكشاف مع المحتوى من Plex اكتشاف ومتابعي متصلة',
			'settings.hideEmptyLibraries' => 'إخفاء المكتبات الفارغة',
			'settings.hideEmptyLibrariesDescription' => 'إزالة المكتبات مع عدد العناصر التي تم الإبلاغ عنها من الخادم من الصفر من الملاحة.',
			'settings.liveTvDefaultFavorites' => 'قناة المفضلة المفضلة',
			'settings.liveTvDefaultFavoritesDescription' => 'عرض القنوات المفضلة فقط عند فتح التلفزيون المباشر',
			'settings.general' => 'عام',
			'settings.generalDescription' => 'اللغة والبدء والنافذة السلوك',
			'settings.languageAndRegion' => 'اللغة والمنطقة',
			'settings.startup' => 'بدء التشغيل',
			'settings.display' => 'العرض',
			'settings.libraryAndCards' => 'المكتبة والبطاقات',
			'settings.homeScreen' => 'Home شاشة',
			'settings.navigation' => 'التنقل',
			'settings.window' => 'نافذة',
			'settings.liveTv' => 'البث التلفزيوني المباشر',
			'settings.player' => 'المشغّل',
			'settings.videoAndDisplay' => 'الفيديو & عرض',
			'settings.audio' => 'الصوت',
			'settings.quality' => 'الجودة',
			'settings.subtitles' => 'الترجمة',
			'settings.seekAndTiming' => 'البحث والتوقيت',
			'settings.behavior' => 'السلوك',
			'settings.gestures' => 'الإيماءات',
			'settings.gestureBrightnessSwipe' => 'الضوء يتلاشى',
			'settings.gestureBrightnessSwipeDescription' => 'انحنى إلى الأعلى أو إلى الأسفل على الحافة اليسرى لتعديل الضوء',
			'settings.gestureVolumeSwipe' => 'حجم Swipe',
			'settings.gestureVolumeSwipeDescription' => 'انحنى إلى الأعلى أو إلى الأسفل على الحافة اليمنى لتعديل الحجم',
			'settings.gesturePinchToZoom' => 'إرسال رسالة إلى Zoom',
			'settings.gesturePinchToZoomDescription' => 'اضغط على الفيديو للزوم داخل أو خارج',
			'settings.gestureSeekSwipe' => 'البحث عن Swipe',
			'settings.gestureSeekSwipeDescription' => 'تحريك اليسار أو اليمين في أي مكان في الفيديو للبحث؛ إطلاق النار للقفز',
			'settings.rememberBrightnessLevel' => 'تذكر مستوى الضوء',
			'settings.rememberBrightnessLevelDescription' => 'بدء تشغيل على الضوء المحدد من قبل النسخ الأخير',
			'settings.controls' => 'عناصر التحكم',
			'settings.rememberPlayerChanges' => 'تذكر تغييرات اللاعبين',
			'settings.rememberPlayerChangesDescription' => 'حيث يتم حفظ التغيير الذي تم إجراؤه أثناء اللعب وإعادة التطبيق من',
			'settings.scopePlaybackSpeed' => 'سرعة التشغيل',
			'settings.scopeShaderPreset' => 'شاتر Preset',
			'settings.scopeAspectRatio' => 'نسبة العرض إلى الارتفاع',
			'settings.scopeSyncOffsets' => 'الصوت و Subtitle Sync',
			'settings.playerScopeOff' => 'لا ينقذ',
			'settings.playerScopeGlobal' => 'في كل مكان',
			'settings.playerScopeLibrary' => 'بواسطة المكتبة',
			'settings.playerScopeTitle' => 'من خلال عرض أو فيلم',
			'settings.exportDialogTitle' => 'تصدير PlezyNG إعدادات',
			'settings.followSystem' => 'اتباع لغة النظام',
			'settings.followAppLanguage' => 'مطابقة لغة الواجهة',
			'settings.regionFormat' => 'التنسيقات الإقليمية',
			'settings.regionFormatDescription' => 'اختر طريقة عرض التواريخ والأرقام ووحدات القياس.',
			'settings.metadataLanguage' => 'لغة بيانات الوسائط',
			'settings.metadataLanguageDescription' => 'لغة العناوين والأوصاف المفضلة عندما يدعمها الخادم. تُضبط تفضيلات الصوت والترجمة بشكل مستقل.',
			'settings.experimentalDolbyVision' => 'Dolby Vision التجريبي',
			'settings.experimentalDolbyVisionDescription' => 'استخدم عارض FEL التجريبي عند التشغيل التالي. يتطلب إصدارًا منفصلًا من المحرك.',
			'settings.dvExperimentUnavailableDescription' => 'هذه التجربة متاحة حاليًا على Linux فقط.',
			'settings.dvCompatibilityFallback' => 'الرجوع للتوافق',
			'settings.dvCompatibilityFallbackDescription' => 'استخدم العارض القياسي إذا تعذر بدء التجربة. قد تُفقد بيانات FEL.',
			'settings.dvExperimentDiagnostics' => 'تسجيل تجربة الفيديو',
			'settings.dvExperimentDiagnosticsDescription' => 'فعّل سجلات المشغّل التفصيلية عند التشغيل التالي.',
			'themeEditor.builtIn' => 'بناء في',
			'themeEditor.presets' => 'الكهنوت',
			'themeEditor.custom' => 'مخصص',
			'themeEditor.customEmpty' => 'لم يخلق بعد',
			'themeEditor.editCustom' => 'تحرير الموضوع المخصص',
			'themeEditor.editCustomDescription' => 'اختر كل لون بنفسك',
			'themeEditor.locked' => 'الوصول مدى الحياة مطلوب',
			'themeEditor.savedLocked' => 'تم توفيرها - متوفرة مع الوصول مدى الحياة',
			'themeEditor.title' => 'موضوع مخصص',
			'themeEditor.startFrom' => 'بدءاً من',
			'themeEditor.startFromDescription' => 'نسخ جميع الألوان من موضوع آخر',
			'themeEditor.colors' => 'الألوان',
			'themeEditor.preview' => 'معاينة',
			'themeEditor.slots.bg' => 'الخلفية',
			'themeEditor.slots.surface' => 'السطح',
			'themeEditor.slots.outline' => 'الخروج',
			'themeEditor.slots.text' => 'النص',
			'themeEditor.slots.textMuted' => 'النص الثانوي',
			'themeEditor.slots.accent' => 'التركيز',
			'themeEditor.opacity' => 'التواضع',
			'themeEditor.hexHint' => '#RRGGBB أو #AARRGGBB',
			'themeEditor.fromOtherThemes' => 'من مواضيع أخرى',
			'themeEditor.swatchLabel' => ({required Object theme, required Object color}) => '${theme} ${color}',
			'themeEditor.contrast.textOnBg' => 'النص على الخلفية',
			'themeEditor.contrast.textOnSurface' => 'النص على السطح',
			'themeEditor.contrast.textMutedOnBg' => 'النص الثانوي على الخلفية',
			'themeEditor.contrast.textMutedOnSurface' => 'النص الثانوي على السطح',
			'themeEditor.contrast.accentOnBg' => 'التركيز على الخلفية',
			'themeEditor.contrast.accentOnSurface' => 'التركيز على السطح',
			'themeEditor.contrast.labelOnAccent' => 'علامة الزر على التركيز',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}: 1، أقل من الموصى به ${minimum}:1',
			'themeEditor.discardTitle' => 'هل تتجاهل التغييرات؟',
			'themeEditor.discardMessage' => 'سيتم فقدان تغييرات اللون غير المحفوظة.',
			'themeEditor.discard' => 'ديكارد',
			'themeEditor.previewCardTitle' => ({required Object number}) => 'الحلقة ${number}',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => '${minutes} دقيقة متبقية',
			'themeEditor.previewSwitch' => 'التشغيل التلقائي',
			'themeEditor.previewMutedText' => 'النص الثانوي يقرأ هكذا',
			'search.hint' => 'البحث عن الأفلام، العروض، الموسيقى...',
			'search.tryDifferentTerm' => 'اختبر مصطلح بحث مختلف',
			'search.searchYourMedia' => 'البحث عن وسائل الإعلام الخاصة بك',
			'search.enterTitleActorOrKeyword' => 'أدخل عنوان أو ممثل أو كلمة مفتاحية',
			'search.people' => 'الأشخاص',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'إعداد القطع القصيرة لـ ${actionName}',
			'hotkeys.clearShortcut' => 'قصيرة واضحة',
			'hotkeys.noShortcutSet' => 'لا توجد مجموعة قصيرة',
			'hotkeys.currentShortcut' => 'القصير الحالي :',
			'hotkeys.pressToRecord' => 'اختار لتسجيل القصير',
			'hotkeys.recordingShortcut' => 'اضغط على القصير الآن',
			'hotkeys.actions.playPause' => 'لعبة / استراحة',
			'hotkeys.actions.volumeUp' => 'حجم الأعلى',
			'hotkeys.actions.volumeDown' => 'حجم أسفل',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'البحث إلى الأمام (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'البحث عن الخلفية (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'انضم إلى الشاشة الكاملة',
			'hotkeys.actions.muteToggle' => 'الموت معاً',
			'hotkeys.actions.subtitleToggle' => 'أضف تعليق حول Subtitles',
			'hotkeys.actions.audioTrackNext' => 'المقالة القادمةأودي تريك',
			'hotkeys.actions.subtitleTrackNext' => 'التالي Subtitle Track',
			'hotkeys.actions.chapterNext' => 'الفصل التالي',
			'hotkeys.actions.chapterPrevious' => 'الفصل السابق',
			'hotkeys.actions.episodeNext' => 'الحلقة التالية',
			'hotkeys.actions.episodePrevious' => 'الحلقة السابقة',
			'hotkeys.actions.speedIncrease' => 'زيادة السرعة',
			'hotkeys.actions.speedDecrease' => 'انخفاض السرعة',
			'hotkeys.actions.speedReset' => 'إعادة سرعة',
			'hotkeys.actions.zoomIn' => 'زوم في',
			'hotkeys.actions.zoomOut' => 'زوم الخروج',
			'hotkeys.actions.zoomReset' => 'إعادة تشغيل Zoom',
			'hotkeys.actions.subSeekNext' => 'البحث عن الموضوع التالي',
			'hotkeys.actions.subSeekPrev' => 'البحث عن العنوان السابق',
			'hotkeys.actions.subtitleDelayIncrease' => 'تأخير أسماء',
			'hotkeys.actions.subtitleDelayDecrease' => 'التقدم تحت عنوان',
			'hotkeys.actions.shaderToggle' => 'اشترك في الظلال',
			'hotkeys.actions.skipMarker' => 'إدخال / الائتمان',
			'hotkeys.actions.screenshot' => 'أخذ شاشة',
			'hotkeys.actions.framePrevious' => 'الإطار السابق',
			'hotkeys.actions.frameNext' => 'التالي إطار',
			'fileInfo.title' => 'ملف المعلومات',
			'fileInfo.overview' => 'نظرة عامة',
			'fileInfo.video' => 'مرئي',
			'fileInfo.audio' => 'الصوت',
			'fileInfo.subtitles' => 'الترجمة',
			'fileInfo.images' => 'صور مدمجة',
			'fileInfo.dataStreams' => 'تدفق البيانات',
			'fileInfo.lyrics' => 'الكلمات',
			'fileInfo.file' => 'ملف',
			'fileInfo.attachments' => 'الارتباطات',
			'fileInfo.delivery' => 'التسليم',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => 'النسخة ${index} من ${count}',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => 'ملف ${index} من ${count}',
			'fileInfo.noStreams' => 'لم يبلغ الخادم أي تدفقات لهذا الملف.',
			'fileInfo.copyPath' => 'نسخ المسار',
			'fileInfo.pathCopied' => 'مسار الملفات نسخة',
			'fileInfo.codec' => 'الترميز',
			'fileInfo.codecTag' => 'وسم الترميز',
			'fileInfo.resolution' => 'الدقة',
			'fileInfo.codedResolution' => 'القرار المعدل',
			'fileInfo.bitrate' => 'معدل البت',
			'fileInfo.frameRate' => 'إطار معدل',
			'fileInfo.rotation' => 'الدوران',
			'fileInfo.comment' => 'كيف',
			'fileInfo.audioDescription' => 'وصف الصوت',
			'fileInfo.headerCompression' => 'الرأس الضغط',
			'fileInfo.sidecarFile' => 'الملفات Sidecar',
			'fileInfo.transportTimestamp' => 'ساعات النقل',
			'fileInfo.displayOffset' => 'عرض Offset',
			'fileInfo.previewFailureCode' => 'كود الفشل السابق',
			'fileInfo.previewRetries' => 'التوقعات التراجع',
			'fileInfo.aspectRatio' => 'نسبة العرض إلى الارتفاع',
			'fileInfo.pixelAspectRatio' => 'نسبة Pixel Aspect',
			'fileInfo.profile' => 'الملف الشخصي',
			'fileInfo.level' => 'المستوى',
			'fileInfo.bitDepth' => 'عمق البت',
			'fileInfo.pixelFormat' => 'تنسيق البكسل',
			'fileInfo.colorSpace' => 'مساحة الألوان',
			'fileInfo.colorRange' => 'نطاق الألوان',
			'fileInfo.colorPrimaries' => 'الألوان الأساسية',
			'fileInfo.colorTransfer' => 'نقل الألوان',
			'fileInfo.chromaSubsampling' => 'كروم Subsampling',
			'fileInfo.chromaLocation' => 'موقع الكروم',
			'fileInfo.scanType' => 'نوع الفحص',
			'fileInfo.interlaced' => 'متشابك',
			'fileInfo.anamorphic' => 'مشوّه عدسيًا (Anamorphic)',
			'fileInfo.referenceFrames' => 'الإطار المرجعي',
			'fileInfo.dynamicRange' => 'نطاق ديناميكي',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Dolby Vision المستوى',
			'fileInfo.dolbyVisionVersion' => 'Dolby Vision النسخة',
			'fileInfo.dolbyVisionLayers' => 'Dolby Vision طبقات',
			'fileInfo.baseLayerCompatibility' => 'التوافق الأساسي',
			'fileInfo.avcBitstream' => 'تدفق بتات AVC',
			'fileInfo.nalLengthSize' => 'نال طول الحجم',
			'fileInfo.scalingMatrix' => 'المصفوفة المصفوفة المصفوفة',
			'fileInfo.streamIdentifier' => 'الهوية الهوية',
			'fileInfo.streamIndex' => 'مؤشر التدفق',
			'fileInfo.streamId' => 'معرّف التدفق',
			'fileInfo.language' => 'اللغة',
			'fileInfo.languageCode' => 'رمز اللغة',
			'fileInfo.streamTitle' => 'العنوان Track',
			'fileInfo.channels' => 'القنوات',
			'fileInfo.sampleRate' => 'معدل العينة',
			'fileInfo.spatialAudio' => 'الفضاء الصوت',
			'fileInfo.textBased' => 'النص القائم',
			'fileInfo.subtitleFormat' => 'صيغة',
			'fileInfo.provider' => 'المورد',
			'fileInfo.matchScore' => 'المباراة النتيجة',
			'fileInfo.externalDelivery' => 'يمكن تقديمها بشكل منفصل',
			'fileInfo.sidecarPath' => 'مسار سيديكار',
			'fileInfo.sourceStream' => 'نسخة من',
			'fileInfo.temporary' => 'مؤقتة',
			'fileInfo.timeBase' => 'قاعدة الزمن',
			'fileInfo.overallBitrate' => 'بطاقة كاملة',
			'fileInfo.path' => 'المسار',
			'fileInfo.fileName' => 'اسم الملف',
			'fileInfo.size' => 'الحجم',
			'fileInfo.totalSize' => 'الحجم الكلي',
			'fileInfo.container' => 'حاوية الملف الشخصي',
			'fileInfo.duration' => 'المدة',
			'fileInfo.previewThumbnails' => 'مسبق التمهيدات',
			'fileInfo.previewIndex' => 'مؤشر مقدمة',
			'fileInfo.packetLength' => 'طول الحزمة',
			'fileInfo.filePresent' => 'الملفات الحالية',
			'fileInfo.fileReadable' => 'قابلة للقراءة من قبل الخادم',
			'fileInfo.streamPath' => 'مسار التدفق',
			'fileInfo.optimizedForStreaming' => 'تحسينات البث',
			'fileInfo.has64bitOffsets' => '64 بت Offsets',
			'fileInfo.protocol' => 'البروتوكول',
			'fileInfo.mediaType' => 'نوع وسائل الإعلام',
			'fileInfo.sourceKind' => 'المصدر الصغير',
			'fileInfo.optimizedVersion' => 'النسخة المثلى',
			'fileInfo.optimizationTarget' => 'الهدف الأفضل',
			'fileInfo.deletedAt' => 'حذف',
			'fileInfo.remoteSource' => 'مصدر بعيد',
			'fileInfo.infiniteStream' => 'تدفق غير نهائي',
			'fileInfo.directPlay' => 'اللعب المباشر',
			'fileInfo.directStream' => 'البث المباشر',
			'fileInfo.transcoding' => 'تحويل الترميز',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'نسخة ID',
			'fileInfo.fileId' => 'ملف ID',
			'fileInfo.defaultAudioTrack' => 'أداة Audio Track',
			'fileInfo.defaultSubtitleTrack' => 'أدنى Subtitle Track',
			'fileInfo.subtitlesOff' => 'إيقاف',
			'fileInfo.flagDefault' => 'الافتراضي',
			'fileInfo.flagForced' => 'إجباري',
			'fileInfo.flagSelected' => 'اختياري',
			'fileInfo.flagExternal' => 'خارجي',
			'fileInfo.flagHearingImpaired' => 'سماع ضعيف',
			'fileInfo.flagDub' => 'دبي',
			'fileInfo.flagOriginal' => 'الأصلي',
			'fileInfo.channelsMono' => 'أحادي (Mono)',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'الملف الشخصي ${profile}',
			'mediaMenu.markAsWatched' => 'مارك كما شاهدت',
			'mediaMenu.markAsUnwatched' => 'مارك غير ملاحظة',
			'mediaMenu.removeFromContinueWatching' => 'إزالة من مواصلة مراقبة',
			'mediaMenu.viewDetails' => 'انظر التفاصيل',
			'mediaMenu.goToSeries' => 'اذهب إلى سلسلة',
			'mediaMenu.shufflePlay' => 'لعبة Shuffle Play',
			'mediaMenu.shuffleNotAvailableOffline' => 'لا توجد متاجر غير متوفرة offline',
			'mediaMenu.fileInfo' => 'ملف المعلومات',
			'mediaMenu.deleteEpisodeFromServer' => 'إزالة الحلقة من الخادم',
			'mediaMenu.deleteSeasonFromServer' => 'إزالة الموسم من الخادم',
			'mediaMenu.deleteShowFromServer' => 'إزالة العرض من الخادم',
			'mediaMenu.deleteMovieFromServer' => 'حذف الفيلم من الخادم',
			'mediaMenu.deleteEpisodeTitle' => 'إلغاء هذا الحدث؟',
			'mediaMenu.deleteSeasonTitle' => 'إلغاء الموسم؟',
			'mediaMenu.deleteShowTitle' => 'إلغاء هذا العرض؟',
			'mediaMenu.deleteMovieTitle' => 'هل تريد حذف هذا الفيلم؟',
			'mediaMenu.deleteEpisodeConfirm' => 'حذف الحلقة',
			'mediaMenu.deleteSeasonConfirm' => 'فصل القضاء',
			'mediaMenu.deleteShowConfirm' => 'إزالة عرض',
			'mediaMenu.deleteMovieConfirm' => 'حذف الفيلم',
			'mediaMenu.deleteAnyway' => 'إزالة على أي حال',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => 'إزالة ${title} بشكل دائم من خادمك؟',
			'mediaMenu.deleteMultipleWarning' => 'هذا يشمل جميع الحلقات وملفاتها.',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: 'لن تُحذف أي حلقات.', one: 'سيُحذف جميع محتواها: حلقة واحدة وملفها.', two: 'سيُحذف جميع محتواها: حلقتان وملفاهما.', few: 'ستُحذف جميع الحلقات الموجودة فيها وعددها ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} حلقات، مع ملفاتها.', many: 'ستُحذف جميع الحلقات الموجودة فيها وعددها ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} حلقة، مع ملفاتها.', other: 'ستُحذف جميع الحلقات الموجودة فيها وعددها ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} حلقة، مع ملفاتها.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: 'لا توجد ملفات لهذا العنصر.', one: 'هذا العنصر محفوظ في ملف واحد سيُحذف.', two: 'هذا العنصر محفوظ في ملفين سيُحذفان.', few: 'هذا العنصر موزّع على ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ملفات، وستُحذف كلها.', many: 'هذا العنصر موزّع على ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ملفًا، وستُحذف كلها.', other: 'هذا العنصر موزّع على ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ملف، وستُحذف كلها.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: 'لا توجد حلقات أخرى في الملف نفسه.', one: 'توجد حلقة أخرى في الملف نفسه وستُحذف أيضًا:', two: 'توجد حلقتان أخريان في الملف نفسه وستُحذفان أيضًا:', few: 'توجد ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} حلقات أخرى في الملف نفسه وستُحذف أيضًا:', many: 'توجد ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} حلقة أخرى في الملف نفسه وستُحذف أيضًا:', other: 'توجد ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} حلقة أخرى في الملف نفسه وستُحذف أيضًا:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'تعذّر على PlezyNG التحقق من الملفات التي سيحذفها هذا الإجراء، لذلك قد يحذف أكثر من العنصر المذكور أعلاه. ألغِ الإجراء وحاول مجددًا، أو اختر الحذف على أي حال.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'لم يقدّم خادمك تفاصيل ملفات هذا العنصر، لذلك لا يستطيع PlezyNG التحقق من الملفات التي سيحذفها هذا الإجراء. قد تُحذف ملفات تتجاوز العنصر المذكور أعلاه.',
			'mediaMenu.mediaDeletedSuccessfully' => 'تم حذف منتجات وسائل الإعلام بنجاح',
			'mediaMenu.mediaFailedToDelete' => 'فشل في حذف موضوع وسائل الإعلام',
			'mediaMenu.rate' => 'المعدل',
			'mediaMenu.playFromBeginning' => 'تشغيل من البداية',
			'mediaMenu.playVersion' => 'اللعب نسخة...',
			'rateSheet.title' => 'المعدل',
			'rateSheet.server' => 'الخادم',
			'rateSheet.favorite' => 'مفضل',
			'rateSheet.favorited' => 'المفضلة',
			'rateSheet.saved' => 'حفظه',
			'rateSheet.notAvailable' => 'لا توجد مباراة',
			'rateSheet.noConnectedServices' => 'قم بتوصيل خدمة في الإعدادات لتقييمها هناك.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}، فيلم',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}، مسلسل تلفزيوني',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'شوهد',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => 'تمت مشاهدة ${percent} بالمئة',
			'accessibility.mediaCardUnwatched' => 'لم تتم مشاهدته',
			'accessibility.tapToPlay' => 'اضغط للتشغيل',
			'accessibility.decrease' => 'انخفاض',
			'accessibility.increase' => 'زيادة',
			'accessibility.decreaseValue' => ({required Object label}) => 'انخفاض ${label}',
			'accessibility.increaseValue' => ({required Object label}) => 'زيادة ${label}',
			'accessibility.hue' => 'هوي',
			'accessibility.saturation' => 'التسمية',
			'accessibility.brightness' => 'الضوء',
			'accessibility.hexColor' => 'لون Hex',
			'accessibility.expandText' => 'توسيع النص',
			'accessibility.collapseText' => 'كسر النص',
			'accessibility.alphabetNavigation' => 'الأبجدية الملاحة',
			'accessibility.alphabetScrollHint' => 'مرّر لأعلى أو لأسفل للتنقل حسب الحرف',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'الصف ${row} من ${rowCount}، العمود ${column} من ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'صف ${row} من ${rowCount}',
			'accessibility.autoScrollPlay' => 'لعبة Auto-Scroll',
			'accessibility.autoScrollPause' => 'استراحة السيارات',
			'accessibility.hueShort' => 'H',
			'accessibility.saturationShort' => 'S',
			'accessibility.valueShort' => 'في',
			'accessibility.red' => 'أحمر',
			'accessibility.green' => 'أخضر',
			'accessibility.blue' => 'أزرق',
			'accessibility.redShort' => 'R',
			'accessibility.greenShort' => 'G',
			'accessibility.blueShort' => 'ب',
			'accessibility.colorModeHsv' => 'HSV',
			'accessibility.colorModeRgb' => 'RGB',
			'accessibility.title' => 'إمكانية الوصول',
			'accessibility.summary' => 'النص والتباين والحركة وعناصر التحكم',
			'accessibility.systemHint' => 'تظل إعدادات إمكانية الوصول في جهازك سارية دائمًا. تضيف هذه الخيارات تعديلات في جميع أنحاء PlezyNG.',
			'accessibility.readability' => 'القراءة والرؤية',
			'accessibility.textSize' => 'تكبير إضافي للنص',
			'accessibility.preview' => 'اعثر على قصتك التالية. اقرأ واستمع وشاهد بالوتيرة التي تناسبك.',
			'accessibility.boldText' => 'نص واجهة عريض',
			'accessibility.highContrast' => 'تباين عالٍ',
			'accessibility.highContrastHint' => 'نص وحدود ومؤشرات تركيز أوضح على الأسطح الفاتحة أو الداكنة.',
			'accessibility.interaction' => 'الحركة والتفاعل',
			'accessibility.reduceMotion' => 'تقليل الحركة',
			'accessibility.reduceMotionHint' => 'إيقاف حركة التركيز وانتقالات الصفحات والمؤثرات الزخرفية.',
			'accessibility.largeTargets' => 'مساحات لمس أكبر',
			'accessibility.largeTargetsHint' => 'توفير مساحة أوسع لعناصر التحكم المشتركة للمس والتنقل باستخدام التقنيات المساعدة.',
			'accessibility.navigationHint' => 'استخدم Tab وShift+Tab للتنقل بين عناصر التحكم، وEnter أو مفتاح المسافة لتفعيلها، وEscape أو زر الرجوع للإغلاق. تتوفر خيارات التكبير وتفضيلات القراءة أثناء فتح الكتاب.',
			'tooltips.shufflePlay' => 'لعبة Shuffle',
			'tooltips.playTrailer' => 'لعبة تريلر',
			'tooltips.markAsWatched' => 'مارك كما شاهدت',
			'tooltips.markAsUnwatched' => 'مارك غير ملاحظة',
			'audioTracks.track' => ({required Object n}) => 'سياق الصوت ${n}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} إطار', one: 'إطار واحد', two: 'إطاران', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} إطارات', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} إطار', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} إطار', ), 
			'videoControls.audioLabel' => 'الصوت',
			'videoControls.subtitlesLabel' => 'الترجمة',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => 'الكتب',
			'videoControls.fillScreen' => 'ملء الشاشة',
			'videoControls.stretch' => 'تمديد',
			'videoControls.lockRotation' => 'قفل الدوران',
			'videoControls.unlockRotation' => 'إلغاء الدوران',
			'videoControls.timerActive' => 'التوقيت النشط',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'لعبة Playback تتوقف في ${duration}',
			'videoControls.sleepTimerEndOfVideo' => 'نهاية الفيديو الحالي',
			'videoControls.sleepTimerStopAtHeader' => 'توقف عن',
			'videoControls.sleepTimerDurationHeader' => 'تيمير',
			'videoControls.playbackWillPauseAtEnd' => 'لعبة Playback ستتوقف في نهاية هذا الفيديو',
			'videoControls.stillWatching' => 'لا يزال ينظر؟',
			'videoControls.pausingIn' => ({required Object seconds}) => 'استراحة في ${seconds}s',
			'videoControls.continueWatching' => 'مواصلة',
			'videoControls.autoPlayNext' => 'اللعب التالي',
			'videoControls.playNext' => 'تشغيل التالي',
			'videoControls.playButton' => 'تشغيل',
			'videoControls.pauseButton' => 'إيقاف مؤقت',
			'videoControls.playbackPaused' => 'استراحة',
			'videoControls.playbackResumed' => 'اللعب',
			'videoControls.loadingVideo' => 'تحميل الفيديو',
			'videoControls.showPlaybackControls' => 'عرض التحكم في playback',
			'videoControls.hidePlaybackControls' => 'إخفاء التحكم في playback',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'البحث إلى الوراء ${seconds} ثانية',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'البحث إلى الأمام ${seconds} ثانية',
			'videoControls.previousButton' => 'الحلقة السابقة',
			'videoControls.nextButton' => 'الحلقة التالية',
			'videoControls.previousChapterButton' => 'الفصل السابق',
			'videoControls.nextChapterButton' => 'الفصل التالي',
			'videoControls.muteButton' => 'كتم الصوت',
			'videoControls.unmuteButton' => 'إلغاء كتم الصوت',
			'videoControls.settingsButton' => 'إعدادات Playback',
			'videoControls.tracksButton' => 'الأصوات & الأصوات',
			'videoControls.trackSelectionTitle' => 'اختيار المسارات قبل اللعب',
			'videoControls.trackSelectionAuto' => 'الاختيار التلقائي',
			'videoControls.chaptersButton' => 'الفصول',
			'videoControls.versionQualityButton' => 'النسخة والجودة',
			'videoControls.versionColumnHeader' => 'الإصدار',
			'videoControls.qualityColumnHeader' => 'الجودة',
			'videoControls.qualityOriginal' => 'الأصلي',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} ميغابايت في الثانية',
			'videoControls.transcodeUnavailableFallback' => 'التشفير غير متوفر - لعب الجودة الأصلية',
			'videoControls.subtitleUnavailableFallback' => 'العناوين الفرعية المختارة لا يمكن تحميلها - الاستمرار دون العناوين الفرعية',
			'videoControls.pipButton' => 'وضع التصوير في الصورة',
			'videoControls.aspectRatioButton' => 'نسبة العرض إلى الارتفاع',
			'videoControls.ambientLighting' => 'الإضاءة البيئية',
			'videoControls.fullscreenButton' => 'إدخال الشاشة الكاملة',
			'videoControls.exitFullscreenButton' => 'الخروج الشاشة الكاملة',
			'videoControls.alwaysOnTopButton' => 'دائماً في الأعلى',
			'videoControls.rotationLockButton' => 'قفل الدوران',
			'videoControls.lockScreen' => 'شاشة قفل',
			'videoControls.screenLockButton' => 'قفل الشاشة',
			'videoControls.longPressToUnlock' => 'طويل الضغط لإلغاء القفل',
			'videoControls.timelineSlider' => 'لعبة الفيديو',
			'videoControls.volumeSlider' => 'حجم المستوى',
			'videoControls.endsAt' => ({required Object time}) => 'النهاية في ${time}',
			'videoControls.pipActive' => 'فيديوهات متعلقة بـ “ Picture in Picture ”',
			'videoControls.pipFailed' => 'صورة في الصورة فشلت في البدء',
			'videoControls.screenshotSaved' => 'صورة شاشة تم حفظها',
			'videoControls.screenshotFailed' => 'لا أستطيع التقاط صورة شاشة',
			'videoControls.zoomPercent' => ({required Object percent}) => 'التكبير ${percent}%',
			'videoControls.volumePercent' => ({required Object percent}) => 'مستوى الصوت ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'مطلوب Android 8.0 أو أحدث',
			'videoControls.pipErrors.iosVersion' => 'مطلوب iOS 15.0 أو أحدث',
			'videoControls.pipErrors.permissionDisabled' => 'تم تعطيل صورة في صورة، وتتمكن من ذلك في إعدادات النظام.',
			'videoControls.pipErrors.notSupported' => 'الجهاز لا يدعم وضع الصورة في الصورة',
			'videoControls.pipErrors.voSwitchFailed' => 'فشل في تحويل إخراج الفيديو إلى صورة في صورة',
			'videoControls.pipErrors.failed' => 'صورة في الصورة فشلت في البدء',
			'videoControls.pipErrors.prepareFailed' => 'لا يمكن إعداد صورة في الصورة',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'حدث خطأ: ${error}',
			'videoControls.chapters' => 'الفصول',
			'videoControls.noChaptersAvailable' => 'لا توجد فصول متاحة',
			'videoControls.queue' => 'كوي',
			'videoControls.noQueueItems' => 'لا توجد عناصر في كوشنر',
			'videoControls.noAudioDevicesAvailable' => 'لا توجد أجهزة صوتية متاحة',
			'videoControls.searchSubtitles' => 'البحث تحت عنوان',
			'videoControls.loadSubtitleFile' => 'تحميل ملف Subtitle',
			'videoControls.subtitleLoadFailed' => 'فشل في تحميل ملف Subtitle',
			'videoControls.language' => 'اللغة',
			'videoControls.noSubtitlesFound' => 'لا توجد عناوين',
			'videoControls.subtitleDownloaded' => 'Subtitle تحميل',
			'videoControls.subtitleDownloadedNotApplied' => 'Subtitle downloaded ولكن لم يتم اختيارها',
			'videoControls.subtitleDownloadFailed' => 'فشل في تنزيل Subtitle',
			'videoControls.searchLanguages' => 'البحث عن اللغات ..',
			'videoControls.skipIntro' => 'سكاي إنترو',
			'videoControls.skipCredits' => 'سكاي الائتمان',
			'videoControls.skipAds' => 'إعلانات Skip',
			'videoControls.nextEpisode' => 'الحلقة التالية',
			'videoControls.subtitleTrack' => ({required Object n}) => 'مسار ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => 'موضوع ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (مجبرة)',
			'videoControls.osdSubtitlesOff' => 'العنوان الأصلي: Off',
			'videoControls.osdSubtitles' => ({required Object track}) => 'الأرقام التالية: ${track}',
			'videoControls.osdAudio' => ({required Object track}) => 'الصوت: ${track}',
			'messages.markedAsWatched' => 'علامة كما تم مشاهدتها',
			'messages.markedAsUnwatched' => 'علامة غير مسبوقة',
			'messages.markedAsWatchedOffline' => 'علامة كما تم مشاهدتها (سيتم مزامنة عند الإنترنت)',
			'messages.markedAsUnwatchedOffline' => 'علامة غير مسبوقة (سيتم مزامنة عند الانترنت)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'إزالة السيارة: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: 'لم تُزل أي تنزيلات تمت مشاهدتها', one: 'أُزيل تنزيل واحد تمت مشاهدته تلقائيًا', two: 'أُزيل تنزيلان تمت مشاهدتهما تلقائيًا', few: 'أُزيلت ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} تنزيلات تمت مشاهدتها تلقائيًا', many: 'أُزيل ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} تنزيلًا تمت مشاهدته تلقائيًا', other: 'أُزيل ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} تنزيل تمت مشاهدته تلقائيًا', ), 
			'messages.removedFromContinueWatching' => 'إزالة من مواصلة مراقبة',
			'messages.errorLoading' => ({required Object error}) => 'الخطأ: ${error}',
			'messages.searchPartialResults' => 'بعض خوادم الوسائط لا يمكن البحث عنها.عرض النتائج المتاحة.',
			'messages.streamInterrupted' => 'تم إيقاف التدفق.الضغط يلعب أو يحاول الانسحاب.',
			'messages.liveStreamInterrupted' => 'تم إيقاف البث المباشر.الضغط يلعب إلى الانسحاب.',
			'messages.fileInfoNotAvailable' => 'معلومات الملفات غير متوفرة',
			'messages.playbackAuthenticationRequired' => 'اشترك في خادم الوسائط مرة أخرى للعب هذا العنصر.',
			'messages.playbackServerUnavailable' => 'لا يوجد خادم وسائل الإعلام، حاول مرة أخرى في وقت لاحق.',
			'messages.playbackDataInvalid' => 'وقد أعاد الخادم معلومات التدوين غير المباشرة.',
			'messages.playbackCancelled' => 'تم إلغاء Playback',
			'messages.playbackFailed' => 'لا يمكن بدء اللعب.',
			'messages.playbackFailedDetail' => ({required Object error}) => 'لا يمكن بدء تشغيل Playback: ${error}',
			'messages.audioOutputFailed' => 'تحقق من اتصال الصوت التلفزيون أو المستلم ؛ إذا لم تكن التطبيقات الأخرى أي صوت ، قم بإعادة تشغيل الجهاز.',
			'messages.mediaUnavailable' => 'هذا المحتوى لم يعد متاحا.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'أخطاء تحميل ملف المعلومات: ${error}',
			'messages.errorLoadingSeries' => 'خطأ سلسلة تحميل',
			'messages.musicNotSupported' => 'لم يتم دعم Playback الموسيقي بعد',
			'messages.noDescriptionAvailable' => 'لا توجد وصفات متاحة',
			'messages.noProfilesAvailable' => 'لا توجد ملفات تعريف متاحة',
			'messages.contactAdminForProfiles' => 'اتصل بمدير الخادم لإضافة ملفات تعريف',
			'messages.unableToDetermineLibrarySection' => 'غير قادر على تحديد قسم المكتبة لهذا العنصر',
			'messages.logsCleared' => 'اللوحات المطهرة',
			'messages.logsCopied' => 'سجلات نسخة إلى clipboard',
			'messages.noLogsAvailable' => 'لا توجد سجلات متاحة',
			'messages.libraryScanning' => ({required Object title}) => 'فحص "${title}" ...',
			'messages.libraryScanStarted' => ({required Object title}) => 'بدأت فحص المكتبة لـ "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'فشل في فحص المكتبة: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'إعادة تدوير البيانات الميتاتية لـ "${title}" ...',
			_ => null,
		} ?? switch (path) {
			'messages.metadataRefreshStarted' => ({required Object title}) => 'بدأ تحديث البيانات الميتة لـ "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'لا يمكن تحديث البيانات الميتا: ${error}',
			'messages.logoutConfirm' => 'هل أنت متأكد من أنك تريد الانسحاب؟',
			'messages.noSeasonsFound' => 'لا توجد مواسم',
			'messages.seasonsLoadFailed' => 'لا أستطيع تحميل الموسم',
			'messages.noEpisodesFound' => 'لا توجد أحداث في الموسم الأول',
			'messages.noEpisodesFoundGeneral' => 'لم يتم العثور على أحداث',
			'messages.episodesLoadFailed' => 'لا يمكن تحميل الحوادث',
			'messages.noResultsFound' => 'لم يتم العثور على نتائج.',
			'messages.sleepTimerSet' => ({required Object label}) => 'ساعة النوم المحددة ${label}',
			'messages.noItemsAvailable' => 'لا توجد عناصر متاحة',
			'messages.failedToCreatePlayQueueNoItems' => 'فشل في إنشاء لعبة - لا عناصر',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'فشل في ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'التبديل إلى لاعب متوافق ...',
			'messages.serverLimitTitle' => 'لعبة Playback فاشلة',
			'messages.serverLimitBody' => 'خطأ الخادم (HTTP 500). قد يرفض هذا الجلسة حد نطاق النطاق / التشفير.',
			'messages.mediaUnreadableTitle' => 'ملف غير متوفر',
			'messages.mediaUnreadableBody' => 'وجد الخادم هذا العنصر ولكن لم يكن قادرا على قراءة ملفها (HTTP 404). تم نقل الملف على الأرجح، وحذف، أو تخزين غير متصل.',
			'messages.serverBusyTitle' => 'البث غير متوفر',
			'messages.serverBusyBody' => 'لا يزال الخادم يرفض بث هذا الملف (HTTP 503).قد يكون إعادة تشغيل، مشغول، أو قد يكون تخزين الملف غير متصل.حاول مرة أخرى في لحظة - إذا كان لا يزال يحدث، اطلب من مالك الخادم التحقق من الخادم وتخزين الملف.',
			'messages.playbackNotAllowedTitle' => 'لا يسمح لـ Playback',
			'messages.playbackNotAllowedBody' => 'رفض الخادم بث هذا العنصر (HTTP 403). قد لا يملك حسابك صلاحية تشغيله، أو قد يسمح الخادم بالتشغيل على شبكته المحلية فقط.',
			'messages.logsUploaded' => 'Logs تحميل',
			'messages.logsUploadFailed' => 'فشل في تحميل اللوحات',
			'messages.logId' => 'معرّف السجل',
			'messages.burnedSubtitlesUseMenu' => 'يتم حرق العناوين في هذا التدفق.تغييرها من قائمة العناوين.',
			'messages.noVideoUrl' => 'لا توجد URL الفيديو المتاحة',
			'messages.playbackNoMediaSources' => 'الخادم لم يعيد أي مصادر وسائل الإعلام المباشرة',
			'messages.playbackDataNotPrepared' => 'بدأت Playback قبل أن تكون بياناتها جاهزة',
			'messages.streamSelectionUnavailable' => 'لا توجد خيارات البث المتاحة لهذا المصدر',
			'messages.streamSelectionFailed' => 'لا يستطيع أن يستخدم التدفقات المختارة',
			'messages.trackSelectionNotRemembered' => 'هذا الاختيار المسار ينطبق فقط على اللعب الحالي.',
			'messages.serverUnavailableForProfile' => 'لا يوجد خادم متاح للملف النشط',
			'subtitlingStyling.previewSample' => 'الفوركس البني السريع يقفز فوق الكلب القبيح',
			'subtitlingStyling.text' => 'النص',
			'subtitlingStyling.border' => 'الحدود',
			'subtitlingStyling.background' => 'الخلفية',
			'subtitlingStyling.fontSize' => 'حجم الصورة',
			'subtitlingStyling.textColor' => 'لون النص',
			'subtitlingStyling.borderSize' => 'الحدود حجم',
			'subtitlingStyling.borderColor' => 'اللون الحدودي',
			'subtitlingStyling.backgroundOpacity' => 'الخلفية Opacity',
			'subtitlingStyling.backgroundColor' => 'خلفية اللون',
			'subtitlingStyling.position' => 'موقف',
			'subtitlingStyling.assOverride' => 'ASS مبالغة',
			'subtitlingStyling.overrideScale' => 'مقياس',
			'subtitlingStyling.overrideForce' => 'القوة',
			'subtitlingStyling.overrideStrip' => 'إزالة التصميم',
			'subtitlingStyling.positionTop' => 'أعلى',
			'subtitlingStyling.positionBottom' => 'أسفل',
			'subtitlingStyling.useMargins' => 'استخدم المارغين',
			'subtitlingStyling.useMarginsDescription' => 'السماح للقبول النصية في الفضاء خارج الفيديو.القبول النصية يمكن أن تحافظ على وضعها الأصلي.',
			'subtitlingStyling.anchorToScreen' => 'Anchor إلى الشاشة',
			'subtitlingStyling.anchorToScreenDescription' => 'عرض العناوين الفرعية النصية في الشرائح السوداء أدناه فيديو الشاشة العريضة',
			'subtitlingStyling.bold' => 'غامق',
			'subtitlingStyling.italic' => 'إيطاليا',
			'subtitlingStyling.renderResolution' => 'رينتر القرار',
			'subtitlingStyling.renderResolutionScreen' => 'دقة الشاشة',
			'subtitlingStyling.renderResolutionVideo' => 'دقة الفيديو',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'إعدادات مشغل الفيديو المتقدمة',
			'mpvConfig.presets' => 'الكهنوت',
			'mpvConfig.noPresets' => 'لا توجد سلاحات',
			'mpvConfig.saveAsPreset' => 'الحفاظ على كونك...',
			'mpvConfig.presetName' => 'الاسم السابق',
			'mpvConfig.presetNameHint' => 'أدخل اسمًا لهذا المجلد',
			'mpvConfig.loadPreset' => 'تحميل',
			'mpvConfig.deletePreset' => 'حذف',
			'mpvConfig.presetSaved' => 'النصر ينقذ',
			'mpvConfig.presetLoaded' => 'محرك محرك',
			'mpvConfig.presetDeleted' => 'إلغاء Preset',
			'mpvConfig.confirmDeletePreset' => 'هل أنت متأكد من أنك ترغب في إزالة هذا التوقيع؟',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan hwdec=auto # التعليق',
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => 'إضافة خط',
			'mpvConfig.removeLine' => 'إزالة الخط',
			'mpvConfig.embeddedVoHint' => 'يتم تجاهل vo، gpu-context و gpu-api على Linux: فيديو مدمج دائما يخرج من خلال vo=libmpv على مقطع الفيديو، و gpu-next (الذي يحتاج الظلال الحاسوبية مثل ArtCNN) لا يمكن تشغيل مدمج.',
			'dialog.confirmAction' => 'تأكيد العملية',
			'profiles.addPlezyProfile' => 'إضافة PlezyNG ملف تعريف',
			'profiles.switchingProfile' => 'تبادل الملفات ...',
			'profiles.deleteThisProfileTitle' => 'إزالة هذا الملف الشخصي؟',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'إزالة ${displayName}.الاتصالات لا تتأثر.',
			'profiles.active' => 'نشطة',
			'profiles.manage' => 'إدارة',
			'profiles.delete' => 'حذف',
			'profiles.signOut' => 'تسجيل الخروج',
			'profiles.signOutPlexTitle' => 'تسجيل الدخول من Plex؟',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'إزالة ${displayName} وجميع Plex المستخدمين المنزليين؟ تسجيل الدخول في أي وقت.',
			'profiles.signOutPlexDeleteDownloads' => 'إزالة أيضًا تحميل',
			'profiles.signOutPlexDeleteDownloadsDescription' => 'وإلا فإنهم يبقون على هذا الجهاز ويعودون عندما تقوم بتسجيل الدخول مرة أخرى إلى هذا الحساب.',
			'profiles.signedOutPlex' => 'تم توقيعها من Plex.',
			'profiles.signOutFailed' => 'تسجيل فشل',
			'profiles.sectionTitle' => 'الملفات',
			'profiles.summarySingle' => 'إضافة ملفات تعريف لخلط المستخدمين المديرين والهوية المحلية',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} ملفات تعريف · نشطة: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} ملفات تعريف',
			'profiles.removeConnectionTitle' => 'إزالة الاتصال ؟',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'إزالة صلاحية وصول ${displayName} إلى ${connectionLabel}. تحتفظ الملفات الشخصية الأخرى بصلاحية الوصول.',
			'profiles.deleteProfileTitle' => 'إزالة الملف الشخصي؟',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'إزالة ${displayName} و اتصالاتها.الخوادم تبقى متاحة.',
			'profiles.profileNameLabel' => 'اسم الملف الشخصي',
			'profiles.pinProtectionLabel' => 'حماية PIN',
			'profiles.copyAutomationLink' => 'نسخة Android اتصال الأتمتة',
			'profiles.copyAutomationLinkDescription' => 'حدد هذا الملف الشخصي من إرادة Android أو الأتمتة.',
			'profiles.automationLinkCopied' => 'نسخ ملف تعريف الأتمتة.',
			'profiles.pinManagedByPlex' => 'قاعدة PIN التي تديرها Plex. Edit on plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'لا إعداد PIN.للتطلب واحد، تحرير المستخدم المنزلي على plex.tv.',
			'profiles.setPin' => 'إعداد PIN',
			'profiles.setPinTitle' => 'إعداد PIN',
			'profiles.confirmPinTitle' => 'تأكيد PIN',
			'profiles.pinSet' => 'إعداد PIN',
			'profiles.changePin' => 'التغيير',
			'profiles.removePin' => 'إزالة',
			'profiles.connectionsLabel' => 'الاتصالات',
			'profiles.add' => 'إضافة',
			'profiles.deleteProfileButton' => 'حذف الملف الشخصي',
			'profiles.noConnectionsHint' => 'لا توجد اتصالات - أضف واحد لاستخدام هذا الملف الشخصي.',
			'profiles.noConnections' => 'لا اتصالات',
			'profiles.plexHomeAccount' => 'Plex الحساب المنزلي',
			'profiles.plexAccountChip' => ({required Object account}) => 'Plex حساب: ${account}',
			'profiles.plexAccountUserChip' => ({required Object user, required Object account}) => '${user} عن طريق ${account}',
			'profiles.connectionDefault' => 'الافتراضي',
			'profiles.connectionAs' => ({required Object displayName}) => 'رقم ${displayName}',
			'profiles.makeDefault' => 'إلغاء الافتراض',
			'profiles.removeConnection' => 'إزالة',
			'profiles.profileRenamed' => 'إعادة تسمية الملف الشخصي',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'إضافة إلى ${displayName}',
			'profiles.borrowExplain' => 'قروض اتصال ملف تعريف آخر.الملفات المحمية PIN تتطلب PIN.',
			'profiles.borrowEmpty' => 'لا شيء للاستئجار بعد.',
			'profiles.borrowEmptySubtitle' => 'اتصل Plex أو Jellyfin أو Emby إلى ملف تعريف آخر أولاً.',
			'profiles.borrowLoadFailed' => 'لا يمكن تحميل الاتصالات المتاحة.محاولة مرة أخرى.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'من ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'اتصال مستأجر',
			'profiles.borrowFailed' => 'فشل في الحصول على اتصال القرض.',
			'profiles.incorrectPin' => 'خطأ في PIN',
			'profiles.incorrectPinTryAgain' => 'إلغاء الخطأ، يرجى المحاولة مرة أخرى.',
			'profiles.sourceProfileMissingParentAccount' => 'الملف الشخصي يفتقر إلى حساب الوالدين.',
			'profiles.failedToLoadHomeUsers' => 'لا يمكن تحميل Plex المستخدمين المنزليين.تحقق من اتصالك ومحاولة مرة أخرى.',
			'profiles.failedToVerifyPin' => 'فشل في التحقق من PIN.',
			'profiles.newProfile' => 'ملف تعريف جديد',
			'profiles.profileNameHint' => 'ضيوف، أطفال، غرفة عائلية',
			'profiles.pinProtectionOptional' => 'حماية PIN (اختياري)',
			'profiles.pinExplain' => '4-الأرقام PIN مطلوب لتغيير الملفات.',
			'profiles.continueButton' => 'مواصلة',
			'profiles.pinsDontMatch' => 'PINs لا تتطابق',
			'profiles.tokenIdentityMismatch' => 'Plex سجل الملف الشخصي تم حلها إلى خادم غير متوقع',
			'profiles.settingsLocked' => 'يتم إغلاق الإعدادات لهذا الملف.',
			'profiles.unlockSettings' => 'إلغاء الإعدادات',
			'profiles.showExploreForProfile' => 'عرض البحث لهذا الملف الشخصي',
			'profiles.showExploreForProfileDescription' => 'انقر فوق إزالة Explore من الملاحة في هذا الملف الشخصي.',
			'connections.sectionTitle' => 'الاتصالات',
			'connections.addConnection' => 'إضافة اتصال',
			'connections.addConnectionSubtitleNoProfile' => 'تسجيل الدخول مع Plex أو الاتصال بخادم Jellyfin أو Emby',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'إضافة إلى ${displayName}: Plex، Jellyfin، Emby، أو أي اتصال ملف تعريف آخر',
			'connections.sessionExpiredOne' => ({required Object name}) => 'الجلسة انتهت لـ ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'انتهاء الجلسة لـ ${count} خادم',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} رفض الوصول إلى هذا الحساب',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} الخوادم رفضت الوصول إلى هذا الحساب',
			'connections.signInAgain' => 'اكتب مرة أخرى',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'تحرير ${product} الاتصال',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'إضافة أو إزالة عناوين URL لـ ${serverName}. PlezyNG سوف تستخدم عناوين URL المتاحة مع أدنى تأخير.',
			'accountPreferences.sectionTitle' => 'تفضيلات الحساب',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => 'تم حفظ خيارات الصوت والعنوان والمكتبة على ${account}',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => 'تم حفظ خيارات الصوت والعنوان والمكتبة على حسابات ${count}',
			'accountPreferences.pickAccount' => 'كل حساب يحفظ تفضيلاته الخاصة.اختر واحد لتحرير.',
			'accountPreferences.storedOnAccount' => 'يتم حفظ هذه الخيارات على الحساب نفسه، لذلك يستخدمها كل تطبيق تم تسجيله إليه – بما في ذلك PlezyNG على أجهزتك الأخرى.',
			'accountPreferences.noAccounts' => 'لا حسابات لتحديد',
			'accountPreferences.noAccountsHint' => 'تسجيل الدخول إلى Plex، أو الاتصال بخادم Jellyfin أو Emby، وتظهر التفضيلات المخزنة على هذا الحساب هنا.',
			'accountPreferences.unavailable' => 'لا يمكن الوصول إلى هذا الحساب',
			'accountPreferences.loadFailed' => 'لا يمكن تحميل هذه التفضيلات',
			'accountPreferences.noPreference' => 'لا تفضيلات',
			'accountPreferences.notSet' => 'لا تضع',
			'accountPreferences.groups.audioAndSubtitles' => 'الأصوات و الأصوات',
			'accountPreferences.groups.libraryDisplay' => 'المكتبة',
			'accountPreferences.groups.personalMedia' => 'وسائل الإعلام الشخصية',
			'accountPreferences.preferredAudioLanguage' => 'لغة الصوت المفضلة',
			'accountPreferences.autoSelectAudio' => 'اختيار الصوت حسب اللغة',
			'accountPreferences.autoSelectAudioDescription' => 'يبقى خارج أي صوت تتبع الملفات علامات الافتراضية.',
			'accountPreferences.preferredSubtitleLanguage' => 'لغة الترجمة المفضلة',
			'accountPreferences.subtitleMode' => 'تحويل العناوين إلى',
			'accountPreferences.subtitleModes.none' => 'اختياري يدويا',
			'accountPreferences.subtitleModes.noneDescription' => 'لا تحول أبداً العناوين الخاصة بك.',
			'accountPreferences.subtitleModes.defaultMode' => 'اتبع العلم المقطع',
			'accountPreferences.subtitleModes.defaultModeDescription' => 'استخدم الأعلام الافتراضية والقسرية المخزنة على كل مسار تحت عنوان.',
			'accountPreferences.subtitleModes.always' => 'إمكانية دائما',
			'accountPreferences.subtitleModes.alwaysDescription' => 'قم بتحريك مسار العنوان الفرعي في اللغة المفضلة في كل مرة يوجد فيها.',
			'accountPreferences.subtitleModes.onlyForced' => 'مجرد العناوين القسرية',
			'accountPreferences.subtitleModes.onlyForcedDescription' => 'تحميل فقط المسارات المحددة كإجبار.',
			'accountPreferences.subtitleModes.smart' => 'عرض مع الصوت الأجنبي',
			'accountPreferences.subtitleModes.smartDescription' => 'تحويل العناوين الفرعية فقط عندما يكون الصوت في لغة أخرى.',
			'accountPreferences.subtitleAccessibility' => 'SDH أسماء',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'أضف تعليق حول غير SDH subtitles',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'أولاً: أحب أرقام SDH',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'مجرد عناوين SDH',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'مجرد أسماء غير SDH',
			'accountPreferences.forcedSubtitles' => 'القبض على العناوين',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'أولاً: عدم إجبار العناوين',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'تفضيل القواعد القسرية',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'مجرد العناوين القسرية',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'فقط العناوين غير القسرية',
			'accountPreferences.displayMissingEpisodes' => 'عرض الحوادث المفقودة',
			'accountPreferences.displayMissingEpisodesDescription' => 'قائمة الحوادث التي يعرفها الخادم ولكن ليس لديه أي ملف.',
			'accountPreferences.hidePlayedInLatest' => 'إخفاء العناصر التي تمت مشاهدتها في الأخير',
			'accountPreferences.hidePlayedInLatestDescription' => 'اترك العناصر التي شاهدتها بالفعل من آخر صفوف الخادم.',
			'accountPreferences.displayCollectionsView' => 'عرض عرض المجموعات',
			'accountPreferences.displayCollectionsViewDescription' => 'عرض مجموعات الخادم بجانب المكتبات الخاصة بك.',
			'accountPreferences.rewatchingInNextUp' => 'إعادة النظر في العروض في Next Up',
			'accountPreferences.rewatchingInNextUpDescription' => 'بمجرد الانتهاء من العرض ، ابدأ من جديد و Next Up يتابع إعادة النظر بدلاً من إسقاط العرض.',
			'accountPreferences.watchedIndicator' => 'المؤشرات المراقبة',
			'accountPreferences.watchedIndicatorOptions.none' => 'أبدًا',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => 'الأفلام والتلفزيون',
			'accountPreferences.watchedIndicatorOptions.movies' => 'الأفلام فقط',
			'accountPreferences.watchedIndicatorOptions.shows' => 'عرض التلفزيون فقط',
			'accountPreferences.mediaReviewsVisibility' => 'تصنيفات & مراجعات',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'المستخدمين والنقاد',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'المستخدمين فقط',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'انتقادات فقط',
			'accountPreferences.mediaReviewsOptions.nobody' => 'مخفية',
			'discover.title' => 'اكتشاف',
			'discover.noContentAvailable' => 'لا محتوى متاح',
			'discover.addMediaToLibraries' => 'إضافة بعض وسائل الإعلام إلى مكتباتك',
			'discover.continueWatching' => 'متابعة المشاهدة',
			'discover.continueWatchingIn' => ({required Object library}) => 'مواصلة مشاهدة في ${library}',
			'discover.nextUp' => 'القادم',
			'discover.nextUpIn' => ({required Object library}) => 'التالي في ${library}',
			'discover.recentlyAdded' => 'أُضيف حديثًا',
			'discover.recentlyAddedIn' => ({required Object library}) => 'أضيف مؤخرا في ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => 'أحدث الألبومات في ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'اللعب مؤخرا في ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'الأكثر لعبًا في ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'م${season} ح${episode}',
			'discover.overview' => 'نظرة عامة',
			'discover.cast' => 'كاست',
			'discover.findNext.title' => 'العثور على التالي',
			'discover.findNext.open' => 'العثور على التالي',
			'discover.findNext.anyTime' => 'أي وقت',
			'discover.findNext.timeAvailable' => 'كم من الوقت لديك؟',
			'discover.findNext.filters' => 'واختر اللحظة',
			'discover.findNext.watch' => 'مشاهدة',
			'discover.findNext.listen' => 'الاستماع',
			'discover.findNext.read' => 'قراءة',
			'discover.findNext.finishable' => ({required Object duration}) => 'انتهاء في ${duration}',
			'discover.findNext.aboutDuration' => ({required Object duration}) => 'حول ${duration}',
			'discover.findNext.nextUnit' => ({required Object duration}) => 'الفصل التالي · ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => '${duration} كاملة',
			'discover.findNext.timingVaries' => 'التوقيت يختلف',
			'discover.findNext.notNow' => 'لا الآن',
			'discover.findNext.swipeHint' => 'تحريك أو استخدام الأزرار أدناه',
			'discover.findNext.saved' => 'النقابات المحفوظة',
			'discover.findNext.savedCount' => ({required Object count}) => 'كلمات متعلقة ${count}',
			'discover.findNext.undo' => 'وواو',
			'discover.findNext.details' => 'تفاصيل',
			'discover.findNext.noPicks' => 'لا شيء يختاره حتى الآن',
			'discover.findNext.noPicksHint' => 'قم بتوصيل مكتبة أو إضافة مصدر وسائل الإعلام للبدء.',
			'discover.findNext.noMatches' => 'لا شيء يناسب هذه اللحظة',
			'discover.findNext.noMatchesHint' => 'حاول تنسيق آخر أو أعط نفسك المزيد من الوقت.',
			'discover.findNext.allDone' => 'أنتم جميعا تم القبض عليكم',
			'discover.findNext.allDoneHint' => 'ابدأ مزيجًا جديدًا لرؤية هذه الخيارات مرة أخرى.',
			'discover.findNext.refresh' => 'العثور على مزيج آخر',
			'discover.findNext.sourceReason' => ({required Object source}) => 'من ${source}',
			'discover.findNext.libraryReason' => ({required Object library}) => 'من ${library}',
			'discover.findNext.ownedReason' => 'من مكتبتك',
			'discover.findNext.liveNow' => 'على الآن',
			'discover.findNext.watchLive' => 'مشاهدة live',
			'discover.findNext.filterAnything' => 'كل شيء',
			'discover.findNext.filterWatch' => 'مشاهدة',
			'discover.findNext.filterListen' => 'الاستماع',
			'discover.findNext.filterRead' => 'قراءة',
			'discover.findNext.twentyMinutes' => '20 دقيقة',
			'discover.findNext.fortyFiveMinutes' => '45 دقيقة',
			'discover.findNext.ninetyMinutes' => '90 دقيقة',
			'discover.findNext.apply' => 'تطبيق',
			'discover.findNext.openFailed' => 'هذا الخيار لم يعد متاحا.تجديد للتحقق مرة أخرى.',
			'discover.findNext.changeFailed' => 'لا أستطيع أن أحفظ هذا التغيير، حاول مرة أخرى.',
			'discover.findNext.savedLimit' => 'النقاط التي تم حفظها كاملة.إزالة اختيار واحد لإنقاذ آخر.',
			'discover.extras' => 'تريلر و إضافات',
			'discover.studio' => 'الاستوديو',
			'discover.rating' => 'تصنيف',
			'discover.director' => 'المخرج',
			'discover.directors' => 'المخرجون',
			'discover.movie' => 'فيلم',
			'discover.tvShow' => 'عرض التلفزيون',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} دقيقة متبقية',
			'discover.moreLikeThis' => 'مشابه لهذا',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} عنوان', one: 'عنوان واحد', two: 'عنوانان', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} عناوين', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} عنوان', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} عنوان', ), 
			'discover.person.born' => 'ولدت',
			'discover.person.died' => 'الموت',
			'discover.person.birthplace' => 'مكان الميلاد',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date} (العمر ${age})',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date} (العمر ${age})',
			'errors.searchFailed' => ({required Object error}) => 'البحث فشل: ${error}',
			'errors.searchUnavailable' => 'لم تتمكن البحث من الوصول إلى أي خادم وسائل الإعلام.',
			'errors.connectionTimeout' => ({required Object context}) => 'اتصال الوقت أثناء التحميل ${context}',
			'errors.connectionFailed' => 'عدم القدرة على الاتصال بـ Media Server',
			'errors.unableToLoad' => ({required Object context}) => 'لا يمكن تحميل ${context}. يرجى المحاولة مرة أخرى.',
			'errors.noClientAvailable' => 'لا يوجد عميل متاح',
			'errors.pleaseEnterToken' => 'يرجى إدخال علامة',
			'errors.invalidToken' => 'الرموز المعاقبة',
			'errors.failedToVerifyToken' => ({required Object error}) => 'عدم التحقق من الرموز: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'لم يتم تحويلها إلى ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'لم يتم حذف ${displayName}',
			'errors.failedToRate' => 'لا يمكن تحديث التصنيف',
			'errors.reasonTimedOut' => 'اتصال موقت',
			'errors.reasonUnreachable' => 'لا يمكن الوصول إلى الخادم',
			'errors.reasonRefused' => 'ورفض الخادم الطلب',
			'errors.reasonNotFound' => 'لم يعد العنصر على الخادم',
			'errors.reasonServerError' => 'الخادم يحدد خطأ',
			'errors.reasonCancelled' => 'تم إلغاء الطلب',
			'errors.reasonUnexpected' => 'حدث خطأ غير متوقع',
			'libraries.playRandomMovie' => 'لعب فيلم عشوائي',
			'libraries.randomPickFailed' => 'لا يمكن أن تختار فيلم عشوائي من هذه المكتبة.',
			'libraries.title' => 'المكتبات',
			'libraries.fallbackTitle' => 'المكتبة',
			'libraries.scanLibraryFiles' => 'فحص المكتبة الملفات',
			'libraries.scanLibrary' => 'فحص المكتبة',
			'libraries.analyze' => 'تحليل',
			'libraries.analyzeLibrary' => 'تحليل المكتبة',
			'libraries.refreshMetadata' => 'تحديث البيانات الوصفية',
			'libraries.emptyTrash' => 'الفراغ الفراغ',
			'libraries.emptyingTrash' => ({required Object title}) => 'إزالة القمامة لـ "${title}" ...',
			'libraries.trashEmptied' => ({required Object title}) => 'أضف تعليق حول "${title}"',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'الفشل في إزالة القمامة الفارغة: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'تحليل "${title}" ...',
			'libraries.analysisStarted' => ({required Object title}) => 'بدأت التحليلات لـ "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'فشل في تحليل المكتبة: ${error}',
			'libraries.noLibrariesFound' => 'لا توجد مكتبات',
			'libraries.allLibrariesHidden' => 'جميع المكتبات مخفية',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'المكتبات الخفية (${count})',
			'libraries.thisLibraryIsEmpty' => 'هذه المكتبة فارغة',
			'libraries.noItemsMatchFilters' => 'لا تتوافق العناصر مع الفلاتر النشطة',
			'libraries.resetFilters' => 'إعادة تعيين الفلاتر',
			'libraries.all' => 'الكل',
			'libraries.clearAll' => 'واضحة كل',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'هل أنت متأكد من أنك تريد مسح "${title}"؟',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'هل أنت متأكد من أنك تريد تحليل "${title}"؟',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'هل أنت متأكد من أنك تريد تحديث البيانات الميتا لـ "${title}"؟',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'هل أنت متأكد من أنك تريد إفراغ القمامة لـ "${title}"؟',
			'libraries.manageLibraries' => 'إدارة المكتبات',
			'libraries.sort' => 'ترتيب',
			'libraries.sortBy' => 'ترتيب حسب',
			'libraries.filters' => 'الفلاتر',
			'libraries.confirmActionMessage' => 'هل أنت متأكد من أنك ترغب في تنفيذ هذا العمل؟',
			'libraries.showLibrary' => 'عرض المكتبة',
			'libraries.hideLibrary' => 'إخفاء المكتبة',
			'libraries.libraryOptions' => 'خيارات المكتبة',
			'libraries.content' => 'مكتبة المحتوى',
			'libraries.selectLibrary' => 'اختيار المكتبة',
			'libraries.filtersWithCount' => ({required Object count}) => 'الفلاتر (${count})',
			'libraries.noRecommendations' => 'لا توجد توصيات متاحة',
			'libraries.noCollections' => 'لا توجد مجموعات في هذه المكتبة',
			'libraries.noFoldersFound' => 'لا توجد ملفات',
			'libraries.folders' => 'المجلدات',
			'libraries.tabs.recommended' => 'الموصى بها',
			'libraries.tabs.browse' => 'استعراض',
			'libraries.tabs.collections' => 'المجموعات',
			'libraries.tabs.playlists' => 'قوائم التشغيل',
			'libraries.groupings.title' => 'مجموعة',
			'libraries.groupings.all' => 'الكل',
			'libraries.groupings.movies' => 'الأفلام',
			'libraries.groupings.shows' => 'مسلسلات تلفزيونية',
			'libraries.groupings.seasons' => 'المواسم',
			'libraries.groupings.episodes' => 'الحلقات',
			'libraries.groupings.artists' => 'الفنانون',
			'libraries.groupings.albums' => 'الألبومات',
			'libraries.groupings.tracks' => 'المسارات',
			'libraries.groupings.folders' => 'المجلدات',
			'libraries.filterCategories.genre' => 'النوع',
			'libraries.filterCategories.year' => 'السنة',
			'libraries.filterCategories.contentRating' => 'تصنيف المحتوى',
			'libraries.filterCategories.tag' => 'وسم',
			'libraries.filterCategories.unwatched' => 'غير ملاحظة',
			'libraries.filterCategories.unplayed' => 'غير مُشغّل',
			'libraries.filterCategories.favorites' => 'المفضلة',
			'libraries.filterCategories.filePath' => 'مسار الملفات',
			'libraries.sortLabels.title' => 'العنوان',
			'libraries.sortLabels.dateAdded' => 'تاريخ الإضافة',
			'libraries.sortLabels.releaseDate' => 'تاريخ الإصدار',
			'libraries.sortLabels.rating' => 'تصنيف',
			'libraries.sortLabels.communityRating' => 'تقييم المجتمع',
			'libraries.sortLabels.criticRating' => 'التصنيف الحرص',
			'libraries.sortLabels.userRating' => 'تصنيف المستخدم',
			'libraries.sortLabels.datePlayed' => 'تاريخ التشغيل',
			'libraries.sortLabels.playCount' => 'عدد مرات التشغيل',
			'libraries.sortLabels.productionYear' => 'سنة الإنتاج',
			'libraries.sortLabels.runtime' => 'مدة التشغيل',
			'libraries.sortLabels.officialRating' => 'التصنيف الرسمي',
			'libraries.sortLabels.premiereDate' => 'تاريخ العرض الأول',
			'libraries.sortLabels.startDate' => 'تاريخ البدء',
			'libraries.sortLabels.airTime' => 'وقت العرض',
			'libraries.sortLabels.studio' => 'الاستوديو',
			'libraries.sortLabels.random' => 'عشوائي',
			'libraries.sortLabels.dateShared' => 'التاريخ المشترك',
			'libraries.sortLabels.latestEpisodeAirDate' => 'آخر الحلقة تاريخ الهواء',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'الحلقة الأخيرة إضافات',
			'libraries.sortLabels.dateDownloaded' => 'تاريخ تنزيل',
			'libraries.sortLabels.size' => 'الحجم',
			'libraries.sortLabels.library' => 'المكتبة',
			'libraries.advancedFilters.include' => 'إدراج',
			'libraries.advancedFilters.exclude' => 'استبعاد',
			'libraries.advancedFilters.any' => 'أي',
			'libraries.advancedFilters.yes' => 'نعم',
			'libraries.advancedFilters.no' => 'لا',
			'libraries.advancedFilters.not' => ({required Object value}) => 'لا ${value}',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '${count} تم اختيارها',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '${count} استبعاد',
			'libraries.advancedFilters.searchValues' => 'قيمة البحث',
			'libraries.advancedFilters.noValues' => 'لا قيمة',
			'libraries.advancedFilters.matchContains' => 'حاوية',
			'libraries.advancedFilters.matchNotContains' => 'لا يحتوي على',
			'libraries.advancedFilters.matchIs' => 'هو',
			'libraries.advancedFilters.matchIsNot' => 'لا يوجد',
			'libraries.advancedFilters.matchBeginsWith' => 'يبدأ مع',
			'libraries.advancedFilters.matchEndsWith' => 'تنتهي مع',
			'libraries.advancedFilters.textHint' => 'النوع إلى المطابقة',
			'libraries.advancedFilters.from' => 'من',
			'libraries.advancedFilters.to' => 'إلى',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from} إلى ${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value} وأعلى',
			'libraries.advancedFilters.atMost' => ({required Object value}) => 'تصل إلى ${value}',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => 'آخر ${count} أيام',
			'libraries.advancedFilters.dateLastYear' => 'العام الماضي',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => 'أقدم من ${count} أيام',
			'libraries.advancedFilters.dateOlderThanYear' => 'أكبر من سنة واحدة',
			'libraries.selection.selectItems' => 'اختيار العناصر',
			'libraries.selection.selectedCount' => ({required Object count}) => '${count} تم اختيارها',
			'libraries.selection.actions' => 'إجراءات الاختيار',
			'libraries.selection.confirmDescendants' => 'هذا يغير جميع الحلقات في العروض والموسم المحدد.',
			'libraries.selection.confirmUnwatched' => 'يؤدي هذا أيضًا إلى مسح تقدّم التشغيل للعناصر المحددة.',
			'libraries.selection.confirmCount' => ({required Object count}) => 'العناصر المختارة: ${count}.',
			'libraries.selection.completed' => ({required Object count}) => 'تحديث العناصر: ${count}.',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => 'تحديث ${succeeded}؛ فشل ${failed}. لا تزال العناصر المفقودة مختارة.',
			'about.title' => 'حول',
			'about.openSourceLicenses' => 'ترخيص المصدر المفتوح',
			'about.versionLabel' => ({required Object version}) => 'النسخة ${version}',
			'about.appDescription' => 'عميل جميل Plex و Jellyfin و Emby لـ Flutter',
			'about.viewLicensesDescription' => 'عرض ترخيص المكتبات من طرف ثالث',
			'about.privacyPolicy' => 'سياسة الخصوصية',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'لا توجد خوادم تم العثور عليها في ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'الخوادم التي لم يتم تحميلها: ${error}',
			'serverSelection.noValidServers' => 'لم يتم العثور على خادمات قابلة للاستخدام في هذا الحساب',
			'hubDetail.title' => 'العنوان',
			'hubDetail.releaseYear' => 'إطلاق السنة',
			'hubDetail.dateAdded' => 'تاريخ الإضافة',
			'hubDetail.rating' => 'تصنيف',
			'hubDetail.noItemsFound' => 'لا توجد عناصر',
			'logs.clearLogs' => 'سجلات واضحة',
			'logs.copyLogs' => 'نسخة Logs',
			'logs.uploadLogs' => 'تحميل اللوحات',
			'logs.saveLogs' => 'حفظ اللوحات إلى الملفات',
			'logs.logsSaved' => ({required Object path}) => 'تسجيل الدخول إلى ${path}',
			'logs.saveLogsFailed' => 'لا أستطيع حفظ ملف السجل.',
			'detail.endsAt' => ({required Object time}) => 'النهاية في ${time}',
			'startup.failedTitle' => 'PlezyNG لا يمكن أن تبدأ',
			'startup.failedBody' => 'حدث شيء خاطئ أثناء بدء التشغيل، وتحدد التفاصيل أدناه ما فشلت.',
			'startup.failedBodyRepairable' => 'ملف إعدادات PlezyNG المحفوظ تالف ويجب إعادة إنشائه قبل بدء التطبيق. لن تفيد إعادة المحاولة؛ اختر إصلاح التخزين.',
			'startup.phaseLabel' => 'خطوة',
			'startup.showDetails' => 'عرض التفاصيل',
			'startup.hideDetails' => 'إخفاء التفاصيل',
			'startup.copyDetails' => 'نسخ التفاصيل',
			'startup.detailsCopied' => 'تفاصيل نسخها إلى clipboard',
			'startup.uploadDetails' => 'تحميل التفاصيل',
			'startup.repairStorage' => 'إصلاح التخزين',
			'startup.repairTitle' => 'إصلاح البيانات المخزنة؟',
			'startup.repairBodyCommon' => 'ملف إعدادات PlezyNG تالف ولا يمكن قراءته. تؤدي عملية الإصلاح إلى إعادة جميع الإعدادات إلى قيمها الافتراضية.',
			'startup.repairBodyOneCredential' => 'تلفت بيانات إحدى عمليات تسجيل الدخول المحفوظة ولا يمكن قراءتها. يحذف الإصلاح هذه البيانات فقط، وتبقى إعداداتك الأخرى دون تغيير.',
			'startup.repairBodySignInsKept' => 'يجب أن تبقى خادماتك وملفاتك الشخصية مسجلة.',
			'startup.repairBodySignInsLost' => 'لا يمكن استعادة المفتاح الذي يحمي بيانات تسجيل الدخول المحفوظة من هذا الملف، لذلك ستحتاج إلى تسجيل الدخول إلى كل خادم وملف شخصي مجددًا. لن يتأثر أي شيء على خادم الوسائط.',
			'startup.repairBodySessionsUncertain' => 'تُحفظ بيانات خدمات التتبع (MAL وAniList وSimkl وTrakt) وSeerr بشكل منفصل، وقد تبقى أو تُفقد. سيُطلعك PlezyNG على البيانات التي احتفظ بها بالضبط.',
			'startup.repairConfirm' => 'إصلاح',
			'startup.repairSucceeded' => 'التخزين إصلاح',
			'startup.repairNeedsRestart' => 'التخزين إصلاح - إعادة تشغيل مطلوب',
			'startup.restartRequiredBody' => 'تم إصلاح بياناتك، لكن يجب إعادة تشغيل PlezyNG قبل استخدامها. أغلق PlezyNG وافتحه مجددًا.',
			'startup.quitPlezy' => 'إلغاء PlezyNG',
			'startup.repairFailed' => 'إصلاح فشل',
			'startup.repairKeptSignIns' => 'لا يزال الخوادم والملفات الشخصية الخاصة بك مسجلة.',
			'startup.repairLostSignIns' => 'لا يمكن استرداد المفتاح الذي يحمي تسجيلاتك المحفوظة.سوف تحتاج إلى تسجيل الدخول إلى كل خادم وملف تعريف مرة أخرى.',
			'startup.repairLostSessions' => 'فُقد اتصال واحد على الأقل بخدمة تتبّع أو بخدمة Seerr، ويجب إعادة الاتصال به.',
			'startup.backupTitle' => 'تم الحفاظ على نسخة من الملف المتضرر',
			'startup.backupWarning' => 'تحتوي هذه النسخة على بيانات تسجيل الدخول الخاصة بك. لا ترفعها أو تشاركها.',
			'startup.deleteBackup' => 'حذف النسخة',
			'startup.backupDeleted' => 'نسخة حذف',
			'startup.previousFailureTitle' => 'PlezyNG فشل في البدء للمرة الأخيرة',
			'licenses.relatedPackages' => 'الحزم ذات الصلة',
			'licenses.license' => 'الترخيص',
			'licenses.licenseNumber' => ({required Object number}) => 'الترخيص ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} ترخيص',
			'navigation.libraries' => 'المكتبات',
			'navigation.downloads' => 'التنزيلات',
			'navigation.liveTv' => 'البث التلفزيوني المباشر',
			'navigation.explore' => 'استكشاف',
			'explore.mdblistShelves.manage' => 'البحث عن المراحيض',
			'explore.mdblistShelves.manageDescription' => 'اختيار وترتيب القوائم من حسابك MDBList',
			'explore.mdblistShelves.description' => 'اختر قوائم الأفلام والتلفزيون العامة من حسابك MDBList.إنشاء أو نسخ القوائم على MDBList, ثم تجديد.',
			'explore.mdblistShelves.selected' => 'المراحيض المختارة',
			'explore.mdblistShelves.available' => 'قائمة الحسابات المتاحة',
			'explore.mdblistShelves.noLists' => 'لا يتم إرجاع أي أفلام عامة أو قوائم تلفزيونية.إنشاء أو نسخ قائمة على MDBList، ثم تحديث.',
			'explore.mdblistShelves.displayName' => 'اسم شاشة Shelf',
			'explore.mdblistShelves.nameHint' => 'اترك فارغا لاستخدام اسم قائمة المصدر.',
			'explore.mdblistShelves.add' => 'إضافة شيلف',
			'explore.mdblistShelves.save' => 'احفظ السترات',
			'explore.mdblistShelves.moveUp' => ({required Object title}) => 'تحريك ${title} إلى الأعلى',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => 'تحريك ${title} إلى أسفل',
			'explore.mdblistShelves.unavailable' => 'هذه القائمة غير متوفرة.إزالة أو إزالة الستار في الإعدادات.',
			'explore.mdblistShelves.rateLimited' => 'MDBList حد الطلب قد وصل، يرجى الانسحاب في وقت لاحق.',
			'explore.mdblistShelves.loadFailed' => 'لا يمكن تحميل الشرائح.تحقق من الاتصال الخاص بك والانسحاب.',
			'explore.mdblistShelves.saveFailed' => 'لا أستطيع أن أحفظ الستائر، يرجى التراجع.',
			'explore.mdblistShelves.accountChanged' => 'تم تغيير حسابك أو ملفك الشخصي.إعادة فتح هذه الإعدادات.',
			'explore.mdblistShelves.settingsUnreadable' => 'لا يمكن قراءة الشرائح المحفوظة.اختر القوائم مرة أخرى لاستبدال هذه الإعدادات.',
			'explore.title' => 'استكشاف',
			'explore.selectSource' => 'اختيار المصدر',
			'explore.rows.watchlist' => 'قائمة مراقبة',
			'explore.rows.recommendedMovies' => 'الأفلام الموصى بها',
			_ => null,
		} ?? switch (path) {
			'explore.rows.recommendedShows' => 'العروض الموصى بها',
			'explore.rows.trendingMovies' => 'أفلام متطورة',
			'explore.rows.trendingShows' => 'عرض الاتجاهات',
			'explore.rows.popularMovies' => 'أفلام شعبية',
			'explore.rows.popularShows' => 'العروض الشعبية',
			'explore.rows.trendingAnime' => 'انيمات الاتجاهات',
			'explore.rows.suggestedAnime' => 'انيمو الموصى بها',
			'explore.rows.airingAnime' => 'أعلى الهواء Anime',
			'explore.rows.popularAnime' => 'الأنيمي الأكثر شعبية',
			'explore.rows.trending' => 'الاتجاهات',
			'explore.rows.upcomingMovies' => 'الأفلام القادمة',
			'explore.rows.upcomingShows' => 'العروض القادمة',
			'explore.status.airing' => 'الهواء',
			'explore.status.ended' => 'انتهى',
			'explore.status.canceled' => 'إلغاء',
			'explore.status.upcoming' => 'التالي',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} حلقة', one: 'حلقة واحدة', two: 'حلقتان', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} حلقات', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} حلقة', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} حلقة', ), 
			'explore.cast' => 'كاست',
			'explore.characters' => 'شخصيات',
			'explore.addToWatchlist' => 'إضافة إلى Watchlist',
			'explore.removeFromWatchlist' => 'إزالة من Watchlist',
			'explore.addedToWatchlist' => 'إضافة إلى Watchlist',
			'explore.removedFromWatchlist' => 'إزالة من قائمة المشاهدين',
			'explore.watchlistUpdateFailed' => 'لا أستطيع تحديث قائمة المشاهدين',
			'explore.watchlistNoMatch' => 'لا يمكن أن تتطابق هذه العنصر مع قائمة مراقبة',
			'explore.notInLibrary' => 'لا في مكتبتك',
			'explore.inTheseLibraries' => 'في هذه المكتبات',
			'explore.checkingLibrary' => 'فحص مكتبتك ..',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: 'تعذر فحص أي خادم', one: 'تعذر فحص خادم واحد', two: 'تعذر فحص خادمين', few: 'تعذر فحص ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} خوادم', many: 'تعذر فحص ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} خادمًا', other: 'تعذر فحص ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} خادم', ), 
			'explore.emptyTitle' => 'لا شيء هنا حتى الآن',
			'explore.emptyMessage' => ({required Object source}) => 'سيتم عرض الأقواس من ${source} هنا بمجرد أن يكون لديهم محتوى.',
			'explore.searchHint' => ({required Object source}) => 'البحث ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'لا توجد نتائج لـ "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'البحث عن الأفلام والأحداث على ${source}.',
			'explore.searchFailed' => 'فشل البحث، تحقق من اتصالك ومحاولة مرة أخرى.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} شعبية',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} الهواء',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} تقييم',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} الاتجاهات',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} في ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} مشاهدة',
			'explore.badge.available' => 'متاح',
			'explore.badge.partiallyAvailable' => 'المتاحة جزئيا',
			'explore.badge.availableIn4k' => '4K متوفر',
			'explore.badge.requested' => 'المطالبة',
			'explore.badge.pendingApproval' => 'الموافقة المتوقعة',
			'explore.badge.processing' => 'المعالجة',
			'explore.badge.declined' => 'انخفاض',
			'explore.badge.requestFailed' => 'طلب فشل',
			'explore.badge.requested4k' => '4K طلب',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} الموسم',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => 'Ep ${episode} في ${duration}',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'التالي في ${duration}',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} إبس',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} دقيقة/أب',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} مكتوبة',
			'explore.stats.viewersDay' => ({required Object n}) => '${n} مشاهدة اليوم',
			'explore.stats.viewersWeek' => ({required Object n}) => '${n} مشاهدة هذا الأسبوع',
			'explore.stats.viewersMonth' => ({required Object n}) => '${n} مشاهدة هذا الشهر',
			'explore.stats.viewersYear' => ({required Object n}) => '${n} مشاهدة هذا العام',
			'explore.stats.viewersAllTime' => ({required Object n}) => '${n} المشاهدين',
			'explore.stats.planning' => ({required Object n}) => '${n} التخطيط لمشاهدة',
			'explore.stats.favorited' => ({required Object n}) => '${n} المفضلة',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} ألغيت',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} تعليق', one: 'تعليق واحد', two: 'تعليقان', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} تعليقات', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} تعليق', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} تعليق', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} صوت',
			'explore.stats.watching' => ({required Object n}) => '${n} مشاهدة',
			'explore.stats.completed' => ({required Object n}) => '${n} إكمال',
			'explore.stats.onHold' => ({required Object n}) => '${n} على الحصن',
			'explore.stats.dropped' => ({required Object n}) => '${n} انخفاض',
			'explore.season.winter' => 'الشتاء',
			'explore.season.spring' => 'الربيع',
			'explore.season.summer' => 'الصيف',
			'explore.season.fall' => 'سقوط',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'تلفاز',
			'explore.format.tvShort' => 'التلفزيون القصير',
			'explore.format.movie' => 'فيلم',
			'explore.format.special' => 'خاصة',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => 'الموسيقى',
			'explore.format.other' => 'أخرى',
			'explore.sourceMaterial.original' => 'الأصلي',
			'explore.sourceMaterial.manga' => 'مانغا',
			'explore.sourceMaterial.lightNovel' => 'الضوء رواية',
			'explore.sourceMaterial.novel' => 'روائي',
			'explore.sourceMaterial.visualNovel' => 'الرواية البصرية',
			'explore.sourceMaterial.game' => 'لعبة',
			'explore.sourceMaterial.webComic' => 'WEB الكوميديا',
			'explore.sourceMaterial.musicRelease' => 'الموسيقى',
			'explore.sourceMaterial.otherMedia' => 'أخرى',
			'explore.creditRole.actor' => 'ممثل',
			'explore.creditRole.director' => 'المخرج',
			'explore.creditRole.writer' => 'الكاتب',
			'explore.creditRole.producer' => 'المنتج',
			'explore.creditRole.creator' => 'المنشئ',
			'explore.creditRole.composer' => 'الملحن',
			'explore.relation.prequel' => 'البروتوكول',
			'explore.relation.sequel' => 'السلسلة',
			'explore.relation.sideStory' => 'قصة الجانب',
			'explore.relation.spinOff' => 'عمل مشتق',
			'explore.relation.alternativeVersion' => 'النسخة البديلة',
			'explore.relation.summary' => 'ملخص',
			'explore.relation.parentStory' => 'قصة الوالدين',
			'explore.relation.adaptation' => 'التكيف',
			'explore.relation.other' => 'مرتبطة',
			'explore.broadcast' => ({required Object day, required Object time}) => 'Airs ${day} عند ${time}',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => 'Airs ${day} عند ${time} ${timezone}',
			'explore.detail.originalTitle' => 'العنوان الأصلي',
			'explore.detail.alsoKnownAs' => 'المعروف أيضًا باسم',
			'explore.detail.studios' => 'الاستوديوهات',
			'explore.detail.country' => 'البلد',
			'explore.detail.language' => 'اللغة',
			'explore.detail.released' => 'إطلاق سراح',
			'explore.detail.physicalRelease' => 'على القرص',
			'explore.detail.ended' => 'انتهى',
			'explore.detail.addedOn' => ({required Object date}) => 'أضيف ${date}',
			'explore.detail.yourRating' => 'تصنيفك',
			'explore.detail.budget' => 'الميزانية',
			'explore.detail.revenue' => 'مكتب البوكس',
			'explore.detail.contentAdvisory' => 'العمر التوجيه',
			'explore.detail.tags' => 'الوسوم',
			'explore.detail.revealSpoilerTags' => 'عرض العلامات spoiler',
			'explore.detail.links' => 'اليمين',
			'explore.detail.watchOn' => 'انظر إلى',
			'explore.detail.watchTrailer' => 'مشاهدة trailer',
			'explore.detail.openOn' => ({required Object site}) => 'مفتوحة على ${site}',
			'explore.detail.crew' => 'الطاقم',
			'explore.detail.ratings' => 'تصنيف',
			'explore.detail.schedule' => 'جدولة',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: 'لا توجد توصيات من المستخدمين', one: 'أوصى به مستخدم واحد', two: 'أوصى به مستخدمان', few: 'أوصى به ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مستخدمين', many: 'أوصى به ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مستخدمًا', other: 'أوصى به ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مستخدم', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'الموصى بها من قبل ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'المفضلة بواسطة ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} لم يتم نشره بعد',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'الموصى بها من قبل ${percent} من المشاهدين',
			'explore.detail.relatedTitles' => 'العناوين ذات الصلة',
			'explore.detail.background' => 'الخلفية',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} نتيجة', one: 'نتيجة واحدة', two: 'نتيجتان', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} نتائج', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} نتيجة', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} نتيجة', ), 
			'liveTv.title' => 'البث التلفزيوني المباشر',
			'liveTv.guide' => 'الدليل',
			'liveTv.noChannels' => 'لا توجد قنوات متاحة',
			'liveTv.noDvr' => 'لا يوجد DVR متوفر على أي خادم',
			'liveTv.serverUnavailable' => 'لا يوجد خادم تلفزيون مباشر.',
			'liveTv.serverNotConnected' => 'خادم التلفزيون المباشر غير متصل.',
			'liveTv.noPrograms' => 'لا توجد بيانات البرنامج المتاحة',
			'liveTv.liveStreamFailed' => 'البث المباشر فشل',
			'liveTv.unknownProgram' => 'برنامج غير معروف',
			'liveTv.timelineLiveProgram' => 'البرنامج الحي (يمكن أن يكون اللعب خارج هذا البرنامج)',
			'liveTv.timelineBuffer' => 'بوفير الوقت',
			'liveTv.timelineUnavailable' => 'الخطوط الزمنية غير متوفر',
			'liveTv.timelineEstimated' => 'مشاهدة Playback',
			'liveTv.timelinePending' => 'طوال البحث',
			'liveTv.timelineStale' => 'قد يكون الجدول الزمني قد يكون قديمًا',
			'liveTv.unknownHub' => 'غير معروف',
			'liveTv.unknownError' => 'خطأ غير معروف',
			'liveTv.channelNumber' => ({required Object number}) => 'قناة ${number}',
			'liveTv.unknownChannel' => 'قناة غير معروفة',
			'liveTv.live' => 'مباشر',
			'liveTv.premiereBadge' => 'جديد',
			'liveTv.reloadGuide' => 'إعادة تحميل دليل',
			'liveTv.searchGuide' => 'دليل البحث',
			'liveTv.searchHint' => 'قنوات البحث والبرامج',
			'liveTv.searchNoResults' => ({required Object query}) => 'لا توجد مباريات لـ "${query}"',
			'liveTv.channelsSection' => 'القنوات',
			'liveTv.programsSection' => 'البرامج',
			'liveTv.now' => 'الآن',
			'liveTv.today' => 'اليوم',
			'liveTv.tomorrow' => 'غداً',
			'liveTv.midnight' => 'منتصف الليل',
			'liveTv.overnight' => 'في الليل',
			'liveTv.morning' => 'صباح',
			'liveTv.daytime' => 'اليومية',
			'liveTv.evening' => 'المساء',
			'liveTv.lateNight' => 'في وقت متأخر من الليل',
			'liveTv.whatsOn' => 'ما هو على',
			'liveTv.watchChannel' => 'مشاهدة القناة',
			'liveTv.favorites' => 'المفضلة',
			'liveTv.reorderFavorites' => 'المفضلة المفضلة',
			'liveTv.noFavoriteChannels' => 'لا قنوات مفضلة',
			'liveTv.noFavoriteChannelsHint' => 'عرض جميع القنوات ، ثم اضغط طويلا على قناة لإضافتها إلى المفضلة لديك.',
			'liveTv.showAllChannels' => 'عرض جميع القنوات',
			'liveTv.favoritesLoadFailed' => 'لا يمكن تحميل المفضلة.تحقق من اتصالك ومحاولة مرة أخرى.',
			'liveTv.favoritesUpdateFailed' => 'لا يمكن تحديث المفضلة.تحقق من اتصالك ومحاولة مرة أخرى.',
			'liveTv.joinSession' => 'انضم إلى جلسة التقدم',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'مشاهدة من البداية (${minutes} دقيقة مضت)',
			'liveTv.watchLive' => 'مشاهدة Live',
			'liveTv.goToLive' => 'اذهب إلى الحياة',
			'liveTv.record' => 'تسجيل',
			'liveTv.recordEpisode' => 'الحلقة التسجيلية',
			'liveTv.recordSeries' => 'تسجيل المسلسل',
			'liveTv.recordOptions' => 'خيارات التسجيل',
			'liveTv.saveTo' => 'إنقاذ إلى',
			'liveTv.recordings' => 'التسجيلات',
			'liveTv.scheduledRecordings' => 'جدول زمني',
			'liveTv.recordingRules' => 'قواعد التسجيل',
			'liveTv.noScheduledRecordings' => 'لا شيء مخطط للتسجيل',
			'liveTv.manageRecording' => 'إدارة التسجيل',
			'liveTv.cancelRecording' => 'إلغاء التسجيل',
			'liveTv.cancelRecordingTitle' => 'إلغاء هذا التسجيل؟',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} لن يتم تسجيلها بعد الآن.',
			'liveTv.deleteRule' => 'إلغاء القاعدة',
			'liveTv.deleteRuleTitle' => 'إلغاء قاعدة التسجيل؟',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'لن يتم تسجيل الحلقات المستقبلية من ${title}.',
			'liveTv.recordingScheduled' => 'تمت جدولة التسجيل.',
			'liveTv.alreadyScheduled' => 'وقد تم التخطيط لهذا البرنامج بالفعل',
			'liveTv.dvrAdminRequired' => 'إعدادات DVR تتطلب حساب admin',
			'liveTv.recordingFailed' => 'لا أستطيع التخطيط للتسجيل',
			'liveTv.recordingTargetMissing' => 'لا أستطيع تحديد تسجيل المكتبة',
			'liveTv.recordNotAvailable' => 'التسجيل غير متوفر لهذا البرنامج',
			'liveTv.recordingCancelled' => 'تسجيل إلغاء',
			'liveTv.recordingRuleDeleted' => 'قاعدة تسجيل حذف',
			'liveTv.processRecordingRules' => 'إعادة تقييم القواعد',
			'liveTv.recordingInProgress' => 'تسجيل الآن',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} مجدولة',
			'liveTv.editRule' => 'قاعدة Edit',
			'liveTv.editRuleAction' => 'تعديل',
			'liveTv.recordingRuleUpdated' => 'قواعد التسجيل تحديث',
			'liveTv.guideReloadRequested' => 'دليل التجديد المطلوب',
			'liveTv.guideReloadFailed' => 'لا أستطيع تجديد الدليل',
			'liveTv.rulesProcessRequested' => 'قواعد إعادة التقييم المطلوبة',
			'liveTv.rulesProcessFailed' => 'لا يمكن إعادة تقييم قواعد التسجيل',
			'liveTv.recordShow' => 'عرض السجلات',
			'liveTv.recordSettings.startEarly' => 'بدء مبكرا ( ثانية )',
			'liveTv.recordSettings.endLate' => 'نهاية متأخرة ( ثواني )',
			'liveTv.recordSettings.newOnly' => 'أحداث جديدة فقط',
			'liveTv.recordSettings.anyChannel' => 'تسجيل في أي قناة',
			'liveTv.recordSettings.anyTime' => 'تسجيل في أي وقت',
			'liveTv.recordSettings.skipInLibrary' => 'إلقاء القفز على الحلقات بالفعل في المكتبة',
			'liveTv.recordSettings.keepUpTo' => 'الحوادث التي يجب الحفاظ عليها',
			'liveTv.recordSettings.keepUpToHint' => '0 يحافظ على كل حلقة',
			'liveTv.startingInMinutes' => ({required Object minutes}) => 'بدءاً في ${minutes} دقيقة',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} في ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product} أعيد بيانات تشغيل التلفزيون المباشر غير صحيحة',
			'liveTv.failedToStartChannel' => 'لا أستطيع أن أبدأ القناة الحية',
			'liveTv.failedToBuildStreamUrl' => 'لا أستطيع إنشاء URL',
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'لا يمكن أن يبدأ القناة: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'لا يمكن تغيير القناة: ${reason}',
			'collections.title' => 'المجموعات',
			'collections.collection' => 'مجموعة',
			'collections.empty' => 'المجموعة فارغة',
			'collections.deleteCollection' => 'حذف المجموعة',
			'collections.deleteConfirm' => ({required Object title}) => 'حذف «${title}»؟ لا يمكن التراجع عن هذا الإجراء.',
			'collections.deleted' => 'جمع محذوف',
			'collections.deleteFailed' => 'فشل في حذف المجموعة',
			'collections.deleteFailedWithError' => ({required Object error}) => 'لم يتم إزالة المجموعة: ${error}',
			'collections.selectCollection' => 'اختيار مجموعة',
			'collections.collectionName' => 'اسم جمع',
			'collections.enterCollectionName' => 'إدخال اسم مجموعة',
			'collections.addedToCollection' => 'إضافة إلى مجموعة',
			'collections.errorAddingToCollection' => 'فشل في إضافة إلى المجموعة',
			'collections.created' => 'مجموعة تم إنشاءها',
			'collections.removeFromCollection' => 'إزالة من المجموعة',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => 'هل تريد إزالة «${title}» من هذه المجموعة؟',
			'collections.removedFromCollection' => 'إزالة من المجموعة',
			'collections.removeFromCollectionFailed' => 'فشل في إزالتها من المجموعة',
			'collections.removeFromCollectionError' => ({required Object error}) => 'أخطاء إزالة من المجموعة: ${error}',
			'collections.searchCollections' => 'البحث عن مجموعات...',
			'playlists.title' => 'قوائم التشغيل',
			'playlists.playlist' => 'قائمة التشغيل',
			'playlists.noPlaylists' => 'لا توجد لعبة',
			'playlists.create' => 'خلق قائمة اللعب',
			'playlists.playlistName' => 'لعبة الاسم',
			'playlists.enterPlaylistName' => 'إدخال اسم playlist',
			'playlists.delete' => 'حذف قائمة التشغيل',
			'playlists.removeItem' => 'إزالة من قائمة التشغيل',
			'playlists.smartPlaylist' => 'لعبة ذكية',
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} عنصر', one: 'عنصر واحد', two: 'عنصران', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} عناصر', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} عنصرًا', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} عنصر', ), 
			'playlists.emptyPlaylist' => 'هذه القائمة فارغة',
			'playlists.deleteConfirm' => 'إلغاء اللعب؟',
			'playlists.deleteMessage' => ({required Object name}) => 'هل أنت متأكد من أنك تريد إزالة "${name}"؟',
			'playlists.created' => 'لعبة تم إنشاءها',
			'playlists.deleted' => 'Playlist حذف',
			'playlists.itemAdded' => 'إضافة إلى playlist',
			'playlists.itemRemoved' => 'إزالة من قائمة اللعب',
			'playlists.selectPlaylist' => 'اختيار Playlist',
			'playlists.searchPlaylists' => 'البحث عن ألعاب...',
			'playlists.errorCreating' => 'فشل في إنشاء قائمة اللعب',
			'playlists.errorDeleting' => 'فشل في إلغاء قائمة اللعب',
			'playlists.errorLoading' => 'فشل في تحميل قائمة الألعاب',
			'playlists.errorAdding' => 'فشل في إضافتها إلى قائمة اللعب',
			'playlists.errorReordering' => 'فشل في إعادة ترتيب العناصر في قائمة اللعب',
			'playlists.errorRemoving' => 'فشل في إزالتها من قائمة الألعاب',
			'music.goToAlbum' => 'اذهب إلى الألبوم',
			'music.goToArtist' => 'الذهاب إلى الفنان',
			'music.instantMix' => 'مزيج فوري',
			'music.playNext' => 'تشغيل التالي',
			'music.addToQueue' => 'إضافة إلى كوشنر',
			'music.discNumber' => ({required Object n}) => 'القرص ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مقطع', one: 'مقطع واحد', two: 'مقطعان', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مقاطع', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مقطع', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مقطع', ), 
			'music.nowPlaying' => 'اللعب الآن',
			'music.playingFrom' => ({required Object title}) => 'اللعب من ${title}',
			'music.queue' => 'كوي',
			'music.clearQueue' => 'مسح قائمة التشغيل الحالية',
			'music.lyrics' => 'الكلمات',
			'music.visualizer' => 'التصور',
			'music.visualizerProfileLoading' => 'قراءة تحليل المسار ...',
			'music.visualizerAmbientMotion' => 'حركة البيئة',
			'music.visualizerPlexLoudness' => 'Plex الصوت',
			'music.visualizerPreviousPreset' => 'النمط البصري السابق',
			'music.visualizerNextPreset' => 'النمط البصري التالي',
			'music.visualizerPresetAurora' => 'أورورا',
			'music.visualizerPresetBloom' => 'بلوم',
			'music.visualizerPresetOrbitals' => 'أوربيتال',
			'music.visualizerPresetPrism' => 'الجائزة',
			'music.visualizerPresetTunnel' => 'النفق',
			'music.visualizerPresetTrackMap' => 'مسار الخريطة',
			'music.noLyrics' => 'لا توجد أغاني متوفرة',
			'music.sleepTimer' => 'ساعات النوم',
			'music.sleepTimerEndOfTrack' => 'نهاية المسار',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} دقيقة', one: 'دقيقة', two: 'دقيقتان', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} دقائق', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} دقيقة', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} دقيقة', ), 
			'music.stopPlayback' => 'إيقاف التشغيل',
			'music.previousTrack' => 'المسار السابق',
			'music.nextTrack' => 'المسار التالي',
			'music.repeat' => 'تكرار',
			'music.repeatAll' => 'تكرار الكل',
			'music.repeatOne' => 'تكرار واحد',
			'music.instantMixNoServer' => 'لا توجد خادم متاح لمزيج فوري',
			'music.instantMixFailed' => 'فشل في تحميل المزيج الفوري',
			'music.instantMixEmpty' => 'عودة المزيج الفوري دون أي مسارات',
			'music.noAudioUrl' => ({required Object track}) => 'لا توجد عناوين URL الصوتية متوفرة على ${track}',
			'music.discography.singlesAndEps' => 'مجلدات & EPs',
			'music.discography.live' => 'مباشر',
			'music.discography.compilations' => 'المجموعات',
			'watchTogether.title' => 'المشاهدة معًا',
			'watchTogether.description' => 'مشاهدة المحتوى في مزامنة مع الأصدقاء والعائلة',
			'watchTogether.createRoom' => 'خلق غرفة',
			'watchTogether.creatingRoom' => 'إنشاء غرفة...',
			'watchTogether.joinRoom' => 'انضم إلى الغرفة',
			'watchTogether.joiningRoom' => 'انضم إلى غرفة...',
			'watchTogether.connecting' => 'اتصال ...',
			'watchTogether.relayPublic' => 'تستخدم الغرف إعلانات الحزب المفتوح للجمهور.',
			'watchTogether.relayCustom' => ({required Object url}) => 'تستخدم الغرف إرسالك على رقم ${url}.',
			'watchTogether.recentRooms' => 'غرف حديثة',
			'watchTogether.roomActions' => 'عمل الغرفة',
			'watchTogether.renameRoom' => 'غرفة رينامي',
			'watchTogether.removeRoom' => 'إزالة',
			'watchTogether.enterRoomCode' => 'أدخل رمز 6 أحرف من المضيف.',
			'watchTogether.roomCode' => 'رمز الغرفة',
			'watchTogether.paste' => 'كعكة',
			'watchTogether.noCodeInClipboard' => 'لا يحتوي الكليب على رمز غرفة',
			'watchTogether.copyCode' => 'نسخ الرمز',
			'watchTogether.codeCopied' => 'رمز الغرفة نسخة',
			'watchTogether.shareInvite' => 'مشاركة دعوة',
			'watchTogether.inviteCopied' => 'إرسال الرسالة - إرسال الرسالة إلى الرسالة',
			'watchTogether.inviteMessage' => ({required Object code}) => 'انضم إلى غرفة Watch Together في PlezyNG: افتح غرفة Watch Together واختر انضم إلى غرفة وانضم إلى ${code}.',
			'watchTogether.openSessionControls' => 'Open Watch معا مراقبة الجلسة',
			'watchTogether.reconnecting' => 'إعادة الاتصال...',
			'watchTogether.reconnectingDescription' => 'انقطع الاتصال.تصل إلى الغرفة تلقائيًا.',
			'watchTogether.connected' => 'متصلة',
			'watchTogether.disconnected' => 'انقطاع الاتصال',
			'watchTogether.youAreHost' => 'أنت المضيف',
			'watchTogether.hostedBy' => ({required Object name}) => 'استضافتها ${name}',
			'watchTogether.hostControlsPlayback' => 'أضف تعليق حول Playback',
			'watchTogether.anyoneCanControl' => 'يمكن لأي شخص التحكم في playback',
			'watchTogether.roomLocked' => 'غرفة مغلقة',
			'watchTogether.nowPlaying' => 'اللعب الآن',
			'watchTogether.nothingPlaying' => 'لا شيء يلعب',
			'watchTogether.nothingPlayingHost' => 'لعب شيء من أي مكتبة لتقاسمها مع الغرفة.',
			'watchTogether.nothingPlayingGuest' => 'عندما يلعب المضيف شيئًا ما ، يفتح هنا.',
			'watchTogether.notShareable' => 'هذا الفيديو ليس له مطابقة الكتالوج، لذلك فقط الأشخاص الذين لديهم إمكانية الوصول إلى نفس الخادم يمكن أن تلعب.',
			'watchTogether.searching' => 'إذا كنت تبحث عن هذا الفيديو في مكتباتك ...',
			'watchTogether.yourCopy' => 'نسخك',
			'watchTogether.sharingYourCopy' => 'أنت تشارك نسختك',
			'watchTogether.playingOtherLength' => ({required Object difference}) => 'لعب النسخة الخاصة بك، ${difference}',
			'watchTogether.mismatchTitle' => 'النسخة الخاصة بك هي طوله مختلف',
			'watchTogether.mismatchDescription' => ({required Object difference}) => 'أقرب نسخة هي ${difference} من الفيديو في الغرفة.',
			'watchTogether.playAnyway' => 'اللعب على أي حال',
			'watchTogether.chooseAnotherCopy' => 'اختر نسخة أخرى',
			'watchTogether.dontPlay' => 'لا تلعب',
			'watchTogether.unavailableTitle' => 'أنت لا تملك هذا الفيديو',
			'watchTogether.unavailableDescription' => 'PlezyNG لا يمكن العثور عليه في المكتبات الخاصة بك. احصل على نسخة لنفسك أو البحث مرة أخرى.',
			'watchTogether.chooseCopy' => 'اختر نسخة',
			'watchTogether.searchAgain' => 'البحث مرة أخرى',
			'watchTogether.noCandidates' => 'لا توجد نسخ في مكتباتك.',
			'watchTogether.choiceFailed' => 'لا أستطيع أن ألعب هذا النسخة لغرفة',
			'watchTogether.lengthLonger' => ({required Object duration}) => '${duration} أطول',
			'watchTogether.lengthShorter' => ({required Object duration}) => '${duration} أقصر',
			'watchTogether.lengthSame' => 'نفس الطول',
			'watchTogether.lengthUnknown' => 'الطول غير المعروف',
			'watchTogether.joinCurrentPlayback' => 'الانضمام إلى Playback',
			'watchTogether.joinCurrentPlaybackDescription' => 'ارجع إلى ما يراقبه المضيف حاليًا',
			'watchTogether.stopMedia' => 'توقف الفيديو للجميع',
			'watchTogether.syncOffset' => 'التعاقد Offset',
			'watchTogether.syncOffsetDescription' => 'تحويل الفيديو الخاص بك إذا كان يعمل أمام أو خلف الغرفة.',
			'watchTogether.offsetHint' => ({required Object difference}) => 'نسختك ${difference} من الفيديو في الغرفة.',
			'watchTogether.applyDifference' => ({required Object offset}) => 'الاستخدام ${offset}',
			'watchTogether.offsetMinusSecond' => '1 س',
			'watchTogether.offsetMinusTenth' => '- 100 ميغاواط',
			'watchTogether.offsetPlusTenth' => '+ 100 ميغاواط',
			'watchTogether.offsetPlusSecond' => '+1 س',
			'watchTogether.participants' => 'المشاركين',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مشارك', one: 'مشارك واحد', two: 'مشاركان', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مشاركين', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مشارك', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مشارك', ), 
			'watchTogether.hostBadge' => 'المضيف',
			'watchTogether.nameYou' => ({required Object name}) => '${name} (أنت)',
			'watchTogether.playerIdle' => 'خاملة',
			'watchTogether.playerLoading' => 'تحميل',
			'watchTogether.playerReady' => 'جاهز',
			'watchTogether.playerBuffering' => 'بوفير',
			'watchTogether.matchSearching' => 'البحث',
			'watchTogether.matchMatched' => 'لديك الفيديو',
			'watchTogether.matchMismatched' => 'الطول المختلف',
			'watchTogether.matchUnavailable' => 'لا يوجد فيديو',
			'watchTogether.participantOffset' => ({required Object offset}) => 'أوبسيت ${offset}',
			'watchTogether.makeHost' => 'جعل المضيف',
			'watchTogether.makeHostQuestion' => 'نقل المضيف؟',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} سيسيطر على تشغيل وتشغيل الجلسة للجميع.',
			'watchTogether.transfer' => 'نقل',
			'watchTogether.removeParticipant' => 'إزالة من الغرفة',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => 'إزالة ${name}؟',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} يغادر الغرفة.يمكنهم الانضمام مرة أخرى مع الرمز ما لم تقم بإغلاق الغرفة.',
			'watchTogether.remove' => 'إزالة',
			'watchTogether.roomSettings' => 'إعدادات الغرفة',
			'watchTogether.letEveryoneControl' => 'دع الجميع يسيطرون على Playback',
			'watchTogether.lockRoom' => 'غرفة القفل',
			'watchTogether.lockRoomDescription' => 'لا أحد جديد يشارك',
			'watchTogether.leaveRoom' => 'غرفة مغادرة',
			'watchTogether.leaveRoomQuestion' => 'غرفة مغادرة؟',
			'watchTogether.leaveRoomConfirm' => 'يمكنك الانضمام مرة أخرى مع رمز الغرفة.',
			'watchTogether.leave' => 'تركها',
			'watchTogether.endRoom' => 'غرفة النهاية',
			'watchTogether.endRoomQuestion' => 'غرفة النهاية؟',
			'watchTogether.endRoomConfirm' => 'هذا هو نهاية الغرفة للجميع.',
			'watchTogether.end' => 'نهاية',
			'watchTogether.playBlockedTitle' => 'لعبة Playback لم تبدأ',
			'watchTogether.playBlockedDescription' => 'أضغط على اللعب للبدء في مشاهدة مع الغرفة.',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} اللعب المضغوط',
			'watchTogether.notices.playbackStarted' => 'بدأت Playback',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} استراحة',
			'watchTogether.notices.playbackPaused' => 'Playback استراحة',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} قفزت إلى ${position}',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => 'تداول الخيارات الثنائية ${position}',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} يحدد السرعة إلى ${speed}',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => 'السرعة المحددة إلى ${speed}',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} بدأت ${title}',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => 'اللعب الآن ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} توقف الفيديو',
			'watchTogether.notices.mediaStopped' => 'فيديو توقف',
			'watchTogether.notices.waitingFor' => ({required Object name}) => 'في انتظار ${name} ...',
			'watchTogether.notices.waitingForSomeone' => 'وانتظر شخص ما يلتقط...',
			'watchTogether.notices.finished' => 'الانتهاء',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} هو الآن المضيف',
			'watchTogether.notices.youAreNowHost' => 'أنت الآن المضيف',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} المشاركة',
			'watchTogether.notices.left' => ({required Object name}) => '${name} قليلا',
			'watchTogether.notices.controlRefused' => 'لا يستطيع المضيف سوى التحكم في البث',
			'watchTogether.notices.searchFailed' => 'بعض الخوادم لا يمكن البحث عن الفيديو في الغرفة',
			'watchTogether.notices.playBlocked' => 'ألعاب الطباعة للبدء',
			'watchTogether.notices.shareFailed' => 'لا أستطيع مشاركة هذا الفيديو مع الغرفة',
			'watchTogether.notices.downloadNotShared' => 'لا يتم مشاركة التحميلات مع الغرفة بينما الخادم غير متصل',
			'watchTogether.notices.openFailed' => 'لا أستطيع فتح الفيديو من الغرفة',
			'watchTogether.ended.ended' => 'المضيف ينتهي الغرفة',
			'watchTogether.ended.kicked' => 'تم إزالتك من الغرفة',
			'watchTogether.ended.expired' => 'الغرفة قد انتهت',
			'watchTogether.ended.replaced' => 'انضم إلى هذا الغرفة على جهاز آخر',
			'watchTogether.ended.lost' => 'فقدت الاتصال بالغرفة',
			'watchTogether.errors.invalidCode' => 'الرموز لديها 6 أحرف والأرقام، دون 0.1، I، L أو O.',
			'watchTogether.errors.roomNotFound' => 'لم يكن هناك أي غرفة لديها هذا الرمز، ربما انتهى.',
			'watchTogether.errors.roomFull' => 'هذه الغرفة مليئة.',
			'watchTogether.errors.roomLocked' => 'أغلقت المضيفة تلك الغرفة.',
			'watchTogether.errors.relayFull' => 'مشاهدة معا مشغول الآن.محاولة مرة أخرى في وقت لاحق.',
			'watchTogether.errors.unreachable' => 'لم أستطع الوصول إلى الساعة معا إرسال.تحقق من اتصالك.',
			'watchTogether.errors.rateLimited' => 'الكثير من المحاولات.انتظر لحظة ومحاولة مرة أخرى.',
			'watchTogether.errors.clientBlocked' => 'هذا الإصدار من PlezyNG لا يستطيع استخدام الإرسال.',
			'watchTogether.errors.forbidden' => 'فقط المضيف يمكن أن يفعل ذلك.',
			'watchTogether.errors.notInRoom' => 'أنت لست في غرفة.',
			'watchTogether.errors.alreadyInRoom' => 'أنت الآن في غرفة.',
			'watchTogether.errors.resumeFailed' => 'لا أستطيع أن أذهب إلى الغرفة.',
			'watchTogether.errors.unsupported' => 'لا يدعم هذا الإذاعة.',
			'watchTogether.errors.generic' => 'حدث خطأ، حاول مرة أخرى.',
			'watchTogether.untitledEpisode' => ({required Object number}) => 'الحلقة ${number}',
			'downloads.title' => 'التنزيلات',
			'downloads.manage' => 'إدارة',
			'downloads.tvShows' => 'مسلسلات تلفزيونية',
			'downloads.movies' => 'الأفلام',
			'downloads.music' => 'الموسيقى',
			'downloads.tracksQueued' => ({required Object count}) => '${count} المسارات التي تم إدراجها للتنزيل',
			'downloads.noDownloads' => 'لا تنزيل بعد',
			'downloads.noDownloadsDescription' => 'سيتم عرض المحتوى الذي تم تنزيله هنا لمشاهدة خارج الإنترنت',
			'downloads.downloadNow' => 'تنزيل',
			'downloads.deleteDownload' => 'حذف download',
			'downloads.retryDownload' => 'Retry تحميل',
			'downloads.downloadQueued' => 'تم وضع التنزيل في قائمة الانتظار.',
			'downloads.downloadResumed' => 'تحميل مجدد',
			'downloads.serverErrorBitrate' => 'خطأ الخادم: قد يتجاوز الملف الحد الأقصى لمعدل النقاط عن بعد',
			'downloads.storageFull' => 'توقف التحميلات لحماية التخزين المتاحة.إعفاء بعض المساحة أو اختيار موقع آخر للتحميل، ثم الانسحاب.',
			'downloads.storageUnavailable' => 'توقفت التحميلات لأن التخزين المتاح لم يكن قادرا على التحقق.تحقق من موقع التحميل، ثم الانسحاب.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} الحلقة التي تم إرسالها للتنزيل',
			'downloads.downloadDeleted' => 'تحميل حذف',
			'downloads.deleteConfirm' => ({required Object title}) => 'هل يمكن إزالة "${title}" من هذا الجهاز؟',
			'downloads.deleteCollectionDownloads' => 'حذف Downloads',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => 'هل تريد حذف جميع التنزيلات في «${title}» من هذا الجهاز؟',
			'downloads.collectionDownloadsDeleted' => 'تحميل حذف',
			'downloads.cancelledDownloadTitle' => 'إلغاء تحميل',
			'downloads.cancelledDownloadMessage' => 'تم إلغاء هذا التنزيل، ماذا تريد أن تفعل؟',
			'downloads.allEpisodesAlreadyDownloaded' => 'جميع الحلقات التي تم تنزيلها',
			'downloads.resumeDownload' => 'إعادة التدوير download',
			'downloads.cancelledDownload' => 'إلغاء تحميل',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (مزامنة ${status})',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => 'تحميل ${file} - انقر للانتهاء',
			'downloads.partialDownloadClickToComplete' => 'تحميل جزئي - Click to complete',
			'downloads.deleting' => 'إلغاء...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'إزالة ${title}... (${current} من ${total})',
			'downloads.queuedTooltip' => 'كويد',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'كويد ${files}',
			'downloads.downloadingTooltip' => 'تحميل...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'تحميل ${files}',
			'downloads.noDownloadsTree' => 'لا تحميل',
			'downloads.pauseAll' => 'استراحة كل',
			'downloads.resumeAll' => 'قراءة كلها',
			'downloads.retryAll' => 'استرداد كل',
			_ => null,
		} ?? switch (path) {
			'downloads.retryFailed' => 'إعادة التدوير الفشل تحميل',
			'downloads.deleteAll' => 'حذف الكل',
			'downloads.selectVersion' => 'اختيار النسخة',
			'downloads.allEpisodes' => 'كل الحلقات',
			'downloads.unwatchedOnly' => 'غير ملاحظة فقط',
			'downloads.nextNUnwatched' => ({required Object count}) => '${count} غير مسبوق',
			'downloads.customAmount' => 'المبلغ المحدد ...',
			'downloads.customAmountAny' => 'المبلغ المحدد (كل ...',
			'downloads.randomEpisodes' => 'الحوادث العشوائية',
			'downloads.includeSpecials' => 'إدخال الخصائص',
			'downloads.howManyEpisodes' => 'كم عدد الحلقات؟',
			'downloads.invalidEpisodeCount' => 'إدخال عدد الحوادث الصحيح.',
			'downloads.keepSynced' => 'الحفاظ على التزامن',
			'downloads.downloadOnce' => 'تحميل مرة واحدة',
			'downloads.keepNUnwatched' => ({required Object count}) => '${count} غير مسبوق',
			'downloads.editSyncRule' => 'تحرير قاعدة Sync',
			'downloads.removeSyncRule' => 'إزالة قاعدة Sync',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'توقف عن مزامنة "${title}"؟ سيتم حفظ الحلقات التي تم تنزيلها.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => 'توقف عن تصفية "${title}"؟',
			'downloads.deleteSyncRuleDownloads' => 'إزالة أيضًا النسخ المرتبطة',
			'downloads.deleteSyncRuleDownloadsDescription' => 'سيتم الاحتفاظ بالتحميلات المستخدمة من قبل قاعدة أو ملف تعريف آخر.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'قاعدة التزامن التي تم إنشاؤها – الحفاظ على ${count} الحوادث غير الملاحظة',
			'downloads.syncRuleUpdated' => 'قاعدة التزامن تحديث',
			'downloads.syncRuleRemoved' => 'قاعدة التزامن إزالة',
			'downloads.syncRuleAndDownloadsRemoved' => 'إزالة قاعدة التزامن والتحميلات المرتبطة',
			'downloads.syncRuleCleanupBusy' => 'قواعد التزامن حاليا تحديث.حاول مرة أخرى في لحظة.',
			'downloads.syncRuleCleanupUnavailable' => 'لا يمكن التعرف على التحميلات المرتبطة بأمان.إعادة توصيل الخادم ومحاولة مرة أخرى، أو إزالة القاعدة دون حذف التحميلات.',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => 'المزامنة ${count} أحداث جديدة ل ${title}',
			'downloads.syncNow' => 'Sync الآن',
			'downloads.downloadsUpToDate' => 'تحميلات متوفرة حتى الآن',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => 'متزامنة كاملة · ${queued} queued, ${removed} إزالة',
			'downloads.activeSyncRules' => 'قواعد Sync',
			'downloads.reviewOrphanFiles' => 'مشاهدة فيلم Orphaned Downloads',
			'downloads.orphanReviewTitle' => 'مشاهدة فيلم Orphaned Downloads',
			'downloads.orphanReviewDescription' => 'هذه الملفات المسمى موجودة في مجلدات التحميل التي يتم إدارةها بواسطة التطبيق الافتراضي PlezyNG ولا تتوافق مع سجل التحميل أو المهمة النشطة.',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count} ملفات · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => 'حذف ${count} الملفات',
			'downloads.orphanCleanupNone' => 'لا توجد ملفات تنزيل العنكبوت',
			'downloads.orphanCleanupFailed' => 'PlezyNG لم يتمكن من فحص مجلد التنزيلات التي تم إدارتها بأمان.',
			'downloads.orphanCleanupChanged' => 'تم تغيير قائمة التنزيل أثناء مراجعة.مراجعة الملفات مرة أخرى قبل التنظيف.',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => 'إزالة ${count} ملفات العذراء · ${size} إطلاق سراح',
			'downloads.noSyncRules' => 'لا توجد قواعد متزامنة',
			'downloads.manageSyncRule' => 'إدارة Sync',
			'downloads.editEpisodeCount' => 'الحلقة العد',
			'downloads.editSyncFilter' => 'تصفية Sync',
			'downloads.syncAllItems' => 'إزالة جميع العناصر',
			'downloads.syncUnwatchedItems' => 'تصنيف العناصر غير المراقبة',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'الخادم: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'متاح',
			'downloads.syncRuleOffline' => 'غير متصل',
			'downloads.syncRuleSignInRequired' => 'التوقيع في المطلوب',
			'downloads.syncRuleAccessDenied' => 'الوصول يرفض',
			'downloads.syncRuleNotAvailableForProfile' => 'غير متوفر للملف الحالي',
			'downloads.syncRuleUnknownServer' => 'الخادم المجهول',
			'downloads.syncRuleListCreated' => 'قاعدة التزام تم إنشاؤها',
			'downloads.backgroundWarning.bannerBlocked' => 'سيتوقف التحميل عند مغادرتك التطبيق',
			'downloads.backgroundWarning.bannerDegraded' => 'يمكن أن تكون تنزيلات الخلفية محدودة',
			'downloads.backgroundWarning.bannerAction' => 'تفاصيل',
			'downloads.backgroundWarning.sheetTitle' => 'يتم حظر تنزيلات الخلفية',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'يمكن أن تكون تنزيلات الخلفية محدودة',
			'downloads.backgroundWarning.sheetIntro' => 'Android يمنع PlezyNG من تنزيل موثوقة في الخلفية.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'جهازك يحدد عندما يمكن تحميل PlezyNG في الخلفية.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'استخدام الخلفية PlezyNG يقتصر.إعداد استخدام البطارية أو الخلفية إلى "غير محدود".',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android قد وضعت PlezyNG في حالة وقوف محدودة.',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'يتم إيقاف تشغيل إشعارات التنزيل ، لذلك قد لا تكون التقدم والسيطرة متاحة.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'يتم إيقاف الإشعارات. على Android 13 أو أحدث، فهي مطلوبة للتنزيلات الخلفية الطويلة.',
			'downloads.backgroundWarning.reasonDataSaver' => 'توفير البيانات مفعّل، مما يمنع التنزيل في الخلفية عبر بيانات الجوّال. يُفترض أن تستمر التنزيلات عبر Wi-Fi.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'توقفت التنزيلات عدة مرات أثناء عمل PlezyNG في الخلفية. تحقق من إعدادات البطارية أو استخدام الخلفية الخاصة بـ PlezyNG.',
			'downloads.backgroundWarning.openSettings' => 'إعدادات مفتوحة',
			'downloads.backgroundWarning.stillNotWorking' => 'مساعدة محددة الأجهزة',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'عرض الخطوات على جهازك، أو إرسال سجل من الإعدادات › عرض السجلات إذا استمرت المشكلة.',
			'downloads.backgroundWarning.dialogTitle' => 'تحميل قد لا ينتهي',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'تحميل على أي حال',
			'downloads.backgroundWarning.dialogFixFirst' => 'إصلاح هذا أولاً',
			'downloads.backgroundWarning.statusTile' => 'خلفية تحميل',
			'downloads.backgroundWarning.statusOk' => 'يسمح بالركض في الخلفية',
			'downloads.backgroundWarning.statusBlocked' => 'محظور من خلال إعدادات النظام',
			'downloads.backgroundWarning.statusDegraded' => 'الحد الأدنى من نظام الإعدادات',
			'downloads.backgroundWarning.statusUnknown' => 'لم يتم فحصها بعد',
			'downloads.backgroundWarning.settingsUnavailable' => 'لا يمكن فتح إعدادات النظام على هذا الجهاز',
			'downloads.backgroundWarning.linkUnavailable' => 'لا يمكن فتح dontkillmyapp.com على هذا الجهاز',
			'downloads.options' => 'خيارات التحميل',
			'downloads.groupings.library' => 'المكتبة',
			'downloads.groupings.collections' => 'المجموعات',
			'downloads.unknownLibrary' => 'مكتبة غير معروفة',
			'downloads.unknownShow' => 'عرض غير معروف',
			'downloads.unknownSeason' => 'الموسم المجهول',
			'downloads.unknownAlbum' => 'ألبوم غير معروف',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} تم الانتهاء منه',
			'downloads.storageUsed' => ({required Object size}) => 'التخزين المستخدم: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} تنزيل', one: 'تنزيل واحد', two: 'تنزيلان', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} تنزيلات', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} تنزيل', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} تنزيل', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مسلسل', one: 'مسلسل واحد', two: 'مسلسلان', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مسلسلات', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مسلسل', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} مسلسل', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} فيلم', one: 'فيلم واحد', two: 'فيلمان', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} أفلام', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} فيلم', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} فيلم', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ألبوم', one: 'ألبوم واحد', two: 'ألبومان', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ألبومات', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ألبوم', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ألبوم', ), 
			'downloads.errorFileNotFound' => 'ملف غير موجود (404)',
			'downloads.errorDownloadNotAllowed' => 'تنزيل غير مسموح به الخادم (403)',
			'downloads.errorDownloadFailed' => 'تحميل فشل',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'تحميل فشل: ${reason}',
			'downloads.convertingOnServer' => 'تحويلها إلى خادم ..',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => 'التحويل على الخادم · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => 'تحميل فشل (HTTP ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => 'بعد المعالجة فشل: ${reason}',
			'downloads.reasonFileNotSaved' => 'لا يمكن حفظ الملف على هذا الجهاز',
			'downloads.reasonCannotResume' => 'لا يمكن إعادة تنزيل الجزئي',
			'downloads.reasonDeviceStorageFull' => 'هذا الجهاز خارج التخزين',
			'downloads.notificationDownloading' => 'تحميل...',
			'downloads.notificationComplete' => 'تحميل كامل',
			'downloads.notificationPaused' => 'تحميل استراحة',
			'shaders.title' => 'الظلال',
			'shaders.noShaderDescription' => 'لا تحسينات الفيديو',
			'shaders.nvscalerDescription' => 'مقياس الصورة NVIDIA للحصول على مقاطع فيديو أكثر وضوحا',
			'shaders.artcnnVariantNeutral' => 'محايد',
			'shaders.artcnnVariantDenoise' => 'ديني',
			'shaders.artcnnVariantDenoiseSharpen' => 'دينيس + شاربين',
			'shaders.qualityFast' => 'سريع',
			'shaders.qualityHQ' => 'الجودة العالية',
			'shaders.mode' => 'الأزياء',
			'shaders.importShader' => 'استيراد شاتر',
			'shaders.customShaderDescription' => 'تخصيص شاتر GLSL',
			'shaders.shaderImported' => 'شاتري المستوردة',
			'shaders.shaderImportFailed' => 'فشل في استيراد الشطرنج',
			'shaders.deleteShader' => 'إلغاء Shader',
			'shaders.deleteShaderConfirm' => ({required Object name}) => 'إلغاء “${name}”؟',
			'companionRemote.title' => 'جهاز التحكم المرافق',
			'companionRemote.connectedTo' => ({required Object name}) => 'الاتصال بـ ${name}',
			'companionRemote.unknownDevice' => 'جهاز غير معروف',
			'companionRemote.session.startingServer' => 'بدء تشغيل الخادم عن بعد',
			'companionRemote.session.hostAddress' => 'العنوان المضيف',
			'companionRemote.session.connected' => 'متصلة',
			'companionRemote.session.serverRunning' => 'الخادم عن بعد نشط',
			'companionRemote.session.serverStopped' => 'توقف الخادم عن بعد',
			'companionRemote.session.serverRunningDescription' => 'الأجهزة المحمولة على شبكتك يمكن الاتصال بهذه التطبيق',
			'companionRemote.session.serverStoppedDescription' => 'بدء تشغيل الخادم لتمكين الأجهزة المحمولة من الاتصال',
			'companionRemote.session.usePhoneToControl' => 'استخدم جهازك المحمول للسيطرة على هذا التطبيق',
			'companionRemote.session.startServer' => 'بدء الخادم',
			'companionRemote.session.stopServer' => 'توقف الخادم',
			'companionRemote.session.minimize' => 'الحد الأدنى',
			'companionRemote.session.manualAddressHint' => 'عنوان الاتصال اليدوي :',
			'companionRemote.pairing.discoveryDescription' => 'الأجهزة PlezyNG مع نفس الحساب Plex تظهر هنا',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'اتصال ...',
			'companionRemote.pairing.searchingForDevices' => 'البحث عن الأجهزة...',
			'companionRemote.pairing.noDevicesFound' => 'لا توجد أجهزة في شبكتك',
			'companionRemote.pairing.noDevicesHint' => 'افتح PlezyNG على سطح المكتب واستخدم نفس Wi-Fi',
			'companionRemote.pairing.availableDevices' => 'أجهزة متوفرة',
			'companionRemote.pairing.manualConnection' => 'الاتصال اليدوي',
			'companionRemote.pairing.cryptoInitFailed' => 'لا يمكن أن تبدأ اتصال آمن. تسجيل الدخول إلى Plex أولا.',
			'companionRemote.pairing.validationHostRequired' => 'يرجى إدخال عنوان المضيف',
			'companionRemote.pairing.validationHostFormat' => 'يجب أن يكون تنسيق IP:port (على سبيل المثال، 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'اتصال متأخر: استخدم نفس الشبكة على كلا الجهازين.',
			'companionRemote.pairing.sessionNotFound' => 'لا يوجد جهاز تم العثور عليه. تأكد من أن PlezyNG يعمل على المضيف.',
			'companionRemote.pairing.authFailed' => 'فشل التحقق: يحتاج كلا الجهازين إلى نفس الحساب Plex.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'عدم الاتصال: ${error}',
			'companionRemote.pairing.codeTitle' => 'الرمز المزدوج',
			'companionRemote.pairing.codeDescription' => 'أدخل الرمز الذي يظهر في Companion Remote على الجهاز المضيف.يجب على كلا الجهازين استخدام نسخة تدعم الارتباط الآمن.',
			'companionRemote.pairing.codeInvalid' => 'أدخل جميع الحروف والأرقام 32 من رمز المضيف.',
			'companionRemote.pairing.updateRequired' => 'تحديث كلا الجهازين إلى إصدار يدعم الارتباط الآمن.',
			'companionRemote.pairing.hostDescription' => 'أدخل هذا الرمز مرة واحدة على كل جهاز بعيد.حافظ على خصوصية: يمنح السيطرة على هذا الملف الشخصي.',
			'companionRemote.pairing.resetCode' => 'إعادة تعيين الرمز المزدوج',
			'companionRemote.pairing.resetDescription' => 'قم بإلغاء الاتصال بجميع الوسائل البعيدة وخلق رمز جديد.سيتعين على كل الوسائل البعيدة أن تتزوج مرة أخرى.',
			'companionRemote.remote.disconnectConfirm' => 'هل ترغب في إلغاء الاتصال من الجلسة عن بعد؟',
			'companionRemote.remote.reconnecting' => 'إعادة الاتصال...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'حاول ${current} من 5',
			'companionRemote.remote.retryNow' => 'العودة الآن',
			'companionRemote.remote.tabRemote' => 'بعيد',
			'companionRemote.remote.tabPlay' => 'تشغيل',
			'companionRemote.remote.tabMore' => 'المزيد',
			'companionRemote.remote.menu' => 'القائمة',
			'companionRemote.remote.tabNavigation' => 'Tab الملاحة',
			'companionRemote.remote.tabDiscover' => 'اكتشاف',
			'companionRemote.remote.tabLibraries' => 'المكتبات',
			'companionRemote.remote.tabSearch' => 'بحث',
			'companionRemote.remote.tabDownloads' => 'التنزيلات',
			'companionRemote.remote.tabSettings' => 'الإعدادات',
			'companionRemote.remote.previous' => 'السابق',
			'companionRemote.remote.playPause' => 'لعبة / استراحة',
			'companionRemote.remote.next' => 'التالي',
			'companionRemote.remote.seekBack' => 'البحث مرة أخرى',
			'companionRemote.remote.stop' => 'إيقاف',
			'companionRemote.remote.seekForward' => 'البحث FWD',
			'companionRemote.remote.volume' => 'حجم',
			'companionRemote.remote.volumeDown' => 'أسفل',
			'companionRemote.remote.volumeUp' => 'أعلى',
			'companionRemote.remote.fullscreen' => 'ملء الشاشة',
			'companionRemote.remote.subtitles' => 'الترجمة',
			'companionRemote.remote.audio' => 'الصوت',
			'companionRemote.remote.searchHint' => 'البحث على سطح المكتب ..',
			'companionRemote.errors.noNetworkInterface' => 'لا توجد واجهة شبكة',
			'companionRemote.errors.authenticationFailed' => 'فشل التحقق',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'عدم تشغيل الخادم عن بعد: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'فشل في إرسال الأمر عن بعد: ${error}',
			'companionRemote.errors.joinTimedOut' => 'توقيت الانضمام إلى الجلسة',
			'companionRemote.errors.failedToConnectAnyAddress' => 'فشل في الاتصال بأي عنوان',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'فقدت الاتصال بعد ${attempts} محاولة',
			'companionRemote.errors.connectionLost' => 'الاتصال المفقود',
			'companionRemote.closedBeforeAuth' => 'إغلاق الاتصال قبل التحقق',
			'videoSettings.playbackSpeed' => 'سرعة التشغيل',
			'videoSettings.normalSpeed' => 'عادي',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'نشط (${duration})',
			'videoSettings.zoom' => 'تكبير (Cover)',
			'videoSettings.sleepTimer' => 'ساعة النوم',
			'videoSettings.audioSync' => 'الصوت Sync',
			'videoSettings.subtitleSync' => 'موضوع Sync',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'HDR غير متوفر هنا - هذا الكمبيوتر المكتبي أو إنتاج الفيديو لا يمكن أن يحمل.',
			'videoSettings.hdrToneMapping' => 'خريطة HDR Tone',
			'videoSettings.hdrToneMappingCompositor' => 'المكونات',
			'videoSettings.hdrToneMappingCompositorDescription' => 'قم بمرور البيانات المعدلة HDR المصدر وترك خريطة مكون سطح المكتب.',
			'videoSettings.hdrToneMappingPlayer' => 'المشغّل',
			'videoSettings.hdrToneMappingPlayerDescription' => 'خريطة إلى أعلى ضوء الشاشة في اللاعب، ثم أخبر المؤلف النتيجة.',
			'videoSettings.hdrToneMappingFailed' => 'لا يمكن تغيير خرائط الأصوات HDR - الوضع السابق لا يزال نشطا.',
			'videoSettings.audioOutput' => 'أداة الصوت',
			'videoSettings.performanceOverlay' => 'أداء Overlay',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'حول',
			'videoSettings.audioOutputSpatial' => 'الفضاء الصوت',
			'videoSettings.audioOutputStereo' => 'ستيريو (Stereo)',
			'videoSettings.audioEqualizer' => 'الصوت المساواة',
			'videoSettings.audioEqualizerDescription' => 'تعديل خمسة شرائح التردد لهذا الجهاز. متوفر على mpv؛ EQ النشط يزيل الصوت ويمنع الارتباك.',
			'videoSettings.audioEqualizerFlat' => 'مسطحة',
			'videoSettings.audioEqualizerActive' => 'مخصص',
			'videoSettings.audioEqualizerSaveFailed' => 'لا يمكن حفظ إعدادات المساواة الصوتية.',
			'videoSettings.backgroundVideoAudio' => 'خلفية الفيديو الصوت',
			'videoSettings.backgroundVideoAudioDescription' => 'الحفاظ على تشغيل الفيديو الصوتي عند مغادرة المشغل؛ يتم إخفاء الصورة حتى تعود. Android يستخدم إشعار تشغيل الوسائط.',
			'videoSettings.audioNormalization' => 'استقرار الضوضاء',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'إزالة الصوت إلى PCM؛ يغلق passthrough بينما يغلق',
			'performanceOverlay.color' => 'اللون',
			'performanceOverlay.performance' => 'الأداء',
			'performanceOverlay.buffer' => 'بوفير',
			'performanceOverlay.app' => 'التطبيق',
			'performanceOverlay.decoder' => 'ديكودر',
			'performanceOverlay.rawDecoder' => 'أدوات التخفيف',
			'performanceOverlay.tunneling' => 'النفقات',
			'performanceOverlay.passthrough' => 'كسارة',
			'performanceOverlay.aspect' => 'وجهة نظر',
			'performanceOverlay.rotation' => 'الدوران',
			'performanceOverlay.dvSource' => 'مصدر DV',
			'performanceOverlay.dvPath' => 'الطريق DV',
			'performanceOverlay.dvRouteDecoder' => 'Dolby Vision الخصم',
			'performanceOverlay.dvRouteDecoderP81' => 'Dolby Vision التخزين (P7→8.1)',
			'performanceOverlay.dvRouteBaseLayer' => 'طبقة قاعدة',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'HDR10 طبقة أساسية',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'طبقة قاعدة HLG',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'SDR طبقة أساسية',
			'performanceOverlay.dvRouteReshaped' => 'إعادة تدوير RPU (gpu-next)',
			'performanceOverlay.p7Conversion' => 'P7 كونف',
			'performanceOverlay.sampleRate' => 'معدل العينة',
			'performanceOverlay.pixelFormat' => 'بيكسل Fmt',
			'performanceOverlay.hwFormat' => 'تنسيق العتاد',
			'performanceOverlay.matrix' => 'ماتريكس',
			'performanceOverlay.primaries' => 'الأوائل',
			'performanceOverlay.transfer' => 'نقل',
			'performanceOverlay.renderFps' => 'رينجر FPS',
			'performanceOverlay.displayFps' => 'عرض FPS',
			'performanceOverlay.avSync' => 'A / V التزامن',
			'performanceOverlay.dropped' => 'انقطاع',
			'performanceOverlay.dvRpus' => 'DV RPUs',
			'performanceOverlay.dvRpuAverage' => 'رويترز RPU Avg',
			'performanceOverlay.dvSampleAverage' => 'DV نموذج Avg',
			'performanceOverlay.maxLuma' => 'ماكس لوما',
			'performanceOverlay.minLuma' => 'لوميا',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'كاش المستخدم',
			'performanceOverlay.cacheLimit' => 'الحد الأدنى للكاش',
			'performanceOverlay.speed' => 'السرعة',
			'performanceOverlay.player' => 'المشغّل',
			'performanceOverlay.playMethod' => 'طريقة التشغيل',
			'performanceOverlay.memory' => 'الذاكرة',
			'performanceOverlay.uiFps' => 'فاي FPS',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android HW',
			'performanceOverlay.decoderNvidiaHw' => 'NVIDIA HW',
			'performanceOverlay.decoderQualcommHw' => 'كوالكوم HW',
			'performanceOverlay.decoderMediatekHw' => 'الوسائط HW',
			'performanceOverlay.decoderExynosHw' => 'إكسينوس HW',
			'performanceOverlay.decoderSoftware' => 'البرمجة',
			'performanceOverlay.decoderHardware' => 'الأجهزة',
			'performanceOverlay.tunnelingActive' => 'نشطة',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted} (${failures} فاشلة)',
			'externalPlayer.title' => 'اللاعب الخارجي',
			'externalPlayer.useExternalPlayer' => 'استخدام اللاعب الخارجي',
			'externalPlayer.useExternalPlayerDescription' => 'فتح الفيديوهات في تطبيق آخر',
			'externalPlayer.selectPlayer' => 'اختيار اللاعب',
			'externalPlayer.customPlayers' => 'اللاعبين المخصصين',
			'externalPlayer.systemDefault' => 'نظام الافتراض',
			'externalPlayer.addCustomPlayer' => 'إضافة اللاعب المخصص',
			'externalPlayer.playerName' => 'اسم اللاعب',
			'externalPlayer.playerNameHint' => 'لاعبنا',
			'externalPlayer.playerCommand' => 'القيادة',
			'externalPlayer.playerPackage' => 'اسم الحزمة',
			'externalPlayer.playerUrlScheme' => 'نظام URL',
			'externalPlayer.off' => 'إيقاف',
			'externalPlayer.launchFailed' => 'فشل في فتح لاعب خارجي',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} لم يتم تثبيت',
			'externalPlayer.playInExternalPlayer' => 'اللعب في اللاعب الخارجي',
			'metadataEdit.editMetadata' => 'تعديل',
			'metadataEdit.screenTitle' => 'تعديل البيانات الوصفية',
			'metadataEdit.basicInfo' => 'معلومات أساسية',
			'metadataEdit.artwork' => 'الفن',
			'metadataEdit.advancedSettings' => 'الإعدادات المتقدمة',
			'metadataEdit.title' => 'العنوان',
			'metadataEdit.sortTitle' => 'عنوان الفرز',
			'metadataEdit.originalTitle' => 'العنوان الأصلي',
			'metadataEdit.releaseDate' => 'تاريخ الإصدار',
			'metadataEdit.contentRating' => 'تصنيف المحتوى',
			'metadataEdit.studio' => 'الاستوديو',
			'metadataEdit.tagline' => 'الشعار النصي',
			'metadataEdit.summary' => 'ملخص',
			'metadataEdit.poster' => 'ملصق',
			'metadataEdit.background' => 'الخلفية',
			'metadataEdit.logo' => 'الشعار',
			'metadataEdit.squareArt' => 'ميدان الفن',
			'metadataEdit.selectPoster' => 'اختيار الملصقات',
			'metadataEdit.selectBackground' => 'اختيار الخلفية',
			'metadataEdit.selectLogo' => 'اختيار الشعار',
			'metadataEdit.selectSquareArt' => 'اختيار الفنون الميدانية',
			'metadataEdit.fromUrl' => 'من URL',
			'metadataEdit.uploadFile' => 'تحميل الملفات',
			'metadataEdit.enterImageUrl' => 'إدخال صورة URL',
			'metadataEdit.imageUrl' => 'صورة URL',
			'metadataEdit.metadataUpdated' => 'متاجدات تحديثات',
			'metadataEdit.metadataUpdateFailed' => 'فشل في تحديث البيانات الميتا',
			'metadataEdit.artworkUpdated' => 'الفنون المحدثة',
			'metadataEdit.artworkUpdateFailed' => 'فشل في تحديث أعمال الفن',
			'metadataEdit.noArtworkAvailable' => 'لا توجد أعمال فنية متاحة',
			'metadataEdit.artworkOption' => ({required Object index}) => 'الخيارات الفنية ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'الخيار الفن ${index}، اختياري',
			'metadataEdit.notSet' => 'لا تضع',
			'metadataEdit.libraryDefault' => 'مكتبة الافتراضية',
			'metadataEdit.accountDefault' => 'الحساب الافتراضي',
			'metadataEdit.seriesDefault' => 'سلسلة الافتراض',
			'metadataEdit.episodeSorting' => 'الحلقة تصنيف',
			'metadataEdit.oldestFirst' => 'أقدم أول',
			'metadataEdit.newestFirst' => 'أحدث أولا',
			'metadataEdit.keep' => 'الحفاظ على',
			'metadataEdit.allEpisodes' => 'كل الحلقات',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} آخر الأحداث',
			'metadataEdit.latestEpisode' => 'الحلقة الأخيرة',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'إضافات في الأيام الماضية ${count}',
			'metadataEdit.deleteAfterPlaying' => 'إزالة الحلقات بعد اللعب',
			'metadataEdit.never' => 'أبدًا',
			'metadataEdit.afterADay' => 'بعد يوم واحد',
			'metadataEdit.afterAWeek' => 'بعد أسبوع',
			'metadataEdit.afterAMonth' => 'بعد شهر واحد',
			'metadataEdit.onNextRefresh' => 'في التجديد التالي',
			'metadataEdit.seasons' => 'المواسم',
			'metadataEdit.show' => 'عرض',
			'metadataEdit.hide' => 'إخفاء',
			'metadataEdit.episodeOrdering' => 'الحلقة الأوامر',
			'metadataEdit.tmdbAiring' => 'قاعدة بيانات الأفلام (Aired)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (الإيرادات)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (المطلق )',
			'metadataEdit.metadataLanguage' => 'لغة الميتايتات',
			'metadataEdit.useOriginalTitle' => 'استخدم العنوان الأصلي',
			'metadataEdit.preferredAudioLanguage' => 'لغة الصوت المفضلة',
			'metadataEdit.preferredSubtitleLanguage' => 'لغة الترجمة المفضلة',
			'metadataEdit.subtitleMode' => 'وضع Subtitle Auto-Select',
			'metadataEdit.manuallySelected' => 'اختياري يدويا',
			'metadataEdit.shownWithForeignAudio' => 'عرض مع الصوت الأجنبي',
			'metadataEdit.alwaysEnabled' => 'إمكانية دائما',
			'metadataEdit.tags' => 'الوسوم',
			'metadataEdit.addTag' => 'إضافة tag',
			'metadataEdit.genre' => 'النوع',
			'metadataEdit.director' => 'المخرج',
			'metadataEdit.writer' => 'الكاتب',
			'metadataEdit.producer' => 'المنتج',
			'metadataEdit.country' => 'البلد',
			'metadataEdit.collection' => 'مجموعة',
			'metadataEdit.label' => 'العلامة',
			'metadataEdit.quickTag' => 'Tag سريع ..',
			'matchScreen.match' => 'المباراة...',
			'matchScreen.fixMatch' => 'إصلاح المباراة ..',
			'matchScreen.unmatch' => 'عدم المباراة',
			'matchScreen.unmatchConfirm' => 'ماذا تفعل هذه المباراة؟ Plex يعالجها كغير متنافسة حتى الانتهاء.',
			'matchScreen.unmatchSuccess' => 'موضوع غير متوافق',
			'matchScreen.unmatchFailed' => 'فشل في إلغاء النتيجة',
			'matchScreen.matchApplied' => 'المباراة تطبق',
			'matchScreen.matchFailed' => 'فشل في تطبيق المباراة',
			'matchScreen.titleHint' => 'العنوان',
			'matchScreen.yearHint' => 'السنة',
			'matchScreen.search' => 'بحث',
			'matchScreen.noMatchesFound' => 'لا توجد مباريات',
			'serverTasks.title' => 'وظائف الخادم',
			'serverTasks.failedToLoad' => 'فشل في تحميل المهام',
			'serverTasks.noTasks' => 'لا توجد مهام تسير',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'متصلة',
			'trakt.connectedAs' => ({required Object username}) => 'اتصلت بـ @${username}',
			'trakt.disconnectConfirm' => 'إلغاء الاتصال Trakt حساب؟',
			'trakt.disconnectConfirmBody' => 'PlezyNG سوف تتوقف عن إرسال الأحداث إلى Trakt.',
			'trakt.scrobble' => 'في الوقت الحقيقي Scrobbling',
			'trakt.scrobbleDescription' => 'إرسال لعبة، وقف، وقف الأحداث إلى Trakt أثناء تشغيل.',
			'trakt.watchedSync' => 'سينك مراقبة الوضع',
			'trakt.watchedSyncDescription' => 'عند وضع علامة على العناصر كما تم مشاهدتها في PlezyNG، يتم وضع علامة على العناصر كما تم مشاهدتها في Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'الاتصال Seerr',
			'seerr.serverUrl' => 'URL الخادم',
			'seerr.serverUrlHelper' => 'العنوان الخاص بك Seerr instance',
			'seerr.checkServer' => 'مواصلة',
			'seerr.signInWithJellyfin' => 'تسجيل الدخول مع Jellyfin',
			'seerr.signInWithEmby' => 'تسجيل الدخول مع Emby',
			'seerr.signInWithLocal' => 'استخدام حساب محلي',
			'seerr.email' => 'البريد الإلكتروني',
			'seerr.noSignInMethods' => 'هذه الحالة Seerr لا تقدم أي دعم طريقة تسجيل الدخول PlezyNG.',
			'seerr.instance' => 'الحالة',
			'seerr.disconnectConfirm' => 'إلغاء الاتصال بـ Seerr؟',
			'seerr.disconnectConfirmBody' => 'PlezyNG سوف تنسى هذه الحالة Seerr.',
			'seerr.request' => 'طلب',
			'seerr.request4k' => 'طلب في 4K',
			'seerr.seasons' => 'المواسم',
			'seerr.allSeasons' => 'جميع الموسم',
			'seerr.advancedOptions' => 'متقدم',
			'seerr.destinationServer' => 'مستخدم الوجهة',
			'seerr.qualityProfile' => 'ملف تعريف الجودة',
			'seerr.rootFolder' => 'مجلد الجذر',
			'seerr.languageProfile' => 'ملف تعريف اللغة',
			'seerr.tags' => 'الوسوم',
			'seerr.noTags' => 'لا توجد علامات',
			'seerr.defaultOption' => ({required Object name}) => '${name} (المعيار الافتراضي)',
			'seerr.animeNote' => 'هذه السلسلة هي أنيمي.',
			'seerr.requestSubmitted' => 'الطلب المقدم',
			'seerr.requestFailed' => ({required Object error}) => 'طلب فشل: ${error}',
			'seerr.requestsLoadFailed' => 'لا يمكن تحميل خيارات الطلب',
			'seerr.nothingToRequest' => 'كل شيء متاح أو مطلوب.',
			'seerr.statusAvailable' => 'متاح',
			'seerr.statusPartiallyAvailable' => 'متاحة جزئيا',
			'seerr.statusRequested' => 'المطالبة',
			'seerr.statusProcessing' => 'المعالجة',
			'seerr.statusBlocklisted' => 'محاصرة',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => 'لا يمكن أن تصل إلى ${url}: ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => 'لا توجد حالة في Seerr عند ${url} (HTTP ${status})',
			'seerr.behindAuthProxy' => 'استجاب وكيل عكسي يتطلب المصادقة (SSO أو مصادقة HTTP) بدلًا من Seerr. لا يستطيع PlezyNG تسجيل الدخول من خلاله: اسمح لمسار /api/v1 الخاص بـ Seerr بتجاوز الوكيل لهذا التطبيق، أو استخدم عنوانًا يصل إلى Seerr مباشرةً.',
			'seerr.invalidUrl' => 'إدخال عنوان خادم مثل https://seerr.example.com',
			'seerr.quickConnectUnsupported' => 'هذا المثال لا يدعم Quick Connect.إنه يحتاج إلى Seerr 3.4 أو أحدث.',
			'seerr.notInitialized' => 'هذه الحالة Seerr لم تكتمل إعدادات أول تشغيل',
			'seerr.noPlexTokenForReauth' => 'رقم Plex توكن متاح للتسجيل مرة أخرى',
			'seerr.noStoredCredentials' => 'لا تتوفر بيانات تسجيل دخول محفوظة لتسجيل الدخول مجددًا',
			'seerr.signInRejected' => 'تم رفض التسجيل',
			'seerr.noSessionCookie' => 'لم تصدر شركة Seerr كوكيز الجلسة',
			'seerr.freshCookieRejected' => 'سييرر يرفض الكوكيز الجلسة الجديدة',
			'seerr.noUserInformation' => 'لم تعيد شركة Seerr معلومات المستخدم',
			'seerr.sessionRejectedAfterReauth' => 'تم رفض الجلسة بعد التوقيع مرة أخرى',
			'seerr.permissionDenied' => 'رفضت شركة Seerr هذا الإجراء: لم يعد حسابك لديه إذن مطلوب',
			'seerr.permissionRevoked' => 'لم يعد لديك إذن لطلب هذا',
			'services.title' => 'الخدمات',
			'services.hubSubtitle' => 'يراقب Sync التقدم و يطلب عناوين جديدة.',
			'services.integrations' => 'الاندماج',
			'services.notConnected' => 'غير متصل',
			'services.connectedAs' => ({required Object username}) => 'اتصلت بـ @${username}',
			'services.scrobble' => 'تتبع التقدم تلقائيًا',
			'services.scrobbleDescription' => 'تحديث قائمتك عند الانتهاء من الحلقة أو الفيلم.',
			'services.disconnectConfirm' => ({required Object service}) => 'إلغاء الاتصال ${service}؟',
			'services.disconnectConfirmBody' => ({required Object service}) => 'PlezyNG سوف تتوقف عن التحديث ${service}.',
			'services.connectFailed' => ({required Object service}) => 'لا أستطيع الاتصال بـ ${service}.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'إعادة الاتصال Simkl',
			'services.simklReconnect.subtitle' => 'توقف Simkl تدريجيًا دعم طريقة تسجيل الدخول المستخدمة في هذا الاتصال. تفتح إعادة الاتصال موقع simkl.com للموافقة على PlezyNG، ولا يطّلع PlezyNG على كلمة مرورك مطلقًا. يبقى سجل مشاهداتك محفوظًا في Simkl.',
			'services.deviceCode.title' => ({required Object service}) => 'تنشيط PlezyNG على ${service}',
			'services.deviceCode.instructions' => 'قم بفحص رمز QR، أو قم بزيارة العنوان أدناه وإدخال هذا الرمز:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'فتح ${service} لتنشيط',
			'services.deviceCode.copyCode' => 'نسخ رمز التنشيط',
			'services.deviceCode.waitingForAuthorization' => 'وانتظروا الترخيص ..',
			'services.deviceCode.codeCopied' => 'الرمز النسخ',
			'services.oauthProxy.title' => ({required Object service}) => 'تسجيل الدخول إلى ${service}',
			'services.oauthProxy.body' => 'فحص هذا الرمز QR أو فتح URL على أي جهاز.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'فتح ${service} للتسجيل في',
			'services.pendingAuth.copyUrl' => 'نسخة من URL',
			'services.pendingAuth.urlCopied' => 'URL نسخة',
			'services.libraryFilter.title' => 'مكتبة الفلتر',
			'services.libraryFilter.subtitleAllSyncing' => 'إعداد جميع المكتبات',
			'services.libraryFilter.subtitleNoneSyncing' => 'لا شيء يتزامن',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} محظور',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} مسموح بها',
			'services.libraryFilter.mode' => 'طريقة الفلتر',
			'services.libraryFilter.modeBlacklist' => 'القائمة السوداء',
			'services.libraryFilter.modeWhitelist' => 'القائمة البيضاء',
			'services.libraryFilter.modeHintBlacklist' => 'تصفية كل مكتبة باستثناء تلك التي تم التحقق منها أدناه.',
			'services.libraryFilter.modeHintWhitelist' => 'لا تتزامن إلا مع المكتبات التي تم التحقق منها أدناه.',
			'services.libraryFilter.libraries' => 'المكتبات',
			'services.libraryFilter.noLibraries' => 'لا توجد مكتبات متاحة',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => 'إضافة ${product} الخادم',
			'addServer.serverUrls' => 'URL الخادم',
			'addServer.serverUrlsHelper' => 'العديد من عناوين URL المسموح بها ، منفصلة بواسطة commas.',
			'addServer.findServer' => 'العثور على الخادم',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'البحث عن خادم محلي ${product} ...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'الخادم المحلي ${product}',
			'addServer.username' => 'اسم المستخدم',
			'addServer.password' => 'كلمة المرور',
			'addServer.signIn' => 'تسجيل الدخول',
			'addServer.change' => 'التغيير',
			'addServer.required' => 'مطلوب',
			'addServer.couldNotReachServer' => ({required Object error}) => 'لا يمكن الوصول إلى الخادم: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'تسجيل الدخول فاشلة: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect فشل: ${error}',
			'addServer.addPlexTitle' => 'تسجيل الدخول مع Plex',
			'addServer.pinExpired' => 'انتهاء صلاحية PIN قبل تسجيل الدخول، يرجى المحاولة مرة أخرى.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'فشل في تسجيل الحساب: ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => 'إدخال عنوان URL الخاص بك ${product}',
			'addServer.addConnectionTitle' => 'إضافة اتصال',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'إضافة إلى ${name}',
			'addServer.signInWithPlexCard' => 'تسجيل الدخول مع Plex',
			'addServer.signInWithPlexCardSubtitle' => 'يُضاف هذا الجهاز، ويُضاف الخوادم المشتركة.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'إمكانية الحصول على حساب Plex.المستخدمين المنزليين يصبحون ملفات تعريف.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => 'الاتصال بـ ${product}',
			'addServer.connectToMediaBrowserCardSubtitle' => 'أدخل عنوان URL، اسم المستخدم، وكلمة المرور.',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => 'تسجيل الدخول إلى خادم ${product}.ربط إلى ${name}.',
			_ => null,
		} ?? switch (path) {
			'addServer.borrowFromAnotherProfile' => 'القروض من ملف تعريف آخر',
			'addServer.borrowFromAnotherProfileSubtitle' => 'إعادة استخدام اتصال ملف تعريف آخر.البروفيسور المحمية بـ PIN تتطلب PIN.',
			'addServer.invalidCredentials' => 'اسم المستخدم أو كلمة المرور غير صالحة',
			'addServer.authResponseNotJson' => 'رد التحقق غير صالح JSON',
			'addServer.authResponseIncomplete' => 'استجابة التسجيل من الخادم كانت غير كاملة',
			'addServer.quickConnectRejected' => 'Quick Connect تم رفضها من قبل الخادم',
			'addServer.quickConnectNotJson' => 'رد Quick Connect لم يكن صالحا JSON',
			'addServer.quickConnectMissingFields' => 'رد Quick Connect يفتقر إلى رمز أو سر',
			'addServer.quickConnectPollRejected' => 'Quick Connect استجواب تم رفضه من قبل الخادم',
			'addServer.serverTimedOut' => 'لم يستجيب الخادم في الوقت المناسب.',
			'addServer.responseNotJson' => 'رد الخادم غير صالح JSON',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'الإجابة تفتقر إلى معرف أو اسم الخادم - هل هذا هو الخادم ${product}؟',
			'addServer.probeFailed' => ({required Object error}) => 'لا يمكن الوصول إلى الخادم: ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => 'إدخال عنوان URL واحد على الأقل ${product}',
			'addServer.noReachableServer' => ({required Object product}) => 'لم يتم العثور على خادم ${product} متاح',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'هذه العناوين URL تشير إلى مختلف الخوادم ${product}',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'هذا URL لا يتطابق مع ${product} الخادم',
			'addServer.redirectUnsupported' => 'إعادة توجيه الخادم إلى عنوان URL غير مدعوم',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'إعادة توجيه الخادم إلى مستودع مختلف.إدخال URL النهائي ${product} مباشرة.',
			'addServer.redirectInsecure' => 'إعادة توجيه الخادم من HTTPS إلى عنوان URL غير آمن',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'إعادة توجيه الخادم إلى عنوان URL غير مدعوم، أدخل عنوان URL ${product} النهائي مباشرة.',
			'addServer.directPlexServerUrl' => 'Plex URL الخادم',
			'addServer.directPlexServerUrlHelper' => 'أدخل IP المحلي وميناء Plex Media Server الخاص بك.',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex توكين (اختياري)',
			'addServer.plexTokenHelper' => 'اترك فارغا إذا تم السماح بالوصول دون auth على هذا الخادم.',
			'addServer.plexTokenRequired' => 'يرجى إدخال رمز Plex الخاص بك (X-Plex-Token).',
			'addServer.connectDirectPlexCard' => 'Plex خادم الوسائط (مباشر / محلي)',
			'addServer.connectDirectPlexCardSubtitle' => 'اتصل مباشرة باستخدام IP أو URL المحلي دون حساب plex.tv.',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => 'اتصل مباشرة باستخدام IP المحلي أو URL. اتصل ${name}.',
			'addServer.insecureTitle' => 'اتصال غير مشفر',
			'addServer.insecureDescription' => ({required Object url}) => 'يستخدم ${url} بروتوكول HTTP. قد يتمكن أشخاص على الشبكة من قراءة كلمة مرورك ورموز الوصول والوسائط أو تغييرها. استخدم HTTPS عند توفره. لا تتابع إلا إذا كنت تثق بهذه الشبكة وتقبل هذه المخاطرة.',
			'addServer.allowHttp' => 'السماح باستخدام HTTP',
			'addServer.httpsRequired' => 'استخدام HTTPS أو يسمح صراحة بتوصيل غير مشفر.',
			'watchLink.serverUnavailable' => 'لم أتمكن من الوصول إلى خادم Plex لهذا الرابط.',
			'watchLink.notFound' => 'لم أتمكن من العثور على هذا العرض أو الفيلم على خادمات Plex الخاصة بك.',
			'watchLink.ambiguous' => 'هذا الرابط يطابق العناصر على أكثر من خادم واحد.إضافة خادم إلى الرابط.',
			'watchLink.plexOnly' => 'الرابطات المراقبة تدعم حاليا Plex الخوادم فقط.',
			'watchLink.unsupportedItem' => 'يمكن مشاهدة الروابط فقط فتح عرض أو فيلم.',
			'watchLink.menuItem' => 'مشاهدة الرابط',
			'watchLink.dialogTitle' => 'مشاهدة الرابط',
			'watchLink.dialogShowHint' => 'يفتح هذا الرابط يلعب الحلقة التالية.إضافة &mode=shuffle إلى النهاية للعب العرض على shuffle.',
			'watchLink.dialogMovieHint' => 'فتح هذا الرابط يلعب الفيلم.',
			'watchLink.copy' => 'نسخ',
			'watchLink.copied' => 'Link نسخ',
			'homeLayout.title' => 'تخطيط الصفحة الرئيسية',
			'homeLayout.resetToast' => 'أُعيد تخطيط الصفحة الرئيسية إلى بانر Plezy الأصلي',
			'homeLayout.resetHeroTitle' => 'إعادة تخطيط البانر إلى إعداد Plezy الأصلي؟',
			'homeLayout.resetHeroBody' => 'يُوقف عرض كل الصفوف كبطاقات بارزة، ويُعيد البانر الدوّار الواحد إلى أعلى الصفحة الرئيسية كما كان سابقًا. يبقى ترتيب الصفوف وإعداد إظهارها كما هو.',
			'homeLayout.removeRowTitle' => 'إزالة صف من الصفحة الرئيسية؟',
			'homeLayout.removeRowBody' => ({required Object title}) => 'سيُحذف ${title}. لا يمكن التراجع عن هذا الإجراء.',
			'homeLayout.sync' => 'مزامنة',
			'homeLayout.syncAccountTitle' => 'مزامنة التخطيط مع حساب Plex',
			'homeLayout.syncAccountOn' => 'مفعّل: يشارك هذا الجهاز ترتيب الصفوف والصفوف نفسها وإعدادات البطاقات البارزة والتنقّل التلقائي مع أجهزتك الأخرى.',
			'homeLayout.syncAccountOff' => 'متوقف: يحتفظ هذا الجهاز بتخطيطه الخاص.',
			'homeLayout.syncNow' => 'مزامنة الآن',
			'homeLayout.plexHomeManager' => 'إدارة الصفحة الرئيسية في Plex',
			'homeLayout.managePlexRows' => 'إدارة صفوف Plex في Plezy',
			'homeLayout.managePlexRowsDescription' => 'تنظيم الصفوف المختارة للصفحة الرئيسية',
			'homeLayout.organizeHomeRows' => 'تنظيم صفوف الصفحة الرئيسية',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} صفوف: نقل، بطاقة بارزة، تنقّل تلقائي، إزالة',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => 'تنظيم صفوف ${library}',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => 'متابعة المشاهدة و${n} صفوف: نقل، مكتبة، رئيسية، بطاقة بارزة، تنقّل تلقائي',
			'homeLayout.renderAsHero' => 'عرض كبطاقة بارزة',
			'homeLayout.heroOnlySingleCollection' => 'متاح فقط عندما يعرض هذا الصف عناوين مجموعة واحدة مباشرةً',
			'homeLayout.hero' => 'بطاقة بارزة',
			'homeLayout.autoSlide' => 'تنقّل تلقائي',
			'homeLayout.autoSlideDescription' => 'ينتقل أيضًا تلقائيًا كل بضع ثوانٍ. تعمل الأسهم على الكمبيوتر وأزرار الاتجاهات على التلفزيون دائمًا، وتعيد بدء المؤقّت.',
			'homeLayout.autoSlideEditDescription' => 'ينتقل أيضًا تلقائيًا كل بضع ثوانٍ. عند الإيقاف، يتنقّل فقط عند النقر على سهم في الكمبيوتر أو الضغط على اليمين أو اليسار في جهاز التحكم. تعمل الأسهم وأزرار الاتجاهات في الحالتين.',
			'homeLayout.enableHeroFirst' => 'فعّل البطاقة البارزة أولًا',
			'homeLayout.showOnHome' => 'إظهار في الصفحة الرئيسية',
			'homeLayout.home' => 'الرئيسية',
			'homeLayout.removeFromHome' => 'إزالة من الصفحة الرئيسية',
			'homeLayout.selectRowsFirst' => 'اختر صفوف الصفحة الرئيسية أدناه أولًا.',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} صفوف يديرها Plex',
			'homeLayout.continueWatching' => 'متابعة المشاهدة',
			'homeLayout.continueWatchingLibraryDescription' => 'صف استئناف المشاهدة الخاص بهذه المكتبة',
			'homeLayout.continueWatchingHomeDescription' => 'صف استئناف المشاهدة المعروض في الصفحة الرئيسية',
			'homeLayout.nextUpHomeDescription' => 'صف الحلقة التالية غير المشاهدة، ويظهر بشكل منفصل في الصفحة الرئيسية',
			'homeLayout.library' => 'المكتبة',
			'homeLayout.showInRecommended' => 'إظهار ضمن توصيات المكتبة',
			'homeLayout.customPlexRow' => 'صف Plex مخصّص',
			'homeLayout.heroNeedsLibrary' => 'حدّد المكتبة أولًا ليكون للبطاقة البارزة مكان تظهر فيه',
			'homeLayout.heroNeedsSurface' => 'حدّد المكتبة أو الصفحة الرئيسية أولًا ليكون للبطاقة البارزة مكان تظهر فيه',
			'homeLayout.removeHub' => 'إزالة قسم المحتوى',
			'homeLayout.noPlexRows' => 'لم يُرجع Plex أي صفوف يديرها لهذه المكتبة.',
			'homeLayout.openDetails' => 'فتح التفاصيل',
			'homeLayout.heroCards' => 'البطاقات البارزة',
			'homeLayout.tapHeroCard' => 'عند النقر على بطاقة بارزة',
			'homeLayout.tvPlayFocus' => 'جهاز التحكم: الانتقال إلى زر التشغيل',
			'homeLayout.tvPlayFocusDescription' => 'يتوقف التنقّل إلى الأسفل على زر التشغيل قبل الانتقال إلى الصف التالي. عند الإيقاف، ينتقل مباشرةً إلى الصف التالي.',
			'homeLayout.tvWrap' => 'جهاز التحكم: تكرار التنقّل بين البطاقات البارزة',
			'homeLayout.tvWrapDescription' => 'الضغط على اليسار عند البطاقة الأخيرة يعيدك إلى الأولى. عند إيقاف الخيار، يتوقف التنقل عند البطاقة الأخيرة. الضغط على اليمين عند البطاقة الأولى ينقلك دائمًا إلى الشريط الجانبي.',
			'homeLayout.castOnHero' => 'طاقم التمثيل في البطاقات البارزة',
			'homeLayout.castOnHeroDescription' => 'يعرض طاقم التمثيل أسفل البطاقة البارزة. عند الإيقاف، يظهر العنوان والملخّص فقط.',
			'homeLayout.customRows' => 'صفوف مخصّصة',
			'homeLayout.loading' => 'جارٍ تحميل تخطيط الصفحة الرئيسية…',
			'homeLayout.noCustomRows' => 'لا توجد صفوف مخصّصة بعد',
			'homeLayout.addRowHint' => 'اختر «إضافة صف إلى الرئيسية» لإنشاء صف.',
			'homeLayout.addHomeRow' => 'إضافة صف إلى الرئيسية',
			'homeLayout.addHomeRowDescription' => 'اختر فئة، وسيُضاف الصف الجديد إلى منظّم الصفوف تلقائيًا',
			'homeLayout.removeRow' => 'إزالة الصف',
			'homeLayout.recentlyAdded' => 'أُضيف مؤخرًا',
			'homeLayout.recentlyReleased' => 'صدر مؤخرًا',
			'homeLayout.movieCollections' => 'مجموعات الأفلام',
			'homeLayout.showCollections' => 'مجموعات المسلسلات',
			'homeLayout.rowTitle' => 'عنوان الصف',
			'homeLayout.content' => 'المحتوى',
			'homeLayout.showThisRowIn' => 'إظهار هذا الصف في:',
			'homeLayout.libraryRecommended' => 'توصيات المكتبة',
			'homeLayout.heroCard' => 'بطاقة بارزة',
			'homeLayout.heroCardDescription' => 'يعرض بطاقة دوّارة بعرض الشاشة بدلًا من صف الملصقات.',
			'homeLayout.heroUnavailableDescription' => 'متاح فقط عندما يعرض الصف عناوين مجموعة واحدة مباشرةً. عند اختيار أكثر من مجموعة، لا توجد مجموعة عناوين واحدة للتنقّل بينها.',
			'homeLayout.librariesSelection' => 'المكتبات (اتركها كلها دون تحديد لتضمين جميع المكتبات)',
			'homeLayout.librariesMergedDescription' => 'تُدمج كل المكتبات المحدّدة هنا في هذا الصف الواحد.',
			'homeLayout.movieCollectionsSelection' => 'مجموعات الأفلام (اتركها كلها دون تحديد لتضمين كل المجموعات في المكتبات المختارة)',
			'homeLayout.showCollectionsSelection' => 'مجموعات المسلسلات (اتركها كلها دون تحديد لتضمين كل المجموعات في المكتبات المختارة)',
			'homeLayout.collectionRowsDescription' => 'إذا طابقت مجموعة واحدة، تظهر عناوينها مباشرةً في الصف. وإذا طابقت عدة مجموعات، تظهر كل مجموعة كملصق واحد؛ انقر عليه لفتحها.',
			'homeLayout.allCollections' => 'كل المجموعات',
			'homeLayout.noRowsHere' => 'لا توجد صفوف هنا بعد.',
			'homeLayout.hideWatchedRows' => 'إخفاء العناصر المشاهدة من الصفوف',
			'homeLayout.hideWatchedRowsDescription' => 'تُزال العناوين التي شاهدتها بالكامل من صفوف الرئيسية وتوصيات المكتبة، وتبقى العناوين التي لا تزال تشاهدها.',
			'homeLayout.untitledCollection' => 'مجموعة بلا عنوان',
			'homeLayout.moveRowHint' => 'أعلى/أسفل: نقل الصف · اختيار: وضعه هنا · رجوع: إلغاء',
			'homeLayout.organizeRowsHint' => 'اختيار الصف أو الضغط المطوّل على اختيار: نقله · يمين/يسار: خيارات الصف · رجوع: إنهاء',
			'homeLayout.layoutNavDescription' => 'اختيار الصفوف والمكتبات وفئات المجموعات',
			'homeLayout.editHomeRow' => 'تعديل صف الصفحة الرئيسية',
			'homeLayout.resetHeroButton' => 'استعادة تخطيط بانر Plezy الأصلي',
			'homeLayout.reorderingUnlocked' => 'إعادة الترتيب متاحة',
			'homeLayout.reorderingLocked' => 'إعادة الترتيب مقفلة',
			'homeLayout.rowsCanBeDragged' => 'يمكن سحب الصفوف؛ انقر على القفل لمنع ذلك',
			'homeLayout.tapLockToDrag' => 'انقر على القفل لسحب الصفوف',
			'homeLayout.customRowLabel' => ({required Object title}) => 'مخصّص: ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => 'إخفاء',
			'homeLayout.remove' => 'إزالة',
			'homeLayout.libraryResumeRow' => 'صف استئناف المشاهدة الخاص بهذه المكتبة',
			'homeLayout.pressAgainToDelete' => 'اضغط مرة أخرى للحذف',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => 'مفعّل',
			'homeLayout.resetHeroButtonDescription' => 'يُوقف عرض الصفوف كبطاقات بارزة، ويُعيد البانر الدوّار الواحد إلى الأعلى كما كان سابقًا. يبقى ترتيب الصفوف كما هو.',
			'platform.localNetworkPermission' => 'يتصل PlezyNG بخوادم الوسائط وأجهزة التشغيل على شبكتك المحلية.',
			'platform.locationPermission' => 'يستخدم PlezyNG إذن الموقع عندما يتطلبه iOS للتعرف على شبكتك المحلية والاتصال بخوادم الوسائط.',
			'platform.photoLibraryPermission' => 'اختر صورًا من مكتبة الصور لاستخدامها كصور للوسائط.',
			'platform.cameraPermission' => 'امسح رموز QR لإقران جهاز تحكم مرافق.',
			'fileSources.title' => 'الملفات والكتب',
			'fileSources.subtitle' => 'اقرأ واستمع وشاهد من ملفاتك الخاصة.',
			'fileSources.add' => 'إضافة مصدر',
			'fileSources.importFiles' => 'استيراد ملفات',
			'fileSources.localFiles' => 'على هذا الجهاز',
			'fileSources.source' => 'المصدر',
			'fileSources.name' => 'الاسم',
			'fileSources.endpoint' => 'عنوان الخادم',
			'fileSources.root' => 'المجلد أو بادئة المسار',
			'fileSources.username' => 'اسم المستخدم',
			'fileSources.password' => 'كلمة المرور',
			'fileSources.token' => 'رمز API',
			'fileSources.accessKey' => 'معرّف مفتاح الوصول',
			'fileSources.secretKey' => 'مفتاح الوصول السري',
			'fileSources.sessionToken' => 'رمز الجلسة (اختياري)',
			'fileSources.region' => 'المنطقة',
			'fileSources.clientId' => 'معرّف عميل OAuth',
			'fileSources.clientSecret' => 'سر عميل OAuth (لـ Google على سطح المكتب فقط)',
			'fileSources.allowHttp' => 'السماح باتصال HTTP غير المشفر على شبكة موثوقة',
			'fileSources.connect' => 'اتصال',
			'fileSources.cancel' => 'إلغاء',
			'fileSources.save' => 'حفظ',
			'fileSources.close' => 'إغلاق',
			'fileSources.removeSource' => 'قطع اتصال المصدر',
			'fileSources.disconnectMessage' => 'هل تريد قطع الاتصال بهذا المصدر؟ ستبقى الملفات المنزّلة وسجل القراءة والاستماع على هذا الجهاز.',
			'fileSources.localFolder' => 'اختيار المجلد',
			'fileSources.empty' => 'لا شيء هنا حتى الآن',
			'fileSources.emptyHint' => 'أضف مصدرًا أو استورد كتابًا أو كتابًا صوتيًا أو موسيقى أو فيديو.',
			'fileSources.search' => 'البحث في هذا المجلد',
			'fileSources.searchCached' => 'البحث في المكتبة المحفوظة',
			'fileSources.refresh' => 'تحديث',
			'fileSources.loadMore' => 'تحميل المزيد',
			'fileSources.offline' => 'متاح دون اتصال',
			'fileSources.download' => 'حفظ للاستخدام دون اتصال',
			'fileSources.removeDownload' => 'إزالة النسخة المحفوظة دون اتصال',
			'fileSources.continueReading' => 'متابعة القراءة',
			'fileSources.continueListening' => 'متابعة الاستماع',
			'fileSources.continueWatching' => 'متابعة المشاهدة',
			'fileSources.read' => 'قراءة',
			'fileSources.listen' => 'الاستماع',
			'fileSources.play' => 'تشغيل',
			'fileSources.pause' => 'إيقاف مؤقت',
			'fileSources.stop' => 'إيقاف',
			'fileSources.startOver' => 'البدء من جديد',
			'fileSources.finished' => 'مكتمل',
			'fileSources.markFinished' => 'وضع علامة مكتمل',
			'fileSources.markUnfinished' => 'وضع علامة غير مكتمل',
			'fileSources.editions' => 'الإصدارات والملفات',
			'fileSources.chapters' => 'الفصول',
			'fileSources.bookmarks' => 'الإشارات المرجعية والملاحظات',
			'fileSources.bookmark' => 'إضافة إشارة مرجعية',
			'fileSources.highlight' => 'تمييز النص',
			'fileSources.note' => 'ملاحظة',
			'fileSources.delete' => 'حذف',
			'fileSources.export' => 'تصدير الملاحظات',
			'fileSources.exported' => 'تم تصدير الملاحظات',
			'fileSources.sync' => 'مزامنة التقدم',
			'fileSources.synced' => 'تمت مزامنة التقدم',
			'fileSources.conflict' => 'موضع القراءة أو الاستماع مختلف على جهاز آخر. اختر الموضع الذي تريد المتابعة منه.',
			'fileSources.useLocal' => 'استخدم هذا الجهاز',
			'fileSources.useRemote' => 'استخدام موضع الجهاز الآخر',
			'fileSources.history' => 'سجل المواضع',
			'fileSources.groupAudio' => 'الاستماع ككتاب صوتي واحد',
			'fileSources.groupHint' => 'يجمع الملفات الصوتية المحمّلة حاليًا في هذا المجلد. حمّل جميع الصفحات أولًا.',
			'fileSources.order' => 'ترتيب الملفات',
			'fileSources.moveUp' => 'تحرك إلى الأعلى',
			'fileSources.moveDown' => 'تحرك إلى أسفل',
			'fileSources.speed' => 'سرعة التشغيل',
			'fileSources.sleep' => 'مؤقّت النوم',
			'fileSources.sleepOff' => 'إيقاف',
			'fileSources.endChapter' => 'نهاية الفصل',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} دقيقة', one: 'دقيقة', two: 'دقيقتان', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} دقائق', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} دقيقة', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} دقيقة', ), 
			'fileSources.skipBack' => 'رجوع للخلف',
			'fileSources.skipForward' => 'تقديم للأمام',
			'fileSources.smartRewind' => 'الرجوع الذكي بعد الإيقاف المؤقت',
			'fileSources.playbackOptions' => 'خيارات الاستماع',
			'fileSources.remaining' => ({required Object time}) => 'متبقٍ ${time}',
			'fileSources.contents' => 'جدول المحتويات',
			'fileSources.readerSettings' => 'إعدادات القراءة',
			'fileSources.fontSize' => 'حجم النص',
			'fileSources.lineHeight' => 'تباعد الأسطر',
			'fileSources.margin' => 'الهوامش',
			'fileSources.font' => 'نوع الخط',
			'fileSources.serif' => 'خط ذو زوائد',
			'fileSources.sans' => 'خط بلا زوائد',
			'fileSources.mono' => 'خط ثابت العرض',
			'fileSources.columns' => 'الأعمدة',
			'fileSources.scroll' => 'التمرير عموديًا',
			'fileSources.justify' => 'ضبط محاذاة النص',
			'fileSources.readerTheme' => 'مظهر الصفحة',
			'fileSources.appTheme' => 'اتباع سمة التطبيق',
			'fileSources.paper' => 'الورق',
			'fileSources.sepia' => 'بني فاتح',
			'fileSources.night' => 'ليلي',
			'fileSources.readAloud' => 'قراءة هذه الصفحة بصوت عالٍ',
			'fileSources.readAlong' => 'متابعة القراءة مع الصوت',
			'fileSources.stopReading' => 'إيقاف السرد',
			'fileSources.searchBook' => 'البحث في الكتاب',
			'fileSources.noMatches' => 'لا توجد نتائج مطابقة',
			'fileSources.previousPage' => 'الصفحة السابقة',
			'fileSources.nextPage' => 'الصفحة التالية',
			'fileSources.page' => ({required Object number}) => 'الصفحة ${number}',
			'fileSources.externalBlocked' => 'يتم تعطيل الروابط الخارجية للكتاب في القارئ.',
			'fileSources.loading' => 'فتح...',
			'fileSources.narrator' => 'الراوي',
			'fileSources.audio' => 'الصوت',
			'fileSources.video' => 'فيديو',
			'fileSources.ebooks' => 'كتب إلكترونية',
			'fileSources.all' => 'الكل',
			'fileSources.downloads' => 'الملفات المحفوظة دون اتصال',
			'fileSources.confirmDelete' => 'هل تريد إزالة النسخة المحددة المحفوظة دون اتصال؟ سيبقى موضعك وملاحظاتك محفوظين.',
			'fileSources.errorAuthentication' => 'سجّل الدخول مجددًا لإعادة الاتصال بهذا المصدر.',
			'fileSources.errorPermission' => 'لم يمنح هذا المصدر إمكانية الوصول إلى الملف المطلوب.',
			'fileSources.errorUnavailable' => 'المصدر غير متاح. حاول مجددًا أو افتح نسخة محفوظة دون اتصال.',
			'fileSources.errorUnsupported' => 'هذه الصيغة أو طريقة الاتصال غير مدعومة على هذا الجهاز. راجع دليل إعداد المصدر.',
			'fileSources.errorInvalidData' => 'لا يمكن قراءة هذا الملف أو استجابة الخادم بأمان.',
			'fileSources.errorCancelled' => 'تم إلغاء العملية.',
			'fileSources.errorConflict' => 'تغيّر الموضع في جلسة أخرى. أعد فتح العنصر لاختيار موضع المتابعة.',
			'fileSources.signIn' => 'تسجيل الدخول',
			'fileSources.reconnect' => 'إعادة الاتصال',
			'fileSources.folderHelp' => 'اتركه فارغًا للبدء من جذر المصدر. تتضمن عناوين S3 اسم حاوية التخزين.',
			'fileSources.preferences' => 'تفضيلات',
			'fileSources.timePosition' => 'موضع التشغيل',
			'fileSources.audioTrack' => 'المسار الصوتي',
			'fileSources.subtitleTrack' => 'مسار الترجمة',
			'fileSources.none' => 'لا شيء',
			'fileSources.fullscreen' => 'ملء الشاشة',
			'fileSources.syncLocation' => 'مجلد مزامنة التقدم (اختياري)',
			'fileSources.syncLocationHint' => 'مجلد WebDAV مخصص لحالة PlezyNG. تُستخدم الكتابة المشروطة، وتبقى ملفات الوسائط دون تغيير.',
			'fileSources.audiobooks' => 'كتب صوتية',
			'fileSources.comics' => 'قصص مصوّرة',
			'fileSources.scan' => 'البحث عن الكتب والوسائط',
			'fileSources.browserReader' => 'فتح القارئ',
			'fileSources.browserReaderHelp' => 'القارئ مفتوح في متصفحك. أبقِ PlezyNG مفتوحًا لحفظ موضعك وملاحظاتك.',
			'fileSources.on' => 'تشغيل',
			'fileSources.advancedSetup' => 'تسجيل التطبيق',
			'fileSources.microsoftSignIn' => 'تسجيل الدخول باستخدام Microsoft',
			'fileSources.zoomIn' => 'تكبير',
			'fileSources.zoomOut' => 'تصغير',
			'fileSources.fitPage' => 'ملاءمة الصفحة',
			'fileSources.fitWidth' => 'ملاءمة العرض',
			'fileSources.actualSize' => 'الحجم الأصلي',
			'fileSources.goToPage' => 'الانتقال إلى صفحة',
			'fileSources.goToSection' => 'الانتقال إلى فصل',
			'fileSources.pageRange' => ({required Object count}) => 'أدخل رقمًا من ١ إلى ${count}',
			'fileSources.pageLayout' => 'تخطيط الصفحات',
			'fileSources.automatic' => 'تلقائي',
			'fileSources.singlePage' => 'صفحة واحدة',
			'fileSources.twoPages' => 'صفحتان',
			'fileSources.readingDirection' => 'اتجاه القراءة',
			'fileSources.leftToRight' => 'من اليسار لليمين',
			'fileSources.rightToLeft' => 'من اليمين لليسار',
			'fileSources.letterSpacing' => 'تباعد الأحرف',
			'fileSources.wordSpacing' => 'تباعد الكلمات',
			'fileSources.readerControlsHelp' => 'استخدم إيماءة التكبير بإصبعين أو أزرار التكبير لتكبير الصفحات، واسحب لتحريكها. استخدم Ctrl/⌘ مع + أو − لضبط التكبير، وCtrl/⌘ مع 0 لإعادة ضبطه. استخدم Page Up وPage Down للتنقل بين الصفحات.',
			'fileSources.imagePage' => 'صفحة قصة مصوّرة',
			'fileSources.resetReader' => 'إعادة تعيين تفضيلات القراءة',
			'fileSources.zoom' => 'التكبير',
			'fileSources.useFiles' => 'استخدام الملفات والكتب',
			'fileSources.cancelScan' => 'إلغاء الفحص',
			'fileSources.googleDrive' => 'Google Drive',
			'lending.title' => 'المكتبات العامة',
			'lending.add' => 'إضافة مكتبة',
			'lending.other' => 'مكتبة أخرى',
			'lending.libraryName' => 'اسم المكتبة',
			'lending.libraryUrl' => 'موقع المكتبة',
			'lending.libraryUrlHint' => 'استخدم صفحة فهرس مكتبتك أو صفحة تسجيل الدخول.',
			'lending.intro' => 'استعر من مكتبتك واحتفظ بكتبك في متناولك.',
			'lending.handoff' => 'سجّل الدخول واستعر واقرأ بأمان عبر خدمة مكتبتك نفسها.',
			'lending.openService' => 'فتح المكتبة',
			'lending.findLibrary' => 'العثور على مكتبة',
			'lending.search' => 'البحث عن كتب ومؤلفين',
			'lending.catalogue' => 'الفهرس',
			'lending.loans' => 'الاستعارات',
			'lending.holds' => 'الحجوزات',
			'lending.signIn' => 'تسجيل الدخول عبر مكتبتك',
			'lending.waiting' => 'أكمل تسجيل الدخول في المتصفح، ثم عُد إلى هنا.',
			'lending.cancel' => 'إلغاء',
			'lending.disconnect' => 'إزالة المكتبة',
			'lending.disconnectMessage' => 'هل تريد إزالة هذه المكتبة من هذا الملف الشخصي؟ ستبقى استعاراتك وحجوزاتك لدى المكتبة.',
			'lending.getBook' => 'الحصول على الكتاب',
			'lending.checkAvailability' => 'التحقق من التوفر',
			'lending.available' => 'متاح للاستعارة',
			'lending.unavailable' => 'غير متاح حاليًا',
			'lending.borrow' => 'استعارة',
			'lending.placeHold' => 'حجز',
			'lending.returnBook' => 'إرجاع مبكر',
			'lending.cancelHold' => 'إلغاء الحجز',
			'lending.confirmBorrow' => 'هل تريد استعارة هذا العنوان من مكتبتك؟',
			'lending.confirmReturn' => 'هل تريد إرجاع هذا العنوان الآن؟ قد تحتاج إلى استعارته مجددًا للمتابعة.',
			'lending.confirmCancelHold' => 'هل تريد إلغاء حجزك لهذا العنوان؟',
			'lending.email' => 'البريد الإلكتروني لإشعارات الحجز',
			'lending.due' => ({required Object date}) => 'موعد الإرجاع: ${date}',
			'lending.queue' => ({required Object position}) => 'ترتيبك في قائمة الانتظار: ${position}',
			'lending.empty' => 'لا توجد عناوين هنا بعد.',
			'lending.openLibraryNote' => 'استكشف فهرس Open Library. تظهر خيارات القراءة والاستعارة في صفحة كل عنوان.',
			'lending.more' => 'تحميل المزيد',
			'lending.gateway' => 'خدمة تسجيل الدخول إلى المكتبة',
			'lending.gatewayHint' => 'توفرها مكتبتك أو مسؤول PlezyNG.',
			'lending.advanced' => 'تكامل المكتبة',
			'lending.loadLibraries' => 'اختيار مكتبتك',
			'lending.expired' => 'انتهت مدة هذه الاستعارة.',
			'lending.updated' => 'تم تحديث المكتبة',
			'lending.continueService' => 'المتابعة في الخدمة',
			'lending.comingSoon' => 'الاستعارة داخل التطبيق · قريبًا',
			'lending.comingSoonDescription' => 'تكامل Libby قادم قريبًا. يمكنك استخدام مكتبتك في Libby بينما نكمل الربط.',
			'lending.suspendHold' => 'تعليق الحجز',
			'lending.resumeHold' => 'استئناف الحجز',
			'lending.suspendMessage' => 'هل تريد الاحتفاظ بترتيبك في قائمة الانتظار والسماح للقارئ التالي باستعارة هذه النسخة؟ يمكنك استئناف الحجز لاحقًا.',
			'lending.resumeMessage' => 'هل تريد استئناف هذا الحجز لتعرض عليك المكتبة النسخة التالية المتاحة؟',
			'lending.editEmail' => 'تغيير البريد الإلكتروني للإشعارات',
			'audiobook.syncTitle' => 'القراءة والاستماع Sync',
			'audiobook.syncHelp' => 'الحفاظ على مواقف القراءة، ومواقف الاستماع، وحالة الانتهاء، والملاحظات والملاحظات عبر أجهزتك.اختر حساب التخزين المرفق واستخدم نفس رمز المزامنة على كل جهاز.',
			'audiobook.addSyncSource' => 'إضافة Google Drive، OneDrive، Dropbox، WebDAV أو S3 في الملفات والكتب أولاً.',
			'audiobook.syncDestination' => 'حساب التخزين المتزامن',
			'audiobook.syncFolder' => 'المجلد أو المجلد السابق',
			'audiobook.syncFolderHelp' => 'استخدم مجلدًا منفصلًا موجودًا داخل مصدر WebDAV الخاص بك، أو مقدمة S3 مخصصة.',
			'audiobook.syncCode' => 'رمز المزامنة الخاص',
			'audiobook.syncCodeHelp' => 'قم بإنشاء رمز على جهازك الأول، ثم أدخل هذا الرمز على أجهزتك الأخرى.حافظ على نسخة خاصة: هو المفتاح للحالة المشفرة الخاصة بك.استخدم رمزًا مختلفًا لكل شخص.',
			'audiobook.showCode' => 'عرض أو إخفاء رمز التزامن',
			'audiobook.newSyncCode' => 'إنشاء رمز مزامنة جديد',
			'audiobook.saveSync' => 'حفظ وتزامن',
			'audiobook.disableSync' => 'قم بإيقاف تشغيل Sync على هذا الجهاز',
			'audiobook.syncSourceDisconnect' => 'إزالة هذا المصدر سيتم إيقاف القراءة والاستماع المزامنة هنا.',
			'audiobook.syncReconnect' => 'إعادة توصيل حساب التخزين',
			'audiobook.lastSynced' => ({required Object time}) => 'آخر تصنيف في ${time}',
			'audiobook.syncPrivacy' => 'يتم تخزين التقدم المشفر والملاحظات فقط. لا يتم تحميل ملفات الصوت والكتب الإلكترونية والرموز الحساب وكلمات المرور. يستخدم Google Drive و OneDrive تخزين التطبيقات؛ يستخدم Dropbox PlezyNG Sync. يسمح التزامن قد يطلب إضافية إمكانية الوصول إلى الكتابة. في حين تم تشغيله، هذا الوجهة يمتلك التقدم التزامن؛ يبقى التقدم الخادم منفصلة. يمنع التزامن يحافظ على التاريخ المحلي والحالة البعيدة.',
			'audiobook.syncConflicts' => 'اقرأ أين تستعيد',
			'audiobook.conflictHelp' => 'تم إجراء هذه التغييرات بشكل مستقل.اختر الموقف أو نسخة علامة التبويب للحفاظ عليها. لا تفوز تلقائيًا بضعة ساعات متأخرة أو نسبة أعلى.',
			'audiobook.syncDevice' => ({required Object device}) => 'جهاز ${device}',
			'audiobook.syncUnknownDevice' => 'جهاز غير معروف',
			'audiobook.deletedBookmark' => 'إلغاء الكتابة',
			'audiobook.finished' => 'الانتهاء',
			'audiobook.readingPosition' => ({required Object percent}) => 'قراءة · ${percent}%',
			'audiobook.chapterTimeline' => 'الفصل التقدم',
			'audiobook.bookTimeline' => 'كتاب التقدم الكامل',
			'audiobook.bookRemaining' => ({required Object time}) => 'الوقت المتبقي في هذا الكتاب: ${time}',
			'audiobook.chapterRemaining' => ({required Object time}) => 'الوقت المتبقي في هذا الفصل: ${time}',
			'audiobook.unknownRemaining' => 'إجمالي الوقت المتاحة كما يتم لعب الأجزاء',
			'audiobook.undoSeek' => 'آخر البحث',
			'audiobook.customSpeed' => 'سرعة اللعب المخصصة',
			'audiobook.speedHelp' => 'اختر سرعة تتراوح بين 0.25 × إلى 4 ×.',
			'audiobook.apply' => 'تطبيق',
			'audiobook.customSleep' => 'ساعات النوم المخصصة',
			'audiobook.sleepMinutes' => 'الدقائق (1 – 1440)',
			'audiobook.sleepChapters' => ({required Object count}) => 'توقف بعد ${count} الفصول',
			'audiobook.extendSleep' => 'إضافة 5 دقائق',
			'audiobook.sleepRemaining' => ({required Object time}) => 'موعد النوم: ${time}',
			'audiobook.useDefaults' => 'استخدم هذه التحكمات الاستماعية للكتب الجديدة',
			'audiobook.librarySort' => 'الكتب المختلفة',
			'audiobook.sortTitle' => 'العنوان',
			'audiobook.sortAuthor' => 'الكاتب',
			'audiobook.sortNarrator' => 'القارئ',
			'audiobook.sortSeries' => 'سلسلة الأوامر',
			'audiobook.sortRecent' => 'افتتح مؤخرا',
			'audiobook.statusFilter' => 'حالة القراءة',
			'audiobook.statusAll' => 'جميع الكتب',
			'audiobook.statusNew' => 'لم يبدأ',
			'audiobook.statusProgress' => 'في التقدم',
			'audiobook.statusFinished' => 'الانتهاء',
			'audiobook.goToTime' => 'اذهب إلى الزمن',
			'audiobook.timeHelp' => 'ساعات: دقائق: ثواني، أو دقائق: ثواني',
			_ => null,
		};
	}
}
