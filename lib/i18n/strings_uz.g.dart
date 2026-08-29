///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
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
	@override late final _Translations$auth$uz auth = _Translations$auth$uz._(_root);
	@override late final _Translations$common$uz common = _Translations$common$uz._(_root);
	@override late final _Translations$screens$uz screens = _Translations$screens$uz._(_root);
	@override late final _Translations$update$uz update = _Translations$update$uz._(_root);
	@override late final _Translations$settings$uz settings = _Translations$settings$uz._(_root);
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
}

// Path: app
class _Translations$app$uz extends Translations$app$en {
	_Translations$app$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
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
	@override String get localDataRecoveryRequired => 'Plezy mahalliy kirish maʼlumotlarini tiklay olmadi. Iltimos, qaytadan kiring.';
	@override String get pinCheckRejected => 'Plex PIN tekshiruvi rad etildi';
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

// Path: settings
class _Translations$settings$uz extends Translations$settings$en {
	_Translations$settings$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Sozlamalar';
	@override String get supportDeveloper => 'Plezy-ni qoʻllab-quvvatlash';
	@override String get supportDeveloperDescription => 'Dasturchini Liberapay orqali qoʻllab-quvvatlang';
	@override String get language => 'Til';
	@override String get theme => 'Mavzu';
	@override String get appearance => 'Tashqi koʻrinish';
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
	@override String get libraryDensity => 'Kutubxona zichligi';
	@override String get displayScale => 'Ekran miqyosi';
	@override String get compact => 'Ixcham';
	@override String get comfortable => 'Qulay';
	@override String get gridSpacing => 'Toʻr oraligʻi';
	@override String get gridSpacingTight => 'Zich';
	@override String get gridSpacingNormal => 'Normal';
	@override String get gridSpacingSpacious => 'Keng';
	@override String get tvCornerSpotlightBackdrop => 'Burchak yoritish foni';
	@override String get tvCornerSpotlightBackdropDescription => 'Fonni toʻliq ekran oʻrniga yuqori oʻng burchakda koʻrsatish';
	@override String get viewMode => 'Koʻrish rejimi';
	@override String get gridView => 'Toʻrsimon';
	@override String get listView => 'Roʻyxat';
	@override String get showHeroSection => 'Asosiy boʻlimni koʻrsatish';
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
	@override String get alwaysKeepSidebarOpenDescription => 'Yon menyu ochiq holatda qoladi';
	@override String get showUnwatchedCount => 'Koʻrilmaganlar sonini koʻrsatish';
	@override String get showUnwatchedCountDescription => 'Seriallar va mavsumlarda koʻrilmagan qismlar sonini koʻrsatish';
	@override String get showEpisodeNumberOnCards => 'Kartochkalarda qism raqamini koʻrsatish';
	@override String get showEpisodeNumberOnCardsDescription => 'Qism kartochkalarida mavsum va qism raqamini koʻrsatish';
	@override String get showSeasonPostersOnTabs => 'Varaqlarda mavsum posterlarini koʻrsatish';
	@override String get showSeasonPostersOnTabsDescription => 'Har bir mavsum posterini oʻz boʻlimida koʻrsatish';
	@override String get tvFullCardLayout => 'Toʻliq TV kartochkalari';
	@override String get tvFullCardLayoutDescription => 'Faqat rasmdan iborat TV kartochkalaridan foydalanish';
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
	@override String get defaultQualityTitle => 'Standart sifat';
	@override String get cellularQualityTitle => 'Mobil tarmoqda standart sifat';
	@override String get cellularQualitySameAsDefault => 'Standart sifat bilan bir xil';
	@override String get musicQualityTitle => 'Musiqa sifati';
	@override String get subtitleStyling => 'Subtitr sozlamalari';
	@override String get subtitleStylingDescription => 'Subtitrlar koʻrinishini moslashtiring';
	@override String get smallSkipDuration => 'Kichik oʻtkazish vaqti';
	@override String get largeSkipDuration => 'Katta oʻtkazish vaqti';
	@override String get rewindOnResume => 'Davom ettirganda orqaga qaytarish';
	@override String secondsUnit({required Object seconds}) => '${seconds} soniya';
	@override String get defaultSleepTimer => 'Standart uyqu taymeri';
	@override String minutesUnit({required Object minutes}) => '${minutes} daqiqa';
	@override String get rememberTrackSelections => 'Har bir film/serial uchun ovoz/subtitr tanlovini eslab qolish';
	@override String get rememberTrackSelectionsDescription => 'Har bir media uchun ovoz va subtitr sozlamalarini saqlash';
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
	@override String get watchTogetherRelayDescription => 'Xususiy rele oʻrnating. Barcha bir xil serverdan foydalanishi kerak.';
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
	@override String get importSettingsInvalidFile => 'Ushbu fayl toʻgʻri Plezy sozlamalar fayli emas';
	@override String get importSettingsNoUser => 'Sozlamalarni import qilishdan oldin tizimga kiring';
	@override String get shortcutsReset => 'Tugmalar birlashmasi standart holatga qaytarildi';
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
	@override String get playNextCountdown => 'Keyingi qism sanogʻi';
	@override String get playNextCountdownImmediate => 'Darhol ijro etish';
	@override String get autoSkipIntro => 'Kirish qismini (Intro) avtomatik oʻtkazish';
	@override String get autoSkipIntroDescription => 'Bir necha soniyadan soʻng kirish qismlarini avtomatik oʻtkazish';
	@override String get autoSkipCredits => 'Titrlarni avtomatik oʻtkazish';
	@override String get autoSkipCreditsDescription => 'Titrlarni oʻtkazib yuborish va keyingi qismni ijro etish';
	@override String get forceSkipMarkerFallback => 'Zahira belgilarini majburlash';
	@override String get forceSkipMarkerFallbackDescription => 'Plex belgilari boʻlsa ham boʻlim sarlavhasi shablonlaridan foydalanish';
	@override String get autoSkipDelay => 'Avtomatik oʻtkazish kechikishi';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Avtomatik oʻtkazishdan oldin ${seconds} soniya kutilsin';
	@override String get introPattern => 'Kirish qismi belgisi shabloni';
	@override String get introPatternDescription => 'Boʻlim sarlavhalarida introni topish uchun Regex shabloni';
	@override String get creditsPattern => 'Titr belgisi shabloni';
	@override String get creditsPatternDescription => 'Boʻlim sarlavhalarida titrlarni topish uchun Regex shabloni';
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
	@override String get cellularDownloadBlocked => 'Mobil tarmoqda yuklash taqiqlangan. Wi-Fi-dan foydalaning.';
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
	@override String get tunneledPlaybackDescription => 'Video tunnellashdan foydalanish. HDR ijrosida ekran qora boʻlsa, oʻchiring.';
	@override String get audioPassthrough => 'Ovozni toʻgʻridan-toʻgʻri oʻtkazish (Passthrough)';
	@override String get audioPassthroughDescription => 'Dolby/DTS ovozini qayta kodlamasdan resiver yoki televizoringizga yuboradi va atroflicha ovozni saqlaydi. Ovoz boʻlmasa, oʻchiring.';
	@override String get audioPassthroughDescriptionAppleTv => 'Dolby Digital Plus uchun Apple dekoderidan foydalanish.';
	@override String get audioDownmix => 'Stereoga oʻtkazish (Downmix)';
	@override String get audioDownmixDescription => 'Koʻp kanalli ovozni stereo dinamiklar uchun ikki kanalga tushirish';
	@override String get downmixCenterBoost => 'Markaziy kanalni kuchaytirish';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Kuchaytirish (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Oʻtkazishda ovozni meʼyorlashtirish';
	@override String get audioDownmixNormalizeDescription => 'Ovoz buzilishining oldini olish uchun darajani tushirish.';
	@override String get dvConversionMode => 'Dolby Vision oʻtkazmasi';
	@override String get dvConversionModeDescription => 'ExoPlayer-ning Dolby Vision Profile 7 fayllarini qayta ishlash rejimini tanlang.';
	@override String get dvConversionAuto => 'Avtomatik';
	@override String get dvConversionNative => 'Ichki / Oʻchirilgan';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Qurilma imkoniyatlaridan foydalanish';
	@override String get dvConversionNativeDescription => 'Ichki DV7 rejimini majburlash';
	@override String get dvConversionDv81Description => 'Dolby Vision profile 8.1 formatiga oʻtkazish';
	@override String get dvConversionHevcStripDescription => 'Dolby Vision qatlamlarini olib tashlash va HEVC sifatida koʻrsatish';
	@override String get deinterlace => 'Interleysni olib tashlash';
	@override String get deinterlaceDescription => 'Interleys videodagi taroqsimon artefaktlarni olib tashlash (faqat mpv pleyerida)';
	@override String get requireProfileSelectionOnOpen => 'Ochilganda profilni soʻrash';
	@override String get requireProfileSelectionOnOpenDescription => 'Ilova ochilgan har safar profilni tanlashni koʻrsatish';
	@override String get forceTvMode => 'TV rejimini majburlash';
	@override String get forceTvModeDescription => 'TV interfeysini majburiy yoqish.';
	@override String get startInFullscreen => 'Toʻliq ekranda boshlash';
	@override String get startInFullscreenDescription => 'Plezy-ni ochganda toʻliq ekran rejimida ochish';
	@override String get exitFullscreenOnPlayerClose => 'Pleyer yopilganda toʻliq ekrandan chiqish';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Video pleyerni yopganda avtomatik ravishda toʻliq ekrandan chiqish';
	@override String get autoHidePerformanceOverlay => 'Unumdorlik panelini avto-yashirish';
	@override String get autoHidePerformanceOverlayDescription => 'Unumdorlik panelini boshqaruv tugmalari bilan birga yashirish';
	@override String get showNavBarLabels => 'Navigatsiya paneli matnlarini koʻrsatish';
	@override String get showNavBarLabelsDescription => 'Navigatsiya belgilarining ostida matnni koʻrsatish';
	@override String get startupSection => 'Boshlangʻich boʻlim';
	@override String get showExploreTab => 'Kashf qilish varagʻini koʻrsatish';
	@override String get showExploreTabDescription => 'Plex Discover va ulangan kuzatuvchilardagi kontent bilan Kashf qilish varagʻini koʻrsatish';
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
	@override String get exportDialogTitle => 'Plezy sozlamalarini eksport qilish';
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
		one: 'Bu undagi barcha ${n} qismni va uning faylini oʻchiradi.',
		other: 'Bu undagi barcha ${n} qismni va ularning fayllarini oʻchiradi.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n,
		one: 'Bu element ${n} fayl shaklida saqlanadi va u oʻchiriladi.',
		other: 'Bu element ${n} faylda saqlanadi va ularning barchasi oʻchiriladi.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n,
		one: 'Xuddi shu faylda yana ${n} qism saqlanadi va u ham oʻchiriladi:',
		other: 'Xuddi shu faylda yana ${n} qism saqlanadi va ular ham oʻchiriladi:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'Plezy qaysi fayllar olib tashlanishini tekshira olmadi, shuning uchun u yuqorida koʻrsatilgan elementdan koʻproq narsani oʻchirishi mumkin. Bekor qilib qaytadan urining yoki baribir oʻchiring.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'Serveringiz ushbu element uchun fayl tafsilotlarini taqdim etmadi, shuning uchun Plezy qaysi fayllar olib tashlanishini tekshira olmaydi. U yuqorida koʻrsatilgan elementdan koʻproq narsani oʻchirishi mumkin.';
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
	@override String zoomPercent({required Object percent}) => 'Masshtab %${percent}';
	@override late final _Translations$videoControls$pipErrors$uz pipErrors = _Translations$videoControls$pipErrors$uz._(_root);
	@override String get chapters => 'Boʻlimlar';
	@override String get noChaptersAvailable => 'Boʻlimlar mavjud emas';
	@override String get queue => 'Navbat';
	@override String get noQueueItems => 'Navbatda elementlar yoʻq';
	@override String get noAudioDevicesAvailable => 'Mavjud audio qurilmalar yoʻq';
	@override String get searchSubtitles => 'Subtitr qidirish';
	@override String get language => 'Til';
	@override String get noSubtitlesFound => 'Subtitr topilmadi';
	@override String get subtitleDownloaded => 'Subtitr yuklab olindi';
	@override String get subtitleDownloadedNotApplied => 'Subtitr yuklab olindi, lekin qoʻllanilmadi';
	@override String get subtitleDownloadFailed => 'Subtitrni yuklab boʻlmadi';
	@override String get searchLanguages => 'Tillardan qidirish...';
	@override String get skipIntro => 'Kirishni oʻtkazish';
	@override String get skipCredits => 'Titrlardan oʻtish';
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
		one: 'Koʻrilgan ${n} yuklama avtomatik oʻchirildi',
		other: 'Koʻrilgan ${n} yuklama avtomatik oʻchirildi',
	);
	@override String get removedFromContinueWatching => '"Tomoshani davom ettirish"dan oʻchirildi';
	@override String errorLoading({required Object error}) => 'Xatolik: ${error}';
	@override String get searchPartialResults => 'Baʼzi media serverlarda qidiruv amalga oshmadi. Mavjud natijalar koʻrsatilmoqda.';
	@override String get streamInterrupted => 'Oqim uzildi. Qayta urinish uchun ijro tugmasini bosing.';
	@override String get liveStreamInterrupted => 'Jonli oqim uzildi. Qayta urinish uchun ijro tugmasini bosing.';
	@override String get fileInfoNotAvailable => 'Fayl haqida maʼlumot mavjud emas';
	@override String get playbackAuthenticationRequired => 'Ushbu elementni ijro etish uchun serverga qaytadan kiring.';
	@override String get playbackServerUnavailable => 'Media serveri mavjud emas. Keyinroq qaytadan urinib koʻring.';
	@override String get playbackDataInvalid => 'Server notoʻgʻri ijro maʼlumotlarini qaytardi.';
	@override String get playbackCancelled => 'Ijro bekor qilindi.';
	@override String get playbackFailed => 'Ijroni ishga tushirishda xatolik.';
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
	@override String get logsUploaded => 'Jurnallar yuklandi';
	@override String get logsUploadFailed => 'Jurnallarni yuklab boʻlmadi';
	@override String get logId => 'Jurnal ID-si';
	@override String get burnedSubtitlesUseMenu => 'Subtitrlar bu oqim tasviriga singdirilgan. Ularni subtitr menyusidan oʻzgartiring.';
	@override String get noVideoUrl => 'Video URL mavjud emas';
	@override String get playbackNoMediaSources => 'Server ijro etiladigan media manbalarini qaytarmadi';
	@override String get playbackDataNotPrepared => 'Ijro maʼlumotlari tayyor boʻlishidan oldin boshlandi';
	@override String get streamSelectionUnavailable => 'Bu manba uchun oqim tanlash imkoni yoʻq';
	@override String get streamSelectionFailed => 'Tanlangan oqimlarni qoʻllab boʻlmadi';
	@override String get serverUnavailableForProfile => 'Faol profil uchun hech qanday server mavjud emas';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$uz extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
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
	@override String get addPlezyProfile => 'Plezy profilini qoʻshish';
	@override String get switchingProfile => 'Profil almashtirilmoqda…';
	@override String get deleteThisProfileTitle => 'Ushbu profil oʻchirilsinmi?';
	@override String deleteThisProfileMessage({required Object displayName}) => '${displayName} oʻchiriladi. Ulanishlarga taʼsir qilmaydi.';
	@override String get active => 'Faol';
	@override String get manage => 'Boshqarish';
	@override String get delete => 'Oʻchirish';
	@override String get signOut => 'Chiqish';
	@override String get signOutPlexTitle => 'Plex-dan chiqilsinmi?';
	@override String signOutPlexMessage({required Object displayName}) => '${displayName} va barcha Plex Home foydalanuvchilari oʻchiriladi.';
	@override String get signedOutPlex => 'Plex-dan chiqdingiz.';
	@override String get signOutFailed => 'Chiqish amalga oshmadi.';
	@override String get sectionTitle => 'Profillar';
	@override String get summarySingle => 'Boshqariladigan foydalanuvchilarni birlashtirish uchun profillar qoʻshing';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} profil · faol: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} profil';
	@override String get removeConnectionTitle => 'Ulanish oʻchirilsinmi?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => '${displayName} foydalanuvchisining ${connectionLabel} kirish huquqi oʻchiriladi.';
	@override String get deleteProfileTitle => 'Profil oʻchirilsinmi?';
	@override String deleteProfileMessage({required Object displayName}) => '${displayName} va uning ulanishlari oʻchiriladi.';
	@override String get profileNameLabel => 'Profil nomi';
	@override String get pinProtectionLabel => 'PIN himoyasi';
	@override String get pinManagedByPlex => 'PIN kodni Plex boshqaradi. plex.tv saytida tahrirlang.';
	@override String get noPinSetEditOnPlex => 'PIN kod oʻrnatilmagan.';
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
	@override String get borrowExplain => 'Boshqa profilning ulanishidan foydalaning.';
	@override String get borrowEmpty => 'Hali foydalanadigan hech narsa yoʻq.';
	@override String get borrowEmptySubtitle => 'Avval boshqa profilga Plex yoki Jellyfin ulang.';
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
}

