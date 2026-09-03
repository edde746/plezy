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
	@override late final _Translations$auth$zh_Hant auth = _Translations$auth$zh_Hant._(_root);
	@override late final _Translations$common$zh_Hant common = _Translations$common$zh_Hant._(_root);
	@override late final _Translations$screens$zh_Hant screens = _Translations$screens$zh_Hant._(_root);
	@override late final _Translations$update$zh_Hant update = _Translations$update$zh_Hant._(_root);
	@override late final _Translations$settings$zh_Hant settings = _Translations$settings$zh_Hant._(_root);
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
}

// Path: app
class _Translations$app$zh_Hant extends Translations$app$zh {
	_Translations$app$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
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
	@override String get localDataRecoveryRequired => 'Plezy 無法安全地復原本機登入資料與待處理的播放資料。請重新登入。';
	@override String get pinCheckRejected => 'Plex PIN 檢查遭到拒絕';
}

// Path: common
class _Translations$common$zh_Hant extends Translations$common$zh {
	_Translations$common$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get cancel => '取消';
	@override String get save => '儲存';
	@override String get close => '關閉';
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
	@override String get mpvConfig => 'mpv.conf 設定';
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
	@override String get supportDeveloper => '贊助 Plezy';
	@override String get supportDeveloperDescription => '透過 Liberapay 捐款支持開發者';
	@override String get language => '語言';
	@override String get theme => '主題';
	@override String get appearance => '外觀';
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
	@override String get defaultQualityTitle => '預設畫質';
	@override String get cellularQualityTitle => '行動網路上的預設畫質';
	@override String get cellularQualitySameAsDefault => '與預設畫質相同';
	@override String get musicQualityTitle => '音樂品質';
	@override String get subtitleStyling => '字幕樣式';
	@override String get subtitleStylingDescription => '調整字幕外觀';
	@override String get smallSkipDuration => '短跳過時間';
	@override String get largeSkipDuration => '長跳過時間';
	@override String get rewindOnResume => '繼續播放時稍微倒轉';
	@override String secondsUnit({required Object seconds}) => '${seconds} 秒';
	@override String get defaultSleepTimer => '預設睡眠計時器';
	@override String minutesUnit({required Object minutes}) => '${minutes} 分鐘';
	@override String get rememberTrackSelections => '記住每部影集或電影的音訊與字幕選擇';
	@override String get rememberTrackSelectionsDescription => '記住每部影片的音軌與字幕選擇';
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
	@override String get watchTogetherRelayDescription => '設定自訂中繼。所有人必須使用相同的伺服器。';
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
	@override String get importSettingsInvalidFile => '此檔案不是有效的 Plezy 設定匯出檔';
	@override String get importSettingsNoUser => '匯入設定前請先登入';
	@override String get shortcutsReset => '快速鍵已重設為預設值';
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
	@override String get playNextCountdown => '下一集倒數計時';
	@override String get playNextCountdownImmediate => '立即播放';
	@override String get autoSkipIntro => '自動跳過片頭';
	@override String get autoSkipIntroDescription => '幾秒鐘後自動跳過片頭標記';
	@override String get autoSkipCredits => '自動跳過片尾';
	@override String get autoSkipCreditsDescription => '自動跳過片尾並播放下一集';
	@override String get forceSkipMarkerFallback => '強制使用備用標記';
	@override String get forceSkipMarkerFallbackDescription => '即使 Plex 有標記，也強制使用章節標題模式';
	@override String get autoSkipDelay => '自動跳過延遲';
	@override String autoSkipDelayDescription({required Object seconds}) => '自動跳過前等待 ${seconds} 秒';
	@override String get introPattern => '片頭標記模式';
	@override String get introPatternDescription => '用於比對章節標題中片頭標記的正規表示式';
	@override String get creditsPattern => '片尾標記模式';
	@override String get creditsPatternDescription => '用於比對章節標題中片尾標記的正規表示式';
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
	@override String get tunneledPlaybackDescription => '使用影片通道模式。若 HDR 播放出現黑畫面，請停用此項。';
	@override String get audioPassthrough => '音訊直通';
	@override String get audioPassthroughDescription => '將 Dolby/DTS 音訊不經重新編碼，直接傳送至擴大機或電視以保留環繞音效。若播放無聲，請關閉此設定。';
	@override String get audioPassthroughDescriptionAppleTv => '使用 Apple 原生 Dolby 解碼器處理 Dolby Digital Plus（包括 Atmos）。DTS 與 TrueHD 仍以多聲道 PCM 播放。若沒有聲音，請關閉此設定。';
	@override String get audioDownmix => '下混為立體聲';
	@override String get audioDownmixDescription => '將環繞音效混合為雙聲道，適用於立體聲喇叭或耳機';
	@override String get downmixCenterBoost => '中置聲道增強';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => '增強（dB）';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => '下混時音量標準化';
	@override String get audioDownmixNormalizeDescription => '降低混音電平以防止破音。關閉以保持原始音量（大音量場景可能會失真）。';
	@override String get dvConversionMode => 'Dolby Vision 轉換模式';
	@override String get dvConversionModeDescription => '選擇 ExoPlayer 如何處理 Dolby Vision Profile 7 檔案。';
	@override String get dvConversionAuto => '自動';
	@override String get dvConversionNative => '原生 / 停用';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => '自動偵測裝置相容性並使用一般備援機制';
	@override String get dvConversionNativeDescription => '強制使用原生 DV7 並停用 DV 轉換重試';
	@override String get dvConversionDv81Description => '強制將內嵌的 RPU 轉換為 Dolby Vision Profile 8.1';
	@override String get dvConversionHevcStripDescription => '移除 Dolby Vision RPU/EL 層，並以一般 HEVC 呈現';
	@override String get deinterlace => '去交錯';
	@override String get deinterlaceDescription => '移除交錯影片中的梳狀雜訊（僅限 mpv 播放器）';
	@override String get requireProfileSelectionOnOpen => '開啟應用程式時要求選擇使用者';
	@override String get requireProfileSelectionOnOpenDescription => '每次開啟應用程式時顯示使用者設定檔選擇畫面';
	@override String get forceTvMode => '強制 TV 模式';
	@override String get forceTvModeDescription => '強制使用 TV 介面版面。適用於無法自動辨識 TV 的裝置。需要重新啟動。';
	@override String get startInFullscreen => '以全螢幕模式啟動';
	@override String get startInFullscreenDescription => '啟動時直接以全螢幕開啟 Plezy';
	@override String get exitFullscreenOnPlayerClose => '關閉播放器時退出全螢幕';
	@override String get exitFullscreenOnPlayerCloseDescription => '關閉影片播放器時自動退出全螢幕模式';
	@override String get autoHidePerformanceOverlay => '自動隱藏效能疊加層';
	@override String get autoHidePerformanceOverlayDescription => '效能疊加層隨播放控制面板一起淡入或淡出';
	@override String get showNavBarLabels => '顯示導覽列標籤';
	@override String get showNavBarLabelsDescription => '在導覽列圖示下方顯示文字標籤';
	@override String get startupSection => '啟動頁面';
	@override String get showExploreTab => '顯示探索分頁';
	@override String get showExploreTabDescription => '顯示探索分頁，其中包含來自 Plex Discover 和已連結追蹤服務的內容';
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
	@override String get exportDialogTitle => '匯出 Plezy 設定';
	@override String get linuxVideoRenderMode => '影片轉譯模式';
	@override String get linuxVideoRenderModeDescription => '自動偏好原生 Wayland 平面（支援 HDR）；紋理強制使用 SDR 備援路徑。';
	@override String get linuxVideoRenderModeAuto => '自動';
	@override String get linuxVideoRenderModeTexture => '紋理（SDR）';
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
		other: '這會刪除其中全部 ${n} 集及其檔案。',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		other: '此項目分散儲存於 ${n} 個檔案中，且全部都會被刪除。',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		other: '另有 ${n} 集儲存在同一檔案中，也會一併被刪除：',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'Plezy 無法確認此操作會刪除哪些檔案，因此刪除範圍可能超出上方所列的項目。請取消後重試，或仍要刪除。';
	@override String get deleteScopeUnverifiedNoFileInfo => '您的伺服器未提供此項目的檔案資訊，因此 Plezy 無法確認此操作會刪除哪些檔案。刪除範圍可能超出上方所列的項目。';
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
	@override String get valueShort => 'V';
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
	@override String get longPressToUnlock => '長按解鎖';
	@override String get timelineSlider => '影片時間軸';
	@override String get volumeSlider => '音量調整';
	@override String endsAt({required Object time}) => '預計 ${time} 結束';
	@override String get pipActive => '正在以子母畫面模式播放';
	@override String get pipFailed => '啟動子母畫面失敗';
	@override String get screenshotSaved => '螢幕截圖已儲存';
	@override String zoomPercent({required Object percent}) => '縮放 ${percent}%';
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
		other: '已自動移除 ${n} 個已觀看的下載內容',
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
	@override String get logsUploaded => '日誌已上傳';
	@override String get logsUploadFailed => '上傳日誌失敗';
	@override String get logId => '日誌 ID';
	@override String get burnedSubtitlesUseMenu => '字幕已燒錄至此串流中。請從字幕選單變更字幕。';
	@override String get noVideoUrl => '沒有可用的視訊 URL';
	@override String get playbackNoMediaSources => '伺服器未傳回可播放的媒體來源';
	@override String get playbackDataNotPrepared => '播放資料尚未準備完成就已開始播放';
	@override String get streamSelectionUnavailable => '此來源不支援選擇串流';
	@override String get streamSelectionFailed => '無法套用所選串流';
	@override String get serverUnavailableForProfile => '使用中的使用者設定檔沒有可用的伺服器';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$zh_Hant extends Translations$subtitlingStyling$zh {
	_Translations$subtitlingStyling$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
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
	@override String get anchorToScreen => '錨定至螢幕';
	@override String get anchorToScreenDescription => '在寬螢幕影片下方的黑邊顯示文字字幕';
	@override String get bold => '粗體';
	@override String get italic => '斜體';
	@override String get renderResolution => '渲染解析度';
	@override String get renderResolutionScreen => '螢幕解析度';
	@override String get renderResolutionVideo => '影片解析度';
}

// Path: mpvConfig
class _Translations$mpvConfig$zh_Hant extends Translations$mpvConfig$zh {
	_Translations$mpvConfig$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv 設定';
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
	@override String get addPlezyProfile => '新增 Plezy 使用者設定檔';
	@override String get switchingProfile => '正在切換使用者設定檔…';
	@override String get deleteThisProfileTitle => '刪除此使用者設定檔？';
	@override String deleteThisProfileMessage({required Object displayName}) => '將移除 ${displayName}。連線資訊將不受影響。';
	@override String get active => '使用中';
	@override String get manage => '管理';
	@override String get delete => '刪除';
	@override String get signOut => '登出';
	@override String get signOutPlexTitle => '登出 Plex？';
	@override String signOutPlexMessage({required Object displayName}) => '確定要移除 ${displayName} 與所有 Plex Home 使用者嗎？您可以隨時重新登入。';
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
	@override String get borrowEmptySubtitle => '請先將 Plex 或 Jellyfin 連線至另一個使用者設定檔。';
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
}

// Path: connections
class _Translations$connections$zh_Hant extends Translations$connections$zh {
	_Translations$connections$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '連線';
	@override String get addConnection => '新增連線';
	@override String get addConnectionSubtitleNoProfile => '使用 Plex 登入或連線至 Jellyfin 伺服器';
	@override String addConnectionSubtitleScoped({required Object displayName}) => '新增至 ${displayName}：Plex、Jellyfin 或其他設定檔連線';
	@override String sessionExpiredOne({required Object name}) => '${name} 的工作階段已過期';
	@override String sessionExpiredMany({required Object count}) => '${count} 個伺服器的工作階段已過期';
	@override String get signInAgain => '重新登入';
	@override String editMediaBrowserTitle({required Object product}) => '編輯 ${product} 連線';
	@override String editMediaBrowserIntro({required Object serverName}) => '為 ${serverName} 新增或移除 URL。Plezy 將使用延遲最低且可連線的 URL。';
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
	@override String get storedOnAccount => '這些選項會儲存在帳戶本身，因此登入該帳戶的所有應用程式都會使用它們，包括您其他裝置上的 Plezy。';
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
		other: '${n} 部作品',
	);
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
}

