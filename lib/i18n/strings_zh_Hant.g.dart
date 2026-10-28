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
import 'strings_zh.g.dart';

// Path: <root>
class TranslationsZhHant extends TranslationsZh with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsZhHant({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zhHant,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <zh-Hant>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsZhHant _root = this; // ignore: unused_field

	@override 
	TranslationsZhHant $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsZhHant(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$zh_Hant app = _Translations$app$zh_Hant._(_root);
	@override late final _Translations$appIcon$zh_Hant appIcon = _Translations$appIcon$zh_Hant._(_root);
	@override late final _Translations$auth$zh_Hant auth = _Translations$auth$zh_Hant._(_root);
	@override late final _Translations$common$zh_Hant common = _Translations$common$zh_Hant._(_root);
	@override late final _Translations$screens$zh_Hant screens = _Translations$screens$zh_Hant._(_root);
	@override late final _Translations$update$zh_Hant update = _Translations$update$zh_Hant._(_root);
	@override late final _Translations$settings$zh_Hant settings = _Translations$settings$zh_Hant._(_root);
	@override late final _Translations$themeEditor$zh_Hant themeEditor = _Translations$themeEditor$zh_Hant._(_root);
	@override late final _Translations$search$zh_Hant search = _Translations$search$zh_Hant._(_root);
	@override late final _Translations$hotkeys$zh_Hant hotkeys = _Translations$hotkeys$zh_Hant._(_root);
	@override late final _Translations$fileInfo$zh_Hant fileInfo = _Translations$fileInfo$zh_Hant._(_root);
	@override late final _Translations$mediaMenu$zh_Hant mediaMenu = _Translations$mediaMenu$zh_Hant._(_root);
	@override late final _Translations$rateSheet$zh_Hant rateSheet = _Translations$rateSheet$zh_Hant._(_root);
	@override late final _Translations$accessibility$zh_Hant accessibility = _Translations$accessibility$zh_Hant._(_root);
	@override late final _Translations$tooltips$zh_Hant tooltips = _Translations$tooltips$zh_Hant._(_root);
	@override late final _Translations$audioTracks$zh_Hant audioTracks = _Translations$audioTracks$zh_Hant._(_root);
	@override late final _Translations$videoControls$zh_Hant videoControls = _Translations$videoControls$zh_Hant._(_root);
	@override late final _Translations$messages$zh_Hant messages = _Translations$messages$zh_Hant._(_root);
	@override late final _Translations$subtitlingStyling$zh_Hant subtitlingStyling = _Translations$subtitlingStyling$zh_Hant._(_root);
	@override late final _Translations$mpvConfig$zh_Hant mpvConfig = _Translations$mpvConfig$zh_Hant._(_root);
	@override late final _Translations$dialog$zh_Hant dialog = _Translations$dialog$zh_Hant._(_root);
	@override late final _Translations$profiles$zh_Hant profiles = _Translations$profiles$zh_Hant._(_root);
	@override late final _Translations$connections$zh_Hant connections = _Translations$connections$zh_Hant._(_root);
	@override late final _Translations$accountPreferences$zh_Hant accountPreferences = _Translations$accountPreferences$zh_Hant._(_root);
	@override late final _Translations$discover$zh_Hant discover = _Translations$discover$zh_Hant._(_root);
	@override late final _Translations$errors$zh_Hant errors = _Translations$errors$zh_Hant._(_root);
	@override late final _Translations$libraries$zh_Hant libraries = _Translations$libraries$zh_Hant._(_root);
	@override late final _Translations$about$zh_Hant about = _Translations$about$zh_Hant._(_root);
	@override late final _Translations$serverSelection$zh_Hant serverSelection = _Translations$serverSelection$zh_Hant._(_root);
	@override late final _Translations$hubDetail$zh_Hant hubDetail = _Translations$hubDetail$zh_Hant._(_root);
	@override late final _Translations$logs$zh_Hant logs = _Translations$logs$zh_Hant._(_root);
	@override late final _Translations$startup$zh_Hant startup = _Translations$startup$zh_Hant._(_root);
	@override late final _Translations$licenses$zh_Hant licenses = _Translations$licenses$zh_Hant._(_root);
	@override late final _Translations$navigation$zh_Hant navigation = _Translations$navigation$zh_Hant._(_root);
	@override late final _Translations$explore$zh_Hant explore = _Translations$explore$zh_Hant._(_root);
	@override late final _Translations$liveTv$zh_Hant liveTv = _Translations$liveTv$zh_Hant._(_root);
	@override late final _Translations$collections$zh_Hant collections = _Translations$collections$zh_Hant._(_root);
	@override late final _Translations$playlists$zh_Hant playlists = _Translations$playlists$zh_Hant._(_root);
	@override late final _Translations$music$zh_Hant music = _Translations$music$zh_Hant._(_root);
	@override late final _Translations$watchTogether$zh_Hant watchTogether = _Translations$watchTogether$zh_Hant._(_root);
	@override late final _Translations$downloads$zh_Hant downloads = _Translations$downloads$zh_Hant._(_root);
	@override late final _Translations$shaders$zh_Hant shaders = _Translations$shaders$zh_Hant._(_root);
	@override late final _Translations$companionRemote$zh_Hant companionRemote = _Translations$companionRemote$zh_Hant._(_root);
	@override late final _Translations$videoSettings$zh_Hant videoSettings = _Translations$videoSettings$zh_Hant._(_root);
	@override late final _Translations$performanceOverlay$zh_Hant performanceOverlay = _Translations$performanceOverlay$zh_Hant._(_root);
	@override late final _Translations$externalPlayer$zh_Hant externalPlayer = _Translations$externalPlayer$zh_Hant._(_root);
	@override late final _Translations$metadataEdit$zh_Hant metadataEdit = _Translations$metadataEdit$zh_Hant._(_root);
	@override late final _Translations$matchScreen$zh_Hant matchScreen = _Translations$matchScreen$zh_Hant._(_root);
	@override late final _Translations$serverTasks$zh_Hant serverTasks = _Translations$serverTasks$zh_Hant._(_root);
	@override late final _Translations$trakt$zh_Hant trakt = _Translations$trakt$zh_Hant._(_root);
	@override late final _Translations$seerr$zh_Hant seerr = _Translations$seerr$zh_Hant._(_root);
	@override late final _Translations$services$zh_Hant services = _Translations$services$zh_Hant._(_root);
	@override late final _Translations$addServer$zh_Hant addServer = _Translations$addServer$zh_Hant._(_root);
	@override late final _Translations$cast$zh_Hant cast = _Translations$cast$zh_Hant._(_root);
	@override late final _Translations$automation$zh_Hant automation = _Translations$automation$zh_Hant._(_root);
	@override late final _Translations$notifications$zh_Hant notifications = _Translations$notifications$zh_Hant._(_root);
	@override late final _Translations$appAccess$zh_Hant appAccess = _Translations$appAccess$zh_Hant._(_root);
	@override late final _Translations$detail$zh_Hant detail = _Translations$detail$zh_Hant._(_root);
	@override late final _Translations$watchLink$zh_Hant watchLink = _Translations$watchLink$zh_Hant._(_root);
	@override late final _Translations$homeLayout$zh_Hant homeLayout = _Translations$homeLayout$zh_Hant._(_root);
	@override late final _Translations$platform$zh_Hant platform = _Translations$platform$zh_Hant._(_root);
	@override late final _Translations$universalMedia$zh_Hant universalMedia = _Translations$universalMedia$zh_Hant._(_root);
	@override late final _Translations$fileSources$zh_Hant fileSources = _Translations$fileSources$zh_Hant._(_root);
	@override late final _Translations$lending$zh_Hant lending = _Translations$lending$zh_Hant._(_root);
	@override late final _Translations$audiobook$zh_Hant audiobook = _Translations$audiobook$zh_Hant._(_root);
	@override late final _Translations$sourceSetup$zh_Hant sourceSetup = _Translations$sourceSetup$zh_Hant._(_root);
	@override late final _Translations$comics$zh_Hant comics = _Translations$comics$zh_Hant._(_root);
	@override late final _Translations$games$zh_Hant games = _Translations$games$zh_Hant._(_root);
	@override late final _Translations$deepLinks$zh_Hant deepLinks = _Translations$deepLinks$zh_Hant._(_root);
	@override late final _Translations$householdSetup$zh_Hant householdSetup = _Translations$householdSetup$zh_Hant._(_root);
	@override late final _Translations$issueReport$zh_Hant issueReport = _Translations$issueReport$zh_Hant._(_root);
}

// Path: app
class _Translations$app$zh_Hant extends Translations$app$zh {
	_Translations$app$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: appIcon
class _Translations$appIcon$zh_Hant extends Translations$appIcon$zh {
	_Translations$appIcon$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '應用程式圖示';
	@override String get defaultIcon => '預設';
	@override String get current => '目前圖示';
	@override String get locked => '終身訪問需要';
	@override String get lockedHint => '啟動 7 天試用或終身解鎖 PlezyNG 以使用替代圖示。';
	@override String get changeFailed => '無法變更應用程式圖示';
	@override String get launcherHint => '離開 PlezyNG 後，新圖示就會出現在主畫面上。';
	@override String get tvLauncherHint => '離開 PlezyNG 後就會顯示新橫幅。在電視重新啟動前，Android TV 可能仍會顯示舊橫幅。';
	@override late final _Translations$appIcon$names$zh_Hant names = _Translations$appIcon$names$zh_Hant._(_root);
	@override String get description => '選擇由您的裝置啟動器顯示的圖示. 預覽顯示每個選項看起來如何。';
}

// Path: auth
class _Translations$auth$zh_Hant extends Translations$auth$zh {
	_Translations$auth$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => '使用 Plex 登入';
	@override String get showQRCode => '顯示 QR 碼';
	@override String get authenticate => '驗證';
	@override String get authenticationTimeout => '驗證逾時。請重試。';
	@override String get scanQRToSignIn => '掃描此 QR 碼以登入';
	@override String get waitingForAuth => '正在等待驗證…\n請在瀏覽器中登入。';
	@override String get useBrowser => '使用瀏覽器';
	@override String get or => '或';
	@override String connectToMediaBrowser({required Object product}) => '連線至 ${product}';
	@override String get quickConnect => '快速連線（Quick Connect）';
	@override String get useQuickConnect => '使用快速連線（Quick Connect）';
	@override String get quickConnectInstructions => '在 Jellyfin 中開啟快速連線並輸入此代碼。';
	@override String get quickConnectWaiting => '等待核准…';
	@override String get quickConnectCancel => '取消';
	@override String get quickConnectExpired => '快速連線代碼已過期。請重試。';
	@override String get localDataRecoveryRequired => 'PlezyNG 無法安全地復原本機登入資料與待處理的播放資料。請重新登入。';
	@override String get pinCheckRejected => 'Plex PIN 檢查遭到拒絕';
	@override String get connectToDirectPlex => '連線到本地伺服器 Plex';
}

// Path: common
class _Translations$common$zh_Hant extends Translations$common$zh {
	_Translations$common$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get cancel => '取消';
	@override String get save => '儲存';
	@override String get close => '關閉';
	@override String get closeMiniPlayer => '附近小型玩家';
	@override String get closeWorkspaceWindow => '附近視窗';
	@override String get returnToFullView => '回到全景';
	@override String get manageMediaSessions => '管理媒體會議';
	@override String get hideMediaSessions => '隱藏媒體會議';
	@override String get mediaSessions => '媒體會議';
	@override String get mediaSessionsHint => '選取工作階段可將它移到前景。停放會隱藏視窗，但讓工作階段保持開啟。返回會以完整檢視開啟工作階段；關閉則會結束工作階段。';
	@override String get sessionInWorkspace => '在工作場所';
	@override String get sessionParked => '停車';
	@override String get sessionFullscreen => '全螢幕';
	@override String get switchToNextWindow => '與下一個視窗交換';
	@override String get moveWindow => '移動視窗';
	@override String get finishMovingWindow => '結束移動視窗';
	@override String get moveWindowHint => '長壓和拖動視窗移動它. 這種控制也允許箭頭金鑰的運動。';
	@override String get movingWindowHelp => '拖到移動 · 投鍵調整 · 輸入儲存器 · 逃避取消';
	@override String get resizeWindow => '修復視窗';
	@override String get resizeWindowHint => '拖這個手套或使用箭頭鍵重新調整視窗。';
	@override String get workspaceWindowHint => '使用移動控制項，或長按並拖曳視窗來移動。使用調整大小把手來調整視窗大小。';
	@override String get workspacePaneHint => '選擇這個面板以集中它. 使用其全屏控制來擴充套件。';
	@override String workspaceWindowLabel({required Object title}) => '會議視窗: ${title}';
	@override String get workspaceTitleHint => '選取以聚焦。拖曳標題列可移動視窗；使用全螢幕按鈕可展開。';
	@override String get moveToSessionTray => '轉到Session Tray';
	@override String get moveToSessionTrayHint => '開啟此會議可用,而不顯示其視窗。';
	@override String get closeSessionHint => '關閉此視窗並結束會議。';
	@override String get sideBySideLayout => '交換到側面佈局';
	@override String get floatingWindows => '轉換為浮動視窗';
	@override String get clear => '清除';
	@override String get reset => '重設';
	@override String get later => '稍後';
	@override String get submit => '送出';
	@override String get confirm => '確認';
	@override String get retry => '重試';
	@override String get logout => '登出';
	@override String get unknown => '未知';
	@override String get refresh => '重新整理';
	@override String get yes => '是';
	@override String get no => '否';
	@override String get delete => '刪除';
	@override String get edit => '編輯';
	@override String get shuffle => '隨機播放';
	@override String get addTo => '新增至…';
	@override String get createNew => '新增';
	@override String get connect => '連線';
	@override String get disconnect => '中斷連線';
	@override String get play => '播放';
	@override String get pause => '暫停';
	@override String get resume => '繼續';
	@override String get error => '錯誤';
	@override String get search => '搜尋';
	@override String get home => '首頁';
	@override String get back => '返回';
	@override String get settings => '設定';
	@override String get mute => '靜音';
	@override String get ok => '確定';
	@override String get off => '關閉';
	@override String get options => '選項';
	@override String seasonNumber({required Object number}) => '第 ${number} 季';
	@override String episodeNumberTitle({required Object number, required Object title}) => '第 ${number} 集 — ${title}';
	@override String chapterNumber({required Object number}) => '第 ${number} 章';
	@override String get reconnect => '重新連線';
	@override String get viewAll => '查看全部';
	@override String get checkingNetwork => '正在檢查網路…';
	@override String get loadingServers => '正在載入伺服器…';
	@override String get connectingToServers => '正在連線伺服器…';
	@override String get startingOfflineMode => '正在啟動離線模式…';
	@override String get loading => '載入中…';
	@override String get fullscreen => '全螢幕';
	@override String get exitFullscreen => '退出全螢幕';
	@override String get pressBackAgainToExit => '再按一次返回以退出';
	@override late final _Translations$common$ratingSource$zh_Hant ratingSource = _Translations$common$ratingSource$zh_Hant._(_root);
	@override String get notAvailable => 'N/A';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
	@override late final _Translations$common$mediaKind$zh_Hant mediaKind = _Translations$common$mediaKind$zh_Hant._(_root);
}

// Path: screens
class _Translations$screens$zh_Hant extends Translations$screens$zh {
	_Translations$screens$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get licenses => '授權條款';
	@override String get switchProfile => '切換使用者';
	@override String get subtitleStyling => '字幕樣式';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => '日誌';
}

// Path: update
class _Translations$update$zh_Hant extends Translations$update$zh {
	_Translations$update$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get available => '有可用更新';
	@override String versionAvailable({required Object version}) => '版本 ${version} 已發佈';
	@override String currentVersion({required Object version}) => '目前版本：${version}';
	@override String get skipVersion => '跳過此版本';
	@override String get viewRelease => '查看版本詳情';
	@override String get latestVersion => '已安裝的版本為最新版本';
	@override String get checkFailed => '無法檢查更新';
}

// Path: settings
class _Translations$settings$zh_Hant extends Translations$settings$zh {
	_Translations$settings$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '設定';
	@override String get supportDeveloper => '贊助 PlezyNG';
	@override String get supportDeveloperDescription => '捐款支持開發';
	@override String get lifetimeAccess => 'PlezyNG 終身訪問';
	@override String get language => '語言';
	@override String get theme => '主題';
	@override String get appearance => '外觀';
	@override String get detailPage => '詳細頁面';
	@override String get themeSongsEnabled => '演奏主題歌曲';
	@override String get themeSongsEnabledDescription => '播放可用的主題歌曲,同時檢視媒體細節。';
	@override String get themeSongVolume => '主題歌曲 卷';
	@override String get videoPlayback => '影片播放';
	@override String get videoPlaybackDescription => '設定播放行為';
	@override String get advanced => '進階';
	@override String get episodePosterMode => '單集海報樣式';
	@override String get seriesPoster => '影集海報';
	@override String get seasonPoster => '單季海報';
	@override String get episodeThumbnail => '縮圖';
	@override String get showHeroSectionDescription => '在主畫面上顯示精選內容輪播區';
	@override String get secondsLabel => '秒';
	@override String get minutesLabel => '分鐘';
	@override String get secondsShort => '秒';
	@override String get minutesShort => '分';
	@override String durationHint({required Object min, required Object max}) => '輸入長度（${min}-${max}）';
	@override String get systemTheme => '系統預設';
	@override String get lightTheme => '淺色';
	@override String get darkTheme => '深色';
	@override String get oledTheme => 'OLED 純黑';
	@override String get emberTheme => '餘燼';
	@override String get glacierTheme => '冰河';
	@override String get forestTheme => '森林';
	@override String get plumTheme => '李子';
	@override String get paperTheme => '紙張';
	@override String get libraryDensity => '媒體庫版面配置密度';
	@override String get displayScale => '介面縮放';
	@override String get compact => '緊湊';
	@override String get comfortable => '舒適';
	@override String get gridSpacing => '網格間距';
	@override String get gridSpacingTight => '緊湊';
	@override String get gridSpacingNormal => '一般';
	@override String get gridSpacingSpacious => '寬鬆';
	@override String get tvCornerSpotlightBackdrop => '右上角焦點背景圖';
	@override String get tvCornerSpotlightBackdropDescription => '在右上角顯示焦點內容圖片，而非填滿整個畫面';
	@override String get viewMode => '檢視模式';
	@override String get gridView => '網格檢視';
	@override String get listView => '清單檢視';
	@override String get showHeroSection => '顯示精選內容區';
	@override String get showHomeBackdrop => '展示家居背景藝術作品';
	@override String get showHomeBackdropDescription => '展示大型藝術作品背後展示的家庭行';
	@override String get contentScreensaverEnabled => '內容螢幕儲存';
	@override String get contentScreensaverEnabledDescription => '顯示全屏藝術作品,應用程式已變成 idle';
	@override String get contentScreensaverDelay => '螢幕儲存後啟動';
	@override String get contentScreensaverLibraries => '圖書館螢幕';
	@override String get contentScreensaverLibrariesDescription => '選擇要用來提供螢幕保護程式圖片的媒體庫。若未選擇任何媒體庫，則會使用所有媒體庫的圖片。';
	@override String get contentScreensaverAllLibraries => '所有圖書館';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} 圖書館 選擇';
	@override String get contentScreensaverNoLibraries => '沒有連線媒體圖書館可用。';
	@override String get contentScreensaverDismissHint => '按下任何按鈕或按下取消';
	@override String get newEpisodeNotifications => '新事件通知';
	@override String get newEpisodeNotificationsDescription => '警告當新集新增到一個節目你被抓住時,檢查 Plezy 是開放的。';
	@override String get continueWatchingRowSize => '繼續觀看 序列大小';
	@override String continueWatchingRowSizeValue({required Object label}) => '${label} 卡片';
	@override String get rowSizeCompact => '緊湊';
	@override String get rowSizeStandard => '標準';
	@override String get rowSizeLarge => '大';
	@override String get continueWatchingAction => '繼續觀看操作';
	@override String get continueWatchingPlay => '播放影片';
	@override String get continueWatchingDetails => '開啟詳情頁';
	@override String get episodeAction => '單集操作';
	@override String get episodePlay => '播放';
	@override String get episodeDetails => '開啟詳情頁';
	@override String get useGlobalHubs => '使用首頁版面配置';
	@override String get useGlobalHubsDescription => '顯示統一的首頁推薦欄，否則使用各媒體庫的推薦內容。';
	@override String get showServerNameOnHubs => '在推薦欄顯示伺服器名稱';
	@override String get showServerNameOnHubsDescription => '一律在推薦區標題中顯示伺服器名稱。';
	@override String get groupLibrariesByServer => '依伺服器將媒體庫分組';
	@override String get groupLibrariesByServerDescription => '將側邊欄中的媒體庫依伺服器進行分組。';
	@override String get alwaysKeepSidebarOpen => '一律保持側邊欄展開';
	@override String get alwaysKeepSidebarOpenDescription => '側邊欄保持展開狀態，內容區域自動調整';
	@override String get showUnwatchedCount => '顯示未觀看數量';
	@override String get showUnwatchedCountDescription => '在影集和單季上顯示未觀看的集數';
	@override String get showWatchedIndicators => '顯示已觀看指示';
	@override String get showWatchedIndicatorsDescription => '在已觀看的電影、影集和單集上顯示勾選標記';
	@override String get showEpisodeNumberOnCards => '在卡片上顯示集數';
	@override String get showEpisodeNumberOnCardsDescription => '在單集卡片上顯示季和集編號';
	@override String get showSeasonPostersOnTabs => '在索引標籤上顯示單季海報';
	@override String get showSeasonPostersOnTabsDescription => '在每季標籤上方顯示該季海報';
	@override String get tvFullCardLayout => '完整 TV 卡片版面配置';
	@override String get tvFullCardLayoutDescription => '使用僅顯示圖片的 TV 卡片，並在圖片上疊加演員姓名';
	@override String get focusGlow => '焦點光暈';
	@override String get focusGlowDescription => '在獲得焦點的卡片周圍顯示柔和的光暈';
	@override String get visualEffects => '視覺效果';
	@override String get visualEffectsAuto => '自動';
	@override String get visualEffectsAutoDescription => '在效能較低的裝置上自動減少效果';
	@override String get visualEffectsFull => '完整效果';
	@override String get visualEffectsReduced => '簡化效果';
	@override String get visualEffectsReducedDescription => '減少動畫並使用較低解析度的封面圖片';
	@override String get hideSpoilers => '隱藏未觀看單集的劇透內容';
	@override String get hideSpoilersDescription => '模糊未觀看單集的縮圖與描述';
	@override String get playerBackend => '播放器引擎';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => '硬體解碼';
	@override String get hardwareDecodingDescription => '如果支援，使用硬體加速';
	@override String get playbackBuffer => '播放緩衝';
	@override String get playbackBufferAuto => '自動（建議）';
	@override String get playbackBufferLarge => '大';
	@override String get playbackBufferExtraLarge => '特大';
	@override String get playbackBufferDescription => '針對不穩定的連線緩衝更多內容。也受緩衝大小限制。';
	@override String get streamBufferSize => '布格大小';
	@override String streamBufferSizeValue({required Object size}) => '${size} MB';
	@override String get streamBufferSizeDescription => '直接播放時預先載入的影片量。轉碼播放以伺服器本身的轉碼緩衝區為限。0 = 自動';
	@override String get streamBufferSizeExoNote => '取代 Playback Buffer 設定時,在應用程式的記憶體限制中半個';
	@override String get streamBufferMegabytes => '梅加位元';
	@override String get defaultQualityTitle => '預設畫質';
	@override String get cellularQualityTitle => '行動網路上的預設畫質';
	@override String get remoteQualityTitle => '遠端播放質量';
	@override String get remoteQualitySameAsDefault => '與假設質量相同';
	@override String get cellularQualitySameAsDefault => '與預設畫質相同';
	@override String get directPlayCoveredQuality => '以原始畫質播放較小影片';
	@override String get directPlayCoveredQualityDescription => '已在畫質限制內的影片直接播放，而非轉碼';
	@override String get videoCodecs => '影片編解碼器';
	@override String get videoCodecsDescription => '未勾選的編解碼器將由伺服器轉碼';
	@override String get videoCodecsAlwaysAccepted => '一律接受';
	@override String get musicQualityTitle => '音樂品質';
	@override String get subtitleStyling => '字幕樣式';
	@override String get subtitleStylingDescription => '調整字幕外觀';
	@override String get smallSkipDuration => '短跳過時間';
	@override String get largeSkipDuration => '長跳過時間';
	@override String get rewindOnResume => '繼續播放時稍微倒轉';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(seconds,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} 秒',
	);
	@override String get defaultSleepTimer => '預設睡眠計時器';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(minutes,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} 分鐘',
	);
	@override String get rememberTrackSelections => '記住每部影集或電影的音訊與字幕選擇';
	@override String get chooseTracksBeforePlayback => '選擇音訊和字幕在播放前';
	@override String get chooseTracksBeforePlaybackDescription => '在每個影片開始之前,選擇源音訊和子標題跟蹤。';
	@override String get alwaysShowSubtitlesOnDevice => '總是顯示該裝置上的字幕';
	@override String get alwaysShowSubtitlesOnDeviceDescription => '當伺服器沒有選定的子標題時,選擇一個路徑,而此事永遠不會改變伺服器的偏好。';
	@override String get autoDownloadPreferredSubtitle => '福克斯缺少偏好語言字幕';
	@override String get autoDownloadPreferredSubtitleDescription => '選擇您所需的語言中的可用字幕,當地選擇;如果沒有字幕,請伺服器在支援時查詢一個字幕;選項將留在該裝置上。';
	@override String get rememberTrackSelectionsDescription => '記住每部影片的音軌與字幕選擇';
	@override String get rememberTrackSelectionsBackendRule => 'Plex 會按檔案將每個選擇儲存在伺服器上；Jellyfin 還會開啟帳戶的「記住選擇」；不支援 Emby';
	@override String get followServerTrackSelections => '使用伺服器為每集選擇的軌道';
	@override String get followServerTrackSelectionsDescription => '切換劇集時，套用伺服器上為該集選擇的音訊與字幕，而不是沿用目前選擇';
	@override String get resumeMusicOnLaunch => '記住音樂工作階段';
	@override String get resumeMusicOnLaunchDescription => '應用程式啟動時，將上次播放的歌曲在停止處以暫停狀態開啟';
	@override String get showChapterMarkersOnTimeline => '在進度條上顯示章節標記';
	@override String get showChapterMarkersOnTimelineDescription => '依章節分段顯示進度條';
	@override String get specialsOrdering => '特別篇依集數排序';
	@override String get specialsOrderingDescription => '特別篇在影集觀看順序中的播放位置';
	@override String get specialsOrderingServer => '依伺服器順序';
	@override String get specialsOrderingAirDate => '依播出日期交錯';
	@override String get specialsOrderingLast => '一般季數之後';
	@override String get clickVideoTogglesPlayback => '點選影片可切換播放或暫停';
	@override String get clickVideoTogglesPlaybackDescription => '點選影片即可播放或暫停，而不顯示控制面板。';
	@override String get videoPlayerControls => '影片播放器控制';
	@override String get keyboardShortcuts => '鍵盤快速鍵';
	@override String get keyboardShortcutsDescription => '自訂鍵盤快速鍵';
	@override String get videoPlayerNavigation => '影片播放器導覽';
	@override String get videoPlayerNavigationDescription => '使用方向鍵導覽影片播放器控制項';
	@override String get watchTogetherRelay => '一起看中繼伺服器';
	@override String get watchTogetherRelayDescription => '除非您自行設定，否則使用公開的 Open Watch Party 中繼伺服器';
	@override String get watchTogetherRelayHint => 'https://my-relay.example.com';
	@override String get watchTogetherRelayInvalid => '請輸入有效的 HTTP 或 HTTPS 中繼伺服器根網址。';
	@override String get crashReporting => '當機報告';
	@override String get crashReportingDescription => '傳送當機報告以協助改善應用程式';
	@override String get debugLogging => '偵錯日誌';
	@override String get debugLoggingDescription => '啟用詳細日誌記錄以便進行疑難排解';
	@override String get viewLogs => '查看日誌';
	@override String get viewLogsDescription => '查看應用程式日誌記錄';
	@override String get clearImageCache => '清除圖片快取';
	@override String get clearImageCacheDescription => '清除已快取的封面圖片與縮圖。圖片在重新下載前載入速度可能較慢。';
	@override String get clearImageCacheSuccess => '圖片快取已成功清除';
	@override String get resetSettings => '重設設定';
	@override String get resetSettingsDescription => '恢復預設設定。此操作無法復原。';
	@override String get resetSettingsSuccess => '設定重設成功';
	@override String get backup => '備份';
	@override String get exportSettings => '匯出設定';
	@override String get exportSettingsDescription => '將您的偏好設定儲存至檔案';
	@override String get exportSettingsSuccess => '設定已匯出';
	@override String get importSettings => '匯入設定';
	@override String get importSettingsDescription => '從檔案還原偏好設定';
	@override String get importSettingsConfirm => '這將覆蓋您目前的設定。要繼續嗎？';
	@override String get importSettingsSuccess => '設定已匯入';
	@override String get importSettingsInvalidFile => '此檔案不是有效的 PlezyNG 設定匯出檔';
	@override String get importSettingsNoUser => '匯入設定前請先登入';
	@override String get cloudBackup => '雲備份';
	@override String get cloudBackupDescription => '透過 HTTPS 將可移轉的設定備份到 WebDAV 位址。伺服器連線和登入憑證保留在此裝置上。';
	@override String get cloudBackupUrl => 'WebDAV JSON 檔案 URL';
	@override String get cloudBackupUsername => '使用者名稱';
	@override String get cloudBackupPassword => '密碼';
	@override String get cloudBackupSaved => '雲備份目的地儲存';
	@override String get cloudBackupNow => '迴歸現在';
	@override String get cloudBackupComplete => '設定備份上傳';
	@override String get cloudBackupRestore => '恢復備份';
	@override String get cloudBackupRestoreConfirm => '此將取代該裝置上的相匹配移動設定。';
	@override String get cloudBackupRestored => '從雲端儲備恢復的設定';
	@override String get shortcutsReset => '快速鍵已重設為預設值';
	@override String get resetShortcutsConfirm => '這會將您的自訂快速鍵替換為預設值。要繼續嗎？';
	@override String get about => '關於';
	@override String get aboutDescription => '應用程式資訊與授權條款';
	@override String get updates => '更新';
	@override String get updateAvailable => '有可用更新';
	@override String get checkForUpdates => '檢查更新';
	@override String get autoCheckUpdatesOnStartup => '啟動時自動檢查更新';
	@override String get autoCheckUpdatesOnStartupDescription => '啟動時若有可用更新便顯示通知';
	@override String get validationErrorEnterNumber => '請輸入有效的數字';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => '長度必須介於 ${min} 與 ${max} ${unit} 之間';
	@override String shortcutAlreadyAssigned({required Object action}) => '該快速鍵已指派給 ${action}';
	@override String shortcutUpdated({required Object action}) => '已更新 ${action} 的快速鍵';
	@override String get saveFailed => '無法儲存變更。請重試。';
	@override String get autoPlayAndSkip => '自動播放與跳過';
	@override String get autoPlayNextEpisode => '自動播放下一集';
	@override String get autoPlayNextEpisodeDescription => '目前單集結束時自動播放下一集';
	@override String get shuffleStartsFromBeginning => '隨機播放從頭開始';
	@override String get shuffleStartsFromBeginningDescription => '隨機播放時每集從頭開始播放，而非繼續播放';
	@override String get plexCinemaPreRoll => '使用伺服器電影輸入';
	@override String get plexCinemaPreRollDescription => '在電影開始之前,播放配置的Plex預角色或Jellyfin和Emby輸入。';
	@override String get playNextCountdown => '下一集倒數計時';
	@override String get playNextCountdownImmediate => '立即播放';
	@override String get skipIntroMode => '跳過片頭';
	@override String get skipIntroModeOffDescription => '正常播放片頭，不顯示跳過按鈕';
	@override String get skipIntroModeButtonDescription => '片頭開始時顯示跳過按鈕';
	@override String get skipIntroModeAutoDescription => '在下方設定的延遲後自動跳過片頭';
	@override String get skipCreditsMode => '跳過片尾';
	@override String get skipCreditsModeOffDescription => '正常播放片尾，不顯示跳過按鈕';
	@override String get skipCreditsModeButtonDescription => '片尾開始時顯示跳過按鈕';
	@override String get skipCreditsModeAutoDescription => '自動跳過片尾並播放下一集';
	@override String get skipAdsMode => '滑雪廣告';
	@override String get skipAdsModeOffDescription => '正常播放被發現的廣告,沒有跳躍按鈕';
	@override String get skipAdsModeButtonDescription => '顯示在 Plex 檢測廣告時,將按鈕轉';
	@override String get skipAdsModeAutoDescription => '下面的延遲後自動刪除被發現的廣告';
	@override String get musicPlayback => '音樂播放';
	@override String get musicSweetFades => '甜蜜的Fades';
	@override String get musicSweetFadesDescription => '音樂在軌道邊緣時,當Plex有聲音資料時,音樂的播放保持不變。';
	@override String get skipMarkerModeOff => '關閉';
	@override String get skipMarkerModeButton => '顯示按鈕';
	@override String get skipMarkerModeAuto => '自動';
	@override String get forceSkipMarkerFallback => '強制使用備用標記';
	@override String get forceSkipMarkerFallbackDescription => '即使 Plex 有標記，也強制使用章節標題模式';
	@override String get theIntroDbFallback => '使用 TheIntroDB 作為 Intro Fallback';
	@override String get theIntroDbFallbackDescription => '僅在伺服器沒有片頭標記時使用社群提供的時間點。比對結果可能因發行版本而異。';
	@override String get autoSkipDelay => '自動跳過延遲';
	@override String autoSkipDelayDescription({required Object seconds}) => '自動跳過前等待 ${seconds} 秒';
	@override String get introPattern => '片頭標記模式';
	@override String get introPatternDescription => '用於比對章節標題中片頭標記的正規表示式';
	@override String get creditsPattern => '片尾標記模式';
	@override String get creditsPatternDescription => '用於比對章節標題中片尾標記的正規表示式';
	@override String get prerolls => '片前影片';
	@override String get playPrerollsBeforeMovies => '電影前玩預告片';
	@override String get playPrerollsBeforeMoviesDescription => '在每部電影之前播放下面的選項中的偶然剪輯,按一下回來跳。';
	@override String get prerollLibrary => '普雷羅圖書館';
	@override String get prerollLibraryNotSet => '未設定';
	@override String get prerollLibraryNoneFound => '您伺服器上沒有找到圖書館。';
	@override String get prerollSelection => '選擇的預算';
	@override String get prerollSelectionPickLibraryFirst => '首先選擇圖書館';
	@override String get prerollSelectionNoneSelected => '沒有選定的特權';
	@override String prerollSelectionCount({required Object count}) => '已選取 ${count} 個';
	@override String get prerollItemPicker => '選擇預算';
	@override String get prerollItemPickerLoadFailed => '我不能從這本圖書館上傳任何東西。';
	@override String get invalidRegex => '無效的正規表示式';
	@override String get regex => '正規表示式';
	@override String get downloads => '下載';
	@override String get downloadLocationDescription => '選擇下載內容的儲存位置';
	@override String get downloadLocationDefault => '預設（應用程式專屬儲存空間）';
	@override String get downloadLocationCustom => '自訂位置';
	@override String get selectFolder => '選擇資料夾';
	@override String get resetToDefault => '重設為預設值';
	@override String currentPath({required Object path}) => '目前路徑：${path}';
	@override String get downloadLocationChanged => '下載位置已變更';
	@override String get downloadLocationReset => '下載位置已重設為預設值';
	@override String get downloadLocationInvalid => '所選資料夾不具寫入權限';
	@override String get downloadLocationPickerUnavailable => '此裝置無法選擇資料夾';
	@override String get downloadOnWifiOnly => '僅在 Wi-Fi 連線時下載';
	@override String get downloadOnWifiOnlyDescription => '使用行動網路時不會下載';
	@override String get autoRemoveWatchedDownloads => '自動移除已觀看的下載內容';
	@override String get autoRemoveWatchedDownloadsDescription => '自動刪除已觀看的下載影片';
	@override String get autoDownloadContinueWatching => '自動下載 繼續觀看';
	@override String get autoDownloadContinueWatchingDescription => '保持在您的繼續觀看盾牌上下載的專案,並在他們離開盾牌後刪除它們';
	@override String get downloadQuality => '下載質量';
	@override String get downloadQualityDescription => 'Plex 在其下載中編制轉換副本. Jellyfin 和 Emby 轉碼,而檔案下載; 中斷的轉換可能需要重新啟動。';
	@override String get askDownloadQualityEachTime => '選擇每個下載的質量';
	@override String get askDownloadQualityEachTimeDescription => '顯示優質點數,在每次影片下載之前';
	@override String get cellularDownloadBlocked => '使用行動網路時無法下載。請改用 Wi-Fi 或變更設定。';
	@override String get maxVolume => '最大音量';
	@override String get maxVolumeDescription => '允許音量調大至 100% 以上，以適應聲音過小的媒體';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord 狀態整合（Rich Presence）';
	@override String get discordRichPresenceDescription => '在 Discord 上顯示您正在觀看的內容';
	@override String get services => '外部服務';
	@override String get servicesDescription => '連結 Trakt、MyAnimeList、Seerr 等服務';
	@override String get manageLibrariesDescription => '重新排序與隱藏媒體庫';
	@override String get companionRemoteServer => '隨身遙控器伺服器';
	@override String get companionRemoteServerDescription => '允許區域網路中的行動裝置控制此應用程式';
	@override String get companionRemoteServerStartFailed => '無法啟動隨身遙控器伺服器';
	@override String get companionRemoteServerStopFailed => '無法停止隨身遙控器伺服器';
	@override String get autoPip => '自動進入子母畫面';
	@override String get autoPipDescription => '播放影片時離開應用程式將自動進入子母畫面模式';
	@override String get matchContentFrameRate => '符合影片影格率';
	@override String get matchContentFrameRateDescription => '將顯示器更新率同步至影片影格率';
	@override String get matchContentResolution => '符合內容解析度';
	@override String get matchContentResolutionDescription => '將顯示切換為影片的原生解析度，由電視負責升頻。播放期間選單與字幕也會一併放大';
	@override String get matchRefreshRate => '同步螢幕更新率';
	@override String get matchRefreshRateDescription => '全螢幕時同步顯示器更新率';
	@override String get matchDynamicRange => '同步動態範圍';
	@override String get matchDynamicRangeDescription => 'HDR 內容切換至 HDR，播放結束切回 SDR';
	@override String get displaySwitchDelay => '顯示器切換延遲時間';
	@override String get tunneledPlayback => '通道化播放（Tunneled Playback）';
	@override String get tunneledPlaybackDescription => '使用影片通道模式。若 HDR 播放出現黑畫面或動態卡頓，請停用此項。';
	@override String get audioPassthrough => '音訊直通';
	@override String get audioPassthroughDescription => '將 Dolby/DTS 音訊不經重新編碼，直接傳送至擴大機或電視以保留環繞音效。若播放無聲，請關閉此設定。';
	@override String get audioPassthroughDescriptionApple => '使用 Apple 原生 Dolby 解碼器處理 Dolby Digital Plus（包括 Atmos）。DTS 與 TrueHD 仍以多聲道 PCM 播放。若沒有聲音，請關閉此設定。';
	@override String get audioPassthroughDescriptionAppleSpatial => '使用 Apple 原生 Dolby 解碼器處理 Dolby Digital Plus（包括 Atmos）。在 iOS、iPadOS 與 tvOS 26 或更新版本上，TrueHD Atmos 與 DTS:X 會以空間音訊播放。其他 DTS 與 TrueHD 音軌則以多聲道 PCM 播放。若沒有聲音，請關閉此設定。';
	@override String get audioPassthroughOverriddenByNormalization => '音量標準化開啟時停用';
	@override String get audioChannelLimit => '音訊聲道';
	@override String get audioChannelLimitDescription => '將解碼後的音訊下混，以配合無法播放所有聲道的喇叭、耳機或 HDMI 設備';
	@override String get audioChannelLimitOriginal => '原始';
	@override String get audioChannelLimitOriginalDescription => '播放音軌中的所有聲道';
	@override String get audioChannelLimitSurround51 => '最多 5.1';
	@override String get audioChannelLimitSurround51Description => '將 7.1 下混為 5.1，適用於僅支援 5.1 PCM 的電視與擴大機。不影響直通。';
	@override String get audioChannelLimitStereo => '立體聲';
	@override String get audioChannelLimitStereoDescription => '下混為雙聲道，適用於立體聲喇叭或耳機。會關閉直通。';
	@override String get downmixCenterBoost => '中置聲道增強';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => '增強（dB）';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => '下混時音量標準化';
	@override String get audioDownmixNormalizeDescription => '降低混音電平以防止破音。關閉以保持原始音量（大音量場景可能會失真）。';
	@override String get dvConversionMode => 'Dolby Vision 轉換模式';
	@override String get dvConversionModeDescription => '選擇如何處理 Dolby Vision Profile 7 檔案。';
	@override String get dvConversionAuto => '自動';
	@override String get dvConversionNative => '原生 / 停用';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => '自動偵測裝置相容性並使用一般備援機制';
	@override String get dvConversionNativeDescription => '強制使用原生 DV7 並停用 DV 轉換重試';
	@override String get dvConversionDv81Description => '強制將內嵌的 RPU 轉換為 Dolby Vision Profile 8.1';
	@override String get dvConversionHevcStripDescription => '移除 Dolby Vision RPU/EL 層，並以一般 HEVC 呈現';
	@override String get experimentalDolbyVision => '實驗性 Dolby Vision';
	@override String get experimentalDolbyVisionDescription => '下次播放時使用實驗性 FEL 算繪器。需要單獨建置的播放引擎。';
	@override String get dvExperimentUnavailableDescription => '此實驗目前僅支援 Linux。';
	@override String get dvCompatibilityFallback => '相容性備援';
	@override String get dvCompatibilityFallbackDescription => '如果實驗無法啟動，則使用標準算繪器。FEL 資料可能會遺失。';
	@override String get dvExperimentDiagnostics => '影片實驗記錄';
	@override String get dvExperimentDiagnosticsDescription => '在下次播放時啟用詳細的播放器記錄。';
	@override String get disableDolbyVision => '停用 Dolby Vision';
	@override String get disableDolbyVisionDescription => '檔案包含 HDR10 或 HLG 層時，改為播放該層而非 Dolby Vision';
	@override String get hdrSdrConversion => 'HDR 轉 SDR';
	@override String get hdrSdrConversionDescription => '選擇在顯示器無法顯示 HDR 時由誰轉換 HDR 影片。';
	@override String get hdrSdrConversionAuto => '自動';
	@override String get hdrSdrConversionAutoDescription => 'Android 9 及更新版本使用裝置，較舊版本使用播放器';
	@override String get hdrSdrConversionDevice => '裝置';
	@override String get hdrSdrConversionDeviceDescription => '由裝置的視訊硬體轉換。速度最快，但色彩取決於裝置';
	@override String get hdrSdrConversionPlayer => '播放器';
	@override String get hdrSdrConversionPlayerDescription => '由播放器轉換。色彩一致，但在低階電視盒上 4K 可能卡頓';
	@override String get deinterlace => '去交錯';
	@override String get deinterlaceDescription => '移除交錯影片中的梳狀雜訊（僅限 mpv 播放器）';
	@override String get deinterlaceOff => '關閉';
	@override String get deinterlaceOffDescription => '以解碼後的原樣顯示交錯影片';
	@override String get deinterlaceVideo => '視訊';
	@override String get deinterlaceVideoDescription => '將每個圖場轉為完整影格。適用於為電視拍攝的影片，例如體育賽事、新聞與演唱會';
	@override String get deinterlaceFilm => '電影';
	@override String get deinterlaceFilmDescription => '還原經 telecine 轉為 29.97 fps 的電影與動畫原始影格，常見於 NTSC DVD。為電視拍攝的影片會出現卡頓。直播電視會使用「視訊」';
	@override String get requireProfileSelectionOnOpen => '開啟應用程式時要求選擇使用者';
	@override String get requireProfileSelectionOnOpenDescription => '每次開啟應用程式時顯示使用者設定檔選擇畫面';
	@override String get forceTvMode => '強制 TV 模式';
	@override String get forceTvModeDescription => '強制使用 TV 介面版面。適用於無法自動辨識 TV 的裝置。需要重新啟動。';
	@override String get startInFullscreen => '以全螢幕模式啟動';
	@override String get startInFullscreenDescription => '啟動時直接以全螢幕開啟 PlezyNG';
	@override String get exitFullscreenOnPlayerClose => '關閉播放器時退出全螢幕';
	@override String get exitFullscreenOnPlayerCloseDescription => '關閉影片播放器時自動退出全螢幕模式';
	@override String get autoHidePerformanceOverlay => '自動隱藏效能疊加層';
	@override String get autoHidePerformanceOverlayDescription => '效能疊加層隨播放控制面板一起淡入或淡出';
	@override String get showNavBarLabels => '顯示導覽列標籤';
	@override String get showNavBarLabelsDescription => '在導覽列圖示下方顯示文字標籤';
	@override String get startupSection => '啟動頁面';
	@override String get preferredServer => '優先伺服器';
	@override String get preferredServerDescription => '優先考慮此伺服器的結果,同時保持所有連線的伺服器可用。';
	@override String get preferredServerAutomatic => '自動';
	@override String get showExploreTab => '顯示探索分頁';
	@override String get showExploreTabDescription => '顯示探索分頁，其中包含來自 Plex Discover 和已連結追蹤服務的內容';
	@override String get hideEmptyLibraries => '隱藏空白圖書館';
	@override String get hideEmptyLibrariesDescription => '從導航中刪除伺服器報告的零件數的圖書館。';
	@override String get liveTvDefaultFavorites => '預設顯示最愛頻道';
	@override String get liveTvDefaultFavoritesDescription => '開啟直播電視時僅顯示最愛頻道';
	@override String get general => '一般';
	@override String get generalDescription => '語言、啟動與視窗行為';
	@override String get languageAndRegion => '語言與地區';
	@override String get startup => '啟動';
	@override String get display => '顯示器';
	@override String get libraryAndCards => '媒體庫與卡片';
	@override String get homeScreen => '主畫面';
	@override String get navigation => '導覽';
	@override String get window => '視窗';
	@override String get liveTv => '直播電視';
	@override String get player => '播放器';
	@override String get videoAndDisplay => '影片與顯示器';
	@override String get audio => '音訊';
	@override String get quality => '畫質';
	@override String get subtitles => '字幕';
	@override String get seekAndTiming => '跳轉與計時';
	@override String get behavior => '行為';
	@override String get gestures => '手勢';
	@override String get gestureBrightnessSwipe => '亮度滑動手勢';
	@override String get gestureBrightnessSwipeDescription => '在螢幕左側邊緣上下滑動以調整亮度';
	@override String get gestureVolumeSwipe => '音量滑動手勢';
	@override String get gestureVolumeSwipeDescription => '在螢幕右側邊緣上下滑動以調整音量';
	@override String get gesturePinchToZoom => '雙指縮放';
	@override String get gesturePinchToZoomDescription => '在影片上雙指捏合以放大或縮小';
	@override String get gestureSeekSwipe => '尋找Swipe';
	@override String get gestureSeekSwipeDescription => '向左或向右轉到影片中尋找; 釋放跳躍';
	@override String get rememberBrightnessLevel => '記住亮度';
	@override String get rememberBrightnessLevelDescription => '以上次滑動設定的亮度開始播放';
	@override String get controls => '控制';
	@override String get rememberPlayerChanges => '記住播放器變更';
	@override String get rememberPlayerChangesDescription => '播放期間所做的變更要儲存並從何處重新套用';
	@override String get scopePlaybackSpeed => '播放速度';
	@override String get scopeShaderPreset => '著色器預設';
	@override String get scopeAspectRatio => '顯示比例';
	@override String get scopeSyncOffsets => '音訊與字幕同步';
	@override String get playerScopeOff => '不要儲存';
	@override String get playerScopeGlobal => '全部';
	@override String get playerScopeLibrary => '依媒體庫';
	@override String get playerScopeTitle => '依影集或電影';
	@override String get exportDialogTitle => '匯出 PlezyNG 設定';
	@override String get followSystem => '跟隨系統';
	@override String get followAppLanguage => '與介面語言一致';
	@override String get regionFormat => '地區格式';
	@override String get regionFormatDescription => '選擇日期、數字及計量單位的顯示方式。';
	@override String get metadataLanguage => '中繼資料語言';
	@override String get metadataLanguageDescription => '伺服器支援時，優先使用此語言顯示標題及簡介。音訊和字幕偏好設定互相獨立。';
	@override String get enterFullscreenOnPlaybackStart => '在播放開始時輸入全屏';
	@override String get enterFullscreenOnPlaybackStartDescription => '開啟桌面影片在播放開始時全屏';
	@override String get extendVideoIntoDisplayCutout => '將影片擴充套件到顯示器中';
	@override String get extendVideoIntoDisplayCutoutDescription => '讓全屏影片在Android手機上使用相機切割';
	@override String get languageDescription => '選擇用於 PlezyNG 控制和訊息的語言. 跟蹤系統跟蹤您的裝置語言。';
	@override String get themeDescription => '選擇應用程式中使用的顏色和對比。';
	@override String get libraryDensityDescription => '改變每個行中的圖書館卡的數量。';
	@override String get displayScaleDescription => '在此車螢幕上重新設定介面,而無需改變您的裝置上的文字大小。';
	@override String get themeSongVolumeDescription => '設定主題歌曲的數量與其他音訊相比。';
	@override String get viewModeDescription => '選擇圖書館專案是否顯示為網上的海報或作為一個小型列表。';
	@override String get gridViewDescription => '安排圖書館專案在海報的行和列。';
	@override String get listViewDescription => '在垂直列表中顯示圖書館專案,每個專案有更多的文字。';
	@override String get gridSpacingDescription => '在圖書館網中設定海報之間的差距。';
	@override String get gridSpacingTightDescription => '在螢幕上插入更多的海報,有較小的差距。';
	@override String get gridSpacingNormalDescription => '使用海報之間的標準差距。';
	@override String get gridSpacingSpaciousDescription => '新增海報之間更大的差距,以獲得更多的分離。';
	@override String get episodePosterModeDescription => '選擇哪個藝術作品出現在節目卡上。';
	@override String get seriesPosterDescription => '使用節目系列的海報為每個集合。';
	@override String get seasonPosterDescription => '使用每集的季節海報,隨時可用。';
	@override String get episodeThumbnailDescription => '在可用時使用集中的框架。';
	@override String get continueWatchingActionDescription => '選擇當您啟動繼續觀看卡時會發生什麼。';
	@override String get continueWatchingPlayDescription => '立即啟動電影或節目。';
	@override String get continueWatchingDetailsDescription => '首先開啟標題頁面,以便您可以檢視詳細資訊並選擇一個行動。';
	@override String get episodeActionDescription => '選擇當您啟動一個節目卡時會發生什麼。';
	@override String get episodePlayDescription => '立即開始事件。';
	@override String get episodeDetailsDescription => '在播放之前開啟集片頁面。';
	@override String get contentScreensaverDelayDescription => '在展示藝術作品之前,選擇 PlezyNG 等待多久沒有輸入。';
	@override String get continueWatchingRowSizeDescription => '在繼續觀看行中選擇卡片的尺寸。';
	@override String get rowSizeCompactDescription => '顯示較小的卡片,以便在行列中新增更多的專案。';
	@override String get rowSizeStandardDescription => '使用標準卡尺寸。';
	@override String get rowSizeLargeDescription => '顯示更大的卡片,更多藝術作品的細節。';
	@override String get visualEffectsDescription => '選擇該裝置的動畫和藝術作品效果預算。';
	@override String get visualEffectsFullDescription => '在每個裝置上使用完整的動畫和藝術作品效果。';
	@override String get startupSectionDescription => '在 PlezyNG 啟動時選擇哪個部分開啟。';
	@override late final _Translations$settings$startupSectionOptions$zh_Hant startupSectionOptions = _Translations$settings$startupSectionOptions$zh_Hant._(_root);
	@override String get smallSkipDurationDescription => '設定由短後方向移動的距離,並向前尋找控制。';
	@override String get largeSkipDurationDescription => '設定遠端移動的長後方向和向前尋找控制。';
	@override String get rewindOnResumeDescription => '在重新播放影片時,以此金額返回播放。';
	@override String get defaultSleepTimerDescription => '設定睡眠時間開始時使用的初始時間。';
	@override String get playNextCountdownDescription => '等待很久,直到下一集開始,設定到0即時開始。';
	@override String get autoSkipDelaySettingDescription => '適用於當一個輸入、信用或廣告設定自動轉換時。';
	@override String get downmixCenterBoostDescription => '在周圍的音訊被混合到斯特里奧時,在中間頻道上增加對話。';
	@override String get displaySwitchDelayDescription => '在更改顯示模式之前等待,以便電視或接收器可以完成其以前的交換。';
	@override String get playerBackendDescription => '選擇哪個播放引擎在該裝置上掃描和播放影片。';
	@override String get exoPlayerDescription => '使用 Android 的本地 Media3 基於播放器和支援的硬體路徑。';
	@override String get mpvDescription => '使用 mpv,它暴露了額外的播放、子標題和影片處理控制。';
	@override String get scopeOffDescription => '只保留當前播放會的更改。';
	@override String get scopeGlobalDescription => '重複使用每個圖書館和標題的相同值。';
	@override String get scopeLibraryDescription => '記住每個圖書館的單獨價值。';
	@override String get scopeTitleDescription => '記住每個節目或電影的單獨值。';
	@override String get specialsOrderingServerDescription => '保持媒體伺服器提供的集合訂單。';
	@override String get specialsOrderingAirDateDescription => '根據他們的空氣日期,將特殊物品列入常規事件中。';
	@override String get specialsOrderingLastDescription => '每個特別的位置,在定期季節後。';
	@override String get skipIntroModeDescription => '選擇輸入標記器是否正常播放,顯示滑動按鈕或自動滑動。';
	@override String get skipCreditsModeDescription => '選擇信用是否正常播放,顯示滑動按鈕或自動滑動。';
	@override String get skipAdsModeDescription => '選擇是否被發現的廣告正常播放,顯示滑動按鈕或自動滑動。';
	@override String get playbackBufferAutoDescription => '讓活躍的玩家選擇其正常的泡沫大小。';
	@override String get playbackBufferLargeDescription => '保持更多媒體在播放前準備;這使用更多的記憶體。';
	@override String get playbackBufferExtraLargeDescription => '保持最大的閱讀面板泡沫;這使用最多的記憶。';
	@override String get defaultQualityDescription => '設定伺服器轉碼串流的預設影片解析度與最高位元率。';
	@override String get cellularQualityDescription => '超越預設質量,當裝置使用單細胞連線時。';
	@override String get remoteQualityDescription => '透過遠端連線連線到伺服器時超越預設質量。';
	@override String get qualityPresetOriginalDescription => '以來源可用的畫質播放，不要求伺服器轉碼。';
	@override String get qualityPresetTranscodeOptionDescription => '請伺服器依照上方顯示的解析度與位元率轉碼串流。';
	@override String get qualityPresetSameAsDefaultDescription => '使用預設品質中選擇的質量。';
	@override String get musicQualityDescription => '設定向伺服器要求的最高音訊位元率；選擇「原始」時會保留來源串流。';
	@override String get musicQualityOriginalDescription => '播放源音訊,無需Bitrate加密的Transcode。';
	@override String get musicQualityTranscodeOptionDescription => '請求伺服器轉程式碼接近上面的位元率;實際輸出可能有所不同。';
	@override String get maxVolumeInputLabel => '最大容量(%)';
	@override String get checkForUpdatesDescription => '現在檢查是否有更新的PlezyNG版本。';
	@override String get appearanceDescription => '選擇應用程式主題,並調整圖書館卡、主行和導航。';
	@override String get prerollLibraryDescription => '選擇包含電影預角色可用的剪輯的圖書館。';
	@override String get prerollSelectionDescription => '選擇從所選圖書館播放的剪輯在電影之前。';
	@override String get contentScreensaverDelayOptionDescription => '在顯示屏儲存藝術作品之前等待這些無輸入的幾分鐘。';
	@override String get videoCodecOptionDescription => '允許在支援時直接播放此程式碼器. 未經檢查的程式碼被媒體伺服器編碼。';
}

// Path: themeEditor
class _Translations$themeEditor$zh_Hant extends Translations$themeEditor$zh {
	_Translations$themeEditor$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get builtIn => '內建';
	@override String get presets => '精選';
	@override String get custom => '自訂';
	@override String get customEmpty => '尚未建立';
	@override String get editCustom => '編輯自訂主題';
	@override String get editCustomDescription => '自行選擇每一種顏色';
	@override String get locked => '終身訪問需要';
	@override String get savedLocked => '儲存 - 可用,終身訪問';
	@override String get title => '自訂主題';
	@override String get startFrom => '從現有主題開始';
	@override String get startFromDescription => '從其他主題複製所有顏色';
	@override String get colors => '顏色';
	@override String get preview => '預覽';
	@override late final _Translations$themeEditor$slots$zh_Hant slots = _Translations$themeEditor$slots$zh_Hant._(_root);
	@override String get opacity => '不透明度';
	@override String get hexHint => '#RRGGBB 或 #AARRGGBB';
	@override String get fromOtherThemes => '來自其他主題';
	@override String swatchLabel({required Object theme, required Object color}) => '${theme} ${color}';
	@override late final _Translations$themeEditor$contrast$zh_Hant contrast = _Translations$themeEditor$contrast$zh_Hant._(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}：${ratio}:1，低於建議的 ${minimum}:1';
	@override String get discardTitle => '要捨棄變更嗎？';
	@override String get discardMessage => '您尚未儲存的顏色變更將會遺失。';
	@override String get discard => '捨棄';
	@override String previewCardTitle({required Object number}) => '第 ${number} 集';
	@override String previewCardSubtitle({required Object minutes}) => '剩餘 ${minutes} 分鐘';
	@override String get previewSwitch => '自動播放';
	@override String get previewMutedText => '次要文字看起來像這樣';
	@override String get themeSystemDescription => '跟蹤您的裝置的外觀,並自動在光和黑暗之間交換。';
	@override String get themeLightDescription => '使用光明的背景與黑暗文字。';
	@override String get themeDarkDescription => '使用黑暗背景與光明文字。';
	@override String get themeOledDescription => '使用近黑的表面,減少OLED螢幕上的光。';
	@override String get themeEmberDescription => '使用溫暖的紅色和<unk>色的重點顏色。';
	@override String get themeGlacierDescription => '使用冷藍色焦點顏色。';
	@override String get themeForestDescription => '使用混合的綠色和天然焦點顏色。';
	@override String get themePlumDescription => '使用紫色和<unk>色的重點顏色。';
	@override String get themePaperDescription => '使用溫暖的紙類表面和印刷靈感的顏色。';
	@override String get themeCustomDescription => '使用您在自定義主題編輯器中建立的顏色板。';
	@override String get editorDescription => '選取調色盤顏色，調整色相、飽和度、亮度或不透明度，並在儲存前查看預覽更新。也可以輸入十六進位顏色。';
}

// Path: search
class _Translations$search$zh_Hant extends Translations$search$zh {
	_Translations$search$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get hint => '搜尋電影、影集、音樂…';
	@override String get tryDifferentTerm => '嘗試不同的關鍵字';
	@override String get searchYourMedia => '搜尋媒體庫';
	@override String get enterTitleActorOrKeyword => '輸入標題、演員或關鍵字';
	@override String get people => '人物';
}

// Path: hotkeys
class _Translations$hotkeys$zh_Hant extends Translations$hotkeys$zh {
	_Translations$hotkeys$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => '為 ${actionName} 設定快速鍵';
	@override String get clearShortcut => '清除快速鍵';
	@override String get noShortcutSet => '未設定快速鍵';
	@override String get currentShortcut => '目前快速鍵：';
	@override String get pressToRecord => '選擇以錄製快速鍵';
	@override String get recordingShortcut => '現在請按下快速鍵組合';
	@override late final _Translations$hotkeys$actions$zh_Hant actions = _Translations$hotkeys$actions$zh_Hant._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$zh_Hant extends Translations$fileInfo$zh {
	_Translations$fileInfo$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '檔案資訊';
	@override String get overview => '概述';
	@override String get video => '影片';
	@override String get audio => '音訊';
	@override String get subtitles => '字幕';
	@override String get images => '內嵌圖片';
	@override String get dataStreams => '資料串流';
	@override String get lyrics => '歌詞';
	@override String get file => '檔案';
	@override String get attachments => '附件';
	@override String get delivery => '傳輸方式';
	@override String versionCounter({required Object index, required Object count}) => '第 ${index} 個版本，共 ${count} 個';
	@override String fileCounter({required Object index, required Object count}) => '第 ${index} 個檔案，共 ${count} 個';
	@override String get noStreams => '伺服器回報此檔案沒有串流。';
	@override String get copyPath => '複製路徑';
	@override String get pathCopied => '已複製檔案路徑';
	@override String get codec => '編解碼器';
	@override String get codecTag => '編解碼器標籤';
	@override String get resolution => '解析度';
	@override String get codedResolution => '編碼解析度';
	@override String get bitrate => '位元率';
	@override String get frameRate => '影格率';
	@override String get rotation => '旋轉';
	@override String get comment => '註解';
	@override String get audioDescription => '口述影像';
	@override String get headerCompression => '標頭壓縮';
	@override String get sidecarFile => '附屬檔案';
	@override String get transportTimestamp => '傳輸時間戳記';
	@override String get displayOffset => '顯示偏移';
	@override String get previewFailureCode => '預覽失敗代碼';
	@override String get previewRetries => '預覽重試次數';
	@override String get aspectRatio => '寬高比';
	@override String get pixelAspectRatio => '像素寬高比';
	@override String get profile => '規格檔（Profile）';
	@override String get level => '等級';
	@override String get bitDepth => '位元深度';
	@override String get pixelFormat => '像素格式';
	@override String get colorSpace => '色彩空間';
	@override String get colorRange => '色彩範圍';
	@override String get colorPrimaries => '色彩基色';
	@override String get colorTransfer => '色彩轉換';
	@override String get chromaSubsampling => '色度抽樣';
	@override String get chromaLocation => '色度位置';
	@override String get scanType => '掃描類型';
	@override String get interlaced => '交錯式';
	@override String get anamorphic => '變形寬銀幕';
	@override String get referenceFrames => '參考影格';
	@override String get dynamicRange => '動態範圍';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Dolby Vision 等級';
	@override String get dolbyVisionVersion => 'Dolby Vision 版本';
	@override String get dolbyVisionLayers => 'Dolby Vision 圖層';
	@override String get baseLayerCompatibility => '基礎圖層相容性';
	@override String get avcBitstream => 'AVC 位元串流';
	@override String get nalLengthSize => 'NAL 長度大小';
	@override String get scalingMatrix => '自訂縮放矩陣';
	@override String get streamIdentifier => '串流識別碼';
	@override String get streamIndex => '串流索引';
	@override String get streamId => '串流 ID';
	@override String get language => '語言';
	@override String get languageCode => '語言代碼';
	@override String get streamTitle => '軌道名稱';
	@override String get channels => '聲道數';
	@override String get sampleRate => '取樣率';
	@override String get spatialAudio => '空間音訊';
	@override String get textBased => '文字型';
	@override String get subtitleFormat => '附屬檔案格式';
	@override String get provider => '提供者';
	@override String get matchScore => '相符度';
	@override String get externalDelivery => '可分開傳送';
	@override String get sidecarPath => '附屬路徑';
	@override String get sourceStream => '複製來源';
	@override String get temporary => '暫時';
	@override String get timeBase => '時間基準';
	@override String get overallBitrate => '總位元率';
	@override String get path => '路徑';
	@override String get fileName => '檔案名稱';
	@override String get size => '大小';
	@override String get totalSize => '總大小';
	@override String get container => '封裝格式';
	@override String get duration => '長度';
	@override String get previewThumbnails => '預覽縮圖';
	@override String get previewIndex => '預覽索引';
	@override String get packetLength => '封包長度';
	@override String get filePresent => '檔案存在';
	@override String get fileReadable => '伺服器可讀取';
	@override String get streamPath => '串流路徑';
	@override String get optimizedForStreaming => '已最佳化串流播放';
	@override String get has64bitOffsets => '具 64 位元偏移量';
	@override String get protocol => '通訊協定';
	@override String get mediaType => '媒體類型';
	@override String get sourceKind => '來源類型';
	@override String get optimizedVersion => '最佳化版本';
	@override String get optimizationTarget => '最佳化目標';
	@override String get deletedAt => '已刪除';
	@override String get remoteSource => '遠端來源';
	@override String get infiniteStream => '無限串流';
	@override String get directPlay => '直接播放';
	@override String get directStream => '直接串流';
	@override String get transcoding => '轉碼';
	@override String get etag => 'ETag';
	@override String get versionId => '版本 ID';
	@override String get fileId => '檔案 ID';
	@override String get defaultAudioTrack => '預設音軌';
	@override String get defaultSubtitleTrack => '預設字幕軌';
	@override String get subtitlesOff => '關閉';
	@override String get flagDefault => '預設';
	@override String get flagForced => '強制';
	@override String get flagSelected => '已選取';
	@override String get flagExternal => '外部';
	@override String get flagHearingImpaired => '聽障輔助';
	@override String get flagDub => '配音';
	@override String get flagOriginal => '原音';
	@override String get channelsMono => '單聲道';
	@override String dolbyVisionProfile({required Object profile}) => '規格檔（Profile）${profile}';
}

// Path: mediaMenu
class _Translations$mediaMenu$zh_Hant extends Translations$mediaMenu$zh {
	_Translations$mediaMenu$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => '標記為已觀看';
	@override String get markAsUnwatched => '標記為未觀看';
	@override String get removeFromContinueWatching => '從「繼續觀看」中移除';
	@override String get viewDetails => '查看詳情';
	@override String get goToSeries => '前往影集';
	@override String get shufflePlay => '隨機播放';
	@override String get shuffleNotAvailableOffline => '離線時無法隨機播放';
	@override String get fileInfo => '檔案資訊';
	@override String get deleteEpisodeFromServer => '從伺服器刪除單集';
	@override String get deleteSeasonFromServer => '從伺服器刪除季';
	@override String get deleteShowFromServer => '從伺服器刪除影集';
	@override String get deleteMovieFromServer => '從伺服器刪除電影';
	@override String get deleteEpisodeTitle => '刪除此單集？';
	@override String get deleteSeasonTitle => '刪除此季？';
	@override String get deleteShowTitle => '刪除此影集？';
	@override String get deleteMovieTitle => '刪除此電影？';
	@override String get deleteEpisodeConfirm => '刪除單集';
	@override String get deleteSeasonConfirm => '刪除季';
	@override String get deleteShowConfirm => '刪除影集';
	@override String get deleteMovieConfirm => '刪除電影';
	@override String get deleteAnyway => '仍要刪除';
	@override String confirmDeleteTarget({required Object title}) => '確定要從您的伺服器永久刪除「${title}」嗎？';
	@override String get deleteMultipleWarning => '這將會刪除所有單集及其檔案。';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '這會刪除其中的 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 集及其檔案。',
		other: '這會刪除其中全部 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 集及其檔案。',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '此項目儲存在 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 個檔案中，該檔案將被刪除。',
		other: '此項目分散儲存於 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 個檔案中，且全部都會被刪除。',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '另有 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 集儲存在同一檔案中，也會一併被刪除：',
		other: '另有 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 集儲存在同一檔案中，也會一併被刪除：',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'PlezyNG 無法確認此操作會刪除哪些檔案，因此刪除範圍可能超出上方所列的項目。請取消後重試，或仍要刪除。';
	@override String get deleteScopeUnverifiedNoFileInfo => '您的伺服器未提供此項目的檔案資訊，因此 PlezyNG 無法確認此操作會刪除哪些檔案。刪除範圍可能超出上方所列的項目。';
	@override String get mediaDeletedSuccessfully => '媒體已成功刪除';
	@override String get mediaFailedToDelete => '刪除媒體失敗';
	@override String get rate => '評分';
	@override String get playFromBeginning => '從頭播放';
	@override String get playVersion => '播放版本…';
}

// Path: rateSheet
class _Translations$rateSheet$zh_Hant extends Translations$rateSheet$zh {
	_Translations$rateSheet$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '評分';
	@override String get server => '伺服器';
	@override String get favorite => '最愛';
	@override String get favorited => '已加入最愛';
	@override String get saved => '已儲存';
	@override String get notAvailable => '找不到相符項目';
	@override String get noConnectedServices => '在設定中連結外部服務後，即可在此評分。';
}

// Path: accessibility
class _Translations$accessibility$zh_Hant extends Translations$accessibility$zh {
	_Translations$accessibility$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, 電影';
	@override String mediaCardShow({required Object title}) => '${title}, 影集';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => '已觀看';
	@override String mediaCardPartiallyWatched({required Object percent}) => '已觀看 ${percent}%';
	@override String get mediaCardUnwatched => '未觀看';
	@override String get tapToPlay => '輕觸即可播放';
	@override String get decrease => '減小';
	@override String get increase => '增大';
	@override String decreaseValue({required Object label}) => '減小 ${label}';
	@override String increaseValue({required Object label}) => '增大 ${label}';
	@override String get hue => '色相';
	@override String get saturation => '飽和度';
	@override String get brightness => '亮度';
	@override String get hexColor => 'Hex 顏色值';
	@override String get expandText => '展開文字';
	@override String get collapseText => '收合文字';
	@override String get alphabetNavigation => '字母導覽';
	@override String get alphabetScrollHint => '向上或向下滑動以按字母移動';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => '第 ${row} 列，共 ${rowCount} 列；第 ${column} 欄，共 ${columnCount} 欄';
	@override String rowPosition({required Object row, required Object rowCount}) => '第 ${row} 列，共 ${rowCount} 列';
	@override String get autoScrollPlay => '開始自動捲動';
	@override String get autoScrollPause => '暫停自動捲動';
	@override String get hueShort => 'H';
	@override String get saturationShort => 'S';
	@override String get valueShort => '五';
	@override String get red => '紅色';
	@override String get green => '綠色';
	@override String get blue => '藍色';
	@override String get redShort => '裡';
	@override String get greenShort => 'G';
	@override String get blueShort => 'B';
	@override String get colorModeHsv => 'HSV';
	@override String get colorModeRgb => '裡格';
	@override String get title => '可用性';
	@override String get summary => '文字、對比、動作和控制';
	@override String get systemHint => '您的裝置的可用性設定始終適用. 這些選項在 PlezyNG 期間新增調整。';
	@override String get readability => '閱讀與可見性';
	@override String get textSize => '附加文字大小';
	@override String get preview => '找下一個故事,閱讀,聽,並以自己的速度觀看。';
	@override String get boldText => '勇敢的介面文字';
	@override String get highContrast => '高度對比';
	@override String get highContrastHint => '在淺色或深色背景上，讓文字、輪廓線和焦點指示器更清晰。';
	@override String get interaction => '動作與互動';
	@override String get reduceMotion => '減少動作';
	@override String get reduceMotionHint => '停止焦點指示器、頁面切換和裝飾效果的動畫。';
	@override String get largeTargets => '觸控目標';
	@override String get largeTargetsHint => '共享控制器提供更多觸控和輔助導航空間。';
	@override String get navigationHint => '使用 Tab 和 Shift+Tab 在控制項之間移動，按 Enter 或空白鍵啟用，按 Escape 或返回按鈕關閉。開啟書籍後，可調整縮放比例和閱讀偏好設定。';
	@override String get textSizeDescription => '在 PlezyNG 中擴充套件介面文字,以及您的裝置的系統文字大小設定。';
	@override String get boldTextHint => '加粗介面標籤與訊息的字重，讓它們更容易辨識。';
}

// Path: tooltips
class _Translations$tooltips$zh_Hant extends Translations$tooltips$zh {
	_Translations$tooltips$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => '隨機播放';
	@override String get playTrailer => '播放預告片';
	@override String get markAsWatched => '標記為已觀看';
	@override String get markAsUnwatched => '標記為未觀看';
}

// Path: audioTracks
class _Translations$audioTracks$zh_Hant extends Translations$audioTracks$zh {
	_Translations$audioTracks$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => '音軌 ${n}';
}

// Path: videoControls
class _Translations$videoControls$zh_Hant extends Translations$videoControls$zh {
	_Translations$videoControls$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => '音訊';
	@override String get subtitlesLabel => '字幕';
	@override String addTime({required Object amount, required Object unit}) => '+${amount} ${unit}';
	@override String get letterbox => '信箱模式（Letterbox）';
	@override String get fillScreen => '填滿螢幕';
	@override String get stretch => '拉伸';
	@override String get lockRotation => '鎖定旋轉';
	@override String get unlockRotation => '解除鎖定旋轉';
	@override String get timerActive => '計時器已啟動';
	@override String playbackWillPauseIn({required Object duration}) => '播放將在 ${duration} 後暫停';
	@override String get sleepTimerEndOfVideo => '目前影片結束時';
	@override String get sleepTimerStopAtHeader => '停止於';
	@override String get sleepTimerDurationHeader => '計時器';
	@override String get playbackWillPauseAtEnd => '播放將在此影片結束時暫停';
	@override String get stillWatching => '您還在觀看嗎？';
	@override String pausingIn({required Object seconds}) => '${seconds} 秒後暫停';
	@override String get continueWatching => '繼續播放';
	@override String get autoPlayNext => '自動播放下一集';
	@override String get playNext => '播放下一集';
	@override String get playButton => '播放';
	@override String get pauseButton => '暫停';
	@override String get playbackPaused => '已暫停';
	@override String get playbackResumed => '播放中';
	@override String get loadingVideo => '正在載入影片';
	@override String get showPlaybackControls => '顯示播放控制項';
	@override String get hidePlaybackControls => '隱藏播放控制項';
	@override String seekBackwardButton({required Object seconds}) => '後退 ${seconds} 秒';
	@override String seekForwardButton({required Object seconds}) => '前進 ${seconds} 秒';
	@override String get previousButton => '上一集';
	@override String get nextButton => '下一集';
	@override String get previousChapterButton => '上一個章節';
	@override String get nextChapterButton => '下一個章節';
	@override String get muteButton => '靜音';
	@override String get unmuteButton => '取消靜音';
	@override String get settingsButton => '播放設定';
	@override String get tracksButton => '音訊與字幕';
	@override String get chaptersButton => '章節';
	@override String get versionQualityButton => '版本與畫質';
	@override String get versionColumnHeader => '版本';
	@override String get qualityColumnHeader => '畫質';
	@override String get qualityOriginal => '原始畫質';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => '無法使用轉碼 — 將以原始畫質播放';
	@override String get subtitleUnavailableFallback => '無法載入所選字幕 — 將繼續無字幕播放';
	@override String get pipButton => '子母畫面模式';
	@override String get aspectRatioButton => '寬高比';
	@override String get ambientLighting => '氛圍燈光';
	@override String get fullscreenButton => '進入全螢幕';
	@override String get exitFullscreenButton => '退出全螢幕';
	@override String get alwaysOnTopButton => '視窗置頂';
	@override String get rotationLockButton => '旋轉鎖定';
	@override String get lockScreen => '鎖定螢幕';
	@override String get screenLockButton => '螢幕鎖定';
	@override String get timelineSlider => '影片時間軸';
	@override String get volumeSlider => '音量調整';
	@override String endsAt({required Object time}) => '預計 ${time} 結束';
	@override String get pipActive => '正在以子母畫面模式播放';
	@override String get pipFailed => '啟動子母畫面失敗';
	@override String get screenshotSaved => '螢幕截圖已儲存';
	@override String get screenshotFailed => '無法擷取螢幕截圖';
	@override String zoomPercent({required Object percent}) => '縮放 ${percent}%';
	@override String volumePercent({required Object percent}) => '音量 ${percent}%';
	@override late final _Translations$videoControls$pipErrors$zh_Hant pipErrors = _Translations$videoControls$pipErrors$zh_Hant._(_root);
	@override String get chapters => '章節';
	@override String get noChaptersAvailable => '沒有可用的章節';
	@override String get queue => '播放佇列';
	@override String get noQueueItems => '佇列中沒有項目';
	@override String get noAudioDevicesAvailable => '沒有可用的音訊裝置';
	@override String get searchSubtitles => '搜尋字幕';
	@override String get language => '語言';
	@override String get noSubtitlesFound => '找不到字幕';
	@override String get subtitleDownloaded => '字幕下載成功';
	@override String get subtitleDownloadedNotApplied => '字幕已下載，但無法套用';
	@override String get subtitleDownloadFailed => '字幕下載失敗';
	@override String get searchLanguages => '搜尋語言…';
	@override String get skipIntro => '略過片頭';
	@override String get skipCredits => '略過片尾';
	@override String get nextEpisode => '下一集';
	@override String subtitleTrack({required Object n}) => '字幕軌 ${n}';
	@override String subtitleFile({required Object name}) => '字幕 ${name}';
	@override String forcedTrack({required Object label}) => '${label}（強制）';
	@override String get osdSubtitlesOff => '字幕：關閉';
	@override String osdSubtitles({required Object track}) => '字幕：${track}';
	@override String osdAudio({required Object track}) => '音訊：${track}';
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 框架',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 框架',
	);
	@override String get trackSelectionTitle => '選擇遊戲前的遊戲';
	@override String get trackSelectionAuto => '自動選擇';
	@override String get openMiniPlayer => '開放小型玩家';
	@override String get returnToFullPlayer => '回到全玩家';
	@override String get loadSubtitleFile => '查詢下載檔案...';
	@override String get subtitleLoadFailed => '未能下載字幕檔案';
	@override String get skipAds => '滑雪廣告';
	@override String get tapToUnlock => '點一下以解鎖';
	@override String get tapAgainToUnlock => '再次點一下以解鎖';
}

// Path: messages
class _Translations$messages$zh_Hant extends Translations$messages$zh {
	_Translations$messages$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => '已標記為已觀看';
	@override String get markedAsUnwatched => '已標記為未觀看';
	@override String get markedAsWatchedOffline => '已標記為已觀看（將在連線時同步）';
	@override String get markedAsUnwatchedOffline => '已標記為未觀看（將在連線時同步）';
	@override String autoRemovedWatchedDownload({required Object title}) => '已自動移除：${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '自動移除 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 觀看下載',
		other: '已自動移除 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 個已觀看的下載內容',
	);
	@override String get removedFromContinueWatching => '已從「繼續觀看」中移除';
	@override String errorLoading({required Object error}) => '錯誤：${error}';
	@override String get searchPartialResults => '部分媒體伺服器無法搜尋。目前顯示可取得的結果。';
	@override String get streamInterrupted => '影片串流中斷。請按播放鍵或拖動進度條重試。';
	@override String get liveStreamInterrupted => '直播串流中斷。請按播放鍵重試。';
	@override String get fileInfoNotAvailable => '無法取得檔案資訊';
	@override String get playbackAuthenticationRequired => '若要播放此項目，請重新登入媒體伺服器。';
	@override String get playbackServerUnavailable => '媒體伺服器目前無法使用。請稍後再試。';
	@override String get playbackDataInvalid => '伺服器傳回的播放資訊無效。';
	@override String get playbackCancelled => '播放已取消。';
	@override String get playbackFailed => '無法開始播放。';
	@override String playbackFailedDetail({required Object error}) => '無法開始播放：${error}';
	@override String get audioOutputFailed => '音訊輸出停止回應。請檢查電視或擴大機的音訊連接；如果其他應用程式也沒有聲音，請重新啟動裝置。';
	@override String get mediaUnavailable => '此內容已無法使用。';
	@override String errorLoadingFileInfo({required Object error}) => '載入檔案資訊時發生錯誤：${error}';
	@override String get errorLoadingSeries => '載入影集時發生錯誤';
	@override String get musicNotSupported => '目前不支援播放音樂';
	@override String get noDescriptionAvailable => '目前沒有描述';
	@override String get noProfilesAvailable => '沒有可用的使用者設定檔';
	@override String get contactAdminForProfiles => '請聯絡伺服器管理員新增使用者設定檔';
	@override String get unableToDetermineLibrarySection => '無法確定此項目的媒體庫分區';
	@override String get logsCleared => '日誌已清除';
	@override String get logsCopied => '日誌已複製到剪貼簿';
	@override String get noLogsAvailable => '沒有可用的日誌';
	@override String libraryScanning({required Object title}) => '正在掃描「${title}」…';
	@override String libraryScanStarted({required Object title}) => '已開始掃描「${title}」媒體庫';
	@override String libraryScanFailed({required Object error}) => '無法掃描媒體庫：${error}';
	@override String metadataRefreshing({required Object title}) => '正在重新整理「${title}」的中繼資料…';
	@override String metadataRefreshStarted({required Object title}) => '已開始重新整理「${title}」的中繼資料';
	@override String metadataRefreshFailed({required Object error}) => '無法重新整理中繼資料：${error}';
	@override String get logoutConfirm => '您確定要登出嗎？';
	@override String get noSeasonsFound => '找不到季數';
	@override String get seasonsLoadFailed => '無法載入季數';
	@override String get noEpisodesFound => '在第一季中找不到單集';
	@override String get noEpisodesFoundGeneral => '找不到單集';
	@override String get episodesLoadFailed => '無法載入單集';
	@override String get noResultsFound => '找不到結果';
	@override String sleepTimerSet({required Object label}) => '睡眠計時器已設定為 ${label}';
	@override String get noItemsAvailable => '沒有可用的項目';
	@override String get failedToCreatePlayQueueNoItems => '無法建立播放佇列 — 沒有項目';
	@override String failedPlayback({required Object action, required Object error}) => '無法${action}：${error}';
	@override String get switchingToCompatiblePlayer => '正在切換至相容的播放器…';
	@override String get serverLimitTitle => '播放失敗';
	@override String get serverLimitBody => '伺服器錯誤（HTTP 500）。伺服器的頻寬或轉碼限制可能拒絕此播放要求。請聯絡伺服器擁有者調整設定。';
	@override String get mediaUnreadableTitle => '檔案無法使用';
	@override String get mediaUnreadableBody => '伺服器找到了此項目，但無法讀取其檔案（HTTP 404）。檔案可能已移動、刪除，或其儲存空間離線。請聯絡伺服器擁有者檢查檔案並重新掃描媒體庫。';
	@override String get serverBusyTitle => '串流無法使用';
	@override String get serverBusyBody => '伺服器持續拒絕串流此檔案（HTTP 503）。伺服器可能正在重新啟動、忙碌中，或檔案所在的儲存裝置可能已離線。請稍後再試；若問題持續發生，請要求伺服器擁有者檢查伺服器及檔案所在的儲存裝置。';
	@override String get playbackNotAllowedTitle => '不允許播放';
	@override String get playbackNotAllowedBody => '伺服器拒絕串流此項目（HTTP 403）。此帳戶可能沒有播放權限，或伺服器可能只允許在其區域網路內播放。';
	@override String get logsUploaded => '日誌已上傳';
	@override String get logsUploadFailed => '上傳日誌失敗';
	@override String get logId => '日誌 ID';
	@override String get burnedSubtitlesUseMenu => '字幕已燒錄至此串流中。請從字幕選單變更字幕。';
	@override String get noVideoUrl => '沒有可用的視訊 URL';
	@override String get playbackNoMediaSources => '伺服器未傳回可播放的媒體來源';
	@override String get playbackDataNotPrepared => '播放資料尚未準備完成就已開始播放';
	@override String get streamSelectionUnavailable => '此來源不支援選擇串流';
	@override String get streamSelectionFailed => '無法套用所選串流';
	@override String get trackSelectionNotRemembered => '此軌道選擇僅套用於目前播放。';
	@override String get serverUnavailableForProfile => '使用中的使用者設定檔沒有可用的伺服器';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$zh_Hant extends Translations$subtitlingStyling$zh {
	_Translations$subtitlingStyling$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get previewSample => '快速的棕色<unk>子跳過可憐的狗';
	@override String get text => '文字';
	@override String get border => '邊框';
	@override String get background => '背景';
	@override String get fontSize => '字型大小';
	@override String get textColor => '文字顏色';
	@override String get borderSize => '邊框大小';
	@override String get borderColor => '邊框顏色';
	@override String get backgroundOpacity => '背景不透明度';
	@override String get backgroundColor => '背景顏色';
	@override String get position => '位置';
	@override String get assOverride => '覆蓋 ASS 樣式';
	@override String get overrideScale => '縮放';
	@override String get overrideForce => '強制套用';
	@override String get overrideStrip => '移除樣式';
	@override String get positionTop => '頂部';
	@override String get positionBottom => '底部';
	@override String get useMargins => '使用邊距';
	@override String get useMarginsDescription => '允許文字字幕顯示在影片畫面之外的區域。樣式字幕可能保留其原始位置。';
	@override String get anchorToScreen => '錨定至螢幕';
	@override String get anchorToScreenDescription => '在寬螢幕影片下方的黑邊顯示文字字幕';
	@override String get bold => '粗體';
	@override String get italic => '斜體';
	@override String get renderResolution => '渲染解析度';
	@override String get renderResolutionScreen => '螢幕解析度';
	@override String get renderResolutionVideo => '影片解析度';
	@override String get fontSizeDescription => '在此裝置上設定字幕文字大小。';
	@override String get textColorDescription => '選擇用於字幕文字的顏色。';
	@override String get borderSizeDescription => '設定字幕厚度周圍的字幕文字。';
	@override String get borderColorDescription => '選擇用於子標題輸出的顏色。';
	@override String get backgroundColorDescription => '選擇字幕文字背後的顏色。';
	@override String get backgroundOpacityDescription => '設定字幕背景透明度:0%是清晰的,100%是堅固的。';
	@override String get positionDescription => '垂直移動字幕:0%是影片的頂部,100%是底部。';
	@override String get assOverrideDescription => '選擇玩家是否遵循、調整、更換或刪除在 ASS 子標題中嵌入的風格。';
	@override late final _Translations$subtitlingStyling$assOverrideOptions$zh_Hant assOverrideOptions = _Translations$subtitlingStyling$assOverrideOptions$zh_Hant._(_root);
	@override String get renderResolutionDescription => '選擇使用的解析度來拉斯特化影象和ASS子標題. 較低的Android尺寸可以減少演示工作,但看起來更柔軟。';
	@override late final _Translations$subtitlingStyling$renderResolutionOptions$zh_Hant renderResolutionOptions = _Translations$subtitlingStyling$renderResolutionOptions$zh_Hant._(_root);
	@override String get boldDescription => '以更重的重量繪製字型。';
	@override String get italicDescription => '在義大利語中繪製字幕文字。';
}

// Path: mpvConfig
class _Translations$mpvConfig$zh_Hant extends Translations$mpvConfig$zh {
	_Translations$mpvConfig$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => '進階影片播放器設定';
	@override String get presets => '預設組';
	@override String get noPresets => '沒有儲存的預設組';
	@override String get saveAsPreset => '儲存為預設組…';
	@override String get presetName => '預設組名稱';
	@override String get presetNameHint => '輸入此預設組的名稱';
	@override String get loadPreset => '載入';
	@override String get deletePreset => '刪除';
	@override String get presetSaved => '預設組已儲存';
	@override String get presetLoaded => '預設組已載入';
	@override String get presetDeleted => '預設組已刪除';
	@override String get confirmDeletePreset => '確定要刪除此預設組嗎？';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# 註解';
	@override String get lineHint => 'option=value';
	@override String get addLine => '新增行';
	@override String get removeLine => '移除行';
	@override String get embeddedVoHint => '在 Linux 上會忽略 vo、gpu-context 和 gpu-api：嵌入式影片一律透過影片平面上的 vo=libmpv 轉譯，而 gpu-next（ArtCNN 等計算著色器需要它）無法以嵌入式方式執行。';
}

// Path: dialog
class _Translations$dialog$zh_Hant extends Translations$dialog$zh {
	_Translations$dialog$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => '確認操作';
}

// Path: profiles
class _Translations$profiles$zh_Hant extends Translations$profiles$zh {
	_Translations$profiles$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => '新增 PlezyNG 使用者設定檔';
	@override String get switchingProfile => '正在切換使用者設定檔…';
	@override String get deleteThisProfileTitle => '刪除此使用者設定檔？';
	@override String deleteThisProfileMessage({required Object displayName}) => '將移除 ${displayName}。連線資訊將不受影響。';
	@override String get active => '使用中';
	@override String get manage => '管理';
	@override String get delete => '刪除';
	@override String get signOut => '登出';
	@override String get signOutPlexTitle => '登出 Plex？';
	@override String signOutPlexMessage({required Object displayName}) => '確定要移除 ${displayName} 與所有 Plex Home 使用者嗎？您可以隨時重新登入。';
	@override String get signOutPlexDeleteDownloads => '一併刪除下載內容';
	@override String get signOutPlexDeleteDownloadsDescription => '否則下載內容會保留在此裝置上，並在您重新登入此帳號時恢復。';
	@override String get signedOutPlex => '已登出 Plex。';
	@override String get signOutFailed => '登出失敗。';
	@override String get sectionTitle => '使用者設定檔';
	@override String get summarySingle => '新增使用者設定檔，以同時管理託管使用者與本地身分';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} 個設定檔 · 使用中：${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} 個設定檔';
	@override String get removeConnectionTitle => '移除連線？';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => '將移除 ${displayName} 對 ${connectionLabel} 的存取權限。其他使用者設定檔仍可使用此連線。';
	@override String get deleteProfileTitle => '刪除使用者設定檔？';
	@override String deleteProfileMessage({required Object displayName}) => '將移除 ${displayName} 及其連線資訊。伺服器仍維持可用狀態。';
	@override String get profileNameLabel => '使用者設定檔名稱';
	@override String get pinProtectionLabel => 'PIN 碼保護';
	@override String get copyAutomationLink => '複製 Android 自動化連結';
	@override String get copyAutomationLinkDescription => '從 Android 意圖或自動化中選擇此檔案,檔案 PIN 檢查仍適用。';
	@override String get automationLinkCopied => '個人資料自動化連結複製。';
	@override String get pinManagedByPlex => 'PIN 碼由 Plex 管理。請至 plex.tv 進行編輯。';
	@override String get noPinSetEditOnPlex => '未設定 PIN 碼。如需啟用 PIN 碼限制，請在 plex.tv 編輯 Home 使用者設定。';
	@override String get setPin => '設定 PIN 碼';
	@override String get setPinTitle => '設定 PIN 碼';
	@override String get confirmPinTitle => '確認 PIN 碼';
	@override String get pinSet => 'PIN 碼已設定';
	@override String get changePin => '變更';
	@override String get removePin => '移除';
	@override String get connectionsLabel => '連線';
	@override String get add => '新增';
	@override String get deleteProfileButton => '刪除使用者設定檔';
	@override String get noConnectionsHint => '無連線 — 請新增一個連線以啟用此設定檔。';
	@override String get noConnections => '無連線資訊';
	@override String get plexHomeAccount => 'Plex Home 帳戶';
	@override String plexAccountChip({required Object account}) => 'Plex 帳戶：${account}';
	@override String plexAccountUserChip({required Object account, required Object user}) => '${account} 帳戶下的 ${user}';
	@override String get connectionDefault => '預設';
	@override String connectionAs({required Object displayName}) => '以 ${displayName} 身分';
	@override String get makeDefault => '設為預設值';
	@override String get removeConnection => '移除';
	@override String get profileRenamed => '使用者設定檔已重新命名。';
	@override String borrowAddTo({required Object displayName}) => '新增至 ${displayName}';
	@override String get borrowExplain => '共用另一個使用者設定檔的連線資訊。受 PIN 碼保護的設定檔需輸入 PIN 碼。';
	@override String get borrowEmpty => '目前沒有可共用的連線。';
	@override String get borrowEmptySubtitle => '請先將 Plex、Jellyfin 或 Emby 連線至另一個使用者設定檔。';
	@override String get borrowLoadFailed => '無法載入可用的連線。請重試。';
	@override String borrowFromProfile({required Object displayName}) => '來自 ${displayName}';
	@override String get borrowConnectionBorrowed => '已共用連線。';
	@override String get borrowFailed => '無法共用連線。';
	@override String get incorrectPin => 'PIN 碼不正確。';
	@override String get incorrectPinTryAgain => 'PIN 碼不正確。請重試。';
	@override String get sourceProfileMissingParentAccount => '來源使用者設定檔缺少其父帳戶資訊。';
	@override String get failedToLoadHomeUsers => '無法載入您的 Plex Home 使用者。請檢查網路連線後重試。';
	@override String get failedToVerifyPin => '無法驗證 PIN 碼。';
	@override String get newProfile => '建立使用者設定檔';
	@override String get profileNameHint => '例如：訪客、兒童、客廳';
	@override String get pinProtectionOptional => 'PIN 碼保護（選填）';
	@override String get pinExplain => '切換至此使用者設定檔時需要 4 位數 PIN 碼。';
	@override String get continueButton => '繼續';
	@override String get pinsDontMatch => 'PIN 碼不符合';
	@override String get tokenIdentityMismatch => 'Plex 使用者設定檔權杖解析到非預期的伺服器';
	@override String get settingsLocked => '此配置已鎖定。';
	@override String get unlockSettings => '解鎖設定';
	@override String get showExploreForProfile => '檢視此資料的探索';
	@override String get showExploreForProfileDescription => '關閉以從此個人資料的導航中刪除 Explore。';
}

// Path: connections
class _Translations$connections$zh_Hant extends Translations$connections$zh {
	_Translations$connections$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '連線';
	@override String get addConnection => '新增連線';
	@override String get addConnectionSubtitleNoProfile => '使用 Plex 登入或連線至 Jellyfin 或 Emby 伺服器';
	@override String addConnectionSubtitleScoped({required Object displayName}) => '新增至 ${displayName}：Plex、Jellyfin、Emby 或其他設定檔連線';
	@override String sessionExpiredOne({required Object name}) => '${name} 的工作階段已過期';
	@override String sessionExpiredMany({required Object count}) => '${count} 個伺服器的工作階段已過期';
	@override String accessDeniedOne({required Object name}) => '${name} 拒絕此帳戶存取';
	@override String accessDeniedMany({required Object count}) => '${count} 台伺服器拒絕此帳戶存取';
	@override String get signInAgain => '重新登入';
	@override String editMediaBrowserTitle({required Object product}) => '編輯 ${product} 連線';
	@override String editMediaBrowserIntro({required Object serverName}) => '為 ${serverName} 新增或移除 URL。PlezyNG 將使用延遲最低且可連線的 URL。';
}

// Path: accountPreferences
class _Translations$accountPreferences$zh_Hant extends Translations$accountPreferences$zh {
	_Translations$accountPreferences$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '帳戶偏好設定';
	@override String hubSubtitleSingle({required Object account}) => '已在 ${account} 上儲存音訊、字幕與媒體庫選項';
	@override String hubSubtitleMultiple({required Object count}) => '已在 ${count} 個帳戶上儲存音訊、字幕與媒體庫選項';
	@override String get pickAccount => '每個帳戶都會儲存各自的偏好設定。請選擇要編輯的帳戶。';
	@override String get storedOnAccount => '這些選項會儲存在帳戶本身，因此登入該帳戶的所有應用程式都會使用它們，包括您其他裝置上的 PlezyNG。';
	@override String get noAccounts => '沒有可設定的帳戶';
	@override String get noAccountsHint => '登入 Plex，或連線至 Jellyfin 或 Emby 伺服器，儲存在該帳戶上的偏好設定便會顯示在此處。';
	@override String get unavailable => '無法連線至此帳戶';
	@override String get loadFailed => '無法載入這些偏好設定';
	@override String get noPreference => '無偏好';
	@override String get notSet => '未設定';
	@override late final _Translations$accountPreferences$groups$zh_Hant groups = _Translations$accountPreferences$groups$zh_Hant._(_root);
	@override String get preferredAudioLanguage => '偏好音訊語言';
	@override String get autoSelectAudio => '依語言選擇音訊';
	@override String get autoSelectAudioDescription => '關閉時會使用檔案標記為預設的音訊軌。';
	@override String get preferredSubtitleLanguage => '偏好字幕語言';
	@override String get subtitleMode => '自動開啟字幕';
	@override late final _Translations$accountPreferences$subtitleModes$zh_Hant subtitleModes = _Translations$accountPreferences$subtitleModes$zh_Hant._(_root);
	@override String get subtitleAccessibility => 'SDH 字幕';
	@override late final _Translations$accountPreferences$subtitleAccessibilityOptions$zh_Hant subtitleAccessibilityOptions = _Translations$accountPreferences$subtitleAccessibilityOptions$zh_Hant._(_root);
	@override String get forcedSubtitles => '強制字幕';
	@override late final _Translations$accountPreferences$forcedSubtitleOptions$zh_Hant forcedSubtitleOptions = _Translations$accountPreferences$forcedSubtitleOptions$zh_Hant._(_root);
	@override String get displayMissingEpisodes => '顯示缺少的單集';
	@override String get displayMissingEpisodesDescription => '列出伺服器已知但沒有檔案的單集。';
	@override String get hidePlayedInLatest => '在「最新」中隱藏已觀看項目';
	@override String get hidePlayedInLatestDescription => '將您已觀看的項目從伺服器的「最新」列中移除。';
	@override String get displayCollectionsView => '顯示收藏集檢視';
	@override String get displayCollectionsViewDescription => '在您的媒體庫旁提供伺服器的收藏集檢視。';
	@override String get rewatchingInNextUp => '在「接下來播放」中保留重看的影集';
	@override String get rewatchingInNextUpDescription => '看完一部影集後再次開始觀看時，「接下來播放」會追蹤重看的進度，而不是將該影集移除。';
	@override String get watchedIndicator => '已觀看指示';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$zh_Hant watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$zh_Hant._(_root);
	@override String get mediaReviewsVisibility => '評分與評論';
	@override late final _Translations$accountPreferences$mediaReviewsOptions$zh_Hant mediaReviewsOptions = _Translations$accountPreferences$mediaReviewsOptions$zh_Hant._(_root);
	@override String get preferredAudioLanguageDescription => '在此語言中更喜歡音訊軌道,當伺服器或播放器自動選擇軌道時。';
	@override String get preferredSubtitleLanguageDescription => '自動選擇字幕時，優先選擇此語言的字幕軌。';
	@override String get subtitleAccessibilityDescription => '自動選擇字幕時，設定聽障字幕（SDH）為優先或必選。';
	@override String get forcedSubtitleDescription => '自動選擇字幕時，選擇優先使用強制字幕軌，或是必須使用強制字幕軌。';
	@override String get watchedIndicatorDescription => '選擇哪個媒體型別在伺服器介面中獲得觀看的檢查標誌。';
	@override String get mediaReviewsVisibilityDescription => '選擇哪個觀眾和批判評分伺服器在媒體頁面上顯示。';
	@override String get subtitleModeDescription => '在此伺服器帳戶中自動啟動子標題時選擇。';
	@override String get hubDescription => '這些偏好儲存在您的媒體伺服器帳戶上,並可能適用於其他客戶。';
}

// Path: discover
class _Translations$discover$zh_Hant extends Translations$discover$zh {
	_Translations$discover$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '發現';
	@override String get noContentAvailable => '沒有可用內容';
	@override String get addMediaToLibraries => '請向您的媒體庫新增一些媒體內容';
	@override String get continueWatching => '繼續觀看';
	@override String continueWatchingIn({required Object library}) => '繼續在 ${library} 觀看';
	@override String get nextUp => '接下來播放';
	@override String nextUpIn({required Object library}) => '接下來在 ${library} 播放';
	@override String get recentlyAdded => '最近新增';
	@override String recentlyAddedIn({required Object library}) => '最近新增至 ${library}';
	@override String latestAlbumsIn({required Object library}) => '${library} 中的最新專輯';
	@override String recentlyPlayedIn({required Object library}) => '最近在 ${library} 播放';
	@override String mostPlayedIn({required Object library}) => '在 ${library} 最常播放';
	@override String playEpisode({required Object season, required Object episode}) => '第 ${season} 季 第 ${episode} 集';
	@override String get overview => '概述';
	@override String get cast => '演員陣容';
	@override late final _Translations$discover$findNext$zh_Hant findNext = _Translations$discover$findNext$zh_Hant._(_root);
	@override String get extras => '預告片與花絮';
	@override String get studio => '製作商';
	@override String get rating => '分級';
	@override String get director => '導演';
	@override String get directors => '導演';
	@override String get movie => '電影';
	@override String get tvShow => '影集';
	@override String minutesLeft({required Object minutes}) => '剩餘 ${minutes} 分鐘';
	@override String get moreLikeThis => '更多類似內容';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '第${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}章',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 部作品',
	);
	@override late final _Translations$discover$person$zh_Hant person = _Translations$discover$person$zh_Hant._(_root);
}

// Path: errors
class _Translations$errors$zh_Hant extends Translations$errors$zh {
	_Translations$errors$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => '搜尋失敗：${error}';
	@override String get searchUnavailable => '搜尋無法連線至任何媒體伺服器。';
	@override String connectionTimeout({required Object context}) => '載入 ${context} 時連線逾時';
	@override String get connectionFailed => '無法連線至媒體伺服器';
	@override String unableToLoad({required Object context}) => '無法載入 ${context}。請重試。';
	@override String get noClientAvailable => '沒有可用用戶端';
	@override String get pleaseEnterToken => '請輸入 Token';
	@override String get invalidToken => 'Token 無效';
	@override String failedToVerifyToken({required Object error}) => '無法驗證 Token：${error}';
	@override String failedToSwitchProfile({required Object displayName}) => '無法切換至 ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => '無法刪除 ${displayName}';
	@override String get failedToRate => '無法更新評分';
	@override String get reasonTimedOut => '連線逾時';
	@override String get reasonUnreachable => '無法連線至媒體伺服器';
	@override String get reasonRefused => '媒體伺服器拒絕了此要求';
	@override String get reasonNotFound => '該項目已不在媒體伺服器上';
	@override String get reasonServerError => '媒體伺服器回報錯誤';
	@override String get reasonCancelled => '要求已取消';
	@override String get reasonUnexpected => '發生未預期的錯誤';
}

// Path: libraries
class _Translations$libraries$zh_Hant extends Translations$libraries$zh {
	_Translations$libraries$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => '隨機電影播放';
	@override String get randomPickFailed => '不能從這本圖書館選擇隨機電影。';
	@override String get title => '媒體庫';
	@override String get fallbackTitle => '媒體庫';
	@override String get scanLibraryFiles => '掃描媒體庫檔案';
	@override String get scanLibrary => '掃描媒體庫';
	@override String get analyze => '分析';
	@override String get analyzeLibrary => '分析媒體庫';
	@override String get refreshMetadata => '重新整理中繼資料';
	@override String get emptyTrash => '清空垃圾桶';
	@override String emptyingTrash({required Object title}) => '正在清空「${title}」的垃圾桶…';
	@override String trashEmptied({required Object title}) => '已清空「${title}」的垃圾桶';
	@override String failedToEmptyTrash({required Object error}) => '無法清空垃圾桶：${error}';
	@override String analyzing({required Object title}) => '正在分析「${title}」…';
	@override String analysisStarted({required Object title}) => '已開始分析「${title}」';
	@override String failedToAnalyze({required Object error}) => '無法分析媒體庫：${error}';
	@override String get noLibrariesFound => '找不到媒體庫';
	@override String get allLibrariesHidden => '所有媒體庫都已隱藏';
	@override String hiddenLibrariesCount({required Object count}) => '已隱藏的媒體庫（${count}）';
	@override String get thisLibraryIsEmpty => '此媒體庫為空';
	@override String get noItemsMatchFilters => '沒有符合目前篩選條件的項目';
	@override String get resetFilters => '重設篩選條件';
	@override String get all => '全部';
	@override String get clearAll => '全部清除';
	@override String scanLibraryConfirm({required Object title}) => '確定要掃描「${title}」嗎？';
	@override String analyzeLibraryConfirm({required Object title}) => '確定要分析「${title}」嗎？';
	@override String refreshMetadataConfirm({required Object title}) => '確定要重新整理「${title}」的中繼資料嗎？';
	@override String emptyTrashConfirm({required Object title}) => '確定要清空「${title}」的垃圾桶嗎？';
	@override String get manageLibraries => '管理媒體庫';
	@override String get sort => '排序';
	@override String get sortBy => '排序依據';
	@override String get filters => '篩選器';
	@override String get confirmActionMessage => '確定要執行此操作嗎？';
	@override String get showLibrary => '顯示媒體庫';
	@override String get hideLibrary => '隱藏媒體庫';
	@override String get libraryOptions => '媒體庫選項';
	@override String get content => '媒體庫內容';
	@override String get selectLibrary => '選擇媒體庫';
	@override String filtersWithCount({required Object count}) => '篩選器（${count}）';
	@override String get noRecommendations => '目前沒有推薦';
	@override String get noCollections => '此媒體庫中沒有收藏集';
	@override String get noFoldersFound => '找不到資料夾';
	@override String get folders => '資料夾';
	@override late final _Translations$libraries$tabs$zh_Hant tabs = _Translations$libraries$tabs$zh_Hant._(_root);
	@override late final _Translations$libraries$groupings$zh_Hant groupings = _Translations$libraries$groupings$zh_Hant._(_root);
	@override late final _Translations$libraries$filterCategories$zh_Hant filterCategories = _Translations$libraries$filterCategories$zh_Hant._(_root);
	@override late final _Translations$libraries$sortLabels$zh_Hant sortLabels = _Translations$libraries$sortLabels$zh_Hant._(_root);
	@override late final _Translations$libraries$advancedFilters$zh_Hant advancedFilters = _Translations$libraries$advancedFilters$zh_Hant._(_root);
	@override late final _Translations$libraries$selection$zh_Hant selection = _Translations$libraries$selection$zh_Hant._(_root);
}

// Path: about
class _Translations$about$zh_Hant extends Translations$about$zh {
	_Translations$about$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '關於';
	@override String get openSourceLicenses => '開源授權條款';
	@override String versionLabel({required Object version}) => '版本 ${version}';
	@override String get appDescription => '一款精美的 Plex、Jellyfin 與 Emby Flutter 用戶端';
	@override String get viewLicensesDescription => '查看第三方套件的授權條款';
	@override String get privacyPolicy => '隱私權政策';
}

// Path: serverSelection
class _Translations$serverSelection$zh_Hant extends Translations$serverSelection$zh {
	_Translations$serverSelection$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => '找不到 ${username}（${email}） 的伺服器';
	@override String failedToLoadServers({required Object error}) => '無法載入伺服器：${error}';
	@override String get noValidServers => '此帳號中找不到可用的伺服器';
}

// Path: hubDetail
class _Translations$hubDetail$zh_Hant extends Translations$hubDetail$zh {
	_Translations$hubDetail$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '標題';
	@override String get releaseYear => '發行年份';
	@override String get dateAdded => '新增日期';
	@override String get rating => '評分';
	@override String get noItemsFound => '找不到項目';
}

// Path: logs
class _Translations$logs$zh_Hant extends Translations$logs$zh {
	_Translations$logs$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => '清除日誌';
	@override String get copyLogs => '複製日誌';
	@override String get uploadLogs => '上傳日誌';
	@override String get saveLogs => '儲存存檔';
	@override String logsSaved({required Object path}) => '儲存到 ${path} 的存檔';
	@override String get saveLogsFailed => '無法儲存存檔。';
}

// Path: startup
class _Translations$startup$zh_Hant extends Translations$startup$zh {
	_Translations$startup$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'PlezyNG 無法啟動';
	@override String get failedBody => '啟動期間發生問題。下方詳細資料可識別失敗的原因。';
	@override String get failedBodyRepairable => 'PlezyNG 儲存的設定檔已損壞，必須先重建才能啟動。重試無法解決問題 — 請選擇「修復儲存空間」。';
	@override String get phaseLabel => '步驟';
	@override String get showDetails => '顯示詳細資料';
	@override String get hideDetails => '隱藏詳細資料';
	@override String get copyDetails => '複製詳細資料';
	@override String get detailsCopied => '詳細資料已複製到剪貼簿';
	@override String get uploadDetails => '上傳詳細資料';
	@override String get repairStorage => '修復儲存空間';
	@override String get repairTitle => '修復已儲存的資料？';
	@override String get repairBodyCommon => 'PlezyNG 的設定檔已損壞且無法讀取。修復會將所有設定重設為預設值。';
	@override String get repairBodyOneCredential => '有一筆已儲存的登入資訊損壞且無法讀取。修復僅會移除該筆資訊，其他設定將保持不變。';
	@override String get repairBodySignInsKept => '您的伺服器與使用者設定檔應可保持登入狀態。';
	@override String get repairBodySignInsLost => '保護已儲存登入資訊的金鑰無法從此檔案中復原，因此您必須重新登入每個伺服器與使用者設定檔。您媒體伺服器上的內容不受影響。';
	@override String get repairBodySessionsUncertain => '追蹤服務（MAL、AniList、Simkl、Trakt）與 Seerr 分別儲存，可能保留也可能遺失。PlezyNG 會明確告知保留了哪些項目。';
	@override String get repairConfirm => '修復';
	@override String get repairSucceeded => '儲存空間已修復';
	@override String get repairNeedsRestart => '儲存空間已修復 — 需要重新啟動';
	@override String get restartRequiredBody => '您的資料已修復，但 PlezyNG 必須重新啟動才能使用。請關閉 PlezyNG 後重新開啟。';
	@override String get quitPlezy => '退出 PlezyNG';
	@override String get repairFailed => '修復失敗';
	@override String get repairKeptSignIns => '您的伺服器與使用者設定檔仍保持登入狀態。';
	@override String get repairLostSignIns => '保護已儲存登入資訊的金鑰無法復原。您必須重新登入每個伺服器與使用者設定檔。';
	@override String get repairLostSessions => '至少一個追蹤服務或 Seerr 連線已遺失，必須重新連線。';
	@override String get backupTitle => '已保留損壞檔案的副本';
	@override String get backupWarning => '其中包含您的登入憑證。請勿上傳或分享。';
	@override String get deleteBackup => '刪除副本';
	@override String get backupDeleted => '副本已刪除。';
	@override String get previousFailureTitle => 'PlezyNG 上次啟動失敗';
}

// Path: licenses
class _Translations$licenses$zh_Hant extends Translations$licenses$zh {
	_Translations$licenses$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => '相關套件';
	@override String get license => '授權';
	@override String licenseNumber({required Object number}) => '授權條款 ${number}';
	@override String licensesCount({required Object count}) => '${count} 個授權條款';
}

// Path: navigation
class _Translations$navigation$zh_Hant extends Translations$navigation$zh {
	_Translations$navigation$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get libraries => '媒體庫';
	@override String get downloads => '下載';
	@override String get liveTv => '直播電視';
	@override String get explore => '探索';
}

// Path: explore
class _Translations$explore$zh_Hant extends Translations$explore$zh {
	_Translations$explore$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override late final _Translations$explore$mdblistShelves$zh_Hant mdblistShelves = _Translations$explore$mdblistShelves$zh_Hant._(_root);
	@override String get title => '探索';
	@override String get selectSource => '選擇來源';
	@override late final _Translations$explore$rows$zh_Hant rows = _Translations$explore$rows$zh_Hant._(_root);
	@override late final _Translations$explore$status$zh_Hant status = _Translations$explore$status$zh_Hant._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 集',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 集',
	);
	@override String get cast => '演員陣容';
	@override String get characters => '角色';
	@override String get addToWatchlist => '新增至待看清單';
	@override String get removeFromWatchlist => '從待看清單移除';
	@override String get addedToWatchlist => '已加入待看清單';
	@override String get removedFromWatchlist => '已從待看清單移除';
	@override String get watchlistUpdateFailed => '無法更新待看清單';
	@override String get watchlistNoMatch => '無法將此項目與待看清單配對';
	@override String get notInLibrary => '不在您的媒體庫中';
	@override String get inTheseLibraries => '在這些媒體庫中';
	@override String get checkingLibrary => '正在檢查您的媒體庫…';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '無法檢視 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 伺服器',
		other: '無法檢查 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 台伺服器',
	);
	@override String get emptyTitle => '這裡還沒有任何內容';
	@override String emptyMessage({required Object source}) => '當 ${source} 有內容時，相關資訊將顯示在此處。';
	@override String searchHint({required Object source}) => '搜尋 ${source}';
	@override String searchEmpty({required Object query}) => '沒有「${query}」的結果';
	@override String searchPrompt({required Object source}) => '在 ${source} 搜尋電影與影集。';
	@override String get searchFailed => '搜尋失敗。請檢查網路連線後重試。';
	@override late final _Translations$explore$badge$zh_Hant badge = _Translations$explore$badge$zh_Hant._(_root);
	@override late final _Translations$explore$stats$zh_Hant stats = _Translations$explore$stats$zh_Hant._(_root);
	@override late final _Translations$explore$season$zh_Hant season = _Translations$explore$season$zh_Hant._(_root);
	@override late final _Translations$explore$format$zh_Hant format = _Translations$explore$format$zh_Hant._(_root);
	@override late final _Translations$explore$sourceMaterial$zh_Hant sourceMaterial = _Translations$explore$sourceMaterial$zh_Hant._(_root);
	@override late final _Translations$explore$creditRole$zh_Hant creditRole = _Translations$explore$creditRole$zh_Hant._(_root);
	@override late final _Translations$explore$relation$zh_Hant relation = _Translations$explore$relation$zh_Hant._(_root);
	@override String broadcast({required Object day, required Object time}) => '${day} ${time} 播出';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => '${day} ${time} ${timezone} 播出';
	@override late final _Translations$explore$detail$zh_Hant detail = _Translations$explore$detail$zh_Hant._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 結果',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 筆結果',
	);
}

// Path: liveTv
class _Translations$liveTv$zh_Hant extends Translations$liveTv$zh {
	_Translations$liveTv$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '直播電視';
	@override String get guide => '節目表指南';
	@override String get noChannels => '沒有可用的頻道';
	@override String get noDvr => '沒有伺服器設定 DVR 錄影機';
	@override String get serverUnavailable => '直播電視伺服器無法使用。';
	@override String get serverNotConnected => '直播電視伺服器未連線。';
	@override String get noPrograms => '沒有可用的節目資料';
	@override String get liveStreamFailed => '即時串流失敗';
	@override String get unknownProgram => '未知節目';
	@override String get timelineLiveProgram => '直播程式(播放可能不在此程式)';
	@override String get timelineBuffer => '布菲爾時間表';
	@override String get timelineUnavailable => '時間不可用';
	@override String get timelineEstimated => '值得一提的Playback';
	@override String get timelinePending => '求求求';
	@override String get timelineStale => '時間表可能過時';
	@override String get unknownHub => '未知';
	@override String get unknownError => '未知錯誤';
	@override String channelNumber({required Object number}) => '頻道 ${number}';
	@override String get unknownChannel => '未知頻道';
	@override String get live => '直播';
	@override String get premiereBadge => '新';
	@override String get reloadGuide => '重新載入節目表指南';
	@override String get searchGuide => '搜尋節目表';
	@override String get searchHint => '搜尋頻道和節目';
	@override String searchNoResults({required Object query}) => '沒有符合「${query}」的結果';
	@override String get channelsSection => '頻道';
	@override String get programsSection => '節目';
	@override String get now => '現在';
	@override String get today => '今天';
	@override String get tomorrow => '明天';
	@override String get midnight => '午夜';
	@override String get overnight => '凌晨';
	@override String get morning => '上午';
	@override String get daytime => '白天';
	@override String get evening => '晚上';
	@override String get lateNight => '深夜';
	@override String get whatsOn => '正在播出';
	@override String get watchChannel => '觀看頻道';
	@override String get favorites => '最愛';
	@override String get reorderFavorites => '重新排序最愛頻道';
	@override String get noFavoriteChannels => '沒有最愛頻道';
	@override String get noFavoriteChannelsHint => '顯示所有頻道，然後長按頻道即可將其加入最愛。';
	@override String get showAllChannels => '顯示所有頻道';
	@override String get favoritesLoadFailed => '無法載入最愛頻道。請檢查網路連線後重試。';
	@override String get favoritesUpdateFailed => '無法更新最愛頻道。請檢查網路連線後重試。';
	@override String get joinSession => '加入進行中的「一起看」';
	@override String watchFromStart({required Object minutes}) => '從頭觀看（自 ${minutes} 分鐘前開始）';
	@override String get watchLive => '觀看直播';
	@override String get goToLive => '跳至直播點';
	@override String get record => '錄製';
	@override String get recordEpisode => '錄製單集';
	@override String get recordSeries => '錄製整部影集';
	@override String get recordOptions => '錄製選項';
	@override String get saveTo => '儲存至';
	@override String get recordings => '已錄製內容';
	@override String get scheduledRecordings => '已排程錄製';
	@override String get recordingRules => '錄製規則';
	@override String get noScheduledRecordings => '沒有排程的錄製任務';
	@override String get manageRecording => '管理錄製';
	@override String get cancelRecording => '取消錄製';
	@override String get cancelRecordingTitle => '取消此次錄製？';
	@override String cancelRecordingMessage({required Object title}) => '將不再錄製 ${title}。';
	@override String get deleteRule => '刪除規則';
	@override String get deleteRuleTitle => '刪除錄製規則？';
	@override String deleteRuleMessage({required Object title}) => '將不再錄製 ${title} 的後續單集。';
	@override String get recordingScheduled => '錄製已排程';
	@override String get alreadyScheduled => '此節目已安排排程錄製';
	@override String get dvrAdminRequired => 'DVR 設定需要管理員帳戶';
	@override String get recordingFailed => '無法安排錄製任務';
	@override String get recordingTargetMissing => '無法確定錄製媒體庫';
	@override String get recordNotAvailable => '此節目無法錄製';
	@override String get recordingCancelled => '錄製已取消';
	@override String get recordingRuleDeleted => '錄製規則已刪除';
	@override String get processRecordingRules => '重新評估規則';
	@override String get recordingInProgress => '正在錄製';
	@override String recordingsCount({required Object count}) => '已排程 ${count} 個';
	@override String get editRule => '編輯規則';
	@override String get editRuleAction => '編輯';
	@override String get recordingRuleUpdated => '錄製規則已更新';
	@override String get guideReloadRequested => '已要求更新節目表指南';
	@override String get guideReloadFailed => '無法重新載入節目表指南';
	@override String get rulesProcessRequested => '已要求重新評估規則';
	@override String get rulesProcessFailed => '無法重新評估錄影規則';
	@override String get recordShow => '錄製節目';
	@override late final _Translations$liveTv$recordSettings$zh_Hant recordSettings = _Translations$liveTv$recordSettings$zh_Hant._(_root);
	@override String startingInMinutes({required Object minutes}) => '${minutes} 分鐘後開始';
	@override String dayAtTime({required Object day, required Object time}) => '${day} ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} 傳回了無效的直播電視播放資料';
	@override String get failedToStartChannel => '無法啟動直播頻道';
	@override String get failedToBuildStreamUrl => '無法建立串流 URL';
	@override String playbackStartFailed({required Object reason}) => '無法開始播放此頻道：${reason}';
	@override String channelSwitchFailed({required Object reason}) => '無法切換頻道：${reason}';
}

// Path: collections
class _Translations$collections$zh_Hant extends Translations$collections$zh {
	_Translations$collections$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '收藏集';
	@override String get collection => '收藏集';
	@override String get empty => '收藏集為空';
	@override String get deleteCollection => '刪除收藏集';
	@override String deleteConfirm({required Object title}) => '確定要刪除「${title}」嗎？此操作無法復原。';
	@override String get deleted => '已刪除收藏集';
	@override String get deleteFailed => '刪除收藏集失敗';
	@override String deleteFailedWithError({required Object error}) => '刪除收藏集失敗：${error}';
	@override String get selectCollection => '選擇收藏集';
	@override String get collectionName => '收藏集名稱';
	@override String get enterCollectionName => '輸入收藏集名稱';
	@override String get addedToCollection => '已新增至收藏集';
	@override String get errorAddingToCollection => '新增至收藏集失敗';
	@override String get created => '已建立收藏集';
	@override String get removeFromCollection => '從收藏集移除';
	@override String removeFromCollectionConfirm({required Object title}) => '將「${title}」從此收藏集移除？';
	@override String get removedFromCollection => '已從收藏集移除';
	@override String get removeFromCollectionFailed => '從收藏集移除失敗';
	@override String removeFromCollectionError({required Object error}) => '從收藏集移除時發生錯誤：${error}';
	@override String get searchCollections => '搜尋收藏集…';
}

// Path: playlists
class _Translations$playlists$zh_Hant extends Translations$playlists$zh {
	_Translations$playlists$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '播放清單';
	@override String get playlist => '播放清單';
	@override String get noPlaylists => '找不到播放清單';
	@override String get create => '建立播放清單';
	@override String get playlistName => '播放清單名稱';
	@override String get enterPlaylistName => '輸入播放清單名稱';
	@override String get delete => '刪除播放清單';
	@override String get removeItem => '從播放清單中移除';
	@override String get smartPlaylist => '智慧播放清單';
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(count,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)}個項目',
	);
	@override String get emptyPlaylist => '此播放清單為空';
	@override String get deleteConfirm => '刪除播放清單？';
	@override String deleteMessage({required Object name}) => '確定要刪除「${name}」嗎？';
	@override String get created => '播放清單已建立';
	@override String get deleted => '播放清單已刪除';
	@override String get itemAdded => '已新增至播放清單';
	@override String get itemRemoved => '已從播放清單移除';
	@override String get selectPlaylist => '選擇播放清單';
	@override String get searchPlaylists => '搜尋播放清單…';
	@override String get errorCreating => '建立播放清單失敗';
	@override String get errorDeleting => '刪除播放清單失敗';
	@override String get errorLoading => '載入播放清單失敗';
	@override String get errorAdding => '新增至播放清單失敗';
	@override String get errorReordering => '重新排序播放清單項目失敗';
	@override String get errorRemoving => '從播放清單移除失敗';
}

// Path: music
class _Translations$music$zh_Hant extends Translations$music$zh {
	_Translations$music$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => '前往專輯';
	@override String get goToArtist => '前往演出者';
	@override String get instantMix => '即時混音';
	@override String get playNext => '下一首播放';
	@override String get addToQueue => '新增至佇列';
	@override String discNumber({required Object n}) => 'CD ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 路徑',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 首',
	);
	@override String get nowPlaying => '正在播放';
	@override String playingFrom({required Object title}) => '來自 ${title}';
	@override String get queue => '播放佇列';
	@override String get clearQueue => '清空佇列';
	@override String get lyrics => '歌詞';
	@override String get visualizer => '視覺化';
	@override String get visualizerProfileLoading => '閱讀路徑分析';
	@override String get visualizerAmbientMotion => '環境動作';
	@override String get visualizerPlexLoudness => 'Plex 噪音';
	@override String get visualizerPreviousPreset => '以前的視覺風格';
	@override String get visualizerNextPreset => '下一篇 視覺風格';
	@override String get visualizerPresetAurora => '奧拉';
	@override String get visualizerPresetBloom => '藍色';
	@override String get visualizerPresetOrbitals => '軌道';
	@override String get visualizerPresetPrism => '普里斯';
	@override String get visualizerPresetTunnel => '隧道';
	@override String get visualizerPresetTrackMap => '跟蹤地圖';
	@override String get noLyrics => '目前沒有歌詞';
	@override String get sleepTimer => '睡眠計時器';
	@override String get sleepTimerEndOfTrack => '曲目結束時';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 分鐘',
	);
	@override String get stopPlayback => '停止播放';
	@override String get previousTrack => '上一首';
	@override String get nextTrack => '下一首';
	@override String get repeat => '重複播放';
	@override String get repeatAll => '全部重複播放';
	@override String get repeatOne => '單曲重複播放';
	@override String get instantMixNoServer => '沒有可用於即時混音的伺服器';
	@override String get instantMixFailed => '無法載入即時混音';
	@override String get instantMixEmpty => '即時混音沒有產生任何曲目';
	@override String noAudioUrl({required Object track}) => '${track} 沒有可用的音訊 URL';
	@override late final _Translations$music$discography$zh_Hant discography = _Translations$music$discography$zh_Hant._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$zh_Hant extends Translations$watchTogether$zh {
	_Translations$watchTogether$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '一起看';
	@override String get description => '與親友同步觀看內容';
	@override String get createRoom => '建立房間';
	@override String get creatingRoom => '正在建立房間…';
	@override String get joinRoom => '加入房間';
	@override String get joiningRoom => '正在加入房間…';
	@override String get connecting => '正在連線…';
	@override String get relayPublic => '房間使用公開的 Open Watch Party 中繼伺服器。';
	@override String relayCustom({required Object url}) => '房間使用您位於 ${url} 的中繼伺服器。';
	@override String get recentRooms => '最近的房間';
	@override String get roomActions => '房間操作';
	@override String get renameRoom => '重新命名房間';
	@override String get removeRoom => '移除';
	@override String get enterRoomCode => '請輸入主持人提供的 6 字元代碼。';
	@override String get roomCode => '房間代碼';
	@override String get paste => '貼上';
	@override String get noCodeInClipboard => '剪貼簿中沒有房間代碼';
	@override String get copyCode => '複製代碼';
	@override String get codeCopied => '房間代碼已複製';
	@override String get shareInvite => '分享邀請';
	@override String get inviteCopied => '已複製邀請。請將其貼到訊息中。';
	@override String inviteMessage({required Object code}) => '來 PlezyNG 加入我的「一起看」房間：開啟「一起看」，選擇「加入房間」，然後輸入 ${code}。';
	@override String get openSessionControls => '開啟「一起看」工作階段控制面板';
	@override String get reconnecting => '正在重新連線…';
	@override String get reconnectingDescription => '連線已中斷。您將自動重新加入房間。';
	@override String get connected => '已連線';
	@override String get disconnected => '已中斷連線';
	@override String get youAreHost => '您是主持人';
	@override String hostedBy({required Object name}) => '主持人：${name}';
	@override String get hostControlsPlayback => '主持人控制播放';
	@override String get anyoneCanControl => '任何人都能控制播放';
	@override String get roomLocked => '房間已鎖定';
	@override String get nowPlaying => '正在播放';
	@override String get nothingPlaying => '目前沒有播放內容';
	@override String get nothingPlayingHost => '從任一媒體庫播放內容，即可與房間成員分享。';
	@override String get nothingPlayingGuest => '主持人播放內容時，會在這裡開啟。';
	@override String get notShareable => '這部影片在目錄中沒有相符項目，因此只有可存取同一台伺服器的人才能播放。';
	@override String get searching => '正在您的媒體庫中尋找這部影片…';
	@override String get yourCopy => '您的副本';
	@override String get sharingYourCopy => '您正在分享您的副本';
	@override String playingOtherLength({required Object difference}) => '正在播放您的副本，${difference}';
	@override String get mismatchTitle => '您的副本長度不同';
	@override String mismatchDescription({required Object difference}) => '您最接近的副本比房間的影片${difference}。可能是不同的剪輯版或版本。';
	@override String get playAnyway => '仍要播放';
	@override String get chooseAnotherCopy => '選擇其他副本';
	@override String get dontPlay => '不要播放';
	@override String get unavailableTitle => '您沒有這部影片';
	@override String get unavailableDescription => 'PlezyNG 無法在您的媒體庫中找到這部影片。請自行選擇副本，或重新搜尋。';
	@override String get chooseCopy => '選擇副本';
	@override String get searchAgain => '重新搜尋';
	@override String get noCandidates => '在您的媒體庫中找不到任何副本。';
	@override String get choiceFailed => '無法為房間播放此副本';
	@override String lengthLonger({required Object duration}) => '長了 ${duration}';
	@override String lengthShorter({required Object duration}) => '短了 ${duration}';
	@override String get lengthSame => '長度相同';
	@override String get lengthUnknown => '長度未知';
	@override String get joinCurrentPlayback => '加入目前播放點';
	@override String get joinCurrentPlaybackDescription => '同步至主持人目前的觀看進度';
	@override String get stopMedia => '為所有人停止影片';
	@override String get syncOffset => '同步偏移';
	@override String get syncOffsetDescription => '若您的影片比房間超前或落後，可在此調整。';
	@override String offsetHint({required Object difference}) => '您的副本比房間的影片${difference}。';
	@override String applyDifference({required Object offset}) => '套用 ${offset}';
	@override String get offsetMinusSecond => '-1 秒';
	@override String get offsetMinusTenth => '-100 毫秒';
	@override String get offsetPlusTenth => '+100 毫秒';
	@override String get offsetPlusSecond => '+1 秒';
	@override String get participants => '參與者';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 參與者',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 位參與者',
	);
	@override String get hostBadge => '主持人';
	@override String nameYou({required Object name}) => '${name}（您）';
	@override String get playerIdle => '閒置';
	@override String get playerLoading => '載入中';
	@override String get playerReady => '就緒';
	@override String get playerBuffering => '緩衝中';
	@override String get matchSearching => '搜尋中';
	@override String get matchMatched => '有此影片';
	@override String get matchMismatched => '長度不同';
	@override String get matchUnavailable => '沒有此影片';
	@override String participantOffset({required Object offset}) => '偏移 ${offset}';
	@override String get makeHost => '設為主持人';
	@override String get makeHostQuestion => '移交主持人？';
	@override String makeHostConfirm({required Object name}) => '${name} 將控制播放並主導所有人的工作階段。';
	@override String get transfer => '移交';
	@override String get removeParticipant => '從房間移除';
	@override String removeParticipantQuestion({required Object name}) => '要移除 ${name} 嗎？';
	@override String removeParticipantConfirm({required Object name}) => '${name} 將離開房間。除非您鎖定房間，否則對方可以使用代碼再次加入。';
	@override String get remove => '移除';
	@override String get roomSettings => '房間設定';
	@override String get letEveryoneControl => '允許所有人控制播放';
	@override String get lockRoom => '鎖定房間';
	@override String get lockRoomDescription => '不允許新成員加入';
	@override String get leaveRoom => '離開房間';
	@override String get leaveRoomQuestion => '要離開房間嗎？';
	@override String get leaveRoomConfirm => '您可以使用房間代碼再次加入。';
	@override String get leave => '離開';
	@override String get endRoom => '結束房間';
	@override String get endRoomQuestion => '要結束房間嗎？';
	@override String get endRoomConfirm => '這會為所有人結束此房間。';
	@override String get end => '結束';
	@override String get playBlockedTitle => '播放未開始';
	@override String get playBlockedDescription => '按下播放，開始與房間成員一起觀看。';
	@override late final _Translations$watchTogether$notices$zh_Hant notices = _Translations$watchTogether$notices$zh_Hant._(_root);
	@override late final _Translations$watchTogether$ended$zh_Hant ended = _Translations$watchTogether$ended$zh_Hant._(_root);
	@override late final _Translations$watchTogether$errors$zh_Hant errors = _Translations$watchTogether$errors$zh_Hant._(_root);
	@override String untitledEpisode({required Object number}) => '第 ${number} 集';
}

// Path: downloads
class _Translations$downloads$zh_Hant extends Translations$downloads$zh {
	_Translations$downloads$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '下載';
	@override String get manage => '管理';
	@override String get tvShows => '影集';
	@override String get movies => '電影';
	@override String get music => '音樂';
	@override String tracksQueued({required Object count}) => '已將 ${count} 首曲目加入下載佇列';
	@override String get noDownloads => '目前沒有下載內容';
	@override String get noDownloadsDescription => '下載的內容將顯示在此處，供您離線觀看';
	@override String get downloadNow => '下載';
	@override String get deleteDownload => '刪除下載內容';
	@override String get retryDownload => '重試下載';
	@override String get downloadQueued => '下載已排隊';
	@override String get downloadResumed => '下載已繼續';
	@override String get serverErrorBitrate => '伺服器錯誤：檔案位元率可能超過遠端位元率限制';
	@override String get storageFull => '為保護剩餘儲存空間，下載已停止。請釋出空間或選擇其他下載位置，然後再試一次。';
	@override String get storageUnavailable => '無法檢查可用儲存空間，因此下載已停止。請檢查下載位置後再試一次。';
	@override String episodesQueued({required Object count}) => '已將 ${count} 集影片加入下載佇列';
	@override String get downloadDeleted => '下載內容已刪除';
	@override String deleteConfirm({required Object title}) => '確定要從此裝置刪除「${title}」嗎？';
	@override String get deleteCollectionDownloads => '刪除下載內容';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => '確定要從此裝置刪除「${title}」中的所有下載內容嗎？';
	@override String get collectionDownloadsDeleted => '下載內容已刪除';
	@override String get cancelledDownloadTitle => '已取消的下載';
	@override String get cancelledDownloadMessage => '此下載已取消。您想要如何處理？';
	@override String get allEpisodesAlreadyDownloaded => '所有單集都已下載完成';
	@override String get resumeDownload => '繼續下載';
	@override String get cancelledDownload => '已取消的下載';
	@override String syncingFile({required Object file, required Object status}) => '${file}（正在同步 ${status}）';
	@override String downloadedFileClickToComplete({required Object file}) => '已下載 ${file} — 點選以完成';
	@override String get partialDownloadClickToComplete => '已部分下載 — 點選以完成';
	@override String get deleting => '正在刪除…';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => '正在刪除 ${title}…（${current}/${total}）';
	@override String get queuedTooltip => '已排隊';
	@override String queuedFilesTooltip({required Object files}) => '已排隊：${files}';
	@override String get downloadingTooltip => '正在下載…';
	@override String downloadingFilesTooltip({required Object files}) => '正在下載 ${files}';
	@override String get noDownloadsTree => '目前沒有下載內容';
	@override String get pauseAll => '全部暫停';
	@override String get resumeAll => '全部繼續';
	@override String get retryAll => '全部重試';
	@override String get retryFailed => '重試失敗的下載';
	@override String get deleteAll => '全部刪除';
	@override String get selectVersion => '選擇版本';
	@override String get allEpisodes => '所有單集';
	@override String get unwatchedOnly => '僅未觀看';
	@override String nextNUnwatched({required Object count}) => '接下來 ${count} 集未觀看';
	@override String get customAmount => '自訂數量…';
	@override String get customAmountAny => '每個數量(每個數...';
	@override String get randomEpisodes => '隨機事件';
	@override String get includeSpecials => '包含特別篇';
	@override String get howManyEpisodes => '要下載多少集？';
	@override String get invalidEpisodeCount => '請輸入有效的集數。';
	@override String get keepSynced => '保持同步';
	@override String get downloadOnce => '下載一次';
	@override String keepNUnwatched({required Object count}) => '保留 ${count} 個未觀看項目';
	@override String get editSyncRule => '編輯同步規則';
	@override String get removeSyncRule => '刪除同步規則';
	@override String removeSyncRuleConfirm({required Object title}) => '停止同步「${title}」？已下載的單集將會保留。';
	@override String removeListSyncRuleConfirm({required Object title}) => '停止同步「${title}」？';
	@override String get deleteSyncRuleDownloads => '一併刪除相關的下載內容';
	@override String get deleteSyncRuleDownloadsDescription => '供其他同步規則或使用者設定檔使用的下載內容將予以保留。';
	@override String syncRuleCreated({required Object count}) => '同步規則已建立 — 將保留 ${count} 個未觀看單集';
	@override String get syncRuleUpdated => '同步規則已更新';
	@override String get syncRuleRemoved => '同步規則已刪除';
	@override String get syncRuleAndDownloadsRemoved => '同步規則與相關的下載內容已刪除';
	@override String get syncRuleCleanupBusy => '同步規則正在更新中。請稍後再試。';
	@override String get syncRuleCleanupUnavailable => '無法安全地識別相關的下載內容。請重新連線伺服器後再試，或在不刪除下載內容的情況下移除規則。';
	@override String syncedNewEpisodes({required Object title, required Object count}) => '已為 ${title} 同步 ${count} 個新單集';
	@override String get syncNow => '現在的Sync';
	@override String get downloadsUpToDate => '下載到目前為止';
	@override String syncComplete({required Object queued, required Object removed}) => '合成完整 · ${queued} queued, ${removed} 刪除';
	@override String get activeSyncRules => '同步規則';
	@override String get reviewOrphanFiles => '檢查無對應紀錄的下載';
	@override String get orphanReviewTitle => '檢查無對應紀錄的下載';
	@override String get orphanReviewDescription => '這些已標記的檔案位於 PlezyNG 預設管理的下載資料夾中，但沒有相符的下載紀錄或進行中的工作。刪除前請先檢查清單。';
	@override String orphanReviewCount({required Object count, required Object size}) => '${count} 個檔案 · ${size}';
	@override String orphanDeleteFiles({required Object count}) => '刪除 ${count} 個檔案';
	@override String get orphanCleanupNone => '找不到無對應紀錄的下載檔案';
	@override String get orphanCleanupFailed => 'PlezyNG 無法安全地掃描受管理的下載資料夾。沒有刪除任何檔案。';
	@override String get orphanCleanupChanged => '檢查期間下載清單已變更。清理前請重新檢查檔案。';
	@override String orphanCleanupComplete({required Object count, required Object size}) => '已刪除 ${count} 個無對應紀錄的檔案 · 釋出 ${size}';
	@override String get noSyncRules => '沒有同步規則';
	@override String get manageSyncRule => '管理同步';
	@override String get editEpisodeCount => '單集數量';
	@override String get editSyncFilter => '同步篩選器';
	@override String get syncAllItems => '同步所有項目';
	@override String get syncUnwatchedItems => '同步未觀看項目';
	@override String syncRuleServerContext({required Object server, required Object status}) => '伺服器：${server} • ${status}';
	@override String get syncRuleAvailable => '可用';
	@override String get syncRuleOffline => '離線';
	@override String get syncRuleSignInRequired => '需要登入';
	@override String get syncRuleAccessDenied => '存取遭拒';
	@override String get syncRuleNotAvailableForProfile => '目前使用者設定檔無法使用';
	@override String get syncRuleUnknownServer => '未知伺服器';
	@override String get syncRuleListCreated => '同步規則已建立';
	@override late final _Translations$downloads$backgroundWarning$zh_Hant backgroundWarning = _Translations$downloads$backgroundWarning$zh_Hant._(_root);
	@override String get options => '下載選項';
	@override late final _Translations$downloads$groupings$zh_Hant groupings = _Translations$downloads$groupings$zh_Hant._(_root);
	@override String get unknownLibrary => '未知媒體庫';
	@override String get unknownShow => '未知節目';
	@override String get unknownSeason => '未知季度';
	@override String get unknownAlbum => '未知專輯';
	@override String completedOfTotal({required Object completed, required Object total}) => '已完成 ${completed}/${total}';
	@override String storageUsed({required Object size}) => '使用的儲存: ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}個下載',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}個下載',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 展覽',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 顯示',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 電影',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 電影',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}張專輯',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}張專輯',
	);
	@override String get errorFileNotFound => '找不到檔案（404）';
	@override String get errorDownloadNotAllowed => '伺服器不允許下載（403）';
	@override String get errorDownloadFailed => '下載失敗';
	@override String errorDownloadFailedWithReason({required Object reason}) => '下載失敗：${reason}';
	@override String get convertingOnServer => '轉換到伺服器';
	@override String convertingOnServerPercent({required Object percent}) => '轉換到伺服器 · ${percent}%';
	@override String errorHttpStatus({required Object status}) => '下載失敗（HTTP ${status}）';
	@override String errorPostProcessing({required Object reason}) => '後續處理失敗：${reason}';
	@override String get reasonFileNotSaved => '無法將檔案儲存到此裝置';
	@override String get reasonCannotResume => '無法繼續未完成的下載';
	@override String get reasonDeviceStorageFull => '此裝置的儲存空間已滿';
	@override String get notificationDownloading => '正在下載…';
	@override String get notificationComplete => '下載完成';
	@override String get notificationPaused => '下載已暫停';
}

// Path: shaders
class _Translations$shaders$zh_Hant extends Translations$shaders$zh {
	_Translations$shaders$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '著色器';
	@override String get noShaderDescription => '無影片增強效果';
	@override String get nvscalerDescription => 'NVIDIA 圖像縮放技術，使影片邊緣更清晰';
	@override String get artcnnVariantNeutral => '中性';
	@override String get artcnnVariantDenoise => '降噪';
	@override String get artcnnVariantDenoiseSharpen => '降噪 + 銳化';
	@override String get qualityFast => '快速';
	@override String get qualityHQ => '高品質';
	@override String get mode => '模式';
	@override String get importShader => '匯入著色器';
	@override String get customShaderDescription => '自訂 GLSL 著色器檔案';
	@override String get shaderImported => '著色器已匯入';
	@override String get shaderImportFailed => '匯入著色器失敗';
	@override String get deleteShader => '刪除著色器';
	@override String deleteShaderConfirm({required Object name}) => '刪除「${name}」？';
}

// Path: companionRemote
class _Translations$companionRemote$zh_Hant extends Translations$companionRemote$zh {
	_Translations$companionRemote$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '隨身遙控器';
	@override String connectedTo({required Object name}) => '已連線至 ${name}';
	@override String get unknownDevice => '未知裝置';
	@override late final _Translations$companionRemote$session$zh_Hant session = _Translations$companionRemote$session$zh_Hant._(_root);
	@override late final _Translations$companionRemote$pairing$zh_Hant pairing = _Translations$companionRemote$pairing$zh_Hant._(_root);
	@override late final _Translations$companionRemote$remote$zh_Hant remote = _Translations$companionRemote$remote$zh_Hant._(_root);
	@override late final _Translations$companionRemote$errors$zh_Hant errors = _Translations$companionRemote$errors$zh_Hant._(_root);
	@override String get closedBeforeAuth => '連線在驗證前已關閉';
}

// Path: videoSettings
class _Translations$videoSettings$zh_Hant extends Translations$videoSettings$zh {
	_Translations$videoSettings$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => '播放速度';
	@override String get normalSpeed => '正常速度';
	@override String sleepTimerActive({required Object duration}) => '執行中（${duration}）';
	@override String get zoom => '縮放';
	@override String get sleepTimer => '睡眠計時器';
	@override String get audioSync => '音訊同步調整';
	@override String get subtitleSync => '字幕同步調整';
	@override String get hdr => 'HDR';
	@override String get hdrUnsupported => '此處無法使用 HDR——這個桌面合成器或視訊輸出無法傳遞 HDR。';
	@override String get hdrToneMapping => 'HDR 色調映射';
	@override String get hdrToneMappingCompositor => '合成器';
	@override String get hdrToneMappingCompositorDescription => '直接傳遞來源的 HDR 中繼資料，並交由桌面合成器進行色調映射。';
	@override String get hdrToneMappingPlayer => '播放器';
	@override String get hdrToneMappingPlayerDescription => '在播放器中依顯示器的峰值亮度進行映射，再將結果告知合成器。';
	@override String get hdrToneMappingFailed => '無法變更 HDR 色調映射，先前的模式仍在使用中。';
	@override String get audioOutput => '音訊輸出';
	@override String get performanceOverlay => '效能監控';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => '環繞聲';
	@override String get audioOutputSpatial => '空間音訊';
	@override String get audioOutputStereo => '立體聲';
	@override String get audioEqualizer => '音訊平衡器';
	@override String get audioEqualizerDescription => '適用於此裝置的五個頻率帶;可在mpv上;一個活躍的EQ音訊解碼,並禁用匹配。';
	@override String get audioEqualizerFlat => '平板';
	@override String get audioEqualizerActive => '自訂';
	@override String get audioEqualizerSaveFailed => '無法儲存音訊平衡器設定。';
	@override String get backgroundVideoAudio => '背景影片音訊';
	@override String get backgroundVideoAudioDescription => '離開播放器後繼續播放影片音訊；返回前畫面會隱藏。Android 會顯示媒體播放通知。';
	@override String get audioNormalization => '音量標準化';
	@override String get audioNormalizationDisablesPassthrough => '將音訊解碼為 PCM；開啟時直通關閉';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$zh_Hant extends Translations$performanceOverlay$zh {
	_Translations$performanceOverlay$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get color => '色彩';
	@override String get performance => '效能';
	@override String get buffer => '緩衝';
	@override String get app => '應用程式';
	@override String get decoder => '解碼器';
	@override String get rawDecoder => '原始解碼器';
	@override String get tunneling => '通道模式';
	@override String get passthrough => '直通';
	@override String get aspect => '寬高比';
	@override String get rotation => '旋轉角度';
	@override String get dvSource => 'DV 來源';
	@override String get dvPath => 'DV 路徑';
	@override String get dvRouteDecoder => 'Dolby Vision 解碼器';
	@override String get dvRouteDecoderP81 => 'Dolby Vision 解碼器（P7→8.1）';
	@override String get dvRouteBaseLayer => '基礎層';
	@override String get dvRouteBaseLayerHdr10 => 'HDR10 基礎層';
	@override String get dvRouteBaseLayerHlg => 'HLG 基礎層';
	@override String get dvRouteBaseLayerSdr => 'SDR 基礎層';
	@override String get dvRouteReshaped => 'RPU 重塑（gpu-next）';
	@override String get dvRouteFelGraphActive => '實驗 P7 FEL 圖表(未合格)';
	@override String get p7Conversion => 'P7 轉換';
	@override String get sampleRate => '取樣率';
	@override String get pixelFormat => '像素格式';
	@override String get hwFormat => '硬體格式';
	@override String get matrix => '矩陣';
	@override String get primaries => '基色';
	@override String get transfer => '傳輸特性';
	@override String get renderFps => '渲染 FPS';
	@override String get displayFps => '螢幕 FPS';
	@override String get avSync => '影音同步（A/V Sync）';
	@override String get dropped => '丟格數（Dropped）';
	@override String get dvRpus => 'DV RPU 數';
	@override String get dvRpuAverage => 'DV RPU 平均';
	@override String get dvSampleAverage => 'DV 取樣平均';
	@override String get maxLuma => '最大亮度';
	@override String get minLuma => '最小亮度';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => '已用快取';
	@override String get cacheLimit => '快取上限';
	@override String get speed => '速度';
	@override String get player => '播放器';
	@override String get playMethod => '玩方法';
	@override String get memory => '記憶體';
	@override String get uiFps => '介面 FPS';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Android 硬體';
	@override String get decoderNvidiaHw => 'NVIDIA 硬體';
	@override String get decoderQualcommHw => 'Qualcomm 硬體';
	@override String get decoderMediatekHw => 'MediaTek 硬體';
	@override String get decoderExynosHw => 'Exynos 硬體';
	@override String get decoderSoftware => '軟體';
	@override String get decoderHardware => '硬體';
	@override String get tunnelingActive => '已啟用';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted}（${failures} 個失敗）';
}

// Path: externalPlayer
class _Translations$externalPlayer$zh_Hant extends Translations$externalPlayer$zh {
	_Translations$externalPlayer$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '外部播放器';
	@override String get useExternalPlayer => '使用外部播放器';
	@override String get useExternalPlayerDescription => '在其他應用程式中開啟影片';
	@override String get selectPlayer => '選擇播放器';
	@override String get customPlayers => '自訂播放器';
	@override String get systemDefault => '系統預設';
	@override String get addCustomPlayer => '新增自訂播放器';
	@override String get playerName => '播放器名稱';
	@override String get playerNameHint => '我的播放器';
	@override String get playerCommand => '執行命令';
	@override String get playerPackage => '套件名稱';
	@override String get playerUrlScheme => 'URL 協定架構（Scheme）';
	@override String get off => '關閉';
	@override String get launchFailed => '無法啟動外部播放器';
	@override String appNotInstalled({required Object name}) => '${name} 未安裝';
	@override String get playInExternalPlayer => '在外部播放器播放';
	@override String get description => '選擇另一個應用程式開啟影片,可用的玩家取決於您的裝置和安裝的應用程式。';
	@override String get systemDefaultDescription => '讓作業系統使用預設應用程式開啟影片。';
	@override String playerOptionDescription({required Object player}) => '使用 ${player} 開啟影片。';
	@override String get playerNameDescription => '標籤顯示在玩家列表中。';
	@override String get playerPackageDescription => '輸入玩家應用程式的Android包名稱,如com.example.player。';
	@override String get playerCommandDescription => '輸入該裝置安裝的播放器命令或可執行路徑。';
	@override String get playerUrlSchemeDescription => '輸入 URL 格式和可選的 URL 模板,用於啟動播放器。';
}

// Path: metadataEdit
class _Translations$metadataEdit$zh_Hant extends Translations$metadataEdit$zh {
	_Translations$metadataEdit$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => '編輯…';
	@override String get screenTitle => '編輯中繼資料';
	@override String get basicInfo => '基本資訊';
	@override String get artwork => '海報與背景';
	@override String get advancedSettings => '進階設定';
	@override String get title => '標題';
	@override String get sortTitle => '排序標題';
	@override String get originalTitle => '原始標題';
	@override String get releaseDate => '上映日期';
	@override String get contentRating => '內容分級';
	@override String get studio => '製片商';
	@override String get tagline => '宣傳標語';
	@override String get summary => '大綱簡介';
	@override String get poster => '海報';
	@override String get background => '背景圖';
	@override String get logo => '標誌（Logo）';
	@override String get squareArt => '方形圖片';
	@override String get selectPoster => '選擇海報';
	@override String get selectBackground => '選擇背景圖';
	@override String get selectLogo => '選擇標誌';
	@override String get selectSquareArt => '選擇方形圖片';
	@override String get fromUrl => '自訂網址';
	@override String get uploadFile => '上傳檔案';
	@override String get enterImageUrl => '輸入圖片 URL';
	@override String get imageUrl => '圖片 URL';
	@override String get metadataUpdated => '中繼資料已更新';
	@override String get metadataUpdateFailed => '中繼資料更新失敗';
	@override String get artworkUpdated => '封面圖片已更新';
	@override String get artworkUpdateFailed => '封面圖片更新失敗';
	@override String get noArtworkAvailable => '沒有可用的封面圖片';
	@override String artworkOption({required Object index}) => '封面圖片選項 ${index}';
	@override String selectedArtworkOption({required Object index}) => '封面圖片選項 ${index}，已選擇';
	@override String get notSet => '未設定';
	@override String get libraryDefault => '媒體庫預設';
	@override String get accountDefault => '帳戶預設';
	@override String get seriesDefault => '影集預設';
	@override String get episodeSorting => '單集排序方式';
	@override String get oldestFirst => '由舊到新';
	@override String get newestFirst => '由新到舊';
	@override String get keep => '保留集數';
	@override String get allEpisodes => '所有單集';
	@override String latestEpisodes({required Object count}) => '最新 ${count} 集';
	@override String get latestEpisode => '最新一集';
	@override String episodesAddedPastDays({required Object count}) => '過去 ${count} 天內新增的單集';
	@override String get deleteAfterPlaying => '播放後刪除單集';
	@override String get never => '從不';
	@override String get afterADay => '一天後';
	@override String get afterAWeek => '一週後';
	@override String get afterAMonth => '一個月後';
	@override String get onNextRefresh => '下次重新整理時';
	@override String get seasons => '季';
	@override String get show => '顯示';
	@override String get hide => '隱藏';
	@override String get episodeOrdering => '單集排序資料源';
	@override String get tmdbAiring => 'The Movie Database（播出順序）';
	@override String get tvdbAiring => 'TheTVDB（播出順序）';
	@override String get tvdbAbsolute => 'TheTVDB（絕對集數順序）';
	@override String get metadataLanguage => '中繼資料語言';
	@override String get useOriginalTitle => '使用原始標題';
	@override String get preferredAudioLanguage => '偏好音訊語言';
	@override String get preferredSubtitleLanguage => '偏好字幕語言';
	@override String get subtitleMode => '自動選擇字幕模式';
	@override String get manuallySelected => '手動選擇';
	@override String get shownWithForeignAudio => '外語配音時顯示';
	@override String get alwaysEnabled => '一律啟用';
	@override String get tags => '標籤';
	@override String get addTag => '新增標籤';
	@override String get genre => '類型';
	@override String get director => '導演';
	@override String get writer => '編劇';
	@override String get producer => '製片';
	@override String get country => '國家/地區';
	@override String get collection => '收藏集';
	@override String get label => '標記';
	@override String get quickTag => '快速標籤…';
}

// Path: matchScreen
class _Translations$matchScreen$zh_Hant extends Translations$matchScreen$zh {
	_Translations$matchScreen$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get match => '配對…';
	@override String get fixMatch => '修正配對…';
	@override String get unmatch => '取消配對';
	@override String get unmatchConfirm => '清除此配對資訊？在重新配對前，Plex 會將其視為未配對媒體。';
	@override String get unmatchSuccess => '已取消配對';
	@override String get unmatchFailed => '無法取消配對';
	@override String get matchApplied => '配對已套用';
	@override String get matchFailed => '套用配對失敗';
	@override String get titleHint => '標題';
	@override String get yearHint => '年份';
	@override String get search => '搜尋';
	@override String get noMatchesFound => '找不到符合的配對';
}

// Path: serverTasks
class _Translations$serverTasks$zh_Hant extends Translations$serverTasks$zh {
	_Translations$serverTasks$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '伺服器工作';
	@override String get failedToLoad => '載入工作失敗';
	@override String get noTasks => '目前沒有執行中的工作';
}

// Path: trakt
class _Translations$trakt$zh_Hant extends Translations$trakt$zh {
	_Translations$trakt$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => '已連線';
	@override String connectedAs({required Object username}) => '已以 @${username} 身分連線';
	@override String get disconnectConfirm => '中斷與 Trakt 帳戶的連結？';
	@override String get disconnectConfirmBody => 'PlezyNG 將停止向 Trakt 傳送事件。您可以隨時重新連線。';
	@override String get scrobble => '即時同步記錄（Scrobble）';
	@override String get scrobbleDescription => '在播放時向 Trakt 傳送播放、暫停和停止等狀態。';
	@override String get watchedSync => '同步已觀看狀態';
	@override String get watchedSyncDescription => '在 PlezyNG 中將項目標記為已觀看時，也會在 Trakt 上標記為已觀看。';
}

// Path: seerr
class _Translations$seerr$zh_Hant extends Translations$seerr$zh {
	_Translations$seerr$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => '連線至 Seerr';
	@override String get serverUrl => '伺服器 URL';
	@override String get serverUrlHelper => '您的 Seerr 執行個體的連線位址';
	@override String get checkServer => '繼續';
	@override String get signInWithJellyfin => '使用 Jellyfin 登入';
	@override String get signInWithEmby => '使用 Emby 登入';
	@override String get signInWithLocal => '使用本地帳戶';
	@override String get email => '電子郵件';
	@override String get noSignInMethods => '此 Seerr 執行個體未提供 PlezyNG 支援的登入方式。';
	@override String get instance => '執行個體';
	@override String get disconnectConfirm => '中斷與 Seerr 的連線？';
	@override String get disconnectConfirmBody => 'PlezyNG 將忘記此 Seerr 連線資訊。您可以隨時重新連線。';
	@override String get request => '請求';
	@override String get request4k => '請求 4K 版本';
	@override String get seasons => '季';
	@override String get allSeasons => '所有季數';
	@override String get advancedOptions => '進階設定';
	@override String get destinationServer => '目標伺服器';
	@override String get qualityProfile => '畫質設定檔（Quality Profile）';
	@override String get rootFolder => '根目錄資料夾';
	@override String get languageProfile => '語言設定檔（Language Profile）';
	@override String get tags => '標籤';
	@override String get noTags => '沒有標籤';
	@override String defaultOption({required Object name}) => '${name}（預設）';
	@override String get animeNote => '此影集為動畫。';
	@override String get requestSubmitted => '請求已送出';
	@override String requestFailed({required Object error}) => '請求失敗：${error}';
	@override String get requestsLoadFailed => '無法載入請求選項';
	@override String get nothingToRequest => '所有內容皆已可用或已提出請求。';
	@override String get statusAvailable => '可用';
	@override String get statusPartiallyAvailable => '部分可用';
	@override String get statusRequested => '已請求';
	@override String get statusProcessing => '處理中';
	@override String get statusBlocklisted => '已加入封鎖清單';
	@override String couldNotReach({required Object url, required Object error}) => '無法連線至 ${url}：${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => '在 ${url} 找不到 Seerr 執行個體（HTTP ${status}）';
	@override String get behindAuthProxy => '回應來自需要驗證的反向代理（SSO 或 HTTP 驗證），而非 Seerr。PlezyNG 無法透過它登入：請讓 Seerr 的 /api/v1 路徑為此應用程式繞過代理，或使用可直接連線至 Seerr 的位址。';
	@override String get invalidUrl => '請輸入伺服器位址，例如 https://seerr.example.com';
	@override String get quickConnectUnsupported => '此 Seerr 執行個體不支援 Quick Connect。需要 Seerr 3.4 或更新版本。';
	@override String get notInitialized => '此 Seerr 執行個體尚未完成首次執行設定';
	@override String get noPlexTokenForReauth => '沒有可用於重新登入的 Plex 權杖';
	@override String get noStoredCredentials => '沒有可用於重新登入的已儲存認證資訊';
	@override String get signInRejected => '登入遭到拒絕';
	@override String get noSessionCookie => 'Seerr 未發出工作階段 Cookie';
	@override String get freshCookieRejected => 'Seerr 拒絕了新的工作階段 Cookie';
	@override String get noUserInformation => 'Seerr 未傳回使用者資訊';
	@override String get sessionRejectedAfterReauth => '重新登入後，工作階段遭到拒絕';
	@override String get permissionDenied => 'Seerr 拒絕了此操作：您的帳戶不再具備所需權限';
	@override String get permissionRevoked => '您不再具有請求此內容的權限';
}

// Path: services
class _Translations$services$zh_Hant extends Translations$services$zh {
	_Translations$services$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '外部服務';
	@override String get hubSubtitle => '同步觀看進度並請求新內容。';
	@override String get integrations => '整合';
	@override String get notConnected => '未連線';
	@override String connectedAs({required Object username}) => '已以 @${username} 身分連線';
	@override String get scrobble => '自動同步播放進度';
	@override String get scrobbleDescription => '觀賞完一集或一部電影後自動更新您的外部列表。';
	@override String disconnectConfirm({required Object service}) => '中斷與 ${service} 的連線？';
	@override String disconnectConfirmBody({required Object service}) => 'PlezyNG 將停止更新 ${service}。您可以隨時重新連線。';
	@override String connectFailed({required Object service}) => '無法連線至 ${service}。請重試。';
	@override late final _Translations$services$names$zh_Hant names = _Translations$services$names$zh_Hant._(_root);
	@override late final _Translations$services$simklReconnect$zh_Hant simklReconnect = _Translations$services$simklReconnect$zh_Hant._(_root);
	@override late final _Translations$services$deviceCode$zh_Hant deviceCode = _Translations$services$deviceCode$zh_Hant._(_root);
	@override late final _Translations$services$oauthProxy$zh_Hant oauthProxy = _Translations$services$oauthProxy$zh_Hant._(_root);
	@override late final _Translations$services$pendingAuth$zh_Hant pendingAuth = _Translations$services$pendingAuth$zh_Hant._(_root);
	@override late final _Translations$services$libraryFilter$zh_Hant libraryFilter = _Translations$services$libraryFilter$zh_Hant._(_root);
	@override String get seerrDescription => '連線到 Seerr 或 Overseerr 以搜尋標題並提交媒體請求。';
	@override late final _Translations$services$trackerDescriptions$zh_Hant trackerDescriptions = _Translations$services$trackerDescriptions$zh_Hant._(_root);
}

// Path: addServer
class _Translations$addServer$zh_Hant extends Translations$addServer$zh {
	_Translations$addServer$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => '新增 ${product} 伺服器';
	@override String get serverUrls => '伺服器 URL';
	@override String get serverUrlsHelper => '可輸入多個連線網址，以逗號區隔。';
	@override String get findServer => '尋找伺服器';
	@override String searchingLocalMediaBrowserServers({required Object product}) => '正在尋找本機的 ${product} 伺服器…';
	@override String localMediaBrowserServers({required Object product}) => '本機的 ${product} 伺服器';
	@override String get username => '使用者名稱';
	@override String get password => '密碼';
	@override String get signIn => '登入';
	@override String get change => '變更';
	@override String get required => '必填';
	@override String couldNotReachServer({required Object error}) => '無法連線至伺服器：${error}';
	@override String signInFailed({required Object error}) => '登入失敗：${error}';
	@override String quickConnectFailed({required Object error}) => '快速連線失敗：${error}';
	@override String get addPlexTitle => '使用 Plex 登入';
	@override String get pinExpired => 'PIN 碼在登入前已過期。請重試。';
	@override String failedToRegisterAccount({required Object error}) => '註冊帳戶失敗：${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => '請輸入您的 ${product} 伺服器 URL';
	@override String get addConnectionTitle => '新增連線';
	@override String addConnectionTitleScoped({required Object name}) => '新增連線至 ${name}';
	@override String get signInWithPlexCard => '使用 Plex 登入';
	@override String get signInWithPlexCardSubtitle => '授權此裝置。將會新增共享的伺服器連線。';
	@override String get signInWithPlexCardSubtitleScoped => '授權 Plex 帳戶。Home 使用者會建立為個別的使用者設定檔。';
	@override String connectToMediaBrowserCard({required Object product}) => '連線至 ${product}';
	@override String get connectToMediaBrowserCardSubtitle => '輸入您的伺服器 URL、使用者名稱與密碼。';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => '登入您的 ${product} 伺服器。將綁定至 ${name}。';
	@override String get borrowFromAnotherProfile => '從另一個使用者設定檔共用';
	@override String get borrowFromAnotherProfileSubtitle => '重複使用另一個使用者設定檔的連線資訊。受 PIN 碼保護的使用者設定檔需輸入 PIN 碼。';
	@override String get invalidCredentials => '使用者名稱或密碼無效';
	@override String get authResponseNotJson => '驗證回應不是有效的 JSON';
	@override String get authResponseIncomplete => '伺服器傳回的登入回應不完整';
	@override String get quickConnectRejected => 'Quick Connect 遭到伺服器拒絕';
	@override String get quickConnectNotJson => 'Quick Connect 回應不是有效的 JSON';
	@override String get quickConnectMissingFields => 'Quick Connect 回應缺少代碼或密鑰';
	@override String get quickConnectPollRejected => 'Quick Connect 輪詢遭到伺服器拒絕';
	@override String get serverTimedOut => '伺服器未及時回應';
	@override String get responseNotJson => '伺服器回應不是有效的 JSON';
	@override String responseMissingIdentity({required Object product}) => '回應缺少 ID 或伺服器名稱——這是 ${product} 伺服器嗎？';
	@override String probeFailed({required Object error}) => '無法連線至伺服器：${error}';
	@override String enterAtLeastOneUrl({required Object product}) => '請輸入至少一個 ${product} 伺服器 URL';
	@override String noReachableServer({required Object product}) => '找不到可連線的 ${product} 伺服器';
	@override String urlsPointToDifferentServers({required Object product}) => '這些 URL 指向不同的 ${product} 伺服器';
	@override String urlDoesNotMatchServer({required Object product}) => '此 URL 與 ${product} 伺服器不符';
	@override String get redirectUnsupported => '伺服器重新導向至不支援的 URL';
	@override String redirectDifferentHost({required Object product}) => '伺服器重新導向至不同的主機。請直接輸入最終的 ${product} URL。';
	@override String get redirectInsecure => '伺服器從 HTTPS 重新導向至不安全的 URL';
	@override String redirectUnsupportedEnterFinal({required Object product}) => '伺服器重新導向至不支援的 URL。請直接輸入最終的 ${product} URL。';
	@override String get directPlexServerUrl => 'Plex 伺服器 URL';
	@override String get directPlexServerUrlHelper => '輸入您的 Plex 媒體伺服器的本地 IP 和埠。';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex 代幣(可選)';
	@override String get plexTokenHelper => '放空,如果在此伺服器上允許無 auth 訪問。';
	@override String get plexTokenRequired => '請輸入您的 Plex 代幣(X-Plex-Token)。';
	@override String get connectDirectPlexCard => 'Plex 媒體伺服器(直接/本地)';
	@override String get connectDirectPlexCardSubtitle => '直接使用本地IP或URL連線,無需 plex.tv 帳戶。';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => '直接使用本地IP或URL連線,連線到${name}。';
	@override String get insecureTitle => '未加密的連線';
	@override String insecureDescription({required Object url}) => '${url} 使用 HTTP。網路中的其他人可能讀取或竄改您的密碼、權杖和媒體內容。請盡可能使用 HTTPS。只有在您信任此網路並接受風險時才繼續。';
	@override String get allowHttp => '允許 HTTP';
	@override String get httpsRequired => '使用 HTTPS 或明確允許未加密的連線。';
}

// Path: cast
class _Translations$cast$zh_Hant extends Translations$cast$zh {
	_Translations$cast$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => '點選一個裝置';
	@override String get searching => '尋找卡片裝置';
	@override String connectedTo({required Object device}) => '連線到 ${device}';
	@override String get device => '加密裝置';
	@override String get readyToCast => '準備放';
	@override String get subtitle => '字幕';
	@override String get serverNotAvailable => '媒體伺服器不適用。';
	@override String get stopCasting => '停止加密';
	@override String get castToDevice => '點選裝置';
	@override String get noEpisodeAvailable => '沒有任何節目可播放。';
	@override String get startFailed => '無法開始投射,檢查伺服器並嘗試一次。';
}

// Path: automation
class _Translations$automation$zh_Hant extends Translations$automation$zh {
	_Translations$automation$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => '沒有活躍的影片會話可以控制。';
}

// Path: notifications
class _Translations$notifications$zh_Hant extends Translations$notifications$zh {
	_Translations$notifications$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => '新集';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appAccess
class _Translations$appAccess$zh_Hant extends Translations$appAccess$zh {
	_Translations$appAccess$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '每個功能都免費嘗試7天';
	@override String get description => '開始一個七天的試用,完全訪問每個PlezyNG功能,在試用期間沒有費用,沒有訂閱,試用後,在您的商店價格上一生購買,終身開鎖PlezyNG。';
	@override String get trialEndedDescription => '依商店顯示的價格一次性購買，即可終身解鎖 PlezyNG 的全部功能，無須訂閱。';
	@override String get startTrial => '開始我的7天免費試驗';
	@override String get trialActive => '您的7天全功能測試已活躍。';
	@override String get trialEnded => '你的七天審判結束了';
	@override String get trialStartFailed => '我無法在這個裝置上儲存測試,請再試一次。';
	@override String get lifetimeTitle => 'PlezyNG 終身禁用';
	@override String get lifetimeBody => '感謝!您終身訪問所有 PlezyNG 功能。';
	@override String get manageTitle => 'PlezyNG 終身訪問';
	@override String get manageDescription => '每個功能都免費嘗試7天,然後用一個付款解鎖一生的一切,以您的商店的價格。';
	@override String buy({required Object price}) => '解鎖所有功能為 ${price}';
	@override String get loadingPrice => '貨物價格...';
	@override String get retryPrice => '回報價格 檢視';
	@override String get restore => '恢復終身購買';
	@override String get pending => '您的購買正在等待付款或核准。商店完成交易後，終身使用權限將立即解鎖。';
	@override String get storeUnavailable => '目前無法購買。請確認您已登入商店，且此裝置允許購買。';
	@override String get productNotFound => 'PlezyNG 終身解鎖 目前尚未在本商店提供。';
	@override String get productQueryFailed => '無法收取商店價格,請檢查您的連線並嘗試一次。';
	@override String get purchaseFailed => '購買不錯了,再試一次。';
	@override String get restoreFailed => '無法到達商店恢復您的購買,再試一次。';
	@override String get nothingToRestore => '已找到第 PlezyNG 終身購買號,用於此商店帳戶。';
}

// Path: detail
class _Translations$detail$zh_Hant extends Translations$detail$zh {
	_Translations$detail$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => '預計 ${time} 結束';
}

// Path: watchLink
class _Translations$watchLink$zh_Hant extends Translations$watchLink$zh {
	_Translations$watchLink$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => '無法訪問 Plex 伺服器此連結。';
	@override String get notFound => '我無法在您的伺服器上找到此節目或電影 Plex。';
	@override String get ambiguous => '此連結匹配多個伺服器上的專案,並將伺服器新增到連結中。';
	@override String get plexOnly => '目前僅支援 Plex 伺服器的觀看連結。';
	@override String get unsupportedItem => '觀看連結只能開啟一個節目或電影。';
	@override String get menuItem => '檢視連結';
	@override String get dialogTitle => '檢視連結';
	@override String get dialogShowHint => '開啟此連結播放下一個節目. 新增 &mode=shuffle 到結尾播放節目在 shuffle 上。';
	@override String get dialogMovieHint => '開啟這個連結播放電影。';
	@override String get copy => '複製';
	@override String get copied => '連結複製';
}

// Path: homeLayout
class _Translations$homeLayout$zh_Hant extends Translations$homeLayout$zh {
	_Translations$homeLayout$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => 'Home 佈局';
	@override String get resetToast => '主頁重新設定到原始Plezy英雄配置';
	@override String get resetHeroTitle => '重定向英雄配置到儲存Plezy?';
	@override String get resetHeroBody => '關閉所有內容列的焦點橫幅設定，並恢復首頁頂端的單一輪播橫幅，如同引入焦點橫幅列之前的版面配置。內容列的順序和顯示狀態不受影響。';
	@override String get removeRowTitle => '取消家居序列?';
	@override String removeRowBody({required Object title}) => '${title} 將被刪除,此不能被刪除。';
	@override String get sync => '同步';
	@override String get syncAccountTitle => '與您的 Plex 帳戶同步配置';
	@override String get syncAccountOn => '開啟：此裝置會與您的其他裝置共用內容列順序、內容列、焦點橫幅和自動輪播設定。';
	@override String get syncAccountOff => '關閉:此裝置保持其自己的配置。';
	@override String get syncNow => '現在的Sync';
	@override String get plexHomeManager => 'Plex 主持人';
	@override String get managePlexRows => '管理 Plex 行在 Plezy';
	@override String get managePlexRowsDescription => '開放組織主選行列';
	@override String get organizeHomeRows => '安排家居行';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} 行: 移動, 英雄, 自動滑動, 移除';
	@override String organizeLibraryRows({required Object library}) => '組織 ${library} 行';
	@override String organizeLibraryRowsDescription({required Object n}) => '繼續觀看 + ${n} 行: 移動, 圖書館, 家, 英雄, 自動滑板';
	@override String get renderAsHero => '顯示為焦點橫幅';
	@override String get heroOnlySingleCollection => '只有當此行解決到單一集合的實際標題時才可用';
	@override String get hero => '焦點橫幅';
	@override String get autoSlide => '自動輪播';
	@override String get autoSlideDescription => '每隔幾秒也會自動切換。電腦上的箭頭按鈕和電視遙控器的方向鍵始終可用，使用後會重新開始計時。';
	@override String get autoSlideEditDescription => '每隔幾秒也會自動切換。關閉時，僅在點選電腦上的箭頭按鈕或按電視遙控器的左右方向鍵時切換。無論此設定是否開啟，箭頭按鈕和方向鍵都可用。';
	@override String get enableHeroFirst => '英雄第一';
	@override String get showOnHome => '顯示在主螢幕上';
	@override String get home => '首頁';
	@override String get removeFromHome => '離開家';
	@override String get selectRowsFirst => '首先,選擇下面的主行。';
	@override String plexManagedRows({required Object n}) => '${n} Plex 管理行';
	@override String get continueWatching => '繼續觀看';
	@override String get continueWatchingLibraryDescription => '圖書館的本質重建進展順序';
	@override String get continueWatchingHomeDescription => '重新進展序列顯示在家';
	@override String get nextUpHomeDescription => '下一篇 未觀看的集合序列在主頁上單獨顯示';
	@override String get library => '媒體庫';
	@override String get showInRecommended => '圖書館推薦';
	@override String get customPlexRow => '定製 Plex 行';
	@override String get heroNeedsLibrary => '檢視圖書館首先 - 英雄需要在某處展示';
	@override String get heroNeedsSurface => '檢視圖書館或家先 - 英雄需要在某處展示';
	@override String get removeHub => '取消 Hub';
	@override String get noPlexRows => '第Plex號管理行返回此圖書館。';
	@override String get openDetails => '開放細節';
	@override String get heroCards => '英雄卡';
	@override String get tapHeroCard => '打破英雄卡';
	@override String get tvPlayFocus => '電視遠端:突出點選播放按鈕';
	@override String get tvPlayFocusDescription => '按方向鍵下鍵時，焦點會先停在播放按鈕上，再移到下一列。關閉時會直接跳到下一列。';
	@override String get tvWrap => '電視遠端: loop 英雄卡';
	@override String get tvWrapDescription => '在最後一張卡片上按右鍵會回到第一張；關閉時則停在最後一張。在第一張卡片上按左鍵始終會進入側邊欄。';
	@override String get castOnHero => '在焦點橫幅上顯示演員';
	@override String get castOnHeroDescription => '在焦點橫幅底部顯示演員列表。關閉時僅保留標題和簡介。';
	@override String get customRows => '定位線';
	@override String get loading => '家用佈局...';
	@override String get noCustomRows => '尚未有定位';
	@override String get addRowHint => '使用新增主行建立一個。';
	@override String get addHomeRow => '新增 Home Rue';
	@override String get addHomeRowDescription => '選擇類別;新行將自動新增到組織者';
	@override String get removeRow => '取消行列';
	@override String get recentlyAdded => '最近新增';
	@override String get recentlyReleased => '最近釋出';
	@override String get movieCollections => '電影收藏';
	@override String get showCollections => '展示集合';
	@override String get rowTitle => '路 標題';
	@override String get content => '內容';
	@override String get showThisRowIn => '顯示此行在:';
	@override String get libraryRecommended => '推薦圖書館';
	@override String get heroCard => '英雄卡';
	@override String get heroCardDescription => '顯示為一個全寬旋轉卡,而不是海報架。';
	@override String get heroUnavailableDescription => '僅當此內容列顯示單一合輯中的實際媒體項目時才可用；選取多個合輯時，沒有可供輪播的單一媒體項目。';
	@override String get librariesSelection => '圖書館(所有未經檢查的圖書館都包含)';
	@override String get librariesMergedDescription => '這裡檢視的每一個圖書館都合併到這個單一的行列。';
	@override String get movieCollectionsSelection => '電影收藏(每個選擇的圖書館都沒有檢視)';
	@override String get showCollectionsSelection => '顯示收藏品(每個選擇的圖書館都沒有檢視)';
	@override String get collectionRowsDescription => '如果一個集合相匹配,其標題直接在序列中顯示;如果一個集合多,每個集合都顯示為單一的海報,則點選它以開啟該集合。';
	@override String get allCollections => '所有收藏';
	@override String get noRowsHere => '目前還沒有線條。';
	@override String get hideWatchedRows => '隱藏在行列中觀看的物品';
	@override String get hideWatchedRowsDescription => '已看完的媒體項目會從首頁和媒體庫的推薦列中移除，尚未看完的項目會保留。';
	@override String get untitledCollection => '未經標題收藏';
	@override String get moveRowHint => '向上/下: 移動行 · 選擇: 將此處放下 · 返回: 取消';
	@override String get organizeRowsHint => '選擇行(或保持):移動 · 左/右:行選項 · 返回:完成';
	@override String get layoutNavDescription => '選擇行、圖書館和收藏類別';
	@override String get editHomeRow => '編輯 主頁 序列';
	@override String get resetHeroButton => '恢復 Plezy 預設焦點橫幅配置';
	@override String get reorderingUnlocked => '重新排序 開鎖';
	@override String get reorderingLocked => '重新安排鎖';
	@override String get rowsCanBeDragged => '可以拖繩 - 點選鎖,以防止';
	@override String get tapLockToDrag => '點選鎖,拖行列';
	@override String customRowLabel({required Object title}) => '定位: ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => '隱藏';
	@override String get remove => '移除';
	@override String get libraryResumeRow => '圖書館的重複順序';
	@override String get pressAgainToDelete => '再次按下刪除';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => '到';
	@override String get resetHeroButtonDescription => '關閉所有內容列的焦點橫幅設定，並恢復頂端的單一輪播橫幅，如同引入焦點橫幅列之前的版面配置。內容列順序維持不變。';
	@override String get tapHeroCardDescription => '選擇打字或選擇一個英雄卡是否開始播放,或者開啟它的細節。';
	@override String get heroTapPlayDescription => '立即啟動所選擇的專案。';
	@override String get heroTapDetailsDescription => '在選擇行動之前,開啟所選專案的詳細資訊。';
}

// Path: platform
class _Translations$platform$zh_Hant extends Translations$platform$zh {
	_Translations$platform$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'PlezyNG 會連線至您區域網路中的媒體伺服器和播放裝置。';
	@override String get locationPermission => '當 iOS 要求提供位置權限才能偵測區域網路並連線至媒體伺服器時，PlezyNG 會使用此權限。';
	@override String get photoLibraryPermission => '從照片圖庫中選取圖片，用作媒體封面等影像。';
	@override String get cameraPermission => '掃描 QR 碼以配對 Companion Remote。';
}

// Path: universalMedia
class _Translations$universalMedia$zh_Hant extends Translations$universalMedia$zh {
	_Translations$universalMedia$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '開放媒體';
	@override String get shortcutHelp => '播放此會議的連結、播放列表或檔案。';
	@override String get intro => '開啟連結、播放列表或檔案 Playback 使用 PlezyNG 的標準播放器,並且不會將歷史新增到您的圖書館。';
	@override String get openWhat => '你想開啟什麼?';
	@override String get stream => '流地址';
	@override String get playlist => '播放列表';
	@override String get files => '裝置檔案';
	@override String get favorites => '儲存流喜愛';
	@override String get address => '媒體地址';
	@override String get addressHelp => 'HTTPS 是優先的. 有認可或簽名引數的 URL 僅用於此會議,並且不能儲存為喜愛。';
	@override String get displayName => '顯示名稱(可選)';
	@override String get displayNameHelp => '選擇玩家和系統媒體控制器的簡稱。';
	@override String get allowHttp => '允許未加密的 HTTP 連線';
	@override String get allowHttpHelp => 'HTTP 不加密連線. 只允許它在可靠的網路上. 當可能時使用 HTTPS。';
	@override String get advancedProtocols => 'MPV 僅:輸入 RTSP、RTMP/RTMPS、UDP 或 RTP 地址,這些地址不能儲存為最受歡迎的。';
	@override String get liveStream => '作為活著的待遇';
	@override String get liveStreamHelp => '使用此用於直播影片或廣播電臺. 該應用程式隱藏了時間欄,滑動按鈕和 go-to-time 選項。';
	@override String get privateSession => '只有此播放使用地址. 儲存一個合格流最喜歡的,以保持它在這個個人資料。';
	@override String get saveFavorite => '儲存最喜歡';
	@override String get playNow => '現在玩';
	@override String get favoriteSaved => '流喜愛儲存到此個人資料';
	@override String skippedEntries({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '${count} 不受支援或不安全的播放列表輸入。',
		other: '${count} 不受支援或不安全的播放列表輸入。',
	);
	@override String get playlistAddress => 'Playlist 地址';
	@override String get playlistAddressHelp => '從網頁地址開啟 M3U、M3U8 或 PLS 播放列表. Direct Stream 連結不會儲存播放名單。';
	@override String get choosePlaylist => '選擇 Playlist 檔案';
	@override String get openPlaylist => '開放播放列表';
	@override String get playlistFormatsHelp => '一張播放列表可以包含最多1000個專案和2MB的HLS顯示為流,所以玩家可以選擇質量。';
	@override String get noFavorites => '尚未儲存流喜愛. 喜愛留在此個人資料中。';
	@override String get removeFavorite => '刪除流喜愛';
	@override String get filesHelp => '選擇音訊、影片或ISO檔案,以便進行臨時記錄. 檔案和URL不新增到圖書館歷史。';
	@override String get chooseFiles => '選擇檔案';
	@override String fileQueue({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '1 選擇的檔案',
		other: '${count} 已選擇的檔案',
	);
	@override String get wifiTransfer => '透過 Wi-Fi 傳送檔案';
	@override String get wifiTransferHelp => '從同一信任網路的瀏覽器傳輸支援的檔案。';
	@override String get wifiTransferIntro => '在另一個裝置上的瀏覽器中開啟此地址. 選擇檔案以將其新增到該裝置的檔案和書籍圖書館。';
	@override String get wifiTransferPrivacy => '本裝置透過您的本地網路接收檔案. 任何知道此地址的人都可以傳送檔案,直到您停止傳輸或地址在15分鐘後終止。';
	@override String get wifiTransferStarting => '準備一個私人,時間有限的轉會...';
	@override String get wifiTransferUnavailable => '無法啟動轉換,檢查本地網路接入並嘗試一次。';
	@override String get openThisAddress => '在傳送裝置上開啟其中一個地址';
	@override String get copyAddress => '傳輸地址複製';
	@override String get addressCopied => '傳輸地址複製';
	@override String transferExpires({required Object time}) => '此地址在 ${time} 中終止。';
	@override String uploadCount({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '${count} 獲取檔案',
		other: '${count} 收到的檔案',
	);
	@override String uploadedData({required Object size}) => '接收 ${size}';
	@override String get stopTransfer => '停止轉讓和取消地址';
	@override String get startTransfer => '轉移開始';
	@override String get wifiImportedFiles => 'Wi-Fi 傳輸';
	@override String get wifiBrowserTitle => '向 PlezyNG 傳送檔案';
	@override String get wifiBrowserIntro => '選擇音訊、影片、電子書或漫畫檔案傳送. 這些檔案儲存在該裝置的檔案和書籍庫中. 最多: 100 個檔案,每個檔案 4 GiB,總共 10 GiB。';
	@override String get uploadFilesLabel => '檔案傳送';
	@override String get uploadSelected => '下載所選擇的檔案';
	@override String get uploadSelectFirst => '首先選擇一個或多個檔案。';
	@override String get uploading => '傳送';
	@override String get uploadComplete => '檔案新增到 PlezyNG。';
	@override String get uploadFailed => '檔案無法新增,請保持此頁面開放並再次嘗試。';
	@override String get liveCue => '生活';
	@override String get liveSession => '直播流';
	@override String get liveCueHelp => '對於直播影片或無線電,應用程式隱藏了時間欄和跳躍按鈕,它不會儲存地址或觀看歷史。';
	@override String get sessionOnly => '此播放僅是會話';
	@override String get sessionOnlyHelp => 'Playback 永遠不會儲存進展或歷史. 如果有資格,請將流作為最受歡迎的儲存在此個人資料中。';
	@override String get pictureAdjustments => '影象調整';
	@override String get pictureHelp => '這些影象變更隻影響此播放,它們在播放結束時重新設定。';
	@override String get resetPicture => '重新設定影象';
	@override String get brightness => '光明';
	@override String get contrast => '矛盾';
	@override String get gamma => '加姆';
	@override String get hue => '鬍子';
	@override String get saturation => '土星';
	@override String get view360 => '平板檢視360度影片';
	@override String get view360Help => 'MPV 需要 FFmpeg 的 v360 過濾器來檢視此檢視。';
	@override String get view360Unavailable => '這個MPV構建不能應用360度過濾器。';
	@override String get view360Yaw => '地平線視野';
	@override String get view360Pitch => '垂直視野';
	@override String get view360FieldOfView => '視野領域';
	@override String get recordStream => '記錄直播';
	@override String get stopRecording => '停止和儲存錄制';
	@override String get recordingStarted => '記錄是活躍的,讓播放停止並儲存錄制。';
	@override String get recordingSaved => '錄製完成並儲存。';
	@override String get recordingActive => '放棄播放停止並儲存它。';
	@override String get recordingFormatHelp => '對於影片,選擇 MKV 或 MPEG-TS. 為音訊,選擇 MKA 或 MKV。';
	@override String get replaceRecordingTitle => '取代這張錄音?';
	@override String get replaceRecordingHelp => 'PlezyNG 在錄製時備份現有檔案;如果無法儲存新錄製,PlezyNG 將備份恢復。';
	@override String get replaceRecording => '替換檔案';
	@override String get discHelp => '在此計算機的光學驅動器中開啟磁碟,您也可以從裝置檔案中開啟ISO影象。';
	@override String get discs => '光學磁碟';
	@override String get dvd => 'DVD';
	@override String get bluray => '藍光';
	@override String get audioCd => '音訊CD';
	@override String get discAvailability => '磁碟播放需要相容的MPV構建、支援的驅動器和作業系統許可,不能超越商業磁碟保護。';
	@override String get converterTitle => '轉換本地媒體檔案';
	@override String get converterHelp => '使用 FFmpeg 建立 MP4, M4A 或 MP3 副本。';
	@override String get converterIntro => '將本地音訊或影片檔案轉換為多個裝置上執行的格式。';
	@override String get converterPrivacy => 'FFmpeg 必須安裝在此計算機上. 轉換隻讀取本地檔案. 不下載流或刪除 DRM。';
	@override String get converterChooseInput => '選擇本地媒體檔案';
	@override String get converterFormat => '輸出格式';
	@override String get converterMp4 => 'MP4 · H.264 和 AAC';
	@override String get converterM4a => 'M4A · AAC 音訊';
	@override String get converterMp3 => 'MP3 · 音訊';
	@override String get converterSaveAs => '儲存轉換的媒體作為';
	@override String get converterExtensionMismatch => '選擇與所選輸出擴充套件的檔名。';
	@override String get converterUnsupportedInput => '選擇音訊或影片檔案。';
	@override String get converterLocalOnly => '所選擇的檔案不作為本地裝置路徑可用。';
	@override String get converterReplaceTitle => '取代此檔案?';
	@override String get converterReplaceHelp => 'PlezyNG 恢復現有檔案,直到轉換的副本被儲存。';
	@override String get converterStarting => '開始 FFmpeg...';
	@override String get converterProgress => '轉換到這個計算機......';
	@override String get converterComplete => '轉換完成,新檔案已準備好。';
	@override String get converterFfmpegMissing => 'FFmpeg 無法找到所需的編碼器. 使用 H.264, AAC 和 MP3 支援安裝 FFmpEG,然後再次嘗試。';
	@override String get converterFailed => '轉換失敗:檢查原始檔可以閱讀,目的地有足夠的免費空間。';
	@override String get converterCancelled => '轉換取消了,不完整的輸出被刪除。';
	@override String get converterDesktopOnly => '本地轉換可在桌面計算機上使用 FFmpeg 安裝。';
	@override String get converterStart => '轉換檔案';
	@override String get mediaToolsTitle => '媒體工具';
	@override String get mediaToolsShortcut => '捕獲或共享媒體,新增搜尋擴充套件或使用命令列。';
	@override String get mediaToolsIntro => '選擇一個專注的工具. 捕獲和流出使用 FFmpeg 安裝在這個桌面上. 擴充套件和 CLI 命令使用有限的 HTTPS 請求和現有 Open media 流。';
	@override String get mediaToolsAccessibility => '工具選項和控制器與觸控、指標、鍵盤和D-pad焦點工作。 錄製、共享和搜尋狀態的變化被公佈。';
	@override String get mediaTool => '媒體工具';
	@override String get captureIntro => '在此計算機上記錄螢幕或相機到 MP4 檔案. FFmpeg 必須安裝幷包含 H.264 編碼器。';
	@override String get captureNoDevices => '沒有螢幕或相機被發現 檢視 FFmpeg 捕捉支援和作業系統隱私許可證。';
	@override String get captureSource => '螢幕或相機';
	@override String get captureScreen => '螢幕';
	@override String get captureAudioSource => '音訊輸入(可選)';
	@override String get captureAudioHelp => '新增來自微型或可用的輸入的音訊 裝置選項取決於 FFmpeg 和系統許可。';
	@override String get captureAudioNone => '沒有音訊';
	@override String get captureDefaultAudio => '預設音訊輸入';
	@override String get captureWaylandHelp => 'Wayland 限制此 XWayland 捕獲到 X display. XWayland 以外的 Windows 可能不會出現。';
	@override String get captureFrameRate => '記錄框率';
	@override String get capturePrivacy => '錄製僅儲存到您選擇的檔案。 微型錄制是可選的. PlezyNG 不會上傳錄製。';
	@override String get captureSaveAs => '儲存螢幕錄製如';
	@override String get captureExtensionMismatch => '在 .mp4 中選擇終端的檔名。';
	@override String get captureFfmpegMissing => 'FFmpeg 或 H.264 影片編碼器不適用. 安裝支援的 FFmpeg 構建,然後再次嘗試。';
	@override String get captureFailed => '記錄無法儲存 檢查裝置許可、可用的儲存和 FFmpeg 支援。';
	@override String get captureSaved => '螢幕錄製儲存';
	@override String get captureElapsedLabel => '錄製時間';
	@override String get captureStart => '開始錄製';
	@override String get captureStop => '停止和拯救';
	@override String get captureMode => '捕捉';
	@override String get shareMode => '分享';
	@override String get shareIntro => '將本地媒體檔案傳送到您的私人網路上的另一個裝置. PlezyNG 建立一個暫時的 HLS 流。';
	@override String get sharePrivacy => '您的本地網路的任何人,誰接收私人連結可以觀看,而它是活躍的. 連結結束後60分鐘. 停止共享,關閉伺服器並取消連結。';
	@override String get shareChooseFile => '選擇媒體檔案';
	@override String get shareChooseHelp => '選擇一個本地的音訊或影片檔案. 該檔案留在此計算機上。';
	@override String get shareFfmpegMissing => 'FFmpeg 或 H.264/AAC 編碼器不適用. 安裝 FFmpeg 與 H.264 和 AAC 編碼支援。';
	@override String get shareFailed => '流量無法意外地開始或停止。 檢視 FFmpeg 和網路訪問。';
	@override String get shareActive => '流在您的私人網路上已經準備好了。';
	@override String get shareEnded => '媒體已經到達了結局,並且不再被分享。';
	@override String get shareStopped => '分享停止了,暫時連結不再有效。';
	@override String get shareUrlCopied => '流地址複製。';
	@override String get shareOpenUrl => '在另一臺裝置上的一個播放器中開啟此地址';
	@override String get shareQrLabel => '臨時流地址的QR程式碼';
	@override String get shareQrHelp => '掃描與同一私人網路連線的相容播放器。';
	@override String get shareHttpHint => '此流使用未加密的 HTTP. 在 PlezyNG 中,允許 HTTP 在開啟它之前。';
	@override String get shareCopyUrl => '複製流地址';
	@override String get shareExpiresLabel => '連結終止';
	@override String get shareStarting => '準備流...';
	@override String get shareStart => '開始分享';
	@override String get shareStop => '停止分享';
	@override String get extensionsMode => '擴充套件和CLI';
	@override String get extensionsIntro => '新增一個資料僅搜尋擴充套件,以找到媒體. 選擇一個結果,將其載入到熟悉的 Open media 表格。';
	@override String get extensionsPrivacy => '一個顯明可以定義一個 HTTPS 搜尋終點和地圖響應欄位. 它不能執行程式碼,新增請求標題,閱讀檔案,或啟動盾牌命令。';
	@override String get extensionImport => '新增擴充套件顯明';
	@override String get extensionEmpty => '尚未搜尋服務. 選擇一個可靠的顯明 JSON 檔案新增一個。';
	@override String get extensionChoose => '搜尋服務';
	@override String get extensionSearchConsent => '每個搜尋都會傳送您的單詞到這個 HTTPS 服務. 結果僅在您選擇一個後開啟。';
	@override String get extensionSearchLabel => '搜尋媒體';
	@override String get extensionSearch => '搜尋';
	@override String get extensionSearching => '尋找...';
	@override String get extensionNoResults => '沒有安全的媒體結果返回,請嘗試另一個搜尋。';
	@override String get extensionInstallTitle => '新增此搜尋服務?';
	@override String get extensionReplaceTitle => '更新此搜尋服務?';
	@override String get extensionService => '服務';
	@override String get extensionEndpoint => 'HTTPS 終點';
	@override String get extensionConsent => '您的搜尋文字被髮送到此服務. 該示文稿不包含執行程式碼. 繼續只有如果你信任這個終點。';
	@override String get extensionInstall => '新增服務';
	@override String get extensionReplace => '更新服務';
	@override String get extensionRemoveTitle => '刪除此搜尋服務?';
	@override String get extensionRemoveHelp => '這將取消該服務從此個人資料中. PlezyNG 不聯絡其終點。';
	@override String get extensionRemove => '取消服務';
	@override String get extensionInvalidManifest => '此檔案不是一個支援的擴充套件顯而易見. 檢視 Open media 格式指南。';
	@override String get extensionSaveFailed => '該擴充套件無法儲存到活躍的個人資料。';
	@override String get extensionSearchFailed => '搜尋服務沒有返回有效的答案 檢查終點並嘗試一次。';
	@override String get cliTitle => '命令線';
	@override String get cliHelp => '使用 plezyctl 指南來驗證一個顯明或搜尋相同的擴充套件. 每次搜尋之前,檢視 HTTPS 服務. 結果在現有媒體格式中開啟; 選擇播放按鈕開始。';
	@override String get cliCopyExample => '複製命令示例';
	@override String get cliCopied => '命令例子複製';
}

// Path: fileSources
class _Translations$fileSources$zh_Hant extends Translations$fileSources$zh {
	_Translations$fileSources$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '檔案和書籍';
	@override String get subtitle => '閱讀、聽、從自己的檔案中觀看。';
	@override String get add => '新增源';
	@override String get importFiles => '進口檔案';
	@override String get localFiles => '在此裝置上';
	@override String get source => '源';
	@override String get name => '名稱';
	@override String get endpoint => '伺服器 URL';
	@override String get smbEndpointHint => '範例：smb://nas/Movies';
	@override String get smbEndpointInvalid => '請輸入 SMB 伺服器和一個共用資料夾。';
	@override String get root => '資料夾或前綴';
	@override String get smbFolderHelp => '留空以使用整個共用資料夾，或輸入其中的某個資料夾。';
	@override String get username => '使用者名稱';
	@override String get smbDomain => '網域（選填）';
	@override String get password => '密碼';
	@override String get token => 'API 標誌';
	@override String get accessKey => '關鍵 ID 訪問';
	@override String get secretKey => '秘密訪問金鑰';
	@override String get sessionToken => '會議程式碼(可選)';
	@override String get region => '區域';
	@override String get clientId => '客戶 ID';
	@override String get clientSecret => 'OAuth 客戶端秘密(僅限 Google 桌面)';
	@override String get allowHttp => '允許在可信任的網路上使用未加密的 HTTP';
	@override String get smbEncryption => '加密 SMB3 連線';
	@override String get smbEncryptionHint => '當 NAS 支援時，使用 SMB3 加密。';
	@override String get connect => '連線';
	@override String get cancel => '取消';
	@override String get save => '儲存';
	@override String get close => '關閉';
	@override String get removeSource => '連線源';
	@override String get disconnectMessage => '要中斷此來源的連線嗎？已下載的檔案及閱讀和聆聽記錄會保留在此裝置上。';
	@override String get localFolder => '選擇資料夾';
	@override String get empty => '這裡還沒有任何內容';
	@override String get emptyHint => '新增來源，或匯入書籍、有聲書、音樂或影片。';
	@override String get search => '搜尋此資料夾';
	@override String get searchCached => '搜尋 儲存圖書館';
	@override String get refresh => '重新整理';
	@override String get loadMore => '載入更多';
	@override String get offline => '可用 offline';
	@override String get download => '保持離線';
	@override String get removeDownload => '刪除非線影印件';
	@override String get continueReading => '繼續閱讀';
	@override String get continueListening => '繼續聽';
	@override String get continueWatching => '繼續觀看';
	@override String get read => '閱讀';
	@override String get listen => '聽';
	@override String get play => '播放';
	@override String get pause => '暫停';
	@override String get stop => '停止';
	@override String get startOver => '開始過';
	@override String get finished => '播放完畢';
	@override String get markFinished => '馬克結束了';
	@override String get markUnfinished => '馬克 未完成';
	@override String get editions => '版和檔案';
	@override String get chapters => '章節';
	@override String get bookmarks => '書標和筆記';
	@override String get bookmark => '新增 Bookmark';
	@override String get highlight => '突出';
	@override String get note => '注目';
	@override String get delete => '刪除';
	@override String get export => '出口筆記';
	@override String get exported => '出口的筆記';
	@override String get sync => '同步進展';
	@override String get synced => '進展合成';
	@override String get conflict => '另一個裝置有不同的位置,選擇去哪裡。';
	@override String get useLocal => '使用此裝置';
	@override String get useRemote => '使用其他裝置';
	@override String get history => '位置歷史';
	@override String get groupAudio => '聽作一本音訊書';
	@override String get groupHint => '將目前在此資料夾中載入的音訊檔案結合起來. 首先載入所有頁面。';
	@override String get order => '檔案命令';
	@override String get moveUp => '移動上';
	@override String get moveDown => '移動下';
	@override String get speed => '播放速度';
	@override String get sleep => '睡眠計時器';
	@override String get sleepOff => '關閉';
	@override String get endChapter => '章節的結尾';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(count,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} 分鐘',
	);
	@override String get skipBack => '滑落回';
	@override String get skipForward => '滑向前';
	@override String get smartRewind => '休假後智慧迴歸';
	@override String get playbackOptions => '聽力選項';
	@override String remaining({required Object time}) => '${time} 剩餘';
	@override String get contents => '內容';
	@override String get readerSettings => '閱讀設定';
	@override String get fontSize => '文字大小';
	@override String get lineHeight => '線路空間';
	@override String get margin => '馬格林';
	@override String get font => '型號';
	@override String get serif => '襯線字型';
	@override String get sans => '無襯線字型';
	@override String get mono => '等寬字型';
	@override String get columns => '列';
	@override String get scroll => '垂直滑動';
	@override String get justify => '左右對齊';
	@override String get readerTheme => '頁面外觀';
	@override String get appTheme => '跟隨應用主題';
	@override String get paper => '紙張';
	@override String get sepia => '塞比亞';
	@override String get night => '夜晚';
	@override String get readAloud => '朗讀此頁';
	@override String get readAlong => '跟讀';
	@override String get stopReading => '停止朗讀';
	@override String get searchBook => '搜尋書中';
	@override String get noMatches => '沒有比賽';
	@override String get previousPage => '上一頁';
	@override String get nextPage => '下一頁';
	@override String page({required Object number}) => '頁面 ${number}';
	@override String get externalBlocked => '閱讀器中已停用書籍的外部連結。';
	@override String get loading => '開...';
	@override String get narrator => '講話者';
	@override String get audio => '音訊';
	@override String get video => '視訊';
	@override String get ebooks => '電子書';
	@override String get all => '全部';
	@override String get downloads => '非線檔案';
	@override String get confirmDelete => '要移除選取的離線副本嗎？閱讀或聆聽進度和筆記會保留。';
	@override String get errorAuthentication => '再登入,重新連線這個來源。';
	@override String get errorPermission => '此來源未授予所要求檔案的存取權限。';
	@override String get errorUnavailable => '源不可用 再試一次,或者開啟一個離線副本。';
	@override String get errorUnsupported => '此裝置不支援該格式或連線方式。請查看來源設定指南。';
	@override String get errorInvalidData => '此檔案或伺服器回覆無法安全地閱讀。';
	@override String get errorCancelled => '行動被取消了。';
	@override String get errorConflict => '閱讀或聆聽位置已在另一個工作階段變更。請重新開啟項目，選擇要使用的位置。';
	@override String get signIn => '登入';
	@override String get reconnect => '重新連線';
	@override String get folderHelp => '留空可從來源根目錄開始。S3 URL 包含儲存貯體名稱。';
	@override String get preferences => '偏好';
	@override String get timePosition => '位置';
	@override String get audioTrack => '音訊軌道';
	@override String get subtitleTrack => '標題 軌道';
	@override String get none => '無';
	@override String get fullscreen => '全螢幕';
	@override String get syncLocation => '進展同步資料夾(可選)';
	@override String get syncLocationHint => '用於儲存 PlezyNG 狀態的專用 WebDAV 資料夾。採用條件式寫入，不會變更媒體檔案。';
	@override String get audiobooks => '音訊書籍';
	@override String get comics => '漫畫';
	@override String get scan => '掃描書籍和媒體';
	@override String get browserReader => '開放讀者';
	@override String get browserReaderHelp => '閱讀器在您的瀏覽器中開放. 保持 PlezyNG 開放,以儲存您的位置和筆記。';
	@override String get on => '到';
	@override String get advancedSetup => 'App 登記';
	@override String get microsoftSignIn => '與Microsoft登入';
	@override String get zoomIn => '放大';
	@override String get zoomOut => '出Zoom';
	@override String get fitPage => '合適頁面';
	@override String get fitWidth => '合適的寬度';
	@override String get actualSize => '目前大小';
	@override String get goToPage => '去頁面';
	@override String get goToSection => '去章節';
	@override String pageRange({required Object count}) => '輸入 1 到 ${count} 的數字';
	@override String get pageLayout => '頁面Layout';
	@override String get automatic => '自動';
	@override String get singlePage => '單頁';
	@override String get twoPages => '二頁';
	@override String get readingDirection => '閱讀方向';
	@override String get leftToRight => '左向右';
	@override String get rightToLeft => '由右至左';
	@override String get letterSpacing => '信 空間';
	@override String get wordSpacing => '字 空間';
	@override String get readerControlsHelp => '張開雙指或使用縮放控制項放大頁面，拖曳可平移頁面。按 Ctrl/⌘ 與 + 或 − 調整縮放，按 Ctrl/⌘ 與 0 重設縮放。使用 Page Up 和 Page Down 翻頁。';
	@override String get imagePage => '漫畫頁面';
	@override String get resetReader => '重新設定閱讀偏好';
	@override String get zoom => '縮放';
	@override String get useFiles => '使用檔案和書籍';
	@override String get cancelScan => '取消掃描';
	@override String get googleDrive => 'Google Drive';
	@override String get offlineQuota => '離線下載限制';
	@override String get offlineQuotaHelp => '設定離線副本、匯入檔案及佇列中下載所使用的空間上限。降低上限不會移除現有副本。';
	@override String get offlineStorageUsage => '非線儲存';
	@override String get reservedStorage => '保留';
	@override String get downloadQueue => '下載Queue';
	@override String get downloadRunning => '下載';
	@override String get downloadQueued => '等待';
	@override String get downloadPaused => '休息';
	@override String get downloadFailed => '需要退休';
	@override String get importing => '進口';
	@override String get importInterrupted => '進口中斷 · 刪除清理';
	@override String get errorQuotaExceeded => '已達離線儲存空間上限。請提高上限或移除已下載的副本。';
	@override String get errorStorageLow => '沒有足夠的免費裝置儲存,以保留保護備份。';
	@override String get errorStorageUnavailable => 'PlezyNG無法檢查免費裝置儲存,所以寫作停止了。';
	@override String get removeDownloadJob => '刪除下載';
	@override String get downloadAlreadyComplete => '此下載完成之前,它可以被刪除. 該專案現在可用於離線。';
	@override String get confirmRemoveDownloadJob => '要移除此下載並捨棄已下載的部分資料嗎？閱讀位置和筆記會保留。';
}

// Path: lending
class _Translations$lending$zh_Hant extends Translations$lending$zh {
	_Translations$lending$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '公共圖書館';
	@override String get add => '新增圖書館';
	@override String get other => '另一家圖書館';
	@override String get libraryName => '圖書館名稱';
	@override String get libraryUrl => '圖書館網站';
	@override String get libraryUrlHint => '使用您的圖書館的目錄或登入頁面。';
	@override String get intro => '向圖書館借閱，讓書籍隨時相伴。';
	@override String get handoff => '登入、借款和安全閱讀,您圖書館的服務。';
	@override String get openService => '開放圖書館';
	@override String get findLibrary => '找個圖書館';
	@override String get search => '搜尋書籍和作家';
	@override String get catalogue => '目錄';
	@override String get loans => '借閱';
	@override String get holds => '預約';
	@override String get signIn => '與您的圖書館登入';
	@override String get waiting => '結束登入在您的瀏覽器,然後返回這裡。';
	@override String get cancel => '取消';
	@override String get disconnect => '取消圖書館';
	@override String get disconnectMessage => '要從此使用者設定檔移除此圖書館嗎？借閱和預約紀錄仍會保留在圖書館。';
	@override String get getBook => '獲書';
	@override String get checkAvailability => '檢視可用性';
	@override String get available => '可借閱';
	@override String get unavailable => '目前不可用';
	@override String get borrow => '借閱';
	@override String get placeHold => '預約借閱';
	@override String get returnBook => '提前歸還';
	@override String get cancelHold => '取消預約';
	@override String get confirmBorrow => '借這本書從圖書館裡?';
	@override String get confirmReturn => '現在歸還此書嗎？您可能需要重新借閱才能繼續閱讀。';
	@override String get confirmCancelHold => '要取消此書的預約嗎？';
	@override String get email => '留下通知電子郵件';
	@override String due({required Object date}) => '歸還日期：${date}';
	@override String queue({required Object position}) => '排隊位置：${position}';
	@override String get empty => '還沒有標題。';
	@override String get openLibraryNote => '探索 Open Library 的目錄。每本書的頁面都會顯示閱讀和借閱選項。';
	@override String get more => '載入更多';
	@override String get gateway => '圖書館登入服務';
	@override String get gatewayHint => '由您的圖書館或管理員提供,PlezyNG。';
	@override String get advanced => '圖書館整合';
	@override String get loadLibraries => '選擇您的圖書館';
	@override String get expired => '此借閱已到期。';
	@override String get updated => '圖書館更新';
	@override String get continueService => '繼續服務';
	@override String get comingSoon => '借款 即將到來';
	@override String get comingSoonDescription => '即將支援 Libby 整合。在連線功能完成之前，您可以先在 Libby 中使用圖書館服務。';
	@override String get suspendHold => '暫停預約';
	@override String get resumeHold => '恢復預約';
	@override String get suspendMessage => '要保留排隊位置，讓下一位讀者先借閱此副本嗎？您可以稍後恢復預約。';
	@override String get resumeMessage => '要恢復此預約，讓圖書館為您提供下一份可借閱的副本嗎？';
	@override String get editEmail => '更改通知電子郵件';
}

// Path: audiobook
class _Translations$audiobook$zh_Hant extends Translations$audiobook$zh {
	_Translations$audiobook$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get syncTitle => '閱讀與傾聽Sync';
	@override String get syncHelp => '在您的裝置上保持閱讀位置、傾聽位置、完成狀態、圖示和筆記。 選擇附加儲存帳戶並在每個裝置上使用相同的同步程式碼. 閱讀和傾聽保持分開。';
	@override String get addSyncSource => '首先將 Google Drive、OneDrive、Dropbox、WebDAV 或 S3 新增到檔案和書籍中。';
	@override String get syncDestination => '同步儲存帳戶';
	@override String get syncFolder => '同步資料夾或預定';
	@override String get syncFolderHelp => '在 WebDAV 源內使用一個單獨的現有資料夾,或一個專門的 S3 預定。';
	@override String get syncCode => '個人同步程式碼';
	@override String get syncCodeHelp => '在您的第一臺裝置上建立一個程式碼,然後在您的其他裝置上輸入該程式碼. 保持一個私人副本:它是您的加密狀態的關鍵。';
	@override String get showCode => '顯示或隱藏同步程式碼';
	@override String get newSyncCode => '建立一個新的同步程式碼';
	@override String get saveSync => '儲存和同步';
	@override String get disableSync => '在此裝置上關閉同步';
	@override String get syncSourceDisconnect => '移除此來源會停用此裝置上的閱讀與聆聽同步。加密的同步檔案仍會保留在儲存服務供應商端。';
	@override String get syncReconnect => '重新連線儲存帳戶';
	@override String lastSynced({required Object time}) => '上一篇: ${time}';
	@override String get syncPrivacy => '僅儲存加密的進度和筆記。音訊檔案、電子書檔案、帳戶權杖和密碼不會上傳。Google Drive 和 OneDrive 使用應用程式專用儲存空間；Dropbox 使用 PlezyNG Sync。啟用同步時，可能會要求額外的寫入權限。啟用後，進度同步由此儲存目標負責，伺服器進度維持獨立。關閉同步後，本機歷史記錄和遠端狀態仍會保留。';
	@override String get syncConflicts => '選擇重定向的地方';
	@override String get conflictHelp => '這些變更是各自獨立進行的。請選擇要保留的進度位置或書籤版本。時間戳記較新或進度百分比較高的版本不會自動優先保留。';
	@override String syncDevice({required Object device}) => '裝置 ${device}';
	@override String get syncUnknownDevice => '未知裝置';
	@override String get deletedBookmark => '刪除圖示';
	@override String get finished => '結束';
	@override String readingPosition({required Object percent}) => '閱讀 · ${percent}%';
	@override String get chapterTimeline => '第四章 進展';
	@override String get bookTimeline => '全書進展';
	@override String bookRemaining({required Object time}) => '本書剩餘時間：${time}';
	@override String chapterRemaining({required Object time}) => '此分類上一篇: ${time}';
	@override String get unknownRemaining => '全部時間可用,當部分被播放時';
	@override String get undoSeek => '最後尋找';
	@override String get customSpeed => '定製播放速度';
	@override String get speedHelp => '選擇速度從 0.25× 到 4×。';
	@override String get apply => '應用';
	@override String get customSleep => '定製睡眠時間';
	@override String get sleepMinutes => '時間(1 - 1440)';
	@override String sleepChapters({required Object count}) => '播放完${count}章後停止';
	@override String get extendSleep => '新增5分鐘';
	@override String sleepRemaining({required Object time}) => '睡眠時間: ${time}';
	@override String get useDefaults => '使用這些聽力控制器為新書';
	@override String get librarySort => '各式各樣的書籍';
	@override String get sortTitle => '標題';
	@override String get sortAuthor => '作者';
	@override String get sortNarrator => '講話者';
	@override String get sortSeries => '系列命令';
	@override String get sortRecent => '最近開放';
	@override String get statusFilter => '閱讀狀態';
	@override String get statusAll => '所有書籍';
	@override String get statusNew => '沒有開始';
	@override String get statusProgress => '進展';
	@override String get statusFinished => '結束';
	@override String get goToTime => '走到時間';
	@override String get timeHelp => '時間: 分鐘: 秒或 分鐘: 秒';
	@override String get recoveryHelp => '移動或修復同步資料前，請先匯出近期的加密備份。匯入資料會與目前狀態合併，不會取代本機同步記錄。請另外保存同步代碼。';
	@override String get recoveryExport => '輸出加密恢復檔案';
	@override String get recoveryImport => '輸入加密恢復檔案';
	@override String get recoveryImportConfirm => '將此加密恢復檔案與當前閱讀位置和筆記相結合嗎?現有歷史記錄將被保留. 共享圖書館和專案 ID 不包含; 在進口之前,在每個裝置上設定匹配 ID。';
	@override String get recoveryExported => '加密恢復檔案儲存。';
	@override String get recoveryImported => '恢復資料合併。';
}

// Path: sourceSetup
class _Translations$sourceSetup$zh_Hant extends Translations$sourceSetup$zh {
	_Translations$sourceSetup$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get savedCertificate => '已儲存的伺服器憑證';
	@override String get nfsEndpointInvalid => '請輸入 NFS 網址，例如 nfs://nas:2049/export。';
	@override String get dlnaNone => '找不到 DLNA 伺服器。請手動輸入裝置描述檔的網址。';
	@override String get dlnaServers => 'DLNA 媒體伺服器';
	@override String get dlnaUnavailable => '無法在此網路探索 DLNA 裝置。請手動輸入裝置描述檔的網址。';
	@override String get dlnaSearching => '正在區域網路搜尋 DLNA 伺服器';
	@override String get networkSearching => '正在搜尋區域網路…';
	@override String get dlnaDiscover => '探索 DLNA 伺服器';
	@override String get dlnaHelp => '裝置探索需要區域網路支援多點傳送。若未顯示伺服器，請在上方輸入裝置描述檔的網址。';
	@override String get dlnaRoot => 'DLNA 物件 ID；留空以使用裝置根目錄。';
	@override String get passwordOrKey => '請輸入密碼，或在下方新增私密金鑰。';
	@override String get sshFingerprint => 'SSH 主機金鑰 SHA256 指紋';
	@override String get sshFingerprintHelp => '請向伺服器管理員核實。在伺服器執行 ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub，並使用顯示的 SHA256 值。';
	@override String get sshFingerprintKeep => '留空以保留目前固定的指紋，或輸入新的伺服器指紋。';
	@override String get sshAuthentication => 'SSH 公開金鑰驗證';
	@override String get sshAuthenticationHelp => '選填；也支援密碼驗證。';
	@override String get privateKey => '私密金鑰（PEM 或 OpenSSH 格式）';
	@override String get privateKeyPassphrase => '私密金鑰密碼';
	@override String get nfsMountPort => 'NFS 掛載服務 TCP 連接埠';
	@override String get nfsMountPortHelp => '預設值：20048';
	@override String get nfsUserId => 'NFS 使用者 ID（AUTH_SYS）';
	@override String get nfsUserIdHelp => '預設值：1000。請使用 NAS 匯出設定允許的使用者 ID。';
	@override String get nfsGroupId => 'NFS 群組 ID（AUTH_SYS）';
	@override String get nfsGroupIdHelp => '預設值：1000。請使用 NAS 匯出設定允許的群組 ID。';
	@override String get nfsEncryption => '要求加密 NFS 連線（RPC-with-TLS）';
	@override String get nfsEncryptionHelp => '要求 NFS 和掛載服務使用 TLS 1.3。若 NAS 不支援，將拒絕連線。';
	@override String get nfsTrustCertificate => '自訂 NFS CA 或伺服器憑證（PEM，選填）';
	@override String get nfsTrustHelp => '使用此裝置信任的憑證時請留空。需要時可新增私人 CA 或自我簽署的伺服器憑證；憑證中的名稱必須與 NFS 網址的主機名稱相符。';
	@override String get nfsTrustInvalid => '請使用 PEM 格式的 CA 或伺服器憑證。請勿包含私密金鑰。';
	@override String get addTrustCertificate => '新增自訂信任憑證';
	@override String get replaceTrustCertificate => '取代已儲存的自訂憑證';
	@override String get nfsTlsHelp => 'RPC-with-TLS 使用一般的 NFS 和掛載服務連接埠，並要求 NAS 支援 RFC 9289。必須使用 TLS 1.3。主機名稱或 IP 位址必須與憑證相符。加密通道內仍須使用 AUTH_SYS UID/GID。';
	@override String get clientCertificate => '用戶端憑證（選填）';
	@override String get clientCertificateHelp => '讓 NAS 驗證此用戶端的身分；AUTH_SYS ID 仍受 NAS 匯出原則約束。';
	@override String get savedIdentity => '將使用已儲存的用戶端身分憑證。';
	@override String get replaceIdentity => '取代已儲存的用戶端身分憑證';
	@override String get chooseIdentity => '選擇 PKCS#12 用戶端身分憑證';
	@override String get identityPassphrase => '用戶端身分憑證密碼';
	@override String get identityPassphraseHelp => '如果檔案沒有密碼，請留空。';
	@override String get removeIdentity => '移除已儲存的用戶端身分憑證';
	@override String get identityStorageHelp => '用戶端身分憑證儲存在加密的來源認證資料儲存區。保持此區段不變，即可保留已儲存的身分憑證。';
	@override String get nfsLimitations => '透過 TCP 以唯讀方式使用 NFSv3。未使用 RPC-with-TLS 時，NFS 流量不會加密。NAS 必須允許所選 AUTH_SYS ID 和非特權用戶端連接埠（匯出選項通常稱為「insecure」）。不支援 NFSv4 和 UDP。';
	@override String get nfsSetupHelp => 'NFS 設定說明';
	@override String get nfsSetupHint => '若無法建立連線，請檢查這些設定。';
	@override String get nfsSetupDetails => '請使用透過 TCP 提供的 NFSv3 匯出。要求加密時，NFS 服務和掛載服務必須都支援 RPC-with-TLS。若伺服器憑證受此裝置信任，自訂憑證可留空；否則請新增 NAS 的 CA 或自我簽署憑證。憑證名稱必須與端點中的主機名稱相符。若 NAS 要求雙向 TLS，請新增其 PKCS#12 用戶端身分憑證。最後，確認匯出設定允許指定的 AUTH_SYS UID/GID 和用戶端連接埠原則。';
	@override String get ftpHelp => 'FTP 使用被動模式。未加密的 FTP 使用 ftp://，明確 TLS 使用 ftpes://；ftps:// 使用 TLS（連接埠 990 為隱含 TLS，其他連接埠為明確 TLS）。';
	@override String get openSubtitles => 'OpenSubtitles';
	@override String get subtitleSetup => '為獨立影片提供選用的字幕搜尋。';
	@override String get apiKey => 'API 金鑰';
	@override String get optionalUsername => '帳戶使用者名稱（選填）';
	@override String get optionalPassword => '帳戶密碼（選填）';
	@override String get subtitlePrivacy => '請從 opensubtitles.com 取得 API 金鑰。搜尋會傳送影片標題和可用的 IMDb/TMDB ID，絕不傳送影片檔案。金鑰和選填的帳戶認證資料會與此來源一同加密儲存。';
	@override String get automaticMetadata => '自動取得線上影片中繼資料';
	@override String get metadataPrivacy => '只傳送檔名中的標題、年份和集數，或 NFO ID，絕不傳送媒體或認證資料。NFO 欄位始終優先。';
	@override String get nfsEncryptionFailure => '使用加密 NFS 時，請確認 NAS 的兩項服務皆支援 RFC 9289 和 TLS 1.3，並核對憑證名稱及匯出 UID/GID。PlezyNG 不會在未加密的情況下重試此連線。';
	@override String get sourceConnecting => '正在連線至來源';
	@override String get metadataSearchPrivacy => '此標題搜尋由 Trakt 處理。只會傳送您輸入的標題，不會傳送影片或來源認證資料。';
	@override String get chooseMatch => '選擇符合的結果';
	@override String get metadataMatchHelp => '選擇前請核對標題與年份。Trakt 會收到搜尋標題；影片檔案會保留在原來源中。';
	@override String get metadataNoMatches => '找不到符合的線上標題。請嘗試其他標題。';
	@override String get metadataSearch => '搜尋線上中繼資料';
	@override String get metadataLoading => '正在查詢線上電影與影集資訊…';
	@override String get metadataFromTrakt => '來自 Trakt 的線上中繼資料';
	@override String get metadataNoAutomaticMatch => '找不到自動符合的標題。請搜尋標題並選擇符合的結果。';
	@override String get metadataFailed => '無法載入線上中繼資料。仍可播放媒體及查看本機資訊。';
	@override String get videoDetailsLoading => '正在載入影片資訊';
	@override String get subtitleKeyRequired => '需要 OpenSubtitles API 金鑰';
	@override String get subtitleKeyHelp => '請編輯此檔案來源，在選用的字幕設定中新增 OpenSubtitles API 金鑰。';
	@override String get subtitleSearchFailed => '字幕搜尋失敗。請檢查 API 金鑰、網路連線及服務存取權。';
	@override String get subtitleApplyFailed => '無法下載或套用此字幕。請檢查連線並嘗試其他結果。';
	@override String get subtitleSearch => '搜尋 OpenSubtitles';
	@override String get subtitleSearchPrivacy => '搜尋會使用標題和可用的 IMDb/TMDB ID。影片檔案會保留在原來源中。選擇前請核對語言、強制字幕或聽障字幕標記，以及評分。';
	@override String get movieOrShow => '電影或影集';
	@override String get subtitleTitleHint => '輸入標題以縮小結果範圍';
	@override String get subtitleLanguage => '字幕語言';
	@override String get subtitleSearching => '正在搜尋 OpenSubtitles';
	@override String get subtitleNoMatches => '找不到符合的字幕。請嘗試其他標題或語言。';
	@override String get downloadSubtitle => '下載字幕';
	@override String get subtitle => '字幕';
	@override String get nfsTlsRequired => '要求 RPC-with-TLS';
	@override String get nfsUnencrypted => '未加密的 NFS';
	@override String get tlsEncrypted => '已啟用 TLS 加密';
	@override String get ftpPlain => '未加密的 FTP';
	@override String get sshPinned => 'SSH 加密 · 已固定主機金鑰';
	@override String get smbEncrypted => 'SMB3 加密已開啟';
	@override String get smbUnencrypted => 'SMB3 加密已關閉';
	@override String get httpUnencrypted => 'HTTP 無傳輸加密';
	@override String get checkEndpointSecurity => '請檢查端點安全性';
	@override String fieldRequired({required Object label}) => '請填寫${label}。';
	@override String integerRange({required Object min, required Object max, required Object label}) => '請輸入 ${min} 至 ${max} 之間的${label}。';
	@override String replaceFile({required Object name}) => '取代 ${name}';
	@override String selectedIdentity({required Object name}) => '已選用戶端身分憑證：${name}';
	@override String subtitleRating({required Object rating}) => '評分 ${rating}';
	@override String subtitleDownloading({required Object title}) => '正在下載字幕：${title}';
	@override String get sharedEntryPair => '將此專案配對';
	@override String get sharedEntryPairHelp => '在每部裝置上為此項目輸入相同的 ID。使用固定的共用識別碼，或產生一組並複製到對應項目。只有當版本的檔案類型、大小和順序相符時，閱讀進度才會配對。留白會移除此對應。';
	@override String get sharedEntryId => '共享專案 ID';
	@override String get generateSharedEntryId => '建立共享專案 ID';
	@override String get sharedLibraryId => '共享圖書館 ID(可選)';
	@override String get sharedLibraryHelp => '使用相同 ID 在開啟相同圖書館的裝置上. 這個公共 ID 有助於在不同的來源連線中進行閱讀進步和筆記; 它不是密碼. 當提供商使用不同的專案 ID 時,將這些專案從其細節螢幕組合。';
	@override String get sharedLibraryInvalid => '使用 8 至 100 個字母、數字、點、字幕或字元。';
	@override String get generateSharedLibraryId => '建立共享圖書館 ID';
	@override String get nfsReadAhead => 'NFS Read-ahead 請求';
	@override String get nfsReadAheadHelp => '更多的平行閱讀可以改善快速NAS或網路的通道。使用1如果伺服器限制當前請求。';
	@override String get nfsReadTest => '測量NFS閱讀效能';
	@override String get nfsReadTestHelp => '從最大的檔案中讀到64 MiB,以測量這個NAS連線,這使用網路頻寬。';
	@override String get nfsQualificationResult => 'NFS 閱讀測量';
	@override String get nfsReadBytes => '資料閱讀';
	@override String get nfsReadSpeed => '測量速度';
	@override String get nfsReadRequests => '閱讀請求';
	@override String get sharedEntryConflict => '此共享專案 ID 已與本圖書館中的另一個專案相匹配. 選擇不同的 ID。';
}

// Path: comics
class _Translations$comics$zh_Hant extends Translations$comics$zh {
	_Translations$comics$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get fitHeight => '符合高度';
	@override String get readingMode => '閱讀模式';
	@override String get paged => '分頁';
	@override String get webtoon => '連續捲動';
	@override String get coverAlone => '單獨顯示封面';
	@override String get splitWide => '分割寬頁';
	@override String get splitWideHelp => '依閱讀順序分別顯示每一半。開啟後暫停雙頁並排顯示。';
	@override String get thumbnails => '頁面縮圖';
	@override String get controlsHelp => '滑動翻頁，點兩下切換顯示比例。連續捲動時，垂直滑動或使用 Page Up 和 Page Down。';
	@override String get savedForComic => '此個人檔案會記住這部漫畫的顯示設定。';
	@override String get readLists => '閱讀清單';
	@override String get collections => '合集';
}

// Path: games
class _Translations$games$zh_Hant extends Translations$games$zh {
	_Translations$games$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

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
class _Translations$deepLinks$zh_Hant extends Translations$deepLinks$zh {
	_Translations$deepLinks$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get invalid => '此 Plezy 連結不有效。';
	@override String profileNotFound({required Object profile}) => '沒有個人資料符合“${profile}”。';
	@override String get serverUnavailable => '我無法到達這個連結的伺服器。';
	@override String get notFound => '我無法在圖書館中找到這個標題。';
	@override String get unsupportedItem => '這個連結不能播放。';
	@override String get noLiveTv => '沒有現場電視伺服器可用於此連結。';
	@override String channelNotFound({required Object channel}) => '我找不到“${channel}”頻道。';
	@override String get showLink => '顯示連結';
	@override String get showProfileLink => '顯示個人資料連結';
	@override String get dialogTitle => '連結';
	@override String get showHint => '開啟此連結會播放下一集。若要隨機播放整個影集，請在結尾加上 &mode=shuffle。';
	@override String get movieHint => '開啟這個連結播放電影。';
	@override String get episodeHint => '開啟這個連結播放了這個節目。';
	@override String get profileHint => '開啟此連結轉換到這個個人資料。';
	@override String openAsProfile({required Object name}) => '開啟 ${name}';
	@override String get copy => '複製';
	@override String get copied => '連結複製';
}

// Path: householdSetup
class _Translations$householdSetup$zh_Hant extends Translations$householdSetup$zh {
	_Translations$householdSetup$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '家庭設定';
}

// Path: issueReport
class _Translations$issueReport$zh_Hant extends Translations$issueReport$zh {
	_Translations$issueReport$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '回報問題';
	@override String get instructions => '掃描 QR 碼即可開啟已預填的 GitHub 草稿。請先檢查內容，準備好後再送出。';
	@override String get privacy => '草稿包含應用程式版本、平台和連線數量，不包含伺服器位址、帳戶或個人資料名稱、媒體標題及檔案路徑。';
	@override String get logPrivacy => '記錄檔為選填。上傳前請先檢查。記錄檔 ID 會加入草稿，而問題可能是公開的。';
	@override String get openDraft => '開啟 GitHub 草稿';
}

// Path: appIcon.names
class _Translations$appIcon$names$zh_Hant extends Translations$appIcon$names$zh {
	_Translations$appIcon$names$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get midnight => '午夜';
	@override String get ember => '餘燼';
	@override String get paper => '紙張';
	@override String get oled => 'OLED';
	@override String get line => '線條';
	@override String get ocean => '海洋';
	@override String get ultraviolet => '紫外線';
	@override String get matcha => '抹茶';
	@override String get sunset => '日落';
	@override String get gold => '金色';
	@override String get titanium => '鈦金屬';
	@override String get glass => '玻璃';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => 'Synthwave';
	@override String get pixel => '像素';
	@override String get neon => '霓虹';
	@override String get sticker => '貼紙';
	@override String get ticket => '票券';
	@override String get pop => '普普風';
	@override String get strata => '層疊';
	@override String get facet => '切面';
	@override String get tilde => '波浪號';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$zh_Hant extends Translations$common$ratingSource$zh {
	_Translations$common$ratingSource$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

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
class _Translations$common$mediaKind$zh_Hant extends Translations$common$mediaKind$zh {
	_Translations$common$mediaKind$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get movie => '電影';
	@override String get show => '劇集';
	@override String get season => '季';
	@override String get episode => '單集';
	@override String get artist => '藝術家';
	@override String get album => '專輯';
	@override String get track => '曲目';
	@override String get collection => '合集';
	@override String get playlist => '播放清單';
	@override String get clip => '短片';
	@override String get photo => '相片';
	@override String get folder => '資料夾';
}

// Path: settings.startupSectionOptions
class _Translations$settings$startupSectionOptions$zh_Hant extends Translations$settings$startupSectionOptions$zh {
	_Translations$settings$startupSectionOptions$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get discover => '從連線的發現來源開啟建議和專案。';
	@override String get libraries => '開啟您的連線媒體圖書館。';
	@override String get liveTv => '在伺服器提供時開啟直播電視;否則,初創公司將返回家庭。';
	@override String get search => '開放媒體搜尋';
}

// Path: themeEditor.slots
class _Translations$themeEditor$slots$zh_Hant extends Translations$themeEditor$slots$zh {
	_Translations$themeEditor$slots$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get bg => '背景';
	@override String get surface => '面板';
	@override String get outline => '外框';
	@override String get text => '文字';
	@override String get textMuted => '次要文字';
	@override String get accent => '強調色';
}

// Path: themeEditor.contrast
class _Translations$themeEditor$contrast$zh_Hant extends Translations$themeEditor$contrast$zh {
	_Translations$themeEditor$contrast$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => '背景上的文字';
	@override String get textOnSurface => '面板上的文字';
	@override String get textMutedOnBg => '背景上的次要文字';
	@override String get textMutedOnSurface => '面板上的次要文字';
	@override String get accentOnBg => '背景上的強調色';
	@override String get accentOnSurface => '面板上的強調色';
	@override String get labelOnAccent => '強調色上的按鈕文字';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$zh_Hant extends Translations$hotkeys$actions$zh {
	_Translations$hotkeys$actions$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get playPause => '播放/暫停';
	@override String get volumeUp => '調大音量';
	@override String get volumeDown => '調小音量';
	@override String seekForward({required Object seconds}) => '快進（${seconds} 秒）';
	@override String seekBackward({required Object seconds}) => '快退（${seconds} 秒）';
	@override String get fullscreenToggle => '切換全螢幕';
	@override String get muteToggle => '切換靜音';
	@override String get subtitleToggle => '切換字幕';
	@override String get audioTrackNext => '下一個音軌';
	@override String get subtitleTrackNext => '下一個字幕軌';
	@override String get chapterNext => '下一個章節';
	@override String get chapterPrevious => '上一個章節';
	@override String get episodeNext => '下一集';
	@override String get episodePrevious => '上一集';
	@override String get speedIncrease => '加速播放';
	@override String get speedDecrease => '減速播放';
	@override String get speedReset => '重設速度';
	@override String get zoomIn => '放大';
	@override String get zoomOut => '縮小';
	@override String get zoomReset => '重設縮放';
	@override String get subSeekNext => '跳轉至下一句字幕';
	@override String get subSeekPrev => '跳轉至上一句字幕';
	@override String get subtitleDelayIncrease => '延遲字幕';
	@override String get subtitleDelayDecrease => '提前字幕';
	@override String get shaderToggle => '切換著色器';
	@override String get skipMarker => '跳過片頭/片尾';
	@override String get screenshot => '螢幕截圖';
	@override String get framePrevious => '上一篇:框架';
	@override String get frameNext => '下一框';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$zh_Hant extends Translations$videoControls$pipErrors$zh {
	_Translations$videoControls$pipErrors$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => '需要 Android 8.0 或更高版本';
	@override String get iosVersion => '需要 iOS 15.0 或更高版本';
	@override String get permissionDisabled => '子母畫面權限已停用。請在系統設定中啟用。';
	@override String get notSupported => '此裝置不支援子母畫面模式';
	@override String get voSwitchFailed => '無法切換子母畫面的影片輸出';
	@override String get failed => '啟動子母畫面失敗';
	@override String get prepareFailed => '無法準備子母畫面';
	@override String unknown({required Object error}) => '發生錯誤：${error}';
}

// Path: subtitlingStyling.assOverrideOptions
class _Translations$subtitlingStyling$assOverrideOptions$zh_Hant extends Translations$subtitlingStyling$assOverrideOptions$zh {
	_Translations$subtitlingStyling$assOverrideOptions$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get no => '保持字型、顏色、尺寸和位置寫在子標題檔案中。';
	@override String get yes => '允許玩家的字幕風格設定調整 ASS 字幕。';
	@override String get scale => '應用播放器風格和規模嵌入式尺寸,以匹配影片尺寸。';
	@override String get force => '取代嵌入式 ASS 風格與玩家的字幕風格。';
	@override String get strip => '刪除嵌入式 ASS 格式化,並清晰地顯示字幕文字。';
}

// Path: subtitlingStyling.renderResolutionOptions
class _Translations$subtitlingStyling$renderResolutionOptions$zh_Hant extends Translations$subtitlingStyling$renderResolutionOptions$zh {
	_Translations$subtitlingStyling$renderResolutionOptions$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get screen => '以全顯示錶面解析度為最清晰的結果。';
	@override String get video => '以影片解析度為基準進行渲染，這可減少高解析度螢幕上的運算量。';
	@override String get threeQuarter => '以75%的顯示錶面解析度為低效節約。';
	@override String get half => '放入 50% 的顯示錶面解析度,以減少工作,與軟的邊緣。';
	@override String get third => '以顯示表面解析度的三分之一進行渲染，以減少運算量並讓邊緣更柔和。';
	@override String get quarter => '在顯示錶面解析度的四分之一下降,以減少工作,最柔軟的結果。';
}

// Path: accountPreferences.groups
class _Translations$accountPreferences$groups$zh_Hant extends Translations$accountPreferences$groups$zh {
	_Translations$accountPreferences$groups$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => '音訊與字幕';
	@override String get libraryDisplay => '媒體庫';
	@override String get personalMedia => '個人媒體';
}

// Path: accountPreferences.subtitleModes
class _Translations$accountPreferences$subtitleModes$zh_Hant extends Translations$accountPreferences$subtitleModes$zh {
	_Translations$accountPreferences$subtitleModes$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get none => '手動選擇';
	@override String get noneDescription => '絕不自行開啟字幕。';
	@override String get defaultMode => '遵循軌道旗標';
	@override String get defaultModeDescription => '使用每個字幕軌上儲存的預設與強制旗標。';
	@override String get always => '一律啟用';
	@override String get alwaysDescription => '只要有偏好語言的字幕軌就自動開啟。';
	@override String get onlyForced => '僅強制字幕';
	@override String get onlyForcedDescription => '僅載入標記為強制的軌道。';
	@override String get smart => '外語配音時顯示';
	@override String get smartDescription => '僅在音訊為其他語言時開啟字幕。';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class _Translations$accountPreferences$subtitleAccessibilityOptions$zh_Hant extends Translations$accountPreferences$subtitleAccessibilityOptions$zh {
	_Translations$accountPreferences$subtitleAccessibilityOptions$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => '偏好非 SDH 字幕';
	@override String get preferSdh => '偏好 SDH 字幕';
	@override String get onlySdh => '僅 SDH 字幕';
	@override String get onlyNonSdh => '僅非 SDH 字幕';
	@override String get preferNonSdhDescription => '偏好標準字幕,當既有標準和SDH版本時。';
	@override String get preferSdhDescription => '偏好在可用時使用 SDH 字幕,但允許標準字幕作為落後。';
	@override String get onlySdhDescription => '只使用 SDH 字幕;不要返回標準字幕。';
	@override String get onlyNonSdhDescription => '只使用標準字幕;排除 SDH 字幕。';
}

// Path: accountPreferences.forcedSubtitleOptions
class _Translations$accountPreferences$forcedSubtitleOptions$zh_Hant extends Translations$accountPreferences$forcedSubtitleOptions$zh {
	_Translations$accountPreferences$forcedSubtitleOptions$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => '偏好非強制字幕';
	@override String get preferForced => '偏好強制字幕';
	@override String get onlyForced => '僅強制字幕';
	@override String get onlyNonForced => '僅非強制字幕';
	@override String get preferNonForcedDescription => '更喜歡定期的字幕,但允許強迫軌道作為落後。';
	@override String get preferForcedDescription => '偏好在可用時強迫行列,但允許定期字幕作為落後。';
	@override String get onlyForcedDescription => '只使用被強制標記的軌道。';
	@override String get onlyNonForcedDescription => '排除被強制標記的軌道。';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$zh_Hant extends Translations$accountPreferences$watchedIndicatorOptions$zh {
	_Translations$accountPreferences$watchedIndicatorOptions$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get none => '從不';
	@override String get moviesAndShows => '電影與影集';
	@override String get movies => '僅電影';
	@override String get shows => '僅影集';
	@override String get noneDescription => '不要顯示已觀看的檢查標誌。';
	@override String get moviesAndShowsDescription => '顯示觀看的電影和電視節目檢查標誌。';
	@override String get moviesDescription => '只為電影顯示觀看標籤。';
	@override String get showsDescription => '只為電視節目顯示觀看的檢查標誌。';
}

// Path: accountPreferences.mediaReviewsOptions
class _Translations$accountPreferences$mediaReviewsOptions$zh_Hant extends Translations$accountPreferences$mediaReviewsOptions$zh {
	_Translations$accountPreferences$mediaReviewsOptions$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => '使用者與影評人';
	@override String get usersOnly => '僅使用者';
	@override String get criticsOnly => '僅影評人';
	@override String get nobody => '隱藏';
	@override String get usersAndCriticsDescription => '顯示使用者評分和批判性評分。';
	@override String get usersOnlyDescription => '顯示使用者提交的評分和評論。';
	@override String get criticsOnlyDescription => '顯示批判性評分和評論。';
	@override String get nobodyDescription => '隱藏評分和評論。';
}

// Path: discover.findNext
class _Translations$discover$findNext$zh_Hant extends Translations$discover$findNext$zh {
	_Translations$discover$findNext$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '發現下一個心頭好';
	@override String get open => '發現下一個心頭好';
	@override String get anyTime => '不限時間';
	@override String get timeAvailable => '你有多少時間？';
	@override String get filters => '選出此刻想做的事';
	@override String get watch => '觀看';
	@override String get listen => '聆聽';
	@override String get read => '閱讀';
	@override String finishable({required Object duration}) => '${duration}內可完成';
	@override String aboutDuration({required Object duration}) => '約${duration}';
	@override String nextUnit({required Object duration}) => '下一章 · ${duration}';
	@override String totalDuration({required Object duration}) => '共${duration}';
	@override String get timingVaries => '所需時間可能有所不同';
	@override String get notNow => '暫時略過';
	@override String get swipeHint => '朝箭頭方向滑動封面，或使用下方按鈕。';
	@override String get saved => '已儲存的推薦';
	@override String savedCount({required Object count}) => '已儲存的推薦 · ${count}';
	@override String get undo => '復原';
	@override String get details => '詳細資訊';
	@override String get noPicks => '暫時沒有可選內容';
	@override String get noPicksHint => '連接媒體庫或新增媒體來源即可開始。';
	@override String get noMatches => '沒有適合此刻的內容';
	@override String get noMatchesHint => '試試其他內容類型，或留出更多時間。';
	@override String get allDone => '你已瀏覽全部推薦';
	@override String get allDoneHint => '換一組推薦，就能再次看到這些選項。';
	@override String get refresh => '尋找另一組推薦';
	@override String sourceReason({required Object source}) => '來自${source}';
	@override String libraryReason({required Object library}) => '來自${library}';
	@override String get ownedReason => '來自你的媒體庫';
	@override String get liveNow => '正在播出';
	@override String get watchLive => '觀看直播';
	@override String get filterAnything => '不限類型';
	@override String get filterWatch => '觀看';
	@override String get filterListen => '聆聽';
	@override String get filterRead => '閱讀';
	@override String get twentyMinutes => '20分鐘';
	@override String get fortyFiveMinutes => '45分鐘';
	@override String get ninetyMinutes => '90分鐘';
	@override String get apply => '套用';
	@override String get openFailed => '此內容已無法使用。重新整理後再次查看。';
	@override String get changeFailed => '無法儲存此次變更，請再試一次。';
	@override String get savedLimit => '已儲存的推薦清單已滿。請先移除一則推薦，再儲存其他推薦。';
	@override String get chooseHint => '開啟作品、儲存以便稍後查看，或略過。';
	@override String get howItWorks => '使用方式';
	@override String get notNowHelp => '暫時略過這部作品。它仍會保留在媒體庫中。';
	@override String get saveHelp => '儲存至此裝置上目前個人檔案的已儲存推薦中。儲存不會下載作品。';
	@override String get openHelp => '選取封面查看詳細資訊。使用主要按鈕播放、閱讀或開啟作品。';
	@override String get controlsHelp => '鍵盤或遙控器：將焦點移到按鈕，然後按 Enter 或選取鍵。復原可恢復上一次選擇。';
	@override String get artworkLoading => '正在載入圖片…';
	@override String get artworkUnavailable => '圖片無法使用';
	@override String get savedFeedback => '已加入儲存的推薦';
	@override String get skippedFeedback => '已暫時略過';
	@override String get releaseToConfirm => '放開以確認';
	@override String get remoteHint => '封面取得焦點時：← / → 選擇 · 選取鍵查看詳細資訊 · ↑ / ↓ 移動焦點';
}

// Path: discover.person
class _Translations$discover$person$zh_Hant extends Translations$discover$person$zh {
	_Translations$discover$person$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get born => '出生';
	@override String get died => '逝世';
	@override String get birthplace => '出生地';
	@override String dateWithAge({required Object date, required Object age}) => '${date}（${age} 歲）';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date}（享年 ${age} 歲）';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$zh_Hant extends Translations$libraries$tabs$zh {
	_Translations$libraries$tabs$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get recommended => '推薦';
	@override String get browse => '瀏覽';
	@override String get collections => '收藏集';
	@override String get playlists => '播放清單';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$zh_Hant extends Translations$libraries$groupings$zh {
	_Translations$libraries$groupings$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '分組';
	@override String get all => '全部';
	@override String get movies => '電影';
	@override String get shows => '影集';
	@override String get seasons => '季';
	@override String get episodes => '集';
	@override String get artists => '演出者';
	@override String get albums => '專輯';
	@override String get tracks => '曲目';
	@override String get folders => '資料夾';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$zh_Hant extends Translations$libraries$filterCategories$zh {
	_Translations$libraries$filterCategories$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get genre => '類型';
	@override String get year => '年份';
	@override String get contentRating => '分級';
	@override String get tag => '標籤';
	@override String get unwatched => '未觀看';
	@override String get unplayed => '未播放';
	@override String get favorites => '我的最愛';
	@override String get filePath => '檔案路徑';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$zh_Hant extends Translations$libraries$sortLabels$zh {
	_Translations$libraries$sortLabels$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '標題';
	@override String get dateAdded => '新增日期';
	@override String get releaseDate => '發行日期';
	@override String get rating => '評分';
	@override String get communityRating => '社群評分';
	@override String get criticRating => '影評人評分';
	@override String get userRating => '使用者評分';
	@override String get datePlayed => '播放日期';
	@override String get playCount => '播放次數';
	@override String get productionYear => '製作年份';
	@override String get runtime => '片長';
	@override String get officialRating => '官方分級';
	@override String get premiereDate => '首映日期';
	@override String get startDate => '開始日期';
	@override String get airTime => '播出時間';
	@override String get studio => '工作室';
	@override String get random => '隨機';
	@override String get dateShared => '分享日期';
	@override String get latestEpisodeAirDate => '最新一集播出日期';
	@override String get lastEpisodeDateAdded => '最新一集新增日期';
	@override String get dateDownloaded => '下載日期';
	@override String get size => '大小';
	@override String get library => '媒體庫';
}

// Path: libraries.advancedFilters
class _Translations$libraries$advancedFilters$zh_Hant extends Translations$libraries$advancedFilters$zh {
	_Translations$libraries$advancedFilters$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get include => '包含';
	@override String get exclude => '排除';
	@override String get any => '不限';
	@override String get yes => '是';
	@override String get no => '否';
	@override String not({required Object value}) => '非 ${value}';
	@override String valueCount({required Object count}) => '已選取 ${count} 個';
	@override String valueCountExcluded({required Object count}) => '已排除 ${count} 個';
	@override String get searchValues => '搜尋選項';
	@override String get noValues => '沒有選項';
	@override String get matchContains => '包含';
	@override String get matchNotContains => '不包含';
	@override String get matchIs => '是';
	@override String get matchIsNot => '不是';
	@override String get matchBeginsWith => '開頭為';
	@override String get matchEndsWith => '結尾為';
	@override String get textHint => '輸入要比對的文字';
	@override String get from => '從';
	@override String get to => '至';
	@override String range({required Object from, required Object to}) => '${from} 至 ${to}';
	@override String atLeast({required Object value}) => '${value} 以上';
	@override String atMost({required Object value}) => '${value} 以下';
	@override String dateLastDays({required Object count}) => '過去 ${count} 天';
	@override String get dateLastYear => '過去一年';
	@override String dateOlderThanDays({required Object count}) => '超過 ${count} 天前';
	@override String get dateOlderThanYear => '超過一年前';
}

// Path: libraries.selection
class _Translations$libraries$selection$zh_Hant extends Translations$libraries$selection$zh {
	_Translations$libraries$selection$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get selectItems => '選擇專案';
	@override String selectedCount({required Object count}) => '已選取 ${count} 個';
	@override String get actions => '選擇行動';
	@override String get confirmDescendants => '這一變化改變了所有節目和季節的節目。';
	@override String get confirmUnwatched => '這也會清除所選項目的播放進度。';
	@override String confirmCount({required Object count}) => '已選擇的專案: ${count}。';
	@override String completed({required Object count}) => '更新專案: ${count}';
	@override String partialFailure({required Object succeeded, required Object failed}) => '更新 ${succeeded}; 失敗 ${failed}. 失敗的專案仍然被選擇。';
}

// Path: explore.mdblistShelves
class _Translations$explore$mdblistShelves$zh_Hant extends Translations$explore$mdblistShelves$zh {
	_Translations$explore$mdblistShelves$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get manage => '管理 探索 地板';
	@override String get manageDescription => '從您的帳戶中選擇和安排列表 MDBList';
	@override String get description => '從您的 MDBList 帳戶中選擇公開電影和電視列表. 建立或複製列表在 MDBList 然後更新。';
	@override String get selected => '選擇的板塊';
	@override String get available => '可用的賬戶列表';
	@override String get noLists => '沒有公開的電影或電視列表返回. 建立或複製列表在 MDBList,然後更新。';
	@override String get displayName => '沙爾夫 顯示名稱';
	@override String get nameHint => '請點選使用源名單名稱。';
	@override String get add => '新增Shelf';
	@override String get save => '儲存沙地';
	@override String moveUp({required Object title}) => '移動 ${title} 升';
	@override String moveDown({required Object title}) => '移動 ${title} 下載';
	@override String get unavailable => '此列表不可用 退出或在設定中刪除其架子。';
	@override String get rateLimited => '第MDBList號請求限制已達到,請隨後退出。';
	@override String get loadFailed => '不能充電板,檢查你的連線和退出。';
	@override String get saveFailed => '沒辦法放下,請放下。';
	@override String get accountChanged => '帳戶或個人資料已更改 重新開啟這些設定。';
	@override String get settingsUnreadable => '儲存的欄位無法閱讀. 重新選擇列表以取代這些設定。';
}

// Path: explore.rows
class _Translations$explore$rows$zh_Hant extends Translations$explore$rows$zh {
	_Translations$explore$rows$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get watchlist => '待看清單';
	@override String get recommendedMovies => '推薦電影';
	@override String get recommendedShows => '推薦影集';
	@override String get trendingMovies => '近期熱門電影';
	@override String get trendingShows => '近期熱門影集';
	@override String get popularMovies => '熱門電影';
	@override String get popularShows => '熱門影集';
	@override String get trendingAnime => '近期熱門動畫';
	@override String get suggestedAnime => '推薦動畫';
	@override String get airingAnime => '熱門連載動畫';
	@override String get popularAnime => '最受歡迎的動畫';
	@override String get trending => '趨勢';
	@override String get upcomingMovies => '即將上映的電影';
	@override String get upcomingShows => '即將播出的影集';
}

// Path: explore.status
class _Translations$explore$status$zh_Hant extends Translations$explore$status$zh {
	_Translations$explore$status$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get airing => '播出中';
	@override String get ended => '已完結';
	@override String get canceled => '已取消';
	@override String get upcoming => '即將上線';
}

// Path: explore.badge
class _Translations$explore$badge$zh_Hant extends Translations$explore$badge$zh {
	_Translations$explore$badge$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} 熱門';
	@override String rankAiring({required Object n}) => '#${n} 播出中';
	@override String rankRated({required Object n}) => '#${n} 高分';
	@override String rankTrending({required Object n}) => '#${n} 趨勢';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} · ${season}';
	@override String watchingNow({required Object n}) => '${n} 觀看中';
	@override String get available => '可觀看';
	@override String get partiallyAvailable => '部分可觀看';
	@override String get availableIn4k => '4K 可觀看';
	@override String get requested => '已提出請求';
	@override String get pendingApproval => '等待核准';
	@override String get processing => '處理中';
	@override String get declined => '已拒絕';
	@override String get requestFailed => '請求失敗';
	@override String get requested4k => '已請求 4K';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} 季';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => '第 ${episode} 集 ${duration} 後播出';
	@override String nextAiringIn({required Object duration}) => '${duration} 後播出';
	@override String episodesShort({required Object n}) => '${n} 集';
	@override String minutesPerEpisode({required Object n}) => '每集 ${n} 分鐘';
	@override String get adult => '18+';
}

// Path: explore.stats
class _Translations$explore$stats$zh_Hant extends Translations$explore$stats$zh {
	_Translations$explore$stats$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} 人已收錄';
	@override String viewersDay({required Object n}) => '今日 ${n} 人觀看';
	@override String viewersWeek({required Object n}) => '本週 ${n} 人觀看';
	@override String viewersMonth({required Object n}) => '本月 ${n} 人觀看';
	@override String viewersYear({required Object n}) => '今年 ${n} 人觀看';
	@override String viewersAllTime({required Object n}) => '累計 ${n} 人觀看';
	@override String planning({required Object n}) => '${n} 人打算觀看';
	@override String favorited({required Object n}) => '${n} 人收藏';
	@override String dropRate({required Object percent}) => '${percent} 的人棄番';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 評論',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 則留言',
	);
	@override String votes({required Object n}) => '${n} 票';
	@override String watching({required Object n}) => '${n} 人正在觀看';
	@override String completed({required Object n}) => '${n} 人已看完';
	@override String onHold({required Object n}) => '${n} 人擱置中';
	@override String dropped({required Object n}) => '${n} 人棄番';
}

// Path: explore.season
class _Translations$explore$season$zh_Hant extends Translations$explore$season$zh {
	_Translations$explore$season$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get winter => '冬季';
	@override String get spring => '春季';
	@override String get summer => '夏季';
	@override String get fall => '秋季';
	@override String withYear({required Object season, required Object year}) => '${season} ${year} 年';
}

// Path: explore.format
class _Translations$explore$format$zh_Hant extends Translations$explore$format$zh {
	_Translations$explore$format$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get tv => 'TV';
	@override String get tvShort => 'TV 短片';
	@override String get movie => '電影';
	@override String get special => '特別篇';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => '音樂';
	@override String get other => '其他';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$zh_Hant extends Translations$explore$sourceMaterial$zh {
	_Translations$explore$sourceMaterial$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get original => '原創';
	@override String get manga => '漫畫';
	@override String get lightNovel => '輕小說';
	@override String get novel => '小說';
	@override String get visualNovel => '視覺小說';
	@override String get game => '遊戲';
	@override String get webComic => '網路漫畫';
	@override String get musicRelease => '音樂';
	@override String get otherMedia => '其他';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$zh_Hant extends Translations$explore$creditRole$zh {
	_Translations$explore$creditRole$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get actor => '演員';
	@override String get director => '導演';
	@override String get writer => '編劇';
	@override String get producer => '製作人';
	@override String get creator => '原作者';
	@override String get composer => '作曲家';
}

// Path: explore.relation
class _Translations$explore$relation$zh_Hant extends Translations$explore$relation$zh {
	_Translations$explore$relation$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get prequel => '前傳';
	@override String get sequel => '續集';
	@override String get sideStory => '外傳';
	@override String get spinOff => '衍生作品';
	@override String get alternativeVersion => '其他版本';
	@override String get summary => '總集篇';
	@override String get parentStory => '原作';
	@override String get adaptation => '改編';
	@override String get other => '相關';
}

// Path: explore.detail
class _Translations$explore$detail$zh_Hant extends Translations$explore$detail$zh {
	_Translations$explore$detail$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => '原始標題';
	@override String get alsoKnownAs => '又名';
	@override String get studios => '製作公司';
	@override String get country => '國家';
	@override String get language => '語言';
	@override String get released => '發行日期';
	@override String get physicalRelease => '光碟發行';
	@override String get ended => '已完結';
	@override String addedOn({required Object date}) => '新增於 ${date}';
	@override String get yourRating => '您的評分';
	@override String get budget => '預算';
	@override String get revenue => '票房';
	@override String get contentAdvisory => '年齡分級';
	@override String get tags => '標籤';
	@override String get revealSpoilerTags => '顯示劇透標籤';
	@override String get links => '連結';
	@override String get watchOn => '觀看平台';
	@override String get watchTrailer => '觀看預告片';
	@override String openOn({required Object site}) => '在 ${site} 開啟';
	@override String get crew => '幕後團隊';
	@override String get ratings => '評分';
	@override String get schedule => '播出時間';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '由 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 使用者推薦',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 位使用者推薦',
	);
	@override String recommendedBy({required Object who}) => '由 ${who} 推薦';
	@override String favoritedBy({required Object who}) => '由 ${who} 收藏';
	@override String unairedEpisodes({required Object n}) => '尚有 ${n} 集未播出';
	@override String recommendedByPercent({required Object percent}) => '${percent} 的觀眾推薦';
	@override String get relatedTitles => '相關作品';
	@override String get background => '背景介紹';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$zh_Hant extends Translations$liveTv$recordSettings$zh {
	_Translations$liveTv$recordSettings$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get startEarly => '提早開始（秒）';
	@override String get endLate => '延後結束（秒）';
	@override String get newOnly => '僅新劇集';
	@override String get anyChannel => '在任何頻道錄影';
	@override String get anyTime => '在任何時間錄影';
	@override String get skipInLibrary => '略過媒體庫中已有的劇集';
	@override String get keepUpTo => '要保留的劇集數';
	@override String get keepUpToHint => '0 表示保留所有劇集';
}

// Path: music.discography
class _Translations$music$discography$zh_Hant extends Translations$music$discography$zh {
	_Translations$music$discography$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => '單曲與 EP';
	@override String get live => '現場';
	@override String get compilations => '合輯';
}

// Path: watchTogether.notices
class _Translations$watchTogether$notices$zh_Hant extends Translations$watchTogether$notices$zh {
	_Translations$watchTogether$notices$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name} 按下了播放';
	@override String get playbackStarted => '已開始播放';
	@override String paused({required Object name}) => '${name} 暫停了播放';
	@override String get playbackPaused => '已暫停播放';
	@override String jumpedTo({required Object name, required Object position}) => '${name} 跳至 ${position}';
	@override String roomJumpedTo({required Object position}) => '已跳至 ${position}';
	@override String changedSpeed({required Object name, required Object speed}) => '${name} 將速度設為 ${speed}';
	@override String speedChanged({required Object speed}) => '速度已設為 ${speed}';
	@override String startedMedia({required Object name, required Object title}) => '${name} 開始播放「${title}」';
	@override String mediaStarted({required Object title}) => '正在播放「${title}」';
	@override String stoppedMedia({required Object name}) => '${name} 停止了影片';
	@override String get mediaStopped => '影片已停止';
	@override String waitingFor({required Object name}) => '正在等待 ${name}…';
	@override String get waitingForSomeone => '正在等待其他人跟上…';
	@override String get finished => '播放完畢';
	@override String hostChangedTo({required Object name}) => '${name} 現在是主持人';
	@override String get youAreNowHost => '您現在是主持人';
	@override String joined({required Object name}) => '${name} 已加入';
	@override String left({required Object name}) => '${name} 已離開';
	@override String get controlRefused => '只有主持人可以控制播放';
	@override String get searchFailed => '部分伺服器無法搜尋房間的影片';
	@override String get playBlocked => '按下播放即可開始';
	@override String get shareFailed => '無法與房間分享此影片';
	@override String get downloadNotShared => '下載內容所屬的伺服器離線時，無法與房間分享';
	@override String get openFailed => '無法開啟房間的影片';
}

// Path: watchTogether.ended
class _Translations$watchTogether$ended$zh_Hant extends Translations$watchTogether$ended$zh {
	_Translations$watchTogether$ended$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get ended => '主持人已結束房間';
	@override String get kicked => '您已被移出房間';
	@override String get expired => '房間已過期';
	@override String get replaced => '您已在其他裝置上加入此房間';
	@override String get lost => '與房間的連線已中斷';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$zh_Hant extends Translations$watchTogether$errors$zh {
	_Translations$watchTogether$errors$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => '這不是有效的房間代碼。代碼由 6 個字母與數字組成，不含 0、1、I、L 或 O。';
	@override String get roomNotFound => '沒有使用此代碼的房間。房間可能已結束。';
	@override String get roomFull => '該房間已滿。';
	@override String get roomLocked => '主持人已鎖定該房間。';
	@override String get relayFull => '「一起看」目前忙碌中。請稍後再試。';
	@override String get unreachable => '無法連線至「一起看」中繼伺服器。請檢查網路連線。';
	@override String get rateLimited => '嘗試次數過多。請稍候再試。';
	@override String get clientBlocked => '此版本的 PlezyNG 無法使用中繼伺服器。請更新應用程式。';
	@override String get forbidden => '只有主持人可以執行此操作。';
	@override String get notInRoom => '您不在房間中。';
	@override String get alreadyInRoom => '您已在房間中。';
	@override String get resumeFailed => '無法重新加入房間。';
	@override String get unsupported => '中繼伺服器不支援此操作。';
	@override String get generic => '發生錯誤。請重試。';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$zh_Hant extends Translations$downloads$backgroundWarning$zh {
	_Translations$downloads$backgroundWarning$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => '離開應用程式後，下載將會停止';
	@override String get bannerDegraded => '背景下載可能受限';
	@override String get bannerAction => '詳細資料';
	@override String get sheetTitle => '背景下載遭到封鎖';
	@override String get sheetTitleDegraded => '背景下載可能受限';
	@override String get sheetIntro => 'Android 正在阻止 PlezyNG 在背景穩定下載。';
	@override String get sheetIntroDegraded => '你的裝置限制了 PlezyNG 可在背景下載的時機。';
	@override String get reasonBackgroundRestricted => 'PlezyNG 的背景使用受限。請將其電池用量或背景使用設定為「無限制」。';
	@override String get reasonStandbyRestricted => 'Android 已將 PlezyNG 設為受限待命狀態。請將電池用量設為「無限制」。';
	@override String get reasonDownloadChannelBlocked => '下載通知已關閉，因此可能無法查看進度或使用控制項。';
	@override String get reasonNotificationsDisabled => '通知已關閉。在 Android 13 或更新版本中，長時間背景下載需要啟用通知。';
	@override String get reasonDataSaver => '已開啟數據節省模式，因此系統會封鎖使用行動數據的背景下載。透過 Wi-Fi 下載應仍可正常執行。';
	@override String get reasonOemUnknown => 'PlezyNG 在背景執行時，下載屢次停止。請檢查 PlezyNG 的電池用量或背景使用設定。';
	@override String get openSettings => '開啟設定';
	@override String get stillNotWorking => '裝置專屬說明';
	@override String get stillNotWorkingDescription => '查看適用於你裝置的步驟；若問題持續發生，也可從設定 › 查看日誌傳送日誌。';
	@override String get dialogTitle => '下載可能無法完成';
	@override String get dialogDownloadAnyway => '仍要下載';
	@override String get dialogFixFirst => '先修正設定';
	@override String get statusTile => '背景下載';
	@override String get statusOk => '可在背景執行';
	@override String get statusBlocked => '遭系統設定封鎖';
	@override String get statusDegraded => '受系統設定限制';
	@override String get statusUnknown => '尚未檢查';
	@override String get settingsUnavailable => '無法在這部裝置上開啟系統設定';
	@override String get linkUnavailable => '無法在這部裝置上開啟 dontkillmyapp.com';
}

// Path: downloads.groupings
class _Translations$downloads$groupings$zh_Hant extends Translations$downloads$groupings$zh {
	_Translations$downloads$groupings$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get library => '媒體庫';
	@override String get collections => '收藏集';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$zh_Hant extends Translations$companionRemote$session$zh {
	_Translations$companionRemote$session$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get startingServer => '正在啟動遠端伺服器…';
	@override String get hostAddress => '主機位址';
	@override String get connected => '已連線';
	@override String get serverRunning => '遠端伺服器已啟動';
	@override String get serverStopped => '遠端伺服器已停止';
	@override String get serverRunningDescription => '區域網路中的行動裝置可以連線至此應用程式';
	@override String get serverStoppedDescription => '啟動伺服器以允許行動裝置連線';
	@override String get usePhoneToControl => '使用行動裝置控制此應用程式';
	@override String get startServer => '啟動伺服器';
	@override String get stopServer => '停止伺服器';
	@override String get minimize => '最小化';
	@override String get manualAddressHint => '手動連線位址：';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$zh_Hant extends Translations$companionRemote$pairing$zh {
	_Translations$companionRemote$pairing$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => '使用相同 Plex 帳戶的 PlezyNG 裝置會顯示在此處';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => '正在連線…';
	@override String get searchingForDevices => '正在搜尋裝置…';
	@override String get noDevicesFound => '在區域網路上找不到裝置';
	@override String get noDevicesHint => '請在電腦上開啟 PlezyNG，並確認兩台裝置使用相同的 Wi-Fi 網路';
	@override String get availableDevices => '可用裝置';
	@override String get manualConnection => '手動連線';
	@override String get cryptoInitFailed => '無法啟動安全連線。請先登入 Plex。';
	@override String get validationHostRequired => '請輸入主機位址';
	@override String get validationHostFormat => '格式必須為 IP 位址:連接埠（例如 192.168.1.100:48632）';
	@override String get connectionTimedOut => '連線逾時。請確認兩台裝置都使用相同網路。';
	@override String get sessionNotFound => '找不到裝置。請確認主機上已啟動 PlezyNG。';
	@override String get authFailed => '驗證失敗。兩台裝置需要登入相同的 Plex 帳戶。';
	@override String failedToConnect({required Object error}) => '連線失敗：${error}';
	@override String get codeTitle => '雙重程式碼';
	@override String get codeDescription => '在主機裝置上輸入“遠端伴侶”中顯示的程式碼,兩臺裝置都必須使用支援安全配對的版本。';
	@override String get codeInvalid => '輸入所有 32 個字母和號碼的主機程式碼。';
	@override String get updateRequired => '將兩臺裝置更新到支援安全配對的版本。';
	@override String get hostDescription => '每次輸入此程式碼一次,遠端保持隱私:它提供對此個人資料的控制。';
	@override String get resetCode => '重新設定編碼';
	@override String get resetDescription => '切斷所有遠端,並建立一個新的程式碼,每個遠端都需要重新連線。';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$zh_Hant extends Translations$companionRemote$remote$zh {
	_Translations$companionRemote$remote$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => '是否要中斷遠端連線工作階段？';
	@override String get reconnecting => '重新連線中…';
	@override String attemptOf({required Object current}) => '第 ${current} 次嘗試，共 5 次';
	@override String get retryNow => '立即重試';
	@override String get tabRemote => '遙控';
	@override String get tabPlay => '播放';
	@override String get tabMore => '更多';
	@override String get menu => '選單';
	@override String get tabNavigation => '分頁導覽';
	@override String get tabDiscover => '發現';
	@override String get tabLibraries => '媒體庫';
	@override String get tabSearch => '搜尋';
	@override String get tabDownloads => '下載';
	@override String get tabSettings => '設定';
	@override String get previous => '上一個';
	@override String get playPause => '播放/暫停';
	@override String get next => '下一個';
	@override String get seekBack => '後退';
	@override String get stop => '停止';
	@override String get seekForward => '前進';
	@override String get volume => '音量';
	@override String get volumeDown => '調小';
	@override String get volumeUp => '調大';
	@override String get fullscreen => '全螢幕';
	@override String get subtitles => '字幕';
	@override String get audio => '音訊';
	@override String get searchHint => '在電腦版上搜尋…';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$zh_Hant extends Translations$companionRemote$errors$zh {
	_Translations$companionRemote$errors$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => '找不到網路介面';
	@override String get authenticationFailed => '身分驗證失敗';
	@override String serverStartFailed({required Object error}) => '無法啟動遠端伺服器：${error}';
	@override String commandFailed({required Object error}) => '無法傳送遠端指令：${error}';
	@override String get joinTimedOut => '加入工作階段逾時';
	@override String get failedToConnectAnyAddress => '無法連線至任何位址';
	@override String connectionLostAfterAttempts({required Object attempts}) => '嘗試 ${attempts} 次後連線中斷';
	@override String get connectionLost => '連線已中斷';
}

// Path: services.names
class _Translations$services$names$zh_Hant extends Translations$services$names$zh {
	_Translations$services$names$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class _Translations$services$simklReconnect$zh_Hant extends Translations$services$simklReconnect$zh {
	_Translations$services$simklReconnect$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '重新連線 Simkl';
	@override String get subtitle => 'Simkl 即將停用此連線所使用的登入方式。重新連線會開啟 simkl.com 以核准 PlezyNG — PlezyNG 絕不會看到您的密碼。您的觀看紀錄仍會保留在 Simkl 上。';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$zh_Hant extends Translations$services$deviceCode$zh {
	_Translations$services$deviceCode$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '在 ${service} 啟用 PlezyNG';
	@override String get instructions => '掃描 QR 碼，或前往下方網址並輸入此代碼：';
	@override String openToActivate({required Object service}) => '開啟 ${service} 進行啟用';
	@override String get copyCode => '複製啟用代碼';
	@override String get waitingForAuthorization => '等待授權中…';
	@override String get codeCopied => '代碼已複製';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$zh_Hant extends Translations$services$oauthProxy$zh {
	_Translations$services$oauthProxy$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '登入 ${service}';
	@override String get body => '掃描 QR 碼，或在任何裝置上開啟該網址。';
	@override String openToSignIn({required Object service}) => '開啟 ${service} 進行登入';
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$zh_Hant extends Translations$services$pendingAuth$zh {
	_Translations$services$pendingAuth$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => '複製登入 URL';
	@override String get urlCopied => 'URL 已複製';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$zh_Hant extends Translations$services$libraryFilter$zh {
	_Translations$services$libraryFilter$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '媒體庫篩選';
	@override String get subtitleAllSyncing => '同步所有媒體庫';
	@override String get subtitleNoneSyncing => '不同步任何內容';
	@override String subtitleBlocked({required Object count}) => '已封鎖 ${count} 個';
	@override String subtitleAllowed({required Object count}) => '已允許 ${count} 個';
	@override String get mode => '篩選模式';
	@override String get modeBlacklist => '黑名單（排除）';
	@override String get modeWhitelist => '白名單（僅限）';
	@override String get modeHintBlacklist => '同步下方未勾選的所有媒體庫。';
	@override String get modeHintWhitelist => '僅同步下方已勾選的媒體庫。';
	@override String get libraries => '媒體庫';
	@override String get noLibraries => '沒有可用的媒體庫';
	@override String get modeDescription => '選擇要阻止已勾選的媒體庫同步，或只同步已勾選的媒體庫。';
}

// Path: services.trackerDescriptions
class _Translations$services$trackerDescriptions$zh_Hant extends Translations$services$trackerDescriptions$zh {
	_Translations$services$trackerDescriptions$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get trakt => '與您的 Trakt 帳戶同步觀看的節目和電影。';
	@override String get mal => '同步動畫列表,並透過 MyAnimeList 觀看進展。';
	@override String get anilist => '同步動畫列表,並與 AniList 觀看進展。';
	@override String get simkl => '同步觀看電影,電視節目和動畫與Simkl。';
	@override String get mdblist => '在推薦和探索中顯示 MDBList 評分和列表。';
}

/// The flat map containing all translations for locale <zh-Hant>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsZhHant {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'appIcon.title' => '應用程式圖示',
			'appIcon.defaultIcon' => '預設',
			'appIcon.current' => '目前圖示',
			'appIcon.locked' => '終身訪問需要',
			'appIcon.lockedHint' => '啟動 7 天試用或終身解鎖 PlezyNG 以使用替代圖示。',
			'appIcon.changeFailed' => '無法變更應用程式圖示',
			'appIcon.launcherHint' => '離開 PlezyNG 後，新圖示就會出現在主畫面上。',
			'appIcon.tvLauncherHint' => '離開 PlezyNG 後就會顯示新橫幅。在電視重新啟動前，Android TV 可能仍會顯示舊橫幅。',
			'appIcon.names.midnight' => '午夜',
			'appIcon.names.ember' => '餘燼',
			'appIcon.names.paper' => '紙張',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => '線條',
			'appIcon.names.ocean' => '海洋',
			'appIcon.names.ultraviolet' => '紫外線',
			'appIcon.names.matcha' => '抹茶',
			'appIcon.names.sunset' => '日落',
			'appIcon.names.gold' => '金色',
			'appIcon.names.titanium' => '鈦金屬',
			'appIcon.names.glass' => '玻璃',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => 'Synthwave',
			'appIcon.names.pixel' => '像素',
			'appIcon.names.neon' => '霓虹',
			'appIcon.names.sticker' => '貼紙',
			'appIcon.names.ticket' => '票券',
			'appIcon.names.pop' => '普普風',
			'appIcon.names.strata' => '層疊',
			'appIcon.names.facet' => '切面',
			'appIcon.names.tilde' => '波浪號',
			'appIcon.description' => '選擇由您的裝置啟動器顯示的圖示. 預覽顯示每個選項看起來如何。',
			'auth.signInWithPlex' => '使用 Plex 登入',
			'auth.showQRCode' => '顯示 QR 碼',
			'auth.authenticate' => '驗證',
			'auth.authenticationTimeout' => '驗證逾時。請重試。',
			'auth.scanQRToSignIn' => '掃描此 QR 碼以登入',
			'auth.waitingForAuth' => '正在等待驗證…\n請在瀏覽器中登入。',
			'auth.useBrowser' => '使用瀏覽器',
			'auth.or' => '或',
			'auth.connectToMediaBrowser' => ({required Object product}) => '連線至 ${product}',
			'auth.quickConnect' => '快速連線（Quick Connect）',
			'auth.useQuickConnect' => '使用快速連線（Quick Connect）',
			'auth.quickConnectInstructions' => '在 Jellyfin 中開啟快速連線並輸入此代碼。',
			'auth.quickConnectWaiting' => '等待核准…',
			'auth.quickConnectCancel' => '取消',
			'auth.quickConnectExpired' => '快速連線代碼已過期。請重試。',
			'auth.localDataRecoveryRequired' => 'PlezyNG 無法安全地復原本機登入資料與待處理的播放資料。請重新登入。',
			'auth.pinCheckRejected' => 'Plex PIN 檢查遭到拒絕',
			'auth.connectToDirectPlex' => '連線到本地伺服器 Plex',
			'common.cancel' => '取消',
			'common.save' => '儲存',
			'common.close' => '關閉',
			'common.closeMiniPlayer' => '附近小型玩家',
			'common.closeWorkspaceWindow' => '附近視窗',
			'common.returnToFullView' => '回到全景',
			'common.manageMediaSessions' => '管理媒體會議',
			'common.hideMediaSessions' => '隱藏媒體會議',
			'common.mediaSessions' => '媒體會議',
			'common.mediaSessionsHint' => '選取工作階段可將它移到前景。停放會隱藏視窗，但讓工作階段保持開啟。返回會以完整檢視開啟工作階段；關閉則會結束工作階段。',
			'common.sessionInWorkspace' => '在工作場所',
			'common.sessionParked' => '停車',
			'common.sessionFullscreen' => '全螢幕',
			'common.switchToNextWindow' => '與下一個視窗交換',
			'common.moveWindow' => '移動視窗',
			'common.finishMovingWindow' => '結束移動視窗',
			'common.moveWindowHint' => '長壓和拖動視窗移動它. 這種控制也允許箭頭金鑰的運動。',
			'common.movingWindowHelp' => '拖到移動 · 投鍵調整 · 輸入儲存器 · 逃避取消',
			'common.resizeWindow' => '修復視窗',
			'common.resizeWindowHint' => '拖這個手套或使用箭頭鍵重新調整視窗。',
			'common.workspaceWindowHint' => '使用移動控制項，或長按並拖曳視窗來移動。使用調整大小把手來調整視窗大小。',
			'common.workspacePaneHint' => '選擇這個面板以集中它. 使用其全屏控制來擴充套件。',
			'common.workspaceWindowLabel' => ({required Object title}) => '會議視窗: ${title}',
			'common.workspaceTitleHint' => '選取以聚焦。拖曳標題列可移動視窗；使用全螢幕按鈕可展開。',
			'common.moveToSessionTray' => '轉到Session Tray',
			'common.moveToSessionTrayHint' => '開啟此會議可用,而不顯示其視窗。',
			'common.closeSessionHint' => '關閉此視窗並結束會議。',
			'common.sideBySideLayout' => '交換到側面佈局',
			'common.floatingWindows' => '轉換為浮動視窗',
			'common.clear' => '清除',
			'common.reset' => '重設',
			'common.later' => '稍後',
			'common.submit' => '送出',
			'common.confirm' => '確認',
			'common.retry' => '重試',
			'common.logout' => '登出',
			'common.unknown' => '未知',
			'common.refresh' => '重新整理',
			'common.yes' => '是',
			'common.no' => '否',
			'common.delete' => '刪除',
			'common.edit' => '編輯',
			'common.shuffle' => '隨機播放',
			'common.addTo' => '新增至…',
			'common.createNew' => '新增',
			'common.connect' => '連線',
			'common.disconnect' => '中斷連線',
			'common.play' => '播放',
			'common.pause' => '暫停',
			'common.resume' => '繼續',
			'common.error' => '錯誤',
			'common.search' => '搜尋',
			'common.home' => '首頁',
			'common.back' => '返回',
			'common.settings' => '設定',
			'common.mute' => '靜音',
			'common.ok' => '確定',
			'common.off' => '關閉',
			'common.options' => '選項',
			'common.seasonNumber' => ({required Object number}) => '第 ${number} 季',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => '第 ${number} 集 — ${title}',
			'common.chapterNumber' => ({required Object number}) => '第 ${number} 章',
			'common.reconnect' => '重新連線',
			'common.viewAll' => '查看全部',
			'common.checkingNetwork' => '正在檢查網路…',
			'common.loadingServers' => '正在載入伺服器…',
			'common.connectingToServers' => '正在連線伺服器…',
			'common.startingOfflineMode' => '正在啟動離線模式…',
			'common.loading' => '載入中…',
			'common.fullscreen' => '全螢幕',
			'common.exitFullscreen' => '退出全螢幕',
			'common.pressBackAgainToExit' => '再按一次返回以退出',
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
			'common.mediaKind.movie' => '電影',
			'common.mediaKind.show' => '劇集',
			'common.mediaKind.season' => '季',
			'common.mediaKind.episode' => '單集',
			'common.mediaKind.artist' => '藝術家',
			'common.mediaKind.album' => '專輯',
			'common.mediaKind.track' => '曲目',
			'common.mediaKind.collection' => '合集',
			'common.mediaKind.playlist' => '播放清單',
			'common.mediaKind.clip' => '短片',
			'common.mediaKind.photo' => '相片',
			'common.mediaKind.folder' => '資料夾',
			'screens.licenses' => '授權條款',
			'screens.switchProfile' => '切換使用者',
			'screens.subtitleStyling' => '字幕樣式',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => '日誌',
			'update.available' => '有可用更新',
			'update.versionAvailable' => ({required Object version}) => '版本 ${version} 已發佈',
			'update.currentVersion' => ({required Object version}) => '目前版本：${version}',
			'update.skipVersion' => '跳過此版本',
			'update.viewRelease' => '查看版本詳情',
			'update.latestVersion' => '已安裝的版本為最新版本',
			'update.checkFailed' => '無法檢查更新',
			'settings.title' => '設定',
			'settings.supportDeveloper' => '贊助 PlezyNG',
			'settings.supportDeveloperDescription' => '捐款支持開發',
			'settings.lifetimeAccess' => 'PlezyNG 終身訪問',
			'settings.language' => '語言',
			'settings.theme' => '主題',
			'settings.appearance' => '外觀',
			'settings.detailPage' => '詳細頁面',
			'settings.themeSongsEnabled' => '演奏主題歌曲',
			'settings.themeSongsEnabledDescription' => '播放可用的主題歌曲,同時檢視媒體細節。',
			'settings.themeSongVolume' => '主題歌曲 卷',
			'settings.videoPlayback' => '影片播放',
			'settings.videoPlaybackDescription' => '設定播放行為',
			'settings.advanced' => '進階',
			'settings.episodePosterMode' => '單集海報樣式',
			'settings.seriesPoster' => '影集海報',
			'settings.seasonPoster' => '單季海報',
			'settings.episodeThumbnail' => '縮圖',
			'settings.showHeroSectionDescription' => '在主畫面上顯示精選內容輪播區',
			'settings.secondsLabel' => '秒',
			'settings.minutesLabel' => '分鐘',
			'settings.secondsShort' => '秒',
			'settings.minutesShort' => '分',
			'settings.durationHint' => ({required Object min, required Object max}) => '輸入長度（${min}-${max}）',
			'settings.systemTheme' => '系統預設',
			'settings.lightTheme' => '淺色',
			'settings.darkTheme' => '深色',
			'settings.oledTheme' => 'OLED 純黑',
			'settings.emberTheme' => '餘燼',
			'settings.glacierTheme' => '冰河',
			'settings.forestTheme' => '森林',
			'settings.plumTheme' => '李子',
			'settings.paperTheme' => '紙張',
			'settings.libraryDensity' => '媒體庫版面配置密度',
			'settings.displayScale' => '介面縮放',
			'settings.compact' => '緊湊',
			'settings.comfortable' => '舒適',
			'settings.gridSpacing' => '網格間距',
			'settings.gridSpacingTight' => '緊湊',
			'settings.gridSpacingNormal' => '一般',
			'settings.gridSpacingSpacious' => '寬鬆',
			'settings.tvCornerSpotlightBackdrop' => '右上角焦點背景圖',
			'settings.tvCornerSpotlightBackdropDescription' => '在右上角顯示焦點內容圖片，而非填滿整個畫面',
			'settings.viewMode' => '檢視模式',
			'settings.gridView' => '網格檢視',
			'settings.listView' => '清單檢視',
			'settings.showHeroSection' => '顯示精選內容區',
			'settings.showHomeBackdrop' => '展示家居背景藝術作品',
			'settings.showHomeBackdropDescription' => '展示大型藝術作品背後展示的家庭行',
			'settings.contentScreensaverEnabled' => '內容螢幕儲存',
			'settings.contentScreensaverEnabledDescription' => '顯示全屏藝術作品,應用程式已變成 idle',
			'settings.contentScreensaverDelay' => '螢幕儲存後啟動',
			'settings.contentScreensaverLibraries' => '圖書館螢幕',
			'settings.contentScreensaverLibrariesDescription' => '選擇要用來提供螢幕保護程式圖片的媒體庫。若未選擇任何媒體庫，則會使用所有媒體庫的圖片。',
			'settings.contentScreensaverAllLibraries' => '所有圖書館',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} 圖書館 選擇',
			'settings.contentScreensaverNoLibraries' => '沒有連線媒體圖書館可用。',
			'settings.contentScreensaverDismissHint' => '按下任何按鈕或按下取消',
			'settings.newEpisodeNotifications' => '新事件通知',
			'settings.newEpisodeNotificationsDescription' => '警告當新集新增到一個節目你被抓住時,檢查 Plezy 是開放的。',
			'settings.continueWatchingRowSize' => '繼續觀看 序列大小',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => '${label} 卡片',
			'settings.rowSizeCompact' => '緊湊',
			'settings.rowSizeStandard' => '標準',
			'settings.rowSizeLarge' => '大',
			'settings.continueWatchingAction' => '繼續觀看操作',
			'settings.continueWatchingPlay' => '播放影片',
			'settings.continueWatchingDetails' => '開啟詳情頁',
			'settings.episodeAction' => '單集操作',
			'settings.episodePlay' => '播放',
			'settings.episodeDetails' => '開啟詳情頁',
			'settings.useGlobalHubs' => '使用首頁版面配置',
			'settings.useGlobalHubsDescription' => '顯示統一的首頁推薦欄，否則使用各媒體庫的推薦內容。',
			'settings.showServerNameOnHubs' => '在推薦欄顯示伺服器名稱',
			'settings.showServerNameOnHubsDescription' => '一律在推薦區標題中顯示伺服器名稱。',
			'settings.groupLibrariesByServer' => '依伺服器將媒體庫分組',
			'settings.groupLibrariesByServerDescription' => '將側邊欄中的媒體庫依伺服器進行分組。',
			'settings.alwaysKeepSidebarOpen' => '一律保持側邊欄展開',
			'settings.alwaysKeepSidebarOpenDescription' => '側邊欄保持展開狀態，內容區域自動調整',
			'settings.showUnwatchedCount' => '顯示未觀看數量',
			'settings.showUnwatchedCountDescription' => '在影集和單季上顯示未觀看的集數',
			'settings.showWatchedIndicators' => '顯示已觀看指示',
			'settings.showWatchedIndicatorsDescription' => '在已觀看的電影、影集和單集上顯示勾選標記',
			'settings.showEpisodeNumberOnCards' => '在卡片上顯示集數',
			'settings.showEpisodeNumberOnCardsDescription' => '在單集卡片上顯示季和集編號',
			'settings.showSeasonPostersOnTabs' => '在索引標籤上顯示單季海報',
			'settings.showSeasonPostersOnTabsDescription' => '在每季標籤上方顯示該季海報',
			'settings.tvFullCardLayout' => '完整 TV 卡片版面配置',
			'settings.tvFullCardLayoutDescription' => '使用僅顯示圖片的 TV 卡片，並在圖片上疊加演員姓名',
			'settings.focusGlow' => '焦點光暈',
			'settings.focusGlowDescription' => '在獲得焦點的卡片周圍顯示柔和的光暈',
			'settings.visualEffects' => '視覺效果',
			'settings.visualEffectsAuto' => '自動',
			'settings.visualEffectsAutoDescription' => '在效能較低的裝置上自動減少效果',
			'settings.visualEffectsFull' => '完整效果',
			'settings.visualEffectsReduced' => '簡化效果',
			'settings.visualEffectsReducedDescription' => '減少動畫並使用較低解析度的封面圖片',
			'settings.hideSpoilers' => '隱藏未觀看單集的劇透內容',
			'settings.hideSpoilersDescription' => '模糊未觀看單集的縮圖與描述',
			'settings.playerBackend' => '播放器引擎',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => '硬體解碼',
			'settings.hardwareDecodingDescription' => '如果支援，使用硬體加速',
			'settings.playbackBuffer' => '播放緩衝',
			'settings.playbackBufferAuto' => '自動（建議）',
			'settings.playbackBufferLarge' => '大',
			'settings.playbackBufferExtraLarge' => '特大',
			'settings.playbackBufferDescription' => '針對不穩定的連線緩衝更多內容。也受緩衝大小限制。',
			'settings.streamBufferSize' => '布格大小',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} MB',
			'settings.streamBufferSizeDescription' => '直接播放時預先載入的影片量。轉碼播放以伺服器本身的轉碼緩衝區為限。0 = 自動',
			'settings.streamBufferSizeExoNote' => '取代 Playback Buffer 設定時,在應用程式的記憶體限制中半個',
			'settings.streamBufferMegabytes' => '梅加位元',
			'settings.defaultQualityTitle' => '預設畫質',
			'settings.cellularQualityTitle' => '行動網路上的預設畫質',
			'settings.remoteQualityTitle' => '遠端播放質量',
			'settings.remoteQualitySameAsDefault' => '與假設質量相同',
			'settings.cellularQualitySameAsDefault' => '與預設畫質相同',
			'settings.directPlayCoveredQuality' => '以原始畫質播放較小影片',
			'settings.directPlayCoveredQualityDescription' => '已在畫質限制內的影片直接播放，而非轉碼',
			'settings.videoCodecs' => '影片編解碼器',
			'settings.videoCodecsDescription' => '未勾選的編解碼器將由伺服器轉碼',
			'settings.videoCodecsAlwaysAccepted' => '一律接受',
			'settings.musicQualityTitle' => '音樂品質',
			'settings.subtitleStyling' => '字幕樣式',
			'settings.subtitleStylingDescription' => '調整字幕外觀',
			'settings.smallSkipDuration' => '短跳過時間',
			'settings.largeSkipDuration' => '長跳過時間',
			'settings.rewindOnResume' => '繼續播放時稍微倒轉',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(seconds, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} 秒', ), 
			'settings.defaultSleepTimer' => '預設睡眠計時器',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(minutes, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} 分鐘', ), 
			'settings.rememberTrackSelections' => '記住每部影集或電影的音訊與字幕選擇',
			'settings.chooseTracksBeforePlayback' => '選擇音訊和字幕在播放前',
			'settings.chooseTracksBeforePlaybackDescription' => '在每個影片開始之前,選擇源音訊和子標題跟蹤。',
			'settings.alwaysShowSubtitlesOnDevice' => '總是顯示該裝置上的字幕',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => '當伺服器沒有選定的子標題時,選擇一個路徑,而此事永遠不會改變伺服器的偏好。',
			'settings.autoDownloadPreferredSubtitle' => '福克斯缺少偏好語言字幕',
			'settings.autoDownloadPreferredSubtitleDescription' => '選擇您所需的語言中的可用字幕,當地選擇;如果沒有字幕,請伺服器在支援時查詢一個字幕;選項將留在該裝置上。',
			'settings.rememberTrackSelectionsDescription' => '記住每部影片的音軌與字幕選擇',
			'settings.rememberTrackSelectionsBackendRule' => 'Plex 會按檔案將每個選擇儲存在伺服器上；Jellyfin 還會開啟帳戶的「記住選擇」；不支援 Emby',
			'settings.followServerTrackSelections' => '使用伺服器為每集選擇的軌道',
			'settings.followServerTrackSelectionsDescription' => '切換劇集時，套用伺服器上為該集選擇的音訊與字幕，而不是沿用目前選擇',
			'settings.resumeMusicOnLaunch' => '記住音樂工作階段',
			'settings.resumeMusicOnLaunchDescription' => '應用程式啟動時，將上次播放的歌曲在停止處以暫停狀態開啟',
			'settings.showChapterMarkersOnTimeline' => '在進度條上顯示章節標記',
			'settings.showChapterMarkersOnTimelineDescription' => '依章節分段顯示進度條',
			'settings.specialsOrdering' => '特別篇依集數排序',
			'settings.specialsOrderingDescription' => '特別篇在影集觀看順序中的播放位置',
			'settings.specialsOrderingServer' => '依伺服器順序',
			'settings.specialsOrderingAirDate' => '依播出日期交錯',
			'settings.specialsOrderingLast' => '一般季數之後',
			'settings.clickVideoTogglesPlayback' => '點選影片可切換播放或暫停',
			'settings.clickVideoTogglesPlaybackDescription' => '點選影片即可播放或暫停，而不顯示控制面板。',
			'settings.videoPlayerControls' => '影片播放器控制',
			'settings.keyboardShortcuts' => '鍵盤快速鍵',
			'settings.keyboardShortcutsDescription' => '自訂鍵盤快速鍵',
			'settings.videoPlayerNavigation' => '影片播放器導覽',
			'settings.videoPlayerNavigationDescription' => '使用方向鍵導覽影片播放器控制項',
			'settings.watchTogetherRelay' => '一起看中繼伺服器',
			'settings.watchTogetherRelayDescription' => '除非您自行設定，否則使用公開的 Open Watch Party 中繼伺服器',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.watchTogetherRelayInvalid' => '請輸入有效的 HTTP 或 HTTPS 中繼伺服器根網址。',
			'settings.crashReporting' => '當機報告',
			'settings.crashReportingDescription' => '傳送當機報告以協助改善應用程式',
			'settings.debugLogging' => '偵錯日誌',
			'settings.debugLoggingDescription' => '啟用詳細日誌記錄以便進行疑難排解',
			'settings.viewLogs' => '查看日誌',
			'settings.viewLogsDescription' => '查看應用程式日誌記錄',
			'settings.clearImageCache' => '清除圖片快取',
			'settings.clearImageCacheDescription' => '清除已快取的封面圖片與縮圖。圖片在重新下載前載入速度可能較慢。',
			'settings.clearImageCacheSuccess' => '圖片快取已成功清除',
			'settings.resetSettings' => '重設設定',
			'settings.resetSettingsDescription' => '恢復預設設定。此操作無法復原。',
			'settings.resetSettingsSuccess' => '設定重設成功',
			'settings.backup' => '備份',
			'settings.exportSettings' => '匯出設定',
			'settings.exportSettingsDescription' => '將您的偏好設定儲存至檔案',
			'settings.exportSettingsSuccess' => '設定已匯出',
			'settings.importSettings' => '匯入設定',
			'settings.importSettingsDescription' => '從檔案還原偏好設定',
			'settings.importSettingsConfirm' => '這將覆蓋您目前的設定。要繼續嗎？',
			'settings.importSettingsSuccess' => '設定已匯入',
			'settings.importSettingsInvalidFile' => '此檔案不是有效的 PlezyNG 設定匯出檔',
			'settings.importSettingsNoUser' => '匯入設定前請先登入',
			'settings.cloudBackup' => '雲備份',
			'settings.cloudBackupDescription' => '透過 HTTPS 將可移轉的設定備份到 WebDAV 位址。伺服器連線和登入憑證保留在此裝置上。',
			'settings.cloudBackupUrl' => 'WebDAV JSON 檔案 URL',
			'settings.cloudBackupUsername' => '使用者名稱',
			'settings.cloudBackupPassword' => '密碼',
			'settings.cloudBackupSaved' => '雲備份目的地儲存',
			'settings.cloudBackupNow' => '迴歸現在',
			'settings.cloudBackupComplete' => '設定備份上傳',
			'settings.cloudBackupRestore' => '恢復備份',
			'settings.cloudBackupRestoreConfirm' => '此將取代該裝置上的相匹配移動設定。',
			'settings.cloudBackupRestored' => '從雲端儲備恢復的設定',
			'settings.shortcutsReset' => '快速鍵已重設為預設值',
			'settings.resetShortcutsConfirm' => '這會將您的自訂快速鍵替換為預設值。要繼續嗎？',
			'settings.about' => '關於',
			'settings.aboutDescription' => '應用程式資訊與授權條款',
			'settings.updates' => '更新',
			'settings.updateAvailable' => '有可用更新',
			'settings.checkForUpdates' => '檢查更新',
			'settings.autoCheckUpdatesOnStartup' => '啟動時自動檢查更新',
			'settings.autoCheckUpdatesOnStartupDescription' => '啟動時若有可用更新便顯示通知',
			'settings.validationErrorEnterNumber' => '請輸入有效的數字',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => '長度必須介於 ${min} 與 ${max} ${unit} 之間',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => '該快速鍵已指派給 ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => '已更新 ${action} 的快速鍵',
			'settings.saveFailed' => '無法儲存變更。請重試。',
			'settings.autoPlayAndSkip' => '自動播放與跳過',
			'settings.autoPlayNextEpisode' => '自動播放下一集',
			'settings.autoPlayNextEpisodeDescription' => '目前單集結束時自動播放下一集',
			'settings.shuffleStartsFromBeginning' => '隨機播放從頭開始',
			'settings.shuffleStartsFromBeginningDescription' => '隨機播放時每集從頭開始播放，而非繼續播放',
			'settings.plexCinemaPreRoll' => '使用伺服器電影輸入',
			'settings.plexCinemaPreRollDescription' => '在電影開始之前,播放配置的Plex預角色或Jellyfin和Emby輸入。',
			'settings.playNextCountdown' => '下一集倒數計時',
			'settings.playNextCountdownImmediate' => '立即播放',
			'settings.skipIntroMode' => '跳過片頭',
			'settings.skipIntroModeOffDescription' => '正常播放片頭，不顯示跳過按鈕',
			'settings.skipIntroModeButtonDescription' => '片頭開始時顯示跳過按鈕',
			'settings.skipIntroModeAutoDescription' => '在下方設定的延遲後自動跳過片頭',
			'settings.skipCreditsMode' => '跳過片尾',
			'settings.skipCreditsModeOffDescription' => '正常播放片尾，不顯示跳過按鈕',
			'settings.skipCreditsModeButtonDescription' => '片尾開始時顯示跳過按鈕',
			'settings.skipCreditsModeAutoDescription' => '自動跳過片尾並播放下一集',
			'settings.skipAdsMode' => '滑雪廣告',
			'settings.skipAdsModeOffDescription' => '正常播放被發現的廣告,沒有跳躍按鈕',
			'settings.skipAdsModeButtonDescription' => '顯示在 Plex 檢測廣告時,將按鈕轉',
			'settings.skipAdsModeAutoDescription' => '下面的延遲後自動刪除被發現的廣告',
			'settings.musicPlayback' => '音樂播放',
			'settings.musicSweetFades' => '甜蜜的Fades',
			'settings.musicSweetFadesDescription' => '音樂在軌道邊緣時,當Plex有聲音資料時,音樂的播放保持不變。',
			'settings.skipMarkerModeOff' => '關閉',
			'settings.skipMarkerModeButton' => '顯示按鈕',
			'settings.skipMarkerModeAuto' => '自動',
			'settings.forceSkipMarkerFallback' => '強制使用備用標記',
			'settings.forceSkipMarkerFallbackDescription' => '即使 Plex 有標記，也強制使用章節標題模式',
			'settings.theIntroDbFallback' => '使用 TheIntroDB 作為 Intro Fallback',
			'settings.theIntroDbFallbackDescription' => '僅在伺服器沒有片頭標記時使用社群提供的時間點。比對結果可能因發行版本而異。',
			'settings.autoSkipDelay' => '自動跳過延遲',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => '自動跳過前等待 ${seconds} 秒',
			'settings.introPattern' => '片頭標記模式',
			'settings.introPatternDescription' => '用於比對章節標題中片頭標記的正規表示式',
			'settings.creditsPattern' => '片尾標記模式',
			'settings.creditsPatternDescription' => '用於比對章節標題中片尾標記的正規表示式',
			'settings.prerolls' => '片前影片',
			'settings.playPrerollsBeforeMovies' => '電影前玩預告片',
			'settings.playPrerollsBeforeMoviesDescription' => '在每部電影之前播放下面的選項中的偶然剪輯,按一下回來跳。',
			'settings.prerollLibrary' => '普雷羅圖書館',
			'settings.prerollLibraryNotSet' => '未設定',
			'settings.prerollLibraryNoneFound' => '您伺服器上沒有找到圖書館。',
			'settings.prerollSelection' => '選擇的預算',
			'settings.prerollSelectionPickLibraryFirst' => '首先選擇圖書館',
			'settings.prerollSelectionNoneSelected' => '沒有選定的特權',
			'settings.prerollSelectionCount' => ({required Object count}) => '已選取 ${count} 個',
			'settings.prerollItemPicker' => '選擇預算',
			'settings.prerollItemPickerLoadFailed' => '我不能從這本圖書館上傳任何東西。',
			'settings.invalidRegex' => '無效的正規表示式',
			'settings.regex' => '正規表示式',
			'settings.downloads' => '下載',
			'settings.downloadLocationDescription' => '選擇下載內容的儲存位置',
			'settings.downloadLocationDefault' => '預設（應用程式專屬儲存空間）',
			'settings.downloadLocationCustom' => '自訂位置',
			'settings.selectFolder' => '選擇資料夾',
			'settings.resetToDefault' => '重設為預設值',
			'settings.currentPath' => ({required Object path}) => '目前路徑：${path}',
			'settings.downloadLocationChanged' => '下載位置已變更',
			'settings.downloadLocationReset' => '下載位置已重設為預設值',
			'settings.downloadLocationInvalid' => '所選資料夾不具寫入權限',
			'settings.downloadLocationPickerUnavailable' => '此裝置無法選擇資料夾',
			'settings.downloadOnWifiOnly' => '僅在 Wi-Fi 連線時下載',
			'settings.downloadOnWifiOnlyDescription' => '使用行動網路時不會下載',
			'settings.autoRemoveWatchedDownloads' => '自動移除已觀看的下載內容',
			'settings.autoRemoveWatchedDownloadsDescription' => '自動刪除已觀看的下載影片',
			'settings.autoDownloadContinueWatching' => '自動下載 繼續觀看',
			'settings.autoDownloadContinueWatchingDescription' => '保持在您的繼續觀看盾牌上下載的專案,並在他們離開盾牌後刪除它們',
			'settings.downloadQuality' => '下載質量',
			'settings.downloadQualityDescription' => 'Plex 在其下載中編制轉換副本. Jellyfin 和 Emby 轉碼,而檔案下載; 中斷的轉換可能需要重新啟動。',
			'settings.askDownloadQualityEachTime' => '選擇每個下載的質量',
			'settings.askDownloadQualityEachTimeDescription' => '顯示優質點數,在每次影片下載之前',
			'settings.cellularDownloadBlocked' => '使用行動網路時無法下載。請改用 Wi-Fi 或變更設定。',
			'settings.maxVolume' => '最大音量',
			'settings.maxVolumeDescription' => '允許音量調大至 100% 以上，以適應聲音過小的媒體',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord 狀態整合（Rich Presence）',
			'settings.discordRichPresenceDescription' => '在 Discord 上顯示您正在觀看的內容',
			'settings.services' => '外部服務',
			'settings.servicesDescription' => '連結 Trakt、MyAnimeList、Seerr 等服務',
			'settings.manageLibrariesDescription' => '重新排序與隱藏媒體庫',
			'settings.companionRemoteServer' => '隨身遙控器伺服器',
			'settings.companionRemoteServerDescription' => '允許區域網路中的行動裝置控制此應用程式',
			'settings.companionRemoteServerStartFailed' => '無法啟動隨身遙控器伺服器',
			'settings.companionRemoteServerStopFailed' => '無法停止隨身遙控器伺服器',
			'settings.autoPip' => '自動進入子母畫面',
			'settings.autoPipDescription' => '播放影片時離開應用程式將自動進入子母畫面模式',
			'settings.matchContentFrameRate' => '符合影片影格率',
			'settings.matchContentFrameRateDescription' => '將顯示器更新率同步至影片影格率',
			'settings.matchContentResolution' => '符合內容解析度',
			'settings.matchContentResolutionDescription' => '將顯示切換為影片的原生解析度，由電視負責升頻。播放期間選單與字幕也會一併放大',
			'settings.matchRefreshRate' => '同步螢幕更新率',
			'settings.matchRefreshRateDescription' => '全螢幕時同步顯示器更新率',
			'settings.matchDynamicRange' => '同步動態範圍',
			'settings.matchDynamicRangeDescription' => 'HDR 內容切換至 HDR，播放結束切回 SDR',
			'settings.displaySwitchDelay' => '顯示器切換延遲時間',
			'settings.tunneledPlayback' => '通道化播放（Tunneled Playback）',
			'settings.tunneledPlaybackDescription' => '使用影片通道模式。若 HDR 播放出現黑畫面或動態卡頓，請停用此項。',
			'settings.audioPassthrough' => '音訊直通',
			'settings.audioPassthroughDescription' => '將 Dolby/DTS 音訊不經重新編碼，直接傳送至擴大機或電視以保留環繞音效。若播放無聲，請關閉此設定。',
			'settings.audioPassthroughDescriptionApple' => '使用 Apple 原生 Dolby 解碼器處理 Dolby Digital Plus（包括 Atmos）。DTS 與 TrueHD 仍以多聲道 PCM 播放。若沒有聲音，請關閉此設定。',
			'settings.audioPassthroughDescriptionAppleSpatial' => '使用 Apple 原生 Dolby 解碼器處理 Dolby Digital Plus（包括 Atmos）。在 iOS、iPadOS 與 tvOS 26 或更新版本上，TrueHD Atmos 與 DTS:X 會以空間音訊播放。其他 DTS 與 TrueHD 音軌則以多聲道 PCM 播放。若沒有聲音，請關閉此設定。',
			'settings.audioPassthroughOverriddenByNormalization' => '音量標準化開啟時停用',
			'settings.audioChannelLimit' => '音訊聲道',
			'settings.audioChannelLimitDescription' => '將解碼後的音訊下混，以配合無法播放所有聲道的喇叭、耳機或 HDMI 設備',
			'settings.audioChannelLimitOriginal' => '原始',
			'settings.audioChannelLimitOriginalDescription' => '播放音軌中的所有聲道',
			'settings.audioChannelLimitSurround51' => '最多 5.1',
			'settings.audioChannelLimitSurround51Description' => '將 7.1 下混為 5.1，適用於僅支援 5.1 PCM 的電視與擴大機。不影響直通。',
			'settings.audioChannelLimitStereo' => '立體聲',
			'settings.audioChannelLimitStereoDescription' => '下混為雙聲道，適用於立體聲喇叭或耳機。會關閉直通。',
			'settings.downmixCenterBoost' => '中置聲道增強',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => '增強（dB）',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => '下混時音量標準化',
			'settings.audioDownmixNormalizeDescription' => '降低混音電平以防止破音。關閉以保持原始音量（大音量場景可能會失真）。',
			'settings.dvConversionMode' => 'Dolby Vision 轉換模式',
			'settings.dvConversionModeDescription' => '選擇如何處理 Dolby Vision Profile 7 檔案。',
			'settings.dvConversionAuto' => '自動',
			'settings.dvConversionNative' => '原生 / 停用',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => '自動偵測裝置相容性並使用一般備援機制',
			'settings.dvConversionNativeDescription' => '強制使用原生 DV7 並停用 DV 轉換重試',
			'settings.dvConversionDv81Description' => '強制將內嵌的 RPU 轉換為 Dolby Vision Profile 8.1',
			'settings.dvConversionHevcStripDescription' => '移除 Dolby Vision RPU/EL 層，並以一般 HEVC 呈現',
			'settings.experimentalDolbyVision' => '實驗性 Dolby Vision',
			'settings.experimentalDolbyVisionDescription' => '下次播放時使用實驗性 FEL 算繪器。需要單獨建置的播放引擎。',
			'settings.dvExperimentUnavailableDescription' => '此實驗目前僅支援 Linux。',
			'settings.dvCompatibilityFallback' => '相容性備援',
			'settings.dvCompatibilityFallbackDescription' => '如果實驗無法啟動，則使用標準算繪器。FEL 資料可能會遺失。',
			'settings.dvExperimentDiagnostics' => '影片實驗記錄',
			'settings.dvExperimentDiagnosticsDescription' => '在下次播放時啟用詳細的播放器記錄。',
			'settings.disableDolbyVision' => '停用 Dolby Vision',
			'settings.disableDolbyVisionDescription' => '檔案包含 HDR10 或 HLG 層時，改為播放該層而非 Dolby Vision',
			'settings.hdrSdrConversion' => 'HDR 轉 SDR',
			'settings.hdrSdrConversionDescription' => '選擇在顯示器無法顯示 HDR 時由誰轉換 HDR 影片。',
			_ => null,
		} ?? switch (path) {
			'settings.hdrSdrConversionAuto' => '自動',
			'settings.hdrSdrConversionAutoDescription' => 'Android 9 及更新版本使用裝置，較舊版本使用播放器',
			'settings.hdrSdrConversionDevice' => '裝置',
			'settings.hdrSdrConversionDeviceDescription' => '由裝置的視訊硬體轉換。速度最快，但色彩取決於裝置',
			'settings.hdrSdrConversionPlayer' => '播放器',
			'settings.hdrSdrConversionPlayerDescription' => '由播放器轉換。色彩一致，但在低階電視盒上 4K 可能卡頓',
			'settings.deinterlace' => '去交錯',
			'settings.deinterlaceDescription' => '移除交錯影片中的梳狀雜訊（僅限 mpv 播放器）',
			'settings.deinterlaceOff' => '關閉',
			'settings.deinterlaceOffDescription' => '以解碼後的原樣顯示交錯影片',
			'settings.deinterlaceVideo' => '視訊',
			'settings.deinterlaceVideoDescription' => '將每個圖場轉為完整影格。適用於為電視拍攝的影片，例如體育賽事、新聞與演唱會',
			'settings.deinterlaceFilm' => '電影',
			'settings.deinterlaceFilmDescription' => '還原經 telecine 轉為 29.97 fps 的電影與動畫原始影格，常見於 NTSC DVD。為電視拍攝的影片會出現卡頓。直播電視會使用「視訊」',
			'settings.requireProfileSelectionOnOpen' => '開啟應用程式時要求選擇使用者',
			'settings.requireProfileSelectionOnOpenDescription' => '每次開啟應用程式時顯示使用者設定檔選擇畫面',
			'settings.forceTvMode' => '強制 TV 模式',
			'settings.forceTvModeDescription' => '強制使用 TV 介面版面。適用於無法自動辨識 TV 的裝置。需要重新啟動。',
			'settings.startInFullscreen' => '以全螢幕模式啟動',
			'settings.startInFullscreenDescription' => '啟動時直接以全螢幕開啟 PlezyNG',
			'settings.exitFullscreenOnPlayerClose' => '關閉播放器時退出全螢幕',
			'settings.exitFullscreenOnPlayerCloseDescription' => '關閉影片播放器時自動退出全螢幕模式',
			'settings.autoHidePerformanceOverlay' => '自動隱藏效能疊加層',
			'settings.autoHidePerformanceOverlayDescription' => '效能疊加層隨播放控制面板一起淡入或淡出',
			'settings.showNavBarLabels' => '顯示導覽列標籤',
			'settings.showNavBarLabelsDescription' => '在導覽列圖示下方顯示文字標籤',
			'settings.startupSection' => '啟動頁面',
			'settings.preferredServer' => '優先伺服器',
			'settings.preferredServerDescription' => '優先考慮此伺服器的結果,同時保持所有連線的伺服器可用。',
			'settings.preferredServerAutomatic' => '自動',
			'settings.showExploreTab' => '顯示探索分頁',
			'settings.showExploreTabDescription' => '顯示探索分頁，其中包含來自 Plex Discover 和已連結追蹤服務的內容',
			'settings.hideEmptyLibraries' => '隱藏空白圖書館',
			'settings.hideEmptyLibrariesDescription' => '從導航中刪除伺服器報告的零件數的圖書館。',
			'settings.liveTvDefaultFavorites' => '預設顯示最愛頻道',
			'settings.liveTvDefaultFavoritesDescription' => '開啟直播電視時僅顯示最愛頻道',
			'settings.general' => '一般',
			'settings.generalDescription' => '語言、啟動與視窗行為',
			'settings.languageAndRegion' => '語言與地區',
			'settings.startup' => '啟動',
			'settings.display' => '顯示器',
			'settings.libraryAndCards' => '媒體庫與卡片',
			'settings.homeScreen' => '主畫面',
			'settings.navigation' => '導覽',
			'settings.window' => '視窗',
			'settings.liveTv' => '直播電視',
			'settings.player' => '播放器',
			'settings.videoAndDisplay' => '影片與顯示器',
			'settings.audio' => '音訊',
			'settings.quality' => '畫質',
			'settings.subtitles' => '字幕',
			'settings.seekAndTiming' => '跳轉與計時',
			'settings.behavior' => '行為',
			'settings.gestures' => '手勢',
			'settings.gestureBrightnessSwipe' => '亮度滑動手勢',
			'settings.gestureBrightnessSwipeDescription' => '在螢幕左側邊緣上下滑動以調整亮度',
			'settings.gestureVolumeSwipe' => '音量滑動手勢',
			'settings.gestureVolumeSwipeDescription' => '在螢幕右側邊緣上下滑動以調整音量',
			'settings.gesturePinchToZoom' => '雙指縮放',
			'settings.gesturePinchToZoomDescription' => '在影片上雙指捏合以放大或縮小',
			'settings.gestureSeekSwipe' => '尋找Swipe',
			'settings.gestureSeekSwipeDescription' => '向左或向右轉到影片中尋找; 釋放跳躍',
			'settings.rememberBrightnessLevel' => '記住亮度',
			'settings.rememberBrightnessLevelDescription' => '以上次滑動設定的亮度開始播放',
			'settings.controls' => '控制',
			'settings.rememberPlayerChanges' => '記住播放器變更',
			'settings.rememberPlayerChangesDescription' => '播放期間所做的變更要儲存並從何處重新套用',
			'settings.scopePlaybackSpeed' => '播放速度',
			'settings.scopeShaderPreset' => '著色器預設',
			'settings.scopeAspectRatio' => '顯示比例',
			'settings.scopeSyncOffsets' => '音訊與字幕同步',
			'settings.playerScopeOff' => '不要儲存',
			'settings.playerScopeGlobal' => '全部',
			'settings.playerScopeLibrary' => '依媒體庫',
			'settings.playerScopeTitle' => '依影集或電影',
			'settings.exportDialogTitle' => '匯出 PlezyNG 設定',
			'settings.followSystem' => '跟隨系統',
			'settings.followAppLanguage' => '與介面語言一致',
			'settings.regionFormat' => '地區格式',
			'settings.regionFormatDescription' => '選擇日期、數字及計量單位的顯示方式。',
			'settings.metadataLanguage' => '中繼資料語言',
			'settings.metadataLanguageDescription' => '伺服器支援時，優先使用此語言顯示標題及簡介。音訊和字幕偏好設定互相獨立。',
			'settings.enterFullscreenOnPlaybackStart' => '在播放開始時輸入全屏',
			'settings.enterFullscreenOnPlaybackStartDescription' => '開啟桌面影片在播放開始時全屏',
			'settings.extendVideoIntoDisplayCutout' => '將影片擴充套件到顯示器中',
			'settings.extendVideoIntoDisplayCutoutDescription' => '讓全屏影片在Android手機上使用相機切割',
			'settings.languageDescription' => '選擇用於 PlezyNG 控制和訊息的語言. 跟蹤系統跟蹤您的裝置語言。',
			'settings.themeDescription' => '選擇應用程式中使用的顏色和對比。',
			'settings.libraryDensityDescription' => '改變每個行中的圖書館卡的數量。',
			'settings.displayScaleDescription' => '在此車螢幕上重新設定介面,而無需改變您的裝置上的文字大小。',
			'settings.themeSongVolumeDescription' => '設定主題歌曲的數量與其他音訊相比。',
			'settings.viewModeDescription' => '選擇圖書館專案是否顯示為網上的海報或作為一個小型列表。',
			'settings.gridViewDescription' => '安排圖書館專案在海報的行和列。',
			'settings.listViewDescription' => '在垂直列表中顯示圖書館專案,每個專案有更多的文字。',
			'settings.gridSpacingDescription' => '在圖書館網中設定海報之間的差距。',
			'settings.gridSpacingTightDescription' => '在螢幕上插入更多的海報,有較小的差距。',
			'settings.gridSpacingNormalDescription' => '使用海報之間的標準差距。',
			'settings.gridSpacingSpaciousDescription' => '新增海報之間更大的差距,以獲得更多的分離。',
			'settings.episodePosterModeDescription' => '選擇哪個藝術作品出現在節目卡上。',
			'settings.seriesPosterDescription' => '使用節目系列的海報為每個集合。',
			'settings.seasonPosterDescription' => '使用每集的季節海報,隨時可用。',
			'settings.episodeThumbnailDescription' => '在可用時使用集中的框架。',
			'settings.continueWatchingActionDescription' => '選擇當您啟動繼續觀看卡時會發生什麼。',
			'settings.continueWatchingPlayDescription' => '立即啟動電影或節目。',
			'settings.continueWatchingDetailsDescription' => '首先開啟標題頁面,以便您可以檢視詳細資訊並選擇一個行動。',
			'settings.episodeActionDescription' => '選擇當您啟動一個節目卡時會發生什麼。',
			'settings.episodePlayDescription' => '立即開始事件。',
			'settings.episodeDetailsDescription' => '在播放之前開啟集片頁面。',
			'settings.contentScreensaverDelayDescription' => '在展示藝術作品之前,選擇 PlezyNG 等待多久沒有輸入。',
			'settings.continueWatchingRowSizeDescription' => '在繼續觀看行中選擇卡片的尺寸。',
			'settings.rowSizeCompactDescription' => '顯示較小的卡片,以便在行列中新增更多的專案。',
			'settings.rowSizeStandardDescription' => '使用標準卡尺寸。',
			'settings.rowSizeLargeDescription' => '顯示更大的卡片,更多藝術作品的細節。',
			'settings.visualEffectsDescription' => '選擇該裝置的動畫和藝術作品效果預算。',
			'settings.visualEffectsFullDescription' => '在每個裝置上使用完整的動畫和藝術作品效果。',
			'settings.startupSectionDescription' => '在 PlezyNG 啟動時選擇哪個部分開啟。',
			'settings.startupSectionOptions.discover' => '從連線的發現來源開啟建議和專案。',
			'settings.startupSectionOptions.libraries' => '開啟您的連線媒體圖書館。',
			'settings.startupSectionOptions.liveTv' => '在伺服器提供時開啟直播電視;否則,初創公司將返回家庭。',
			'settings.startupSectionOptions.search' => '開放媒體搜尋',
			'settings.smallSkipDurationDescription' => '設定由短後方向移動的距離,並向前尋找控制。',
			'settings.largeSkipDurationDescription' => '設定遠端移動的長後方向和向前尋找控制。',
			'settings.rewindOnResumeDescription' => '在重新播放影片時,以此金額返回播放。',
			'settings.defaultSleepTimerDescription' => '設定睡眠時間開始時使用的初始時間。',
			'settings.playNextCountdownDescription' => '等待很久,直到下一集開始,設定到0即時開始。',
			'settings.autoSkipDelaySettingDescription' => '適用於當一個輸入、信用或廣告設定自動轉換時。',
			'settings.downmixCenterBoostDescription' => '在周圍的音訊被混合到斯特里奧時,在中間頻道上增加對話。',
			'settings.displaySwitchDelayDescription' => '在更改顯示模式之前等待,以便電視或接收器可以完成其以前的交換。',
			'settings.playerBackendDescription' => '選擇哪個播放引擎在該裝置上掃描和播放影片。',
			'settings.exoPlayerDescription' => '使用 Android 的本地 Media3 基於播放器和支援的硬體路徑。',
			'settings.mpvDescription' => '使用 mpv,它暴露了額外的播放、子標題和影片處理控制。',
			'settings.scopeOffDescription' => '只保留當前播放會的更改。',
			'settings.scopeGlobalDescription' => '重複使用每個圖書館和標題的相同值。',
			'settings.scopeLibraryDescription' => '記住每個圖書館的單獨價值。',
			'settings.scopeTitleDescription' => '記住每個節目或電影的單獨值。',
			'settings.specialsOrderingServerDescription' => '保持媒體伺服器提供的集合訂單。',
			'settings.specialsOrderingAirDateDescription' => '根據他們的空氣日期,將特殊物品列入常規事件中。',
			'settings.specialsOrderingLastDescription' => '每個特別的位置,在定期季節後。',
			'settings.skipIntroModeDescription' => '選擇輸入標記器是否正常播放,顯示滑動按鈕或自動滑動。',
			'settings.skipCreditsModeDescription' => '選擇信用是否正常播放,顯示滑動按鈕或自動滑動。',
			'settings.skipAdsModeDescription' => '選擇是否被發現的廣告正常播放,顯示滑動按鈕或自動滑動。',
			'settings.playbackBufferAutoDescription' => '讓活躍的玩家選擇其正常的泡沫大小。',
			'settings.playbackBufferLargeDescription' => '保持更多媒體在播放前準備;這使用更多的記憶體。',
			'settings.playbackBufferExtraLargeDescription' => '保持最大的閱讀面板泡沫;這使用最多的記憶。',
			'settings.defaultQualityDescription' => '設定伺服器轉碼串流的預設影片解析度與最高位元率。',
			'settings.cellularQualityDescription' => '超越預設質量,當裝置使用單細胞連線時。',
			'settings.remoteQualityDescription' => '透過遠端連線連線到伺服器時超越預設質量。',
			'settings.qualityPresetOriginalDescription' => '以來源可用的畫質播放，不要求伺服器轉碼。',
			'settings.qualityPresetTranscodeOptionDescription' => '請伺服器依照上方顯示的解析度與位元率轉碼串流。',
			'settings.qualityPresetSameAsDefaultDescription' => '使用預設品質中選擇的質量。',
			'settings.musicQualityDescription' => '設定向伺服器要求的最高音訊位元率；選擇「原始」時會保留來源串流。',
			'settings.musicQualityOriginalDescription' => '播放源音訊,無需Bitrate加密的Transcode。',
			'settings.musicQualityTranscodeOptionDescription' => '請求伺服器轉程式碼接近上面的位元率;實際輸出可能有所不同。',
			'settings.maxVolumeInputLabel' => '最大容量(%)',
			'settings.checkForUpdatesDescription' => '現在檢查是否有更新的PlezyNG版本。',
			'settings.appearanceDescription' => '選擇應用程式主題,並調整圖書館卡、主行和導航。',
			'settings.prerollLibraryDescription' => '選擇包含電影預角色可用的剪輯的圖書館。',
			'settings.prerollSelectionDescription' => '選擇從所選圖書館播放的剪輯在電影之前。',
			'settings.contentScreensaverDelayOptionDescription' => '在顯示屏儲存藝術作品之前等待這些無輸入的幾分鐘。',
			'settings.videoCodecOptionDescription' => '允許在支援時直接播放此程式碼器. 未經檢查的程式碼被媒體伺服器編碼。',
			'themeEditor.builtIn' => '內建',
			'themeEditor.presets' => '精選',
			'themeEditor.custom' => '自訂',
			'themeEditor.customEmpty' => '尚未建立',
			'themeEditor.editCustom' => '編輯自訂主題',
			'themeEditor.editCustomDescription' => '自行選擇每一種顏色',
			'themeEditor.locked' => '終身訪問需要',
			'themeEditor.savedLocked' => '儲存 - 可用,終身訪問',
			'themeEditor.title' => '自訂主題',
			'themeEditor.startFrom' => '從現有主題開始',
			'themeEditor.startFromDescription' => '從其他主題複製所有顏色',
			'themeEditor.colors' => '顏色',
			'themeEditor.preview' => '預覽',
			'themeEditor.slots.bg' => '背景',
			'themeEditor.slots.surface' => '面板',
			'themeEditor.slots.outline' => '外框',
			'themeEditor.slots.text' => '文字',
			'themeEditor.slots.textMuted' => '次要文字',
			'themeEditor.slots.accent' => '強調色',
			'themeEditor.opacity' => '不透明度',
			'themeEditor.hexHint' => '#RRGGBB 或 #AARRGGBB',
			'themeEditor.fromOtherThemes' => '來自其他主題',
			'themeEditor.swatchLabel' => ({required Object theme, required Object color}) => '${theme} ${color}',
			'themeEditor.contrast.textOnBg' => '背景上的文字',
			'themeEditor.contrast.textOnSurface' => '面板上的文字',
			'themeEditor.contrast.textMutedOnBg' => '背景上的次要文字',
			'themeEditor.contrast.textMutedOnSurface' => '面板上的次要文字',
			'themeEditor.contrast.accentOnBg' => '背景上的強調色',
			'themeEditor.contrast.accentOnSurface' => '面板上的強調色',
			'themeEditor.contrast.labelOnAccent' => '強調色上的按鈕文字',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}：${ratio}:1，低於建議的 ${minimum}:1',
			'themeEditor.discardTitle' => '要捨棄變更嗎？',
			'themeEditor.discardMessage' => '您尚未儲存的顏色變更將會遺失。',
			'themeEditor.discard' => '捨棄',
			'themeEditor.previewCardTitle' => ({required Object number}) => '第 ${number} 集',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => '剩餘 ${minutes} 分鐘',
			'themeEditor.previewSwitch' => '自動播放',
			'themeEditor.previewMutedText' => '次要文字看起來像這樣',
			'themeEditor.themeSystemDescription' => '跟蹤您的裝置的外觀,並自動在光和黑暗之間交換。',
			'themeEditor.themeLightDescription' => '使用光明的背景與黑暗文字。',
			'themeEditor.themeDarkDescription' => '使用黑暗背景與光明文字。',
			'themeEditor.themeOledDescription' => '使用近黑的表面,減少OLED螢幕上的光。',
			'themeEditor.themeEmberDescription' => '使用溫暖的紅色和<unk>色的重點顏色。',
			'themeEditor.themeGlacierDescription' => '使用冷藍色焦點顏色。',
			'themeEditor.themeForestDescription' => '使用混合的綠色和天然焦點顏色。',
			'themeEditor.themePlumDescription' => '使用紫色和<unk>色的重點顏色。',
			'themeEditor.themePaperDescription' => '使用溫暖的紙類表面和印刷靈感的顏色。',
			'themeEditor.themeCustomDescription' => '使用您在自定義主題編輯器中建立的顏色板。',
			'themeEditor.editorDescription' => '選取調色盤顏色，調整色相、飽和度、亮度或不透明度，並在儲存前查看預覽更新。也可以輸入十六進位顏色。',
			'search.hint' => '搜尋電影、影集、音樂…',
			'search.tryDifferentTerm' => '嘗試不同的關鍵字',
			'search.searchYourMedia' => '搜尋媒體庫',
			'search.enterTitleActorOrKeyword' => '輸入標題、演員或關鍵字',
			'search.people' => '人物',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => '為 ${actionName} 設定快速鍵',
			'hotkeys.clearShortcut' => '清除快速鍵',
			'hotkeys.noShortcutSet' => '未設定快速鍵',
			'hotkeys.currentShortcut' => '目前快速鍵：',
			'hotkeys.pressToRecord' => '選擇以錄製快速鍵',
			'hotkeys.recordingShortcut' => '現在請按下快速鍵組合',
			'hotkeys.actions.playPause' => '播放/暫停',
			'hotkeys.actions.volumeUp' => '調大音量',
			'hotkeys.actions.volumeDown' => '調小音量',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => '快進（${seconds} 秒）',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => '快退（${seconds} 秒）',
			'hotkeys.actions.fullscreenToggle' => '切換全螢幕',
			'hotkeys.actions.muteToggle' => '切換靜音',
			'hotkeys.actions.subtitleToggle' => '切換字幕',
			'hotkeys.actions.audioTrackNext' => '下一個音軌',
			'hotkeys.actions.subtitleTrackNext' => '下一個字幕軌',
			'hotkeys.actions.chapterNext' => '下一個章節',
			'hotkeys.actions.chapterPrevious' => '上一個章節',
			'hotkeys.actions.episodeNext' => '下一集',
			'hotkeys.actions.episodePrevious' => '上一集',
			'hotkeys.actions.speedIncrease' => '加速播放',
			'hotkeys.actions.speedDecrease' => '減速播放',
			'hotkeys.actions.speedReset' => '重設速度',
			'hotkeys.actions.zoomIn' => '放大',
			'hotkeys.actions.zoomOut' => '縮小',
			'hotkeys.actions.zoomReset' => '重設縮放',
			'hotkeys.actions.subSeekNext' => '跳轉至下一句字幕',
			'hotkeys.actions.subSeekPrev' => '跳轉至上一句字幕',
			'hotkeys.actions.subtitleDelayIncrease' => '延遲字幕',
			'hotkeys.actions.subtitleDelayDecrease' => '提前字幕',
			'hotkeys.actions.shaderToggle' => '切換著色器',
			'hotkeys.actions.skipMarker' => '跳過片頭/片尾',
			'hotkeys.actions.screenshot' => '螢幕截圖',
			'hotkeys.actions.framePrevious' => '上一篇:框架',
			'hotkeys.actions.frameNext' => '下一框',
			'fileInfo.title' => '檔案資訊',
			'fileInfo.overview' => '概述',
			'fileInfo.video' => '影片',
			'fileInfo.audio' => '音訊',
			'fileInfo.subtitles' => '字幕',
			'fileInfo.images' => '內嵌圖片',
			'fileInfo.dataStreams' => '資料串流',
			'fileInfo.lyrics' => '歌詞',
			'fileInfo.file' => '檔案',
			'fileInfo.attachments' => '附件',
			'fileInfo.delivery' => '傳輸方式',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => '第 ${index} 個版本，共 ${count} 個',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => '第 ${index} 個檔案，共 ${count} 個',
			'fileInfo.noStreams' => '伺服器回報此檔案沒有串流。',
			'fileInfo.copyPath' => '複製路徑',
			'fileInfo.pathCopied' => '已複製檔案路徑',
			'fileInfo.codec' => '編解碼器',
			'fileInfo.codecTag' => '編解碼器標籤',
			'fileInfo.resolution' => '解析度',
			'fileInfo.codedResolution' => '編碼解析度',
			'fileInfo.bitrate' => '位元率',
			'fileInfo.frameRate' => '影格率',
			'fileInfo.rotation' => '旋轉',
			'fileInfo.comment' => '註解',
			'fileInfo.audioDescription' => '口述影像',
			'fileInfo.headerCompression' => '標頭壓縮',
			'fileInfo.sidecarFile' => '附屬檔案',
			'fileInfo.transportTimestamp' => '傳輸時間戳記',
			'fileInfo.displayOffset' => '顯示偏移',
			'fileInfo.previewFailureCode' => '預覽失敗代碼',
			'fileInfo.previewRetries' => '預覽重試次數',
			'fileInfo.aspectRatio' => '寬高比',
			'fileInfo.pixelAspectRatio' => '像素寬高比',
			'fileInfo.profile' => '規格檔（Profile）',
			'fileInfo.level' => '等級',
			'fileInfo.bitDepth' => '位元深度',
			'fileInfo.pixelFormat' => '像素格式',
			'fileInfo.colorSpace' => '色彩空間',
			'fileInfo.colorRange' => '色彩範圍',
			'fileInfo.colorPrimaries' => '色彩基色',
			'fileInfo.colorTransfer' => '色彩轉換',
			'fileInfo.chromaSubsampling' => '色度抽樣',
			'fileInfo.chromaLocation' => '色度位置',
			'fileInfo.scanType' => '掃描類型',
			'fileInfo.interlaced' => '交錯式',
			'fileInfo.anamorphic' => '變形寬銀幕',
			'fileInfo.referenceFrames' => '參考影格',
			'fileInfo.dynamicRange' => '動態範圍',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Dolby Vision 等級',
			'fileInfo.dolbyVisionVersion' => 'Dolby Vision 版本',
			'fileInfo.dolbyVisionLayers' => 'Dolby Vision 圖層',
			'fileInfo.baseLayerCompatibility' => '基礎圖層相容性',
			'fileInfo.avcBitstream' => 'AVC 位元串流',
			'fileInfo.nalLengthSize' => 'NAL 長度大小',
			'fileInfo.scalingMatrix' => '自訂縮放矩陣',
			'fileInfo.streamIdentifier' => '串流識別碼',
			'fileInfo.streamIndex' => '串流索引',
			'fileInfo.streamId' => '串流 ID',
			'fileInfo.language' => '語言',
			'fileInfo.languageCode' => '語言代碼',
			'fileInfo.streamTitle' => '軌道名稱',
			'fileInfo.channels' => '聲道數',
			'fileInfo.sampleRate' => '取樣率',
			'fileInfo.spatialAudio' => '空間音訊',
			'fileInfo.textBased' => '文字型',
			'fileInfo.subtitleFormat' => '附屬檔案格式',
			'fileInfo.provider' => '提供者',
			'fileInfo.matchScore' => '相符度',
			'fileInfo.externalDelivery' => '可分開傳送',
			'fileInfo.sidecarPath' => '附屬路徑',
			'fileInfo.sourceStream' => '複製來源',
			'fileInfo.temporary' => '暫時',
			'fileInfo.timeBase' => '時間基準',
			'fileInfo.overallBitrate' => '總位元率',
			'fileInfo.path' => '路徑',
			'fileInfo.fileName' => '檔案名稱',
			'fileInfo.size' => '大小',
			'fileInfo.totalSize' => '總大小',
			'fileInfo.container' => '封裝格式',
			'fileInfo.duration' => '長度',
			'fileInfo.previewThumbnails' => '預覽縮圖',
			'fileInfo.previewIndex' => '預覽索引',
			'fileInfo.packetLength' => '封包長度',
			'fileInfo.filePresent' => '檔案存在',
			'fileInfo.fileReadable' => '伺服器可讀取',
			'fileInfo.streamPath' => '串流路徑',
			'fileInfo.optimizedForStreaming' => '已最佳化串流播放',
			'fileInfo.has64bitOffsets' => '具 64 位元偏移量',
			'fileInfo.protocol' => '通訊協定',
			'fileInfo.mediaType' => '媒體類型',
			'fileInfo.sourceKind' => '來源類型',
			'fileInfo.optimizedVersion' => '最佳化版本',
			'fileInfo.optimizationTarget' => '最佳化目標',
			'fileInfo.deletedAt' => '已刪除',
			'fileInfo.remoteSource' => '遠端來源',
			'fileInfo.infiniteStream' => '無限串流',
			'fileInfo.directPlay' => '直接播放',
			'fileInfo.directStream' => '直接串流',
			'fileInfo.transcoding' => '轉碼',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => '版本 ID',
			'fileInfo.fileId' => '檔案 ID',
			'fileInfo.defaultAudioTrack' => '預設音軌',
			'fileInfo.defaultSubtitleTrack' => '預設字幕軌',
			'fileInfo.subtitlesOff' => '關閉',
			'fileInfo.flagDefault' => '預設',
			'fileInfo.flagForced' => '強制',
			'fileInfo.flagSelected' => '已選取',
			'fileInfo.flagExternal' => '外部',
			'fileInfo.flagHearingImpaired' => '聽障輔助',
			'fileInfo.flagDub' => '配音',
			'fileInfo.flagOriginal' => '原音',
			'fileInfo.channelsMono' => '單聲道',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => '規格檔（Profile）${profile}',
			'mediaMenu.markAsWatched' => '標記為已觀看',
			'mediaMenu.markAsUnwatched' => '標記為未觀看',
			'mediaMenu.removeFromContinueWatching' => '從「繼續觀看」中移除',
			'mediaMenu.viewDetails' => '查看詳情',
			'mediaMenu.goToSeries' => '前往影集',
			'mediaMenu.shufflePlay' => '隨機播放',
			'mediaMenu.shuffleNotAvailableOffline' => '離線時無法隨機播放',
			'mediaMenu.fileInfo' => '檔案資訊',
			'mediaMenu.deleteEpisodeFromServer' => '從伺服器刪除單集',
			'mediaMenu.deleteSeasonFromServer' => '從伺服器刪除季',
			'mediaMenu.deleteShowFromServer' => '從伺服器刪除影集',
			'mediaMenu.deleteMovieFromServer' => '從伺服器刪除電影',
			'mediaMenu.deleteEpisodeTitle' => '刪除此單集？',
			'mediaMenu.deleteSeasonTitle' => '刪除此季？',
			'mediaMenu.deleteShowTitle' => '刪除此影集？',
			'mediaMenu.deleteMovieTitle' => '刪除此電影？',
			'mediaMenu.deleteEpisodeConfirm' => '刪除單集',
			'mediaMenu.deleteSeasonConfirm' => '刪除季',
			'mediaMenu.deleteShowConfirm' => '刪除影集',
			'mediaMenu.deleteMovieConfirm' => '刪除電影',
			'mediaMenu.deleteAnyway' => '仍要刪除',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => '確定要從您的伺服器永久刪除「${title}」嗎？',
			'mediaMenu.deleteMultipleWarning' => '這將會刪除所有單集及其檔案。',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '這會刪除其中的 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 集及其檔案。', other: '這會刪除其中全部 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 集及其檔案。', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '此項目儲存在 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 個檔案中，該檔案將被刪除。', other: '此項目分散儲存於 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 個檔案中，且全部都會被刪除。', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '另有 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 集儲存在同一檔案中，也會一併被刪除：', other: '另有 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 集儲存在同一檔案中，也會一併被刪除：', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'PlezyNG 無法確認此操作會刪除哪些檔案，因此刪除範圍可能超出上方所列的項目。請取消後重試，或仍要刪除。',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => '您的伺服器未提供此項目的檔案資訊，因此 PlezyNG 無法確認此操作會刪除哪些檔案。刪除範圍可能超出上方所列的項目。',
			'mediaMenu.mediaDeletedSuccessfully' => '媒體已成功刪除',
			'mediaMenu.mediaFailedToDelete' => '刪除媒體失敗',
			'mediaMenu.rate' => '評分',
			'mediaMenu.playFromBeginning' => '從頭播放',
			'mediaMenu.playVersion' => '播放版本…',
			'rateSheet.title' => '評分',
			'rateSheet.server' => '伺服器',
			'rateSheet.favorite' => '最愛',
			'rateSheet.favorited' => '已加入最愛',
			'rateSheet.saved' => '已儲存',
			'rateSheet.notAvailable' => '找不到相符項目',
			'rateSheet.noConnectedServices' => '在設定中連結外部服務後，即可在此評分。',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, 電影',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, 影集',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => '已觀看',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '已觀看 ${percent}%',
			'accessibility.mediaCardUnwatched' => '未觀看',
			'accessibility.tapToPlay' => '輕觸即可播放',
			'accessibility.decrease' => '減小',
			'accessibility.increase' => '增大',
			'accessibility.decreaseValue' => ({required Object label}) => '減小 ${label}',
			'accessibility.increaseValue' => ({required Object label}) => '增大 ${label}',
			'accessibility.hue' => '色相',
			'accessibility.saturation' => '飽和度',
			'accessibility.brightness' => '亮度',
			'accessibility.hexColor' => 'Hex 顏色值',
			'accessibility.expandText' => '展開文字',
			'accessibility.collapseText' => '收合文字',
			'accessibility.alphabetNavigation' => '字母導覽',
			'accessibility.alphabetScrollHint' => '向上或向下滑動以按字母移動',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => '第 ${row} 列，共 ${rowCount} 列；第 ${column} 欄，共 ${columnCount} 欄',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => '第 ${row} 列，共 ${rowCount} 列',
			'accessibility.autoScrollPlay' => '開始自動捲動',
			'accessibility.autoScrollPause' => '暫停自動捲動',
			'accessibility.hueShort' => 'H',
			'accessibility.saturationShort' => 'S',
			'accessibility.valueShort' => '五',
			'accessibility.red' => '紅色',
			'accessibility.green' => '綠色',
			'accessibility.blue' => '藍色',
			'accessibility.redShort' => '裡',
			'accessibility.greenShort' => 'G',
			'accessibility.blueShort' => 'B',
			'accessibility.colorModeHsv' => 'HSV',
			'accessibility.colorModeRgb' => '裡格',
			'accessibility.title' => '可用性',
			'accessibility.summary' => '文字、對比、動作和控制',
			'accessibility.systemHint' => '您的裝置的可用性設定始終適用. 這些選項在 PlezyNG 期間新增調整。',
			'accessibility.readability' => '閱讀與可見性',
			'accessibility.textSize' => '附加文字大小',
			'accessibility.preview' => '找下一個故事,閱讀,聽,並以自己的速度觀看。',
			'accessibility.boldText' => '勇敢的介面文字',
			'accessibility.highContrast' => '高度對比',
			'accessibility.highContrastHint' => '在淺色或深色背景上，讓文字、輪廓線和焦點指示器更清晰。',
			'accessibility.interaction' => '動作與互動',
			'accessibility.reduceMotion' => '減少動作',
			'accessibility.reduceMotionHint' => '停止焦點指示器、頁面切換和裝飾效果的動畫。',
			'accessibility.largeTargets' => '觸控目標',
			'accessibility.largeTargetsHint' => '共享控制器提供更多觸控和輔助導航空間。',
			'accessibility.navigationHint' => '使用 Tab 和 Shift+Tab 在控制項之間移動，按 Enter 或空白鍵啟用，按 Escape 或返回按鈕關閉。開啟書籍後，可調整縮放比例和閱讀偏好設定。',
			'accessibility.textSizeDescription' => '在 PlezyNG 中擴充套件介面文字,以及您的裝置的系統文字大小設定。',
			'accessibility.boldTextHint' => '加粗介面標籤與訊息的字重，讓它們更容易辨識。',
			'tooltips.shufflePlay' => '隨機播放',
			'tooltips.playTrailer' => '播放預告片',
			'tooltips.markAsWatched' => '標記為已觀看',
			'tooltips.markAsUnwatched' => '標記為未觀看',
			'audioTracks.track' => ({required Object n}) => '音軌 ${n}',
			'videoControls.audioLabel' => '音訊',
			'videoControls.subtitlesLabel' => '字幕',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount} ${unit}',
			'videoControls.letterbox' => '信箱模式（Letterbox）',
			'videoControls.fillScreen' => '填滿螢幕',
			'videoControls.stretch' => '拉伸',
			'videoControls.lockRotation' => '鎖定旋轉',
			'videoControls.unlockRotation' => '解除鎖定旋轉',
			'videoControls.timerActive' => '計時器已啟動',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => '播放將在 ${duration} 後暫停',
			'videoControls.sleepTimerEndOfVideo' => '目前影片結束時',
			'videoControls.sleepTimerStopAtHeader' => '停止於',
			'videoControls.sleepTimerDurationHeader' => '計時器',
			'videoControls.playbackWillPauseAtEnd' => '播放將在此影片結束時暫停',
			'videoControls.stillWatching' => '您還在觀看嗎？',
			'videoControls.pausingIn' => ({required Object seconds}) => '${seconds} 秒後暫停',
			'videoControls.continueWatching' => '繼續播放',
			'videoControls.autoPlayNext' => '自動播放下一集',
			'videoControls.playNext' => '播放下一集',
			'videoControls.playButton' => '播放',
			'videoControls.pauseButton' => '暫停',
			'videoControls.playbackPaused' => '已暫停',
			'videoControls.playbackResumed' => '播放中',
			'videoControls.loadingVideo' => '正在載入影片',
			'videoControls.showPlaybackControls' => '顯示播放控制項',
			'videoControls.hidePlaybackControls' => '隱藏播放控制項',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => '後退 ${seconds} 秒',
			'videoControls.seekForwardButton' => ({required Object seconds}) => '前進 ${seconds} 秒',
			'videoControls.previousButton' => '上一集',
			'videoControls.nextButton' => '下一集',
			'videoControls.previousChapterButton' => '上一個章節',
			'videoControls.nextChapterButton' => '下一個章節',
			'videoControls.muteButton' => '靜音',
			'videoControls.unmuteButton' => '取消靜音',
			'videoControls.settingsButton' => '播放設定',
			'videoControls.tracksButton' => '音訊與字幕',
			'videoControls.chaptersButton' => '章節',
			'videoControls.versionQualityButton' => '版本與畫質',
			'videoControls.versionColumnHeader' => '版本',
			'videoControls.qualityColumnHeader' => '畫質',
			'videoControls.qualityOriginal' => '原始畫質',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => '無法使用轉碼 — 將以原始畫質播放',
			'videoControls.subtitleUnavailableFallback' => '無法載入所選字幕 — 將繼續無字幕播放',
			'videoControls.pipButton' => '子母畫面模式',
			'videoControls.aspectRatioButton' => '寬高比',
			'videoControls.ambientLighting' => '氛圍燈光',
			'videoControls.fullscreenButton' => '進入全螢幕',
			'videoControls.exitFullscreenButton' => '退出全螢幕',
			'videoControls.alwaysOnTopButton' => '視窗置頂',
			'videoControls.rotationLockButton' => '旋轉鎖定',
			_ => null,
		} ?? switch (path) {
			'videoControls.lockScreen' => '鎖定螢幕',
			'videoControls.screenLockButton' => '螢幕鎖定',
			'videoControls.timelineSlider' => '影片時間軸',
			'videoControls.volumeSlider' => '音量調整',
			'videoControls.endsAt' => ({required Object time}) => '預計 ${time} 結束',
			'videoControls.pipActive' => '正在以子母畫面模式播放',
			'videoControls.pipFailed' => '啟動子母畫面失敗',
			'videoControls.screenshotSaved' => '螢幕截圖已儲存',
			'videoControls.screenshotFailed' => '無法擷取螢幕截圖',
			'videoControls.zoomPercent' => ({required Object percent}) => '縮放 ${percent}%',
			'videoControls.volumePercent' => ({required Object percent}) => '音量 ${percent}%',
			'videoControls.pipErrors.androidVersion' => '需要 Android 8.0 或更高版本',
			'videoControls.pipErrors.iosVersion' => '需要 iOS 15.0 或更高版本',
			'videoControls.pipErrors.permissionDisabled' => '子母畫面權限已停用。請在系統設定中啟用。',
			'videoControls.pipErrors.notSupported' => '此裝置不支援子母畫面模式',
			'videoControls.pipErrors.voSwitchFailed' => '無法切換子母畫面的影片輸出',
			'videoControls.pipErrors.failed' => '啟動子母畫面失敗',
			'videoControls.pipErrors.prepareFailed' => '無法準備子母畫面',
			'videoControls.pipErrors.unknown' => ({required Object error}) => '發生錯誤：${error}',
			'videoControls.chapters' => '章節',
			'videoControls.noChaptersAvailable' => '沒有可用的章節',
			'videoControls.queue' => '播放佇列',
			'videoControls.noQueueItems' => '佇列中沒有項目',
			'videoControls.noAudioDevicesAvailable' => '沒有可用的音訊裝置',
			'videoControls.searchSubtitles' => '搜尋字幕',
			'videoControls.language' => '語言',
			'videoControls.noSubtitlesFound' => '找不到字幕',
			'videoControls.subtitleDownloaded' => '字幕下載成功',
			'videoControls.subtitleDownloadedNotApplied' => '字幕已下載，但無法套用',
			'videoControls.subtitleDownloadFailed' => '字幕下載失敗',
			'videoControls.searchLanguages' => '搜尋語言…',
			'videoControls.skipIntro' => '略過片頭',
			'videoControls.skipCredits' => '略過片尾',
			'videoControls.nextEpisode' => '下一集',
			'videoControls.subtitleTrack' => ({required Object n}) => '字幕軌 ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => '字幕 ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label}（強制）',
			'videoControls.osdSubtitlesOff' => '字幕：關閉',
			'videoControls.osdSubtitles' => ({required Object track}) => '字幕：${track}',
			'videoControls.osdAudio' => ({required Object track}) => '音訊：${track}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 框架', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 框架', ), 
			'videoControls.trackSelectionTitle' => '選擇遊戲前的遊戲',
			'videoControls.trackSelectionAuto' => '自動選擇',
			'videoControls.openMiniPlayer' => '開放小型玩家',
			'videoControls.returnToFullPlayer' => '回到全玩家',
			'videoControls.loadSubtitleFile' => '查詢下載檔案...',
			'videoControls.subtitleLoadFailed' => '未能下載字幕檔案',
			'videoControls.skipAds' => '滑雪廣告',
			'videoControls.tapToUnlock' => '點一下以解鎖',
			'videoControls.tapAgainToUnlock' => '再次點一下以解鎖',
			'messages.markedAsWatched' => '已標記為已觀看',
			'messages.markedAsUnwatched' => '已標記為未觀看',
			'messages.markedAsWatchedOffline' => '已標記為已觀看（將在連線時同步）',
			'messages.markedAsUnwatchedOffline' => '已標記為未觀看（將在連線時同步）',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => '已自動移除：${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '自動移除 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 觀看下載', other: '已自動移除 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 個已觀看的下載內容', ), 
			'messages.removedFromContinueWatching' => '已從「繼續觀看」中移除',
			'messages.errorLoading' => ({required Object error}) => '錯誤：${error}',
			'messages.searchPartialResults' => '部分媒體伺服器無法搜尋。目前顯示可取得的結果。',
			'messages.streamInterrupted' => '影片串流中斷。請按播放鍵或拖動進度條重試。',
			'messages.liveStreamInterrupted' => '直播串流中斷。請按播放鍵重試。',
			'messages.fileInfoNotAvailable' => '無法取得檔案資訊',
			'messages.playbackAuthenticationRequired' => '若要播放此項目，請重新登入媒體伺服器。',
			'messages.playbackServerUnavailable' => '媒體伺服器目前無法使用。請稍後再試。',
			'messages.playbackDataInvalid' => '伺服器傳回的播放資訊無效。',
			'messages.playbackCancelled' => '播放已取消。',
			'messages.playbackFailed' => '無法開始播放。',
			'messages.playbackFailedDetail' => ({required Object error}) => '無法開始播放：${error}',
			'messages.audioOutputFailed' => '音訊輸出停止回應。請檢查電視或擴大機的音訊連接；如果其他應用程式也沒有聲音，請重新啟動裝置。',
			'messages.mediaUnavailable' => '此內容已無法使用。',
			'messages.errorLoadingFileInfo' => ({required Object error}) => '載入檔案資訊時發生錯誤：${error}',
			'messages.errorLoadingSeries' => '載入影集時發生錯誤',
			'messages.musicNotSupported' => '目前不支援播放音樂',
			'messages.noDescriptionAvailable' => '目前沒有描述',
			'messages.noProfilesAvailable' => '沒有可用的使用者設定檔',
			'messages.contactAdminForProfiles' => '請聯絡伺服器管理員新增使用者設定檔',
			'messages.unableToDetermineLibrarySection' => '無法確定此項目的媒體庫分區',
			'messages.logsCleared' => '日誌已清除',
			'messages.logsCopied' => '日誌已複製到剪貼簿',
			'messages.noLogsAvailable' => '沒有可用的日誌',
			'messages.libraryScanning' => ({required Object title}) => '正在掃描「${title}」…',
			'messages.libraryScanStarted' => ({required Object title}) => '已開始掃描「${title}」媒體庫',
			'messages.libraryScanFailed' => ({required Object error}) => '無法掃描媒體庫：${error}',
			'messages.metadataRefreshing' => ({required Object title}) => '正在重新整理「${title}」的中繼資料…',
			'messages.metadataRefreshStarted' => ({required Object title}) => '已開始重新整理「${title}」的中繼資料',
			'messages.metadataRefreshFailed' => ({required Object error}) => '無法重新整理中繼資料：${error}',
			'messages.logoutConfirm' => '您確定要登出嗎？',
			'messages.noSeasonsFound' => '找不到季數',
			'messages.seasonsLoadFailed' => '無法載入季數',
			'messages.noEpisodesFound' => '在第一季中找不到單集',
			'messages.noEpisodesFoundGeneral' => '找不到單集',
			'messages.episodesLoadFailed' => '無法載入單集',
			'messages.noResultsFound' => '找不到結果',
			'messages.sleepTimerSet' => ({required Object label}) => '睡眠計時器已設定為 ${label}',
			'messages.noItemsAvailable' => '沒有可用的項目',
			'messages.failedToCreatePlayQueueNoItems' => '無法建立播放佇列 — 沒有項目',
			'messages.failedPlayback' => ({required Object action, required Object error}) => '無法${action}：${error}',
			'messages.switchingToCompatiblePlayer' => '正在切換至相容的播放器…',
			'messages.serverLimitTitle' => '播放失敗',
			'messages.serverLimitBody' => '伺服器錯誤（HTTP 500）。伺服器的頻寬或轉碼限制可能拒絕此播放要求。請聯絡伺服器擁有者調整設定。',
			'messages.mediaUnreadableTitle' => '檔案無法使用',
			'messages.mediaUnreadableBody' => '伺服器找到了此項目，但無法讀取其檔案（HTTP 404）。檔案可能已移動、刪除，或其儲存空間離線。請聯絡伺服器擁有者檢查檔案並重新掃描媒體庫。',
			'messages.serverBusyTitle' => '串流無法使用',
			'messages.serverBusyBody' => '伺服器持續拒絕串流此檔案（HTTP 503）。伺服器可能正在重新啟動、忙碌中，或檔案所在的儲存裝置可能已離線。請稍後再試；若問題持續發生，請要求伺服器擁有者檢查伺服器及檔案所在的儲存裝置。',
			'messages.playbackNotAllowedTitle' => '不允許播放',
			'messages.playbackNotAllowedBody' => '伺服器拒絕串流此項目（HTTP 403）。此帳戶可能沒有播放權限，或伺服器可能只允許在其區域網路內播放。',
			'messages.logsUploaded' => '日誌已上傳',
			'messages.logsUploadFailed' => '上傳日誌失敗',
			'messages.logId' => '日誌 ID',
			'messages.burnedSubtitlesUseMenu' => '字幕已燒錄至此串流中。請從字幕選單變更字幕。',
			'messages.noVideoUrl' => '沒有可用的視訊 URL',
			'messages.playbackNoMediaSources' => '伺服器未傳回可播放的媒體來源',
			'messages.playbackDataNotPrepared' => '播放資料尚未準備完成就已開始播放',
			'messages.streamSelectionUnavailable' => '此來源不支援選擇串流',
			'messages.streamSelectionFailed' => '無法套用所選串流',
			'messages.trackSelectionNotRemembered' => '此軌道選擇僅套用於目前播放。',
			'messages.serverUnavailableForProfile' => '使用中的使用者設定檔沒有可用的伺服器',
			'subtitlingStyling.previewSample' => '快速的棕色<unk>子跳過可憐的狗',
			'subtitlingStyling.text' => '文字',
			'subtitlingStyling.border' => '邊框',
			'subtitlingStyling.background' => '背景',
			'subtitlingStyling.fontSize' => '字型大小',
			'subtitlingStyling.textColor' => '文字顏色',
			'subtitlingStyling.borderSize' => '邊框大小',
			'subtitlingStyling.borderColor' => '邊框顏色',
			'subtitlingStyling.backgroundOpacity' => '背景不透明度',
			'subtitlingStyling.backgroundColor' => '背景顏色',
			'subtitlingStyling.position' => '位置',
			'subtitlingStyling.assOverride' => '覆蓋 ASS 樣式',
			'subtitlingStyling.overrideScale' => '縮放',
			'subtitlingStyling.overrideForce' => '強制套用',
			'subtitlingStyling.overrideStrip' => '移除樣式',
			'subtitlingStyling.positionTop' => '頂部',
			'subtitlingStyling.positionBottom' => '底部',
			'subtitlingStyling.useMargins' => '使用邊距',
			'subtitlingStyling.useMarginsDescription' => '允許文字字幕顯示在影片畫面之外的區域。樣式字幕可能保留其原始位置。',
			'subtitlingStyling.anchorToScreen' => '錨定至螢幕',
			'subtitlingStyling.anchorToScreenDescription' => '在寬螢幕影片下方的黑邊顯示文字字幕',
			'subtitlingStyling.bold' => '粗體',
			'subtitlingStyling.italic' => '斜體',
			'subtitlingStyling.renderResolution' => '渲染解析度',
			'subtitlingStyling.renderResolutionScreen' => '螢幕解析度',
			'subtitlingStyling.renderResolutionVideo' => '影片解析度',
			'subtitlingStyling.fontSizeDescription' => '在此裝置上設定字幕文字大小。',
			'subtitlingStyling.textColorDescription' => '選擇用於字幕文字的顏色。',
			'subtitlingStyling.borderSizeDescription' => '設定字幕厚度周圍的字幕文字。',
			'subtitlingStyling.borderColorDescription' => '選擇用於子標題輸出的顏色。',
			'subtitlingStyling.backgroundColorDescription' => '選擇字幕文字背後的顏色。',
			'subtitlingStyling.backgroundOpacityDescription' => '設定字幕背景透明度:0%是清晰的,100%是堅固的。',
			'subtitlingStyling.positionDescription' => '垂直移動字幕:0%是影片的頂部,100%是底部。',
			'subtitlingStyling.assOverrideDescription' => '選擇玩家是否遵循、調整、更換或刪除在 ASS 子標題中嵌入的風格。',
			'subtitlingStyling.assOverrideOptions.no' => '保持字型、顏色、尺寸和位置寫在子標題檔案中。',
			'subtitlingStyling.assOverrideOptions.yes' => '允許玩家的字幕風格設定調整 ASS 字幕。',
			'subtitlingStyling.assOverrideOptions.scale' => '應用播放器風格和規模嵌入式尺寸,以匹配影片尺寸。',
			'subtitlingStyling.assOverrideOptions.force' => '取代嵌入式 ASS 風格與玩家的字幕風格。',
			'subtitlingStyling.assOverrideOptions.strip' => '刪除嵌入式 ASS 格式化,並清晰地顯示字幕文字。',
			'subtitlingStyling.renderResolutionDescription' => '選擇使用的解析度來拉斯特化影象和ASS子標題. 較低的Android尺寸可以減少演示工作,但看起來更柔軟。',
			'subtitlingStyling.renderResolutionOptions.screen' => '以全顯示錶面解析度為最清晰的結果。',
			'subtitlingStyling.renderResolutionOptions.video' => '以影片解析度為基準進行渲染，這可減少高解析度螢幕上的運算量。',
			'subtitlingStyling.renderResolutionOptions.threeQuarter' => '以75%的顯示錶面解析度為低效節約。',
			'subtitlingStyling.renderResolutionOptions.half' => '放入 50% 的顯示錶面解析度,以減少工作,與軟的邊緣。',
			'subtitlingStyling.renderResolutionOptions.third' => '以顯示表面解析度的三分之一進行渲染，以減少運算量並讓邊緣更柔和。',
			'subtitlingStyling.renderResolutionOptions.quarter' => '在顯示錶面解析度的四分之一下降,以減少工作,最柔軟的結果。',
			'subtitlingStyling.boldDescription' => '以更重的重量繪製字型。',
			'subtitlingStyling.italicDescription' => '在義大利語中繪製字幕文字。',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => '進階影片播放器設定',
			'mpvConfig.presets' => '預設組',
			'mpvConfig.noPresets' => '沒有儲存的預設組',
			'mpvConfig.saveAsPreset' => '儲存為預設組…',
			'mpvConfig.presetName' => '預設組名稱',
			'mpvConfig.presetNameHint' => '輸入此預設組的名稱',
			'mpvConfig.loadPreset' => '載入',
			'mpvConfig.deletePreset' => '刪除',
			'mpvConfig.presetSaved' => '預設組已儲存',
			'mpvConfig.presetLoaded' => '預設組已載入',
			'mpvConfig.presetDeleted' => '預設組已刪除',
			'mpvConfig.confirmDeletePreset' => '確定要刪除此預設組嗎？',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# 註解',
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => '新增行',
			'mpvConfig.removeLine' => '移除行',
			'mpvConfig.embeddedVoHint' => '在 Linux 上會忽略 vo、gpu-context 和 gpu-api：嵌入式影片一律透過影片平面上的 vo=libmpv 轉譯，而 gpu-next（ArtCNN 等計算著色器需要它）無法以嵌入式方式執行。',
			'dialog.confirmAction' => '確認操作',
			'profiles.addPlezyProfile' => '新增 PlezyNG 使用者設定檔',
			'profiles.switchingProfile' => '正在切換使用者設定檔…',
			'profiles.deleteThisProfileTitle' => '刪除此使用者設定檔？',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => '將移除 ${displayName}。連線資訊將不受影響。',
			'profiles.active' => '使用中',
			'profiles.manage' => '管理',
			'profiles.delete' => '刪除',
			'profiles.signOut' => '登出',
			'profiles.signOutPlexTitle' => '登出 Plex？',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => '確定要移除 ${displayName} 與所有 Plex Home 使用者嗎？您可以隨時重新登入。',
			'profiles.signOutPlexDeleteDownloads' => '一併刪除下載內容',
			'profiles.signOutPlexDeleteDownloadsDescription' => '否則下載內容會保留在此裝置上，並在您重新登入此帳號時恢復。',
			'profiles.signedOutPlex' => '已登出 Plex。',
			'profiles.signOutFailed' => '登出失敗。',
			'profiles.sectionTitle' => '使用者設定檔',
			'profiles.summarySingle' => '新增使用者設定檔，以同時管理託管使用者與本地身分',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} 個設定檔 · 使用中：${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} 個設定檔',
			'profiles.removeConnectionTitle' => '移除連線？',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => '將移除 ${displayName} 對 ${connectionLabel} 的存取權限。其他使用者設定檔仍可使用此連線。',
			'profiles.deleteProfileTitle' => '刪除使用者設定檔？',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => '將移除 ${displayName} 及其連線資訊。伺服器仍維持可用狀態。',
			'profiles.profileNameLabel' => '使用者設定檔名稱',
			'profiles.pinProtectionLabel' => 'PIN 碼保護',
			'profiles.copyAutomationLink' => '複製 Android 自動化連結',
			'profiles.copyAutomationLinkDescription' => '從 Android 意圖或自動化中選擇此檔案,檔案 PIN 檢查仍適用。',
			'profiles.automationLinkCopied' => '個人資料自動化連結複製。',
			'profiles.pinManagedByPlex' => 'PIN 碼由 Plex 管理。請至 plex.tv 進行編輯。',
			'profiles.noPinSetEditOnPlex' => '未設定 PIN 碼。如需啟用 PIN 碼限制，請在 plex.tv 編輯 Home 使用者設定。',
			'profiles.setPin' => '設定 PIN 碼',
			'profiles.setPinTitle' => '設定 PIN 碼',
			'profiles.confirmPinTitle' => '確認 PIN 碼',
			'profiles.pinSet' => 'PIN 碼已設定',
			'profiles.changePin' => '變更',
			'profiles.removePin' => '移除',
			'profiles.connectionsLabel' => '連線',
			'profiles.add' => '新增',
			'profiles.deleteProfileButton' => '刪除使用者設定檔',
			'profiles.noConnectionsHint' => '無連線 — 請新增一個連線以啟用此設定檔。',
			'profiles.noConnections' => '無連線資訊',
			'profiles.plexHomeAccount' => 'Plex Home 帳戶',
			'profiles.plexAccountChip' => ({required Object account}) => 'Plex 帳戶：${account}',
			'profiles.plexAccountUserChip' => ({required Object account, required Object user}) => '${account} 帳戶下的 ${user}',
			'profiles.connectionDefault' => '預設',
			'profiles.connectionAs' => ({required Object displayName}) => '以 ${displayName} 身分',
			'profiles.makeDefault' => '設為預設值',
			'profiles.removeConnection' => '移除',
			'profiles.profileRenamed' => '使用者設定檔已重新命名。',
			'profiles.borrowAddTo' => ({required Object displayName}) => '新增至 ${displayName}',
			'profiles.borrowExplain' => '共用另一個使用者設定檔的連線資訊。受 PIN 碼保護的設定檔需輸入 PIN 碼。',
			'profiles.borrowEmpty' => '目前沒有可共用的連線。',
			'profiles.borrowEmptySubtitle' => '請先將 Plex、Jellyfin 或 Emby 連線至另一個使用者設定檔。',
			'profiles.borrowLoadFailed' => '無法載入可用的連線。請重試。',
			'profiles.borrowFromProfile' => ({required Object displayName}) => '來自 ${displayName}',
			'profiles.borrowConnectionBorrowed' => '已共用連線。',
			'profiles.borrowFailed' => '無法共用連線。',
			'profiles.incorrectPin' => 'PIN 碼不正確。',
			'profiles.incorrectPinTryAgain' => 'PIN 碼不正確。請重試。',
			'profiles.sourceProfileMissingParentAccount' => '來源使用者設定檔缺少其父帳戶資訊。',
			'profiles.failedToLoadHomeUsers' => '無法載入您的 Plex Home 使用者。請檢查網路連線後重試。',
			'profiles.failedToVerifyPin' => '無法驗證 PIN 碼。',
			'profiles.newProfile' => '建立使用者設定檔',
			'profiles.profileNameHint' => '例如：訪客、兒童、客廳',
			'profiles.pinProtectionOptional' => 'PIN 碼保護（選填）',
			'profiles.pinExplain' => '切換至此使用者設定檔時需要 4 位數 PIN 碼。',
			'profiles.continueButton' => '繼續',
			'profiles.pinsDontMatch' => 'PIN 碼不符合',
			'profiles.tokenIdentityMismatch' => 'Plex 使用者設定檔權杖解析到非預期的伺服器',
			'profiles.settingsLocked' => '此配置已鎖定。',
			'profiles.unlockSettings' => '解鎖設定',
			'profiles.showExploreForProfile' => '檢視此資料的探索',
			'profiles.showExploreForProfileDescription' => '關閉以從此個人資料的導航中刪除 Explore。',
			'connections.sectionTitle' => '連線',
			'connections.addConnection' => '新增連線',
			'connections.addConnectionSubtitleNoProfile' => '使用 Plex 登入或連線至 Jellyfin 或 Emby 伺服器',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => '新增至 ${displayName}：Plex、Jellyfin、Emby 或其他設定檔連線',
			'connections.sessionExpiredOne' => ({required Object name}) => '${name} 的工作階段已過期',
			'connections.sessionExpiredMany' => ({required Object count}) => '${count} 個伺服器的工作階段已過期',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} 拒絕此帳戶存取',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} 台伺服器拒絕此帳戶存取',
			'connections.signInAgain' => '重新登入',
			'connections.editMediaBrowserTitle' => ({required Object product}) => '編輯 ${product} 連線',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => '為 ${serverName} 新增或移除 URL。PlezyNG 將使用延遲最低且可連線的 URL。',
			'accountPreferences.sectionTitle' => '帳戶偏好設定',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => '已在 ${account} 上儲存音訊、字幕與媒體庫選項',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => '已在 ${count} 個帳戶上儲存音訊、字幕與媒體庫選項',
			'accountPreferences.pickAccount' => '每個帳戶都會儲存各自的偏好設定。請選擇要編輯的帳戶。',
			'accountPreferences.storedOnAccount' => '這些選項會儲存在帳戶本身，因此登入該帳戶的所有應用程式都會使用它們，包括您其他裝置上的 PlezyNG。',
			'accountPreferences.noAccounts' => '沒有可設定的帳戶',
			'accountPreferences.noAccountsHint' => '登入 Plex，或連線至 Jellyfin 或 Emby 伺服器，儲存在該帳戶上的偏好設定便會顯示在此處。',
			'accountPreferences.unavailable' => '無法連線至此帳戶',
			'accountPreferences.loadFailed' => '無法載入這些偏好設定',
			'accountPreferences.noPreference' => '無偏好',
			'accountPreferences.notSet' => '未設定',
			'accountPreferences.groups.audioAndSubtitles' => '音訊與字幕',
			'accountPreferences.groups.libraryDisplay' => '媒體庫',
			'accountPreferences.groups.personalMedia' => '個人媒體',
			'accountPreferences.preferredAudioLanguage' => '偏好音訊語言',
			'accountPreferences.autoSelectAudio' => '依語言選擇音訊',
			'accountPreferences.autoSelectAudioDescription' => '關閉時會使用檔案標記為預設的音訊軌。',
			'accountPreferences.preferredSubtitleLanguage' => '偏好字幕語言',
			'accountPreferences.subtitleMode' => '自動開啟字幕',
			'accountPreferences.subtitleModes.none' => '手動選擇',
			'accountPreferences.subtitleModes.noneDescription' => '絕不自行開啟字幕。',
			'accountPreferences.subtitleModes.defaultMode' => '遵循軌道旗標',
			'accountPreferences.subtitleModes.defaultModeDescription' => '使用每個字幕軌上儲存的預設與強制旗標。',
			'accountPreferences.subtitleModes.always' => '一律啟用',
			'accountPreferences.subtitleModes.alwaysDescription' => '只要有偏好語言的字幕軌就自動開啟。',
			'accountPreferences.subtitleModes.onlyForced' => '僅強制字幕',
			'accountPreferences.subtitleModes.onlyForcedDescription' => '僅載入標記為強制的軌道。',
			'accountPreferences.subtitleModes.smart' => '外語配音時顯示',
			'accountPreferences.subtitleModes.smartDescription' => '僅在音訊為其他語言時開啟字幕。',
			'accountPreferences.subtitleAccessibility' => 'SDH 字幕',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => '偏好非 SDH 字幕',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => '偏好 SDH 字幕',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => '僅 SDH 字幕',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => '僅非 SDH 字幕',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdhDescription' => '偏好標準字幕,當既有標準和SDH版本時。',
			'accountPreferences.subtitleAccessibilityOptions.preferSdhDescription' => '偏好在可用時使用 SDH 字幕,但允許標準字幕作為落後。',
			'accountPreferences.subtitleAccessibilityOptions.onlySdhDescription' => '只使用 SDH 字幕;不要返回標準字幕。',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdhDescription' => '只使用標準字幕;排除 SDH 字幕。',
			'accountPreferences.forcedSubtitles' => '強制字幕',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => '偏好非強制字幕',
			'accountPreferences.forcedSubtitleOptions.preferForced' => '偏好強制字幕',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => '僅強制字幕',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => '僅非強制字幕',
			'accountPreferences.forcedSubtitleOptions.preferNonForcedDescription' => '更喜歡定期的字幕,但允許強迫軌道作為落後。',
			'accountPreferences.forcedSubtitleOptions.preferForcedDescription' => '偏好在可用時強迫行列,但允許定期字幕作為落後。',
			'accountPreferences.forcedSubtitleOptions.onlyForcedDescription' => '只使用被強制標記的軌道。',
			'accountPreferences.forcedSubtitleOptions.onlyNonForcedDescription' => '排除被強制標記的軌道。',
			'accountPreferences.displayMissingEpisodes' => '顯示缺少的單集',
			'accountPreferences.displayMissingEpisodesDescription' => '列出伺服器已知但沒有檔案的單集。',
			'accountPreferences.hidePlayedInLatest' => '在「最新」中隱藏已觀看項目',
			'accountPreferences.hidePlayedInLatestDescription' => '將您已觀看的項目從伺服器的「最新」列中移除。',
			'accountPreferences.displayCollectionsView' => '顯示收藏集檢視',
			'accountPreferences.displayCollectionsViewDescription' => '在您的媒體庫旁提供伺服器的收藏集檢視。',
			'accountPreferences.rewatchingInNextUp' => '在「接下來播放」中保留重看的影集',
			'accountPreferences.rewatchingInNextUpDescription' => '看完一部影集後再次開始觀看時，「接下來播放」會追蹤重看的進度，而不是將該影集移除。',
			'accountPreferences.watchedIndicator' => '已觀看指示',
			'accountPreferences.watchedIndicatorOptions.none' => '從不',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => '電影與影集',
			'accountPreferences.watchedIndicatorOptions.movies' => '僅電影',
			'accountPreferences.watchedIndicatorOptions.shows' => '僅影集',
			'accountPreferences.watchedIndicatorOptions.noneDescription' => '不要顯示已觀看的檢查標誌。',
			'accountPreferences.watchedIndicatorOptions.moviesAndShowsDescription' => '顯示觀看的電影和電視節目檢查標誌。',
			'accountPreferences.watchedIndicatorOptions.moviesDescription' => '只為電影顯示觀看標籤。',
			'accountPreferences.watchedIndicatorOptions.showsDescription' => '只為電視節目顯示觀看的檢查標誌。',
			'accountPreferences.mediaReviewsVisibility' => '評分與評論',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => '使用者與影評人',
			'accountPreferences.mediaReviewsOptions.usersOnly' => '僅使用者',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => '僅影評人',
			'accountPreferences.mediaReviewsOptions.nobody' => '隱藏',
			'accountPreferences.mediaReviewsOptions.usersAndCriticsDescription' => '顯示使用者評分和批判性評分。',
			'accountPreferences.mediaReviewsOptions.usersOnlyDescription' => '顯示使用者提交的評分和評論。',
			'accountPreferences.mediaReviewsOptions.criticsOnlyDescription' => '顯示批判性評分和評論。',
			'accountPreferences.mediaReviewsOptions.nobodyDescription' => '隱藏評分和評論。',
			'accountPreferences.preferredAudioLanguageDescription' => '在此語言中更喜歡音訊軌道,當伺服器或播放器自動選擇軌道時。',
			'accountPreferences.preferredSubtitleLanguageDescription' => '自動選擇字幕時，優先選擇此語言的字幕軌。',
			'accountPreferences.subtitleAccessibilityDescription' => '自動選擇字幕時，設定聽障字幕（SDH）為優先或必選。',
			'accountPreferences.forcedSubtitleDescription' => '自動選擇字幕時，選擇優先使用強制字幕軌，或是必須使用強制字幕軌。',
			'accountPreferences.watchedIndicatorDescription' => '選擇哪個媒體型別在伺服器介面中獲得觀看的檢查標誌。',
			'accountPreferences.mediaReviewsVisibilityDescription' => '選擇哪個觀眾和批判評分伺服器在媒體頁面上顯示。',
			'accountPreferences.subtitleModeDescription' => '在此伺服器帳戶中自動啟動子標題時選擇。',
			'accountPreferences.hubDescription' => '這些偏好儲存在您的媒體伺服器帳戶上,並可能適用於其他客戶。',
			'discover.title' => '發現',
			'discover.noContentAvailable' => '沒有可用內容',
			'discover.addMediaToLibraries' => '請向您的媒體庫新增一些媒體內容',
			'discover.continueWatching' => '繼續觀看',
			'discover.continueWatchingIn' => ({required Object library}) => '繼續在 ${library} 觀看',
			'discover.nextUp' => '接下來播放',
			'discover.nextUpIn' => ({required Object library}) => '接下來在 ${library} 播放',
			'discover.recentlyAdded' => '最近新增',
			'discover.recentlyAddedIn' => ({required Object library}) => '最近新增至 ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => '${library} 中的最新專輯',
			'discover.recentlyPlayedIn' => ({required Object library}) => '最近在 ${library} 播放',
			'discover.mostPlayedIn' => ({required Object library}) => '在 ${library} 最常播放',
			'discover.playEpisode' => ({required Object season, required Object episode}) => '第 ${season} 季 第 ${episode} 集',
			'discover.overview' => '概述',
			'discover.cast' => '演員陣容',
			'discover.findNext.title' => '發現下一個心頭好',
			'discover.findNext.open' => '發現下一個心頭好',
			'discover.findNext.anyTime' => '不限時間',
			'discover.findNext.timeAvailable' => '你有多少時間？',
			'discover.findNext.filters' => '選出此刻想做的事',
			'discover.findNext.watch' => '觀看',
			'discover.findNext.listen' => '聆聽',
			'discover.findNext.read' => '閱讀',
			'discover.findNext.finishable' => ({required Object duration}) => '${duration}內可完成',
			'discover.findNext.aboutDuration' => ({required Object duration}) => '約${duration}',
			'discover.findNext.nextUnit' => ({required Object duration}) => '下一章 · ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => '共${duration}',
			'discover.findNext.timingVaries' => '所需時間可能有所不同',
			'discover.findNext.notNow' => '暫時略過',
			'discover.findNext.swipeHint' => '朝箭頭方向滑動封面，或使用下方按鈕。',
			'discover.findNext.saved' => '已儲存的推薦',
			'discover.findNext.savedCount' => ({required Object count}) => '已儲存的推薦 · ${count}',
			'discover.findNext.undo' => '復原',
			'discover.findNext.details' => '詳細資訊',
			'discover.findNext.noPicks' => '暫時沒有可選內容',
			'discover.findNext.noPicksHint' => '連接媒體庫或新增媒體來源即可開始。',
			'discover.findNext.noMatches' => '沒有適合此刻的內容',
			'discover.findNext.noMatchesHint' => '試試其他內容類型，或留出更多時間。',
			'discover.findNext.allDone' => '你已瀏覽全部推薦',
			'discover.findNext.allDoneHint' => '換一組推薦，就能再次看到這些選項。',
			'discover.findNext.refresh' => '尋找另一組推薦',
			'discover.findNext.sourceReason' => ({required Object source}) => '來自${source}',
			'discover.findNext.libraryReason' => ({required Object library}) => '來自${library}',
			'discover.findNext.ownedReason' => '來自你的媒體庫',
			'discover.findNext.liveNow' => '正在播出',
			'discover.findNext.watchLive' => '觀看直播',
			'discover.findNext.filterAnything' => '不限類型',
			'discover.findNext.filterWatch' => '觀看',
			'discover.findNext.filterListen' => '聆聽',
			'discover.findNext.filterRead' => '閱讀',
			'discover.findNext.twentyMinutes' => '20分鐘',
			'discover.findNext.fortyFiveMinutes' => '45分鐘',
			'discover.findNext.ninetyMinutes' => '90分鐘',
			'discover.findNext.apply' => '套用',
			'discover.findNext.openFailed' => '此內容已無法使用。重新整理後再次查看。',
			'discover.findNext.changeFailed' => '無法儲存此次變更，請再試一次。',
			'discover.findNext.savedLimit' => '已儲存的推薦清單已滿。請先移除一則推薦，再儲存其他推薦。',
			'discover.findNext.chooseHint' => '開啟作品、儲存以便稍後查看，或略過。',
			'discover.findNext.howItWorks' => '使用方式',
			'discover.findNext.notNowHelp' => '暫時略過這部作品。它仍會保留在媒體庫中。',
			'discover.findNext.saveHelp' => '儲存至此裝置上目前個人檔案的已儲存推薦中。儲存不會下載作品。',
			'discover.findNext.openHelp' => '選取封面查看詳細資訊。使用主要按鈕播放、閱讀或開啟作品。',
			'discover.findNext.controlsHelp' => '鍵盤或遙控器：將焦點移到按鈕，然後按 Enter 或選取鍵。復原可恢復上一次選擇。',
			'discover.findNext.artworkLoading' => '正在載入圖片…',
			'discover.findNext.artworkUnavailable' => '圖片無法使用',
			'discover.findNext.savedFeedback' => '已加入儲存的推薦',
			'discover.findNext.skippedFeedback' => '已暫時略過',
			'discover.findNext.releaseToConfirm' => '放開以確認',
			'discover.findNext.remoteHint' => '封面取得焦點時：← / → 選擇 · 選取鍵查看詳細資訊 · ↑ / ↓ 移動焦點',
			'discover.extras' => '預告片與花絮',
			'discover.studio' => '製作商',
			'discover.rating' => '分級',
			'discover.director' => '導演',
			'discover.directors' => '導演',
			'discover.movie' => '電影',
			'discover.tvShow' => '影集',
			'discover.minutesLeft' => ({required Object minutes}) => '剩餘 ${minutes} 分鐘',
			'discover.moreLikeThis' => '更多類似內容',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '第${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}章', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 部作品', ), 
			'discover.person.born' => '出生',
			'discover.person.died' => '逝世',
			'discover.person.birthplace' => '出生地',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date}（${age} 歲）',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date}（享年 ${age} 歲）',
			'errors.searchFailed' => ({required Object error}) => '搜尋失敗：${error}',
			'errors.searchUnavailable' => '搜尋無法連線至任何媒體伺服器。',
			'errors.connectionTimeout' => ({required Object context}) => '載入 ${context} 時連線逾時',
			'errors.connectionFailed' => '無法連線至媒體伺服器',
			'errors.unableToLoad' => ({required Object context}) => '無法載入 ${context}。請重試。',
			'errors.noClientAvailable' => '沒有可用用戶端',
			'errors.pleaseEnterToken' => '請輸入 Token',
			'errors.invalidToken' => 'Token 無效',
			'errors.failedToVerifyToken' => ({required Object error}) => '無法驗證 Token：${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => '無法切換至 ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => '無法刪除 ${displayName}',
			'errors.failedToRate' => '無法更新評分',
			'errors.reasonTimedOut' => '連線逾時',
			'errors.reasonUnreachable' => '無法連線至媒體伺服器',
			'errors.reasonRefused' => '媒體伺服器拒絕了此要求',
			'errors.reasonNotFound' => '該項目已不在媒體伺服器上',
			'errors.reasonServerError' => '媒體伺服器回報錯誤',
			'errors.reasonCancelled' => '要求已取消',
			'errors.reasonUnexpected' => '發生未預期的錯誤',
			'libraries.playRandomMovie' => '隨機電影播放',
			'libraries.randomPickFailed' => '不能從這本圖書館選擇隨機電影。',
			'libraries.title' => '媒體庫',
			'libraries.fallbackTitle' => '媒體庫',
			'libraries.scanLibraryFiles' => '掃描媒體庫檔案',
			'libraries.scanLibrary' => '掃描媒體庫',
			'libraries.analyze' => '分析',
			'libraries.analyzeLibrary' => '分析媒體庫',
			'libraries.refreshMetadata' => '重新整理中繼資料',
			'libraries.emptyTrash' => '清空垃圾桶',
			'libraries.emptyingTrash' => ({required Object title}) => '正在清空「${title}」的垃圾桶…',
			'libraries.trashEmptied' => ({required Object title}) => '已清空「${title}」的垃圾桶',
			'libraries.failedToEmptyTrash' => ({required Object error}) => '無法清空垃圾桶：${error}',
			'libraries.analyzing' => ({required Object title}) => '正在分析「${title}」…',
			'libraries.analysisStarted' => ({required Object title}) => '已開始分析「${title}」',
			'libraries.failedToAnalyze' => ({required Object error}) => '無法分析媒體庫：${error}',
			'libraries.noLibrariesFound' => '找不到媒體庫',
			'libraries.allLibrariesHidden' => '所有媒體庫都已隱藏',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => '已隱藏的媒體庫（${count}）',
			'libraries.thisLibraryIsEmpty' => '此媒體庫為空',
			'libraries.noItemsMatchFilters' => '沒有符合目前篩選條件的項目',
			'libraries.resetFilters' => '重設篩選條件',
			'libraries.all' => '全部',
			'libraries.clearAll' => '全部清除',
			'libraries.scanLibraryConfirm' => ({required Object title}) => '確定要掃描「${title}」嗎？',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => '確定要分析「${title}」嗎？',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => '確定要重新整理「${title}」的中繼資料嗎？',
			'libraries.emptyTrashConfirm' => ({required Object title}) => '確定要清空「${title}」的垃圾桶嗎？',
			'libraries.manageLibraries' => '管理媒體庫',
			'libraries.sort' => '排序',
			'libraries.sortBy' => '排序依據',
			'libraries.filters' => '篩選器',
			'libraries.confirmActionMessage' => '確定要執行此操作嗎？',
			'libraries.showLibrary' => '顯示媒體庫',
			'libraries.hideLibrary' => '隱藏媒體庫',
			'libraries.libraryOptions' => '媒體庫選項',
			'libraries.content' => '媒體庫內容',
			'libraries.selectLibrary' => '選擇媒體庫',
			'libraries.filtersWithCount' => ({required Object count}) => '篩選器（${count}）',
			'libraries.noRecommendations' => '目前沒有推薦',
			'libraries.noCollections' => '此媒體庫中沒有收藏集',
			'libraries.noFoldersFound' => '找不到資料夾',
			'libraries.folders' => '資料夾',
			'libraries.tabs.recommended' => '推薦',
			'libraries.tabs.browse' => '瀏覽',
			'libraries.tabs.collections' => '收藏集',
			'libraries.tabs.playlists' => '播放清單',
			'libraries.groupings.title' => '分組',
			'libraries.groupings.all' => '全部',
			'libraries.groupings.movies' => '電影',
			'libraries.groupings.shows' => '影集',
			'libraries.groupings.seasons' => '季',
			'libraries.groupings.episodes' => '集',
			'libraries.groupings.artists' => '演出者',
			'libraries.groupings.albums' => '專輯',
			'libraries.groupings.tracks' => '曲目',
			'libraries.groupings.folders' => '資料夾',
			'libraries.filterCategories.genre' => '類型',
			'libraries.filterCategories.year' => '年份',
			'libraries.filterCategories.contentRating' => '分級',
			'libraries.filterCategories.tag' => '標籤',
			_ => null,
		} ?? switch (path) {
			'libraries.filterCategories.unwatched' => '未觀看',
			'libraries.filterCategories.unplayed' => '未播放',
			'libraries.filterCategories.favorites' => '我的最愛',
			'libraries.filterCategories.filePath' => '檔案路徑',
			'libraries.sortLabels.title' => '標題',
			'libraries.sortLabels.dateAdded' => '新增日期',
			'libraries.sortLabels.releaseDate' => '發行日期',
			'libraries.sortLabels.rating' => '評分',
			'libraries.sortLabels.communityRating' => '社群評分',
			'libraries.sortLabels.criticRating' => '影評人評分',
			'libraries.sortLabels.userRating' => '使用者評分',
			'libraries.sortLabels.datePlayed' => '播放日期',
			'libraries.sortLabels.playCount' => '播放次數',
			'libraries.sortLabels.productionYear' => '製作年份',
			'libraries.sortLabels.runtime' => '片長',
			'libraries.sortLabels.officialRating' => '官方分級',
			'libraries.sortLabels.premiereDate' => '首映日期',
			'libraries.sortLabels.startDate' => '開始日期',
			'libraries.sortLabels.airTime' => '播出時間',
			'libraries.sortLabels.studio' => '工作室',
			'libraries.sortLabels.random' => '隨機',
			'libraries.sortLabels.dateShared' => '分享日期',
			'libraries.sortLabels.latestEpisodeAirDate' => '最新一集播出日期',
			'libraries.sortLabels.lastEpisodeDateAdded' => '最新一集新增日期',
			'libraries.sortLabels.dateDownloaded' => '下載日期',
			'libraries.sortLabels.size' => '大小',
			'libraries.sortLabels.library' => '媒體庫',
			'libraries.advancedFilters.include' => '包含',
			'libraries.advancedFilters.exclude' => '排除',
			'libraries.advancedFilters.any' => '不限',
			'libraries.advancedFilters.yes' => '是',
			'libraries.advancedFilters.no' => '否',
			'libraries.advancedFilters.not' => ({required Object value}) => '非 ${value}',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '已選取 ${count} 個',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '已排除 ${count} 個',
			'libraries.advancedFilters.searchValues' => '搜尋選項',
			'libraries.advancedFilters.noValues' => '沒有選項',
			'libraries.advancedFilters.matchContains' => '包含',
			'libraries.advancedFilters.matchNotContains' => '不包含',
			'libraries.advancedFilters.matchIs' => '是',
			'libraries.advancedFilters.matchIsNot' => '不是',
			'libraries.advancedFilters.matchBeginsWith' => '開頭為',
			'libraries.advancedFilters.matchEndsWith' => '結尾為',
			'libraries.advancedFilters.textHint' => '輸入要比對的文字',
			'libraries.advancedFilters.from' => '從',
			'libraries.advancedFilters.to' => '至',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from} 至 ${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value} 以上',
			'libraries.advancedFilters.atMost' => ({required Object value}) => '${value} 以下',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => '過去 ${count} 天',
			'libraries.advancedFilters.dateLastYear' => '過去一年',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => '超過 ${count} 天前',
			'libraries.advancedFilters.dateOlderThanYear' => '超過一年前',
			'libraries.selection.selectItems' => '選擇專案',
			'libraries.selection.selectedCount' => ({required Object count}) => '已選取 ${count} 個',
			'libraries.selection.actions' => '選擇行動',
			'libraries.selection.confirmDescendants' => '這一變化改變了所有節目和季節的節目。',
			'libraries.selection.confirmUnwatched' => '這也會清除所選項目的播放進度。',
			'libraries.selection.confirmCount' => ({required Object count}) => '已選擇的專案: ${count}。',
			'libraries.selection.completed' => ({required Object count}) => '更新專案: ${count}',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => '更新 ${succeeded}; 失敗 ${failed}. 失敗的專案仍然被選擇。',
			'about.title' => '關於',
			'about.openSourceLicenses' => '開源授權條款',
			'about.versionLabel' => ({required Object version}) => '版本 ${version}',
			'about.appDescription' => '一款精美的 Plex、Jellyfin 與 Emby Flutter 用戶端',
			'about.viewLicensesDescription' => '查看第三方套件的授權條款',
			'about.privacyPolicy' => '隱私權政策',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => '找不到 ${username}（${email}） 的伺服器',
			'serverSelection.failedToLoadServers' => ({required Object error}) => '無法載入伺服器：${error}',
			'serverSelection.noValidServers' => '此帳號中找不到可用的伺服器',
			'hubDetail.title' => '標題',
			'hubDetail.releaseYear' => '發行年份',
			'hubDetail.dateAdded' => '新增日期',
			'hubDetail.rating' => '評分',
			'hubDetail.noItemsFound' => '找不到項目',
			'logs.clearLogs' => '清除日誌',
			'logs.copyLogs' => '複製日誌',
			'logs.uploadLogs' => '上傳日誌',
			'logs.saveLogs' => '儲存存檔',
			'logs.logsSaved' => ({required Object path}) => '儲存到 ${path} 的存檔',
			'logs.saveLogsFailed' => '無法儲存存檔。',
			'startup.failedTitle' => 'PlezyNG 無法啟動',
			'startup.failedBody' => '啟動期間發生問題。下方詳細資料可識別失敗的原因。',
			'startup.failedBodyRepairable' => 'PlezyNG 儲存的設定檔已損壞，必須先重建才能啟動。重試無法解決問題 — 請選擇「修復儲存空間」。',
			'startup.phaseLabel' => '步驟',
			'startup.showDetails' => '顯示詳細資料',
			'startup.hideDetails' => '隱藏詳細資料',
			'startup.copyDetails' => '複製詳細資料',
			'startup.detailsCopied' => '詳細資料已複製到剪貼簿',
			'startup.uploadDetails' => '上傳詳細資料',
			'startup.repairStorage' => '修復儲存空間',
			'startup.repairTitle' => '修復已儲存的資料？',
			'startup.repairBodyCommon' => 'PlezyNG 的設定檔已損壞且無法讀取。修復會將所有設定重設為預設值。',
			'startup.repairBodyOneCredential' => '有一筆已儲存的登入資訊損壞且無法讀取。修復僅會移除該筆資訊，其他設定將保持不變。',
			'startup.repairBodySignInsKept' => '您的伺服器與使用者設定檔應可保持登入狀態。',
			'startup.repairBodySignInsLost' => '保護已儲存登入資訊的金鑰無法從此檔案中復原，因此您必須重新登入每個伺服器與使用者設定檔。您媒體伺服器上的內容不受影響。',
			'startup.repairBodySessionsUncertain' => '追蹤服務（MAL、AniList、Simkl、Trakt）與 Seerr 分別儲存，可能保留也可能遺失。PlezyNG 會明確告知保留了哪些項目。',
			'startup.repairConfirm' => '修復',
			'startup.repairSucceeded' => '儲存空間已修復',
			'startup.repairNeedsRestart' => '儲存空間已修復 — 需要重新啟動',
			'startup.restartRequiredBody' => '您的資料已修復，但 PlezyNG 必須重新啟動才能使用。請關閉 PlezyNG 後重新開啟。',
			'startup.quitPlezy' => '退出 PlezyNG',
			'startup.repairFailed' => '修復失敗',
			'startup.repairKeptSignIns' => '您的伺服器與使用者設定檔仍保持登入狀態。',
			'startup.repairLostSignIns' => '保護已儲存登入資訊的金鑰無法復原。您必須重新登入每個伺服器與使用者設定檔。',
			'startup.repairLostSessions' => '至少一個追蹤服務或 Seerr 連線已遺失，必須重新連線。',
			'startup.backupTitle' => '已保留損壞檔案的副本',
			'startup.backupWarning' => '其中包含您的登入憑證。請勿上傳或分享。',
			'startup.deleteBackup' => '刪除副本',
			'startup.backupDeleted' => '副本已刪除。',
			'startup.previousFailureTitle' => 'PlezyNG 上次啟動失敗',
			'licenses.relatedPackages' => '相關套件',
			'licenses.license' => '授權',
			'licenses.licenseNumber' => ({required Object number}) => '授權條款 ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} 個授權條款',
			'navigation.libraries' => '媒體庫',
			'navigation.downloads' => '下載',
			'navigation.liveTv' => '直播電視',
			'navigation.explore' => '探索',
			'explore.mdblistShelves.manage' => '管理 探索 地板',
			'explore.mdblistShelves.manageDescription' => '從您的帳戶中選擇和安排列表 MDBList',
			'explore.mdblistShelves.description' => '從您的 MDBList 帳戶中選擇公開電影和電視列表. 建立或複製列表在 MDBList 然後更新。',
			'explore.mdblistShelves.selected' => '選擇的板塊',
			'explore.mdblistShelves.available' => '可用的賬戶列表',
			'explore.mdblistShelves.noLists' => '沒有公開的電影或電視列表返回. 建立或複製列表在 MDBList,然後更新。',
			'explore.mdblistShelves.displayName' => '沙爾夫 顯示名稱',
			'explore.mdblistShelves.nameHint' => '請點選使用源名單名稱。',
			'explore.mdblistShelves.add' => '新增Shelf',
			'explore.mdblistShelves.save' => '儲存沙地',
			'explore.mdblistShelves.moveUp' => ({required Object title}) => '移動 ${title} 升',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => '移動 ${title} 下載',
			'explore.mdblistShelves.unavailable' => '此列表不可用 退出或在設定中刪除其架子。',
			'explore.mdblistShelves.rateLimited' => '第MDBList號請求限制已達到,請隨後退出。',
			'explore.mdblistShelves.loadFailed' => '不能充電板,檢查你的連線和退出。',
			'explore.mdblistShelves.saveFailed' => '沒辦法放下,請放下。',
			'explore.mdblistShelves.accountChanged' => '帳戶或個人資料已更改 重新開啟這些設定。',
			'explore.mdblistShelves.settingsUnreadable' => '儲存的欄位無法閱讀. 重新選擇列表以取代這些設定。',
			'explore.title' => '探索',
			'explore.selectSource' => '選擇來源',
			'explore.rows.watchlist' => '待看清單',
			'explore.rows.recommendedMovies' => '推薦電影',
			'explore.rows.recommendedShows' => '推薦影集',
			'explore.rows.trendingMovies' => '近期熱門電影',
			'explore.rows.trendingShows' => '近期熱門影集',
			'explore.rows.popularMovies' => '熱門電影',
			'explore.rows.popularShows' => '熱門影集',
			'explore.rows.trendingAnime' => '近期熱門動畫',
			'explore.rows.suggestedAnime' => '推薦動畫',
			'explore.rows.airingAnime' => '熱門連載動畫',
			'explore.rows.popularAnime' => '最受歡迎的動畫',
			'explore.rows.trending' => '趨勢',
			'explore.rows.upcomingMovies' => '即將上映的電影',
			'explore.rows.upcomingShows' => '即將播出的影集',
			'explore.status.airing' => '播出中',
			'explore.status.ended' => '已完結',
			'explore.status.canceled' => '已取消',
			'explore.status.upcoming' => '即將上線',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 集', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 集', ), 
			'explore.cast' => '演員陣容',
			'explore.characters' => '角色',
			'explore.addToWatchlist' => '新增至待看清單',
			'explore.removeFromWatchlist' => '從待看清單移除',
			'explore.addedToWatchlist' => '已加入待看清單',
			'explore.removedFromWatchlist' => '已從待看清單移除',
			'explore.watchlistUpdateFailed' => '無法更新待看清單',
			'explore.watchlistNoMatch' => '無法將此項目與待看清單配對',
			'explore.notInLibrary' => '不在您的媒體庫中',
			'explore.inTheseLibraries' => '在這些媒體庫中',
			'explore.checkingLibrary' => '正在檢查您的媒體庫…',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '無法檢視 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 伺服器', other: '無法檢查 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 台伺服器', ), 
			'explore.emptyTitle' => '這裡還沒有任何內容',
			'explore.emptyMessage' => ({required Object source}) => '當 ${source} 有內容時，相關資訊將顯示在此處。',
			'explore.searchHint' => ({required Object source}) => '搜尋 ${source}',
			'explore.searchEmpty' => ({required Object query}) => '沒有「${query}」的結果',
			'explore.searchPrompt' => ({required Object source}) => '在 ${source} 搜尋電影與影集。',
			'explore.searchFailed' => '搜尋失敗。請檢查網路連線後重試。',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} 熱門',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} 播出中',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} 高分',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} 趨勢',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} · ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} 觀看中',
			'explore.badge.available' => '可觀看',
			'explore.badge.partiallyAvailable' => '部分可觀看',
			'explore.badge.availableIn4k' => '4K 可觀看',
			'explore.badge.requested' => '已提出請求',
			'explore.badge.pendingApproval' => '等待核准',
			'explore.badge.processing' => '處理中',
			'explore.badge.declined' => '已拒絕',
			'explore.badge.requestFailed' => '請求失敗',
			'explore.badge.requested4k' => '已請求 4K',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} 季',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => '第 ${episode} 集 ${duration} 後播出',
			'explore.badge.nextAiringIn' => ({required Object duration}) => '${duration} 後播出',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} 集',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '每集 ${n} 分鐘',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} 人已收錄',
			'explore.stats.viewersDay' => ({required Object n}) => '今日 ${n} 人觀看',
			'explore.stats.viewersWeek' => ({required Object n}) => '本週 ${n} 人觀看',
			'explore.stats.viewersMonth' => ({required Object n}) => '本月 ${n} 人觀看',
			'explore.stats.viewersYear' => ({required Object n}) => '今年 ${n} 人觀看',
			'explore.stats.viewersAllTime' => ({required Object n}) => '累計 ${n} 人觀看',
			'explore.stats.planning' => ({required Object n}) => '${n} 人打算觀看',
			'explore.stats.favorited' => ({required Object n}) => '${n} 人收藏',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} 的人棄番',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 評論', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 則留言', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} 票',
			'explore.stats.watching' => ({required Object n}) => '${n} 人正在觀看',
			'explore.stats.completed' => ({required Object n}) => '${n} 人已看完',
			'explore.stats.onHold' => ({required Object n}) => '${n} 人擱置中',
			'explore.stats.dropped' => ({required Object n}) => '${n} 人棄番',
			'explore.season.winter' => '冬季',
			'explore.season.spring' => '春季',
			'explore.season.summer' => '夏季',
			'explore.season.fall' => '秋季',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year} 年',
			'explore.format.tv' => 'TV',
			'explore.format.tvShort' => 'TV 短片',
			'explore.format.movie' => '電影',
			'explore.format.special' => '特別篇',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => '音樂',
			'explore.format.other' => '其他',
			'explore.sourceMaterial.original' => '原創',
			'explore.sourceMaterial.manga' => '漫畫',
			'explore.sourceMaterial.lightNovel' => '輕小說',
			'explore.sourceMaterial.novel' => '小說',
			'explore.sourceMaterial.visualNovel' => '視覺小說',
			'explore.sourceMaterial.game' => '遊戲',
			'explore.sourceMaterial.webComic' => '網路漫畫',
			'explore.sourceMaterial.musicRelease' => '音樂',
			'explore.sourceMaterial.otherMedia' => '其他',
			'explore.creditRole.actor' => '演員',
			'explore.creditRole.director' => '導演',
			'explore.creditRole.writer' => '編劇',
			'explore.creditRole.producer' => '製作人',
			'explore.creditRole.creator' => '原作者',
			'explore.creditRole.composer' => '作曲家',
			'explore.relation.prequel' => '前傳',
			'explore.relation.sequel' => '續集',
			'explore.relation.sideStory' => '外傳',
			'explore.relation.spinOff' => '衍生作品',
			'explore.relation.alternativeVersion' => '其他版本',
			'explore.relation.summary' => '總集篇',
			'explore.relation.parentStory' => '原作',
			'explore.relation.adaptation' => '改編',
			'explore.relation.other' => '相關',
			'explore.broadcast' => ({required Object day, required Object time}) => '${day} ${time} 播出',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => '${day} ${time} ${timezone} 播出',
			'explore.detail.originalTitle' => '原始標題',
			'explore.detail.alsoKnownAs' => '又名',
			'explore.detail.studios' => '製作公司',
			'explore.detail.country' => '國家',
			'explore.detail.language' => '語言',
			'explore.detail.released' => '發行日期',
			'explore.detail.physicalRelease' => '光碟發行',
			'explore.detail.ended' => '已完結',
			'explore.detail.addedOn' => ({required Object date}) => '新增於 ${date}',
			'explore.detail.yourRating' => '您的評分',
			'explore.detail.budget' => '預算',
			'explore.detail.revenue' => '票房',
			'explore.detail.contentAdvisory' => '年齡分級',
			'explore.detail.tags' => '標籤',
			'explore.detail.revealSpoilerTags' => '顯示劇透標籤',
			'explore.detail.links' => '連結',
			'explore.detail.watchOn' => '觀看平台',
			'explore.detail.watchTrailer' => '觀看預告片',
			'explore.detail.openOn' => ({required Object site}) => '在 ${site} 開啟',
			'explore.detail.crew' => '幕後團隊',
			'explore.detail.ratings' => '評分',
			'explore.detail.schedule' => '播出時間',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '由 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 使用者推薦', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 位使用者推薦', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => '由 ${who} 推薦',
			'explore.detail.favoritedBy' => ({required Object who}) => '由 ${who} 收藏',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '尚有 ${n} 集未播出',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => '${percent} 的觀眾推薦',
			'explore.detail.relatedTitles' => '相關作品',
			'explore.detail.background' => '背景介紹',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 結果', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 筆結果', ), 
			'liveTv.title' => '直播電視',
			'liveTv.guide' => '節目表指南',
			'liveTv.noChannels' => '沒有可用的頻道',
			'liveTv.noDvr' => '沒有伺服器設定 DVR 錄影機',
			'liveTv.serverUnavailable' => '直播電視伺服器無法使用。',
			'liveTv.serverNotConnected' => '直播電視伺服器未連線。',
			'liveTv.noPrograms' => '沒有可用的節目資料',
			'liveTv.liveStreamFailed' => '即時串流失敗',
			'liveTv.unknownProgram' => '未知節目',
			'liveTv.timelineLiveProgram' => '直播程式(播放可能不在此程式)',
			'liveTv.timelineBuffer' => '布菲爾時間表',
			'liveTv.timelineUnavailable' => '時間不可用',
			'liveTv.timelineEstimated' => '值得一提的Playback',
			'liveTv.timelinePending' => '求求求',
			'liveTv.timelineStale' => '時間表可能過時',
			'liveTv.unknownHub' => '未知',
			'liveTv.unknownError' => '未知錯誤',
			'liveTv.channelNumber' => ({required Object number}) => '頻道 ${number}',
			'liveTv.unknownChannel' => '未知頻道',
			'liveTv.live' => '直播',
			'liveTv.premiereBadge' => '新',
			'liveTv.reloadGuide' => '重新載入節目表指南',
			'liveTv.searchGuide' => '搜尋節目表',
			'liveTv.searchHint' => '搜尋頻道和節目',
			'liveTv.searchNoResults' => ({required Object query}) => '沒有符合「${query}」的結果',
			'liveTv.channelsSection' => '頻道',
			'liveTv.programsSection' => '節目',
			'liveTv.now' => '現在',
			'liveTv.today' => '今天',
			'liveTv.tomorrow' => '明天',
			'liveTv.midnight' => '午夜',
			'liveTv.overnight' => '凌晨',
			'liveTv.morning' => '上午',
			'liveTv.daytime' => '白天',
			'liveTv.evening' => '晚上',
			'liveTv.lateNight' => '深夜',
			'liveTv.whatsOn' => '正在播出',
			'liveTv.watchChannel' => '觀看頻道',
			'liveTv.favorites' => '最愛',
			'liveTv.reorderFavorites' => '重新排序最愛頻道',
			'liveTv.noFavoriteChannels' => '沒有最愛頻道',
			'liveTv.noFavoriteChannelsHint' => '顯示所有頻道，然後長按頻道即可將其加入最愛。',
			'liveTv.showAllChannels' => '顯示所有頻道',
			'liveTv.favoritesLoadFailed' => '無法載入最愛頻道。請檢查網路連線後重試。',
			'liveTv.favoritesUpdateFailed' => '無法更新最愛頻道。請檢查網路連線後重試。',
			'liveTv.joinSession' => '加入進行中的「一起看」',
			'liveTv.watchFromStart' => ({required Object minutes}) => '從頭觀看（自 ${minutes} 分鐘前開始）',
			'liveTv.watchLive' => '觀看直播',
			'liveTv.goToLive' => '跳至直播點',
			'liveTv.record' => '錄製',
			'liveTv.recordEpisode' => '錄製單集',
			'liveTv.recordSeries' => '錄製整部影集',
			'liveTv.recordOptions' => '錄製選項',
			'liveTv.saveTo' => '儲存至',
			'liveTv.recordings' => '已錄製內容',
			'liveTv.scheduledRecordings' => '已排程錄製',
			'liveTv.recordingRules' => '錄製規則',
			'liveTv.noScheduledRecordings' => '沒有排程的錄製任務',
			'liveTv.manageRecording' => '管理錄製',
			'liveTv.cancelRecording' => '取消錄製',
			'liveTv.cancelRecordingTitle' => '取消此次錄製？',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '將不再錄製 ${title}。',
			'liveTv.deleteRule' => '刪除規則',
			'liveTv.deleteRuleTitle' => '刪除錄製規則？',
			'liveTv.deleteRuleMessage' => ({required Object title}) => '將不再錄製 ${title} 的後續單集。',
			'liveTv.recordingScheduled' => '錄製已排程',
			'liveTv.alreadyScheduled' => '此節目已安排排程錄製',
			'liveTv.dvrAdminRequired' => 'DVR 設定需要管理員帳戶',
			'liveTv.recordingFailed' => '無法安排錄製任務',
			'liveTv.recordingTargetMissing' => '無法確定錄製媒體庫',
			'liveTv.recordNotAvailable' => '此節目無法錄製',
			'liveTv.recordingCancelled' => '錄製已取消',
			'liveTv.recordingRuleDeleted' => '錄製規則已刪除',
			'liveTv.processRecordingRules' => '重新評估規則',
			'liveTv.recordingInProgress' => '正在錄製',
			'liveTv.recordingsCount' => ({required Object count}) => '已排程 ${count} 個',
			'liveTv.editRule' => '編輯規則',
			'liveTv.editRuleAction' => '編輯',
			'liveTv.recordingRuleUpdated' => '錄製規則已更新',
			'liveTv.guideReloadRequested' => '已要求更新節目表指南',
			'liveTv.guideReloadFailed' => '無法重新載入節目表指南',
			'liveTv.rulesProcessRequested' => '已要求重新評估規則',
			'liveTv.rulesProcessFailed' => '無法重新評估錄影規則',
			'liveTv.recordShow' => '錄製節目',
			'liveTv.recordSettings.startEarly' => '提早開始（秒）',
			'liveTv.recordSettings.endLate' => '延後結束（秒）',
			'liveTv.recordSettings.newOnly' => '僅新劇集',
			'liveTv.recordSettings.anyChannel' => '在任何頻道錄影',
			'liveTv.recordSettings.anyTime' => '在任何時間錄影',
			'liveTv.recordSettings.skipInLibrary' => '略過媒體庫中已有的劇集',
			'liveTv.recordSettings.keepUpTo' => '要保留的劇集數',
			'liveTv.recordSettings.keepUpToHint' => '0 表示保留所有劇集',
			'liveTv.startingInMinutes' => ({required Object minutes}) => '${minutes} 分鐘後開始',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product} 傳回了無效的直播電視播放資料',
			'liveTv.failedToStartChannel' => '無法啟動直播頻道',
			'liveTv.failedToBuildStreamUrl' => '無法建立串流 URL',
			'liveTv.playbackStartFailed' => ({required Object reason}) => '無法開始播放此頻道：${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => '無法切換頻道：${reason}',
			'collections.title' => '收藏集',
			'collections.collection' => '收藏集',
			'collections.empty' => '收藏集為空',
			'collections.deleteCollection' => '刪除收藏集',
			'collections.deleteConfirm' => ({required Object title}) => '確定要刪除「${title}」嗎？此操作無法復原。',
			'collections.deleted' => '已刪除收藏集',
			'collections.deleteFailed' => '刪除收藏集失敗',
			'collections.deleteFailedWithError' => ({required Object error}) => '刪除收藏集失敗：${error}',
			'collections.selectCollection' => '選擇收藏集',
			'collections.collectionName' => '收藏集名稱',
			'collections.enterCollectionName' => '輸入收藏集名稱',
			'collections.addedToCollection' => '已新增至收藏集',
			'collections.errorAddingToCollection' => '新增至收藏集失敗',
			'collections.created' => '已建立收藏集',
			'collections.removeFromCollection' => '從收藏集移除',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => '將「${title}」從此收藏集移除？',
			'collections.removedFromCollection' => '已從收藏集移除',
			'collections.removeFromCollectionFailed' => '從收藏集移除失敗',
			'collections.removeFromCollectionError' => ({required Object error}) => '從收藏集移除時發生錯誤：${error}',
			'collections.searchCollections' => '搜尋收藏集…',
			'playlists.title' => '播放清單',
			'playlists.playlist' => '播放清單',
			'playlists.noPlaylists' => '找不到播放清單',
			'playlists.create' => '建立播放清單',
			'playlists.playlistName' => '播放清單名稱',
			'playlists.enterPlaylistName' => '輸入播放清單名稱',
			'playlists.delete' => '刪除播放清單',
			'playlists.removeItem' => '從播放清單中移除',
			'playlists.smartPlaylist' => '智慧播放清單',
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(count, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)}個項目', ), 
			'playlists.emptyPlaylist' => '此播放清單為空',
			'playlists.deleteConfirm' => '刪除播放清單？',
			'playlists.deleteMessage' => ({required Object name}) => '確定要刪除「${name}」嗎？',
			'playlists.created' => '播放清單已建立',
			'playlists.deleted' => '播放清單已刪除',
			'playlists.itemAdded' => '已新增至播放清單',
			'playlists.itemRemoved' => '已從播放清單移除',
			'playlists.selectPlaylist' => '選擇播放清單',
			'playlists.searchPlaylists' => '搜尋播放清單…',
			'playlists.errorCreating' => '建立播放清單失敗',
			'playlists.errorDeleting' => '刪除播放清單失敗',
			'playlists.errorLoading' => '載入播放清單失敗',
			'playlists.errorAdding' => '新增至播放清單失敗',
			'playlists.errorReordering' => '重新排序播放清單項目失敗',
			'playlists.errorRemoving' => '從播放清單移除失敗',
			'music.goToAlbum' => '前往專輯',
			'music.goToArtist' => '前往演出者',
			'music.instantMix' => '即時混音',
			'music.playNext' => '下一首播放',
			'music.addToQueue' => '新增至佇列',
			'music.discNumber' => ({required Object n}) => 'CD ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 路徑', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 首', ), 
			'music.nowPlaying' => '正在播放',
			'music.playingFrom' => ({required Object title}) => '來自 ${title}',
			'music.queue' => '播放佇列',
			'music.clearQueue' => '清空佇列',
			'music.lyrics' => '歌詞',
			'music.visualizer' => '視覺化',
			'music.visualizerProfileLoading' => '閱讀路徑分析',
			'music.visualizerAmbientMotion' => '環境動作',
			'music.visualizerPlexLoudness' => 'Plex 噪音',
			'music.visualizerPreviousPreset' => '以前的視覺風格',
			'music.visualizerNextPreset' => '下一篇 視覺風格',
			'music.visualizerPresetAurora' => '奧拉',
			'music.visualizerPresetBloom' => '藍色',
			'music.visualizerPresetOrbitals' => '軌道',
			'music.visualizerPresetPrism' => '普里斯',
			'music.visualizerPresetTunnel' => '隧道',
			'music.visualizerPresetTrackMap' => '跟蹤地圖',
			'music.noLyrics' => '目前沒有歌詞',
			'music.sleepTimer' => '睡眠計時器',
			'music.sleepTimerEndOfTrack' => '曲目結束時',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 分鐘', ), 
			'music.stopPlayback' => '停止播放',
			'music.previousTrack' => '上一首',
			'music.nextTrack' => '下一首',
			'music.repeat' => '重複播放',
			'music.repeatAll' => '全部重複播放',
			'music.repeatOne' => '單曲重複播放',
			'music.instantMixNoServer' => '沒有可用於即時混音的伺服器',
			'music.instantMixFailed' => '無法載入即時混音',
			'music.instantMixEmpty' => '即時混音沒有產生任何曲目',
			'music.noAudioUrl' => ({required Object track}) => '${track} 沒有可用的音訊 URL',
			'music.discography.singlesAndEps' => '單曲與 EP',
			'music.discography.live' => '現場',
			'music.discography.compilations' => '合輯',
			'watchTogether.title' => '一起看',
			'watchTogether.description' => '與親友同步觀看內容',
			'watchTogether.createRoom' => '建立房間',
			'watchTogether.creatingRoom' => '正在建立房間…',
			'watchTogether.joinRoom' => '加入房間',
			'watchTogether.joiningRoom' => '正在加入房間…',
			'watchTogether.connecting' => '正在連線…',
			'watchTogether.relayPublic' => '房間使用公開的 Open Watch Party 中繼伺服器。',
			'watchTogether.relayCustom' => ({required Object url}) => '房間使用您位於 ${url} 的中繼伺服器。',
			'watchTogether.recentRooms' => '最近的房間',
			'watchTogether.roomActions' => '房間操作',
			'watchTogether.renameRoom' => '重新命名房間',
			'watchTogether.removeRoom' => '移除',
			'watchTogether.enterRoomCode' => '請輸入主持人提供的 6 字元代碼。',
			'watchTogether.roomCode' => '房間代碼',
			'watchTogether.paste' => '貼上',
			'watchTogether.noCodeInClipboard' => '剪貼簿中沒有房間代碼',
			'watchTogether.copyCode' => '複製代碼',
			'watchTogether.codeCopied' => '房間代碼已複製',
			'watchTogether.shareInvite' => '分享邀請',
			'watchTogether.inviteCopied' => '已複製邀請。請將其貼到訊息中。',
			'watchTogether.inviteMessage' => ({required Object code}) => '來 PlezyNG 加入我的「一起看」房間：開啟「一起看」，選擇「加入房間」，然後輸入 ${code}。',
			'watchTogether.openSessionControls' => '開啟「一起看」工作階段控制面板',
			'watchTogether.reconnecting' => '正在重新連線…',
			'watchTogether.reconnectingDescription' => '連線已中斷。您將自動重新加入房間。',
			'watchTogether.connected' => '已連線',
			'watchTogether.disconnected' => '已中斷連線',
			'watchTogether.youAreHost' => '您是主持人',
			'watchTogether.hostedBy' => ({required Object name}) => '主持人：${name}',
			'watchTogether.hostControlsPlayback' => '主持人控制播放',
			'watchTogether.anyoneCanControl' => '任何人都能控制播放',
			'watchTogether.roomLocked' => '房間已鎖定',
			'watchTogether.nowPlaying' => '正在播放',
			'watchTogether.nothingPlaying' => '目前沒有播放內容',
			'watchTogether.nothingPlayingHost' => '從任一媒體庫播放內容，即可與房間成員分享。',
			'watchTogether.nothingPlayingGuest' => '主持人播放內容時，會在這裡開啟。',
			'watchTogether.notShareable' => '這部影片在目錄中沒有相符項目，因此只有可存取同一台伺服器的人才能播放。',
			'watchTogether.searching' => '正在您的媒體庫中尋找這部影片…',
			'watchTogether.yourCopy' => '您的副本',
			'watchTogether.sharingYourCopy' => '您正在分享您的副本',
			'watchTogether.playingOtherLength' => ({required Object difference}) => '正在播放您的副本，${difference}',
			'watchTogether.mismatchTitle' => '您的副本長度不同',
			'watchTogether.mismatchDescription' => ({required Object difference}) => '您最接近的副本比房間的影片${difference}。可能是不同的剪輯版或版本。',
			'watchTogether.playAnyway' => '仍要播放',
			'watchTogether.chooseAnotherCopy' => '選擇其他副本',
			'watchTogether.dontPlay' => '不要播放',
			_ => null,
		} ?? switch (path) {
			'watchTogether.unavailableTitle' => '您沒有這部影片',
			'watchTogether.unavailableDescription' => 'PlezyNG 無法在您的媒體庫中找到這部影片。請自行選擇副本，或重新搜尋。',
			'watchTogether.chooseCopy' => '選擇副本',
			'watchTogether.searchAgain' => '重新搜尋',
			'watchTogether.noCandidates' => '在您的媒體庫中找不到任何副本。',
			'watchTogether.choiceFailed' => '無法為房間播放此副本',
			'watchTogether.lengthLonger' => ({required Object duration}) => '長了 ${duration}',
			'watchTogether.lengthShorter' => ({required Object duration}) => '短了 ${duration}',
			'watchTogether.lengthSame' => '長度相同',
			'watchTogether.lengthUnknown' => '長度未知',
			'watchTogether.joinCurrentPlayback' => '加入目前播放點',
			'watchTogether.joinCurrentPlaybackDescription' => '同步至主持人目前的觀看進度',
			'watchTogether.stopMedia' => '為所有人停止影片',
			'watchTogether.syncOffset' => '同步偏移',
			'watchTogether.syncOffsetDescription' => '若您的影片比房間超前或落後，可在此調整。',
			'watchTogether.offsetHint' => ({required Object difference}) => '您的副本比房間的影片${difference}。',
			'watchTogether.applyDifference' => ({required Object offset}) => '套用 ${offset}',
			'watchTogether.offsetMinusSecond' => '-1 秒',
			'watchTogether.offsetMinusTenth' => '-100 毫秒',
			'watchTogether.offsetPlusTenth' => '+100 毫秒',
			'watchTogether.offsetPlusSecond' => '+1 秒',
			'watchTogether.participants' => '參與者',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 參與者', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 位參與者', ), 
			'watchTogether.hostBadge' => '主持人',
			'watchTogether.nameYou' => ({required Object name}) => '${name}（您）',
			'watchTogether.playerIdle' => '閒置',
			'watchTogether.playerLoading' => '載入中',
			'watchTogether.playerReady' => '就緒',
			'watchTogether.playerBuffering' => '緩衝中',
			'watchTogether.matchSearching' => '搜尋中',
			'watchTogether.matchMatched' => '有此影片',
			'watchTogether.matchMismatched' => '長度不同',
			'watchTogether.matchUnavailable' => '沒有此影片',
			'watchTogether.participantOffset' => ({required Object offset}) => '偏移 ${offset}',
			'watchTogether.makeHost' => '設為主持人',
			'watchTogether.makeHostQuestion' => '移交主持人？',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} 將控制播放並主導所有人的工作階段。',
			'watchTogether.transfer' => '移交',
			'watchTogether.removeParticipant' => '從房間移除',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => '要移除 ${name} 嗎？',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} 將離開房間。除非您鎖定房間，否則對方可以使用代碼再次加入。',
			'watchTogether.remove' => '移除',
			'watchTogether.roomSettings' => '房間設定',
			'watchTogether.letEveryoneControl' => '允許所有人控制播放',
			'watchTogether.lockRoom' => '鎖定房間',
			'watchTogether.lockRoomDescription' => '不允許新成員加入',
			'watchTogether.leaveRoom' => '離開房間',
			'watchTogether.leaveRoomQuestion' => '要離開房間嗎？',
			'watchTogether.leaveRoomConfirm' => '您可以使用房間代碼再次加入。',
			'watchTogether.leave' => '離開',
			'watchTogether.endRoom' => '結束房間',
			'watchTogether.endRoomQuestion' => '要結束房間嗎？',
			'watchTogether.endRoomConfirm' => '這會為所有人結束此房間。',
			'watchTogether.end' => '結束',
			'watchTogether.playBlockedTitle' => '播放未開始',
			'watchTogether.playBlockedDescription' => '按下播放，開始與房間成員一起觀看。',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} 按下了播放',
			'watchTogether.notices.playbackStarted' => '已開始播放',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} 暫停了播放',
			'watchTogether.notices.playbackPaused' => '已暫停播放',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} 跳至 ${position}',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => '已跳至 ${position}',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} 將速度設為 ${speed}',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => '速度已設為 ${speed}',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} 開始播放「${title}」',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => '正在播放「${title}」',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} 停止了影片',
			'watchTogether.notices.mediaStopped' => '影片已停止',
			'watchTogether.notices.waitingFor' => ({required Object name}) => '正在等待 ${name}…',
			'watchTogether.notices.waitingForSomeone' => '正在等待其他人跟上…',
			'watchTogether.notices.finished' => '播放完畢',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} 現在是主持人',
			'watchTogether.notices.youAreNowHost' => '您現在是主持人',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} 已加入',
			'watchTogether.notices.left' => ({required Object name}) => '${name} 已離開',
			'watchTogether.notices.controlRefused' => '只有主持人可以控制播放',
			'watchTogether.notices.searchFailed' => '部分伺服器無法搜尋房間的影片',
			'watchTogether.notices.playBlocked' => '按下播放即可開始',
			'watchTogether.notices.shareFailed' => '無法與房間分享此影片',
			'watchTogether.notices.downloadNotShared' => '下載內容所屬的伺服器離線時，無法與房間分享',
			'watchTogether.notices.openFailed' => '無法開啟房間的影片',
			'watchTogether.ended.ended' => '主持人已結束房間',
			'watchTogether.ended.kicked' => '您已被移出房間',
			'watchTogether.ended.expired' => '房間已過期',
			'watchTogether.ended.replaced' => '您已在其他裝置上加入此房間',
			'watchTogether.ended.lost' => '與房間的連線已中斷',
			'watchTogether.errors.invalidCode' => '這不是有效的房間代碼。代碼由 6 個字母與數字組成，不含 0、1、I、L 或 O。',
			'watchTogether.errors.roomNotFound' => '沒有使用此代碼的房間。房間可能已結束。',
			'watchTogether.errors.roomFull' => '該房間已滿。',
			'watchTogether.errors.roomLocked' => '主持人已鎖定該房間。',
			'watchTogether.errors.relayFull' => '「一起看」目前忙碌中。請稍後再試。',
			'watchTogether.errors.unreachable' => '無法連線至「一起看」中繼伺服器。請檢查網路連線。',
			'watchTogether.errors.rateLimited' => '嘗試次數過多。請稍候再試。',
			'watchTogether.errors.clientBlocked' => '此版本的 PlezyNG 無法使用中繼伺服器。請更新應用程式。',
			'watchTogether.errors.forbidden' => '只有主持人可以執行此操作。',
			'watchTogether.errors.notInRoom' => '您不在房間中。',
			'watchTogether.errors.alreadyInRoom' => '您已在房間中。',
			'watchTogether.errors.resumeFailed' => '無法重新加入房間。',
			'watchTogether.errors.unsupported' => '中繼伺服器不支援此操作。',
			'watchTogether.errors.generic' => '發生錯誤。請重試。',
			'watchTogether.untitledEpisode' => ({required Object number}) => '第 ${number} 集',
			'downloads.title' => '下載',
			'downloads.manage' => '管理',
			'downloads.tvShows' => '影集',
			'downloads.movies' => '電影',
			'downloads.music' => '音樂',
			'downloads.tracksQueued' => ({required Object count}) => '已將 ${count} 首曲目加入下載佇列',
			'downloads.noDownloads' => '目前沒有下載內容',
			'downloads.noDownloadsDescription' => '下載的內容將顯示在此處，供您離線觀看',
			'downloads.downloadNow' => '下載',
			'downloads.deleteDownload' => '刪除下載內容',
			'downloads.retryDownload' => '重試下載',
			'downloads.downloadQueued' => '下載已排隊',
			'downloads.downloadResumed' => '下載已繼續',
			'downloads.serverErrorBitrate' => '伺服器錯誤：檔案位元率可能超過遠端位元率限制',
			'downloads.storageFull' => '為保護剩餘儲存空間，下載已停止。請釋出空間或選擇其他下載位置，然後再試一次。',
			'downloads.storageUnavailable' => '無法檢查可用儲存空間，因此下載已停止。請檢查下載位置後再試一次。',
			'downloads.episodesQueued' => ({required Object count}) => '已將 ${count} 集影片加入下載佇列',
			'downloads.downloadDeleted' => '下載內容已刪除',
			'downloads.deleteConfirm' => ({required Object title}) => '確定要從此裝置刪除「${title}」嗎？',
			'downloads.deleteCollectionDownloads' => '刪除下載內容',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => '確定要從此裝置刪除「${title}」中的所有下載內容嗎？',
			'downloads.collectionDownloadsDeleted' => '下載內容已刪除',
			'downloads.cancelledDownloadTitle' => '已取消的下載',
			'downloads.cancelledDownloadMessage' => '此下載已取消。您想要如何處理？',
			'downloads.allEpisodesAlreadyDownloaded' => '所有單集都已下載完成',
			'downloads.resumeDownload' => '繼續下載',
			'downloads.cancelledDownload' => '已取消的下載',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file}（正在同步 ${status}）',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => '已下載 ${file} — 點選以完成',
			'downloads.partialDownloadClickToComplete' => '已部分下載 — 點選以完成',
			'downloads.deleting' => '正在刪除…',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => '正在刪除 ${title}…（${current}/${total}）',
			'downloads.queuedTooltip' => '已排隊',
			'downloads.queuedFilesTooltip' => ({required Object files}) => '已排隊：${files}',
			'downloads.downloadingTooltip' => '正在下載…',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => '正在下載 ${files}',
			'downloads.noDownloadsTree' => '目前沒有下載內容',
			'downloads.pauseAll' => '全部暫停',
			'downloads.resumeAll' => '全部繼續',
			'downloads.retryAll' => '全部重試',
			'downloads.retryFailed' => '重試失敗的下載',
			'downloads.deleteAll' => '全部刪除',
			'downloads.selectVersion' => '選擇版本',
			'downloads.allEpisodes' => '所有單集',
			'downloads.unwatchedOnly' => '僅未觀看',
			'downloads.nextNUnwatched' => ({required Object count}) => '接下來 ${count} 集未觀看',
			'downloads.customAmount' => '自訂數量…',
			'downloads.customAmountAny' => '每個數量(每個數...',
			'downloads.randomEpisodes' => '隨機事件',
			'downloads.includeSpecials' => '包含特別篇',
			'downloads.howManyEpisodes' => '要下載多少集？',
			'downloads.invalidEpisodeCount' => '請輸入有效的集數。',
			'downloads.keepSynced' => '保持同步',
			'downloads.downloadOnce' => '下載一次',
			'downloads.keepNUnwatched' => ({required Object count}) => '保留 ${count} 個未觀看項目',
			'downloads.editSyncRule' => '編輯同步規則',
			'downloads.removeSyncRule' => '刪除同步規則',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => '停止同步「${title}」？已下載的單集將會保留。',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => '停止同步「${title}」？',
			'downloads.deleteSyncRuleDownloads' => '一併刪除相關的下載內容',
			'downloads.deleteSyncRuleDownloadsDescription' => '供其他同步規則或使用者設定檔使用的下載內容將予以保留。',
			'downloads.syncRuleCreated' => ({required Object count}) => '同步規則已建立 — 將保留 ${count} 個未觀看單集',
			'downloads.syncRuleUpdated' => '同步規則已更新',
			'downloads.syncRuleRemoved' => '同步規則已刪除',
			'downloads.syncRuleAndDownloadsRemoved' => '同步規則與相關的下載內容已刪除',
			'downloads.syncRuleCleanupBusy' => '同步規則正在更新中。請稍後再試。',
			'downloads.syncRuleCleanupUnavailable' => '無法安全地識別相關的下載內容。請重新連線伺服器後再試，或在不刪除下載內容的情況下移除規則。',
			'downloads.syncedNewEpisodes' => ({required Object title, required Object count}) => '已為 ${title} 同步 ${count} 個新單集',
			'downloads.syncNow' => '現在的Sync',
			'downloads.downloadsUpToDate' => '下載到目前為止',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => '合成完整 · ${queued} queued, ${removed} 刪除',
			'downloads.activeSyncRules' => '同步規則',
			'downloads.reviewOrphanFiles' => '檢查無對應紀錄的下載',
			'downloads.orphanReviewTitle' => '檢查無對應紀錄的下載',
			'downloads.orphanReviewDescription' => '這些已標記的檔案位於 PlezyNG 預設管理的下載資料夾中，但沒有相符的下載紀錄或進行中的工作。刪除前請先檢查清單。',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count} 個檔案 · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => '刪除 ${count} 個檔案',
			'downloads.orphanCleanupNone' => '找不到無對應紀錄的下載檔案',
			'downloads.orphanCleanupFailed' => 'PlezyNG 無法安全地掃描受管理的下載資料夾。沒有刪除任何檔案。',
			'downloads.orphanCleanupChanged' => '檢查期間下載清單已變更。清理前請重新檢查檔案。',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => '已刪除 ${count} 個無對應紀錄的檔案 · 釋出 ${size}',
			'downloads.noSyncRules' => '沒有同步規則',
			'downloads.manageSyncRule' => '管理同步',
			'downloads.editEpisodeCount' => '單集數量',
			'downloads.editSyncFilter' => '同步篩選器',
			'downloads.syncAllItems' => '同步所有項目',
			'downloads.syncUnwatchedItems' => '同步未觀看項目',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => '伺服器：${server} • ${status}',
			'downloads.syncRuleAvailable' => '可用',
			'downloads.syncRuleOffline' => '離線',
			'downloads.syncRuleSignInRequired' => '需要登入',
			'downloads.syncRuleAccessDenied' => '存取遭拒',
			'downloads.syncRuleNotAvailableForProfile' => '目前使用者設定檔無法使用',
			'downloads.syncRuleUnknownServer' => '未知伺服器',
			'downloads.syncRuleListCreated' => '同步規則已建立',
			'downloads.backgroundWarning.bannerBlocked' => '離開應用程式後，下載將會停止',
			'downloads.backgroundWarning.bannerDegraded' => '背景下載可能受限',
			'downloads.backgroundWarning.bannerAction' => '詳細資料',
			'downloads.backgroundWarning.sheetTitle' => '背景下載遭到封鎖',
			'downloads.backgroundWarning.sheetTitleDegraded' => '背景下載可能受限',
			'downloads.backgroundWarning.sheetIntro' => 'Android 正在阻止 PlezyNG 在背景穩定下載。',
			'downloads.backgroundWarning.sheetIntroDegraded' => '你的裝置限制了 PlezyNG 可在背景下載的時機。',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'PlezyNG 的背景使用受限。請將其電池用量或背景使用設定為「無限制」。',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android 已將 PlezyNG 設為受限待命狀態。請將電池用量設為「無限制」。',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => '下載通知已關閉，因此可能無法查看進度或使用控制項。',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => '通知已關閉。在 Android 13 或更新版本中，長時間背景下載需要啟用通知。',
			'downloads.backgroundWarning.reasonDataSaver' => '已開啟數據節省模式，因此系統會封鎖使用行動數據的背景下載。透過 Wi-Fi 下載應仍可正常執行。',
			'downloads.backgroundWarning.reasonOemUnknown' => 'PlezyNG 在背景執行時，下載屢次停止。請檢查 PlezyNG 的電池用量或背景使用設定。',
			'downloads.backgroundWarning.openSettings' => '開啟設定',
			'downloads.backgroundWarning.stillNotWorking' => '裝置專屬說明',
			'downloads.backgroundWarning.stillNotWorkingDescription' => '查看適用於你裝置的步驟；若問題持續發生，也可從設定 › 查看日誌傳送日誌。',
			'downloads.backgroundWarning.dialogTitle' => '下載可能無法完成',
			'downloads.backgroundWarning.dialogDownloadAnyway' => '仍要下載',
			'downloads.backgroundWarning.dialogFixFirst' => '先修正設定',
			'downloads.backgroundWarning.statusTile' => '背景下載',
			'downloads.backgroundWarning.statusOk' => '可在背景執行',
			'downloads.backgroundWarning.statusBlocked' => '遭系統設定封鎖',
			'downloads.backgroundWarning.statusDegraded' => '受系統設定限制',
			'downloads.backgroundWarning.statusUnknown' => '尚未檢查',
			'downloads.backgroundWarning.settingsUnavailable' => '無法在這部裝置上開啟系統設定',
			'downloads.backgroundWarning.linkUnavailable' => '無法在這部裝置上開啟 dontkillmyapp.com',
			'downloads.options' => '下載選項',
			'downloads.groupings.library' => '媒體庫',
			'downloads.groupings.collections' => '收藏集',
			'downloads.unknownLibrary' => '未知媒體庫',
			'downloads.unknownShow' => '未知節目',
			'downloads.unknownSeason' => '未知季度',
			'downloads.unknownAlbum' => '未知專輯',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '已完成 ${completed}/${total}',
			'downloads.storageUsed' => ({required Object size}) => '使用的儲存: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}個下載', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}個下載', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 展覽', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 顯示', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 電影', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 電影', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}張專輯', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}張專輯', ), 
			'downloads.errorFileNotFound' => '找不到檔案（404）',
			'downloads.errorDownloadNotAllowed' => '伺服器不允許下載（403）',
			'downloads.errorDownloadFailed' => '下載失敗',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => '下載失敗：${reason}',
			'downloads.convertingOnServer' => '轉換到伺服器',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => '轉換到伺服器 · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => '下載失敗（HTTP ${status}）',
			'downloads.errorPostProcessing' => ({required Object reason}) => '後續處理失敗：${reason}',
			'downloads.reasonFileNotSaved' => '無法將檔案儲存到此裝置',
			'downloads.reasonCannotResume' => '無法繼續未完成的下載',
			'downloads.reasonDeviceStorageFull' => '此裝置的儲存空間已滿',
			'downloads.notificationDownloading' => '正在下載…',
			'downloads.notificationComplete' => '下載完成',
			'downloads.notificationPaused' => '下載已暫停',
			'shaders.title' => '著色器',
			'shaders.noShaderDescription' => '無影片增強效果',
			'shaders.nvscalerDescription' => 'NVIDIA 圖像縮放技術，使影片邊緣更清晰',
			'shaders.artcnnVariantNeutral' => '中性',
			'shaders.artcnnVariantDenoise' => '降噪',
			'shaders.artcnnVariantDenoiseSharpen' => '降噪 + 銳化',
			'shaders.qualityFast' => '快速',
			'shaders.qualityHQ' => '高品質',
			'shaders.mode' => '模式',
			'shaders.importShader' => '匯入著色器',
			'shaders.customShaderDescription' => '自訂 GLSL 著色器檔案',
			'shaders.shaderImported' => '著色器已匯入',
			'shaders.shaderImportFailed' => '匯入著色器失敗',
			'shaders.deleteShader' => '刪除著色器',
			'shaders.deleteShaderConfirm' => ({required Object name}) => '刪除「${name}」？',
			'companionRemote.title' => '隨身遙控器',
			'companionRemote.connectedTo' => ({required Object name}) => '已連線至 ${name}',
			'companionRemote.unknownDevice' => '未知裝置',
			'companionRemote.session.startingServer' => '正在啟動遠端伺服器…',
			'companionRemote.session.hostAddress' => '主機位址',
			'companionRemote.session.connected' => '已連線',
			'companionRemote.session.serverRunning' => '遠端伺服器已啟動',
			'companionRemote.session.serverStopped' => '遠端伺服器已停止',
			'companionRemote.session.serverRunningDescription' => '區域網路中的行動裝置可以連線至此應用程式',
			'companionRemote.session.serverStoppedDescription' => '啟動伺服器以允許行動裝置連線',
			'companionRemote.session.usePhoneToControl' => '使用行動裝置控制此應用程式',
			'companionRemote.session.startServer' => '啟動伺服器',
			'companionRemote.session.stopServer' => '停止伺服器',
			'companionRemote.session.minimize' => '最小化',
			'companionRemote.session.manualAddressHint' => '手動連線位址：',
			'companionRemote.pairing.discoveryDescription' => '使用相同 Plex 帳戶的 PlezyNG 裝置會顯示在此處',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => '正在連線…',
			'companionRemote.pairing.searchingForDevices' => '正在搜尋裝置…',
			'companionRemote.pairing.noDevicesFound' => '在區域網路上找不到裝置',
			'companionRemote.pairing.noDevicesHint' => '請在電腦上開啟 PlezyNG，並確認兩台裝置使用相同的 Wi-Fi 網路',
			'companionRemote.pairing.availableDevices' => '可用裝置',
			'companionRemote.pairing.manualConnection' => '手動連線',
			'companionRemote.pairing.cryptoInitFailed' => '無法啟動安全連線。請先登入 Plex。',
			'companionRemote.pairing.validationHostRequired' => '請輸入主機位址',
			'companionRemote.pairing.validationHostFormat' => '格式必須為 IP 位址:連接埠（例如 192.168.1.100:48632）',
			'companionRemote.pairing.connectionTimedOut' => '連線逾時。請確認兩台裝置都使用相同網路。',
			'companionRemote.pairing.sessionNotFound' => '找不到裝置。請確認主機上已啟動 PlezyNG。',
			'companionRemote.pairing.authFailed' => '驗證失敗。兩台裝置需要登入相同的 Plex 帳戶。',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => '連線失敗：${error}',
			'companionRemote.pairing.codeTitle' => '雙重程式碼',
			'companionRemote.pairing.codeDescription' => '在主機裝置上輸入“遠端伴侶”中顯示的程式碼,兩臺裝置都必須使用支援安全配對的版本。',
			'companionRemote.pairing.codeInvalid' => '輸入所有 32 個字母和號碼的主機程式碼。',
			'companionRemote.pairing.updateRequired' => '將兩臺裝置更新到支援安全配對的版本。',
			'companionRemote.pairing.hostDescription' => '每次輸入此程式碼一次,遠端保持隱私:它提供對此個人資料的控制。',
			'companionRemote.pairing.resetCode' => '重新設定編碼',
			'companionRemote.pairing.resetDescription' => '切斷所有遠端,並建立一個新的程式碼,每個遠端都需要重新連線。',
			'companionRemote.remote.disconnectConfirm' => '是否要中斷遠端連線工作階段？',
			'companionRemote.remote.reconnecting' => '重新連線中…',
			'companionRemote.remote.attemptOf' => ({required Object current}) => '第 ${current} 次嘗試，共 5 次',
			'companionRemote.remote.retryNow' => '立即重試',
			'companionRemote.remote.tabRemote' => '遙控',
			'companionRemote.remote.tabPlay' => '播放',
			'companionRemote.remote.tabMore' => '更多',
			'companionRemote.remote.menu' => '選單',
			'companionRemote.remote.tabNavigation' => '分頁導覽',
			'companionRemote.remote.tabDiscover' => '發現',
			'companionRemote.remote.tabLibraries' => '媒體庫',
			'companionRemote.remote.tabSearch' => '搜尋',
			'companionRemote.remote.tabDownloads' => '下載',
			'companionRemote.remote.tabSettings' => '設定',
			'companionRemote.remote.previous' => '上一個',
			'companionRemote.remote.playPause' => '播放/暫停',
			'companionRemote.remote.next' => '下一個',
			'companionRemote.remote.seekBack' => '後退',
			'companionRemote.remote.stop' => '停止',
			'companionRemote.remote.seekForward' => '前進',
			'companionRemote.remote.volume' => '音量',
			'companionRemote.remote.volumeDown' => '調小',
			'companionRemote.remote.volumeUp' => '調大',
			'companionRemote.remote.fullscreen' => '全螢幕',
			'companionRemote.remote.subtitles' => '字幕',
			'companionRemote.remote.audio' => '音訊',
			'companionRemote.remote.searchHint' => '在電腦版上搜尋…',
			'companionRemote.errors.noNetworkInterface' => '找不到網路介面',
			'companionRemote.errors.authenticationFailed' => '身分驗證失敗',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => '無法啟動遠端伺服器：${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => '無法傳送遠端指令：${error}',
			'companionRemote.errors.joinTimedOut' => '加入工作階段逾時',
			'companionRemote.errors.failedToConnectAnyAddress' => '無法連線至任何位址',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => '嘗試 ${attempts} 次後連線中斷',
			'companionRemote.errors.connectionLost' => '連線已中斷',
			'companionRemote.closedBeforeAuth' => '連線在驗證前已關閉',
			'videoSettings.playbackSpeed' => '播放速度',
			'videoSettings.normalSpeed' => '正常速度',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => '執行中（${duration}）',
			'videoSettings.zoom' => '縮放',
			'videoSettings.sleepTimer' => '睡眠計時器',
			'videoSettings.audioSync' => '音訊同步調整',
			'videoSettings.subtitleSync' => '字幕同步調整',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => '此處無法使用 HDR——這個桌面合成器或視訊輸出無法傳遞 HDR。',
			'videoSettings.hdrToneMapping' => 'HDR 色調映射',
			'videoSettings.hdrToneMappingCompositor' => '合成器',
			'videoSettings.hdrToneMappingCompositorDescription' => '直接傳遞來源的 HDR 中繼資料，並交由桌面合成器進行色調映射。',
			'videoSettings.hdrToneMappingPlayer' => '播放器',
			'videoSettings.hdrToneMappingPlayerDescription' => '在播放器中依顯示器的峰值亮度進行映射，再將結果告知合成器。',
			'videoSettings.hdrToneMappingFailed' => '無法變更 HDR 色調映射，先前的模式仍在使用中。',
			'videoSettings.audioOutput' => '音訊輸出',
			'videoSettings.performanceOverlay' => '效能監控',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => '環繞聲',
			'videoSettings.audioOutputSpatial' => '空間音訊',
			'videoSettings.audioOutputStereo' => '立體聲',
			'videoSettings.audioEqualizer' => '音訊平衡器',
			'videoSettings.audioEqualizerDescription' => '適用於此裝置的五個頻率帶;可在mpv上;一個活躍的EQ音訊解碼,並禁用匹配。',
			'videoSettings.audioEqualizerFlat' => '平板',
			'videoSettings.audioEqualizerActive' => '自訂',
			'videoSettings.audioEqualizerSaveFailed' => '無法儲存音訊平衡器設定。',
			'videoSettings.backgroundVideoAudio' => '背景影片音訊',
			'videoSettings.backgroundVideoAudioDescription' => '離開播放器後繼續播放影片音訊；返回前畫面會隱藏。Android 會顯示媒體播放通知。',
			'videoSettings.audioNormalization' => '音量標準化',
			'videoSettings.audioNormalizationDisablesPassthrough' => '將音訊解碼為 PCM；開啟時直通關閉',
			'performanceOverlay.color' => '色彩',
			'performanceOverlay.performance' => '效能',
			'performanceOverlay.buffer' => '緩衝',
			'performanceOverlay.app' => '應用程式',
			'performanceOverlay.decoder' => '解碼器',
			'performanceOverlay.rawDecoder' => '原始解碼器',
			'performanceOverlay.tunneling' => '通道模式',
			'performanceOverlay.passthrough' => '直通',
			'performanceOverlay.aspect' => '寬高比',
			'performanceOverlay.rotation' => '旋轉角度',
			'performanceOverlay.dvSource' => 'DV 來源',
			'performanceOverlay.dvPath' => 'DV 路徑',
			'performanceOverlay.dvRouteDecoder' => 'Dolby Vision 解碼器',
			'performanceOverlay.dvRouteDecoderP81' => 'Dolby Vision 解碼器（P7→8.1）',
			'performanceOverlay.dvRouteBaseLayer' => '基礎層',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'HDR10 基礎層',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'HLG 基礎層',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'SDR 基礎層',
			'performanceOverlay.dvRouteReshaped' => 'RPU 重塑（gpu-next）',
			'performanceOverlay.dvRouteFelGraphActive' => '實驗 P7 FEL 圖表(未合格)',
			'performanceOverlay.p7Conversion' => 'P7 轉換',
			'performanceOverlay.sampleRate' => '取樣率',
			'performanceOverlay.pixelFormat' => '像素格式',
			'performanceOverlay.hwFormat' => '硬體格式',
			'performanceOverlay.matrix' => '矩陣',
			'performanceOverlay.primaries' => '基色',
			'performanceOverlay.transfer' => '傳輸特性',
			'performanceOverlay.renderFps' => '渲染 FPS',
			'performanceOverlay.displayFps' => '螢幕 FPS',
			'performanceOverlay.avSync' => '影音同步（A/V Sync）',
			'performanceOverlay.dropped' => '丟格數（Dropped）',
			'performanceOverlay.dvRpus' => 'DV RPU 數',
			'performanceOverlay.dvRpuAverage' => 'DV RPU 平均',
			'performanceOverlay.dvSampleAverage' => 'DV 取樣平均',
			'performanceOverlay.maxLuma' => '最大亮度',
			'performanceOverlay.minLuma' => '最小亮度',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => '已用快取',
			'performanceOverlay.cacheLimit' => '快取上限',
			'performanceOverlay.speed' => '速度',
			'performanceOverlay.player' => '播放器',
			'performanceOverlay.playMethod' => '玩方法',
			'performanceOverlay.memory' => '記憶體',
			'performanceOverlay.uiFps' => '介面 FPS',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android 硬體',
			'performanceOverlay.decoderNvidiaHw' => 'NVIDIA 硬體',
			'performanceOverlay.decoderQualcommHw' => 'Qualcomm 硬體',
			'performanceOverlay.decoderMediatekHw' => 'MediaTek 硬體',
			'performanceOverlay.decoderExynosHw' => 'Exynos 硬體',
			'performanceOverlay.decoderSoftware' => '軟體',
			'performanceOverlay.decoderHardware' => '硬體',
			'performanceOverlay.tunnelingActive' => '已啟用',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted}（${failures} 個失敗）',
			'externalPlayer.title' => '外部播放器',
			'externalPlayer.useExternalPlayer' => '使用外部播放器',
			'externalPlayer.useExternalPlayerDescription' => '在其他應用程式中開啟影片',
			'externalPlayer.selectPlayer' => '選擇播放器',
			'externalPlayer.customPlayers' => '自訂播放器',
			'externalPlayer.systemDefault' => '系統預設',
			'externalPlayer.addCustomPlayer' => '新增自訂播放器',
			'externalPlayer.playerName' => '播放器名稱',
			'externalPlayer.playerNameHint' => '我的播放器',
			'externalPlayer.playerCommand' => '執行命令',
			'externalPlayer.playerPackage' => '套件名稱',
			'externalPlayer.playerUrlScheme' => 'URL 協定架構（Scheme）',
			'externalPlayer.off' => '關閉',
			'externalPlayer.launchFailed' => '無法啟動外部播放器',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} 未安裝',
			'externalPlayer.playInExternalPlayer' => '在外部播放器播放',
			'externalPlayer.description' => '選擇另一個應用程式開啟影片,可用的玩家取決於您的裝置和安裝的應用程式。',
			'externalPlayer.systemDefaultDescription' => '讓作業系統使用預設應用程式開啟影片。',
			'externalPlayer.playerOptionDescription' => ({required Object player}) => '使用 ${player} 開啟影片。',
			'externalPlayer.playerNameDescription' => '標籤顯示在玩家列表中。',
			'externalPlayer.playerPackageDescription' => '輸入玩家應用程式的Android包名稱,如com.example.player。',
			'externalPlayer.playerCommandDescription' => '輸入該裝置安裝的播放器命令或可執行路徑。',
			'externalPlayer.playerUrlSchemeDescription' => '輸入 URL 格式和可選的 URL 模板,用於啟動播放器。',
			'metadataEdit.editMetadata' => '編輯…',
			'metadataEdit.screenTitle' => '編輯中繼資料',
			'metadataEdit.basicInfo' => '基本資訊',
			'metadataEdit.artwork' => '海報與背景',
			'metadataEdit.advancedSettings' => '進階設定',
			'metadataEdit.title' => '標題',
			'metadataEdit.sortTitle' => '排序標題',
			'metadataEdit.originalTitle' => '原始標題',
			'metadataEdit.releaseDate' => '上映日期',
			'metadataEdit.contentRating' => '內容分級',
			'metadataEdit.studio' => '製片商',
			'metadataEdit.tagline' => '宣傳標語',
			'metadataEdit.summary' => '大綱簡介',
			'metadataEdit.poster' => '海報',
			'metadataEdit.background' => '背景圖',
			'metadataEdit.logo' => '標誌（Logo）',
			'metadataEdit.squareArt' => '方形圖片',
			'metadataEdit.selectPoster' => '選擇海報',
			'metadataEdit.selectBackground' => '選擇背景圖',
			'metadataEdit.selectLogo' => '選擇標誌',
			'metadataEdit.selectSquareArt' => '選擇方形圖片',
			'metadataEdit.fromUrl' => '自訂網址',
			'metadataEdit.uploadFile' => '上傳檔案',
			'metadataEdit.enterImageUrl' => '輸入圖片 URL',
			'metadataEdit.imageUrl' => '圖片 URL',
			'metadataEdit.metadataUpdated' => '中繼資料已更新',
			'metadataEdit.metadataUpdateFailed' => '中繼資料更新失敗',
			'metadataEdit.artworkUpdated' => '封面圖片已更新',
			'metadataEdit.artworkUpdateFailed' => '封面圖片更新失敗',
			'metadataEdit.noArtworkAvailable' => '沒有可用的封面圖片',
			'metadataEdit.artworkOption' => ({required Object index}) => '封面圖片選項 ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => '封面圖片選項 ${index}，已選擇',
			'metadataEdit.notSet' => '未設定',
			'metadataEdit.libraryDefault' => '媒體庫預設',
			'metadataEdit.accountDefault' => '帳戶預設',
			'metadataEdit.seriesDefault' => '影集預設',
			'metadataEdit.episodeSorting' => '單集排序方式',
			'metadataEdit.oldestFirst' => '由舊到新',
			'metadataEdit.newestFirst' => '由新到舊',
			'metadataEdit.keep' => '保留集數',
			'metadataEdit.allEpisodes' => '所有單集',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '最新 ${count} 集',
			'metadataEdit.latestEpisode' => '最新一集',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => '過去 ${count} 天內新增的單集',
			'metadataEdit.deleteAfterPlaying' => '播放後刪除單集',
			'metadataEdit.never' => '從不',
			'metadataEdit.afterADay' => '一天後',
			'metadataEdit.afterAWeek' => '一週後',
			'metadataEdit.afterAMonth' => '一個月後',
			'metadataEdit.onNextRefresh' => '下次重新整理時',
			'metadataEdit.seasons' => '季',
			'metadataEdit.show' => '顯示',
			'metadataEdit.hide' => '隱藏',
			'metadataEdit.episodeOrdering' => '單集排序資料源',
			'metadataEdit.tmdbAiring' => 'The Movie Database（播出順序）',
			'metadataEdit.tvdbAiring' => 'TheTVDB（播出順序）',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB（絕對集數順序）',
			'metadataEdit.metadataLanguage' => '中繼資料語言',
			'metadataEdit.useOriginalTitle' => '使用原始標題',
			'metadataEdit.preferredAudioLanguage' => '偏好音訊語言',
			'metadataEdit.preferredSubtitleLanguage' => '偏好字幕語言',
			'metadataEdit.subtitleMode' => '自動選擇字幕模式',
			'metadataEdit.manuallySelected' => '手動選擇',
			'metadataEdit.shownWithForeignAudio' => '外語配音時顯示',
			'metadataEdit.alwaysEnabled' => '一律啟用',
			'metadataEdit.tags' => '標籤',
			_ => null,
		} ?? switch (path) {
			'metadataEdit.addTag' => '新增標籤',
			'metadataEdit.genre' => '類型',
			'metadataEdit.director' => '導演',
			'metadataEdit.writer' => '編劇',
			'metadataEdit.producer' => '製片',
			'metadataEdit.country' => '國家/地區',
			'metadataEdit.collection' => '收藏集',
			'metadataEdit.label' => '標記',
			'metadataEdit.quickTag' => '快速標籤…',
			'matchScreen.match' => '配對…',
			'matchScreen.fixMatch' => '修正配對…',
			'matchScreen.unmatch' => '取消配對',
			'matchScreen.unmatchConfirm' => '清除此配對資訊？在重新配對前，Plex 會將其視為未配對媒體。',
			'matchScreen.unmatchSuccess' => '已取消配對',
			'matchScreen.unmatchFailed' => '無法取消配對',
			'matchScreen.matchApplied' => '配對已套用',
			'matchScreen.matchFailed' => '套用配對失敗',
			'matchScreen.titleHint' => '標題',
			'matchScreen.yearHint' => '年份',
			'matchScreen.search' => '搜尋',
			'matchScreen.noMatchesFound' => '找不到符合的配對',
			'serverTasks.title' => '伺服器工作',
			'serverTasks.failedToLoad' => '載入工作失敗',
			'serverTasks.noTasks' => '目前沒有執行中的工作',
			'trakt.title' => 'Trakt',
			'trakt.connected' => '已連線',
			'trakt.connectedAs' => ({required Object username}) => '已以 @${username} 身分連線',
			'trakt.disconnectConfirm' => '中斷與 Trakt 帳戶的連結？',
			'trakt.disconnectConfirmBody' => 'PlezyNG 將停止向 Trakt 傳送事件。您可以隨時重新連線。',
			'trakt.scrobble' => '即時同步記錄（Scrobble）',
			'trakt.scrobbleDescription' => '在播放時向 Trakt 傳送播放、暫停和停止等狀態。',
			'trakt.watchedSync' => '同步已觀看狀態',
			'trakt.watchedSyncDescription' => '在 PlezyNG 中將項目標記為已觀看時，也會在 Trakt 上標記為已觀看。',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => '連線至 Seerr',
			'seerr.serverUrl' => '伺服器 URL',
			'seerr.serverUrlHelper' => '您的 Seerr 執行個體的連線位址',
			'seerr.checkServer' => '繼續',
			'seerr.signInWithJellyfin' => '使用 Jellyfin 登入',
			'seerr.signInWithEmby' => '使用 Emby 登入',
			'seerr.signInWithLocal' => '使用本地帳戶',
			'seerr.email' => '電子郵件',
			'seerr.noSignInMethods' => '此 Seerr 執行個體未提供 PlezyNG 支援的登入方式。',
			'seerr.instance' => '執行個體',
			'seerr.disconnectConfirm' => '中斷與 Seerr 的連線？',
			'seerr.disconnectConfirmBody' => 'PlezyNG 將忘記此 Seerr 連線資訊。您可以隨時重新連線。',
			'seerr.request' => '請求',
			'seerr.request4k' => '請求 4K 版本',
			'seerr.seasons' => '季',
			'seerr.allSeasons' => '所有季數',
			'seerr.advancedOptions' => '進階設定',
			'seerr.destinationServer' => '目標伺服器',
			'seerr.qualityProfile' => '畫質設定檔（Quality Profile）',
			'seerr.rootFolder' => '根目錄資料夾',
			'seerr.languageProfile' => '語言設定檔（Language Profile）',
			'seerr.tags' => '標籤',
			'seerr.noTags' => '沒有標籤',
			'seerr.defaultOption' => ({required Object name}) => '${name}（預設）',
			'seerr.animeNote' => '此影集為動畫。',
			'seerr.requestSubmitted' => '請求已送出',
			'seerr.requestFailed' => ({required Object error}) => '請求失敗：${error}',
			'seerr.requestsLoadFailed' => '無法載入請求選項',
			'seerr.nothingToRequest' => '所有內容皆已可用或已提出請求。',
			'seerr.statusAvailable' => '可用',
			'seerr.statusPartiallyAvailable' => '部分可用',
			'seerr.statusRequested' => '已請求',
			'seerr.statusProcessing' => '處理中',
			'seerr.statusBlocklisted' => '已加入封鎖清單',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => '無法連線至 ${url}：${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => '在 ${url} 找不到 Seerr 執行個體（HTTP ${status}）',
			'seerr.behindAuthProxy' => '回應來自需要驗證的反向代理（SSO 或 HTTP 驗證），而非 Seerr。PlezyNG 無法透過它登入：請讓 Seerr 的 /api/v1 路徑為此應用程式繞過代理，或使用可直接連線至 Seerr 的位址。',
			'seerr.invalidUrl' => '請輸入伺服器位址，例如 https://seerr.example.com',
			'seerr.quickConnectUnsupported' => '此 Seerr 執行個體不支援 Quick Connect。需要 Seerr 3.4 或更新版本。',
			'seerr.notInitialized' => '此 Seerr 執行個體尚未完成首次執行設定',
			'seerr.noPlexTokenForReauth' => '沒有可用於重新登入的 Plex 權杖',
			'seerr.noStoredCredentials' => '沒有可用於重新登入的已儲存認證資訊',
			'seerr.signInRejected' => '登入遭到拒絕',
			'seerr.noSessionCookie' => 'Seerr 未發出工作階段 Cookie',
			'seerr.freshCookieRejected' => 'Seerr 拒絕了新的工作階段 Cookie',
			'seerr.noUserInformation' => 'Seerr 未傳回使用者資訊',
			'seerr.sessionRejectedAfterReauth' => '重新登入後，工作階段遭到拒絕',
			'seerr.permissionDenied' => 'Seerr 拒絕了此操作：您的帳戶不再具備所需權限',
			'seerr.permissionRevoked' => '您不再具有請求此內容的權限',
			'services.title' => '外部服務',
			'services.hubSubtitle' => '同步觀看進度並請求新內容。',
			'services.integrations' => '整合',
			'services.notConnected' => '未連線',
			'services.connectedAs' => ({required Object username}) => '已以 @${username} 身分連線',
			'services.scrobble' => '自動同步播放進度',
			'services.scrobbleDescription' => '觀賞完一集或一部電影後自動更新您的外部列表。',
			'services.disconnectConfirm' => ({required Object service}) => '中斷與 ${service} 的連線？',
			'services.disconnectConfirmBody' => ({required Object service}) => 'PlezyNG 將停止更新 ${service}。您可以隨時重新連線。',
			'services.connectFailed' => ({required Object service}) => '無法連線至 ${service}。請重試。',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => '重新連線 Simkl',
			'services.simklReconnect.subtitle' => 'Simkl 即將停用此連線所使用的登入方式。重新連線會開啟 simkl.com 以核准 PlezyNG — PlezyNG 絕不會看到您的密碼。您的觀看紀錄仍會保留在 Simkl 上。',
			'services.deviceCode.title' => ({required Object service}) => '在 ${service} 啟用 PlezyNG',
			'services.deviceCode.instructions' => '掃描 QR 碼，或前往下方網址並輸入此代碼：',
			'services.deviceCode.openToActivate' => ({required Object service}) => '開啟 ${service} 進行啟用',
			'services.deviceCode.copyCode' => '複製啟用代碼',
			'services.deviceCode.waitingForAuthorization' => '等待授權中…',
			'services.deviceCode.codeCopied' => '代碼已複製',
			'services.oauthProxy.title' => ({required Object service}) => '登入 ${service}',
			'services.oauthProxy.body' => '掃描 QR 碼，或在任何裝置上開啟該網址。',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => '開啟 ${service} 進行登入',
			'services.pendingAuth.copyUrl' => '複製登入 URL',
			'services.pendingAuth.urlCopied' => 'URL 已複製',
			'services.libraryFilter.title' => '媒體庫篩選',
			'services.libraryFilter.subtitleAllSyncing' => '同步所有媒體庫',
			'services.libraryFilter.subtitleNoneSyncing' => '不同步任何內容',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '已封鎖 ${count} 個',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '已允許 ${count} 個',
			'services.libraryFilter.mode' => '篩選模式',
			'services.libraryFilter.modeBlacklist' => '黑名單（排除）',
			'services.libraryFilter.modeWhitelist' => '白名單（僅限）',
			'services.libraryFilter.modeHintBlacklist' => '同步下方未勾選的所有媒體庫。',
			'services.libraryFilter.modeHintWhitelist' => '僅同步下方已勾選的媒體庫。',
			'services.libraryFilter.libraries' => '媒體庫',
			'services.libraryFilter.noLibraries' => '沒有可用的媒體庫',
			'services.libraryFilter.modeDescription' => '選擇要阻止已勾選的媒體庫同步，或只同步已勾選的媒體庫。',
			'services.seerrDescription' => '連線到 Seerr 或 Overseerr 以搜尋標題並提交媒體請求。',
			'services.trackerDescriptions.trakt' => '與您的 Trakt 帳戶同步觀看的節目和電影。',
			'services.trackerDescriptions.mal' => '同步動畫列表,並透過 MyAnimeList 觀看進展。',
			'services.trackerDescriptions.anilist' => '同步動畫列表,並與 AniList 觀看進展。',
			'services.trackerDescriptions.simkl' => '同步觀看電影,電視節目和動畫與Simkl。',
			'services.trackerDescriptions.mdblist' => '在推薦和探索中顯示 MDBList 評分和列表。',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => '新增 ${product} 伺服器',
			'addServer.serverUrls' => '伺服器 URL',
			'addServer.serverUrlsHelper' => '可輸入多個連線網址，以逗號區隔。',
			'addServer.findServer' => '尋找伺服器',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => '正在尋找本機的 ${product} 伺服器…',
			'addServer.localMediaBrowserServers' => ({required Object product}) => '本機的 ${product} 伺服器',
			'addServer.username' => '使用者名稱',
			'addServer.password' => '密碼',
			'addServer.signIn' => '登入',
			'addServer.change' => '變更',
			'addServer.required' => '必填',
			'addServer.couldNotReachServer' => ({required Object error}) => '無法連線至伺服器：${error}',
			'addServer.signInFailed' => ({required Object error}) => '登入失敗：${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => '快速連線失敗：${error}',
			'addServer.addPlexTitle' => '使用 Plex 登入',
			'addServer.pinExpired' => 'PIN 碼在登入前已過期。請重試。',
			'addServer.failedToRegisterAccount' => ({required Object error}) => '註冊帳戶失敗：${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => '請輸入您的 ${product} 伺服器 URL',
			'addServer.addConnectionTitle' => '新增連線',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => '新增連線至 ${name}',
			'addServer.signInWithPlexCard' => '使用 Plex 登入',
			'addServer.signInWithPlexCardSubtitle' => '授權此裝置。將會新增共享的伺服器連線。',
			'addServer.signInWithPlexCardSubtitleScoped' => '授權 Plex 帳戶。Home 使用者會建立為個別的使用者設定檔。',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => '連線至 ${product}',
			'addServer.connectToMediaBrowserCardSubtitle' => '輸入您的伺服器 URL、使用者名稱與密碼。',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => '登入您的 ${product} 伺服器。將綁定至 ${name}。',
			'addServer.borrowFromAnotherProfile' => '從另一個使用者設定檔共用',
			'addServer.borrowFromAnotherProfileSubtitle' => '重複使用另一個使用者設定檔的連線資訊。受 PIN 碼保護的使用者設定檔需輸入 PIN 碼。',
			'addServer.invalidCredentials' => '使用者名稱或密碼無效',
			'addServer.authResponseNotJson' => '驗證回應不是有效的 JSON',
			'addServer.authResponseIncomplete' => '伺服器傳回的登入回應不完整',
			'addServer.quickConnectRejected' => 'Quick Connect 遭到伺服器拒絕',
			'addServer.quickConnectNotJson' => 'Quick Connect 回應不是有效的 JSON',
			'addServer.quickConnectMissingFields' => 'Quick Connect 回應缺少代碼或密鑰',
			'addServer.quickConnectPollRejected' => 'Quick Connect 輪詢遭到伺服器拒絕',
			'addServer.serverTimedOut' => '伺服器未及時回應',
			'addServer.responseNotJson' => '伺服器回應不是有效的 JSON',
			'addServer.responseMissingIdentity' => ({required Object product}) => '回應缺少 ID 或伺服器名稱——這是 ${product} 伺服器嗎？',
			'addServer.probeFailed' => ({required Object error}) => '無法連線至伺服器：${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => '請輸入至少一個 ${product} 伺服器 URL',
			'addServer.noReachableServer' => ({required Object product}) => '找不到可連線的 ${product} 伺服器',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => '這些 URL 指向不同的 ${product} 伺服器',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => '此 URL 與 ${product} 伺服器不符',
			'addServer.redirectUnsupported' => '伺服器重新導向至不支援的 URL',
			'addServer.redirectDifferentHost' => ({required Object product}) => '伺服器重新導向至不同的主機。請直接輸入最終的 ${product} URL。',
			'addServer.redirectInsecure' => '伺服器從 HTTPS 重新導向至不安全的 URL',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => '伺服器重新導向至不支援的 URL。請直接輸入最終的 ${product} URL。',
			'addServer.directPlexServerUrl' => 'Plex 伺服器 URL',
			'addServer.directPlexServerUrlHelper' => '輸入您的 Plex 媒體伺服器的本地 IP 和埠。',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex 代幣(可選)',
			'addServer.plexTokenHelper' => '放空,如果在此伺服器上允許無 auth 訪問。',
			'addServer.plexTokenRequired' => '請輸入您的 Plex 代幣(X-Plex-Token)。',
			'addServer.connectDirectPlexCard' => 'Plex 媒體伺服器(直接/本地)',
			'addServer.connectDirectPlexCardSubtitle' => '直接使用本地IP或URL連線,無需 plex.tv 帳戶。',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => '直接使用本地IP或URL連線,連線到${name}。',
			'addServer.insecureTitle' => '未加密的連線',
			'addServer.insecureDescription' => ({required Object url}) => '${url} 使用 HTTP。網路中的其他人可能讀取或竄改您的密碼、權杖和媒體內容。請盡可能使用 HTTPS。只有在您信任此網路並接受風險時才繼續。',
			'addServer.allowHttp' => '允許 HTTP',
			'addServer.httpsRequired' => '使用 HTTPS 或明確允許未加密的連線。',
			'cast.chooseDevice' => '點選一個裝置',
			'cast.searching' => '尋找卡片裝置',
			'cast.connectedTo' => ({required Object device}) => '連線到 ${device}',
			'cast.device' => '加密裝置',
			'cast.readyToCast' => '準備放',
			'cast.subtitle' => '字幕',
			'cast.serverNotAvailable' => '媒體伺服器不適用。',
			'cast.stopCasting' => '停止加密',
			'cast.castToDevice' => '點選裝置',
			'cast.noEpisodeAvailable' => '沒有任何節目可播放。',
			'cast.startFailed' => '無法開始投射,檢查伺服器並嘗試一次。',
			'automation.noActivePlayback' => '沒有活躍的影片會話可以控制。',
			'notifications.newEpisodeTitle' => '新集',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appAccess.title' => '每個功能都免費嘗試7天',
			'appAccess.description' => '開始一個七天的試用,完全訪問每個PlezyNG功能,在試用期間沒有費用,沒有訂閱,試用後,在您的商店價格上一生購買,終身開鎖PlezyNG。',
			'appAccess.trialEndedDescription' => '依商店顯示的價格一次性購買，即可終身解鎖 PlezyNG 的全部功能，無須訂閱。',
			'appAccess.startTrial' => '開始我的7天免費試驗',
			'appAccess.trialActive' => '您的7天全功能測試已活躍。',
			'appAccess.trialEnded' => '你的七天審判結束了',
			'appAccess.trialStartFailed' => '我無法在這個裝置上儲存測試,請再試一次。',
			'appAccess.lifetimeTitle' => 'PlezyNG 終身禁用',
			'appAccess.lifetimeBody' => '感謝!您終身訪問所有 PlezyNG 功能。',
			'appAccess.manageTitle' => 'PlezyNG 終身訪問',
			'appAccess.manageDescription' => '每個功能都免費嘗試7天,然後用一個付款解鎖一生的一切,以您的商店的價格。',
			'appAccess.buy' => ({required Object price}) => '解鎖所有功能為 ${price}',
			'appAccess.loadingPrice' => '貨物價格...',
			'appAccess.retryPrice' => '回報價格 檢視',
			'appAccess.restore' => '恢復終身購買',
			'appAccess.pending' => '您的購買正在等待付款或核准。商店完成交易後，終身使用權限將立即解鎖。',
			'appAccess.storeUnavailable' => '目前無法購買。請確認您已登入商店，且此裝置允許購買。',
			'appAccess.productNotFound' => 'PlezyNG 終身解鎖 目前尚未在本商店提供。',
			'appAccess.productQueryFailed' => '無法收取商店價格,請檢查您的連線並嘗試一次。',
			'appAccess.purchaseFailed' => '購買不錯了,再試一次。',
			'appAccess.restoreFailed' => '無法到達商店恢復您的購買,再試一次。',
			'appAccess.nothingToRestore' => '已找到第 PlezyNG 終身購買號,用於此商店帳戶。',
			'detail.endsAt' => ({required Object time}) => '預計 ${time} 結束',
			'watchLink.serverUnavailable' => '無法訪問 Plex 伺服器此連結。',
			'watchLink.notFound' => '我無法在您的伺服器上找到此節目或電影 Plex。',
			'watchLink.ambiguous' => '此連結匹配多個伺服器上的專案,並將伺服器新增到連結中。',
			'watchLink.plexOnly' => '目前僅支援 Plex 伺服器的觀看連結。',
			'watchLink.unsupportedItem' => '觀看連結只能開啟一個節目或電影。',
			'watchLink.menuItem' => '檢視連結',
			'watchLink.dialogTitle' => '檢視連結',
			'watchLink.dialogShowHint' => '開啟此連結播放下一個節目. 新增 &mode=shuffle 到結尾播放節目在 shuffle 上。',
			'watchLink.dialogMovieHint' => '開啟這個連結播放電影。',
			'watchLink.copy' => '複製',
			'watchLink.copied' => '連結複製',
			'homeLayout.title' => 'Home 佈局',
			'homeLayout.resetToast' => '主頁重新設定到原始Plezy英雄配置',
			'homeLayout.resetHeroTitle' => '重定向英雄配置到儲存Plezy?',
			'homeLayout.resetHeroBody' => '關閉所有內容列的焦點橫幅設定，並恢復首頁頂端的單一輪播橫幅，如同引入焦點橫幅列之前的版面配置。內容列的順序和顯示狀態不受影響。',
			'homeLayout.removeRowTitle' => '取消家居序列?',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} 將被刪除,此不能被刪除。',
			'homeLayout.sync' => '同步',
			'homeLayout.syncAccountTitle' => '與您的 Plex 帳戶同步配置',
			'homeLayout.syncAccountOn' => '開啟：此裝置會與您的其他裝置共用內容列順序、內容列、焦點橫幅和自動輪播設定。',
			'homeLayout.syncAccountOff' => '關閉:此裝置保持其自己的配置。',
			'homeLayout.syncNow' => '現在的Sync',
			'homeLayout.plexHomeManager' => 'Plex 主持人',
			'homeLayout.managePlexRows' => '管理 Plex 行在 Plezy',
			'homeLayout.managePlexRowsDescription' => '開放組織主選行列',
			'homeLayout.organizeHomeRows' => '安排家居行',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} 行: 移動, 英雄, 自動滑動, 移除',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => '組織 ${library} 行',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => '繼續觀看 + ${n} 行: 移動, 圖書館, 家, 英雄, 自動滑板',
			'homeLayout.renderAsHero' => '顯示為焦點橫幅',
			'homeLayout.heroOnlySingleCollection' => '只有當此行解決到單一集合的實際標題時才可用',
			'homeLayout.hero' => '焦點橫幅',
			'homeLayout.autoSlide' => '自動輪播',
			'homeLayout.autoSlideDescription' => '每隔幾秒也會自動切換。電腦上的箭頭按鈕和電視遙控器的方向鍵始終可用，使用後會重新開始計時。',
			'homeLayout.autoSlideEditDescription' => '每隔幾秒也會自動切換。關閉時，僅在點選電腦上的箭頭按鈕或按電視遙控器的左右方向鍵時切換。無論此設定是否開啟，箭頭按鈕和方向鍵都可用。',
			'homeLayout.enableHeroFirst' => '英雄第一',
			'homeLayout.showOnHome' => '顯示在主螢幕上',
			'homeLayout.home' => '首頁',
			'homeLayout.removeFromHome' => '離開家',
			'homeLayout.selectRowsFirst' => '首先,選擇下面的主行。',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} Plex 管理行',
			'homeLayout.continueWatching' => '繼續觀看',
			'homeLayout.continueWatchingLibraryDescription' => '圖書館的本質重建進展順序',
			'homeLayout.continueWatchingHomeDescription' => '重新進展序列顯示在家',
			'homeLayout.nextUpHomeDescription' => '下一篇 未觀看的集合序列在主頁上單獨顯示',
			'homeLayout.library' => '媒體庫',
			'homeLayout.showInRecommended' => '圖書館推薦',
			'homeLayout.customPlexRow' => '定製 Plex 行',
			'homeLayout.heroNeedsLibrary' => '檢視圖書館首先 - 英雄需要在某處展示',
			'homeLayout.heroNeedsSurface' => '檢視圖書館或家先 - 英雄需要在某處展示',
			'homeLayout.removeHub' => '取消 Hub',
			'homeLayout.noPlexRows' => '第Plex號管理行返回此圖書館。',
			'homeLayout.openDetails' => '開放細節',
			'homeLayout.heroCards' => '英雄卡',
			'homeLayout.tapHeroCard' => '打破英雄卡',
			'homeLayout.tvPlayFocus' => '電視遠端:突出點選播放按鈕',
			'homeLayout.tvPlayFocusDescription' => '按方向鍵下鍵時，焦點會先停在播放按鈕上，再移到下一列。關閉時會直接跳到下一列。',
			'homeLayout.tvWrap' => '電視遠端: loop 英雄卡',
			'homeLayout.tvWrapDescription' => '在最後一張卡片上按右鍵會回到第一張；關閉時則停在最後一張。在第一張卡片上按左鍵始終會進入側邊欄。',
			'homeLayout.castOnHero' => '在焦點橫幅上顯示演員',
			'homeLayout.castOnHeroDescription' => '在焦點橫幅底部顯示演員列表。關閉時僅保留標題和簡介。',
			'homeLayout.customRows' => '定位線',
			'homeLayout.loading' => '家用佈局...',
			'homeLayout.noCustomRows' => '尚未有定位',
			'homeLayout.addRowHint' => '使用新增主行建立一個。',
			'homeLayout.addHomeRow' => '新增 Home Rue',
			'homeLayout.addHomeRowDescription' => '選擇類別;新行將自動新增到組織者',
			'homeLayout.removeRow' => '取消行列',
			'homeLayout.recentlyAdded' => '最近新增',
			'homeLayout.recentlyReleased' => '最近釋出',
			'homeLayout.movieCollections' => '電影收藏',
			'homeLayout.showCollections' => '展示集合',
			'homeLayout.rowTitle' => '路 標題',
			'homeLayout.content' => '內容',
			'homeLayout.showThisRowIn' => '顯示此行在:',
			'homeLayout.libraryRecommended' => '推薦圖書館',
			'homeLayout.heroCard' => '英雄卡',
			'homeLayout.heroCardDescription' => '顯示為一個全寬旋轉卡,而不是海報架。',
			'homeLayout.heroUnavailableDescription' => '僅當此內容列顯示單一合輯中的實際媒體項目時才可用；選取多個合輯時，沒有可供輪播的單一媒體項目。',
			'homeLayout.librariesSelection' => '圖書館(所有未經檢查的圖書館都包含)',
			'homeLayout.librariesMergedDescription' => '這裡檢視的每一個圖書館都合併到這個單一的行列。',
			'homeLayout.movieCollectionsSelection' => '電影收藏(每個選擇的圖書館都沒有檢視)',
			'homeLayout.showCollectionsSelection' => '顯示收藏品(每個選擇的圖書館都沒有檢視)',
			'homeLayout.collectionRowsDescription' => '如果一個集合相匹配,其標題直接在序列中顯示;如果一個集合多,每個集合都顯示為單一的海報,則點選它以開啟該集合。',
			'homeLayout.allCollections' => '所有收藏',
			'homeLayout.noRowsHere' => '目前還沒有線條。',
			'homeLayout.hideWatchedRows' => '隱藏在行列中觀看的物品',
			'homeLayout.hideWatchedRowsDescription' => '已看完的媒體項目會從首頁和媒體庫的推薦列中移除，尚未看完的項目會保留。',
			'homeLayout.untitledCollection' => '未經標題收藏',
			'homeLayout.moveRowHint' => '向上/下: 移動行 · 選擇: 將此處放下 · 返回: 取消',
			'homeLayout.organizeRowsHint' => '選擇行(或保持):移動 · 左/右:行選項 · 返回:完成',
			'homeLayout.layoutNavDescription' => '選擇行、圖書館和收藏類別',
			'homeLayout.editHomeRow' => '編輯 主頁 序列',
			'homeLayout.resetHeroButton' => '恢復 Plezy 預設焦點橫幅配置',
			'homeLayout.reorderingUnlocked' => '重新排序 開鎖',
			'homeLayout.reorderingLocked' => '重新安排鎖',
			'homeLayout.rowsCanBeDragged' => '可以拖繩 - 點選鎖,以防止',
			'homeLayout.tapLockToDrag' => '點選鎖,拖行列',
			'homeLayout.customRowLabel' => ({required Object title}) => '定位: ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => '隱藏',
			'homeLayout.remove' => '移除',
			'homeLayout.libraryResumeRow' => '圖書館的重複順序',
			'homeLayout.pressAgainToDelete' => '再次按下刪除',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => '到',
			'homeLayout.resetHeroButtonDescription' => '關閉所有內容列的焦點橫幅設定，並恢復頂端的單一輪播橫幅，如同引入焦點橫幅列之前的版面配置。內容列順序維持不變。',
			'homeLayout.tapHeroCardDescription' => '選擇打字或選擇一個英雄卡是否開始播放,或者開啟它的細節。',
			'homeLayout.heroTapPlayDescription' => '立即啟動所選擇的專案。',
			'homeLayout.heroTapDetailsDescription' => '在選擇行動之前,開啟所選專案的詳細資訊。',
			'platform.localNetworkPermission' => 'PlezyNG 會連線至您區域網路中的媒體伺服器和播放裝置。',
			'platform.locationPermission' => '當 iOS 要求提供位置權限才能偵測區域網路並連線至媒體伺服器時，PlezyNG 會使用此權限。',
			'platform.photoLibraryPermission' => '從照片圖庫中選取圖片，用作媒體封面等影像。',
			'platform.cameraPermission' => '掃描 QR 碼以配對 Companion Remote。',
			'universalMedia.title' => '開放媒體',
			'universalMedia.shortcutHelp' => '播放此會議的連結、播放列表或檔案。',
			'universalMedia.intro' => '開啟連結、播放列表或檔案 Playback 使用 PlezyNG 的標準播放器,並且不會將歷史新增到您的圖書館。',
			'universalMedia.openWhat' => '你想開啟什麼?',
			'universalMedia.stream' => '流地址',
			'universalMedia.playlist' => '播放列表',
			'universalMedia.files' => '裝置檔案',
			'universalMedia.favorites' => '儲存流喜愛',
			'universalMedia.address' => '媒體地址',
			'universalMedia.addressHelp' => 'HTTPS 是優先的. 有認可或簽名引數的 URL 僅用於此會議,並且不能儲存為喜愛。',
			'universalMedia.displayName' => '顯示名稱(可選)',
			'universalMedia.displayNameHelp' => '選擇玩家和系統媒體控制器的簡稱。',
			'universalMedia.allowHttp' => '允許未加密的 HTTP 連線',
			'universalMedia.allowHttpHelp' => 'HTTP 不加密連線. 只允許它在可靠的網路上. 當可能時使用 HTTPS。',
			'universalMedia.advancedProtocols' => 'MPV 僅:輸入 RTSP、RTMP/RTMPS、UDP 或 RTP 地址,這些地址不能儲存為最受歡迎的。',
			'universalMedia.liveStream' => '作為活著的待遇',
			'universalMedia.liveStreamHelp' => '使用此用於直播影片或廣播電臺. 該應用程式隱藏了時間欄,滑動按鈕和 go-to-time 選項。',
			'universalMedia.privateSession' => '只有此播放使用地址. 儲存一個合格流最喜歡的,以保持它在這個個人資料。',
			'universalMedia.saveFavorite' => '儲存最喜歡',
			'universalMedia.playNow' => '現在玩',
			'universalMedia.favoriteSaved' => '流喜愛儲存到此個人資料',
			'universalMedia.skippedEntries' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '${count} 不受支援或不安全的播放列表輸入。', other: '${count} 不受支援或不安全的播放列表輸入。', ), 
			'universalMedia.playlistAddress' => 'Playlist 地址',
			'universalMedia.playlistAddressHelp' => '從網頁地址開啟 M3U、M3U8 或 PLS 播放列表. Direct Stream 連結不會儲存播放名單。',
			'universalMedia.choosePlaylist' => '選擇 Playlist 檔案',
			'universalMedia.openPlaylist' => '開放播放列表',
			'universalMedia.playlistFormatsHelp' => '一張播放列表可以包含最多1000個專案和2MB的HLS顯示為流,所以玩家可以選擇質量。',
			'universalMedia.noFavorites' => '尚未儲存流喜愛. 喜愛留在此個人資料中。',
			'universalMedia.removeFavorite' => '刪除流喜愛',
			'universalMedia.filesHelp' => '選擇音訊、影片或ISO檔案,以便進行臨時記錄. 檔案和URL不新增到圖書館歷史。',
			'universalMedia.chooseFiles' => '選擇檔案',
			'universalMedia.fileQueue' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '1 選擇的檔案', other: '${count} 已選擇的檔案', ), 
			'universalMedia.wifiTransfer' => '透過 Wi-Fi 傳送檔案',
			'universalMedia.wifiTransferHelp' => '從同一信任網路的瀏覽器傳輸支援的檔案。',
			'universalMedia.wifiTransferIntro' => '在另一個裝置上的瀏覽器中開啟此地址. 選擇檔案以將其新增到該裝置的檔案和書籍圖書館。',
			'universalMedia.wifiTransferPrivacy' => '本裝置透過您的本地網路接收檔案. 任何知道此地址的人都可以傳送檔案,直到您停止傳輸或地址在15分鐘後終止。',
			'universalMedia.wifiTransferStarting' => '準備一個私人,時間有限的轉會...',
			'universalMedia.wifiTransferUnavailable' => '無法啟動轉換,檢查本地網路接入並嘗試一次。',
			'universalMedia.openThisAddress' => '在傳送裝置上開啟其中一個地址',
			'universalMedia.copyAddress' => '傳輸地址複製',
			'universalMedia.addressCopied' => '傳輸地址複製',
			'universalMedia.transferExpires' => ({required Object time}) => '此地址在 ${time} 中終止。',
			'universalMedia.uploadCount' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '${count} 獲取檔案', other: '${count} 收到的檔案', ), 
			'universalMedia.uploadedData' => ({required Object size}) => '接收 ${size}',
			'universalMedia.stopTransfer' => '停止轉讓和取消地址',
			'universalMedia.startTransfer' => '轉移開始',
			'universalMedia.wifiImportedFiles' => 'Wi-Fi 傳輸',
			'universalMedia.wifiBrowserTitle' => '向 PlezyNG 傳送檔案',
			'universalMedia.wifiBrowserIntro' => '選擇音訊、影片、電子書或漫畫檔案傳送. 這些檔案儲存在該裝置的檔案和書籍庫中. 最多: 100 個檔案,每個檔案 4 GiB,總共 10 GiB。',
			'universalMedia.uploadFilesLabel' => '檔案傳送',
			'universalMedia.uploadSelected' => '下載所選擇的檔案',
			'universalMedia.uploadSelectFirst' => '首先選擇一個或多個檔案。',
			'universalMedia.uploading' => '傳送',
			'universalMedia.uploadComplete' => '檔案新增到 PlezyNG。',
			'universalMedia.uploadFailed' => '檔案無法新增,請保持此頁面開放並再次嘗試。',
			'universalMedia.liveCue' => '生活',
			'universalMedia.liveSession' => '直播流',
			'universalMedia.liveCueHelp' => '對於直播影片或無線電,應用程式隱藏了時間欄和跳躍按鈕,它不會儲存地址或觀看歷史。',
			'universalMedia.sessionOnly' => '此播放僅是會話',
			'universalMedia.sessionOnlyHelp' => 'Playback 永遠不會儲存進展或歷史. 如果有資格,請將流作為最受歡迎的儲存在此個人資料中。',
			'universalMedia.pictureAdjustments' => '影象調整',
			'universalMedia.pictureHelp' => '這些影象變更隻影響此播放,它們在播放結束時重新設定。',
			'universalMedia.resetPicture' => '重新設定影象',
			'universalMedia.brightness' => '光明',
			'universalMedia.contrast' => '矛盾',
			'universalMedia.gamma' => '加姆',
			'universalMedia.hue' => '鬍子',
			'universalMedia.saturation' => '土星',
			'universalMedia.view360' => '平板檢視360度影片',
			'universalMedia.view360Help' => 'MPV 需要 FFmpeg 的 v360 過濾器來檢視此檢視。',
			'universalMedia.view360Unavailable' => '這個MPV構建不能應用360度過濾器。',
			'universalMedia.view360Yaw' => '地平線視野',
			'universalMedia.view360Pitch' => '垂直視野',
			'universalMedia.view360FieldOfView' => '視野領域',
			'universalMedia.recordStream' => '記錄直播',
			'universalMedia.stopRecording' => '停止和儲存錄制',
			'universalMedia.recordingStarted' => '記錄是活躍的,讓播放停止並儲存錄制。',
			'universalMedia.recordingSaved' => '錄製完成並儲存。',
			'universalMedia.recordingActive' => '放棄播放停止並儲存它。',
			'universalMedia.recordingFormatHelp' => '對於影片,選擇 MKV 或 MPEG-TS. 為音訊,選擇 MKA 或 MKV。',
			'universalMedia.replaceRecordingTitle' => '取代這張錄音?',
			'universalMedia.replaceRecordingHelp' => 'PlezyNG 在錄製時備份現有檔案;如果無法儲存新錄製,PlezyNG 將備份恢復。',
			'universalMedia.replaceRecording' => '替換檔案',
			'universalMedia.discHelp' => '在此計算機的光學驅動器中開啟磁碟,您也可以從裝置檔案中開啟ISO影象。',
			'universalMedia.discs' => '光學磁碟',
			'universalMedia.dvd' => 'DVD',
			'universalMedia.bluray' => '藍光',
			'universalMedia.audioCd' => '音訊CD',
			'universalMedia.discAvailability' => '磁碟播放需要相容的MPV構建、支援的驅動器和作業系統許可,不能超越商業磁碟保護。',
			'universalMedia.converterTitle' => '轉換本地媒體檔案',
			'universalMedia.converterHelp' => '使用 FFmpeg 建立 MP4, M4A 或 MP3 副本。',
			'universalMedia.converterIntro' => '將本地音訊或影片檔案轉換為多個裝置上執行的格式。',
			'universalMedia.converterPrivacy' => 'FFmpeg 必須安裝在此計算機上. 轉換隻讀取本地檔案. 不下載流或刪除 DRM。',
			'universalMedia.converterChooseInput' => '選擇本地媒體檔案',
			'universalMedia.converterFormat' => '輸出格式',
			'universalMedia.converterMp4' => 'MP4 · H.264 和 AAC',
			'universalMedia.converterM4a' => 'M4A · AAC 音訊',
			'universalMedia.converterMp3' => 'MP3 · 音訊',
			'universalMedia.converterSaveAs' => '儲存轉換的媒體作為',
			'universalMedia.converterExtensionMismatch' => '選擇與所選輸出擴充套件的檔名。',
			'universalMedia.converterUnsupportedInput' => '選擇音訊或影片檔案。',
			'universalMedia.converterLocalOnly' => '所選擇的檔案不作為本地裝置路徑可用。',
			'universalMedia.converterReplaceTitle' => '取代此檔案?',
			'universalMedia.converterReplaceHelp' => 'PlezyNG 恢復現有檔案,直到轉換的副本被儲存。',
			'universalMedia.converterStarting' => '開始 FFmpeg...',
			'universalMedia.converterProgress' => '轉換到這個計算機......',
			'universalMedia.converterComplete' => '轉換完成,新檔案已準備好。',
			'universalMedia.converterFfmpegMissing' => 'FFmpeg 無法找到所需的編碼器. 使用 H.264, AAC 和 MP3 支援安裝 FFmpEG,然後再次嘗試。',
			'universalMedia.converterFailed' => '轉換失敗:檢查原始檔可以閱讀,目的地有足夠的免費空間。',
			'universalMedia.converterCancelled' => '轉換取消了,不完整的輸出被刪除。',
			'universalMedia.converterDesktopOnly' => '本地轉換可在桌面計算機上使用 FFmpeg 安裝。',
			'universalMedia.converterStart' => '轉換檔案',
			'universalMedia.mediaToolsTitle' => '媒體工具',
			'universalMedia.mediaToolsShortcut' => '捕獲或共享媒體,新增搜尋擴充套件或使用命令列。',
			'universalMedia.mediaToolsIntro' => '選擇一個專注的工具. 捕獲和流出使用 FFmpeg 安裝在這個桌面上. 擴充套件和 CLI 命令使用有限的 HTTPS 請求和現有 Open media 流。',
			'universalMedia.mediaToolsAccessibility' => '工具選項和控制器與觸控、指標、鍵盤和D-pad焦點工作。 錄製、共享和搜尋狀態的變化被公佈。',
			'universalMedia.mediaTool' => '媒體工具',
			'universalMedia.captureIntro' => '在此計算機上記錄螢幕或相機到 MP4 檔案. FFmpeg 必須安裝幷包含 H.264 編碼器。',
			'universalMedia.captureNoDevices' => '沒有螢幕或相機被發現 檢視 FFmpeg 捕捉支援和作業系統隱私許可證。',
			'universalMedia.captureSource' => '螢幕或相機',
			'universalMedia.captureScreen' => '螢幕',
			'universalMedia.captureAudioSource' => '音訊輸入(可選)',
			'universalMedia.captureAudioHelp' => '新增來自微型或可用的輸入的音訊 裝置選項取決於 FFmpeg 和系統許可。',
			'universalMedia.captureAudioNone' => '沒有音訊',
			'universalMedia.captureDefaultAudio' => '預設音訊輸入',
			'universalMedia.captureWaylandHelp' => 'Wayland 限制此 XWayland 捕獲到 X display. XWayland 以外的 Windows 可能不會出現。',
			'universalMedia.captureFrameRate' => '記錄框率',
			'universalMedia.capturePrivacy' => '錄製僅儲存到您選擇的檔案。 微型錄制是可選的. PlezyNG 不會上傳錄製。',
			'universalMedia.captureSaveAs' => '儲存螢幕錄製如',
			'universalMedia.captureExtensionMismatch' => '在 .mp4 中選擇終端的檔名。',
			'universalMedia.captureFfmpegMissing' => 'FFmpeg 或 H.264 影片編碼器不適用. 安裝支援的 FFmpeg 構建,然後再次嘗試。',
			'universalMedia.captureFailed' => '記錄無法儲存 檢查裝置許可、可用的儲存和 FFmpeg 支援。',
			'universalMedia.captureSaved' => '螢幕錄製儲存',
			'universalMedia.captureElapsedLabel' => '錄製時間',
			'universalMedia.captureStart' => '開始錄製',
			'universalMedia.captureStop' => '停止和拯救',
			'universalMedia.captureMode' => '捕捉',
			'universalMedia.shareMode' => '分享',
			'universalMedia.shareIntro' => '將本地媒體檔案傳送到您的私人網路上的另一個裝置. PlezyNG 建立一個暫時的 HLS 流。',
			'universalMedia.sharePrivacy' => '您的本地網路的任何人,誰接收私人連結可以觀看,而它是活躍的. 連結結束後60分鐘. 停止共享,關閉伺服器並取消連結。',
			'universalMedia.shareChooseFile' => '選擇媒體檔案',
			'universalMedia.shareChooseHelp' => '選擇一個本地的音訊或影片檔案. 該檔案留在此計算機上。',
			'universalMedia.shareFfmpegMissing' => 'FFmpeg 或 H.264/AAC 編碼器不適用. 安裝 FFmpeg 與 H.264 和 AAC 編碼支援。',
			'universalMedia.shareFailed' => '流量無法意外地開始或停止。 檢視 FFmpeg 和網路訪問。',
			'universalMedia.shareActive' => '流在您的私人網路上已經準備好了。',
			'universalMedia.shareEnded' => '媒體已經到達了結局,並且不再被分享。',
			'universalMedia.shareStopped' => '分享停止了,暫時連結不再有效。',
			'universalMedia.shareUrlCopied' => '流地址複製。',
			'universalMedia.shareOpenUrl' => '在另一臺裝置上的一個播放器中開啟此地址',
			'universalMedia.shareQrLabel' => '臨時流地址的QR程式碼',
			'universalMedia.shareQrHelp' => '掃描與同一私人網路連線的相容播放器。',
			'universalMedia.shareHttpHint' => '此流使用未加密的 HTTP. 在 PlezyNG 中,允許 HTTP 在開啟它之前。',
			'universalMedia.shareCopyUrl' => '複製流地址',
			'universalMedia.shareExpiresLabel' => '連結終止',
			'universalMedia.shareStarting' => '準備流...',
			'universalMedia.shareStart' => '開始分享',
			'universalMedia.shareStop' => '停止分享',
			'universalMedia.extensionsMode' => '擴充套件和CLI',
			'universalMedia.extensionsIntro' => '新增一個資料僅搜尋擴充套件,以找到媒體. 選擇一個結果,將其載入到熟悉的 Open media 表格。',
			'universalMedia.extensionsPrivacy' => '一個顯明可以定義一個 HTTPS 搜尋終點和地圖響應欄位. 它不能執行程式碼,新增請求標題,閱讀檔案,或啟動盾牌命令。',
			'universalMedia.extensionImport' => '新增擴充套件顯明',
			'universalMedia.extensionEmpty' => '尚未搜尋服務. 選擇一個可靠的顯明 JSON 檔案新增一個。',
			'universalMedia.extensionChoose' => '搜尋服務',
			'universalMedia.extensionSearchConsent' => '每個搜尋都會傳送您的單詞到這個 HTTPS 服務. 結果僅在您選擇一個後開啟。',
			'universalMedia.extensionSearchLabel' => '搜尋媒體',
			'universalMedia.extensionSearch' => '搜尋',
			'universalMedia.extensionSearching' => '尋找...',
			'universalMedia.extensionNoResults' => '沒有安全的媒體結果返回,請嘗試另一個搜尋。',
			'universalMedia.extensionInstallTitle' => '新增此搜尋服務?',
			'universalMedia.extensionReplaceTitle' => '更新此搜尋服務?',
			'universalMedia.extensionService' => '服務',
			_ => null,
		} ?? switch (path) {
			'universalMedia.extensionEndpoint' => 'HTTPS 終點',
			'universalMedia.extensionConsent' => '您的搜尋文字被髮送到此服務. 該示文稿不包含執行程式碼. 繼續只有如果你信任這個終點。',
			'universalMedia.extensionInstall' => '新增服務',
			'universalMedia.extensionReplace' => '更新服務',
			'universalMedia.extensionRemoveTitle' => '刪除此搜尋服務?',
			'universalMedia.extensionRemoveHelp' => '這將取消該服務從此個人資料中. PlezyNG 不聯絡其終點。',
			'universalMedia.extensionRemove' => '取消服務',
			'universalMedia.extensionInvalidManifest' => '此檔案不是一個支援的擴充套件顯而易見. 檢視 Open media 格式指南。',
			'universalMedia.extensionSaveFailed' => '該擴充套件無法儲存到活躍的個人資料。',
			'universalMedia.extensionSearchFailed' => '搜尋服務沒有返回有效的答案 檢查終點並嘗試一次。',
			'universalMedia.cliTitle' => '命令線',
			'universalMedia.cliHelp' => '使用 plezyctl 指南來驗證一個顯明或搜尋相同的擴充套件. 每次搜尋之前,檢視 HTTPS 服務. 結果在現有媒體格式中開啟; 選擇播放按鈕開始。',
			'universalMedia.cliCopyExample' => '複製命令示例',
			'universalMedia.cliCopied' => '命令例子複製',
			'fileSources.title' => '檔案和書籍',
			'fileSources.subtitle' => '閱讀、聽、從自己的檔案中觀看。',
			'fileSources.add' => '新增源',
			'fileSources.importFiles' => '進口檔案',
			'fileSources.localFiles' => '在此裝置上',
			'fileSources.source' => '源',
			'fileSources.name' => '名稱',
			'fileSources.endpoint' => '伺服器 URL',
			'fileSources.smbEndpointHint' => '範例：smb://nas/Movies',
			'fileSources.smbEndpointInvalid' => '請輸入 SMB 伺服器和一個共用資料夾。',
			'fileSources.root' => '資料夾或前綴',
			'fileSources.smbFolderHelp' => '留空以使用整個共用資料夾，或輸入其中的某個資料夾。',
			'fileSources.username' => '使用者名稱',
			'fileSources.smbDomain' => '網域（選填）',
			'fileSources.password' => '密碼',
			'fileSources.token' => 'API 標誌',
			'fileSources.accessKey' => '關鍵 ID 訪問',
			'fileSources.secretKey' => '秘密訪問金鑰',
			'fileSources.sessionToken' => '會議程式碼(可選)',
			'fileSources.region' => '區域',
			'fileSources.clientId' => '客戶 ID',
			'fileSources.clientSecret' => 'OAuth 客戶端秘密(僅限 Google 桌面)',
			'fileSources.allowHttp' => '允許在可信任的網路上使用未加密的 HTTP',
			'fileSources.smbEncryption' => '加密 SMB3 連線',
			'fileSources.smbEncryptionHint' => '當 NAS 支援時，使用 SMB3 加密。',
			'fileSources.connect' => '連線',
			'fileSources.cancel' => '取消',
			'fileSources.save' => '儲存',
			'fileSources.close' => '關閉',
			'fileSources.removeSource' => '連線源',
			'fileSources.disconnectMessage' => '要中斷此來源的連線嗎？已下載的檔案及閱讀和聆聽記錄會保留在此裝置上。',
			'fileSources.localFolder' => '選擇資料夾',
			'fileSources.empty' => '這裡還沒有任何內容',
			'fileSources.emptyHint' => '新增來源，或匯入書籍、有聲書、音樂或影片。',
			'fileSources.search' => '搜尋此資料夾',
			'fileSources.searchCached' => '搜尋 儲存圖書館',
			'fileSources.refresh' => '重新整理',
			'fileSources.loadMore' => '載入更多',
			'fileSources.offline' => '可用 offline',
			'fileSources.download' => '保持離線',
			'fileSources.removeDownload' => '刪除非線影印件',
			'fileSources.continueReading' => '繼續閱讀',
			'fileSources.continueListening' => '繼續聽',
			'fileSources.continueWatching' => '繼續觀看',
			'fileSources.read' => '閱讀',
			'fileSources.listen' => '聽',
			'fileSources.play' => '播放',
			'fileSources.pause' => '暫停',
			'fileSources.stop' => '停止',
			'fileSources.startOver' => '開始過',
			'fileSources.finished' => '播放完畢',
			'fileSources.markFinished' => '馬克結束了',
			'fileSources.markUnfinished' => '馬克 未完成',
			'fileSources.editions' => '版和檔案',
			'fileSources.chapters' => '章節',
			'fileSources.bookmarks' => '書標和筆記',
			'fileSources.bookmark' => '新增 Bookmark',
			'fileSources.highlight' => '突出',
			'fileSources.note' => '注目',
			'fileSources.delete' => '刪除',
			'fileSources.export' => '出口筆記',
			'fileSources.exported' => '出口的筆記',
			'fileSources.sync' => '同步進展',
			'fileSources.synced' => '進展合成',
			'fileSources.conflict' => '另一個裝置有不同的位置,選擇去哪裡。',
			'fileSources.useLocal' => '使用此裝置',
			'fileSources.useRemote' => '使用其他裝置',
			'fileSources.history' => '位置歷史',
			'fileSources.groupAudio' => '聽作一本音訊書',
			'fileSources.groupHint' => '將目前在此資料夾中載入的音訊檔案結合起來. 首先載入所有頁面。',
			'fileSources.order' => '檔案命令',
			'fileSources.moveUp' => '移動上',
			'fileSources.moveDown' => '移動下',
			'fileSources.speed' => '播放速度',
			'fileSources.sleep' => '睡眠計時器',
			'fileSources.sleepOff' => '關閉',
			'fileSources.endChapter' => '章節的結尾',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(count, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} 分鐘', ), 
			'fileSources.skipBack' => '滑落回',
			'fileSources.skipForward' => '滑向前',
			'fileSources.smartRewind' => '休假後智慧迴歸',
			'fileSources.playbackOptions' => '聽力選項',
			'fileSources.remaining' => ({required Object time}) => '${time} 剩餘',
			'fileSources.contents' => '內容',
			'fileSources.readerSettings' => '閱讀設定',
			'fileSources.fontSize' => '文字大小',
			'fileSources.lineHeight' => '線路空間',
			'fileSources.margin' => '馬格林',
			'fileSources.font' => '型號',
			'fileSources.serif' => '襯線字型',
			'fileSources.sans' => '無襯線字型',
			'fileSources.mono' => '等寬字型',
			'fileSources.columns' => '列',
			'fileSources.scroll' => '垂直滑動',
			'fileSources.justify' => '左右對齊',
			'fileSources.readerTheme' => '頁面外觀',
			'fileSources.appTheme' => '跟隨應用主題',
			'fileSources.paper' => '紙張',
			'fileSources.sepia' => '塞比亞',
			'fileSources.night' => '夜晚',
			'fileSources.readAloud' => '朗讀此頁',
			'fileSources.readAlong' => '跟讀',
			'fileSources.stopReading' => '停止朗讀',
			'fileSources.searchBook' => '搜尋書中',
			'fileSources.noMatches' => '沒有比賽',
			'fileSources.previousPage' => '上一頁',
			'fileSources.nextPage' => '下一頁',
			'fileSources.page' => ({required Object number}) => '頁面 ${number}',
			'fileSources.externalBlocked' => '閱讀器中已停用書籍的外部連結。',
			'fileSources.loading' => '開...',
			'fileSources.narrator' => '講話者',
			'fileSources.audio' => '音訊',
			'fileSources.video' => '視訊',
			'fileSources.ebooks' => '電子書',
			'fileSources.all' => '全部',
			'fileSources.downloads' => '非線檔案',
			'fileSources.confirmDelete' => '要移除選取的離線副本嗎？閱讀或聆聽進度和筆記會保留。',
			'fileSources.errorAuthentication' => '再登入,重新連線這個來源。',
			'fileSources.errorPermission' => '此來源未授予所要求檔案的存取權限。',
			'fileSources.errorUnavailable' => '源不可用 再試一次,或者開啟一個離線副本。',
			'fileSources.errorUnsupported' => '此裝置不支援該格式或連線方式。請查看來源設定指南。',
			'fileSources.errorInvalidData' => '此檔案或伺服器回覆無法安全地閱讀。',
			'fileSources.errorCancelled' => '行動被取消了。',
			'fileSources.errorConflict' => '閱讀或聆聽位置已在另一個工作階段變更。請重新開啟項目，選擇要使用的位置。',
			'fileSources.signIn' => '登入',
			'fileSources.reconnect' => '重新連線',
			'fileSources.folderHelp' => '留空可從來源根目錄開始。S3 URL 包含儲存貯體名稱。',
			'fileSources.preferences' => '偏好',
			'fileSources.timePosition' => '位置',
			'fileSources.audioTrack' => '音訊軌道',
			'fileSources.subtitleTrack' => '標題 軌道',
			'fileSources.none' => '無',
			'fileSources.fullscreen' => '全螢幕',
			'fileSources.syncLocation' => '進展同步資料夾(可選)',
			'fileSources.syncLocationHint' => '用於儲存 PlezyNG 狀態的專用 WebDAV 資料夾。採用條件式寫入，不會變更媒體檔案。',
			'fileSources.audiobooks' => '音訊書籍',
			'fileSources.comics' => '漫畫',
			'fileSources.scan' => '掃描書籍和媒體',
			'fileSources.browserReader' => '開放讀者',
			'fileSources.browserReaderHelp' => '閱讀器在您的瀏覽器中開放. 保持 PlezyNG 開放,以儲存您的位置和筆記。',
			'fileSources.on' => '到',
			'fileSources.advancedSetup' => 'App 登記',
			'fileSources.microsoftSignIn' => '與Microsoft登入',
			'fileSources.zoomIn' => '放大',
			'fileSources.zoomOut' => '出Zoom',
			'fileSources.fitPage' => '合適頁面',
			'fileSources.fitWidth' => '合適的寬度',
			'fileSources.actualSize' => '目前大小',
			'fileSources.goToPage' => '去頁面',
			'fileSources.goToSection' => '去章節',
			'fileSources.pageRange' => ({required Object count}) => '輸入 1 到 ${count} 的數字',
			'fileSources.pageLayout' => '頁面Layout',
			'fileSources.automatic' => '自動',
			'fileSources.singlePage' => '單頁',
			'fileSources.twoPages' => '二頁',
			'fileSources.readingDirection' => '閱讀方向',
			'fileSources.leftToRight' => '左向右',
			'fileSources.rightToLeft' => '由右至左',
			'fileSources.letterSpacing' => '信 空間',
			'fileSources.wordSpacing' => '字 空間',
			'fileSources.readerControlsHelp' => '張開雙指或使用縮放控制項放大頁面，拖曳可平移頁面。按 Ctrl/⌘ 與 + 或 − 調整縮放，按 Ctrl/⌘ 與 0 重設縮放。使用 Page Up 和 Page Down 翻頁。',
			'fileSources.imagePage' => '漫畫頁面',
			'fileSources.resetReader' => '重新設定閱讀偏好',
			'fileSources.zoom' => '縮放',
			'fileSources.useFiles' => '使用檔案和書籍',
			'fileSources.cancelScan' => '取消掃描',
			'fileSources.googleDrive' => 'Google Drive',
			'fileSources.offlineQuota' => '離線下載限制',
			'fileSources.offlineQuotaHelp' => '設定離線副本、匯入檔案及佇列中下載所使用的空間上限。降低上限不會移除現有副本。',
			'fileSources.offlineStorageUsage' => '非線儲存',
			'fileSources.reservedStorage' => '保留',
			'fileSources.downloadQueue' => '下載Queue',
			'fileSources.downloadRunning' => '下載',
			'fileSources.downloadQueued' => '等待',
			'fileSources.downloadPaused' => '休息',
			'fileSources.downloadFailed' => '需要退休',
			'fileSources.importing' => '進口',
			'fileSources.importInterrupted' => '進口中斷 · 刪除清理',
			'fileSources.errorQuotaExceeded' => '已達離線儲存空間上限。請提高上限或移除已下載的副本。',
			'fileSources.errorStorageLow' => '沒有足夠的免費裝置儲存,以保留保護備份。',
			'fileSources.errorStorageUnavailable' => 'PlezyNG無法檢查免費裝置儲存,所以寫作停止了。',
			'fileSources.removeDownloadJob' => '刪除下載',
			'fileSources.downloadAlreadyComplete' => '此下載完成之前,它可以被刪除. 該專案現在可用於離線。',
			'fileSources.confirmRemoveDownloadJob' => '要移除此下載並捨棄已下載的部分資料嗎？閱讀位置和筆記會保留。',
			'lending.title' => '公共圖書館',
			'lending.add' => '新增圖書館',
			'lending.other' => '另一家圖書館',
			'lending.libraryName' => '圖書館名稱',
			'lending.libraryUrl' => '圖書館網站',
			'lending.libraryUrlHint' => '使用您的圖書館的目錄或登入頁面。',
			'lending.intro' => '向圖書館借閱，讓書籍隨時相伴。',
			'lending.handoff' => '登入、借款和安全閱讀,您圖書館的服務。',
			'lending.openService' => '開放圖書館',
			'lending.findLibrary' => '找個圖書館',
			'lending.search' => '搜尋書籍和作家',
			'lending.catalogue' => '目錄',
			'lending.loans' => '借閱',
			'lending.holds' => '預約',
			'lending.signIn' => '與您的圖書館登入',
			'lending.waiting' => '結束登入在您的瀏覽器,然後返回這裡。',
			'lending.cancel' => '取消',
			'lending.disconnect' => '取消圖書館',
			'lending.disconnectMessage' => '要從此使用者設定檔移除此圖書館嗎？借閱和預約紀錄仍會保留在圖書館。',
			'lending.getBook' => '獲書',
			'lending.checkAvailability' => '檢視可用性',
			'lending.available' => '可借閱',
			'lending.unavailable' => '目前不可用',
			'lending.borrow' => '借閱',
			'lending.placeHold' => '預約借閱',
			'lending.returnBook' => '提前歸還',
			'lending.cancelHold' => '取消預約',
			'lending.confirmBorrow' => '借這本書從圖書館裡?',
			'lending.confirmReturn' => '現在歸還此書嗎？您可能需要重新借閱才能繼續閱讀。',
			'lending.confirmCancelHold' => '要取消此書的預約嗎？',
			'lending.email' => '留下通知電子郵件',
			'lending.due' => ({required Object date}) => '歸還日期：${date}',
			'lending.queue' => ({required Object position}) => '排隊位置：${position}',
			'lending.empty' => '還沒有標題。',
			'lending.openLibraryNote' => '探索 Open Library 的目錄。每本書的頁面都會顯示閱讀和借閱選項。',
			'lending.more' => '載入更多',
			'lending.gateway' => '圖書館登入服務',
			'lending.gatewayHint' => '由您的圖書館或管理員提供,PlezyNG。',
			'lending.advanced' => '圖書館整合',
			'lending.loadLibraries' => '選擇您的圖書館',
			'lending.expired' => '此借閱已到期。',
			'lending.updated' => '圖書館更新',
			'lending.continueService' => '繼續服務',
			'lending.comingSoon' => '借款 即將到來',
			'lending.comingSoonDescription' => '即將支援 Libby 整合。在連線功能完成之前，您可以先在 Libby 中使用圖書館服務。',
			'lending.suspendHold' => '暫停預約',
			'lending.resumeHold' => '恢復預約',
			'lending.suspendMessage' => '要保留排隊位置，讓下一位讀者先借閱此副本嗎？您可以稍後恢復預約。',
			'lending.resumeMessage' => '要恢復此預約，讓圖書館為您提供下一份可借閱的副本嗎？',
			'lending.editEmail' => '更改通知電子郵件',
			'audiobook.syncTitle' => '閱讀與傾聽Sync',
			'audiobook.syncHelp' => '在您的裝置上保持閱讀位置、傾聽位置、完成狀態、圖示和筆記。 選擇附加儲存帳戶並在每個裝置上使用相同的同步程式碼. 閱讀和傾聽保持分開。',
			'audiobook.addSyncSource' => '首先將 Google Drive、OneDrive、Dropbox、WebDAV 或 S3 新增到檔案和書籍中。',
			'audiobook.syncDestination' => '同步儲存帳戶',
			'audiobook.syncFolder' => '同步資料夾或預定',
			'audiobook.syncFolderHelp' => '在 WebDAV 源內使用一個單獨的現有資料夾,或一個專門的 S3 預定。',
			'audiobook.syncCode' => '個人同步程式碼',
			'audiobook.syncCodeHelp' => '在您的第一臺裝置上建立一個程式碼,然後在您的其他裝置上輸入該程式碼. 保持一個私人副本:它是您的加密狀態的關鍵。',
			'audiobook.showCode' => '顯示或隱藏同步程式碼',
			'audiobook.newSyncCode' => '建立一個新的同步程式碼',
			'audiobook.saveSync' => '儲存和同步',
			'audiobook.disableSync' => '在此裝置上關閉同步',
			'audiobook.syncSourceDisconnect' => '移除此來源會停用此裝置上的閱讀與聆聽同步。加密的同步檔案仍會保留在儲存服務供應商端。',
			'audiobook.syncReconnect' => '重新連線儲存帳戶',
			'audiobook.lastSynced' => ({required Object time}) => '上一篇: ${time}',
			'audiobook.syncPrivacy' => '僅儲存加密的進度和筆記。音訊檔案、電子書檔案、帳戶權杖和密碼不會上傳。Google Drive 和 OneDrive 使用應用程式專用儲存空間；Dropbox 使用 PlezyNG Sync。啟用同步時，可能會要求額外的寫入權限。啟用後，進度同步由此儲存目標負責，伺服器進度維持獨立。關閉同步後，本機歷史記錄和遠端狀態仍會保留。',
			'audiobook.syncConflicts' => '選擇重定向的地方',
			'audiobook.conflictHelp' => '這些變更是各自獨立進行的。請選擇要保留的進度位置或書籤版本。時間戳記較新或進度百分比較高的版本不會自動優先保留。',
			'audiobook.syncDevice' => ({required Object device}) => '裝置 ${device}',
			'audiobook.syncUnknownDevice' => '未知裝置',
			'audiobook.deletedBookmark' => '刪除圖示',
			'audiobook.finished' => '結束',
			'audiobook.readingPosition' => ({required Object percent}) => '閱讀 · ${percent}%',
			'audiobook.chapterTimeline' => '第四章 進展',
			'audiobook.bookTimeline' => '全書進展',
			'audiobook.bookRemaining' => ({required Object time}) => '本書剩餘時間：${time}',
			'audiobook.chapterRemaining' => ({required Object time}) => '此分類上一篇: ${time}',
			'audiobook.unknownRemaining' => '全部時間可用,當部分被播放時',
			'audiobook.undoSeek' => '最後尋找',
			'audiobook.customSpeed' => '定製播放速度',
			'audiobook.speedHelp' => '選擇速度從 0.25× 到 4×。',
			'audiobook.apply' => '應用',
			'audiobook.customSleep' => '定製睡眠時間',
			'audiobook.sleepMinutes' => '時間(1 - 1440)',
			'audiobook.sleepChapters' => ({required Object count}) => '播放完${count}章後停止',
			'audiobook.extendSleep' => '新增5分鐘',
			'audiobook.sleepRemaining' => ({required Object time}) => '睡眠時間: ${time}',
			'audiobook.useDefaults' => '使用這些聽力控制器為新書',
			'audiobook.librarySort' => '各式各樣的書籍',
			'audiobook.sortTitle' => '標題',
			'audiobook.sortAuthor' => '作者',
			'audiobook.sortNarrator' => '講話者',
			'audiobook.sortSeries' => '系列命令',
			'audiobook.sortRecent' => '最近開放',
			'audiobook.statusFilter' => '閱讀狀態',
			'audiobook.statusAll' => '所有書籍',
			'audiobook.statusNew' => '沒有開始',
			'audiobook.statusProgress' => '進展',
			'audiobook.statusFinished' => '結束',
			'audiobook.goToTime' => '走到時間',
			'audiobook.timeHelp' => '時間: 分鐘: 秒或 分鐘: 秒',
			'audiobook.recoveryHelp' => '移動或修復同步資料前，請先匯出近期的加密備份。匯入資料會與目前狀態合併，不會取代本機同步記錄。請另外保存同步代碼。',
			'audiobook.recoveryExport' => '輸出加密恢復檔案',
			'audiobook.recoveryImport' => '輸入加密恢復檔案',
			'audiobook.recoveryImportConfirm' => '將此加密恢復檔案與當前閱讀位置和筆記相結合嗎?現有歷史記錄將被保留. 共享圖書館和專案 ID 不包含; 在進口之前,在每個裝置上設定匹配 ID。',
			'audiobook.recoveryExported' => '加密恢復檔案儲存。',
			'audiobook.recoveryImported' => '恢復資料合併。',
			'sourceSetup.savedCertificate' => '已儲存的伺服器憑證',
			'sourceSetup.nfsEndpointInvalid' => '請輸入 NFS 網址，例如 nfs://nas:2049/export。',
			'sourceSetup.dlnaNone' => '找不到 DLNA 伺服器。請手動輸入裝置描述檔的網址。',
			'sourceSetup.dlnaServers' => 'DLNA 媒體伺服器',
			'sourceSetup.dlnaUnavailable' => '無法在此網路探索 DLNA 裝置。請手動輸入裝置描述檔的網址。',
			'sourceSetup.dlnaSearching' => '正在區域網路搜尋 DLNA 伺服器',
			'sourceSetup.networkSearching' => '正在搜尋區域網路…',
			'sourceSetup.dlnaDiscover' => '探索 DLNA 伺服器',
			'sourceSetup.dlnaHelp' => '裝置探索需要區域網路支援多點傳送。若未顯示伺服器，請在上方輸入裝置描述檔的網址。',
			'sourceSetup.dlnaRoot' => 'DLNA 物件 ID；留空以使用裝置根目錄。',
			'sourceSetup.passwordOrKey' => '請輸入密碼，或在下方新增私密金鑰。',
			'sourceSetup.sshFingerprint' => 'SSH 主機金鑰 SHA256 指紋',
			'sourceSetup.sshFingerprintHelp' => '請向伺服器管理員核實。在伺服器執行 ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub，並使用顯示的 SHA256 值。',
			'sourceSetup.sshFingerprintKeep' => '留空以保留目前固定的指紋，或輸入新的伺服器指紋。',
			'sourceSetup.sshAuthentication' => 'SSH 公開金鑰驗證',
			'sourceSetup.sshAuthenticationHelp' => '選填；也支援密碼驗證。',
			'sourceSetup.privateKey' => '私密金鑰（PEM 或 OpenSSH 格式）',
			'sourceSetup.privateKeyPassphrase' => '私密金鑰密碼',
			'sourceSetup.nfsMountPort' => 'NFS 掛載服務 TCP 連接埠',
			'sourceSetup.nfsMountPortHelp' => '預設值：20048',
			'sourceSetup.nfsUserId' => 'NFS 使用者 ID（AUTH_SYS）',
			'sourceSetup.nfsUserIdHelp' => '預設值：1000。請使用 NAS 匯出設定允許的使用者 ID。',
			'sourceSetup.nfsGroupId' => 'NFS 群組 ID（AUTH_SYS）',
			'sourceSetup.nfsGroupIdHelp' => '預設值：1000。請使用 NAS 匯出設定允許的群組 ID。',
			'sourceSetup.nfsEncryption' => '要求加密 NFS 連線（RPC-with-TLS）',
			'sourceSetup.nfsEncryptionHelp' => '要求 NFS 和掛載服務使用 TLS 1.3。若 NAS 不支援，將拒絕連線。',
			'sourceSetup.nfsTrustCertificate' => '自訂 NFS CA 或伺服器憑證（PEM，選填）',
			'sourceSetup.nfsTrustHelp' => '使用此裝置信任的憑證時請留空。需要時可新增私人 CA 或自我簽署的伺服器憑證；憑證中的名稱必須與 NFS 網址的主機名稱相符。',
			'sourceSetup.nfsTrustInvalid' => '請使用 PEM 格式的 CA 或伺服器憑證。請勿包含私密金鑰。',
			'sourceSetup.addTrustCertificate' => '新增自訂信任憑證',
			'sourceSetup.replaceTrustCertificate' => '取代已儲存的自訂憑證',
			'sourceSetup.nfsTlsHelp' => 'RPC-with-TLS 使用一般的 NFS 和掛載服務連接埠，並要求 NAS 支援 RFC 9289。必須使用 TLS 1.3。主機名稱或 IP 位址必須與憑證相符。加密通道內仍須使用 AUTH_SYS UID/GID。',
			'sourceSetup.clientCertificate' => '用戶端憑證（選填）',
			'sourceSetup.clientCertificateHelp' => '讓 NAS 驗證此用戶端的身分；AUTH_SYS ID 仍受 NAS 匯出原則約束。',
			'sourceSetup.savedIdentity' => '將使用已儲存的用戶端身分憑證。',
			'sourceSetup.replaceIdentity' => '取代已儲存的用戶端身分憑證',
			'sourceSetup.chooseIdentity' => '選擇 PKCS#12 用戶端身分憑證',
			'sourceSetup.identityPassphrase' => '用戶端身分憑證密碼',
			'sourceSetup.identityPassphraseHelp' => '如果檔案沒有密碼，請留空。',
			'sourceSetup.removeIdentity' => '移除已儲存的用戶端身分憑證',
			'sourceSetup.identityStorageHelp' => '用戶端身分憑證儲存在加密的來源認證資料儲存區。保持此區段不變，即可保留已儲存的身分憑證。',
			'sourceSetup.nfsLimitations' => '透過 TCP 以唯讀方式使用 NFSv3。未使用 RPC-with-TLS 時，NFS 流量不會加密。NAS 必須允許所選 AUTH_SYS ID 和非特權用戶端連接埠（匯出選項通常稱為「insecure」）。不支援 NFSv4 和 UDP。',
			'sourceSetup.nfsSetupHelp' => 'NFS 設定說明',
			'sourceSetup.nfsSetupHint' => '若無法建立連線，請檢查這些設定。',
			'sourceSetup.nfsSetupDetails' => '請使用透過 TCP 提供的 NFSv3 匯出。要求加密時，NFS 服務和掛載服務必須都支援 RPC-with-TLS。若伺服器憑證受此裝置信任，自訂憑證可留空；否則請新增 NAS 的 CA 或自我簽署憑證。憑證名稱必須與端點中的主機名稱相符。若 NAS 要求雙向 TLS，請新增其 PKCS#12 用戶端身分憑證。最後，確認匯出設定允許指定的 AUTH_SYS UID/GID 和用戶端連接埠原則。',
			'sourceSetup.ftpHelp' => 'FTP 使用被動模式。未加密的 FTP 使用 ftp://，明確 TLS 使用 ftpes://；ftps:// 使用 TLS（連接埠 990 為隱含 TLS，其他連接埠為明確 TLS）。',
			'sourceSetup.openSubtitles' => 'OpenSubtitles',
			'sourceSetup.subtitleSetup' => '為獨立影片提供選用的字幕搜尋。',
			'sourceSetup.apiKey' => 'API 金鑰',
			'sourceSetup.optionalUsername' => '帳戶使用者名稱（選填）',
			'sourceSetup.optionalPassword' => '帳戶密碼（選填）',
			'sourceSetup.subtitlePrivacy' => '請從 opensubtitles.com 取得 API 金鑰。搜尋會傳送影片標題和可用的 IMDb/TMDB ID，絕不傳送影片檔案。金鑰和選填的帳戶認證資料會與此來源一同加密儲存。',
			'sourceSetup.automaticMetadata' => '自動取得線上影片中繼資料',
			'sourceSetup.metadataPrivacy' => '只傳送檔名中的標題、年份和集數，或 NFO ID，絕不傳送媒體或認證資料。NFO 欄位始終優先。',
			'sourceSetup.nfsEncryptionFailure' => '使用加密 NFS 時，請確認 NAS 的兩項服務皆支援 RFC 9289 和 TLS 1.3，並核對憑證名稱及匯出 UID/GID。PlezyNG 不會在未加密的情況下重試此連線。',
			'sourceSetup.sourceConnecting' => '正在連線至來源',
			'sourceSetup.metadataSearchPrivacy' => '此標題搜尋由 Trakt 處理。只會傳送您輸入的標題，不會傳送影片或來源認證資料。',
			'sourceSetup.chooseMatch' => '選擇符合的結果',
			'sourceSetup.metadataMatchHelp' => '選擇前請核對標題與年份。Trakt 會收到搜尋標題；影片檔案會保留在原來源中。',
			'sourceSetup.metadataNoMatches' => '找不到符合的線上標題。請嘗試其他標題。',
			'sourceSetup.metadataSearch' => '搜尋線上中繼資料',
			'sourceSetup.metadataLoading' => '正在查詢線上電影與影集資訊…',
			'sourceSetup.metadataFromTrakt' => '來自 Trakt 的線上中繼資料',
			'sourceSetup.metadataNoAutomaticMatch' => '找不到自動符合的標題。請搜尋標題並選擇符合的結果。',
			'sourceSetup.metadataFailed' => '無法載入線上中繼資料。仍可播放媒體及查看本機資訊。',
			'sourceSetup.videoDetailsLoading' => '正在載入影片資訊',
			'sourceSetup.subtitleKeyRequired' => '需要 OpenSubtitles API 金鑰',
			'sourceSetup.subtitleKeyHelp' => '請編輯此檔案來源，在選用的字幕設定中新增 OpenSubtitles API 金鑰。',
			'sourceSetup.subtitleSearchFailed' => '字幕搜尋失敗。請檢查 API 金鑰、網路連線及服務存取權。',
			'sourceSetup.subtitleApplyFailed' => '無法下載或套用此字幕。請檢查連線並嘗試其他結果。',
			'sourceSetup.subtitleSearch' => '搜尋 OpenSubtitles',
			'sourceSetup.subtitleSearchPrivacy' => '搜尋會使用標題和可用的 IMDb/TMDB ID。影片檔案會保留在原來源中。選擇前請核對語言、強制字幕或聽障字幕標記，以及評分。',
			'sourceSetup.movieOrShow' => '電影或影集',
			'sourceSetup.subtitleTitleHint' => '輸入標題以縮小結果範圍',
			'sourceSetup.subtitleLanguage' => '字幕語言',
			'sourceSetup.subtitleSearching' => '正在搜尋 OpenSubtitles',
			'sourceSetup.subtitleNoMatches' => '找不到符合的字幕。請嘗試其他標題或語言。',
			'sourceSetup.downloadSubtitle' => '下載字幕',
			'sourceSetup.subtitle' => '字幕',
			'sourceSetup.nfsTlsRequired' => '要求 RPC-with-TLS',
			'sourceSetup.nfsUnencrypted' => '未加密的 NFS',
			'sourceSetup.tlsEncrypted' => '已啟用 TLS 加密',
			'sourceSetup.ftpPlain' => '未加密的 FTP',
			'sourceSetup.sshPinned' => 'SSH 加密 · 已固定主機金鑰',
			'sourceSetup.smbEncrypted' => 'SMB3 加密已開啟',
			'sourceSetup.smbUnencrypted' => 'SMB3 加密已關閉',
			'sourceSetup.httpUnencrypted' => 'HTTP 無傳輸加密',
			'sourceSetup.checkEndpointSecurity' => '請檢查端點安全性',
			'sourceSetup.fieldRequired' => ({required Object label}) => '請填寫${label}。',
			'sourceSetup.integerRange' => ({required Object min, required Object max, required Object label}) => '請輸入 ${min} 至 ${max} 之間的${label}。',
			'sourceSetup.replaceFile' => ({required Object name}) => '取代 ${name}',
			'sourceSetup.selectedIdentity' => ({required Object name}) => '已選用戶端身分憑證：${name}',
			'sourceSetup.subtitleRating' => ({required Object rating}) => '評分 ${rating}',
			'sourceSetup.subtitleDownloading' => ({required Object title}) => '正在下載字幕：${title}',
			'sourceSetup.sharedEntryPair' => '將此專案配對',
			'sourceSetup.sharedEntryPairHelp' => '在每部裝置上為此項目輸入相同的 ID。使用固定的共用識別碼，或產生一組並複製到對應項目。只有當版本的檔案類型、大小和順序相符時，閱讀進度才會配對。留白會移除此對應。',
			'sourceSetup.sharedEntryId' => '共享專案 ID',
			'sourceSetup.generateSharedEntryId' => '建立共享專案 ID',
			'sourceSetup.sharedLibraryId' => '共享圖書館 ID(可選)',
			'sourceSetup.sharedLibraryHelp' => '使用相同 ID 在開啟相同圖書館的裝置上. 這個公共 ID 有助於在不同的來源連線中進行閱讀進步和筆記; 它不是密碼. 當提供商使用不同的專案 ID 時,將這些專案從其細節螢幕組合。',
			'sourceSetup.sharedLibraryInvalid' => '使用 8 至 100 個字母、數字、點、字幕或字元。',
			'sourceSetup.generateSharedLibraryId' => '建立共享圖書館 ID',
			'sourceSetup.nfsReadAhead' => 'NFS Read-ahead 請求',
			'sourceSetup.nfsReadAheadHelp' => '更多的平行閱讀可以改善快速NAS或網路的通道。使用1如果伺服器限制當前請求。',
			'sourceSetup.nfsReadTest' => '測量NFS閱讀效能',
			'sourceSetup.nfsReadTestHelp' => '從最大的檔案中讀到64 MiB,以測量這個NAS連線,這使用網路頻寬。',
			'sourceSetup.nfsQualificationResult' => 'NFS 閱讀測量',
			'sourceSetup.nfsReadBytes' => '資料閱讀',
			'sourceSetup.nfsReadSpeed' => '測量速度',
			'sourceSetup.nfsReadRequests' => '閱讀請求',
			'sourceSetup.sharedEntryConflict' => '此共享專案 ID 已與本圖書館中的另一個專案相匹配. 選擇不同的 ID。',
			'comics.fitHeight' => '符合高度',
			'comics.readingMode' => '閱讀模式',
			'comics.paged' => '分頁',
			'comics.webtoon' => '連續捲動',
			'comics.coverAlone' => '單獨顯示封面',
			'comics.splitWide' => '分割寬頁',
			'comics.splitWideHelp' => '依閱讀順序分別顯示每一半。開啟後暫停雙頁並排顯示。',
			'comics.thumbnails' => '頁面縮圖',
			'comics.controlsHelp' => '滑動翻頁，點兩下切換顯示比例。連續捲動時，垂直滑動或使用 Page Up 和 Page Down。',
			'comics.savedForComic' => '此個人檔案會記住這部漫畫的顯示設定。',
			'comics.readLists' => '閱讀清單',
			'comics.collections' => '合集',
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
			'deepLinks.invalid' => '此 Plezy 連結不有效。',
			'deepLinks.profileNotFound' => ({required Object profile}) => '沒有個人資料符合“${profile}”。',
			'deepLinks.serverUnavailable' => '我無法到達這個連結的伺服器。',
			'deepLinks.notFound' => '我無法在圖書館中找到這個標題。',
			'deepLinks.unsupportedItem' => '這個連結不能播放。',
			'deepLinks.noLiveTv' => '沒有現場電視伺服器可用於此連結。',
			'deepLinks.channelNotFound' => ({required Object channel}) => '我找不到“${channel}”頻道。',
			'deepLinks.showLink' => '顯示連結',
			_ => null,
		} ?? switch (path) {
			'deepLinks.showProfileLink' => '顯示個人資料連結',
			'deepLinks.dialogTitle' => '連結',
			'deepLinks.showHint' => '開啟此連結會播放下一集。若要隨機播放整個影集，請在結尾加上 &mode=shuffle。',
			'deepLinks.movieHint' => '開啟這個連結播放電影。',
			'deepLinks.episodeHint' => '開啟這個連結播放了這個節目。',
			'deepLinks.profileHint' => '開啟此連結轉換到這個個人資料。',
			'deepLinks.openAsProfile' => ({required Object name}) => '開啟 ${name}',
			'deepLinks.copy' => '複製',
			'deepLinks.copied' => '連結複製',
			'householdSetup.title' => '家庭設定',
			'issueReport.title' => '回報問題',
			'issueReport.instructions' => '掃描 QR 碼即可開啟已預填的 GitHub 草稿。請先檢查內容，準備好後再送出。',
			'issueReport.privacy' => '草稿包含應用程式版本、平台和連線數量，不包含伺服器位址、帳戶或個人資料名稱、媒體標題及檔案路徑。',
			'issueReport.logPrivacy' => '記錄檔為選填。上傳前請先檢查。記錄檔 ID 會加入草稿，而問題可能是公開的。',
			'issueReport.openDraft' => '開啟 GitHub 草稿',
			_ => null,
		};
	}
}
