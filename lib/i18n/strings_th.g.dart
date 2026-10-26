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
class TranslationsTh extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsTh({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.th,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <th>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsTh _root = this; // ignore: unused_field

	@override 
	TranslationsTh $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsTh(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$th app = _Translations$app$th._(_root);
	@override late final _Translations$cast$th cast = _Translations$cast$th._(_root);
	@override late final _Translations$automation$th automation = _Translations$automation$th._(_root);
	@override late final _Translations$notifications$th notifications = _Translations$notifications$th._(_root);
	@override late final _Translations$appIcon$th appIcon = _Translations$appIcon$th._(_root);
	@override late final _Translations$auth$th auth = _Translations$auth$th._(_root);
	@override late final _Translations$common$th common = _Translations$common$th._(_root);
	@override late final _Translations$screens$th screens = _Translations$screens$th._(_root);
	@override late final _Translations$update$th update = _Translations$update$th._(_root);
	@override late final _Translations$appAccess$th appAccess = _Translations$appAccess$th._(_root);
	@override late final _Translations$settings$th settings = _Translations$settings$th._(_root);
	@override late final _Translations$themeEditor$th themeEditor = _Translations$themeEditor$th._(_root);
	@override late final _Translations$search$th search = _Translations$search$th._(_root);
	@override late final _Translations$hotkeys$th hotkeys = _Translations$hotkeys$th._(_root);
	@override late final _Translations$fileInfo$th fileInfo = _Translations$fileInfo$th._(_root);
	@override late final _Translations$mediaMenu$th mediaMenu = _Translations$mediaMenu$th._(_root);
	@override late final _Translations$rateSheet$th rateSheet = _Translations$rateSheet$th._(_root);
	@override late final _Translations$accessibility$th accessibility = _Translations$accessibility$th._(_root);
	@override late final _Translations$tooltips$th tooltips = _Translations$tooltips$th._(_root);
	@override late final _Translations$audioTracks$th audioTracks = _Translations$audioTracks$th._(_root);
	@override late final _Translations$videoControls$th videoControls = _Translations$videoControls$th._(_root);
	@override late final _Translations$messages$th messages = _Translations$messages$th._(_root);
	@override late final _Translations$subtitlingStyling$th subtitlingStyling = _Translations$subtitlingStyling$th._(_root);
	@override late final _Translations$mpvConfig$th mpvConfig = _Translations$mpvConfig$th._(_root);
	@override late final _Translations$dialog$th dialog = _Translations$dialog$th._(_root);
	@override late final _Translations$profiles$th profiles = _Translations$profiles$th._(_root);
	@override late final _Translations$connections$th connections = _Translations$connections$th._(_root);
	@override late final _Translations$accountPreferences$th accountPreferences = _Translations$accountPreferences$th._(_root);
	@override late final _Translations$discover$th discover = _Translations$discover$th._(_root);
	@override late final _Translations$errors$th errors = _Translations$errors$th._(_root);
	@override late final _Translations$libraries$th libraries = _Translations$libraries$th._(_root);
	@override late final _Translations$about$th about = _Translations$about$th._(_root);
	@override late final _Translations$serverSelection$th serverSelection = _Translations$serverSelection$th._(_root);
	@override late final _Translations$hubDetail$th hubDetail = _Translations$hubDetail$th._(_root);
	@override late final _Translations$logs$th logs = _Translations$logs$th._(_root);
	@override late final _Translations$detail$th detail = _Translations$detail$th._(_root);
	@override late final _Translations$startup$th startup = _Translations$startup$th._(_root);
	@override late final _Translations$licenses$th licenses = _Translations$licenses$th._(_root);
	@override late final _Translations$navigation$th navigation = _Translations$navigation$th._(_root);
	@override late final _Translations$explore$th explore = _Translations$explore$th._(_root);
	@override late final _Translations$liveTv$th liveTv = _Translations$liveTv$th._(_root);
	@override late final _Translations$collections$th collections = _Translations$collections$th._(_root);
	@override late final _Translations$playlists$th playlists = _Translations$playlists$th._(_root);
	@override late final _Translations$music$th music = _Translations$music$th._(_root);
	@override late final _Translations$watchTogether$th watchTogether = _Translations$watchTogether$th._(_root);
	@override late final _Translations$downloads$th downloads = _Translations$downloads$th._(_root);
	@override late final _Translations$shaders$th shaders = _Translations$shaders$th._(_root);
	@override late final _Translations$companionRemote$th companionRemote = _Translations$companionRemote$th._(_root);
	@override late final _Translations$videoSettings$th videoSettings = _Translations$videoSettings$th._(_root);
	@override late final _Translations$performanceOverlay$th performanceOverlay = _Translations$performanceOverlay$th._(_root);
	@override late final _Translations$externalPlayer$th externalPlayer = _Translations$externalPlayer$th._(_root);
	@override late final _Translations$metadataEdit$th metadataEdit = _Translations$metadataEdit$th._(_root);
	@override late final _Translations$matchScreen$th matchScreen = _Translations$matchScreen$th._(_root);
	@override late final _Translations$serverTasks$th serverTasks = _Translations$serverTasks$th._(_root);
	@override late final _Translations$trakt$th trakt = _Translations$trakt$th._(_root);
	@override late final _Translations$seerr$th seerr = _Translations$seerr$th._(_root);
	@override late final _Translations$services$th services = _Translations$services$th._(_root);
	@override late final _Translations$addServer$th addServer = _Translations$addServer$th._(_root);
	@override late final _Translations$watchLink$th watchLink = _Translations$watchLink$th._(_root);
	@override late final _Translations$homeLayout$th homeLayout = _Translations$homeLayout$th._(_root);
	@override late final _Translations$platform$th platform = _Translations$platform$th._(_root);
	@override late final _Translations$fileSources$th fileSources = _Translations$fileSources$th._(_root);
	@override late final _Translations$lending$th lending = _Translations$lending$th._(_root);
}

// Path: app
class _Translations$app$th extends Translations$app$en {
	_Translations$app$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: cast
class _Translations$cast$th extends Translations$cast$en {
	_Translations$cast$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => 'แคสต์ไปยังอุปกรณ์';
	@override String get searching => 'ค้นหาอุปกรณ์ Cast ...';
	@override String connectedTo({required Object device}) => 'เชื่อมต่อ ${device}';
	@override String get device => 'อุปกรณ์แคสต์';
	@override String get readyToCast => 'พร้อมแคสต์';
	@override String get subtitle => 'คำบรรยาย';
	@override String get serverNotAvailable => 'เซิร์ฟเวอร์สื่อไม่สามารถใช้ได้';
	@override String get stopCasting => 'หยุดแคสต์';
	@override String get castToDevice => 'แคสต์ไปยังอุปกรณ์';
	@override String get noEpisodeAvailable => 'ไม่มีส่วนที่สามารถปล่อยตัวได้';
	@override String get startFailed => 'ไม่สามารถเริ่ม casting ตรวจสอบเซิร์ฟเวอร์และลองอีกครั้ง';
}

// Path: automation
class _Translations$automation$th extends Translations$automation$en {
	_Translations$automation$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => 'ไม่มีเซสชั่นวิดีโอที่มีการใช้งานในการควบคุม';
	@override String get profileNotFound => 'ที่ Plezy โปรไฟล์ไม่สามารถพบได้';
}

// Path: notifications
class _Translations$notifications$th extends Translations$notifications$en {
	_Translations$notifications$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => 'ฉบับใหม่';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appIcon
class _Translations$appIcon$th extends Translations$appIcon$en {
	_Translations$appIcon$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'แอปไอคอน';
	@override String get defaultIcon => 'ค่าเริ่มต้น';
	@override String get current => 'หมายเลขรุ่น: Icon';
	@override String get locked => 'การเข้าถึงอายุการใช้งานที่จําเป็น';
	@override String get lockedHint => 'เริ่มต้นการทดสอบ 7 วันหรือล็อค PlezyNG สําหรับชีวิตเพื่อใช้ไอคอนทางเลือก';
	@override String get changeFailed => 'ไม่สามารถเปลี่ยนแอปไอคอน';
	@override String get launcherHint => 'สัญลักษณ์ใหม่จะปรากฏบนหน้าจอบ้านของคุณเมื่อคุณออกจาก PlezyNG';
	@override String get tvLauncherHint => 'แบนเนอร์ใหม่จะปรากฏเมื่อคุณออกจาก PlezyNG. Android TV สามารถยังคงแสดงแบนเนอร์เก่าจนกว่าทีวีจะเปิดใหม่';
	@override late final _Translations$appIcon$names$th names = _Translations$appIcon$names$th._(_root);
}

// Path: auth
class _Translations$auth$th extends Translations$auth$en {
	_Translations$auth$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'ลงทะเบียนกับ Plex';
	@override String get showQRCode => 'แสดงรหัส QR';
	@override String get authenticate => 'การรับรอง';
	@override String get authenticationTimeout => 'การรับรองเป็นเวลาแล้ว โปรดลองอีกครั้ง';
	@override String get scanQRToSignIn => 'สแกนรหัส QR นี้เพื่อลงทะเบียน';
	@override String get waitingForAuth => 'รอการรับรอง... ลงทะเบียนจากเบราว์เซอร์ของคุณ';
	@override String get useBrowser => 'ใช้เบราว์เซอร์';
	@override String get or => 'หรือ';
	@override String connectToMediaBrowser({required Object product}) => 'ติดต่อ ${product}';
	@override String get quickConnect => 'Quick Connect';
	@override String get useQuickConnect => 'ใช้การเชื่อมต่อด่วน';
	@override String get quickConnectInstructions => 'เปิด Quick Connect ใน Jellyfin และป้อนรหัสนี้';
	@override String get quickConnectWaiting => 'รอการอนุมัติ';
	@override String get quickConnectCancel => 'ยกเลิก';
	@override String get quickConnectExpired => 'Quick Connect หมดอายุ ลองอีกครั้ง';
	@override String get localDataRecoveryRequired => 'PlezyNG ไม่สามารถคืนข้อมูลการลงชื่อเข้าและข้อมูลการสะท้อนกลับในท้องถิ่นได้อย่างปลอดภัย โปรดลงชื่อเข้าอีกครั้ง';
	@override String get pinCheckRejected => 'การตรวจสอบ PIN Plex ได้รับการปฏิเสธ';
	@override String get connectToDirectPlex => 'เชื่อมต่อกับเซิร์ฟเวอร์ท้องถิ่น Plex';
}

// Path: common
class _Translations$common$th extends Translations$common$en {
	_Translations$common$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'ยกเลิก';
	@override String get save => 'บันทึก';
	@override String get close => 'ปิด';
	@override String get clear => 'หมายเหตุ';
	@override String get reset => 'รีเซ็ต';
	@override String get later => 'ต่อไป';
	@override String get submit => 'ส่ง';
	@override String get confirm => 'การยืนยัน';
	@override String get retry => 'การคืนเงิน';
	@override String get logout => 'ปล่อยออก';
	@override String get unknown => 'ที่เก็บข้อมูลไม่รู้จัก';
	@override String get refresh => 'การทําความเย็น';
	@override String get yes => 'ใช่';
	@override String get no => 'ไม่';
	@override String get delete => 'ลบ';
	@override String get edit => 'แก้ไข';
	@override String get shuffle => 'สุ่มเล่น';
	@override String get addTo => 'เพิ่มให้...';
	@override String get createNew => 'สร้างใหม่';
	@override String get connect => 'เชื่อมต่อ';
	@override String get disconnect => 'ยกเลิกการเชื่อมต่อ';
	@override String get play => 'เล่น';
	@override String get pause => 'หยุดชั่วคราว';
	@override String get resume => 'เล่นต่อ';
	@override String get error => 'ข้อผิดพลาด';
	@override String get search => 'ค้นหา';
	@override String get home => 'บ้าน';
	@override String get back => 'กลับ';
	@override String get settings => 'การตั้งค่า';
	@override String get mute => 'ปกติ';
	@override String get ok => 'ตกลง';
	@override String get off => 'ปิด';
	@override String get options => 'ตัวเลือก';
	@override String seasonNumber({required Object number}) => 'ฤดูกาล ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'ฉบับที่ ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'ประเภท ${number}';
	@override String get reconnect => 'การเชื่อมต่อ';
	@override String get viewAll => 'ดูทั้งหมด';
	@override String get checkingNetwork => 'การตรวจสอบเครือข่าย';
	@override String get loadingServers => 'เซิร์ฟเวอร์โหลด';
	@override String get connectingToServers => 'การเชื่อมต่อกับเซิร์ฟเวอร์';
	@override String get startingOfflineMode => 'เริ่มต้นแบบ offline...';
	@override String get loading => 'การโหลด...';
	@override String get fullscreen => 'เต็มหน้าจอ';
	@override String get exitFullscreen => 'หน้าจอแสดงผลเต็ม';
	@override String get pressBackAgainToExit => 'คลิกกลับเพื่อออก';
	@override late final _Translations$common$ratingSource$th ratingSource = _Translations$common$ratingSource$th._(_root);
	@override String get notAvailable => 'หมายเลขรุ่น: A';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
	@override late final _Translations$common$mediaKind$th mediaKind = _Translations$common$mediaKind$th._(_root);
}

// Path: screens
class _Translations$screens$th extends Translations$screens$en {
	_Translations$screens$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'ใบอนุญาต';
	@override String get switchProfile => 'โปรไฟล์สวิทช์';
	@override String get subtitleStyling => 'สไตล์ Subtitle';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'โลก';
}

// Path: update
class _Translations$update$th extends Translations$update$en {
	_Translations$update$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get available => 'การปรับปรุงที่มีอยู่';
	@override String versionAvailable({required Object version}) => 'รุ่น ${version} มีอยู่';
	@override String currentVersion({required Object version}) => 'อัพเดท: ${version}';
	@override String get skipVersion => 'ดาวน์โหลดเวอร์ชันนี้';
	@override String get viewRelease => 'ดูการปล่อย';
	@override String get latestVersion => 'คุณอยู่ในเวอร์ชันล่าสุด';
	@override String get checkFailed => 'ไม่สามารถตรวจสอบอัปเดตได้';
}

// Path: appAccess
class _Translations$appAccess$th extends Translations$appAccess$en {
	_Translations$appAccess$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'ลองทุกฟังก์ชั่นฟรีสําหรับ 7 วัน';
	@override String get description => 'เริ่มต้นการทดลองใช้ 7 วันพร้อมการเข้าถึงเต็มรูปแบบทุกฟังก์ชั่น PlezyNG ไม่มีค่าธรรมเนียมในระหว่างการทดลองใช้และไม่มีการสมัครสมาชิก หลังจากทดลองใช้การซื้อตลอดชีวิตในราคาของร้านค้าของคุณเปิดใช้งาน PlezyNGตลอดชีวิต';
	@override String get trialEndedDescription => 'ปล็อคฟังก์ชั่นทุกฟังก์ชั่นที่ PlezyNG สําหรับชีวิตด้วยการซื้อเดียวในราคาของร้านค้าของคุณ ไม่มีสมาชิก';
	@override String get startTrial => 'เริ่มต้นการทดลองฟรี 7 วัน';
	@override String get trialActive => 'การทดสอบเต็มรูปแบบ 7 วันของคุณจะใช้งานได้';
	@override String get trialEnded => 'การสอบถาม 7 วันของคุณจบลง';
	@override String get trialStartFailed => 'ฉันไม่สามารถบันทึกการทดสอบบนอุปกรณ์นี้ โปรดลองอีกครั้ง';
	@override String get lifetimeTitle => 'PlezyNG ปิดล็อคสําหรับชีวิต';
	@override String get lifetimeBody => 'ขอบคุณ! คุณสามารถเข้าถึงทุกฟังก์ชั่น PlezyNG ทุกชีวิต';
	@override String get manageTitle => 'PlezyNG การเข้าถึงตลอดชีวิต';
	@override String get manageDescription => 'ลองฟังก์ชั่นแต่ละอย่างฟรีเป็นเวลา 7 วันแล้วเปิดเปิดทุกอย่างตลอดชีวิตด้วยค่าใช้จ่ายเดียวในราคาของร้านค้าของคุณ';
	@override String buy({required Object price}) => 'ปล็อคฟังก์ชั่นทั้งหมดสําหรับ ${price}';
	@override String get loadingPrice => 'ราคาของร้านขายส่ง';
	@override String get retryPrice => 'ค่าใช้จ่าย Retry Lookup';
	@override String get restore => 'การซื้อคืนชีวิต';
	@override String get pending => 'การซื้อของคุณกําลังรอการชําระเงินหรือการอนุมัติ การเข้าถึงตลอดชีวิตจะเปิดตัวทันทีที่ร้านค้าเสร็จสมบูรณ์';
	@override String get storeUnavailable => 'การซื้อไม่สามารถใช้ได้ ตรวจสอบว่าคุณลงชื่อเข้าสู่ร้านค้าและการซื้อจะได้รับอนุญาตบนอุปกรณ์นี้';
	@override String get productNotFound => 'PlezyNG ชีวิตล็อคยังไม่ได้อยู่ในร้านค้านี้';
	@override String get productQueryFailed => 'ไม่สามารถโหลดราคาร้านค้าได้ ตรวจสอบการเชื่อมต่อของคุณและลองอีกครั้ง';
	@override String get purchaseFailed => 'การซื้อไม่ได้ผ่านการทดลองอีกครั้ง';
	@override String get restoreFailed => 'ฉันไม่สามารถเข้าถึงร้านค้าเพื่อรับคืนการซื้อของคุณ ลองอีกครั้ง';
	@override String get nothingToRestore => 'หมายเลขการซื้อตลอดชีวิต PlezyNG ได้รับการค้นหาสําหรับบัญชีร้านค้านี้';
}

// Path: settings
class _Translations$settings$th extends Translations$settings$en {
	_Translations$settings$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'การตั้งค่า';
	@override String get supportDeveloper => 'สนับสนุน PlezyNG';
	@override String get supportDeveloperDescription => 'การสนับสนุนการพัฒนา';
	@override String get lifetimeAccess => 'PlezyNG การเข้าถึงตลอดชีวิต';
	@override String get language => 'ภาษา';
	@override String get theme => 'ธีม';
	@override String get appearance => 'แสดง';
	@override String get detailPage => 'รายละเอียดหน้า';
	@override String get themeSongsEnabled => 'เล่นหัวข้อเพลง';
	@override String get themeSongsEnabledDescription => 'เล่นเพลงธีมที่มีอยู่ในขณะที่ดูรายละเอียดสื่อ';
	@override String get themeSongVolume => 'ธีมเพลงปริมาณ';
	@override String get videoPlayback => 'วิดีโอ Playback';
	@override String get videoPlaybackDescription => 'การตั้งค่าพฤติกรรม playback';
	@override String get advanced => 'ขั้นสูง';
	@override String get episodePosterMode => 'โพสต์สไตล์';
	@override String get seriesPoster => 'โพสต์ชุด';
	@override String get seasonPoster => 'โพสต์ฤดูกาล';
	@override String get episodeThumbnail => 'วินเทจ';
	@override String get showHeroSectionDescription => 'แสดงเนื้อหา carousel บนหน้าจอบ้าน';
	@override String get secondsLabel => 'วินาที';
	@override String get minutesLabel => 'นาที';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'ม';
	@override String durationHint({required Object min, required Object max}) => 'ใส่ค่า (${min}-${max})';
	@override String get systemTheme => 'ระบบ';
	@override String get lightTheme => 'แสง';
	@override String get darkTheme => 'ดํา';
	@override String get oledTheme => 'OLED';
	@override String get emberTheme => 'คน';
	@override String get glacierTheme => 'เหล็กกล้า';
	@override String get forestTheme => 'สวน';
	@override String get plumTheme => 'ปลั๊ก';
	@override String get paperTheme => 'กระดาษ';
	@override String get libraryDensity => 'ความหนาแน่นของห้องสมุด';
	@override String get displayScale => 'แสดง Scale';
	@override String get compact => 'คอมโพสิต';
	@override String get comfortable => 'ความสะดวกสบาย';
	@override String get gridSpacing => 'ไฟฉาย';
	@override String get gridSpacingTight => 'ตูด';
	@override String get gridSpacingNormal => 'หลักสูตร';
	@override String get gridSpacingSpacious => 'สเปค';
	@override String get tvCornerSpotlightBackdrop => 'คอร์เนอร์ Spotlight Backdrop';
	@override String get tvCornerSpotlightBackdropDescription => 'แสดงงานศิลปะในมุมด้านบนขวาแทนที่จะเติมหน้าจอ';
	@override String get viewMode => 'ดูแฟชั่น';
	@override String get gridView => 'กด';
	@override String get listView => 'รายการ';
	@override String get showHeroSection => 'แสดงส่วนฮีโร่';
	@override String get showHomeBackdrop => 'แสดง บ้าน Backdrop Artwork';
	@override String get showHomeBackdropDescription => 'แสดงงานศิลปะขนาดใหญ่ด้านหลังของเรือนบ้าน';
	@override String get contentScreensaverEnabled => 'แสดงเนื้อหา';
	@override String get contentScreensaverEnabledDescription => 'แสดงงานศิลปะเต็มหน้าจอหลังจากที่แอปเป็น idle';
	@override String get contentScreensaverDelay => 'เปิดหน้าจอซอฟต์แวร์หลังจาก';
	@override String get contentScreensaverLibraries => 'สกรีนซอฟต์แวร์';
	@override String get contentScreensaverLibrariesDescription => 'เลือกห้องสมุดที่จัดหางานศิลปะที่บันทึกหน้าจอ หากไม่มีการเลือกงานศิลปะจากห้องสมุดทั้งหมดจะใช้';
	@override String get contentScreensaverAllLibraries => 'ทุกไลบรารี';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} ห้องสมุดที่เลือก';
	@override String get contentScreensaverNoLibraries => 'ไม่มีห้องสมุดสื่อที่เชื่อมต่อ';
	@override String get contentScreensaverDismissHint => 'คลิกที่ปุ่มหรือปุ่มใด ๆ เพื่อยกเลิก';
	@override String get newEpisodeNotifications => 'การแจ้งเตือนฉบับใหม่';
	@override String get newEpisodeNotificationsDescription => 'บันทึกเมื่อส่วนใหม่จะถูกเพิ่มไปสู่การแสดงที่คุณจะถูกจับได้ ตรวจสอบในขณะที่ Plezy เปิด';
	@override String get continueWatchingRowSize => 'เก็บดูขนาดแถว';
	@override String continueWatchingRowSizeValue({required Object label}) => '${label} บัตร';
	@override String get rowSizeCompact => 'คอมโพสิต';
	@override String get rowSizeStandard => 'มาตรฐาน';
	@override String get rowSizeLarge => 'ใหญ่';
	@override String get continueWatchingAction => 'การดําเนินการต่อการตรวจสอบ';
	@override String get continueWatchingPlay => 'เล่น';
	@override String get continueWatchingDetails => 'รายละเอียดเปิด';
	@override String get episodeAction => 'การกระทํา';
	@override String get episodePlay => 'เล่น';
	@override String get episodeDetails => 'รายละเอียดเปิด';
	@override String get useGlobalHubs => 'ใช้ Home Layout';
	@override String get useGlobalHubsDescription => 'แสดงช่องบ้านแบบบูรณาการ ไม่ได้ใช้คําแนะนําของห้องสมุด';
	@override String get showServerNameOnHubs => 'แสดงชื่อเซิร์ฟเวอร์บน Hubs';
	@override String get showServerNameOnHubsDescription => 'แสดงชื่อเซิร์ฟเวอร์เสมอในหัวข้อ hub';
	@override String get groupLibrariesByServer => 'ห้องสมุดกลุ่มโดย Server';
	@override String get groupLibrariesByServerDescription => 'ห้องสมุดหน้ากลุ่มภายใต้เซิร์ฟเวอร์สื่อแต่ละครั้ง';
	@override String get alwaysKeepSidebarOpen => 'ปล่อยให้หน้าต่างเปิดเสมอ';
	@override String get alwaysKeepSidebarOpenDescription => 'บาร์ด้านข้างยังคงขยายและพื้นที่เนื้อหาปรับให้เหมาะสม';
	@override String get showUnwatchedCount => 'แสดง Unwatched Count';
	@override String get showUnwatchedCountDescription => 'แสดง episodes unwatched count on shows and seasons';
	@override String get showWatchedIndicators => 'แสดงตัวชี้วัดที่ได้รับการตรวจสอบ';
	@override String get showWatchedIndicatorsDescription => 'แสดงการตรวจสอบในภาพยนตร์การแสดงผลและ episodes ที่เห็น';
	@override String get showEpisodeNumberOnCards => 'แสดง Episode Number on Cards';
	@override String get showEpisodeNumberOnCardsDescription => 'แสดงฤดูกาลและหมายเลข episodes บนการ์ด episodes';
	@override String get showSeasonPostersOnTabs => 'แสดงกระดานฤดูกาลบนแท็บ';
	@override String get showSeasonPostersOnTabsDescription => 'แสดงโพสต์ของแต่ละฤดูกาลด้านบนแท็บของมัน';
	@override String get tvFullCardLayout => 'หมายเลขโทรทัศน์เต็ม';
	@override String get tvFullCardLayoutDescription => 'ใช้การ์ดทีวีรูปภาพเท่านั้นที่มีชื่อนักแสดง';
	@override String get focusGlow => 'ไฟฉาย';
	@override String get focusGlowDescription => 'ดําเนินการแสงอ่อนรอบคอบการ์ดที่มุ่งเน้น';
	@override String get visualEffects => 'ผลการมองเห็น';
	@override String get visualEffectsAuto => 'อัตโนมัติ';
	@override String get visualEffectsAutoDescription => 'ลดผลกระทบโดยอัตโนมัติบนอุปกรณ์ที่มีพลังงานต่ํา';
	@override String get visualEffectsFull => 'เต็ม';
	@override String get visualEffectsReduced => 'ลดลง';
	@override String get visualEffectsReducedDescription => 'การเคลื่อนไหวน้อยและงานศิลปะที่มีความละเอียดต่ํา';
	@override String get hideSpoilers => 'ซ่อน Spoilers สําหรับ Episodes Unwatched';
	@override String get hideSpoilersDescription => 'บลูรไทม์และคําอธิบายสําหรับ episodes ที่ไม่ได้สังเกต';
	@override String get playerBackend => 'ผู้เล่น Backend';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'การเข้ารหัสฮาร์ดแวร์';
	@override String get hardwareDecodingDescription => 'ใช้ความเร็วฮาร์ดแวร์เมื่อมี';
	@override String get playbackBuffer => 'บูฟเวอร์ Playback';
	@override String get playbackBufferAuto => 'รถยนต์ (แนะนํา)';
	@override String get playbackBufferLarge => 'ใหญ่';
	@override String get playbackBufferExtraLarge => 'ขนาดใหญ่';
	@override String get playbackBufferDescription => 'Buffer มากกว่าต่อการเชื่อมต่อที่ไม่เสถียร นอกจากนี้ยัง จํากัด โดย ขนาด Buffer';
	@override String get streamBufferSize => 'ขนาด Buffer';
	@override String streamBufferSizeValue({required Object size}) => '${size} MB';
	@override String get streamBufferSizeDescription => 'จํานวนวิดีโอที่จะโหลดก่อนเมื่อเล่นโดยตรง Transcodes stop at the server\'s own transcode buffer. 0 = Auto';
	@override String get streamBufferSizeExoNote => 'แทนที่ Playback Buffer เมื่อตั้งค่า, capped ที่ครึ่งของขอบหน่วยความจําของแอป';
	@override String get streamBufferMegabytes => 'มกเบตต์';
	@override String get defaultQualityTitle => 'คุณภาพที่กําหนดเอง';
	@override String get cellularQualityTitle => 'คุณภาพที่กําหนดเองในเซลล์';
	@override String get remoteQualityTitle => 'คุณภาพ Streaming ออนไลน์';
	@override String get remoteQualitySameAsDefault => 'เช่นเดียวกับคุณภาพที่กําหนดเอง';
	@override String get cellularQualitySameAsDefault => 'เช่นเดียวกับคุณภาพที่กําหนดเอง';
	@override String get directPlayCoveredQuality => 'เล่นวิดีโอขนาดเล็กในคุณภาพเดิม';
	@override String get directPlayCoveredQualityDescription => 'การเล่นวิดีโอโดยตรงอยู่ภายในข้อ จํากัด คุณภาพแทนที่จะรหัสพวกเขา';
	@override String get videoCodecs => 'วีดีโอโค้ด';
	@override String get videoCodecsDescription => 'โคเด็กที่ไม่ได้ตรวจสอบจะถูกรหัสผ่านโดยเซิร์ฟเวอร์';
	@override String get videoCodecsAlwaysAccepted => 'ได้รับการยอมรับเสมอ';
	@override String get musicQualityTitle => 'คุณภาพเพลง';
	@override String get subtitleStyling => 'สไตล์ Subtitle';
	@override String get subtitleStylingDescription => 'การปรับแต่งการปรากฏตัว Subtitle';
	@override String get smallSkipDuration => 'ระยะเวลาสกีขนาดเล็ก';
	@override String get largeSkipDuration => 'ระยะเวลา Skip';
	@override String get rewindOnResume => 'กลับไปสู่การสรุป';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(seconds,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} วินาที',
	);
	@override String get defaultSleepTimer => 'ระยะเวลาการนอนหลับแบบกําหนดเอง';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(minutes,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} นาที',
	);
	@override String get rememberTrackSelections => 'โปรดจําการเลือกติดตามตามแสดง / ภาพยนตร์';
	@override String get chooseTracksBeforePlayback => 'เลือกเสียงและหัวข้อก่อนที่จะเล่น';
	@override String get chooseTracksBeforePlaybackDescription => 'เลือกเสียงแหล่งที่มาและติดตามหัวข้อก่อนที่จะเริ่มต้นวิดีโอแต่ละครั้ง';
	@override String get alwaysShowSubtitlesOnDevice => 'แสดงหัวข้อในอุปกรณ์นี้เสมอ';
	@override String get alwaysShowSubtitlesOnDeviceDescription => 'เมื่อเซิร์ฟเวอร์ไม่มีหัวข้อที่เลือกให้เลือกเส้นทางในท้องถิ่น สิ่งนี้ไม่เปลี่ยนแปลงความต้องการของเซิร์ฟเวอร์';
	@override String get autoDownloadPreferredSubtitle => 'Fetch ปิดหัวข้อภาษาที่ชื่นชอบ';
	@override String get autoDownloadPreferredSubtitleDescription => 'เลือกหัวข้อที่มีอยู่ในภาษาที่คุณต้องการในท้องถิ่น หากไม่มีหัวข้อใด ๆ โปรดขอให้เซิร์ฟเวอร์จับหัวข้อหนึ่งเมื่อมีการสนับสนุน ตัวเลือกจะอยู่บนอุปกรณ์นี้';
	@override String get rememberTrackSelectionsDescription => 'การจัดเก็บเสียงและตัวเลือกหัวข้อโดยการแสดงหรือภาพยนตร์บนอุปกรณ์นี้';
	@override String get rememberTrackSelectionsBackendRule => 'ทํางานในท้องถิ่นกับ Plex, Jellyfin, และ Emby; Plex และ Jellyfin นอกจากนี้ยังสามารถบันทึกตัวเลือกบนเซิร์ฟเวอร์';
	@override String get followServerTrackSelections => 'ใช้ตัวเลือกติดตามต่อส่วนของเซิร์ฟเวอร์';
	@override String get followServerTrackSelectionsDescription => 'เมื่อมีการเปลี่ยนแปลงส่วนหนึ่งใช้เสียงและหัวข้อที่เลือกไว้บนเซิร์ฟเวอร์แทนที่จะดําเนินการตามตัวเลือกปัจจุบัน';
	@override String get resumeMusicOnLaunch => 'เสร็จสิ้นการประชุมดนตรี';
	@override String get resumeMusicOnLaunchDescription => 'เปิดใหม่เพลงสุดท้ายหยุดที่มันออกเมื่อแอปเริ่มต้น';
	@override String get showChapterMarkersOnTimeline => 'แสดงหมวดหมู่ บาร์ค้นหา';
	@override String get showChapterMarkersOnTimelineDescription => 'Segment the search bar ที่ขอบเขตบท';
	@override String get specialsOrdering => 'พิเศษในลําดับ episodes';
	@override String get specialsOrderingDescription => 'ที่พิเศษเล่นในคําสั่งของชั่วโมงของแสดง';
	@override String get specialsOrderingServer => 'ติดตามคําสั่งเซิร์ฟเวอร์';
	@override String get specialsOrderingAirDate => 'ระยะเวลาตามวันที่อากาศ';
	@override String get specialsOrderingLast => 'หลังจากฤดูกาลปกติ';
	@override String get clickVideoTogglesPlayback => 'คลิกที่วิดีโอเพื่อ toggle play/pause';
	@override String get clickVideoTogglesPlaybackDescription => 'คลิกวิดีโอเพื่อเล่น/หยุดแทนที่จะแสดงการควบคุม';
	@override String get videoPlayerControls => 'วิดีโอผู้เล่นควบคุม';
	@override String get keyboardShortcuts => 'คีย์บอร์ด Shortcuts';
	@override String get keyboardShortcutsDescription => 'ปรับแต่งคีย์บอร์ดสั้น ๆ';
	@override String get videoPlayerNavigation => 'วีดีโอ Player Navigation';
	@override String get videoPlayerNavigationDescription => 'ใช้คีย์ไฟเพื่อนําทางควบคุมวิดีโอเล่น';
	@override String get watchTogetherRelay => 'ดู Relay ร่วมกัน';
	@override String get watchTogetherRelayDescription => 'สาธารณะเปิด Watch ปาร์ตี้สื่อลามกถ้าคุณตั้งค่าของคุณเอง';
	@override String get watchTogetherRelayHint => 'https://my-relay.example.com';
	@override String get watchTogetherRelayInvalid => 'ป้อน URL หลักของเซิร์ฟเวอร์รีเลย์ที่ใช้ HTTP หรือ HTTPS ให้ถูกต้อง';
	@override String get crashReporting => 'การแจ้งเตือนความเสียหาย';
	@override String get crashReportingDescription => 'ส่งรายงานความล้มเหลวเพื่อช่วยปรับปรุงแอป';
	@override String get debugLogging => 'การเข้าสู่ระบบ Debug';
	@override String get debugLoggingDescription => 'อนุญาตให้บันทึกรายละเอียดสําหรับการแก้ปัญหา';
	@override String get viewLogs => 'ดูโลโก้';
	@override String get viewLogsDescription => 'ดูแอปพลิเคชันโลโก้';
	@override String get clearImageCache => 'ภาพที่ชัดเจน cache';
	@override String get clearImageCacheDescription => 'การทําศิลปะที่ซ่อนอยู่และรูปทรงขนาดเล็ก ภาพสามารถโหลดได้ช้าลงจนกว่าจะดาวน์โหลดอีกครั้ง';
	@override String get clearImageCacheSuccess => 'ภาพ cache ทําความสะอาดอย่างประสบความสําเร็จ';
	@override String get resetSettings => 'การตั้งค่าใหม่';
	@override String get resetSettingsDescription => 'ปรับปรุงการตั้งค่าที่กําหนดเอง สิ่งนี้ไม่สามารถลบได้';
	@override String get resetSettingsSuccess => 'การตั้งค่าใหม่ได้ดี';
	@override String get backup => 'คู่มือ';
	@override String get exportSettings => 'การตั้งค่าการส่งออก';
	@override String get exportSettingsDescription => 'เก็บความต้องการของคุณไปยังไฟล์';
	@override String get exportSettingsSuccess => 'การตั้งค่าที่ส่งออก';
	@override String get importSettings => 'การตั้งค่าการนําเข้า';
	@override String get importSettingsDescription => 'การกู้คืนความต้องการจากไฟล์';
	@override String get importSettingsConfirm => 'สิ่งนี้จะเปลี่ยนการตั้งค่าปัจจุบันของคุณ ต่อเนื่อง?';
	@override String get importSettingsSuccess => 'การตั้งค่าที่นําเข้า';
	@override String get importSettingsInvalidFile => 'ไฟล์นี้ไม่ได้รับการส่งออกการตั้งค่า PlezyNG';
	@override String get importSettingsNoUser => 'ลงทะเบียนก่อนนําเข้าการตั้งค่า';
	@override String get cloudBackup => 'คล็อค Backup';
	@override String get cloudBackupDescription => 'Backup settings portable to a WebDAV endpoint over HTTPS. การเชื่อมต่อเซิร์ฟเวอร์และการรับรองจะอยู่บนอุปกรณ์นี้';
	@override String get cloudBackupUrl => 'WebDAV JSON ไฟล์ URL';
	@override String get cloudBackupUsername => 'ชื่อผู้ใช้';
	@override String get cloudBackupPassword => 'คู่มือ';
	@override String get cloudBackupSaved => 'Cloud Backup destination ที่บันทึก';
	@override String get cloudBackupNow => 'กลับขึ้นตอนนี้';
	@override String get cloudBackupComplete => 'การตั้งค่า Backup upload';
	@override String get cloudBackupRestore => 'การกู้คืน Backup';
	@override String get cloudBackupRestoreConfirm => 'สิ่งนี้จะแทนที่การตั้งค่าแบบพกพาที่ตรงกับอุปกรณ์นี้. ต่อไป?';
	@override String get cloudBackupRestored => 'การตั้งค่าที่ได้รับการกู้คืนจาก Cloud Backup';
	@override String get shortcutsReset => 'ระยะสั้นที่กําหนดเอง';
	@override String get resetShortcutsConfirm => 'นี่จะแทนที่การสั้น ๆ ที่กําหนดเองของคุณด้วยข้อกําหนดต่อไปหรือไม่?';
	@override String get about => 'เกี่ยวกับ';
	@override String get aboutDescription => 'ข้อมูลแอปและใบอนุญาต';
	@override String get updates => 'ปรับปรุง';
	@override String get updateAvailable => 'การปรับปรุงที่มีอยู่';
	@override String get checkForUpdates => 'ตรวจสอบการปรับปรุง';
	@override String get autoCheckUpdatesOnStartup => 'ตรวจสอบอัตโนมัติสําหรับอัปเดตใน Startup';
	@override String get autoCheckUpdatesOnStartupDescription => 'บันทึกเมื่อมีการปรับปรุงพร้อมใช้งานเมื่อเปิดตัว';
	@override String get validationErrorEnterNumber => 'กรุณาใส่หมายเลขที่ถูกต้อง';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'ต้องมีระหว่าง ${min} และ ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Shortcut ที่กําหนดไว้แล้ว ${action}';
	@override String shortcutUpdated({required Object action}) => 'Shortcut อัพเดทสําหรับ ${action}';
	@override String get saveFailed => 'ไม่สามารถบันทึกการเปลี่ยนแปลงได้ ลองอีกครั้ง';
	@override String get autoPlayAndSkip => 'อัตโนมัติ Play & Skip';
	@override String get autoPlayNextEpisode => 'Auto-Play ฉบับต่อไป';
	@override String get autoPlayNextEpisodeDescription => 'เริ่มต้นส่วนต่อไปโดยอัตโนมัติเมื่อหนึ่งสิ้นสุด';
	@override String get shuffleStartsFromBeginning => 'Shuffle เริ่มต้น';
	@override String get shuffleStartsFromBeginningDescription => 'เริ่มต้นแต่ละ epizode ในตอนเริ่มต้นเมื่อ shuffling แทนที่จะ reuming';
	@override String get plexCinemaPreRoll => 'ใช้เซิร์ฟเวอร์ Cinema Intros';
	@override String get plexCinemaPreRollDescription => 'เล่น Plex Pre-rolls หรือ Jellyfin และ Emby intros ที่กําหนดเองก่อนที่จะเริ่มภาพยนตร์';
	@override String get playNextCountdown => 'เล่น Countdown ต่อไป';
	@override String get playNextCountdownImmediate => 'เล่นทันที';
	@override String get skipIntroMode => 'สไลด์อินเตอร์เน็ต';
	@override String get skipIntroModeOffDescription => 'เล่น intros โดยปกติโดยไม่มีปุ่ม skip';
	@override String get skipIntroModeButtonDescription => 'แสดงปุ่ม Skip เมื่อ intro เริ่มต้น';
	@override String get skipIntroModeAutoDescription => 'สปินอินเตอร์โดยอัตโนมัติหลังจากการล่าช้าด้านล่าง';
	@override String get skipCreditsMode => 'คิดสกี';
	@override String get skipCreditsModeOffDescription => 'เล่นเครดิตโดยปกติโดยไม่มีปุ่ม skip';
	@override String get skipCreditsModeButtonDescription => 'แสดงปุ่ม Skip เมื่อเครดิตเริ่มต้น';
	@override String get skipCreditsModeAutoDescription => 'คลิกเครดิตโดยอัตโนมัติและเล่นส่วนต่อไป';
	@override String get skipAdsMode => 'การโฆษณา Skip';
	@override String get skipAdsModeOffDescription => 'เล่นโฆษณาที่ได้รับการตรวจพบโดยปกติโดยไม่มีปุ่มสปิก';
	@override String get skipAdsModeButtonDescription => 'แสดงปุ่ม Skip เมื่อ Plex รู้สึกโฆษณา';
	@override String get skipAdsModeAutoDescription => 'ลบโฆษณาที่ได้รับการตรวจพบโดยอัตโนมัติหลังจากการล่าช้าด้านล่าง';
	@override String get musicPlayback => 'การเล่นเพลง';
	@override String get musicSweetFades => 'หวาน';
	@override String get musicSweetFadesDescription => 'ไฟล์เพลงบนแอนดคอร์เมื่อ Plex มีข้อมูลเสียง การเล่นอัลบั้มยังคงไม่เปลี่ยนแปลง';
	@override String get skipMarkerModeOff => 'ปิด';
	@override String get skipMarkerModeButton => 'แสดงปุ่ม';
	@override String get skipMarkerModeAuto => 'อัตโนมัติ';
	@override String get forceSkipMarkerFallback => 'แรงดันไฟฟ้า Fallback Markers';
	@override String get forceSkipMarkerFallbackDescription => 'ใช้รูปแบบหัวข้อแม้ว่า Plex มีเครื่องหมาย';
	@override String get theIntroDbFallback => 'ใช้ TheIntroDB เป็น intro fallback';
	@override String get theIntroDbFallbackDescription => 'ใช้เวลาชุมชนเท่านั้นเมื่อเซิร์ฟเวอร์ไม่มีเครื่องหมายการเข้า การแข่งขันสามารถแตกต่างกันตามการปล่อย';
	@override String get autoSkipDelay => 'รถยนต์ Skip ละลาย';
	@override String autoSkipDelayDescription({required Object seconds}) => 'รอ ${seconds} วินาทีก่อนที่จะสปินอัตโนมัติ';
	@override String get introPattern => 'หมายเลขรุ่น: Intro Marker Pattern';
	@override String get introPatternDescription => 'รูปแบบ Regex เพื่อตอบสนองตัวอักษรในหัวข้อ';
	@override String get creditsPattern => 'หลักฐานการทําสัญญา';
	@override String get creditsPatternDescription => 'รูปแบบ Regex เพื่อตอบสนองผู้รับรองในหัวข้อ';
	@override String get prerolls => 'โพสต์';
	@override String get playPrerollsBeforeMovies => 'เล่น prerolls ก่อนภาพยนตร์';
	@override String get playPrerollsBeforeMoviesDescription => 'เล่นคลิปสุ่มจากตัวเลือกของคุณด้านล่างก่อนแต่ละภาพยนตร์ คลิกกลับเพื่อล่วงหน้า';
	@override String get prerollLibrary => 'โพสต์ห้องสมุด';
	@override String get prerollLibraryNotSet => 'ไม่ตั้งค่า';
	@override String get prerollLibraryNoneFound => 'ไม่มีห้องสมุดที่พบในเซิร์ฟเวอร์ของคุณ';
	@override String get prerollSelection => 'โพสต์ที่เลือก';
	@override String get prerollSelectionPickLibraryFirst => 'เลือกห้องสมุดครั้งแรก';
	@override String get prerollSelectionNoneSelected => 'ไม่มีการเลือก';
	@override String prerollSelectionCount({required Object count}) => '${count} เลือก';
	@override String get prerollItemPicker => 'เลือกใบรับรอง';
	@override String get prerollItemPickerLoadFailed => 'ฉันไม่สามารถโหลดรายการจากห้องสมุดนี้ได้';
	@override String get invalidRegex => 'ความผิดปกติของการแสดงออกปกติ';
	@override String get regex => 'คําอธิบายปกติ';
	@override String get downloads => 'รายการดาวน์โหลด';
	@override String get downloadLocationDescription => 'เลือกสถานที่ที่จะเก็บเนื้อหาที่ดาวน์โหลด';
	@override String get downloadLocationDefault => 'การจัดเก็บแอป (App Storage)';
	@override String get downloadLocationCustom => 'โพสต์ที่กําหนดเอง';
	@override String get selectFolder => 'เลือกโฟลเดอร์';
	@override String get resetToDefault => 'การตั้งค่าใหม่แบบ default';
	@override String currentPath({required Object path}) => 'อัพเดท: ${path}';
	@override String get downloadLocationChanged => 'ดาวน์โหลดตําแหน่งที่เปลี่ยนแปลง';
	@override String get downloadLocationReset => 'ดาวน์โหลดตําแหน่ง reset to default';
	@override String get downloadLocationInvalid => 'โพสต์ที่เลือกไม่สามารถเขียนได้';
	@override String get downloadLocationPickerUnavailable => 'การเลือกโฟลเดอร์ไม่สามารถใช้ได้บนอุปกรณ์นี้';
	@override String get downloadOnWifiOnly => 'ดาวน์โหลดที่ Wi-Fiเท่านั้น';
	@override String get downloadOnWifiOnlyDescription => 'ป้องกันการดาวน์โหลดเมื่อบนข้อมูลมือถือ';
	@override String get autoRemoveWatchedDownloads => 'ดาวน์โหลดอัตโนมัติ';
	@override String get autoRemoveWatchedDownloadsDescription => 'ลบดาวน์โหลดที่เห็นโดยอัตโนมัติ';
	@override String get autoDownloadContinueWatching => 'อัตโนมัติดาวน์โหลด Continue Watching';
	@override String get autoDownloadContinueWatchingDescription => 'บันทึกรายการในคอลเลกชัน Continue Watch ของคุณดาวน์โหลดและลบพวกเขาเมื่อพวกเขาออกจากคอลเลกชัน';
	@override String get downloadQuality => 'ดาวน์โหลดคุณภาพ';
	@override String get downloadQualityDescription => 'Plex เตรียมสำเนาที่แปลงแล้วในคิวดาวน์โหลด ส่วน Jellyfin และ Emby จะแปลงรหัสระหว่างดาวน์โหลดไฟล์ หากการถ่ายโอนหยุดชะงัก อาจต้องเริ่มใหม่';
	@override String get askDownloadQualityEachTime => 'เลือกคุณภาพสําหรับแต่ละดาวน์โหลด';
	@override String get askDownloadQualityEachTimeDescription => 'แสดงตัวเลือกคุณภาพก่อนที่จะสแกนวิดีโอการดาวน์โหลดแต่ละครั้ง';
	@override String get cellularDownloadBlocked => 'ดาวน์โหลดจะถูกบล็อกบนโทรศัพท์มือถือ ใช้ Wi-Fi หรือเปลี่ยนการตั้งค่า';
	@override String get maxVolume => 'ระดับเสียงสูงสุด';
	@override String get maxVolumeDescription => 'อนุญาตให้เพิ่มระดับเสียงเกิน 100% สำหรับสื่อที่มีเสียงเบา';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'ความแตกต่างของความปรากฏตัวที่อุดมสมบูรณ์';
	@override String get discordRichPresenceDescription => 'แสดงสิ่งที่คุณกําลังมองหาบน Discord';
	@override String get services => 'บริการ';
	@override String get servicesDescription => 'ติดต่อ Trakt, MyAnimeList, Seerr, และอื่น ๆ';
	@override String get manageLibrariesDescription => 'การจัดเก็บและซ่อนห้องสมุด';
	@override String get companionRemoteServer => 'เซิร์ฟเวอร์ระยะไกล';
	@override String get companionRemoteServerDescription => 'ให้อุปกรณ์มือถือบนเครือข่ายของคุณควบคุมแอปนี้';
	@override String get companionRemoteServerStartFailed => 'ไม่สามารถเริ่มต้นเซิร์ฟเวอร์คู่ค้าได้';
	@override String get companionRemoteServerStopFailed => 'ไม่สามารถหยุดเซิร์ฟเวอร์พันธมิตร';
	@override String get autoPip => 'ภาพถ่ายในภาพ';
	@override String get autoPipDescription => 'เข้าสู่ภาพในภาพโดยอัตโนมัติเมื่อคุณออกจากแอปในระหว่างการเล่น';
	@override String get matchContentFrameRate => 'Match Content Frame Rate ความเร็ว';
	@override String get matchContentFrameRateDescription => 'การแสดงผล Match อัตราการฟื้นฟูไปยังเนื้อหาวิดีโอ';
	@override String get matchContentResolution => 'โซลูชั่นเนื้อหา Match';
	@override String get matchContentResolutionDescription => 'แปลงหน้าจอไปยังความละเอียดของวิดีโอในท้องถิ่นเพื่อให้ทีวีของคุณจัดการกับ upscaling เมนูและหัวข้อจะ upscaled ยังในช่วงการเล่น';
	@override String get matchRefreshRate => 'การแข่งขันอัตโนมัติ';
	@override String get matchRefreshRateDescription => 'การแสดงผล Match อัตราการสดชื่นในหน้าจอเต็มรูปแบบ';
	@override String get matchDynamicRange => 'การแข่งขัน Dynamic Range';
	@override String get matchDynamicRangeDescription => 'สวิตช์ HDR สําหรับเนื้อหา HDR จากนั้นกลับไปที่ SDR';
	@override String get displaySwitchDelay => 'แสดงสวิทช์ช้า';
	@override String get tunneledPlayback => 'การเล่นแบบ Tunnelback';
	@override String get tunneledPlaybackDescription => 'ใช้วิดีโอ tunneling ปิดใช้งานหาก HDR playback แสดงวิดีโอสีดําหรือภาพเคลื่อนไหว stutters';
	@override String get audioPassthrough => 'เสียงที่กําหนดเอง';
	@override String get audioPassthroughDescription => 'ส่งเสียง Dolby / DTS ไปยังรับหรือทีวีของคุณโดยไม่ต้องเข้ารหัสใหม่และยังคงเสียงรอบ ปิดถ้าคุณไม่มีเสียง';
	@override String get audioPassthroughDescriptionApple => 'ใช้ decoder Dolby ที่เกิดจาก Apple สําหรับ Dolby Digital Plus รวมถึง Atmos DTS และ TrueHD ยังคงเล่นเป็น PCM มัลติช่อง ปิดถ้าคุณไม่มีเสียง';
	@override String get audioPassthroughDescriptionAppleSpatial => 'ใช้ decoder Dolby ที่เกิดจาก Apple สําหรับ Dolby Digital Plus รวมถึง Atmos. บน iOS, iPadOS และ tvOS 26 หรือภายหลัง, TrueHD Atmos และ DTS:X เล่นเป็นเสียงพื้นที่. ระยะทาง DTS และ TrueHD อื่น ๆ เล่นเป็น PCM มัลติช่อง. ปิดถ้าคุณไม่มีเสียง.';
	@override String get audioPassthroughOverriddenByNormalization => 'ปิดขณะที่เสียง normalization เป็น';
	@override String get audioChannelLimit => 'ช่องเสียง';
	@override String get audioChannelLimitDescription => 'ลดจำนวนช่องเสียงที่ถอดรหัสแล้วให้เหมาะกับลำโพง หูฟัง หรือระบบ HDMI ที่ไม่สามารถเล่นได้ครบทุกช่อง';
	@override String get audioChannelLimitOriginal => 'หลัก';
	@override String get audioChannelLimitOriginalDescription => 'เล่นทุกช่องในทิศทาง';
	@override String get audioChannelLimitSurround51 => 'สูงสุด 5.1';
	@override String get audioChannelLimitSurround51Description => 'ผสม 7.1 ลงไป 5.1 สําหรับทีวีและผู้รับที่ใช้ PCM 5.1 เท่านั้น Passthrough ไม่ได้รับผลกระทบ';
	@override String get audioChannelLimitStereo => 'สเตียรอยด์';
	@override String get audioChannelLimitStereoDescription => 'ผสมลงไปสองช่องสําหรับสเตียรอยด์หรือหัวข้อ แปลงไปตรงไปตรงไปตรง';
	@override String get downmixCenterBoost => 'ศูนย์ช่อง Boost';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'ปริมาณ (dB)';
	@override String get downmixCenterBoostShort => 'DB';
	@override String get audioDownmixNormalize => 'ปรับปรุงปริมาณบน Downmix';
	@override String get audioDownmixNormalizeDescription => 'ลดส่วนผสมเพื่อป้องกันไม่ให้คลิก ปิดเพื่อรักษาปริมาณเดิม (อาจทําให้เกิดความผิดปกติในสถานการณ์ที่เสียงรบกวน)';
	@override String get dvConversionMode => 'Dolby Vision การแปลง';
	@override String get dvConversionModeDescription => 'เลือกวิธีการจัดการไฟล์ Dolby Vision โปรไฟล์ 7';
	@override String get dvConversionAuto => 'อัตโนมัติ';
	@override String get dvConversionNative => 'พื้นที่ / ภาวะมี инвалидност';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'ใช้การตรวจจับความสามารถของอุปกรณ์และพฤติกรรม fallback ปกติ';
	@override String get dvConversionNativeDescription => 'Force native DV7 และยับยั้งการแปลง DV Retry';
	@override String get dvConversionDv81Description => 'แปลง RPU ในร่องรัดไป Dolby Vision โปรไฟล์ 8.1';
	@override String get dvConversionHevcStripDescription => 'เกรด Dolby Vision ชั้น RPU/EL และแบนปัจจุบัน HEVC';
	@override String get disableDolbyVision => 'ไม่สามารถใช้งานได้ Dolby Vision';
	@override String get disableDolbyVisionDescription => 'เล่นไฟล์ HDR10 หรือชั้น HLG แทน Dolby Vision เมื่อมี';
	@override String get hdrSdrConversion => 'การแปลง HDR ไปยัง SDR';
	@override String get hdrSdrConversionDescription => 'เลือกสิ่งที่แปลงวิดีโอ HDR เมื่อหน้าจอไม่สามารถแสดง HDR';
	@override String get hdrSdrConversionAuto => 'อัตโนมัติ';
	@override String get hdrSdrConversionAutoDescription => 'อุปกรณ์บน Android 9 และภายหลังผู้เล่นบนรุ่นเก่า';
	@override String get hdrSdrConversionDevice => 'อุปกรณ์';
	@override String get hdrSdrConversionDeviceDescription => 'อุปกรณ์วิดีโอฮาร์ดแวร์จะแปลงได้เร็วที่สุด แต่สีขึ้นอยู่กับอุปกรณ์';
	@override String get hdrSdrConversionPlayer => 'ตัวเล่น';
	@override String get hdrSdrConversionPlayerDescription => 'ผู้เล่นแปลงสีที่สม่ําเสมอ แต่ 4K สามารถจับบนกล่องทีวีต่ําสุด';
	@override String get deinterlace => 'การเชื่อมต่อ';
	@override String get deinterlaceDescription => 'การกําจัดรายการผสมจากวิดีโอแบบเชื่อมต่อ (mpv ผู้เล่นเท่านั้น)';
	@override String get deinterlaceOff => 'ปิด';
	@override String get deinterlaceOffDescription => 'แสดงวิดีโอที่เชื่อมโยงกันเมื่อมันถูก decoded';
	@override String get deinterlaceVideo => 'วิดีโอ';
	@override String get deinterlaceVideoDescription => 'แปลงแต่ละฟิลด์เป็นกรอบเต็ม สําหรับภาพถ่ายวิดีโอสําหรับโทรทัศน์เช่นกีฬาข่าวและคอนเทนต์';
	@override String get deinterlaceFilm => 'ภาพยนตร์';
	@override String get deinterlaceFilmDescription => 'การกู้คืนกรอบเดิมของภาพยนตร์และภาพเคลื่อนไหวที่โทรคมนาคมถึง 29.97 ฟิล์มต่อวินาทีที่พบได้บน DVD ของ NTSC วิดีโอถ่ายภาพสําหรับนักแสดงทีวีทีวีสดใช้วิดีโอ';
	@override String get requireProfileSelectionOnOpen => 'ขอโปรไฟล์บนแอปเปิด';
	@override String get requireProfileSelectionOnOpenDescription => 'แสดงตัวเลือกโปรไฟล์ทุกครั้งที่แอปเปิด';
	@override String get forceTvMode => 'โหมดโทรทัศน์';
	@override String get forceTvModeDescription => 'การจัดตั้ง TV Force สําหรับอุปกรณ์ที่ไม่ได้ตรวจจับอัตโนมัติ ต้องเริ่มต้นใหม่';
	@override String get startInFullscreen => 'เริ่มต้นในหน้าจอเต็มรูปแบบ';
	@override String get startInFullscreenDescription => 'เปิด PlezyNG ในโหมดหน้าจอเต็มที่เมื่อเปิดตัว';
	@override String get exitFullscreenOnPlayerClose => 'หน้าจอเต็มหน้าจอออกในผู้เล่นปิด';
	@override String get exitFullscreenOnPlayerCloseDescription => 'การออกหน้าจอเต็มรูปแบบโดยอัตโนมัติเมื่อปิดเครื่องเล่นวิดีโอ';
	@override String get autoHidePerformanceOverlay => 'ความสามารถในการทํางานอัตโนมัติ';
	@override String get autoHidePerformanceOverlayDescription => 'Fade performance overlay ด้วยการควบคุม playback';
	@override String get showNavBarLabels => 'แสดงแถบ Navigation Bar Labels';
	@override String get showNavBarLabelsDescription => 'แสดงฉลากข้อความภายใต้ไอคอนบาร์การนําทาง';
	@override String get startupSection => 'ส่วนเริ่มต้น';
	@override String get preferredServer => 'เซิร์ฟเวอร์ที่ชื่นชอบ';
	@override String get preferredServerDescription => 'หลักการผลลัพธ์ของเซิร์ฟเวอร์นี้ในขณะที่รักษาเซิร์ฟเวอร์ที่เชื่อมต่อแต่ละคนพร้อมใช้งาน';
	@override String get preferredServerAutomatic => 'อัตโนมัติ';
	@override String get showExploreTab => 'แสดง ค้นหาแท็บ';
	@override String get showExploreTabDescription => 'แสดงแท็บ Explore กับเนื้อหาจาก Plex Discover และติดตามที่เชื่อมต่อ';
	@override String get hideEmptyLibraries => 'ลบห้องสมุดว่างเปล่า';
	@override String get hideEmptyLibrariesDescription => 'ลบสมุดที่มีรายการที่รายงานจากเซิร์ฟเวอร์เป็นศูนย์จากการนําทาง';
	@override String get liveTvDefaultFavorites => 'ข้อกําหนดสําหรับช่องทางที่ชื่นชอบ';
	@override String get liveTvDefaultFavoritesDescription => 'แสดงช่องทางที่ชื่นชอบเท่านั้นเมื่อเปิดทีวีสด';
	@override String get general => 'ทั่วไป';
	@override String get generalDescription => 'ภาษาเริ่มต้นและพฤติกรรมหน้าต่าง';
	@override String get languageAndRegion => 'ภาษาและภูมิภาค';
	@override String get startup => 'การเริ่มต้น';
	@override String get display => 'แสดง';
	@override String get libraryAndCards => 'บีทอรีและแผนที่';
	@override String get homeScreen => 'หน้าจอบ้าน';
	@override String get navigation => 'การนําทาง';
	@override String get window => 'หน้าต่าง';
	@override String get liveTv => 'ทีวีสด';
	@override String get player => 'ตัวเล่น';
	@override String get videoAndDisplay => 'วิดีโอและแสดงผล';
	@override String get audio => 'เสียง';
	@override String get quality => 'คุณภาพ';
	@override String get subtitles => 'คำบรรยาย';
	@override String get seekAndTiming => 'ค้นหาและเวลา';
	@override String get behavior => 'การกระทํา';
	@override String get gestures => 'การกระตุ้น';
	@override String get gestureBrightnessSwipe => 'ความสว่าง Swipe';
	@override String get gestureBrightnessSwipeDescription => 'สวิทช์ขึ้นหรือลงบนขอบด้านซ้ายเพื่อปรับความสว่าง';
	@override String get gestureVolumeSwipe => 'หมายเลขรุ่น: Swipe';
	@override String get gestureVolumeSwipeDescription => 'สลับขึ้นหรือลงบนขอบขวาเพื่อปรับปริมาณ';
	@override String get gesturePinchToZoom => 'ไฟฟ้าระดับ Zoom';
	@override String get gesturePinchToZoomDescription => 'คลิกที่วิดีโอเพื่อ zoom ในหรือออก';
	@override String get gestureSeekSwipe => 'ค้นหา Swipe';
	@override String get gestureSeekSwipeDescription => 'เปลี่ยนขวาหรือขวาที่ใดก็ได้ในวิดีโอเพื่อค้นหา; ปล่อยเพื่อย้อนกลับ';
	@override String get rememberBrightnessLevel => 'หมายถึงระดับความสว่าง';
	@override String get rememberBrightnessLevelDescription => 'เริ่มต้นการเล่นในความสว่างที่กําหนดโดยสวิทส์สุดท้าย';
	@override String get controls => 'การควบคุม';
	@override String get rememberPlayerChanges => 'หมายเหตุการเปลี่ยนแปลงของผู้เล่น';
	@override String get rememberPlayerChangesDescription => 'ที่การเปลี่ยนแปลงที่เกิดขึ้นในระหว่างการเล่นจะถูกบันทึกและนํามาใช้อีกครั้งจาก';
	@override String get scopePlaybackSpeed => 'ความเร็ว Playback';
	@override String get scopeShaderPreset => 'โซเดอร์ Preset';
	@override String get scopeAspectRatio => 'อัตราส่วน';
	@override String get scopeSyncOffsets => 'Audio & Subtitle ซิงค์';
	@override String get playerScopeOff => 'อย่าบันทึก';
	@override String get playerScopeGlobal => 'ทุกที่';
	@override String get playerScopeLibrary => 'โดยห้องสมุด';
	@override String get playerScopeTitle => 'สําหรับการแสดงหรือภาพยนตร์';
	@override String get exportDialogTitle => 'การส่งออก PlezyNG การตั้งค่า';
	@override String get followSystem => 'ตามระบบ';
	@override String get followAppLanguage => 'ใช้ภาษาเดียวกับอินเทอร์เฟซ';
	@override String get regionFormat => 'รูปแบบภูมิภาค';
	@override String get regionFormatDescription => 'เลือกวิธีแสดงวันที่ ตัวเลข และหน่วยวัด';
	@override String get metadataLanguage => 'ภาษาข้อมูลสื่อ';
	@override String get metadataLanguageDescription => 'ภาษาที่ต้องการสำหรับชื่อและคำอธิบายเมื่อเซิร์ฟเวอร์รองรับ การตั้งค่าเสียงและคำบรรยายจะแยกจากกัน';
}

// Path: themeEditor
class _Translations$themeEditor$th extends Translations$themeEditor$en {
	_Translations$themeEditor$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get builtIn => 'โครงสร้าง';
	@override String get presets => 'โพสต์';
	@override String get custom => 'คู่มือ';
	@override String get customEmpty => 'ไม่ได้สร้างขึ้น';
	@override String get editCustom => 'โมดูลแบบกําหนดเอง';
	@override String get editCustomDescription => 'เลือกสีแต่ละตัว';
	@override String get locked => 'การเข้าถึงอายุการใช้งานที่จําเป็น';
	@override String get savedLocked => 'เก็บ - มีการเข้าถึงตลอดชีวิต';
	@override String get title => 'ธีมที่กําหนดเอง';
	@override String get startFrom => 'เริ่มต้นจาก';
	@override String get startFromDescription => 'คัดลอกสีทั้งหมดจากธีมอื่น ๆ';
	@override String get colors => 'สี';
	@override String get preview => 'มุมมอง';
	@override late final _Translations$themeEditor$slots$th slots = _Translations$themeEditor$slots$th._(_root);
	@override String get opacity => 'ความผิดปกติ';
	@override String get hexHint => '#RRGGBB หรือ #AARRGGBB';
	@override String get fromOtherThemes => 'จากหัวข้ออื่น ๆ';
	@override String swatchLabel({required Object theme, required Object color}) => '${theme} ${color}';
	@override late final _Translations$themeEditor$contrast$th contrast = _Translations$themeEditor$contrast$th._(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, ด้านล่างของที่แนะนํา ${minimum}:1';
	@override String get discardTitle => 'ปล่อยการเปลี่ยนแปลง?';
	@override String get discardMessage => 'การเปลี่ยนแปลงสีที่ไม่ซ้ํากันของคุณจะหายไป';
	@override String get discard => 'ตูด';
	@override String previewCardTitle({required Object number}) => 'ฉบับที่ ${number}';
	@override String previewCardSubtitle({required Object minutes}) => '${minutes} นาที left';
	@override String get previewSwitch => 'รถยนต์';
	@override String get previewMutedText => 'ภาษาไทยอ่านเช่นนี้';
}

// Path: search
class _Translations$search$th extends Translations$search$en {
	_Translations$search$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get hint => 'ค้นหา ภาพยนตร์, แสดง, เพลง...';
	@override String get tryDifferentTerm => 'ลองคําค้นหาที่แตกต่างกัน';
	@override String get searchYourMedia => 'ค้นหาสื่อของคุณ';
	@override String get enterTitleActorOrKeyword => 'ใส่ชื่อผู้เล่นหรือคําหลัก';
	@override String get people => 'คน';
}

// Path: hotkeys
class _Translations$hotkeys$th extends Translations$hotkeys$en {
	_Translations$hotkeys$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Set Shortcut สําหรับ ${actionName}';
	@override String get clearShortcut => 'ระยะเวลาที่ชัดเจน';
	@override String get noShortcutSet => 'ไม่มีชุดสั้น';
	@override String get currentShortcut => 'ระยะสั้นปัจจุบัน:';
	@override String get pressToRecord => 'เลือกเพื่อบันทึกการสั้น ๆ';
	@override String get recordingShortcut => 'คลิกที่สั้นตอนนี้';
	@override late final _Translations$hotkeys$actions$th actions = _Translations$hotkeys$actions$th._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$th extends Translations$fileInfo$en {
	_Translations$fileInfo$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'ข้อมูลไฟล์';
	@override String get overview => 'ทบทวน';
	@override String get video => 'วิดีโอ';
	@override String get audio => 'เสียง';
	@override String get subtitles => 'คำบรรยาย';
	@override String get images => 'ภาพรวม';
	@override String get dataStreams => 'การไหลข้อมูล';
	@override String get lyrics => 'เนื้อเพลง';
	@override String get file => 'ไฟล์';
	@override String get attachments => 'การเชื่อมต่อ';
	@override String get delivery => 'การจัดส่ง';
	@override String versionCounter({required Object index, required Object count}) => 'รุ่น ${index} ของ ${count}';
	@override String fileCounter({required Object index, required Object count}) => 'ไฟล์ ${index} ของ ${count}';
	@override String get noStreams => 'เซิร์ฟเวอร์รายงานไม่มีการไหลสําหรับไฟล์นี้';
	@override String get copyPath => 'การคัดลอกเส้นทาง';
	@override String get pathCopied => 'ไฟล์เส้นทางคัดลอก';
	@override String get codec => 'รหัส';
	@override String get codecTag => 'รหัสผ่าน Tag';
	@override String get resolution => 'โซลูชั่น';
	@override String get codedResolution => 'โซลูชันที่รหัส';
	@override String get bitrate => 'บิทริก';
	@override String get frameRate => 'ความเร็ว Frame';
	@override String get rotation => 'การหมุน';
	@override String get comment => 'วิธีการ';
	@override String get audioDescription => 'คําอธิบายเสียง';
	@override String get headerCompression => 'หัวฉีด';
	@override String get sidecarFile => 'ไฟล์ Sidecar';
	@override String get transportTimestamp => 'ระยะเวลาการขนส่ง';
	@override String get displayOffset => 'แสดง Offset';
	@override String get previewFailureCode => 'โค้ดความล้มเหลว';
	@override String get previewRetries => 'ความคิดเห็น';
	@override String get aspectRatio => 'อัตราส่วน';
	@override String get pixelAspectRatio => 'พิกเซล Aspect Ratio';
	@override String get profile => 'โปรไฟล์';
	@override String get level => 'ระดับ';
	@override String get bitDepth => 'ความลึก';
	@override String get pixelFormat => 'รูปแบบ Pixel';
	@override String get colorSpace => 'ปริภูมิสี';
	@override String get colorRange => 'สี Range';
	@override String get colorPrimaries => 'สีหลัก';
	@override String get colorTransfer => 'การถ่ายโอนสี';
	@override String get chromaSubsampling => 'โครเมี่ยม Subsampling';
	@override String get chromaLocation => 'โพสต์โครเมี่ยม';
	@override String get scanType => 'ประเภทการสแกน';
	@override String get interlaced => 'การเชื่อมต่อ';
	@override String get anamorphic => 'อะโนเมอร์ฟิก';
	@override String get referenceFrames => 'หลักสูตรการอ้างอิง';
	@override String get dynamicRange => 'ช่วงไดนามิก';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Dolby Vision ระดับ';
	@override String get dolbyVisionVersion => 'Dolby Vision รุ่น';
	@override String get dolbyVisionLayers => 'Dolby Vision ชั้น';
	@override String get baseLayerCompatibility => 'ความเข้ากันได้ชั้นฐาน';
	@override String get avcBitstream => 'บิตสตรีม AVC';
	@override String get nalLengthSize => 'ขนาด NAL ความยาว';
	@override String get scalingMatrix => 'เครื่องวัดการสแกนแบบกําหนดเอง';
	@override String get streamIdentifier => 'การระบุการไหล';
	@override String get streamIndex => 'อัตราการไหล';
	@override String get streamId => 'การส่งออก ID';
	@override String get language => 'ภาษา';
	@override String get languageCode => 'รหัสภาษา';
	@override String get streamTitle => 'หมายเลข Track';
	@override String get channels => 'ช่อง';
	@override String get sampleRate => 'ตัวอย่างอัตรา';
	@override String get spatialAudio => 'อากาศเสียง';
	@override String get textBased => 'ฐานข้อความ';
	@override String get subtitleFormat => 'โครงสร้าง';
	@override String get provider => 'ผู้ให้บริการ';
	@override String get matchScore => 'การแข่งขัน Score';
	@override String get externalDelivery => 'สามารถให้บริการแยกต่างหาก';
	@override String get sidecarPath => 'เหล็กเส้นทาง';
	@override String get sourceStream => 'การคัดลอกจาก';
	@override String get temporary => 'ระยะเวลา';
	@override String get timeBase => 'ฐานเวลา';
	@override String get overallBitrate => 'บิตตารางทั้งหมด';
	@override String get path => 'ถนน';
	@override String get fileName => 'ชื่อไฟล์';
	@override String get size => 'ขนาด';
	@override String get totalSize => 'ขนาดทั้งหมด';
	@override String get container => 'บรรจุภัณฑ์';
	@override String get duration => 'ความยาว';
	@override String get previewThumbnails => 'โมดูล';
	@override String get previewIndex => 'มาตรฐาน Index';
	@override String get packetLength => 'ความยาวแพคเกจ';
	@override String get filePresent => 'ไฟล์ปัจจุบัน';
	@override String get fileReadable => 'อ่านโดยเซิร์ฟเวอร์';
	@override String get streamPath => 'เส้นทางการไหล';
	@override String get optimizedForStreaming => 'การปรับปรุงสําหรับ Streaming';
	@override String get has64bitOffsets => '64 บิต Offsets';
	@override String get protocol => 'โปรโตคอล';
	@override String get mediaType => 'ประเภทสื่อ';
	@override String get sourceKind => 'ประเภทแหล่งข้อมูล';
	@override String get optimizedVersion => 'รุ่นที่เพิ่มประสิทธิภาพ';
	@override String get optimizationTarget => 'เป้าหมายการเพิ่มประสิทธิภาพ';
	@override String get deletedAt => 'ลบ';
	@override String get remoteSource => 'แหล่งกําเนิด';
	@override String get infiniteStream => 'การไหลไม่สิ้นสุด';
	@override String get directPlay => 'เล่นโดยตรง';
	@override String get directStream => 'การไหลโดยตรง';
	@override String get transcoding => 'การเข้ารหัส';
	@override String get etag => 'ETag';
	@override String get versionId => 'รุ่น ID';
	@override String get fileId => 'ไฟล์ ID';
	@override String get defaultAudioTrack => 'ลักษณะ Audio Track';
	@override String get defaultSubtitleTrack => 'การติดตาม Subtitle';
	@override String get subtitlesOff => 'ปิด';
	@override String get flagDefault => 'ค่าเริ่มต้น';
	@override String get flagForced => 'การบังคับ';
	@override String get flagSelected => 'เลือก';
	@override String get flagExternal => 'ภายนอก';
	@override String get flagHearingImpaired => 'ความยินเสียหาย';
	@override String get flagDub => 'คู่มือ';
	@override String get flagOriginal => 'หลัก';
	@override String get channelsMono => 'โมโน';
	@override String dolbyVisionProfile({required Object profile}) => 'โปรไฟล์ ${profile}';
}

// Path: mediaMenu
class _Translations$mediaMenu$th extends Translations$mediaMenu$en {
	_Translations$mediaMenu$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'แสดงให้เห็น';
	@override String get markAsUnwatched => 'หมายเลขรุ่น: Unwatched';
	@override String get removeFromContinueWatching => 'ลบออกจาก Continuing Watching';
	@override String get viewDetails => 'ดูรายละเอียด';
	@override String get goToSeries => 'ไปยัง ชุด';
	@override String get shufflePlay => 'เล่น Shuffle';
	@override String get shuffleNotAvailableOffline => 'Shuffle ไม่สามารถเข้าถึงได้ offline';
	@override String get fileInfo => 'ข้อมูลไฟล์';
	@override String get deleteEpisodeFromServer => 'ลบส่วนจากเซิร์ฟเวอร์';
	@override String get deleteSeasonFromServer => 'ลบฤดูกาลจากเซิร์ฟเวอร์';
	@override String get deleteShowFromServer => 'ลบแสดงจากเซิร์ฟเวอร์';
	@override String get deleteMovieFromServer => 'ลบภาพยนตร์จากเซิร์ฟเวอร์';
	@override String get deleteEpisodeTitle => 'ลบบทความนี้หรือไม่';
	@override String get deleteSeasonTitle => 'ปล่อยฤดูกาลนี้';
	@override String get deleteShowTitle => 'ลบการแสดงนี้หรือไม่';
	@override String get deleteMovieTitle => 'ลบภาพยนตร์นี้';
	@override String get deleteEpisodeConfirm => 'ปลั๊ก Episode';
	@override String get deleteSeasonConfirm => 'ปล่อยฤดูกาล';
	@override String get deleteShowConfirm => 'ลบแสดง';
	@override String get deleteMovieConfirm => 'ลบภาพยนตร์';
	@override String get deleteAnyway => 'ลบอย่างไรก็ตาม';
	@override String confirmDeleteTarget({required Object title}) => 'ลบ ${title} จากเซิร์ฟเวอร์ของคุณอย่างต่อเนื่อง?';
	@override String get deleteMultipleWarning => 'นี่รวมถึงบทความทั้งหมดและไฟล์ของพวกเขา';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n,
		other: 'นี้ลบทั้งหมด ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodes ในมัน, และไฟล์ของพวกเขา.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n,
		other: 'รายการนี้จะถูกเก็บไว้ผ่านไฟล์ ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} และทั้งหมดจะถูกลบ',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodes อื่น ๆ จะถูกบันทึกในไฟล์เดียวกันและจะถูกลบยัง:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'PlezyNG ไม่สามารถตรวจสอบไฟล์ใดนี้จะลบดังนั้นจึงสามารถลบมากกว่ารายการที่ระบุไว้ข้างต้น ลบและลองอีกครั้งหรือลบในทางใด ๆ';
	@override String get deleteScopeUnverifiedNoFileInfo => 'เซิร์ฟเวอร์ของคุณไม่ให้ข้อมูลไฟล์สําหรับรายการนี้ดังนั้น PlezyNG ไม่สามารถตรวจสอบไฟล์ใดที่จะลบได้ มันอาจลบมากกว่ารายการที่ระบุไว้ข้างต้น';
	@override String get mediaDeletedSuccessfully => 'รายการสื่อลบอย่างประสบความสําเร็จ';
	@override String get mediaFailedToDelete => 'ไม่สามารถลบรายการสื่อ';
	@override String get rate => 'อัตรา';
	@override String get playFromBeginning => 'เล่นจากเริ่มต้น';
	@override String get playVersion => 'เล่นเวอร์ชัน';
}

// Path: rateSheet
class _Translations$rateSheet$th extends Translations$rateSheet$en {
	_Translations$rateSheet$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'อัตรา';
	@override String get server => 'เซิร์ฟเวอร์';
	@override String get favorite => 'รายการโปรด';
	@override String get favorited => 'ความรัก';
	@override String get saved => 'การบันทึก';
	@override String get notAvailable => 'ไม่พบการแข่งขัน';
	@override String get noConnectedServices => 'เชื่อมต่อบริการในตั้งค่าเพื่อให้คะแนนในนั้น';
}

// Path: accessibility
class _Translations$accessibility$th extends Translations$accessibility$en {
	_Translations$accessibility$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, ภาพยนตร์';
	@override String mediaCardShow({required Object title}) => '${title}, แสดงทีวี';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'มุมมอง';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent}% ครั้งที่เข้าดู';
	@override String get mediaCardUnwatched => 'ไม่สังเกต';
	@override String get tapToPlay => 'คลิกที่เล่น';
	@override String get decrease => 'การลดลง';
	@override String get increase => 'เพิ่มขึ้น';
	@override String decreaseValue({required Object label}) => 'การลดลง ${label}';
	@override String increaseValue({required Object label}) => 'การเพิ่มขึ้น ${label}';
	@override String get hue => 'ก้น';
	@override String get saturation => 'อะแดปเตอร์';
	@override String get brightness => 'ความสว่าง';
	@override String get hexColor => 'สี Hex';
	@override String get expandText => 'หมายเลขที่ขยาย';
	@override String get collapseText => 'หมายเลขรุ่น';
	@override String get alphabetNavigation => 'การนําทางอัลฟเฟต';
	@override String get alphabetScrollHint => 'สวิทช์ขึ้นหรือลงเพื่อย้ายด้วยข้อความ';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'รอบ ${row} ของ ${rowCount}, รอบ ${column} ของ ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'รอบ ${row} ของ ${rowCount}';
	@override String get autoScrollPlay => 'เล่น Auto-Scroll';
	@override String get autoScrollPause => 'การหยุดชะลออัตโนมัติ';
	@override String get hueShort => 'H';
	@override String get saturationShort => 'ส';
	@override String get valueShort => 'V';
	@override String get red => 'สีแดง';
	@override String get green => 'สีเขียว';
	@override String get blue => 'สีน้ำเงิน';
	@override String get redShort => 'R';
	@override String get greenShort => 'G';
	@override String get blueShort => 'บ';
	@override String get colorModeHsv => 'HSV';
	@override String get colorModeRgb => 'RGB';
	@override String get title => 'ความเข้าถึง';
	@override String get summary => 'หมายเลขรุ่น: Text, contrast, motion and controls';
	@override String get systemHint => 'การตั้งค่าการเข้าถึงของอุปกรณ์ของคุณจะใช้เสมอ ตัวเลือกเหล่านี้จะเพิ่มการปรับได้ตลอดทั้ง PlezyNG';
	@override String get readability => 'อ่านและดู';
	@override String get textSize => 'ขนาดข้อความเพิ่มเติม';
	@override String get preview => 'ค้นหาเรื่องต่อไปของคุณ อ่านฟังและดูในความเร็วของคุณเอง';
	@override String get boldText => 'ภาษาไทย';
	@override String get highContrast => 'ความต้านทานสูง';
	@override String get highContrastHint => 'ข้อความที่แข็งแกร่งและแสดงผลที่สําคัญขึ้นบนพื้นผิวที่แสงหรือเข้ม';
	@override String get interaction => 'การเคลื่อนไหวและการโต้ตอบ';
	@override String get reduceMotion => 'ลดการเคลื่อนไหว';
	@override String get reduceMotionHint => 'ปกติความสนใจการเปลี่ยนแปลงหน้าและผลตกแต่งอยู่';
	@override String get largeTargets => 'เป้าหมายสัมผัสขนาดใหญ่';
	@override String get largeTargetsHint => 'ให้การควบคุมร่วมกันพื้นที่มากขึ้นสําหรับสัมผัสและนิวเวชั่นช่วย';
	@override String get navigationHint => 'ใช้ Tab และ Shift+Tab เพื่อย้ายระหว่างควบคุม Enter หรือ Space เพื่อเปิดใช้งาน และ Escape หรือ Back เพื่อปิด โปรแกรมอ่าน zoom และเลือกอ่านพร้อมใช้งานในขณะที่หนังสือเปิด';
}

// Path: tooltips
class _Translations$tooltips$th extends Translations$tooltips$en {
	_Translations$tooltips$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'เล่น Shuffle';
	@override String get playTrailer => 'เล่น Trailer';
	@override String get markAsWatched => 'Mark ตามที่มองเห็น';
	@override String get markAsUnwatched => 'หมายเลขรุ่น: Unwatched';
}

// Path: audioTracks
class _Translations$audioTracks$th extends Translations$audioTracks$en {
	_Translations$audioTracks$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'ลวดเสียง ${n}';
}

// Path: videoControls
class _Translations$videoControls$th extends Translations$videoControls$en {
	_Translations$videoControls$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} โครง',
	);
	@override String get audioLabel => 'เสียง';
	@override String get subtitlesLabel => 'คำบรรยาย';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String get letterbox => 'กล่องข้อความ';
	@override String get fillScreen => 'หน้าจอเต็มรูปแบบ';
	@override String get stretch => 'ยืด';
	@override String get lockRotation => 'ล็อคหมุน';
	@override String get unlockRotation => 'ล็อคหมุน';
	@override String get timerActive => 'ฤดูใบไม้ผลิ';
	@override String playbackWillPauseIn({required Object duration}) => 'Playback จะหยุดใน ${duration}';
	@override String get sleepTimerEndOfVideo => 'วีดีโอปัจจุบัน';
	@override String get sleepTimerStopAtHeader => 'หยุด';
	@override String get sleepTimerDurationHeader => 'เวลา';
	@override String get playbackWillPauseAtEnd => 'Playback จะหยุดในตอนท้ายของวิดีโอนี้';
	@override String get stillWatching => 'ยังคงดู?';
	@override String pausingIn({required Object seconds}) => 'การพักผ่อนใน ${seconds}s';
	@override String get continueWatching => 'เสร็จสิ้น';
	@override String get autoPlayNext => 'การเล่นอัตโนมัติ';
	@override String get playNext => 'เล่นต่อไป';
	@override String get playButton => 'เล่น';
	@override String get pauseButton => 'หยุดชั่วคราว';
	@override String get playbackPaused => 'สะพาน';
	@override String get playbackResumed => 'เล่น';
	@override String get loadingVideo => 'วิดีโอโหลด';
	@override String get showPlaybackControls => 'แสดงการควบคุม playback';
	@override String get hidePlaybackControls => 'การควบคุม Playback';
	@override String seekBackwardButton({required Object seconds}) => 'ค้นหากลับ ${seconds} วินาที';
	@override String seekForwardButton({required Object seconds}) => 'ค้นหาต่อไป ${seconds} วินาที';
	@override String get previousButton => 'เรื่องก่อนหน้า';
	@override String get nextButton => 'เรื่องถัดไป';
	@override String get previousChapterButton => 'ประเภทก่อนหน้า';
	@override String get nextChapterButton => 'บทความถัดไป';
	@override String get muteButton => 'ปกติ';
	@override String get unmuteButton => 'หมายเลข';
	@override String get settingsButton => 'การตั้งค่า Playback';
	@override String get tracksButton => 'เสียงและหัวข้อ';
	@override String get trackSelectionTitle => 'เลือกแถบก่อน playback';
	@override String get trackSelectionAuto => 'การเลือกอัตโนมัติ';
	@override String get chaptersButton => 'ประเภท';
	@override String get versionQualityButton => 'รุ่น & คุณภาพ';
	@override String get versionColumnHeader => 'รุ่น';
	@override String get qualityColumnHeader => 'คุณภาพ';
	@override String get qualityOriginal => 'หลัก';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'การเข้ารหัสผ่านไม่สามารถใช้ได้ - เล่นคุณภาพเดิม';
	@override String get subtitleUnavailableFallback => 'หัวฉบับที่เลือกไม่สามารถโหลดได้ - ต่อเนื่องโดยไม่มีหัวฉบับ';
	@override String get pipButton => 'รูปภาพในโหมด';
	@override String get aspectRatioButton => 'อัตราส่วน';
	@override String get ambientLighting => 'แสงสภาพแวดล้อม';
	@override String get fullscreenButton => 'หน้าจอเต็มรูปแบบ';
	@override String get exitFullscreenButton => 'หน้าจอแสดงผลเต็ม';
	@override String get alwaysOnTopButton => 'เสมอในด้านบน';
	@override String get rotationLockButton => 'ล็อคหมุน';
	@override String get lockScreen => 'หน้าจอปิดผนึก';
	@override String get screenLockButton => 'ล็อคหน้าจอ';
	@override String get longPressToUnlock => 'ความดันยาวที่จะเปิด';
	@override String get timelineSlider => 'วิดีโอ Timeline';
	@override String get volumeSlider => 'ระดับปริมาณ';
	@override String endsAt({required Object time}) => 'เสร็จสิ้นที่ ${time}';
	@override String get pipActive => 'เล่นใน Picture-in-Picture';
	@override String get pipFailed => 'ภาพถ่ายในภาพไม่สามารถเริ่มต้นได้';
	@override String get screenshotSaved => 'หน้าจอบันทึก';
	@override String get screenshotFailed => 'ไม่สามารถถ่ายภาพหน้าจอได้';
	@override String zoomPercent({required Object percent}) => 'ซูม ${percent}%';
	@override String volumePercent({required Object percent}) => 'ระดับเสียง ${percent}%';
	@override late final _Translations$videoControls$pipErrors$th pipErrors = _Translations$videoControls$pipErrors$th._(_root);
	@override String get chapters => 'ประเภท';
	@override String get noChaptersAvailable => 'ไม่มีบทที่พร้อมใช้งาน';
	@override String get queue => 'สิทธิ';
	@override String get noQueueItems => 'ไม่มีรายการใน Queue';
	@override String get noAudioDevicesAvailable => 'ไม่มีอุปกรณ์เสียง';
	@override String get searchSubtitles => 'ค้นหา Subtitles';
	@override String get loadSubtitleFile => 'ดาวน์โหลดไฟล์ Subtitle';
	@override String get subtitleLoadFailed => 'ไม่สามารถดาวน์โหลดไฟล์ subtitle';
	@override String get language => 'ภาษา';
	@override String get noSubtitlesFound => 'ไม่มีหัวข้อที่พบ';
	@override String get subtitleDownloaded => 'Subtitle ดาวน์โหลด';
	@override String get subtitleDownloadedNotApplied => 'Subtitle ดาวน์โหลด แต่ไม่สามารถเลือกได้';
	@override String get subtitleDownloadFailed => 'ไม่สามารถดาวน์โหลด Subtitle';
	@override String get searchLanguages => 'ค้นหาภาษา';
	@override String get skipIntro => 'สไลด์อินเตอร์เน็ต';
	@override String get skipCredits => 'คิดสกี';
	@override String get skipAds => 'การโฆษณา Skip';
	@override String get nextEpisode => 'เรื่องถัดไป';
	@override String subtitleTrack({required Object n}) => 'เคล็ดลับ ${n}';
	@override String subtitleFile({required Object name}) => 'คำบรรยาย ${name}';
	@override String forcedTrack({required Object label}) => '${label} (บังคับใช้)';
	@override String get osdSubtitlesOff => 'หัวข้อ: ปิด';
	@override String osdSubtitles({required Object track}) => 'หัวข้อ: ${track}';
	@override String osdAudio({required Object track}) => 'เสียง: ${track}';
}

// Path: messages
class _Translations$messages$th extends Translations$messages$en {
	_Translations$messages$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'บัญชีตามที่สังเกต';
	@override String get markedAsUnwatched => 'บัญชีที่ไม่ได้รับการตรวจสอบ';
	@override String get markedAsWatchedOffline => 'บรรทัดตามที่เห็น (จะซิงค์เมื่อออนไลน์)';
	@override String get markedAsUnwatchedOffline => 'บัญชีที่ไม่ได้รับการตรวจสอบ (จะซิงค์เมื่อออนไลน์)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'อัตโนมัติ: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n,
		other: 'อัตโนมัติลบ ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ดาวน์โหลด',
	);
	@override String get removedFromContinueWatching => 'ปล่อยออกจาก Continuing Watching';
	@override String errorLoading({required Object error}) => 'ความผิดพลาด: ${error}';
	@override String get searchPartialResults => 'บางเซิร์ฟเวอร์สื่อไม่สามารถค้นหาได้ แสดงผลที่มีอยู่';
	@override String get streamInterrupted => 'กระแสถูกหยุด การกดเล่นหรือพยายามที่จะย้อนกลับ';
	@override String get liveStreamInterrupted => 'การไหลสดถูกหยุด การเล่นกดเพื่อรีด';
	@override String get fileInfoNotAvailable => 'ข้อมูลไฟล์ไม่สามารถใช้ได้';
	@override String get playbackAuthenticationRequired => 'ลงชื่อเข้าสู่เซิร์ฟเวอร์สื่ออีกครั้งเพื่อเล่นรายการนี้';
	@override String get playbackServerUnavailable => 'เซิร์ฟเวอร์สื่อไม่สามารถใช้ได้ ลองอีกครั้งหลังจากนั้น';
	@override String get playbackDataInvalid => 'เซิร์ฟเวอร์ส่งข้อมูลการเล่นการเล่นที่ผิดพลาด';
	@override String get playbackCancelled => 'Playback ถูกยกเลิก';
	@override String get playbackFailed => 'Playback ไม่สามารถเริ่มต้นได้';
	@override String playbackFailedDetail({required Object error}) => 'Playback ไม่สามารถเริ่มต้นได้: ${error}';
	@override String get audioOutputFailed => 'การส่งออกเสียงหยุดตอบสนอง ตรวจสอบการเชื่อมต่อเสียงของทีวีหรือผู้รับ หากแอปอื่น ๆ ยังไม่มีเสียงแล้วเปิดอุปกรณ์ใหม่';
	@override String get mediaUnavailable => 'เนื้อหานี้ไม่สามารถใช้ได้อีกต่อไป';
	@override String errorLoadingFileInfo({required Object error}) => 'ข้อมูลไฟล์โหลดข้อผิดพลาด: ${error}';
	@override String get errorLoadingSeries => 'ชุดโหลดข้อผิดพลาด';
	@override String get musicNotSupported => 'การเล่นเพลงยังไม่ได้สนับสนุน';
	@override String get noDescriptionAvailable => 'ไม่มีคําอธิบาย';
	@override String get noProfilesAvailable => 'ไม่มีโปรไฟล์';
	@override String get contactAdminForProfiles => 'ติดต่อผู้ดูแลระบบเซิร์ฟเวอร์ของคุณเพื่อเพิ่มโปรไฟล์';
	@override String get unableToDetermineLibrarySection => 'ไม่สามารถกําหนดส่วนห้องสมุดสําหรับรายการนี้';
	@override String get logsCleared => 'โลกที่ทําความสะอาด';
	@override String get logsCopied => 'บันทึกที่คัดลอกไปยัง clipboard';
	@override String get noLogsAvailable => 'ไม่มีโลโก้ที่มีอยู่';
	@override String libraryScanning({required Object title}) => 'การสแกน "${title}"';
	@override String libraryScanStarted({required Object title}) => 'การสแกนห้องสมุดเริ่มสําหรับ "${title}"';
	@override String libraryScanFailed({required Object error}) => 'ไม่สามารถสแกนห้องสมุดได้: ${error}';
	@override String metadataRefreshing({required Object title}) => 'ข้อมูลจําเพาะสําหรับ "${title}"';
	@override String metadataRefreshStarted({required Object title}) => 'การฟื้นฟู Metadata เริ่มต้นสําหรับ "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'ไม่สามารถปรับปรุงข้อมูลโลหะได้: ${error}';
	@override String get logoutConfirm => 'คุณแน่ใจว่าคุณต้องการที่จะลงทะเบียนออกหรือไม่';
	@override String get noSeasonsFound => 'ไม่มีฤดูกาลที่พบ';
	@override String get seasonsLoadFailed => 'ไม่สามารถโหลดฤดูกาล';
	@override String get noEpisodesFound => 'ไม่พบ episodes ในฤดูกาลแรก';
	@override String get noEpisodesFoundGeneral => 'ไม่พบเหตุการณ์';
	@override String get episodesLoadFailed => 'ไม่สามารถโหลด episodes';
	@override String get noResultsFound => 'ไม่มีผลลัพธ์';
	@override String sleepTimerSet({required Object label}) => 'เวลานอนตั้งค่าสําหรับ ${label}';
	@override String get noItemsAvailable => 'ไม่มีรายการ';
	@override String get failedToCreatePlayQueueNoItems => 'ไม่สามารถสร้างสี่เหลี่ยมเล่นได้ - ไม่มีรายการ';
	@override String failedPlayback({required Object action, required Object error}) => 'ความล้มเหลว ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'เปลี่ยนไปยังผู้เล่นที่เข้ากันได้ ...';
	@override String get serverLimitTitle => 'Playback ไม่ประสบความสําเร็จ';
	@override String get serverLimitBody => 'ข้อผิดพลาดเซิร์ฟเวอร์ (HTTP 500) ข้อ จํากัด ความกว้างแบนด์วิดท์/การรหัสอาจปฏิเสธการประชุมนี้ โปรดขอให้เจ้าของปรับได้';
	@override String get mediaUnreadableTitle => 'ไฟล์ไม่สามารถเข้าถึงได้';
	@override String get mediaUnreadableBody => 'เซิร์ฟเวอร์พบรายการนี้ แต่ไม่สามารถอ่านไฟล์ (HTTP 404) ไฟล์อาจถูกย้ายลบหรือการจัดเก็บของมันไม่สามารถเข้าถึงได้ โปรดขอให้เจ้าของเซิร์ฟเวอร์ตรวจสอบไฟล์และบันทึกห้องสมุด';
	@override String get serverBusyTitle => 'การไหลไม่สามารถเข้าถึงได้';
	@override String get serverBusyBody => 'เซิร์ฟเวอร์ยังคงปฏิเสธที่จะส่งไฟล์นี้ (HTTP 503). มันอาจเป็นการเปิดตัวใหม่忙碌หรือการจัดเก็บของไฟล์อาจเป็นออฟไลน์ ลองอีกครั้งในเวลา - ถ้ามันยังคงเกิดขึ้นขอให้เจ้าของเซิร์ฟเวอร์ตรวจสอบเซิร์ฟเวอร์และจัดเก็บของไฟล์';
	@override String get playbackNotAllowedTitle => 'Playback ไม่ได้อนุญาต';
	@override String get playbackNotAllowedBody => 'เซิร์ฟเวอร์ปฏิเสธที่จะส่งรายการนี้ (HTTP 403). บัญชีของคุณอาจไม่มีอนุญาตในการเล่นมันหรือเซิร์ฟเวอร์อาจอนุญาตให้เล่นบนเครือข่ายท้องถิ่นเท่านั้น';
	@override String get logsUploaded => 'โลกอัปโหลด';
	@override String get logsUploadFailed => 'ไม่สามารถอัพโหลดโลโก้ได้';
	@override String get logId => 'รหัส';
	@override String get burnedSubtitlesUseMenu => 'Subtitles จะถูกเผาไหม้ลงใน stream นี้ เปลี่ยนพวกเขาจากเมนู subtitles';
	@override String get noVideoUrl => 'ไม่มี URL วีดีโอ';
	@override String get playbackNoMediaSources => 'เซิร์ฟเวอร์ไม่ส่งคืนแหล่งสื่อที่เล่นได้';
	@override String get playbackDataNotPrepared => 'Playback เริ่มต้นก่อนที่ข้อมูลของคุณพร้อม';
	@override String get streamSelectionUnavailable => 'การเลือก Stream ไม่สามารถใช้ได้สําหรับแหล่งนี้';
	@override String get streamSelectionFailed => 'ไม่สามารถใช้กระแสที่เลือก';
	@override String get trackSelectionNotRemembered => 'ตัวเลือกติดตามนี้ใช้กับการเล่นปัจจุบันเท่านั้น';
	@override String get serverUnavailableForProfile => 'ไม่มีเซิร์ฟเวอร์ที่มีอยู่สําหรับโปรไฟล์ที่ใช้งาน';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$th extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get previewSample => 'รวดเร็วสีน้ําตาล fox jumped บน คน หยาบคาย หํา';
	@override String get text => 'ข้อความ';
	@override String get border => 'รอบเขต';
	@override String get background => 'ลักษณะ';
	@override String get fontSize => 'หมายเลขขนาด';
	@override String get textColor => 'สีตัวอักษร';
	@override String get borderSize => 'ขนาดชายแดน';
	@override String get borderColor => 'สี จํากัด';
	@override String get backgroundOpacity => 'ลักษณะพื้นหลัง Opacity';
	@override String get backgroundColor => 'สีพื้นหลัง';
	@override String get position => 'ตําแหน่ง';
	@override String get assOverride => 'ASS ทั่วไป';
	@override String get overrideScale => 'ระดับ';
	@override String get overrideForce => 'ความแข็งแรง';
	@override String get overrideStrip => 'ปล่อยสเตนเลส';
	@override String get positionTop => 'หลัก';
	@override String get positionBottom => 'ภายใต้';
	@override String get useMargins => 'การใช้ margins';
	@override String get useMarginsDescription => 'ให้หัวข้อข้อความอยู่ในพื้นที่นอกวิดีโอ หัวข้อรูปแบบสามารถเก็บตําแหน่งเดิม';
	@override String get anchorToScreen => 'Anchor to หน้าจอ';
	@override String get anchorToScreenDescription => 'แสดงหัวข้อข้อความในแถบสีดําด้านล่างวิดีโอหน้าจอกว้าง';
	@override String get bold => 'ตัวหนา';
	@override String get italic => 'อิตาลี';
	@override String get renderResolution => 'โซลูชั่น Render';
	@override String get renderResolutionScreen => 'ความละเอียดจอ';
	@override String get renderResolutionVideo => 'วีดีโอ Resolution';
}

// Path: mpvConfig
class _Translations$mpvConfig$th extends Translations$mpvConfig$en {
	_Translations$mpvConfig$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'การตั้งค่าของวิดีโอเล่นขั้นสูง';
	@override String get presets => 'โพสต์';
	@override String get noPresets => 'ไม่มีการบันทึก';
	@override String get saveAsPreset => 'เก็บเป็น Preset';
	@override String get presetName => 'ชื่อเริ่มต้น';
	@override String get presetNameHint => 'ใส่ชื่อสําหรับ preset นี้';
	@override String get loadPreset => 'โหลด';
	@override String get deletePreset => 'ลบ';
	@override String get presetSaved => 'โพสต์บันทึก';
	@override String get presetLoaded => 'โหลด';
	@override String get presetDeleted => 'โพสต์ลบ';
	@override String get confirmDeletePreset => 'คุณแน่ใจว่าคุณต้องการลบการตั้งค่านี้หรือไม่';
	@override String get configPlaceholder => 'gpu-api=vulkan hwdec=auto # ความคิดเห็น';
	@override String get lineHint => 'option=value';
	@override String get addLine => 'เพิ่มสาย';
	@override String get removeLine => 'ลบสาย';
	@override String get embeddedVoHint => 'vo, gpu-context และ gpu-api จะถูก ignored บน Linux: วิดีโอที่รวมเสมอส่งผ่าน vo=libmpv บนวิดีโอเครื่องบินและ gpu-next (ซึ่งวอลล์คอมพิวเตอร์เช่น ArtCNN ต้องใช้) ไม่สามารถทํางานที่รวม';
}

// Path: dialog
class _Translations$dialog$th extends Translations$dialog$en {
	_Translations$dialog$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'การกระทําที่ยืนยัน';
}

// Path: profiles
class _Translations$profiles$th extends Translations$profiles$en {
	_Translations$profiles$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'เพิ่มโปรไฟล์ PlezyNG';
	@override String get switchingProfile => 'การเปลี่ยนโปรไฟล์';
	@override String get deleteThisProfileTitle => 'ลบโปรไฟล์นี้หรือไม่';
	@override String deleteThisProfileMessage({required Object displayName}) => 'ลบ ${displayName}. การเชื่อมต่อไม่ได้รับผลกระทบ';
	@override String get active => 'การใช้งาน';
	@override String get manage => 'การจัดการ';
	@override String get delete => 'ลบ';
	@override String get signOut => 'ออกจากระบบ';
	@override String get signOutPlexTitle => 'ลงทะเบียนออกจาก Plex';
	@override String signOutPlexMessage({required Object displayName}) => 'ลบ ${displayName} และทั้งหมด Plex ผู้ใช้บ้าน? ลงทะเบียนกลับมาในเวลาใด ๆ.';
	@override String get signOutPlexDeleteDownloads => 'ลบดาวน์โหลด';
	@override String get signOutPlexDeleteDownloadsDescription => 'ไม่ว่าพวกเขาจะอยู่บนอุปกรณ์นี้และกลับมาเมื่อคุณลงชื่อเข้าสู่บัญชีนี้';
	@override String get signedOutPlex => 'ได้รับการลงนามจาก Plex';
	@override String get signOutFailed => 'การลงทะเบียนไม่สําเร็จ';
	@override String get sectionTitle => 'โปรไฟล์';
	@override String get summarySingle => 'เพิ่มโปรไฟล์เพื่อผสมผู้ใช้ที่จัดการและตัวตนในท้องถิ่น';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} โปรไฟล์ · ใช้งานได้: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} โปรไฟล์';
	@override String get removeConnectionTitle => 'การเชื่อมต่อ';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'ลบการเข้าถึง ${displayName} ไปยัง ${connectionLabel}. โปรไฟล์อื่น ๆ เก็บไว้.';
	@override String get deleteProfileTitle => 'ลบโปรไฟล์';
	@override String deleteProfileMessage({required Object displayName}) => 'ลบ ${displayName} และเชื่อมต่อของมัน เซิร์ฟเวอร์ยังคงมีอยู่';
	@override String get profileNameLabel => 'ชื่อโปรไฟล์';
	@override String get pinProtectionLabel => 'การป้องกัน PIN';
	@override String get copyAutomationLink => 'คัดลอก Android ลิงค์อัตโนมัติ';
	@override String get copyAutomationLinkDescription => 'เลือกโปรไฟล์นี้จากความตั้งใจหรืออัตโนมัติ Android โปรไฟล์ตรวจสอบ PIN ยังคงใช้';
	@override String get automationLinkCopied => 'โปรไฟล์อัตโนมัติลิงค์คัดลอก';
	@override String get pinManagedByPlex => 'PIN ที่จัดการโดย Plex. Edit on plex.tv.';
	@override String get noPinSetEditOnPlex => 'ไม่มีการตั้งค่า PIN สําหรับต้องการหนึ่งแก้ไขผู้ใช้บ้านบน plex.tv';
	@override String get setPin => 'ปรับ PIN';
	@override String get setPinTitle => 'ปรับ PIN';
	@override String get confirmPinTitle => 'การยืนยัน PIN';
	@override String get pinSet => 'หมายเลขรุ่น: PIN';
	@override String get changePin => 'การเปลี่ยนแปลง';
	@override String get removePin => 'นำออก';
	@override String get connectionsLabel => 'การเชื่อมต่อ';
	@override String get add => 'เพิ่ม';
	@override String get deleteProfileButton => 'ปล่อยโปรไฟล์';
	@override String get noConnectionsHint => 'ไม่มีการเชื่อมต่อ - เพิ่มหนึ่งเพื่อใช้โปรไฟล์นี้';
	@override String get noConnections => 'ไม่มีการเชื่อมต่อ';
	@override String get plexHomeAccount => 'Plex บัญชีบ้าน';
	@override String plexAccountChip({required Object account}) => 'Plex บัญชี: ${account}';
	@override String plexAccountUserChip({required Object user, required Object account}) => '${user} ผ่าน ${account}';
	@override String get connectionDefault => 'ค่าเริ่มต้น';
	@override String connectionAs({required Object displayName}) => 'เป็น ${displayName}';
	@override String get makeDefault => 'ทํา default';
	@override String get removeConnection => 'นำออก';
	@override String get profileRenamed => 'ชื่อโปรไฟล์';
	@override String borrowAddTo({required Object displayName}) => 'เพิ่มไปยัง ${displayName}';
	@override String get borrowExplain => 'การเชื่อมต่อโปรไฟล์อื่น ๆ การป้องกันโปรไฟล์ PIN ต้องใช้ PIN';
	@override String get borrowEmpty => 'ไม่มีอะไรที่จะ δανειστείอีกต่อไป';
	@override String get borrowEmptySubtitle => 'เชื่อมต่อ Plex, Jellyfin หรือ Emby ไปยังโปรไฟล์อื่นแรก';
	@override String get borrowLoadFailed => 'การเชื่อมต่อที่มีอยู่ไม่สามารถโหลดได้ ลองอีกครั้ง';
	@override String borrowFromProfile({required Object displayName}) => 'จาก ${displayName}';
	@override String get borrowConnectionBorrowed => 'การเชื่อมต่อที่ถูก δανειστεί';
	@override String get borrowFailed => 'ไม่สามารถเชื่อมต่อเครดิตได้';
	@override String get incorrectPin => 'PIN ไม่ถูกต้อง';
	@override String get incorrectPinTryAgain => 'PIN ไม่ถูกต้อง โปรดลองอีกครั้ง';
	@override String get sourceProfileMissingParentAccount => 'โปรไฟล์แหล่งที่มาขาดบัญชีผู้ปกครอง';
	@override String get failedToLoadHomeUsers => 'ไม่สามารถโหลดผู้ใช้บ้าน Plex ของคุณ ตรวจสอบการเชื่อมต่อของคุณและลองอีกครั้ง';
	@override String get failedToVerifyPin => 'ไม่สามารถตรวจสอบ PIN ได้';
	@override String get newProfile => 'โปรไฟล์ใหม่';
	@override String get profileNameHint => 'ตัวอย่าง: บุคคลทั่วไป, เด็ก, ห้องครอบครัว';
	@override String get pinProtectionOptional => 'การป้องกัน PIN (ตัวเลือก)';
	@override String get pinExplain => '4 หมายเลข PIN ที่จําเป็นสําหรับการเปลี่ยนโปรไฟล์';
	@override String get continueButton => 'เสร็จสิ้น';
	@override String get pinsDontMatch => 'PINs ไม่เข้ากันได้';
	@override String get tokenIdentityMismatch => 'โค้นโปรไฟล์ Plex โซลูชันไปยังเซิร์ฟเวอร์ที่ไม่คาดหวัง';
	@override String get settingsLocked => 'การตั้งค่าจะถูกล็อคสําหรับโปรไฟล์นี้';
	@override String get unlockSettings => 'ปล็อคการตั้งค่า';
	@override String get showExploreForProfile => 'แสดง ค้นหาสําหรับโปรไฟล์นี้';
	@override String get showExploreForProfileDescription => 'ปิดเพื่อลบ Explore จากการนําทางโปรไฟล์นี้';
}

// Path: connections
class _Translations$connections$th extends Translations$connections$en {
	_Translations$connections$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'การเชื่อมต่อ';
	@override String get addConnection => 'เพิ่มการเชื่อมต่อ';
	@override String get addConnectionSubtitleNoProfile => 'ลงทะเบียนกับ Plex หรือเชื่อมต่อเซิร์ฟเวอร์ Jellyfin หรือ Emby';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'เพิ่มไปยัง ${displayName}: Plex, Jellyfin, Emby, หรือการเชื่อมต่อโปรไฟล์อื่น ๆ';
	@override String sessionExpiredOne({required Object name}) => 'การประชุมสิ้นสุดสําหรับ ${name}';
	@override String sessionExpiredMany({required Object count}) => 'เซิร์ฟเวอร์ ${count} เซิร์ฟเวอร์';
	@override String accessDeniedOne({required Object name}) => '${name} ไม่เข้าถึงบัญชีนี้';
	@override String accessDeniedMany({required Object count}) => '${count} เซิร์ฟเวอร์ปฏิเสธการเข้าถึงบัญชีนี้';
	@override String get signInAgain => 'ลงทะเบียนอีกครั้ง';
	@override String editMediaBrowserTitle({required Object product}) => 'Edit ${product} การเชื่อมต่อ';
	@override String editMediaBrowserIntro({required Object serverName}) => 'เพิ่มหรือลบ URL สําหรับ ${serverName}. PlezyNG จะใช้ URL ที่สามารถเข้าถึงได้ด้วย latency ที่ต่ําสุด';
}

// Path: accountPreferences
class _Translations$accountPreferences$th extends Translations$accountPreferences$en {
	_Translations$accountPreferences$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'การตั้งค่าบัญชี';
	@override String hubSubtitleSingle({required Object account}) => 'ออฟต์แวร์เสียงและตัวเลือกห้องสมุดที่บันทึกไว้บน ${account}';
	@override String hubSubtitleMultiple({required Object count}) => 'ออฟต์แวร์อัตโนมัติและตัวเลือกห้องสมุดที่บันทึกไว้ในบัญชี ${count}';
	@override String get pickAccount => 'บัญชีแต่ละบัญชีจัดเก็บความต้องการของตัวเอง เลือกหนึ่งในการแก้ไข';
	@override String get storedOnAccount => 'ตัวเลือกเหล่านี้จะถูกบันทึกไว้ในบัญชีของคุณเองดังนั้นแอปที่ลงชื่อเข้าสู่ระบบจะใช้พวกเขา - รวมถึง PlezyNG บนอุปกรณ์อื่น ๆ ของคุณ';
	@override String get noAccounts => 'ไม่มีบัญชีที่กําหนดเอง';
	@override String get noAccountsHint => 'ลงชื่อเข้าสู่ระบบที่ Plex หรือเชื่อมต่อกับเซิร์ฟเวอร์ Jellyfin หรือ Emby และข้อกําหนดที่เก็บไว้ในบัญชีนี้จะปรากฏที่นี่';
	@override String get unavailable => 'ไม่สามารถเข้าถึงบัญชีนี้ได้';
	@override String get loadFailed => 'ไม่สามารถโหลดข้อกําหนดเหล่านี้ได้';
	@override String get noPreference => 'ไม่มีความต้องการ';
	@override String get notSet => 'ไม่ตั้งค่า';
	@override late final _Translations$accountPreferences$groups$th groups = _Translations$accountPreferences$groups$th._(_root);
	@override String get preferredAudioLanguage => 'ภาษาเสียงที่ชื่นชอบ';
	@override String get autoSelectAudio => 'เลือกเสียงตามภาษา';
	@override String get autoSelectAudioDescription => 'ปิดเก็บรวบรวมเสียงใด ๆ ที่ติดตามไฟล์เป็นตัวเลือกที่กําหนดเอง';
	@override String get preferredSubtitleLanguage => 'ภาษาที่ชื่นชอบ Subtitle';
	@override String get subtitleMode => 'แปลงหัวข้อใน';
	@override late final _Translations$accountPreferences$subtitleModes$th subtitleModes = _Translations$accountPreferences$subtitleModes$th._(_root);
	@override String get subtitleAccessibility => 'SDH หัวข้อ';
	@override late final _Translations$accountPreferences$subtitleAccessibilityOptions$th subtitleAccessibilityOptions = _Translations$accountPreferences$subtitleAccessibilityOptions$th._(_root);
	@override String get forcedSubtitles => 'หัวข้อบังคับ';
	@override late final _Translations$accountPreferences$forcedSubtitleOptions$th forcedSubtitleOptions = _Translations$accountPreferences$forcedSubtitleOptions$th._(_root);
	@override String get displayMissingEpisodes => 'แสดงเหตุการณ์ที่หายไป';
	@override String get displayMissingEpisodesDescription => 'รายการ episodes ที่เซิร์ฟเวอร์รู้เกี่ยวกับ แต่ไม่มีไฟล์สําหรับ';
	@override String get hidePlayedInLatest => 'ลองดูรายการในล่าสุด';
	@override String get hidePlayedInLatestDescription => 'ปล่อยรายการที่คุณได้ดูออกจากแถวล่าสุดของเซิร์ฟเวอร์';
	@override String get displayCollectionsView => 'แสดงการดูการเก็บเกี่ยว';
	@override String get displayCollectionsViewDescription => 'ให้ดูการเก็บของเซิร์ฟเวอร์พร้อมกับห้องสมุดของคุณ';
	@override String get rewatchingInNextUp => 'ปล่อยให้มีการตรวจสอบใหม่ใน Next Up';
	@override String get rewatchingInNextUpDescription => 'เมื่อคุณเสร็จสิ้นการแสดงแล้วเริ่มอีกครั้งและ Next Up จะติดตามการตรวจสอบใหม่แทนที่จะลดการแสดง';
	@override String get watchedIndicator => 'ตัวชี้วัดที่มองเห็น';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$th watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$th._(_root);
	@override String get mediaReviewsVisibility => 'การประเมิน & รีวิว';
	@override late final _Translations$accountPreferences$mediaReviewsOptions$th mediaReviewsOptions = _Translations$accountPreferences$mediaReviewsOptions$th._(_root);
}

// Path: discover
class _Translations$discover$th extends Translations$discover$en {
	_Translations$discover$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'ค้นหา';
	@override String get noContentAvailable => 'ไม่มีเนื้อหาที่มีอยู่';
	@override String get addMediaToLibraries => 'เพิ่มสื่อบางอย่างไปยังห้องสมุดของคุณ';
	@override String get continueWatching => 'ดูต่อ';
	@override String continueWatchingIn({required Object library}) => 'ดูเพิ่มเติมใน ${library}';
	@override String get nextUp => 'ถัดไป';
	@override String nextUpIn({required Object library}) => 'ต่อไปขึ้นใน ${library}';
	@override String get recentlyAdded => 'เพิ่มล่าสุด';
	@override String recentlyAddedIn({required Object library}) => 'เพิ่มเมื่อเร็ว ๆ นี้ ใน ${library}';
	@override String latestAlbumsIn({required Object library}) => 'อัลบั้มล่าสุดใน ${library}';
	@override String recentlyPlayedIn({required Object library}) => 'เล่นล่าสุดใน ${library}';
	@override String mostPlayedIn({required Object library}) => 'ส่วนใหญ่เล่นใน ${library}';
	@override String playEpisode({required Object season, required Object episode}) => 'ซีซัน ${season} ตอน ${episode}';
	@override String get overview => 'ทบทวน';
	@override String get cast => 'คะแนน';
	@override String get extras => 'Trailers และ Extras';
	@override String get studio => 'สตูดิโอ';
	@override String get rating => 'คะแนน';
	@override String get director => 'ผู้กำกับ';
	@override String get directors => 'ผู้กำกับ';
	@override String get movie => 'ภาพยนตร์';
	@override String get tvShow => 'แสดงทีวี';
	@override String minutesLeft({required Object minutes}) => '${minutes} นาที left';
	@override String get moreLikeThis => 'มากกว่าเช่นนี้';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} หัวข้อ',
	);
	@override late final _Translations$discover$person$th person = _Translations$discover$person$th._(_root);
}

// Path: errors
class _Translations$errors$th extends Translations$errors$en {
	_Translations$errors$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'ค้นหาล้มเหลว: ${error}';
	@override String get searchUnavailable => 'ค้นหาไม่สามารถเข้าถึงเซิร์ฟเวอร์สื่อใด ๆ';
	@override String connectionTimeout({required Object context}) => 'เวลาการเชื่อมต่อเมื่อโหลด ${context}';
	@override String get connectionFailed => 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์สื่อ';
	@override String unableToLoad({required Object context}) => 'ไม่สามารถโหลด ${context} โปรดลองอีกครั้ง';
	@override String get noClientAvailable => 'ไม่มีลูกค้า';
	@override String get pleaseEnterToken => 'กรุณาใส่ token';
	@override String get invalidToken => 'โค้นที่ผิดพลาด';
	@override String failedToVerifyToken({required Object error}) => 'ไม่สามารถตรวจสอบ token: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'ไม่สามารถเปลี่ยนไป ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'ไม่สามารถลบได้ ${displayName}';
	@override String get failedToRate => 'ไม่สามารถปรับปรุงการรับรอง';
	@override String get reasonTimedOut => 'การเชื่อมต่อที่กําหนดเวลา';
	@override String get reasonUnreachable => 'เซิร์ฟเวอร์ไม่สามารถเข้าถึงได้';
	@override String get reasonRefused => 'เซิร์ฟเวอร์ปฏิเสธคําขอ';
	@override String get reasonNotFound => 'รายการไม่ได้อยู่ในเซิร์ฟเวอร์';
	@override String get reasonServerError => 'เซิร์ฟเวอร์รายงานข้อผิดพลาด';
	@override String get reasonCancelled => 'คําขอถูกยกเลิก';
	@override String get reasonUnexpected => 'ข้อผิดพลาดที่ไม่คาดหวังเกิดขึ้น';
}

// Path: libraries
class _Translations$libraries$th extends Translations$libraries$en {
	_Translations$libraries$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => 'เล่นภาพยนตร์สุ่ม';
	@override String get randomPickFailed => 'ไม่สามารถเลือกภาพยนตร์สุ่มจากห้องสมุดนี้ได้';
	@override String get title => 'ห้องสมุด';
	@override String get fallbackTitle => 'คลังสื่อ';
	@override String get scanLibraryFiles => 'ไฟล์สแกนห้องสมุด';
	@override String get scanLibrary => 'แสกนไลบรารี่';
	@override String get analyze => 'การวิเคราะห์';
	@override String get analyzeLibrary => 'การวิเคราะห์ห้องสมุด';
	@override String get refreshMetadata => 'การปรับปรุง Metadata';
	@override String get emptyTrash => 'ระยําที่ว่างเปล่า';
	@override String emptyingTrash({required Object title}) => 'ปิดฝุ่นสําหรับ "${title}..."';
	@override String trashEmptied({required Object title}) => 'โลหะที่ถูกเก็บไว้สําหรับ "${title}"';
	@override String failedToEmptyTrash({required Object error}) => 'ไม่สามารถล้างฝุ่นได้: ${error}';
	@override String analyzing({required Object title}) => 'การวิเคราะห์ "${title}..."';
	@override String analysisStarted({required Object title}) => 'การวิเคราะห์เริ่มต้นสําหรับ "${title}"';
	@override String failedToAnalyze({required Object error}) => 'ไม่สามารถวิเคราะห์ห้องสมุดได้: ${error}';
	@override String get noLibrariesFound => 'ไม่พบห้องสมุด';
	@override String get allLibrariesHidden => 'ห้องสมุดทั้งหมดซ่อนอยู่';
	@override String hiddenLibrariesCount({required Object count}) => 'ห้องสมุดที่ซ่อนอยู่ (${count})';
	@override String get thisLibraryIsEmpty => 'ห้องสมุดนี้ว่างเปล่า';
	@override String get noItemsMatchFilters => 'ไม่มีรายการตรงกับตัวกรองที่ใช้งาน';
	@override String get resetFilters => 'ฟิล์มรีเซ็ต';
	@override String get all => 'ทั้งหมด';
	@override String get clearAll => 'แสดงทั้งหมด';
	@override String scanLibraryConfirm({required Object title}) => 'คุณแน่ใจว่าคุณต้องการสแกน "${title}"';
	@override String analyzeLibraryConfirm({required Object title}) => 'คุณแน่ใจว่าคุณต้องการวิเคราะห์ "${title}"';
	@override String refreshMetadataConfirm({required Object title}) => 'คุณแน่ใจว่าคุณต้องการอัปเดตข้อมูล metadata สําหรับ "${title}"';
	@override String emptyTrashConfirm({required Object title}) => 'คุณแน่ใจว่าคุณต้องการที่จะทําให้เสียเปล่าสําหรับ "${title}"';
	@override String get manageLibraries => 'การจัดการห้องสมุด';
	@override String get sort => 'จัดเรียง';
	@override String get sortBy => 'หมายเลขรุ่น:';
	@override String get filters => 'ฟิล์ม';
	@override String get confirmActionMessage => 'คุณแน่ใจว่าคุณต้องการดําเนินการนี้หรือไม่';
	@override String get showLibrary => 'แสดงห้องสมุด';
	@override String get hideLibrary => 'ซ่อนห้องสมุด';
	@override String get libraryOptions => 'ตัวเลือกห้องสมุด';
	@override String get content => 'วัสดุห้องสมุด';
	@override String get selectLibrary => 'เลือกห้องสมุด';
	@override String filtersWithCount({required Object count}) => 'ตัวกรอง (${count})';
	@override String get noRecommendations => 'ไม่มีคําแนะนําที่มีอยู่';
	@override String get noCollections => 'ไม่มีคอลเลกชันในห้องสมุดนี้';
	@override String get noFoldersFound => 'ไม่พบโฟลเดอร์';
	@override String get folders => 'โฟลเดอร์';
	@override late final _Translations$libraries$tabs$th tabs = _Translations$libraries$tabs$th._(_root);
	@override late final _Translations$libraries$groupings$th groupings = _Translations$libraries$groupings$th._(_root);
	@override late final _Translations$libraries$filterCategories$th filterCategories = _Translations$libraries$filterCategories$th._(_root);
	@override late final _Translations$libraries$sortLabels$th sortLabels = _Translations$libraries$sortLabels$th._(_root);
	@override late final _Translations$libraries$advancedFilters$th advancedFilters = _Translations$libraries$advancedFilters$th._(_root);
	@override late final _Translations$libraries$selection$th selection = _Translations$libraries$selection$th._(_root);
}

// Path: about
class _Translations$about$th extends Translations$about$en {
	_Translations$about$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'เกี่ยวกับ';
	@override String get openSourceLicenses => 'ใบอนุญาต Open Source';
	@override String versionLabel({required Object version}) => 'รุ่น ${version}';
	@override String get appDescription => 'ลูกค้าที่สวยงาม Plex, Jellyfin และ Emby สําหรับ Flutter';
	@override String get viewLicensesDescription => 'ดูใบอนุญาตของห้องสมุดบุคคลที่สาม';
	@override String get privacyPolicy => 'นโยบายความเป็นส่วนตัว';
}

// Path: serverSelection
class _Translations$serverSelection$th extends Translations$serverSelection$en {
	_Translations$serverSelection$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'ไม่มีเซิร์ฟเวอร์ที่พบสําหรับ ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'เซิร์ฟเวอร์ที่ไม่ได้โหลด: ${error}';
	@override String get noValidServers => 'ไม่มีเซิร์ฟเวอร์ที่ใช้ได้พบในบัญชีนี้';
}

// Path: hubDetail
class _Translations$hubDetail$th extends Translations$hubDetail$en {
	_Translations$hubDetail$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'ชื่อเรื่อง';
	@override String get releaseYear => 'ปีการปล่อย';
	@override String get dateAdded => 'วันที่เพิ่ม';
	@override String get rating => 'คะแนน';
	@override String get noItemsFound => 'ไม่มีรายการที่พบ';
}

// Path: logs
class _Translations$logs$th extends Translations$logs$en {
	_Translations$logs$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'โลกที่ชัดเจน';
	@override String get copyLogs => 'คัดลอกโลโก้';
	@override String get uploadLogs => 'โลกอัปโหลด';
	@override String get saveLogs => 'บันทึกบันทึกไฟล์';
	@override String logsSaved({required Object path}) => 'บันทึกที่บันทึกถึง ${path}';
	@override String get saveLogsFailed => 'ไม่สามารถบันทึกไฟล์บันทึก';
}

// Path: detail
class _Translations$detail$th extends Translations$detail$en {
	_Translations$detail$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => 'เสร็จสิ้นที่ ${time}';
}

// Path: startup
class _Translations$startup$th extends Translations$startup$en {
	_Translations$startup$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'PlezyNG ไม่สามารถเริ่มต้นได้';
	@override String get failedBody => 'สิ่งบางอย่างผิดพลาดในระหว่างการเริ่มต้น รายละเอียดด้านล่างระบุสิ่งที่ไม่ประสบความสําเร็จ';
	@override String get failedBodyRepairable => 'PlezyNG ไฟล์การตั้งค่าที่บันทึกจะเสียหายและต้องสร้างใหม่ก่อนที่ PlezyNG สามารถเริ่มต้น การคืนเงินจะไม่ช่วย - เลือกการซ่อมแซมการจัดเก็บข้อมูล';
	@override String get phaseLabel => 'ขั้นตอน';
	@override String get showDetails => 'แสดงรายละเอียด';
	@override String get hideDetails => 'ลบรายละเอียด';
	@override String get copyDetails => 'คัดลอกรายละเอียด';
	@override String get detailsCopied => 'รายละเอียดคัดลอกไปยัง clipboard';
	@override String get uploadDetails => 'รายละเอียดอัปโหลด';
	@override String get repairStorage => 'การซ่อมแซม';
	@override String get repairTitle => 'การซ่อมแซมข้อมูลที่เก็บไว้';
	@override String get repairBodyCommon => 'PlezyNG ไฟล์การตั้งค่าจะเสียหายและไม่สามารถอ่านได้ การซ่อมแซมการตั้งค่าแต่ละตั้งค่าจะถูกกําหนดเอง';
	@override String get repairBodyOneCredential => 'หนึ่งบันทึกจะเสียหายและไม่สามารถอ่านได้ การซ่อมแซมจะลบเพียงหนึ่งการตั้งค่าอื่น ๆ ของคุณจะหายไป';
	@override String get repairBodySignInsKept => 'เซิร์ฟเวอร์และโปรไฟล์ของคุณควรจะยังคงลงทะเบียน';
	@override String get repairBodySignInsLost => 'คีย์ที่ปกป้องการบันทึกบันทึกของคุณไม่สามารถกู้คืนจากไฟล์นี้ดังนั้นคุณจะต้องลงชื่อเข้าสู่เซิร์ฟเวอร์และโปรไฟล์อีกครั้ง ไม่มีอะไรในเซิร์ฟเวอร์สื่อของคุณจะได้รับผลกระทบ';
	@override String get repairBodySessionsUncertain => 'Trackers (MAL, AniList, Simkl, Trakt) และ Seerr จะถูกเก็บไว้แยกต่างหากและอาจหรืออาจไม่ได้อยู่อยู่ PlezyNG จะบอกคุณว่าสิ่งที่มันเก็บไว้';
	@override String get repairConfirm => 'การซ่อมแซม';
	@override String get repairSucceeded => 'การจัดเก็บที่ซ่อมแซม';
	@override String get repairNeedsRestart => 'การจัดเก็บที่ซ่อมแซม - การเริ่มต้นใหม่ที่จําเป็น';
	@override String get restartRequiredBody => 'ข้อมูลของคุณได้รับการแก้ไข แต่ PlezyNG จะต้องเริ่มต้นใหม่ก่อนที่จะสามารถใช้ได้ ลบ PlezyNG และเปิดอีกครั้ง';
	@override String get quitPlezy => 'เคลือบ PlezyNG';
	@override String get repairFailed => 'การซ่อมแซมล้มเหลว';
	@override String get repairKeptSignIns => 'เซิร์ฟเวอร์และโปรไฟล์ของคุณยังคงลงทะเบียน';
	@override String get repairLostSignIns => 'คีย์ที่ปกป้องการบันทึกของคุณไม่สามารถกู้คืน คุณจะต้องลงชื่อเข้าสู่เซิร์ฟเวอร์และโปรไฟล์ทุกครั้งอีกครั้ง';
	@override String get repairLostSessions => 'การเชื่อมต่อ Tracker หรือ Seerr หนึ่งอย่างน้อยถูกสูญเสียและต้องเชื่อมต่อใหม่';
	@override String get backupTitle => 'คูปองของไฟล์ที่เสียหายถูกเก็บไว้';
	@override String get backupWarning => 'มันมีใบรับรองการลงทะเบียนของคุณ อย่าอัพโหลดหรือแบ่งปัน';
	@override String get deleteBackup => 'ลบสําเนา';
	@override String get backupDeleted => 'การคัดลอกลบ';
	@override String get previousFailureTitle => 'PlezyNG ไม่สามารถเริ่มต้นครั้งสุดท้าย';
}

// Path: licenses
class _Translations$licenses$th extends Translations$licenses$en {
	_Translations$licenses$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'บรรจุภัณฑ์ที่เกี่ยวข้อง';
	@override String get license => 'ใบอนุญาต';
	@override String licenseNumber({required Object number}) => 'ใบอนุญาต ${number}';
	@override String licensesCount({required Object count}) => '${count} ใบอนุญาต';
}

// Path: navigation
class _Translations$navigation$th extends Translations$navigation$en {
	_Translations$navigation$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'ห้องสมุด';
	@override String get downloads => 'รายการดาวน์โหลด';
	@override String get liveTv => 'ทีวีสด';
	@override String get explore => 'ค้นหา';
}

// Path: explore
class _Translations$explore$th extends Translations$explore$en {
	_Translations$explore$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override late final _Translations$explore$mdblistShelves$th mdblistShelves = _Translations$explore$mdblistShelves$th._(_root);
	@override String get title => 'ค้นหา';
	@override String get selectSource => 'เลือกแหล่งข้อมูล';
	@override late final _Translations$explore$rows$th rows = _Translations$explore$rows$th._(_root);
	@override late final _Translations$explore$status$th status = _Translations$explore$status$th._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ครั้งที่เข้าดู',
	);
	@override String get cast => 'คะแนน';
	@override String get characters => 'ตัวละคร';
	@override String get addToWatchlist => 'เพิ่มเข้าสู่ Watchlist';
	@override String get removeFromWatchlist => 'ลบออกจาก Watchlist';
	@override String get addedToWatchlist => 'ที่เพิ่มลงใน watchlist';
	@override String get removedFromWatchlist => 'ลบออกจาก watchlist';
	@override String get watchlistUpdateFailed => 'ไม่สามารถปรับปรุงรายการตรวจสอบ';
	@override String get watchlistNoMatch => 'ไม่สามารถเข้ากันได้รายการนี้กับรายการตรวจสอบ';
	@override String get notInLibrary => 'ไม่อยู่ในห้องสมุดของคุณ';
	@override String get inTheseLibraries => 'ในห้องสมุดเหล่านี้';
	@override String get checkingLibrary => 'ตรวจสอบห้องสมุดของคุณ';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n,
		other: 'ไม่สามารถตรวจสอบเซิร์ฟเวอร์ ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}',
	);
	@override String get emptyTitle => 'ไม่มีอะไรที่นี่';
	@override String emptyMessage({required Object source}) => 'รอบจาก ${source} จะปรากฏที่นี่เมื่อมีเนื้อหา';
	@override String searchHint({required Object source}) => 'ค้นหา ${source}';
	@override String searchEmpty({required Object query}) => 'ไม่มีผลลัพธ์สําหรับ "${query}"';
	@override String searchPrompt({required Object source}) => 'ค้นหาภาพยนตร์และแสดงใน ${source}';
	@override String get searchFailed => 'ค้นหาล้มเหลว ตรวจสอบการเชื่อมต่อของคุณและลองอีกครั้ง';
	@override late final _Translations$explore$badge$th badge = _Translations$explore$badge$th._(_root);
	@override late final _Translations$explore$stats$th stats = _Translations$explore$stats$th._(_root);
	@override late final _Translations$explore$season$th season = _Translations$explore$season$th._(_root);
	@override late final _Translations$explore$format$th format = _Translations$explore$format$th._(_root);
	@override late final _Translations$explore$sourceMaterial$th sourceMaterial = _Translations$explore$sourceMaterial$th._(_root);
	@override late final _Translations$explore$creditRole$th creditRole = _Translations$explore$creditRole$th._(_root);
	@override late final _Translations$explore$relation$th relation = _Translations$explore$relation$th._(_root);
	@override String broadcast({required Object day, required Object time}) => 'Airs ${day} ที่ ${time}';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => 'Airs ${day} ที่ ${time} ${timezone}';
	@override late final _Translations$explore$detail$th detail = _Translations$explore$detail$th._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ผล',
	);
}

// Path: liveTv
class _Translations$liveTv$th extends Translations$liveTv$en {
	_Translations$liveTv$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'ทีวีสด';
	@override String get guide => 'คู่มือ';
	@override String get noChannels => 'ไม่มีช่องทาง';
	@override String get noDvr => 'ไม่มีการกําหนดค่า DVR บนเซิร์ฟเวอร์ใด ๆ';
	@override String get serverUnavailable => 'เซิร์ฟเวอร์ทีวีสดไม่สามารถใช้ได้';
	@override String get serverNotConnected => 'เซิร์ฟเวอร์ทีวีสดไม่ได้เชื่อมต่อ';
	@override String get noPrograms => 'ไม่มีข้อมูลโปรแกรมที่มีอยู่';
	@override String get liveStreamFailed => 'การไหลสดล้มเหลว';
	@override String get unknownProgram => 'โปรแกรมที่ไม่รู้จัก';
	@override String get timelineLiveProgram => 'โปรแกรมสด (Playback อาจอยู่นอกโปรแกรมนี้)';
	@override String get timelineBuffer => 'บูฟเฟอร์ Timeline';
	@override String get timelineUnavailable => 'ระยะเวลาไม่สามารถใช้ได้';
	@override String get timelineEstimated => 'ค่าใช้จ่าย Playback';
	@override String get timelinePending => 'ค้นหา';
	@override String get timelineStale => 'แผนที่สามารถล่วงหน้าได้';
	@override String get unknownHub => 'ที่เก็บข้อมูลไม่รู้จัก';
	@override String get unknownError => 'ความผิดพลาดที่ไม่ทราบ';
	@override String channelNumber({required Object number}) => 'ช่อง ${number}';
	@override String get unknownChannel => 'ช่องที่ไม่รู้จัก';
	@override String get live => 'ชีวิต';
	@override String get premiereBadge => 'ใหม่';
	@override String get reloadGuide => 'คู่มืออัพโหลด';
	@override String get searchGuide => 'คู่มือการค้นหา';
	@override String get searchHint => 'ช่องค้นหาและโปรแกรม';
	@override String searchNoResults({required Object query}) => 'ไม่มีการแข่งขันสําหรับ "${query}"';
	@override String get channelsSection => 'ช่อง';
	@override String get programsSection => 'โปรแกรม';
	@override String get now => 'ตอนนี้';
	@override String get today => 'วันนี้';
	@override String get tomorrow => 'วันพรุ่งนี้';
	@override String get midnight => 'นมกลางคืน';
	@override String get overnight => 'คืน';
	@override String get morning => 'คู่เช้า';
	@override String get daytime => 'วัน';
	@override String get evening => 'คืน';
	@override String get lateNight => 'คืนช้า';
	@override String get whatsOn => 'สิ่งที่อยู่บน';
	@override String get watchChannel => 'ดูช่องทาง';
	@override String get favorites => 'รายการโปรด';
	@override String get reorderFavorites => 'โพสต์ที่ชื่นชอบ';
	@override String get noFavoriteChannels => 'ไม่มีช่องทางที่ชื่นชอบ';
	@override String get noFavoriteChannelsHint => 'แสดงช่องทั้งหมดแล้วกดช่องเพื่อเพิ่มช่องไปยังคนที่คุณชื่นชอบ';
	@override String get showAllChannels => 'แสดงช่องทั้งหมด';
	@override String get favoritesLoadFailed => 'ไม่สามารถโหลด Favorites ตรวจสอบการเชื่อมต่อของคุณและลองอีกครั้ง';
	@override String get favoritesUpdateFailed => 'ไม่สามารถปรับปรุง Favorites ตรวจสอบการเชื่อมต่อของคุณและลองอีกครั้ง';
	@override String get joinSession => 'เข้าร่วมประชุมในขั้นตอน';
	@override String watchFromStart({required Object minutes}) => 'ดูจากเริ่มต้น (${minutes} นาทีที่ผ่านมา)';
	@override String get watchLive => 'ดูสด';
	@override String get goToLive => 'ไปยัง ชีวิต';
	@override String get record => 'บันทึก';
	@override String get recordEpisode => 'ฉบับบันทึก';
	@override String get recordSeries => 'ซีรีส์บันทึก';
	@override String get recordOptions => 'ตัวเลือกการบันทึก';
	@override String get saveTo => 'การบันทึก';
	@override String get recordings => 'การบันทึก';
	@override String get scheduledRecordings => 'การวางแผน';
	@override String get recordingRules => 'กฎการบันทึก';
	@override String get noScheduledRecordings => 'ไม่มีอะไรที่วางแผนที่จะบันทึก';
	@override String get manageRecording => 'การจัดการการบันทึก';
	@override String get cancelRecording => 'ยกเลิกการบันทึก';
	@override String get cancelRecordingTitle => 'ปล่อยการบันทึกนี้';
	@override String cancelRecordingMessage({required Object title}) => '${title} จะไม่ได้รับการบันทึก';
	@override String get deleteRule => 'กฎการลบ';
	@override String get deleteRuleTitle => 'ลบกฎการบันทึก';
	@override String deleteRuleMessage({required Object title}) => 'ฉบับที่เกิดขึ้นในอนาคตของ ${title} จะไม่ได้บันทึก';
	@override String get recordingScheduled => 'การบันทึกที่วางแผน';
	@override String get alreadyScheduled => 'โปรแกรมนี้ได้รับการวางแผน';
	@override String get dvrAdminRequired => 'การตั้งค่า DVR ต้องมีบัญชี admin';
	@override String get recordingFailed => 'ไม่สามารถวางแผนการบันทึก';
	@override String get recordingTargetMissing => 'ไม่สามารถกําหนดการบันทึกห้องสมุด';
	@override String get recordNotAvailable => 'การบันทึกไม่สามารถใช้ได้สําหรับโปรแกรมนี้';
	@override String get recordingCancelled => 'การบันทึกยกเลิก';
	@override String get recordingRuleDeleted => 'กฎบันทึกลบ';
	@override String get processRecordingRules => 'การประเมินกฎใหม่';
	@override String get recordingInProgress => 'การบันทึกตอนนี้';
	@override String recordingsCount({required Object count}) => '${count} การวางแผน';
	@override String get editRule => 'กฎ Edit';
	@override String get editRuleAction => 'แก้ไข';
	@override String get recordingRuleUpdated => 'กฎการบันทึกปรับปรุง';
	@override String get guideReloadRequested => 'คู่มือฟื้นฟูที่ขอ';
	@override String get guideReloadFailed => 'ไม่สามารถทําความสะอาดคู่มือ';
	@override String get rulesProcessRequested => 'ข้อกําหนดการประเมินใหม่ที่ต้องการ';
	@override String get rulesProcessFailed => 'ไม่สามารถประเมินกฎการบันทึกใหม่ได้';
	@override String get recordShow => 'แสดงบันทึก';
	@override late final _Translations$liveTv$recordSettings$th recordSettings = _Translations$liveTv$recordSettings$th._(_root);
	@override String startingInMinutes({required Object minutes}) => 'เริ่มต้นใน ${minutes} นาที';
	@override String dayAtTime({required Object day, required Object time}) => '${day} ที่ ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} ข้อมูลการเล่นทีวีสดที่ไม่ได้รับการคืนเงิน';
	@override String get failedToStartChannel => 'ไม่สามารถเริ่มต้นช่องทางสด';
	@override String get failedToBuildStreamUrl => 'ไม่สามารถสร้าง URL Stream';
	@override String playbackStartFailed({required Object reason}) => 'ไม่สามารถเริ่มต้นช่อง: ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'ไม่สามารถเปลี่ยนช่อง: ${reason}';
}

// Path: collections
class _Translations$collections$th extends Translations$collections$en {
	_Translations$collections$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'คอลเลกชัน';
	@override String get collection => 'การจัดเก็บ';
	@override String get empty => 'การเก็บรวบรวมช็อตว่างเปล่า';
	@override String get deleteCollection => 'ลบเก็บ';
	@override String deleteConfirm({required Object title}) => 'ลบ "${title}"? นี้ไม่สามารถลบได้';
	@override String get deleted => 'การเก็บรวบรวมช็อตเด็ด';
	@override String get deleteFailed => 'ไม่สามารถลบการเก็บรวบรวม';
	@override String deleteFailedWithError({required Object error}) => 'ไม่ได้ลบการเก็บรวบรวมช็อตเด็ด: ${error}';
	@override String get selectCollection => 'เลือกชุด';
	@override String get collectionName => 'ชื่อการเก็บเกี่ยว';
	@override String get enterCollectionName => 'ระบุชื่อการเก็บรวบรวม';
	@override String get addedToCollection => 'เพิ่มเข้าสู่การเก็บเกี่ยว';
	@override String get errorAddingToCollection => 'ไม่สามารถเพิ่มเข้าสู่การเก็บเกี่ยว';
	@override String get created => 'การเก็บรวบรวม';
	@override String get removeFromCollection => 'การกําจัดจากการเก็บรวบรวม';
	@override String removeFromCollectionConfirm({required Object title}) => 'นำ “${title}” ออกจากคอลเลกชันนี้หรือไม่';
	@override String get removedFromCollection => 'การกําจัดจากการเก็บรวบรวม';
	@override String get removeFromCollectionFailed => 'ไม่สามารถถอดออกจากการเก็บรวบรวม';
	@override String removeFromCollectionError({required Object error}) => 'ความผิดพลาดในการลบจากการเก็บรวบรวม: ${error}';
	@override String get searchCollections => 'ค้นหาคอลเลกชัน';
}

// Path: playlists
class _Translations$playlists$th extends Translations$playlists$en {
	_Translations$playlists$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'เพลย์ลิสต์';
	@override String get playlist => 'เพลย์ลิสต์';
	@override String get noPlaylists => 'ไม่พบรายการเล่น';
	@override String get create => 'สร้าง Playlist';
	@override String get playlistName => 'ชื่อ Playlist';
	@override String get enterPlaylistName => 'ชื่อ Playlist';
	@override String get delete => 'ลบ Playlist';
	@override String get removeItem => 'ลบออกจากเพลย์ลิสต์';
	@override String get smartPlaylist => 'การเล่นสมาร์ท';
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(count,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} รายการ',
	);
	@override String get emptyPlaylist => 'รายการเล่นนี้ว่างเปล่า';
	@override String get deleteConfirm => 'ลบ Playlist';
	@override String deleteMessage({required Object name}) => 'คุณแน่ใจว่าคุณต้องการลบ "${name}"';
	@override String get created => 'Playlist สร้างขึ้น';
	@override String get deleted => 'Playlist ลบ';
	@override String get itemAdded => 'เพิ่มขึ้นใน Playlist';
	@override String get itemRemoved => 'ลบออกจาก Playlist';
	@override String get selectPlaylist => 'เลือก Playlist';
	@override String get searchPlaylists => 'ค้นหารายการเล่น';
	@override String get errorCreating => 'ไม่ได้สร้าง playlist';
	@override String get errorDeleting => 'ไม่สามารถลบ playlist';
	@override String get errorLoading => 'ไม่สามารถโหลดรายการเล่นได้';
	@override String get errorAdding => 'ไม่สามารถเพิ่มไปยัง playlist';
	@override String get errorReordering => 'ไม่สามารถปรับแต่งรายการ playlist';
	@override String get errorRemoving => 'ไม่สามารถลบออกจาก Playlist';
}

// Path: music
class _Translations$music$th extends Translations$music$en {
	_Translations$music$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'ไปยัง อัลบั้ม';
	@override String get goToArtist => 'ไปยังศิลปิน';
	@override String get instantMix => 'ผสมทันที';
	@override String get playNext => 'เล่นต่อไป';
	@override String get addToQueue => 'เพิ่มให้ Queue';
	@override String discNumber({required Object n}) => 'ดิสก์ ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ล้อ',
	);
	@override String get nowPlaying => 'ตอนนี้เล่น';
	@override String playingFrom({required Object title}) => 'เล่นจาก ${title}';
	@override String get queue => 'สิทธิ';
	@override String get clearQueue => 'ล้างคิว';
	@override String get lyrics => 'เนื้อเพลง';
	@override String get visualizer => 'วิดีโอ';
	@override String get visualizerProfileLoading => 'อ่าน track analysis ...';
	@override String get visualizerAmbientMotion => 'การเคลื่อนไหวสภาพแวดล้อม';
	@override String get visualizerPlexLoudness => 'Plex เสียง';
	@override String get visualizerPreviousPreset => 'สไตล์ภาพก่อนหน้า';
	@override String get visualizerNextPreset => 'สไตล์ภาพต่อไป';
	@override String get visualizerPresetAurora => 'ออโรารี';
	@override String get visualizerPresetBloom => 'บลู';
	@override String get visualizerPresetOrbitals => 'วงจร';
	@override String get visualizerPresetPrism => 'โพสต์';
	@override String get visualizerPresetTunnel => 'ทนเลอร์';
	@override String get visualizerPresetTrackMap => 'การติดตามแผนที่';
	@override String get noLyrics => 'ไม่มีข้อความที่มีอยู่';
	@override String get sleepTimer => 'เวลานอนหลับ';
	@override String get sleepTimerEndOfTrack => 'เสร็จสิ้นของเส้นทาง';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} นาที',
	);
	@override String get stopPlayback => 'ปิด Playback';
	@override String get previousTrack => 'แทร็กก่อนหน้า';
	@override String get nextTrack => 'แทร็กถัดไป';
	@override String get repeat => 'อัปเดต';
	@override String get repeatAll => 'อัปเดตทั้งหมด';
	@override String get repeatOne => 'อัปเดต 1';
	@override String get instantMixNoServer => 'ไม่มีเซิร์ฟเวอร์ที่มีอยู่สําหรับการผสมทันที';
	@override String get instantMixFailed => 'ไม่สามารถโหลดตัวผสมทันที';
	@override String get instantMixEmpty => 'การผสมทันทีกลับด้วยไม่มีเส้นทาง';
	@override String noAudioUrl({required Object track}) => 'ไม่มี URL เสียงที่มีอยู่สําหรับ ${track}';
	@override late final _Translations$music$discography$th discography = _Translations$music$discography$th._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$th extends Translations$watchTogether$en {
	_Translations$watchTogether$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'รับชมร่วมกัน';
	@override String get description => 'ดูเนื้อหาในซิงค์กับเพื่อนและครอบครัว';
	@override String get createRoom => 'สร้างห้องพัก';
	@override String get creatingRoom => 'ห้องสร้าง...';
	@override String get joinRoom => 'ห้องพัก';
	@override String get joiningRoom => 'ห้องเข้าร่วม';
	@override String get connecting => 'การเชื่อมต่อ...';
	@override String get relayPublic => 'ห้องพักใช้การสื่อสารสาธารณะ Open Watch Party';
	@override String relayCustom({required Object url}) => 'ห้องพักใช้โทรศัพท์ของคุณที่ ${url}';
	@override String get recentRooms => 'ห้องพักล่าสุด';
	@override String get roomActions => 'การกระทําห้อง';
	@override String get renameRoom => 'ห้องพัก';
	@override String get removeRoom => 'นำออก';
	@override String get enterRoomCode => 'ใส่รหัส 6 หมายเลขจากโฮสต์';
	@override String get roomCode => 'รหัสห้อง';
	@override String get paste => 'แพสติ้ง';
	@override String get noCodeInClipboard => 'แผ่นคลิปไม่ได้มีรหัสห้อง';
	@override String get copyCode => 'รหัสคัดลอก';
	@override String get codeCopied => 'รหัสห้องคัดลอก';
	@override String get shareInvite => 'คู่มือ';
	@override String get inviteCopied => 'ขออธิบายการคัดลอก เขียนลงในข้อความ';
	@override String inviteMessage({required Object code}) => 'เข้าร่วมห้องของ Watch Together ที่ PlezyNG: เปิดห้องของ Watch Together, เลือกห้องของ Join และเข้าสู่ระบบ ${code}.';
	@override String get openSessionControls => 'Open Watch ร่วมกันเซสชันควบคุม';
	@override String get reconnecting => 'การเชื่อมต่อ...';
	@override String get reconnectingDescription => 'การเชื่อมต่อถูกปิดแล้ว คุณจะเข้าสู่ห้องโดยอัตโนมัติ';
	@override String get connected => 'เชื่อมต่อ';
	@override String get disconnected => 'ปิดเชื่อมต่อ';
	@override String get youAreHost => 'คุณเป็นโฮสต์';
	@override String hostedBy({required Object name}) => 'โฮสติ้งโดย ${name}';
	@override String get hostControlsPlayback => 'โฮสต์ควบคุม playback';
	@override String get anyoneCanControl => 'ทุกคนสามารถควบคุม playback';
	@override String get roomLocked => 'ห้องล็อค';
	@override String get nowPlaying => 'ตอนนี้เล่น';
	@override String get nothingPlaying => 'ไม่มีอะไรเล่น';
	@override String get nothingPlayingHost => 'เล่นสิ่งบางอย่างจากห้องสมุดใด ๆ เพื่อแบ่งปันกับห้อง';
	@override String get nothingPlayingGuest => 'เมื่อโฮสต์เล่นสิ่งบางอย่างมันเปิดที่นี่';
	@override String get notShareable => 'วีดีโอนี้ไม่มีการเข้าถึงคอลัมน์ดังนั้นเพียงผู้ที่มีการเข้าถึงเซิร์ฟเวอร์เดียวกันเท่านั้นที่สามารถเล่นได้';
	@override String get searching => 'ค้นหาวิดีโอนี้ในห้องสมุดของคุณ ...';
	@override String get yourCopy => 'คูปองของคุณ';
	@override String get sharingYourCopy => 'คุณจะแบ่งปันสําเนาของคุณ';
	@override String playingOtherLength({required Object difference}) => 'เล่นสําเนาของคุณ, ${difference}';
	@override String get mismatchTitle => 'ความยาวของสําเนาของคุณแตกต่างกัน';
	@override String mismatchDescription({required Object difference}) => 'คูปองที่ใกล้ที่สุดของคุณคือ ${difference} จากวิดีโอในห้อง มันอาจเป็นตัดหรือรุ่นอื่น ๆ';
	@override String get playAnyway => 'เล่นอย่างไรก็ตาม';
	@override String get chooseAnotherCopy => 'เลือกสําเนาอื่น ๆ';
	@override String get dontPlay => 'อย่าเล่น';
	@override String get unavailableTitle => 'คุณไม่มีวิดีโอนี้';
	@override String get unavailableDescription => 'PlezyNG ไม่สามารถหาได้ในห้องสมุดของคุณ เลือกสําเนาด้วยตัวเองหรือค้นหาอีกครั้ง';
	@override String get chooseCopy => 'เลือกสําเนา';
	@override String get searchAgain => 'ค้นหาอีกครั้ง';
	@override String get noCandidates => 'ไม่มีสําเนาที่พบในห้องสมุดของคุณ';
	@override String get choiceFailed => 'ฉันไม่สามารถเล่นสําเนานี้สําหรับห้อง';
	@override String lengthLonger({required Object duration}) => '${duration} มากกว่า';
	@override String lengthShorter({required Object duration}) => '${duration} สั้น ๆ';
	@override String get lengthSame => 'ความยาวเดียวกัน';
	@override String get lengthUnknown => 'ความยาวไม่ทราบ';
	@override String get joinCurrentPlayback => 'เข้าร่วม Playback ปัจจุบัน';
	@override String get joinCurrentPlaybackDescription => 'กลับไปที่สิ่งที่โฮสต์กําลังมองหาในขณะนี้';
	@override String get stopMedia => 'ปิดวิดีโอสําหรับทุกคน';
	@override String get syncOffset => 'ซิงค์ Offset';
	@override String get syncOffsetDescription => 'เปลี่ยนวิดีโอของคุณถ้ามันทํางานด้านหน้าหรือหลังห้อง';
	@override String offsetHint({required Object difference}) => 'คูปองของคุณคือ ${difference} จากวิดีโอในห้อง';
	@override String applyDifference({required Object offset}) => 'ใช้ ${offset}';
	@override String get offsetMinusSecond => '1 ซ';
	@override String get offsetMinusTenth => '- 100 มิลลิเมตร';
	@override String get offsetPlusTenth => '+100 มิลลิเมตร';
	@override String get offsetPlusSecond => '+ 1 ซ';
	@override String get participants => 'ผู้เข้าร่วม';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ผู้เข้าร่วม',
	);
	@override String get hostBadge => 'โฮสต์';
	@override String nameYou({required Object name}) => '${name} (คุณ)';
	@override String get playerIdle => 'นี่คือ';
	@override String get playerLoading => 'โหลด';
	@override String get playerReady => 'เตรียม';
	@override String get playerBuffering => 'บูบ';
	@override String get matchSearching => 'ค้นหา';
	@override String get matchMatched => 'มีวิดีโอ';
	@override String get matchMismatched => 'ความยาวที่แตกต่างกัน';
	@override String get matchUnavailable => 'ไม่ได้มีวิดีโอ';
	@override String participantOffset({required Object offset}) => 'ตลับลูกปืน ${offset}';
	@override String get makeHost => 'ทําโฮสต์';
	@override String get makeHostQuestion => 'โฮสติ้ง';
	@override String makeHostConfirm({required Object name}) => '${name} จะควบคุมการเล่นและขับเคลื่อนการประชุมสําหรับทุกคน';
	@override String get transfer => 'การถ่ายโอน';
	@override String get removeParticipant => 'เอาจากห้องพัก';
	@override String removeParticipantQuestion({required Object name}) => 'ลบ ${name}?';
	@override String removeParticipantConfirm({required Object name}) => '${name} จะออกจากห้อง พวกเขาสามารถเข้าร่วมกับรหัสอีกครั้งถ้าคุณปิดห้อง';
	@override String get remove => 'นำออก';
	@override String get roomSettings => 'การตั้งค่าห้อง';
	@override String get letEveryoneControl => 'ให้ทุกคนควบคุม Playback';
	@override String get lockRoom => 'ห้องล็อค';
	@override String get lockRoomDescription => 'ไม่มีคนใหม่ที่สามารถเข้าร่วม';
	@override String get leaveRoom => 'ห้องพัก';
	@override String get leaveRoomQuestion => 'ห้องพัก';
	@override String get leaveRoomConfirm => 'คุณสามารถเข้าร่วมอีกครั้งด้วยรหัสห้อง';
	@override String get leave => 'ปล่อย';
	@override String get endRoom => 'ห้องที่สิ้นสุด';
	@override String get endRoomQuestion => 'ห้องพักสุดท้าย';
	@override String get endRoomConfirm => 'นี่คือจุดสิ้นสุดของห้องสําหรับทุกคน';
	@override String get end => 'เสร็จสิ้น';
	@override String get playBlockedTitle => 'Playback ไม่เริ่ม';
	@override String get playBlockedDescription => 'การเล่นกดเพื่อเริ่มดูกับห้อง';
	@override late final _Translations$watchTogether$notices$th notices = _Translations$watchTogether$notices$th._(_root);
	@override late final _Translations$watchTogether$ended$th ended = _Translations$watchTogether$ended$th._(_root);
	@override late final _Translations$watchTogether$errors$th errors = _Translations$watchTogether$errors$th._(_root);
	@override String untitledEpisode({required Object number}) => 'ฉบับที่ ${number}';
}

// Path: downloads
class _Translations$downloads$th extends Translations$downloads$en {
	_Translations$downloads$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'รายการดาวน์โหลด';
	@override String get manage => 'การจัดการ';
	@override String get tvShows => 'แสดงทีวี';
	@override String get movies => 'ภาพยนตร์';
	@override String get music => 'เพลง';
	@override String tracksQueued({required Object count}) => '${count} tracks queued สําหรับดาวน์โหลด';
	@override String get noDownloads => 'ไม่มีดาวน์โหลด';
	@override String get noDownloadsDescription => 'เนื้อหาที่ดาวน์โหลดจะปรากฏที่นี่สําหรับการดู offline';
	@override String get downloadNow => 'ดาวน์โหลด';
	@override String get deleteDownload => 'ดาวน์โหลด';
	@override String get retryDownload => 'ดาวน์โหลด';
	@override String get downloadQueued => 'ดาวน์โหลด Queued';
	@override String get downloadResumed => 'ดาวน์โหลดใหม่';
	@override String get serverErrorBitrate => 'ข้อผิดพลาดเซิร์ฟเวอร์: ไฟล์อาจเกินขีด จํากัด bitrate จากระยะไกล';
	@override String get storageFull => 'ดาวน์โหลดหยุดเพื่อปกป้องจัดเก็บที่อยู่ ฟรีพื้นที่บางอย่างหรือเลือกสถานที่ดาวน์โหลดอื่นแล้วรีด';
	@override String get storageUnavailable => 'ดาวน์โหลดหยุดเพราะการจัดเก็บที่พร้อมใช้งานไม่สามารถตรวจสอบได้ ตรวจสอบตําแหน่งดาวน์โหลดแล้วรีด';
	@override String episodesQueued({required Object count}) => '${count} episodes queued สําหรับดาวน์โหลด';
	@override String get downloadDeleted => 'ดาวน์โหลดลบ';
	@override String deleteConfirm({required Object title}) => 'ลบ "${title}" จากอุปกรณ์นี้?';
	@override String get deleteCollectionDownloads => 'ลบดาวน์โหลด';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => 'ลบไฟล์ที่ดาวน์โหลดทั้งหมดใน “${title}” ออกจากอุปกรณ์นี้หรือไม่';
	@override String get collectionDownloadsDeleted => 'ดาวน์โหลดลบ';
	@override String get cancelledDownloadTitle => 'ดาวน์โหลดยกเลิก';
	@override String get cancelledDownloadMessage => 'ดาวน์โหลดนี้ถูกยกเลิก สิ่งที่คุณต้องการทํา?';
	@override String get allEpisodesAlreadyDownloaded => 'ส่วนทั้งหมดที่ดาวน์โหลดแล้ว';
	@override String get resumeDownload => 'ดาวน์โหลด';
	@override String get cancelledDownload => 'ดาวน์โหลดยกเลิก';
	@override String syncingFile({required Object file, required Object status}) => '${file} (ซิงค์ ${status})';
	@override String downloadedFileClickToComplete({required Object file}) => 'ดาวน์โหลด ${file} - คลิกเพื่อเสร็จสิ้น';
	@override String get partialDownloadClickToComplete => 'ดาวน์โหลดส่วน - คลิกเพื่อเสร็จสิ้น';
	@override String get deleting => 'การลบ...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'ลบ ${title}... (${current} ของ ${total})';
	@override String get queuedTooltip => 'คุ้มกัน';
	@override String queuedFilesTooltip({required Object files}) => 'คู่มือ ${files}';
	@override String get downloadingTooltip => 'ดาวน์โหลด...';
	@override String downloadingFilesTooltip({required Object files}) => 'ดาวน์โหลด ${files}';
	@override String get noDownloadsTree => 'ไม่มีดาวน์โหลด';
	@override String get pauseAll => 'สอดคล้องทั้งหมด';
	@override String get resumeAll => 'ทบทวนทั้งหมด';
	@override String get retryAll => 'กลับทั้งหมด';
	@override String get retryFailed => 'ดาวน์โหลดที่ล้มเหลว';
	@override String get deleteAll => 'ลบทั้งหมด';
	@override String get selectVersion => 'เลือกรุ่น';
	@override String get allEpisodes => 'ทุกตอน';
	@override String get unwatchedOnly => 'เท่านั้นไม่สังเกต';
	@override String nextNUnwatched({required Object count}) => 'ถัดไป ${count} ไม่ตรวจสอบ';
	@override String get customAmount => 'จํานวนที่กําหนดเอง';
	@override String get customAmountAny => 'จํานวนที่กําหนดเอง (ทุกปี)';
	@override String get randomEpisodes => 'ฉากที่สุ่ม';
	@override String get includeSpecials => 'รวมพิเศษ';
	@override String get howManyEpisodes => 'ประวัติจํานวนมาก';
	@override String get invalidEpisodeCount => 'เขียนคํานวณส่วนที่ถูกต้อง';
	@override String get keepSynced => 'ป้องกันการสังเคราะห์';
	@override String get downloadOnce => 'ดาวน์โหลดครั้งเดียว';
	@override String keepNUnwatched({required Object count}) => 'เก็บ ${count} ไม่ตรวจสอบ';
	@override String get editSyncRule => 'กฎการปรับแต่ง';
	@override String get removeSyncRule => 'ปล่อยกฎการซิงค์';
	@override String removeSyncRuleConfirm({required Object title}) => 'หยุดการซิงค์ "${title}"? ฉบับที่ดาวน์โหลดจะถูกเก็บไว้';
	@override String removeListSyncRuleConfirm({required Object title}) => 'หยุดการซิงค์ "${title}"';
	@override String get deleteSyncRuleDownloads => 'นอกจากนี้ยังลบดาวน์โหลดที่เกี่ยวข้อง';
	@override String get deleteSyncRuleDownloadsDescription => 'ดาวน์โหลดที่ใช้ตามกฎการซิงค์หรือโปรไฟล์อื่น ๆ จะถูกเก็บไว้';
	@override String syncRuleCreated({required Object count}) => 'หลักการ Sync ที่สร้างขึ้น — รักษา ${count} ฉบับที่ไม่ได้รับการตรวจสอบ';
	@override String get syncRuleUpdated => 'หลักการ Sync ปรับปรุง';
	@override String get syncRuleRemoved => 'หลักการ Sync Removed';
	@override String get syncRuleAndDownloadsRemoved => 'หลักการ Sync และดาวน์โหลดที่เกี่ยวข้องลบ';
	@override String get syncRuleCleanupBusy => 'กฎการซิงค์ในขณะนี้มีการปรับปรุง ลองอีกครั้งในเวลาหนึ่ง';
	@override String get syncRuleCleanupUnavailable => 'ดาวน์โหลดที่เกี่ยวข้องไม่สามารถระบุได้อย่างปลอดภัย การเชื่อมต่อเซิร์ฟเวอร์อีกครั้งและลองอีกครั้งหรือลบกฎโดยไม่ต้องลบดาวน์โหลด';
	@override String syncedNewEpisodes({required Object count, required Object title}) => 'การซิงค์ ${count} ฉบับใหม่สําหรับ ${title}';
	@override String get syncNow => 'ซิงค์ตอนนี้';
	@override String get downloadsUpToDate => 'ดาวน์โหลดถึงปัจจุบัน';
	@override String syncComplete({required Object queued, required Object removed}) => 'ซิงค์เต็ม · ${queued} queued, ${removed} 删除';
	@override String get activeSyncRules => 'หลักการ Sync';
	@override String get reviewOrphanFiles => 'รีวิวดาวน์โหลด orphaned';
	@override String get orphanReviewTitle => 'รีวิวดาวน์โหลด orphaned';
	@override String get orphanReviewDescription => 'ไฟล์ที่ติดฉลากเหล่านี้อยู่ในโฟลเดอร์ดาวน์โหลดที่จัดการโดยแอปที่กําหนดเองของ PlezyNG และไม่มีบันทึกดาวน์โหลดหรืองานที่ใช้งานได้ คลิกที่รายการก่อนที่จะลบ';
	@override String orphanReviewCount({required Object count, required Object size}) => '${count} ไฟล์ · ${size}';
	@override String orphanDeleteFiles({required Object count}) => 'ลบไฟล์ ${count}';
	@override String get orphanCleanupNone => 'ไม่พบไฟล์ดาวน์โหลด';
	@override String get orphanCleanupFailed => 'PlezyNG ไม่สามารถสแกนได้อย่างปลอดภัยโฟลเดอร์การดาวน์โหลดที่จัดการ ไม่ได้ลบไฟล์ใด ๆ';
	@override String get orphanCleanupChanged => 'รายการดาวน์โหลดได้เปลี่ยนแปลงในระหว่างการตรวจสอบ ตรวจสอบไฟล์อีกครั้งก่อนทําความสะอาด';
	@override String orphanCleanupComplete({required Object count, required Object size}) => 'โซลูชัน ${count} โซลูชัน · ${size} ฟรี';
	@override String get noSyncRules => 'ไม่มีกฎ sync';
	@override String get manageSyncRule => 'การจัดการ Sync';
	@override String get editEpisodeCount => 'หมายเลขเหตุ';
	@override String get editSyncFilter => 'ตัวกรอง Sync';
	@override String get syncAllItems => 'การซิงค์รายการทั้งหมด';
	@override String get syncUnwatchedItems => 'การซิงค์รายการที่ไม่ได้ตรวจสอบ';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'เซิร์ฟเวอร์: ${server} • ${status}';
	@override String get syncRuleAvailable => 'มี';
	@override String get syncRuleOffline => 'ออฟไลน์';
	@override String get syncRuleSignInRequired => 'เขียนลงในที่ต้องการ';
	@override String get syncRuleAccessDenied => 'การเข้าถึงที่ปฏิเสธ';
	@override String get syncRuleNotAvailableForProfile => 'ไม่สามารถใช้ได้สําหรับโปรไฟล์ปัจจุบัน';
	@override String get syncRuleUnknownServer => 'เซิร์ฟเวอร์ที่ไม่รู้จัก';
	@override String get syncRuleListCreated => 'กฎ Sync ที่สร้างขึ้น';
	@override late final _Translations$downloads$backgroundWarning$th backgroundWarning = _Translations$downloads$backgroundWarning$th._(_root);
	@override String get options => 'ดาวน์โหลดตัวเลือก';
	@override late final _Translations$downloads$groupings$th groupings = _Translations$downloads$groupings$th._(_root);
	@override String get unknownLibrary => 'บีบอิสระที่ไม่รู้จัก';
	@override String get unknownShow => 'แสดงที่ไม่รู้จัก';
	@override String get unknownSeason => 'ฤดูกาลที่ไม่รู้จัก';
	@override String get unknownAlbum => 'อัลบั้มที่ไม่รู้จัก';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} เสร็จสิ้น';
	@override String storageUsed({required Object size}) => 'การจัดเก็บข้อมูลที่ใช้: ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ดาวน์โหลด',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} แสดง',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ภาพยนตร์',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} อัลบั้ม',
	);
	@override String get errorFileNotFound => 'ไฟล์ที่ไม่ได้พบ (404)';
	@override String get errorDownloadNotAllowed => 'ดาวน์โหลดที่ไม่ได้รับอนุญาตโดยเซิร์ฟเวอร์ (403)';
	@override String get errorDownloadFailed => 'ดาวน์โหลดล้มเหลว';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'ดาวน์โหลดที่ผิดพลาด: ${reason}';
	@override String get convertingOnServer => 'การแปลงไปยังเซิร์ฟเวอร์';
	@override String convertingOnServerPercent({required Object percent}) => 'การแปลงไปยังเซิร์ฟเวอร์ · ${percent}%';
	@override String errorHttpStatus({required Object status}) => 'ดาวน์โหลดที่ผิดพลาด (HTTP ${status})';
	@override String errorPostProcessing({required Object reason}) => 'การประมวลผลหลังล้มเหลว: ${reason}';
	@override String get reasonFileNotSaved => 'ไฟล์ไม่สามารถบันทึกไว้บนอุปกรณ์นี้';
	@override String get reasonCannotResume => 'การดาวน์โหลดส่วนไม่สามารถยกเลิกได้';
	@override String get reasonDeviceStorageFull => 'อุปกรณ์นี้ไม่ได้รับการจัดเก็บ';
	@override String get notificationDownloading => 'ดาวน์โหลด...';
	@override String get notificationComplete => 'ดาวน์โหลดเต็มรูปแบบ';
	@override String get notificationPaused => 'ดาวน์โหลดหยุด';
}

// Path: shaders
class _Translations$shaders$th extends Translations$shaders$en {
	_Translations$shaders$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'ตุ๊กตา';
	@override String get noShaderDescription => 'ไม่มีการปรับปรุงวิดีโอ';
	@override String get nvscalerDescription => 'การสแกนภาพ NVIDIA สําหรับวิดีโอที่ชัดเจน';
	@override String get artcnnVariantNeutral => 'สภาพกลาง';
	@override String get artcnnVariantDenoise => 'ละลาย';
	@override String get artcnnVariantDenoiseSharpen => 'สะดวก + Sharpen';
	@override String get qualityFast => 'ความเร็ว';
	@override String get qualityHQ => 'คุณภาพสูง';
	@override String get mode => 'โหมด';
	@override String get importShader => 'การนําเข้า Shader';
	@override String get customShaderDescription => 'แชดร์ GLSL แบบกําหนดเอง';
	@override String get shaderImported => 'Shader ที่นําเข้า';
	@override String get shaderImportFailed => 'ไม่สามารถนําเข้า Shader';
	@override String get deleteShader => 'ลบ Shader';
	@override String deleteShaderConfirm({required Object name}) => 'ลบ “${name}”';
}

// Path: companionRemote
class _Translations$companionRemote$th extends Translations$companionRemote$en {
	_Translations$companionRemote$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'รีโมตเสริม';
	@override String connectedTo({required Object name}) => 'เชื่อมต่อ ${name}';
	@override String get unknownDevice => 'อุปกรณ์ที่ไม่รู้จัก';
	@override late final _Translations$companionRemote$session$th session = _Translations$companionRemote$session$th._(_root);
	@override late final _Translations$companionRemote$pairing$th pairing = _Translations$companionRemote$pairing$th._(_root);
	@override late final _Translations$companionRemote$remote$th remote = _Translations$companionRemote$remote$th._(_root);
	@override late final _Translations$companionRemote$errors$th errors = _Translations$companionRemote$errors$th._(_root);
	@override String get closedBeforeAuth => 'การเชื่อมต่อปิดก่อนการรับรอง';
}

// Path: videoSettings
class _Translations$videoSettings$th extends Translations$videoSettings$en {
	_Translations$videoSettings$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'ความเร็ว Playback';
	@override String get normalSpeed => 'หลักสูตร';
	@override String sleepTimerActive({required Object duration}) => 'การใช้งาน (${duration})';
	@override String get zoom => 'โซม';
	@override String get sleepTimer => 'เวลานอน';
	@override String get audioSync => 'โซฟิกเสียง';
	@override String get subtitleSync => 'ซอฟต์แวร์ Sync';
	@override String get hdr => 'HDR';
	@override String get hdrUnsupported => 'HDR ไม่สามารถใช้ได้ที่นี่ - เครื่องเขียนโต๊ะหรือวิดีโอนี้ไม่สามารถนํามาใช้ได้';
	@override String get hdrToneMapping => 'การ์ตูน HDR';
	@override String get hdrToneMappingCompositor => 'คอมโพสิต';
	@override String get hdrToneMappingCompositorDescription => 'ผ่านข้อมูล HDR ของแหล่งข้อมูลและปล่อยให้เครื่องเขียนตารางแผนที่';
	@override String get hdrToneMappingPlayer => 'ตัวเล่น';
	@override String get hdrToneMappingPlayerDescription => 'แผนที่เพื่อความสว่างสูงสุดของจอแสดงผลในผู้เล่นแล้วบอกนักแสดงผล';
	@override String get hdrToneMappingFailed => 'ไม่สามารถเปลี่ยนการ์ดเสียง HDR - โหมดก่อนหน้านี้ยังคงใช้งานได้';
	@override String get audioOutput => 'การออกเสียง';
	@override String get performanceOverlay => 'ประสิทธิภาพ Overlay';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'รอบ';
	@override String get audioOutputSpatial => 'อากาศเสียง';
	@override String get audioOutputStereo => 'สเตียรอยด์';
	@override String get audioEqualizer => 'ออนไลน์ Equalizer';
	@override String get audioEqualizerDescription => 'การปรับตัวห้าแถบความถี่สําหรับอุปกรณ์นี้ สามารถใช้ได้บน mpv ใช้งานได้ EQ decodes เสียงและปิดผนึก';
	@override String get audioEqualizerFlat => 'ใบไม้ผลิ';
	@override String get audioEqualizerActive => 'คู่มือ';
	@override String get audioEqualizerSaveFailed => 'ฉันไม่สามารถบันทึกการตั้งค่าของ Audio Equalizer';
	@override String get backgroundVideoAudio => 'วิดีโอเสียงพื้นหลัง';
	@override String get backgroundVideoAudioDescription => 'ปล่อยให้วิดีโอเสียงเล่นเมื่อคุณออกจากผู้เล่น ภาพถูกซ่อนจนกว่าคุณจะกลับมา Android ใช้การแจ้งเตือนการเล่นสื่อ';
	@override String get audioNormalization => 'การปรับเสียง';
	@override String get audioNormalizationDisablesPassthrough => 'ลบเสียงไปยัง PCM; passthrough จะปิดในขณะที่นี้จะ';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$th extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get color => 'สี';
	@override String get performance => 'การแสดงผล';
	@override String get buffer => 'บูฟเฟอร์';
	@override String get app => 'แอป';
	@override String get decoder => 'การตกแต่ง';
	@override String get rawDecoder => 'วัตถุประสงค์';
	@override String get tunneling => 'ทนเลอร์';
	@override String get passthrough => 'โพสต์';
	@override String get aspect => 'ความเห็น';
	@override String get rotation => 'การหมุน';
	@override String get dvSource => 'หลักฐาน';
	@override String get dvPath => 'สองเส้นทาง';
	@override String get dvRouteDecoder => 'ตัวถอดรหัส Dolby Vision';
	@override String get dvRouteDecoderP81 => 'ตัวถอดรหัส Dolby Vision (P7→8.1)';
	@override String get dvRouteBaseLayer => 'ฐานชั้น';
	@override String get dvRouteBaseLayerHdr10 => 'HDR10 ชั้นฐาน';
	@override String get dvRouteBaseLayerHlg => 'HLG ฐานชั้น';
	@override String get dvRouteBaseLayerSdr => 'SDR ฐานชั้น';
	@override String get dvRouteReshaped => 'RPU แก้ไข (gpu-next)';
	@override String get p7Conversion => 'การแปลง P7';
	@override String get sampleRate => 'ตัวอย่างอัตรา';
	@override String get pixelFormat => 'พิกเซล Fmt';
	@override String get hwFormat => 'มณฑลสหรัฐอเมริกา';
	@override String get matrix => 'มะตริก';
	@override String get primaries => 'หลัก';
	@override String get transfer => 'การถ่ายโอน';
	@override String get renderFps => 'ฟิล์ม';
	@override String get displayFps => 'แสดง FPS';
	@override String get avSync => 'A / V Sync';
	@override String get dropped => 'ละลาย';
	@override String get dvRpus => 'DV RPUs';
	@override String get dvRpuAverage => 'DV RPU AVG';
	@override String get dvSampleAverage => 'DV ตัวอย่าง Avg';
	@override String get maxLuma => 'แม็กซ์ Luma';
	@override String get minLuma => 'มิน Luma';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Cache ใช้';
	@override String get cacheLimit => 'หมายเลขรุ่น: Cache Limit';
	@override String get speed => 'ความเร็ว';
	@override String get player => 'ตัวเล่น';
	@override String get playMethod => 'วิธีการเล่น';
	@override String get memory => 'ความจํา';
	@override String get uiFps => 'ภาษาไทย';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Android HW';
	@override String get decoderNvidiaHw => 'NVIDIA HW';
	@override String get decoderQualcommHw => 'คอลัมคัม HW';
	@override String get decoderMediatekHw => 'โมเดียม HW';
	@override String get decoderExynosHw => 'แอพลิเคชัน HW';
	@override String get decoderSoftware => 'ซอฟต์แวร์';
	@override String get decoderHardware => 'ฮาร์ดแวร์';
	@override String get tunnelingActive => 'การใช้งาน';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted} (${failures} ไม่สําเร็จ)';
}

// Path: externalPlayer
class _Translations$externalPlayer$th extends Translations$externalPlayer$en {
	_Translations$externalPlayer$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'ผู้เล่นภายนอก';
	@override String get useExternalPlayer => 'ใช้ผู้เล่นภายนอก';
	@override String get useExternalPlayerDescription => 'เปิดวิดีโอในแอปอื่น ๆ';
	@override String get selectPlayer => 'เลือกผู้เล่น';
	@override String get customPlayers => 'ผู้เล่นที่กําหนดเอง';
	@override String get systemDefault => 'ระบบที่กําหนดเอง';
	@override String get addCustomPlayer => 'เพิ่มผู้เล่นที่กําหนดเอง';
	@override String get playerName => 'ชื่อผู้เล่น';
	@override String get playerNameHint => 'ผู้เล่นของเรา';
	@override String get playerCommand => 'คอมเมนต์';
	@override String get playerPackage => 'ชื่อแพคเกจ';
	@override String get playerUrlScheme => 'แผนที่ URL';
	@override String get off => 'ปิด';
	@override String get launchFailed => 'ไม่สามารถเปิดผู้เล่นภายนอกได้';
	@override String appNotInstalled({required Object name}) => '${name} ไม่ติดตั้ง';
	@override String get playInExternalPlayer => 'เล่นในผู้เล่นภายนอก';
}

// Path: metadataEdit
class _Translations$metadataEdit$th extends Translations$metadataEdit$en {
	_Translations$metadataEdit$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'แก้ไข';
	@override String get screenTitle => 'การแก้ไข Metadata';
	@override String get basicInfo => 'ข้อมูลพื้นฐาน';
	@override String get artwork => 'งานศิลปะ';
	@override String get advancedSettings => 'การตั้งค่าขั้นสูง';
	@override String get title => 'ชื่อเรื่อง';
	@override String get sortTitle => 'ชื่อที่แตกต่างกัน';
	@override String get originalTitle => 'ชื่อเดิม';
	@override String get releaseDate => 'วันที่ปล่อย';
	@override String get contentRating => 'ระดับเนื้อหา';
	@override String get studio => 'สตูดิโอ';
	@override String get tagline => 'คำโปรย';
	@override String get summary => 'คําอธิบาย';
	@override String get poster => 'โพสต์';
	@override String get background => 'ลักษณะ';
	@override String get logo => 'โลโก้';
	@override String get squareArt => 'พื้นที่ศิลปะ';
	@override String get selectPoster => 'เลือกโพสต์';
	@override String get selectBackground => 'เลือกพื้นหลัง';
	@override String get selectLogo => 'เลือกโลโก้';
	@override String get selectSquareArt => 'เลือก Square Art';
	@override String get fromUrl => 'จาก URL';
	@override String get uploadFile => 'ดาวน์โหลดไฟล์';
	@override String get enterImageUrl => 'หมายเลข URL';
	@override String get imageUrl => 'ภาพ URL';
	@override String get metadataUpdated => 'ข้อมูลอัปเดต';
	@override String get metadataUpdateFailed => 'ไม่สามารถปรับปรุงข้อมูล metadata';
	@override String get artworkUpdated => 'อัพเดทศิลปะ';
	@override String get artworkUpdateFailed => 'ไม่สามารถปรับปรุงงานศิลปะได้';
	@override String get noArtworkAvailable => 'ไม่มีงานศิลปะ';
	@override String artworkOption({required Object index}) => 'ตัวเลือกงานศิลปะ ${index}';
	@override String selectedArtworkOption({required Object index}) => 'ตัวเลือกงานศิลปะ ${index}, เลือก';
	@override String get notSet => 'ไม่ตั้งค่า';
	@override String get libraryDefault => 'บีบอิสระ';
	@override String get accountDefault => 'บัญชีที่ผิดพลาด';
	@override String get seriesDefault => 'ซีรี่ส์ที่กําหนดเอง';
	@override String get episodeSorting => 'ประเภท';
	@override String get oldestFirst => 'เก่าที่สุดครั้งแรก';
	@override String get newestFirst => 'ใหม่แรก';
	@override String get keep => 'ปกติ';
	@override String get allEpisodes => 'ทุกตอน';
	@override String latestEpisodes({required Object count}) => '${count} ครั้งที่เข้าดูล่าสุด';
	@override String get latestEpisode => 'ประวัติล่าสุด';
	@override String episodesAddedPastDays({required Object count}) => 'Episodes ที่เพิ่มใน ${count} วันที่ผ่านมา';
	@override String get deleteAfterPlaying => 'ลบ Episodes หลังจากเล่น';
	@override String get never => 'ไม่เคย';
	@override String get afterADay => 'หลังจากหนึ่งวัน';
	@override String get afterAWeek => 'หลังจากหนึ่งสัปดาห์';
	@override String get afterAMonth => 'หลังจากหนึ่งเดือน';
	@override String get onNextRefresh => 'ต่อไปนี้ทําความสะอาด';
	@override String get seasons => 'ฤดูกาล';
	@override String get show => 'แสดง';
	@override String get hide => 'ซ่อน';
	@override String get episodeOrdering => 'การสั่งซื้อ';
	@override String get tmdbAiring => 'ฐานข้อมูลของภาพยนตร์ (Aired)';
	@override String get tvdbAiring => 'TheTVDB (ระบายอากาศ)';
	@override String get tvdbAbsolute => 'TheTVDB (อัลลอฮอล์)';
	@override String get metadataLanguage => 'ภาษา Metadata';
	@override String get useOriginalTitle => 'ใช้ชื่อเดิม';
	@override String get preferredAudioLanguage => 'ภาษาเสียงที่ชื่นชอบ';
	@override String get preferredSubtitleLanguage => 'ภาษาที่ชื่นชอบ Subtitle';
	@override String get subtitleMode => 'โหมด Subtitle ตัวเลือกอัตโนมัติ';
	@override String get manuallySelected => 'เลือกด้วยตนเอง';
	@override String get shownWithForeignAudio => 'แสดงด้วยเสียงต่างประเทศ';
	@override String get alwaysEnabled => 'ปัจจุบันเปิดใช้งาน';
	@override String get tags => 'แท็ก';
	@override String get addTag => 'เพิ่มแท็ก';
	@override String get genre => 'ประเภท';
	@override String get director => 'ผู้กำกับ';
	@override String get writer => 'ผู้เขียน';
	@override String get producer => 'ผู้ผลิต';
	@override String get country => 'ประเทศ';
	@override String get collection => 'การจัดเก็บ';
	@override String get label => 'แท็ก';
	@override String get quickTag => 'Tag อัตรา...';
}

// Path: matchScreen
class _Translations$matchScreen$th extends Translations$matchScreen$en {
	_Translations$matchScreen$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get match => 'การแข่งขัน';
	@override String get fixMatch => 'ปรับการแข่งขัน';
	@override String get unmatch => 'การแข่งขัน';
	@override String get unmatchConfirm => 'ลบเกมนี้? Plex รักษามันเป็นไม่แข่งขันจนถึงเสร็จสิ้น';
	@override String get unmatchSuccess => 'รายการที่ไม่สมบูรณ์';
	@override String get unmatchFailed => 'ข้อผิดพลาดในการไม่เข้าถึงรายการ';
	@override String get matchApplied => 'การแข่งขันใช้';
	@override String get matchFailed => 'ไม่สามารถใช้การแข่งขัน';
	@override String get titleHint => 'ชื่อเรื่อง';
	@override String get yearHint => 'ปี';
	@override String get search => 'ค้นหา';
	@override String get noMatchesFound => 'ไม่พบการแข่งขัน';
}

// Path: serverTasks
class _Translations$serverTasks$th extends Translations$serverTasks$en {
	_Translations$serverTasks$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'งานเซิร์ฟเวอร์';
	@override String get failedToLoad => 'ไม่สามารถโหลดงานได้';
	@override String get noTasks => 'ไม่มีงานที่ทํางาน';
}

// Path: trakt
class _Translations$trakt$th extends Translations$trakt$en {
	_Translations$trakt$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'เชื่อมต่อ';
	@override String connectedAs({required Object username}) => 'เชื่อมต่อที่ @${username}';
	@override String get disconnectConfirm => 'ปิดการเชื่อมต่อบัญชี Trakt';
	@override String get disconnectConfirmBody => 'PlezyNG จะหยุดส่งกิจกรรมไปยัง Trakt. คุณสามารถเชื่อมต่อใหม่ได้ตลอดเวลา';
	@override String get scrobble => 'ระยะเวลาจริง scrobbling';
	@override String get scrobbleDescription => 'ส่งการเล่นหยุดและหยุดกิจกรรมไปยัง Trakt ในระหว่างการเล่น';
	@override String get watchedSync => 'สภาพที่สังเกต';
	@override String get watchedSyncDescription => 'เมื่อคุณทําเครื่องหมายรายการตามที่ดูใน PlezyNG พวกเขาจะทําเครื่องหมายตามที่ดูใน Trakt';
}

// Path: seerr
class _Translations$seerr$th extends Translations$seerr$en {
	_Translations$seerr$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'เชื่อมต่อ Seerr';
	@override String get serverUrl => 'URL ของเซิร์ฟเวอร์';
	@override String get serverUrlHelper => 'ที่อยู่ของตัวอย่าง Seerr ของคุณ';
	@override String get checkServer => 'เสร็จสิ้น';
	@override String get signInWithJellyfin => 'ลงทะเบียนกับ Jellyfin';
	@override String get signInWithEmby => 'ลงทะเบียนกับ Emby';
	@override String get signInWithLocal => 'ใช้บัญชีท้องถิ่น';
	@override String get email => 'อีเมล';
	@override String get noSignInMethods => 'ตัวอย่าง Seerr นี้ไม่ให้การลงชื่อเข้าใช้วิธีการ PlezyNG สนับสนุน';
	@override String get instance => 'สัปดาห์';
	@override String get disconnectConfirm => 'ปิดเชื่อมต่อ Seerr';
	@override String get disconnectConfirmBody => 'PlezyNG จะลืมตัวอย่าง Seerr นี้ ติดต่ออีกครั้งตลอดเวลา';
	@override String get request => 'คําขอ';
	@override String get request4k => 'คําขอใน 4K';
	@override String get seasons => 'ฤดูกาล';
	@override String get allSeasons => 'ทุกฤดูกาล';
	@override String get advancedOptions => 'ขั้นสูง';
	@override String get destinationServer => 'เซิร์ฟเวอร์ปลายทาง';
	@override String get qualityProfile => 'คุณภาพโปรไฟล์';
	@override String get rootFolder => 'รูตาราง';
	@override String get languageProfile => 'โปรไฟล์ภาษา';
	@override String get tags => 'แท็ก';
	@override String get noTags => 'ไม่มีแท็ก';
	@override String defaultOption({required Object name}) => '${name} (เริ่มต้น)';
	@override String get animeNote => 'ชุดนี้เป็น anime';
	@override String get requestSubmitted => 'คําขอที่ส่ง';
	@override String requestFailed({required Object error}) => 'คําขอที่ผิดพลาด: ${error}';
	@override String get requestsLoadFailed => 'ไม่สามารถโหลดตัวเลือกการร้องขอ';
	@override String get nothingToRequest => 'ทุกอย่างที่มีอยู่หรือขอ';
	@override String get statusAvailable => 'มี';
	@override String get statusPartiallyAvailable => 'มีส่วนหนึ่ง';
	@override String get statusRequested => 'คําขอ';
	@override String get statusProcessing => 'การประมวลผล';
	@override String get statusBlocklisted => 'บล็อก';
	@override String couldNotReach({required Object url, required Object error}) => 'ไม่สามารถเข้าถึง ${url}: ${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => 'ไม่มีกรณี Seerr ที่ ${url} (HTTP ${status})';
	@override String get behindAuthProxy => 'โพคซีกลับที่ได้รับการรับรอง (SSO หรือ HTTP auth) ที่ตอบแทน Seerr PlezyNG ไม่สามารถลงทะเบียนผ่านมันได้: ให้เส้นทาง /api/v1 ของ Seerr ผ่านโพคซีสําหรับแอปนี้หรือใช้ที่อยู่ที่เข้าถึง Seerr โดยตรง';
	@override String get invalidUrl => 'ใส่ที่อยู่อีเมลเซิร์ฟเวอร์เช่น https://seerr.example.com';
	@override String get quickConnectUnsupported => 'ตัวอย่าง Seerr นี้ไม่สนับสนุน Quick Connect. มันต้องการ Seerr 3.4 หรือใหม่กว่า';
	@override String get notInitialized => 'ตัวอย่างนี้ Seerr ไม่ได้เสร็จสิ้นการตั้งค่าครั้งแรก';
	@override String get noPlexTokenForReauth => 'No Plex token มีการลงทะเบียนอีกครั้ง';
	@override String get noStoredCredentials => 'ไม่มีใบรับรองที่เก็บไว้พร้อมที่จะลงทะเบียนอีกครั้ง';
	@override String get signInRejected => 'การลงทะเบียนถูกปฏิเสธ';
	@override String get noSessionCookie => 'Seerr ไม่ได้ปล่อยคุกกี้การประชุม';
	@override String get freshCookieRejected => 'Seerr ยกเลิกคุกกี้เซสชั่นใหม่';
	@override String get noUserInformation => 'Seerr ไม่ได้คืนข้อมูลผู้ใช้';
	@override String get sessionRejectedAfterReauth => 'การประชุมถูกปฏิเสธหลังจากการลงทะเบียนอีกครั้ง';
	@override String get permissionDenied => 'Seerr ไม่ยอมรับการกระทํานี้: บัญชีของคุณไม่ได้รับอนุญาตที่ต้องการ';
	@override String get permissionRevoked => 'คุณไม่สามารถร้องขอได้อีกต่อไป';
}

// Path: services
class _Translations$services$th extends Translations$services$en {
	_Translations$services$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'บริการ';
	@override String get hubSubtitle => 'Sync ดูการพัฒนาและขอชื่อใหม่';
	@override String get integrations => 'การรวมกัน';
	@override String get notConnected => 'ไม่เชื่อมต่อ';
	@override String connectedAs({required Object username}) => 'เชื่อมต่อที่ @${username}';
	@override String get scrobble => 'ติดตามขั้นตอนโดยอัตโนมัติ';
	@override String get scrobbleDescription => 'ปรับปรุงรายการของคุณเมื่อคุณเสร็จสิ้นการจัดงานหรือภาพยนตร์';
	@override String disconnectConfirm({required Object service}) => 'ปิดการเชื่อมต่อ ${service}';
	@override String disconnectConfirmBody({required Object service}) => 'PlezyNG จะหยุดการอัพเดท ${service}. ติดต่ออีกครั้งตลอดเวลา';
	@override String connectFailed({required Object service}) => 'ฉันไม่สามารถเชื่อมต่อกับ ${service}. ลองอีกครั้ง';
	@override late final _Translations$services$names$th names = _Translations$services$names$th._(_root);
	@override late final _Translations$services$simklReconnect$th simklReconnect = _Translations$services$simklReconnect$th._(_root);
	@override late final _Translations$services$deviceCode$th deviceCode = _Translations$services$deviceCode$th._(_root);
	@override late final _Translations$services$oauthProxy$th oauthProxy = _Translations$services$oauthProxy$th._(_root);
	@override late final _Translations$services$pendingAuth$th pendingAuth = _Translations$services$pendingAuth$th._(_root);
	@override late final _Translations$services$libraryFilter$th libraryFilter = _Translations$services$libraryFilter$th._(_root);
}

// Path: addServer
class _Translations$addServer$th extends Translations$addServer$en {
	_Translations$addServer$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => 'เพิ่มเซิร์ฟเวอร์ ${product}';
	@override String get serverUrls => 'URL ของเซิร์ฟเวอร์';
	@override String get serverUrlsHelper => 'URL จํานวนมากที่ได้รับอนุญาตแยกโดย commas';
	@override String get findServer => 'ค้นหาเซิร์ฟเวอร์';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'ค้นหาเซิร์ฟเวอร์ท้องถิ่น ${product} ...';
	@override String localMediaBrowserServers({required Object product}) => 'เซิร์ฟเวอร์ท้องถิ่น ${product}';
	@override String get username => 'ชื่อผู้ใช้';
	@override String get password => 'คู่มือ';
	@override String get signIn => 'เข้าสู่ระบบ';
	@override String get change => 'การเปลี่ยนแปลง';
	@override String get required => 'ความต้องการ';
	@override String couldNotReachServer({required Object error}) => 'ไม่สามารถเข้าถึงเซิร์ฟเวอร์: ${error}';
	@override String signInFailed({required Object error}) => 'การลงทะเบียนที่ผิดพลาด: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect ความล้มเหลว: ${error}';
	@override String get addPlexTitle => 'ลงทะเบียนกับ Plex';
	@override String get pinExpired => 'PIN หมดอายุก่อนลงชื่อเข้าสู่ระบบ โปรดลองอีกครั้ง';
	@override String failedToRegisterAccount({required Object error}) => 'บัญชีที่ไม่ได้ลงทะเบียน: ${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => 'ใส่ URL ของเซิร์ฟเวอร์ ${product}';
	@override String get addConnectionTitle => 'เพิ่มการเชื่อมต่อ';
	@override String addConnectionTitleScoped({required Object name}) => 'เพิ่มไปยัง ${name}';
	@override String get signInWithPlexCard => 'ลงทะเบียนกับ Plex';
	@override String get signInWithPlexCardSubtitle => 'ปรับรองอุปกรณ์นี้ เซิร์ฟเวอร์ที่แบ่งปันจะเพิ่ม';
	@override String get signInWithPlexCardSubtitleScoped => 'รับอนุญาตให้มีบัญชี Plex ผู้ใช้บ้านกลายเป็นโปรไฟล์';
	@override String connectToMediaBrowserCard({required Object product}) => 'ติดต่อ ${product}';
	@override String get connectToMediaBrowserCardSubtitle => 'ใส่ URL, ชื่อผู้ใช้และรหัสผ่านเซิร์ฟเวอร์ของคุณ';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => 'ลงชื่อเข้าสู่เซิร์ฟเวอร์ ${product}. เชื่อมต่อกับ ${name}.';
	@override String get borrowFromAnotherProfile => 'โอกาสจากโปรไฟล์อื่น ๆ';
	@override String get borrowFromAnotherProfileSubtitle => 'ใช้การเชื่อมต่อของโปรไฟล์อื่น ๆ โปรไฟล์ที่ปกป้องด้วย PIN ต้องใช้ PIN';
	@override String get invalidCredentials => 'ชื่อผู้ใช้หรือรหัสผ่านที่ไม่ถูกต้อง';
	@override String get authResponseNotJson => 'คําตอบการรับรองไม่ได้รับการรับรอง JSON';
	@override String get authResponseIncomplete => 'การตอบสนองการลงชื่อเข้าจากเซิร์ฟเวอร์ไม่สมบูรณ์';
	@override String get quickConnectRejected => 'Quick Connect ได้รับการปฏิเสธโดยเซิร์ฟเวอร์';
	@override String get quickConnectNotJson => 'คําตอบ Quick Connect ไม่ถูกต้อง JSON';
	@override String get quickConnectMissingFields => 'คําตอบ Quick Connect ไม่มีรหัสหรือความลับ';
	@override String get quickConnectPollRejected => 'Quick Connect การสอบถามถูกปฏิเสธโดยเซิร์ฟเวอร์';
	@override String get serverTimedOut => 'เซิร์ฟเวอร์ไม่ตอบสนองในเวลา';
	@override String get responseNotJson => 'คําตอบเซิร์ฟเวอร์ไม่ถูกต้อง JSON';
	@override String responseMissingIdentity({required Object product}) => 'คําตอบที่ขาด ID หรือชื่อเซิร์ฟเวอร์ - นี้คือเซิร์ฟเวอร์ ${product}?';
	@override String probeFailed({required Object error}) => 'ไม่สามารถเข้าถึงเซิร์ฟเวอร์: ${error}';
	@override String enterAtLeastOneUrl({required Object product}) => 'ใส่ URL server ${product} หนึ่งอย่างน้อย';
	@override String noReachableServer({required Object product}) => 'ไม่พบเซิร์ฟเวอร์ที่สามารถเข้าถึงได้ ${product}';
	@override String urlsPointToDifferentServers({required Object product}) => 'URLs เหล่านี้หมายถึงเซิร์ฟเวอร์ที่แตกต่างกัน ${product}';
	@override String urlDoesNotMatchServer({required Object product}) => 'URL นี้ไม่ตรงกับเซิร์ฟเวอร์ ${product}';
	@override String get redirectUnsupported => 'เซิร์ฟเวอร์ที่นําไปสู่ URL ที่ไม่ได้สนับสนุน';
	@override String redirectDifferentHost({required Object product}) => 'เซิร์ฟเวอร์ที่นําไปสู่โฮสต์ที่แตกต่างกัน ใส่ URL ${product} สุดท้ายโดยตรง';
	@override String get redirectInsecure => 'เซิร์ฟเวอร์ที่นําทางจาก HTTPS ไปยัง URL ไม่ปลอดภัย';
	@override String redirectUnsupportedEnterFinal({required Object product}) => 'เซิร์ฟเวอร์ที่ถูกนําไปสู่ URL ที่ไม่ได้รับการสนับสนุน ใส่ URL ${product} สุดท้ายโดยตรง';
	@override String get directPlexServerUrl => 'Plex URL เซิร์ฟเวอร์';
	@override String get directPlexServerUrlHelper => 'เข้าสู่ IP และพอร์ตท้องถิ่นของเซิร์ฟเวอร์ Media Plex ของคุณ';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex Token (ตัวเลือก)';
	@override String get plexTokenHelper => 'ปล่อยให้ว่างเปล่าหากการเข้าถึงโดยไม่มี auth จะได้รับอนุญาตบนเซิร์ฟเวอร์นี้';
	@override String get plexTokenRequired => 'การรับรองที่จําเป็น โปรดเข้าสู่ token Plex ของคุณ (X-Plex-Token)';
	@override String get connectDirectPlexCard => 'Plex เซิร์ฟเวอร์สื่อ (โดยตรง / ไซต์)';
	@override String get connectDirectPlexCardSubtitle => 'เชื่อมต่อโดยตรงโดยใช้ IP หรือ URL ภายในโดยไม่ต้องใช้บัญชี plex.tv';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => 'เชื่อมต่อโดยตรงโดยใช้ IP หรือ URL ท้องถิ่น เชื่อมต่อไปยัง ${name}.';
	@override String get insecureTitle => 'การเชื่อมต่อที่ไม่เข้ารหัส';
	@override String insecureDescription({required Object url}) => '${url} ใช้ HTTP บุคคลอื่นในเครือข่ายอาจอ่านหรือแก้ไขรหัสผ่าน โทเค็น และสื่อของคุณได้ โปรดใช้ HTTPS หากมีให้ใช้ ดำเนินการต่อเฉพาะเมื่อคุณเชื่อถือเครือข่ายนี้และยอมรับความเสี่ยง';
	@override String get allowHttp => 'อนุญาต HTTP';
	@override String get httpsRequired => 'ใช้ HTTPS หรืออนุญาตให้มีการเชื่อมต่อที่ไม่ได้เข้ารหัส';
}

// Path: watchLink
class _Translations$watchLink$th extends Translations$watchLink$en {
	_Translations$watchLink$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => 'ฉันไม่สามารถเข้าถึงเซิร์ฟเวอร์ Plex สําหรับลิงค์นี้';
	@override String get notFound => 'ฉันไม่สามารถหาการแสดงหรือภาพยนตร์นี้ได้บนเซิร์ฟเวอร์ Plex ของคุณ';
	@override String get ambiguous => 'เชื่อมโยงนี้ตรงกับรายการในเซิร์ฟเวอร์เดียว เพิ่มเซิร์ฟเวอร์ไปยังลิงค์';
	@override String get plexOnly => 'ติดตามลิงค์ในขณะนี้สนับสนุนเซิร์ฟเวอร์ Plex เท่านั้น';
	@override String get unsupportedItem => 'ดูลิงค์สามารถเปิดการแสดงหรือภาพยนตร์เท่านั้น';
	@override String get menuItem => 'ดูลิงค์';
	@override String get dialogTitle => 'ดูลิงค์';
	@override String get dialogShowHint => 'เปิดลิงค์นี้เล่นส่วนต่อไป เพิ่ม &mode=shuffle ไปยังจุดสุดยอดเพื่อเล่นการแสดงบน shuffle';
	@override String get dialogMovieHint => 'เปิดลิงก์นี้เล่นภาพยนตร์';
	@override String get copy => 'คัดลอก';
	@override String get copied => 'ลิงค์คัดลอก';
}

// Path: homeLayout
class _Translations$homeLayout$th extends Translations$homeLayout$en {
	_Translations$homeLayout$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'Home โลหะ';
	@override String get resetToast => 'บ้านรีเซ็ตไปยังโครงสร้างพื้นฐาน Plezy';
	@override String get resetHeroTitle => 'รีเซ็ตโครงสร้างฮีโร่ไปยังสต็อก Plezy?';
	@override String get resetHeroBody => 'ปิดการตั้งค่าฮีโร่ของแต่ละแถวและนํากลับแบนเนอร์หมุนเดียวที่ด้านบนของบ้านเช่นเดียวกับก่อนที่แถวฮีโร่มีอยู่ แถวและแถวที่แสดงไม่ได้รับผลกระทบ';
	@override String get removeRowTitle => 'ปล่อยสายบ้าน';
	@override String removeRowBody({required Object title}) => '${title} จะถูกลบ ไม่สามารถลบได้';
	@override String get sync => 'ซิงค์';
	@override String get syncAccountTitle => 'การจัดเรียงซิงค์กับบัญชี Plex ของคุณ';
	@override String get syncAccountOn => 'บน: อุปกรณ์นี้แบ่งปันคําสั่งลําดับลําดับ Hero และ Auto-slide กับอุปกรณ์อื่น ๆ ของคุณ';
	@override String get syncAccountOff => 'ปิด: อุปกรณ์นี้ยังคงจัดตั้งของตัวเอง';
	@override String get syncNow => 'ซิงค์ตอนนี้';
	@override String get plexHomeManager => 'Plex ผู้จัดการบ้าน';
	@override String get managePlexRows => 'การจัดการ Plex เถวใน Plezy';
	@override String get managePlexRowsDescription => 'เปิดเพื่อจัดเตรียมเส้นที่เลือกในบ้าน';
	@override String get organizeHomeRows => 'การจัดเรียงสายบ้าน';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} เถว: การเคลื่อนไหว, สัตว์ประหลาด, การลบอัตโนมัติ, ลบ';
	@override String organizeLibraryRows({required Object library}) => 'จัดการ ${library} เถว';
	@override String organizeLibraryRowsDescription({required Object n}) => 'Continue Watching + ${n} เกรด: การเคลื่อนไหว, ห้องสมุด, บ้าน, พระมหากษัตริย์, Auto-slide';
	@override String get renderAsHero => 'Render ในฐานะที่เป็นการ์ดฮีโร่';
	@override String get heroOnlySingleCollection => 'เท่านั้นสามารถใช้ได้เมื่อแถวนี้ได้รับการแก้ไขกับชื่อจริงของชุดเดียว';
	@override String get hero => 'สัตว์เลี้ยง';
	@override String get autoSlide => 'อัตโนมัติ Slide';
	@override String get autoSlideDescription => 'นอกจากนี้ยังสไลด์ด้วยตัวเองทุกวินาที Arrows (PC) และ d-pad (TV) ทํางานเสมอและเปิดตัวใหม่ชั่วโมง';
	@override String get autoSlideEditDescription => 'นอกจากนี้ยังสไลด์ด้วยตัวเองทุกวินาที ปิด: เท่านั้นเคลื่อนที่เมื่อคุณคลิกปืน (พีซี) หรือกดซ้าย / ขวาบนระยะไกล (ทีวี) สไลด์และ d-pad ทํางานเสมอในทางใด ๆ';
	@override String get enableHeroFirst => 'อนุญาตให้ฮีโร่แรก';
	@override String get showOnHome => 'แสดงบนหน้าจอบ้าน';
	@override String get home => 'บ้าน';
	@override String get removeFromHome => 'เอาจากบ้าน';
	@override String get selectRowsFirst => 'เลือกเส้นบ้านด้านล่างแรก';
	@override String plexManagedRows({required Object n}) => '${n} Plex สายการจัดการ';
	@override String get continueWatching => 'ดูต่อ';
	@override String get continueWatchingLibraryDescription => 'เถื่อนขั้นสูงของห้องสมุดนี้เอง';
	@override String get continueWatchingHomeDescription => 'เถื่อนขั้นตอนที่แสดงไว้ในบ้าน';
	@override String get nextUpHomeDescription => 'ต่อไปไม่ได้รับการสังเกต episod sequence แสดงแยกต่างหากใน Home';
	@override String get library => 'คลังสื่อ';
	@override String get showInRecommended => 'แสดงในห้องสมุดแนะนํา';
	@override String get customPlexRow => 'คู่มือ Plex รอบ';
	@override String get heroNeedsLibrary => 'ตรวจสอบห้องสมุดแรก — Hero ต้องการที่ไหนที่จะแสดง';
	@override String get heroNeedsSurface => 'ตรวจสอบห้องสมุดหรือบ้านแรก — สัตว์ประหลาดต้องการที่ไหนที่จะแสดง';
	@override String get removeHub => 'ลบ Hub';
	@override String get noPlexRows => 'หมายเลข Plex-จัดการสายกลับสําหรับห้องสมุดนี้';
	@override String get openDetails => 'รายละเอียดเปิด';
	@override String get heroCards => 'บัตรฮีโร่';
	@override String get tapHeroCard => 'การสูญเสียการ์ดฮีโร่';
	@override String get tvPlayFocus => 'โทรทัศน์ระยะไกล: ปุ่ม Play';
	@override String get tvPlayFocusDescription => 'D-pad down stops on the Play button before moving to the next row ปิดสกีตรงไปสู่ row ต่อไป';
	@override String get tvWrap => 'โทรทัศน์ระยะไกล: ล็อปการ์ดฮีโร่';
	@override String get tvWrapDescription => 'ขวาบนบัตรสุดท้ายจะกลับไปสู่บัตรแรก ปิดหยุดในบัตรสุดท้าย ป้ายบนบัตรแรกจะไปสู่แถบด้านข้างเสมอ';
	@override String get castOnHero => 'การเล่นบนฮีโร่แบนเนอร์';
	@override String get castOnHeroDescription => 'แสดงการแสดงออกอยู่ด้านล่างของแบนเนอร์ฮีโร่ ปิดยังคงเพียงชื่อและสรุป';
	@override String get customRows => 'สายการกําหนดเอง';
	@override String get loading => 'โหลดบ้าน layout ...';
	@override String get noCustomRows => 'ไม่มีการกําหนดเอง';
	@override String get addRowHint => 'ใช้ Add Home เถวเพื่อสร้างหนึ่ง';
	@override String get addHomeRow => 'เพิ่มเรือนบ้าน';
	@override String get addHomeRowDescription => 'เลือกหมวดหมู่ ใบสั่งใหม่จะถูกเพิ่มไปยังผู้จัดงานโดยอัตโนมัติ';
	@override String get removeRow => 'ลบแถว';
	@override String get recentlyAdded => 'เพิ่มล่าสุด';
	@override String get recentlyReleased => 'ปล่อยล่าสุด';
	@override String get movieCollections => 'คอลเลกชันภาพยนตร์';
	@override String get showCollections => 'แสดงคอลเลกชัน';
	@override String get rowTitle => 'รูชื่อ';
	@override String get content => 'ความสุข';
	@override String get showThisRowIn => 'แสดงแถวนี้ใน:';
	@override String get libraryRecommended => 'โบรชัวร์ที่แนะนํา';
	@override String get heroCard => 'บัตรฮีโร่';
	@override String get heroCardDescription => 'แสดงเป็นบัตรหมุนกว้างเดียวแทนที่กระดาษโพสต์';
	@override String get heroUnavailableDescription => 'มีเพียงเมื่อแถวนี้ได้รับการแก้ไขกับชื่อจริงของคอลเลกชันเดียว - ด้วยคอลเลกชันหนึ่งที่เลือกไม่มีชื่อเดียวที่จะหมุนผ่าน';
	@override String get librariesSelection => 'ห้องสมุด (ปล่อยให้ทั้งหมดไม่ตรวจสอบเพื่อรวมห้องสมุดแต่ละห้อง)';
	@override String get librariesMergedDescription => 'ทุกห้องสมุดที่ตรวจสอบที่นี่จะรวมอยู่ในบรรทัดนี้';
	@override String get movieCollectionsSelection => 'ชุดภาพยนตร์ (ปล่อยให้ทั้งหมดไม่ได้ตรวจสอบสําหรับแต่ละห้องสมุดที่เลือก)';
	@override String get showCollectionsSelection => 'แสดงคอลเลกชัน (ปล่อยให้ทั้งหมดไม่ได้ตรวจสอบสําหรับแต่ละห้องสมุดที่เลือก)';
	@override String get collectionRowsDescription => 'หากคอลเลกชันหนึ่งตรงกันข้ามชื่อของมันแสดงโดยตรงในแถว หากคอลเลกชันหนึ่งตรงกันข้ามแต่ละคอลเลกชันแสดงเป็นโพสต์เดียว - คลิกที่มันเพื่อเปิดคอลเลกชันนั้น';
	@override String get allCollections => 'การจัดเก็บทั้งหมด';
	@override String get noRowsHere => 'ไม่มีการติดตามที่นี่อีกต่อไป';
	@override String get hideWatchedRows => 'ซ่อนรายการที่มองเห็นในแถว';
	@override String get hideWatchedRowsDescription => 'หน้าแรกและห้องสมุดตามลําดับที่แนะนํา ในขั้นสูงอยู่';
	@override String get untitledCollection => 'การเก็บรวบรวม';
	@override String get moveRowHint => 'Up/Down: ขั้นตอน · เลือก: ลบที่นี่ · กลับ: ลบ';
	@override String get organizeRowsHint => 'เลือกในแถว (หรือถือ เลือก): ย้ายมัน · ด้านซ้าย/ขวา: ตัวเลือกแถว · กลับ: ทํา';
	@override String get layoutNavDescription => 'เลือกแถว, ห้องสมุดและประเภทการเก็บรวบรวม';
	@override String get editHomeRow => 'รอบบ้าน Edit';
	@override String get resetHeroButton => 'รีเซ็ตโครงสร้างฮีโร่ไปยังสต็อก Plezy';
	@override String get reorderingUnlocked => 'การจัดเรียงใหม่ Unlocked';
	@override String get reorderingLocked => 'ล็อคซับ';
	@override String get rowsCanBeDragged => 'รั้วสามารถดึง — ปิดล็อคเพื่อป้องกันไม่ให้';
	@override String get tapLockToDrag => 'คลิกที่ล็อคเพื่อดึงเส้น';
	@override String customRowLabel({required Object title}) => 'คู่มือ: ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => 'ซ่อน';
	@override String get remove => 'นำออก';
	@override String get libraryResumeRow => 'ใบรับรองของห้องสมุดนี้';
	@override String get pressAgainToDelete => 'คลิกอีกครั้งเพื่อลบ';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => 'ใน';
	@override String get resetHeroButtonDescription => 'ปิดการตั้งค่าฮีโร่ของแต่ละแถวและนําแบรนด์หมุนเดียวกลับไปด้านบนเช่นเดียวกับก่อนที่แถวฮีโร่มีอยู่ แถวจะถูกเก็บไว้';
}

// Path: platform
class _Translations$platform$th extends Translations$platform$en {
	_Translations$platform$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'PlezyNG เชื่อมต่อกับเซิร์ฟเวอร์สื่อและอุปกรณ์การเล่นบนเครือข่ายท้องถิ่นของคุณ';
	@override String get locationPermission => 'PlezyNG ใช้การเข้าถึงตําแหน่งเมื่อ iOS ต้องการการตรวจจับเครือข่ายท้องถิ่นของคุณและเชื่อมต่อกับเซิร์ฟเวอร์สื่อของคุณ';
	@override String get photoLibraryPermission => 'เลือกภาพจากห้องสมุดภาพของคุณเพื่อใช้เป็นงานศิลปะสื่อ';
	@override String get cameraPermission => 'การสแกนรหัส QR เพื่อคู่กับ Companion Remote';
}

// Path: fileSources
class _Translations$fileSources$th extends Translations$fileSources$en {
	_Translations$fileSources$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'ไฟล์และหนังสือ';
	@override String get subtitle => 'อ่านฟังและตรวจสอบจากไฟล์ของคุณเอง';
	@override String get add => 'เพิ่มแหล่ง';
	@override String get importFiles => 'ไฟล์นําเข้า';
	@override String get localFiles => 'ในอุปกรณ์นี้';
	@override String get source => 'หลักสูตร';
	@override String get name => 'ชื่อ';
	@override String get endpoint => 'URL ของเซิร์ฟเวอร์';
	@override String get root => 'แผงหรือ Prefix';
	@override String get username => 'ชื่อผู้ใช้';
	@override String get password => 'คู่มือ';
	@override String get token => 'API โค้น';
	@override String get accessKey => 'การเข้าถึง ID Key';
	@override String get secretKey => 'หลักการเข้าถึงที่ลับ';
	@override String get sessionToken => 'โค้นเซสชั่น (ตัวเลือก)';
	@override String get region => 'พื้นที่';
	@override String get clientId => 'OAuth ID ลูกค้า';
	@override String get clientSecret => 'OAuth คีย์ความลับ (เดสก์ท็อป Google เท่านั้น)';
	@override String get allowHttp => 'อนุญาต HTTP ที่ไม่เข้ารหัสบนเครือข่ายที่เชื่อถือได้';
	@override String get connect => 'เชื่อมต่อ';
	@override String get cancel => 'ยกเลิก';
	@override String get save => 'บันทึก';
	@override String get close => 'ปิด';
	@override String get removeSource => 'ไฟฉาย';
	@override String get disconnectMessage => 'ตัดการเชื่อมต่อแหล่งข้อมูลนี้หรือไม่? ไฟล์ที่ดาวน์โหลดและประวัติการอ่านและการฟังจะยังคงอยู่บนอุปกรณ์นี้';
	@override String get localFolder => 'เลือกโฟลเดอร์';
	@override String get empty => 'ไม่มีอะไรที่นี่';
	@override String get emptyHint => 'เพิ่มแหล่งหรือนําเข้าหนังสือ audiobook, เพลงหรือวิดีโอ';
	@override String get search => 'ค้นหาโฟลเดอร์นี้';
	@override String get searchCached => 'ค้นหาห้องสมุดบันทึก';
	@override String get refresh => 'การทําความเย็น';
	@override String get loadMore => 'บรรจุเพิ่มเติม';
	@override String get offline => 'มีอยู่ offline';
	@override String get download => 'ปิดออก';
	@override String get removeDownload => 'ลบออฟไลน์ คูปอง';
	@override String get continueReading => 'อ่านต่อ';
	@override String get continueListening => 'อ่านต่อ';
	@override String get continueWatching => 'ดูต่อ';
	@override String get read => 'อ่าน';
	@override String get listen => 'ดูข้อความ';
	@override String get play => 'เล่น';
	@override String get pause => 'หยุดชั่วคราว';
	@override String get stop => 'หยุด';
	@override String get startOver => 'เริ่มต้น';
	@override String get finished => 'เสร็จสิ้น';
	@override String get markFinished => 'หมายเลขรุ่น: Mark finished';
	@override String get markUnfinished => 'หมายเลขที่สิ้นสุด';
	@override String get editions => 'การพิมพ์และไฟล์';
	@override String get chapters => 'ประเภท';
	@override String get bookmarks => 'บัญชีและบันทึก';
	@override String get bookmark => 'เพิ่ม Bookmark';
	@override String get highlight => 'แสดง';
	@override String get note => 'บันทึก';
	@override String get delete => 'ลบ';
	@override String get export => 'การส่งออก';
	@override String get exported => 'หมายเลขที่ส่งออก';
	@override String get sync => 'การพัฒนา Sync';
	@override String get synced => 'การพัฒนาแบบซิงค์';
	@override String get conflict => 'อุปกรณ์อื่นมีตําแหน่งที่แตกต่างกัน เลือกที่ที่จะดําเนินการ';
	@override String get useLocal => 'ใช้อุปกรณ์นี้';
	@override String get useRemote => 'ใช้อุปกรณ์อื่น ๆ';
	@override String get history => 'ประวัติตําแหน่ง';
	@override String get groupAudio => 'ดูเหมือนหนังสือเสียง';
	@override String get groupHint => 'รวมไฟล์เสียงที่โหลดในโฟลเดอร์นี้ คลิกที่หน้าทั้งหมดก่อน';
	@override String get order => 'กรณีคําสั่ง';
	@override String get moveUp => 'ขึ้นไป';
	@override String get moveDown => 'การเคลื่อนไหวลง';
	@override String get speed => 'ความเร็ว Playback';
	@override String get sleep => 'เวลานอนหลับ';
	@override String get sleepOff => 'ปิด';
	@override String get endChapter => 'ประเภทสุดท้าย';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(count,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} นาที',
	);
	@override String get skipBack => 'สกินกลับ';
	@override String get skipForward => 'ขั้นตอน';
	@override String get smartRewind => 'สื่อลามกหลังจากการหยุด';
	@override String get playbackOptions => 'การฟังตัวเลือก';
	@override String remaining({required Object time}) => '${time} ออกจากนี้';
	@override String get contents => 'วัสดุ';
	@override String get readerSettings => 'การตั้งค่าการอ่าน';
	@override String get fontSize => 'ขนาดตัวอักษร';
	@override String get lineHeight => 'สายการสเปน';
	@override String get margin => 'มาร์เจน';
	@override String get font => 'ประเภท';
	@override String get serif => 'เซ็กส์';
	@override String get sans => 'ไม่ใช่เซริฟ';
	@override String get mono => 'โมโนสเปน';
	@override String get columns => 'คอลัมน์';
	@override String get scroll => 'การสกรูแนวตั้ง';
	@override String get justify => 'หมายเลข';
	@override String get readerTheme => 'หน้าปรากฏ';
	@override String get appTheme => 'ติดตาม app theme';
	@override String get paper => 'กระดาษ';
	@override String get sepia => 'ซิปต์';
	@override String get night => 'นอน';
	@override String get readAloud => 'อ่านหน้านี้ด้วยเสียง';
	@override String get readAlong => 'อ่านต่อไป';
	@override String get stopReading => 'ปิดการพูด';
	@override String get searchBook => 'ค้นหาในหนังสือ';
	@override String get noMatches => 'ไม่มีเกม';
	@override String get previousPage => 'หน้าแรก';
	@override String get nextPage => 'หน้าต่อไป';
	@override String page({required Object number}) => 'หน้า ${number}';
	@override String get externalBlocked => 'ลิงค์หนังสือภายนอกจะถูกปิดใช้งานในผู้อ่าน';
	@override String get loading => 'เปิด...';
	@override String get narrator => 'สื่อลามก';
	@override String get audio => 'เสียง';
	@override String get video => 'วิดีโอ';
	@override String get ebooks => 'อีบุ๊ก';
	@override String get all => 'ทั้งหมด';
	@override String get downloads => 'ไฟล์ Offline';
	@override String get confirmDelete => 'ลบสำเนาออฟไลน์ที่เลือกหรือไม่? ตำแหน่งการอ่านหรือการฟังและบันทึกของคุณจะยังคงอยู่';
	@override String get errorAuthentication => 'ลงชื่อเข้าสู่ระบบอีกครั้งเพื่อเชื่อมต่อแหล่งนี้อีกครั้ง';
	@override String get errorPermission => 'แหล่งนี้ไม่ให้การเข้าถึงไฟล์ที่ขอ';
	@override String get errorUnavailable => 'แหล่งที่มาไม่สามารถใช้ได้ ลองอีกครั้งหรือเปิดสําเนาแบบออฟไลน์';
	@override String get errorUnsupported => 'รูปแบบหรือการเชื่อมต่อนี้ไม่ได้รับการสนับสนุนบนอุปกรณ์นี้ ดูคู่มือการตั้งค่าแหล่งข้อมูล';
	@override String get errorInvalidData => 'ไฟล์หรือคําตอบเซิร์ฟเวอร์นี้ไม่สามารถอ่านได้ได้อย่างปลอดภัย';
	@override String get errorCancelled => 'การดําเนินการถูกยกเลิก';
	@override String get errorConflict => 'ตําแหน่งได้เปลี่ยนในเซสชั่นอื่น เปิดรายการอีกครั้งเพื่อเลือกตําแหน่ง';
	@override String get signIn => 'เข้าสู่ระบบ';
	@override String get reconnect => 'การเชื่อมต่อ';
	@override String get folderHelp => 'ปล่อยให้เปิดเพื่อเริ่มต้นจากรากแหล่งที่มา URL S3 รวมถึงกล่อง';
	@override String get preferences => 'ความต้องการ';
	@override String get timePosition => 'ตําแหน่ง';
	@override String get audioTrack => 'ออนไลน์';
	@override String get subtitleTrack => 'Subtitle เทร็ก';
	@override String get none => 'ไม่มี';
	@override String get fullscreen => 'หน้าจอเต็มรูปแบบ';
	@override String get syncLocation => 'โฟลเดอร์ Sync Progress (ตัวเลือก)';
	@override String get syncLocationHint => 'โพสต์ WebDAV ที่กําหนดเองสําหรับ PlezyNG state ใช้การเขียนที่กําหนดเอง; โมเดียมยังคงไม่เปลี่ยนแปลง';
	@override String get audiobooks => 'ออดิโอ';
	@override String get comics => 'คอมเมติก';
	@override String get scan => 'สแกนสําหรับหนังสือและสื่อ';
	@override String get browserReader => 'เปิดตัว';
	@override String get browserReaderHelp => 'อ่านเปิดในเบราว์เซอร์ของคุณ ปล่อยให้ PlezyNG เปิดเพื่อบันทึกสถานที่และบันทึกของคุณ';
	@override String get on => 'ใน';
	@override String get advancedSetup => 'การลงทะเบียนแอป';
	@override String get microsoftSignIn => 'ลงชื่อเข้าสู่ระบบกับ Microsoft';
	@override String get zoomIn => 'สื่อใน';
	@override String get zoomOut => 'สวยไป';
	@override String get fitPage => 'หน้าที่เหมาะสม';
	@override String get fitWidth => 'ความกว้างที่เหมาะสม';
	@override String get actualSize => 'ขนาดปัจจุบัน';
	@override String get goToPage => 'ไปที่หน้า';
	@override String get goToSection => 'ไปยังบทความ';
	@override String pageRange({required Object count}) => 'หมายเลข 1 ไปยัง ${count}';
	@override String get pageLayout => 'โลกหน้า';
	@override String get automatic => 'อัตโนมัติ';
	@override String get singlePage => 'หน้าเดียว';
	@override String get twoPages => '2 หน้า';
	@override String get readingDirection => 'การอ่านทิศทาง';
	@override String get leftToRight => 'ป้ายไปขวา';
	@override String get rightToLeft => 'หมายเลขรุ่น: Right to Lease';
	@override String get letterSpacing => 'สเปคจดหมาย';
	@override String get wordSpacing => 'คําอธิบาย';
	@override String get readerControlsHelp => 'ปิดหรือใช้ควบคุมการจูงเพื่อขยายหน้า แดร์ไปยังหน้า Ctrl/ ⁇  + หรือ − ปรับจูง Ctrl/ ⁇  0 จะรีเซ็ตหน้า Page Up และ Page Down จะเปิดหน้า';
	@override String get imagePage => 'หน้าการ์ตูน';
	@override String get resetReader => 'การตั้งค่าการอ่านใหม่';
	@override String get zoom => 'โซม';
	@override String get useFiles => 'ใช้ไฟล์และหนังสือ';
	@override String get cancelScan => 'สแกนลบ';
	@override String get googleDrive => 'Google Drive';
}

// Path: lending
class _Translations$lending$th extends Translations$lending$en {
	_Translations$lending$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'สวนสาธารณะ';
	@override String get add => 'เพิ่มห้องสมุด';
	@override String get other => 'อื่น ๆ บิสตจักร';
	@override String get libraryName => 'ชื่อห้องสมุด';
	@override String get libraryUrl => 'เว็บไซต์ของห้องสมุด';
	@override String get libraryUrlHint => 'ใช้คอลเลกชันของห้องสมุดหรือหน้าลงทะเบียน';
	@override String get intro => 'จองจากห้องสมุดของคุณ ปกป้องหนังสือของคุณ';
	@override String get handoff => 'ลงทะเบียนให้เช่าและอ่านได้อย่างปลอดภัยด้วยบริการของห้องสมุดของคุณเอง';
	@override String get openService => 'ห้องสมุดเปิด';
	@override String get findLibrary => 'ค้นหาห้องสมุด';
	@override String get search => 'ค้นหาหนังสือและผู้เขียน';
	@override String get catalogue => 'คาตาล็อก';
	@override String get loans => 'โอนเงิน';
	@override String get holds => '⁇';
	@override String get signIn => 'ลงทะเบียนกับห้องสมุดของคุณ';
	@override String get waiting => 'เสร็จสิ้นการลงทะเบียนในเบราว์เซอร์ของคุณแล้วกลับที่นี่';
	@override String get cancel => 'ยกเลิก';
	@override String get disconnect => 'ลบห้องสมุด';
	@override String get disconnectMessage => 'ลบห้องสมุดนี้จากโปรไฟล์นี้? ใบรับรองของคุณและเก็บพักกับห้องสมุดของคุณ';
	@override String get getBook => 'รับหนังสือ';
	@override String get checkAvailability => 'ตรวจสอบความพร้อม';
	@override String get available => 'มีให้เลือกที่จะให้เช่า';
	@override String get unavailable => 'ไม่สามารถใช้ได้ในขณะนี้';
	@override String get borrow => 'โอกาส';
	@override String get placeHold => 'สถานที่เก็บ';
	@override String get returnBook => 'กลับมาก่อน';
	@override String get cancelHold => 'ปล่อยการเก็บรักษา';
	@override String get confirmBorrow => 'รับใบรับรองจากห้องสมุดของคุณหรือไม่';
	@override String get confirmReturn => 'รับเงินคืนนี้ตอนนี้? คุณอาจต้องรับเงินคืนเพื่อให้ดําเนินการต่อไป';
	@override String get confirmCancelHold => 'ลบการเก็บรักษาของคุณในชื่อนี้หรือไม่';
	@override String get email => 'หมายเลขอีเมล';
	@override String due({required Object date}) => 'หมายเลขรุ่น: ${date}';
	@override String queue({required Object position}) => 'ตําแหน่ง ${position} ในเส้น';
	@override String get empty => 'ไม่มีชื่อที่นี่';
	@override String get openLibraryNote => 'ค้นหาคอลเลกชันของ Open Library ตัวเลือกการอ่านและรับเงินจะแสดงในหน้าของแต่ละหัวข้อ';
	@override String get more => 'บรรจุเพิ่มเติม';
	@override String get gateway => 'บริการลงทะเบียนห้องสมุด';
	@override String get gatewayHint => 'ให้โดยห้องสมุดของคุณหรือผู้ดูแลระบบ PlezyNG';
	@override String get advanced => 'การรวมห้องสมุด';
	@override String get loadLibraries => 'เลือกห้องสมุดของคุณ';
	@override String get expired => 'โอนนี้หมดอายุ';
	@override String get updated => 'บีบอิสระปรับปรุง';
	@override String get continueService => 'ทํางานต่อไป';
	@override String get comingSoon => 'การรับประกันในแอป · มาเร็ว ๆ นี้';
	@override String get comingSoonDescription => 'การรวมของ Libby จะอยู่บนทางของคุณ คุณสามารถใช้ห้องสมุดของคุณใน Libby ในขณะที่เราจะเสร็จสิ้นการเชื่อมต่อ';
	@override String get suspendHold => 'ปิดการเก็บรักษา';
	@override String get resumeHold => 'ใบเสนอราคา';
	@override String get suspendMessage => 'ปล่อยตําแหน่งของคุณในเส้นและปล่อยให้ผู้อ่านต่อไปให้คูปองนี้? คุณสามารถรับคืนการเก็บไว้ในภายหลัง';
	@override String get resumeMessage => 'ใหม่นี้เก็บไว้เพื่อให้ห้องสมุดของคุณสามารถเสนอสําเนาต่อไปที่พร้อมใช้งานได้หรือไม่';
	@override String get editEmail => 'การเปลี่ยนแปลงอีเมลการแจ้งเตือน';
}

// Path: appIcon.names
class _Translations$appIcon$names$th extends Translations$appIcon$names$en {
	_Translations$appIcon$names$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get midnight => 'นมกลางคืน';
	@override String get ember => 'คน';
	@override String get paper => 'กระดาษ';
	@override String get oled => 'OLED';
	@override String get line => 'สาย';
	@override String get ocean => 'ชายหาด';
	@override String get ultraviolet => 'อัลตราไวโอเลต';
	@override String get matcha => 'การแข่งขัน';
	@override String get sunset => 'กุหลาบ';
	@override String get gold => 'เหรียญ';
	@override String get titanium => 'ไทเทเนียม';
	@override String get glass => 'กระจก';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => 'ซินเทจ';
	@override String get pixel => 'พิกเซล';
	@override String get neon => 'ไนโอน';
	@override String get sticker => 'สติ๊กเกอร์';
	@override String get ticket => 'ตั๋ว';
	@override String get pop => 'โป๊';
	@override String get strata => 'แพทย์';
	@override String get facet => 'หน้า';
	@override String get tilde => 'ตุ๊กตา';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$th extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

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
class _Translations$common$mediaKind$th extends Translations$common$mediaKind$en {
	_Translations$common$mediaKind$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get movie => 'ภาพยนตร์';
	@override String get show => 'แสดง';
	@override String get season => 'ซีซัน';
	@override String get episode => 'ตอน';
	@override String get artist => 'ศิลปิน';
	@override String get album => 'อัลบั้ม';
	@override String get track => 'ล้อ';
	@override String get collection => 'การจัดเก็บ';
	@override String get playlist => 'เพลย์ลิสต์';
	@override String get clip => 'คลิก';
	@override String get photo => 'ภาพถ่าย';
	@override String get folder => 'แผง';
}

// Path: themeEditor.slots
class _Translations$themeEditor$slots$th extends Translations$themeEditor$slots$en {
	_Translations$themeEditor$slots$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get bg => 'ลักษณะ';
	@override String get surface => 'พื้นผิว';
	@override String get outline => 'อะไหล่';
	@override String get text => 'ข้อความ';
	@override String get textMuted => 'ภาษาไทย';
	@override String get accent => 'แรงดันไฟฟ้า';
}

// Path: themeEditor.contrast
class _Translations$themeEditor$contrast$th extends Translations$themeEditor$contrast$en {
	_Translations$themeEditor$contrast$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => 'หมายเลขในพื้นหลัง';
	@override String get textOnSurface => 'หมายเลขบนพื้นผิว';
	@override String get textMutedOnBg => 'วิดีโอด้านหลัง';
	@override String get textMutedOnSurface => 'วินาทีข้อความบนพื้นผิว';
	@override String get accentOnBg => 'ความเข้มข้นในพื้นหลัง';
	@override String get accentOnSurface => 'ความเข้มข้นบนพื้นผิว';
	@override String get labelOnAccent => 'ปุ่มแท็กบน accent';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$th extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'เล่น / ปาก';
	@override String get volumeUp => 'หมายเลขรุ่น: Volume Up';
	@override String get volumeDown => 'หมายเลขรุ่น: Down';
	@override String seekForward({required Object seconds}) => 'ค้นหาไปข้างหน้า (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'ค้นหากลับ (${seconds}s)';
	@override String get fullscreenToggle => 'รวมหน้าจอเต็มรูปแบบ';
	@override String get muteToggle => 'ร่วมกัน ควย';
	@override String get subtitleToggle => 'รวบรวม Subtitles';
	@override String get audioTrackNext => 'ถัดไป Audio Track';
	@override String get subtitleTrackNext => 'ถัดไป Subtitle Track';
	@override String get chapterNext => 'บทความถัดไป';
	@override String get chapterPrevious => 'ประเภทก่อนหน้านี้';
	@override String get episodeNext => 'เรื่องถัดไป';
	@override String get episodePrevious => 'ประวัติศาสตร์';
	@override String get speedIncrease => 'ความเร็วเพิ่มขึ้น';
	@override String get speedDecrease => 'ลดความเร็ว';
	@override String get speedReset => 'ความเร็วการตั้งค่า';
	@override String get zoomIn => 'โซม In';
	@override String get zoomOut => 'สื่อลามก';
	@override String get zoomReset => 'รีเซ็ต Zoom';
	@override String get subSeekNext => 'ค้นหา Subtitle ต่อไป';
	@override String get subSeekPrev => 'ค้นหา Subtitle ก่อนหน้านี้';
	@override String get subtitleDelayIncrease => 'ภายใต้หัวข้อ';
	@override String get subtitleDelayDecrease => 'Subtitles ออนไลน์';
	@override String get shaderToggle => 'ตะแกรง';
	@override String get skipMarker => 'สปินอินเทอร์ / โคตร';
	@override String get screenshot => 'จอภาพหน้าจอ';
	@override String get framePrevious => 'Frame อดีต';
	@override String get frameNext => 'Frame ต่อไป';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$th extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'ต้องการ Android 8.0 หรือใหม่กว่า';
	@override String get iosVersion => 'ต้องใช้ iOS 15.0 หรือใหม่กว่า';
	@override String get permissionDisabled => 'รูปภาพในภาพถูกปิดใช้งาน เปิดใช้งานในตั้งค่าระบบ';
	@override String get notSupported => 'อุปกรณ์ไม่สนับสนุนโหมดภาพในภาพ';
	@override String get voSwitchFailed => 'ไม่สามารถเปลี่ยนการส่งออกวิดีโอเพื่อภาพในภาพ';
	@override String get failed => 'ภาพถ่ายในภาพไม่สามารถเริ่มต้นได้';
	@override String get prepareFailed => 'รูปภาพในภาพไม่สามารถเตรียมได้';
	@override String unknown({required Object error}) => 'ข้อผิดพลาดเกิดขึ้น: ${error}';
}

// Path: accountPreferences.groups
class _Translations$accountPreferences$groups$th extends Translations$accountPreferences$groups$en {
	_Translations$accountPreferences$groups$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => 'เสียงและหัวข้อ';
	@override String get libraryDisplay => 'คลังสื่อ';
	@override String get personalMedia => 'ข้อมูลส่วนบุคคล';
}

// Path: accountPreferences.subtitleModes
class _Translations$accountPreferences$subtitleModes$th extends Translations$accountPreferences$subtitleModes$en {
	_Translations$accountPreferences$subtitleModes$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get none => 'เลือกด้วยตนเอง';
	@override String get noneDescription => 'ไม่เคยเปลี่ยนหัวข้อโดยตัวเอง';
	@override String get defaultMode => 'เคล็ดลับการติดตามการติดตาม';
	@override String get defaultModeDescription => 'ใช้ป้ายเริ่มต้นและบังคับที่เก็บไว้ในแต่ละแถบหัวข้อ';
	@override String get always => 'ปัจจุบันเปิดใช้งาน';
	@override String get alwaysDescription => 'แปลงเส้นทางของหัวข้อในภาษาที่ต้องการทุกครั้งที่หนึ่งมีอยู่';
	@override String get onlyForced => 'เท่านั้น Subtitles';
	@override String get onlyForcedDescription => 'บรรจุเพียงเส้นทางที่ระบุไว้เป็นบังคับ';
	@override String get smart => 'แสดงด้วยเสียงต่างประเทศ';
	@override String get smartDescription => 'แปลงหัวข้อเฉพาะเมื่อเสียงอยู่ในภาษาอื่น';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class _Translations$accountPreferences$subtitleAccessibilityOptions$th extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	_Translations$accountPreferences$subtitleAccessibilityOptions$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'มักจะชอบหัวข้อที่ไม่ใช่ SDH';
	@override String get preferSdh => 'ดีกว่า SDH subtitles';
	@override String get onlySdh => 'เท่านั้น SDH subtitles';
	@override String get onlyNonSdh => 'เท่านั้น Subtitles ไม่ใช่ SDH';
}

// Path: accountPreferences.forcedSubtitleOptions
class _Translations$accountPreferences$forcedSubtitleOptions$th extends Translations$accountPreferences$forcedSubtitleOptions$en {
	_Translations$accountPreferences$forcedSubtitleOptions$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => 'มากกว่าหัวข้อที่ไม่บังคับ';
	@override String get preferForced => 'มากกว่าหัวข้อบังคับ';
	@override String get onlyForced => 'เท่านั้น Subtitles';
	@override String get onlyNonForced => 'เท่านั้น Subtitles ไม่บังคับ';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$th extends Translations$accountPreferences$watchedIndicatorOptions$en {
	_Translations$accountPreferences$watchedIndicatorOptions$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get none => 'ไม่เคย';
	@override String get moviesAndShows => 'ภาพยนตร์และการแสดงทีวี';
	@override String get movies => 'ภาพยนตร์เท่านั้น';
	@override String get shows => 'แสดงทีวีเท่านั้น';
}

// Path: accountPreferences.mediaReviewsOptions
class _Translations$accountPreferences$mediaReviewsOptions$th extends Translations$accountPreferences$mediaReviewsOptions$en {
	_Translations$accountPreferences$mediaReviewsOptions$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'ผู้ใช้และนักวิจารณ์';
	@override String get usersOnly => 'ผู้ใช้เท่านั้น';
	@override String get criticsOnly => 'การวิจารณ์เท่านั้น';
	@override String get nobody => 'ซ่อนอยู่';
}

// Path: discover.person
class _Translations$discover$person$th extends Translations$discover$person$en {
	_Translations$discover$person$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get born => 'เกิด';
	@override String get died => 'ตาย';
	@override String get birthplace => 'สถานที่เกิด';
	@override String dateWithAge({required Object date, required Object age}) => '${date} (อายุ ${age})';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (อายุ ${age})';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$th extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'คําแนะนํา';
	@override String get browse => 'เรียกดู';
	@override String get collections => 'คอลเลกชัน';
	@override String get playlists => 'เพลย์ลิสต์';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$th extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'กลุ่ม';
	@override String get all => 'ทั้งหมด';
	@override String get movies => 'ภาพยนตร์';
	@override String get shows => 'แสดงทีวี';
	@override String get seasons => 'ฤดูกาล';
	@override String get episodes => 'ฉาก';
	@override String get artists => 'ศิลปิน';
	@override String get albums => 'อัลบั้ม';
	@override String get tracks => 'การเดินทาง';
	@override String get folders => 'โฟลเดอร์';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$th extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get genre => 'ประเภท';
	@override String get year => 'ปี';
	@override String get contentRating => 'ระดับเนื้อหา';
	@override String get tag => 'แท็ก';
	@override String get unwatched => 'การตรวจสอบ';
	@override String get unplayed => 'การเล่น';
	@override String get favorites => 'รายการโปรด';
	@override String get filePath => 'ฟิล์มเส้นทาง';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$th extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'ชื่อเรื่อง';
	@override String get dateAdded => 'วันที่เพิ่ม';
	@override String get releaseDate => 'วันที่ปล่อย';
	@override String get rating => 'คะแนน';
	@override String get communityRating => 'การให้คะแนนจากคอมมิวนิตี';
	@override String get criticRating => 'การรับรองเชิงบวก';
	@override String get userRating => 'รีวิวผู้ใช้';
	@override String get datePlayed => 'วันที่เล่น';
	@override String get playCount => 'เล่นหมายเลข';
	@override String get productionYear => 'ปีการผลิต';
	@override String get runtime => 'ระยะเวลา';
	@override String get officialRating => 'การรับรองทางการ';
	@override String get premiereDate => 'วันที่เริ่มต้น';
	@override String get startDate => 'วันที่เริ่มต้น';
	@override String get airTime => 'เวลาอากาศ';
	@override String get studio => 'สตูดิโอ';
	@override String get random => 'สัญญา';
	@override String get dateShared => 'วันที่แบ่งปัน';
	@override String get latestEpisodeAirDate => 'ฤดูใบไม้ผลิล่าสุด';
	@override String get lastEpisodeDateAdded => 'ไฟล์ล่าสุด ไฟล์ล่าสุด';
	@override String get dateDownloaded => 'วันที่ดาวน์โหลด';
	@override String get size => 'ขนาด';
	@override String get library => 'คลังสื่อ';
}

// Path: libraries.advancedFilters
class _Translations$libraries$advancedFilters$th extends Translations$libraries$advancedFilters$en {
	_Translations$libraries$advancedFilters$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get include => 'รวมถึง';
	@override String get exclude => 'การยกเลิก';
	@override String get any => 'ใด ๆ';
	@override String get yes => 'ใช่';
	@override String get no => 'ไม่';
	@override String not({required Object value}) => 'ไม่ ${value}';
	@override String valueCount({required Object count}) => '${count} เลือก';
	@override String valueCountExcluded({required Object count}) => '${count} ไม่มี';
	@override String get searchValues => 'หลักการค้นหา';
	@override String get noValues => 'ไม่มีค่า';
	@override String get matchContains => 'บรรจุภัณฑ์';
	@override String get matchNotContains => 'ไม่รวมถึง';
	@override String get matchIs => 'เป็น';
	@override String get matchIsNot => 'ไม่ใช่';
	@override String get matchBeginsWith => 'เริ่มต้นด้วย';
	@override String get matchEndsWith => 'เสร็จสิ้นกับ';
	@override String get textHint => 'ชนิด เพื่อ Match';
	@override String get from => 'จาก';
	@override String get to => 'เพื่อ';
	@override String range({required Object from, required Object to}) => '${from} ถึง ${to}';
	@override String atLeast({required Object value}) => '${value} และขึ้น';
	@override String atMost({required Object value}) => 'สูงสุด ${value}';
	@override String dateLastDays({required Object count}) => '${count} วันที่ผ่านมา';
	@override String get dateLastYear => 'ปีที่ผ่านมา';
	@override String dateOlderThanDays({required Object count}) => 'เก่ากว่า ${count} วัน';
	@override String get dateOlderThanYear => 'เก่ากว่าหนึ่งปี';
}

// Path: libraries.selection
class _Translations$libraries$selection$th extends Translations$libraries$selection$en {
	_Translations$libraries$selection$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get selectItems => 'เลือกรายการ';
	@override String selectedCount({required Object count}) => '${count} เลือก';
	@override String get actions => 'การเลือกกิจกรรม';
	@override String get confirmDescendants => 'นี่จะเปลี่ยนทุก episodes ในการแสดงและฤดูกาลที่เลือก';
	@override String get confirmUnwatched => 'นี่ยังทําความสะอาดการเล่นของรายการที่เลือก';
	@override String confirmCount({required Object count}) => 'รายการที่เลือก: ${count}';
	@override String completed({required Object count}) => 'รายการที่ปรับปรุง: ${count}';
	@override String partialFailure({required Object succeeded, required Object failed}) => 'ปรับปรุง ${succeeded}; ไม่ได้สําเร็จ ${failed}. รายการที่ไม่สําเร็จจะยังคงเลือก';
}

// Path: explore.mdblistShelves
class _Translations$explore$mdblistShelves$th extends Translations$explore$mdblistShelves$en {
	_Translations$explore$mdblistShelves$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get manage => 'การจัดการสํารวจชั้นวาง';
	@override String get manageDescription => 'เลือกและจัดรายการจากบัญชี MDBList ของคุณ';
	@override String get description => 'เลือกรายการภาพยนตร์และโทรทัศน์สาธารณะจากบัญชี MDBList ของคุณ สร้างหรือคัดลอกรายการบน MDBList จากนั้นปรับปรุง';
	@override String get selected => 'ตารางที่เลือก';
	@override String get available => 'รายการบัญชีที่มีอยู่';
	@override String get noLists => 'ไม่มีรายการภาพยนตร์สาธารณะหรือรายการทีวีที่กลับมา สร้างหรือคัดลอกรายการที่ MDBList จากนั้นปรับปรุง';
	@override String get displayName => 'ชื่อ Shelf Display';
	@override String get nameHint => 'ปล่อยให้เปิดเพื่อใช้ชื่อรายการแหล่งข้อมูล';
	@override String get add => 'เพิ่ม Shelf';
	@override String get save => 'เก็บเตียง';
	@override String moveUp({required Object title}) => 'การเคลื่อนไหว ${title} ขึ้น';
	@override String moveDown({required Object title}) => 'การเคลื่อนไหว ${title} ลง';
	@override String get unavailable => 'รายการนี้ไม่สามารถใช้ได้ ลบหรือลบตู้ของมันในตั้งค่า';
	@override String get rateLimited => 'MDBList ขั้นตอนการร้องขอได้ถึง. โปรดส่งกลับต่อไป.';
	@override String get loadFailed => 'ไม่สามารถโหลดแผ่นได้ ตรวจสอบการเชื่อมต่อของคุณและรีด';
	@override String get saveFailed => 'ฉันไม่สามารถบันทึกเก้าอี้โปรดรีด';
	@override String get accountChanged => 'บัญชีหรือโปรไฟล์ได้เปลี่ยนแปลง การเปิดตั้งค่าเหล่านี้อีกครั้ง';
	@override String get settingsUnreadable => 'แผ่นบันทึกไม่สามารถอ่านได้ เลือกรายการของคุณอีกครั้งเพื่อแทนที่การตั้งค่าเหล่านี้';
}

// Path: explore.rows
class _Translations$explore$rows$th extends Translations$explore$rows$en {
	_Translations$explore$rows$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'รายการตรวจสอบ';
	@override String get recommendedMovies => 'ภาพยนตร์ที่แนะนํา';
	@override String get recommendedShows => 'แสดงที่แนะนํา';
	@override String get trendingMovies => 'ภาพยนตร์แนวโน้ม';
	@override String get trendingShows => 'แสดงแนวโน้ม';
	@override String get popularMovies => 'ภาพยนตร์ยอดนิยม';
	@override String get popularShows => 'แสดงยอดนิยม';
	@override String get trendingAnime => 'มือสมัครเล่น';
	@override String get suggestedAnime => 'แนะนํา Anime';
	@override String get airingAnime => 'ออนิเมะ';
	@override String get popularAnime => 'มากที่สุด Anime';
	@override String get trending => 'ทนทาน';
	@override String get upcomingMovies => 'ภาพยนตร์ที่มา';
	@override String get upcomingShows => 'แสดงที่มา';
}

// Path: explore.status
class _Translations$explore$status$th extends Translations$explore$status$en {
	_Translations$explore$status$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get airing => 'อากาศ';
	@override String get ended => 'จบ';
	@override String get canceled => 'ปล่อย';
	@override String get upcoming => 'มาใหม่';
}

// Path: explore.badge
class _Translations$explore$badge$th extends Translations$explore$badge$en {
	_Translations$explore$badge$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} ยอดนิยม';
	@override String rankAiring({required Object n}) => '#${n} อากาศ';
	@override String rankRated({required Object n}) => '#${n} คะแนน';
	@override String rankTrending({required Object n}) => '#${n} ทนทาน';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} ใน ${season}';
	@override String watchingNow({required Object n}) => '${n} ดู';
	@override String get available => 'มี';
	@override String get partiallyAvailable => 'มีส่วนหนึ่ง';
	@override String get availableIn4k => '4K มี';
	@override String get requested => 'คําขอ';
	@override String get pendingApproval => 'การอนุมัติ';
	@override String get processing => 'การประมวลผล';
	@override String get declined => 'การลดลง';
	@override String get requestFailed => 'การร้องขอไม่สําเร็จ';
	@override String get requested4k => '4K คําขอ';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} ฤดูกาล';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => 'Ep ${episode} ใน ${duration}';
	@override String nextAiringIn({required Object duration}) => 'ถัดไป ใน ${duration}';
	@override String episodesShort({required Object n}) => '${n} ตอน';
	@override String minutesPerEpisode({required Object n}) => '${n} นาที / กรกฎาคม';
	@override String get adult => '18+';
}

// Path: explore.stats
class _Translations$explore$stats$th extends Translations$explore$stats$en {
	_Translations$explore$stats$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} รายการ';
	@override String viewersDay({required Object n}) => '${n} ครั้งที่เข้าดูวันนี้';
	@override String viewersWeek({required Object n}) => '${n} ครั้งในสัปดาห์นี้';
	@override String viewersMonth({required Object n}) => '${n} ครั้งในเดือนนี้';
	@override String viewersYear({required Object n}) => '${n} ครั้งในปีนี้';
	@override String viewersAllTime({required Object n}) => '${n} ครั้งที่เข้าดู';
	@override String planning({required Object n}) => '${n} การวางแผนที่จะดู';
	@override String favorited({required Object n}) => '${n} ความรัก';
	@override String dropRate({required Object percent}) => '${percent} ลบมัน';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ความคิดเห็น',
	);
	@override String votes({required Object n}) => '${n} วิดีโอ';
	@override String watching({required Object n}) => '${n} ดูมัน';
	@override String completed({required Object n}) => '${n} ที่เสร็จสิ้น';
	@override String onHold({required Object n}) => '${n} บน hold';
	@override String dropped({required Object n}) => '${n} ปิด';
}

// Path: explore.season
class _Translations$explore$season$th extends Translations$explore$season$en {
	_Translations$explore$season$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get winter => 'ฤดูหนาว';
	@override String get spring => 'สวน';
	@override String get summer => 'ฤดูร้อน';
	@override String get fall => 'ปิด';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class _Translations$explore$format$th extends Translations$explore$format$en {
	_Translations$explore$format$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get tv => 'ทีวี';
	@override String get tvShort => 'ช่องทีวี';
	@override String get movie => 'ภาพยนตร์';
	@override String get special => 'ข้อมูลพิเศษ';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => 'เพลง';
	@override String get other => 'อื่น ๆ';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$th extends Translations$explore$sourceMaterial$en {
	_Translations$explore$sourceMaterial$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get original => 'หลัก';
	@override String get manga => 'มังสเตน';
	@override String get lightNovel => 'โบรี่แสง';
	@override String get novel => 'เรื่องราว';
	@override String get visualNovel => 'หนังสือภาพ';
	@override String get game => 'เกม';
	@override String get webComic => 'เว็บแคม';
	@override String get musicRelease => 'เพลง';
	@override String get otherMedia => 'อื่น ๆ';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$th extends Translations$explore$creditRole$en {
	_Translations$explore$creditRole$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get actor => 'นักแสดง';
	@override String get director => 'ผู้กำกับ';
	@override String get writer => 'ผู้เขียน';
	@override String get producer => 'ผู้ผลิต';
	@override String get creator => 'ผู้สร้าง';
	@override String get composer => 'คอมโพสิต';
}

// Path: explore.relation
class _Translations$explore$relation$th extends Translations$explore$relation$en {
	_Translations$explore$relation$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get prequel => 'โพสต์';
	@override String get sequel => 'เซ็กส์';
	@override String get sideStory => 'ประวัติด้านข้าง';
	@override String get spinOff => 'สปินออก';
	@override String get alternativeVersion => 'เวอร์ชันทางเลือก';
	@override String get summary => 'คําอธิบาย';
	@override String get parentStory => 'ประวัติของพ่อแม่';
	@override String get adaptation => 'การปรับแต่ง';
	@override String get other => 'การเชื่อมโยง';
}

// Path: explore.detail
class _Translations$explore$detail$th extends Translations$explore$detail$en {
	_Translations$explore$detail$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'ชื่อต้นฉบับ';
	@override String get alsoKnownAs => 'นอกจากนี้ยังเป็นที่รู้จักกันว่า';
	@override String get studios => 'สตูดิโอ';
	@override String get country => 'ประเทศ';
	@override String get language => 'ภาษา';
	@override String get released => 'ปล่อย';
	@override String get physicalRelease => 'บดิสก์';
	@override String get ended => 'จบ';
	@override String addedOn({required Object date}) => 'ที่เพิ่ม ${date}';
	@override String get yourRating => 'การจัดอันดับของคุณ';
	@override String get budget => 'โพสต์';
	@override String get revenue => 'กล่องสํานักงาน';
	@override String get contentAdvisory => 'การแนะนําอายุ';
	@override String get tags => 'แท็ก';
	@override String get revealSpoilerTags => 'แสดงแท็ก spoiler';
	@override String get links => 'ป้าย';
	@override String get watchOn => 'ดูเพิ่มเติม';
	@override String get watchTrailer => 'ดู trailer';
	@override String openOn({required Object site}) => 'เปิดที่ ${site}';
	@override String get crew => 'พันธมิตร';
	@override String get ratings => 'คะแนน';
	@override String get schedule => 'ตั้งเวลา';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n,
		other: 'คําแนะนําโดย ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ผู้ใช้',
	);
	@override String recommendedBy({required Object who}) => 'คําแนะนําโดย ${who}';
	@override String favoritedBy({required Object who}) => 'มือสมัครเล่นโดย ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} ไม่มีการส่งมา';
	@override String recommendedByPercent({required Object percent}) => 'คําแนะนําโดย ${percent} ของผู้ชม';
	@override String get relatedTitles => 'ชื่อที่เกี่ยวข้อง';
	@override String get background => 'ลักษณะ';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$th extends Translations$liveTv$recordSettings$en {
	_Translations$liveTv$recordSettings$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get startEarly => 'เริ่มต้นเร็ว ๆ นี้ (วินาที)';
	@override String get endLate => 'เสร็จสิ้นช้า (วินาที)';
	@override String get newOnly => 'เท่านั้น episodes ใหม่';
	@override String get anyChannel => 'การบันทึกในช่องใด ๆ';
	@override String get anyTime => 'บันทึกในเวลาใด ๆ';
	@override String get skipInLibrary => 'ละลาย episodes ในห้องสมุดแล้ว';
	@override String get keepUpTo => 'ฉากที่จะรักษา';
	@override String get keepUpToHint => '0 เก็บทุก episod';
}

// Path: music.discography
class _Translations$music$discography$th extends Translations$music$discography$en {
	_Translations$music$discography$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'Singles และ EPs';
	@override String get live => 'ชีวิต';
	@override String get compilations => 'คอมเพลต';
}

// Path: watchTogether.notices
class _Translations$watchTogether$notices$th extends Translations$watchTogether$notices$en {
	_Translations$watchTogether$notices$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name} การเล่นกด';
	@override String get playbackStarted => 'Playback เริ่มต้น';
	@override String paused({required Object name}) => '${name} ปิด';
	@override String get playbackPaused => 'Playback ปิด';
	@override String jumpedTo({required Object name, required Object position}) => '${name} ยกไป ${position}';
	@override String roomJumpedTo({required Object position}) => 'คลิกที่ ${position}';
	@override String changedSpeed({required Object name, required Object speed}) => '${name} ระบุความเร็วถึง ${speed}';
	@override String speedChanged({required Object speed}) => 'ความเร็วที่กําหนดเองถึง ${speed}';
	@override String startedMedia({required Object name, required Object title}) => '${name} เริ่มต้น ${title}';
	@override String mediaStarted({required Object title}) => 'ตอนนี้เล่น ${title}';
	@override String stoppedMedia({required Object name}) => '${name} ปิดวิดีโอ';
	@override String get mediaStopped => 'วิดีโอหยุด';
	@override String waitingFor({required Object name}) => 'รอสําหรับ ${name} ...';
	@override String get waitingForSomeone => 'รอสําหรับคนที่จะจับ ...';
	@override String get finished => 'เสร็จสิ้น';
	@override String hostChangedTo({required Object name}) => '${name} ตอนนี้เป็นโฮสต์';
	@override String get youAreNowHost => 'ตอนนี้คุณเป็นโฮสต์';
	@override String joined({required Object name}) => '${name} เข้าร่วม';
	@override String left({required Object name}) => '${name} ป้าย';
	@override String get controlRefused => 'เท่านั้นโฮสต์เท่านั้นที่สามารถควบคุม playback';
	@override String get searchFailed => 'บางเซิร์ฟเวอร์ไม่สามารถค้นหาสําหรับวิดีโอของห้อง';
	@override String get playBlocked => 'การเล่นกดเพื่อเริ่มต้น';
	@override String get shareFailed => 'ฉันไม่สามารถแบ่งปันวิดีโอนี้กับห้องพัก';
	@override String get downloadNotShared => 'ดาวน์โหลดไม่ได้แบ่งปันกับห้องในขณะที่เซิร์ฟเวอร์ของพวกเขาเป็นออฟไลน์';
	@override String get openFailed => 'ไม่สามารถเปิดวิดีโอของห้อง';
}

// Path: watchTogether.ended
class _Translations$watchTogether$ended$th extends Translations$watchTogether$ended$en {
	_Translations$watchTogether$ended$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get ended => 'เจ้าภาพเสร็จสิ้นห้องพัก';
	@override String get kicked => 'คุณถูกถอดออกจากห้อง';
	@override String get expired => 'ห้องพักสิ้นสุด';
	@override String get replaced => 'คุณเชื่อมต่อห้องนี้บนอุปกรณ์อื่น ๆ';
	@override String get lost => 'การสูญเสียการเชื่อมต่อกับห้องพัก';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$th extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => 'นี่ไม่ใช่รหัสห้อง รหัสมี 6 บิตและตัวเลขโดยไม่มี 0, 1, I, L หรือ O';
	@override String get roomNotFound => 'ไม่มีห้องที่มีรหัสนี้ อาจจะสิ้นสุด';
	@override String get roomFull => 'ห้องนั้นเต็มไปด้วย';
	@override String get roomLocked => 'เจ้าภาพปิดห้องนี้';
	@override String get relayFull => 'ดูร่วมกัน忙碌ในขณะนี้ ลองอีกครั้งหลังจากนั้น';
	@override String get unreachable => 'ไม่สามารถเข้าถึง Watch Together relay ตรวจสอบการเชื่อมต่อของคุณ';
	@override String get rateLimited => 'มากเกินไปการพยายาม. รอนาทีและลองอีกครั้ง';
	@override String get clientBlocked => 'เวอร์ชันนี้ของ PlezyNG ไม่สามารถใช้ relay ปรับปรุงแอป';
	@override String get forbidden => 'เท่านั้นโฮสต์เท่านั้นที่สามารถทําได้';
	@override String get notInRoom => 'คุณไม่ได้อยู่ในห้อง';
	@override String get alreadyInRoom => 'คุณอยู่ในห้อง';
	@override String get resumeFailed => 'ไม่สามารถเข้าถึงห้อง';
	@override String get unsupported => 'Relay ไม่สนับสนุนสิ่งนี้';
	@override String get generic => 'สิ่งบางอย่างผิดพลาด ลองอีกครั้ง';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$th extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'ดาวน์โหลดจะหยุดเมื่อคุณออกจากแอป';
	@override String get bannerDegraded => 'ดาวน์โหลดพื้นหลังอาจ จํากัด';
	@override String get bannerAction => 'รายละเอียด';
	@override String get sheetTitle => 'ดาวน์โหลดพื้นหลังถูกบล็อก';
	@override String get sheetTitleDegraded => 'ดาวน์โหลดพื้นหลังอาจ จํากัด';
	@override String get sheetIntro => 'Android จะป้องกันไม่ให้ PlezyNG ดาวน์โหลดได้อย่างน่าเชื่อถือในพื้นหลัง';
	@override String get sheetIntroDegraded => 'อุปกรณ์ของคุณจะ จํากัด เมื่อ PlezyNG สามารถดาวน์โหลดในพื้นหลัง';
	@override String get reasonBackgroundRestricted => 'การใช้พื้นหลังของ PlezyNG ถูก จํากัด การใช้แบตเตอรี่หรือพื้นหลังของมันจะตั้งค่าเป็น "ไม่ จํากัด"';
	@override String get reasonStandbyRestricted => 'Android ได้วาง PlezyNG ในสถานะยืนที่ จํากัด การใช้แบตเตอรี่ของมันตั้งค่าเป็น "ไม่ จํากัด"';
	@override String get reasonDownloadChannelBlocked => 'การแจ้งเตือนการดาวน์โหลดจะถูกเปิดใช้งานดังนั้นขั้นตอนและการควบคุมอาจไม่สามารถเข้าถึงได้';
	@override String get reasonNotificationsDisabled => 'การแจ้งเตือนถูกเปิดใช้งาน บน Android 13 หรือใหม่กว่าพวกเขาจําเป็นสําหรับการดาวน์โหลดพื้นหลังยาว';
	@override String get reasonDataSaver => 'Data Saver เป็นที่เปิดใช้งานซึ่งบล็อกการดาวน์โหลดพื้นหลังบนข้อมูลมือถือ ดาวน์โหลดยังคงทํางานบน Wi-Fi.';
	@override String get reasonOemUnknown => 'ดาวน์โหลดหยุดได้หลายครั้งในขณะที่ PlezyNG อยู่ในพื้นหลัง ตรวจสอบการตั้งค่าแบตเตอรี่หรือการใช้งานพื้นหลังของ PlezyNG';
	@override String get openSettings => 'การตั้งค่าเปิด';
	@override String get stillNotWorking => 'อุปกรณ์พิเศษความช่วยเหลือ';
	@override String get stillNotWorkingDescription => 'ดูขั้นตอนสําหรับอุปกรณ์ของคุณหรือส่งบันทึกจากตั้งค่า › ดูบันทึกถ้าปัญหายังคงอยู่';
	@override String get dialogTitle => 'ดาวน์โหลดอาจไม่เสร็จสิ้น';
	@override String get dialogDownloadAnyway => 'ดาวน์โหลดอย่างไรก็ตาม';
	@override String get dialogFixFirst => 'แก้ไขสิ่งนี้ก่อน';
	@override String get statusTile => 'ดาวน์โหลดพื้นหลัง';
	@override String get statusOk => 'อนุญาตให้ทํางานในพื้นหลัง';
	@override String get statusBlocked => 'บล็อกโดยการตั้งค่าระบบ';
	@override String get statusDegraded => 'จํากัด โดยการตั้งค่าระบบ';
	@override String get statusUnknown => 'ไม่ได้ตรวจสอบ';
	@override String get settingsUnavailable => 'ไม่สามารถเปิดการตั้งค่าระบบบนอุปกรณ์นี้ได้';
	@override String get linkUnavailable => 'ไม่สามารถเปิด dontkillmyapp.com บนอุปกรณ์นี้';
}

// Path: downloads.groupings
class _Translations$downloads$groupings$th extends Translations$downloads$groupings$en {
	_Translations$downloads$groupings$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get library => 'คลังสื่อ';
	@override String get collections => 'คอลเลกชัน';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$th extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'เริ่มต้นเซิร์ฟเวอร์ระยะไกล';
	@override String get hostAddress => 'ที่อยู่โฮสต์';
	@override String get connected => 'เชื่อมต่อ';
	@override String get serverRunning => 'เซิร์ฟเวอร์ระยะไกลที่ใช้งานได้';
	@override String get serverStopped => 'เซิร์ฟเวอร์ระยะไกลหยุด';
	@override String get serverRunningDescription => 'อุปกรณ์มือถือบนเครือข่ายของคุณสามารถเชื่อมต่อกับแอปนี้';
	@override String get serverStoppedDescription => 'เปิดเซิร์ฟเวอร์เพื่อให้อุปกรณ์มือถือสามารถเชื่อมต่อได้';
	@override String get usePhoneToControl => 'ใช้อุปกรณ์มือถือของคุณเพื่อควบคุมแอปนี้';
	@override String get startServer => 'เริ่มต้นเซิร์ฟเวอร์';
	@override String get stopServer => 'ปิดเซิร์ฟเวอร์';
	@override String get minimize => 'minimizing';
	@override String get manualAddressHint => 'ที่อยู่การเชื่อมต่อแบบคู่มือ:';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$th extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'PlezyNG อุปกรณ์ที่มีบัญชี Plex ที่ปรากฏที่นี่';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'การเชื่อมต่อ...';
	@override String get searchingForDevices => 'ค้นหาอุปกรณ์';
	@override String get noDevicesFound => 'ไม่มีอุปกรณ์ที่พบในเครือข่ายของคุณ';
	@override String get noDevicesHint => 'เปิด PlezyNG บนโต๊ะทํางานและใช้ Wi-Fi';
	@override String get availableDevices => 'อุปกรณ์ที่มีอยู่';
	@override String get manualConnection => 'การเชื่อมต่อคู่มือ';
	@override String get cryptoInitFailed => 'ไม่สามารถเริ่มต้นการเชื่อมต่อที่ปลอดภัยลงชื่อเข้าสู่ระบบที่ Plex ก่อน';
	@override String get validationHostRequired => 'กรุณาเข้าสู่ที่อยู่อาศัยโฮสต์';
	@override String get validationHostFormat => 'รูปแบบจะต้องเป็น IP:port (เช่น 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'การเชื่อมต่อหมดเวลา ใช้เครือข่ายเดียวกันบนทั้งสองอุปกรณ์';
	@override String get sessionNotFound => 'อุปกรณ์ไม่ได้พบ ตรวจสอบให้แน่ใจว่า PlezyNG ทํางานบนโฮสต์';
	@override String get authFailed => 'การรับรองไม่สามารถรับรองได้ ทั้งสองอุปกรณ์ต้องการบัญชี Plex ที่เดียวกัน';
	@override String failedToConnect({required Object error}) => 'ไม่สามารถเชื่อมต่อได้: ${error}';
	@override String get codeTitle => 'คู่รหัส';
	@override String get codeDescription => 'ใส่รหัสที่แสดงใน Companion Remote บนอุปกรณ์โฮสต์ ทั้งสองอุปกรณ์จะต้องใช้รุ่นที่สนับสนุนการเชื่อมต่อที่ปลอดภัย';
	@override String get codeInvalid => 'ใส่ทั้งหมด 32 หมายเลขและหมายเลขจากรหัสโฮสต์';
	@override String get updateRequired => 'ปรับปรุงทั้งอุปกรณ์ไปยังรุ่นที่สนับสนุนการเชื่อมต่อที่ปลอดภัย';
	@override String get hostDescription => 'ใส่รหัสนี้ครั้งเดียวในแต่ละระยะไกล ปกป้องความเป็นส่วนตัว: มันให้การควบคุมของโปรไฟล์นี้';
	@override String get resetCode => 'คู่รหัสรีเซ็ต';
	@override String get resetDescription => 'ปิดการเชื่อมต่อทั้งหมดและสร้างรหัสใหม่แต่ละรหัสจะจําเป็นต้องคู่อีกครั้ง';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$th extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'คุณต้องการปิดการเชื่อมต่อจากเซสชั่นระยะไกลหรือไม่';
	@override String get reconnecting => 'การเชื่อมต่อ...';
	@override String attemptOf({required Object current}) => 'การทดลอง ${current} ของ 5';
	@override String get retryNow => 'กลับตอนนี้';
	@override String get tabRemote => 'ระยะไกล';
	@override String get tabPlay => 'เล่น';
	@override String get tabMore => 'เพิ่มเติม';
	@override String get menu => 'โมดูล';
	@override String get tabNavigation => 'แท็บ Navigation';
	@override String get tabDiscover => 'ค้นหา';
	@override String get tabLibraries => 'ห้องสมุด';
	@override String get tabSearch => 'ค้นหา';
	@override String get tabDownloads => 'รายการดาวน์โหลด';
	@override String get tabSettings => 'การตั้งค่า';
	@override String get previous => 'ก่อนหน้านี้';
	@override String get playPause => 'เล่น / ปาก';
	@override String get next => 'ถัดไป';
	@override String get seekBack => 'ค้นหากลับ';
	@override String get stop => 'หยุด';
	@override String get seekForward => 'ค้นหา FWD';
	@override String get volume => 'จํานวน';
	@override String get volumeDown => 'ลง';
	@override String get volumeUp => 'ขึ้น';
	@override String get fullscreen => 'เต็มหน้าจอ';
	@override String get subtitles => 'คำบรรยาย';
	@override String get audio => 'เสียง';
	@override String get searchHint => 'ค้นหาบน Desktop';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$th extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'ไม่พบอินเตอร์เฟซเครือข่าย';
	@override String get authenticationFailed => 'การรับรองล้มเหลว';
	@override String serverStartFailed({required Object error}) => 'ไม่สามารถเริ่มต้นเซิร์ฟเวอร์ระยะไกลได้: ${error}';
	@override String commandFailed({required Object error}) => 'ไม่สามารถส่งคําสั่งจากระยะไกล: ${error}';
	@override String get joinTimedOut => 'เวลาในการเข้าร่วมประชุม';
	@override String get failedToConnectAnyAddress => 'ไม่สามารถเชื่อมต่อไปยังที่อยู่ใด ๆ';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'การเชื่อมต่อที่สูญเสียหลังจาก ${attempts} การพยายาม';
	@override String get connectionLost => 'การเชื่อมต่อที่สูญเสีย';
}

// Path: services.names
class _Translations$services$names$th extends Translations$services$names$en {
	_Translations$services$names$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class _Translations$services$simklReconnect$th extends Translations$services$simklReconnect$en {
	_Translations$services$simklReconnect$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'การเชื่อมต่อใหม่ Simkl';
	@override String get subtitle => 'Simkl จะลบวิธีการลงชื่อเข้าใช้การเชื่อมต่อนี้ ใช้ การเชื่อมต่อใหม่เปิด simkl.com เพื่อให้ได้รับการอนุมัติ PlezyNG — PlezyNG ไม่เคยเห็นรหัสผ่านของคุณ ประวัตินาฬิกาของคุณยังคงอยู่บน Simkl.';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$th extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'เปิดใช้งาน PlezyNG บน ${service}';
	@override String get instructions => 'สแกนรหัส QR หรือเยี่ยมชมที่อยู่ด้านล่างและป้อนรหัสนี้:';
	@override String openToActivate({required Object service}) => 'เปิด ${service} เพื่อเปิดใช้งาน';
	@override String get copyCode => 'คัดลอกรหัสการใช้งาน';
	@override String get waitingForAuthorization => 'รอการรับอนุญาต ...';
	@override String get codeCopied => 'รหัสคัดลอก';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$th extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'ลงชื่อเข้าสู่ระบบ ${service}';
	@override String get body => 'สแกนรหัส QR นี้หรือเปิด URL บนอุปกรณ์ใด ๆ';
	@override String openToSignIn({required Object service}) => 'เปิด ${service} เพื่อลงทะเบียน';
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$th extends Translations$services$pendingAuth$en {
	_Translations$services$pendingAuth$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'คัดลอก sign-in URL';
	@override String get urlCopied => 'URL คัดลอก';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$th extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$th._(TranslationsTh root) : this._root = root, super.internal(root);

	final TranslationsTh _root; // ignore: unused_field

	// Translations
	@override String get title => 'ห้องสมุดกรอง';
	@override String get subtitleAllSyncing => 'การซิงค์สมุดทั้งหมด';
	@override String get subtitleNoneSyncing => 'ไม่มีการสังเคราะห์';
	@override String subtitleBlocked({required Object count}) => '${count} บล็อก';
	@override String subtitleAllowed({required Object count}) => '${count} อนุญาต';
	@override String get mode => 'โหมดกรอง';
	@override String get modeBlacklist => 'แบล็คลิสต์';
	@override String get modeWhitelist => 'บลอนด์';
	@override String get modeHintBlacklist => 'การซิงค์ทุกห้องสมุดยกเว้นที่ตรวจสอบด้านล่าง';
	@override String get modeHintWhitelist => 'Sync เท่านั้นห้องสมุดที่ตรวจสอบด้านล่าง';
	@override String get libraries => 'ห้องสมุด';
	@override String get noLibraries => 'ไม่มีห้องสมุด';
}

/// The flat map containing all translations for locale <th>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsTh {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'cast.chooseDevice' => 'แคสต์ไปยังอุปกรณ์',
			'cast.searching' => 'ค้นหาอุปกรณ์ Cast ...',
			'cast.connectedTo' => ({required Object device}) => 'เชื่อมต่อ ${device}',
			'cast.device' => 'อุปกรณ์แคสต์',
			'cast.readyToCast' => 'พร้อมแคสต์',
			'cast.subtitle' => 'คำบรรยาย',
			'cast.serverNotAvailable' => 'เซิร์ฟเวอร์สื่อไม่สามารถใช้ได้',
			'cast.stopCasting' => 'หยุดแคสต์',
			'cast.castToDevice' => 'แคสต์ไปยังอุปกรณ์',
			'cast.noEpisodeAvailable' => 'ไม่มีส่วนที่สามารถปล่อยตัวได้',
			'cast.startFailed' => 'ไม่สามารถเริ่ม casting ตรวจสอบเซิร์ฟเวอร์และลองอีกครั้ง',
			'automation.noActivePlayback' => 'ไม่มีเซสชั่นวิดีโอที่มีการใช้งานในการควบคุม',
			'automation.profileNotFound' => 'ที่ Plezy โปรไฟล์ไม่สามารถพบได้',
			'notifications.newEpisodeTitle' => 'ฉบับใหม่',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appIcon.title' => 'แอปไอคอน',
			'appIcon.defaultIcon' => 'ค่าเริ่มต้น',
			'appIcon.current' => 'หมายเลขรุ่น: Icon',
			'appIcon.locked' => 'การเข้าถึงอายุการใช้งานที่จําเป็น',
			'appIcon.lockedHint' => 'เริ่มต้นการทดสอบ 7 วันหรือล็อค PlezyNG สําหรับชีวิตเพื่อใช้ไอคอนทางเลือก',
			'appIcon.changeFailed' => 'ไม่สามารถเปลี่ยนแอปไอคอน',
			'appIcon.launcherHint' => 'สัญลักษณ์ใหม่จะปรากฏบนหน้าจอบ้านของคุณเมื่อคุณออกจาก PlezyNG',
			'appIcon.tvLauncherHint' => 'แบนเนอร์ใหม่จะปรากฏเมื่อคุณออกจาก PlezyNG. Android TV สามารถยังคงแสดงแบนเนอร์เก่าจนกว่าทีวีจะเปิดใหม่',
			'appIcon.names.midnight' => 'นมกลางคืน',
			'appIcon.names.ember' => 'คน',
			'appIcon.names.paper' => 'กระดาษ',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => 'สาย',
			'appIcon.names.ocean' => 'ชายหาด',
			'appIcon.names.ultraviolet' => 'อัลตราไวโอเลต',
			'appIcon.names.matcha' => 'การแข่งขัน',
			'appIcon.names.sunset' => 'กุหลาบ',
			'appIcon.names.gold' => 'เหรียญ',
			'appIcon.names.titanium' => 'ไทเทเนียม',
			'appIcon.names.glass' => 'กระจก',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => 'ซินเทจ',
			'appIcon.names.pixel' => 'พิกเซล',
			'appIcon.names.neon' => 'ไนโอน',
			'appIcon.names.sticker' => 'สติ๊กเกอร์',
			'appIcon.names.ticket' => 'ตั๋ว',
			'appIcon.names.pop' => 'โป๊',
			'appIcon.names.strata' => 'แพทย์',
			'appIcon.names.facet' => 'หน้า',
			'appIcon.names.tilde' => 'ตุ๊กตา',
			'auth.signInWithPlex' => 'ลงทะเบียนกับ Plex',
			'auth.showQRCode' => 'แสดงรหัส QR',
			'auth.authenticate' => 'การรับรอง',
			'auth.authenticationTimeout' => 'การรับรองเป็นเวลาแล้ว โปรดลองอีกครั้ง',
			'auth.scanQRToSignIn' => 'สแกนรหัส QR นี้เพื่อลงทะเบียน',
			'auth.waitingForAuth' => 'รอการรับรอง... ลงทะเบียนจากเบราว์เซอร์ของคุณ',
			'auth.useBrowser' => 'ใช้เบราว์เซอร์',
			'auth.or' => 'หรือ',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'ติดต่อ ${product}',
			'auth.quickConnect' => 'Quick Connect',
			'auth.useQuickConnect' => 'ใช้การเชื่อมต่อด่วน',
			'auth.quickConnectInstructions' => 'เปิด Quick Connect ใน Jellyfin และป้อนรหัสนี้',
			'auth.quickConnectWaiting' => 'รอการอนุมัติ',
			'auth.quickConnectCancel' => 'ยกเลิก',
			'auth.quickConnectExpired' => 'Quick Connect หมดอายุ ลองอีกครั้ง',
			'auth.localDataRecoveryRequired' => 'PlezyNG ไม่สามารถคืนข้อมูลการลงชื่อเข้าและข้อมูลการสะท้อนกลับในท้องถิ่นได้อย่างปลอดภัย โปรดลงชื่อเข้าอีกครั้ง',
			'auth.pinCheckRejected' => 'การตรวจสอบ PIN Plex ได้รับการปฏิเสธ',
			'auth.connectToDirectPlex' => 'เชื่อมต่อกับเซิร์ฟเวอร์ท้องถิ่น Plex',
			'common.cancel' => 'ยกเลิก',
			'common.save' => 'บันทึก',
			'common.close' => 'ปิด',
			'common.clear' => 'หมายเหตุ',
			'common.reset' => 'รีเซ็ต',
			'common.later' => 'ต่อไป',
			'common.submit' => 'ส่ง',
			'common.confirm' => 'การยืนยัน',
			'common.retry' => 'การคืนเงิน',
			'common.logout' => 'ปล่อยออก',
			'common.unknown' => 'ที่เก็บข้อมูลไม่รู้จัก',
			'common.refresh' => 'การทําความเย็น',
			'common.yes' => 'ใช่',
			'common.no' => 'ไม่',
			'common.delete' => 'ลบ',
			'common.edit' => 'แก้ไข',
			'common.shuffle' => 'สุ่มเล่น',
			'common.addTo' => 'เพิ่มให้...',
			'common.createNew' => 'สร้างใหม่',
			'common.connect' => 'เชื่อมต่อ',
			'common.disconnect' => 'ยกเลิกการเชื่อมต่อ',
			'common.play' => 'เล่น',
			'common.pause' => 'หยุดชั่วคราว',
			'common.resume' => 'เล่นต่อ',
			'common.error' => 'ข้อผิดพลาด',
			'common.search' => 'ค้นหา',
			'common.home' => 'บ้าน',
			'common.back' => 'กลับ',
			'common.settings' => 'การตั้งค่า',
			'common.mute' => 'ปกติ',
			'common.ok' => 'ตกลง',
			'common.off' => 'ปิด',
			'common.options' => 'ตัวเลือก',
			'common.seasonNumber' => ({required Object number}) => 'ฤดูกาล ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'ฉบับที่ ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'ประเภท ${number}',
			'common.reconnect' => 'การเชื่อมต่อ',
			'common.viewAll' => 'ดูทั้งหมด',
			'common.checkingNetwork' => 'การตรวจสอบเครือข่าย',
			'common.loadingServers' => 'เซิร์ฟเวอร์โหลด',
			'common.connectingToServers' => 'การเชื่อมต่อกับเซิร์ฟเวอร์',
			'common.startingOfflineMode' => 'เริ่มต้นแบบ offline...',
			'common.loading' => 'การโหลด...',
			'common.fullscreen' => 'เต็มหน้าจอ',
			'common.exitFullscreen' => 'หน้าจอแสดงผลเต็ม',
			'common.pressBackAgainToExit' => 'คลิกกลับเพื่อออก',
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
			'common.notAvailable' => 'หมายเลขรุ่น: A',
			'common.url' => 'URL',
			'common.letterKeys' => 'ABC',
			'common.mediaKind.movie' => 'ภาพยนตร์',
			'common.mediaKind.show' => 'แสดง',
			'common.mediaKind.season' => 'ซีซัน',
			'common.mediaKind.episode' => 'ตอน',
			'common.mediaKind.artist' => 'ศิลปิน',
			'common.mediaKind.album' => 'อัลบั้ม',
			'common.mediaKind.track' => 'ล้อ',
			'common.mediaKind.collection' => 'การจัดเก็บ',
			'common.mediaKind.playlist' => 'เพลย์ลิสต์',
			'common.mediaKind.clip' => 'คลิก',
			'common.mediaKind.photo' => 'ภาพถ่าย',
			'common.mediaKind.folder' => 'แผง',
			'screens.licenses' => 'ใบอนุญาต',
			'screens.switchProfile' => 'โปรไฟล์สวิทช์',
			'screens.subtitleStyling' => 'สไตล์ Subtitle',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'โลก',
			'update.available' => 'การปรับปรุงที่มีอยู่',
			'update.versionAvailable' => ({required Object version}) => 'รุ่น ${version} มีอยู่',
			'update.currentVersion' => ({required Object version}) => 'อัพเดท: ${version}',
			'update.skipVersion' => 'ดาวน์โหลดเวอร์ชันนี้',
			'update.viewRelease' => 'ดูการปล่อย',
			'update.latestVersion' => 'คุณอยู่ในเวอร์ชันล่าสุด',
			'update.checkFailed' => 'ไม่สามารถตรวจสอบอัปเดตได้',
			'appAccess.title' => 'ลองทุกฟังก์ชั่นฟรีสําหรับ 7 วัน',
			'appAccess.description' => 'เริ่มต้นการทดลองใช้ 7 วันพร้อมการเข้าถึงเต็มรูปแบบทุกฟังก์ชั่น PlezyNG ไม่มีค่าธรรมเนียมในระหว่างการทดลองใช้และไม่มีการสมัครสมาชิก หลังจากทดลองใช้การซื้อตลอดชีวิตในราคาของร้านค้าของคุณเปิดใช้งาน PlezyNGตลอดชีวิต',
			'appAccess.trialEndedDescription' => 'ปล็อคฟังก์ชั่นทุกฟังก์ชั่นที่ PlezyNG สําหรับชีวิตด้วยการซื้อเดียวในราคาของร้านค้าของคุณ ไม่มีสมาชิก',
			'appAccess.startTrial' => 'เริ่มต้นการทดลองฟรี 7 วัน',
			'appAccess.trialActive' => 'การทดสอบเต็มรูปแบบ 7 วันของคุณจะใช้งานได้',
			'appAccess.trialEnded' => 'การสอบถาม 7 วันของคุณจบลง',
			'appAccess.trialStartFailed' => 'ฉันไม่สามารถบันทึกการทดสอบบนอุปกรณ์นี้ โปรดลองอีกครั้ง',
			'appAccess.lifetimeTitle' => 'PlezyNG ปิดล็อคสําหรับชีวิต',
			'appAccess.lifetimeBody' => 'ขอบคุณ! คุณสามารถเข้าถึงทุกฟังก์ชั่น PlezyNG ทุกชีวิต',
			'appAccess.manageTitle' => 'PlezyNG การเข้าถึงตลอดชีวิต',
			'appAccess.manageDescription' => 'ลองฟังก์ชั่นแต่ละอย่างฟรีเป็นเวลา 7 วันแล้วเปิดเปิดทุกอย่างตลอดชีวิตด้วยค่าใช้จ่ายเดียวในราคาของร้านค้าของคุณ',
			'appAccess.buy' => ({required Object price}) => 'ปล็อคฟังก์ชั่นทั้งหมดสําหรับ ${price}',
			'appAccess.loadingPrice' => 'ราคาของร้านขายส่ง',
			'appAccess.retryPrice' => 'ค่าใช้จ่าย Retry Lookup',
			'appAccess.restore' => 'การซื้อคืนชีวิต',
			'appAccess.pending' => 'การซื้อของคุณกําลังรอการชําระเงินหรือการอนุมัติ การเข้าถึงตลอดชีวิตจะเปิดตัวทันทีที่ร้านค้าเสร็จสมบูรณ์',
			'appAccess.storeUnavailable' => 'การซื้อไม่สามารถใช้ได้ ตรวจสอบว่าคุณลงชื่อเข้าสู่ร้านค้าและการซื้อจะได้รับอนุญาตบนอุปกรณ์นี้',
			'appAccess.productNotFound' => 'PlezyNG ชีวิตล็อคยังไม่ได้อยู่ในร้านค้านี้',
			'appAccess.productQueryFailed' => 'ไม่สามารถโหลดราคาร้านค้าได้ ตรวจสอบการเชื่อมต่อของคุณและลองอีกครั้ง',
			'appAccess.purchaseFailed' => 'การซื้อไม่ได้ผ่านการทดลองอีกครั้ง',
			'appAccess.restoreFailed' => 'ฉันไม่สามารถเข้าถึงร้านค้าเพื่อรับคืนการซื้อของคุณ ลองอีกครั้ง',
			'appAccess.nothingToRestore' => 'หมายเลขการซื้อตลอดชีวิต PlezyNG ได้รับการค้นหาสําหรับบัญชีร้านค้านี้',
			'settings.title' => 'การตั้งค่า',
			'settings.supportDeveloper' => 'สนับสนุน PlezyNG',
			'settings.supportDeveloperDescription' => 'การสนับสนุนการพัฒนา',
			'settings.lifetimeAccess' => 'PlezyNG การเข้าถึงตลอดชีวิต',
			'settings.language' => 'ภาษา',
			'settings.theme' => 'ธีม',
			'settings.appearance' => 'แสดง',
			'settings.detailPage' => 'รายละเอียดหน้า',
			'settings.themeSongsEnabled' => 'เล่นหัวข้อเพลง',
			'settings.themeSongsEnabledDescription' => 'เล่นเพลงธีมที่มีอยู่ในขณะที่ดูรายละเอียดสื่อ',
			'settings.themeSongVolume' => 'ธีมเพลงปริมาณ',
			'settings.videoPlayback' => 'วิดีโอ Playback',
			'settings.videoPlaybackDescription' => 'การตั้งค่าพฤติกรรม playback',
			'settings.advanced' => 'ขั้นสูง',
			'settings.episodePosterMode' => 'โพสต์สไตล์',
			'settings.seriesPoster' => 'โพสต์ชุด',
			'settings.seasonPoster' => 'โพสต์ฤดูกาล',
			'settings.episodeThumbnail' => 'วินเทจ',
			'settings.showHeroSectionDescription' => 'แสดงเนื้อหา carousel บนหน้าจอบ้าน',
			'settings.secondsLabel' => 'วินาที',
			'settings.minutesLabel' => 'นาที',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'ม',
			'settings.durationHint' => ({required Object min, required Object max}) => 'ใส่ค่า (${min}-${max})',
			'settings.systemTheme' => 'ระบบ',
			'settings.lightTheme' => 'แสง',
			'settings.darkTheme' => 'ดํา',
			'settings.oledTheme' => 'OLED',
			'settings.emberTheme' => 'คน',
			'settings.glacierTheme' => 'เหล็กกล้า',
			'settings.forestTheme' => 'สวน',
			'settings.plumTheme' => 'ปลั๊ก',
			'settings.paperTheme' => 'กระดาษ',
			'settings.libraryDensity' => 'ความหนาแน่นของห้องสมุด',
			'settings.displayScale' => 'แสดง Scale',
			'settings.compact' => 'คอมโพสิต',
			'settings.comfortable' => 'ความสะดวกสบาย',
			'settings.gridSpacing' => 'ไฟฉาย',
			'settings.gridSpacingTight' => 'ตูด',
			'settings.gridSpacingNormal' => 'หลักสูตร',
			'settings.gridSpacingSpacious' => 'สเปค',
			'settings.tvCornerSpotlightBackdrop' => 'คอร์เนอร์ Spotlight Backdrop',
			'settings.tvCornerSpotlightBackdropDescription' => 'แสดงงานศิลปะในมุมด้านบนขวาแทนที่จะเติมหน้าจอ',
			'settings.viewMode' => 'ดูแฟชั่น',
			'settings.gridView' => 'กด',
			'settings.listView' => 'รายการ',
			'settings.showHeroSection' => 'แสดงส่วนฮีโร่',
			'settings.showHomeBackdrop' => 'แสดง บ้าน Backdrop Artwork',
			'settings.showHomeBackdropDescription' => 'แสดงงานศิลปะขนาดใหญ่ด้านหลังของเรือนบ้าน',
			'settings.contentScreensaverEnabled' => 'แสดงเนื้อหา',
			'settings.contentScreensaverEnabledDescription' => 'แสดงงานศิลปะเต็มหน้าจอหลังจากที่แอปเป็น idle',
			'settings.contentScreensaverDelay' => 'เปิดหน้าจอซอฟต์แวร์หลังจาก',
			'settings.contentScreensaverLibraries' => 'สกรีนซอฟต์แวร์',
			'settings.contentScreensaverLibrariesDescription' => 'เลือกห้องสมุดที่จัดหางานศิลปะที่บันทึกหน้าจอ หากไม่มีการเลือกงานศิลปะจากห้องสมุดทั้งหมดจะใช้',
			'settings.contentScreensaverAllLibraries' => 'ทุกไลบรารี',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} ห้องสมุดที่เลือก',
			'settings.contentScreensaverNoLibraries' => 'ไม่มีห้องสมุดสื่อที่เชื่อมต่อ',
			'settings.contentScreensaverDismissHint' => 'คลิกที่ปุ่มหรือปุ่มใด ๆ เพื่อยกเลิก',
			'settings.newEpisodeNotifications' => 'การแจ้งเตือนฉบับใหม่',
			'settings.newEpisodeNotificationsDescription' => 'บันทึกเมื่อส่วนใหม่จะถูกเพิ่มไปสู่การแสดงที่คุณจะถูกจับได้ ตรวจสอบในขณะที่ Plezy เปิด',
			'settings.continueWatchingRowSize' => 'เก็บดูขนาดแถว',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => '${label} บัตร',
			'settings.rowSizeCompact' => 'คอมโพสิต',
			'settings.rowSizeStandard' => 'มาตรฐาน',
			'settings.rowSizeLarge' => 'ใหญ่',
			'settings.continueWatchingAction' => 'การดําเนินการต่อการตรวจสอบ',
			'settings.continueWatchingPlay' => 'เล่น',
			'settings.continueWatchingDetails' => 'รายละเอียดเปิด',
			'settings.episodeAction' => 'การกระทํา',
			'settings.episodePlay' => 'เล่น',
			'settings.episodeDetails' => 'รายละเอียดเปิด',
			'settings.useGlobalHubs' => 'ใช้ Home Layout',
			'settings.useGlobalHubsDescription' => 'แสดงช่องบ้านแบบบูรณาการ ไม่ได้ใช้คําแนะนําของห้องสมุด',
			'settings.showServerNameOnHubs' => 'แสดงชื่อเซิร์ฟเวอร์บน Hubs',
			'settings.showServerNameOnHubsDescription' => 'แสดงชื่อเซิร์ฟเวอร์เสมอในหัวข้อ hub',
			'settings.groupLibrariesByServer' => 'ห้องสมุดกลุ่มโดย Server',
			'settings.groupLibrariesByServerDescription' => 'ห้องสมุดหน้ากลุ่มภายใต้เซิร์ฟเวอร์สื่อแต่ละครั้ง',
			'settings.alwaysKeepSidebarOpen' => 'ปล่อยให้หน้าต่างเปิดเสมอ',
			'settings.alwaysKeepSidebarOpenDescription' => 'บาร์ด้านข้างยังคงขยายและพื้นที่เนื้อหาปรับให้เหมาะสม',
			'settings.showUnwatchedCount' => 'แสดง Unwatched Count',
			'settings.showUnwatchedCountDescription' => 'แสดง episodes unwatched count on shows and seasons',
			'settings.showWatchedIndicators' => 'แสดงตัวชี้วัดที่ได้รับการตรวจสอบ',
			'settings.showWatchedIndicatorsDescription' => 'แสดงการตรวจสอบในภาพยนตร์การแสดงผลและ episodes ที่เห็น',
			'settings.showEpisodeNumberOnCards' => 'แสดง Episode Number on Cards',
			'settings.showEpisodeNumberOnCardsDescription' => 'แสดงฤดูกาลและหมายเลข episodes บนการ์ด episodes',
			'settings.showSeasonPostersOnTabs' => 'แสดงกระดานฤดูกาลบนแท็บ',
			'settings.showSeasonPostersOnTabsDescription' => 'แสดงโพสต์ของแต่ละฤดูกาลด้านบนแท็บของมัน',
			'settings.tvFullCardLayout' => 'หมายเลขโทรทัศน์เต็ม',
			'settings.tvFullCardLayoutDescription' => 'ใช้การ์ดทีวีรูปภาพเท่านั้นที่มีชื่อนักแสดง',
			'settings.focusGlow' => 'ไฟฉาย',
			'settings.focusGlowDescription' => 'ดําเนินการแสงอ่อนรอบคอบการ์ดที่มุ่งเน้น',
			'settings.visualEffects' => 'ผลการมองเห็น',
			'settings.visualEffectsAuto' => 'อัตโนมัติ',
			'settings.visualEffectsAutoDescription' => 'ลดผลกระทบโดยอัตโนมัติบนอุปกรณ์ที่มีพลังงานต่ํา',
			'settings.visualEffectsFull' => 'เต็ม',
			'settings.visualEffectsReduced' => 'ลดลง',
			'settings.visualEffectsReducedDescription' => 'การเคลื่อนไหวน้อยและงานศิลปะที่มีความละเอียดต่ํา',
			'settings.hideSpoilers' => 'ซ่อน Spoilers สําหรับ Episodes Unwatched',
			'settings.hideSpoilersDescription' => 'บลูรไทม์และคําอธิบายสําหรับ episodes ที่ไม่ได้สังเกต',
			'settings.playerBackend' => 'ผู้เล่น Backend',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'การเข้ารหัสฮาร์ดแวร์',
			'settings.hardwareDecodingDescription' => 'ใช้ความเร็วฮาร์ดแวร์เมื่อมี',
			'settings.playbackBuffer' => 'บูฟเวอร์ Playback',
			'settings.playbackBufferAuto' => 'รถยนต์ (แนะนํา)',
			'settings.playbackBufferLarge' => 'ใหญ่',
			'settings.playbackBufferExtraLarge' => 'ขนาดใหญ่',
			'settings.playbackBufferDescription' => 'Buffer มากกว่าต่อการเชื่อมต่อที่ไม่เสถียร นอกจากนี้ยัง จํากัด โดย ขนาด Buffer',
			'settings.streamBufferSize' => 'ขนาด Buffer',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} MB',
			'settings.streamBufferSizeDescription' => 'จํานวนวิดีโอที่จะโหลดก่อนเมื่อเล่นโดยตรง Transcodes stop at the server\'s own transcode buffer. 0 = Auto',
			'settings.streamBufferSizeExoNote' => 'แทนที่ Playback Buffer เมื่อตั้งค่า, capped ที่ครึ่งของขอบหน่วยความจําของแอป',
			'settings.streamBufferMegabytes' => 'มกเบตต์',
			'settings.defaultQualityTitle' => 'คุณภาพที่กําหนดเอง',
			'settings.cellularQualityTitle' => 'คุณภาพที่กําหนดเองในเซลล์',
			'settings.remoteQualityTitle' => 'คุณภาพ Streaming ออนไลน์',
			'settings.remoteQualitySameAsDefault' => 'เช่นเดียวกับคุณภาพที่กําหนดเอง',
			'settings.cellularQualitySameAsDefault' => 'เช่นเดียวกับคุณภาพที่กําหนดเอง',
			'settings.directPlayCoveredQuality' => 'เล่นวิดีโอขนาดเล็กในคุณภาพเดิม',
			'settings.directPlayCoveredQualityDescription' => 'การเล่นวิดีโอโดยตรงอยู่ภายในข้อ จํากัด คุณภาพแทนที่จะรหัสพวกเขา',
			'settings.videoCodecs' => 'วีดีโอโค้ด',
			'settings.videoCodecsDescription' => 'โคเด็กที่ไม่ได้ตรวจสอบจะถูกรหัสผ่านโดยเซิร์ฟเวอร์',
			'settings.videoCodecsAlwaysAccepted' => 'ได้รับการยอมรับเสมอ',
			'settings.musicQualityTitle' => 'คุณภาพเพลง',
			'settings.subtitleStyling' => 'สไตล์ Subtitle',
			'settings.subtitleStylingDescription' => 'การปรับแต่งการปรากฏตัว Subtitle',
			'settings.smallSkipDuration' => 'ระยะเวลาสกีขนาดเล็ก',
			'settings.largeSkipDuration' => 'ระยะเวลา Skip',
			'settings.rewindOnResume' => 'กลับไปสู่การสรุป',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(seconds, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} วินาที', ), 
			'settings.defaultSleepTimer' => 'ระยะเวลาการนอนหลับแบบกําหนดเอง',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(minutes, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} นาที', ), 
			'settings.rememberTrackSelections' => 'โปรดจําการเลือกติดตามตามแสดง / ภาพยนตร์',
			'settings.chooseTracksBeforePlayback' => 'เลือกเสียงและหัวข้อก่อนที่จะเล่น',
			'settings.chooseTracksBeforePlaybackDescription' => 'เลือกเสียงแหล่งที่มาและติดตามหัวข้อก่อนที่จะเริ่มต้นวิดีโอแต่ละครั้ง',
			'settings.alwaysShowSubtitlesOnDevice' => 'แสดงหัวข้อในอุปกรณ์นี้เสมอ',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => 'เมื่อเซิร์ฟเวอร์ไม่มีหัวข้อที่เลือกให้เลือกเส้นทางในท้องถิ่น สิ่งนี้ไม่เปลี่ยนแปลงความต้องการของเซิร์ฟเวอร์',
			'settings.autoDownloadPreferredSubtitle' => 'Fetch ปิดหัวข้อภาษาที่ชื่นชอบ',
			'settings.autoDownloadPreferredSubtitleDescription' => 'เลือกหัวข้อที่มีอยู่ในภาษาที่คุณต้องการในท้องถิ่น หากไม่มีหัวข้อใด ๆ โปรดขอให้เซิร์ฟเวอร์จับหัวข้อหนึ่งเมื่อมีการสนับสนุน ตัวเลือกจะอยู่บนอุปกรณ์นี้',
			'settings.rememberTrackSelectionsDescription' => 'การจัดเก็บเสียงและตัวเลือกหัวข้อโดยการแสดงหรือภาพยนตร์บนอุปกรณ์นี้',
			'settings.rememberTrackSelectionsBackendRule' => 'ทํางานในท้องถิ่นกับ Plex, Jellyfin, และ Emby; Plex และ Jellyfin นอกจากนี้ยังสามารถบันทึกตัวเลือกบนเซิร์ฟเวอร์',
			'settings.followServerTrackSelections' => 'ใช้ตัวเลือกติดตามต่อส่วนของเซิร์ฟเวอร์',
			'settings.followServerTrackSelectionsDescription' => 'เมื่อมีการเปลี่ยนแปลงส่วนหนึ่งใช้เสียงและหัวข้อที่เลือกไว้บนเซิร์ฟเวอร์แทนที่จะดําเนินการตามตัวเลือกปัจจุบัน',
			'settings.resumeMusicOnLaunch' => 'เสร็จสิ้นการประชุมดนตรี',
			'settings.resumeMusicOnLaunchDescription' => 'เปิดใหม่เพลงสุดท้ายหยุดที่มันออกเมื่อแอปเริ่มต้น',
			'settings.showChapterMarkersOnTimeline' => 'แสดงหมวดหมู่ บาร์ค้นหา',
			'settings.showChapterMarkersOnTimelineDescription' => 'Segment the search bar ที่ขอบเขตบท',
			'settings.specialsOrdering' => 'พิเศษในลําดับ episodes',
			'settings.specialsOrderingDescription' => 'ที่พิเศษเล่นในคําสั่งของชั่วโมงของแสดง',
			'settings.specialsOrderingServer' => 'ติดตามคําสั่งเซิร์ฟเวอร์',
			'settings.specialsOrderingAirDate' => 'ระยะเวลาตามวันที่อากาศ',
			'settings.specialsOrderingLast' => 'หลังจากฤดูกาลปกติ',
			'settings.clickVideoTogglesPlayback' => 'คลิกที่วิดีโอเพื่อ toggle play/pause',
			'settings.clickVideoTogglesPlaybackDescription' => 'คลิกวิดีโอเพื่อเล่น/หยุดแทนที่จะแสดงการควบคุม',
			'settings.videoPlayerControls' => 'วิดีโอผู้เล่นควบคุม',
			'settings.keyboardShortcuts' => 'คีย์บอร์ด Shortcuts',
			'settings.keyboardShortcutsDescription' => 'ปรับแต่งคีย์บอร์ดสั้น ๆ',
			'settings.videoPlayerNavigation' => 'วีดีโอ Player Navigation',
			'settings.videoPlayerNavigationDescription' => 'ใช้คีย์ไฟเพื่อนําทางควบคุมวิดีโอเล่น',
			'settings.watchTogetherRelay' => 'ดู Relay ร่วมกัน',
			'settings.watchTogetherRelayDescription' => 'สาธารณะเปิด Watch ปาร์ตี้สื่อลามกถ้าคุณตั้งค่าของคุณเอง',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.watchTogetherRelayInvalid' => 'ป้อน URL หลักของเซิร์ฟเวอร์รีเลย์ที่ใช้ HTTP หรือ HTTPS ให้ถูกต้อง',
			'settings.crashReporting' => 'การแจ้งเตือนความเสียหาย',
			'settings.crashReportingDescription' => 'ส่งรายงานความล้มเหลวเพื่อช่วยปรับปรุงแอป',
			'settings.debugLogging' => 'การเข้าสู่ระบบ Debug',
			'settings.debugLoggingDescription' => 'อนุญาตให้บันทึกรายละเอียดสําหรับการแก้ปัญหา',
			'settings.viewLogs' => 'ดูโลโก้',
			'settings.viewLogsDescription' => 'ดูแอปพลิเคชันโลโก้',
			'settings.clearImageCache' => 'ภาพที่ชัดเจน cache',
			'settings.clearImageCacheDescription' => 'การทําศิลปะที่ซ่อนอยู่และรูปทรงขนาดเล็ก ภาพสามารถโหลดได้ช้าลงจนกว่าจะดาวน์โหลดอีกครั้ง',
			'settings.clearImageCacheSuccess' => 'ภาพ cache ทําความสะอาดอย่างประสบความสําเร็จ',
			'settings.resetSettings' => 'การตั้งค่าใหม่',
			'settings.resetSettingsDescription' => 'ปรับปรุงการตั้งค่าที่กําหนดเอง สิ่งนี้ไม่สามารถลบได้',
			'settings.resetSettingsSuccess' => 'การตั้งค่าใหม่ได้ดี',
			'settings.backup' => 'คู่มือ',
			'settings.exportSettings' => 'การตั้งค่าการส่งออก',
			'settings.exportSettingsDescription' => 'เก็บความต้องการของคุณไปยังไฟล์',
			'settings.exportSettingsSuccess' => 'การตั้งค่าที่ส่งออก',
			'settings.importSettings' => 'การตั้งค่าการนําเข้า',
			'settings.importSettingsDescription' => 'การกู้คืนความต้องการจากไฟล์',
			'settings.importSettingsConfirm' => 'สิ่งนี้จะเปลี่ยนการตั้งค่าปัจจุบันของคุณ ต่อเนื่อง?',
			'settings.importSettingsSuccess' => 'การตั้งค่าที่นําเข้า',
			'settings.importSettingsInvalidFile' => 'ไฟล์นี้ไม่ได้รับการส่งออกการตั้งค่า PlezyNG',
			'settings.importSettingsNoUser' => 'ลงทะเบียนก่อนนําเข้าการตั้งค่า',
			'settings.cloudBackup' => 'คล็อค Backup',
			'settings.cloudBackupDescription' => 'Backup settings portable to a WebDAV endpoint over HTTPS. การเชื่อมต่อเซิร์ฟเวอร์และการรับรองจะอยู่บนอุปกรณ์นี้',
			'settings.cloudBackupUrl' => 'WebDAV JSON ไฟล์ URL',
			'settings.cloudBackupUsername' => 'ชื่อผู้ใช้',
			'settings.cloudBackupPassword' => 'คู่มือ',
			'settings.cloudBackupSaved' => 'Cloud Backup destination ที่บันทึก',
			'settings.cloudBackupNow' => 'กลับขึ้นตอนนี้',
			'settings.cloudBackupComplete' => 'การตั้งค่า Backup upload',
			'settings.cloudBackupRestore' => 'การกู้คืน Backup',
			'settings.cloudBackupRestoreConfirm' => 'สิ่งนี้จะแทนที่การตั้งค่าแบบพกพาที่ตรงกับอุปกรณ์นี้. ต่อไป?',
			'settings.cloudBackupRestored' => 'การตั้งค่าที่ได้รับการกู้คืนจาก Cloud Backup',
			'settings.shortcutsReset' => 'ระยะสั้นที่กําหนดเอง',
			'settings.resetShortcutsConfirm' => 'นี่จะแทนที่การสั้น ๆ ที่กําหนดเองของคุณด้วยข้อกําหนดต่อไปหรือไม่?',
			'settings.about' => 'เกี่ยวกับ',
			'settings.aboutDescription' => 'ข้อมูลแอปและใบอนุญาต',
			'settings.updates' => 'ปรับปรุง',
			'settings.updateAvailable' => 'การปรับปรุงที่มีอยู่',
			'settings.checkForUpdates' => 'ตรวจสอบการปรับปรุง',
			'settings.autoCheckUpdatesOnStartup' => 'ตรวจสอบอัตโนมัติสําหรับอัปเดตใน Startup',
			'settings.autoCheckUpdatesOnStartupDescription' => 'บันทึกเมื่อมีการปรับปรุงพร้อมใช้งานเมื่อเปิดตัว',
			'settings.validationErrorEnterNumber' => 'กรุณาใส่หมายเลขที่ถูกต้อง',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'ต้องมีระหว่าง ${min} และ ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Shortcut ที่กําหนดไว้แล้ว ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Shortcut อัพเดทสําหรับ ${action}',
			'settings.saveFailed' => 'ไม่สามารถบันทึกการเปลี่ยนแปลงได้ ลองอีกครั้ง',
			'settings.autoPlayAndSkip' => 'อัตโนมัติ Play & Skip',
			'settings.autoPlayNextEpisode' => 'Auto-Play ฉบับต่อไป',
			'settings.autoPlayNextEpisodeDescription' => 'เริ่มต้นส่วนต่อไปโดยอัตโนมัติเมื่อหนึ่งสิ้นสุด',
			'settings.shuffleStartsFromBeginning' => 'Shuffle เริ่มต้น',
			'settings.shuffleStartsFromBeginningDescription' => 'เริ่มต้นแต่ละ epizode ในตอนเริ่มต้นเมื่อ shuffling แทนที่จะ reuming',
			'settings.plexCinemaPreRoll' => 'ใช้เซิร์ฟเวอร์ Cinema Intros',
			'settings.plexCinemaPreRollDescription' => 'เล่น Plex Pre-rolls หรือ Jellyfin และ Emby intros ที่กําหนดเองก่อนที่จะเริ่มภาพยนตร์',
			'settings.playNextCountdown' => 'เล่น Countdown ต่อไป',
			'settings.playNextCountdownImmediate' => 'เล่นทันที',
			'settings.skipIntroMode' => 'สไลด์อินเตอร์เน็ต',
			'settings.skipIntroModeOffDescription' => 'เล่น intros โดยปกติโดยไม่มีปุ่ม skip',
			'settings.skipIntroModeButtonDescription' => 'แสดงปุ่ม Skip เมื่อ intro เริ่มต้น',
			'settings.skipIntroModeAutoDescription' => 'สปินอินเตอร์โดยอัตโนมัติหลังจากการล่าช้าด้านล่าง',
			'settings.skipCreditsMode' => 'คิดสกี',
			'settings.skipCreditsModeOffDescription' => 'เล่นเครดิตโดยปกติโดยไม่มีปุ่ม skip',
			'settings.skipCreditsModeButtonDescription' => 'แสดงปุ่ม Skip เมื่อเครดิตเริ่มต้น',
			'settings.skipCreditsModeAutoDescription' => 'คลิกเครดิตโดยอัตโนมัติและเล่นส่วนต่อไป',
			'settings.skipAdsMode' => 'การโฆษณา Skip',
			'settings.skipAdsModeOffDescription' => 'เล่นโฆษณาที่ได้รับการตรวจพบโดยปกติโดยไม่มีปุ่มสปิก',
			'settings.skipAdsModeButtonDescription' => 'แสดงปุ่ม Skip เมื่อ Plex รู้สึกโฆษณา',
			'settings.skipAdsModeAutoDescription' => 'ลบโฆษณาที่ได้รับการตรวจพบโดยอัตโนมัติหลังจากการล่าช้าด้านล่าง',
			'settings.musicPlayback' => 'การเล่นเพลง',
			'settings.musicSweetFades' => 'หวาน',
			'settings.musicSweetFadesDescription' => 'ไฟล์เพลงบนแอนดคอร์เมื่อ Plex มีข้อมูลเสียง การเล่นอัลบั้มยังคงไม่เปลี่ยนแปลง',
			'settings.skipMarkerModeOff' => 'ปิด',
			'settings.skipMarkerModeButton' => 'แสดงปุ่ม',
			'settings.skipMarkerModeAuto' => 'อัตโนมัติ',
			'settings.forceSkipMarkerFallback' => 'แรงดันไฟฟ้า Fallback Markers',
			'settings.forceSkipMarkerFallbackDescription' => 'ใช้รูปแบบหัวข้อแม้ว่า Plex มีเครื่องหมาย',
			'settings.theIntroDbFallback' => 'ใช้ TheIntroDB เป็น intro fallback',
			'settings.theIntroDbFallbackDescription' => 'ใช้เวลาชุมชนเท่านั้นเมื่อเซิร์ฟเวอร์ไม่มีเครื่องหมายการเข้า การแข่งขันสามารถแตกต่างกันตามการปล่อย',
			'settings.autoSkipDelay' => 'รถยนต์ Skip ละลาย',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'รอ ${seconds} วินาทีก่อนที่จะสปินอัตโนมัติ',
			'settings.introPattern' => 'หมายเลขรุ่น: Intro Marker Pattern',
			'settings.introPatternDescription' => 'รูปแบบ Regex เพื่อตอบสนองตัวอักษรในหัวข้อ',
			'settings.creditsPattern' => 'หลักฐานการทําสัญญา',
			'settings.creditsPatternDescription' => 'รูปแบบ Regex เพื่อตอบสนองผู้รับรองในหัวข้อ',
			'settings.prerolls' => 'โพสต์',
			'settings.playPrerollsBeforeMovies' => 'เล่น prerolls ก่อนภาพยนตร์',
			'settings.playPrerollsBeforeMoviesDescription' => 'เล่นคลิปสุ่มจากตัวเลือกของคุณด้านล่างก่อนแต่ละภาพยนตร์ คลิกกลับเพื่อล่วงหน้า',
			'settings.prerollLibrary' => 'โพสต์ห้องสมุด',
			'settings.prerollLibraryNotSet' => 'ไม่ตั้งค่า',
			'settings.prerollLibraryNoneFound' => 'ไม่มีห้องสมุดที่พบในเซิร์ฟเวอร์ของคุณ',
			'settings.prerollSelection' => 'โพสต์ที่เลือก',
			'settings.prerollSelectionPickLibraryFirst' => 'เลือกห้องสมุดครั้งแรก',
			'settings.prerollSelectionNoneSelected' => 'ไม่มีการเลือก',
			'settings.prerollSelectionCount' => ({required Object count}) => '${count} เลือก',
			'settings.prerollItemPicker' => 'เลือกใบรับรอง',
			'settings.prerollItemPickerLoadFailed' => 'ฉันไม่สามารถโหลดรายการจากห้องสมุดนี้ได้',
			'settings.invalidRegex' => 'ความผิดปกติของการแสดงออกปกติ',
			'settings.regex' => 'คําอธิบายปกติ',
			'settings.downloads' => 'รายการดาวน์โหลด',
			'settings.downloadLocationDescription' => 'เลือกสถานที่ที่จะเก็บเนื้อหาที่ดาวน์โหลด',
			'settings.downloadLocationDefault' => 'การจัดเก็บแอป (App Storage)',
			'settings.downloadLocationCustom' => 'โพสต์ที่กําหนดเอง',
			'settings.selectFolder' => 'เลือกโฟลเดอร์',
			'settings.resetToDefault' => 'การตั้งค่าใหม่แบบ default',
			'settings.currentPath' => ({required Object path}) => 'อัพเดท: ${path}',
			'settings.downloadLocationChanged' => 'ดาวน์โหลดตําแหน่งที่เปลี่ยนแปลง',
			'settings.downloadLocationReset' => 'ดาวน์โหลดตําแหน่ง reset to default',
			'settings.downloadLocationInvalid' => 'โพสต์ที่เลือกไม่สามารถเขียนได้',
			'settings.downloadLocationPickerUnavailable' => 'การเลือกโฟลเดอร์ไม่สามารถใช้ได้บนอุปกรณ์นี้',
			'settings.downloadOnWifiOnly' => 'ดาวน์โหลดที่ Wi-Fiเท่านั้น',
			'settings.downloadOnWifiOnlyDescription' => 'ป้องกันการดาวน์โหลดเมื่อบนข้อมูลมือถือ',
			'settings.autoRemoveWatchedDownloads' => 'ดาวน์โหลดอัตโนมัติ',
			'settings.autoRemoveWatchedDownloadsDescription' => 'ลบดาวน์โหลดที่เห็นโดยอัตโนมัติ',
			'settings.autoDownloadContinueWatching' => 'อัตโนมัติดาวน์โหลด Continue Watching',
			'settings.autoDownloadContinueWatchingDescription' => 'บันทึกรายการในคอลเลกชัน Continue Watch ของคุณดาวน์โหลดและลบพวกเขาเมื่อพวกเขาออกจากคอลเลกชัน',
			'settings.downloadQuality' => 'ดาวน์โหลดคุณภาพ',
			'settings.downloadQualityDescription' => 'Plex เตรียมสำเนาที่แปลงแล้วในคิวดาวน์โหลด ส่วน Jellyfin และ Emby จะแปลงรหัสระหว่างดาวน์โหลดไฟล์ หากการถ่ายโอนหยุดชะงัก อาจต้องเริ่มใหม่',
			'settings.askDownloadQualityEachTime' => 'เลือกคุณภาพสําหรับแต่ละดาวน์โหลด',
			'settings.askDownloadQualityEachTimeDescription' => 'แสดงตัวเลือกคุณภาพก่อนที่จะสแกนวิดีโอการดาวน์โหลดแต่ละครั้ง',
			'settings.cellularDownloadBlocked' => 'ดาวน์โหลดจะถูกบล็อกบนโทรศัพท์มือถือ ใช้ Wi-Fi หรือเปลี่ยนการตั้งค่า',
			'settings.maxVolume' => 'ระดับเสียงสูงสุด',
			'settings.maxVolumeDescription' => 'อนุญาตให้เพิ่มระดับเสียงเกิน 100% สำหรับสื่อที่มีเสียงเบา',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'ความแตกต่างของความปรากฏตัวที่อุดมสมบูรณ์',
			'settings.discordRichPresenceDescription' => 'แสดงสิ่งที่คุณกําลังมองหาบน Discord',
			'settings.services' => 'บริการ',
			'settings.servicesDescription' => 'ติดต่อ Trakt, MyAnimeList, Seerr, และอื่น ๆ',
			'settings.manageLibrariesDescription' => 'การจัดเก็บและซ่อนห้องสมุด',
			'settings.companionRemoteServer' => 'เซิร์ฟเวอร์ระยะไกล',
			'settings.companionRemoteServerDescription' => 'ให้อุปกรณ์มือถือบนเครือข่ายของคุณควบคุมแอปนี้',
			'settings.companionRemoteServerStartFailed' => 'ไม่สามารถเริ่มต้นเซิร์ฟเวอร์คู่ค้าได้',
			'settings.companionRemoteServerStopFailed' => 'ไม่สามารถหยุดเซิร์ฟเวอร์พันธมิตร',
			'settings.autoPip' => 'ภาพถ่ายในภาพ',
			'settings.autoPipDescription' => 'เข้าสู่ภาพในภาพโดยอัตโนมัติเมื่อคุณออกจากแอปในระหว่างการเล่น',
			'settings.matchContentFrameRate' => 'Match Content Frame Rate ความเร็ว',
			'settings.matchContentFrameRateDescription' => 'การแสดงผล Match อัตราการฟื้นฟูไปยังเนื้อหาวิดีโอ',
			'settings.matchContentResolution' => 'โซลูชั่นเนื้อหา Match',
			'settings.matchContentResolutionDescription' => 'แปลงหน้าจอไปยังความละเอียดของวิดีโอในท้องถิ่นเพื่อให้ทีวีของคุณจัดการกับ upscaling เมนูและหัวข้อจะ upscaled ยังในช่วงการเล่น',
			'settings.matchRefreshRate' => 'การแข่งขันอัตโนมัติ',
			'settings.matchRefreshRateDescription' => 'การแสดงผล Match อัตราการสดชื่นในหน้าจอเต็มรูปแบบ',
			'settings.matchDynamicRange' => 'การแข่งขัน Dynamic Range',
			'settings.matchDynamicRangeDescription' => 'สวิตช์ HDR สําหรับเนื้อหา HDR จากนั้นกลับไปที่ SDR',
			'settings.displaySwitchDelay' => 'แสดงสวิทช์ช้า',
			'settings.tunneledPlayback' => 'การเล่นแบบ Tunnelback',
			'settings.tunneledPlaybackDescription' => 'ใช้วิดีโอ tunneling ปิดใช้งานหาก HDR playback แสดงวิดีโอสีดําหรือภาพเคลื่อนไหว stutters',
			'settings.audioPassthrough' => 'เสียงที่กําหนดเอง',
			'settings.audioPassthroughDescription' => 'ส่งเสียง Dolby / DTS ไปยังรับหรือทีวีของคุณโดยไม่ต้องเข้ารหัสใหม่และยังคงเสียงรอบ ปิดถ้าคุณไม่มีเสียง',
			'settings.audioPassthroughDescriptionApple' => 'ใช้ decoder Dolby ที่เกิดจาก Apple สําหรับ Dolby Digital Plus รวมถึง Atmos DTS และ TrueHD ยังคงเล่นเป็น PCM มัลติช่อง ปิดถ้าคุณไม่มีเสียง',
			'settings.audioPassthroughDescriptionAppleSpatial' => 'ใช้ decoder Dolby ที่เกิดจาก Apple สําหรับ Dolby Digital Plus รวมถึง Atmos. บน iOS, iPadOS และ tvOS 26 หรือภายหลัง, TrueHD Atmos และ DTS:X เล่นเป็นเสียงพื้นที่. ระยะทาง DTS และ TrueHD อื่น ๆ เล่นเป็น PCM มัลติช่อง. ปิดถ้าคุณไม่มีเสียง.',
			'settings.audioPassthroughOverriddenByNormalization' => 'ปิดขณะที่เสียง normalization เป็น',
			'settings.audioChannelLimit' => 'ช่องเสียง',
			'settings.audioChannelLimitDescription' => 'ลดจำนวนช่องเสียงที่ถอดรหัสแล้วให้เหมาะกับลำโพง หูฟัง หรือระบบ HDMI ที่ไม่สามารถเล่นได้ครบทุกช่อง',
			'settings.audioChannelLimitOriginal' => 'หลัก',
			'settings.audioChannelLimitOriginalDescription' => 'เล่นทุกช่องในทิศทาง',
			'settings.audioChannelLimitSurround51' => 'สูงสุด 5.1',
			'settings.audioChannelLimitSurround51Description' => 'ผสม 7.1 ลงไป 5.1 สําหรับทีวีและผู้รับที่ใช้ PCM 5.1 เท่านั้น Passthrough ไม่ได้รับผลกระทบ',
			'settings.audioChannelLimitStereo' => 'สเตียรอยด์',
			'settings.audioChannelLimitStereoDescription' => 'ผสมลงไปสองช่องสําหรับสเตียรอยด์หรือหัวข้อ แปลงไปตรงไปตรงไปตรง',
			'settings.downmixCenterBoost' => 'ศูนย์ช่อง Boost',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'ปริมาณ (dB)',
			'settings.downmixCenterBoostShort' => 'DB',
			'settings.audioDownmixNormalize' => 'ปรับปรุงปริมาณบน Downmix',
			'settings.audioDownmixNormalizeDescription' => 'ลดส่วนผสมเพื่อป้องกันไม่ให้คลิก ปิดเพื่อรักษาปริมาณเดิม (อาจทําให้เกิดความผิดปกติในสถานการณ์ที่เสียงรบกวน)',
			'settings.dvConversionMode' => 'Dolby Vision การแปลง',
			'settings.dvConversionModeDescription' => 'เลือกวิธีการจัดการไฟล์ Dolby Vision โปรไฟล์ 7',
			'settings.dvConversionAuto' => 'อัตโนมัติ',
			'settings.dvConversionNative' => 'พื้นที่ / ภาวะมี инвалидност',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'ใช้การตรวจจับความสามารถของอุปกรณ์และพฤติกรรม fallback ปกติ',
			'settings.dvConversionNativeDescription' => 'Force native DV7 และยับยั้งการแปลง DV Retry',
			'settings.dvConversionDv81Description' => 'แปลง RPU ในร่องรัดไป Dolby Vision โปรไฟล์ 8.1',
			'settings.dvConversionHevcStripDescription' => 'เกรด Dolby Vision ชั้น RPU/EL และแบนปัจจุบัน HEVC',
			'settings.disableDolbyVision' => 'ไม่สามารถใช้งานได้ Dolby Vision',
			_ => null,
		} ?? switch (path) {
			'settings.disableDolbyVisionDescription' => 'เล่นไฟล์ HDR10 หรือชั้น HLG แทน Dolby Vision เมื่อมี',
			'settings.hdrSdrConversion' => 'การแปลง HDR ไปยัง SDR',
			'settings.hdrSdrConversionDescription' => 'เลือกสิ่งที่แปลงวิดีโอ HDR เมื่อหน้าจอไม่สามารถแสดง HDR',
			'settings.hdrSdrConversionAuto' => 'อัตโนมัติ',
			'settings.hdrSdrConversionAutoDescription' => 'อุปกรณ์บน Android 9 และภายหลังผู้เล่นบนรุ่นเก่า',
			'settings.hdrSdrConversionDevice' => 'อุปกรณ์',
			'settings.hdrSdrConversionDeviceDescription' => 'อุปกรณ์วิดีโอฮาร์ดแวร์จะแปลงได้เร็วที่สุด แต่สีขึ้นอยู่กับอุปกรณ์',
			'settings.hdrSdrConversionPlayer' => 'ตัวเล่น',
			'settings.hdrSdrConversionPlayerDescription' => 'ผู้เล่นแปลงสีที่สม่ําเสมอ แต่ 4K สามารถจับบนกล่องทีวีต่ําสุด',
			'settings.deinterlace' => 'การเชื่อมต่อ',
			'settings.deinterlaceDescription' => 'การกําจัดรายการผสมจากวิดีโอแบบเชื่อมต่อ (mpv ผู้เล่นเท่านั้น)',
			'settings.deinterlaceOff' => 'ปิด',
			'settings.deinterlaceOffDescription' => 'แสดงวิดีโอที่เชื่อมโยงกันเมื่อมันถูก decoded',
			'settings.deinterlaceVideo' => 'วิดีโอ',
			'settings.deinterlaceVideoDescription' => 'แปลงแต่ละฟิลด์เป็นกรอบเต็ม สําหรับภาพถ่ายวิดีโอสําหรับโทรทัศน์เช่นกีฬาข่าวและคอนเทนต์',
			'settings.deinterlaceFilm' => 'ภาพยนตร์',
			'settings.deinterlaceFilmDescription' => 'การกู้คืนกรอบเดิมของภาพยนตร์และภาพเคลื่อนไหวที่โทรคมนาคมถึง 29.97 ฟิล์มต่อวินาทีที่พบได้บน DVD ของ NTSC วิดีโอถ่ายภาพสําหรับนักแสดงทีวีทีวีสดใช้วิดีโอ',
			'settings.requireProfileSelectionOnOpen' => 'ขอโปรไฟล์บนแอปเปิด',
			'settings.requireProfileSelectionOnOpenDescription' => 'แสดงตัวเลือกโปรไฟล์ทุกครั้งที่แอปเปิด',
			'settings.forceTvMode' => 'โหมดโทรทัศน์',
			'settings.forceTvModeDescription' => 'การจัดตั้ง TV Force สําหรับอุปกรณ์ที่ไม่ได้ตรวจจับอัตโนมัติ ต้องเริ่มต้นใหม่',
			'settings.startInFullscreen' => 'เริ่มต้นในหน้าจอเต็มรูปแบบ',
			'settings.startInFullscreenDescription' => 'เปิด PlezyNG ในโหมดหน้าจอเต็มที่เมื่อเปิดตัว',
			'settings.exitFullscreenOnPlayerClose' => 'หน้าจอเต็มหน้าจอออกในผู้เล่นปิด',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'การออกหน้าจอเต็มรูปแบบโดยอัตโนมัติเมื่อปิดเครื่องเล่นวิดีโอ',
			'settings.autoHidePerformanceOverlay' => 'ความสามารถในการทํางานอัตโนมัติ',
			'settings.autoHidePerformanceOverlayDescription' => 'Fade performance overlay ด้วยการควบคุม playback',
			'settings.showNavBarLabels' => 'แสดงแถบ Navigation Bar Labels',
			'settings.showNavBarLabelsDescription' => 'แสดงฉลากข้อความภายใต้ไอคอนบาร์การนําทาง',
			'settings.startupSection' => 'ส่วนเริ่มต้น',
			'settings.preferredServer' => 'เซิร์ฟเวอร์ที่ชื่นชอบ',
			'settings.preferredServerDescription' => 'หลักการผลลัพธ์ของเซิร์ฟเวอร์นี้ในขณะที่รักษาเซิร์ฟเวอร์ที่เชื่อมต่อแต่ละคนพร้อมใช้งาน',
			'settings.preferredServerAutomatic' => 'อัตโนมัติ',
			'settings.showExploreTab' => 'แสดง ค้นหาแท็บ',
			'settings.showExploreTabDescription' => 'แสดงแท็บ Explore กับเนื้อหาจาก Plex Discover และติดตามที่เชื่อมต่อ',
			'settings.hideEmptyLibraries' => 'ลบห้องสมุดว่างเปล่า',
			'settings.hideEmptyLibrariesDescription' => 'ลบสมุดที่มีรายการที่รายงานจากเซิร์ฟเวอร์เป็นศูนย์จากการนําทาง',
			'settings.liveTvDefaultFavorites' => 'ข้อกําหนดสําหรับช่องทางที่ชื่นชอบ',
			'settings.liveTvDefaultFavoritesDescription' => 'แสดงช่องทางที่ชื่นชอบเท่านั้นเมื่อเปิดทีวีสด',
			'settings.general' => 'ทั่วไป',
			'settings.generalDescription' => 'ภาษาเริ่มต้นและพฤติกรรมหน้าต่าง',
			'settings.languageAndRegion' => 'ภาษาและภูมิภาค',
			'settings.startup' => 'การเริ่มต้น',
			'settings.display' => 'แสดง',
			'settings.libraryAndCards' => 'บีทอรีและแผนที่',
			'settings.homeScreen' => 'หน้าจอบ้าน',
			'settings.navigation' => 'การนําทาง',
			'settings.window' => 'หน้าต่าง',
			'settings.liveTv' => 'ทีวีสด',
			'settings.player' => 'ตัวเล่น',
			'settings.videoAndDisplay' => 'วิดีโอและแสดงผล',
			'settings.audio' => 'เสียง',
			'settings.quality' => 'คุณภาพ',
			'settings.subtitles' => 'คำบรรยาย',
			'settings.seekAndTiming' => 'ค้นหาและเวลา',
			'settings.behavior' => 'การกระทํา',
			'settings.gestures' => 'การกระตุ้น',
			'settings.gestureBrightnessSwipe' => 'ความสว่าง Swipe',
			'settings.gestureBrightnessSwipeDescription' => 'สวิทช์ขึ้นหรือลงบนขอบด้านซ้ายเพื่อปรับความสว่าง',
			'settings.gestureVolumeSwipe' => 'หมายเลขรุ่น: Swipe',
			'settings.gestureVolumeSwipeDescription' => 'สลับขึ้นหรือลงบนขอบขวาเพื่อปรับปริมาณ',
			'settings.gesturePinchToZoom' => 'ไฟฟ้าระดับ Zoom',
			'settings.gesturePinchToZoomDescription' => 'คลิกที่วิดีโอเพื่อ zoom ในหรือออก',
			'settings.gestureSeekSwipe' => 'ค้นหา Swipe',
			'settings.gestureSeekSwipeDescription' => 'เปลี่ยนขวาหรือขวาที่ใดก็ได้ในวิดีโอเพื่อค้นหา; ปล่อยเพื่อย้อนกลับ',
			'settings.rememberBrightnessLevel' => 'หมายถึงระดับความสว่าง',
			'settings.rememberBrightnessLevelDescription' => 'เริ่มต้นการเล่นในความสว่างที่กําหนดโดยสวิทส์สุดท้าย',
			'settings.controls' => 'การควบคุม',
			'settings.rememberPlayerChanges' => 'หมายเหตุการเปลี่ยนแปลงของผู้เล่น',
			'settings.rememberPlayerChangesDescription' => 'ที่การเปลี่ยนแปลงที่เกิดขึ้นในระหว่างการเล่นจะถูกบันทึกและนํามาใช้อีกครั้งจาก',
			'settings.scopePlaybackSpeed' => 'ความเร็ว Playback',
			'settings.scopeShaderPreset' => 'โซเดอร์ Preset',
			'settings.scopeAspectRatio' => 'อัตราส่วน',
			'settings.scopeSyncOffsets' => 'Audio & Subtitle ซิงค์',
			'settings.playerScopeOff' => 'อย่าบันทึก',
			'settings.playerScopeGlobal' => 'ทุกที่',
			'settings.playerScopeLibrary' => 'โดยห้องสมุด',
			'settings.playerScopeTitle' => 'สําหรับการแสดงหรือภาพยนตร์',
			'settings.exportDialogTitle' => 'การส่งออก PlezyNG การตั้งค่า',
			'settings.followSystem' => 'ตามระบบ',
			'settings.followAppLanguage' => 'ใช้ภาษาเดียวกับอินเทอร์เฟซ',
			'settings.regionFormat' => 'รูปแบบภูมิภาค',
			'settings.regionFormatDescription' => 'เลือกวิธีแสดงวันที่ ตัวเลข และหน่วยวัด',
			'settings.metadataLanguage' => 'ภาษาข้อมูลสื่อ',
			'settings.metadataLanguageDescription' => 'ภาษาที่ต้องการสำหรับชื่อและคำอธิบายเมื่อเซิร์ฟเวอร์รองรับ การตั้งค่าเสียงและคำบรรยายจะแยกจากกัน',
			'themeEditor.builtIn' => 'โครงสร้าง',
			'themeEditor.presets' => 'โพสต์',
			'themeEditor.custom' => 'คู่มือ',
			'themeEditor.customEmpty' => 'ไม่ได้สร้างขึ้น',
			'themeEditor.editCustom' => 'โมดูลแบบกําหนดเอง',
			'themeEditor.editCustomDescription' => 'เลือกสีแต่ละตัว',
			'themeEditor.locked' => 'การเข้าถึงอายุการใช้งานที่จําเป็น',
			'themeEditor.savedLocked' => 'เก็บ - มีการเข้าถึงตลอดชีวิต',
			'themeEditor.title' => 'ธีมที่กําหนดเอง',
			'themeEditor.startFrom' => 'เริ่มต้นจาก',
			'themeEditor.startFromDescription' => 'คัดลอกสีทั้งหมดจากธีมอื่น ๆ',
			'themeEditor.colors' => 'สี',
			'themeEditor.preview' => 'มุมมอง',
			'themeEditor.slots.bg' => 'ลักษณะ',
			'themeEditor.slots.surface' => 'พื้นผิว',
			'themeEditor.slots.outline' => 'อะไหล่',
			'themeEditor.slots.text' => 'ข้อความ',
			'themeEditor.slots.textMuted' => 'ภาษาไทย',
			'themeEditor.slots.accent' => 'แรงดันไฟฟ้า',
			'themeEditor.opacity' => 'ความผิดปกติ',
			'themeEditor.hexHint' => '#RRGGBB หรือ #AARRGGBB',
			'themeEditor.fromOtherThemes' => 'จากหัวข้ออื่น ๆ',
			'themeEditor.swatchLabel' => ({required Object theme, required Object color}) => '${theme} ${color}',
			'themeEditor.contrast.textOnBg' => 'หมายเลขในพื้นหลัง',
			'themeEditor.contrast.textOnSurface' => 'หมายเลขบนพื้นผิว',
			'themeEditor.contrast.textMutedOnBg' => 'วิดีโอด้านหลัง',
			'themeEditor.contrast.textMutedOnSurface' => 'วินาทีข้อความบนพื้นผิว',
			'themeEditor.contrast.accentOnBg' => 'ความเข้มข้นในพื้นหลัง',
			'themeEditor.contrast.accentOnSurface' => 'ความเข้มข้นบนพื้นผิว',
			'themeEditor.contrast.labelOnAccent' => 'ปุ่มแท็กบน accent',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, ด้านล่างของที่แนะนํา ${minimum}:1',
			'themeEditor.discardTitle' => 'ปล่อยการเปลี่ยนแปลง?',
			'themeEditor.discardMessage' => 'การเปลี่ยนแปลงสีที่ไม่ซ้ํากันของคุณจะหายไป',
			'themeEditor.discard' => 'ตูด',
			'themeEditor.previewCardTitle' => ({required Object number}) => 'ฉบับที่ ${number}',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => '${minutes} นาที left',
			'themeEditor.previewSwitch' => 'รถยนต์',
			'themeEditor.previewMutedText' => 'ภาษาไทยอ่านเช่นนี้',
			'search.hint' => 'ค้นหา ภาพยนตร์, แสดง, เพลง...',
			'search.tryDifferentTerm' => 'ลองคําค้นหาที่แตกต่างกัน',
			'search.searchYourMedia' => 'ค้นหาสื่อของคุณ',
			'search.enterTitleActorOrKeyword' => 'ใส่ชื่อผู้เล่นหรือคําหลัก',
			'search.people' => 'คน',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Set Shortcut สําหรับ ${actionName}',
			'hotkeys.clearShortcut' => 'ระยะเวลาที่ชัดเจน',
			'hotkeys.noShortcutSet' => 'ไม่มีชุดสั้น',
			'hotkeys.currentShortcut' => 'ระยะสั้นปัจจุบัน:',
			'hotkeys.pressToRecord' => 'เลือกเพื่อบันทึกการสั้น ๆ',
			'hotkeys.recordingShortcut' => 'คลิกที่สั้นตอนนี้',
			'hotkeys.actions.playPause' => 'เล่น / ปาก',
			'hotkeys.actions.volumeUp' => 'หมายเลขรุ่น: Volume Up',
			'hotkeys.actions.volumeDown' => 'หมายเลขรุ่น: Down',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'ค้นหาไปข้างหน้า (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'ค้นหากลับ (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'รวมหน้าจอเต็มรูปแบบ',
			'hotkeys.actions.muteToggle' => 'ร่วมกัน ควย',
			'hotkeys.actions.subtitleToggle' => 'รวบรวม Subtitles',
			'hotkeys.actions.audioTrackNext' => 'ถัดไป Audio Track',
			'hotkeys.actions.subtitleTrackNext' => 'ถัดไป Subtitle Track',
			'hotkeys.actions.chapterNext' => 'บทความถัดไป',
			'hotkeys.actions.chapterPrevious' => 'ประเภทก่อนหน้านี้',
			'hotkeys.actions.episodeNext' => 'เรื่องถัดไป',
			'hotkeys.actions.episodePrevious' => 'ประวัติศาสตร์',
			'hotkeys.actions.speedIncrease' => 'ความเร็วเพิ่มขึ้น',
			'hotkeys.actions.speedDecrease' => 'ลดความเร็ว',
			'hotkeys.actions.speedReset' => 'ความเร็วการตั้งค่า',
			'hotkeys.actions.zoomIn' => 'โซม In',
			'hotkeys.actions.zoomOut' => 'สื่อลามก',
			'hotkeys.actions.zoomReset' => 'รีเซ็ต Zoom',
			'hotkeys.actions.subSeekNext' => 'ค้นหา Subtitle ต่อไป',
			'hotkeys.actions.subSeekPrev' => 'ค้นหา Subtitle ก่อนหน้านี้',
			'hotkeys.actions.subtitleDelayIncrease' => 'ภายใต้หัวข้อ',
			'hotkeys.actions.subtitleDelayDecrease' => 'Subtitles ออนไลน์',
			'hotkeys.actions.shaderToggle' => 'ตะแกรง',
			'hotkeys.actions.skipMarker' => 'สปินอินเทอร์ / โคตร',
			'hotkeys.actions.screenshot' => 'จอภาพหน้าจอ',
			'hotkeys.actions.framePrevious' => 'Frame อดีต',
			'hotkeys.actions.frameNext' => 'Frame ต่อไป',
			'fileInfo.title' => 'ข้อมูลไฟล์',
			'fileInfo.overview' => 'ทบทวน',
			'fileInfo.video' => 'วิดีโอ',
			'fileInfo.audio' => 'เสียง',
			'fileInfo.subtitles' => 'คำบรรยาย',
			'fileInfo.images' => 'ภาพรวม',
			'fileInfo.dataStreams' => 'การไหลข้อมูล',
			'fileInfo.lyrics' => 'เนื้อเพลง',
			'fileInfo.file' => 'ไฟล์',
			'fileInfo.attachments' => 'การเชื่อมต่อ',
			'fileInfo.delivery' => 'การจัดส่ง',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => 'รุ่น ${index} ของ ${count}',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => 'ไฟล์ ${index} ของ ${count}',
			'fileInfo.noStreams' => 'เซิร์ฟเวอร์รายงานไม่มีการไหลสําหรับไฟล์นี้',
			'fileInfo.copyPath' => 'การคัดลอกเส้นทาง',
			'fileInfo.pathCopied' => 'ไฟล์เส้นทางคัดลอก',
			'fileInfo.codec' => 'รหัส',
			'fileInfo.codecTag' => 'รหัสผ่าน Tag',
			'fileInfo.resolution' => 'โซลูชั่น',
			'fileInfo.codedResolution' => 'โซลูชันที่รหัส',
			'fileInfo.bitrate' => 'บิทริก',
			'fileInfo.frameRate' => 'ความเร็ว Frame',
			'fileInfo.rotation' => 'การหมุน',
			'fileInfo.comment' => 'วิธีการ',
			'fileInfo.audioDescription' => 'คําอธิบายเสียง',
			'fileInfo.headerCompression' => 'หัวฉีด',
			'fileInfo.sidecarFile' => 'ไฟล์ Sidecar',
			'fileInfo.transportTimestamp' => 'ระยะเวลาการขนส่ง',
			'fileInfo.displayOffset' => 'แสดง Offset',
			'fileInfo.previewFailureCode' => 'โค้ดความล้มเหลว',
			'fileInfo.previewRetries' => 'ความคิดเห็น',
			'fileInfo.aspectRatio' => 'อัตราส่วน',
			'fileInfo.pixelAspectRatio' => 'พิกเซล Aspect Ratio',
			'fileInfo.profile' => 'โปรไฟล์',
			'fileInfo.level' => 'ระดับ',
			'fileInfo.bitDepth' => 'ความลึก',
			'fileInfo.pixelFormat' => 'รูปแบบ Pixel',
			'fileInfo.colorSpace' => 'ปริภูมิสี',
			'fileInfo.colorRange' => 'สี Range',
			'fileInfo.colorPrimaries' => 'สีหลัก',
			'fileInfo.colorTransfer' => 'การถ่ายโอนสี',
			'fileInfo.chromaSubsampling' => 'โครเมี่ยม Subsampling',
			'fileInfo.chromaLocation' => 'โพสต์โครเมี่ยม',
			'fileInfo.scanType' => 'ประเภทการสแกน',
			'fileInfo.interlaced' => 'การเชื่อมต่อ',
			'fileInfo.anamorphic' => 'อะโนเมอร์ฟิก',
			'fileInfo.referenceFrames' => 'หลักสูตรการอ้างอิง',
			'fileInfo.dynamicRange' => 'ช่วงไดนามิก',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Dolby Vision ระดับ',
			'fileInfo.dolbyVisionVersion' => 'Dolby Vision รุ่น',
			'fileInfo.dolbyVisionLayers' => 'Dolby Vision ชั้น',
			'fileInfo.baseLayerCompatibility' => 'ความเข้ากันได้ชั้นฐาน',
			'fileInfo.avcBitstream' => 'บิตสตรีม AVC',
			'fileInfo.nalLengthSize' => 'ขนาด NAL ความยาว',
			'fileInfo.scalingMatrix' => 'เครื่องวัดการสแกนแบบกําหนดเอง',
			'fileInfo.streamIdentifier' => 'การระบุการไหล',
			'fileInfo.streamIndex' => 'อัตราการไหล',
			'fileInfo.streamId' => 'การส่งออก ID',
			'fileInfo.language' => 'ภาษา',
			'fileInfo.languageCode' => 'รหัสภาษา',
			'fileInfo.streamTitle' => 'หมายเลข Track',
			'fileInfo.channels' => 'ช่อง',
			'fileInfo.sampleRate' => 'ตัวอย่างอัตรา',
			'fileInfo.spatialAudio' => 'อากาศเสียง',
			'fileInfo.textBased' => 'ฐานข้อความ',
			'fileInfo.subtitleFormat' => 'โครงสร้าง',
			'fileInfo.provider' => 'ผู้ให้บริการ',
			'fileInfo.matchScore' => 'การแข่งขัน Score',
			'fileInfo.externalDelivery' => 'สามารถให้บริการแยกต่างหาก',
			'fileInfo.sidecarPath' => 'เหล็กเส้นทาง',
			'fileInfo.sourceStream' => 'การคัดลอกจาก',
			'fileInfo.temporary' => 'ระยะเวลา',
			'fileInfo.timeBase' => 'ฐานเวลา',
			'fileInfo.overallBitrate' => 'บิตตารางทั้งหมด',
			'fileInfo.path' => 'ถนน',
			'fileInfo.fileName' => 'ชื่อไฟล์',
			'fileInfo.size' => 'ขนาด',
			'fileInfo.totalSize' => 'ขนาดทั้งหมด',
			'fileInfo.container' => 'บรรจุภัณฑ์',
			'fileInfo.duration' => 'ความยาว',
			'fileInfo.previewThumbnails' => 'โมดูล',
			'fileInfo.previewIndex' => 'มาตรฐาน Index',
			'fileInfo.packetLength' => 'ความยาวแพคเกจ',
			'fileInfo.filePresent' => 'ไฟล์ปัจจุบัน',
			'fileInfo.fileReadable' => 'อ่านโดยเซิร์ฟเวอร์',
			'fileInfo.streamPath' => 'เส้นทางการไหล',
			'fileInfo.optimizedForStreaming' => 'การปรับปรุงสําหรับ Streaming',
			'fileInfo.has64bitOffsets' => '64 บิต Offsets',
			'fileInfo.protocol' => 'โปรโตคอล',
			'fileInfo.mediaType' => 'ประเภทสื่อ',
			'fileInfo.sourceKind' => 'ประเภทแหล่งข้อมูล',
			'fileInfo.optimizedVersion' => 'รุ่นที่เพิ่มประสิทธิภาพ',
			'fileInfo.optimizationTarget' => 'เป้าหมายการเพิ่มประสิทธิภาพ',
			'fileInfo.deletedAt' => 'ลบ',
			'fileInfo.remoteSource' => 'แหล่งกําเนิด',
			'fileInfo.infiniteStream' => 'การไหลไม่สิ้นสุด',
			'fileInfo.directPlay' => 'เล่นโดยตรง',
			'fileInfo.directStream' => 'การไหลโดยตรง',
			'fileInfo.transcoding' => 'การเข้ารหัส',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'รุ่น ID',
			'fileInfo.fileId' => 'ไฟล์ ID',
			'fileInfo.defaultAudioTrack' => 'ลักษณะ Audio Track',
			'fileInfo.defaultSubtitleTrack' => 'การติดตาม Subtitle',
			'fileInfo.subtitlesOff' => 'ปิด',
			'fileInfo.flagDefault' => 'ค่าเริ่มต้น',
			'fileInfo.flagForced' => 'การบังคับ',
			'fileInfo.flagSelected' => 'เลือก',
			'fileInfo.flagExternal' => 'ภายนอก',
			'fileInfo.flagHearingImpaired' => 'ความยินเสียหาย',
			'fileInfo.flagDub' => 'คู่มือ',
			'fileInfo.flagOriginal' => 'หลัก',
			'fileInfo.channelsMono' => 'โมโน',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'โปรไฟล์ ${profile}',
			'mediaMenu.markAsWatched' => 'แสดงให้เห็น',
			'mediaMenu.markAsUnwatched' => 'หมายเลขรุ่น: Unwatched',
			'mediaMenu.removeFromContinueWatching' => 'ลบออกจาก Continuing Watching',
			'mediaMenu.viewDetails' => 'ดูรายละเอียด',
			'mediaMenu.goToSeries' => 'ไปยัง ชุด',
			'mediaMenu.shufflePlay' => 'เล่น Shuffle',
			'mediaMenu.shuffleNotAvailableOffline' => 'Shuffle ไม่สามารถเข้าถึงได้ offline',
			'mediaMenu.fileInfo' => 'ข้อมูลไฟล์',
			'mediaMenu.deleteEpisodeFromServer' => 'ลบส่วนจากเซิร์ฟเวอร์',
			'mediaMenu.deleteSeasonFromServer' => 'ลบฤดูกาลจากเซิร์ฟเวอร์',
			'mediaMenu.deleteShowFromServer' => 'ลบแสดงจากเซิร์ฟเวอร์',
			'mediaMenu.deleteMovieFromServer' => 'ลบภาพยนตร์จากเซิร์ฟเวอร์',
			'mediaMenu.deleteEpisodeTitle' => 'ลบบทความนี้หรือไม่',
			'mediaMenu.deleteSeasonTitle' => 'ปล่อยฤดูกาลนี้',
			'mediaMenu.deleteShowTitle' => 'ลบการแสดงนี้หรือไม่',
			'mediaMenu.deleteMovieTitle' => 'ลบภาพยนตร์นี้',
			'mediaMenu.deleteEpisodeConfirm' => 'ปลั๊ก Episode',
			'mediaMenu.deleteSeasonConfirm' => 'ปล่อยฤดูกาล',
			'mediaMenu.deleteShowConfirm' => 'ลบแสดง',
			'mediaMenu.deleteMovieConfirm' => 'ลบภาพยนตร์',
			'mediaMenu.deleteAnyway' => 'ลบอย่างไรก็ตาม',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => 'ลบ ${title} จากเซิร์ฟเวอร์ของคุณอย่างต่อเนื่อง?',
			'mediaMenu.deleteMultipleWarning' => 'นี่รวมถึงบทความทั้งหมดและไฟล์ของพวกเขา',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n, other: 'นี้ลบทั้งหมด ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodes ในมัน, และไฟล์ของพวกเขา.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n, other: 'รายการนี้จะถูกเก็บไว้ผ่านไฟล์ ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} และทั้งหมดจะถูกลบ', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodes อื่น ๆ จะถูกบันทึกในไฟล์เดียวกันและจะถูกลบยัง:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'PlezyNG ไม่สามารถตรวจสอบไฟล์ใดนี้จะลบดังนั้นจึงสามารถลบมากกว่ารายการที่ระบุไว้ข้างต้น ลบและลองอีกครั้งหรือลบในทางใด ๆ',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'เซิร์ฟเวอร์ของคุณไม่ให้ข้อมูลไฟล์สําหรับรายการนี้ดังนั้น PlezyNG ไม่สามารถตรวจสอบไฟล์ใดที่จะลบได้ มันอาจลบมากกว่ารายการที่ระบุไว้ข้างต้น',
			'mediaMenu.mediaDeletedSuccessfully' => 'รายการสื่อลบอย่างประสบความสําเร็จ',
			'mediaMenu.mediaFailedToDelete' => 'ไม่สามารถลบรายการสื่อ',
			'mediaMenu.rate' => 'อัตรา',
			'mediaMenu.playFromBeginning' => 'เล่นจากเริ่มต้น',
			'mediaMenu.playVersion' => 'เล่นเวอร์ชัน',
			'rateSheet.title' => 'อัตรา',
			'rateSheet.server' => 'เซิร์ฟเวอร์',
			'rateSheet.favorite' => 'รายการโปรด',
			'rateSheet.favorited' => 'ความรัก',
			'rateSheet.saved' => 'การบันทึก',
			'rateSheet.notAvailable' => 'ไม่พบการแข่งขัน',
			'rateSheet.noConnectedServices' => 'เชื่อมต่อบริการในตั้งค่าเพื่อให้คะแนนในนั้น',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, ภาพยนตร์',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, แสดงทีวี',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'มุมมอง',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent}% ครั้งที่เข้าดู',
			'accessibility.mediaCardUnwatched' => 'ไม่สังเกต',
			'accessibility.tapToPlay' => 'คลิกที่เล่น',
			'accessibility.decrease' => 'การลดลง',
			'accessibility.increase' => 'เพิ่มขึ้น',
			'accessibility.decreaseValue' => ({required Object label}) => 'การลดลง ${label}',
			'accessibility.increaseValue' => ({required Object label}) => 'การเพิ่มขึ้น ${label}',
			'accessibility.hue' => 'ก้น',
			'accessibility.saturation' => 'อะแดปเตอร์',
			'accessibility.brightness' => 'ความสว่าง',
			'accessibility.hexColor' => 'สี Hex',
			'accessibility.expandText' => 'หมายเลขที่ขยาย',
			'accessibility.collapseText' => 'หมายเลขรุ่น',
			'accessibility.alphabetNavigation' => 'การนําทางอัลฟเฟต',
			'accessibility.alphabetScrollHint' => 'สวิทช์ขึ้นหรือลงเพื่อย้ายด้วยข้อความ',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'รอบ ${row} ของ ${rowCount}, รอบ ${column} ของ ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'รอบ ${row} ของ ${rowCount}',
			'accessibility.autoScrollPlay' => 'เล่น Auto-Scroll',
			'accessibility.autoScrollPause' => 'การหยุดชะลออัตโนมัติ',
			'accessibility.hueShort' => 'H',
			'accessibility.saturationShort' => 'ส',
			'accessibility.valueShort' => 'V',
			'accessibility.red' => 'สีแดง',
			'accessibility.green' => 'สีเขียว',
			'accessibility.blue' => 'สีน้ำเงิน',
			'accessibility.redShort' => 'R',
			'accessibility.greenShort' => 'G',
			'accessibility.blueShort' => 'บ',
			'accessibility.colorModeHsv' => 'HSV',
			'accessibility.colorModeRgb' => 'RGB',
			'accessibility.title' => 'ความเข้าถึง',
			'accessibility.summary' => 'หมายเลขรุ่น: Text, contrast, motion and controls',
			'accessibility.systemHint' => 'การตั้งค่าการเข้าถึงของอุปกรณ์ของคุณจะใช้เสมอ ตัวเลือกเหล่านี้จะเพิ่มการปรับได้ตลอดทั้ง PlezyNG',
			'accessibility.readability' => 'อ่านและดู',
			'accessibility.textSize' => 'ขนาดข้อความเพิ่มเติม',
			'accessibility.preview' => 'ค้นหาเรื่องต่อไปของคุณ อ่านฟังและดูในความเร็วของคุณเอง',
			'accessibility.boldText' => 'ภาษาไทย',
			'accessibility.highContrast' => 'ความต้านทานสูง',
			'accessibility.highContrastHint' => 'ข้อความที่แข็งแกร่งและแสดงผลที่สําคัญขึ้นบนพื้นผิวที่แสงหรือเข้ม',
			'accessibility.interaction' => 'การเคลื่อนไหวและการโต้ตอบ',
			'accessibility.reduceMotion' => 'ลดการเคลื่อนไหว',
			'accessibility.reduceMotionHint' => 'ปกติความสนใจการเปลี่ยนแปลงหน้าและผลตกแต่งอยู่',
			'accessibility.largeTargets' => 'เป้าหมายสัมผัสขนาดใหญ่',
			'accessibility.largeTargetsHint' => 'ให้การควบคุมร่วมกันพื้นที่มากขึ้นสําหรับสัมผัสและนิวเวชั่นช่วย',
			'accessibility.navigationHint' => 'ใช้ Tab และ Shift+Tab เพื่อย้ายระหว่างควบคุม Enter หรือ Space เพื่อเปิดใช้งาน และ Escape หรือ Back เพื่อปิด โปรแกรมอ่าน zoom และเลือกอ่านพร้อมใช้งานในขณะที่หนังสือเปิด',
			'tooltips.shufflePlay' => 'เล่น Shuffle',
			'tooltips.playTrailer' => 'เล่น Trailer',
			'tooltips.markAsWatched' => 'Mark ตามที่มองเห็น',
			'tooltips.markAsUnwatched' => 'หมายเลขรุ่น: Unwatched',
			'audioTracks.track' => ({required Object n}) => 'ลวดเสียง ${n}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} โครง', ), 
			'videoControls.audioLabel' => 'เสียง',
			'videoControls.subtitlesLabel' => 'คำบรรยาย',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => 'กล่องข้อความ',
			'videoControls.fillScreen' => 'หน้าจอเต็มรูปแบบ',
			'videoControls.stretch' => 'ยืด',
			'videoControls.lockRotation' => 'ล็อคหมุน',
			'videoControls.unlockRotation' => 'ล็อคหมุน',
			'videoControls.timerActive' => 'ฤดูใบไม้ผลิ',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Playback จะหยุดใน ${duration}',
			'videoControls.sleepTimerEndOfVideo' => 'วีดีโอปัจจุบัน',
			'videoControls.sleepTimerStopAtHeader' => 'หยุด',
			'videoControls.sleepTimerDurationHeader' => 'เวลา',
			'videoControls.playbackWillPauseAtEnd' => 'Playback จะหยุดในตอนท้ายของวิดีโอนี้',
			'videoControls.stillWatching' => 'ยังคงดู?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'การพักผ่อนใน ${seconds}s',
			'videoControls.continueWatching' => 'เสร็จสิ้น',
			'videoControls.autoPlayNext' => 'การเล่นอัตโนมัติ',
			'videoControls.playNext' => 'เล่นต่อไป',
			'videoControls.playButton' => 'เล่น',
			'videoControls.pauseButton' => 'หยุดชั่วคราว',
			'videoControls.playbackPaused' => 'สะพาน',
			'videoControls.playbackResumed' => 'เล่น',
			'videoControls.loadingVideo' => 'วิดีโอโหลด',
			'videoControls.showPlaybackControls' => 'แสดงการควบคุม playback',
			'videoControls.hidePlaybackControls' => 'การควบคุม Playback',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'ค้นหากลับ ${seconds} วินาที',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'ค้นหาต่อไป ${seconds} วินาที',
			'videoControls.previousButton' => 'เรื่องก่อนหน้า',
			'videoControls.nextButton' => 'เรื่องถัดไป',
			'videoControls.previousChapterButton' => 'ประเภทก่อนหน้า',
			'videoControls.nextChapterButton' => 'บทความถัดไป',
			'videoControls.muteButton' => 'ปกติ',
			'videoControls.unmuteButton' => 'หมายเลข',
			'videoControls.settingsButton' => 'การตั้งค่า Playback',
			'videoControls.tracksButton' => 'เสียงและหัวข้อ',
			'videoControls.trackSelectionTitle' => 'เลือกแถบก่อน playback',
			'videoControls.trackSelectionAuto' => 'การเลือกอัตโนมัติ',
			'videoControls.chaptersButton' => 'ประเภท',
			'videoControls.versionQualityButton' => 'รุ่น & คุณภาพ',
			'videoControls.versionColumnHeader' => 'รุ่น',
			'videoControls.qualityColumnHeader' => 'คุณภาพ',
			'videoControls.qualityOriginal' => 'หลัก',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'การเข้ารหัสผ่านไม่สามารถใช้ได้ - เล่นคุณภาพเดิม',
			'videoControls.subtitleUnavailableFallback' => 'หัวฉบับที่เลือกไม่สามารถโหลดได้ - ต่อเนื่องโดยไม่มีหัวฉบับ',
			'videoControls.pipButton' => 'รูปภาพในโหมด',
			'videoControls.aspectRatioButton' => 'อัตราส่วน',
			'videoControls.ambientLighting' => 'แสงสภาพแวดล้อม',
			'videoControls.fullscreenButton' => 'หน้าจอเต็มรูปแบบ',
			'videoControls.exitFullscreenButton' => 'หน้าจอแสดงผลเต็ม',
			'videoControls.alwaysOnTopButton' => 'เสมอในด้านบน',
			'videoControls.rotationLockButton' => 'ล็อคหมุน',
			'videoControls.lockScreen' => 'หน้าจอปิดผนึก',
			'videoControls.screenLockButton' => 'ล็อคหน้าจอ',
			'videoControls.longPressToUnlock' => 'ความดันยาวที่จะเปิด',
			'videoControls.timelineSlider' => 'วิดีโอ Timeline',
			'videoControls.volumeSlider' => 'ระดับปริมาณ',
			'videoControls.endsAt' => ({required Object time}) => 'เสร็จสิ้นที่ ${time}',
			'videoControls.pipActive' => 'เล่นใน Picture-in-Picture',
			'videoControls.pipFailed' => 'ภาพถ่ายในภาพไม่สามารถเริ่มต้นได้',
			'videoControls.screenshotSaved' => 'หน้าจอบันทึก',
			'videoControls.screenshotFailed' => 'ไม่สามารถถ่ายภาพหน้าจอได้',
			'videoControls.zoomPercent' => ({required Object percent}) => 'ซูม ${percent}%',
			'videoControls.volumePercent' => ({required Object percent}) => 'ระดับเสียง ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'ต้องการ Android 8.0 หรือใหม่กว่า',
			'videoControls.pipErrors.iosVersion' => 'ต้องใช้ iOS 15.0 หรือใหม่กว่า',
			'videoControls.pipErrors.permissionDisabled' => 'รูปภาพในภาพถูกปิดใช้งาน เปิดใช้งานในตั้งค่าระบบ',
			'videoControls.pipErrors.notSupported' => 'อุปกรณ์ไม่สนับสนุนโหมดภาพในภาพ',
			'videoControls.pipErrors.voSwitchFailed' => 'ไม่สามารถเปลี่ยนการส่งออกวิดีโอเพื่อภาพในภาพ',
			'videoControls.pipErrors.failed' => 'ภาพถ่ายในภาพไม่สามารถเริ่มต้นได้',
			'videoControls.pipErrors.prepareFailed' => 'รูปภาพในภาพไม่สามารถเตรียมได้',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'ข้อผิดพลาดเกิดขึ้น: ${error}',
			'videoControls.chapters' => 'ประเภท',
			'videoControls.noChaptersAvailable' => 'ไม่มีบทที่พร้อมใช้งาน',
			'videoControls.queue' => 'สิทธิ',
			'videoControls.noQueueItems' => 'ไม่มีรายการใน Queue',
			'videoControls.noAudioDevicesAvailable' => 'ไม่มีอุปกรณ์เสียง',
			'videoControls.searchSubtitles' => 'ค้นหา Subtitles',
			'videoControls.loadSubtitleFile' => 'ดาวน์โหลดไฟล์ Subtitle',
			'videoControls.subtitleLoadFailed' => 'ไม่สามารถดาวน์โหลดไฟล์ subtitle',
			'videoControls.language' => 'ภาษา',
			'videoControls.noSubtitlesFound' => 'ไม่มีหัวข้อที่พบ',
			'videoControls.subtitleDownloaded' => 'Subtitle ดาวน์โหลด',
			'videoControls.subtitleDownloadedNotApplied' => 'Subtitle ดาวน์โหลด แต่ไม่สามารถเลือกได้',
			'videoControls.subtitleDownloadFailed' => 'ไม่สามารถดาวน์โหลด Subtitle',
			'videoControls.searchLanguages' => 'ค้นหาภาษา',
			'videoControls.skipIntro' => 'สไลด์อินเตอร์เน็ต',
			'videoControls.skipCredits' => 'คิดสกี',
			'videoControls.skipAds' => 'การโฆษณา Skip',
			'videoControls.nextEpisode' => 'เรื่องถัดไป',
			'videoControls.subtitleTrack' => ({required Object n}) => 'เคล็ดลับ ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => 'คำบรรยาย ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (บังคับใช้)',
			'videoControls.osdSubtitlesOff' => 'หัวข้อ: ปิด',
			'videoControls.osdSubtitles' => ({required Object track}) => 'หัวข้อ: ${track}',
			'videoControls.osdAudio' => ({required Object track}) => 'เสียง: ${track}',
			'messages.markedAsWatched' => 'บัญชีตามที่สังเกต',
			'messages.markedAsUnwatched' => 'บัญชีที่ไม่ได้รับการตรวจสอบ',
			'messages.markedAsWatchedOffline' => 'บรรทัดตามที่เห็น (จะซิงค์เมื่อออนไลน์)',
			'messages.markedAsUnwatchedOffline' => 'บัญชีที่ไม่ได้รับการตรวจสอบ (จะซิงค์เมื่อออนไลน์)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'อัตโนมัติ: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n, other: 'อัตโนมัติลบ ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ดาวน์โหลด', ), 
			'messages.removedFromContinueWatching' => 'ปล่อยออกจาก Continuing Watching',
			'messages.errorLoading' => ({required Object error}) => 'ความผิดพลาด: ${error}',
			'messages.searchPartialResults' => 'บางเซิร์ฟเวอร์สื่อไม่สามารถค้นหาได้ แสดงผลที่มีอยู่',
			'messages.streamInterrupted' => 'กระแสถูกหยุด การกดเล่นหรือพยายามที่จะย้อนกลับ',
			'messages.liveStreamInterrupted' => 'การไหลสดถูกหยุด การเล่นกดเพื่อรีด',
			'messages.fileInfoNotAvailable' => 'ข้อมูลไฟล์ไม่สามารถใช้ได้',
			'messages.playbackAuthenticationRequired' => 'ลงชื่อเข้าสู่เซิร์ฟเวอร์สื่ออีกครั้งเพื่อเล่นรายการนี้',
			'messages.playbackServerUnavailable' => 'เซิร์ฟเวอร์สื่อไม่สามารถใช้ได้ ลองอีกครั้งหลังจากนั้น',
			'messages.playbackDataInvalid' => 'เซิร์ฟเวอร์ส่งข้อมูลการเล่นการเล่นที่ผิดพลาด',
			'messages.playbackCancelled' => 'Playback ถูกยกเลิก',
			'messages.playbackFailed' => 'Playback ไม่สามารถเริ่มต้นได้',
			'messages.playbackFailedDetail' => ({required Object error}) => 'Playback ไม่สามารถเริ่มต้นได้: ${error}',
			'messages.audioOutputFailed' => 'การส่งออกเสียงหยุดตอบสนอง ตรวจสอบการเชื่อมต่อเสียงของทีวีหรือผู้รับ หากแอปอื่น ๆ ยังไม่มีเสียงแล้วเปิดอุปกรณ์ใหม่',
			'messages.mediaUnavailable' => 'เนื้อหานี้ไม่สามารถใช้ได้อีกต่อไป',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'ข้อมูลไฟล์โหลดข้อผิดพลาด: ${error}',
			'messages.errorLoadingSeries' => 'ชุดโหลดข้อผิดพลาด',
			'messages.musicNotSupported' => 'การเล่นเพลงยังไม่ได้สนับสนุน',
			'messages.noDescriptionAvailable' => 'ไม่มีคําอธิบาย',
			'messages.noProfilesAvailable' => 'ไม่มีโปรไฟล์',
			'messages.contactAdminForProfiles' => 'ติดต่อผู้ดูแลระบบเซิร์ฟเวอร์ของคุณเพื่อเพิ่มโปรไฟล์',
			'messages.unableToDetermineLibrarySection' => 'ไม่สามารถกําหนดส่วนห้องสมุดสําหรับรายการนี้',
			'messages.logsCleared' => 'โลกที่ทําความสะอาด',
			'messages.logsCopied' => 'บันทึกที่คัดลอกไปยัง clipboard',
			'messages.noLogsAvailable' => 'ไม่มีโลโก้ที่มีอยู่',
			'messages.libraryScanning' => ({required Object title}) => 'การสแกน "${title}"',
			'messages.libraryScanStarted' => ({required Object title}) => 'การสแกนห้องสมุดเริ่มสําหรับ "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'ไม่สามารถสแกนห้องสมุดได้: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'ข้อมูลจําเพาะสําหรับ "${title}"',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'การฟื้นฟู Metadata เริ่มต้นสําหรับ "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'ไม่สามารถปรับปรุงข้อมูลโลหะได้: ${error}',
			'messages.logoutConfirm' => 'คุณแน่ใจว่าคุณต้องการที่จะลงทะเบียนออกหรือไม่',
			'messages.noSeasonsFound' => 'ไม่มีฤดูกาลที่พบ',
			'messages.seasonsLoadFailed' => 'ไม่สามารถโหลดฤดูกาล',
			'messages.noEpisodesFound' => 'ไม่พบ episodes ในฤดูกาลแรก',
			'messages.noEpisodesFoundGeneral' => 'ไม่พบเหตุการณ์',
			_ => null,
		} ?? switch (path) {
			'messages.episodesLoadFailed' => 'ไม่สามารถโหลด episodes',
			'messages.noResultsFound' => 'ไม่มีผลลัพธ์',
			'messages.sleepTimerSet' => ({required Object label}) => 'เวลานอนตั้งค่าสําหรับ ${label}',
			'messages.noItemsAvailable' => 'ไม่มีรายการ',
			'messages.failedToCreatePlayQueueNoItems' => 'ไม่สามารถสร้างสี่เหลี่ยมเล่นได้ - ไม่มีรายการ',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'ความล้มเหลว ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'เปลี่ยนไปยังผู้เล่นที่เข้ากันได้ ...',
			'messages.serverLimitTitle' => 'Playback ไม่ประสบความสําเร็จ',
			'messages.serverLimitBody' => 'ข้อผิดพลาดเซิร์ฟเวอร์ (HTTP 500) ข้อ จํากัด ความกว้างแบนด์วิดท์/การรหัสอาจปฏิเสธการประชุมนี้ โปรดขอให้เจ้าของปรับได้',
			'messages.mediaUnreadableTitle' => 'ไฟล์ไม่สามารถเข้าถึงได้',
			'messages.mediaUnreadableBody' => 'เซิร์ฟเวอร์พบรายการนี้ แต่ไม่สามารถอ่านไฟล์ (HTTP 404) ไฟล์อาจถูกย้ายลบหรือการจัดเก็บของมันไม่สามารถเข้าถึงได้ โปรดขอให้เจ้าของเซิร์ฟเวอร์ตรวจสอบไฟล์และบันทึกห้องสมุด',
			'messages.serverBusyTitle' => 'การไหลไม่สามารถเข้าถึงได้',
			'messages.serverBusyBody' => 'เซิร์ฟเวอร์ยังคงปฏิเสธที่จะส่งไฟล์นี้ (HTTP 503). มันอาจเป็นการเปิดตัวใหม่忙碌หรือการจัดเก็บของไฟล์อาจเป็นออฟไลน์ ลองอีกครั้งในเวลา - ถ้ามันยังคงเกิดขึ้นขอให้เจ้าของเซิร์ฟเวอร์ตรวจสอบเซิร์ฟเวอร์และจัดเก็บของไฟล์',
			'messages.playbackNotAllowedTitle' => 'Playback ไม่ได้อนุญาต',
			'messages.playbackNotAllowedBody' => 'เซิร์ฟเวอร์ปฏิเสธที่จะส่งรายการนี้ (HTTP 403). บัญชีของคุณอาจไม่มีอนุญาตในการเล่นมันหรือเซิร์ฟเวอร์อาจอนุญาตให้เล่นบนเครือข่ายท้องถิ่นเท่านั้น',
			'messages.logsUploaded' => 'โลกอัปโหลด',
			'messages.logsUploadFailed' => 'ไม่สามารถอัพโหลดโลโก้ได้',
			'messages.logId' => 'รหัส',
			'messages.burnedSubtitlesUseMenu' => 'Subtitles จะถูกเผาไหม้ลงใน stream นี้ เปลี่ยนพวกเขาจากเมนู subtitles',
			'messages.noVideoUrl' => 'ไม่มี URL วีดีโอ',
			'messages.playbackNoMediaSources' => 'เซิร์ฟเวอร์ไม่ส่งคืนแหล่งสื่อที่เล่นได้',
			'messages.playbackDataNotPrepared' => 'Playback เริ่มต้นก่อนที่ข้อมูลของคุณพร้อม',
			'messages.streamSelectionUnavailable' => 'การเลือก Stream ไม่สามารถใช้ได้สําหรับแหล่งนี้',
			'messages.streamSelectionFailed' => 'ไม่สามารถใช้กระแสที่เลือก',
			'messages.trackSelectionNotRemembered' => 'ตัวเลือกติดตามนี้ใช้กับการเล่นปัจจุบันเท่านั้น',
			'messages.serverUnavailableForProfile' => 'ไม่มีเซิร์ฟเวอร์ที่มีอยู่สําหรับโปรไฟล์ที่ใช้งาน',
			'subtitlingStyling.previewSample' => 'รวดเร็วสีน้ําตาล fox jumped บน คน หยาบคาย หํา',
			'subtitlingStyling.text' => 'ข้อความ',
			'subtitlingStyling.border' => 'รอบเขต',
			'subtitlingStyling.background' => 'ลักษณะ',
			'subtitlingStyling.fontSize' => 'หมายเลขขนาด',
			'subtitlingStyling.textColor' => 'สีตัวอักษร',
			'subtitlingStyling.borderSize' => 'ขนาดชายแดน',
			'subtitlingStyling.borderColor' => 'สี จํากัด',
			'subtitlingStyling.backgroundOpacity' => 'ลักษณะพื้นหลัง Opacity',
			'subtitlingStyling.backgroundColor' => 'สีพื้นหลัง',
			'subtitlingStyling.position' => 'ตําแหน่ง',
			'subtitlingStyling.assOverride' => 'ASS ทั่วไป',
			'subtitlingStyling.overrideScale' => 'ระดับ',
			'subtitlingStyling.overrideForce' => 'ความแข็งแรง',
			'subtitlingStyling.overrideStrip' => 'ปล่อยสเตนเลส',
			'subtitlingStyling.positionTop' => 'หลัก',
			'subtitlingStyling.positionBottom' => 'ภายใต้',
			'subtitlingStyling.useMargins' => 'การใช้ margins',
			'subtitlingStyling.useMarginsDescription' => 'ให้หัวข้อข้อความอยู่ในพื้นที่นอกวิดีโอ หัวข้อรูปแบบสามารถเก็บตําแหน่งเดิม',
			'subtitlingStyling.anchorToScreen' => 'Anchor to หน้าจอ',
			'subtitlingStyling.anchorToScreenDescription' => 'แสดงหัวข้อข้อความในแถบสีดําด้านล่างวิดีโอหน้าจอกว้าง',
			'subtitlingStyling.bold' => 'ตัวหนา',
			'subtitlingStyling.italic' => 'อิตาลี',
			'subtitlingStyling.renderResolution' => 'โซลูชั่น Render',
			'subtitlingStyling.renderResolutionScreen' => 'ความละเอียดจอ',
			'subtitlingStyling.renderResolutionVideo' => 'วีดีโอ Resolution',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'การตั้งค่าของวิดีโอเล่นขั้นสูง',
			'mpvConfig.presets' => 'โพสต์',
			'mpvConfig.noPresets' => 'ไม่มีการบันทึก',
			'mpvConfig.saveAsPreset' => 'เก็บเป็น Preset',
			'mpvConfig.presetName' => 'ชื่อเริ่มต้น',
			'mpvConfig.presetNameHint' => 'ใส่ชื่อสําหรับ preset นี้',
			'mpvConfig.loadPreset' => 'โหลด',
			'mpvConfig.deletePreset' => 'ลบ',
			'mpvConfig.presetSaved' => 'โพสต์บันทึก',
			'mpvConfig.presetLoaded' => 'โหลด',
			'mpvConfig.presetDeleted' => 'โพสต์ลบ',
			'mpvConfig.confirmDeletePreset' => 'คุณแน่ใจว่าคุณต้องการลบการตั้งค่านี้หรือไม่',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan hwdec=auto # ความคิดเห็น',
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => 'เพิ่มสาย',
			'mpvConfig.removeLine' => 'ลบสาย',
			'mpvConfig.embeddedVoHint' => 'vo, gpu-context และ gpu-api จะถูก ignored บน Linux: วิดีโอที่รวมเสมอส่งผ่าน vo=libmpv บนวิดีโอเครื่องบินและ gpu-next (ซึ่งวอลล์คอมพิวเตอร์เช่น ArtCNN ต้องใช้) ไม่สามารถทํางานที่รวม',
			'dialog.confirmAction' => 'การกระทําที่ยืนยัน',
			'profiles.addPlezyProfile' => 'เพิ่มโปรไฟล์ PlezyNG',
			'profiles.switchingProfile' => 'การเปลี่ยนโปรไฟล์',
			'profiles.deleteThisProfileTitle' => 'ลบโปรไฟล์นี้หรือไม่',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'ลบ ${displayName}. การเชื่อมต่อไม่ได้รับผลกระทบ',
			'profiles.active' => 'การใช้งาน',
			'profiles.manage' => 'การจัดการ',
			'profiles.delete' => 'ลบ',
			'profiles.signOut' => 'ออกจากระบบ',
			'profiles.signOutPlexTitle' => 'ลงทะเบียนออกจาก Plex',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'ลบ ${displayName} และทั้งหมด Plex ผู้ใช้บ้าน? ลงทะเบียนกลับมาในเวลาใด ๆ.',
			'profiles.signOutPlexDeleteDownloads' => 'ลบดาวน์โหลด',
			'profiles.signOutPlexDeleteDownloadsDescription' => 'ไม่ว่าพวกเขาจะอยู่บนอุปกรณ์นี้และกลับมาเมื่อคุณลงชื่อเข้าสู่บัญชีนี้',
			'profiles.signedOutPlex' => 'ได้รับการลงนามจาก Plex',
			'profiles.signOutFailed' => 'การลงทะเบียนไม่สําเร็จ',
			'profiles.sectionTitle' => 'โปรไฟล์',
			'profiles.summarySingle' => 'เพิ่มโปรไฟล์เพื่อผสมผู้ใช้ที่จัดการและตัวตนในท้องถิ่น',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} โปรไฟล์ · ใช้งานได้: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} โปรไฟล์',
			'profiles.removeConnectionTitle' => 'การเชื่อมต่อ',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'ลบการเข้าถึง ${displayName} ไปยัง ${connectionLabel}. โปรไฟล์อื่น ๆ เก็บไว้.',
			'profiles.deleteProfileTitle' => 'ลบโปรไฟล์',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'ลบ ${displayName} และเชื่อมต่อของมัน เซิร์ฟเวอร์ยังคงมีอยู่',
			'profiles.profileNameLabel' => 'ชื่อโปรไฟล์',
			'profiles.pinProtectionLabel' => 'การป้องกัน PIN',
			'profiles.copyAutomationLink' => 'คัดลอก Android ลิงค์อัตโนมัติ',
			'profiles.copyAutomationLinkDescription' => 'เลือกโปรไฟล์นี้จากความตั้งใจหรืออัตโนมัติ Android โปรไฟล์ตรวจสอบ PIN ยังคงใช้',
			'profiles.automationLinkCopied' => 'โปรไฟล์อัตโนมัติลิงค์คัดลอก',
			'profiles.pinManagedByPlex' => 'PIN ที่จัดการโดย Plex. Edit on plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'ไม่มีการตั้งค่า PIN สําหรับต้องการหนึ่งแก้ไขผู้ใช้บ้านบน plex.tv',
			'profiles.setPin' => 'ปรับ PIN',
			'profiles.setPinTitle' => 'ปรับ PIN',
			'profiles.confirmPinTitle' => 'การยืนยัน PIN',
			'profiles.pinSet' => 'หมายเลขรุ่น: PIN',
			'profiles.changePin' => 'การเปลี่ยนแปลง',
			'profiles.removePin' => 'นำออก',
			'profiles.connectionsLabel' => 'การเชื่อมต่อ',
			'profiles.add' => 'เพิ่ม',
			'profiles.deleteProfileButton' => 'ปล่อยโปรไฟล์',
			'profiles.noConnectionsHint' => 'ไม่มีการเชื่อมต่อ - เพิ่มหนึ่งเพื่อใช้โปรไฟล์นี้',
			'profiles.noConnections' => 'ไม่มีการเชื่อมต่อ',
			'profiles.plexHomeAccount' => 'Plex บัญชีบ้าน',
			'profiles.plexAccountChip' => ({required Object account}) => 'Plex บัญชี: ${account}',
			'profiles.plexAccountUserChip' => ({required Object user, required Object account}) => '${user} ผ่าน ${account}',
			'profiles.connectionDefault' => 'ค่าเริ่มต้น',
			'profiles.connectionAs' => ({required Object displayName}) => 'เป็น ${displayName}',
			'profiles.makeDefault' => 'ทํา default',
			'profiles.removeConnection' => 'นำออก',
			'profiles.profileRenamed' => 'ชื่อโปรไฟล์',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'เพิ่มไปยัง ${displayName}',
			'profiles.borrowExplain' => 'การเชื่อมต่อโปรไฟล์อื่น ๆ การป้องกันโปรไฟล์ PIN ต้องใช้ PIN',
			'profiles.borrowEmpty' => 'ไม่มีอะไรที่จะ δανειστείอีกต่อไป',
			'profiles.borrowEmptySubtitle' => 'เชื่อมต่อ Plex, Jellyfin หรือ Emby ไปยังโปรไฟล์อื่นแรก',
			'profiles.borrowLoadFailed' => 'การเชื่อมต่อที่มีอยู่ไม่สามารถโหลดได้ ลองอีกครั้ง',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'จาก ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'การเชื่อมต่อที่ถูก δανειστεί',
			'profiles.borrowFailed' => 'ไม่สามารถเชื่อมต่อเครดิตได้',
			'profiles.incorrectPin' => 'PIN ไม่ถูกต้อง',
			'profiles.incorrectPinTryAgain' => 'PIN ไม่ถูกต้อง โปรดลองอีกครั้ง',
			'profiles.sourceProfileMissingParentAccount' => 'โปรไฟล์แหล่งที่มาขาดบัญชีผู้ปกครอง',
			'profiles.failedToLoadHomeUsers' => 'ไม่สามารถโหลดผู้ใช้บ้าน Plex ของคุณ ตรวจสอบการเชื่อมต่อของคุณและลองอีกครั้ง',
			'profiles.failedToVerifyPin' => 'ไม่สามารถตรวจสอบ PIN ได้',
			'profiles.newProfile' => 'โปรไฟล์ใหม่',
			'profiles.profileNameHint' => 'ตัวอย่าง: บุคคลทั่วไป, เด็ก, ห้องครอบครัว',
			'profiles.pinProtectionOptional' => 'การป้องกัน PIN (ตัวเลือก)',
			'profiles.pinExplain' => '4 หมายเลข PIN ที่จําเป็นสําหรับการเปลี่ยนโปรไฟล์',
			'profiles.continueButton' => 'เสร็จสิ้น',
			'profiles.pinsDontMatch' => 'PINs ไม่เข้ากันได้',
			'profiles.tokenIdentityMismatch' => 'โค้นโปรไฟล์ Plex โซลูชันไปยังเซิร์ฟเวอร์ที่ไม่คาดหวัง',
			'profiles.settingsLocked' => 'การตั้งค่าจะถูกล็อคสําหรับโปรไฟล์นี้',
			'profiles.unlockSettings' => 'ปล็อคการตั้งค่า',
			'profiles.showExploreForProfile' => 'แสดง ค้นหาสําหรับโปรไฟล์นี้',
			'profiles.showExploreForProfileDescription' => 'ปิดเพื่อลบ Explore จากการนําทางโปรไฟล์นี้',
			'connections.sectionTitle' => 'การเชื่อมต่อ',
			'connections.addConnection' => 'เพิ่มการเชื่อมต่อ',
			'connections.addConnectionSubtitleNoProfile' => 'ลงทะเบียนกับ Plex หรือเชื่อมต่อเซิร์ฟเวอร์ Jellyfin หรือ Emby',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'เพิ่มไปยัง ${displayName}: Plex, Jellyfin, Emby, หรือการเชื่อมต่อโปรไฟล์อื่น ๆ',
			'connections.sessionExpiredOne' => ({required Object name}) => 'การประชุมสิ้นสุดสําหรับ ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'เซิร์ฟเวอร์ ${count} เซิร์ฟเวอร์',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} ไม่เข้าถึงบัญชีนี้',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} เซิร์ฟเวอร์ปฏิเสธการเข้าถึงบัญชีนี้',
			'connections.signInAgain' => 'ลงทะเบียนอีกครั้ง',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'Edit ${product} การเชื่อมต่อ',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'เพิ่มหรือลบ URL สําหรับ ${serverName}. PlezyNG จะใช้ URL ที่สามารถเข้าถึงได้ด้วย latency ที่ต่ําสุด',
			'accountPreferences.sectionTitle' => 'การตั้งค่าบัญชี',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => 'ออฟต์แวร์เสียงและตัวเลือกห้องสมุดที่บันทึกไว้บน ${account}',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => 'ออฟต์แวร์อัตโนมัติและตัวเลือกห้องสมุดที่บันทึกไว้ในบัญชี ${count}',
			'accountPreferences.pickAccount' => 'บัญชีแต่ละบัญชีจัดเก็บความต้องการของตัวเอง เลือกหนึ่งในการแก้ไข',
			'accountPreferences.storedOnAccount' => 'ตัวเลือกเหล่านี้จะถูกบันทึกไว้ในบัญชีของคุณเองดังนั้นแอปที่ลงชื่อเข้าสู่ระบบจะใช้พวกเขา - รวมถึง PlezyNG บนอุปกรณ์อื่น ๆ ของคุณ',
			'accountPreferences.noAccounts' => 'ไม่มีบัญชีที่กําหนดเอง',
			'accountPreferences.noAccountsHint' => 'ลงชื่อเข้าสู่ระบบที่ Plex หรือเชื่อมต่อกับเซิร์ฟเวอร์ Jellyfin หรือ Emby และข้อกําหนดที่เก็บไว้ในบัญชีนี้จะปรากฏที่นี่',
			'accountPreferences.unavailable' => 'ไม่สามารถเข้าถึงบัญชีนี้ได้',
			'accountPreferences.loadFailed' => 'ไม่สามารถโหลดข้อกําหนดเหล่านี้ได้',
			'accountPreferences.noPreference' => 'ไม่มีความต้องการ',
			'accountPreferences.notSet' => 'ไม่ตั้งค่า',
			'accountPreferences.groups.audioAndSubtitles' => 'เสียงและหัวข้อ',
			'accountPreferences.groups.libraryDisplay' => 'คลังสื่อ',
			'accountPreferences.groups.personalMedia' => 'ข้อมูลส่วนบุคคล',
			'accountPreferences.preferredAudioLanguage' => 'ภาษาเสียงที่ชื่นชอบ',
			'accountPreferences.autoSelectAudio' => 'เลือกเสียงตามภาษา',
			'accountPreferences.autoSelectAudioDescription' => 'ปิดเก็บรวบรวมเสียงใด ๆ ที่ติดตามไฟล์เป็นตัวเลือกที่กําหนดเอง',
			'accountPreferences.preferredSubtitleLanguage' => 'ภาษาที่ชื่นชอบ Subtitle',
			'accountPreferences.subtitleMode' => 'แปลงหัวข้อใน',
			'accountPreferences.subtitleModes.none' => 'เลือกด้วยตนเอง',
			'accountPreferences.subtitleModes.noneDescription' => 'ไม่เคยเปลี่ยนหัวข้อโดยตัวเอง',
			'accountPreferences.subtitleModes.defaultMode' => 'เคล็ดลับการติดตามการติดตาม',
			'accountPreferences.subtitleModes.defaultModeDescription' => 'ใช้ป้ายเริ่มต้นและบังคับที่เก็บไว้ในแต่ละแถบหัวข้อ',
			'accountPreferences.subtitleModes.always' => 'ปัจจุบันเปิดใช้งาน',
			'accountPreferences.subtitleModes.alwaysDescription' => 'แปลงเส้นทางของหัวข้อในภาษาที่ต้องการทุกครั้งที่หนึ่งมีอยู่',
			'accountPreferences.subtitleModes.onlyForced' => 'เท่านั้น Subtitles',
			'accountPreferences.subtitleModes.onlyForcedDescription' => 'บรรจุเพียงเส้นทางที่ระบุไว้เป็นบังคับ',
			'accountPreferences.subtitleModes.smart' => 'แสดงด้วยเสียงต่างประเทศ',
			'accountPreferences.subtitleModes.smartDescription' => 'แปลงหัวข้อเฉพาะเมื่อเสียงอยู่ในภาษาอื่น',
			'accountPreferences.subtitleAccessibility' => 'SDH หัวข้อ',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'มักจะชอบหัวข้อที่ไม่ใช่ SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'ดีกว่า SDH subtitles',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'เท่านั้น SDH subtitles',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'เท่านั้น Subtitles ไม่ใช่ SDH',
			'accountPreferences.forcedSubtitles' => 'หัวข้อบังคับ',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'มากกว่าหัวข้อที่ไม่บังคับ',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'มากกว่าหัวข้อบังคับ',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'เท่านั้น Subtitles',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'เท่านั้น Subtitles ไม่บังคับ',
			'accountPreferences.displayMissingEpisodes' => 'แสดงเหตุการณ์ที่หายไป',
			'accountPreferences.displayMissingEpisodesDescription' => 'รายการ episodes ที่เซิร์ฟเวอร์รู้เกี่ยวกับ แต่ไม่มีไฟล์สําหรับ',
			'accountPreferences.hidePlayedInLatest' => 'ลองดูรายการในล่าสุด',
			'accountPreferences.hidePlayedInLatestDescription' => 'ปล่อยรายการที่คุณได้ดูออกจากแถวล่าสุดของเซิร์ฟเวอร์',
			'accountPreferences.displayCollectionsView' => 'แสดงการดูการเก็บเกี่ยว',
			'accountPreferences.displayCollectionsViewDescription' => 'ให้ดูการเก็บของเซิร์ฟเวอร์พร้อมกับห้องสมุดของคุณ',
			'accountPreferences.rewatchingInNextUp' => 'ปล่อยให้มีการตรวจสอบใหม่ใน Next Up',
			'accountPreferences.rewatchingInNextUpDescription' => 'เมื่อคุณเสร็จสิ้นการแสดงแล้วเริ่มอีกครั้งและ Next Up จะติดตามการตรวจสอบใหม่แทนที่จะลดการแสดง',
			'accountPreferences.watchedIndicator' => 'ตัวชี้วัดที่มองเห็น',
			'accountPreferences.watchedIndicatorOptions.none' => 'ไม่เคย',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => 'ภาพยนตร์และการแสดงทีวี',
			'accountPreferences.watchedIndicatorOptions.movies' => 'ภาพยนตร์เท่านั้น',
			'accountPreferences.watchedIndicatorOptions.shows' => 'แสดงทีวีเท่านั้น',
			'accountPreferences.mediaReviewsVisibility' => 'การประเมิน & รีวิว',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'ผู้ใช้และนักวิจารณ์',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'ผู้ใช้เท่านั้น',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'การวิจารณ์เท่านั้น',
			'accountPreferences.mediaReviewsOptions.nobody' => 'ซ่อนอยู่',
			'discover.title' => 'ค้นหา',
			'discover.noContentAvailable' => 'ไม่มีเนื้อหาที่มีอยู่',
			'discover.addMediaToLibraries' => 'เพิ่มสื่อบางอย่างไปยังห้องสมุดของคุณ',
			'discover.continueWatching' => 'ดูต่อ',
			'discover.continueWatchingIn' => ({required Object library}) => 'ดูเพิ่มเติมใน ${library}',
			'discover.nextUp' => 'ถัดไป',
			'discover.nextUpIn' => ({required Object library}) => 'ต่อไปขึ้นใน ${library}',
			'discover.recentlyAdded' => 'เพิ่มล่าสุด',
			'discover.recentlyAddedIn' => ({required Object library}) => 'เพิ่มเมื่อเร็ว ๆ นี้ ใน ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => 'อัลบั้มล่าสุดใน ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'เล่นล่าสุดใน ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'ส่วนใหญ่เล่นใน ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'ซีซัน ${season} ตอน ${episode}',
			'discover.overview' => 'ทบทวน',
			'discover.cast' => 'คะแนน',
			'discover.extras' => 'Trailers และ Extras',
			'discover.studio' => 'สตูดิโอ',
			'discover.rating' => 'คะแนน',
			'discover.director' => 'ผู้กำกับ',
			'discover.directors' => 'ผู้กำกับ',
			'discover.movie' => 'ภาพยนตร์',
			'discover.tvShow' => 'แสดงทีวี',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} นาที left',
			'discover.moreLikeThis' => 'มากกว่าเช่นนี้',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} หัวข้อ', ), 
			'discover.person.born' => 'เกิด',
			'discover.person.died' => 'ตาย',
			'discover.person.birthplace' => 'สถานที่เกิด',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date} (อายุ ${age})',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date} (อายุ ${age})',
			'errors.searchFailed' => ({required Object error}) => 'ค้นหาล้มเหลว: ${error}',
			'errors.searchUnavailable' => 'ค้นหาไม่สามารถเข้าถึงเซิร์ฟเวอร์สื่อใด ๆ',
			'errors.connectionTimeout' => ({required Object context}) => 'เวลาการเชื่อมต่อเมื่อโหลด ${context}',
			'errors.connectionFailed' => 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์สื่อ',
			'errors.unableToLoad' => ({required Object context}) => 'ไม่สามารถโหลด ${context} โปรดลองอีกครั้ง',
			'errors.noClientAvailable' => 'ไม่มีลูกค้า',
			'errors.pleaseEnterToken' => 'กรุณาใส่ token',
			'errors.invalidToken' => 'โค้นที่ผิดพลาด',
			'errors.failedToVerifyToken' => ({required Object error}) => 'ไม่สามารถตรวจสอบ token: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'ไม่สามารถเปลี่ยนไป ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'ไม่สามารถลบได้ ${displayName}',
			'errors.failedToRate' => 'ไม่สามารถปรับปรุงการรับรอง',
			'errors.reasonTimedOut' => 'การเชื่อมต่อที่กําหนดเวลา',
			'errors.reasonUnreachable' => 'เซิร์ฟเวอร์ไม่สามารถเข้าถึงได้',
			'errors.reasonRefused' => 'เซิร์ฟเวอร์ปฏิเสธคําขอ',
			'errors.reasonNotFound' => 'รายการไม่ได้อยู่ในเซิร์ฟเวอร์',
			'errors.reasonServerError' => 'เซิร์ฟเวอร์รายงานข้อผิดพลาด',
			'errors.reasonCancelled' => 'คําขอถูกยกเลิก',
			'errors.reasonUnexpected' => 'ข้อผิดพลาดที่ไม่คาดหวังเกิดขึ้น',
			'libraries.playRandomMovie' => 'เล่นภาพยนตร์สุ่ม',
			'libraries.randomPickFailed' => 'ไม่สามารถเลือกภาพยนตร์สุ่มจากห้องสมุดนี้ได้',
			'libraries.title' => 'ห้องสมุด',
			'libraries.fallbackTitle' => 'คลังสื่อ',
			'libraries.scanLibraryFiles' => 'ไฟล์สแกนห้องสมุด',
			'libraries.scanLibrary' => 'แสกนไลบรารี่',
			'libraries.analyze' => 'การวิเคราะห์',
			'libraries.analyzeLibrary' => 'การวิเคราะห์ห้องสมุด',
			'libraries.refreshMetadata' => 'การปรับปรุง Metadata',
			'libraries.emptyTrash' => 'ระยําที่ว่างเปล่า',
			'libraries.emptyingTrash' => ({required Object title}) => 'ปิดฝุ่นสําหรับ "${title}..."',
			'libraries.trashEmptied' => ({required Object title}) => 'โลหะที่ถูกเก็บไว้สําหรับ "${title}"',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'ไม่สามารถล้างฝุ่นได้: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'การวิเคราะห์ "${title}..."',
			'libraries.analysisStarted' => ({required Object title}) => 'การวิเคราะห์เริ่มต้นสําหรับ "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'ไม่สามารถวิเคราะห์ห้องสมุดได้: ${error}',
			'libraries.noLibrariesFound' => 'ไม่พบห้องสมุด',
			'libraries.allLibrariesHidden' => 'ห้องสมุดทั้งหมดซ่อนอยู่',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'ห้องสมุดที่ซ่อนอยู่ (${count})',
			'libraries.thisLibraryIsEmpty' => 'ห้องสมุดนี้ว่างเปล่า',
			'libraries.noItemsMatchFilters' => 'ไม่มีรายการตรงกับตัวกรองที่ใช้งาน',
			'libraries.resetFilters' => 'ฟิล์มรีเซ็ต',
			'libraries.all' => 'ทั้งหมด',
			'libraries.clearAll' => 'แสดงทั้งหมด',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'คุณแน่ใจว่าคุณต้องการสแกน "${title}"',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'คุณแน่ใจว่าคุณต้องการวิเคราะห์ "${title}"',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'คุณแน่ใจว่าคุณต้องการอัปเดตข้อมูล metadata สําหรับ "${title}"',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'คุณแน่ใจว่าคุณต้องการที่จะทําให้เสียเปล่าสําหรับ "${title}"',
			'libraries.manageLibraries' => 'การจัดการห้องสมุด',
			'libraries.sort' => 'จัดเรียง',
			'libraries.sortBy' => 'หมายเลขรุ่น:',
			'libraries.filters' => 'ฟิล์ม',
			'libraries.confirmActionMessage' => 'คุณแน่ใจว่าคุณต้องการดําเนินการนี้หรือไม่',
			'libraries.showLibrary' => 'แสดงห้องสมุด',
			'libraries.hideLibrary' => 'ซ่อนห้องสมุด',
			'libraries.libraryOptions' => 'ตัวเลือกห้องสมุด',
			'libraries.content' => 'วัสดุห้องสมุด',
			'libraries.selectLibrary' => 'เลือกห้องสมุด',
			'libraries.filtersWithCount' => ({required Object count}) => 'ตัวกรอง (${count})',
			'libraries.noRecommendations' => 'ไม่มีคําแนะนําที่มีอยู่',
			'libraries.noCollections' => 'ไม่มีคอลเลกชันในห้องสมุดนี้',
			'libraries.noFoldersFound' => 'ไม่พบโฟลเดอร์',
			'libraries.folders' => 'โฟลเดอร์',
			'libraries.tabs.recommended' => 'คําแนะนํา',
			'libraries.tabs.browse' => 'เรียกดู',
			'libraries.tabs.collections' => 'คอลเลกชัน',
			'libraries.tabs.playlists' => 'เพลย์ลิสต์',
			'libraries.groupings.title' => 'กลุ่ม',
			'libraries.groupings.all' => 'ทั้งหมด',
			'libraries.groupings.movies' => 'ภาพยนตร์',
			'libraries.groupings.shows' => 'แสดงทีวี',
			'libraries.groupings.seasons' => 'ฤดูกาล',
			'libraries.groupings.episodes' => 'ฉาก',
			'libraries.groupings.artists' => 'ศิลปิน',
			'libraries.groupings.albums' => 'อัลบั้ม',
			'libraries.groupings.tracks' => 'การเดินทาง',
			'libraries.groupings.folders' => 'โฟลเดอร์',
			'libraries.filterCategories.genre' => 'ประเภท',
			'libraries.filterCategories.year' => 'ปี',
			'libraries.filterCategories.contentRating' => 'ระดับเนื้อหา',
			'libraries.filterCategories.tag' => 'แท็ก',
			'libraries.filterCategories.unwatched' => 'การตรวจสอบ',
			'libraries.filterCategories.unplayed' => 'การเล่น',
			'libraries.filterCategories.favorites' => 'รายการโปรด',
			'libraries.filterCategories.filePath' => 'ฟิล์มเส้นทาง',
			'libraries.sortLabels.title' => 'ชื่อเรื่อง',
			'libraries.sortLabels.dateAdded' => 'วันที่เพิ่ม',
			'libraries.sortLabels.releaseDate' => 'วันที่ปล่อย',
			'libraries.sortLabels.rating' => 'คะแนน',
			'libraries.sortLabels.communityRating' => 'การให้คะแนนจากคอมมิวนิตี',
			'libraries.sortLabels.criticRating' => 'การรับรองเชิงบวก',
			'libraries.sortLabels.userRating' => 'รีวิวผู้ใช้',
			'libraries.sortLabels.datePlayed' => 'วันที่เล่น',
			'libraries.sortLabels.playCount' => 'เล่นหมายเลข',
			'libraries.sortLabels.productionYear' => 'ปีการผลิต',
			'libraries.sortLabels.runtime' => 'ระยะเวลา',
			'libraries.sortLabels.officialRating' => 'การรับรองทางการ',
			'libraries.sortLabels.premiereDate' => 'วันที่เริ่มต้น',
			'libraries.sortLabels.startDate' => 'วันที่เริ่มต้น',
			'libraries.sortLabels.airTime' => 'เวลาอากาศ',
			'libraries.sortLabels.studio' => 'สตูดิโอ',
			'libraries.sortLabels.random' => 'สัญญา',
			'libraries.sortLabels.dateShared' => 'วันที่แบ่งปัน',
			'libraries.sortLabels.latestEpisodeAirDate' => 'ฤดูใบไม้ผลิล่าสุด',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'ไฟล์ล่าสุด ไฟล์ล่าสุด',
			'libraries.sortLabels.dateDownloaded' => 'วันที่ดาวน์โหลด',
			'libraries.sortLabels.size' => 'ขนาด',
			'libraries.sortLabels.library' => 'คลังสื่อ',
			'libraries.advancedFilters.include' => 'รวมถึง',
			'libraries.advancedFilters.exclude' => 'การยกเลิก',
			'libraries.advancedFilters.any' => 'ใด ๆ',
			'libraries.advancedFilters.yes' => 'ใช่',
			'libraries.advancedFilters.no' => 'ไม่',
			'libraries.advancedFilters.not' => ({required Object value}) => 'ไม่ ${value}',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '${count} เลือก',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '${count} ไม่มี',
			'libraries.advancedFilters.searchValues' => 'หลักการค้นหา',
			'libraries.advancedFilters.noValues' => 'ไม่มีค่า',
			'libraries.advancedFilters.matchContains' => 'บรรจุภัณฑ์',
			'libraries.advancedFilters.matchNotContains' => 'ไม่รวมถึง',
			'libraries.advancedFilters.matchIs' => 'เป็น',
			'libraries.advancedFilters.matchIsNot' => 'ไม่ใช่',
			'libraries.advancedFilters.matchBeginsWith' => 'เริ่มต้นด้วย',
			'libraries.advancedFilters.matchEndsWith' => 'เสร็จสิ้นกับ',
			'libraries.advancedFilters.textHint' => 'ชนิด เพื่อ Match',
			'libraries.advancedFilters.from' => 'จาก',
			'libraries.advancedFilters.to' => 'เพื่อ',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from} ถึง ${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value} และขึ้น',
			'libraries.advancedFilters.atMost' => ({required Object value}) => 'สูงสุด ${value}',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => '${count} วันที่ผ่านมา',
			'libraries.advancedFilters.dateLastYear' => 'ปีที่ผ่านมา',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => 'เก่ากว่า ${count} วัน',
			'libraries.advancedFilters.dateOlderThanYear' => 'เก่ากว่าหนึ่งปี',
			'libraries.selection.selectItems' => 'เลือกรายการ',
			'libraries.selection.selectedCount' => ({required Object count}) => '${count} เลือก',
			'libraries.selection.actions' => 'การเลือกกิจกรรม',
			'libraries.selection.confirmDescendants' => 'นี่จะเปลี่ยนทุก episodes ในการแสดงและฤดูกาลที่เลือก',
			'libraries.selection.confirmUnwatched' => 'นี่ยังทําความสะอาดการเล่นของรายการที่เลือก',
			'libraries.selection.confirmCount' => ({required Object count}) => 'รายการที่เลือก: ${count}',
			'libraries.selection.completed' => ({required Object count}) => 'รายการที่ปรับปรุง: ${count}',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => 'ปรับปรุง ${succeeded}; ไม่ได้สําเร็จ ${failed}. รายการที่ไม่สําเร็จจะยังคงเลือก',
			'about.title' => 'เกี่ยวกับ',
			'about.openSourceLicenses' => 'ใบอนุญาต Open Source',
			'about.versionLabel' => ({required Object version}) => 'รุ่น ${version}',
			'about.appDescription' => 'ลูกค้าที่สวยงาม Plex, Jellyfin และ Emby สําหรับ Flutter',
			'about.viewLicensesDescription' => 'ดูใบอนุญาตของห้องสมุดบุคคลที่สาม',
			'about.privacyPolicy' => 'นโยบายความเป็นส่วนตัว',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'ไม่มีเซิร์ฟเวอร์ที่พบสําหรับ ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'เซิร์ฟเวอร์ที่ไม่ได้โหลด: ${error}',
			'serverSelection.noValidServers' => 'ไม่มีเซิร์ฟเวอร์ที่ใช้ได้พบในบัญชีนี้',
			'hubDetail.title' => 'ชื่อเรื่อง',
			'hubDetail.releaseYear' => 'ปีการปล่อย',
			'hubDetail.dateAdded' => 'วันที่เพิ่ม',
			'hubDetail.rating' => 'คะแนน',
			'hubDetail.noItemsFound' => 'ไม่มีรายการที่พบ',
			'logs.clearLogs' => 'โลกที่ชัดเจน',
			'logs.copyLogs' => 'คัดลอกโลโก้',
			'logs.uploadLogs' => 'โลกอัปโหลด',
			'logs.saveLogs' => 'บันทึกบันทึกไฟล์',
			'logs.logsSaved' => ({required Object path}) => 'บันทึกที่บันทึกถึง ${path}',
			'logs.saveLogsFailed' => 'ไม่สามารถบันทึกไฟล์บันทึก',
			'detail.endsAt' => ({required Object time}) => 'เสร็จสิ้นที่ ${time}',
			'startup.failedTitle' => 'PlezyNG ไม่สามารถเริ่มต้นได้',
			'startup.failedBody' => 'สิ่งบางอย่างผิดพลาดในระหว่างการเริ่มต้น รายละเอียดด้านล่างระบุสิ่งที่ไม่ประสบความสําเร็จ',
			'startup.failedBodyRepairable' => 'PlezyNG ไฟล์การตั้งค่าที่บันทึกจะเสียหายและต้องสร้างใหม่ก่อนที่ PlezyNG สามารถเริ่มต้น การคืนเงินจะไม่ช่วย - เลือกการซ่อมแซมการจัดเก็บข้อมูล',
			'startup.phaseLabel' => 'ขั้นตอน',
			'startup.showDetails' => 'แสดงรายละเอียด',
			'startup.hideDetails' => 'ลบรายละเอียด',
			'startup.copyDetails' => 'คัดลอกรายละเอียด',
			'startup.detailsCopied' => 'รายละเอียดคัดลอกไปยัง clipboard',
			'startup.uploadDetails' => 'รายละเอียดอัปโหลด',
			'startup.repairStorage' => 'การซ่อมแซม',
			'startup.repairTitle' => 'การซ่อมแซมข้อมูลที่เก็บไว้',
			'startup.repairBodyCommon' => 'PlezyNG ไฟล์การตั้งค่าจะเสียหายและไม่สามารถอ่านได้ การซ่อมแซมการตั้งค่าแต่ละตั้งค่าจะถูกกําหนดเอง',
			'startup.repairBodyOneCredential' => 'หนึ่งบันทึกจะเสียหายและไม่สามารถอ่านได้ การซ่อมแซมจะลบเพียงหนึ่งการตั้งค่าอื่น ๆ ของคุณจะหายไป',
			'startup.repairBodySignInsKept' => 'เซิร์ฟเวอร์และโปรไฟล์ของคุณควรจะยังคงลงทะเบียน',
			'startup.repairBodySignInsLost' => 'คีย์ที่ปกป้องการบันทึกบันทึกของคุณไม่สามารถกู้คืนจากไฟล์นี้ดังนั้นคุณจะต้องลงชื่อเข้าสู่เซิร์ฟเวอร์และโปรไฟล์อีกครั้ง ไม่มีอะไรในเซิร์ฟเวอร์สื่อของคุณจะได้รับผลกระทบ',
			'startup.repairBodySessionsUncertain' => 'Trackers (MAL, AniList, Simkl, Trakt) และ Seerr จะถูกเก็บไว้แยกต่างหากและอาจหรืออาจไม่ได้อยู่อยู่ PlezyNG จะบอกคุณว่าสิ่งที่มันเก็บไว้',
			'startup.repairConfirm' => 'การซ่อมแซม',
			'startup.repairSucceeded' => 'การจัดเก็บที่ซ่อมแซม',
			'startup.repairNeedsRestart' => 'การจัดเก็บที่ซ่อมแซม - การเริ่มต้นใหม่ที่จําเป็น',
			'startup.restartRequiredBody' => 'ข้อมูลของคุณได้รับการแก้ไข แต่ PlezyNG จะต้องเริ่มต้นใหม่ก่อนที่จะสามารถใช้ได้ ลบ PlezyNG และเปิดอีกครั้ง',
			'startup.quitPlezy' => 'เคลือบ PlezyNG',
			'startup.repairFailed' => 'การซ่อมแซมล้มเหลว',
			'startup.repairKeptSignIns' => 'เซิร์ฟเวอร์และโปรไฟล์ของคุณยังคงลงทะเบียน',
			'startup.repairLostSignIns' => 'คีย์ที่ปกป้องการบันทึกของคุณไม่สามารถกู้คืน คุณจะต้องลงชื่อเข้าสู่เซิร์ฟเวอร์และโปรไฟล์ทุกครั้งอีกครั้ง',
			'startup.repairLostSessions' => 'การเชื่อมต่อ Tracker หรือ Seerr หนึ่งอย่างน้อยถูกสูญเสียและต้องเชื่อมต่อใหม่',
			'startup.backupTitle' => 'คูปองของไฟล์ที่เสียหายถูกเก็บไว้',
			'startup.backupWarning' => 'มันมีใบรับรองการลงทะเบียนของคุณ อย่าอัพโหลดหรือแบ่งปัน',
			'startup.deleteBackup' => 'ลบสําเนา',
			'startup.backupDeleted' => 'การคัดลอกลบ',
			'startup.previousFailureTitle' => 'PlezyNG ไม่สามารถเริ่มต้นครั้งสุดท้าย',
			'licenses.relatedPackages' => 'บรรจุภัณฑ์ที่เกี่ยวข้อง',
			'licenses.license' => 'ใบอนุญาต',
			'licenses.licenseNumber' => ({required Object number}) => 'ใบอนุญาต ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} ใบอนุญาต',
			'navigation.libraries' => 'ห้องสมุด',
			'navigation.downloads' => 'รายการดาวน์โหลด',
			'navigation.liveTv' => 'ทีวีสด',
			'navigation.explore' => 'ค้นหา',
			'explore.mdblistShelves.manage' => 'การจัดการสํารวจชั้นวาง',
			'explore.mdblistShelves.manageDescription' => 'เลือกและจัดรายการจากบัญชี MDBList ของคุณ',
			'explore.mdblistShelves.description' => 'เลือกรายการภาพยนตร์และโทรทัศน์สาธารณะจากบัญชี MDBList ของคุณ สร้างหรือคัดลอกรายการบน MDBList จากนั้นปรับปรุง',
			'explore.mdblistShelves.selected' => 'ตารางที่เลือก',
			'explore.mdblistShelves.available' => 'รายการบัญชีที่มีอยู่',
			'explore.mdblistShelves.noLists' => 'ไม่มีรายการภาพยนตร์สาธารณะหรือรายการทีวีที่กลับมา สร้างหรือคัดลอกรายการที่ MDBList จากนั้นปรับปรุง',
			'explore.mdblistShelves.displayName' => 'ชื่อ Shelf Display',
			'explore.mdblistShelves.nameHint' => 'ปล่อยให้เปิดเพื่อใช้ชื่อรายการแหล่งข้อมูล',
			'explore.mdblistShelves.add' => 'เพิ่ม Shelf',
			'explore.mdblistShelves.save' => 'เก็บเตียง',
			'explore.mdblistShelves.moveUp' => ({required Object title}) => 'การเคลื่อนไหว ${title} ขึ้น',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => 'การเคลื่อนไหว ${title} ลง',
			'explore.mdblistShelves.unavailable' => 'รายการนี้ไม่สามารถใช้ได้ ลบหรือลบตู้ของมันในตั้งค่า',
			'explore.mdblistShelves.rateLimited' => 'MDBList ขั้นตอนการร้องขอได้ถึง. โปรดส่งกลับต่อไป.',
			'explore.mdblistShelves.loadFailed' => 'ไม่สามารถโหลดแผ่นได้ ตรวจสอบการเชื่อมต่อของคุณและรีด',
			'explore.mdblistShelves.saveFailed' => 'ฉันไม่สามารถบันทึกเก้าอี้โปรดรีด',
			'explore.mdblistShelves.accountChanged' => 'บัญชีหรือโปรไฟล์ได้เปลี่ยนแปลง การเปิดตั้งค่าเหล่านี้อีกครั้ง',
			'explore.mdblistShelves.settingsUnreadable' => 'แผ่นบันทึกไม่สามารถอ่านได้ เลือกรายการของคุณอีกครั้งเพื่อแทนที่การตั้งค่าเหล่านี้',
			'explore.title' => 'ค้นหา',
			'explore.selectSource' => 'เลือกแหล่งข้อมูล',
			'explore.rows.watchlist' => 'รายการตรวจสอบ',
			'explore.rows.recommendedMovies' => 'ภาพยนตร์ที่แนะนํา',
			'explore.rows.recommendedShows' => 'แสดงที่แนะนํา',
			'explore.rows.trendingMovies' => 'ภาพยนตร์แนวโน้ม',
			'explore.rows.trendingShows' => 'แสดงแนวโน้ม',
			'explore.rows.popularMovies' => 'ภาพยนตร์ยอดนิยม',
			'explore.rows.popularShows' => 'แสดงยอดนิยม',
			'explore.rows.trendingAnime' => 'มือสมัครเล่น',
			'explore.rows.suggestedAnime' => 'แนะนํา Anime',
			'explore.rows.airingAnime' => 'ออนิเมะ',
			'explore.rows.popularAnime' => 'มากที่สุด Anime',
			'explore.rows.trending' => 'ทนทาน',
			'explore.rows.upcomingMovies' => 'ภาพยนตร์ที่มา',
			'explore.rows.upcomingShows' => 'แสดงที่มา',
			'explore.status.airing' => 'อากาศ',
			'explore.status.ended' => 'จบ',
			'explore.status.canceled' => 'ปล่อย',
			'explore.status.upcoming' => 'มาใหม่',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ครั้งที่เข้าดู', ), 
			'explore.cast' => 'คะแนน',
			'explore.characters' => 'ตัวละคร',
			'explore.addToWatchlist' => 'เพิ่มเข้าสู่ Watchlist',
			'explore.removeFromWatchlist' => 'ลบออกจาก Watchlist',
			'explore.addedToWatchlist' => 'ที่เพิ่มลงใน watchlist',
			'explore.removedFromWatchlist' => 'ลบออกจาก watchlist',
			'explore.watchlistUpdateFailed' => 'ไม่สามารถปรับปรุงรายการตรวจสอบ',
			'explore.watchlistNoMatch' => 'ไม่สามารถเข้ากันได้รายการนี้กับรายการตรวจสอบ',
			'explore.notInLibrary' => 'ไม่อยู่ในห้องสมุดของคุณ',
			'explore.inTheseLibraries' => 'ในห้องสมุดเหล่านี้',
			'explore.checkingLibrary' => 'ตรวจสอบห้องสมุดของคุณ',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n, other: 'ไม่สามารถตรวจสอบเซิร์ฟเวอร์ ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}', ), 
			'explore.emptyTitle' => 'ไม่มีอะไรที่นี่',
			'explore.emptyMessage' => ({required Object source}) => 'รอบจาก ${source} จะปรากฏที่นี่เมื่อมีเนื้อหา',
			'explore.searchHint' => ({required Object source}) => 'ค้นหา ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'ไม่มีผลลัพธ์สําหรับ "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'ค้นหาภาพยนตร์และแสดงใน ${source}',
			'explore.searchFailed' => 'ค้นหาล้มเหลว ตรวจสอบการเชื่อมต่อของคุณและลองอีกครั้ง',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} ยอดนิยม',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} อากาศ',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} คะแนน',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} ทนทาน',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} ใน ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} ดู',
			'explore.badge.available' => 'มี',
			'explore.badge.partiallyAvailable' => 'มีส่วนหนึ่ง',
			'explore.badge.availableIn4k' => '4K มี',
			'explore.badge.requested' => 'คําขอ',
			'explore.badge.pendingApproval' => 'การอนุมัติ',
			'explore.badge.processing' => 'การประมวลผล',
			'explore.badge.declined' => 'การลดลง',
			'explore.badge.requestFailed' => 'การร้องขอไม่สําเร็จ',
			_ => null,
		} ?? switch (path) {
			'explore.badge.requested4k' => '4K คําขอ',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} ฤดูกาล',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => 'Ep ${episode} ใน ${duration}',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'ถัดไป ใน ${duration}',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} ตอน',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} นาที / กรกฎาคม',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} รายการ',
			'explore.stats.viewersDay' => ({required Object n}) => '${n} ครั้งที่เข้าดูวันนี้',
			'explore.stats.viewersWeek' => ({required Object n}) => '${n} ครั้งในสัปดาห์นี้',
			'explore.stats.viewersMonth' => ({required Object n}) => '${n} ครั้งในเดือนนี้',
			'explore.stats.viewersYear' => ({required Object n}) => '${n} ครั้งในปีนี้',
			'explore.stats.viewersAllTime' => ({required Object n}) => '${n} ครั้งที่เข้าดู',
			'explore.stats.planning' => ({required Object n}) => '${n} การวางแผนที่จะดู',
			'explore.stats.favorited' => ({required Object n}) => '${n} ความรัก',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} ลบมัน',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ความคิดเห็น', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} วิดีโอ',
			'explore.stats.watching' => ({required Object n}) => '${n} ดูมัน',
			'explore.stats.completed' => ({required Object n}) => '${n} ที่เสร็จสิ้น',
			'explore.stats.onHold' => ({required Object n}) => '${n} บน hold',
			'explore.stats.dropped' => ({required Object n}) => '${n} ปิด',
			'explore.season.winter' => 'ฤดูหนาว',
			'explore.season.spring' => 'สวน',
			'explore.season.summer' => 'ฤดูร้อน',
			'explore.season.fall' => 'ปิด',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'ทีวี',
			'explore.format.tvShort' => 'ช่องทีวี',
			'explore.format.movie' => 'ภาพยนตร์',
			'explore.format.special' => 'ข้อมูลพิเศษ',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => 'เพลง',
			'explore.format.other' => 'อื่น ๆ',
			'explore.sourceMaterial.original' => 'หลัก',
			'explore.sourceMaterial.manga' => 'มังสเตน',
			'explore.sourceMaterial.lightNovel' => 'โบรี่แสง',
			'explore.sourceMaterial.novel' => 'เรื่องราว',
			'explore.sourceMaterial.visualNovel' => 'หนังสือภาพ',
			'explore.sourceMaterial.game' => 'เกม',
			'explore.sourceMaterial.webComic' => 'เว็บแคม',
			'explore.sourceMaterial.musicRelease' => 'เพลง',
			'explore.sourceMaterial.otherMedia' => 'อื่น ๆ',
			'explore.creditRole.actor' => 'นักแสดง',
			'explore.creditRole.director' => 'ผู้กำกับ',
			'explore.creditRole.writer' => 'ผู้เขียน',
			'explore.creditRole.producer' => 'ผู้ผลิต',
			'explore.creditRole.creator' => 'ผู้สร้าง',
			'explore.creditRole.composer' => 'คอมโพสิต',
			'explore.relation.prequel' => 'โพสต์',
			'explore.relation.sequel' => 'เซ็กส์',
			'explore.relation.sideStory' => 'ประวัติด้านข้าง',
			'explore.relation.spinOff' => 'สปินออก',
			'explore.relation.alternativeVersion' => 'เวอร์ชันทางเลือก',
			'explore.relation.summary' => 'คําอธิบาย',
			'explore.relation.parentStory' => 'ประวัติของพ่อแม่',
			'explore.relation.adaptation' => 'การปรับแต่ง',
			'explore.relation.other' => 'การเชื่อมโยง',
			'explore.broadcast' => ({required Object day, required Object time}) => 'Airs ${day} ที่ ${time}',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => 'Airs ${day} ที่ ${time} ${timezone}',
			'explore.detail.originalTitle' => 'ชื่อต้นฉบับ',
			'explore.detail.alsoKnownAs' => 'นอกจากนี้ยังเป็นที่รู้จักกันว่า',
			'explore.detail.studios' => 'สตูดิโอ',
			'explore.detail.country' => 'ประเทศ',
			'explore.detail.language' => 'ภาษา',
			'explore.detail.released' => 'ปล่อย',
			'explore.detail.physicalRelease' => 'บดิสก์',
			'explore.detail.ended' => 'จบ',
			'explore.detail.addedOn' => ({required Object date}) => 'ที่เพิ่ม ${date}',
			'explore.detail.yourRating' => 'การจัดอันดับของคุณ',
			'explore.detail.budget' => 'โพสต์',
			'explore.detail.revenue' => 'กล่องสํานักงาน',
			'explore.detail.contentAdvisory' => 'การแนะนําอายุ',
			'explore.detail.tags' => 'แท็ก',
			'explore.detail.revealSpoilerTags' => 'แสดงแท็ก spoiler',
			'explore.detail.links' => 'ป้าย',
			'explore.detail.watchOn' => 'ดูเพิ่มเติม',
			'explore.detail.watchTrailer' => 'ดู trailer',
			'explore.detail.openOn' => ({required Object site}) => 'เปิดที่ ${site}',
			'explore.detail.crew' => 'พันธมิตร',
			'explore.detail.ratings' => 'คะแนน',
			'explore.detail.schedule' => 'ตั้งเวลา',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n, other: 'คําแนะนําโดย ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ผู้ใช้', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'คําแนะนําโดย ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'มือสมัครเล่นโดย ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} ไม่มีการส่งมา',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'คําแนะนําโดย ${percent} ของผู้ชม',
			'explore.detail.relatedTitles' => 'ชื่อที่เกี่ยวข้อง',
			'explore.detail.background' => 'ลักษณะ',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ผล', ), 
			'liveTv.title' => 'ทีวีสด',
			'liveTv.guide' => 'คู่มือ',
			'liveTv.noChannels' => 'ไม่มีช่องทาง',
			'liveTv.noDvr' => 'ไม่มีการกําหนดค่า DVR บนเซิร์ฟเวอร์ใด ๆ',
			'liveTv.serverUnavailable' => 'เซิร์ฟเวอร์ทีวีสดไม่สามารถใช้ได้',
			'liveTv.serverNotConnected' => 'เซิร์ฟเวอร์ทีวีสดไม่ได้เชื่อมต่อ',
			'liveTv.noPrograms' => 'ไม่มีข้อมูลโปรแกรมที่มีอยู่',
			'liveTv.liveStreamFailed' => 'การไหลสดล้มเหลว',
			'liveTv.unknownProgram' => 'โปรแกรมที่ไม่รู้จัก',
			'liveTv.timelineLiveProgram' => 'โปรแกรมสด (Playback อาจอยู่นอกโปรแกรมนี้)',
			'liveTv.timelineBuffer' => 'บูฟเฟอร์ Timeline',
			'liveTv.timelineUnavailable' => 'ระยะเวลาไม่สามารถใช้ได้',
			'liveTv.timelineEstimated' => 'ค่าใช้จ่าย Playback',
			'liveTv.timelinePending' => 'ค้นหา',
			'liveTv.timelineStale' => 'แผนที่สามารถล่วงหน้าได้',
			'liveTv.unknownHub' => 'ที่เก็บข้อมูลไม่รู้จัก',
			'liveTv.unknownError' => 'ความผิดพลาดที่ไม่ทราบ',
			'liveTv.channelNumber' => ({required Object number}) => 'ช่อง ${number}',
			'liveTv.unknownChannel' => 'ช่องที่ไม่รู้จัก',
			'liveTv.live' => 'ชีวิต',
			'liveTv.premiereBadge' => 'ใหม่',
			'liveTv.reloadGuide' => 'คู่มืออัพโหลด',
			'liveTv.searchGuide' => 'คู่มือการค้นหา',
			'liveTv.searchHint' => 'ช่องค้นหาและโปรแกรม',
			'liveTv.searchNoResults' => ({required Object query}) => 'ไม่มีการแข่งขันสําหรับ "${query}"',
			'liveTv.channelsSection' => 'ช่อง',
			'liveTv.programsSection' => 'โปรแกรม',
			'liveTv.now' => 'ตอนนี้',
			'liveTv.today' => 'วันนี้',
			'liveTv.tomorrow' => 'วันพรุ่งนี้',
			'liveTv.midnight' => 'นมกลางคืน',
			'liveTv.overnight' => 'คืน',
			'liveTv.morning' => 'คู่เช้า',
			'liveTv.daytime' => 'วัน',
			'liveTv.evening' => 'คืน',
			'liveTv.lateNight' => 'คืนช้า',
			'liveTv.whatsOn' => 'สิ่งที่อยู่บน',
			'liveTv.watchChannel' => 'ดูช่องทาง',
			'liveTv.favorites' => 'รายการโปรด',
			'liveTv.reorderFavorites' => 'โพสต์ที่ชื่นชอบ',
			'liveTv.noFavoriteChannels' => 'ไม่มีช่องทางที่ชื่นชอบ',
			'liveTv.noFavoriteChannelsHint' => 'แสดงช่องทั้งหมดแล้วกดช่องเพื่อเพิ่มช่องไปยังคนที่คุณชื่นชอบ',
			'liveTv.showAllChannels' => 'แสดงช่องทั้งหมด',
			'liveTv.favoritesLoadFailed' => 'ไม่สามารถโหลด Favorites ตรวจสอบการเชื่อมต่อของคุณและลองอีกครั้ง',
			'liveTv.favoritesUpdateFailed' => 'ไม่สามารถปรับปรุง Favorites ตรวจสอบการเชื่อมต่อของคุณและลองอีกครั้ง',
			'liveTv.joinSession' => 'เข้าร่วมประชุมในขั้นตอน',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'ดูจากเริ่มต้น (${minutes} นาทีที่ผ่านมา)',
			'liveTv.watchLive' => 'ดูสด',
			'liveTv.goToLive' => 'ไปยัง ชีวิต',
			'liveTv.record' => 'บันทึก',
			'liveTv.recordEpisode' => 'ฉบับบันทึก',
			'liveTv.recordSeries' => 'ซีรีส์บันทึก',
			'liveTv.recordOptions' => 'ตัวเลือกการบันทึก',
			'liveTv.saveTo' => 'การบันทึก',
			'liveTv.recordings' => 'การบันทึก',
			'liveTv.scheduledRecordings' => 'การวางแผน',
			'liveTv.recordingRules' => 'กฎการบันทึก',
			'liveTv.noScheduledRecordings' => 'ไม่มีอะไรที่วางแผนที่จะบันทึก',
			'liveTv.manageRecording' => 'การจัดการการบันทึก',
			'liveTv.cancelRecording' => 'ยกเลิกการบันทึก',
			'liveTv.cancelRecordingTitle' => 'ปล่อยการบันทึกนี้',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} จะไม่ได้รับการบันทึก',
			'liveTv.deleteRule' => 'กฎการลบ',
			'liveTv.deleteRuleTitle' => 'ลบกฎการบันทึก',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'ฉบับที่เกิดขึ้นในอนาคตของ ${title} จะไม่ได้บันทึก',
			'liveTv.recordingScheduled' => 'การบันทึกที่วางแผน',
			'liveTv.alreadyScheduled' => 'โปรแกรมนี้ได้รับการวางแผน',
			'liveTv.dvrAdminRequired' => 'การตั้งค่า DVR ต้องมีบัญชี admin',
			'liveTv.recordingFailed' => 'ไม่สามารถวางแผนการบันทึก',
			'liveTv.recordingTargetMissing' => 'ไม่สามารถกําหนดการบันทึกห้องสมุด',
			'liveTv.recordNotAvailable' => 'การบันทึกไม่สามารถใช้ได้สําหรับโปรแกรมนี้',
			'liveTv.recordingCancelled' => 'การบันทึกยกเลิก',
			'liveTv.recordingRuleDeleted' => 'กฎบันทึกลบ',
			'liveTv.processRecordingRules' => 'การประเมินกฎใหม่',
			'liveTv.recordingInProgress' => 'การบันทึกตอนนี้',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} การวางแผน',
			'liveTv.editRule' => 'กฎ Edit',
			'liveTv.editRuleAction' => 'แก้ไข',
			'liveTv.recordingRuleUpdated' => 'กฎการบันทึกปรับปรุง',
			'liveTv.guideReloadRequested' => 'คู่มือฟื้นฟูที่ขอ',
			'liveTv.guideReloadFailed' => 'ไม่สามารถทําความสะอาดคู่มือ',
			'liveTv.rulesProcessRequested' => 'ข้อกําหนดการประเมินใหม่ที่ต้องการ',
			'liveTv.rulesProcessFailed' => 'ไม่สามารถประเมินกฎการบันทึกใหม่ได้',
			'liveTv.recordShow' => 'แสดงบันทึก',
			'liveTv.recordSettings.startEarly' => 'เริ่มต้นเร็ว ๆ นี้ (วินาที)',
			'liveTv.recordSettings.endLate' => 'เสร็จสิ้นช้า (วินาที)',
			'liveTv.recordSettings.newOnly' => 'เท่านั้น episodes ใหม่',
			'liveTv.recordSettings.anyChannel' => 'การบันทึกในช่องใด ๆ',
			'liveTv.recordSettings.anyTime' => 'บันทึกในเวลาใด ๆ',
			'liveTv.recordSettings.skipInLibrary' => 'ละลาย episodes ในห้องสมุดแล้ว',
			'liveTv.recordSettings.keepUpTo' => 'ฉากที่จะรักษา',
			'liveTv.recordSettings.keepUpToHint' => '0 เก็บทุก episod',
			'liveTv.startingInMinutes' => ({required Object minutes}) => 'เริ่มต้นใน ${minutes} นาที',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} ที่ ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product} ข้อมูลการเล่นทีวีสดที่ไม่ได้รับการคืนเงิน',
			'liveTv.failedToStartChannel' => 'ไม่สามารถเริ่มต้นช่องทางสด',
			'liveTv.failedToBuildStreamUrl' => 'ไม่สามารถสร้าง URL Stream',
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'ไม่สามารถเริ่มต้นช่อง: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'ไม่สามารถเปลี่ยนช่อง: ${reason}',
			'collections.title' => 'คอลเลกชัน',
			'collections.collection' => 'การจัดเก็บ',
			'collections.empty' => 'การเก็บรวบรวมช็อตว่างเปล่า',
			'collections.deleteCollection' => 'ลบเก็บ',
			'collections.deleteConfirm' => ({required Object title}) => 'ลบ "${title}"? นี้ไม่สามารถลบได้',
			'collections.deleted' => 'การเก็บรวบรวมช็อตเด็ด',
			'collections.deleteFailed' => 'ไม่สามารถลบการเก็บรวบรวม',
			'collections.deleteFailedWithError' => ({required Object error}) => 'ไม่ได้ลบการเก็บรวบรวมช็อตเด็ด: ${error}',
			'collections.selectCollection' => 'เลือกชุด',
			'collections.collectionName' => 'ชื่อการเก็บเกี่ยว',
			'collections.enterCollectionName' => 'ระบุชื่อการเก็บรวบรวม',
			'collections.addedToCollection' => 'เพิ่มเข้าสู่การเก็บเกี่ยว',
			'collections.errorAddingToCollection' => 'ไม่สามารถเพิ่มเข้าสู่การเก็บเกี่ยว',
			'collections.created' => 'การเก็บรวบรวม',
			'collections.removeFromCollection' => 'การกําจัดจากการเก็บรวบรวม',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => 'นำ “${title}” ออกจากคอลเลกชันนี้หรือไม่',
			'collections.removedFromCollection' => 'การกําจัดจากการเก็บรวบรวม',
			'collections.removeFromCollectionFailed' => 'ไม่สามารถถอดออกจากการเก็บรวบรวม',
			'collections.removeFromCollectionError' => ({required Object error}) => 'ความผิดพลาดในการลบจากการเก็บรวบรวม: ${error}',
			'collections.searchCollections' => 'ค้นหาคอลเลกชัน',
			'playlists.title' => 'เพลย์ลิสต์',
			'playlists.playlist' => 'เพลย์ลิสต์',
			'playlists.noPlaylists' => 'ไม่พบรายการเล่น',
			'playlists.create' => 'สร้าง Playlist',
			'playlists.playlistName' => 'ชื่อ Playlist',
			'playlists.enterPlaylistName' => 'ชื่อ Playlist',
			'playlists.delete' => 'ลบ Playlist',
			'playlists.removeItem' => 'ลบออกจากเพลย์ลิสต์',
			'playlists.smartPlaylist' => 'การเล่นสมาร์ท',
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(count, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} รายการ', ), 
			'playlists.emptyPlaylist' => 'รายการเล่นนี้ว่างเปล่า',
			'playlists.deleteConfirm' => 'ลบ Playlist',
			'playlists.deleteMessage' => ({required Object name}) => 'คุณแน่ใจว่าคุณต้องการลบ "${name}"',
			'playlists.created' => 'Playlist สร้างขึ้น',
			'playlists.deleted' => 'Playlist ลบ',
			'playlists.itemAdded' => 'เพิ่มขึ้นใน Playlist',
			'playlists.itemRemoved' => 'ลบออกจาก Playlist',
			'playlists.selectPlaylist' => 'เลือก Playlist',
			'playlists.searchPlaylists' => 'ค้นหารายการเล่น',
			'playlists.errorCreating' => 'ไม่ได้สร้าง playlist',
			'playlists.errorDeleting' => 'ไม่สามารถลบ playlist',
			'playlists.errorLoading' => 'ไม่สามารถโหลดรายการเล่นได้',
			'playlists.errorAdding' => 'ไม่สามารถเพิ่มไปยัง playlist',
			'playlists.errorReordering' => 'ไม่สามารถปรับแต่งรายการ playlist',
			'playlists.errorRemoving' => 'ไม่สามารถลบออกจาก Playlist',
			'music.goToAlbum' => 'ไปยัง อัลบั้ม',
			'music.goToArtist' => 'ไปยังศิลปิน',
			'music.instantMix' => 'ผสมทันที',
			'music.playNext' => 'เล่นต่อไป',
			'music.addToQueue' => 'เพิ่มให้ Queue',
			'music.discNumber' => ({required Object n}) => 'ดิสก์ ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ล้อ', ), 
			'music.nowPlaying' => 'ตอนนี้เล่น',
			'music.playingFrom' => ({required Object title}) => 'เล่นจาก ${title}',
			'music.queue' => 'สิทธิ',
			'music.clearQueue' => 'ล้างคิว',
			'music.lyrics' => 'เนื้อเพลง',
			'music.visualizer' => 'วิดีโอ',
			'music.visualizerProfileLoading' => 'อ่าน track analysis ...',
			'music.visualizerAmbientMotion' => 'การเคลื่อนไหวสภาพแวดล้อม',
			'music.visualizerPlexLoudness' => 'Plex เสียง',
			'music.visualizerPreviousPreset' => 'สไตล์ภาพก่อนหน้า',
			'music.visualizerNextPreset' => 'สไตล์ภาพต่อไป',
			'music.visualizerPresetAurora' => 'ออโรารี',
			'music.visualizerPresetBloom' => 'บลู',
			'music.visualizerPresetOrbitals' => 'วงจร',
			'music.visualizerPresetPrism' => 'โพสต์',
			'music.visualizerPresetTunnel' => 'ทนเลอร์',
			'music.visualizerPresetTrackMap' => 'การติดตามแผนที่',
			'music.noLyrics' => 'ไม่มีข้อความที่มีอยู่',
			'music.sleepTimer' => 'เวลานอนหลับ',
			'music.sleepTimerEndOfTrack' => 'เสร็จสิ้นของเส้นทาง',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} นาที', ), 
			'music.stopPlayback' => 'ปิด Playback',
			'music.previousTrack' => 'แทร็กก่อนหน้า',
			'music.nextTrack' => 'แทร็กถัดไป',
			'music.repeat' => 'อัปเดต',
			'music.repeatAll' => 'อัปเดตทั้งหมด',
			'music.repeatOne' => 'อัปเดต 1',
			'music.instantMixNoServer' => 'ไม่มีเซิร์ฟเวอร์ที่มีอยู่สําหรับการผสมทันที',
			'music.instantMixFailed' => 'ไม่สามารถโหลดตัวผสมทันที',
			'music.instantMixEmpty' => 'การผสมทันทีกลับด้วยไม่มีเส้นทาง',
			'music.noAudioUrl' => ({required Object track}) => 'ไม่มี URL เสียงที่มีอยู่สําหรับ ${track}',
			'music.discography.singlesAndEps' => 'Singles และ EPs',
			'music.discography.live' => 'ชีวิต',
			'music.discography.compilations' => 'คอมเพลต',
			'watchTogether.title' => 'รับชมร่วมกัน',
			'watchTogether.description' => 'ดูเนื้อหาในซิงค์กับเพื่อนและครอบครัว',
			'watchTogether.createRoom' => 'สร้างห้องพัก',
			'watchTogether.creatingRoom' => 'ห้องสร้าง...',
			'watchTogether.joinRoom' => 'ห้องพัก',
			'watchTogether.joiningRoom' => 'ห้องเข้าร่วม',
			'watchTogether.connecting' => 'การเชื่อมต่อ...',
			'watchTogether.relayPublic' => 'ห้องพักใช้การสื่อสารสาธารณะ Open Watch Party',
			'watchTogether.relayCustom' => ({required Object url}) => 'ห้องพักใช้โทรศัพท์ของคุณที่ ${url}',
			'watchTogether.recentRooms' => 'ห้องพักล่าสุด',
			'watchTogether.roomActions' => 'การกระทําห้อง',
			'watchTogether.renameRoom' => 'ห้องพัก',
			'watchTogether.removeRoom' => 'นำออก',
			'watchTogether.enterRoomCode' => 'ใส่รหัส 6 หมายเลขจากโฮสต์',
			'watchTogether.roomCode' => 'รหัสห้อง',
			'watchTogether.paste' => 'แพสติ้ง',
			'watchTogether.noCodeInClipboard' => 'แผ่นคลิปไม่ได้มีรหัสห้อง',
			'watchTogether.copyCode' => 'รหัสคัดลอก',
			'watchTogether.codeCopied' => 'รหัสห้องคัดลอก',
			'watchTogether.shareInvite' => 'คู่มือ',
			'watchTogether.inviteCopied' => 'ขออธิบายการคัดลอก เขียนลงในข้อความ',
			'watchTogether.inviteMessage' => ({required Object code}) => 'เข้าร่วมห้องของ Watch Together ที่ PlezyNG: เปิดห้องของ Watch Together, เลือกห้องของ Join และเข้าสู่ระบบ ${code}.',
			'watchTogether.openSessionControls' => 'Open Watch ร่วมกันเซสชันควบคุม',
			'watchTogether.reconnecting' => 'การเชื่อมต่อ...',
			'watchTogether.reconnectingDescription' => 'การเชื่อมต่อถูกปิดแล้ว คุณจะเข้าสู่ห้องโดยอัตโนมัติ',
			'watchTogether.connected' => 'เชื่อมต่อ',
			'watchTogether.disconnected' => 'ปิดเชื่อมต่อ',
			'watchTogether.youAreHost' => 'คุณเป็นโฮสต์',
			'watchTogether.hostedBy' => ({required Object name}) => 'โฮสติ้งโดย ${name}',
			'watchTogether.hostControlsPlayback' => 'โฮสต์ควบคุม playback',
			'watchTogether.anyoneCanControl' => 'ทุกคนสามารถควบคุม playback',
			'watchTogether.roomLocked' => 'ห้องล็อค',
			'watchTogether.nowPlaying' => 'ตอนนี้เล่น',
			'watchTogether.nothingPlaying' => 'ไม่มีอะไรเล่น',
			'watchTogether.nothingPlayingHost' => 'เล่นสิ่งบางอย่างจากห้องสมุดใด ๆ เพื่อแบ่งปันกับห้อง',
			'watchTogether.nothingPlayingGuest' => 'เมื่อโฮสต์เล่นสิ่งบางอย่างมันเปิดที่นี่',
			'watchTogether.notShareable' => 'วีดีโอนี้ไม่มีการเข้าถึงคอลัมน์ดังนั้นเพียงผู้ที่มีการเข้าถึงเซิร์ฟเวอร์เดียวกันเท่านั้นที่สามารถเล่นได้',
			'watchTogether.searching' => 'ค้นหาวิดีโอนี้ในห้องสมุดของคุณ ...',
			'watchTogether.yourCopy' => 'คูปองของคุณ',
			'watchTogether.sharingYourCopy' => 'คุณจะแบ่งปันสําเนาของคุณ',
			'watchTogether.playingOtherLength' => ({required Object difference}) => 'เล่นสําเนาของคุณ, ${difference}',
			'watchTogether.mismatchTitle' => 'ความยาวของสําเนาของคุณแตกต่างกัน',
			'watchTogether.mismatchDescription' => ({required Object difference}) => 'คูปองที่ใกล้ที่สุดของคุณคือ ${difference} จากวิดีโอในห้อง มันอาจเป็นตัดหรือรุ่นอื่น ๆ',
			'watchTogether.playAnyway' => 'เล่นอย่างไรก็ตาม',
			'watchTogether.chooseAnotherCopy' => 'เลือกสําเนาอื่น ๆ',
			'watchTogether.dontPlay' => 'อย่าเล่น',
			'watchTogether.unavailableTitle' => 'คุณไม่มีวิดีโอนี้',
			'watchTogether.unavailableDescription' => 'PlezyNG ไม่สามารถหาได้ในห้องสมุดของคุณ เลือกสําเนาด้วยตัวเองหรือค้นหาอีกครั้ง',
			'watchTogether.chooseCopy' => 'เลือกสําเนา',
			'watchTogether.searchAgain' => 'ค้นหาอีกครั้ง',
			'watchTogether.noCandidates' => 'ไม่มีสําเนาที่พบในห้องสมุดของคุณ',
			'watchTogether.choiceFailed' => 'ฉันไม่สามารถเล่นสําเนานี้สําหรับห้อง',
			'watchTogether.lengthLonger' => ({required Object duration}) => '${duration} มากกว่า',
			'watchTogether.lengthShorter' => ({required Object duration}) => '${duration} สั้น ๆ',
			'watchTogether.lengthSame' => 'ความยาวเดียวกัน',
			'watchTogether.lengthUnknown' => 'ความยาวไม่ทราบ',
			'watchTogether.joinCurrentPlayback' => 'เข้าร่วม Playback ปัจจุบัน',
			'watchTogether.joinCurrentPlaybackDescription' => 'กลับไปที่สิ่งที่โฮสต์กําลังมองหาในขณะนี้',
			'watchTogether.stopMedia' => 'ปิดวิดีโอสําหรับทุกคน',
			'watchTogether.syncOffset' => 'ซิงค์ Offset',
			'watchTogether.syncOffsetDescription' => 'เปลี่ยนวิดีโอของคุณถ้ามันทํางานด้านหน้าหรือหลังห้อง',
			'watchTogether.offsetHint' => ({required Object difference}) => 'คูปองของคุณคือ ${difference} จากวิดีโอในห้อง',
			'watchTogether.applyDifference' => ({required Object offset}) => 'ใช้ ${offset}',
			'watchTogether.offsetMinusSecond' => '1 ซ',
			'watchTogether.offsetMinusTenth' => '- 100 มิลลิเมตร',
			'watchTogether.offsetPlusTenth' => '+100 มิลลิเมตร',
			'watchTogether.offsetPlusSecond' => '+ 1 ซ',
			'watchTogether.participants' => 'ผู้เข้าร่วม',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ผู้เข้าร่วม', ), 
			'watchTogether.hostBadge' => 'โฮสต์',
			'watchTogether.nameYou' => ({required Object name}) => '${name} (คุณ)',
			'watchTogether.playerIdle' => 'นี่คือ',
			'watchTogether.playerLoading' => 'โหลด',
			'watchTogether.playerReady' => 'เตรียม',
			'watchTogether.playerBuffering' => 'บูบ',
			'watchTogether.matchSearching' => 'ค้นหา',
			'watchTogether.matchMatched' => 'มีวิดีโอ',
			'watchTogether.matchMismatched' => 'ความยาวที่แตกต่างกัน',
			'watchTogether.matchUnavailable' => 'ไม่ได้มีวิดีโอ',
			'watchTogether.participantOffset' => ({required Object offset}) => 'ตลับลูกปืน ${offset}',
			'watchTogether.makeHost' => 'ทําโฮสต์',
			'watchTogether.makeHostQuestion' => 'โฮสติ้ง',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} จะควบคุมการเล่นและขับเคลื่อนการประชุมสําหรับทุกคน',
			'watchTogether.transfer' => 'การถ่ายโอน',
			'watchTogether.removeParticipant' => 'เอาจากห้องพัก',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => 'ลบ ${name}?',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} จะออกจากห้อง พวกเขาสามารถเข้าร่วมกับรหัสอีกครั้งถ้าคุณปิดห้อง',
			'watchTogether.remove' => 'นำออก',
			'watchTogether.roomSettings' => 'การตั้งค่าห้อง',
			'watchTogether.letEveryoneControl' => 'ให้ทุกคนควบคุม Playback',
			'watchTogether.lockRoom' => 'ห้องล็อค',
			'watchTogether.lockRoomDescription' => 'ไม่มีคนใหม่ที่สามารถเข้าร่วม',
			'watchTogether.leaveRoom' => 'ห้องพัก',
			'watchTogether.leaveRoomQuestion' => 'ห้องพัก',
			'watchTogether.leaveRoomConfirm' => 'คุณสามารถเข้าร่วมอีกครั้งด้วยรหัสห้อง',
			'watchTogether.leave' => 'ปล่อย',
			'watchTogether.endRoom' => 'ห้องที่สิ้นสุด',
			'watchTogether.endRoomQuestion' => 'ห้องพักสุดท้าย',
			'watchTogether.endRoomConfirm' => 'นี่คือจุดสิ้นสุดของห้องสําหรับทุกคน',
			'watchTogether.end' => 'เสร็จสิ้น',
			'watchTogether.playBlockedTitle' => 'Playback ไม่เริ่ม',
			'watchTogether.playBlockedDescription' => 'การเล่นกดเพื่อเริ่มดูกับห้อง',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} การเล่นกด',
			'watchTogether.notices.playbackStarted' => 'Playback เริ่มต้น',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} ปิด',
			'watchTogether.notices.playbackPaused' => 'Playback ปิด',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} ยกไป ${position}',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => 'คลิกที่ ${position}',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} ระบุความเร็วถึง ${speed}',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => 'ความเร็วที่กําหนดเองถึง ${speed}',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} เริ่มต้น ${title}',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => 'ตอนนี้เล่น ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} ปิดวิดีโอ',
			'watchTogether.notices.mediaStopped' => 'วิดีโอหยุด',
			'watchTogether.notices.waitingFor' => ({required Object name}) => 'รอสําหรับ ${name} ...',
			'watchTogether.notices.waitingForSomeone' => 'รอสําหรับคนที่จะจับ ...',
			'watchTogether.notices.finished' => 'เสร็จสิ้น',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} ตอนนี้เป็นโฮสต์',
			'watchTogether.notices.youAreNowHost' => 'ตอนนี้คุณเป็นโฮสต์',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} เข้าร่วม',
			'watchTogether.notices.left' => ({required Object name}) => '${name} ป้าย',
			'watchTogether.notices.controlRefused' => 'เท่านั้นโฮสต์เท่านั้นที่สามารถควบคุม playback',
			'watchTogether.notices.searchFailed' => 'บางเซิร์ฟเวอร์ไม่สามารถค้นหาสําหรับวิดีโอของห้อง',
			'watchTogether.notices.playBlocked' => 'การเล่นกดเพื่อเริ่มต้น',
			'watchTogether.notices.shareFailed' => 'ฉันไม่สามารถแบ่งปันวิดีโอนี้กับห้องพัก',
			'watchTogether.notices.downloadNotShared' => 'ดาวน์โหลดไม่ได้แบ่งปันกับห้องในขณะที่เซิร์ฟเวอร์ของพวกเขาเป็นออฟไลน์',
			'watchTogether.notices.openFailed' => 'ไม่สามารถเปิดวิดีโอของห้อง',
			'watchTogether.ended.ended' => 'เจ้าภาพเสร็จสิ้นห้องพัก',
			'watchTogether.ended.kicked' => 'คุณถูกถอดออกจากห้อง',
			'watchTogether.ended.expired' => 'ห้องพักสิ้นสุด',
			'watchTogether.ended.replaced' => 'คุณเชื่อมต่อห้องนี้บนอุปกรณ์อื่น ๆ',
			'watchTogether.ended.lost' => 'การสูญเสียการเชื่อมต่อกับห้องพัก',
			'watchTogether.errors.invalidCode' => 'นี่ไม่ใช่รหัสห้อง รหัสมี 6 บิตและตัวเลขโดยไม่มี 0, 1, I, L หรือ O',
			'watchTogether.errors.roomNotFound' => 'ไม่มีห้องที่มีรหัสนี้ อาจจะสิ้นสุด',
			'watchTogether.errors.roomFull' => 'ห้องนั้นเต็มไปด้วย',
			'watchTogether.errors.roomLocked' => 'เจ้าภาพปิดห้องนี้',
			'watchTogether.errors.relayFull' => 'ดูร่วมกัน忙碌ในขณะนี้ ลองอีกครั้งหลังจากนั้น',
			'watchTogether.errors.unreachable' => 'ไม่สามารถเข้าถึง Watch Together relay ตรวจสอบการเชื่อมต่อของคุณ',
			'watchTogether.errors.rateLimited' => 'มากเกินไปการพยายาม. รอนาทีและลองอีกครั้ง',
			'watchTogether.errors.clientBlocked' => 'เวอร์ชันนี้ของ PlezyNG ไม่สามารถใช้ relay ปรับปรุงแอป',
			'watchTogether.errors.forbidden' => 'เท่านั้นโฮสต์เท่านั้นที่สามารถทําได้',
			'watchTogether.errors.notInRoom' => 'คุณไม่ได้อยู่ในห้อง',
			'watchTogether.errors.alreadyInRoom' => 'คุณอยู่ในห้อง',
			'watchTogether.errors.resumeFailed' => 'ไม่สามารถเข้าถึงห้อง',
			'watchTogether.errors.unsupported' => 'Relay ไม่สนับสนุนสิ่งนี้',
			'watchTogether.errors.generic' => 'สิ่งบางอย่างผิดพลาด ลองอีกครั้ง',
			'watchTogether.untitledEpisode' => ({required Object number}) => 'ฉบับที่ ${number}',
			'downloads.title' => 'รายการดาวน์โหลด',
			'downloads.manage' => 'การจัดการ',
			'downloads.tvShows' => 'แสดงทีวี',
			'downloads.movies' => 'ภาพยนตร์',
			'downloads.music' => 'เพลง',
			'downloads.tracksQueued' => ({required Object count}) => '${count} tracks queued สําหรับดาวน์โหลด',
			'downloads.noDownloads' => 'ไม่มีดาวน์โหลด',
			'downloads.noDownloadsDescription' => 'เนื้อหาที่ดาวน์โหลดจะปรากฏที่นี่สําหรับการดู offline',
			'downloads.downloadNow' => 'ดาวน์โหลด',
			'downloads.deleteDownload' => 'ดาวน์โหลด',
			'downloads.retryDownload' => 'ดาวน์โหลด',
			'downloads.downloadQueued' => 'ดาวน์โหลด Queued',
			'downloads.downloadResumed' => 'ดาวน์โหลดใหม่',
			'downloads.serverErrorBitrate' => 'ข้อผิดพลาดเซิร์ฟเวอร์: ไฟล์อาจเกินขีด จํากัด bitrate จากระยะไกล',
			'downloads.storageFull' => 'ดาวน์โหลดหยุดเพื่อปกป้องจัดเก็บที่อยู่ ฟรีพื้นที่บางอย่างหรือเลือกสถานที่ดาวน์โหลดอื่นแล้วรีด',
			'downloads.storageUnavailable' => 'ดาวน์โหลดหยุดเพราะการจัดเก็บที่พร้อมใช้งานไม่สามารถตรวจสอบได้ ตรวจสอบตําแหน่งดาวน์โหลดแล้วรีด',
			'downloads.episodesQueued' => ({required Object count}) => '${count} episodes queued สําหรับดาวน์โหลด',
			'downloads.downloadDeleted' => 'ดาวน์โหลดลบ',
			'downloads.deleteConfirm' => ({required Object title}) => 'ลบ "${title}" จากอุปกรณ์นี้?',
			'downloads.deleteCollectionDownloads' => 'ลบดาวน์โหลด',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => 'ลบไฟล์ที่ดาวน์โหลดทั้งหมดใน “${title}” ออกจากอุปกรณ์นี้หรือไม่',
			'downloads.collectionDownloadsDeleted' => 'ดาวน์โหลดลบ',
			'downloads.cancelledDownloadTitle' => 'ดาวน์โหลดยกเลิก',
			'downloads.cancelledDownloadMessage' => 'ดาวน์โหลดนี้ถูกยกเลิก สิ่งที่คุณต้องการทํา?',
			'downloads.allEpisodesAlreadyDownloaded' => 'ส่วนทั้งหมดที่ดาวน์โหลดแล้ว',
			'downloads.resumeDownload' => 'ดาวน์โหลด',
			'downloads.cancelledDownload' => 'ดาวน์โหลดยกเลิก',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (ซิงค์ ${status})',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => 'ดาวน์โหลด ${file} - คลิกเพื่อเสร็จสิ้น',
			'downloads.partialDownloadClickToComplete' => 'ดาวน์โหลดส่วน - คลิกเพื่อเสร็จสิ้น',
			'downloads.deleting' => 'การลบ...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'ลบ ${title}... (${current} ของ ${total})',
			'downloads.queuedTooltip' => 'คุ้มกัน',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'คู่มือ ${files}',
			'downloads.downloadingTooltip' => 'ดาวน์โหลด...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'ดาวน์โหลด ${files}',
			'downloads.noDownloadsTree' => 'ไม่มีดาวน์โหลด',
			'downloads.pauseAll' => 'สอดคล้องทั้งหมด',
			'downloads.resumeAll' => 'ทบทวนทั้งหมด',
			'downloads.retryAll' => 'กลับทั้งหมด',
			'downloads.retryFailed' => 'ดาวน์โหลดที่ล้มเหลว',
			'downloads.deleteAll' => 'ลบทั้งหมด',
			'downloads.selectVersion' => 'เลือกรุ่น',
			'downloads.allEpisodes' => 'ทุกตอน',
			'downloads.unwatchedOnly' => 'เท่านั้นไม่สังเกต',
			'downloads.nextNUnwatched' => ({required Object count}) => 'ถัดไป ${count} ไม่ตรวจสอบ',
			'downloads.customAmount' => 'จํานวนที่กําหนดเอง',
			'downloads.customAmountAny' => 'จํานวนที่กําหนดเอง (ทุกปี)',
			'downloads.randomEpisodes' => 'ฉากที่สุ่ม',
			'downloads.includeSpecials' => 'รวมพิเศษ',
			'downloads.howManyEpisodes' => 'ประวัติจํานวนมาก',
			'downloads.invalidEpisodeCount' => 'เขียนคํานวณส่วนที่ถูกต้อง',
			'downloads.keepSynced' => 'ป้องกันการสังเคราะห์',
			'downloads.downloadOnce' => 'ดาวน์โหลดครั้งเดียว',
			'downloads.keepNUnwatched' => ({required Object count}) => 'เก็บ ${count} ไม่ตรวจสอบ',
			'downloads.editSyncRule' => 'กฎการปรับแต่ง',
			'downloads.removeSyncRule' => 'ปล่อยกฎการซิงค์',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'หยุดการซิงค์ "${title}"? ฉบับที่ดาวน์โหลดจะถูกเก็บไว้',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => 'หยุดการซิงค์ "${title}"',
			'downloads.deleteSyncRuleDownloads' => 'นอกจากนี้ยังลบดาวน์โหลดที่เกี่ยวข้อง',
			'downloads.deleteSyncRuleDownloadsDescription' => 'ดาวน์โหลดที่ใช้ตามกฎการซิงค์หรือโปรไฟล์อื่น ๆ จะถูกเก็บไว้',
			'downloads.syncRuleCreated' => ({required Object count}) => 'หลักการ Sync ที่สร้างขึ้น — รักษา ${count} ฉบับที่ไม่ได้รับการตรวจสอบ',
			'downloads.syncRuleUpdated' => 'หลักการ Sync ปรับปรุง',
			'downloads.syncRuleRemoved' => 'หลักการ Sync Removed',
			'downloads.syncRuleAndDownloadsRemoved' => 'หลักการ Sync และดาวน์โหลดที่เกี่ยวข้องลบ',
			'downloads.syncRuleCleanupBusy' => 'กฎการซิงค์ในขณะนี้มีการปรับปรุง ลองอีกครั้งในเวลาหนึ่ง',
			'downloads.syncRuleCleanupUnavailable' => 'ดาวน์โหลดที่เกี่ยวข้องไม่สามารถระบุได้อย่างปลอดภัย การเชื่อมต่อเซิร์ฟเวอร์อีกครั้งและลองอีกครั้งหรือลบกฎโดยไม่ต้องลบดาวน์โหลด',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => 'การซิงค์ ${count} ฉบับใหม่สําหรับ ${title}',
			'downloads.syncNow' => 'ซิงค์ตอนนี้',
			'downloads.downloadsUpToDate' => 'ดาวน์โหลดถึงปัจจุบัน',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => 'ซิงค์เต็ม · ${queued} queued, ${removed} 删除',
			'downloads.activeSyncRules' => 'หลักการ Sync',
			'downloads.reviewOrphanFiles' => 'รีวิวดาวน์โหลด orphaned',
			'downloads.orphanReviewTitle' => 'รีวิวดาวน์โหลด orphaned',
			'downloads.orphanReviewDescription' => 'ไฟล์ที่ติดฉลากเหล่านี้อยู่ในโฟลเดอร์ดาวน์โหลดที่จัดการโดยแอปที่กําหนดเองของ PlezyNG และไม่มีบันทึกดาวน์โหลดหรืองานที่ใช้งานได้ คลิกที่รายการก่อนที่จะลบ',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count} ไฟล์ · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => 'ลบไฟล์ ${count}',
			'downloads.orphanCleanupNone' => 'ไม่พบไฟล์ดาวน์โหลด',
			'downloads.orphanCleanupFailed' => 'PlezyNG ไม่สามารถสแกนได้อย่างปลอดภัยโฟลเดอร์การดาวน์โหลดที่จัดการ ไม่ได้ลบไฟล์ใด ๆ',
			'downloads.orphanCleanupChanged' => 'รายการดาวน์โหลดได้เปลี่ยนแปลงในระหว่างการตรวจสอบ ตรวจสอบไฟล์อีกครั้งก่อนทําความสะอาด',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => 'โซลูชัน ${count} โซลูชัน · ${size} ฟรี',
			'downloads.noSyncRules' => 'ไม่มีกฎ sync',
			'downloads.manageSyncRule' => 'การจัดการ Sync',
			'downloads.editEpisodeCount' => 'หมายเลขเหตุ',
			'downloads.editSyncFilter' => 'ตัวกรอง Sync',
			'downloads.syncAllItems' => 'การซิงค์รายการทั้งหมด',
			'downloads.syncUnwatchedItems' => 'การซิงค์รายการที่ไม่ได้ตรวจสอบ',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'เซิร์ฟเวอร์: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'มี',
			_ => null,
		} ?? switch (path) {
			'downloads.syncRuleOffline' => 'ออฟไลน์',
			'downloads.syncRuleSignInRequired' => 'เขียนลงในที่ต้องการ',
			'downloads.syncRuleAccessDenied' => 'การเข้าถึงที่ปฏิเสธ',
			'downloads.syncRuleNotAvailableForProfile' => 'ไม่สามารถใช้ได้สําหรับโปรไฟล์ปัจจุบัน',
			'downloads.syncRuleUnknownServer' => 'เซิร์ฟเวอร์ที่ไม่รู้จัก',
			'downloads.syncRuleListCreated' => 'กฎ Sync ที่สร้างขึ้น',
			'downloads.backgroundWarning.bannerBlocked' => 'ดาวน์โหลดจะหยุดเมื่อคุณออกจากแอป',
			'downloads.backgroundWarning.bannerDegraded' => 'ดาวน์โหลดพื้นหลังอาจ จํากัด',
			'downloads.backgroundWarning.bannerAction' => 'รายละเอียด',
			'downloads.backgroundWarning.sheetTitle' => 'ดาวน์โหลดพื้นหลังถูกบล็อก',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'ดาวน์โหลดพื้นหลังอาจ จํากัด',
			'downloads.backgroundWarning.sheetIntro' => 'Android จะป้องกันไม่ให้ PlezyNG ดาวน์โหลดได้อย่างน่าเชื่อถือในพื้นหลัง',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'อุปกรณ์ของคุณจะ จํากัด เมื่อ PlezyNG สามารถดาวน์โหลดในพื้นหลัง',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'การใช้พื้นหลังของ PlezyNG ถูก จํากัด การใช้แบตเตอรี่หรือพื้นหลังของมันจะตั้งค่าเป็น "ไม่ จํากัด"',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android ได้วาง PlezyNG ในสถานะยืนที่ จํากัด การใช้แบตเตอรี่ของมันตั้งค่าเป็น "ไม่ จํากัด"',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'การแจ้งเตือนการดาวน์โหลดจะถูกเปิดใช้งานดังนั้นขั้นตอนและการควบคุมอาจไม่สามารถเข้าถึงได้',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'การแจ้งเตือนถูกเปิดใช้งาน บน Android 13 หรือใหม่กว่าพวกเขาจําเป็นสําหรับการดาวน์โหลดพื้นหลังยาว',
			'downloads.backgroundWarning.reasonDataSaver' => 'Data Saver เป็นที่เปิดใช้งานซึ่งบล็อกการดาวน์โหลดพื้นหลังบนข้อมูลมือถือ ดาวน์โหลดยังคงทํางานบน Wi-Fi.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'ดาวน์โหลดหยุดได้หลายครั้งในขณะที่ PlezyNG อยู่ในพื้นหลัง ตรวจสอบการตั้งค่าแบตเตอรี่หรือการใช้งานพื้นหลังของ PlezyNG',
			'downloads.backgroundWarning.openSettings' => 'การตั้งค่าเปิด',
			'downloads.backgroundWarning.stillNotWorking' => 'อุปกรณ์พิเศษความช่วยเหลือ',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'ดูขั้นตอนสําหรับอุปกรณ์ของคุณหรือส่งบันทึกจากตั้งค่า › ดูบันทึกถ้าปัญหายังคงอยู่',
			'downloads.backgroundWarning.dialogTitle' => 'ดาวน์โหลดอาจไม่เสร็จสิ้น',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'ดาวน์โหลดอย่างไรก็ตาม',
			'downloads.backgroundWarning.dialogFixFirst' => 'แก้ไขสิ่งนี้ก่อน',
			'downloads.backgroundWarning.statusTile' => 'ดาวน์โหลดพื้นหลัง',
			'downloads.backgroundWarning.statusOk' => 'อนุญาตให้ทํางานในพื้นหลัง',
			'downloads.backgroundWarning.statusBlocked' => 'บล็อกโดยการตั้งค่าระบบ',
			'downloads.backgroundWarning.statusDegraded' => 'จํากัด โดยการตั้งค่าระบบ',
			'downloads.backgroundWarning.statusUnknown' => 'ไม่ได้ตรวจสอบ',
			'downloads.backgroundWarning.settingsUnavailable' => 'ไม่สามารถเปิดการตั้งค่าระบบบนอุปกรณ์นี้ได้',
			'downloads.backgroundWarning.linkUnavailable' => 'ไม่สามารถเปิด dontkillmyapp.com บนอุปกรณ์นี้',
			'downloads.options' => 'ดาวน์โหลดตัวเลือก',
			'downloads.groupings.library' => 'คลังสื่อ',
			'downloads.groupings.collections' => 'คอลเลกชัน',
			'downloads.unknownLibrary' => 'บีบอิสระที่ไม่รู้จัก',
			'downloads.unknownShow' => 'แสดงที่ไม่รู้จัก',
			'downloads.unknownSeason' => 'ฤดูกาลที่ไม่รู้จัก',
			'downloads.unknownAlbum' => 'อัลบั้มที่ไม่รู้จัก',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} เสร็จสิ้น',
			'downloads.storageUsed' => ({required Object size}) => 'การจัดเก็บข้อมูลที่ใช้: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ดาวน์โหลด', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} แสดง', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ภาพยนตร์', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} อัลบั้ม', ), 
			'downloads.errorFileNotFound' => 'ไฟล์ที่ไม่ได้พบ (404)',
			'downloads.errorDownloadNotAllowed' => 'ดาวน์โหลดที่ไม่ได้รับอนุญาตโดยเซิร์ฟเวอร์ (403)',
			'downloads.errorDownloadFailed' => 'ดาวน์โหลดล้มเหลว',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'ดาวน์โหลดที่ผิดพลาด: ${reason}',
			'downloads.convertingOnServer' => 'การแปลงไปยังเซิร์ฟเวอร์',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => 'การแปลงไปยังเซิร์ฟเวอร์ · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => 'ดาวน์โหลดที่ผิดพลาด (HTTP ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => 'การประมวลผลหลังล้มเหลว: ${reason}',
			'downloads.reasonFileNotSaved' => 'ไฟล์ไม่สามารถบันทึกไว้บนอุปกรณ์นี้',
			'downloads.reasonCannotResume' => 'การดาวน์โหลดส่วนไม่สามารถยกเลิกได้',
			'downloads.reasonDeviceStorageFull' => 'อุปกรณ์นี้ไม่ได้รับการจัดเก็บ',
			'downloads.notificationDownloading' => 'ดาวน์โหลด...',
			'downloads.notificationComplete' => 'ดาวน์โหลดเต็มรูปแบบ',
			'downloads.notificationPaused' => 'ดาวน์โหลดหยุด',
			'shaders.title' => 'ตุ๊กตา',
			'shaders.noShaderDescription' => 'ไม่มีการปรับปรุงวิดีโอ',
			'shaders.nvscalerDescription' => 'การสแกนภาพ NVIDIA สําหรับวิดีโอที่ชัดเจน',
			'shaders.artcnnVariantNeutral' => 'สภาพกลาง',
			'shaders.artcnnVariantDenoise' => 'ละลาย',
			'shaders.artcnnVariantDenoiseSharpen' => 'สะดวก + Sharpen',
			'shaders.qualityFast' => 'ความเร็ว',
			'shaders.qualityHQ' => 'คุณภาพสูง',
			'shaders.mode' => 'โหมด',
			'shaders.importShader' => 'การนําเข้า Shader',
			'shaders.customShaderDescription' => 'แชดร์ GLSL แบบกําหนดเอง',
			'shaders.shaderImported' => 'Shader ที่นําเข้า',
			'shaders.shaderImportFailed' => 'ไม่สามารถนําเข้า Shader',
			'shaders.deleteShader' => 'ลบ Shader',
			'shaders.deleteShaderConfirm' => ({required Object name}) => 'ลบ “${name}”',
			'companionRemote.title' => 'รีโมตเสริม',
			'companionRemote.connectedTo' => ({required Object name}) => 'เชื่อมต่อ ${name}',
			'companionRemote.unknownDevice' => 'อุปกรณ์ที่ไม่รู้จัก',
			'companionRemote.session.startingServer' => 'เริ่มต้นเซิร์ฟเวอร์ระยะไกล',
			'companionRemote.session.hostAddress' => 'ที่อยู่โฮสต์',
			'companionRemote.session.connected' => 'เชื่อมต่อ',
			'companionRemote.session.serverRunning' => 'เซิร์ฟเวอร์ระยะไกลที่ใช้งานได้',
			'companionRemote.session.serverStopped' => 'เซิร์ฟเวอร์ระยะไกลหยุด',
			'companionRemote.session.serverRunningDescription' => 'อุปกรณ์มือถือบนเครือข่ายของคุณสามารถเชื่อมต่อกับแอปนี้',
			'companionRemote.session.serverStoppedDescription' => 'เปิดเซิร์ฟเวอร์เพื่อให้อุปกรณ์มือถือสามารถเชื่อมต่อได้',
			'companionRemote.session.usePhoneToControl' => 'ใช้อุปกรณ์มือถือของคุณเพื่อควบคุมแอปนี้',
			'companionRemote.session.startServer' => 'เริ่มต้นเซิร์ฟเวอร์',
			'companionRemote.session.stopServer' => 'ปิดเซิร์ฟเวอร์',
			'companionRemote.session.minimize' => 'minimizing',
			'companionRemote.session.manualAddressHint' => 'ที่อยู่การเชื่อมต่อแบบคู่มือ:',
			'companionRemote.pairing.discoveryDescription' => 'PlezyNG อุปกรณ์ที่มีบัญชี Plex ที่ปรากฏที่นี่',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'การเชื่อมต่อ...',
			'companionRemote.pairing.searchingForDevices' => 'ค้นหาอุปกรณ์',
			'companionRemote.pairing.noDevicesFound' => 'ไม่มีอุปกรณ์ที่พบในเครือข่ายของคุณ',
			'companionRemote.pairing.noDevicesHint' => 'เปิด PlezyNG บนโต๊ะทํางานและใช้ Wi-Fi',
			'companionRemote.pairing.availableDevices' => 'อุปกรณ์ที่มีอยู่',
			'companionRemote.pairing.manualConnection' => 'การเชื่อมต่อคู่มือ',
			'companionRemote.pairing.cryptoInitFailed' => 'ไม่สามารถเริ่มต้นการเชื่อมต่อที่ปลอดภัยลงชื่อเข้าสู่ระบบที่ Plex ก่อน',
			'companionRemote.pairing.validationHostRequired' => 'กรุณาเข้าสู่ที่อยู่อาศัยโฮสต์',
			'companionRemote.pairing.validationHostFormat' => 'รูปแบบจะต้องเป็น IP:port (เช่น 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'การเชื่อมต่อหมดเวลา ใช้เครือข่ายเดียวกันบนทั้งสองอุปกรณ์',
			'companionRemote.pairing.sessionNotFound' => 'อุปกรณ์ไม่ได้พบ ตรวจสอบให้แน่ใจว่า PlezyNG ทํางานบนโฮสต์',
			'companionRemote.pairing.authFailed' => 'การรับรองไม่สามารถรับรองได้ ทั้งสองอุปกรณ์ต้องการบัญชี Plex ที่เดียวกัน',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'ไม่สามารถเชื่อมต่อได้: ${error}',
			'companionRemote.pairing.codeTitle' => 'คู่รหัส',
			'companionRemote.pairing.codeDescription' => 'ใส่รหัสที่แสดงใน Companion Remote บนอุปกรณ์โฮสต์ ทั้งสองอุปกรณ์จะต้องใช้รุ่นที่สนับสนุนการเชื่อมต่อที่ปลอดภัย',
			'companionRemote.pairing.codeInvalid' => 'ใส่ทั้งหมด 32 หมายเลขและหมายเลขจากรหัสโฮสต์',
			'companionRemote.pairing.updateRequired' => 'ปรับปรุงทั้งอุปกรณ์ไปยังรุ่นที่สนับสนุนการเชื่อมต่อที่ปลอดภัย',
			'companionRemote.pairing.hostDescription' => 'ใส่รหัสนี้ครั้งเดียวในแต่ละระยะไกล ปกป้องความเป็นส่วนตัว: มันให้การควบคุมของโปรไฟล์นี้',
			'companionRemote.pairing.resetCode' => 'คู่รหัสรีเซ็ต',
			'companionRemote.pairing.resetDescription' => 'ปิดการเชื่อมต่อทั้งหมดและสร้างรหัสใหม่แต่ละรหัสจะจําเป็นต้องคู่อีกครั้ง',
			'companionRemote.remote.disconnectConfirm' => 'คุณต้องการปิดการเชื่อมต่อจากเซสชั่นระยะไกลหรือไม่',
			'companionRemote.remote.reconnecting' => 'การเชื่อมต่อ...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'การทดลอง ${current} ของ 5',
			'companionRemote.remote.retryNow' => 'กลับตอนนี้',
			'companionRemote.remote.tabRemote' => 'ระยะไกล',
			'companionRemote.remote.tabPlay' => 'เล่น',
			'companionRemote.remote.tabMore' => 'เพิ่มเติม',
			'companionRemote.remote.menu' => 'โมดูล',
			'companionRemote.remote.tabNavigation' => 'แท็บ Navigation',
			'companionRemote.remote.tabDiscover' => 'ค้นหา',
			'companionRemote.remote.tabLibraries' => 'ห้องสมุด',
			'companionRemote.remote.tabSearch' => 'ค้นหา',
			'companionRemote.remote.tabDownloads' => 'รายการดาวน์โหลด',
			'companionRemote.remote.tabSettings' => 'การตั้งค่า',
			'companionRemote.remote.previous' => 'ก่อนหน้านี้',
			'companionRemote.remote.playPause' => 'เล่น / ปาก',
			'companionRemote.remote.next' => 'ถัดไป',
			'companionRemote.remote.seekBack' => 'ค้นหากลับ',
			'companionRemote.remote.stop' => 'หยุด',
			'companionRemote.remote.seekForward' => 'ค้นหา FWD',
			'companionRemote.remote.volume' => 'จํานวน',
			'companionRemote.remote.volumeDown' => 'ลง',
			'companionRemote.remote.volumeUp' => 'ขึ้น',
			'companionRemote.remote.fullscreen' => 'เต็มหน้าจอ',
			'companionRemote.remote.subtitles' => 'คำบรรยาย',
			'companionRemote.remote.audio' => 'เสียง',
			'companionRemote.remote.searchHint' => 'ค้นหาบน Desktop',
			'companionRemote.errors.noNetworkInterface' => 'ไม่พบอินเตอร์เฟซเครือข่าย',
			'companionRemote.errors.authenticationFailed' => 'การรับรองล้มเหลว',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'ไม่สามารถเริ่มต้นเซิร์ฟเวอร์ระยะไกลได้: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'ไม่สามารถส่งคําสั่งจากระยะไกล: ${error}',
			'companionRemote.errors.joinTimedOut' => 'เวลาในการเข้าร่วมประชุม',
			'companionRemote.errors.failedToConnectAnyAddress' => 'ไม่สามารถเชื่อมต่อไปยังที่อยู่ใด ๆ',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'การเชื่อมต่อที่สูญเสียหลังจาก ${attempts} การพยายาม',
			'companionRemote.errors.connectionLost' => 'การเชื่อมต่อที่สูญเสีย',
			'companionRemote.closedBeforeAuth' => 'การเชื่อมต่อปิดก่อนการรับรอง',
			'videoSettings.playbackSpeed' => 'ความเร็ว Playback',
			'videoSettings.normalSpeed' => 'หลักสูตร',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'การใช้งาน (${duration})',
			'videoSettings.zoom' => 'โซม',
			'videoSettings.sleepTimer' => 'เวลานอน',
			'videoSettings.audioSync' => 'โซฟิกเสียง',
			'videoSettings.subtitleSync' => 'ซอฟต์แวร์ Sync',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'HDR ไม่สามารถใช้ได้ที่นี่ - เครื่องเขียนโต๊ะหรือวิดีโอนี้ไม่สามารถนํามาใช้ได้',
			'videoSettings.hdrToneMapping' => 'การ์ตูน HDR',
			'videoSettings.hdrToneMappingCompositor' => 'คอมโพสิต',
			'videoSettings.hdrToneMappingCompositorDescription' => 'ผ่านข้อมูล HDR ของแหล่งข้อมูลและปล่อยให้เครื่องเขียนตารางแผนที่',
			'videoSettings.hdrToneMappingPlayer' => 'ตัวเล่น',
			'videoSettings.hdrToneMappingPlayerDescription' => 'แผนที่เพื่อความสว่างสูงสุดของจอแสดงผลในผู้เล่นแล้วบอกนักแสดงผล',
			'videoSettings.hdrToneMappingFailed' => 'ไม่สามารถเปลี่ยนการ์ดเสียง HDR - โหมดก่อนหน้านี้ยังคงใช้งานได้',
			'videoSettings.audioOutput' => 'การออกเสียง',
			'videoSettings.performanceOverlay' => 'ประสิทธิภาพ Overlay',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'รอบ',
			'videoSettings.audioOutputSpatial' => 'อากาศเสียง',
			'videoSettings.audioOutputStereo' => 'สเตียรอยด์',
			'videoSettings.audioEqualizer' => 'ออนไลน์ Equalizer',
			'videoSettings.audioEqualizerDescription' => 'การปรับตัวห้าแถบความถี่สําหรับอุปกรณ์นี้ สามารถใช้ได้บน mpv ใช้งานได้ EQ decodes เสียงและปิดผนึก',
			'videoSettings.audioEqualizerFlat' => 'ใบไม้ผลิ',
			'videoSettings.audioEqualizerActive' => 'คู่มือ',
			'videoSettings.audioEqualizerSaveFailed' => 'ฉันไม่สามารถบันทึกการตั้งค่าของ Audio Equalizer',
			'videoSettings.backgroundVideoAudio' => 'วิดีโอเสียงพื้นหลัง',
			'videoSettings.backgroundVideoAudioDescription' => 'ปล่อยให้วิดีโอเสียงเล่นเมื่อคุณออกจากผู้เล่น ภาพถูกซ่อนจนกว่าคุณจะกลับมา Android ใช้การแจ้งเตือนการเล่นสื่อ',
			'videoSettings.audioNormalization' => 'การปรับเสียง',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'ลบเสียงไปยัง PCM; passthrough จะปิดในขณะที่นี้จะ',
			'performanceOverlay.color' => 'สี',
			'performanceOverlay.performance' => 'การแสดงผล',
			'performanceOverlay.buffer' => 'บูฟเฟอร์',
			'performanceOverlay.app' => 'แอป',
			'performanceOverlay.decoder' => 'การตกแต่ง',
			'performanceOverlay.rawDecoder' => 'วัตถุประสงค์',
			'performanceOverlay.tunneling' => 'ทนเลอร์',
			'performanceOverlay.passthrough' => 'โพสต์',
			'performanceOverlay.aspect' => 'ความเห็น',
			'performanceOverlay.rotation' => 'การหมุน',
			'performanceOverlay.dvSource' => 'หลักฐาน',
			'performanceOverlay.dvPath' => 'สองเส้นทาง',
			'performanceOverlay.dvRouteDecoder' => 'ตัวถอดรหัส Dolby Vision',
			'performanceOverlay.dvRouteDecoderP81' => 'ตัวถอดรหัส Dolby Vision (P7→8.1)',
			'performanceOverlay.dvRouteBaseLayer' => 'ฐานชั้น',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'HDR10 ชั้นฐาน',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'HLG ฐานชั้น',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'SDR ฐานชั้น',
			'performanceOverlay.dvRouteReshaped' => 'RPU แก้ไข (gpu-next)',
			'performanceOverlay.p7Conversion' => 'การแปลง P7',
			'performanceOverlay.sampleRate' => 'ตัวอย่างอัตรา',
			'performanceOverlay.pixelFormat' => 'พิกเซล Fmt',
			'performanceOverlay.hwFormat' => 'มณฑลสหรัฐอเมริกา',
			'performanceOverlay.matrix' => 'มะตริก',
			'performanceOverlay.primaries' => 'หลัก',
			'performanceOverlay.transfer' => 'การถ่ายโอน',
			'performanceOverlay.renderFps' => 'ฟิล์ม',
			'performanceOverlay.displayFps' => 'แสดง FPS',
			'performanceOverlay.avSync' => 'A / V Sync',
			'performanceOverlay.dropped' => 'ละลาย',
			'performanceOverlay.dvRpus' => 'DV RPUs',
			'performanceOverlay.dvRpuAverage' => 'DV RPU AVG',
			'performanceOverlay.dvSampleAverage' => 'DV ตัวอย่าง Avg',
			'performanceOverlay.maxLuma' => 'แม็กซ์ Luma',
			'performanceOverlay.minLuma' => 'มิน Luma',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Cache ใช้',
			'performanceOverlay.cacheLimit' => 'หมายเลขรุ่น: Cache Limit',
			'performanceOverlay.speed' => 'ความเร็ว',
			'performanceOverlay.player' => 'ตัวเล่น',
			'performanceOverlay.playMethod' => 'วิธีการเล่น',
			'performanceOverlay.memory' => 'ความจํา',
			'performanceOverlay.uiFps' => 'ภาษาไทย',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android HW',
			'performanceOverlay.decoderNvidiaHw' => 'NVIDIA HW',
			'performanceOverlay.decoderQualcommHw' => 'คอลัมคัม HW',
			'performanceOverlay.decoderMediatekHw' => 'โมเดียม HW',
			'performanceOverlay.decoderExynosHw' => 'แอพลิเคชัน HW',
			'performanceOverlay.decoderSoftware' => 'ซอฟต์แวร์',
			'performanceOverlay.decoderHardware' => 'ฮาร์ดแวร์',
			'performanceOverlay.tunnelingActive' => 'การใช้งาน',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted} (${failures} ไม่สําเร็จ)',
			'externalPlayer.title' => 'ผู้เล่นภายนอก',
			'externalPlayer.useExternalPlayer' => 'ใช้ผู้เล่นภายนอก',
			'externalPlayer.useExternalPlayerDescription' => 'เปิดวิดีโอในแอปอื่น ๆ',
			'externalPlayer.selectPlayer' => 'เลือกผู้เล่น',
			'externalPlayer.customPlayers' => 'ผู้เล่นที่กําหนดเอง',
			'externalPlayer.systemDefault' => 'ระบบที่กําหนดเอง',
			'externalPlayer.addCustomPlayer' => 'เพิ่มผู้เล่นที่กําหนดเอง',
			'externalPlayer.playerName' => 'ชื่อผู้เล่น',
			'externalPlayer.playerNameHint' => 'ผู้เล่นของเรา',
			'externalPlayer.playerCommand' => 'คอมเมนต์',
			'externalPlayer.playerPackage' => 'ชื่อแพคเกจ',
			'externalPlayer.playerUrlScheme' => 'แผนที่ URL',
			'externalPlayer.off' => 'ปิด',
			'externalPlayer.launchFailed' => 'ไม่สามารถเปิดผู้เล่นภายนอกได้',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} ไม่ติดตั้ง',
			'externalPlayer.playInExternalPlayer' => 'เล่นในผู้เล่นภายนอก',
			'metadataEdit.editMetadata' => 'แก้ไข',
			'metadataEdit.screenTitle' => 'การแก้ไข Metadata',
			'metadataEdit.basicInfo' => 'ข้อมูลพื้นฐาน',
			'metadataEdit.artwork' => 'งานศิลปะ',
			'metadataEdit.advancedSettings' => 'การตั้งค่าขั้นสูง',
			'metadataEdit.title' => 'ชื่อเรื่อง',
			'metadataEdit.sortTitle' => 'ชื่อที่แตกต่างกัน',
			'metadataEdit.originalTitle' => 'ชื่อเดิม',
			'metadataEdit.releaseDate' => 'วันที่ปล่อย',
			'metadataEdit.contentRating' => 'ระดับเนื้อหา',
			'metadataEdit.studio' => 'สตูดิโอ',
			'metadataEdit.tagline' => 'คำโปรย',
			'metadataEdit.summary' => 'คําอธิบาย',
			'metadataEdit.poster' => 'โพสต์',
			'metadataEdit.background' => 'ลักษณะ',
			'metadataEdit.logo' => 'โลโก้',
			'metadataEdit.squareArt' => 'พื้นที่ศิลปะ',
			'metadataEdit.selectPoster' => 'เลือกโพสต์',
			'metadataEdit.selectBackground' => 'เลือกพื้นหลัง',
			'metadataEdit.selectLogo' => 'เลือกโลโก้',
			'metadataEdit.selectSquareArt' => 'เลือก Square Art',
			'metadataEdit.fromUrl' => 'จาก URL',
			'metadataEdit.uploadFile' => 'ดาวน์โหลดไฟล์',
			'metadataEdit.enterImageUrl' => 'หมายเลข URL',
			'metadataEdit.imageUrl' => 'ภาพ URL',
			'metadataEdit.metadataUpdated' => 'ข้อมูลอัปเดต',
			'metadataEdit.metadataUpdateFailed' => 'ไม่สามารถปรับปรุงข้อมูล metadata',
			'metadataEdit.artworkUpdated' => 'อัพเดทศิลปะ',
			'metadataEdit.artworkUpdateFailed' => 'ไม่สามารถปรับปรุงงานศิลปะได้',
			'metadataEdit.noArtworkAvailable' => 'ไม่มีงานศิลปะ',
			'metadataEdit.artworkOption' => ({required Object index}) => 'ตัวเลือกงานศิลปะ ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'ตัวเลือกงานศิลปะ ${index}, เลือก',
			'metadataEdit.notSet' => 'ไม่ตั้งค่า',
			'metadataEdit.libraryDefault' => 'บีบอิสระ',
			'metadataEdit.accountDefault' => 'บัญชีที่ผิดพลาด',
			'metadataEdit.seriesDefault' => 'ซีรี่ส์ที่กําหนดเอง',
			'metadataEdit.episodeSorting' => 'ประเภท',
			'metadataEdit.oldestFirst' => 'เก่าที่สุดครั้งแรก',
			'metadataEdit.newestFirst' => 'ใหม่แรก',
			'metadataEdit.keep' => 'ปกติ',
			'metadataEdit.allEpisodes' => 'ทุกตอน',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} ครั้งที่เข้าดูล่าสุด',
			'metadataEdit.latestEpisode' => 'ประวัติล่าสุด',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Episodes ที่เพิ่มใน ${count} วันที่ผ่านมา',
			'metadataEdit.deleteAfterPlaying' => 'ลบ Episodes หลังจากเล่น',
			'metadataEdit.never' => 'ไม่เคย',
			'metadataEdit.afterADay' => 'หลังจากหนึ่งวัน',
			'metadataEdit.afterAWeek' => 'หลังจากหนึ่งสัปดาห์',
			'metadataEdit.afterAMonth' => 'หลังจากหนึ่งเดือน',
			'metadataEdit.onNextRefresh' => 'ต่อไปนี้ทําความสะอาด',
			'metadataEdit.seasons' => 'ฤดูกาล',
			'metadataEdit.show' => 'แสดง',
			'metadataEdit.hide' => 'ซ่อน',
			'metadataEdit.episodeOrdering' => 'การสั่งซื้อ',
			'metadataEdit.tmdbAiring' => 'ฐานข้อมูลของภาพยนตร์ (Aired)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (ระบายอากาศ)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (อัลลอฮอล์)',
			'metadataEdit.metadataLanguage' => 'ภาษา Metadata',
			'metadataEdit.useOriginalTitle' => 'ใช้ชื่อเดิม',
			'metadataEdit.preferredAudioLanguage' => 'ภาษาเสียงที่ชื่นชอบ',
			'metadataEdit.preferredSubtitleLanguage' => 'ภาษาที่ชื่นชอบ Subtitle',
			'metadataEdit.subtitleMode' => 'โหมด Subtitle ตัวเลือกอัตโนมัติ',
			'metadataEdit.manuallySelected' => 'เลือกด้วยตนเอง',
			'metadataEdit.shownWithForeignAudio' => 'แสดงด้วยเสียงต่างประเทศ',
			'metadataEdit.alwaysEnabled' => 'ปัจจุบันเปิดใช้งาน',
			'metadataEdit.tags' => 'แท็ก',
			'metadataEdit.addTag' => 'เพิ่มแท็ก',
			'metadataEdit.genre' => 'ประเภท',
			'metadataEdit.director' => 'ผู้กำกับ',
			'metadataEdit.writer' => 'ผู้เขียน',
			'metadataEdit.producer' => 'ผู้ผลิต',
			'metadataEdit.country' => 'ประเทศ',
			'metadataEdit.collection' => 'การจัดเก็บ',
			'metadataEdit.label' => 'แท็ก',
			'metadataEdit.quickTag' => 'Tag อัตรา...',
			'matchScreen.match' => 'การแข่งขัน',
			'matchScreen.fixMatch' => 'ปรับการแข่งขัน',
			'matchScreen.unmatch' => 'การแข่งขัน',
			'matchScreen.unmatchConfirm' => 'ลบเกมนี้? Plex รักษามันเป็นไม่แข่งขันจนถึงเสร็จสิ้น',
			'matchScreen.unmatchSuccess' => 'รายการที่ไม่สมบูรณ์',
			'matchScreen.unmatchFailed' => 'ข้อผิดพลาดในการไม่เข้าถึงรายการ',
			'matchScreen.matchApplied' => 'การแข่งขันใช้',
			'matchScreen.matchFailed' => 'ไม่สามารถใช้การแข่งขัน',
			'matchScreen.titleHint' => 'ชื่อเรื่อง',
			'matchScreen.yearHint' => 'ปี',
			'matchScreen.search' => 'ค้นหา',
			'matchScreen.noMatchesFound' => 'ไม่พบการแข่งขัน',
			'serverTasks.title' => 'งานเซิร์ฟเวอร์',
			'serverTasks.failedToLoad' => 'ไม่สามารถโหลดงานได้',
			'serverTasks.noTasks' => 'ไม่มีงานที่ทํางาน',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'เชื่อมต่อ',
			'trakt.connectedAs' => ({required Object username}) => 'เชื่อมต่อที่ @${username}',
			'trakt.disconnectConfirm' => 'ปิดการเชื่อมต่อบัญชี Trakt',
			'trakt.disconnectConfirmBody' => 'PlezyNG จะหยุดส่งกิจกรรมไปยัง Trakt. คุณสามารถเชื่อมต่อใหม่ได้ตลอดเวลา',
			'trakt.scrobble' => 'ระยะเวลาจริง scrobbling',
			'trakt.scrobbleDescription' => 'ส่งการเล่นหยุดและหยุดกิจกรรมไปยัง Trakt ในระหว่างการเล่น',
			'trakt.watchedSync' => 'สภาพที่สังเกต',
			'trakt.watchedSyncDescription' => 'เมื่อคุณทําเครื่องหมายรายการตามที่ดูใน PlezyNG พวกเขาจะทําเครื่องหมายตามที่ดูใน Trakt',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'เชื่อมต่อ Seerr',
			'seerr.serverUrl' => 'URL ของเซิร์ฟเวอร์',
			'seerr.serverUrlHelper' => 'ที่อยู่ของตัวอย่าง Seerr ของคุณ',
			'seerr.checkServer' => 'เสร็จสิ้น',
			'seerr.signInWithJellyfin' => 'ลงทะเบียนกับ Jellyfin',
			'seerr.signInWithEmby' => 'ลงทะเบียนกับ Emby',
			'seerr.signInWithLocal' => 'ใช้บัญชีท้องถิ่น',
			'seerr.email' => 'อีเมล',
			'seerr.noSignInMethods' => 'ตัวอย่าง Seerr นี้ไม่ให้การลงชื่อเข้าใช้วิธีการ PlezyNG สนับสนุน',
			'seerr.instance' => 'สัปดาห์',
			'seerr.disconnectConfirm' => 'ปิดเชื่อมต่อ Seerr',
			'seerr.disconnectConfirmBody' => 'PlezyNG จะลืมตัวอย่าง Seerr นี้ ติดต่ออีกครั้งตลอดเวลา',
			'seerr.request' => 'คําขอ',
			'seerr.request4k' => 'คําขอใน 4K',
			'seerr.seasons' => 'ฤดูกาล',
			'seerr.allSeasons' => 'ทุกฤดูกาล',
			'seerr.advancedOptions' => 'ขั้นสูง',
			'seerr.destinationServer' => 'เซิร์ฟเวอร์ปลายทาง',
			'seerr.qualityProfile' => 'คุณภาพโปรไฟล์',
			'seerr.rootFolder' => 'รูตาราง',
			'seerr.languageProfile' => 'โปรไฟล์ภาษา',
			'seerr.tags' => 'แท็ก',
			'seerr.noTags' => 'ไม่มีแท็ก',
			'seerr.defaultOption' => ({required Object name}) => '${name} (เริ่มต้น)',
			'seerr.animeNote' => 'ชุดนี้เป็น anime',
			'seerr.requestSubmitted' => 'คําขอที่ส่ง',
			'seerr.requestFailed' => ({required Object error}) => 'คําขอที่ผิดพลาด: ${error}',
			'seerr.requestsLoadFailed' => 'ไม่สามารถโหลดตัวเลือกการร้องขอ',
			'seerr.nothingToRequest' => 'ทุกอย่างที่มีอยู่หรือขอ',
			'seerr.statusAvailable' => 'มี',
			'seerr.statusPartiallyAvailable' => 'มีส่วนหนึ่ง',
			'seerr.statusRequested' => 'คําขอ',
			'seerr.statusProcessing' => 'การประมวลผล',
			'seerr.statusBlocklisted' => 'บล็อก',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => 'ไม่สามารถเข้าถึง ${url}: ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => 'ไม่มีกรณี Seerr ที่ ${url} (HTTP ${status})',
			'seerr.behindAuthProxy' => 'โพคซีกลับที่ได้รับการรับรอง (SSO หรือ HTTP auth) ที่ตอบแทน Seerr PlezyNG ไม่สามารถลงทะเบียนผ่านมันได้: ให้เส้นทาง /api/v1 ของ Seerr ผ่านโพคซีสําหรับแอปนี้หรือใช้ที่อยู่ที่เข้าถึง Seerr โดยตรง',
			'seerr.invalidUrl' => 'ใส่ที่อยู่อีเมลเซิร์ฟเวอร์เช่น https://seerr.example.com',
			'seerr.quickConnectUnsupported' => 'ตัวอย่าง Seerr นี้ไม่สนับสนุน Quick Connect. มันต้องการ Seerr 3.4 หรือใหม่กว่า',
			'seerr.notInitialized' => 'ตัวอย่างนี้ Seerr ไม่ได้เสร็จสิ้นการตั้งค่าครั้งแรก',
			'seerr.noPlexTokenForReauth' => 'No Plex token มีการลงทะเบียนอีกครั้ง',
			'seerr.noStoredCredentials' => 'ไม่มีใบรับรองที่เก็บไว้พร้อมที่จะลงทะเบียนอีกครั้ง',
			'seerr.signInRejected' => 'การลงทะเบียนถูกปฏิเสธ',
			'seerr.noSessionCookie' => 'Seerr ไม่ได้ปล่อยคุกกี้การประชุม',
			'seerr.freshCookieRejected' => 'Seerr ยกเลิกคุกกี้เซสชั่นใหม่',
			'seerr.noUserInformation' => 'Seerr ไม่ได้คืนข้อมูลผู้ใช้',
			'seerr.sessionRejectedAfterReauth' => 'การประชุมถูกปฏิเสธหลังจากการลงทะเบียนอีกครั้ง',
			'seerr.permissionDenied' => 'Seerr ไม่ยอมรับการกระทํานี้: บัญชีของคุณไม่ได้รับอนุญาตที่ต้องการ',
			'seerr.permissionRevoked' => 'คุณไม่สามารถร้องขอได้อีกต่อไป',
			'services.title' => 'บริการ',
			'services.hubSubtitle' => 'Sync ดูการพัฒนาและขอชื่อใหม่',
			'services.integrations' => 'การรวมกัน',
			'services.notConnected' => 'ไม่เชื่อมต่อ',
			'services.connectedAs' => ({required Object username}) => 'เชื่อมต่อที่ @${username}',
			'services.scrobble' => 'ติดตามขั้นตอนโดยอัตโนมัติ',
			'services.scrobbleDescription' => 'ปรับปรุงรายการของคุณเมื่อคุณเสร็จสิ้นการจัดงานหรือภาพยนตร์',
			'services.disconnectConfirm' => ({required Object service}) => 'ปิดการเชื่อมต่อ ${service}',
			'services.disconnectConfirmBody' => ({required Object service}) => 'PlezyNG จะหยุดการอัพเดท ${service}. ติดต่ออีกครั้งตลอดเวลา',
			'services.connectFailed' => ({required Object service}) => 'ฉันไม่สามารถเชื่อมต่อกับ ${service}. ลองอีกครั้ง',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'การเชื่อมต่อใหม่ Simkl',
			'services.simklReconnect.subtitle' => 'Simkl จะลบวิธีการลงชื่อเข้าใช้การเชื่อมต่อนี้ ใช้ การเชื่อมต่อใหม่เปิด simkl.com เพื่อให้ได้รับการอนุมัติ PlezyNG — PlezyNG ไม่เคยเห็นรหัสผ่านของคุณ ประวัตินาฬิกาของคุณยังคงอยู่บน Simkl.',
			'services.deviceCode.title' => ({required Object service}) => 'เปิดใช้งาน PlezyNG บน ${service}',
			'services.deviceCode.instructions' => 'สแกนรหัส QR หรือเยี่ยมชมที่อยู่ด้านล่างและป้อนรหัสนี้:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'เปิด ${service} เพื่อเปิดใช้งาน',
			'services.deviceCode.copyCode' => 'คัดลอกรหัสการใช้งาน',
			'services.deviceCode.waitingForAuthorization' => 'รอการรับอนุญาต ...',
			'services.deviceCode.codeCopied' => 'รหัสคัดลอก',
			'services.oauthProxy.title' => ({required Object service}) => 'ลงชื่อเข้าสู่ระบบ ${service}',
			'services.oauthProxy.body' => 'สแกนรหัส QR นี้หรือเปิด URL บนอุปกรณ์ใด ๆ',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'เปิด ${service} เพื่อลงทะเบียน',
			'services.pendingAuth.copyUrl' => 'คัดลอก sign-in URL',
			'services.pendingAuth.urlCopied' => 'URL คัดลอก',
			'services.libraryFilter.title' => 'ห้องสมุดกรอง',
			'services.libraryFilter.subtitleAllSyncing' => 'การซิงค์สมุดทั้งหมด',
			'services.libraryFilter.subtitleNoneSyncing' => 'ไม่มีการสังเคราะห์',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} บล็อก',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} อนุญาต',
			'services.libraryFilter.mode' => 'โหมดกรอง',
			'services.libraryFilter.modeBlacklist' => 'แบล็คลิสต์',
			'services.libraryFilter.modeWhitelist' => 'บลอนด์',
			'services.libraryFilter.modeHintBlacklist' => 'การซิงค์ทุกห้องสมุดยกเว้นที่ตรวจสอบด้านล่าง',
			'services.libraryFilter.modeHintWhitelist' => 'Sync เท่านั้นห้องสมุดที่ตรวจสอบด้านล่าง',
			'services.libraryFilter.libraries' => 'ห้องสมุด',
			'services.libraryFilter.noLibraries' => 'ไม่มีห้องสมุด',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => 'เพิ่มเซิร์ฟเวอร์ ${product}',
			'addServer.serverUrls' => 'URL ของเซิร์ฟเวอร์',
			'addServer.serverUrlsHelper' => 'URL จํานวนมากที่ได้รับอนุญาตแยกโดย commas',
			'addServer.findServer' => 'ค้นหาเซิร์ฟเวอร์',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'ค้นหาเซิร์ฟเวอร์ท้องถิ่น ${product} ...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'เซิร์ฟเวอร์ท้องถิ่น ${product}',
			'addServer.username' => 'ชื่อผู้ใช้',
			'addServer.password' => 'คู่มือ',
			'addServer.signIn' => 'เข้าสู่ระบบ',
			'addServer.change' => 'การเปลี่ยนแปลง',
			'addServer.required' => 'ความต้องการ',
			'addServer.couldNotReachServer' => ({required Object error}) => 'ไม่สามารถเข้าถึงเซิร์ฟเวอร์: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'การลงทะเบียนที่ผิดพลาด: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect ความล้มเหลว: ${error}',
			'addServer.addPlexTitle' => 'ลงทะเบียนกับ Plex',
			'addServer.pinExpired' => 'PIN หมดอายุก่อนลงชื่อเข้าสู่ระบบ โปรดลองอีกครั้ง',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'บัญชีที่ไม่ได้ลงทะเบียน: ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => 'ใส่ URL ของเซิร์ฟเวอร์ ${product}',
			'addServer.addConnectionTitle' => 'เพิ่มการเชื่อมต่อ',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'เพิ่มไปยัง ${name}',
			'addServer.signInWithPlexCard' => 'ลงทะเบียนกับ Plex',
			'addServer.signInWithPlexCardSubtitle' => 'ปรับรองอุปกรณ์นี้ เซิร์ฟเวอร์ที่แบ่งปันจะเพิ่ม',
			'addServer.signInWithPlexCardSubtitleScoped' => 'รับอนุญาตให้มีบัญชี Plex ผู้ใช้บ้านกลายเป็นโปรไฟล์',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => 'ติดต่อ ${product}',
			'addServer.connectToMediaBrowserCardSubtitle' => 'ใส่ URL, ชื่อผู้ใช้และรหัสผ่านเซิร์ฟเวอร์ของคุณ',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => 'ลงชื่อเข้าสู่เซิร์ฟเวอร์ ${product}. เชื่อมต่อกับ ${name}.',
			'addServer.borrowFromAnotherProfile' => 'โอกาสจากโปรไฟล์อื่น ๆ',
			'addServer.borrowFromAnotherProfileSubtitle' => 'ใช้การเชื่อมต่อของโปรไฟล์อื่น ๆ โปรไฟล์ที่ปกป้องด้วย PIN ต้องใช้ PIN',
			'addServer.invalidCredentials' => 'ชื่อผู้ใช้หรือรหัสผ่านที่ไม่ถูกต้อง',
			'addServer.authResponseNotJson' => 'คําตอบการรับรองไม่ได้รับการรับรอง JSON',
			'addServer.authResponseIncomplete' => 'การตอบสนองการลงชื่อเข้าจากเซิร์ฟเวอร์ไม่สมบูรณ์',
			'addServer.quickConnectRejected' => 'Quick Connect ได้รับการปฏิเสธโดยเซิร์ฟเวอร์',
			'addServer.quickConnectNotJson' => 'คําตอบ Quick Connect ไม่ถูกต้อง JSON',
			'addServer.quickConnectMissingFields' => 'คําตอบ Quick Connect ไม่มีรหัสหรือความลับ',
			'addServer.quickConnectPollRejected' => 'Quick Connect การสอบถามถูกปฏิเสธโดยเซิร์ฟเวอร์',
			'addServer.serverTimedOut' => 'เซิร์ฟเวอร์ไม่ตอบสนองในเวลา',
			'addServer.responseNotJson' => 'คําตอบเซิร์ฟเวอร์ไม่ถูกต้อง JSON',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'คําตอบที่ขาด ID หรือชื่อเซิร์ฟเวอร์ - นี้คือเซิร์ฟเวอร์ ${product}?',
			'addServer.probeFailed' => ({required Object error}) => 'ไม่สามารถเข้าถึงเซิร์ฟเวอร์: ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => 'ใส่ URL server ${product} หนึ่งอย่างน้อย',
			'addServer.noReachableServer' => ({required Object product}) => 'ไม่พบเซิร์ฟเวอร์ที่สามารถเข้าถึงได้ ${product}',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'URLs เหล่านี้หมายถึงเซิร์ฟเวอร์ที่แตกต่างกัน ${product}',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'URL นี้ไม่ตรงกับเซิร์ฟเวอร์ ${product}',
			'addServer.redirectUnsupported' => 'เซิร์ฟเวอร์ที่นําไปสู่ URL ที่ไม่ได้สนับสนุน',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'เซิร์ฟเวอร์ที่นําไปสู่โฮสต์ที่แตกต่างกัน ใส่ URL ${product} สุดท้ายโดยตรง',
			'addServer.redirectInsecure' => 'เซิร์ฟเวอร์ที่นําทางจาก HTTPS ไปยัง URL ไม่ปลอดภัย',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'เซิร์ฟเวอร์ที่ถูกนําไปสู่ URL ที่ไม่ได้รับการสนับสนุน ใส่ URL ${product} สุดท้ายโดยตรง',
			'addServer.directPlexServerUrl' => 'Plex URL เซิร์ฟเวอร์',
			'addServer.directPlexServerUrlHelper' => 'เข้าสู่ IP และพอร์ตท้องถิ่นของเซิร์ฟเวอร์ Media Plex ของคุณ',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex Token (ตัวเลือก)',
			'addServer.plexTokenHelper' => 'ปล่อยให้ว่างเปล่าหากการเข้าถึงโดยไม่มี auth จะได้รับอนุญาตบนเซิร์ฟเวอร์นี้',
			'addServer.plexTokenRequired' => 'การรับรองที่จําเป็น โปรดเข้าสู่ token Plex ของคุณ (X-Plex-Token)',
			'addServer.connectDirectPlexCard' => 'Plex เซิร์ฟเวอร์สื่อ (โดยตรง / ไซต์)',
			'addServer.connectDirectPlexCardSubtitle' => 'เชื่อมต่อโดยตรงโดยใช้ IP หรือ URL ภายในโดยไม่ต้องใช้บัญชี plex.tv',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => 'เชื่อมต่อโดยตรงโดยใช้ IP หรือ URL ท้องถิ่น เชื่อมต่อไปยัง ${name}.',
			'addServer.insecureTitle' => 'การเชื่อมต่อที่ไม่เข้ารหัส',
			'addServer.insecureDescription' => ({required Object url}) => '${url} ใช้ HTTP บุคคลอื่นในเครือข่ายอาจอ่านหรือแก้ไขรหัสผ่าน โทเค็น และสื่อของคุณได้ โปรดใช้ HTTPS หากมีให้ใช้ ดำเนินการต่อเฉพาะเมื่อคุณเชื่อถือเครือข่ายนี้และยอมรับความเสี่ยง',
			'addServer.allowHttp' => 'อนุญาต HTTP',
			'addServer.httpsRequired' => 'ใช้ HTTPS หรืออนุญาตให้มีการเชื่อมต่อที่ไม่ได้เข้ารหัส',
			'watchLink.serverUnavailable' => 'ฉันไม่สามารถเข้าถึงเซิร์ฟเวอร์ Plex สําหรับลิงค์นี้',
			'watchLink.notFound' => 'ฉันไม่สามารถหาการแสดงหรือภาพยนตร์นี้ได้บนเซิร์ฟเวอร์ Plex ของคุณ',
			'watchLink.ambiguous' => 'เชื่อมโยงนี้ตรงกับรายการในเซิร์ฟเวอร์เดียว เพิ่มเซิร์ฟเวอร์ไปยังลิงค์',
			'watchLink.plexOnly' => 'ติดตามลิงค์ในขณะนี้สนับสนุนเซิร์ฟเวอร์ Plex เท่านั้น',
			'watchLink.unsupportedItem' => 'ดูลิงค์สามารถเปิดการแสดงหรือภาพยนตร์เท่านั้น',
			'watchLink.menuItem' => 'ดูลิงค์',
			'watchLink.dialogTitle' => 'ดูลิงค์',
			'watchLink.dialogShowHint' => 'เปิดลิงค์นี้เล่นส่วนต่อไป เพิ่ม &mode=shuffle ไปยังจุดสุดยอดเพื่อเล่นการแสดงบน shuffle',
			'watchLink.dialogMovieHint' => 'เปิดลิงก์นี้เล่นภาพยนตร์',
			'watchLink.copy' => 'คัดลอก',
			'watchLink.copied' => 'ลิงค์คัดลอก',
			'homeLayout.title' => 'Home โลหะ',
			'homeLayout.resetToast' => 'บ้านรีเซ็ตไปยังโครงสร้างพื้นฐาน Plezy',
			'homeLayout.resetHeroTitle' => 'รีเซ็ตโครงสร้างฮีโร่ไปยังสต็อก Plezy?',
			'homeLayout.resetHeroBody' => 'ปิดการตั้งค่าฮีโร่ของแต่ละแถวและนํากลับแบนเนอร์หมุนเดียวที่ด้านบนของบ้านเช่นเดียวกับก่อนที่แถวฮีโร่มีอยู่ แถวและแถวที่แสดงไม่ได้รับผลกระทบ',
			_ => null,
		} ?? switch (path) {
			'homeLayout.removeRowTitle' => 'ปล่อยสายบ้าน',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} จะถูกลบ ไม่สามารถลบได้',
			'homeLayout.sync' => 'ซิงค์',
			'homeLayout.syncAccountTitle' => 'การจัดเรียงซิงค์กับบัญชี Plex ของคุณ',
			'homeLayout.syncAccountOn' => 'บน: อุปกรณ์นี้แบ่งปันคําสั่งลําดับลําดับ Hero และ Auto-slide กับอุปกรณ์อื่น ๆ ของคุณ',
			'homeLayout.syncAccountOff' => 'ปิด: อุปกรณ์นี้ยังคงจัดตั้งของตัวเอง',
			'homeLayout.syncNow' => 'ซิงค์ตอนนี้',
			'homeLayout.plexHomeManager' => 'Plex ผู้จัดการบ้าน',
			'homeLayout.managePlexRows' => 'การจัดการ Plex เถวใน Plezy',
			'homeLayout.managePlexRowsDescription' => 'เปิดเพื่อจัดเตรียมเส้นที่เลือกในบ้าน',
			'homeLayout.organizeHomeRows' => 'การจัดเรียงสายบ้าน',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} เถว: การเคลื่อนไหว, สัตว์ประหลาด, การลบอัตโนมัติ, ลบ',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => 'จัดการ ${library} เถว',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => 'Continue Watching + ${n} เกรด: การเคลื่อนไหว, ห้องสมุด, บ้าน, พระมหากษัตริย์, Auto-slide',
			'homeLayout.renderAsHero' => 'Render ในฐานะที่เป็นการ์ดฮีโร่',
			'homeLayout.heroOnlySingleCollection' => 'เท่านั้นสามารถใช้ได้เมื่อแถวนี้ได้รับการแก้ไขกับชื่อจริงของชุดเดียว',
			'homeLayout.hero' => 'สัตว์เลี้ยง',
			'homeLayout.autoSlide' => 'อัตโนมัติ Slide',
			'homeLayout.autoSlideDescription' => 'นอกจากนี้ยังสไลด์ด้วยตัวเองทุกวินาที Arrows (PC) และ d-pad (TV) ทํางานเสมอและเปิดตัวใหม่ชั่วโมง',
			'homeLayout.autoSlideEditDescription' => 'นอกจากนี้ยังสไลด์ด้วยตัวเองทุกวินาที ปิด: เท่านั้นเคลื่อนที่เมื่อคุณคลิกปืน (พีซี) หรือกดซ้าย / ขวาบนระยะไกล (ทีวี) สไลด์และ d-pad ทํางานเสมอในทางใด ๆ',
			'homeLayout.enableHeroFirst' => 'อนุญาตให้ฮีโร่แรก',
			'homeLayout.showOnHome' => 'แสดงบนหน้าจอบ้าน',
			'homeLayout.home' => 'บ้าน',
			'homeLayout.removeFromHome' => 'เอาจากบ้าน',
			'homeLayout.selectRowsFirst' => 'เลือกเส้นบ้านด้านล่างแรก',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} Plex สายการจัดการ',
			'homeLayout.continueWatching' => 'ดูต่อ',
			'homeLayout.continueWatchingLibraryDescription' => 'เถื่อนขั้นสูงของห้องสมุดนี้เอง',
			'homeLayout.continueWatchingHomeDescription' => 'เถื่อนขั้นตอนที่แสดงไว้ในบ้าน',
			'homeLayout.nextUpHomeDescription' => 'ต่อไปไม่ได้รับการสังเกต episod sequence แสดงแยกต่างหากใน Home',
			'homeLayout.library' => 'คลังสื่อ',
			'homeLayout.showInRecommended' => 'แสดงในห้องสมุดแนะนํา',
			'homeLayout.customPlexRow' => 'คู่มือ Plex รอบ',
			'homeLayout.heroNeedsLibrary' => 'ตรวจสอบห้องสมุดแรก — Hero ต้องการที่ไหนที่จะแสดง',
			'homeLayout.heroNeedsSurface' => 'ตรวจสอบห้องสมุดหรือบ้านแรก — สัตว์ประหลาดต้องการที่ไหนที่จะแสดง',
			'homeLayout.removeHub' => 'ลบ Hub',
			'homeLayout.noPlexRows' => 'หมายเลข Plex-จัดการสายกลับสําหรับห้องสมุดนี้',
			'homeLayout.openDetails' => 'รายละเอียดเปิด',
			'homeLayout.heroCards' => 'บัตรฮีโร่',
			'homeLayout.tapHeroCard' => 'การสูญเสียการ์ดฮีโร่',
			'homeLayout.tvPlayFocus' => 'โทรทัศน์ระยะไกล: ปุ่ม Play',
			'homeLayout.tvPlayFocusDescription' => 'D-pad down stops on the Play button before moving to the next row ปิดสกีตรงไปสู่ row ต่อไป',
			'homeLayout.tvWrap' => 'โทรทัศน์ระยะไกล: ล็อปการ์ดฮีโร่',
			'homeLayout.tvWrapDescription' => 'ขวาบนบัตรสุดท้ายจะกลับไปสู่บัตรแรก ปิดหยุดในบัตรสุดท้าย ป้ายบนบัตรแรกจะไปสู่แถบด้านข้างเสมอ',
			'homeLayout.castOnHero' => 'การเล่นบนฮีโร่แบนเนอร์',
			'homeLayout.castOnHeroDescription' => 'แสดงการแสดงออกอยู่ด้านล่างของแบนเนอร์ฮีโร่ ปิดยังคงเพียงชื่อและสรุป',
			'homeLayout.customRows' => 'สายการกําหนดเอง',
			'homeLayout.loading' => 'โหลดบ้าน layout ...',
			'homeLayout.noCustomRows' => 'ไม่มีการกําหนดเอง',
			'homeLayout.addRowHint' => 'ใช้ Add Home เถวเพื่อสร้างหนึ่ง',
			'homeLayout.addHomeRow' => 'เพิ่มเรือนบ้าน',
			'homeLayout.addHomeRowDescription' => 'เลือกหมวดหมู่ ใบสั่งใหม่จะถูกเพิ่มไปยังผู้จัดงานโดยอัตโนมัติ',
			'homeLayout.removeRow' => 'ลบแถว',
			'homeLayout.recentlyAdded' => 'เพิ่มล่าสุด',
			'homeLayout.recentlyReleased' => 'ปล่อยล่าสุด',
			'homeLayout.movieCollections' => 'คอลเลกชันภาพยนตร์',
			'homeLayout.showCollections' => 'แสดงคอลเลกชัน',
			'homeLayout.rowTitle' => 'รูชื่อ',
			'homeLayout.content' => 'ความสุข',
			'homeLayout.showThisRowIn' => 'แสดงแถวนี้ใน:',
			'homeLayout.libraryRecommended' => 'โบรชัวร์ที่แนะนํา',
			'homeLayout.heroCard' => 'บัตรฮีโร่',
			'homeLayout.heroCardDescription' => 'แสดงเป็นบัตรหมุนกว้างเดียวแทนที่กระดาษโพสต์',
			'homeLayout.heroUnavailableDescription' => 'มีเพียงเมื่อแถวนี้ได้รับการแก้ไขกับชื่อจริงของคอลเลกชันเดียว - ด้วยคอลเลกชันหนึ่งที่เลือกไม่มีชื่อเดียวที่จะหมุนผ่าน',
			'homeLayout.librariesSelection' => 'ห้องสมุด (ปล่อยให้ทั้งหมดไม่ตรวจสอบเพื่อรวมห้องสมุดแต่ละห้อง)',
			'homeLayout.librariesMergedDescription' => 'ทุกห้องสมุดที่ตรวจสอบที่นี่จะรวมอยู่ในบรรทัดนี้',
			'homeLayout.movieCollectionsSelection' => 'ชุดภาพยนตร์ (ปล่อยให้ทั้งหมดไม่ได้ตรวจสอบสําหรับแต่ละห้องสมุดที่เลือก)',
			'homeLayout.showCollectionsSelection' => 'แสดงคอลเลกชัน (ปล่อยให้ทั้งหมดไม่ได้ตรวจสอบสําหรับแต่ละห้องสมุดที่เลือก)',
			'homeLayout.collectionRowsDescription' => 'หากคอลเลกชันหนึ่งตรงกันข้ามชื่อของมันแสดงโดยตรงในแถว หากคอลเลกชันหนึ่งตรงกันข้ามแต่ละคอลเลกชันแสดงเป็นโพสต์เดียว - คลิกที่มันเพื่อเปิดคอลเลกชันนั้น',
			'homeLayout.allCollections' => 'การจัดเก็บทั้งหมด',
			'homeLayout.noRowsHere' => 'ไม่มีการติดตามที่นี่อีกต่อไป',
			'homeLayout.hideWatchedRows' => 'ซ่อนรายการที่มองเห็นในแถว',
			'homeLayout.hideWatchedRowsDescription' => 'หน้าแรกและห้องสมุดตามลําดับที่แนะนํา ในขั้นสูงอยู่',
			'homeLayout.untitledCollection' => 'การเก็บรวบรวม',
			'homeLayout.moveRowHint' => 'Up/Down: ขั้นตอน · เลือก: ลบที่นี่ · กลับ: ลบ',
			'homeLayout.organizeRowsHint' => 'เลือกในแถว (หรือถือ เลือก): ย้ายมัน · ด้านซ้าย/ขวา: ตัวเลือกแถว · กลับ: ทํา',
			'homeLayout.layoutNavDescription' => 'เลือกแถว, ห้องสมุดและประเภทการเก็บรวบรวม',
			'homeLayout.editHomeRow' => 'รอบบ้าน Edit',
			'homeLayout.resetHeroButton' => 'รีเซ็ตโครงสร้างฮีโร่ไปยังสต็อก Plezy',
			'homeLayout.reorderingUnlocked' => 'การจัดเรียงใหม่ Unlocked',
			'homeLayout.reorderingLocked' => 'ล็อคซับ',
			'homeLayout.rowsCanBeDragged' => 'รั้วสามารถดึง — ปิดล็อคเพื่อป้องกันไม่ให้',
			'homeLayout.tapLockToDrag' => 'คลิกที่ล็อคเพื่อดึงเส้น',
			'homeLayout.customRowLabel' => ({required Object title}) => 'คู่มือ: ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => 'ซ่อน',
			'homeLayout.remove' => 'นำออก',
			'homeLayout.libraryResumeRow' => 'ใบรับรองของห้องสมุดนี้',
			'homeLayout.pressAgainToDelete' => 'คลิกอีกครั้งเพื่อลบ',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => 'ใน',
			'homeLayout.resetHeroButtonDescription' => 'ปิดการตั้งค่าฮีโร่ของแต่ละแถวและนําแบรนด์หมุนเดียวกลับไปด้านบนเช่นเดียวกับก่อนที่แถวฮีโร่มีอยู่ แถวจะถูกเก็บไว้',
			'platform.localNetworkPermission' => 'PlezyNG เชื่อมต่อกับเซิร์ฟเวอร์สื่อและอุปกรณ์การเล่นบนเครือข่ายท้องถิ่นของคุณ',
			'platform.locationPermission' => 'PlezyNG ใช้การเข้าถึงตําแหน่งเมื่อ iOS ต้องการการตรวจจับเครือข่ายท้องถิ่นของคุณและเชื่อมต่อกับเซิร์ฟเวอร์สื่อของคุณ',
			'platform.photoLibraryPermission' => 'เลือกภาพจากห้องสมุดภาพของคุณเพื่อใช้เป็นงานศิลปะสื่อ',
			'platform.cameraPermission' => 'การสแกนรหัส QR เพื่อคู่กับ Companion Remote',
			'fileSources.title' => 'ไฟล์และหนังสือ',
			'fileSources.subtitle' => 'อ่านฟังและตรวจสอบจากไฟล์ของคุณเอง',
			'fileSources.add' => 'เพิ่มแหล่ง',
			'fileSources.importFiles' => 'ไฟล์นําเข้า',
			'fileSources.localFiles' => 'ในอุปกรณ์นี้',
			'fileSources.source' => 'หลักสูตร',
			'fileSources.name' => 'ชื่อ',
			'fileSources.endpoint' => 'URL ของเซิร์ฟเวอร์',
			'fileSources.root' => 'แผงหรือ Prefix',
			'fileSources.username' => 'ชื่อผู้ใช้',
			'fileSources.password' => 'คู่มือ',
			'fileSources.token' => 'API โค้น',
			'fileSources.accessKey' => 'การเข้าถึง ID Key',
			'fileSources.secretKey' => 'หลักการเข้าถึงที่ลับ',
			'fileSources.sessionToken' => 'โค้นเซสชั่น (ตัวเลือก)',
			'fileSources.region' => 'พื้นที่',
			'fileSources.clientId' => 'OAuth ID ลูกค้า',
			'fileSources.clientSecret' => 'OAuth คีย์ความลับ (เดสก์ท็อป Google เท่านั้น)',
			'fileSources.allowHttp' => 'อนุญาต HTTP ที่ไม่เข้ารหัสบนเครือข่ายที่เชื่อถือได้',
			'fileSources.connect' => 'เชื่อมต่อ',
			'fileSources.cancel' => 'ยกเลิก',
			'fileSources.save' => 'บันทึก',
			'fileSources.close' => 'ปิด',
			'fileSources.removeSource' => 'ไฟฉาย',
			'fileSources.disconnectMessage' => 'ตัดการเชื่อมต่อแหล่งข้อมูลนี้หรือไม่? ไฟล์ที่ดาวน์โหลดและประวัติการอ่านและการฟังจะยังคงอยู่บนอุปกรณ์นี้',
			'fileSources.localFolder' => 'เลือกโฟลเดอร์',
			'fileSources.empty' => 'ไม่มีอะไรที่นี่',
			'fileSources.emptyHint' => 'เพิ่มแหล่งหรือนําเข้าหนังสือ audiobook, เพลงหรือวิดีโอ',
			'fileSources.search' => 'ค้นหาโฟลเดอร์นี้',
			'fileSources.searchCached' => 'ค้นหาห้องสมุดบันทึก',
			'fileSources.refresh' => 'การทําความเย็น',
			'fileSources.loadMore' => 'บรรจุเพิ่มเติม',
			'fileSources.offline' => 'มีอยู่ offline',
			'fileSources.download' => 'ปิดออก',
			'fileSources.removeDownload' => 'ลบออฟไลน์ คูปอง',
			'fileSources.continueReading' => 'อ่านต่อ',
			'fileSources.continueListening' => 'อ่านต่อ',
			'fileSources.continueWatching' => 'ดูต่อ',
			'fileSources.read' => 'อ่าน',
			'fileSources.listen' => 'ดูข้อความ',
			'fileSources.play' => 'เล่น',
			'fileSources.pause' => 'หยุดชั่วคราว',
			'fileSources.stop' => 'หยุด',
			'fileSources.startOver' => 'เริ่มต้น',
			'fileSources.finished' => 'เสร็จสิ้น',
			'fileSources.markFinished' => 'หมายเลขรุ่น: Mark finished',
			'fileSources.markUnfinished' => 'หมายเลขที่สิ้นสุด',
			'fileSources.editions' => 'การพิมพ์และไฟล์',
			'fileSources.chapters' => 'ประเภท',
			'fileSources.bookmarks' => 'บัญชีและบันทึก',
			'fileSources.bookmark' => 'เพิ่ม Bookmark',
			'fileSources.highlight' => 'แสดง',
			'fileSources.note' => 'บันทึก',
			'fileSources.delete' => 'ลบ',
			'fileSources.export' => 'การส่งออก',
			'fileSources.exported' => 'หมายเลขที่ส่งออก',
			'fileSources.sync' => 'การพัฒนา Sync',
			'fileSources.synced' => 'การพัฒนาแบบซิงค์',
			'fileSources.conflict' => 'อุปกรณ์อื่นมีตําแหน่งที่แตกต่างกัน เลือกที่ที่จะดําเนินการ',
			'fileSources.useLocal' => 'ใช้อุปกรณ์นี้',
			'fileSources.useRemote' => 'ใช้อุปกรณ์อื่น ๆ',
			'fileSources.history' => 'ประวัติตําแหน่ง',
			'fileSources.groupAudio' => 'ดูเหมือนหนังสือเสียง',
			'fileSources.groupHint' => 'รวมไฟล์เสียงที่โหลดในโฟลเดอร์นี้ คลิกที่หน้าทั้งหมดก่อน',
			'fileSources.order' => 'กรณีคําสั่ง',
			'fileSources.moveUp' => 'ขึ้นไป',
			'fileSources.moveDown' => 'การเคลื่อนไหวลง',
			'fileSources.speed' => 'ความเร็ว Playback',
			'fileSources.sleep' => 'เวลานอนหลับ',
			'fileSources.sleepOff' => 'ปิด',
			'fileSources.endChapter' => 'ประเภทสุดท้าย',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('th'))(count, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} นาที', ), 
			'fileSources.skipBack' => 'สกินกลับ',
			'fileSources.skipForward' => 'ขั้นตอน',
			'fileSources.smartRewind' => 'สื่อลามกหลังจากการหยุด',
			'fileSources.playbackOptions' => 'การฟังตัวเลือก',
			'fileSources.remaining' => ({required Object time}) => '${time} ออกจากนี้',
			'fileSources.contents' => 'วัสดุ',
			'fileSources.readerSettings' => 'การตั้งค่าการอ่าน',
			'fileSources.fontSize' => 'ขนาดตัวอักษร',
			'fileSources.lineHeight' => 'สายการสเปน',
			'fileSources.margin' => 'มาร์เจน',
			'fileSources.font' => 'ประเภท',
			'fileSources.serif' => 'เซ็กส์',
			'fileSources.sans' => 'ไม่ใช่เซริฟ',
			'fileSources.mono' => 'โมโนสเปน',
			'fileSources.columns' => 'คอลัมน์',
			'fileSources.scroll' => 'การสกรูแนวตั้ง',
			'fileSources.justify' => 'หมายเลข',
			'fileSources.readerTheme' => 'หน้าปรากฏ',
			'fileSources.appTheme' => 'ติดตาม app theme',
			'fileSources.paper' => 'กระดาษ',
			'fileSources.sepia' => 'ซิปต์',
			'fileSources.night' => 'นอน',
			'fileSources.readAloud' => 'อ่านหน้านี้ด้วยเสียง',
			'fileSources.readAlong' => 'อ่านต่อไป',
			'fileSources.stopReading' => 'ปิดการพูด',
			'fileSources.searchBook' => 'ค้นหาในหนังสือ',
			'fileSources.noMatches' => 'ไม่มีเกม',
			'fileSources.previousPage' => 'หน้าแรก',
			'fileSources.nextPage' => 'หน้าต่อไป',
			'fileSources.page' => ({required Object number}) => 'หน้า ${number}',
			'fileSources.externalBlocked' => 'ลิงค์หนังสือภายนอกจะถูกปิดใช้งานในผู้อ่าน',
			'fileSources.loading' => 'เปิด...',
			'fileSources.narrator' => 'สื่อลามก',
			'fileSources.audio' => 'เสียง',
			'fileSources.video' => 'วิดีโอ',
			'fileSources.ebooks' => 'อีบุ๊ก',
			'fileSources.all' => 'ทั้งหมด',
			'fileSources.downloads' => 'ไฟล์ Offline',
			'fileSources.confirmDelete' => 'ลบสำเนาออฟไลน์ที่เลือกหรือไม่? ตำแหน่งการอ่านหรือการฟังและบันทึกของคุณจะยังคงอยู่',
			'fileSources.errorAuthentication' => 'ลงชื่อเข้าสู่ระบบอีกครั้งเพื่อเชื่อมต่อแหล่งนี้อีกครั้ง',
			'fileSources.errorPermission' => 'แหล่งนี้ไม่ให้การเข้าถึงไฟล์ที่ขอ',
			'fileSources.errorUnavailable' => 'แหล่งที่มาไม่สามารถใช้ได้ ลองอีกครั้งหรือเปิดสําเนาแบบออฟไลน์',
			'fileSources.errorUnsupported' => 'รูปแบบหรือการเชื่อมต่อนี้ไม่ได้รับการสนับสนุนบนอุปกรณ์นี้ ดูคู่มือการตั้งค่าแหล่งข้อมูล',
			'fileSources.errorInvalidData' => 'ไฟล์หรือคําตอบเซิร์ฟเวอร์นี้ไม่สามารถอ่านได้ได้อย่างปลอดภัย',
			'fileSources.errorCancelled' => 'การดําเนินการถูกยกเลิก',
			'fileSources.errorConflict' => 'ตําแหน่งได้เปลี่ยนในเซสชั่นอื่น เปิดรายการอีกครั้งเพื่อเลือกตําแหน่ง',
			'fileSources.signIn' => 'เข้าสู่ระบบ',
			'fileSources.reconnect' => 'การเชื่อมต่อ',
			'fileSources.folderHelp' => 'ปล่อยให้เปิดเพื่อเริ่มต้นจากรากแหล่งที่มา URL S3 รวมถึงกล่อง',
			'fileSources.preferences' => 'ความต้องการ',
			'fileSources.timePosition' => 'ตําแหน่ง',
			'fileSources.audioTrack' => 'ออนไลน์',
			'fileSources.subtitleTrack' => 'Subtitle เทร็ก',
			'fileSources.none' => 'ไม่มี',
			'fileSources.fullscreen' => 'หน้าจอเต็มรูปแบบ',
			'fileSources.syncLocation' => 'โฟลเดอร์ Sync Progress (ตัวเลือก)',
			'fileSources.syncLocationHint' => 'โพสต์ WebDAV ที่กําหนดเองสําหรับ PlezyNG state ใช้การเขียนที่กําหนดเอง; โมเดียมยังคงไม่เปลี่ยนแปลง',
			'fileSources.audiobooks' => 'ออดิโอ',
			'fileSources.comics' => 'คอมเมติก',
			'fileSources.scan' => 'สแกนสําหรับหนังสือและสื่อ',
			'fileSources.browserReader' => 'เปิดตัว',
			'fileSources.browserReaderHelp' => 'อ่านเปิดในเบราว์เซอร์ของคุณ ปล่อยให้ PlezyNG เปิดเพื่อบันทึกสถานที่และบันทึกของคุณ',
			'fileSources.on' => 'ใน',
			'fileSources.advancedSetup' => 'การลงทะเบียนแอป',
			'fileSources.microsoftSignIn' => 'ลงชื่อเข้าสู่ระบบกับ Microsoft',
			'fileSources.zoomIn' => 'สื่อใน',
			'fileSources.zoomOut' => 'สวยไป',
			'fileSources.fitPage' => 'หน้าที่เหมาะสม',
			'fileSources.fitWidth' => 'ความกว้างที่เหมาะสม',
			'fileSources.actualSize' => 'ขนาดปัจจุบัน',
			'fileSources.goToPage' => 'ไปที่หน้า',
			'fileSources.goToSection' => 'ไปยังบทความ',
			'fileSources.pageRange' => ({required Object count}) => 'หมายเลข 1 ไปยัง ${count}',
			'fileSources.pageLayout' => 'โลกหน้า',
			'fileSources.automatic' => 'อัตโนมัติ',
			'fileSources.singlePage' => 'หน้าเดียว',
			'fileSources.twoPages' => '2 หน้า',
			'fileSources.readingDirection' => 'การอ่านทิศทาง',
			'fileSources.leftToRight' => 'ป้ายไปขวา',
			'fileSources.rightToLeft' => 'หมายเลขรุ่น: Right to Lease',
			'fileSources.letterSpacing' => 'สเปคจดหมาย',
			'fileSources.wordSpacing' => 'คําอธิบาย',
			'fileSources.readerControlsHelp' => 'ปิดหรือใช้ควบคุมการจูงเพื่อขยายหน้า แดร์ไปยังหน้า Ctrl/ ⁇  + หรือ − ปรับจูง Ctrl/ ⁇  0 จะรีเซ็ตหน้า Page Up และ Page Down จะเปิดหน้า',
			'fileSources.imagePage' => 'หน้าการ์ตูน',
			'fileSources.resetReader' => 'การตั้งค่าการอ่านใหม่',
			'fileSources.zoom' => 'โซม',
			'fileSources.useFiles' => 'ใช้ไฟล์และหนังสือ',
			'fileSources.cancelScan' => 'สแกนลบ',
			'fileSources.googleDrive' => 'Google Drive',
			'lending.title' => 'สวนสาธารณะ',
			'lending.add' => 'เพิ่มห้องสมุด',
			'lending.other' => 'อื่น ๆ บิสตจักร',
			'lending.libraryName' => 'ชื่อห้องสมุด',
			'lending.libraryUrl' => 'เว็บไซต์ของห้องสมุด',
			'lending.libraryUrlHint' => 'ใช้คอลเลกชันของห้องสมุดหรือหน้าลงทะเบียน',
			'lending.intro' => 'จองจากห้องสมุดของคุณ ปกป้องหนังสือของคุณ',
			'lending.handoff' => 'ลงทะเบียนให้เช่าและอ่านได้อย่างปลอดภัยด้วยบริการของห้องสมุดของคุณเอง',
			'lending.openService' => 'ห้องสมุดเปิด',
			'lending.findLibrary' => 'ค้นหาห้องสมุด',
			'lending.search' => 'ค้นหาหนังสือและผู้เขียน',
			'lending.catalogue' => 'คาตาล็อก',
			'lending.loans' => 'โอนเงิน',
			'lending.holds' => '⁇',
			'lending.signIn' => 'ลงทะเบียนกับห้องสมุดของคุณ',
			'lending.waiting' => 'เสร็จสิ้นการลงทะเบียนในเบราว์เซอร์ของคุณแล้วกลับที่นี่',
			'lending.cancel' => 'ยกเลิก',
			'lending.disconnect' => 'ลบห้องสมุด',
			'lending.disconnectMessage' => 'ลบห้องสมุดนี้จากโปรไฟล์นี้? ใบรับรองของคุณและเก็บพักกับห้องสมุดของคุณ',
			'lending.getBook' => 'รับหนังสือ',
			'lending.checkAvailability' => 'ตรวจสอบความพร้อม',
			'lending.available' => 'มีให้เลือกที่จะให้เช่า',
			'lending.unavailable' => 'ไม่สามารถใช้ได้ในขณะนี้',
			'lending.borrow' => 'โอกาส',
			'lending.placeHold' => 'สถานที่เก็บ',
			'lending.returnBook' => 'กลับมาก่อน',
			'lending.cancelHold' => 'ปล่อยการเก็บรักษา',
			'lending.confirmBorrow' => 'รับใบรับรองจากห้องสมุดของคุณหรือไม่',
			'lending.confirmReturn' => 'รับเงินคืนนี้ตอนนี้? คุณอาจต้องรับเงินคืนเพื่อให้ดําเนินการต่อไป',
			'lending.confirmCancelHold' => 'ลบการเก็บรักษาของคุณในชื่อนี้หรือไม่',
			'lending.email' => 'หมายเลขอีเมล',
			'lending.due' => ({required Object date}) => 'หมายเลขรุ่น: ${date}',
			'lending.queue' => ({required Object position}) => 'ตําแหน่ง ${position} ในเส้น',
			'lending.empty' => 'ไม่มีชื่อที่นี่',
			'lending.openLibraryNote' => 'ค้นหาคอลเลกชันของ Open Library ตัวเลือกการอ่านและรับเงินจะแสดงในหน้าของแต่ละหัวข้อ',
			'lending.more' => 'บรรจุเพิ่มเติม',
			'lending.gateway' => 'บริการลงทะเบียนห้องสมุด',
			'lending.gatewayHint' => 'ให้โดยห้องสมุดของคุณหรือผู้ดูแลระบบ PlezyNG',
			'lending.advanced' => 'การรวมห้องสมุด',
			'lending.loadLibraries' => 'เลือกห้องสมุดของคุณ',
			'lending.expired' => 'โอนนี้หมดอายุ',
			'lending.updated' => 'บีบอิสระปรับปรุง',
			'lending.continueService' => 'ทํางานต่อไป',
			'lending.comingSoon' => 'การรับประกันในแอป · มาเร็ว ๆ นี้',
			'lending.comingSoonDescription' => 'การรวมของ Libby จะอยู่บนทางของคุณ คุณสามารถใช้ห้องสมุดของคุณใน Libby ในขณะที่เราจะเสร็จสิ้นการเชื่อมต่อ',
			'lending.suspendHold' => 'ปิดการเก็บรักษา',
			'lending.resumeHold' => 'ใบเสนอราคา',
			'lending.suspendMessage' => 'ปล่อยตําแหน่งของคุณในเส้นและปล่อยให้ผู้อ่านต่อไปให้คูปองนี้? คุณสามารถรับคืนการเก็บไว้ในภายหลัง',
			'lending.resumeMessage' => 'ใหม่นี้เก็บไว้เพื่อให้ห้องสมุดของคุณสามารถเสนอสําเนาต่อไปที่พร้อมใช้งานได้หรือไม่',
			'lending.editEmail' => 'การเปลี่ยนแปลงอีเมลการแจ้งเตือน',
			_ => null,
		};
	}
}
