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
	@override late final _Translations$discover$zh_Hant discover = _Translations$discover$zh_Hant._(_root);
	@override late final _Translations$errors$zh_Hant errors = _Translations$errors$zh_Hant._(_root);
	@override late final _Translations$libraries$zh_Hant libraries = _Translations$libraries$zh_Hant._(_root);
	@override late final _Translations$about$zh_Hant about = _Translations$about$zh_Hant._(_root);
	@override late final _Translations$serverSelection$zh_Hant serverSelection = _Translations$serverSelection$zh_Hant._(_root);
	@override late final _Translations$hubDetail$zh_Hant hubDetail = _Translations$hubDetail$zh_Hant._(_root);
	@override late final _Translations$logs$zh_Hant logs = _Translations$logs$zh_Hant._(_root);
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
	@override String get useQuickConnect => '使用快速連線（Quick Connect）';
	@override String get quickConnectInstructions => '在 Jellyfin 中開啟快速連線並輸入此代碼。';
	@override String get quickConnectWaiting => '等待核准…';
	@override String get quickConnectCancel => '取消';
	@override String get quickConnectExpired => '快速連線代碼已過期。請重試。';
	@override String get localDataRecoveryRequired => 'Plezy 無法安全地復原本機登入資料與待處理的播放資料。請重新登入。';
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
	@override String get compact => '緊湊';
	@override String get comfortable => '舒適';
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
	@override String get bufferSize => '緩衝區大小';
	@override String bufferSizeMB({required Object size}) => '${size} MB';
	@override String get bufferSizeAuto => '自動（推薦）';
	@override String bufferSizeWarning({required Object heap, required Object size}) => '可用記憶體為 ${heap} MB。設定 ${size} MB 緩衝可能影響播放穩定性。';
	@override String get defaultQualityTitle => '預設畫質';
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
	@override String get showChapterMarkersOnTimeline => '在進度條上顯示章節標記';
	@override String get showChapterMarkersOnTimelineDescription => '依章節分段顯示進度條';
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
	@override String get autoSkip => '自動跳過';
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
	@override String get atmosDiagnostics => 'Atmos 輸出測試';
	@override String get atmosDiagnosticsDescription => '透過系統播放器播放測試訊號，診斷 Dolby Atmos 輸出狀態';
	@override String get atmosTestHlsAtmos => 'Apple Atmos 串流';
	@override String get atmosTestHlsAtmosDescription => '已知正常的 Dolby Atmos 串流。擴大機應顯示 Dolby Atmos。';
	@override String get atmosTestHlsControl => 'Apple 環繞音效串流';
	@override String get atmosTestHlsControlDescription => '不含 Atmos 的對照組串流。擴大機應顯示一般環繞音效（非 Atmos）。';
	@override String get atmosTestRawStream => '原始 EAC3 串流';
	@override String get atmosTestRawStreamDescription => '以與播放器播放 Atmos 完全相同的方式串流測試檔案。需要測試檔案的 URL。';
	@override String get atmosTestRawFile => '原始 EAC3 檔案';
	@override String get atmosTestRawFileDescription => '以已知長度播放測試檔案。需要測試檔案的 URL。';
	@override String get atmosTestAsbarNative => '取樣緩衝渲染器（原生）';
	@override String get atmosTestAsbarNativeDescription => '將檔案未經更動的壓縮音訊直接交給系統渲染器。需要測試檔案 URL。';
	@override String get atmosTestAsbarGenerated => '取樣緩衝渲染器（重建）';
	@override String get atmosTestAsbarGeneratedDescription => '相同，但音訊描述以播放時的方式重建。需要測試檔案 URL。';
	@override String get atmosTestSessionMode => '使用影片播放工作階段模式';
	@override String get atmosTestSessionModeDescription => '關閉時使用 Dolby 文件所述的模式。開啟時使用先前的模式。';
	@override String get atmosTestShowRoutePicker => '選擇 AirPlay 輸出';
	@override String get atmosTestHideRoutePicker => '隱藏 AirPlay 輸出選擇器';
	@override String get atmosTestRoutePickerDescription => '將測試傳送到 AirPlay 接收器。只有 AirPlay 會回報已確定的音訊模式。';
	@override String get atmosTestStop => '停止測試';
	@override String get atmosTestUrl => '測試檔案 URL';
	@override String get atmosTestUrlDescription => '原始 .ec3 Dolby Atmos 檔案的 HTTP URL（例如使用 ffmpeg 提取的檔案）';
	@override String get atmosTestUrlMissing => '請先設定測試檔案的 URL';
	@override String get atmosTestStatus => '狀態';
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
	@override String get liveTvDefaultFavorites => '預設顯示最愛頻道';
	@override String get liveTvDefaultFavoritesDescription => '開啟直播電視時僅顯示最愛頻道';
	@override String get display => '顯示器';
	@override String get homeScreen => '主畫面';
	@override String get navigation => '導覽';
	@override String get window => '視窗';
	@override String get content => '內容';
	@override String get player => '播放器';
	@override String get subtitlesAndConfig => '字幕與設定';
	@override String get seekAndTiming => '跳轉與計時';
	@override String get behavior => '行為';
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
	@override String get video => '影片';
	@override String get audio => '音訊';
	@override String get subtitles => '字幕';
	@override String get file => '檔案';
	@override String get codec => '編解碼器';
	@override String get resolution => '解析度';
	@override String get bitrate => '位元率';
	@override String get frameRate => '影格率';
	@override String get aspectRatio => '寬高比';
	@override String get profile => '規格檔（Profile）';
	@override String get bitDepth => '位元深度';
	@override String get colorSpace => '色彩空間';
	@override String get colorRange => '色彩範圍';
	@override String get colorPrimaries => '色彩基色';
	@override String get chromaSubsampling => '色度抽樣';
	@override String get channels => '聲道數';
	@override String get overallBitrate => '總位元率';
	@override String get path => '路徑';
	@override String get size => '大小';
	@override String get container => '封裝格式';
	@override String get duration => '長度';
	@override String get optimizedForStreaming => '已最佳化串流播放';
	@override String get has64bitOffsets => '具 64 位元偏移量';
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
	@override String get deleteMultipleWarning => '這將會刪除所有單集及其檔案。';
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
	@override String get resetToZero => '重設為 0 ms';
	@override String addTime({required Object amount, required Object unit}) => '+${amount} ${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount} ${unit}';
	@override String playsLater({required Object label}) => '${label} 延後播放';
	@override String playsEarlier({required Object label}) => '${label} 提前播放';
	@override String get noOffset => '無偏移';
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
	@override String get searchSubtitles => '搜尋字幕';
	@override String get language => '語言';
	@override String get noSubtitlesFound => '找不到字幕';
	@override String get subtitleDownloaded => '字幕下載成功';
	@override String get subtitleDownloadedNotApplied => '字幕已下載，但無法套用';
	@override String get subtitleDownloadFailed => '字幕下載失敗';
	@override String get searchLanguages => '搜尋語言…';
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
	@override String get logsUploaded => '日誌已上傳';
	@override String get logsUploadFailed => '上傳日誌失敗';
	@override String get logId => '日誌 ID';
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
}