// Path: libraries
class _Translations$libraries$zh_Hant extends Translations$libraries$zh {
	_Translations$libraries$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
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
}

// Path: about
class _Translations$about$zh_Hant extends Translations$about$zh {
	_Translations$about$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '關於';
	@override String get openSourceLicenses => '開源授權條款';
	@override String versionLabel({required Object version}) => '版本 ${version}';
	@override String get appDescription => '一款精美的 Plex 與 Jellyfin Flutter 用戶端';
	@override String get viewLicensesDescription => '查看第三方套件的授權條款';
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
}

// Path: startup
class _Translations$startup$zh_Hant extends Translations$startup$zh {
	_Translations$startup$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'Plezy 無法啟動';
	@override String get failedBody => '啟動期間發生問題。下方詳細資料可識別失敗的原因。';
	@override String get failedBodyRepairable => 'Plezy 儲存的設定檔已損壞，必須先重建才能啟動。重試無法解決問題 — 請選擇「修復儲存空間」。';
	@override String get phaseLabel => '步驟';
	@override String get showDetails => '顯示詳細資料';
	@override String get hideDetails => '隱藏詳細資料';
	@override String get copyDetails => '複製詳細資料';
	@override String get detailsCopied => '詳細資料已複製到剪貼簿';
	@override String get uploadDetails => '上傳詳細資料';
	@override String get repairStorage => '修復儲存空間';
	@override String get repairTitle => '修復已儲存的資料？';
	@override String get repairBodyCommon => 'Plezy 的設定檔已損壞且無法讀取。修復會將所有設定重設為預設值。';
	@override String get repairBodyOneCredential => '有一筆已儲存的登入資訊損壞且無法讀取。修復僅會移除該筆資訊，其他設定將保持不變。';
	@override String get repairBodySignInsKept => '您的伺服器與使用者設定檔應可保持登入狀態。';
	@override String get repairBodySignInsLost => '保護已儲存登入資訊的金鑰無法從此檔案中復原，因此您必須重新登入每個伺服器與使用者設定檔。您媒體伺服器上的內容不受影響。';
	@override String get repairBodySessionsUncertain => '追蹤服務（MAL、AniList、Simkl、Trakt）與 Seerr 分別儲存，可能保留也可能遺失。Plezy 會明確告知保留了哪些項目。';
	@override String get repairConfirm => '修復';
	@override String get repairSucceeded => '儲存空間已修復';
	@override String get repairNeedsRestart => '儲存空間已修復 — 需要重新啟動';
	@override String get restartRequiredBody => '您的資料已修復，但 Plezy 必須重新啟動才能使用。請關閉 Plezy 後重新開啟。';
	@override String get quitPlezy => '退出 Plezy';
	@override String get repairFailed => '修復失敗';
	@override String get repairKeptSignIns => '您的伺服器與使用者設定檔仍保持登入狀態。';
	@override String get repairLostSignIns => '保護已儲存登入資訊的金鑰無法復原。您必須重新登入每個伺服器與使用者設定檔。';
	@override String get repairLostSessions => '至少一個追蹤服務或 Seerr 連線已遺失，必須重新連線。';
	@override String get backupTitle => '已保留損壞檔案的副本';
	@override String get backupWarning => '其中包含您的登入憑證。請勿上傳或分享。';
	@override String get deleteBackup => '刪除副本';
	@override String get backupDeleted => '副本已刪除。';
	@override String get previousFailureTitle => 'Plezy 上次啟動失敗';
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
	@override String get title => '探索';
	@override String get selectSource => '選擇來源';
	@override late final _Translations$explore$rows$zh_Hant rows = _Translations$explore$rows$zh_Hant._(_root);
	@override late final _Translations$explore$status$zh_Hant status = _Translations$explore$status$zh_Hant._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		other: '${n} 集',
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
		other: '${n} 筆結果',
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
	@override String get unknownHub => '未知';
	@override String get unknownError => '未知錯誤';
	@override String channelNumber({required Object number}) => '頻道 ${number}';
	@override String get unknownChannel => '未知頻道';
	@override String get live => '直播';
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
	@override String get rulesProcessRequested => '已要求重新評估規則';
	@override String get recordShow => '錄製節目';
	@override late final _Translations$liveTv$recordSettings$zh_Hant recordSettings = _Translations$liveTv$recordSettings$zh_Hant._(_root);
	@override String startingInMinutes({required Object minutes}) => '${minutes} 分鐘後開始';
	@override String dayAtTime({required Object day, required Object time}) => '${day} ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} 傳回了無效的直播電視播放資料';
	@override String get failedToStartChannel => '無法啟動直播頻道';
	@override String get failedToBuildStreamUrl => '無法建立串流 URL';
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
	@override String itemCount({required Object count}) => '${count} 個項目';
	@override String get oneItem => '1 個項目';
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
		other: '${n} 首',
	);
	@override String get nowPlaying => '正在播放';
	@override String playingFrom({required Object title}) => '來自 ${title}';
	@override String get queue => '播放佇列';
	@override String get clearQueue => '清空佇列';
	@override String get lyrics => '歌詞';
	@override String get noLyrics => '目前沒有歌詞';
	@override String get sleepTimer => '睡眠計時器';
	@override String get sleepTimerEndOfTrack => '曲目結束時';
	@override String sleepTimerMinutes({required Object n}) => '${n} 分鐘';
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
	@override String get createSession => '建立「一起看」工作階段';
	@override String get creating => '正在建立…';
	@override String get joinSession => '加入工作階段';
	@override String get joining => '正在加入…';
	@override String get controlMode => '控制模式';
	@override String get controlModeQuestion => '誰可以控制播放？';
	@override String get hostOnly => '僅限主持人';
	@override String get anyone => '任何人';
	@override String get hostingSession => '主持「一起看」';
	@override String get inSession => '在工作階段中';
	@override String get sessionCode => '工作階段代碼';
	@override String get openSessionControls => '開啟「一起看」工作階段控制面板';
	@override String get copySessionCode => '複製工作階段代碼';
	@override String get hostControlsPlayback => '主持人控制播放';
	@override String get anyoneCanControl => '任何人都能控制播放';
	@override String get hostControls => '主持人控制';
	@override String get anyoneControls => '任何人控制';
	@override String get participants => '參與者';
	@override String get host => '主持人';
	@override String get hostBadge => '主持人';
	@override String get youAreHost => '您是主持人';
	@override String get watchingWithOthers => '與他人一起觀看';
	@override String get endSession => '結束工作階段';
	@override String get leaveSession => '離開工作階段';
	@override String get endSessionQuestion => '結束工作階段？';
	@override String get leaveSessionQuestion => '離開工作階段？';
	@override String get endSessionConfirm => '這將為所有參與者結束此「一起看」工作階段。';
	@override String get leaveSessionConfirm => '您將退出此「一起看」工作階段。';
	@override String get endSessionConfirmOverlay => '這將為所有參與者結束觀看工作階段。';
	@override String get leaveSessionConfirmOverlay => '您將中斷與「一起看」工作階段的連線。';
	@override String get end => '結束';
	@override String get leave => '離開';
	@override String get syncing => '同步中…';
	@override String get joinWatchSession => '加入「一起看」工作階段';
	@override String get enterCodeHint => '輸入 5 個英數字元的代碼';
	@override String get pasteFromClipboard => '從剪貼簿貼上';
	@override String get pleaseEnterCode => '請輸入工作階段代碼';
	@override String get codeMustBe5Chars => '工作階段代碼必須為 5 個字元';
	@override String get joinInstructions => '輸入主持人的工作階段代碼以加入「一起看」。';
	@override String get failedToCreate => '建立工作階段失敗';
	@override String get failedToJoin => '加入工作階段失敗';
	@override String get sessionCodeCopied => '工作階段代碼已複製到剪貼簿';
	@override String get relayUnreachable => '無法連線至中繼伺服器。ISP 封鎖可能會導致「一起看」無法使用。';
	@override String get reconnectingToHost => '正在重新連線至主持人…';
	@override String get currentPlayback => '目前播放內容';
	@override String get joinCurrentPlayback => '加入目前播放點';
	@override String get joinCurrentPlaybackDescription => '同步至主持人目前的觀看進度';
	@override String get failedToOpenCurrentPlayback => '無法開啟目前播放點';
	@override String participantJoined({required Object name}) => '${name} 已加入';
	@override String participantLeft({required Object name}) => '${name} 已離開';
	@override String participantPaused({required Object name}) => '${name} 暫停了播放';
	@override String participantResumed({required Object name}) => '${name} 恢復了播放';
	@override String participantSeeked({required Object name}) => '${name} 變更了播放位置';
	@override String participantBuffering({required Object name}) => '${name} 正在緩衝';
	@override String participantNeedsUpdate({required Object name}) => '${name} 正在使用舊版應用程式，無法進行同步';
	@override String resumingWithout({required Object name}) => '不等待 ${name}，繼續播放';
	@override String get waitingForParticipants => '正在等待其他人載入…';
	@override String waitingForName({required Object name}) => '正在等待 ${name}…';
	@override String get recentRooms => '最近的房間';
	@override String get renameRoom => '重新命名房間';
	@override String get removeRoom => '移除';
	@override String get guestSwitchUnavailable => '無法切換 — 伺服器無法進行同步';
	@override String get guestSwitchFailed => '無法切換 — 在此伺服器上找不到內容';
	@override String get defaultDisplayName => '使用者';
	@override late final _Translations$watchTogether$errors$zh_Hant errors = _Translations$watchTogether$errors$zh_Hant._(_root);
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
	@override String get storageFull => '裝置儲存空間已滿，因此下載已停止。請釋出空間後再試一次。';
	@override String episodesQueued({required Object count}) => '已將 ${count} 集影片加入下載佇列';
	@override String get downloadDeleted => '下載內容已刪除';
	@override String deleteConfirm({required Object title}) => '確定要從此裝置刪除「${title}」嗎？';
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
	@override String get deleteAll => '全部刪除';
	@override String get selectVersion => '選擇版本';
	@override String get allEpisodes => '所有單集';
	@override String get unwatchedOnly => '僅未觀看';
	@override String nextNUnwatched({required Object count}) => '接下來 ${count} 集未觀看';
	@override String get customAmount => '自訂數量…';
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
	@override String get activeSyncRules => '同步規則';
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
	@override String get syncRuleNotAvailableForProfile => '目前使用者設定檔無法使用';
	@override String get syncRuleUnknownServer => '未知伺服器';
	@override String get syncRuleListCreated => '同步規則已建立';
	@override late final _Translations$downloads$backgroundWarning$zh_Hant backgroundWarning = _Translations$downloads$backgroundWarning$zh_Hant._(_root);
	@override String get unknownShow => '未知節目';
	@override String get unknownSeason => '未知季度';
	@override String get unknownAlbum => '未知專輯';
	@override String completedOfTotal({required Object completed, required Object total}) => '已完成 ${completed}/${total}';
	@override String get errorFileNotFound => '找不到檔案（404）';
	@override String get errorDownloadFailed => '下載失敗';
	@override String errorPostProcessing({required Object error}) => '後續處理失敗：${error}';
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
	@override String get audioNormalization => '音量標準化';
	@override String get audioDownmix => '下混為立體聲';
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
	@override String get memory => '記憶體';
	@override String get uiFps => 'UI FPS';
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
	@override String get disconnectConfirmBody => 'Plezy 將停止向 Trakt 傳送事件。您可以隨時重新連線。';
	@override String get scrobble => '即時同步記錄（Scrobble）';
	@override String get scrobbleDescription => '在播放時向 Trakt 傳送播放、暫停和停止等狀態。';
	@override String get watchedSync => '同步已觀看狀態';
	@override String get watchedSyncDescription => '在 Plezy 中將項目標記為已觀看時，也會在 Trakt 上標記為已觀看。';
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
	@override String get noSignInMethods => '此 Seerr 執行個體未提供 Plezy 支援的登入方式。';
	@override String get instance => '執行個體';
	@override String get disconnectConfirm => '中斷與 Seerr 的連線？';
	@override String get disconnectConfirmBody => 'Plezy 將忘記此 Seerr 連線資訊。您可以隨時重新連線。';
	@override String get request => '請求';
	@override String get request4k => '請求 4K 版本';
	@override String get seasons => '季';
	@override String get allSeasons => '所有季數';
	@override String get advancedOptions => '進階設定';
	@override String get destinationServer => '目標伺服器';
	@override String get qualityProfile => '畫質設定檔（Quality Profile）';
	@override String get rootFolder => '根目錄資料夾';
	@override String get languageProfile => '語言設定檔（Language Profile）';
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
	@override String disconnectConfirmBody({required Object service}) => 'Plezy 將停止更新 ${service}。您可以隨時重新連線。';
	@override String connectFailed({required Object service}) => '無法連線至 ${service}。請重試。';
	@override late final _Translations$services$names$zh_Hant names = _Translations$services$names$zh_Hant._(_root);
	@override late final _Translations$services$deviceCode$zh_Hant deviceCode = _Translations$services$deviceCode$zh_Hant._(_root);
	@override late final _Translations$services$oauthProxy$zh_Hant oauthProxy = _Translations$services$oauthProxy$zh_Hant._(_root);
	@override late final _Translations$services$pendingAuth$zh_Hant pendingAuth = _Translations$services$pendingAuth$zh_Hant._(_root);
	@override late final _Translations$services$libraryFilter$zh_Hant libraryFilter = _Translations$services$libraryFilter$zh_Hant._(_root);
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
}

