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
class TranslationsZh extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsZh({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zh,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <zh>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsZh _root = this; // ignore: unused_field

	@override 
	TranslationsZh $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsZh(meta: meta ?? this.$meta);

	// Translations
	@override late final Translations$app$zh app = Translations$app$zh.internal(_root);
	@override late final Translations$auth$zh auth = Translations$auth$zh.internal(_root);
	@override late final Translations$common$zh common = Translations$common$zh.internal(_root);
	@override late final Translations$screens$zh screens = Translations$screens$zh.internal(_root);
	@override late final Translations$update$zh update = Translations$update$zh.internal(_root);
	@override late final Translations$settings$zh settings = Translations$settings$zh.internal(_root);
	@override late final Translations$search$zh search = Translations$search$zh.internal(_root);
	@override late final Translations$hotkeys$zh hotkeys = Translations$hotkeys$zh.internal(_root);
	@override late final Translations$fileInfo$zh fileInfo = Translations$fileInfo$zh.internal(_root);
	@override late final Translations$mediaMenu$zh mediaMenu = Translations$mediaMenu$zh.internal(_root);
	@override late final Translations$rateSheet$zh rateSheet = Translations$rateSheet$zh.internal(_root);
	@override late final Translations$accessibility$zh accessibility = Translations$accessibility$zh.internal(_root);
	@override late final Translations$tooltips$zh tooltips = Translations$tooltips$zh.internal(_root);
	@override late final Translations$audioTracks$zh audioTracks = Translations$audioTracks$zh.internal(_root);
	@override late final Translations$videoControls$zh videoControls = Translations$videoControls$zh.internal(_root);
	@override late final Translations$messages$zh messages = Translations$messages$zh.internal(_root);
	@override late final Translations$subtitlingStyling$zh subtitlingStyling = Translations$subtitlingStyling$zh.internal(_root);
	@override late final Translations$mpvConfig$zh mpvConfig = Translations$mpvConfig$zh.internal(_root);
	@override late final Translations$dialog$zh dialog = Translations$dialog$zh.internal(_root);
	@override late final Translations$profiles$zh profiles = Translations$profiles$zh.internal(_root);
	@override late final Translations$connections$zh connections = Translations$connections$zh.internal(_root);
	@override late final Translations$discover$zh discover = Translations$discover$zh.internal(_root);
	@override late final Translations$errors$zh errors = Translations$errors$zh.internal(_root);
	@override late final Translations$libraries$zh libraries = Translations$libraries$zh.internal(_root);
	@override late final Translations$about$zh about = Translations$about$zh.internal(_root);
	@override late final Translations$serverSelection$zh serverSelection = Translations$serverSelection$zh.internal(_root);
	@override late final Translations$hubDetail$zh hubDetail = Translations$hubDetail$zh.internal(_root);
	@override late final Translations$logs$zh logs = Translations$logs$zh.internal(_root);
	@override late final Translations$startup$zh startup = Translations$startup$zh.internal(_root);
	@override late final Translations$licenses$zh licenses = Translations$licenses$zh.internal(_root);
	@override late final Translations$navigation$zh navigation = Translations$navigation$zh.internal(_root);
	@override late final Translations$explore$zh explore = Translations$explore$zh.internal(_root);
	@override late final Translations$liveTv$zh liveTv = Translations$liveTv$zh.internal(_root);
	@override late final Translations$collections$zh collections = Translations$collections$zh.internal(_root);
	@override late final Translations$playlists$zh playlists = Translations$playlists$zh.internal(_root);
	@override late final Translations$music$zh music = Translations$music$zh.internal(_root);
	@override late final Translations$watchTogether$zh watchTogether = Translations$watchTogether$zh.internal(_root);
	@override late final Translations$downloads$zh downloads = Translations$downloads$zh.internal(_root);
	@override late final Translations$shaders$zh shaders = Translations$shaders$zh.internal(_root);
	@override late final Translations$companionRemote$zh companionRemote = Translations$companionRemote$zh.internal(_root);
	@override late final Translations$videoSettings$zh videoSettings = Translations$videoSettings$zh.internal(_root);
	@override late final Translations$performanceOverlay$zh performanceOverlay = Translations$performanceOverlay$zh.internal(_root);
	@override late final Translations$externalPlayer$zh externalPlayer = Translations$externalPlayer$zh.internal(_root);
	@override late final Translations$metadataEdit$zh metadataEdit = Translations$metadataEdit$zh.internal(_root);
	@override late final Translations$matchScreen$zh matchScreen = Translations$matchScreen$zh.internal(_root);
	@override late final Translations$serverTasks$zh serverTasks = Translations$serverTasks$zh.internal(_root);
	@override late final Translations$trakt$zh trakt = Translations$trakt$zh.internal(_root);
	@override late final Translations$seerr$zh seerr = Translations$seerr$zh.internal(_root);
	@override late final Translations$services$zh services = Translations$services$zh.internal(_root);
	@override late final Translations$addServer$zh addServer = Translations$addServer$zh.internal(_root);
}

// Path: app
class Translations$app$zh extends Translations$app$en {
	Translations$app$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class Translations$auth$zh extends Translations$auth$en {
	Translations$auth$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => '使用 Plex 登录';
	@override String get showQRCode => '显示二维码';
	@override String get authenticate => '验证';
	@override String get authenticationTimeout => '验证超时。请重试。';
	@override String get scanQRToSignIn => '扫描二维码登录';
	@override String get waitingForAuth => '正在等待身份验证…\n请在浏览器中登录。';
	@override String get useBrowser => '使用浏览器';
	@override String get or => '或';
	@override String connectToMediaBrowser({required Object product}) => '连接到 ${product}';
	@override String get useQuickConnect => '使用 Quick Connect';
	@override String get quickConnectInstructions => '在 Jellyfin 中打开 Quick Connect 并输入此代码。';
	@override String get quickConnectWaiting => '等待批准…';
	@override String get quickConnectCancel => '取消';
	@override String get quickConnectExpired => 'Quick Connect 已过期。请重试。';
	@override String get localDataRecoveryRequired => 'Plezy 无法安全恢复本地登录状态和待处理的播放数据。请重新登录。';
	@override String get pinCheckRejected => 'Plex PIN 检查被拒绝';
}

// Path: common
class Translations$common$zh extends Translations$common$en {
	Translations$common$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get cancel => '取消';
	@override String get save => '保存';
	@override String get close => '关闭';
	@override String get clear => '清除';
	@override String get reset => '重置';
	@override String get later => '稍后';
	@override String get submit => '提交';
	@override String get confirm => '确认';
	@override String get retry => '重试';
	@override String get logout => '退出登录';
	@override String get unknown => '未知';
	@override String get refresh => '刷新';
	@override String get yes => '是';
	@override String get no => '否';
	@override String get delete => '删除';
	@override String get edit => '编辑';
	@override String get shuffle => '随机播放';
	@override String get addTo => '添加到…';
	@override String get createNew => '新建';
	@override String get connect => '连接';
	@override String get disconnect => '断开连接';
	@override String get play => '播放';
	@override String get pause => '暂停';
	@override String get resume => '继续';
	@override String get error => '错误';
	@override String get search => '搜索';
	@override String get home => '首页';
	@override String get back => '返回';
	@override String get settings => '设置';
	@override String get mute => '静音';
	@override String get ok => '确定';
	@override String get off => '关闭';
	@override String seasonNumber({required Object number}) => '第${number}季';
	@override String episodeNumberTitle({required Object number, required Object title}) => '第${number}集 — ${title}';
	@override String chapterNumber({required Object number}) => '第${number}章';
	@override String get reconnect => '重新连接';
	@override String get viewAll => '查看全部';
	@override String get checkingNetwork => '正在检查网络…';
	@override String get loadingServers => '正在加载服务器…';
	@override String get connectingToServers => '正在连接服务器…';
	@override String get startingOfflineMode => '正在启动离线模式…';
	@override String get loading => '加载中…';
	@override String get fullscreen => '全屏';
	@override String get exitFullscreen => '退出全屏';
	@override String get pressBackAgainToExit => '再按一次返回键退出';
	@override late final Translations$common$ratingSource$zh ratingSource = Translations$common$ratingSource$zh.internal(_root);
	@override String get notAvailable => 'N/A';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
	@override late final Translations$common$mediaKind$zh mediaKind = Translations$common$mediaKind$zh.internal(_root);
}

// Path: screens
class Translations$screens$zh extends Translations$screens$en {
	Translations$screens$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get licenses => '许可证';
	@override String get switchProfile => '切换用户';
	@override String get subtitleStyling => '字幕样式';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => '日志';
}

// Path: update
class Translations$update$zh extends Translations$update$en {
	Translations$update$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get available => '有可用更新';
	@override String versionAvailable({required Object version}) => '版本 ${version} 已发布';
	@override String currentVersion({required Object version}) => '当前版本：${version}';
	@override String get skipVersion => '跳过此版本';
	@override String get viewRelease => '查看发布详情';
	@override String get latestVersion => '当前已是最新版本';
	@override String get checkFailed => '无法检查更新';
}

// Path: settings
class Translations$settings$zh extends Translations$settings$en {
	Translations$settings$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '设置';
	@override String get supportDeveloper => '支持 Plezy';
	@override String get supportDeveloperDescription => '通过 Liberapay 捐赠支持开发';
	@override String get language => '语言';
	@override String get theme => '主题';
	@override String get appearance => '外观';
	@override String get videoPlayback => '视频播放';
	@override String get videoPlaybackDescription => '配置播放行为';
	@override String get advanced => '高级';
	@override String get episodePosterMode => '剧集海报样式';
	@override String get seriesPoster => '剧集海报';
	@override String get seasonPoster => '季海报';
	@override String get episodeThumbnail => '缩略图';
	@override String get showHeroSectionDescription => '在主屏幕上显示精选内容轮播区';
	@override String get secondsLabel => '秒';
	@override String get minutesLabel => '分钟';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => '输入时长（${min}–${max}）';
	@override String get systemTheme => '系统';
	@override String get lightTheme => '浅色';
	@override String get darkTheme => '深色';
	@override String get oledTheme => 'OLED';
	@override String get libraryDensity => '媒体库密度';
	@override String get displayScale => '界面缩放';
	@override String get compact => '紧凑';
	@override String get comfortable => '舒适';
	@override String get tvCornerSpotlightBackdrop => '右上角聚焦背景图';
	@override String get tvCornerSpotlightBackdropDescription => '在右上角显示精选内容图片，而不是铺满整个屏幕';
	@override String get viewMode => '视图模式';
	@override String get gridView => '网格视图';
	@override String get listView => '列表视图';
	@override String get showHeroSection => '显示精选内容区';
	@override String get continueWatchingAction => '继续观看操作';
	@override String get continueWatchingPlay => '播放';
	@override String get continueWatchingDetails => '打开详情';
	@override String get episodeAction => '剧集操作';
	@override String get episodePlay => '播放';
	@override String get episodeDetails => '打开详情';
	@override String get useGlobalHubs => '使用主页布局';
	@override String get useGlobalHubsDescription => '显示统一主页内容；否则使用各媒体库的推荐内容。';
	@override String get showServerNameOnHubs => '在推荐栏显示服务器名称';
	@override String get showServerNameOnHubsDescription => '始终在推荐栏标题中显示服务器名称。';
	@override String get groupLibrariesByServer => '按服务器分组媒体库';
	@override String get groupLibrariesByServerDescription => '在侧边栏中按媒体服务器分组媒体库。';
	@override String get alwaysKeepSidebarOpen => '始终保持侧边栏展开';
	@override String get alwaysKeepSidebarOpenDescription => '侧边栏保持展开状态，内容区域自动调整';
	@override String get showUnwatchedCount => '显示未观看数量';
	@override String get showUnwatchedCountDescription => '在剧集和季上显示未观看集数';
	@override String get showEpisodeNumberOnCards => '在卡片上显示集数';
	@override String get showEpisodeNumberOnCardsDescription => '在剧集卡片上显示季和集编号';
	@override String get showSeasonPostersOnTabs => '在选项卡上显示季海报';
	@override String get showSeasonPostersOnTabsDescription => '在每季标签上方显示该季海报';
	@override String get tvFullCardLayout => '完整电视卡片';
	@override String get tvFullCardLayoutDescription => '使用仅显示图片的电视卡片，并在图片上叠加演员姓名';
	@override String get focusGlow => '焦点光晕';
	@override String get focusGlowDescription => '在获得焦点的卡片周围显示柔和的光晕';
	@override String get visualEffects => '视觉效果';
	@override String get visualEffectsAuto => '自动';
	@override String get visualEffectsAutoDescription => '在性能较低的设备上自动减少效果';
	@override String get visualEffectsFull => '完整效果';
	@override String get visualEffectsReduced => '简化';
	@override String get visualEffectsReducedDescription => '减少动画并使用较低分辨率的封面图片';
	@override String get hideSpoilers => '隐藏未看剧集的剧透内容';
	@override String get hideSpoilersDescription => '模糊未观看剧集的缩略图和描述';
	@override String get playerBackend => '播放器引擎';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => '硬件解码';
	@override String get hardwareDecodingDescription => '如果可用，使用硬件加速';
	@override String get bufferSize => '缓冲区大小';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => '自动（推荐）';
	@override String bufferSizeWarning({required Object heap, required Object size}) => '可用内存 ${heap}MB。${size}MB 缓冲可能影响播放。';
	@override String get playbackBuffer => '播放缓冲';
	@override String get playbackBufferAuto => '自动（推荐）';
	@override String get playbackBufferLarge => '大';
	@override String get playbackBufferExtraLarge => '特大';
	@override String get playbackBufferDescription => '针对不稳定的连接缓冲更多内容。也受缓冲大小限制。';
	@override String get defaultQualityTitle => '默认画质';
	@override String get musicQualityTitle => '音乐音质';
	@override String get subtitleStyling => '字幕样式';
	@override String get subtitleStylingDescription => '调整字幕外观';
	@override String get smallSkipDuration => '短跳过时长';
	@override String get largeSkipDuration => '长跳过时长';
	@override String get rewindOnResume => '恢复时回退';
	@override String secondsUnit({required Object seconds}) => '${seconds} 秒';
	@override String get defaultSleepTimer => '默认睡眠定时器';
	@override String minutesUnit({required Object minutes}) => '${minutes} 分钟';
	@override String get rememberTrackSelections => '记住每部剧集或电影的音轨选择';
	@override String get rememberTrackSelectionsDescription => '分别记住每部内容的音频和字幕选择';
	@override String get followServerTrackSelections => '使用服务器为每集选择的轨道';
	@override String get followServerTrackSelectionsDescription => '切换剧集时，应用服务器上为该集选择的音频和字幕，而不是沿用当前选择';
	@override String get showChapterMarkersOnTimeline => '在进度条上显示章节标记';
	@override String get showChapterMarkersOnTimelineDescription => '按章节边界分段显示进度条';
	@override String get specialsOrdering => '特别篇按剧集顺序';
	@override String get specialsOrderingDescription => '特别篇在剧集观看顺序中的播放位置';
	@override String get specialsOrderingServer => '遵循服务器顺序';
	@override String get specialsOrderingAirDate => '按播出日期穿插';
	@override String get specialsOrderingLast => '常规季之后';
	@override String get clickVideoTogglesPlayback => '点击视频可切换播放/暂停';
	@override String get clickVideoTogglesPlaybackDescription => '点击视频即可播放或暂停，而不是显示控制项。';
	@override String get videoPlayerControls => '视频播放器控制';
	@override String get keyboardShortcuts => '键盘快捷键';
	@override String get keyboardShortcutsDescription => '自定义键盘快捷键';
	@override String get videoPlayerNavigation => '视频播放器导航';
	@override String get videoPlayerNavigationDescription => '使用方向键导航视频播放器控件';
	@override String get watchTogetherRelay => '一起看中继服务器';
	@override String get watchTogetherRelayDescription => '设置自定义中继。所有人必须使用同一服务器。';
	@override String get watchTogetherRelayHint => 'https://my-relay.example.com';
	@override String get watchTogetherRelayInvalid => '请输入有效的 HTTP 或 HTTPS 中继服务器基础 URL。';
	@override String get crashReporting => '崩溃报告';
	@override String get crashReportingDescription => '发送崩溃报告以帮助改进应用';
	@override String get debugLogging => '调试日志';
	@override String get debugLoggingDescription => '启用详细日志记录以便故障排除';
	@override String get viewLogs => '查看日志';
	@override String get viewLogsDescription => '查看应用日志';
	@override String get clearImageCache => '清除图片缓存';
	@override String get clearImageCacheDescription => '清除缓存的封面与缩略图。图片在重新下载前加载速度可能会变慢。';
	@override String get clearImageCacheSuccess => '图片缓存已成功清除';
	@override String get resetSettings => '重置设置';
	@override String get resetSettingsDescription => '恢复默认设置。此操作无法撤销。';
	@override String get resetSettingsSuccess => '设置重置成功';
	@override String get backup => '备份';
	@override String get exportSettings => '导出设置';
	@override String get exportSettingsDescription => '将偏好设置保存到文件';
	@override String get exportSettingsSuccess => '设置已导出';
	@override String get importSettings => '导入设置';
	@override String get importSettingsDescription => '从文件恢复偏好设置';
	@override String get importSettingsConfirm => '这将替换您当前的设置。继续吗？';
	@override String get importSettingsSuccess => '设置已导入';
	@override String get importSettingsInvalidFile => '此文件不是有效的 Plezy 设置导出';
	@override String get importSettingsNoUser => '导入设置前请先登录';
	@override String get shortcutsReset => '快捷键已重置为默认值';
	@override String get about => '关于';
	@override String get aboutDescription => '应用程序信息和许可证';
	@override String get updates => '更新';
	@override String get updateAvailable => '有可用更新';
	@override String get checkForUpdates => '检查更新';
	@override String get autoCheckUpdatesOnStartup => '启动时自动检查更新';
	@override String get autoCheckUpdatesOnStartupDescription => '启动时有可用更新则通知';
	@override String get validationErrorEnterNumber => '请输入有效数字';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => '时长必须介于 ${min} 和 ${max} ${unit} 之间';
	@override String shortcutAlreadyAssigned({required Object action}) => '快捷键已被分配给 ${action}';
	@override String shortcutUpdated({required Object action}) => '快捷键已为 ${action} 更新';
	@override String get saveFailed => '无法保存更改。请重试。';
	@override String get autoSkip => '自动跳过';
	@override String get autoSkipIntro => '自动跳过片头';
	@override String get autoSkipIntroDescription => '几秒钟后自动跳过片头标记';
	@override String get autoSkipCredits => '自动跳过片尾';
	@override String get autoSkipCreditsDescription => '自动跳过片尾并播放下一集';
	@override String get forceSkipMarkerFallback => '强制使用备用标记';
	@override String get forceSkipMarkerFallbackDescription => '即使 Plex 有标记，也使用章节标题模式';
	@override String get autoSkipDelay => '自动跳过延迟';
	@override String autoSkipDelayDescription({required Object seconds}) => '自动跳过前等待 ${seconds} 秒';
	@override String get introPattern => '片头标记模式';
	@override String get introPatternDescription => '用于匹配章节标题中片头标记的正则表达式';
	@override String get creditsPattern => '片尾标记模式';
	@override String get creditsPatternDescription => '用于匹配章节标题中片尾标记的正则表达式';
	@override String get invalidRegex => '无效的正则表达式';
	@override String get regex => '正则表达式';
	@override String get downloads => '下载';
	@override String get downloadLocationDescription => '选择下载内容的存储位置';
	@override String get downloadLocationDefault => '默认（应用存储）';
	@override String get downloadLocationCustom => '自定义位置';
	@override String get selectFolder => '选择文件夹';
	@override String get resetToDefault => '重置为默认';
	@override String currentPath({required Object path}) => '当前路径：${path}';
	@override String get downloadLocationChanged => '下载位置已更改';
	@override String get downloadLocationReset => '下载位置已重置为默认';
	@override String get downloadLocationInvalid => '所选文件夹不可写入';
	@override String get downloadLocationPickerUnavailable => '此设备不支持选择文件夹';
	@override String get downloadOnWifiOnly => '仅通过 Wi-Fi 下载';
	@override String get downloadOnWifiOnlyDescription => '使用移动数据时不允许下载';
	@override String get autoRemoveWatchedDownloads => '自动移除已观看的下载';
	@override String get autoRemoveWatchedDownloadsDescription => '自动删除已观看的下载';
	@override String get cellularDownloadBlocked => '已阻止通过移动网络下载。请连接 Wi-Fi 或更改设置。';
	@override String get maxVolume => '最大音量';
	@override String get maxVolumeDescription => '允许音量超过 100%，以便播放音量较低的内容';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord 动态状态';
	@override String get discordRichPresenceDescription => '在 Discord 上显示您正在观看的内容';
	@override String get services => '服务';
	@override String get servicesDescription => '连接 Trakt、MyAnimeList、Seerr 等';
	@override String get manageLibrariesDescription => '重新排序和隐藏媒体库';
	@override String get companionRemoteServer => '远程控制服务器';
	@override String get companionRemoteServerDescription => '允许同一网络中的移动设备控制此应用';
	@override String get autoPip => '自动画中画';
	@override String get autoPipDescription => '播放期间离开应用时自动进入画中画模式';
	@override String get matchContentFrameRate => '匹配内容帧率';
	@override String get matchContentFrameRateDescription => '使显示器刷新率与视频帧率匹配';
	@override String get matchContentResolution => '匹配内容分辨率';
	@override String get matchContentResolutionDescription => '将显示切换为视频的原生分辨率，由电视负责放大。播放期间菜单和字幕也会一并放大';
	@override String get matchRefreshRate => '匹配刷新率';
	@override String get matchRefreshRateDescription => '全屏时匹配显示刷新率';
	@override String get matchDynamicRange => '匹配动态范围';
	@override String get matchDynamicRangeDescription => 'HDR 内容切换到 HDR，随后切回 SDR';
	@override String get displaySwitchDelay => '显示切换延迟';
	@override String get tunneledPlayback => '隧道播放';
	@override String get tunneledPlaybackDescription => '使用视频隧道模式。若播放 HDR 内容时出现黑屏，请将其关闭。';
	@override String get audioPassthrough => '音频直通';
	@override String get audioPassthroughDescription => '将 Dolby/DTS 音频不经重新编码直接发送到功放或电视，保留环绕声。如果没有声音，请关闭。';
	@override String get audioPassthroughDescriptionAppleTv => '将 Dolby Digital Plus（含 Atmos）以比特流方式交给系统输出。DTS 和 TrueHD 仍以多声道 PCM 播放。快进快退时可能出现短暂声音中断。';
	@override String get audioDownmix => '下混为立体声';
	@override String get audioDownmixDescription => '将环绕声混合为双声道，适用于立体声音箱或耳机';
	@override String get downmixCenterBoost => '中置声道增强';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => '增强（dB）';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => '下混时音量标准化';
	@override String get audioDownmixNormalizeDescription => '降低混音电平以防止削波。关闭可保持原始音量（大音量场景可能失真）。';
	@override String get dvConversionMode => 'Dolby Vision 转换';
	@override String get dvConversionModeDescription => '选择 ExoPlayer 如何处理 Dolby Vision Profile 7 文件。';
	@override String get dvConversionAuto => '自动';
	@override String get dvConversionNative => '原生 / 禁用';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => '使用设备能力检测和常规回退机制';
	@override String get dvConversionNativeDescription => '强制原生 DV7 并禁止重试 DV 转换';
	@override String get dvConversionDv81Description => '强制内联 RPU 转换为 Dolby Vision Profile 8.1';
	@override String get dvConversionHevcStripDescription => '移除 Dolby Vision RPU/EL 层并呈现普通 HEVC';
	@override String get demuxer => '容器解复用器';
	@override String get demuxerDescription => '由哪个解复用器解析直接播放的文件。若某个文件播放异常，可切换为 media3。';
	@override String get demuxerFfmpeg => 'FFmpeg（推荐）';
	@override String get demuxerMedia3 => 'media3';
	@override String get requireProfileSelectionOnOpen => '打开应用时选择用户资料';
	@override String get requireProfileSelectionOnOpenDescription => '每次打开应用时都显示用户资料选择界面';
	@override String get forceTvMode => '强制 TV 模式';
	@override String get forceTvModeDescription => '强制 TV 布局。适用于无法自动检测的设备。需要重启。';
	@override String get startInFullscreen => '以全屏模式启动';
	@override String get startInFullscreenDescription => '启动时以全屏模式打开 Plezy';
	@override String get exitFullscreenOnPlayerClose => '关闭播放器时退出全屏';
	@override String get exitFullscreenOnPlayerCloseDescription => '关闭视频播放器时自动退出全屏模式';
	@override String get autoHidePerformanceOverlay => '自动隐藏性能叠加层';
	@override String get autoHidePerformanceOverlayDescription => '性能叠加层随播放控件一起淡入淡出';
	@override String get showNavBarLabels => '显示导航栏标签';
	@override String get showNavBarLabelsDescription => '在导航栏图标下方显示文字标签';
	@override String get startupSection => '启动页面';
	@override String get showExploreTab => '显示“探索”标签页';
	@override String get showExploreTabDescription => '显示“探索”标签页，其中包含来自 Plex Discover 和已连接追踪服务的内容';
	@override String get liveTvDefaultFavorites => '默认显示收藏频道';
	@override String get liveTvDefaultFavoritesDescription => '打开直播电视时仅显示收藏频道';
	@override String get display => '显示';
	@override String get homeScreen => '主屏幕';
	@override String get navigation => '导航';
	@override String get window => '窗口';
	@override String get content => '内容';
	@override String get player => '播放器';
	@override String get subtitlesAndConfig => '字幕与配置';
	@override String get seekAndTiming => '跳转与计时';
	@override String get behavior => '行为';
	@override String get rememberPlayerChanges => '记住播放器更改';
	@override String get rememberPlayerChangesDescription => '播放期间所做的更改保存并重新应用的位置';
	@override String get scopePlaybackSpeed => '播放速度';
	@override String get scopeShaderPreset => '着色器预设';
	@override String get scopeAspectRatio => '宽高比';
	@override String get scopeSyncOffsets => '音频和字幕同步';
	@override String get playerScopeOff => '不保存';
	@override String get playerScopeGlobal => '所有位置';
	@override String get playerScopeLibrary => '按媒体库';
	@override String get playerScopeTitle => '按剧集或电影';
	@override String get exportDialogTitle => '导出 Plezy 设置';
}

// Path: search
class Translations$search$zh extends Translations$search$en {
	Translations$search$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get hint => '搜索电影、剧集、音乐…';
	@override String get tryDifferentTerm => '尝试不同的搜索词';
	@override String get searchYourMedia => '搜索媒体';
	@override String get enterTitleActorOrKeyword => '输入标题、演员或关键词';
}

// Path: hotkeys
class Translations$hotkeys$zh extends Translations$hotkeys$en {
	Translations$hotkeys$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => '为 ${actionName} 设置快捷键';
	@override String get clearShortcut => '清除快捷键';
	@override String get noShortcutSet => '未设置快捷键';
	@override String get currentShortcut => '当前快捷键：';
	@override String get pressToRecord => '点击后录入快捷键';
	@override String get recordingShortcut => '请按下快捷键';
	@override late final Translations$hotkeys$actions$zh actions = Translations$hotkeys$actions$zh.internal(_root);
}

// Path: fileInfo
class Translations$fileInfo$zh extends Translations$fileInfo$en {
	Translations$fileInfo$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '文件信息';
	@override String get overview => '简介';
	@override String get video => '视频';
	@override String get audio => '音频';
	@override String get subtitles => '字幕';
	@override String get images => '内嵌图片';
	@override String get dataStreams => '数据流';
	@override String get lyrics => '歌词';
	@override String get file => '文件';
	@override String get attachments => '附件';
	@override String get delivery => '传输方式';
	@override String versionCounter({required Object index, required Object count}) => '第 ${index} 个版本，共 ${count} 个';
	@override String fileCounter({required Object index, required Object count}) => '第 ${index} 个文件，共 ${count} 个';
	@override String get noStreams => '服务器报告此文件没有媒体流。';
	@override String get copyPath => '复制路径';
	@override String get pathCopied => '文件路径已复制';
	@override String get codec => '编解码器';
	@override String get codecTag => '编码器标签';
	@override String get resolution => '分辨率';
	@override String get codedResolution => '编码分辨率';
	@override String get bitrate => '比特率';
	@override String get frameRate => '帧率';
	@override String get rotation => '旋转';
	@override String get comment => '注释';
	@override String get audioDescription => '音频描述';
	@override String get headerCompression => '头部压缩';
	@override String get sidecarFile => '外挂文件';
	@override String get transportTimestamp => '传输时间戳';
	@override String get displayOffset => '显示偏移';
	@override String get previewFailureCode => '预览失败代码';
	@override String get previewRetries => '预览重试次数';
	@override String get aspectRatio => '宽高比';
	@override String get pixelAspectRatio => '像素宽高比';
	@override String get profile => '编码配置';
	@override String get level => '级别';
	@override String get bitDepth => '位深度';
	@override String get pixelFormat => '像素格式';
	@override String get colorSpace => '色彩空间';
	@override String get colorRange => '色彩范围';
	@override String get colorPrimaries => '色彩基色';
	@override String get colorTransfer => '色彩转换';
	@override String get chromaSubsampling => '色度子采样';
	@override String get chromaLocation => '色度位置';
	@override String get scanType => '扫描类型';
	@override String get interlaced => '隔行扫描';
	@override String get anamorphic => '变形宽银幕';
	@override String get referenceFrames => '参考帧';
	@override String get dynamicRange => '动态范围';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Dolby Vision 级别';
	@override String get dolbyVisionVersion => 'Dolby Vision 版本';
	@override String get dolbyVisionLayers => 'Dolby Vision 图层';
	@override String get baseLayerCompatibility => '基础层兼容性';
	@override String get avcBitstream => 'AVC 比特流';
	@override String get nalLengthSize => 'NAL 长度';
	@override String get scalingMatrix => '自定义缩放矩阵';
	@override String get streamIdentifier => '流标识符';
	@override String get streamIndex => '流索引';
	@override String get streamId => '流 ID';
	@override String get language => '语言';
	@override String get languageCode => '语言代码';
	@override String get streamTitle => '轨道标题';
	@override String get channels => '声道';
	@override String get sampleRate => '采样率';
	@override String get spatialAudio => '空间音频';
	@override String get textBased => '基于文本';
	@override String get subtitleFormat => '外挂文件格式';
	@override String get provider => '提供方';
	@override String get matchScore => '匹配分数';
	@override String get externalDelivery => '可单独提供';
	@override String get sidecarPath => '外挂文件路径';
	@override String get sourceStream => '复制来源';
	@override String get temporary => '临时';
	@override String get timeBase => '时间基准';
	@override String get overallBitrate => '总比特率';
	@override String get path => '路径';
	@override String get fileName => '文件名';
	@override String get size => '大小';
	@override String get totalSize => '总大小';
	@override String get container => '容器';
	@override String get duration => '时长';
	@override String get previewThumbnails => '预览缩略图';
	@override String get previewIndex => '预览索引';
	@override String get packetLength => '数据包长度';
	@override String get filePresent => '文件存在';
	@override String get fileReadable => '服务器可读';
	@override String get streamPath => '流路径';
	@override String get optimizedForStreaming => '已针对流式传输优化';
	@override String get has64bitOffsets => '64 位偏移量';
	@override String get protocol => '协议';
	@override String get mediaType => '媒体类型';
	@override String get sourceKind => '来源类型';
	@override String get optimizedVersion => '优化版本';
	@override String get optimizationTarget => '优化目标';
	@override String get deletedAt => '已删除';
	@override String get remoteSource => '远程来源';
	@override String get infiniteStream => '无限流';
	@override String get directPlay => '直接播放';
	@override String get directStream => '直接串流';
	@override String get transcoding => '转码';
	@override String get etag => 'ETag';
	@override String get versionId => '版本 ID';
	@override String get fileId => '文件 ID';
	@override String get defaultAudioTrack => '默认音轨';
	@override String get defaultSubtitleTrack => '默认字幕轨道';
	@override String get subtitlesOff => '关闭';
	@override String get flagDefault => '默认';
	@override String get flagForced => '强制';
	@override String get flagSelected => '已选';
	@override String get flagExternal => '外部';
	@override String get flagHearingImpaired => '听障辅助';
	@override String get flagDub => '配音';
	@override String get flagOriginal => '原声';
	@override String get channelsMono => '单声道';
	@override String dolbyVisionProfile({required Object profile}) => '编码配置 ${profile}';
}

// Path: mediaMenu
class Translations$mediaMenu$zh extends Translations$mediaMenu$en {
	Translations$mediaMenu$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => '标记为已观看';
	@override String get markAsUnwatched => '标记为未观看';
	@override String get removeFromContinueWatching => '从继续观看中移除';
	@override String get viewDetails => '查看详情';
	@override String get goToSeries => '前往剧集';
	@override String get shufflePlay => '随机播放';
	@override String get shuffleNotAvailableOffline => '离线时无法随机播放';
	@override String get fileInfo => '文件信息';
	@override String get deleteEpisodeFromServer => '从服务器删除单集';
	@override String get deleteSeasonFromServer => '从服务器删除季度';
	@override String get deleteShowFromServer => '从服务器删除剧集';
	@override String get deleteMovieFromServer => '从服务器删除电影';
	@override String get deleteEpisodeTitle => '删除这个单集？';
	@override String get deleteSeasonTitle => '删除这一季度？';
	@override String get deleteShowTitle => '删除这部剧集？';
	@override String get deleteMovieTitle => '删除这部电影？';
	@override String get deleteEpisodeConfirm => '删除单集';
	@override String get deleteSeasonConfirm => '删除季度';
	@override String get deleteShowConfirm => '删除剧集';
	@override String get deleteMovieConfirm => '删除电影';
	@override String get deleteAnyway => '仍然删除';
	@override String confirmDeleteTarget({required Object title}) => '从你的服务器永久删除 ${title}？';
	@override String get deleteMultipleWarning => '这包括所有剧集及其文件。';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		other: '这将删除其中全部 ${n} 集以及它们的文件。',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		other: '此项目存储在 ${n} 个文件中，所有这些文件都会被删除。',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		other: '另外 ${n} 集存储在同一个文件中，也会一并删除：',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'Plezy 无法确认此操作会删除哪些文件，因此删除范围可能超出上面提到的项目。请取消后重试，或仍然删除。';
	@override String get deleteScopeUnverifiedNoFileInfo => '你的服务器没有提供此项目的文件详情，因此 Plezy 无法确认此操作会删除哪些文件。删除范围可能超出上面提到的项目。';
	@override String get mediaDeletedSuccessfully => '媒体项已成功删除';
	@override String get mediaFailedToDelete => '删除媒体项失败';
	@override String get rate => '评分';
	@override String get playFromBeginning => '从头播放';
	@override String get playVersion => '播放版本…';
}

// Path: rateSheet
class Translations$rateSheet$zh extends Translations$rateSheet$en {
	Translations$rateSheet$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '评分';
	@override String get server => '服务器';
	@override String get favorite => '收藏';
	@override String get favorited => '已收藏';
	@override String get saved => '已保存';
	@override String get notAvailable => '未找到匹配项';
	@override String get noConnectedServices => '在设置中连接服务，即可在此评分。';
}

// Path: accessibility
class Translations$accessibility$zh extends Translations$accessibility$en {
	Translations$accessibility$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, 电影';
	@override String mediaCardShow({required Object title}) => '${title}, 电视剧';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => '已观看';
	@override String mediaCardPartiallyWatched({required Object percent}) => '已观看 ${percent}%';
	@override String get mediaCardUnwatched => '未观看';
	@override String get tapToPlay => '点击播放';
	@override String get decrease => '减小';
	@override String get increase => '增大';
	@override String decreaseValue({required Object label}) => '减小${label}';
	@override String increaseValue({required Object label}) => '增大${label}';
	@override String get hue => '色相';
	@override String get saturation => '饱和度';
	@override String get brightness => '亮度';
	@override String get hexColor => '十六进制颜色';
	@override String get expandText => '展开文本';
	@override String get collapseText => '折叠文本';
	@override String get alphabetNavigation => '字母导航';
	@override String get alphabetScrollHint => '上下滑动以按字母移动';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => '第 ${row} 行，共 ${rowCount} 行；第 ${column} 列，共 ${columnCount} 列';
	@override String rowPosition({required Object row, required Object rowCount}) => '第 ${row} 行，共 ${rowCount} 行';
	@override String get autoScrollPlay => '开始自动滚动';
	@override String get autoScrollPause => '暂停自动滚动';
	@override String get hueShort => 'H';
	@override String get saturationShort => 'S';
	@override String get valueShort => 'V';
}

// Path: tooltips
class Translations$tooltips$zh extends Translations$tooltips$en {
	Translations$tooltips$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => '随机播放';
	@override String get playTrailer => '播放预告片';
	@override String get markAsWatched => '标记为已观看';
	@override String get markAsUnwatched => '标记为未观看';
}

// Path: audioTracks
class Translations$audioTracks$zh extends Translations$audioTracks$en {
	Translations$audioTracks$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => '音轨 ${n}';
}

// Path: videoControls
class Translations$videoControls$zh extends Translations$videoControls$en {
	Translations$videoControls$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => '音频';
	@override String get subtitlesLabel => '字幕';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String get letterbox => '黑边模式';
	@override String get fillScreen => '填充屏幕';
	@override String get stretch => '拉伸';
	@override String get lockRotation => '锁定旋转';
	@override String get unlockRotation => '解锁旋转';
	@override String get timerActive => '定时器已激活';
	@override String playbackWillPauseIn({required Object duration}) => '播放将在 ${duration} 后暂停';
	@override String get sleepTimerEndOfVideo => '当前视频结束时';
	@override String get sleepTimerStopAtHeader => '停止于';
	@override String get sleepTimerDurationHeader => '定时器';
	@override String get playbackWillPauseAtEnd => '播放将在此视频结束时暂停';
	@override String get stillWatching => '还在看吗？';
	@override String pausingIn({required Object seconds}) => '${seconds} 秒后暂停';
	@override String get continueWatching => '继续';
	@override String get autoPlayNext => '自动播放下一集';
	@override String get playNext => '播放下一集';
	@override String get playButton => '播放';
	@override String get pauseButton => '暂停';
	@override String get playbackPaused => '已暂停';
	@override String get playbackResumed => '正在播放';
	@override String get loadingVideo => '正在加载视频';
	@override String get showPlaybackControls => '显示播放控制项';
	@override String get hidePlaybackControls => '隐藏播放控制项';
	@override String seekBackwardButton({required Object seconds}) => '快退 ${seconds} 秒';
	@override String seekForwardButton({required Object seconds}) => '快进 ${seconds} 秒';
	@override String get previousButton => '上一集';
	@override String get nextButton => '下一集';
	@override String get previousChapterButton => '上一章节';
	@override String get nextChapterButton => '下一章节';
	@override String get muteButton => '静音';
	@override String get unmuteButton => '取消静音';
	@override String get settingsButton => '播放设置';
	@override String get tracksButton => '音频和字幕';
	@override String get chaptersButton => '章节';
	@override String get versionQualityButton => '版本与画质';
	@override String get versionColumnHeader => '版本';
	@override String get qualityColumnHeader => '画质';
	@override String get qualityOriginal => '原始';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => '转码不可用 — 以原始画质播放';
	@override String get subtitleUnavailableFallback => '无法加载所选字幕 — 将继续无字幕播放';
	@override String get pipButton => '画中画';
	@override String get aspectRatioButton => '宽高比';
	@override String get ambientLighting => '氛围灯光';
	@override String get fullscreenButton => '进入全屏';
	@override String get exitFullscreenButton => '退出全屏';
	@override String get alwaysOnTopButton => '窗口置顶';
	@override String get rotationLockButton => '旋转锁定';
	@override String get lockScreen => '锁定屏幕';
	@override String get screenLockButton => '屏幕锁定';
	@override String get longPressToUnlock => '长按解锁';
	@override String get timelineSlider => '视频时间轴';
	@override String get volumeSlider => '音量滑块';
	@override String endsAt({required Object time}) => '结束时间：${time}';
	@override String get pipActive => '正在以画中画模式播放';
	@override String get pipFailed => '画中画启动失败';
	@override String get screenshotSaved => '截图已保存';
	@override String zoomPercent({required Object percent}) => '缩放 ${percent}%';
	@override late final Translations$videoControls$pipErrors$zh pipErrors = Translations$videoControls$pipErrors$zh.internal(_root);
	@override String get chapters => '章节';
	@override String get noChaptersAvailable => '没有可用的章节';
	@override String get queue => '播放队列';
	@override String get noQueueItems => '队列中没有项目';
	@override String get noAudioDevicesAvailable => '没有可用的音频设备';
	@override String get searchSubtitles => '搜索字幕';
	@override String get language => '语言';
	@override String get noSubtitlesFound => '未找到字幕';
	@override String get subtitleDownloaded => '字幕已下载';
	@override String get subtitleDownloadedNotApplied => '字幕已下载，但无法选择';
	@override String get subtitleDownloadFailed => '字幕下载失败';
	@override String get searchLanguages => '搜索语言…';
	@override String get skipIntro => '跳过片头';
	@override String get skipCredits => '跳过片尾';
	@override String get nextEpisode => '下一集';
	@override String subtitleTrack({required Object n}) => '轨道 ${n}';
	@override String subtitleFile({required Object name}) => '字幕 ${name}';
	@override String forcedTrack({required Object label}) => '${label}（强制）';
	@override String get osdSubtitlesOff => '字幕：关闭';
	@override String osdSubtitles({required Object track}) => '字幕：${track}';
	@override String osdAudio({required Object track}) => '音频：${track}';
}

// Path: messages
class Translations$messages$zh extends Translations$messages$en {
	Translations$messages$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => '已标记为已观看';
	@override String get markedAsUnwatched => '已标记为未观看';
	@override String get markedAsWatchedOffline => '已标记为已观看（将在联网时同步）';
	@override String get markedAsUnwatchedOffline => '已标记为未观看（将在联网时同步）';
	@override String autoRemovedWatchedDownload({required Object title}) => '已自动移除：${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		other: '已自动移除 ${n} 个看过的下载',
	);
	@override String get removedFromContinueWatching => '已从继续观看中移除';
	@override String errorLoading({required Object error}) => '出错：${error}';
	@override String get searchPartialResults => '部分媒体服务器无法搜索。正在显示可用的结果。';
	@override String get streamInterrupted => '视频流已中断。按播放键或拖动进度条重试。';
	@override String get liveStreamInterrupted => '直播流已中断。按播放键重试。';
	@override String get fileInfoNotAvailable => '文件信息不可用';
	@override String get playbackAuthenticationRequired => '请重新登录媒体服务器以播放此项目。';
	@override String get playbackServerUnavailable => '媒体服务器不可用。请稍后重试。';
	@override String get playbackDataInvalid => '服务器返回了无效的播放信息。';
	@override String get playbackCancelled => '播放已取消。';
	@override String get playbackFailed => '无法开始播放。';
	@override String errorLoadingFileInfo({required Object error}) => '加载文件信息时出错：${error}';
	@override String get errorLoadingSeries => '加载剧集时出错';
	@override String get musicNotSupported => '尚不支持播放音乐';
	@override String get noDescriptionAvailable => '暂无描述';
	@override String get noProfilesAvailable => '没有可用的用户资料';
	@override String get contactAdminForProfiles => '请联系服务器管理员添加用户资料';
	@override String get unableToDetermineLibrarySection => '无法确定此项目所属的媒体库';
	@override String get logsCleared => '日志已清除';
	@override String get logsCopied => '日志已复制到剪贴板';
	@override String get noLogsAvailable => '没有可用日志';
	@override String libraryScanning({required Object title}) => '正在扫描“${title}”…';
	@override String libraryScanStarted({required Object title}) => '已开始扫描“${title}”媒体库';
	@override String libraryScanFailed({required Object error}) => '无法扫描媒体库：${error}';
	@override String metadataRefreshing({required Object title}) => '正在刷新“${title}”的元数据…';
	@override String metadataRefreshStarted({required Object title}) => '已开始刷新“${title}”的元数据';
	@override String metadataRefreshFailed({required Object error}) => '无法刷新元数据：${error}';
	@override String get logoutConfirm => '确定要退出登录吗？';
	@override String get noSeasonsFound => '未找到季';
	@override String get seasonsLoadFailed => '无法加载季';
	@override String get noEpisodesFound => '在第一季中未找到剧集';
	@override String get noEpisodesFoundGeneral => '未找到剧集';
	@override String get episodesLoadFailed => '无法加载剧集';
	@override String get noResultsFound => '未找到结果';
	@override String sleepTimerSet({required Object label}) => '睡眠定时器已设置为 ${label}';
	@override String get noItemsAvailable => '没有可用的项目';
	@override String get failedToCreatePlayQueueNoItems => '创建播放队列失败：没有可用项目';
	@override String failedPlayback({required Object action, required Object error}) => '无法执行“${action}”：${error}';
	@override String get switchingToCompatiblePlayer => '正在切换到兼容的播放器…';
	@override String get serverLimitTitle => '播放失败';
	@override String get serverLimitBody => '服务器错误（HTTP 500）。此次会话可能因带宽或转码限制而被拒绝。请联系服务器所有者调整限制。';
	@override String get mediaUnreadableTitle => '文件不可用';
	@override String get mediaUnreadableBody => '服务器找到了此项目，但无法读取其文件（HTTP 404）。文件可能已被移动、删除，或其存储已离线。请联系服务器管理员检查文件并重新扫描媒体库。';
	@override String get serverBusyTitle => '视频流不可用';
	@override String get serverBusyBody => '服务器持续拒绝传输此文件（HTTP 503）。服务器可能正在重启或正忙，也可能是文件所在的存储设备已离线。请稍后重试；如果问题持续出现，请联系服务器所有者检查服务器和文件存储设备。';
	@override String get logsUploaded => '日志已上传';
	@override String get logsUploadFailed => '上传日志失败';
	@override String get logId => '日志 ID';
	@override String get burnedSubtitlesUseMenu => '字幕已烧录到此视频流中。请从字幕菜单中更改。';
	@override String get noVideoUrl => '没有可用的视频 URL';
	@override String get playbackNoMediaSources => '服务器未返回可播放的媒体源';
	@override String get playbackDataNotPrepared => '播放数据尚未准备就绪时便开始了播放';
	@override String get streamSelectionUnavailable => '此媒体源不支持选择视频流';
	@override String get streamSelectionFailed => '无法应用所选视频流';
	@override String get serverUnavailableForProfile => '没有可供当前用户资料使用的服务器';
}

// Path: subtitlingStyling
class Translations$subtitlingStyling$zh extends Translations$subtitlingStyling$en {
	Translations$subtitlingStyling$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get text => '文本';
	@override String get border => '边框';
	@override String get background => '背景';
	@override String get fontSize => '字号';
	@override String get textColor => '文本颜色';
	@override String get borderSize => '边框大小';
	@override String get borderColor => '边框颜色';
	@override String get backgroundOpacity => '背景不透明度';
	@override String get backgroundColor => '背景颜色';
	@override String get position => '位置';
	@override String get assOverride => 'ASS 样式覆盖';
	@override String get overrideScale => '缩放';
	@override String get overrideForce => '强制';
	@override String get overrideStrip => '移除样式';
	@override String get positionTop => '顶部';
	@override String get positionBottom => '底部';
	@override String get anchorToScreen => '锚定到屏幕';
	@override String get anchorToScreenDescription => '在宽屏视频下方的黑边中显示文本字幕';
	@override String get bold => '粗体';
	@override String get italic => '斜体';
	@override String get renderResolution => '渲染分辨率';
	@override String get renderResolutionScreen => '屏幕分辨率';
	@override String get renderResolutionVideo => '视频分辨率';
}

// Path: mpvConfig
class Translations$mpvConfig$zh extends Translations$mpvConfig$en {
	Translations$mpvConfig$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv 配置';
	@override String get description => '高级视频播放器设置';
	@override String get presets => '预设';
	@override String get noPresets => '没有保存的预设';
	@override String get saveAsPreset => '保存为预设…';
	@override String get presetName => '预设名称';
	@override String get presetNameHint => '输入此预设的名称';
	@override String get loadPreset => '加载';
	@override String get deletePreset => '删除';
	@override String get presetSaved => '预设已保存';
	@override String get presetLoaded => '预设已加载';
	@override String get presetDeleted => '预设已删除';
	@override String get confirmDeletePreset => '确定要删除此预设吗？';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comment';
	@override String get embeddedVoHint => 'Linux 上会忽略 vo、gpu-context 和 gpu-api：嵌入式视频始终通过视频平面上的 vo=libmpv 渲染，而 gpu-next（ArtCNN 等计算着色器需要它）无法以嵌入式方式运行。';
}

// Path: dialog
class Translations$dialog$zh extends Translations$dialog$en {
	Translations$dialog$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => '确认操作';
}

// Path: profiles
class Translations$profiles$zh extends Translations$profiles$en {
	Translations$profiles$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => '添加 Plezy 用户资料';
	@override String get switchingProfile => '正在切换用户资料…';
	@override String get deleteThisProfileTitle => '删除此用户资料？';
	@override String deleteThisProfileMessage({required Object displayName}) => '移除 ${displayName}。连接不会受影响。';
	@override String get active => '当前使用';
	@override String get manage => '管理';
	@override String get delete => '删除';
	@override String get signOut => '退出登录';
	@override String get signOutPlexTitle => '退出 Plex 登录？';
	@override String signOutPlexMessage({required Object displayName}) => '要移除 ${displayName} 和所有 Plex Home 用户吗？可随时重新登录。';
	@override String get signedOutPlex => '已退出 Plex 登录。';
	@override String get signOutFailed => '退出登录失败。';
	@override String get sectionTitle => '用户资料';
	@override String get summarySingle => '添加用户资料，以便同时使用受管理用户和本地用户身份';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} 个用户资料 · 当前：${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} 个用户资料';
	@override String get removeConnectionTitle => '移除连接？';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => '移除 ${displayName} 对 ${connectionLabel} 的访问权限。其他用户资料仍可使用此连接。';
	@override String get deleteProfileTitle => '删除用户资料？';
	@override String deleteProfileMessage({required Object displayName}) => '移除 ${displayName} 及其连接。服务器仍可供其他用户资料使用。';
	@override String get profileNameLabel => '用户资料名称';
	@override String get pinProtectionLabel => 'PIN 保护';
	@override String get pinManagedByPlex => 'PIN 由 Plex 管理。在 plex.tv 上编辑。';
	@override String get noPinSetEditOnPlex => '未设置 PIN。如需设置，请在 plex.tv 上编辑 Plex Home 用户。';
	@override String get setPin => '设置 PIN';
	@override String get setPinTitle => '设置 PIN';
	@override String get confirmPinTitle => '确认 PIN';
	@override String get pinSet => '已设置 PIN';
	@override String get changePin => '更改';
	@override String get removePin => '移除';
	@override String get connectionsLabel => '连接';
	@override String get add => '添加';
	@override String get deleteProfileButton => '删除用户资料';
	@override String get noConnectionsHint => '没有连接 — 请添加连接以使用此用户资料。';
	@override String get noConnections => '没有连接';
	@override String get plexHomeAccount => 'Plex Home 账户';
	@override String plexAccountChip({required Object account}) => 'Plex 账户：${account}';
	@override String plexAccountUserChip({required Object account, required Object user}) => '${account} 账户下的 ${user}';
	@override String get connectionDefault => '默认';
	@override String connectionAs({required Object displayName}) => '以 ${displayName} 身份';
	@override String get makeDefault => '设为默认';
	@override String get removeConnection => '移除';
	@override String get profileRenamed => '用户资料已重命名。';
	@override String borrowAddTo({required Object displayName}) => '添加到 ${displayName}';
	@override String get borrowExplain => '使用另一个用户资料的连接。受 PIN 保护的用户资料需要输入 PIN。';
	@override String get borrowEmpty => '暂无可用连接。';
	@override String get borrowEmptySubtitle => '请先将 Plex 或 Jellyfin 连接到另一个用户资料。';
	@override String get borrowLoadFailed => '无法加载可用连接。请重试。';
	@override String borrowFromProfile({required Object displayName}) => '来自 ${displayName}';
	@override String get borrowConnectionBorrowed => '连接已添加。';
	@override String get borrowFailed => '无法添加连接。';
	@override String get incorrectPin => 'PIN 不正确。';
	@override String get incorrectPinTryAgain => 'PIN 不正确。请重试。';
	@override String get sourceProfileMissingParentAccount => '源用户资料缺少关联的主账户。';
	@override String get failedToLoadHomeUsers => '无法加载您的 Plex Home 用户。请检查网络连接后重试。';
	@override String get failedToVerifyPin => '无法验证 PIN。';
	@override String get newProfile => '新建用户资料';
	@override String get profileNameHint => '例如：访客、儿童、客厅';
	@override String get pinProtectionOptional => 'PIN 保护（可选）';
	@override String get pinExplain => '切换用户资料时需要输入 4 位 PIN。';
	@override String get continueButton => '继续';
	@override String get pinsDontMatch => 'PIN 不匹配';
	@override String get tokenIdentityMismatch => 'Plex 用户资料令牌解析到了非预期服务器';
}