// Path: connections
class _Translations$connections$uz extends Translations$connections$en {
	_Translations$connections$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Ulanishlar';
	@override String get addConnection => 'Ulanish qoʻshish';
	@override String get addConnectionSubtitleNoProfile => 'Plex orqali kiring yoki Jellyfin serveriga ulaning';
	@override String addConnectionSubtitleScoped({required Object displayName}) => '${displayName} profiliga qoʻshish';
	@override String sessionExpiredOne({required Object name}) => '${name} uchun seans vaqti tugadi';
	@override String sessionExpiredMany({required Object count}) => '${count} server uchun seans vaqti tugadi';
	@override String get signInAgain => 'Qaytadan kirish';
	@override String editMediaBrowserTitle({required Object product}) => '${product} ulanishini tahrirlash';
	@override String editMediaBrowserIntro({required Object serverName}) => '${serverName} uchun URL-larni qoʻshing yoki olib tashlang. Plezy eng kam kechikishga ega boʻlgan mavjud URL-dan foydalanadi.';
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
	@override String get storedOnAccount => 'Bu parametrlar hisobning oʻzida saqlanadi — unga kirilgan har bir ilova ulardan foydalanadi, jumladan boshqa qurilmalaringizdagi Plezy ham.';
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
		one: '${n} ta nom',
		other: '${n} ta nom',
	);
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
}

// Path: libraries
class _Translations$libraries$uz extends Translations$libraries$en {
	_Translations$libraries$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
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
}

// Path: about
class _Translations$about$uz extends Translations$about$en {
	_Translations$about$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Dastur haqida';
	@override String get openSourceLicenses => 'Ochiq kodli litsenziyalar';
	@override String versionLabel({required Object version}) => 'Versiya ${version}';
	@override String get appDescription => 'Flutter asosidagi qulay Plex va Jellyfin mijozi';
	@override String get viewLicensesDescription => 'Uchinchi tomon kutubxonalarining litsenziyalarini koʻrish';
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
}