// Path: errors
class _Translations$errors$zh_Hant extends Translations$errors$zh {
	_Translations$errors$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => '搜尋失敗：${error}';
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
	@override String get watchlistUpdateFailed => '無法更新待看清單';
	@override String get notInLibrary => '不在您的媒體庫中';
	@override String get inTheseLibraries => '在這些媒體庫中';
	@override String get checkingLibrary => '正在檢查您的媒體庫…';
	@override String get emptyTitle => '這裡還沒有任何內容';
	@override String emptyMessage({required Object source}) => '當 ${source} 有內容時，相關資訊將顯示在此處。';
	@override String searchHint({required Object source}) => '搜尋 ${source}';
	@override String searchEmpty({required Object query}) => '沒有「${query}」的結果';
	@override String searchPrompt({required Object source}) => '在 ${source} 搜尋電影與影集。';
	@override String get searchFailed => '搜尋失敗。請檢查網路連線後重試。';
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
	@override String syncRuleCreated({required Object count}) => '同步規則已建立 — 將保留 ${count} 個未觀看單集';
	@override String get syncRuleUpdated => '同步規則已更新';
	@override String get syncRuleRemoved => '同步規則已刪除';
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
	@override String get style => '風格';
	@override String get mood => '氛圍';
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
}

// Path: services
class _Translations$services$zh_Hant extends Translations$services$zh {
	_Translations$services$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get title => '外部服務';
	@override String get hubSubtitle => '同步觀看進度並請求新內容。';
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
	@override late final _Translations$services$libraryFilter$zh_Hant libraryFilter = _Translations$services$libraryFilter$zh_Hant._(_root);
}

