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
class TranslationsUz extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsUz({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.uz,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <uz>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsUz _root = this; // ignore: unused_field

	@override 
	TranslationsUz $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsUz(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$uz app = _Translations$app$uz._(_root);
	@override late final _Translations$cast$uz cast = _Translations$cast$uz._(_root);
	@override late final _Translations$automation$uz automation = _Translations$automation$uz._(_root);
	@override late final _Translations$notifications$uz notifications = _Translations$notifications$uz._(_root);
	@override late final _Translations$appIcon$uz appIcon = _Translations$appIcon$uz._(_root);
	@override late final _Translations$auth$uz auth = _Translations$auth$uz._(_root);
	@override late final _Translations$common$uz common = _Translations$common$uz._(_root);
	@override late final _Translations$screens$uz screens = _Translations$screens$uz._(_root);
	@override late final _Translations$update$uz update = _Translations$update$uz._(_root);
	@override late final _Translations$appAccess$uz appAccess = _Translations$appAccess$uz._(_root);
	@override late final _Translations$settings$uz settings = _Translations$settings$uz._(_root);
	@override late final _Translations$themeEditor$uz themeEditor = _Translations$themeEditor$uz._(_root);
	@override late final _Translations$search$uz search = _Translations$search$uz._(_root);
	@override late final _Translations$hotkeys$uz hotkeys = _Translations$hotkeys$uz._(_root);
	@override late final _Translations$fileInfo$uz fileInfo = _Translations$fileInfo$uz._(_root);
	@override late final _Translations$mediaMenu$uz mediaMenu = _Translations$mediaMenu$uz._(_root);
	@override late final _Translations$rateSheet$uz rateSheet = _Translations$rateSheet$uz._(_root);
	@override late final _Translations$accessibility$uz accessibility = _Translations$accessibility$uz._(_root);
	@override late final _Translations$tooltips$uz tooltips = _Translations$tooltips$uz._(_root);
	@override late final _Translations$audioTracks$uz audioTracks = _Translations$audioTracks$uz._(_root);
	@override late final _Translations$videoControls$uz videoControls = _Translations$videoControls$uz._(_root);
	@override late final _Translations$messages$uz messages = _Translations$messages$uz._(_root);
	@override late final _Translations$subtitlingStyling$uz subtitlingStyling = _Translations$subtitlingStyling$uz._(_root);
	@override late final _Translations$mpvConfig$uz mpvConfig = _Translations$mpvConfig$uz._(_root);
	@override late final _Translations$dialog$uz dialog = _Translations$dialog$uz._(_root);
	@override late final _Translations$profiles$uz profiles = _Translations$profiles$uz._(_root);
	@override late final _Translations$connections$uz connections = _Translations$connections$uz._(_root);
	@override late final _Translations$accountPreferences$uz accountPreferences = _Translations$accountPreferences$uz._(_root);
	@override late final _Translations$discover$uz discover = _Translations$discover$uz._(_root);
	@override late final _Translations$errors$uz errors = _Translations$errors$uz._(_root);
	@override late final _Translations$libraries$uz libraries = _Translations$libraries$uz._(_root);
	@override late final _Translations$about$uz about = _Translations$about$uz._(_root);
	@override late final _Translations$serverSelection$uz serverSelection = _Translations$serverSelection$uz._(_root);
	@override late final _Translations$hubDetail$uz hubDetail = _Translations$hubDetail$uz._(_root);
	@override late final _Translations$logs$uz logs = _Translations$logs$uz._(_root);
	@override late final _Translations$detail$uz detail = _Translations$detail$uz._(_root);
	@override late final _Translations$startup$uz startup = _Translations$startup$uz._(_root);
	@override late final _Translations$licenses$uz licenses = _Translations$licenses$uz._(_root);
	@override late final _Translations$navigation$uz navigation = _Translations$navigation$uz._(_root);
	@override late final _Translations$explore$uz explore = _Translations$explore$uz._(_root);
	@override late final _Translations$liveTv$uz liveTv = _Translations$liveTv$uz._(_root);
	@override late final _Translations$collections$uz collections = _Translations$collections$uz._(_root);
	@override late final _Translations$playlists$uz playlists = _Translations$playlists$uz._(_root);
	@override late final _Translations$music$uz music = _Translations$music$uz._(_root);
	@override late final _Translations$watchTogether$uz watchTogether = _Translations$watchTogether$uz._(_root);
	@override late final _Translations$downloads$uz downloads = _Translations$downloads$uz._(_root);
	@override late final _Translations$shaders$uz shaders = _Translations$shaders$uz._(_root);
	@override late final _Translations$companionRemote$uz companionRemote = _Translations$companionRemote$uz._(_root);
	@override late final _Translations$videoSettings$uz videoSettings = _Translations$videoSettings$uz._(_root);
	@override late final _Translations$performanceOverlay$uz performanceOverlay = _Translations$performanceOverlay$uz._(_root);
	@override late final _Translations$externalPlayer$uz externalPlayer = _Translations$externalPlayer$uz._(_root);
	@override late final _Translations$metadataEdit$uz metadataEdit = _Translations$metadataEdit$uz._(_root);
	@override late final _Translations$matchScreen$uz matchScreen = _Translations$matchScreen$uz._(_root);
	@override late final _Translations$serverTasks$uz serverTasks = _Translations$serverTasks$uz._(_root);
	@override late final _Translations$trakt$uz trakt = _Translations$trakt$uz._(_root);
	@override late final _Translations$seerr$uz seerr = _Translations$seerr$uz._(_root);
	@override late final _Translations$services$uz services = _Translations$services$uz._(_root);
	@override late final _Translations$addServer$uz addServer = _Translations$addServer$uz._(_root);
	@override late final _Translations$watchLink$uz watchLink = _Translations$watchLink$uz._(_root);
	@override late final _Translations$homeLayout$uz homeLayout = _Translations$homeLayout$uz._(_root);
	@override late final _Translations$platform$uz platform = _Translations$platform$uz._(_root);
	@override late final _Translations$fileSources$uz fileSources = _Translations$fileSources$uz._(_root);
	@override late final _Translations$lending$uz lending = _Translations$lending$uz._(_root);
	@override late final _Translations$audiobook$uz audiobook = _Translations$audiobook$uz._(_root);
	@override late final _Translations$games$uz games = _Translations$games$uz._(_root);
}

// Path: app
class _Translations$app$uz extends Translations$app$en {
	_Translations$app$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: cast
class _Translations$cast$uz extends Translations$cast$en {
	_Translations$cast$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => 'Bir cihazda qurtlar';
	@override String get searching => 'Tadiqlarga xiyimni xiyimlarga...';
	@override String connectedTo({required Object device}) => '${device} qizga qizga';
	@override String get device => 'Tadiqadi';
	@override String get readyToCast => 'Hazardga bo‘qadi';
	@override String get subtitle => 'Subtitrlar';
	@override String get serverNotAvailable => 'Media server qiziziz.';
	@override String get stopCasting => 'Castingdan qurtum';
	@override String get castToDevice => 'U\'zadiya\'da qurtlar';
	@override String get noEpisodeAvailable => 'U\'zadi\'ni qaytadi yok.';
	@override String get startFailed => 'U\'zizga qurtlar. serveri kontroldan qurtlar, qaytarga qurtlam.';
}

// Path: automation
class _Translations$automation$uz extends Translations$automation$en {
	_Translations$automation$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => 'Video aktivni sessiya ko‘zadi.';
	@override String get profileNotFound => 'Bu Plezy profili qothathathathatdi.';
}

// Path: notifications
class _Translations$notifications$uz extends Translations$notifications$en {
	_Translations$notifications$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => 'Yeni epizod';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appIcon
class _Translations$appIcon$uz extends Translations$appIcon$en {
	_Translations$appIcon$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ilova belgisi';
	@override String get defaultIcon => 'Standart';
	@override String get current => 'Joriy belgi';
	@override String get locked => 'Hayatdan qaplan qaplan';
	@override String get lockedHint => '7 dayni provayni ko‘zingiz o‘zingizga PlezyNG qaytadi, alternatiyik ikonlar kullan.';
	@override String get changeFailed => 'Ilova belgisini oʻzgartirib boʻlmadi';
	@override String get launcherHint => 'Yangi belgi PlezyNG-dan chiqqaningizdan soʻng bosh ekranda paydo boʻladi.';
	@override String get tvLauncherHint => 'Yangi banner PlezyNG-dan chiqqaningizdan soʻng paydo boʻladi. Android TV televizor qayta ishga tushirilmaguncha eskisini koʻrsatishda davom etishi mumkin.';
	@override late final _Translations$appIcon$names$uz names = _Translations$appIcon$names$uz._(_root);
}

// Path: auth
class _Translations$auth$uz extends Translations$auth$en {
	_Translations$auth$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Plex orqali kirish';
	@override String get showQRCode => 'QR kodni koʻrsatish';
	@override String get authenticate => 'Tasdiqlash';
	@override String get authenticationTimeout => 'Tasdiqlash vaqti tugadi. Iltimos, qaytadan urinib koʻring.';
	@override String get scanQRToSignIn => 'Kirish uchun ushbu QR kodni skanerlang';
	@override String get waitingForAuth => 'Tasdiqlanish kutilmoqda...\nBrauzeringizdan kiring.';
	@override String get useBrowser => 'Brauzerdan foydalanish';
	@override String get or => 'yoki';
	@override String connectToMediaBrowser({required Object product}) => '${product}ga ulanish';
	@override String get quickConnect => 'Tezkor ulanish';
	@override String get useQuickConnect => 'Tezkor ulanishdan foydalanish';
	@override String get quickConnectInstructions => 'Jellyfin-da Tezkor ulanishni oching va ushbu kodni kiriting.';
	@override String get quickConnectWaiting => 'Tasdiq kutilmoqda…';
	@override String get quickConnectCancel => 'Bekor qilish';
	@override String get quickConnectExpired => 'Tezkor ulanish vaqti tugadi. Qaytadan urinib koʻring.';
	@override String get localDataRecoveryRequired => 'PlezyNG qurilmadagi kirish ma’lumotlarini va qayta ishlanishini kutayotgan ijro ma’lumotlarini xavfsiz tiklay olmadi. Qayta kiring.';
	@override String get pinCheckRejected => 'Plex PIN tekshiruvi rad etildi';
	@override String get connectToDirectPlex => 'Mahalliy Plex serveriga ulanish';
}

// Path: common
class _Translations$common$uz extends Translations$common$en {
	_Translations$common$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Bekor qilish';
	@override String get save => 'Saqlash';
	@override String get close => 'Yopish';
	@override String get clear => 'Tozalash';
	@override String get reset => 'Qayta oʻrnatish';
	@override String get later => 'Keyinroq';
	@override String get submit => 'Yuborish';
	@override String get confirm => 'Tasdiqlash';
	@override String get retry => 'Qaytadan urinish';
	@override String get logout => 'Chiqish';
	@override String get unknown => 'Nomaʼlum';
	@override String get refresh => 'Yangilash';
	@override String get yes => 'Ha';
	@override String get no => 'Yoʻq';
	@override String get delete => 'Oʻchirish';
	@override String get edit => 'Tahrirlash';
	@override String get shuffle => 'Aralashtirish';
	@override String get addTo => 'Qoʻshish...';
	@override String get createNew => 'Yangi yaratish';
	@override String get connect => 'Ulanish';
	@override String get disconnect => 'Uzilish';
	@override String get play => 'Ijro etish';
	@override String get pause => 'Pauza';
	@override String get resume => 'Davom ettirish';
	@override String get error => 'Xatolik';
	@override String get search => 'Qidiruv';
	@override String get home => 'Bosh sahifa';
	@override String get back => 'Orqaga';
	@override String get settings => 'Sozlamalar';
	@override String get mute => 'Ovozni oʻchirish';
	@override String get ok => 'Tushunarli';
	@override String get off => 'Oʻchirilgan';
	@override String get options => 'Parametrlar';
	@override String seasonNumber({required Object number}) => '${number}-mavsum';
	@override String episodeNumberTitle({required Object number, required Object title}) => '${number}-qism - ${title}';
	@override String chapterNumber({required Object number}) => '${number}-boʻlim';
	@override String get reconnect => 'Qayta ulanish';
	@override String get viewAll => 'Barchasini koʻrish';
	@override String get checkingNetwork => 'Tarmoq tekshirilmoqda...';
	@override String get loadingServers => 'Serverlar yuklanmoqda...';
	@override String get connectingToServers => 'Serverlarga ulanmoqda...';
	@override String get startingOfflineMode => 'Oflayn rejim ishga tushmoqda...';
	@override String get loading => 'Yuklanmoqda...';
	@override String get fullscreen => 'Toʻliq ekran';
	@override String get exitFullscreen => 'Toʻliq ekrandan chiqish';
	@override String get pressBackAgainToExit => 'Chiqish uchun orqaga tugmasini yana bir bor bosing';
	@override late final _Translations$common$ratingSource$uz ratingSource = _Translations$common$ratingSource$uz._(_root);
	@override String get notAvailable => 'N/A';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
	@override late final _Translations$common$mediaKind$uz mediaKind = _Translations$common$mediaKind$uz._(_root);
}

// Path: screens
class _Translations$screens$uz extends Translations$screens$en {
	_Translations$screens$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Litsenziyalar';
	@override String get switchProfile => 'Profilni almashtirish';
	@override String get subtitleStyling => 'Subtitr sozlamalari';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Jurnallar';
}

// Path: update
class _Translations$update$uz extends Translations$update$en {
	_Translations$update$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get available => 'Yangilanish mavjud';
	@override String versionAvailable({required Object version}) => '${version} versiyasi mavjud';
	@override String currentVersion({required Object version}) => 'Joriy: ${version}';
	@override String get skipVersion => 'Ushbu versiyani oʻtkazib yuborish';
	@override String get viewRelease => 'Tafsilotlarni koʻrish';
	@override String get latestVersion => 'Sizda eng soʻnggi versiya oʻrnatilgan';
	@override String get checkFailed => 'Yangilanishlarni tekshirish imkoni boʻlmadi';
}

// Path: appAccess
class _Translations$appAccess$uz extends Translations$appAccess$en {
	_Translations$appAccess$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => '7 günni bütün aktiviyatlardan özgürni qaytdan.';
	@override String get description => 'PlezyNG’ning barcha funksiyalaridan yetti kun bepul foydalanib ko‘ring. Sinov davrida to‘lov olinmaydi va obuna talab qilinmaydi. Sinovdan so‘ng do‘konda ko‘rsatilgan narxda bir marta xarid qilib, PlezyNG’dan cheksiz foydalanishingiz mumkin.';
	@override String get trialEndedDescription => 'Do‘konda ko‘rsatilgan narxda bir marta xarid qilib, PlezyNG’ning barcha funksiyalarini umrbod oching. Obuna talab qilinmaydi.';
	@override String get startTrial => '7 day free proving sizga qaytadi.';
	@override String get trialActive => '7 day full-feature proving siz aktivir.';
	@override String get trialEnded => '7 kunlik sinov muddati tugadi';
	@override String get trialStartFailed => 'Bu cihazda testini salmaydi. lütfen qaytarga.';
	@override String get lifetimeTitle => 'PlezyNG hayri boʻlu boʻlu';
	@override String get lifetimeBody => 'Rahmat! PlezyNG’ning barcha funksiyalaridan umrbod foydalanishingiz mumkin.';
	@override String get manageTitle => 'PlezyNG lifetime qasizga';
	@override String get manageDescription => '7 gün bu bütün funksiyalardan free-to-free, sonra sizga mağazadan bir payga o‘zayda o‘ziyada o‘zib.';
	@override String buy({required Object price}) => 'Barcha funksiyalarni ${price} evaziga ochish';
	@override String get loadingPrice => 'Buqqqqga market market...';
	@override String get retryPrice => 'Reddit bilan bakup';
	@override String get restore => 'Hayat bilan buyuj';
	@override String get pending => 'Siz qaplan o‘ziz o‘zib o‘zig o‘ziga o‘zige o‘zigi o‘zaga o‘zaya o‘zay o‘ziy o‘ziye o‘ziyan o‘zayn o‘zinc o‘zyan o‘zayan o‘zac o‘zinin o‘ziyar o‘zqan o‘zari o‘zani o‘zaman o‘zadan o‘zagan o‘zanc o‘z.';
	@override String get storeUnavailable => 'Siz bu mağazada abonlikliklik oluyiz. siz bu mağazadan abonliklik olayiz.';
	@override String get productNotFound => 'PlezyNG lifetime unlock bu mağazada yet o‘zayda olmaygan.';
	@override String get productQueryFailed => 'Do‘kondagi narxni yuklab bo‘lmadi. Ulanishingizni tekshirib, qayta urinib ko‘ring.';
	@override String get purchaseFailed => 'Bu qotomiyadi ko‘zadi. qaytarga ko‘z.';
	@override String get restoreFailed => 'Sizga buyni qaytarga qotʻyadi. qaytarga qaytarga.';
	@override String get nothingToRestore => 'No PlezyNG lifetime buy bu mağazalar hesab için bulgan.';
}

// Path: settings
class _Translations$settings$uz extends Translations$settings$en {
	_Translations$settings$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Sozlamalar';
	@override String get supportDeveloper => 'PlezyNG-ni qoʻllab-quvvatlash';
	@override String get supportDeveloperDescription => 'Rivojlanishni qoʻllab-quvvatlash uchun xayriya qiling';
	@override String get lifetimeAccess => 'PlezyNG lifetime qasizga';
	@override String get language => 'Til';
	@override String get theme => 'Mavzu';
	@override String get appearance => 'Tashqi koʻrinish';
	@override String get detailPage => 'Detaylar Sayfadi';
	@override String get themeSongsEnabled => 'Theme lagular';
	@override String get themeSongsEnabledDescription => 'Playing tema lagular, media details o‘shayni.';
	@override String get themeSongVolume => 'Tomaq Song Volume';
	@override String get videoPlayback => 'Video ijrosi';
	@override String get videoPlaybackDescription => 'Ijro parametrlarini sozlang';
	@override String get advanced => 'Kengaytirilgan';
	@override String get episodePosterMode => 'Qism poster stili';
	@override String get seriesPoster => 'Serial posteri';
	@override String get seasonPoster => 'Mavsum posteri';
	@override String get episodeThumbnail => 'Kadr koʻrinishi';
	@override String get showHeroSectionDescription => 'Bosh sahifada tanlangan kontent karuselini koʻrsatish';
	@override String get secondsLabel => 'Soniya';
	@override String get minutesLabel => 'Daqiqa';
	@override String get secondsShort => 'son';
	@override String get minutesShort => 'daq';
	@override String durationHint({required Object min, required Object max}) => 'Vaqtni kiriting (${min}-${max})';
	@override String get systemTheme => 'Tizim sozlamasi';
	@override String get lightTheme => 'Yorugʻ';
	@override String get darkTheme => 'Toʻq';
	@override String get oledTheme => 'OLED';
	@override String get emberTheme => 'Choʻgʻ';
	@override String get glacierTheme => 'Muzlik';
	@override String get forestTheme => 'Oʻrmon';
	@override String get plumTheme => 'Olxoʻri';
	@override String get paperTheme => 'Qogʻoz';
	@override String get libraryDensity => 'Kutubxona zichligi';
	@override String get displayScale => 'Ekran miqyosi';
	@override String get compact => 'Ixcham';
	@override String get comfortable => 'Qulay';
	@override String get gridSpacing => 'Toʻr oraligʻi';
	@override String get gridSpacingTight => 'Zich';
	@override String get gridSpacingNormal => 'Oddiy';
	@override String get gridSpacingSpacious => 'Keng';
	@override String get tvCornerSpotlightBackdrop => 'Burchak yoritish foni';
	@override String get tvCornerSpotlightBackdropDescription => 'Fonni toʻliq ekran oʻrniga yuqori oʻng burchakda koʻrsatish';
	@override String get viewMode => 'Koʻrish rejimi';
	@override String get gridView => 'Toʻrsimon';
	@override String get listView => 'Roʻyxat';
	@override String get showHeroSection => 'Asosiy boʻlimni koʻrsatish';
	@override String get showHomeBackdrop => 'Home Backdrop Artwork\'i yuxaylar';
	@override String get showHomeBackdropDescription => 'U\'zizga\'da qaytadi qaytadi\'ni qaytadi';
	@override String get contentScreensaverEnabled => 'Ekranlarga';
	@override String get contentScreensaverEnabledDescription => 'Full screen-sharing artwork ko‘zadi, app is idle.';
	@override String get contentScreensaverDelay => 'Ekranlarga qaytdan sonra';
	@override String get contentScreensaverLibraries => 'Screensaver librarlar';
	@override String get contentScreensaverLibrariesDescription => 'Ekran saqlagichi uchun rasmlar olinadigan kutubxonalarni tanlang. Hech biri tanlanmasa, barcha kutubxonalardagi rasmlar ishlatiladi.';
	@override String get contentScreensaverAllLibraries => 'All librarlar';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} librarlar seçkin';
	@override String get contentScreensaverNoLibraries => 'Bağlanmış medya librarlar yok.';
	@override String get contentScreensaverDismissHint => 'Bu\'da bir buton o\'t tapatni bo\'t tabatni';
	@override String get newEpisodeNotifications => 'Yangi qismlar haqida bildirishnomalar';
	@override String get newEpisodeNotificationsDescription => 'Tomosha qilib bo‘lgan serialingizga yangi qism qo‘shilganda xabar berish. Plezy ochiq bo‘lganda tekshiriladi.';
	@override String get continueWatchingRowSize => 'U\'qizga sizliklikliklik.';
	@override String continueWatchingRowSizeValue({required Object label}) => '${label} kartlar';
	@override String get rowSizeCompact => 'Ixcham';
	@override String get rowSizeStandard => 'Standardi';
	@override String get rowSizeLarge => 'Katta';
	@override String get continueWatchingAction => '"Tomoshani davom ettirish" harakati';
	@override String get continueWatchingPlay => 'Ijro etish';
	@override String get continueWatchingDetails => 'Tafsilotlarni ochish';
	@override String get episodeAction => 'Qism harakati';
	@override String get episodePlay => 'Ijro etish';
	@override String get episodeDetails => 'Tafsilotlarni ochish';
	@override String get useGlobalHubs => 'Bosh sahifa tuzilishidan foydalanish';
	@override String get useGlobalHubsDescription => 'Birlashtirilgan bosh sahifa boʻlimlarini koʻrsatish.';
	@override String get showServerNameOnHubs => 'Boʻlimlarda server nomini koʻrsatish';
	@override String get showServerNameOnHubsDescription => 'Boʻlim sarlavhalarida har doim server nomini koʻrsatish.';
	@override String get groupLibrariesByServer => 'Kutubxonalarni server boʻyicha guruhlash';
	@override String get groupLibrariesByServerDescription => 'Yon menyudagi kutubxonalarni serverlar boʻyicha guruhlash.';
	@override String get alwaysKeepSidebarOpen => 'Yon menyuni har doim ochiq saqlash';
	@override String get alwaysKeepSidebarOpenDescription => 'Yon menyu ochiq holatda qoladi, kontent maydoni unga moslashadi';
	@override String get showUnwatchedCount => 'Koʻrilmaganlar sonini koʻrsatish';
	@override String get showUnwatchedCountDescription => 'Seriallar va mavsumlarda koʻrilmagan qismlar sonini koʻrsatish';
	@override String get showWatchedIndicators => 'Koʻrilgan belgilarni koʻrsatish';
	@override String get showWatchedIndicatorsDescription => 'Koʻrilgan filmlar, seriallar va qismlarda tasdiq belgisi koʻrsatish';
	@override String get showEpisodeNumberOnCards => 'Kartochkalarda qism raqamini koʻrsatish';
	@override String get showEpisodeNumberOnCardsDescription => 'Qism kartochkalarida mavsum va qism raqamini koʻrsatish';
	@override String get showSeasonPostersOnTabs => 'Varaqlarda mavsum posterlarini koʻrsatish';
	@override String get showSeasonPostersOnTabsDescription => 'Har bir mavsum posterini oʻz boʻlimida koʻrsatish';
	@override String get tvFullCardLayout => 'Toʻliq TV kartochkalari';
	@override String get tvFullCardLayoutDescription => 'Aktyor ismlari ustiga yozilgan, faqat rasmdan iborat TV kartochkalaridan foydalanish';
	@override String get focusGlow => 'Fokus nuri';
	@override String get focusGlowDescription => 'Tanlangan kartochka atrofida yumshoq nur koʻrsatish';
	@override String get visualEffects => 'Vizual effektlar';
	@override String get visualEffectsAuto => 'Avtomatik';
	@override String get visualEffectsAutoDescription => 'Kuchsiz qurilmalarda effektlarni avtomatik kamaytirish';
	@override String get visualEffectsFull => 'Toʻliq';
	@override String get visualEffectsReduced => 'Kamaytirilgan';
	@override String get visualEffectsReducedDescription => 'Kamroq animatsiya va pastroq sifatli rasmlar';
	@override String get hideSpoilers => 'Koʻrilmagan qismlar uchun spoylerlarni yashirish';
	@override String get hideSpoilersDescription => 'Koʻrilmagan qismlar rasmlari va tavsiflarini xiralashtirish';
	@override String get playerBackend => 'Pleyer infratuzilmasi';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Apparatli dekodlash';
	@override String get hardwareDecodingDescription => 'Imkon qadar apparatli tezlashtirishdan foydalanish';
	@override String get playbackBuffer => 'Ijro buferi';
	@override String get playbackBufferAuto => 'Avto (tavsiya etiladi)';
	@override String get playbackBufferLarge => 'Katta';
	@override String get playbackBufferExtraLarge => 'Juda katta';
	@override String get playbackBufferDescription => 'Beqaror ulanishlarga qarshi koʻproq buferlaydi. Bufer hajmi bilan ham cheklanadi.';
	@override String get streamBufferSize => 'Buffer siz';
	@override String streamBufferSizeValue({required Object size}) => '${size} MB';
	@override String get streamBufferSizeDescription => 'Transcodes qotʻi qotʻo qotʻu qotʻon qotʻun qotʻur. 0 = Auto';
	@override String get streamBufferSizeExoNote => 'Playback Buffer\'i ayatlarsa, app\'nin memori limiti yarda qapibib.';
	@override String get streamBufferMegabytes => 'Megabitni';
	@override String get defaultQualityTitle => 'Standart sifat';
	@override String get cellularQualityTitle => 'Mobil tarmoqda standart sifat';
	@override String get remoteQualityTitle => 'Remote Streaming Qalitadi';
	@override String get remoteQualitySameAsDefault => 'Uqqqqga kvalitadi';
	@override String get cellularQualitySameAsDefault => 'Standart sifat bilan bir xil';
	@override String get directPlayCoveredQuality => 'Kichik videolarni asl sifatda ijro etish';
	@override String get directPlayCoveredQualityDescription => 'Sifat chegarasiga kiruvchi videolarni qayta kodlash oʻrniga toʻgʻridan-toʻgʻri ijro etish';
	@override String get videoCodecs => 'Video kodeklar';
	@override String get videoCodecsDescription => 'Belgilanmagan kodeklarni server qayta kodlaydi';
	@override String get videoCodecsAlwaysAccepted => 'Har doim qabul qilinadi';
	@override String get musicQualityTitle => 'Musiqa sifati';
	@override String get subtitleStyling => 'Subtitr sozlamalari';
	@override String get subtitleStylingDescription => 'Subtitrlar koʻrinishini moslashtiring';
	@override String get smallSkipDuration => 'Kichik oʻtkazish vaqti';
	@override String get largeSkipDuration => 'Katta oʻtkazish vaqti';
	@override String get rewindOnResume => 'Davom ettirganda orqaga qaytarish';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(seconds,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} soniya',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} soniya',
	);
	@override String get defaultSleepTimer => 'Standart uyqu taymeri';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(minutes,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} daqiqa',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} daqiqa',
	);
	@override String get rememberTrackSelections => 'Har bir film/serial uchun ovoz/subtitr tanlovini eslab qolish';
	@override String get chooseTracksBeforePlayback => 'Playback-dan əvvəl audio-dan subtitles seçin.';
	@override String get chooseTracksBeforePlaybackDescription => 'Har bir video boshlanishidan oldin manbadagi audio va subtitr yo‘laklarini tanlang.';
	@override String get alwaysShowSubtitlesOnDevice => 'Bu cihazda subtitles ko‘zlar.';
	@override String get alwaysShowSubtitlesOnDeviceDescription => 'Serverni bir subtiti yoksa, lokalizasyonda bir track seçin. Bu, serverni preferansini ko‘zadi.';
	@override String get autoDownloadPreferredSubtitle => 'Yiyiyiyiyiz, preferlik-language subtitles qurtlar';
	@override String get autoDownloadPreferredSubtitleDescription => 'Siz lokalni preferlik dilinizde bir subtitsiz seçin. Siz bir yoksa, serveri bir qotqlar ko‘t support. Seçim bu cihazda qotq.';
	@override String get rememberTrackSelectionsDescription => 'Har bir media uchun ovoz va subtitr sozlamalarini saqlash';
	@override String get rememberTrackSelectionsBackendRule => 'Plex har bir tanlovni serverda fayl boʻyicha saqlaydi; Jellyfin hisobning "Tanlovlarni eslab qolish" funksiyasini ham yoqadi; Emby qoʻllab-quvvatlanmaydi';
	@override String get followServerTrackSelections => 'Har bir epizod uchun serverdagi tanlovlardan foydalanish';
	@override String get followServerTrackSelectionsDescription => 'Epizod almashganda joriy tanlovni ko\'chirish o\'rniga serverda tanlangan ovoz va subtitrni qo\'llash';
	@override String get resumeMusicOnLaunch => 'Musiqa seansini eslab qolish';
	@override String get resumeMusicOnLaunchDescription => 'Ilova ochilganda oxirgi qo\'shiqni to\'xtagan joyida pauzada ochish';
	@override String get showChapterMarkersOnTimeline => 'Vaqt shkalasida boʻlim belgilarini koʻrsatish';
	@override String get showChapterMarkersOnTimelineDescription => 'Vaqt shkalasini boʻlimlarga boʻlish';
	@override String get specialsOrdering => 'Maxsus qismlar epizodlar tartibida';
	@override String get specialsOrderingDescription => 'Maxsus qismlar serialning tomosha qilish tartibida qayerda ijro etiladi';
	@override String get specialsOrderingServer => 'Server tartibiga amal qilish';
	@override String get specialsOrderingAirDate => 'Efirdagi sana boʻyicha aralashtirish';
	@override String get specialsOrderingLast => 'Oddiy fasllardan keyin';
	@override String get clickVideoTogglesPlayback => 'Ijro/pauza uchun videoga bosing';
	@override String get clickVideoTogglesPlaybackDescription => 'Boshqaruv tugmalarini koʻrsatish oʻrniga videoni ijro etish yoki pauza qilish';
	@override String get videoPlayerControls => 'Video pleyer boshqaruv elementlari';
	@override String get keyboardShortcuts => 'Klaviatura tugmalari';
	@override String get keyboardShortcutsDescription => 'Klaviatura tugmalarini moslashtiring';
	@override String get videoPlayerNavigation => 'Video pleyer navigatsiyasi';
	@override String get videoPlayerNavigationDescription => 'Pleyerni boshqarish uchun yoʻnalish tugmalaridan foydalaning';
	@override String get watchTogetherRelay => 'Birgalikda tomosha relesi';
	@override String get watchTogetherRelayDescription => 'Oʻz relengizni belgilamasangiz, ommaviy Open Watch Party relelari ishlatiladi';
	@override String get watchTogetherRelayHint => 'https://my-relay.example.com';
	@override String get watchTogetherRelayInvalid => 'Toʻgʻri HTTP yoki HTTPS rele manzilini kiriting.';
	@override String get crashReporting => 'Xatoliklar haqida hisobot';
	@override String get crashReportingDescription => 'Ilovani takomillashtirishga yordam berish uchun xatoliklar hisobotini yuboring';
	@override String get debugLogging => 'Nosozliklarni aniqlash jurnali';
	@override String get debugLoggingDescription => 'Muammolarni hal qilish uchun batafsil jurnal yuritishni yoqing';
	@override String get viewLogs => 'Jurnallarni koʻrish';
	@override String get viewLogsDescription => 'Ilova jurnallarini koʻrish';
	@override String get clearImageCache => 'Rasm keshini tozalash';
	@override String get clearImageCacheDescription => 'Keshlangan rasm va eskizlarni tozalaydi. Qayta yuklab olinmaguncha rasmlar sekinroq ochilishi mumkin.';
	@override String get clearImageCacheSuccess => 'Rasm keshi muvaffaqiyatli tozalandi';
	@override String get resetSettings => 'Sozlamalarni qayta oʻrnatish';
	@override String get resetSettingsDescription => 'Standart sozlamalarni tiklash. Bu amalni ortga qaytarib boʻlmaydi.';
	@override String get resetSettingsSuccess => 'Sozlamalar muvaffaqiyatli qayta oʻrnatildi';
	@override String get backup => 'Zahira nusxa';
	@override String get exportSettings => 'Sozlamalarni eksport qilish';
	@override String get exportSettingsDescription => 'Parametrlaringizni faylga saqlang';
	@override String get exportSettingsSuccess => 'Sozlamalar eksport qilindi';
	@override String get importSettings => 'Sozlamalarni import qilish';
	@override String get importSettingsDescription => 'Parametrlarni fayldan tiklang';
	@override String get importSettingsConfirm => 'Bu joriy sozlamalaringiz ustidan yoziladi. Davom etasizmi?';
	@override String get importSettingsSuccess => 'Sozlamalar import qilindi';
	@override String get importSettingsInvalidFile => 'Ushbu fayl toʻgʻri PlezyNG sozlamalar fayli emas';
	@override String get importSettingsNoUser => 'Sozlamalarni import qilishdan oldin tizimga kiring';
	@override String get cloudBackup => 'Bulutli zaxira nusxasi';
	@override String get cloudBackupDescription => 'Ko‘chiriladigan sozlamalarni HTTPS orqali WebDAV manziliga zaxiralang. Server ulanishlari va kirish ma’lumotlari ushbu qurilmada qoladi.';
	@override String get cloudBackupUrl => 'WebDAV JSON fildi URL';
	@override String get cloudBackupUsername => 'Foydalanuvchi nomi';
	@override String get cloudBackupPassword => 'Parol';
	@override String get cloudBackupSaved => 'Bulutli zaxira nusxasi saqlanadigan manzil saqlandi';
	@override String get cloudBackupNow => 'Tadi qaytadi';
	@override String get cloudBackupComplete => 'Yatlarlarlarlar yatlarlar';
	@override String get cloudBackupRestore => 'Backup qaytarga';
	@override String get cloudBackupRestoreConfirm => 'Bu ayarlar bu cihazda uyumlanga mobil ayarlar qaytadi.';
	@override String get cloudBackupRestored => 'Uqqqqlarlar bilan qaytarga qotlar.';
	@override String get shortcutsReset => 'Tugmalar birlashmasi standart holatga qaytarildi';
	@override String get resetShortcutsConfirm => 'Bu oʻzingiz sozlagan tugmalar birlashmalarini standart holatga qaytaradi. Davom etasizmi?';
	@override String get about => 'Dastur haqida';
	@override String get aboutDescription => 'Ilova haqida maʼlumot va litsenziyalar';
	@override String get updates => 'Yangilanishlar';
	@override String get updateAvailable => 'Yangilanish mavjud';
	@override String get checkForUpdates => 'Yangilanishlarni tekshirish';
	@override String get autoCheckUpdatesOnStartup => 'Ishga tushganda avtomatik tekshirish';
	@override String get autoCheckUpdatesOnStartupDescription => 'Ishga tushganda yangilanish boʻlsa xabar berish';
	@override String get validationErrorEnterNumber => 'Toʻgʻri raqam kiriting';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Vaqt ${min} va ${max} ${unit} orasida boʻlishi kerak';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Bu birlashma ${action} harakatiga biriktirilgan';
	@override String shortcutUpdated({required Object action}) => '${action} uchun tugmalar birlashmasi yangilandi';
	@override String get saveFailed => 'Oʻzgarishlar saqlanmadi. Qaytadan urinib koʻring.';
	@override String get autoPlayAndSkip => 'Avtomatik ijro va oʻtkazish';
	@override String get autoPlayNextEpisode => 'Keyingi qismni avtomatik ijro etish';
	@override String get autoPlayNextEpisodeDescription => 'Qism tugagach, keyingisini avtomatik ijro etish';
	@override String get shuffleStartsFromBeginning => 'Aralashtirish boshidan boshlanadi';
	@override String get shuffleStartsFromBeginningDescription => 'Aralashtirganda har bir qismni davom ettirish oʻrniga boshidan boshlash';
	@override String get plexCinemaPreRoll => 'Serverdagi film kirish videolaridan foydalanish';
	@override String get plexCinemaPreRollDescription => 'Plex pre-rolls ya Jellyfin və Emby intros ko‘figurada oynaygan film başlatmaydan.';
	@override String get playNextCountdown => 'Keyingi qism sanogʻi';
	@override String get playNextCountdownImmediate => 'Darhol ijro etish';
	@override String get skipIntroMode => 'Kirishni oʻtkazish';
	@override String get skipIntroModeOffDescription => 'Kirishlarni oʻtkazish tugmasiz oddiy ijro etish';
	@override String get skipIntroModeButtonDescription => 'Kirish boshlanganda oʻtkazish tugmasini koʻrsatish';
	@override String get skipIntroModeAutoDescription => 'Kirishlarni quyidagi kechikishdan keyin avtomatik oʻtkazish';
	@override String get skipCreditsMode => 'Titrlarni oʻtkazish';
	@override String get skipCreditsModeOffDescription => 'Titrlarni oʻtkazish tugmasiz oddiy ijro etish';
	@override String get skipCreditsModeButtonDescription => 'Titrlar boshlanganda oʻtkazish tugmasini koʻrsatish';
	@override String get skipCreditsModeAutoDescription => 'Titrlarni avtomatik oʻtkazib, keyingi qismni ijro etish';
	@override String get skipAdsMode => 'Ads koʻyadi';
	@override String get skipAdsModeOffDescription => 'Xamqadi reklamlar normalga kaygaqdan kaygaqlar.';
	@override String get skipAdsModeButtonDescription => 'Plex reklamani aniqlaganda o‘tkazib yuborish tugmasini ko‘rsatish';
	@override String get skipAdsModeAutoDescription => 'Aniqlangan reklamalarni quyida belgilangan kutish vaqtidan so‘ng avtomatik o‘tkazib yuborish';
	@override String get musicPlayback => 'Musiqa ijrosi';
	@override String get musicSweetFades => 'Yiyiyiyiy';
	@override String get musicSweetFadesDescription => 'Plex’da ovoz balandligi ma’lumotlari bo‘lsa, trek boshida va oxirida musiqani asta kuchaytirish va pasaytirish. Albom ijrosi o‘zgarmaydi.';
	@override String get skipMarkerModeOff => 'Oʻchirilgan';
	@override String get skipMarkerModeButton => 'Tugmani koʻrsatish';
	@override String get skipMarkerModeAuto => 'Avtomatik';
	@override String get forceSkipMarkerFallback => 'Zahira belgilarini majburlash';
	@override String get forceSkipMarkerFallbackDescription => 'Plex belgilari boʻlsa ham boʻlim sarlavhasi shablonlaridan foydalanish';
	@override String get theIntroDbFallback => 'Thin-Dub-i‘z‘‘i‘z’i‘z\'i‘z-i‘zi‘z‘i‘zi’z‘i’z‘z‘z’in';
	@override String get theIntroDbFallbackDescription => 'U\'zizga xiyimizga xifimizga, xifimizi xifimize, xifimi xifimisi, xifimin xifimiyizga, Xifimiyimiyimisi xifimiyo, xifimen xifimyo, xifin xifimio, xifinin xifimili, xifmin xifimilo, xifmen xifimile, xifrin xifim, xifren xifimila, xifrimili, xivimili,';
	@override String get autoSkipDelay => 'Avtomatik oʻtkazish kechikishi';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Avtomatik oʻtkazishdan oldin ${seconds} soniya kutilsin';
	@override String get introPattern => 'Kirish qismi belgisi shabloni';
	@override String get introPatternDescription => 'Boʻlim sarlavhalarida introni topish uchun Regex shabloni';
	@override String get creditsPattern => 'Titr belgisi shabloni';
	@override String get creditsPatternDescription => 'Boʻlim sarlavhalarida titrlarni topish uchun Regex shabloni';
	@override String get prerolls => 'Prelimin';
	@override String get playPrerollsBeforeMovies => 'Filmdan əvvəl filmlar oynaylar.';
	@override String get playPrerollsBeforeMoviesDescription => 'Siz filmdan əvvəl sizdan bir random klip oynay.';
	@override String get prerollLibrary => 'Preroll librariy';
	@override String get prerollLibraryNotSet => 'Oʻrnatilmagan';
	@override String get prerollLibraryNoneFound => 'Siz serverlarda librarlar bulhathathathatlar.';
	@override String get prerollSelection => 'Tadiqlar seçib';
	@override String get prerollSelectionPickLibraryFirst => 'Bir librariyiz ilk birini';
	@override String get prerollSelectionNoneSelected => 'U\'zari seçilmaydi';
	@override String prerollSelectionCount({required Object count}) => '${count} ta tanlangan';
	@override String get prerollItemPicker => 'Tadiqlar seçib';
	@override String get prerollItemPickerLoadFailed => 'Bu librariyadan bir şey ko‘zadi.';
	@override String get invalidRegex => 'Notoʻgʻri muntazam ifoda (Regex)';
	@override String get regex => 'Muntazam ifoda (Regex)';
	@override String get downloads => 'Yuklamalar';
	@override String get downloadLocationDescription => 'Yuklangan fayllar saqlanadigan joyni tanlang';
	@override String get downloadLocationDefault => 'Standart (Ilova xotirasi)';
	@override String get downloadLocationCustom => 'Boshqa joy';
	@override String get selectFolder => 'Jildni tanlash';
	@override String get resetToDefault => 'Standart holatga qaytarish';
	@override String currentPath({required Object path}) => 'Joriy: ${path}';
	@override String get downloadLocationChanged => 'Yuklash joyi oʻzgartirildi';
	@override String get downloadLocationReset => 'Yuklash joyi standart holatga qaytarildi';
	@override String get downloadLocationInvalid => 'Tanlangan jildga yozib boʻlmadi';
	@override String get downloadLocationPickerUnavailable => 'Ushbu qurilmada jildni tanlash imkoniyati yoʻq';
	@override String get downloadOnWifiOnly => 'Faqat Wi-Fi orqali yuklash';
	@override String get downloadOnWifiOnlyDescription => 'Mobil tarmoqdan foydalanilganda yuklashni toʻxtatib turish';
	@override String get autoRemoveWatchedDownloads => 'Koʻrilgan yuklamalarni avtomatik oʻchirish';
	@override String get autoRemoveWatchedDownloadsDescription => 'Koʻrib boʻlingan yuklamalarni avtomatik oʻchirish';
	@override String get autoDownloadContinueWatching => '“Tomoshani davom ettirish” ro‘yxatini avtomatik yuklab olish';
	@override String get autoDownloadContinueWatchingDescription => 'U\'zizni isqizni isxizni iscizni isgizni isnizni isfizni isjizni ischizni ishqizni.';
	@override String get downloadQuality => 'Download Qalitsiya';
	@override String get downloadQualityDescription => 'Plex isqizda bir transferlik kopyadi hazırlar. Jellyfin və Emby transkodlar ko‘dadi fil download; isqizdan transferliklar yeniden başlatmaq gerektirir.';
	@override String get askDownloadQualityEachTime => 'Qiyizizizizimizimizimizimizizimizimizizizimizizimizizizizimizimizizimizizimiz';
	@override String get askDownloadQualityEachTimeDescription => 'Sizga video download o‘zizdan əvvəl picker o‘zizi.';
	@override String get cellularDownloadBlocked => 'Mobil tarmoqda yuklash taqiqlangan. Wi-Fi-dan foydalaning yoki sozlamani oʻzgartiring.';
	@override String get maxVolume => 'Maksimal ovoz';
	@override String get maxVolumeDescription => 'Pastroq ovozli videolar uchun ovozni 100%-dan oshirishga ruxsat berish';
	@override String maxVolumePercent({required Object percent}) => '%${percent}';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Discord-da nima tomosha qilayotganingizni koʻrsatish';
	@override String get services => 'Xizmatlar';
	@override String get servicesDescription => 'Trakt, MyAnimeList, Seerr va boshqalarni ulang';
	@override String get manageLibrariesDescription => 'Kutubxonalarni tartiblash va yashirish';
	@override String get companionRemoteServer => 'Yordamchi pult serveri';
	@override String get companionRemoteServerDescription => 'Tarmoqdagi mobil qurilmalarga ushbu ilovani boshqarishga ruxsat berish';
	@override String get companionRemoteServerStartFailed => 'Yordamchi pult serverini ishga tushirib bo‘lmadi';
	@override String get companionRemoteServerStopFailed => 'Yordamchi pult serverini to‘xtatib bo‘lmadi';
	@override String get autoPip => 'Avtomatik Rasm ichida rasm (PiP)';
	@override String get autoPipDescription => 'Video ijro etilayotganda ilovadan chiqilganda avto-PiP rejimiga oʻtish';
	@override String get matchContentFrameRate => 'Kadrlar chastotasini moslashtirish';
	@override String get matchContentFrameRateDescription => 'Ekran chastotasini video kontentiga moslashtirish';
	@override String get matchContentResolution => 'Kontent oʻlchamiga moslashtirish';
	@override String get matchContentResolutionDescription => 'Masshtablashni televizor bajarishi uchun ekranni videoning oʻz oʻlchamiga oʻtkazadi. Ijro vaqtida menyular va subtitrlar ham masshtablanadi';
	@override String get matchRefreshRate => 'Yangilanish chastotasini moslashtirish';
	@override String get matchRefreshRateDescription => 'Toʻliq ekranda ekran chastotasini moslashtirish';
	@override String get matchDynamicRange => 'Dinamik diapazonni moslashtirish';
	@override String get matchDynamicRangeDescription => 'HDR kontent uchun HDR-ni yoqish, soʻng SDR-ga qaytish';
	@override String get displaySwitchDelay => 'Ekranni almashtirish kechikishi';
	@override String get tunneledPlayback => 'Tunnelli ijro';
	@override String get tunneledPlaybackDescription => 'Video tunnellashdan foydalanish. HDR ijrosida ekran qora boʻlsa yoki harakat uzilib qolsa, oʻchiring.';
	@override String get audioPassthrough => 'Ovozni toʻgʻridan-toʻgʻri oʻtkazish (Passthrough)';
	@override String get audioPassthroughDescription => 'Dolby/DTS ovozini qayta kodlamasdan resiver yoki televizoringizga yuboradi va atroflicha ovozni saqlaydi. Ovoz boʻlmasa, oʻchiring.';
	@override String get audioPassthroughDescriptionApple => 'Dolby Digital Plus, jumladan Atmos uchun Apple’ning oʻz Dolby dekoderidan foydalanish. DTS va TrueHD avvalgidek koʻp kanalli PCM sifatida ijro etiladi. Ovoz boʻlmasa, oʻchiring.';
	@override String get audioPassthroughDescriptionAppleSpatial => 'Dolby Digital Plus, jumladan Atmos uchun Apple’ning oʻz Dolby dekoderidan foydalanish. iOS, iPadOS va tvOS 26 yoki undan yangi versiyalarda TrueHD Atmos va DTS:X fazoviy audio sifatida ijro etiladi. Boshqa DTS va TrueHD treklari koʻp kanalli PCM sifatida ijro etiladi. Ovoz boʻlmasa, oʻchiring.';
	@override String get audioPassthroughOverriddenByNormalization => 'Ovoz balandligini meʼyorlashtirish yoqilganda oʻchirilgan';
	@override String get audioChannelLimit => 'Audio kanallari';
	@override String get audioChannelLimitDescription => 'Barcha kanallarni ijro eta olmaydigan karnaylar, quloqchinlar yoki HDMI tizimlari uchun dekodlangan ovoz kanallarini kamaytirish';
	@override String get audioChannelLimitOriginal => 'Asl';
	@override String get audioChannelLimitOriginalDescription => 'Trekdagi barcha kanallarni ijro etish';
	@override String get audioChannelLimitSurround51 => '5.1 gacha';
	@override String get audioChannelLimitSurround51Description => 'Faqat 5.1 PCM qabul qiladigan televizor va resiverlar uchun 7.1 ni 5.1 ga tushirish. Toʻgʻridan-toʻgʻri oʻtkazishga taʼsir qilmaydi.';
	@override String get audioChannelLimitStereo => 'Stereo';
	@override String get audioChannelLimitStereoDescription => 'Stereo karnaylar yoki quloqchinlar uchun ikki kanalga tushirish. Toʻgʻridan-toʻgʻri oʻtkazishni oʻchiradi.';
	@override String get downmixCenterBoost => 'Markaziy kanalni kuchaytirish';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Kuchaytirish (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Oʻtkazishda ovozni meʼyorlashtirish';
	@override String get audioDownmixNormalizeDescription => 'Ovoz buzilishining oldini olish uchun darajani tushirish. Asl ovoz balandligini saqlash uchun oʻchiring (baland sahnalar buzilishi mumkin).';
	@override String get dvConversionMode => 'Dolby Vision oʻtkazmasi';
	@override String get dvConversionModeDescription => 'Dolby Vision Profile 7 fayllarini qayta ishlash rejimini tanlang.';
	@override String get dvConversionAuto => 'Avtomatik';
	@override String get dvConversionNative => 'Ichki / Oʻchirilgan';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Qurilma imkoniyatlaridan foydalanish';
	@override String get dvConversionNativeDescription => 'Ichki DV7 rejimini majburlash';
	@override String get dvConversionDv81Description => 'Dolby Vision profile 8.1 formatiga oʻtkazish';
	@override String get dvConversionHevcStripDescription => 'Dolby Vision qatlamlarini olib tashlash va HEVC sifatida koʻrsatish';
	@override String get disableDolbyVision => 'Dolby Vision\'ni oʻchirish';
	@override String get disableDolbyVisionDescription => 'Faylda boʻlsa, Dolby Vision oʻrniga HDR10 yoki HLG qatlamini ijro etish';
	@override String get hdrSdrConversion => 'HDR\'ni SDR\'ga aylantirish';
	@override String get hdrSdrConversionDescription => 'Displey HDR\'ni ko‘rsata olmaganda HDR videoni nima aylantirishini tanlang.';
	@override String get hdrSdrConversionAuto => 'Avtomatik';
	@override String get hdrSdrConversionAutoDescription => 'Android 9 va undan keyingi versiyalarda qurilma, eskiroq versiyalarda pleyer';
	@override String get hdrSdrConversionDevice => 'Qurilma';
	@override String get hdrSdrConversionDeviceDescription => 'Aylantirishni qurilmaning video apparati bajaradi. Eng tezi, lekin ranglar qurilmaga bog‘liq';
	@override String get hdrSdrConversionPlayer => 'Pleyer';
	@override String get hdrSdrConversionPlayerDescription => 'Aylantirishni pleyer bajaradi. Ranglar bir xil, lekin kuchsiz TV-pristavkalarda 4K qotishi mumkin';
	@override String get deinterlace => 'Interleysni olib tashlash';
	@override String get deinterlaceDescription => 'Interleys videodagi taroqsimon artefaktlarni olib tashlash (faqat mpv pleyerida)';
	@override String get deinterlaceOff => 'Oʻchirilgan';
	@override String get deinterlaceOffDescription => 'Interleys videoni dekodlangan holicha koʻrsatish';
	@override String get deinterlaceVideo => 'Video';
	@override String get deinterlaceVideoDescription => 'Har bir maydonni toʻliq kadrga aylantirish. Sport, yangiliklar va konsertlar kabi televideniye uchun suratga olingan videolar uchun';
	@override String get deinterlaceFilm => 'Film';
	@override String get deinterlaceFilmDescription => 'NTSC DVD-larda keng tarqalgan, 29.97 fps ga telesine qilingan film va animatsiyaning asl kadrlarini tiklash. Televideniye uchun suratga olingan video uzilib-uzilib koʻrinadi. Jonli TV Video rejimidan foydalanadi';
	@override String get requireProfileSelectionOnOpen => 'Ochilganda profilni soʻrash';
	@override String get requireProfileSelectionOnOpenDescription => 'Ilova ochilgan har safar profilni tanlashni koʻrsatish';
	@override String get forceTvMode => 'TV rejimini majburlash';
	@override String get forceTvModeDescription => 'TV interfeysini majburiy yoqish. Avtomatik aniqlanmaydigan qurilmalar uchun. Qayta ishga tushirish talab qilinadi.';
	@override String get startInFullscreen => 'Toʻliq ekranda boshlash';
	@override String get startInFullscreenDescription => 'PlezyNG-ni ochganda toʻliq ekran rejimida ochish';
	@override String get exitFullscreenOnPlayerClose => 'Pleyer yopilganda toʻliq ekrandan chiqish';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Video pleyerni yopganda avtomatik ravishda toʻliq ekrandan chiqish';
	@override String get autoHidePerformanceOverlay => 'Unumdorlik panelini avto-yashirish';
	@override String get autoHidePerformanceOverlayDescription => 'Unumdorlik panelini boshqaruv tugmalari bilan birga yashirish';
	@override String get showNavBarLabels => 'Navigatsiya paneli matnlarini koʻrsatish';
	@override String get showNavBarLabelsDescription => 'Navigatsiya belgilarining ostida matnni koʻrsatish';
	@override String get startupSection => 'Boshlangʻich boʻlim';
	@override String get preferredServer => 'Server qiziziziz';
	@override String get preferredServerDescription => 'Bu server\'nin sonuçlar bilan prioriziziziz, bütün bağlantılı serverlar qothatlar.';
	@override String get preferredServerAutomatic => 'Avtomatik';
	@override String get showExploreTab => 'Kashf qilish varagʻini koʻrsatish';
	@override String get showExploreTabDescription => 'Plex Discover va ulangan kuzatuvchilardagi kontent bilan Kashf qilish varagʻini koʻrsatish';
	@override String get hideEmptyLibraries => 'Librarlar bo‘qlar';
	@override String get hideEmptyLibrariesDescription => 'Bu server-di-reporting element sayni nullga navigation.';
	@override String get liveTvDefaultFavorites => 'Jonli TV-da tanlangan kanallarni standart qilish';
	@override String get liveTvDefaultFavoritesDescription => 'Jonli TV ochilganda faqat tanlangan kanallarni koʻrsatish';
	@override String get general => 'Umumiy';
	@override String get generalDescription => 'Til, ishga tushirish va oyna xatti-harakati';
	@override String get languageAndRegion => 'Til va mintaqa';
	@override String get startup => 'Ishga tushirish';
	@override String get display => 'Displey';
	@override String get libraryAndCards => 'Kutubxona va kartochkalar';
	@override String get homeScreen => 'Bosh ekran';
	@override String get navigation => 'Navigatsiya';
	@override String get window => 'Oyna';
	@override String get liveTv => 'Jonli TV';
	@override String get player => 'Pleyer';
	@override String get videoAndDisplay => 'Video va displey';
	@override String get audio => 'Audio';
	@override String get quality => 'Sifat';
	@override String get subtitles => 'Subtitrlar';
	@override String get seekAndTiming => 'Oʻtkazish va vaqt sozlamalari';
	@override String get behavior => 'Xatti-harakat';
	@override String get gestures => 'Imo-ishoralar';
	@override String get gestureBrightnessSwipe => 'Yorqinlik surish';
	@override String get gestureBrightnessSwipeDescription => 'Yorqinlikni sozlash uchun chap chekkada yuqoriga yoki pastga suring';
	@override String get gestureVolumeSwipe => 'Ovoz surish';
	@override String get gestureVolumeSwipeDescription => 'Ovozni sozlash uchun oʻng chekkada yuqoriga yoki pastga suring';
	@override String get gesturePinchToZoom => 'Chimchilab masshtablash';
	@override String get gesturePinchToZoomDescription => 'Videoni yaqinlashtirish yoki uzoqlashtirish uchun chimchilang';
	@override String get gestureSeekSwipe => 'Swipe qona';
	@override String get gestureSeekSwipeDescription => 'Yat-yat-yata o\'qizga video\'da argaqga; qaytdan-yat';
	@override String get rememberBrightnessLevel => 'Yorqinlik darajasini eslab qolish';
	@override String get rememberBrightnessLevelDescription => 'Ijroni oxirgi surish bilan oʻrnatilgan yorqinlikda boshlash';
	@override String get controls => 'Boshqaruv elementlari';
	@override String get rememberPlayerChanges => 'Pleyer oʻzgarishlarini eslab qolish';
	@override String get rememberPlayerChangesDescription => 'Ijro vaqtida qilingan oʻzgarish qayerda saqlanishi va qayta qoʻllanishi';
	@override String get scopePlaybackSpeed => 'Ijro tezligi';
	@override String get scopeShaderPreset => 'Sheyder oldindan sozlamasi';
	@override String get scopeAspectRatio => 'Tomonlar nisbati';
	@override String get scopeSyncOffsets => 'Audio va subtitr sinxronizatsiyasi';
	@override String get playerScopeOff => 'Saqlamaslik';
	@override String get playerScopeGlobal => 'Hamma joyda';
	@override String get playerScopeLibrary => 'Kutubxona boʻyicha';
	@override String get playerScopeTitle => 'Serial yoki film boʻyicha';
	@override String get exportDialogTitle => 'PlezyNG sozlamalarini eksport qilish';
	@override String get followSystem => 'Tizim tiliga mos';
	@override String get followAppLanguage => 'Interfeys tili bilan bir xil';
	@override String get regionFormat => 'Mintaqaviy formatlar';
	@override String get regionFormatDescription => 'Sana, sonlar va oʻlchov birliklari qanday koʻrsatilishini tanlang.';
	@override String get metadataLanguage => 'Metamaʼlumotlar tili';
	@override String get metadataLanguageDescription => 'Server qoʻllab-quvvatlasa, sarlavha va tavsiflar uchun afzal til. Audio va subtitr tili alohida sozlanadi.';
	@override String get experimentalDolbyVision => 'Tajribaviy Dolby Vision';
	@override String get experimentalDolbyVisionDescription => 'Keyingi ijroda tajribaviy FEL renderidan foydalaning. Dvigatelning alohida yig‘ilmasi talab qilinadi.';
	@override String get dvExperimentUnavailableDescription => 'Bu tajriba hozircha faqat Linux tizimida mavjud.';
	@override String get dvCompatibilityFallback => 'Moslik uchun zaxira rejim';
	@override String get dvCompatibilityFallbackDescription => 'Tajriba boshlanmasa, standart renderdan foydalaning. FEL ma’lumotlari yo‘qolishi mumkin.';
	@override String get dvExperimentDiagnostics => 'Video tajribasi jurnali';
	@override String get dvExperimentDiagnosticsDescription => 'Keyingi ijroda pleyerning batafsil jurnallarini yoqing.';
}

// Path: themeEditor
class _Translations$themeEditor$uz extends Translations$themeEditor$en {
	_Translations$themeEditor$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get builtIn => 'Oʻrnatilgan';
	@override String get presets => 'Tayyor mavzular';
	@override String get custom => 'Shaxsiy';
	@override String get customEmpty => 'Hali yaratilmagan';
	@override String get editCustom => 'Shaxsiy mavzuni tahrirlash';
	@override String get editCustomDescription => 'Har bir rangni oʻzingiz tanlang';
	@override String get locked => 'Hayatdan qaplan qaplan';
	@override String get savedLocked => 'Sa\'qiz - lively access qiziziz';
	@override String get title => 'Shaxsiy mavzu';
	@override String get startFrom => 'Asos qilib olish';
	@override String get startFromDescription => 'Boshqa mavzudan barcha ranglarni nusxalash';
	@override String get colors => 'Ranglar';
	@override String get preview => 'Oldindan koʻrish';
	@override late final _Translations$themeEditor$slots$uz slots = _Translations$themeEditor$slots$uz._(_root);
	@override String get opacity => 'Noshaffoflik';
	@override String get hexHint => '#RRGGBB yoki #AARRGGBB';
	@override String get fromOtherThemes => 'Boshqa mavzulardan';
	@override String swatchLabel({required Object theme, required Object color}) => '${theme} — ${color}';
	@override late final _Translations$themeEditor$contrast$uz contrast = _Translations$themeEditor$contrast$uz._(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, tavsiya etilgan ${minimum}:1 dan past';
	@override String get discardTitle => 'Oʻzgarishlardan voz kechilsinmi?';
	@override String get discardMessage => 'Saqlanmagan rang oʻzgarishlari yoʻqoladi.';
	@override String get discard => 'Voz kechish';
	@override String previewCardTitle({required Object number}) => '${number}-qism';
	@override String previewCardSubtitle({required Object minutes}) => '${minutes} daq qoldi';
	@override String get previewSwitch => 'Avtomatik ijro';
	@override String get previewMutedText => 'Ikkilamchi matn shunday koʻrinadi';
}

// Path: search
class _Translations$search$uz extends Translations$search$en {
	_Translations$search$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Filmlar, seriallar, musiqa qidirish...';
	@override String get tryDifferentTerm => 'Boshqa qidiruv soʻzini kiriting';
	@override String get searchYourMedia => 'Medialaringizdan qidiring';
	@override String get enterTitleActorOrKeyword => 'Nomini, aktyorni yoki kalit soʻzni kiriting';
	@override String get people => 'Odamlar';
}

// Path: hotkeys
class _Translations$hotkeys$uz extends Translations$hotkeys$en {
	_Translations$hotkeys$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => '${actionName} uchun tugmalar birlashmasini oʻrnatish';
	@override String get clearShortcut => 'Birlashmani tozalash';
	@override String get noShortcutSet => 'Tugmalar birlashmasi oʻrnatilmagan';
	@override String get currentShortcut => 'Joriy birlashma:';
	@override String get pressToRecord => 'Birlashmani yozib olish uchun bosing';
	@override String get recordingShortcut => 'Endi tugmalarni bosing';
	@override late final _Translations$hotkeys$actions$uz actions = _Translations$hotkeys$actions$uz._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$uz extends Translations$fileInfo$en {
	_Translations$fileInfo$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Fayl haqida maʼlumot';
	@override String get overview => 'Tavsif';
	@override String get video => 'Video';
	@override String get audio => 'Audio';
	@override String get subtitles => 'Subtitrlar';
	@override String get images => 'Ichiga joylangan rasmlar';
	@override String get dataStreams => 'Maʼlumot oqimlari';
	@override String get lyrics => 'Qoʻshiq matni';
	@override String get file => 'Fayl';
	@override String get attachments => 'Biriktirilgan fayllar';
	@override String get delivery => 'Yetkazib berish';
	@override String versionCounter({required Object index, required Object count}) => '${index}-versiya (${count} tadan)';
	@override String fileCounter({required Object index, required Object count}) => '${index}-fayl (${count} tadan)';
	@override String get noStreams => 'Server ushbu fayl uchun oqimlar mavjud emasligini bildirdi.';
	@override String get copyPath => 'Yoʻlni nusxalash';
	@override String get pathCopied => 'Fayl yoʻli nusxalandi';
	@override String get codec => 'Kodek';
	@override String get codecTag => 'Kodek yorligʻi';
	@override String get resolution => 'Oʻlchamlari (Resolution)';
	@override String get codedResolution => 'Kodlangan oʻlcham';
	@override String get bitrate => 'Bitreyt (Bitrate)';
	@override String get frameRate => 'Kadrlar chastotasi';
	@override String get rotation => 'Burilish';
	@override String get comment => 'Izoh';
	@override String get audioDescription => 'Audio tavsif';
	@override String get headerCompression => 'Sarlavha siqish';
	@override String get sidecarFile => 'Yordamchi fayl';
	@override String get transportTimestamp => 'Transport vaqt belgisi';
	@override String get displayOffset => 'Koʻrsatish siljishi';
	@override String get previewFailureCode => 'Oldindan koʻrish xatosi kodi';
	@override String get previewRetries => 'Oldindan koʻrish urinishlari';
	@override String get aspectRatio => 'Tomonlar nisbati';
	@override String get pixelAspectRatio => 'Piksel tomonlar nisbati';
	@override String get profile => 'Profil';
	@override String get level => 'Daraja';
	@override String get bitDepth => 'Bit chuqurligi';
	@override String get pixelFormat => 'Piksel formati';
	@override String get colorSpace => 'Rang makoni';
	@override String get colorRange => 'Rang diapazoni';
	@override String get colorPrimaries => 'Asosiy ranglar';
	@override String get colorTransfer => 'Rang uzatish';
	@override String get chromaSubsampling => 'Rangli subdiskretlash';
	@override String get chromaLocation => 'Chroma joylashuvi';
	@override String get scanType => 'Skanerlash turi';
	@override String get interlaced => 'Interleys';
	@override String get anamorphic => 'Anamorfik';
	@override String get referenceFrames => 'Tayanch kadrlar';
	@override String get dynamicRange => 'Dinamik diapazon';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Dolby Vision darajasi';
	@override String get dolbyVisionVersion => 'Dolby Vision versiyasi';
	@override String get dolbyVisionLayers => 'Dolby Vision qatlamlari';
	@override String get baseLayerCompatibility => 'Asosiy qatlam mosligi';
	@override String get avcBitstream => 'AVC bit oqimi';
	@override String get nalLengthSize => 'NAL uzunlik oʻlchami';
	@override String get scalingMatrix => 'Maxsus masshtablash matritsasi';
	@override String get streamIdentifier => 'Oqim identifikatori';
	@override String get streamIndex => 'Oqim indeksi';
	@override String get streamId => 'Oqim ID-si';
	@override String get language => 'Til';
	@override String get languageCode => 'Til kodi';
	@override String get streamTitle => 'Trek nomi';
	@override String get channels => 'Kanallar';
	@override String get sampleRate => 'Namuna tezligi';
	@override String get spatialAudio => 'Fazoviy audio';
	@override String get textBased => 'Matnga asoslangan';
	@override String get subtitleFormat => 'Yordamchi format';
	@override String get provider => 'Provayder';
	@override String get matchScore => 'Moslik darajasi';
	@override String get externalDelivery => 'Alohida uzatilishi mumkin';
	@override String get sidecarPath => 'Yordamchi fayl yoʻli';
	@override String get sourceStream => 'Nusxa olingan manba';
	@override String get temporary => 'Vaqtinchalik';
	@override String get timeBase => 'Vaqt bazasi';
	@override String get overallBitrate => 'Umumiy bitreyt';
	@override String get path => 'Yoʻl';
	@override String get fileName => 'Fayl nomi';
	@override String get size => 'Hajmi';
	@override String get totalSize => 'Umumiy hajm';
	@override String get container => 'Konteyner';
	@override String get duration => 'Davomiyligi';
	@override String get previewThumbnails => 'Oldindan koʻrish eskizlari';
	@override String get previewIndex => 'Oldindan koʻrish indeksi';
	@override String get packetLength => 'Paket uzunligi';
	@override String get filePresent => 'Fayl mavjud';
	@override String get fileReadable => 'Server tomonidan oʻqiladigan';
	@override String get streamPath => 'Oqim yoʻli';
	@override String get optimizedForStreaming => 'Oqimli uzatish uchun optimallashtirilgan';
	@override String get has64bitOffsets => '64-bitli siljishlar';
	@override String get protocol => 'Protokol';
	@override String get mediaType => 'Media turi';
	@override String get sourceKind => 'Manba turi';
	@override String get optimizedVersion => 'Optimallashtirilgan versiya';
	@override String get optimizationTarget => 'Optimallashtirish maqsadi';
	@override String get deletedAt => 'Oʻchirilgan';
	@override String get remoteSource => 'Masofaviy manba';
	@override String get infiniteStream => 'Cheksiz oqim';
	@override String get directPlay => 'Toʻgʻridan-toʻgʻri ijro';
	@override String get directStream => 'Toʻgʻridan-toʻgʻri oqim';
	@override String get transcoding => 'Qayta kodlash';
	@override String get etag => 'ETag';
	@override String get versionId => 'Versiya ID-si';
	@override String get fileId => 'Fayl ID-si';
	@override String get defaultAudioTrack => 'Standart audio trek';
	@override String get defaultSubtitleTrack => 'Standart subtitr treki';
	@override String get subtitlesOff => 'Oʻchirilgan';
	@override String get flagDefault => 'Standart';
	@override String get flagForced => 'Majburiy';
	@override String get flagSelected => 'Tanlangan';
	@override String get flagExternal => 'Tashqi';
	@override String get flagHearingImpaired => 'Eshitishida nuqsoni borlar uchun';
	@override String get flagDub => 'Dublyaj';
	@override String get flagOriginal => 'Asl';
	@override String get channelsMono => 'Mono';
	@override String dolbyVisionProfile({required Object profile}) => 'Profil ${profile}';
}

// Path: mediaMenu
class _Translations$mediaMenu$uz extends Translations$mediaMenu$en {
	_Translations$mediaMenu$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Koʻrilgan deb belgilash';
	@override String get markAsUnwatched => 'Koʻrilmagan deb belgilash';
	@override String get removeFromContinueWatching => '"Tomoshani davom ettirish"dan oʻchirish';
	@override String get viewDetails => 'Batafsil koʻrish';
	@override String get goToSeries => 'Serialga oʻtish';
	@override String get shufflePlay => 'Aralashtirib ijro etish';
	@override String get shuffleNotAvailableOffline => 'Aralashtirib ijro etish oflayn rejimda mavjud emas';
	@override String get fileInfo => 'Fayl haqida maʼlumot';
	@override String get deleteEpisodeFromServer => 'Qismni serverdan oʻchirish';
	@override String get deleteSeasonFromServer => 'Mavsumni serverdan oʻchirish';
	@override String get deleteShowFromServer => 'Shouni serverdan oʻchirish';
	@override String get deleteMovieFromServer => 'Filmni serverdan oʻchirish';
	@override String get deleteEpisodeTitle => 'Ushbu qism oʻchirilsinmi?';
	@override String get deleteSeasonTitle => 'Ushbu mavsum oʻchirilsinmi?';
	@override String get deleteShowTitle => 'Ushbu shou oʻchirilsinmi?';
	@override String get deleteMovieTitle => 'Ushbu film oʻchirilsinmi?';
	@override String get deleteEpisodeConfirm => 'Qismni oʻchirish';
	@override String get deleteSeasonConfirm => 'Mavsumni oʻchirish';
	@override String get deleteShowConfirm => 'Shouni oʻchirish';
	@override String get deleteMovieConfirm => 'Filmni oʻchirish';
	@override String get deleteAnyway => 'Baribir oʻchirish';
	@override String confirmDeleteTarget({required Object title}) => '${title} serveringizdan butunlay oʻchirilsinmi?';
	@override String get deleteMultipleWarning => 'Bu barcha qismlar va fayllarga taʼsir qiladi.';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n,
		one: 'Bu undagi ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} qismni va uning faylini o‘chiradi.',
		other: 'Bu undagi barcha ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} qismni va ularning fayllarini oʻchiradi.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n,
		one: 'Bu element ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} fayl shaklida saqlanadi va u oʻchiriladi.',
		other: 'Bu element ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} faylda saqlanadi va ularning barchasi oʻchiriladi.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n,
		one: 'Xuddi shu faylda yana ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} qism saqlanadi va u ham oʻchiriladi:',
		other: 'Xuddi shu faylda yana ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} qism saqlanadi va ular ham oʻchiriladi:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'PlezyNG qaysi fayllar olib tashlanishini tekshira olmadi, shuning uchun u yuqorida koʻrsatilgan elementdan koʻproq narsani oʻchirishi mumkin. Bekor qilib qaytadan urining yoki baribir oʻchiring.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'Serveringiz ushbu element uchun fayl tafsilotlarini taqdim etmadi, shuning uchun PlezyNG qaysi fayllar olib tashlanishini tekshira olmaydi. U yuqorida koʻrsatilgan elementdan koʻproq narsani oʻchirishi mumkin.';
	@override String get mediaDeletedSuccessfully => 'Media elementi muvaffaqiyatli oʻchirildi';
	@override String get mediaFailedToDelete => 'Media elementini oʻchirib boʻlmadi';
	@override String get rate => 'Baho berish';
	@override String get playFromBeginning => 'Boshidan ijro etish';
	@override String get playVersion => 'Versiyani ijro etish...';
}

// Path: rateSheet
class _Translations$rateSheet$uz extends Translations$rateSheet$en {
	_Translations$rateSheet$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Baho berish';
	@override String get server => 'Server';
	@override String get favorite => 'Tanlangan';
	@override String get favorited => 'Tanlanganlarga qoʻshildi';
	@override String get saved => 'Saqlandi';
	@override String get notAvailable => 'Moslik topilmadi';
	@override String get noConnectedServices => 'Baho berish uchun Sozlamalardan xizmatni ulang.';
}

// Path: accessibility
class _Translations$accessibility$uz extends Translations$accessibility$en {
	_Translations$accessibility$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, film';
	@override String mediaCardShow({required Object title}) => '${title}, TV shou';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'koʻrilgan';
	@override String mediaCardPartiallyWatched({required Object percent}) => '%${percent} koʻrilgan';
	@override String get mediaCardUnwatched => 'koʻrilmagan';
	@override String get tapToPlay => 'Ijro etish uchun bosing';
	@override String get decrease => 'Kamaytirish';
	@override String get increase => 'Oshirish';
	@override String decreaseValue({required Object label}) => '${label} qiymatini kamaytirish';
	@override String increaseValue({required Object label}) => '${label} qiymatini oshirish';
	@override String get hue => 'Rang jilosi';
	@override String get saturation => 'Toʻyinganlik';
	@override String get brightness => 'Yorqinlik';
	@override String get hexColor => 'Hex rangi';
	@override String get expandText => 'Matnni yoyish';
	@override String get collapseText => 'Matnni yigʻish';
	@override String get alphabetNavigation => 'Alifboli navigatsiya';
	@override String get alphabetScrollHint => 'Harflar boʻyicha oʻtish uchun yuqoriga yoki pastga suring';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Qator ${row} / ${rowCount}, ustun ${column} / ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'Qator ${row} / ${rowCount}';
	@override String get autoScrollPlay => 'Avtomatik aylantirishni boshlash';
	@override String get autoScrollPause => 'Avtomatik aylantirishni pauza qilish';
	@override String get hueShort => 'H';
	@override String get saturationShort => 'S';
	@override String get valueShort => 'V';
	@override String get red => 'Rojadi';
	@override String get green => 'Yunan';
	@override String get blue => 'Mavi';
	@override String get redShort => 'R';
	@override String get greenShort => 'G';
	@override String get blueShort => 'B';
	@override String get colorModeHsv => 'HSV';
	@override String get colorModeRgb => 'RGB';
	@override String get title => 'Aksesibilit';
	@override String get summary => 'Text, kontrast, motil, kontrollar';
	@override String get systemHint => 'Qurilmangizning maxsus imkoniyatlar sozlamalari doim amal qiladi. Bu parametrlar PlezyNG bo‘ylab qo‘shimcha moslashlarni taqdim etadi.';
	@override String get readability => 'Okumadi və vizibiliyadi';
	@override String get textSize => 'Tekstil bilan bilan bilan';
	@override String get preview => 'Keyingi hikoyangizni toping. O‘zingizga qulay sur’atda o‘qing, tinglang va tomosha qiling.';
	@override String get boldText => 'Interface texti';
	@override String get highContrast => 'Kontrast bilan';
	@override String get highContrastHint => 'Tekstil, outlines, qurtlar, qurtlari, qurtalar, qurtlara qurtlar.';
	@override String get interaction => 'Movsiya və interakcion';
	@override String get reduceMotion => 'Movsiya ko‘zadi';
	@override String get reduceMotionHint => 'Fokus ko‘rsatkichi harakatini, sahifa almashish animatsiyasini va bezak effektlarini to‘xtating.';
	@override String get largeTargets => 'Tadiqni sasni';
	@override String get largeTargetsHint => 'U\'zizga qo‘zlar, touch-i-asistivi navigation üçün daha fazla yer qo‘z.';
	@override String get navigationHint => 'Boshqaruv elementlari orasida yurish uchun Tab va Shift+Tab, ishga tushirish uchun Enter yoki Bo‘sh joy, yopish uchun Escape yoki Orqaga tugmasidan foydalaning. Kitob ochiq bo‘lsa, masshtab va o‘qish sozlamalarini o‘zgartirish mumkin.';
}

// Path: tooltips
class _Translations$tooltips$uz extends Translations$tooltips$en {
	_Translations$tooltips$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Aralashtirib ijro etish';
	@override String get playTrailer => 'Treylerni koʻrish';
	@override String get markAsWatched => 'Koʻrilgan deb belgilash';
	@override String get markAsUnwatched => 'Koʻrilmagan deb belgilash';
}

// Path: audioTracks
class _Translations$audioTracks$uz extends Translations$audioTracks$en {
	_Translations$audioTracks$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'Audio yoʻlak ${n}';
}

// Path: videoControls
class _Translations$videoControls$uz extends Translations$videoControls$en {
	_Translations$videoControls$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} qiziziziz',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} qiziziziz',
	);
	@override String get audioLabel => 'Ovoz';
	@override String get subtitlesLabel => 'Subtitr';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String get letterbox => 'Keng ekran (Letterbox)';
	@override String get fillScreen => 'Ekranni toʻldirish';
	@override String get stretch => 'Choʻzish';
	@override String get lockRotation => 'Aylanishni qulflash';
	@override String get unlockRotation => 'Aylanish qulfini ochish';
	@override String get timerActive => 'Taymer faol';
	@override String playbackWillPauseIn({required Object duration}) => 'Ijro ${duration}-dan keyin toʻxtatiladi';
	@override String get sleepTimerEndOfVideo => 'Joriy videoning oxiri';
	@override String get sleepTimerStopAtHeader => 'Toʻxtash vaqti';
	@override String get sleepTimerDurationHeader => 'Taymer';
	@override String get playbackWillPauseAtEnd => 'Ijro ushbu videoning oxirida toʻxtatiladi';
	@override String get stillWatching => 'Hali ham tomosha qilyapsizmi?';
	@override String pausingIn({required Object seconds}) => '${seconds}son-dan keyin toʻxtatiladi';
	@override String get continueWatching => 'Davom ettirish';
	@override String get autoPlayNext => 'Keyingisini avtomatik ijro etish';
	@override String get playNext => 'Keyingisini ijro etish';
	@override String get playButton => 'Ijro etish';
	@override String get pauseButton => 'Pauza';
	@override String get playbackPaused => 'Pauza';
	@override String get playbackResumed => 'Ijro etilmoqda';
	@override String get loadingVideo => 'Video yuklanmoqda';
	@override String get showPlaybackControls => 'Boshqaruv tugmalarini koʻrsatish';
	@override String get hidePlaybackControls => 'Boshqaruv tugmalarini yashirish';
	@override String seekBackwardButton({required Object seconds}) => '${seconds} soniya orqaga oʻtkazish';
	@override String seekForwardButton({required Object seconds}) => '${seconds} soniya oldinga oʻtkazish';
	@override String get previousButton => 'Oldingi qism';
	@override String get nextButton => 'Keyingi qism';
	@override String get previousChapterButton => 'Oldingi boʻlimcha';
	@override String get nextChapterButton => 'Keyingi boʻlimcha';
	@override String get muteButton => 'Ovozni oʻchirish';
	@override String get unmuteButton => 'Ovozni yoqish';
	@override String get settingsButton => 'Ijro sozlamalari';
	@override String get tracksButton => 'Ovoz va subtitrlar';
	@override String get trackSelectionTitle => 'Playback\'dan əvvəl birimimiz.';
	@override String get trackSelectionAuto => 'Automatizasyon';
	@override String get chaptersButton => 'Boʻlimlar';
	@override String get versionQualityButton => 'Versiya va sifat';
	@override String get versionColumnHeader => 'Versiya';
	@override String get qualityColumnHeader => 'Sifat';
	@override String get qualityOriginal => 'Asl nusxa';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Qayta kodlash mavjud emas — asl sifatda ijro etiladi';
	@override String get subtitleUnavailableFallback => 'Tanlangan subtitr yuklanmadi';
	@override String get pipButton => 'Rasm ichida rasm rejimi';
	@override String get aspectRatioButton => 'Tomonlar nisbati';
	@override String get ambientLighting => 'Atrof-muhit yoritilishi';
	@override String get fullscreenButton => 'Toʻliq ekranga oʻtish';
	@override String get exitFullscreenButton => 'Toʻliq ekrandan chiqish';
	@override String get alwaysOnTopButton => 'Har doim ustida';
	@override String get rotationLockButton => 'Aylanish qulfi';
	@override String get lockScreen => 'Ekranni qulflash';
	@override String get screenLockButton => 'Ekran qulfi';
	@override String get longPressToUnlock => 'Qulfdan chiqarish uchun bosib turing';
	@override String get timelineSlider => 'Video vaqt shkalasi';
	@override String get volumeSlider => 'Ovoz balandligi';
	@override String endsAt({required Object time}) => 'Tugash vaqti: ${time}';
	@override String get pipActive => 'Rasm ichida rasm rejimida ijro etilmoqda';
	@override String get pipFailed => 'PiP rejimini ishga tushirishda xatolik';
	@override String get screenshotSaved => 'Ekran tasviri saqlandi';
	@override String get screenshotFailed => 'Ekran tasvirini olib boʻlmadi';
	@override String zoomPercent({required Object percent}) => 'Masshtab %${percent}';
	@override String volumePercent({required Object percent}) => 'Ovoz ${percent}%';
	@override late final _Translations$videoControls$pipErrors$uz pipErrors = _Translations$videoControls$pipErrors$uz._(_root);
	@override String get chapters => 'Boʻlimlar';
	@override String get noChaptersAvailable => 'Boʻlimlar mavjud emas';
	@override String get queue => 'Navbat';
	@override String get noQueueItems => 'Navbatda elementlar yoʻq';
	@override String get noAudioDevicesAvailable => 'Mavjud audio qurilmalar yoʻq';
	@override String get searchSubtitles => 'Subtitr qidirish';
	@override String get loadSubtitleFile => 'Subtitle fildi qaytadi.';
	@override String get subtitleLoadFailed => 'Subtitle file‘i qaytadi.';
	@override String get language => 'Til';
	@override String get noSubtitlesFound => 'Subtitr topilmadi';
	@override String get subtitleDownloaded => 'Subtitr yuklab olindi';
	@override String get subtitleDownloadedNotApplied => 'Subtitr yuklab olindi, lekin qoʻllanilmadi';
	@override String get subtitleDownloadFailed => 'Subtitrni yuklab boʻlmadi';
	@override String get searchLanguages => 'Tillardan qidirish...';
	@override String get skipIntro => 'Kirishni oʻtkazish';
	@override String get skipCredits => 'Titrlardan oʻtish';
	@override String get skipAds => 'Ads koʻyadi';
	@override String get nextEpisode => 'Keyingi qism';
	@override String subtitleTrack({required Object n}) => 'Yoʻlak ${n}';
	@override String subtitleFile({required Object name}) => 'Subtitr ${name}';
	@override String forcedTrack({required Object label}) => '${label} (Majburiy)';
	@override String get osdSubtitlesOff => 'Subtitr: Oʻchirilgan';
	@override String osdSubtitles({required Object track}) => 'Subtitr: ${track}';
	@override String osdAudio({required Object track}) => 'Ovoz: ${track}';
}

// Path: messages
class _Translations$messages$uz extends Translations$messages$en {
	_Translations$messages$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Koʻrilgan deb belgilandi';
	@override String get markedAsUnwatched => 'Koʻrilmagan deb belgilandi';
	@override String get markedAsWatchedOffline => 'Koʻrilgan deb belgilandi (tarmoqqa ulanganda sinxronlanadi)';
	@override String get markedAsUnwatchedOffline => 'Koʻrilmagan deb belgilandi (tarmoqqa ulanganda sinxronlanadi)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Avtomatik oʻchirildi: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n,
		one: 'Koʻrilgan ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} yuklama avtomatik oʻchirildi',
		other: 'Koʻrilgan ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} yuklama avtomatik oʻchirildi',
	);
	@override String get removedFromContinueWatching => '"Tomoshani davom ettirish"dan oʻchirildi';
	@override String errorLoading({required Object error}) => 'Xatolik: ${error}';
	@override String get searchPartialResults => 'Baʼzi media serverlarda qidiruv amalga oshmadi. Mavjud natijalar koʻrsatilmoqda.';
	@override String get streamInterrupted => 'Oqim uzildi. Qayta urinish uchun ijro tugmasini bosing yoki boshqa joyga oʻting.';
	@override String get liveStreamInterrupted => 'Jonli oqim uzildi. Qayta urinish uchun ijro tugmasini bosing.';
	@override String get fileInfoNotAvailable => 'Fayl haqida maʼlumot mavjud emas';
	@override String get playbackAuthenticationRequired => 'Ushbu elementni ijro etish uchun serverga qaytadan kiring.';
	@override String get playbackServerUnavailable => 'Media serveri mavjud emas. Keyinroq qaytadan urinib koʻring.';
	@override String get playbackDataInvalid => 'Server notoʻgʻri ijro maʼlumotlarini qaytardi.';
	@override String get playbackCancelled => 'Ijro bekor qilindi.';
	@override String get playbackFailed => 'Ijroni ishga tushirishda xatolik.';
	@override String playbackFailedDetail({required Object error}) => 'Ijroni boshlab boʻlmadi: ${error}';
	@override String get audioOutputFailed => 'Audio chiqishi javob bermay qoldi. Televizor yoki resiverning audio ulanishini tekshiring; boshqa ilovalarda ham ovoz boʻlmasa, qurilmani qayta ishga tushiring.';
	@override String get mediaUnavailable => 'Bu kontent endi mavjud emas.';
	@override String errorLoadingFileInfo({required Object error}) => 'Fayl maʼlumotlarini yuklashda xatolik: ${error}';
	@override String get errorLoadingSeries => 'Serialni yuklashda xatolik';
	@override String get musicNotSupported => 'Musiqa ijrosi hali qoʻllab-quvvatlanmaydi';
	@override String get noDescriptionAvailable => 'Tavsif mavjud emas';
	@override String get noProfilesAvailable => 'Profillar yoʻq';
	@override String get contactAdminForProfiles => 'Profil qoʻshish uchun administratorga murojaat qiling';
	@override String get unableToDetermineLibrarySection => 'Kutubxona boʻlimini aniqlab boʻlmadi';
	@override String get logsCleared => 'Jurnallar tozalandi';
	@override String get logsCopied => 'Jurnallar nusxalandi';
	@override String get noLogsAvailable => 'Jurnallar yoʻq';
	@override String libraryScanning({required Object title}) => '"${title}" skanerlanmoqda...';
	@override String libraryScanStarted({required Object title}) => '"${title}" uchun skanerlash boshlandi';
	@override String libraryScanFailed({required Object error}) => 'Kutubxonani skanerlab boʻlmadi: ${error}';
	@override String metadataRefreshing({required Object title}) => '"${title}" uchun metamaʼlumotlar yangilanmoqda...';
	@override String metadataRefreshStarted({required Object title}) => '"${title}" uchun metamaʼlumotlarni yangilash boshlandi';
	@override String metadataRefreshFailed({required Object error}) => 'Metamaʼlumotlarni yangilab boʻlmadi: ${error}';
	@override String get logoutConfirm => 'Haqiqatan ham chiqmoqchimisiz?';
	@override String get noSeasonsFound => 'Mavsumlar topilmadi';
	@override String get seasonsLoadFailed => 'Mavsumlarni yuklab boʻlmadi';
	@override String get noEpisodesFound => 'Birinchi mavsumda qismlar topilmadi';
	@override String get noEpisodesFoundGeneral => 'Qismlar topilmadi';
	@override String get episodesLoadFailed => 'Qismlarni yuklab boʻlmadi';
	@override String get noResultsFound => 'Natijalar topilmadi';
	@override String sleepTimerSet({required Object label}) => 'Uyqu taymeri ${label} vaqtiga oʻrnatildi';
	@override String get noItemsAvailable => 'Elementlar yoʻq';
	@override String get failedToCreatePlayQueueNoItems => 'Ijro navbatini yaratib boʻlmadi — elementlar yoʻq';
	@override String failedPlayback({required Object action, required Object error}) => '${action} muvaffaqiyatsiz tugadi: ${error}';
	@override String get switchingToCompatiblePlayer => 'Mos keluvchi pleyerga oʻtilmoqda...';
	@override String get serverLimitTitle => 'Ijro etishda xatolik';
	@override String get serverLimitBody => 'Server xatoligi (HTTP 500). Cheklov ushbu seansni rad etdi.';
	@override String get mediaUnreadableTitle => 'Fayl mavjud emas';
	@override String get mediaUnreadableBody => 'Server bu elementni topdi, lekin uning faylini oʻqiy olmadi (HTTP 404). Fayl koʻchirilgan, oʻchirilgan yoki uning saqlash joyi oflayn boʻlishi mumkin. Server egasidan faylni tekshirishni va kutubxonani qayta skanerlashni soʻrang.';
	@override String get serverBusyTitle => 'Oqim mavjud emas';
	@override String get serverBusyBody => 'Server bu faylni uzatishni qayta-qayta rad etdi (HTTP 503). U qayta ishga tushayotgan yoki band boʻlishi, yoxud fayl saqlanadigan xotira oflayn boʻlishi mumkin. Birozdan keyin qaytadan urinib koʻring. Muammo davom etsa, server egasidan server va fayl xotirasini tekshirishni soʻrang.';
	@override String get playbackNotAllowedTitle => 'Ijro etishga ruxsat berilmagan';
	@override String get playbackNotAllowedBody => 'Server bu elementni uzatishni rad etdi (HTTP 403). Hisobingizda uni ijro etishga ruxsat boʻlmasligi yoki server ijroga faqat oʻzining mahalliy tarmogʻida ruxsat berishi mumkin.';
	@override String get logsUploaded => 'Jurnallar yuklandi';
	@override String get logsUploadFailed => 'Jurnallarni yuklab boʻlmadi';
	@override String get logId => 'Jurnal ID-si';
	@override String get burnedSubtitlesUseMenu => 'Subtitrlar bu oqim tasviriga singdirilgan. Ularni subtitr menyusidan oʻzgartiring.';
	@override String get noVideoUrl => 'Video URL mavjud emas';
	@override String get playbackNoMediaSources => 'Server ijro etiladigan media manbalarini qaytarmadi';
	@override String get playbackDataNotPrepared => 'Ijro maʼlumotlari tayyor boʻlishidan oldin boshlandi';
	@override String get streamSelectionUnavailable => 'Bu manba uchun oqim tanlash imkoni yoʻq';
	@override String get streamSelectionFailed => 'Tanlangan oqimlarni qoʻllab boʻlmadi';
	@override String get trackSelectionNotRemembered => 'Bu trek tanlovi faqat joriy ijroga qoʻllanadi.';
	@override String get serverUnavailableForProfile => 'Faol profil uchun hech qanday server mavjud emas';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$uz extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get previewSample => 'Uqqqqga qurtlar qurtlarga qurtlan qurtlar.';
	@override String get text => 'Matn';
	@override String get border => 'Hoshiya';
	@override String get background => 'Fon';
	@override String get fontSize => 'Shrift oʻlchami';
	@override String get textColor => 'Matn rangi';
	@override String get borderSize => 'Hoshiya oʻlchami';
	@override String get borderColor => 'Hoshiya rangi';
	@override String get backgroundOpacity => 'Fon shaffofligi';
	@override String get backgroundColor => 'Fon rangi';
	@override String get position => 'Joylashuvi';
	@override String get assOverride => 'ASS qayta aniqlash';
	@override String get overrideScale => 'Masshtablash';
	@override String get overrideForce => 'Majburlash';
	@override String get overrideStrip => 'Formatlashni olib tashlash';
	@override String get positionTop => 'Yuqori';
	@override String get positionBottom => 'Pastki';
	@override String get useMargins => 'Chekkalardan foydalanish';
	@override String get useMarginsDescription => 'Matnli subtitrlarga videodan tashqaridagi joydan foydalanishga ruxsat berish. Uslubiy subtitrlar oʻz joylashuvini saqlashi mumkin.';
	@override String get anchorToScreen => 'Ekranga mahkamlash';
	@override String get anchorToScreenDescription => 'Matnli subtitrlarni keng ekranli video ostidagi qora hoshiyalarda koʻrsatish';
	@override String get bold => 'Qalin';
	@override String get italic => 'Qiya';
	@override String get renderResolution => 'Renderlash oʻlchamlari';
	@override String get renderResolutionScreen => 'Ekran oʻlchamlari';
	@override String get renderResolutionVideo => 'Video oʻlchamlari';
}

// Path: mpvConfig
class _Translations$mpvConfig$uz extends Translations$mpvConfig$en {
	_Translations$mpvConfig$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Kengaytirilgan video pleyer sozlamalari';
	@override String get presets => 'Tayyor sozlamalar';
	@override String get noPresets => 'Saqlangan sozlamalar yoʻq';
	@override String get saveAsPreset => 'Sozlama sifatida saqlash...';
	@override String get presetName => 'Sozlama nomi';
	@override String get presetNameHint => 'Ushbu sozlama uchun nom kiriting';
	@override String get loadPreset => 'Yuklash';
	@override String get deletePreset => 'Oʻchirish';
	@override String get presetSaved => 'Sozlama saqlandi';
	@override String get presetLoaded => 'Sozlama yuklandi';
	@override String get presetDeleted => 'Sozlama oʻchirildi';
	@override String get confirmDeletePreset => 'Ushbu sozlamani oʻchirishga ishonchingiz komilmi?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# izoh';
	@override String get lineHint => 'option=value';
	@override String get addLine => 'Qator qoʻshish';
	@override String get removeLine => 'Qatorni oʻchirish';
	@override String get embeddedVoHint => 'Linux-da vo, gpu-context va gpu-api e\'tiborga olinmaydi: ichki video har doim video tekisligida vo=libmpv orqali ko\'rsatiladi va gpu-next (ArtCNN kabi compute shaderlar uchun zarur) ichki rejimda ishlay olmaydi.';
}

// Path: dialog
class _Translations$dialog$uz extends Translations$dialog$en {
	_Translations$dialog$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Harakatni tasdiqlash';
}

// Path: profiles
class _Translations$profiles$uz extends Translations$profiles$en {
	_Translations$profiles$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'PlezyNG profilini qoʻshish';
	@override String get switchingProfile => 'Profil almashtirilmoqda…';
	@override String get deleteThisProfileTitle => 'Ushbu profil oʻchirilsinmi?';
	@override String deleteThisProfileMessage({required Object displayName}) => '${displayName} oʻchiriladi. Ulanishlarga taʼsir qilmaydi.';
	@override String get active => 'Faol';
	@override String get manage => 'Boshqarish';
	@override String get delete => 'Oʻchirish';
	@override String get signOut => 'Chiqish';
	@override String get signOutPlexTitle => 'Plex-dan chiqilsinmi?';
	@override String signOutPlexMessage({required Object displayName}) => '${displayName} va barcha Plex Home foydalanuvchilari oʻchirilsinmi? Istalgan vaqtda qayta kirishingiz mumkin.';
	@override String get signOutPlexDeleteDownloads => 'Yuklamalarni ham oʻchirish';
	@override String get signOutPlexDeleteDownloadsDescription => 'Aks holda ular ushbu qurilmada qoladi va shu hisobga qayta kirganingizda yana paydo boʻladi.';
	@override String get signedOutPlex => 'Plex-dan chiqdingiz.';
	@override String get signOutFailed => 'Chiqish amalga oshmadi.';
	@override String get sectionTitle => 'Profillar';
	@override String get summarySingle => 'Boshqariladigan foydalanuvchilarni birlashtirish uchun profillar qoʻshing';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} profil · faol: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} profil';
	@override String get removeConnectionTitle => 'Ulanish oʻchirilsinmi?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => '${displayName} foydalanuvchisining ${connectionLabel} ulanishiga kirish huquqi olib tashlanadi. Boshqa profillarning kirish huquqi saqlanadi.';
	@override String get deleteProfileTitle => 'Profil oʻchirilsinmi?';
	@override String deleteProfileMessage({required Object displayName}) => '${displayName} va uning ulanishlari oʻchiriladi. Serverlar mavjud boʻlib qoladi.';
	@override String get profileNameLabel => 'Profil nomi';
	@override String get pinProtectionLabel => 'PIN himoyasi';
	@override String get copyAutomationLink => 'Android automatizasyon link';
	@override String get copyAutomationLinkDescription => 'Bu profili Android\'dan ya\'z o\'z o‘z o\'zi o\'z. Profil PIN kontrollar hala valib.';
	@override String get automationLinkCopied => 'Profil automatizasyon link kopyadi.';
	@override String get pinManagedByPlex => 'PIN kodni Plex boshqaradi. plex.tv saytida tahrirlang.';
	@override String get noPinSetEditOnPlex => 'PIN kod oʻrnatilmagan. Talab qilish uchun plex.tv saytida Home foydalanuvchisini tahrirlang.';
	@override String get setPin => 'PIN oʻrnatish';
	@override String get setPinTitle => 'PIN oʻrnatish';
	@override String get confirmPinTitle => 'PIN kodni tasdiqlash';
	@override String get pinSet => 'PIN oʻrnatildi';
	@override String get changePin => 'Oʻzgartirish';
	@override String get removePin => 'Oʻchirish';
	@override String get connectionsLabel => 'Ulanishlar';
	@override String get add => 'Qoʻshish';
	@override String get deleteProfileButton => 'Profilni oʻchirish';
	@override String get noConnectionsHint => 'Ulanishlar yoʻq — ushbu profildan foydalanish uchun ulanish qoʻshing.';
	@override String get noConnections => 'Ulanishlar yoʻq';
	@override String get plexHomeAccount => 'Plex Home hisobi';
	@override String plexAccountChip({required Object account}) => 'Plex hisobi: ${account}';
	@override String plexAccountUserChip({required Object account, required Object user}) => '${account} hisobi orqali ${user}';
	@override String get connectionDefault => 'Standart';
	@override String connectionAs({required Object displayName}) => '${displayName} sifatida';
	@override String get makeDefault => 'Standart qilish';
	@override String get removeConnection => 'Oʻchirish';
	@override String get profileRenamed => 'Profil nomi oʻzgartirildi.';
	@override String borrowAddTo({required Object displayName}) => '${displayName} profiliga qoʻshish';
	@override String get borrowExplain => 'Boshqa profilning ulanishidan foydalanish. PIN bilan himoyalangan profillar PIN talab qiladi.';
	@override String get borrowEmpty => 'Hali foydalanadigan hech narsa yoʻq.';
	@override String get borrowEmptySubtitle => 'Avval boshqa profilga Plex, Jellyfin yoki Emby ulang.';
	@override String get borrowLoadFailed => 'Mavjud ulanishlarni yuklab boʻlmadi.';
	@override String borrowFromProfile({required Object displayName}) => '${displayName} profilidan';
	@override String get borrowConnectionBorrowed => 'Ulanishdan foydalanildi.';
	@override String get borrowFailed => 'Ulanishdan foydalanib boʻlmadi.';
	@override String get incorrectPin => 'Notoʻgʻri PIN kod.';
	@override String get incorrectPinTryAgain => 'Notoʻgʻri PIN kod. Qaytadan urinib koʻring.';
	@override String get sourceProfileMissingParentAccount => 'Manba profilda asosiy hisob yoʻq.';
	@override String get failedToLoadHomeUsers => 'Plex Home foydalanuvchilarini yuklab boʻlmadi.';
	@override String get failedToVerifyPin => 'PIN kodni tekshirib boʻlmadi.';
	@override String get newProfile => 'Yangi profil';
	@override String get profileNameHint => 'masalan, Mehmonlar, Bolalar';
	@override String get pinProtectionOptional => 'PIN himoyasi (ixtiyoriy)';
	@override String get pinExplain => 'Profillar orasida oʻtish uchun 4 xonali PIN kod talab qilinadi.';
	@override String get continueButton => 'Davom ettirish';
	@override String get pinsDontMatch => 'PIN kodlar mos kelmadi';
	@override String get tokenIdentityMismatch => 'Plex profil tokeni kutilmagan serverga tegishli boʻlib chiqdi';
	@override String get settingsLocked => 'Bu profili için ayatlar kilib.';
	@override String get unlockSettings => 'Unlock ko‘zlar';
	@override String get showExploreForProfile => 'Bu profili bo\'qlarga ko\'qlar.';
	@override String get showExploreForProfileDescription => 'Bu profili navigationdan Explore\'i yasaningiz.';
}

// Path: connections
class _Translations$connections$uz extends Translations$connections$en {
	_Translations$connections$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Ulanishlar';
	@override String get addConnection => 'Ulanish qoʻshish';
	@override String get addConnectionSubtitleNoProfile => 'Plex orqali kiring yoki Jellyfin yoki Emby serveriga ulaning';
	@override String addConnectionSubtitleScoped({required Object displayName}) => '${displayName} profiliga qoʻshish: Plex, Jellyfin, Emby yoki boshqa ulanish';
	@override String sessionExpiredOne({required Object name}) => '${name} uchun seans vaqti tugadi';
	@override String sessionExpiredMany({required Object count}) => '${count} server uchun seans vaqti tugadi';
	@override String accessDeniedOne({required Object name}) => '${name} ushbu hisobga kirishni rad etdi';
	@override String accessDeniedMany({required Object count}) => '${count} ta server ushbu hisobga kirishni rad etdi';
	@override String get signInAgain => 'Qaytadan kirish';
	@override String editMediaBrowserTitle({required Object product}) => '${product} ulanishini tahrirlash';
	@override String editMediaBrowserIntro({required Object serverName}) => '${serverName} uchun URL-larni qoʻshing yoki olib tashlang. PlezyNG eng kam kechikishga ega boʻlgan mavjud URL-dan foydalanadi.';
}

// Path: accountPreferences
class _Translations$accountPreferences$uz extends Translations$accountPreferences$en {
	_Translations$accountPreferences$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Hisob sozlamalari';
	@override String hubSubtitleSingle({required Object account}) => '${account} hisobida saqlangan audio, subtitr va kutubxona parametrlari';
	@override String hubSubtitleMultiple({required Object count}) => '${count} ta hisobda saqlangan audio, subtitr va kutubxona parametrlari';
	@override String get pickAccount => 'Har bir hisob oʻz sozlamalarini saqlaydi. Tahrirlash uchun birini tanlang.';
	@override String get storedOnAccount => 'Bu parametrlar hisobning oʻzida saqlanadi — unga kirilgan har bir ilova ulardan foydalanadi, jumladan boshqa qurilmalaringizdagi PlezyNG ham.';
	@override String get noAccounts => 'Sozlanadigan hisoblar yoʻq';
	@override String get noAccountsHint => 'Plex-ga kiring yoki Jellyfin yoki Emby serverini ulang — shunda oʻsha hisobda saqlangan sozlamalar shu yerda koʻrinadi.';
	@override String get unavailable => 'Bu hisobga ulanib boʻlmadi';
	@override String get loadFailed => 'Bu sozlamalarni yuklab boʻlmadi';
	@override String get noPreference => 'Afzallik yoʻq';
	@override String get notSet => 'Oʻrnatilmagan';
	@override late final _Translations$accountPreferences$groups$uz groups = _Translations$accountPreferences$groups$uz._(_root);
	@override String get preferredAudioLanguage => 'Afzal koʻrilgan audio tili';
	@override String get autoSelectAudio => 'Audioni til boʻyicha tanlash';
	@override String get autoSelectAudioDescription => 'Oʻchirilgan holatda faylda standart deb belgilangan audio trek ishlatiladi.';
	@override String get preferredSubtitleLanguage => 'Afzal koʻrilgan subtitr tili';
	@override String get subtitleMode => 'Subtitrni yoqish';
	@override late final _Translations$accountPreferences$subtitleModes$uz subtitleModes = _Translations$accountPreferences$subtitleModes$uz._(_root);
	@override String get subtitleAccessibility => 'SDH subtitrlar';
	@override late final _Translations$accountPreferences$subtitleAccessibilityOptions$uz subtitleAccessibilityOptions = _Translations$accountPreferences$subtitleAccessibilityOptions$uz._(_root);
	@override String get forcedSubtitles => 'Majburiy subtitrlar';
	@override late final _Translations$accountPreferences$forcedSubtitleOptions$uz forcedSubtitleOptions = _Translations$accountPreferences$forcedSubtitleOptions$uz._(_root);
	@override String get displayMissingEpisodes => 'Yoʻqolgan qismlarni koʻrsatish';
	@override String get displayMissingEpisodesDescription => 'Server biladigan, lekin fayli boʻlmagan qismlarni roʻyxatlaydi.';
	@override String get hidePlayedInLatest => '"Soʻnggi" boʻlimida koʻrilganlarni yashirish';
	@override String get hidePlayedInLatestDescription => 'Serverning "Soʻnggi" qatorlariga allaqachon koʻrgan narsalaringizni kiritmaslik.';
	@override String get displayCollectionsView => 'Toʻplamlar koʻrinishini koʻrsatish';
	@override String get displayCollectionsViewDescription => 'Kutubxonalaringiz yonida serverning Toʻplamlar koʻrinishini taklif qilish.';
	@override String get rewatchingInNextUp => 'Qayta koʻrilgan seriallarni "Keyingi" boʻlimida saqlash';
	@override String get rewatchingInNextUpDescription => 'Serialni tugatib, qayta boshlasangiz, "Keyingi" boʻlimi serialni tashlab yuborish oʻrniga qayta tomoshaga ergashadi.';
	@override String get watchedIndicator => 'Koʻrilganlik belgilari';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$uz watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$uz._(_root);
	@override String get mediaReviewsVisibility => 'Baholar va sharhlar';
	@override late final _Translations$accountPreferences$mediaReviewsOptions$uz mediaReviewsOptions = _Translations$accountPreferences$mediaReviewsOptions$uz._(_root);
}

// Path: discover
class _Translations$discover$uz extends Translations$discover$en {
	_Translations$discover$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Kashf qilish';
	@override String get noContentAvailable => 'Kontent mavjud emas';
	@override String get addMediaToLibraries => 'Kutubxonalaringizga media qoʻshing';
	@override String get continueWatching => 'Tomoshani davom ettirish';
	@override String continueWatchingIn({required Object library}) => '${library} ichida tomoshani davom ettirish';
	@override String get nextUp => 'Navbatda';
	@override String nextUpIn({required Object library}) => '${library} ichida navbatda';
	@override String get recentlyAdded => 'Yaqinda qoʻshilganlar';
	@override String recentlyAddedIn({required Object library}) => '${library} ichida yaqinda qoʻshilganlar';
	@override String latestAlbumsIn({required Object library}) => '${library} ichida soʻnggi albomlar';
	@override String recentlyPlayedIn({required Object library}) => '${library} ichida yaqinda eshitilganlar';
	@override String mostPlayedIn({required Object library}) => '${library} ichida eng koʻp eshitilganlar';
	@override String playEpisode({required Object season, required Object episode}) => 'M${season}Q${episode}';
	@override String get overview => 'Tavsif';
	@override String get cast => 'Aktyorlar';
	@override late final _Translations$discover$findNext$uz findNext = _Translations$discover$findNext$uz._(_root);
	@override String get extras => 'Treylerlar va qoʻshimchalar';
	@override String get studio => 'Studiya';
	@override String get rating => 'Reyting';
	@override String get director => 'Rejissyor';
	@override String get directors => 'Rejissyorlar';
	@override String get movie => 'Film';
	@override String get tvShow => 'TV Shou';
	@override String minutesLeft({required Object minutes}) => '${minutes} daq qoldi';
	@override String get moreLikeThis => 'Oʻxshashlar';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ta nom',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ta nom',
	);
	@override late final _Translations$discover$person$uz person = _Translations$discover$person$uz._(_root);
}

// Path: errors
class _Translations$errors$uz extends Translations$errors$en {
	_Translations$errors$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Qidiruv xatoligi: ${error}';
	@override String get searchUnavailable => 'Qidiruv hech bir media serverga ulana olmadi.';
	@override String connectionTimeout({required Object context}) => '${context} yuklanish vaqti tugadi';
	@override String get connectionFailed => 'Media serveriga ulanib boʻlmadi';
	@override String unableToLoad({required Object context}) => '${context} yuklab boʻlmadi.';
	@override String get noClientAvailable => 'Mavjud mijoz yoʻq';
	@override String get pleaseEnterToken => 'Tokenni kiriting';
	@override String get invalidToken => 'Notoʻgʻri token';
	@override String failedToVerifyToken({required Object error}) => 'Tokenni tekshirib boʻlmadi: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => '${displayName} profiliga oʻtib boʻlmadi';
	@override String failedToDeleteProfile({required Object displayName}) => '${displayName} profilini oʻchirib boʻlmadi';
	@override String get failedToRate => 'Reytingni yangilab boʻlmadi';
	@override String get reasonTimedOut => 'ulanish vaqti tugadi';
	@override String get reasonUnreachable => 'serverga ulanib boʻlmadi';
	@override String get reasonRefused => 'server soʻrovni rad etdi';
	@override String get reasonNotFound => 'element endi serverda yoʻq';
	@override String get reasonServerError => 'server xatolik haqida xabar berdi';
	@override String get reasonCancelled => 'soʻrov bekor qilindi';
	@override String get reasonUnexpected => 'kutilmagan xatolik yuz berdi';
}

// Path: libraries
class _Translations$libraries$uz extends Translations$libraries$en {
	_Translations$libraries$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => 'Film o‘zari film o‘zadi';
	@override String get randomPickFailed => 'Bu librariyadan film o‘zilmaydi.';
	@override String get title => 'Kutubxonalar';
	@override String get fallbackTitle => 'Kutubxona';
	@override String get scanLibraryFiles => 'Fayllarni skanerlash';
	@override String get scanLibrary => 'Kutubxonani skanerlash';
	@override String get analyze => 'Tahlil qilish';
	@override String get analyzeLibrary => 'Kutubxonani tahlil qilish';
	@override String get refreshMetadata => 'Metamaʼlumotlarni yangilash';
	@override String get emptyTrash => 'Savatni tozalash';
	@override String emptyingTrash({required Object title}) => '"${title}" savati tozalanmoqda...';
	@override String trashEmptied({required Object title}) => '"${title}" savati tozalandi';
	@override String failedToEmptyTrash({required Object error}) => 'Savatni tozalab boʻlmadi: ${error}';
	@override String analyzing({required Object title}) => '"${title}" tahlil qilinmoqda...';
	@override String analysisStarted({required Object title}) => '"${title}" uchun tahlil boshlandi';
	@override String failedToAnalyze({required Object error}) => 'Tahlil qilib boʻlmadi: ${error}';
	@override String get noLibrariesFound => 'Kutubxonalar topilmadi';
	@override String get allLibrariesHidden => 'Barcha kutubxonalar yashirilgan';
	@override String hiddenLibrariesCount({required Object count}) => 'Yashirin kutubxonalar (${count})';
	@override String get thisLibraryIsEmpty => 'Ushbu kutubxona boʻsh';
	@override String get noItemsMatchFilters => 'Filtrlarga mos keladigan elementlar topilmadi';
	@override String get resetFilters => 'Filtrlarni qayta oʻrnatish';
	@override String get all => 'Barchasi';
	@override String get clearAll => 'Barchasini tozalash';
	@override String scanLibraryConfirm({required Object title}) => '"${title}" kutubxonasini skanerlamoqchimisiz?';
	@override String analyzeLibraryConfirm({required Object title}) => '"${title}" kutubxonasini tahlil qilmoqchimisiz?';
	@override String refreshMetadataConfirm({required Object title}) => '"${title}" metamaʼlumotlarini yangilaysizmi?';
	@override String emptyTrashConfirm({required Object title}) => '"${title}" savatini tozalaysizmi?';
	@override String get manageLibraries => 'Kutubxonalarni boshqarish';
	@override String get sort => 'Saralash';
	@override String get sortBy => 'Saralash mezonlari';
	@override String get filters => 'Filtrlar';
	@override String get confirmActionMessage => 'Ushbu harakatni bajarmoqchimisiz?';
	@override String get showLibrary => 'Kutubxonani koʻrsatish';
	@override String get hideLibrary => 'Kutubxonani yashirish';
	@override String get libraryOptions => 'Kutubxona parametrlari';
	@override String get content => 'kutubxona tarkibi';
	@override String get selectLibrary => 'Kutubxonani tanlash';
	@override String filtersWithCount({required Object count}) => 'Filtrlar (${count})';
	@override String get noRecommendations => 'Tavsiyalar yoʻq';
	@override String get noCollections => 'Ushbu kutubxonada toʻplamlar yoʻq';
	@override String get noFoldersFound => 'Jildlar topilmadi';
	@override String get folders => 'jildlar';
	@override late final _Translations$libraries$tabs$uz tabs = _Translations$libraries$tabs$uz._(_root);
	@override late final _Translations$libraries$groupings$uz groupings = _Translations$libraries$groupings$uz._(_root);
	@override late final _Translations$libraries$filterCategories$uz filterCategories = _Translations$libraries$filterCategories$uz._(_root);
	@override late final _Translations$libraries$sortLabels$uz sortLabels = _Translations$libraries$sortLabels$uz._(_root);
	@override late final _Translations$libraries$advancedFilters$uz advancedFilters = _Translations$libraries$advancedFilters$uz._(_root);
	@override late final _Translations$libraries$selection$uz selection = _Translations$libraries$selection$uz._(_root);
}

// Path: about
class _Translations$about$uz extends Translations$about$en {
	_Translations$about$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Dastur haqida';
	@override String get openSourceLicenses => 'Ochiq kodli litsenziyalar';
	@override String versionLabel({required Object version}) => 'Versiya ${version}';
	@override String get appDescription => 'Flutter asosidagi qulay Plex, Jellyfin va Emby mijozi';
	@override String get viewLicensesDescription => 'Uchinchi tomon kutubxonalarining litsenziyalarini koʻrish';
	@override String get privacyPolicy => 'Maxfiylik siyosati';
}

// Path: serverSelection
class _Translations$serverSelection$uz extends Translations$serverSelection$en {
	_Translations$serverSelection$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => '${username} (${email}) uchun serverlar topilmadi';
	@override String failedToLoadServers({required Object error}) => 'Serverlarni yuklashda xatolik: ${error}';
	@override String get noValidServers => 'Bu hisobda foydalanish mumkin boʻlgan server topilmadi';
}

// Path: hubDetail
class _Translations$hubDetail$uz extends Translations$hubDetail$en {
	_Translations$hubDetail$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Nomi';
	@override String get releaseYear => 'Chiqqan yili';
	@override String get dateAdded => 'Qoʻshilgan sanasi';
	@override String get rating => 'Reyting';
	@override String get noItemsFound => 'Elementlar topilmadi';
}

// Path: logs
class _Translations$logs$uz extends Translations$logs$en {
	_Translations$logs$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Jurnallarni tozalash';
	@override String get copyLogs => 'Jurnallarni nusxalash';
	@override String get uploadLogs => 'Jurnallarni yuklash';
	@override String get saveLogs => 'Jurnallarni faylga saqlash';
	@override String logsSaved({required Object path}) => 'Hesizlar kaygan ${path}';
	@override String get saveLogsFailed => 'Bu log file\'i salmaydi.';
}

// Path: detail
class _Translations$detail$uz extends Translations$detail$en {
	_Translations$detail$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => 'Tugash vaqti: ${time}';
}

// Path: startup
class _Translations$startup$uz extends Translations$startup$en {
	_Translations$startup$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'PlezyNG ishga tusha olmadi';
	@override String get failedBody => 'Ishga tushirish paytida nimadir xato ketdi. Quyidagi tafsilotlar aynan nima muvaffaqiyatsiz boʻlganini koʻrsatadi.';
	@override String get failedBodyRepairable => 'Plezyning saqlangan sozlamalar fayli shikastlangan va PlezyNG ishga tushishidan oldin uni qayta tiklash kerak. Qayta urinish yordam bermaydi — Saqlashni tiklashni tanlang.';
	@override String get phaseLabel => 'Qadam';
	@override String get showDetails => 'Tafsilotlarni koʻrsatish';
	@override String get hideDetails => 'Tafsilotlarni yashirish';
	@override String get copyDetails => 'Tafsilotlarni nusxalash';
	@override String get detailsCopied => 'Tafsilotlar buferga nusxalandi';
	@override String get uploadDetails => 'Tafsilotlarni yuklash';
	@override String get repairStorage => 'Saqlashni tiklash';
	@override String get repairTitle => 'Saqlangan maʼlumotlar tikilsinmi?';
	@override String get repairBodyCommon => 'Plezyning sozlamalar fayli shikastlangan va uni oʻqib boʻlmaydi. Tiklash barcha sozlamalarni standart holatiga qaytaradi.';
	@override String get repairBodyOneCredential => 'Bitta saqlangan kirish maʼlumoti shikastlangan va uni oʻqib boʻlmaydi. Tiklash faqat uni olib tashlaydi; boshqa sozlamalaringizga tegilmaydi.';
	@override String get repairBodySignInsKept => 'Serverlaringiz va profillaringiz tizimga kirgan holda qoladi.';
	@override String get repairBodySignInsLost => 'Saqlangan kirish maʼlumotlaringizni himoya qiluvchi kalitni ushbu fayldan tiklab boʻlmaydi, shuning uchun har bir server va profilga qaytadan kirishingiz kerak boʻladi. Media serveringizdagi hech narsaga taʼsir qilmaydi.';
	@override String get repairBodySessionsUncertain => 'Trekerlar (MAL, AniList, Simkl, Trakt) va Seerr alohida saqlanadi va ular saqlanib qolishi ham, yoʻqolishi ham mumkin. PlezyNG aynan nimani saqlaganini sizga xabar qiladi.';
	@override String get repairConfirm => 'Tiklash';
	@override String get repairSucceeded => 'Saqlash tiklandi';
	@override String get repairNeedsRestart => 'Saqlash tiklandi — qayta ishga tushirish kerak';
	@override String get restartRequiredBody => 'Maʼlumotlaringiz tiklandi, lekin PlezyNG ulardan foydalanishi uchun yangidan ishga tushishi kerak. PlezyNG-ni yoping va qayta oching.';
	@override String get quitPlezy => 'PlezyNG-dan chiqish';
	@override String get repairFailed => 'Tiklash amalga oshmadi';
	@override String get repairKeptSignIns => 'Serverlaringiz va profillaringiz hali ham tizimga kirgan.';
	@override String get repairLostSignIns => 'Saqlangan kirish maʼlumotlaringizni himoya qiluvchi kalitni tiklab boʻlmadi. Har bir server va profilga qaytadan kirishingiz kerak boʻladi.';
	@override String get repairLostSessions => 'Kamida bitta treker yoki Seerr ulanishi yoʻqoldi va uni qayta ulash kerak.';
	@override String get backupTitle => 'Shikastlangan faylning nusxasi saqlab qoʻyildi';
	@override String get backupWarning => 'Unda kirish hisob maʼlumotlaringiz bor. Uni yuklamang yoki baham koʻrmang.';
	@override String get deleteBackup => 'Nusxani oʻchirish';
	@override String get backupDeleted => 'Nusxa oʻchirildi.';
	@override String get previousFailureTitle => 'PlezyNG oxirgi marta ishga tushmadi';
}

// Path: licenses
class _Translations$licenses$uz extends Translations$licenses$en {
	_Translations$licenses$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Bogʻliq paketlar';
	@override String get license => 'Litsenziya';
	@override String licenseNumber({required Object number}) => 'Litsenziya ${number}';
	@override String licensesCount({required Object count}) => '${count} litsenziya';
}

// Path: navigation
class _Translations$navigation$uz extends Translations$navigation$en {
	_Translations$navigation$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Kutubxonalar';
	@override String get downloads => 'Yuklamalar';
	@override String get liveTv => 'Jonli TV';
	@override String get explore => 'Kashf qilish';
}

// Path: explore
class _Translations$explore$uz extends Translations$explore$en {
	_Translations$explore$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override late final _Translations$explore$mdblistShelves$uz mdblistShelves = _Translations$explore$mdblistShelves$uz._(_root);
	@override String get title => 'Kashf qilish';
	@override String get selectSource => 'Manbani tanlang';
	@override late final _Translations$explore$rows$uz rows = _Translations$explore$rows$uz._(_root);
	@override late final _Translations$explore$status$uz status = _Translations$explore$status$uz._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} qism',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} qism',
	);
	@override String get cast => 'Aktyorlar';
	@override String get characters => 'Qahramonlar';
	@override String get addToWatchlist => 'Tomosha roʻyxatiga qoʻshish';
	@override String get removeFromWatchlist => 'Tomosha roʻyxatidan oʻchirish';
	@override String get addedToWatchlist => 'Tomosha roʻyxatiga qoʻshildi';
	@override String get removedFromWatchlist => 'Tomosha roʻyxatidan olib tashlandi';
	@override String get watchlistUpdateFailed => 'Tomosha roʻyxatini yangilab boʻlmadi';
	@override String get watchlistNoMatch => 'Bu elementni tomosha roʻyxatiga moslab boʻlmadi';
	@override String get notInLibrary => 'Kutubxonangizda yoʻq';
	@override String get inTheseLibraries => 'Ushbu kutubxonalarda bor';
	@override String get checkingLibrary => 'Kutubxona tekshirilmoqda...';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} serverni tekshirib boʻlmadi',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} serverni tekshirib boʻlmadi',
	);
	@override String get emptyTitle => 'Hali bu yerda hech narsa yoʻq';
	@override String emptyMessage({required Object source}) => '${source} manbasidan olingan qatorlar bu yerda koʻrinadi.';
	@override String searchHint({required Object source}) => '${source} ichidan qidirish';
	@override String searchEmpty({required Object query}) => '"${query}" boʻyicha natija topilmadi';
	@override String searchPrompt({required Object source}) => '${source} orqali filmlar va seriallarni qidiring.';
	@override String get searchFailed => 'Qidiruv xatoligi. Ulanishni tekshiring.';
	@override late final _Translations$explore$badge$uz badge = _Translations$explore$badge$uz._(_root);
	@override late final _Translations$explore$stats$uz stats = _Translations$explore$stats$uz._(_root);
	@override late final _Translations$explore$season$uz season = _Translations$explore$season$uz._(_root);
	@override late final _Translations$explore$format$uz format = _Translations$explore$format$uz._(_root);
	@override late final _Translations$explore$sourceMaterial$uz sourceMaterial = _Translations$explore$sourceMaterial$uz._(_root);
	@override late final _Translations$explore$creditRole$uz creditRole = _Translations$explore$creditRole$uz._(_root);
	@override late final _Translations$explore$relation$uz relation = _Translations$explore$relation$uz._(_root);
	@override String broadcast({required Object day, required Object time}) => '${day} kuni soat ${time} da efirga uzatiladi';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => '${day} kuni soat ${time} ${timezone} da efirga uzatiladi';
	@override late final _Translations$explore$detail$uz detail = _Translations$explore$detail$uz._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ta natija',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ta natija',
	);
}

// Path: liveTv
class _Translations$liveTv$uz extends Translations$liveTv$en {
	_Translations$liveTv$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Jonli TV';
	@override String get guide => 'Dasturlar jadvali';
	@override String get noChannels => 'Mavjud kanallar yoʻq';
	@override String get noDvr => 'Serverda DVR sozlanmagan';
	@override String get serverUnavailable => 'Jonli TV serveri mavjud emas.';
	@override String get serverNotConnected => 'Jonli TV serveriga ulanmagan.';
	@override String get noPrograms => 'Dastur haqida maʼlumot yoʻq';
	@override String get liveStreamFailed => 'Jonli oqim xatoligi';
	@override String get unknownProgram => 'Nomaʼlum dastur';
	@override String get timelineLiveProgram => 'Live program (playback bu programdan o‘zadi)';
	@override String get timelineBuffer => 'Bufer vaqt chizig‘i';
	@override String get timelineUnavailable => 'Timinni ishatta';
	@override String get timelineEstimated => 'Playback bilan bilan bilan';
	@override String get timelinePending => 'Tadiqga islan';
	@override String get timelineStale => 'Dastur jadvali eskirgan bo‘lishi mumkin';
	@override String get unknownHub => 'Nomaʼlum';
	@override String get unknownError => 'Nomaʼlum xatolik';
	@override String channelNumber({required Object number}) => '${number}-kanal';
	@override String get unknownChannel => 'Nomaʼlum kanal';
	@override String get live => 'JONLI EFIR';
	@override String get premiereBadge => 'Yeni';
	@override String get reloadGuide => 'Jadvalni yangilash';
	@override String get searchGuide => 'Dasturlar jadvalidan qidirish';
	@override String get searchHint => 'Kanal va dasturlarni qidirish';
	@override String searchNoResults({required Object query}) => '"${query}" boʻyicha moslik topilmadi';
	@override String get channelsSection => 'Kanallar';
	@override String get programsSection => 'Dasturlar';
	@override String get now => 'Hozir';
	@override String get today => 'Bugun';
	@override String get tomorrow => 'Ertaga';
	@override String get midnight => 'Yarim tun';
	@override String get overnight => 'Tunda';
	@override String get morning => 'Ertalab';
	@override String get daytime => 'Kunduzi';
	@override String get evening => 'Kechqurun';
	@override String get lateNight => 'Tunda';
	@override String get whatsOn => 'Hozir nima efirda?';
	@override String get watchChannel => 'Kanalni tomosha qilish';
	@override String get favorites => 'Tanlanganlar';
	@override String get reorderFavorites => 'Tanlanganlarni tartiblash';
	@override String get noFavoriteChannels => 'Sevimli kanallar yoʻq';
	@override String get noFavoriteChannelsHint => 'Barcha kanallarni koʻrsating, soʻng kanalni sevimlilarga qoʻshish uchun uni bosib turing.';
	@override String get showAllChannels => 'Barcha kanallarni koʻrsatish';
	@override String get favoritesLoadFailed => 'Tanlanganlarni yuklab boʻlmadi. Ulanishni tekshirib, qayta urinib koʻring.';
	@override String get favoritesUpdateFailed => 'Tanlanganlarni yangilab boʻlmadi.';
	@override String get joinSession => 'Davom etayotgan seansga qoʻshilish';
	@override String watchFromStart({required Object minutes}) => 'Boshidan tomosha qilish (${minutes} daq ilgari)';
	@override String get watchLive => 'Jonli efirni tomosha qilish';
	@override String get goToLive => 'Jonli efirga oʻtish';
	@override String get record => 'Yozib olish';
	@override String get recordEpisode => 'Qismni yozib olish';
	@override String get recordSeries => 'Serialni yozib olish';
	@override String get recordOptions => 'Yozib olish parametrlari';
	@override String get saveTo => 'Shu yerga saqlash';
	@override String get recordings => 'Yozib olinganlar';
	@override String get scheduledRecordings => 'Rejalashtirilganlar';
	@override String get recordingRules => 'Yozib olish qoidalari';
	@override String get noScheduledRecordings => 'Rejalashtirilgan yozuvlar yoʻq';
	@override String get manageRecording => 'Yozuvni boshqarish';
	@override String get cancelRecording => 'Yozishni bekor qilish';
	@override String get cancelRecordingTitle => 'Yozish toʻxtatilsinmi?';
	@override String cancelRecordingMessage({required Object title}) => '${title} endi yozib olinmaydi.';
	@override String get deleteRule => 'Qoidani oʻchirish';
	@override String get deleteRuleTitle => 'Yozib olish qoidasi oʻchirilsinmi?';
	@override String deleteRuleMessage({required Object title}) => '${title} serialining keyingi qismlari yozib olinmaydi.';
	@override String get recordingScheduled => 'Yozib olish rejalashtirildi';
	@override String get alreadyScheduled => 'Ushbu dastur avvaldan rejalashtirilgan';
	@override String get dvrAdminRequired => 'DVR sozlamalari administrator huquqini talab qiladi';
	@override String get recordingFailed => 'Yozib olishni rejalashtirib boʻlmadi';
	@override String get recordingTargetMissing => 'Yozib olinadigan kutubxona aniqlanmadi';
	@override String get recordNotAvailable => 'Ushbu dasturni yozib olib boʻlmaydi';
	@override String get recordingCancelled => 'Yozib olish bekor qilindi';
	@override String get recordingRuleDeleted => 'Yozib olish qoidasi oʻchirildi';
	@override String get processRecordingRules => 'Qoidalarni qayta baholash';
	@override String get recordingInProgress => 'Hozir yozib olinmoqda';
	@override String recordingsCount({required Object count}) => '${count} rejalashtirilgan';
	@override String get editRule => 'Qoidani tahrirlash';
	@override String get editRuleAction => 'Tahrirlash';
	@override String get recordingRuleUpdated => 'Yozib olish qoidasi yangilandi';
	@override String get guideReloadRequested => 'Jadvalni yangilash soʻraldi';
	@override String get guideReloadFailed => 'Dasturlar jadvalini yangilab boʻlmadi';
	@override String get rulesProcessRequested => 'Qoidalarni qayta baholash soʻraldi';
	@override String get rulesProcessFailed => 'Yozib olish qoidalarini qayta baholab boʻlmadi';
	@override String get recordShow => 'Shouni yozib olish';
	@override late final _Translations$liveTv$recordSettings$uz recordSettings = _Translations$liveTv$recordSettings$uz._(_root);
	@override String startingInMinutes({required Object minutes}) => '${minutes} daqiqadan keyin boshlanadi';
	@override String dayAtTime({required Object day, required Object time}) => '${day}, soat ${time} da';
	@override String invalidPlaybackData({required Object product}) => '${product} Jonli TV ijrosi uchun notoʻgʻri maʼlumot qaytardi';
	@override String get failedToStartChannel => 'Jonli kanalni boshlab boʻlmadi';
	@override String get failedToBuildStreamUrl => 'Oqim URL-ini tuzib boʻlmadi';
	@override String playbackStartFailed({required Object reason}) => 'Kanalni ishga tushirib boʻlmadi: ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'Kanalni almashtirib boʻlmadi: ${reason}';
}

// Path: collections
class _Translations$collections$uz extends Translations$collections$en {
	_Translations$collections$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Toʻplamlar';
	@override String get collection => 'Toʻplam';
	@override String get empty => 'Toʻplam boʻsh';
	@override String get deleteCollection => 'Toʻplamni oʻchirish';
	@override String deleteConfirm({required Object title}) => '"${title}" oʻchirilsinmi? Bu amalni ortga qaytarib boʻlmaydi.';
	@override String get deleted => 'Toʻplam oʻchirildi';
	@override String get deleteFailed => 'Toʻplamni oʻchirib boʻlmadi';
	@override String deleteFailedWithError({required Object error}) => 'Toʻplamni oʻchirish xatoligi: ${error}';
	@override String get selectCollection => 'Toʻplamni tanlash';
	@override String get collectionName => 'Toʻplam nomi';
	@override String get enterCollectionName => 'Toʻplam nomini kiriting';
	@override String get addedToCollection => 'Toʻplamga qoʻshildi';
	@override String get errorAddingToCollection => 'Toʻplamga qoʻshib boʻlmadi';
	@override String get created => 'Toʻplam yaratildi';
	@override String get removeFromCollection => 'Toʻplamdan oʻchirish';
	@override String removeFromCollectionConfirm({required Object title}) => '"${title}" ushbu toʻplamdan oʻchirilsinmi?';
	@override String get removedFromCollection => 'Toʻplamdan oʻchirildi';
	@override String get removeFromCollectionFailed => 'Toʻplamdan oʻchirib boʻlmadi';
	@override String removeFromCollectionError({required Object error}) => 'Oʻchirish xatoligi: ${error}';
	@override String get searchCollections => 'Toʻplamlardan qidirish...';
}

// Path: playlists
class _Translations$playlists$uz extends Translations$playlists$en {
	_Translations$playlists$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ijro roʻyxatlari';
	@override String get playlist => 'Ijro roʻyxati';
	@override String get noPlaylists => 'Ijro roʻyxatlari topilmadi';
	@override String get create => 'Ijro roʻyxatini yaratish';
	@override String get playlistName => 'Ijro roʻyxati nomi';
	@override String get enterPlaylistName => 'Roʻyxat nomini kiriting';
	@override String get delete => 'Ijro roʻyxatini oʻchirish';
	@override String get removeItem => 'Roʻyxatdan oʻchirish';
	@override String get smartPlaylist => 'Aqlli ijro roʻyxati';
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} element',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} element',
	);
	@override String get emptyPlaylist => 'Ushbu roʻyxat boʻsh';
	@override String get deleteConfirm => 'Ijro roʻyxati oʻchirilsinmi?';
	@override String deleteMessage({required Object name}) => '"${name}" oʻchirilsinmi?';
	@override String get created => 'Ijro roʻyxati yaratildi';
	@override String get deleted => 'Ijro roʻyxati oʻchirildi';
	@override String get itemAdded => 'Roʻyxatga qoʻshildi';
	@override String get itemRemoved => 'Roʻyxatdan oʻchirildi';
	@override String get selectPlaylist => 'Roʻyxatni tanlash';
	@override String get searchPlaylists => 'Ijro roʻyxatlaridan qidirish...';
	@override String get errorCreating => 'Roʻyxatni yaratib boʻlmadi';
	@override String get errorDeleting => 'Roʻyxatni oʻchirib boʻlmadi';
	@override String get errorLoading => 'Roʻyxatlarni yuklab boʻlmadi';
	@override String get errorAdding => 'Roʻyxatga qoʻshib boʻlmadi';
	@override String get errorReordering => 'Qayta tartiblab boʻlmadi';
	@override String get errorRemoving => 'Roʻyxatdan oʻchirib boʻlmadi';
}

// Path: music
class _Translations$music$uz extends Translations$music$en {
	_Translations$music$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Albomga oʻtish';
	@override String get goToArtist => 'Ijrochiga oʻtish';
	@override String get instantMix => 'Tezkor miks';
	@override String get playNext => 'Keyingisini ijro etish';
	@override String get addToQueue => 'Navbatga qoʻshish';
	@override String discNumber({required Object n}) => '${n}-disk';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tarona',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tarona',
	);
	@override String get nowPlaying => 'Hozir ijro etilmoqda';
	@override String playingFrom({required Object title}) => '${title} manbasidan';
	@override String get queue => 'Navbat';
	@override String get clearQueue => 'Navbatni tozalash';
	@override String get lyrics => 'Musiqa matni';
	@override String get visualizer => 'vizualiz';
	@override String get visualizerProfileLoading => 'U‘qot bilan analizi...';
	@override String get visualizerAmbientMotion => 'Ummatik Movisi';
	@override String get visualizerPlexLoudness => 'Plex qiziziziz';
	@override String get visualizerPreviousPreset => 'Oldingi vizual uslub';
	@override String get visualizerNextPreset => 'Keyingi vizual uslub';
	@override String get visualizerPresetAurora => 'Qutb yog‘dusi';
	@override String get visualizerPresetBloom => 'Gullash';
	@override String get visualizerPresetOrbitals => 'Orbitadi';
	@override String get visualizerPresetPrism => 'Prizma';
	@override String get visualizerPresetTunnel => 'Tünel';
	@override String get visualizerPresetTrackMap => 'Mapadi';
	@override String get noLyrics => 'Musiqa matni yoʻq';
	@override String get sleepTimer => 'Uyqu taymeri';
	@override String get sleepTimerEndOfTrack => 'Taronaning oxiri';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} daqiqa',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} daqiqa',
	);
	@override String get stopPlayback => 'Ijroni toʻxtatish';
	@override String get previousTrack => 'Oldingi tarona';
	@override String get nextTrack => 'Keyingi tarona';
	@override String get repeat => 'Takrorlash';
	@override String get repeatAll => 'Barchasini takrorlash';
	@override String get repeatOne => 'Birtasini takrorlash';
	@override String get instantMixNoServer => 'Tezkor miks uchun hech qanday server mavjud emas';
	@override String get instantMixFailed => 'Tezkor miksni yuklab boʻlmadi';
	@override String get instantMixEmpty => 'Tezkor miks hech qanday taronani qaytarmadi';
	@override String noAudioUrl({required Object track}) => '${track} uchun audio URL mavjud emas';
	@override late final _Translations$music$discography$uz discography = _Translations$music$discography$uz._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$uz extends Translations$watchTogether$en {
	_Translations$watchTogether$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Birgalikda tomosha qilish';
	@override String get description => 'Doʻstlaringiz va oilangiz bilan birga tomosha qiling';
	@override String get createRoom => 'Xona yaratish';
	@override String get creatingRoom => 'Xona yaratilmoqda...';
	@override String get joinRoom => 'Xonaga qoʻshilish';
	@override String get joiningRoom => 'Xonaga qoʻshilmoqda...';
	@override String get connecting => 'Ulanmoqda...';
	@override String get relayPublic => 'Xonalar ommaviy Open Watch Party relelaridan foydalanadi.';
	@override String relayCustom({required Object url}) => 'Xonalar ${url} manzilidagi relengizdan foydalanadi.';
	@override String get recentRooms => 'Yaqindagi xonalar';
	@override String get roomActions => 'Xona amallari';
	@override String get renameRoom => 'Xona nomini oʻzgartirish';
	@override String get removeRoom => 'Oʻchirish';
	@override String get enterRoomCode => 'Tashkilotchidan olingan 6 belgili kodni kiriting.';
	@override String get roomCode => 'Xona kodi';
	@override String get paste => 'Qoʻyish';
	@override String get noCodeInClipboard => 'Almashish buferida xona kodi yoʻq';
	@override String get copyCode => 'Kodni nusxalash';
	@override String get codeCopied => 'Xona kodi nusxalandi';
	@override String get shareInvite => 'Taklifni ulashish';
	@override String get inviteCopied => 'Taklif nusxalandi. Uni xabarga joylashtiring.';
	@override String inviteMessage({required Object code}) => 'PlezyNG-dagi "Birgalikda tomosha qilish" xonamga qoʻshiling: "Birgalikda tomosha qilish" boʻlimini oching, "Xonaga qoʻshilish" tugmasini tanlang va ${code} kodini kiriting.';
	@override String get openSessionControls => 'Boshqaruv elementlarini ochish';
	@override String get reconnecting => 'Qayta ulanmoqda...';
	@override String get reconnectingDescription => 'Ulanish uzildi. Xonaga avtomatik ravishda qayta qoʻshilasiz.';
	@override String get connected => 'Ulandi';
	@override String get disconnected => 'Uzildi';
	@override String get youAreHost => 'Siz tashkilotchisiz';
	@override String hostedBy({required Object name}) => 'Tashkilotchi: ${name}';
	@override String get hostControlsPlayback => 'Ijroni tashkilotchi boshqaradi';
	@override String get anyoneCanControl => 'Ijroni har kim boshqara oladi';
	@override String get roomLocked => 'Xona qulflangan';
	@override String get nowPlaying => 'Hozir ijro etilmoqda';
	@override String get nothingPlaying => 'Hech narsa ijro etilmayapti';
	@override String get nothingPlayingHost => 'Xona bilan ulashish uchun istalgan kutubxonadan biror narsani ijro eting.';
	@override String get nothingPlayingGuest => 'Tashkilotchi biror narsani ijro etganda, u shu yerda ochiladi.';
	@override String get notShareable => 'Bu video katalogdagi hech bir nomga mos kelmadi, shuning uchun uni faqat shu serverga kirish huquqi bor foydalanuvchilar ijro eta oladi.';
	@override String get searching => 'Bu video kutubxonalaringizdan qidirilmoqda...';
	@override String get yourCopy => 'Sizning nusxangiz';
	@override String get sharingYourCopy => 'Siz oʻz nusxangizni ulashyapsiz';
	@override String playingOtherLength({required Object difference}) => 'Nusxangiz ijro etilmoqda, ${difference}';
	@override String get mismatchTitle => 'Nusxangizning uzunligi boshqacha';
	@override String mismatchDescription({required Object difference}) => 'Eng yaqin nusxangiz xonadagi videodan ${difference}. Bu boshqa montaj yoki versiya boʻlishi mumkin.';
	@override String get playAnyway => 'Baribir ijro etish';
	@override String get chooseAnotherCopy => 'Boshqa nusxani tanlash';
	@override String get dontPlay => 'Ijro etmaslik';
	@override String get unavailableTitle => 'Sizda bu video yoʻq';
	@override String get unavailableDescription => 'PlezyNG uni kutubxonalaringizdan topa olmadi. Nusxani oʻzingiz tanlang yoki qaytadan qidiring.';
	@override String get chooseCopy => 'Nusxani tanlash';
	@override String get searchAgain => 'Qaytadan qidirish';
	@override String get noCandidates => 'Kutubxonalaringizda nusxalar topilmadi.';
	@override String get choiceFailed => 'Bu nusxani xona uchun ijro etib boʻlmadi';
	@override String lengthLonger({required Object duration}) => '${duration} uzunroq';
	@override String lengthShorter({required Object duration}) => '${duration} qisqaroq';
	@override String get lengthSame => 'Uzunligi bir xil';
	@override String get lengthUnknown => 'Uzunligi nomaʼlum';
	@override String get joinCurrentPlayback => 'Joriy ijroga qoʻshilish';
	@override String get joinCurrentPlaybackDescription => 'Tashkilotchi koʻrayotgan joyga oʻting';
	@override String get stopMedia => 'Videoni hamma uchun toʻxtatish';
	@override String get syncOffset => 'Sinxronlash siljishi';
	@override String get syncOffsetDescription => 'Videongiz xonadan oldinda yoki orqada boʻlsa, uni siljiting.';
	@override String offsetHint({required Object difference}) => 'Nusxangiz xonadagi videodan ${difference}.';
	@override String applyDifference({required Object offset}) => 'Qoʻllash: ${offset}';
	@override String get offsetMinusSecond => '-1 s';
	@override String get offsetMinusTenth => '-100 ms';
	@override String get offsetPlusTenth => '+100 ms';
	@override String get offsetPlusSecond => '+1 s';
	@override String get participants => 'Ishtirokchilar';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ishtirokchi',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ishtirokchi',
	);
	@override String get hostBadge => 'TASHKILOTCHI';
	@override String nameYou({required Object name}) => '${name} (Siz)';
	@override String get playerIdle => 'Nofaol';
	@override String get playerLoading => 'Yuklanmoqda';
	@override String get playerReady => 'Tayyor';
	@override String get playerBuffering => 'Buferlanmoqda';
	@override String get matchSearching => 'Qidirilmoqda';
	@override String get matchMatched => 'Video bor';
	@override String get matchMismatched => 'Uzunligi boshqacha';
	@override String get matchUnavailable => 'Video yoʻq';
	@override String participantOffset({required Object offset}) => 'Siljish: ${offset}';
	@override String get makeHost => 'Tashkilotchi qilish';
	@override String get makeHostQuestion => 'Tashkilotchi oʻtkazilsinmi?';
	@override String makeHostConfirm({required Object name}) => '${name} ijroni boshqaradi va seansni hamma uchun olib boradi.';
	@override String get transfer => 'Oʻtkazish';
	@override String get removeParticipant => 'Xonadan chiqarish';
	@override String removeParticipantQuestion({required Object name}) => '${name} chiqarilsinmi?';
	@override String removeParticipantConfirm({required Object name}) => '${name} xonadan chiqariladi. Xonani qulflamasangiz, u kod orqali qayta qoʻshila oladi.';
	@override String get remove => 'Chiqarish';
	@override String get roomSettings => 'Xona sozlamalari';
	@override String get letEveryoneControl => 'Hammaga ijroni boshqarishga ruxsat berish';
	@override String get lockRoom => 'Xonani qulflash';
	@override String get lockRoomDescription => 'Yangi ishtirokchilar qoʻshila olmaydi';
	@override String get leaveRoom => 'Xonadan chiqish';
	@override String get leaveRoomQuestion => 'Xonadan chiqilsinmi?';
	@override String get leaveRoomConfirm => 'Xona kodi orqali qayta qoʻshilishingiz mumkin.';
	@override String get leave => 'Chiqish';
	@override String get endRoom => 'Xonani yakunlash';
	@override String get endRoomQuestion => 'Xona yakunlansinmi?';
	@override String get endRoomConfirm => 'Bu xonani hamma uchun yakunlaydi.';
	@override String get end => 'Yakunlash';
	@override String get playBlockedTitle => 'Ijro boshlanmadi';
	@override String get playBlockedDescription => 'Xona bilan birga tomosha qilishni boshlash uchun ijro tugmasini bosing.';
	@override late final _Translations$watchTogether$notices$uz notices = _Translations$watchTogether$notices$uz._(_root);
	@override late final _Translations$watchTogether$ended$uz ended = _Translations$watchTogether$ended$uz._(_root);
	@override late final _Translations$watchTogether$errors$uz errors = _Translations$watchTogether$errors$uz._(_root);
	@override String untitledEpisode({required Object number}) => '${number}-qism';
}

// Path: downloads
class _Translations$downloads$uz extends Translations$downloads$en {
	_Translations$downloads$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Yuklamalar';
	@override String get manage => 'Boshqarish';
	@override String get tvShows => 'TV Shoular';
	@override String get movies => 'Filmlar';
	@override String get music => 'Musiqa';
	@override String tracksQueued({required Object count}) => '${count} tarona yuklash navbatiga qoʻshildi';
	@override String get noDownloads => 'Hali yuklamalar yoʻq';
	@override String get noDownloadsDescription => 'Yuklangan fayllar oflayn koʻrish uchun bu yerda koʻrinadi';
	@override String get downloadNow => 'Yuklab olish';
	@override String get deleteDownload => 'Yuklamani oʻchirish';
	@override String get retryDownload => 'Yuklashni qaytadan urinish';
	@override String get downloadQueued => 'Yuklash navbatga qoʻyildi';
	@override String get downloadResumed => 'Yuklash davom ettirildi';
	@override String get serverErrorBitrate => 'Server xatoligi: fayl tezlik cheklovidan oshgan boʻlishi mumkin';
	@override String get storageFull => 'Boʻsh xotirani saqlash uchun yuklashlar toʻxtatildi. Joy boʻshating yoki boshqa yuklash joyini tanlang, soʻng qayta urinib koʻring.';
	@override String get storageUnavailable => 'Boʻsh xotirani tekshirib boʻlmagani uchun yuklamalar toʻxtatildi. Yuklash joyini tekshirib, qaytadan urinib koʻring.';
	@override String episodesQueued({required Object count}) => '${count} qism yuklash navbatiga qoʻshildi';
	@override String get downloadDeleted => 'Yuklama oʻchirildi';
	@override String deleteConfirm({required Object title}) => '"${title}" ushbu qurilmadan oʻchirilsinmi?';
	@override String get deleteCollectionDownloads => 'Yuklamalarni oʻchirish';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => '"${title}" ichidagi barcha yuklamalar ushbu qurilmadan oʻchirilsinmi?';
	@override String get collectionDownloadsDeleted => 'Yuklamalar oʻchirildi';
	@override String get cancelledDownloadTitle => 'Toʻxtatilgan yuklama';
	@override String get cancelledDownloadMessage => 'Ushbu yuklash bekor qilindi. Nima qilmoqchisiz?';
	@override String get allEpisodesAlreadyDownloaded => 'Barcha qismlar avvaldan yuklab olingan';
	@override String get resumeDownload => 'Yuklashni davom ettirish';
	@override String get cancelledDownload => 'Toʻxtatilgan yuklama';
	@override String syncingFile({required Object file, required Object status}) => '${file} (${status} sinxronlanmoqda)';
	@override String downloadedFileClickToComplete({required Object file}) => 'Yuklab olindi ${file} - Yakunlash uchun bosing';
	@override String get partialDownloadClickToComplete => 'Qisman yuklandi - Yakunlash uchun bosing';
	@override String get deleting => 'Oʻchirilmoqda...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => '${title} oʻchirilmoqda... (${current} / ${total})';
	@override String get queuedTooltip => 'Navbatda';
	@override String queuedFilesTooltip({required Object files}) => 'Navbatdagi fayllar: ${files}';
	@override String get downloadingTooltip => 'Yuklanmoqda...';
	@override String downloadingFilesTooltip({required Object files}) => 'Yuklanayotgan fayllar: ${files}';
	@override String get noDownloadsTree => 'Yuklamalar yoʻq';
	@override String get pauseAll => 'Barchasini toʻxtatib turish';
	@override String get resumeAll => 'Barchasini davom ettirish';
	@override String get retryAll => 'Barchasini qaytadan yuklash';
	@override String get retryFailed => 'Muvaffaqiyatsiz yuklamalarni qaytadan yuklash';
	@override String get deleteAll => 'Barchasini oʻchirish';
	@override String get selectVersion => 'Versiyani tanlash';
	@override String get allEpisodes => 'Barcha qismlar';
	@override String get unwatchedOnly => 'Faqat koʻrilmaganlar';
	@override String nextNUnwatched({required Object count}) => 'Keyingi ${count} koʻrilmagan';
	@override String get customAmount => 'Boshqa miqdor...';
	@override String get customAmountAny => 'Istalgan miqdorni kiriting…';
	@override String get randomEpisodes => 'Reddimiyadi';
	@override String get includeSpecials => 'Maxsus qismlarni qoʻshish';
	@override String get howManyEpisodes => 'Nechta qism?';
	@override String get invalidEpisodeCount => 'Toʻgʻri qismlar sonini kiriting.';
	@override String get keepSynced => 'Sinxronlangan holatda ushlash';
	@override String get downloadOnce => 'Bir marta yuklab olish';
	@override String keepNUnwatched({required Object count}) => '${count} koʻrilmagan qismni saqlash';
	@override String get editSyncRule => 'Sinxronlash qoidasini tahrirlash';
	@override String get removeSyncRule => 'Sinxronlash qoidasini oʻchirish';
	@override String removeSyncRuleConfirm({required Object title}) => '"${title}" sinxronlashi toʻxtatilsinmi? Yuklab olingan qismlar saqlanadi.';
	@override String removeListSyncRuleConfirm({required Object title}) => '"${title}" sinxronlashi toʻxtatilsinmi?';
	@override String get deleteSyncRuleDownloads => 'Bogʻliq yuklamalar ham oʻchirilsin';
	@override String get deleteSyncRuleDownloadsDescription => 'Boshqa sinxronlash qoidasi yoki profil ishlatayotgan yuklamalar saqlanadi.';
	@override String syncRuleCreated({required Object count}) => 'Sinxronlash qoidasi yaratildi — ${count} koʻrilmagan qism saqlanadi';
	@override String get syncRuleUpdated => 'Sinxronlash qoidasi yangilandi';
	@override String get syncRuleRemoved => 'Sinxronlash qoidasi oʻchirildi';
	@override String get syncRuleAndDownloadsRemoved => 'Sinxronlash qoidasi va bogʻliq yuklamalar oʻchirildi';
	@override String get syncRuleCleanupBusy => 'Sinxronlash qoidalari hozir yangilanmoqda. Bir ozdan soʻng qayta urinib koʻring.';
	@override String get syncRuleCleanupUnavailable => 'Bogʻliq yuklamalarni xavfsiz aniqlab boʻlmadi. Serverga qayta ulanib koʻring yoki yuklamalarni oʻchirmasdan qoidani olib tashlang.';
	@override String syncedNewEpisodes({required Object title, required Object count}) => '${title} uchun ${count} yangi qism sinxronlandi';
	@override String get syncNow => 'Sinkni';
	@override String get downloadsUpToDate => 'Yuklab olingan fayllar yangilangan';
	@override String syncComplete({required Object queued, required Object removed}) => 'Sync complet · ${queued} queued, ${removed} xifonadi';
	@override String get activeSyncRules => 'Faol sinxronlash qoidalari';
	@override String get reviewOrphanFiles => 'Yozuvi yo‘q yuklamalarni ko‘rib chiqish';
	@override String get orphanReviewTitle => 'Yozuvi yo‘q yuklamalarni ko‘rib chiqish';
	@override String get orphanReviewDescription => 'Bu belgilangan fayllar PlezyNG boshqaradigan standart yuklab olish papkalarida joylashgan, ammo ularga mos yuklab olish yozuvi yoki faol vazifa yo‘q. O‘chirishdan oldin ro‘yxatni tekshiring.';
	@override String orphanReviewCount({required Object count, required Object size}) => '${count} ta fayl · ${size}';
	@override String orphanDeleteFiles({required Object count}) => '${count} ta faylni o‘chirish';
	@override String get orphanCleanupNone => 'Yozuvi yo‘q yuklab olingan fayllar topilmadi';
	@override String get orphanCleanupFailed => 'PlezyNG boshqariladigan yuklab olish papkasini xavfsiz tarzda tekshira olmadi. Hech qanday fayl o‘chirilmadi.';
	@override String get orphanCleanupChanged => 'Ko‘rib chiqish paytida yuklab olishlar ro‘yxati o‘zgardi. Tozalashdan oldin fayllarni qayta ko‘rib chiqing.';
	@override String orphanCleanupComplete({required Object count, required Object size}) => '${count} ta yozuvi yo‘q fayl o‘chirildi · ${size} joy bo‘shatildi';
	@override String get noSyncRules => 'Sinxronlash qoidalari yoʻq';
	@override String get manageSyncRule => 'Sinxronlashni boshqarish';
	@override String get editEpisodeCount => 'Qismlar soni';
	@override String get editSyncFilter => 'Sinxronlash filtri';
	@override String get syncAllItems => 'Barcha elementlar sinxronlanadi';
	@override String get syncUnwatchedItems => 'Koʻrilmagan elementlar sinxronlanadi';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Server: ${server} • ${status}';
	@override String get syncRuleAvailable => 'Mavjud';
	@override String get syncRuleOffline => 'Oflayn';
	@override String get syncRuleSignInRequired => 'Kirish talab etiladi';
	@override String get syncRuleAccessDenied => 'Kirish rad etildi';
	@override String get syncRuleNotAvailableForProfile => 'Joriy profil uchun mavjud emas';
	@override String get syncRuleUnknownServer => 'Nomaʼlum server';
	@override String get syncRuleListCreated => 'Sinxronlash qoidasi yaratildi';
	@override late final _Translations$downloads$backgroundWarning$uz backgroundWarning = _Translations$downloads$backgroundWarning$uz._(_root);
	@override String get options => 'Yuklamalar parametrlari';
	@override late final _Translations$downloads$groupings$uz groupings = _Translations$downloads$groupings$uz._(_root);
	@override String get unknownLibrary => 'Nomaʼlum kutubxona';
	@override String get unknownShow => 'Nomaʼlum serial';
	@override String get unknownSeason => 'Nomaʼlum mavsum';
	@override String get unknownAlbum => 'Nomaʼlum albom';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} ta yakunlandi';
	@override String storageUsed({required Object size}) => 'U‘zizga: ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} yuklab olish',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} yuklab olish',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} kino',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} kino',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} film',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmlar',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} albom',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} albom',
	);
	@override String get errorFileNotFound => 'Fayl topilmadi (404)';
	@override String get errorDownloadNotAllowed => 'Server yuklab olishga ruxsat bermaydi (403)';
	@override String get errorDownloadFailed => 'Yuklab boʻlmadi';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'Yuklab boʻlmadi: ${reason}';
	@override String get convertingOnServer => 'Serverga qaytadi...';
	@override String convertingOnServerPercent({required Object percent}) => 'Konveksiyon serverni · ${percent}%';
	@override String errorHttpStatus({required Object status}) => 'Yuklab boʻlmadi (HTTP ${status})';
	@override String errorPostProcessing({required Object reason}) => 'Keyingi ishlov berishda xatolik: ${reason}';
	@override String get reasonFileNotSaved => 'faylni ushbu qurilmada saqlab boʻlmadi';
	@override String get reasonCannotResume => 'qisman yuklab olishni davom ettirib boʻlmadi';
	@override String get reasonDeviceStorageFull => 'ushbu qurilmada xotira qolmadi';
	@override String get notificationDownloading => 'Yuklanmoqda...';
	@override String get notificationComplete => 'Yuklash tugallandi';
	@override String get notificationPaused => 'Yuklash toʻxtatib turildi';
}

// Path: shaders
class _Translations$shaders$uz extends Translations$shaders$en {
	_Translations$shaders$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Sheyderlar';
	@override String get noShaderDescription => 'Video yaxshilash oʻchirilgan';
	@override String get nvscalerDescription => 'Aniqroq video uchun NVIDIA masshtabi';
	@override String get artcnnVariantNeutral => 'Neytral';
	@override String get artcnnVariantDenoise => 'Shovqinni kamaytirish';
	@override String get artcnnVariantDenoiseSharpen => 'Shovqinni kamaytirish + Aniqlik';
	@override String get qualityFast => 'Tezkor';
	@override String get qualityHQ => 'Yuqori sifat';
	@override String get mode => 'Rejim';
	@override String get importShader => 'Sheyderni import qilish';
	@override String get customShaderDescription => 'Maxsus GLSL sheyderi';
	@override String get shaderImported => 'Sheyder import qilindi';
	@override String get shaderImportFailed => 'Sheyderni import qilib boʻlmadi';
	@override String get deleteShader => 'Sheyderni oʻchirish';
	@override String deleteShaderConfirm({required Object name}) => '"${name}" oʻchirilsinmi?';
}

// Path: companionRemote
class _Translations$companionRemote$uz extends Translations$companionRemote$en {
	_Translations$companionRemote$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Yordamchi pult';
	@override String connectedTo({required Object name}) => '${name} qurilmasiga ulandi';
	@override String get unknownDevice => 'Nomaʼlum qurilma';
	@override late final _Translations$companionRemote$session$uz session = _Translations$companionRemote$session$uz._(_root);
	@override late final _Translations$companionRemote$pairing$uz pairing = _Translations$companionRemote$pairing$uz._(_root);
	@override late final _Translations$companionRemote$remote$uz remote = _Translations$companionRemote$remote$uz._(_root);
	@override late final _Translations$companionRemote$errors$uz errors = _Translations$companionRemote$errors$uz._(_root);
	@override String get closedBeforeAuth => 'Ulanish autentifikatsiyadan oldin yopildi';
}

// Path: videoSettings
class _Translations$videoSettings$uz extends Translations$videoSettings$en {
	_Translations$videoSettings$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Ijro tezligi';
	@override String get normalSpeed => 'Oddiy';
	@override String sleepTimerActive({required Object duration}) => 'Faol (${duration})';
	@override String get zoom => 'Masshtab';
	@override String get sleepTimer => 'Uyqu taymeri';
	@override String get audioSync => 'Audio sinxronlash';
	@override String get subtitleSync => 'Subtitr sinxronlash';
	@override String get hdr => 'HDR';
	@override String get hdrUnsupported => 'Bu yerda HDR mavjud emas — ish stoli kompozitori yoki video chiqishi uni uzata olmaydi.';
	@override String get hdrToneMapping => 'HDR tonlarini moslashtirish';
	@override String get hdrToneMappingCompositor => 'Kompozitor';
	@override String get hdrToneMappingCompositorDescription => 'Manbaning HDR metamaʼlumotlarini oʻzgarishsiz uzatib, ularni moslashtirishni ish stoli kompozitoriga topshirish.';
	@override String get hdrToneMappingPlayer => 'Pleyer';
	@override String get hdrToneMappingPlayerDescription => 'Pleyerda displeyning eng yuqori yorqinligiga moslashtirib, soʻng natijani kompozitorga bildirish.';
	@override String get hdrToneMappingFailed => 'HDR tonlarini moslashtirishni oʻzgartirib boʻlmadi — avvalgi rejim hali ham faol.';
	@override String get audioOutput => 'Audio chiqishi';
	@override String get performanceOverlay => 'Unumdorlik paneli';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'Hajmli ovoz';
	@override String get audioOutputSpatial => 'Fazoviy audio';
	@override String get audioOutputStereo => 'Stereo';
	@override String get audioEqualizer => 'Audio bilan bilan';
	@override String get audioEqualizerDescription => 'Bu cihaz için 5 frekans bandlar ayat. mpv\'da qothatlar; aktiv EQ audio decoding və passthrough boʻyadi.';
	@override String get audioEqualizerFlat => 'Yiyiyiyiy';
	@override String get audioEqualizerActive => 'Shaxsiy';
	@override String get audioEqualizerSaveFailed => 'Audio ekvalayzer sozlamalarini saqlab bo‘lmadi.';
	@override String get backgroundVideoAudio => 'Video audio bilan';
	@override String get backgroundVideoAudioDescription => 'Video audio oynatma qadi siz oynatma\'dan qaytadi; foto qadi qaytadi. Android bir media playback bildirim kullanır.';
	@override String get audioNormalization => 'Ovoz balandligini meʼyorlashtirish';
	@override String get audioNormalizationDisablesPassthrough => 'Ovozni PCM-ga dekodlaydi; bu yoqilganda toʻgʻridan-toʻgʻri oʻtkazish oʻchiriladi';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$uz extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get color => 'Rang';
	@override String get performance => 'Unumdorlik';
	@override String get buffer => 'Bufer';
	@override String get app => 'Ilova';
	@override String get decoder => 'Dekoder';
	@override String get rawDecoder => 'Ishlov berilmagan dekoder';
	@override String get tunneling => 'Tunnellash';
	@override String get passthrough => 'Toʻgʻridan-toʻgʻri oʻtkazish';
	@override String get aspect => 'Nisbat';
	@override String get rotation => 'Aylanish';
	@override String get dvSource => 'DV manbasi';
	@override String get dvPath => 'DV yoʻli';
	@override String get dvRouteDecoder => 'Dolby Vision dekoderi';
	@override String get dvRouteDecoderP81 => 'Dolby Vision dekoderi (P7→8.1)';
	@override String get dvRouteBaseLayer => 'Asosiy qatlam';
	@override String get dvRouteBaseLayerHdr10 => 'HDR10 asosiy qatlami';
	@override String get dvRouteBaseLayerHlg => 'HLG asosiy qatlami';
	@override String get dvRouteBaseLayerSdr => 'SDR asosiy qatlami';
	@override String get dvRouteReshaped => 'RPU orqali qayta shakllantirilgan (gpu-next)';
	@override String get p7Conversion => 'P7 oʻtkazmasi';
	@override String get sampleRate => 'Diskretlash chastotasi';
	@override String get pixelFormat => 'Piksel formati';
	@override String get hwFormat => 'HW formati';
	@override String get matrix => 'Matritsa';
	@override String get primaries => 'Asosiy ranglar';
	@override String get transfer => 'Uzatish';
	@override String get renderFps => 'Render FPS';
	@override String get displayFps => 'Displey FPS';
	@override String get avSync => 'A/V sinxronlash';
	@override String get dropped => 'Tushirib qoldirilgan kadrlar';
	@override String get dvRpus => 'DV RPU-lar';
	@override String get dvRpuAverage => 'DV RPU Oʻrt.';
	@override String get dvSampleAverage => 'DV Namuna Oʻrt.';
	@override String get maxLuma => 'Maks Luma';
	@override String get minLuma => 'Min Luma';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Foydalanilgan kesh';
	@override String get cacheLimit => 'Kesh chegarasi';
	@override String get speed => 'Tezlik';
	@override String get player => 'Pleyer';
	@override String get playMethod => 'Metodizmi';
	@override String get memory => 'Xotira';
	@override String get uiFps => 'Interfeys (UI) FPS';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Android HW';
	@override String get decoderNvidiaHw => 'NVIDIA HW';
	@override String get decoderQualcommHw => 'Qualcomm HW';
	@override String get decoderMediatekHw => 'MediaTek HW';
	@override String get decoderExynosHw => 'Exynos HW';
	@override String get decoderSoftware => 'Dasturiy';
	@override String get decoderHardware => 'Apparat';
	@override String get tunnelingActive => 'Faol';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted} (${failures} ta muvaffaqiyatsiz)';
}

// Path: externalPlayer
class _Translations$externalPlayer$uz extends Translations$externalPlayer$en {
	_Translations$externalPlayer$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tashqi pleyer';
	@override String get useExternalPlayer => 'Tashqi pleyerdan foydalanish';
	@override String get useExternalPlayerDescription => 'Videolarni boshqa ilovada ochish';
	@override String get selectPlayer => 'Pleyerni tanlash';
	@override String get customPlayers => 'Maxsus pleyerlar';
	@override String get systemDefault => 'Tizim standarti';
	@override String get addCustomPlayer => 'Maxsus pleyer qoʻshish';
	@override String get playerName => 'Pleyer nomi';
	@override String get playerNameHint => 'Mening pleyerim';
	@override String get playerCommand => 'Buyruq';
	@override String get playerPackage => 'Paket nomi';
	@override String get playerUrlScheme => 'URL sxemasi';
	@override String get off => 'Oʻchirilgan';
	@override String get launchFailed => 'Tashqi pleyerni ishga tushirib boʻlmadi';
	@override String appNotInstalled({required Object name}) => '${name} oʻrnatilmagan';
	@override String get playInExternalPlayer => 'Tashqi pleyerda ijro etish';
}

// Path: metadataEdit
class _Translations$metadataEdit$uz extends Translations$metadataEdit$en {
	_Translations$metadataEdit$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Tahrirlash...';
	@override String get screenTitle => 'Metamaʼlumotlarni tahrirlash';
	@override String get basicInfo => 'Asosiy maʼlumotlar';
	@override String get artwork => 'Rasmlar/Posterlar';
	@override String get advancedSettings => 'Kengaytirilgan sozlamalar';
	@override String get title => 'Nomi';
	@override String get sortTitle => 'Saralash nomi';
	@override String get originalTitle => 'Asl nomi';
	@override String get releaseDate => 'Chiqqan sanasi';
	@override String get contentRating => 'Kontent reytingi';
	@override String get studio => 'Studiya';
	@override String get tagline => 'Shior/Slogan';
	@override String get summary => 'Tavsif/Qisqacha';
	@override String get poster => 'Poster';
	@override String get background => 'Fon';
	@override String get logo => 'Logotip';
	@override String get squareArt => 'Kvadrat rasm';
	@override String get selectPoster => 'Posterni tanlash';
	@override String get selectBackground => 'Fonni tanlash';
	@override String get selectLogo => 'Logotipni tanlash';
	@override String get selectSquareArt => 'Kvadrat rasm tanlash';
	@override String get fromUrl => 'URL orqali';
	@override String get uploadFile => 'Fayl yuklash';
	@override String get enterImageUrl => 'Rasm URL-manzilini kiriting';
	@override String get imageUrl => 'Rasm URL-manzili';
	@override String get metadataUpdated => 'Metamaʼlumotlar yangilandi';
	@override String get metadataUpdateFailed => 'Metamaʼlumotlarni yangilab boʻlmadi';
	@override String get artworkUpdated => 'Rasmlar yangilandi';
	@override String get artworkUpdateFailed => 'Rasmlarni yangilab boʻlmadi';
	@override String get noArtworkAvailable => 'Rasm mavjud emas';
	@override String artworkOption({required Object index}) => 'Rasm opsiyasi ${index}';
	@override String selectedArtworkOption({required Object index}) => 'Rasm opsiyasi ${index}, tanlandi';
	@override String get notSet => 'Oʻrnatilmagan';
	@override String get libraryDefault => 'Kutubxona standarti';
	@override String get accountDefault => 'Hisob standarti';
	@override String get seriesDefault => 'Serial standarti';
	@override String get episodeSorting => 'Qismlarni saralash';
	@override String get oldestFirst => 'Avval eskilar';
	@override String get newestFirst => 'Avval yangilar';
	@override String get keep => 'Saqlash';
	@override String get allEpisodes => 'Barcha qismlar';
	@override String latestEpisodes({required Object count}) => 'Soʻnggi ${count} qism';
	@override String get latestEpisode => 'Soʻnggi qism';
	@override String episodesAddedPastDays({required Object count}) => 'Soʻnggi ${count} kunda qoʻshilgan qismlar';
	@override String get deleteAfterPlaying => 'Ijro etgandan keyin oʻchirish';
	@override String get never => 'Hech qachon';
	@override String get afterADay => 'Bir kundan keyin';
	@override String get afterAWeek => 'Bir haftadan keyin';
	@override String get afterAMonth => 'Bir oydan keyin';
	@override String get onNextRefresh => 'Keyingi yangilanishda';
	@override String get seasons => 'Mavsumlar';
	@override String get show => 'Koʻrsatish';
	@override String get hide => 'Yashirish';
	@override String get episodeOrdering => 'Qismlar tartibi';
	@override String get tmdbAiring => 'The Movie Database (Efir)';
	@override String get tvdbAiring => 'TheTVDB (Efir)';
	@override String get tvdbAbsolute => 'TheTVDB (Absolyut)';
	@override String get metadataLanguage => 'Metamaʼlumotlar tili';
	@override String get useOriginalTitle => 'Asl nomidan foydalanish';
	@override String get preferredAudioLanguage => 'Afzal koʻrilgan audio tili';
	@override String get preferredSubtitleLanguage => 'Afzal koʻrilgan subtitr tili';
	@override String get subtitleMode => 'Avtomatik subtitr tanlash rejimi';
	@override String get manuallySelected => 'Qoʻlda tanlangan';
	@override String get shownWithForeignAudio => 'Chet el audiosi bilan koʻrsatiladi';
	@override String get alwaysEnabled => 'Har doim yoqilgan';
	@override String get tags => 'Teglar';
	@override String get addTag => 'Teg qoʻshish';
	@override String get genre => 'Janr';
	@override String get director => 'Rejissyor';
	@override String get writer => 'Ssenarist';
	@override String get producer => 'Prodyuser';
	@override String get country => 'Mamlakat';
	@override String get collection => 'Toʻplam';
	@override String get label => 'Yorliq';
	@override String get quickTag => 'Tezkor teg...';
}

// Path: matchScreen
class _Translations$matchScreen$uz extends Translations$matchScreen$en {
	_Translations$matchScreen$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get match => 'Moslashtirish...';
	@override String get fixMatch => 'Moslikni tuzatish...';
	@override String get unmatch => 'Moslikni oʻchirish';
	@override String get unmatchConfirm => 'Ushbu moslik oʻchirilsinmi? Qayta moslashtirilgunga qadar Plex uni moslashtirilmagan deb hisoblaydi.';
	@override String get unmatchSuccess => 'Moslik oʻchirildi';
	@override String get unmatchFailed => 'Moslikni oʻchirib boʻlmadi';
	@override String get matchApplied => 'Moslik qoʻllanildi';
	@override String get matchFailed => 'Moslikni qoʻllab boʻlmadi';
	@override String get titleHint => 'Nomi';
	@override String get yearHint => 'Yil';
	@override String get search => 'Qidiruv';
	@override String get noMatchesFound => 'Mosliklar topilmadi';
}

// Path: serverTasks
class _Translations$serverTasks$uz extends Translations$serverTasks$en {
	_Translations$serverTasks$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Server vazifalari';
	@override String get failedToLoad => 'Vazifalarni yuklab boʻlmadi';
	@override String get noTasks => 'Bajarilayotgan vazifalar yoʻq';
}

// Path: trakt
class _Translations$trakt$uz extends Translations$trakt$en {
	_Translations$trakt$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Ulandi';
	@override String connectedAs({required Object username}) => '@${username} sifatida ulandi';
	@override String get disconnectConfirm => 'Trakt uzilsinmi?';
	@override String get disconnectConfirmBody => 'PlezyNG Trakt-ga maʼlumot yuborishni toʻxtatadi.';
	@override String get scrobble => 'Real vaqt rejimida kuzatish';
	@override String get scrobbleDescription => 'Ijro paytida Trakt-ga maʼlumot yuborish.';
	@override String get watchedSync => 'Koʻrish holatini sinxronlash';
	@override String get watchedSyncDescription => 'PlezyNG-da belgilanganda Trakt-da ham belgilanadi.';
}

// Path: seerr
class _Translations$seerr$uz extends Translations$seerr$en {
	_Translations$seerr$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Seerr ulash';
	@override String get serverUrl => 'Server URL-i';
	@override String get serverUrlHelper => 'Seerr manzilingiz';
	@override String get checkServer => 'Davom ettirish';
	@override String get signInWithJellyfin => 'Jellyfin orqali kirish';
	@override String get signInWithEmby => 'Emby orqali kirish';
	@override String get signInWithLocal => 'Mahalliy hisobdan foydalanish';
	@override String get email => 'Elektron pochta';
	@override String get noSignInMethods => 'Ushbu Seerr qoʻllab-quvvatlanadigan kirish usulini taklif qilmaydi.';
	@override String get instance => 'Instansiya';
	@override String get disconnectConfirm => 'Seerr uzilsinmi?';
	@override String get disconnectConfirmBody => 'PlezyNG ushbu Seerr nusxasini unutadi. Istalgan vaqtda qayta ulanishingiz mumkin.';
	@override String get request => 'Soʻrov yuborish';
	@override String get request4k => '4K soʻrov yuborish';
	@override String get seasons => 'Mavsumlar';
	@override String get allSeasons => 'Barcha mavsumlar';
	@override String get advancedOptions => 'Kengaytirilgan';
	@override String get destinationServer => 'Moʻljal server';
	@override String get qualityProfile => 'Sifat profili';
	@override String get rootFolder => 'Asosiy jild';
	@override String get languageProfile => 'Til profili';
	@override String get tags => 'Yorliqlar';
	@override String get noTags => 'Yorliqlar yoʻq';
	@override String defaultOption({required Object name}) => '${name} (Standart)';
	@override String get animeNote => 'Bu serial anime.';
	@override String get requestSubmitted => 'Soʻrov yuborildi';
	@override String requestFailed({required Object error}) => 'Soʻrov xatoligi: ${error}';
	@override String get requestsLoadFailed => 'Parametrlarni yuklab boʻlmadi';
	@override String get nothingToRequest => 'Barchasi avvaldan bor yoki soʻralgan.';
	@override String get statusAvailable => 'Mavjud';
	@override String get statusPartiallyAvailable => 'Qisman mavjud';
	@override String get statusRequested => 'Soʻraldi';
	@override String get statusProcessing => 'Ishlanmoqda';
	@override String get statusBlocklisted => 'Bloklangan roʻyxatda';
	@override String couldNotReach({required Object url, required Object error}) => '${url} manziliga ulanib boʻlmadi: ${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => '${url} manzilida Seerr nusxasi yoʻq (HTTP ${status})';
	@override String get behindAuthProxy => 'Seerr oʻrniga autentifikatsiya qiluvchi teskari proksi (SSO yoki HTTP auth) javob berdi. PlezyNG uning orqali kira olmaydi: ushbu ilova uchun Seerrning /api/v1 yoʻli proksini aylanib oʻtishiga ruxsat bering yoki Seerrga toʻgʻridan-toʻgʻri yetadigan manzildan foydalaning.';
	@override String get invalidUrl => 'Server manzilini kiriting, masalan: https://seerr.example.com';
	@override String get quickConnectUnsupported => 'Bu Seerr nusxasi Tezkor ulanishni qoʻllab-quvvatlamaydi. Buning uchun Seerr 3.4 yoki undan yangi versiya kerak.';
	@override String get notInitialized => 'Bu Seerr nusxasining dastlabki sozlamasi yakunlanmagan';
	@override String get noPlexTokenForReauth => 'Qayta kirish uchun Plex tokeni mavjud emas';
	@override String get noStoredCredentials => 'Qayta kirish uchun saqlangan kirish maʼlumotlari mavjud emas';
	@override String get signInRejected => 'Kirish rad etildi';
	@override String get noSessionCookie => 'Seerr seans cookie-faylini bermadi';
	@override String get freshCookieRejected => 'Seerr yangi seans cookie-faylini rad etdi';
	@override String get noUserInformation => 'Seerr foydalanuvchi maʼlumotlarini qaytarmadi';
	@override String get sessionRejectedAfterReauth => 'Qayta kirilgandan keyin seans rad etildi';
	@override String get permissionDenied => 'Seerr bu amalni rad etdi: hisobingizda endi kerakli ruxsat yoʻq';
	@override String get permissionRevoked => 'Buni soʻrash uchun endi ruxsatingiz yoʻq';
}

// Path: services
class _Translations$services$uz extends Translations$services$en {
	_Translations$services$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Xizmatlar';
	@override String get hubSubtitle => 'Koʻrish jarayonini sinxronlang va yangi kontent soʻrang.';
	@override String get integrations => 'Integratsiyalar';
	@override String get notConnected => 'Ulanmagan';
	@override String connectedAs({required Object username}) => '@${username} sifatida ulandi';
	@override String get scrobble => 'Jarayonni avtomatik kuzatish';
	@override String get scrobbleDescription => 'Epizod yoki filmni tugatganingizda roʻyxatingizni yangilash.';
	@override String disconnectConfirm({required Object service}) => '${service} uzilsinmi?';
	@override String disconnectConfirmBody({required Object service}) => 'PlezyNG ${service} yangilashni toʻxtatadi. Istalgan vaqtda qayta ulanishingiz mumkin.';
	@override String connectFailed({required Object service}) => '${service} ulana olmadi. Qaytadan urinib koʻring.';
	@override late final _Translations$services$names$uz names = _Translations$services$names$uz._(_root);
	@override late final _Translations$services$simklReconnect$uz simklReconnect = _Translations$services$simklReconnect$uz._(_root);
	@override late final _Translations$services$deviceCode$uz deviceCode = _Translations$services$deviceCode$uz._(_root);
	@override late final _Translations$services$oauthProxy$uz oauthProxy = _Translations$services$oauthProxy$uz._(_root);
	@override late final _Translations$services$pendingAuth$uz pendingAuth = _Translations$services$pendingAuth$uz._(_root);
	@override late final _Translations$services$libraryFilter$uz libraryFilter = _Translations$services$libraryFilter$uz._(_root);
}

// Path: addServer
class _Translations$addServer$uz extends Translations$addServer$en {
	_Translations$addServer$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => '${product} serverini qoʻshish';
	@override String get serverUrls => 'Server URL-lari';
	@override String get serverUrlsHelper => 'Vergul bilan ajratilgan bir nechta URL manziliga ruxsat beriladi.';
	@override String get findServer => 'Serverni topish';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'Mahalliy ${product} serverlari qidirilmoqda...';
	@override String localMediaBrowserServers({required Object product}) => 'Mahalliy ${product} serverlari';
	@override String get username => 'Foydalanuvchi nomi';
	@override String get password => 'Parol';
	@override String get signIn => 'Kirish';
	@override String get change => 'Oʻzgartirish';
	@override String get required => 'Talab qilinadi';
	@override String couldNotReachServer({required Object error}) => 'Serverga ulanib boʻlmadi: ${error}';
	@override String signInFailed({required Object error}) => 'Kirish xatoligi: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Tezkor ulanish xatoligi: ${error}';
	@override String get addPlexTitle => 'Plex orqali kirish';
	@override String get pinExpired => 'PIN kod vaqti tugadi.';
	@override String failedToRegisterAccount({required Object error}) => 'Hisobni roʻyxatdan oʻtkazishda xatolik: ${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => '${product} server URL-ini kiriting';
	@override String get addConnectionTitle => 'Ulanish qoʻshish';
	@override String addConnectionTitleScoped({required Object name}) => '${name} profiliga qoʻshish';
	@override String get signInWithPlexCard => 'Plex orqali kirish';
	@override String get signInWithPlexCardSubtitle => 'Ushbu qurilmani avtorizatsiya qiling. Ulashilgan serverlar qoʻshiladi.';
	@override String get signInWithPlexCardSubtitleScoped => 'Plex hisobini avtorizatsiya qiling. Home foydalanuvchilari profillarga aylanadi.';
	@override String connectToMediaBrowserCard({required Object product}) => '${product}ga ulanish';
	@override String get connectToMediaBrowserCardSubtitle => 'Server URL-ini, foydalanuvchi nomini va parolni kiriting.';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => '${product} serveringizga kiring. ${name} profiliga bogʻlanadi.';
	@override String get borrowFromAnotherProfile => 'Boshqa profildan olish';
	@override String get borrowFromAnotherProfileSubtitle => 'Boshqa profilning ulanishidan qayta foydalaning.';
	@override String get invalidCredentials => 'Foydalanuvchi nomi yoki parol notoʻgʻri';
	@override String get authResponseNotJson => 'Autentifikatsiya javobi yaroqli JSON emas';
	@override String get authResponseIncomplete => 'Serverdan kelgan kirish javobi toʻliq emas';
	@override String get quickConnectRejected => 'Quick Connect server tomonidan rad etildi';
	@override String get quickConnectNotJson => 'Quick Connect javobi yaroqli JSON emas';
	@override String get quickConnectMissingFields => 'Quick Connect javobida kod yoki maxfiy kalit yoʻq';
	@override String get quickConnectPollRejected => 'Quick Connect soʻrovi server tomonidan rad etildi';
	@override String get serverTimedOut => 'Server oʻz vaqtida javob bermadi';
	@override String get responseNotJson => 'Server javobi yaroqli JSON emas';
	@override String responseMissingIdentity({required Object product}) => 'Javobda ID yoki server nomi yoʻq — bu ${product} serverimi?';
	@override String probeFailed({required Object error}) => 'Serverga ulanib boʻlmadi: ${error}';
	@override String enterAtLeastOneUrl({required Object product}) => 'Kamida bitta ${product} server URL-ini kiriting';
	@override String noReachableServer({required Object product}) => 'Ulanish mumkin boʻlgan ${product} serveri topilmadi';
	@override String urlsPointToDifferentServers({required Object product}) => 'Bu URL-lar turli ${product} serverlariga olib boradi';
	@override String urlDoesNotMatchServer({required Object product}) => 'Bu URL ${product} serveriga mos kelmaydi';
	@override String get redirectUnsupported => 'Server qoʻllab-quvvatlanmaydigan URL-ga yoʻnaltirdi';
	@override String redirectDifferentHost({required Object product}) => 'Server boshqa xostga yoʻnaltirdi. Yakuniy ${product} URL-ini bevosita kiriting.';
	@override String get redirectInsecure => 'Server HTTPS manzilidan xavfsiz boʻlmagan URL-ga yoʻnaltirdi';
	@override String redirectUnsupportedEnterFinal({required Object product}) => 'Server qoʻllab-quvvatlanmaydigan URL-ga yoʻnaltirdi. Yakuniy ${product} URL-ini bevosita kiriting.';
	@override String get directPlexServerUrl => 'Plex server URL manzili';
	@override String get directPlexServerUrlHelper => 'IP-i və port-i Plex Media Server\'da girdi.';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex Token (iziziz)';
	@override String get plexTokenHelper => 'Bu serverda auth olmadan qurtlamad.';
	@override String get plexTokenRequired => 'Siz xifififiziziziz. xififiziniz Plex token (X-Plex-Token) sizdir.';
	@override String get connectDirectPlexCard => 'Plex Media Server (Suradi / Lokal)';
	@override String get connectDirectPlexCardSubtitle => 'IP ya URL\'i qonkash qonkash plex.tv hesab olmadan qonkash.';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => 'IP ya URL\'ni ya qotʻi qotʻy. ${name}\'i qotuj.';
	@override String get insecureTitle => 'Unencrypting qonkong';
	@override String insecureDescription({required Object url}) => '${url} HTTP protokolidan foydalanadi. Tarmoqdagi boshqa odamlar parolingizni, tokenlaringizni va mediafayllaringizni oʻqishi yoki oʻzgartirishi mumkin. Imkon boʻlsa, HTTPS dan foydalaning. Faqat ushbu tarmoqqa ishonsangiz va xavfni qabul qilsangiz davom eting.';
	@override String get allowHttp => 'HTTP ulanishiga ruxsat berish';
	@override String get httpsRequired => 'HTTPS ya qizizga qizga qifififiyizga qihga qifida qifida.';
}

// Path: watchLink
class _Translations$watchLink$uz extends Translations$watchLink$en {
	_Translations$watchLink$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => 'Bu link için bir server Plex qothathathathatdi.';
	@override String get notFound => 'Bu serial yoki film Plex serverlaringizda topilmadi.';
	@override String get ambiguous => 'Bu link birdan daha bir server\'da items-i ko‘yadi.';
	@override String get plexOnly => 'Tomosha havolalari hozircha faqat Plex serverlarini qo‘llab-quvvatlaydi.';
	@override String get unsupportedItem => 'View linklar yalnız bir show o film o\'yadi.';
	@override String get menuItem => 'U\'qizdan link';
	@override String get dialogTitle => 'Link ko‘z';
	@override String get dialogShowHint => 'Bu link\'i açmak bir sonraki epizod oynayır. shuffle\'da show\'u oynaymak için sonuna &mode=shuffle\'u ektir.';
	@override String get dialogMovieHint => 'Bu link\'i açmak filmini oynaylar.';
	@override String get copy => 'Kopi';
	@override String get copied => 'Link koʻpadi';
}

// Path: homeLayout
class _Translations$homeLayout$uz extends Translations$homeLayout$en {
	_Translations$homeLayout$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bosh sahifa tartibi';
	@override String get resetToast => 'Bosh sahifa asl Plezy joylashuviga qaytarildi';
	@override String get resetHeroTitle => 'Asosiy ko‘rinish asl Plezy holatiga qaytarilsinmi?';
	@override String get resetHeroBody => 'Herradi\'nin kahraman ayatlar bo\'yadi, bir-rondaylar bo\'ya qaytarga, Home\'nin topta, o\'yadi\'nin önizdan bo\'yadlar.';
	@override String get removeRowTitle => 'Home Riyadh bilan bilan bilan?';
	@override String removeRowBody({required Object title}) => '${title} o‘chiriladi. Bu amalni ortga qaytarib bo‘lmaydi.';
	@override String get sync => 'Sinq';
	@override String get syncAccountTitle => 'Sizga Plex hesabla sinqiziziziz.';
	@override String get syncAccountOn => 'Yoqilgan: bu qurilma qatorlar tartibi, qatorlar, asosiy banner va avtomatik almashish sozlamalarini boshqa qurilmalaringiz bilan ulashadi.';
	@override String get syncAccountOff => 'Bu sistemimiz, bu sistemimiz öz layoutini tutmayır.';
	@override String get syncNow => 'Sinkni';
	@override String get plexHomeManager => 'Plex Home menaxer';
	@override String get managePlexRows => 'Plex ruzlar Plezy\'da qotlarlar.';
	@override String get managePlexRowsDescription => 'U\'ziziziziz qiziziziyizizizimizizizizimiziziz';
	@override String get organizeHomeRows => 'Home Riyadhlar';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} ruzlar: Moving, Hero, Auto-slide, xifida';
	@override String organizeLibraryRows({required Object library}) => '${library} qaytlarlar';
	@override String organizeLibraryRowsDescription({required Object n}) => '+ ${n} riylar: Moving, Library, Home, Hero, Auto-slide';
	@override String get renderAsHero => 'Bir kartatda bir kahraman.';
	@override String get heroOnlySingleCollection => 'Bu o‘ziz o‘z o‘z q‘z o’z o‘q‘z o\'z o‘y o‘z bu‘z o`z o‘s o‘z';
	@override String get hero => 'Asosiy banner';
	@override String get autoSlide => 'Avtomatik almashish';
	@override String get autoSlideDescription => 'U\'zizga (PC) və d-pad (TV) qotlarga çalışmaygan, timiyarni qaytarmaygan.';
	@override String get autoSlideEditDescription => 'O‘shayni o‘shaydi o‘shahdi o‘s. Off: o‘shaya‘ga bir pul (PC) o‘shakla‘ga sol/dishayni o’shayni (TV). Arrows and d-pad always work either way.';
	@override String get enableHeroFirst => 'Birinci kahramanlar';
	@override String get showOnHome => 'Show on Home screen.';
	@override String get home => 'Bosh sahifa';
	@override String get removeFromHome => 'Home‘dan qaytadi';
	@override String get selectRowsFirst => 'U\'ziz, siz sizni ilk aşağıda qaytadi.';
	@override String plexManagedRows({required Object n}) => 'Plex boshqaradigan qatorlar: ${n}';
	@override String get continueWatching => 'Tomoshani davom ettirish';
	@override String get continueWatchingLibraryDescription => 'Ushbu kutubxonada tomoshani to‘xtagan joydan davom ettirish qatori';
	@override String get continueWatchingHomeDescription => 'Bosh sahifada ko‘rsatiladigan, tomoshani to‘xtagan joydan davom ettirish qatori';
	@override String get nextUpHomeDescription => 'Next Unwatched epizod riyadi sizlikliklik Home\'da o‘zizliklikliklikdi';
	@override String get library => 'Kutubxona';
	@override String get showInRecommended => 'Librarikda qaytadi qaytadi.';
	@override String get customPlexRow => 'Maxsus Plex qatori';
	@override String get heroNeedsLibrary => 'Avval “Kutubxona” bandini belgilang — asosiy banner ko‘rsatiladigan joy kerak';
	@override String get heroNeedsSurface => 'Birincisi Library o Home ko‘shayt — Hero\'s need somewhere to show';
	@override String get removeHub => 'Hub qiziziz';
	@override String get noPlexRows => 'No Plex-manadi ruzlar bu librariyaya qaytardi.';
	@override String get openDetails => 'Detaylar';
	@override String get heroCards => 'Karta qiziziz';
	@override String get tapHeroCard => 'Bir kahraman kartta bo‘yadi';
	@override String get tvPlayFocus => 'TV remote: Play button qiziziziz';
	@override String get tvPlayFocusDescription => 'D-pad down bo\'t Play button\'da bo\'t ko\'t ko. Ko\'t ko`t ko\'n ko\'t.';
	@override String get tvWrap => 'TV remote: Loop hero kartlar';
	@override String get tvWrapDescription => 'Son kartta qaytadi. son kartta boʻshadi. son karta boʻshad. son karttanda boʻshada boʻshud.';
	@override String get castOnHero => 'Bananlarda yuxirga';
	@override String get castOnHeroDescription => 'Bir kahraman banner\'dan debt-da yuxay. Off o‘zayni titni və bilan.';
	@override String get customRows => 'Custom qiziziz';
	@override String get loading => 'Home Loading Loading Load...';
	@override String get noCustomRows => 'U‘zari ko‘zari yok';
	@override String get addRowHint => 'U\'zadi\'ni birini yaratmaq üçün Home Row\'ni qo‘zadi.';
	@override String get addHomeRow => 'Home Riyadh';
	@override String get addHomeRowDescription => 'Bir kategoriyiz seçin; Yeni seri automatik olarak Organizator\'a qo‘zilgan.';
	@override String get removeRow => 'Riyadhdan';
	@override String get recentlyAdded => 'Yaqinda qoʻshilganlar';
	@override String get recentlyReleased => 'Songa bilan bilan bilan';
	@override String get movieCollections => 'Film Koleksiya';
	@override String get showCollections => 'Koleksiya ko‘z';
	@override String get rowTitle => 'Tadiq Tadiq';
	@override String get content => 'Tadiq';
	@override String get showThisRowIn => 'Bu yadi\'ni yadi:';
	@override String get libraryRecommended => 'Librariyadi bilan';
	@override String get heroCard => 'Karta bo‘z';
	@override String get heroCardDescription => 'Bir kartta bir kartta bir poster shelf ko‘zadi.';
	@override String get heroUnavailableDescription => 'Bu seri bir koleksiyonin real titlarlarga qotʻlarda qotʻlanga qotujayda qotujiyada qotujaya qotujin qotujan qotuj.';
	@override String get librariesSelection => 'Librarlar (tashqqqqtqqt qtqqqta qtqtqt qtaqtqtaqt qqtqtsqtql qtqts qtqlqtqdqlqqttql)';
	@override String get librariesMergedDescription => 'Her librariyiz burada kontrolda bu bir sıraya birimdir.';
	@override String get movieCollectionsSelection => 'Film koleksiyonlar (tashqiziziziz bütün seçkin librariyalar)';
	@override String get showCollectionsSelection => 'Koleksiylar (tashqiziziziz o‘tashqitiziziz)';
	@override String get collectionRowsDescription => 'Siz o‘zari bir koleksiyonga ma\'zari, o‘zori titlarlarlar doğrudan bir sıraya bo‘zari. e‘zari ma\'zadi, o‘zi koleksiyonda bir poster olarak bo‘zadi — o‘zadi o‘zaki o‘zeki o‘zani o‘zoni o‘zagi.';
	@override String get allCollections => 'Koleksiya';
	@override String get noRowsHere => 'Bu qotlar ko‘zadi.';
	@override String get hideWatchedRows => 'U\'qizga o\'qizganlar qizga o‘qizga';
	@override String get hideWatchedRowsDescription => 'Full-tolled titles go\'t Home and library Recommended riys. In-progress ones stay.';
	@override String get untitledCollection => 'Koleksiya bilan';
	@override String get moveRowHint => 'Up/Down: xifida · Seçin: xifoda · Back: xifot';
	@override String get organizeRowsHint => 'Seçim (o hallar) Seçim: ta\'yadi · Sa\'yadi/sa\'yadi: riyadi seçim · Riyadi: ta\'ya qaytadi';
	@override String get layoutNavDescription => 'Siz, librarlar, kategoriyalar seçin';
	@override String get editHomeRow => 'Edit Home Row';
	@override String get resetHeroButton => 'Asosiy banner tartibini Plezy standartiga qaytarish';
	@override String get reorderingUnlocked => 'Yenni qaytadi';
	@override String get reorderingLocked => 'Tadiqlar kiladi';
	@override String get rowsCanBeDragged => 'Tadiqlar qurtlar qurtlanga — bu qurtlardan qurtlanmdan qurtlar.';
	@override String get tapLockToDrag => 'Tadiqlar qotlarga qaytlarga qaytarga';
	@override String customRowLabel({required Object title}) => 'U‘ziz: ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => 'Yashirish';
	@override String get remove => 'Oʻchirish';
	@override String get libraryResumeRow => 'Ushbu kutubxonaning tomoshani davom ettirish qatori';
	@override String get pressAgainToDelete => 'Yenni xifida qaytadi.';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => 'On';
	@override String get resetHeroButtonDescription => 'Herroni ayatlar bo\'yadi, yandan yandan yadan yandan yandadi yandan yanda yandan yanan yandan yalan yandan yansat.';
}

// Path: platform
class _Translations$platform$uz extends Translations$platform$en {
	_Translations$platform$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'PlezyNG sizga lokal network sizga media serveri və playback cihazlara bağlanır.';
	@override String get locationPermission => 'Mahalliy tarmoqni aniqlash va media serverlaringizga ulanish uchun iOS talab qilganida, PlezyNG joylashuv ma’lumotlaridan foydalanish ruxsatidan foydalanadi.';
	@override String get photoLibraryPermission => 'Media muqovasi sifatida ishlatish uchun foto kutubxonangizdan rasmlarni tanlang.';
	@override String get cameraPermission => 'Companion Remote pultini ulash uchun QR kodlarini skanerlang.';
}

// Path: fileSources
class _Translations$fileSources$uz extends Translations$fileSources$en {
	_Translations$fileSources$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Fillar və kitablar';
	@override String get subtitle => 'O‘z fayllaringizni o‘qing, tinglang va tomosha qiling.';
	@override String get add => 'Kaynaklar';
	@override String get importFiles => 'Fildiya';
	@override String get localFiles => 'Bu cihazda';
	@override String get source => 'Kaynak';
	@override String get name => 'Namo';
	@override String get endpoint => 'Server URL-i';
	@override String get root => 'Bir prefix o prefix';
	@override String get username => 'Foydalanuvchi nomi';
	@override String get password => 'Parol';
	@override String get token => 'API token';
	@override String get accessKey => 'Key ID qozga';
	@override String get secretKey => 'Key qapashat';
	@override String get sessionToken => 'Session token (iziziz)';
	@override String get region => 'Region';
	@override String get clientId => 'OAuth Client ID';
	@override String get clientSecret => 'OAuth client secret (so‘z Google desktop)';
	@override String get allowHttp => 'Ishonchli tarmoqda shifrlanmagan HTTP ulanishiga ruxsat berish';
	@override String get connect => 'Ulanish';
	@override String get cancel => 'Bekor qilish';
	@override String get save => 'Saqlash';
	@override String get close => 'Yopish';
	@override String get removeSource => 'Kaynaklar qurtlan';
	@override String get disconnectMessage => 'Ushbu manba ulanishi uzilsinmi? Yuklab olingan fayllar, o‘qish va tinglash tarixi ushbu qurilmada saqlanib qoladi.';
	@override String get localFolder => 'Fildi seçti';
	@override String get empty => 'Hali bu yerda hech narsa yoʻq';
	@override String get emptyHint => 'Bir kayndan qo‘yadi o‘yadi bir kitab, audiobok, musiqi, o‘video.';
	@override String get search => 'Bu folderga qaytadi';
	@override String get searchCached => 'Librariyizga saladi';
	@override String get refresh => 'Yangilash';
	@override String get loadMore => 'Yatadi';
	@override String get offline => 'Offline qozga';
	@override String get download => 'Offline ko‘z';
	@override String get removeDownload => 'Offline kopyadi';
	@override String get continueReading => 'Okumaya devam';
	@override String get continueListening => 'Tadiqga qulaq';
	@override String get continueWatching => 'U‘qizga';
	@override String get read => 'Okumada';
	@override String get listen => 'Tadiq';
	@override String get play => 'Ijro etish';
	@override String get pause => 'Pauza';
	@override String get stop => 'Toʻxtatish';
	@override String get startOver => 'Yatlarga';
	@override String get finished => 'Tugadi';
	@override String get markFinished => 'Marqdan bo‘qadi';
	@override String get markUnfinished => 'Marqimizni';
	@override String get editions => 'Edicionlar və fillar';
	@override String get chapters => 'Boʻlimlar';
	@override String get bookmarks => 'Bookmarklar və notlar';
	@override String get bookmark => 'Bookmark ko‘z';
	@override String get highlight => 'Yiyiyiyiy';
	@override String get note => 'Tadiq';
	@override String get delete => 'Oʻchirish';
	@override String get export => 'Eksportlar bilan';
	@override String get exported => 'U‘zadiqlar';
	@override String get sync => 'Sinklik progres';
	@override String get synced => 'Tadiqlar synthesiz';
	@override String get conflict => 'Bir yandan bir sistemdi, bir yandan bir yandan, bir yanda seçin.';
	@override String get useLocal => 'Bu qurilmadan foydalanish';
	@override String get useRemote => 'Boshqa qurilmadan foydalanish';
	@override String get history => 'Tarih';
	@override String get groupAudio => 'Bir audio-book kimi o‘zadi.';
	@override String get groupHint => 'Bu folderda ko‘zadi\'ni ko‘zad. All pages first.';
	@override String get order => 'File bilan';
	@override String get moveUp => 'Tadiqga';
	@override String get moveDown => 'Tadiqni';
	@override String get speed => 'Playback xiyim';
	@override String get sleep => 'Uyqu taymeri';
	@override String get sleepOff => 'Oʻchirilgan';
	@override String get endChapter => 'Kapitalni bilan';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} daqiqa',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} daqiqa',
	);
	@override String get skipBack => 'Tadiq qaytadi';
	@override String get skipForward => 'Tadiqadi';
	@override String get smartRewind => 'U\'qimni qaytarga bir pauzdan sonra';
	@override String get playbackOptions => 'O’qizim seçenekler';
	@override String remaining({required Object time}) => '${time} bilan bilan bilan';
	@override String get contents => 'Konteyn';
	@override String get readerSettings => 'Okumadi ayatlar';
	@override String get fontSize => 'Text Size';
	@override String get lineHeight => 'Satrlar oralig‘i';
	@override String get margin => 'Margini';
	@override String get font => 'Tifon';
	@override String get serif => 'Serifli';
	@override String get sans => 'Serifiyadi';
	@override String get mono => 'Monomadi';
	@override String get columns => 'Kolumni';
	@override String get scroll => 'Vertikalga qaytadi';
	@override String get justify => 'Tekstilni';
	@override String get readerTheme => 'Page görünüş';
	@override String get appTheme => 'App tema‘ga qaytadi';
	@override String get paper => 'Qogʻoz';
	@override String get sepia => 'Sepiya';
	@override String get night => 'Nash';
	@override String get readAloud => 'Bu sahifani ovoz chiqarib o‘qish';
	@override String get readAlong => 'Okumadi';
	@override String get stopReading => 'Ovoz chiqarib o‘qishni to‘xtatish';
	@override String get searchBook => 'Bookda検索';
	@override String get noMatches => 'U\'qizmi';
	@override String get previousPage => 'Oldingi sahifa';
	@override String get nextPage => 'Keyingi sahifa';
	@override String page({required Object number}) => '${number}-sahifa';
	@override String get externalBlocked => 'O‘qish dasturida kitoblarning tashqi havolalari o‘chirilgan.';
	@override String get loading => 'O’q...';
	@override String get narrator => 'Tadiq';
	@override String get audio => 'Ovoz';
	@override String get video => 'Video';
	@override String get ebooks => 'Ebook';
	@override String get all => 'Barchasi';
	@override String get downloads => 'Offline bilan';
	@override String get confirmDelete => 'Tanlangan oflayn nusxa o‘chirilsinmi? O‘qish yoki tinglash joyi va qaydlaringiz saqlanib qoladi.';
	@override String get errorAuthentication => 'Bu kaynadi qaytarga qaytarga.';
	@override String get errorPermission => 'Bu manba so‘ralgan faylga kirishga ruxsat bermadi.';
	@override String get errorUnavailable => 'Bu kaynadi yetim. Yenni xifida koʻtadi, ya\'yadi offline kopiy.';
	@override String get errorUnsupported => 'Bu format ya ko‘zlar bu cihazda supportasiz. kaynaqlar ko‘zalar guadi.';
	@override String get errorInvalidData => 'Bu fayl yoki server javobini xavfsiz o‘qib bo‘lmadi.';
	@override String get errorCancelled => 'Amal bekor qilindi.';
	@override String get errorConflict => 'Possiya bir seansda qaytadi. bir pozsiya seçibim üçün elementni qaytadi!';
	@override String get signIn => 'Kirish';
	@override String get reconnect => 'Qayta ulanish';
	@override String get folderHelp => 'U\'qotni koʻtadi. URL\'lar S3 buqotni.';
	@override String get preferences => 'Preferans';
	@override String get timePosition => 'Joylashuvi';
	@override String get audioTrack => 'Audio Trag';
	@override String get subtitleTrack => 'Subtitle Tadiq';
	@override String get none => 'U‘yadi';
	@override String get fullscreen => 'Ekran';
	@override String get syncLocation => 'Progress sync folder (iziziz)';
	@override String get syncLocationHint => 'PlezyNG holati uchun alohida WebDAV jildi. Shartli yozishdan foydalaniladi; mediafayllar o‘zgarmaydi.';
	@override String get audiobooks => 'Audiobotlar';
	@override String get comics => 'Komik';
	@override String get scan => 'Scanlar kitablar və mediyalar';
	@override String get browserReader => 'Open lugadi';
	@override String get browserReaderHelp => 'O‘qish oynasi brauzeringizda ochiq. O‘qish joyi va qaydlaringiz saqlanishi uchun PlezyNG’ni ochiq qoldiring.';
	@override String get on => 'Yoqilgan';
	@override String get advancedSetup => 'App Registration';
	@override String get microsoftSignIn => 'Microsoftga abonni.';
	@override String get zoomIn => 'Zoomga';
	@override String get zoomOut => 'Zoomga';
	@override String get fitPage => 'Pageqiz';
	@override String get fitWidth => 'Uqqqqga';
	@override String get actualSize => 'Tariflik';
	@override String get goToPage => 'Pagega qaytadi';
	@override String get goToSection => 'Kapitalga qaytadi';
	@override String pageRange({required Object count}) => '1dan ${count}\'ni bir numir girdi.';
	@override String get pageLayout => 'Page Layout';
	@override String get automatic => 'Avtomatik';
	@override String get singlePage => 'Bir sayat';
	@override String get twoPages => '2 sayat';
	@override String get readingDirection => 'Okumadi qaytadi';
	@override String get leftToRight => 'Chapdan o‘ngga';
	@override String get rightToLeft => 'O‘ngdan chapga';
	@override String get letterSpacing => 'Tadiqadiqadi';
	@override String get wordSpacing => 'U‘zizga';
	@override String get readerControlsHelp => 'Sahifani kattalashtirish uchun ikki barmog‘ingizni bir-biridan uzoqlashtiring yoki masshtab tugmalaridan foydalaning. Sahifani siljitish uchun sudrang. Ctrl/⌘ va + yoki − masshtabni o‘zgartiradi; Ctrl/⌘ va 0 uni tiklaydi. Page Up va Page Down sahifalarni almashtiradi.';
	@override String get imagePage => 'Komik sayadi';
	@override String get resetReader => 'Okumadi preferanslar';
	@override String get zoom => 'Masshtab';
	@override String get useFiles => 'Fillar və kitablar kullanır.';
	@override String get cancelScan => 'Sankcion';
	@override String get googleDrive => 'Google Drive';
}

// Path: lending
class _Translations$lending$uz extends Translations$lending$en {
	_Translations$lending$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Public librarlar';
	@override String get add => 'Bir kütüphan qo‘yadi';
	@override String get other => 'Bir librariyada';
	@override String get libraryName => 'Librari adı';
	@override String get libraryUrl => 'Webbiliya';
	@override String get libraryUrlHint => 'Siz librariyiznin katalogi ya‘y‘y‘ya‘y‘yo‘y‘ay.';
	@override String get intro => 'Kütüphanizdan borga.Bibrarizdan qurt.';
	@override String get handoff => 'Kutubxonangizning o‘z xizmati orqali hisobingizga kiring, kitoblarni vaqtincha oling va xavfsiz o‘qing.';
	@override String get openService => 'Librariq';
	@override String get findLibrary => 'Bir kütüphan bulga';
	@override String get search => 'Kitablar ve yazarlar aradi';
	@override String get catalogue => 'Katalog';
	@override String get loans => 'Loan';
	@override String get holds => 'Band qilingan kitoblar';
	@override String get signIn => 'Siz librariyizga qaytadi.';
	@override String get waiting => 'Siz browserga abonni bilan bilan, qaytdan qaytdan.';
	@override String get cancel => 'Bekor qilish';
	@override String get disconnect => 'Librariya bilan';
	@override String get disconnectMessage => 'Bu kutubxona shu profildan olib tashlansinmi? Vaqtincha olgan va band qilgan kitoblaringiz kutubxona hisobingizda saqlanadi.';
	@override String get getBook => 'Bookga bo‘yadi';
	@override String get checkAvailability => 'Tadiqlar bilan bilan bilan';
	@override String get available => 'U\'ziyadi borga';
	@override String get unavailable => 'Şu anda yetimlik';
	@override String get borrow => 'Vaqtincha olish';
	@override String get placeHold => 'Band qilish';
	@override String get returnBook => 'Tadi qaytar';
	@override String get cancelHold => 'Band qilishni bekor qilish';
	@override String get confirmBorrow => 'Bu titili librarizdan borga?';
	@override String get confirmReturn => 'Bu kitobni hozir qaytarasizmi? Davom etish uchun uni yana olishingiz kerak bo‘lishi mumkin.';
	@override String get confirmCancelHold => 'Bu kitobni band qilishni bekor qilasizmi?';
	@override String get email => 'Kitobni band qilish haqidagi bildirishnomalar uchun elektron pochta';
	@override String due({required Object date}) => 'Qaytarish muddati: ${date}';
	@override String queue({required Object position}) => 'Possiya ${position} linni.';
	@override String get empty => 'Yiyiyiyiy o‘zlar.';
	@override String get openLibraryNote => 'Open Library\'nin katalogi va\'qlar. Read and borrilik seçenekler hər bir titilinin sayadi.';
	@override String get more => 'Yatadi';
	@override String get gateway => 'Librariyadi-sign-in servis';
	@override String get gatewayHint => 'Siz librariyiz o‘yibib o‘yiba PlezyNG administrator.';
	@override String get advanced => 'Librariya integrasyon';
	@override String get loadLibraries => 'Librari sizni seçin';
	@override String get expired => 'Bu borga bilan bilan bo‘zadi.';
	@override String get updated => 'Librari bilan günahlar';
	@override String get continueService => 'U‘ziyadi';
	@override String get comingSoon => 'U-app borga · Biraz qaytarga';
	@override String get comingSoonDescription => 'Libby integration is on its way. Siz Libby librariyizni sizni kullanabiliz, biz onu bağlayganni bilan.';
	@override String get suspendHold => 'Tadiqadiqadi';
	@override String get resumeHold => 'Tadiqadiqadi';
	@override String get suspendMessage => 'Navbatdagi o‘rningizni saqlab, keyingi o‘quvchiga bu nusxani olishga ruxsat berasizmi? Band qilishni keyin davom ettirishingiz mumkin.';
	@override String get resumeMessage => 'Kutubxona keyingi bo‘sh nusxani sizga taklif qilishi uchun bu band qilishni davom ettirasizmi?';
	@override String get editEmail => 'Email Notifikacion';
}

// Path: audiobook
class _Translations$audiobook$uz extends Translations$audiobook$en {
	_Translations$audiobook$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get syncTitle => 'Okum & dining sync';
	@override String get syncHelp => 'Okuma pozsiya, okuma pozisyonlar, completion status, bookmarks, notlar siz cihazlarınızda. Added stockage account seçin ve hər cihazda aynı sinq kod kullanın. Okuma və dinim ayaladi.';
	@override String get addSyncSource => 'Google Drive, OneDrive, Dropbox, WebDAV o S3\'i fillar və kitablar qoladi.';
	@override String get syncDestination => 'Sync bilan bilan bilan';
	@override String get syncFolder => 'Filmi ya prefix.';
	@override String get syncFolderHelp => 'WebDAV kaynağınızda, ya da dedikadi S3 prefix\'i bir separat bilan folder kullan. Book files is never changed.';
	@override String get syncCode => 'Sink kodlar';
	@override String get syncCodeHelp => 'Bir kod o‘ziz, sonra o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘z.';
	@override String get showCode => 'Sink-kodni koʻyadi koʻyadi.';
	@override String get newSyncCode => 'Yeni bir sinq-kodi yaratlar.';
	@override String get saveSync => 'Save and synq.';
	@override String get disableSync => 'Bu cihazda synchroniziziziziziz.';
	@override String get syncSourceDisconnect => 'Bu kayndan qaytdan o‘yadi o‘yadi o‘yadi o‘yadi o‘yadi o‘yadi o‘yadi o‘yadi o‘yadi.';
	@override String get syncReconnect => 'Hesab bilan bilan bilan bilan bilan bilan';
	@override String lastSynced({required Object time}) => '${time}\'da sonda sinqizdi';
	@override String get syncPrivacy => 'Biz xifriyo bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan.';
	@override String get syncConflicts => 'Onda qaytarga qaytarga.';
	@override String get conflictHelp => 'Bu modifikasyonlar bağımsızdan ko‘zadi. ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi';
	@override String syncDevice({required Object device}) => '${device}';
	@override String get syncUnknownDevice => 'U‘zari';
	@override String get deletedBookmark => 'Bookmark bilan bilan bilan';
	@override String get finished => 'Konni';
	@override String readingPosition({required Object percent}) => '${percent} %';
	@override String get chapterTimeline => 'Kapital bilan bilan';
	@override String get bookTimeline => 'Kitab bilan progresi';
	@override String bookRemaining({required Object time}) => '${time} bu kitabda qaytadi.';
	@override String chapterRemaining({required Object time}) => 'Bu kapitalda kalan zaman: ${time}';
	@override String get unknownRemaining => 'Total time available as parts is playing. — Tull time available as parts are playing. — Tull time available as parts are playing. — Tull time available as parts are playing.';
	@override String get undoSeek => 'Songa ko‘zadi.';
	@override String get customSpeed => 'Custom playback ritmi.';
	@override String get speedHelp => 'Siz 0.25 x 4 x o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z';
	@override String get apply => 'Diggadi';
	@override String get customSleep => 'Custom uyumalar';
	@override String get sleepMinutes => '1 – 440 min)';
	@override String sleepChapters({required Object count}) => '${count} kapitallardan sonra durga';
	@override String get extendSleep => '5 dakikadi';
	@override String sleepRemaining({required Object time}) => 'U\'qiziziz: ${time}';
	@override String get useDefaults => 'Yeni kitaplar için bu dining kontrollar kullanın.';
	@override String get librarySort => 'Kitajlar';
	@override String get sortTitle => 'Tadiya';
	@override String get sortAuthor => 'Avtor';
	@override String get sortNarrator => 'Hikmatlar';
	@override String get sortSeries => 'Seriyadi';
	@override String get sortRecent => 'U‘zʻzʻzʻzʻzʻzʻzʻ';
	@override String get statusFilter => 'Okumaya status';
	@override String get statusAll => 'Bütün kitablar';
	@override String get statusNew => 'Başlamad';
	@override String get statusProgress => 'Tadiqadi';
	@override String get statusFinished => 'Konni';
	@override String get goToTime => 'O‘zadi.';
	@override String get timeHelp => 'Hours:minuts:seconds, o minutlar:seconds';
}

// Path: games
class _Translations$games$uz extends Translations$games$en {
	_Translations$games$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

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
class _Translations$appIcon$names$uz extends Translations$appIcon$names$en {
	_Translations$appIcon$names$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get midnight => 'Yarim tun';
	@override String get ember => 'Choʻgʻ';
	@override String get paper => 'Qogʻoz';
	@override String get oled => 'OLED';
	@override String get line => 'Chiziq';
	@override String get ocean => 'Okean';
	@override String get ultraviolet => 'Ultrabinafsha';
	@override String get matcha => 'Matcha';
	@override String get sunset => 'Shafaq';
	@override String get gold => 'Oltin';
	@override String get titanium => 'Titan';
	@override String get glass => 'Shisha';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => 'Synthwave';
	@override String get pixel => 'Piksel';
	@override String get neon => 'Neon';
	@override String get sticker => 'Stiker';
	@override String get ticket => 'Chipta';
	@override String get pop => 'Pop';
	@override String get strata => 'Qatlamlar';
	@override String get facet => 'Qirra';
	@override String get tilde => 'Tilda';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$uz extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

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
class _Translations$common$mediaKind$uz extends Translations$common$mediaKind$en {
	_Translations$common$mediaKind$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get movie => 'Film';
	@override String get show => 'Serial';
	@override String get season => 'Fasl';
	@override String get episode => 'Epizod';
	@override String get artist => 'Ijrochi';
	@override String get album => 'Albom';
	@override String get track => 'Trek';
	@override String get collection => 'Toʻplam';
	@override String get playlist => 'Pleylist';
	@override String get clip => 'Klip';
	@override String get photo => 'Foto';
	@override String get folder => 'Papka';
}

// Path: themeEditor.slots
class _Translations$themeEditor$slots$uz extends Translations$themeEditor$slots$en {
	_Translations$themeEditor$slots$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get bg => 'Fon';
	@override String get surface => 'Sirt';
	@override String get outline => 'Kontur';
	@override String get text => 'Matn';
	@override String get textMuted => 'Ikkilamchi matn';
	@override String get accent => 'Urgʻu rangi';
}

// Path: themeEditor.contrast
class _Translations$themeEditor$contrast$uz extends Translations$themeEditor$contrast$en {
	_Translations$themeEditor$contrast$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => 'Fondagi matn';
	@override String get textOnSurface => 'Sirtdagi matn';
	@override String get textMutedOnBg => 'Fondagi ikkilamchi matn';
	@override String get textMutedOnSurface => 'Sirtdagi ikkilamchi matn';
	@override String get accentOnBg => 'Fondagi urgʻu rangi';
	@override String get accentOnSurface => 'Sirtdagi urgʻu rangi';
	@override String get labelOnAccent => 'Urgʻu rangidagi tugma matni';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$uz extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Ijro/Pauza';
	@override String get volumeUp => 'Ovozni balandlatish';
	@override String get volumeDown => 'Ovozni pastlatish';
	@override String seekForward({required Object seconds}) => 'Oldinga oʻtkazish (${seconds}son)';
	@override String seekBackward({required Object seconds}) => 'Orqaga oʻtkazish (${seconds}son)';
	@override String get fullscreenToggle => 'Toʻliq ekranga oʻtish/chiqish';
	@override String get muteToggle => 'Ovozni oʻchirish/yoqish';
	@override String get subtitleToggle => 'Subtitrni yoqish/oʻchirish';
	@override String get audioTrackNext => 'Keyingi audio yoʻlak';
	@override String get subtitleTrackNext => 'Keyingi subtitr yoʻlagi';
	@override String get chapterNext => 'Keyingi boʻlim';
	@override String get chapterPrevious => 'Oldingi boʻlim';
	@override String get episodeNext => 'Keyingi qism';
	@override String get episodePrevious => 'Oldingi qism';
	@override String get speedIncrease => 'Tezlikni oshirish';
	@override String get speedDecrease => 'Tezlikni kamaytirish';
	@override String get speedReset => 'Tezlikni qayta oʻrnatish';
	@override String get zoomIn => 'Yaqinlashtirish';
	@override String get zoomOut => 'Uzoqlashtirish';
	@override String get zoomReset => 'Masshtabni qayta oʻrnatish';
	@override String get subSeekNext => 'Keyingi subtitrga oʻtish';
	@override String get subSeekPrev => 'Oldingi subtitrga oʻtish';
	@override String get subtitleDelayIncrease => 'Subtitrni kechiktirish';
	@override String get subtitleDelayDecrease => 'Subtitrni oldinga surish';
	@override String get shaderToggle => 'Sheyderlarni yoqish/oʻchirish';
	@override String get skipMarker => 'Intro/Titrlarni oʻtkazib yuborish';
	@override String get screenshot => 'Ekran tasvirini olish';
	@override String get framePrevious => 'Previous Ramiq';
	@override String get frameNext => 'Next Ramiq';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$uz extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Android 8.0 yoki undan yangisi talab qilinadi';
	@override String get iosVersion => 'iOS 15.0 yoki undan yangisi talab qilinadi';
	@override String get permissionDisabled => 'PiP rejimi oʻchirilgan. Tizim sozlamalaridan yoqing.';
	@override String get notSupported => 'Qurilma PiP rejimini qoʻllab-quvvatlamaydi';
	@override String get voSwitchFailed => 'PiP uchun video chiqishini almashtirib boʻlmadi';
	@override String get failed => 'PiP rejimini ishga tushirishda xatolik';
	@override String get prepareFailed => 'PiP rejimini tayyorlab boʻlmadi';
	@override String unknown({required Object error}) => 'Xatolik yuz berdi: ${error}';
}

// Path: accountPreferences.groups
class _Translations$accountPreferences$groups$uz extends Translations$accountPreferences$groups$en {
	_Translations$accountPreferences$groups$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => 'Audio va subtitrlar';
	@override String get libraryDisplay => 'Kutubxona';
	@override String get personalMedia => 'Shaxsiy media';
}

// Path: accountPreferences.subtitleModes
class _Translations$accountPreferences$subtitleModes$uz extends Translations$accountPreferences$subtitleModes$en {
	_Translations$accountPreferences$subtitleModes$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get none => 'Qoʻlda tanlangan';
	@override String get noneDescription => 'Subtitrni hech qachon oʻzi yoqmaydi.';
	@override String get defaultMode => 'Trek bayroqlariga amal qilish';
	@override String get defaultModeDescription => 'Har bir subtitr trekida saqlangan standart va majburiy bayroqlardan foydalanish.';
	@override String get always => 'Har doim yoqilgan';
	@override String get alwaysDescription => 'Mavjud boʻlganda afzal koʻrilgan tildagi subtitr treki yoqiladi.';
	@override String get onlyForced => 'Faqat majburiy subtitrlar';
	@override String get onlyForcedDescription => 'Faqat majburiy deb belgilangan treklar yuklanadi.';
	@override String get smart => 'Chet el audiosi bilan koʻrsatiladi';
	@override String get smartDescription => 'Subtitr faqat audio boshqa tilda boʻlganda yoqiladi.';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class _Translations$accountPreferences$subtitleAccessibilityOptions$uz extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	_Translations$accountPreferences$subtitleAccessibilityOptions$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'SDH boʻlmagan subtitrlarga ustunlik berish';
	@override String get preferSdh => 'SDH subtitrlarga ustunlik berish';
	@override String get onlySdh => 'Faqat SDH subtitrlar';
	@override String get onlyNonSdh => 'Faqat SDH boʻlmagan subtitrlar';
}

// Path: accountPreferences.forcedSubtitleOptions
class _Translations$accountPreferences$forcedSubtitleOptions$uz extends Translations$accountPreferences$forcedSubtitleOptions$en {
	_Translations$accountPreferences$forcedSubtitleOptions$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => 'Majburiy boʻlmagan subtitrlarga ustunlik berish';
	@override String get preferForced => 'Majburiy subtitrlarga ustunlik berish';
	@override String get onlyForced => 'Faqat majburiy subtitrlar';
	@override String get onlyNonForced => 'Faqat majburiy boʻlmagan subtitrlar';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$uz extends Translations$accountPreferences$watchedIndicatorOptions$en {
	_Translations$accountPreferences$watchedIndicatorOptions$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get none => 'Hech qachon';
	@override String get moviesAndShows => 'Filmlar va seriallar';
	@override String get movies => 'Faqat filmlar';
	@override String get shows => 'Faqat seriallar';
}

// Path: accountPreferences.mediaReviewsOptions
class _Translations$accountPreferences$mediaReviewsOptions$uz extends Translations$accountPreferences$mediaReviewsOptions$en {
	_Translations$accountPreferences$mediaReviewsOptions$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'Foydalanuvchilar va tanqidchilar';
	@override String get usersOnly => 'Faqat foydalanuvchilar';
	@override String get criticsOnly => 'Faqat tanqidchilar';
	@override String get nobody => 'Yashirilgan';
}

// Path: discover.findNext
class _Translations$discover$findNext$uz extends Translations$discover$findNext$en {
	_Translations$discover$findNext$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Next sizga bulga';
	@override String get open => 'Next sizga bulga';
	@override String get anyTime => 'Her zaman';
	@override String get timeAvailable => 'Siz o‘zʻzʻzʻzʻzʻzʻ?';
	@override String get filters => 'O’qimni seçdi';
	@override String get watch => 'Tadiq';
	@override String get listen => 'Ulu';
	@override String get read => 'Okuma';
	@override String finishable({required Object duration}) => '${duration}\'da qaytadi';
	@override String aboutDuration({required Object duration}) => '${duration} qxzq qxzq';
	@override String nextUnit({required Object duration}) => 'Next post · ${duration}';
	@override String totalDuration({required Object duration}) => '${duration} total';
	@override String get timingVaries => 'Tarifimiz variadi';
	@override String get notNow => 'Şimdi ko‘z';
	@override String get swipeHint => 'Muqovani strelka tomon suring yoki quyidagi tugmalardan foydalaning.';
	@override String get saved => 'Pikaqlar bilan';
	@override String savedCount({required Object count}) => '${count}';
	@override String get undo => 'O‘z';
	@override String get details => 'Detaylar';
	@override String get noPicks => 'U‘zari ko‘zari ko‘zari.';
	@override String get noPicksHint => 'Bir kütüphan bağlayın ya da başlatmak için bir medya kaynaq qoşun.';
	@override String get noMatches => 'Bir şey bu momni ko‘yadi.';
	@override String get noMatchesHint => 'Bir formati ko‘di o‘di o‘di o‘di o‘di o‘di o‘di.';
	@override String get allDone => 'Sizga hepsi yakadi.';
	@override String get allDoneHint => 'Bu seçimler qaytarga qaytarga qaytarga qaytarga.';
	@override String get refresh => 'Bir mix ko‘yadi.';
	@override String sourceReason({required Object source}) => '${source} qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq';
	@override String libraryReason({required Object library}) => '${library} qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq';
	@override String get ownedReason => 'Bu librariyizdan';
	@override String get liveNow => 'Onda';
	@override String get watchLive => 'Live o‘zadi';
	@override String get filterAnything => 'O‘yadi';
	@override String get filterWatch => 'Tadiq';
	@override String get filterListen => 'Ulu';
	@override String get filterRead => 'Okuma';
	@override String get twentyMinutes => '20 min';
	@override String get fortyFiveMinutes => '45 min';
	@override String get ninetyMinutes => '90 min';
	@override String get apply => 'Diggadi';
	@override String get openFailed => 'Bu seçenek artık kullanılmadi. refresh ko\'t check again.';
	@override String get changeFailed => 'Bu cambiadi ko‘yadi. qaytarga ko‘yadi.';
	@override String get savedLimit => 'U\'qizga bo\'qizga bo\'qizga bo\'qizga bo\'qizga bo\'qizga bo\'qizga bo\'qizga bo\'qizga bo\'qizga bo\'qizga bo.';
	@override String get chooseHint => 'Asarni oching, keyinga saqlang yoki o‘tkazib yuboring.';
	@override String get howItWorks => 'Foydalanish tartibi';
	@override String get notNowHelp => 'Bu asarni hozircha o‘tkazib yuboring. U kutubxonangizda qoladi.';
	@override String get saveHelp => 'Uni shu qurilmadagi shu profilning saqlangan tanlovlariga qo‘shing. Saqlash kontentni yuklab olmaydi.';
	@override String get openHelp => 'Tafsilotlar uchun muqovani tanlang. Asarni ijro etish, o‘qish yoki ochish uchun asosiy tugmadan foydalaning.';
	@override String get controlsHelp => 'Klaviatura yoki pult: tugmani tanlang, so‘ng Enter yoki tanlash tugmasini bosing. Bekor qilish oxirgi tanlovingizni qaytaradi.';
	@override String get artworkLoading => 'Rasm yuklanmoqda…';
	@override String get artworkUnavailable => 'Rasm mavjud emas';
	@override String get savedFeedback => 'Saqlangan tanlovlarga qo‘shildi';
	@override String get skippedFeedback => 'Hozircha o‘tkazib yuborildi';
	@override String get releaseToConfirm => 'Tasdiqlash uchun qo‘yib yuboring';
	@override String get remoteHint => 'Muqova tanlanganda: ← / → tanlash · Tanlash tugmasi: tafsilotlar · ↑ / ↓ fokusni ko‘chirish';
}

// Path: discover.person
class _Translations$discover$person$uz extends Translations$discover$person$en {
	_Translations$discover$person$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get born => 'Tugʻilgan';
	@override String get died => 'Vafot etgan';
	@override String get birthplace => 'Tugʻilgan joyi';
	@override String dateWithAge({required Object date, required Object age}) => '${date} (${age} yosh)';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (${age} yoshda)';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$uz extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Tavsiya etilganlar';
	@override String get browse => 'Koʻrib chiqish';
	@override String get collections => 'Toʻplamlar';
	@override String get playlists => 'Ijro roʻyxatlari';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$uz extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Guruhlash';
	@override String get all => 'Barchasi';
	@override String get movies => 'Filmlar';
	@override String get shows => 'TV Shoular';
	@override String get seasons => 'Mavsumlar';
	@override String get episodes => 'Qismlar';
	@override String get artists => 'Ijrochilar';
	@override String get albums => 'Albomlar';
	@override String get tracks => 'Taronalar';
	@override String get folders => 'Jildlar';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$uz extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Janr';
	@override String get year => 'Yil';
	@override String get contentRating => 'Kontent reytingi';
	@override String get tag => 'Teg';
	@override String get unwatched => 'Koʻrilmagan';
	@override String get unplayed => 'Eshitilmagan';
	@override String get favorites => 'Tanlanganlar';
	@override String get filePath => 'Fayl yoʻli';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$uz extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Nomi';
	@override String get dateAdded => 'Qoʻshilgan sanasi';
	@override String get releaseDate => 'Chıqqan sanasi';
	@override String get rating => 'Reyting';
	@override String get communityRating => 'Hamjamiyat reytingi';
	@override String get criticRating => 'Muntaqidlar reytingi';
	@override String get userRating => 'Foydalanuvchi reytingi';
	@override String get datePlayed => 'Ijro etilgan sanasi';
	@override String get playCount => 'Ijrolar soni';
	@override String get productionYear => 'Ishlab chiqarilgan yili';
	@override String get runtime => 'Davomiyligi';
	@override String get officialRating => 'Rasmiy reyting';
	@override String get premiereDate => 'Premyera sanasi';
	@override String get startDate => 'Boshlangan sanasi';
	@override String get airTime => 'Efir vaqti';
	@override String get studio => 'Studiya';
	@override String get random => 'Tasodifiy';
	@override String get dateShared => 'Ulashilgan sanasi';
	@override String get latestEpisodeAirDate => 'Soʻnggi qism chiqqan sana';
	@override String get lastEpisodeDateAdded => 'Soʻnggi qoʻshilgan qism sanasi';
	@override String get dateDownloaded => 'Yuklab olingan sanasi';
	@override String get size => 'Hajmi';
	@override String get library => 'Kutubxona';
}

// Path: libraries.advancedFilters
class _Translations$libraries$advancedFilters$uz extends Translations$libraries$advancedFilters$en {
	_Translations$libraries$advancedFilters$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get include => 'Kiritish';
	@override String get exclude => 'Istisno qilish';
	@override String get any => 'Istalgan';
	@override String get yes => 'Ha';
	@override String get no => 'Yoʻq';
	@override String not({required Object value}) => '${value} emas';
	@override String valueCount({required Object count}) => '${count} ta tanlangan';
	@override String valueCountExcluded({required Object count}) => '${count} ta istisno qilingan';
	@override String get searchValues => 'Qiymatlarni qidirish';
	@override String get noValues => 'Qiymatlar yoʻq';
	@override String get matchContains => 'Oʻz ichiga oladi';
	@override String get matchNotContains => 'Oʻz ichiga olmaydi';
	@override String get matchIs => 'Teng';
	@override String get matchIsNot => 'Teng emas';
	@override String get matchBeginsWith => '… bilan boshlanadi';
	@override String get matchEndsWith => '… bilan tugaydi';
	@override String get textHint => 'Mos keladigan matnni kiriting';
	@override String get from => 'Dan';
	@override String get to => 'Gacha';
	@override String range({required Object from, required Object to}) => '${from} – ${to}';
	@override String atLeast({required Object value}) => '${value} va undan yuqori';
	@override String atMost({required Object value}) => '${value} gacha';
	@override String dateLastDays({required Object count}) => 'Soʻnggi ${count} kun';
	@override String get dateLastYear => 'Soʻnggi bir yil';
	@override String dateOlderThanDays({required Object count}) => '${count} kundan eski';
	@override String get dateOlderThanYear => 'Bir yildan eski';
}

// Path: libraries.selection
class _Translations$libraries$selection$uz extends Translations$libraries$selection$en {
	_Translations$libraries$selection$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get selectItems => 'Tadiqadiqadi';
	@override String selectedCount({required Object count}) => '${count} ta tanlangan';
	@override String get actions => 'Seçim aktivatlar';
	@override String get confirmDescendants => 'Bu, seçkin show-da və sezonlarda bütün epizodlar ko‘zadi.';
	@override String get confirmUnwatched => 'Bu tanlangan elementlarning ijro jarayoni haqidagi ma’lumotlarni ham tozalaydi.';
	@override String confirmCount({required Object count}) => 'U‘zizdan qiziziz: ${count}.';
	@override String completed({required Object count}) => 'Yangilangan elementlar: ${count}.';
	@override String partialFailure({required Object succeeded, required Object failed}) => 'Updated ${succeeded}; faqizdi ${failed}. Faqizdi items qurtlar.';
}

// Path: explore.mdblistShelves
class _Translations$explore$mdblistShelves$uz extends Translations$explore$mdblistShelves$en {
	_Translations$explore$mdblistShelves$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get manage => '“Kashf qilish” bo‘limidagi javonlarni boshqarish';
	@override String get manageDescription => 'Siz MDBList hesabinizdan listlar seçin və düzəlin';
	@override String get description => 'MDBList hisobingizdagi ochiq film va serial ro‘yxatlarini tanlang. MDBList’da ro‘yxat yarating yoki nusxalang, so‘ng yangilang.';
	@override String get selected => 'Seçkin qiyizlar';
	@override String get available => 'Hesablar listlar';
	@override String get noLists => 'Ochiq film yoki serial ro‘yxatlari topilmadi. MDBList’da ro‘yxat yarating yoki nusxalang, so‘ng yangilang.';
	@override String get displayName => 'Shelf Display Nominadi';
	@override String get nameHint => 'U\'zayda kaynlar listni ismi kullanmaqdan qurt.';
	@override String get add => 'Shell ko‘z';
	@override String get save => 'Tadiqlarga saladi';
	@override String moveUp({required Object title}) => '${title}ni yuqoriga ko‘chirish';
	@override String moveDown({required Object title}) => '${title} qaytadi';
	@override String get unavailable => 'Bu list ishat. Bu listini qaytadi o\'zingiz.';
	@override String get rateLimited => 'MDBList ismi limiti qadi. lüthi qaytarga.';
	@override String get loadFailed => 'U\'zlar ko‘zlar. Sizga qaytarga ko‘z.';
	@override String get saveFailed => 'U\'zlarga qaytadi. lütfen qaytadi!';
	@override String get accountChanged => 'Hisob yoki profil o‘zgardi. Bu sozlamalarni qayta oching.';
	@override String get settingsUnreadable => 'U\'zizlar bo\'zlar bo\'qlar. Bu ayarlar yasanlar yasan.';
}

// Path: explore.rows
class _Translations$explore$rows$uz extends Translations$explore$rows$en {
	_Translations$explore$rows$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'Tomosha roʻyxati';
	@override String get recommendedMovies => 'Tavsiya etilgan filmlar';
	@override String get recommendedShows => 'Tavsiya etilgan seriallar';
	@override String get trendingMovies => 'Ommabop filmlar';
	@override String get trendingShows => 'Ommabop seriallar';
	@override String get popularMovies => 'Mashhur filmlar';
	@override String get popularShows => 'Mashhur seriallar';
	@override String get trendingAnime => 'Ommabop anime';
	@override String get suggestedAnime => 'Tavsiya etilgan anime';
	@override String get airingAnime => 'Efirga uzatilayotgan eng yaxshi anime';
	@override String get popularAnime => 'Eng mashhur anime';
	@override String get trending => 'Ommaboplar';
	@override String get upcomingMovies => 'Kutilayotgan filmlar';
	@override String get upcomingShows => 'Kutilayotgan seriallar';
}

// Path: explore.status
class _Translations$explore$status$uz extends Translations$explore$status$en {
	_Translations$explore$status$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get airing => 'Efirda';
	@override String get ended => 'Tugallandi';
	@override String get canceled => 'Bekor qilindi';
	@override String get upcoming => 'Kutilmoqda';
}

// Path: explore.badge
class _Translations$explore$badge$uz extends Translations$explore$badge$en {
	_Translations$explore$badge$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} mashhur';
	@override String rankAiring({required Object n}) => '#${n} efirda';
	@override String rankRated({required Object n}) => '#${n} baholangan';
	@override String rankTrending({required Object n}) => '#${n} ommabop';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} ${season} mavsumida';
	@override String watchingNow({required Object n}) => '${n} kishi tomosha qilmoqda';
	@override String get available => 'Mavjud';
	@override String get partiallyAvailable => 'Qisman mavjud';
	@override String get availableIn4k => '4K mavjud';
	@override String get requested => 'Soʻralgan';
	@override String get pendingApproval => 'Tasdiq kutilmoqda';
	@override String get processing => 'Ishlanmoqda';
	@override String get declined => 'Rad etilgan';
	@override String get requestFailed => 'Soʻrov amalga oshmadi';
	@override String get requested4k => '4K soʻralgan';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} mavsum';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => '${episode}-qism ${duration} ichida';
	@override String nextAiringIn({required Object duration}) => 'Keyingisi ${duration} ichida';
	@override String episodesShort({required Object n}) => '${n} qism';
	@override String minutesPerEpisode({required Object n}) => '${n} daq/qism';
	@override String get adult => '18+';
}

// Path: explore.stats
class _Translations$explore$stats$uz extends Translations$explore$stats$en {
	_Translations$explore$stats$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} roʻyxatda';
	@override String viewersDay({required Object n}) => 'Bugun ${n} kishi tomosha qildi';
	@override String viewersWeek({required Object n}) => 'Bu hafta ${n} kishi tomosha qildi';
	@override String viewersMonth({required Object n}) => 'Bu oy ${n} kishi tomosha qildi';
	@override String viewersYear({required Object n}) => 'Bu yil ${n} kishi tomosha qildi';
	@override String viewersAllTime({required Object n}) => '${n} kishi tomosha qilgan';
	@override String planning({required Object n}) => '${n} kishi tomosha qilishni rejalashtirmoqda';
	@override String favorited({required Object n}) => '${n} ta tanlangan';
	@override String dropRate({required Object percent}) => '${percent} tomosha qilishni toʻxtatgan';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ta izoh',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ta izoh',
	);
	@override String votes({required Object n}) => '${n} ta ovoz';
	@override String watching({required Object n}) => '${n} kishi tomosha qilmoqda';
	@override String completed({required Object n}) => '${n} kishi yakunlagan';
	@override String onHold({required Object n}) => '${n} kishi toʻxtatib turibdi';
	@override String dropped({required Object n}) => '${n} kishi toʻxtatgan';
}

// Path: explore.season
class _Translations$explore$season$uz extends Translations$explore$season$en {
	_Translations$explore$season$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get winter => 'Qish';
	@override String get spring => 'Bahor';
	@override String get summer => 'Yoz';
	@override String get fall => 'Kuz';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class _Translations$explore$format$uz extends Translations$explore$format$en {
	_Translations$explore$format$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get tv => 'TV';
	@override String get tvShort => 'Qisqa TV';
	@override String get movie => 'Film';
	@override String get special => 'Maxsus';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => 'Musiqa';
	@override String get other => 'Boshqa';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$uz extends Translations$explore$sourceMaterial$en {
	_Translations$explore$sourceMaterial$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get original => 'Asl';
	@override String get manga => 'Manga';
	@override String get lightNovel => 'Yengil roman';
	@override String get novel => 'Roman';
	@override String get visualNovel => 'Vizual roman';
	@override String get game => 'Oʻyin';
	@override String get webComic => 'Veb-komiks';
	@override String get musicRelease => 'Musiqa';
	@override String get otherMedia => 'Boshqa';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$uz extends Translations$explore$creditRole$en {
	_Translations$explore$creditRole$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get actor => 'Aktyor';
	@override String get director => 'Rejissyor';
	@override String get writer => 'Ssenarist';
	@override String get producer => 'Prodyuser';
	@override String get creator => 'Muallif';
	@override String get composer => 'Bastakor';
}

// Path: explore.relation
class _Translations$explore$relation$uz extends Translations$explore$relation$en {
	_Translations$explore$relation$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get prequel => 'Prikvel';
	@override String get sequel => 'Sikvel';
	@override String get sideStory => 'Yon hikoya';
	@override String get spinOff => 'Spin-off';
	@override String get alternativeVersion => 'Muqobil versiya';
	@override String get summary => 'Xulosa';
	@override String get parentStory => 'Asosiy hikoya';
	@override String get adaptation => 'Adaptatsiya';
	@override String get other => 'Bogʻliq';
}

// Path: explore.detail
class _Translations$explore$detail$uz extends Translations$explore$detail$en {
	_Translations$explore$detail$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'Asl nomi';
	@override String get alsoKnownAs => 'Boshqa nomi bilan ham tanilgan';
	@override String get studios => 'Studiyalar';
	@override String get country => 'Mamlakat';
	@override String get language => 'Til';
	@override String get released => 'Chiqarilgan';
	@override String get physicalRelease => 'Diskda';
	@override String get ended => 'Yakunlangan';
	@override String addedOn({required Object date}) => '${date} da qoʻshilgan';
	@override String get yourRating => 'Sizning bahoyingiz';
	@override String get budget => 'Byudjet';
	@override String get revenue => 'Kassa yigʻimi';
	@override String get contentAdvisory => 'Yosh cheklovi';
	@override String get tags => 'Teglar';
	@override String get revealSpoilerTags => 'Spoyler teglarini koʻrsatish';
	@override String get links => 'Havolalar';
	@override String get watchOn => 'Tomosha qilish';
	@override String get watchTrailer => 'Treylerni koʻrish';
	@override String openOn({required Object site}) => '${site} da ochish';
	@override String get crew => 'Jamoa';
	@override String get ratings => 'Baholar';
	@override String get schedule => 'Jadval';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} foydalanuvchi tavsiya qilgan',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} foydalanuvchi tavsiya qilgan',
	);
	@override String recommendedBy({required Object who}) => '${who} tavsiya qilgan';
	@override String favoritedBy({required Object who}) => '${who} tanlanganlarga qoʻshgan';
	@override String unairedEpisodes({required Object n}) => '${n} hali efirga chiqmagan';
	@override String recommendedByPercent({required Object percent}) => 'Tomoshabinlarning ${percent} tavsiya qilgan';
	@override String get relatedTitles => 'Bogʻliq nomlar';
	@override String get background => 'Orqa fon';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$uz extends Translations$liveTv$recordSettings$en {
	_Translations$liveTv$recordSettings$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get startEarly => 'Erta boshlash (soniya)';
	@override String get endLate => 'Kech tugatish (soniya)';
	@override String get newOnly => 'Faqat yangi epizodlar';
	@override String get anyChannel => 'Istalgan kanaldan yozib olish';
	@override String get anyTime => 'Istalgan vaqtda yozib olish';
	@override String get skipInLibrary => 'Kutubxonada mavjud epizodlarni oʻtkazib yuborish';
	@override String get keepUpTo => 'Saqlanadigan epizodlar';
	@override String get keepUpToHint => '0 barcha epizodlarni saqlaydi';
}

// Path: music.discography
class _Translations$music$discography$uz extends Translations$music$discography$en {
	_Translations$music$discography$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'Singllar va EP';
	@override String get live => 'Jonli';
	@override String get compilations => 'Toʻplamlar';
}

// Path: watchTogether.notices
class _Translations$watchTogether$notices$uz extends Translations$watchTogether$notices$en {
	_Translations$watchTogether$notices$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name} ijro tugmasini bosdi';
	@override String get playbackStarted => 'Ijro boshlandi';
	@override String paused({required Object name}) => '${name} toʻxtatdi';
	@override String get playbackPaused => 'Ijro pauza qilindi';
	@override String jumpedTo({required Object name, required Object position}) => '${name} ${position} ga oʻtdi';
	@override String roomJumpedTo({required Object position}) => '${position} ga oʻtildi';
	@override String changedSpeed({required Object name, required Object speed}) => '${name} tezlikni ${speed} ga oʻrnatdi';
	@override String speedChanged({required Object speed}) => 'Tezlik ${speed} ga oʻrnatildi';
	@override String startedMedia({required Object name, required Object title}) => '${name} "${title}" ijrosini boshladi';
	@override String mediaStarted({required Object title}) => 'Hozir ijro etilmoqda: ${title}';
	@override String stoppedMedia({required Object name}) => '${name} videoni toʻxtatdi';
	@override String get mediaStopped => 'Video toʻxtatildi';
	@override String waitingFor({required Object name}) => '${name} kutilmoqda...';
	@override String get waitingForSomeone => 'Kimdir yetib olishi kutilmoqda...';
	@override String get finished => 'Tugadi';
	@override String hostChangedTo({required Object name}) => '${name} endi tashkilotchi';
	@override String get youAreNowHost => 'Endi tashkilotchi sizsiz';
	@override String joined({required Object name}) => '${name} qoʻshildi';
	@override String left({required Object name}) => '${name} chiqdi';
	@override String get controlRefused => 'Ijroni faqat tashkilotchi boshqara oladi';
	@override String get searchFailed => 'Baʼzi serverlarda xona videosini qidirib boʻlmadi';
	@override String get playBlocked => 'Boshlash uchun ijro tugmasini bosing';
	@override String get shareFailed => 'Bu videoni xona bilan ulashib boʻlmadi';
	@override String get downloadNotShared => 'Server oflayn boʻlganda yuklamalar xona bilan ulashilmaydi';
	@override String get openFailed => 'Xona videosini ochib boʻlmadi';
}

// Path: watchTogether.ended
class _Translations$watchTogether$ended$uz extends Translations$watchTogether$ended$en {
	_Translations$watchTogether$ended$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get ended => 'Tashkilotchi xonani yakunladi';
	@override String get kicked => 'Siz xonadan chiqarildingiz';
	@override String get expired => 'Xona muddati tugadi';
	@override String get replaced => 'Siz bu xonaga boshqa qurilmada qoʻshildingiz';
	@override String get lost => 'Xona bilan aloqa uzildi';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$uz extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => 'Bu xona kodi emas. Kodlar 6 ta harf va raqamdan iborat boʻlib, ularda 0, 1, I, L yoki O boʻlmaydi.';
	@override String get roomNotFound => 'Bunday kodli xona yoʻq. U yakunlangan boʻlishi mumkin.';
	@override String get roomFull => 'Bu xona toʻla.';
	@override String get roomLocked => 'Tashkilotchi bu xonani qulflagan.';
	@override String get relayFull => 'Birgalikda tomosha qilish xizmati hozir band. Keyinroq qaytadan urinib koʻring.';
	@override String get unreachable => 'Birgalikda tomosha relesiga ulanib boʻlmadi. Ulanishni tekshiring.';
	@override String get rateLimited => 'Urinishlar juda koʻp. Biroz kuting va qaytadan urinib koʻring.';
	@override String get clientBlocked => 'PlezyNG-ning bu versiyasi reledan foydalana olmaydi. Ilovani yangilang.';
	@override String get forbidden => 'Buni faqat tashkilotchi qila oladi.';
	@override String get notInRoom => 'Siz xonada emassiz.';
	@override String get alreadyInRoom => 'Siz allaqachon xonadasiz.';
	@override String get resumeFailed => 'Xonaga qayta qoʻshilib boʻlmadi.';
	@override String get unsupported => 'Rele buni qoʻllab-quvvatlamaydi.';
	@override String get generic => 'Nimadir xato ketdi. Qaytadan urinib koʻring.';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$uz extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'Ilovadan chiqqaningizda yuklamalar toʻxtaydi';
	@override String get bannerDegraded => 'Fondagi yuklamalar cheklangan boʻlishi mumkin';
	@override String get bannerAction => 'Batafsil';
	@override String get sheetTitle => 'Fondagi yuklamalar bloklangan';
	@override String get sheetTitleDegraded => 'Fondagi yuklamalar cheklangan boʻlishi mumkin';
	@override String get sheetIntro => 'Android PlezyNG-ning fonda ishonchli yuklab olishiga toʻsqinlik qilmoqda.';
	@override String get sheetIntroDegraded => 'Qurilmangiz PlezyNG fonda qachon yuklay olishini cheklamoqda.';
	@override String get reasonBackgroundRestricted => 'PlezyNG-ning fondagi faoliyati cheklangan. Batareya yoki fondagi foydalanishni "Cheklanmagan" qilib belgilang.';
	@override String get reasonStandbyRestricted => 'Android PlezyNG-ni cheklangan kutish holatiga oʻtkazdi. Batareya foydalanishini "Cheklanmagan" qilib belgilang.';
	@override String get reasonDownloadChannelBlocked => 'Yuklash bildirishnomalari oʻchirilgan, shuning uchun jarayon koʻrsatkichi va boshqaruv elementlari mavjud boʻlmasligi mumkin.';
	@override String get reasonNotificationsDisabled => 'Bildirishnomalar oʻchirilgan. Android 13 va undan yangi versiyalarda uzoq davom etadigan fondagi yuklamalar uchun ular talab qilinadi.';
	@override String get reasonDataSaver => 'Trafik tejash yoqilgan, bu mobil internetda fondagi yuklamalarni bloklaydi. Wi-Fi orqali yuklamalar ishlashi kerak.';
	@override String get reasonOemUnknown => 'PlezyNG fonda boʻlganida yuklamalar bir necha marta toʻxtadi. PlezyNG-ning batareya yoki fondagi foydalanish sozlamalarini tekshiring.';
	@override String get openSettings => 'Sozlamalarni ochish';
	@override String get stillNotWorking => 'Qurilmaga oid yordam';
	@override String get stillNotWorkingDescription => 'Qurilmangiz uchun qadamlarni koʻring yoki muammo davom etsa Sozlamalar › Jurnallarni koʻrish boʻlimidan jurnal yuboring.';
	@override String get dialogTitle => 'Yuklamalar tugamasligi mumkin';
	@override String get dialogDownloadAnyway => 'Baribir yuklash';
	@override String get dialogFixFirst => 'Avval buni tuzatish';
	@override String get statusTile => 'Fondagi yuklamalar';
	@override String get statusOk => 'Fonda ishlashga ruxsat berilgan';
	@override String get statusBlocked => 'Tizim sozlamalari tomonidan bloklangan';
	@override String get statusDegraded => 'Tizim sozlamalari tomonidan cheklangan';
	@override String get statusUnknown => 'Hali tekshirilmagan';
	@override String get settingsUnavailable => 'Bu qurilmada tizim sozlamalarini ochib boʻlmadi';
	@override String get linkUnavailable => 'Bu qurilmada dontkillmyapp.com-ni ochib boʻlmadi';
}

// Path: downloads.groupings
class _Translations$downloads$groupings$uz extends Translations$downloads$groupings$en {
	_Translations$downloads$groupings$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get library => 'Kutubxona';
	@override String get collections => 'Toʻplamlar';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$uz extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Pult serveri ishga tushmoqda...';
	@override String get hostAddress => 'Xost manzili';
	@override String get connected => 'Ulandi';
	@override String get serverRunning => 'Server faol';
	@override String get serverStopped => 'Server toʻxtatildi';
	@override String get serverRunningDescription => 'Tarmoqdagi mobil qurilmalar ulanishi mumkin';
	@override String get serverStoppedDescription => 'Ulanishga ruxsat berish uchun serverni ishga tushiring';
	@override String get usePhoneToControl => 'Ushbu ilovani boshqarish uchun telefoningizdan foydalaning';
	@override String get startServer => 'Serverni ishga tushirish';
	@override String get stopServer => 'Serverni toʻxtatish';
	@override String get minimize => 'Yigʻish';
	@override String get manualAddressHint => 'Qoʻlda ulanish manzili:';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$uz extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Bir xil Plex hisobidagi PlezyNG qurilmalari bu yerda koʻrinadi';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Ulanilmoqda...';
	@override String get searchingForDevices => 'Qurilmalar qidirilmoqda...';
	@override String get noDevicesFound => 'Tarmoqda qurilmalar topilmadi';
	@override String get noDevicesHint => 'Kompyuterda PlezyNG-ni oching va bir xil Wi-Fi-ga ulaning';
	@override String get availableDevices => 'Mavjud qurilmalar';
	@override String get manualConnection => 'Qoʻlda ulanish';
	@override String get cryptoInitFailed => 'Xavfsiz ulanish xatoligi. Avval Plex-ga kiring.';
	@override String get validationHostRequired => 'Xost manzilini kiriting';
	@override String get validationHostFormat => 'Format IP:port koʻrinishida boʻlishi kerak';
	@override String get connectionTimedOut => 'Ulanish vaqti tugadi. Ikkala qurilmada ham bir xil tarmoqdan foydalaning.';
	@override String get sessionNotFound => 'Qurilma topilmadi. PlezyNG xost qurilmada ishga tushirilganiga ishonch hosil qiling.';
	@override String get authFailed => 'Autentifikatsiya xatoligi.';
	@override String failedToConnect({required Object error}) => 'Ulanib boʻlmadi: ${error}';
	@override String get codeTitle => 'Code qadi';
	@override String get codeDescription => 'Kompanion Remote\'da yasan koodingiz. qotʻlar cihazlar qotʻlan. qotōlar sistemini koruygan bir versiyon qo‘zilgan.';
	@override String get codeInvalid => '32 ismi və numaralar qotʻi xotʻi.';
	@override String get updateRequired => 'Bu iki cihazlar korni‘ni bir versiyona qaytadi, korni‘nin korni‘n.';
	@override String get hostDescription => 'Bu kod bir o‘zizga. Bu kod gizli tut. Bu profil kontrollar.';
	@override String get resetCode => 'Xifida koodlar';
	@override String get resetDescription => 'All remote\'s ko\'zlar, yeni bir kod yarat. All remote will need to pair again.';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$uz extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Pult seansidan uzilasizmi?';
	@override String get reconnecting => 'Qayta ulanilmoqda...';
	@override String attemptOf({required Object current}) => 'Urinish ${current} / 5';
	@override String get retryNow => 'Hozir qaytadan urinib koʻrish';
	@override String get tabRemote => 'Pult';
	@override String get tabPlay => 'Ijro';
	@override String get tabMore => 'Koʻproq';
	@override String get menu => 'Menyu';
	@override String get tabNavigation => 'Navigatsiya';
	@override String get tabDiscover => 'Kashf qilish';
	@override String get tabLibraries => 'Kutubxonalar';
	@override String get tabSearch => 'Qidiruv';
	@override String get tabDownloads => 'Yuklamalar';
	@override String get tabSettings => 'Sozlamalar';
	@override String get previous => 'Oldingi';
	@override String get playPause => 'Ijro/Pauza';
	@override String get next => 'Keyingi';
	@override String get seekBack => 'Orqaga oʻtkazish';
	@override String get stop => 'Toʻxtatish';
	@override String get seekForward => 'Oldinga oʻtkazish';
	@override String get volume => 'Ovoz';
	@override String get volumeDown => 'Kamaytirish';
	@override String get volumeUp => 'Oshirish';
	@override String get fullscreen => 'Toʻliq ekran';
	@override String get subtitles => 'Subtitrlar';
	@override String get audio => 'Ovoz';
	@override String get searchHint => 'Kompyuterda qidirish...';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$uz extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'Tarmoq interfeysi topilmadi';
	@override String get authenticationFailed => 'Autentifikatsiya xatoligi';
	@override String serverStartFailed({required Object error}) => 'Serverni ishga tushirishda xatolik: ${error}';
	@override String commandFailed({required Object error}) => 'Buyruqni yuborishda xatolik: ${error}';
	@override String get joinTimedOut => 'Ulanish vaqti tugadi';
	@override String get failedToConnectAnyAddress => 'Hech bir manzilga ulanib boʻlmadi';
	@override String connectionLostAfterAttempts({required Object attempts}) => '${attempts} urinishdan keyin aloqa uzildi';
	@override String get connectionLost => 'Aloqa uzildi';
}

// Path: services.names
class _Translations$services$names$uz extends Translations$services$names$en {
	_Translations$services$names$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class _Translations$services$simklReconnect$uz extends Translations$services$simklReconnect$en {
	_Translations$services$simklReconnect$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Simkl-ni qayta ulash';
	@override String get subtitle => 'Simkl bu ulanishda ishlatiladigan kirish usulini toʻxtatmoqda. Qayta ulanganda PlezyNG-ni tasdiqlash uchun simkl.com ochiladi — PlezyNG parolingizni hech qachon koʻrmaydi. Tomosha tarixingiz Simkl-da saqlanib qoladi.';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$uz extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'PlezyNG-ni ${service} xizmatida faollashtiring';
	@override String get instructions => 'QR-kodni skanerlang yoki quyidagi manzilga oʻtib, bu kodni kiriting:';
	@override String openToActivate({required Object service}) => 'Faollashtirish uchun ${service} xizmatini oching';
	@override String get copyCode => 'Faollashtirish kodini nusxalash';
	@override String get waitingForAuthorization => 'Avtorizatsiya kutilmoqda…';
	@override String get codeCopied => 'Kod nusxalandi';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$uz extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '${service} xizmatiga kiring';
	@override String get body => 'Ushbu QR kodni skanerlang yoki URL-ni oching.';
	@override String openToSignIn({required Object service}) => 'Kirish uchun ${service} xizmatini oching';
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$uz extends Translations$services$pendingAuth$en {
	_Translations$services$pendingAuth$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'Kirish URL-ini nusxalash';
	@override String get urlCopied => 'URL nusxalandi';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$uz extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Kutubxona filtri';
	@override String get subtitleAllSyncing => 'Barcha kutubxonalar sinxronlanmoqda';
	@override String get subtitleNoneSyncing => 'Hech narsa sinxronlanmaydi';
	@override String subtitleBlocked({required Object count}) => '${count} bloklandi';
	@override String subtitleAllowed({required Object count}) => '${count} ruxsat berildi';
	@override String get mode => 'Filtr rejimi';
	@override String get modeBlacklist => 'Qora roʻyxat';
	@override String get modeWhitelist => 'Oq roʻyxat';
	@override String get modeHintBlacklist => 'Quyida tanlanganlardan tashqari barcha kutubxonalarni sinxronlash.';
	@override String get modeHintWhitelist => 'Faqat quyida tanlangan kutubxonalarni sinxronlash.';
	@override String get libraries => 'Kutubxonalar';
	@override String get noLibraries => 'Kutubxonalar yoʻq';
}

/// The flat map containing all translations for locale <uz>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsUz {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'cast.chooseDevice' => 'Bir cihazda qurtlar',
			'cast.searching' => 'Tadiqlarga xiyimni xiyimlarga...',
			'cast.connectedTo' => ({required Object device}) => '${device} qizga qizga',
			'cast.device' => 'Tadiqadi',
			'cast.readyToCast' => 'Hazardga bo‘qadi',
			'cast.subtitle' => 'Subtitrlar',
			'cast.serverNotAvailable' => 'Media server qiziziz.',
			'cast.stopCasting' => 'Castingdan qurtum',
			'cast.castToDevice' => 'U\'zadiya\'da qurtlar',
			'cast.noEpisodeAvailable' => 'U\'zadi\'ni qaytadi yok.',
			'cast.startFailed' => 'U\'zizga qurtlar. serveri kontroldan qurtlar, qaytarga qurtlam.',
			'automation.noActivePlayback' => 'Video aktivni sessiya ko‘zadi.',
			'automation.profileNotFound' => 'Bu Plezy profili qothathathathatdi.',
			'notifications.newEpisodeTitle' => 'Yeni epizod',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appIcon.title' => 'Ilova belgisi',
			'appIcon.defaultIcon' => 'Standart',
			'appIcon.current' => 'Joriy belgi',
			'appIcon.locked' => 'Hayatdan qaplan qaplan',
			'appIcon.lockedHint' => '7 dayni provayni ko‘zingiz o‘zingizga PlezyNG qaytadi, alternatiyik ikonlar kullan.',
			'appIcon.changeFailed' => 'Ilova belgisini oʻzgartirib boʻlmadi',
			'appIcon.launcherHint' => 'Yangi belgi PlezyNG-dan chiqqaningizdan soʻng bosh ekranda paydo boʻladi.',
			'appIcon.tvLauncherHint' => 'Yangi banner PlezyNG-dan chiqqaningizdan soʻng paydo boʻladi. Android TV televizor qayta ishga tushirilmaguncha eskisini koʻrsatishda davom etishi mumkin.',
			'appIcon.names.midnight' => 'Yarim tun',
			'appIcon.names.ember' => 'Choʻgʻ',
			'appIcon.names.paper' => 'Qogʻoz',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => 'Chiziq',
			'appIcon.names.ocean' => 'Okean',
			'appIcon.names.ultraviolet' => 'Ultrabinafsha',
			'appIcon.names.matcha' => 'Matcha',
			'appIcon.names.sunset' => 'Shafaq',
			'appIcon.names.gold' => 'Oltin',
			'appIcon.names.titanium' => 'Titan',
			'appIcon.names.glass' => 'Shisha',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => 'Synthwave',
			'appIcon.names.pixel' => 'Piksel',
			'appIcon.names.neon' => 'Neon',
			'appIcon.names.sticker' => 'Stiker',
			'appIcon.names.ticket' => 'Chipta',
			'appIcon.names.pop' => 'Pop',
			'appIcon.names.strata' => 'Qatlamlar',
			'appIcon.names.facet' => 'Qirra',
			'appIcon.names.tilde' => 'Tilda',
			'auth.signInWithPlex' => 'Plex orqali kirish',
			'auth.showQRCode' => 'QR kodni koʻrsatish',
			'auth.authenticate' => 'Tasdiqlash',
			'auth.authenticationTimeout' => 'Tasdiqlash vaqti tugadi. Iltimos, qaytadan urinib koʻring.',
			'auth.scanQRToSignIn' => 'Kirish uchun ushbu QR kodni skanerlang',
			'auth.waitingForAuth' => 'Tasdiqlanish kutilmoqda...\nBrauzeringizdan kiring.',
			'auth.useBrowser' => 'Brauzerdan foydalanish',
			'auth.or' => 'yoki',
			'auth.connectToMediaBrowser' => ({required Object product}) => '${product}ga ulanish',
			'auth.quickConnect' => 'Tezkor ulanish',
			'auth.useQuickConnect' => 'Tezkor ulanishdan foydalanish',
			'auth.quickConnectInstructions' => 'Jellyfin-da Tezkor ulanishni oching va ushbu kodni kiriting.',
			'auth.quickConnectWaiting' => 'Tasdiq kutilmoqda…',
			'auth.quickConnectCancel' => 'Bekor qilish',
			'auth.quickConnectExpired' => 'Tezkor ulanish vaqti tugadi. Qaytadan urinib koʻring.',
			'auth.localDataRecoveryRequired' => 'PlezyNG qurilmadagi kirish ma’lumotlarini va qayta ishlanishini kutayotgan ijro ma’lumotlarini xavfsiz tiklay olmadi. Qayta kiring.',
			'auth.pinCheckRejected' => 'Plex PIN tekshiruvi rad etildi',
			'auth.connectToDirectPlex' => 'Mahalliy Plex serveriga ulanish',
			'common.cancel' => 'Bekor qilish',
			'common.save' => 'Saqlash',
			'common.close' => 'Yopish',
			'common.clear' => 'Tozalash',
			'common.reset' => 'Qayta oʻrnatish',
			'common.later' => 'Keyinroq',
			'common.submit' => 'Yuborish',
			'common.confirm' => 'Tasdiqlash',
			'common.retry' => 'Qaytadan urinish',
			'common.logout' => 'Chiqish',
			'common.unknown' => 'Nomaʼlum',
			'common.refresh' => 'Yangilash',
			'common.yes' => 'Ha',
			'common.no' => 'Yoʻq',
			'common.delete' => 'Oʻchirish',
			'common.edit' => 'Tahrirlash',
			'common.shuffle' => 'Aralashtirish',
			'common.addTo' => 'Qoʻshish...',
			'common.createNew' => 'Yangi yaratish',
			'common.connect' => 'Ulanish',
			'common.disconnect' => 'Uzilish',
			'common.play' => 'Ijro etish',
			'common.pause' => 'Pauza',
			'common.resume' => 'Davom ettirish',
			'common.error' => 'Xatolik',
			'common.search' => 'Qidiruv',
			'common.home' => 'Bosh sahifa',
			'common.back' => 'Orqaga',
			'common.settings' => 'Sozlamalar',
			'common.mute' => 'Ovozni oʻchirish',
			'common.ok' => 'Tushunarli',
			'common.off' => 'Oʻchirilgan',
			'common.options' => 'Parametrlar',
			'common.seasonNumber' => ({required Object number}) => '${number}-mavsum',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => '${number}-qism - ${title}',
			'common.chapterNumber' => ({required Object number}) => '${number}-boʻlim',
			'common.reconnect' => 'Qayta ulanish',
			'common.viewAll' => 'Barchasini koʻrish',
			'common.checkingNetwork' => 'Tarmoq tekshirilmoqda...',
			'common.loadingServers' => 'Serverlar yuklanmoqda...',
			'common.connectingToServers' => 'Serverlarga ulanmoqda...',
			'common.startingOfflineMode' => 'Oflayn rejim ishga tushmoqda...',
			'common.loading' => 'Yuklanmoqda...',
			'common.fullscreen' => 'Toʻliq ekran',
			'common.exitFullscreen' => 'Toʻliq ekrandan chiqish',
			'common.pressBackAgainToExit' => 'Chiqish uchun orqaga tugmasini yana bir bor bosing',
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
			'common.mediaKind.movie' => 'Film',
			'common.mediaKind.show' => 'Serial',
			'common.mediaKind.season' => 'Fasl',
			'common.mediaKind.episode' => 'Epizod',
			'common.mediaKind.artist' => 'Ijrochi',
			'common.mediaKind.album' => 'Albom',
			'common.mediaKind.track' => 'Trek',
			'common.mediaKind.collection' => 'Toʻplam',
			'common.mediaKind.playlist' => 'Pleylist',
			'common.mediaKind.clip' => 'Klip',
			'common.mediaKind.photo' => 'Foto',
			'common.mediaKind.folder' => 'Papka',
			'screens.licenses' => 'Litsenziyalar',
			'screens.switchProfile' => 'Profilni almashtirish',
			'screens.subtitleStyling' => 'Subtitr sozlamalari',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Jurnallar',
			'update.available' => 'Yangilanish mavjud',
			'update.versionAvailable' => ({required Object version}) => '${version} versiyasi mavjud',
			'update.currentVersion' => ({required Object version}) => 'Joriy: ${version}',
			'update.skipVersion' => 'Ushbu versiyani oʻtkazib yuborish',
			'update.viewRelease' => 'Tafsilotlarni koʻrish',
			'update.latestVersion' => 'Sizda eng soʻnggi versiya oʻrnatilgan',
			'update.checkFailed' => 'Yangilanishlarni tekshirish imkoni boʻlmadi',
			'appAccess.title' => '7 günni bütün aktiviyatlardan özgürni qaytdan.',
			'appAccess.description' => 'PlezyNG’ning barcha funksiyalaridan yetti kun bepul foydalanib ko‘ring. Sinov davrida to‘lov olinmaydi va obuna talab qilinmaydi. Sinovdan so‘ng do‘konda ko‘rsatilgan narxda bir marta xarid qilib, PlezyNG’dan cheksiz foydalanishingiz mumkin.',
			'appAccess.trialEndedDescription' => 'Do‘konda ko‘rsatilgan narxda bir marta xarid qilib, PlezyNG’ning barcha funksiyalarini umrbod oching. Obuna talab qilinmaydi.',
			'appAccess.startTrial' => '7 day free proving sizga qaytadi.',
			'appAccess.trialActive' => '7 day full-feature proving siz aktivir.',
			'appAccess.trialEnded' => '7 kunlik sinov muddati tugadi',
			'appAccess.trialStartFailed' => 'Bu cihazda testini salmaydi. lütfen qaytarga.',
			'appAccess.lifetimeTitle' => 'PlezyNG hayri boʻlu boʻlu',
			'appAccess.lifetimeBody' => 'Rahmat! PlezyNG’ning barcha funksiyalaridan umrbod foydalanishingiz mumkin.',
			'appAccess.manageTitle' => 'PlezyNG lifetime qasizga',
			'appAccess.manageDescription' => '7 gün bu bütün funksiyalardan free-to-free, sonra sizga mağazadan bir payga o‘zayda o‘ziyada o‘zib.',
			'appAccess.buy' => ({required Object price}) => 'Barcha funksiyalarni ${price} evaziga ochish',
			'appAccess.loadingPrice' => 'Buqqqqga market market...',
			'appAccess.retryPrice' => 'Reddit bilan bakup',
			'appAccess.restore' => 'Hayat bilan buyuj',
			'appAccess.pending' => 'Siz qaplan o‘ziz o‘zib o‘zig o‘ziga o‘zige o‘zigi o‘zaga o‘zaya o‘zay o‘ziy o‘ziye o‘ziyan o‘zayn o‘zinc o‘zyan o‘zayan o‘zac o‘zinin o‘ziyar o‘zqan o‘zari o‘zani o‘zaman o‘zadan o‘zagan o‘zanc o‘z.',
			'appAccess.storeUnavailable' => 'Siz bu mağazada abonlikliklik oluyiz. siz bu mağazadan abonliklik olayiz.',
			'appAccess.productNotFound' => 'PlezyNG lifetime unlock bu mağazada yet o‘zayda olmaygan.',
			'appAccess.productQueryFailed' => 'Do‘kondagi narxni yuklab bo‘lmadi. Ulanishingizni tekshirib, qayta urinib ko‘ring.',
			'appAccess.purchaseFailed' => 'Bu qotomiyadi ko‘zadi. qaytarga ko‘z.',
			'appAccess.restoreFailed' => 'Sizga buyni qaytarga qotʻyadi. qaytarga qaytarga.',
			'appAccess.nothingToRestore' => 'No PlezyNG lifetime buy bu mağazalar hesab için bulgan.',
			'settings.title' => 'Sozlamalar',
			'settings.supportDeveloper' => 'PlezyNG-ni qoʻllab-quvvatlash',
			'settings.supportDeveloperDescription' => 'Rivojlanishni qoʻllab-quvvatlash uchun xayriya qiling',
			'settings.lifetimeAccess' => 'PlezyNG lifetime qasizga',
			'settings.language' => 'Til',
			'settings.theme' => 'Mavzu',
			'settings.appearance' => 'Tashqi koʻrinish',
			'settings.detailPage' => 'Detaylar Sayfadi',
			'settings.themeSongsEnabled' => 'Theme lagular',
			'settings.themeSongsEnabledDescription' => 'Playing tema lagular, media details o‘shayni.',
			'settings.themeSongVolume' => 'Tomaq Song Volume',
			'settings.videoPlayback' => 'Video ijrosi',
			'settings.videoPlaybackDescription' => 'Ijro parametrlarini sozlang',
			'settings.advanced' => 'Kengaytirilgan',
			'settings.episodePosterMode' => 'Qism poster stili',
			'settings.seriesPoster' => 'Serial posteri',
			'settings.seasonPoster' => 'Mavsum posteri',
			'settings.episodeThumbnail' => 'Kadr koʻrinishi',
			'settings.showHeroSectionDescription' => 'Bosh sahifada tanlangan kontent karuselini koʻrsatish',
			'settings.secondsLabel' => 'Soniya',
			'settings.minutesLabel' => 'Daqiqa',
			'settings.secondsShort' => 'son',
			'settings.minutesShort' => 'daq',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Vaqtni kiriting (${min}-${max})',
			'settings.systemTheme' => 'Tizim sozlamasi',
			'settings.lightTheme' => 'Yorugʻ',
			'settings.darkTheme' => 'Toʻq',
			'settings.oledTheme' => 'OLED',
			'settings.emberTheme' => 'Choʻgʻ',
			'settings.glacierTheme' => 'Muzlik',
			'settings.forestTheme' => 'Oʻrmon',
			'settings.plumTheme' => 'Olxoʻri',
			'settings.paperTheme' => 'Qogʻoz',
			'settings.libraryDensity' => 'Kutubxona zichligi',
			'settings.displayScale' => 'Ekran miqyosi',
			'settings.compact' => 'Ixcham',
			'settings.comfortable' => 'Qulay',
			'settings.gridSpacing' => 'Toʻr oraligʻi',
			'settings.gridSpacingTight' => 'Zich',
			'settings.gridSpacingNormal' => 'Oddiy',
			'settings.gridSpacingSpacious' => 'Keng',
			'settings.tvCornerSpotlightBackdrop' => 'Burchak yoritish foni',
			'settings.tvCornerSpotlightBackdropDescription' => 'Fonni toʻliq ekran oʻrniga yuqori oʻng burchakda koʻrsatish',
			'settings.viewMode' => 'Koʻrish rejimi',
			'settings.gridView' => 'Toʻrsimon',
			'settings.listView' => 'Roʻyxat',
			'settings.showHeroSection' => 'Asosiy boʻlimni koʻrsatish',
			'settings.showHomeBackdrop' => 'Home Backdrop Artwork\'i yuxaylar',
			'settings.showHomeBackdropDescription' => 'U\'zizga\'da qaytadi qaytadi\'ni qaytadi',
			'settings.contentScreensaverEnabled' => 'Ekranlarga',
			'settings.contentScreensaverEnabledDescription' => 'Full screen-sharing artwork ko‘zadi, app is idle.',
			'settings.contentScreensaverDelay' => 'Ekranlarga qaytdan sonra',
			'settings.contentScreensaverLibraries' => 'Screensaver librarlar',
			'settings.contentScreensaverLibrariesDescription' => 'Ekran saqlagichi uchun rasmlar olinadigan kutubxonalarni tanlang. Hech biri tanlanmasa, barcha kutubxonalardagi rasmlar ishlatiladi.',
			'settings.contentScreensaverAllLibraries' => 'All librarlar',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} librarlar seçkin',
			'settings.contentScreensaverNoLibraries' => 'Bağlanmış medya librarlar yok.',
			'settings.contentScreensaverDismissHint' => 'Bu\'da bir buton o\'t tapatni bo\'t tabatni',
			'settings.newEpisodeNotifications' => 'Yangi qismlar haqida bildirishnomalar',
			'settings.newEpisodeNotificationsDescription' => 'Tomosha qilib bo‘lgan serialingizga yangi qism qo‘shilganda xabar berish. Plezy ochiq bo‘lganda tekshiriladi.',
			'settings.continueWatchingRowSize' => 'U\'qizga sizliklikliklik.',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => '${label} kartlar',
			'settings.rowSizeCompact' => 'Ixcham',
			'settings.rowSizeStandard' => 'Standardi',
			'settings.rowSizeLarge' => 'Katta',
			'settings.continueWatchingAction' => '"Tomoshani davom ettirish" harakati',
			'settings.continueWatchingPlay' => 'Ijro etish',
			'settings.continueWatchingDetails' => 'Tafsilotlarni ochish',
			'settings.episodeAction' => 'Qism harakati',
			'settings.episodePlay' => 'Ijro etish',
			'settings.episodeDetails' => 'Tafsilotlarni ochish',
			'settings.useGlobalHubs' => 'Bosh sahifa tuzilishidan foydalanish',
			'settings.useGlobalHubsDescription' => 'Birlashtirilgan bosh sahifa boʻlimlarini koʻrsatish.',
			'settings.showServerNameOnHubs' => 'Boʻlimlarda server nomini koʻrsatish',
			'settings.showServerNameOnHubsDescription' => 'Boʻlim sarlavhalarida har doim server nomini koʻrsatish.',
			'settings.groupLibrariesByServer' => 'Kutubxonalarni server boʻyicha guruhlash',
			'settings.groupLibrariesByServerDescription' => 'Yon menyudagi kutubxonalarni serverlar boʻyicha guruhlash.',
			'settings.alwaysKeepSidebarOpen' => 'Yon menyuni har doim ochiq saqlash',
			'settings.alwaysKeepSidebarOpenDescription' => 'Yon menyu ochiq holatda qoladi, kontent maydoni unga moslashadi',
			'settings.showUnwatchedCount' => 'Koʻrilmaganlar sonini koʻrsatish',
			'settings.showUnwatchedCountDescription' => 'Seriallar va mavsumlarda koʻrilmagan qismlar sonini koʻrsatish',
			'settings.showWatchedIndicators' => 'Koʻrilgan belgilarni koʻrsatish',
			'settings.showWatchedIndicatorsDescription' => 'Koʻrilgan filmlar, seriallar va qismlarda tasdiq belgisi koʻrsatish',
			'settings.showEpisodeNumberOnCards' => 'Kartochkalarda qism raqamini koʻrsatish',
			'settings.showEpisodeNumberOnCardsDescription' => 'Qism kartochkalarida mavsum va qism raqamini koʻrsatish',
			'settings.showSeasonPostersOnTabs' => 'Varaqlarda mavsum posterlarini koʻrsatish',
			'settings.showSeasonPostersOnTabsDescription' => 'Har bir mavsum posterini oʻz boʻlimida koʻrsatish',
			'settings.tvFullCardLayout' => 'Toʻliq TV kartochkalari',
			'settings.tvFullCardLayoutDescription' => 'Aktyor ismlari ustiga yozilgan, faqat rasmdan iborat TV kartochkalaridan foydalanish',
			'settings.focusGlow' => 'Fokus nuri',
			'settings.focusGlowDescription' => 'Tanlangan kartochka atrofida yumshoq nur koʻrsatish',
			'settings.visualEffects' => 'Vizual effektlar',
			'settings.visualEffectsAuto' => 'Avtomatik',
			'settings.visualEffectsAutoDescription' => 'Kuchsiz qurilmalarda effektlarni avtomatik kamaytirish',
			'settings.visualEffectsFull' => 'Toʻliq',
			'settings.visualEffectsReduced' => 'Kamaytirilgan',
			'settings.visualEffectsReducedDescription' => 'Kamroq animatsiya va pastroq sifatli rasmlar',
			'settings.hideSpoilers' => 'Koʻrilmagan qismlar uchun spoylerlarni yashirish',
			'settings.hideSpoilersDescription' => 'Koʻrilmagan qismlar rasmlari va tavsiflarini xiralashtirish',
			'settings.playerBackend' => 'Pleyer infratuzilmasi',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Apparatli dekodlash',
			'settings.hardwareDecodingDescription' => 'Imkon qadar apparatli tezlashtirishdan foydalanish',
			'settings.playbackBuffer' => 'Ijro buferi',
			'settings.playbackBufferAuto' => 'Avto (tavsiya etiladi)',
			'settings.playbackBufferLarge' => 'Katta',
			'settings.playbackBufferExtraLarge' => 'Juda katta',
			'settings.playbackBufferDescription' => 'Beqaror ulanishlarga qarshi koʻproq buferlaydi. Bufer hajmi bilan ham cheklanadi.',
			'settings.streamBufferSize' => 'Buffer siz',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} MB',
			'settings.streamBufferSizeDescription' => 'Transcodes qotʻi qotʻo qotʻu qotʻon qotʻun qotʻur. 0 = Auto',
			'settings.streamBufferSizeExoNote' => 'Playback Buffer\'i ayatlarsa, app\'nin memori limiti yarda qapibib.',
			'settings.streamBufferMegabytes' => 'Megabitni',
			'settings.defaultQualityTitle' => 'Standart sifat',
			'settings.cellularQualityTitle' => 'Mobil tarmoqda standart sifat',
			'settings.remoteQualityTitle' => 'Remote Streaming Qalitadi',
			'settings.remoteQualitySameAsDefault' => 'Uqqqqga kvalitadi',
			'settings.cellularQualitySameAsDefault' => 'Standart sifat bilan bir xil',
			'settings.directPlayCoveredQuality' => 'Kichik videolarni asl sifatda ijro etish',
			'settings.directPlayCoveredQualityDescription' => 'Sifat chegarasiga kiruvchi videolarni qayta kodlash oʻrniga toʻgʻridan-toʻgʻri ijro etish',
			'settings.videoCodecs' => 'Video kodeklar',
			'settings.videoCodecsDescription' => 'Belgilanmagan kodeklarni server qayta kodlaydi',
			'settings.videoCodecsAlwaysAccepted' => 'Har doim qabul qilinadi',
			'settings.musicQualityTitle' => 'Musiqa sifati',
			'settings.subtitleStyling' => 'Subtitr sozlamalari',
			'settings.subtitleStylingDescription' => 'Subtitrlar koʻrinishini moslashtiring',
			'settings.smallSkipDuration' => 'Kichik oʻtkazish vaqti',
			'settings.largeSkipDuration' => 'Katta oʻtkazish vaqti',
			'settings.rewindOnResume' => 'Davom ettirganda orqaga qaytarish',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(seconds, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} soniya', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} soniya', ), 
			'settings.defaultSleepTimer' => 'Standart uyqu taymeri',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(minutes, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} daqiqa', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} daqiqa', ), 
			'settings.rememberTrackSelections' => 'Har bir film/serial uchun ovoz/subtitr tanlovini eslab qolish',
			'settings.chooseTracksBeforePlayback' => 'Playback-dan əvvəl audio-dan subtitles seçin.',
			'settings.chooseTracksBeforePlaybackDescription' => 'Har bir video boshlanishidan oldin manbadagi audio va subtitr yo‘laklarini tanlang.',
			'settings.alwaysShowSubtitlesOnDevice' => 'Bu cihazda subtitles ko‘zlar.',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => 'Serverni bir subtiti yoksa, lokalizasyonda bir track seçin. Bu, serverni preferansini ko‘zadi.',
			'settings.autoDownloadPreferredSubtitle' => 'Yiyiyiyiyiz, preferlik-language subtitles qurtlar',
			'settings.autoDownloadPreferredSubtitleDescription' => 'Siz lokalni preferlik dilinizde bir subtitsiz seçin. Siz bir yoksa, serveri bir qotqlar ko‘t support. Seçim bu cihazda qotq.',
			'settings.rememberTrackSelectionsDescription' => 'Har bir media uchun ovoz va subtitr sozlamalarini saqlash',
			'settings.rememberTrackSelectionsBackendRule' => 'Plex har bir tanlovni serverda fayl boʻyicha saqlaydi; Jellyfin hisobning "Tanlovlarni eslab qolish" funksiyasini ham yoqadi; Emby qoʻllab-quvvatlanmaydi',
			'settings.followServerTrackSelections' => 'Har bir epizod uchun serverdagi tanlovlardan foydalanish',
			'settings.followServerTrackSelectionsDescription' => 'Epizod almashganda joriy tanlovni ko\'chirish o\'rniga serverda tanlangan ovoz va subtitrni qo\'llash',
			'settings.resumeMusicOnLaunch' => 'Musiqa seansini eslab qolish',
			'settings.resumeMusicOnLaunchDescription' => 'Ilova ochilganda oxirgi qo\'shiqni to\'xtagan joyida pauzada ochish',
			'settings.showChapterMarkersOnTimeline' => 'Vaqt shkalasida boʻlim belgilarini koʻrsatish',
			'settings.showChapterMarkersOnTimelineDescription' => 'Vaqt shkalasini boʻlimlarga boʻlish',
			'settings.specialsOrdering' => 'Maxsus qismlar epizodlar tartibida',
			'settings.specialsOrderingDescription' => 'Maxsus qismlar serialning tomosha qilish tartibida qayerda ijro etiladi',
			'settings.specialsOrderingServer' => 'Server tartibiga amal qilish',
			'settings.specialsOrderingAirDate' => 'Efirdagi sana boʻyicha aralashtirish',
			'settings.specialsOrderingLast' => 'Oddiy fasllardan keyin',
			'settings.clickVideoTogglesPlayback' => 'Ijro/pauza uchun videoga bosing',
			'settings.clickVideoTogglesPlaybackDescription' => 'Boshqaruv tugmalarini koʻrsatish oʻrniga videoni ijro etish yoki pauza qilish',
			'settings.videoPlayerControls' => 'Video pleyer boshqaruv elementlari',
			'settings.keyboardShortcuts' => 'Klaviatura tugmalari',
			'settings.keyboardShortcutsDescription' => 'Klaviatura tugmalarini moslashtiring',
			'settings.videoPlayerNavigation' => 'Video pleyer navigatsiyasi',
			'settings.videoPlayerNavigationDescription' => 'Pleyerni boshqarish uchun yoʻnalish tugmalaridan foydalaning',
			'settings.watchTogetherRelay' => 'Birgalikda tomosha relesi',
			'settings.watchTogetherRelayDescription' => 'Oʻz relengizni belgilamasangiz, ommaviy Open Watch Party relelari ishlatiladi',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.watchTogetherRelayInvalid' => 'Toʻgʻri HTTP yoki HTTPS rele manzilini kiriting.',
			'settings.crashReporting' => 'Xatoliklar haqida hisobot',
			'settings.crashReportingDescription' => 'Ilovani takomillashtirishga yordam berish uchun xatoliklar hisobotini yuboring',
			'settings.debugLogging' => 'Nosozliklarni aniqlash jurnali',
			'settings.debugLoggingDescription' => 'Muammolarni hal qilish uchun batafsil jurnal yuritishni yoqing',
			'settings.viewLogs' => 'Jurnallarni koʻrish',
			'settings.viewLogsDescription' => 'Ilova jurnallarini koʻrish',
			'settings.clearImageCache' => 'Rasm keshini tozalash',
			'settings.clearImageCacheDescription' => 'Keshlangan rasm va eskizlarni tozalaydi. Qayta yuklab olinmaguncha rasmlar sekinroq ochilishi mumkin.',
			'settings.clearImageCacheSuccess' => 'Rasm keshi muvaffaqiyatli tozalandi',
			'settings.resetSettings' => 'Sozlamalarni qayta oʻrnatish',
			'settings.resetSettingsDescription' => 'Standart sozlamalarni tiklash. Bu amalni ortga qaytarib boʻlmaydi.',
			'settings.resetSettingsSuccess' => 'Sozlamalar muvaffaqiyatli qayta oʻrnatildi',
			'settings.backup' => 'Zahira nusxa',
			'settings.exportSettings' => 'Sozlamalarni eksport qilish',
			'settings.exportSettingsDescription' => 'Parametrlaringizni faylga saqlang',
			'settings.exportSettingsSuccess' => 'Sozlamalar eksport qilindi',
			'settings.importSettings' => 'Sozlamalarni import qilish',
			'settings.importSettingsDescription' => 'Parametrlarni fayldan tiklang',
			'settings.importSettingsConfirm' => 'Bu joriy sozlamalaringiz ustidan yoziladi. Davom etasizmi?',
			'settings.importSettingsSuccess' => 'Sozlamalar import qilindi',
			'settings.importSettingsInvalidFile' => 'Ushbu fayl toʻgʻri PlezyNG sozlamalar fayli emas',
			'settings.importSettingsNoUser' => 'Sozlamalarni import qilishdan oldin tizimga kiring',
			'settings.cloudBackup' => 'Bulutli zaxira nusxasi',
			'settings.cloudBackupDescription' => 'Ko‘chiriladigan sozlamalarni HTTPS orqali WebDAV manziliga zaxiralang. Server ulanishlari va kirish ma’lumotlari ushbu qurilmada qoladi.',
			'settings.cloudBackupUrl' => 'WebDAV JSON fildi URL',
			'settings.cloudBackupUsername' => 'Foydalanuvchi nomi',
			'settings.cloudBackupPassword' => 'Parol',
			'settings.cloudBackupSaved' => 'Bulutli zaxira nusxasi saqlanadigan manzil saqlandi',
			'settings.cloudBackupNow' => 'Tadi qaytadi',
			'settings.cloudBackupComplete' => 'Yatlarlarlarlar yatlarlar',
			'settings.cloudBackupRestore' => 'Backup qaytarga',
			'settings.cloudBackupRestoreConfirm' => 'Bu ayarlar bu cihazda uyumlanga mobil ayarlar qaytadi.',
			'settings.cloudBackupRestored' => 'Uqqqqlarlar bilan qaytarga qotlar.',
			'settings.shortcutsReset' => 'Tugmalar birlashmasi standart holatga qaytarildi',
			'settings.resetShortcutsConfirm' => 'Bu oʻzingiz sozlagan tugmalar birlashmalarini standart holatga qaytaradi. Davom etasizmi?',
			'settings.about' => 'Dastur haqida',
			'settings.aboutDescription' => 'Ilova haqida maʼlumot va litsenziyalar',
			'settings.updates' => 'Yangilanishlar',
			'settings.updateAvailable' => 'Yangilanish mavjud',
			'settings.checkForUpdates' => 'Yangilanishlarni tekshirish',
			'settings.autoCheckUpdatesOnStartup' => 'Ishga tushganda avtomatik tekshirish',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Ishga tushganda yangilanish boʻlsa xabar berish',
			'settings.validationErrorEnterNumber' => 'Toʻgʻri raqam kiriting',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Vaqt ${min} va ${max} ${unit} orasida boʻlishi kerak',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Bu birlashma ${action} harakatiga biriktirilgan',
			'settings.shortcutUpdated' => ({required Object action}) => '${action} uchun tugmalar birlashmasi yangilandi',
			'settings.saveFailed' => 'Oʻzgarishlar saqlanmadi. Qaytadan urinib koʻring.',
			'settings.autoPlayAndSkip' => 'Avtomatik ijro va oʻtkazish',
			'settings.autoPlayNextEpisode' => 'Keyingi qismni avtomatik ijro etish',
			'settings.autoPlayNextEpisodeDescription' => 'Qism tugagach, keyingisini avtomatik ijro etish',
			'settings.shuffleStartsFromBeginning' => 'Aralashtirish boshidan boshlanadi',
			'settings.shuffleStartsFromBeginningDescription' => 'Aralashtirganda har bir qismni davom ettirish oʻrniga boshidan boshlash',
			'settings.plexCinemaPreRoll' => 'Serverdagi film kirish videolaridan foydalanish',
			'settings.plexCinemaPreRollDescription' => 'Plex pre-rolls ya Jellyfin və Emby intros ko‘figurada oynaygan film başlatmaydan.',
			'settings.playNextCountdown' => 'Keyingi qism sanogʻi',
			'settings.playNextCountdownImmediate' => 'Darhol ijro etish',
			'settings.skipIntroMode' => 'Kirishni oʻtkazish',
			'settings.skipIntroModeOffDescription' => 'Kirishlarni oʻtkazish tugmasiz oddiy ijro etish',
			'settings.skipIntroModeButtonDescription' => 'Kirish boshlanganda oʻtkazish tugmasini koʻrsatish',
			'settings.skipIntroModeAutoDescription' => 'Kirishlarni quyidagi kechikishdan keyin avtomatik oʻtkazish',
			'settings.skipCreditsMode' => 'Titrlarni oʻtkazish',
			'settings.skipCreditsModeOffDescription' => 'Titrlarni oʻtkazish tugmasiz oddiy ijro etish',
			'settings.skipCreditsModeButtonDescription' => 'Titrlar boshlanganda oʻtkazish tugmasini koʻrsatish',
			'settings.skipCreditsModeAutoDescription' => 'Titrlarni avtomatik oʻtkazib, keyingi qismni ijro etish',
			'settings.skipAdsMode' => 'Ads koʻyadi',
			'settings.skipAdsModeOffDescription' => 'Xamqadi reklamlar normalga kaygaqdan kaygaqlar.',
			'settings.skipAdsModeButtonDescription' => 'Plex reklamani aniqlaganda o‘tkazib yuborish tugmasini ko‘rsatish',
			'settings.skipAdsModeAutoDescription' => 'Aniqlangan reklamalarni quyida belgilangan kutish vaqtidan so‘ng avtomatik o‘tkazib yuborish',
			'settings.musicPlayback' => 'Musiqa ijrosi',
			'settings.musicSweetFades' => 'Yiyiyiyiy',
			'settings.musicSweetFadesDescription' => 'Plex’da ovoz balandligi ma’lumotlari bo‘lsa, trek boshida va oxirida musiqani asta kuchaytirish va pasaytirish. Albom ijrosi o‘zgarmaydi.',
			'settings.skipMarkerModeOff' => 'Oʻchirilgan',
			'settings.skipMarkerModeButton' => 'Tugmani koʻrsatish',
			'settings.skipMarkerModeAuto' => 'Avtomatik',
			'settings.forceSkipMarkerFallback' => 'Zahira belgilarini majburlash',
			'settings.forceSkipMarkerFallbackDescription' => 'Plex belgilari boʻlsa ham boʻlim sarlavhasi shablonlaridan foydalanish',
			'settings.theIntroDbFallback' => 'Thin-Dub-i‘z‘‘i‘z’i‘z\'i‘z-i‘zi‘z‘i‘zi’z‘i’z‘z‘z’in',
			'settings.theIntroDbFallbackDescription' => 'U\'zizga xiyimizga xifimizga, xifimizi xifimize, xifimi xifimisi, xifimin xifimiyizga, Xifimiyimiyimisi xifimiyo, xifimen xifimyo, xifin xifimio, xifinin xifimili, xifmin xifimilo, xifmen xifimile, xifrin xifim, xifren xifimila, xifrimili, xivimili,',
			'settings.autoSkipDelay' => 'Avtomatik oʻtkazish kechikishi',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Avtomatik oʻtkazishdan oldin ${seconds} soniya kutilsin',
			'settings.introPattern' => 'Kirish qismi belgisi shabloni',
			'settings.introPatternDescription' => 'Boʻlim sarlavhalarida introni topish uchun Regex shabloni',
			'settings.creditsPattern' => 'Titr belgisi shabloni',
			'settings.creditsPatternDescription' => 'Boʻlim sarlavhalarida titrlarni topish uchun Regex shabloni',
			'settings.prerolls' => 'Prelimin',
			'settings.playPrerollsBeforeMovies' => 'Filmdan əvvəl filmlar oynaylar.',
			'settings.playPrerollsBeforeMoviesDescription' => 'Siz filmdan əvvəl sizdan bir random klip oynay.',
			'settings.prerollLibrary' => 'Preroll librariy',
			'settings.prerollLibraryNotSet' => 'Oʻrnatilmagan',
			'settings.prerollLibraryNoneFound' => 'Siz serverlarda librarlar bulhathathathatlar.',
			'settings.prerollSelection' => 'Tadiqlar seçib',
			'settings.prerollSelectionPickLibraryFirst' => 'Bir librariyiz ilk birini',
			'settings.prerollSelectionNoneSelected' => 'U\'zari seçilmaydi',
			'settings.prerollSelectionCount' => ({required Object count}) => '${count} ta tanlangan',
			'settings.prerollItemPicker' => 'Tadiqlar seçib',
			'settings.prerollItemPickerLoadFailed' => 'Bu librariyadan bir şey ko‘zadi.',
			'settings.invalidRegex' => 'Notoʻgʻri muntazam ifoda (Regex)',
			'settings.regex' => 'Muntazam ifoda (Regex)',
			'settings.downloads' => 'Yuklamalar',
			'settings.downloadLocationDescription' => 'Yuklangan fayllar saqlanadigan joyni tanlang',
			'settings.downloadLocationDefault' => 'Standart (Ilova xotirasi)',
			'settings.downloadLocationCustom' => 'Boshqa joy',
			'settings.selectFolder' => 'Jildni tanlash',
			'settings.resetToDefault' => 'Standart holatga qaytarish',
			'settings.currentPath' => ({required Object path}) => 'Joriy: ${path}',
			'settings.downloadLocationChanged' => 'Yuklash joyi oʻzgartirildi',
			'settings.downloadLocationReset' => 'Yuklash joyi standart holatga qaytarildi',
			'settings.downloadLocationInvalid' => 'Tanlangan jildga yozib boʻlmadi',
			'settings.downloadLocationPickerUnavailable' => 'Ushbu qurilmada jildni tanlash imkoniyati yoʻq',
			'settings.downloadOnWifiOnly' => 'Faqat Wi-Fi orqali yuklash',
			'settings.downloadOnWifiOnlyDescription' => 'Mobil tarmoqdan foydalanilganda yuklashni toʻxtatib turish',
			'settings.autoRemoveWatchedDownloads' => 'Koʻrilgan yuklamalarni avtomatik oʻchirish',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Koʻrib boʻlingan yuklamalarni avtomatik oʻchirish',
			'settings.autoDownloadContinueWatching' => '“Tomoshani davom ettirish” ro‘yxatini avtomatik yuklab olish',
			'settings.autoDownloadContinueWatchingDescription' => 'U\'zizni isqizni isxizni iscizni isgizni isnizni isfizni isjizni ischizni ishqizni.',
			'settings.downloadQuality' => 'Download Qalitsiya',
			'settings.downloadQualityDescription' => 'Plex isqizda bir transferlik kopyadi hazırlar. Jellyfin və Emby transkodlar ko‘dadi fil download; isqizdan transferliklar yeniden başlatmaq gerektirir.',
			'settings.askDownloadQualityEachTime' => 'Qiyizizizizimizimizimizimizizimizimizizizimizizimizizizizimizimizizimizizimiz',
			'settings.askDownloadQualityEachTimeDescription' => 'Sizga video download o‘zizdan əvvəl picker o‘zizi.',
			'settings.cellularDownloadBlocked' => 'Mobil tarmoqda yuklash taqiqlangan. Wi-Fi-dan foydalaning yoki sozlamani oʻzgartiring.',
			'settings.maxVolume' => 'Maksimal ovoz',
			'settings.maxVolumeDescription' => 'Pastroq ovozli videolar uchun ovozni 100%-dan oshirishga ruxsat berish',
			'settings.maxVolumePercent' => ({required Object percent}) => '%${percent}',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Discord-da nima tomosha qilayotganingizni koʻrsatish',
			'settings.services' => 'Xizmatlar',
			'settings.servicesDescription' => 'Trakt, MyAnimeList, Seerr va boshqalarni ulang',
			'settings.manageLibrariesDescription' => 'Kutubxonalarni tartiblash va yashirish',
			'settings.companionRemoteServer' => 'Yordamchi pult serveri',
			'settings.companionRemoteServerDescription' => 'Tarmoqdagi mobil qurilmalarga ushbu ilovani boshqarishga ruxsat berish',
			'settings.companionRemoteServerStartFailed' => 'Yordamchi pult serverini ishga tushirib bo‘lmadi',
			'settings.companionRemoteServerStopFailed' => 'Yordamchi pult serverini to‘xtatib bo‘lmadi',
			'settings.autoPip' => 'Avtomatik Rasm ichida rasm (PiP)',
			'settings.autoPipDescription' => 'Video ijro etilayotganda ilovadan chiqilganda avto-PiP rejimiga oʻtish',
			'settings.matchContentFrameRate' => 'Kadrlar chastotasini moslashtirish',
			'settings.matchContentFrameRateDescription' => 'Ekran chastotasini video kontentiga moslashtirish',
			'settings.matchContentResolution' => 'Kontent oʻlchamiga moslashtirish',
			'settings.matchContentResolutionDescription' => 'Masshtablashni televizor bajarishi uchun ekranni videoning oʻz oʻlchamiga oʻtkazadi. Ijro vaqtida menyular va subtitrlar ham masshtablanadi',
			'settings.matchRefreshRate' => 'Yangilanish chastotasini moslashtirish',
			'settings.matchRefreshRateDescription' => 'Toʻliq ekranda ekran chastotasini moslashtirish',
			'settings.matchDynamicRange' => 'Dinamik diapazonni moslashtirish',
			'settings.matchDynamicRangeDescription' => 'HDR kontent uchun HDR-ni yoqish, soʻng SDR-ga qaytish',
			'settings.displaySwitchDelay' => 'Ekranni almashtirish kechikishi',
			'settings.tunneledPlayback' => 'Tunnelli ijro',
			'settings.tunneledPlaybackDescription' => 'Video tunnellashdan foydalanish. HDR ijrosida ekran qora boʻlsa yoki harakat uzilib qolsa, oʻchiring.',
			'settings.audioPassthrough' => 'Ovozni toʻgʻridan-toʻgʻri oʻtkazish (Passthrough)',
			'settings.audioPassthroughDescription' => 'Dolby/DTS ovozini qayta kodlamasdan resiver yoki televizoringizga yuboradi va atroflicha ovozni saqlaydi. Ovoz boʻlmasa, oʻchiring.',
			'settings.audioPassthroughDescriptionApple' => 'Dolby Digital Plus, jumladan Atmos uchun Apple’ning oʻz Dolby dekoderidan foydalanish. DTS va TrueHD avvalgidek koʻp kanalli PCM sifatida ijro etiladi. Ovoz boʻlmasa, oʻchiring.',
			'settings.audioPassthroughDescriptionAppleSpatial' => 'Dolby Digital Plus, jumladan Atmos uchun Apple’ning oʻz Dolby dekoderidan foydalanish. iOS, iPadOS va tvOS 26 yoki undan yangi versiyalarda TrueHD Atmos va DTS:X fazoviy audio sifatida ijro etiladi. Boshqa DTS va TrueHD treklari koʻp kanalli PCM sifatida ijro etiladi. Ovoz boʻlmasa, oʻchiring.',
			'settings.audioPassthroughOverriddenByNormalization' => 'Ovoz balandligini meʼyorlashtirish yoqilganda oʻchirilgan',
			'settings.audioChannelLimit' => 'Audio kanallari',
			'settings.audioChannelLimitDescription' => 'Barcha kanallarni ijro eta olmaydigan karnaylar, quloqchinlar yoki HDMI tizimlari uchun dekodlangan ovoz kanallarini kamaytirish',
			'settings.audioChannelLimitOriginal' => 'Asl',
			'settings.audioChannelLimitOriginalDescription' => 'Trekdagi barcha kanallarni ijro etish',
			'settings.audioChannelLimitSurround51' => '5.1 gacha',
			'settings.audioChannelLimitSurround51Description' => 'Faqat 5.1 PCM qabul qiladigan televizor va resiverlar uchun 7.1 ni 5.1 ga tushirish. Toʻgʻridan-toʻgʻri oʻtkazishga taʼsir qilmaydi.',
			'settings.audioChannelLimitStereo' => 'Stereo',
			'settings.audioChannelLimitStereoDescription' => 'Stereo karnaylar yoki quloqchinlar uchun ikki kanalga tushirish. Toʻgʻridan-toʻgʻri oʻtkazishni oʻchiradi.',
			'settings.downmixCenterBoost' => 'Markaziy kanalni kuchaytirish',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Kuchaytirish (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Oʻtkazishda ovozni meʼyorlashtirish',
			'settings.audioDownmixNormalizeDescription' => 'Ovoz buzilishining oldini olish uchun darajani tushirish. Asl ovoz balandligini saqlash uchun oʻchiring (baland sahnalar buzilishi mumkin).',
			'settings.dvConversionMode' => 'Dolby Vision oʻtkazmasi',
			'settings.dvConversionModeDescription' => 'Dolby Vision Profile 7 fayllarini qayta ishlash rejimini tanlang.',
			'settings.dvConversionAuto' => 'Avtomatik',
			'settings.dvConversionNative' => 'Ichki / Oʻchirilgan',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Qurilma imkoniyatlaridan foydalanish',
			'settings.dvConversionNativeDescription' => 'Ichki DV7 rejimini majburlash',
			'settings.dvConversionDv81Description' => 'Dolby Vision profile 8.1 formatiga oʻtkazish',
			'settings.dvConversionHevcStripDescription' => 'Dolby Vision qatlamlarini olib tashlash va HEVC sifatida koʻrsatish',
			'settings.disableDolbyVision' => 'Dolby Vision\'ni oʻchirish',
			_ => null,
		} ?? switch (path) {
			'settings.disableDolbyVisionDescription' => 'Faylda boʻlsa, Dolby Vision oʻrniga HDR10 yoki HLG qatlamini ijro etish',
			'settings.hdrSdrConversion' => 'HDR\'ni SDR\'ga aylantirish',
			'settings.hdrSdrConversionDescription' => 'Displey HDR\'ni ko‘rsata olmaganda HDR videoni nima aylantirishini tanlang.',
			'settings.hdrSdrConversionAuto' => 'Avtomatik',
			'settings.hdrSdrConversionAutoDescription' => 'Android 9 va undan keyingi versiyalarda qurilma, eskiroq versiyalarda pleyer',
			'settings.hdrSdrConversionDevice' => 'Qurilma',
			'settings.hdrSdrConversionDeviceDescription' => 'Aylantirishni qurilmaning video apparati bajaradi. Eng tezi, lekin ranglar qurilmaga bog‘liq',
			'settings.hdrSdrConversionPlayer' => 'Pleyer',
			'settings.hdrSdrConversionPlayerDescription' => 'Aylantirishni pleyer bajaradi. Ranglar bir xil, lekin kuchsiz TV-pristavkalarda 4K qotishi mumkin',
			'settings.deinterlace' => 'Interleysni olib tashlash',
			'settings.deinterlaceDescription' => 'Interleys videodagi taroqsimon artefaktlarni olib tashlash (faqat mpv pleyerida)',
			'settings.deinterlaceOff' => 'Oʻchirilgan',
			'settings.deinterlaceOffDescription' => 'Interleys videoni dekodlangan holicha koʻrsatish',
			'settings.deinterlaceVideo' => 'Video',
			'settings.deinterlaceVideoDescription' => 'Har bir maydonni toʻliq kadrga aylantirish. Sport, yangiliklar va konsertlar kabi televideniye uchun suratga olingan videolar uchun',
			'settings.deinterlaceFilm' => 'Film',
			'settings.deinterlaceFilmDescription' => 'NTSC DVD-larda keng tarqalgan, 29.97 fps ga telesine qilingan film va animatsiyaning asl kadrlarini tiklash. Televideniye uchun suratga olingan video uzilib-uzilib koʻrinadi. Jonli TV Video rejimidan foydalanadi',
			'settings.requireProfileSelectionOnOpen' => 'Ochilganda profilni soʻrash',
			'settings.requireProfileSelectionOnOpenDescription' => 'Ilova ochilgan har safar profilni tanlashni koʻrsatish',
			'settings.forceTvMode' => 'TV rejimini majburlash',
			'settings.forceTvModeDescription' => 'TV interfeysini majburiy yoqish. Avtomatik aniqlanmaydigan qurilmalar uchun. Qayta ishga tushirish talab qilinadi.',
			'settings.startInFullscreen' => 'Toʻliq ekranda boshlash',
			'settings.startInFullscreenDescription' => 'PlezyNG-ni ochganda toʻliq ekran rejimida ochish',
			'settings.exitFullscreenOnPlayerClose' => 'Pleyer yopilganda toʻliq ekrandan chiqish',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Video pleyerni yopganda avtomatik ravishda toʻliq ekrandan chiqish',
			'settings.autoHidePerformanceOverlay' => 'Unumdorlik panelini avto-yashirish',
			'settings.autoHidePerformanceOverlayDescription' => 'Unumdorlik panelini boshqaruv tugmalari bilan birga yashirish',
			'settings.showNavBarLabels' => 'Navigatsiya paneli matnlarini koʻrsatish',
			'settings.showNavBarLabelsDescription' => 'Navigatsiya belgilarining ostida matnni koʻrsatish',
			'settings.startupSection' => 'Boshlangʻich boʻlim',
			'settings.preferredServer' => 'Server qiziziziz',
			'settings.preferredServerDescription' => 'Bu server\'nin sonuçlar bilan prioriziziziz, bütün bağlantılı serverlar qothatlar.',
			'settings.preferredServerAutomatic' => 'Avtomatik',
			'settings.showExploreTab' => 'Kashf qilish varagʻini koʻrsatish',
			'settings.showExploreTabDescription' => 'Plex Discover va ulangan kuzatuvchilardagi kontent bilan Kashf qilish varagʻini koʻrsatish',
			'settings.hideEmptyLibraries' => 'Librarlar bo‘qlar',
			'settings.hideEmptyLibrariesDescription' => 'Bu server-di-reporting element sayni nullga navigation.',
			'settings.liveTvDefaultFavorites' => 'Jonli TV-da tanlangan kanallarni standart qilish',
			'settings.liveTvDefaultFavoritesDescription' => 'Jonli TV ochilganda faqat tanlangan kanallarni koʻrsatish',
			'settings.general' => 'Umumiy',
			'settings.generalDescription' => 'Til, ishga tushirish va oyna xatti-harakati',
			'settings.languageAndRegion' => 'Til va mintaqa',
			'settings.startup' => 'Ishga tushirish',
			'settings.display' => 'Displey',
			'settings.libraryAndCards' => 'Kutubxona va kartochkalar',
			'settings.homeScreen' => 'Bosh ekran',
			'settings.navigation' => 'Navigatsiya',
			'settings.window' => 'Oyna',
			'settings.liveTv' => 'Jonli TV',
			'settings.player' => 'Pleyer',
			'settings.videoAndDisplay' => 'Video va displey',
			'settings.audio' => 'Audio',
			'settings.quality' => 'Sifat',
			'settings.subtitles' => 'Subtitrlar',
			'settings.seekAndTiming' => 'Oʻtkazish va vaqt sozlamalari',
			'settings.behavior' => 'Xatti-harakat',
			'settings.gestures' => 'Imo-ishoralar',
			'settings.gestureBrightnessSwipe' => 'Yorqinlik surish',
			'settings.gestureBrightnessSwipeDescription' => 'Yorqinlikni sozlash uchun chap chekkada yuqoriga yoki pastga suring',
			'settings.gestureVolumeSwipe' => 'Ovoz surish',
			'settings.gestureVolumeSwipeDescription' => 'Ovozni sozlash uchun oʻng chekkada yuqoriga yoki pastga suring',
			'settings.gesturePinchToZoom' => 'Chimchilab masshtablash',
			'settings.gesturePinchToZoomDescription' => 'Videoni yaqinlashtirish yoki uzoqlashtirish uchun chimchilang',
			'settings.gestureSeekSwipe' => 'Swipe qona',
			'settings.gestureSeekSwipeDescription' => 'Yat-yat-yata o\'qizga video\'da argaqga; qaytdan-yat',
			'settings.rememberBrightnessLevel' => 'Yorqinlik darajasini eslab qolish',
			'settings.rememberBrightnessLevelDescription' => 'Ijroni oxirgi surish bilan oʻrnatilgan yorqinlikda boshlash',
			'settings.controls' => 'Boshqaruv elementlari',
			'settings.rememberPlayerChanges' => 'Pleyer oʻzgarishlarini eslab qolish',
			'settings.rememberPlayerChangesDescription' => 'Ijro vaqtida qilingan oʻzgarish qayerda saqlanishi va qayta qoʻllanishi',
			'settings.scopePlaybackSpeed' => 'Ijro tezligi',
			'settings.scopeShaderPreset' => 'Sheyder oldindan sozlamasi',
			'settings.scopeAspectRatio' => 'Tomonlar nisbati',
			'settings.scopeSyncOffsets' => 'Audio va subtitr sinxronizatsiyasi',
			'settings.playerScopeOff' => 'Saqlamaslik',
			'settings.playerScopeGlobal' => 'Hamma joyda',
			'settings.playerScopeLibrary' => 'Kutubxona boʻyicha',
			'settings.playerScopeTitle' => 'Serial yoki film boʻyicha',
			'settings.exportDialogTitle' => 'PlezyNG sozlamalarini eksport qilish',
			'settings.followSystem' => 'Tizim tiliga mos',
			'settings.followAppLanguage' => 'Interfeys tili bilan bir xil',
			'settings.regionFormat' => 'Mintaqaviy formatlar',
			'settings.regionFormatDescription' => 'Sana, sonlar va oʻlchov birliklari qanday koʻrsatilishini tanlang.',
			'settings.metadataLanguage' => 'Metamaʼlumotlar tili',
			'settings.metadataLanguageDescription' => 'Server qoʻllab-quvvatlasa, sarlavha va tavsiflar uchun afzal til. Audio va subtitr tili alohida sozlanadi.',
			'settings.experimentalDolbyVision' => 'Tajribaviy Dolby Vision',
			'settings.experimentalDolbyVisionDescription' => 'Keyingi ijroda tajribaviy FEL renderidan foydalaning. Dvigatelning alohida yig‘ilmasi talab qilinadi.',
			'settings.dvExperimentUnavailableDescription' => 'Bu tajriba hozircha faqat Linux tizimida mavjud.',
			'settings.dvCompatibilityFallback' => 'Moslik uchun zaxira rejim',
			'settings.dvCompatibilityFallbackDescription' => 'Tajriba boshlanmasa, standart renderdan foydalaning. FEL ma’lumotlari yo‘qolishi mumkin.',
			'settings.dvExperimentDiagnostics' => 'Video tajribasi jurnali',
			'settings.dvExperimentDiagnosticsDescription' => 'Keyingi ijroda pleyerning batafsil jurnallarini yoqing.',
			'themeEditor.builtIn' => 'Oʻrnatilgan',
			'themeEditor.presets' => 'Tayyor mavzular',
			'themeEditor.custom' => 'Shaxsiy',
			'themeEditor.customEmpty' => 'Hali yaratilmagan',
			'themeEditor.editCustom' => 'Shaxsiy mavzuni tahrirlash',
			'themeEditor.editCustomDescription' => 'Har bir rangni oʻzingiz tanlang',
			'themeEditor.locked' => 'Hayatdan qaplan qaplan',
			'themeEditor.savedLocked' => 'Sa\'qiz - lively access qiziziz',
			'themeEditor.title' => 'Shaxsiy mavzu',
			'themeEditor.startFrom' => 'Asos qilib olish',
			'themeEditor.startFromDescription' => 'Boshqa mavzudan barcha ranglarni nusxalash',
			'themeEditor.colors' => 'Ranglar',
			'themeEditor.preview' => 'Oldindan koʻrish',
			'themeEditor.slots.bg' => 'Fon',
			'themeEditor.slots.surface' => 'Sirt',
			'themeEditor.slots.outline' => 'Kontur',
			'themeEditor.slots.text' => 'Matn',
			'themeEditor.slots.textMuted' => 'Ikkilamchi matn',
			'themeEditor.slots.accent' => 'Urgʻu rangi',
			'themeEditor.opacity' => 'Noshaffoflik',
			'themeEditor.hexHint' => '#RRGGBB yoki #AARRGGBB',
			'themeEditor.fromOtherThemes' => 'Boshqa mavzulardan',
			'themeEditor.swatchLabel' => ({required Object theme, required Object color}) => '${theme} — ${color}',
			'themeEditor.contrast.textOnBg' => 'Fondagi matn',
			'themeEditor.contrast.textOnSurface' => 'Sirtdagi matn',
			'themeEditor.contrast.textMutedOnBg' => 'Fondagi ikkilamchi matn',
			'themeEditor.contrast.textMutedOnSurface' => 'Sirtdagi ikkilamchi matn',
			'themeEditor.contrast.accentOnBg' => 'Fondagi urgʻu rangi',
			'themeEditor.contrast.accentOnSurface' => 'Sirtdagi urgʻu rangi',
			'themeEditor.contrast.labelOnAccent' => 'Urgʻu rangidagi tugma matni',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, tavsiya etilgan ${minimum}:1 dan past',
			'themeEditor.discardTitle' => 'Oʻzgarishlardan voz kechilsinmi?',
			'themeEditor.discardMessage' => 'Saqlanmagan rang oʻzgarishlari yoʻqoladi.',
			'themeEditor.discard' => 'Voz kechish',
			'themeEditor.previewCardTitle' => ({required Object number}) => '${number}-qism',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => '${minutes} daq qoldi',
			'themeEditor.previewSwitch' => 'Avtomatik ijro',
			'themeEditor.previewMutedText' => 'Ikkilamchi matn shunday koʻrinadi',
			'search.hint' => 'Filmlar, seriallar, musiqa qidirish...',
			'search.tryDifferentTerm' => 'Boshqa qidiruv soʻzini kiriting',
			'search.searchYourMedia' => 'Medialaringizdan qidiring',
			'search.enterTitleActorOrKeyword' => 'Nomini, aktyorni yoki kalit soʻzni kiriting',
			'search.people' => 'Odamlar',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => '${actionName} uchun tugmalar birlashmasini oʻrnatish',
			'hotkeys.clearShortcut' => 'Birlashmani tozalash',
			'hotkeys.noShortcutSet' => 'Tugmalar birlashmasi oʻrnatilmagan',
			'hotkeys.currentShortcut' => 'Joriy birlashma:',
			'hotkeys.pressToRecord' => 'Birlashmani yozib olish uchun bosing',
			'hotkeys.recordingShortcut' => 'Endi tugmalarni bosing',
			'hotkeys.actions.playPause' => 'Ijro/Pauza',
			'hotkeys.actions.volumeUp' => 'Ovozni balandlatish',
			'hotkeys.actions.volumeDown' => 'Ovozni pastlatish',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Oldinga oʻtkazish (${seconds}son)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Orqaga oʻtkazish (${seconds}son)',
			'hotkeys.actions.fullscreenToggle' => 'Toʻliq ekranga oʻtish/chiqish',
			'hotkeys.actions.muteToggle' => 'Ovozni oʻchirish/yoqish',
			'hotkeys.actions.subtitleToggle' => 'Subtitrni yoqish/oʻchirish',
			'hotkeys.actions.audioTrackNext' => 'Keyingi audio yoʻlak',
			'hotkeys.actions.subtitleTrackNext' => 'Keyingi subtitr yoʻlagi',
			'hotkeys.actions.chapterNext' => 'Keyingi boʻlim',
			'hotkeys.actions.chapterPrevious' => 'Oldingi boʻlim',
			'hotkeys.actions.episodeNext' => 'Keyingi qism',
			'hotkeys.actions.episodePrevious' => 'Oldingi qism',
			'hotkeys.actions.speedIncrease' => 'Tezlikni oshirish',
			'hotkeys.actions.speedDecrease' => 'Tezlikni kamaytirish',
			'hotkeys.actions.speedReset' => 'Tezlikni qayta oʻrnatish',
			'hotkeys.actions.zoomIn' => 'Yaqinlashtirish',
			'hotkeys.actions.zoomOut' => 'Uzoqlashtirish',
			'hotkeys.actions.zoomReset' => 'Masshtabni qayta oʻrnatish',
			'hotkeys.actions.subSeekNext' => 'Keyingi subtitrga oʻtish',
			'hotkeys.actions.subSeekPrev' => 'Oldingi subtitrga oʻtish',
			'hotkeys.actions.subtitleDelayIncrease' => 'Subtitrni kechiktirish',
			'hotkeys.actions.subtitleDelayDecrease' => 'Subtitrni oldinga surish',
			'hotkeys.actions.shaderToggle' => 'Sheyderlarni yoqish/oʻchirish',
			'hotkeys.actions.skipMarker' => 'Intro/Titrlarni oʻtkazib yuborish',
			'hotkeys.actions.screenshot' => 'Ekran tasvirini olish',
			'hotkeys.actions.framePrevious' => 'Previous Ramiq',
			'hotkeys.actions.frameNext' => 'Next Ramiq',
			'fileInfo.title' => 'Fayl haqida maʼlumot',
			'fileInfo.overview' => 'Tavsif',
			'fileInfo.video' => 'Video',
			'fileInfo.audio' => 'Audio',
			'fileInfo.subtitles' => 'Subtitrlar',
			'fileInfo.images' => 'Ichiga joylangan rasmlar',
			'fileInfo.dataStreams' => 'Maʼlumot oqimlari',
			'fileInfo.lyrics' => 'Qoʻshiq matni',
			'fileInfo.file' => 'Fayl',
			'fileInfo.attachments' => 'Biriktirilgan fayllar',
			'fileInfo.delivery' => 'Yetkazib berish',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => '${index}-versiya (${count} tadan)',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => '${index}-fayl (${count} tadan)',
			'fileInfo.noStreams' => 'Server ushbu fayl uchun oqimlar mavjud emasligini bildirdi.',
			'fileInfo.copyPath' => 'Yoʻlni nusxalash',
			'fileInfo.pathCopied' => 'Fayl yoʻli nusxalandi',
			'fileInfo.codec' => 'Kodek',
			'fileInfo.codecTag' => 'Kodek yorligʻi',
			'fileInfo.resolution' => 'Oʻlchamlari (Resolution)',
			'fileInfo.codedResolution' => 'Kodlangan oʻlcham',
			'fileInfo.bitrate' => 'Bitreyt (Bitrate)',
			'fileInfo.frameRate' => 'Kadrlar chastotasi',
			'fileInfo.rotation' => 'Burilish',
			'fileInfo.comment' => 'Izoh',
			'fileInfo.audioDescription' => 'Audio tavsif',
			'fileInfo.headerCompression' => 'Sarlavha siqish',
			'fileInfo.sidecarFile' => 'Yordamchi fayl',
			'fileInfo.transportTimestamp' => 'Transport vaqt belgisi',
			'fileInfo.displayOffset' => 'Koʻrsatish siljishi',
			'fileInfo.previewFailureCode' => 'Oldindan koʻrish xatosi kodi',
			'fileInfo.previewRetries' => 'Oldindan koʻrish urinishlari',
			'fileInfo.aspectRatio' => 'Tomonlar nisbati',
			'fileInfo.pixelAspectRatio' => 'Piksel tomonlar nisbati',
			'fileInfo.profile' => 'Profil',
			'fileInfo.level' => 'Daraja',
			'fileInfo.bitDepth' => 'Bit chuqurligi',
			'fileInfo.pixelFormat' => 'Piksel formati',
			'fileInfo.colorSpace' => 'Rang makoni',
			'fileInfo.colorRange' => 'Rang diapazoni',
			'fileInfo.colorPrimaries' => 'Asosiy ranglar',
			'fileInfo.colorTransfer' => 'Rang uzatish',
			'fileInfo.chromaSubsampling' => 'Rangli subdiskretlash',
			'fileInfo.chromaLocation' => 'Chroma joylashuvi',
			'fileInfo.scanType' => 'Skanerlash turi',
			'fileInfo.interlaced' => 'Interleys',
			'fileInfo.anamorphic' => 'Anamorfik',
			'fileInfo.referenceFrames' => 'Tayanch kadrlar',
			'fileInfo.dynamicRange' => 'Dinamik diapazon',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Dolby Vision darajasi',
			'fileInfo.dolbyVisionVersion' => 'Dolby Vision versiyasi',
			'fileInfo.dolbyVisionLayers' => 'Dolby Vision qatlamlari',
			'fileInfo.baseLayerCompatibility' => 'Asosiy qatlam mosligi',
			'fileInfo.avcBitstream' => 'AVC bit oqimi',
			'fileInfo.nalLengthSize' => 'NAL uzunlik oʻlchami',
			'fileInfo.scalingMatrix' => 'Maxsus masshtablash matritsasi',
			'fileInfo.streamIdentifier' => 'Oqim identifikatori',
			'fileInfo.streamIndex' => 'Oqim indeksi',
			'fileInfo.streamId' => 'Oqim ID-si',
			'fileInfo.language' => 'Til',
			'fileInfo.languageCode' => 'Til kodi',
			'fileInfo.streamTitle' => 'Trek nomi',
			'fileInfo.channels' => 'Kanallar',
			'fileInfo.sampleRate' => 'Namuna tezligi',
			'fileInfo.spatialAudio' => 'Fazoviy audio',
			'fileInfo.textBased' => 'Matnga asoslangan',
			'fileInfo.subtitleFormat' => 'Yordamchi format',
			'fileInfo.provider' => 'Provayder',
			'fileInfo.matchScore' => 'Moslik darajasi',
			'fileInfo.externalDelivery' => 'Alohida uzatilishi mumkin',
			'fileInfo.sidecarPath' => 'Yordamchi fayl yoʻli',
			'fileInfo.sourceStream' => 'Nusxa olingan manba',
			'fileInfo.temporary' => 'Vaqtinchalik',
			'fileInfo.timeBase' => 'Vaqt bazasi',
			'fileInfo.overallBitrate' => 'Umumiy bitreyt',
			'fileInfo.path' => 'Yoʻl',
			'fileInfo.fileName' => 'Fayl nomi',
			'fileInfo.size' => 'Hajmi',
			'fileInfo.totalSize' => 'Umumiy hajm',
			'fileInfo.container' => 'Konteyner',
			'fileInfo.duration' => 'Davomiyligi',
			'fileInfo.previewThumbnails' => 'Oldindan koʻrish eskizlari',
			'fileInfo.previewIndex' => 'Oldindan koʻrish indeksi',
			'fileInfo.packetLength' => 'Paket uzunligi',
			'fileInfo.filePresent' => 'Fayl mavjud',
			'fileInfo.fileReadable' => 'Server tomonidan oʻqiladigan',
			'fileInfo.streamPath' => 'Oqim yoʻli',
			'fileInfo.optimizedForStreaming' => 'Oqimli uzatish uchun optimallashtirilgan',
			'fileInfo.has64bitOffsets' => '64-bitli siljishlar',
			'fileInfo.protocol' => 'Protokol',
			'fileInfo.mediaType' => 'Media turi',
			'fileInfo.sourceKind' => 'Manba turi',
			'fileInfo.optimizedVersion' => 'Optimallashtirilgan versiya',
			'fileInfo.optimizationTarget' => 'Optimallashtirish maqsadi',
			'fileInfo.deletedAt' => 'Oʻchirilgan',
			'fileInfo.remoteSource' => 'Masofaviy manba',
			'fileInfo.infiniteStream' => 'Cheksiz oqim',
			'fileInfo.directPlay' => 'Toʻgʻridan-toʻgʻri ijro',
			'fileInfo.directStream' => 'Toʻgʻridan-toʻgʻri oqim',
			'fileInfo.transcoding' => 'Qayta kodlash',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'Versiya ID-si',
			'fileInfo.fileId' => 'Fayl ID-si',
			'fileInfo.defaultAudioTrack' => 'Standart audio trek',
			'fileInfo.defaultSubtitleTrack' => 'Standart subtitr treki',
			'fileInfo.subtitlesOff' => 'Oʻchirilgan',
			'fileInfo.flagDefault' => 'Standart',
			'fileInfo.flagForced' => 'Majburiy',
			'fileInfo.flagSelected' => 'Tanlangan',
			'fileInfo.flagExternal' => 'Tashqi',
			'fileInfo.flagHearingImpaired' => 'Eshitishida nuqsoni borlar uchun',
			'fileInfo.flagDub' => 'Dublyaj',
			'fileInfo.flagOriginal' => 'Asl',
			'fileInfo.channelsMono' => 'Mono',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'Profil ${profile}',
			'mediaMenu.markAsWatched' => 'Koʻrilgan deb belgilash',
			'mediaMenu.markAsUnwatched' => 'Koʻrilmagan deb belgilash',
			'mediaMenu.removeFromContinueWatching' => '"Tomoshani davom ettirish"dan oʻchirish',
			'mediaMenu.viewDetails' => 'Batafsil koʻrish',
			'mediaMenu.goToSeries' => 'Serialga oʻtish',
			'mediaMenu.shufflePlay' => 'Aralashtirib ijro etish',
			'mediaMenu.shuffleNotAvailableOffline' => 'Aralashtirib ijro etish oflayn rejimda mavjud emas',
			'mediaMenu.fileInfo' => 'Fayl haqida maʼlumot',
			'mediaMenu.deleteEpisodeFromServer' => 'Qismni serverdan oʻchirish',
			'mediaMenu.deleteSeasonFromServer' => 'Mavsumni serverdan oʻchirish',
			'mediaMenu.deleteShowFromServer' => 'Shouni serverdan oʻchirish',
			'mediaMenu.deleteMovieFromServer' => 'Filmni serverdan oʻchirish',
			'mediaMenu.deleteEpisodeTitle' => 'Ushbu qism oʻchirilsinmi?',
			'mediaMenu.deleteSeasonTitle' => 'Ushbu mavsum oʻchirilsinmi?',
			'mediaMenu.deleteShowTitle' => 'Ushbu shou oʻchirilsinmi?',
			'mediaMenu.deleteMovieTitle' => 'Ushbu film oʻchirilsinmi?',
			'mediaMenu.deleteEpisodeConfirm' => 'Qismni oʻchirish',
			'mediaMenu.deleteSeasonConfirm' => 'Mavsumni oʻchirish',
			'mediaMenu.deleteShowConfirm' => 'Shouni oʻchirish',
			'mediaMenu.deleteMovieConfirm' => 'Filmni oʻchirish',
			'mediaMenu.deleteAnyway' => 'Baribir oʻchirish',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => '${title} serveringizdan butunlay oʻchirilsinmi?',
			'mediaMenu.deleteMultipleWarning' => 'Bu barcha qismlar va fayllarga taʼsir qiladi.',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: 'Bu undagi ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} qismni va uning faylini o‘chiradi.', other: 'Bu undagi barcha ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} qismni va ularning fayllarini oʻchiradi.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: 'Bu element ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} fayl shaklida saqlanadi va u oʻchiriladi.', other: 'Bu element ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} faylda saqlanadi va ularning barchasi oʻchiriladi.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: 'Xuddi shu faylda yana ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} qism saqlanadi va u ham oʻchiriladi:', other: 'Xuddi shu faylda yana ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} qism saqlanadi va ular ham oʻchiriladi:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'PlezyNG qaysi fayllar olib tashlanishini tekshira olmadi, shuning uchun u yuqorida koʻrsatilgan elementdan koʻproq narsani oʻchirishi mumkin. Bekor qilib qaytadan urining yoki baribir oʻchiring.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'Serveringiz ushbu element uchun fayl tafsilotlarini taqdim etmadi, shuning uchun PlezyNG qaysi fayllar olib tashlanishini tekshira olmaydi. U yuqorida koʻrsatilgan elementdan koʻproq narsani oʻchirishi mumkin.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Media elementi muvaffaqiyatli oʻchirildi',
			'mediaMenu.mediaFailedToDelete' => 'Media elementini oʻchirib boʻlmadi',
			'mediaMenu.rate' => 'Baho berish',
			'mediaMenu.playFromBeginning' => 'Boshidan ijro etish',
			'mediaMenu.playVersion' => 'Versiyani ijro etish...',
			'rateSheet.title' => 'Baho berish',
			'rateSheet.server' => 'Server',
			'rateSheet.favorite' => 'Tanlangan',
			'rateSheet.favorited' => 'Tanlanganlarga qoʻshildi',
			'rateSheet.saved' => 'Saqlandi',
			'rateSheet.notAvailable' => 'Moslik topilmadi',
			'rateSheet.noConnectedServices' => 'Baho berish uchun Sozlamalardan xizmatni ulang.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, film',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, TV shou',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'koʻrilgan',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '%${percent} koʻrilgan',
			'accessibility.mediaCardUnwatched' => 'koʻrilmagan',
			'accessibility.tapToPlay' => 'Ijro etish uchun bosing',
			'accessibility.decrease' => 'Kamaytirish',
			'accessibility.increase' => 'Oshirish',
			'accessibility.decreaseValue' => ({required Object label}) => '${label} qiymatini kamaytirish',
			'accessibility.increaseValue' => ({required Object label}) => '${label} qiymatini oshirish',
			'accessibility.hue' => 'Rang jilosi',
			'accessibility.saturation' => 'Toʻyinganlik',
			'accessibility.brightness' => 'Yorqinlik',
			'accessibility.hexColor' => 'Hex rangi',
			'accessibility.expandText' => 'Matnni yoyish',
			'accessibility.collapseText' => 'Matnni yigʻish',
			'accessibility.alphabetNavigation' => 'Alifboli navigatsiya',
			'accessibility.alphabetScrollHint' => 'Harflar boʻyicha oʻtish uchun yuqoriga yoki pastga suring',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Qator ${row} / ${rowCount}, ustun ${column} / ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'Qator ${row} / ${rowCount}',
			'accessibility.autoScrollPlay' => 'Avtomatik aylantirishni boshlash',
			'accessibility.autoScrollPause' => 'Avtomatik aylantirishni pauza qilish',
			'accessibility.hueShort' => 'H',
			'accessibility.saturationShort' => 'S',
			'accessibility.valueShort' => 'V',
			'accessibility.red' => 'Rojadi',
			'accessibility.green' => 'Yunan',
			'accessibility.blue' => 'Mavi',
			'accessibility.redShort' => 'R',
			'accessibility.greenShort' => 'G',
			'accessibility.blueShort' => 'B',
			'accessibility.colorModeHsv' => 'HSV',
			'accessibility.colorModeRgb' => 'RGB',
			'accessibility.title' => 'Aksesibilit',
			'accessibility.summary' => 'Text, kontrast, motil, kontrollar',
			'accessibility.systemHint' => 'Qurilmangizning maxsus imkoniyatlar sozlamalari doim amal qiladi. Bu parametrlar PlezyNG bo‘ylab qo‘shimcha moslashlarni taqdim etadi.',
			'accessibility.readability' => 'Okumadi və vizibiliyadi',
			'accessibility.textSize' => 'Tekstil bilan bilan bilan',
			'accessibility.preview' => 'Keyingi hikoyangizni toping. O‘zingizga qulay sur’atda o‘qing, tinglang va tomosha qiling.',
			'accessibility.boldText' => 'Interface texti',
			'accessibility.highContrast' => 'Kontrast bilan',
			'accessibility.highContrastHint' => 'Tekstil, outlines, qurtlar, qurtlari, qurtalar, qurtlara qurtlar.',
			'accessibility.interaction' => 'Movsiya və interakcion',
			'accessibility.reduceMotion' => 'Movsiya ko‘zadi',
			'accessibility.reduceMotionHint' => 'Fokus ko‘rsatkichi harakatini, sahifa almashish animatsiyasini va bezak effektlarini to‘xtating.',
			'accessibility.largeTargets' => 'Tadiqni sasni',
			'accessibility.largeTargetsHint' => 'U\'zizga qo‘zlar, touch-i-asistivi navigation üçün daha fazla yer qo‘z.',
			'accessibility.navigationHint' => 'Boshqaruv elementlari orasida yurish uchun Tab va Shift+Tab, ishga tushirish uchun Enter yoki Bo‘sh joy, yopish uchun Escape yoki Orqaga tugmasidan foydalaning. Kitob ochiq bo‘lsa, masshtab va o‘qish sozlamalarini o‘zgartirish mumkin.',
			'tooltips.shufflePlay' => 'Aralashtirib ijro etish',
			'tooltips.playTrailer' => 'Treylerni koʻrish',
			'tooltips.markAsWatched' => 'Koʻrilgan deb belgilash',
			'tooltips.markAsUnwatched' => 'Koʻrilmagan deb belgilash',
			'audioTracks.track' => ({required Object n}) => 'Audio yoʻlak ${n}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} qiziziziz', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} qiziziziz', ), 
			'videoControls.audioLabel' => 'Ovoz',
			'videoControls.subtitlesLabel' => 'Subtitr',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => 'Keng ekran (Letterbox)',
			'videoControls.fillScreen' => 'Ekranni toʻldirish',
			'videoControls.stretch' => 'Choʻzish',
			'videoControls.lockRotation' => 'Aylanishni qulflash',
			'videoControls.unlockRotation' => 'Aylanish qulfini ochish',
			'videoControls.timerActive' => 'Taymer faol',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Ijro ${duration}-dan keyin toʻxtatiladi',
			'videoControls.sleepTimerEndOfVideo' => 'Joriy videoning oxiri',
			'videoControls.sleepTimerStopAtHeader' => 'Toʻxtash vaqti',
			'videoControls.sleepTimerDurationHeader' => 'Taymer',
			'videoControls.playbackWillPauseAtEnd' => 'Ijro ushbu videoning oxirida toʻxtatiladi',
			'videoControls.stillWatching' => 'Hali ham tomosha qilyapsizmi?',
			'videoControls.pausingIn' => ({required Object seconds}) => '${seconds}son-dan keyin toʻxtatiladi',
			'videoControls.continueWatching' => 'Davom ettirish',
			'videoControls.autoPlayNext' => 'Keyingisini avtomatik ijro etish',
			'videoControls.playNext' => 'Keyingisini ijro etish',
			'videoControls.playButton' => 'Ijro etish',
			'videoControls.pauseButton' => 'Pauza',
			'videoControls.playbackPaused' => 'Pauza',
			'videoControls.playbackResumed' => 'Ijro etilmoqda',
			'videoControls.loadingVideo' => 'Video yuklanmoqda',
			'videoControls.showPlaybackControls' => 'Boshqaruv tugmalarini koʻrsatish',
			'videoControls.hidePlaybackControls' => 'Boshqaruv tugmalarini yashirish',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => '${seconds} soniya orqaga oʻtkazish',
			'videoControls.seekForwardButton' => ({required Object seconds}) => '${seconds} soniya oldinga oʻtkazish',
			'videoControls.previousButton' => 'Oldingi qism',
			'videoControls.nextButton' => 'Keyingi qism',
			'videoControls.previousChapterButton' => 'Oldingi boʻlimcha',
			'videoControls.nextChapterButton' => 'Keyingi boʻlimcha',
			'videoControls.muteButton' => 'Ovozni oʻchirish',
			'videoControls.unmuteButton' => 'Ovozni yoqish',
			'videoControls.settingsButton' => 'Ijro sozlamalari',
			'videoControls.tracksButton' => 'Ovoz va subtitrlar',
			'videoControls.trackSelectionTitle' => 'Playback\'dan əvvəl birimimiz.',
			'videoControls.trackSelectionAuto' => 'Automatizasyon',
			'videoControls.chaptersButton' => 'Boʻlimlar',
			'videoControls.versionQualityButton' => 'Versiya va sifat',
			'videoControls.versionColumnHeader' => 'Versiya',
			'videoControls.qualityColumnHeader' => 'Sifat',
			'videoControls.qualityOriginal' => 'Asl nusxa',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Qayta kodlash mavjud emas — asl sifatda ijro etiladi',
			'videoControls.subtitleUnavailableFallback' => 'Tanlangan subtitr yuklanmadi',
			'videoControls.pipButton' => 'Rasm ichida rasm rejimi',
			'videoControls.aspectRatioButton' => 'Tomonlar nisbati',
			'videoControls.ambientLighting' => 'Atrof-muhit yoritilishi',
			'videoControls.fullscreenButton' => 'Toʻliq ekranga oʻtish',
			'videoControls.exitFullscreenButton' => 'Toʻliq ekrandan chiqish',
			'videoControls.alwaysOnTopButton' => 'Har doim ustida',
			'videoControls.rotationLockButton' => 'Aylanish qulfi',
			'videoControls.lockScreen' => 'Ekranni qulflash',
			'videoControls.screenLockButton' => 'Ekran qulfi',
			'videoControls.longPressToUnlock' => 'Qulfdan chiqarish uchun bosib turing',
			'videoControls.timelineSlider' => 'Video vaqt shkalasi',
			'videoControls.volumeSlider' => 'Ovoz balandligi',
			'videoControls.endsAt' => ({required Object time}) => 'Tugash vaqti: ${time}',
			'videoControls.pipActive' => 'Rasm ichida rasm rejimida ijro etilmoqda',
			'videoControls.pipFailed' => 'PiP rejimini ishga tushirishda xatolik',
			'videoControls.screenshotSaved' => 'Ekran tasviri saqlandi',
			'videoControls.screenshotFailed' => 'Ekran tasvirini olib boʻlmadi',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Masshtab %${percent}',
			'videoControls.volumePercent' => ({required Object percent}) => 'Ovoz ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Android 8.0 yoki undan yangisi talab qilinadi',
			'videoControls.pipErrors.iosVersion' => 'iOS 15.0 yoki undan yangisi talab qilinadi',
			'videoControls.pipErrors.permissionDisabled' => 'PiP rejimi oʻchirilgan. Tizim sozlamalaridan yoqing.',
			'videoControls.pipErrors.notSupported' => 'Qurilma PiP rejimini qoʻllab-quvvatlamaydi',
			'videoControls.pipErrors.voSwitchFailed' => 'PiP uchun video chiqishini almashtirib boʻlmadi',
			'videoControls.pipErrors.failed' => 'PiP rejimini ishga tushirishda xatolik',
			'videoControls.pipErrors.prepareFailed' => 'PiP rejimini tayyorlab boʻlmadi',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Xatolik yuz berdi: ${error}',
			'videoControls.chapters' => 'Boʻlimlar',
			'videoControls.noChaptersAvailable' => 'Boʻlimlar mavjud emas',
			'videoControls.queue' => 'Navbat',
			'videoControls.noQueueItems' => 'Navbatda elementlar yoʻq',
			'videoControls.noAudioDevicesAvailable' => 'Mavjud audio qurilmalar yoʻq',
			'videoControls.searchSubtitles' => 'Subtitr qidirish',
			'videoControls.loadSubtitleFile' => 'Subtitle fildi qaytadi.',
			'videoControls.subtitleLoadFailed' => 'Subtitle file‘i qaytadi.',
			'videoControls.language' => 'Til',
			'videoControls.noSubtitlesFound' => 'Subtitr topilmadi',
			'videoControls.subtitleDownloaded' => 'Subtitr yuklab olindi',
			'videoControls.subtitleDownloadedNotApplied' => 'Subtitr yuklab olindi, lekin qoʻllanilmadi',
			'videoControls.subtitleDownloadFailed' => 'Subtitrni yuklab boʻlmadi',
			'videoControls.searchLanguages' => 'Tillardan qidirish...',
			'videoControls.skipIntro' => 'Kirishni oʻtkazish',
			'videoControls.skipCredits' => 'Titrlardan oʻtish',
			'videoControls.skipAds' => 'Ads koʻyadi',
			'videoControls.nextEpisode' => 'Keyingi qism',
			'videoControls.subtitleTrack' => ({required Object n}) => 'Yoʻlak ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => 'Subtitr ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (Majburiy)',
			'videoControls.osdSubtitlesOff' => 'Subtitr: Oʻchirilgan',
			'videoControls.osdSubtitles' => ({required Object track}) => 'Subtitr: ${track}',
			'videoControls.osdAudio' => ({required Object track}) => 'Ovoz: ${track}',
			'messages.markedAsWatched' => 'Koʻrilgan deb belgilandi',
			'messages.markedAsUnwatched' => 'Koʻrilmagan deb belgilandi',
			'messages.markedAsWatchedOffline' => 'Koʻrilgan deb belgilandi (tarmoqqa ulanganda sinxronlanadi)',
			'messages.markedAsUnwatchedOffline' => 'Koʻrilmagan deb belgilandi (tarmoqqa ulanganda sinxronlanadi)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Avtomatik oʻchirildi: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: 'Koʻrilgan ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} yuklama avtomatik oʻchirildi', other: 'Koʻrilgan ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} yuklama avtomatik oʻchirildi', ), 
			'messages.removedFromContinueWatching' => '"Tomoshani davom ettirish"dan oʻchirildi',
			'messages.errorLoading' => ({required Object error}) => 'Xatolik: ${error}',
			'messages.searchPartialResults' => 'Baʼzi media serverlarda qidiruv amalga oshmadi. Mavjud natijalar koʻrsatilmoqda.',
			'messages.streamInterrupted' => 'Oqim uzildi. Qayta urinish uchun ijro tugmasini bosing yoki boshqa joyga oʻting.',
			'messages.liveStreamInterrupted' => 'Jonli oqim uzildi. Qayta urinish uchun ijro tugmasini bosing.',
			'messages.fileInfoNotAvailable' => 'Fayl haqida maʼlumot mavjud emas',
			'messages.playbackAuthenticationRequired' => 'Ushbu elementni ijro etish uchun serverga qaytadan kiring.',
			'messages.playbackServerUnavailable' => 'Media serveri mavjud emas. Keyinroq qaytadan urinib koʻring.',
			'messages.playbackDataInvalid' => 'Server notoʻgʻri ijro maʼlumotlarini qaytardi.',
			'messages.playbackCancelled' => 'Ijro bekor qilindi.',
			'messages.playbackFailed' => 'Ijroni ishga tushirishda xatolik.',
			'messages.playbackFailedDetail' => ({required Object error}) => 'Ijroni boshlab boʻlmadi: ${error}',
			'messages.audioOutputFailed' => 'Audio chiqishi javob bermay qoldi. Televizor yoki resiverning audio ulanishini tekshiring; boshqa ilovalarda ham ovoz boʻlmasa, qurilmani qayta ishga tushiring.',
			'messages.mediaUnavailable' => 'Bu kontent endi mavjud emas.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Fayl maʼlumotlarini yuklashda xatolik: ${error}',
			'messages.errorLoadingSeries' => 'Serialni yuklashda xatolik',
			'messages.musicNotSupported' => 'Musiqa ijrosi hali qoʻllab-quvvatlanmaydi',
			'messages.noDescriptionAvailable' => 'Tavsif mavjud emas',
			'messages.noProfilesAvailable' => 'Profillar yoʻq',
			'messages.contactAdminForProfiles' => 'Profil qoʻshish uchun administratorga murojaat qiling',
			'messages.unableToDetermineLibrarySection' => 'Kutubxona boʻlimini aniqlab boʻlmadi',
			'messages.logsCleared' => 'Jurnallar tozalandi',
			'messages.logsCopied' => 'Jurnallar nusxalandi',
			'messages.noLogsAvailable' => 'Jurnallar yoʻq',
			'messages.libraryScanning' => ({required Object title}) => '"${title}" skanerlanmoqda...',
			'messages.libraryScanStarted' => ({required Object title}) => '"${title}" uchun skanerlash boshlandi',
			'messages.libraryScanFailed' => ({required Object error}) => 'Kutubxonani skanerlab boʻlmadi: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => '"${title}" uchun metamaʼlumotlar yangilanmoqda...',
			_ => null,
		} ?? switch (path) {
			'messages.metadataRefreshStarted' => ({required Object title}) => '"${title}" uchun metamaʼlumotlarni yangilash boshlandi',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Metamaʼlumotlarni yangilab boʻlmadi: ${error}',
			'messages.logoutConfirm' => 'Haqiqatan ham chiqmoqchimisiz?',
			'messages.noSeasonsFound' => 'Mavsumlar topilmadi',
			'messages.seasonsLoadFailed' => 'Mavsumlarni yuklab boʻlmadi',
			'messages.noEpisodesFound' => 'Birinchi mavsumda qismlar topilmadi',
			'messages.noEpisodesFoundGeneral' => 'Qismlar topilmadi',
			'messages.episodesLoadFailed' => 'Qismlarni yuklab boʻlmadi',
			'messages.noResultsFound' => 'Natijalar topilmadi',
			'messages.sleepTimerSet' => ({required Object label}) => 'Uyqu taymeri ${label} vaqtiga oʻrnatildi',
			'messages.noItemsAvailable' => 'Elementlar yoʻq',
			'messages.failedToCreatePlayQueueNoItems' => 'Ijro navbatini yaratib boʻlmadi — elementlar yoʻq',
			'messages.failedPlayback' => ({required Object action, required Object error}) => '${action} muvaffaqiyatsiz tugadi: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Mos keluvchi pleyerga oʻtilmoqda...',
			'messages.serverLimitTitle' => 'Ijro etishda xatolik',
			'messages.serverLimitBody' => 'Server xatoligi (HTTP 500). Cheklov ushbu seansni rad etdi.',
			'messages.mediaUnreadableTitle' => 'Fayl mavjud emas',
			'messages.mediaUnreadableBody' => 'Server bu elementni topdi, lekin uning faylini oʻqiy olmadi (HTTP 404). Fayl koʻchirilgan, oʻchirilgan yoki uning saqlash joyi oflayn boʻlishi mumkin. Server egasidan faylni tekshirishni va kutubxonani qayta skanerlashni soʻrang.',
			'messages.serverBusyTitle' => 'Oqim mavjud emas',
			'messages.serverBusyBody' => 'Server bu faylni uzatishni qayta-qayta rad etdi (HTTP 503). U qayta ishga tushayotgan yoki band boʻlishi, yoxud fayl saqlanadigan xotira oflayn boʻlishi mumkin. Birozdan keyin qaytadan urinib koʻring. Muammo davom etsa, server egasidan server va fayl xotirasini tekshirishni soʻrang.',
			'messages.playbackNotAllowedTitle' => 'Ijro etishga ruxsat berilmagan',
			'messages.playbackNotAllowedBody' => 'Server bu elementni uzatishni rad etdi (HTTP 403). Hisobingizda uni ijro etishga ruxsat boʻlmasligi yoki server ijroga faqat oʻzining mahalliy tarmogʻida ruxsat berishi mumkin.',
			'messages.logsUploaded' => 'Jurnallar yuklandi',
			'messages.logsUploadFailed' => 'Jurnallarni yuklab boʻlmadi',
			'messages.logId' => 'Jurnal ID-si',
			'messages.burnedSubtitlesUseMenu' => 'Subtitrlar bu oqim tasviriga singdirilgan. Ularni subtitr menyusidan oʻzgartiring.',
			'messages.noVideoUrl' => 'Video URL mavjud emas',
			'messages.playbackNoMediaSources' => 'Server ijro etiladigan media manbalarini qaytarmadi',
			'messages.playbackDataNotPrepared' => 'Ijro maʼlumotlari tayyor boʻlishidan oldin boshlandi',
			'messages.streamSelectionUnavailable' => 'Bu manba uchun oqim tanlash imkoni yoʻq',
			'messages.streamSelectionFailed' => 'Tanlangan oqimlarni qoʻllab boʻlmadi',
			'messages.trackSelectionNotRemembered' => 'Bu trek tanlovi faqat joriy ijroga qoʻllanadi.',
			'messages.serverUnavailableForProfile' => 'Faol profil uchun hech qanday server mavjud emas',
			'subtitlingStyling.previewSample' => 'Uqqqqga qurtlar qurtlarga qurtlan qurtlar.',
			'subtitlingStyling.text' => 'Matn',
			'subtitlingStyling.border' => 'Hoshiya',
			'subtitlingStyling.background' => 'Fon',
			'subtitlingStyling.fontSize' => 'Shrift oʻlchami',
			'subtitlingStyling.textColor' => 'Matn rangi',
			'subtitlingStyling.borderSize' => 'Hoshiya oʻlchami',
			'subtitlingStyling.borderColor' => 'Hoshiya rangi',
			'subtitlingStyling.backgroundOpacity' => 'Fon shaffofligi',
			'subtitlingStyling.backgroundColor' => 'Fon rangi',
			'subtitlingStyling.position' => 'Joylashuvi',
			'subtitlingStyling.assOverride' => 'ASS qayta aniqlash',
			'subtitlingStyling.overrideScale' => 'Masshtablash',
			'subtitlingStyling.overrideForce' => 'Majburlash',
			'subtitlingStyling.overrideStrip' => 'Formatlashni olib tashlash',
			'subtitlingStyling.positionTop' => 'Yuqori',
			'subtitlingStyling.positionBottom' => 'Pastki',
			'subtitlingStyling.useMargins' => 'Chekkalardan foydalanish',
			'subtitlingStyling.useMarginsDescription' => 'Matnli subtitrlarga videodan tashqaridagi joydan foydalanishga ruxsat berish. Uslubiy subtitrlar oʻz joylashuvini saqlashi mumkin.',
			'subtitlingStyling.anchorToScreen' => 'Ekranga mahkamlash',
			'subtitlingStyling.anchorToScreenDescription' => 'Matnli subtitrlarni keng ekranli video ostidagi qora hoshiyalarda koʻrsatish',
			'subtitlingStyling.bold' => 'Qalin',
			'subtitlingStyling.italic' => 'Qiya',
			'subtitlingStyling.renderResolution' => 'Renderlash oʻlchamlari',
			'subtitlingStyling.renderResolutionScreen' => 'Ekran oʻlchamlari',
			'subtitlingStyling.renderResolutionVideo' => 'Video oʻlchamlari',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Kengaytirilgan video pleyer sozlamalari',
			'mpvConfig.presets' => 'Tayyor sozlamalar',
			'mpvConfig.noPresets' => 'Saqlangan sozlamalar yoʻq',
			'mpvConfig.saveAsPreset' => 'Sozlama sifatida saqlash...',
			'mpvConfig.presetName' => 'Sozlama nomi',
			'mpvConfig.presetNameHint' => 'Ushbu sozlama uchun nom kiriting',
			'mpvConfig.loadPreset' => 'Yuklash',
			'mpvConfig.deletePreset' => 'Oʻchirish',
			'mpvConfig.presetSaved' => 'Sozlama saqlandi',
			'mpvConfig.presetLoaded' => 'Sozlama yuklandi',
			'mpvConfig.presetDeleted' => 'Sozlama oʻchirildi',
			'mpvConfig.confirmDeletePreset' => 'Ushbu sozlamani oʻchirishga ishonchingiz komilmi?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# izoh',
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => 'Qator qoʻshish',
			'mpvConfig.removeLine' => 'Qatorni oʻchirish',
			'mpvConfig.embeddedVoHint' => 'Linux-da vo, gpu-context va gpu-api e\'tiborga olinmaydi: ichki video har doim video tekisligida vo=libmpv orqali ko\'rsatiladi va gpu-next (ArtCNN kabi compute shaderlar uchun zarur) ichki rejimda ishlay olmaydi.',
			'dialog.confirmAction' => 'Harakatni tasdiqlash',
			'profiles.addPlezyProfile' => 'PlezyNG profilini qoʻshish',
			'profiles.switchingProfile' => 'Profil almashtirilmoqda…',
			'profiles.deleteThisProfileTitle' => 'Ushbu profil oʻchirilsinmi?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => '${displayName} oʻchiriladi. Ulanishlarga taʼsir qilmaydi.',
			'profiles.active' => 'Faol',
			'profiles.manage' => 'Boshqarish',
			'profiles.delete' => 'Oʻchirish',
			'profiles.signOut' => 'Chiqish',
			'profiles.signOutPlexTitle' => 'Plex-dan chiqilsinmi?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => '${displayName} va barcha Plex Home foydalanuvchilari oʻchirilsinmi? Istalgan vaqtda qayta kirishingiz mumkin.',
			'profiles.signOutPlexDeleteDownloads' => 'Yuklamalarni ham oʻchirish',
			'profiles.signOutPlexDeleteDownloadsDescription' => 'Aks holda ular ushbu qurilmada qoladi va shu hisobga qayta kirganingizda yana paydo boʻladi.',
			'profiles.signedOutPlex' => 'Plex-dan chiqdingiz.',
			'profiles.signOutFailed' => 'Chiqish amalga oshmadi.',
			'profiles.sectionTitle' => 'Profillar',
			'profiles.summarySingle' => 'Boshqariladigan foydalanuvchilarni birlashtirish uchun profillar qoʻshing',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} profil · faol: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} profil',
			'profiles.removeConnectionTitle' => 'Ulanish oʻchirilsinmi?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => '${displayName} foydalanuvchisining ${connectionLabel} ulanishiga kirish huquqi olib tashlanadi. Boshqa profillarning kirish huquqi saqlanadi.',
			'profiles.deleteProfileTitle' => 'Profil oʻchirilsinmi?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => '${displayName} va uning ulanishlari oʻchiriladi. Serverlar mavjud boʻlib qoladi.',
			'profiles.profileNameLabel' => 'Profil nomi',
			'profiles.pinProtectionLabel' => 'PIN himoyasi',
			'profiles.copyAutomationLink' => 'Android automatizasyon link',
			'profiles.copyAutomationLinkDescription' => 'Bu profili Android\'dan ya\'z o\'z o‘z o\'zi o\'z. Profil PIN kontrollar hala valib.',
			'profiles.automationLinkCopied' => 'Profil automatizasyon link kopyadi.',
			'profiles.pinManagedByPlex' => 'PIN kodni Plex boshqaradi. plex.tv saytida tahrirlang.',
			'profiles.noPinSetEditOnPlex' => 'PIN kod oʻrnatilmagan. Talab qilish uchun plex.tv saytida Home foydalanuvchisini tahrirlang.',
			'profiles.setPin' => 'PIN oʻrnatish',
			'profiles.setPinTitle' => 'PIN oʻrnatish',
			'profiles.confirmPinTitle' => 'PIN kodni tasdiqlash',
			'profiles.pinSet' => 'PIN oʻrnatildi',
			'profiles.changePin' => 'Oʻzgartirish',
			'profiles.removePin' => 'Oʻchirish',
			'profiles.connectionsLabel' => 'Ulanishlar',
			'profiles.add' => 'Qoʻshish',
			'profiles.deleteProfileButton' => 'Profilni oʻchirish',
			'profiles.noConnectionsHint' => 'Ulanishlar yoʻq — ushbu profildan foydalanish uchun ulanish qoʻshing.',
			'profiles.noConnections' => 'Ulanishlar yoʻq',
			'profiles.plexHomeAccount' => 'Plex Home hisobi',
			'profiles.plexAccountChip' => ({required Object account}) => 'Plex hisobi: ${account}',
			'profiles.plexAccountUserChip' => ({required Object account, required Object user}) => '${account} hisobi orqali ${user}',
			'profiles.connectionDefault' => 'Standart',
			'profiles.connectionAs' => ({required Object displayName}) => '${displayName} sifatida',
			'profiles.makeDefault' => 'Standart qilish',
			'profiles.removeConnection' => 'Oʻchirish',
			'profiles.profileRenamed' => 'Profil nomi oʻzgartirildi.',
			'profiles.borrowAddTo' => ({required Object displayName}) => '${displayName} profiliga qoʻshish',
			'profiles.borrowExplain' => 'Boshqa profilning ulanishidan foydalanish. PIN bilan himoyalangan profillar PIN talab qiladi.',
			'profiles.borrowEmpty' => 'Hali foydalanadigan hech narsa yoʻq.',
			'profiles.borrowEmptySubtitle' => 'Avval boshqa profilga Plex, Jellyfin yoki Emby ulang.',
			'profiles.borrowLoadFailed' => 'Mavjud ulanishlarni yuklab boʻlmadi.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => '${displayName} profilidan',
			'profiles.borrowConnectionBorrowed' => 'Ulanishdan foydalanildi.',
			'profiles.borrowFailed' => 'Ulanishdan foydalanib boʻlmadi.',
			'profiles.incorrectPin' => 'Notoʻgʻri PIN kod.',
			'profiles.incorrectPinTryAgain' => 'Notoʻgʻri PIN kod. Qaytadan urinib koʻring.',
			'profiles.sourceProfileMissingParentAccount' => 'Manba profilda asosiy hisob yoʻq.',
			'profiles.failedToLoadHomeUsers' => 'Plex Home foydalanuvchilarini yuklab boʻlmadi.',
			'profiles.failedToVerifyPin' => 'PIN kodni tekshirib boʻlmadi.',
			'profiles.newProfile' => 'Yangi profil',
			'profiles.profileNameHint' => 'masalan, Mehmonlar, Bolalar',
			'profiles.pinProtectionOptional' => 'PIN himoyasi (ixtiyoriy)',
			'profiles.pinExplain' => 'Profillar orasida oʻtish uchun 4 xonali PIN kod talab qilinadi.',
			'profiles.continueButton' => 'Davom ettirish',
			'profiles.pinsDontMatch' => 'PIN kodlar mos kelmadi',
			'profiles.tokenIdentityMismatch' => 'Plex profil tokeni kutilmagan serverga tegishli boʻlib chiqdi',
			'profiles.settingsLocked' => 'Bu profili için ayatlar kilib.',
			'profiles.unlockSettings' => 'Unlock ko‘zlar',
			'profiles.showExploreForProfile' => 'Bu profili bo\'qlarga ko\'qlar.',
			'profiles.showExploreForProfileDescription' => 'Bu profili navigationdan Explore\'i yasaningiz.',
			'connections.sectionTitle' => 'Ulanishlar',
			'connections.addConnection' => 'Ulanish qoʻshish',
			'connections.addConnectionSubtitleNoProfile' => 'Plex orqali kiring yoki Jellyfin yoki Emby serveriga ulaning',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => '${displayName} profiliga qoʻshish: Plex, Jellyfin, Emby yoki boshqa ulanish',
			'connections.sessionExpiredOne' => ({required Object name}) => '${name} uchun seans vaqti tugadi',
			'connections.sessionExpiredMany' => ({required Object count}) => '${count} server uchun seans vaqti tugadi',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} ushbu hisobga kirishni rad etdi',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} ta server ushbu hisobga kirishni rad etdi',
			'connections.signInAgain' => 'Qaytadan kirish',
			'connections.editMediaBrowserTitle' => ({required Object product}) => '${product} ulanishini tahrirlash',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => '${serverName} uchun URL-larni qoʻshing yoki olib tashlang. PlezyNG eng kam kechikishga ega boʻlgan mavjud URL-dan foydalanadi.',
			'accountPreferences.sectionTitle' => 'Hisob sozlamalari',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => '${account} hisobida saqlangan audio, subtitr va kutubxona parametrlari',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => '${count} ta hisobda saqlangan audio, subtitr va kutubxona parametrlari',
			'accountPreferences.pickAccount' => 'Har bir hisob oʻz sozlamalarini saqlaydi. Tahrirlash uchun birini tanlang.',
			'accountPreferences.storedOnAccount' => 'Bu parametrlar hisobning oʻzida saqlanadi — unga kirilgan har bir ilova ulardan foydalanadi, jumladan boshqa qurilmalaringizdagi PlezyNG ham.',
			'accountPreferences.noAccounts' => 'Sozlanadigan hisoblar yoʻq',
			'accountPreferences.noAccountsHint' => 'Plex-ga kiring yoki Jellyfin yoki Emby serverini ulang — shunda oʻsha hisobda saqlangan sozlamalar shu yerda koʻrinadi.',
			'accountPreferences.unavailable' => 'Bu hisobga ulanib boʻlmadi',
			'accountPreferences.loadFailed' => 'Bu sozlamalarni yuklab boʻlmadi',
			'accountPreferences.noPreference' => 'Afzallik yoʻq',
			'accountPreferences.notSet' => 'Oʻrnatilmagan',
			'accountPreferences.groups.audioAndSubtitles' => 'Audio va subtitrlar',
			'accountPreferences.groups.libraryDisplay' => 'Kutubxona',
			'accountPreferences.groups.personalMedia' => 'Shaxsiy media',
			'accountPreferences.preferredAudioLanguage' => 'Afzal koʻrilgan audio tili',
			'accountPreferences.autoSelectAudio' => 'Audioni til boʻyicha tanlash',
			'accountPreferences.autoSelectAudioDescription' => 'Oʻchirilgan holatda faylda standart deb belgilangan audio trek ishlatiladi.',
			'accountPreferences.preferredSubtitleLanguage' => 'Afzal koʻrilgan subtitr tili',
			'accountPreferences.subtitleMode' => 'Subtitrni yoqish',
			'accountPreferences.subtitleModes.none' => 'Qoʻlda tanlangan',
			'accountPreferences.subtitleModes.noneDescription' => 'Subtitrni hech qachon oʻzi yoqmaydi.',
			'accountPreferences.subtitleModes.defaultMode' => 'Trek bayroqlariga amal qilish',
			'accountPreferences.subtitleModes.defaultModeDescription' => 'Har bir subtitr trekida saqlangan standart va majburiy bayroqlardan foydalanish.',
			'accountPreferences.subtitleModes.always' => 'Har doim yoqilgan',
			'accountPreferences.subtitleModes.alwaysDescription' => 'Mavjud boʻlganda afzal koʻrilgan tildagi subtitr treki yoqiladi.',
			'accountPreferences.subtitleModes.onlyForced' => 'Faqat majburiy subtitrlar',
			'accountPreferences.subtitleModes.onlyForcedDescription' => 'Faqat majburiy deb belgilangan treklar yuklanadi.',
			'accountPreferences.subtitleModes.smart' => 'Chet el audiosi bilan koʻrsatiladi',
			'accountPreferences.subtitleModes.smartDescription' => 'Subtitr faqat audio boshqa tilda boʻlganda yoqiladi.',
			'accountPreferences.subtitleAccessibility' => 'SDH subtitrlar',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'SDH boʻlmagan subtitrlarga ustunlik berish',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'SDH subtitrlarga ustunlik berish',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'Faqat SDH subtitrlar',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'Faqat SDH boʻlmagan subtitrlar',
			'accountPreferences.forcedSubtitles' => 'Majburiy subtitrlar',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'Majburiy boʻlmagan subtitrlarga ustunlik berish',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'Majburiy subtitrlarga ustunlik berish',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'Faqat majburiy subtitrlar',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'Faqat majburiy boʻlmagan subtitrlar',
			'accountPreferences.displayMissingEpisodes' => 'Yoʻqolgan qismlarni koʻrsatish',
			'accountPreferences.displayMissingEpisodesDescription' => 'Server biladigan, lekin fayli boʻlmagan qismlarni roʻyxatlaydi.',
			'accountPreferences.hidePlayedInLatest' => '"Soʻnggi" boʻlimida koʻrilganlarni yashirish',
			'accountPreferences.hidePlayedInLatestDescription' => 'Serverning "Soʻnggi" qatorlariga allaqachon koʻrgan narsalaringizni kiritmaslik.',
			'accountPreferences.displayCollectionsView' => 'Toʻplamlar koʻrinishini koʻrsatish',
			'accountPreferences.displayCollectionsViewDescription' => 'Kutubxonalaringiz yonida serverning Toʻplamlar koʻrinishini taklif qilish.',
			'accountPreferences.rewatchingInNextUp' => 'Qayta koʻrilgan seriallarni "Keyingi" boʻlimida saqlash',
			'accountPreferences.rewatchingInNextUpDescription' => 'Serialni tugatib, qayta boshlasangiz, "Keyingi" boʻlimi serialni tashlab yuborish oʻrniga qayta tomoshaga ergashadi.',
			'accountPreferences.watchedIndicator' => 'Koʻrilganlik belgilari',
			'accountPreferences.watchedIndicatorOptions.none' => 'Hech qachon',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => 'Filmlar va seriallar',
			'accountPreferences.watchedIndicatorOptions.movies' => 'Faqat filmlar',
			'accountPreferences.watchedIndicatorOptions.shows' => 'Faqat seriallar',
			'accountPreferences.mediaReviewsVisibility' => 'Baholar va sharhlar',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'Foydalanuvchilar va tanqidchilar',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'Faqat foydalanuvchilar',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'Faqat tanqidchilar',
			'accountPreferences.mediaReviewsOptions.nobody' => 'Yashirilgan',
			'discover.title' => 'Kashf qilish',
			'discover.noContentAvailable' => 'Kontent mavjud emas',
			'discover.addMediaToLibraries' => 'Kutubxonalaringizga media qoʻshing',
			'discover.continueWatching' => 'Tomoshani davom ettirish',
			'discover.continueWatchingIn' => ({required Object library}) => '${library} ichida tomoshani davom ettirish',
			'discover.nextUp' => 'Navbatda',
			'discover.nextUpIn' => ({required Object library}) => '${library} ichida navbatda',
			'discover.recentlyAdded' => 'Yaqinda qoʻshilganlar',
			'discover.recentlyAddedIn' => ({required Object library}) => '${library} ichida yaqinda qoʻshilganlar',
			'discover.latestAlbumsIn' => ({required Object library}) => '${library} ichida soʻnggi albomlar',
			'discover.recentlyPlayedIn' => ({required Object library}) => '${library} ichida yaqinda eshitilganlar',
			'discover.mostPlayedIn' => ({required Object library}) => '${library} ichida eng koʻp eshitilganlar',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'M${season}Q${episode}',
			'discover.overview' => 'Tavsif',
			'discover.cast' => 'Aktyorlar',
			'discover.findNext.title' => 'Next sizga bulga',
			'discover.findNext.open' => 'Next sizga bulga',
			'discover.findNext.anyTime' => 'Her zaman',
			'discover.findNext.timeAvailable' => 'Siz o‘zʻzʻzʻzʻzʻzʻ?',
			'discover.findNext.filters' => 'O’qimni seçdi',
			'discover.findNext.watch' => 'Tadiq',
			'discover.findNext.listen' => 'Ulu',
			'discover.findNext.read' => 'Okuma',
			'discover.findNext.finishable' => ({required Object duration}) => '${duration}\'da qaytadi',
			'discover.findNext.aboutDuration' => ({required Object duration}) => '${duration} qxzq qxzq',
			'discover.findNext.nextUnit' => ({required Object duration}) => 'Next post · ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => '${duration} total',
			'discover.findNext.timingVaries' => 'Tarifimiz variadi',
			'discover.findNext.notNow' => 'Şimdi ko‘z',
			'discover.findNext.swipeHint' => 'Muqovani strelka tomon suring yoki quyidagi tugmalardan foydalaning.',
			'discover.findNext.saved' => 'Pikaqlar bilan',
			'discover.findNext.savedCount' => ({required Object count}) => '${count}',
			'discover.findNext.undo' => 'O‘z',
			'discover.findNext.details' => 'Detaylar',
			'discover.findNext.noPicks' => 'U‘zari ko‘zari ko‘zari.',
			'discover.findNext.noPicksHint' => 'Bir kütüphan bağlayın ya da başlatmak için bir medya kaynaq qoşun.',
			'discover.findNext.noMatches' => 'Bir şey bu momni ko‘yadi.',
			'discover.findNext.noMatchesHint' => 'Bir formati ko‘di o‘di o‘di o‘di o‘di o‘di o‘di.',
			'discover.findNext.allDone' => 'Sizga hepsi yakadi.',
			'discover.findNext.allDoneHint' => 'Bu seçimler qaytarga qaytarga qaytarga qaytarga.',
			'discover.findNext.refresh' => 'Bir mix ko‘yadi.',
			'discover.findNext.sourceReason' => ({required Object source}) => '${source} qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq',
			'discover.findNext.libraryReason' => ({required Object library}) => '${library} qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq qxzq',
			'discover.findNext.ownedReason' => 'Bu librariyizdan',
			'discover.findNext.liveNow' => 'Onda',
			'discover.findNext.watchLive' => 'Live o‘zadi',
			'discover.findNext.filterAnything' => 'O‘yadi',
			'discover.findNext.filterWatch' => 'Tadiq',
			'discover.findNext.filterListen' => 'Ulu',
			'discover.findNext.filterRead' => 'Okuma',
			'discover.findNext.twentyMinutes' => '20 min',
			'discover.findNext.fortyFiveMinutes' => '45 min',
			'discover.findNext.ninetyMinutes' => '90 min',
			'discover.findNext.apply' => 'Diggadi',
			'discover.findNext.openFailed' => 'Bu seçenek artık kullanılmadi. refresh ko\'t check again.',
			'discover.findNext.changeFailed' => 'Bu cambiadi ko‘yadi. qaytarga ko‘yadi.',
			'discover.findNext.savedLimit' => 'U\'qizga bo\'qizga bo\'qizga bo\'qizga bo\'qizga bo\'qizga bo\'qizga bo\'qizga bo\'qizga bo\'qizga bo\'qizga bo.',
			'discover.findNext.chooseHint' => 'Asarni oching, keyinga saqlang yoki o‘tkazib yuboring.',
			'discover.findNext.howItWorks' => 'Foydalanish tartibi',
			'discover.findNext.notNowHelp' => 'Bu asarni hozircha o‘tkazib yuboring. U kutubxonangizda qoladi.',
			'discover.findNext.saveHelp' => 'Uni shu qurilmadagi shu profilning saqlangan tanlovlariga qo‘shing. Saqlash kontentni yuklab olmaydi.',
			'discover.findNext.openHelp' => 'Tafsilotlar uchun muqovani tanlang. Asarni ijro etish, o‘qish yoki ochish uchun asosiy tugmadan foydalaning.',
			'discover.findNext.controlsHelp' => 'Klaviatura yoki pult: tugmani tanlang, so‘ng Enter yoki tanlash tugmasini bosing. Bekor qilish oxirgi tanlovingizni qaytaradi.',
			'discover.findNext.artworkLoading' => 'Rasm yuklanmoqda…',
			'discover.findNext.artworkUnavailable' => 'Rasm mavjud emas',
			'discover.findNext.savedFeedback' => 'Saqlangan tanlovlarga qo‘shildi',
			'discover.findNext.skippedFeedback' => 'Hozircha o‘tkazib yuborildi',
			'discover.findNext.releaseToConfirm' => 'Tasdiqlash uchun qo‘yib yuboring',
			'discover.findNext.remoteHint' => 'Muqova tanlanganda: ← / → tanlash · Tanlash tugmasi: tafsilotlar · ↑ / ↓ fokusni ko‘chirish',
			'discover.extras' => 'Treylerlar va qoʻshimchalar',
			'discover.studio' => 'Studiya',
			'discover.rating' => 'Reyting',
			'discover.director' => 'Rejissyor',
			'discover.directors' => 'Rejissyorlar',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'TV Shou',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} daq qoldi',
			'discover.moreLikeThis' => 'Oʻxshashlar',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ta nom', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ta nom', ), 
			'discover.person.born' => 'Tugʻilgan',
			'discover.person.died' => 'Vafot etgan',
			'discover.person.birthplace' => 'Tugʻilgan joyi',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date} (${age} yosh)',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date} (${age} yoshda)',
			'errors.searchFailed' => ({required Object error}) => 'Qidiruv xatoligi: ${error}',
			'errors.searchUnavailable' => 'Qidiruv hech bir media serverga ulana olmadi.',
			'errors.connectionTimeout' => ({required Object context}) => '${context} yuklanish vaqti tugadi',
			'errors.connectionFailed' => 'Media serveriga ulanib boʻlmadi',
			'errors.unableToLoad' => ({required Object context}) => '${context} yuklab boʻlmadi.',
			'errors.noClientAvailable' => 'Mavjud mijoz yoʻq',
			'errors.pleaseEnterToken' => 'Tokenni kiriting',
			'errors.invalidToken' => 'Notoʻgʻri token',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Tokenni tekshirib boʻlmadi: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => '${displayName} profiliga oʻtib boʻlmadi',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => '${displayName} profilini oʻchirib boʻlmadi',
			'errors.failedToRate' => 'Reytingni yangilab boʻlmadi',
			'errors.reasonTimedOut' => 'ulanish vaqti tugadi',
			'errors.reasonUnreachable' => 'serverga ulanib boʻlmadi',
			'errors.reasonRefused' => 'server soʻrovni rad etdi',
			'errors.reasonNotFound' => 'element endi serverda yoʻq',
			'errors.reasonServerError' => 'server xatolik haqida xabar berdi',
			'errors.reasonCancelled' => 'soʻrov bekor qilindi',
			'errors.reasonUnexpected' => 'kutilmagan xatolik yuz berdi',
			'libraries.playRandomMovie' => 'Film o‘zari film o‘zadi',
			'libraries.randomPickFailed' => 'Bu librariyadan film o‘zilmaydi.',
			'libraries.title' => 'Kutubxonalar',
			'libraries.fallbackTitle' => 'Kutubxona',
			'libraries.scanLibraryFiles' => 'Fayllarni skanerlash',
			'libraries.scanLibrary' => 'Kutubxonani skanerlash',
			'libraries.analyze' => 'Tahlil qilish',
			'libraries.analyzeLibrary' => 'Kutubxonani tahlil qilish',
			'libraries.refreshMetadata' => 'Metamaʼlumotlarni yangilash',
			'libraries.emptyTrash' => 'Savatni tozalash',
			'libraries.emptyingTrash' => ({required Object title}) => '"${title}" savati tozalanmoqda...',
			'libraries.trashEmptied' => ({required Object title}) => '"${title}" savati tozalandi',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Savatni tozalab boʻlmadi: ${error}',
			'libraries.analyzing' => ({required Object title}) => '"${title}" tahlil qilinmoqda...',
			'libraries.analysisStarted' => ({required Object title}) => '"${title}" uchun tahlil boshlandi',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Tahlil qilib boʻlmadi: ${error}',
			'libraries.noLibrariesFound' => 'Kutubxonalar topilmadi',
			'libraries.allLibrariesHidden' => 'Barcha kutubxonalar yashirilgan',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Yashirin kutubxonalar (${count})',
			'libraries.thisLibraryIsEmpty' => 'Ushbu kutubxona boʻsh',
			'libraries.noItemsMatchFilters' => 'Filtrlarga mos keladigan elementlar topilmadi',
			'libraries.resetFilters' => 'Filtrlarni qayta oʻrnatish',
			'libraries.all' => 'Barchasi',
			'libraries.clearAll' => 'Barchasini tozalash',
			'libraries.scanLibraryConfirm' => ({required Object title}) => '"${title}" kutubxonasini skanerlamoqchimisiz?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => '"${title}" kutubxonasini tahlil qilmoqchimisiz?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => '"${title}" metamaʼlumotlarini yangilaysizmi?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => '"${title}" savatini tozalaysizmi?',
			'libraries.manageLibraries' => 'Kutubxonalarni boshqarish',
			'libraries.sort' => 'Saralash',
			'libraries.sortBy' => 'Saralash mezonlari',
			'libraries.filters' => 'Filtrlar',
			'libraries.confirmActionMessage' => 'Ushbu harakatni bajarmoqchimisiz?',
			'libraries.showLibrary' => 'Kutubxonani koʻrsatish',
			'libraries.hideLibrary' => 'Kutubxonani yashirish',
			'libraries.libraryOptions' => 'Kutubxona parametrlari',
			'libraries.content' => 'kutubxona tarkibi',
			'libraries.selectLibrary' => 'Kutubxonani tanlash',
			'libraries.filtersWithCount' => ({required Object count}) => 'Filtrlar (${count})',
			'libraries.noRecommendations' => 'Tavsiyalar yoʻq',
			'libraries.noCollections' => 'Ushbu kutubxonada toʻplamlar yoʻq',
			'libraries.noFoldersFound' => 'Jildlar topilmadi',
			'libraries.folders' => 'jildlar',
			'libraries.tabs.recommended' => 'Tavsiya etilganlar',
			'libraries.tabs.browse' => 'Koʻrib chiqish',
			'libraries.tabs.collections' => 'Toʻplamlar',
			'libraries.tabs.playlists' => 'Ijro roʻyxatlari',
			'libraries.groupings.title' => 'Guruhlash',
			'libraries.groupings.all' => 'Barchasi',
			'libraries.groupings.movies' => 'Filmlar',
			'libraries.groupings.shows' => 'TV Shoular',
			'libraries.groupings.seasons' => 'Mavsumlar',
			'libraries.groupings.episodes' => 'Qismlar',
			'libraries.groupings.artists' => 'Ijrochilar',
			'libraries.groupings.albums' => 'Albomlar',
			'libraries.groupings.tracks' => 'Taronalar',
			'libraries.groupings.folders' => 'Jildlar',
			'libraries.filterCategories.genre' => 'Janr',
			'libraries.filterCategories.year' => 'Yil',
			'libraries.filterCategories.contentRating' => 'Kontent reytingi',
			'libraries.filterCategories.tag' => 'Teg',
			'libraries.filterCategories.unwatched' => 'Koʻrilmagan',
			'libraries.filterCategories.unplayed' => 'Eshitilmagan',
			'libraries.filterCategories.favorites' => 'Tanlanganlar',
			'libraries.filterCategories.filePath' => 'Fayl yoʻli',
			'libraries.sortLabels.title' => 'Nomi',
			'libraries.sortLabels.dateAdded' => 'Qoʻshilgan sanasi',
			'libraries.sortLabels.releaseDate' => 'Chıqqan sanasi',
			'libraries.sortLabels.rating' => 'Reyting',
			'libraries.sortLabels.communityRating' => 'Hamjamiyat reytingi',
			'libraries.sortLabels.criticRating' => 'Muntaqidlar reytingi',
			'libraries.sortLabels.userRating' => 'Foydalanuvchi reytingi',
			'libraries.sortLabels.datePlayed' => 'Ijro etilgan sanasi',
			'libraries.sortLabels.playCount' => 'Ijrolar soni',
			'libraries.sortLabels.productionYear' => 'Ishlab chiqarilgan yili',
			'libraries.sortLabels.runtime' => 'Davomiyligi',
			'libraries.sortLabels.officialRating' => 'Rasmiy reyting',
			'libraries.sortLabels.premiereDate' => 'Premyera sanasi',
			'libraries.sortLabels.startDate' => 'Boshlangan sanasi',
			'libraries.sortLabels.airTime' => 'Efir vaqti',
			'libraries.sortLabels.studio' => 'Studiya',
			'libraries.sortLabels.random' => 'Tasodifiy',
			'libraries.sortLabels.dateShared' => 'Ulashilgan sanasi',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Soʻnggi qism chiqqan sana',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Soʻnggi qoʻshilgan qism sanasi',
			'libraries.sortLabels.dateDownloaded' => 'Yuklab olingan sanasi',
			'libraries.sortLabels.size' => 'Hajmi',
			'libraries.sortLabels.library' => 'Kutubxona',
			'libraries.advancedFilters.include' => 'Kiritish',
			'libraries.advancedFilters.exclude' => 'Istisno qilish',
			'libraries.advancedFilters.any' => 'Istalgan',
			'libraries.advancedFilters.yes' => 'Ha',
			'libraries.advancedFilters.no' => 'Yoʻq',
			'libraries.advancedFilters.not' => ({required Object value}) => '${value} emas',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '${count} ta tanlangan',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '${count} ta istisno qilingan',
			'libraries.advancedFilters.searchValues' => 'Qiymatlarni qidirish',
			'libraries.advancedFilters.noValues' => 'Qiymatlar yoʻq',
			'libraries.advancedFilters.matchContains' => 'Oʻz ichiga oladi',
			'libraries.advancedFilters.matchNotContains' => 'Oʻz ichiga olmaydi',
			'libraries.advancedFilters.matchIs' => 'Teng',
			'libraries.advancedFilters.matchIsNot' => 'Teng emas',
			'libraries.advancedFilters.matchBeginsWith' => '… bilan boshlanadi',
			'libraries.advancedFilters.matchEndsWith' => '… bilan tugaydi',
			'libraries.advancedFilters.textHint' => 'Mos keladigan matnni kiriting',
			'libraries.advancedFilters.from' => 'Dan',
			'libraries.advancedFilters.to' => 'Gacha',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from} – ${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value} va undan yuqori',
			'libraries.advancedFilters.atMost' => ({required Object value}) => '${value} gacha',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => 'Soʻnggi ${count} kun',
			'libraries.advancedFilters.dateLastYear' => 'Soʻnggi bir yil',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => '${count} kundan eski',
			'libraries.advancedFilters.dateOlderThanYear' => 'Bir yildan eski',
			'libraries.selection.selectItems' => 'Tadiqadiqadi',
			'libraries.selection.selectedCount' => ({required Object count}) => '${count} ta tanlangan',
			'libraries.selection.actions' => 'Seçim aktivatlar',
			'libraries.selection.confirmDescendants' => 'Bu, seçkin show-da və sezonlarda bütün epizodlar ko‘zadi.',
			'libraries.selection.confirmUnwatched' => 'Bu tanlangan elementlarning ijro jarayoni haqidagi ma’lumotlarni ham tozalaydi.',
			'libraries.selection.confirmCount' => ({required Object count}) => 'U‘zizdan qiziziz: ${count}.',
			'libraries.selection.completed' => ({required Object count}) => 'Yangilangan elementlar: ${count}.',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => 'Updated ${succeeded}; faqizdi ${failed}. Faqizdi items qurtlar.',
			'about.title' => 'Dastur haqida',
			'about.openSourceLicenses' => 'Ochiq kodli litsenziyalar',
			'about.versionLabel' => ({required Object version}) => 'Versiya ${version}',
			'about.appDescription' => 'Flutter asosidagi qulay Plex, Jellyfin va Emby mijozi',
			'about.viewLicensesDescription' => 'Uchinchi tomon kutubxonalarining litsenziyalarini koʻrish',
			'about.privacyPolicy' => 'Maxfiylik siyosati',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => '${username} (${email}) uchun serverlar topilmadi',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Serverlarni yuklashda xatolik: ${error}',
			'serverSelection.noValidServers' => 'Bu hisobda foydalanish mumkin boʻlgan server topilmadi',
			'hubDetail.title' => 'Nomi',
			'hubDetail.releaseYear' => 'Chiqqan yili',
			'hubDetail.dateAdded' => 'Qoʻshilgan sanasi',
			'hubDetail.rating' => 'Reyting',
			'hubDetail.noItemsFound' => 'Elementlar topilmadi',
			'logs.clearLogs' => 'Jurnallarni tozalash',
			'logs.copyLogs' => 'Jurnallarni nusxalash',
			'logs.uploadLogs' => 'Jurnallarni yuklash',
			'logs.saveLogs' => 'Jurnallarni faylga saqlash',
			'logs.logsSaved' => ({required Object path}) => 'Hesizlar kaygan ${path}',
			'logs.saveLogsFailed' => 'Bu log file\'i salmaydi.',
			'detail.endsAt' => ({required Object time}) => 'Tugash vaqti: ${time}',
			'startup.failedTitle' => 'PlezyNG ishga tusha olmadi',
			'startup.failedBody' => 'Ishga tushirish paytida nimadir xato ketdi. Quyidagi tafsilotlar aynan nima muvaffaqiyatsiz boʻlganini koʻrsatadi.',
			'startup.failedBodyRepairable' => 'Plezyning saqlangan sozlamalar fayli shikastlangan va PlezyNG ishga tushishidan oldin uni qayta tiklash kerak. Qayta urinish yordam bermaydi — Saqlashni tiklashni tanlang.',
			'startup.phaseLabel' => 'Qadam',
			'startup.showDetails' => 'Tafsilotlarni koʻrsatish',
			'startup.hideDetails' => 'Tafsilotlarni yashirish',
			'startup.copyDetails' => 'Tafsilotlarni nusxalash',
			'startup.detailsCopied' => 'Tafsilotlar buferga nusxalandi',
			'startup.uploadDetails' => 'Tafsilotlarni yuklash',
			'startup.repairStorage' => 'Saqlashni tiklash',
			'startup.repairTitle' => 'Saqlangan maʼlumotlar tikilsinmi?',
			'startup.repairBodyCommon' => 'Plezyning sozlamalar fayli shikastlangan va uni oʻqib boʻlmaydi. Tiklash barcha sozlamalarni standart holatiga qaytaradi.',
			'startup.repairBodyOneCredential' => 'Bitta saqlangan kirish maʼlumoti shikastlangan va uni oʻqib boʻlmaydi. Tiklash faqat uni olib tashlaydi; boshqa sozlamalaringizga tegilmaydi.',
			'startup.repairBodySignInsKept' => 'Serverlaringiz va profillaringiz tizimga kirgan holda qoladi.',
			'startup.repairBodySignInsLost' => 'Saqlangan kirish maʼlumotlaringizni himoya qiluvchi kalitni ushbu fayldan tiklab boʻlmaydi, shuning uchun har bir server va profilga qaytadan kirishingiz kerak boʻladi. Media serveringizdagi hech narsaga taʼsir qilmaydi.',
			'startup.repairBodySessionsUncertain' => 'Trekerlar (MAL, AniList, Simkl, Trakt) va Seerr alohida saqlanadi va ular saqlanib qolishi ham, yoʻqolishi ham mumkin. PlezyNG aynan nimani saqlaganini sizga xabar qiladi.',
			'startup.repairConfirm' => 'Tiklash',
			'startup.repairSucceeded' => 'Saqlash tiklandi',
			'startup.repairNeedsRestart' => 'Saqlash tiklandi — qayta ishga tushirish kerak',
			'startup.restartRequiredBody' => 'Maʼlumotlaringiz tiklandi, lekin PlezyNG ulardan foydalanishi uchun yangidan ishga tushishi kerak. PlezyNG-ni yoping va qayta oching.',
			'startup.quitPlezy' => 'PlezyNG-dan chiqish',
			'startup.repairFailed' => 'Tiklash amalga oshmadi',
			'startup.repairKeptSignIns' => 'Serverlaringiz va profillaringiz hali ham tizimga kirgan.',
			'startup.repairLostSignIns' => 'Saqlangan kirish maʼlumotlaringizni himoya qiluvchi kalitni tiklab boʻlmadi. Har bir server va profilga qaytadan kirishingiz kerak boʻladi.',
			'startup.repairLostSessions' => 'Kamida bitta treker yoki Seerr ulanishi yoʻqoldi va uni qayta ulash kerak.',
			'startup.backupTitle' => 'Shikastlangan faylning nusxasi saqlab qoʻyildi',
			'startup.backupWarning' => 'Unda kirish hisob maʼlumotlaringiz bor. Uni yuklamang yoki baham koʻrmang.',
			'startup.deleteBackup' => 'Nusxani oʻchirish',
			'startup.backupDeleted' => 'Nusxa oʻchirildi.',
			'startup.previousFailureTitle' => 'PlezyNG oxirgi marta ishga tushmadi',
			'licenses.relatedPackages' => 'Bogʻliq paketlar',
			'licenses.license' => 'Litsenziya',
			'licenses.licenseNumber' => ({required Object number}) => 'Litsenziya ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} litsenziya',
			'navigation.libraries' => 'Kutubxonalar',
			'navigation.downloads' => 'Yuklamalar',
			'navigation.liveTv' => 'Jonli TV',
			'navigation.explore' => 'Kashf qilish',
			'explore.mdblistShelves.manage' => '“Kashf qilish” bo‘limidagi javonlarni boshqarish',
			'explore.mdblistShelves.manageDescription' => 'Siz MDBList hesabinizdan listlar seçin və düzəlin',
			'explore.mdblistShelves.description' => 'MDBList hisobingizdagi ochiq film va serial ro‘yxatlarini tanlang. MDBList’da ro‘yxat yarating yoki nusxalang, so‘ng yangilang.',
			'explore.mdblistShelves.selected' => 'Seçkin qiyizlar',
			'explore.mdblistShelves.available' => 'Hesablar listlar',
			'explore.mdblistShelves.noLists' => 'Ochiq film yoki serial ro‘yxatlari topilmadi. MDBList’da ro‘yxat yarating yoki nusxalang, so‘ng yangilang.',
			'explore.mdblistShelves.displayName' => 'Shelf Display Nominadi',
			'explore.mdblistShelves.nameHint' => 'U\'zayda kaynlar listni ismi kullanmaqdan qurt.',
			'explore.mdblistShelves.add' => 'Shell ko‘z',
			'explore.mdblistShelves.save' => 'Tadiqlarga saladi',
			_ => null,
		} ?? switch (path) {
			'explore.mdblistShelves.moveUp' => ({required Object title}) => '${title}ni yuqoriga ko‘chirish',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => '${title} qaytadi',
			'explore.mdblistShelves.unavailable' => 'Bu list ishat. Bu listini qaytadi o\'zingiz.',
			'explore.mdblistShelves.rateLimited' => 'MDBList ismi limiti qadi. lüthi qaytarga.',
			'explore.mdblistShelves.loadFailed' => 'U\'zlar ko‘zlar. Sizga qaytarga ko‘z.',
			'explore.mdblistShelves.saveFailed' => 'U\'zlarga qaytadi. lütfen qaytadi!',
			'explore.mdblistShelves.accountChanged' => 'Hisob yoki profil o‘zgardi. Bu sozlamalarni qayta oching.',
			'explore.mdblistShelves.settingsUnreadable' => 'U\'zizlar bo\'zlar bo\'qlar. Bu ayarlar yasanlar yasan.',
			'explore.title' => 'Kashf qilish',
			'explore.selectSource' => 'Manbani tanlang',
			'explore.rows.watchlist' => 'Tomosha roʻyxati',
			'explore.rows.recommendedMovies' => 'Tavsiya etilgan filmlar',
			'explore.rows.recommendedShows' => 'Tavsiya etilgan seriallar',
			'explore.rows.trendingMovies' => 'Ommabop filmlar',
			'explore.rows.trendingShows' => 'Ommabop seriallar',
			'explore.rows.popularMovies' => 'Mashhur filmlar',
			'explore.rows.popularShows' => 'Mashhur seriallar',
			'explore.rows.trendingAnime' => 'Ommabop anime',
			'explore.rows.suggestedAnime' => 'Tavsiya etilgan anime',
			'explore.rows.airingAnime' => 'Efirga uzatilayotgan eng yaxshi anime',
			'explore.rows.popularAnime' => 'Eng mashhur anime',
			'explore.rows.trending' => 'Ommaboplar',
			'explore.rows.upcomingMovies' => 'Kutilayotgan filmlar',
			'explore.rows.upcomingShows' => 'Kutilayotgan seriallar',
			'explore.status.airing' => 'Efirda',
			'explore.status.ended' => 'Tugallandi',
			'explore.status.canceled' => 'Bekor qilindi',
			'explore.status.upcoming' => 'Kutilmoqda',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} qism', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} qism', ), 
			'explore.cast' => 'Aktyorlar',
			'explore.characters' => 'Qahramonlar',
			'explore.addToWatchlist' => 'Tomosha roʻyxatiga qoʻshish',
			'explore.removeFromWatchlist' => 'Tomosha roʻyxatidan oʻchirish',
			'explore.addedToWatchlist' => 'Tomosha roʻyxatiga qoʻshildi',
			'explore.removedFromWatchlist' => 'Tomosha roʻyxatidan olib tashlandi',
			'explore.watchlistUpdateFailed' => 'Tomosha roʻyxatini yangilab boʻlmadi',
			'explore.watchlistNoMatch' => 'Bu elementni tomosha roʻyxatiga moslab boʻlmadi',
			'explore.notInLibrary' => 'Kutubxonangizda yoʻq',
			'explore.inTheseLibraries' => 'Ushbu kutubxonalarda bor',
			'explore.checkingLibrary' => 'Kutubxona tekshirilmoqda...',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} serverni tekshirib boʻlmadi', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} serverni tekshirib boʻlmadi', ), 
			'explore.emptyTitle' => 'Hali bu yerda hech narsa yoʻq',
			'explore.emptyMessage' => ({required Object source}) => '${source} manbasidan olingan qatorlar bu yerda koʻrinadi.',
			'explore.searchHint' => ({required Object source}) => '${source} ichidan qidirish',
			'explore.searchEmpty' => ({required Object query}) => '"${query}" boʻyicha natija topilmadi',
			'explore.searchPrompt' => ({required Object source}) => '${source} orqali filmlar va seriallarni qidiring.',
			'explore.searchFailed' => 'Qidiruv xatoligi. Ulanishni tekshiring.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} mashhur',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} efirda',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} baholangan',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} ommabop',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} ${season} mavsumida',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} kishi tomosha qilmoqda',
			'explore.badge.available' => 'Mavjud',
			'explore.badge.partiallyAvailable' => 'Qisman mavjud',
			'explore.badge.availableIn4k' => '4K mavjud',
			'explore.badge.requested' => 'Soʻralgan',
			'explore.badge.pendingApproval' => 'Tasdiq kutilmoqda',
			'explore.badge.processing' => 'Ishlanmoqda',
			'explore.badge.declined' => 'Rad etilgan',
			'explore.badge.requestFailed' => 'Soʻrov amalga oshmadi',
			'explore.badge.requested4k' => '4K soʻralgan',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} mavsum',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => '${episode}-qism ${duration} ichida',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'Keyingisi ${duration} ichida',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} qism',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} daq/qism',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} roʻyxatda',
			'explore.stats.viewersDay' => ({required Object n}) => 'Bugun ${n} kishi tomosha qildi',
			'explore.stats.viewersWeek' => ({required Object n}) => 'Bu hafta ${n} kishi tomosha qildi',
			'explore.stats.viewersMonth' => ({required Object n}) => 'Bu oy ${n} kishi tomosha qildi',
			'explore.stats.viewersYear' => ({required Object n}) => 'Bu yil ${n} kishi tomosha qildi',
			'explore.stats.viewersAllTime' => ({required Object n}) => '${n} kishi tomosha qilgan',
			'explore.stats.planning' => ({required Object n}) => '${n} kishi tomosha qilishni rejalashtirmoqda',
			'explore.stats.favorited' => ({required Object n}) => '${n} ta tanlangan',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} tomosha qilishni toʻxtatgan',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ta izoh', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ta izoh', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} ta ovoz',
			'explore.stats.watching' => ({required Object n}) => '${n} kishi tomosha qilmoqda',
			'explore.stats.completed' => ({required Object n}) => '${n} kishi yakunlagan',
			'explore.stats.onHold' => ({required Object n}) => '${n} kishi toʻxtatib turibdi',
			'explore.stats.dropped' => ({required Object n}) => '${n} kishi toʻxtatgan',
			'explore.season.winter' => 'Qish',
			'explore.season.spring' => 'Bahor',
			'explore.season.summer' => 'Yoz',
			'explore.season.fall' => 'Kuz',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'TV',
			'explore.format.tvShort' => 'Qisqa TV',
			'explore.format.movie' => 'Film',
			'explore.format.special' => 'Maxsus',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => 'Musiqa',
			'explore.format.other' => 'Boshqa',
			'explore.sourceMaterial.original' => 'Asl',
			'explore.sourceMaterial.manga' => 'Manga',
			'explore.sourceMaterial.lightNovel' => 'Yengil roman',
			'explore.sourceMaterial.novel' => 'Roman',
			'explore.sourceMaterial.visualNovel' => 'Vizual roman',
			'explore.sourceMaterial.game' => 'Oʻyin',
			'explore.sourceMaterial.webComic' => 'Veb-komiks',
			'explore.sourceMaterial.musicRelease' => 'Musiqa',
			'explore.sourceMaterial.otherMedia' => 'Boshqa',
			'explore.creditRole.actor' => 'Aktyor',
			'explore.creditRole.director' => 'Rejissyor',
			'explore.creditRole.writer' => 'Ssenarist',
			'explore.creditRole.producer' => 'Prodyuser',
			'explore.creditRole.creator' => 'Muallif',
			'explore.creditRole.composer' => 'Bastakor',
			'explore.relation.prequel' => 'Prikvel',
			'explore.relation.sequel' => 'Sikvel',
			'explore.relation.sideStory' => 'Yon hikoya',
			'explore.relation.spinOff' => 'Spin-off',
			'explore.relation.alternativeVersion' => 'Muqobil versiya',
			'explore.relation.summary' => 'Xulosa',
			'explore.relation.parentStory' => 'Asosiy hikoya',
			'explore.relation.adaptation' => 'Adaptatsiya',
			'explore.relation.other' => 'Bogʻliq',
			'explore.broadcast' => ({required Object day, required Object time}) => '${day} kuni soat ${time} da efirga uzatiladi',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => '${day} kuni soat ${time} ${timezone} da efirga uzatiladi',
			'explore.detail.originalTitle' => 'Asl nomi',
			'explore.detail.alsoKnownAs' => 'Boshqa nomi bilan ham tanilgan',
			'explore.detail.studios' => 'Studiyalar',
			'explore.detail.country' => 'Mamlakat',
			'explore.detail.language' => 'Til',
			'explore.detail.released' => 'Chiqarilgan',
			'explore.detail.physicalRelease' => 'Diskda',
			'explore.detail.ended' => 'Yakunlangan',
			'explore.detail.addedOn' => ({required Object date}) => '${date} da qoʻshilgan',
			'explore.detail.yourRating' => 'Sizning bahoyingiz',
			'explore.detail.budget' => 'Byudjet',
			'explore.detail.revenue' => 'Kassa yigʻimi',
			'explore.detail.contentAdvisory' => 'Yosh cheklovi',
			'explore.detail.tags' => 'Teglar',
			'explore.detail.revealSpoilerTags' => 'Spoyler teglarini koʻrsatish',
			'explore.detail.links' => 'Havolalar',
			'explore.detail.watchOn' => 'Tomosha qilish',
			'explore.detail.watchTrailer' => 'Treylerni koʻrish',
			'explore.detail.openOn' => ({required Object site}) => '${site} da ochish',
			'explore.detail.crew' => 'Jamoa',
			'explore.detail.ratings' => 'Baholar',
			'explore.detail.schedule' => 'Jadval',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} foydalanuvchi tavsiya qilgan', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} foydalanuvchi tavsiya qilgan', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => '${who} tavsiya qilgan',
			'explore.detail.favoritedBy' => ({required Object who}) => '${who} tanlanganlarga qoʻshgan',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} hali efirga chiqmagan',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'Tomoshabinlarning ${percent} tavsiya qilgan',
			'explore.detail.relatedTitles' => 'Bogʻliq nomlar',
			'explore.detail.background' => 'Orqa fon',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ta natija', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ta natija', ), 
			'liveTv.title' => 'Jonli TV',
			'liveTv.guide' => 'Dasturlar jadvali',
			'liveTv.noChannels' => 'Mavjud kanallar yoʻq',
			'liveTv.noDvr' => 'Serverda DVR sozlanmagan',
			'liveTv.serverUnavailable' => 'Jonli TV serveri mavjud emas.',
			'liveTv.serverNotConnected' => 'Jonli TV serveriga ulanmagan.',
			'liveTv.noPrograms' => 'Dastur haqida maʼlumot yoʻq',
			'liveTv.liveStreamFailed' => 'Jonli oqim xatoligi',
			'liveTv.unknownProgram' => 'Nomaʼlum dastur',
			'liveTv.timelineLiveProgram' => 'Live program (playback bu programdan o‘zadi)',
			'liveTv.timelineBuffer' => 'Bufer vaqt chizig‘i',
			'liveTv.timelineUnavailable' => 'Timinni ishatta',
			'liveTv.timelineEstimated' => 'Playback bilan bilan bilan',
			'liveTv.timelinePending' => 'Tadiqga islan',
			'liveTv.timelineStale' => 'Dastur jadvali eskirgan bo‘lishi mumkin',
			'liveTv.unknownHub' => 'Nomaʼlum',
			'liveTv.unknownError' => 'Nomaʼlum xatolik',
			'liveTv.channelNumber' => ({required Object number}) => '${number}-kanal',
			'liveTv.unknownChannel' => 'Nomaʼlum kanal',
			'liveTv.live' => 'JONLI EFIR',
			'liveTv.premiereBadge' => 'Yeni',
			'liveTv.reloadGuide' => 'Jadvalni yangilash',
			'liveTv.searchGuide' => 'Dasturlar jadvalidan qidirish',
			'liveTv.searchHint' => 'Kanal va dasturlarni qidirish',
			'liveTv.searchNoResults' => ({required Object query}) => '"${query}" boʻyicha moslik topilmadi',
			'liveTv.channelsSection' => 'Kanallar',
			'liveTv.programsSection' => 'Dasturlar',
			'liveTv.now' => 'Hozir',
			'liveTv.today' => 'Bugun',
			'liveTv.tomorrow' => 'Ertaga',
			'liveTv.midnight' => 'Yarim tun',
			'liveTv.overnight' => 'Tunda',
			'liveTv.morning' => 'Ertalab',
			'liveTv.daytime' => 'Kunduzi',
			'liveTv.evening' => 'Kechqurun',
			'liveTv.lateNight' => 'Tunda',
			'liveTv.whatsOn' => 'Hozir nima efirda?',
			'liveTv.watchChannel' => 'Kanalni tomosha qilish',
			'liveTv.favorites' => 'Tanlanganlar',
			'liveTv.reorderFavorites' => 'Tanlanganlarni tartiblash',
			'liveTv.noFavoriteChannels' => 'Sevimli kanallar yoʻq',
			'liveTv.noFavoriteChannelsHint' => 'Barcha kanallarni koʻrsating, soʻng kanalni sevimlilarga qoʻshish uchun uni bosib turing.',
			'liveTv.showAllChannels' => 'Barcha kanallarni koʻrsatish',
			'liveTv.favoritesLoadFailed' => 'Tanlanganlarni yuklab boʻlmadi. Ulanishni tekshirib, qayta urinib koʻring.',
			'liveTv.favoritesUpdateFailed' => 'Tanlanganlarni yangilab boʻlmadi.',
			'liveTv.joinSession' => 'Davom etayotgan seansga qoʻshilish',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Boshidan tomosha qilish (${minutes} daq ilgari)',
			'liveTv.watchLive' => 'Jonli efirni tomosha qilish',
			'liveTv.goToLive' => 'Jonli efirga oʻtish',
			'liveTv.record' => 'Yozib olish',
			'liveTv.recordEpisode' => 'Qismni yozib olish',
			'liveTv.recordSeries' => 'Serialni yozib olish',
			'liveTv.recordOptions' => 'Yozib olish parametrlari',
			'liveTv.saveTo' => 'Shu yerga saqlash',
			'liveTv.recordings' => 'Yozib olinganlar',
			'liveTv.scheduledRecordings' => 'Rejalashtirilganlar',
			'liveTv.recordingRules' => 'Yozib olish qoidalari',
			'liveTv.noScheduledRecordings' => 'Rejalashtirilgan yozuvlar yoʻq',
			'liveTv.manageRecording' => 'Yozuvni boshqarish',
			'liveTv.cancelRecording' => 'Yozishni bekor qilish',
			'liveTv.cancelRecordingTitle' => 'Yozish toʻxtatilsinmi?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} endi yozib olinmaydi.',
			'liveTv.deleteRule' => 'Qoidani oʻchirish',
			'liveTv.deleteRuleTitle' => 'Yozib olish qoidasi oʻchirilsinmi?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => '${title} serialining keyingi qismlari yozib olinmaydi.',
			'liveTv.recordingScheduled' => 'Yozib olish rejalashtirildi',
			'liveTv.alreadyScheduled' => 'Ushbu dastur avvaldan rejalashtirilgan',
			'liveTv.dvrAdminRequired' => 'DVR sozlamalari administrator huquqini talab qiladi',
			'liveTv.recordingFailed' => 'Yozib olishni rejalashtirib boʻlmadi',
			'liveTv.recordingTargetMissing' => 'Yozib olinadigan kutubxona aniqlanmadi',
			'liveTv.recordNotAvailable' => 'Ushbu dasturni yozib olib boʻlmaydi',
			'liveTv.recordingCancelled' => 'Yozib olish bekor qilindi',
			'liveTv.recordingRuleDeleted' => 'Yozib olish qoidasi oʻchirildi',
			'liveTv.processRecordingRules' => 'Qoidalarni qayta baholash',
			'liveTv.recordingInProgress' => 'Hozir yozib olinmoqda',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} rejalashtirilgan',
			'liveTv.editRule' => 'Qoidani tahrirlash',
			'liveTv.editRuleAction' => 'Tahrirlash',
			'liveTv.recordingRuleUpdated' => 'Yozib olish qoidasi yangilandi',
			'liveTv.guideReloadRequested' => 'Jadvalni yangilash soʻraldi',
			'liveTv.guideReloadFailed' => 'Dasturlar jadvalini yangilab boʻlmadi',
			'liveTv.rulesProcessRequested' => 'Qoidalarni qayta baholash soʻraldi',
			'liveTv.rulesProcessFailed' => 'Yozib olish qoidalarini qayta baholab boʻlmadi',
			'liveTv.recordShow' => 'Shouni yozib olish',
			'liveTv.recordSettings.startEarly' => 'Erta boshlash (soniya)',
			'liveTv.recordSettings.endLate' => 'Kech tugatish (soniya)',
			'liveTv.recordSettings.newOnly' => 'Faqat yangi epizodlar',
			'liveTv.recordSettings.anyChannel' => 'Istalgan kanaldan yozib olish',
			'liveTv.recordSettings.anyTime' => 'Istalgan vaqtda yozib olish',
			'liveTv.recordSettings.skipInLibrary' => 'Kutubxonada mavjud epizodlarni oʻtkazib yuborish',
			'liveTv.recordSettings.keepUpTo' => 'Saqlanadigan epizodlar',
			'liveTv.recordSettings.keepUpToHint' => '0 barcha epizodlarni saqlaydi',
			'liveTv.startingInMinutes' => ({required Object minutes}) => '${minutes} daqiqadan keyin boshlanadi',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day}, soat ${time} da',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product} Jonli TV ijrosi uchun notoʻgʻri maʼlumot qaytardi',
			'liveTv.failedToStartChannel' => 'Jonli kanalni boshlab boʻlmadi',
			'liveTv.failedToBuildStreamUrl' => 'Oqim URL-ini tuzib boʻlmadi',
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'Kanalni ishga tushirib boʻlmadi: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'Kanalni almashtirib boʻlmadi: ${reason}',
			'collections.title' => 'Toʻplamlar',
			'collections.collection' => 'Toʻplam',
			'collections.empty' => 'Toʻplam boʻsh',
			'collections.deleteCollection' => 'Toʻplamni oʻchirish',
			'collections.deleteConfirm' => ({required Object title}) => '"${title}" oʻchirilsinmi? Bu amalni ortga qaytarib boʻlmaydi.',
			'collections.deleted' => 'Toʻplam oʻchirildi',
			'collections.deleteFailed' => 'Toʻplamni oʻchirib boʻlmadi',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Toʻplamni oʻchirish xatoligi: ${error}',
			'collections.selectCollection' => 'Toʻplamni tanlash',
			'collections.collectionName' => 'Toʻplam nomi',
			'collections.enterCollectionName' => 'Toʻplam nomini kiriting',
			'collections.addedToCollection' => 'Toʻplamga qoʻshildi',
			'collections.errorAddingToCollection' => 'Toʻplamga qoʻshib boʻlmadi',
			'collections.created' => 'Toʻplam yaratildi',
			'collections.removeFromCollection' => 'Toʻplamdan oʻchirish',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => '"${title}" ushbu toʻplamdan oʻchirilsinmi?',
			'collections.removedFromCollection' => 'Toʻplamdan oʻchirildi',
			'collections.removeFromCollectionFailed' => 'Toʻplamdan oʻchirib boʻlmadi',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Oʻchirish xatoligi: ${error}',
			'collections.searchCollections' => 'Toʻplamlardan qidirish...',
			'playlists.title' => 'Ijro roʻyxatlari',
			'playlists.playlist' => 'Ijro roʻyxati',
			'playlists.noPlaylists' => 'Ijro roʻyxatlari topilmadi',
			'playlists.create' => 'Ijro roʻyxatini yaratish',
			'playlists.playlistName' => 'Ijro roʻyxati nomi',
			'playlists.enterPlaylistName' => 'Roʻyxat nomini kiriting',
			'playlists.delete' => 'Ijro roʻyxatini oʻchirish',
			'playlists.removeItem' => 'Roʻyxatdan oʻchirish',
			'playlists.smartPlaylist' => 'Aqlli ijro roʻyxati',
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} element', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} element', ), 
			'playlists.emptyPlaylist' => 'Ushbu roʻyxat boʻsh',
			'playlists.deleteConfirm' => 'Ijro roʻyxati oʻchirilsinmi?',
			'playlists.deleteMessage' => ({required Object name}) => '"${name}" oʻchirilsinmi?',
			'playlists.created' => 'Ijro roʻyxati yaratildi',
			'playlists.deleted' => 'Ijro roʻyxati oʻchirildi',
			'playlists.itemAdded' => 'Roʻyxatga qoʻshildi',
			'playlists.itemRemoved' => 'Roʻyxatdan oʻchirildi',
			'playlists.selectPlaylist' => 'Roʻyxatni tanlash',
			'playlists.searchPlaylists' => 'Ijro roʻyxatlaridan qidirish...',
			'playlists.errorCreating' => 'Roʻyxatni yaratib boʻlmadi',
			'playlists.errorDeleting' => 'Roʻyxatni oʻchirib boʻlmadi',
			'playlists.errorLoading' => 'Roʻyxatlarni yuklab boʻlmadi',
			'playlists.errorAdding' => 'Roʻyxatga qoʻshib boʻlmadi',
			'playlists.errorReordering' => 'Qayta tartiblab boʻlmadi',
			'playlists.errorRemoving' => 'Roʻyxatdan oʻchirib boʻlmadi',
			'music.goToAlbum' => 'Albomga oʻtish',
			'music.goToArtist' => 'Ijrochiga oʻtish',
			'music.instantMix' => 'Tezkor miks',
			'music.playNext' => 'Keyingisini ijro etish',
			'music.addToQueue' => 'Navbatga qoʻshish',
			'music.discNumber' => ({required Object n}) => '${n}-disk',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tarona', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tarona', ), 
			'music.nowPlaying' => 'Hozir ijro etilmoqda',
			'music.playingFrom' => ({required Object title}) => '${title} manbasidan',
			'music.queue' => 'Navbat',
			'music.clearQueue' => 'Navbatni tozalash',
			'music.lyrics' => 'Musiqa matni',
			'music.visualizer' => 'vizualiz',
			'music.visualizerProfileLoading' => 'U‘qot bilan analizi...',
			'music.visualizerAmbientMotion' => 'Ummatik Movisi',
			'music.visualizerPlexLoudness' => 'Plex qiziziziz',
			'music.visualizerPreviousPreset' => 'Oldingi vizual uslub',
			'music.visualizerNextPreset' => 'Keyingi vizual uslub',
			'music.visualizerPresetAurora' => 'Qutb yog‘dusi',
			'music.visualizerPresetBloom' => 'Gullash',
			'music.visualizerPresetOrbitals' => 'Orbitadi',
			'music.visualizerPresetPrism' => 'Prizma',
			'music.visualizerPresetTunnel' => 'Tünel',
			'music.visualizerPresetTrackMap' => 'Mapadi',
			'music.noLyrics' => 'Musiqa matni yoʻq',
			'music.sleepTimer' => 'Uyqu taymeri',
			'music.sleepTimerEndOfTrack' => 'Taronaning oxiri',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} daqiqa', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} daqiqa', ), 
			'music.stopPlayback' => 'Ijroni toʻxtatish',
			'music.previousTrack' => 'Oldingi tarona',
			'music.nextTrack' => 'Keyingi tarona',
			'music.repeat' => 'Takrorlash',
			'music.repeatAll' => 'Barchasini takrorlash',
			'music.repeatOne' => 'Birtasini takrorlash',
			'music.instantMixNoServer' => 'Tezkor miks uchun hech qanday server mavjud emas',
			'music.instantMixFailed' => 'Tezkor miksni yuklab boʻlmadi',
			'music.instantMixEmpty' => 'Tezkor miks hech qanday taronani qaytarmadi',
			'music.noAudioUrl' => ({required Object track}) => '${track} uchun audio URL mavjud emas',
			'music.discography.singlesAndEps' => 'Singllar va EP',
			'music.discography.live' => 'Jonli',
			'music.discography.compilations' => 'Toʻplamlar',
			'watchTogether.title' => 'Birgalikda tomosha qilish',
			'watchTogether.description' => 'Doʻstlaringiz va oilangiz bilan birga tomosha qiling',
			'watchTogether.createRoom' => 'Xona yaratish',
			'watchTogether.creatingRoom' => 'Xona yaratilmoqda...',
			'watchTogether.joinRoom' => 'Xonaga qoʻshilish',
			'watchTogether.joiningRoom' => 'Xonaga qoʻshilmoqda...',
			'watchTogether.connecting' => 'Ulanmoqda...',
			'watchTogether.relayPublic' => 'Xonalar ommaviy Open Watch Party relelaridan foydalanadi.',
			'watchTogether.relayCustom' => ({required Object url}) => 'Xonalar ${url} manzilidagi relengizdan foydalanadi.',
			'watchTogether.recentRooms' => 'Yaqindagi xonalar',
			'watchTogether.roomActions' => 'Xona amallari',
			'watchTogether.renameRoom' => 'Xona nomini oʻzgartirish',
			'watchTogether.removeRoom' => 'Oʻchirish',
			'watchTogether.enterRoomCode' => 'Tashkilotchidan olingan 6 belgili kodni kiriting.',
			'watchTogether.roomCode' => 'Xona kodi',
			'watchTogether.paste' => 'Qoʻyish',
			'watchTogether.noCodeInClipboard' => 'Almashish buferida xona kodi yoʻq',
			'watchTogether.copyCode' => 'Kodni nusxalash',
			'watchTogether.codeCopied' => 'Xona kodi nusxalandi',
			'watchTogether.shareInvite' => 'Taklifni ulashish',
			'watchTogether.inviteCopied' => 'Taklif nusxalandi. Uni xabarga joylashtiring.',
			'watchTogether.inviteMessage' => ({required Object code}) => 'PlezyNG-dagi "Birgalikda tomosha qilish" xonamga qoʻshiling: "Birgalikda tomosha qilish" boʻlimini oching, "Xonaga qoʻshilish" tugmasini tanlang va ${code} kodini kiriting.',
			'watchTogether.openSessionControls' => 'Boshqaruv elementlarini ochish',
			'watchTogether.reconnecting' => 'Qayta ulanmoqda...',
			'watchTogether.reconnectingDescription' => 'Ulanish uzildi. Xonaga avtomatik ravishda qayta qoʻshilasiz.',
			'watchTogether.connected' => 'Ulandi',
			'watchTogether.disconnected' => 'Uzildi',
			'watchTogether.youAreHost' => 'Siz tashkilotchisiz',
			'watchTogether.hostedBy' => ({required Object name}) => 'Tashkilotchi: ${name}',
			'watchTogether.hostControlsPlayback' => 'Ijroni tashkilotchi boshqaradi',
			'watchTogether.anyoneCanControl' => 'Ijroni har kim boshqara oladi',
			'watchTogether.roomLocked' => 'Xona qulflangan',
			'watchTogether.nowPlaying' => 'Hozir ijro etilmoqda',
			'watchTogether.nothingPlaying' => 'Hech narsa ijro etilmayapti',
			'watchTogether.nothingPlayingHost' => 'Xona bilan ulashish uchun istalgan kutubxonadan biror narsani ijro eting.',
			'watchTogether.nothingPlayingGuest' => 'Tashkilotchi biror narsani ijro etganda, u shu yerda ochiladi.',
			'watchTogether.notShareable' => 'Bu video katalogdagi hech bir nomga mos kelmadi, shuning uchun uni faqat shu serverga kirish huquqi bor foydalanuvchilar ijro eta oladi.',
			'watchTogether.searching' => 'Bu video kutubxonalaringizdan qidirilmoqda...',
			'watchTogether.yourCopy' => 'Sizning nusxangiz',
			'watchTogether.sharingYourCopy' => 'Siz oʻz nusxangizni ulashyapsiz',
			'watchTogether.playingOtherLength' => ({required Object difference}) => 'Nusxangiz ijro etilmoqda, ${difference}',
			'watchTogether.mismatchTitle' => 'Nusxangizning uzunligi boshqacha',
			'watchTogether.mismatchDescription' => ({required Object difference}) => 'Eng yaqin nusxangiz xonadagi videodan ${difference}. Bu boshqa montaj yoki versiya boʻlishi mumkin.',
			'watchTogether.playAnyway' => 'Baribir ijro etish',
			'watchTogether.chooseAnotherCopy' => 'Boshqa nusxani tanlash',
			'watchTogether.dontPlay' => 'Ijro etmaslik',
			'watchTogether.unavailableTitle' => 'Sizda bu video yoʻq',
			'watchTogether.unavailableDescription' => 'PlezyNG uni kutubxonalaringizdan topa olmadi. Nusxani oʻzingiz tanlang yoki qaytadan qidiring.',
			'watchTogether.chooseCopy' => 'Nusxani tanlash',
			'watchTogether.searchAgain' => 'Qaytadan qidirish',
			'watchTogether.noCandidates' => 'Kutubxonalaringizda nusxalar topilmadi.',
			'watchTogether.choiceFailed' => 'Bu nusxani xona uchun ijro etib boʻlmadi',
			'watchTogether.lengthLonger' => ({required Object duration}) => '${duration} uzunroq',
			'watchTogether.lengthShorter' => ({required Object duration}) => '${duration} qisqaroq',
			'watchTogether.lengthSame' => 'Uzunligi bir xil',
			'watchTogether.lengthUnknown' => 'Uzunligi nomaʼlum',
			'watchTogether.joinCurrentPlayback' => 'Joriy ijroga qoʻshilish',
			'watchTogether.joinCurrentPlaybackDescription' => 'Tashkilotchi koʻrayotgan joyga oʻting',
			'watchTogether.stopMedia' => 'Videoni hamma uchun toʻxtatish',
			'watchTogether.syncOffset' => 'Sinxronlash siljishi',
			'watchTogether.syncOffsetDescription' => 'Videongiz xonadan oldinda yoki orqada boʻlsa, uni siljiting.',
			'watchTogether.offsetHint' => ({required Object difference}) => 'Nusxangiz xonadagi videodan ${difference}.',
			'watchTogether.applyDifference' => ({required Object offset}) => 'Qoʻllash: ${offset}',
			'watchTogether.offsetMinusSecond' => '-1 s',
			'watchTogether.offsetMinusTenth' => '-100 ms',
			'watchTogether.offsetPlusTenth' => '+100 ms',
			'watchTogether.offsetPlusSecond' => '+1 s',
			'watchTogether.participants' => 'Ishtirokchilar',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ishtirokchi', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ishtirokchi', ), 
			'watchTogether.hostBadge' => 'TASHKILOTCHI',
			'watchTogether.nameYou' => ({required Object name}) => '${name} (Siz)',
			'watchTogether.playerIdle' => 'Nofaol',
			'watchTogether.playerLoading' => 'Yuklanmoqda',
			'watchTogether.playerReady' => 'Tayyor',
			'watchTogether.playerBuffering' => 'Buferlanmoqda',
			'watchTogether.matchSearching' => 'Qidirilmoqda',
			'watchTogether.matchMatched' => 'Video bor',
			'watchTogether.matchMismatched' => 'Uzunligi boshqacha',
			'watchTogether.matchUnavailable' => 'Video yoʻq',
			'watchTogether.participantOffset' => ({required Object offset}) => 'Siljish: ${offset}',
			'watchTogether.makeHost' => 'Tashkilotchi qilish',
			'watchTogether.makeHostQuestion' => 'Tashkilotchi oʻtkazilsinmi?',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} ijroni boshqaradi va seansni hamma uchun olib boradi.',
			'watchTogether.transfer' => 'Oʻtkazish',
			'watchTogether.removeParticipant' => 'Xonadan chiqarish',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => '${name} chiqarilsinmi?',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} xonadan chiqariladi. Xonani qulflamasangiz, u kod orqali qayta qoʻshila oladi.',
			'watchTogether.remove' => 'Chiqarish',
			'watchTogether.roomSettings' => 'Xona sozlamalari',
			'watchTogether.letEveryoneControl' => 'Hammaga ijroni boshqarishga ruxsat berish',
			'watchTogether.lockRoom' => 'Xonani qulflash',
			'watchTogether.lockRoomDescription' => 'Yangi ishtirokchilar qoʻshila olmaydi',
			'watchTogether.leaveRoom' => 'Xonadan chiqish',
			'watchTogether.leaveRoomQuestion' => 'Xonadan chiqilsinmi?',
			'watchTogether.leaveRoomConfirm' => 'Xona kodi orqali qayta qoʻshilishingiz mumkin.',
			'watchTogether.leave' => 'Chiqish',
			'watchTogether.endRoom' => 'Xonani yakunlash',
			'watchTogether.endRoomQuestion' => 'Xona yakunlansinmi?',
			'watchTogether.endRoomConfirm' => 'Bu xonani hamma uchun yakunlaydi.',
			'watchTogether.end' => 'Yakunlash',
			'watchTogether.playBlockedTitle' => 'Ijro boshlanmadi',
			'watchTogether.playBlockedDescription' => 'Xona bilan birga tomosha qilishni boshlash uchun ijro tugmasini bosing.',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} ijro tugmasini bosdi',
			'watchTogether.notices.playbackStarted' => 'Ijro boshlandi',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} toʻxtatdi',
			'watchTogether.notices.playbackPaused' => 'Ijro pauza qilindi',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} ${position} ga oʻtdi',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => '${position} ga oʻtildi',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} tezlikni ${speed} ga oʻrnatdi',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => 'Tezlik ${speed} ga oʻrnatildi',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} "${title}" ijrosini boshladi',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => 'Hozir ijro etilmoqda: ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} videoni toʻxtatdi',
			'watchTogether.notices.mediaStopped' => 'Video toʻxtatildi',
			'watchTogether.notices.waitingFor' => ({required Object name}) => '${name} kutilmoqda...',
			'watchTogether.notices.waitingForSomeone' => 'Kimdir yetib olishi kutilmoqda...',
			'watchTogether.notices.finished' => 'Tugadi',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} endi tashkilotchi',
			'watchTogether.notices.youAreNowHost' => 'Endi tashkilotchi sizsiz',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} qoʻshildi',
			'watchTogether.notices.left' => ({required Object name}) => '${name} chiqdi',
			'watchTogether.notices.controlRefused' => 'Ijroni faqat tashkilotchi boshqara oladi',
			'watchTogether.notices.searchFailed' => 'Baʼzi serverlarda xona videosini qidirib boʻlmadi',
			'watchTogether.notices.playBlocked' => 'Boshlash uchun ijro tugmasini bosing',
			'watchTogether.notices.shareFailed' => 'Bu videoni xona bilan ulashib boʻlmadi',
			'watchTogether.notices.downloadNotShared' => 'Server oflayn boʻlganda yuklamalar xona bilan ulashilmaydi',
			'watchTogether.notices.openFailed' => 'Xona videosini ochib boʻlmadi',
			'watchTogether.ended.ended' => 'Tashkilotchi xonani yakunladi',
			'watchTogether.ended.kicked' => 'Siz xonadan chiqarildingiz',
			'watchTogether.ended.expired' => 'Xona muddati tugadi',
			'watchTogether.ended.replaced' => 'Siz bu xonaga boshqa qurilmada qoʻshildingiz',
			'watchTogether.ended.lost' => 'Xona bilan aloqa uzildi',
			'watchTogether.errors.invalidCode' => 'Bu xona kodi emas. Kodlar 6 ta harf va raqamdan iborat boʻlib, ularda 0, 1, I, L yoki O boʻlmaydi.',
			'watchTogether.errors.roomNotFound' => 'Bunday kodli xona yoʻq. U yakunlangan boʻlishi mumkin.',
			'watchTogether.errors.roomFull' => 'Bu xona toʻla.',
			'watchTogether.errors.roomLocked' => 'Tashkilotchi bu xonani qulflagan.',
			'watchTogether.errors.relayFull' => 'Birgalikda tomosha qilish xizmati hozir band. Keyinroq qaytadan urinib koʻring.',
			'watchTogether.errors.unreachable' => 'Birgalikda tomosha relesiga ulanib boʻlmadi. Ulanishni tekshiring.',
			'watchTogether.errors.rateLimited' => 'Urinishlar juda koʻp. Biroz kuting va qaytadan urinib koʻring.',
			'watchTogether.errors.clientBlocked' => 'PlezyNG-ning bu versiyasi reledan foydalana olmaydi. Ilovani yangilang.',
			'watchTogether.errors.forbidden' => 'Buni faqat tashkilotchi qila oladi.',
			'watchTogether.errors.notInRoom' => 'Siz xonada emassiz.',
			'watchTogether.errors.alreadyInRoom' => 'Siz allaqachon xonadasiz.',
			'watchTogether.errors.resumeFailed' => 'Xonaga qayta qoʻshilib boʻlmadi.',
			'watchTogether.errors.unsupported' => 'Rele buni qoʻllab-quvvatlamaydi.',
			'watchTogether.errors.generic' => 'Nimadir xato ketdi. Qaytadan urinib koʻring.',
			'watchTogether.untitledEpisode' => ({required Object number}) => '${number}-qism',
			'downloads.title' => 'Yuklamalar',
			'downloads.manage' => 'Boshqarish',
			'downloads.tvShows' => 'TV Shoular',
			'downloads.movies' => 'Filmlar',
			'downloads.music' => 'Musiqa',
			'downloads.tracksQueued' => ({required Object count}) => '${count} tarona yuklash navbatiga qoʻshildi',
			'downloads.noDownloads' => 'Hali yuklamalar yoʻq',
			'downloads.noDownloadsDescription' => 'Yuklangan fayllar oflayn koʻrish uchun bu yerda koʻrinadi',
			'downloads.downloadNow' => 'Yuklab olish',
			'downloads.deleteDownload' => 'Yuklamani oʻchirish',
			'downloads.retryDownload' => 'Yuklashni qaytadan urinish',
			'downloads.downloadQueued' => 'Yuklash navbatga qoʻyildi',
			'downloads.downloadResumed' => 'Yuklash davom ettirildi',
			'downloads.serverErrorBitrate' => 'Server xatoligi: fayl tezlik cheklovidan oshgan boʻlishi mumkin',
			'downloads.storageFull' => 'Boʻsh xotirani saqlash uchun yuklashlar toʻxtatildi. Joy boʻshating yoki boshqa yuklash joyini tanlang, soʻng qayta urinib koʻring.',
			'downloads.storageUnavailable' => 'Boʻsh xotirani tekshirib boʻlmagani uchun yuklamalar toʻxtatildi. Yuklash joyini tekshirib, qaytadan urinib koʻring.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} qism yuklash navbatiga qoʻshildi',
			'downloads.downloadDeleted' => 'Yuklama oʻchirildi',
			'downloads.deleteConfirm' => ({required Object title}) => '"${title}" ushbu qurilmadan oʻchirilsinmi?',
			'downloads.deleteCollectionDownloads' => 'Yuklamalarni oʻchirish',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => '"${title}" ichidagi barcha yuklamalar ushbu qurilmadan oʻchirilsinmi?',
			'downloads.collectionDownloadsDeleted' => 'Yuklamalar oʻchirildi',
			'downloads.cancelledDownloadTitle' => 'Toʻxtatilgan yuklama',
			'downloads.cancelledDownloadMessage' => 'Ushbu yuklash bekor qilindi. Nima qilmoqchisiz?',
			'downloads.allEpisodesAlreadyDownloaded' => 'Barcha qismlar avvaldan yuklab olingan',
			'downloads.resumeDownload' => 'Yuklashni davom ettirish',
			'downloads.cancelledDownload' => 'Toʻxtatilgan yuklama',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (${status} sinxronlanmoqda)',
			_ => null,
		} ?? switch (path) {
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => 'Yuklab olindi ${file} - Yakunlash uchun bosing',
			'downloads.partialDownloadClickToComplete' => 'Qisman yuklandi - Yakunlash uchun bosing',
			'downloads.deleting' => 'Oʻchirilmoqda...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => '${title} oʻchirilmoqda... (${current} / ${total})',
			'downloads.queuedTooltip' => 'Navbatda',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'Navbatdagi fayllar: ${files}',
			'downloads.downloadingTooltip' => 'Yuklanmoqda...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'Yuklanayotgan fayllar: ${files}',
			'downloads.noDownloadsTree' => 'Yuklamalar yoʻq',
			'downloads.pauseAll' => 'Barchasini toʻxtatib turish',
			'downloads.resumeAll' => 'Barchasini davom ettirish',
			'downloads.retryAll' => 'Barchasini qaytadan yuklash',
			'downloads.retryFailed' => 'Muvaffaqiyatsiz yuklamalarni qaytadan yuklash',
			'downloads.deleteAll' => 'Barchasini oʻchirish',
			'downloads.selectVersion' => 'Versiyani tanlash',
			'downloads.allEpisodes' => 'Barcha qismlar',
			'downloads.unwatchedOnly' => 'Faqat koʻrilmaganlar',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Keyingi ${count} koʻrilmagan',
			'downloads.customAmount' => 'Boshqa miqdor...',
			'downloads.customAmountAny' => 'Istalgan miqdorni kiriting…',
			'downloads.randomEpisodes' => 'Reddimiyadi',
			'downloads.includeSpecials' => 'Maxsus qismlarni qoʻshish',
			'downloads.howManyEpisodes' => 'Nechta qism?',
			'downloads.invalidEpisodeCount' => 'Toʻgʻri qismlar sonini kiriting.',
			'downloads.keepSynced' => 'Sinxronlangan holatda ushlash',
			'downloads.downloadOnce' => 'Bir marta yuklab olish',
			'downloads.keepNUnwatched' => ({required Object count}) => '${count} koʻrilmagan qismni saqlash',
			'downloads.editSyncRule' => 'Sinxronlash qoidasini tahrirlash',
			'downloads.removeSyncRule' => 'Sinxronlash qoidasini oʻchirish',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => '"${title}" sinxronlashi toʻxtatilsinmi? Yuklab olingan qismlar saqlanadi.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => '"${title}" sinxronlashi toʻxtatilsinmi?',
			'downloads.deleteSyncRuleDownloads' => 'Bogʻliq yuklamalar ham oʻchirilsin',
			'downloads.deleteSyncRuleDownloadsDescription' => 'Boshqa sinxronlash qoidasi yoki profil ishlatayotgan yuklamalar saqlanadi.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Sinxronlash qoidasi yaratildi — ${count} koʻrilmagan qism saqlanadi',
			'downloads.syncRuleUpdated' => 'Sinxronlash qoidasi yangilandi',
			'downloads.syncRuleRemoved' => 'Sinxronlash qoidasi oʻchirildi',
			'downloads.syncRuleAndDownloadsRemoved' => 'Sinxronlash qoidasi va bogʻliq yuklamalar oʻchirildi',
			'downloads.syncRuleCleanupBusy' => 'Sinxronlash qoidalari hozir yangilanmoqda. Bir ozdan soʻng qayta urinib koʻring.',
			'downloads.syncRuleCleanupUnavailable' => 'Bogʻliq yuklamalarni xavfsiz aniqlab boʻlmadi. Serverga qayta ulanib koʻring yoki yuklamalarni oʻchirmasdan qoidani olib tashlang.',
			'downloads.syncedNewEpisodes' => ({required Object title, required Object count}) => '${title} uchun ${count} yangi qism sinxronlandi',
			'downloads.syncNow' => 'Sinkni',
			'downloads.downloadsUpToDate' => 'Yuklab olingan fayllar yangilangan',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => 'Sync complet · ${queued} queued, ${removed} xifonadi',
			'downloads.activeSyncRules' => 'Faol sinxronlash qoidalari',
			'downloads.reviewOrphanFiles' => 'Yozuvi yo‘q yuklamalarni ko‘rib chiqish',
			'downloads.orphanReviewTitle' => 'Yozuvi yo‘q yuklamalarni ko‘rib chiqish',
			'downloads.orphanReviewDescription' => 'Bu belgilangan fayllar PlezyNG boshqaradigan standart yuklab olish papkalarida joylashgan, ammo ularga mos yuklab olish yozuvi yoki faol vazifa yo‘q. O‘chirishdan oldin ro‘yxatni tekshiring.',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count} ta fayl · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => '${count} ta faylni o‘chirish',
			'downloads.orphanCleanupNone' => 'Yozuvi yo‘q yuklab olingan fayllar topilmadi',
			'downloads.orphanCleanupFailed' => 'PlezyNG boshqariladigan yuklab olish papkasini xavfsiz tarzda tekshira olmadi. Hech qanday fayl o‘chirilmadi.',
			'downloads.orphanCleanupChanged' => 'Ko‘rib chiqish paytida yuklab olishlar ro‘yxati o‘zgardi. Tozalashdan oldin fayllarni qayta ko‘rib chiqing.',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => '${count} ta yozuvi yo‘q fayl o‘chirildi · ${size} joy bo‘shatildi',
			'downloads.noSyncRules' => 'Sinxronlash qoidalari yoʻq',
			'downloads.manageSyncRule' => 'Sinxronlashni boshqarish',
			'downloads.editEpisodeCount' => 'Qismlar soni',
			'downloads.editSyncFilter' => 'Sinxronlash filtri',
			'downloads.syncAllItems' => 'Barcha elementlar sinxronlanadi',
			'downloads.syncUnwatchedItems' => 'Koʻrilmagan elementlar sinxronlanadi',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Server: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Mavjud',
			'downloads.syncRuleOffline' => 'Oflayn',
			'downloads.syncRuleSignInRequired' => 'Kirish talab etiladi',
			'downloads.syncRuleAccessDenied' => 'Kirish rad etildi',
			'downloads.syncRuleNotAvailableForProfile' => 'Joriy profil uchun mavjud emas',
			'downloads.syncRuleUnknownServer' => 'Nomaʼlum server',
			'downloads.syncRuleListCreated' => 'Sinxronlash qoidasi yaratildi',
			'downloads.backgroundWarning.bannerBlocked' => 'Ilovadan chiqqaningizda yuklamalar toʻxtaydi',
			'downloads.backgroundWarning.bannerDegraded' => 'Fondagi yuklamalar cheklangan boʻlishi mumkin',
			'downloads.backgroundWarning.bannerAction' => 'Batafsil',
			'downloads.backgroundWarning.sheetTitle' => 'Fondagi yuklamalar bloklangan',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Fondagi yuklamalar cheklangan boʻlishi mumkin',
			'downloads.backgroundWarning.sheetIntro' => 'Android PlezyNG-ning fonda ishonchli yuklab olishiga toʻsqinlik qilmoqda.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Qurilmangiz PlezyNG fonda qachon yuklay olishini cheklamoqda.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'PlezyNG-ning fondagi faoliyati cheklangan. Batareya yoki fondagi foydalanishni "Cheklanmagan" qilib belgilang.',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android PlezyNG-ni cheklangan kutish holatiga oʻtkazdi. Batareya foydalanishini "Cheklanmagan" qilib belgilang.',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Yuklash bildirishnomalari oʻchirilgan, shuning uchun jarayon koʻrsatkichi va boshqaruv elementlari mavjud boʻlmasligi mumkin.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Bildirishnomalar oʻchirilgan. Android 13 va undan yangi versiyalarda uzoq davom etadigan fondagi yuklamalar uchun ular talab qilinadi.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Trafik tejash yoqilgan, bu mobil internetda fondagi yuklamalarni bloklaydi. Wi-Fi orqali yuklamalar ishlashi kerak.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'PlezyNG fonda boʻlganida yuklamalar bir necha marta toʻxtadi. PlezyNG-ning batareya yoki fondagi foydalanish sozlamalarini tekshiring.',
			'downloads.backgroundWarning.openSettings' => 'Sozlamalarni ochish',
			'downloads.backgroundWarning.stillNotWorking' => 'Qurilmaga oid yordam',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'Qurilmangiz uchun qadamlarni koʻring yoki muammo davom etsa Sozlamalar › Jurnallarni koʻrish boʻlimidan jurnal yuboring.',
			'downloads.backgroundWarning.dialogTitle' => 'Yuklamalar tugamasligi mumkin',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'Baribir yuklash',
			'downloads.backgroundWarning.dialogFixFirst' => 'Avval buni tuzatish',
			'downloads.backgroundWarning.statusTile' => 'Fondagi yuklamalar',
			'downloads.backgroundWarning.statusOk' => 'Fonda ishlashga ruxsat berilgan',
			'downloads.backgroundWarning.statusBlocked' => 'Tizim sozlamalari tomonidan bloklangan',
			'downloads.backgroundWarning.statusDegraded' => 'Tizim sozlamalari tomonidan cheklangan',
			'downloads.backgroundWarning.statusUnknown' => 'Hali tekshirilmagan',
			'downloads.backgroundWarning.settingsUnavailable' => 'Bu qurilmada tizim sozlamalarini ochib boʻlmadi',
			'downloads.backgroundWarning.linkUnavailable' => 'Bu qurilmada dontkillmyapp.com-ni ochib boʻlmadi',
			'downloads.options' => 'Yuklamalar parametrlari',
			'downloads.groupings.library' => 'Kutubxona',
			'downloads.groupings.collections' => 'Toʻplamlar',
			'downloads.unknownLibrary' => 'Nomaʼlum kutubxona',
			'downloads.unknownShow' => 'Nomaʼlum serial',
			'downloads.unknownSeason' => 'Nomaʼlum mavsum',
			'downloads.unknownAlbum' => 'Nomaʼlum albom',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} ta yakunlandi',
			'downloads.storageUsed' => ({required Object size}) => 'U‘zizga: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} yuklab olish', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} yuklab olish', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} kino', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} kino', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} film', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmlar', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} albom', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} albom', ), 
			'downloads.errorFileNotFound' => 'Fayl topilmadi (404)',
			'downloads.errorDownloadNotAllowed' => 'Server yuklab olishga ruxsat bermaydi (403)',
			'downloads.errorDownloadFailed' => 'Yuklab boʻlmadi',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'Yuklab boʻlmadi: ${reason}',
			'downloads.convertingOnServer' => 'Serverga qaytadi...',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => 'Konveksiyon serverni · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => 'Yuklab boʻlmadi (HTTP ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => 'Keyingi ishlov berishda xatolik: ${reason}',
			'downloads.reasonFileNotSaved' => 'faylni ushbu qurilmada saqlab boʻlmadi',
			'downloads.reasonCannotResume' => 'qisman yuklab olishni davom ettirib boʻlmadi',
			'downloads.reasonDeviceStorageFull' => 'ushbu qurilmada xotira qolmadi',
			'downloads.notificationDownloading' => 'Yuklanmoqda...',
			'downloads.notificationComplete' => 'Yuklash tugallandi',
			'downloads.notificationPaused' => 'Yuklash toʻxtatib turildi',
			'shaders.title' => 'Sheyderlar',
			'shaders.noShaderDescription' => 'Video yaxshilash oʻchirilgan',
			'shaders.nvscalerDescription' => 'Aniqroq video uchun NVIDIA masshtabi',
			'shaders.artcnnVariantNeutral' => 'Neytral',
			'shaders.artcnnVariantDenoise' => 'Shovqinni kamaytirish',
			'shaders.artcnnVariantDenoiseSharpen' => 'Shovqinni kamaytirish + Aniqlik',
			'shaders.qualityFast' => 'Tezkor',
			'shaders.qualityHQ' => 'Yuqori sifat',
			'shaders.mode' => 'Rejim',
			'shaders.importShader' => 'Sheyderni import qilish',
			'shaders.customShaderDescription' => 'Maxsus GLSL sheyderi',
			'shaders.shaderImported' => 'Sheyder import qilindi',
			'shaders.shaderImportFailed' => 'Sheyderni import qilib boʻlmadi',
			'shaders.deleteShader' => 'Sheyderni oʻchirish',
			'shaders.deleteShaderConfirm' => ({required Object name}) => '"${name}" oʻchirilsinmi?',
			'companionRemote.title' => 'Yordamchi pult',
			'companionRemote.connectedTo' => ({required Object name}) => '${name} qurilmasiga ulandi',
			'companionRemote.unknownDevice' => 'Nomaʼlum qurilma',
			'companionRemote.session.startingServer' => 'Pult serveri ishga tushmoqda...',
			'companionRemote.session.hostAddress' => 'Xost manzili',
			'companionRemote.session.connected' => 'Ulandi',
			'companionRemote.session.serverRunning' => 'Server faol',
			'companionRemote.session.serverStopped' => 'Server toʻxtatildi',
			'companionRemote.session.serverRunningDescription' => 'Tarmoqdagi mobil qurilmalar ulanishi mumkin',
			'companionRemote.session.serverStoppedDescription' => 'Ulanishga ruxsat berish uchun serverni ishga tushiring',
			'companionRemote.session.usePhoneToControl' => 'Ushbu ilovani boshqarish uchun telefoningizdan foydalaning',
			'companionRemote.session.startServer' => 'Serverni ishga tushirish',
			'companionRemote.session.stopServer' => 'Serverni toʻxtatish',
			'companionRemote.session.minimize' => 'Yigʻish',
			'companionRemote.session.manualAddressHint' => 'Qoʻlda ulanish manzili:',
			'companionRemote.pairing.discoveryDescription' => 'Bir xil Plex hisobidagi PlezyNG qurilmalari bu yerda koʻrinadi',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Ulanilmoqda...',
			'companionRemote.pairing.searchingForDevices' => 'Qurilmalar qidirilmoqda...',
			'companionRemote.pairing.noDevicesFound' => 'Tarmoqda qurilmalar topilmadi',
			'companionRemote.pairing.noDevicesHint' => 'Kompyuterda PlezyNG-ni oching va bir xil Wi-Fi-ga ulaning',
			'companionRemote.pairing.availableDevices' => 'Mavjud qurilmalar',
			'companionRemote.pairing.manualConnection' => 'Qoʻlda ulanish',
			'companionRemote.pairing.cryptoInitFailed' => 'Xavfsiz ulanish xatoligi. Avval Plex-ga kiring.',
			'companionRemote.pairing.validationHostRequired' => 'Xost manzilini kiriting',
			'companionRemote.pairing.validationHostFormat' => 'Format IP:port koʻrinishida boʻlishi kerak',
			'companionRemote.pairing.connectionTimedOut' => 'Ulanish vaqti tugadi. Ikkala qurilmada ham bir xil tarmoqdan foydalaning.',
			'companionRemote.pairing.sessionNotFound' => 'Qurilma topilmadi. PlezyNG xost qurilmada ishga tushirilganiga ishonch hosil qiling.',
			'companionRemote.pairing.authFailed' => 'Autentifikatsiya xatoligi.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Ulanib boʻlmadi: ${error}',
			'companionRemote.pairing.codeTitle' => 'Code qadi',
			'companionRemote.pairing.codeDescription' => 'Kompanion Remote\'da yasan koodingiz. qotʻlar cihazlar qotʻlan. qotōlar sistemini koruygan bir versiyon qo‘zilgan.',
			'companionRemote.pairing.codeInvalid' => '32 ismi və numaralar qotʻi xotʻi.',
			'companionRemote.pairing.updateRequired' => 'Bu iki cihazlar korni‘ni bir versiyona qaytadi, korni‘nin korni‘n.',
			'companionRemote.pairing.hostDescription' => 'Bu kod bir o‘zizga. Bu kod gizli tut. Bu profil kontrollar.',
			'companionRemote.pairing.resetCode' => 'Xifida koodlar',
			'companionRemote.pairing.resetDescription' => 'All remote\'s ko\'zlar, yeni bir kod yarat. All remote will need to pair again.',
			'companionRemote.remote.disconnectConfirm' => 'Pult seansidan uzilasizmi?',
			'companionRemote.remote.reconnecting' => 'Qayta ulanilmoqda...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Urinish ${current} / 5',
			'companionRemote.remote.retryNow' => 'Hozir qaytadan urinib koʻrish',
			'companionRemote.remote.tabRemote' => 'Pult',
			'companionRemote.remote.tabPlay' => 'Ijro',
			'companionRemote.remote.tabMore' => 'Koʻproq',
			'companionRemote.remote.menu' => 'Menyu',
			'companionRemote.remote.tabNavigation' => 'Navigatsiya',
			'companionRemote.remote.tabDiscover' => 'Kashf qilish',
			'companionRemote.remote.tabLibraries' => 'Kutubxonalar',
			'companionRemote.remote.tabSearch' => 'Qidiruv',
			'companionRemote.remote.tabDownloads' => 'Yuklamalar',
			'companionRemote.remote.tabSettings' => 'Sozlamalar',
			'companionRemote.remote.previous' => 'Oldingi',
			'companionRemote.remote.playPause' => 'Ijro/Pauza',
			'companionRemote.remote.next' => 'Keyingi',
			'companionRemote.remote.seekBack' => 'Orqaga oʻtkazish',
			'companionRemote.remote.stop' => 'Toʻxtatish',
			'companionRemote.remote.seekForward' => 'Oldinga oʻtkazish',
			'companionRemote.remote.volume' => 'Ovoz',
			'companionRemote.remote.volumeDown' => 'Kamaytirish',
			'companionRemote.remote.volumeUp' => 'Oshirish',
			'companionRemote.remote.fullscreen' => 'Toʻliq ekran',
			'companionRemote.remote.subtitles' => 'Subtitrlar',
			'companionRemote.remote.audio' => 'Ovoz',
			'companionRemote.remote.searchHint' => 'Kompyuterda qidirish...',
			'companionRemote.errors.noNetworkInterface' => 'Tarmoq interfeysi topilmadi',
			'companionRemote.errors.authenticationFailed' => 'Autentifikatsiya xatoligi',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'Serverni ishga tushirishda xatolik: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'Buyruqni yuborishda xatolik: ${error}',
			'companionRemote.errors.joinTimedOut' => 'Ulanish vaqti tugadi',
			'companionRemote.errors.failedToConnectAnyAddress' => 'Hech bir manzilga ulanib boʻlmadi',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => '${attempts} urinishdan keyin aloqa uzildi',
			'companionRemote.errors.connectionLost' => 'Aloqa uzildi',
			'companionRemote.closedBeforeAuth' => 'Ulanish autentifikatsiyadan oldin yopildi',
			'videoSettings.playbackSpeed' => 'Ijro tezligi',
			'videoSettings.normalSpeed' => 'Oddiy',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Faol (${duration})',
			'videoSettings.zoom' => 'Masshtab',
			'videoSettings.sleepTimer' => 'Uyqu taymeri',
			'videoSettings.audioSync' => 'Audio sinxronlash',
			'videoSettings.subtitleSync' => 'Subtitr sinxronlash',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'Bu yerda HDR mavjud emas — ish stoli kompozitori yoki video chiqishi uni uzata olmaydi.',
			'videoSettings.hdrToneMapping' => 'HDR tonlarini moslashtirish',
			'videoSettings.hdrToneMappingCompositor' => 'Kompozitor',
			'videoSettings.hdrToneMappingCompositorDescription' => 'Manbaning HDR metamaʼlumotlarini oʻzgarishsiz uzatib, ularni moslashtirishni ish stoli kompozitoriga topshirish.',
			'videoSettings.hdrToneMappingPlayer' => 'Pleyer',
			'videoSettings.hdrToneMappingPlayerDescription' => 'Pleyerda displeyning eng yuqori yorqinligiga moslashtirib, soʻng natijani kompozitorga bildirish.',
			'videoSettings.hdrToneMappingFailed' => 'HDR tonlarini moslashtirishni oʻzgartirib boʻlmadi — avvalgi rejim hali ham faol.',
			'videoSettings.audioOutput' => 'Audio chiqishi',
			'videoSettings.performanceOverlay' => 'Unumdorlik paneli',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'Hajmli ovoz',
			'videoSettings.audioOutputSpatial' => 'Fazoviy audio',
			'videoSettings.audioOutputStereo' => 'Stereo',
			'videoSettings.audioEqualizer' => 'Audio bilan bilan',
			'videoSettings.audioEqualizerDescription' => 'Bu cihaz için 5 frekans bandlar ayat. mpv\'da qothatlar; aktiv EQ audio decoding və passthrough boʻyadi.',
			'videoSettings.audioEqualizerFlat' => 'Yiyiyiyiy',
			'videoSettings.audioEqualizerActive' => 'Shaxsiy',
			'videoSettings.audioEqualizerSaveFailed' => 'Audio ekvalayzer sozlamalarini saqlab bo‘lmadi.',
			'videoSettings.backgroundVideoAudio' => 'Video audio bilan',
			'videoSettings.backgroundVideoAudioDescription' => 'Video audio oynatma qadi siz oynatma\'dan qaytadi; foto qadi qaytadi. Android bir media playback bildirim kullanır.',
			'videoSettings.audioNormalization' => 'Ovoz balandligini meʼyorlashtirish',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'Ovozni PCM-ga dekodlaydi; bu yoqilganda toʻgʻridan-toʻgʻri oʻtkazish oʻchiriladi',
			'performanceOverlay.color' => 'Rang',
			'performanceOverlay.performance' => 'Unumdorlik',
			'performanceOverlay.buffer' => 'Bufer',
			'performanceOverlay.app' => 'Ilova',
			'performanceOverlay.decoder' => 'Dekoder',
			'performanceOverlay.rawDecoder' => 'Ishlov berilmagan dekoder',
			'performanceOverlay.tunneling' => 'Tunnellash',
			'performanceOverlay.passthrough' => 'Toʻgʻridan-toʻgʻri oʻtkazish',
			'performanceOverlay.aspect' => 'Nisbat',
			'performanceOverlay.rotation' => 'Aylanish',
			'performanceOverlay.dvSource' => 'DV manbasi',
			'performanceOverlay.dvPath' => 'DV yoʻli',
			'performanceOverlay.dvRouteDecoder' => 'Dolby Vision dekoderi',
			'performanceOverlay.dvRouteDecoderP81' => 'Dolby Vision dekoderi (P7→8.1)',
			'performanceOverlay.dvRouteBaseLayer' => 'Asosiy qatlam',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'HDR10 asosiy qatlami',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'HLG asosiy qatlami',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'SDR asosiy qatlami',
			'performanceOverlay.dvRouteReshaped' => 'RPU orqali qayta shakllantirilgan (gpu-next)',
			'performanceOverlay.p7Conversion' => 'P7 oʻtkazmasi',
			'performanceOverlay.sampleRate' => 'Diskretlash chastotasi',
			'performanceOverlay.pixelFormat' => 'Piksel formati',
			'performanceOverlay.hwFormat' => 'HW formati',
			'performanceOverlay.matrix' => 'Matritsa',
			'performanceOverlay.primaries' => 'Asosiy ranglar',
			'performanceOverlay.transfer' => 'Uzatish',
			'performanceOverlay.renderFps' => 'Render FPS',
			'performanceOverlay.displayFps' => 'Displey FPS',
			'performanceOverlay.avSync' => 'A/V sinxronlash',
			'performanceOverlay.dropped' => 'Tushirib qoldirilgan kadrlar',
			'performanceOverlay.dvRpus' => 'DV RPU-lar',
			'performanceOverlay.dvRpuAverage' => 'DV RPU Oʻrt.',
			'performanceOverlay.dvSampleAverage' => 'DV Namuna Oʻrt.',
			'performanceOverlay.maxLuma' => 'Maks Luma',
			'performanceOverlay.minLuma' => 'Min Luma',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Foydalanilgan kesh',
			'performanceOverlay.cacheLimit' => 'Kesh chegarasi',
			'performanceOverlay.speed' => 'Tezlik',
			'performanceOverlay.player' => 'Pleyer',
			'performanceOverlay.playMethod' => 'Metodizmi',
			'performanceOverlay.memory' => 'Xotira',
			'performanceOverlay.uiFps' => 'Interfeys (UI) FPS',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android HW',
			'performanceOverlay.decoderNvidiaHw' => 'NVIDIA HW',
			'performanceOverlay.decoderQualcommHw' => 'Qualcomm HW',
			'performanceOverlay.decoderMediatekHw' => 'MediaTek HW',
			'performanceOverlay.decoderExynosHw' => 'Exynos HW',
			'performanceOverlay.decoderSoftware' => 'Dasturiy',
			'performanceOverlay.decoderHardware' => 'Apparat',
			'performanceOverlay.tunnelingActive' => 'Faol',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted} (${failures} ta muvaffaqiyatsiz)',
			'externalPlayer.title' => 'Tashqi pleyer',
			'externalPlayer.useExternalPlayer' => 'Tashqi pleyerdan foydalanish',
			'externalPlayer.useExternalPlayerDescription' => 'Videolarni boshqa ilovada ochish',
			'externalPlayer.selectPlayer' => 'Pleyerni tanlash',
			'externalPlayer.customPlayers' => 'Maxsus pleyerlar',
			'externalPlayer.systemDefault' => 'Tizim standarti',
			'externalPlayer.addCustomPlayer' => 'Maxsus pleyer qoʻshish',
			'externalPlayer.playerName' => 'Pleyer nomi',
			'externalPlayer.playerNameHint' => 'Mening pleyerim',
			'externalPlayer.playerCommand' => 'Buyruq',
			'externalPlayer.playerPackage' => 'Paket nomi',
			'externalPlayer.playerUrlScheme' => 'URL sxemasi',
			'externalPlayer.off' => 'Oʻchirilgan',
			'externalPlayer.launchFailed' => 'Tashqi pleyerni ishga tushirib boʻlmadi',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} oʻrnatilmagan',
			'externalPlayer.playInExternalPlayer' => 'Tashqi pleyerda ijro etish',
			'metadataEdit.editMetadata' => 'Tahrirlash...',
			'metadataEdit.screenTitle' => 'Metamaʼlumotlarni tahrirlash',
			'metadataEdit.basicInfo' => 'Asosiy maʼlumotlar',
			'metadataEdit.artwork' => 'Rasmlar/Posterlar',
			'metadataEdit.advancedSettings' => 'Kengaytirilgan sozlamalar',
			'metadataEdit.title' => 'Nomi',
			'metadataEdit.sortTitle' => 'Saralash nomi',
			'metadataEdit.originalTitle' => 'Asl nomi',
			'metadataEdit.releaseDate' => 'Chiqqan sanasi',
			'metadataEdit.contentRating' => 'Kontent reytingi',
			'metadataEdit.studio' => 'Studiya',
			'metadataEdit.tagline' => 'Shior/Slogan',
			'metadataEdit.summary' => 'Tavsif/Qisqacha',
			'metadataEdit.poster' => 'Poster',
			'metadataEdit.background' => 'Fon',
			'metadataEdit.logo' => 'Logotip',
			'metadataEdit.squareArt' => 'Kvadrat rasm',
			'metadataEdit.selectPoster' => 'Posterni tanlash',
			'metadataEdit.selectBackground' => 'Fonni tanlash',
			'metadataEdit.selectLogo' => 'Logotipni tanlash',
			'metadataEdit.selectSquareArt' => 'Kvadrat rasm tanlash',
			'metadataEdit.fromUrl' => 'URL orqali',
			'metadataEdit.uploadFile' => 'Fayl yuklash',
			'metadataEdit.enterImageUrl' => 'Rasm URL-manzilini kiriting',
			'metadataEdit.imageUrl' => 'Rasm URL-manzili',
			'metadataEdit.metadataUpdated' => 'Metamaʼlumotlar yangilandi',
			'metadataEdit.metadataUpdateFailed' => 'Metamaʼlumotlarni yangilab boʻlmadi',
			'metadataEdit.artworkUpdated' => 'Rasmlar yangilandi',
			'metadataEdit.artworkUpdateFailed' => 'Rasmlarni yangilab boʻlmadi',
			'metadataEdit.noArtworkAvailable' => 'Rasm mavjud emas',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Rasm opsiyasi ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Rasm opsiyasi ${index}, tanlandi',
			'metadataEdit.notSet' => 'Oʻrnatilmagan',
			'metadataEdit.libraryDefault' => 'Kutubxona standarti',
			'metadataEdit.accountDefault' => 'Hisob standarti',
			'metadataEdit.seriesDefault' => 'Serial standarti',
			'metadataEdit.episodeSorting' => 'Qismlarni saralash',
			'metadataEdit.oldestFirst' => 'Avval eskilar',
			'metadataEdit.newestFirst' => 'Avval yangilar',
			'metadataEdit.keep' => 'Saqlash',
			'metadataEdit.allEpisodes' => 'Barcha qismlar',
			'metadataEdit.latestEpisodes' => ({required Object count}) => 'Soʻnggi ${count} qism',
			'metadataEdit.latestEpisode' => 'Soʻnggi qism',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Soʻnggi ${count} kunda qoʻshilgan qismlar',
			'metadataEdit.deleteAfterPlaying' => 'Ijro etgandan keyin oʻchirish',
			'metadataEdit.never' => 'Hech qachon',
			'metadataEdit.afterADay' => 'Bir kundan keyin',
			'metadataEdit.afterAWeek' => 'Bir haftadan keyin',
			'metadataEdit.afterAMonth' => 'Bir oydan keyin',
			'metadataEdit.onNextRefresh' => 'Keyingi yangilanishda',
			'metadataEdit.seasons' => 'Mavsumlar',
			'metadataEdit.show' => 'Koʻrsatish',
			'metadataEdit.hide' => 'Yashirish',
			'metadataEdit.episodeOrdering' => 'Qismlar tartibi',
			'metadataEdit.tmdbAiring' => 'The Movie Database (Efir)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (Efir)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (Absolyut)',
			'metadataEdit.metadataLanguage' => 'Metamaʼlumotlar tili',
			'metadataEdit.useOriginalTitle' => 'Asl nomidan foydalanish',
			'metadataEdit.preferredAudioLanguage' => 'Afzal koʻrilgan audio tili',
			'metadataEdit.preferredSubtitleLanguage' => 'Afzal koʻrilgan subtitr tili',
			'metadataEdit.subtitleMode' => 'Avtomatik subtitr tanlash rejimi',
			'metadataEdit.manuallySelected' => 'Qoʻlda tanlangan',
			'metadataEdit.shownWithForeignAudio' => 'Chet el audiosi bilan koʻrsatiladi',
			'metadataEdit.alwaysEnabled' => 'Har doim yoqilgan',
			'metadataEdit.tags' => 'Teglar',
			'metadataEdit.addTag' => 'Teg qoʻshish',
			'metadataEdit.genre' => 'Janr',
			'metadataEdit.director' => 'Rejissyor',
			'metadataEdit.writer' => 'Ssenarist',
			'metadataEdit.producer' => 'Prodyuser',
			'metadataEdit.country' => 'Mamlakat',
			'metadataEdit.collection' => 'Toʻplam',
			'metadataEdit.label' => 'Yorliq',
			'metadataEdit.quickTag' => 'Tezkor teg...',
			'matchScreen.match' => 'Moslashtirish...',
			'matchScreen.fixMatch' => 'Moslikni tuzatish...',
			'matchScreen.unmatch' => 'Moslikni oʻchirish',
			'matchScreen.unmatchConfirm' => 'Ushbu moslik oʻchirilsinmi? Qayta moslashtirilgunga qadar Plex uni moslashtirilmagan deb hisoblaydi.',
			'matchScreen.unmatchSuccess' => 'Moslik oʻchirildi',
			'matchScreen.unmatchFailed' => 'Moslikni oʻchirib boʻlmadi',
			'matchScreen.matchApplied' => 'Moslik qoʻllanildi',
			'matchScreen.matchFailed' => 'Moslikni qoʻllab boʻlmadi',
			'matchScreen.titleHint' => 'Nomi',
			'matchScreen.yearHint' => 'Yil',
			'matchScreen.search' => 'Qidiruv',
			'matchScreen.noMatchesFound' => 'Mosliklar topilmadi',
			'serverTasks.title' => 'Server vazifalari',
			'serverTasks.failedToLoad' => 'Vazifalarni yuklab boʻlmadi',
			'serverTasks.noTasks' => 'Bajarilayotgan vazifalar yoʻq',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Ulandi',
			'trakt.connectedAs' => ({required Object username}) => '@${username} sifatida ulandi',
			'trakt.disconnectConfirm' => 'Trakt uzilsinmi?',
			'trakt.disconnectConfirmBody' => 'PlezyNG Trakt-ga maʼlumot yuborishni toʻxtatadi.',
			'trakt.scrobble' => 'Real vaqt rejimida kuzatish',
			'trakt.scrobbleDescription' => 'Ijro paytida Trakt-ga maʼlumot yuborish.',
			'trakt.watchedSync' => 'Koʻrish holatini sinxronlash',
			'trakt.watchedSyncDescription' => 'PlezyNG-da belgilanganda Trakt-da ham belgilanadi.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Seerr ulash',
			'seerr.serverUrl' => 'Server URL-i',
			'seerr.serverUrlHelper' => 'Seerr manzilingiz',
			'seerr.checkServer' => 'Davom ettirish',
			'seerr.signInWithJellyfin' => 'Jellyfin orqali kirish',
			'seerr.signInWithEmby' => 'Emby orqali kirish',
			'seerr.signInWithLocal' => 'Mahalliy hisobdan foydalanish',
			'seerr.email' => 'Elektron pochta',
			'seerr.noSignInMethods' => 'Ushbu Seerr qoʻllab-quvvatlanadigan kirish usulini taklif qilmaydi.',
			'seerr.instance' => 'Instansiya',
			'seerr.disconnectConfirm' => 'Seerr uzilsinmi?',
			'seerr.disconnectConfirmBody' => 'PlezyNG ushbu Seerr nusxasini unutadi. Istalgan vaqtda qayta ulanishingiz mumkin.',
			'seerr.request' => 'Soʻrov yuborish',
			'seerr.request4k' => '4K soʻrov yuborish',
			'seerr.seasons' => 'Mavsumlar',
			'seerr.allSeasons' => 'Barcha mavsumlar',
			'seerr.advancedOptions' => 'Kengaytirilgan',
			'seerr.destinationServer' => 'Moʻljal server',
			'seerr.qualityProfile' => 'Sifat profili',
			'seerr.rootFolder' => 'Asosiy jild',
			'seerr.languageProfile' => 'Til profili',
			'seerr.tags' => 'Yorliqlar',
			'seerr.noTags' => 'Yorliqlar yoʻq',
			'seerr.defaultOption' => ({required Object name}) => '${name} (Standart)',
			'seerr.animeNote' => 'Bu serial anime.',
			'seerr.requestSubmitted' => 'Soʻrov yuborildi',
			'seerr.requestFailed' => ({required Object error}) => 'Soʻrov xatoligi: ${error}',
			'seerr.requestsLoadFailed' => 'Parametrlarni yuklab boʻlmadi',
			'seerr.nothingToRequest' => 'Barchasi avvaldan bor yoki soʻralgan.',
			'seerr.statusAvailable' => 'Mavjud',
			'seerr.statusPartiallyAvailable' => 'Qisman mavjud',
			'seerr.statusRequested' => 'Soʻraldi',
			'seerr.statusProcessing' => 'Ishlanmoqda',
			'seerr.statusBlocklisted' => 'Bloklangan roʻyxatda',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => '${url} manziliga ulanib boʻlmadi: ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => '${url} manzilida Seerr nusxasi yoʻq (HTTP ${status})',
			'seerr.behindAuthProxy' => 'Seerr oʻrniga autentifikatsiya qiluvchi teskari proksi (SSO yoki HTTP auth) javob berdi. PlezyNG uning orqali kira olmaydi: ushbu ilova uchun Seerrning /api/v1 yoʻli proksini aylanib oʻtishiga ruxsat bering yoki Seerrga toʻgʻridan-toʻgʻri yetadigan manzildan foydalaning.',
			'seerr.invalidUrl' => 'Server manzilini kiriting, masalan: https://seerr.example.com',
			'seerr.quickConnectUnsupported' => 'Bu Seerr nusxasi Tezkor ulanishni qoʻllab-quvvatlamaydi. Buning uchun Seerr 3.4 yoki undan yangi versiya kerak.',
			'seerr.notInitialized' => 'Bu Seerr nusxasining dastlabki sozlamasi yakunlanmagan',
			'seerr.noPlexTokenForReauth' => 'Qayta kirish uchun Plex tokeni mavjud emas',
			'seerr.noStoredCredentials' => 'Qayta kirish uchun saqlangan kirish maʼlumotlari mavjud emas',
			'seerr.signInRejected' => 'Kirish rad etildi',
			'seerr.noSessionCookie' => 'Seerr seans cookie-faylini bermadi',
			'seerr.freshCookieRejected' => 'Seerr yangi seans cookie-faylini rad etdi',
			'seerr.noUserInformation' => 'Seerr foydalanuvchi maʼlumotlarini qaytarmadi',
			'seerr.sessionRejectedAfterReauth' => 'Qayta kirilgandan keyin seans rad etildi',
			'seerr.permissionDenied' => 'Seerr bu amalni rad etdi: hisobingizda endi kerakli ruxsat yoʻq',
			'seerr.permissionRevoked' => 'Buni soʻrash uchun endi ruxsatingiz yoʻq',
			'services.title' => 'Xizmatlar',
			'services.hubSubtitle' => 'Koʻrish jarayonini sinxronlang va yangi kontent soʻrang.',
			'services.integrations' => 'Integratsiyalar',
			'services.notConnected' => 'Ulanmagan',
			'services.connectedAs' => ({required Object username}) => '@${username} sifatida ulandi',
			'services.scrobble' => 'Jarayonni avtomatik kuzatish',
			'services.scrobbleDescription' => 'Epizod yoki filmni tugatganingizda roʻyxatingizni yangilash.',
			'services.disconnectConfirm' => ({required Object service}) => '${service} uzilsinmi?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'PlezyNG ${service} yangilashni toʻxtatadi. Istalgan vaqtda qayta ulanishingiz mumkin.',
			'services.connectFailed' => ({required Object service}) => '${service} ulana olmadi. Qaytadan urinib koʻring.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'Simkl-ni qayta ulash',
			'services.simklReconnect.subtitle' => 'Simkl bu ulanishda ishlatiladigan kirish usulini toʻxtatmoqda. Qayta ulanganda PlezyNG-ni tasdiqlash uchun simkl.com ochiladi — PlezyNG parolingizni hech qachon koʻrmaydi. Tomosha tarixingiz Simkl-da saqlanib qoladi.',
			'services.deviceCode.title' => ({required Object service}) => 'PlezyNG-ni ${service} xizmatida faollashtiring',
			'services.deviceCode.instructions' => 'QR-kodni skanerlang yoki quyidagi manzilga oʻtib, bu kodni kiriting:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Faollashtirish uchun ${service} xizmatini oching',
			'services.deviceCode.copyCode' => 'Faollashtirish kodini nusxalash',
			'services.deviceCode.waitingForAuthorization' => 'Avtorizatsiya kutilmoqda…',
			'services.deviceCode.codeCopied' => 'Kod nusxalandi',
			'services.oauthProxy.title' => ({required Object service}) => '${service} xizmatiga kiring',
			'services.oauthProxy.body' => 'Ushbu QR kodni skanerlang yoki URL-ni oching.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Kirish uchun ${service} xizmatini oching',
			'services.pendingAuth.copyUrl' => 'Kirish URL-ini nusxalash',
			'services.pendingAuth.urlCopied' => 'URL nusxalandi',
			'services.libraryFilter.title' => 'Kutubxona filtri',
			'services.libraryFilter.subtitleAllSyncing' => 'Barcha kutubxonalar sinxronlanmoqda',
			'services.libraryFilter.subtitleNoneSyncing' => 'Hech narsa sinxronlanmaydi',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} bloklandi',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} ruxsat berildi',
			'services.libraryFilter.mode' => 'Filtr rejimi',
			'services.libraryFilter.modeBlacklist' => 'Qora roʻyxat',
			'services.libraryFilter.modeWhitelist' => 'Oq roʻyxat',
			'services.libraryFilter.modeHintBlacklist' => 'Quyida tanlanganlardan tashqari barcha kutubxonalarni sinxronlash.',
			'services.libraryFilter.modeHintWhitelist' => 'Faqat quyida tanlangan kutubxonalarni sinxronlash.',
			'services.libraryFilter.libraries' => 'Kutubxonalar',
			'services.libraryFilter.noLibraries' => 'Kutubxonalar yoʻq',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => '${product} serverini qoʻshish',
			'addServer.serverUrls' => 'Server URL-lari',
			'addServer.serverUrlsHelper' => 'Vergul bilan ajratilgan bir nechta URL manziliga ruxsat beriladi.',
			'addServer.findServer' => 'Serverni topish',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'Mahalliy ${product} serverlari qidirilmoqda...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'Mahalliy ${product} serverlari',
			'addServer.username' => 'Foydalanuvchi nomi',
			'addServer.password' => 'Parol',
			'addServer.signIn' => 'Kirish',
			'addServer.change' => 'Oʻzgartirish',
			'addServer.required' => 'Talab qilinadi',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Serverga ulanib boʻlmadi: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Kirish xatoligi: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Tezkor ulanish xatoligi: ${error}',
			_ => null,
		} ?? switch (path) {
			'addServer.addPlexTitle' => 'Plex orqali kirish',
			'addServer.pinExpired' => 'PIN kod vaqti tugadi.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Hisobni roʻyxatdan oʻtkazishda xatolik: ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => '${product} server URL-ini kiriting',
			'addServer.addConnectionTitle' => 'Ulanish qoʻshish',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => '${name} profiliga qoʻshish',
			'addServer.signInWithPlexCard' => 'Plex orqali kirish',
			'addServer.signInWithPlexCardSubtitle' => 'Ushbu qurilmani avtorizatsiya qiling. Ulashilgan serverlar qoʻshiladi.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Plex hisobini avtorizatsiya qiling. Home foydalanuvchilari profillarga aylanadi.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => '${product}ga ulanish',
			'addServer.connectToMediaBrowserCardSubtitle' => 'Server URL-ini, foydalanuvchi nomini va parolni kiriting.',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => '${product} serveringizga kiring. ${name} profiliga bogʻlanadi.',
			'addServer.borrowFromAnotherProfile' => 'Boshqa profildan olish',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Boshqa profilning ulanishidan qayta foydalaning.',
			'addServer.invalidCredentials' => 'Foydalanuvchi nomi yoki parol notoʻgʻri',
			'addServer.authResponseNotJson' => 'Autentifikatsiya javobi yaroqli JSON emas',
			'addServer.authResponseIncomplete' => 'Serverdan kelgan kirish javobi toʻliq emas',
			'addServer.quickConnectRejected' => 'Quick Connect server tomonidan rad etildi',
			'addServer.quickConnectNotJson' => 'Quick Connect javobi yaroqli JSON emas',
			'addServer.quickConnectMissingFields' => 'Quick Connect javobida kod yoki maxfiy kalit yoʻq',
			'addServer.quickConnectPollRejected' => 'Quick Connect soʻrovi server tomonidan rad etildi',
			'addServer.serverTimedOut' => 'Server oʻz vaqtida javob bermadi',
			'addServer.responseNotJson' => 'Server javobi yaroqli JSON emas',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'Javobda ID yoki server nomi yoʻq — bu ${product} serverimi?',
			'addServer.probeFailed' => ({required Object error}) => 'Serverga ulanib boʻlmadi: ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => 'Kamida bitta ${product} server URL-ini kiriting',
			'addServer.noReachableServer' => ({required Object product}) => 'Ulanish mumkin boʻlgan ${product} serveri topilmadi',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'Bu URL-lar turli ${product} serverlariga olib boradi',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'Bu URL ${product} serveriga mos kelmaydi',
			'addServer.redirectUnsupported' => 'Server qoʻllab-quvvatlanmaydigan URL-ga yoʻnaltirdi',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'Server boshqa xostga yoʻnaltirdi. Yakuniy ${product} URL-ini bevosita kiriting.',
			'addServer.redirectInsecure' => 'Server HTTPS manzilidan xavfsiz boʻlmagan URL-ga yoʻnaltirdi',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'Server qoʻllab-quvvatlanmaydigan URL-ga yoʻnaltirdi. Yakuniy ${product} URL-ini bevosita kiriting.',
			'addServer.directPlexServerUrl' => 'Plex server URL manzili',
			'addServer.directPlexServerUrlHelper' => 'IP-i və port-i Plex Media Server\'da girdi.',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex Token (iziziz)',
			'addServer.plexTokenHelper' => 'Bu serverda auth olmadan qurtlamad.',
			'addServer.plexTokenRequired' => 'Siz xifififiziziziz. xififiziniz Plex token (X-Plex-Token) sizdir.',
			'addServer.connectDirectPlexCard' => 'Plex Media Server (Suradi / Lokal)',
			'addServer.connectDirectPlexCardSubtitle' => 'IP ya URL\'i qonkash qonkash plex.tv hesab olmadan qonkash.',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => 'IP ya URL\'ni ya qotʻi qotʻy. ${name}\'i qotuj.',
			'addServer.insecureTitle' => 'Unencrypting qonkong',
			'addServer.insecureDescription' => ({required Object url}) => '${url} HTTP protokolidan foydalanadi. Tarmoqdagi boshqa odamlar parolingizni, tokenlaringizni va mediafayllaringizni oʻqishi yoki oʻzgartirishi mumkin. Imkon boʻlsa, HTTPS dan foydalaning. Faqat ushbu tarmoqqa ishonsangiz va xavfni qabul qilsangiz davom eting.',
			'addServer.allowHttp' => 'HTTP ulanishiga ruxsat berish',
			'addServer.httpsRequired' => 'HTTPS ya qizizga qizga qifififiyizga qihga qifida qifida.',
			'watchLink.serverUnavailable' => 'Bu link için bir server Plex qothathathathatdi.',
			'watchLink.notFound' => 'Bu serial yoki film Plex serverlaringizda topilmadi.',
			'watchLink.ambiguous' => 'Bu link birdan daha bir server\'da items-i ko‘yadi.',
			'watchLink.plexOnly' => 'Tomosha havolalari hozircha faqat Plex serverlarini qo‘llab-quvvatlaydi.',
			'watchLink.unsupportedItem' => 'View linklar yalnız bir show o film o\'yadi.',
			'watchLink.menuItem' => 'U\'qizdan link',
			'watchLink.dialogTitle' => 'Link ko‘z',
			'watchLink.dialogShowHint' => 'Bu link\'i açmak bir sonraki epizod oynayır. shuffle\'da show\'u oynaymak için sonuna &mode=shuffle\'u ektir.',
			'watchLink.dialogMovieHint' => 'Bu link\'i açmak filmini oynaylar.',
			'watchLink.copy' => 'Kopi',
			'watchLink.copied' => 'Link koʻpadi',
			'homeLayout.title' => 'Bosh sahifa tartibi',
			'homeLayout.resetToast' => 'Bosh sahifa asl Plezy joylashuviga qaytarildi',
			'homeLayout.resetHeroTitle' => 'Asosiy ko‘rinish asl Plezy holatiga qaytarilsinmi?',
			'homeLayout.resetHeroBody' => 'Herradi\'nin kahraman ayatlar bo\'yadi, bir-rondaylar bo\'ya qaytarga, Home\'nin topta, o\'yadi\'nin önizdan bo\'yadlar.',
			'homeLayout.removeRowTitle' => 'Home Riyadh bilan bilan bilan?',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} o‘chiriladi. Bu amalni ortga qaytarib bo‘lmaydi.',
			'homeLayout.sync' => 'Sinq',
			'homeLayout.syncAccountTitle' => 'Sizga Plex hesabla sinqiziziziz.',
			'homeLayout.syncAccountOn' => 'Yoqilgan: bu qurilma qatorlar tartibi, qatorlar, asosiy banner va avtomatik almashish sozlamalarini boshqa qurilmalaringiz bilan ulashadi.',
			'homeLayout.syncAccountOff' => 'Bu sistemimiz, bu sistemimiz öz layoutini tutmayır.',
			'homeLayout.syncNow' => 'Sinkni',
			'homeLayout.plexHomeManager' => 'Plex Home menaxer',
			'homeLayout.managePlexRows' => 'Plex ruzlar Plezy\'da qotlarlar.',
			'homeLayout.managePlexRowsDescription' => 'U\'ziziziziz qiziziziyizizizimizizizizimiziziz',
			'homeLayout.organizeHomeRows' => 'Home Riyadhlar',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} ruzlar: Moving, Hero, Auto-slide, xifida',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => '${library} qaytlarlar',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => '+ ${n} riylar: Moving, Library, Home, Hero, Auto-slide',
			'homeLayout.renderAsHero' => 'Bir kartatda bir kahraman.',
			'homeLayout.heroOnlySingleCollection' => 'Bu o‘ziz o‘z o‘z q‘z o’z o‘q‘z o\'z o‘y o‘z bu‘z o`z o‘s o‘z',
			'homeLayout.hero' => 'Asosiy banner',
			'homeLayout.autoSlide' => 'Avtomatik almashish',
			'homeLayout.autoSlideDescription' => 'U\'zizga (PC) və d-pad (TV) qotlarga çalışmaygan, timiyarni qaytarmaygan.',
			'homeLayout.autoSlideEditDescription' => 'O‘shayni o‘shaydi o‘shahdi o‘s. Off: o‘shaya‘ga bir pul (PC) o‘shakla‘ga sol/dishayni o’shayni (TV). Arrows and d-pad always work either way.',
			'homeLayout.enableHeroFirst' => 'Birinci kahramanlar',
			'homeLayout.showOnHome' => 'Show on Home screen.',
			'homeLayout.home' => 'Bosh sahifa',
			'homeLayout.removeFromHome' => 'Home‘dan qaytadi',
			'homeLayout.selectRowsFirst' => 'U\'ziz, siz sizni ilk aşağıda qaytadi.',
			'homeLayout.plexManagedRows' => ({required Object n}) => 'Plex boshqaradigan qatorlar: ${n}',
			'homeLayout.continueWatching' => 'Tomoshani davom ettirish',
			'homeLayout.continueWatchingLibraryDescription' => 'Ushbu kutubxonada tomoshani to‘xtagan joydan davom ettirish qatori',
			'homeLayout.continueWatchingHomeDescription' => 'Bosh sahifada ko‘rsatiladigan, tomoshani to‘xtagan joydan davom ettirish qatori',
			'homeLayout.nextUpHomeDescription' => 'Next Unwatched epizod riyadi sizlikliklik Home\'da o‘zizliklikliklikdi',
			'homeLayout.library' => 'Kutubxona',
			'homeLayout.showInRecommended' => 'Librarikda qaytadi qaytadi.',
			'homeLayout.customPlexRow' => 'Maxsus Plex qatori',
			'homeLayout.heroNeedsLibrary' => 'Avval “Kutubxona” bandini belgilang — asosiy banner ko‘rsatiladigan joy kerak',
			'homeLayout.heroNeedsSurface' => 'Birincisi Library o Home ko‘shayt — Hero\'s need somewhere to show',
			'homeLayout.removeHub' => 'Hub qiziziz',
			'homeLayout.noPlexRows' => 'No Plex-manadi ruzlar bu librariyaya qaytardi.',
			'homeLayout.openDetails' => 'Detaylar',
			'homeLayout.heroCards' => 'Karta qiziziz',
			'homeLayout.tapHeroCard' => 'Bir kahraman kartta bo‘yadi',
			'homeLayout.tvPlayFocus' => 'TV remote: Play button qiziziziz',
			'homeLayout.tvPlayFocusDescription' => 'D-pad down bo\'t Play button\'da bo\'t ko\'t ko. Ko\'t ko`t ko\'n ko\'t.',
			'homeLayout.tvWrap' => 'TV remote: Loop hero kartlar',
			'homeLayout.tvWrapDescription' => 'Son kartta qaytadi. son kartta boʻshadi. son karta boʻshad. son karttanda boʻshada boʻshud.',
			'homeLayout.castOnHero' => 'Bananlarda yuxirga',
			'homeLayout.castOnHeroDescription' => 'Bir kahraman banner\'dan debt-da yuxay. Off o‘zayni titni və bilan.',
			'homeLayout.customRows' => 'Custom qiziziz',
			'homeLayout.loading' => 'Home Loading Loading Load...',
			'homeLayout.noCustomRows' => 'U‘zari ko‘zari yok',
			'homeLayout.addRowHint' => 'U\'zadi\'ni birini yaratmaq üçün Home Row\'ni qo‘zadi.',
			'homeLayout.addHomeRow' => 'Home Riyadh',
			'homeLayout.addHomeRowDescription' => 'Bir kategoriyiz seçin; Yeni seri automatik olarak Organizator\'a qo‘zilgan.',
			'homeLayout.removeRow' => 'Riyadhdan',
			'homeLayout.recentlyAdded' => 'Yaqinda qoʻshilganlar',
			'homeLayout.recentlyReleased' => 'Songa bilan bilan bilan',
			'homeLayout.movieCollections' => 'Film Koleksiya',
			'homeLayout.showCollections' => 'Koleksiya ko‘z',
			'homeLayout.rowTitle' => 'Tadiq Tadiq',
			'homeLayout.content' => 'Tadiq',
			'homeLayout.showThisRowIn' => 'Bu yadi\'ni yadi:',
			'homeLayout.libraryRecommended' => 'Librariyadi bilan',
			'homeLayout.heroCard' => 'Karta bo‘z',
			'homeLayout.heroCardDescription' => 'Bir kartta bir kartta bir poster shelf ko‘zadi.',
			'homeLayout.heroUnavailableDescription' => 'Bu seri bir koleksiyonin real titlarlarga qotʻlarda qotʻlanga qotujayda qotujiyada qotujaya qotujin qotujan qotuj.',
			'homeLayout.librariesSelection' => 'Librarlar (tashqqqqtqqt qtqqqta qtqtqt qtaqtqtaqt qqtqtsqtql qtqts qtqlqtqdqlqqttql)',
			'homeLayout.librariesMergedDescription' => 'Her librariyiz burada kontrolda bu bir sıraya birimdir.',
			'homeLayout.movieCollectionsSelection' => 'Film koleksiyonlar (tashqiziziziz bütün seçkin librariyalar)',
			'homeLayout.showCollectionsSelection' => 'Koleksiylar (tashqiziziziz o‘tashqitiziziz)',
			'homeLayout.collectionRowsDescription' => 'Siz o‘zari bir koleksiyonga ma\'zari, o‘zori titlarlarlar doğrudan bir sıraya bo‘zari. e‘zari ma\'zadi, o‘zi koleksiyonda bir poster olarak bo‘zadi — o‘zadi o‘zaki o‘zeki o‘zani o‘zoni o‘zagi.',
			'homeLayout.allCollections' => 'Koleksiya',
			'homeLayout.noRowsHere' => 'Bu qotlar ko‘zadi.',
			'homeLayout.hideWatchedRows' => 'U\'qizga o\'qizganlar qizga o‘qizga',
			'homeLayout.hideWatchedRowsDescription' => 'Full-tolled titles go\'t Home and library Recommended riys. In-progress ones stay.',
			'homeLayout.untitledCollection' => 'Koleksiya bilan',
			'homeLayout.moveRowHint' => 'Up/Down: xifida · Seçin: xifoda · Back: xifot',
			'homeLayout.organizeRowsHint' => 'Seçim (o hallar) Seçim: ta\'yadi · Sa\'yadi/sa\'yadi: riyadi seçim · Riyadi: ta\'ya qaytadi',
			'homeLayout.layoutNavDescription' => 'Siz, librarlar, kategoriyalar seçin',
			'homeLayout.editHomeRow' => 'Edit Home Row',
			'homeLayout.resetHeroButton' => 'Asosiy banner tartibini Plezy standartiga qaytarish',
			'homeLayout.reorderingUnlocked' => 'Yenni qaytadi',
			'homeLayout.reorderingLocked' => 'Tadiqlar kiladi',
			'homeLayout.rowsCanBeDragged' => 'Tadiqlar qurtlar qurtlanga — bu qurtlardan qurtlanmdan qurtlar.',
			'homeLayout.tapLockToDrag' => 'Tadiqlar qotlarga qaytlarga qaytarga',
			'homeLayout.customRowLabel' => ({required Object title}) => 'U‘ziz: ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => 'Yashirish',
			'homeLayout.remove' => 'Oʻchirish',
			'homeLayout.libraryResumeRow' => 'Ushbu kutubxonaning tomoshani davom ettirish qatori',
			'homeLayout.pressAgainToDelete' => 'Yenni xifida qaytadi.',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => 'On',
			'homeLayout.resetHeroButtonDescription' => 'Herroni ayatlar bo\'yadi, yandan yandan yadan yandan yandadi yandan yanda yandan yanan yandan yalan yandan yansat.',
			'platform.localNetworkPermission' => 'PlezyNG sizga lokal network sizga media serveri və playback cihazlara bağlanır.',
			'platform.locationPermission' => 'Mahalliy tarmoqni aniqlash va media serverlaringizga ulanish uchun iOS talab qilganida, PlezyNG joylashuv ma’lumotlaridan foydalanish ruxsatidan foydalanadi.',
			'platform.photoLibraryPermission' => 'Media muqovasi sifatida ishlatish uchun foto kutubxonangizdan rasmlarni tanlang.',
			'platform.cameraPermission' => 'Companion Remote pultini ulash uchun QR kodlarini skanerlang.',
			'fileSources.title' => 'Fillar və kitablar',
			'fileSources.subtitle' => 'O‘z fayllaringizni o‘qing, tinglang va tomosha qiling.',
			'fileSources.add' => 'Kaynaklar',
			'fileSources.importFiles' => 'Fildiya',
			'fileSources.localFiles' => 'Bu cihazda',
			'fileSources.source' => 'Kaynak',
			'fileSources.name' => 'Namo',
			'fileSources.endpoint' => 'Server URL-i',
			'fileSources.root' => 'Bir prefix o prefix',
			'fileSources.username' => 'Foydalanuvchi nomi',
			'fileSources.password' => 'Parol',
			'fileSources.token' => 'API token',
			'fileSources.accessKey' => 'Key ID qozga',
			'fileSources.secretKey' => 'Key qapashat',
			'fileSources.sessionToken' => 'Session token (iziziz)',
			'fileSources.region' => 'Region',
			'fileSources.clientId' => 'OAuth Client ID',
			'fileSources.clientSecret' => 'OAuth client secret (so‘z Google desktop)',
			'fileSources.allowHttp' => 'Ishonchli tarmoqda shifrlanmagan HTTP ulanishiga ruxsat berish',
			'fileSources.connect' => 'Ulanish',
			'fileSources.cancel' => 'Bekor qilish',
			'fileSources.save' => 'Saqlash',
			'fileSources.close' => 'Yopish',
			'fileSources.removeSource' => 'Kaynaklar qurtlan',
			'fileSources.disconnectMessage' => 'Ushbu manba ulanishi uzilsinmi? Yuklab olingan fayllar, o‘qish va tinglash tarixi ushbu qurilmada saqlanib qoladi.',
			'fileSources.localFolder' => 'Fildi seçti',
			'fileSources.empty' => 'Hali bu yerda hech narsa yoʻq',
			'fileSources.emptyHint' => 'Bir kayndan qo‘yadi o‘yadi bir kitab, audiobok, musiqi, o‘video.',
			'fileSources.search' => 'Bu folderga qaytadi',
			'fileSources.searchCached' => 'Librariyizga saladi',
			'fileSources.refresh' => 'Yangilash',
			'fileSources.loadMore' => 'Yatadi',
			'fileSources.offline' => 'Offline qozga',
			'fileSources.download' => 'Offline ko‘z',
			'fileSources.removeDownload' => 'Offline kopyadi',
			'fileSources.continueReading' => 'Okumaya devam',
			'fileSources.continueListening' => 'Tadiqga qulaq',
			'fileSources.continueWatching' => 'U‘qizga',
			'fileSources.read' => 'Okumada',
			'fileSources.listen' => 'Tadiq',
			'fileSources.play' => 'Ijro etish',
			'fileSources.pause' => 'Pauza',
			'fileSources.stop' => 'Toʻxtatish',
			'fileSources.startOver' => 'Yatlarga',
			'fileSources.finished' => 'Tugadi',
			'fileSources.markFinished' => 'Marqdan bo‘qadi',
			'fileSources.markUnfinished' => 'Marqimizni',
			'fileSources.editions' => 'Edicionlar və fillar',
			'fileSources.chapters' => 'Boʻlimlar',
			'fileSources.bookmarks' => 'Bookmarklar və notlar',
			'fileSources.bookmark' => 'Bookmark ko‘z',
			'fileSources.highlight' => 'Yiyiyiyiy',
			'fileSources.note' => 'Tadiq',
			'fileSources.delete' => 'Oʻchirish',
			'fileSources.export' => 'Eksportlar bilan',
			'fileSources.exported' => 'U‘zadiqlar',
			'fileSources.sync' => 'Sinklik progres',
			'fileSources.synced' => 'Tadiqlar synthesiz',
			'fileSources.conflict' => 'Bir yandan bir sistemdi, bir yandan bir yandan, bir yanda seçin.',
			'fileSources.useLocal' => 'Bu qurilmadan foydalanish',
			'fileSources.useRemote' => 'Boshqa qurilmadan foydalanish',
			'fileSources.history' => 'Tarih',
			'fileSources.groupAudio' => 'Bir audio-book kimi o‘zadi.',
			'fileSources.groupHint' => 'Bu folderda ko‘zadi\'ni ko‘zad. All pages first.',
			'fileSources.order' => 'File bilan',
			'fileSources.moveUp' => 'Tadiqga',
			'fileSources.moveDown' => 'Tadiqni',
			'fileSources.speed' => 'Playback xiyim',
			'fileSources.sleep' => 'Uyqu taymeri',
			'fileSources.sleepOff' => 'Oʻchirilgan',
			'fileSources.endChapter' => 'Kapitalni bilan',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} daqiqa', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} daqiqa', ), 
			'fileSources.skipBack' => 'Tadiq qaytadi',
			'fileSources.skipForward' => 'Tadiqadi',
			'fileSources.smartRewind' => 'U\'qimni qaytarga bir pauzdan sonra',
			'fileSources.playbackOptions' => 'O’qizim seçenekler',
			'fileSources.remaining' => ({required Object time}) => '${time} bilan bilan bilan',
			'fileSources.contents' => 'Konteyn',
			'fileSources.readerSettings' => 'Okumadi ayatlar',
			'fileSources.fontSize' => 'Text Size',
			'fileSources.lineHeight' => 'Satrlar oralig‘i',
			'fileSources.margin' => 'Margini',
			'fileSources.font' => 'Tifon',
			'fileSources.serif' => 'Serifli',
			'fileSources.sans' => 'Serifiyadi',
			'fileSources.mono' => 'Monomadi',
			'fileSources.columns' => 'Kolumni',
			'fileSources.scroll' => 'Vertikalga qaytadi',
			'fileSources.justify' => 'Tekstilni',
			'fileSources.readerTheme' => 'Page görünüş',
			'fileSources.appTheme' => 'App tema‘ga qaytadi',
			'fileSources.paper' => 'Qogʻoz',
			'fileSources.sepia' => 'Sepiya',
			'fileSources.night' => 'Nash',
			'fileSources.readAloud' => 'Bu sahifani ovoz chiqarib o‘qish',
			'fileSources.readAlong' => 'Okumadi',
			'fileSources.stopReading' => 'Ovoz chiqarib o‘qishni to‘xtatish',
			'fileSources.searchBook' => 'Bookda検索',
			'fileSources.noMatches' => 'U\'qizmi',
			'fileSources.previousPage' => 'Oldingi sahifa',
			'fileSources.nextPage' => 'Keyingi sahifa',
			'fileSources.page' => ({required Object number}) => '${number}-sahifa',
			'fileSources.externalBlocked' => 'O‘qish dasturida kitoblarning tashqi havolalari o‘chirilgan.',
			'fileSources.loading' => 'O’q...',
			'fileSources.narrator' => 'Tadiq',
			'fileSources.audio' => 'Ovoz',
			'fileSources.video' => 'Video',
			'fileSources.ebooks' => 'Ebook',
			'fileSources.all' => 'Barchasi',
			'fileSources.downloads' => 'Offline bilan',
			'fileSources.confirmDelete' => 'Tanlangan oflayn nusxa o‘chirilsinmi? O‘qish yoki tinglash joyi va qaydlaringiz saqlanib qoladi.',
			'fileSources.errorAuthentication' => 'Bu kaynadi qaytarga qaytarga.',
			'fileSources.errorPermission' => 'Bu manba so‘ralgan faylga kirishga ruxsat bermadi.',
			'fileSources.errorUnavailable' => 'Bu kaynadi yetim. Yenni xifida koʻtadi, ya\'yadi offline kopiy.',
			'fileSources.errorUnsupported' => 'Bu format ya ko‘zlar bu cihazda supportasiz. kaynaqlar ko‘zalar guadi.',
			'fileSources.errorInvalidData' => 'Bu fayl yoki server javobini xavfsiz o‘qib bo‘lmadi.',
			'fileSources.errorCancelled' => 'Amal bekor qilindi.',
			'fileSources.errorConflict' => 'Possiya bir seansda qaytadi. bir pozsiya seçibim üçün elementni qaytadi!',
			'fileSources.signIn' => 'Kirish',
			'fileSources.reconnect' => 'Qayta ulanish',
			'fileSources.folderHelp' => 'U\'qotni koʻtadi. URL\'lar S3 buqotni.',
			'fileSources.preferences' => 'Preferans',
			'fileSources.timePosition' => 'Joylashuvi',
			'fileSources.audioTrack' => 'Audio Trag',
			'fileSources.subtitleTrack' => 'Subtitle Tadiq',
			'fileSources.none' => 'U‘yadi',
			'fileSources.fullscreen' => 'Ekran',
			'fileSources.syncLocation' => 'Progress sync folder (iziziz)',
			'fileSources.syncLocationHint' => 'PlezyNG holati uchun alohida WebDAV jildi. Shartli yozishdan foydalaniladi; mediafayllar o‘zgarmaydi.',
			'fileSources.audiobooks' => 'Audiobotlar',
			'fileSources.comics' => 'Komik',
			'fileSources.scan' => 'Scanlar kitablar və mediyalar',
			'fileSources.browserReader' => 'Open lugadi',
			'fileSources.browserReaderHelp' => 'O‘qish oynasi brauzeringizda ochiq. O‘qish joyi va qaydlaringiz saqlanishi uchun PlezyNG’ni ochiq qoldiring.',
			'fileSources.on' => 'Yoqilgan',
			'fileSources.advancedSetup' => 'App Registration',
			'fileSources.microsoftSignIn' => 'Microsoftga abonni.',
			'fileSources.zoomIn' => 'Zoomga',
			'fileSources.zoomOut' => 'Zoomga',
			'fileSources.fitPage' => 'Pageqiz',
			'fileSources.fitWidth' => 'Uqqqqga',
			'fileSources.actualSize' => 'Tariflik',
			'fileSources.goToPage' => 'Pagega qaytadi',
			'fileSources.goToSection' => 'Kapitalga qaytadi',
			'fileSources.pageRange' => ({required Object count}) => '1dan ${count}\'ni bir numir girdi.',
			'fileSources.pageLayout' => 'Page Layout',
			'fileSources.automatic' => 'Avtomatik',
			'fileSources.singlePage' => 'Bir sayat',
			'fileSources.twoPages' => '2 sayat',
			'fileSources.readingDirection' => 'Okumadi qaytadi',
			'fileSources.leftToRight' => 'Chapdan o‘ngga',
			'fileSources.rightToLeft' => 'O‘ngdan chapga',
			'fileSources.letterSpacing' => 'Tadiqadiqadi',
			'fileSources.wordSpacing' => 'U‘zizga',
			'fileSources.readerControlsHelp' => 'Sahifani kattalashtirish uchun ikki barmog‘ingizni bir-biridan uzoqlashtiring yoki masshtab tugmalaridan foydalaning. Sahifani siljitish uchun sudrang. Ctrl/⌘ va + yoki − masshtabni o‘zgartiradi; Ctrl/⌘ va 0 uni tiklaydi. Page Up va Page Down sahifalarni almashtiradi.',
			'fileSources.imagePage' => 'Komik sayadi',
			'fileSources.resetReader' => 'Okumadi preferanslar',
			'fileSources.zoom' => 'Masshtab',
			'fileSources.useFiles' => 'Fillar və kitablar kullanır.',
			'fileSources.cancelScan' => 'Sankcion',
			'fileSources.googleDrive' => 'Google Drive',
			'lending.title' => 'Public librarlar',
			'lending.add' => 'Bir kütüphan qo‘yadi',
			'lending.other' => 'Bir librariyada',
			'lending.libraryName' => 'Librari adı',
			'lending.libraryUrl' => 'Webbiliya',
			'lending.libraryUrlHint' => 'Siz librariyiznin katalogi ya‘y‘y‘ya‘y‘yo‘y‘ay.',
			'lending.intro' => 'Kütüphanizdan borga.Bibrarizdan qurt.',
			'lending.handoff' => 'Kutubxonangizning o‘z xizmati orqali hisobingizga kiring, kitoblarni vaqtincha oling va xavfsiz o‘qing.',
			'lending.openService' => 'Librariq',
			'lending.findLibrary' => 'Bir kütüphan bulga',
			'lending.search' => 'Kitablar ve yazarlar aradi',
			'lending.catalogue' => 'Katalog',
			'lending.loans' => 'Loan',
			'lending.holds' => 'Band qilingan kitoblar',
			'lending.signIn' => 'Siz librariyizga qaytadi.',
			'lending.waiting' => 'Siz browserga abonni bilan bilan, qaytdan qaytdan.',
			'lending.cancel' => 'Bekor qilish',
			'lending.disconnect' => 'Librariya bilan',
			'lending.disconnectMessage' => 'Bu kutubxona shu profildan olib tashlansinmi? Vaqtincha olgan va band qilgan kitoblaringiz kutubxona hisobingizda saqlanadi.',
			'lending.getBook' => 'Bookga bo‘yadi',
			'lending.checkAvailability' => 'Tadiqlar bilan bilan bilan',
			'lending.available' => 'U\'ziyadi borga',
			'lending.unavailable' => 'Şu anda yetimlik',
			'lending.borrow' => 'Vaqtincha olish',
			'lending.placeHold' => 'Band qilish',
			'lending.returnBook' => 'Tadi qaytar',
			'lending.cancelHold' => 'Band qilishni bekor qilish',
			'lending.confirmBorrow' => 'Bu titili librarizdan borga?',
			'lending.confirmReturn' => 'Bu kitobni hozir qaytarasizmi? Davom etish uchun uni yana olishingiz kerak bo‘lishi mumkin.',
			'lending.confirmCancelHold' => 'Bu kitobni band qilishni bekor qilasizmi?',
			'lending.email' => 'Kitobni band qilish haqidagi bildirishnomalar uchun elektron pochta',
			'lending.due' => ({required Object date}) => 'Qaytarish muddati: ${date}',
			'lending.queue' => ({required Object position}) => 'Possiya ${position} linni.',
			'lending.empty' => 'Yiyiyiyiy o‘zlar.',
			'lending.openLibraryNote' => 'Open Library\'nin katalogi va\'qlar. Read and borrilik seçenekler hər bir titilinin sayadi.',
			'lending.more' => 'Yatadi',
			'lending.gateway' => 'Librariyadi-sign-in servis',
			'lending.gatewayHint' => 'Siz librariyiz o‘yibib o‘yiba PlezyNG administrator.',
			'lending.advanced' => 'Librariya integrasyon',
			'lending.loadLibraries' => 'Librari sizni seçin',
			'lending.expired' => 'Bu borga bilan bilan bo‘zadi.',
			'lending.updated' => 'Librari bilan günahlar',
			'lending.continueService' => 'U‘ziyadi',
			'lending.comingSoon' => 'U-app borga · Biraz qaytarga',
			'lending.comingSoonDescription' => 'Libby integration is on its way. Siz Libby librariyizni sizni kullanabiliz, biz onu bağlayganni bilan.',
			'lending.suspendHold' => 'Tadiqadiqadi',
			'lending.resumeHold' => 'Tadiqadiqadi',
			'lending.suspendMessage' => 'Navbatdagi o‘rningizni saqlab, keyingi o‘quvchiga bu nusxani olishga ruxsat berasizmi? Band qilishni keyin davom ettirishingiz mumkin.',
			'lending.resumeMessage' => 'Kutubxona keyingi bo‘sh nusxani sizga taklif qilishi uchun bu band qilishni davom ettirasizmi?',
			'lending.editEmail' => 'Email Notifikacion',
			'audiobook.syncTitle' => 'Okum & dining sync',
			'audiobook.syncHelp' => 'Okuma pozsiya, okuma pozisyonlar, completion status, bookmarks, notlar siz cihazlarınızda. Added stockage account seçin ve hər cihazda aynı sinq kod kullanın. Okuma və dinim ayaladi.',
			'audiobook.addSyncSource' => 'Google Drive, OneDrive, Dropbox, WebDAV o S3\'i fillar və kitablar qoladi.',
			'audiobook.syncDestination' => 'Sync bilan bilan bilan',
			'audiobook.syncFolder' => 'Filmi ya prefix.',
			'audiobook.syncFolderHelp' => 'WebDAV kaynağınızda, ya da dedikadi S3 prefix\'i bir separat bilan folder kullan. Book files is never changed.',
			'audiobook.syncCode' => 'Sink kodlar',
			'audiobook.syncCodeHelp' => 'Bir kod o‘ziz, sonra o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘ziz o‘z.',
			'audiobook.showCode' => 'Sink-kodni koʻyadi koʻyadi.',
			'audiobook.newSyncCode' => 'Yeni bir sinq-kodi yaratlar.',
			'audiobook.saveSync' => 'Save and synq.',
			'audiobook.disableSync' => 'Bu cihazda synchroniziziziziziz.',
			'audiobook.syncSourceDisconnect' => 'Bu kayndan qaytdan o‘yadi o‘yadi o‘yadi o‘yadi o‘yadi o‘yadi o‘yadi o‘yadi o‘yadi.',
			'audiobook.syncReconnect' => 'Hesab bilan bilan bilan bilan bilan bilan',
			'audiobook.lastSynced' => ({required Object time}) => '${time}\'da sonda sinqizdi',
			'audiobook.syncPrivacy' => 'Biz xifriyo bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan bilan.',
			'audiobook.syncConflicts' => 'Onda qaytarga qaytarga.',
			'audiobook.conflictHelp' => 'Bu modifikasyonlar bağımsızdan ko‘zadi. ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi ko‘zadi',
			'audiobook.syncDevice' => ({required Object device}) => '${device}',
			'audiobook.syncUnknownDevice' => 'U‘zari',
			'audiobook.deletedBookmark' => 'Bookmark bilan bilan bilan',
			'audiobook.finished' => 'Konni',
			'audiobook.readingPosition' => ({required Object percent}) => '${percent} %',
			'audiobook.chapterTimeline' => 'Kapital bilan bilan',
			'audiobook.bookTimeline' => 'Kitab bilan progresi',
			'audiobook.bookRemaining' => ({required Object time}) => '${time} bu kitabda qaytadi.',
			'audiobook.chapterRemaining' => ({required Object time}) => 'Bu kapitalda kalan zaman: ${time}',
			'audiobook.unknownRemaining' => 'Total time available as parts is playing. — Tull time available as parts are playing. — Tull time available as parts are playing. — Tull time available as parts are playing.',
			'audiobook.undoSeek' => 'Songa ko‘zadi.',
			'audiobook.customSpeed' => 'Custom playback ritmi.',
			'audiobook.speedHelp' => 'Siz 0.25 x 4 x o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z o‘z',
			'audiobook.apply' => 'Diggadi',
			'audiobook.customSleep' => 'Custom uyumalar',
			'audiobook.sleepMinutes' => '1 – 440 min)',
			'audiobook.sleepChapters' => ({required Object count}) => '${count} kapitallardan sonra durga',
			'audiobook.extendSleep' => '5 dakikadi',
			'audiobook.sleepRemaining' => ({required Object time}) => 'U\'qiziziz: ${time}',
			'audiobook.useDefaults' => 'Yeni kitaplar için bu dining kontrollar kullanın.',
			'audiobook.librarySort' => 'Kitajlar',
			'audiobook.sortTitle' => 'Tadiya',
			'audiobook.sortAuthor' => 'Avtor',
			'audiobook.sortNarrator' => 'Hikmatlar',
			'audiobook.sortSeries' => 'Seriyadi',
			'audiobook.sortRecent' => 'U‘zʻzʻzʻzʻzʻzʻzʻ',
			'audiobook.statusFilter' => 'Okumaya status',
			'audiobook.statusAll' => 'Bütün kitablar',
			'audiobook.statusNew' => 'Başlamad',
			'audiobook.statusProgress' => 'Tadiqadi',
			'audiobook.statusFinished' => 'Konni',
			'audiobook.goToTime' => 'O‘zadi.',
			'audiobook.timeHelp' => 'Hours:minuts:seconds, o minutlar:seconds',
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