// Path: connections
class Translations$connections$zh extends Translations$connections$en {
	Translations$connections$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '连接';
	@override String get addConnection => '添加连接';
	@override String get addConnectionSubtitleNoProfile => '使用 Plex 登录或连接 Jellyfin 服务器';
	@override String addConnectionSubtitleScoped({required Object displayName}) => '添加到 ${displayName}：Plex、Jellyfin，或其他用户资料的连接';
	@override String sessionExpiredOne({required Object name}) => '${name} 的会话已过期';
	@override String sessionExpiredMany({required Object count}) => '${count} 个服务器的会话已过期';
	@override String get signInAgain => '重新登录';
	@override String editMediaBrowserTitle({required Object product}) => '编辑 ${product} 连接';
	@override String editMediaBrowserIntro({required Object serverName}) => '为 ${serverName} 添加或移除 URL。Plezy 会使用延迟最低且可访问的 URL。';
}

// Path: discover
class Translations$discover$zh extends Translations$discover$en {
	Translations$discover$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '发现';
	@override String get noContentAvailable => '没有可用内容';
	@override String get addMediaToLibraries => '请向你的媒体库添加一些媒体';
	@override String get continueWatching => '继续观看';
	@override String continueWatchingIn({required Object library}) => '${library} 中继续观看';
	@override String get nextUp => '接下来';
	@override String nextUpIn({required Object library}) => '${library} 中接下来';
	@override String get recentlyAdded => '最近添加';
	@override String recentlyAddedIn({required Object library}) => '${library} 中最近添加';
	@override String latestAlbumsIn({required Object library}) => '${library} 中的最新专辑';
	@override String recentlyPlayedIn({required Object library}) => '${library} 中最近播放';
	@override String mostPlayedIn({required Object library}) => '${library} 中最常播放';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => '概述';
	@override String get cast => '演员表';
	@override String get extras => '预告片与花絮';
	@override String get studio => '制作公司';
	@override String get rating => '年龄分级';
	@override String get director => '导演';
	@override String get directors => '导演';
	@override String get movie => '电影';
	@override String get tvShow => '电视剧';
	@override String minutesLeft({required Object minutes}) => '剩余 ${minutes} 分钟';
	@override String get moreLikeThis => '更多类似内容';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		other: '${n} 个标题',
	);
}

// Path: errors
class Translations$errors$zh extends Translations$errors$en {
	Translations$errors$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => '搜索失败：${error}';
	@override String get searchUnavailable => '搜索无法连接任何媒体服务器。';
	@override String connectionTimeout({required Object context}) => '加载 ${context} 时连接超时';
	@override String get connectionFailed => '无法连接到媒体服务器';
	@override String unableToLoad({required Object context}) => '无法加载${context}。请重试。';
	@override String get noClientAvailable => '没有可用客户端';
	@override String get pleaseEnterToken => '请输入一个令牌';
	@override String get invalidToken => '令牌无效';
	@override String failedToVerifyToken({required Object error}) => '无法验证令牌：${error}';
	@override String failedToSwitchProfile({required Object displayName}) => '无法切换到 ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => '无法删除 ${displayName}';
	@override String get failedToRate => '无法更新评分';
}

// Path: libraries
class Translations$libraries$zh extends Translations$libraries$en {
	Translations$libraries$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '媒体库';
	@override String get fallbackTitle => '媒体库';
	@override String get scanLibraryFiles => '扫描媒体库文件';
	@override String get scanLibrary => '扫描媒体库';
	@override String get analyze => '分析';
	@override String get analyzeLibrary => '分析媒体库';
	@override String get refreshMetadata => '刷新元数据';
	@override String get emptyTrash => '清空回收站';
	@override String emptyingTrash({required Object title}) => '正在清空“${title}”的回收站…';
	@override String trashEmptied({required Object title}) => '已清空“${title}”的回收站';
	@override String failedToEmptyTrash({required Object error}) => '无法清空回收站：${error}';
	@override String analyzing({required Object title}) => '正在分析“${title}”…';
	@override String analysisStarted({required Object title}) => '已开始分析“${title}”';
	@override String failedToAnalyze({required Object error}) => '无法分析媒体库：${error}';
	@override String get noLibrariesFound => '未找到媒体库';
	@override String get allLibrariesHidden => '所有媒体库已隐藏';
	@override String hiddenLibrariesCount({required Object count}) => '已隐藏的媒体库 (${count})';
	@override String get thisLibraryIsEmpty => '此媒体库为空';
	@override String get noItemsMatchFilters => '没有项目符合当前筛选条件';
	@override String get resetFilters => '重置筛选条件';
	@override String get all => '全部';
	@override String get clearAll => '全部清除';
	@override String scanLibraryConfirm({required Object title}) => '确定要扫描“${title}”吗？';
	@override String analyzeLibraryConfirm({required Object title}) => '确定要分析“${title}”吗？';
	@override String refreshMetadataConfirm({required Object title}) => '确定要刷新“${title}”的元数据吗？';
	@override String emptyTrashConfirm({required Object title}) => '确定要清空“${title}”的回收站吗？';
	@override String get manageLibraries => '管理媒体库';
	@override String get sort => '排序';
	@override String get sortBy => '排序依据';
	@override String get filters => '筛选';
	@override String get confirmActionMessage => '确定要执行此操作吗？';
	@override String get showLibrary => '显示媒体库';
	@override String get hideLibrary => '隐藏媒体库';
	@override String get libraryOptions => '媒体库选项';
	@override String get content => '媒体库内容';
	@override String get selectLibrary => '选择媒体库';
	@override String filtersWithCount({required Object count}) => '筛选器（${count}）';
	@override String get noRecommendations => '暂无推荐';
	@override String get noCollections => '此媒体库中没有合集';
	@override String get noFoldersFound => '未找到文件夹';
	@override String get folders => '文件夹';
	@override late final Translations$libraries$tabs$zh tabs = Translations$libraries$tabs$zh.internal(_root);
	@override late final Translations$libraries$groupings$zh groupings = Translations$libraries$groupings$zh.internal(_root);
	@override late final Translations$libraries$filterCategories$zh filterCategories = Translations$libraries$filterCategories$zh.internal(_root);
	@override late final Translations$libraries$sortLabels$zh sortLabels = Translations$libraries$sortLabels$zh.internal(_root);
}

// Path: about
class Translations$about$zh extends Translations$about$en {
	Translations$about$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '关于';
	@override String get openSourceLicenses => '开源许可证';
	@override String versionLabel({required Object version}) => '版本 ${version}';
	@override String get appDescription => '一款精美的 Flutter Plex 和 Jellyfin 客户端';
	@override String get viewLicensesDescription => '查看第三方库的许可证';
}

// Path: serverSelection
class Translations$serverSelection$zh extends Translations$serverSelection$en {
	Translations$serverSelection$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => '未找到 ${username}（${email}）的服务器';
	@override String failedToLoadServers({required Object error}) => '无法加载服务器：${error}';
	@override String get noValidServers => '此账号下未找到可用的服务器';
}

// Path: hubDetail
class Translations$hubDetail$zh extends Translations$hubDetail$en {
	Translations$hubDetail$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '标题';
	@override String get releaseYear => '发行年份';
	@override String get dateAdded => '添加日期';
	@override String get rating => '评分';
	@override String get noItemsFound => '未找到项目';
}

// Path: logs
class Translations$logs$zh extends Translations$logs$en {
	Translations$logs$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => '清除日志';
	@override String get copyLogs => '复制日志';
	@override String get uploadLogs => '上传日志';
}