// Path: addServer
class _Translations$addServer$zh_Hant extends Translations$addServer$zh {
	_Translations$addServer$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String get serverUrls => '伺服器 URL';
	@override String get serverUrlsHelper => '可輸入多個連線網址，以逗號區隔。';
	@override String get findServer => '尋找伺服器';
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
	@override String get addConnectionTitle => '新增連線';
	@override String addConnectionTitleScoped({required Object name}) => '新增連線至 ${name}';
	@override String get signInWithPlexCard => '使用 Plex 登入';
	@override String get signInWithPlexCardSubtitle => '授權此裝置。將會新增共享的伺服器連線。';
	@override String get signInWithPlexCardSubtitleScoped => '授權 Plex 帳戶。Home 使用者會建立為個別的使用者設定檔。';
	@override String get borrowFromAnotherProfile => '從另一個使用者設定檔共用';
	@override String get borrowFromAnotherProfileSubtitle => '重複使用另一個使用者設定檔的連線資訊。受 PIN 碼保護的使用者設定檔需輸入 PIN 碼。';
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
	@override String unknown({required Object error}) => '發生錯誤：${error}';
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
}

// Path: services.deviceCode
class _Translations$services$deviceCode$zh_Hant extends Translations$services$deviceCode$zh {
	_Translations$services$deviceCode$zh_Hant._(TranslationsZhHant root) : this._root = root, super.internal(root);