// Path: startup
class _Translations$startup$uz extends Translations$startup$en {
	_Translations$startup$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'Plezy ishga tusha olmadi';
	@override String get failedBody => 'Ishga tushirish paytida nimadir xato ketdi. Quyidagi tafsilotlar aynan nima muvaffaqiyatsiz boʻlganini koʻrsatadi.';
	@override String get failedBodyRepairable => 'Plezyning saqlangan sozlamalar fayli shikastlangan va Plezy ishga tushishidan oldin uni qayta tiklash kerak. Qayta urinish yordam bermaydi — Saqlashni tiklashni tanlang.';
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
	@override String get repairBodySessionsUncertain => 'Trekerlar (MAL, AniList, Simkl, Trakt) va Seerr alohida saqlanadi va ular saqlanib qolishi ham, yoʻqolishi ham mumkin. Plezy aynan nimani saqlaganini sizga xabar qiladi.';
	@override String get repairConfirm => 'Tiklash';
	@override String get repairSucceeded => 'Saqlash tiklandi';
	@override String get repairNeedsRestart => 'Saqlash tiklandi — qayta ishga tushirish kerak';
	@override String get restartRequiredBody => 'Maʼlumotlaringiz tiklandi, lekin Plezy ulardan foydalanishi uchun yangidan ishga tushishi kerak. Plezy-ni yoping va qayta oching.';
	@override String get quitPlezy => 'Plezy-dan chiqish';
	@override String get repairFailed => 'Tiklash amalga oshmadi';
	@override String get repairKeptSignIns => 'Serverlaringiz va profillaringiz hali ham tizimga kirgan.';
	@override String get repairLostSignIns => 'Saqlangan kirish maʼlumotlaringizni himoya qiluvchi kalitni tiklab boʻlmadi. Har bir server va profilga qaytadan kirishingiz kerak boʻladi.';
	@override String get repairLostSessions => 'Kamida bitta treker yoki Seerr ulanishi yoʻqoldi va uni qayta ulash kerak.';
	@override String get backupTitle => 'Shikastlangan faylning nusxasi saqlab qoʻyildi';
	@override String get backupWarning => 'Unda kirish hisob maʼlumotlaringiz bor. Uni yuklamang yoki baham koʻrmang.';
	@override String get deleteBackup => 'Nusxani oʻchirish';
	@override String get backupDeleted => 'Nusxa oʻchirildi.';
	@override String get previousFailureTitle => 'Plezy oxirgi marta ishga tushmadi';
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
	@override String get title => 'Kashf qilish';
	@override String get selectSource => 'Manbani tanlang';
	@override late final _Translations$explore$rows$uz rows = _Translations$explore$rows$uz._(_root);
	@override late final _Translations$explore$status$uz status = _Translations$explore$status$uz._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n,
		one: '${n} qism',
		other: '${n} qism',
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
		one: '${n} ta natija',
		other: '${n} ta natija',
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
	@override String get unknownHub => 'Nomaʼlum';
	@override String get unknownError => 'Nomaʼlum xatolik';
	@override String channelNumber({required Object number}) => '${number}-kanal';
	@override String get unknownChannel => 'Nomaʼlum kanal';
	@override String get live => 'JONLI EFIR';
	@override String get reloadGuide => 'Jadvalni yangilash';
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
	@override String get favoritesLoadFailed => 'Tanlanganlarni yuklab boʻlmadi.';
	@override String get favoritesUpdateFailed => 'Tanlanganlarni yangilab boʻlmadi.';
	@override String get joinSession => 'Seansga qoʻshilish';
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
	@override String get rulesProcessRequested => 'Qoidalarni qayta baholash soʻraldi';
	@override String get recordShow => 'Shouni yozib olish';
	@override late final _Translations$liveTv$recordSettings$uz recordSettings = _Translations$liveTv$recordSettings$uz._(_root);
	@override String startingInMinutes({required Object minutes}) => '${minutes} daqiqadan keyin boshlanadi';
	@override String dayAtTime({required Object day, required Object time}) => '${day}, soat ${time} da';
	@override String invalidPlaybackData({required Object product}) => '${product} Jonli TV ijrosi uchun notoʻgʻri maʼlumot qaytardi';
	@override String get failedToStartChannel => 'Jonli kanalni boshlab boʻlmadi';
	@override String get failedToBuildStreamUrl => 'Oqim URL-ini tuzib boʻlmadi';
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
	@override String deleteConfirm({required Object title}) => '"${title}" oʻchirilsinmi?';
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
	@override String itemCount({required Object count}) => '${count} element';
	@override String get oneItem => '1 element';
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
		one: '${n} tarona',
		other: '${n} tarona',
	);
	@override String get nowPlaying => 'Hozir ijro etilmoqda';
	@override String playingFrom({required Object title}) => '${title} manbasidan';
	@override String get queue => 'Navbat';
	@override String get clearQueue => 'Navbatni tozalash';
	@override String get lyrics => 'Musiqa matni';
	@override String get noLyrics => 'Musiqa matni yoʻq';
	@override String get sleepTimer => 'Uyqu taymeri';
	@override String get sleepTimerEndOfTrack => 'Taronaning oxiri';
	@override String sleepTimerMinutes({required Object n}) => '${n} daqiqa';
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
	@override String get createSession => 'Seans yaratish';
	@override String get creating => 'Yaratilmoqda...';
	@override String get joinSession => 'Seansga qoʻshilish';
	@override String get joining => 'Qoʻshilinmoqda...';
	@override String get controlMode => 'Boshqaruv rejimi';
	@override String get controlModeQuestion => 'Ijroni kim boshqara oladi?';
	@override String get hostOnly => 'Faqat tashkilotchi';
	@override String get anyone => 'Har kim';
	@override String get hostingSession => 'Seans tashkillashtirilmoqda';
	@override String get inSession => 'Seansda';
	@override String get sessionCode => 'Seans kodi';
	@override String get openSessionControls => 'Boshqaruv elementlarini ochish';
	@override String get copySessionCode => 'Seans kodini nusxalash';
	@override String get hostControlsPlayback => 'Ijroni tashkilotchi boshqaradi';
	@override String get anyoneCanControl => 'Ijroni har kim boshqara oladi';
	@override String get hostControls => 'Tashkilotchi boshqaradi';
	@override String get anyoneControls => 'Hamma boshqaradi';
	@override String get participants => 'Ishtirokchilar';
	@override String get host => 'Tashkilotchi';
	@override String get hostBadge => 'TASHKILOTCHI';
	@override String get youAreHost => 'Siz tashkilotchisiz';
	@override String get watchingWithOthers => 'Boshqalar bilan tomosha qilinmoqda';
	@override String get endSession => 'Seansni yakunlash';
	@override String get leaveSession => 'Seansdan chiqish';
	@override String get endSessionQuestion => 'Seans yakunlansinmi?';
	@override String get leaveSessionQuestion => 'Seansdan chiqasizmi?';
	@override String get endSessionConfirm => 'Bu barcha ishtirokchilar uchun seansni yakunlaydi.';
	@override String get leaveSessionConfirm => 'Siz seansdan uzilasiz.';
	@override String get endSessionConfirmOverlay => 'Bu barcha uchun tomosha seansini yakunlaydi.';
	@override String get leaveSessionConfirmOverlay => 'Tomosha seansidan uzilasiz.';
	@override String get end => 'Yakunlash';
	@override String get leave => 'Chiqish';
	@override String get syncing => 'Sinxronlanmoqda...';
	@override String get joinWatchSession => 'Tomosha seansiga qoʻshilish';
	@override String get enterCodeHint => '5 xonali kodni kiriting';
	@override String get pasteFromClipboard => 'Xotiradan joylash';
	@override String get pleaseEnterCode => 'Seans kodini kiriting';
	@override String get codeMustBe5Chars => 'Seans kodi 5 ta belgidan iborat boʻlishi kerak';
	@override String get joinInstructions => 'Tashkilotchining seans kodini kiriting.';
	@override String get failedToCreate => 'Seansni yaratib boʻlmadi';
	@override String get failedToJoin => 'Seansga qoʻshilib boʻlmadi';
	@override String get sessionCodeCopied => 'Seans kodi nusxalandi';
	@override String get relayUnreachable => 'Rele serveriga ulanib boʻlmadi.';
	@override String get reconnectingToHost => 'Tashkilotchiga qayta ulanilmoqda...';
	@override String get currentPlayback => 'Joriy ijro';
	@override String get joinCurrentPlayback => 'Joriy ijroga qoʻshilish';
	@override String get joinCurrentPlaybackDescription => 'Tashkilotchi koʻrayotgan joyga oʻting';
	@override String get failedToOpenCurrentPlayback => 'Joriy ijroni ochib boʻlmadi';
	@override String participantJoined({required Object name}) => '${name} qoʻshildi';
	@override String participantLeft({required Object name}) => '${name} chiqdi';
	@override String participantPaused({required Object name}) => '${name} toʻxtatdi';
	@override String participantResumed({required Object name}) => '${name} davom ettirdi';
	@override String participantSeeked({required Object name}) => '${name} vaqtni oʻzgartirdi';
	@override String participantBuffering({required Object name}) => '${name} buferlamoqda';
	@override String participantNeedsUpdate({required Object name}) => '${name} eski versiyada';
	@override String resumingWithout({required Object name}) => '${name} hisobga olinmasdan davom ettirilmoqda';
	@override String get waitingForParticipants => 'Boshqalarning yuklashini kutilmoqda...';
	@override String waitingForName({required Object name}) => '${name} kutilmoqda...';
	@override String get recentRooms => 'Yaqindagi xonalar';
	@override String get renameRoom => 'Xona nomini oʻzgartirmoqchimisiz?';
	@override String get removeRoom => 'Oʻchirish';
	@override String get guestSwitchUnavailable => 'Oʻtib boʻlmadi';
	@override String get guestSwitchFailed => 'Oʻtib boʻlmadi — kontent topilmadi';
	@override String get defaultDisplayName => 'Foydalanuvchi';
	@override late final _Translations$watchTogether$errors$uz errors = _Translations$watchTogether$errors$uz._(_root);
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
	@override String get storageFull => 'Xotira toʻlganligi sababli yuklash toʻxtatildi.';
	@override String episodesQueued({required Object count}) => '${count} qism yuklash navbatiga qoʻshildi';
	@override String get downloadDeleted => 'Yuklama oʻchirildi';
	@override String deleteConfirm({required Object title}) => '"${title}" ushbu qurilmadan oʻchirilsinmi?';
	@override String get cancelledDownloadTitle => 'Toʻxtatilgan yuklama';
	@override String get cancelledDownloadMessage => 'Ushbu yuklash toʻxtatildi.';
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
	@override String get deleteAll => 'Barchasini oʻchirish';
	@override String get selectVersion => 'Versiyani tanlash';
	@override String get allEpisodes => 'Barcha qismlar';
	@override String get unwatchedOnly => 'Faqat koʻrilmaganlar';
	@override String nextNUnwatched({required Object count}) => 'Keyingi ${count} koʻrilmagan';
	@override String get customAmount => 'Boshqa miqdor...';
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
	@override String get activeSyncRules => 'Faol sinxronlash qoidalari';
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
	@override String get syncRuleNotAvailableForProfile => 'Joriy profil uchun mavjud emas';
	@override String get syncRuleUnknownServer => 'Nomaʼlum server';
	@override String get syncRuleListCreated => 'Sinxronlash qoidasi yaratildi';
	@override late final _Translations$downloads$backgroundWarning$uz backgroundWarning = _Translations$downloads$backgroundWarning$uz._(_root);
	@override String get unknownShow => 'Nomaʼlum serial';
	@override String get unknownSeason => 'Nomaʼlum mavsum';
	@override String get unknownAlbum => 'Nomaʼlum albom';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} ta yakunlandi';
	@override String get errorFileNotFound => 'Fayl topilmadi (404)';
	@override String get errorDownloadFailed => 'Yuklab boʻlmadi';
	@override String errorPostProcessing({required Object error}) => 'Keyingi ishlov berishda xatolik: ${error}';
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
	@override String get normalSpeed => 'Normal';
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
	@override String get audioOutputSurround => 'Surround';
	@override String get audioOutputSpatial => 'Fazoviy audio';
	@override String get audioOutputStereo => 'Stereo';
	@override String get audioNormalization => 'Ovoz balandligini meʼyorlashtirish';
	@override String get audioDownmix => 'Stereoga oʻtkazish';
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
}