// Path: startup
class Translations$startup$zh extends Translations$startup$en {
	Translations$startup$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'Plezy 无法启动';
	@override String get failedBody => '启动过程中出现问题。以下详情指出了失败的原因。';
	@override String get failedBodyRepairable => 'Plezy 的已保存设置文件已损坏，必须先重建才能启动。重试没有用——请选择“修复存储”。';
	@override String get phaseLabel => '步骤';
	@override String get showDetails => '显示详情';
	@override String get hideDetails => '隐藏详情';
	@override String get copyDetails => '复制详情';
	@override String get detailsCopied => '详情已复制到剪贴板';
	@override String get uploadDetails => '上传详情';
	@override String get repairStorage => '修复存储';
	@override String get repairTitle => '修复已存储的数据？';
	@override String get repairBodyCommon => 'Plezy 的设置文件已损坏且无法读取。修复会将所有设置重置为默认值。';
	@override String get repairBodyOneCredential => '有一项已保存的登录信息已损坏且无法读取。修复只会移除这一项，其他设置保持不变。';
	@override String get repairBodySignInsKept => '你的服务器和个人资料应保持登录状态。';
	@override String get repairBodySignInsLost => '保护已保存登录信息的密钥无法从此文件中恢复，因此你需要重新登录每个服务器和个人资料。媒体服务器上的内容不受影响。';
	@override String get repairBodySessionsUncertain => '追踪服务（MAL、AniList、Simkl、Trakt）和 Seerr 是分开存储的，可能保留也可能无法保留。Plezy 会明确告诉你保留了哪些。';
	@override String get repairConfirm => '修复';
	@override String get repairSucceeded => '存储已修复';
	@override String get repairNeedsRestart => '存储已修复 — 需要重启';
	@override String get restartRequiredBody => '你的数据已修复，但 Plezy 需要重新启动后才能使用。请关闭 Plezy 并重新打开。';
	@override String get quitPlezy => '退出 Plezy';
	@override String get repairFailed => '修复失败';
	@override String get repairKeptSignIns => '你的服务器和个人资料仍然保持登录状态。';
	@override String get repairLostSignIns => '保护已保存登录信息的密钥无法恢复。你需要重新登录每个服务器和个人资料。';
	@override String get repairLostSessions => '至少有一个追踪服务或 Seerr 连接已丢失，需要重新连接。';
	@override String get backupTitle => '已保留损坏文件的副本';
	@override String get backupWarning => '其中包含你的登录凭据。请勿上传或分享。';
	@override String get deleteBackup => '删除副本';
	@override String get backupDeleted => '副本已删除。';
	@override String get previousFailureTitle => 'Plezy 上次启动失败';
}

// Path: licenses
class Translations$licenses$zh extends Translations$licenses$en {
	Translations$licenses$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => '相关软件包';
	@override String get license => '许可证';
	@override String licenseNumber({required Object number}) => '许可证 ${number}';
	@override String licensesCount({required Object count}) => '${count} 个许可证';
}

// Path: navigation
class Translations$navigation$zh extends Translations$navigation$en {
	Translations$navigation$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get libraries => '媒体库';
	@override String get downloads => '下载';
	@override String get liveTv => '直播电视';
	@override String get explore => '探索';
}

// Path: explore
class Translations$explore$zh extends Translations$explore$en {
	Translations$explore$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '探索';
	@override String get selectSource => '选择来源';
	@override late final Translations$explore$rows$zh rows = Translations$explore$rows$zh.internal(_root);
	@override late final Translations$explore$status$zh status = Translations$explore$status$zh.internal(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		other: '${n} 集',
	);
	@override String get cast => '演员表';
	@override String get characters => '角色';
	@override String get addToWatchlist => '添加到想看列表';
	@override String get removeFromWatchlist => '从想看列表移除';
	@override String get addedToWatchlist => '已加入待看列表';
	@override String get removedFromWatchlist => '已从待看列表中移除';
	@override String get watchlistUpdateFailed => '无法更新想看列表';
	@override String get watchlistNoMatch => '无法将此项目与待看列表匹配';
	@override String get notInLibrary => '不在你的媒体库中';
	@override String get inTheseLibraries => '在这些媒体库中';
	@override String get checkingLibrary => '正在检查你的媒体库…';
	@override String get emptyTitle => '这里还什么都没有';
	@override String emptyMessage({required Object source}) => '当 ${source} 有内容时，相关内容将显示在这里。';
	@override String searchHint({required Object source}) => '搜索 ${source}';
	@override String searchEmpty({required Object query}) => '没有“${query}”的结果';
	@override String searchPrompt({required Object source}) => '在 ${source} 上搜索电影和剧集。';
	@override String get searchFailed => '搜索失败。请检查网络连接后重试。';
	@override late final Translations$explore$badge$zh badge = Translations$explore$badge$zh.internal(_root);
	@override late final Translations$explore$stats$zh stats = Translations$explore$stats$zh.internal(_root);
	@override late final Translations$explore$season$zh season = Translations$explore$season$zh.internal(_root);
	@override late final Translations$explore$format$zh format = Translations$explore$format$zh.internal(_root);
	@override late final Translations$explore$sourceMaterial$zh sourceMaterial = Translations$explore$sourceMaterial$zh.internal(_root);
	@override late final Translations$explore$creditRole$zh creditRole = Translations$explore$creditRole$zh.internal(_root);
	@override late final Translations$explore$relation$zh relation = Translations$explore$relation$zh.internal(_root);
	@override String broadcast({required Object day, required Object time}) => '每周${day} ${time}播出';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => '每周${day} ${time} ${timezone}播出';
	@override late final Translations$explore$detail$zh detail = Translations$explore$detail$zh.internal(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		other: '${n} 条结果',
	);
}

// Path: liveTv
class Translations$liveTv$zh extends Translations$liveTv$en {
	Translations$liveTv$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '直播电视';
	@override String get guide => '节目指南';
	@override String get noChannels => '没有可用的频道';
	@override String get noDvr => '没有服务器配置 DVR';
	@override String get serverUnavailable => '直播电视服务器不可用。';
	@override String get serverNotConnected => '直播电视服务器未连接。';
	@override String get noPrograms => '没有可用的节目数据';
	@override String get liveStreamFailed => '直播流失败';
	@override String get unknownProgram => '未知节目';
	@override String get unknownHub => '未知';
	@override String get unknownError => '未知错误';
	@override String channelNumber({required Object number}) => '频道 ${number}';
	@override String get unknownChannel => '未知频道';
	@override String get live => '直播';
	@override String get reloadGuide => '重新加载节目指南';
	@override String searchNoResults({required Object query}) => 'No matches for "${query}"';
	@override String get now => '现在';
	@override String get today => '今天';
	@override String get tomorrow => '明天';
	@override String get midnight => '午夜';
	@override String get overnight => '凌晨';
	@override String get morning => '上午';
	@override String get daytime => '白天';
	@override String get evening => '晚上';
	@override String get lateNight => '深夜';
	@override String get whatsOn => '正在播出';
	@override String get watchChannel => '观看频道';
	@override String get favorites => '收藏';
	@override String get reorderFavorites => '重新排序收藏';
	@override String get noFavoriteChannels => '没有收藏的频道';
	@override String get noFavoriteChannelsHint => '显示所有频道，然后长按某个频道将其加入收藏。';
	@override String get showAllChannels => '显示所有频道';
	@override String get favoritesLoadFailed => '无法加载收藏。请检查网络连接后重试。';
	@override String get favoritesUpdateFailed => '无法更新收藏。请检查网络连接后重试。';
	@override String get joinSession => '加入正在进行的会话';
	@override String watchFromStart({required Object minutes}) => '从头观看（${minutes}分钟前开始）';
	@override String get watchLive => '观看直播';
	@override String get goToLive => '跳至直播';
	@override String get record => '录制';
	@override String get recordEpisode => '录制单集';
	@override String get recordSeries => '录制系列节目';
	@override String get recordOptions => '录制选项';
	@override String get saveTo => '保存到';
	@override String get recordings => '录制内容';
	@override String get scheduledRecordings => '计划录制';
	@override String get recordingRules => '录制规则';
	@override String get noScheduledRecordings => '没有安排的录制';
	@override String get manageRecording => '管理录制';
	@override String get cancelRecording => '取消录制';
	@override String get cancelRecordingTitle => '取消此次录制？';
	@override String cancelRecordingMessage({required Object title}) => '将不再录制 ${title}。';
	@override String get deleteRule => '删除规则';
	@override String get deleteRuleTitle => '删除录制规则？';
	@override String deleteRuleMessage({required Object title}) => '今后将不再录制 ${title} 的剧集。';
	@override String get recordingScheduled => '录制已安排';
	@override String get alreadyScheduled => '此节目已安排录制';
	@override String get dvrAdminRequired => 'DVR 设置需要管理员账户';
	@override String get recordingFailed => '无法安排录制';
	@override String get recordingTargetMissing => '无法确定录制库';
	@override String get recordNotAvailable => '此节目无法录制';
	@override String get recordingCancelled => '录制已取消';
	@override String get recordingRuleDeleted => '录制规则已删除';
	@override String get processRecordingRules => '重新评估规则';
	@override String get recordingInProgress => '正在录制';
	@override String recordingsCount({required Object count}) => '已安排 ${count} 项录制';
	@override String get editRule => '编辑规则';
	@override String get editRuleAction => '编辑';
	@override String get recordingRuleUpdated => '录制规则已更新';
	@override String get guideReloadRequested => '已请求更新节目指南';
	@override String get rulesProcessRequested => '已请求重新评估规则';
	@override String get recordShow => '录制节目';
	@override late final Translations$liveTv$recordSettings$zh recordSettings = Translations$liveTv$recordSettings$zh.internal(_root);
	@override String startingInMinutes({required Object minutes}) => '${minutes} 分钟后开始';
	@override String dayAtTime({required Object day, required Object time}) => '${day} ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} 返回了无效的直播电视播放数据';
	@override String get failedToStartChannel => '无法播放直播频道';
	@override String get failedToBuildStreamUrl => '无法生成视频流 URL';
}

// Path: collections
class Translations$collections$zh extends Translations$collections$en {
	Translations$collections$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '合集';
	@override String get collection => '合集';
	@override String get empty => '合集为空';
	@override String get deleteCollection => '删除合集';
	@override String deleteConfirm({required Object title}) => '要删除“${title}”吗？此操作无法撤销。';
	@override String get deleted => '已删除合集';
	@override String get deleteFailed => '删除合集失败';
	@override String deleteFailedWithError({required Object error}) => '删除合集失败：${error}';
	@override String get selectCollection => '选择合集';
	@override String get collectionName => '合集名称';
	@override String get enterCollectionName => '输入合集名称';
	@override String get addedToCollection => '已添加到合集';
	@override String get errorAddingToCollection => '添加到合集失败';
	@override String get created => '已创建合集';
	@override String get removeFromCollection => '从合集移除';
	@override String removeFromCollectionConfirm({required Object title}) => '将“${title}”从此合集移除？';
	@override String get removedFromCollection => '已从合集移除';
	@override String get removeFromCollectionFailed => '从合集移除失败';
	@override String removeFromCollectionError({required Object error}) => '从合集移除时出错：${error}';
	@override String get searchCollections => '搜索合集…';
}

// Path: playlists
class Translations$playlists$zh extends Translations$playlists$en {
	Translations$playlists$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '播放列表';
	@override String get playlist => '播放列表';
	@override String get noPlaylists => '未找到播放列表';
	@override String get create => '创建播放列表';
	@override String get playlistName => '播放列表名称';
	@override String get enterPlaylistName => '输入播放列表名称';
	@override String get delete => '删除播放列表';
	@override String get removeItem => '从播放列表中移除';
	@override String get smartPlaylist => '智能播放列表';
	@override String itemCount({required Object count}) => '${count} 个项目';
	@override String get oneItem => '1 个项目';
	@override String get emptyPlaylist => '此播放列表为空';
	@override String get deleteConfirm => '删除播放列表？';
	@override String deleteMessage({required Object name}) => '确定要删除“${name}”吗？';
	@override String get created => '播放列表已创建';
	@override String get deleted => '播放列表已删除';
	@override String get itemAdded => '已添加到播放列表';
	@override String get itemRemoved => '已从播放列表中移除';
	@override String get selectPlaylist => '选择播放列表';
	@override String get searchPlaylists => '搜索播放列表…';
	@override String get errorCreating => '创建播放列表失败';
	@override String get errorDeleting => '删除播放列表失败';
	@override String get errorLoading => '加载播放列表失败';
	@override String get errorAdding => '添加到播放列表失败';
	@override String get errorReordering => '重新排序播放列表项目失败';
	@override String get errorRemoving => '从播放列表中移除失败';
}

// Path: music
class Translations$music$zh extends Translations$music$en {
	Translations$music$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => '前往专辑';
	@override String get goToArtist => '前往艺术家';
	@override String get instantMix => '即时混合播放';
	@override String get playNext => '下一首播放';
	@override String get addToQueue => '添加到队列';
	@override String discNumber({required Object n}) => '碟片 ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		other: '${n} 首',
	);
	@override String get nowPlaying => '正在播放';
	@override String playingFrom({required Object title}) => '播放来源：${title}';
	@override String get queue => '播放队列';
	@override String get clearQueue => '清空队列';
	@override String get lyrics => '歌词';
	@override String get noLyrics => '暂无歌词';
	@override String get sleepTimer => '睡眠定时器';
	@override String get sleepTimerEndOfTrack => '当前曲目结束时';
	@override String sleepTimerMinutes({required Object n}) => '${n} 分钟';
	@override String get stopPlayback => '停止播放';
	@override String get previousTrack => '上一首';
	@override String get nextTrack => '下一首';
	@override String get repeat => '循环';
	@override String get repeatAll => '列表循环';
	@override String get repeatOne => '单曲循环';
	@override String get instantMixNoServer => '没有可用于即时混合的服务器';
	@override String noAudioUrl({required Object track}) => '没有可供 ${track} 使用的音频 URL';
	@override late final Translations$music$discography$zh discography = Translations$music$discography$zh.internal(_root);
}

// Path: watchTogether
class Translations$watchTogether$zh extends Translations$watchTogether$en {
	Translations$watchTogether$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '一起看';
	@override String get description => '与朋友和家人同步观看内容';
	@override String get createSession => '创建会话';
	@override String get creating => '正在创建…';
	@override String get joinSession => '加入会话';
	@override String get joining => '正在加入…';
	@override String get controlMode => '控制模式';
	@override String get controlModeQuestion => '谁可以控制播放？';
	@override String get hostOnly => '仅主持人';
	@override String get anyone => '任何人';
	@override String get hostingSession => '主持会话';
	@override String get inSession => '在会话中';
	@override String get sessionCode => '会话代码';
	@override String get openSessionControls => '打开“一起看”会话控制';
	@override String get copySessionCode => '复制会话代码';
	@override String get hostControlsPlayback => '主持人控制播放';
	@override String get anyoneCanControl => '任何人都可以控制播放';
	@override String get hostControls => '主持人控制';
	@override String get anyoneControls => '任何人控制';
	@override String get participants => '参与者';
	@override String get host => '主持人';
	@override String get hostBadge => '主持人';
	@override String get youAreHost => '你是主持人';
	@override String get watchingWithOthers => '与他人一起观看';
	@override String get endSession => '结束会话';
	@override String get leaveSession => '离开会话';
	@override String get endSessionQuestion => '结束会话？';
	@override String get leaveSessionQuestion => '离开会话？';
	@override String get endSessionConfirm => '这将为所有参与者结束会话。';
	@override String get leaveSessionConfirm => '你将被移出会话。';
	@override String get endSessionConfirmOverlay => '这将为所有参与者结束观看会话。';
	@override String get leaveSessionConfirmOverlay => '你将断开与观看会话的连接。';
	@override String get end => '结束';
	@override String get leave => '离开';
	@override String get syncing => '正在同步…';
	@override String get joinWatchSession => '加入观看会话';
	@override String get enterCodeHint => '输入 5 位代码';
	@override String get pasteFromClipboard => '从剪贴板粘贴';
	@override String get pleaseEnterCode => '请输入会话代码';
	@override String get codeMustBe5Chars => '会话代码必须是 5 个字符';
	@override String get joinInstructions => '输入主持人的会话代码以加入。';
	@override String get failedToCreate => '创建会话失败';
	@override String get failedToJoin => '加入会话失败';
	@override String get sessionCodeCopied => '会话代码已复制到剪贴板';
	@override String get relayUnreachable => '无法访问中继服务器。网络运营商的屏蔽可能导致“一起看”不可用。';
	@override String get reconnectingToHost => '正在重新连接到主持人…';
	@override String get currentPlayback => '当前播放';
	@override String get joinCurrentPlayback => '加入当前播放';
	@override String get joinCurrentPlaybackDescription => '加入主持人当前正在观看的内容';
	@override String get failedToOpenCurrentPlayback => '无法打开当前播放';
	@override String participantJoined({required Object name}) => '${name} 已加入';
	@override String participantLeft({required Object name}) => '${name} 已离开';
	@override String participantPaused({required Object name}) => '${name} 暂停了播放';
	@override String participantResumed({required Object name}) => '${name} 恢复了播放';
	@override String participantSeeked({required Object name}) => '${name} 更改了播放位置';
	@override String participantBuffering({required Object name}) => '${name} 正在缓冲';
	@override String participantNeedsUpdate({required Object name}) => '${name} 正在使用较旧版本的应用，无法同步';
	@override String resumingWithout({required Object name}) => '不再等待 ${name}，继续播放';
	@override String get waitingForParticipants => '正在等待其他人加载…';
	@override String waitingForName({required Object name}) => '正在等待 ${name}…';
	@override String get recentRooms => '最近的房间';
	@override String get renameRoom => '重命名房间';
	@override String get removeRoom => '移除';
	@override String get guestSwitchUnavailable => '无法切换 — 服务器不可用于同步';
	@override String get guestSwitchFailed => '无法切换 — 在此服务器上未找到内容';
	@override String get defaultDisplayName => '用户';
	@override late final Translations$watchTogether$errors$zh errors = Translations$watchTogether$errors$zh.internal(_root);
}

// Path: downloads
class Translations$downloads$zh extends Translations$downloads$en {
	Translations$downloads$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '下载';
	@override String get manage => '管理';
	@override String get tvShows => '电视剧';
	@override String get movies => '电影';
	@override String get music => '音乐';
	@override String tracksQueued({required Object count}) => '${count} 首曲目已加入下载队列';
	@override String get noDownloads => '暂无下载';
	@override String get noDownloadsDescription => '下载的内容将在此处显示以供离线观看';
	@override String get downloadNow => '下载';
	@override String get deleteDownload => '删除下载';
	@override String get retryDownload => '重试下载';
	@override String get downloadQueued => '下载已排队';
	@override String get downloadResumed => '下载已继续';
	@override String get serverErrorBitrate => '服务器错误：文件可能超过远程比特率限制';
	@override String get storageFull => '设备存储空间已满，因此下载已停止。请释放空间后重试。';
	@override String episodesQueued({required Object count}) => '${count} 集已加入下载队列';
	@override String get downloadDeleted => '下载已删除';
	@override String deleteConfirm({required Object title}) => '要从此设备删除“${title}”吗？';
	@override String get cancelledDownloadTitle => '已取消的下载';
	@override String get cancelledDownloadMessage => '此下载已取消。你想怎么做？';
	@override String get allEpisodesAlreadyDownloaded => '所有剧集均已下载';
	@override String get resumeDownload => '继续下载';
	@override String get cancelledDownload => '已取消的下载';
	@override String syncingFile({required Object file, required Object status}) => '${file}（正在同步 ${status}）';
	@override String downloadedFileClickToComplete({required Object file}) => '已下载 ${file} — 点击以完成';
	@override String get partialDownloadClickToComplete => '已部分下载 — 点击以完成';
	@override String get deleting => '正在删除…';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => '正在删除 ${title}…（${current}/${total}）';
	@override String get queuedTooltip => '已排队';
	@override String queuedFilesTooltip({required Object files}) => '已排队：${files}';
	@override String get downloadingTooltip => '正在下载…';
	@override String downloadingFilesTooltip({required Object files}) => '正在下载 ${files}';
	@override String get noDownloadsTree => '暂无下载';
	@override String get pauseAll => '全部暂停';
	@override String get resumeAll => '全部继续';
	@override String get deleteAll => '全部删除';
	@override String get selectVersion => '选择版本';
	@override String get allEpisodes => '所有剧集';
	@override String get unwatchedOnly => '仅未观看';
	@override String nextNUnwatched({required Object count}) => '接下来 ${count} 集未观看';
	@override String get customAmount => '自定义数量…';
	@override String get includeSpecials => '包含特别篇';
	@override String get howManyEpisodes => '下载几集？';
	@override String get invalidEpisodeCount => '请输入有效的集数。';
	@override String get keepSynced => '保持同步';
	@override String get downloadOnce => '下载一次';
	@override String keepNUnwatched({required Object count}) => '保留 ${count} 集未观看内容';
	@override String get editSyncRule => '编辑同步规则';
	@override String get removeSyncRule => '删除同步规则';
	@override String removeSyncRuleConfirm({required Object title}) => '停止同步“${title}”？已下载的剧集将被保留。';
	@override String removeListSyncRuleConfirm({required Object title}) => '停止同步“${title}”？';
	@override String get deleteSyncRuleDownloads => '同时删除相关下载';
	@override String get deleteSyncRuleDownloadsDescription => '被其他同步规则或个人资料使用的下载将保留。';
	@override String syncRuleCreated({required Object count}) => '同步规则已创建 — 保留 ${count} 集未观看内容';
	@override String get syncRuleUpdated => '同步规则已更新';
	@override String get syncRuleRemoved => '同步规则已删除';
	@override String get syncRuleAndDownloadsRemoved => '同步规则及相关下载已删除';
	@override String get syncRuleCleanupBusy => '同步规则正在更新中，请稍后再试。';
	@override String get syncRuleCleanupUnavailable => '无法安全识别相关下载。请重新连接服务器后再试，或在不删除下载的情况下移除规则。';
	@override String syncedNewEpisodes({required Object title, required Object count}) => '已为 ${title} 同步 ${count} 个新剧集';
	@override String get activeSyncRules => '同步规则';
	@override String get noSyncRules => '没有同步规则';
	@override String get manageSyncRule => '管理同步';
	@override String get editEpisodeCount => '剧集数量';
	@override String get editSyncFilter => '同步筛选';
	@override String get syncAllItems => '同步所有项目';
	@override String get syncUnwatchedItems => '同步未观看项目';
	@override String syncRuleServerContext({required Object server, required Object status}) => '服务器：${server} • ${status}';
	@override String get syncRuleAvailable => '可用';
	@override String get syncRuleOffline => '离线';
	@override String get syncRuleSignInRequired => '需要登录';
	@override String get syncRuleNotAvailableForProfile => '当前用户资料不可用';
	@override String get syncRuleUnknownServer => '未知服务器';
	@override String get syncRuleListCreated => '同步规则已创建';
	@override late final Translations$downloads$backgroundWarning$zh backgroundWarning = Translations$downloads$backgroundWarning$zh.internal(_root);
	@override String get unknownShow => '未知节目';
	@override String get unknownSeason => '未知季';
	@override String get unknownAlbum => '未知专辑';
	@override String completedOfTotal({required Object completed, required Object total}) => '已完成 ${completed}/${total}';
	@override String get errorFileNotFound => '未找到文件（404）';
	@override String get errorDownloadFailed => '下载失败';
	@override String errorPostProcessing({required Object error}) => '后处理失败：${error}';
	@override String get notificationDownloading => '正在下载…';
	@override String get notificationComplete => '下载完成';
	@override String get notificationPaused => '下载已暂停';
}

// Path: shaders
class Translations$shaders$zh extends Translations$shaders$en {
	Translations$shaders$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '着色器';
	@override String get noShaderDescription => '无视频增强';
	@override String get nvscalerDescription => 'NVIDIA 图像缩放，使视频更清晰';
	@override String get artcnnVariantNeutral => '中性';
	@override String get artcnnVariantDenoise => '降噪';
	@override String get artcnnVariantDenoiseSharpen => '降噪 + 锐化';
	@override String get qualityFast => '快速';
	@override String get qualityHQ => '高质量';
	@override String get mode => '模式';
	@override String get importShader => '导入着色器';
	@override String get customShaderDescription => '自定义 GLSL 着色器';
	@override String get shaderImported => '着色器已导入';
	@override String get shaderImportFailed => '导入着色器失败';
	@override String get deleteShader => '删除着色器';
	@override String deleteShaderConfirm({required Object name}) => '删除“${name}”？';
}

// Path: companionRemote
class Translations$companionRemote$zh extends Translations$companionRemote$en {
	Translations$companionRemote$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '遥控器';
	@override String connectedTo({required Object name}) => '已连接到 ${name}';
	@override String get unknownDevice => '未知设备';
	@override late final Translations$companionRemote$session$zh session = Translations$companionRemote$session$zh.internal(_root);
	@override late final Translations$companionRemote$pairing$zh pairing = Translations$companionRemote$pairing$zh.internal(_root);
	@override late final Translations$companionRemote$remote$zh remote = Translations$companionRemote$remote$zh.internal(_root);
	@override late final Translations$companionRemote$errors$zh errors = Translations$companionRemote$errors$zh.internal(_root);
	@override String get closedBeforeAuth => '连接在身份验证前已关闭';
}

// Path: videoSettings
class Translations$videoSettings$zh extends Translations$videoSettings$en {
	Translations$videoSettings$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => '播放速度';
	@override String get normalSpeed => '正常';
	@override String sleepTimerActive({required Object duration}) => '运行中（${duration}）';
	@override String get zoom => '缩放';
	@override String get sleepTimer => '睡眠定时器';
	@override String get audioSync => '音频同步';
	@override String get subtitleSync => '字幕同步';
	@override String get hdr => 'HDR';
	@override String get hdrUnsupported => '此处不支持 HDR——当前桌面合成器或视频输出无法传输 HDR。';
	@override String get hdrToneMapping => 'HDR 色调映射';
	@override String get hdrToneMappingCompositor => '合成器';
	@override String get hdrToneMappingCompositorDescription => '直接传递源的 HDR 元数据，并由桌面合成器进行映射。';
	@override String get hdrToneMappingPlayer => '播放器';
	@override String get hdrToneMappingPlayerDescription => '在播放器中映射到显示器的峰值亮度，然后将结果告知合成器。';
	@override String get hdrToneMappingFailed => '无法更改 HDR 色调映射——仍在使用之前的模式。';
	@override String get audioOutput => '音频输出';
	@override String get performanceOverlay => '性能监控';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => '环绕声';
	@override String get audioOutputSpatial => '空间音频';
	@override String get audioOutputStereo => '立体声';
	@override String get audioNormalization => '响度标准化';
	@override String get audioDownmix => '下混为立体声';
}

// Path: performanceOverlay
class Translations$performanceOverlay$zh extends Translations$performanceOverlay$en {
	Translations$performanceOverlay$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get color => '颜色';
	@override String get performance => '性能';
	@override String get buffer => '缓冲';
	@override String get app => '应用';
	@override String get decoder => '解码器';
	@override String get rawDecoder => '原始解码器';
	@override String get tunneling => '隧道';
	@override String get passthrough => '直通';
	@override String get aspect => '宽高比';
	@override String get rotation => '旋转';
	@override String get dvSource => 'DV 来源';
	@override String get dvPath => 'DV 路径';
	@override String get p7Conversion => 'P7 转换';
	@override String get sampleRate => '采样率';
	@override String get pixelFormat => '像素格式';
	@override String get hwFormat => '硬件格式';
	@override String get matrix => '矩阵';
	@override String get primaries => '基色';
	@override String get transfer => '传递特性';
	@override String get renderFps => '渲染 FPS';
	@override String get displayFps => '显示 FPS';
	@override String get avSync => 'A/V 同步';
	@override String get dropped => '丢帧';
	@override String get dvRpus => 'DV RPU';
	@override String get dvRpuAverage => 'DV RPU 平均';
	@override String get dvSampleAverage => 'DV 采样平均';
	@override String get maxLuma => '最大亮度';
	@override String get minLuma => '最小亮度';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => '已用缓存';
	@override String get cacheLimit => '缓存限制';
	@override String get speed => '速度';
	@override String get player => '播放器';
	@override String get memory => '内存';
	@override String get uiFps => 'UI FPS';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Android 硬件';
	@override String get decoderNvidiaHw => 'NVIDIA 硬件';
	@override String get decoderQualcommHw => 'Qualcomm 硬件';
	@override String get decoderMediatekHw => 'MediaTek 硬件';
	@override String get decoderExynosHw => 'Exynos 硬件';
	@override String get decoderSoftware => '软件';
	@override String get decoderHardware => '硬件';
	@override String get tunnelingActive => '已启用';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted}（${failures} 个失败）';
}

// Path: externalPlayer
class Translations$externalPlayer$zh extends Translations$externalPlayer$en {
	Translations$externalPlayer$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '外部播放器';
	@override String get useExternalPlayer => '使用外部播放器';
	@override String get useExternalPlayerDescription => '在其他应用中打开视频';
	@override String get selectPlayer => '选择播放器';
	@override String get customPlayers => '自定义播放器';
	@override String get systemDefault => '系统默认';
	@override String get addCustomPlayer => '添加自定义播放器';
	@override String get playerName => '播放器名称';
	@override String get playerNameHint => '我的播放器';
	@override String get playerCommand => '命令';
	@override String get playerPackage => '包名';
	@override String get playerUrlScheme => 'URL 方案';
	@override String get off => '关闭';
	@override String get launchFailed => '无法打开外部播放器';
	@override String appNotInstalled({required Object name}) => '${name} 未安装';
	@override String get playInExternalPlayer => '在外部播放器中播放';
}

