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
class TranslationsVi extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsVi({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.vi,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <vi>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsVi _root = this; // ignore: unused_field

	@override 
	TranslationsVi $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsVi(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$vi app = _Translations$app$vi._(_root);
	@override late final _Translations$appIcon$vi appIcon = _Translations$appIcon$vi._(_root);
	@override late final _Translations$auth$vi auth = _Translations$auth$vi._(_root);
	@override late final _Translations$common$vi common = _Translations$common$vi._(_root);
	@override late final _Translations$screens$vi screens = _Translations$screens$vi._(_root);
	@override late final _Translations$update$vi update = _Translations$update$vi._(_root);
	@override late final _Translations$settings$vi settings = _Translations$settings$vi._(_root);
	@override late final _Translations$themeEditor$vi themeEditor = _Translations$themeEditor$vi._(_root);
	@override late final _Translations$search$vi search = _Translations$search$vi._(_root);
	@override late final _Translations$hotkeys$vi hotkeys = _Translations$hotkeys$vi._(_root);
	@override late final _Translations$fileInfo$vi fileInfo = _Translations$fileInfo$vi._(_root);
	@override late final _Translations$mediaMenu$vi mediaMenu = _Translations$mediaMenu$vi._(_root);
	@override late final _Translations$rateSheet$vi rateSheet = _Translations$rateSheet$vi._(_root);
	@override late final _Translations$accessibility$vi accessibility = _Translations$accessibility$vi._(_root);
	@override late final _Translations$tooltips$vi tooltips = _Translations$tooltips$vi._(_root);
	@override late final _Translations$audioTracks$vi audioTracks = _Translations$audioTracks$vi._(_root);
	@override late final _Translations$videoControls$vi videoControls = _Translations$videoControls$vi._(_root);
	@override late final _Translations$messages$vi messages = _Translations$messages$vi._(_root);
	@override late final _Translations$subtitlingStyling$vi subtitlingStyling = _Translations$subtitlingStyling$vi._(_root);
	@override late final _Translations$mpvConfig$vi mpvConfig = _Translations$mpvConfig$vi._(_root);
	@override late final _Translations$dialog$vi dialog = _Translations$dialog$vi._(_root);
	@override late final _Translations$profiles$vi profiles = _Translations$profiles$vi._(_root);
	@override late final _Translations$connections$vi connections = _Translations$connections$vi._(_root);
	@override late final _Translations$accountPreferences$vi accountPreferences = _Translations$accountPreferences$vi._(_root);
	@override late final _Translations$discover$vi discover = _Translations$discover$vi._(_root);
	@override late final _Translations$errors$vi errors = _Translations$errors$vi._(_root);
	@override late final _Translations$libraries$vi libraries = _Translations$libraries$vi._(_root);
	@override late final _Translations$about$vi about = _Translations$about$vi._(_root);
	@override late final _Translations$serverSelection$vi serverSelection = _Translations$serverSelection$vi._(_root);
	@override late final _Translations$hubDetail$vi hubDetail = _Translations$hubDetail$vi._(_root);
	@override late final _Translations$logs$vi logs = _Translations$logs$vi._(_root);
	@override late final _Translations$startup$vi startup = _Translations$startup$vi._(_root);
	@override late final _Translations$licenses$vi licenses = _Translations$licenses$vi._(_root);
	@override late final _Translations$navigation$vi navigation = _Translations$navigation$vi._(_root);
	@override late final _Translations$explore$vi explore = _Translations$explore$vi._(_root);
	@override late final _Translations$liveTv$vi liveTv = _Translations$liveTv$vi._(_root);
	@override late final _Translations$collections$vi collections = _Translations$collections$vi._(_root);
	@override late final _Translations$playlists$vi playlists = _Translations$playlists$vi._(_root);
	@override late final _Translations$music$vi music = _Translations$music$vi._(_root);
	@override late final _Translations$watchTogether$vi watchTogether = _Translations$watchTogether$vi._(_root);
	@override late final _Translations$downloads$vi downloads = _Translations$downloads$vi._(_root);
	@override late final _Translations$shaders$vi shaders = _Translations$shaders$vi._(_root);
	@override late final _Translations$companionRemote$vi companionRemote = _Translations$companionRemote$vi._(_root);
	@override late final _Translations$videoSettings$vi videoSettings = _Translations$videoSettings$vi._(_root);
	@override late final _Translations$performanceOverlay$vi performanceOverlay = _Translations$performanceOverlay$vi._(_root);
	@override late final _Translations$externalPlayer$vi externalPlayer = _Translations$externalPlayer$vi._(_root);
	@override late final _Translations$metadataEdit$vi metadataEdit = _Translations$metadataEdit$vi._(_root);
	@override late final _Translations$matchScreen$vi matchScreen = _Translations$matchScreen$vi._(_root);
	@override late final _Translations$serverTasks$vi serverTasks = _Translations$serverTasks$vi._(_root);
	@override late final _Translations$trakt$vi trakt = _Translations$trakt$vi._(_root);
	@override late final _Translations$seerr$vi seerr = _Translations$seerr$vi._(_root);
	@override late final _Translations$services$vi services = _Translations$services$vi._(_root);
	@override late final _Translations$addServer$vi addServer = _Translations$addServer$vi._(_root);
	@override late final _Translations$cast$vi cast = _Translations$cast$vi._(_root);
	@override late final _Translations$automation$vi automation = _Translations$automation$vi._(_root);
	@override late final _Translations$notifications$vi notifications = _Translations$notifications$vi._(_root);
	@override late final _Translations$appAccess$vi appAccess = _Translations$appAccess$vi._(_root);
	@override late final _Translations$detail$vi detail = _Translations$detail$vi._(_root);
	@override late final _Translations$watchLink$vi watchLink = _Translations$watchLink$vi._(_root);
	@override late final _Translations$homeLayout$vi homeLayout = _Translations$homeLayout$vi._(_root);
	@override late final _Translations$platform$vi platform = _Translations$platform$vi._(_root);
	@override late final _Translations$universalMedia$vi universalMedia = _Translations$universalMedia$vi._(_root);
	@override late final _Translations$fileSources$vi fileSources = _Translations$fileSources$vi._(_root);
	@override late final _Translations$lending$vi lending = _Translations$lending$vi._(_root);
	@override late final _Translations$audiobook$vi audiobook = _Translations$audiobook$vi._(_root);
	@override late final _Translations$sourceSetup$vi sourceSetup = _Translations$sourceSetup$vi._(_root);
	@override late final _Translations$comics$vi comics = _Translations$comics$vi._(_root);
	@override late final _Translations$games$vi games = _Translations$games$vi._(_root);
	@override late final _Translations$deepLinks$vi deepLinks = _Translations$deepLinks$vi._(_root);
	@override late final _Translations$householdSetup$vi householdSetup = _Translations$householdSetup$vi._(_root);
	@override late final _Translations$issueReport$vi issueReport = _Translations$issueReport$vi._(_root);
}

// Path: app
class _Translations$app$vi extends Translations$app$en {
	_Translations$app$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: appIcon
class _Translations$appIcon$vi extends Translations$appIcon$en {
	_Translations$appIcon$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'ứng dụng icon';
	@override String get defaultIcon => 'Mặc Định';
	@override String get current => 'Icon hiện tại';
	@override String get locked => 'Thời gian tiếp cận cần thiết';
	@override String get lockedHint => 'Bắt đầu thử nghiệm 7 ngày của bạn hoặc mở khóa PlezyNG cho đời để sử dụng các biểu tượng thay thế.';
	@override String get changeFailed => 'Không thể thay đổi icon ứng dụng';
	@override String get launcherHint => 'biểu tượng mới sẽ xuất hiện trên màn hình nhà của bạn một khi bạn rời khỏi PlezyNG.';
	@override String get tvLauncherHint => 'Banner mới xuất hiện một khi bạn rời khỏi PlezyNG. Android TV có thể tiếp tục hiển thị một cũ cho đến khi TV khởi động lại.';
	@override late final _Translations$appIcon$names$vi names = _Translations$appIcon$names$vi._(_root);
	@override String get description => 'Chọn biểu tượng được hiển thị bởi người khởi động thiết bị của bạn. các bản xem trước cho thấy mỗi tùy chọn trông như thế nào.';
}

// Path: auth
class _Translations$auth$vi extends Translations$auth$en {
	_Translations$auth$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Đăng ký với Plex';
	@override String get showQRCode => 'Hiển thị QR Code';
	@override String get authenticate => 'xác thực';
	@override String get authenticationTimeout => 'Chứng nhận đã hết hạn, xin vui lòng thử lại.';
	@override String get scanQRToSignIn => 'Scan mã QR này để đăng ký';
	@override String get waitingForAuth => 'Đang chờ xác thực... Đăng nhập từ trình duyệt của bạn.';
	@override String get useBrowser => 'Sử dụng browser';
	@override String get or => 'hoặc';
	@override String connectToMediaBrowser({required Object product}) => 'Kết nối với ${product}';
	@override String get quickConnect => 'Kết Nối Nhanh';
	@override String get useQuickConnect => 'Dùng kết nối nhanh';
	@override String get quickConnectInstructions => 'Mở Quick Connect trong Jellyfin và nhập mã này.';
	@override String get quickConnectWaiting => 'Đang chờ sự chấp thuận...';
	@override String get quickConnectCancel => 'Hủy bỏ';
	@override String get quickConnectExpired => 'Quick Connect đã hết hạn. thử lại.';
	@override String get localDataRecoveryRequired => 'PlezyNG không thể khôi phục an toàn dữ liệu đăng nhập cục bộ và dữ liệu phát đang chờ xử lý. Vui lòng đăng nhập lại.';
	@override String get pinCheckRejected => 'Kiểm tra PIN Plex đã bị từ chối';
	@override String get connectToDirectPlex => 'Kết nối với máy chủ địa phương Plex';
}

// Path: common
class _Translations$common$vi extends Translations$common$en {
	_Translations$common$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Hủy bỏ';
	@override String get save => 'Lưu';
	@override String get close => 'Đóng';
	@override String get closeMiniPlayer => 'Trò chơi mini gần';
	@override String get closeWorkspaceWindow => 'cửa sổ gần';
	@override String get returnToFullView => 'Trở về View Full';
	@override String get manageMediaSessions => 'Quản lý các phiên truyền thông';
	@override String get hideMediaSessions => 'Giữ các buổi truyền thông';
	@override String get mediaSessions => 'Các buổi truyền thông';
	@override String get mediaSessionsHint => 'Chọn để đưa một phiên về phía trước. Park che giấu cửa sổ của nó nhưng giữ cho nó mở. Return mở nó trong toàn diện; gần kết thúc nó.';
	@override String get sessionInWorkspace => 'trong Workspace';
	@override String get sessionParked => 'đậu xe';
	@override String get sessionFullscreen => 'màn hình đầy đủ';
	@override String get switchToNextWindow => 'Chuyển đổi với cửa sổ tiếp theo';
	@override String get moveWindow => 'di chuyển cửa sổ';
	@override String get finishMovingWindow => 'Kết thúc cửa sổ di chuyển';
	@override String get moveWindowHint => 'Nhấn dài và kéo cửa sổ để di chuyển nó. điều khiển này cũng cho phép phong trào mũi tên-chìa khóa.';
	@override String get movingWindowHelp => 'Tắt để di chuyển · Cài đặt chìa khóa · Enter Saves · Escape Cancel';
	@override String get resizeWindow => 'Tải lại cửa sổ';
	@override String get resizeWindowHint => 'Tắt bàn tay này hoặc sử dụng chìa khóa mũi tên để khôi phục lại cửa sổ.';
	@override String get workspaceWindowHint => 'Sử dụng điều khiển chuyển động hoặc kéo dài và kéo để di chuyển.';
	@override String get workspacePaneHint => 'Chọn bảng điều khiển này để tập trung vào nó. Sử dụng kiểm soát màn hình đầy đủ của nó để mở rộng.';
	@override String workspaceWindowLabel({required Object title}) => 'Màn hình: ${title}';
	@override String get workspaceTitleHint => 'Chọn để tập trung. kéo thanh tiêu đề để di chuyển; sử dụng nút màn hình đầy đủ để mở rộng.';
	@override String get moveToSessionTray => 'Chuyển sang session tray';
	@override String get moveToSessionTrayHint => 'Khóa phiên này có sẵn mà không hiển thị cửa sổ của nó.';
	@override String get closeSessionHint => 'Bắt cửa sổ này và kết thúc phiên.';
	@override String get sideBySideLayout => 'Chuyển đổi sang side-by-side layout';
	@override String get floatingWindows => 'Chuyển đổi để floating windows';
	@override String get clear => 'rõ ràng';
	@override String get reset => 'Đặt lại';
	@override String get later => 'Sau đó';
	@override String get submit => 'Gửi đi';
	@override String get confirm => 'xác nhận';
	@override String get retry => 'Thử lại';
	@override String get logout => 'Đăng nhập';
	@override String get unknown => 'Không rõ';
	@override String get refresh => 'Làm mới';
	@override String get yes => 'Đúng';
	@override String get no => 'Không';
	@override String get delete => 'Xóa';
	@override String get edit => 'Sửa';
	@override String get shuffle => 'Phát ngẫu nhiên';
	@override String get addTo => 'Thêm vào...';
	@override String get createNew => 'Tạo mới';
	@override String get connect => 'Kết nối';
	@override String get disconnect => 'Ngắt kết nối';
	@override String get play => 'Phát';
	@override String get pause => 'Tạm dừng';
	@override String get resume => 'Tiếp tục phát';
	@override String get error => 'Lỗi';
	@override String get search => 'Tìm kiếm';
	@override String get home => 'Trang chủ';
	@override String get back => 'Quay lại';
	@override String get settings => 'Cài đặt';
	@override String get mute => 'Tắt Tiếng';
	@override String get ok => 'Đồng Ý';
	@override String get off => 'Tắt';
	@override String get options => 'Lựa chọn';
	@override String seasonNumber({required Object number}) => 'Mùa ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'Chương ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'Chương ${number}';
	@override String get reconnect => 'nối lại';
	@override String get viewAll => 'Xem tất cả';
	@override String get checkingNetwork => 'Kiểm tra mạng...';
	@override String get loadingServers => 'Các máy chủ tải...';
	@override String get connectingToServers => 'Kết nối với máy chủ...';
	@override String get startingOfflineMode => 'Bắt đầu offline...';
	@override String get loading => 'tải...';
	@override String get fullscreen => 'Toàn màn hình';
	@override String get exitFullscreen => 'Khởi hành Fullscreen';
	@override String get pressBackAgainToExit => 'Nhấn trở lại để ra ngoài';
	@override late final _Translations$common$ratingSource$vi ratingSource = _Translations$common$ratingSource$vi._(_root);
	@override String get notAvailable => 'N / A';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
	@override late final _Translations$common$mediaKind$vi mediaKind = _Translations$common$mediaKind$vi._(_root);
}

// Path: screens
class _Translations$screens$vi extends Translations$screens$en {
	_Translations$screens$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Giấy phép';
	@override String get switchProfile => 'Tính năng Switch Profile';
	@override String get subtitleStyling => 'Kiểu phụ đề';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Nhật ký';
}

// Path: update
class _Translations$update$vi extends Translations$update$en {
	_Translations$update$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get available => 'Update có sẵn';
	@override String versionAvailable({required Object version}) => 'Phiên bản ${version} có sẵn';
	@override String currentVersion({required Object version}) => 'Hiện tại: ${version}';
	@override String get skipVersion => 'Tải phiên bản này';
	@override String get viewRelease => 'Xem bản phát hành';
	@override String get latestVersion => 'Bạn đang ở phiên bản mới nhất';
	@override String get checkFailed => 'Không kiểm tra cho các bản cập nhật';
}

// Path: settings
class _Translations$settings$vi extends Translations$settings$en {
	_Translations$settings$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Cài đặt';
	@override String get supportDeveloper => 'Hỗ trợ PlezyNG';
	@override String get supportDeveloperDescription => 'Ưu đãi để hỗ trợ phát triển';
	@override String get lifetimeAccess => 'PlezyNG Thời gian truy cập';
	@override String get language => 'Ngôn ngữ';
	@override String get theme => 'Chủ đề';
	@override String get appearance => 'xuất hiện';
	@override String get detailPage => 'Trang chi tiết';
	@override String get themeSongsEnabled => 'Chơi bài hát Theme';
	@override String get themeSongsEnabledDescription => 'Chơi các bài hát chủ đề có sẵn trong khi xem các chi tiết truyền thông.';
	@override String get themeSongVolume => 'Lời bài hát Volume';
	@override String get videoPlayback => 'Phát video';
	@override String get videoPlaybackDescription => 'Thiết lập hành vi playback';
	@override String get advanced => 'Nâng cao';
	@override String get episodePosterMode => 'Phong cách poster';
	@override String get seriesPoster => 'Series bài poster';
	@override String get seasonPoster => 'Poster mùa';
	@override String get episodeThumbnail => 'Ảnh thu nhỏ';
	@override String get showHeroSectionDescription => 'Hiển thị nội dung carousel trên màn hình nhà';
	@override String get secondsLabel => 'giây';
	@override String get minutesLabel => 'phút';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Nhập giá trị (${min}-${max})';
	@override String get systemTheme => 'Hệ thống';
	@override String get lightTheme => 'Ánh sáng';
	@override String get darkTheme => 'bóng tối';
	@override String get oledTheme => 'OLED';
	@override String get emberTheme => 'người';
	@override String get glacierTheme => 'Băng';
	@override String get forestTheme => 'rừng';
	@override String get plumTheme => 'Tím mận';
	@override String get paperTheme => 'giấy';
	@override String get libraryDensity => 'Dung lượng thư viện';
	@override String get displayScale => 'Màn hình Scale';
	@override String get compact => 'Gọn';
	@override String get comfortable => 'thoải mái';
	@override String get gridSpacing => 'Mạng lưới Spacing';
	@override String get gridSpacingTight => 'Sát';
	@override String get gridSpacingNormal => 'Bình thường';
	@override String get gridSpacingSpacious => 'không gian';
	@override String get tvCornerSpotlightBackdrop => 'Phân tích Spotlight Backdrop';
	@override String get tvCornerSpotlightBackdropDescription => 'Hiển thị tác phẩm nghệ thuật trong góc trên bên phải thay vì lấp đầy màn hình';
	@override String get viewMode => 'View Thời gian';
	@override String get gridView => 'Mạng';
	@override String get listView => 'Danh sách';
	@override String get showHeroSection => 'Show Hero Phần';
	@override String get showHomeBackdrop => 'Show home backdrop tác phẩm nghệ thuật';
	@override String get showHomeBackdropDescription => 'Hiển thị tác phẩm nghệ thuật vĩ đại đằng sau dòng Home';
	@override String get contentScreensaverEnabled => 'Nội dung Screensaver';
	@override String get contentScreensaverEnabledDescription => 'Hiển thị tác phẩm nghệ thuật màn hình đầy đủ sau khi ứng dụng đã trở thành idle';
	@override String get contentScreensaverDelay => 'Bắt đầu màn hình sau';
	@override String get contentScreensaverLibraries => 'Thư viện Screensaver';
	@override String get contentScreensaverLibrariesDescription => 'Chọn thư viện nào cung cấp màn hình bảo vệ công việc nghệ thuật. Nếu không có, công việc nghệ thuật từ tất cả thư viện được sử dụng.';
	@override String get contentScreensaverAllLibraries => 'Tất cả thư viện';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} thư viện được chọn';
	@override String get contentScreensaverNoLibraries => 'Không có thư viện truyền thông kết nối.';
	@override String get contentScreensaverDismissHint => 'Nhấn bất kỳ nút hoặc nhấn để tháo';
	@override String get newEpisodeNotifications => 'Thông báo episode mới';
	@override String get newEpisodeNotificationsDescription => 'Cảnh báo khi một tập mới được thêm vào một chương trình bạn đang bị bắt. kiểm tra khi Plezy mở.';
	@override String get continueWatchingRowSize => 'Xem thêm kích thước hàng';
	@override String continueWatchingRowSizeValue({required Object label}) => '${label} thẻ';
	@override String get rowSizeCompact => 'Gọn';
	@override String get rowSizeStandard => 'Tiêu chuẩn';
	@override String get rowSizeLarge => 'Lớn';
	@override String get continueWatchingAction => 'Tiếp tục theo dõi hành động';
	@override String get continueWatchingPlay => 'Phát';
	@override String get continueWatchingDetails => 'chi tiết mở';
	@override String get episodeAction => 'Episode hành động';
	@override String get episodePlay => 'Phát';
	@override String get episodeDetails => 'chi tiết mở';
	@override String get useGlobalHubs => 'Sử dụng Home Layout';
	@override String get useGlobalHubsDescription => 'Hiển thị các hub nhà thống nhất. nếu không sử dụng các khuyến nghị thư viện.';
	@override String get showServerNameOnHubs => 'Hiển thị tên máy chủ trên Hubs';
	@override String get showServerNameOnHubsDescription => 'Luôn hiển thị tên máy chủ trong các tiêu đề hub.';
	@override String get groupLibrariesByServer => 'Thư viện Nhóm bởi Server';
	@override String get groupLibrariesByServerDescription => 'Thư viện nhóm bên dưới mỗi máy chủ truyền thông.';
	@override String get alwaysKeepSidebarOpen => 'Luôn luôn giữ cửa sổ mở';
	@override String get alwaysKeepSidebarOpenDescription => 'Sidebar vẫn mở rộng và khu vực nội dung được điều chỉnh để phù hợp';
	@override String get showUnwatchedCount => 'Show Unwatched Số lượng';
	@override String get showUnwatchedCountDescription => 'Hiển thị không được xem tập số trên các chương trình và mùa';
	@override String get showWatchedIndicators => 'Hiển thị các chỉ số được xem';
	@override String get showWatchedIndicatorsDescription => 'Hiển thị dấu kiểm trên các bộ phim, chương trình và các tập phim đã được xem';
	@override String get showEpisodeNumberOnCards => 'Show Episode Number on Cards (Điểm số trên bản đồ)';
	@override String get showEpisodeNumberOnCardsDescription => 'Hiển thị mùa và số episode trên thẻ episode';
	@override String get showSeasonPostersOnTabs => 'Hiển thị poster mùa trên tabs';
	@override String get showSeasonPostersOnTabsDescription => 'Hiển thị poster của mỗi mùa trên tab của nó';
	@override String get tvFullCardLayout => 'Full TV Card';
	@override String get tvFullCardLayoutDescription => 'Sử dụng hình ảnh-chỉ thẻ TV với tên diễn viên quá tải';
	@override String get focusGlow => 'Tập trung Glow';
	@override String get focusGlowDescription => 'Nhấn một ánh sáng mềm xung quanh thẻ tập trung';
	@override String get visualEffects => 'Hiệu ứng hình ảnh';
	@override String get visualEffectsAuto => 'Tự động';
	@override String get visualEffectsAutoDescription => 'Tự động giảm hiệu ứng trên các thiết bị có năng lượng thấp';
	@override String get visualEffectsFull => 'đầy đủ';
	@override String get visualEffectsReduced => 'Giảm';
	@override String get visualEffectsReducedDescription => 'Ít hoạt hình và các tác phẩm nghệ thuật độ phân giải thấp hơn';
	@override String get hideSpoilers => 'Ẩn Spoilers cho Unwatched Episodes';
	@override String get hideSpoilersDescription => 'Blur miniatures và mô tả cho các tập phim chưa được quan sát';
	@override String get playerBackend => 'Trò chơi Backend';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Phần cứng decoding';
	@override String get hardwareDecodingDescription => 'Sử dụng phần cứng tăng tốc khi có sẵn';
	@override String get playbackBuffer => 'Đánh giá Playback Buffer';
	@override String get playbackBufferAuto => 'Xe (được khuyến cáo)';
	@override String get playbackBufferLarge => 'Lớn';
	@override String get playbackBufferExtraLarge => 'Rất Lớn';
	@override String get playbackBufferDescription => 'Buffer nhiều hơn so với các kết nối không ổn định. cũng giới hạn bởi Buffer Size.';
	@override String get streamBufferSize => 'Buffer kích thước';
	@override String streamBufferSizeValue({required Object size}) => '${size} MB';
	@override String get streamBufferSizeDescription => 'Bao nhiêu video để tải về trước khi chơi trực tiếp. Transcodes dừng tại buffer transcode của máy chủ. 0 = Tự động';
	@override String get streamBufferSizeExoNote => 'Thay thế Playback Buffer khi cài đặt, cáp ở nửa giới hạn bộ nhớ của ứng dụng';
	@override String get streamBufferMegabytes => 'Megabyte';
	@override String get defaultQualityTitle => 'Chất lượng mặc định';
	@override String get cellularQualityTitle => 'Chất lượng mặc định trên Cellular';
	@override String get remoteQualityTitle => 'chất lượng Streaming từ xa';
	@override String get remoteQualitySameAsDefault => 'Tương tự như chất lượng mặc định';
	@override String get cellularQualitySameAsDefault => 'Tương tự như chất lượng mặc định';
	@override String get directPlayCoveredQuality => 'Chơi video nhỏ hơn với chất lượng ban đầu';
	@override String get directPlayCoveredQualityDescription => 'Tải trực tiếp video trong giới hạn chất lượng thay vì chuyển mã chúng';
	@override String get videoCodecs => 'Video Codec';
	@override String get videoCodecsDescription => 'Các codec không được kiểm tra được mã hóa bởi máy chủ';
	@override String get videoCodecsAlwaysAccepted => 'Luôn luôn chấp nhận';
	@override String get musicQualityTitle => 'Chất Lượng Âm Nhạc';
	@override String get subtitleStyling => 'Kiểu phụ đề';
	@override String get subtitleStylingDescription => 'Tùy chỉnh Subtitle xuất hiện';
	@override String get smallSkipDuration => 'Lớn Skip Thời gian';
	@override String get largeSkipDuration => 'Lớn Skip Thời gian';
	@override String get rewindOnResume => 'Rewind trên Resume';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(seconds,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} giây',
	);
	@override String get defaultSleepTimer => 'Thời gian giấc ngủ mặc định';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(minutes,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} phút',
	);
	@override String get rememberTrackSelections => 'Hãy nhớ các lựa chọn theo show/movie';
	@override String get chooseTracksBeforePlayback => 'Chọn âm thanh và subtitles trước khi playback';
	@override String get chooseTracksBeforePlaybackDescription => 'Chọn nguồn âm thanh và theo dõi subtitle trước khi mỗi video bắt đầu.';
	@override String get alwaysShowSubtitlesOnDevice => 'Luôn hiển thị các tiêu đề trên thiết bị này';
	@override String get alwaysShowSubtitlesOnDeviceDescription => 'Khi máy chủ không có subtitle được chọn, hãy chọn một track địa phương. điều này không bao giờ thay đổi sở thích của máy chủ.';
	@override String get autoDownloadPreferredSubtitle => 'Fetch thiếu các subtitles ngôn ngữ thích nhất';
	@override String get autoDownloadPreferredSubtitleDescription => 'Chọn một tiêu đề có sẵn trong ngôn ngữ yêu thích của bạn tại địa phương. nếu không có, hãy yêu cầu máy chủ thu thập một khi được hỗ trợ.';
	@override String get rememberTrackSelectionsDescription => 'Lưu các lựa chọn âm thanh và subtitle bằng chương trình hoặc phim trên thiết bị này';
	@override String get rememberTrackSelectionsBackendRule => 'Làm việc tại địa phương với Plex, Jellyfin, và Emby; Plex và Jellyfin cũng có thể lưu các lựa chọn trên máy chủ';
	@override String get followServerTrackSelections => 'Sử dụng các lựa chọn theo đoạn của máy chủ';
	@override String get followServerTrackSelectionsDescription => 'Khi thay đổi giai đoạn, hãy áp dụng âm thanh và tiêu đề được chọn trên máy chủ thay vì mang theo sự lựa chọn hiện tại.';
	@override String get resumeMusicOnLaunch => 'Lời bài hát Session Music';
	@override String get resumeMusicOnLaunchDescription => 'Khởi mở lại bài hát cuối cùng nghỉ ngơi nơi nó rời đi khi ứng dụng bắt đầu';
	@override String get showChapterMarkersOnTimeline => 'Hiển thị mục markers trên search bar';
	@override String get showChapterMarkersOnTimelineDescription => 'Segment the search bar at chapter giới hạn';
	@override String get specialsOrdering => 'Đặc biệt trong thứ tự episode';
	@override String get specialsOrderingDescription => 'Nơi đặc biệt chơi trong lệnh đồng hồ của một chương trình';
	@override String get specialsOrderingServer => 'Theo lệnh server';
	@override String get specialsOrderingAirDate => 'Interleave by air ngày';
	@override String get specialsOrderingLast => 'Sau mùa thường xuyên';
	@override String get clickVideoTogglesPlayback => 'Click vào video để toggle play/pause';
	@override String get clickVideoTogglesPlaybackDescription => 'Nhấp vào video để chơi/phút thay vì hiển thị các điều khiển.';
	@override String get videoPlayerControls => 'Video Player kiểm soát';
	@override String get keyboardShortcuts => 'Keyboard ngắn gọn';
	@override String get keyboardShortcutsDescription => 'Tùy chỉnh keyboard shortcuts';
	@override String get videoPlayerNavigation => 'Video Player hướng dẫn';
	@override String get videoPlayerNavigationDescription => 'Sử dụng chìa khóa mũi tên để di chuyển các điều khiển video player';
	@override String get watchTogetherRelay => 'Cùng xem Relay';
	@override String get watchTogetherRelayDescription => 'Public Open Watch Party phát sóng trừ khi bạn đặt riêng của bạn';
	@override String get watchTogetherRelayHint => 'https://my-relay.example.com';
	@override String get watchTogetherRelayInvalid => 'Nhập URL cơ sở HTTP hoặc HTTPS hợp lệ của máy chủ chuyển tiếp.';
	@override String get crashReporting => 'báo cáo crash';
	@override String get crashReportingDescription => 'Gửi báo cáo tai nạn để giúp cải thiện ứng dụng';
	@override String get debugLogging => 'Debug Logging Đánh giá';
	@override String get debugLoggingDescription => 'Khả năng đăng ký chi tiết cho giải quyết vấn đề';
	@override String get viewLogs => 'Xem Logs';
	@override String get viewLogsDescription => 'Xem ứng dụng logs';
	@override String get clearImageCache => 'Hình ảnh Cache';
	@override String get clearImageCacheDescription => 'Dấu hình và hình ảnh có thể tải chậm hơn cho đến khi tải lại.';
	@override String get clearImageCacheSuccess => 'Image cache đã được xóa thành công';
	@override String get resetSettings => 'Cài đặt Reset';
	@override String get resetSettingsDescription => 'Khôi phục cài đặt mặc định. điều này không thể bị bỏ qua.';
	@override String get resetSettingsSuccess => 'Cài đặt lại thành công';
	@override String get backup => 'Sao lưu';
	@override String get exportSettings => 'Cài đặt xuất khẩu';
	@override String get exportSettingsDescription => 'Lưu các tùy chọn của bạn vào một tệp';
	@override String get exportSettingsSuccess => 'Cài đặt xuất khẩu';
	@override String get importSettings => 'Cài đặt Import';
	@override String get importSettingsDescription => 'khôi phục các tùy chọn từ một tệp';
	@override String get importSettingsConfirm => 'Điều này sẽ thay thế cài đặt hiện tại của bạn. tiếp tục?';
	@override String get importSettingsSuccess => 'Cài đặt nhập khẩu';
	@override String get importSettingsInvalidFile => 'Tệp này không phải là một hợp lệ PlezyNG cài đặt xuất khẩu';
	@override String get importSettingsNoUser => 'Đăng nhập trước khi nhập cài đặt';
	@override String get cloudBackup => 'Mây Backup';
	@override String get cloudBackupDescription => 'Sao lưu các cài đặt có thể chuyển sang thiết bị khác đến địa chỉ WebDAV qua HTTPS. Kết nối máy chủ và thông tin đăng nhập vẫn nằm trên thiết bị này.';
	@override String get cloudBackupUrl => 'WebDAV JSON tập tin URL';
	@override String get cloudBackupUsername => 'Tên đăng nhập';
	@override String get cloudBackupPassword => 'Mật Khẩu';
	@override String get cloudBackupSaved => 'Cloud Backup Destination được tiết kiệm';
	@override String get cloudBackupNow => 'Back Up Nay';
	@override String get cloudBackupComplete => 'Cài đặt backup uploaded';
	@override String get cloudBackupRestore => 'khôi phục backup';
	@override String get cloudBackupRestoreConfirm => 'Điều này sẽ thay thế các cài đặt di động phù hợp trên thiết bị này.';
	@override String get cloudBackupRestored => 'Cài đặt khôi phục từ Cloud Backup';
	@override String get shortcutsReset => 'Tải về Shortcuts to defaults';
	@override String get resetShortcutsConfirm => 'Điều này sẽ thay thế các shortcuts tùy chỉnh của bạn với các default.';
	@override String get about => 'Về';
	@override String get aboutDescription => 'Thông tin ứng dụng và giấy phép';
	@override String get updates => 'Cập nhật';
	@override String get updateAvailable => 'Update có sẵn';
	@override String get checkForUpdates => 'Kiểm tra các bản cập nhật';
	@override String get autoCheckUpdatesOnStartup => 'Tự động kiểm tra cho các bản cập nhật trên startup';
	@override String get autoCheckUpdatesOnStartupDescription => 'Thông báo khi một bản cập nhật có sẵn khi khởi động';
	@override String get validationErrorEnterNumber => 'Vui lòng nhập số hợp lệ';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Phải nằm giữa ${min} và ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Shortcut đã được quy định cho ${action}';
	@override String shortcutUpdated({required Object action}) => 'Shortcut cập nhật cho ${action}';
	@override String get saveFailed => 'Không thể tiết kiệm được những thay đổi, hãy thử lại.';
	@override String get autoPlayAndSkip => 'Tải về Auto-Play & Skip';
	@override String get autoPlayNextEpisode => 'Auto-Play Phần tiếp theo';
	@override String get autoPlayNextEpisodeDescription => 'Bắt đầu phần tiếp theo tự động khi một kết thúc';
	@override String get shuffleStartsFromBeginning => 'Shuffle bắt đầu từ đầu';
	@override String get shuffleStartsFromBeginningDescription => 'Bắt đầu mỗi giai đoạn ngay từ đầu khi bấm vào thay vì lặp lại';
	@override String get plexCinemaPreRoll => 'Sử dụng server cinema intros';
	@override String get plexCinemaPreRollDescription => 'Chơi cấu hình Plex Pre-rolls hoặc Jellyfin và Emby intros trước khi một bộ phim bắt đầu.';
	@override String get playNextCountdown => 'Chơi Next Countdown';
	@override String get playNextCountdownImmediate => 'chơi ngay lập tức';
	@override String get skipIntroMode => 'Tải Skip Intro';
	@override String get skipIntroModeOffDescription => 'Chơi intros bình thường mà không có nút skip';
	@override String get skipIntroModeButtonDescription => 'Hiển thị nút skip khi một intro bắt đầu';
	@override String get skipIntroModeAutoDescription => 'Tự động nhảy vào sau khi chậm trễ dưới đây';
	@override String get skipCreditsMode => 'Skip tín dụng';
	@override String get skipCreditsModeOffDescription => 'Chơi tín dụng bình thường mà không có nút skip';
	@override String get skipCreditsModeButtonDescription => 'Hiển thị nút skip khi tín dụng bắt đầu';
	@override String get skipCreditsModeAutoDescription => 'Tải tín dụng tự động và chơi tập tiếp theo';
	@override String get skipAdsMode => 'Tải Ads';
	@override String get skipAdsModeOffDescription => 'Chơi quảng cáo được phát hiện bình thường mà không cần nút skip';
	@override String get skipAdsModeButtonDescription => 'Hiển thị nút skip khi Plex phát hiện một quảng cáo';
	@override String get skipAdsModeAutoDescription => 'Tắt quảng cáo được phát hiện tự động sau khi trì hoãn bên dưới';
	@override String get musicPlayback => 'Âm nhạc Playback';
	@override String get musicSweetFades => 'Sữa Fades';
	@override String get musicSweetFadesDescription => 'Âm nhạc Fade ở cạnh track khi Plex có dữ liệu âm thanh. album playback vẫn không thay đổi.';
	@override String get skipMarkerModeOff => 'Tắt';
	@override String get skipMarkerModeButton => 'Hiển thị nút';
	@override String get skipMarkerModeAuto => 'tự động';
	@override String get forceSkipMarkerFallback => 'Lời bài hát: Fallback Markers';
	@override String get forceSkipMarkerFallbackDescription => 'Sử dụng mô hình tiêu đề chương ngay cả khi Plex có dấu hiệu';
	@override String get theIntroDbFallback => 'Sử dụng TheIntroDB như một intro fallback';
	@override String get theIntroDbFallbackDescription => 'Sử dụng lịch cộng đồng chỉ khi máy chủ không có dấu intro.';
	@override String get autoSkipDelay => 'xe Skip chậm';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Đợi ${seconds} giây trước khi tự động nhảy';
	@override String get introPattern => 'Nhãn hiệu Intro Marker';
	@override String get introPatternDescription => 'Mô hình Regex để phù hợp với các markers intro trong tiêu đề';
	@override String get creditsPattern => 'Mã tín dụng Marker Pattern';
	@override String get creditsPatternDescription => 'Mô hình Regex để phù hợp với các tín dụng markers trong tiêu đề chương';
	@override String get prerolls => 'Video mở đầu';
	@override String get playPrerollsBeforeMovies => 'Trò chơi prerolls trước khi phim';
	@override String get playPrerollsBeforeMoviesDescription => 'Chơi một clip ngẫu nhiên từ lựa chọn của bạn bên dưới trước mỗi bộ phim.';
	@override String get prerollLibrary => 'Thư viện Preroll';
	@override String get prerollLibraryNotSet => 'Không đặt';
	@override String get prerollLibraryNoneFound => 'Không tìm thấy thư viện trên máy chủ của bạn.';
	@override String get prerollSelection => 'Quyền chọn prerolls';
	@override String get prerollSelectionPickLibraryFirst => 'Lựa chọn thư viện trước';
	@override String get prerollSelectionNoneSelected => 'Không có ưu đãi được chọn';
	@override String prerollSelectionCount({required Object count}) => '${count} được chọn';
	@override String get prerollItemPicker => 'Chọn prerolls';
	@override String get prerollItemPickerLoadFailed => 'Tôi không thể tải các mục từ thư viện này.';
	@override String get invalidRegex => '• Không có hiệu lực biểu hiện thường xuyên';
	@override String get regex => 'biểu hiện thường xuyên';
	@override String get downloads => 'Nội dung tải xuống';
	@override String get downloadLocationDescription => 'Chọn nơi để lưu trữ nội dung tải xuống';
	@override String get downloadLocationDefault => 'Chế độ lưu trữ (App Storage)';
	@override String get downloadLocationCustom => 'Vị trí tùy chỉnh';
	@override String get selectFolder => 'Chọn Folder';
	@override String get resetToDefault => 'Lập lại theo mặc định';
	@override String currentPath({required Object path}) => 'Hiện tại: ${path}';
	@override String get downloadLocationChanged => 'Download địa điểm thay đổi';
	@override String get downloadLocationReset => 'Tải về vị trí reset to default';
	@override String get downloadLocationInvalid => 'Mẫu được chọn không thể viết';
	@override String get downloadLocationPickerUnavailable => 'Chọn thư mục không sẵn dùng trên thiết bị này';
	@override String get downloadOnWifiOnly => 'Tải về trên Wi-Fi chỉ';
	@override String get downloadOnWifiOnlyDescription => 'Tránh tải xuống khi trên dữ liệu di động';
	@override String get autoRemoveWatchedDownloads => 'Auto-remove xem tải xuống';
	@override String get autoRemoveWatchedDownloadsDescription => 'Tự động xóa các tải xuống được xem';
	@override String get autoDownloadContinueWatching => 'Auto-Download Xem tiếp';
	@override String get autoDownloadContinueWatchingDescription => 'Giữ các mục trên hộp tiếp tục xem của bạn tải xuống, và xóa chúng một khi họ rời khỏi hộp';
	@override String get downloadQuality => 'Download chất lượng';
	@override String get downloadQualityDescription => 'Plex chuẩn bị một bản sao được chuyển đổi trong chuỗi tải xuống của nó. Jellyfin và Emby transcode trong khi tệp tải xuống; chuyển đổi bị gián đoạn có thể cần phải khởi động lại.';
	@override String get askDownloadQualityEachTime => 'Chọn chất lượng cho mỗi download';
	@override String get askDownloadQualityEachTimeDescription => 'Hiển thị chất lượng picker trước khi cheue mỗi video tải xuống';
	@override String get cellularDownloadBlocked => 'Tải xuống bị chặn trên điện thoại di động. sử dụng Wi-Fi hoặc thay đổi thiết lập.';
	@override String get maxVolume => 'Âm lượng tối đa';
	@override String get maxVolumeDescription => 'Cho phép tăng âm lượng trên 100% đối với nội dung có âm thanh nhỏ';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Sự hiện diện phong phú';
	@override String get discordRichPresenceDescription => 'Hiển thị những gì bạn đang xem trên Discord';
	@override String get services => 'Dịch vụ';
	@override String get servicesDescription => 'Kết nối Trakt, MyAnimeList, Seerr, và nhiều hơn nữa';
	@override String get manageLibrariesDescription => 'Đặt lại và ẩn thư viện';
	@override String get companionRemoteServer => 'Dịch vụ Remote Server';
	@override String get companionRemoteServerDescription => 'Cho phép các thiết bị di động trên mạng của bạn để kiểm soát ứng dụng này';
	@override String get companionRemoteServerStartFailed => 'Không thể khởi động máy chủ đồng nghiệp';
	@override String get companionRemoteServerStopFailed => 'Không thể dừng lại máy chủ đồng nghiệp';
	@override String get autoPip => 'Ảnh Auto Picture in Picture';
	@override String get autoPipDescription => 'Tự động nhập hình ảnh trong khi bạn rời khỏi ứng dụng trong khi chơi';
	@override String get matchContentFrameRate => 'Match Content Frame Tỷ lệ';
	@override String get matchContentFrameRateDescription => 'Match hiển thị tốc độ phục hồi cho nội dung video';
	@override String get matchContentResolution => 'Match Content Quyết định';
	@override String get matchContentResolutionDescription => 'Chuyển đổi màn hình sang độ phân giải bản địa của video để TV của bạn hoạt động upscaling. Menu và subtitles cũng được upscaled trong khi xem lại';
	@override String get matchRefreshRate => 'Tỷ lệ Match Refresh Rate';
	@override String get matchRefreshRateDescription => 'Match hiển thị tốc độ phục hồi trong màn hình đầy đủ';
	@override String get matchDynamicRange => 'Đánh giá Dynamic Range';
	@override String get matchDynamicRangeDescription => 'Chuyển đổi HDR cho nội dung HDR, sau đó trở lại SDR';
	@override String get displaySwitchDelay => 'Tính năng: Display Switch Delay';
	@override String get tunneledPlayback => 'Tải Tunnel Playback';
	@override String get tunneledPlaybackDescription => 'Sử dụng đường hầm video. tắt nếu HDR playback hiển thị video màu đen hoặc động tác.';
	@override String get audioPassthrough => 'Âm thanh trượt';
	@override String get audioPassthroughDescription => 'Gửi âm thanh Dolby/DTS đến máy nhận hoặc TV của bạn mà không cần mã hóa lại, duy trì âm thanh xung quanh.';
	@override String get audioPassthroughDescriptionApple => 'Sử dụng bộ giải mã Dolby gốc của Apple cho Dolby Digital Plus, bao gồm Atmos. DTS và TrueHD vẫn chơi như PCM đa kênh.';
	@override String get audioPassthroughDescriptionAppleSpatial => 'Sử dụng bộ giải mã Dolby bản địa của Apple cho Dolby Digital Plus, bao gồm Atmos. Trên iOS, iPadOS và tvOS 26 hoặc sau đó, TrueHD Atmos và DTS:X chơi như âm thanh không gian.';
	@override String get audioPassthroughOverriddenByNormalization => 'Tắt trong khi bình thường hóa âm thanh';
	@override String get audioChannelLimit => 'Kênh âm thanh';
	@override String get audioChannelLimitDescription => 'Thay đổi âm thanh giải mã xuống cho các loa, tai nghe, hoặc cài đặt HDMI mà không thể phát tất cả các kênh';
	@override String get audioChannelLimitOriginal => 'nguyên bản';
	@override String get audioChannelLimitOriginalDescription => 'Chơi mỗi kênh trong track';
	@override String get audioChannelLimitSurround51 => 'Đến 5.1';
	@override String get audioChannelLimitSurround51Description => 'Trộn 7.1 xuống 5.1 cho các TV và máy nhận mà chỉ mất 5.1 PCM.';
	@override String get audioChannelLimitStereo => 'Âm Thanh Nổi';
	@override String get audioChannelLimitStereoDescription => 'Thay vào hai kênh cho các loa stereo hoặc tai nghe.';
	@override String get downmixCenterBoost => 'Trung tâm kênh Boost';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Độ bền (dB)';
	@override String get downmixCenterBoostShort => 'db';
	@override String get audioDownmixNormalize => 'Tính năng của Downmix';
	@override String get audioDownmixNormalizeDescription => 'Giảm hỗn hợp để ngăn chặn nhấp chuột. tắt để giữ khối lượng ban đầu (có thể làm hỏng các cảnh lớn).';
	@override String get dvConversionMode => 'Dolby Vision Chuyển đổi';
	@override String get dvConversionModeDescription => 'Chọn cách xử lý Dolby Vision Hồ sơ 7 tệp.';
	@override String get dvConversionAuto => 'Tự động';
	@override String get dvConversionNative => 'Người mẹ / khuyết tật';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Sử dụng khả năng phát hiện thiết bị và hành vi Fallback bình thường';
	@override String get dvConversionNativeDescription => 'Native Force DV7 và suppress DV conversion retry';
	@override String get dvConversionDv81Description => 'Chuyển đổi RPU mạnh vào hồ sơ Dolby Vision 8.1';
	@override String get dvConversionHevcStripDescription => 'Dây Dolby Vision lớp RPU/EL và mặt bằng hiện tại HEVC';
	@override String get experimentalDolbyVision => 'Dolby Vision thử nghiệm';
	@override String get experimentalDolbyVisionDescription => 'Dùng bộ kết xuất FEL thử nghiệm trong lần phát tiếp theo. Cần bản dựng bộ máy riêng.';
	@override String get dvExperimentUnavailableDescription => 'Thử nghiệm này hiện chỉ có trên Linux.';
	@override String get dvCompatibilityFallback => 'Phương án tương thích dự phòng';
	@override String get dvCompatibilityFallbackDescription => 'Dùng bộ kết xuất tiêu chuẩn nếu không thể bắt đầu thử nghiệm. Dữ liệu FEL có thể bị mất.';
	@override String get dvExperimentDiagnostics => 'Nhật ký thử nghiệm video';
	@override String get dvExperimentDiagnosticsDescription => 'Bật nhật ký trình phát chi tiết trong lần phát tiếp theo.';
	@override String get disableDolbyVision => 'Không thể bỏ qua Dolby Vision';
	@override String get disableDolbyVisionDescription => 'Chơi file HDR10 hoặc lớp HLG thay vì Dolby Vision, khi nó có một';
	@override String get hdrSdrConversion => 'HDR sang SDR chuyển đổi';
	@override String get hdrSdrConversionDescription => 'Chọn những gì chuyển đổi video HDR khi màn hình không thể hiển thị HDR.';
	@override String get hdrSdrConversionAuto => 'Tự động';
	@override String get hdrSdrConversionAutoDescription => 'Thiết bị trên Android 9 và sau, người chơi trên các phiên bản cũ hơn';
	@override String get hdrSdrConversionDevice => 'Thiết bị';
	@override String get hdrSdrConversionDeviceDescription => 'Phần cứng video của thiết bị của bạn chuyển đổi nó. nhanh nhất, nhưng màu sắc phụ thuộc vào thiết bị';
	@override String get hdrSdrConversionPlayer => 'Trình Phát';
	@override String get hdrSdrConversionPlayerDescription => 'Màu sắc nhất quán, nhưng 4K có thể đâm vào các hộp TV thấp';
	@override String get deinterlace => 'Interlacing Đánh giá';
	@override String get deinterlaceDescription => 'Xóa các tác phẩm kết hợp từ video liên kết (mpv người chơi chỉ)';
	@override String get deinterlaceOff => 'Tắt';
	@override String get deinterlaceOffDescription => 'Hiển thị video liên kết khi nó được giải mã';
	@override String get deinterlaceVideo => 'Video';
	@override String get deinterlaceVideoDescription => 'Chuyển đổi mỗi trường thành một khung đầy đủ. cho video chụp cho TV, chẳng hạn như thể thao, tin tức, và các buổi hòa nhạc';
	@override String get deinterlaceFilm => 'phim';
	@override String get deinterlaceFilmDescription => 'Khôi phục các khung gốc của bộ phim và hoạt hình truyền hình đến 29.97 fps, phổ biến trên DVD NTSC. Video shot for TV stutters. Live TV uses Video';
	@override String get requireProfileSelectionOnOpen => 'Yêu cầu hồ sơ trên app open';
	@override String get requireProfileSelectionOnOpenDescription => 'Hiển thị lựa chọn hồ sơ mỗi khi ứng dụng được mở';
	@override String get forceTvMode => 'Phim truyền hình Force';
	@override String get forceTvModeDescription => 'Thiết lập TV Force. Đối với các thiết bị không tự phát hiện. Cần khởi động lại.';
	@override String get startInFullscreen => 'Bắt đầu trên màn hình đầy đủ';
	@override String get startInFullscreenDescription => 'Mở PlezyNG trong chế độ màn hình đầy đủ khi ra mắt';
	@override String get exitFullscreenOnPlayerClose => 'Mở màn hình đầy đủ trên player close';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Tự động ra khỏi màn hình đầy đủ khi đóng video player';
	@override String get autoHidePerformanceOverlay => 'Tính năng Auto-Hide Performance Overlay';
	@override String get autoHidePerformanceOverlayDescription => 'Giảm hiệu suất với các điều khiển playback';
	@override String get showNavBarLabels => 'Hiển thị Navigation Bar Labels';
	@override String get showNavBarLabelsDescription => 'Hiển thị các nhãn văn bản dưới biểu tượng thanh điều hướng';
	@override String get startupSection => 'Startup Phần';
	@override String get preferredServer => 'Ưu tiên Server';
	@override String get preferredServerDescription => 'ưu tiên kết quả của máy chủ này trong khi giữ cho mỗi máy chủ kết nối có sẵn.';
	@override String get preferredServerAutomatic => 'tự động';
	@override String get showExploreTab => 'Hiển thị Explore Tab';
	@override String get showExploreTabDescription => 'Hiển thị tab Khám phá với nội dung từ Plex Khám phá và theo dõi kết nối';
	@override String get hideEmptyLibraries => 'Ẩn thư viện trống';
	@override String get hideEmptyLibrariesDescription => 'Xóa thư viện với số lượng mục được báo cáo trên máy chủ bằng 0 từ điều hướng.';
	@override String get liveTvDefaultFavorites => 'Chất lượng kênh yêu thích';
	@override String get liveTvDefaultFavoritesDescription => 'Chỉ hiển thị các kênh yêu thích khi mở Live TV';
	@override String get general => 'Chung';
	@override String get generalDescription => 'Ngôn ngữ, khởi động và hành vi cửa sổ';
	@override String get languageAndRegion => 'Ngôn ngữ & Khu vực';
	@override String get startup => 'Khởi động';
	@override String get display => 'Hiển thị';
	@override String get libraryAndCards => 'Thư viện & Bản đồ';
	@override String get homeScreen => 'Home màn hình';
	@override String get navigation => 'Điều Hướng';
	@override String get window => 'cửa sổ';
	@override String get liveTv => 'Truyền hình trực tiếp';
	@override String get player => 'Trình Phát';
	@override String get videoAndDisplay => 'Video & Hiển thị';
	@override String get audio => 'Âm thanh';
	@override String get quality => 'Chất lượng';
	@override String get subtitles => 'Phụ đề';
	@override String get seekAndTiming => 'Tìm & Thời gian';
	@override String get behavior => 'hành vi';
	@override String get gestures => 'gợi ý';
	@override String get gestureBrightnessSwipe => 'Ánh sáng Swipe';
	@override String get gestureBrightnessSwipeDescription => 'Chuyển lên hoặc xuống trên cạnh trái để điều chỉnh độ sáng';
	@override String get gestureVolumeSwipe => 'Độ bền Swipe';
	@override String get gestureVolumeSwipeDescription => 'Chuyển lên hoặc xuống trên cạnh phải để điều chỉnh khối lượng';
	@override String get gesturePinchToZoom => 'Pinch đến Zoom';
	@override String get gesturePinchToZoomDescription => 'Nhấn vào video để zoom vào hoặc ra';
	@override String get gestureSeekSwipe => 'Tìm kiếm Swipe';
	@override String get gestureSeekSwipeDescription => 'Chuyển sang trái hoặc thẳng bất cứ nơi nào trên video để tìm; phát hành để nhảy';
	@override String get rememberBrightnessLevel => 'Nhớ mức độ sáng';
	@override String get rememberBrightnessLevelDescription => 'Bắt đầu playback tại độ sáng được thiết lập bởi swipe cuối cùng';
	@override String get controls => 'Điều khiển';
	@override String get rememberPlayerChanges => 'Nhớ thay đổi người chơi';
	@override String get rememberPlayerChangesDescription => 'Khi một thay đổi được thực hiện trong khi playback được tiết kiệm và áp dụng lại từ';
	@override String get scopePlaybackSpeed => 'Tốc Độ Phát';
	@override String get scopeShaderPreset => 'Shader Preset Đánh giá';
	@override String get scopeAspectRatio => 'Tỷ Lệ Khung Hình';
	@override String get scopeSyncOffsets => 'Audio & Subtitle đồng bộ';
	@override String get playerScopeOff => 'Đừng tiết kiệm';
	@override String get playerScopeGlobal => 'khắp nơi';
	@override String get playerScopeLibrary => 'bởi thư viện';
	@override String get playerScopeTitle => 'Theo chương trình hay phim';
	@override String get exportDialogTitle => 'Xuất khẩu PlezyNG thiết lập';
	@override String get followSystem => 'Theo hệ thống';
	@override String get followAppLanguage => 'Theo ngôn ngữ giao diện';
	@override String get regionFormat => 'Định dạng khu vực';
	@override String get regionFormatDescription => 'Chọn cách hiển thị ngày, số và đơn vị đo.';
	@override String get metadataLanguage => 'Ngôn ngữ siêu dữ liệu';
	@override String get metadataLanguageDescription => 'Ngôn ngữ ưu tiên cho tiêu đề và mô tả khi máy chủ hỗ trợ. Tùy chọn âm thanh và phụ đề được thiết lập riêng.';
	@override String get enterFullscreenOnPlaybackStart => 'Nhập màn hình đầy đủ khi playback bắt đầu';
	@override String get enterFullscreenOnPlaybackStartDescription => 'Mở video desktop trên màn hình đầy đủ khi playback bắt đầu';
	@override String get extendVideoIntoDisplayCutout => 'mở rộng video vào display cutout';
	@override String get extendVideoIntoDisplayCutoutDescription => 'Hãy để video màn hình đầy đủ sử dụng camera cutout trên điện thoại Android';
	@override String get languageDescription => 'Chọn ngôn ngữ được sử dụng cho các điều khiển và thông điệp PlezyNG. Theo hệ thống theo dõi ngôn ngữ thiết bị của bạn.';
	@override String get themeDescription => 'Chọn các màu sắc và tương phản được sử dụng trong toàn bộ ứng dụng.';
	@override String get libraryDensityDescription => 'Thay đổi số thẻ thư viện phù hợp trong mỗi hàng.';
	@override String get displayScaleDescription => 'Khôi phục lại giao diện trên màn hình xe này mà không thay đổi kích thước văn bản trên thiết bị của bạn.';
	@override String get themeSongVolumeDescription => 'Thiết lập khối lượng của bài hát chủ đề so với các âm thanh khác.';
	@override String get viewModeDescription => 'Chọn xem các mục thư viện có xuất hiện như poster trong một mạng lưới hay là danh sách nhỏ gọn.';
	@override String get gridViewDescription => 'sắp xếp các mục thư viện trong hàng và cột poster.';
	@override String get listViewDescription => 'Hiển thị các mục thư viện trong một danh sách dọc với nhiều văn bản hơn cho mỗi mục.';
	@override String get gridSpacingDescription => 'Đặt khoảng cách giữa các poster trong các mạng thư viện.';
	@override String get gridSpacingTightDescription => 'Thích hợp nhiều poster trên màn hình với khoảng trống nhỏ hơn.';
	@override String get gridSpacingNormalDescription => 'Sử dụng khoảng cách tiêu chuẩn giữa các poster.';
	@override String get gridSpacingSpaciousDescription => 'Thêm khoảng cách lớn hơn giữa các poster cho sự tách rời nhiều hơn.';
	@override String get episodePosterModeDescription => 'Chọn tác phẩm nghệ thuật nào xuất hiện trên các thẻ tập.';
	@override String get seriesPosterDescription => 'Sử dụng poster series của chương trình cho mỗi tập.';
	@override String get seasonPosterDescription => 'Sử dụng poster mùa cho mỗi tập khi có sẵn.';
	@override String get episodeThumbnailDescription => 'Sử dụng một khung từ tập phim khi có sẵn.';
	@override String get continueWatchingActionDescription => 'Chọn những gì xảy ra khi bạn kích hoạt một thẻ tiếp tục xem.';
	@override String get continueWatchingPlayDescription => 'Bắt đầu bộ phim hoặc tập ngay lập tức.';
	@override String get continueWatchingDetailsDescription => 'Mở trang tiêu đề đầu tiên để bạn có thể xem xét chi tiết và chọn một hành động.';
	@override String get episodeActionDescription => 'Chọn những gì xảy ra khi bạn kích hoạt một thẻ episode.';
	@override String get episodePlayDescription => 'Bắt đầu sự kiện ngay lập tức.';
	@override String get episodeDetailsDescription => 'Mở trang tập trước khi playback.';
	@override String get contentScreensaverDelayDescription => 'Chọn bao lâu PlezyNG chờ đợi mà không có đầu vào trước khi hiển thị tác phẩm nghệ thuật.';
	@override String get continueWatchingRowSizeDescription => 'Chọn kích thước của các thẻ trong dòng tiếp tục xem.';
	@override String get rowSizeCompactDescription => 'Hiển thị các thẻ nhỏ hơn để nhiều mục phù hợp trên hàng.';
	@override String get rowSizeStandardDescription => 'Sử dụng kích thước thẻ tiêu chuẩn.';
	@override String get rowSizeLargeDescription => 'Hiển thị các thẻ lớn hơn với chi tiết nghệ thuật nhiều hơn.';
	@override String get visualEffectsDescription => 'Chọn ngân sách hoạt hình và hiệu ứng nghệ thuật cho thiết bị này.';
	@override String get visualEffectsFullDescription => 'Sử dụng các hiệu ứng hoạt hình và nghệ thuật đầy đủ trên mỗi thiết bị.';
	@override String get startupSectionDescription => 'Chọn phần nào mở khi PlezyNG bắt đầu.';
	@override late final _Translations$settings$startupSectionOptions$vi startupSectionOptions = _Translations$settings$startupSectionOptions$vi._(_root);
	@override String get smallSkipDurationDescription => 'Thiết lập khoảng cách di chuyển bởi phía sau ngắn và phía trước tìm kiếm kiểm soát.';
	@override String get largeSkipDurationDescription => 'Thiết lập khoảng cách di chuyển bởi phía sau dài và phía trước tìm kiếm kiểm soát.';
	@override String get rewindOnResumeDescription => 'Chuyển đổi playback trở lại với số tiền này khi quay lại một video.';
	@override String get defaultSleepTimerDescription => 'Thiết lập thời gian ban đầu được sử dụng khi bạn bắt đầu giờ ngủ.';
	@override String get playNextCountdownDescription => 'Hãy đợi điều này lâu trước khi bắt đầu tập tiếp theo. thiết lập đến 0 để bắt đầu ngay lập tức.';
	@override String get autoSkipDelaySettingDescription => 'Ứng dụng khi một intro, tín chỉ hoặc quảng cáo được thiết lập để tự động bỏ qua.';
	@override String get downmixCenterBoostDescription => 'Tăng sự đối thoại trong kênh trung tâm khi âm thanh xung quanh được trộn xuống stereo.';
	@override String get displaySwitchDelayDescription => 'Đợi trước khi thay đổi chế độ hiển thị để TV hoặc người nhận có thể hoàn thành chuyển đổi trước đó.';
	@override String get playerBackendDescription => 'Chọn động cơ playback nào giải mã và render video trên thiết bị này.';
	@override String get exoPlayerDescription => 'Sử dụng người chơi gốc của Android dựa trên Media3 và các con đường phần cứng được hỗ trợ.';
	@override String get mpvDescription => 'Sử dụng mpv, mà tiết lộ thêm playback, subtitle và kiểm soát xử lý video.';
	@override String get scopeOffDescription => 'Chỉ giữ các thay đổi cho phiên bản playback hiện tại.';
	@override String get scopeGlobalDescription => 'Sử dụng lại cùng một giá trị cho mỗi thư viện và tiêu đề.';
	@override String get scopeLibraryDescription => 'Hãy nhớ một giá trị riêng biệt cho mỗi thư viện.';
	@override String get scopeTitleDescription => 'Hãy nhớ một giá trị riêng biệt cho mỗi chương trình hoặc bộ phim.';
	@override String get specialsOrderingServerDescription => 'Giữ lệnh episode được cung cấp bởi máy chủ truyền thông.';
	@override String get specialsOrderingAirDateDescription => 'Đặt đặc biệt trong số các tập thường xuyên theo ngày không của họ.';
	@override String get specialsOrderingLastDescription => 'Đặt mỗi đặc biệt sau các mùa thường xuyên.';
	@override String get skipIntroModeDescription => 'Chọn xem các markers intro chơi bình thường, hiển thị một nút skip hoặc skip tự động.';
	@override String get skipCreditsModeDescription => 'Chọn xem tín dụng chơi bình thường, hiển thị một nút skip hoặc tự động skip.';
	@override String get skipAdsModeDescription => 'Chọn xem quảng cáo được phát hiện có chơi bình thường hay không, hiển thị nút skip hoặc skip tự động.';
	@override String get playbackBufferAutoDescription => 'Cho phép người chơi hoạt động chọn kích thước buffer bình thường của nó.';
	@override String get playbackBufferLargeDescription => 'Giữ nhiều phương tiện truyền thông sẵn sàng trước khi chơi; điều này sử dụng thêm bộ nhớ.';
	@override String get playbackBufferExtraLargeDescription => 'Giữ buffer lớn nhất để đọc; điều này sử dụng bộ nhớ nhiều nhất.';
	@override String get defaultQualityDescription => 'Thiết lập độ phân giải video mặc định và bitrate mái cho các dòng mà máy chủ chuyển mã.';
	@override String get cellularQualityDescription => 'Override Chất lượng mặc định khi thiết bị đang sử dụng một kết nối cell-only.';
	@override String get remoteQualityDescription => 'Override Chất lượng mặc định khi kết nối với một máy chủ thông qua kết nối từ xa.';
	@override String get qualityPresetOriginalDescription => 'Chơi nguồn với chất lượng có sẵn mà không yêu cầu máy chủ chuyển mã nó.';
	@override String get qualityPresetTranscodeOptionDescription => 'Yêu cầu máy chủ cho một dòng chuyển đổi bằng cách sử dụng độ phân giải và bitrate được hiển thị ở trên.';
	@override String get qualityPresetSameAsDefaultDescription => 'Sử dụng chất lượng được chọn trong Chất lượng mặc định.';
	@override String get musicQualityDescription => 'Thiết lập tốc độ bit âm thanh tối đa được yêu cầu từ máy chủ; Original giữ dòng nguồn.';
	@override String get musicQualityOriginalDescription => 'Chơi âm thanh nguồn mà không có transcode bitrate.';
	@override String get musicQualityTranscodeOptionDescription => 'Yêu cầu một transcode máy chủ được cáp gần bitrate hiển thị ở trên; kết quả thực tế có thể thay đổi.';
	@override String get maxVolumeInputLabel => 'Số lượng tối đa (%)';
	@override String get checkForUpdatesDescription => 'Bây giờ kiểm tra xem phiên bản mới hơn của PlezyNG có sẵn hay không.';
	@override String get appearanceDescription => 'Chọn chủ đề ứng dụng và điều chỉnh thư viện thẻ, dòng nhà, và di chuyển.';
	@override String get prerollLibraryDescription => 'Chọn thư viện chứa các clip có sẵn như phim pre-rolls.';
	@override String get prerollSelectionDescription => 'Chọn clip nào từ thư viện được chọn có thể chơi trước khi xem phim.';
	@override String get contentScreensaverDelayOptionDescription => 'Đợi nhiều phút này mà không cần nhập trước khi hiển thị màn hình bảo vệ nghệ thuật.';
	@override String get videoCodecOptionDescription => 'Cho phép phát trực tiếp cho codec này khi được hỗ trợ. codec không kiểm tra được chuyển mã bởi máy chủ truyền thông.';
}

// Path: themeEditor
class _Translations$themeEditor$vi extends Translations$themeEditor$en {
	_Translations$themeEditor$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get builtIn => 'xây dựng';
	@override String get presets => 'Lời bài hát';
	@override String get custom => 'Tùy chọn';
	@override String get customEmpty => 'chưa được tạo ra';
	@override String get editCustom => 'Edit chủ đề';
	@override String get editCustomDescription => 'Chọn mỗi màu cho riêng mình';
	@override String get locked => 'Thời gian tiếp cận cần thiết';
	@override String get savedLocked => 'Tiết kiệm - có sẵn với quyền truy cập suốt đời';
	@override String get title => 'Chủ đề Custom';
	@override String get startFrom => 'Bắt đầu từ';
	@override String get startFromDescription => 'Sao chép tất cả các màu sắc từ một chủ đề khác';
	@override String get colors => 'Màu sắc';
	@override String get preview => 'Xem thử';
	@override late final _Translations$themeEditor$slots$vi slots = _Translations$themeEditor$slots$vi._(_root);
	@override String get opacity => 'Độ mờ';
	@override String get hexHint => '#RRGGBB hoặc #AARRGGBB';
	@override String get fromOtherThemes => 'Từ các chủ đề khác';
	@override String swatchLabel({required Object theme, required Object color}) => '${theme} ${color}';
	@override late final _Translations$themeEditor$contrast$vi contrast = _Translations$themeEditor$contrast$vi._(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, dưới số đề xuất ${minimum}:1';
	@override String get discardTitle => 'Thay đổi không?';
	@override String get discardMessage => 'Các thay đổi màu chưa lưu sẽ bị mất.';
	@override String get discard => 'Khác';
	@override String previewCardTitle({required Object number}) => 'Chương ${number}';
	@override String previewCardSubtitle({required Object minutes}) => '${minutes} phút left';
	@override String get previewSwitch => 'Tự động phát';
	@override String get previewMutedText => 'Bài viết thứ hai đọc như thế này';
	@override String get themeSystemDescription => 'Theo dõi sự xuất hiện của thiết bị và tự động chuyển đổi giữa ánh sáng và bóng tối.';
	@override String get themeLightDescription => 'Sử dụng nền sáng với văn bản tối.';
	@override String get themeDarkDescription => 'Sử dụng nền tối với văn bản sáng.';
	@override String get themeOledDescription => 'Sử dụng các bề mặt gần đen làm giảm ánh sáng trên màn hình OLED.';
	@override String get themeEmberDescription => 'Sử dụng màu đỏ ấm và accent amber.';
	@override String get themeGlacierDescription => 'Sử dụng màu sắc accent xanh mát mẻ.';
	@override String get themeForestDescription => 'Sử dụng màu xanh lá cây và sắc thái tự nhiên.';
	@override String get themePlumDescription => 'Sử dụng màu violet và plum accent.';
	@override String get themePaperDescription => 'Sử dụng các bề mặt như giấy ấm áp và màu sắc được truyền cảm hứng từ sơn.';
	@override String get themeCustomDescription => 'Sử dụng bảng màu mà bạn tạo trong biên tập chủ đề tùy chỉnh.';
	@override String get editorDescription => 'Chọn một màu palette, điều chỉnh độ ẩm, độ ăn kiêng, độ sáng hoặc độ không chính xác của nó và xem bản cập nhật trước khi tiết kiệm. bạn cũng có thể nhập màu hex.';
}

// Path: search
class _Translations$search$vi extends Translations$search$en {
	_Translations$search$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Tìm kiếm phim, chương trình, âm nhạc...';
	@override String get tryDifferentTerm => 'Thử một thuật ngữ tìm kiếm khác';
	@override String get searchYourMedia => 'Tìm kiếm phương tiện truyền thông của bạn';
	@override String get enterTitleActorOrKeyword => 'Nhập một tiêu đề, diễn viên hoặc từ khóa';
	@override String get people => 'Diễn Viên';
}

// Path: hotkeys
class _Translations$hotkeys$vi extends Translations$hotkeys$en {
	_Translations$hotkeys$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Thiết lập Shortcut cho ${actionName}';
	@override String get clearShortcut => 'ngắn gọn';
	@override String get noShortcutSet => 'Không shortcut set';
	@override String get currentShortcut => 'Hiện tại shortcut:';
	@override String get pressToRecord => 'Chọn để ghi một shortcut';
	@override String get recordingShortcut => 'Nhấn shortcut bây giờ';
	@override late final _Translations$hotkeys$actions$vi actions = _Translations$hotkeys$actions$vi._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$vi extends Translations$fileInfo$en {
	_Translations$fileInfo$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'File thông tin';
	@override String get overview => 'Tổng quan';
	@override String get video => 'Video';
	@override String get audio => 'Âm thanh';
	@override String get subtitles => 'Phụ đề';
	@override String get images => 'Hình ảnh tích hợp';
	@override String get dataStreams => 'dữ liệu Streams';
	@override String get lyrics => 'Lời bài hát';
	@override String get file => 'Tệp';
	@override String get attachments => 'Phụ kiện';
	@override String get delivery => 'giao hàng';
	@override String versionCounter({required Object index, required Object count}) => 'Phiên bản ${index} của ${count}';
	@override String fileCounter({required Object index, required Object count}) => 'Tài liệu ${index} của ${count}';
	@override String get noStreams => 'Các máy chủ không tiết lộ không có dòng cho tệp này.';
	@override String get copyPath => 'Bản sao đường';
	@override String get pathCopied => 'file path sao chép';
	@override String get codec => 'Mã hóa';
	@override String get codecTag => 'Thẻ mã hóa';
	@override String get resolution => 'Độ phân giải';
	@override String get codedResolution => 'Quyết định mã hóa';
	@override String get bitrate => 'Tốc độ bit';
	@override String get frameRate => 'Tỷ lệ Frame';
	@override String get rotation => 'Xoay';
	@override String get comment => 'Comment Cách';
	@override String get audioDescription => 'Mô tả Audio';
	@override String get headerCompression => 'Header phức tạp';
	@override String get sidecarFile => 'Sidecar Tệp';
	@override String get transportTimestamp => 'Thời gian vận chuyển';
	@override String get displayOffset => 'Hiển thị Offset';
	@override String get previewFailureCode => 'Mã thất bại trước';
	@override String get previewRetries => 'Preview Phản hồi';
	@override String get aspectRatio => 'Tỷ Lệ Khung Hình';
	@override String get pixelAspectRatio => 'Tính năng Pixel Aspect';
	@override String get profile => 'Hồ sơ';
	@override String get level => 'Mức độ';
	@override String get bitDepth => 'Độ sâu bit';
	@override String get pixelFormat => 'Định dạng pixel';
	@override String get colorSpace => 'Bộ mã màu';
	@override String get colorRange => 'Màu sắc Range';
	@override String get colorPrimaries => 'Những màu chủ đạo';
	@override String get colorTransfer => 'Chuyển đổi màu';
	@override String get chromaSubsampling => 'Chronic Subsampling';
	@override String get chromaLocation => 'Địa điểm Chroma';
	@override String get scanType => 'Loại scan';
	@override String get interlaced => 'Xen kẽ';
	@override String get anamorphic => 'Biến dạng';
	@override String get referenceFrames => 'Quá trình tham khảo';
	@override String get dynamicRange => 'Dynamic Range Độ bền';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Dolby Vision Độ bền';
	@override String get dolbyVisionVersion => 'Dolby Vision Phiên bản';
	@override String get dolbyVisionLayers => 'Dolby Vision Dây';
	@override String get baseLayerCompatibility => 'Tùy hợp lớp cơ sở';
	@override String get avcBitstream => 'Đánh giá AVC Bitstream';
	@override String get nalLengthSize => 'Độ dài NAL';
	@override String get scalingMatrix => 'Tính năng: Custom Scaling Matrix';
	@override String get streamIdentifier => 'Tính năng Stream Identifier';
	@override String get streamIndex => 'Chỉ số Stream';
	@override String get streamId => 'Thông số Stream ID';
	@override String get language => 'Ngôn ngữ';
	@override String get languageCode => 'Mã ngôn ngữ';
	@override String get streamTitle => 'Track tiêu đề';
	@override String get channels => 'Kênh';
	@override String get sampleRate => 'Tỷ lệ mẫu';
	@override String get spatialAudio => 'âm thanh không gian';
	@override String get textBased => 'văn bản dựa';
	@override String get subtitleFormat => 'Hình thức Sidecar';
	@override String get provider => 'Nhà cung cấp';
	@override String get matchScore => 'Match Score Kết quả';
	@override String get externalDelivery => 'Có thể phục vụ riêng biệt';
	@override String get sidecarPath => 'Đường Sidecar';
	@override String get sourceStream => 'sao chép từ';
	@override String get temporary => 'Tạm thời';
	@override String get timeBase => 'Cơ sở thời gian';
	@override String get overallBitrate => 'Tổng số Bitrate';
	@override String get path => 'Đường dẫn';
	@override String get fileName => 'File tên';
	@override String get size => 'Kích cỡ';
	@override String get totalSize => 'Tổng kích thước';
	@override String get container => 'Định dạng';
	@override String get duration => 'Thời gian';
	@override String get previewThumbnails => 'Giới thiệu Thumbnails';
	@override String get previewIndex => 'Preview chỉ số';
	@override String get packetLength => 'Lượng gói';
	@override String get filePresent => 'file hiện tại';
	@override String get fileReadable => 'Có thể đọc bởi server';
	@override String get streamPath => 'Stream đường';
	@override String get optimizedForStreaming => 'Tốt nhất cho Streaming';
	@override String get has64bitOffsets => 'Độ lệch 64 bit';
	@override String get protocol => 'Giao thức';
	@override String get mediaType => 'loại phương tiện';
	@override String get sourceKind => 'Nguồn Kind';
	@override String get optimizedVersion => 'Phiên bản tối ưu';
	@override String get optimizationTarget => 'Mục tiêu tối ưu hóa';
	@override String get deletedAt => 'xóa';
	@override String get remoteSource => 'Nguồn từ xa';
	@override String get infiniteStream => 'Infinite dòng';
	@override String get directPlay => 'trực tiếp chơi';
	@override String get directStream => 'Stream trực tiếp';
	@override String get transcoding => 'Chuyển mã';
	@override String get etag => 'ETag';
	@override String get versionId => 'Phiên bản ID';
	@override String get fileId => 'file ID';
	@override String get defaultAudioTrack => 'Lời bài hát: Audio Track';
	@override String get defaultSubtitleTrack => 'Subtitle Track theo tiêu chuẩn';
	@override String get subtitlesOff => 'Tắt';
	@override String get flagDefault => 'Mặc Định';
	@override String get flagForced => 'Bắt Buộc';
	@override String get flagSelected => 'Chọn';
	@override String get flagExternal => 'Bên ngoài';
	@override String get flagHearingImpaired => 'Nghe bị hư hỏng';
	@override String get flagDub => 'Dúp';
	@override String get flagOriginal => 'nguyên bản';
	@override String get channelsMono => 'Âm Thanh Đơn Kênh';
	@override String dolbyVisionProfile({required Object profile}) => 'Hồ sơ ${profile}';
}

// Path: mediaMenu
class _Translations$mediaMenu$vi extends Translations$mediaMenu$en {
	_Translations$mediaMenu$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Mark như được xem';
	@override String get markAsUnwatched => 'Mark như Unwatched';
	@override String get removeFromContinueWatching => 'Xóa khỏi tiếp tục xem';
	@override String get viewDetails => 'Xem chi tiết';
	@override String get goToSeries => 'Đi đến series';
	@override String get shufflePlay => 'Chơi Shuffle';
	@override String get shuffleNotAvailableOffline => 'Shuffle không có sẵn offline';
	@override String get fileInfo => 'File thông tin';
	@override String get deleteEpisodeFromServer => 'xóa các tập từ server';
	@override String get deleteSeasonFromServer => 'Xóa mùa từ máy chủ';
	@override String get deleteShowFromServer => 'Xóa show từ server';
	@override String get deleteMovieFromServer => 'Xóa phim từ máy chủ';
	@override String get deleteEpisodeTitle => 'Tải về episode này?';
	@override String get deleteSeasonTitle => 'Hủy bỏ mùa này?';
	@override String get deleteShowTitle => 'Hủy bỏ chương trình này?';
	@override String get deleteMovieTitle => 'Phải chăng bạn xóa phim này?';
	@override String get deleteEpisodeConfirm => 'Xóa Tập';
	@override String get deleteSeasonConfirm => 'Chụp mùa';
	@override String get deleteShowConfirm => 'Hiển thị Delete';
	@override String get deleteMovieConfirm => 'xóa phim';
	@override String get deleteAnyway => 'xóa bất cứ';
	@override String confirmDeleteTarget({required Object title}) => 'Xóa vĩnh viễn ${title} khỏi máy chủ của bạn?';
	@override String get deleteMultipleWarning => 'Bao gồm tất cả các tập phim và tệp của chúng.';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n,
		other: 'Thao tác này xóa tất cả ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tập phim trong mục này cùng các tệp của chúng.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n,
		other: 'Mục này được lưu trong ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tệp và tất cả các tệp đó sẽ bị xóa.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n,
		other: 'Có ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tập phim khác được lưu trong cùng tệp và cũng sẽ bị xóa:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'PlezyNG không thể xác định những tệp sẽ bị xóa, nên có thể xóa nhiều hơn mục nêu trên. Hãy hủy và thử lại, hoặc vẫn xóa.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'Máy chủ không cung cấp thông tin tệp cho mục này, nên PlezyNG không thể xác định những tệp sẽ bị xóa. Có thể xóa nhiều hơn mục nêu trên.';
	@override String get mediaDeletedSuccessfully => 'Media item đã bị xóa thành công';
	@override String get mediaFailedToDelete => 'Không xóa các mục phương tiện truyền thông';
	@override String get rate => 'Đánh giá';
	@override String get playFromBeginning => 'Phát từ đầu';
	@override String get playVersion => 'Game phiên bản...';
}

// Path: rateSheet
class _Translations$rateSheet$vi extends Translations$rateSheet$en {
	_Translations$rateSheet$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Đánh giá';
	@override String get server => 'Máy chủ';
	@override String get favorite => 'Yêu thích';
	@override String get favorited => 'Ưu tiên';
	@override String get saved => 'cứu';
	@override String get notAvailable => 'Không tìm thấy trận đấu';
	@override String get noConnectedServices => 'Kết nối một dịch vụ trong Settings để đánh giá ở đó.';
}

// Path: accessibility
class _Translations$accessibility$vi extends Translations$accessibility$en {
	_Translations$accessibility$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, phim';
	@override String mediaCardShow({required Object title}) => '${title}, chương trình truyền hình';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'Đã xem';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} phần trăm xem';
	@override String get mediaCardUnwatched => 'chưa xem';
	@override String get tapToPlay => 'Nhập để chơi';
	@override String get decrease => 'Giảm';
	@override String get increase => 'tăng';
	@override String decreaseValue({required Object label}) => 'Tỷ lệ giảm ${label}';
	@override String increaseValue({required Object label}) => 'Tăng ${label}';
	@override String get hue => 'Sắc độ';
	@override String get saturation => 'Độ bão hòa';
	@override String get brightness => 'sáng';
	@override String get hexColor => 'Màu Hex';
	@override String get expandText => 'Tăng văn bản';
	@override String get collapseText => 'Tác phẩm sụp đổ';
	@override String get alphabetNavigation => 'Alphabet Navigation (liên kết  sửa đổi)';
	@override String get alphabetScrollHint => 'Vuốt lên hoặc xuống để di chuyển theo chữ cái';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Dòng ${row} của ${rowCount}, cột ${column} của ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'Dòng ${row} của ${rowCount}';
	@override String get autoScrollPlay => 'Chơi Auto-Scroll';
	@override String get autoScrollPause => 'Lời bài hát: Auto-Scroll';
	@override String get hueShort => 'H';
	@override String get saturationShort => 'S';
	@override String get valueShort => 'V';
	@override String get red => 'Đỏ';
	@override String get green => 'Xanh lá';
	@override String get blue => 'Xanh lam';
	@override String get redShort => 'R';
	@override String get greenShort => 'G';
	@override String get blueShort => 'B';
	@override String get colorModeHsv => 'HSV';
	@override String get colorModeRgb => 'RGB';
	@override String get title => 'Truy cập';
	@override String get summary => 'Text, contrast, motion và controls';
	@override String get systemHint => 'Cài đặt khả năng truy cập của thiết bị của bạn luôn được áp dụng. các tùy chọn này thêm các điều chỉnh trong suốt PlezyNG.';
	@override String get readability => 'Đọc và hiển thị';
	@override String get textSize => '- Thêm Text Size';
	@override String get preview => 'Tìm câu chuyện tiếp theo của bạn. đọc, nghe và xem theo tốc độ của riêng bạn.';
	@override String get boldText => 'Lời bài hát Bold Interface';
	@override String get highContrast => 'Contrast cao';
	@override String get highContrastHint => 'Văn bản mạnh hơn, chi tiết và chỉ số tập trung trên các bề mặt sáng hoặc tối.';
	@override String get interaction => 'động và tương tác';
	@override String get reduceMotion => 'Giảm động lực';
	@override String get reduceMotionHint => 'Dừng chuyển động của dấu chỉ tiêu điểm, hiệu ứng chuyển trang và các hiệu ứng trang trí.';
	@override String get largeTargets => 'Mục tiêu Touch lớn hơn';
	@override String get largeTargetsHint => 'Tăng diện tích các điều khiển dùng chung để dễ chạm và điều hướng bằng công nghệ hỗ trợ.';
	@override String get navigationHint => 'Dùng Tab và Shift+Tab để di chuyển giữa các điều khiển, Enter hoặc Space để kích hoạt, Escape hoặc nút Quay lại để đóng. Bạn có thể chỉnh mức thu phóng và tùy chọn đọc khi mở sách.';
	@override String get textSizeDescription => 'Tích hợp văn bản giao diện trong PlezyNG ngoài thiết lập kích thước văn bản hệ thống của thiết bị của bạn.';
	@override String get boldTextHint => 'Sử dụng trọng lượng nặng hơn cho các nhãn giao diện và tin nhắn để làm cho chúng dễ dàng phân biệt.';
}

// Path: tooltips
class _Translations$tooltips$vi extends Translations$tooltips$en {
	_Translations$tooltips$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Shuffle chơi';
	@override String get playTrailer => 'Trò chơi Trailer';
	@override String get markAsWatched => 'Mark theo dõi';
	@override String get markAsUnwatched => 'Mark như không được xem';
}

// Path: audioTracks
class _Translations$audioTracks$vi extends Translations$audioTracks$en {
	_Translations$audioTracks$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'Âm thanh Track ${n}';
}

// Path: videoControls
class _Translations$videoControls$vi extends Translations$videoControls$en {
	_Translations$videoControls$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Âm thanh';
	@override String get subtitlesLabel => 'Phụ đề';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String get letterbox => 'Bảng Letterbox';
	@override String get fillScreen => 'Full màn hình';
	@override String get stretch => 'Kéo dài';
	@override String get lockRotation => 'Lock xoay';
	@override String get unlockRotation => 'Khóa xoay';
	@override String get timerActive => 'Thời gian hoạt động';
	@override String playbackWillPauseIn({required Object duration}) => 'Playback sẽ nghỉ tại ${duration}';
	@override String get sleepTimerEndOfVideo => 'Kết thúc video hiện tại';
	@override String get sleepTimerStopAtHeader => 'dừng lại';
	@override String get sleepTimerDurationHeader => 'Thời gian';
	@override String get playbackWillPauseAtEnd => 'Playback sẽ nghỉ ngơi vào cuối video này';
	@override String get stillWatching => 'vẫn đang xem?';
	@override String pausingIn({required Object seconds}) => 'Đánh giá tại ${seconds}s';
	@override String get continueWatching => 'tiếp tục';
	@override String get autoPlayNext => 'Auto-Play tiếp theo';
	@override String get playNext => 'Phát kế tiếp';
	@override String get playButton => 'Phát';
	@override String get pauseButton => 'Tạm dừng';
	@override String get playbackPaused => 'nghỉ ngơi';
	@override String get playbackResumed => 'chơi';
	@override String get loadingVideo => 'tải video';
	@override String get showPlaybackControls => 'Hiển thị Playback Control';
	@override String get hidePlaybackControls => 'Ẩn Playback Controls';
	@override String seekBackwardButton({required Object seconds}) => 'Tìm lại ${seconds} giây';
	@override String seekForwardButton({required Object seconds}) => 'Tìm trước ${seconds} giây';
	@override String get previousButton => 'Episode trước';
	@override String get nextButton => 'Tập Kế Tiếp';
	@override String get previousChapterButton => 'Đoạn trước';
	@override String get nextChapterButton => 'Đoạn kế tiếp';
	@override String get muteButton => 'Tắt Tiếng';
	@override String get unmuteButton => 'Bật Tiếng';
	@override String get settingsButton => 'Cài đặt Playback';
	@override String get tracksButton => 'Âm thanh & Subtitles';
	@override String get chaptersButton => 'Chương 1';
	@override String get segmentLoopHelp => 'Đặt A, sau đó đặt B sau đó trong dòng thời gian.';
	@override String get setLoopStart => 'Cài đặt loop bắt đầu (A)';
	@override String get setLoopEnd => 'Thiết lập vòng tròn kết thúc (B)';
	@override String get clearSegmentLoop => 'Chi tiết Segment Loop';
	@override String get setLoopStartFirst => 'Cài đặt vòng bắt đầu (A) trước khi kết thúc (B).';
	@override String get loopEndAfterStart => 'Kết thúc vòng tròn phải là muộn hơn khởi đầu.';
	@override String get segmentLoopUnavailable => 'Segment looping không có sẵn cho playback này.';
	@override String get loopPointNotSet => 'Không đặt';
	@override String get bookmarksHelp => 'Bookmarks được lưu trên thiết bị này. chọn một để đi đến thời điểm đó.';
	@override String get bookmarksButton => 'Bookmarks Đánh giá';
	@override String get chaptersAndBookmarks => 'Chương và Bookmark';
	@override String get segmentLoop => 'phân đoạn loop';
	@override String get addBookmark => 'Thêm Bookmark';
	@override String get bookmarkName => 'Bookmark tên';
	@override String get bookmarkNameHint => 'Ví dụ: Mở cảnh';
	@override String bookmarkDefaultName({required Object n}) => 'Bookmark Đề ${n}';
	@override String get bookmarkNameRequired => 'Nhập tên cho bookmark này.';
	@override String get deleteBookmark => 'xóa bookmark';
	@override String get bookmarkLimitReached => 'Bài viết này đã có 100 bookmarks.';
	@override String get bookmarkUnavailable => 'Không thể lưu hoặc xóa sổ này.';
	@override String get bookmarkSaved => 'Bookmark được tiết kiệm';
	@override String get bookmarkDeleted => 'Bookmark bị xóa';
	@override String loopPointSet({required Object point, required Object time}) => 'Điểm Loop ${point} Set tại ${time}.';
	@override String get noChaptersOrBookmarks => 'Không có chương hoặc bảng chữ cái có sẵn.';
	@override String get versionQualityButton => 'Phiên bản & Chất lượng';
	@override String get versionColumnHeader => 'Phiên bản';
	@override String get qualityColumnHeader => 'Chất lượng';
	@override String get qualityOriginal => 'nguyên bản';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Transcoding unavailable — chơi chất lượng ban đầu';
	@override String get subtitleUnavailableFallback => 'Các tiêu đề được chọn không thể tải — tiếp tục mà không có tiêu đề';
	@override String get pipButton => 'Hình ảnh trong hình ảnh mode';
	@override String get aspectRatioButton => 'Tỷ Lệ Khung Hình';
	@override String get ambientLighting => 'Ánh sáng môi trường';
	@override String get fullscreenButton => 'Nhập Fullscreen';
	@override String get exitFullscreenButton => 'Khởi hành Fullscreen';
	@override String get alwaysOnTopButton => 'Luôn ở trên';
	@override String get rotationLockButton => 'Lock xoay';
	@override String get lockScreen => 'Màn hình Lock';
	@override String get screenLockButton => 'màn hình lock';
	@override String get timelineSlider => 'Thanh thời gian video';
	@override String get volumeSlider => 'Tỷ lệ Volume';
	@override String endsAt({required Object time}) => 'Kết thúc tại ${time}';
	@override String get pipActive => 'Chơi trong Picture-in-Picture';
	@override String get pipFailed => 'Picture-in-picture không bắt đầu';
	@override String get screenshotSaved => 'Screenshot được tiết kiệm';
	@override String get screenshotFailed => 'Không thể chụp ảnh màn hình';
	@override String zoomPercent({required Object percent}) => 'Thu phóng ${percent}%';
	@override String volumePercent({required Object percent}) => 'Âm lượng ${percent}%';
	@override late final _Translations$videoControls$pipErrors$vi pipErrors = _Translations$videoControls$pipErrors$vi._(_root);
	@override String get chapters => 'Chương 1';
	@override String get noChaptersAvailable => 'Không có chương có sẵn';
	@override String get queue => 'Quay';
	@override String get noQueueItems => 'Không có mặt hàng trong quue';
	@override String get noAudioDevicesAvailable => 'Không có thiết bị âm thanh';
	@override String get searchSubtitles => 'Tìm kiếm Subtitles';
	@override String get language => 'Ngôn ngữ';
	@override String get noSubtitlesFound => 'Không tìm thấy subtitles';
	@override String get subtitleDownloaded => 'Subtitle tải xuống';
	@override String get subtitleDownloadedNotApplied => 'Subtitle đã tải xuống, nhưng nó không thể được chọn';
	@override String get subtitleDownloadFailed => 'Không tải Subtitle';
	@override String get searchLanguages => 'Tìm kiếm ngôn ngữ...';
	@override String get skipIntro => 'Tải Skip Intro';
	@override String get skipCredits => 'Skip tín dụng';
	@override String get nextEpisode => 'Tập Kế Tiếp';
	@override String subtitleTrack({required Object n}) => 'Đường sắt ${n}';
	@override String subtitleFile({required Object name}) => 'Chủ đề: ${name}';
	@override String forcedTrack({required Object label}) => '${label} (được bắt buộc)';
	@override String get osdSubtitlesOff => 'Chủ đề: Off';
	@override String osdSubtitles({required Object track}) => 'Đánh giá: ${track}';
	@override String osdAudio({required Object track}) => 'Âm thanh: ${track}';
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} khung',
	);
	@override String get trackSelectionTitle => 'Lựa chọn đường trước khi playback';
	@override String get trackSelectionAuto => 'Tự động Selection';
	@override String get openMiniPlayer => 'Trò chơi Mini Open';
	@override String get returnToFullPlayer => 'Trở lại cầu thủ đầy đủ';
	@override String get loadSubtitleFile => 'tải file subtitle...';
	@override String get subtitleLoadFailed => 'Không tải file subtitle';
	@override String get skipAds => 'Tải Ads';
	@override String get tapToUnlock => 'Chạm để mở khóa';
	@override String get tapAgainToUnlock => 'Chạm lại để mở khóa';
}

// Path: messages
class _Translations$messages$vi extends Translations$messages$en {
	_Translations$messages$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Đánh dấu như được xem';
	@override String get markedAsUnwatched => 'Đánh dấu không được xem';
	@override String get markedAsWatchedOffline => 'Đánh dấu như đã được xem (sẽ đồng bộ khi trực tuyến)';
	@override String get markedAsUnwatchedOffline => 'Đánh dấu như không được xem (sẽ đồng bộ khi trực tuyến)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Tự động xóa: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n,
		other: 'Tự động xóa ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} xem tải xuống',
	);
	@override String get removedFromContinueWatching => 'Xóa khỏi tiếp tục xem';
	@override String errorLoading({required Object error}) => 'Lỗi: ${error}';
	@override String get searchPartialResults => 'Một số máy chủ truyền thông không thể được tìm kiếm. hiển thị kết quả có sẵn.';
	@override String get streamInterrupted => 'Stream đã bị gián đoạn. press play hoặc tìm cách rút lui.';
	@override String get liveStreamInterrupted => 'Live stream đã bị ngừng. press play to retry.';
	@override String get fileInfoNotAvailable => 'File thông tin không sẵn dùng';
	@override String get playbackAuthenticationRequired => 'Đăng nhập vào máy chủ media một lần nữa để chơi mục này.';
	@override String get playbackServerUnavailable => 'Máy chủ media không sẵn dùng, hãy thử lại sau này.';
	@override String get playbackDataInvalid => 'Máy chủ trả lại thông tin playback không có hiệu lực.';
	@override String get playbackCancelled => 'Playback đã bị hủy bỏ.';
	@override String get playbackFailed => 'Playback không thể bắt đầu.';
	@override String playbackFailedDetail({required Object error}) => 'Playback không thể khởi động: ${error}';
	@override String get audioOutputFailed => 'Kiểm tra kết nối âm thanh của TV hoặc người nhận; nếu các ứng dụng khác cũng không có âm thanh, hãy khởi động lại thiết bị.';
	@override String get mediaUnavailable => 'Nội dung này không còn có sẵn nữa.';
	@override String errorLoadingFileInfo({required Object error}) => 'Lỗi tải file info: ${error}';
	@override String get errorLoadingSeries => 'Lỗi Loading Series';
	@override String get musicNotSupported => 'Music playback chưa được hỗ trợ';
	@override String get noDescriptionAvailable => 'Không có mô tả';
	@override String get noProfilesAvailable => 'Không có hồ sơ có sẵn';
	@override String get contactAdminForProfiles => 'Liên hệ với người quản trị máy chủ của bạn để thêm hồ sơ';
	@override String get unableToDetermineLibrarySection => 'Không thể xác định phần thư viện cho mục này';
	@override String get logsCleared => 'Logs Đánh giá';
	@override String get logsCopied => 'Lời bài hát: Copied to clipboard';
	@override String get noLogsAvailable => 'Không có logs có sẵn';
	@override String libraryScanning({required Object title}) => 'Đánh giá “${title}...”';
	@override String libraryScanStarted({required Object title}) => 'Thư viện quét bắt đầu cho "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Không thể quét thư viện: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Tải về các thông tin mới cho "${title}"';
	@override String metadataRefreshStarted({required Object title}) => 'Metadata update bắt đầu cho "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Không cập nhật dữ liệu siêu dữ liệu: ${error}';
	@override String get logoutConfirm => 'Bạn có chắc chắn bạn muốn đăng nhập không?';
	@override String get noSeasonsFound => 'Không tìm thấy mùa';
	@override String get seasonsLoadFailed => 'Không thể tải mùa';
	@override String get noEpisodesFound => 'Không có sự kiện nào được tìm thấy trong mùa giải đầu tiên';
	@override String get noEpisodesFoundGeneral => 'Không tìm thấy sự kiện';
	@override String get episodesLoadFailed => 'Không thể tải các sự kiện';
	@override String get noResultsFound => 'Không tìm thấy kết quả nào.';
	@override String sleepTimerSet({required Object label}) => 'Thời gian ngủ được thiết lập cho ${label}';
	@override String get noItemsAvailable => 'Không có mặt hàng có sẵn';
	@override String get failedToCreatePlayQueueNoItems => 'Không thể tạo ra một trò chơi cue — không có mục';
	@override String failedPlayback({required Object action, required Object error}) => 'thất bại đến ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'Chuyển sang Player compatible...';
	@override String get serverLimitTitle => 'Playback thất bại';
	@override String get serverLimitBody => 'Lỗi máy chủ (HTTP 500). Một giới hạn băng thông / mã hóa có thể đã từ chối phiên này.';
	@override String get mediaUnreadableTitle => 'file không sẵn dùng';
	@override String get mediaUnreadableBody => 'Máy chủ đã tìm thấy mục này nhưng không thể đọc tệp của nó (HTTP 404). tệp có thể đã di chuyển, xóa, hoặc lưu trữ của nó là không dây.';
	@override String get serverBusyTitle => 'Stream không sẵn dùng';
	@override String get serverBusyBody => 'Máy chủ vẫn từ chối truyền tải tệp này (HTTP 503). nó có thể khởi động lại, bận rộn, hoặc lưu trữ tệp có thể offline. thử lại một lần nữa - nếu nó tiếp tục xảy ra, yêu cầu chủ máy chủ để kiểm tra máy chủ và lưu trữ tệp.';
	@override String get playbackNotAllowedTitle => 'Playback không được phép';
	@override String get playbackNotAllowedBody => 'Máy chủ từ chối truyền tải mục này (HTTP 403). Tài khoản của bạn có thể không được phép chơi nó, hoặc máy chủ có thể chỉ cho phép phát lại trên mạng địa phương của nó.';
	@override String get logsUploaded => 'Logs upload';
	@override String get logsUploadFailed => 'Không thể tải lên logs';
	@override String get logId => 'Mã nhật ký';
	@override String get burnedSubtitlesUseMenu => 'Các tiêu đề được đốt trong dòng này. thay đổi chúng từ menu tiêu đề.';
	@override String get noVideoUrl => 'Không có URL video';
	@override String get playbackNoMediaSources => 'Máy chủ không trả về các nguồn truyền thông chơi game';
	@override String get playbackDataNotPrepared => 'Playback bắt đầu trước khi dữ liệu của nó đã sẵn sàng';
	@override String get streamSelectionUnavailable => 'Stream selection không sẵn dùng cho nguồn này';
	@override String get streamSelectionFailed => 'Không thể áp dụng các dòng được chọn';
	@override String get trackSelectionNotRemembered => 'Lựa chọn track này chỉ áp dụng cho playback hiện tại.';
	@override String get serverUnavailableForProfile => 'Không có máy chủ có sẵn cho hồ sơ hoạt động';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$vi extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get previewSample => 'The Fast Brown Fox nhảy qua con chó lười biếng';
	@override String get text => 'Văn bản';
	@override String get border => 'biên giới';
	@override String get background => 'nền';
	@override String get fontSize => 'font kích thước';
	@override String get textColor => 'Màu văn bản';
	@override String get borderSize => 'biên giới kích thước';
	@override String get borderColor => 'Màu biên giới';
	@override String get backgroundOpacity => 'Hình nền Opacity';
	@override String get backgroundColor => 'Màu nền';
	@override String get position => 'vị trí';
	@override String get assOverride => 'ASS Đánh giá';
	@override String get overrideScale => 'Tỷ lệ';
	@override String get overrideForce => 'lực lượng';
	@override String get overrideStrip => 'xóa styling';
	@override String get positionTop => 'Top';
	@override String get positionBottom => 'dưới';
	@override String get useMargins => 'Sử dụng margins';
	@override String get useMarginsDescription => 'Cho phép các tiêu đề văn bản trong không gian bên ngoài video. tiêu đề kiểu có thể giữ vị trí ban đầu của họ.';
	@override String get anchorToScreen => 'Anchor to màn hình';
	@override String get anchorToScreenDescription => 'Hiển thị các tiêu đề văn bản trong thanh đen dưới màn hình video';
	@override String get bold => 'In đậm';
	@override String get italic => 'Ý';
	@override String get renderResolution => 'Quyết định Render';
	@override String get renderResolutionScreen => 'Độ Phân Giải Màn Hình';
	@override String get renderResolutionVideo => 'Độ phân giải video';
	@override String get fontSizeDescription => 'Thiết lập kích thước văn bản subtitle trên thiết bị này.';
	@override String get textColorDescription => 'Chọn màu được sử dụng cho subtitle text.';
	@override String get borderSizeDescription => 'Đặt độ dày của outline xung quanh văn bản subtitle.';
	@override String get borderColorDescription => 'Chọn màu được sử dụng cho dòng outline subtitle.';
	@override String get backgroundColorDescription => 'Chọn màu đằng sau subtitle text.';
	@override String get backgroundOpacityDescription => 'Thiết lập độ minh bạch của nền chủ đề là: 0% rõ ràng và 100% vững chắc.';
	@override String get positionDescription => 'Di chuyển các tiêu đề theo chiều dọc. 0% là trên cùng của video và 100% là dưới cùng.';
	@override String get assOverrideDescription => 'Chọn xem người chơi có theo dõi, điều chỉnh, thay thế hoặc loại bỏ kiểu dáng được tích hợp trong các tiêu đề ASS.';
	@override late final _Translations$subtitlingStyling$assOverrideOptions$vi assOverrideOptions = _Translations$subtitlingStyling$assOverrideOptions$vi._(_root);
	@override String get renderResolutionDescription => 'Chọn độ phân giải được sử dụng để rasterize hình ảnh và ASS subtitles. Lượng Android thấp hơn có thể làm giảm công việc rendering nhưng trông mềm hơn.';
	@override late final _Translations$subtitlingStyling$renderResolutionOptions$vi renderResolutionOptions = _Translations$subtitlingStyling$renderResolutionOptions$vi._(_root);
	@override String get boldDescription => 'Vẽ văn bản subtitle trong một trọng lượng nặng hơn.';
	@override String get italicDescription => 'Tạo subtitle văn bản trong tiếng Ý.';
}

// Path: mpvConfig
class _Translations$mpvConfig$vi extends Translations$mpvConfig$en {
	_Translations$mpvConfig$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Cài đặt Video Player Advanced';
	@override String get presets => 'Lời bài hát';
	@override String get noPresets => 'Không có tiền thưởng';
	@override String get saveAsPreset => 'Tiết kiệm như Preset';
	@override String get presetName => 'Preset tên';
	@override String get presetNameHint => 'Nhập một tên cho bài viết này';
	@override String get loadPreset => 'tải';
	@override String get deletePreset => 'Xóa';
	@override String get presetSaved => 'Preset được cứu';
	@override String get presetLoaded => 'Preset tải';
	@override String get presetDeleted => 'Preset xóa';
	@override String get confirmDeletePreset => 'Bạn có chắc chắn rằng bạn muốn xóa tiền này không?';
	@override String get configPlaceholder => 'gpu-api=vulkan hwdec=auto # bình luận';
	@override String get lineHint => 'option=value';
	@override String get addLine => 'thêm dòng';
	@override String get removeLine => 'xóa dòng';
	@override String get embeddedVoHint => 'vo, gpu-context và gpu-api bị bỏ qua trên Linux: video tích hợp luôn được chuyển qua vo=libmpv trên máy tính video, và gpu-next (màu máy tính như ArtCNN cần) không thể chạy tích hợp.';
}

// Path: dialog
class _Translations$dialog$vi extends Translations$dialog$en {
	_Translations$dialog$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'xác nhận hành động';
}

// Path: profiles
class _Translations$profiles$vi extends Translations$profiles$en {
	_Translations$profiles$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Thêm PlezyNG hồ sơ';
	@override String get switchingProfile => 'Thay đổi profile...';
	@override String get deleteThisProfileTitle => 'Xóa hồ sơ này?';
	@override String deleteThisProfileMessage({required Object displayName}) => 'Xóa ${displayName}. kết nối không bị ảnh hưởng.';
	@override String get active => 'hoạt động';
	@override String get manage => 'quản lý';
	@override String get delete => 'Xóa';
	@override String get signOut => 'Đăng xuất';
	@override String get signOutPlexTitle => 'Đăng ký từ Plex?';
	@override String signOutPlexMessage({required Object displayName}) => 'Xóa ${displayName} và tất cả Plex Người dùng nhà? đăng ký lại bất kỳ lúc nào.';
	@override String get signOutPlexDeleteDownloads => 'Tải xuống cũng';
	@override String get signOutPlexDeleteDownloadsDescription => 'Nếu không, họ sẽ ở lại trên thiết bị này và trở lại khi bạn đăng nhập lại vào tài khoản này.';
	@override String get signedOutPlex => 'Đã đăng ký từ Plex.';
	@override String get signOutFailed => 'Đăng ký thất bại';
	@override String get sectionTitle => 'Hồ sơ';
	@override String get summarySingle => 'Thêm hồ sơ để kết hợp người dùng được quản lý và danh tính địa phương';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} hồ sơ · hoạt động: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} hồ sơ';
	@override String get removeConnectionTitle => 'Xóa kết nối?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'Xóa truy cập ${displayName} đến ${connectionLabel}. các hồ sơ khác giữ nó.';
	@override String get deleteProfileTitle => 'xóa hồ sơ?';
	@override String deleteProfileMessage({required Object displayName}) => 'Xóa ${displayName} và các kết nối của nó. máy chủ vẫn có sẵn.';
	@override String get profileNameLabel => 'Profile tên';
	@override String get pinProtectionLabel => 'PIN bảo vệ';
	@override String get copyAutomationLink => 'Bản sao Android tự động hóa liên kết';
	@override String get copyAutomationLinkDescription => 'Chọn hồ sơ này từ mục đích hoặc tự động hóa Android.Các kiểm tra PIN hồ sơ vẫn áp dụng.';
	@override String get automationLinkCopied => 'Profile tự động hóa link sao chép.';
	@override String get pinManagedByPlex => 'PIN được quản lý bởi Plex. Edit on plex.tv.';
	@override String get noPinSetEditOnPlex => 'Không thiết lập PIN. Để yêu cầu một, chỉnh sửa người dùng nhà trên plex.tv.';
	@override String get setPin => 'Thiết lập PIN';
	@override String get setPinTitle => 'Thiết lập PIN';
	@override String get confirmPinTitle => 'xác nhận PIN';
	@override String get pinSet => 'PIN thiết lập';
	@override String get changePin => 'Thay đổi';
	@override String get removePin => 'Gỡ bỏ';
	@override String get connectionsLabel => 'Liên kết';
	@override String get add => 'Thêm';
	@override String get deleteProfileButton => 'xóa profile';
	@override String get noConnectionsHint => 'Không có kết nối — thêm một để sử dụng hồ sơ này.';
	@override String get noConnections => 'Không liên kết';
	@override String get plexHomeAccount => 'Plex Tài khoản nhà';
	@override String plexAccountChip({required Object account}) => 'Plex Tài khoản: ${account}';
	@override String plexAccountUserChip({required Object user, required Object account}) => '${user} qua ${account}';
	@override String get connectionDefault => 'Mặc Định';
	@override String connectionAs({required Object displayName}) => 'Số lượng: ${displayName}';
	@override String get makeDefault => 'làm default';
	@override String get removeConnection => 'Gỡ bỏ';
	@override String get profileRenamed => 'Hồ sơ đổi tên';
	@override String borrowAddTo({required Object displayName}) => 'Thêm vào ${displayName}';
	@override String get borrowExplain => 'Mượn kết nối của hồ sơ khác. hồ sơ được bảo vệ bằng PIN đòi hỏi một PIN.';
	@override String get borrowEmpty => 'Chưa có gì để vay mượn.';
	@override String get borrowEmptySubtitle => 'Kết nối Plex, Jellyfin, hoặc Emby với hồ sơ khác đầu tiên.';
	@override String get borrowLoadFailed => 'Các kết nối có sẵn không thể được tải lên. thử lại.';
	@override String borrowFromProfile({required Object displayName}) => 'Từ ${displayName}';
	@override String get borrowConnectionBorrowed => 'Kết nối vay mượn';
	@override String get borrowFailed => 'Không có kết nối vay.';
	@override String get incorrectPin => 'PIN không chính xác';
	@override String get incorrectPinTryAgain => 'PIN không chính xác, xin vui lòng thử lại.';
	@override String get sourceProfileMissingParentAccount => 'Tài khoản nguồn đang thiếu tài khoản của cha mẹ.';
	@override String get failedToLoadHomeUsers => 'Không thể tải lên người dùng nhà Plex của bạn. kiểm tra kết nối của bạn và thử lại.';
	@override String get failedToVerifyPin => 'Không thể xác minh PIN';
	@override String get newProfile => 'Hồ sơ mới';
	@override String get profileNameHint => 'Ví dụ: khách, trẻ em, phòng gia đình';
	@override String get pinProtectionOptional => 'Bảo vệ PIN (tùy chọn)';
	@override String get pinExplain => '4 số PIN cần thiết để chuyển đổi hồ sơ.';
	@override String get continueButton => 'tiếp tục';
	@override String get pinsDontMatch => 'PIN không phù hợp';
	@override String get tokenIdentityMismatch => 'Tóc hồ sơ Plex được giải quyết đến một máy chủ bất ngờ';
	@override String get settingsLocked => 'Cài đặt được khóa cho hồ sơ này.';
	@override String get unlockSettings => 'Khóa cài đặt';
	@override String get showExploreForProfile => 'Show Explore cho profile này';
	@override String get showExploreForProfileDescription => 'Tắt để loại bỏ Explore khỏi trình duyệt hồ sơ này.';
}

// Path: connections
class _Translations$connections$vi extends Translations$connections$en {
	_Translations$connections$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Liên kết';
	@override String get addConnection => 'thêm liên kết';
	@override String get addConnectionSubtitleNoProfile => 'Đăng nhập với Plex hoặc kết nối với một máy chủ Jellyfin hoặc Emby';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Thêm vào ${displayName}: Plex, Jellyfin, Emby, hoặc kết nối hồ sơ khác';
	@override String sessionExpiredOne({required Object name}) => 'Kết thúc phiên tại ${name}';
	@override String sessionExpiredMany({required Object count}) => 'Thời gian lưu trữ cho ${count} máy chủ';
	@override String accessDeniedOne({required Object name}) => '${name} từ chối truy cập vào tài khoản này';
	@override String accessDeniedMany({required Object count}) => '${count} máy chủ từ chối truy cập vào tài khoản này';
	@override String get signInAgain => 'Đăng ký lại';
	@override String editMediaBrowserTitle({required Object product}) => 'Edit ${product} kết nối';
	@override String editMediaBrowserIntro({required Object serverName}) => 'Thêm hoặc xóa URL cho ${serverName}. PlezyNG sẽ sử dụng URL có thể truy cập với độ chậm thấp nhất.';
}

// Path: accountPreferences
class _Translations$accountPreferences$vi extends Translations$accountPreferences$en {
	_Translations$accountPreferences$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Kế toán ưu tiên';
	@override String hubSubtitleSingle({required Object account}) => 'Audio, subtitle và thư viện tùy chọn được lưu trên ${account}';
	@override String hubSubtitleMultiple({required Object count}) => 'Audio, subtitle và thư viện tùy chọn được lưu trên ${count} tài khoản';
	@override String get pickAccount => 'Mỗi tài khoản lưu trữ sở thích của riêng mình. chọn một để chỉnh sửa.';
	@override String get storedOnAccount => 'Các tùy chọn này được lưu trữ trên tài khoản của bạn, vì vậy mỗi ứng dụng đăng ký sử dụng chúng – bao gồm PlezyNG trên các thiết bị khác của bạn.';
	@override String get noAccounts => 'Không có tài khoản để cấu hình';
	@override String get noAccountsHint => 'Đăng nhập vào Plex, hoặc kết nối với một máy chủ Jellyfin hoặc Emby, và các tùy chọn được lưu trữ trên tài khoản đó được hiển thị ở đây.';
	@override String get unavailable => 'Không thể truy cập tài khoản này';
	@override String get loadFailed => 'Không thể tải các tùy chọn này';
	@override String get noPreference => 'Không ưu tiên';
	@override String get notSet => 'Không đặt';
	@override late final _Translations$accountPreferences$groups$vi groups = _Translations$accountPreferences$groups$vi._(_root);
	@override String get preferredAudioLanguage => 'Ngôn ngữ thoại ưa thích';
	@override String get autoSelectAudio => 'Chọn âm thanh theo ngôn ngữ';
	@override String get autoSelectAudioDescription => 'Tắt giữ bất kỳ âm thanh theo dõi các tệp được đánh dấu theo mặc định.';
	@override String get preferredSubtitleLanguage => 'Ngôn ngữ phụ đề ưu tiên';
	@override String get subtitleMode => 'Chuyển Subtitles vào';
	@override late final _Translations$accountPreferences$subtitleModes$vi subtitleModes = _Translations$accountPreferences$subtitleModes$vi._(_root);
	@override String get subtitleAccessibility => 'SDH Subtitles';
	@override late final _Translations$accountPreferences$subtitleAccessibilityOptions$vi subtitleAccessibilityOptions = _Translations$accountPreferences$subtitleAccessibilityOptions$vi._(_root);
	@override String get forcedSubtitles => 'Subtitles buộc';
	@override late final _Translations$accountPreferences$forcedSubtitleOptions$vi forcedSubtitleOptions = _Translations$accountPreferences$forcedSubtitleOptions$vi._(_root);
	@override String get displayMissingEpisodes => 'Xem các chương trình thiếu';
	@override String get displayMissingEpisodesDescription => 'Danh sách các tập tin mà máy chủ biết về nhưng không có tệp cho.';
	@override String get hidePlayedInLatest => 'Ẩn các mục được xem trong Latest';
	@override String get hidePlayedInLatestDescription => 'Hãy để lại các mục bạn đã xem ra khỏi dòng cuối cùng của máy chủ.';
	@override String get displayCollectionsView => 'Hiển thị bộ sưu tập View';
	@override String get displayCollectionsViewDescription => 'Cung cấp xem bộ sưu tập trên máy chủ bên cạnh thư viện của bạn.';
	@override String get rewatchingInNextUp => 'Tiếp tục xem lại các chương trình trong Next Up';
	@override String get rewatchingInNextUpDescription => 'Một khi bạn hoàn thành một chương trình, hãy bắt đầu lại và Next Up theo dõi lại thay vì bỏ chương trình.';
	@override String get watchedIndicator => 'Các chỉ số được xem';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$vi watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$vi._(_root);
	@override String get mediaReviewsVisibility => 'Đánh giá & đánh giá';
	@override late final _Translations$accountPreferences$mediaReviewsOptions$vi mediaReviewsOptions = _Translations$accountPreferences$mediaReviewsOptions$vi._(_root);
	@override String get preferredAudioLanguageDescription => 'Thích theo dõi âm thanh trong ngôn ngữ này khi máy chủ hoặc người chơi tự động chọn một track.';
	@override String get preferredSubtitleLanguageDescription => 'Thích theo dõi subtitle trong ngôn ngữ này khi subtitles được chọn tự động.';
	@override String get subtitleAccessibilityDescription => 'Chọn xem mục SDH có được yêu cầu hay không trong quá trình tự động chọn subtitle.';
	@override String get forcedSubtitleDescription => 'Chọn xem các đường dẫn subtitle bắt buộc có được ưu tiên hay yêu cầu trong quá trình tự động chọn.';
	@override String get watchedIndicatorDescription => 'Chọn loại phương tiện nào nhận được dấu kiểm theo dõi trong giao diện máy chủ.';
	@override String get mediaReviewsVisibilityDescription => 'Chọn loại khán giả và đánh giá quan trọng mà máy chủ hiển thị trên các trang truyền thông.';
	@override String get subtitleModeDescription => 'Chọn khi subtitles tự động bật cho tài khoản máy chủ này.';
	@override String get hubDescription => 'Những tùy chọn này được lưu trữ trên tài khoản máy chủ phương tiện của bạn và có thể áp dụng cho các khách hàng khác.';
}

// Path: discover
class _Translations$discover$vi extends Translations$discover$en {
	_Translations$discover$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Khám phá';
	@override String get noContentAvailable => 'Không có nội dung có sẵn';
	@override String get addMediaToLibraries => 'Thêm một số phương tiện truyền thông vào thư viện của bạn';
	@override String get continueWatching => 'Tiếp tục xem';
	@override String continueWatchingIn({required Object library}) => 'Tiếp tục xem tại ${library}';
	@override String get nextUp => 'Tiếp Theo';
	@override String nextUpIn({required Object library}) => 'Tiếp theo lên trong ${library}';
	@override String get recentlyAdded => 'Thêm Gần Đây';
	@override String recentlyAddedIn({required Object library}) => 'Gần đây Thêm vào ${library}';
	@override String latestAlbumsIn({required Object library}) => 'Album mới nhất trong ${library}';
	@override String recentlyPlayedIn({required Object library}) => 'Chơi gần đây tại ${library}';
	@override String mostPlayedIn({required Object library}) => 'Hầu hết được chơi trong ${library}';
	@override String playEpisode({required Object season, required Object episode}) => 'Mùa ${season} Tập ${episode}';
	@override String get overview => 'Tổng quan';
	@override String get cast => 'Diễn viên';
	@override late final _Translations$discover$findNext$vi findNext = _Translations$discover$findNext$vi._(_root);
	@override String get extras => 'Trailers và Extras';
	@override String get studio => 'Hãng phim';
	@override String get rating => 'Đánh giá';
	@override String get director => 'Đạo Diễn';
	@override String get directors => 'Đạo Diễn';
	@override String get movie => 'Phim';
	@override String get tvShow => 'chương trình TV';
	@override String minutesLeft({required Object minutes}) => '${minutes} phút left';
	@override String get moreLikeThis => 'Nội Dung Tương Tự';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} danh sách',
	);
	@override late final _Translations$discover$person$vi person = _Translations$discover$person$vi._(_root);
}

// Path: errors
class _Translations$errors$vi extends Translations$errors$en {
	_Translations$errors$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Tìm kiếm thất bại: ${error}';
	@override String get searchUnavailable => 'Tìm kiếm không thể truy cập bất kỳ máy chủ phương tiện nào.';
	@override String connectionTimeout({required Object context}) => 'Thời gian kết nối trong khi tải ${context}';
	@override String get connectionFailed => 'Không thể kết nối với Media Server';
	@override String unableToLoad({required Object context}) => 'Không thể tải ${context}. xin vui lòng thử lại.';
	@override String get noClientAvailable => 'Không có khách hàng';
	@override String get pleaseEnterToken => 'Vui lòng nhập token';
	@override String get invalidToken => 'Mã xác thực không hợp lệ';
	@override String failedToVerifyToken({required Object error}) => 'Không xác minh token: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Không thể chuyển sang ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'Không xóa ${displayName}';
	@override String get failedToRate => 'Không thể update rating';
	@override String get reasonTimedOut => 'Kết nối đã tạm thời';
	@override String get reasonUnreachable => 'Server không thể truy cập được';
	@override String get reasonRefused => 'server từ chối yêu cầu';
	@override String get reasonNotFound => 'mục không còn trên máy chủ';
	@override String get reasonServerError => 'Server nhận được lỗi';
	@override String get reasonCancelled => 'Yêu cầu đã bị hủy';
	@override String get reasonUnexpected => 'Một sai lầm bất ngờ xảy ra';
}

// Path: libraries
class _Translations$libraries$vi extends Translations$libraries$en {
	_Translations$libraries$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => 'Chơi một bộ phim ngẫu nhiên';
	@override String get randomPickFailed => 'Không thể chọn một bộ phim ngẫu nhiên từ thư viện này.';
	@override String get title => 'Thư viện';
	@override String get fallbackTitle => 'Thư viện';
	@override String get scanLibraryFiles => 'Scan thư viện file';
	@override String get scanLibrary => 'Quét thư viện';
	@override String get analyze => 'phân tích';
	@override String get analyzeLibrary => 'Phân tích Thư viện';
	@override String get refreshMetadata => 'Làm mới dữ liệu mô tả';
	@override String get emptyTrash => 'Dọn sạch thùng rác';
	@override String emptyingTrash({required Object title}) => 'Khả năng làm sạch bụi bẩn cho "${title}..."';
	@override String trashEmptied({required Object title}) => 'Trash emptied cho "${title}"';
	@override String failedToEmptyTrash({required Object error}) => 'Không làm trống rỗng: ${error}';
	@override String analyzing({required Object title}) => 'Phân tích “${title}...”';
	@override String analysisStarted({required Object title}) => 'Phân tích bắt đầu cho "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Không phân tích thư viện: ${error}';
	@override String get noLibrariesFound => 'Không tìm thấy thư viện';
	@override String get allLibrariesHidden => 'Tất cả các thư viện được ẩn';
	@override String hiddenLibrariesCount({required Object count}) => 'Thư viện ẩn (${count})';
	@override String get thisLibraryIsEmpty => 'Thư viện này trống';
	@override String get noItemsMatchFilters => 'Không có mục phù hợp với bộ lọc hoạt động';
	@override String get resetFilters => 'Đặt lại bộ lọc';
	@override String get all => 'Tất cả';
	@override String get clearAll => 'Tất cả rõ ràng';
	@override String scanLibraryConfirm({required Object title}) => 'Bạn có chắc chắn bạn muốn quét "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Bạn có chắc chắn bạn muốn phân tích "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => 'Bạn có chắc chắn rằng bạn muốn cập nhật dữ liệu metadata cho "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Bạn có chắc chắn rằng bạn muốn làm trống rỗng cho "${title}"?';
	@override String get manageLibraries => 'Quản lý thư viện';
	@override String get sort => 'Sắp xếp';
	@override String get sortBy => 'Sắp xếp theo';
	@override String get filters => 'Bộ lọc';
	@override String get confirmActionMessage => 'Bạn có chắc chắn bạn muốn thực hiện hành động này không?';
	@override String get showLibrary => 'Hiển thị thư viện';
	@override String get hideLibrary => 'ẩn thư viện';
	@override String get libraryOptions => 'Tùy chọn thư viện';
	@override String get content => 'Thư viện Content';
	@override String get selectLibrary => 'Chọn thư viện';
	@override String filtersWithCount({required Object count}) => 'Bộ lọc (${count})';
	@override String get noRecommendations => 'Không có khuyến nghị có sẵn';
	@override String get noCollections => 'Không có tập hợp trong thư viện này';
	@override String get noFoldersFound => 'Không tìm thấy thư mục';
	@override String get folders => 'Thư Mục';
	@override late final _Translations$libraries$tabs$vi tabs = _Translations$libraries$tabs$vi._(_root);
	@override late final _Translations$libraries$groupings$vi groupings = _Translations$libraries$groupings$vi._(_root);
	@override late final _Translations$libraries$filterCategories$vi filterCategories = _Translations$libraries$filterCategories$vi._(_root);
	@override late final _Translations$libraries$sortLabels$vi sortLabels = _Translations$libraries$sortLabels$vi._(_root);
	@override late final _Translations$libraries$advancedFilters$vi advancedFilters = _Translations$libraries$advancedFilters$vi._(_root);
	@override late final _Translations$libraries$selection$vi selection = _Translations$libraries$selection$vi._(_root);
}

// Path: about
class _Translations$about$vi extends Translations$about$en {
	_Translations$about$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Về';
	@override String get openSourceLicenses => 'Giấy phép nguồn mở';
	@override String versionLabel({required Object version}) => 'Phiên bản ${version}';
	@override String get appDescription => 'Một khách hàng đẹp Plex, Jellyfin, và Emby cho Flutter';
	@override String get viewLicensesDescription => 'Xem giấy phép của các thư viện bên thứ ba';
	@override String get privacyPolicy => 'Chính sách Privacy';
}

// Path: serverSelection
class _Translations$serverSelection$vi extends Translations$serverSelection$en {
	_Translations$serverSelection$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Không tìm thấy máy chủ cho ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Không tải máy chủ: ${error}';
	@override String get noValidServers => 'Không tìm thấy máy chủ có sẵn trên tài khoản này';
}

// Path: hubDetail
class _Translations$hubDetail$vi extends Translations$hubDetail$en {
	_Translations$hubDetail$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tiêu đề';
	@override String get releaseYear => 'Giải phóng năm';
	@override String get dateAdded => 'Ngày thêm';
	@override String get rating => 'Đánh giá';
	@override String get noItemsFound => 'Không tìm thấy các mục';
}

// Path: logs
class _Translations$logs$vi extends Translations$logs$en {
	_Translations$logs$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Logs rõ ràng';
	@override String get copyLogs => 'Bản sao Logs';
	@override String get uploadLogs => 'tải logs';
	@override String get saveLogs => 'Save Logs to File - Lưu Logs đến File';
	@override String logsSaved({required Object path}) => 'Đăng ký được lưu đến ${path}';
	@override String get saveLogsFailed => 'Không thể lưu file log.';
}

// Path: startup
class _Translations$startup$vi extends Translations$startup$en {
	_Translations$startup$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'PlezyNG không thể bắt đầu';
	@override String get failedBody => 'Một cái gì đó đã sai trong quá trình khởi động. chi tiết bên dưới xác định những gì đã thất bại.';
	@override String get failedBodyRepairable => 'Tệp cài đặt đã lưu của PlezyNG bị hỏng và phải được tạo lại trước khi ứng dụng có thể khởi động. Thử lại sẽ không giúp ích — hãy chọn sửa bộ nhớ.';
	@override String get phaseLabel => 'Bước bước';
	@override String get showDetails => 'Hiển thị chi tiết';
	@override String get hideDetails => 'Ẩn chi tiết';
	@override String get copyDetails => 'Copy chi tiết';
	@override String get detailsCopied => 'Các chi tiết được sao chép vào clipboard';
	@override String get uploadDetails => 'tải chi tiết';
	@override String get repairStorage => 'sửa lưu trữ';
	@override String get repairTitle => 'sửa lại dữ liệu được lưu trữ?';
	@override String get repairBodyCommon => 'Tệp cài đặt của PlezyNG bị hư hỏng và không thể đọc được. sửa chữa tái cài đặt mỗi cài đặt theo mặc định.';
	@override String get repairBodyOneCredential => 'Một đăng nhập được lưu được bị hư hỏng và không thể đọc được. sửa chữa loại bỏ chỉ một; các cài đặt khác của bạn được để lại một mình.';
	@override String get repairBodySignInsKept => 'Trạng thái đăng nhập vào các máy chủ và hồ sơ của bạn sẽ được giữ lại nếu quá trình khôi phục diễn ra bình thường.';
	@override String get repairBodySignInsLost => 'Không thể khôi phục khóa bảo vệ thông tin đăng nhập đã lưu từ tệp này. Bạn sẽ phải đăng nhập lại vào từng máy chủ và hồ sơ. Không có gì trên máy chủ nội dung bị ảnh hưởng.';
	@override String get repairBodySessionsUncertain => 'Trackers (MAL, AniList, Simkl, Trakt) và Seerr được lưu trữ riêng biệt và có thể hay không tồn tại. PlezyNG sẽ cho bạn biết chính xác những gì nó giữ.';
	@override String get repairConfirm => 'sửa chữa';
	@override String get repairSucceeded => 'lưu trữ sửa chữa';
	@override String get repairNeedsRestart => 'Lưu trữ được sửa chữa - cần khởi động lại';
	@override String get restartRequiredBody => 'Dữ liệu của bạn đã được sửa, nhưng cần khởi động lại PlezyNG để sử dụng. Hãy đóng PlezyNG rồi mở lại.';
	@override String get quitPlezy => 'Đánh giá PlezyNG';
	@override String get repairFailed => 'sửa chữa thất bại';
	@override String get repairKeptSignIns => 'Bạn vẫn đang đăng nhập vào các máy chủ và hồ sơ của mình.';
	@override String get repairLostSignIns => 'Không thể khôi phục khóa bảo vệ thông tin đăng nhập đã lưu. Bạn sẽ phải đăng nhập lại vào từng máy chủ và hồ sơ.';
	@override String get repairLostSessions => 'Ít nhất một tracker hoặc kết nối Seerr đã bị mất và phải được nối lại.';
	@override String get backupTitle => 'Một bản sao của file bị hư hỏng đã được giữ lại';
	@override String get backupWarning => 'Bản sao này chứa thông tin đăng nhập của bạn. Không tải lên hoặc chia sẻ.';
	@override String get deleteBackup => 'xóa copy';
	@override String get backupDeleted => 'Bản sao bị xóa';
	@override String get previousFailureTitle => 'PlezyNG không bắt đầu lần cuối';
}

// Path: licenses
class _Translations$licenses$vi extends Translations$licenses$en {
	_Translations$licenses$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Các gói liên quan';
	@override String get license => 'Giấy phép';
	@override String licenseNumber({required Object number}) => 'Giấy phép ${number}';
	@override String licensesCount({required Object count}) => '${count} giấy phép';
}

// Path: navigation
class _Translations$navigation$vi extends Translations$navigation$en {
	_Translations$navigation$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Thư viện';
	@override String get downloads => 'Nội dung tải xuống';
	@override String get liveTv => 'Truyền hình trực tiếp';
	@override String get explore => 'Khám phá';
}

// Path: explore
class _Translations$explore$vi extends Translations$explore$en {
	_Translations$explore$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override late final _Translations$explore$mdblistShelves$vi mdblistShelves = _Translations$explore$mdblistShelves$vi._(_root);
	@override String get title => 'Khám phá';
	@override String get selectSource => 'Chọn nguồn';
	@override late final _Translations$explore$rows$vi rows = _Translations$explore$rows$vi._(_root);
	@override late final _Translations$explore$status$vi status = _Translations$explore$status$vi._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Phản ứng',
	);
	@override String get cast => 'Diễn viên';
	@override String get characters => 'nhân vật';
	@override String get addToWatchlist => 'Thêm vào Watchlist';
	@override String get removeFromWatchlist => 'Xóa khỏi Watchlist';
	@override String get addedToWatchlist => 'Thêm vào watchlist';
	@override String get removedFromWatchlist => 'Xóa khỏi watchlist';
	@override String get watchlistUpdateFailed => 'Không thể update watchlist';
	@override String get watchlistNoMatch => 'Không thể phù hợp với mục này với danh sách xem';
	@override String get notInLibrary => 'Không phải trong thư viện';
	@override String get inTheseLibraries => 'Trong các thư viện này';
	@override String get checkingLibrary => 'Kiểm tra thư viện của bạn...';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n,
		other: 'Không thể kiểm tra ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} máy chủ',
	);
	@override String get emptyTitle => 'Chưa có gì ở đây';
	@override String emptyMessage({required Object source}) => 'Các dòng từ ${source} sẽ xuất hiện ở đây một khi họ có nội dung.';
	@override String searchHint({required Object source}) => 'Tìm kiếm ${source}';
	@override String searchEmpty({required Object query}) => 'Không có kết quả cho "${query}"';
	@override String searchPrompt({required Object source}) => 'Tìm kiếm các bộ phim và chương trình trên ${source}.';
	@override String get searchFailed => 'Tìm kiếm thất bại. kiểm tra kết nối của bạn và thử lại.';
	@override late final _Translations$explore$badge$vi badge = _Translations$explore$badge$vi._(_root);
	@override late final _Translations$explore$stats$vi stats = _Translations$explore$stats$vi._(_root);
	@override late final _Translations$explore$season$vi season = _Translations$explore$season$vi._(_root);
	@override late final _Translations$explore$format$vi format = _Translations$explore$format$vi._(_root);
	@override late final _Translations$explore$sourceMaterial$vi sourceMaterial = _Translations$explore$sourceMaterial$vi._(_root);
	@override late final _Translations$explore$creditRole$vi creditRole = _Translations$explore$creditRole$vi._(_root);
	@override late final _Translations$explore$relation$vi relation = _Translations$explore$relation$vi._(_root);
	@override String broadcast({required Object day, required Object time}) => 'Airs ${day} tại ${time}';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => 'Airs ${day} tại ${time} ${timezone}';
	@override late final _Translations$explore$detail$vi detail = _Translations$explore$detail$vi._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} kết quả',
	);
}

// Path: liveTv
class _Translations$liveTv$vi extends Translations$liveTv$en {
	_Translations$liveTv$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Truyền hình trực tiếp';
	@override String get guide => 'Lịch phát sóng';
	@override String get noChannels => 'Không có kênh';
	@override String get noDvr => 'Không có DVR được cấu hình trên bất kỳ máy chủ nào';
	@override String get serverUnavailable => 'Live TV server không có sẵn.';
	@override String get serverNotConnected => 'Máy chủ TV trực tiếp không được kết nối.';
	@override String get noPrograms => 'Không có dữ liệu chương trình';
	@override String get liveStreamFailed => 'Live Stream thất bại';
	@override String get unknownProgram => 'Chương trình chưa biết';
	@override String get timelineLiveProgram => 'Chương trình trực tiếp (playback có thể nằm ngoài chương trình này)';
	@override String get timelineBuffer => 'Thời gian buffer';
	@override String get timelineUnavailable => 'Thời gian không sẵn dùng';
	@override String get timelineEstimated => 'Đánh giá playback';
	@override String get timelinePending => 'Tìm kiếm';
	@override String get timelineStale => 'Lập trình có thể bị lỗi thời';
	@override String get unknownHub => 'Không rõ';
	@override String get unknownError => 'sai lầm chưa biết';
	@override String channelNumber({required Object number}) => 'kênh ${number}';
	@override String get unknownChannel => 'kênh chưa biết';
	@override String get live => 'Trực tiếp';
	@override String get premiereBadge => 'Mới';
	@override String get reloadGuide => 'Hướng dẫn tải về';
	@override String get searchGuide => 'Hướng dẫn tìm kiếm';
	@override String get searchHint => 'Các kênh tìm kiếm & chương trình';
	@override String searchNoResults({required Object query}) => 'Không có trận đấu cho "${query}"';
	@override String get channelsSection => 'Kênh';
	@override String get programsSection => 'Chương Trình';
	@override String get now => 'Bây giờ';
	@override String get today => 'Hôm nay';
	@override String get tomorrow => 'Ngày mai';
	@override String get midnight => 'nửa đêm';
	@override String get overnight => 'buổi tối';
	@override String get morning => 'buổi sáng';
	@override String get daytime => 'Thời gian';
	@override String get evening => 'Đêm';
	@override String get lateNight => 'đêm muộn';
	@override String get whatsOn => 'cái gì trên';
	@override String get watchChannel => 'Xem kênh';
	@override String get favorites => 'Yêu Thích';
	@override String get reorderFavorites => 'Lời bài hát Favorite';
	@override String get noFavoriteChannels => 'Không có kênh yêu thích';
	@override String get noFavoriteChannelsHint => 'Hiển thị tất cả các kênh, sau đó nhấn dài một kênh để thêm nó vào yêu thích của bạn.';
	@override String get showAllChannels => 'Hiển thị tất cả các kênh';
	@override String get favoritesLoadFailed => 'Không thể tải các yêu thích. kiểm tra kết nối của bạn và thử lại.';
	@override String get favoritesUpdateFailed => 'Không thể cập nhật yêu thích. kiểm tra kết nối của bạn và thử lại.';
	@override String get joinSession => 'Tham gia phiên trong tiến bộ';
	@override String watchFromStart({required Object minutes}) => 'Xem từ đầu (${minutes} phút trước)';
	@override String get watchLive => 'Xem Live';
	@override String get goToLive => 'đi sống';
	@override String get record => 'Ghi lại';
	@override String get recordEpisode => 'kỷ lục episode';
	@override String get recordSeries => 'Ghi lại loạt phim';
	@override String get recordOptions => 'Lựa chọn Record';
	@override String get saveTo => 'Lưu vào';
	@override String get recordings => 'Bản ghi';
	@override String get scheduledRecordings => 'Kế hoạch';
	@override String get recordingRules => 'Quy tắc ghi âm';
	@override String get noScheduledRecordings => 'Không có gì được lên kế hoạch để ghi lại';
	@override String get manageRecording => 'Quản lý ghi lại';
	@override String get cancelRecording => 'Hủy ghi lại';
	@override String get cancelRecordingTitle => 'Hủy bỏ bản ghi này?';
	@override String cancelRecordingMessage({required Object title}) => '${title} sẽ không còn được ghi lại.';
	@override String get deleteRule => 'xóa quy tắc';
	@override String get deleteRuleTitle => 'Xóa quy tắc ghi âm?';
	@override String deleteRuleMessage({required Object title}) => 'Các tập phim tương lai của ${title} sẽ không được ghi lại.';
	@override String get recordingScheduled => 'Ghi theo lịch trình.';
	@override String get alreadyScheduled => 'Chương trình này đã được lên kế hoạch';
	@override String get dvrAdminRequired => 'Cài đặt DVR đòi hỏi tài khoản admin';
	@override String get recordingFailed => 'Không thể lên lịch ghi âm';
	@override String get recordingTargetMissing => 'Không thể xác định việc ghi lại thư viện';
	@override String get recordNotAvailable => 'Ghi âm không sẵn dùng cho chương trình này';
	@override String get recordingCancelled => 'Ghi âm hủy';
	@override String get recordingRuleDeleted => 'Quy tắc ghi âm bị xóa';
	@override String get processRecordingRules => 'Đánh giá lại các quy tắc';
	@override String get recordingInProgress => 'Ghi âm Now';
	@override String recordingsCount({required Object count}) => '${count} dự kiến';
	@override String get editRule => 'Edit quy tắc';
	@override String get editRuleAction => 'Sửa';
	@override String get recordingRuleUpdated => 'Quy tắc ghi lại cập nhật';
	@override String get guideReloadRequested => 'Hướng dẫn làm mới được yêu cầu';
	@override String get guideReloadFailed => 'Không thể làm mới hướng dẫn';
	@override String get rulesProcessRequested => 'Quy tắc đánh giá lại được yêu cầu';
	@override String get rulesProcessFailed => 'Không thể đánh giá lại các quy tắc ghi âm';
	@override String get recordShow => 'Record show diễn';
	@override late final _Translations$liveTv$recordSettings$vi recordSettings = _Translations$liveTv$recordSettings$vi._(_root);
	@override String startingInMinutes({required Object minutes}) => 'Bắt đầu trong ${minutes} phút';
	@override String dayAtTime({required Object day, required Object time}) => '${day} tại ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} trả về dữ liệu phát trực tiếp TV không hợp lệ';
	@override String get failedToStartChannel => 'Không thể khởi động kênh trực tiếp';
	@override String get failedToBuildStreamUrl => 'Không thể xây dựng dòng URL';
	@override String playbackStartFailed({required Object reason}) => 'Không thể khởi động kênh: ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'Không thể chuyển kênh: ${reason}';
}

// Path: collections
class _Translations$collections$vi extends Translations$collections$en {
	_Translations$collections$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bộ Sưu Tập';
	@override String get collection => 'Bộ Sưu Tập';
	@override String get empty => 'Bộ sưu tập trống';
	@override String get deleteCollection => 'Xóa Bộ Sưu Tập';
	@override String deleteConfirm({required Object title}) => 'Xóa "${title}"? Không thể hoàn tác thao tác này.';
	@override String get deleted => 'Bộ sưu tập xóa';
	@override String get deleteFailed => 'Không xóa bộ sưu tập';
	@override String deleteFailedWithError({required Object error}) => 'Không xóa bộ sưu tập: ${error}';
	@override String get selectCollection => 'Chọn bộ sưu tập';
	@override String get collectionName => 'Collection Tên';
	@override String get enterCollectionName => 'Nhập tên bộ sưu tập';
	@override String get addedToCollection => 'Thêm vào Collection';
	@override String get errorAddingToCollection => 'Không thể thêm vào bộ sưu tập';
	@override String get created => 'Bộ sưu tập được tạo ra';
	@override String get removeFromCollection => 'Xóa khỏi bộ sưu tập';
	@override String removeFromCollectionConfirm({required Object title}) => 'Xóa “${title}” khỏi bộ sưu tập này?';
	@override String get removedFromCollection => 'Loại bỏ từ bộ sưu tập';
	@override String get removeFromCollectionFailed => 'Không thể loại bỏ khỏi bộ sưu tập';
	@override String removeFromCollectionError({required Object error}) => 'Sai lầm xóa khỏi bộ sưu tập: ${error}';
	@override String get searchCollections => 'Tìm kiếm bộ sưu tập';
}

// Path: playlists
class _Translations$playlists$vi extends Translations$playlists$en {
	_Translations$playlists$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Danh sách phát';
	@override String get playlist => 'Danh sách phát';
	@override String get noPlaylists => 'Không tìm thấy playlist';
	@override String get create => 'Tạo Playlist';
	@override String get playlistName => 'Playlist Tên';
	@override String get enterPlaylistName => 'Nhập tên playlist';
	@override String get delete => 'Xóa Danh Sách Phát';
	@override String get removeItem => 'Xóa khỏi danh sách phát';
	@override String get smartPlaylist => 'Đồ chơi thông minh';
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(count,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} mục',
	);
	@override String get emptyPlaylist => 'Danh sách game này trống';
	@override String get deleteConfirm => 'xóa playlist?';
	@override String deleteMessage({required Object name}) => 'Bạn có chắc chắn bạn muốn xóa "${name}" không?';
	@override String get created => 'Playlist tạo ra';
	@override String get deleted => 'Playlist xóa';
	@override String get itemAdded => 'Thêm vào playlist';
	@override String get itemRemoved => 'Xóa khỏi playlist';
	@override String get selectPlaylist => 'Chọn Playlist';
	@override String get searchPlaylists => 'Tìm kiếm playlists';
	@override String get errorCreating => 'Không thể tạo playlist';
	@override String get errorDeleting => 'Không xóa playlist';
	@override String get errorLoading => 'Không tải các playlists';
	@override String get errorAdding => 'Không thể thêm vào playlist';
	@override String get errorReordering => 'Không thể đặt lại các mục playlist';
	@override String get errorRemoving => 'Không thể loại bỏ khỏi playlist';
}

// Path: music
class _Translations$music$vi extends Translations$music$en {
	_Translations$music$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Đi đến album';
	@override String get goToArtist => 'Đi đến nghệ sĩ';
	@override String get instantMix => 'Trộn Lẫn Nhanh';
	@override String get playNext => 'Phát kế tiếp';
	@override String get addToQueue => 'Thêm vào Queue';
	@override String discNumber({required Object n}) => 'Đĩa ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} đường dẫn',
	);
	@override String get nowPlaying => 'Bây giờ chơi';
	@override String playingFrom({required Object title}) => 'Chơi từ ${title}';
	@override String get queue => 'Quay';
	@override String get clearQueue => 'Xóa hàng đợi';
	@override String get lyrics => 'Lời bài hát';
	@override String get visualizer => 'hình ảnh';
	@override String get visualizerProfileLoading => 'Đọc Track Analysis...';
	@override String get visualizerAmbientMotion => 'động cơ môi trường';
	@override String get visualizerPlexLoudness => 'Plex tiếng ồn';
	@override String get visualizerLiveAudio => 'Phân tích âm thanh trực tiếp';
	@override String get visualizerPreviousPreset => 'Phong cách Visual Previous';
	@override String get visualizerNextPreset => 'Tiếp theo: Visual Style';
	@override String get visualizerPresetAurora => 'Cực quang';
	@override String get visualizerPresetBloom => 'Nở hoa';
	@override String get visualizerPresetOrbitals => 'Ước';
	@override String get visualizerPresetPrism => 'Lăng kính';
	@override String get visualizerPresetTunnel => 'đường hầm';
	@override String get visualizerPresetTrackMap => 'Track Bản đồ';
	@override String get noLyrics => 'Không có Lyrics';
	@override String get sleepTimer => 'Giấc ngủ Timer';
	@override String get sleepTimerEndOfTrack => 'Kết thúc track';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} phút',
	);
	@override String get stopPlayback => 'Dừng Phát';
	@override String get previousTrack => 'Bản ghi trước';
	@override String get nextTrack => 'Bản ghi tiếp theo';
	@override String get repeat => 'Lặp lại';
	@override String get repeatAll => 'Lặp lại tất cả';
	@override String get repeatOne => 'Lặp lại một lần';
	@override String get instantMixNoServer => 'Không có máy chủ có sẵn cho một hỗn hợp tức thời';
	@override String get instantMixFailed => 'Không thể tải được hỗn hợp tức thời';
	@override String get instantMixEmpty => 'Tốc độ hỗn hợp đã trở lại với không có dấu vết';
	@override String noAudioUrl({required Object track}) => 'Không có URL âm thanh có sẵn cho ${track}';
	@override late final _Translations$music$discography$vi discography = _Translations$music$discography$vi._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$vi extends Translations$watchTogether$en {
	_Translations$watchTogether$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Xem cùng nhau';
	@override String get description => 'Xem nội dung đồng bộ với bạn bè và gia đình';
	@override String get createRoom => 'tạo phòng';
	@override String get creatingRoom => 'Tạo phòng...';
	@override String get joinRoom => 'Tham gia phòng';
	@override String get joiningRoom => 'Tham gia phòng...';
	@override String get connecting => 'Kết nối...';
	@override String get relayPublic => 'Các phòng sử dụng các phát sóng Open Watch Party công cộng.';
	@override String relayCustom({required Object url}) => 'Các căn phòng sử dụng điện thoại của bạn tại ${url}.';
	@override String get recentRooms => 'Phòng mới';
	@override String get roomActions => 'Phòng hành động';
	@override String get renameRoom => 'Đặt phòng';
	@override String get removeRoom => 'Gỡ bỏ';
	@override String get enterRoomCode => 'Nhập mã 6 ký tự từ host.';
	@override String get roomCode => 'Mã phòng';
	@override String get paste => 'Ăn bánh';
	@override String get noCodeInClipboard => 'Clipboard không chứa mã phòng';
	@override String get copyCode => 'Copy mã';
	@override String get codeCopied => 'Mã phòng copy';
	@override String get shareInvite => 'Chia sẻ mời';
	@override String get inviteCopied => 'Gửi tin nhắn, gửi nó vào một tin nhắn.';
	@override String inviteMessage({required Object code}) => 'Tham gia phòng đồng hồ của tôi tại PlezyNG: mở phòng đồng hồ, chọn phòng đồng hồ và nhập phòng đồng hồ ${code}.';
	@override String get openSessionControls => 'Open Watch Cùng kiểm soát phiên';
	@override String get reconnecting => 'Kết nối lại...';
	@override String get reconnectingDescription => 'Kết nối bị hỏng. bạn sẽ tự động vào phòng.';
	@override String get connected => 'Kết nối';
	@override String get disconnected => 'Khóa kết nối';
	@override String get youAreHost => 'Ngươi là người chủ';
	@override String hostedBy({required Object name}) => 'Được lưu trữ bởi ${name}';
	@override String get hostControlsPlayback => 'Hướng dẫn cài đặt playback';
	@override String get anyoneCanControl => 'Ai cũng có thể kiểm soát playback';
	@override String get roomLocked => 'phòng khóa';
	@override String get nowPlaying => 'Bây giờ chơi';
	@override String get nothingPlaying => 'Không chơi gì';
	@override String get nothingPlayingHost => 'Chơi một cái gì đó từ bất kỳ thư viện nào để chia sẻ nó với phòng.';
	@override String get nothingPlayingGuest => 'Khi chủ sở hữu chơi một cái gì đó, nó mở ra ở đây.';
	@override String get notShareable => 'Video này không có danh sách phù hợp, vì vậy chỉ có những người có quyền truy cập vào cùng một máy chủ có thể chơi nó.';
	@override String get searching => 'Tìm kiếm video này trong thư viện của bạn ...';
	@override String get yourCopy => 'bản sao của bạn';
	@override String get sharingYourCopy => 'Bạn đang chia sẻ bản sao của mình';
	@override String playingOtherLength({required Object difference}) => 'Chơi bản sao của bạn, ${difference}';
	@override String get mismatchTitle => 'Bản sao của bạn là một chiều dài khác nhau';
	@override String mismatchDescription({required Object difference}) => 'Bản sao gần nhất của bạn là ${difference} so với video của phòng. nó có thể là một cắt hoặc phiên bản khác.';
	@override String get playAnyway => 'Chơi bất cứ';
	@override String get chooseAnotherCopy => 'Chọn một bản sao khác';
	@override String get dontPlay => 'Đừng chơi';
	@override String get unavailableTitle => 'Bạn không có video này';
	@override String get unavailableDescription => 'PlezyNG không thể tìm thấy nó trong thư viện của bạn. chọn bản sao cho chính mình hoặc tìm kiếm lại.';
	@override String get chooseCopy => 'Chọn một bản sao';
	@override String get searchAgain => 'Tìm lại';
	@override String get noCandidates => 'Không có bản sao được tìm thấy trong thư viện của bạn.';
	@override String get choiceFailed => 'Tôi không thể chơi bản sao này cho phòng';
	@override String lengthLonger({required Object duration}) => '${duration} lâu hơn';
	@override String lengthShorter({required Object duration}) => '${duration} ngắn hơn';
	@override String get lengthSame => 'cùng chiều dài';
	@override String get lengthUnknown => 'Kích thước không rõ';
	@override String get joinCurrentPlayback => 'Tham gia Playback hiện tại';
	@override String get joinCurrentPlaybackDescription => 'Trở lại vào những gì chủ sở hữu hiện đang xem';
	@override String get stopMedia => 'Video cho mọi người';
	@override String get syncOffset => 'Đồng bộ Offset';
	@override String get syncOffsetDescription => 'Chuyển đổi video của bạn nếu nó chạy trước hoặc sau phòng.';
	@override String offsetHint({required Object difference}) => 'Bản sao của bạn là ${difference} so với video của phòng.';
	@override String applyDifference({required Object offset}) => 'Sử dụng ${offset}';
	@override String get offsetMinusSecond => '1 s';
	@override String get offsetMinusTenth => '- 100 ms';
	@override String get offsetPlusTenth => '+ 100 ms';
	@override String get offsetPlusSecond => '+ 1 s';
	@override String get participants => 'người tham gia';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} người tham gia',
	);
	@override String get hostBadge => 'Máy chủ';
	@override String nameYou({required Object name}) => '${name} (Các bạn)';
	@override String get playerIdle => 'Nhàn rỗi';
	@override String get playerLoading => 'tải';
	@override String get playerReady => 'sẵn sàng';
	@override String get playerBuffering => 'Buckingheri';
	@override String get matchSearching => 'Tìm kiếm';
	@override String get matchMatched => 'Có video';
	@override String get matchMismatched => 'chiều dài khác nhau';
	@override String get matchUnavailable => 'Không có video';
	@override String participantOffset({required Object offset}) => 'Tính năng: Offset ${offset}';
	@override String get makeHost => 'làm chủ';
	@override String get makeHostQuestion => 'Chuyển khách?';
	@override String makeHostConfirm({required Object name}) => '${name} sẽ kiểm soát playback và chạy phiên cho tất cả mọi người.';
	@override String get transfer => 'Chuyển đổi';
	@override String get removeParticipant => 'Xóa khỏi phòng';
	@override String removeParticipantQuestion({required Object name}) => 'Xóa ${name}?';
	@override String removeParticipantConfirm({required Object name}) => '${name} rời khỏi phòng. họ có thể tham gia lại với mã trừ khi bạn khóa phòng.';
	@override String get remove => 'Gỡ bỏ';
	@override String get roomSettings => 'Thiết lập phòng';
	@override String get letEveryoneControl => 'Hãy để mọi người kiểm soát Playback';
	@override String get lockRoom => 'Phòng Lock';
	@override String get lockRoomDescription => 'Không ai mới có thể tham gia';
	@override String get leaveRoom => 'Giữ phòng';
	@override String get leaveRoomQuestion => 'Giữ phòng?';
	@override String get leaveRoomConfirm => 'Bạn có thể tham gia lại với mã phòng.';
	@override String get leave => 'rời đi';
	@override String get endRoom => 'phòng cuối';
	@override String get endRoomQuestion => 'phòng cuối ?';
	@override String get endRoomConfirm => 'Đây là kết thúc của phòng cho tất cả mọi người.';
	@override String get end => 'Kết thúc';
	@override String get playBlockedTitle => 'Playback không bắt đầu';
	@override String get playBlockedDescription => 'Tải về trò chơi để bắt đầu xem với phòng.';
	@override late final _Translations$watchTogether$notices$vi notices = _Translations$watchTogether$notices$vi._(_root);
	@override late final _Translations$watchTogether$ended$vi ended = _Translations$watchTogether$ended$vi._(_root);
	@override late final _Translations$watchTogether$errors$vi errors = _Translations$watchTogether$errors$vi._(_root);
	@override String untitledEpisode({required Object number}) => 'Chương ${number}';
}

// Path: downloads
class _Translations$downloads$vi extends Translations$downloads$en {
	_Translations$downloads$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Nội dung tải xuống';
	@override String get manage => 'quản lý';
	@override String get tvShows => 'Chương Trình TV';
	@override String get movies => 'Phim';
	@override String get music => 'Nhạc';
	@override String tracksQueued({required Object count}) => '${count} tracks queued cho download';
	@override String get noDownloads => 'Không tải xuống';
	@override String get noDownloadsDescription => 'Nội dung tải xuống sẽ xuất hiện ở đây để xem offline';
	@override String get downloadNow => 'Tải về';
	@override String get deleteDownload => 'Tải Download';
	@override String get retryDownload => 'Retry tải xuống';
	@override String get downloadQueued => 'Tải xuống đã được xếp hàng đợi.';
	@override String get downloadResumed => 'Download Đổi lại';
	@override String get serverErrorBitrate => 'lỗi máy chủ: file có thể vượt quá giới hạn bitrate từ xa';
	@override String get storageFull => 'Tải xuống dừng lại để bảo vệ lưu trữ có sẵn.Tự do một số không gian hoặc chọn một vị trí tải xuống khác, sau đó rút lại.';
	@override String get storageUnavailable => 'Tải xuống dừng lại vì lưu trữ có sẵn không thể được kiểm tra. kiểm tra vị trí tải xuống, sau đó rút lại.';
	@override String episodesQueued({required Object count}) => '${count} episodes quoted for download (liên kết  sửa đổi)';
	@override String get downloadDeleted => 'Download đã xóa';
	@override String deleteConfirm({required Object title}) => 'Xóa "${title}" từ thiết bị này?';
	@override String get deleteCollectionDownloads => 'Xóa Downloads';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => 'Xóa mọi tệp đã tải xuống trong “${title}” khỏi thiết bị này?';
	@override String get collectionDownloadsDeleted => 'Downloads xóa';
	@override String get cancelledDownloadTitle => 'Hủy Download';
	@override String get cancelledDownloadMessage => 'Download này đã bị hủy bỏ. bạn muốn làm gì?';
	@override String get allEpisodesAlreadyDownloaded => 'Tất cả các tập đã tải xuống';
	@override String get resumeDownload => 'Đánh giá download';
	@override String get cancelledDownload => 'Hủy download';
	@override String syncingFile({required Object file, required Object status}) => '${file} (tính hợp ${status})';
	@override String downloadedFileClickToComplete({required Object file}) => 'Tải về ${file} - Click để hoàn thành';
	@override String get partialDownloadClickToComplete => 'Tải về - Click to complete';
	@override String get deleting => 'xóa...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Xóa ${title}... (${current} trong số ${total})';
	@override String get queuedTooltip => 'Quả';
	@override String queuedFilesTooltip({required Object files}) => 'Đánh giá ${files}';
	@override String get downloadingTooltip => 'tải...';
	@override String downloadingFilesTooltip({required Object files}) => 'Tải về ${files}';
	@override String get noDownloadsTree => 'Không tải xuống';
	@override String get pauseAll => 'All nghỉ ngơi';
	@override String get resumeAll => 'Tóm lại tất cả';
	@override String get retryAll => 'Quay lại tất cả';
	@override String get retryFailed => 'Retry thất bại Downloads';
	@override String get deleteAll => 'Xóa Hết';
	@override String get selectVersion => 'Chọn phiên bản';
	@override String get allEpisodes => 'Tất cả các tập';
	@override String get unwatchedOnly => 'Không chỉ quan sát';
	@override String nextNUnwatched({required Object count}) => 'Tiếp theo ${count} chưa được xem';
	@override String get customAmount => 'Số lượng tùy chỉnh...';
	@override String get customAmountAny => 'Số lượng (tất cả)';
	@override String get randomEpisodes => 'Ngẫu thuật episodes';
	@override String get includeSpecials => 'bao gồm đặc biệt';
	@override String get howManyEpisodes => 'Bao nhiêu sự kiện?';
	@override String get invalidEpisodeCount => 'Nhập một số tập hợp hợp lệ.';
	@override String get keepSynced => 'Giữ synchronized';
	@override String get downloadOnce => 'Download một lần';
	@override String keepNUnwatched({required Object count}) => 'Giữ ${count} không được xem';
	@override String get editSyncRule => 'Quy tắc Edit Sync';
	@override String get removeSyncRule => 'Xóa quy tắc sync';
	@override String removeSyncRuleConfirm({required Object title}) => 'Ngừng đồng bộ hóa "${title}"? các tập phim được tải xuống sẽ được giữ lại.';
	@override String removeListSyncRuleConfirm({required Object title}) => 'Đừng đồng bộ hóa "${title}"';
	@override String get deleteSyncRuleDownloads => 'Cũng xóa các tải xuống liên quan';
	@override String get deleteSyncRuleDownloadsDescription => 'Tải về được sử dụng bởi một quy tắc đồng bộ hoặc hồ sơ khác sẽ được giữ lại.';
	@override String syncRuleCreated({required Object count}) => 'Quy tắc đồng bộ được tạo — giữ ${count} các tập không được xem';
	@override String get syncRuleUpdated => 'Quy tắc Sync cập nhật';
	@override String get syncRuleRemoved => 'Quy tắc đồng bộ đã bị loại bỏ';
	@override String get syncRuleAndDownloadsRemoved => 'Quy tắc đồng bộ và các tải xuống liên quan đã bị xóa';
	@override String get syncRuleCleanupBusy => 'Các quy tắc đồng bộ hiện đang được cập nhật. thử lại một lần nữa.';
	@override String get syncRuleCleanupUnavailable => 'Các tải xuống liên quan không thể được xác định an toàn. nối lại máy chủ và thử lại, hoặc xóa quy tắc mà không xóa tải xuống.';
	@override String syncedNewEpisodes({required Object count, required Object title}) => 'Đồng bộ ${count} các tập mới cho ${title}';
	@override String get syncNow => 'Sync hiện tại';
	@override String get downloadsUpToDate => 'Tải xuống hiện tại';
	@override String syncComplete({required Object queued, required Object removed}) => 'Sync complete · ${queued} queued, ${removed} đã được xóa';
	@override String get activeSyncRules => 'Quy tắc Sync';
	@override String get reviewOrphanFiles => 'Đánh giá Downloads Orphaned';
	@override String get orphanReviewTitle => 'Đánh giá Downloads Orphaned';
	@override String get orphanReviewDescription => 'Các tệp được nhãn hiệu này nằm trong các thư mục tải xuống được quản lý bởi ứng dụng mặc định của PlezyNG và không có bản ghi tải xuống hoặc nhiệm vụ hoạt động phù hợp.';
	@override String orphanReviewCount({required Object count, required Object size}) => '${count} tập tin · ${size}';
	@override String orphanDeleteFiles({required Object count}) => 'xóa ${count} file';
	@override String get orphanCleanupNone => 'Không tìm thấy các file download orphaned';
	@override String get orphanCleanupFailed => 'PlezyNG không thể an toàn quét thư mục tải xuống được quản lý. không có tệp đã bị xóa.';
	@override String get orphanCleanupChanged => 'Danh sách tải xuống đã thay đổi trong quá trình xem xét. xem lại các tập tin trước khi làm sạch.';
	@override String orphanCleanupComplete({required Object count, required Object size}) => 'xóa ${count} các tệp mồ côi · ${size} miễn phí';
	@override String get noSyncRules => 'Không có quy tắc sync';
	@override String get manageSyncRule => 'Quản lý sync';
	@override String get editEpisodeCount => 'Số Episode';
	@override String get editSyncFilter => 'Bộ lọc Sync';
	@override String get syncAllItems => 'Tích hợp tất cả các mục';
	@override String get syncUnwatchedItems => 'Tích hợp các mục không được xem xét';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Máy chủ: ${server} • ${status}';
	@override String get syncRuleAvailable => 'Sẵn có';
	@override String get syncRuleOffline => 'Ngoại tuyến';
	@override String get syncRuleSignInRequired => 'Nhập vào yêu cầu';
	@override String get syncRuleAccessDenied => 'Truy cập từ chối';
	@override String get syncRuleNotAvailableForProfile => 'Không sẵn dùng cho hồ sơ hiện tại';
	@override String get syncRuleUnknownServer => 'máy chủ không rõ';
	@override String get syncRuleListCreated => 'Quy tắc Sync được tạo ra';
	@override late final _Translations$downloads$backgroundWarning$vi backgroundWarning = _Translations$downloads$backgroundWarning$vi._(_root);
	@override String get options => 'Tải về tùy chọn';
	@override late final _Translations$downloads$groupings$vi groupings = _Translations$downloads$groupings$vi._(_root);
	@override String get unknownLibrary => 'Thư viện chưa biết';
	@override String get unknownShow => 'show chưa biết';
	@override String get unknownSeason => 'Mùa chưa biết';
	@override String get unknownAlbum => 'Album chưa biết';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} hoàn thành';
	@override String storageUsed({required Object size}) => 'Lưu trữ sử dụng: ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tải về',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} hiển thị',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} phim ảnh',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} album',
	);
	@override String get errorFileNotFound => 'file chưa tìm thấy (404)';
	@override String get errorDownloadNotAllowed => 'Tải xuống không được phép bởi máy chủ (403)';
	@override String get errorDownloadFailed => 'Download thất bại';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'Tải về thất bại: ${reason}';
	@override String get convertingOnServer => 'Chuyển đổi sang server...';
	@override String convertingOnServerPercent({required Object percent}) => 'Chuyển đổi trên máy chủ · ${percent}%';
	@override String errorHttpStatus({required Object status}) => 'Tải về thất bại (HTTP ${status})';
	@override String errorPostProcessing({required Object reason}) => 'Tiếp theo xử lý thất bại: ${reason}';
	@override String get reasonFileNotSaved => 'file không thể được lưu trên thiết bị này';
	@override String get reasonCannotResume => 'Phần tải xuống không thể được khôi phục';
	@override String get reasonDeviceStorageFull => 'Thiết bị này không được lưu trữ';
	@override String get notificationDownloading => 'tải...';
	@override String get notificationComplete => 'Download hoàn chỉnh';
	@override String get notificationPaused => 'Download nghỉ ngơi';
}

// Path: shaders
class _Translations$shaders$vi extends Translations$shaders$en {
	_Translations$shaders$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bộ đổ bóng';
	@override String get noShaderDescription => 'Không có video nâng cấp';
	@override String get nvscalerDescription => 'NVIDIA image scaling cho video sắc nét hơn';
	@override String get artcnnVariantNeutral => 'trung lập';
	@override String get artcnnVariantDenoise => 'Dinoza';
	@override String get artcnnVariantDenoiseSharpen => 'Đánh giá + Sharpen';
	@override String get qualityFast => 'nhanh chóng';
	@override String get qualityHQ => 'chất lượng cao';
	@override String get mode => 'Thời trang';
	@override String get importShader => 'nhập khẩu Shader';
	@override String get customShaderDescription => 'Tính năng GLSL Shader';
	@override String get shaderImported => 'Shader nhập khẩu';
	@override String get shaderImportFailed => 'Không nhập khẩu Shader';
	@override String get deleteShader => 'Xóa Shader';
	@override String deleteShaderConfirm({required Object name}) => 'Xóa “${name}” ?';
}

// Path: companionRemote
class _Translations$companionRemote$vi extends Translations$companionRemote$en {
	_Translations$companionRemote$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Điều khiển từ xa đi kèm';
	@override String connectedTo({required Object name}) => 'Kết nối với ${name}';
	@override String get unknownDevice => 'Thiết bị chưa biết';
	@override late final _Translations$companionRemote$session$vi session = _Translations$companionRemote$session$vi._(_root);
	@override late final _Translations$companionRemote$pairing$vi pairing = _Translations$companionRemote$pairing$vi._(_root);
	@override late final _Translations$companionRemote$remote$vi remote = _Translations$companionRemote$remote$vi._(_root);
	@override late final _Translations$companionRemote$errors$vi errors = _Translations$companionRemote$errors$vi._(_root);
	@override String get closedBeforeAuth => 'Kết nối đóng cửa trước khi xác thực';
}

// Path: videoSettings
class _Translations$videoSettings$vi extends Translations$videoSettings$en {
	_Translations$videoSettings$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Tốc Độ Phát';
	@override String get normalSpeed => 'Bình thường';
	@override String sleepTimerActive({required Object duration}) => 'Động tác (${duration})';
	@override String get zoom => 'Thu phóng';
	@override String get sleepTimer => 'Giấc ngủ Timer';
	@override String get audioSync => 'Âm thanh Sync';
	@override String get subtitleSync => 'Chủ đề Sync';
	@override String get hdr => 'HDR';
	@override String get hdrUnsupported => 'HDR không có sẵn ở đây - máy tính bảng hoặc video output này không thể mang nó.';
	@override String get hdrToneMapping => 'HDR Tone Bản đồ';
	@override String get hdrToneMappingCompositor => 'Tác giả';
	@override String get hdrToneMappingCompositorDescription => 'Đi qua các metadata HDR của nguồn và để cho bản đồ máy tính để bàn.';
	@override String get hdrToneMappingPlayer => 'Trình Phát';
	@override String get hdrToneMappingPlayerDescription => 'Bản đồ cho độ sáng cao của màn hình trong người chơi, sau đó nói với nhà soạn nhạc kết quả.';
	@override String get hdrToneMappingFailed => 'Không thể thay đổi bản đồ âm thanh HDR - chế độ trước vẫn hoạt động.';
	@override String get audioOutput => 'Audio output xuất';
	@override String get videoTrack => 'Bản video';
	@override String get videoTrackDescription => 'Chọn luồng video cần hiển thị. Có sẵn khi phát bằng MPV nếu tệp có các bản video thay thế.';
	@override String get videoTrackDefault => 'Mặc định';
	@override String get videoTrackUnavailable => 'Không có bản video thay thế nào.';
	@override String get videoTrackFailed => 'Không thể đổi bản video.';
	@override String videoTrackNumber({required Object id}) => 'Bản ${id}';
	@override String get performanceOverlay => 'Hiệu suất Overlay';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'xung quanh';
	@override String get audioOutputSpatial => 'âm thanh không gian';
	@override String get audioOutputStereo => 'Âm Thanh Nổi';
	@override String get audioEqualizer => 'âm thanh equalizer';
	@override String get audioEqualizerDescription => '10-band equalizer cho MPVCác bộ lọc âm thanh sử dụng âm thanh giải mã và tắt passthrough.';
	@override String get audioEqualizerFlat => 'Đơn giản';
	@override String get audioEqualizerActive => 'Tùy chọn';
	@override String get audioEqualizerSaveFailed => 'Không thể tiết kiệm các thiết lập Audio Equalizer.';
	@override String get audioEffectsDescription => 'Hiệu ứng sử dụng âm thanh giải mã, do đó passthrough xoay. không gian phòng và mở rộng stereo phụ thuộc vào MPV xây dựng và theo dõi.';
	@override String get audioStereoWidth => 'Stereo mở rộng';
	@override String get audioSpatializer => 'Môi trường phòng';
	@override String get audioSpatializerDescription => 'Thêm phản ánh phòng yên tĩnh.';
	@override String get audioPitch => 'Pitch thay đổi';
	@override String get audioPitchDescription => 'Thay đổi vị trí mà không thay đổi tốc độ. MPV xây dựng phải bao gồm Rubber Band.';
	@override String get audioEffectUnavailable => 'Hiệu ứng này không có sẵn cho con đường này hoặc MPV xây dựng';
	@override String get backgroundVideoAudio => 'Video âm thanh nền';
	@override String get backgroundVideoAudioDescription => 'Giữ video chơi âm thanh khi bạn rời chơi; hình ảnh được ẩn cho đến khi bạn trở về. Android sử dụng thông báo phát lại phương tiện truyền thông.';
	@override String get audioNormalization => 'bình thường tiếng ồn';
	@override String get audioNormalizationDisablesPassthrough => 'Xóa âm thanh đến PCM; passthrough đang tắt trong khi điều này đang';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$vi extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get color => 'Màu sắc';
	@override String get performance => 'Hiệu suất';
	@override String get buffer => 'Bộ đệm';
	@override String get app => 'Ứng Dụng';
	@override String get decoder => 'Bộ giải mã';
	@override String get rawDecoder => 'Mã Decoder';
	@override String get tunneling => 'đường hầm';
	@override String get passthrough => 'Truyền thẳng';
	@override String get aspect => 'Khía cạnh';
	@override String get rotation => 'Xoay';
	@override String get dvSource => 'Nguồn DV';
	@override String get dvPath => 'Đường DV';
	@override String get dvRouteDecoder => 'Dolby Vision Bộ xử lý';
	@override String get dvRouteDecoderP81 => 'Bộ giải mã Dolby Vision (P7→8.1)';
	@override String get dvRouteBaseLayer => 'Lớp cơ sở';
	@override String get dvRouteBaseLayerHdr10 => 'HDR10 lớp cơ sở';
	@override String get dvRouteBaseLayerHlg => 'HLG cơ sở lớp';
	@override String get dvRouteBaseLayerSdr => 'SDR cơ sở';
	@override String get dvRouteReshaped => 'RPU tái tạo (gpu-next)';
	@override String get dvRouteFelGraphActive => 'P7 FEL biểu đồ thí nghiệm (không đủ điều kiện)';
	@override String get p7Conversion => 'Chuyển đổi P7';
	@override String get sampleRate => 'Tỷ lệ mẫu';
	@override String get pixelFormat => 'Đánh giá Pixel Fmt';
	@override String get hwFormat => 'Định dạng phần cứng';
	@override String get matrix => 'Ma trận';
	@override String get primaries => 'nguyên nhân';
	@override String get transfer => 'Chuyển đổi';
	@override String get renderFps => 'Đánh giá FPS';
	@override String get displayFps => 'Hiển thị FPS';
	@override String get avSync => 'A/V đồng bộ';
	@override String get dropped => 'bị rơi';
	@override String get dvRpus => 'DV RPU';
	@override String get dvRpuAverage => 'Đánh giá RPU AVG';
	@override String get dvSampleAverage => 'Đánh giá DV Sample Avg';
	@override String get maxLuma => 'Độ chói tối đa';
	@override String get minLuma => 'Lúa Lúa';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Cache sử dụng';
	@override String get cacheLimit => 'Cache giới hạn';
	@override String get speed => 'Tốc độ';
	@override String get player => 'Trình Phát';
	@override String get playMethod => 'Cách Phát';
	@override String get memory => 'ký ức';
	@override String get uiFps => 'Đánh giá FPS';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Android HW';
	@override String get decoderNvidiaHw => 'Đánh giá NVIDIA';
	@override String get decoderQualcommHw => 'Đánh giá Qualcomm HW';
	@override String get decoderMediatekHw => 'Thông tin HW';
	@override String get decoderExynosHw => 'Đánh giá HW';
	@override String get decoderSoftware => 'Phần mềm';
	@override String get decoderHardware => 'Phần cứng';
	@override String get tunnelingActive => 'hoạt động';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted} (${failures} thất bại)';
}

// Path: externalPlayer
class _Translations$externalPlayer$vi extends Translations$externalPlayer$en {
	_Translations$externalPlayer$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Người chơi bên ngoài';
	@override String get useExternalPlayer => 'Sử dụng Player External';
	@override String get useExternalPlayerDescription => 'Mở video trong ứng dụng khác';
	@override String get selectPlayer => 'Chọn Player';
	@override String get customPlayers => 'Người chơi Custom';
	@override String get systemDefault => 'Hệ thống default';
	@override String get addCustomPlayer => 'Thêm Custom Player';
	@override String get playerName => 'Tên cầu thủ';
	@override String get playerNameHint => 'Cầu thủ của tôi';
	@override String get playerCommand => 'Lệnh';
	@override String get playerPackage => 'gói tên';
	@override String get playerUrlScheme => 'Hệ thống URL';
	@override String get off => 'Tắt';
	@override String get launchFailed => 'Không mở cầu thủ bên ngoài';
	@override String appNotInstalled({required Object name}) => '${name} không được cài đặt';
	@override String get playInExternalPlayer => 'Chơi trong người chơi bên ngoài';
	@override String get description => 'Chọn một ứng dụng khác để mở video trong. Người chơi có sẵn phụ thuộc vào thiết bị của bạn và các ứng dụng được cài đặt.';
	@override String get systemDefaultDescription => 'Hãy để hệ điều hành mở video với ứng dụng mặc định của nó.';
	@override String playerOptionDescription({required Object player}) => 'Mở video với ${player}.';
	@override String get playerNameDescription => 'Nhãn được hiển thị trong danh sách người chơi.';
	@override String get playerPackageDescription => 'Nhập tên gói Android của ứng dụng người chơi, chẳng hạn như com.example.player.';
	@override String get playerCommandDescription => 'Nhập lệnh người chơi cài đặt hoặc con đường thực hiện cho thiết bị này.';
	@override String get playerUrlSchemeDescription => 'Nhập biểu đồ URL và mẫu URL tùy chọn được sử dụng để khởi động người chơi.';
}

// Path: metadataEdit
class _Translations$metadataEdit$vi extends Translations$metadataEdit$en {
	_Translations$metadataEdit$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Sửa';
	@override String get screenTitle => 'Sửa dữ liệu mô tả';
	@override String get basicInfo => 'Thông tin cơ bản';
	@override String get artwork => 'Nghệ thuật';
	@override String get advancedSettings => 'Cài đặt Advanced';
	@override String get title => 'Tiêu đề';
	@override String get sortTitle => 'Sắp xếp tiêu đề';
	@override String get originalTitle => 'Tiêu đề gốc';
	@override String get releaseDate => 'Ngày phát hành';
	@override String get contentRating => 'Content Đánh giá';
	@override String get studio => 'Hãng phim';
	@override String get tagline => 'Giới thiệu';
	@override String get summary => 'Tổng hợp';
	@override String get poster => 'Áp phích';
	@override String get background => 'nền';
	@override String get logo => 'Biểu trưng';
	@override String get squareArt => 'Quảng trường Art';
	@override String get selectPoster => 'Chọn Poster';
	@override String get selectBackground => 'Chọn nền';
	@override String get selectLogo => 'Chọn logo';
	@override String get selectSquareArt => 'Chọn Square Art';
	@override String get fromUrl => 'Từ URL';
	@override String get uploadFile => 'tải file';
	@override String get enterImageUrl => 'Nhập hình ảnh URL';
	@override String get imageUrl => 'Ảnh URL';
	@override String get metadataUpdated => 'Metadata cập nhật';
	@override String get metadataUpdateFailed => 'Không cập nhật metadata';
	@override String get artworkUpdated => 'Artwork cập nhật';
	@override String get artworkUpdateFailed => 'Không cập nhật tác phẩm nghệ thuật';
	@override String get noArtworkAvailable => 'Không có tác phẩm nghệ thuật';
	@override String artworkOption({required Object index}) => 'Tùy chọn nghệ thuật ${index}';
	@override String selectedArtworkOption({required Object index}) => 'Tùy chọn Artwork ${index}, được chọn';
	@override String get notSet => 'Không đặt';
	@override String get libraryDefault => 'Thư viện thất bại';
	@override String get accountDefault => 'Tài khoản default';
	@override String get seriesDefault => 'Lập trình default';
	@override String get episodeSorting => 'Episode Đánh giá';
	@override String get oldestFirst => 'Lớn nhất đầu tiên';
	@override String get newestFirst => 'mới nhất đầu tiên';
	@override String get keep => 'giữ';
	@override String get allEpisodes => 'Tất cả các tập';
	@override String latestEpisodes({required Object count}) => '${count} các tập cuối cùng';
	@override String get latestEpisode => 'episode mới nhất';
	@override String episodesAddedPastDays({required Object count}) => 'Các sự kiện đã được thêm vào trong những ngày gần đây ${count}';
	@override String get deleteAfterPlaying => 'Xóa các tập sau khi chơi';
	@override String get never => 'Không Bao Giờ';
	@override String get afterADay => 'Sau một ngày';
	@override String get afterAWeek => 'Sau một tuần';
	@override String get afterAMonth => 'Sau một tháng';
	@override String get onNextRefresh => 'Next Cung cấp mới';
	@override String get seasons => 'Phần';
	@override String get show => 'show show';
	@override String get hide => 'Ẩn';
	@override String get episodeOrdering => 'Episode Đặt hàng';
	@override String get tmdbAiring => 'Cơ sở dữ liệu phim (Aired)';
	@override String get tvdbAiring => 'TheTVDB (theo thứ tự phát sóng)';
	@override String get tvdbAbsolute => 'TTVDB (tự nhiên)';
	@override String get metadataLanguage => 'Metadata ngôn ngữ';
	@override String get useOriginalTitle => 'Sử dụng tiêu đề gốc';
	@override String get preferredAudioLanguage => 'Ngôn ngữ thoại ưa thích';
	@override String get preferredSubtitleLanguage => 'Ngôn ngữ phụ đề ưu tiên';
	@override String get subtitleMode => 'Tự chọn Subtitle Mode';
	@override String get manuallySelected => 'Chọn thủ công';
	@override String get shownWithForeignAudio => 'Hiển thị bằng âm thanh nước ngoài';
	@override String get alwaysEnabled => 'Luôn có khả năng';
	@override String get tags => 'Thẻ';
	@override String get addTag => 'thêm tag';
	@override String get genre => 'Thể loại';
	@override String get director => 'Đạo Diễn';
	@override String get writer => 'Người viết';
	@override String get producer => 'Nhà sản xuất';
	@override String get country => 'đất nước';
	@override String get collection => 'Bộ Sưu Tập';
	@override String get label => 'Nhãn hiệu';
	@override String get quickTag => 'Tag nhanh...';
}

// Path: matchScreen
class _Translations$matchScreen$vi extends Translations$matchScreen$en {
	_Translations$matchScreen$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get match => 'trận đấu...';
	@override String get fixMatch => 'Đặt trận đấu...';
	@override String get unmatch => 'Hủy khớp';
	@override String get unmatchConfirm => 'Đánh giá trận đấu này? Plex đối xử với nó như là không đụng độ cho đến khi hoàn thành.';
	@override String get unmatchSuccess => 'mục không phù hợp';
	@override String get unmatchFailed => 'thất bại trong Unmatch item';
	@override String get matchApplied => 'Match ứng dụng';
	@override String get matchFailed => 'Không thực hiện trận đấu';
	@override String get titleHint => 'Tiêu đề';
	@override String get yearHint => 'Năm';
	@override String get search => 'Tìm kiếm';
	@override String get noMatchesFound => 'Không tìm thấy trận đấu';
}

// Path: serverTasks
class _Translations$serverTasks$vi extends Translations$serverTasks$en {
	_Translations$serverTasks$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Server nhiệm vụ';
	@override String get failedToLoad => 'Không thể tải nhiệm vụ';
	@override String get noTasks => 'Không có nhiệm vụ chạy';
}

// Path: trakt
class _Translations$trakt$vi extends Translations$trakt$en {
	_Translations$trakt$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Kết nối';
	@override String connectedAs({required Object username}) => 'Kết nối với @${username}';
	@override String get disconnectConfirm => 'Tắt tài khoản Trakt?';
	@override String get disconnectConfirmBody => 'PlezyNG sẽ ngừng gửi các sự kiện đến Trakt. Bạn có thể kết nối lại bất cứ lúc nào.';
	@override String get scrobble => 'Thời gian thực scrobbling';
	@override String get scrobbleDescription => 'Gửi game, nghỉ ngơi, và dừng các sự kiện đến Trakt trong khi chơi lại.';
	@override String get watchedSync => 'Sync theo dõi trạng thái';
	@override String get watchedSyncDescription => 'Khi bạn đánh dấu các mục như được xem ở PlezyNG, chúng cũng được đánh dấu như được xem ở Trakt.';
}

// Path: seerr
class _Translations$seerr$vi extends Translations$seerr$en {
	_Translations$seerr$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Kết nối Seerr';
	@override String get serverUrl => 'URL máy chủ';
	@override String get serverUrlHelper => 'Địa chỉ của đơn vị Seerr của bạn';
	@override String get checkServer => 'tiếp tục';
	@override String get signInWithJellyfin => 'Đăng ký với Jellyfin';
	@override String get signInWithEmby => 'Đăng ký với Emby';
	@override String get signInWithLocal => 'Sử dụng tài khoản địa phương';
	@override String get email => 'Email';
	@override String get noSignInMethods => 'Ví dụ này Seerr không cung cấp các phương pháp đăng nhập PlezyNG hỗ trợ.';
	@override String get instance => 'Ấn Độ';
	@override String get disconnectConfirm => 'Cắt kết nối Seerr?';
	@override String get disconnectConfirmBody => 'PlezyNG sẽ quên ví dụ này Seerr. nối lại bất cứ lúc nào.';
	@override String get request => 'yêu cầu';
	@override String get request4k => 'yêu cầu 4K';
	@override String get seasons => 'Phần';
	@override String get allSeasons => 'Tất cả mùa';
	@override String get advancedOptions => 'Nâng cao';
	@override String get destinationServer => 'Destination Server Khách sạn';
	@override String get qualityProfile => 'Hồ sơ chất lượng';
	@override String get rootFolder => 'Root thư mục';
	@override String get languageProfile => 'ngôn ngữ profile';
	@override String get tags => 'Thẻ';
	@override String get noTags => 'Không tags';
	@override String defaultOption({required Object name}) => '${name} (Điều mặc định)';
	@override String get animeNote => 'Bộ phim này là anime.';
	@override String get requestSubmitted => 'Yêu cầu gửi';
	@override String requestFailed({required Object error}) => 'Đề nghị thất bại: ${error}';
	@override String get requestsLoadFailed => 'Không thể tải các tùy chọn yêu cầu';
	@override String get nothingToRequest => 'Mọi thứ đều có sẵn hoặc được yêu cầu.';
	@override String get statusAvailable => 'Sẵn có';
	@override String get statusPartiallyAvailable => 'Phần có sẵn';
	@override String get statusRequested => 'yêu cầu';
	@override String get statusProcessing => 'xử lý';
	@override String get statusBlocklisted => 'Khám phá';
	@override String couldNotReach({required Object url, required Object error}) => 'Không thể đạt ${url}: ${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => 'Không có trường hợp Seerr tại ${url} (HTTP ${status})';
	@override String get behindAuthProxy => 'Một proxy ngược xác thực (SSO hoặc HTTP auth) trả lời thay vì Seerr. PlezyNG không thể đăng ký thông qua nó: để Seerr /api/v1 đường đi qua proxy cho ứng dụng này, hoặc sử dụng một địa chỉ tiếp cận Seerr trực tiếp.';
	@override String get invalidUrl => 'Nhập địa chỉ máy chủ như https://seerr.example.com';
	@override String get quickConnectUnsupported => 'Ví dụ Seerr này không hỗ trợ Quick Connect. nó cần Seerr 3.4 hoặc mới hơn.';
	@override String get notInitialized => 'Ví dụ này Seerr không hoàn thành cài đặt chạy đầu tiên';
	@override String get noPlexTokenForReauth => 'Số token Plex có sẵn để đăng ký lại';
	@override String get noStoredCredentials => 'Không có thông tin đăng nhập đã lưu để đăng nhập lại';
	@override String get signInRejected => 'Sign-in bị từ chối';
	@override String get noSessionCookie => 'Seerr không phát hành cookie session';
	@override String get freshCookieRejected => 'Seerr từ chối cookie phiên mới';
	@override String get noUserInformation => 'Seerr không trả lại thông tin người dùng';
	@override String get sessionRejectedAfterReauth => 'Cuộc họp đã bị từ chối sau khi ký lại';
	@override String get permissionDenied => 'Seerr từ chối hành động này: Tài khoản của bạn không còn được phép yêu cầu';
	@override String get permissionRevoked => 'Bạn không còn được phép yêu cầu điều này';
}

// Path: services
class _Translations$services$vi extends Translations$services$en {
	_Translations$services$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Dịch vụ';
	@override String get hubSubtitle => 'Sync theo dõi tiến bộ và yêu cầu các tiêu đề mới.';
	@override String get integrations => 'Integration';
	@override String get notConnected => 'Không liên kết';
	@override String connectedAs({required Object username}) => 'Kết nối với @${username}';
	@override String get scrobble => 'Theo dõi tiến bộ tự động';
	@override String get scrobbleDescription => 'Cập nhật danh sách của bạn khi bạn hoàn thành một tập hoặc phim.';
	@override String disconnectConfirm({required Object service}) => 'Tắt kết nối ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'PlezyNG sẽ ngừng cập nhật ${service}. Liên hệ lại bất cứ lúc nào.';
	@override String connectFailed({required Object service}) => 'Không thể kết nối với ${service}.Cần thử lại.';
	@override late final _Translations$services$names$vi names = _Translations$services$names$vi._(_root);
	@override late final _Translations$services$simklReconnect$vi simklReconnect = _Translations$services$simklReconnect$vi._(_root);
	@override late final _Translations$services$deviceCode$vi deviceCode = _Translations$services$deviceCode$vi._(_root);
	@override late final _Translations$services$oauthProxy$vi oauthProxy = _Translations$services$oauthProxy$vi._(_root);
	@override late final _Translations$services$pendingAuth$vi pendingAuth = _Translations$services$pendingAuth$vi._(_root);
	@override late final _Translations$services$libraryFilter$vi libraryFilter = _Translations$services$libraryFilter$vi._(_root);
	@override String get seerrDescription => 'Kết nối với Seerr hoặc Overseerr để tìm kiếm tiêu đề và gửi yêu cầu phương tiện truyền thông.';
	@override late final _Translations$services$trackerDescriptions$vi trackerDescriptions = _Translations$services$trackerDescriptions$vi._(_root);
}

// Path: addServer
class _Translations$addServer$vi extends Translations$addServer$en {
	_Translations$addServer$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => 'Thêm máy chủ ${product}';
	@override String get serverUrls => 'Server URL của bạn';
	@override String get serverUrlsHelper => 'Nhiều URL được cho phép, tách biệt bởi commas.';
	@override String get findServer => 'tìm server';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'Tìm kiếm các máy chủ địa phương ${product} ...';
	@override String localMediaBrowserServers({required Object product}) => 'Địa phương ${product} máy chủ';
	@override String get username => 'Tên đăng nhập';
	@override String get password => 'Mật Khẩu';
	@override String get signIn => 'Đăng nhập';
	@override String get change => 'Thay đổi';
	@override String get required => 'cần thiết';
	@override String couldNotReachServer({required Object error}) => 'Không thể truy cập máy chủ: ${error}';
	@override String signInFailed({required Object error}) => 'Đăng ký thất bại: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect thất bại: ${error}';
	@override String get addPlexTitle => 'Đăng ký với Plex';
	@override String get pinExpired => 'PIN đã hết hạn trước khi đăng nhập. xin vui lòng thử lại.';
	@override String failedToRegisterAccount({required Object error}) => 'Không đăng ký tài khoản: ${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => 'Nhập URL máy chủ ${product} của bạn';
	@override String get addConnectionTitle => 'thêm liên kết';
	@override String addConnectionTitleScoped({required Object name}) => 'Thêm vào ${name}';
	@override String get signInWithPlexCard => 'Đăng ký với Plex';
	@override String get signInWithPlexCardSubtitle => 'Tùy chọn thiết bị này.Share server được thêm vào.';
	@override String get signInWithPlexCardSubtitleScoped => 'Tùy chọn tài khoản Plex. người dùng nhà trở thành hồ sơ.';
	@override String connectToMediaBrowserCard({required Object product}) => 'Kết nối với ${product}';
	@override String get connectToMediaBrowserCardSubtitle => 'Nhập URL, tên người dùng và mật khẩu máy chủ của bạn.';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => 'Đăng nhập vào máy chủ của bạn ${product}. kết nối với ${name}.';
	@override String get borrowFromAnotherProfile => 'Loan từ một hồ sơ khác';
	@override String get borrowFromAnotherProfileSubtitle => 'Sử dụng lại kết nối của hồ sơ khác. hồ sơ được bảo vệ bằng PIN đòi hỏi một PIN.';
	@override String get invalidCredentials => 'Tên người dùng hoặc mật khẩu không hợp lệ';
	@override String get authResponseNotJson => 'Trả lời xác thực không đúng JSON';
	@override String get authResponseIncomplete => 'Trả lời đăng nhập từ máy chủ là không đầy đủ';
	@override String get quickConnectRejected => 'Quick Connect đã bị từ chối bởi máy chủ';
	@override String get quickConnectNotJson => 'Câu trả lời Quick Connect không đúng JSON';
	@override String get quickConnectMissingFields => 'Câu trả lời Quick Connect thiếu mã hoặc bí mật';
	@override String get quickConnectPollRejected => 'Quick Connect truy vấn đã bị từ chối bởi máy chủ';
	@override String get serverTimedOut => 'Server không trả lời kịp thời';
	@override String get responseNotJson => 'Trả lời máy chủ không đúng JSON';
	@override String responseMissingIdentity({required Object product}) => 'Câu trả lời là thiếu một ID hoặc tên máy chủ - đây là máy chủ ${product}?';
	@override String probeFailed({required Object error}) => 'Không thể truy cập máy chủ: ${error}';
	@override String enterAtLeastOneUrl({required Object product}) => 'Nhập ít nhất một URL máy chủ ${product}';
	@override String noReachableServer({required Object product}) => 'Không tìm thấy máy chủ ${product} có thể truy cập';
	@override String urlsPointToDifferentServers({required Object product}) => 'Các URL này chỉ đến các máy chủ khác nhau ${product}';
	@override String urlDoesNotMatchServer({required Object product}) => 'URL này không phù hợp với máy chủ ${product}';
	@override String get redirectUnsupported => 'Server được chuyển hướng sang URL không được hỗ trợ';
	@override String redirectDifferentHost({required Object product}) => 'Server được chuyển hướng sang một host khác. nhập URL cuối cùng ${product} trực tiếp.';
	@override String get redirectInsecure => 'Server chuyển hướng từ HTTPS đến một URL không an toàn';
	@override String redirectUnsupportedEnterFinal({required Object product}) => 'Server được chuyển hướng sang một URL không được hỗ trợ. nhập URL cuối cùng ${product} trực tiếp.';
	@override String get directPlexServerUrl => 'Plex URL máy chủ';
	@override String get directPlexServerUrlHelper => 'Nhập IP và cổng địa phương của máy chủ truyền thông Plex của bạn.';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex Token (tùy chọn)';
	@override String get plexTokenHelper => 'Hãy để lại trống nếu truy cập mà không có auth được cho phép trên máy chủ này.';
	@override String get plexTokenRequired => 'Xin vui lòng nhập token Plex của bạn (X-Plex-Token).';
	@override String get connectDirectPlexCard => 'Plex Media Server (Thông tin trực tiếp / địa phương)';
	@override String get connectDirectPlexCardSubtitle => 'Kết nối trực tiếp bằng cách sử dụng địa phương IP hoặc URL mà không có tài khoản plex.tv.';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => 'Kết nối trực tiếp bằng cách sử dụng địa phương IP hoặc URL. Kết nối đến ${name}.';
	@override String get insecureTitle => 'Kết nối không mã hóa';
	@override String insecureDescription({required Object url}) => '${url} sử dụng HTTP. Người khác trên mạng có thể đọc hoặc thay đổi mật khẩu, mã thông báo và nội dung của bạn. Hãy dùng HTTPS nếu có. Chỉ tiếp tục nếu bạn tin tưởng mạng này và chấp nhận rủi ro.';
	@override String get allowHttp => 'Cho phép HTTP';
	@override String get httpsRequired => 'Sử dụng HTTPS hoặc rõ ràng cho phép kết nối không mã hóa.';
}

// Path: cast
class _Translations$cast$vi extends Translations$cast$en {
	_Translations$cast$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => 'Truyền đến thiết bị';
	@override String get searching => 'Tìm kiếm các thiết bị Cast...';
	@override String connectedTo({required Object device}) => 'Kết nối với ${device}';
	@override String get device => 'Thiết bị truyền';
	@override String get readyToCast => 'Sẵn sàng truyền';
	@override String get subtitle => 'Phụ đề';
	@override String get serverNotAvailable => 'Server phương tiện truyền thông không sẵn dùng.';
	@override String get stopCasting => 'Dừng truyền';
	@override String get castToDevice => 'Truyền đến thiết bị';
	@override String get noEpisodeAvailable => 'Không có tập nào có sẵn để phát.';
	@override String get startFailed => 'Không thể bắt đầu casting. kiểm tra máy chủ và thử lại.';
}

// Path: automation
class _Translations$automation$vi extends Translations$automation$en {
	_Translations$automation$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => 'Không có phiên video hoạt động để kiểm soát.';
}

// Path: notifications
class _Translations$notifications$vi extends Translations$notifications$en {
	_Translations$notifications$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => 'episode mới';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appAccess
class _Translations$appAccess$vi extends Translations$appAccess$en {
	_Translations$appAccess$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Cố gắng mọi tính năng miễn phí trong 7 ngày';
	@override String get description => 'Bắt đầu một cuộc thử nghiệm 7 ngày với quyền truy cập đầy đủ vào mỗi tính năng PlezyNG. không có phí trong cuộc thử nghiệm và không có đăng ký. sau khi thử nghiệm, một mua hàng suốt đời tại giá của cửa hàng của bạn sẽ mở khóa PlezyNG suốt đời.';
	@override String get trialEndedDescription => 'Khóa tất cả các tính năng trong PlezyNG cho đời với một mua tại giá của cửa hàng của bạn.';
	@override String get startTrial => 'Bắt đầu bài kiểm tra miễn phí 7 ngày';
	@override String get trialActive => 'Thử nghiệm đầy đủ 7 ngày của bạn đang hoạt động.';
	@override String get trialEnded => 'Cuộc thi 7 ngày đã kết thúc';
	@override String get trialStartFailed => 'Tôi không thể tiết kiệm thử nghiệm trên thiết bị này. xin vui lòng thử lại.';
	@override String get lifetimeTitle => 'PlezyNG mở khóa suốt đời';
	@override String get lifetimeBody => 'Cảm ơn bạn! bạn có quyền truy cập suốt đời cho mỗi tính năng PlezyNG.';
	@override String get manageTitle => 'PlezyNG Thời gian truy cập';
	@override String get manageDescription => 'Cố gắng mỗi tính năng miễn phí trong 7 ngày, sau đó mở khóa mọi thứ trong suốt đời với một khoản thanh toán với giá của cửa hàng của bạn.';
	@override String buy({required Object price}) => 'Khóa tất cả các tính năng cho ${price}';
	@override String get loadingPrice => 'Giá bán hàng tải...';
	@override String get retryPrice => 'Retry giá lookup';
	@override String get restore => 'Lợi ích mua sắm suốt đời';
	@override String get pending => 'Mua hàng của bạn đang chờ đợi thanh toán hoặc phê duyệt. truy cập suốt đời sẽ mở khóa ngay khi cửa hàng hoàn thành nó.';
	@override String get storeUnavailable => 'Kiểm tra rằng bạn đã đăng ký vào cửa hàng và mua hàng được phép trên thiết bị này.';
	@override String get productNotFound => 'Tính năng mở khóa PlezyNG vẫn chưa có sẵn trong cửa hàng này.';
	@override String get productQueryFailed => 'Không thể tải giá cửa hàng. kiểm tra kết nối của bạn và thử lại.';
	@override String get purchaseFailed => 'Mua sắm không qua được. thử lại.';
	@override String get restoreFailed => 'Tôi không thể đến cửa hàng để khôi phục mua hàng của bạn. thử lại.';
	@override String get nothingToRestore => 'Số PlezyNG mua hàng đời đã được tìm thấy cho tài khoản cửa hàng này.';
}

// Path: detail
class _Translations$detail$vi extends Translations$detail$en {
	_Translations$detail$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => 'Kết thúc tại ${time}';
}

// Path: watchLink
class _Translations$watchLink$vi extends Translations$watchLink$en {
	_Translations$watchLink$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => 'Tôi không thể truy cập một máy chủ Plex cho liên kết này.';
	@override String get notFound => 'Tôi không thể tìm thấy chương trình hoặc bộ phim này trên máy chủ của bạn Plex.';
	@override String get ambiguous => 'Liên kết này phù hợp với các mục trên nhiều hơn một máy chủ.Hãy thêm một máy chủ vào liên kết.';
	@override String get plexOnly => 'Các liên kết xem hiện chỉ hỗ trợ các máy chủ Plex.';
	@override String get unsupportedItem => 'Các liên kết xem chỉ có thể mở một chương trình hoặc một bộ phim.';
	@override String get menuItem => 'Xem link xem';
	@override String get dialogTitle => 'Xem link';
	@override String get dialogShowHint => 'Mở liên kết này sẽ chơi phần tiếp theo. Thêm &mode=shuffle vào cuối để chơi chương trình trên shuffle.';
	@override String get dialogMovieHint => 'Mở liên kết này chơi bộ phim.';
	@override String get copy => 'Sao chép';
	@override String get copied => 'Link sao chép';
}

// Path: homeLayout
class _Translations$homeLayout$vi extends Translations$homeLayout$en {
	_Translations$homeLayout$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trang chủ Layout';
	@override String get resetToast => 'Home Reset to the original Plezy anh hùng bố trí';
	@override String get resetHeroTitle => 'Đặt lại bố trí anh hùng để stock Plezy?';
	@override String get resetHeroBody => 'Nó xoay khỏi thiết lập anh hùng của mỗi hàng và mang lại một ban nhạc xoay duy nhất ở trên cùng của Nhà, giống như trước khi hàng anh hùng tồn tại.';
	@override String get removeRowTitle => 'Xóa dòng Home?';
	@override String removeRowBody({required Object title}) => '${title} sẽ bị xóa. điều này không thể bị bỏ qua.';
	@override String get sync => 'đồng bộ';
	@override String get syncAccountTitle => 'Đồng bộ hóa bố trí với tài khoản Plex của bạn';
	@override String get syncAccountOn => 'Trên: Thiết bị này chia sẻ lệnh hàng, hàng, Hero và Auto-slide với các thiết bị khác của bạn.';
	@override String get syncAccountOff => 'Tắt: Thiết bị này giữ bố trí của riêng mình.';
	@override String get syncNow => 'Sync hiện tại';
	@override String get plexHomeManager => 'Plex Nhà quản lý';
	@override String get managePlexRows => 'Quản lý Plex hàng trong Plezy';
	@override String get managePlexRowsDescription => 'Mở để tổ chức các dòng được chọn tại nhà';
	@override String get organizeHomeRows => 'Tổ chức Home Rows';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} hàng: di chuyển, Anh hùng, Auto-slide, loại bỏ';
	@override String organizeLibraryRows({required Object library}) => 'Tổ chức ${library} hàng';
	@override String organizeLibraryRowsDescription({required Object n}) => 'Tiếp tục xem + ${n} hàng: di chuyển, Thư viện, Nhà, Anh hùng, tự động-slide';
	@override String get renderAsHero => 'Render như một thẻ anh hùng';
	@override String get heroOnlySingleCollection => 'Chỉ có sẵn khi hàng này được giải quyết cho các tiêu đề thực tế của một bộ sưu tập duy nhất';
	@override String get hero => 'Anh hùng';
	@override String get autoSlide => 'tự động slide';
	@override String get autoSlideDescription => 'Lấy (PC) và d-pad (TV) luôn hoạt động và khởi động lại đồng hồ.';
	@override String get autoSlideEditDescription => 'Ngoài ra, nó tự nhảy mỗi vài giây. tắt: chỉ di chuyển khi bạn nhấp vào một mũi tên (PC) hoặc nhấn trái / phải trên từ xa (TV).';
	@override String get enableHeroFirst => 'Khả năng Hero đầu tiên';
	@override String get showOnHome => 'Hiển thị trên màn hình Home';
	@override String get home => 'Trang chủ';
	@override String get removeFromHome => 'Xóa khỏi nhà';
	@override String get selectRowsFirst => 'Chọn dòng Home bên dưới trước.';
	@override String plexManagedRows({required Object n}) => '${n} Plex hàng quản lý';
	@override String get continueWatching => 'Tiếp tục xem';
	@override String get continueWatchingLibraryDescription => 'Thư viện bản thân của dòng tiến bộ';
	@override String get continueWatchingHomeDescription => 'Lời bài hát: The Resume-Progress Trail Showed On Home';
	@override String get nextUpHomeDescription => 'Next Unwatched episode series hiển thị riêng biệt trên Home';
	@override String get library => 'Thư viện';
	@override String get showInRecommended => 'Hiển thị trong Thư viện khuyến cáo';
	@override String get customPlexRow => 'Tính năng: Plex';
	@override String get heroNeedsLibrary => 'Kiểm tra Thư viện đầu tiên — Hero cần một nơi nào đó để hiển thị';
	@override String get heroNeedsSurface => 'Kiểm tra Thư viện hoặc Nhà đầu tiên — Anh hùng cần một nơi nào đó để hiển thị';
	@override String get removeHub => 'Xóa Hub';
	@override String get noPlexRows => 'Số Plex hàng quản lý đã trở lại cho thư viện này.';
	@override String get openDetails => 'chi tiết mở';
	@override String get heroCards => 'thẻ anh hùng';
	@override String get tapHeroCard => 'Tải thẻ anh hùng';
	@override String get tvPlayFocus => 'TV từ xa: nhấn nút Play';
	@override String get tvPlayFocusDescription => 'D-pad xuống dừng lại trên nút Play trước khi di chuyển đến hàng tiếp theo.';
	@override String get tvWrap => 'TV từ xa: loop hero cards';
	@override String get tvWrapDescription => 'Ngay trên thẻ cuối cùng đi trở lại thẻ đầu tiên. off dừng ở thẻ cuối cùng. trái trên thẻ đầu tiên luôn đi đến thanh bên.';
	@override String get castOnHero => 'Lời bài hát: Hero Banner';
	@override String get castOnHeroDescription => 'Hiển thị bản vẽ dọc theo đáy của một banner anh hùng. Off giữ chỉ tiêu đề và tổng hợp.';
	@override String get customRows => 'Custom dòng';
	@override String get loading => 'Trang chủ » Layout ...';
	@override String get noCustomRows => 'Không có dòng tiêu chuẩn';
	@override String get addRowHint => 'Sử dụng Add Home row để tạo một.';
	@override String get addHomeRow => 'Thêm Home Row';
	@override String get addHomeRowDescription => 'Chọn một thể loại; dòng mới được thêm vào Nhà tổ chức tự động';
	@override String get removeRow => 'Xóa dòng';
	@override String get recentlyAdded => 'Thêm Gần Đây';
	@override String get recentlyReleased => 'Gần đây phát hành';
	@override String get movieCollections => 'Bộ sưu tập phim';
	@override String get showCollections => 'Hiển thị bộ sưu tập';
	@override String get rowTitle => 'Row tiêu đề';
	@override String get content => 'Nội dung';
	@override String get showThisRowIn => 'Hiển thị dòng này trong:';
	@override String get libraryRecommended => 'Thư viện khuyến cáo';
	@override String get heroCard => 'thẻ anh hùng';
	@override String get heroCardDescription => 'Hiển thị như một thẻ quay rộng đầy đủ thay vì một tấm poster.';
	@override String get heroUnavailableDescription => 'Chỉ có sẵn khi hàng này được giải quyết với các tiêu đề thực tế của một bộ sưu tập duy nhất - với nhiều hơn một bộ sưu tập được chọn không có tiêu đề duy nhất để xoay qua.';
	@override String get librariesSelection => 'Thư viện (tìm tất cả không kiểm tra để bao gồm mỗi thư viện)';
	@override String get librariesMergedDescription => 'Mỗi thư viện được kiểm tra ở đây được kết hợp vào một hàng này.';
	@override String get movieCollectionsSelection => 'Bộ sưu tập phim (tìm tất cả không kiểm tra cho mỗi thư viện được chọn)';
	@override String get showCollectionsSelection => 'Hiển thị các bộ sưu tập (tìm tất cả không kiểm tra cho mỗi thư viện được chọn)';
	@override String get collectionRowsDescription => 'Nếu chính xác một bộ sưu tập phù hợp, các tiêu đề của nó hiển thị trực tiếp trong hàng. Nếu nhiều hơn một bộ sưu tập phù hợp, mỗi bộ sưu tập hiển thị như một poster duy nhất — nhấn vào nó để mở bộ sưu tập đó.';
	@override String get allCollections => 'Tất cả bộ sưu tập';
	@override String get noRowsHere => 'Hiện chưa có dòng nào ở đây.';
	@override String get hideWatchedRows => 'Ẩn các mục được xem trong hàng';
	@override String get hideWatchedRowsDescription => 'Các tiêu đề được xem đầy đủ rời khỏi Nhà và Thư viện Các dòng được đề xuất.';
	@override String get untitledCollection => 'Lời bài hát Untitled Collection';
	@override String get moveRowHint => 'Up/Down: move row · Select: drop it here · Back: cancell';
	@override String get organizeRowsHint => 'Chọn theo một hàng (hoặc giữ Chọn): di chuyển nó · Trái/Trái: tùy chọn hàng · Trở lại: hoàn thành';
	@override String get layoutNavDescription => 'Chọn hàng, thư viện, và thể loại thu thập';
	@override String get editHomeRow => 'Trang chủ Edit';
	@override String get resetHeroButton => 'Đặt lại bản bố trí anh hùng để stock Plezy';
	@override String get reorderingUnlocked => 'Đặt lại Unlocked';
	@override String get reorderingLocked => 'Đặt lại khóa';
	@override String get rowsCanBeDragged => 'Các dây có thể được kéo — nhấn khóa để ngăn chặn';
	@override String get tapLockToDrag => 'Nhấn khóa để kéo hàng';
	@override String customRowLabel({required Object title}) => 'Số lượng: ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => 'Ẩn';
	@override String get remove => 'Gỡ bỏ';
	@override String get libraryResumeRow => 'Thư viện của thư viện này';
	@override String get pressAgainToDelete => 'Nhấn lại để xóa';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => 'trên';
	@override String get resetHeroButtonDescription => 'Nó xoay khỏi thiết lập anh hùng của mỗi hàng và mang lại một banner xoay duy nhất ở phía trên, giống như trước khi hàng anh hùng tồn tại.';
	@override String get tapHeroCardDescription => 'Chọn xem đánh hoặc chọn một thẻ Hero bắt đầu phát lại hay mở chi tiết của nó.';
	@override String get heroTapPlayDescription => 'Bắt đầu mục được chọn ngay lập tức.';
	@override String get heroTapDetailsDescription => 'Mở chi tiết của mục được chọn trước khi chọn một hành động.';
}

// Path: platform
class _Translations$platform$vi extends Translations$platform$en {
	_Translations$platform$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'PlezyNG kết nối với máy chủ truyền thông và thiết bị phát lại trên mạng địa phương của bạn.';
	@override String get locationPermission => 'PlezyNG sử dụng quyền truy cập vị trí khi iOS yêu cầu nó để phát hiện mạng lưới địa phương của bạn và kết nối với máy chủ truyền thông của bạn.';
	@override String get photoLibraryPermission => 'Chọn hình ảnh từ thư viện ảnh của bạn để sử dụng như một công việc nghệ thuật phương tiện truyền thông.';
	@override String get cameraPermission => 'Scan mã QR để kết hợp một Companion Remote.';
}

// Path: universalMedia
class _Translations$universalMedia$vi extends Translations$universalMedia$en {
	_Translations$universalMedia$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'phương tiện truyền thông mở';
	@override String get shortcutHelp => 'Chơi một liên kết, danh sách chơi hoặc tệp cho phiên này.';
	@override String get intro => 'Mở một liên kết, danh sách phát hoặc tệp. Playback sử dụng người chơi tiêu chuẩn của PlezyNG và không thêm lịch sử vào thư viện của bạn.';
	@override String get openWhat => 'Bạn muốn mở cái gì?';
	@override String get stream => 'Địa chỉ Stream';
	@override String get playlist => 'Danh sách Playlist';
	@override String get files => 'Thiết bị file';
	@override String get favorites => 'Save Stream yêu thích';
	@override String get address => 'Địa chỉ Media';
	@override String get addressHelp => 'URL với các thông số xác nhận hoặc ký tự được công nhận chỉ được sử dụng cho phiên này và không thể được lưu như là yêu thích.';
	@override String get displayName => 'Tên hiển thị (tùy chọn)';
	@override String get displayNameHelp => 'Chọn tên ngắn cho người chơi và hệ thống điều khiển phương tiện truyền thông.';
	@override String get allowHttp => 'Cho phép kết nối HTTP không được mã hóa';
	@override String get allowHttpHelp => 'HTTP không mã hóa kết nối. Chỉ cho phép nó trên một mạng tin cậy. Sử dụng HTTPS khi có thể.';
	@override String get advancedProtocols => 'Chỉ MPV: nhập một địa chỉ RTSP, RTMP/RTMPS, UDP hoặc RTP. Các địa chỉ này không thể được lưu như là yêu thích.';
	@override String get liveStream => 'Chăm sóc như sống';
	@override String get liveStreamHelp => 'Sử dụng điều này cho video hay radio trực tiếp. Ứng dụng che giấu thanh thời gian, nhấp chuột và tùy chọn go-to-time.';
	@override String get privateSession => 'Chỉ bài phát này sử dụng địa chỉ.Save an eligible stream favorite to keep it in this profile.';
	@override String get saveFavorite => 'Giữ yêu thích';
	@override String get playNow => 'Chơi bây giờ';
	@override String get favoriteSaved => 'Stream Favorite được tiết kiệm đến hồ sơ này';
	@override String skippedEntries({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n,
		other: 'Tắt ${count} không được hỗ trợ hoặc không an toàn danh sách đăng nhập.',
	);
	@override String get playlistAddress => 'Địa chỉ Playlist';
	@override String get playlistAddressHelp => 'Mở một danh sách chơi M3U, M3u8, hoặc PLS từ địa chỉ web. liên kết trực tiếp không lưu danh sách playlist.';
	@override String get choosePlaylist => 'Chọn playlist file';
	@override String get openPlaylist => 'playlist mở';
	@override String get playlistFormatsHelp => 'Một danh sách phát có thể chứa tối đa 1.000 mục và 2 MB. HLS hiển thị mở như dòng để người chơi có thể chọn một chất lượng.';
	@override String get saveQueuePlaylist => 'Lưu hàng đợi thành danh sách phát';
	@override String get queuePlaylistSaved => 'Danh sách phát đã được lưu cạnh các tệp phương tiện.';
	@override String get queuePlaylistUnavailable => 'Không thể lưu hàng đợi này thành danh sách phát cục bộ để dùng lại.';
	@override String get queuePlaylistFolderRequired => 'Chọn vị trí lưu trong cùng thư mục với các tệp trong hàng đợi.';
	@override String get noFavorites => 'Không được lưu stream yêu thích cho đến nay. Favorites stay in this profile.';
	@override String get removeFavorite => 'Xóa stream yêu thích';
	@override String get filesHelp => 'Chọn các tệp âm thanh, video hoặc ISO cho một cặp tạm thời. tệp và URL không được thêm vào lịch sử thư viện.';
	@override String get chooseFiles => 'Chọn file';
	@override String fileQueue({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n,
		other: '${count} tập tin được chọn',
	);
	@override String get wifiTransfer => 'Gửi file qua Wi-Fi';
	@override String get wifiTransferHelp => 'Chuyển các tập tin được hỗ trợ từ một trình duyệt trên cùng một mạng đáng tin cậy.';
	@override String get wifiTransferIntro => 'Mở địa chỉ này trong một trình duyệt trên thiết bị khác.Chọn các tệp để thêm chúng vào thư viện tệp và sách của thiết bị này.';
	@override String get wifiTransferPrivacy => 'Thiết bị này nhận được tệp qua mạng địa phương của bạn. bất cứ ai biết địa chỉ này có thể gửi tệp cho đến khi bạn ngừng chuyển giao hoặc địa chỉ hết hạn sau 15 phút. tối đa: 100 tệp, 4 GiB mỗi tệp; tổng cộng 10 GiB.';
	@override String get wifiTransferStarting => 'Chuẩn bị một chuyển giao riêng, thời gian giới hạn...';
	@override String get wifiTransferUnavailable => 'Không thể bắt đầu chuyển giao. kiểm tra truy cập mạng địa phương và thử lại.';
	@override String get openThisAddress => 'Mở một trong những địa chỉ này trên thiết bị gửi';
	@override String get copyAddress => 'Bản sao địa chỉ chuyển đổi';
	@override String get addressCopied => 'Địa chỉ chuyển đổi sao chép';
	@override String transferExpires({required Object time}) => 'Địa chỉ này hết hạn trong ${time}.';
	@override String uploadCount({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n,
		other: '${count} file nhận được',
	);
	@override String uploadedData({required Object size}) => 'Nhận ${size}';
	@override String get stopTransfer => 'Ngừng chuyển giao và vô hiệu hóa địa chỉ';
	@override String get startTransfer => 'Bắt đầu chuyển giao';
	@override String get wifiImportedFiles => 'Chuyển Wi-Fi';
	@override String get wifiBrowserTitle => 'Gửi file đến PlezyNG';
	@override String get wifiBrowserIntro => 'Chọn các tập tin âm thanh, video, ebook hoặc truyện tranh để gửi. Các tập tin được lưu trữ trong thư viện tệp và sách của thiết bị này. Tối đa: 100 tập tin, 4 GiB mỗi file, tổng cộng 10 GiB.';
	@override String get uploadFilesLabel => 'file để gửi';
	@override String get uploadSelected => 'Tải các tập tin được chọn';
	@override String get uploadSelectFirst => 'Chọn một hoặc nhiều tập tin đầu tiên.';
	@override String get uploading => 'gửi';
	@override String get uploadComplete => 'File được thêm vào PlezyNG.';
	@override String get uploadFailed => 'Tệp không thể được thêm vào. giữ cho trang này mở và thử lại.';
	@override String get liveCue => 'Sống';
	@override String get liveSession => 'Stream trực tiếp';
	@override String get liveCueHelp => 'Đối với video hay radio trực tiếp, ứng dụng ẩn thanh thời gian và nhảy nút. nó không lưu địa chỉ hoặc xem lịch sử.';
	@override String get sessionOnly => 'Playback này là session-only';
	@override String get sessionOnlyHelp => 'Playback không bao giờ tiết kiệm tiến bộ hoặc lịch sử.Save the stream as a favorite to keep it in this profile if it is eligible.';
	@override String get pictureAdjustments => 'hình ảnh điều chỉnh';
	@override String get pictureHelp => 'Những thay đổi hình ảnh này chỉ ảnh hưởng đến playback này. họ đặt lại khi playback kết thúc.';
	@override String get resetPicture => 'Reset hình ảnh';
	@override String get brightness => 'Ánh sáng';
	@override String get contrast => 'Ngược điểm';
	@override String get gamma => 'Gamma';
	@override String get hue => 'Hue';
	@override String get saturation => 'Saturation';
	@override String get view360 => 'Màn hình 360° video';
	@override String get view360Help => 'Sử dụng điều này cho video 360° đồng chiều. MPV cần bộ lọc v360 của FFmpeg để xem.';
	@override String get view360Unavailable => 'Thiết lập MPV này không thể áp dụng bộ lọc 360°.';
	@override String get view360Yaw => 'tầm nhìn chân trời';
	@override String get view360Pitch => 'Màn hình Vertical View';
	@override String get view360FieldOfView => 'Vùng tầm nhìn';
	@override String get recordStream => 'Đánh giá Live Stream';
	@override String get stopRecording => 'Ngừng và tiết kiệm ghi âm';
	@override String get recordingStarted => 'Ghi âm là hoạt động.Leaving playback stops and saves the recording.';
	@override String get recordingSaved => 'Ghi âm được hoàn thành và tiết kiệm.';
	@override String get recordingActive => 'Để lại playback dừng lại và tiết kiệm nó.';
	@override String get recordingFormatHelp => 'Đối với video, chọn MKV hoặc MPEG-TS. Đối với âm thanh, chọn MKA hoặc MKV.';
	@override String get replaceRecordingTitle => 'Thay thế bản ghi này?';
	@override String get replaceRecordingHelp => 'PlezyNG sao lưu tệp hiện có trong khi ghi lại. nếu nó không thể tiết kiệm bản ghi mới, Plezyng khôi phục sao lưu.';
	@override String get replaceRecording => 'Thay thế file';
	@override String get discHelp => 'Mở một đĩa trong ổ đĩa quang của máy tính này. Bạn cũng có thể mở hình ảnh ISO từ các tệp thiết bị.';
	@override String get discs => 'Đĩa Optical';
	@override String get editionOrTitle => 'Ấn bản hoặc tên đĩa';
	@override String get dvd => 'DVD';
	@override String get bluray => 'Đánh giá Blu-ray';
	@override String get audioCd => 'CD âm thanh';
	@override String get discAvailability => 'Đĩa playback cần một cấu trúc MPV tương thích, ổ đĩa được hỗ trợ và giấy phép hệ điều hành. nó không thể vượt qua bảo vệ đĩa thương mại.';
	@override String get converterTitle => 'Chuyển đổi một tập tin phương tiện truyền thông địa phương';
	@override String get converterHelp => 'Chuyển đổi một tệp địa phương hoặc sửa lại nó với FFmpeg.';
	@override String get converterIntro => 'Chuyển đổi một tệp âm thanh hoặc video địa phương sang định dạng hoạt động trên nhiều thiết bị.';
	@override String get converterPrivacy => 'FFmpeg phải được cài đặt trên máy tính này. chuyển đổi chỉ đọc các tập tin địa phương. nó không tải về dòng hoặc loại bỏ DRM.';
	@override String get converterChooseInput => 'Chọn một tập tin phương tiện truyền thông địa phương';
	@override String get converterFormat => 'định dạng output';
	@override String get converterMp4 => 'MP4 · H.264 và AAC';
	@override String get converterM4a => 'M4A · AAC âm thanh';
	@override String get converterMp3 => 'MP3 - Âm thanh';
	@override String get allowFtp => 'Khả năng FTP';
	@override String get allowFtpHelp => 'FTP gửi các phương tiện truyền thông mà không có mã hóa. sử dụng chỉ trên mạng tin cậy.';
	@override String get converterSaveAs => 'Lưu các phương tiện truyền thông được chuyển đổi như';
	@override String get converterExtensionMismatch => 'Chọn tên file với phần mở rộng output được chọn.';
	@override String get converterUnsupportedInput => 'Chọn một file audio hoặc video.';
	@override String get converterLocalOnly => 'Tệp được chọn không có sẵn như một con đường thiết bị địa phương.';
	@override String get converterReplaceTitle => 'Thay thế file này?';
	@override String get converterReplaceHelp => 'PlezyNG khôi phục lại tệp hiện có cho đến khi bản sao được chuyển đổi được lưu.';
	@override String get converterStarting => 'Bắt đầu FFmpeg...';
	@override String get converterProgress => 'Chuyển đổi vào máy tính này...';
	@override String get converterComplete => 'Chuyển đổi hoàn thành. file mới đã sẵn sàng.';
	@override String get converterFfmpegMissing => 'FFmpeg thiếu hoặc không hỗ trợ định dạng này.';
	@override String get converterFailed => 'Chuyển đổi thất bại. kiểm tra rằng tệp nguồn có thể được đọc và điểm đến có đủ không gian miễn phí.';
	@override String get converterCancelled => 'Chuyển đổi đã bị hủy; Kết quả không đầy đủ đã được loại bỏ.';
	@override String get converterDesktopOnly => 'Chuyển đổi địa phương có sẵn trên máy tính bảng với FFmpeg cài đặt.';
	@override String get converterStart => 'chuyển đổi file';
	@override String get mediaToolsTitle => 'Công cụ Media';
	@override String get mediaToolsShortcut => 'Ghi hoặc chia sẻ phương tiện truyền thông, thêm phần mở rộng tìm kiếm, hoặc sử dụng dòng lệnh.';
	@override String get mediaToolsIntro => 'Chọn một công cụ tập trung. chụp và stream-out sử dụng FFmpeg được cài đặt trên máy tính để bàn này. Extensions và CLI lệnh sử dụng giới hạn yêu cầu HTTPS và dòng Open media hiện có.';
	@override String get mediaToolsAccessibility => 'Các công cụ lựa chọn và điều khiển làm việc với touch, point, keyboard, và D-pad tập trung. ghi âm, chia sẻ, và các thay đổi trạng thái tìm kiếm được công bố.';
	@override String get mediaTool => 'Công cụ Media';
	@override String get captureIntro => 'Ghi lại màn hình hoặc máy ảnh của bạn vào một tệp MP4 trên máy tính này. FFmpeg phải được cài đặt và bao gồm mã hóa H.264.';
	@override String get captureNoDevices => 'Không tìm thấy màn hình hoặc máy ảnh. kiểm tra hỗ trợ chụp FFmpeg và quyền riêng tư hệ điều hành.';
	@override String get captureSource => 'màn hình hoặc camera';
	@override String get captureScreen => 'màn hình';
	@override String get captureAudioSource => 'Audio input (tùy chọn)';
	@override String get captureAudioHelp => 'Thêm âm thanh từ microphone hoặc input có sẵn. lựa chọn thiết bị phụ thuộc vào FFmpeg và quyền hệ thống.';
	@override String get captureAudioNone => 'Không có Audio';
	@override String get captureDefaultAudio => 'Lập trình Audio Input';
	@override String get captureWaylandHelp => 'Wayland giới hạn thu thập XWayland này đến X display. Windows bên ngoài XWayland có thể không xuất hiện.';
	@override String get captureFrameRate => 'Tỷ lệ ghi âm frame rate';
	@override String get capturePrivacy => 'Ghi âm được lưu chỉ cho tệp bạn chọn. microphone capture là tùy chọn. PlezyNG không tải lên ghi âm.';
	@override String get captureSaveAs => 'Lưu màn hình ghi âm như';
	@override String get captureExtensionMismatch => 'Chọn tên file kết thúc trong .mp4.';
	@override String get captureFfmpegMissing => 'FFmpeg hoặc mã hóa video H.264 không sẵn dùng. cài đặt một xây dựng FFmpeg được hỗ trợ, sau đó thử lại.';
	@override String get captureFailed => 'Kiểm tra giấy phép thiết bị, lưu trữ có sẵn, và hỗ trợ FFmpeg.';
	@override String get captureSaved => 'Màn hình ghi âm được tiết kiệm';
	@override String get captureElapsedLabel => 'Thời gian ghi âm';
	@override String get captureStart => 'Bắt đầu ghi âm';
	@override String get capturePreview => 'Xem trước trong trình phát';
	@override String get capturePreviewHelp => 'Xem trước nguồn đã chọn trong trình phát thông thường. Bản xem trước chỉ tồn tại trong phiên này và không lưu bản ghi. Hỗ trợ thiết bị và quyền truy cập tùy thuộc vào MPV và hệ điều hành. Bản xem trước chỉ dùng video; bản ghi đã lưu có thể kèm âm thanh tùy chọn.';
	@override String get capturePreviewActive => 'Xem trước trực tiếp · không ghi hình';
	@override String get captureStop => 'Stop và Save';
	@override String get captureMode => 'bắt giữ';
	@override String get shareMode => 'chia sẻ';
	@override String get shareIntro => 'Gửi một tệp phương tiện truyền thông địa phương đến một thiết bị khác trên mạng riêng của bạn. PlezyNG tạo ra một dòng HLS tạm thời.';
	@override String get sharePrivacy => 'Bất cứ ai trên mạng địa phương của bạn nhận được liên kết tư nhân có thể xem trong khi nó hoạt động. liên kết hết hạn sau 60 phút. ngừng chia sẻ để đóng máy chủ và vô hiệu hóa liên kết.';
	@override String get shareChooseFile => 'Chọn file media';
	@override String get shareChooseHelp => 'Chọn một tệp âm thanh hoặc video địa phương. tệp vẫn ở trên máy tính này.';
	@override String get shareFfmpegMissing => 'FFmpeg hoặc các mã hóa H.264/AAC không sẵn dùng. cài đặt FFmpeg với hỗ trợ mã hóa H.264 và AAC.';
	@override String get shareFailed => 'Stream không thể bắt đầu hoặc dừng lại bất ngờ. kiểm tra FFmpeg và truy cập mạng.';
	@override String get shareActive => 'Stream đã sẵn sàng trên mạng riêng của bạn.';
	@override String get shareEnded => 'Truyền thông đã đạt đến kết thúc và không còn được chia sẻ nữa.';
	@override String get shareStopped => 'Chia sẻ dừng lại. liên kết tạm thời không còn hợp lệ.';
	@override String get shareUrlCopied => 'Địa chỉ dòng được sao chép.';
	@override String get shareOpenUrl => 'Mở địa chỉ này trong một người chơi trên thiết bị khác';
	@override String get shareQrLabel => 'Mã QR cho địa chỉ dòng tạm thời';
	@override String get shareQrHelp => 'Scan với một người chơi tương thích kết nối với cùng một mạng tư nhân.';
	@override String get shareHttpHint => 'Stream này sử dụng HTTP không được mã hóa. trong PlezyNG, cho phép HTTP trước khi mở nó.';
	@override String get shareCopyUrl => 'Bản sao Stream Address';
	@override String get shareExpiresLabel => 'Link kết thúc tại';
	@override String get shareStarting => 'Chuẩn bị dòng chảy...';
	@override String get shareStart => 'Bắt đầu chia sẻ';
	@override String get shareStop => 'Ngừng chia sẻ';
	@override String get extensionsMode => 'Tăng cường và CLI';
	@override String get extensionsIntro => 'Thêm một phần mở rộng chỉ tìm kiếm dữ liệu để tìm các phương tiện truyền thông. Chọn kết quả để tải nó vào biểu mẫu quen thuộc Open media.';
	@override String get extensionsPrivacy => 'Một biểu hiện có thể xác định một HTTPS tìm kiếm kết thúc và các trường phản ứng bản đồ. nó không thể chạy mã, thêm tiêu đề yêu cầu, đọc các tệp, hoặc lệnh khởi động shell.';
	@override String get extensionImport => 'Thêm Extension Manifest';
	@override String get extensionEmpty => 'Chưa có dịch vụ tìm kiếm cho đến nay. chọn một tệp hiển thị đáng tin cậy JSON để thêm một.';
	@override String get extensionChoose => 'Dịch vụ tìm kiếm';
	@override String get extensionSearchConsent => 'Mỗi tìm kiếm gửi từ của bạn đến dịch vụ HTTPS này. kết quả chỉ mở sau khi bạn chọn một.';
	@override String get extensionSearchLabel => 'Tìm kiếm Media';
	@override String get extensionSearch => 'Tìm kiếm';
	@override String get extensionSearching => 'Tìm kiếm...';
	@override String get extensionNoResults => 'Không có kết quả truyền thông an toàn đã được trả về.Cần tìm kiếm thêm.';
	@override String get extensionInstallTitle => 'Thêm dịch vụ tìm kiếm này?';
	@override String get extensionReplaceTitle => 'Cập nhật dịch vụ tìm kiếm này?';
	@override String get extensionService => 'Dịch vụ';
	@override String get extensionEndpoint => 'HTTPS điểm cuối';
	@override String get extensionConsent => 'Văn bản tìm kiếm của bạn được gửi đến dịch vụ này.Manifest không chứa mã thực hiện.Hãy tiếp tục chỉ nếu bạn tin tưởng vào điểm kết thúc này.';
	@override String get extensionInstall => 'thêm dịch vụ';
	@override String get extensionReplace => 'Update dịch vụ';
	@override String get extensionRemoveTitle => 'Xóa dịch vụ tìm kiếm này?';
	@override String get extensionRemoveHelp => 'Điều này loại bỏ dịch vụ khỏi hồ sơ này.PlezyNG không liên hệ với điểm kết thúc của nó.';
	@override String get extensionRemove => 'Xóa dịch vụ';
	@override String get extensionInvalidManifest => 'Tệp này không phải là một biểu hiện mở rộng được hỗ trợ. xem hướng dẫn Open media cho định dạng.';
	@override String get extensionSaveFailed => 'Việc mở rộng không thể được lưu vào hồ sơ hoạt động.';
	@override String get extensionSearchFailed => 'Dịch vụ tìm kiếm không trả lại câu trả lời đúng. kiểm tra điểm kết thúc và thử lại.';
	@override String get cliTitle => 'Command dòng';
	@override String get cliHelp => 'Sử dụng hướng dẫn plezyctl để xác nhận một biểu hiện hoặc tìm kiếm cùng một phần mở rộng. Xem lại dịch vụ HTTPS của nó trước mỗi tìm kiếm. Kết quả mở trong biểu mẫu phương tiện hiện có; chọn nút playback để bắt đầu.';
	@override String get cliCopyExample => 'copy command ví dụ';
	@override String get cliCopied => 'Lệnh ví dụ sao chép.';
}

// Path: fileSources
class _Translations$fileSources$vi extends Translations$fileSources$en {
	_Translations$fileSources$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'File và sách';
	@override String get subtitle => 'Đọc, lắng nghe, và xem từ các tệp của riêng bạn.';
	@override String get add => 'thêm nguồn';
	@override String get importFiles => 'nhập file';
	@override String get localFiles => 'Trên thiết bị này';
	@override String get source => 'Nguồn';
	@override String get name => 'Tên';
	@override String get endpoint => 'URL máy chủ';
	@override String get smbEndpointHint => 'Ví dụ: smb://nas/Movies';
	@override String get smbEndpointInvalid => 'Nhập một máy chủ SMB và một thư mục chia sẻ.';
	@override String get root => 'Folder hoặc Prefix';
	@override String get smbFolderHelp => 'Để trống để dùng toàn bộ thư mục chia sẻ, hoặc nhập một thư mục bên trong.';
	@override String get username => 'Tên đăng nhập';
	@override String get smbDomain => 'Miền (không bắt buộc)';
	@override String get password => 'Mật Khẩu';
	@override String get token => 'API Đánh giá';
	@override String get accessKey => 'Access Key ID';
	@override String get secretKey => 'Key Access bí mật';
	@override String get sessionToken => 'Session token (tùy chọn)';
	@override String get region => 'Khu vực';
	@override String get clientId => 'ID khách hàng OAuth';
	@override String get clientSecret => 'OAuth Client Secret (chỉ Google Desktop)';
	@override String get allowHttp => 'Cho phép HTTP không mã hóa trên mạng đáng tin cậy';
	@override String get smbEncryption => 'Mã hóa kết nối SMB3';
	@override String get smbEncryptionHint => 'Dùng mã hóa SMB3 khi NAS hỗ trợ.';
	@override String get connect => 'Kết nối';
	@override String get cancel => 'Hủy bỏ';
	@override String get save => 'Lưu';
	@override String get close => 'Đóng';
	@override String get removeSource => 'Nguồn Disconnect';
	@override String get disconnectMessage => 'Ngắt kết nối nguồn này? Các tệp đã tải xuống cùng lịch sử đọc và nghe sẽ vẫn được giữ trên thiết bị này.';
	@override String get localFolder => 'Chọn folder';
	@override String get empty => 'Chưa có gì ở đây';
	@override String get emptyHint => 'Thêm một nguồn hoặc nhập một cuốn sách, cuốn sách âm thanh, âm nhạc hoặc video.';
	@override String get search => 'Tìm kiếm folder này';
	@override String get searchCached => 'Tìm kiếm thư viện cứu';
	@override String get refresh => 'Làm mới';
	@override String get loadMore => 'tải thêm';
	@override String get offline => 'Có sẵn offline';
	@override String get download => 'giữ offline';
	@override String get removeDownload => 'Xóa bản sao offline';
	@override String get continueReading => 'Tiếp tục đọc';
	@override String get continueListening => 'Tiếp Tục Nghe';
	@override String get continueWatching => 'Tiếp tục xem';
	@override String get read => 'Đọc';
	@override String get listen => 'nghe';
	@override String get play => 'Phát';
	@override String get pause => 'Tạm dừng';
	@override String get stop => 'Ngưng';
	@override String get startOver => 'Bắt đầu qua';
	@override String get finished => 'Kết thúc';
	@override String get markFinished => 'Mark kết thúc';
	@override String get markUnfinished => 'Mark chưa hoàn thành';
	@override String get editions => 'Phiên bản và file';
	@override String get chapters => 'Chương 1';
	@override String get bookmarks => 'Bookmarks và Note';
	@override String get bookmark => 'Thêm Bookmark';
	@override String get highlight => 'Đánh giá';
	@override String get note => 'Ghi chú';
	@override String get delete => 'Xóa';
	@override String get export => 'Export ghi chú';
	@override String get exported => 'Các ghi chú xuất khẩu';
	@override String get sync => 'Sync tiến bộ';
	@override String get synced => 'tiến bộ synchronized';
	@override String get conflict => 'Một thiết bị khác có vị trí khác. chọn nơi để tiếp tục.';
	@override String get useLocal => 'Sử dụng thiết bị này';
	@override String get useRemote => 'Sử dụng các thiết bị khác';
	@override String get history => 'Lịch sử vị trí';
	@override String get groupAudio => 'Lắng nghe như một cuốn sách âm thanh';
	@override String get groupHint => 'Kết hợp các tệp âm thanh hiện đang được tải vào thư mục này. tải tất cả các trang trước.';
	@override String get order => 'File Order Đơn';
	@override String get moveUp => 'chuyển lên';
	@override String get moveDown => 'di chuyển xuống';
	@override String get speed => 'Tốc Độ Phát';
	@override String get sleep => 'Giấc ngủ Timer';
	@override String get sleepOff => 'Tắt';
	@override String get endChapter => 'Cuối chương';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(count,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} phút',
	);
	@override String get skipBack => 'Skip trở lại';
	@override String get skipForward => 'Skip đi trước';
	@override String get smartRewind => 'Lợi ích của Smart Revenue sau một nghỉ ngơi';
	@override String get playbackOptions => 'Lắng nghe các tùy chọn';
	@override String remaining({required Object time}) => '${time} còn lại';
	@override String get contents => 'Nội dung';
	@override String get readerSettings => 'Đọc Settings';
	@override String get fontSize => 'Cỡ chữ';
	@override String get lineHeight => 'Line không gian';
	@override String get margin => 'Lề';
	@override String get font => 'Typeface hình';
	@override String get serif => 'Có chân';
	@override String get sans => 'Không có serif';
	@override String get mono => 'Đơn cách';
	@override String get columns => 'Cột';
	@override String get scroll => 'Cuộn dọc';
	@override String get justify => 'Căn đều hai bên';
	@override String get readerTheme => 'Trang xuất hiện';
	@override String get appTheme => 'Theo dõi app theme';
	@override String get paper => 'giấy';
	@override String get sepia => 'Sepia';
	@override String get night => 'đêm';
	@override String get readAloud => 'Đọc to trang này';
	@override String get readAlong => 'Đọc theo lời đọc';
	@override String get stopReading => 'Ngừng kể chuyện';
	@override String get searchBook => 'Tìm kiếm trong sách';
	@override String get noMatches => 'Không trận đấu';
	@override String get previousPage => 'Trang trước';
	@override String get nextPage => 'Trang sau';
	@override String page({required Object number}) => 'Trang ${number}';
	@override String get externalBlocked => 'Các liên kết sách bên ngoài bị vô hiệu hóa trong người đọc.';
	@override String get loading => 'Mở...';
	@override String get narrator => 'Tác giả';
	@override String get audio => 'Âm thanh';
	@override String get video => 'Video';
	@override String get ebooks => 'Ebook';
	@override String get all => 'Tất cả';
	@override String get downloads => 'Offline file';
	@override String get confirmDelete => 'Xóa bản sao ngoại tuyến đã chọn? Vị trí đọc hoặc nghe và ghi chú của bạn vẫn được giữ lại.';
	@override String get errorAuthentication => 'Đăng nhập lại để nối lại nguồn này.';
	@override String get errorPermission => 'Nguồn này không cho phép truy cập vào tệp yêu cầu.';
	@override String get errorUnavailable => 'Nguồn không sẵn dùng.Chiên thử lại, hoặc mở bản sao offline.';
	@override String get errorUnsupported => 'Định dạng hoặc kết nối này không được hỗ trợ trên thiết bị này. kiểm tra hướng dẫn cài đặt nguồn.';
	@override String get errorInvalidData => 'Không thể đọc tệp hoặc phản hồi của máy chủ này một cách an toàn.';
	@override String get errorCancelled => 'Chiến dịch đã bị hủy bỏ.';
	@override String get errorConflict => 'Vị trí thay đổi trong phiên khác. mở lại mục để chọn một vị trí.';
	@override String get signIn => 'Đăng nhập';
	@override String get reconnect => 'nối lại';
	@override String get folderHelp => 'Để lại trắng để bắt đầu từ gốc nguồn. URL S3 bao gồm bucket.';
	@override String get preferences => 'Ưu tiên';
	@override String get timePosition => 'vị trí';
	@override String get audioTrack => 'Audio Track Đánh giá';
	@override String get subtitleTrack => 'Subtitle Track';
	@override String get none => 'Không có';
	@override String get fullscreen => 'Toàn màn hình';
	@override String get syncLocation => 'Progress sync folder (tùy chọn)';
	@override String get syncLocationHint => 'Thư mục WebDAV dành riêng cho trạng thái PlezyNG. Dữ liệu được ghi có điều kiện; các tệp nội dung không bị thay đổi.';
	@override String get audiobooks => 'Sách nói';
	@override String get comics => 'truyện tranh';
	@override String get scan => 'Scan cho sách và phương tiện truyền thông';
	@override String get browserReader => 'Open Reader Đọc';
	@override String get browserReaderHelp => 'Đọc được mở trong trình duyệt của bạn. giữ PlezyNG mở để lưu vị trí và ghi chú của bạn.';
	@override String get on => 'trên';
	@override String get advancedSetup => 'App đăng ký';
	@override String get microsoftSignIn => 'Đăng ký với Microsoft';
	@override String get zoomIn => 'Zoom trong';
	@override String get zoomOut => 'Zoom ra ngoài';
	@override String get fitPage => 'Trang phù hợp';
	@override String get fitWidth => 'Fit rộng';
	@override String get actualSize => 'Kích thước hiện tại';
	@override String get goToPage => 'Đi đến page';
	@override String get goToSection => 'Đi đến chương';
	@override String pageRange({required Object count}) => 'Nhập số từ 1 đến ${count}';
	@override String get pageLayout => 'Trang layout';
	@override String get automatic => 'tự động';
	@override String get singlePage => '1 trang đơn';
	@override String get twoPages => '2 Trang';
	@override String get readingDirection => 'hướng đọc';
	@override String get leftToRight => 'Trái sang Phải';
	@override String get rightToLeft => 'Phải sang Trái';
	@override String get letterSpacing => 'Thư không gian';
	@override String get wordSpacing => 'Lời bài hát Spacing';
	@override String get readerControlsHelp => 'Dùng hai ngón tay để phóng to hoặc dùng các nút thu phóng. Kéo để di chuyển trang. Ctrl/⌘ cùng + hoặc − điều chỉnh mức thu phóng; Ctrl/⌘ cùng 0 đặt lại mức thu phóng. Page Up và Page Down chuyển trang.';
	@override String get imagePage => 'Trang truyện tranh';
	@override String get resetReader => 'Đặt lại các ưu tiên đọc';
	@override String get zoom => 'Thu phóng';
	@override String get useFiles => 'Sử dụng file và sách';
	@override String get cancelScan => 'Đặt hủy scan';
	@override String get googleDrive => 'Google Drive';
	@override String get offlineQuota => 'Offline download giới hạn';
	@override String get offlineQuotaHelp => 'Thiết lập không gian tối đa được sử dụng bởi các bản sao ngoại tuyến, tệp nhập khẩu và tải xuống. Giảm giới hạn sẽ không loại bỏ các bản gốc hiện có.';
	@override String get offlineStorageUsage => 'Lưu trữ Offline';
	@override String get reservedStorage => 'Bảo Vệ';
	@override String get downloadQueue => 'Tải Queue';
	@override String get downloadRunning => 'tải xuống';
	@override String get downloadQueued => 'chờ đợi';
	@override String get downloadPaused => 'nghỉ ngơi';
	@override String get downloadFailed => 'Phải nghỉ hưu';
	@override String get importing => 'nhập khẩu';
	@override String get importInterrupted => 'nhập khẩu bị gián đoạn · xóa để làm rõ';
	@override String get errorQuotaExceeded => 'Giới hạn lưu trữ offline đã đạt được.Tăng giới hạn hoặc xóa bản sao tải xuống.';
	@override String get errorStorageLow => 'Không có đủ lưu trữ thiết bị miễn phí để giữ bảo tồn được bảo vệ.';
	@override String get errorStorageUnavailable => 'PlezyNG không thể kiểm tra lưu trữ thiết bị miễn phí, vì vậy việc viết đã dừng lại.';
	@override String get removeDownloadJob => 'xóa download';
	@override String get downloadAlreadyComplete => 'Tải xuống này đã hoàn thành trước khi nó có thể được xóa. mục bây giờ có sẵn offline.';
	@override String get confirmRemoveDownloadJob => 'Loại bỏ tải xuống này và loại bỏ bất kỳ dữ liệu được tải về một phần? vị trí và ghi chú của bạn sẽ ở lại.';
}

// Path: lending
class _Translations$lending$vi extends Translations$lending$en {
	_Translations$lending$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Thư viện công cộng';
	@override String get add => 'Thêm một thư viện';
	@override String get other => 'Thư viện khác';
	@override String get libraryName => 'Thư viện tên';
	@override String get libraryUrl => 'Thư viện website';
	@override String get libraryUrlHint => 'Dùng danh mục hoặc trang đăng nhập của thư viện.';
	@override String get intro => 'Hãy vay từ thư viện của bạn, hãy giữ cho sách của bạn gần.';
	@override String get handoff => 'Đăng nhập, mượn sách và đọc an toàn qua dịch vụ riêng của thư viện.';
	@override String get openService => 'Thư viện mở';
	@override String get findLibrary => 'Tìm một thư viện';
	@override String get search => 'Tìm kiếm sách và tác giả';
	@override String get catalogue => 'Danh mục';
	@override String get loans => 'Sách đã mượn';
	@override String get holds => 'Đặt trước';
	@override String get signIn => 'Đăng nhập với thư viện của bạn';
	@override String get waiting => 'Kết thúc đăng ký trong trình duyệt của bạn, sau đó trở lại đây.';
	@override String get cancel => 'Hủy bỏ';
	@override String get disconnect => 'xóa thư viện';
	@override String get disconnectMessage => 'Xóa thư viện này khỏi hồ sơ này? Các sách đã mượn và lượt đặt trước vẫn được giữ tại thư viện.';
	@override String get getBook => 'Nhận sách';
	@override String get checkAvailability => 'Kiểm tra khả dụng';
	@override String get available => 'Có sẵn để vay';
	@override String get unavailable => 'Hiện chưa có';
	@override String get borrow => 'Mượn';
	@override String get placeHold => 'Đặt trước';
	@override String get returnBook => 'Trả trước hạn';
	@override String get cancelHold => 'Hủy đặt trước';
	@override String get confirmBorrow => 'Bạn có nên mượn danh hiệu này từ thư viện của mình?';
	@override String get confirmReturn => 'Trả tựa sách này ngay? Bạn có thể cần mượn lại để tiếp tục.';
	@override String get confirmCancelHold => 'Hủy lượt đặt trước của bạn cho tựa sách này?';
	@override String get email => 'Đặt thông báo email';
	@override String due({required Object date}) => 'Hạn trả: ${date}';
	@override String queue({required Object position}) => 'Vị trí ${position} trong dòng';
	@override String get empty => 'Không có tiêu đề nào ở đây.';
	@override String get openLibraryNote => 'Khám phá danh mục của Open Library. Các tùy chọn đọc và mượn được hiển thị trên trang của từng tựa sách.';
	@override String get more => 'tải thêm';
	@override String get gateway => 'Thư viện đăng ký dịch vụ';
	@override String get gatewayHint => 'Được cung cấp bởi thư viện của bạn hoặc quản trị viên PlezyNG.';
	@override String get advanced => 'Thư viện Integration';
	@override String get loadLibraries => 'Chọn thư viện của bạn';
	@override String get expired => 'Thời hạn mượn sách này đã kết thúc.';
	@override String get updated => 'Thư viện cập nhật';
	@override String get continueService => 'tiếp tục phục vụ';
	@override String get comingSoon => 'Lương In-app · Đến sớm';
	@override String get comingSoonDescription => 'Bạn có thể sử dụng thư viện của bạn trong Libby trong khi chúng tôi kết thúc kết nối nó.';
	@override String get suspendHold => 'Tạm dừng đặt trước';
	@override String get resumeHold => 'Tiếp tục đặt trước';
	@override String get suspendMessage => 'Giữ vị trí trong hàng chờ và để người đọc tiếp theo mượn bản này? Bạn có thể tiếp tục lượt đặt trước sau.';
	@override String get resumeMessage => 'Tiếp tục lượt đặt trước này để thư viện có thể cung cấp bản sẵn có tiếp theo cho bạn?';
	@override String get editEmail => 'Thay đổi thông báo email';
}

// Path: audiobook
class _Translations$audiobook$vi extends Translations$audiobook$en {
	_Translations$audiobook$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get syncTitle => 'Đọc & lắng nghe Sync';
	@override String get syncHelp => 'Giữ vị trí đọc, nghe vị trí, trạng thái hoàn thành, sổ ghi chép và ghi chú trên thiết bị của bạn. Chọn một tài khoản lưu trữ được gắn và sử dụng cùng mã đồng bộ trên mỗi thiết bị. Đọc và nghe vẫn riêng biệt.';
	@override String get addSyncSource => 'Thêm Google Drive, OneDrive, Dropbox, WebDAV hoặc S3 vào tệp và sách trước.';
	@override String get syncDestination => 'Tài khoản lưu trữ Sync';
	@override String get syncFolder => 'Sync folder hoặc prefix';
	@override String get syncFolderHelp => 'Sử dụng một thư mục riêng biệt hiện có trong nguồn WebDAV của bạn, hoặc một tiền lệ S3 dành riêng.';
	@override String get syncCode => 'Mã đồng bộ riêng';
	@override String get syncCodeHelp => 'Tạo một mã trên thiết bị đầu tiên của bạn, sau đó nhập mã đó trên các thiết bị khác của bạn. giữ một bản sao riêng: đó là chìa khóa cho trạng thái mã hóa của bạn. Sử dụng mã khác nhau cho mỗi người.';
	@override String get showCode => 'Hiển thị hoặc ẩn mã đồng bộ';
	@override String get newSyncCode => 'Tạo một mã đồng bộ mới';
	@override String get saveSync => 'Save và Sync';
	@override String get disableSync => 'Tắt sync trên thiết bị này';
	@override String get syncSourceDisconnect => 'Xóa nguồn này sẽ tắt đọc và nghe đồng bộ ở đây. các tệp đồng bộ mã hóa sẽ ở lại trong nhà cung cấp.';
	@override String get syncReconnect => 'Kết nối lại tài khoản lưu trữ';
	@override String lastSynced({required Object time}) => 'Kết quả tìm kiếm tại ${time}';
	@override String get syncPrivacy => 'Chỉ mã hóa tiến bộ và ghi chú được lưu trữ. Audio và ebook tập tin, tài khoản tokens và mật khẩu không được tải lên. Google Drive và OneDrive sử dụng lưu trữ ứng dụng; Dropbox sử dụng PlezyNG Sync. Khả năng đồng bộ có thể yêu cầu thêm truy cập viết. Trong khi bật, điểm đến này sở hữu tiến bộ đồng bộ; tiến bộ máy chủ vẫn riêng biệt. Khả năng đồng bộ tắt giữ lịch sử địa phương và trạng thái từ xa.';
	@override String get syncConflicts => 'Chọn nơi để lặp lại';
	@override String get conflictHelp => 'Những thay đổi này được thực hiện độc lập.Chọn vị trí hoặc phiên bản đánh dấu để giữ.Một thời gian sau hoặc tỷ lệ cao hơn không tự động giành chiến thắng.';
	@override String syncDevice({required Object device}) => 'Thiết bị ${device}';
	@override String get syncUnknownDevice => 'Thiết bị chưa biết';
	@override String get deletedBookmark => 'Bookmark bị xóa';
	@override String get finished => 'Kết thúc';
	@override String readingPosition({required Object percent}) => 'Đọc · ${percent}%';
	@override String get chapterTimeline => 'Chương tiến bộ';
	@override String get bookTimeline => 'Toàn bộ sách tiến bộ';
	@override String bookRemaining({required Object time}) => 'Thời gian còn lại trong cuốn sách này: ${time}';
	@override String chapterRemaining({required Object time}) => 'Thời gian còn lại trong chương này: ${time}';
	@override String get unknownRemaining => 'Tổng thời gian có sẵn khi các phần được chơi';
	@override String get undoSeek => 'tìm kiếm cuối cùng';
	@override String get customSpeed => 'Tốc độ playback tùy chỉnh';
	@override String get speedHelp => 'Chọn tốc độ từ 0.25× đến 4×.';
	@override String get apply => 'Ứng dụng';
	@override String get customSleep => 'Thời gian giấc ngủ tùy chỉnh';
	@override String get sleepMinutes => 'Thời gian (1 – 1440)';
	@override String sleepChapters({required Object count}) => 'Ngừng sau các chương ${count}';
	@override String get extendSleep => 'Thêm 5 phút';
	@override String sleepRemaining({required Object time}) => 'Thời gian ngủ: ${time}';
	@override String get useDefaults => 'Sử dụng các điều khiển lắng nghe này cho các cuốn sách mới';
	@override String get librarySort => 'sort sách';
	@override String get sortTitle => 'Tiêu đề';
	@override String get sortAuthor => 'Tác giả';
	@override String get sortNarrator => 'Nữ diễn viên';
	@override String get sortSeries => 'Lệnh Series';
	@override String get sortRecent => 'Gần đây mở';
	@override String get statusFilter => 'Đọc Status';
	@override String get statusAll => 'Tất cả sách';
	@override String get statusNew => 'Không bắt đầu';
	@override String get statusProgress => 'trong tiến bộ';
	@override String get statusFinished => 'Kết thúc';
	@override String get goToTime => 'Đi đến thời gian';
	@override String get timeHelp => 'Thời gian: phút: giây, hoặc phút: giây';
	@override String get recoveryHelp => 'Xuất một bản sao được mã hóa gần đây trước khi di chuyển hoặc sửa chữa dữ liệu đồng bộ. nhập khẩu kết hợp với trạng thái hiện tại; họ không bao giờ thay thế lịch sử đồng bộ địa phương. Giữ mã đồng bộ riêng biệt.';
	@override String get recoveryExport => 'Xuất khẩu file recovery mã hóa';
	@override String get recoveryImport => 'nhập file recovery mã hóa';
	@override String get recoveryImportConfirm => 'Kết hợp tệp phục hồi mã hóa này với các vị trí đọc và ghi chú hiện tại? Lịch sử hiện có sẽ được giữ lại. Thư viện chia sẻ và ID mục không bao gồm; thiết lập ID phù hợp trên mỗi thiết bị trước khi nhập khẩu.';
	@override String get recoveryExported => 'Tệp phục hồi mã hóa đã được lưu.';
	@override String get recoveryImported => 'Dữ liệu phục hồi kết hợp.';
}

// Path: sourceSetup
class _Translations$sourceSetup$vi extends Translations$sourceSetup$en {
	_Translations$sourceSetup$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get savedCertificate => 'Chứng chỉ máy chủ đã lưu';
	@override String get nfsEndpointInvalid => 'Nhập URL NFS, chẳng hạn nfs://nas:2049/export.';
	@override String get dlnaNone => 'Không tìm thấy máy chủ DLNA. Hãy nhập thủ công URL mô tả thiết bị.';
	@override String get dlnaServers => 'Máy chủ đa phương tiện DLNA';
	@override String get dlnaUnavailable => 'Không thể dò tìm DLNA trên mạng này. Hãy nhập thủ công URL mô tả thiết bị.';
	@override String get dlnaSearching => 'Đang tìm máy chủ DLNA trên mạng cục bộ';
	@override String get networkSearching => 'Đang tìm trên mạng cục bộ…';
	@override String get dlnaDiscover => 'Dò tìm máy chủ DLNA';
	@override String get dlnaHelp => 'Việc dò tìm phụ thuộc vào multicast trên mạng cục bộ. Nếu không thấy máy chủ, hãy nhập URL mô tả thiết bị của máy chủ đó ở trên.';
	@override String get dlnaRoot => 'ID đối tượng DLNA; để trống để dùng thư mục gốc của thiết bị.';
	@override String get passwordOrKey => 'Nhập mật khẩu hoặc thêm khóa riêng bên dưới.';
	@override String get sshFingerprint => 'Dấu vân tay SHA256 của khóa máy chủ SSH';
	@override String get sshFingerprintHelp => 'Xác minh với quản trị viên máy chủ. Trên máy chủ, chạy ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub và dùng giá trị SHA256.';
	@override String get sshFingerprintKeep => 'Để trống để giữ dấu vân tay đang được ghim, hoặc nhập dấu vân tay máy chủ mới.';
	@override String get sshAuthentication => 'Xác thực SSH bằng khóa công khai';
	@override String get sshAuthenticationHelp => 'Không bắt buộc; cũng hỗ trợ xác thực bằng mật khẩu.';
	@override String get privateKey => 'Khóa riêng (định dạng PEM hoặc OpenSSH)';
	@override String get privateKeyPassphrase => 'Cụm mật khẩu của khóa riêng';
	@override String get nfsMountPort => 'Cổng TCP của dịch vụ gắn kết NFS';
	@override String get nfsMountPortHelp => 'Mặc định: 20048';
	@override String get nfsUserId => 'ID người dùng NFS (AUTH_SYS)';
	@override String get nfsUserIdHelp => 'Mặc định: 1000. Dùng ID được vùng chia sẻ NFS trên NAS cho phép.';
	@override String get nfsGroupId => 'ID nhóm NFS (AUTH_SYS)';
	@override String get nfsGroupIdHelp => 'Mặc định: 1000. Dùng ID nhóm được vùng chia sẻ NFS trên NAS cho phép.';
	@override String get nfsEncryption => 'Bắt buộc mã hóa NFS (RPC-with-TLS)';
	@override String get nfsEncryptionHelp => 'Bắt buộc dùng TLS 1.3 cho NFS và dịch vụ gắn kết. Nếu NAS không hỗ trợ, kết nối sẽ bị từ chối.';
	@override String get nfsTrustCertificate => 'CA NFS tùy chỉnh hoặc chứng chỉ máy chủ (PEM, không bắt buộc)';
	@override String get nfsTrustHelp => 'Để trống để dùng các chứng chỉ được thiết bị này tin cậy. Nếu cần, thêm chứng chỉ của CA riêng hoặc chứng chỉ máy chủ tự ký; các tên trong chứng chỉ phải khớp với máy chủ trong URL NFS.';
	@override String get nfsTrustInvalid => 'Dùng chứng chỉ CA hoặc máy chủ ở định dạng PEM. Không kèm khóa riêng.';
	@override String get addTrustCertificate => 'Thêm chứng chỉ tin cậy tùy chỉnh';
	@override String get replaceTrustCertificate => 'Thay chứng chỉ tùy chỉnh đã lưu';
	@override String get nfsTlsHelp => 'RPC-with-TLS dùng các cổng thông thường của NFS và dịch vụ gắn kết, đồng thời yêu cầu NAS hỗ trợ RFC 9289. Bắt buộc dùng TLS 1.3. Tên máy chủ hoặc địa chỉ IP phải khớp với chứng chỉ. AUTH_SYS UID/GID vẫn áp dụng trong kênh được mã hóa.';
	@override String get clientCertificate => 'Chứng chỉ máy khách (không bắt buộc)';
	@override String get clientCertificateHelp => 'Cho phép NAS xác thực máy khách này; ID AUTH_SYS vẫn phụ thuộc vào chính sách của vùng chia sẻ NFS trên NAS.';
	@override String get savedIdentity => 'Sẽ dùng danh tính máy khách đã lưu.';
	@override String get replaceIdentity => 'Thay danh tính máy khách đã lưu';
	@override String get chooseIdentity => 'Chọn danh tính máy khách PKCS#12';
	@override String get identityPassphrase => 'Cụm mật khẩu của danh tính máy khách';
	@override String get identityPassphraseHelp => 'Để trống nếu tệp không có cụm mật khẩu.';
	@override String get removeIdentity => 'Xóa danh tính máy khách đã lưu nếu có';
	@override String get identityStorageHelp => 'Danh tính máy khách được lưu trong kho thông tin xác thực đã mã hóa của nguồn. Giữ nguyên phần này để giữ lại danh tính đã lưu.';
	@override String get nfsLimitations => 'NFSv3 chỉ đọc qua TCP. Không có RPC-with-TLS thì lưu lượng NFS không được mã hóa. NAS phải cho phép các ID AUTH_SYS đã chọn và các cổng máy khách không cần đặc quyền (thường gọi là tùy chọn xuất “insecure”). Không hỗ trợ NFSv4 và UDP.';
	@override String get nfsSetupHelp => 'Trợ giúp thiết lập NFS';
	@override String get nfsSetupHint => 'Kiểm tra các thiết lập này nếu không mở được kết nối.';
	@override String get nfsSetupDetails => 'Dùng vùng chia sẻ NFSv3 qua TCP. Khi bắt buộc mã hóa, cả dịch vụ NFS và dịch vụ gắn kết phải hỗ trợ RPC-with-TLS. Để trống chứng chỉ tùy chỉnh nếu chứng chỉ máy chủ được thiết bị này tin cậy, hoặc thêm chứng chỉ CA hay chứng chỉ tự ký của NAS. Tên trong chứng chỉ phải khớp với máy chủ của điểm cuối. Nếu NAS yêu cầu TLS hai chiều, hãy thêm danh tính máy khách PKCS#12 của nó. Cuối cùng, xác nhận vùng chia sẻ cho phép AUTH_SYS UID/GID đã cấu hình và chính sách cổng máy khách.';
	@override String get ftpHelp => 'FTP dùng chế độ thụ động. Dùng ftp:// cho FTP không mã hóa, ftpes:// cho TLS tường minh, hoặc ftps:// cho TLS (ngầm định trên cổng 990; tường minh trên các cổng khác).';
	@override String get openSubtitles => 'OpenSubtitles';
	@override String get subtitleSetup => 'Tìm phụ đề tùy chọn cho các video riêng lẻ.';
	@override String get apiKey => 'Khóa API';
	@override String get optionalUsername => 'Tên người dùng của tài khoản (không bắt buộc)';
	@override String get optionalPassword => 'Mật khẩu tài khoản (không bắt buộc)';
	@override String get subtitlePrivacy => 'Lấy khóa API từ opensubtitles.com. Tìm kiếm gửi tiêu đề video và các ID IMDb/TMDB có sẵn, không bao giờ gửi tệp video. Khóa và thông tin xác thực tài khoản tùy chọn được mã hóa cùng nguồn này.';
	@override String get automaticMetadata => 'Siêu dữ liệu video trực tuyến tự động';
	@override String get metadataPrivacy => 'Chỉ gửi tiêu đề/năm từ tên tệp và số tập hoặc một ID NFO, không bao giờ gửi nội dung đa phương tiện hay thông tin xác thực. Các trường NFO vẫn được ưu tiên.';
	@override String get nfsEncryptionFailure => 'Với NFS được mã hóa, kiểm tra hỗ trợ RFC 9289 và TLS 1.3 trên cả hai dịch vụ NAS, tên trong chứng chỉ và UID/GID của vùng chia sẻ. PlezyNG sẽ không thử lại kết nối này khi không mã hóa.';
	@override String get sourceConnecting => 'Đang kết nối đến nguồn';
	@override String get metadataSearchPrivacy => 'Lượt tìm tiêu đề này được gửi đến Trakt. Chỉ tiêu đề bạn nhập được gửi đi, không phải video hay thông tin xác thực của nguồn.';
	@override String get chooseMatch => 'Chọn kết quả phù hợp';
	@override String get metadataMatchHelp => 'Kiểm tra tiêu đề và năm trước khi chọn. Trakt nhận tiêu đề tìm kiếm; video vẫn ở nguồn của nó.';
	@override String get metadataNoMatches => 'Không tìm thấy tiêu đề trực tuyến phù hợp. Hãy thử tiêu đề khác.';
	@override String get metadataSearch => 'Tìm siêu dữ liệu trực tuyến';
	@override String get metadataLoading => 'Đang tra cứu thông tin phim và chương trình TV trực tuyến…';
	@override String get metadataFromTrakt => 'Siêu dữ liệu trực tuyến từ Trakt';
	@override String get metadataNoAutomaticMatch => 'Không tự động tìm thấy tiêu đề phù hợp. Hãy tìm tiêu đề để chọn kết quả.';
	@override String get metadataFailed => 'Không tải được siêu dữ liệu trực tuyến. Vẫn có thể phát và xem thông tin cục bộ.';
	@override String get videoDetailsLoading => 'Đang tải thông tin video';
	@override String get subtitleKeyRequired => 'Cần có khóa API OpenSubtitles';
	@override String get subtitleKeyHelp => 'Chỉnh sửa nguồn tệp này và thêm khóa API OpenSubtitles trong phần cài đặt phụ đề tùy chọn.';
	@override String get subtitleSearchFailed => 'Tìm phụ đề thất bại. Kiểm tra khóa API, kết nối và quyền truy cập dịch vụ.';
	@override String get subtitleApplyFailed => 'Không thể tải xuống hoặc áp dụng phụ đề này. Kiểm tra kết nối và thử kết quả khác.';
	@override String get subtitleSearch => 'Tìm trên OpenSubtitles';
	@override String get subtitleSearchPrivacy => 'Tìm kiếm dùng tiêu đề và các ID IMDb/TMDB có sẵn. Tệp video vẫn ở nguồn của nó. Trước khi chọn, hãy kiểm tra ngôn ngữ, nhãn phụ đề bắt buộc hoặc dành cho người khiếm thính, và điểm đánh giá.';
	@override String get movieOrShow => 'Phim hoặc chương trình TV';
	@override String get subtitleTitleHint => 'Nhập tiêu đề để thu hẹp kết quả';
	@override String get subtitleLanguage => 'Ngôn ngữ phụ đề';
	@override String get subtitleSearching => 'Đang tìm trên OpenSubtitles';
	@override String get subtitleNoMatches => 'Không tìm thấy phụ đề phù hợp. Thử tiêu đề hoặc ngôn ngữ khác.';
	@override String get downloadSubtitle => 'Tải phụ đề';
	@override String get subtitle => 'Phụ đề';
	@override String get nfsTlsRequired => 'Bắt buộc có RPC-with-TLS';
	@override String get nfsUnencrypted => 'NFS không mã hóa';
	@override String get tlsEncrypted => 'Được mã hóa bằng TLS';
	@override String get ftpPlain => 'FTP không mã hóa';
	@override String get sshPinned => 'SSH được mã hóa · khóa máy chủ đã ghim';
	@override String get smbEncrypted => 'Mã hóa SMB3 bật';
	@override String get smbUnencrypted => 'Mã hóa SMB3 tắt';
	@override String get httpUnencrypted => 'HTTP không mã hóa đường truyền';
	@override String get checkEndpointSecurity => 'Kiểm tra bảo mật điểm cuối';
	@override String fieldRequired({required Object label}) => '${label} là bắt buộc.';
	@override String integerRange({required Object label, required Object min, required Object max}) => 'Nhập ${label} từ ${min} đến ${max}.';
	@override String replaceFile({required Object name}) => 'Thay thế ${name}';
	@override String selectedIdentity({required Object name}) => 'Danh tính máy khách đã chọn: ${name}';
	@override String subtitleRating({required Object rating}) => 'Điểm đánh giá ${rating}';
	@override String subtitleDownloading({required Object title}) => 'Đang tải phụ đề: ${title}';
	@override String get sharedEntryPair => 'Cặp bài này';
	@override String get sharedEntryPairHelp => 'Nhập ID tương tự cho mục này trên mỗi thiết bị. Sử dụng một định dạng chia sẻ ổn định hoặc tạo một và sao chép nó vào mục phù hợp. tiến bộ cặp chỉ khi các loại tệp phiên bản, kích thước, và đơn đặt hàng tương ứng. Blank xóa bản đồ này.';
	@override String get sharedEntryId => 'chia sẻ item ID';
	@override String get generateSharedEntryId => 'Tạo ID mục chia sẻ';
	@override String get sharedLibraryId => 'ID thư viện chia sẻ (tùy chọn)';
	@override String get sharedLibraryHelp => 'Sử dụng ID tương tự trên các thiết bị mở cùng một thư viện. ID công cộng này giúp mang lại tiến bộ đọc và ghi chú qua các kết nối nguồn khác nhau; nó không phải là mật khẩu. Khi nhà cung cấp sử dụng ID mục khác nhau, cặp những mục từ màn hình chi tiết của họ.';
	@override String get sharedLibraryInvalid => 'Sử dụng 8-100 lá thư, số lượng, điểm, subscores hoặc hyphens.';
	@override String get generateSharedLibraryId => 'Tạo một ID thư viện chia sẻ';
	@override String get nfsReadAhead => 'NFS read-ahead yêu cầu';
	@override String get nfsReadAheadHelp => 'Đọc song song nhiều hơn có thể cải thiện khả năng thông qua trên một NAS nhanh hoặc mạng lưới. sử dụng 1 nếu máy chủ giới hạn các yêu cầu tương đương.';
	@override String get nfsReadTest => 'Đánh giá hiệu suất NFS';
	@override String get nfsReadTestHelp => 'Đọc lên đến 64 MiB từ tệp lớn nhất để đo kết nối NAS này.';
	@override String get nfsQualificationResult => 'NFS đọc đo lường';
	@override String get nfsReadBytes => 'Dữ liệu đọc';
	@override String get nfsReadSpeed => 'Tốc độ đo';
	@override String get nfsReadRequests => 'Đọc yêu cầu';
	@override String get sharedEntryConflict => 'ID mục được chia sẻ này đã được kết hợp với một mục khác trong thư viện này.';
}

// Path: comics
class _Translations$comics$vi extends Translations$comics$en {
	_Translations$comics$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get fitHeight => 'Vừa chiều cao';
	@override String get readingMode => 'Chế độ đọc';
	@override String get paged => 'Trang';
	@override String get webtoon => 'Cuộn liên tục';
	@override String get coverAlone => 'Hiển thị bìa riêng';
	@override String get splitWide => 'Chia trang rộng';
	@override String get splitWideHelp => 'Hiển thị riêng từng nửa theo thứ tự đọc. Tạm dừng hiển thị hai trang cạnh nhau khi bật tùy chọn này.';
	@override String get thumbnails => 'Hình thu nhỏ của trang';
	@override String get controlsHelp => 'Vuốt để lật trang. Chạm hai lần để đổi cách vừa trang. Khi cuộn liên tục, vuốt dọc hoặc dùng Page Up và Page Down.';
	@override String get savedForComic => 'Cài đặt hiển thị được ghi nhớ cho truyện tranh này trong hồ sơ này.';
	@override String get readLists => 'Danh sách đọc';
	@override String get collections => 'Bộ sưu tập';
}

// Path: games
class _Translations$games$vi extends Translations$games$en {
	_Translations$games$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

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
	@override String get touchDescription => 'Show the on-screen controller during a stream. It supports multiple fingers, sticks, buttons and triggers.';
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
	@override String get helpBody => 'Enable Games for your profile, choose a computer and approve the first connection. Steam can open Big Picture or launch a saved game shortcut inside PlezyNG on receivers that support it. Connect Companion Remote to combine installed games from your computers in one library. Steam pairing does not grant access to a private account library.\n\nSteam receivers are experimental on Android, Linux and Apple. The stream menu provides controller, audio and connection controls. Pyrowave is an optional codec on compatible Android and Apple receivers and needs a fast network.\n\nPairing requires the host’s approval. Sunshine QR codes open its PIN page without carrying credentials. For access away from home, use the computer’s VPN address. Automatic discovery normally stays on the local network.\n\nDisconnecting leaves the game running on the computer.';
	@override String get cancel => 'Cancel';
	@override String get scanning => 'Looking for computers…';
	@override String get saveShortcut => 'Save shortcut';
	@override String get manualHint => 'For Moonlight use the host’s GameStream HTTP port (usually 47989), not its web settings port. Steam normally advertises on 27036.';
	@override String get engineUnavailable => 'In-app streaming is not available here yet';
	@override String get nativeEnginePending => 'This build does not include a streaming engine for this platform. You can save the computer, but it cannot play here yet.';
	@override String get steamEnginePending => 'This build does not include an embedded Steam receiver for this device. You can browse your library and manage computers. Playing here requires a build with a compatible receiver.';
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
class _Translations$deepLinks$vi extends Translations$deepLinks$en {
	_Translations$deepLinks$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get invalid => 'Liên kết Plezy này không hợp lệ.';
	@override String profileNotFound({required Object profile}) => 'Không có hồ sơ phù hợp với "${profile}".';
	@override String get serverUnavailable => 'Tôi không thể truy cập máy chủ cho liên kết này.';
	@override String get notFound => 'Tôi không thể tìm thấy tiêu đề này trong thư viện của bạn.';
	@override String get unsupportedItem => 'Link này không thể chơi được.';
	@override String get noLiveTv => 'Không có máy chủ TV trực tiếp có sẵn cho liên kết này.';
	@override String channelNotFound({required Object channel}) => 'Không thể tìm thấy kênh "${channel}".';
	@override String get showLink => 'Hiển thị link';
	@override String get showProfileLink => 'Hiển thị profile link';
	@override String get dialogTitle => 'liên kết';
	@override String get showHint => 'Mở liên kết này chơi phần tiếp theo. Thêm &mode=shuffle để chơi chương trình trên shuffle.';
	@override String get movieHint => 'Mở liên kết này chơi bộ phim.';
	@override String get episodeHint => 'Mở liên kết này chơi phần này.';
	@override String get profileHint => 'Mở liên kết này chuyển đổi đến hồ sơ này.';
	@override String openAsProfile({required Object name}) => 'Mở như ${name}';
	@override String get copy => 'sao chép';
	@override String get copied => 'Link copy';
}

// Path: householdSetup
class _Translations$householdSetup$vi extends Translations$householdSetup$en {
	_Translations$householdSetup$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Thiết lập gia đình';
}

// Path: issueReport
class _Translations$issueReport$vi extends Translations$issueReport$en {
	_Translations$issueReport$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Báo cáo sự cố';
	@override String get instructions => 'Quét mã QR để mở bản nháp GitHub đã điền sẵn. Hãy xem lại và chỉ gửi khi bạn sẵn sàng.';
	@override String get privacy => 'Bản nháp gồm phiên bản ứng dụng, nền tảng và số lượng kết nối. Bản nháp không có địa chỉ máy chủ, tên tài khoản hoặc hồ sơ, tiêu đề nội dung hay đường dẫn tệp.';
	@override String get logPrivacy => 'Nhật ký là tùy chọn. Hãy xem lại trước khi tải lên. ID nhật ký được thêm vào bản nháp, có thể hiển thị công khai.';
	@override String get openDraft => 'Mở bản nháp GitHub';
}

// Path: appIcon.names
class _Translations$appIcon$names$vi extends Translations$appIcon$names$en {
	_Translations$appIcon$names$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get midnight => 'nửa đêm';
	@override String get ember => 'người';
	@override String get paper => 'giấy';
	@override String get oled => 'OLED';
	@override String get line => 'Line Đề';
	@override String get ocean => 'Đại dương';
	@override String get ultraviolet => 'Tử ngoại';
	@override String get matcha => 'Matcha';
	@override String get sunset => 'Hoàng hôn';
	@override String get gold => 'vàng';
	@override String get titanium => 'Titanic';
	@override String get glass => 'kính';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => 'Synthwave';
	@override String get pixel => 'Pixel';
	@override String get neon => 'Neon';
	@override String get sticker => 'Nhãn dán';
	@override String get ticket => 'Vé';
	@override String get pop => 'Pop';
	@override String get strata => 'đường phố';
	@override String get facet => 'mặt';
	@override String get tilde => 'Tilde';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$vi extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

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
class _Translations$common$mediaKind$vi extends Translations$common$mediaKind$en {
	_Translations$common$mediaKind$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get movie => 'Phim';
	@override String get show => 'show show';
	@override String get season => 'Phần';
	@override String get episode => 'Tập';
	@override String get artist => 'Ca Sĩ';
	@override String get album => 'Tuyển Tập';
	@override String get track => 'Bản ghi';
	@override String get collection => 'Bộ Sưu Tập';
	@override String get playlist => 'Danh sách phát';
	@override String get clip => 'Video ngắn';
	@override String get photo => 'Hình Ảnh';
	@override String get folder => 'Thư mục';
}

// Path: settings.startupSectionOptions
class _Translations$settings$startupSectionOptions$vi extends Translations$settings$startupSectionOptions$en {
	_Translations$settings$startupSectionOptions$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get discover => 'Mở các khuyến nghị và mục từ các nguồn phát hiện liên kết.';
	@override String get libraries => 'Mở thư viện truyền thông liên kết của bạn.';
	@override String get liveTv => 'Mở Live TV khi một máy chủ cung cấp nó; nếu không, khởi động sẽ trở về nhà.';
	@override String get search => 'Khởi mở Media Search.';
}

// Path: themeEditor.slots
class _Translations$themeEditor$slots$vi extends Translations$themeEditor$slots$en {
	_Translations$themeEditor$slots$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get bg => 'nền';
	@override String get surface => 'bề mặt';
	@override String get outline => 'outline';
	@override String get text => 'Văn bản';
	@override String get textMuted => 'Text thứ hai';
	@override String get accent => 'accent';
}

// Path: themeEditor.contrast
class _Translations$themeEditor$contrast$vi extends Translations$themeEditor$contrast$en {
	_Translations$themeEditor$contrast$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => 'Bài viết trên nền';
	@override String get textOnSurface => 'Text trên bề mặt';
	@override String get textMutedOnBg => 'Bài viết thứ hai trên nền';
	@override String get textMutedOnSurface => 'Văn bản thứ hai trên bề mặt';
	@override String get accentOnBg => 'Tập trung vào nền';
	@override String get accentOnSurface => 'Tập trung vào bề mặt';
	@override String get labelOnAccent => 'Bút nhãn trên accent';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$vi extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Chơi / Pause';
	@override String get volumeUp => 'Độ bền up';
	@override String get volumeDown => 'Số lượng Down';
	@override String seekForward({required Object seconds}) => 'Tìm về phía trước (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'Tìm kiếm trở lại (${seconds}s)';
	@override String get fullscreenToggle => 'Cùng Fullscreen';
	@override String get muteToggle => 'cùng nhau mút';
	@override String get subtitleToggle => 'Thêm Subtitles';
	@override String get audioTrackNext => 'Audio Track tiếp theo';
	@override String get subtitleTrackNext => 'Subtitle Track tiếp theo';
	@override String get chapterNext => 'Đoạn kế tiếp';
	@override String get chapterPrevious => 'Đoạn trước';
	@override String get episodeNext => 'Tập Kế Tiếp';
	@override String get episodePrevious => 'Chương trước';
	@override String get speedIncrease => 'Tăng tốc độ';
	@override String get speedDecrease => 'Giảm tốc độ';
	@override String get speedReset => 'Tốc độ Reset';
	@override String get zoomIn => 'Zoom trong';
	@override String get zoomOut => 'Zoom ra ngoài';
	@override String get zoomReset => 'Tải Zoom';
	@override String get subSeekNext => 'Tìm kiếm Subtitle tiếp theo';
	@override String get subSeekPrev => 'Tìm kiếm trước Subtitle';
	@override String get subtitleDelayIncrease => 'Lễ Subtitles';
	@override String get subtitleDelayDecrease => 'Hiện phụ đề sớm hơn';
	@override String get shaderToggle => 'Cùng nhau Shaders';
	@override String get skipMarker => 'Lượt xem / tín dụng';
	@override String get screenshot => 'chụp màn hình';
	@override String get framePrevious => 'Frame trước';
	@override String get frameNext => 'Frame tiếp theo';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$vi extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Yêu cầu Android 8.0 hoặc mới hơn';
	@override String get iosVersion => 'Yêu cầu iOS 15.0 hoặc mới hơn';
	@override String get permissionDisabled => 'Picture-in-picture bị vô hiệu hóa. bật nó trong cài đặt hệ thống.';
	@override String get notSupported => 'Thiết bị không hỗ trợ chế độ hình ảnh trong hình ảnh';
	@override String get voSwitchFailed => 'Không thể chuyển phát video sang hình ảnh-in-photo';
	@override String get failed => 'Picture-in-picture không bắt đầu';
	@override String get prepareFailed => 'Hình ảnh trong hình không thể được chuẩn bị';
	@override String unknown({required Object error}) => 'Một lỗi xảy ra: ${error}';
}

// Path: subtitlingStyling.assOverrideOptions
class _Translations$subtitlingStyling$assOverrideOptions$vi extends Translations$subtitlingStyling$assOverrideOptions$en {
	_Translations$subtitlingStyling$assOverrideOptions$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get no => 'Giữ các phông chữ, màu sắc, kích cỡ và vị trí được viết trong tệp chủ đề.';
	@override String get yes => 'Cho phép cài đặt phong cách subtitle của người chơi để điều chỉnh các subtitles ASS.';
	@override String get scale => 'Ứng dụng phong cách người chơi và quy mô các kích cỡ tích hợp để phù hợp với kích thước video.';
	@override String get force => 'Thay thế các phong cách ASS tích hợp với phong cách subtitle của người chơi.';
	@override String get strip => 'Xóa định dạng ASS tích hợp và làm cho văn bản chủ đề rõ ràng.';
}

// Path: subtitlingStyling.renderResolutionOptions
class _Translations$subtitlingStyling$renderResolutionOptions$vi extends Translations$subtitlingStyling$renderResolutionOptions$en {
	_Translations$subtitlingStyling$renderResolutionOptions$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get screen => 'Render ở độ phân giải bề mặt màn hình đầy đủ cho kết quả sắc nét nhất.';
	@override String get video => 'Render sử dụng độ phân giải video như là tham chiếu, có thể làm giảm công việc trên màn hình độ phân biệt cao.';
	@override String get threeQuarter => 'Render tại 75% độ phân giải bề mặt hiển thị để tiết kiệm hiệu suất khiêm tốn.';
	@override String get half => 'Tải xuống 50% độ phân giải bề mặt hiển thị để giảm công việc, với các cạnh mềm hơn.';
	@override String get third => 'Render tại một phần ba độ phân giải bề mặt hiển thị để giảm công việc, với các cạnh mềm hơn.';
	@override String get quarter => 'Render tại một phần tư độ phân giải bề mặt hiển thị để giảm công việc, với kết quả mềm nhất.';
}

// Path: accountPreferences.groups
class _Translations$accountPreferences$groups$vi extends Translations$accountPreferences$groups$en {
	_Translations$accountPreferences$groups$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => 'Âm thanh & Subtitles';
	@override String get libraryDisplay => 'Thư viện';
	@override String get personalMedia => 'Thông tin cá nhân';
}

// Path: accountPreferences.subtitleModes
class _Translations$accountPreferences$subtitleModes$vi extends Translations$accountPreferences$subtitleModes$en {
	_Translations$accountPreferences$subtitleModes$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get none => 'Chọn thủ công';
	@override String get noneDescription => 'Đừng bao giờ tự nhặt các tiêu đề.';
	@override String get defaultMode => 'Theo dõi theo các lá cờ';
	@override String get defaultModeDescription => 'Sử dụng các lá cờ mặc định và bắt buộc được lưu trữ trên mỗi dòng subtitle.';
	@override String get always => 'Luôn có khả năng';
	@override String get alwaysDescription => 'Chuyển vào một dòng subtitle trong ngôn ngữ yêu thích bất cứ khi nào có.';
	@override String get onlyForced => 'Chỉ có các subtitles';
	@override String get onlyForcedDescription => 'Chỉ tải các con đường được đánh dấu là bắt buộc.';
	@override String get smart => 'Hiển thị bằng âm thanh nước ngoài';
	@override String get smartDescription => 'Thay đổi các tiêu đề chỉ khi âm thanh ở ngôn ngữ khác.';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class _Translations$accountPreferences$subtitleAccessibilityOptions$vi extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	_Translations$accountPreferences$subtitleAccessibilityOptions$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'Ưu tiên không SDH subtitles';
	@override String get preferSdh => 'Ưu đãi SDH Subtitles';
	@override String get onlySdh => 'Chỉ có SDH Subtitles';
	@override String get onlyNonSdh => 'Chỉ có các tiêu đề không SDH';
	@override String get preferNonSdhDescription => 'Thích các tiêu chuẩn khi cả phiên bản tiêu chuẩn và SDH đều có sẵn.';
	@override String get preferSdhDescription => 'Thích các tiêu đề SDH khi có sẵn, nhưng cho phép tiêu chuẩn tiêu đề như là một sự sụp đổ.';
	@override String get onlySdhDescription => 'Chỉ sử dụng các tiêu đề SDH; không rơi trở lại các tiêu chuẩn.';
	@override String get onlyNonSdhDescription => 'Chỉ sử dụng các tiêu chuẩn; loại trừ các tiêu đề SDH.';
}

// Path: accountPreferences.forcedSubtitleOptions
class _Translations$accountPreferences$forcedSubtitleOptions$vi extends Translations$accountPreferences$forcedSubtitleOptions$en {
	_Translations$accountPreferences$forcedSubtitleOptions$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => 'Ưu tiên không bắt buộc subtitles';
	@override String get preferForced => 'Ưu tiên Subtitles';
	@override String get onlyForced => 'Chỉ có các subtitles';
	@override String get onlyNonForced => 'Chỉ có các subtitles không bắt buộc';
	@override String get preferNonForcedDescription => 'Thích các tiêu đề thường xuyên, nhưng cho phép những con đường bắt buộc như một sự sụp đổ.';
	@override String get preferForcedDescription => 'Tốt nhất là bắt buộc theo dõi khi có sẵn, nhưng cho phép các tiêu đề thường xuyên như một sự sụp đổ.';
	@override String get onlyForcedDescription => 'Chỉ sử dụng các con đường được đánh dấu là bắt buộc.';
	@override String get onlyNonForcedDescription => 'Trừ các dấu vết được đánh dấu là bắt buộc.';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$vi extends Translations$accountPreferences$watchedIndicatorOptions$en {
	_Translations$accountPreferences$watchedIndicatorOptions$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get none => 'Không Bao Giờ';
	@override String get moviesAndShows => 'phim và chương trình truyền hình';
	@override String get movies => 'phim chỉ';
	@override String get shows => 'TV Show Chỉ';
	@override String get noneDescription => 'Đừng hiển thị các dấu hiệu kiểm tra được xem.';
	@override String get moviesAndShowsDescription => 'Hiển thị kiểm tra được xem cho các bộ phim và chương trình truyền hình.';
	@override String get moviesDescription => 'Hiển thị các dấu hiệu kiểm tra chỉ cho phim.';
	@override String get showsDescription => 'Chỉ hiển thị dấu đánh dấu đã xem cho các chương trình truyền hình.';
}

// Path: accountPreferences.mediaReviewsOptions
class _Translations$accountPreferences$mediaReviewsOptions$vi extends Translations$accountPreferences$mediaReviewsOptions$en {
	_Translations$accountPreferences$mediaReviewsOptions$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'Người dùng và các nhà phê bình';
	@override String get usersOnly => 'Người dùng chỉ';
	@override String get criticsOnly => 'Chỉ có những người chỉ trích';
	@override String get nobody => 'Ẩn';
	@override String get usersAndCriticsDescription => 'Hiển thị cả đánh giá người dùng và đánh giá quan trọng.';
	@override String get usersOnlyDescription => 'Hiển thị đánh giá và đánh giá được gửi bởi người dùng.';
	@override String get criticsOnlyDescription => 'Hiển thị đánh giá và đánh giá quan trọng.';
	@override String get nobodyDescription => 'Ẩn đánh giá và đánh giá.';
}

// Path: discover.findNext
class _Translations$discover$findNext$vi extends Translations$discover$findNext$en {
	_Translations$discover$findNext$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tìm lựa chọn tiếp theo';
	@override String get open => 'Tìm lựa chọn tiếp theo';
	@override String get anyTime => 'Không giới hạn thời gian';
	@override String get timeAvailable => 'Bạn có bao nhiêu thời gian?';
	@override String get filters => 'Chọn điều phù hợp lúc này';
	@override String get watch => 'Xem';
	@override String get listen => 'Nghe';
	@override String get read => 'Đọc';
	@override String finishable({required Object duration}) => 'Có thể hoàn thành trong ${duration}';
	@override String aboutDuration({required Object duration}) => 'Khoảng ${duration}';
	@override String nextUnit({required Object duration}) => 'Chương tiếp theo · ${duration}';
	@override String totalDuration({required Object duration}) => 'Tổng cộng ${duration}';
	@override String get timingVaries => 'Thời lượng có thể thay đổi';
	@override String get notNow => 'Để sau';
	@override String get swipeHint => 'Vuốt ảnh bìa theo hướng mũi tên hoặc dùng các nút bên dưới.';
	@override String get saved => 'Gợi ý đã lưu';
	@override String savedCount({required Object count}) => 'Gợi ý đã lưu · ${count}';
	@override String get undo => 'Hoàn tác';
	@override String get details => 'Chi tiết';
	@override String get noPicks => 'Chưa có nội dung để chọn';
	@override String get noPicksHint => 'Kết nối thư viện hoặc thêm nguồn nội dung để bắt đầu.';
	@override String get noMatches => 'Chưa có nội dung phù hợp lúc này';
	@override String get noMatchesHint => 'Thử loại nội dung khác hoặc dành thêm thời gian.';
	@override String get allDone => 'Bạn đã xem hết các gợi ý';
	@override String get allDoneHint => 'Tạo nhóm gợi ý mới để xem lại những lựa chọn này.';
	@override String get refresh => 'Tìm nhóm gợi ý khác';
	@override String sourceReason({required Object source}) => 'Từ ${source}';
	@override String libraryReason({required Object library}) => 'Từ ${library}';
	@override String get ownedReason => 'Từ thư viện của bạn';
	@override String get liveNow => 'Đang phát sóng';
	@override String get watchLive => 'Xem trực tiếp';
	@override String get filterAnything => 'Tất cả các loại';
	@override String get filterWatch => 'Xem';
	@override String get filterListen => 'Nghe';
	@override String get filterRead => 'Đọc';
	@override String get twentyMinutes => '20 phút';
	@override String get fortyFiveMinutes => '45 phút';
	@override String get ninetyMinutes => '90 phút';
	@override String get apply => 'Áp dụng';
	@override String get openFailed => 'Lựa chọn này không còn khả dụng. Làm mới để kiểm tra lại.';
	@override String get changeFailed => 'Không thể lưu thay đổi. Vui lòng thử lại.';
	@override String get savedLimit => 'Danh sách gợi ý đã lưu đã đầy. Xóa một gợi ý để lưu gợi ý khác.';
	@override String get chooseHint => 'Mở một tựa, lưu để xem sau hoặc bỏ qua.';
	@override String get howItWorks => 'Cách sử dụng';
	@override String get notNowHelp => 'Tạm bỏ qua tựa này. Tựa vẫn ở trong thư viện của bạn.';
	@override String get saveHelp => 'Lưu vào các lựa chọn đã lưu của hồ sơ này trên thiết bị này. Việc lưu không tải nội dung xuống.';
	@override String get openHelp => 'Chọn ảnh bìa để xem chi tiết. Dùng nút chính để phát, đọc hoặc mở tựa.';
	@override String get controlsHelp => 'Bàn phím hoặc điều khiển: chọn một nút rồi nhấn Enter hoặc nút Chọn. Hoàn tác khôi phục lựa chọn vừa rồi.';
	@override String get artworkLoading => 'Đang tải ảnh…';
	@override String get artworkUnavailable => 'Không có ảnh';
	@override String get savedFeedback => 'Đã thêm vào các lựa chọn đã lưu';
	@override String get skippedFeedback => 'Đã tạm bỏ qua';
	@override String get releaseToConfirm => 'Thả để xác nhận';
	@override String get remoteHint => 'Khi chọn ảnh bìa: ← / → chọn · Nút Chọn: chi tiết · ↑ / ↓ chuyển tiêu điểm';
}

// Path: discover.person
class _Translations$discover$person$vi extends Translations$discover$person$en {
	_Translations$discover$person$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get born => 'Sinh ra';
	@override String get died => 'chết';
	@override String get birthplace => 'Địa điểm sinh';
	@override String dateWithAge({required Object date, required Object age}) => '${date} ( tuổi ${age})';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (trẻ ${age})';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$vi extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'khuyến cáo';
	@override String get browse => 'Duyệt';
	@override String get collections => 'Bộ Sưu Tập';
	@override String get playlists => 'Danh sách phát';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$vi extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Nhóm';
	@override String get all => 'Tất cả';
	@override String get movies => 'Phim';
	@override String get shows => 'Chương Trình TV';
	@override String get seasons => 'Phần';
	@override String get episodes => 'Tập Phim';
	@override String get artists => 'Ca Sĩ';
	@override String get albums => 'Album';
	@override String get tracks => 'Bản ghi';
	@override String get folders => 'Thư Mục';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$vi extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Thể loại';
	@override String get year => 'Năm';
	@override String get contentRating => 'Content Đánh giá';
	@override String get tag => 'Nhãn';
	@override String get unwatched => 'Không quan sát';
	@override String get unplayed => 'Chưa Phát';
	@override String get favorites => 'Yêu Thích';
	@override String get filePath => 'file đường';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$vi extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tiêu đề';
	@override String get dateAdded => 'Ngày thêm';
	@override String get releaseDate => 'Ngày phát hành';
	@override String get rating => 'Đánh giá';
	@override String get communityRating => 'Điểm cộng đồng';
	@override String get criticRating => 'Đánh giá Critical Rating';
	@override String get userRating => 'User Đánh giá';
	@override String get datePlayed => 'Ngày phát';
	@override String get playCount => 'Số lần phát';
	@override String get productionYear => 'Năm sản xuất';
	@override String get runtime => 'Thời lượng';
	@override String get officialRating => 'Rating chính thức';
	@override String get premiereDate => 'Ngày công chiếu';
	@override String get startDate => 'Start ngày';
	@override String get airTime => 'Thời gian phát sóng';
	@override String get studio => 'Hãng phim';
	@override String get random => 'Ngẫu Nhiên';
	@override String get dateShared => 'ngày chia sẻ';
	@override String get latestEpisodeAirDate => 'Ngày cuối cùng của Air Date';
	@override String get lastEpisodeDateAdded => 'Chương cuối ngày thêm';
	@override String get dateDownloaded => 'Ngày tải xuống';
	@override String get size => 'Kích cỡ';
	@override String get library => 'Thư viện';
}

// Path: libraries.advancedFilters
class _Translations$libraries$advancedFilters$vi extends Translations$libraries$advancedFilters$en {
	_Translations$libraries$advancedFilters$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get include => 'bao gồm';
	@override String get exclude => 'trừ';
	@override String get any => 'bất kỳ';
	@override String get yes => 'Đúng';
	@override String get no => 'Không';
	@override String not({required Object value}) => 'Không ${value}';
	@override String valueCount({required Object count}) => '${count} được chọn';
	@override String valueCountExcluded({required Object count}) => '${count} ngoại trừ';
	@override String get searchValues => 'Giá trị tìm kiếm';
	@override String get noValues => 'Không có giá trị';
	@override String get matchContains => 'chứa';
	@override String get matchNotContains => 'Không chứa';
	@override String get matchIs => 'là';
	@override String get matchIsNot => 'Không phải';
	@override String get matchBeginsWith => 'Bắt đầu với';
	@override String get matchEndsWith => 'Kết thúc với';
	@override String get textHint => 'kiểu để match';
	@override String get from => 'Từ';
	@override String get to => 'để';
	@override String range({required Object from, required Object to}) => '${from} đến ${to}';
	@override String atLeast({required Object value}) => '${value} và trên';
	@override String atMost({required Object value}) => 'Tối đa ${value}';
	@override String dateLastDays({required Object count}) => '${count} ngày trước';
	@override String get dateLastYear => 'năm ngoái';
	@override String dateOlderThanDays({required Object count}) => 'Tuổi hơn ${count} ngày';
	@override String get dateOlderThanYear => 'Độ tuổi hơn 1 năm';
}

// Path: libraries.selection
class _Translations$libraries$selection$vi extends Translations$libraries$selection$en {
	_Translations$libraries$selection$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get selectItems => 'Chọn mục';
	@override String selectedCount({required Object count}) => '${count} được chọn';
	@override String get actions => 'Tùy chọn hành động';
	@override String get confirmDescendants => 'Điều này thay đổi tất cả các tập trong các chương trình và mùa được chọn.';
	@override String get confirmUnwatched => 'Thao tác này cũng xóa tiến trình phát của các mục đã chọn.';
	@override String confirmCount({required Object count}) => 'Các mục được chọn: ${count}.';
	@override String completed({required Object count}) => 'Các mục được cập nhật: ${count}.';
	@override String partialFailure({required Object succeeded, required Object failed}) => 'Cập nhật ${succeeded}; thất bại ${failed}. mục thất bại vẫn được chọn.';
}

// Path: explore.mdblistShelves
class _Translations$explore$mdblistShelves$vi extends Translations$explore$mdblistShelves$en {
	_Translations$explore$mdblistShelves$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get manage => 'Quản lý Khám phá Vườn';
	@override String get manageDescription => 'Chọn và sắp xếp danh sách từ tài khoản MDBList của bạn';
	@override String get description => 'Chọn danh sách phim và truyền hình công cộng từ tài khoản MDBList của bạn.Tạo hoặc sao chép danh sách trên MDBList, sau đó làm mới.';
	@override String get selected => 'Chọn Chọn Chọn';
	@override String get available => 'Danh sách tài khoản có sẵn';
	@override String get noLists => 'Không có danh sách phim công cộng hoặc TV được trả về.Tạo hoặc sao chép một danh sách trên MDBList, sau đó làm mới.';
	@override String get displayName => 'Shelf hiển thị tên';
	@override String get nameHint => 'Để lại màu trắng để sử dụng tên danh sách nguồn.';
	@override String get add => 'Thêm Shelf';
	@override String get save => 'Bảo vệ shelves';
	@override String moveUp({required Object title}) => 'Chuyển ${title} lên';
	@override String moveDown({required Object title}) => 'Chuyển ${title} xuống';
	@override String get unavailable => 'Danh sách này không sẵn dùng. rút hoặc xóa hộp trong cài đặt.';
	@override String get rateLimited => 'MDBList yêu cầu giới hạn đã đạt được. xin vui lòng rút lại sau.';
	@override String get loadFailed => 'Không thể tải các tấm. kiểm tra kết nối của bạn và rút.';
	@override String get saveFailed => 'Không thể bỏ qua được, xin vui lòng rút lui.';
	@override String get accountChanged => 'Tài khoản hoặc hồ sơ đã thay đổi. mở lại các cài đặt này.';
	@override String get settingsUnreadable => 'Các tab được tiết kiệm không thể được đọc. chọn danh sách của bạn một lần nữa để thay thế các cài đặt này.';
}

// Path: explore.rows
class _Translations$explore$rows$vi extends Translations$explore$rows$en {
	_Translations$explore$rows$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'Danh sách Watchlist';
	@override String get recommendedMovies => 'Phim khuyến cáo';
	@override String get recommendedShows => 'Ưu đãi show';
	@override String get trendingMovies => 'Phim Trending';
	@override String get trendingShows => 'Xu hướng show';
	@override String get popularMovies => 'Phim phổ biến';
	@override String get popularShows => 'Ưu đãi phổ biến';
	@override String get trendingAnime => 'Xu hướng Anime';
	@override String get suggestedAnime => 'Anime đề xuất';
	@override String get airingAnime => 'Lời bài hát: Top Airing Anime';
	@override String get popularAnime => 'Anime phổ biến nhất';
	@override String get trending => 'xu hướng';
	@override String get upcomingMovies => 'phim sắp tới';
	@override String get upcomingShows => 'Các chương trình sắp tới';
}

// Path: explore.status
class _Translations$explore$status$vi extends Translations$explore$status$en {
	_Translations$explore$status$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get airing => 'không khí';
	@override String get ended => 'Đã Kết Thúc';
	@override String get canceled => 'hủy';
	@override String get upcoming => 'Sắp Công Chiếu';
}

// Path: explore.badge
class _Translations$explore$badge$vi extends Translations$explore$badge$en {
	_Translations$explore$badge$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} phổ biến';
	@override String rankAiring({required Object n}) => '#${n} không khí';
	@override String rankRated({required Object n}) => '#${n} đánh giá';
	@override String rankTrending({required Object n}) => '#${n} xu hướng';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} trong ${season}';
	@override String watchingNow({required Object n}) => '${n} xem';
	@override String get available => 'Sẵn có';
	@override String get partiallyAvailable => 'Phần có sẵn';
	@override String get availableIn4k => '4K có sẵn';
	@override String get requested => 'yêu cầu';
	@override String get pendingApproval => 'Thời gian chấp thuận';
	@override String get processing => 'xử lý';
	@override String get declined => 'giảm';
	@override String get requestFailed => 'yêu cầu thất bại';
	@override String get requested4k => '4K yêu cầu';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} mùa';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => 'Ep ${episode} trong ${duration}';
	@override String nextAiringIn({required Object duration}) => 'Tiếp theo tại ${duration}';
	@override String episodesShort({required Object n}) => '${n} tập';
	@override String minutesPerEpisode({required Object n}) => '${n} phút/tập';
	@override String get adult => '18+';
}

// Path: explore.stats
class _Translations$explore$stats$vi extends Translations$explore$stats$en {
	_Translations$explore$stats$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} Danh sách';
	@override String viewersDay({required Object n}) => '${n} xem ngày hôm nay';
	@override String viewersWeek({required Object n}) => '${n} xem trong tuần này';
	@override String viewersMonth({required Object n}) => '${n} xem trong tháng này';
	@override String viewersYear({required Object n}) => '${n} xem năm nay';
	@override String viewersAllTime({required Object n}) => '${n} người xem';
	@override String planning({required Object n}) => '${n} kế hoạch để xem';
	@override String favorited({required Object n}) => '${n} yêu thích';
	@override String dropRate({required Object percent}) => '${percent} đã bỏ qua nó';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} bình luận',
	);
	@override String votes({required Object n}) => '${n} phiếu bầu';
	@override String watching({required Object n}) => '${n} xem nó';
	@override String completed({required Object n}) => '${n} hoàn thành';
	@override String onHold({required Object n}) => '${n} trên nắm giữ';
	@override String dropped({required Object n}) => '${n} Đã mất';
}

// Path: explore.season
class _Translations$explore$season$vi extends Translations$explore$season$en {
	_Translations$explore$season$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get winter => 'Mùa đông';
	@override String get spring => 'Xuân';
	@override String get summer => 'Mùa hè';
	@override String get fall => 'rơi';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class _Translations$explore$format$vi extends Translations$explore$format$en {
	_Translations$explore$format$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get tv => 'TV';
	@override String get tvShort => 'TV ngắn';
	@override String get movie => 'Phim';
	@override String get special => 'đặc biệt';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => 'Nhạc';
	@override String get other => 'Khác';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$vi extends Translations$explore$sourceMaterial$en {
	_Translations$explore$sourceMaterial$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get original => 'nguyên bản';
	@override String get manga => 'Manga';
	@override String get lightNovel => 'Ánh sáng novel';
	@override String get novel => 'Tiểu thuyết';
	@override String get visualNovel => 'Visual Novel Giới thiệu';
	@override String get game => 'Trò chơi';
	@override String get webComic => 'Trang web Comic';
	@override String get musicRelease => 'Nhạc';
	@override String get otherMedia => 'Khác';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$vi extends Translations$explore$creditRole$en {
	_Translations$explore$creditRole$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get actor => 'Diễn viên';
	@override String get director => 'Đạo Diễn';
	@override String get writer => 'Người viết';
	@override String get producer => 'Nhà sản xuất';
	@override String get creator => 'Người sáng tạo';
	@override String get composer => 'Nhà soạn nhạc';
}

// Path: explore.relation
class _Translations$explore$relation$vi extends Translations$explore$relation$en {
	_Translations$explore$relation$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get prequel => 'Prequê';
	@override String get sequel => 'tiếp theo';
	@override String get sideStory => 'Câu chuyện bên';
	@override String get spinOff => 'Ngoại truyện';
	@override String get alternativeVersion => 'Phiên bản thay thế';
	@override String get summary => 'Tổng hợp';
	@override String get parentStory => 'Câu chuyện cha mẹ';
	@override String get adaptation => 'thích ứng';
	@override String get other => 'liên quan';
}

// Path: explore.detail
class _Translations$explore$detail$vi extends Translations$explore$detail$en {
	_Translations$explore$detail$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'Tiêu đề gốc';
	@override String get alsoKnownAs => 'cũng được biết đến như';
	@override String get studios => 'Hãng Phim';
	@override String get country => 'đất nước';
	@override String get language => 'Ngôn ngữ';
	@override String get released => 'Giải phóng';
	@override String get physicalRelease => 'trên đĩa';
	@override String get ended => 'Đã Kết Thúc';
	@override String addedOn({required Object date}) => 'Thêm ${date}';
	@override String get yourRating => 'Đánh giá của bạn';
	@override String get budget => 'ngân sách';
	@override String get revenue => 'Box văn phòng';
	@override String get contentAdvisory => 'Lời hướng dẫn tuổi';
	@override String get tags => 'Thẻ';
	@override String get revealSpoilerTags => 'Hiển thị spoiler tags';
	@override String get links => 'trái';
	@override String get watchOn => 'Xem tại';
	@override String get watchTrailer => 'Xem trailer';
	@override String openOn({required Object site}) => 'Khởi mở tại ${site}';
	@override String get crew => 'phi hành đoàn';
	@override String get ratings => 'Đánh giá';
	@override String get schedule => 'Lên lịch';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n,
		other: 'Đề nghị bởi ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} người dùng',
	);
	@override String recommendedBy({required Object who}) => 'Đề nghị bởi ${who}';
	@override String favoritedBy({required Object who}) => 'Ưu đãi của ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} chưa được trình bày';
	@override String recommendedByPercent({required Object percent}) => 'Đề nghị bởi ${percent} người xem';
	@override String get relatedTitles => 'Các tiêu đề liên quan';
	@override String get background => 'nền';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$vi extends Translations$liveTv$recordSettings$en {
	_Translations$liveTv$recordSettings$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get startEarly => 'Bắt đầu sớm (từ 2 giây)';
	@override String get endLate => 'Kết thúc muộn (tạm dịch: Seconds)';
	@override String get newOnly => 'Chỉ có các tập mới';
	@override String get anyChannel => 'Ghi âm trên bất kỳ kênh nào';
	@override String get anyTime => 'Ghi chú bất cứ lúc nào';
	@override String get skipInLibrary => 'Tải các tập phim đã ở trong thư viện';
	@override String get keepUpTo => 'Các sự kiện để duy trì';
	@override String get keepUpToHint => '0 giữ cho mỗi tập';
}

// Path: music.discography
class _Translations$music$discography$vi extends Translations$music$discography$en {
	_Translations$music$discography$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'Đĩa đơn và EP';
	@override String get live => 'Trực tiếp';
	@override String get compilations => 'Tuyển tập';
}

// Path: watchTogether.notices
class _Translations$watchTogether$notices$vi extends Translations$watchTogether$notices$en {
	_Translations$watchTogether$notices$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name} áp lực chơi';
	@override String get playbackStarted => 'Playback bắt đầu';
	@override String paused({required Object name}) => '${name} nghỉ ngơi';
	@override String get playbackPaused => 'Playback nghỉ ngơi';
	@override String jumpedTo({required Object name, required Object position}) => '${name} nhảy lên ${position}';
	@override String roomJumpedTo({required Object position}) => 'Đang xem mục từ: ${position}';
	@override String changedSpeed({required Object name, required Object speed}) => '${name} đặt tốc độ lên ${speed}';
	@override String speedChanged({required Object speed}) => 'Tốc độ được thiết lập lên đến ${speed}';
	@override String startedMedia({required Object name, required Object title}) => '${name} bắt đầu ${title}';
	@override String mediaStarted({required Object title}) => 'Bây giờ chơi ${title}';
	@override String stoppedMedia({required Object name}) => '${name} dừng video';
	@override String get mediaStopped => 'Video đã dừng lại';
	@override String waitingFor({required Object name}) => 'Đang xem mục từ: ${name}';
	@override String get waitingForSomeone => 'Chờ đợi ai đó bắt được...';
	@override String get finished => 'Kết thúc';
	@override String hostChangedTo({required Object name}) => '${name} hiện đang là chủ nhà';
	@override String get youAreNowHost => 'Bây giờ bạn là người chủ';
	@override String joined({required Object name}) => '${name} tham gia';
	@override String left({required Object name}) => '${name} đã rời đi';
	@override String get controlRefused => 'Chỉ có chủ sở hữu mới có thể kiểm soát playback';
	@override String get searchFailed => 'Một số máy chủ không thể được tìm kiếm cho video của phòng';
	@override String get playBlocked => 'Tải về trò chơi để bắt đầu';
	@override String get shareFailed => 'Tôi không thể chia sẻ video này với phòng';
	@override String get downloadNotShared => 'Tải xuống không được chia sẻ với phòng trong khi máy chủ của họ offline';
	@override String get openFailed => 'Không thể mở video phòng';
}

// Path: watchTogether.ended
class _Translations$watchTogether$ended$vi extends Translations$watchTogether$ended$en {
	_Translations$watchTogether$ended$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get ended => 'Khách mời kết thúc phòng';
	@override String get kicked => 'Bạn bị loại bỏ khỏi phòng';
	@override String get expired => 'Phòng trôi qua';
	@override String get replaced => 'Bạn đã kết nối phòng này trên thiết bị khác';
	@override String get lost => 'Mất kết nối với phòng';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$vi extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => 'Mã có 6 chữ cái và số, mà không có 0, 1, I, L hoặc O.';
	@override String get roomNotFound => 'Không có phòng nào có mã đó, có lẽ nó đã kết thúc.';
	@override String get roomFull => 'Căn phòng đó đầy.';
	@override String get roomLocked => 'Người chủ đã đóng cửa căn phòng đó.';
	@override String get relayFull => 'Xem cùng nhau đang bận rộn ngay bây giờ. thử lại sau này.';
	@override String get unreachable => 'Tôi không thể đạt được đồng hồ cùng nhau phát sóng. kiểm tra kết nối của bạn.';
	@override String get rateLimited => 'Đã có quá nhiều nỗ lực, hãy đợi một phút và thử lại.';
	@override String get clientBlocked => 'Phiên bản PlezyNG này không thể sử dụng bản phát.';
	@override String get forbidden => 'Chỉ có chủ nhà mới có thể làm được điều đó.';
	@override String get notInRoom => 'Bạn không ở trong một căn phòng.';
	@override String get alreadyInRoom => 'Bạn đã ở trong một căn phòng.';
	@override String get resumeFailed => 'Tôi không thể vào phòng.';
	@override String get unsupported => 'Truyền thông không ủng hộ điều này.';
	@override String get generic => 'Có điều gì đó sai rồi, hãy thử lại.';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$vi extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'Tải xuống sẽ dừng lại khi bạn rời khỏi ứng dụng';
	@override String get bannerDegraded => 'Tải xuống nền có thể bị giới hạn';
	@override String get bannerAction => 'chi tiết';
	@override String get sheetTitle => 'Tải xuống nền bị chặn';
	@override String get sheetTitleDegraded => 'Tải xuống nền có thể bị giới hạn';
	@override String get sheetIntro => 'Android ngăn cản PlezyNG tải về đáng tin cậy trong nền.';
	@override String get sheetIntroDegraded => 'Thiết bị của bạn đang giới hạn khi PlezyNG có thể tải về trong nền.';
	@override String get reasonBackgroundRestricted => 'Sử dụng nền của PlezyNG là hạn chế. thiết lập sử dụng pin hoặc nền của nó là "Không hạn chế".';
	@override String get reasonStandbyRestricted => 'Android đã đặt PlezyNG trong trạng thái đứng hạn chế. đặt sử dụng pin của nó lên "Không hạn chế".';
	@override String get reasonDownloadChannelBlocked => 'Thông báo tải xuống bị tắt, vì vậy tiến bộ và kiểm soát có thể không sẵn dùng.';
	@override String get reasonNotificationsDisabled => 'Thông báo được tắt. trên Android 13 hoặc mới hơn, chúng được yêu cầu cho tải xuống nền dài.';
	@override String get reasonDataSaver => 'Data Saver là trên, mà chặn tải xuống nền trên dữ liệu di động. tải xuống vẫn nên chạy trên Wi-Fi.';
	@override String get reasonOemUnknown => 'Tải về đã ngừng lại nhiều lần trong khi PlezyNG đang ở trong nền. kiểm tra cài đặt pin hoặc nền của PlezyNG.';
	@override String get openSettings => 'cài đặt mở';
	@override String get stillNotWorking => '- Hỗ trợ cụ thể thiết bị';
	@override String get stillNotWorkingDescription => 'Xem các bước cho thiết bị của bạn, hoặc gửi một sổ ghi chép từ Cài đặt › Xem sổ ghi chép nếu vấn đề tiếp tục.';
	@override String get dialogTitle => 'Download có thể không kết thúc';
	@override String get dialogDownloadAnyway => 'Download bất cứ điều gì';
	@override String get dialogFixFirst => 'Đặt điều này trước';
	@override String get statusTile => 'Background Downloads';
	@override String get statusOk => 'được phép chạy trong nền';
	@override String get statusBlocked => 'Chặn bởi hệ thống cài đặt';
	@override String get statusDegraded => 'Giới hạn bởi thiết lập hệ thống';
	@override String get statusUnknown => 'chưa kiểm tra';
	@override String get settingsUnavailable => 'Không thể mở cài đặt hệ thống trên thiết bị này';
	@override String get linkUnavailable => 'Không thể mở dontkillmyapp.com trên thiết bị này';
}

// Path: downloads.groupings
class _Translations$downloads$groupings$vi extends Translations$downloads$groupings$en {
	_Translations$downloads$groupings$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get library => 'Thư viện';
	@override String get collections => 'Bộ Sưu Tập';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$vi extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Bắt đầu máy chủ từ xa';
	@override String get hostAddress => 'Địa chỉ Host';
	@override String get connected => 'Kết nối';
	@override String get serverRunning => 'Remote Server hoạt động';
	@override String get serverStopped => 'Remote server bị dừng lại';
	@override String get serverRunningDescription => 'Các thiết bị di động trên mạng của bạn có thể kết nối với ứng dụng này';
	@override String get serverStoppedDescription => 'Bắt đầu máy chủ để cho phép các thiết bị di động kết nối';
	@override String get usePhoneToControl => 'Sử dụng thiết bị di động của bạn để kiểm soát ứng dụng này';
	@override String get startServer => 'Bắt đầu server';
	@override String get stopServer => 'Ngừng Server';
	@override String get minimize => 'giảm thiểu';
	@override String get manualAddressHint => 'Địa chỉ kết nối thủ công:';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$vi extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Các thiết bị PlezyNG với cùng tài khoản Plex xuất hiện tại đây';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Kết nối...';
	@override String get searchingForDevices => 'Tìm kiếm các thiết bị...';
	@override String get noDevicesFound => 'Không tìm thấy thiết bị trên mạng của bạn';
	@override String get noDevicesHint => 'Mở PlezyNG trên máy tính để bàn và sử dụng cùng Wi-Fi';
	@override String get availableDevices => 'Thiết bị có sẵn';
	@override String get manualConnection => 'Manual kết nối';
	@override String get cryptoInitFailed => 'Không thể bắt đầu kết nối an toàn. đăng nhập lên Plex đầu tiên.';
	@override String get validationHostRequired => 'Vui lòng nhập địa chỉ host';
	@override String get validationHostFormat => 'Định dạng phải là IP:port (ví dụ: 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Kết nối tạm thời: Sử dụng cùng một mạng trên cả hai thiết bị.';
	@override String get sessionNotFound => 'Thiết bị không được tìm thấy. đảm bảo PlezyNG đang chạy trên máy chủ.';
	@override String get authFailed => 'Cả hai thiết bị đều cần cùng một tài khoản Plex.';
	@override String failedToConnect({required Object error}) => 'Không kết nối: ${error}';
	@override String get codeTitle => 'Cặp code';
	@override String get codeDescription => 'Nhập mã được hiển thị trong Companion Remote trên thiết bị chủ. Cả hai thiết bị phải sử dụng một phiên bản hỗ trợ cặp an toàn.';
	@override String get codeInvalid => 'Nhập tất cả 32 chữ cái và số từ mã host.';
	@override String get updateRequired => 'Cập nhật cả hai thiết bị đến một phiên bản hỗ trợ cặp an toàn.';
	@override String get hostDescription => 'Nhập mã này một lần trên mỗi remote. giữ nó riêng tư: nó cho phép kiểm soát hồ sơ này.';
	@override String get resetCode => 'Đặt lại mã cặp';
	@override String get resetDescription => 'Tắt tất cả các từ xa và tạo một mã mới. mỗi từ xa sẽ cần phải cặp lại.';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$vi extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Bạn muốn tắt kết nối từ phiên từ xa?';
	@override String get reconnecting => 'Kết nối lại...';
	@override String attemptOf({required Object current}) => 'Thử ${current} của 5';
	@override String get retryNow => 'Trở lại bây giờ';
	@override String get tabRemote => 'Khoảng cách';
	@override String get tabPlay => 'Phát';
	@override String get tabMore => 'Thêm';
	@override String get menu => 'Menu';
	@override String get tabNavigation => 'Tab Navigation Đánh giá';
	@override String get tabDiscover => 'Khám phá';
	@override String get tabLibraries => 'Thư viện';
	@override String get tabSearch => 'Tìm kiếm';
	@override String get tabDownloads => 'Nội dung tải xuống';
	@override String get tabSettings => 'Cài đặt';
	@override String get previous => 'Trước';
	@override String get playPause => 'Chơi / Pause';
	@override String get next => 'Kế tiếp';
	@override String get seekBack => 'Tìm lại';
	@override String get stop => 'Ngưng';
	@override String get seekForward => 'Tìm kiếm FWD';
	@override String get volume => 'Số lượng';
	@override String get volumeDown => 'Xuống';
	@override String get volumeUp => 'Lên';
	@override String get fullscreen => 'Toàn màn hình';
	@override String get subtitles => 'Phụ đề';
	@override String get audio => 'Âm thanh';
	@override String get searchHint => 'Tìm kiếm trên desktop';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$vi extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'Không tìm thấy giao diện mạng';
	@override String get authenticationFailed => 'xác thực thất bại';
	@override String serverStartFailed({required Object error}) => 'Không khởi động máy chủ từ xa: ${error}';
	@override String commandFailed({required Object error}) => 'Không gửi lệnh từ xa: ${error}';
	@override String get joinTimedOut => 'Thời gian tham gia phiên';
	@override String get failedToConnectAnyAddress => 'Không kết nối với bất kỳ địa chỉ nào';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'Kết nối bị mất sau ${attempts} nỗ lực';
	@override String get connectionLost => 'Kết nối mất';
}

// Path: services.names
class _Translations$services$names$vi extends Translations$services$names$en {
	_Translations$services$names$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class _Translations$services$simklReconnect$vi extends Translations$services$simklReconnect$en {
	_Translations$services$simklReconnect$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Kết nối Simkl';
	@override String get subtitle => 'Simkl là loại bỏ phương pháp đăng nhập sử dụng kết nối này. tái kết nối mở simkl.com để chấp thuận PlezyNG — PlezyNG không bao giờ thấy mật khẩu của bạn. lịch sử đồng hồ của bạn vẫn ở trên Simkl.';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$vi extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Chạy PlezyNG trên ${service}';
	@override String get instructions => 'Kiểm tra mã QR, hoặc truy cập địa chỉ dưới đây và nhập mã này:';
	@override String openToActivate({required Object service}) => 'Mở ${service} để kích hoạt';
	@override String get copyCode => 'copy code kích hoạt';
	@override String get waitingForAuthorization => 'Đang chờ sự cho phép...';
	@override String get codeCopied => 'Mã copy';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$vi extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Đăng ký tại ${service}';
	@override String get body => 'Scan mã QR này hoặc mở URL trên bất kỳ thiết bị nào.';
	@override String openToSignIn({required Object service}) => 'Mở ${service} để đăng ký';
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$vi extends Translations$services$pendingAuth$en {
	_Translations$services$pendingAuth$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'Bản sao sign-in URL';
	@override String get urlCopied => 'URL sao chép';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$vi extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Thư viện Filter';
	@override String get subtitleAllSyncing => 'Tích hợp tất cả các thư viện';
	@override String get subtitleNoneSyncing => 'Không synchronize gì';
	@override String subtitleBlocked({required Object count}) => '${count} bị chặn';
	@override String subtitleAllowed({required Object count}) => '${count} được phép';
	@override String get mode => 'Phương pháp lọc';
	@override String get modeBlacklist => 'Danh sách đen';
	@override String get modeWhitelist => 'Danh sách trắng';
	@override String get modeHintBlacklist => 'Đồng bộ tất cả các thư viện ngoại trừ những thư viện được kiểm tra dưới đây.';
	@override String get modeHintWhitelist => 'Đồng bộ chỉ các thư viện được kiểm tra dưới đây.';
	@override String get libraries => 'Thư viện';
	@override String get noLibraries => 'Không có thư viện';
	@override String get modeDescription => 'Chọn xem các thư viện được kiểm tra có bị chặn khỏi đồng bộ hoặc là thư viện duy nhất đồng bộ.';
}

// Path: services.trackerDescriptions
class _Translations$services$trackerDescriptions$vi extends Translations$services$trackerDescriptions$en {
	_Translations$services$trackerDescriptions$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get trakt => 'Đồng bộ xem các tập và phim với tài khoản Trakt của bạn.';
	@override String get mal => 'Đồng bộ danh sách anime và xem tiến trình với MyAnimeList.';
	@override String get anilist => 'Đồng bộ danh sách anime và xem tiến bộ với AniList.';
	@override String get simkl => 'Sync xem phim, chương trình truyền hình và anime với Simkl.';
	@override String get mdblist => 'Hiển thị xếp hạng và danh sách MDBList trong khuyến nghị và Khám phá.';
}

/// The flat map containing all translations for locale <vi>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsVi {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'appIcon.title' => 'ứng dụng icon',
			'appIcon.defaultIcon' => 'Mặc Định',
			'appIcon.current' => 'Icon hiện tại',
			'appIcon.locked' => 'Thời gian tiếp cận cần thiết',
			'appIcon.lockedHint' => 'Bắt đầu thử nghiệm 7 ngày của bạn hoặc mở khóa PlezyNG cho đời để sử dụng các biểu tượng thay thế.',
			'appIcon.changeFailed' => 'Không thể thay đổi icon ứng dụng',
			'appIcon.launcherHint' => 'biểu tượng mới sẽ xuất hiện trên màn hình nhà của bạn một khi bạn rời khỏi PlezyNG.',
			'appIcon.tvLauncherHint' => 'Banner mới xuất hiện một khi bạn rời khỏi PlezyNG. Android TV có thể tiếp tục hiển thị một cũ cho đến khi TV khởi động lại.',
			'appIcon.names.midnight' => 'nửa đêm',
			'appIcon.names.ember' => 'người',
			'appIcon.names.paper' => 'giấy',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => 'Line Đề',
			'appIcon.names.ocean' => 'Đại dương',
			'appIcon.names.ultraviolet' => 'Tử ngoại',
			'appIcon.names.matcha' => 'Matcha',
			'appIcon.names.sunset' => 'Hoàng hôn',
			'appIcon.names.gold' => 'vàng',
			'appIcon.names.titanium' => 'Titanic',
			'appIcon.names.glass' => 'kính',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => 'Synthwave',
			'appIcon.names.pixel' => 'Pixel',
			'appIcon.names.neon' => 'Neon',
			'appIcon.names.sticker' => 'Nhãn dán',
			'appIcon.names.ticket' => 'Vé',
			'appIcon.names.pop' => 'Pop',
			'appIcon.names.strata' => 'đường phố',
			'appIcon.names.facet' => 'mặt',
			'appIcon.names.tilde' => 'Tilde',
			'appIcon.description' => 'Chọn biểu tượng được hiển thị bởi người khởi động thiết bị của bạn. các bản xem trước cho thấy mỗi tùy chọn trông như thế nào.',
			'auth.signInWithPlex' => 'Đăng ký với Plex',
			'auth.showQRCode' => 'Hiển thị QR Code',
			'auth.authenticate' => 'xác thực',
			'auth.authenticationTimeout' => 'Chứng nhận đã hết hạn, xin vui lòng thử lại.',
			'auth.scanQRToSignIn' => 'Scan mã QR này để đăng ký',
			'auth.waitingForAuth' => 'Đang chờ xác thực... Đăng nhập từ trình duyệt của bạn.',
			'auth.useBrowser' => 'Sử dụng browser',
			'auth.or' => 'hoặc',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'Kết nối với ${product}',
			'auth.quickConnect' => 'Kết Nối Nhanh',
			'auth.useQuickConnect' => 'Dùng kết nối nhanh',
			'auth.quickConnectInstructions' => 'Mở Quick Connect trong Jellyfin và nhập mã này.',
			'auth.quickConnectWaiting' => 'Đang chờ sự chấp thuận...',
			'auth.quickConnectCancel' => 'Hủy bỏ',
			'auth.quickConnectExpired' => 'Quick Connect đã hết hạn. thử lại.',
			'auth.localDataRecoveryRequired' => 'PlezyNG không thể khôi phục an toàn dữ liệu đăng nhập cục bộ và dữ liệu phát đang chờ xử lý. Vui lòng đăng nhập lại.',
			'auth.pinCheckRejected' => 'Kiểm tra PIN Plex đã bị từ chối',
			'auth.connectToDirectPlex' => 'Kết nối với máy chủ địa phương Plex',
			'common.cancel' => 'Hủy bỏ',
			'common.save' => 'Lưu',
			'common.close' => 'Đóng',
			'common.closeMiniPlayer' => 'Trò chơi mini gần',
			'common.closeWorkspaceWindow' => 'cửa sổ gần',
			'common.returnToFullView' => 'Trở về View Full',
			'common.manageMediaSessions' => 'Quản lý các phiên truyền thông',
			'common.hideMediaSessions' => 'Giữ các buổi truyền thông',
			'common.mediaSessions' => 'Các buổi truyền thông',
			'common.mediaSessionsHint' => 'Chọn để đưa một phiên về phía trước. Park che giấu cửa sổ của nó nhưng giữ cho nó mở. Return mở nó trong toàn diện; gần kết thúc nó.',
			'common.sessionInWorkspace' => 'trong Workspace',
			'common.sessionParked' => 'đậu xe',
			'common.sessionFullscreen' => 'màn hình đầy đủ',
			'common.switchToNextWindow' => 'Chuyển đổi với cửa sổ tiếp theo',
			'common.moveWindow' => 'di chuyển cửa sổ',
			'common.finishMovingWindow' => 'Kết thúc cửa sổ di chuyển',
			'common.moveWindowHint' => 'Nhấn dài và kéo cửa sổ để di chuyển nó. điều khiển này cũng cho phép phong trào mũi tên-chìa khóa.',
			'common.movingWindowHelp' => 'Tắt để di chuyển · Cài đặt chìa khóa · Enter Saves · Escape Cancel',
			'common.resizeWindow' => 'Tải lại cửa sổ',
			'common.resizeWindowHint' => 'Tắt bàn tay này hoặc sử dụng chìa khóa mũi tên để khôi phục lại cửa sổ.',
			'common.workspaceWindowHint' => 'Sử dụng điều khiển chuyển động hoặc kéo dài và kéo để di chuyển.',
			'common.workspacePaneHint' => 'Chọn bảng điều khiển này để tập trung vào nó. Sử dụng kiểm soát màn hình đầy đủ của nó để mở rộng.',
			'common.workspaceWindowLabel' => ({required Object title}) => 'Màn hình: ${title}',
			'common.workspaceTitleHint' => 'Chọn để tập trung. kéo thanh tiêu đề để di chuyển; sử dụng nút màn hình đầy đủ để mở rộng.',
			'common.moveToSessionTray' => 'Chuyển sang session tray',
			'common.moveToSessionTrayHint' => 'Khóa phiên này có sẵn mà không hiển thị cửa sổ của nó.',
			'common.closeSessionHint' => 'Bắt cửa sổ này và kết thúc phiên.',
			'common.sideBySideLayout' => 'Chuyển đổi sang side-by-side layout',
			'common.floatingWindows' => 'Chuyển đổi để floating windows',
			'common.clear' => 'rõ ràng',
			'common.reset' => 'Đặt lại',
			'common.later' => 'Sau đó',
			'common.submit' => 'Gửi đi',
			'common.confirm' => 'xác nhận',
			'common.retry' => 'Thử lại',
			'common.logout' => 'Đăng nhập',
			'common.unknown' => 'Không rõ',
			'common.refresh' => 'Làm mới',
			'common.yes' => 'Đúng',
			'common.no' => 'Không',
			'common.delete' => 'Xóa',
			'common.edit' => 'Sửa',
			'common.shuffle' => 'Phát ngẫu nhiên',
			'common.addTo' => 'Thêm vào...',
			'common.createNew' => 'Tạo mới',
			'common.connect' => 'Kết nối',
			'common.disconnect' => 'Ngắt kết nối',
			'common.play' => 'Phát',
			'common.pause' => 'Tạm dừng',
			'common.resume' => 'Tiếp tục phát',
			'common.error' => 'Lỗi',
			'common.search' => 'Tìm kiếm',
			'common.home' => 'Trang chủ',
			'common.back' => 'Quay lại',
			'common.settings' => 'Cài đặt',
			'common.mute' => 'Tắt Tiếng',
			'common.ok' => 'Đồng Ý',
			'common.off' => 'Tắt',
			'common.options' => 'Lựa chọn',
			'common.seasonNumber' => ({required Object number}) => 'Mùa ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'Chương ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'Chương ${number}',
			'common.reconnect' => 'nối lại',
			'common.viewAll' => 'Xem tất cả',
			'common.checkingNetwork' => 'Kiểm tra mạng...',
			'common.loadingServers' => 'Các máy chủ tải...',
			'common.connectingToServers' => 'Kết nối với máy chủ...',
			'common.startingOfflineMode' => 'Bắt đầu offline...',
			'common.loading' => 'tải...',
			'common.fullscreen' => 'Toàn màn hình',
			'common.exitFullscreen' => 'Khởi hành Fullscreen',
			'common.pressBackAgainToExit' => 'Nhấn trở lại để ra ngoài',
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
			'common.mediaKind.movie' => 'Phim',
			'common.mediaKind.show' => 'show show',
			'common.mediaKind.season' => 'Phần',
			'common.mediaKind.episode' => 'Tập',
			'common.mediaKind.artist' => 'Ca Sĩ',
			'common.mediaKind.album' => 'Tuyển Tập',
			'common.mediaKind.track' => 'Bản ghi',
			'common.mediaKind.collection' => 'Bộ Sưu Tập',
			'common.mediaKind.playlist' => 'Danh sách phát',
			'common.mediaKind.clip' => 'Video ngắn',
			'common.mediaKind.photo' => 'Hình Ảnh',
			'common.mediaKind.folder' => 'Thư mục',
			'screens.licenses' => 'Giấy phép',
			'screens.switchProfile' => 'Tính năng Switch Profile',
			'screens.subtitleStyling' => 'Kiểu phụ đề',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Nhật ký',
			'update.available' => 'Update có sẵn',
			'update.versionAvailable' => ({required Object version}) => 'Phiên bản ${version} có sẵn',
			'update.currentVersion' => ({required Object version}) => 'Hiện tại: ${version}',
			'update.skipVersion' => 'Tải phiên bản này',
			'update.viewRelease' => 'Xem bản phát hành',
			'update.latestVersion' => 'Bạn đang ở phiên bản mới nhất',
			'update.checkFailed' => 'Không kiểm tra cho các bản cập nhật',
			'settings.title' => 'Cài đặt',
			'settings.supportDeveloper' => 'Hỗ trợ PlezyNG',
			'settings.supportDeveloperDescription' => 'Ưu đãi để hỗ trợ phát triển',
			'settings.lifetimeAccess' => 'PlezyNG Thời gian truy cập',
			'settings.language' => 'Ngôn ngữ',
			'settings.theme' => 'Chủ đề',
			'settings.appearance' => 'xuất hiện',
			'settings.detailPage' => 'Trang chi tiết',
			'settings.themeSongsEnabled' => 'Chơi bài hát Theme',
			'settings.themeSongsEnabledDescription' => 'Chơi các bài hát chủ đề có sẵn trong khi xem các chi tiết truyền thông.',
			'settings.themeSongVolume' => 'Lời bài hát Volume',
			'settings.videoPlayback' => 'Phát video',
			'settings.videoPlaybackDescription' => 'Thiết lập hành vi playback',
			'settings.advanced' => 'Nâng cao',
			'settings.episodePosterMode' => 'Phong cách poster',
			'settings.seriesPoster' => 'Series bài poster',
			'settings.seasonPoster' => 'Poster mùa',
			'settings.episodeThumbnail' => 'Ảnh thu nhỏ',
			'settings.showHeroSectionDescription' => 'Hiển thị nội dung carousel trên màn hình nhà',
			'settings.secondsLabel' => 'giây',
			'settings.minutesLabel' => 'phút',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Nhập giá trị (${min}-${max})',
			'settings.systemTheme' => 'Hệ thống',
			'settings.lightTheme' => 'Ánh sáng',
			'settings.darkTheme' => 'bóng tối',
			'settings.oledTheme' => 'OLED',
			'settings.emberTheme' => 'người',
			'settings.glacierTheme' => 'Băng',
			'settings.forestTheme' => 'rừng',
			'settings.plumTheme' => 'Tím mận',
			'settings.paperTheme' => 'giấy',
			'settings.libraryDensity' => 'Dung lượng thư viện',
			'settings.displayScale' => 'Màn hình Scale',
			'settings.compact' => 'Gọn',
			'settings.comfortable' => 'thoải mái',
			'settings.gridSpacing' => 'Mạng lưới Spacing',
			'settings.gridSpacingTight' => 'Sát',
			'settings.gridSpacingNormal' => 'Bình thường',
			'settings.gridSpacingSpacious' => 'không gian',
			'settings.tvCornerSpotlightBackdrop' => 'Phân tích Spotlight Backdrop',
			'settings.tvCornerSpotlightBackdropDescription' => 'Hiển thị tác phẩm nghệ thuật trong góc trên bên phải thay vì lấp đầy màn hình',
			'settings.viewMode' => 'View Thời gian',
			'settings.gridView' => 'Mạng',
			'settings.listView' => 'Danh sách',
			'settings.showHeroSection' => 'Show Hero Phần',
			'settings.showHomeBackdrop' => 'Show home backdrop tác phẩm nghệ thuật',
			'settings.showHomeBackdropDescription' => 'Hiển thị tác phẩm nghệ thuật vĩ đại đằng sau dòng Home',
			'settings.contentScreensaverEnabled' => 'Nội dung Screensaver',
			'settings.contentScreensaverEnabledDescription' => 'Hiển thị tác phẩm nghệ thuật màn hình đầy đủ sau khi ứng dụng đã trở thành idle',
			'settings.contentScreensaverDelay' => 'Bắt đầu màn hình sau',
			'settings.contentScreensaverLibraries' => 'Thư viện Screensaver',
			'settings.contentScreensaverLibrariesDescription' => 'Chọn thư viện nào cung cấp màn hình bảo vệ công việc nghệ thuật. Nếu không có, công việc nghệ thuật từ tất cả thư viện được sử dụng.',
			'settings.contentScreensaverAllLibraries' => 'Tất cả thư viện',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} thư viện được chọn',
			'settings.contentScreensaverNoLibraries' => 'Không có thư viện truyền thông kết nối.',
			'settings.contentScreensaverDismissHint' => 'Nhấn bất kỳ nút hoặc nhấn để tháo',
			'settings.newEpisodeNotifications' => 'Thông báo episode mới',
			'settings.newEpisodeNotificationsDescription' => 'Cảnh báo khi một tập mới được thêm vào một chương trình bạn đang bị bắt. kiểm tra khi Plezy mở.',
			'settings.continueWatchingRowSize' => 'Xem thêm kích thước hàng',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => '${label} thẻ',
			'settings.rowSizeCompact' => 'Gọn',
			'settings.rowSizeStandard' => 'Tiêu chuẩn',
			'settings.rowSizeLarge' => 'Lớn',
			'settings.continueWatchingAction' => 'Tiếp tục theo dõi hành động',
			'settings.continueWatchingPlay' => 'Phát',
			'settings.continueWatchingDetails' => 'chi tiết mở',
			'settings.episodeAction' => 'Episode hành động',
			'settings.episodePlay' => 'Phát',
			'settings.episodeDetails' => 'chi tiết mở',
			'settings.useGlobalHubs' => 'Sử dụng Home Layout',
			'settings.useGlobalHubsDescription' => 'Hiển thị các hub nhà thống nhất. nếu không sử dụng các khuyến nghị thư viện.',
			'settings.showServerNameOnHubs' => 'Hiển thị tên máy chủ trên Hubs',
			'settings.showServerNameOnHubsDescription' => 'Luôn hiển thị tên máy chủ trong các tiêu đề hub.',
			'settings.groupLibrariesByServer' => 'Thư viện Nhóm bởi Server',
			'settings.groupLibrariesByServerDescription' => 'Thư viện nhóm bên dưới mỗi máy chủ truyền thông.',
			'settings.alwaysKeepSidebarOpen' => 'Luôn luôn giữ cửa sổ mở',
			'settings.alwaysKeepSidebarOpenDescription' => 'Sidebar vẫn mở rộng và khu vực nội dung được điều chỉnh để phù hợp',
			'settings.showUnwatchedCount' => 'Show Unwatched Số lượng',
			'settings.showUnwatchedCountDescription' => 'Hiển thị không được xem tập số trên các chương trình và mùa',
			'settings.showWatchedIndicators' => 'Hiển thị các chỉ số được xem',
			'settings.showWatchedIndicatorsDescription' => 'Hiển thị dấu kiểm trên các bộ phim, chương trình và các tập phim đã được xem',
			'settings.showEpisodeNumberOnCards' => 'Show Episode Number on Cards (Điểm số trên bản đồ)',
			'settings.showEpisodeNumberOnCardsDescription' => 'Hiển thị mùa và số episode trên thẻ episode',
			'settings.showSeasonPostersOnTabs' => 'Hiển thị poster mùa trên tabs',
			'settings.showSeasonPostersOnTabsDescription' => 'Hiển thị poster của mỗi mùa trên tab của nó',
			'settings.tvFullCardLayout' => 'Full TV Card',
			'settings.tvFullCardLayoutDescription' => 'Sử dụng hình ảnh-chỉ thẻ TV với tên diễn viên quá tải',
			'settings.focusGlow' => 'Tập trung Glow',
			'settings.focusGlowDescription' => 'Nhấn một ánh sáng mềm xung quanh thẻ tập trung',
			'settings.visualEffects' => 'Hiệu ứng hình ảnh',
			'settings.visualEffectsAuto' => 'Tự động',
			'settings.visualEffectsAutoDescription' => 'Tự động giảm hiệu ứng trên các thiết bị có năng lượng thấp',
			'settings.visualEffectsFull' => 'đầy đủ',
			'settings.visualEffectsReduced' => 'Giảm',
			'settings.visualEffectsReducedDescription' => 'Ít hoạt hình và các tác phẩm nghệ thuật độ phân giải thấp hơn',
			'settings.hideSpoilers' => 'Ẩn Spoilers cho Unwatched Episodes',
			'settings.hideSpoilersDescription' => 'Blur miniatures và mô tả cho các tập phim chưa được quan sát',
			'settings.playerBackend' => 'Trò chơi Backend',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Phần cứng decoding',
			'settings.hardwareDecodingDescription' => 'Sử dụng phần cứng tăng tốc khi có sẵn',
			'settings.playbackBuffer' => 'Đánh giá Playback Buffer',
			'settings.playbackBufferAuto' => 'Xe (được khuyến cáo)',
			'settings.playbackBufferLarge' => 'Lớn',
			'settings.playbackBufferExtraLarge' => 'Rất Lớn',
			'settings.playbackBufferDescription' => 'Buffer nhiều hơn so với các kết nối không ổn định. cũng giới hạn bởi Buffer Size.',
			'settings.streamBufferSize' => 'Buffer kích thước',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} MB',
			'settings.streamBufferSizeDescription' => 'Bao nhiêu video để tải về trước khi chơi trực tiếp. Transcodes dừng tại buffer transcode của máy chủ. 0 = Tự động',
			'settings.streamBufferSizeExoNote' => 'Thay thế Playback Buffer khi cài đặt, cáp ở nửa giới hạn bộ nhớ của ứng dụng',
			'settings.streamBufferMegabytes' => 'Megabyte',
			'settings.defaultQualityTitle' => 'Chất lượng mặc định',
			'settings.cellularQualityTitle' => 'Chất lượng mặc định trên Cellular',
			'settings.remoteQualityTitle' => 'chất lượng Streaming từ xa',
			'settings.remoteQualitySameAsDefault' => 'Tương tự như chất lượng mặc định',
			'settings.cellularQualitySameAsDefault' => 'Tương tự như chất lượng mặc định',
			'settings.directPlayCoveredQuality' => 'Chơi video nhỏ hơn với chất lượng ban đầu',
			'settings.directPlayCoveredQualityDescription' => 'Tải trực tiếp video trong giới hạn chất lượng thay vì chuyển mã chúng',
			'settings.videoCodecs' => 'Video Codec',
			'settings.videoCodecsDescription' => 'Các codec không được kiểm tra được mã hóa bởi máy chủ',
			'settings.videoCodecsAlwaysAccepted' => 'Luôn luôn chấp nhận',
			'settings.musicQualityTitle' => 'Chất Lượng Âm Nhạc',
			'settings.subtitleStyling' => 'Kiểu phụ đề',
			'settings.subtitleStylingDescription' => 'Tùy chỉnh Subtitle xuất hiện',
			'settings.smallSkipDuration' => 'Lớn Skip Thời gian',
			'settings.largeSkipDuration' => 'Lớn Skip Thời gian',
			'settings.rewindOnResume' => 'Rewind trên Resume',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(seconds, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} giây', ), 
			'settings.defaultSleepTimer' => 'Thời gian giấc ngủ mặc định',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(minutes, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} phút', ), 
			'settings.rememberTrackSelections' => 'Hãy nhớ các lựa chọn theo show/movie',
			'settings.chooseTracksBeforePlayback' => 'Chọn âm thanh và subtitles trước khi playback',
			'settings.chooseTracksBeforePlaybackDescription' => 'Chọn nguồn âm thanh và theo dõi subtitle trước khi mỗi video bắt đầu.',
			'settings.alwaysShowSubtitlesOnDevice' => 'Luôn hiển thị các tiêu đề trên thiết bị này',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => 'Khi máy chủ không có subtitle được chọn, hãy chọn một track địa phương. điều này không bao giờ thay đổi sở thích của máy chủ.',
			'settings.autoDownloadPreferredSubtitle' => 'Fetch thiếu các subtitles ngôn ngữ thích nhất',
			'settings.autoDownloadPreferredSubtitleDescription' => 'Chọn một tiêu đề có sẵn trong ngôn ngữ yêu thích của bạn tại địa phương. nếu không có, hãy yêu cầu máy chủ thu thập một khi được hỗ trợ.',
			'settings.rememberTrackSelectionsDescription' => 'Lưu các lựa chọn âm thanh và subtitle bằng chương trình hoặc phim trên thiết bị này',
			'settings.rememberTrackSelectionsBackendRule' => 'Làm việc tại địa phương với Plex, Jellyfin, và Emby; Plex và Jellyfin cũng có thể lưu các lựa chọn trên máy chủ',
			'settings.followServerTrackSelections' => 'Sử dụng các lựa chọn theo đoạn của máy chủ',
			'settings.followServerTrackSelectionsDescription' => 'Khi thay đổi giai đoạn, hãy áp dụng âm thanh và tiêu đề được chọn trên máy chủ thay vì mang theo sự lựa chọn hiện tại.',
			'settings.resumeMusicOnLaunch' => 'Lời bài hát Session Music',
			'settings.resumeMusicOnLaunchDescription' => 'Khởi mở lại bài hát cuối cùng nghỉ ngơi nơi nó rời đi khi ứng dụng bắt đầu',
			'settings.showChapterMarkersOnTimeline' => 'Hiển thị mục markers trên search bar',
			'settings.showChapterMarkersOnTimelineDescription' => 'Segment the search bar at chapter giới hạn',
			'settings.specialsOrdering' => 'Đặc biệt trong thứ tự episode',
			'settings.specialsOrderingDescription' => 'Nơi đặc biệt chơi trong lệnh đồng hồ của một chương trình',
			'settings.specialsOrderingServer' => 'Theo lệnh server',
			'settings.specialsOrderingAirDate' => 'Interleave by air ngày',
			'settings.specialsOrderingLast' => 'Sau mùa thường xuyên',
			'settings.clickVideoTogglesPlayback' => 'Click vào video để toggle play/pause',
			'settings.clickVideoTogglesPlaybackDescription' => 'Nhấp vào video để chơi/phút thay vì hiển thị các điều khiển.',
			'settings.videoPlayerControls' => 'Video Player kiểm soát',
			'settings.keyboardShortcuts' => 'Keyboard ngắn gọn',
			'settings.keyboardShortcutsDescription' => 'Tùy chỉnh keyboard shortcuts',
			'settings.videoPlayerNavigation' => 'Video Player hướng dẫn',
			'settings.videoPlayerNavigationDescription' => 'Sử dụng chìa khóa mũi tên để di chuyển các điều khiển video player',
			'settings.watchTogetherRelay' => 'Cùng xem Relay',
			'settings.watchTogetherRelayDescription' => 'Public Open Watch Party phát sóng trừ khi bạn đặt riêng của bạn',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.watchTogetherRelayInvalid' => 'Nhập URL cơ sở HTTP hoặc HTTPS hợp lệ của máy chủ chuyển tiếp.',
			'settings.crashReporting' => 'báo cáo crash',
			'settings.crashReportingDescription' => 'Gửi báo cáo tai nạn để giúp cải thiện ứng dụng',
			'settings.debugLogging' => 'Debug Logging Đánh giá',
			'settings.debugLoggingDescription' => 'Khả năng đăng ký chi tiết cho giải quyết vấn đề',
			'settings.viewLogs' => 'Xem Logs',
			'settings.viewLogsDescription' => 'Xem ứng dụng logs',
			'settings.clearImageCache' => 'Hình ảnh Cache',
			'settings.clearImageCacheDescription' => 'Dấu hình và hình ảnh có thể tải chậm hơn cho đến khi tải lại.',
			'settings.clearImageCacheSuccess' => 'Image cache đã được xóa thành công',
			'settings.resetSettings' => 'Cài đặt Reset',
			'settings.resetSettingsDescription' => 'Khôi phục cài đặt mặc định. điều này không thể bị bỏ qua.',
			'settings.resetSettingsSuccess' => 'Cài đặt lại thành công',
			'settings.backup' => 'Sao lưu',
			'settings.exportSettings' => 'Cài đặt xuất khẩu',
			'settings.exportSettingsDescription' => 'Lưu các tùy chọn của bạn vào một tệp',
			'settings.exportSettingsSuccess' => 'Cài đặt xuất khẩu',
			'settings.importSettings' => 'Cài đặt Import',
			'settings.importSettingsDescription' => 'khôi phục các tùy chọn từ một tệp',
			'settings.importSettingsConfirm' => 'Điều này sẽ thay thế cài đặt hiện tại của bạn. tiếp tục?',
			'settings.importSettingsSuccess' => 'Cài đặt nhập khẩu',
			'settings.importSettingsInvalidFile' => 'Tệp này không phải là một hợp lệ PlezyNG cài đặt xuất khẩu',
			'settings.importSettingsNoUser' => 'Đăng nhập trước khi nhập cài đặt',
			'settings.cloudBackup' => 'Mây Backup',
			'settings.cloudBackupDescription' => 'Sao lưu các cài đặt có thể chuyển sang thiết bị khác đến địa chỉ WebDAV qua HTTPS. Kết nối máy chủ và thông tin đăng nhập vẫn nằm trên thiết bị này.',
			'settings.cloudBackupUrl' => 'WebDAV JSON tập tin URL',
			'settings.cloudBackupUsername' => 'Tên đăng nhập',
			'settings.cloudBackupPassword' => 'Mật Khẩu',
			'settings.cloudBackupSaved' => 'Cloud Backup Destination được tiết kiệm',
			'settings.cloudBackupNow' => 'Back Up Nay',
			'settings.cloudBackupComplete' => 'Cài đặt backup uploaded',
			'settings.cloudBackupRestore' => 'khôi phục backup',
			'settings.cloudBackupRestoreConfirm' => 'Điều này sẽ thay thế các cài đặt di động phù hợp trên thiết bị này.',
			'settings.cloudBackupRestored' => 'Cài đặt khôi phục từ Cloud Backup',
			'settings.shortcutsReset' => 'Tải về Shortcuts to defaults',
			'settings.resetShortcutsConfirm' => 'Điều này sẽ thay thế các shortcuts tùy chỉnh của bạn với các default.',
			'settings.about' => 'Về',
			'settings.aboutDescription' => 'Thông tin ứng dụng và giấy phép',
			'settings.updates' => 'Cập nhật',
			'settings.updateAvailable' => 'Update có sẵn',
			'settings.checkForUpdates' => 'Kiểm tra các bản cập nhật',
			'settings.autoCheckUpdatesOnStartup' => 'Tự động kiểm tra cho các bản cập nhật trên startup',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Thông báo khi một bản cập nhật có sẵn khi khởi động',
			'settings.validationErrorEnterNumber' => 'Vui lòng nhập số hợp lệ',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Phải nằm giữa ${min} và ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Shortcut đã được quy định cho ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Shortcut cập nhật cho ${action}',
			'settings.saveFailed' => 'Không thể tiết kiệm được những thay đổi, hãy thử lại.',
			'settings.autoPlayAndSkip' => 'Tải về Auto-Play & Skip',
			'settings.autoPlayNextEpisode' => 'Auto-Play Phần tiếp theo',
			'settings.autoPlayNextEpisodeDescription' => 'Bắt đầu phần tiếp theo tự động khi một kết thúc',
			'settings.shuffleStartsFromBeginning' => 'Shuffle bắt đầu từ đầu',
			'settings.shuffleStartsFromBeginningDescription' => 'Bắt đầu mỗi giai đoạn ngay từ đầu khi bấm vào thay vì lặp lại',
			'settings.plexCinemaPreRoll' => 'Sử dụng server cinema intros',
			'settings.plexCinemaPreRollDescription' => 'Chơi cấu hình Plex Pre-rolls hoặc Jellyfin và Emby intros trước khi một bộ phim bắt đầu.',
			'settings.playNextCountdown' => 'Chơi Next Countdown',
			'settings.playNextCountdownImmediate' => 'chơi ngay lập tức',
			'settings.skipIntroMode' => 'Tải Skip Intro',
			'settings.skipIntroModeOffDescription' => 'Chơi intros bình thường mà không có nút skip',
			'settings.skipIntroModeButtonDescription' => 'Hiển thị nút skip khi một intro bắt đầu',
			'settings.skipIntroModeAutoDescription' => 'Tự động nhảy vào sau khi chậm trễ dưới đây',
			'settings.skipCreditsMode' => 'Skip tín dụng',
			'settings.skipCreditsModeOffDescription' => 'Chơi tín dụng bình thường mà không có nút skip',
			'settings.skipCreditsModeButtonDescription' => 'Hiển thị nút skip khi tín dụng bắt đầu',
			'settings.skipCreditsModeAutoDescription' => 'Tải tín dụng tự động và chơi tập tiếp theo',
			'settings.skipAdsMode' => 'Tải Ads',
			'settings.skipAdsModeOffDescription' => 'Chơi quảng cáo được phát hiện bình thường mà không cần nút skip',
			'settings.skipAdsModeButtonDescription' => 'Hiển thị nút skip khi Plex phát hiện một quảng cáo',
			'settings.skipAdsModeAutoDescription' => 'Tắt quảng cáo được phát hiện tự động sau khi trì hoãn bên dưới',
			'settings.musicPlayback' => 'Âm nhạc Playback',
			'settings.musicSweetFades' => 'Sữa Fades',
			'settings.musicSweetFadesDescription' => 'Âm nhạc Fade ở cạnh track khi Plex có dữ liệu âm thanh. album playback vẫn không thay đổi.',
			'settings.skipMarkerModeOff' => 'Tắt',
			'settings.skipMarkerModeButton' => 'Hiển thị nút',
			'settings.skipMarkerModeAuto' => 'tự động',
			'settings.forceSkipMarkerFallback' => 'Lời bài hát: Fallback Markers',
			'settings.forceSkipMarkerFallbackDescription' => 'Sử dụng mô hình tiêu đề chương ngay cả khi Plex có dấu hiệu',
			'settings.theIntroDbFallback' => 'Sử dụng TheIntroDB như một intro fallback',
			'settings.theIntroDbFallbackDescription' => 'Sử dụng lịch cộng đồng chỉ khi máy chủ không có dấu intro.',
			'settings.autoSkipDelay' => 'xe Skip chậm',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Đợi ${seconds} giây trước khi tự động nhảy',
			'settings.introPattern' => 'Nhãn hiệu Intro Marker',
			'settings.introPatternDescription' => 'Mô hình Regex để phù hợp với các markers intro trong tiêu đề',
			'settings.creditsPattern' => 'Mã tín dụng Marker Pattern',
			'settings.creditsPatternDescription' => 'Mô hình Regex để phù hợp với các tín dụng markers trong tiêu đề chương',
			'settings.prerolls' => 'Video mở đầu',
			'settings.playPrerollsBeforeMovies' => 'Trò chơi prerolls trước khi phim',
			'settings.playPrerollsBeforeMoviesDescription' => 'Chơi một clip ngẫu nhiên từ lựa chọn của bạn bên dưới trước mỗi bộ phim.',
			'settings.prerollLibrary' => 'Thư viện Preroll',
			'settings.prerollLibraryNotSet' => 'Không đặt',
			'settings.prerollLibraryNoneFound' => 'Không tìm thấy thư viện trên máy chủ của bạn.',
			'settings.prerollSelection' => 'Quyền chọn prerolls',
			'settings.prerollSelectionPickLibraryFirst' => 'Lựa chọn thư viện trước',
			'settings.prerollSelectionNoneSelected' => 'Không có ưu đãi được chọn',
			'settings.prerollSelectionCount' => ({required Object count}) => '${count} được chọn',
			'settings.prerollItemPicker' => 'Chọn prerolls',
			'settings.prerollItemPickerLoadFailed' => 'Tôi không thể tải các mục từ thư viện này.',
			'settings.invalidRegex' => '• Không có hiệu lực biểu hiện thường xuyên',
			'settings.regex' => 'biểu hiện thường xuyên',
			'settings.downloads' => 'Nội dung tải xuống',
			'settings.downloadLocationDescription' => 'Chọn nơi để lưu trữ nội dung tải xuống',
			'settings.downloadLocationDefault' => 'Chế độ lưu trữ (App Storage)',
			'settings.downloadLocationCustom' => 'Vị trí tùy chỉnh',
			'settings.selectFolder' => 'Chọn Folder',
			'settings.resetToDefault' => 'Lập lại theo mặc định',
			'settings.currentPath' => ({required Object path}) => 'Hiện tại: ${path}',
			'settings.downloadLocationChanged' => 'Download địa điểm thay đổi',
			'settings.downloadLocationReset' => 'Tải về vị trí reset to default',
			'settings.downloadLocationInvalid' => 'Mẫu được chọn không thể viết',
			'settings.downloadLocationPickerUnavailable' => 'Chọn thư mục không sẵn dùng trên thiết bị này',
			'settings.downloadOnWifiOnly' => 'Tải về trên Wi-Fi chỉ',
			'settings.downloadOnWifiOnlyDescription' => 'Tránh tải xuống khi trên dữ liệu di động',
			'settings.autoRemoveWatchedDownloads' => 'Auto-remove xem tải xuống',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Tự động xóa các tải xuống được xem',
			'settings.autoDownloadContinueWatching' => 'Auto-Download Xem tiếp',
			'settings.autoDownloadContinueWatchingDescription' => 'Giữ các mục trên hộp tiếp tục xem của bạn tải xuống, và xóa chúng một khi họ rời khỏi hộp',
			'settings.downloadQuality' => 'Download chất lượng',
			'settings.downloadQualityDescription' => 'Plex chuẩn bị một bản sao được chuyển đổi trong chuỗi tải xuống của nó. Jellyfin và Emby transcode trong khi tệp tải xuống; chuyển đổi bị gián đoạn có thể cần phải khởi động lại.',
			'settings.askDownloadQualityEachTime' => 'Chọn chất lượng cho mỗi download',
			'settings.askDownloadQualityEachTimeDescription' => 'Hiển thị chất lượng picker trước khi cheue mỗi video tải xuống',
			'settings.cellularDownloadBlocked' => 'Tải xuống bị chặn trên điện thoại di động. sử dụng Wi-Fi hoặc thay đổi thiết lập.',
			'settings.maxVolume' => 'Âm lượng tối đa',
			'settings.maxVolumeDescription' => 'Cho phép tăng âm lượng trên 100% đối với nội dung có âm thanh nhỏ',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Sự hiện diện phong phú',
			'settings.discordRichPresenceDescription' => 'Hiển thị những gì bạn đang xem trên Discord',
			'settings.services' => 'Dịch vụ',
			'settings.servicesDescription' => 'Kết nối Trakt, MyAnimeList, Seerr, và nhiều hơn nữa',
			'settings.manageLibrariesDescription' => 'Đặt lại và ẩn thư viện',
			'settings.companionRemoteServer' => 'Dịch vụ Remote Server',
			'settings.companionRemoteServerDescription' => 'Cho phép các thiết bị di động trên mạng của bạn để kiểm soát ứng dụng này',
			'settings.companionRemoteServerStartFailed' => 'Không thể khởi động máy chủ đồng nghiệp',
			'settings.companionRemoteServerStopFailed' => 'Không thể dừng lại máy chủ đồng nghiệp',
			'settings.autoPip' => 'Ảnh Auto Picture in Picture',
			'settings.autoPipDescription' => 'Tự động nhập hình ảnh trong khi bạn rời khỏi ứng dụng trong khi chơi',
			'settings.matchContentFrameRate' => 'Match Content Frame Tỷ lệ',
			'settings.matchContentFrameRateDescription' => 'Match hiển thị tốc độ phục hồi cho nội dung video',
			'settings.matchContentResolution' => 'Match Content Quyết định',
			'settings.matchContentResolutionDescription' => 'Chuyển đổi màn hình sang độ phân giải bản địa của video để TV của bạn hoạt động upscaling. Menu và subtitles cũng được upscaled trong khi xem lại',
			'settings.matchRefreshRate' => 'Tỷ lệ Match Refresh Rate',
			'settings.matchRefreshRateDescription' => 'Match hiển thị tốc độ phục hồi trong màn hình đầy đủ',
			'settings.matchDynamicRange' => 'Đánh giá Dynamic Range',
			'settings.matchDynamicRangeDescription' => 'Chuyển đổi HDR cho nội dung HDR, sau đó trở lại SDR',
			'settings.displaySwitchDelay' => 'Tính năng: Display Switch Delay',
			'settings.tunneledPlayback' => 'Tải Tunnel Playback',
			'settings.tunneledPlaybackDescription' => 'Sử dụng đường hầm video. tắt nếu HDR playback hiển thị video màu đen hoặc động tác.',
			'settings.audioPassthrough' => 'Âm thanh trượt',
			'settings.audioPassthroughDescription' => 'Gửi âm thanh Dolby/DTS đến máy nhận hoặc TV của bạn mà không cần mã hóa lại, duy trì âm thanh xung quanh.',
			'settings.audioPassthroughDescriptionApple' => 'Sử dụng bộ giải mã Dolby gốc của Apple cho Dolby Digital Plus, bao gồm Atmos. DTS và TrueHD vẫn chơi như PCM đa kênh.',
			'settings.audioPassthroughDescriptionAppleSpatial' => 'Sử dụng bộ giải mã Dolby bản địa của Apple cho Dolby Digital Plus, bao gồm Atmos. Trên iOS, iPadOS và tvOS 26 hoặc sau đó, TrueHD Atmos và DTS:X chơi như âm thanh không gian.',
			'settings.audioPassthroughOverriddenByNormalization' => 'Tắt trong khi bình thường hóa âm thanh',
			'settings.audioChannelLimit' => 'Kênh âm thanh',
			'settings.audioChannelLimitDescription' => 'Thay đổi âm thanh giải mã xuống cho các loa, tai nghe, hoặc cài đặt HDMI mà không thể phát tất cả các kênh',
			'settings.audioChannelLimitOriginal' => 'nguyên bản',
			'settings.audioChannelLimitOriginalDescription' => 'Chơi mỗi kênh trong track',
			'settings.audioChannelLimitSurround51' => 'Đến 5.1',
			'settings.audioChannelLimitSurround51Description' => 'Trộn 7.1 xuống 5.1 cho các TV và máy nhận mà chỉ mất 5.1 PCM.',
			'settings.audioChannelLimitStereo' => 'Âm Thanh Nổi',
			'settings.audioChannelLimitStereoDescription' => 'Thay vào hai kênh cho các loa stereo hoặc tai nghe.',
			'settings.downmixCenterBoost' => 'Trung tâm kênh Boost',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Độ bền (dB)',
			'settings.downmixCenterBoostShort' => 'db',
			'settings.audioDownmixNormalize' => 'Tính năng của Downmix',
			'settings.audioDownmixNormalizeDescription' => 'Giảm hỗn hợp để ngăn chặn nhấp chuột. tắt để giữ khối lượng ban đầu (có thể làm hỏng các cảnh lớn).',
			'settings.dvConversionMode' => 'Dolby Vision Chuyển đổi',
			'settings.dvConversionModeDescription' => 'Chọn cách xử lý Dolby Vision Hồ sơ 7 tệp.',
			'settings.dvConversionAuto' => 'Tự động',
			'settings.dvConversionNative' => 'Người mẹ / khuyết tật',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Sử dụng khả năng phát hiện thiết bị và hành vi Fallback bình thường',
			'settings.dvConversionNativeDescription' => 'Native Force DV7 và suppress DV conversion retry',
			'settings.dvConversionDv81Description' => 'Chuyển đổi RPU mạnh vào hồ sơ Dolby Vision 8.1',
			'settings.dvConversionHevcStripDescription' => 'Dây Dolby Vision lớp RPU/EL và mặt bằng hiện tại HEVC',
			'settings.experimentalDolbyVision' => 'Dolby Vision thử nghiệm',
			'settings.experimentalDolbyVisionDescription' => 'Dùng bộ kết xuất FEL thử nghiệm trong lần phát tiếp theo. Cần bản dựng bộ máy riêng.',
			'settings.dvExperimentUnavailableDescription' => 'Thử nghiệm này hiện chỉ có trên Linux.',
			'settings.dvCompatibilityFallback' => 'Phương án tương thích dự phòng',
			'settings.dvCompatibilityFallbackDescription' => 'Dùng bộ kết xuất tiêu chuẩn nếu không thể bắt đầu thử nghiệm. Dữ liệu FEL có thể bị mất.',
			'settings.dvExperimentDiagnostics' => 'Nhật ký thử nghiệm video',
			'settings.dvExperimentDiagnosticsDescription' => 'Bật nhật ký trình phát chi tiết trong lần phát tiếp theo.',
			'settings.disableDolbyVision' => 'Không thể bỏ qua Dolby Vision',
			'settings.disableDolbyVisionDescription' => 'Chơi file HDR10 hoặc lớp HLG thay vì Dolby Vision, khi nó có một',
			'settings.hdrSdrConversion' => 'HDR sang SDR chuyển đổi',
			'settings.hdrSdrConversionDescription' => 'Chọn những gì chuyển đổi video HDR khi màn hình không thể hiển thị HDR.',
			_ => null,
		} ?? switch (path) {
			'settings.hdrSdrConversionAuto' => 'Tự động',
			'settings.hdrSdrConversionAutoDescription' => 'Thiết bị trên Android 9 và sau, người chơi trên các phiên bản cũ hơn',
			'settings.hdrSdrConversionDevice' => 'Thiết bị',
			'settings.hdrSdrConversionDeviceDescription' => 'Phần cứng video của thiết bị của bạn chuyển đổi nó. nhanh nhất, nhưng màu sắc phụ thuộc vào thiết bị',
			'settings.hdrSdrConversionPlayer' => 'Trình Phát',
			'settings.hdrSdrConversionPlayerDescription' => 'Màu sắc nhất quán, nhưng 4K có thể đâm vào các hộp TV thấp',
			'settings.deinterlace' => 'Interlacing Đánh giá',
			'settings.deinterlaceDescription' => 'Xóa các tác phẩm kết hợp từ video liên kết (mpv người chơi chỉ)',
			'settings.deinterlaceOff' => 'Tắt',
			'settings.deinterlaceOffDescription' => 'Hiển thị video liên kết khi nó được giải mã',
			'settings.deinterlaceVideo' => 'Video',
			'settings.deinterlaceVideoDescription' => 'Chuyển đổi mỗi trường thành một khung đầy đủ. cho video chụp cho TV, chẳng hạn như thể thao, tin tức, và các buổi hòa nhạc',
			'settings.deinterlaceFilm' => 'phim',
			'settings.deinterlaceFilmDescription' => 'Khôi phục các khung gốc của bộ phim và hoạt hình truyền hình đến 29.97 fps, phổ biến trên DVD NTSC. Video shot for TV stutters. Live TV uses Video',
			'settings.requireProfileSelectionOnOpen' => 'Yêu cầu hồ sơ trên app open',
			'settings.requireProfileSelectionOnOpenDescription' => 'Hiển thị lựa chọn hồ sơ mỗi khi ứng dụng được mở',
			'settings.forceTvMode' => 'Phim truyền hình Force',
			'settings.forceTvModeDescription' => 'Thiết lập TV Force. Đối với các thiết bị không tự phát hiện. Cần khởi động lại.',
			'settings.startInFullscreen' => 'Bắt đầu trên màn hình đầy đủ',
			'settings.startInFullscreenDescription' => 'Mở PlezyNG trong chế độ màn hình đầy đủ khi ra mắt',
			'settings.exitFullscreenOnPlayerClose' => 'Mở màn hình đầy đủ trên player close',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Tự động ra khỏi màn hình đầy đủ khi đóng video player',
			'settings.autoHidePerformanceOverlay' => 'Tính năng Auto-Hide Performance Overlay',
			'settings.autoHidePerformanceOverlayDescription' => 'Giảm hiệu suất với các điều khiển playback',
			'settings.showNavBarLabels' => 'Hiển thị Navigation Bar Labels',
			'settings.showNavBarLabelsDescription' => 'Hiển thị các nhãn văn bản dưới biểu tượng thanh điều hướng',
			'settings.startupSection' => 'Startup Phần',
			'settings.preferredServer' => 'Ưu tiên Server',
			'settings.preferredServerDescription' => 'ưu tiên kết quả của máy chủ này trong khi giữ cho mỗi máy chủ kết nối có sẵn.',
			'settings.preferredServerAutomatic' => 'tự động',
			'settings.showExploreTab' => 'Hiển thị Explore Tab',
			'settings.showExploreTabDescription' => 'Hiển thị tab Khám phá với nội dung từ Plex Khám phá và theo dõi kết nối',
			'settings.hideEmptyLibraries' => 'Ẩn thư viện trống',
			'settings.hideEmptyLibrariesDescription' => 'Xóa thư viện với số lượng mục được báo cáo trên máy chủ bằng 0 từ điều hướng.',
			'settings.liveTvDefaultFavorites' => 'Chất lượng kênh yêu thích',
			'settings.liveTvDefaultFavoritesDescription' => 'Chỉ hiển thị các kênh yêu thích khi mở Live TV',
			'settings.general' => 'Chung',
			'settings.generalDescription' => 'Ngôn ngữ, khởi động và hành vi cửa sổ',
			'settings.languageAndRegion' => 'Ngôn ngữ & Khu vực',
			'settings.startup' => 'Khởi động',
			'settings.display' => 'Hiển thị',
			'settings.libraryAndCards' => 'Thư viện & Bản đồ',
			'settings.homeScreen' => 'Home màn hình',
			'settings.navigation' => 'Điều Hướng',
			'settings.window' => 'cửa sổ',
			'settings.liveTv' => 'Truyền hình trực tiếp',
			'settings.player' => 'Trình Phát',
			'settings.videoAndDisplay' => 'Video & Hiển thị',
			'settings.audio' => 'Âm thanh',
			'settings.quality' => 'Chất lượng',
			'settings.subtitles' => 'Phụ đề',
			'settings.seekAndTiming' => 'Tìm & Thời gian',
			'settings.behavior' => 'hành vi',
			'settings.gestures' => 'gợi ý',
			'settings.gestureBrightnessSwipe' => 'Ánh sáng Swipe',
			'settings.gestureBrightnessSwipeDescription' => 'Chuyển lên hoặc xuống trên cạnh trái để điều chỉnh độ sáng',
			'settings.gestureVolumeSwipe' => 'Độ bền Swipe',
			'settings.gestureVolumeSwipeDescription' => 'Chuyển lên hoặc xuống trên cạnh phải để điều chỉnh khối lượng',
			'settings.gesturePinchToZoom' => 'Pinch đến Zoom',
			'settings.gesturePinchToZoomDescription' => 'Nhấn vào video để zoom vào hoặc ra',
			'settings.gestureSeekSwipe' => 'Tìm kiếm Swipe',
			'settings.gestureSeekSwipeDescription' => 'Chuyển sang trái hoặc thẳng bất cứ nơi nào trên video để tìm; phát hành để nhảy',
			'settings.rememberBrightnessLevel' => 'Nhớ mức độ sáng',
			'settings.rememberBrightnessLevelDescription' => 'Bắt đầu playback tại độ sáng được thiết lập bởi swipe cuối cùng',
			'settings.controls' => 'Điều khiển',
			'settings.rememberPlayerChanges' => 'Nhớ thay đổi người chơi',
			'settings.rememberPlayerChangesDescription' => 'Khi một thay đổi được thực hiện trong khi playback được tiết kiệm và áp dụng lại từ',
			'settings.scopePlaybackSpeed' => 'Tốc Độ Phát',
			'settings.scopeShaderPreset' => 'Shader Preset Đánh giá',
			'settings.scopeAspectRatio' => 'Tỷ Lệ Khung Hình',
			'settings.scopeSyncOffsets' => 'Audio & Subtitle đồng bộ',
			'settings.playerScopeOff' => 'Đừng tiết kiệm',
			'settings.playerScopeGlobal' => 'khắp nơi',
			'settings.playerScopeLibrary' => 'bởi thư viện',
			'settings.playerScopeTitle' => 'Theo chương trình hay phim',
			'settings.exportDialogTitle' => 'Xuất khẩu PlezyNG thiết lập',
			'settings.followSystem' => 'Theo hệ thống',
			'settings.followAppLanguage' => 'Theo ngôn ngữ giao diện',
			'settings.regionFormat' => 'Định dạng khu vực',
			'settings.regionFormatDescription' => 'Chọn cách hiển thị ngày, số và đơn vị đo.',
			'settings.metadataLanguage' => 'Ngôn ngữ siêu dữ liệu',
			'settings.metadataLanguageDescription' => 'Ngôn ngữ ưu tiên cho tiêu đề và mô tả khi máy chủ hỗ trợ. Tùy chọn âm thanh và phụ đề được thiết lập riêng.',
			'settings.enterFullscreenOnPlaybackStart' => 'Nhập màn hình đầy đủ khi playback bắt đầu',
			'settings.enterFullscreenOnPlaybackStartDescription' => 'Mở video desktop trên màn hình đầy đủ khi playback bắt đầu',
			'settings.extendVideoIntoDisplayCutout' => 'mở rộng video vào display cutout',
			'settings.extendVideoIntoDisplayCutoutDescription' => 'Hãy để video màn hình đầy đủ sử dụng camera cutout trên điện thoại Android',
			'settings.languageDescription' => 'Chọn ngôn ngữ được sử dụng cho các điều khiển và thông điệp PlezyNG. Theo hệ thống theo dõi ngôn ngữ thiết bị của bạn.',
			'settings.themeDescription' => 'Chọn các màu sắc và tương phản được sử dụng trong toàn bộ ứng dụng.',
			'settings.libraryDensityDescription' => 'Thay đổi số thẻ thư viện phù hợp trong mỗi hàng.',
			'settings.displayScaleDescription' => 'Khôi phục lại giao diện trên màn hình xe này mà không thay đổi kích thước văn bản trên thiết bị của bạn.',
			'settings.themeSongVolumeDescription' => 'Thiết lập khối lượng của bài hát chủ đề so với các âm thanh khác.',
			'settings.viewModeDescription' => 'Chọn xem các mục thư viện có xuất hiện như poster trong một mạng lưới hay là danh sách nhỏ gọn.',
			'settings.gridViewDescription' => 'sắp xếp các mục thư viện trong hàng và cột poster.',
			'settings.listViewDescription' => 'Hiển thị các mục thư viện trong một danh sách dọc với nhiều văn bản hơn cho mỗi mục.',
			'settings.gridSpacingDescription' => 'Đặt khoảng cách giữa các poster trong các mạng thư viện.',
			'settings.gridSpacingTightDescription' => 'Thích hợp nhiều poster trên màn hình với khoảng trống nhỏ hơn.',
			'settings.gridSpacingNormalDescription' => 'Sử dụng khoảng cách tiêu chuẩn giữa các poster.',
			'settings.gridSpacingSpaciousDescription' => 'Thêm khoảng cách lớn hơn giữa các poster cho sự tách rời nhiều hơn.',
			'settings.episodePosterModeDescription' => 'Chọn tác phẩm nghệ thuật nào xuất hiện trên các thẻ tập.',
			'settings.seriesPosterDescription' => 'Sử dụng poster series của chương trình cho mỗi tập.',
			'settings.seasonPosterDescription' => 'Sử dụng poster mùa cho mỗi tập khi có sẵn.',
			'settings.episodeThumbnailDescription' => 'Sử dụng một khung từ tập phim khi có sẵn.',
			'settings.continueWatchingActionDescription' => 'Chọn những gì xảy ra khi bạn kích hoạt một thẻ tiếp tục xem.',
			'settings.continueWatchingPlayDescription' => 'Bắt đầu bộ phim hoặc tập ngay lập tức.',
			'settings.continueWatchingDetailsDescription' => 'Mở trang tiêu đề đầu tiên để bạn có thể xem xét chi tiết và chọn một hành động.',
			'settings.episodeActionDescription' => 'Chọn những gì xảy ra khi bạn kích hoạt một thẻ episode.',
			'settings.episodePlayDescription' => 'Bắt đầu sự kiện ngay lập tức.',
			'settings.episodeDetailsDescription' => 'Mở trang tập trước khi playback.',
			'settings.contentScreensaverDelayDescription' => 'Chọn bao lâu PlezyNG chờ đợi mà không có đầu vào trước khi hiển thị tác phẩm nghệ thuật.',
			'settings.continueWatchingRowSizeDescription' => 'Chọn kích thước của các thẻ trong dòng tiếp tục xem.',
			'settings.rowSizeCompactDescription' => 'Hiển thị các thẻ nhỏ hơn để nhiều mục phù hợp trên hàng.',
			'settings.rowSizeStandardDescription' => 'Sử dụng kích thước thẻ tiêu chuẩn.',
			'settings.rowSizeLargeDescription' => 'Hiển thị các thẻ lớn hơn với chi tiết nghệ thuật nhiều hơn.',
			'settings.visualEffectsDescription' => 'Chọn ngân sách hoạt hình và hiệu ứng nghệ thuật cho thiết bị này.',
			'settings.visualEffectsFullDescription' => 'Sử dụng các hiệu ứng hoạt hình và nghệ thuật đầy đủ trên mỗi thiết bị.',
			'settings.startupSectionDescription' => 'Chọn phần nào mở khi PlezyNG bắt đầu.',
			'settings.startupSectionOptions.discover' => 'Mở các khuyến nghị và mục từ các nguồn phát hiện liên kết.',
			'settings.startupSectionOptions.libraries' => 'Mở thư viện truyền thông liên kết của bạn.',
			'settings.startupSectionOptions.liveTv' => 'Mở Live TV khi một máy chủ cung cấp nó; nếu không, khởi động sẽ trở về nhà.',
			'settings.startupSectionOptions.search' => 'Khởi mở Media Search.',
			'settings.smallSkipDurationDescription' => 'Thiết lập khoảng cách di chuyển bởi phía sau ngắn và phía trước tìm kiếm kiểm soát.',
			'settings.largeSkipDurationDescription' => 'Thiết lập khoảng cách di chuyển bởi phía sau dài và phía trước tìm kiếm kiểm soát.',
			'settings.rewindOnResumeDescription' => 'Chuyển đổi playback trở lại với số tiền này khi quay lại một video.',
			'settings.defaultSleepTimerDescription' => 'Thiết lập thời gian ban đầu được sử dụng khi bạn bắt đầu giờ ngủ.',
			'settings.playNextCountdownDescription' => 'Hãy đợi điều này lâu trước khi bắt đầu tập tiếp theo. thiết lập đến 0 để bắt đầu ngay lập tức.',
			'settings.autoSkipDelaySettingDescription' => 'Ứng dụng khi một intro, tín chỉ hoặc quảng cáo được thiết lập để tự động bỏ qua.',
			'settings.downmixCenterBoostDescription' => 'Tăng sự đối thoại trong kênh trung tâm khi âm thanh xung quanh được trộn xuống stereo.',
			'settings.displaySwitchDelayDescription' => 'Đợi trước khi thay đổi chế độ hiển thị để TV hoặc người nhận có thể hoàn thành chuyển đổi trước đó.',
			'settings.playerBackendDescription' => 'Chọn động cơ playback nào giải mã và render video trên thiết bị này.',
			'settings.exoPlayerDescription' => 'Sử dụng người chơi gốc của Android dựa trên Media3 và các con đường phần cứng được hỗ trợ.',
			'settings.mpvDescription' => 'Sử dụng mpv, mà tiết lộ thêm playback, subtitle và kiểm soát xử lý video.',
			'settings.scopeOffDescription' => 'Chỉ giữ các thay đổi cho phiên bản playback hiện tại.',
			'settings.scopeGlobalDescription' => 'Sử dụng lại cùng một giá trị cho mỗi thư viện và tiêu đề.',
			'settings.scopeLibraryDescription' => 'Hãy nhớ một giá trị riêng biệt cho mỗi thư viện.',
			'settings.scopeTitleDescription' => 'Hãy nhớ một giá trị riêng biệt cho mỗi chương trình hoặc bộ phim.',
			'settings.specialsOrderingServerDescription' => 'Giữ lệnh episode được cung cấp bởi máy chủ truyền thông.',
			'settings.specialsOrderingAirDateDescription' => 'Đặt đặc biệt trong số các tập thường xuyên theo ngày không của họ.',
			'settings.specialsOrderingLastDescription' => 'Đặt mỗi đặc biệt sau các mùa thường xuyên.',
			'settings.skipIntroModeDescription' => 'Chọn xem các markers intro chơi bình thường, hiển thị một nút skip hoặc skip tự động.',
			'settings.skipCreditsModeDescription' => 'Chọn xem tín dụng chơi bình thường, hiển thị một nút skip hoặc tự động skip.',
			'settings.skipAdsModeDescription' => 'Chọn xem quảng cáo được phát hiện có chơi bình thường hay không, hiển thị nút skip hoặc skip tự động.',
			'settings.playbackBufferAutoDescription' => 'Cho phép người chơi hoạt động chọn kích thước buffer bình thường của nó.',
			'settings.playbackBufferLargeDescription' => 'Giữ nhiều phương tiện truyền thông sẵn sàng trước khi chơi; điều này sử dụng thêm bộ nhớ.',
			'settings.playbackBufferExtraLargeDescription' => 'Giữ buffer lớn nhất để đọc; điều này sử dụng bộ nhớ nhiều nhất.',
			'settings.defaultQualityDescription' => 'Thiết lập độ phân giải video mặc định và bitrate mái cho các dòng mà máy chủ chuyển mã.',
			'settings.cellularQualityDescription' => 'Override Chất lượng mặc định khi thiết bị đang sử dụng một kết nối cell-only.',
			'settings.remoteQualityDescription' => 'Override Chất lượng mặc định khi kết nối với một máy chủ thông qua kết nối từ xa.',
			'settings.qualityPresetOriginalDescription' => 'Chơi nguồn với chất lượng có sẵn mà không yêu cầu máy chủ chuyển mã nó.',
			'settings.qualityPresetTranscodeOptionDescription' => 'Yêu cầu máy chủ cho một dòng chuyển đổi bằng cách sử dụng độ phân giải và bitrate được hiển thị ở trên.',
			'settings.qualityPresetSameAsDefaultDescription' => 'Sử dụng chất lượng được chọn trong Chất lượng mặc định.',
			'settings.musicQualityDescription' => 'Thiết lập tốc độ bit âm thanh tối đa được yêu cầu từ máy chủ; Original giữ dòng nguồn.',
			'settings.musicQualityOriginalDescription' => 'Chơi âm thanh nguồn mà không có transcode bitrate.',
			'settings.musicQualityTranscodeOptionDescription' => 'Yêu cầu một transcode máy chủ được cáp gần bitrate hiển thị ở trên; kết quả thực tế có thể thay đổi.',
			'settings.maxVolumeInputLabel' => 'Số lượng tối đa (%)',
			'settings.checkForUpdatesDescription' => 'Bây giờ kiểm tra xem phiên bản mới hơn của PlezyNG có sẵn hay không.',
			'settings.appearanceDescription' => 'Chọn chủ đề ứng dụng và điều chỉnh thư viện thẻ, dòng nhà, và di chuyển.',
			'settings.prerollLibraryDescription' => 'Chọn thư viện chứa các clip có sẵn như phim pre-rolls.',
			'settings.prerollSelectionDescription' => 'Chọn clip nào từ thư viện được chọn có thể chơi trước khi xem phim.',
			'settings.contentScreensaverDelayOptionDescription' => 'Đợi nhiều phút này mà không cần nhập trước khi hiển thị màn hình bảo vệ nghệ thuật.',
			'settings.videoCodecOptionDescription' => 'Cho phép phát trực tiếp cho codec này khi được hỗ trợ. codec không kiểm tra được chuyển mã bởi máy chủ truyền thông.',
			'themeEditor.builtIn' => 'xây dựng',
			'themeEditor.presets' => 'Lời bài hát',
			'themeEditor.custom' => 'Tùy chọn',
			'themeEditor.customEmpty' => 'chưa được tạo ra',
			'themeEditor.editCustom' => 'Edit chủ đề',
			'themeEditor.editCustomDescription' => 'Chọn mỗi màu cho riêng mình',
			'themeEditor.locked' => 'Thời gian tiếp cận cần thiết',
			'themeEditor.savedLocked' => 'Tiết kiệm - có sẵn với quyền truy cập suốt đời',
			'themeEditor.title' => 'Chủ đề Custom',
			'themeEditor.startFrom' => 'Bắt đầu từ',
			'themeEditor.startFromDescription' => 'Sao chép tất cả các màu sắc từ một chủ đề khác',
			'themeEditor.colors' => 'Màu sắc',
			'themeEditor.preview' => 'Xem thử',
			'themeEditor.slots.bg' => 'nền',
			'themeEditor.slots.surface' => 'bề mặt',
			'themeEditor.slots.outline' => 'outline',
			'themeEditor.slots.text' => 'Văn bản',
			'themeEditor.slots.textMuted' => 'Text thứ hai',
			'themeEditor.slots.accent' => 'accent',
			'themeEditor.opacity' => 'Độ mờ',
			'themeEditor.hexHint' => '#RRGGBB hoặc #AARRGGBB',
			'themeEditor.fromOtherThemes' => 'Từ các chủ đề khác',
			'themeEditor.swatchLabel' => ({required Object theme, required Object color}) => '${theme} ${color}',
			'themeEditor.contrast.textOnBg' => 'Bài viết trên nền',
			'themeEditor.contrast.textOnSurface' => 'Text trên bề mặt',
			'themeEditor.contrast.textMutedOnBg' => 'Bài viết thứ hai trên nền',
			'themeEditor.contrast.textMutedOnSurface' => 'Văn bản thứ hai trên bề mặt',
			'themeEditor.contrast.accentOnBg' => 'Tập trung vào nền',
			'themeEditor.contrast.accentOnSurface' => 'Tập trung vào bề mặt',
			'themeEditor.contrast.labelOnAccent' => 'Bút nhãn trên accent',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, dưới số đề xuất ${minimum}:1',
			'themeEditor.discardTitle' => 'Thay đổi không?',
			'themeEditor.discardMessage' => 'Các thay đổi màu chưa lưu sẽ bị mất.',
			'themeEditor.discard' => 'Khác',
			'themeEditor.previewCardTitle' => ({required Object number}) => 'Chương ${number}',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => '${minutes} phút left',
			'themeEditor.previewSwitch' => 'Tự động phát',
			'themeEditor.previewMutedText' => 'Bài viết thứ hai đọc như thế này',
			'themeEditor.themeSystemDescription' => 'Theo dõi sự xuất hiện của thiết bị và tự động chuyển đổi giữa ánh sáng và bóng tối.',
			'themeEditor.themeLightDescription' => 'Sử dụng nền sáng với văn bản tối.',
			'themeEditor.themeDarkDescription' => 'Sử dụng nền tối với văn bản sáng.',
			'themeEditor.themeOledDescription' => 'Sử dụng các bề mặt gần đen làm giảm ánh sáng trên màn hình OLED.',
			'themeEditor.themeEmberDescription' => 'Sử dụng màu đỏ ấm và accent amber.',
			'themeEditor.themeGlacierDescription' => 'Sử dụng màu sắc accent xanh mát mẻ.',
			'themeEditor.themeForestDescription' => 'Sử dụng màu xanh lá cây và sắc thái tự nhiên.',
			'themeEditor.themePlumDescription' => 'Sử dụng màu violet và plum accent.',
			'themeEditor.themePaperDescription' => 'Sử dụng các bề mặt như giấy ấm áp và màu sắc được truyền cảm hứng từ sơn.',
			'themeEditor.themeCustomDescription' => 'Sử dụng bảng màu mà bạn tạo trong biên tập chủ đề tùy chỉnh.',
			'themeEditor.editorDescription' => 'Chọn một màu palette, điều chỉnh độ ẩm, độ ăn kiêng, độ sáng hoặc độ không chính xác của nó và xem bản cập nhật trước khi tiết kiệm. bạn cũng có thể nhập màu hex.',
			'search.hint' => 'Tìm kiếm phim, chương trình, âm nhạc...',
			'search.tryDifferentTerm' => 'Thử một thuật ngữ tìm kiếm khác',
			'search.searchYourMedia' => 'Tìm kiếm phương tiện truyền thông của bạn',
			'search.enterTitleActorOrKeyword' => 'Nhập một tiêu đề, diễn viên hoặc từ khóa',
			'search.people' => 'Diễn Viên',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Thiết lập Shortcut cho ${actionName}',
			'hotkeys.clearShortcut' => 'ngắn gọn',
			'hotkeys.noShortcutSet' => 'Không shortcut set',
			'hotkeys.currentShortcut' => 'Hiện tại shortcut:',
			'hotkeys.pressToRecord' => 'Chọn để ghi một shortcut',
			'hotkeys.recordingShortcut' => 'Nhấn shortcut bây giờ',
			'hotkeys.actions.playPause' => 'Chơi / Pause',
			'hotkeys.actions.volumeUp' => 'Độ bền up',
			'hotkeys.actions.volumeDown' => 'Số lượng Down',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Tìm về phía trước (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Tìm kiếm trở lại (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'Cùng Fullscreen',
			'hotkeys.actions.muteToggle' => 'cùng nhau mút',
			'hotkeys.actions.subtitleToggle' => 'Thêm Subtitles',
			'hotkeys.actions.audioTrackNext' => 'Audio Track tiếp theo',
			'hotkeys.actions.subtitleTrackNext' => 'Subtitle Track tiếp theo',
			'hotkeys.actions.chapterNext' => 'Đoạn kế tiếp',
			'hotkeys.actions.chapterPrevious' => 'Đoạn trước',
			'hotkeys.actions.episodeNext' => 'Tập Kế Tiếp',
			'hotkeys.actions.episodePrevious' => 'Chương trước',
			'hotkeys.actions.speedIncrease' => 'Tăng tốc độ',
			'hotkeys.actions.speedDecrease' => 'Giảm tốc độ',
			'hotkeys.actions.speedReset' => 'Tốc độ Reset',
			'hotkeys.actions.zoomIn' => 'Zoom trong',
			'hotkeys.actions.zoomOut' => 'Zoom ra ngoài',
			'hotkeys.actions.zoomReset' => 'Tải Zoom',
			'hotkeys.actions.subSeekNext' => 'Tìm kiếm Subtitle tiếp theo',
			'hotkeys.actions.subSeekPrev' => 'Tìm kiếm trước Subtitle',
			'hotkeys.actions.subtitleDelayIncrease' => 'Lễ Subtitles',
			'hotkeys.actions.subtitleDelayDecrease' => 'Hiện phụ đề sớm hơn',
			'hotkeys.actions.shaderToggle' => 'Cùng nhau Shaders',
			'hotkeys.actions.skipMarker' => 'Lượt xem / tín dụng',
			'hotkeys.actions.screenshot' => 'chụp màn hình',
			'hotkeys.actions.framePrevious' => 'Frame trước',
			'hotkeys.actions.frameNext' => 'Frame tiếp theo',
			'fileInfo.title' => 'File thông tin',
			'fileInfo.overview' => 'Tổng quan',
			'fileInfo.video' => 'Video',
			'fileInfo.audio' => 'Âm thanh',
			'fileInfo.subtitles' => 'Phụ đề',
			'fileInfo.images' => 'Hình ảnh tích hợp',
			'fileInfo.dataStreams' => 'dữ liệu Streams',
			'fileInfo.lyrics' => 'Lời bài hát',
			'fileInfo.file' => 'Tệp',
			'fileInfo.attachments' => 'Phụ kiện',
			'fileInfo.delivery' => 'giao hàng',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => 'Phiên bản ${index} của ${count}',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => 'Tài liệu ${index} của ${count}',
			'fileInfo.noStreams' => 'Các máy chủ không tiết lộ không có dòng cho tệp này.',
			'fileInfo.copyPath' => 'Bản sao đường',
			'fileInfo.pathCopied' => 'file path sao chép',
			'fileInfo.codec' => 'Mã hóa',
			'fileInfo.codecTag' => 'Thẻ mã hóa',
			'fileInfo.resolution' => 'Độ phân giải',
			'fileInfo.codedResolution' => 'Quyết định mã hóa',
			'fileInfo.bitrate' => 'Tốc độ bit',
			'fileInfo.frameRate' => 'Tỷ lệ Frame',
			'fileInfo.rotation' => 'Xoay',
			'fileInfo.comment' => 'Comment Cách',
			'fileInfo.audioDescription' => 'Mô tả Audio',
			'fileInfo.headerCompression' => 'Header phức tạp',
			'fileInfo.sidecarFile' => 'Sidecar Tệp',
			'fileInfo.transportTimestamp' => 'Thời gian vận chuyển',
			'fileInfo.displayOffset' => 'Hiển thị Offset',
			'fileInfo.previewFailureCode' => 'Mã thất bại trước',
			'fileInfo.previewRetries' => 'Preview Phản hồi',
			'fileInfo.aspectRatio' => 'Tỷ Lệ Khung Hình',
			'fileInfo.pixelAspectRatio' => 'Tính năng Pixel Aspect',
			'fileInfo.profile' => 'Hồ sơ',
			'fileInfo.level' => 'Mức độ',
			'fileInfo.bitDepth' => 'Độ sâu bit',
			'fileInfo.pixelFormat' => 'Định dạng pixel',
			'fileInfo.colorSpace' => 'Bộ mã màu',
			'fileInfo.colorRange' => 'Màu sắc Range',
			'fileInfo.colorPrimaries' => 'Những màu chủ đạo',
			'fileInfo.colorTransfer' => 'Chuyển đổi màu',
			'fileInfo.chromaSubsampling' => 'Chronic Subsampling',
			'fileInfo.chromaLocation' => 'Địa điểm Chroma',
			'fileInfo.scanType' => 'Loại scan',
			'fileInfo.interlaced' => 'Xen kẽ',
			'fileInfo.anamorphic' => 'Biến dạng',
			'fileInfo.referenceFrames' => 'Quá trình tham khảo',
			'fileInfo.dynamicRange' => 'Dynamic Range Độ bền',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Dolby Vision Độ bền',
			'fileInfo.dolbyVisionVersion' => 'Dolby Vision Phiên bản',
			'fileInfo.dolbyVisionLayers' => 'Dolby Vision Dây',
			'fileInfo.baseLayerCompatibility' => 'Tùy hợp lớp cơ sở',
			'fileInfo.avcBitstream' => 'Đánh giá AVC Bitstream',
			'fileInfo.nalLengthSize' => 'Độ dài NAL',
			'fileInfo.scalingMatrix' => 'Tính năng: Custom Scaling Matrix',
			'fileInfo.streamIdentifier' => 'Tính năng Stream Identifier',
			'fileInfo.streamIndex' => 'Chỉ số Stream',
			'fileInfo.streamId' => 'Thông số Stream ID',
			'fileInfo.language' => 'Ngôn ngữ',
			'fileInfo.languageCode' => 'Mã ngôn ngữ',
			'fileInfo.streamTitle' => 'Track tiêu đề',
			'fileInfo.channels' => 'Kênh',
			'fileInfo.sampleRate' => 'Tỷ lệ mẫu',
			'fileInfo.spatialAudio' => 'âm thanh không gian',
			'fileInfo.textBased' => 'văn bản dựa',
			'fileInfo.subtitleFormat' => 'Hình thức Sidecar',
			'fileInfo.provider' => 'Nhà cung cấp',
			'fileInfo.matchScore' => 'Match Score Kết quả',
			'fileInfo.externalDelivery' => 'Có thể phục vụ riêng biệt',
			'fileInfo.sidecarPath' => 'Đường Sidecar',
			'fileInfo.sourceStream' => 'sao chép từ',
			'fileInfo.temporary' => 'Tạm thời',
			'fileInfo.timeBase' => 'Cơ sở thời gian',
			'fileInfo.overallBitrate' => 'Tổng số Bitrate',
			'fileInfo.path' => 'Đường dẫn',
			'fileInfo.fileName' => 'File tên',
			'fileInfo.size' => 'Kích cỡ',
			'fileInfo.totalSize' => 'Tổng kích thước',
			'fileInfo.container' => 'Định dạng',
			'fileInfo.duration' => 'Thời gian',
			'fileInfo.previewThumbnails' => 'Giới thiệu Thumbnails',
			'fileInfo.previewIndex' => 'Preview chỉ số',
			'fileInfo.packetLength' => 'Lượng gói',
			'fileInfo.filePresent' => 'file hiện tại',
			'fileInfo.fileReadable' => 'Có thể đọc bởi server',
			'fileInfo.streamPath' => 'Stream đường',
			'fileInfo.optimizedForStreaming' => 'Tốt nhất cho Streaming',
			'fileInfo.has64bitOffsets' => 'Độ lệch 64 bit',
			'fileInfo.protocol' => 'Giao thức',
			'fileInfo.mediaType' => 'loại phương tiện',
			'fileInfo.sourceKind' => 'Nguồn Kind',
			'fileInfo.optimizedVersion' => 'Phiên bản tối ưu',
			'fileInfo.optimizationTarget' => 'Mục tiêu tối ưu hóa',
			'fileInfo.deletedAt' => 'xóa',
			'fileInfo.remoteSource' => 'Nguồn từ xa',
			'fileInfo.infiniteStream' => 'Infinite dòng',
			'fileInfo.directPlay' => 'trực tiếp chơi',
			'fileInfo.directStream' => 'Stream trực tiếp',
			'fileInfo.transcoding' => 'Chuyển mã',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'Phiên bản ID',
			'fileInfo.fileId' => 'file ID',
			'fileInfo.defaultAudioTrack' => 'Lời bài hát: Audio Track',
			'fileInfo.defaultSubtitleTrack' => 'Subtitle Track theo tiêu chuẩn',
			'fileInfo.subtitlesOff' => 'Tắt',
			'fileInfo.flagDefault' => 'Mặc Định',
			'fileInfo.flagForced' => 'Bắt Buộc',
			'fileInfo.flagSelected' => 'Chọn',
			'fileInfo.flagExternal' => 'Bên ngoài',
			'fileInfo.flagHearingImpaired' => 'Nghe bị hư hỏng',
			'fileInfo.flagDub' => 'Dúp',
			'fileInfo.flagOriginal' => 'nguyên bản',
			'fileInfo.channelsMono' => 'Âm Thanh Đơn Kênh',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'Hồ sơ ${profile}',
			'mediaMenu.markAsWatched' => 'Mark như được xem',
			'mediaMenu.markAsUnwatched' => 'Mark như Unwatched',
			'mediaMenu.removeFromContinueWatching' => 'Xóa khỏi tiếp tục xem',
			'mediaMenu.viewDetails' => 'Xem chi tiết',
			'mediaMenu.goToSeries' => 'Đi đến series',
			'mediaMenu.shufflePlay' => 'Chơi Shuffle',
			'mediaMenu.shuffleNotAvailableOffline' => 'Shuffle không có sẵn offline',
			'mediaMenu.fileInfo' => 'File thông tin',
			'mediaMenu.deleteEpisodeFromServer' => 'xóa các tập từ server',
			'mediaMenu.deleteSeasonFromServer' => 'Xóa mùa từ máy chủ',
			'mediaMenu.deleteShowFromServer' => 'Xóa show từ server',
			'mediaMenu.deleteMovieFromServer' => 'Xóa phim từ máy chủ',
			'mediaMenu.deleteEpisodeTitle' => 'Tải về episode này?',
			'mediaMenu.deleteSeasonTitle' => 'Hủy bỏ mùa này?',
			'mediaMenu.deleteShowTitle' => 'Hủy bỏ chương trình này?',
			'mediaMenu.deleteMovieTitle' => 'Phải chăng bạn xóa phim này?',
			'mediaMenu.deleteEpisodeConfirm' => 'Xóa Tập',
			'mediaMenu.deleteSeasonConfirm' => 'Chụp mùa',
			'mediaMenu.deleteShowConfirm' => 'Hiển thị Delete',
			'mediaMenu.deleteMovieConfirm' => 'xóa phim',
			'mediaMenu.deleteAnyway' => 'xóa bất cứ',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => 'Xóa vĩnh viễn ${title} khỏi máy chủ của bạn?',
			'mediaMenu.deleteMultipleWarning' => 'Bao gồm tất cả các tập phim và tệp của chúng.',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n, other: 'Thao tác này xóa tất cả ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tập phim trong mục này cùng các tệp của chúng.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n, other: 'Mục này được lưu trong ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tệp và tất cả các tệp đó sẽ bị xóa.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n, other: 'Có ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tập phim khác được lưu trong cùng tệp và cũng sẽ bị xóa:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'PlezyNG không thể xác định những tệp sẽ bị xóa, nên có thể xóa nhiều hơn mục nêu trên. Hãy hủy và thử lại, hoặc vẫn xóa.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'Máy chủ không cung cấp thông tin tệp cho mục này, nên PlezyNG không thể xác định những tệp sẽ bị xóa. Có thể xóa nhiều hơn mục nêu trên.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Media item đã bị xóa thành công',
			'mediaMenu.mediaFailedToDelete' => 'Không xóa các mục phương tiện truyền thông',
			'mediaMenu.rate' => 'Đánh giá',
			'mediaMenu.playFromBeginning' => 'Phát từ đầu',
			'mediaMenu.playVersion' => 'Game phiên bản...',
			'rateSheet.title' => 'Đánh giá',
			'rateSheet.server' => 'Máy chủ',
			'rateSheet.favorite' => 'Yêu thích',
			'rateSheet.favorited' => 'Ưu tiên',
			'rateSheet.saved' => 'cứu',
			'rateSheet.notAvailable' => 'Không tìm thấy trận đấu',
			'rateSheet.noConnectedServices' => 'Kết nối một dịch vụ trong Settings để đánh giá ở đó.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, phim',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, chương trình truyền hình',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'Đã xem',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} phần trăm xem',
			'accessibility.mediaCardUnwatched' => 'chưa xem',
			'accessibility.tapToPlay' => 'Nhập để chơi',
			'accessibility.decrease' => 'Giảm',
			'accessibility.increase' => 'tăng',
			'accessibility.decreaseValue' => ({required Object label}) => 'Tỷ lệ giảm ${label}',
			'accessibility.increaseValue' => ({required Object label}) => 'Tăng ${label}',
			'accessibility.hue' => 'Sắc độ',
			'accessibility.saturation' => 'Độ bão hòa',
			'accessibility.brightness' => 'sáng',
			'accessibility.hexColor' => 'Màu Hex',
			'accessibility.expandText' => 'Tăng văn bản',
			'accessibility.collapseText' => 'Tác phẩm sụp đổ',
			'accessibility.alphabetNavigation' => 'Alphabet Navigation (liên kết  sửa đổi)',
			'accessibility.alphabetScrollHint' => 'Vuốt lên hoặc xuống để di chuyển theo chữ cái',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Dòng ${row} của ${rowCount}, cột ${column} của ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'Dòng ${row} của ${rowCount}',
			'accessibility.autoScrollPlay' => 'Chơi Auto-Scroll',
			'accessibility.autoScrollPause' => 'Lời bài hát: Auto-Scroll',
			'accessibility.hueShort' => 'H',
			'accessibility.saturationShort' => 'S',
			'accessibility.valueShort' => 'V',
			'accessibility.red' => 'Đỏ',
			'accessibility.green' => 'Xanh lá',
			'accessibility.blue' => 'Xanh lam',
			'accessibility.redShort' => 'R',
			'accessibility.greenShort' => 'G',
			'accessibility.blueShort' => 'B',
			'accessibility.colorModeHsv' => 'HSV',
			'accessibility.colorModeRgb' => 'RGB',
			'accessibility.title' => 'Truy cập',
			'accessibility.summary' => 'Text, contrast, motion và controls',
			'accessibility.systemHint' => 'Cài đặt khả năng truy cập của thiết bị của bạn luôn được áp dụng. các tùy chọn này thêm các điều chỉnh trong suốt PlezyNG.',
			'accessibility.readability' => 'Đọc và hiển thị',
			'accessibility.textSize' => '- Thêm Text Size',
			'accessibility.preview' => 'Tìm câu chuyện tiếp theo của bạn. đọc, nghe và xem theo tốc độ của riêng bạn.',
			'accessibility.boldText' => 'Lời bài hát Bold Interface',
			'accessibility.highContrast' => 'Contrast cao',
			'accessibility.highContrastHint' => 'Văn bản mạnh hơn, chi tiết và chỉ số tập trung trên các bề mặt sáng hoặc tối.',
			'accessibility.interaction' => 'động và tương tác',
			'accessibility.reduceMotion' => 'Giảm động lực',
			'accessibility.reduceMotionHint' => 'Dừng chuyển động của dấu chỉ tiêu điểm, hiệu ứng chuyển trang và các hiệu ứng trang trí.',
			'accessibility.largeTargets' => 'Mục tiêu Touch lớn hơn',
			'accessibility.largeTargetsHint' => 'Tăng diện tích các điều khiển dùng chung để dễ chạm và điều hướng bằng công nghệ hỗ trợ.',
			'accessibility.navigationHint' => 'Dùng Tab và Shift+Tab để di chuyển giữa các điều khiển, Enter hoặc Space để kích hoạt, Escape hoặc nút Quay lại để đóng. Bạn có thể chỉnh mức thu phóng và tùy chọn đọc khi mở sách.',
			'accessibility.textSizeDescription' => 'Tích hợp văn bản giao diện trong PlezyNG ngoài thiết lập kích thước văn bản hệ thống của thiết bị của bạn.',
			'accessibility.boldTextHint' => 'Sử dụng trọng lượng nặng hơn cho các nhãn giao diện và tin nhắn để làm cho chúng dễ dàng phân biệt.',
			'tooltips.shufflePlay' => 'Shuffle chơi',
			'tooltips.playTrailer' => 'Trò chơi Trailer',
			'tooltips.markAsWatched' => 'Mark theo dõi',
			'tooltips.markAsUnwatched' => 'Mark như không được xem',
			'audioTracks.track' => ({required Object n}) => 'Âm thanh Track ${n}',
			'videoControls.audioLabel' => 'Âm thanh',
			'videoControls.subtitlesLabel' => 'Phụ đề',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => 'Bảng Letterbox',
			'videoControls.fillScreen' => 'Full màn hình',
			'videoControls.stretch' => 'Kéo dài',
			'videoControls.lockRotation' => 'Lock xoay',
			'videoControls.unlockRotation' => 'Khóa xoay',
			'videoControls.timerActive' => 'Thời gian hoạt động',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Playback sẽ nghỉ tại ${duration}',
			'videoControls.sleepTimerEndOfVideo' => 'Kết thúc video hiện tại',
			'videoControls.sleepTimerStopAtHeader' => 'dừng lại',
			'videoControls.sleepTimerDurationHeader' => 'Thời gian',
			'videoControls.playbackWillPauseAtEnd' => 'Playback sẽ nghỉ ngơi vào cuối video này',
			'videoControls.stillWatching' => 'vẫn đang xem?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Đánh giá tại ${seconds}s',
			'videoControls.continueWatching' => 'tiếp tục',
			'videoControls.autoPlayNext' => 'Auto-Play tiếp theo',
			'videoControls.playNext' => 'Phát kế tiếp',
			'videoControls.playButton' => 'Phát',
			'videoControls.pauseButton' => 'Tạm dừng',
			'videoControls.playbackPaused' => 'nghỉ ngơi',
			'videoControls.playbackResumed' => 'chơi',
			'videoControls.loadingVideo' => 'tải video',
			'videoControls.showPlaybackControls' => 'Hiển thị Playback Control',
			'videoControls.hidePlaybackControls' => 'Ẩn Playback Controls',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Tìm lại ${seconds} giây',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Tìm trước ${seconds} giây',
			'videoControls.previousButton' => 'Episode trước',
			'videoControls.nextButton' => 'Tập Kế Tiếp',
			'videoControls.previousChapterButton' => 'Đoạn trước',
			'videoControls.nextChapterButton' => 'Đoạn kế tiếp',
			'videoControls.muteButton' => 'Tắt Tiếng',
			'videoControls.unmuteButton' => 'Bật Tiếng',
			'videoControls.settingsButton' => 'Cài đặt Playback',
			'videoControls.tracksButton' => 'Âm thanh & Subtitles',
			'videoControls.chaptersButton' => 'Chương 1',
			'videoControls.segmentLoopHelp' => 'Đặt A, sau đó đặt B sau đó trong dòng thời gian.',
			'videoControls.setLoopStart' => 'Cài đặt loop bắt đầu (A)',
			'videoControls.setLoopEnd' => 'Thiết lập vòng tròn kết thúc (B)',
			'videoControls.clearSegmentLoop' => 'Chi tiết Segment Loop',
			'videoControls.setLoopStartFirst' => 'Cài đặt vòng bắt đầu (A) trước khi kết thúc (B).',
			'videoControls.loopEndAfterStart' => 'Kết thúc vòng tròn phải là muộn hơn khởi đầu.',
			'videoControls.segmentLoopUnavailable' => 'Segment looping không có sẵn cho playback này.',
			'videoControls.loopPointNotSet' => 'Không đặt',
			'videoControls.bookmarksHelp' => 'Bookmarks được lưu trên thiết bị này. chọn một để đi đến thời điểm đó.',
			'videoControls.bookmarksButton' => 'Bookmarks Đánh giá',
			'videoControls.chaptersAndBookmarks' => 'Chương và Bookmark',
			'videoControls.segmentLoop' => 'phân đoạn loop',
			'videoControls.addBookmark' => 'Thêm Bookmark',
			'videoControls.bookmarkName' => 'Bookmark tên',
			_ => null,
		} ?? switch (path) {
			'videoControls.bookmarkNameHint' => 'Ví dụ: Mở cảnh',
			'videoControls.bookmarkDefaultName' => ({required Object n}) => 'Bookmark Đề ${n}',
			'videoControls.bookmarkNameRequired' => 'Nhập tên cho bookmark này.',
			'videoControls.deleteBookmark' => 'xóa bookmark',
			'videoControls.bookmarkLimitReached' => 'Bài viết này đã có 100 bookmarks.',
			'videoControls.bookmarkUnavailable' => 'Không thể lưu hoặc xóa sổ này.',
			'videoControls.bookmarkSaved' => 'Bookmark được tiết kiệm',
			'videoControls.bookmarkDeleted' => 'Bookmark bị xóa',
			'videoControls.loopPointSet' => ({required Object point, required Object time}) => 'Điểm Loop ${point} Set tại ${time}.',
			'videoControls.noChaptersOrBookmarks' => 'Không có chương hoặc bảng chữ cái có sẵn.',
			'videoControls.versionQualityButton' => 'Phiên bản & Chất lượng',
			'videoControls.versionColumnHeader' => 'Phiên bản',
			'videoControls.qualityColumnHeader' => 'Chất lượng',
			'videoControls.qualityOriginal' => 'nguyên bản',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Transcoding unavailable — chơi chất lượng ban đầu',
			'videoControls.subtitleUnavailableFallback' => 'Các tiêu đề được chọn không thể tải — tiếp tục mà không có tiêu đề',
			'videoControls.pipButton' => 'Hình ảnh trong hình ảnh mode',
			'videoControls.aspectRatioButton' => 'Tỷ Lệ Khung Hình',
			'videoControls.ambientLighting' => 'Ánh sáng môi trường',
			'videoControls.fullscreenButton' => 'Nhập Fullscreen',
			'videoControls.exitFullscreenButton' => 'Khởi hành Fullscreen',
			'videoControls.alwaysOnTopButton' => 'Luôn ở trên',
			'videoControls.rotationLockButton' => 'Lock xoay',
			'videoControls.lockScreen' => 'Màn hình Lock',
			'videoControls.screenLockButton' => 'màn hình lock',
			'videoControls.timelineSlider' => 'Thanh thời gian video',
			'videoControls.volumeSlider' => 'Tỷ lệ Volume',
			'videoControls.endsAt' => ({required Object time}) => 'Kết thúc tại ${time}',
			'videoControls.pipActive' => 'Chơi trong Picture-in-Picture',
			'videoControls.pipFailed' => 'Picture-in-picture không bắt đầu',
			'videoControls.screenshotSaved' => 'Screenshot được tiết kiệm',
			'videoControls.screenshotFailed' => 'Không thể chụp ảnh màn hình',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Thu phóng ${percent}%',
			'videoControls.volumePercent' => ({required Object percent}) => 'Âm lượng ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Yêu cầu Android 8.0 hoặc mới hơn',
			'videoControls.pipErrors.iosVersion' => 'Yêu cầu iOS 15.0 hoặc mới hơn',
			'videoControls.pipErrors.permissionDisabled' => 'Picture-in-picture bị vô hiệu hóa. bật nó trong cài đặt hệ thống.',
			'videoControls.pipErrors.notSupported' => 'Thiết bị không hỗ trợ chế độ hình ảnh trong hình ảnh',
			'videoControls.pipErrors.voSwitchFailed' => 'Không thể chuyển phát video sang hình ảnh-in-photo',
			'videoControls.pipErrors.failed' => 'Picture-in-picture không bắt đầu',
			'videoControls.pipErrors.prepareFailed' => 'Hình ảnh trong hình không thể được chuẩn bị',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Một lỗi xảy ra: ${error}',
			'videoControls.chapters' => 'Chương 1',
			'videoControls.noChaptersAvailable' => 'Không có chương có sẵn',
			'videoControls.queue' => 'Quay',
			'videoControls.noQueueItems' => 'Không có mặt hàng trong quue',
			'videoControls.noAudioDevicesAvailable' => 'Không có thiết bị âm thanh',
			'videoControls.searchSubtitles' => 'Tìm kiếm Subtitles',
			'videoControls.language' => 'Ngôn ngữ',
			'videoControls.noSubtitlesFound' => 'Không tìm thấy subtitles',
			'videoControls.subtitleDownloaded' => 'Subtitle tải xuống',
			'videoControls.subtitleDownloadedNotApplied' => 'Subtitle đã tải xuống, nhưng nó không thể được chọn',
			'videoControls.subtitleDownloadFailed' => 'Không tải Subtitle',
			'videoControls.searchLanguages' => 'Tìm kiếm ngôn ngữ...',
			'videoControls.skipIntro' => 'Tải Skip Intro',
			'videoControls.skipCredits' => 'Skip tín dụng',
			'videoControls.nextEpisode' => 'Tập Kế Tiếp',
			'videoControls.subtitleTrack' => ({required Object n}) => 'Đường sắt ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => 'Chủ đề: ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (được bắt buộc)',
			'videoControls.osdSubtitlesOff' => 'Chủ đề: Off',
			'videoControls.osdSubtitles' => ({required Object track}) => 'Đánh giá: ${track}',
			'videoControls.osdAudio' => ({required Object track}) => 'Âm thanh: ${track}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} khung', ), 
			'videoControls.trackSelectionTitle' => 'Lựa chọn đường trước khi playback',
			'videoControls.trackSelectionAuto' => 'Tự động Selection',
			'videoControls.openMiniPlayer' => 'Trò chơi Mini Open',
			'videoControls.returnToFullPlayer' => 'Trở lại cầu thủ đầy đủ',
			'videoControls.loadSubtitleFile' => 'tải file subtitle...',
			'videoControls.subtitleLoadFailed' => 'Không tải file subtitle',
			'videoControls.skipAds' => 'Tải Ads',
			'videoControls.tapToUnlock' => 'Chạm để mở khóa',
			'videoControls.tapAgainToUnlock' => 'Chạm lại để mở khóa',
			'messages.markedAsWatched' => 'Đánh dấu như được xem',
			'messages.markedAsUnwatched' => 'Đánh dấu không được xem',
			'messages.markedAsWatchedOffline' => 'Đánh dấu như đã được xem (sẽ đồng bộ khi trực tuyến)',
			'messages.markedAsUnwatchedOffline' => 'Đánh dấu như không được xem (sẽ đồng bộ khi trực tuyến)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Tự động xóa: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n, other: 'Tự động xóa ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} xem tải xuống', ), 
			'messages.removedFromContinueWatching' => 'Xóa khỏi tiếp tục xem',
			'messages.errorLoading' => ({required Object error}) => 'Lỗi: ${error}',
			'messages.searchPartialResults' => 'Một số máy chủ truyền thông không thể được tìm kiếm. hiển thị kết quả có sẵn.',
			'messages.streamInterrupted' => 'Stream đã bị gián đoạn. press play hoặc tìm cách rút lui.',
			'messages.liveStreamInterrupted' => 'Live stream đã bị ngừng. press play to retry.',
			'messages.fileInfoNotAvailable' => 'File thông tin không sẵn dùng',
			'messages.playbackAuthenticationRequired' => 'Đăng nhập vào máy chủ media một lần nữa để chơi mục này.',
			'messages.playbackServerUnavailable' => 'Máy chủ media không sẵn dùng, hãy thử lại sau này.',
			'messages.playbackDataInvalid' => 'Máy chủ trả lại thông tin playback không có hiệu lực.',
			'messages.playbackCancelled' => 'Playback đã bị hủy bỏ.',
			'messages.playbackFailed' => 'Playback không thể bắt đầu.',
			'messages.playbackFailedDetail' => ({required Object error}) => 'Playback không thể khởi động: ${error}',
			'messages.audioOutputFailed' => 'Kiểm tra kết nối âm thanh của TV hoặc người nhận; nếu các ứng dụng khác cũng không có âm thanh, hãy khởi động lại thiết bị.',
			'messages.mediaUnavailable' => 'Nội dung này không còn có sẵn nữa.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Lỗi tải file info: ${error}',
			'messages.errorLoadingSeries' => 'Lỗi Loading Series',
			'messages.musicNotSupported' => 'Music playback chưa được hỗ trợ',
			'messages.noDescriptionAvailable' => 'Không có mô tả',
			'messages.noProfilesAvailable' => 'Không có hồ sơ có sẵn',
			'messages.contactAdminForProfiles' => 'Liên hệ với người quản trị máy chủ của bạn để thêm hồ sơ',
			'messages.unableToDetermineLibrarySection' => 'Không thể xác định phần thư viện cho mục này',
			'messages.logsCleared' => 'Logs Đánh giá',
			'messages.logsCopied' => 'Lời bài hát: Copied to clipboard',
			'messages.noLogsAvailable' => 'Không có logs có sẵn',
			'messages.libraryScanning' => ({required Object title}) => 'Đánh giá “${title}...”',
			'messages.libraryScanStarted' => ({required Object title}) => 'Thư viện quét bắt đầu cho "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Không thể quét thư viện: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Tải về các thông tin mới cho "${title}"',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Metadata update bắt đầu cho "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Không cập nhật dữ liệu siêu dữ liệu: ${error}',
			'messages.logoutConfirm' => 'Bạn có chắc chắn bạn muốn đăng nhập không?',
			'messages.noSeasonsFound' => 'Không tìm thấy mùa',
			'messages.seasonsLoadFailed' => 'Không thể tải mùa',
			'messages.noEpisodesFound' => 'Không có sự kiện nào được tìm thấy trong mùa giải đầu tiên',
			'messages.noEpisodesFoundGeneral' => 'Không tìm thấy sự kiện',
			'messages.episodesLoadFailed' => 'Không thể tải các sự kiện',
			'messages.noResultsFound' => 'Không tìm thấy kết quả nào.',
			'messages.sleepTimerSet' => ({required Object label}) => 'Thời gian ngủ được thiết lập cho ${label}',
			'messages.noItemsAvailable' => 'Không có mặt hàng có sẵn',
			'messages.failedToCreatePlayQueueNoItems' => 'Không thể tạo ra một trò chơi cue — không có mục',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'thất bại đến ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Chuyển sang Player compatible...',
			'messages.serverLimitTitle' => 'Playback thất bại',
			'messages.serverLimitBody' => 'Lỗi máy chủ (HTTP 500). Một giới hạn băng thông / mã hóa có thể đã từ chối phiên này.',
			'messages.mediaUnreadableTitle' => 'file không sẵn dùng',
			'messages.mediaUnreadableBody' => 'Máy chủ đã tìm thấy mục này nhưng không thể đọc tệp của nó (HTTP 404). tệp có thể đã di chuyển, xóa, hoặc lưu trữ của nó là không dây.',
			'messages.serverBusyTitle' => 'Stream không sẵn dùng',
			'messages.serverBusyBody' => 'Máy chủ vẫn từ chối truyền tải tệp này (HTTP 503). nó có thể khởi động lại, bận rộn, hoặc lưu trữ tệp có thể offline. thử lại một lần nữa - nếu nó tiếp tục xảy ra, yêu cầu chủ máy chủ để kiểm tra máy chủ và lưu trữ tệp.',
			'messages.playbackNotAllowedTitle' => 'Playback không được phép',
			'messages.playbackNotAllowedBody' => 'Máy chủ từ chối truyền tải mục này (HTTP 403). Tài khoản của bạn có thể không được phép chơi nó, hoặc máy chủ có thể chỉ cho phép phát lại trên mạng địa phương của nó.',
			'messages.logsUploaded' => 'Logs upload',
			'messages.logsUploadFailed' => 'Không thể tải lên logs',
			'messages.logId' => 'Mã nhật ký',
			'messages.burnedSubtitlesUseMenu' => 'Các tiêu đề được đốt trong dòng này. thay đổi chúng từ menu tiêu đề.',
			'messages.noVideoUrl' => 'Không có URL video',
			'messages.playbackNoMediaSources' => 'Máy chủ không trả về các nguồn truyền thông chơi game',
			'messages.playbackDataNotPrepared' => 'Playback bắt đầu trước khi dữ liệu của nó đã sẵn sàng',
			'messages.streamSelectionUnavailable' => 'Stream selection không sẵn dùng cho nguồn này',
			'messages.streamSelectionFailed' => 'Không thể áp dụng các dòng được chọn',
			'messages.trackSelectionNotRemembered' => 'Lựa chọn track này chỉ áp dụng cho playback hiện tại.',
			'messages.serverUnavailableForProfile' => 'Không có máy chủ có sẵn cho hồ sơ hoạt động',
			'subtitlingStyling.previewSample' => 'The Fast Brown Fox nhảy qua con chó lười biếng',
			'subtitlingStyling.text' => 'Văn bản',
			'subtitlingStyling.border' => 'biên giới',
			'subtitlingStyling.background' => 'nền',
			'subtitlingStyling.fontSize' => 'font kích thước',
			'subtitlingStyling.textColor' => 'Màu văn bản',
			'subtitlingStyling.borderSize' => 'biên giới kích thước',
			'subtitlingStyling.borderColor' => 'Màu biên giới',
			'subtitlingStyling.backgroundOpacity' => 'Hình nền Opacity',
			'subtitlingStyling.backgroundColor' => 'Màu nền',
			'subtitlingStyling.position' => 'vị trí',
			'subtitlingStyling.assOverride' => 'ASS Đánh giá',
			'subtitlingStyling.overrideScale' => 'Tỷ lệ',
			'subtitlingStyling.overrideForce' => 'lực lượng',
			'subtitlingStyling.overrideStrip' => 'xóa styling',
			'subtitlingStyling.positionTop' => 'Top',
			'subtitlingStyling.positionBottom' => 'dưới',
			'subtitlingStyling.useMargins' => 'Sử dụng margins',
			'subtitlingStyling.useMarginsDescription' => 'Cho phép các tiêu đề văn bản trong không gian bên ngoài video. tiêu đề kiểu có thể giữ vị trí ban đầu của họ.',
			'subtitlingStyling.anchorToScreen' => 'Anchor to màn hình',
			'subtitlingStyling.anchorToScreenDescription' => 'Hiển thị các tiêu đề văn bản trong thanh đen dưới màn hình video',
			'subtitlingStyling.bold' => 'In đậm',
			'subtitlingStyling.italic' => 'Ý',
			'subtitlingStyling.renderResolution' => 'Quyết định Render',
			'subtitlingStyling.renderResolutionScreen' => 'Độ Phân Giải Màn Hình',
			'subtitlingStyling.renderResolutionVideo' => 'Độ phân giải video',
			'subtitlingStyling.fontSizeDescription' => 'Thiết lập kích thước văn bản subtitle trên thiết bị này.',
			'subtitlingStyling.textColorDescription' => 'Chọn màu được sử dụng cho subtitle text.',
			'subtitlingStyling.borderSizeDescription' => 'Đặt độ dày của outline xung quanh văn bản subtitle.',
			'subtitlingStyling.borderColorDescription' => 'Chọn màu được sử dụng cho dòng outline subtitle.',
			'subtitlingStyling.backgroundColorDescription' => 'Chọn màu đằng sau subtitle text.',
			'subtitlingStyling.backgroundOpacityDescription' => 'Thiết lập độ minh bạch của nền chủ đề là: 0% rõ ràng và 100% vững chắc.',
			'subtitlingStyling.positionDescription' => 'Di chuyển các tiêu đề theo chiều dọc. 0% là trên cùng của video và 100% là dưới cùng.',
			'subtitlingStyling.assOverrideDescription' => 'Chọn xem người chơi có theo dõi, điều chỉnh, thay thế hoặc loại bỏ kiểu dáng được tích hợp trong các tiêu đề ASS.',
			'subtitlingStyling.assOverrideOptions.no' => 'Giữ các phông chữ, màu sắc, kích cỡ và vị trí được viết trong tệp chủ đề.',
			'subtitlingStyling.assOverrideOptions.yes' => 'Cho phép cài đặt phong cách subtitle của người chơi để điều chỉnh các subtitles ASS.',
			'subtitlingStyling.assOverrideOptions.scale' => 'Ứng dụng phong cách người chơi và quy mô các kích cỡ tích hợp để phù hợp với kích thước video.',
			'subtitlingStyling.assOverrideOptions.force' => 'Thay thế các phong cách ASS tích hợp với phong cách subtitle của người chơi.',
			'subtitlingStyling.assOverrideOptions.strip' => 'Xóa định dạng ASS tích hợp và làm cho văn bản chủ đề rõ ràng.',
			'subtitlingStyling.renderResolutionDescription' => 'Chọn độ phân giải được sử dụng để rasterize hình ảnh và ASS subtitles. Lượng Android thấp hơn có thể làm giảm công việc rendering nhưng trông mềm hơn.',
			'subtitlingStyling.renderResolutionOptions.screen' => 'Render ở độ phân giải bề mặt màn hình đầy đủ cho kết quả sắc nét nhất.',
			'subtitlingStyling.renderResolutionOptions.video' => 'Render sử dụng độ phân giải video như là tham chiếu, có thể làm giảm công việc trên màn hình độ phân biệt cao.',
			'subtitlingStyling.renderResolutionOptions.threeQuarter' => 'Render tại 75% độ phân giải bề mặt hiển thị để tiết kiệm hiệu suất khiêm tốn.',
			'subtitlingStyling.renderResolutionOptions.half' => 'Tải xuống 50% độ phân giải bề mặt hiển thị để giảm công việc, với các cạnh mềm hơn.',
			'subtitlingStyling.renderResolutionOptions.third' => 'Render tại một phần ba độ phân giải bề mặt hiển thị để giảm công việc, với các cạnh mềm hơn.',
			'subtitlingStyling.renderResolutionOptions.quarter' => 'Render tại một phần tư độ phân giải bề mặt hiển thị để giảm công việc, với kết quả mềm nhất.',
			'subtitlingStyling.boldDescription' => 'Vẽ văn bản subtitle trong một trọng lượng nặng hơn.',
			'subtitlingStyling.italicDescription' => 'Tạo subtitle văn bản trong tiếng Ý.',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Cài đặt Video Player Advanced',
			'mpvConfig.presets' => 'Lời bài hát',
			'mpvConfig.noPresets' => 'Không có tiền thưởng',
			'mpvConfig.saveAsPreset' => 'Tiết kiệm như Preset',
			'mpvConfig.presetName' => 'Preset tên',
			'mpvConfig.presetNameHint' => 'Nhập một tên cho bài viết này',
			'mpvConfig.loadPreset' => 'tải',
			'mpvConfig.deletePreset' => 'Xóa',
			'mpvConfig.presetSaved' => 'Preset được cứu',
			'mpvConfig.presetLoaded' => 'Preset tải',
			'mpvConfig.presetDeleted' => 'Preset xóa',
			'mpvConfig.confirmDeletePreset' => 'Bạn có chắc chắn rằng bạn muốn xóa tiền này không?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan hwdec=auto # bình luận',
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => 'thêm dòng',
			'mpvConfig.removeLine' => 'xóa dòng',
			'mpvConfig.embeddedVoHint' => 'vo, gpu-context và gpu-api bị bỏ qua trên Linux: video tích hợp luôn được chuyển qua vo=libmpv trên máy tính video, và gpu-next (màu máy tính như ArtCNN cần) không thể chạy tích hợp.',
			'dialog.confirmAction' => 'xác nhận hành động',
			'profiles.addPlezyProfile' => 'Thêm PlezyNG hồ sơ',
			'profiles.switchingProfile' => 'Thay đổi profile...',
			'profiles.deleteThisProfileTitle' => 'Xóa hồ sơ này?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'Xóa ${displayName}. kết nối không bị ảnh hưởng.',
			'profiles.active' => 'hoạt động',
			'profiles.manage' => 'quản lý',
			'profiles.delete' => 'Xóa',
			'profiles.signOut' => 'Đăng xuất',
			'profiles.signOutPlexTitle' => 'Đăng ký từ Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'Xóa ${displayName} và tất cả Plex Người dùng nhà? đăng ký lại bất kỳ lúc nào.',
			'profiles.signOutPlexDeleteDownloads' => 'Tải xuống cũng',
			'profiles.signOutPlexDeleteDownloadsDescription' => 'Nếu không, họ sẽ ở lại trên thiết bị này và trở lại khi bạn đăng nhập lại vào tài khoản này.',
			'profiles.signedOutPlex' => 'Đã đăng ký từ Plex.',
			'profiles.signOutFailed' => 'Đăng ký thất bại',
			'profiles.sectionTitle' => 'Hồ sơ',
			'profiles.summarySingle' => 'Thêm hồ sơ để kết hợp người dùng được quản lý và danh tính địa phương',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} hồ sơ · hoạt động: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} hồ sơ',
			'profiles.removeConnectionTitle' => 'Xóa kết nối?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'Xóa truy cập ${displayName} đến ${connectionLabel}. các hồ sơ khác giữ nó.',
			'profiles.deleteProfileTitle' => 'xóa hồ sơ?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'Xóa ${displayName} và các kết nối của nó. máy chủ vẫn có sẵn.',
			'profiles.profileNameLabel' => 'Profile tên',
			'profiles.pinProtectionLabel' => 'PIN bảo vệ',
			'profiles.copyAutomationLink' => 'Bản sao Android tự động hóa liên kết',
			'profiles.copyAutomationLinkDescription' => 'Chọn hồ sơ này từ mục đích hoặc tự động hóa Android.Các kiểm tra PIN hồ sơ vẫn áp dụng.',
			'profiles.automationLinkCopied' => 'Profile tự động hóa link sao chép.',
			'profiles.pinManagedByPlex' => 'PIN được quản lý bởi Plex. Edit on plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'Không thiết lập PIN. Để yêu cầu một, chỉnh sửa người dùng nhà trên plex.tv.',
			'profiles.setPin' => 'Thiết lập PIN',
			'profiles.setPinTitle' => 'Thiết lập PIN',
			'profiles.confirmPinTitle' => 'xác nhận PIN',
			'profiles.pinSet' => 'PIN thiết lập',
			'profiles.changePin' => 'Thay đổi',
			'profiles.removePin' => 'Gỡ bỏ',
			'profiles.connectionsLabel' => 'Liên kết',
			'profiles.add' => 'Thêm',
			'profiles.deleteProfileButton' => 'xóa profile',
			'profiles.noConnectionsHint' => 'Không có kết nối — thêm một để sử dụng hồ sơ này.',
			'profiles.noConnections' => 'Không liên kết',
			'profiles.plexHomeAccount' => 'Plex Tài khoản nhà',
			'profiles.plexAccountChip' => ({required Object account}) => 'Plex Tài khoản: ${account}',
			'profiles.plexAccountUserChip' => ({required Object user, required Object account}) => '${user} qua ${account}',
			'profiles.connectionDefault' => 'Mặc Định',
			'profiles.connectionAs' => ({required Object displayName}) => 'Số lượng: ${displayName}',
			'profiles.makeDefault' => 'làm default',
			'profiles.removeConnection' => 'Gỡ bỏ',
			'profiles.profileRenamed' => 'Hồ sơ đổi tên',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Thêm vào ${displayName}',
			'profiles.borrowExplain' => 'Mượn kết nối của hồ sơ khác. hồ sơ được bảo vệ bằng PIN đòi hỏi một PIN.',
			'profiles.borrowEmpty' => 'Chưa có gì để vay mượn.',
			'profiles.borrowEmptySubtitle' => 'Kết nối Plex, Jellyfin, hoặc Emby với hồ sơ khác đầu tiên.',
			'profiles.borrowLoadFailed' => 'Các kết nối có sẵn không thể được tải lên. thử lại.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'Từ ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'Kết nối vay mượn',
			'profiles.borrowFailed' => 'Không có kết nối vay.',
			'profiles.incorrectPin' => 'PIN không chính xác',
			'profiles.incorrectPinTryAgain' => 'PIN không chính xác, xin vui lòng thử lại.',
			'profiles.sourceProfileMissingParentAccount' => 'Tài khoản nguồn đang thiếu tài khoản của cha mẹ.',
			'profiles.failedToLoadHomeUsers' => 'Không thể tải lên người dùng nhà Plex của bạn. kiểm tra kết nối của bạn và thử lại.',
			'profiles.failedToVerifyPin' => 'Không thể xác minh PIN',
			'profiles.newProfile' => 'Hồ sơ mới',
			'profiles.profileNameHint' => 'Ví dụ: khách, trẻ em, phòng gia đình',
			'profiles.pinProtectionOptional' => 'Bảo vệ PIN (tùy chọn)',
			'profiles.pinExplain' => '4 số PIN cần thiết để chuyển đổi hồ sơ.',
			'profiles.continueButton' => 'tiếp tục',
			'profiles.pinsDontMatch' => 'PIN không phù hợp',
			'profiles.tokenIdentityMismatch' => 'Tóc hồ sơ Plex được giải quyết đến một máy chủ bất ngờ',
			'profiles.settingsLocked' => 'Cài đặt được khóa cho hồ sơ này.',
			'profiles.unlockSettings' => 'Khóa cài đặt',
			'profiles.showExploreForProfile' => 'Show Explore cho profile này',
			'profiles.showExploreForProfileDescription' => 'Tắt để loại bỏ Explore khỏi trình duyệt hồ sơ này.',
			'connections.sectionTitle' => 'Liên kết',
			'connections.addConnection' => 'thêm liên kết',
			'connections.addConnectionSubtitleNoProfile' => 'Đăng nhập với Plex hoặc kết nối với một máy chủ Jellyfin hoặc Emby',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Thêm vào ${displayName}: Plex, Jellyfin, Emby, hoặc kết nối hồ sơ khác',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Kết thúc phiên tại ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Thời gian lưu trữ cho ${count} máy chủ',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} từ chối truy cập vào tài khoản này',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} máy chủ từ chối truy cập vào tài khoản này',
			'connections.signInAgain' => 'Đăng ký lại',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'Edit ${product} kết nối',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'Thêm hoặc xóa URL cho ${serverName}. PlezyNG sẽ sử dụng URL có thể truy cập với độ chậm thấp nhất.',
			'accountPreferences.sectionTitle' => 'Kế toán ưu tiên',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => 'Audio, subtitle và thư viện tùy chọn được lưu trên ${account}',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => 'Audio, subtitle và thư viện tùy chọn được lưu trên ${count} tài khoản',
			'accountPreferences.pickAccount' => 'Mỗi tài khoản lưu trữ sở thích của riêng mình. chọn một để chỉnh sửa.',
			'accountPreferences.storedOnAccount' => 'Các tùy chọn này được lưu trữ trên tài khoản của bạn, vì vậy mỗi ứng dụng đăng ký sử dụng chúng – bao gồm PlezyNG trên các thiết bị khác của bạn.',
			'accountPreferences.noAccounts' => 'Không có tài khoản để cấu hình',
			'accountPreferences.noAccountsHint' => 'Đăng nhập vào Plex, hoặc kết nối với một máy chủ Jellyfin hoặc Emby, và các tùy chọn được lưu trữ trên tài khoản đó được hiển thị ở đây.',
			'accountPreferences.unavailable' => 'Không thể truy cập tài khoản này',
			'accountPreferences.loadFailed' => 'Không thể tải các tùy chọn này',
			'accountPreferences.noPreference' => 'Không ưu tiên',
			'accountPreferences.notSet' => 'Không đặt',
			'accountPreferences.groups.audioAndSubtitles' => 'Âm thanh & Subtitles',
			'accountPreferences.groups.libraryDisplay' => 'Thư viện',
			'accountPreferences.groups.personalMedia' => 'Thông tin cá nhân',
			'accountPreferences.preferredAudioLanguage' => 'Ngôn ngữ thoại ưa thích',
			'accountPreferences.autoSelectAudio' => 'Chọn âm thanh theo ngôn ngữ',
			'accountPreferences.autoSelectAudioDescription' => 'Tắt giữ bất kỳ âm thanh theo dõi các tệp được đánh dấu theo mặc định.',
			'accountPreferences.preferredSubtitleLanguage' => 'Ngôn ngữ phụ đề ưu tiên',
			'accountPreferences.subtitleMode' => 'Chuyển Subtitles vào',
			'accountPreferences.subtitleModes.none' => 'Chọn thủ công',
			'accountPreferences.subtitleModes.noneDescription' => 'Đừng bao giờ tự nhặt các tiêu đề.',
			'accountPreferences.subtitleModes.defaultMode' => 'Theo dõi theo các lá cờ',
			'accountPreferences.subtitleModes.defaultModeDescription' => 'Sử dụng các lá cờ mặc định và bắt buộc được lưu trữ trên mỗi dòng subtitle.',
			'accountPreferences.subtitleModes.always' => 'Luôn có khả năng',
			'accountPreferences.subtitleModes.alwaysDescription' => 'Chuyển vào một dòng subtitle trong ngôn ngữ yêu thích bất cứ khi nào có.',
			'accountPreferences.subtitleModes.onlyForced' => 'Chỉ có các subtitles',
			'accountPreferences.subtitleModes.onlyForcedDescription' => 'Chỉ tải các con đường được đánh dấu là bắt buộc.',
			'accountPreferences.subtitleModes.smart' => 'Hiển thị bằng âm thanh nước ngoài',
			'accountPreferences.subtitleModes.smartDescription' => 'Thay đổi các tiêu đề chỉ khi âm thanh ở ngôn ngữ khác.',
			'accountPreferences.subtitleAccessibility' => 'SDH Subtitles',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'Ưu tiên không SDH subtitles',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'Ưu đãi SDH Subtitles',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'Chỉ có SDH Subtitles',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'Chỉ có các tiêu đề không SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdhDescription' => 'Thích các tiêu chuẩn khi cả phiên bản tiêu chuẩn và SDH đều có sẵn.',
			'accountPreferences.subtitleAccessibilityOptions.preferSdhDescription' => 'Thích các tiêu đề SDH khi có sẵn, nhưng cho phép tiêu chuẩn tiêu đề như là một sự sụp đổ.',
			'accountPreferences.subtitleAccessibilityOptions.onlySdhDescription' => 'Chỉ sử dụng các tiêu đề SDH; không rơi trở lại các tiêu chuẩn.',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdhDescription' => 'Chỉ sử dụng các tiêu chuẩn; loại trừ các tiêu đề SDH.',
			'accountPreferences.forcedSubtitles' => 'Subtitles buộc',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'Ưu tiên không bắt buộc subtitles',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'Ưu tiên Subtitles',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'Chỉ có các subtitles',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'Chỉ có các subtitles không bắt buộc',
			'accountPreferences.forcedSubtitleOptions.preferNonForcedDescription' => 'Thích các tiêu đề thường xuyên, nhưng cho phép những con đường bắt buộc như một sự sụp đổ.',
			'accountPreferences.forcedSubtitleOptions.preferForcedDescription' => 'Tốt nhất là bắt buộc theo dõi khi có sẵn, nhưng cho phép các tiêu đề thường xuyên như một sự sụp đổ.',
			'accountPreferences.forcedSubtitleOptions.onlyForcedDescription' => 'Chỉ sử dụng các con đường được đánh dấu là bắt buộc.',
			'accountPreferences.forcedSubtitleOptions.onlyNonForcedDescription' => 'Trừ các dấu vết được đánh dấu là bắt buộc.',
			'accountPreferences.displayMissingEpisodes' => 'Xem các chương trình thiếu',
			'accountPreferences.displayMissingEpisodesDescription' => 'Danh sách các tập tin mà máy chủ biết về nhưng không có tệp cho.',
			'accountPreferences.hidePlayedInLatest' => 'Ẩn các mục được xem trong Latest',
			'accountPreferences.hidePlayedInLatestDescription' => 'Hãy để lại các mục bạn đã xem ra khỏi dòng cuối cùng của máy chủ.',
			'accountPreferences.displayCollectionsView' => 'Hiển thị bộ sưu tập View',
			'accountPreferences.displayCollectionsViewDescription' => 'Cung cấp xem bộ sưu tập trên máy chủ bên cạnh thư viện của bạn.',
			'accountPreferences.rewatchingInNextUp' => 'Tiếp tục xem lại các chương trình trong Next Up',
			'accountPreferences.rewatchingInNextUpDescription' => 'Một khi bạn hoàn thành một chương trình, hãy bắt đầu lại và Next Up theo dõi lại thay vì bỏ chương trình.',
			'accountPreferences.watchedIndicator' => 'Các chỉ số được xem',
			'accountPreferences.watchedIndicatorOptions.none' => 'Không Bao Giờ',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => 'phim và chương trình truyền hình',
			'accountPreferences.watchedIndicatorOptions.movies' => 'phim chỉ',
			'accountPreferences.watchedIndicatorOptions.shows' => 'TV Show Chỉ',
			'accountPreferences.watchedIndicatorOptions.noneDescription' => 'Đừng hiển thị các dấu hiệu kiểm tra được xem.',
			'accountPreferences.watchedIndicatorOptions.moviesAndShowsDescription' => 'Hiển thị kiểm tra được xem cho các bộ phim và chương trình truyền hình.',
			'accountPreferences.watchedIndicatorOptions.moviesDescription' => 'Hiển thị các dấu hiệu kiểm tra chỉ cho phim.',
			'accountPreferences.watchedIndicatorOptions.showsDescription' => 'Chỉ hiển thị dấu đánh dấu đã xem cho các chương trình truyền hình.',
			'accountPreferences.mediaReviewsVisibility' => 'Đánh giá & đánh giá',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'Người dùng và các nhà phê bình',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'Người dùng chỉ',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'Chỉ có những người chỉ trích',
			'accountPreferences.mediaReviewsOptions.nobody' => 'Ẩn',
			'accountPreferences.mediaReviewsOptions.usersAndCriticsDescription' => 'Hiển thị cả đánh giá người dùng và đánh giá quan trọng.',
			'accountPreferences.mediaReviewsOptions.usersOnlyDescription' => 'Hiển thị đánh giá và đánh giá được gửi bởi người dùng.',
			'accountPreferences.mediaReviewsOptions.criticsOnlyDescription' => 'Hiển thị đánh giá và đánh giá quan trọng.',
			'accountPreferences.mediaReviewsOptions.nobodyDescription' => 'Ẩn đánh giá và đánh giá.',
			'accountPreferences.preferredAudioLanguageDescription' => 'Thích theo dõi âm thanh trong ngôn ngữ này khi máy chủ hoặc người chơi tự động chọn một track.',
			'accountPreferences.preferredSubtitleLanguageDescription' => 'Thích theo dõi subtitle trong ngôn ngữ này khi subtitles được chọn tự động.',
			'accountPreferences.subtitleAccessibilityDescription' => 'Chọn xem mục SDH có được yêu cầu hay không trong quá trình tự động chọn subtitle.',
			'accountPreferences.forcedSubtitleDescription' => 'Chọn xem các đường dẫn subtitle bắt buộc có được ưu tiên hay yêu cầu trong quá trình tự động chọn.',
			'accountPreferences.watchedIndicatorDescription' => 'Chọn loại phương tiện nào nhận được dấu kiểm theo dõi trong giao diện máy chủ.',
			'accountPreferences.mediaReviewsVisibilityDescription' => 'Chọn loại khán giả và đánh giá quan trọng mà máy chủ hiển thị trên các trang truyền thông.',
			'accountPreferences.subtitleModeDescription' => 'Chọn khi subtitles tự động bật cho tài khoản máy chủ này.',
			'accountPreferences.hubDescription' => 'Những tùy chọn này được lưu trữ trên tài khoản máy chủ phương tiện của bạn và có thể áp dụng cho các khách hàng khác.',
			'discover.title' => 'Khám phá',
			'discover.noContentAvailable' => 'Không có nội dung có sẵn',
			'discover.addMediaToLibraries' => 'Thêm một số phương tiện truyền thông vào thư viện của bạn',
			'discover.continueWatching' => 'Tiếp tục xem',
			'discover.continueWatchingIn' => ({required Object library}) => 'Tiếp tục xem tại ${library}',
			'discover.nextUp' => 'Tiếp Theo',
			'discover.nextUpIn' => ({required Object library}) => 'Tiếp theo lên trong ${library}',
			'discover.recentlyAdded' => 'Thêm Gần Đây',
			'discover.recentlyAddedIn' => ({required Object library}) => 'Gần đây Thêm vào ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => 'Album mới nhất trong ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'Chơi gần đây tại ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'Hầu hết được chơi trong ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'Mùa ${season} Tập ${episode}',
			'discover.overview' => 'Tổng quan',
			'discover.cast' => 'Diễn viên',
			'discover.findNext.title' => 'Tìm lựa chọn tiếp theo',
			'discover.findNext.open' => 'Tìm lựa chọn tiếp theo',
			'discover.findNext.anyTime' => 'Không giới hạn thời gian',
			'discover.findNext.timeAvailable' => 'Bạn có bao nhiêu thời gian?',
			'discover.findNext.filters' => 'Chọn điều phù hợp lúc này',
			'discover.findNext.watch' => 'Xem',
			'discover.findNext.listen' => 'Nghe',
			'discover.findNext.read' => 'Đọc',
			'discover.findNext.finishable' => ({required Object duration}) => 'Có thể hoàn thành trong ${duration}',
			'discover.findNext.aboutDuration' => ({required Object duration}) => 'Khoảng ${duration}',
			'discover.findNext.nextUnit' => ({required Object duration}) => 'Chương tiếp theo · ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => 'Tổng cộng ${duration}',
			'discover.findNext.timingVaries' => 'Thời lượng có thể thay đổi',
			'discover.findNext.notNow' => 'Để sau',
			'discover.findNext.swipeHint' => 'Vuốt ảnh bìa theo hướng mũi tên hoặc dùng các nút bên dưới.',
			'discover.findNext.saved' => 'Gợi ý đã lưu',
			'discover.findNext.savedCount' => ({required Object count}) => 'Gợi ý đã lưu · ${count}',
			'discover.findNext.undo' => 'Hoàn tác',
			'discover.findNext.details' => 'Chi tiết',
			'discover.findNext.noPicks' => 'Chưa có nội dung để chọn',
			'discover.findNext.noPicksHint' => 'Kết nối thư viện hoặc thêm nguồn nội dung để bắt đầu.',
			'discover.findNext.noMatches' => 'Chưa có nội dung phù hợp lúc này',
			'discover.findNext.noMatchesHint' => 'Thử loại nội dung khác hoặc dành thêm thời gian.',
			'discover.findNext.allDone' => 'Bạn đã xem hết các gợi ý',
			'discover.findNext.allDoneHint' => 'Tạo nhóm gợi ý mới để xem lại những lựa chọn này.',
			'discover.findNext.refresh' => 'Tìm nhóm gợi ý khác',
			'discover.findNext.sourceReason' => ({required Object source}) => 'Từ ${source}',
			'discover.findNext.libraryReason' => ({required Object library}) => 'Từ ${library}',
			'discover.findNext.ownedReason' => 'Từ thư viện của bạn',
			'discover.findNext.liveNow' => 'Đang phát sóng',
			'discover.findNext.watchLive' => 'Xem trực tiếp',
			'discover.findNext.filterAnything' => 'Tất cả các loại',
			'discover.findNext.filterWatch' => 'Xem',
			'discover.findNext.filterListen' => 'Nghe',
			'discover.findNext.filterRead' => 'Đọc',
			'discover.findNext.twentyMinutes' => '20 phút',
			'discover.findNext.fortyFiveMinutes' => '45 phút',
			'discover.findNext.ninetyMinutes' => '90 phút',
			'discover.findNext.apply' => 'Áp dụng',
			'discover.findNext.openFailed' => 'Lựa chọn này không còn khả dụng. Làm mới để kiểm tra lại.',
			'discover.findNext.changeFailed' => 'Không thể lưu thay đổi. Vui lòng thử lại.',
			'discover.findNext.savedLimit' => 'Danh sách gợi ý đã lưu đã đầy. Xóa một gợi ý để lưu gợi ý khác.',
			'discover.findNext.chooseHint' => 'Mở một tựa, lưu để xem sau hoặc bỏ qua.',
			'discover.findNext.howItWorks' => 'Cách sử dụng',
			'discover.findNext.notNowHelp' => 'Tạm bỏ qua tựa này. Tựa vẫn ở trong thư viện của bạn.',
			'discover.findNext.saveHelp' => 'Lưu vào các lựa chọn đã lưu của hồ sơ này trên thiết bị này. Việc lưu không tải nội dung xuống.',
			'discover.findNext.openHelp' => 'Chọn ảnh bìa để xem chi tiết. Dùng nút chính để phát, đọc hoặc mở tựa.',
			'discover.findNext.controlsHelp' => 'Bàn phím hoặc điều khiển: chọn một nút rồi nhấn Enter hoặc nút Chọn. Hoàn tác khôi phục lựa chọn vừa rồi.',
			'discover.findNext.artworkLoading' => 'Đang tải ảnh…',
			'discover.findNext.artworkUnavailable' => 'Không có ảnh',
			'discover.findNext.savedFeedback' => 'Đã thêm vào các lựa chọn đã lưu',
			'discover.findNext.skippedFeedback' => 'Đã tạm bỏ qua',
			'discover.findNext.releaseToConfirm' => 'Thả để xác nhận',
			'discover.findNext.remoteHint' => 'Khi chọn ảnh bìa: ← / → chọn · Nút Chọn: chi tiết · ↑ / ↓ chuyển tiêu điểm',
			'discover.extras' => 'Trailers và Extras',
			'discover.studio' => 'Hãng phim',
			'discover.rating' => 'Đánh giá',
			'discover.director' => 'Đạo Diễn',
			'discover.directors' => 'Đạo Diễn',
			'discover.movie' => 'Phim',
			'discover.tvShow' => 'chương trình TV',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} phút left',
			'discover.moreLikeThis' => 'Nội Dung Tương Tự',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} danh sách', ), 
			'discover.person.born' => 'Sinh ra',
			'discover.person.died' => 'chết',
			'discover.person.birthplace' => 'Địa điểm sinh',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date} ( tuổi ${age})',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date} (trẻ ${age})',
			'errors.searchFailed' => ({required Object error}) => 'Tìm kiếm thất bại: ${error}',
			'errors.searchUnavailable' => 'Tìm kiếm không thể truy cập bất kỳ máy chủ phương tiện nào.',
			'errors.connectionTimeout' => ({required Object context}) => 'Thời gian kết nối trong khi tải ${context}',
			'errors.connectionFailed' => 'Không thể kết nối với Media Server',
			'errors.unableToLoad' => ({required Object context}) => 'Không thể tải ${context}. xin vui lòng thử lại.',
			'errors.noClientAvailable' => 'Không có khách hàng',
			'errors.pleaseEnterToken' => 'Vui lòng nhập token',
			'errors.invalidToken' => 'Mã xác thực không hợp lệ',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Không xác minh token: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Không thể chuyển sang ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'Không xóa ${displayName}',
			'errors.failedToRate' => 'Không thể update rating',
			'errors.reasonTimedOut' => 'Kết nối đã tạm thời',
			'errors.reasonUnreachable' => 'Server không thể truy cập được',
			'errors.reasonRefused' => 'server từ chối yêu cầu',
			'errors.reasonNotFound' => 'mục không còn trên máy chủ',
			'errors.reasonServerError' => 'Server nhận được lỗi',
			'errors.reasonCancelled' => 'Yêu cầu đã bị hủy',
			'errors.reasonUnexpected' => 'Một sai lầm bất ngờ xảy ra',
			'libraries.playRandomMovie' => 'Chơi một bộ phim ngẫu nhiên',
			'libraries.randomPickFailed' => 'Không thể chọn một bộ phim ngẫu nhiên từ thư viện này.',
			'libraries.title' => 'Thư viện',
			'libraries.fallbackTitle' => 'Thư viện',
			'libraries.scanLibraryFiles' => 'Scan thư viện file',
			'libraries.scanLibrary' => 'Quét thư viện',
			'libraries.analyze' => 'phân tích',
			'libraries.analyzeLibrary' => 'Phân tích Thư viện',
			'libraries.refreshMetadata' => 'Làm mới dữ liệu mô tả',
			'libraries.emptyTrash' => 'Dọn sạch thùng rác',
			'libraries.emptyingTrash' => ({required Object title}) => 'Khả năng làm sạch bụi bẩn cho "${title}..."',
			'libraries.trashEmptied' => ({required Object title}) => 'Trash emptied cho "${title}"',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Không làm trống rỗng: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'Phân tích “${title}...”',
			'libraries.analysisStarted' => ({required Object title}) => 'Phân tích bắt đầu cho "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Không phân tích thư viện: ${error}',
			'libraries.noLibrariesFound' => 'Không tìm thấy thư viện',
			'libraries.allLibrariesHidden' => 'Tất cả các thư viện được ẩn',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Thư viện ẩn (${count})',
			'libraries.thisLibraryIsEmpty' => 'Thư viện này trống',
			'libraries.noItemsMatchFilters' => 'Không có mục phù hợp với bộ lọc hoạt động',
			'libraries.resetFilters' => 'Đặt lại bộ lọc',
			'libraries.all' => 'Tất cả',
			'libraries.clearAll' => 'Tất cả rõ ràng',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'Bạn có chắc chắn bạn muốn quét "${title}"?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'Bạn có chắc chắn bạn muốn phân tích "${title}"?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'Bạn có chắc chắn rằng bạn muốn cập nhật dữ liệu metadata cho "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'Bạn có chắc chắn rằng bạn muốn làm trống rỗng cho "${title}"?',
			'libraries.manageLibraries' => 'Quản lý thư viện',
			'libraries.sort' => 'Sắp xếp',
			'libraries.sortBy' => 'Sắp xếp theo',
			'libraries.filters' => 'Bộ lọc',
			'libraries.confirmActionMessage' => 'Bạn có chắc chắn bạn muốn thực hiện hành động này không?',
			'libraries.showLibrary' => 'Hiển thị thư viện',
			'libraries.hideLibrary' => 'ẩn thư viện',
			'libraries.libraryOptions' => 'Tùy chọn thư viện',
			'libraries.content' => 'Thư viện Content',
			_ => null,
		} ?? switch (path) {
			'libraries.selectLibrary' => 'Chọn thư viện',
			'libraries.filtersWithCount' => ({required Object count}) => 'Bộ lọc (${count})',
			'libraries.noRecommendations' => 'Không có khuyến nghị có sẵn',
			'libraries.noCollections' => 'Không có tập hợp trong thư viện này',
			'libraries.noFoldersFound' => 'Không tìm thấy thư mục',
			'libraries.folders' => 'Thư Mục',
			'libraries.tabs.recommended' => 'khuyến cáo',
			'libraries.tabs.browse' => 'Duyệt',
			'libraries.tabs.collections' => 'Bộ Sưu Tập',
			'libraries.tabs.playlists' => 'Danh sách phát',
			'libraries.groupings.title' => 'Nhóm',
			'libraries.groupings.all' => 'Tất cả',
			'libraries.groupings.movies' => 'Phim',
			'libraries.groupings.shows' => 'Chương Trình TV',
			'libraries.groupings.seasons' => 'Phần',
			'libraries.groupings.episodes' => 'Tập Phim',
			'libraries.groupings.artists' => 'Ca Sĩ',
			'libraries.groupings.albums' => 'Album',
			'libraries.groupings.tracks' => 'Bản ghi',
			'libraries.groupings.folders' => 'Thư Mục',
			'libraries.filterCategories.genre' => 'Thể loại',
			'libraries.filterCategories.year' => 'Năm',
			'libraries.filterCategories.contentRating' => 'Content Đánh giá',
			'libraries.filterCategories.tag' => 'Nhãn',
			'libraries.filterCategories.unwatched' => 'Không quan sát',
			'libraries.filterCategories.unplayed' => 'Chưa Phát',
			'libraries.filterCategories.favorites' => 'Yêu Thích',
			'libraries.filterCategories.filePath' => 'file đường',
			'libraries.sortLabels.title' => 'Tiêu đề',
			'libraries.sortLabels.dateAdded' => 'Ngày thêm',
			'libraries.sortLabels.releaseDate' => 'Ngày phát hành',
			'libraries.sortLabels.rating' => 'Đánh giá',
			'libraries.sortLabels.communityRating' => 'Điểm cộng đồng',
			'libraries.sortLabels.criticRating' => 'Đánh giá Critical Rating',
			'libraries.sortLabels.userRating' => 'User Đánh giá',
			'libraries.sortLabels.datePlayed' => 'Ngày phát',
			'libraries.sortLabels.playCount' => 'Số lần phát',
			'libraries.sortLabels.productionYear' => 'Năm sản xuất',
			'libraries.sortLabels.runtime' => 'Thời lượng',
			'libraries.sortLabels.officialRating' => 'Rating chính thức',
			'libraries.sortLabels.premiereDate' => 'Ngày công chiếu',
			'libraries.sortLabels.startDate' => 'Start ngày',
			'libraries.sortLabels.airTime' => 'Thời gian phát sóng',
			'libraries.sortLabels.studio' => 'Hãng phim',
			'libraries.sortLabels.random' => 'Ngẫu Nhiên',
			'libraries.sortLabels.dateShared' => 'ngày chia sẻ',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Ngày cuối cùng của Air Date',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Chương cuối ngày thêm',
			'libraries.sortLabels.dateDownloaded' => 'Ngày tải xuống',
			'libraries.sortLabels.size' => 'Kích cỡ',
			'libraries.sortLabels.library' => 'Thư viện',
			'libraries.advancedFilters.include' => 'bao gồm',
			'libraries.advancedFilters.exclude' => 'trừ',
			'libraries.advancedFilters.any' => 'bất kỳ',
			'libraries.advancedFilters.yes' => 'Đúng',
			'libraries.advancedFilters.no' => 'Không',
			'libraries.advancedFilters.not' => ({required Object value}) => 'Không ${value}',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '${count} được chọn',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '${count} ngoại trừ',
			'libraries.advancedFilters.searchValues' => 'Giá trị tìm kiếm',
			'libraries.advancedFilters.noValues' => 'Không có giá trị',
			'libraries.advancedFilters.matchContains' => 'chứa',
			'libraries.advancedFilters.matchNotContains' => 'Không chứa',
			'libraries.advancedFilters.matchIs' => 'là',
			'libraries.advancedFilters.matchIsNot' => 'Không phải',
			'libraries.advancedFilters.matchBeginsWith' => 'Bắt đầu với',
			'libraries.advancedFilters.matchEndsWith' => 'Kết thúc với',
			'libraries.advancedFilters.textHint' => 'kiểu để match',
			'libraries.advancedFilters.from' => 'Từ',
			'libraries.advancedFilters.to' => 'để',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from} đến ${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value} và trên',
			'libraries.advancedFilters.atMost' => ({required Object value}) => 'Tối đa ${value}',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => '${count} ngày trước',
			'libraries.advancedFilters.dateLastYear' => 'năm ngoái',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => 'Tuổi hơn ${count} ngày',
			'libraries.advancedFilters.dateOlderThanYear' => 'Độ tuổi hơn 1 năm',
			'libraries.selection.selectItems' => 'Chọn mục',
			'libraries.selection.selectedCount' => ({required Object count}) => '${count} được chọn',
			'libraries.selection.actions' => 'Tùy chọn hành động',
			'libraries.selection.confirmDescendants' => 'Điều này thay đổi tất cả các tập trong các chương trình và mùa được chọn.',
			'libraries.selection.confirmUnwatched' => 'Thao tác này cũng xóa tiến trình phát của các mục đã chọn.',
			'libraries.selection.confirmCount' => ({required Object count}) => 'Các mục được chọn: ${count}.',
			'libraries.selection.completed' => ({required Object count}) => 'Các mục được cập nhật: ${count}.',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => 'Cập nhật ${succeeded}; thất bại ${failed}. mục thất bại vẫn được chọn.',
			'about.title' => 'Về',
			'about.openSourceLicenses' => 'Giấy phép nguồn mở',
			'about.versionLabel' => ({required Object version}) => 'Phiên bản ${version}',
			'about.appDescription' => 'Một khách hàng đẹp Plex, Jellyfin, và Emby cho Flutter',
			'about.viewLicensesDescription' => 'Xem giấy phép của các thư viện bên thứ ba',
			'about.privacyPolicy' => 'Chính sách Privacy',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Không tìm thấy máy chủ cho ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Không tải máy chủ: ${error}',
			'serverSelection.noValidServers' => 'Không tìm thấy máy chủ có sẵn trên tài khoản này',
			'hubDetail.title' => 'Tiêu đề',
			'hubDetail.releaseYear' => 'Giải phóng năm',
			'hubDetail.dateAdded' => 'Ngày thêm',
			'hubDetail.rating' => 'Đánh giá',
			'hubDetail.noItemsFound' => 'Không tìm thấy các mục',
			'logs.clearLogs' => 'Logs rõ ràng',
			'logs.copyLogs' => 'Bản sao Logs',
			'logs.uploadLogs' => 'tải logs',
			'logs.saveLogs' => 'Save Logs to File - Lưu Logs đến File',
			'logs.logsSaved' => ({required Object path}) => 'Đăng ký được lưu đến ${path}',
			'logs.saveLogsFailed' => 'Không thể lưu file log.',
			'startup.failedTitle' => 'PlezyNG không thể bắt đầu',
			'startup.failedBody' => 'Một cái gì đó đã sai trong quá trình khởi động. chi tiết bên dưới xác định những gì đã thất bại.',
			'startup.failedBodyRepairable' => 'Tệp cài đặt đã lưu của PlezyNG bị hỏng và phải được tạo lại trước khi ứng dụng có thể khởi động. Thử lại sẽ không giúp ích — hãy chọn sửa bộ nhớ.',
			'startup.phaseLabel' => 'Bước bước',
			'startup.showDetails' => 'Hiển thị chi tiết',
			'startup.hideDetails' => 'Ẩn chi tiết',
			'startup.copyDetails' => 'Copy chi tiết',
			'startup.detailsCopied' => 'Các chi tiết được sao chép vào clipboard',
			'startup.uploadDetails' => 'tải chi tiết',
			'startup.repairStorage' => 'sửa lưu trữ',
			'startup.repairTitle' => 'sửa lại dữ liệu được lưu trữ?',
			'startup.repairBodyCommon' => 'Tệp cài đặt của PlezyNG bị hư hỏng và không thể đọc được. sửa chữa tái cài đặt mỗi cài đặt theo mặc định.',
			'startup.repairBodyOneCredential' => 'Một đăng nhập được lưu được bị hư hỏng và không thể đọc được. sửa chữa loại bỏ chỉ một; các cài đặt khác của bạn được để lại một mình.',
			'startup.repairBodySignInsKept' => 'Trạng thái đăng nhập vào các máy chủ và hồ sơ của bạn sẽ được giữ lại nếu quá trình khôi phục diễn ra bình thường.',
			'startup.repairBodySignInsLost' => 'Không thể khôi phục khóa bảo vệ thông tin đăng nhập đã lưu từ tệp này. Bạn sẽ phải đăng nhập lại vào từng máy chủ và hồ sơ. Không có gì trên máy chủ nội dung bị ảnh hưởng.',
			'startup.repairBodySessionsUncertain' => 'Trackers (MAL, AniList, Simkl, Trakt) và Seerr được lưu trữ riêng biệt và có thể hay không tồn tại. PlezyNG sẽ cho bạn biết chính xác những gì nó giữ.',
			'startup.repairConfirm' => 'sửa chữa',
			'startup.repairSucceeded' => 'lưu trữ sửa chữa',
			'startup.repairNeedsRestart' => 'Lưu trữ được sửa chữa - cần khởi động lại',
			'startup.restartRequiredBody' => 'Dữ liệu của bạn đã được sửa, nhưng cần khởi động lại PlezyNG để sử dụng. Hãy đóng PlezyNG rồi mở lại.',
			'startup.quitPlezy' => 'Đánh giá PlezyNG',
			'startup.repairFailed' => 'sửa chữa thất bại',
			'startup.repairKeptSignIns' => 'Bạn vẫn đang đăng nhập vào các máy chủ và hồ sơ của mình.',
			'startup.repairLostSignIns' => 'Không thể khôi phục khóa bảo vệ thông tin đăng nhập đã lưu. Bạn sẽ phải đăng nhập lại vào từng máy chủ và hồ sơ.',
			'startup.repairLostSessions' => 'Ít nhất một tracker hoặc kết nối Seerr đã bị mất và phải được nối lại.',
			'startup.backupTitle' => 'Một bản sao của file bị hư hỏng đã được giữ lại',
			'startup.backupWarning' => 'Bản sao này chứa thông tin đăng nhập của bạn. Không tải lên hoặc chia sẻ.',
			'startup.deleteBackup' => 'xóa copy',
			'startup.backupDeleted' => 'Bản sao bị xóa',
			'startup.previousFailureTitle' => 'PlezyNG không bắt đầu lần cuối',
			'licenses.relatedPackages' => 'Các gói liên quan',
			'licenses.license' => 'Giấy phép',
			'licenses.licenseNumber' => ({required Object number}) => 'Giấy phép ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} giấy phép',
			'navigation.libraries' => 'Thư viện',
			'navigation.downloads' => 'Nội dung tải xuống',
			'navigation.liveTv' => 'Truyền hình trực tiếp',
			'navigation.explore' => 'Khám phá',
			'explore.mdblistShelves.manage' => 'Quản lý Khám phá Vườn',
			'explore.mdblistShelves.manageDescription' => 'Chọn và sắp xếp danh sách từ tài khoản MDBList của bạn',
			'explore.mdblistShelves.description' => 'Chọn danh sách phim và truyền hình công cộng từ tài khoản MDBList của bạn.Tạo hoặc sao chép danh sách trên MDBList, sau đó làm mới.',
			'explore.mdblistShelves.selected' => 'Chọn Chọn Chọn',
			'explore.mdblistShelves.available' => 'Danh sách tài khoản có sẵn',
			'explore.mdblistShelves.noLists' => 'Không có danh sách phim công cộng hoặc TV được trả về.Tạo hoặc sao chép một danh sách trên MDBList, sau đó làm mới.',
			'explore.mdblistShelves.displayName' => 'Shelf hiển thị tên',
			'explore.mdblistShelves.nameHint' => 'Để lại màu trắng để sử dụng tên danh sách nguồn.',
			'explore.mdblistShelves.add' => 'Thêm Shelf',
			'explore.mdblistShelves.save' => 'Bảo vệ shelves',
			'explore.mdblistShelves.moveUp' => ({required Object title}) => 'Chuyển ${title} lên',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => 'Chuyển ${title} xuống',
			'explore.mdblistShelves.unavailable' => 'Danh sách này không sẵn dùng. rút hoặc xóa hộp trong cài đặt.',
			'explore.mdblistShelves.rateLimited' => 'MDBList yêu cầu giới hạn đã đạt được. xin vui lòng rút lại sau.',
			'explore.mdblistShelves.loadFailed' => 'Không thể tải các tấm. kiểm tra kết nối của bạn và rút.',
			'explore.mdblistShelves.saveFailed' => 'Không thể bỏ qua được, xin vui lòng rút lui.',
			'explore.mdblistShelves.accountChanged' => 'Tài khoản hoặc hồ sơ đã thay đổi. mở lại các cài đặt này.',
			'explore.mdblistShelves.settingsUnreadable' => 'Các tab được tiết kiệm không thể được đọc. chọn danh sách của bạn một lần nữa để thay thế các cài đặt này.',
			'explore.title' => 'Khám phá',
			'explore.selectSource' => 'Chọn nguồn',
			'explore.rows.watchlist' => 'Danh sách Watchlist',
			'explore.rows.recommendedMovies' => 'Phim khuyến cáo',
			'explore.rows.recommendedShows' => 'Ưu đãi show',
			'explore.rows.trendingMovies' => 'Phim Trending',
			'explore.rows.trendingShows' => 'Xu hướng show',
			'explore.rows.popularMovies' => 'Phim phổ biến',
			'explore.rows.popularShows' => 'Ưu đãi phổ biến',
			'explore.rows.trendingAnime' => 'Xu hướng Anime',
			'explore.rows.suggestedAnime' => 'Anime đề xuất',
			'explore.rows.airingAnime' => 'Lời bài hát: Top Airing Anime',
			'explore.rows.popularAnime' => 'Anime phổ biến nhất',
			'explore.rows.trending' => 'xu hướng',
			'explore.rows.upcomingMovies' => 'phim sắp tới',
			'explore.rows.upcomingShows' => 'Các chương trình sắp tới',
			'explore.status.airing' => 'không khí',
			'explore.status.ended' => 'Đã Kết Thúc',
			'explore.status.canceled' => 'hủy',
			'explore.status.upcoming' => 'Sắp Công Chiếu',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Phản ứng', ), 
			'explore.cast' => 'Diễn viên',
			'explore.characters' => 'nhân vật',
			'explore.addToWatchlist' => 'Thêm vào Watchlist',
			'explore.removeFromWatchlist' => 'Xóa khỏi Watchlist',
			'explore.addedToWatchlist' => 'Thêm vào watchlist',
			'explore.removedFromWatchlist' => 'Xóa khỏi watchlist',
			'explore.watchlistUpdateFailed' => 'Không thể update watchlist',
			'explore.watchlistNoMatch' => 'Không thể phù hợp với mục này với danh sách xem',
			'explore.notInLibrary' => 'Không phải trong thư viện',
			'explore.inTheseLibraries' => 'Trong các thư viện này',
			'explore.checkingLibrary' => 'Kiểm tra thư viện của bạn...',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n, other: 'Không thể kiểm tra ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} máy chủ', ), 
			'explore.emptyTitle' => 'Chưa có gì ở đây',
			'explore.emptyMessage' => ({required Object source}) => 'Các dòng từ ${source} sẽ xuất hiện ở đây một khi họ có nội dung.',
			'explore.searchHint' => ({required Object source}) => 'Tìm kiếm ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'Không có kết quả cho "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'Tìm kiếm các bộ phim và chương trình trên ${source}.',
			'explore.searchFailed' => 'Tìm kiếm thất bại. kiểm tra kết nối của bạn và thử lại.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} phổ biến',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} không khí',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} đánh giá',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} xu hướng',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} trong ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} xem',
			'explore.badge.available' => 'Sẵn có',
			'explore.badge.partiallyAvailable' => 'Phần có sẵn',
			'explore.badge.availableIn4k' => '4K có sẵn',
			'explore.badge.requested' => 'yêu cầu',
			'explore.badge.pendingApproval' => 'Thời gian chấp thuận',
			'explore.badge.processing' => 'xử lý',
			'explore.badge.declined' => 'giảm',
			'explore.badge.requestFailed' => 'yêu cầu thất bại',
			'explore.badge.requested4k' => '4K yêu cầu',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} mùa',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => 'Ep ${episode} trong ${duration}',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'Tiếp theo tại ${duration}',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} tập',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} phút/tập',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} Danh sách',
			'explore.stats.viewersDay' => ({required Object n}) => '${n} xem ngày hôm nay',
			'explore.stats.viewersWeek' => ({required Object n}) => '${n} xem trong tuần này',
			'explore.stats.viewersMonth' => ({required Object n}) => '${n} xem trong tháng này',
			'explore.stats.viewersYear' => ({required Object n}) => '${n} xem năm nay',
			'explore.stats.viewersAllTime' => ({required Object n}) => '${n} người xem',
			'explore.stats.planning' => ({required Object n}) => '${n} kế hoạch để xem',
			'explore.stats.favorited' => ({required Object n}) => '${n} yêu thích',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} đã bỏ qua nó',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} bình luận', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} phiếu bầu',
			'explore.stats.watching' => ({required Object n}) => '${n} xem nó',
			'explore.stats.completed' => ({required Object n}) => '${n} hoàn thành',
			'explore.stats.onHold' => ({required Object n}) => '${n} trên nắm giữ',
			'explore.stats.dropped' => ({required Object n}) => '${n} Đã mất',
			'explore.season.winter' => 'Mùa đông',
			'explore.season.spring' => 'Xuân',
			'explore.season.summer' => 'Mùa hè',
			'explore.season.fall' => 'rơi',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'TV',
			'explore.format.tvShort' => 'TV ngắn',
			'explore.format.movie' => 'Phim',
			'explore.format.special' => 'đặc biệt',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => 'Nhạc',
			'explore.format.other' => 'Khác',
			'explore.sourceMaterial.original' => 'nguyên bản',
			'explore.sourceMaterial.manga' => 'Manga',
			'explore.sourceMaterial.lightNovel' => 'Ánh sáng novel',
			'explore.sourceMaterial.novel' => 'Tiểu thuyết',
			'explore.sourceMaterial.visualNovel' => 'Visual Novel Giới thiệu',
			'explore.sourceMaterial.game' => 'Trò chơi',
			'explore.sourceMaterial.webComic' => 'Trang web Comic',
			'explore.sourceMaterial.musicRelease' => 'Nhạc',
			'explore.sourceMaterial.otherMedia' => 'Khác',
			'explore.creditRole.actor' => 'Diễn viên',
			'explore.creditRole.director' => 'Đạo Diễn',
			'explore.creditRole.writer' => 'Người viết',
			'explore.creditRole.producer' => 'Nhà sản xuất',
			'explore.creditRole.creator' => 'Người sáng tạo',
			'explore.creditRole.composer' => 'Nhà soạn nhạc',
			'explore.relation.prequel' => 'Prequê',
			'explore.relation.sequel' => 'tiếp theo',
			'explore.relation.sideStory' => 'Câu chuyện bên',
			'explore.relation.spinOff' => 'Ngoại truyện',
			'explore.relation.alternativeVersion' => 'Phiên bản thay thế',
			'explore.relation.summary' => 'Tổng hợp',
			'explore.relation.parentStory' => 'Câu chuyện cha mẹ',
			'explore.relation.adaptation' => 'thích ứng',
			'explore.relation.other' => 'liên quan',
			'explore.broadcast' => ({required Object day, required Object time}) => 'Airs ${day} tại ${time}',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => 'Airs ${day} tại ${time} ${timezone}',
			'explore.detail.originalTitle' => 'Tiêu đề gốc',
			'explore.detail.alsoKnownAs' => 'cũng được biết đến như',
			'explore.detail.studios' => 'Hãng Phim',
			'explore.detail.country' => 'đất nước',
			'explore.detail.language' => 'Ngôn ngữ',
			'explore.detail.released' => 'Giải phóng',
			'explore.detail.physicalRelease' => 'trên đĩa',
			'explore.detail.ended' => 'Đã Kết Thúc',
			'explore.detail.addedOn' => ({required Object date}) => 'Thêm ${date}',
			'explore.detail.yourRating' => 'Đánh giá của bạn',
			'explore.detail.budget' => 'ngân sách',
			'explore.detail.revenue' => 'Box văn phòng',
			'explore.detail.contentAdvisory' => 'Lời hướng dẫn tuổi',
			'explore.detail.tags' => 'Thẻ',
			'explore.detail.revealSpoilerTags' => 'Hiển thị spoiler tags',
			'explore.detail.links' => 'trái',
			'explore.detail.watchOn' => 'Xem tại',
			'explore.detail.watchTrailer' => 'Xem trailer',
			'explore.detail.openOn' => ({required Object site}) => 'Khởi mở tại ${site}',
			'explore.detail.crew' => 'phi hành đoàn',
			'explore.detail.ratings' => 'Đánh giá',
			'explore.detail.schedule' => 'Lên lịch',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n, other: 'Đề nghị bởi ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} người dùng', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'Đề nghị bởi ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'Ưu đãi của ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} chưa được trình bày',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'Đề nghị bởi ${percent} người xem',
			'explore.detail.relatedTitles' => 'Các tiêu đề liên quan',
			'explore.detail.background' => 'nền',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} kết quả', ), 
			'liveTv.title' => 'Truyền hình trực tiếp',
			'liveTv.guide' => 'Lịch phát sóng',
			'liveTv.noChannels' => 'Không có kênh',
			'liveTv.noDvr' => 'Không có DVR được cấu hình trên bất kỳ máy chủ nào',
			'liveTv.serverUnavailable' => 'Live TV server không có sẵn.',
			'liveTv.serverNotConnected' => 'Máy chủ TV trực tiếp không được kết nối.',
			'liveTv.noPrograms' => 'Không có dữ liệu chương trình',
			'liveTv.liveStreamFailed' => 'Live Stream thất bại',
			'liveTv.unknownProgram' => 'Chương trình chưa biết',
			'liveTv.timelineLiveProgram' => 'Chương trình trực tiếp (playback có thể nằm ngoài chương trình này)',
			'liveTv.timelineBuffer' => 'Thời gian buffer',
			'liveTv.timelineUnavailable' => 'Thời gian không sẵn dùng',
			'liveTv.timelineEstimated' => 'Đánh giá playback',
			'liveTv.timelinePending' => 'Tìm kiếm',
			'liveTv.timelineStale' => 'Lập trình có thể bị lỗi thời',
			'liveTv.unknownHub' => 'Không rõ',
			'liveTv.unknownError' => 'sai lầm chưa biết',
			'liveTv.channelNumber' => ({required Object number}) => 'kênh ${number}',
			'liveTv.unknownChannel' => 'kênh chưa biết',
			'liveTv.live' => 'Trực tiếp',
			'liveTv.premiereBadge' => 'Mới',
			'liveTv.reloadGuide' => 'Hướng dẫn tải về',
			'liveTv.searchGuide' => 'Hướng dẫn tìm kiếm',
			'liveTv.searchHint' => 'Các kênh tìm kiếm & chương trình',
			'liveTv.searchNoResults' => ({required Object query}) => 'Không có trận đấu cho "${query}"',
			'liveTv.channelsSection' => 'Kênh',
			'liveTv.programsSection' => 'Chương Trình',
			'liveTv.now' => 'Bây giờ',
			'liveTv.today' => 'Hôm nay',
			'liveTv.tomorrow' => 'Ngày mai',
			'liveTv.midnight' => 'nửa đêm',
			'liveTv.overnight' => 'buổi tối',
			'liveTv.morning' => 'buổi sáng',
			'liveTv.daytime' => 'Thời gian',
			'liveTv.evening' => 'Đêm',
			'liveTv.lateNight' => 'đêm muộn',
			'liveTv.whatsOn' => 'cái gì trên',
			'liveTv.watchChannel' => 'Xem kênh',
			'liveTv.favorites' => 'Yêu Thích',
			'liveTv.reorderFavorites' => 'Lời bài hát Favorite',
			'liveTv.noFavoriteChannels' => 'Không có kênh yêu thích',
			'liveTv.noFavoriteChannelsHint' => 'Hiển thị tất cả các kênh, sau đó nhấn dài một kênh để thêm nó vào yêu thích của bạn.',
			'liveTv.showAllChannels' => 'Hiển thị tất cả các kênh',
			'liveTv.favoritesLoadFailed' => 'Không thể tải các yêu thích. kiểm tra kết nối của bạn và thử lại.',
			'liveTv.favoritesUpdateFailed' => 'Không thể cập nhật yêu thích. kiểm tra kết nối của bạn và thử lại.',
			'liveTv.joinSession' => 'Tham gia phiên trong tiến bộ',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Xem từ đầu (${minutes} phút trước)',
			'liveTv.watchLive' => 'Xem Live',
			'liveTv.goToLive' => 'đi sống',
			'liveTv.record' => 'Ghi lại',
			'liveTv.recordEpisode' => 'kỷ lục episode',
			'liveTv.recordSeries' => 'Ghi lại loạt phim',
			'liveTv.recordOptions' => 'Lựa chọn Record',
			'liveTv.saveTo' => 'Lưu vào',
			'liveTv.recordings' => 'Bản ghi',
			'liveTv.scheduledRecordings' => 'Kế hoạch',
			'liveTv.recordingRules' => 'Quy tắc ghi âm',
			'liveTv.noScheduledRecordings' => 'Không có gì được lên kế hoạch để ghi lại',
			'liveTv.manageRecording' => 'Quản lý ghi lại',
			'liveTv.cancelRecording' => 'Hủy ghi lại',
			'liveTv.cancelRecordingTitle' => 'Hủy bỏ bản ghi này?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} sẽ không còn được ghi lại.',
			'liveTv.deleteRule' => 'xóa quy tắc',
			'liveTv.deleteRuleTitle' => 'Xóa quy tắc ghi âm?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'Các tập phim tương lai của ${title} sẽ không được ghi lại.',
			'liveTv.recordingScheduled' => 'Ghi theo lịch trình.',
			'liveTv.alreadyScheduled' => 'Chương trình này đã được lên kế hoạch',
			'liveTv.dvrAdminRequired' => 'Cài đặt DVR đòi hỏi tài khoản admin',
			'liveTv.recordingFailed' => 'Không thể lên lịch ghi âm',
			'liveTv.recordingTargetMissing' => 'Không thể xác định việc ghi lại thư viện',
			'liveTv.recordNotAvailable' => 'Ghi âm không sẵn dùng cho chương trình này',
			'liveTv.recordingCancelled' => 'Ghi âm hủy',
			'liveTv.recordingRuleDeleted' => 'Quy tắc ghi âm bị xóa',
			'liveTv.processRecordingRules' => 'Đánh giá lại các quy tắc',
			'liveTv.recordingInProgress' => 'Ghi âm Now',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} dự kiến',
			'liveTv.editRule' => 'Edit quy tắc',
			'liveTv.editRuleAction' => 'Sửa',
			'liveTv.recordingRuleUpdated' => 'Quy tắc ghi lại cập nhật',
			'liveTv.guideReloadRequested' => 'Hướng dẫn làm mới được yêu cầu',
			'liveTv.guideReloadFailed' => 'Không thể làm mới hướng dẫn',
			'liveTv.rulesProcessRequested' => 'Quy tắc đánh giá lại được yêu cầu',
			'liveTv.rulesProcessFailed' => 'Không thể đánh giá lại các quy tắc ghi âm',
			'liveTv.recordShow' => 'Record show diễn',
			'liveTv.recordSettings.startEarly' => 'Bắt đầu sớm (từ 2 giây)',
			'liveTv.recordSettings.endLate' => 'Kết thúc muộn (tạm dịch: Seconds)',
			'liveTv.recordSettings.newOnly' => 'Chỉ có các tập mới',
			'liveTv.recordSettings.anyChannel' => 'Ghi âm trên bất kỳ kênh nào',
			'liveTv.recordSettings.anyTime' => 'Ghi chú bất cứ lúc nào',
			'liveTv.recordSettings.skipInLibrary' => 'Tải các tập phim đã ở trong thư viện',
			'liveTv.recordSettings.keepUpTo' => 'Các sự kiện để duy trì',
			'liveTv.recordSettings.keepUpToHint' => '0 giữ cho mỗi tập',
			'liveTv.startingInMinutes' => ({required Object minutes}) => 'Bắt đầu trong ${minutes} phút',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} tại ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product} trả về dữ liệu phát trực tiếp TV không hợp lệ',
			'liveTv.failedToStartChannel' => 'Không thể khởi động kênh trực tiếp',
			'liveTv.failedToBuildStreamUrl' => 'Không thể xây dựng dòng URL',
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'Không thể khởi động kênh: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'Không thể chuyển kênh: ${reason}',
			'collections.title' => 'Bộ Sưu Tập',
			'collections.collection' => 'Bộ Sưu Tập',
			'collections.empty' => 'Bộ sưu tập trống',
			'collections.deleteCollection' => 'Xóa Bộ Sưu Tập',
			'collections.deleteConfirm' => ({required Object title}) => 'Xóa "${title}"? Không thể hoàn tác thao tác này.',
			'collections.deleted' => 'Bộ sưu tập xóa',
			'collections.deleteFailed' => 'Không xóa bộ sưu tập',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Không xóa bộ sưu tập: ${error}',
			'collections.selectCollection' => 'Chọn bộ sưu tập',
			'collections.collectionName' => 'Collection Tên',
			'collections.enterCollectionName' => 'Nhập tên bộ sưu tập',
			'collections.addedToCollection' => 'Thêm vào Collection',
			'collections.errorAddingToCollection' => 'Không thể thêm vào bộ sưu tập',
			'collections.created' => 'Bộ sưu tập được tạo ra',
			'collections.removeFromCollection' => 'Xóa khỏi bộ sưu tập',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => 'Xóa “${title}” khỏi bộ sưu tập này?',
			'collections.removedFromCollection' => 'Loại bỏ từ bộ sưu tập',
			'collections.removeFromCollectionFailed' => 'Không thể loại bỏ khỏi bộ sưu tập',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Sai lầm xóa khỏi bộ sưu tập: ${error}',
			'collections.searchCollections' => 'Tìm kiếm bộ sưu tập',
			'playlists.title' => 'Danh sách phát',
			'playlists.playlist' => 'Danh sách phát',
			'playlists.noPlaylists' => 'Không tìm thấy playlist',
			'playlists.create' => 'Tạo Playlist',
			'playlists.playlistName' => 'Playlist Tên',
			'playlists.enterPlaylistName' => 'Nhập tên playlist',
			'playlists.delete' => 'Xóa Danh Sách Phát',
			'playlists.removeItem' => 'Xóa khỏi danh sách phát',
			'playlists.smartPlaylist' => 'Đồ chơi thông minh',
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(count, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} mục', ), 
			'playlists.emptyPlaylist' => 'Danh sách game này trống',
			'playlists.deleteConfirm' => 'xóa playlist?',
			'playlists.deleteMessage' => ({required Object name}) => 'Bạn có chắc chắn bạn muốn xóa "${name}" không?',
			'playlists.created' => 'Playlist tạo ra',
			'playlists.deleted' => 'Playlist xóa',
			'playlists.itemAdded' => 'Thêm vào playlist',
			'playlists.itemRemoved' => 'Xóa khỏi playlist',
			'playlists.selectPlaylist' => 'Chọn Playlist',
			'playlists.searchPlaylists' => 'Tìm kiếm playlists',
			'playlists.errorCreating' => 'Không thể tạo playlist',
			'playlists.errorDeleting' => 'Không xóa playlist',
			'playlists.errorLoading' => 'Không tải các playlists',
			'playlists.errorAdding' => 'Không thể thêm vào playlist',
			'playlists.errorReordering' => 'Không thể đặt lại các mục playlist',
			'playlists.errorRemoving' => 'Không thể loại bỏ khỏi playlist',
			'music.goToAlbum' => 'Đi đến album',
			'music.goToArtist' => 'Đi đến nghệ sĩ',
			'music.instantMix' => 'Trộn Lẫn Nhanh',
			'music.playNext' => 'Phát kế tiếp',
			'music.addToQueue' => 'Thêm vào Queue',
			'music.discNumber' => ({required Object n}) => 'Đĩa ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} đường dẫn', ), 
			'music.nowPlaying' => 'Bây giờ chơi',
			'music.playingFrom' => ({required Object title}) => 'Chơi từ ${title}',
			'music.queue' => 'Quay',
			'music.clearQueue' => 'Xóa hàng đợi',
			'music.lyrics' => 'Lời bài hát',
			'music.visualizer' => 'hình ảnh',
			'music.visualizerProfileLoading' => 'Đọc Track Analysis...',
			'music.visualizerAmbientMotion' => 'động cơ môi trường',
			'music.visualizerPlexLoudness' => 'Plex tiếng ồn',
			'music.visualizerLiveAudio' => 'Phân tích âm thanh trực tiếp',
			'music.visualizerPreviousPreset' => 'Phong cách Visual Previous',
			'music.visualizerNextPreset' => 'Tiếp theo: Visual Style',
			'music.visualizerPresetAurora' => 'Cực quang',
			'music.visualizerPresetBloom' => 'Nở hoa',
			'music.visualizerPresetOrbitals' => 'Ước',
			'music.visualizerPresetPrism' => 'Lăng kính',
			'music.visualizerPresetTunnel' => 'đường hầm',
			'music.visualizerPresetTrackMap' => 'Track Bản đồ',
			'music.noLyrics' => 'Không có Lyrics',
			'music.sleepTimer' => 'Giấc ngủ Timer',
			'music.sleepTimerEndOfTrack' => 'Kết thúc track',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} phút', ), 
			'music.stopPlayback' => 'Dừng Phát',
			'music.previousTrack' => 'Bản ghi trước',
			'music.nextTrack' => 'Bản ghi tiếp theo',
			'music.repeat' => 'Lặp lại',
			'music.repeatAll' => 'Lặp lại tất cả',
			'music.repeatOne' => 'Lặp lại một lần',
			'music.instantMixNoServer' => 'Không có máy chủ có sẵn cho một hỗn hợp tức thời',
			'music.instantMixFailed' => 'Không thể tải được hỗn hợp tức thời',
			'music.instantMixEmpty' => 'Tốc độ hỗn hợp đã trở lại với không có dấu vết',
			'music.noAudioUrl' => ({required Object track}) => 'Không có URL âm thanh có sẵn cho ${track}',
			'music.discography.singlesAndEps' => 'Đĩa đơn và EP',
			'music.discography.live' => 'Trực tiếp',
			'music.discography.compilations' => 'Tuyển tập',
			'watchTogether.title' => 'Xem cùng nhau',
			'watchTogether.description' => 'Xem nội dung đồng bộ với bạn bè và gia đình',
			'watchTogether.createRoom' => 'tạo phòng',
			'watchTogether.creatingRoom' => 'Tạo phòng...',
			'watchTogether.joinRoom' => 'Tham gia phòng',
			'watchTogether.joiningRoom' => 'Tham gia phòng...',
			'watchTogether.connecting' => 'Kết nối...',
			'watchTogether.relayPublic' => 'Các phòng sử dụng các phát sóng Open Watch Party công cộng.',
			'watchTogether.relayCustom' => ({required Object url}) => 'Các căn phòng sử dụng điện thoại của bạn tại ${url}.',
			'watchTogether.recentRooms' => 'Phòng mới',
			'watchTogether.roomActions' => 'Phòng hành động',
			'watchTogether.renameRoom' => 'Đặt phòng',
			'watchTogether.removeRoom' => 'Gỡ bỏ',
			'watchTogether.enterRoomCode' => 'Nhập mã 6 ký tự từ host.',
			'watchTogether.roomCode' => 'Mã phòng',
			'watchTogether.paste' => 'Ăn bánh',
			'watchTogether.noCodeInClipboard' => 'Clipboard không chứa mã phòng',
			'watchTogether.copyCode' => 'Copy mã',
			'watchTogether.codeCopied' => 'Mã phòng copy',
			'watchTogether.shareInvite' => 'Chia sẻ mời',
			'watchTogether.inviteCopied' => 'Gửi tin nhắn, gửi nó vào một tin nhắn.',
			_ => null,
		} ?? switch (path) {
			'watchTogether.inviteMessage' => ({required Object code}) => 'Tham gia phòng đồng hồ của tôi tại PlezyNG: mở phòng đồng hồ, chọn phòng đồng hồ và nhập phòng đồng hồ ${code}.',
			'watchTogether.openSessionControls' => 'Open Watch Cùng kiểm soát phiên',
			'watchTogether.reconnecting' => 'Kết nối lại...',
			'watchTogether.reconnectingDescription' => 'Kết nối bị hỏng. bạn sẽ tự động vào phòng.',
			'watchTogether.connected' => 'Kết nối',
			'watchTogether.disconnected' => 'Khóa kết nối',
			'watchTogether.youAreHost' => 'Ngươi là người chủ',
			'watchTogether.hostedBy' => ({required Object name}) => 'Được lưu trữ bởi ${name}',
			'watchTogether.hostControlsPlayback' => 'Hướng dẫn cài đặt playback',
			'watchTogether.anyoneCanControl' => 'Ai cũng có thể kiểm soát playback',
			'watchTogether.roomLocked' => 'phòng khóa',
			'watchTogether.nowPlaying' => 'Bây giờ chơi',
			'watchTogether.nothingPlaying' => 'Không chơi gì',
			'watchTogether.nothingPlayingHost' => 'Chơi một cái gì đó từ bất kỳ thư viện nào để chia sẻ nó với phòng.',
			'watchTogether.nothingPlayingGuest' => 'Khi chủ sở hữu chơi một cái gì đó, nó mở ra ở đây.',
			'watchTogether.notShareable' => 'Video này không có danh sách phù hợp, vì vậy chỉ có những người có quyền truy cập vào cùng một máy chủ có thể chơi nó.',
			'watchTogether.searching' => 'Tìm kiếm video này trong thư viện của bạn ...',
			'watchTogether.yourCopy' => 'bản sao của bạn',
			'watchTogether.sharingYourCopy' => 'Bạn đang chia sẻ bản sao của mình',
			'watchTogether.playingOtherLength' => ({required Object difference}) => 'Chơi bản sao của bạn, ${difference}',
			'watchTogether.mismatchTitle' => 'Bản sao của bạn là một chiều dài khác nhau',
			'watchTogether.mismatchDescription' => ({required Object difference}) => 'Bản sao gần nhất của bạn là ${difference} so với video của phòng. nó có thể là một cắt hoặc phiên bản khác.',
			'watchTogether.playAnyway' => 'Chơi bất cứ',
			'watchTogether.chooseAnotherCopy' => 'Chọn một bản sao khác',
			'watchTogether.dontPlay' => 'Đừng chơi',
			'watchTogether.unavailableTitle' => 'Bạn không có video này',
			'watchTogether.unavailableDescription' => 'PlezyNG không thể tìm thấy nó trong thư viện của bạn. chọn bản sao cho chính mình hoặc tìm kiếm lại.',
			'watchTogether.chooseCopy' => 'Chọn một bản sao',
			'watchTogether.searchAgain' => 'Tìm lại',
			'watchTogether.noCandidates' => 'Không có bản sao được tìm thấy trong thư viện của bạn.',
			'watchTogether.choiceFailed' => 'Tôi không thể chơi bản sao này cho phòng',
			'watchTogether.lengthLonger' => ({required Object duration}) => '${duration} lâu hơn',
			'watchTogether.lengthShorter' => ({required Object duration}) => '${duration} ngắn hơn',
			'watchTogether.lengthSame' => 'cùng chiều dài',
			'watchTogether.lengthUnknown' => 'Kích thước không rõ',
			'watchTogether.joinCurrentPlayback' => 'Tham gia Playback hiện tại',
			'watchTogether.joinCurrentPlaybackDescription' => 'Trở lại vào những gì chủ sở hữu hiện đang xem',
			'watchTogether.stopMedia' => 'Video cho mọi người',
			'watchTogether.syncOffset' => 'Đồng bộ Offset',
			'watchTogether.syncOffsetDescription' => 'Chuyển đổi video của bạn nếu nó chạy trước hoặc sau phòng.',
			'watchTogether.offsetHint' => ({required Object difference}) => 'Bản sao của bạn là ${difference} so với video của phòng.',
			'watchTogether.applyDifference' => ({required Object offset}) => 'Sử dụng ${offset}',
			'watchTogether.offsetMinusSecond' => '1 s',
			'watchTogether.offsetMinusTenth' => '- 100 ms',
			'watchTogether.offsetPlusTenth' => '+ 100 ms',
			'watchTogether.offsetPlusSecond' => '+ 1 s',
			'watchTogether.participants' => 'người tham gia',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} người tham gia', ), 
			'watchTogether.hostBadge' => 'Máy chủ',
			'watchTogether.nameYou' => ({required Object name}) => '${name} (Các bạn)',
			'watchTogether.playerIdle' => 'Nhàn rỗi',
			'watchTogether.playerLoading' => 'tải',
			'watchTogether.playerReady' => 'sẵn sàng',
			'watchTogether.playerBuffering' => 'Buckingheri',
			'watchTogether.matchSearching' => 'Tìm kiếm',
			'watchTogether.matchMatched' => 'Có video',
			'watchTogether.matchMismatched' => 'chiều dài khác nhau',
			'watchTogether.matchUnavailable' => 'Không có video',
			'watchTogether.participantOffset' => ({required Object offset}) => 'Tính năng: Offset ${offset}',
			'watchTogether.makeHost' => 'làm chủ',
			'watchTogether.makeHostQuestion' => 'Chuyển khách?',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} sẽ kiểm soát playback và chạy phiên cho tất cả mọi người.',
			'watchTogether.transfer' => 'Chuyển đổi',
			'watchTogether.removeParticipant' => 'Xóa khỏi phòng',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => 'Xóa ${name}?',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} rời khỏi phòng. họ có thể tham gia lại với mã trừ khi bạn khóa phòng.',
			'watchTogether.remove' => 'Gỡ bỏ',
			'watchTogether.roomSettings' => 'Thiết lập phòng',
			'watchTogether.letEveryoneControl' => 'Hãy để mọi người kiểm soát Playback',
			'watchTogether.lockRoom' => 'Phòng Lock',
			'watchTogether.lockRoomDescription' => 'Không ai mới có thể tham gia',
			'watchTogether.leaveRoom' => 'Giữ phòng',
			'watchTogether.leaveRoomQuestion' => 'Giữ phòng?',
			'watchTogether.leaveRoomConfirm' => 'Bạn có thể tham gia lại với mã phòng.',
			'watchTogether.leave' => 'rời đi',
			'watchTogether.endRoom' => 'phòng cuối',
			'watchTogether.endRoomQuestion' => 'phòng cuối ?',
			'watchTogether.endRoomConfirm' => 'Đây là kết thúc của phòng cho tất cả mọi người.',
			'watchTogether.end' => 'Kết thúc',
			'watchTogether.playBlockedTitle' => 'Playback không bắt đầu',
			'watchTogether.playBlockedDescription' => 'Tải về trò chơi để bắt đầu xem với phòng.',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} áp lực chơi',
			'watchTogether.notices.playbackStarted' => 'Playback bắt đầu',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} nghỉ ngơi',
			'watchTogether.notices.playbackPaused' => 'Playback nghỉ ngơi',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} nhảy lên ${position}',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => 'Đang xem mục từ: ${position}',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} đặt tốc độ lên ${speed}',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => 'Tốc độ được thiết lập lên đến ${speed}',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} bắt đầu ${title}',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => 'Bây giờ chơi ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} dừng video',
			'watchTogether.notices.mediaStopped' => 'Video đã dừng lại',
			'watchTogether.notices.waitingFor' => ({required Object name}) => 'Đang xem mục từ: ${name}',
			'watchTogether.notices.waitingForSomeone' => 'Chờ đợi ai đó bắt được...',
			'watchTogether.notices.finished' => 'Kết thúc',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} hiện đang là chủ nhà',
			'watchTogether.notices.youAreNowHost' => 'Bây giờ bạn là người chủ',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} tham gia',
			'watchTogether.notices.left' => ({required Object name}) => '${name} đã rời đi',
			'watchTogether.notices.controlRefused' => 'Chỉ có chủ sở hữu mới có thể kiểm soát playback',
			'watchTogether.notices.searchFailed' => 'Một số máy chủ không thể được tìm kiếm cho video của phòng',
			'watchTogether.notices.playBlocked' => 'Tải về trò chơi để bắt đầu',
			'watchTogether.notices.shareFailed' => 'Tôi không thể chia sẻ video này với phòng',
			'watchTogether.notices.downloadNotShared' => 'Tải xuống không được chia sẻ với phòng trong khi máy chủ của họ offline',
			'watchTogether.notices.openFailed' => 'Không thể mở video phòng',
			'watchTogether.ended.ended' => 'Khách mời kết thúc phòng',
			'watchTogether.ended.kicked' => 'Bạn bị loại bỏ khỏi phòng',
			'watchTogether.ended.expired' => 'Phòng trôi qua',
			'watchTogether.ended.replaced' => 'Bạn đã kết nối phòng này trên thiết bị khác',
			'watchTogether.ended.lost' => 'Mất kết nối với phòng',
			'watchTogether.errors.invalidCode' => 'Mã có 6 chữ cái và số, mà không có 0, 1, I, L hoặc O.',
			'watchTogether.errors.roomNotFound' => 'Không có phòng nào có mã đó, có lẽ nó đã kết thúc.',
			'watchTogether.errors.roomFull' => 'Căn phòng đó đầy.',
			'watchTogether.errors.roomLocked' => 'Người chủ đã đóng cửa căn phòng đó.',
			'watchTogether.errors.relayFull' => 'Xem cùng nhau đang bận rộn ngay bây giờ. thử lại sau này.',
			'watchTogether.errors.unreachable' => 'Tôi không thể đạt được đồng hồ cùng nhau phát sóng. kiểm tra kết nối của bạn.',
			'watchTogether.errors.rateLimited' => 'Đã có quá nhiều nỗ lực, hãy đợi một phút và thử lại.',
			'watchTogether.errors.clientBlocked' => 'Phiên bản PlezyNG này không thể sử dụng bản phát.',
			'watchTogether.errors.forbidden' => 'Chỉ có chủ nhà mới có thể làm được điều đó.',
			'watchTogether.errors.notInRoom' => 'Bạn không ở trong một căn phòng.',
			'watchTogether.errors.alreadyInRoom' => 'Bạn đã ở trong một căn phòng.',
			'watchTogether.errors.resumeFailed' => 'Tôi không thể vào phòng.',
			'watchTogether.errors.unsupported' => 'Truyền thông không ủng hộ điều này.',
			'watchTogether.errors.generic' => 'Có điều gì đó sai rồi, hãy thử lại.',
			'watchTogether.untitledEpisode' => ({required Object number}) => 'Chương ${number}',
			'downloads.title' => 'Nội dung tải xuống',
			'downloads.manage' => 'quản lý',
			'downloads.tvShows' => 'Chương Trình TV',
			'downloads.movies' => 'Phim',
			'downloads.music' => 'Nhạc',
			'downloads.tracksQueued' => ({required Object count}) => '${count} tracks queued cho download',
			'downloads.noDownloads' => 'Không tải xuống',
			'downloads.noDownloadsDescription' => 'Nội dung tải xuống sẽ xuất hiện ở đây để xem offline',
			'downloads.downloadNow' => 'Tải về',
			'downloads.deleteDownload' => 'Tải Download',
			'downloads.retryDownload' => 'Retry tải xuống',
			'downloads.downloadQueued' => 'Tải xuống đã được xếp hàng đợi.',
			'downloads.downloadResumed' => 'Download Đổi lại',
			'downloads.serverErrorBitrate' => 'lỗi máy chủ: file có thể vượt quá giới hạn bitrate từ xa',
			'downloads.storageFull' => 'Tải xuống dừng lại để bảo vệ lưu trữ có sẵn.Tự do một số không gian hoặc chọn một vị trí tải xuống khác, sau đó rút lại.',
			'downloads.storageUnavailable' => 'Tải xuống dừng lại vì lưu trữ có sẵn không thể được kiểm tra. kiểm tra vị trí tải xuống, sau đó rút lại.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} episodes quoted for download (liên kết  sửa đổi)',
			'downloads.downloadDeleted' => 'Download đã xóa',
			'downloads.deleteConfirm' => ({required Object title}) => 'Xóa "${title}" từ thiết bị này?',
			'downloads.deleteCollectionDownloads' => 'Xóa Downloads',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => 'Xóa mọi tệp đã tải xuống trong “${title}” khỏi thiết bị này?',
			'downloads.collectionDownloadsDeleted' => 'Downloads xóa',
			'downloads.cancelledDownloadTitle' => 'Hủy Download',
			'downloads.cancelledDownloadMessage' => 'Download này đã bị hủy bỏ. bạn muốn làm gì?',
			'downloads.allEpisodesAlreadyDownloaded' => 'Tất cả các tập đã tải xuống',
			'downloads.resumeDownload' => 'Đánh giá download',
			'downloads.cancelledDownload' => 'Hủy download',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (tính hợp ${status})',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => 'Tải về ${file} - Click để hoàn thành',
			'downloads.partialDownloadClickToComplete' => 'Tải về - Click to complete',
			'downloads.deleting' => 'xóa...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Xóa ${title}... (${current} trong số ${total})',
			'downloads.queuedTooltip' => 'Quả',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'Đánh giá ${files}',
			'downloads.downloadingTooltip' => 'tải...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'Tải về ${files}',
			'downloads.noDownloadsTree' => 'Không tải xuống',
			'downloads.pauseAll' => 'All nghỉ ngơi',
			'downloads.resumeAll' => 'Tóm lại tất cả',
			'downloads.retryAll' => 'Quay lại tất cả',
			'downloads.retryFailed' => 'Retry thất bại Downloads',
			'downloads.deleteAll' => 'Xóa Hết',
			'downloads.selectVersion' => 'Chọn phiên bản',
			'downloads.allEpisodes' => 'Tất cả các tập',
			'downloads.unwatchedOnly' => 'Không chỉ quan sát',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Tiếp theo ${count} chưa được xem',
			'downloads.customAmount' => 'Số lượng tùy chỉnh...',
			'downloads.customAmountAny' => 'Số lượng (tất cả)',
			'downloads.randomEpisodes' => 'Ngẫu thuật episodes',
			'downloads.includeSpecials' => 'bao gồm đặc biệt',
			'downloads.howManyEpisodes' => 'Bao nhiêu sự kiện?',
			'downloads.invalidEpisodeCount' => 'Nhập một số tập hợp hợp lệ.',
			'downloads.keepSynced' => 'Giữ synchronized',
			'downloads.downloadOnce' => 'Download một lần',
			'downloads.keepNUnwatched' => ({required Object count}) => 'Giữ ${count} không được xem',
			'downloads.editSyncRule' => 'Quy tắc Edit Sync',
			'downloads.removeSyncRule' => 'Xóa quy tắc sync',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'Ngừng đồng bộ hóa "${title}"? các tập phim được tải xuống sẽ được giữ lại.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => 'Đừng đồng bộ hóa "${title}"',
			'downloads.deleteSyncRuleDownloads' => 'Cũng xóa các tải xuống liên quan',
			'downloads.deleteSyncRuleDownloadsDescription' => 'Tải về được sử dụng bởi một quy tắc đồng bộ hoặc hồ sơ khác sẽ được giữ lại.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Quy tắc đồng bộ được tạo — giữ ${count} các tập không được xem',
			'downloads.syncRuleUpdated' => 'Quy tắc Sync cập nhật',
			'downloads.syncRuleRemoved' => 'Quy tắc đồng bộ đã bị loại bỏ',
			'downloads.syncRuleAndDownloadsRemoved' => 'Quy tắc đồng bộ và các tải xuống liên quan đã bị xóa',
			'downloads.syncRuleCleanupBusy' => 'Các quy tắc đồng bộ hiện đang được cập nhật. thử lại một lần nữa.',
			'downloads.syncRuleCleanupUnavailable' => 'Các tải xuống liên quan không thể được xác định an toàn. nối lại máy chủ và thử lại, hoặc xóa quy tắc mà không xóa tải xuống.',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => 'Đồng bộ ${count} các tập mới cho ${title}',
			'downloads.syncNow' => 'Sync hiện tại',
			'downloads.downloadsUpToDate' => 'Tải xuống hiện tại',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => 'Sync complete · ${queued} queued, ${removed} đã được xóa',
			'downloads.activeSyncRules' => 'Quy tắc Sync',
			'downloads.reviewOrphanFiles' => 'Đánh giá Downloads Orphaned',
			'downloads.orphanReviewTitle' => 'Đánh giá Downloads Orphaned',
			'downloads.orphanReviewDescription' => 'Các tệp được nhãn hiệu này nằm trong các thư mục tải xuống được quản lý bởi ứng dụng mặc định của PlezyNG và không có bản ghi tải xuống hoặc nhiệm vụ hoạt động phù hợp.',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count} tập tin · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => 'xóa ${count} file',
			'downloads.orphanCleanupNone' => 'Không tìm thấy các file download orphaned',
			'downloads.orphanCleanupFailed' => 'PlezyNG không thể an toàn quét thư mục tải xuống được quản lý. không có tệp đã bị xóa.',
			'downloads.orphanCleanupChanged' => 'Danh sách tải xuống đã thay đổi trong quá trình xem xét. xem lại các tập tin trước khi làm sạch.',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => 'xóa ${count} các tệp mồ côi · ${size} miễn phí',
			'downloads.noSyncRules' => 'Không có quy tắc sync',
			'downloads.manageSyncRule' => 'Quản lý sync',
			'downloads.editEpisodeCount' => 'Số Episode',
			'downloads.editSyncFilter' => 'Bộ lọc Sync',
			'downloads.syncAllItems' => 'Tích hợp tất cả các mục',
			'downloads.syncUnwatchedItems' => 'Tích hợp các mục không được xem xét',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Máy chủ: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Sẵn có',
			'downloads.syncRuleOffline' => 'Ngoại tuyến',
			'downloads.syncRuleSignInRequired' => 'Nhập vào yêu cầu',
			'downloads.syncRuleAccessDenied' => 'Truy cập từ chối',
			'downloads.syncRuleNotAvailableForProfile' => 'Không sẵn dùng cho hồ sơ hiện tại',
			'downloads.syncRuleUnknownServer' => 'máy chủ không rõ',
			'downloads.syncRuleListCreated' => 'Quy tắc Sync được tạo ra',
			'downloads.backgroundWarning.bannerBlocked' => 'Tải xuống sẽ dừng lại khi bạn rời khỏi ứng dụng',
			'downloads.backgroundWarning.bannerDegraded' => 'Tải xuống nền có thể bị giới hạn',
			'downloads.backgroundWarning.bannerAction' => 'chi tiết',
			'downloads.backgroundWarning.sheetTitle' => 'Tải xuống nền bị chặn',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Tải xuống nền có thể bị giới hạn',
			'downloads.backgroundWarning.sheetIntro' => 'Android ngăn cản PlezyNG tải về đáng tin cậy trong nền.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Thiết bị của bạn đang giới hạn khi PlezyNG có thể tải về trong nền.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'Sử dụng nền của PlezyNG là hạn chế. thiết lập sử dụng pin hoặc nền của nó là "Không hạn chế".',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android đã đặt PlezyNG trong trạng thái đứng hạn chế. đặt sử dụng pin của nó lên "Không hạn chế".',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Thông báo tải xuống bị tắt, vì vậy tiến bộ và kiểm soát có thể không sẵn dùng.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Thông báo được tắt. trên Android 13 hoặc mới hơn, chúng được yêu cầu cho tải xuống nền dài.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Data Saver là trên, mà chặn tải xuống nền trên dữ liệu di động. tải xuống vẫn nên chạy trên Wi-Fi.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Tải về đã ngừng lại nhiều lần trong khi PlezyNG đang ở trong nền. kiểm tra cài đặt pin hoặc nền của PlezyNG.',
			'downloads.backgroundWarning.openSettings' => 'cài đặt mở',
			'downloads.backgroundWarning.stillNotWorking' => '- Hỗ trợ cụ thể thiết bị',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'Xem các bước cho thiết bị của bạn, hoặc gửi một sổ ghi chép từ Cài đặt › Xem sổ ghi chép nếu vấn đề tiếp tục.',
			'downloads.backgroundWarning.dialogTitle' => 'Download có thể không kết thúc',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'Download bất cứ điều gì',
			'downloads.backgroundWarning.dialogFixFirst' => 'Đặt điều này trước',
			'downloads.backgroundWarning.statusTile' => 'Background Downloads',
			'downloads.backgroundWarning.statusOk' => 'được phép chạy trong nền',
			'downloads.backgroundWarning.statusBlocked' => 'Chặn bởi hệ thống cài đặt',
			'downloads.backgroundWarning.statusDegraded' => 'Giới hạn bởi thiết lập hệ thống',
			'downloads.backgroundWarning.statusUnknown' => 'chưa kiểm tra',
			'downloads.backgroundWarning.settingsUnavailable' => 'Không thể mở cài đặt hệ thống trên thiết bị này',
			'downloads.backgroundWarning.linkUnavailable' => 'Không thể mở dontkillmyapp.com trên thiết bị này',
			'downloads.options' => 'Tải về tùy chọn',
			'downloads.groupings.library' => 'Thư viện',
			'downloads.groupings.collections' => 'Bộ Sưu Tập',
			'downloads.unknownLibrary' => 'Thư viện chưa biết',
			'downloads.unknownShow' => 'show chưa biết',
			'downloads.unknownSeason' => 'Mùa chưa biết',
			'downloads.unknownAlbum' => 'Album chưa biết',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} hoàn thành',
			'downloads.storageUsed' => ({required Object size}) => 'Lưu trữ sử dụng: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tải về', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} hiển thị', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} phim ảnh', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} album', ), 
			'downloads.errorFileNotFound' => 'file chưa tìm thấy (404)',
			'downloads.errorDownloadNotAllowed' => 'Tải xuống không được phép bởi máy chủ (403)',
			'downloads.errorDownloadFailed' => 'Download thất bại',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'Tải về thất bại: ${reason}',
			'downloads.convertingOnServer' => 'Chuyển đổi sang server...',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => 'Chuyển đổi trên máy chủ · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => 'Tải về thất bại (HTTP ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => 'Tiếp theo xử lý thất bại: ${reason}',
			'downloads.reasonFileNotSaved' => 'file không thể được lưu trên thiết bị này',
			'downloads.reasonCannotResume' => 'Phần tải xuống không thể được khôi phục',
			'downloads.reasonDeviceStorageFull' => 'Thiết bị này không được lưu trữ',
			'downloads.notificationDownloading' => 'tải...',
			'downloads.notificationComplete' => 'Download hoàn chỉnh',
			'downloads.notificationPaused' => 'Download nghỉ ngơi',
			'shaders.title' => 'Bộ đổ bóng',
			'shaders.noShaderDescription' => 'Không có video nâng cấp',
			'shaders.nvscalerDescription' => 'NVIDIA image scaling cho video sắc nét hơn',
			'shaders.artcnnVariantNeutral' => 'trung lập',
			'shaders.artcnnVariantDenoise' => 'Dinoza',
			'shaders.artcnnVariantDenoiseSharpen' => 'Đánh giá + Sharpen',
			'shaders.qualityFast' => 'nhanh chóng',
			'shaders.qualityHQ' => 'chất lượng cao',
			'shaders.mode' => 'Thời trang',
			'shaders.importShader' => 'nhập khẩu Shader',
			'shaders.customShaderDescription' => 'Tính năng GLSL Shader',
			'shaders.shaderImported' => 'Shader nhập khẩu',
			'shaders.shaderImportFailed' => 'Không nhập khẩu Shader',
			'shaders.deleteShader' => 'Xóa Shader',
			'shaders.deleteShaderConfirm' => ({required Object name}) => 'Xóa “${name}” ?',
			'companionRemote.title' => 'Điều khiển từ xa đi kèm',
			'companionRemote.connectedTo' => ({required Object name}) => 'Kết nối với ${name}',
			'companionRemote.unknownDevice' => 'Thiết bị chưa biết',
			'companionRemote.session.startingServer' => 'Bắt đầu máy chủ từ xa',
			'companionRemote.session.hostAddress' => 'Địa chỉ Host',
			'companionRemote.session.connected' => 'Kết nối',
			'companionRemote.session.serverRunning' => 'Remote Server hoạt động',
			'companionRemote.session.serverStopped' => 'Remote server bị dừng lại',
			'companionRemote.session.serverRunningDescription' => 'Các thiết bị di động trên mạng của bạn có thể kết nối với ứng dụng này',
			'companionRemote.session.serverStoppedDescription' => 'Bắt đầu máy chủ để cho phép các thiết bị di động kết nối',
			'companionRemote.session.usePhoneToControl' => 'Sử dụng thiết bị di động của bạn để kiểm soát ứng dụng này',
			'companionRemote.session.startServer' => 'Bắt đầu server',
			'companionRemote.session.stopServer' => 'Ngừng Server',
			'companionRemote.session.minimize' => 'giảm thiểu',
			'companionRemote.session.manualAddressHint' => 'Địa chỉ kết nối thủ công:',
			'companionRemote.pairing.discoveryDescription' => 'Các thiết bị PlezyNG với cùng tài khoản Plex xuất hiện tại đây',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Kết nối...',
			'companionRemote.pairing.searchingForDevices' => 'Tìm kiếm các thiết bị...',
			'companionRemote.pairing.noDevicesFound' => 'Không tìm thấy thiết bị trên mạng của bạn',
			'companionRemote.pairing.noDevicesHint' => 'Mở PlezyNG trên máy tính để bàn và sử dụng cùng Wi-Fi',
			'companionRemote.pairing.availableDevices' => 'Thiết bị có sẵn',
			'companionRemote.pairing.manualConnection' => 'Manual kết nối',
			'companionRemote.pairing.cryptoInitFailed' => 'Không thể bắt đầu kết nối an toàn. đăng nhập lên Plex đầu tiên.',
			'companionRemote.pairing.validationHostRequired' => 'Vui lòng nhập địa chỉ host',
			'companionRemote.pairing.validationHostFormat' => 'Định dạng phải là IP:port (ví dụ: 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Kết nối tạm thời: Sử dụng cùng một mạng trên cả hai thiết bị.',
			'companionRemote.pairing.sessionNotFound' => 'Thiết bị không được tìm thấy. đảm bảo PlezyNG đang chạy trên máy chủ.',
			'companionRemote.pairing.authFailed' => 'Cả hai thiết bị đều cần cùng một tài khoản Plex.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Không kết nối: ${error}',
			'companionRemote.pairing.codeTitle' => 'Cặp code',
			'companionRemote.pairing.codeDescription' => 'Nhập mã được hiển thị trong Companion Remote trên thiết bị chủ. Cả hai thiết bị phải sử dụng một phiên bản hỗ trợ cặp an toàn.',
			'companionRemote.pairing.codeInvalid' => 'Nhập tất cả 32 chữ cái và số từ mã host.',
			'companionRemote.pairing.updateRequired' => 'Cập nhật cả hai thiết bị đến một phiên bản hỗ trợ cặp an toàn.',
			'companionRemote.pairing.hostDescription' => 'Nhập mã này một lần trên mỗi remote. giữ nó riêng tư: nó cho phép kiểm soát hồ sơ này.',
			'companionRemote.pairing.resetCode' => 'Đặt lại mã cặp',
			'companionRemote.pairing.resetDescription' => 'Tắt tất cả các từ xa và tạo một mã mới. mỗi từ xa sẽ cần phải cặp lại.',
			'companionRemote.remote.disconnectConfirm' => 'Bạn muốn tắt kết nối từ phiên từ xa?',
			'companionRemote.remote.reconnecting' => 'Kết nối lại...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Thử ${current} của 5',
			'companionRemote.remote.retryNow' => 'Trở lại bây giờ',
			'companionRemote.remote.tabRemote' => 'Khoảng cách',
			'companionRemote.remote.tabPlay' => 'Phát',
			'companionRemote.remote.tabMore' => 'Thêm',
			'companionRemote.remote.menu' => 'Menu',
			'companionRemote.remote.tabNavigation' => 'Tab Navigation Đánh giá',
			'companionRemote.remote.tabDiscover' => 'Khám phá',
			'companionRemote.remote.tabLibraries' => 'Thư viện',
			'companionRemote.remote.tabSearch' => 'Tìm kiếm',
			'companionRemote.remote.tabDownloads' => 'Nội dung tải xuống',
			'companionRemote.remote.tabSettings' => 'Cài đặt',
			'companionRemote.remote.previous' => 'Trước',
			'companionRemote.remote.playPause' => 'Chơi / Pause',
			'companionRemote.remote.next' => 'Kế tiếp',
			'companionRemote.remote.seekBack' => 'Tìm lại',
			'companionRemote.remote.stop' => 'Ngưng',
			'companionRemote.remote.seekForward' => 'Tìm kiếm FWD',
			'companionRemote.remote.volume' => 'Số lượng',
			'companionRemote.remote.volumeDown' => 'Xuống',
			'companionRemote.remote.volumeUp' => 'Lên',
			'companionRemote.remote.fullscreen' => 'Toàn màn hình',
			'companionRemote.remote.subtitles' => 'Phụ đề',
			'companionRemote.remote.audio' => 'Âm thanh',
			'companionRemote.remote.searchHint' => 'Tìm kiếm trên desktop',
			'companionRemote.errors.noNetworkInterface' => 'Không tìm thấy giao diện mạng',
			'companionRemote.errors.authenticationFailed' => 'xác thực thất bại',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'Không khởi động máy chủ từ xa: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'Không gửi lệnh từ xa: ${error}',
			'companionRemote.errors.joinTimedOut' => 'Thời gian tham gia phiên',
			'companionRemote.errors.failedToConnectAnyAddress' => 'Không kết nối với bất kỳ địa chỉ nào',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'Kết nối bị mất sau ${attempts} nỗ lực',
			'companionRemote.errors.connectionLost' => 'Kết nối mất',
			'companionRemote.closedBeforeAuth' => 'Kết nối đóng cửa trước khi xác thực',
			'videoSettings.playbackSpeed' => 'Tốc Độ Phát',
			'videoSettings.normalSpeed' => 'Bình thường',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Động tác (${duration})',
			'videoSettings.zoom' => 'Thu phóng',
			'videoSettings.sleepTimer' => 'Giấc ngủ Timer',
			'videoSettings.audioSync' => 'Âm thanh Sync',
			'videoSettings.subtitleSync' => 'Chủ đề Sync',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'HDR không có sẵn ở đây - máy tính bảng hoặc video output này không thể mang nó.',
			'videoSettings.hdrToneMapping' => 'HDR Tone Bản đồ',
			'videoSettings.hdrToneMappingCompositor' => 'Tác giả',
			'videoSettings.hdrToneMappingCompositorDescription' => 'Đi qua các metadata HDR của nguồn và để cho bản đồ máy tính để bàn.',
			'videoSettings.hdrToneMappingPlayer' => 'Trình Phát',
			'videoSettings.hdrToneMappingPlayerDescription' => 'Bản đồ cho độ sáng cao của màn hình trong người chơi, sau đó nói với nhà soạn nhạc kết quả.',
			'videoSettings.hdrToneMappingFailed' => 'Không thể thay đổi bản đồ âm thanh HDR - chế độ trước vẫn hoạt động.',
			'videoSettings.audioOutput' => 'Audio output xuất',
			'videoSettings.videoTrack' => 'Bản video',
			'videoSettings.videoTrackDescription' => 'Chọn luồng video cần hiển thị. Có sẵn khi phát bằng MPV nếu tệp có các bản video thay thế.',
			'videoSettings.videoTrackDefault' => 'Mặc định',
			'videoSettings.videoTrackUnavailable' => 'Không có bản video thay thế nào.',
			'videoSettings.videoTrackFailed' => 'Không thể đổi bản video.',
			'videoSettings.videoTrackNumber' => ({required Object id}) => 'Bản ${id}',
			'videoSettings.performanceOverlay' => 'Hiệu suất Overlay',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'xung quanh',
			'videoSettings.audioOutputSpatial' => 'âm thanh không gian',
			'videoSettings.audioOutputStereo' => 'Âm Thanh Nổi',
			'videoSettings.audioEqualizer' => 'âm thanh equalizer',
			'videoSettings.audioEqualizerDescription' => '10-band equalizer cho MPVCác bộ lọc âm thanh sử dụng âm thanh giải mã và tắt passthrough.',
			'videoSettings.audioEqualizerFlat' => 'Đơn giản',
			'videoSettings.audioEqualizerActive' => 'Tùy chọn',
			'videoSettings.audioEqualizerSaveFailed' => 'Không thể tiết kiệm các thiết lập Audio Equalizer.',
			'videoSettings.audioEffectsDescription' => 'Hiệu ứng sử dụng âm thanh giải mã, do đó passthrough xoay. không gian phòng và mở rộng stereo phụ thuộc vào MPV xây dựng và theo dõi.',
			'videoSettings.audioStereoWidth' => 'Stereo mở rộng',
			'videoSettings.audioSpatializer' => 'Môi trường phòng',
			'videoSettings.audioSpatializerDescription' => 'Thêm phản ánh phòng yên tĩnh.',
			'videoSettings.audioPitch' => 'Pitch thay đổi',
			'videoSettings.audioPitchDescription' => 'Thay đổi vị trí mà không thay đổi tốc độ. MPV xây dựng phải bao gồm Rubber Band.',
			'videoSettings.audioEffectUnavailable' => 'Hiệu ứng này không có sẵn cho con đường này hoặc MPV xây dựng',
			'videoSettings.backgroundVideoAudio' => 'Video âm thanh nền',
			'videoSettings.backgroundVideoAudioDescription' => 'Giữ video chơi âm thanh khi bạn rời chơi; hình ảnh được ẩn cho đến khi bạn trở về. Android sử dụng thông báo phát lại phương tiện truyền thông.',
			'videoSettings.audioNormalization' => 'bình thường tiếng ồn',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'Xóa âm thanh đến PCM; passthrough đang tắt trong khi điều này đang',
			'performanceOverlay.color' => 'Màu sắc',
			'performanceOverlay.performance' => 'Hiệu suất',
			'performanceOverlay.buffer' => 'Bộ đệm',
			'performanceOverlay.app' => 'Ứng Dụng',
			'performanceOverlay.decoder' => 'Bộ giải mã',
			'performanceOverlay.rawDecoder' => 'Mã Decoder',
			'performanceOverlay.tunneling' => 'đường hầm',
			'performanceOverlay.passthrough' => 'Truyền thẳng',
			'performanceOverlay.aspect' => 'Khía cạnh',
			'performanceOverlay.rotation' => 'Xoay',
			'performanceOverlay.dvSource' => 'Nguồn DV',
			'performanceOverlay.dvPath' => 'Đường DV',
			'performanceOverlay.dvRouteDecoder' => 'Dolby Vision Bộ xử lý',
			'performanceOverlay.dvRouteDecoderP81' => 'Bộ giải mã Dolby Vision (P7→8.1)',
			'performanceOverlay.dvRouteBaseLayer' => 'Lớp cơ sở',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'HDR10 lớp cơ sở',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'HLG cơ sở lớp',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'SDR cơ sở',
			'performanceOverlay.dvRouteReshaped' => 'RPU tái tạo (gpu-next)',
			'performanceOverlay.dvRouteFelGraphActive' => 'P7 FEL biểu đồ thí nghiệm (không đủ điều kiện)',
			'performanceOverlay.p7Conversion' => 'Chuyển đổi P7',
			'performanceOverlay.sampleRate' => 'Tỷ lệ mẫu',
			'performanceOverlay.pixelFormat' => 'Đánh giá Pixel Fmt',
			'performanceOverlay.hwFormat' => 'Định dạng phần cứng',
			'performanceOverlay.matrix' => 'Ma trận',
			'performanceOverlay.primaries' => 'nguyên nhân',
			'performanceOverlay.transfer' => 'Chuyển đổi',
			'performanceOverlay.renderFps' => 'Đánh giá FPS',
			'performanceOverlay.displayFps' => 'Hiển thị FPS',
			'performanceOverlay.avSync' => 'A/V đồng bộ',
			'performanceOverlay.dropped' => 'bị rơi',
			'performanceOverlay.dvRpus' => 'DV RPU',
			'performanceOverlay.dvRpuAverage' => 'Đánh giá RPU AVG',
			'performanceOverlay.dvSampleAverage' => 'Đánh giá DV Sample Avg',
			'performanceOverlay.maxLuma' => 'Độ chói tối đa',
			'performanceOverlay.minLuma' => 'Lúa Lúa',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Cache sử dụng',
			'performanceOverlay.cacheLimit' => 'Cache giới hạn',
			'performanceOverlay.speed' => 'Tốc độ',
			'performanceOverlay.player' => 'Trình Phát',
			'performanceOverlay.playMethod' => 'Cách Phát',
			'performanceOverlay.memory' => 'ký ức',
			'performanceOverlay.uiFps' => 'Đánh giá FPS',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android HW',
			'performanceOverlay.decoderNvidiaHw' => 'Đánh giá NVIDIA',
			'performanceOverlay.decoderQualcommHw' => 'Đánh giá Qualcomm HW',
			'performanceOverlay.decoderMediatekHw' => 'Thông tin HW',
			'performanceOverlay.decoderExynosHw' => 'Đánh giá HW',
			'performanceOverlay.decoderSoftware' => 'Phần mềm',
			'performanceOverlay.decoderHardware' => 'Phần cứng',
			'performanceOverlay.tunnelingActive' => 'hoạt động',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted} (${failures} thất bại)',
			'externalPlayer.title' => 'Người chơi bên ngoài',
			'externalPlayer.useExternalPlayer' => 'Sử dụng Player External',
			'externalPlayer.useExternalPlayerDescription' => 'Mở video trong ứng dụng khác',
			'externalPlayer.selectPlayer' => 'Chọn Player',
			'externalPlayer.customPlayers' => 'Người chơi Custom',
			'externalPlayer.systemDefault' => 'Hệ thống default',
			'externalPlayer.addCustomPlayer' => 'Thêm Custom Player',
			'externalPlayer.playerName' => 'Tên cầu thủ',
			'externalPlayer.playerNameHint' => 'Cầu thủ của tôi',
			'externalPlayer.playerCommand' => 'Lệnh',
			'externalPlayer.playerPackage' => 'gói tên',
			'externalPlayer.playerUrlScheme' => 'Hệ thống URL',
			'externalPlayer.off' => 'Tắt',
			'externalPlayer.launchFailed' => 'Không mở cầu thủ bên ngoài',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} không được cài đặt',
			'externalPlayer.playInExternalPlayer' => 'Chơi trong người chơi bên ngoài',
			'externalPlayer.description' => 'Chọn một ứng dụng khác để mở video trong. Người chơi có sẵn phụ thuộc vào thiết bị của bạn và các ứng dụng được cài đặt.',
			'externalPlayer.systemDefaultDescription' => 'Hãy để hệ điều hành mở video với ứng dụng mặc định của nó.',
			'externalPlayer.playerOptionDescription' => ({required Object player}) => 'Mở video với ${player}.',
			'externalPlayer.playerNameDescription' => 'Nhãn được hiển thị trong danh sách người chơi.',
			'externalPlayer.playerPackageDescription' => 'Nhập tên gói Android của ứng dụng người chơi, chẳng hạn như com.example.player.',
			'externalPlayer.playerCommandDescription' => 'Nhập lệnh người chơi cài đặt hoặc con đường thực hiện cho thiết bị này.',
			'externalPlayer.playerUrlSchemeDescription' => 'Nhập biểu đồ URL và mẫu URL tùy chọn được sử dụng để khởi động người chơi.',
			'metadataEdit.editMetadata' => 'Sửa',
			'metadataEdit.screenTitle' => 'Sửa dữ liệu mô tả',
			'metadataEdit.basicInfo' => 'Thông tin cơ bản',
			'metadataEdit.artwork' => 'Nghệ thuật',
			'metadataEdit.advancedSettings' => 'Cài đặt Advanced',
			'metadataEdit.title' => 'Tiêu đề',
			'metadataEdit.sortTitle' => 'Sắp xếp tiêu đề',
			'metadataEdit.originalTitle' => 'Tiêu đề gốc',
			'metadataEdit.releaseDate' => 'Ngày phát hành',
			'metadataEdit.contentRating' => 'Content Đánh giá',
			'metadataEdit.studio' => 'Hãng phim',
			'metadataEdit.tagline' => 'Giới thiệu',
			'metadataEdit.summary' => 'Tổng hợp',
			'metadataEdit.poster' => 'Áp phích',
			'metadataEdit.background' => 'nền',
			'metadataEdit.logo' => 'Biểu trưng',
			'metadataEdit.squareArt' => 'Quảng trường Art',
			'metadataEdit.selectPoster' => 'Chọn Poster',
			'metadataEdit.selectBackground' => 'Chọn nền',
			'metadataEdit.selectLogo' => 'Chọn logo',
			'metadataEdit.selectSquareArt' => 'Chọn Square Art',
			'metadataEdit.fromUrl' => 'Từ URL',
			'metadataEdit.uploadFile' => 'tải file',
			'metadataEdit.enterImageUrl' => 'Nhập hình ảnh URL',
			'metadataEdit.imageUrl' => 'Ảnh URL',
			'metadataEdit.metadataUpdated' => 'Metadata cập nhật',
			'metadataEdit.metadataUpdateFailed' => 'Không cập nhật metadata',
			'metadataEdit.artworkUpdated' => 'Artwork cập nhật',
			_ => null,
		} ?? switch (path) {
			'metadataEdit.artworkUpdateFailed' => 'Không cập nhật tác phẩm nghệ thuật',
			'metadataEdit.noArtworkAvailable' => 'Không có tác phẩm nghệ thuật',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Tùy chọn nghệ thuật ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Tùy chọn Artwork ${index}, được chọn',
			'metadataEdit.notSet' => 'Không đặt',
			'metadataEdit.libraryDefault' => 'Thư viện thất bại',
			'metadataEdit.accountDefault' => 'Tài khoản default',
			'metadataEdit.seriesDefault' => 'Lập trình default',
			'metadataEdit.episodeSorting' => 'Episode Đánh giá',
			'metadataEdit.oldestFirst' => 'Lớn nhất đầu tiên',
			'metadataEdit.newestFirst' => 'mới nhất đầu tiên',
			'metadataEdit.keep' => 'giữ',
			'metadataEdit.allEpisodes' => 'Tất cả các tập',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} các tập cuối cùng',
			'metadataEdit.latestEpisode' => 'episode mới nhất',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Các sự kiện đã được thêm vào trong những ngày gần đây ${count}',
			'metadataEdit.deleteAfterPlaying' => 'Xóa các tập sau khi chơi',
			'metadataEdit.never' => 'Không Bao Giờ',
			'metadataEdit.afterADay' => 'Sau một ngày',
			'metadataEdit.afterAWeek' => 'Sau một tuần',
			'metadataEdit.afterAMonth' => 'Sau một tháng',
			'metadataEdit.onNextRefresh' => 'Next Cung cấp mới',
			'metadataEdit.seasons' => 'Phần',
			'metadataEdit.show' => 'show show',
			'metadataEdit.hide' => 'Ẩn',
			'metadataEdit.episodeOrdering' => 'Episode Đặt hàng',
			'metadataEdit.tmdbAiring' => 'Cơ sở dữ liệu phim (Aired)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (theo thứ tự phát sóng)',
			'metadataEdit.tvdbAbsolute' => 'TTVDB (tự nhiên)',
			'metadataEdit.metadataLanguage' => 'Metadata ngôn ngữ',
			'metadataEdit.useOriginalTitle' => 'Sử dụng tiêu đề gốc',
			'metadataEdit.preferredAudioLanguage' => 'Ngôn ngữ thoại ưa thích',
			'metadataEdit.preferredSubtitleLanguage' => 'Ngôn ngữ phụ đề ưu tiên',
			'metadataEdit.subtitleMode' => 'Tự chọn Subtitle Mode',
			'metadataEdit.manuallySelected' => 'Chọn thủ công',
			'metadataEdit.shownWithForeignAudio' => 'Hiển thị bằng âm thanh nước ngoài',
			'metadataEdit.alwaysEnabled' => 'Luôn có khả năng',
			'metadataEdit.tags' => 'Thẻ',
			'metadataEdit.addTag' => 'thêm tag',
			'metadataEdit.genre' => 'Thể loại',
			'metadataEdit.director' => 'Đạo Diễn',
			'metadataEdit.writer' => 'Người viết',
			'metadataEdit.producer' => 'Nhà sản xuất',
			'metadataEdit.country' => 'đất nước',
			'metadataEdit.collection' => 'Bộ Sưu Tập',
			'metadataEdit.label' => 'Nhãn hiệu',
			'metadataEdit.quickTag' => 'Tag nhanh...',
			'matchScreen.match' => 'trận đấu...',
			'matchScreen.fixMatch' => 'Đặt trận đấu...',
			'matchScreen.unmatch' => 'Hủy khớp',
			'matchScreen.unmatchConfirm' => 'Đánh giá trận đấu này? Plex đối xử với nó như là không đụng độ cho đến khi hoàn thành.',
			'matchScreen.unmatchSuccess' => 'mục không phù hợp',
			'matchScreen.unmatchFailed' => 'thất bại trong Unmatch item',
			'matchScreen.matchApplied' => 'Match ứng dụng',
			'matchScreen.matchFailed' => 'Không thực hiện trận đấu',
			'matchScreen.titleHint' => 'Tiêu đề',
			'matchScreen.yearHint' => 'Năm',
			'matchScreen.search' => 'Tìm kiếm',
			'matchScreen.noMatchesFound' => 'Không tìm thấy trận đấu',
			'serverTasks.title' => 'Server nhiệm vụ',
			'serverTasks.failedToLoad' => 'Không thể tải nhiệm vụ',
			'serverTasks.noTasks' => 'Không có nhiệm vụ chạy',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Kết nối',
			'trakt.connectedAs' => ({required Object username}) => 'Kết nối với @${username}',
			'trakt.disconnectConfirm' => 'Tắt tài khoản Trakt?',
			'trakt.disconnectConfirmBody' => 'PlezyNG sẽ ngừng gửi các sự kiện đến Trakt. Bạn có thể kết nối lại bất cứ lúc nào.',
			'trakt.scrobble' => 'Thời gian thực scrobbling',
			'trakt.scrobbleDescription' => 'Gửi game, nghỉ ngơi, và dừng các sự kiện đến Trakt trong khi chơi lại.',
			'trakt.watchedSync' => 'Sync theo dõi trạng thái',
			'trakt.watchedSyncDescription' => 'Khi bạn đánh dấu các mục như được xem ở PlezyNG, chúng cũng được đánh dấu như được xem ở Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Kết nối Seerr',
			'seerr.serverUrl' => 'URL máy chủ',
			'seerr.serverUrlHelper' => 'Địa chỉ của đơn vị Seerr của bạn',
			'seerr.checkServer' => 'tiếp tục',
			'seerr.signInWithJellyfin' => 'Đăng ký với Jellyfin',
			'seerr.signInWithEmby' => 'Đăng ký với Emby',
			'seerr.signInWithLocal' => 'Sử dụng tài khoản địa phương',
			'seerr.email' => 'Email',
			'seerr.noSignInMethods' => 'Ví dụ này Seerr không cung cấp các phương pháp đăng nhập PlezyNG hỗ trợ.',
			'seerr.instance' => 'Ấn Độ',
			'seerr.disconnectConfirm' => 'Cắt kết nối Seerr?',
			'seerr.disconnectConfirmBody' => 'PlezyNG sẽ quên ví dụ này Seerr. nối lại bất cứ lúc nào.',
			'seerr.request' => 'yêu cầu',
			'seerr.request4k' => 'yêu cầu 4K',
			'seerr.seasons' => 'Phần',
			'seerr.allSeasons' => 'Tất cả mùa',
			'seerr.advancedOptions' => 'Nâng cao',
			'seerr.destinationServer' => 'Destination Server Khách sạn',
			'seerr.qualityProfile' => 'Hồ sơ chất lượng',
			'seerr.rootFolder' => 'Root thư mục',
			'seerr.languageProfile' => 'ngôn ngữ profile',
			'seerr.tags' => 'Thẻ',
			'seerr.noTags' => 'Không tags',
			'seerr.defaultOption' => ({required Object name}) => '${name} (Điều mặc định)',
			'seerr.animeNote' => 'Bộ phim này là anime.',
			'seerr.requestSubmitted' => 'Yêu cầu gửi',
			'seerr.requestFailed' => ({required Object error}) => 'Đề nghị thất bại: ${error}',
			'seerr.requestsLoadFailed' => 'Không thể tải các tùy chọn yêu cầu',
			'seerr.nothingToRequest' => 'Mọi thứ đều có sẵn hoặc được yêu cầu.',
			'seerr.statusAvailable' => 'Sẵn có',
			'seerr.statusPartiallyAvailable' => 'Phần có sẵn',
			'seerr.statusRequested' => 'yêu cầu',
			'seerr.statusProcessing' => 'xử lý',
			'seerr.statusBlocklisted' => 'Khám phá',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => 'Không thể đạt ${url}: ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => 'Không có trường hợp Seerr tại ${url} (HTTP ${status})',
			'seerr.behindAuthProxy' => 'Một proxy ngược xác thực (SSO hoặc HTTP auth) trả lời thay vì Seerr. PlezyNG không thể đăng ký thông qua nó: để Seerr /api/v1 đường đi qua proxy cho ứng dụng này, hoặc sử dụng một địa chỉ tiếp cận Seerr trực tiếp.',
			'seerr.invalidUrl' => 'Nhập địa chỉ máy chủ như https://seerr.example.com',
			'seerr.quickConnectUnsupported' => 'Ví dụ Seerr này không hỗ trợ Quick Connect. nó cần Seerr 3.4 hoặc mới hơn.',
			'seerr.notInitialized' => 'Ví dụ này Seerr không hoàn thành cài đặt chạy đầu tiên',
			'seerr.noPlexTokenForReauth' => 'Số token Plex có sẵn để đăng ký lại',
			'seerr.noStoredCredentials' => 'Không có thông tin đăng nhập đã lưu để đăng nhập lại',
			'seerr.signInRejected' => 'Sign-in bị từ chối',
			'seerr.noSessionCookie' => 'Seerr không phát hành cookie session',
			'seerr.freshCookieRejected' => 'Seerr từ chối cookie phiên mới',
			'seerr.noUserInformation' => 'Seerr không trả lại thông tin người dùng',
			'seerr.sessionRejectedAfterReauth' => 'Cuộc họp đã bị từ chối sau khi ký lại',
			'seerr.permissionDenied' => 'Seerr từ chối hành động này: Tài khoản của bạn không còn được phép yêu cầu',
			'seerr.permissionRevoked' => 'Bạn không còn được phép yêu cầu điều này',
			'services.title' => 'Dịch vụ',
			'services.hubSubtitle' => 'Sync theo dõi tiến bộ và yêu cầu các tiêu đề mới.',
			'services.integrations' => 'Integration',
			'services.notConnected' => 'Không liên kết',
			'services.connectedAs' => ({required Object username}) => 'Kết nối với @${username}',
			'services.scrobble' => 'Theo dõi tiến bộ tự động',
			'services.scrobbleDescription' => 'Cập nhật danh sách của bạn khi bạn hoàn thành một tập hoặc phim.',
			'services.disconnectConfirm' => ({required Object service}) => 'Tắt kết nối ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'PlezyNG sẽ ngừng cập nhật ${service}. Liên hệ lại bất cứ lúc nào.',
			'services.connectFailed' => ({required Object service}) => 'Không thể kết nối với ${service}.Cần thử lại.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'Kết nối Simkl',
			'services.simklReconnect.subtitle' => 'Simkl là loại bỏ phương pháp đăng nhập sử dụng kết nối này. tái kết nối mở simkl.com để chấp thuận PlezyNG — PlezyNG không bao giờ thấy mật khẩu của bạn. lịch sử đồng hồ của bạn vẫn ở trên Simkl.',
			'services.deviceCode.title' => ({required Object service}) => 'Chạy PlezyNG trên ${service}',
			'services.deviceCode.instructions' => 'Kiểm tra mã QR, hoặc truy cập địa chỉ dưới đây và nhập mã này:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Mở ${service} để kích hoạt',
			'services.deviceCode.copyCode' => 'copy code kích hoạt',
			'services.deviceCode.waitingForAuthorization' => 'Đang chờ sự cho phép...',
			'services.deviceCode.codeCopied' => 'Mã copy',
			'services.oauthProxy.title' => ({required Object service}) => 'Đăng ký tại ${service}',
			'services.oauthProxy.body' => 'Scan mã QR này hoặc mở URL trên bất kỳ thiết bị nào.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Mở ${service} để đăng ký',
			'services.pendingAuth.copyUrl' => 'Bản sao sign-in URL',
			'services.pendingAuth.urlCopied' => 'URL sao chép',
			'services.libraryFilter.title' => 'Thư viện Filter',
			'services.libraryFilter.subtitleAllSyncing' => 'Tích hợp tất cả các thư viện',
			'services.libraryFilter.subtitleNoneSyncing' => 'Không synchronize gì',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} bị chặn',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} được phép',
			'services.libraryFilter.mode' => 'Phương pháp lọc',
			'services.libraryFilter.modeBlacklist' => 'Danh sách đen',
			'services.libraryFilter.modeWhitelist' => 'Danh sách trắng',
			'services.libraryFilter.modeHintBlacklist' => 'Đồng bộ tất cả các thư viện ngoại trừ những thư viện được kiểm tra dưới đây.',
			'services.libraryFilter.modeHintWhitelist' => 'Đồng bộ chỉ các thư viện được kiểm tra dưới đây.',
			'services.libraryFilter.libraries' => 'Thư viện',
			'services.libraryFilter.noLibraries' => 'Không có thư viện',
			'services.libraryFilter.modeDescription' => 'Chọn xem các thư viện được kiểm tra có bị chặn khỏi đồng bộ hoặc là thư viện duy nhất đồng bộ.',
			'services.seerrDescription' => 'Kết nối với Seerr hoặc Overseerr để tìm kiếm tiêu đề và gửi yêu cầu phương tiện truyền thông.',
			'services.trackerDescriptions.trakt' => 'Đồng bộ xem các tập và phim với tài khoản Trakt của bạn.',
			'services.trackerDescriptions.mal' => 'Đồng bộ danh sách anime và xem tiến trình với MyAnimeList.',
			'services.trackerDescriptions.anilist' => 'Đồng bộ danh sách anime và xem tiến bộ với AniList.',
			'services.trackerDescriptions.simkl' => 'Sync xem phim, chương trình truyền hình và anime với Simkl.',
			'services.trackerDescriptions.mdblist' => 'Hiển thị xếp hạng và danh sách MDBList trong khuyến nghị và Khám phá.',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => 'Thêm máy chủ ${product}',
			'addServer.serverUrls' => 'Server URL của bạn',
			'addServer.serverUrlsHelper' => 'Nhiều URL được cho phép, tách biệt bởi commas.',
			'addServer.findServer' => 'tìm server',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'Tìm kiếm các máy chủ địa phương ${product} ...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'Địa phương ${product} máy chủ',
			'addServer.username' => 'Tên đăng nhập',
			'addServer.password' => 'Mật Khẩu',
			'addServer.signIn' => 'Đăng nhập',
			'addServer.change' => 'Thay đổi',
			'addServer.required' => 'cần thiết',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Không thể truy cập máy chủ: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Đăng ký thất bại: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect thất bại: ${error}',
			'addServer.addPlexTitle' => 'Đăng ký với Plex',
			'addServer.pinExpired' => 'PIN đã hết hạn trước khi đăng nhập. xin vui lòng thử lại.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Không đăng ký tài khoản: ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => 'Nhập URL máy chủ ${product} của bạn',
			'addServer.addConnectionTitle' => 'thêm liên kết',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Thêm vào ${name}',
			'addServer.signInWithPlexCard' => 'Đăng ký với Plex',
			'addServer.signInWithPlexCardSubtitle' => 'Tùy chọn thiết bị này.Share server được thêm vào.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Tùy chọn tài khoản Plex. người dùng nhà trở thành hồ sơ.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => 'Kết nối với ${product}',
			'addServer.connectToMediaBrowserCardSubtitle' => 'Nhập URL, tên người dùng và mật khẩu máy chủ của bạn.',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => 'Đăng nhập vào máy chủ của bạn ${product}. kết nối với ${name}.',
			'addServer.borrowFromAnotherProfile' => 'Loan từ một hồ sơ khác',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Sử dụng lại kết nối của hồ sơ khác. hồ sơ được bảo vệ bằng PIN đòi hỏi một PIN.',
			'addServer.invalidCredentials' => 'Tên người dùng hoặc mật khẩu không hợp lệ',
			'addServer.authResponseNotJson' => 'Trả lời xác thực không đúng JSON',
			'addServer.authResponseIncomplete' => 'Trả lời đăng nhập từ máy chủ là không đầy đủ',
			'addServer.quickConnectRejected' => 'Quick Connect đã bị từ chối bởi máy chủ',
			'addServer.quickConnectNotJson' => 'Câu trả lời Quick Connect không đúng JSON',
			'addServer.quickConnectMissingFields' => 'Câu trả lời Quick Connect thiếu mã hoặc bí mật',
			'addServer.quickConnectPollRejected' => 'Quick Connect truy vấn đã bị từ chối bởi máy chủ',
			'addServer.serverTimedOut' => 'Server không trả lời kịp thời',
			'addServer.responseNotJson' => 'Trả lời máy chủ không đúng JSON',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'Câu trả lời là thiếu một ID hoặc tên máy chủ - đây là máy chủ ${product}?',
			'addServer.probeFailed' => ({required Object error}) => 'Không thể truy cập máy chủ: ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => 'Nhập ít nhất một URL máy chủ ${product}',
			'addServer.noReachableServer' => ({required Object product}) => 'Không tìm thấy máy chủ ${product} có thể truy cập',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'Các URL này chỉ đến các máy chủ khác nhau ${product}',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'URL này không phù hợp với máy chủ ${product}',
			'addServer.redirectUnsupported' => 'Server được chuyển hướng sang URL không được hỗ trợ',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'Server được chuyển hướng sang một host khác. nhập URL cuối cùng ${product} trực tiếp.',
			'addServer.redirectInsecure' => 'Server chuyển hướng từ HTTPS đến một URL không an toàn',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'Server được chuyển hướng sang một URL không được hỗ trợ. nhập URL cuối cùng ${product} trực tiếp.',
			'addServer.directPlexServerUrl' => 'Plex URL máy chủ',
			'addServer.directPlexServerUrlHelper' => 'Nhập IP và cổng địa phương của máy chủ truyền thông Plex của bạn.',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex Token (tùy chọn)',
			'addServer.plexTokenHelper' => 'Hãy để lại trống nếu truy cập mà không có auth được cho phép trên máy chủ này.',
			'addServer.plexTokenRequired' => 'Xin vui lòng nhập token Plex của bạn (X-Plex-Token).',
			'addServer.connectDirectPlexCard' => 'Plex Media Server (Thông tin trực tiếp / địa phương)',
			'addServer.connectDirectPlexCardSubtitle' => 'Kết nối trực tiếp bằng cách sử dụng địa phương IP hoặc URL mà không có tài khoản plex.tv.',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => 'Kết nối trực tiếp bằng cách sử dụng địa phương IP hoặc URL. Kết nối đến ${name}.',
			'addServer.insecureTitle' => 'Kết nối không mã hóa',
			'addServer.insecureDescription' => ({required Object url}) => '${url} sử dụng HTTP. Người khác trên mạng có thể đọc hoặc thay đổi mật khẩu, mã thông báo và nội dung của bạn. Hãy dùng HTTPS nếu có. Chỉ tiếp tục nếu bạn tin tưởng mạng này và chấp nhận rủi ro.',
			'addServer.allowHttp' => 'Cho phép HTTP',
			'addServer.httpsRequired' => 'Sử dụng HTTPS hoặc rõ ràng cho phép kết nối không mã hóa.',
			'cast.chooseDevice' => 'Truyền đến thiết bị',
			'cast.searching' => 'Tìm kiếm các thiết bị Cast...',
			'cast.connectedTo' => ({required Object device}) => 'Kết nối với ${device}',
			'cast.device' => 'Thiết bị truyền',
			'cast.readyToCast' => 'Sẵn sàng truyền',
			'cast.subtitle' => 'Phụ đề',
			'cast.serverNotAvailable' => 'Server phương tiện truyền thông không sẵn dùng.',
			'cast.stopCasting' => 'Dừng truyền',
			'cast.castToDevice' => 'Truyền đến thiết bị',
			'cast.noEpisodeAvailable' => 'Không có tập nào có sẵn để phát.',
			'cast.startFailed' => 'Không thể bắt đầu casting. kiểm tra máy chủ và thử lại.',
			'automation.noActivePlayback' => 'Không có phiên video hoạt động để kiểm soát.',
			'notifications.newEpisodeTitle' => 'episode mới',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appAccess.title' => 'Cố gắng mọi tính năng miễn phí trong 7 ngày',
			'appAccess.description' => 'Bắt đầu một cuộc thử nghiệm 7 ngày với quyền truy cập đầy đủ vào mỗi tính năng PlezyNG. không có phí trong cuộc thử nghiệm và không có đăng ký. sau khi thử nghiệm, một mua hàng suốt đời tại giá của cửa hàng của bạn sẽ mở khóa PlezyNG suốt đời.',
			'appAccess.trialEndedDescription' => 'Khóa tất cả các tính năng trong PlezyNG cho đời với một mua tại giá của cửa hàng của bạn.',
			'appAccess.startTrial' => 'Bắt đầu bài kiểm tra miễn phí 7 ngày',
			'appAccess.trialActive' => 'Thử nghiệm đầy đủ 7 ngày của bạn đang hoạt động.',
			'appAccess.trialEnded' => 'Cuộc thi 7 ngày đã kết thúc',
			'appAccess.trialStartFailed' => 'Tôi không thể tiết kiệm thử nghiệm trên thiết bị này. xin vui lòng thử lại.',
			'appAccess.lifetimeTitle' => 'PlezyNG mở khóa suốt đời',
			'appAccess.lifetimeBody' => 'Cảm ơn bạn! bạn có quyền truy cập suốt đời cho mỗi tính năng PlezyNG.',
			'appAccess.manageTitle' => 'PlezyNG Thời gian truy cập',
			'appAccess.manageDescription' => 'Cố gắng mỗi tính năng miễn phí trong 7 ngày, sau đó mở khóa mọi thứ trong suốt đời với một khoản thanh toán với giá của cửa hàng của bạn.',
			'appAccess.buy' => ({required Object price}) => 'Khóa tất cả các tính năng cho ${price}',
			'appAccess.loadingPrice' => 'Giá bán hàng tải...',
			'appAccess.retryPrice' => 'Retry giá lookup',
			'appAccess.restore' => 'Lợi ích mua sắm suốt đời',
			'appAccess.pending' => 'Mua hàng của bạn đang chờ đợi thanh toán hoặc phê duyệt. truy cập suốt đời sẽ mở khóa ngay khi cửa hàng hoàn thành nó.',
			'appAccess.storeUnavailable' => 'Kiểm tra rằng bạn đã đăng ký vào cửa hàng và mua hàng được phép trên thiết bị này.',
			'appAccess.productNotFound' => 'Tính năng mở khóa PlezyNG vẫn chưa có sẵn trong cửa hàng này.',
			'appAccess.productQueryFailed' => 'Không thể tải giá cửa hàng. kiểm tra kết nối của bạn và thử lại.',
			'appAccess.purchaseFailed' => 'Mua sắm không qua được. thử lại.',
			'appAccess.restoreFailed' => 'Tôi không thể đến cửa hàng để khôi phục mua hàng của bạn. thử lại.',
			'appAccess.nothingToRestore' => 'Số PlezyNG mua hàng đời đã được tìm thấy cho tài khoản cửa hàng này.',
			'detail.endsAt' => ({required Object time}) => 'Kết thúc tại ${time}',
			'watchLink.serverUnavailable' => 'Tôi không thể truy cập một máy chủ Plex cho liên kết này.',
			'watchLink.notFound' => 'Tôi không thể tìm thấy chương trình hoặc bộ phim này trên máy chủ của bạn Plex.',
			'watchLink.ambiguous' => 'Liên kết này phù hợp với các mục trên nhiều hơn một máy chủ.Hãy thêm một máy chủ vào liên kết.',
			'watchLink.plexOnly' => 'Các liên kết xem hiện chỉ hỗ trợ các máy chủ Plex.',
			'watchLink.unsupportedItem' => 'Các liên kết xem chỉ có thể mở một chương trình hoặc một bộ phim.',
			'watchLink.menuItem' => 'Xem link xem',
			'watchLink.dialogTitle' => 'Xem link',
			'watchLink.dialogShowHint' => 'Mở liên kết này sẽ chơi phần tiếp theo. Thêm &mode=shuffle vào cuối để chơi chương trình trên shuffle.',
			'watchLink.dialogMovieHint' => 'Mở liên kết này chơi bộ phim.',
			'watchLink.copy' => 'Sao chép',
			'watchLink.copied' => 'Link sao chép',
			'homeLayout.title' => 'Trang chủ Layout',
			'homeLayout.resetToast' => 'Home Reset to the original Plezy anh hùng bố trí',
			'homeLayout.resetHeroTitle' => 'Đặt lại bố trí anh hùng để stock Plezy?',
			'homeLayout.resetHeroBody' => 'Nó xoay khỏi thiết lập anh hùng của mỗi hàng và mang lại một ban nhạc xoay duy nhất ở trên cùng của Nhà, giống như trước khi hàng anh hùng tồn tại.',
			'homeLayout.removeRowTitle' => 'Xóa dòng Home?',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} sẽ bị xóa. điều này không thể bị bỏ qua.',
			'homeLayout.sync' => 'đồng bộ',
			'homeLayout.syncAccountTitle' => 'Đồng bộ hóa bố trí với tài khoản Plex của bạn',
			'homeLayout.syncAccountOn' => 'Trên: Thiết bị này chia sẻ lệnh hàng, hàng, Hero và Auto-slide với các thiết bị khác của bạn.',
			'homeLayout.syncAccountOff' => 'Tắt: Thiết bị này giữ bố trí của riêng mình.',
			'homeLayout.syncNow' => 'Sync hiện tại',
			'homeLayout.plexHomeManager' => 'Plex Nhà quản lý',
			'homeLayout.managePlexRows' => 'Quản lý Plex hàng trong Plezy',
			'homeLayout.managePlexRowsDescription' => 'Mở để tổ chức các dòng được chọn tại nhà',
			'homeLayout.organizeHomeRows' => 'Tổ chức Home Rows',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} hàng: di chuyển, Anh hùng, Auto-slide, loại bỏ',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => 'Tổ chức ${library} hàng',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => 'Tiếp tục xem + ${n} hàng: di chuyển, Thư viện, Nhà, Anh hùng, tự động-slide',
			'homeLayout.renderAsHero' => 'Render như một thẻ anh hùng',
			'homeLayout.heroOnlySingleCollection' => 'Chỉ có sẵn khi hàng này được giải quyết cho các tiêu đề thực tế của một bộ sưu tập duy nhất',
			'homeLayout.hero' => 'Anh hùng',
			'homeLayout.autoSlide' => 'tự động slide',
			'homeLayout.autoSlideDescription' => 'Lấy (PC) và d-pad (TV) luôn hoạt động và khởi động lại đồng hồ.',
			'homeLayout.autoSlideEditDescription' => 'Ngoài ra, nó tự nhảy mỗi vài giây. tắt: chỉ di chuyển khi bạn nhấp vào một mũi tên (PC) hoặc nhấn trái / phải trên từ xa (TV).',
			'homeLayout.enableHeroFirst' => 'Khả năng Hero đầu tiên',
			'homeLayout.showOnHome' => 'Hiển thị trên màn hình Home',
			'homeLayout.home' => 'Trang chủ',
			'homeLayout.removeFromHome' => 'Xóa khỏi nhà',
			'homeLayout.selectRowsFirst' => 'Chọn dòng Home bên dưới trước.',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} Plex hàng quản lý',
			'homeLayout.continueWatching' => 'Tiếp tục xem',
			'homeLayout.continueWatchingLibraryDescription' => 'Thư viện bản thân của dòng tiến bộ',
			'homeLayout.continueWatchingHomeDescription' => 'Lời bài hát: The Resume-Progress Trail Showed On Home',
			'homeLayout.nextUpHomeDescription' => 'Next Unwatched episode series hiển thị riêng biệt trên Home',
			'homeLayout.library' => 'Thư viện',
			'homeLayout.showInRecommended' => 'Hiển thị trong Thư viện khuyến cáo',
			'homeLayout.customPlexRow' => 'Tính năng: Plex',
			'homeLayout.heroNeedsLibrary' => 'Kiểm tra Thư viện đầu tiên — Hero cần một nơi nào đó để hiển thị',
			'homeLayout.heroNeedsSurface' => 'Kiểm tra Thư viện hoặc Nhà đầu tiên — Anh hùng cần một nơi nào đó để hiển thị',
			'homeLayout.removeHub' => 'Xóa Hub',
			'homeLayout.noPlexRows' => 'Số Plex hàng quản lý đã trở lại cho thư viện này.',
			'homeLayout.openDetails' => 'chi tiết mở',
			'homeLayout.heroCards' => 'thẻ anh hùng',
			'homeLayout.tapHeroCard' => 'Tải thẻ anh hùng',
			'homeLayout.tvPlayFocus' => 'TV từ xa: nhấn nút Play',
			'homeLayout.tvPlayFocusDescription' => 'D-pad xuống dừng lại trên nút Play trước khi di chuyển đến hàng tiếp theo.',
			'homeLayout.tvWrap' => 'TV từ xa: loop hero cards',
			'homeLayout.tvWrapDescription' => 'Ngay trên thẻ cuối cùng đi trở lại thẻ đầu tiên. off dừng ở thẻ cuối cùng. trái trên thẻ đầu tiên luôn đi đến thanh bên.',
			'homeLayout.castOnHero' => 'Lời bài hát: Hero Banner',
			'homeLayout.castOnHeroDescription' => 'Hiển thị bản vẽ dọc theo đáy của một banner anh hùng. Off giữ chỉ tiêu đề và tổng hợp.',
			'homeLayout.customRows' => 'Custom dòng',
			'homeLayout.loading' => 'Trang chủ » Layout ...',
			'homeLayout.noCustomRows' => 'Không có dòng tiêu chuẩn',
			'homeLayout.addRowHint' => 'Sử dụng Add Home row để tạo một.',
			'homeLayout.addHomeRow' => 'Thêm Home Row',
			'homeLayout.addHomeRowDescription' => 'Chọn một thể loại; dòng mới được thêm vào Nhà tổ chức tự động',
			'homeLayout.removeRow' => 'Xóa dòng',
			'homeLayout.recentlyAdded' => 'Thêm Gần Đây',
			'homeLayout.recentlyReleased' => 'Gần đây phát hành',
			'homeLayout.movieCollections' => 'Bộ sưu tập phim',
			'homeLayout.showCollections' => 'Hiển thị bộ sưu tập',
			'homeLayout.rowTitle' => 'Row tiêu đề',
			'homeLayout.content' => 'Nội dung',
			'homeLayout.showThisRowIn' => 'Hiển thị dòng này trong:',
			'homeLayout.libraryRecommended' => 'Thư viện khuyến cáo',
			'homeLayout.heroCard' => 'thẻ anh hùng',
			'homeLayout.heroCardDescription' => 'Hiển thị như một thẻ quay rộng đầy đủ thay vì một tấm poster.',
			'homeLayout.heroUnavailableDescription' => 'Chỉ có sẵn khi hàng này được giải quyết với các tiêu đề thực tế của một bộ sưu tập duy nhất - với nhiều hơn một bộ sưu tập được chọn không có tiêu đề duy nhất để xoay qua.',
			'homeLayout.librariesSelection' => 'Thư viện (tìm tất cả không kiểm tra để bao gồm mỗi thư viện)',
			'homeLayout.librariesMergedDescription' => 'Mỗi thư viện được kiểm tra ở đây được kết hợp vào một hàng này.',
			'homeLayout.movieCollectionsSelection' => 'Bộ sưu tập phim (tìm tất cả không kiểm tra cho mỗi thư viện được chọn)',
			'homeLayout.showCollectionsSelection' => 'Hiển thị các bộ sưu tập (tìm tất cả không kiểm tra cho mỗi thư viện được chọn)',
			'homeLayout.collectionRowsDescription' => 'Nếu chính xác một bộ sưu tập phù hợp, các tiêu đề của nó hiển thị trực tiếp trong hàng. Nếu nhiều hơn một bộ sưu tập phù hợp, mỗi bộ sưu tập hiển thị như một poster duy nhất — nhấn vào nó để mở bộ sưu tập đó.',
			'homeLayout.allCollections' => 'Tất cả bộ sưu tập',
			'homeLayout.noRowsHere' => 'Hiện chưa có dòng nào ở đây.',
			'homeLayout.hideWatchedRows' => 'Ẩn các mục được xem trong hàng',
			'homeLayout.hideWatchedRowsDescription' => 'Các tiêu đề được xem đầy đủ rời khỏi Nhà và Thư viện Các dòng được đề xuất.',
			'homeLayout.untitledCollection' => 'Lời bài hát Untitled Collection',
			'homeLayout.moveRowHint' => 'Up/Down: move row · Select: drop it here · Back: cancell',
			'homeLayout.organizeRowsHint' => 'Chọn theo một hàng (hoặc giữ Chọn): di chuyển nó · Trái/Trái: tùy chọn hàng · Trở lại: hoàn thành',
			'homeLayout.layoutNavDescription' => 'Chọn hàng, thư viện, và thể loại thu thập',
			'homeLayout.editHomeRow' => 'Trang chủ Edit',
			'homeLayout.resetHeroButton' => 'Đặt lại bản bố trí anh hùng để stock Plezy',
			'homeLayout.reorderingUnlocked' => 'Đặt lại Unlocked',
			'homeLayout.reorderingLocked' => 'Đặt lại khóa',
			'homeLayout.rowsCanBeDragged' => 'Các dây có thể được kéo — nhấn khóa để ngăn chặn',
			'homeLayout.tapLockToDrag' => 'Nhấn khóa để kéo hàng',
			'homeLayout.customRowLabel' => ({required Object title}) => 'Số lượng: ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => 'Ẩn',
			'homeLayout.remove' => 'Gỡ bỏ',
			'homeLayout.libraryResumeRow' => 'Thư viện của thư viện này',
			'homeLayout.pressAgainToDelete' => 'Nhấn lại để xóa',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => 'trên',
			'homeLayout.resetHeroButtonDescription' => 'Nó xoay khỏi thiết lập anh hùng của mỗi hàng và mang lại một banner xoay duy nhất ở phía trên, giống như trước khi hàng anh hùng tồn tại.',
			'homeLayout.tapHeroCardDescription' => 'Chọn xem đánh hoặc chọn một thẻ Hero bắt đầu phát lại hay mở chi tiết của nó.',
			'homeLayout.heroTapPlayDescription' => 'Bắt đầu mục được chọn ngay lập tức.',
			'homeLayout.heroTapDetailsDescription' => 'Mở chi tiết của mục được chọn trước khi chọn một hành động.',
			'platform.localNetworkPermission' => 'PlezyNG kết nối với máy chủ truyền thông và thiết bị phát lại trên mạng địa phương của bạn.',
			'platform.locationPermission' => 'PlezyNG sử dụng quyền truy cập vị trí khi iOS yêu cầu nó để phát hiện mạng lưới địa phương của bạn và kết nối với máy chủ truyền thông của bạn.',
			'platform.photoLibraryPermission' => 'Chọn hình ảnh từ thư viện ảnh của bạn để sử dụng như một công việc nghệ thuật phương tiện truyền thông.',
			'platform.cameraPermission' => 'Scan mã QR để kết hợp một Companion Remote.',
			'universalMedia.title' => 'phương tiện truyền thông mở',
			'universalMedia.shortcutHelp' => 'Chơi một liên kết, danh sách chơi hoặc tệp cho phiên này.',
			'universalMedia.intro' => 'Mở một liên kết, danh sách phát hoặc tệp. Playback sử dụng người chơi tiêu chuẩn của PlezyNG và không thêm lịch sử vào thư viện của bạn.',
			'universalMedia.openWhat' => 'Bạn muốn mở cái gì?',
			'universalMedia.stream' => 'Địa chỉ Stream',
			'universalMedia.playlist' => 'Danh sách Playlist',
			'universalMedia.files' => 'Thiết bị file',
			'universalMedia.favorites' => 'Save Stream yêu thích',
			'universalMedia.address' => 'Địa chỉ Media',
			'universalMedia.addressHelp' => 'URL với các thông số xác nhận hoặc ký tự được công nhận chỉ được sử dụng cho phiên này và không thể được lưu như là yêu thích.',
			'universalMedia.displayName' => 'Tên hiển thị (tùy chọn)',
			'universalMedia.displayNameHelp' => 'Chọn tên ngắn cho người chơi và hệ thống điều khiển phương tiện truyền thông.',
			'universalMedia.allowHttp' => 'Cho phép kết nối HTTP không được mã hóa',
			'universalMedia.allowHttpHelp' => 'HTTP không mã hóa kết nối. Chỉ cho phép nó trên một mạng tin cậy. Sử dụng HTTPS khi có thể.',
			'universalMedia.advancedProtocols' => 'Chỉ MPV: nhập một địa chỉ RTSP, RTMP/RTMPS, UDP hoặc RTP. Các địa chỉ này không thể được lưu như là yêu thích.',
			'universalMedia.liveStream' => 'Chăm sóc như sống',
			'universalMedia.liveStreamHelp' => 'Sử dụng điều này cho video hay radio trực tiếp. Ứng dụng che giấu thanh thời gian, nhấp chuột và tùy chọn go-to-time.',
			'universalMedia.privateSession' => 'Chỉ bài phát này sử dụng địa chỉ.Save an eligible stream favorite to keep it in this profile.',
			'universalMedia.saveFavorite' => 'Giữ yêu thích',
			'universalMedia.playNow' => 'Chơi bây giờ',
			'universalMedia.favoriteSaved' => 'Stream Favorite được tiết kiệm đến hồ sơ này',
			'universalMedia.skippedEntries' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n, other: 'Tắt ${count} không được hỗ trợ hoặc không an toàn danh sách đăng nhập.', ), 
			'universalMedia.playlistAddress' => 'Địa chỉ Playlist',
			'universalMedia.playlistAddressHelp' => 'Mở một danh sách chơi M3U, M3u8, hoặc PLS từ địa chỉ web. liên kết trực tiếp không lưu danh sách playlist.',
			'universalMedia.choosePlaylist' => 'Chọn playlist file',
			'universalMedia.openPlaylist' => 'playlist mở',
			'universalMedia.playlistFormatsHelp' => 'Một danh sách phát có thể chứa tối đa 1.000 mục và 2 MB. HLS hiển thị mở như dòng để người chơi có thể chọn một chất lượng.',
			'universalMedia.saveQueuePlaylist' => 'Lưu hàng đợi thành danh sách phát',
			'universalMedia.queuePlaylistSaved' => 'Danh sách phát đã được lưu cạnh các tệp phương tiện.',
			'universalMedia.queuePlaylistUnavailable' => 'Không thể lưu hàng đợi này thành danh sách phát cục bộ để dùng lại.',
			'universalMedia.queuePlaylistFolderRequired' => 'Chọn vị trí lưu trong cùng thư mục với các tệp trong hàng đợi.',
			'universalMedia.noFavorites' => 'Không được lưu stream yêu thích cho đến nay. Favorites stay in this profile.',
			'universalMedia.removeFavorite' => 'Xóa stream yêu thích',
			'universalMedia.filesHelp' => 'Chọn các tệp âm thanh, video hoặc ISO cho một cặp tạm thời. tệp và URL không được thêm vào lịch sử thư viện.',
			'universalMedia.chooseFiles' => 'Chọn file',
			'universalMedia.fileQueue' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n, other: '${count} tập tin được chọn', ), 
			'universalMedia.wifiTransfer' => 'Gửi file qua Wi-Fi',
			'universalMedia.wifiTransferHelp' => 'Chuyển các tập tin được hỗ trợ từ một trình duyệt trên cùng một mạng đáng tin cậy.',
			'universalMedia.wifiTransferIntro' => 'Mở địa chỉ này trong một trình duyệt trên thiết bị khác.Chọn các tệp để thêm chúng vào thư viện tệp và sách của thiết bị này.',
			'universalMedia.wifiTransferPrivacy' => 'Thiết bị này nhận được tệp qua mạng địa phương của bạn. bất cứ ai biết địa chỉ này có thể gửi tệp cho đến khi bạn ngừng chuyển giao hoặc địa chỉ hết hạn sau 15 phút. tối đa: 100 tệp, 4 GiB mỗi tệp; tổng cộng 10 GiB.',
			'universalMedia.wifiTransferStarting' => 'Chuẩn bị một chuyển giao riêng, thời gian giới hạn...',
			'universalMedia.wifiTransferUnavailable' => 'Không thể bắt đầu chuyển giao. kiểm tra truy cập mạng địa phương và thử lại.',
			'universalMedia.openThisAddress' => 'Mở một trong những địa chỉ này trên thiết bị gửi',
			'universalMedia.copyAddress' => 'Bản sao địa chỉ chuyển đổi',
			'universalMedia.addressCopied' => 'Địa chỉ chuyển đổi sao chép',
			'universalMedia.transferExpires' => ({required Object time}) => 'Địa chỉ này hết hạn trong ${time}.',
			'universalMedia.uploadCount' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n, other: '${count} file nhận được', ), 
			'universalMedia.uploadedData' => ({required Object size}) => 'Nhận ${size}',
			'universalMedia.stopTransfer' => 'Ngừng chuyển giao và vô hiệu hóa địa chỉ',
			'universalMedia.startTransfer' => 'Bắt đầu chuyển giao',
			'universalMedia.wifiImportedFiles' => 'Chuyển Wi-Fi',
			'universalMedia.wifiBrowserTitle' => 'Gửi file đến PlezyNG',
			'universalMedia.wifiBrowserIntro' => 'Chọn các tập tin âm thanh, video, ebook hoặc truyện tranh để gửi. Các tập tin được lưu trữ trong thư viện tệp và sách của thiết bị này. Tối đa: 100 tập tin, 4 GiB mỗi file, tổng cộng 10 GiB.',
			'universalMedia.uploadFilesLabel' => 'file để gửi',
			'universalMedia.uploadSelected' => 'Tải các tập tin được chọn',
			'universalMedia.uploadSelectFirst' => 'Chọn một hoặc nhiều tập tin đầu tiên.',
			'universalMedia.uploading' => 'gửi',
			'universalMedia.uploadComplete' => 'File được thêm vào PlezyNG.',
			'universalMedia.uploadFailed' => 'Tệp không thể được thêm vào. giữ cho trang này mở và thử lại.',
			'universalMedia.liveCue' => 'Sống',
			'universalMedia.liveSession' => 'Stream trực tiếp',
			'universalMedia.liveCueHelp' => 'Đối với video hay radio trực tiếp, ứng dụng ẩn thanh thời gian và nhảy nút. nó không lưu địa chỉ hoặc xem lịch sử.',
			'universalMedia.sessionOnly' => 'Playback này là session-only',
			'universalMedia.sessionOnlyHelp' => 'Playback không bao giờ tiết kiệm tiến bộ hoặc lịch sử.Save the stream as a favorite to keep it in this profile if it is eligible.',
			'universalMedia.pictureAdjustments' => 'hình ảnh điều chỉnh',
			'universalMedia.pictureHelp' => 'Những thay đổi hình ảnh này chỉ ảnh hưởng đến playback này. họ đặt lại khi playback kết thúc.',
			'universalMedia.resetPicture' => 'Reset hình ảnh',
			'universalMedia.brightness' => 'Ánh sáng',
			'universalMedia.contrast' => 'Ngược điểm',
			'universalMedia.gamma' => 'Gamma',
			'universalMedia.hue' => 'Hue',
			'universalMedia.saturation' => 'Saturation',
			'universalMedia.view360' => 'Màn hình 360° video',
			'universalMedia.view360Help' => 'Sử dụng điều này cho video 360° đồng chiều. MPV cần bộ lọc v360 của FFmpeg để xem.',
			'universalMedia.view360Unavailable' => 'Thiết lập MPV này không thể áp dụng bộ lọc 360°.',
			'universalMedia.view360Yaw' => 'tầm nhìn chân trời',
			'universalMedia.view360Pitch' => 'Màn hình Vertical View',
			'universalMedia.view360FieldOfView' => 'Vùng tầm nhìn',
			'universalMedia.recordStream' => 'Đánh giá Live Stream',
			'universalMedia.stopRecording' => 'Ngừng và tiết kiệm ghi âm',
			'universalMedia.recordingStarted' => 'Ghi âm là hoạt động.Leaving playback stops and saves the recording.',
			'universalMedia.recordingSaved' => 'Ghi âm được hoàn thành và tiết kiệm.',
			'universalMedia.recordingActive' => 'Để lại playback dừng lại và tiết kiệm nó.',
			'universalMedia.recordingFormatHelp' => 'Đối với video, chọn MKV hoặc MPEG-TS. Đối với âm thanh, chọn MKA hoặc MKV.',
			'universalMedia.replaceRecordingTitle' => 'Thay thế bản ghi này?',
			'universalMedia.replaceRecordingHelp' => 'PlezyNG sao lưu tệp hiện có trong khi ghi lại. nếu nó không thể tiết kiệm bản ghi mới, Plezyng khôi phục sao lưu.',
			'universalMedia.replaceRecording' => 'Thay thế file',
			'universalMedia.discHelp' => 'Mở một đĩa trong ổ đĩa quang của máy tính này. Bạn cũng có thể mở hình ảnh ISO từ các tệp thiết bị.',
			'universalMedia.discs' => 'Đĩa Optical',
			'universalMedia.editionOrTitle' => 'Ấn bản hoặc tên đĩa',
			'universalMedia.dvd' => 'DVD',
			'universalMedia.bluray' => 'Đánh giá Blu-ray',
			'universalMedia.audioCd' => 'CD âm thanh',
			'universalMedia.discAvailability' => 'Đĩa playback cần một cấu trúc MPV tương thích, ổ đĩa được hỗ trợ và giấy phép hệ điều hành. nó không thể vượt qua bảo vệ đĩa thương mại.',
			'universalMedia.converterTitle' => 'Chuyển đổi một tập tin phương tiện truyền thông địa phương',
			'universalMedia.converterHelp' => 'Chuyển đổi một tệp địa phương hoặc sửa lại nó với FFmpeg.',
			'universalMedia.converterIntro' => 'Chuyển đổi một tệp âm thanh hoặc video địa phương sang định dạng hoạt động trên nhiều thiết bị.',
			'universalMedia.converterPrivacy' => 'FFmpeg phải được cài đặt trên máy tính này. chuyển đổi chỉ đọc các tập tin địa phương. nó không tải về dòng hoặc loại bỏ DRM.',
			'universalMedia.converterChooseInput' => 'Chọn một tập tin phương tiện truyền thông địa phương',
			'universalMedia.converterFormat' => 'định dạng output',
			'universalMedia.converterMp4' => 'MP4 · H.264 và AAC',
			'universalMedia.converterM4a' => 'M4A · AAC âm thanh',
			'universalMedia.converterMp3' => 'MP3 - Âm thanh',
			'universalMedia.allowFtp' => 'Khả năng FTP',
			'universalMedia.allowFtpHelp' => 'FTP gửi các phương tiện truyền thông mà không có mã hóa. sử dụng chỉ trên mạng tin cậy.',
			'universalMedia.converterSaveAs' => 'Lưu các phương tiện truyền thông được chuyển đổi như',
			'universalMedia.converterExtensionMismatch' => 'Chọn tên file với phần mở rộng output được chọn.',
			'universalMedia.converterUnsupportedInput' => 'Chọn một file audio hoặc video.',
			'universalMedia.converterLocalOnly' => 'Tệp được chọn không có sẵn như một con đường thiết bị địa phương.',
			'universalMedia.converterReplaceTitle' => 'Thay thế file này?',
			'universalMedia.converterReplaceHelp' => 'PlezyNG khôi phục lại tệp hiện có cho đến khi bản sao được chuyển đổi được lưu.',
			'universalMedia.converterStarting' => 'Bắt đầu FFmpeg...',
			'universalMedia.converterProgress' => 'Chuyển đổi vào máy tính này...',
			'universalMedia.converterComplete' => 'Chuyển đổi hoàn thành. file mới đã sẵn sàng.',
			'universalMedia.converterFfmpegMissing' => 'FFmpeg thiếu hoặc không hỗ trợ định dạng này.',
			'universalMedia.converterFailed' => 'Chuyển đổi thất bại. kiểm tra rằng tệp nguồn có thể được đọc và điểm đến có đủ không gian miễn phí.',
			'universalMedia.converterCancelled' => 'Chuyển đổi đã bị hủy; Kết quả không đầy đủ đã được loại bỏ.',
			'universalMedia.converterDesktopOnly' => 'Chuyển đổi địa phương có sẵn trên máy tính bảng với FFmpeg cài đặt.',
			'universalMedia.converterStart' => 'chuyển đổi file',
			'universalMedia.mediaToolsTitle' => 'Công cụ Media',
			'universalMedia.mediaToolsShortcut' => 'Ghi hoặc chia sẻ phương tiện truyền thông, thêm phần mở rộng tìm kiếm, hoặc sử dụng dòng lệnh.',
			'universalMedia.mediaToolsIntro' => 'Chọn một công cụ tập trung. chụp và stream-out sử dụng FFmpeg được cài đặt trên máy tính để bàn này. Extensions và CLI lệnh sử dụng giới hạn yêu cầu HTTPS và dòng Open media hiện có.',
			'universalMedia.mediaToolsAccessibility' => 'Các công cụ lựa chọn và điều khiển làm việc với touch, point, keyboard, và D-pad tập trung. ghi âm, chia sẻ, và các thay đổi trạng thái tìm kiếm được công bố.',
			'universalMedia.mediaTool' => 'Công cụ Media',
			'universalMedia.captureIntro' => 'Ghi lại màn hình hoặc máy ảnh của bạn vào một tệp MP4 trên máy tính này. FFmpeg phải được cài đặt và bao gồm mã hóa H.264.',
			'universalMedia.captureNoDevices' => 'Không tìm thấy màn hình hoặc máy ảnh. kiểm tra hỗ trợ chụp FFmpeg và quyền riêng tư hệ điều hành.',
			'universalMedia.captureSource' => 'màn hình hoặc camera',
			'universalMedia.captureScreen' => 'màn hình',
			'universalMedia.captureAudioSource' => 'Audio input (tùy chọn)',
			'universalMedia.captureAudioHelp' => 'Thêm âm thanh từ microphone hoặc input có sẵn. lựa chọn thiết bị phụ thuộc vào FFmpeg và quyền hệ thống.',
			'universalMedia.captureAudioNone' => 'Không có Audio',
			'universalMedia.captureDefaultAudio' => 'Lập trình Audio Input',
			'universalMedia.captureWaylandHelp' => 'Wayland giới hạn thu thập XWayland này đến X display. Windows bên ngoài XWayland có thể không xuất hiện.',
			_ => null,
		} ?? switch (path) {
			'universalMedia.captureFrameRate' => 'Tỷ lệ ghi âm frame rate',
			'universalMedia.capturePrivacy' => 'Ghi âm được lưu chỉ cho tệp bạn chọn. microphone capture là tùy chọn. PlezyNG không tải lên ghi âm.',
			'universalMedia.captureSaveAs' => 'Lưu màn hình ghi âm như',
			'universalMedia.captureExtensionMismatch' => 'Chọn tên file kết thúc trong .mp4.',
			'universalMedia.captureFfmpegMissing' => 'FFmpeg hoặc mã hóa video H.264 không sẵn dùng. cài đặt một xây dựng FFmpeg được hỗ trợ, sau đó thử lại.',
			'universalMedia.captureFailed' => 'Kiểm tra giấy phép thiết bị, lưu trữ có sẵn, và hỗ trợ FFmpeg.',
			'universalMedia.captureSaved' => 'Màn hình ghi âm được tiết kiệm',
			'universalMedia.captureElapsedLabel' => 'Thời gian ghi âm',
			'universalMedia.captureStart' => 'Bắt đầu ghi âm',
			'universalMedia.capturePreview' => 'Xem trước trong trình phát',
			'universalMedia.capturePreviewHelp' => 'Xem trước nguồn đã chọn trong trình phát thông thường. Bản xem trước chỉ tồn tại trong phiên này và không lưu bản ghi. Hỗ trợ thiết bị và quyền truy cập tùy thuộc vào MPV và hệ điều hành. Bản xem trước chỉ dùng video; bản ghi đã lưu có thể kèm âm thanh tùy chọn.',
			'universalMedia.capturePreviewActive' => 'Xem trước trực tiếp · không ghi hình',
			'universalMedia.captureStop' => 'Stop và Save',
			'universalMedia.captureMode' => 'bắt giữ',
			'universalMedia.shareMode' => 'chia sẻ',
			'universalMedia.shareIntro' => 'Gửi một tệp phương tiện truyền thông địa phương đến một thiết bị khác trên mạng riêng của bạn. PlezyNG tạo ra một dòng HLS tạm thời.',
			'universalMedia.sharePrivacy' => 'Bất cứ ai trên mạng địa phương của bạn nhận được liên kết tư nhân có thể xem trong khi nó hoạt động. liên kết hết hạn sau 60 phút. ngừng chia sẻ để đóng máy chủ và vô hiệu hóa liên kết.',
			'universalMedia.shareChooseFile' => 'Chọn file media',
			'universalMedia.shareChooseHelp' => 'Chọn một tệp âm thanh hoặc video địa phương. tệp vẫn ở trên máy tính này.',
			'universalMedia.shareFfmpegMissing' => 'FFmpeg hoặc các mã hóa H.264/AAC không sẵn dùng. cài đặt FFmpeg với hỗ trợ mã hóa H.264 và AAC.',
			'universalMedia.shareFailed' => 'Stream không thể bắt đầu hoặc dừng lại bất ngờ. kiểm tra FFmpeg và truy cập mạng.',
			'universalMedia.shareActive' => 'Stream đã sẵn sàng trên mạng riêng của bạn.',
			'universalMedia.shareEnded' => 'Truyền thông đã đạt đến kết thúc và không còn được chia sẻ nữa.',
			'universalMedia.shareStopped' => 'Chia sẻ dừng lại. liên kết tạm thời không còn hợp lệ.',
			'universalMedia.shareUrlCopied' => 'Địa chỉ dòng được sao chép.',
			'universalMedia.shareOpenUrl' => 'Mở địa chỉ này trong một người chơi trên thiết bị khác',
			'universalMedia.shareQrLabel' => 'Mã QR cho địa chỉ dòng tạm thời',
			'universalMedia.shareQrHelp' => 'Scan với một người chơi tương thích kết nối với cùng một mạng tư nhân.',
			'universalMedia.shareHttpHint' => 'Stream này sử dụng HTTP không được mã hóa. trong PlezyNG, cho phép HTTP trước khi mở nó.',
			'universalMedia.shareCopyUrl' => 'Bản sao Stream Address',
			'universalMedia.shareExpiresLabel' => 'Link kết thúc tại',
			'universalMedia.shareStarting' => 'Chuẩn bị dòng chảy...',
			'universalMedia.shareStart' => 'Bắt đầu chia sẻ',
			'universalMedia.shareStop' => 'Ngừng chia sẻ',
			'universalMedia.extensionsMode' => 'Tăng cường và CLI',
			'universalMedia.extensionsIntro' => 'Thêm một phần mở rộng chỉ tìm kiếm dữ liệu để tìm các phương tiện truyền thông. Chọn kết quả để tải nó vào biểu mẫu quen thuộc Open media.',
			'universalMedia.extensionsPrivacy' => 'Một biểu hiện có thể xác định một HTTPS tìm kiếm kết thúc và các trường phản ứng bản đồ. nó không thể chạy mã, thêm tiêu đề yêu cầu, đọc các tệp, hoặc lệnh khởi động shell.',
			'universalMedia.extensionImport' => 'Thêm Extension Manifest',
			'universalMedia.extensionEmpty' => 'Chưa có dịch vụ tìm kiếm cho đến nay. chọn một tệp hiển thị đáng tin cậy JSON để thêm một.',
			'universalMedia.extensionChoose' => 'Dịch vụ tìm kiếm',
			'universalMedia.extensionSearchConsent' => 'Mỗi tìm kiếm gửi từ của bạn đến dịch vụ HTTPS này. kết quả chỉ mở sau khi bạn chọn một.',
			'universalMedia.extensionSearchLabel' => 'Tìm kiếm Media',
			'universalMedia.extensionSearch' => 'Tìm kiếm',
			'universalMedia.extensionSearching' => 'Tìm kiếm...',
			'universalMedia.extensionNoResults' => 'Không có kết quả truyền thông an toàn đã được trả về.Cần tìm kiếm thêm.',
			'universalMedia.extensionInstallTitle' => 'Thêm dịch vụ tìm kiếm này?',
			'universalMedia.extensionReplaceTitle' => 'Cập nhật dịch vụ tìm kiếm này?',
			'universalMedia.extensionService' => 'Dịch vụ',
			'universalMedia.extensionEndpoint' => 'HTTPS điểm cuối',
			'universalMedia.extensionConsent' => 'Văn bản tìm kiếm của bạn được gửi đến dịch vụ này.Manifest không chứa mã thực hiện.Hãy tiếp tục chỉ nếu bạn tin tưởng vào điểm kết thúc này.',
			'universalMedia.extensionInstall' => 'thêm dịch vụ',
			'universalMedia.extensionReplace' => 'Update dịch vụ',
			'universalMedia.extensionRemoveTitle' => 'Xóa dịch vụ tìm kiếm này?',
			'universalMedia.extensionRemoveHelp' => 'Điều này loại bỏ dịch vụ khỏi hồ sơ này.PlezyNG không liên hệ với điểm kết thúc của nó.',
			'universalMedia.extensionRemove' => 'Xóa dịch vụ',
			'universalMedia.extensionInvalidManifest' => 'Tệp này không phải là một biểu hiện mở rộng được hỗ trợ. xem hướng dẫn Open media cho định dạng.',
			'universalMedia.extensionSaveFailed' => 'Việc mở rộng không thể được lưu vào hồ sơ hoạt động.',
			'universalMedia.extensionSearchFailed' => 'Dịch vụ tìm kiếm không trả lại câu trả lời đúng. kiểm tra điểm kết thúc và thử lại.',
			'universalMedia.cliTitle' => 'Command dòng',
			'universalMedia.cliHelp' => 'Sử dụng hướng dẫn plezyctl để xác nhận một biểu hiện hoặc tìm kiếm cùng một phần mở rộng. Xem lại dịch vụ HTTPS của nó trước mỗi tìm kiếm. Kết quả mở trong biểu mẫu phương tiện hiện có; chọn nút playback để bắt đầu.',
			'universalMedia.cliCopyExample' => 'copy command ví dụ',
			'universalMedia.cliCopied' => 'Lệnh ví dụ sao chép.',
			'fileSources.title' => 'File và sách',
			'fileSources.subtitle' => 'Đọc, lắng nghe, và xem từ các tệp của riêng bạn.',
			'fileSources.add' => 'thêm nguồn',
			'fileSources.importFiles' => 'nhập file',
			'fileSources.localFiles' => 'Trên thiết bị này',
			'fileSources.source' => 'Nguồn',
			'fileSources.name' => 'Tên',
			'fileSources.endpoint' => 'URL máy chủ',
			'fileSources.smbEndpointHint' => 'Ví dụ: smb://nas/Movies',
			'fileSources.smbEndpointInvalid' => 'Nhập một máy chủ SMB và một thư mục chia sẻ.',
			'fileSources.root' => 'Folder hoặc Prefix',
			'fileSources.smbFolderHelp' => 'Để trống để dùng toàn bộ thư mục chia sẻ, hoặc nhập một thư mục bên trong.',
			'fileSources.username' => 'Tên đăng nhập',
			'fileSources.smbDomain' => 'Miền (không bắt buộc)',
			'fileSources.password' => 'Mật Khẩu',
			'fileSources.token' => 'API Đánh giá',
			'fileSources.accessKey' => 'Access Key ID',
			'fileSources.secretKey' => 'Key Access bí mật',
			'fileSources.sessionToken' => 'Session token (tùy chọn)',
			'fileSources.region' => 'Khu vực',
			'fileSources.clientId' => 'ID khách hàng OAuth',
			'fileSources.clientSecret' => 'OAuth Client Secret (chỉ Google Desktop)',
			'fileSources.allowHttp' => 'Cho phép HTTP không mã hóa trên mạng đáng tin cậy',
			'fileSources.smbEncryption' => 'Mã hóa kết nối SMB3',
			'fileSources.smbEncryptionHint' => 'Dùng mã hóa SMB3 khi NAS hỗ trợ.',
			'fileSources.connect' => 'Kết nối',
			'fileSources.cancel' => 'Hủy bỏ',
			'fileSources.save' => 'Lưu',
			'fileSources.close' => 'Đóng',
			'fileSources.removeSource' => 'Nguồn Disconnect',
			'fileSources.disconnectMessage' => 'Ngắt kết nối nguồn này? Các tệp đã tải xuống cùng lịch sử đọc và nghe sẽ vẫn được giữ trên thiết bị này.',
			'fileSources.localFolder' => 'Chọn folder',
			'fileSources.empty' => 'Chưa có gì ở đây',
			'fileSources.emptyHint' => 'Thêm một nguồn hoặc nhập một cuốn sách, cuốn sách âm thanh, âm nhạc hoặc video.',
			'fileSources.search' => 'Tìm kiếm folder này',
			'fileSources.searchCached' => 'Tìm kiếm thư viện cứu',
			'fileSources.refresh' => 'Làm mới',
			'fileSources.loadMore' => 'tải thêm',
			'fileSources.offline' => 'Có sẵn offline',
			'fileSources.download' => 'giữ offline',
			'fileSources.removeDownload' => 'Xóa bản sao offline',
			'fileSources.continueReading' => 'Tiếp tục đọc',
			'fileSources.continueListening' => 'Tiếp Tục Nghe',
			'fileSources.continueWatching' => 'Tiếp tục xem',
			'fileSources.read' => 'Đọc',
			'fileSources.listen' => 'nghe',
			'fileSources.play' => 'Phát',
			'fileSources.pause' => 'Tạm dừng',
			'fileSources.stop' => 'Ngưng',
			'fileSources.startOver' => 'Bắt đầu qua',
			'fileSources.finished' => 'Kết thúc',
			'fileSources.markFinished' => 'Mark kết thúc',
			'fileSources.markUnfinished' => 'Mark chưa hoàn thành',
			'fileSources.editions' => 'Phiên bản và file',
			'fileSources.chapters' => 'Chương 1',
			'fileSources.bookmarks' => 'Bookmarks và Note',
			'fileSources.bookmark' => 'Thêm Bookmark',
			'fileSources.highlight' => 'Đánh giá',
			'fileSources.note' => 'Ghi chú',
			'fileSources.delete' => 'Xóa',
			'fileSources.export' => 'Export ghi chú',
			'fileSources.exported' => 'Các ghi chú xuất khẩu',
			'fileSources.sync' => 'Sync tiến bộ',
			'fileSources.synced' => 'tiến bộ synchronized',
			'fileSources.conflict' => 'Một thiết bị khác có vị trí khác. chọn nơi để tiếp tục.',
			'fileSources.useLocal' => 'Sử dụng thiết bị này',
			'fileSources.useRemote' => 'Sử dụng các thiết bị khác',
			'fileSources.history' => 'Lịch sử vị trí',
			'fileSources.groupAudio' => 'Lắng nghe như một cuốn sách âm thanh',
			'fileSources.groupHint' => 'Kết hợp các tệp âm thanh hiện đang được tải vào thư mục này. tải tất cả các trang trước.',
			'fileSources.order' => 'File Order Đơn',
			'fileSources.moveUp' => 'chuyển lên',
			'fileSources.moveDown' => 'di chuyển xuống',
			'fileSources.speed' => 'Tốc Độ Phát',
			'fileSources.sleep' => 'Giấc ngủ Timer',
			'fileSources.sleepOff' => 'Tắt',
			'fileSources.endChapter' => 'Cuối chương',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(count, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} phút', ), 
			'fileSources.skipBack' => 'Skip trở lại',
			'fileSources.skipForward' => 'Skip đi trước',
			'fileSources.smartRewind' => 'Lợi ích của Smart Revenue sau một nghỉ ngơi',
			'fileSources.playbackOptions' => 'Lắng nghe các tùy chọn',
			'fileSources.remaining' => ({required Object time}) => '${time} còn lại',
			'fileSources.contents' => 'Nội dung',
			'fileSources.readerSettings' => 'Đọc Settings',
			'fileSources.fontSize' => 'Cỡ chữ',
			'fileSources.lineHeight' => 'Line không gian',
			'fileSources.margin' => 'Lề',
			'fileSources.font' => 'Typeface hình',
			'fileSources.serif' => 'Có chân',
			'fileSources.sans' => 'Không có serif',
			'fileSources.mono' => 'Đơn cách',
			'fileSources.columns' => 'Cột',
			'fileSources.scroll' => 'Cuộn dọc',
			'fileSources.justify' => 'Căn đều hai bên',
			'fileSources.readerTheme' => 'Trang xuất hiện',
			'fileSources.appTheme' => 'Theo dõi app theme',
			'fileSources.paper' => 'giấy',
			'fileSources.sepia' => 'Sepia',
			'fileSources.night' => 'đêm',
			'fileSources.readAloud' => 'Đọc to trang này',
			'fileSources.readAlong' => 'Đọc theo lời đọc',
			'fileSources.stopReading' => 'Ngừng kể chuyện',
			'fileSources.searchBook' => 'Tìm kiếm trong sách',
			'fileSources.noMatches' => 'Không trận đấu',
			'fileSources.previousPage' => 'Trang trước',
			'fileSources.nextPage' => 'Trang sau',
			'fileSources.page' => ({required Object number}) => 'Trang ${number}',
			'fileSources.externalBlocked' => 'Các liên kết sách bên ngoài bị vô hiệu hóa trong người đọc.',
			'fileSources.loading' => 'Mở...',
			'fileSources.narrator' => 'Tác giả',
			'fileSources.audio' => 'Âm thanh',
			'fileSources.video' => 'Video',
			'fileSources.ebooks' => 'Ebook',
			'fileSources.all' => 'Tất cả',
			'fileSources.downloads' => 'Offline file',
			'fileSources.confirmDelete' => 'Xóa bản sao ngoại tuyến đã chọn? Vị trí đọc hoặc nghe và ghi chú của bạn vẫn được giữ lại.',
			'fileSources.errorAuthentication' => 'Đăng nhập lại để nối lại nguồn này.',
			'fileSources.errorPermission' => 'Nguồn này không cho phép truy cập vào tệp yêu cầu.',
			'fileSources.errorUnavailable' => 'Nguồn không sẵn dùng.Chiên thử lại, hoặc mở bản sao offline.',
			'fileSources.errorUnsupported' => 'Định dạng hoặc kết nối này không được hỗ trợ trên thiết bị này. kiểm tra hướng dẫn cài đặt nguồn.',
			'fileSources.errorInvalidData' => 'Không thể đọc tệp hoặc phản hồi của máy chủ này một cách an toàn.',
			'fileSources.errorCancelled' => 'Chiến dịch đã bị hủy bỏ.',
			'fileSources.errorConflict' => 'Vị trí thay đổi trong phiên khác. mở lại mục để chọn một vị trí.',
			'fileSources.signIn' => 'Đăng nhập',
			'fileSources.reconnect' => 'nối lại',
			'fileSources.folderHelp' => 'Để lại trắng để bắt đầu từ gốc nguồn. URL S3 bao gồm bucket.',
			'fileSources.preferences' => 'Ưu tiên',
			'fileSources.timePosition' => 'vị trí',
			'fileSources.audioTrack' => 'Audio Track Đánh giá',
			'fileSources.subtitleTrack' => 'Subtitle Track',
			'fileSources.none' => 'Không có',
			'fileSources.fullscreen' => 'Toàn màn hình',
			'fileSources.syncLocation' => 'Progress sync folder (tùy chọn)',
			'fileSources.syncLocationHint' => 'Thư mục WebDAV dành riêng cho trạng thái PlezyNG. Dữ liệu được ghi có điều kiện; các tệp nội dung không bị thay đổi.',
			'fileSources.audiobooks' => 'Sách nói',
			'fileSources.comics' => 'truyện tranh',
			'fileSources.scan' => 'Scan cho sách và phương tiện truyền thông',
			'fileSources.browserReader' => 'Open Reader Đọc',
			'fileSources.browserReaderHelp' => 'Đọc được mở trong trình duyệt của bạn. giữ PlezyNG mở để lưu vị trí và ghi chú của bạn.',
			'fileSources.on' => 'trên',
			'fileSources.advancedSetup' => 'App đăng ký',
			'fileSources.microsoftSignIn' => 'Đăng ký với Microsoft',
			'fileSources.zoomIn' => 'Zoom trong',
			'fileSources.zoomOut' => 'Zoom ra ngoài',
			'fileSources.fitPage' => 'Trang phù hợp',
			'fileSources.fitWidth' => 'Fit rộng',
			'fileSources.actualSize' => 'Kích thước hiện tại',
			'fileSources.goToPage' => 'Đi đến page',
			'fileSources.goToSection' => 'Đi đến chương',
			'fileSources.pageRange' => ({required Object count}) => 'Nhập số từ 1 đến ${count}',
			'fileSources.pageLayout' => 'Trang layout',
			'fileSources.automatic' => 'tự động',
			'fileSources.singlePage' => '1 trang đơn',
			'fileSources.twoPages' => '2 Trang',
			'fileSources.readingDirection' => 'hướng đọc',
			'fileSources.leftToRight' => 'Trái sang Phải',
			'fileSources.rightToLeft' => 'Phải sang Trái',
			'fileSources.letterSpacing' => 'Thư không gian',
			'fileSources.wordSpacing' => 'Lời bài hát Spacing',
			'fileSources.readerControlsHelp' => 'Dùng hai ngón tay để phóng to hoặc dùng các nút thu phóng. Kéo để di chuyển trang. Ctrl/⌘ cùng + hoặc − điều chỉnh mức thu phóng; Ctrl/⌘ cùng 0 đặt lại mức thu phóng. Page Up và Page Down chuyển trang.',
			'fileSources.imagePage' => 'Trang truyện tranh',
			'fileSources.resetReader' => 'Đặt lại các ưu tiên đọc',
			'fileSources.zoom' => 'Thu phóng',
			'fileSources.useFiles' => 'Sử dụng file và sách',
			'fileSources.cancelScan' => 'Đặt hủy scan',
			'fileSources.googleDrive' => 'Google Drive',
			'fileSources.offlineQuota' => 'Offline download giới hạn',
			'fileSources.offlineQuotaHelp' => 'Thiết lập không gian tối đa được sử dụng bởi các bản sao ngoại tuyến, tệp nhập khẩu và tải xuống. Giảm giới hạn sẽ không loại bỏ các bản gốc hiện có.',
			'fileSources.offlineStorageUsage' => 'Lưu trữ Offline',
			'fileSources.reservedStorage' => 'Bảo Vệ',
			'fileSources.downloadQueue' => 'Tải Queue',
			'fileSources.downloadRunning' => 'tải xuống',
			'fileSources.downloadQueued' => 'chờ đợi',
			'fileSources.downloadPaused' => 'nghỉ ngơi',
			'fileSources.downloadFailed' => 'Phải nghỉ hưu',
			'fileSources.importing' => 'nhập khẩu',
			'fileSources.importInterrupted' => 'nhập khẩu bị gián đoạn · xóa để làm rõ',
			'fileSources.errorQuotaExceeded' => 'Giới hạn lưu trữ offline đã đạt được.Tăng giới hạn hoặc xóa bản sao tải xuống.',
			'fileSources.errorStorageLow' => 'Không có đủ lưu trữ thiết bị miễn phí để giữ bảo tồn được bảo vệ.',
			'fileSources.errorStorageUnavailable' => 'PlezyNG không thể kiểm tra lưu trữ thiết bị miễn phí, vì vậy việc viết đã dừng lại.',
			'fileSources.removeDownloadJob' => 'xóa download',
			'fileSources.downloadAlreadyComplete' => 'Tải xuống này đã hoàn thành trước khi nó có thể được xóa. mục bây giờ có sẵn offline.',
			'fileSources.confirmRemoveDownloadJob' => 'Loại bỏ tải xuống này và loại bỏ bất kỳ dữ liệu được tải về một phần? vị trí và ghi chú của bạn sẽ ở lại.',
			'lending.title' => 'Thư viện công cộng',
			'lending.add' => 'Thêm một thư viện',
			'lending.other' => 'Thư viện khác',
			'lending.libraryName' => 'Thư viện tên',
			'lending.libraryUrl' => 'Thư viện website',
			'lending.libraryUrlHint' => 'Dùng danh mục hoặc trang đăng nhập của thư viện.',
			'lending.intro' => 'Hãy vay từ thư viện của bạn, hãy giữ cho sách của bạn gần.',
			'lending.handoff' => 'Đăng nhập, mượn sách và đọc an toàn qua dịch vụ riêng của thư viện.',
			'lending.openService' => 'Thư viện mở',
			'lending.findLibrary' => 'Tìm một thư viện',
			'lending.search' => 'Tìm kiếm sách và tác giả',
			'lending.catalogue' => 'Danh mục',
			'lending.loans' => 'Sách đã mượn',
			'lending.holds' => 'Đặt trước',
			'lending.signIn' => 'Đăng nhập với thư viện của bạn',
			'lending.waiting' => 'Kết thúc đăng ký trong trình duyệt của bạn, sau đó trở lại đây.',
			'lending.cancel' => 'Hủy bỏ',
			'lending.disconnect' => 'xóa thư viện',
			'lending.disconnectMessage' => 'Xóa thư viện này khỏi hồ sơ này? Các sách đã mượn và lượt đặt trước vẫn được giữ tại thư viện.',
			'lending.getBook' => 'Nhận sách',
			'lending.checkAvailability' => 'Kiểm tra khả dụng',
			'lending.available' => 'Có sẵn để vay',
			'lending.unavailable' => 'Hiện chưa có',
			'lending.borrow' => 'Mượn',
			'lending.placeHold' => 'Đặt trước',
			'lending.returnBook' => 'Trả trước hạn',
			'lending.cancelHold' => 'Hủy đặt trước',
			'lending.confirmBorrow' => 'Bạn có nên mượn danh hiệu này từ thư viện của mình?',
			'lending.confirmReturn' => 'Trả tựa sách này ngay? Bạn có thể cần mượn lại để tiếp tục.',
			'lending.confirmCancelHold' => 'Hủy lượt đặt trước của bạn cho tựa sách này?',
			'lending.email' => 'Đặt thông báo email',
			'lending.due' => ({required Object date}) => 'Hạn trả: ${date}',
			'lending.queue' => ({required Object position}) => 'Vị trí ${position} trong dòng',
			'lending.empty' => 'Không có tiêu đề nào ở đây.',
			'lending.openLibraryNote' => 'Khám phá danh mục của Open Library. Các tùy chọn đọc và mượn được hiển thị trên trang của từng tựa sách.',
			'lending.more' => 'tải thêm',
			'lending.gateway' => 'Thư viện đăng ký dịch vụ',
			'lending.gatewayHint' => 'Được cung cấp bởi thư viện của bạn hoặc quản trị viên PlezyNG.',
			'lending.advanced' => 'Thư viện Integration',
			'lending.loadLibraries' => 'Chọn thư viện của bạn',
			'lending.expired' => 'Thời hạn mượn sách này đã kết thúc.',
			'lending.updated' => 'Thư viện cập nhật',
			'lending.continueService' => 'tiếp tục phục vụ',
			'lending.comingSoon' => 'Lương In-app · Đến sớm',
			'lending.comingSoonDescription' => 'Bạn có thể sử dụng thư viện của bạn trong Libby trong khi chúng tôi kết thúc kết nối nó.',
			'lending.suspendHold' => 'Tạm dừng đặt trước',
			'lending.resumeHold' => 'Tiếp tục đặt trước',
			'lending.suspendMessage' => 'Giữ vị trí trong hàng chờ và để người đọc tiếp theo mượn bản này? Bạn có thể tiếp tục lượt đặt trước sau.',
			'lending.resumeMessage' => 'Tiếp tục lượt đặt trước này để thư viện có thể cung cấp bản sẵn có tiếp theo cho bạn?',
			'lending.editEmail' => 'Thay đổi thông báo email',
			'audiobook.syncTitle' => 'Đọc & lắng nghe Sync',
			'audiobook.syncHelp' => 'Giữ vị trí đọc, nghe vị trí, trạng thái hoàn thành, sổ ghi chép và ghi chú trên thiết bị của bạn. Chọn một tài khoản lưu trữ được gắn và sử dụng cùng mã đồng bộ trên mỗi thiết bị. Đọc và nghe vẫn riêng biệt.',
			'audiobook.addSyncSource' => 'Thêm Google Drive, OneDrive, Dropbox, WebDAV hoặc S3 vào tệp và sách trước.',
			'audiobook.syncDestination' => 'Tài khoản lưu trữ Sync',
			'audiobook.syncFolder' => 'Sync folder hoặc prefix',
			'audiobook.syncFolderHelp' => 'Sử dụng một thư mục riêng biệt hiện có trong nguồn WebDAV của bạn, hoặc một tiền lệ S3 dành riêng.',
			'audiobook.syncCode' => 'Mã đồng bộ riêng',
			'audiobook.syncCodeHelp' => 'Tạo một mã trên thiết bị đầu tiên của bạn, sau đó nhập mã đó trên các thiết bị khác của bạn. giữ một bản sao riêng: đó là chìa khóa cho trạng thái mã hóa của bạn. Sử dụng mã khác nhau cho mỗi người.',
			'audiobook.showCode' => 'Hiển thị hoặc ẩn mã đồng bộ',
			'audiobook.newSyncCode' => 'Tạo một mã đồng bộ mới',
			'audiobook.saveSync' => 'Save và Sync',
			'audiobook.disableSync' => 'Tắt sync trên thiết bị này',
			'audiobook.syncSourceDisconnect' => 'Xóa nguồn này sẽ tắt đọc và nghe đồng bộ ở đây. các tệp đồng bộ mã hóa sẽ ở lại trong nhà cung cấp.',
			'audiobook.syncReconnect' => 'Kết nối lại tài khoản lưu trữ',
			'audiobook.lastSynced' => ({required Object time}) => 'Kết quả tìm kiếm tại ${time}',
			'audiobook.syncPrivacy' => 'Chỉ mã hóa tiến bộ và ghi chú được lưu trữ. Audio và ebook tập tin, tài khoản tokens và mật khẩu không được tải lên. Google Drive và OneDrive sử dụng lưu trữ ứng dụng; Dropbox sử dụng PlezyNG Sync. Khả năng đồng bộ có thể yêu cầu thêm truy cập viết. Trong khi bật, điểm đến này sở hữu tiến bộ đồng bộ; tiến bộ máy chủ vẫn riêng biệt. Khả năng đồng bộ tắt giữ lịch sử địa phương và trạng thái từ xa.',
			'audiobook.syncConflicts' => 'Chọn nơi để lặp lại',
			'audiobook.conflictHelp' => 'Những thay đổi này được thực hiện độc lập.Chọn vị trí hoặc phiên bản đánh dấu để giữ.Một thời gian sau hoặc tỷ lệ cao hơn không tự động giành chiến thắng.',
			'audiobook.syncDevice' => ({required Object device}) => 'Thiết bị ${device}',
			'audiobook.syncUnknownDevice' => 'Thiết bị chưa biết',
			'audiobook.deletedBookmark' => 'Bookmark bị xóa',
			'audiobook.finished' => 'Kết thúc',
			'audiobook.readingPosition' => ({required Object percent}) => 'Đọc · ${percent}%',
			'audiobook.chapterTimeline' => 'Chương tiến bộ',
			'audiobook.bookTimeline' => 'Toàn bộ sách tiến bộ',
			'audiobook.bookRemaining' => ({required Object time}) => 'Thời gian còn lại trong cuốn sách này: ${time}',
			'audiobook.chapterRemaining' => ({required Object time}) => 'Thời gian còn lại trong chương này: ${time}',
			'audiobook.unknownRemaining' => 'Tổng thời gian có sẵn khi các phần được chơi',
			'audiobook.undoSeek' => 'tìm kiếm cuối cùng',
			'audiobook.customSpeed' => 'Tốc độ playback tùy chỉnh',
			'audiobook.speedHelp' => 'Chọn tốc độ từ 0.25× đến 4×.',
			'audiobook.apply' => 'Ứng dụng',
			'audiobook.customSleep' => 'Thời gian giấc ngủ tùy chỉnh',
			'audiobook.sleepMinutes' => 'Thời gian (1 – 1440)',
			'audiobook.sleepChapters' => ({required Object count}) => 'Ngừng sau các chương ${count}',
			'audiobook.extendSleep' => 'Thêm 5 phút',
			'audiobook.sleepRemaining' => ({required Object time}) => 'Thời gian ngủ: ${time}',
			'audiobook.useDefaults' => 'Sử dụng các điều khiển lắng nghe này cho các cuốn sách mới',
			'audiobook.librarySort' => 'sort sách',
			'audiobook.sortTitle' => 'Tiêu đề',
			'audiobook.sortAuthor' => 'Tác giả',
			'audiobook.sortNarrator' => 'Nữ diễn viên',
			'audiobook.sortSeries' => 'Lệnh Series',
			'audiobook.sortRecent' => 'Gần đây mở',
			'audiobook.statusFilter' => 'Đọc Status',
			'audiobook.statusAll' => 'Tất cả sách',
			'audiobook.statusNew' => 'Không bắt đầu',
			'audiobook.statusProgress' => 'trong tiến bộ',
			'audiobook.statusFinished' => 'Kết thúc',
			'audiobook.goToTime' => 'Đi đến thời gian',
			'audiobook.timeHelp' => 'Thời gian: phút: giây, hoặc phút: giây',
			'audiobook.recoveryHelp' => 'Xuất một bản sao được mã hóa gần đây trước khi di chuyển hoặc sửa chữa dữ liệu đồng bộ. nhập khẩu kết hợp với trạng thái hiện tại; họ không bao giờ thay thế lịch sử đồng bộ địa phương. Giữ mã đồng bộ riêng biệt.',
			'audiobook.recoveryExport' => 'Xuất khẩu file recovery mã hóa',
			'audiobook.recoveryImport' => 'nhập file recovery mã hóa',
			'audiobook.recoveryImportConfirm' => 'Kết hợp tệp phục hồi mã hóa này với các vị trí đọc và ghi chú hiện tại? Lịch sử hiện có sẽ được giữ lại. Thư viện chia sẻ và ID mục không bao gồm; thiết lập ID phù hợp trên mỗi thiết bị trước khi nhập khẩu.',
			'audiobook.recoveryExported' => 'Tệp phục hồi mã hóa đã được lưu.',
			'audiobook.recoveryImported' => 'Dữ liệu phục hồi kết hợp.',
			'sourceSetup.savedCertificate' => 'Chứng chỉ máy chủ đã lưu',
			'sourceSetup.nfsEndpointInvalid' => 'Nhập URL NFS, chẳng hạn nfs://nas:2049/export.',
			'sourceSetup.dlnaNone' => 'Không tìm thấy máy chủ DLNA. Hãy nhập thủ công URL mô tả thiết bị.',
			'sourceSetup.dlnaServers' => 'Máy chủ đa phương tiện DLNA',
			'sourceSetup.dlnaUnavailable' => 'Không thể dò tìm DLNA trên mạng này. Hãy nhập thủ công URL mô tả thiết bị.',
			'sourceSetup.dlnaSearching' => 'Đang tìm máy chủ DLNA trên mạng cục bộ',
			'sourceSetup.networkSearching' => 'Đang tìm trên mạng cục bộ…',
			'sourceSetup.dlnaDiscover' => 'Dò tìm máy chủ DLNA',
			'sourceSetup.dlnaHelp' => 'Việc dò tìm phụ thuộc vào multicast trên mạng cục bộ. Nếu không thấy máy chủ, hãy nhập URL mô tả thiết bị của máy chủ đó ở trên.',
			'sourceSetup.dlnaRoot' => 'ID đối tượng DLNA; để trống để dùng thư mục gốc của thiết bị.',
			'sourceSetup.passwordOrKey' => 'Nhập mật khẩu hoặc thêm khóa riêng bên dưới.',
			'sourceSetup.sshFingerprint' => 'Dấu vân tay SHA256 của khóa máy chủ SSH',
			'sourceSetup.sshFingerprintHelp' => 'Xác minh với quản trị viên máy chủ. Trên máy chủ, chạy ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub và dùng giá trị SHA256.',
			'sourceSetup.sshFingerprintKeep' => 'Để trống để giữ dấu vân tay đang được ghim, hoặc nhập dấu vân tay máy chủ mới.',
			'sourceSetup.sshAuthentication' => 'Xác thực SSH bằng khóa công khai',
			'sourceSetup.sshAuthenticationHelp' => 'Không bắt buộc; cũng hỗ trợ xác thực bằng mật khẩu.',
			'sourceSetup.privateKey' => 'Khóa riêng (định dạng PEM hoặc OpenSSH)',
			'sourceSetup.privateKeyPassphrase' => 'Cụm mật khẩu của khóa riêng',
			'sourceSetup.nfsMountPort' => 'Cổng TCP của dịch vụ gắn kết NFS',
			'sourceSetup.nfsMountPortHelp' => 'Mặc định: 20048',
			'sourceSetup.nfsUserId' => 'ID người dùng NFS (AUTH_SYS)',
			'sourceSetup.nfsUserIdHelp' => 'Mặc định: 1000. Dùng ID được vùng chia sẻ NFS trên NAS cho phép.',
			'sourceSetup.nfsGroupId' => 'ID nhóm NFS (AUTH_SYS)',
			'sourceSetup.nfsGroupIdHelp' => 'Mặc định: 1000. Dùng ID nhóm được vùng chia sẻ NFS trên NAS cho phép.',
			'sourceSetup.nfsEncryption' => 'Bắt buộc mã hóa NFS (RPC-with-TLS)',
			'sourceSetup.nfsEncryptionHelp' => 'Bắt buộc dùng TLS 1.3 cho NFS và dịch vụ gắn kết. Nếu NAS không hỗ trợ, kết nối sẽ bị từ chối.',
			'sourceSetup.nfsTrustCertificate' => 'CA NFS tùy chỉnh hoặc chứng chỉ máy chủ (PEM, không bắt buộc)',
			'sourceSetup.nfsTrustHelp' => 'Để trống để dùng các chứng chỉ được thiết bị này tin cậy. Nếu cần, thêm chứng chỉ của CA riêng hoặc chứng chỉ máy chủ tự ký; các tên trong chứng chỉ phải khớp với máy chủ trong URL NFS.',
			'sourceSetup.nfsTrustInvalid' => 'Dùng chứng chỉ CA hoặc máy chủ ở định dạng PEM. Không kèm khóa riêng.',
			'sourceSetup.addTrustCertificate' => 'Thêm chứng chỉ tin cậy tùy chỉnh',
			'sourceSetup.replaceTrustCertificate' => 'Thay chứng chỉ tùy chỉnh đã lưu',
			'sourceSetup.nfsTlsHelp' => 'RPC-with-TLS dùng các cổng thông thường của NFS và dịch vụ gắn kết, đồng thời yêu cầu NAS hỗ trợ RFC 9289. Bắt buộc dùng TLS 1.3. Tên máy chủ hoặc địa chỉ IP phải khớp với chứng chỉ. AUTH_SYS UID/GID vẫn áp dụng trong kênh được mã hóa.',
			'sourceSetup.clientCertificate' => 'Chứng chỉ máy khách (không bắt buộc)',
			'sourceSetup.clientCertificateHelp' => 'Cho phép NAS xác thực máy khách này; ID AUTH_SYS vẫn phụ thuộc vào chính sách của vùng chia sẻ NFS trên NAS.',
			'sourceSetup.savedIdentity' => 'Sẽ dùng danh tính máy khách đã lưu.',
			'sourceSetup.replaceIdentity' => 'Thay danh tính máy khách đã lưu',
			'sourceSetup.chooseIdentity' => 'Chọn danh tính máy khách PKCS#12',
			'sourceSetup.identityPassphrase' => 'Cụm mật khẩu của danh tính máy khách',
			'sourceSetup.identityPassphraseHelp' => 'Để trống nếu tệp không có cụm mật khẩu.',
			'sourceSetup.removeIdentity' => 'Xóa danh tính máy khách đã lưu nếu có',
			'sourceSetup.identityStorageHelp' => 'Danh tính máy khách được lưu trong kho thông tin xác thực đã mã hóa của nguồn. Giữ nguyên phần này để giữ lại danh tính đã lưu.',
			'sourceSetup.nfsLimitations' => 'NFSv3 chỉ đọc qua TCP. Không có RPC-with-TLS thì lưu lượng NFS không được mã hóa. NAS phải cho phép các ID AUTH_SYS đã chọn và các cổng máy khách không cần đặc quyền (thường gọi là tùy chọn xuất “insecure”). Không hỗ trợ NFSv4 và UDP.',
			'sourceSetup.nfsSetupHelp' => 'Trợ giúp thiết lập NFS',
			'sourceSetup.nfsSetupHint' => 'Kiểm tra các thiết lập này nếu không mở được kết nối.',
			'sourceSetup.nfsSetupDetails' => 'Dùng vùng chia sẻ NFSv3 qua TCP. Khi bắt buộc mã hóa, cả dịch vụ NFS và dịch vụ gắn kết phải hỗ trợ RPC-with-TLS. Để trống chứng chỉ tùy chỉnh nếu chứng chỉ máy chủ được thiết bị này tin cậy, hoặc thêm chứng chỉ CA hay chứng chỉ tự ký của NAS. Tên trong chứng chỉ phải khớp với máy chủ của điểm cuối. Nếu NAS yêu cầu TLS hai chiều, hãy thêm danh tính máy khách PKCS#12 của nó. Cuối cùng, xác nhận vùng chia sẻ cho phép AUTH_SYS UID/GID đã cấu hình và chính sách cổng máy khách.',
			'sourceSetup.ftpHelp' => 'FTP dùng chế độ thụ động. Dùng ftp:// cho FTP không mã hóa, ftpes:// cho TLS tường minh, hoặc ftps:// cho TLS (ngầm định trên cổng 990; tường minh trên các cổng khác).',
			'sourceSetup.openSubtitles' => 'OpenSubtitles',
			'sourceSetup.subtitleSetup' => 'Tìm phụ đề tùy chọn cho các video riêng lẻ.',
			'sourceSetup.apiKey' => 'Khóa API',
			'sourceSetup.optionalUsername' => 'Tên người dùng của tài khoản (không bắt buộc)',
			'sourceSetup.optionalPassword' => 'Mật khẩu tài khoản (không bắt buộc)',
			'sourceSetup.subtitlePrivacy' => 'Lấy khóa API từ opensubtitles.com. Tìm kiếm gửi tiêu đề video và các ID IMDb/TMDB có sẵn, không bao giờ gửi tệp video. Khóa và thông tin xác thực tài khoản tùy chọn được mã hóa cùng nguồn này.',
			'sourceSetup.automaticMetadata' => 'Siêu dữ liệu video trực tuyến tự động',
			'sourceSetup.metadataPrivacy' => 'Chỉ gửi tiêu đề/năm từ tên tệp và số tập hoặc một ID NFO, không bao giờ gửi nội dung đa phương tiện hay thông tin xác thực. Các trường NFO vẫn được ưu tiên.',
			'sourceSetup.nfsEncryptionFailure' => 'Với NFS được mã hóa, kiểm tra hỗ trợ RFC 9289 và TLS 1.3 trên cả hai dịch vụ NAS, tên trong chứng chỉ và UID/GID của vùng chia sẻ. PlezyNG sẽ không thử lại kết nối này khi không mã hóa.',
			'sourceSetup.sourceConnecting' => 'Đang kết nối đến nguồn',
			'sourceSetup.metadataSearchPrivacy' => 'Lượt tìm tiêu đề này được gửi đến Trakt. Chỉ tiêu đề bạn nhập được gửi đi, không phải video hay thông tin xác thực của nguồn.',
			'sourceSetup.chooseMatch' => 'Chọn kết quả phù hợp',
			'sourceSetup.metadataMatchHelp' => 'Kiểm tra tiêu đề và năm trước khi chọn. Trakt nhận tiêu đề tìm kiếm; video vẫn ở nguồn của nó.',
			'sourceSetup.metadataNoMatches' => 'Không tìm thấy tiêu đề trực tuyến phù hợp. Hãy thử tiêu đề khác.',
			'sourceSetup.metadataSearch' => 'Tìm siêu dữ liệu trực tuyến',
			'sourceSetup.metadataLoading' => 'Đang tra cứu thông tin phim và chương trình TV trực tuyến…',
			'sourceSetup.metadataFromTrakt' => 'Siêu dữ liệu trực tuyến từ Trakt',
			'sourceSetup.metadataNoAutomaticMatch' => 'Không tự động tìm thấy tiêu đề phù hợp. Hãy tìm tiêu đề để chọn kết quả.',
			'sourceSetup.metadataFailed' => 'Không tải được siêu dữ liệu trực tuyến. Vẫn có thể phát và xem thông tin cục bộ.',
			'sourceSetup.videoDetailsLoading' => 'Đang tải thông tin video',
			'sourceSetup.subtitleKeyRequired' => 'Cần có khóa API OpenSubtitles',
			'sourceSetup.subtitleKeyHelp' => 'Chỉnh sửa nguồn tệp này và thêm khóa API OpenSubtitles trong phần cài đặt phụ đề tùy chọn.',
			'sourceSetup.subtitleSearchFailed' => 'Tìm phụ đề thất bại. Kiểm tra khóa API, kết nối và quyền truy cập dịch vụ.',
			'sourceSetup.subtitleApplyFailed' => 'Không thể tải xuống hoặc áp dụng phụ đề này. Kiểm tra kết nối và thử kết quả khác.',
			'sourceSetup.subtitleSearch' => 'Tìm trên OpenSubtitles',
			'sourceSetup.subtitleSearchPrivacy' => 'Tìm kiếm dùng tiêu đề và các ID IMDb/TMDB có sẵn. Tệp video vẫn ở nguồn của nó. Trước khi chọn, hãy kiểm tra ngôn ngữ, nhãn phụ đề bắt buộc hoặc dành cho người khiếm thính, và điểm đánh giá.',
			'sourceSetup.movieOrShow' => 'Phim hoặc chương trình TV',
			'sourceSetup.subtitleTitleHint' => 'Nhập tiêu đề để thu hẹp kết quả',
			'sourceSetup.subtitleLanguage' => 'Ngôn ngữ phụ đề',
			'sourceSetup.subtitleSearching' => 'Đang tìm trên OpenSubtitles',
			'sourceSetup.subtitleNoMatches' => 'Không tìm thấy phụ đề phù hợp. Thử tiêu đề hoặc ngôn ngữ khác.',
			'sourceSetup.downloadSubtitle' => 'Tải phụ đề',
			'sourceSetup.subtitle' => 'Phụ đề',
			'sourceSetup.nfsTlsRequired' => 'Bắt buộc có RPC-with-TLS',
			'sourceSetup.nfsUnencrypted' => 'NFS không mã hóa',
			'sourceSetup.tlsEncrypted' => 'Được mã hóa bằng TLS',
			'sourceSetup.ftpPlain' => 'FTP không mã hóa',
			'sourceSetup.sshPinned' => 'SSH được mã hóa · khóa máy chủ đã ghim',
			'sourceSetup.smbEncrypted' => 'Mã hóa SMB3 bật',
			'sourceSetup.smbUnencrypted' => 'Mã hóa SMB3 tắt',
			'sourceSetup.httpUnencrypted' => 'HTTP không mã hóa đường truyền',
			'sourceSetup.checkEndpointSecurity' => 'Kiểm tra bảo mật điểm cuối',
			'sourceSetup.fieldRequired' => ({required Object label}) => '${label} là bắt buộc.',
			'sourceSetup.integerRange' => ({required Object label, required Object min, required Object max}) => 'Nhập ${label} từ ${min} đến ${max}.',
			'sourceSetup.replaceFile' => ({required Object name}) => 'Thay thế ${name}',
			'sourceSetup.selectedIdentity' => ({required Object name}) => 'Danh tính máy khách đã chọn: ${name}',
			'sourceSetup.subtitleRating' => ({required Object rating}) => 'Điểm đánh giá ${rating}',
			'sourceSetup.subtitleDownloading' => ({required Object title}) => 'Đang tải phụ đề: ${title}',
			'sourceSetup.sharedEntryPair' => 'Cặp bài này',
			'sourceSetup.sharedEntryPairHelp' => 'Nhập ID tương tự cho mục này trên mỗi thiết bị. Sử dụng một định dạng chia sẻ ổn định hoặc tạo một và sao chép nó vào mục phù hợp. tiến bộ cặp chỉ khi các loại tệp phiên bản, kích thước, và đơn đặt hàng tương ứng. Blank xóa bản đồ này.',
			'sourceSetup.sharedEntryId' => 'chia sẻ item ID',
			'sourceSetup.generateSharedEntryId' => 'Tạo ID mục chia sẻ',
			'sourceSetup.sharedLibraryId' => 'ID thư viện chia sẻ (tùy chọn)',
			'sourceSetup.sharedLibraryHelp' => 'Sử dụng ID tương tự trên các thiết bị mở cùng một thư viện. ID công cộng này giúp mang lại tiến bộ đọc và ghi chú qua các kết nối nguồn khác nhau; nó không phải là mật khẩu. Khi nhà cung cấp sử dụng ID mục khác nhau, cặp những mục từ màn hình chi tiết của họ.',
			'sourceSetup.sharedLibraryInvalid' => 'Sử dụng 8-100 lá thư, số lượng, điểm, subscores hoặc hyphens.',
			'sourceSetup.generateSharedLibraryId' => 'Tạo một ID thư viện chia sẻ',
			'sourceSetup.nfsReadAhead' => 'NFS read-ahead yêu cầu',
			'sourceSetup.nfsReadAheadHelp' => 'Đọc song song nhiều hơn có thể cải thiện khả năng thông qua trên một NAS nhanh hoặc mạng lưới. sử dụng 1 nếu máy chủ giới hạn các yêu cầu tương đương.',
			'sourceSetup.nfsReadTest' => 'Đánh giá hiệu suất NFS',
			'sourceSetup.nfsReadTestHelp' => 'Đọc lên đến 64 MiB từ tệp lớn nhất để đo kết nối NAS này.',
			'sourceSetup.nfsQualificationResult' => 'NFS đọc đo lường',
			'sourceSetup.nfsReadBytes' => 'Dữ liệu đọc',
			'sourceSetup.nfsReadSpeed' => 'Tốc độ đo',
			'sourceSetup.nfsReadRequests' => 'Đọc yêu cầu',
			'sourceSetup.sharedEntryConflict' => 'ID mục được chia sẻ này đã được kết hợp với một mục khác trong thư viện này.',
			'comics.fitHeight' => 'Vừa chiều cao',
			'comics.readingMode' => 'Chế độ đọc',
			'comics.paged' => 'Trang',
			'comics.webtoon' => 'Cuộn liên tục',
			'comics.coverAlone' => 'Hiển thị bìa riêng',
			'comics.splitWide' => 'Chia trang rộng',
			'comics.splitWideHelp' => 'Hiển thị riêng từng nửa theo thứ tự đọc. Tạm dừng hiển thị hai trang cạnh nhau khi bật tùy chọn này.',
			'comics.thumbnails' => 'Hình thu nhỏ của trang',
			'comics.controlsHelp' => 'Vuốt để lật trang. Chạm hai lần để đổi cách vừa trang. Khi cuộn liên tục, vuốt dọc hoặc dùng Page Up và Page Down.',
			'comics.savedForComic' => 'Cài đặt hiển thị được ghi nhớ cho truyện tranh này trong hồ sơ này.',
			'comics.readLists' => 'Danh sách đọc',
			'comics.collections' => 'Bộ sưu tập',
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
			_ => null,
		} ?? switch (path) {
			'games.libraryHint' => 'Choose a computer to connect and load its games. Once connected, choose a game to play inside PlezyNG.',
			'games.touchControls' => 'On-screen controller',
			'games.touchDescription' => 'Show the on-screen controller during a stream. It supports multiple fingers, sticks, buttons and triggers.',
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
			'games.helpBody' => 'Enable Games for your profile, choose a computer and approve the first connection. Steam can open Big Picture or launch a saved game shortcut inside PlezyNG on receivers that support it. Connect Companion Remote to combine installed games from your computers in one library. Steam pairing does not grant access to a private account library.\n\nSteam receivers are experimental on Android, Linux and Apple. The stream menu provides controller, audio and connection controls. Pyrowave is an optional codec on compatible Android and Apple receivers and needs a fast network.\n\nPairing requires the host’s approval. Sunshine QR codes open its PIN page without carrying credentials. For access away from home, use the computer’s VPN address. Automatic discovery normally stays on the local network.\n\nDisconnecting leaves the game running on the computer.',
			'games.cancel' => 'Cancel',
			'games.scanning' => 'Looking for computers…',
			'games.saveShortcut' => 'Save shortcut',
			'games.manualHint' => 'For Moonlight use the host’s GameStream HTTP port (usually 47989), not its web settings port. Steam normally advertises on 27036.',
			'games.engineUnavailable' => 'In-app streaming is not available here yet',
			'games.nativeEnginePending' => 'This build does not include a streaming engine for this platform. You can save the computer, but it cannot play here yet.',
			'games.steamEnginePending' => 'This build does not include an embedded Steam receiver for this device. You can browse your library and manage computers. Playing here requires a build with a compatible receiver.',
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
			'deepLinks.invalid' => 'Liên kết Plezy này không hợp lệ.',
			'deepLinks.profileNotFound' => ({required Object profile}) => 'Không có hồ sơ phù hợp với "${profile}".',
			'deepLinks.serverUnavailable' => 'Tôi không thể truy cập máy chủ cho liên kết này.',
			'deepLinks.notFound' => 'Tôi không thể tìm thấy tiêu đề này trong thư viện của bạn.',
			'deepLinks.unsupportedItem' => 'Link này không thể chơi được.',
			'deepLinks.noLiveTv' => 'Không có máy chủ TV trực tiếp có sẵn cho liên kết này.',
			'deepLinks.channelNotFound' => ({required Object channel}) => 'Không thể tìm thấy kênh "${channel}".',
			'deepLinks.showLink' => 'Hiển thị link',
			'deepLinks.showProfileLink' => 'Hiển thị profile link',
			'deepLinks.dialogTitle' => 'liên kết',
			'deepLinks.showHint' => 'Mở liên kết này chơi phần tiếp theo. Thêm &mode=shuffle để chơi chương trình trên shuffle.',
			'deepLinks.movieHint' => 'Mở liên kết này chơi bộ phim.',
			'deepLinks.episodeHint' => 'Mở liên kết này chơi phần này.',
			'deepLinks.profileHint' => 'Mở liên kết này chuyển đổi đến hồ sơ này.',
			'deepLinks.openAsProfile' => ({required Object name}) => 'Mở như ${name}',
			'deepLinks.copy' => 'sao chép',
			'deepLinks.copied' => 'Link copy',
			'householdSetup.title' => 'Thiết lập gia đình',
			'issueReport.title' => 'Báo cáo sự cố',
			'issueReport.instructions' => 'Quét mã QR để mở bản nháp GitHub đã điền sẵn. Hãy xem lại và chỉ gửi khi bạn sẵn sàng.',
			'issueReport.privacy' => 'Bản nháp gồm phiên bản ứng dụng, nền tảng và số lượng kết nối. Bản nháp không có địa chỉ máy chủ, tên tài khoản hoặc hồ sơ, tiêu đề nội dung hay đường dẫn tệp.',
			'issueReport.logPrivacy' => 'Nhật ký là tùy chọn. Hãy xem lại trước khi tải lên. ID nhật ký được thêm vào bản nháp, có thể hiển thị công khai.',
			'issueReport.openDraft' => 'Mở bản nháp GitHub',
			_ => null,
		};
	}
}