// Path: common.ratingSource
class _Translations$common$ratingSource$zh_Hant extends Translations$common$ratingSource$zh {
	_Translations$common$ratingSource$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get critic => '影評人';
	@override String get audience => '觀眾';
	@override String get imdb => 'IMDb';
	@override String get tmdb => 'TMDB';
	@override String get rottenTomatoes => 'Rotten Tomatoes';
	@override String get simkl => 'Simkl';
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get trakt => 'Trakt';
	@override String get rottenTomatoesCritic => 'Rotten Tomatoes 影評人';
	@override String get rottenTomatoesAudience => 'Rotten Tomatoes 觀眾';
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
	@override String get shaderToggle => '切換著色器';
	@override String get skipMarker => '跳過片頭/片尾';
	@override String get screenshot => '螢幕截圖';
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
		other: '${n} 則留言',
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
		other: '${n} 位使用者推薦',
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

// Path: watchTogether.errors
class _Translations$watchTogether$errors$zh_Hant extends Translations$watchTogether$errors$zh {
	_Translations$watchTogether$errors$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get timedOut => '中繼伺服器未及時回應';
	@override String get connectionLost => '工作階段就緒前連線已中斷';
	@override String get invalidRelayResponse => '中繼伺服器傳回了非預期的回應';
	@override String get sessionEnded => '主持人已結束工作階段';
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
	@override String get sheetIntro => 'Android 正在阻止 Plezy 在背景穩定下載。';
	@override String get sheetIntroDegraded => '你的裝置限制了 Plezy 可在背景下載的時機。';
	@override String get reasonBackgroundRestricted => 'Plezy 的背景使用受限。請將其電池用量或背景使用設定為「無限制」。';
	@override String get reasonStandbyRestricted => 'Android 已將 Plezy 設為受限待命狀態。請將電池用量設為「無限制」。';
	@override String get reasonDownloadChannelBlocked => '下載通知已關閉，因此可能無法查看進度或使用控制項。';
	@override String get reasonNotificationsDisabled => '通知已關閉。在 Android 13 或更新版本中，長時間背景下載需要啟用通知。';
	@override String get reasonDataSaver => '已開啟數據節省模式，因此系統會封鎖使用行動數據的背景下載。透過 Wi-Fi 下載應仍可正常執行。';
	@override String get reasonOemUnknown => 'Plezy 在背景執行時，下載屢次停止。請檢查 Plezy 的電池用量或背景使用設定。';
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
	@override String get discoveryDescription => '使用相同 Plex 帳戶的 Plezy 裝置會顯示在此處';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => '正在連線…';
	@override String get searchingForDevices => '正在搜尋裝置…';
	@override String get noDevicesFound => '在區域網路上找不到裝置';
	@override String get noDevicesHint => '請在電腦上開啟 Plezy，並確認兩台裝置使用相同的 Wi-Fi 網路';
	@override String get availableDevices => '可用裝置';
	@override String get manualConnection => '手動連線';
	@override String get cryptoInitFailed => '無法啟動安全連線。請先登入 Plex。';
	@override String get validationHostRequired => '請輸入主機位址';
	@override String get validationHostFormat => '格式必須為 IP 位址:連接埠（例如 192.168.1.100:48632）';
	@override String get connectionTimedOut => '連線逾時。請確認兩台裝置都使用相同網路。';
	@override String get sessionNotFound => '找不到裝置。請確認主機上已啟動 Plezy。';
	@override String get authFailed => '驗證失敗。兩台裝置需要登入相同的 Plex 帳戶。';
	@override String failedToConnect({required Object error}) => '連線失敗：${error}';
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

// Path: services.deviceCode
class _Translations$services$deviceCode$zh_Hant extends Translations$services$deviceCode$zh {
	_Translations$services$deviceCode$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '在 ${service} 啟用 Plezy';
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
}

/// The flat map containing all translations for locale <zh-Hant>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsZhHant {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Plezy',
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
			'auth.localDataRecoveryRequired' => 'Plezy 無法安全地復原本機登入資料與待處理的播放資料。請重新登入。',
			'auth.pinCheckRejected' => 'Plex PIN 檢查遭到拒絕',
			'common.cancel' => '取消',
			'common.save' => '儲存',
			'common.close' => '關閉',
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
			'common.ratingSource.critic' => '影評人',
			'common.ratingSource.audience' => '觀眾',
			'common.ratingSource.imdb' => 'IMDb',
			'common.ratingSource.tmdb' => 'TMDB',
			'common.ratingSource.rottenTomatoes' => 'Rotten Tomatoes',
			'common.ratingSource.simkl' => 'Simkl',
			'common.ratingSource.mal' => 'MyAnimeList',
			'common.ratingSource.anilist' => 'AniList',
			'common.ratingSource.trakt' => 'Trakt',
			'common.ratingSource.rottenTomatoesCritic' => 'Rotten Tomatoes 影評人',
			'common.ratingSource.rottenTomatoesAudience' => 'Rotten Tomatoes 觀眾',
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
			'screens.mpvConfig' => 'mpv.conf 設定',
			'screens.logs' => '日誌',
			'update.available' => '有可用更新',
			'update.versionAvailable' => ({required Object version}) => '版本 ${version} 已發佈',
			'update.currentVersion' => ({required Object version}) => '目前版本：${version}',
			'update.skipVersion' => '跳過此版本',
			'update.viewRelease' => '查看版本詳情',
			'update.latestVersion' => '已安裝的版本為最新版本',
			'update.checkFailed' => '無法檢查更新',
			'settings.title' => '設定',
			'settings.supportDeveloper' => '贊助 Plezy',
			'settings.supportDeveloperDescription' => '透過 Liberapay 捐款支持開發者',
			'settings.language' => '語言',
			'settings.theme' => '主題',
			'settings.appearance' => '外觀',
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
			'settings.defaultQualityTitle' => '預設畫質',
			'settings.cellularQualityTitle' => '行動網路上的預設畫質',
			'settings.cellularQualitySameAsDefault' => '與預設畫質相同',
			'settings.musicQualityTitle' => '音樂品質',
			'settings.subtitleStyling' => '字幕樣式',
			'settings.subtitleStylingDescription' => '調整字幕外觀',
			'settings.smallSkipDuration' => '短跳過時間',
			'settings.largeSkipDuration' => '長跳過時間',
			'settings.rewindOnResume' => '繼續播放時稍微倒轉',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} 秒',
			'settings.defaultSleepTimer' => '預設睡眠計時器',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} 分鐘',
			'settings.rememberTrackSelections' => '記住每部影集或電影的音訊與字幕選擇',
			'settings.rememberTrackSelectionsDescription' => '記住每部影片的音軌與字幕選擇',
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
			'settings.watchTogetherRelayDescription' => '設定自訂中繼。所有人必須使用相同的伺服器。',
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
			'settings.importSettingsInvalidFile' => '此檔案不是有效的 Plezy 設定匯出檔',
			'settings.importSettingsNoUser' => '匯入設定前請先登入',
			'settings.shortcutsReset' => '快速鍵已重設為預設值',
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
			'settings.playNextCountdown' => '下一集倒數計時',
			'settings.playNextCountdownImmediate' => '立即播放',
			'settings.autoSkipIntro' => '自動跳過片頭',
			'settings.autoSkipIntroDescription' => '幾秒鐘後自動跳過片頭標記',
			'settings.autoSkipCredits' => '自動跳過片尾',
			'settings.autoSkipCreditsDescription' => '自動跳過片尾並播放下一集',
			'settings.forceSkipMarkerFallback' => '強制使用備用標記',
			'settings.forceSkipMarkerFallbackDescription' => '即使 Plex 有標記，也強制使用章節標題模式',
			'settings.autoSkipDelay' => '自動跳過延遲',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => '自動跳過前等待 ${seconds} 秒',
			'settings.introPattern' => '片頭標記模式',
			'settings.introPatternDescription' => '用於比對章節標題中片頭標記的正規表示式',
			'settings.creditsPattern' => '片尾標記模式',
			'settings.creditsPatternDescription' => '用於比對章節標題中片尾標記的正規表示式',
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
			'settings.tunneledPlaybackDescription' => '使用影片通道模式。若 HDR 播放出現黑畫面，請停用此項。',
			'settings.audioPassthrough' => '音訊直通',
			'settings.audioPassthroughDescription' => '將 Dolby/DTS 音訊不經重新編碼，直接傳送至擴大機或電視以保留環繞音效。若播放無聲，請關閉此設定。',
			'settings.audioPassthroughDescriptionAppleTv' => '使用 Apple 原生 Dolby 解碼器處理 Dolby Digital Plus（包括 Atmos）。DTS 與 TrueHD 仍以多聲道 PCM 播放。若沒有聲音，請關閉此設定。',
			'settings.audioDownmix' => '下混為立體聲',
			'settings.audioDownmixDescription' => '將環繞音效混合為雙聲道，適用於立體聲喇叭或耳機',
			'settings.downmixCenterBoost' => '中置聲道增強',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => '增強（dB）',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => '下混時音量標準化',
			'settings.audioDownmixNormalizeDescription' => '降低混音電平以防止破音。關閉以保持原始音量（大音量場景可能會失真）。',
			'settings.dvConversionMode' => 'Dolby Vision 轉換模式',
			'settings.dvConversionModeDescription' => '選擇 ExoPlayer 如何處理 Dolby Vision Profile 7 檔案。',
			'settings.dvConversionAuto' => '自動',
			'settings.dvConversionNative' => '原生 / 停用',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => '自動偵測裝置相容性並使用一般備援機制',
			'settings.dvConversionNativeDescription' => '強制使用原生 DV7 並停用 DV 轉換重試',
			'settings.dvConversionDv81Description' => '強制將內嵌的 RPU 轉換為 Dolby Vision Profile 8.1',
			'settings.dvConversionHevcStripDescription' => '移除 Dolby Vision RPU/EL 層，並以一般 HEVC 呈現',
			'settings.deinterlace' => '去交錯',
			'settings.deinterlaceDescription' => '移除交錯影片中的梳狀雜訊（僅限 mpv 播放器）',
			'settings.requireProfileSelectionOnOpen' => '開啟應用程式時要求選擇使用者',
			'settings.requireProfileSelectionOnOpenDescription' => '每次開啟應用程式時顯示使用者設定檔選擇畫面',
			'settings.forceTvMode' => '強制 TV 模式',
			'settings.forceTvModeDescription' => '強制使用 TV 介面版面。適用於無法自動辨識 TV 的裝置。需要重新啟動。',
			'settings.startInFullscreen' => '以全螢幕模式啟動',
			'settings.startInFullscreenDescription' => '啟動時直接以全螢幕開啟 Plezy',
			'settings.exitFullscreenOnPlayerClose' => '關閉播放器時退出全螢幕',
			'settings.exitFullscreenOnPlayerCloseDescription' => '關閉影片播放器時自動退出全螢幕模式',
			'settings.autoHidePerformanceOverlay' => '自動隱藏效能疊加層',
			'settings.autoHidePerformanceOverlayDescription' => '效能疊加層隨播放控制面板一起淡入或淡出',
			'settings.showNavBarLabels' => '顯示導覽列標籤',
			'settings.showNavBarLabelsDescription' => '在導覽列圖示下方顯示文字標籤',
			'settings.startupSection' => '啟動頁面',
			'settings.showExploreTab' => '顯示探索分頁',
			'settings.showExploreTabDescription' => '顯示探索分頁，其中包含來自 Plex Discover 和已連結追蹤服務的內容',
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
			'settings.exportDialogTitle' => '匯出 Plezy 設定',
			'settings.linuxVideoRenderMode' => '影片轉譯模式',
			'settings.linuxVideoRenderModeDescription' => '自動偏好原生 Wayland 平面（支援 HDR）；紋理強制使用 SDR 備援路徑。',
			'settings.linuxVideoRenderModeAuto' => '自動',
			'settings.linuxVideoRenderModeTexture' => '紋理（SDR）',
			'search.hint' => '搜尋電影、影集、音樂…',
			'search.tryDifferentTerm' => '嘗試不同的關鍵字',
			'search.searchYourMedia' => '搜尋媒體庫',
			'search.enterTitleActorOrKeyword' => '輸入標題、演員或關鍵字',
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
			'hotkeys.actions.shaderToggle' => '切換著色器',
			'hotkeys.actions.skipMarker' => '跳過片頭/片尾',
			'hotkeys.actions.screenshot' => '螢幕截圖',
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
			_ => null,
		} ?? switch (path) {
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
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '這會刪除其中全部 ${n} 集及其檔案。', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '此項目分散儲存於 ${n} 個檔案中，且全部都會被刪除。', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '另有 ${n} 集儲存在同一檔案中，也會一併被刪除：', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'Plezy 無法確認此操作會刪除哪些檔案，因此刪除範圍可能超出上方所列的項目。請取消後重試，或仍要刪除。',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => '您的伺服器未提供此項目的檔案資訊，因此 Plezy 無法確認此操作會刪除哪些檔案。刪除範圍可能超出上方所列的項目。',
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
			'accessibility.valueShort' => 'V',
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
			'videoControls.lockScreen' => '鎖定螢幕',
			'videoControls.screenLockButton' => '螢幕鎖定',
			'videoControls.longPressToUnlock' => '長按解鎖',
			'videoControls.timelineSlider' => '影片時間軸',
			'videoControls.volumeSlider' => '音量調整',
			'videoControls.endsAt' => ({required Object time}) => '預計 ${time} 結束',
			'videoControls.pipActive' => '正在以子母畫面模式播放',
			'videoControls.pipFailed' => '啟動子母畫面失敗',
			'videoControls.screenshotSaved' => '螢幕截圖已儲存',
			'videoControls.zoomPercent' => ({required Object percent}) => '縮放 ${percent}%',
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
			'messages.markedAsWatched' => '已標記為已觀看',
			'messages.markedAsUnwatched' => '已標記為未觀看',
			'messages.markedAsWatchedOffline' => '已標記為已觀看（將在連線時同步）',
			'messages.markedAsUnwatchedOffline' => '已標記為未觀看（將在連線時同步）',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => '已自動移除：${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '已自動移除 ${n} 個已觀看的下載內容', ), 
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
			'messages.logsUploaded' => '日誌已上傳',
			'messages.logsUploadFailed' => '上傳日誌失敗',
			'messages.logId' => '日誌 ID',
			'messages.burnedSubtitlesUseMenu' => '字幕已燒錄至此串流中。請從字幕選單變更字幕。',
			'messages.noVideoUrl' => '沒有可用的視訊 URL',
			'messages.playbackNoMediaSources' => '伺服器未傳回可播放的媒體來源',
			'messages.playbackDataNotPrepared' => '播放資料尚未準備完成就已開始播放',
			'messages.streamSelectionUnavailable' => '此來源不支援選擇串流',
			'messages.streamSelectionFailed' => '無法套用所選串流',
			'messages.serverUnavailableForProfile' => '使用中的使用者設定檔沒有可用的伺服器',
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
			'subtitlingStyling.anchorToScreen' => '錨定至螢幕',
			'subtitlingStyling.anchorToScreenDescription' => '在寬螢幕影片下方的黑邊顯示文字字幕',
			'subtitlingStyling.bold' => '粗體',
			'subtitlingStyling.italic' => '斜體',
			'subtitlingStyling.renderResolution' => '渲染解析度',
			'subtitlingStyling.renderResolutionScreen' => '螢幕解析度',
			'subtitlingStyling.renderResolutionVideo' => '影片解析度',
			'mpvConfig.title' => 'mpv 設定',
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
			'mpvConfig.embeddedVoHint' => '在 Linux 上會忽略 vo、gpu-context 和 gpu-api：嵌入式影片一律透過影片平面上的 vo=libmpv 轉譯，而 gpu-next（ArtCNN 等計算著色器需要它）無法以嵌入式方式執行。',
			'dialog.confirmAction' => '確認操作',
			'profiles.addPlezyProfile' => '新增 Plezy 使用者設定檔',
			'profiles.switchingProfile' => '正在切換使用者設定檔…',
			'profiles.deleteThisProfileTitle' => '刪除此使用者設定檔？',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => '將移除 ${displayName}。連線資訊將不受影響。',
			'profiles.active' => '使用中',
			'profiles.manage' => '管理',
			'profiles.delete' => '刪除',
			'profiles.signOut' => '登出',
			'profiles.signOutPlexTitle' => '登出 Plex？',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => '確定要移除 ${displayName} 與所有 Plex Home 使用者嗎？您可以隨時重新登入。',
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
			'profiles.borrowEmptySubtitle' => '請先將 Plex 或 Jellyfin 連線至另一個使用者設定檔。',
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
			'connections.sectionTitle' => '連線',
			'connections.addConnection' => '新增連線',
			'connections.addConnectionSubtitleNoProfile' => '使用 Plex 登入或連線至 Jellyfin 伺服器',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => '新增至 ${displayName}：Plex、Jellyfin 或其他設定檔連線',
			'connections.sessionExpiredOne' => ({required Object name}) => '${name} 的工作階段已過期',
			'connections.sessionExpiredMany' => ({required Object count}) => '${count} 個伺服器的工作階段已過期',
			'connections.signInAgain' => '重新登入',
			'connections.editMediaBrowserTitle' => ({required Object product}) => '編輯 ${product} 連線',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => '為 ${serverName} 新增或移除 URL。Plezy 將使用延遲最低且可連線的 URL。',
			'accountPreferences.sectionTitle' => '帳戶偏好設定',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => '已在 ${account} 上儲存音訊、字幕與媒體庫選項',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => '已在 ${count} 個帳戶上儲存音訊、字幕與媒體庫選項',
			'accountPreferences.pickAccount' => '每個帳戶都會儲存各自的偏好設定。請選擇要編輯的帳戶。',
			'accountPreferences.storedOnAccount' => '這些選項會儲存在帳戶本身，因此登入該帳戶的所有應用程式都會使用它們，包括您其他裝置上的 Plezy。',
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
			'accountPreferences.forcedSubtitles' => '強制字幕',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => '偏好非強制字幕',
			'accountPreferences.forcedSubtitleOptions.preferForced' => '偏好強制字幕',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => '僅強制字幕',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => '僅非強制字幕',
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
			'accountPreferences.mediaReviewsVisibility' => '評分與評論',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => '使用者與影評人',
			'accountPreferences.mediaReviewsOptions.usersOnly' => '僅使用者',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => '僅影評人',
			'accountPreferences.mediaReviewsOptions.nobody' => '隱藏',
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
			'discover.extras' => '預告片與花絮',
			'discover.studio' => '製作商',
			'discover.rating' => '分級',
			'discover.director' => '導演',
			'discover.directors' => '導演',
			'discover.movie' => '電影',
			'discover.tvShow' => '影集',
			'discover.minutesLeft' => ({required Object minutes}) => '剩餘 ${minutes} 分鐘',
			'discover.moreLikeThis' => '更多類似內容',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '${n} 部作品', ), 
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
			_ => null,
		} ?? switch (path) {
			'libraries.filterCategories.year' => '年份',
			'libraries.filterCategories.contentRating' => '分級',
			'libraries.filterCategories.tag' => '標籤',
			'libraries.filterCategories.unwatched' => '未觀看',
			'libraries.filterCategories.unplayed' => '未播放',
			'libraries.filterCategories.favorites' => '我的最愛',
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
			'about.title' => '關於',
			'about.openSourceLicenses' => '開源授權條款',
			'about.versionLabel' => ({required Object version}) => '版本 ${version}',
			'about.appDescription' => '一款精美的 Plex 與 Jellyfin Flutter 用戶端',
			'about.viewLicensesDescription' => '查看第三方套件的授權條款',
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
			'startup.failedTitle' => 'Plezy 無法啟動',
			'startup.failedBody' => '啟動期間發生問題。下方詳細資料可識別失敗的原因。',
			'startup.failedBodyRepairable' => 'Plezy 儲存的設定檔已損壞，必須先重建才能啟動。重試無法解決問題 — 請選擇「修復儲存空間」。',
			'startup.phaseLabel' => '步驟',
			'startup.showDetails' => '顯示詳細資料',
			'startup.hideDetails' => '隱藏詳細資料',
			'startup.copyDetails' => '複製詳細資料',
			'startup.detailsCopied' => '詳細資料已複製到剪貼簿',
			'startup.uploadDetails' => '上傳詳細資料',
			'startup.repairStorage' => '修復儲存空間',
			'startup.repairTitle' => '修復已儲存的資料？',
			'startup.repairBodyCommon' => 'Plezy 的設定檔已損壞且無法讀取。修復會將所有設定重設為預設值。',
			'startup.repairBodyOneCredential' => '有一筆已儲存的登入資訊損壞且無法讀取。修復僅會移除該筆資訊，其他設定將保持不變。',
			'startup.repairBodySignInsKept' => '您的伺服器與使用者設定檔應可保持登入狀態。',
			'startup.repairBodySignInsLost' => '保護已儲存登入資訊的金鑰無法從此檔案中復原，因此您必須重新登入每個伺服器與使用者設定檔。您媒體伺服器上的內容不受影響。',
			'startup.repairBodySessionsUncertain' => '追蹤服務（MAL、AniList、Simkl、Trakt）與 Seerr 分別儲存，可能保留也可能遺失。Plezy 會明確告知保留了哪些項目。',
			'startup.repairConfirm' => '修復',
			'startup.repairSucceeded' => '儲存空間已修復',
			'startup.repairNeedsRestart' => '儲存空間已修復 — 需要重新啟動',
			'startup.restartRequiredBody' => '您的資料已修復，但 Plezy 必須重新啟動才能使用。請關閉 Plezy 後重新開啟。',
			'startup.quitPlezy' => '退出 Plezy',
			'startup.repairFailed' => '修復失敗',
			'startup.repairKeptSignIns' => '您的伺服器與使用者設定檔仍保持登入狀態。',
			'startup.repairLostSignIns' => '保護已儲存登入資訊的金鑰無法復原。您必須重新登入每個伺服器與使用者設定檔。',
			'startup.repairLostSessions' => '至少一個追蹤服務或 Seerr 連線已遺失，必須重新連線。',
			'startup.backupTitle' => '已保留損壞檔案的副本',
			'startup.backupWarning' => '其中包含您的登入憑證。請勿上傳或分享。',
			'startup.deleteBackup' => '刪除副本',
			'startup.backupDeleted' => '副本已刪除。',
			'startup.previousFailureTitle' => 'Plezy 上次啟動失敗',
			'licenses.relatedPackages' => '相關套件',
			'licenses.license' => '授權',
			'licenses.licenseNumber' => ({required Object number}) => '授權條款 ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} 個授權條款',
			'navigation.libraries' => '媒體庫',
			'navigation.downloads' => '下載',
			'navigation.liveTv' => '直播電視',
			'navigation.explore' => '探索',
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
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '${n} 集', ), 
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
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '${n} 則留言', ), 
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
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '${n} 位使用者推薦', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => '由 ${who} 推薦',
			'explore.detail.favoritedBy' => ({required Object who}) => '由 ${who} 收藏',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '尚有 ${n} 集未播出',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => '${percent} 的觀眾推薦',
			'explore.detail.relatedTitles' => '相關作品',
			'explore.detail.background' => '背景介紹',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '${n} 筆結果', ), 
			'liveTv.title' => '直播電視',
			'liveTv.guide' => '節目表指南',
			'liveTv.noChannels' => '沒有可用的頻道',
			'liveTv.noDvr' => '沒有伺服器設定 DVR 錄影機',
			'liveTv.serverUnavailable' => '直播電視伺服器無法使用。',
			'liveTv.serverNotConnected' => '直播電視伺服器未連線。',
			'liveTv.noPrograms' => '沒有可用的節目資料',
			'liveTv.liveStreamFailed' => '即時串流失敗',
			'liveTv.unknownProgram' => '未知節目',
			'liveTv.unknownHub' => '未知',
			'liveTv.unknownError' => '未知錯誤',
			'liveTv.channelNumber' => ({required Object number}) => '頻道 ${number}',
			'liveTv.unknownChannel' => '未知頻道',
			'liveTv.live' => '直播',
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
			'liveTv.rulesProcessRequested' => '已要求重新評估規則',
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
			'playlists.itemCount' => ({required Object count}) => '${count} 個項目',
			'playlists.oneItem' => '1 個項目',
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
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '${n} 首', ), 
			'music.nowPlaying' => '正在播放',
			'music.playingFrom' => ({required Object title}) => '來自 ${title}',
			'music.queue' => '播放佇列',
			'music.clearQueue' => '清空佇列',
			'music.lyrics' => '歌詞',
			'music.noLyrics' => '目前沒有歌詞',
			'music.sleepTimer' => '睡眠計時器',
			'music.sleepTimerEndOfTrack' => '曲目結束時',
			'music.sleepTimerMinutes' => ({required Object n}) => '${n} 分鐘',
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
			'watchTogether.createSession' => '建立「一起看」工作階段',
			'watchTogether.creating' => '正在建立…',
			'watchTogether.joinSession' => '加入工作階段',
			'watchTogether.joining' => '正在加入…',
			'watchTogether.controlMode' => '控制模式',
			'watchTogether.controlModeQuestion' => '誰可以控制播放？',
			'watchTogether.hostOnly' => '僅限主持人',
			'watchTogether.anyone' => '任何人',
			'watchTogether.hostingSession' => '主持「一起看」',
			'watchTogether.inSession' => '在工作階段中',
			'watchTogether.sessionCode' => '工作階段代碼',
			'watchTogether.openSessionControls' => '開啟「一起看」工作階段控制面板',
			'watchTogether.copySessionCode' => '複製工作階段代碼',
			'watchTogether.hostControlsPlayback' => '主持人控制播放',
			'watchTogether.anyoneCanControl' => '任何人都能控制播放',
			'watchTogether.hostControls' => '主持人控制',
			'watchTogether.anyoneControls' => '任何人控制',
			'watchTogether.participants' => '參與者',
			'watchTogether.host' => '主持人',
			'watchTogether.hostBadge' => '主持人',
			'watchTogether.youAreHost' => '您是主持人',
			'watchTogether.watchingWithOthers' => '與他人一起觀看',
			'watchTogether.endSession' => '結束工作階段',
			'watchTogether.leaveSession' => '離開工作階段',
			'watchTogether.endSessionQuestion' => '結束工作階段？',
			'watchTogether.leaveSessionQuestion' => '離開工作階段？',
			'watchTogether.endSessionConfirm' => '這將為所有參與者結束此「一起看」工作階段。',
			'watchTogether.leaveSessionConfirm' => '您將退出此「一起看」工作階段。',
			'watchTogether.endSessionConfirmOverlay' => '這將為所有參與者結束觀看工作階段。',
			'watchTogether.leaveSessionConfirmOverlay' => '您將中斷與「一起看」工作階段的連線。',
			'watchTogether.end' => '結束',
			'watchTogether.leave' => '離開',
			'watchTogether.syncing' => '同步中…',
			'watchTogether.joinWatchSession' => '加入「一起看」工作階段',
			'watchTogether.enterCodeHint' => '輸入 5 個英數字元的代碼',
			'watchTogether.pasteFromClipboard' => '從剪貼簿貼上',
			'watchTogether.pleaseEnterCode' => '請輸入工作階段代碼',
			'watchTogether.codeMustBe5Chars' => '工作階段代碼必須為 5 個字元',
			'watchTogether.joinInstructions' => '輸入主持人的工作階段代碼以加入「一起看」。',
			'watchTogether.failedToCreate' => '建立工作階段失敗',
			'watchTogether.failedToJoin' => '加入工作階段失敗',
			'watchTogether.sessionCodeCopied' => '工作階段代碼已複製到剪貼簿',
			'watchTogether.relayUnreachable' => '無法連線至中繼伺服器。ISP 封鎖可能會導致「一起看」無法使用。',
			'watchTogether.reconnectingToHost' => '正在重新連線至主持人…',
			'watchTogether.currentPlayback' => '目前播放內容',
			'watchTogether.joinCurrentPlayback' => '加入目前播放點',
			'watchTogether.joinCurrentPlaybackDescription' => '同步至主持人目前的觀看進度',
			'watchTogether.failedToOpenCurrentPlayback' => '無法開啟目前播放點',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} 已加入',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} 已離開',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} 暫停了播放',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} 恢復了播放',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} 變更了播放位置',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} 正在緩衝',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name} 正在使用舊版應用程式，無法進行同步',
			'watchTogether.resumingWithout' => ({required Object name}) => '不等待 ${name}，繼續播放',
			'watchTogether.waitingForParticipants' => '正在等待其他人載入…',
			'watchTogether.waitingForName' => ({required Object name}) => '正在等待 ${name}…',
			'watchTogether.recentRooms' => '最近的房間',
			'watchTogether.renameRoom' => '重新命名房間',
			'watchTogether.removeRoom' => '移除',
			'watchTogether.guestSwitchUnavailable' => '無法切換 — 伺服器無法進行同步',
			'watchTogether.guestSwitchFailed' => '無法切換 — 在此伺服器上找不到內容',
			'watchTogether.defaultDisplayName' => '使用者',
			'watchTogether.errors.timedOut' => '中繼伺服器未及時回應',
			'watchTogether.errors.connectionLost' => '工作階段就緒前連線已中斷',
			'watchTogether.errors.invalidRelayResponse' => '中繼伺服器傳回了非預期的回應',
			'watchTogether.errors.sessionEnded' => '主持人已結束工作階段',
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
			'downloads.storageFull' => '裝置儲存空間已滿，因此下載已停止。請釋出空間後再試一次。',
			'downloads.episodesQueued' => ({required Object count}) => '已將 ${count} 集影片加入下載佇列',
			'downloads.downloadDeleted' => '下載內容已刪除',
			'downloads.deleteConfirm' => ({required Object title}) => '確定要從此裝置刪除「${title}」嗎？',
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
			'downloads.deleteAll' => '全部刪除',
			'downloads.selectVersion' => '選擇版本',
			'downloads.allEpisodes' => '所有單集',
			'downloads.unwatchedOnly' => '僅未觀看',
			'downloads.nextNUnwatched' => ({required Object count}) => '接下來 ${count} 集未觀看',
			'downloads.customAmount' => '自訂數量…',
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
			_ => null,
		} ?? switch (path) {
			'downloads.syncRuleCleanupBusy' => '同步規則正在更新中。請稍後再試。',
			'downloads.syncRuleCleanupUnavailable' => '無法安全地識別相關的下載內容。請重新連線伺服器後再試，或在不刪除下載內容的情況下移除規則。',
			'downloads.syncedNewEpisodes' => ({required Object title, required Object count}) => '已為 ${title} 同步 ${count} 個新單集',
			'downloads.activeSyncRules' => '同步規則',
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
			'downloads.syncRuleNotAvailableForProfile' => '目前使用者設定檔無法使用',
			'downloads.syncRuleUnknownServer' => '未知伺服器',
			'downloads.syncRuleListCreated' => '同步規則已建立',
			'downloads.backgroundWarning.bannerBlocked' => '離開應用程式後，下載將會停止',
			'downloads.backgroundWarning.bannerDegraded' => '背景下載可能受限',
			'downloads.backgroundWarning.bannerAction' => '詳細資料',
			'downloads.backgroundWarning.sheetTitle' => '背景下載遭到封鎖',
			'downloads.backgroundWarning.sheetTitleDegraded' => '背景下載可能受限',
			'downloads.backgroundWarning.sheetIntro' => 'Android 正在阻止 Plezy 在背景穩定下載。',
			'downloads.backgroundWarning.sheetIntroDegraded' => '你的裝置限制了 Plezy 可在背景下載的時機。',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'Plezy 的背景使用受限。請將其電池用量或背景使用設定為「無限制」。',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android 已將 Plezy 設為受限待命狀態。請將電池用量設為「無限制」。',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => '下載通知已關閉，因此可能無法查看進度或使用控制項。',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => '通知已關閉。在 Android 13 或更新版本中，長時間背景下載需要啟用通知。',
			'downloads.backgroundWarning.reasonDataSaver' => '已開啟數據節省模式，因此系統會封鎖使用行動數據的背景下載。透過 Wi-Fi 下載應仍可正常執行。',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Plezy 在背景執行時，下載屢次停止。請檢查 Plezy 的電池用量或背景使用設定。',
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
			'downloads.unknownShow' => '未知節目',
			'downloads.unknownSeason' => '未知季度',
			'downloads.unknownAlbum' => '未知專輯',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '已完成 ${completed}/${total}',
			'downloads.errorFileNotFound' => '找不到檔案（404）',
			'downloads.errorDownloadFailed' => '下載失敗',
			'downloads.errorPostProcessing' => ({required Object error}) => '後續處理失敗：${error}',
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
			'companionRemote.pairing.discoveryDescription' => '使用相同 Plex 帳戶的 Plezy 裝置會顯示在此處',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => '正在連線…',
			'companionRemote.pairing.searchingForDevices' => '正在搜尋裝置…',
			'companionRemote.pairing.noDevicesFound' => '在區域網路上找不到裝置',
			'companionRemote.pairing.noDevicesHint' => '請在電腦上開啟 Plezy，並確認兩台裝置使用相同的 Wi-Fi 網路',
			'companionRemote.pairing.availableDevices' => '可用裝置',
			'companionRemote.pairing.manualConnection' => '手動連線',
			'companionRemote.pairing.cryptoInitFailed' => '無法啟動安全連線。請先登入 Plex。',
			'companionRemote.pairing.validationHostRequired' => '請輸入主機位址',
			'companionRemote.pairing.validationHostFormat' => '格式必須為 IP 位址:連接埠（例如 192.168.1.100:48632）',
			'companionRemote.pairing.connectionTimedOut' => '連線逾時。請確認兩台裝置都使用相同網路。',
			'companionRemote.pairing.sessionNotFound' => '找不到裝置。請確認主機上已啟動 Plezy。',
			'companionRemote.pairing.authFailed' => '驗證失敗。兩台裝置需要登入相同的 Plex 帳戶。',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => '連線失敗：${error}',
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
			'videoSettings.audioNormalization' => '音量標準化',
			'videoSettings.audioDownmix' => '下混為立體聲',
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
			'performanceOverlay.memory' => '記憶體',
			'performanceOverlay.uiFps' => 'UI FPS',
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
			'metadataEdit.addTag' => '新增標籤',
			'metadataEdit.genre' => '類型',
			'metadataEdit.director' => '導演',
			'metadataEdit.writer' => '編劇',
			'metadataEdit.producer' => '製片',
			'metadataEdit.country' => '國家/地區',
			'metadataEdit.collection' => '收藏集',
			'metadataEdit.label' => '標記',
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
			'trakt.disconnectConfirmBody' => 'Plezy 將停止向 Trakt 傳送事件。您可以隨時重新連線。',
			'trakt.scrobble' => '即時同步記錄（Scrobble）',
			'trakt.scrobbleDescription' => '在播放時向 Trakt 傳送播放、暫停和停止等狀態。',
			'trakt.watchedSync' => '同步已觀看狀態',
			'trakt.watchedSyncDescription' => '在 Plezy 中將項目標記為已觀看時，也會在 Trakt 上標記為已觀看。',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => '連線至 Seerr',
			'seerr.serverUrl' => '伺服器 URL',
			'seerr.serverUrlHelper' => '您的 Seerr 執行個體的連線位址',
			'seerr.checkServer' => '繼續',
			'seerr.signInWithJellyfin' => '使用 Jellyfin 登入',
			'seerr.signInWithEmby' => '使用 Emby 登入',
			'seerr.signInWithLocal' => '使用本地帳戶',
			'seerr.email' => '電子郵件',
			'seerr.noSignInMethods' => '此 Seerr 執行個體未提供 Plezy 支援的登入方式。',
			'seerr.instance' => '執行個體',
			'seerr.disconnectConfirm' => '中斷與 Seerr 的連線？',
			'seerr.disconnectConfirmBody' => 'Plezy 將忘記此 Seerr 連線資訊。您可以隨時重新連線。',
			'seerr.request' => '請求',
			'seerr.request4k' => '請求 4K 版本',
			'seerr.seasons' => '季',
			'seerr.allSeasons' => '所有季數',
			'seerr.advancedOptions' => '進階設定',
			'seerr.destinationServer' => '目標伺服器',
			'seerr.qualityProfile' => '畫質設定檔（Quality Profile）',
			'seerr.rootFolder' => '根目錄資料夾',
			'seerr.languageProfile' => '語言設定檔（Language Profile）',
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
			'services.title' => '外部服務',
			'services.hubSubtitle' => '同步觀看進度並請求新內容。',
			'services.integrations' => '整合',
			'services.notConnected' => '未連線',
			'services.connectedAs' => ({required Object username}) => '已以 @${username} 身分連線',
			'services.scrobble' => '自動同步播放進度',
			'services.scrobbleDescription' => '觀賞完一集或一部電影後自動更新您的外部列表。',
			'services.disconnectConfirm' => ({required Object service}) => '中斷與 ${service} 的連線？',
			'services.disconnectConfirmBody' => ({required Object service}) => 'Plezy 將停止更新 ${service}。您可以隨時重新連線。',
			'services.connectFailed' => ({required Object service}) => '無法連線至 ${service}。請重試。',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.deviceCode.title' => ({required Object service}) => '在 ${service} 啟用 Plezy',
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
			_ => null,
		};
	}
}