// Path: metadataEdit
class Translations$metadataEdit$zh extends Translations$metadataEdit$en {
	Translations$metadataEdit$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => '编辑…';
	@override String get screenTitle => '编辑元数据';
	@override String get basicInfo => '基本信息';
	@override String get artwork => '封面图片';
	@override String get advancedSettings => '高级设置';
	@override String get title => '标题';
	@override String get sortTitle => '排序标题';
	@override String get originalTitle => '原始标题';
	@override String get releaseDate => '上映日期';
	@override String get contentRating => '内容分级';
	@override String get studio => '制片厂';
	@override String get tagline => '标语';
	@override String get summary => '简介';
	@override String get poster => '海报';
	@override String get background => '背景';
	@override String get logo => '标志';
	@override String get squareArt => '方形图片';
	@override String get selectPoster => '选择海报';
	@override String get selectBackground => '选择背景';
	@override String get selectLogo => '选择标志';
	@override String get selectSquareArt => '选择方形图片';
	@override String get fromUrl => '通过 URL';
	@override String get uploadFile => '上传文件';
	@override String get enterImageUrl => '输入图片 URL';
	@override String get imageUrl => '图片 URL';
	@override String get metadataUpdated => '元数据已更新';
	@override String get metadataUpdateFailed => '元数据更新失败';
	@override String get artworkUpdated => '封面图片已更新';
	@override String get artworkUpdateFailed => '封面图片更新失败';
	@override String get noArtworkAvailable => '没有可用的封面图片';
	@override String artworkOption({required Object index}) => '封面图片选项 ${index}';
	@override String selectedArtworkOption({required Object index}) => '封面图片选项 ${index}，已选择';
	@override String get notSet => '未设置';
	@override String get libraryDefault => '媒体库默认';
	@override String get accountDefault => '账户默认';
	@override String get seriesDefault => '剧集默认';
	@override String get episodeSorting => '剧集排序';
	@override String get oldestFirst => '最旧优先';
	@override String get newestFirst => '最新优先';
	@override String get keep => '保留';
	@override String get allEpisodes => '所有剧集';
	@override String latestEpisodes({required Object count}) => '最新 ${count} 集';
	@override String get latestEpisode => '最新一集';
	@override String episodesAddedPastDays({required Object count}) => '过去 ${count} 天内添加的剧集';
	@override String get deleteAfterPlaying => '播放后删除剧集';
	@override String get never => '从不';
	@override String get afterADay => '一天后';
	@override String get afterAWeek => '一周后';
	@override String get afterAMonth => '一个月后';
	@override String get onNextRefresh => '下次刷新时';
	@override String get seasons => '季';
	@override String get show => '显示';
	@override String get hide => '隐藏';
	@override String get episodeOrdering => '剧集排列顺序';
	@override String get tmdbAiring => 'The Movie Database（播出顺序）';
	@override String get tvdbAiring => 'TheTVDB（播出顺序）';
	@override String get tvdbAbsolute => 'TheTVDB（绝对顺序）';
	@override String get metadataLanguage => '元数据语言';
	@override String get useOriginalTitle => '使用原始标题';
	@override String get preferredAudioLanguage => '首选音频语言';
	@override String get preferredSubtitleLanguage => '首选字幕语言';
	@override String get subtitleMode => '自动选择字幕模式';
	@override String get manuallySelected => '手动选择';
	@override String get shownWithForeignAudio => '外语音频时显示';
	@override String get alwaysEnabled => '始终启用';
	@override String get tags => '标签';
	@override String get addTag => '添加标签';
	@override String get genre => '类型';
	@override String get director => '导演';
	@override String get writer => '编剧';
	@override String get producer => '制片人';
	@override String get country => '国家';
	@override String get collection => '合集';
	@override String get label => '标记';
}

// Path: matchScreen
class Translations$matchScreen$zh extends Translations$matchScreen$en {
	Translations$matchScreen$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get match => '匹配…';
	@override String get fixMatch => '修正匹配…';
	@override String get unmatch => '取消匹配';
	@override String get unmatchConfirm => '清除此匹配？在重新匹配前，Plex 会将其视为未匹配。';
	@override String get unmatchSuccess => '已取消匹配';
	@override String get unmatchFailed => '无法取消匹配';
	@override String get matchApplied => '匹配已应用';
	@override String get matchFailed => '应用匹配失败';
	@override String get titleHint => '标题';
	@override String get yearHint => '年份';
	@override String get search => '搜索';
	@override String get noMatchesFound => '未找到匹配项';
}

// Path: serverTasks
class Translations$serverTasks$zh extends Translations$serverTasks$en {
	Translations$serverTasks$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '服务器任务';
	@override String get failedToLoad => '加载任务失败';
	@override String get noTasks => '没有正在运行的任务';
}

// Path: trakt
class Translations$trakt$zh extends Translations$trakt$en {
	Translations$trakt$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => '已连接';
	@override String connectedAs({required Object username}) => '已以 @${username} 身份连接';
	@override String get disconnectConfirm => '断开 Trakt 账户？';
	@override String get disconnectConfirmBody => 'Plezy 将停止向 Trakt 发送事件。你可随时重新连接。';
	@override String get scrobble => '实时同步播放状态';
	@override String get scrobbleDescription => '播放期间将播放、暂停和停止事件发送到 Trakt。';
	@override String get watchedSync => '同步已观看状态';
	@override String get watchedSyncDescription => '在 Plezy 中将内容标记为已观看时，也会在 Trakt 上标记为已观看。';
}

// Path: seerr
class Translations$seerr$zh extends Translations$seerr$en {
	Translations$seerr$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => '连接 Seerr';
	@override String get serverUrl => '服务器 URL';
	@override String get serverUrlHelper => '你的 Seerr 实例的地址';
	@override String get checkServer => '继续';
	@override String get signInWithJellyfin => '使用 Jellyfin 登录';
	@override String get signInWithEmby => '使用 Emby 登录';
	@override String get signInWithLocal => '使用本地账户';
	@override String get email => '邮箱';
	@override String get noSignInMethods => '此 Seerr 实例未提供 Plezy 支持的登录方式。';
	@override String get instance => '实例';
	@override String get disconnectConfirm => '断开 Seerr 连接？';
	@override String get disconnectConfirmBody => 'Plezy 将忘记此 Seerr 实例。可随时重新连接。';
	@override String get request => '请求';
	@override String get request4k => '请求 4K';
	@override String get seasons => '季';
	@override String get allSeasons => '全部季';
	@override String get advancedOptions => '高级';
	@override String get destinationServer => '目标服务器';
	@override String get qualityProfile => '画质配置';
	@override String get rootFolder => '根目录';
	@override String get languageProfile => '语言配置';
	@override String get requestSubmitted => '请求已提交';
	@override String requestFailed({required Object error}) => '请求失败：${error}';
	@override String get requestsLoadFailed => '无法加载请求选项';
	@override String get nothingToRequest => '所有内容都已可用或已请求。';
	@override String get statusAvailable => '可用';
	@override String get statusPartiallyAvailable => '部分可用';
	@override String get statusRequested => '已请求';
	@override String get statusProcessing => '处理中';
	@override String get statusBlocklisted => '已加入屏蔽列表';
	@override String couldNotReach({required Object url, required Object error}) => '无法连接到 ${url}：${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => '${url} 上没有 Seerr 实例（HTTP ${status}）';
	@override String get notInitialized => '此 Seerr 实例尚未完成首次运行设置';
	@override String get noPlexTokenForReauth => '没有可用于重新登录的 Plex 令牌';
	@override String get noStoredCredentials => '没有已保存的凭据可用于重新登录';
	@override String get signInRejected => '登录被拒绝';
	@override String get noSessionCookie => 'Seerr 未签发会话 Cookie';
	@override String get freshCookieRejected => 'Seerr 拒绝了新的会话 Cookie';
	@override String get noUserInformation => 'Seerr 未返回用户信息';
	@override String get sessionRejectedAfterReauth => '重新登录后会话被拒绝';
}

// Path: services
class Translations$services$zh extends Translations$services$en {
	Translations$services$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '服务';
	@override String get hubSubtitle => '同步观看进度并请求新内容。';
	@override String get notConnected => '未连接';
	@override String connectedAs({required Object username}) => '已以 @${username} 身份连接';
	@override String get scrobble => '自动记录进度';
	@override String get scrobbleDescription => '观看完一集或一部电影后更新你的列表。';
	@override String disconnectConfirm({required Object service}) => '断开 ${service} 连接？';
	@override String disconnectConfirmBody({required Object service}) => 'Plezy 将停止更新 ${service}。可随时重新连接。';
	@override String connectFailed({required Object service}) => '无法连接到 ${service}。请重试。';
	@override late final Translations$services$names$zh names = Translations$services$names$zh.internal(_root);
	@override late final Translations$services$deviceCode$zh deviceCode = Translations$services$deviceCode$zh.internal(_root);
	@override late final Translations$services$oauthProxy$zh oauthProxy = Translations$services$oauthProxy$zh.internal(_root);
	@override late final Translations$services$pendingAuth$zh pendingAuth = Translations$services$pendingAuth$zh.internal(_root);
	@override late final Translations$services$libraryFilter$zh libraryFilter = Translations$services$libraryFilter$zh.internal(_root);
}

// Path: addServer
class Translations$addServer$zh extends Translations$addServer$en {
	Translations$addServer$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => '添加 ${product} 服务器';
	@override String get serverUrls => '服务器 URL';
	@override String get serverUrlsHelper => '可输入多个 URL，并用逗号分隔。';
	@override String get findServer => '查找服务器';
	@override String searchingLocalMediaBrowserServers({required Object product}) => '正在查找本地 ${product} 服务器…';
	@override String localMediaBrowserServers({required Object product}) => '本地 ${product} 服务器';
	@override String get username => '用户名';
	@override String get password => '密码';
	@override String get signIn => '登录';
	@override String get change => '更改';
	@override String get required => '必填';
	@override String couldNotReachServer({required Object error}) => '无法连接到服务器：${error}';
	@override String signInFailed({required Object error}) => '登录失败：${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect 失败：${error}';
	@override String get addPlexTitle => '使用 Plex 登录';
	@override String get pinExpired => 'PIN 在登录前已过期。请重试。';
	@override String failedToRegisterAccount({required Object error}) => '注册账户失败：${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => '请输入你的 ${product} 服务器 URL';
	@override String get addConnectionTitle => '添加连接';
	@override String addConnectionTitleScoped({required Object name}) => '添加到 ${name}';
	@override String get signInWithPlexCard => '使用 Plex 登录';
	@override String get signInWithPlexCardSubtitle => '授权此设备。共享服务器会被添加。';
	@override String get signInWithPlexCardSubtitleScoped => '授权一个 Plex 账户。Plex Home 用户将成为 Plezy 用户资料。';
	@override String connectToMediaBrowserCard({required Object product}) => '连接到 ${product}';
	@override String get connectToMediaBrowserCardSubtitle => '输入你的服务器 URL、用户名和密码。';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => '登录你的 ${product} 服务器。将绑定到 ${name}。';
	@override String get borrowFromAnotherProfile => '使用其他用户资料的连接';
	@override String get borrowFromAnotherProfileSubtitle => '复用另一个用户资料的连接。受 PIN 保护的用户资料需要输入 PIN。';
	@override String get invalidCredentials => '用户名或密码无效';
	@override String get authResponseNotJson => '身份验证响应不是有效的 JSON';
	@override String get authResponseIncomplete => '服务器返回的登录响应不完整';
	@override String get quickConnectRejected => '服务器拒绝了 Quick Connect';
	@override String get quickConnectNotJson => 'Quick Connect 响应不是有效的 JSON';
	@override String get quickConnectMissingFields => 'Quick Connect 响应中缺少代码或密钥';
	@override String get quickConnectPollRejected => '服务器拒绝了 Quick Connect 轮询';
	@override String get serverTimedOut => '服务器未及时响应';
	@override String get responseNotJson => '服务器响应不是有效的 JSON';
	@override String responseMissingIdentity({required Object product}) => '响应中缺少 ID 或服务器名称——这是 ${product} 服务器吗？';
	@override String probeFailed({required Object error}) => '无法连接到服务器：${error}';
	@override String enterAtLeastOneUrl({required Object product}) => '请输入至少一个 ${product} 服务器 URL';
	@override String noReachableServer({required Object product}) => '未找到可连接的 ${product} 服务器';
	@override String urlsPointToDifferentServers({required Object product}) => '这些 URL 指向不同的 ${product} 服务器';
	@override String urlDoesNotMatchServer({required Object product}) => '此 URL 与 ${product} 服务器不匹配';
	@override String get redirectUnsupported => '服务器重定向到了不受支持的 URL';
	@override String redirectDifferentHost({required Object product}) => '服务器重定向到了其他主机。请直接输入最终的 ${product} URL。';
	@override String get redirectInsecure => '服务器从 HTTPS 重定向到了不安全的 URL';
	@override String redirectUnsupportedEnterFinal({required Object product}) => '服务器重定向到了不受支持的 URL。请直接输入最终的 ${product} URL。';
}

// Path: common.ratingSource
class Translations$common$ratingSource$zh extends Translations$common$ratingSource$en {
	Translations$common$ratingSource$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get critic => '影评人';
	@override String get audience => '观众';
	@override String get imdb => 'IMDb';
	@override String get tmdb => 'TMDB';
	@override String get rottenTomatoes => 'Rotten Tomatoes';
	@override String get simkl => 'Simkl';
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get trakt => 'Trakt';
	@override String get rottenTomatoesCritic => 'Rotten Tomatoes 影评人';
	@override String get rottenTomatoesAudience => 'Rotten Tomatoes 观众';
}

// Path: common.mediaKind
class Translations$common$mediaKind$zh extends Translations$common$mediaKind$en {
	Translations$common$mediaKind$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get movie => '电影';
	@override String get show => '剧集';
	@override String get season => '季';
	@override String get episode => '单集';
	@override String get artist => '艺术家';
	@override String get album => '专辑';
	@override String get track => '曲目';
	@override String get collection => '合集';
	@override String get playlist => '播放列表';
	@override String get clip => '短片';
	@override String get photo => '照片';
	@override String get folder => '文件夹';
}

// Path: hotkeys.actions
class Translations$hotkeys$actions$zh extends Translations$hotkeys$actions$en {
	Translations$hotkeys$actions$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get playPause => '播放/暂停';
	@override String get volumeUp => '增大音量';
	@override String get volumeDown => '减小音量';
	@override String seekForward({required Object seconds}) => '快进 (${seconds}秒)';
	@override String seekBackward({required Object seconds}) => '快退 (${seconds}秒)';
	@override String get fullscreenToggle => '切换全屏';
	@override String get muteToggle => '切换静音';
	@override String get subtitleToggle => '切换字幕';
	@override String get audioTrackNext => '下一音轨';
	@override String get subtitleTrackNext => '下一字幕轨';
	@override String get chapterNext => '下一章节';
	@override String get chapterPrevious => '上一章节';
	@override String get episodeNext => '下一集';
	@override String get episodePrevious => '上一集';
	@override String get speedIncrease => '加速';
	@override String get speedDecrease => '减速';
	@override String get speedReset => '重置速度';
	@override String get zoomIn => '放大';
	@override String get zoomOut => '缩小';
	@override String get zoomReset => '重置缩放';
	@override String get subSeekNext => '跳转到下一条字幕';
	@override String get subSeekPrev => '跳转到上一条字幕';
	@override String get shaderToggle => '切换着色器';
	@override String get skipMarker => '跳过片头/片尾';
	@override String get screenshot => '截图';
}

// Path: videoControls.pipErrors
class Translations$videoControls$pipErrors$zh extends Translations$videoControls$pipErrors$en {
	Translations$videoControls$pipErrors$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => '需要 Android 8.0 或更高版本';
	@override String get iosVersion => '需要 iOS 15.0 或更高版本';
	@override String get permissionDisabled => '画中画已禁用。请在系统设置中启用。';
	@override String get notSupported => '此设备不支持画中画模式';
	@override String get voSwitchFailed => '无法切换画中画的视频输出';
	@override String get failed => '画中画启动失败';
	@override String get prepareFailed => '无法准备画中画';
	@override String unknown({required Object error}) => '发生错误：${error}';
}

// Path: libraries.tabs
class Translations$libraries$tabs$zh extends Translations$libraries$tabs$en {
	Translations$libraries$tabs$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get recommended => '推荐';
	@override String get browse => '浏览';
	@override String get collections => '合集';
	@override String get playlists => '播放列表';
}

// Path: libraries.groupings
class Translations$libraries$groupings$zh extends Translations$libraries$groupings$en {
	Translations$libraries$groupings$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '分组';
	@override String get all => '全部';
	@override String get movies => '电影';
	@override String get shows => '剧集';
	@override String get seasons => '季';
	@override String get episodes => '集';
	@override String get artists => '艺术家';
	@override String get albums => '专辑';
	@override String get tracks => '曲目';
	@override String get folders => '文件夹';
}

// Path: libraries.filterCategories
class Translations$libraries$filterCategories$zh extends Translations$libraries$filterCategories$en {
	Translations$libraries$filterCategories$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get genre => '类型';
	@override String get year => '年份';
	@override String get contentRating => '内容分级';
	@override String get tag => '标签';
	@override String get unwatched => '未观看';
	@override String get unplayed => '未播放';
	@override String get favorites => '收藏夹';
}

// Path: libraries.sortLabels
class Translations$libraries$sortLabels$zh extends Translations$libraries$sortLabels$en {
	Translations$libraries$sortLabels$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '标题';
	@override String get dateAdded => '添加日期';
	@override String get releaseDate => '发行日期';
	@override String get rating => '评分';
	@override String get communityRating => '社区评分';
	@override String get criticRating => '影评人评分';
	@override String get userRating => '用户评分';
	@override String get datePlayed => '播放日期';
	@override String get playCount => '播放次数';
	@override String get productionYear => '制作年份';
	@override String get runtime => '时长';
	@override String get officialRating => '官方分级';
	@override String get premiereDate => '首映日期';
	@override String get startDate => '开始日期';
	@override String get airTime => '播出时间';
	@override String get studio => '制片公司';
	@override String get random => '随机';
	@override String get dateShared => '共享日期';
	@override String get latestEpisodeAirDate => '最新一集播出日期';
	@override String get lastEpisodeDateAdded => '最新一集添加日期';
}

// Path: explore.rows
class Translations$explore$rows$zh extends Translations$explore$rows$en {
	Translations$explore$rows$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get watchlist => '想看列表';
	@override String get recommendedMovies => '推荐电影';
	@override String get recommendedShows => '推荐剧集';
	@override String get trendingMovies => '近期热门电影';
	@override String get trendingShows => '近期热门剧集';
	@override String get popularMovies => '人气电影';
	@override String get popularShows => '人气剧集';
	@override String get trendingAnime => '热门动画';
	@override String get suggestedAnime => '推荐动画';
	@override String get airingAnime => '热门连载动画';
	@override String get popularAnime => '最受欢迎动画';
	@override String get trending => '近期热门';
	@override String get upcomingMovies => '即将上映的电影';
	@override String get upcomingShows => '即将播出的剧集';
}

// Path: explore.status
class Translations$explore$status$zh extends Translations$explore$status$en {
	Translations$explore$status$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get airing => '连载中';
	@override String get ended => '已完结';
	@override String get canceled => '已取消';
	@override String get upcoming => '即将上线';
}

// Path: explore.badge
class Translations$explore$badge$zh extends Translations$explore$badge$en {
	Translations$explore$badge$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '热门榜第 #${n} 名';
	@override String rankAiring({required Object n}) => '在播榜第 #${n} 名';
	@override String rankRated({required Object n}) => '评分榜第 #${n} 名';
	@override String rankTrending({required Object n}) => '趋势榜第 #${n} 名';
	@override String rankSeasonal({required Object season, required Object n}) => '${season}榜第 #${n} 名';
	@override String watchingNow({required Object n}) => '${n} 人正在观看';
	@override String get available => '可观看';
	@override String get partiallyAvailable => '部分可观看';
	@override String get availableIn4k => '提供 4K';
	@override String get requested => '已请求';
	@override String get pendingApproval => '待批准';
	@override String get processing => '处理中';
	@override String get declined => '已拒绝';
	@override String get requestFailed => '请求失败';
	@override String get requested4k => '已请求 4K';
	@override String seasonsAvailable({required Object available, required Object total}) => '已有 ${available}/${total} 季';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => '第 ${episode} 集将在 ${duration} 后播出';
	@override String nextAiringIn({required Object duration}) => '下一集将在 ${duration} 后播出';
	@override String episodesShort({required Object n}) => '${n} 集';
	@override String minutesPerEpisode({required Object n}) => '${n} 分钟/集';
	@override String get adult => '18+';
}

// Path: explore.stats
class Translations$explore$stats$zh extends Translations$explore$stats$en {
	Translations$explore$stats$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} 人已标记';
	@override String viewersDay({required Object n}) => '今日 ${n} 人观看';
	@override String viewersWeek({required Object n}) => '本周 ${n} 人观看';
	@override String viewersMonth({required Object n}) => '本月 ${n} 人观看';
	@override String viewersYear({required Object n}) => '今年 ${n} 人观看';
	@override String viewersAllTime({required Object n}) => '累计 ${n} 人观看';
	@override String planning({required Object n}) => '${n} 人想看';
	@override String favorited({required Object n}) => '${n} 人收藏';
	@override String dropRate({required Object percent}) => '${percent} 弃番';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		other: '${n} 条评论',
	);
	@override String votes({required Object n}) => '${n} 票';
	@override String watching({required Object n}) => '${n} 人正在观看';
	@override String completed({required Object n}) => '${n} 人已看完';
	@override String onHold({required Object n}) => '${n} 人搁置';
	@override String dropped({required Object n}) => '${n} 人弃番';
}

// Path: explore.season
class Translations$explore$season$zh extends Translations$explore$season$en {
	Translations$explore$season$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get winter => '冬季';
	@override String get spring => '春季';
	@override String get summer => '夏季';
	@override String get fall => '秋季';
	@override String withYear({required Object year, required Object season}) => '${year}年${season}';
}

// Path: explore.format
class Translations$explore$format$zh extends Translations$explore$format$en {
	Translations$explore$format$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get tv => 'TV';
	@override String get tvShort => 'TV 短片';
	@override String get movie => '电影';
	@override String get special => '特别篇';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => '音乐';
	@override String get other => '其他';
}

// Path: explore.sourceMaterial
class Translations$explore$sourceMaterial$zh extends Translations$explore$sourceMaterial$en {
	Translations$explore$sourceMaterial$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get original => '原创';
	@override String get manga => '漫画';
	@override String get lightNovel => '轻小说';
	@override String get novel => '小说';
	@override String get visualNovel => '视觉小说';
	@override String get game => '游戏';
	@override String get webComic => '网络漫画';
	@override String get musicRelease => '音乐';
	@override String get otherMedia => '其他';
}

// Path: explore.creditRole
class Translations$explore$creditRole$zh extends Translations$explore$creditRole$en {
	Translations$explore$creditRole$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get director => '导演';
	@override String get writer => '编剧';
	@override String get producer => '制片人';
	@override String get creator => '创作者';
	@override String get composer => '作曲';
}

// Path: explore.relation
class Translations$explore$relation$zh extends Translations$explore$relation$en {
	Translations$explore$relation$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get prequel => '前传';
	@override String get sequel => '续集';
	@override String get sideStory => '番外篇';
	@override String get spinOff => '衍生作品';
	@override String get alternativeVersion => '另一版本';
	@override String get summary => '总集篇';
	@override String get parentStory => '原作';
	@override String get adaptation => '改编';
	@override String get other => '相关';
}

// Path: explore.detail
class Translations$explore$detail$zh extends Translations$explore$detail$en {
	Translations$explore$detail$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => '原名';
	@override String get alsoKnownAs => '又名';
	@override String get studios => '制作公司';
	@override String get country => '国家/地区';
	@override String get language => '语言';
	@override String get released => '上映日期';
	@override String get physicalRelease => '光盘发售';
	@override String get ended => '完结日期';
	@override String addedOn({required Object date}) => '添加于 ${date}';
	@override String get yourRating => '你的评分';
	@override String get budget => '预算';
	@override String get revenue => '票房';
	@override String get contentAdvisory => '年龄分级';
	@override String get tags => '标签';
	@override String get revealSpoilerTags => '显示剧透标签';
	@override String get links => '链接';
	@override String get watchOn => '观看平台';
	@override String get watchTrailer => '观看预告片';
	@override String openOn({required Object site}) => '在 ${site} 打开';
	@override String get crew => '演职人员';
	@override String get ratings => '评分';
	@override String get schedule => '播出时间';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		other: '由 ${n} 位用户推荐',
	);
	@override String recommendedBy({required Object who}) => '由 ${who} 推荐';
	@override String favoritedBy({required Object who}) => '由 ${who} 收藏';
	@override String unairedEpisodes({required Object n}) => '还有 ${n} 集未播出';
	@override String recommendedByPercent({required Object percent}) => '${percent} 的观众推荐';
	@override String get relatedTitles => '相关作品';
	@override String get background => '背景';
}

// Path: liveTv.recordSettings
class Translations$liveTv$recordSettings$zh extends Translations$liveTv$recordSettings$en {
	Translations$liveTv$recordSettings$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get startEarly => '提前开始（秒）';
	@override String get endLate => '延后结束（秒）';
	@override String get newOnly => '仅新剧集';
	@override String get anyChannel => '在任意频道录制';
	@override String get anyTime => '在任意时间录制';
	@override String get skipInLibrary => '跳过媒体库中已有的剧集';
	@override String get keepUpTo => '保留的剧集数';
	@override String get keepUpToHint => '0 表示保留全部剧集';
}

// Path: music.discography
class Translations$music$discography$zh extends Translations$music$discography$en {
	Translations$music$discography$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => '单曲和 EP';
	@override String get live => '现场';
	@override String get compilations => '合集';
}

// Path: watchTogether.errors
class Translations$watchTogether$errors$zh extends Translations$watchTogether$errors$en {
	Translations$watchTogether$errors$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get timedOut => '中继服务器未及时响应';
	@override String get connectionLost => '会话准备就绪前连接已断开';
	@override String get invalidRelayResponse => '中继服务器返回了意外的响应';
	@override String get sessionEnded => '主持人已结束会话';
}

// Path: downloads.backgroundWarning
class Translations$downloads$backgroundWarning$zh extends Translations$downloads$backgroundWarning$en {
	Translations$downloads$backgroundWarning$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => '离开应用后，下载将停止';
	@override String get bannerDegraded => '后台下载可能受限';
	@override String get bannerAction => '详情';
	@override String get sheetTitle => '后台下载已被阻止';
	@override String get sheetTitleDegraded => '后台下载可能受限';
	@override String get sheetIntro => 'Android 正在阻止 Plezy 在后台稳定下载。';
	@override String get sheetIntroDegraded => '你的设备限制了 Plezy 在后台下载的时机。';
	@override String get reasonBackgroundRestricted => 'Plezy 的后台使用受到限制。请将其电池用量或后台使用设置为“不受限制”。';
	@override String get reasonStandbyRestricted => 'Android 已将 Plezy 置于受限待机状态。请将其电池用量设为“不受限制”。';
	@override String get reasonDownloadChannelBlocked => '下载通知已关闭，因此可能无法查看进度或进行控制。';
	@override String get reasonNotificationsDisabled => '通知已关闭。在 Android 13 或更高版本中，长时间后台下载需要开启通知。';
	@override String get reasonDataSaver => '流量节省程序已开启，会阻止使用移动数据进行后台下载。使用 Wi-Fi 时下载应仍可进行。';
	@override String get reasonOemUnknown => 'Plezy 在后台时，下载曾多次停止。请检查 Plezy 的电池用量或后台使用设置。';
	@override String get openSettings => '打开设置';
	@override String get stillNotWorking => '设备专属帮助';
	@override String get stillNotWorkingDescription => '查看适用于你设备的操作步骤；如果问题仍然存在，请通过设置 › 查看日志发送日志。';
	@override String get dialogTitle => '下载可能无法完成';
	@override String get dialogDownloadAnyway => '仍要下载';
	@override String get dialogFixFirst => '先解决此问题';
	@override String get statusTile => '后台下载';
	@override String get statusOk => '允许在后台运行';
	@override String get statusBlocked => '已被系统设置阻止';
	@override String get statusDegraded => '受系统设置限制';
	@override String get statusUnknown => '尚未检查';
	@override String get settingsUnavailable => '无法在此设备上打开系统设置';
	@override String get linkUnavailable => '无法在此设备上打开 dontkillmyapp.com';
}

// Path: companionRemote.session
class Translations$companionRemote$session$zh extends Translations$companionRemote$session$en {
	Translations$companionRemote$session$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get startingServer => '正在启动远程服务器…';
	@override String get hostAddress => '主机地址';
	@override String get connected => '已连接';
	@override String get serverRunning => '远程服务器已启动';
	@override String get serverStopped => '远程服务器已停止';
	@override String get serverRunningDescription => '网络上的移动设备可以连接到此应用';
	@override String get serverStoppedDescription => '启动服务器以允许移动设备连接';
	@override String get usePhoneToControl => '使用移动设备控制此应用';
	@override String get startServer => '启动服务器';
	@override String get stopServer => '停止服务器';
	@override String get minimize => '最小化';
	@override String get manualAddressHint => '手动连接地址：';
}

// Path: companionRemote.pairing
class Translations$companionRemote$pairing$zh extends Translations$companionRemote$pairing$en {
	Translations$companionRemote$pairing$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => '使用同一 Plex 账号的 Plezy 设备会显示在这里';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => '正在连接…';
	@override String get searchingForDevices => '正在搜索设备…';
	@override String get noDevicesFound => '未在网络中找到设备';
	@override String get noDevicesHint => '请在桌面端打开 Plezy，并确保设备连接到同一 Wi-Fi 网络';
	@override String get availableDevices => '可用设备';
	@override String get manualConnection => '手动连接';
	@override String get cryptoInitFailed => '无法启动安全连接。请先登录 Plex。';
	@override String get validationHostRequired => '请输入主机地址';
	@override String get validationHostFormat => '格式必须为 IP:端口（例如 192.168.1.100:48632）';
	@override String get connectionTimedOut => '连接超时。请在两台设备上使用同一网络。';
	@override String get sessionNotFound => '未找到设备。请确认 Plezy 正在主机上运行。';
	@override String get authFailed => '认证失败。两台设备需要使用同一 Plex 账号。';
	@override String failedToConnect({required Object error}) => '连接失败：${error}';
}