	final TranslationsZhHant _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '在 ${service} 啟用 Plezy';
	@override String body({required Object url}) => '請前往 ${url} 並輸入此代碼：';
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
			'auth.useQuickConnect' => '使用快速連線（Quick Connect）',
			'auth.quickConnectInstructions' => '在 Jellyfin 中開啟快速連線並輸入此代碼。',
			'auth.quickConnectWaiting' => '等待核准…',
			'auth.quickConnectCancel' => '取消',
			'auth.quickConnectExpired' => '快速連線代碼已過期。請重試。',
			'auth.localDataRecoveryRequired' => 'Plezy 無法安全地復原本機登入資料與待處理的播放資料。請重新登入。',
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
			'settings.compact' => '緊湊',
			'settings.comfortable' => '舒適',
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
			'settings.bufferSize' => '緩衝區大小',
			'settings.bufferSizeMB' => ({required Object size}) => '${size} MB',
			'settings.bufferSizeAuto' => '自動（推薦）',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => '可用記憶體為 ${heap} MB。設定 ${size} MB 緩衝可能影響播放穩定性。',
			'settings.defaultQualityTitle' => '預設畫質',
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
			'settings.showChapterMarkersOnTimeline' => '在進度條上顯示章節標記',
			'settings.showChapterMarkersOnTimelineDescription' => '依章節分段顯示進度條',
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
			'settings.autoSkip' => '自動跳過',
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
			'settings.atmosDiagnostics' => 'Atmos 輸出測試',
			'settings.atmosDiagnosticsDescription' => '透過系統播放器播放測試訊號，診斷 Dolby Atmos 輸出狀態',
			'settings.atmosTestHlsAtmos' => 'Apple Atmos 串流',
			'settings.atmosTestHlsAtmosDescription' => '已知正常的 Dolby Atmos 串流。擴大機應顯示 Dolby Atmos。',
			'settings.atmosTestHlsControl' => 'Apple 環繞音效串流',
			'settings.atmosTestHlsControlDescription' => '不含 Atmos 的對照組串流。擴大機應顯示一般環繞音效（非 Atmos）。',
			'settings.atmosTestRawStream' => '原始 EAC3 串流',
			'settings.atmosTestRawStreamDescription' => '以與播放器播放 Atmos 完全相同的方式串流測試檔案。需要測試檔案的 URL。',
			'settings.atmosTestRawFile' => '原始 EAC3 檔案',
			'settings.atmosTestRawFileDescription' => '以已知長度播放測試檔案。需要測試檔案的 URL。',
			'settings.atmosTestAsbarNative' => '取樣緩衝渲染器（原生）',
			'settings.atmosTestAsbarNativeDescription' => '將檔案未經更動的壓縮音訊直接交給系統渲染器。需要測試檔案 URL。',
			'settings.atmosTestAsbarGenerated' => '取樣緩衝渲染器（重建）',
			'settings.atmosTestAsbarGeneratedDescription' => '相同，但音訊描述以播放時的方式重建。需要測試檔案 URL。',
			'settings.atmosTestSessionMode' => '使用影片播放工作階段模式',
			'settings.atmosTestSessionModeDescription' => '關閉時使用 Dolby 文件所述的模式。開啟時使用先前的模式。',
			'settings.atmosTestShowRoutePicker' => '選擇 AirPlay 輸出',
			'settings.atmosTestHideRoutePicker' => '隱藏 AirPlay 輸出選擇器',
			'settings.atmosTestRoutePickerDescription' => '將測試傳送到 AirPlay 接收器。只有 AirPlay 會回報已確定的音訊模式。',
			'settings.atmosTestStop' => '停止測試',
			'settings.atmosTestUrl' => '測試檔案 URL',
			'settings.atmosTestUrlDescription' => '原始 .ec3 Dolby Atmos 檔案的 HTTP URL（例如使用 ffmpeg 提取的檔案）',
			'settings.atmosTestUrlMissing' => '請先設定測試檔案的 URL',
			'settings.atmosTestStatus' => '狀態',
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
			'settings.liveTvDefaultFavorites' => '預設顯示最愛頻道',
			'settings.liveTvDefaultFavoritesDescription' => '開啟直播電視時僅顯示最愛頻道',
			'settings.display' => '顯示器',
			'settings.homeScreen' => '主畫面',
			'settings.navigation' => '導覽',
			'settings.window' => '視窗',
			'settings.content' => '內容',
			'settings.player' => '播放器',
			'settings.subtitlesAndConfig' => '字幕與設定',
			'settings.seekAndTiming' => '跳轉與計時',
			'settings.behavior' => '行為',
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
			'fileInfo.video' => '影片',
			'fileInfo.audio' => '音訊',
			'fileInfo.subtitles' => '字幕',
			'fileInfo.file' => '檔案',
			'fileInfo.codec' => '編解碼器',
			'fileInfo.resolution' => '解析度',
			'fileInfo.bitrate' => '位元率',
			'fileInfo.frameRate' => '影格率',
			'fileInfo.aspectRatio' => '寬高比',
			'fileInfo.profile' => '規格檔（Profile）',
			'fileInfo.bitDepth' => '位元深度',
			'fileInfo.colorSpace' => '色彩空間',
			'fileInfo.colorRange' => '色彩範圍',
			'fileInfo.colorPrimaries' => '色彩基色',
			'fileInfo.chromaSubsampling' => '色度抽樣',
			'fileInfo.channels' => '聲道數',
			'fileInfo.overallBitrate' => '總位元率',
			'fileInfo.path' => '路徑',
			'fileInfo.size' => '大小',
			'fileInfo.container' => '封裝格式',
			'fileInfo.duration' => '長度',
			'fileInfo.optimizedForStreaming' => '已最佳化串流播放',
			'fileInfo.has64bitOffsets' => '具 64 位元偏移量',
			'mediaMenu.markAsWatched' => '標記為已觀看',
			'mediaMenu.markAsUnwatched' => '標記為未觀看',
			'mediaMenu.removeFromContinueWatching' => '從「繼續觀看」中移除',
			'mediaMenu.viewDetails' => '查看詳情',
			'mediaMenu.goToSeries' => '前往影集',
			'mediaMenu.shufflePlay' => '隨機播放',
			'mediaMenu.shuffleNotAvailableOffline' => '離線時無法隨機播放',
			'mediaMenu.fileInfo' => '檔案資訊',
			'mediaMenu.deleteMultipleWarning' => '這將會刪除所有單集及其檔案。',
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
			'tooltips.shufflePlay' => '隨機播放',
			'tooltips.playTrailer' => '播放預告片',
			'tooltips.markAsWatched' => '標記為已觀看',
			'tooltips.markAsUnwatched' => '標記為未觀看',
			'audioTracks.track' => ({required Object n}) => '音軌 ${n}',
			'videoControls.audioLabel' => '音訊',
			'videoControls.subtitlesLabel' => '字幕',
			'videoControls.resetToZero' => '重設為 0 ms',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount} ${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount} ${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label} 延後播放',
			'videoControls.playsEarlier' => ({required Object label}) => '${label} 提前播放',
			'videoControls.noOffset' => '無偏移',
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
			'videoControls.pipErrors.unknown' => ({required Object error}) => '發生錯誤：${error}',
			'videoControls.chapters' => '章節',
			'videoControls.noChaptersAvailable' => '沒有可用的章節',
			'videoControls.queue' => '播放佇列',
			'videoControls.noQueueItems' => '佇列中沒有項目',
			'videoControls.searchSubtitles' => '搜尋字幕',
			'videoControls.language' => '語言',
			'videoControls.noSubtitlesFound' => '找不到字幕',
			'videoControls.subtitleDownloaded' => '字幕下載成功',
			'videoControls.subtitleDownloadedNotApplied' => '字幕已下載，但無法套用',
			'videoControls.subtitleDownloadFailed' => '字幕下載失敗',
			_ => null,
		} ?? switch (path) {
			'videoControls.searchLanguages' => '搜尋語言…',
			'messages.markedAsWatched' => '已標記為已觀看',
			'messages.markedAsUnwatched' => '已標記為未觀看',
			'messages.markedAsWatchedOffline' => '已標記為已觀看（將在連線時同步）',
			'messages.markedAsUnwatchedOffline' => '已標記為未觀看（將在連線時同步）',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => '已自動移除：${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '已自動移除 ${n} 個已觀看的下載內容', ), 
			'messages.removedFromContinueWatching' => '已從「繼續觀看」中移除',
			'messages.errorLoading' => ({required Object error}) => '錯誤：${error}',
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
			'messages.logsUploaded' => '日誌已上傳',
			'messages.logsUploadFailed' => '上傳日誌失敗',
			'messages.logId' => '日誌 ID',
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
			'connections.sectionTitle' => '連線',
			'connections.addConnection' => '新增連線',
			'connections.addConnectionSubtitleNoProfile' => '使用 Plex 登入或連線至 Jellyfin 伺服器',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => '新增至 ${displayName}：Plex、Jellyfin 或其他設定檔連線',
			'connections.sessionExpiredOne' => ({required Object name}) => '${name} 的工作階段已過期',
			'connections.sessionExpiredMany' => ({required Object count}) => '${count} 個伺服器的工作階段已過期',
			'connections.signInAgain' => '重新登入',
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
			'errors.searchFailed' => ({required Object error}) => '搜尋失敗：${error}',
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
			'hubDetail.title' => '標題',
			'hubDetail.releaseYear' => '發行年份',
			'hubDetail.dateAdded' => '新增日期',
			'hubDetail.rating' => '評分',
			'hubDetail.noItemsFound' => '找不到項目',
			'logs.clearLogs' => '清除日誌',
			'logs.copyLogs' => '複製日誌',
			'logs.uploadLogs' => '上傳日誌',
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
			'explore.watchlistUpdateFailed' => '無法更新待看清單',
			'explore.notInLibrary' => '不在您的媒體庫中',
			'explore.inTheseLibraries' => '在這些媒體庫中',
			'explore.checkingLibrary' => '正在檢查您的媒體庫…',
			'explore.emptyTitle' => '這裡還沒有任何內容',
			'explore.emptyMessage' => ({required Object source}) => '當 ${source} 有內容時，相關資訊將顯示在此處。',
			'explore.searchHint' => ({required Object source}) => '搜尋 ${source}',
			'explore.searchEmpty' => ({required Object query}) => '沒有「${query}」的結果',
			'explore.searchPrompt' => ({required Object source}) => '在 ${source} 搜尋電影與影集。',
			'explore.searchFailed' => '搜尋失敗。請檢查網路連線後重試。',
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
			_ => null,
		} ?? switch (path) {
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
			'downloads.syncRuleCreated' => ({required Object count}) => '同步規則已建立 — 將保留 ${count} 個未觀看單集',
			'downloads.syncRuleUpdated' => '同步規則已更新',
			'downloads.syncRuleRemoved' => '同步規則已刪除',
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
			'videoSettings.playbackSpeed' => '播放速度',
			'videoSettings.normalSpeed' => '正常速度',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => '執行中（${duration}）',
			'videoSettings.zoom' => '縮放',
			'videoSettings.sleepTimer' => '睡眠計時器',
			'videoSettings.audioSync' => '音訊同步調整',
			'videoSettings.subtitleSync' => '字幕同步調整',
			'videoSettings.hdr' => 'HDR',
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
			'metadataEdit.style' => '風格',
			'metadataEdit.mood' => '氛圍',
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
			'services.title' => '外部服務',
			'services.hubSubtitle' => '同步觀看進度並請求新內容。',
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
			'services.deviceCode.title' => ({required Object service}) => '在 ${service} 啟用 Plezy',
			'services.deviceCode.body' => ({required Object url}) => '請前往 ${url} 並輸入此代碼：',
			'services.deviceCode.openToActivate' => ({required Object service}) => '開啟 ${service} 進行啟用',
			'services.deviceCode.copyCode' => '複製啟用代碼',
			'services.deviceCode.waitingForAuthorization' => '等待授權中…',
			'services.deviceCode.codeCopied' => '代碼已複製',
			'services.oauthProxy.title' => ({required Object service}) => '登入 ${service}',
			'services.oauthProxy.body' => '掃描 QR 碼，或在任何裝置上開啟該網址。',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => '開啟 ${service} 進行登入',
			'services.oauthProxy.copyUrl' => '複製登入 URL',
			'services.oauthProxy.urlCopied' => 'URL 已複製',
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
			'addServer.serverUrls' => '伺服器 URL',
			'addServer.serverUrlsHelper' => '可輸入多個連線網址，以逗號區隔。',
			'addServer.findServer' => '尋找伺服器',
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
			'addServer.addConnectionTitle' => '新增連線',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => '新增連線至 ${name}',
			'addServer.signInWithPlexCard' => '使用 Plex 登入',
			'addServer.signInWithPlexCardSubtitle' => '授權此裝置。將會新增共享的伺服器連線。',
			'addServer.signInWithPlexCardSubtitleScoped' => '授權 Plex 帳戶。Home 使用者會建立為個別的使用者設定檔。',
			'addServer.borrowFromAnotherProfile' => '從另一個使用者設定檔共用',
			'addServer.borrowFromAnotherProfileSubtitle' => '重複使用另一個使用者設定檔的連線資訊。受 PIN 碼保護的使用者設定檔需輸入 PIN 碼。',
			_ => null,
		};
	}
}