// Path: matchScreen
class _Translations$matchScreen$uz extends Translations$matchScreen$en {
	_Translations$matchScreen$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get match => 'Moslashtirish...';
	@override String get fixMatch => 'Moslikni tuzatish...';
	@override String get unmatch => 'Moslikni oʻchirish';
	@override String get unmatchConfirm => 'Ushbu moslik oʻchirilsinmi?';
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
	@override String get disconnectConfirmBody => 'Plezy Trakt-ga maʼlumot yuborishni toʻxtatadi.';
	@override String get scrobble => 'Real vaqt rejimida kuzatish';
	@override String get scrobbleDescription => 'Ijro paytida Trakt-ga maʼlumot yuborish.';
	@override String get watchedSync => 'Koʻrish holatini sinxronlash';
	@override String get watchedSyncDescription => 'Plezy-da belgilanganda Trakt-da ham belgilanadi.';
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
	@override String get disconnectConfirmBody => 'Plezy ushbu Seerr manzilini oʻchiradi.';
	@override String get request => 'Soʻrov yuborish';
	@override String get request4k => '4K soʻrov yuborish';
	@override String get seasons => 'Mavsumlar';
	@override String get allSeasons => 'Barcha mavsumlar';
	@override String get advancedOptions => 'Kengaytirilgan';
	@override String get destinationServer => 'Moʻljal server';
	@override String get qualityProfile => 'Sifat profili';
	@override String get rootFolder => 'Asosiy jild';
	@override String get languageProfile => 'Til profili';
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
	@override String get scrobbleDescription => 'Roʻyxatingizni avtomatik yangilang.';
	@override String disconnectConfirm({required Object service}) => '${service} uzilsinmi?';
	@override String disconnectConfirmBody({required Object service}) => 'Plezy ${service} yangilanishini toʻxtatadi.';
	@override String connectFailed({required Object service}) => '${service} ulana olmadi. Qaytadan urinib koʻring.';
	@override late final _Translations$services$names$uz names = _Translations$services$names$uz._(_root);
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
	@override String get signInWithPlexCardSubtitle => 'Ushbu qurilmani avtorizatsiya qiling.';
	@override String get signInWithPlexCardSubtitleScoped => 'Plex hisobini avtorizatsiya qiling.';
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
}

// Path: common.ratingSource
class _Translations$common$ratingSource$uz extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get critic => 'Tanqidchilar';
	@override String get audience => 'Tomoshabinlar';
	@override String get imdb => 'IMDb';
	@override String get tmdb => 'TMDB';
	@override String get rottenTomatoes => 'Rotten Tomatoes';
	@override String get simkl => 'Simkl';
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get trakt => 'Trakt';
	@override String get rottenTomatoesCritic => 'Rotten Tomatoes tanqidchilari';
	@override String get rottenTomatoesAudience => 'Rotten Tomatoes tomoshabinlari';
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
	@override String get shaderToggle => 'Sheyderlarni yoqish/oʻchirish';
	@override String get skipMarker => 'Intro/Titrlarni oʻtkazib yuborish';
	@override String get screenshot => 'Ekran tasvirini olish';
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
		one: '${n} ta izoh',
		other: '${n} ta izoh',
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
	@override String get lightNovel => 'Light novel';
	@override String get novel => 'Roman';
	@override String get visualNovel => 'Visual novel';
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
		one: '${n} foydalanuvchi tavsiya qilgan',
		other: '${n} foydalanuvchi tavsiya qilgan',
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

// Path: watchTogether.errors
class _Translations$watchTogether$errors$uz extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String get timedOut => 'Rele serveri oʻz vaqtida javob bermadi';
	@override String get connectionLost => 'Seans tayyor boʻlmasidan ulanish uzildi';
	@override String get invalidRelayResponse => 'Rele serveri kutilmagan javob yubordi';
	@override String get sessionEnded => 'Tashkilotchi seansni tugatdi';
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
	@override String get sheetIntro => 'Android Plezy-ning fonda ishonchli yuklab olishiga toʻsqinlik qilmoqda.';
	@override String get sheetIntroDegraded => 'Qurilmangiz Plezy fonda qachon yuklay olishini cheklamoqda.';
	@override String get reasonBackgroundRestricted => 'Plezy-ning fondagi faoliyati cheklangan. Batareya yoki fondagi foydalanishni "Cheklanmagan" qilib belgilang.';
	@override String get reasonStandbyRestricted => 'Android Plezy-ni cheklangan kutish holatiga oʻtkazdi. Batareya foydalanishini "Cheklanmagan" qilib belgilang.';
	@override String get reasonDownloadChannelBlocked => 'Yuklash bildirishnomalari oʻchirilgan, shuning uchun jarayon koʻrsatkichi va boshqaruv elementlari mavjud boʻlmasligi mumkin.';
	@override String get reasonNotificationsDisabled => 'Bildirishnomalar oʻchirilgan. Android 13 va undan yangi versiyalarda uzoq davom etadigan fondagi yuklamalar uchun ular talab qilinadi.';
	@override String get reasonDataSaver => 'Trafik tejash yoqilgan, bu mobil internetda fondagi yuklamalarni bloklaydi. Wi-Fi orqali yuklamalar ishlashi kerak.';
	@override String get reasonOemUnknown => 'Plezy fonda boʻlganida yuklamalar bir necha marta toʻxtadi. Plezy-ning batareya yoki fondagi foydalanish sozlamalarini tekshiring.';
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
	@override String get discoveryDescription => 'Bir xil Plex hisobidagi Plezy qurilmalari bu yerda koʻrinadi';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Ulanilmoqda...';
	@override String get searchingForDevices => 'Qurilmalar qidirilmoqda...';
	@override String get noDevicesFound => 'Tarmoqda qurilmalar topilmadi';
	@override String get noDevicesHint => 'Kompyuterda Plezy-ni oching va bir xil Wi-Fi-ga ulaning';
	@override String get availableDevices => 'Mavjud qurilmalar';
	@override String get manualConnection => 'Qoʻlda ulanish';
	@override String get cryptoInitFailed => 'Xavfsiz ulanish xatoligi. Avval Plex-ga kiring.';
	@override String get validationHostRequired => 'Xost manzilini kiriting';
	@override String get validationHostFormat => 'Format IP:port koʻrinishida boʻlishi kerak';
	@override String get connectionTimedOut => 'Ulanish vaqti tugadi.';
	@override String get sessionNotFound => 'Qurilma topilmadi.';
	@override String get authFailed => 'Autentifikatsiya xatoligi.';
	@override String failedToConnect({required Object error}) => 'Ulanib boʻlmadi: ${error}';
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