// Path: companionRemote.remote
class Translations$companionRemote$remote$zh extends Translations$companionRemote$remote$en {
	Translations$companionRemote$remote$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => '确定要断开遥控会话吗？';
	@override String get reconnecting => '正在重新连接…';
	@override String attemptOf({required Object current}) => '第 ${current} 次尝试，共 5 次';
	@override String get retryNow => '立即重试';
	@override String get tabRemote => '遥控器';
	@override String get tabPlay => '播放';
	@override String get tabMore => '更多';
	@override String get menu => '菜单';
	@override String get tabNavigation => '导航';
	@override String get tabDiscover => '发现';
	@override String get tabLibraries => '媒体库';
	@override String get tabSearch => '搜索';
	@override String get tabDownloads => '下载';
	@override String get tabSettings => '设置';
	@override String get previous => '上一个';
	@override String get playPause => '播放/暂停';
	@override String get next => '下一个';
	@override String get seekBack => '快退';
	@override String get stop => '停止';
	@override String get seekForward => '快进';
	@override String get volume => '音量';
	@override String get volumeDown => '降低音量';
	@override String get volumeUp => '提高音量';
	@override String get fullscreen => '全屏';
	@override String get subtitles => '字幕';
	@override String get audio => '音频';
	@override String get searchHint => '在桌面端搜索…';
}

// Path: companionRemote.errors
class Translations$companionRemote$errors$zh extends Translations$companionRemote$errors$en {
	Translations$companionRemote$errors$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => '未找到网络接口';
	@override String get authenticationFailed => '身份验证失败';
	@override String serverStartFailed({required Object error}) => '无法启动远程服务器：${error}';
	@override String commandFailed({required Object error}) => '无法发送远程命令：${error}';
	@override String get joinTimedOut => '加入会话超时';
	@override String get failedToConnectAnyAddress => '无法连接到任何地址';
	@override String connectionLostAfterAttempts({required Object attempts}) => '${attempts} 次尝试后连接丢失';
	@override String get connectionLost => '连接丢失';
}