// Path: services.deviceCode
class _Translations$services$deviceCode$uz extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$uz._(TranslationsUz root) : this._root = root, super.internal(root);

	final TranslationsUz _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Plezy-ni ${service} xizmatida faollashtiring';
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
			'app.title' => 'Plezy',
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
			'auth.localDataRecoveryRequired' => 'Plezy mahalliy kirish maʼlumotlarini tiklay olmadi. Iltimos, qaytadan kiring.',
			'auth.pinCheckRejected' => 'Plex PIN tekshiruvi rad etildi',
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
			'common.ratingSource.critic' => 'Tanqidchilar',
			'common.ratingSource.audience' => 'Tomoshabinlar',
			'common.ratingSource.imdb' => 'IMDb',
			'common.ratingSource.tmdb' => 'TMDB',
			'common.ratingSource.rottenTomatoes' => 'Rotten Tomatoes',
			'common.ratingSource.simkl' => 'Simkl',
			'common.ratingSource.mal' => 'MyAnimeList',
			'common.ratingSource.anilist' => 'AniList',
			'common.ratingSource.trakt' => 'Trakt',
			'common.ratingSource.rottenTomatoesCritic' => 'Rotten Tomatoes tanqidchilari',
			'common.ratingSource.rottenTomatoesAudience' => 'Rotten Tomatoes tomoshabinlari',
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
			'settings.title' => 'Sozlamalar',
			'settings.supportDeveloper' => 'Plezy-ni qoʻllab-quvvatlash',
			'settings.supportDeveloperDescription' => 'Dasturchini Liberapay orqali qoʻllab-quvvatlang',
			'settings.language' => 'Til',
			'settings.theme' => 'Mavzu',
			'settings.appearance' => 'Tashqi koʻrinish',
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
			'settings.libraryDensity' => 'Kutubxona zichligi',
			'settings.displayScale' => 'Ekran miqyosi',
			'settings.compact' => 'Ixcham',
			'settings.comfortable' => 'Qulay',
			'settings.gridSpacing' => 'Toʻr oraligʻi',
			'settings.gridSpacingTight' => 'Zich',
			'settings.gridSpacingNormal' => 'Normal',
			'settings.gridSpacingSpacious' => 'Keng',
			'settings.tvCornerSpotlightBackdrop' => 'Burchak yoritish foni',
			'settings.tvCornerSpotlightBackdropDescription' => 'Fonni toʻliq ekran oʻrniga yuqori oʻng burchakda koʻrsatish',
			'settings.viewMode' => 'Koʻrish rejimi',
			'settings.gridView' => 'Toʻrsimon',
			'settings.listView' => 'Roʻyxat',
			'settings.showHeroSection' => 'Asosiy boʻlimni koʻrsatish',
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
			'settings.alwaysKeepSidebarOpenDescription' => 'Yon menyu ochiq holatda qoladi',
			'settings.showUnwatchedCount' => 'Koʻrilmaganlar sonini koʻrsatish',
			'settings.showUnwatchedCountDescription' => 'Seriallar va mavsumlarda koʻrilmagan qismlar sonini koʻrsatish',
			'settings.showEpisodeNumberOnCards' => 'Kartochkalarda qism raqamini koʻrsatish',
			'settings.showEpisodeNumberOnCardsDescription' => 'Qism kartochkalarida mavsum va qism raqamini koʻrsatish',
			'settings.showSeasonPostersOnTabs' => 'Varaqlarda mavsum posterlarini koʻrsatish',
			'settings.showSeasonPostersOnTabsDescription' => 'Har bir mavsum posterini oʻz boʻlimida koʻrsatish',
			'settings.tvFullCardLayout' => 'Toʻliq TV kartochkalari',
			'settings.tvFullCardLayoutDescription' => 'Faqat rasmdan iborat TV kartochkalaridan foydalanish',
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
			'settings.defaultQualityTitle' => 'Standart sifat',
			'settings.cellularQualityTitle' => 'Mobil tarmoqda standart sifat',
			'settings.cellularQualitySameAsDefault' => 'Standart sifat bilan bir xil',
			'settings.musicQualityTitle' => 'Musiqa sifati',
			'settings.subtitleStyling' => 'Subtitr sozlamalari',
			'settings.subtitleStylingDescription' => 'Subtitrlar koʻrinishini moslashtiring',
			'settings.smallSkipDuration' => 'Kichik oʻtkazish vaqti',
			'settings.largeSkipDuration' => 'Katta oʻtkazish vaqti',
			'settings.rewindOnResume' => 'Davom ettirganda orqaga qaytarish',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} soniya',
			'settings.defaultSleepTimer' => 'Standart uyqu taymeri',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} daqiqa',
			'settings.rememberTrackSelections' => 'Har bir film/serial uchun ovoz/subtitr tanlovini eslab qolish',
			'settings.rememberTrackSelectionsDescription' => 'Har bir media uchun ovoz va subtitr sozlamalarini saqlash',
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
			'settings.watchTogetherRelayDescription' => 'Xususiy rele oʻrnating. Barcha bir xil serverdan foydalanishi kerak.',
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
			'settings.importSettingsInvalidFile' => 'Ushbu fayl toʻgʻri Plezy sozlamalar fayli emas',
			'settings.importSettingsNoUser' => 'Sozlamalarni import qilishdan oldin tizimga kiring',
			'settings.shortcutsReset' => 'Tugmalar birlashmasi standart holatga qaytarildi',
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
			'settings.playNextCountdown' => 'Keyingi qism sanogʻi',
			'settings.playNextCountdownImmediate' => 'Darhol ijro etish',
			'settings.autoSkipIntro' => 'Kirish qismini (Intro) avtomatik oʻtkazish',
			'settings.autoSkipIntroDescription' => 'Bir necha soniyadan soʻng kirish qismlarini avtomatik oʻtkazish',
			'settings.autoSkipCredits' => 'Titrlarni avtomatik oʻtkazish',
			'settings.autoSkipCreditsDescription' => 'Titrlarni oʻtkazib yuborish va keyingi qismni ijro etish',
			'settings.forceSkipMarkerFallback' => 'Zahira belgilarini majburlash',
			'settings.forceSkipMarkerFallbackDescription' => 'Plex belgilari boʻlsa ham boʻlim sarlavhasi shablonlaridan foydalanish',
			'settings.autoSkipDelay' => 'Avtomatik oʻtkazish kechikishi',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Avtomatik oʻtkazishdan oldin ${seconds} soniya kutilsin',
			'settings.introPattern' => 'Kirish qismi belgisi shabloni',
			'settings.introPatternDescription' => 'Boʻlim sarlavhalarida introni topish uchun Regex shabloni',
			'settings.creditsPattern' => 'Titr belgisi shabloni',
			'settings.creditsPatternDescription' => 'Boʻlim sarlavhalarida titrlarni topish uchun Regex shabloni',
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
			'settings.cellularDownloadBlocked' => 'Mobil tarmoqda yuklash taqiqlangan. Wi-Fi-dan foydalaning.',
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
			'settings.tunneledPlaybackDescription' => 'Video tunnellashdan foydalanish. HDR ijrosida ekran qora boʻlsa, oʻchiring.',
			'settings.audioPassthrough' => 'Ovozni toʻgʻridan-toʻgʻri oʻtkazish (Passthrough)',
			'settings.audioPassthroughDescription' => 'Dolby/DTS ovozini qayta kodlamasdan resiver yoki televizoringizga yuboradi va atroflicha ovozni saqlaydi. Ovoz boʻlmasa, oʻchiring.',
			'settings.audioPassthroughDescriptionAppleTv' => 'Dolby Digital Plus uchun Apple dekoderidan foydalanish.',
			'settings.audioDownmix' => 'Stereoga oʻtkazish (Downmix)',
			'settings.audioDownmixDescription' => 'Koʻp kanalli ovozni stereo dinamiklar uchun ikki kanalga tushirish',
			'settings.downmixCenterBoost' => 'Markaziy kanalni kuchaytirish',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Kuchaytirish (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Oʻtkazishda ovozni meʼyorlashtirish',
			'settings.audioDownmixNormalizeDescription' => 'Ovoz buzilishining oldini olish uchun darajani tushirish.',
			'settings.dvConversionMode' => 'Dolby Vision oʻtkazmasi',
			'settings.dvConversionModeDescription' => 'ExoPlayer-ning Dolby Vision Profile 7 fayllarini qayta ishlash rejimini tanlang.',
			'settings.dvConversionAuto' => 'Avtomatik',
			'settings.dvConversionNative' => 'Ichki / Oʻchirilgan',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Qurilma imkoniyatlaridan foydalanish',
			'settings.dvConversionNativeDescription' => 'Ichki DV7 rejimini majburlash',
			'settings.dvConversionDv81Description' => 'Dolby Vision profile 8.1 formatiga oʻtkazish',
			'settings.dvConversionHevcStripDescription' => 'Dolby Vision qatlamlarini olib tashlash va HEVC sifatida koʻrsatish',
			'settings.deinterlace' => 'Interleysni olib tashlash',
			'settings.deinterlaceDescription' => 'Interleys videodagi taroqsimon artefaktlarni olib tashlash (faqat mpv pleyerida)',
			'settings.requireProfileSelectionOnOpen' => 'Ochilganda profilni soʻrash',
			'settings.requireProfileSelectionOnOpenDescription' => 'Ilova ochilgan har safar profilni tanlashni koʻrsatish',
			'settings.forceTvMode' => 'TV rejimini majburlash',
			'settings.forceTvModeDescription' => 'TV interfeysini majburiy yoqish.',
			'settings.startInFullscreen' => 'Toʻliq ekranda boshlash',
			'settings.startInFullscreenDescription' => 'Plezy-ni ochganda toʻliq ekran rejimida ochish',
			'settings.exitFullscreenOnPlayerClose' => 'Pleyer yopilganda toʻliq ekrandan chiqish',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Video pleyerni yopganda avtomatik ravishda toʻliq ekrandan chiqish',
			'settings.autoHidePerformanceOverlay' => 'Unumdorlik panelini avto-yashirish',
			'settings.autoHidePerformanceOverlayDescription' => 'Unumdorlik panelini boshqaruv tugmalari bilan birga yashirish',
			'settings.showNavBarLabels' => 'Navigatsiya paneli matnlarini koʻrsatish',
			'settings.showNavBarLabelsDescription' => 'Navigatsiya belgilarining ostida matnni koʻrsatish',
			'settings.startupSection' => 'Boshlangʻich boʻlim',
			'settings.showExploreTab' => 'Kashf qilish varagʻini koʻrsatish',
			'settings.showExploreTabDescription' => 'Plex Discover va ulangan kuzatuvchilardagi kontent bilan Kashf qilish varagʻini koʻrsatish',
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
			'settings.exportDialogTitle' => 'Plezy sozlamalarini eksport qilish',
			'search.hint' => 'Filmlar, seriallar, musiqa qidirish...',
			'search.tryDifferentTerm' => 'Boshqa qidiruv soʻzini kiriting',
			'search.searchYourMedia' => 'Medialaringizdan qidiring',
			'search.enterTitleActorOrKeyword' => 'Nomini, aktyorni yoki kalit soʻzni kiriting',
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
			'hotkeys.actions.shaderToggle' => 'Sheyderlarni yoqish/oʻchirish',
			'hotkeys.actions.skipMarker' => 'Intro/Titrlarni oʻtkazib yuborish',
			'hotkeys.actions.screenshot' => 'Ekran tasvirini olish',
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
			_ => null,
		} ?? switch (path) {
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
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: 'Bu undagi barcha ${n} qismni va uning faylini oʻchiradi.', other: 'Bu undagi barcha ${n} qismni va ularning fayllarini oʻchiradi.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: 'Bu element ${n} fayl shaklida saqlanadi va u oʻchiriladi.', other: 'Bu element ${n} faylda saqlanadi va ularning barchasi oʻchiriladi.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: 'Xuddi shu faylda yana ${n} qism saqlanadi va u ham oʻchiriladi:', other: 'Xuddi shu faylda yana ${n} qism saqlanadi va ular ham oʻchiriladi:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'Plezy qaysi fayllar olib tashlanishini tekshira olmadi, shuning uchun u yuqorida koʻrsatilgan elementdan koʻproq narsani oʻchirishi mumkin. Bekor qilib qaytadan urining yoki baribir oʻchiring.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'Serveringiz ushbu element uchun fayl tafsilotlarini taqdim etmadi, shuning uchun Plezy qaysi fayllar olib tashlanishini tekshira olmaydi. U yuqorida koʻrsatilgan elementdan koʻproq narsani oʻchirishi mumkin.',
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
			'tooltips.shufflePlay' => 'Aralashtirib ijro etish',
			'tooltips.playTrailer' => 'Treylerni koʻrish',
			'tooltips.markAsWatched' => 'Koʻrilgan deb belgilash',
			'tooltips.markAsUnwatched' => 'Koʻrilmagan deb belgilash',
			'audioTracks.track' => ({required Object n}) => 'Audio yoʻlak ${n}',
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
			'videoControls.zoomPercent' => ({required Object percent}) => 'Masshtab %${percent}',
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
			'videoControls.language' => 'Til',
			'videoControls.noSubtitlesFound' => 'Subtitr topilmadi',
			'videoControls.subtitleDownloaded' => 'Subtitr yuklab olindi',
			'videoControls.subtitleDownloadedNotApplied' => 'Subtitr yuklab olindi, lekin qoʻllanilmadi',
			'videoControls.subtitleDownloadFailed' => 'Subtitrni yuklab boʻlmadi',
			'videoControls.searchLanguages' => 'Tillardan qidirish...',
			'videoControls.skipIntro' => 'Kirishni oʻtkazish',
			'videoControls.skipCredits' => 'Titrlardan oʻtish',
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
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: 'Koʻrilgan ${n} yuklama avtomatik oʻchirildi', other: 'Koʻrilgan ${n} yuklama avtomatik oʻchirildi', ), 
			'messages.removedFromContinueWatching' => '"Tomoshani davom ettirish"dan oʻchirildi',
			'messages.errorLoading' => ({required Object error}) => 'Xatolik: ${error}',
			'messages.searchPartialResults' => 'Baʼzi media serverlarda qidiruv amalga oshmadi. Mavjud natijalar koʻrsatilmoqda.',
			'messages.streamInterrupted' => 'Oqim uzildi. Qayta urinish uchun ijro tugmasini bosing.',
			'messages.liveStreamInterrupted' => 'Jonli oqim uzildi. Qayta urinish uchun ijro tugmasini bosing.',
			'messages.fileInfoNotAvailable' => 'Fayl haqida maʼlumot mavjud emas',
			'messages.playbackAuthenticationRequired' => 'Ushbu elementni ijro etish uchun serverga qaytadan kiring.',
			'messages.playbackServerUnavailable' => 'Media serveri mavjud emas. Keyinroq qaytadan urinib koʻring.',
			'messages.playbackDataInvalid' => 'Server notoʻgʻri ijro maʼlumotlarini qaytardi.',
			'messages.playbackCancelled' => 'Ijro bekor qilindi.',
			'messages.playbackFailed' => 'Ijroni ishga tushirishda xatolik.',
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
			'messages.logsUploaded' => 'Jurnallar yuklandi',
			'messages.logsUploadFailed' => 'Jurnallarni yuklab boʻlmadi',
			'messages.logId' => 'Jurnal ID-si',
			'messages.burnedSubtitlesUseMenu' => 'Subtitrlar bu oqim tasviriga singdirilgan. Ularni subtitr menyusidan oʻzgartiring.',
			'messages.noVideoUrl' => 'Video URL mavjud emas',
			'messages.playbackNoMediaSources' => 'Server ijro etiladigan media manbalarini qaytarmadi',
			'messages.playbackDataNotPrepared' => 'Ijro maʼlumotlari tayyor boʻlishidan oldin boshlandi',
			'messages.streamSelectionUnavailable' => 'Bu manba uchun oqim tanlash imkoni yoʻq',
			'messages.streamSelectionFailed' => 'Tanlangan oqimlarni qoʻllab boʻlmadi',
			'messages.serverUnavailableForProfile' => 'Faol profil uchun hech qanday server mavjud emas',
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
			'mpvConfig.embeddedVoHint' => 'Linux-da vo, gpu-context va gpu-api e\'tiborga olinmaydi: ichki video har doim video tekisligida vo=libmpv orqali ko\'rsatiladi va gpu-next (ArtCNN kabi compute shaderlar uchun zarur) ichki rejimda ishlay olmaydi.',
			'dialog.confirmAction' => 'Harakatni tasdiqlash',
			'profiles.addPlezyProfile' => 'Plezy profilini qoʻshish',
			'profiles.switchingProfile' => 'Profil almashtirilmoqda…',
			'profiles.deleteThisProfileTitle' => 'Ushbu profil oʻchirilsinmi?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => '${displayName} oʻchiriladi. Ulanishlarga taʼsir qilmaydi.',
			'profiles.active' => 'Faol',
			'profiles.manage' => 'Boshqarish',
			'profiles.delete' => 'Oʻchirish',
			'profiles.signOut' => 'Chiqish',
			'profiles.signOutPlexTitle' => 'Plex-dan chiqilsinmi?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => '${displayName} va barcha Plex Home foydalanuvchilari oʻchiriladi.',
			'profiles.signedOutPlex' => 'Plex-dan chiqdingiz.',
			'profiles.signOutFailed' => 'Chiqish amalga oshmadi.',
			'profiles.sectionTitle' => 'Profillar',
			'profiles.summarySingle' => 'Boshqariladigan foydalanuvchilarni birlashtirish uchun profillar qoʻshing',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} profil · faol: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} profil',
			'profiles.removeConnectionTitle' => 'Ulanish oʻchirilsinmi?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => '${displayName} foydalanuvchisining ${connectionLabel} kirish huquqi oʻchiriladi.',
			'profiles.deleteProfileTitle' => 'Profil oʻchirilsinmi?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => '${displayName} va uning ulanishlari oʻchiriladi.',
			'profiles.profileNameLabel' => 'Profil nomi',
			'profiles.pinProtectionLabel' => 'PIN himoyasi',
			'profiles.pinManagedByPlex' => 'PIN kodni Plex boshqaradi. plex.tv saytida tahrirlang.',
			'profiles.noPinSetEditOnPlex' => 'PIN kod oʻrnatilmagan.',
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
			'profiles.borrowExplain' => 'Boshqa profilning ulanishidan foydalaning.',
			'profiles.borrowEmpty' => 'Hali foydalanadigan hech narsa yoʻq.',
			'profiles.borrowEmptySubtitle' => 'Avval boshqa profilga Plex yoki Jellyfin ulang.',
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
			'connections.sectionTitle' => 'Ulanishlar',
			'connections.addConnection' => 'Ulanish qoʻshish',
			'connections.addConnectionSubtitleNoProfile' => 'Plex orqali kiring yoki Jellyfin serveriga ulaning',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => '${displayName} profiliga qoʻshish',
			'connections.sessionExpiredOne' => ({required Object name}) => '${name} uchun seans vaqti tugadi',
			'connections.sessionExpiredMany' => ({required Object count}) => '${count} server uchun seans vaqti tugadi',
			'connections.signInAgain' => 'Qaytadan kirish',
			'connections.editMediaBrowserTitle' => ({required Object product}) => '${product} ulanishini tahrirlash',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => '${serverName} uchun URL-larni qoʻshing yoki olib tashlang. Plezy eng kam kechikishga ega boʻlgan mavjud URL-dan foydalanadi.',
			'accountPreferences.sectionTitle' => 'Hisob sozlamalari',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => '${account} hisobida saqlangan audio, subtitr va kutubxona parametrlari',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => '${count} ta hisobda saqlangan audio, subtitr va kutubxona parametrlari',
			'accountPreferences.pickAccount' => 'Har bir hisob oʻz sozlamalarini saqlaydi. Tahrirlash uchun birini tanlang.',
			'accountPreferences.storedOnAccount' => 'Bu parametrlar hisobning oʻzida saqlanadi — unga kirilgan har bir ilova ulardan foydalanadi, jumladan boshqa qurilmalaringizdagi Plezy ham.',
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
			'discover.extras' => 'Treylerlar va qoʻshimchalar',
			'discover.studio' => 'Studiya',
			'discover.rating' => 'Reyting',
			'discover.director' => 'Rejissyor',
			'discover.directors' => 'Rejissyorlar',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'TV Shou',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} daq qoldi',
			'discover.moreLikeThis' => 'Oʻxshashlar',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: '${n} ta nom', other: '${n} ta nom', ), 
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
			_ => null,
		} ?? switch (path) {
			'libraries.filterCategories.favorites' => 'Tanlanganlar',
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
			'about.title' => 'Dastur haqida',
			'about.openSourceLicenses' => 'Ochiq kodli litsenziyalar',
			'about.versionLabel' => ({required Object version}) => 'Versiya ${version}',
			'about.appDescription' => 'Flutter asosidagi qulay Plex va Jellyfin mijozi',
			'about.viewLicensesDescription' => 'Uchinchi tomon kutubxonalarining litsenziyalarini koʻrish',
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
			'startup.failedTitle' => 'Plezy ishga tusha olmadi',
			'startup.failedBody' => 'Ishga tushirish paytida nimadir xato ketdi. Quyidagi tafsilotlar aynan nima muvaffaqiyatsiz boʻlganini koʻrsatadi.',
			'startup.failedBodyRepairable' => 'Plezyning saqlangan sozlamalar fayli shikastlangan va Plezy ishga tushishidan oldin uni qayta tiklash kerak. Qayta urinish yordam bermaydi — Saqlashni tiklashni tanlang.',
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
			'startup.repairBodySessionsUncertain' => 'Trekerlar (MAL, AniList, Simkl, Trakt) va Seerr alohida saqlanadi va ular saqlanib qolishi ham, yoʻqolishi ham mumkin. Plezy aynan nimani saqlaganini sizga xabar qiladi.',
			'startup.repairConfirm' => 'Tiklash',
			'startup.repairSucceeded' => 'Saqlash tiklandi',
			'startup.repairNeedsRestart' => 'Saqlash tiklandi — qayta ishga tushirish kerak',
			'startup.restartRequiredBody' => 'Maʼlumotlaringiz tiklandi, lekin Plezy ulardan foydalanishi uchun yangidan ishga tushishi kerak. Plezy-ni yoping va qayta oching.',
			'startup.quitPlezy' => 'Plezy-dan chiqish',
			'startup.repairFailed' => 'Tiklash amalga oshmadi',
			'startup.repairKeptSignIns' => 'Serverlaringiz va profillaringiz hali ham tizimga kirgan.',
			'startup.repairLostSignIns' => 'Saqlangan kirish maʼlumotlaringizni himoya qiluvchi kalitni tiklab boʻlmadi. Har bir server va profilga qaytadan kirishingiz kerak boʻladi.',
			'startup.repairLostSessions' => 'Kamida bitta treker yoki Seerr ulanishi yoʻqoldi va uni qayta ulash kerak.',
			'startup.backupTitle' => 'Shikastlangan faylning nusxasi saqlab qoʻyildi',
			'startup.backupWarning' => 'Unda kirish hisob maʼlumotlaringiz bor. Uni yuklamang yoki baham koʻrmang.',
			'startup.deleteBackup' => 'Nusxani oʻchirish',
			'startup.backupDeleted' => 'Nusxa oʻchirildi.',
			'startup.previousFailureTitle' => 'Plezy oxirgi marta ishga tushmadi',
			'licenses.relatedPackages' => 'Bogʻliq paketlar',
			'licenses.license' => 'Litsenziya',
			'licenses.licenseNumber' => ({required Object number}) => 'Litsenziya ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} litsenziya',
			'navigation.libraries' => 'Kutubxonalar',
			'navigation.downloads' => 'Yuklamalar',
			'navigation.liveTv' => 'Jonli TV',
			'navigation.explore' => 'Kashf qilish',
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
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: '${n} qism', other: '${n} qism', ), 
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
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: '${n} ta izoh', other: '${n} ta izoh', ), 
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
			'explore.sourceMaterial.lightNovel' => 'Light novel',
			'explore.sourceMaterial.novel' => 'Roman',
			'explore.sourceMaterial.visualNovel' => 'Visual novel',
			'explore.sourceMaterial.game' => 'Oʻyin',
			'explore.sourceMaterial.webComic' => 'Veb-komiks',
			'explore.sourceMaterial.musicRelease' => 'Musiqa',
			'explore.sourceMaterial.otherMedia' => 'Boshqa',
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
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: '${n} foydalanuvchi tavsiya qilgan', other: '${n} foydalanuvchi tavsiya qilgan', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => '${who} tavsiya qilgan',
			'explore.detail.favoritedBy' => ({required Object who}) => '${who} tanlanganlarga qoʻshgan',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} hali efirga chiqmagan',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'Tomoshabinlarning ${percent} tavsiya qilgan',
			'explore.detail.relatedTitles' => 'Bogʻliq nomlar',
			'explore.detail.background' => 'Orqa fon',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: '${n} ta natija', other: '${n} ta natija', ), 
			'liveTv.title' => 'Jonli TV',
			'liveTv.guide' => 'Dasturlar jadvali',
			'liveTv.noChannels' => 'Mavjud kanallar yoʻq',
			'liveTv.noDvr' => 'Serverda DVR sozlanmagan',
			'liveTv.serverUnavailable' => 'Jonli TV serveri mavjud emas.',
			'liveTv.serverNotConnected' => 'Jonli TV serveriga ulanmagan.',
			'liveTv.noPrograms' => 'Dastur haqida maʼlumot yoʻq',
			'liveTv.liveStreamFailed' => 'Jonli oqim xatoligi',
			'liveTv.unknownProgram' => 'Nomaʼlum dastur',
			'liveTv.unknownHub' => 'Nomaʼlum',
			'liveTv.unknownError' => 'Nomaʼlum xatolik',
			'liveTv.channelNumber' => ({required Object number}) => '${number}-kanal',
			'liveTv.unknownChannel' => 'Nomaʼlum kanal',
			'liveTv.live' => 'JONLI EFIR',
			'liveTv.reloadGuide' => 'Jadvalni yangilash',
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
			'liveTv.favoritesLoadFailed' => 'Tanlanganlarni yuklab boʻlmadi.',
			'liveTv.favoritesUpdateFailed' => 'Tanlanganlarni yangilab boʻlmadi.',
			'liveTv.joinSession' => 'Seansga qoʻshilish',
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
			'liveTv.rulesProcessRequested' => 'Qoidalarni qayta baholash soʻraldi',
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
			'collections.title' => 'Toʻplamlar',
			'collections.collection' => 'Toʻplam',
			'collections.empty' => 'Toʻplam boʻsh',
			'collections.deleteCollection' => 'Toʻplamni oʻchirish',
			'collections.deleteConfirm' => ({required Object title}) => '"${title}" oʻchirilsinmi?',
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
			'playlists.itemCount' => ({required Object count}) => '${count} element',
			'playlists.oneItem' => '1 element',
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
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uz'))(n, one: '${n} tarona', other: '${n} tarona', ), 
			'music.nowPlaying' => 'Hozir ijro etilmoqda',
			'music.playingFrom' => ({required Object title}) => '${title} manbasidan',
			'music.queue' => 'Navbat',
			'music.clearQueue' => 'Navbatni tozalash',
			'music.lyrics' => 'Musiqa matni',
			'music.noLyrics' => 'Musiqa matni yoʻq',
			'music.sleepTimer' => 'Uyqu taymeri',
			'music.sleepTimerEndOfTrack' => 'Taronaning oxiri',
			'music.sleepTimerMinutes' => ({required Object n}) => '${n} daqiqa',
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
			'watchTogether.createSession' => 'Seans yaratish',
			'watchTogether.creating' => 'Yaratilmoqda...',
			'watchTogether.joinSession' => 'Seansga qoʻshilish',
			'watchTogether.joining' => 'Qoʻshilinmoqda...',
			'watchTogether.controlMode' => 'Boshqaruv rejimi',
			'watchTogether.controlModeQuestion' => 'Ijroni kim boshqara oladi?',
			'watchTogether.hostOnly' => 'Faqat tashkilotchi',
			'watchTogether.anyone' => 'Har kim',
			'watchTogether.hostingSession' => 'Seans tashkillashtirilmoqda',
			'watchTogether.inSession' => 'Seansda',
			'watchTogether.sessionCode' => 'Seans kodi',
			'watchTogether.openSessionControls' => 'Boshqaruv elementlarini ochish',
			'watchTogether.copySessionCode' => 'Seans kodini nusxalash',
			'watchTogether.hostControlsPlayback' => 'Ijroni tashkilotchi boshqaradi',
			'watchTogether.anyoneCanControl' => 'Ijroni har kim boshqara oladi',
			'watchTogether.hostControls' => 'Tashkilotchi boshqaradi',
			'watchTogether.anyoneControls' => 'Hamma boshqaradi',
			'watchTogether.participants' => 'Ishtirokchilar',
			'watchTogether.host' => 'Tashkilotchi',
			'watchTogether.hostBadge' => 'TASHKILOTCHI',
			'watchTogether.youAreHost' => 'Siz tashkilotchisiz',
			'watchTogether.watchingWithOthers' => 'Boshqalar bilan tomosha qilinmoqda',
			'watchTogether.endSession' => 'Seansni yakunlash',
			'watchTogether.leaveSession' => 'Seansdan chiqish',
			'watchTogether.endSessionQuestion' => 'Seans yakunlansinmi?',
			'watchTogether.leaveSessionQuestion' => 'Seansdan chiqasizmi?',
			'watchTogether.endSessionConfirm' => 'Bu barcha ishtirokchilar uchun seansni yakunlaydi.',
			'watchTogether.leaveSessionConfirm' => 'Siz seansdan uzilasiz.',
			'watchTogether.endSessionConfirmOverlay' => 'Bu barcha uchun tomosha seansini yakunlaydi.',
			'watchTogether.leaveSessionConfirmOverlay' => 'Tomosha seansidan uzilasiz.',
			'watchTogether.end' => 'Yakunlash',
			'watchTogether.leave' => 'Chiqish',
			'watchTogether.syncing' => 'Sinxronlanmoqda...',
			'watchTogether.joinWatchSession' => 'Tomosha seansiga qoʻshilish',
			'watchTogether.enterCodeHint' => '5 xonali kodni kiriting',
			'watchTogether.pasteFromClipboard' => 'Xotiradan joylash',
			'watchTogether.pleaseEnterCode' => 'Seans kodini kiriting',
			'watchTogether.codeMustBe5Chars' => 'Seans kodi 5 ta belgidan iborat boʻlishi kerak',
			'watchTogether.joinInstructions' => 'Tashkilotchining seans kodini kiriting.',
			'watchTogether.failedToCreate' => 'Seansni yaratib boʻlmadi',
			'watchTogether.failedToJoin' => 'Seansga qoʻshilib boʻlmadi',
			'watchTogether.sessionCodeCopied' => 'Seans kodi nusxalandi',
			'watchTogether.relayUnreachable' => 'Rele serveriga ulanib boʻlmadi.',
			'watchTogether.reconnectingToHost' => 'Tashkilotchiga qayta ulanilmoqda...',
			'watchTogether.currentPlayback' => 'Joriy ijro',
			'watchTogether.joinCurrentPlayback' => 'Joriy ijroga qoʻshilish',
			'watchTogether.joinCurrentPlaybackDescription' => 'Tashkilotchi koʻrayotgan joyga oʻting',
			'watchTogether.failedToOpenCurrentPlayback' => 'Joriy ijroni ochib boʻlmadi',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} qoʻshildi',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} chiqdi',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} toʻxtatdi',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} davom ettirdi',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} vaqtni oʻzgartirdi',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} buferlamoqda',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name} eski versiyada',
			'watchTogether.resumingWithout' => ({required Object name}) => '${name} hisobga olinmasdan davom ettirilmoqda',
			'watchTogether.waitingForParticipants' => 'Boshqalarning yuklashini kutilmoqda...',
			'watchTogether.waitingForName' => ({required Object name}) => '${name} kutilmoqda...',
			'watchTogether.recentRooms' => 'Yaqindagi xonalar',
			'watchTogether.renameRoom' => 'Xona nomini oʻzgartirmoqchimisiz?',
			'watchTogether.removeRoom' => 'Oʻchirish',
			'watchTogether.guestSwitchUnavailable' => 'Oʻtib boʻlmadi',
			'watchTogether.guestSwitchFailed' => 'Oʻtib boʻlmadi — kontent topilmadi',
			'watchTogether.defaultDisplayName' => 'Foydalanuvchi',
			'watchTogether.errors.timedOut' => 'Rele serveri oʻz vaqtida javob bermadi',
			'watchTogether.errors.connectionLost' => 'Seans tayyor boʻlmasidan ulanish uzildi',
			'watchTogether.errors.invalidRelayResponse' => 'Rele serveri kutilmagan javob yubordi',
			'watchTogether.errors.sessionEnded' => 'Tashkilotchi seansni tugatdi',
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
			'downloads.storageFull' => 'Xotira toʻlganligi sababli yuklash toʻxtatildi.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} qism yuklash navbatiga qoʻshildi',
			'downloads.downloadDeleted' => 'Yuklama oʻchirildi',
			'downloads.deleteConfirm' => ({required Object title}) => '"${title}" ushbu qurilmadan oʻchirilsinmi?',
			'downloads.cancelledDownloadTitle' => 'Toʻxtatilgan yuklama',
			'downloads.cancelledDownloadMessage' => 'Ushbu yuklash toʻxtatildi.',
			'downloads.allEpisodesAlreadyDownloaded' => 'Barcha qismlar avvaldan yuklab olingan',
			'downloads.resumeDownload' => 'Yuklashni davom ettirish',
			'downloads.cancelledDownload' => 'Toʻxtatilgan yuklama',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (${status} sinxronlanmoqda)',
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
			'downloads.deleteAll' => 'Barchasini oʻchirish',
			'downloads.selectVersion' => 'Versiyani tanlash',
			'downloads.allEpisodes' => 'Barcha qismlar',
			'downloads.unwatchedOnly' => 'Faqat koʻrilmaganlar',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Keyingi ${count} koʻrilmagan',
			'downloads.customAmount' => 'Boshqa miqdor...',
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
			'downloads.activeSyncRules' => 'Faol sinxronlash qoidalari',
			'downloads.noSyncRules' => 'Sinxronlash qoidalari yoʻq',
			'downloads.manageSyncRule' => 'Sinxronlashni boshqarish',
			'downloads.editEpisodeCount' => 'Qismlar soni',
			'downloads.editSyncFilter' => 'Sinxronlash filtri',
			'downloads.syncAllItems' => 'Barcha elementlar sinxronlanadi',
			'downloads.syncUnwatchedItems' => 'Koʻrilmagan elementlar sinxronlanadi',
			_ => null,
		} ?? switch (path) {
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Server: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Mavjud',
			'downloads.syncRuleOffline' => 'Oflayn',
			'downloads.syncRuleSignInRequired' => 'Kirish talab etiladi',
			'downloads.syncRuleNotAvailableForProfile' => 'Joriy profil uchun mavjud emas',
			'downloads.syncRuleUnknownServer' => 'Nomaʼlum server',
			'downloads.syncRuleListCreated' => 'Sinxronlash qoidasi yaratildi',
			'downloads.backgroundWarning.bannerBlocked' => 'Ilovadan chiqqaningizda yuklamalar toʻxtaydi',
			'downloads.backgroundWarning.bannerDegraded' => 'Fondagi yuklamalar cheklangan boʻlishi mumkin',
			'downloads.backgroundWarning.bannerAction' => 'Batafsil',
			'downloads.backgroundWarning.sheetTitle' => 'Fondagi yuklamalar bloklangan',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Fondagi yuklamalar cheklangan boʻlishi mumkin',
			'downloads.backgroundWarning.sheetIntro' => 'Android Plezy-ning fonda ishonchli yuklab olishiga toʻsqinlik qilmoqda.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Qurilmangiz Plezy fonda qachon yuklay olishini cheklamoqda.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'Plezy-ning fondagi faoliyati cheklangan. Batareya yoki fondagi foydalanishni "Cheklanmagan" qilib belgilang.',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android Plezy-ni cheklangan kutish holatiga oʻtkazdi. Batareya foydalanishini "Cheklanmagan" qilib belgilang.',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Yuklash bildirishnomalari oʻchirilgan, shuning uchun jarayon koʻrsatkichi va boshqaruv elementlari mavjud boʻlmasligi mumkin.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Bildirishnomalar oʻchirilgan. Android 13 va undan yangi versiyalarda uzoq davom etadigan fondagi yuklamalar uchun ular talab qilinadi.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Trafik tejash yoqilgan, bu mobil internetda fondagi yuklamalarni bloklaydi. Wi-Fi orqali yuklamalar ishlashi kerak.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Plezy fonda boʻlganida yuklamalar bir necha marta toʻxtadi. Plezy-ning batareya yoki fondagi foydalanish sozlamalarini tekshiring.',
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
			'downloads.unknownShow' => 'Nomaʼlum serial',
			'downloads.unknownSeason' => 'Nomaʼlum mavsum',
			'downloads.unknownAlbum' => 'Nomaʼlum albom',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} ta yakunlandi',
			'downloads.errorFileNotFound' => 'Fayl topilmadi (404)',
			'downloads.errorDownloadFailed' => 'Yuklab boʻlmadi',
			'downloads.errorPostProcessing' => ({required Object error}) => 'Keyingi ishlov berishda xatolik: ${error}',
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
			'companionRemote.pairing.discoveryDescription' => 'Bir xil Plex hisobidagi Plezy qurilmalari bu yerda koʻrinadi',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Ulanilmoqda...',
			'companionRemote.pairing.searchingForDevices' => 'Qurilmalar qidirilmoqda...',
			'companionRemote.pairing.noDevicesFound' => 'Tarmoqda qurilmalar topilmadi',
			'companionRemote.pairing.noDevicesHint' => 'Kompyuterda Plezy-ni oching va bir xil Wi-Fi-ga ulaning',
			'companionRemote.pairing.availableDevices' => 'Mavjud qurilmalar',
			'companionRemote.pairing.manualConnection' => 'Qoʻlda ulanish',
			'companionRemote.pairing.cryptoInitFailed' => 'Xavfsiz ulanish xatoligi. Avval Plex-ga kiring.',
			'companionRemote.pairing.validationHostRequired' => 'Xost manzilini kiriting',
			'companionRemote.pairing.validationHostFormat' => 'Format IP:port koʻrinishida boʻlishi kerak',
			'companionRemote.pairing.connectionTimedOut' => 'Ulanish vaqti tugadi.',
			'companionRemote.pairing.sessionNotFound' => 'Qurilma topilmadi.',
			'companionRemote.pairing.authFailed' => 'Autentifikatsiya xatoligi.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Ulanib boʻlmadi: ${error}',
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
			'videoSettings.normalSpeed' => 'Normal',
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
			'videoSettings.audioOutputSurround' => 'Surround',
			'videoSettings.audioOutputSpatial' => 'Fazoviy audio',
			'videoSettings.audioOutputStereo' => 'Stereo',
			'videoSettings.audioNormalization' => 'Ovoz balandligini meʼyorlashtirish',
			'videoSettings.audioDownmix' => 'Stereoga oʻtkazish',
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
			'matchScreen.match' => 'Moslashtirish...',
			'matchScreen.fixMatch' => 'Moslikni tuzatish...',
			'matchScreen.unmatch' => 'Moslikni oʻchirish',
			'matchScreen.unmatchConfirm' => 'Ushbu moslik oʻchirilsinmi?',
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
			'trakt.disconnectConfirmBody' => 'Plezy Trakt-ga maʼlumot yuborishni toʻxtatadi.',
			'trakt.scrobble' => 'Real vaqt rejimida kuzatish',
			'trakt.scrobbleDescription' => 'Ijro paytida Trakt-ga maʼlumot yuborish.',
			'trakt.watchedSync' => 'Koʻrish holatini sinxronlash',
			'trakt.watchedSyncDescription' => 'Plezy-da belgilanganda Trakt-da ham belgilanadi.',
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
			'seerr.disconnectConfirmBody' => 'Plezy ushbu Seerr manzilini oʻchiradi.',
			'seerr.request' => 'Soʻrov yuborish',
			'seerr.request4k' => '4K soʻrov yuborish',
			'seerr.seasons' => 'Mavsumlar',
			'seerr.allSeasons' => 'Barcha mavsumlar',
			'seerr.advancedOptions' => 'Kengaytirilgan',
			'seerr.destinationServer' => 'Moʻljal server',
			'seerr.qualityProfile' => 'Sifat profili',
			'seerr.rootFolder' => 'Asosiy jild',
			'seerr.languageProfile' => 'Til profili',
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
			'services.title' => 'Xizmatlar',
			'services.hubSubtitle' => 'Koʻrish jarayonini sinxronlang va yangi kontent soʻrang.',
			'services.integrations' => 'Integratsiyalar',
			'services.notConnected' => 'Ulanmagan',
			'services.connectedAs' => ({required Object username}) => '@${username} sifatida ulandi',
			'services.scrobble' => 'Jarayonni avtomatik kuzatish',
			'services.scrobbleDescription' => 'Roʻyxatingizni avtomatik yangilang.',
			'services.disconnectConfirm' => ({required Object service}) => '${service} uzilsinmi?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'Plezy ${service} yangilanishini toʻxtatadi.',
			'services.connectFailed' => ({required Object service}) => '${service} ulana olmadi. Qaytadan urinib koʻring.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.deviceCode.title' => ({required Object service}) => 'Plezy-ni ${service} xizmatida faollashtiring',
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
			'addServer.addPlexTitle' => 'Plex orqali kirish',
			'addServer.pinExpired' => 'PIN kod vaqti tugadi.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Hisobni roʻyxatdan oʻtkazishda xatolik: ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => '${product} server URL-ini kiriting',
			'addServer.addConnectionTitle' => 'Ulanish qoʻshish',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => '${name} profiliga qoʻshish',
			'addServer.signInWithPlexCard' => 'Plex orqali kirish',
			'addServer.signInWithPlexCardSubtitle' => 'Ushbu qurilmani avtorizatsiya qiling.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Plex hisobini avtorizatsiya qiling.',
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
			_ => null,
		};
	}
}