// Path: services.names
class Translations$services$names$zh extends Translations$services$names$en {
	Translations$services$names$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.deviceCode
class Translations$services$deviceCode$zh extends Translations$services$deviceCode$en {
	Translations$services$deviceCode$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '在 ${service} 上激活 Plezy';
	@override String get instructions => '扫描二维码，或访问下方地址并输入此代码：';
	@override String openToActivate({required Object service}) => '打开 ${service} 以激活';
	@override String get copyCode => '复制激活代码';
	@override String get waitingForAuthorization => '等待授权…';
	@override String get codeCopied => '代码已复制';
}

// Path: services.oauthProxy
class Translations$services$oauthProxy$zh extends Translations$services$oauthProxy$en {
	Translations$services$oauthProxy$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '登录 ${service}';
	@override String get body => '扫描此二维码，或在任意设备上打开 URL。';
	@override String openToSignIn({required Object service}) => '打开 ${service} 以登录';
}

// Path: services.pendingAuth
class Translations$services$pendingAuth$zh extends Translations$services$pendingAuth$en {
	Translations$services$pendingAuth$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => '复制登录 URL';
	@override String get urlCopied => 'URL 已复制';
}

// Path: services.libraryFilter
class Translations$services$libraryFilter$zh extends Translations$services$libraryFilter$en {
	Translations$services$libraryFilter$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '媒体库筛选';
	@override String get subtitleAllSyncing => '同步所有媒体库';
	@override String get subtitleNoneSyncing => '不同步任何内容';
	@override String subtitleBlocked({required Object count}) => '已屏蔽 ${count} 个';
	@override String subtitleAllowed({required Object count}) => '已允许 ${count} 个';
	@override String get mode => '筛选模式';
	@override String get modeBlacklist => '黑名单';
	@override String get modeWhitelist => '白名单';
	@override String get modeHintBlacklist => '同步下方未勾选的所有媒体库。';
	@override String get modeHintWhitelist => '仅同步下方勾选的媒体库。';
	@override String get libraries => '媒体库';
	@override String get noLibraries => '没有可用的媒体库';
}

/// The flat map containing all translations for locale <zh>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsZh {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Plezy',
			'auth.signInWithPlex' => '使用 Plex 登录',
			'auth.showQRCode' => '显示二维码',
			'auth.authenticate' => '验证',
			'auth.authenticationTimeout' => '验证超时。请重试。',
			'auth.scanQRToSignIn' => '扫描二维码登录',
			'auth.waitingForAuth' => '正在等待身份验证…\n请在浏览器中登录。',
			'auth.useBrowser' => '使用浏览器',
			'auth.or' => '或',
			'auth.connectToMediaBrowser' => ({required Object product}) => '连接到 ${product}',
			'auth.useQuickConnect' => '使用 Quick Connect',
			'auth.quickConnectInstructions' => '在 Jellyfin 中打开 Quick Connect 并输入此代码。',
			'auth.quickConnectWaiting' => '等待批准…',
			'auth.quickConnectCancel' => '取消',
			'auth.quickConnectExpired' => 'Quick Connect 已过期。请重试。',
			'auth.localDataRecoveryRequired' => 'Plezy 无法安全恢复本地登录状态和待处理的播放数据。请重新登录。',
			'auth.pinCheckRejected' => 'Plex PIN 检查被拒绝',
			'common.cancel' => '取消',
			'common.save' => '保存',
			'common.close' => '关闭',
			'common.clear' => '清除',
			'common.reset' => '重置',
			'common.later' => '稍后',
			'common.submit' => '提交',
			'common.confirm' => '确认',
			'common.retry' => '重试',
			'common.logout' => '退出登录',
			'common.unknown' => '未知',
			'common.refresh' => '刷新',
			'common.yes' => '是',
			'common.no' => '否',
			'common.delete' => '删除',
			'common.edit' => '编辑',
			'common.shuffle' => '随机播放',
			'common.addTo' => '添加到…',
			'common.createNew' => '新建',
			'common.connect' => '连接',
			'common.disconnect' => '断开连接',
			'common.play' => '播放',
			'common.pause' => '暂停',
			'common.resume' => '继续',
			'common.error' => '错误',
			'common.search' => '搜索',
			'common.home' => '首页',
			'common.back' => '返回',
			'common.settings' => '设置',
			'common.mute' => '静音',
			'common.ok' => '确定',
			'common.off' => '关闭',
			'common.seasonNumber' => ({required Object number}) => '第${number}季',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => '第${number}集 — ${title}',
			'common.chapterNumber' => ({required Object number}) => '第${number}章',
			'common.reconnect' => '重新连接',
			'common.viewAll' => '查看全部',
			'common.checkingNetwork' => '正在检查网络…',
			'common.loadingServers' => '正在加载服务器…',
			'common.connectingToServers' => '正在连接服务器…',
			'common.startingOfflineMode' => '正在启动离线模式…',
			'common.loading' => '加载中…',
			'common.fullscreen' => '全屏',
			'common.exitFullscreen' => '退出全屏',
			'common.pressBackAgainToExit' => '再按一次返回键退出',
			'common.ratingSource.critic' => '影评人',
			'common.ratingSource.audience' => '观众',
			'common.ratingSource.imdb' => 'IMDb',
			'common.ratingSource.tmdb' => 'TMDB',
			'common.ratingSource.rottenTomatoes' => 'Rotten Tomatoes',
			'common.ratingSource.simkl' => 'Simkl',
			'common.ratingSource.mal' => 'MyAnimeList',
			'common.ratingSource.anilist' => 'AniList',
			'common.ratingSource.trakt' => 'Trakt',
			'common.ratingSource.rottenTomatoesCritic' => 'Rotten Tomatoes 影评人',
			'common.ratingSource.rottenTomatoesAudience' => 'Rotten Tomatoes 观众',
			'common.notAvailable' => 'N/A',
			'common.url' => 'URL',
			'common.letterKeys' => 'ABC',
			'common.mediaKind.movie' => '电影',
			'common.mediaKind.show' => '剧集',
			'common.mediaKind.season' => '季',
			'common.mediaKind.episode' => '单集',
			'common.mediaKind.artist' => '艺术家',
			'common.mediaKind.album' => '专辑',
			'common.mediaKind.track' => '曲目',
			'common.mediaKind.collection' => '合集',
			'common.mediaKind.playlist' => '播放列表',
			'common.mediaKind.clip' => '短片',
			'common.mediaKind.photo' => '照片',
			'common.mediaKind.folder' => '文件夹',
			'screens.licenses' => '许可证',
			'screens.switchProfile' => '切换用户',
			'screens.subtitleStyling' => '字幕样式',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => '日志',
			'update.available' => '有可用更新',
			'update.versionAvailable' => ({required Object version}) => '版本 ${version} 已发布',
			'update.currentVersion' => ({required Object version}) => '当前版本：${version}',
			'update.skipVersion' => '跳过此版本',
			'update.viewRelease' => '查看发布详情',
			'update.latestVersion' => '当前已是最新版本',
			'update.checkFailed' => '无法检查更新',
			'settings.title' => '设置',
			'settings.supportDeveloper' => '支持 Plezy',
			'settings.supportDeveloperDescription' => '通过 Liberapay 捐赠支持开发',
			'settings.language' => '语言',
			'settings.theme' => '主题',
			'settings.appearance' => '外观',
			'settings.videoPlayback' => '视频播放',
			'settings.videoPlaybackDescription' => '配置播放行为',
			'settings.advanced' => '高级',
			'settings.episodePosterMode' => '剧集海报样式',
			'settings.seriesPoster' => '剧集海报',
			'settings.seasonPoster' => '季海报',
			'settings.episodeThumbnail' => '缩略图',
			'settings.showHeroSectionDescription' => '在主屏幕上显示精选内容轮播区',
			'settings.secondsLabel' => '秒',
			'settings.minutesLabel' => '分钟',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => '输入时长（${min}–${max}）',
			'settings.systemTheme' => '系统',
			'settings.lightTheme' => '浅色',
			'settings.darkTheme' => '深色',
			'settings.oledTheme' => 'OLED',
			'settings.libraryDensity' => '媒体库密度',
			'settings.displayScale' => '界面缩放',
			'settings.compact' => '紧凑',
			'settings.comfortable' => '舒适',
			'settings.tvCornerSpotlightBackdrop' => '右上角聚焦背景图',
			'settings.tvCornerSpotlightBackdropDescription' => '在右上角显示精选内容图片，而不是铺满整个屏幕',
			'settings.viewMode' => '视图模式',
			'settings.gridView' => '网格视图',
			'settings.listView' => '列表视图',
			'settings.showHeroSection' => '显示精选内容区',
			'settings.continueWatchingAction' => '继续观看操作',
			'settings.continueWatchingPlay' => '播放',
			'settings.continueWatchingDetails' => '打开详情',
			'settings.episodeAction' => '剧集操作',
			'settings.episodePlay' => '播放',
			'settings.episodeDetails' => '打开详情',
			'settings.useGlobalHubs' => '使用主页布局',
			'settings.useGlobalHubsDescription' => '显示统一主页内容；否则使用各媒体库的推荐内容。',
			'settings.showServerNameOnHubs' => '在推荐栏显示服务器名称',
			'settings.showServerNameOnHubsDescription' => '始终在推荐栏标题中显示服务器名称。',
			'settings.groupLibrariesByServer' => '按服务器分组媒体库',
			'settings.groupLibrariesByServerDescription' => '在侧边栏中按媒体服务器分组媒体库。',
			'settings.alwaysKeepSidebarOpen' => '始终保持侧边栏展开',
			'settings.alwaysKeepSidebarOpenDescription' => '侧边栏保持展开状态，内容区域自动调整',
			'settings.showUnwatchedCount' => '显示未观看数量',
			'settings.showUnwatchedCountDescription' => '在剧集和季上显示未观看集数',
			'settings.showEpisodeNumberOnCards' => '在卡片上显示集数',
			'settings.showEpisodeNumberOnCardsDescription' => '在剧集卡片上显示季和集编号',
			'settings.showSeasonPostersOnTabs' => '在选项卡上显示季海报',
			'settings.showSeasonPostersOnTabsDescription' => '在每季标签上方显示该季海报',
			'settings.tvFullCardLayout' => '完整电视卡片',
			'settings.tvFullCardLayoutDescription' => '使用仅显示图片的电视卡片，并在图片上叠加演员姓名',
			'settings.focusGlow' => '焦点光晕',
			'settings.focusGlowDescription' => '在获得焦点的卡片周围显示柔和的光晕',
			'settings.visualEffects' => '视觉效果',
			'settings.visualEffectsAuto' => '自动',
			'settings.visualEffectsAutoDescription' => '在性能较低的设备上自动减少效果',
			'settings.visualEffectsFull' => '完整效果',
			'settings.visualEffectsReduced' => '简化',
			'settings.visualEffectsReducedDescription' => '减少动画并使用较低分辨率的封面图片',
			'settings.hideSpoilers' => '隐藏未看剧集的剧透内容',
			'settings.hideSpoilersDescription' => '模糊未观看剧集的缩略图和描述',
			'settings.playerBackend' => '播放器引擎',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => '硬件解码',
			'settings.hardwareDecodingDescription' => '如果可用，使用硬件加速',
			'settings.bufferSize' => '缓冲区大小',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => '自动（推荐）',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => '可用内存 ${heap}MB。${size}MB 缓冲可能影响播放。',
			'settings.playbackBuffer' => '播放缓冲',
			'settings.playbackBufferAuto' => '自动（推荐）',
			'settings.playbackBufferLarge' => '大',
			'settings.playbackBufferExtraLarge' => '特大',
			'settings.playbackBufferDescription' => '针对不稳定的连接缓冲更多内容。也受缓冲大小限制。',
			'settings.defaultQualityTitle' => '默认画质',
			'settings.musicQualityTitle' => '音乐音质',
			'settings.subtitleStyling' => '字幕样式',
			'settings.subtitleStylingDescription' => '调整字幕外观',
			'settings.smallSkipDuration' => '短跳过时长',
			'settings.largeSkipDuration' => '长跳过时长',
			'settings.rewindOnResume' => '恢复时回退',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} 秒',
			'settings.defaultSleepTimer' => '默认睡眠定时器',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} 分钟',
			'settings.rememberTrackSelections' => '记住每部剧集或电影的音轨选择',
			'settings.rememberTrackSelectionsDescription' => '分别记住每部内容的音频和字幕选择',
			'settings.followServerTrackSelections' => '使用服务器为每集选择的轨道',
			'settings.followServerTrackSelectionsDescription' => '切换剧集时，应用服务器上为该集选择的音频和字幕，而不是沿用当前选择',
			'settings.showChapterMarkersOnTimeline' => '在进度条上显示章节标记',
			'settings.showChapterMarkersOnTimelineDescription' => '按章节边界分段显示进度条',
			'settings.specialsOrdering' => '特别篇按剧集顺序',
			'settings.specialsOrderingDescription' => '特别篇在剧集观看顺序中的播放位置',
			'settings.specialsOrderingServer' => '遵循服务器顺序',
			'settings.specialsOrderingAirDate' => '按播出日期穿插',
			'settings.specialsOrderingLast' => '常规季之后',
			'settings.clickVideoTogglesPlayback' => '点击视频可切换播放/暂停',
			'settings.clickVideoTogglesPlaybackDescription' => '点击视频即可播放或暂停，而不是显示控制项。',
			'settings.videoPlayerControls' => '视频播放器控制',
			'settings.keyboardShortcuts' => '键盘快捷键',
			'settings.keyboardShortcutsDescription' => '自定义键盘快捷键',
			'settings.videoPlayerNavigation' => '视频播放器导航',
			'settings.videoPlayerNavigationDescription' => '使用方向键导航视频播放器控件',
			'settings.watchTogetherRelay' => '一起看中继服务器',
			'settings.watchTogetherRelayDescription' => '设置自定义中继。所有人必须使用同一服务器。',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.watchTogetherRelayInvalid' => '请输入有效的 HTTP 或 HTTPS 中继服务器基础 URL。',
			'settings.crashReporting' => '崩溃报告',
			'settings.crashReportingDescription' => '发送崩溃报告以帮助改进应用',
			'settings.debugLogging' => '调试日志',
			'settings.debugLoggingDescription' => '启用详细日志记录以便故障排除',
			'settings.viewLogs' => '查看日志',
			'settings.viewLogsDescription' => '查看应用日志',
			'settings.clearImageCache' => '清除图片缓存',
			'settings.clearImageCacheDescription' => '清除缓存的封面与缩略图。图片在重新下载前加载速度可能会变慢。',
			'settings.clearImageCacheSuccess' => '图片缓存已成功清除',
			'settings.resetSettings' => '重置设置',
			'settings.resetSettingsDescription' => '恢复默认设置。此操作无法撤销。',
			'settings.resetSettingsSuccess' => '设置重置成功',
			'settings.backup' => '备份',
			'settings.exportSettings' => '导出设置',
			'settings.exportSettingsDescription' => '将偏好设置保存到文件',
			'settings.exportSettingsSuccess' => '设置已导出',
			'settings.importSettings' => '导入设置',
			'settings.importSettingsDescription' => '从文件恢复偏好设置',
			'settings.importSettingsConfirm' => '这将替换您当前的设置。继续吗？',
			'settings.importSettingsSuccess' => '设置已导入',
			'settings.importSettingsInvalidFile' => '此文件不是有效的 Plezy 设置导出',
			'settings.importSettingsNoUser' => '导入设置前请先登录',
			'settings.shortcutsReset' => '快捷键已重置为默认值',
			'settings.about' => '关于',
			'settings.aboutDescription' => '应用程序信息和许可证',
			'settings.updates' => '更新',
			'settings.updateAvailable' => '有可用更新',
			'settings.checkForUpdates' => '检查更新',
			'settings.autoCheckUpdatesOnStartup' => '启动时自动检查更新',
			'settings.autoCheckUpdatesOnStartupDescription' => '启动时有可用更新则通知',
			'settings.validationErrorEnterNumber' => '请输入有效数字',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => '时长必须介于 ${min} 和 ${max} ${unit} 之间',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => '快捷键已被分配给 ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => '快捷键已为 ${action} 更新',
			'settings.saveFailed' => '无法保存更改。请重试。',
			'settings.autoSkip' => '自动跳过',
			'settings.autoSkipIntro' => '自动跳过片头',
			'settings.autoSkipIntroDescription' => '几秒钟后自动跳过片头标记',
			'settings.autoSkipCredits' => '自动跳过片尾',
			'settings.autoSkipCreditsDescription' => '自动跳过片尾并播放下一集',
			'settings.forceSkipMarkerFallback' => '强制使用备用标记',
			'settings.forceSkipMarkerFallbackDescription' => '即使 Plex 有标记，也使用章节标题模式',
			'settings.autoSkipDelay' => '自动跳过延迟',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => '自动跳过前等待 ${seconds} 秒',
			'settings.introPattern' => '片头标记模式',
			'settings.introPatternDescription' => '用于匹配章节标题中片头标记的正则表达式',
			'settings.creditsPattern' => '片尾标记模式',
			'settings.creditsPatternDescription' => '用于匹配章节标题中片尾标记的正则表达式',
			'settings.invalidRegex' => '无效的正则表达式',
			'settings.regex' => '正则表达式',
			'settings.downloads' => '下载',
			'settings.downloadLocationDescription' => '选择下载内容的存储位置',
			'settings.downloadLocationDefault' => '默认（应用存储）',
			'settings.downloadLocationCustom' => '自定义位置',
			'settings.selectFolder' => '选择文件夹',
			'settings.resetToDefault' => '重置为默认',
			'settings.currentPath' => ({required Object path}) => '当前路径：${path}',
			'settings.downloadLocationChanged' => '下载位置已更改',
			'settings.downloadLocationReset' => '下载位置已重置为默认',
			'settings.downloadLocationInvalid' => '所选文件夹不可写入',
			'settings.downloadLocationPickerUnavailable' => '此设备不支持选择文件夹',
			'settings.downloadOnWifiOnly' => '仅通过 Wi-Fi 下载',
			'settings.downloadOnWifiOnlyDescription' => '使用移动数据时不允许下载',
			'settings.autoRemoveWatchedDownloads' => '自动移除已观看的下载',
			'settings.autoRemoveWatchedDownloadsDescription' => '自动删除已观看的下载',
			'settings.cellularDownloadBlocked' => '已阻止通过移动网络下载。请连接 Wi-Fi 或更改设置。',
			'settings.maxVolume' => '最大音量',
			'settings.maxVolumeDescription' => '允许音量超过 100%，以便播放音量较低的内容',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord 动态状态',
			'settings.discordRichPresenceDescription' => '在 Discord 上显示您正在观看的内容',
			'settings.services' => '服务',
			'settings.servicesDescription' => '连接 Trakt、MyAnimeList、Seerr 等',
			'settings.manageLibrariesDescription' => '重新排序和隐藏媒体库',
			'settings.companionRemoteServer' => '远程控制服务器',
			'settings.companionRemoteServerDescription' => '允许同一网络中的移动设备控制此应用',
			'settings.autoPip' => '自动画中画',
			'settings.autoPipDescription' => '播放期间离开应用时自动进入画中画模式',
			'settings.matchContentFrameRate' => '匹配内容帧率',
			'settings.matchContentFrameRateDescription' => '使显示器刷新率与视频帧率匹配',
			'settings.matchContentResolution' => '匹配内容分辨率',
			'settings.matchContentResolutionDescription' => '将显示切换为视频的原生分辨率，由电视负责放大。播放期间菜单和字幕也会一并放大',
			'settings.matchRefreshRate' => '匹配刷新率',
			'settings.matchRefreshRateDescription' => '全屏时匹配显示刷新率',
			'settings.matchDynamicRange' => '匹配动态范围',
			'settings.matchDynamicRangeDescription' => 'HDR 内容切换到 HDR，随后切回 SDR',
			'settings.displaySwitchDelay' => '显示切换延迟',
			'settings.tunneledPlayback' => '隧道播放',
			'settings.tunneledPlaybackDescription' => '使用视频隧道模式。若播放 HDR 内容时出现黑屏，请将其关闭。',
			'settings.audioPassthrough' => '音频直通',
			'settings.audioPassthroughDescription' => '将 Dolby/DTS 音频不经重新编码直接发送到功放或电视，保留环绕声。如果没有声音，请关闭。',
			'settings.audioPassthroughDescriptionAppleTv' => '将 Dolby Digital Plus（含 Atmos）以比特流方式交给系统输出。DTS 和 TrueHD 仍以多声道 PCM 播放。快进快退时可能出现短暂声音中断。',
			'settings.audioDownmix' => '下混为立体声',
			'settings.audioDownmixDescription' => '将环绕声混合为双声道，适用于立体声音箱或耳机',
			'settings.downmixCenterBoost' => '中置声道增强',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => '增强（dB）',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => '下混时音量标准化',
			'settings.audioDownmixNormalizeDescription' => '降低混音电平以防止削波。关闭可保持原始音量（大音量场景可能失真）。',
			'settings.dvConversionMode' => 'Dolby Vision 转换',
			'settings.dvConversionModeDescription' => '选择 ExoPlayer 如何处理 Dolby Vision Profile 7 文件。',
			'settings.dvConversionAuto' => '自动',
			'settings.dvConversionNative' => '原生 / 禁用',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => '使用设备能力检测和常规回退机制',
			'settings.dvConversionNativeDescription' => '强制原生 DV7 并禁止重试 DV 转换',
			'settings.dvConversionDv81Description' => '强制内联 RPU 转换为 Dolby Vision Profile 8.1',
			'settings.dvConversionHevcStripDescription' => '移除 Dolby Vision RPU/EL 层并呈现普通 HEVC',
			'settings.demuxer' => '容器解复用器',
			'settings.demuxerDescription' => '由哪个解复用器解析直接播放的文件。若某个文件播放异常，可切换为 media3。',
			'settings.demuxerFfmpeg' => 'FFmpeg（推荐）',
			'settings.demuxerMedia3' => 'media3',
			'settings.requireProfileSelectionOnOpen' => '打开应用时选择用户资料',
			'settings.requireProfileSelectionOnOpenDescription' => '每次打开应用时都显示用户资料选择界面',
			'settings.forceTvMode' => '强制 TV 模式',
			'settings.forceTvModeDescription' => '强制 TV 布局。适用于无法自动检测的设备。需要重启。',
			'settings.startInFullscreen' => '以全屏模式启动',
			'settings.startInFullscreenDescription' => '启动时以全屏模式打开 Plezy',
			'settings.exitFullscreenOnPlayerClose' => '关闭播放器时退出全屏',
			'settings.exitFullscreenOnPlayerCloseDescription' => '关闭视频播放器时自动退出全屏模式',
			'settings.autoHidePerformanceOverlay' => '自动隐藏性能叠加层',
			'settings.autoHidePerformanceOverlayDescription' => '性能叠加层随播放控件一起淡入淡出',
			'settings.showNavBarLabels' => '显示导航栏标签',
			'settings.showNavBarLabelsDescription' => '在导航栏图标下方显示文字标签',
			'settings.startupSection' => '启动页面',
			'settings.showExploreTab' => '显示“探索”标签页',
			'settings.showExploreTabDescription' => '显示“探索”标签页，其中包含来自 Plex Discover 和已连接追踪服务的内容',
			'settings.liveTvDefaultFavorites' => '默认显示收藏频道',
			'settings.liveTvDefaultFavoritesDescription' => '打开直播电视时仅显示收藏频道',
			'settings.display' => '显示',
			'settings.homeScreen' => '主屏幕',
			'settings.navigation' => '导航',
			'settings.window' => '窗口',
			'settings.content' => '内容',
			'settings.player' => '播放器',
			'settings.subtitlesAndConfig' => '字幕与配置',
			'settings.seekAndTiming' => '跳转与计时',
			'settings.behavior' => '行为',
			'settings.rememberPlayerChanges' => '记住播放器更改',
			'settings.rememberPlayerChangesDescription' => '播放期间所做的更改保存并重新应用的位置',
			'settings.scopePlaybackSpeed' => '播放速度',
			'settings.scopeShaderPreset' => '着色器预设',
			'settings.scopeAspectRatio' => '宽高比',
			'settings.scopeSyncOffsets' => '音频和字幕同步',
			'settings.playerScopeOff' => '不保存',
			'settings.playerScopeGlobal' => '所有位置',
			'settings.playerScopeLibrary' => '按媒体库',
			'settings.playerScopeTitle' => '按剧集或电影',
			'settings.exportDialogTitle' => '导出 Plezy 设置',
			'search.hint' => '搜索电影、剧集、音乐…',
			'search.tryDifferentTerm' => '尝试不同的搜索词',
			'search.searchYourMedia' => '搜索媒体',
			'search.enterTitleActorOrKeyword' => '输入标题、演员或关键词',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => '为 ${actionName} 设置快捷键',
			'hotkeys.clearShortcut' => '清除快捷键',
			'hotkeys.noShortcutSet' => '未设置快捷键',
			'hotkeys.currentShortcut' => '当前快捷键：',
			'hotkeys.pressToRecord' => '点击后录入快捷键',
			'hotkeys.recordingShortcut' => '请按下快捷键',
			'hotkeys.actions.playPause' => '播放/暂停',
			'hotkeys.actions.volumeUp' => '增大音量',
			'hotkeys.actions.volumeDown' => '减小音量',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => '快进 (${seconds}秒)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => '快退 (${seconds}秒)',
			'hotkeys.actions.fullscreenToggle' => '切换全屏',
			'hotkeys.actions.muteToggle' => '切换静音',
			'hotkeys.actions.subtitleToggle' => '切换字幕',
			'hotkeys.actions.audioTrackNext' => '下一音轨',
			'hotkeys.actions.subtitleTrackNext' => '下一字幕轨',
			'hotkeys.actions.chapterNext' => '下一章节',
			'hotkeys.actions.chapterPrevious' => '上一章节',
			'hotkeys.actions.episodeNext' => '下一集',
			'hotkeys.actions.episodePrevious' => '上一集',
			'hotkeys.actions.speedIncrease' => '加速',
			'hotkeys.actions.speedDecrease' => '减速',
			'hotkeys.actions.speedReset' => '重置速度',
			'hotkeys.actions.zoomIn' => '放大',
			'hotkeys.actions.zoomOut' => '缩小',
			'hotkeys.actions.zoomReset' => '重置缩放',
			'hotkeys.actions.subSeekNext' => '跳转到下一条字幕',
			'hotkeys.actions.subSeekPrev' => '跳转到上一条字幕',
			'hotkeys.actions.shaderToggle' => '切换着色器',
			'hotkeys.actions.skipMarker' => '跳过片头/片尾',
			'hotkeys.actions.screenshot' => '截图',
			'fileInfo.title' => '文件信息',
			'fileInfo.overview' => '简介',
			'fileInfo.video' => '视频',
			'fileInfo.audio' => '音频',
			'fileInfo.subtitles' => '字幕',
			'fileInfo.images' => '内嵌图片',
			'fileInfo.dataStreams' => '数据流',
			'fileInfo.lyrics' => '歌词',
			'fileInfo.file' => '文件',
			'fileInfo.attachments' => '附件',
			'fileInfo.delivery' => '传输方式',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => '第 ${index} 个版本，共 ${count} 个',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => '第 ${index} 个文件，共 ${count} 个',
			'fileInfo.noStreams' => '服务器报告此文件没有媒体流。',
			'fileInfo.copyPath' => '复制路径',
			'fileInfo.pathCopied' => '文件路径已复制',
			'fileInfo.codec' => '编解码器',
			'fileInfo.codecTag' => '编码器标签',
			'fileInfo.resolution' => '分辨率',
			'fileInfo.codedResolution' => '编码分辨率',
			'fileInfo.bitrate' => '比特率',
			'fileInfo.frameRate' => '帧率',
			'fileInfo.rotation' => '旋转',
			'fileInfo.comment' => '注释',
			'fileInfo.audioDescription' => '音频描述',
			'fileInfo.headerCompression' => '头部压缩',
			'fileInfo.sidecarFile' => '外挂文件',
			'fileInfo.transportTimestamp' => '传输时间戳',
			'fileInfo.displayOffset' => '显示偏移',
			'fileInfo.previewFailureCode' => '预览失败代码',
			'fileInfo.previewRetries' => '预览重试次数',
			'fileInfo.aspectRatio' => '宽高比',
			'fileInfo.pixelAspectRatio' => '像素宽高比',
			'fileInfo.profile' => '编码配置',
			'fileInfo.level' => '级别',
			'fileInfo.bitDepth' => '位深度',
			'fileInfo.pixelFormat' => '像素格式',
			'fileInfo.colorSpace' => '色彩空间',
			'fileInfo.colorRange' => '色彩范围',
			'fileInfo.colorPrimaries' => '色彩基色',
			'fileInfo.colorTransfer' => '色彩转换',
			'fileInfo.chromaSubsampling' => '色度子采样',
			'fileInfo.chromaLocation' => '色度位置',
			'fileInfo.scanType' => '扫描类型',
			'fileInfo.interlaced' => '隔行扫描',
			'fileInfo.anamorphic' => '变形宽银幕',
			'fileInfo.referenceFrames' => '参考帧',
			'fileInfo.dynamicRange' => '动态范围',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Dolby Vision 级别',
			'fileInfo.dolbyVisionVersion' => 'Dolby Vision 版本',
			'fileInfo.dolbyVisionLayers' => 'Dolby Vision 图层',
			'fileInfo.baseLayerCompatibility' => '基础层兼容性',
			'fileInfo.avcBitstream' => 'AVC 比特流',
			'fileInfo.nalLengthSize' => 'NAL 长度',
			'fileInfo.scalingMatrix' => '自定义缩放矩阵',
			'fileInfo.streamIdentifier' => '流标识符',
			'fileInfo.streamIndex' => '流索引',
			'fileInfo.streamId' => '流 ID',
			'fileInfo.language' => '语言',
			'fileInfo.languageCode' => '语言代码',
			'fileInfo.streamTitle' => '轨道标题',
			'fileInfo.channels' => '声道',
			'fileInfo.sampleRate' => '采样率',
			'fileInfo.spatialAudio' => '空间音频',
			'fileInfo.textBased' => '基于文本',
			'fileInfo.subtitleFormat' => '外挂文件格式',
			'fileInfo.provider' => '提供方',
			'fileInfo.matchScore' => '匹配分数',
			'fileInfo.externalDelivery' => '可单独提供',
			'fileInfo.sidecarPath' => '外挂文件路径',
			'fileInfo.sourceStream' => '复制来源',
			'fileInfo.temporary' => '临时',
			'fileInfo.timeBase' => '时间基准',
			'fileInfo.overallBitrate' => '总比特率',
			'fileInfo.path' => '路径',
			'fileInfo.fileName' => '文件名',
			'fileInfo.size' => '大小',
			'fileInfo.totalSize' => '总大小',
			'fileInfo.container' => '容器',
			'fileInfo.duration' => '时长',
			'fileInfo.previewThumbnails' => '预览缩略图',
			'fileInfo.previewIndex' => '预览索引',
			'fileInfo.packetLength' => '数据包长度',
			'fileInfo.filePresent' => '文件存在',
			'fileInfo.fileReadable' => '服务器可读',
			'fileInfo.streamPath' => '流路径',
			'fileInfo.optimizedForStreaming' => '已针对流式传输优化',
			'fileInfo.has64bitOffsets' => '64 位偏移量',
			'fileInfo.protocol' => '协议',
			'fileInfo.mediaType' => '媒体类型',
			'fileInfo.sourceKind' => '来源类型',
			'fileInfo.optimizedVersion' => '优化版本',
			'fileInfo.optimizationTarget' => '优化目标',
			'fileInfo.deletedAt' => '已删除',
			'fileInfo.remoteSource' => '远程来源',
			'fileInfo.infiniteStream' => '无限流',
			'fileInfo.directPlay' => '直接播放',
			'fileInfo.directStream' => '直接串流',
			'fileInfo.transcoding' => '转码',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => '版本 ID',
			'fileInfo.fileId' => '文件 ID',
			'fileInfo.defaultAudioTrack' => '默认音轨',
			'fileInfo.defaultSubtitleTrack' => '默认字幕轨道',
			'fileInfo.subtitlesOff' => '关闭',
			'fileInfo.flagDefault' => '默认',
			'fileInfo.flagForced' => '强制',
			'fileInfo.flagSelected' => '已选',
			'fileInfo.flagExternal' => '外部',
			'fileInfo.flagHearingImpaired' => '听障辅助',
			'fileInfo.flagDub' => '配音',
			'fileInfo.flagOriginal' => '原声',
			'fileInfo.channelsMono' => '单声道',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => '编码配置 ${profile}',
			_ => null,
		} ?? switch (path) {
			'mediaMenu.markAsWatched' => '标记为已观看',
			'mediaMenu.markAsUnwatched' => '标记为未观看',
			'mediaMenu.removeFromContinueWatching' => '从继续观看中移除',
			'mediaMenu.viewDetails' => '查看详情',
			'mediaMenu.goToSeries' => '前往剧集',
			'mediaMenu.shufflePlay' => '随机播放',
			'mediaMenu.shuffleNotAvailableOffline' => '离线时无法随机播放',
			'mediaMenu.fileInfo' => '文件信息',
			'mediaMenu.deleteEpisodeFromServer' => '从服务器删除单集',
			'mediaMenu.deleteSeasonFromServer' => '从服务器删除季度',
			'mediaMenu.deleteShowFromServer' => '从服务器删除剧集',
			'mediaMenu.deleteMovieFromServer' => '从服务器删除电影',
			'mediaMenu.deleteEpisodeTitle' => '删除这个单集？',
			'mediaMenu.deleteSeasonTitle' => '删除这一季度？',
			'mediaMenu.deleteShowTitle' => '删除这部剧集？',
			'mediaMenu.deleteMovieTitle' => '删除这部电影？',
			'mediaMenu.deleteEpisodeConfirm' => '删除单集',
			'mediaMenu.deleteSeasonConfirm' => '删除季度',
			'mediaMenu.deleteShowConfirm' => '删除剧集',
			'mediaMenu.deleteMovieConfirm' => '删除电影',
			'mediaMenu.deleteAnyway' => '仍然删除',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => '从你的服务器永久删除 ${title}？',
			'mediaMenu.deleteMultipleWarning' => '这包括所有剧集及其文件。',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '这将删除其中全部 ${n} 集以及它们的文件。', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '此项目存储在 ${n} 个文件中，所有这些文件都会被删除。', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '另外 ${n} 集存储在同一个文件中，也会一并删除：', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'Plezy 无法确认此操作会删除哪些文件，因此删除范围可能超出上面提到的项目。请取消后重试，或仍然删除。',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => '你的服务器没有提供此项目的文件详情，因此 Plezy 无法确认此操作会删除哪些文件。删除范围可能超出上面提到的项目。',
			'mediaMenu.mediaDeletedSuccessfully' => '媒体项已成功删除',
			'mediaMenu.mediaFailedToDelete' => '删除媒体项失败',
			'mediaMenu.rate' => '评分',
			'mediaMenu.playFromBeginning' => '从头播放',
			'mediaMenu.playVersion' => '播放版本…',
			'rateSheet.title' => '评分',
			'rateSheet.server' => '服务器',
			'rateSheet.favorite' => '收藏',
			'rateSheet.favorited' => '已收藏',
			'rateSheet.saved' => '已保存',
			'rateSheet.notAvailable' => '未找到匹配项',
			'rateSheet.noConnectedServices' => '在设置中连接服务，即可在此评分。',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, 电影',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, 电视剧',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => '已观看',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '已观看 ${percent}%',
			'accessibility.mediaCardUnwatched' => '未观看',
			'accessibility.tapToPlay' => '点击播放',
			'accessibility.decrease' => '减小',
			'accessibility.increase' => '增大',
			'accessibility.decreaseValue' => ({required Object label}) => '减小${label}',
			'accessibility.increaseValue' => ({required Object label}) => '增大${label}',
			'accessibility.hue' => '色相',
			'accessibility.saturation' => '饱和度',
			'accessibility.brightness' => '亮度',
			'accessibility.hexColor' => '十六进制颜色',
			'accessibility.expandText' => '展开文本',
			'accessibility.collapseText' => '折叠文本',
			'accessibility.alphabetNavigation' => '字母导航',
			'accessibility.alphabetScrollHint' => '上下滑动以按字母移动',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => '第 ${row} 行，共 ${rowCount} 行；第 ${column} 列，共 ${columnCount} 列',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => '第 ${row} 行，共 ${rowCount} 行',
			'accessibility.autoScrollPlay' => '开始自动滚动',
			'accessibility.autoScrollPause' => '暂停自动滚动',
			'accessibility.hueShort' => 'H',
			'accessibility.saturationShort' => 'S',
			'accessibility.valueShort' => 'V',
			'tooltips.shufflePlay' => '随机播放',
			'tooltips.playTrailer' => '播放预告片',
			'tooltips.markAsWatched' => '标记为已观看',
			'tooltips.markAsUnwatched' => '标记为未观看',
			'audioTracks.track' => ({required Object n}) => '音轨 ${n}',
			'videoControls.audioLabel' => '音频',
			'videoControls.subtitlesLabel' => '字幕',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => '黑边模式',
			'videoControls.fillScreen' => '填充屏幕',
			'videoControls.stretch' => '拉伸',
			'videoControls.lockRotation' => '锁定旋转',
			'videoControls.unlockRotation' => '解锁旋转',
			'videoControls.timerActive' => '定时器已激活',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => '播放将在 ${duration} 后暂停',
			'videoControls.sleepTimerEndOfVideo' => '当前视频结束时',
			'videoControls.sleepTimerStopAtHeader' => '停止于',
			'videoControls.sleepTimerDurationHeader' => '定时器',
			'videoControls.playbackWillPauseAtEnd' => '播放将在此视频结束时暂停',
			'videoControls.stillWatching' => '还在看吗？',
			'videoControls.pausingIn' => ({required Object seconds}) => '${seconds} 秒后暂停',
			'videoControls.continueWatching' => '继续',
			'videoControls.autoPlayNext' => '自动播放下一集',
			'videoControls.playNext' => '播放下一集',
			'videoControls.playButton' => '播放',
			'videoControls.pauseButton' => '暂停',
			'videoControls.playbackPaused' => '已暂停',
			'videoControls.playbackResumed' => '正在播放',
			'videoControls.loadingVideo' => '正在加载视频',
			'videoControls.showPlaybackControls' => '显示播放控制项',
			'videoControls.hidePlaybackControls' => '隐藏播放控制项',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => '快退 ${seconds} 秒',
			'videoControls.seekForwardButton' => ({required Object seconds}) => '快进 ${seconds} 秒',
			'videoControls.previousButton' => '上一集',
			'videoControls.nextButton' => '下一集',
			'videoControls.previousChapterButton' => '上一章节',
			'videoControls.nextChapterButton' => '下一章节',
			'videoControls.muteButton' => '静音',
			'videoControls.unmuteButton' => '取消静音',
			'videoControls.settingsButton' => '播放设置',
			'videoControls.tracksButton' => '音频和字幕',
			'videoControls.chaptersButton' => '章节',
			'videoControls.versionQualityButton' => '版本与画质',
			'videoControls.versionColumnHeader' => '版本',
			'videoControls.qualityColumnHeader' => '画质',
			'videoControls.qualityOriginal' => '原始',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => '转码不可用 — 以原始画质播放',
			'videoControls.subtitleUnavailableFallback' => '无法加载所选字幕 — 将继续无字幕播放',
			'videoControls.pipButton' => '画中画',
			'videoControls.aspectRatioButton' => '宽高比',
			'videoControls.ambientLighting' => '氛围灯光',
			'videoControls.fullscreenButton' => '进入全屏',
			'videoControls.exitFullscreenButton' => '退出全屏',
			'videoControls.alwaysOnTopButton' => '窗口置顶',
			'videoControls.rotationLockButton' => '旋转锁定',
			'videoControls.lockScreen' => '锁定屏幕',
			'videoControls.screenLockButton' => '屏幕锁定',
			'videoControls.longPressToUnlock' => '长按解锁',
			'videoControls.timelineSlider' => '视频时间轴',
			'videoControls.volumeSlider' => '音量滑块',
			'videoControls.endsAt' => ({required Object time}) => '结束时间：${time}',
			'videoControls.pipActive' => '正在以画中画模式播放',
			'videoControls.pipFailed' => '画中画启动失败',
			'videoControls.screenshotSaved' => '截图已保存',
			'videoControls.zoomPercent' => ({required Object percent}) => '缩放 ${percent}%',
			'videoControls.pipErrors.androidVersion' => '需要 Android 8.0 或更高版本',
			'videoControls.pipErrors.iosVersion' => '需要 iOS 15.0 或更高版本',
			'videoControls.pipErrors.permissionDisabled' => '画中画已禁用。请在系统设置中启用。',
			'videoControls.pipErrors.notSupported' => '此设备不支持画中画模式',
			'videoControls.pipErrors.voSwitchFailed' => '无法切换画中画的视频输出',
			'videoControls.pipErrors.failed' => '画中画启动失败',
			'videoControls.pipErrors.prepareFailed' => '无法准备画中画',
			'videoControls.pipErrors.unknown' => ({required Object error}) => '发生错误：${error}',
			'videoControls.chapters' => '章节',
			'videoControls.noChaptersAvailable' => '没有可用的章节',
			'videoControls.queue' => '播放队列',
			'videoControls.noQueueItems' => '队列中没有项目',
			'videoControls.noAudioDevicesAvailable' => '没有可用的音频设备',
			'videoControls.searchSubtitles' => '搜索字幕',
			'videoControls.language' => '语言',
			'videoControls.noSubtitlesFound' => '未找到字幕',
			'videoControls.subtitleDownloaded' => '字幕已下载',
			'videoControls.subtitleDownloadedNotApplied' => '字幕已下载，但无法选择',
			'videoControls.subtitleDownloadFailed' => '字幕下载失败',
			'videoControls.searchLanguages' => '搜索语言…',
			'videoControls.skipIntro' => '跳过片头',
			'videoControls.skipCredits' => '跳过片尾',
			'videoControls.nextEpisode' => '下一集',
			'videoControls.subtitleTrack' => ({required Object n}) => '轨道 ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => '字幕 ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label}（强制）',
			'videoControls.osdSubtitlesOff' => '字幕：关闭',
			'videoControls.osdSubtitles' => ({required Object track}) => '字幕：${track}',
			'videoControls.osdAudio' => ({required Object track}) => '音频：${track}',
			'messages.markedAsWatched' => '已标记为已观看',
			'messages.markedAsUnwatched' => '已标记为未观看',
			'messages.markedAsWatchedOffline' => '已标记为已观看（将在联网时同步）',
			'messages.markedAsUnwatchedOffline' => '已标记为未观看（将在联网时同步）',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => '已自动移除：${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '已自动移除 ${n} 个看过的下载', ), 
			'messages.removedFromContinueWatching' => '已从继续观看中移除',
			'messages.errorLoading' => ({required Object error}) => '出错：${error}',
			'messages.searchPartialResults' => '部分媒体服务器无法搜索。正在显示可用的结果。',
			'messages.streamInterrupted' => '视频流已中断。按播放键或拖动进度条重试。',
			'messages.liveStreamInterrupted' => '直播流已中断。按播放键重试。',
			'messages.fileInfoNotAvailable' => '文件信息不可用',
			'messages.playbackAuthenticationRequired' => '请重新登录媒体服务器以播放此项目。',
			'messages.playbackServerUnavailable' => '媒体服务器不可用。请稍后重试。',
			'messages.playbackDataInvalid' => '服务器返回了无效的播放信息。',
			'messages.playbackCancelled' => '播放已取消。',
			'messages.playbackFailed' => '无法开始播放。',
			'messages.errorLoadingFileInfo' => ({required Object error}) => '加载文件信息时出错：${error}',
			'messages.errorLoadingSeries' => '加载剧集时出错',
			'messages.musicNotSupported' => '尚不支持播放音乐',
			'messages.noDescriptionAvailable' => '暂无描述',
			'messages.noProfilesAvailable' => '没有可用的用户资料',
			'messages.contactAdminForProfiles' => '请联系服务器管理员添加用户资料',
			'messages.unableToDetermineLibrarySection' => '无法确定此项目所属的媒体库',
			'messages.logsCleared' => '日志已清除',
			'messages.logsCopied' => '日志已复制到剪贴板',
			'messages.noLogsAvailable' => '没有可用日志',
			'messages.libraryScanning' => ({required Object title}) => '正在扫描“${title}”…',
			'messages.libraryScanStarted' => ({required Object title}) => '已开始扫描“${title}”媒体库',
			'messages.libraryScanFailed' => ({required Object error}) => '无法扫描媒体库：${error}',
			'messages.metadataRefreshing' => ({required Object title}) => '正在刷新“${title}”的元数据…',
			'messages.metadataRefreshStarted' => ({required Object title}) => '已开始刷新“${title}”的元数据',
			'messages.metadataRefreshFailed' => ({required Object error}) => '无法刷新元数据：${error}',
			'messages.logoutConfirm' => '确定要退出登录吗？',
			'messages.noSeasonsFound' => '未找到季',
			'messages.seasonsLoadFailed' => '无法加载季',
			'messages.noEpisodesFound' => '在第一季中未找到剧集',
			'messages.noEpisodesFoundGeneral' => '未找到剧集',
			'messages.episodesLoadFailed' => '无法加载剧集',
			'messages.noResultsFound' => '未找到结果',
			'messages.sleepTimerSet' => ({required Object label}) => '睡眠定时器已设置为 ${label}',
			'messages.noItemsAvailable' => '没有可用的项目',
			'messages.failedToCreatePlayQueueNoItems' => '创建播放队列失败：没有可用项目',
			'messages.failedPlayback' => ({required Object action, required Object error}) => '无法执行“${action}”：${error}',
			'messages.switchingToCompatiblePlayer' => '正在切换到兼容的播放器…',
			'messages.serverLimitTitle' => '播放失败',
			'messages.serverLimitBody' => '服务器错误（HTTP 500）。此次会话可能因带宽或转码限制而被拒绝。请联系服务器所有者调整限制。',
			'messages.mediaUnreadableTitle' => '文件不可用',
			'messages.mediaUnreadableBody' => '服务器找到了此项目，但无法读取其文件（HTTP 404）。文件可能已被移动、删除，或其存储已离线。请联系服务器管理员检查文件并重新扫描媒体库。',
			'messages.serverBusyTitle' => '视频流不可用',
			'messages.serverBusyBody' => '服务器持续拒绝传输此文件（HTTP 503）。服务器可能正在重启或正忙，也可能是文件所在的存储设备已离线。请稍后重试；如果问题持续出现，请联系服务器所有者检查服务器和文件存储设备。',
			'messages.logsUploaded' => '日志已上传',
			'messages.logsUploadFailed' => '上传日志失败',
			'messages.logId' => '日志 ID',
			'messages.burnedSubtitlesUseMenu' => '字幕已烧录到此视频流中。请从字幕菜单中更改。',
			'messages.noVideoUrl' => '没有可用的视频 URL',
			'messages.playbackNoMediaSources' => '服务器未返回可播放的媒体源',
			'messages.playbackDataNotPrepared' => '播放数据尚未准备就绪时便开始了播放',
			'messages.streamSelectionUnavailable' => '此媒体源不支持选择视频流',
			'messages.streamSelectionFailed' => '无法应用所选视频流',
			'messages.serverUnavailableForProfile' => '没有可供当前用户资料使用的服务器',
			'subtitlingStyling.text' => '文本',
			'subtitlingStyling.border' => '边框',
			'subtitlingStyling.background' => '背景',
			'subtitlingStyling.fontSize' => '字号',
			'subtitlingStyling.textColor' => '文本颜色',
			'subtitlingStyling.borderSize' => '边框大小',
			'subtitlingStyling.borderColor' => '边框颜色',
			'subtitlingStyling.backgroundOpacity' => '背景不透明度',
			'subtitlingStyling.backgroundColor' => '背景颜色',
			'subtitlingStyling.position' => '位置',
			'subtitlingStyling.assOverride' => 'ASS 样式覆盖',
			'subtitlingStyling.overrideScale' => '缩放',
			'subtitlingStyling.overrideForce' => '强制',
			'subtitlingStyling.overrideStrip' => '移除样式',
			'subtitlingStyling.positionTop' => '顶部',
			'subtitlingStyling.positionBottom' => '底部',
			'subtitlingStyling.anchorToScreen' => '锚定到屏幕',
			'subtitlingStyling.anchorToScreenDescription' => '在宽屏视频下方的黑边中显示文本字幕',
			'subtitlingStyling.bold' => '粗体',
			'subtitlingStyling.italic' => '斜体',
			'subtitlingStyling.renderResolution' => '渲染分辨率',
			'subtitlingStyling.renderResolutionScreen' => '屏幕分辨率',
			'subtitlingStyling.renderResolutionVideo' => '视频分辨率',
			'mpvConfig.title' => 'mpv 配置',
			'mpvConfig.description' => '高级视频播放器设置',
			'mpvConfig.presets' => '预设',
			'mpvConfig.noPresets' => '没有保存的预设',
			'mpvConfig.saveAsPreset' => '保存为预设…',
			'mpvConfig.presetName' => '预设名称',
			'mpvConfig.presetNameHint' => '输入此预设的名称',
			'mpvConfig.loadPreset' => '加载',
			'mpvConfig.deletePreset' => '删除',
			'mpvConfig.presetSaved' => '预设已保存',
			'mpvConfig.presetLoaded' => '预设已加载',
			'mpvConfig.presetDeleted' => '预设已删除',
			'mpvConfig.confirmDeletePreset' => '确定要删除此预设吗？',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comment',
			'mpvConfig.embeddedVoHint' => 'Linux 上会忽略 vo、gpu-context 和 gpu-api：嵌入式视频始终通过视频平面上的 vo=libmpv 渲染，而 gpu-next（ArtCNN 等计算着色器需要它）无法以嵌入式方式运行。',
			'dialog.confirmAction' => '确认操作',
			'profiles.addPlezyProfile' => '添加 Plezy 用户资料',
			'profiles.switchingProfile' => '正在切换用户资料…',
			'profiles.deleteThisProfileTitle' => '删除此用户资料？',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => '移除 ${displayName}。连接不会受影响。',
			'profiles.active' => '当前使用',
			'profiles.manage' => '管理',
			'profiles.delete' => '删除',
			'profiles.signOut' => '退出登录',
			'profiles.signOutPlexTitle' => '退出 Plex 登录？',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => '要移除 ${displayName} 和所有 Plex Home 用户吗？可随时重新登录。',
			'profiles.signedOutPlex' => '已退出 Plex 登录。',
			'profiles.signOutFailed' => '退出登录失败。',
			'profiles.sectionTitle' => '用户资料',
			'profiles.summarySingle' => '添加用户资料，以便同时使用受管理用户和本地用户身份',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} 个用户资料 · 当前：${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} 个用户资料',
			'profiles.removeConnectionTitle' => '移除连接？',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => '移除 ${displayName} 对 ${connectionLabel} 的访问权限。其他用户资料仍可使用此连接。',
			'profiles.deleteProfileTitle' => '删除用户资料？',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => '移除 ${displayName} 及其连接。服务器仍可供其他用户资料使用。',
			'profiles.profileNameLabel' => '用户资料名称',
			'profiles.pinProtectionLabel' => 'PIN 保护',
			'profiles.pinManagedByPlex' => 'PIN 由 Plex 管理。在 plex.tv 上编辑。',
			'profiles.noPinSetEditOnPlex' => '未设置 PIN。如需设置，请在 plex.tv 上编辑 Plex Home 用户。',
			'profiles.setPin' => '设置 PIN',
			'profiles.setPinTitle' => '设置 PIN',
			'profiles.confirmPinTitle' => '确认 PIN',
			'profiles.pinSet' => '已设置 PIN',
			'profiles.changePin' => '更改',
			'profiles.removePin' => '移除',
			'profiles.connectionsLabel' => '连接',
			'profiles.add' => '添加',
			'profiles.deleteProfileButton' => '删除用户资料',
			'profiles.noConnectionsHint' => '没有连接 — 请添加连接以使用此用户资料。',
			'profiles.noConnections' => '没有连接',
			'profiles.plexHomeAccount' => 'Plex Home 账户',
			'profiles.plexAccountChip' => ({required Object account}) => 'Plex 账户：${account}',
			'profiles.plexAccountUserChip' => ({required Object account, required Object user}) => '${account} 账户下的 ${user}',
			'profiles.connectionDefault' => '默认',
			'profiles.connectionAs' => ({required Object displayName}) => '以 ${displayName} 身份',
			'profiles.makeDefault' => '设为默认',
			'profiles.removeConnection' => '移除',
			'profiles.profileRenamed' => '用户资料已重命名。',
			'profiles.borrowAddTo' => ({required Object displayName}) => '添加到 ${displayName}',
			'profiles.borrowExplain' => '使用另一个用户资料的连接。受 PIN 保护的用户资料需要输入 PIN。',
			'profiles.borrowEmpty' => '暂无可用连接。',
			'profiles.borrowEmptySubtitle' => '请先将 Plex 或 Jellyfin 连接到另一个用户资料。',
			'profiles.borrowLoadFailed' => '无法加载可用连接。请重试。',
			'profiles.borrowFromProfile' => ({required Object displayName}) => '来自 ${displayName}',
			'profiles.borrowConnectionBorrowed' => '连接已添加。',
			'profiles.borrowFailed' => '无法添加连接。',
			'profiles.incorrectPin' => 'PIN 不正确。',
			'profiles.incorrectPinTryAgain' => 'PIN 不正确。请重试。',
			'profiles.sourceProfileMissingParentAccount' => '源用户资料缺少关联的主账户。',
			'profiles.failedToLoadHomeUsers' => '无法加载您的 Plex Home 用户。请检查网络连接后重试。',
			'profiles.failedToVerifyPin' => '无法验证 PIN。',
			'profiles.newProfile' => '新建用户资料',
			'profiles.profileNameHint' => '例如：访客、儿童、客厅',
			'profiles.pinProtectionOptional' => 'PIN 保护（可选）',
			'profiles.pinExplain' => '切换用户资料时需要输入 4 位 PIN。',
			'profiles.continueButton' => '继续',
			'profiles.pinsDontMatch' => 'PIN 不匹配',
			'profiles.tokenIdentityMismatch' => 'Plex 用户资料令牌解析到了非预期服务器',
			'connections.sectionTitle' => '连接',
			'connections.addConnection' => '添加连接',
			'connections.addConnectionSubtitleNoProfile' => '使用 Plex 登录或连接 Jellyfin 服务器',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => '添加到 ${displayName}：Plex、Jellyfin，或其他用户资料的连接',
			'connections.sessionExpiredOne' => ({required Object name}) => '${name} 的会话已过期',
			'connections.sessionExpiredMany' => ({required Object count}) => '${count} 个服务器的会话已过期',
			'connections.signInAgain' => '重新登录',
			'connections.editMediaBrowserTitle' => ({required Object product}) => '编辑 ${product} 连接',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => '为 ${serverName} 添加或移除 URL。Plezy 会使用延迟最低且可访问的 URL。',
			'discover.title' => '发现',
			'discover.noContentAvailable' => '没有可用内容',
			'discover.addMediaToLibraries' => '请向你的媒体库添加一些媒体',
			'discover.continueWatching' => '继续观看',
			'discover.continueWatchingIn' => ({required Object library}) => '${library} 中继续观看',
			'discover.nextUp' => '接下来',
			'discover.nextUpIn' => ({required Object library}) => '${library} 中接下来',
			'discover.recentlyAdded' => '最近添加',
			'discover.recentlyAddedIn' => ({required Object library}) => '${library} 中最近添加',
			'discover.latestAlbumsIn' => ({required Object library}) => '${library} 中的最新专辑',
			'discover.recentlyPlayedIn' => ({required Object library}) => '${library} 中最近播放',
			'discover.mostPlayedIn' => ({required Object library}) => '${library} 中最常播放',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => '概述',
			'discover.cast' => '演员表',
			'discover.extras' => '预告片与花絮',
			'discover.studio' => '制作公司',
			'discover.rating' => '年龄分级',
			'discover.director' => '导演',
			'discover.directors' => '导演',
			'discover.movie' => '电影',
			'discover.tvShow' => '电视剧',
			'discover.minutesLeft' => ({required Object minutes}) => '剩余 ${minutes} 分钟',
			'discover.moreLikeThis' => '更多类似内容',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '${n} 个标题', ), 
			'errors.searchFailed' => ({required Object error}) => '搜索失败：${error}',
			'errors.searchUnavailable' => '搜索无法连接任何媒体服务器。',
			'errors.connectionTimeout' => ({required Object context}) => '加载 ${context} 时连接超时',
			'errors.connectionFailed' => '无法连接到媒体服务器',
			'errors.unableToLoad' => ({required Object context}) => '无法加载${context}。请重试。',
			'errors.noClientAvailable' => '没有可用客户端',
			'errors.pleaseEnterToken' => '请输入一个令牌',
			'errors.invalidToken' => '令牌无效',
			'errors.failedToVerifyToken' => ({required Object error}) => '无法验证令牌：${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => '无法切换到 ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => '无法删除 ${displayName}',
			'errors.failedToRate' => '无法更新评分',
			'libraries.title' => '媒体库',
			'libraries.fallbackTitle' => '媒体库',
			'libraries.scanLibraryFiles' => '扫描媒体库文件',
			'libraries.scanLibrary' => '扫描媒体库',
			'libraries.analyze' => '分析',
			'libraries.analyzeLibrary' => '分析媒体库',
			'libraries.refreshMetadata' => '刷新元数据',
			'libraries.emptyTrash' => '清空回收站',
			'libraries.emptyingTrash' => ({required Object title}) => '正在清空“${title}”的回收站…',
			'libraries.trashEmptied' => ({required Object title}) => '已清空“${title}”的回收站',
			'libraries.failedToEmptyTrash' => ({required Object error}) => '无法清空回收站：${error}',
			'libraries.analyzing' => ({required Object title}) => '正在分析“${title}”…',
			'libraries.analysisStarted' => ({required Object title}) => '已开始分析“${title}”',
			'libraries.failedToAnalyze' => ({required Object error}) => '无法分析媒体库：${error}',
			'libraries.noLibrariesFound' => '未找到媒体库',
			'libraries.allLibrariesHidden' => '所有媒体库已隐藏',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => '已隐藏的媒体库 (${count})',
			'libraries.thisLibraryIsEmpty' => '此媒体库为空',
			'libraries.noItemsMatchFilters' => '没有项目符合当前筛选条件',
			'libraries.resetFilters' => '重置筛选条件',
			'libraries.all' => '全部',
			'libraries.clearAll' => '全部清除',
			'libraries.scanLibraryConfirm' => ({required Object title}) => '确定要扫描“${title}”吗？',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => '确定要分析“${title}”吗？',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => '确定要刷新“${title}”的元数据吗？',
			'libraries.emptyTrashConfirm' => ({required Object title}) => '确定要清空“${title}”的回收站吗？',
			'libraries.manageLibraries' => '管理媒体库',
			'libraries.sort' => '排序',
			'libraries.sortBy' => '排序依据',
			'libraries.filters' => '筛选',
			'libraries.confirmActionMessage' => '确定要执行此操作吗？',
			'libraries.showLibrary' => '显示媒体库',
			'libraries.hideLibrary' => '隐藏媒体库',
			'libraries.libraryOptions' => '媒体库选项',
			'libraries.content' => '媒体库内容',
			'libraries.selectLibrary' => '选择媒体库',
			'libraries.filtersWithCount' => ({required Object count}) => '筛选器（${count}）',
			'libraries.noRecommendations' => '暂无推荐',
			'libraries.noCollections' => '此媒体库中没有合集',
			'libraries.noFoldersFound' => '未找到文件夹',
			'libraries.folders' => '文件夹',
			'libraries.tabs.recommended' => '推荐',
			'libraries.tabs.browse' => '浏览',
			'libraries.tabs.collections' => '合集',
			'libraries.tabs.playlists' => '播放列表',
			'libraries.groupings.title' => '分组',
			'libraries.groupings.all' => '全部',
			'libraries.groupings.movies' => '电影',
			'libraries.groupings.shows' => '剧集',
			'libraries.groupings.seasons' => '季',
			'libraries.groupings.episodes' => '集',
			'libraries.groupings.artists' => '艺术家',
			'libraries.groupings.albums' => '专辑',
			'libraries.groupings.tracks' => '曲目',
			'libraries.groupings.folders' => '文件夹',
			'libraries.filterCategories.genre' => '类型',
			'libraries.filterCategories.year' => '年份',
			'libraries.filterCategories.contentRating' => '内容分级',
			'libraries.filterCategories.tag' => '标签',
			'libraries.filterCategories.unwatched' => '未观看',
			'libraries.filterCategories.unplayed' => '未播放',
			'libraries.filterCategories.favorites' => '收藏夹',
			'libraries.sortLabels.title' => '标题',
			'libraries.sortLabels.dateAdded' => '添加日期',
			'libraries.sortLabels.releaseDate' => '发行日期',
			'libraries.sortLabels.rating' => '评分',
			'libraries.sortLabels.communityRating' => '社区评分',
			'libraries.sortLabels.criticRating' => '影评人评分',
			'libraries.sortLabels.userRating' => '用户评分',
			'libraries.sortLabels.datePlayed' => '播放日期',
			'libraries.sortLabels.playCount' => '播放次数',
			'libraries.sortLabels.productionYear' => '制作年份',
			'libraries.sortLabels.runtime' => '时长',
			'libraries.sortLabels.officialRating' => '官方分级',
			'libraries.sortLabels.premiereDate' => '首映日期',
			'libraries.sortLabels.startDate' => '开始日期',
			'libraries.sortLabels.airTime' => '播出时间',
			'libraries.sortLabels.studio' => '制片公司',
			'libraries.sortLabels.random' => '随机',
			'libraries.sortLabels.dateShared' => '共享日期',
			'libraries.sortLabels.latestEpisodeAirDate' => '最新一集播出日期',
			'libraries.sortLabels.lastEpisodeDateAdded' => '最新一集添加日期',
			'about.title' => '关于',
			'about.openSourceLicenses' => '开源许可证',
			'about.versionLabel' => ({required Object version}) => '版本 ${version}',
			'about.appDescription' => '一款精美的 Flutter Plex 和 Jellyfin 客户端',
			'about.viewLicensesDescription' => '查看第三方库的许可证',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => '未找到 ${username}（${email}）的服务器',
			'serverSelection.failedToLoadServers' => ({required Object error}) => '无法加载服务器：${error}',
			'serverSelection.noValidServers' => '此账号下未找到可用的服务器',
			'hubDetail.title' => '标题',
			'hubDetail.releaseYear' => '发行年份',
			'hubDetail.dateAdded' => '添加日期',
			'hubDetail.rating' => '评分',
			'hubDetail.noItemsFound' => '未找到项目',
			'logs.clearLogs' => '清除日志',
			'logs.copyLogs' => '复制日志',
			'logs.uploadLogs' => '上传日志',
			'startup.failedTitle' => 'Plezy 无法启动',
			'startup.failedBody' => '启动过程中出现问题。以下详情指出了失败的原因。',
			'startup.failedBodyRepairable' => 'Plezy 的已保存设置文件已损坏，必须先重建才能启动。重试没有用——请选择“修复存储”。',
			'startup.phaseLabel' => '步骤',
			'startup.showDetails' => '显示详情',
			'startup.hideDetails' => '隐藏详情',
			'startup.copyDetails' => '复制详情',
			'startup.detailsCopied' => '详情已复制到剪贴板',
			'startup.uploadDetails' => '上传详情',
			'startup.repairStorage' => '修复存储',
			'startup.repairTitle' => '修复已存储的数据？',
			'startup.repairBodyCommon' => 'Plezy 的设置文件已损坏且无法读取。修复会将所有设置重置为默认值。',
			'startup.repairBodyOneCredential' => '有一项已保存的登录信息已损坏且无法读取。修复只会移除这一项，其他设置保持不变。',
			'startup.repairBodySignInsKept' => '你的服务器和个人资料应保持登录状态。',
			'startup.repairBodySignInsLost' => '保护已保存登录信息的密钥无法从此文件中恢复，因此你需要重新登录每个服务器和个人资料。媒体服务器上的内容不受影响。',
			'startup.repairBodySessionsUncertain' => '追踪服务（MAL、AniList、Simkl、Trakt）和 Seerr 是分开存储的，可能保留也可能无法保留。Plezy 会明确告诉你保留了哪些。',
			'startup.repairConfirm' => '修复',
			'startup.repairSucceeded' => '存储已修复',
			'startup.repairNeedsRestart' => '存储已修复 — 需要重启',
			'startup.restartRequiredBody' => '你的数据已修复，但 Plezy 需要重新启动后才能使用。请关闭 Plezy 并重新打开。',
			'startup.quitPlezy' => '退出 Plezy',
			'startup.repairFailed' => '修复失败',
			'startup.repairKeptSignIns' => '你的服务器和个人资料仍然保持登录状态。',
			'startup.repairLostSignIns' => '保护已保存登录信息的密钥无法恢复。你需要重新登录每个服务器和个人资料。',
			'startup.repairLostSessions' => '至少有一个追踪服务或 Seerr 连接已丢失，需要重新连接。',
			'startup.backupTitle' => '已保留损坏文件的副本',
			'startup.backupWarning' => '其中包含你的登录凭据。请勿上传或分享。',
			'startup.deleteBackup' => '删除副本',
			'startup.backupDeleted' => '副本已删除。',
			'startup.previousFailureTitle' => 'Plezy 上次启动失败',
			'licenses.relatedPackages' => '相关软件包',
			'licenses.license' => '许可证',
			'licenses.licenseNumber' => ({required Object number}) => '许可证 ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} 个许可证',
			'navigation.libraries' => '媒体库',
			'navigation.downloads' => '下载',
			'navigation.liveTv' => '直播电视',
			'navigation.explore' => '探索',
			'explore.title' => '探索',
			'explore.selectSource' => '选择来源',
			'explore.rows.watchlist' => '想看列表',
			'explore.rows.recommendedMovies' => '推荐电影',
			'explore.rows.recommendedShows' => '推荐剧集',
			_ => null,
		} ?? switch (path) {
			'explore.rows.trendingMovies' => '近期热门电影',
			'explore.rows.trendingShows' => '近期热门剧集',
			'explore.rows.popularMovies' => '人气电影',
			'explore.rows.popularShows' => '人气剧集',
			'explore.rows.trendingAnime' => '热门动画',
			'explore.rows.suggestedAnime' => '推荐动画',
			'explore.rows.airingAnime' => '热门连载动画',
			'explore.rows.popularAnime' => '最受欢迎动画',
			'explore.rows.trending' => '近期热门',
			'explore.rows.upcomingMovies' => '即将上映的电影',
			'explore.rows.upcomingShows' => '即将播出的剧集',
			'explore.status.airing' => '连载中',
			'explore.status.ended' => '已完结',
			'explore.status.canceled' => '已取消',
			'explore.status.upcoming' => '即将上线',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '${n} 集', ), 
			'explore.cast' => '演员表',
			'explore.characters' => '角色',
			'explore.addToWatchlist' => '添加到想看列表',
			'explore.removeFromWatchlist' => '从想看列表移除',
			'explore.addedToWatchlist' => '已加入待看列表',
			'explore.removedFromWatchlist' => '已从待看列表中移除',
			'explore.watchlistUpdateFailed' => '无法更新想看列表',
			'explore.watchlistNoMatch' => '无法将此项目与待看列表匹配',
			'explore.notInLibrary' => '不在你的媒体库中',
			'explore.inTheseLibraries' => '在这些媒体库中',
			'explore.checkingLibrary' => '正在检查你的媒体库…',
			'explore.emptyTitle' => '这里还什么都没有',
			'explore.emptyMessage' => ({required Object source}) => '当 ${source} 有内容时，相关内容将显示在这里。',
			'explore.searchHint' => ({required Object source}) => '搜索 ${source}',
			'explore.searchEmpty' => ({required Object query}) => '没有“${query}”的结果',
			'explore.searchPrompt' => ({required Object source}) => '在 ${source} 上搜索电影和剧集。',
			'explore.searchFailed' => '搜索失败。请检查网络连接后重试。',
			'explore.badge.rankPopular' => ({required Object n}) => '热门榜第 #${n} 名',
			'explore.badge.rankAiring' => ({required Object n}) => '在播榜第 #${n} 名',
			'explore.badge.rankRated' => ({required Object n}) => '评分榜第 #${n} 名',
			'explore.badge.rankTrending' => ({required Object n}) => '趋势榜第 #${n} 名',
			'explore.badge.rankSeasonal' => ({required Object season, required Object n}) => '${season}榜第 #${n} 名',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} 人正在观看',
			'explore.badge.available' => '可观看',
			'explore.badge.partiallyAvailable' => '部分可观看',
			'explore.badge.availableIn4k' => '提供 4K',
			'explore.badge.requested' => '已请求',
			'explore.badge.pendingApproval' => '待批准',
			'explore.badge.processing' => '处理中',
			'explore.badge.declined' => '已拒绝',
			'explore.badge.requestFailed' => '请求失败',
			'explore.badge.requested4k' => '已请求 4K',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '已有 ${available}/${total} 季',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => '第 ${episode} 集将在 ${duration} 后播出',
			'explore.badge.nextAiringIn' => ({required Object duration}) => '下一集将在 ${duration} 后播出',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} 集',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} 分钟/集',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} 人已标记',
			'explore.stats.viewersDay' => ({required Object n}) => '今日 ${n} 人观看',
			'explore.stats.viewersWeek' => ({required Object n}) => '本周 ${n} 人观看',
			'explore.stats.viewersMonth' => ({required Object n}) => '本月 ${n} 人观看',
			'explore.stats.viewersYear' => ({required Object n}) => '今年 ${n} 人观看',
			'explore.stats.viewersAllTime' => ({required Object n}) => '累计 ${n} 人观看',
			'explore.stats.planning' => ({required Object n}) => '${n} 人想看',
			'explore.stats.favorited' => ({required Object n}) => '${n} 人收藏',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} 弃番',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '${n} 条评论', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} 票',
			'explore.stats.watching' => ({required Object n}) => '${n} 人正在观看',
			'explore.stats.completed' => ({required Object n}) => '${n} 人已看完',
			'explore.stats.onHold' => ({required Object n}) => '${n} 人搁置',
			'explore.stats.dropped' => ({required Object n}) => '${n} 人弃番',
			'explore.season.winter' => '冬季',
			'explore.season.spring' => '春季',
			'explore.season.summer' => '夏季',
			'explore.season.fall' => '秋季',
			'explore.season.withYear' => ({required Object year, required Object season}) => '${year}年${season}',
			'explore.format.tv' => 'TV',
			'explore.format.tvShort' => 'TV 短片',
			'explore.format.movie' => '电影',
			'explore.format.special' => '特别篇',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => '音乐',
			'explore.format.other' => '其他',
			'explore.sourceMaterial.original' => '原创',
			'explore.sourceMaterial.manga' => '漫画',
			'explore.sourceMaterial.lightNovel' => '轻小说',
			'explore.sourceMaterial.novel' => '小说',
			'explore.sourceMaterial.visualNovel' => '视觉小说',
			'explore.sourceMaterial.game' => '游戏',
			'explore.sourceMaterial.webComic' => '网络漫画',
			'explore.sourceMaterial.musicRelease' => '音乐',
			'explore.sourceMaterial.otherMedia' => '其他',
			'explore.creditRole.director' => '导演',
			'explore.creditRole.writer' => '编剧',
			'explore.creditRole.producer' => '制片人',
			'explore.creditRole.creator' => '创作者',
			'explore.creditRole.composer' => '作曲',
			'explore.relation.prequel' => '前传',
			'explore.relation.sequel' => '续集',
			'explore.relation.sideStory' => '番外篇',
			'explore.relation.spinOff' => '衍生作品',
			'explore.relation.alternativeVersion' => '另一版本',
			'explore.relation.summary' => '总集篇',
			'explore.relation.parentStory' => '原作',
			'explore.relation.adaptation' => '改编',
			'explore.relation.other' => '相关',
			'explore.broadcast' => ({required Object day, required Object time}) => '每周${day} ${time}播出',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => '每周${day} ${time} ${timezone}播出',
			'explore.detail.originalTitle' => '原名',
			'explore.detail.alsoKnownAs' => '又名',
			'explore.detail.studios' => '制作公司',
			'explore.detail.country' => '国家/地区',
			'explore.detail.language' => '语言',
			'explore.detail.released' => '上映日期',
			'explore.detail.physicalRelease' => '光盘发售',
			'explore.detail.ended' => '完结日期',
			'explore.detail.addedOn' => ({required Object date}) => '添加于 ${date}',
			'explore.detail.yourRating' => '你的评分',
			'explore.detail.budget' => '预算',
			'explore.detail.revenue' => '票房',
			'explore.detail.contentAdvisory' => '年龄分级',
			'explore.detail.tags' => '标签',
			'explore.detail.revealSpoilerTags' => '显示剧透标签',
			'explore.detail.links' => '链接',
			'explore.detail.watchOn' => '观看平台',
			'explore.detail.watchTrailer' => '观看预告片',
			'explore.detail.openOn' => ({required Object site}) => '在 ${site} 打开',
			'explore.detail.crew' => '演职人员',
			'explore.detail.ratings' => '评分',
			'explore.detail.schedule' => '播出时间',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '由 ${n} 位用户推荐', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => '由 ${who} 推荐',
			'explore.detail.favoritedBy' => ({required Object who}) => '由 ${who} 收藏',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '还有 ${n} 集未播出',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => '${percent} 的观众推荐',
			'explore.detail.relatedTitles' => '相关作品',
			'explore.detail.background' => '背景',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '${n} 条结果', ), 
			'liveTv.title' => '直播电视',
			'liveTv.guide' => '节目指南',
			'liveTv.noChannels' => '没有可用的频道',
			'liveTv.noDvr' => '没有服务器配置 DVR',
			'liveTv.serverUnavailable' => '直播电视服务器不可用。',
			'liveTv.serverNotConnected' => '直播电视服务器未连接。',
			'liveTv.noPrograms' => '没有可用的节目数据',
			'liveTv.liveStreamFailed' => '直播流失败',
			'liveTv.unknownProgram' => '未知节目',
			'liveTv.unknownHub' => '未知',
			'liveTv.unknownError' => '未知错误',
			'liveTv.channelNumber' => ({required Object number}) => '频道 ${number}',
			'liveTv.unknownChannel' => '未知频道',
			'liveTv.live' => '直播',
			'liveTv.reloadGuide' => '重新加载节目指南',
			'liveTv.searchNoResults' => ({required Object query}) => 'No matches for "${query}"',
			'liveTv.now' => '现在',
			'liveTv.today' => '今天',
			'liveTv.tomorrow' => '明天',
			'liveTv.midnight' => '午夜',
			'liveTv.overnight' => '凌晨',
			'liveTv.morning' => '上午',
			'liveTv.daytime' => '白天',
			'liveTv.evening' => '晚上',
			'liveTv.lateNight' => '深夜',
			'liveTv.whatsOn' => '正在播出',
			'liveTv.watchChannel' => '观看频道',
			'liveTv.favorites' => '收藏',
			'liveTv.reorderFavorites' => '重新排序收藏',
			'liveTv.noFavoriteChannels' => '没有收藏的频道',
			'liveTv.noFavoriteChannelsHint' => '显示所有频道，然后长按某个频道将其加入收藏。',
			'liveTv.showAllChannels' => '显示所有频道',
			'liveTv.favoritesLoadFailed' => '无法加载收藏。请检查网络连接后重试。',
			'liveTv.favoritesUpdateFailed' => '无法更新收藏。请检查网络连接后重试。',
			'liveTv.joinSession' => '加入正在进行的会话',
			'liveTv.watchFromStart' => ({required Object minutes}) => '从头观看（${minutes}分钟前开始）',
			'liveTv.watchLive' => '观看直播',
			'liveTv.goToLive' => '跳至直播',
			'liveTv.record' => '录制',
			'liveTv.recordEpisode' => '录制单集',
			'liveTv.recordSeries' => '录制系列节目',
			'liveTv.recordOptions' => '录制选项',
			'liveTv.saveTo' => '保存到',
			'liveTv.recordings' => '录制内容',
			'liveTv.scheduledRecordings' => '计划录制',
			'liveTv.recordingRules' => '录制规则',
			'liveTv.noScheduledRecordings' => '没有安排的录制',
			'liveTv.manageRecording' => '管理录制',
			'liveTv.cancelRecording' => '取消录制',
			'liveTv.cancelRecordingTitle' => '取消此次录制？',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '将不再录制 ${title}。',
			'liveTv.deleteRule' => '删除规则',
			'liveTv.deleteRuleTitle' => '删除录制规则？',
			'liveTv.deleteRuleMessage' => ({required Object title}) => '今后将不再录制 ${title} 的剧集。',
			'liveTv.recordingScheduled' => '录制已安排',
			'liveTv.alreadyScheduled' => '此节目已安排录制',
			'liveTv.dvrAdminRequired' => 'DVR 设置需要管理员账户',
			'liveTv.recordingFailed' => '无法安排录制',
			'liveTv.recordingTargetMissing' => '无法确定录制库',
			'liveTv.recordNotAvailable' => '此节目无法录制',
			'liveTv.recordingCancelled' => '录制已取消',
			'liveTv.recordingRuleDeleted' => '录制规则已删除',
			'liveTv.processRecordingRules' => '重新评估规则',
			'liveTv.recordingInProgress' => '正在录制',
			'liveTv.recordingsCount' => ({required Object count}) => '已安排 ${count} 项录制',
			'liveTv.editRule' => '编辑规则',
			'liveTv.editRuleAction' => '编辑',
			'liveTv.recordingRuleUpdated' => '录制规则已更新',
			'liveTv.guideReloadRequested' => '已请求更新节目指南',
			'liveTv.rulesProcessRequested' => '已请求重新评估规则',
			'liveTv.recordShow' => '录制节目',
			'liveTv.recordSettings.startEarly' => '提前开始（秒）',
			'liveTv.recordSettings.endLate' => '延后结束（秒）',
			'liveTv.recordSettings.newOnly' => '仅新剧集',
			'liveTv.recordSettings.anyChannel' => '在任意频道录制',
			'liveTv.recordSettings.anyTime' => '在任意时间录制',
			'liveTv.recordSettings.skipInLibrary' => '跳过媒体库中已有的剧集',
			'liveTv.recordSettings.keepUpTo' => '保留的剧集数',
			'liveTv.recordSettings.keepUpToHint' => '0 表示保留全部剧集',
			'liveTv.startingInMinutes' => ({required Object minutes}) => '${minutes} 分钟后开始',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product} 返回了无效的直播电视播放数据',
			'liveTv.failedToStartChannel' => '无法播放直播频道',
			'liveTv.failedToBuildStreamUrl' => '无法生成视频流 URL',
			'collections.title' => '合集',
			'collections.collection' => '合集',
			'collections.empty' => '合集为空',
			'collections.deleteCollection' => '删除合集',
			'collections.deleteConfirm' => ({required Object title}) => '要删除“${title}”吗？此操作无法撤销。',
			'collections.deleted' => '已删除合集',
			'collections.deleteFailed' => '删除合集失败',
			'collections.deleteFailedWithError' => ({required Object error}) => '删除合集失败：${error}',
			'collections.selectCollection' => '选择合集',
			'collections.collectionName' => '合集名称',
			'collections.enterCollectionName' => '输入合集名称',
			'collections.addedToCollection' => '已添加到合集',
			'collections.errorAddingToCollection' => '添加到合集失败',
			'collections.created' => '已创建合集',
			'collections.removeFromCollection' => '从合集移除',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => '将“${title}”从此合集移除？',
			'collections.removedFromCollection' => '已从合集移除',
			'collections.removeFromCollectionFailed' => '从合集移除失败',
			'collections.removeFromCollectionError' => ({required Object error}) => '从合集移除时出错：${error}',
			'collections.searchCollections' => '搜索合集…',
			'playlists.title' => '播放列表',
			'playlists.playlist' => '播放列表',
			'playlists.noPlaylists' => '未找到播放列表',
			'playlists.create' => '创建播放列表',
			'playlists.playlistName' => '播放列表名称',
			'playlists.enterPlaylistName' => '输入播放列表名称',
			'playlists.delete' => '删除播放列表',
			'playlists.removeItem' => '从播放列表中移除',
			'playlists.smartPlaylist' => '智能播放列表',
			'playlists.itemCount' => ({required Object count}) => '${count} 个项目',
			'playlists.oneItem' => '1 个项目',
			'playlists.emptyPlaylist' => '此播放列表为空',
			'playlists.deleteConfirm' => '删除播放列表？',
			'playlists.deleteMessage' => ({required Object name}) => '确定要删除“${name}”吗？',
			'playlists.created' => '播放列表已创建',
			'playlists.deleted' => '播放列表已删除',
			'playlists.itemAdded' => '已添加到播放列表',
			'playlists.itemRemoved' => '已从播放列表中移除',
			'playlists.selectPlaylist' => '选择播放列表',
			'playlists.searchPlaylists' => '搜索播放列表…',
			'playlists.errorCreating' => '创建播放列表失败',
			'playlists.errorDeleting' => '删除播放列表失败',
			'playlists.errorLoading' => '加载播放列表失败',
			'playlists.errorAdding' => '添加到播放列表失败',
			'playlists.errorReordering' => '重新排序播放列表项目失败',
			'playlists.errorRemoving' => '从播放列表中移除失败',
			'music.goToAlbum' => '前往专辑',
			'music.goToArtist' => '前往艺术家',
			'music.instantMix' => '即时混合播放',
			'music.playNext' => '下一首播放',
			'music.addToQueue' => '添加到队列',
			'music.discNumber' => ({required Object n}) => '碟片 ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '${n} 首', ), 
			'music.nowPlaying' => '正在播放',
			'music.playingFrom' => ({required Object title}) => '播放来源：${title}',
			'music.queue' => '播放队列',
			'music.clearQueue' => '清空队列',
			'music.lyrics' => '歌词',
			'music.noLyrics' => '暂无歌词',
			'music.sleepTimer' => '睡眠定时器',
			'music.sleepTimerEndOfTrack' => '当前曲目结束时',
			'music.sleepTimerMinutes' => ({required Object n}) => '${n} 分钟',
			'music.stopPlayback' => '停止播放',
			'music.previousTrack' => '上一首',
			'music.nextTrack' => '下一首',
			'music.repeat' => '循环',
			'music.repeatAll' => '列表循环',
			'music.repeatOne' => '单曲循环',
			'music.instantMixNoServer' => '没有可用于即时混合的服务器',
			'music.noAudioUrl' => ({required Object track}) => '没有可供 ${track} 使用的音频 URL',
			'music.discography.singlesAndEps' => '单曲和 EP',
			'music.discography.live' => '现场',
			'music.discography.compilations' => '合集',
			'watchTogether.title' => '一起看',
			'watchTogether.description' => '与朋友和家人同步观看内容',
			'watchTogether.createSession' => '创建会话',
			'watchTogether.creating' => '正在创建…',
			'watchTogether.joinSession' => '加入会话',
			'watchTogether.joining' => '正在加入…',
			'watchTogether.controlMode' => '控制模式',
			'watchTogether.controlModeQuestion' => '谁可以控制播放？',
			'watchTogether.hostOnly' => '仅主持人',
			'watchTogether.anyone' => '任何人',
			'watchTogether.hostingSession' => '主持会话',
			'watchTogether.inSession' => '在会话中',
			'watchTogether.sessionCode' => '会话代码',
			'watchTogether.openSessionControls' => '打开“一起看”会话控制',
			'watchTogether.copySessionCode' => '复制会话代码',
			'watchTogether.hostControlsPlayback' => '主持人控制播放',
			'watchTogether.anyoneCanControl' => '任何人都可以控制播放',
			'watchTogether.hostControls' => '主持人控制',
			'watchTogether.anyoneControls' => '任何人控制',
			'watchTogether.participants' => '参与者',
			'watchTogether.host' => '主持人',
			'watchTogether.hostBadge' => '主持人',
			'watchTogether.youAreHost' => '你是主持人',
			'watchTogether.watchingWithOthers' => '与他人一起观看',
			'watchTogether.endSession' => '结束会话',
			'watchTogether.leaveSession' => '离开会话',
			'watchTogether.endSessionQuestion' => '结束会话？',
			'watchTogether.leaveSessionQuestion' => '离开会话？',
			'watchTogether.endSessionConfirm' => '这将为所有参与者结束会话。',
			'watchTogether.leaveSessionConfirm' => '你将被移出会话。',
			'watchTogether.endSessionConfirmOverlay' => '这将为所有参与者结束观看会话。',
			'watchTogether.leaveSessionConfirmOverlay' => '你将断开与观看会话的连接。',
			'watchTogether.end' => '结束',
			'watchTogether.leave' => '离开',
			'watchTogether.syncing' => '正在同步…',
			'watchTogether.joinWatchSession' => '加入观看会话',
			'watchTogether.enterCodeHint' => '输入 5 位代码',
			'watchTogether.pasteFromClipboard' => '从剪贴板粘贴',
			'watchTogether.pleaseEnterCode' => '请输入会话代码',
			'watchTogether.codeMustBe5Chars' => '会话代码必须是 5 个字符',
			'watchTogether.joinInstructions' => '输入主持人的会话代码以加入。',
			'watchTogether.failedToCreate' => '创建会话失败',
			'watchTogether.failedToJoin' => '加入会话失败',
			'watchTogether.sessionCodeCopied' => '会话代码已复制到剪贴板',
			'watchTogether.relayUnreachable' => '无法访问中继服务器。网络运营商的屏蔽可能导致“一起看”不可用。',
			'watchTogether.reconnectingToHost' => '正在重新连接到主持人…',
			'watchTogether.currentPlayback' => '当前播放',
			'watchTogether.joinCurrentPlayback' => '加入当前播放',
			'watchTogether.joinCurrentPlaybackDescription' => '加入主持人当前正在观看的内容',
			'watchTogether.failedToOpenCurrentPlayback' => '无法打开当前播放',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} 已加入',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} 已离开',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} 暂停了播放',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} 恢复了播放',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} 更改了播放位置',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} 正在缓冲',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name} 正在使用较旧版本的应用，无法同步',
			'watchTogether.resumingWithout' => ({required Object name}) => '不再等待 ${name}，继续播放',
			'watchTogether.waitingForParticipants' => '正在等待其他人加载…',
			'watchTogether.waitingForName' => ({required Object name}) => '正在等待 ${name}…',
			'watchTogether.recentRooms' => '最近的房间',
			'watchTogether.renameRoom' => '重命名房间',
			'watchTogether.removeRoom' => '移除',
			'watchTogether.guestSwitchUnavailable' => '无法切换 — 服务器不可用于同步',
			'watchTogether.guestSwitchFailed' => '无法切换 — 在此服务器上未找到内容',
			'watchTogether.defaultDisplayName' => '用户',
			'watchTogether.errors.timedOut' => '中继服务器未及时响应',
			'watchTogether.errors.connectionLost' => '会话准备就绪前连接已断开',
			'watchTogether.errors.invalidRelayResponse' => '中继服务器返回了意外的响应',
			'watchTogether.errors.sessionEnded' => '主持人已结束会话',
			'downloads.title' => '下载',
			'downloads.manage' => '管理',
			'downloads.tvShows' => '电视剧',
			'downloads.movies' => '电影',
			'downloads.music' => '音乐',
			'downloads.tracksQueued' => ({required Object count}) => '${count} 首曲目已加入下载队列',
			'downloads.noDownloads' => '暂无下载',
			'downloads.noDownloadsDescription' => '下载的内容将在此处显示以供离线观看',
			'downloads.downloadNow' => '下载',
			'downloads.deleteDownload' => '删除下载',
			'downloads.retryDownload' => '重试下载',
			'downloads.downloadQueued' => '下载已排队',
			'downloads.downloadResumed' => '下载已继续',
			'downloads.serverErrorBitrate' => '服务器错误：文件可能超过远程比特率限制',
			'downloads.storageFull' => '设备存储空间已满，因此下载已停止。请释放空间后重试。',
			'downloads.episodesQueued' => ({required Object count}) => '${count} 集已加入下载队列',
			'downloads.downloadDeleted' => '下载已删除',
			'downloads.deleteConfirm' => ({required Object title}) => '要从此设备删除“${title}”吗？',
			'downloads.cancelledDownloadTitle' => '已取消的下载',
			'downloads.cancelledDownloadMessage' => '此下载已取消。你想怎么做？',
			'downloads.allEpisodesAlreadyDownloaded' => '所有剧集均已下载',
			'downloads.resumeDownload' => '继续下载',
			'downloads.cancelledDownload' => '已取消的下载',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file}（正在同步 ${status}）',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => '已下载 ${file} — 点击以完成',
			'downloads.partialDownloadClickToComplete' => '已部分下载 — 点击以完成',
			'downloads.deleting' => '正在删除…',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => '正在删除 ${title}…（${current}/${total}）',
			'downloads.queuedTooltip' => '已排队',
			'downloads.queuedFilesTooltip' => ({required Object files}) => '已排队：${files}',
			'downloads.downloadingTooltip' => '正在下载…',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => '正在下载 ${files}',
			'downloads.noDownloadsTree' => '暂无下载',
			'downloads.pauseAll' => '全部暂停',
			'downloads.resumeAll' => '全部继续',
			'downloads.deleteAll' => '全部删除',
			'downloads.selectVersion' => '选择版本',
			'downloads.allEpisodes' => '所有剧集',
			'downloads.unwatchedOnly' => '仅未观看',
			'downloads.nextNUnwatched' => ({required Object count}) => '接下来 ${count} 集未观看',
			'downloads.customAmount' => '自定义数量…',
			'downloads.includeSpecials' => '包含特别篇',
			'downloads.howManyEpisodes' => '下载几集？',
			'downloads.invalidEpisodeCount' => '请输入有效的集数。',
			'downloads.keepSynced' => '保持同步',
			'downloads.downloadOnce' => '下载一次',
			'downloads.keepNUnwatched' => ({required Object count}) => '保留 ${count} 集未观看内容',
			'downloads.editSyncRule' => '编辑同步规则',
			'downloads.removeSyncRule' => '删除同步规则',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => '停止同步“${title}”？已下载的剧集将被保留。',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => '停止同步“${title}”？',
			'downloads.deleteSyncRuleDownloads' => '同时删除相关下载',
			'downloads.deleteSyncRuleDownloadsDescription' => '被其他同步规则或个人资料使用的下载将保留。',
			'downloads.syncRuleCreated' => ({required Object count}) => '同步规则已创建 — 保留 ${count} 集未观看内容',
			'downloads.syncRuleUpdated' => '同步规则已更新',
			'downloads.syncRuleRemoved' => '同步规则已删除',
			'downloads.syncRuleAndDownloadsRemoved' => '同步规则及相关下载已删除',
			'downloads.syncRuleCleanupBusy' => '同步规则正在更新中，请稍后再试。',
			'downloads.syncRuleCleanupUnavailable' => '无法安全识别相关下载。请重新连接服务器后再试，或在不删除下载的情况下移除规则。',
			'downloads.syncedNewEpisodes' => ({required Object title, required Object count}) => '已为 ${title} 同步 ${count} 个新剧集',
			'downloads.activeSyncRules' => '同步规则',
			'downloads.noSyncRules' => '没有同步规则',
			'downloads.manageSyncRule' => '管理同步',
			'downloads.editEpisodeCount' => '剧集数量',
			'downloads.editSyncFilter' => '同步筛选',
			'downloads.syncAllItems' => '同步所有项目',
			'downloads.syncUnwatchedItems' => '同步未观看项目',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => '服务器：${server} • ${status}',
			'downloads.syncRuleAvailable' => '可用',
			'downloads.syncRuleOffline' => '离线',
			'downloads.syncRuleSignInRequired' => '需要登录',
			'downloads.syncRuleNotAvailableForProfile' => '当前用户资料不可用',
			'downloads.syncRuleUnknownServer' => '未知服务器',
			'downloads.syncRuleListCreated' => '同步规则已创建',
			'downloads.backgroundWarning.bannerBlocked' => '离开应用后，下载将停止',
			'downloads.backgroundWarning.bannerDegraded' => '后台下载可能受限',
			'downloads.backgroundWarning.bannerAction' => '详情',
			'downloads.backgroundWarning.sheetTitle' => '后台下载已被阻止',
			'downloads.backgroundWarning.sheetTitleDegraded' => '后台下载可能受限',
			'downloads.backgroundWarning.sheetIntro' => 'Android 正在阻止 Plezy 在后台稳定下载。',
			'downloads.backgroundWarning.sheetIntroDegraded' => '你的设备限制了 Plezy 在后台下载的时机。',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'Plezy 的后台使用受到限制。请将其电池用量或后台使用设置为“不受限制”。',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android 已将 Plezy 置于受限待机状态。请将其电池用量设为“不受限制”。',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => '下载通知已关闭，因此可能无法查看进度或进行控制。',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => '通知已关闭。在 Android 13 或更高版本中，长时间后台下载需要开启通知。',
			'downloads.backgroundWarning.reasonDataSaver' => '流量节省程序已开启，会阻止使用移动数据进行后台下载。使用 Wi-Fi 时下载应仍可进行。',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Plezy 在后台时，下载曾多次停止。请检查 Plezy 的电池用量或后台使用设置。',
			'downloads.backgroundWarning.openSettings' => '打开设置',
			'downloads.backgroundWarning.stillNotWorking' => '设备专属帮助',
			'downloads.backgroundWarning.stillNotWorkingDescription' => '查看适用于你设备的操作步骤；如果问题仍然存在，请通过设置 › 查看日志发送日志。',
			'downloads.backgroundWarning.dialogTitle' => '下载可能无法完成',
			'downloads.backgroundWarning.dialogDownloadAnyway' => '仍要下载',
			'downloads.backgroundWarning.dialogFixFirst' => '先解决此问题',
			'downloads.backgroundWarning.statusTile' => '后台下载',
			'downloads.backgroundWarning.statusOk' => '允许在后台运行',
			'downloads.backgroundWarning.statusBlocked' => '已被系统设置阻止',
			'downloads.backgroundWarning.statusDegraded' => '受系统设置限制',
			'downloads.backgroundWarning.statusUnknown' => '尚未检查',
			'downloads.backgroundWarning.settingsUnavailable' => '无法在此设备上打开系统设置',
			'downloads.backgroundWarning.linkUnavailable' => '无法在此设备上打开 dontkillmyapp.com',
			'downloads.unknownShow' => '未知节目',
			'downloads.unknownSeason' => '未知季',
			'downloads.unknownAlbum' => '未知专辑',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '已完成 ${completed}/${total}',
			'downloads.errorFileNotFound' => '未找到文件（404）',
			'downloads.errorDownloadFailed' => '下载失败',
			'downloads.errorPostProcessing' => ({required Object error}) => '后处理失败：${error}',
			'downloads.notificationDownloading' => '正在下载…',
			'downloads.notificationComplete' => '下载完成',
			'downloads.notificationPaused' => '下载已暂停',
			'shaders.title' => '着色器',
			'shaders.noShaderDescription' => '无视频增强',
			'shaders.nvscalerDescription' => 'NVIDIA 图像缩放，使视频更清晰',
			'shaders.artcnnVariantNeutral' => '中性',
			'shaders.artcnnVariantDenoise' => '降噪',
			'shaders.artcnnVariantDenoiseSharpen' => '降噪 + 锐化',
			'shaders.qualityFast' => '快速',
			'shaders.qualityHQ' => '高质量',
			'shaders.mode' => '模式',
			'shaders.importShader' => '导入着色器',
			'shaders.customShaderDescription' => '自定义 GLSL 着色器',
			'shaders.shaderImported' => '着色器已导入',
			'shaders.shaderImportFailed' => '导入着色器失败',
			'shaders.deleteShader' => '删除着色器',
			'shaders.deleteShaderConfirm' => ({required Object name}) => '删除“${name}”？',
			'companionRemote.title' => '遥控器',
			'companionRemote.connectedTo' => ({required Object name}) => '已连接到 ${name}',
			'companionRemote.unknownDevice' => '未知设备',
			'companionRemote.session.startingServer' => '正在启动远程服务器…',
			'companionRemote.session.hostAddress' => '主机地址',
			'companionRemote.session.connected' => '已连接',
			'companionRemote.session.serverRunning' => '远程服务器已启动',
			'companionRemote.session.serverStopped' => '远程服务器已停止',
			'companionRemote.session.serverRunningDescription' => '网络上的移动设备可以连接到此应用',
			'companionRemote.session.serverStoppedDescription' => '启动服务器以允许移动设备连接',
			'companionRemote.session.usePhoneToControl' => '使用移动设备控制此应用',
			'companionRemote.session.startServer' => '启动服务器',
			'companionRemote.session.stopServer' => '停止服务器',
			'companionRemote.session.minimize' => '最小化',
			'companionRemote.session.manualAddressHint' => '手动连接地址：',
			'companionRemote.pairing.discoveryDescription' => '使用同一 Plex 账号的 Plezy 设备会显示在这里',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => '正在连接…',
			'companionRemote.pairing.searchingForDevices' => '正在搜索设备…',
			'companionRemote.pairing.noDevicesFound' => '未在网络中找到设备',
			'companionRemote.pairing.noDevicesHint' => '请在桌面端打开 Plezy，并确保设备连接到同一 Wi-Fi 网络',
			'companionRemote.pairing.availableDevices' => '可用设备',
			'companionRemote.pairing.manualConnection' => '手动连接',
			_ => null,
		} ?? switch (path) {
			'companionRemote.pairing.cryptoInitFailed' => '无法启动安全连接。请先登录 Plex。',
			'companionRemote.pairing.validationHostRequired' => '请输入主机地址',
			'companionRemote.pairing.validationHostFormat' => '格式必须为 IP:端口（例如 192.168.1.100:48632）',
			'companionRemote.pairing.connectionTimedOut' => '连接超时。请在两台设备上使用同一网络。',
			'companionRemote.pairing.sessionNotFound' => '未找到设备。请确认 Plezy 正在主机上运行。',
			'companionRemote.pairing.authFailed' => '认证失败。两台设备需要使用同一 Plex 账号。',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => '连接失败：${error}',
			'companionRemote.remote.disconnectConfirm' => '确定要断开遥控会话吗？',
			'companionRemote.remote.reconnecting' => '正在重新连接…',
			'companionRemote.remote.attemptOf' => ({required Object current}) => '第 ${current} 次尝试，共 5 次',
			'companionRemote.remote.retryNow' => '立即重试',
			'companionRemote.remote.tabRemote' => '遥控器',
			'companionRemote.remote.tabPlay' => '播放',
			'companionRemote.remote.tabMore' => '更多',
			'companionRemote.remote.menu' => '菜单',
			'companionRemote.remote.tabNavigation' => '导航',
			'companionRemote.remote.tabDiscover' => '发现',
			'companionRemote.remote.tabLibraries' => '媒体库',
			'companionRemote.remote.tabSearch' => '搜索',
			'companionRemote.remote.tabDownloads' => '下载',
			'companionRemote.remote.tabSettings' => '设置',
			'companionRemote.remote.previous' => '上一个',
			'companionRemote.remote.playPause' => '播放/暂停',
			'companionRemote.remote.next' => '下一个',
			'companionRemote.remote.seekBack' => '快退',
			'companionRemote.remote.stop' => '停止',
			'companionRemote.remote.seekForward' => '快进',
			'companionRemote.remote.volume' => '音量',
			'companionRemote.remote.volumeDown' => '降低音量',
			'companionRemote.remote.volumeUp' => '提高音量',
			'companionRemote.remote.fullscreen' => '全屏',
			'companionRemote.remote.subtitles' => '字幕',
			'companionRemote.remote.audio' => '音频',
			'companionRemote.remote.searchHint' => '在桌面端搜索…',
			'companionRemote.errors.noNetworkInterface' => '未找到网络接口',
			'companionRemote.errors.authenticationFailed' => '身份验证失败',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => '无法启动远程服务器：${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => '无法发送远程命令：${error}',
			'companionRemote.errors.joinTimedOut' => '加入会话超时',
			'companionRemote.errors.failedToConnectAnyAddress' => '无法连接到任何地址',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => '${attempts} 次尝试后连接丢失',
			'companionRemote.errors.connectionLost' => '连接丢失',
			'companionRemote.closedBeforeAuth' => '连接在身份验证前已关闭',
			'videoSettings.playbackSpeed' => '播放速度',
			'videoSettings.normalSpeed' => '正常',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => '运行中（${duration}）',
			'videoSettings.zoom' => '缩放',
			'videoSettings.sleepTimer' => '睡眠定时器',
			'videoSettings.audioSync' => '音频同步',
			'videoSettings.subtitleSync' => '字幕同步',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => '此处不支持 HDR——当前桌面合成器或视频输出无法传输 HDR。',
			'videoSettings.hdrToneMapping' => 'HDR 色调映射',
			'videoSettings.hdrToneMappingCompositor' => '合成器',
			'videoSettings.hdrToneMappingCompositorDescription' => '直接传递源的 HDR 元数据，并由桌面合成器进行映射。',
			'videoSettings.hdrToneMappingPlayer' => '播放器',
			'videoSettings.hdrToneMappingPlayerDescription' => '在播放器中映射到显示器的峰值亮度，然后将结果告知合成器。',
			'videoSettings.hdrToneMappingFailed' => '无法更改 HDR 色调映射——仍在使用之前的模式。',
			'videoSettings.audioOutput' => '音频输出',
			'videoSettings.performanceOverlay' => '性能监控',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => '环绕声',
			'videoSettings.audioOutputSpatial' => '空间音频',
			'videoSettings.audioOutputStereo' => '立体声',
			'videoSettings.audioNormalization' => '响度标准化',
			'videoSettings.audioDownmix' => '下混为立体声',
			'performanceOverlay.color' => '颜色',
			'performanceOverlay.performance' => '性能',
			'performanceOverlay.buffer' => '缓冲',
			'performanceOverlay.app' => '应用',
			'performanceOverlay.decoder' => '解码器',
			'performanceOverlay.rawDecoder' => '原始解码器',
			'performanceOverlay.tunneling' => '隧道',
			'performanceOverlay.passthrough' => '直通',
			'performanceOverlay.aspect' => '宽高比',
			'performanceOverlay.rotation' => '旋转',
			'performanceOverlay.dvSource' => 'DV 来源',
			'performanceOverlay.dvPath' => 'DV 路径',
			'performanceOverlay.p7Conversion' => 'P7 转换',
			'performanceOverlay.sampleRate' => '采样率',
			'performanceOverlay.pixelFormat' => '像素格式',
			'performanceOverlay.hwFormat' => '硬件格式',
			'performanceOverlay.matrix' => '矩阵',
			'performanceOverlay.primaries' => '基色',
			'performanceOverlay.transfer' => '传递特性',
			'performanceOverlay.renderFps' => '渲染 FPS',
			'performanceOverlay.displayFps' => '显示 FPS',
			'performanceOverlay.avSync' => 'A/V 同步',
			'performanceOverlay.dropped' => '丢帧',
			'performanceOverlay.dvRpus' => 'DV RPU',
			'performanceOverlay.dvRpuAverage' => 'DV RPU 平均',
			'performanceOverlay.dvSampleAverage' => 'DV 采样平均',
			'performanceOverlay.maxLuma' => '最大亮度',
			'performanceOverlay.minLuma' => '最小亮度',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => '已用缓存',
			'performanceOverlay.cacheLimit' => '缓存限制',
			'performanceOverlay.speed' => '速度',
			'performanceOverlay.player' => '播放器',
			'performanceOverlay.memory' => '内存',
			'performanceOverlay.uiFps' => 'UI FPS',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android 硬件',
			'performanceOverlay.decoderNvidiaHw' => 'NVIDIA 硬件',
			'performanceOverlay.decoderQualcommHw' => 'Qualcomm 硬件',
			'performanceOverlay.decoderMediatekHw' => 'MediaTek 硬件',
			'performanceOverlay.decoderExynosHw' => 'Exynos 硬件',
			'performanceOverlay.decoderSoftware' => '软件',
			'performanceOverlay.decoderHardware' => '硬件',
			'performanceOverlay.tunnelingActive' => '已启用',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted}（${failures} 个失败）',
			'externalPlayer.title' => '外部播放器',
			'externalPlayer.useExternalPlayer' => '使用外部播放器',
			'externalPlayer.useExternalPlayerDescription' => '在其他应用中打开视频',
			'externalPlayer.selectPlayer' => '选择播放器',
			'externalPlayer.customPlayers' => '自定义播放器',
			'externalPlayer.systemDefault' => '系统默认',
			'externalPlayer.addCustomPlayer' => '添加自定义播放器',
			'externalPlayer.playerName' => '播放器名称',
			'externalPlayer.playerNameHint' => '我的播放器',
			'externalPlayer.playerCommand' => '命令',
			'externalPlayer.playerPackage' => '包名',
			'externalPlayer.playerUrlScheme' => 'URL 方案',
			'externalPlayer.off' => '关闭',
			'externalPlayer.launchFailed' => '无法打开外部播放器',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} 未安装',
			'externalPlayer.playInExternalPlayer' => '在外部播放器中播放',
			'metadataEdit.editMetadata' => '编辑…',
			'metadataEdit.screenTitle' => '编辑元数据',
			'metadataEdit.basicInfo' => '基本信息',
			'metadataEdit.artwork' => '封面图片',
			'metadataEdit.advancedSettings' => '高级设置',
			'metadataEdit.title' => '标题',
			'metadataEdit.sortTitle' => '排序标题',
			'metadataEdit.originalTitle' => '原始标题',
			'metadataEdit.releaseDate' => '上映日期',
			'metadataEdit.contentRating' => '内容分级',
			'metadataEdit.studio' => '制片厂',
			'metadataEdit.tagline' => '标语',
			'metadataEdit.summary' => '简介',
			'metadataEdit.poster' => '海报',
			'metadataEdit.background' => '背景',
			'metadataEdit.logo' => '标志',
			'metadataEdit.squareArt' => '方形图片',
			'metadataEdit.selectPoster' => '选择海报',
			'metadataEdit.selectBackground' => '选择背景',
			'metadataEdit.selectLogo' => '选择标志',
			'metadataEdit.selectSquareArt' => '选择方形图片',
			'metadataEdit.fromUrl' => '通过 URL',
			'metadataEdit.uploadFile' => '上传文件',
			'metadataEdit.enterImageUrl' => '输入图片 URL',
			'metadataEdit.imageUrl' => '图片 URL',
			'metadataEdit.metadataUpdated' => '元数据已更新',
			'metadataEdit.metadataUpdateFailed' => '元数据更新失败',
			'metadataEdit.artworkUpdated' => '封面图片已更新',
			'metadataEdit.artworkUpdateFailed' => '封面图片更新失败',
			'metadataEdit.noArtworkAvailable' => '没有可用的封面图片',
			'metadataEdit.artworkOption' => ({required Object index}) => '封面图片选项 ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => '封面图片选项 ${index}，已选择',
			'metadataEdit.notSet' => '未设置',
			'metadataEdit.libraryDefault' => '媒体库默认',
			'metadataEdit.accountDefault' => '账户默认',
			'metadataEdit.seriesDefault' => '剧集默认',
			'metadataEdit.episodeSorting' => '剧集排序',
			'metadataEdit.oldestFirst' => '最旧优先',
			'metadataEdit.newestFirst' => '最新优先',
			'metadataEdit.keep' => '保留',
			'metadataEdit.allEpisodes' => '所有剧集',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '最新 ${count} 集',
			'metadataEdit.latestEpisode' => '最新一集',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => '过去 ${count} 天内添加的剧集',
			'metadataEdit.deleteAfterPlaying' => '播放后删除剧集',
			'metadataEdit.never' => '从不',
			'metadataEdit.afterADay' => '一天后',
			'metadataEdit.afterAWeek' => '一周后',
			'metadataEdit.afterAMonth' => '一个月后',
			'metadataEdit.onNextRefresh' => '下次刷新时',
			'metadataEdit.seasons' => '季',
			'metadataEdit.show' => '显示',
			'metadataEdit.hide' => '隐藏',
			'metadataEdit.episodeOrdering' => '剧集排列顺序',
			'metadataEdit.tmdbAiring' => 'The Movie Database（播出顺序）',
			'metadataEdit.tvdbAiring' => 'TheTVDB（播出顺序）',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB（绝对顺序）',
			'metadataEdit.metadataLanguage' => '元数据语言',
			'metadataEdit.useOriginalTitle' => '使用原始标题',
			'metadataEdit.preferredAudioLanguage' => '首选音频语言',
			'metadataEdit.preferredSubtitleLanguage' => '首选字幕语言',
			'metadataEdit.subtitleMode' => '自动选择字幕模式',
			'metadataEdit.manuallySelected' => '手动选择',
			'metadataEdit.shownWithForeignAudio' => '外语音频时显示',
			'metadataEdit.alwaysEnabled' => '始终启用',
			'metadataEdit.tags' => '标签',
			'metadataEdit.addTag' => '添加标签',
			'metadataEdit.genre' => '类型',
			'metadataEdit.director' => '导演',
			'metadataEdit.writer' => '编剧',
			'metadataEdit.producer' => '制片人',
			'metadataEdit.country' => '国家',
			'metadataEdit.collection' => '合集',
			'metadataEdit.label' => '标记',
			'matchScreen.match' => '匹配…',
			'matchScreen.fixMatch' => '修正匹配…',
			'matchScreen.unmatch' => '取消匹配',
			'matchScreen.unmatchConfirm' => '清除此匹配？在重新匹配前，Plex 会将其视为未匹配。',
			'matchScreen.unmatchSuccess' => '已取消匹配',
			'matchScreen.unmatchFailed' => '无法取消匹配',
			'matchScreen.matchApplied' => '匹配已应用',
			'matchScreen.matchFailed' => '应用匹配失败',
			'matchScreen.titleHint' => '标题',
			'matchScreen.yearHint' => '年份',
			'matchScreen.search' => '搜索',
			'matchScreen.noMatchesFound' => '未找到匹配项',
			'serverTasks.title' => '服务器任务',
			'serverTasks.failedToLoad' => '加载任务失败',
			'serverTasks.noTasks' => '没有正在运行的任务',
			'trakt.title' => 'Trakt',
			'trakt.connected' => '已连接',
			'trakt.connectedAs' => ({required Object username}) => '已以 @${username} 身份连接',
			'trakt.disconnectConfirm' => '断开 Trakt 账户？',
			'trakt.disconnectConfirmBody' => 'Plezy 将停止向 Trakt 发送事件。你可随时重新连接。',
			'trakt.scrobble' => '实时同步播放状态',
			'trakt.scrobbleDescription' => '播放期间将播放、暂停和停止事件发送到 Trakt。',
			'trakt.watchedSync' => '同步已观看状态',
			'trakt.watchedSyncDescription' => '在 Plezy 中将内容标记为已观看时，也会在 Trakt 上标记为已观看。',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => '连接 Seerr',
			'seerr.serverUrl' => '服务器 URL',
			'seerr.serverUrlHelper' => '你的 Seerr 实例的地址',
			'seerr.checkServer' => '继续',
			'seerr.signInWithJellyfin' => '使用 Jellyfin 登录',
			'seerr.signInWithEmby' => '使用 Emby 登录',
			'seerr.signInWithLocal' => '使用本地账户',
			'seerr.email' => '邮箱',
			'seerr.noSignInMethods' => '此 Seerr 实例未提供 Plezy 支持的登录方式。',
			'seerr.instance' => '实例',
			'seerr.disconnectConfirm' => '断开 Seerr 连接？',
			'seerr.disconnectConfirmBody' => 'Plezy 将忘记此 Seerr 实例。可随时重新连接。',
			'seerr.request' => '请求',
			'seerr.request4k' => '请求 4K',
			'seerr.seasons' => '季',
			'seerr.allSeasons' => '全部季',
			'seerr.advancedOptions' => '高级',
			'seerr.destinationServer' => '目标服务器',
			'seerr.qualityProfile' => '画质配置',
			'seerr.rootFolder' => '根目录',
			'seerr.languageProfile' => '语言配置',
			'seerr.requestSubmitted' => '请求已提交',
			'seerr.requestFailed' => ({required Object error}) => '请求失败：${error}',
			'seerr.requestsLoadFailed' => '无法加载请求选项',
			'seerr.nothingToRequest' => '所有内容都已可用或已请求。',
			'seerr.statusAvailable' => '可用',
			'seerr.statusPartiallyAvailable' => '部分可用',
			'seerr.statusRequested' => '已请求',
			'seerr.statusProcessing' => '处理中',
			'seerr.statusBlocklisted' => '已加入屏蔽列表',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => '无法连接到 ${url}：${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => '${url} 上没有 Seerr 实例（HTTP ${status}）',
			'seerr.notInitialized' => '此 Seerr 实例尚未完成首次运行设置',
			'seerr.noPlexTokenForReauth' => '没有可用于重新登录的 Plex 令牌',
			'seerr.noStoredCredentials' => '没有已保存的凭据可用于重新登录',
			'seerr.signInRejected' => '登录被拒绝',
			'seerr.noSessionCookie' => 'Seerr 未签发会话 Cookie',
			'seerr.freshCookieRejected' => 'Seerr 拒绝了新的会话 Cookie',
			'seerr.noUserInformation' => 'Seerr 未返回用户信息',
			'seerr.sessionRejectedAfterReauth' => '重新登录后会话被拒绝',
			'services.title' => '服务',
			'services.hubSubtitle' => '同步观看进度并请求新内容。',
			'services.notConnected' => '未连接',
			'services.connectedAs' => ({required Object username}) => '已以 @${username} 身份连接',
			'services.scrobble' => '自动记录进度',
			'services.scrobbleDescription' => '观看完一集或一部电影后更新你的列表。',
			'services.disconnectConfirm' => ({required Object service}) => '断开 ${service} 连接？',
			'services.disconnectConfirmBody' => ({required Object service}) => 'Plezy 将停止更新 ${service}。可随时重新连接。',
			'services.connectFailed' => ({required Object service}) => '无法连接到 ${service}。请重试。',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.deviceCode.title' => ({required Object service}) => '在 ${service} 上激活 Plezy',
			'services.deviceCode.instructions' => '扫描二维码，或访问下方地址并输入此代码：',
			'services.deviceCode.openToActivate' => ({required Object service}) => '打开 ${service} 以激活',
			'services.deviceCode.copyCode' => '复制激活代码',
			'services.deviceCode.waitingForAuthorization' => '等待授权…',
			'services.deviceCode.codeCopied' => '代码已复制',
			'services.oauthProxy.title' => ({required Object service}) => '登录 ${service}',
			'services.oauthProxy.body' => '扫描此二维码，或在任意设备上打开 URL。',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => '打开 ${service} 以登录',
			'services.pendingAuth.copyUrl' => '复制登录 URL',
			'services.pendingAuth.urlCopied' => 'URL 已复制',
			'services.libraryFilter.title' => '媒体库筛选',
			'services.libraryFilter.subtitleAllSyncing' => '同步所有媒体库',
			'services.libraryFilter.subtitleNoneSyncing' => '不同步任何内容',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '已屏蔽 ${count} 个',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '已允许 ${count} 个',
			'services.libraryFilter.mode' => '筛选模式',
			'services.libraryFilter.modeBlacklist' => '黑名单',
			'services.libraryFilter.modeWhitelist' => '白名单',
			'services.libraryFilter.modeHintBlacklist' => '同步下方未勾选的所有媒体库。',
			'services.libraryFilter.modeHintWhitelist' => '仅同步下方勾选的媒体库。',
			'services.libraryFilter.libraries' => '媒体库',
			'services.libraryFilter.noLibraries' => '没有可用的媒体库',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => '添加 ${product} 服务器',
			'addServer.serverUrls' => '服务器 URL',
			'addServer.serverUrlsHelper' => '可输入多个 URL，并用逗号分隔。',
			'addServer.findServer' => '查找服务器',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => '正在查找本地 ${product} 服务器…',
			'addServer.localMediaBrowserServers' => ({required Object product}) => '本地 ${product} 服务器',
			'addServer.username' => '用户名',
			'addServer.password' => '密码',
			'addServer.signIn' => '登录',
			'addServer.change' => '更改',
			'addServer.required' => '必填',
			'addServer.couldNotReachServer' => ({required Object error}) => '无法连接到服务器：${error}',
			'addServer.signInFailed' => ({required Object error}) => '登录失败：${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect 失败：${error}',
			'addServer.addPlexTitle' => '使用 Plex 登录',
			'addServer.pinExpired' => 'PIN 在登录前已过期。请重试。',
			'addServer.failedToRegisterAccount' => ({required Object error}) => '注册账户失败：${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => '请输入你的 ${product} 服务器 URL',
			'addServer.addConnectionTitle' => '添加连接',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => '添加到 ${name}',
			'addServer.signInWithPlexCard' => '使用 Plex 登录',
			'addServer.signInWithPlexCardSubtitle' => '授权此设备。共享服务器会被添加。',
			'addServer.signInWithPlexCardSubtitleScoped' => '授权一个 Plex 账户。Plex Home 用户将成为 Plezy 用户资料。',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => '连接到 ${product}',
			'addServer.connectToMediaBrowserCardSubtitle' => '输入你的服务器 URL、用户名和密码。',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => '登录你的 ${product} 服务器。将绑定到 ${name}。',
			'addServer.borrowFromAnotherProfile' => '使用其他用户资料的连接',
			'addServer.borrowFromAnotherProfileSubtitle' => '复用另一个用户资料的连接。受 PIN 保护的用户资料需要输入 PIN。',
			'addServer.invalidCredentials' => '用户名或密码无效',
			'addServer.authResponseNotJson' => '身份验证响应不是有效的 JSON',
			'addServer.authResponseIncomplete' => '服务器返回的登录响应不完整',
			'addServer.quickConnectRejected' => '服务器拒绝了 Quick Connect',
			'addServer.quickConnectNotJson' => 'Quick Connect 响应不是有效的 JSON',
			'addServer.quickConnectMissingFields' => 'Quick Connect 响应中缺少代码或密钥',
			'addServer.quickConnectPollRejected' => '服务器拒绝了 Quick Connect 轮询',
			'addServer.serverTimedOut' => '服务器未及时响应',
			'addServer.responseNotJson' => '服务器响应不是有效的 JSON',
			'addServer.responseMissingIdentity' => ({required Object product}) => '响应中缺少 ID 或服务器名称——这是 ${product} 服务器吗？',
			'addServer.probeFailed' => ({required Object error}) => '无法连接到服务器：${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => '请输入至少一个 ${product} 服务器 URL',
			'addServer.noReachableServer' => ({required Object product}) => '未找到可连接的 ${product} 服务器',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => '这些 URL 指向不同的 ${product} 服务器',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => '此 URL 与 ${product} 服务器不匹配',
			'addServer.redirectUnsupported' => '服务器重定向到了不受支持的 URL',
			'addServer.redirectDifferentHost' => ({required Object product}) => '服务器重定向到了其他主机。请直接输入最终的 ${product} URL。',
			'addServer.redirectInsecure' => '服务器从 HTTPS 重定向到了不安全的 URL',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => '服务器重定向到了不受支持的 URL。请直接输入最终的 ${product} URL。',
			_ => null,
		};
	}
}
