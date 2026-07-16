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
	@override late final _TranslationsAppZh app = _TranslationsAppZh._(_root);
	@override late final _TranslationsAuthZh auth = _TranslationsAuthZh._(_root);
	@override late final _TranslationsCommonZh common = _TranslationsCommonZh._(_root);
	@override late final _TranslationsScreensZh screens = _TranslationsScreensZh._(_root);
	@override late final _TranslationsUpdateZh update = _TranslationsUpdateZh._(_root);
	@override late final _TranslationsSettingsZh settings = _TranslationsSettingsZh._(_root);
	@override late final _TranslationsSearchZh search = _TranslationsSearchZh._(_root);
	@override late final _TranslationsHotkeysZh hotkeys = _TranslationsHotkeysZh._(_root);
	@override late final _TranslationsFileInfoZh fileInfo = _TranslationsFileInfoZh._(_root);
	@override late final _TranslationsMediaMenuZh mediaMenu = _TranslationsMediaMenuZh._(_root);
	@override late final _TranslationsRateSheetZh rateSheet = _TranslationsRateSheetZh._(_root);
	@override late final _TranslationsAccessibilityZh accessibility = _TranslationsAccessibilityZh._(_root);
	@override late final _TranslationsTooltipsZh tooltips = _TranslationsTooltipsZh._(_root);
	@override late final _TranslationsVideoControlsZh videoControls = _TranslationsVideoControlsZh._(_root);
	@override late final _TranslationsMessagesZh messages = _TranslationsMessagesZh._(_root);
	@override late final _TranslationsSubtitlingStylingZh subtitlingStyling = _TranslationsSubtitlingStylingZh._(_root);
	@override late final _TranslationsMpvConfigZh mpvConfig = _TranslationsMpvConfigZh._(_root);
	@override late final _TranslationsDialogZh dialog = _TranslationsDialogZh._(_root);
	@override late final _TranslationsProfilesZh profiles = _TranslationsProfilesZh._(_root);
	@override late final _TranslationsConnectionsZh connections = _TranslationsConnectionsZh._(_root);
	@override late final _TranslationsDiscoverZh discover = _TranslationsDiscoverZh._(_root);
	@override late final _TranslationsErrorsZh errors = _TranslationsErrorsZh._(_root);
	@override late final _TranslationsLibrariesZh libraries = _TranslationsLibrariesZh._(_root);
	@override late final _TranslationsAboutZh about = _TranslationsAboutZh._(_root);
	@override late final _TranslationsServerSelectionZh serverSelection = _TranslationsServerSelectionZh._(_root);
	@override late final _TranslationsHubDetailZh hubDetail = _TranslationsHubDetailZh._(_root);
	@override late final _TranslationsLogsZh logs = _TranslationsLogsZh._(_root);
	@override late final _TranslationsLicensesZh licenses = _TranslationsLicensesZh._(_root);
	@override late final _TranslationsNavigationZh navigation = _TranslationsNavigationZh._(_root);
	@override late final _TranslationsExploreZh explore = _TranslationsExploreZh._(_root);
	@override late final _TranslationsLiveTvZh liveTv = _TranslationsLiveTvZh._(_root);
	@override late final _TranslationsCollectionsZh collections = _TranslationsCollectionsZh._(_root);
	@override late final _TranslationsPlaylistsZh playlists = _TranslationsPlaylistsZh._(_root);
	@override late final _TranslationsMusicZh music = _TranslationsMusicZh._(_root);
	@override late final _TranslationsWatchTogetherZh watchTogether = _TranslationsWatchTogetherZh._(_root);
	@override late final _TranslationsDownloadsZh downloads = _TranslationsDownloadsZh._(_root);
	@override late final _TranslationsShadersZh shaders = _TranslationsShadersZh._(_root);
	@override late final _TranslationsCompanionRemoteZh companionRemote = _TranslationsCompanionRemoteZh._(_root);
	@override late final _TranslationsVideoSettingsZh videoSettings = _TranslationsVideoSettingsZh._(_root);
	@override late final _TranslationsPerformanceOverlayZh performanceOverlay = _TranslationsPerformanceOverlayZh._(_root);
	@override late final _TranslationsExternalPlayerZh externalPlayer = _TranslationsExternalPlayerZh._(_root);
	@override late final _TranslationsMetadataEditZh metadataEdit = _TranslationsMetadataEditZh._(_root);
	@override late final _TranslationsMatchScreenZh matchScreen = _TranslationsMatchScreenZh._(_root);
	@override late final _TranslationsServerTasksZh serverTasks = _TranslationsServerTasksZh._(_root);
	@override late final _TranslationsTraktZh trakt = _TranslationsTraktZh._(_root);
	@override late final _TranslationsSeerrZh seerr = _TranslationsSeerrZh._(_root);
	@override late final _TranslationsServicesZh services = _TranslationsServicesZh._(_root);
	@override late final _TranslationsAddServerZh addServer = _TranslationsAddServerZh._(_root);
}

// Path: app
class _TranslationsAppZh extends TranslationsAppEn {
	_TranslationsAppZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _TranslationsAuthZh extends TranslationsAuthEn {
	_TranslationsAuthZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => '使用 Plex 登录';
	@override String get showQRCode => '显示二维码';
	@override String get authenticate => '验证';
	@override String get authenticationTimeout => '验证超时。请重试。';
	@override String get scanQRToSignIn => '扫描二维码登录';
	@override String get waitingForAuth => '正在等待认证...\n请在浏览器中登录。';
	@override String get useBrowser => '使用浏览器';
	@override String get or => '或';
	@override String get connectToJellyfin => '连接到 Jellyfin';
	@override String get useQuickConnect => '使用 Quick Connect';
	@override String get quickConnectInstructions => '在 Jellyfin 中打开 Quick Connect 并输入此代码。';
	@override String get quickConnectWaiting => '等待批准…';
	@override String get quickConnectCancel => '取消';
	@override String get quickConnectExpired => 'Quick Connect 已过期。请重试。';
}

// Path: common
class _TranslationsCommonZh extends TranslationsCommonEn {
	_TranslationsCommonZh._(TranslationsZh root) : this._root = root, super.internal(root);

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
	@override String get logout => '登出';
	@override String get unknown => '未知';
	@override String get refresh => '刷新';
	@override String get yes => '是';
	@override String get no => '否';
	@override String get delete => '删除';
	@override String get edit => '编辑';
	@override String get shuffle => '随机播放';
	@override String get addTo => '添加到...';
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
	@override String episodeNumberTitle({required Object number, required Object title}) => '第${number}集 - ${title}';
	@override String chapterNumber({required Object number}) => '章节 ${number}';
	@override String get reconnect => '重新连接';
	@override String get viewAll => '查看全部';
	@override String get checkingNetwork => '正在检查网络...';
	@override String get loadingServers => '正在加载服务器...';
	@override String get connectingToServers => '正在连接服务器...';
	@override String get startingOfflineMode => '正在启动离线模式...';
	@override String get loading => '加载中...';
	@override String get fullscreen => '全屏';
	@override String get exitFullscreen => '退出全屏';
	@override String get pressBackAgainToExit => '再按一次返回退出';
}

// Path: screens
class _TranslationsScreensZh extends TranslationsScreensEn {
	_TranslationsScreensZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get licenses => '许可证';
	@override String get switchProfile => '切换用户';
	@override String get subtitleStyling => '字幕样式';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => '日志';
}

// Path: update
class _TranslationsUpdateZh extends TranslationsUpdateEn {
	_TranslationsUpdateZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get available => '有可用更新';
	@override String versionAvailable({required Object version}) => '版本 ${version} 已发布';
	@override String currentVersion({required Object version}) => '当前版本: ${version}';
	@override String get skipVersion => '跳过此版本';
	@override String get viewRelease => '查看发布详情';
	@override String get latestVersion => '已安装的版本是可用的最新版本';
	@override String get checkFailed => '无法检查更新';
}

// Path: settings
class _TranslationsSettingsZh extends TranslationsSettingsEn {
	_TranslationsSettingsZh._(TranslationsZh root) : this._root = root, super.internal(root);

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
	@override String durationHint({required Object min, required Object max}) => '输入时长 (${min}-${max})';
	@override String get systemTheme => '系统';
	@override String get lightTheme => '浅色';
	@override String get darkTheme => '深色';
	@override String get oledTheme => 'OLED';
	@override String get libraryDensity => '媒体库密度';
	@override String get compact => '紧凑';
	@override String get comfortable => '舒适';
	@override String get viewMode => '视图模式';
	@override String get gridView => '网格视图';
	@override String get listView => '列表视图';
	@override String get showHeroSection => '显示主要精选区';
	@override String get continueWatchingAction => '继续观看操作';
	@override String get continueWatchingPlay => '播放';
	@override String get continueWatchingDetails => '打开详情';
	@override String get episodeAction => '剧集操作';
	@override String get episodePlay => '播放';
	@override String get episodeDetails => '打开详情';
	@override String get useGlobalHubs => '使用主页布局';
	@override String get useGlobalHubsDescription => '显示统一主页中心。否则使用资料库推荐。';
	@override String get showServerNameOnHubs => '在推荐栏显示服务器名称';
	@override String get showServerNameOnHubsDescription => '始终在中心标题中显示服务器名称。';
	@override String get groupLibrariesByServer => '按服务器分组媒体库';
	@override String get groupLibrariesByServerDescription => '按媒体服务器分组侧边栏资料库。';
	@override String get alwaysKeepSidebarOpen => '始终保持侧边栏展开';
	@override String get alwaysKeepSidebarOpenDescription => '侧边栏保持展开状态，内容区域自动调整';
	@override String get showUnwatchedCount => '显示未观看数量';
	@override String get showUnwatchedCountDescription => '在剧集和季上显示未观看的集数';
	@override String get showEpisodeNumberOnCards => '在卡片上显示集数';
	@override String get showEpisodeNumberOnCardsDescription => '在剧集卡片上显示季和集编号';
	@override String get showSeasonPostersOnTabs => '在选项卡上显示季海报';
	@override String get showSeasonPostersOnTabsDescription => '在每季标签上方显示该季海报';
	@override String get tvFullCardLayout => '完整 TV 卡片';
	@override String get tvFullCardLayoutDescription => '使用仅显示图片的 TV 卡片，并叠加演员姓名';
	@override String get focusGlow => '焦点光晕';
	@override String get focusGlowDescription => '在获得焦点的卡片周围显示柔和的光晕';
	@override String get visualEffects => '视觉效果';
	@override String get visualEffectsAuto => '自动';
	@override String get visualEffectsAutoDescription => '在性能较低的设备上自动减少效果';
	@override String get visualEffectsFull => '完整';
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
	@override String get defaultQualityTitle => '默认画质';
	@override String get musicQualityTitle => '音乐质量';
	@override String get subtitleStyling => '字幕样式';
	@override String get subtitleStylingDescription => '调整字幕外观';
	@override String get smallSkipDuration => '短跳过时长';
	@override String get largeSkipDuration => '长跳过时长';
	@override String get rewindOnResume => '恢复时回退';
	@override String secondsUnit({required Object seconds}) => '${seconds} 秒';
	@override String get defaultSleepTimer => '默认睡眠定时器';
	@override String minutesUnit({required Object minutes}) => '${minutes} 分钟';
	@override String get rememberTrackSelections => '记住每个剧集/电影的音轨选择';
	@override String get rememberTrackSelectionsDescription => '记住每个标题的音频和字幕选择';
	@override String get showChapterMarkersOnTimeline => '在进度条上显示章节标记';
	@override String get showChapterMarkersOnTimelineDescription => '按章节边界分段显示进度条';
	@override String get clickVideoTogglesPlayback => '点击视频可切换播放/暂停';
	@override String get clickVideoTogglesPlaybackDescription => '点击视频进行播放/暂停，而不是显示控制项。';
	@override String get videoPlayerControls => '视频播放器控制';
	@override String get keyboardShortcuts => '键盘快捷键';
	@override String get keyboardShortcutsDescription => '自定义键盘快捷键';
	@override String get videoPlayerNavigation => '视频播放器导航';
	@override String get videoPlayerNavigationDescription => '使用方向键导航视频播放器控件';
	@override String get watchTogetherRelay => '一起看中继服务器';
	@override String get watchTogetherRelayDescription => '设置自定义中继。所有人必须使用同一服务器。';
	@override String get watchTogetherRelayHint => 'https://my-relay.example.com';
	@override String get crashReporting => '崩溃报告';
	@override String get crashReportingDescription => '发送崩溃报告以帮助改进应用';
	@override String get debugLogging => '调试日志';
	@override String get debugLoggingDescription => '启用详细日志记录以便故障排除';
	@override String get viewLogs => '查看日志';
	@override String get viewLogsDescription => '查看应用程序日志';
	@override String get clearCache => '清除缓存';
	@override String get clearCacheDescription => '清除缓存的图片和数据。内容加载可能变慢。';
	@override String get clearCacheSuccess => '缓存清除成功';
	@override String get resetSettings => '重置设置';
	@override String get resetSettingsDescription => '恢复默认设置。此操作无法撤销。';
	@override String get resetSettingsSuccess => '设置重置成功';
	@override String get backup => '备份';
	@override String get exportSettings => '导出设置';
	@override String get exportSettingsDescription => '将您的偏好保存到文件';
	@override String get exportSettingsSuccess => '设置已导出';
	@override String get exportSettingsFailed => '无法导出设置';
	@override String get importSettings => '导入设置';
	@override String get importSettingsDescription => '从文件恢复偏好';
	@override String get importSettingsConfirm => '这将替换您当前的设置。继续吗？';
	@override String get importSettingsSuccess => '设置已导入';
	@override String get importSettingsFailed => '无法导入设置';
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
	@override String get validationErrorEnterNumber => '请输入一个有效的数字';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => '时长必须介于 ${min} 和 ${max} ${unit} 之间';
	@override String shortcutAlreadyAssigned({required Object action}) => '快捷键已被分配给 ${action}';
	@override String shortcutUpdated({required Object action}) => '快捷键已为 ${action} 更新';
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
	@override String currentPath({required Object path}) => '当前: ${path}';
	@override String get downloadLocationChanged => '下载位置已更改';
	@override String get downloadLocationReset => '下载位置已重置为默认';
	@override String get downloadLocationInvalid => '所选文件夹不可写入';
	@override String get downloadLocationSelectError => '选择文件夹失败';
	@override String get downloadOnWifiOnly => '仅在 WiFi 时下载';
	@override String get downloadOnWifiOnlyDescription => '使用蜂窝数据时禁止下载';
	@override String get autoRemoveWatchedDownloads => '自动移除已观看的下载';
	@override String get autoRemoveWatchedDownloadsDescription => '自动删除已观看的下载';
	@override String get cellularDownloadBlocked => '蜂窝网络下已阻止下载。请使用 WiFi 或更改设置。';
	@override String get maxVolume => '最大音量';
	@override String get maxVolumeDescription => '允许音量超过 100% 以适应安静的媒体';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord 动态状态';
	@override String get discordRichPresenceDescription => '在 Discord 上显示您正在观看的内容';
	@override String get services => '服务';
	@override String get servicesDescription => '连接 Trakt、MyAnimeList、Seerr 等';
	@override String get manageLibrariesDescription => '重新排序和隐藏媒体库';
	@override String get companionRemoteServer => '配套遥控服务器';
	@override String get companionRemoteServerDescription => '允许网络上的移动设备控制此应用';
	@override String get autoPip => '自动画中画';
	@override String get autoPipDescription => '播放时离开会进入画中画';
	@override String get matchContentFrameRate => '匹配内容帧率';
	@override String get matchContentFrameRateDescription => '将显示刷新率匹配到视频内容';
	@override String get matchRefreshRate => '匹配刷新率';
	@override String get matchRefreshRateDescription => '全屏时匹配显示刷新率';
	@override String get matchDynamicRange => '匹配动态范围';
	@override String get matchDynamicRangeDescription => 'HDR 内容切换到 HDR，随后切回 SDR';
	@override String get displaySwitchDelay => '显示切换延迟';
	@override String get tunneledPlayback => '通道化播放';
	@override String get tunneledPlaybackDescription => '使用视频隧道。若 HDR 播放出现黑屏，请禁用。';
	@override String get audioPassthrough => '音频直通';
	@override String get audioPassthroughDescription => '将 Dolby/DTS 音频不经重新编码直接发送到功放或电视，保留环绕声。如果没有声音，请关闭。';
	@override String get audioPassthroughDescriptionAppleTv => '将 Dolby Digital Plus（含 Atmos）以比特流方式交给系统输出。DTS 和 TrueHD 仍以多声道 PCM 播放。快进快退时可能出现短暂声音中断。';
	@override String get audioDownmix => '下混为立体声';
	@override String get audioDownmixDescription => '将环绕声混合为双声道，适用于立体声音箱或耳机';
	@override String get downmixCenterBoost => '中置声道增强';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => '增强 (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => '下混时音量标准化';
	@override String get audioDownmixNormalizeDescription => '降低混音电平以防止削波。关闭可保持原始音量（大音量场景可能失真）。';
	@override String get atmosDiagnostics => 'Atmos 输出测试';
	@override String get atmosDiagnosticsDescription => '通过系统播放器播放测试信号，诊断 Dolby Atmos 输出';
	@override String get atmosTestHlsAtmos => 'Apple Atmos 流';
	@override String get atmosTestHlsAtmosDescription => '已知正常的 Dolby Atmos 流。功放应显示 Dolby Atmos。';
	@override String get atmosTestHlsControl => 'Apple 环绕声流';
	@override String get atmosTestHlsControlDescription => '不含 Atmos 的对照流。功放应显示不带 Atmos 的环绕声。';
	@override String get atmosTestRawStream => '原始 EAC3 流';
	@override String get atmosTestRawStreamDescription => '以与播放器内 Atmos 播放完全相同的方式串流测试文件。需要测试文件 URL。';
	@override String get atmosTestRawFile => '原始 EAC3 文件';
	@override String get atmosTestRawFileDescription => '以已知长度播放测试文件。需要测试文件 URL。';
	@override String get atmosTestStop => '停止测试';
	@override String get atmosTestUrl => '测试文件 URL';
	@override String get atmosTestUrlDescription => '原始 .ec3 Dolby Atmos 文件的 HTTP URL（例如用 ffmpeg 提取）';
	@override String get atmosTestUrlMissing => '请先设置测试文件 URL';
	@override String get atmosTestStatus => '状态';
	@override String get dvConversionMode => 'Dolby Vision 转换';
	@override String get dvConversionModeDescription => '选择 ExoPlayer 如何处理 Dolby Vision Profile 7 文件。';
	@override String get dvConversionAuto => '自动';
	@override String get dvConversionNative => '原生 / 禁用';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => '使用设备能力检测和正常回退行为';
	@override String get dvConversionNativeDescription => '强制原生 DV7 并抑制 DV 转换重试';
	@override String get dvConversionDv81Description => '强制内联 RPU 转换为 Dolby Vision Profile 8.1';
	@override String get dvConversionHevcStripDescription => '移除 Dolby Vision RPU/EL 层并呈现普通 HEVC';
	@override String get requireProfileSelectionOnOpen => '打开应用时询问配置文件';
	@override String get requireProfileSelectionOnOpenDescription => '每次打开应用时显示配置文件选择';
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
}

// Path: search
class _TranslationsSearchZh extends TranslationsSearchEn {
	_TranslationsSearchZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get hint => '搜索电影、系列、音乐...';
	@override String get tryDifferentTerm => '尝试不同的搜索词';
	@override String get searchYourMedia => '搜索媒体';
	@override String get enterTitleActorOrKeyword => '输入标题、演员或关键词';
}

// Path: hotkeys
class _TranslationsHotkeysZh extends TranslationsHotkeysEn {
	_TranslationsHotkeysZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => '为 ${actionName} 设置快捷键';
	@override String get clearShortcut => '清除快捷键';
	@override String get noShortcutSet => '未设置快捷键';
	@override String get currentShortcut => '当前快捷键:';
	@override String get pressToRecord => '选择以录制快捷键';
	@override String get recordingShortcut => '现在请按下快捷键';
	@override late final _TranslationsHotkeysActionsZh actions = _TranslationsHotkeysActionsZh._(_root);
}

// Path: fileInfo
class _TranslationsFileInfoZh extends TranslationsFileInfoEn {
	_TranslationsFileInfoZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '文件信息';
	@override String get video => '视频';
	@override String get audio => '音频';
	@override String get file => '文件';
	@override String get advanced => '高级';
	@override String get codec => '编解码器';
	@override String get resolution => '分辨率';
	@override String get bitrate => '比特率';
	@override String get frameRate => '帧率';
	@override String get aspectRatio => '宽高比';
	@override String get profile => '配置文件';
	@override String get bitDepth => '位深度';
	@override String get colorSpace => '色彩空间';
	@override String get colorRange => '色彩范围';
	@override String get colorPrimaries => '颜色原色';
	@override String get chromaSubsampling => '色度子采样';
	@override String get channels => '声道';
	@override String get subtitles => '字幕';
	@override String get overallBitrate => '总比特率';
	@override String get path => '路径';
	@override String get size => '大小';
	@override String get container => '容器';
	@override String get duration => '时长';
	@override String get optimizedForStreaming => '已优化用于流媒体';
	@override String get has64bitOffsets => '64位偏移量';
}

// Path: mediaMenu
class _TranslationsMediaMenuZh extends TranslationsMediaMenuEn {
	_TranslationsMediaMenuZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => '标记为已观看';
	@override String get markAsUnwatched => '标记为未观看';
	@override String get removeFromContinueWatching => '从继续观看中移除';
	@override String get viewDetails => '查看详情';
	@override String get goToSeries => '转到系列';
	@override String get shufflePlay => '随机播放';
	@override String get shuffleNotAvailableOffline => '离线时无法随机播放';
	@override String get fileInfo => '文件信息';
	@override String get deleteFromServer => '从服务器删除';
	@override String get confirmDelete => '要从服务器删除此媒体及其文件吗？';
	@override String get deleteMultipleWarning => '这包括所有剧集及其文件。';
	@override String get mediaDeletedSuccessfully => '媒体项已成功删除';
	@override String get mediaFailedToDelete => '删除媒体项失败';
	@override String get rate => '评分';
	@override String get playFromBeginning => '从头播放';
	@override String get playVersion => '播放版本...';
}

// Path: rateSheet
class _TranslationsRateSheetZh extends TranslationsRateSheetEn {
	_TranslationsRateSheetZh._(TranslationsZh root) : this._root = root, super.internal(root);

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
class _TranslationsAccessibilityZh extends TranslationsAccessibilityEn {
	_TranslationsAccessibilityZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, 电影';
	@override String mediaCardShow({required Object title}) => '${title}, 电视剧';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => '已观看';
	@override String mediaCardPartiallyWatched({required Object percent}) => '已观看 ${percent} 百分比';
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
}

// Path: tooltips
class _TranslationsTooltipsZh extends TranslationsTooltipsEn {
	_TranslationsTooltipsZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => '随机播放';
	@override String get playTrailer => '播放预告片';
	@override String get markAsWatched => '标记为已观看';
	@override String get markAsUnwatched => '标记为未观看';
}

// Path: videoControls
class _TranslationsVideoControlsZh extends TranslationsVideoControlsEn {
	_TranslationsVideoControlsZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => '音频';
	@override String get subtitlesLabel => '字幕';
	@override String get resetToZero => '重置为 0ms';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} 播放较晚';
	@override String playsEarlier({required Object label}) => '${label} 播放较早';
	@override String get noOffset => '无偏移';
	@override String get letterbox => '信箱模式（Letterbox）';
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
	@override String pausingIn({required Object seconds}) => '${seconds}秒后暂停';
	@override String get continueWatching => '继续';
	@override String get autoPlayNext => '自动播放下一集';
	@override String get playNext => '播放下一集';
	@override String get playButton => '播放';
	@override String get pauseButton => '暂停';
	@override String seekBackwardButton({required Object seconds}) => '后退 ${seconds} 秒';
	@override String seekForwardButton({required Object seconds}) => '前进 ${seconds} 秒';
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
	@override String get pipButton => '画中画模式';
	@override String get aspectRatioButton => '宽高比';
	@override String get ambientLighting => '氛围灯光';
	@override String get fullscreenButton => '进入全屏';
	@override String get exitFullscreenButton => '退出全屏';
	@override String get alwaysOnTopButton => '置顶窗口';
	@override String get rotationLockButton => '旋转锁定';
	@override String get lockScreen => '锁定屏幕';
	@override String get screenLockButton => '屏幕锁定';
	@override String get longPressToUnlock => '长按解锁';
	@override String get timelineSlider => '视频时间轴';
	@override String get volumeSlider => '音量调节';
	@override String endsAt({required Object time}) => '${time} 结束';
	@override String get pipActive => '正在画中画模式中播放';
	@override String get pipFailed => '画中画启动失败';
	@override String get screenshotSaved => '截图已保存';
	@override String zoomPercent({required Object percent}) => '缩放 ${percent}%';
	@override late final _TranslationsVideoControlsPipErrorsZh pipErrors = _TranslationsVideoControlsPipErrorsZh._(_root);
	@override String get chapters => '章节';
	@override String get noChaptersAvailable => '没有可用的章节';
	@override String get queue => '播放队列';
	@override String get noQueueItems => '队列中没有项目';
	@override String get searchSubtitles => '搜索字幕';
	@override String get language => '语言';
	@override String get noSubtitlesFound => '未找到字幕';
	@override String get downloadedSubtitle => '已下载';
	@override String get noSubtitlesAvailable => '没有可用字幕';
	@override String get noAudioTracksAvailable => '没有可用音轨';
	@override String get noTracksAvailable => '没有可用轨道';
	@override String get subtitleDownloaded => '字幕已下载';
	@override String get subtitleDownloadFailed => '字幕下载失败';
	@override String get searchLanguages => '搜索语言...';
}

// Path: messages
class _TranslationsMessagesZh extends TranslationsMessagesEn {
	_TranslationsMessagesZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => '已标记为已观看';
	@override String get markedAsUnwatched => '已标记为未观看';
	@override String get markedAsWatchedOffline => '已标记为已观看 (将在联网时同步)';
	@override String get markedAsUnwatchedOffline => '已标记为未观看 (将在联网时同步)';
	@override String autoRemovedWatchedDownload({required Object title}) => '已自动移除: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		other: '已自动移除 ${n} 个看过的下载',
	);
	@override String get removedFromContinueWatching => '已从继续观看中移除';
	@override String errorLoading({required Object error}) => '错误: ${error}';
	@override String get streamInterrupted => '视频流已中断。按播放键或拖动进度条重试。';
	@override String get liveStreamInterrupted => '直播流已中断。按播放键重试。';
	@override String get fileInfoNotAvailable => '文件信息不可用';
	@override String errorLoadingFileInfo({required Object error}) => '加载文件信息时出错: ${error}';
	@override String get errorLoadingSeries => '加载系列时出错';
	@override String get musicNotSupported => '尚不支持播放音乐';
	@override String get noDescriptionAvailable => '暂无描述';
	@override String get noProfilesAvailable => '没有可用的用户';
	@override String get contactAdminForProfiles => '请联系服务器管理员添加用户配置';
	@override String get unableToDetermineLibrarySection => '无法确定此项目的库分区';
	@override String get logsCleared => '日志已清除';
	@override String get logsCopied => '日志已复制到剪贴板';
	@override String get noLogsAvailable => '没有可用日志';
	@override String libraryScanning({required Object title}) => '正在扫描 “${title}”...';
	@override String libraryScanStarted({required Object title}) => '已开始扫描 “${title}” 媒体库';
	@override String libraryScanFailed({required Object error}) => '无法扫描媒体库: ${error}';
	@override String metadataRefreshing({required Object title}) => '正在刷新 “${title}” 的元数据...';
	@override String metadataRefreshStarted({required Object title}) => '已开始刷新 “${title}” 的元数据';
	@override String metadataRefreshFailed({required Object error}) => '无法刷新元数据: ${error}';
	@override String get logoutConfirm => '你确定要登出吗？';
	@override String get noSeasonsFound => '未找到季';
	@override String get seasonsLoadFailed => '无法加载季';
	@override String get noEpisodesFound => '在第一季中未找到剧集';
	@override String get noEpisodesFoundGeneral => '未找到剧集';
	@override String get episodesLoadFailed => '无法加载剧集';
	@override String get noResultsFound => '未找到结果';
	@override String sleepTimerSet({required Object label}) => '睡眠定时器已设置为 ${label}';
	@override String get noItemsAvailable => '没有可用的项目';
	@override String get failedToCreatePlayQueueNoItems => '创建播放队列失败 - 没有项目';
	@override String failedPlayback({required Object action, required Object error}) => '无法${action}: ${error}';
	@override String get switchingToCompatiblePlayer => '正在切换到兼容的播放器...';
	@override String get serverLimitTitle => '播放失败';
	@override String get serverLimitBody => '服务器错误 (HTTP 500)。带宽/转码限制可能拒绝了此会话。请让所有者调整。';
	@override String get logsUploaded => '日志已上传';
	@override String get logsUploadFailed => '上传日志失败';
	@override String get logId => '日志 ID';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingZh extends TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingZh._(TranslationsZh root) : this._root = root, super.internal(root);

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
	@override String get bold => '粗体';
	@override String get italic => '斜体';
	@override String get renderResolution => '渲染分辨率';
	@override String get renderResolutionScreen => '屏幕分辨率';
	@override String get renderResolutionVideo => '视频分辨率';
}

// Path: mpvConfig
class _TranslationsMpvConfigZh extends TranslationsMpvConfigEn {
	_TranslationsMpvConfigZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv 配置';
	@override String get description => '高级视频播放器设置';
	@override String get presets => '预设';
	@override String get noPresets => '没有保存的预设';
	@override String get saveAsPreset => '保存为预设...';
	@override String get presetName => '预设名称';
	@override String get presetNameHint => '输入此预设的名称';
	@override String get loadPreset => '加载';
	@override String get deletePreset => '删除';
	@override String get presetSaved => '预设已保存';
	@override String get presetLoaded => '预设已加载';
	@override String get presetDeleted => '预设已删除';
	@override String get confirmDeletePreset => '确定要删除此预设吗？';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comment';
}

// Path: dialog
class _TranslationsDialogZh extends TranslationsDialogEn {
	_TranslationsDialogZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => '确认操作';
}

// Path: profiles
class _TranslationsProfilesZh extends TranslationsProfilesEn {
	_TranslationsProfilesZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => '添加 Plezy 配置文件';
	@override String get switchingProfile => '切换配置文件中…';
	@override String get deleteThisProfileTitle => '删除此配置文件？';
	@override String deleteThisProfileMessage({required Object displayName}) => '移除 ${displayName}。连接不会受影响。';
	@override String get active => '活跃';
	@override String get manage => '管理';
	@override String get delete => '删除';
	@override String get signOut => '退出登录';
	@override String get signOutPlexTitle => '退出 Plex 登录？';
	@override String signOutPlexMessage({required Object displayName}) => '要移除 ${displayName} 和所有 Plex Home 用户吗？可随时重新登录。';
	@override String get signedOutPlex => '已退出 Plex 登录。';
	@override String get signOutFailed => '退出登录失败。';
	@override String get sectionTitle => '配置文件';
	@override String get summarySingle => '添加配置文件以混合托管用户和本地身份';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} 个配置文件 · 活跃：${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} 个配置文件';
	@override String get removeConnectionTitle => '移除连接？';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => '移除 ${displayName} 对 ${connectionLabel} 的访问。其他个人资料仍保留。';
	@override String get deleteProfileTitle => '删除配置文件？';
	@override String deleteProfileMessage({required Object displayName}) => '移除 ${displayName} 及其连接。服务器仍可用。';
	@override String get profileNameLabel => '配置文件名称';
	@override String get pinProtectionLabel => 'PIN 保护';
	@override String get pinManagedByPlex => 'PIN 由 Plex 管理。在 plex.tv 上编辑。';
	@override String get noPinSetEditOnPlex => '未设置 PIN。如需要求 PIN，请在 plex.tv 上编辑 Home 用户。';
	@override String get setPin => '设置 PIN';
	@override String get setPinTitle => '设置 PIN';
	@override String get confirmPinTitle => '确认 PIN';
	@override String get pinSet => '已设置 PIN';
	@override String get changePin => '更改';
	@override String get removePin => '移除';
	@override String get connectionsLabel => '连接';
	@override String get add => '添加';
	@override String get deleteProfileButton => '删除配置文件';
	@override String get noConnectionsHint => '没有连接 — 添加一个以使用此配置文件。';
	@override String get noConnections => '没有连接';
	@override String get plexHomeAccount => 'Plex Home 账户';
	@override String get connectionDefault => '默认';
	@override String connectionAs({required Object displayName}) => '以 ${displayName} 身份';
	@override String get makeDefault => '设为默认';
	@override String get removeConnection => '移除';
	@override String get profileRenamed => '个人资料已重命名。';
	@override String borrowAddTo({required Object displayName}) => '添加到 ${displayName}';
	@override String get borrowExplain => '借用另一个个人资料的连接。受 PIN 保护的个人资料需要 PIN。';
	@override String get borrowEmpty => '暂无可借用的内容。';
	@override String get borrowEmptySubtitle => '请先将 Plex 或 Jellyfin 连接到另一个个人资料。';
	@override String borrowFromProfile({required Object displayName}) => '来自 ${displayName}';
	@override String get borrowConnectionBorrowed => '已借用连接。';
	@override String get borrowFailed => '无法借用连接。';
	@override String get incorrectPin => 'PIN 不正确。';
	@override String get incorrectPinTryAgain => 'PIN 不正确。请重试。';
	@override String get sourceProfileMissingParentAccount => '源个人资料缺少其父账号。';
	@override String get failedToLoadHomeUsers => '无法加载您的 Plex Home 用户。请检查网络连接后重试。';
	@override String get failedToVerifyPin => '无法验证 PIN。';
	@override String get newProfile => '新建配置文件';
	@override String get profileNameHint => '例如：访客、儿童、家庭房';
	@override String get pinProtectionOptional => 'PIN 保护（可选）';
	@override String get pinExplain => '切换个人资料需要 4 位 PIN。';
	@override String get continueButton => '继续';
	@override String get pinsDontMatch => 'PIN 不匹配';
}

// Path: connections
class _TranslationsConnectionsZh extends TranslationsConnectionsEn {
	_TranslationsConnectionsZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '连接';
	@override String get addConnection => '添加连接';
	@override String get addConnectionSubtitleNoProfile => '使用 Plex 登录或连接 Jellyfin 服务器';
	@override String addConnectionSubtitleScoped({required Object displayName}) => '添加到 ${displayName}: Plex、Jellyfin 或其他个人资料连接';
	@override String sessionExpiredOne({required Object name}) => '${name} 的会话已过期';
	@override String sessionExpiredMany({required Object count}) => '${count} 个服务器的会话已过期';
	@override String get signInAgain => '重新登录';
	@override String get editJellyfinTitle => '编辑 Jellyfin 连接';
	@override String editJellyfinIntro({required Object serverName}) => '添加或移除 ${serverName} 的 URL。Plezy 会使用可访问且延迟最低的 URL。';
}

// Path: discover
class _TranslationsDiscoverZh extends TranslationsDiscoverEn {
	_TranslationsDiscoverZh._(TranslationsZh root) : this._root = root, super.internal(root);

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
	@override String get movie => '电影';
	@override String get tvShow => '电视剧';
	@override String minutesLeft({required Object minutes}) => '剩余 ${minutes} 分钟';
	@override String get moreLikeThis => '更多类似内容';
}

// Path: errors
class _TranslationsErrorsZh extends TranslationsErrorsEn {
	_TranslationsErrorsZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => '搜索失败: ${error}';
	@override String connectionTimeout({required Object context}) => '加载 ${context} 时连接超时';
	@override String get connectionFailed => '无法连接到媒体服务器';
	@override String unableToLoad({required Object context}) => '无法加载${context}。请重试。';
	@override String get noClientAvailable => '没有可用客户端';
	@override String get pleaseEnterToken => '请输入一个令牌';
	@override String get invalidToken => '令牌无效';
	@override String failedToVerifyToken({required Object error}) => '无法验证令牌: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => '无法切换到 ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => '无法删除 ${displayName}';
	@override String get failedToRate => '无法更新评分';
}

// Path: libraries
class _TranslationsLibrariesZh extends TranslationsLibrariesEn {
	_TranslationsLibrariesZh._(TranslationsZh root) : this._root = root, super.internal(root);

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
	@override String emptyingTrash({required Object title}) => '正在清空 “${title}” 的回收站...';
	@override String trashEmptied({required Object title}) => '已清空 “${title}” 的回收站';
	@override String failedToEmptyTrash({required Object error}) => '无法清空回收站: ${error}';
	@override String analyzing({required Object title}) => '正在分析 “${title}”...';
	@override String analysisStarted({required Object title}) => '已开始分析 “${title}”';
	@override String failedToAnalyze({required Object error}) => '无法分析媒体库: ${error}';
	@override String get noLibrariesFound => '未找到媒体库';
	@override String get allLibrariesHidden => '所有媒体库已隐藏';
	@override String hiddenLibrariesCount({required Object count}) => '已隐藏的媒体库 (${count})';
	@override String get thisLibraryIsEmpty => '此媒体库为空';
	@override String get noItemsMatchFilters => '没有项目符合当前筛选条件';
	@override String get resetFilters => '重置筛选条件';
	@override String get all => '全部';
	@override String get clearAll => '全部清除';
	@override String scanLibraryConfirm({required Object title}) => '确定要扫描 “${title}” 吗？';
	@override String analyzeLibraryConfirm({required Object title}) => '确定要分析 “${title}” 吗？';
	@override String refreshMetadataConfirm({required Object title}) => '确定要刷新 “${title}” 的元数据吗？';
	@override String emptyTrashConfirm({required Object title}) => '确定要清空 “${title}” 的回收站吗？';
	@override String get manageLibraries => '管理媒体库';
	@override String get sort => '排序';
	@override String get sortBy => '排序依据';
	@override String get filters => '筛选器';
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
	@override late final _TranslationsLibrariesTabsZh tabs = _TranslationsLibrariesTabsZh._(_root);
	@override late final _TranslationsLibrariesGroupingsZh groupings = _TranslationsLibrariesGroupingsZh._(_root);
	@override late final _TranslationsLibrariesFilterCategoriesZh filterCategories = _TranslationsLibrariesFilterCategoriesZh._(_root);
	@override late final _TranslationsLibrariesSortLabelsZh sortLabels = _TranslationsLibrariesSortLabelsZh._(_root);
}

// Path: about
class _TranslationsAboutZh extends TranslationsAboutEn {
	_TranslationsAboutZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '关于';
	@override String get openSourceLicenses => '开源许可证';
	@override String versionLabel({required Object version}) => '版本 ${version}';
	@override String get appDescription => '一款精美的 Flutter Plex 和 Jellyfin 客户端';
	@override String get viewLicensesDescription => '查看第三方库的许可证';
}

// Path: serverSelection
class _TranslationsServerSelectionZh extends TranslationsServerSelectionEn {
	_TranslationsServerSelectionZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => '未找到 ${username} (${email}) 的服务器';
	@override String failedToLoadServers({required Object error}) => '无法加载服务器: ${error}';
}

// Path: hubDetail
class _TranslationsHubDetailZh extends TranslationsHubDetailEn {
	_TranslationsHubDetailZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '标题';
	@override String get releaseYear => '发行年份';
	@override String get dateAdded => '添加日期';
	@override String get rating => '评分';
	@override String get noItemsFound => '未找到项目';
}

// Path: logs
class _TranslationsLogsZh extends TranslationsLogsEn {
	_TranslationsLogsZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => '清除日志';
	@override String get copyLogs => '复制日志';
	@override String get uploadLogs => '上传日志';
}

// Path: licenses
class _TranslationsLicensesZh extends TranslationsLicensesEn {
	_TranslationsLicensesZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => '相关软件包';
	@override String get license => '许可证';
	@override String licenseNumber({required Object number}) => '许可证 ${number}';
	@override String licensesCount({required Object count}) => '${count} 个许可证';
}

// Path: navigation
class _TranslationsNavigationZh extends TranslationsNavigationEn {
	_TranslationsNavigationZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get libraries => '媒体库';
	@override String get downloads => '下载';
	@override String get liveTv => '电视直播';
	@override String get explore => '探索';
}

// Path: explore
class _TranslationsExploreZh extends TranslationsExploreEn {
	_TranslationsExploreZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '探索';
	@override String get selectSource => '选择来源';
	@override late final _TranslationsExploreRowsZh rows = _TranslationsExploreRowsZh._(_root);
	@override late final _TranslationsExploreStatusZh status = _TranslationsExploreStatusZh._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		other: '${n} 集',
	);
	@override String get cast => '演员表';
	@override String get characters => '角色';
	@override String get addToWatchlist => '添加到想看列表';
	@override String get removeFromWatchlist => '从想看列表移除';
	@override String get watchlistUpdateFailed => '无法更新想看列表';
	@override String get notInLibrary => '不在你的媒体库中';
	@override String get inTheseLibraries => '在这些媒体库中';
	@override String get checkingLibrary => '正在检查你的媒体库...';
	@override String get emptyTitle => '这里还什么都没有';
	@override String emptyMessage({required Object source}) => '当 ${source} 有内容时，相关内容将显示在这里。';
	@override String searchHint({required Object source}) => '搜索 ${source}';
	@override String searchEmpty({required Object query}) => '没有“${query}”的结果';
	@override String searchPrompt({required Object source}) => '在 ${source} 上搜索电影和剧集。';
	@override String get searchFailed => '搜索失败。请检查网络连接后重试。';
}

// Path: liveTv
class _TranslationsLiveTvZh extends TranslationsLiveTvEn {
	_TranslationsLiveTvZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '电视直播';
	@override String get guide => '节目指南';
	@override String get noChannels => '没有可用的频道';
	@override String get noDvr => '没有服务器配置了DVR';
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
	@override String get favoritesLoadFailed => '无法加载收藏。请检查网络连接后重试。';
	@override String get joinSession => '加入正在进行的会话';
	@override String watchFromStart({required Object minutes}) => '从头观看（${minutes}分钟前开始）';
	@override String get watchLive => '观看直播';
	@override String get goToLive => '跳至直播';
	@override String get record => '录制';
	@override String get recordEpisode => '录制单集';
	@override String get recordSeries => '录制整部剧集';
	@override String get recordOptions => '录制选项';
	@override String get saveTo => '保存到';
	@override String get recordings => '录制内容';
	@override String get scheduledRecordings => '已安排';
	@override String get recordingRules => '录制规则';
	@override String get noScheduledRecordings => '没有安排的录制';
	@override String get manageRecording => '管理录制';
	@override String get cancelRecording => '取消录制';
	@override String get cancelRecordingTitle => '取消此次录制？';
	@override String cancelRecordingMessage({required Object title}) => '将不再录制 ${title}。';
	@override String get deleteRule => '删除规则';
	@override String get deleteRuleTitle => '删除录制规则？';
	@override String deleteRuleMessage({required Object title}) => '未来的 ${title} 剧集将不会被录制。';
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
	@override String recordingsCount({required Object count}) => '已安排 ${count} 个';
	@override String get editRule => '编辑规则';
	@override String get editRuleAction => '编辑';
	@override String get recordingRuleUpdated => '录制规则已更新';
	@override String get guideReloadRequested => '已请求更新节目指南';
	@override String get rulesProcessRequested => '已请求重新评估规则';
	@override String get recordShow => '录制节目';
}

// Path: collections
class _TranslationsCollectionsZh extends TranslationsCollectionsEn {
	_TranslationsCollectionsZh._(TranslationsZh root) : this._root = root, super.internal(root);

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
	@override String get searchCollections => '搜索合集...';
}

// Path: playlists
class _TranslationsPlaylistsZh extends TranslationsPlaylistsEn {
	_TranslationsPlaylistsZh._(TranslationsZh root) : this._root = root, super.internal(root);

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
	@override String deleteMessage({required Object name}) => '确定要删除 "${name}" 吗？';
	@override String get created => '播放列表已创建';
	@override String get deleted => '播放列表已删除';
	@override String get itemAdded => '已添加到播放列表';
	@override String get itemRemoved => '已从播放列表中移除';
	@override String get selectPlaylist => '选择播放列表';
	@override String get searchPlaylists => '搜索播放列表...';
	@override String get errorCreating => '创建播放列表失败';
	@override String get errorDeleting => '删除播放列表失败';
	@override String get errorLoading => '加载播放列表失败';
	@override String get errorAdding => '添加到播放列表失败';
	@override String get errorReordering => '重新排序播放列表项目失败';
	@override String get errorRemoving => '从播放列表中移除失败';
}

// Path: music
class _TranslationsMusicZh extends TranslationsMusicEn {
	_TranslationsMusicZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => '前往专辑';
	@override String get goToArtist => '前往艺术家';
	@override String get instantMix => '即时混音';
	@override String get playNext => '下一首播放';
	@override String get addToQueue => '添加到队列';
	@override String discNumber({required Object n}) => '碟片 ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		other: '${n} 首',
	);
	@override String get nowPlaying => '正在播放';
	@override String playingFrom({required Object title}) => '来自 ${title}';
	@override String get queue => '播放队列';
	@override String get clearQueue => '清空队列';
	@override String get lyrics => '歌词';
	@override String get noLyrics => '暂无歌词';
	@override String get sleepTimer => '睡眠定时器';
	@override String get sleepTimerEndOfTrack => '曲目结束时';
	@override String sleepTimerMinutes({required Object n}) => '${n} 分钟';
	@override String get stopPlayback => '停止播放';
	@override String get previousTrack => '上一首';
	@override String get nextTrack => '下一首';
	@override String get repeat => '循环';
	@override String get repeatAll => '列表循环';
	@override String get repeatOne => '单曲循环';
}

// Path: watchTogether
class _TranslationsWatchTogetherZh extends TranslationsWatchTogetherEn {
	_TranslationsWatchTogetherZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '一起看';
	@override String get description => '与朋友和家人同步观看内容';
	@override String get createSession => '创建会话';
	@override String get creating => '创建中...';
	@override String get joinSession => '加入会话';
	@override String get joining => '加入中...';
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
	@override String get syncing => '同步中...';
	@override String get joinWatchSession => '加入观看会话';
	@override String get enterCodeHint => '输入5位代码';
	@override String get pasteFromClipboard => '从剪贴板粘贴';
	@override String get pleaseEnterCode => '请输入会话代码';
	@override String get codeMustBe5Chars => '会话代码必须是5个字符';
	@override String get joinInstructions => '输入主持人的会话代码以加入。';
	@override String get failedToCreate => '创建会话失败';
	@override String get failedToJoin => '加入会话失败';
	@override String get sessionCodeCopied => '会话代码已复制到剪贴板';
	@override String get relayUnreachable => '无法访问中继服务器。ISP 阻止可能导致 Watch Together 不可用。';
	@override String get reconnectingToHost => '正在重新连接到主持人...';
	@override String get currentPlayback => '当前播放';
	@override String get joinCurrentPlayback => '加入当前播放';
	@override String get joinCurrentPlaybackDescription => '回到房主当前正在观看的内容';
	@override String get failedToOpenCurrentPlayback => '无法打开当前播放';
	@override String participantJoined({required Object name}) => '${name} 加入了';
	@override String participantLeft({required Object name}) => '${name} 离开了';
	@override String participantPaused({required Object name}) => '${name} 暂停了';
	@override String participantResumed({required Object name}) => '${name} 继续播放了';
	@override String participantSeeked({required Object name}) => '${name} 跳转了';
	@override String participantBuffering({required Object name}) => '${name} 正在缓冲';
	@override String participantNeedsUpdate({required Object name}) => '${name} 正在使用较旧版本的应用，无法同步';
	@override String resumingWithout({required Object name}) => '不等待 ${name}，继续播放';
	@override String get waitingForParticipants => '等待其他人加载...';
	@override String waitingForName({required Object name}) => '正在等待 ${name}...';
	@override String get recentRooms => '最近的房间';
	@override String get renameRoom => '重命名房间';
	@override String get removeRoom => '移除';
	@override String get guestSwitchUnavailable => '无法切换 — 服务器无法同步';
	@override String get guestSwitchFailed => '无法切换 — 在此服务器上未找到内容';
}

// Path: downloads
class _TranslationsDownloadsZh extends TranslationsDownloadsEn {
	_TranslationsDownloadsZh._(TranslationsZh root) : this._root = root, super.internal(root);

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
	@override String episodesQueued({required Object count}) => '${count} 集已加入下载队列';
	@override String get downloadDeleted => '下载已删除';
	@override String deleteConfirm({required Object title}) => '要从此设备删除“${title}”吗？';
	@override String get cancelledDownloadTitle => '已取消的下载';
	@override String get cancelledDownloadMessage => '此下载已取消。你想怎么做？';
	@override String get allEpisodesAlreadyDownloaded => '所有剧集均已下载';
	@override String get resumeDownload => '继续下载';
	@override String get cancelledDownload => '已取消的下载';
	@override String syncingFile({required Object file, required Object status}) => '${file}（正在同步 ${status}）';
	@override String downloadedFileClickToComplete({required Object file}) => '已下载 ${file} — 点击完成';
	@override String get partialDownloadClickToComplete => '已部分下载 — 点击完成';
	@override String get deleting => '正在删除...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => '正在删除 ${title}... (${current}/${total})';
	@override String get queuedTooltip => '已排队';
	@override String queuedFilesTooltip({required Object files}) => '已排队：${files}';
	@override String get downloadingTooltip => '正在下载...';
	@override String downloadingFilesTooltip({required Object files}) => '正在下载 ${files}';
	@override String get noDownloadsTree => '暂无下载';
	@override String get pauseAll => '全部暂停';
	@override String get resumeAll => '全部继续';
	@override String get deleteAll => '全部删除';
	@override String get selectVersion => '选择版本';
	@override String get allEpisodes => '所有剧集';
	@override String get unwatchedOnly => '仅未观看';
	@override String nextNUnwatched({required Object count}) => '接下来 ${count} 集未观看';
	@override String get customAmount => '自定义数量...';
	@override String get includeSpecials => '包含特别篇';
	@override String get howManyEpisodes => '下载几集？';
	@override String get invalidEpisodeCount => '请输入有效的集数。';
	@override String get keepSynced => '保持同步';
	@override String get downloadOnce => '下载一次';
	@override String keepNUnwatched({required Object count}) => '保留${count}个未观看';
	@override String get editSyncRule => '编辑同步规则';
	@override String get removeSyncRule => '删除同步规则';
	@override String removeSyncRuleConfirm({required Object title}) => '停止同步“${title}”？已下载的剧集将被保留。';
	@override String syncRuleCreated({required Object count}) => '同步规则已创建 — 保留${count}个未观看的剧集';
	@override String get syncRuleUpdated => '同步规则已更新';
	@override String get syncRuleRemoved => '同步规则已删除';
	@override String syncedNewEpisodes({required Object title, required Object count}) => '已为${title}同步${count}个新剧集';
	@override String get activeSyncRules => '同步规则';
	@override String get noSyncRules => '没有同步规则';
	@override String get manageSyncRule => '管理同步';
	@override String get editEpisodeCount => '剧集数量';
	@override String get editSyncFilter => '同步筛选';
	@override String get syncAllItems => '同步所有项目';
	@override String get syncUnwatchedItems => '同步未观看项目';
	@override String syncRuleServerContext({required Object server, required Object status}) => '服务器: ${server} • ${status}';
	@override String get syncRuleAvailable => '可用';
	@override String get syncRuleOffline => '离线';
	@override String get syncRuleSignInRequired => '需要登录';
	@override String get syncRuleNotAvailableForProfile => '当前个人资料不可用';
	@override String get syncRuleUnknownServer => '未知服务器';
	@override String get syncRuleListCreated => '同步规则已创建';
}

// Path: shaders
class _TranslationsShadersZh extends TranslationsShadersEn {
	_TranslationsShadersZh._(TranslationsZh root) : this._root = root, super.internal(root);

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
	@override String deleteShaderConfirm({required Object name}) => '删除"${name}"？';
}

// Path: companionRemote
class _TranslationsCompanionRemoteZh extends TranslationsCompanionRemoteEn {
	_TranslationsCompanionRemoteZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '伴侣遥控';
	@override String connectedTo({required Object name}) => '已连接到 ${name}';
	@override String get unknownDevice => '未知设备';
	@override late final _TranslationsCompanionRemoteSessionZh session = _TranslationsCompanionRemoteSessionZh._(_root);
	@override late final _TranslationsCompanionRemotePairingZh pairing = _TranslationsCompanionRemotePairingZh._(_root);
	@override late final _TranslationsCompanionRemoteRemoteZh remote = _TranslationsCompanionRemoteRemoteZh._(_root);
	@override late final _TranslationsCompanionRemoteErrorsZh errors = _TranslationsCompanionRemoteErrorsZh._(_root);
}

// Path: videoSettings
class _TranslationsVideoSettingsZh extends TranslationsVideoSettingsEn {
	_TranslationsVideoSettingsZh._(TranslationsZh root) : this._root = root, super.internal(root);

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
	@override String get audioOutput => '音频输出';
	@override String get performanceOverlay => '性能监控';
	@override String get audioPassthrough => '音频直通';
	@override String get audioNormalization => '响度标准化';
	@override String get audioDownmix => '下混为立体声';
}

// Path: performanceOverlay
class _TranslationsPerformanceOverlayZh extends TranslationsPerformanceOverlayEn {
	_TranslationsPerformanceOverlayZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get color => '颜色';
	@override String get performance => '性能';
	@override String get buffer => '缓冲';
	@override String get app => '应用';
	@override String get decoder => '解码器';
	@override String get rawDecoder => '原始解码器';
	@override String get tunneling => '隧道';
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
	@override String get transfer => '传输';
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
}

// Path: externalPlayer
class _TranslationsExternalPlayerZh extends TranslationsExternalPlayerEn {
	_TranslationsExternalPlayerZh._(TranslationsZh root) : this._root = root, super.internal(root);

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
class _TranslationsMetadataEditZh extends TranslationsMetadataEditEn {
	_TranslationsMetadataEditZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => '编辑...';
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
	@override String get fromUrl => '从 URL';
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
	@override String get style => '风格';
	@override String get mood => '氛围';
}

// Path: matchScreen
class _TranslationsMatchScreenZh extends TranslationsMatchScreenEn {
	_TranslationsMatchScreenZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get match => '匹配...';
	@override String get fixMatch => '修正匹配...';
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
class _TranslationsServerTasksZh extends TranslationsServerTasksEn {
	_TranslationsServerTasksZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '服务器任务';
	@override String get failedToLoad => '加载任务失败';
	@override String get noTasks => '没有正在运行的任务';
}

// Path: trakt
class _TranslationsTraktZh extends TranslationsTraktEn {
	_TranslationsTraktZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => '已连接';
	@override String connectedAs({required Object username}) => '已以 @${username} 身份连接';
	@override String get disconnectConfirm => '断开 Trakt 账户？';
	@override String get disconnectConfirmBody => 'Plezy 将停止向 Trakt 发送事件。你可随时重新连接。';
	@override String get scrobble => '实时 Scrobble';
	@override String get scrobbleDescription => '在播放时向 Trakt 发送播放、暂停和停止事件。';
	@override String get watchedSync => '同步已观看状态';
	@override String get watchedSyncDescription => '在 Plezy 中将内容标记为已观看时，也会在 Trakt 上标记为已观看。';
}

// Path: seerr
class _TranslationsSeerrZh extends TranslationsSeerrEn {
	_TranslationsSeerrZh._(TranslationsZh root) : this._root = root, super.internal(root);

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
	@override String get qualityProfile => '质量配置文件';
	@override String get rootFolder => '根目录';
	@override String get languageProfile => '语言配置文件';
	@override String get requestSubmitted => '请求已提交';
	@override String requestFailed({required Object error}) => '请求失败: ${error}';
	@override String get requestsLoadFailed => '无法加载请求选项';
	@override String get nothingToRequest => '所有内容都已可用或已请求。';
	@override String get statusAvailable => '可用';
	@override String get statusPartiallyAvailable => '部分可用';
	@override String get statusRequested => '已请求';
	@override String get statusProcessing => '处理中';
}

// Path: services
class _TranslationsServicesZh extends TranslationsServicesEn {
	_TranslationsServicesZh._(TranslationsZh root) : this._root = root, super.internal(root);

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
	@override late final _TranslationsServicesNamesZh names = _TranslationsServicesNamesZh._(_root);
	@override late final _TranslationsServicesDeviceCodeZh deviceCode = _TranslationsServicesDeviceCodeZh._(_root);
	@override late final _TranslationsServicesOauthProxyZh oauthProxy = _TranslationsServicesOauthProxyZh._(_root);
	@override late final _TranslationsServicesLibraryFilterZh libraryFilter = _TranslationsServicesLibraryFilterZh._(_root);
}

// Path: addServer
class _TranslationsAddServerZh extends TranslationsAddServerEn {
	_TranslationsAddServerZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get addJellyfinTitle => '添加 Jellyfin 服务器';
	@override String get serverUrls => '服务器 URL';
	@override String get serverUrlsHelper => '可输入多个 URL，以逗号分隔。';
	@override String get findServer => '查找服务器';
	@override String get searchingLocalServers => '正在查找本地 Jellyfin 服务器...';
	@override String get localServers => '本地 Jellyfin 服务器';
	@override String get username => '用户名';
	@override String get password => '密码';
	@override String get signIn => '登录';
	@override String get change => '更改';
	@override String get required => '必填';
	@override String couldNotReachServer({required Object error}) => '无法连接到服务器: ${error}';
	@override String signInFailed({required Object error}) => '登录失败: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect 失败: ${error}';
	@override String get addPlexTitle => '使用 Plex 登录';
	@override String get pinExpired => 'PIN 在登录前已过期。请重试。';
	@override String failedToRegisterAccount({required Object error}) => '注册帐户失败: ${error}';
	@override String get enterJellyfinUrlError => '输入你的 Jellyfin 服务器 URL';
	@override String get addConnectionTitle => '添加连接';
	@override String addConnectionTitleScoped({required Object name}) => '添加到 ${name}';
	@override String get signInWithPlexCard => '使用 Plex 登录';
	@override String get signInWithPlexCardSubtitle => '授权此设备。共享服务器会被添加。';
	@override String get signInWithPlexCardSubtitleScoped => '授权一个 Plex 账号。Home 用户会成为个人资料。';
	@override String get connectToJellyfinCard => '连接到 Jellyfin';
	@override String get connectToJellyfinCardSubtitle => '输入服务器 URL、用户名和密码。';
	@override String connectToJellyfinCardSubtitleScoped({required Object name}) => '登录到 Jellyfin 服务器。绑定到 ${name}。';
	@override String get borrowFromAnotherProfile => '从另一个配置文件借用';
	@override String get borrowFromAnotherProfileSubtitle => '复用另一个个人资料的连接。受 PIN 保护的个人资料需要 PIN。';
}

// Path: hotkeys.actions
class _TranslationsHotkeysActionsZh extends TranslationsHotkeysActionsEn {
	_TranslationsHotkeysActionsZh._(TranslationsZh root) : this._root = root, super.internal(root);

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
	@override String get subSeekNext => '跳转到下一字幕';
	@override String get subSeekPrev => '跳转到上一字幕';
	@override String get shaderToggle => '切换着色器';
	@override String get skipMarker => '跳过片头/片尾';
	@override String get screenshot => '截图';
}

// Path: videoControls.pipErrors
class _TranslationsVideoControlsPipErrorsZh extends TranslationsVideoControlsPipErrorsEn {
	_TranslationsVideoControlsPipErrorsZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => '需要 Android 8.0 或更高版本';
	@override String get iosVersion => '需要 iOS 15.0 或更高版本';
	@override String get permissionDisabled => '画中画已禁用。请在系统设置中启用。';
	@override String get notSupported => '此设备不支持画中画模式';
	@override String get voSwitchFailed => '无法切换画中画的视频输出';
	@override String get failed => '画中画启动失败';
	@override String unknown({required Object error}) => '发生错误：${error}';
}

// Path: libraries.tabs
class _TranslationsLibrariesTabsZh extends TranslationsLibrariesTabsEn {
	_TranslationsLibrariesTabsZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get recommended => '推荐';
	@override String get browse => '浏览';
	@override String get collections => '合集';
	@override String get playlists => '播放列表';
}

// Path: libraries.groupings
class _TranslationsLibrariesGroupingsZh extends TranslationsLibrariesGroupingsEn {
	_TranslationsLibrariesGroupingsZh._(TranslationsZh root) : this._root = root, super.internal(root);

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
class _TranslationsLibrariesFilterCategoriesZh extends TranslationsLibrariesFilterCategoriesEn {
	_TranslationsLibrariesFilterCategoriesZh._(TranslationsZh root) : this._root = root, super.internal(root);

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
class _TranslationsLibrariesSortLabelsZh extends TranslationsLibrariesSortLabelsEn {
	_TranslationsLibrariesSortLabelsZh._(TranslationsZh root) : this._root = root, super.internal(root);

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
	@override String get studio => '工作室';
	@override String get random => '随机';
	@override String get dateShared => '共享日期';
	@override String get latestEpisodeAirDate => '最新一集播出日期';
	@override String get lastEpisodeDateAdded => '最新一集添加日期';
}

// Path: explore.rows
class _TranslationsExploreRowsZh extends TranslationsExploreRowsEn {
	_TranslationsExploreRowsZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get watchlist => '想看列表';
	@override String get recommendedMovies => '推荐电影';
	@override String get recommendedShows => '推荐剧集';
	@override String get trendingMovies => '趋势电影';
	@override String get trendingShows => '趋势剧集';
	@override String get popularMovies => '热门电影';
	@override String get popularShows => '热门剧集';
	@override String get suggestedAnime => '推荐动画';
	@override String get airingAnime => '热门连载动画';
	@override String get popularAnime => '最受欢迎动画';
	@override String get trending => '趋势';
	@override String get upcomingMovies => '即将上映的电影';
	@override String get upcomingShows => '即将播出的剧集';
}

// Path: explore.status
class _TranslationsExploreStatusZh extends TranslationsExploreStatusEn {
	_TranslationsExploreStatusZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get airing => '连载中';
	@override String get ended => '已完结';
	@override String get canceled => '已取消';
	@override String get upcoming => '即将上线';
}

// Path: companionRemote.session
class _TranslationsCompanionRemoteSessionZh extends TranslationsCompanionRemoteSessionEn {
	_TranslationsCompanionRemoteSessionZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get startingServer => '正在启动远程服务器...';
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
}

// Path: companionRemote.pairing
class _TranslationsCompanionRemotePairingZh extends TranslationsCompanionRemotePairingEn {
	_TranslationsCompanionRemotePairingZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => '使用同一 Plex 账号的 Plezy 设备会显示在这里';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => '正在连接...';
	@override String get searchingForDevices => '正在搜索设备...';
	@override String get noDevicesFound => '未在网络上找到设备';
	@override String get noDevicesHint => '在桌面端打开 Plezy 并使用同一 WiFi';
	@override String get availableDevices => '可用设备';
	@override String get manualConnection => '手动连接';
	@override String get cryptoInitFailed => '无法启动安全连接。请先登录 Plex。';
	@override String get validationHostRequired => '请输入主机地址';
	@override String get validationHostFormat => '格式必须为IP:端口（例如 192.168.1.100:48632）';
	@override String get connectionTimedOut => '连接超时。请在两台设备上使用同一网络。';
	@override String get sessionNotFound => '未找到设备。请确认 Plezy 正在主机上运行。';
	@override String get authFailed => '认证失败。两台设备需要使用同一 Plex 账号。';
	@override String failedToConnect({required Object error}) => '连接失败：${error}';
}

// Path: companionRemote.remote
class _TranslationsCompanionRemoteRemoteZh extends TranslationsCompanionRemoteRemoteEn {
	_TranslationsCompanionRemoteRemoteZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => '是否要断开远程会话的连接？';
	@override String get reconnecting => '重新连接中...';
	@override String attemptOf({required Object current}) => '第 ${current} 次尝试，共 5 次';
	@override String get retryNow => '立即重试';
	@override String get tabRemote => '遥控';
	@override String get tabPlay => '播放';
	@override String get tabMore => '更多';
	@override String get menu => '菜单';
	@override String get tabNavigation => '标签导航';
	@override String get tabDiscover => '发现';
	@override String get tabLibraries => '媒体库';
	@override String get tabSearch => '搜索';
	@override String get tabDownloads => '下载';
	@override String get tabSettings => '设置';
	@override String get previous => '上一个';
	@override String get playPause => '播放/暂停';
	@override String get next => '下一个';
	@override String get seekBack => '后退';
	@override String get stop => '停止';
	@override String get seekForward => '快进';
	@override String get volume => '音量';
	@override String get volumeDown => '减小';
	@override String get volumeUp => '增大';
	@override String get fullscreen => '全屏';
	@override String get subtitles => '字幕';
	@override String get audio => '音频';
	@override String get searchHint => '在桌面上搜索...';
}

// Path: companionRemote.errors
class _TranslationsCompanionRemoteErrorsZh extends TranslationsCompanionRemoteErrorsEn {
	_TranslationsCompanionRemoteErrorsZh._(TranslationsZh root) : this._root = root, super.internal(root);

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
class _TranslationsServicesNamesZh extends TranslationsServicesNamesEn {
	_TranslationsServicesNamesZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
}

// Path: services.deviceCode
class _TranslationsServicesDeviceCodeZh extends TranslationsServicesDeviceCodeEn {
	_TranslationsServicesDeviceCodeZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '在 ${service} 上激活 Plezy';
	@override String body({required Object url}) => '访问 ${url} 并输入此代码：';
	@override String openToActivate({required Object service}) => '打开 ${service} 以激活';
	@override String get copyCode => '复制激活代码';
	@override String get waitingForAuthorization => '等待授权…';
	@override String get codeCopied => '代码已复制';
}

// Path: services.oauthProxy
class _TranslationsServicesOauthProxyZh extends TranslationsServicesOauthProxyEn {
	_TranslationsServicesOauthProxyZh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '登录 ${service}';
	@override String get body => '扫描此二维码，或在任意设备上打开 URL。';
	@override String openToSignIn({required Object service}) => '打开 ${service} 以登录';
	@override String get copyUrl => '复制登录 URL';
	@override String get urlCopied => 'URL 已复制';
}

// Path: services.libraryFilter
class _TranslationsServicesLibraryFilterZh extends TranslationsServicesLibraryFilterEn {
	_TranslationsServicesLibraryFilterZh._(TranslationsZh root) : this._root = root, super.internal(root);

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
			'auth.waitingForAuth' => '正在等待认证...\n请在浏览器中登录。',
			'auth.useBrowser' => '使用浏览器',
			'auth.or' => '或',
			'auth.connectToJellyfin' => '连接到 Jellyfin',
			'auth.useQuickConnect' => '使用 Quick Connect',
			'auth.quickConnectInstructions' => '在 Jellyfin 中打开 Quick Connect 并输入此代码。',
			'auth.quickConnectWaiting' => '等待批准…',
			'auth.quickConnectCancel' => '取消',
			'auth.quickConnectExpired' => 'Quick Connect 已过期。请重试。',
			'common.cancel' => '取消',
			'common.save' => '保存',
			'common.close' => '关闭',
			'common.clear' => '清除',
			'common.reset' => '重置',
			'common.later' => '稍后',
			'common.submit' => '提交',
			'common.confirm' => '确认',
			'common.retry' => '重试',
			'common.logout' => '登出',
			'common.unknown' => '未知',
			'common.refresh' => '刷新',
			'common.yes' => '是',
			'common.no' => '否',
			'common.delete' => '删除',
			'common.edit' => '编辑',
			'common.shuffle' => '随机播放',
			'common.addTo' => '添加到...',
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
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => '第${number}集 - ${title}',
			'common.chapterNumber' => ({required Object number}) => '章节 ${number}',
			'common.reconnect' => '重新连接',
			'common.viewAll' => '查看全部',
			'common.checkingNetwork' => '正在检查网络...',
			'common.loadingServers' => '正在加载服务器...',
			'common.connectingToServers' => '正在连接服务器...',
			'common.startingOfflineMode' => '正在启动离线模式...',
			'common.loading' => '加载中...',
			'common.fullscreen' => '全屏',
			'common.exitFullscreen' => '退出全屏',
			'common.pressBackAgainToExit' => '再按一次返回退出',
			'screens.licenses' => '许可证',
			'screens.switchProfile' => '切换用户',
			'screens.subtitleStyling' => '字幕样式',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => '日志',
			'update.available' => '有可用更新',
			'update.versionAvailable' => ({required Object version}) => '版本 ${version} 已发布',
			'update.currentVersion' => ({required Object version}) => '当前版本: ${version}',
			'update.skipVersion' => '跳过此版本',
			'update.viewRelease' => '查看发布详情',
			'update.latestVersion' => '已安装的版本是可用的最新版本',
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
			'settings.durationHint' => ({required Object min, required Object max}) => '输入时长 (${min}-${max})',
			'settings.systemTheme' => '系统',
			'settings.lightTheme' => '浅色',
			'settings.darkTheme' => '深色',
			'settings.oledTheme' => 'OLED',
			'settings.libraryDensity' => '媒体库密度',
			'settings.compact' => '紧凑',
			'settings.comfortable' => '舒适',
			'settings.viewMode' => '视图模式',
			'settings.gridView' => '网格视图',
			'settings.listView' => '列表视图',
			'settings.showHeroSection' => '显示主要精选区',
			'settings.continueWatchingAction' => '继续观看操作',
			'settings.continueWatchingPlay' => '播放',
			'settings.continueWatchingDetails' => '打开详情',
			'settings.episodeAction' => '剧集操作',
			'settings.episodePlay' => '播放',
			'settings.episodeDetails' => '打开详情',
			'settings.useGlobalHubs' => '使用主页布局',
			'settings.useGlobalHubsDescription' => '显示统一主页中心。否则使用资料库推荐。',
			'settings.showServerNameOnHubs' => '在推荐栏显示服务器名称',
			'settings.showServerNameOnHubsDescription' => '始终在中心标题中显示服务器名称。',
			'settings.groupLibrariesByServer' => '按服务器分组媒体库',
			'settings.groupLibrariesByServerDescription' => '按媒体服务器分组侧边栏资料库。',
			'settings.alwaysKeepSidebarOpen' => '始终保持侧边栏展开',
			'settings.alwaysKeepSidebarOpenDescription' => '侧边栏保持展开状态，内容区域自动调整',
			'settings.showUnwatchedCount' => '显示未观看数量',
			'settings.showUnwatchedCountDescription' => '在剧集和季上显示未观看的集数',
			'settings.showEpisodeNumberOnCards' => '在卡片上显示集数',
			'settings.showEpisodeNumberOnCardsDescription' => '在剧集卡片上显示季和集编号',
			'settings.showSeasonPostersOnTabs' => '在选项卡上显示季海报',
			'settings.showSeasonPostersOnTabsDescription' => '在每季标签上方显示该季海报',
			'settings.tvFullCardLayout' => '完整 TV 卡片',
			'settings.tvFullCardLayoutDescription' => '使用仅显示图片的 TV 卡片，并叠加演员姓名',
			'settings.focusGlow' => '焦点光晕',
			'settings.focusGlowDescription' => '在获得焦点的卡片周围显示柔和的光晕',
			'settings.visualEffects' => '视觉效果',
			'settings.visualEffectsAuto' => '自动',
			'settings.visualEffectsAutoDescription' => '在性能较低的设备上自动减少效果',
			'settings.visualEffectsFull' => '完整',
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
			'settings.defaultQualityTitle' => '默认画质',
			'settings.musicQualityTitle' => '音乐质量',
			'settings.subtitleStyling' => '字幕样式',
			'settings.subtitleStylingDescription' => '调整字幕外观',
			'settings.smallSkipDuration' => '短跳过时长',
			'settings.largeSkipDuration' => '长跳过时长',
			'settings.rewindOnResume' => '恢复时回退',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} 秒',
			'settings.defaultSleepTimer' => '默认睡眠定时器',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} 分钟',
			'settings.rememberTrackSelections' => '记住每个剧集/电影的音轨选择',
			'settings.rememberTrackSelectionsDescription' => '记住每个标题的音频和字幕选择',
			'settings.showChapterMarkersOnTimeline' => '在进度条上显示章节标记',
			'settings.showChapterMarkersOnTimelineDescription' => '按章节边界分段显示进度条',
			'settings.clickVideoTogglesPlayback' => '点击视频可切换播放/暂停',
			'settings.clickVideoTogglesPlaybackDescription' => '点击视频进行播放/暂停，而不是显示控制项。',
			'settings.videoPlayerControls' => '视频播放器控制',
			'settings.keyboardShortcuts' => '键盘快捷键',
			'settings.keyboardShortcutsDescription' => '自定义键盘快捷键',
			'settings.videoPlayerNavigation' => '视频播放器导航',
			'settings.videoPlayerNavigationDescription' => '使用方向键导航视频播放器控件',
			'settings.watchTogetherRelay' => '一起看中继服务器',
			'settings.watchTogetherRelayDescription' => '设置自定义中继。所有人必须使用同一服务器。',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.crashReporting' => '崩溃报告',
			'settings.crashReportingDescription' => '发送崩溃报告以帮助改进应用',
			'settings.debugLogging' => '调试日志',
			'settings.debugLoggingDescription' => '启用详细日志记录以便故障排除',
			'settings.viewLogs' => '查看日志',
			'settings.viewLogsDescription' => '查看应用程序日志',
			'settings.clearCache' => '清除缓存',
			'settings.clearCacheDescription' => '清除缓存的图片和数据。内容加载可能变慢。',
			'settings.clearCacheSuccess' => '缓存清除成功',
			'settings.resetSettings' => '重置设置',
			'settings.resetSettingsDescription' => '恢复默认设置。此操作无法撤销。',
			'settings.resetSettingsSuccess' => '设置重置成功',
			'settings.backup' => '备份',
			'settings.exportSettings' => '导出设置',
			'settings.exportSettingsDescription' => '将您的偏好保存到文件',
			'settings.exportSettingsSuccess' => '设置已导出',
			'settings.exportSettingsFailed' => '无法导出设置',
			'settings.importSettings' => '导入设置',
			'settings.importSettingsDescription' => '从文件恢复偏好',
			'settings.importSettingsConfirm' => '这将替换您当前的设置。继续吗？',
			'settings.importSettingsSuccess' => '设置已导入',
			'settings.importSettingsFailed' => '无法导入设置',
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
			'settings.validationErrorEnterNumber' => '请输入一个有效的数字',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => '时长必须介于 ${min} 和 ${max} ${unit} 之间',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => '快捷键已被分配给 ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => '快捷键已为 ${action} 更新',
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
			'settings.currentPath' => ({required Object path}) => '当前: ${path}',
			'settings.downloadLocationChanged' => '下载位置已更改',
			'settings.downloadLocationReset' => '下载位置已重置为默认',
			'settings.downloadLocationInvalid' => '所选文件夹不可写入',
			'settings.downloadLocationSelectError' => '选择文件夹失败',
			'settings.downloadOnWifiOnly' => '仅在 WiFi 时下载',
			'settings.downloadOnWifiOnlyDescription' => '使用蜂窝数据时禁止下载',
			'settings.autoRemoveWatchedDownloads' => '自动移除已观看的下载',
			'settings.autoRemoveWatchedDownloadsDescription' => '自动删除已观看的下载',
			'settings.cellularDownloadBlocked' => '蜂窝网络下已阻止下载。请使用 WiFi 或更改设置。',
			'settings.maxVolume' => '最大音量',
			'settings.maxVolumeDescription' => '允许音量超过 100% 以适应安静的媒体',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord 动态状态',
			'settings.discordRichPresenceDescription' => '在 Discord 上显示您正在观看的内容',
			'settings.services' => '服务',
			'settings.servicesDescription' => '连接 Trakt、MyAnimeList、Seerr 等',
			'settings.manageLibrariesDescription' => '重新排序和隐藏媒体库',
			'settings.companionRemoteServer' => '配套遥控服务器',
			'settings.companionRemoteServerDescription' => '允许网络上的移动设备控制此应用',
			'settings.autoPip' => '自动画中画',
			'settings.autoPipDescription' => '播放时离开会进入画中画',
			'settings.matchContentFrameRate' => '匹配内容帧率',
			'settings.matchContentFrameRateDescription' => '将显示刷新率匹配到视频内容',
			'settings.matchRefreshRate' => '匹配刷新率',
			'settings.matchRefreshRateDescription' => '全屏时匹配显示刷新率',
			'settings.matchDynamicRange' => '匹配动态范围',
			'settings.matchDynamicRangeDescription' => 'HDR 内容切换到 HDR，随后切回 SDR',
			'settings.displaySwitchDelay' => '显示切换延迟',
			'settings.tunneledPlayback' => '通道化播放',
			'settings.tunneledPlaybackDescription' => '使用视频隧道。若 HDR 播放出现黑屏，请禁用。',
			'settings.audioPassthrough' => '音频直通',
			'settings.audioPassthroughDescription' => '将 Dolby/DTS 音频不经重新编码直接发送到功放或电视，保留环绕声。如果没有声音，请关闭。',
			'settings.audioPassthroughDescriptionAppleTv' => '将 Dolby Digital Plus（含 Atmos）以比特流方式交给系统输出。DTS 和 TrueHD 仍以多声道 PCM 播放。快进快退时可能出现短暂声音中断。',
			'settings.audioDownmix' => '下混为立体声',
			'settings.audioDownmixDescription' => '将环绕声混合为双声道，适用于立体声音箱或耳机',
			'settings.downmixCenterBoost' => '中置声道增强',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => '增强 (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => '下混时音量标准化',
			'settings.audioDownmixNormalizeDescription' => '降低混音电平以防止削波。关闭可保持原始音量（大音量场景可能失真）。',
			'settings.atmosDiagnostics' => 'Atmos 输出测试',
			'settings.atmosDiagnosticsDescription' => '通过系统播放器播放测试信号，诊断 Dolby Atmos 输出',
			'settings.atmosTestHlsAtmos' => 'Apple Atmos 流',
			'settings.atmosTestHlsAtmosDescription' => '已知正常的 Dolby Atmos 流。功放应显示 Dolby Atmos。',
			'settings.atmosTestHlsControl' => 'Apple 环绕声流',
			'settings.atmosTestHlsControlDescription' => '不含 Atmos 的对照流。功放应显示不带 Atmos 的环绕声。',
			'settings.atmosTestRawStream' => '原始 EAC3 流',
			'settings.atmosTestRawStreamDescription' => '以与播放器内 Atmos 播放完全相同的方式串流测试文件。需要测试文件 URL。',
			'settings.atmosTestRawFile' => '原始 EAC3 文件',
			'settings.atmosTestRawFileDescription' => '以已知长度播放测试文件。需要测试文件 URL。',
			'settings.atmosTestStop' => '停止测试',
			'settings.atmosTestUrl' => '测试文件 URL',
			'settings.atmosTestUrlDescription' => '原始 .ec3 Dolby Atmos 文件的 HTTP URL（例如用 ffmpeg 提取）',
			'settings.atmosTestUrlMissing' => '请先设置测试文件 URL',
			'settings.atmosTestStatus' => '状态',
			'settings.dvConversionMode' => 'Dolby Vision 转换',
			'settings.dvConversionModeDescription' => '选择 ExoPlayer 如何处理 Dolby Vision Profile 7 文件。',
			'settings.dvConversionAuto' => '自动',
			'settings.dvConversionNative' => '原生 / 禁用',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => '使用设备能力检测和正常回退行为',
			'settings.dvConversionNativeDescription' => '强制原生 DV7 并抑制 DV 转换重试',
			'settings.dvConversionDv81Description' => '强制内联 RPU 转换为 Dolby Vision Profile 8.1',
			'settings.dvConversionHevcStripDescription' => '移除 Dolby Vision RPU/EL 层并呈现普通 HEVC',
			'settings.requireProfileSelectionOnOpen' => '打开应用时询问配置文件',
			'settings.requireProfileSelectionOnOpenDescription' => '每次打开应用时显示配置文件选择',
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
			'search.hint' => '搜索电影、系列、音乐...',
			'search.tryDifferentTerm' => '尝试不同的搜索词',
			'search.searchYourMedia' => '搜索媒体',
			'search.enterTitleActorOrKeyword' => '输入标题、演员或关键词',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => '为 ${actionName} 设置快捷键',
			'hotkeys.clearShortcut' => '清除快捷键',
			'hotkeys.noShortcutSet' => '未设置快捷键',
			'hotkeys.currentShortcut' => '当前快捷键:',
			'hotkeys.pressToRecord' => '选择以录制快捷键',
			'hotkeys.recordingShortcut' => '现在请按下快捷键',
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
			'hotkeys.actions.subSeekNext' => '跳转到下一字幕',
			'hotkeys.actions.subSeekPrev' => '跳转到上一字幕',
			'hotkeys.actions.shaderToggle' => '切换着色器',
			'hotkeys.actions.skipMarker' => '跳过片头/片尾',
			'hotkeys.actions.screenshot' => '截图',
			'fileInfo.title' => '文件信息',
			'fileInfo.video' => '视频',
			'fileInfo.audio' => '音频',
			'fileInfo.file' => '文件',
			'fileInfo.advanced' => '高级',
			'fileInfo.codec' => '编解码器',
			'fileInfo.resolution' => '分辨率',
			'fileInfo.bitrate' => '比特率',
			'fileInfo.frameRate' => '帧率',
			'fileInfo.aspectRatio' => '宽高比',
			'fileInfo.profile' => '配置文件',
			'fileInfo.bitDepth' => '位深度',
			'fileInfo.colorSpace' => '色彩空间',
			'fileInfo.colorRange' => '色彩范围',
			'fileInfo.colorPrimaries' => '颜色原色',
			'fileInfo.chromaSubsampling' => '色度子采样',
			'fileInfo.channels' => '声道',
			'fileInfo.subtitles' => '字幕',
			'fileInfo.overallBitrate' => '总比特率',
			'fileInfo.path' => '路径',
			'fileInfo.size' => '大小',
			'fileInfo.container' => '容器',
			'fileInfo.duration' => '时长',
			'fileInfo.optimizedForStreaming' => '已优化用于流媒体',
			'fileInfo.has64bitOffsets' => '64位偏移量',
			'mediaMenu.markAsWatched' => '标记为已观看',
			'mediaMenu.markAsUnwatched' => '标记为未观看',
			'mediaMenu.removeFromContinueWatching' => '从继续观看中移除',
			'mediaMenu.viewDetails' => '查看详情',
			'mediaMenu.goToSeries' => '转到系列',
			'mediaMenu.shufflePlay' => '随机播放',
			'mediaMenu.shuffleNotAvailableOffline' => '离线时无法随机播放',
			'mediaMenu.fileInfo' => '文件信息',
			'mediaMenu.deleteFromServer' => '从服务器删除',
			'mediaMenu.confirmDelete' => '要从服务器删除此媒体及其文件吗？',
			'mediaMenu.deleteMultipleWarning' => '这包括所有剧集及其文件。',
			'mediaMenu.mediaDeletedSuccessfully' => '媒体项已成功删除',
			'mediaMenu.mediaFailedToDelete' => '删除媒体项失败',
			'mediaMenu.rate' => '评分',
			'mediaMenu.playFromBeginning' => '从头播放',
			'mediaMenu.playVersion' => '播放版本...',
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
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '已观看 ${percent} 百分比',
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
			'tooltips.shufflePlay' => '随机播放',
			'tooltips.playTrailer' => '播放预告片',
			'tooltips.markAsWatched' => '标记为已观看',
			'tooltips.markAsUnwatched' => '标记为未观看',
			'videoControls.audioLabel' => '音频',
			'videoControls.subtitlesLabel' => '字幕',
			'videoControls.resetToZero' => '重置为 0ms',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount}${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label} 播放较晚',
			'videoControls.playsEarlier' => ({required Object label}) => '${label} 播放较早',
			'videoControls.noOffset' => '无偏移',
			'videoControls.letterbox' => '信箱模式（Letterbox）',
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
			'videoControls.pausingIn' => ({required Object seconds}) => '${seconds}秒后暂停',
			'videoControls.continueWatching' => '继续',
			'videoControls.autoPlayNext' => '自动播放下一集',
			'videoControls.playNext' => '播放下一集',
			'videoControls.playButton' => '播放',
			'videoControls.pauseButton' => '暂停',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => '后退 ${seconds} 秒',
			'videoControls.seekForwardButton' => ({required Object seconds}) => '前进 ${seconds} 秒',
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
			'videoControls.pipButton' => '画中画模式',
			'videoControls.aspectRatioButton' => '宽高比',
			'videoControls.ambientLighting' => '氛围灯光',
			'videoControls.fullscreenButton' => '进入全屏',
			'videoControls.exitFullscreenButton' => '退出全屏',
			'videoControls.alwaysOnTopButton' => '置顶窗口',
			'videoControls.rotationLockButton' => '旋转锁定',
			'videoControls.lockScreen' => '锁定屏幕',
			'videoControls.screenLockButton' => '屏幕锁定',
			'videoControls.longPressToUnlock' => '长按解锁',
			'videoControls.timelineSlider' => '视频时间轴',
			'videoControls.volumeSlider' => '音量调节',
			'videoControls.endsAt' => ({required Object time}) => '${time} 结束',
			'videoControls.pipActive' => '正在画中画模式中播放',
			'videoControls.pipFailed' => '画中画启动失败',
			'videoControls.screenshotSaved' => '截图已保存',
			'videoControls.zoomPercent' => ({required Object percent}) => '缩放 ${percent}%',
			'videoControls.pipErrors.androidVersion' => '需要 Android 8.0 或更高版本',
			'videoControls.pipErrors.iosVersion' => '需要 iOS 15.0 或更高版本',
			'videoControls.pipErrors.permissionDisabled' => '画中画已禁用。请在系统设置中启用。',
			'videoControls.pipErrors.notSupported' => '此设备不支持画中画模式',
			'videoControls.pipErrors.voSwitchFailed' => '无法切换画中画的视频输出',
			'videoControls.pipErrors.failed' => '画中画启动失败',
			'videoControls.pipErrors.unknown' => ({required Object error}) => '发生错误：${error}',
			'videoControls.chapters' => '章节',
			'videoControls.noChaptersAvailable' => '没有可用的章节',
			'videoControls.queue' => '播放队列',
			'videoControls.noQueueItems' => '队列中没有项目',
			'videoControls.searchSubtitles' => '搜索字幕',
			'videoControls.language' => '语言',
			'videoControls.noSubtitlesFound' => '未找到字幕',
			'videoControls.downloadedSubtitle' => '已下载',
			'videoControls.noSubtitlesAvailable' => '没有可用字幕',
			'videoControls.noAudioTracksAvailable' => '没有可用音轨',
			'videoControls.noTracksAvailable' => '没有可用轨道',
			'videoControls.subtitleDownloaded' => '字幕已下载',
			'videoControls.subtitleDownloadFailed' => '字幕下载失败',
			'videoControls.searchLanguages' => '搜索语言...',
			'messages.markedAsWatched' => '已标记为已观看',
			'messages.markedAsUnwatched' => '已标记为未观看',
			'messages.markedAsWatchedOffline' => '已标记为已观看 (将在联网时同步)',
			'messages.markedAsUnwatchedOffline' => '已标记为未观看 (将在联网时同步)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => '已自动移除: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '已自动移除 ${n} 个看过的下载', ), 
			'messages.removedFromContinueWatching' => '已从继续观看中移除',
			'messages.errorLoading' => ({required Object error}) => '错误: ${error}',
			'messages.streamInterrupted' => '视频流已中断。按播放键或拖动进度条重试。',
			'messages.liveStreamInterrupted' => '直播流已中断。按播放键重试。',
			'messages.fileInfoNotAvailable' => '文件信息不可用',
			_ => null,
		} ?? switch (path) {
			'messages.errorLoadingFileInfo' => ({required Object error}) => '加载文件信息时出错: ${error}',
			'messages.errorLoadingSeries' => '加载系列时出错',
			'messages.musicNotSupported' => '尚不支持播放音乐',
			'messages.noDescriptionAvailable' => '暂无描述',
			'messages.noProfilesAvailable' => '没有可用的用户',
			'messages.contactAdminForProfiles' => '请联系服务器管理员添加用户配置',
			'messages.unableToDetermineLibrarySection' => '无法确定此项目的库分区',
			'messages.logsCleared' => '日志已清除',
			'messages.logsCopied' => '日志已复制到剪贴板',
			'messages.noLogsAvailable' => '没有可用日志',
			'messages.libraryScanning' => ({required Object title}) => '正在扫描 “${title}”...',
			'messages.libraryScanStarted' => ({required Object title}) => '已开始扫描 “${title}” 媒体库',
			'messages.libraryScanFailed' => ({required Object error}) => '无法扫描媒体库: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => '正在刷新 “${title}” 的元数据...',
			'messages.metadataRefreshStarted' => ({required Object title}) => '已开始刷新 “${title}” 的元数据',
			'messages.metadataRefreshFailed' => ({required Object error}) => '无法刷新元数据: ${error}',
			'messages.logoutConfirm' => '你确定要登出吗？',
			'messages.noSeasonsFound' => '未找到季',
			'messages.seasonsLoadFailed' => '无法加载季',
			'messages.noEpisodesFound' => '在第一季中未找到剧集',
			'messages.noEpisodesFoundGeneral' => '未找到剧集',
			'messages.episodesLoadFailed' => '无法加载剧集',
			'messages.noResultsFound' => '未找到结果',
			'messages.sleepTimerSet' => ({required Object label}) => '睡眠定时器已设置为 ${label}',
			'messages.noItemsAvailable' => '没有可用的项目',
			'messages.failedToCreatePlayQueueNoItems' => '创建播放队列失败 - 没有项目',
			'messages.failedPlayback' => ({required Object action, required Object error}) => '无法${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => '正在切换到兼容的播放器...',
			'messages.serverLimitTitle' => '播放失败',
			'messages.serverLimitBody' => '服务器错误 (HTTP 500)。带宽/转码限制可能拒绝了此会话。请让所有者调整。',
			'messages.logsUploaded' => '日志已上传',
			'messages.logsUploadFailed' => '上传日志失败',
			'messages.logId' => '日志 ID',
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
			'subtitlingStyling.bold' => '粗体',
			'subtitlingStyling.italic' => '斜体',
			'subtitlingStyling.renderResolution' => '渲染分辨率',
			'subtitlingStyling.renderResolutionScreen' => '屏幕分辨率',
			'subtitlingStyling.renderResolutionVideo' => '视频分辨率',
			'mpvConfig.title' => 'mpv 配置',
			'mpvConfig.description' => '高级视频播放器设置',
			'mpvConfig.presets' => '预设',
			'mpvConfig.noPresets' => '没有保存的预设',
			'mpvConfig.saveAsPreset' => '保存为预设...',
			'mpvConfig.presetName' => '预设名称',
			'mpvConfig.presetNameHint' => '输入此预设的名称',
			'mpvConfig.loadPreset' => '加载',
			'mpvConfig.deletePreset' => '删除',
			'mpvConfig.presetSaved' => '预设已保存',
			'mpvConfig.presetLoaded' => '预设已加载',
			'mpvConfig.presetDeleted' => '预设已删除',
			'mpvConfig.confirmDeletePreset' => '确定要删除此预设吗？',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comment',
			'dialog.confirmAction' => '确认操作',
			'profiles.addPlezyProfile' => '添加 Plezy 配置文件',
			'profiles.switchingProfile' => '切换配置文件中…',
			'profiles.deleteThisProfileTitle' => '删除此配置文件？',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => '移除 ${displayName}。连接不会受影响。',
			'profiles.active' => '活跃',
			'profiles.manage' => '管理',
			'profiles.delete' => '删除',
			'profiles.signOut' => '退出登录',
			'profiles.signOutPlexTitle' => '退出 Plex 登录？',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => '要移除 ${displayName} 和所有 Plex Home 用户吗？可随时重新登录。',
			'profiles.signedOutPlex' => '已退出 Plex 登录。',
			'profiles.signOutFailed' => '退出登录失败。',
			'profiles.sectionTitle' => '配置文件',
			'profiles.summarySingle' => '添加配置文件以混合托管用户和本地身份',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} 个配置文件 · 活跃：${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} 个配置文件',
			'profiles.removeConnectionTitle' => '移除连接？',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => '移除 ${displayName} 对 ${connectionLabel} 的访问。其他个人资料仍保留。',
			'profiles.deleteProfileTitle' => '删除配置文件？',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => '移除 ${displayName} 及其连接。服务器仍可用。',
			'profiles.profileNameLabel' => '配置文件名称',
			'profiles.pinProtectionLabel' => 'PIN 保护',
			'profiles.pinManagedByPlex' => 'PIN 由 Plex 管理。在 plex.tv 上编辑。',
			'profiles.noPinSetEditOnPlex' => '未设置 PIN。如需要求 PIN，请在 plex.tv 上编辑 Home 用户。',
			'profiles.setPin' => '设置 PIN',
			'profiles.setPinTitle' => '设置 PIN',
			'profiles.confirmPinTitle' => '确认 PIN',
			'profiles.pinSet' => '已设置 PIN',
			'profiles.changePin' => '更改',
			'profiles.removePin' => '移除',
			'profiles.connectionsLabel' => '连接',
			'profiles.add' => '添加',
			'profiles.deleteProfileButton' => '删除配置文件',
			'profiles.noConnectionsHint' => '没有连接 — 添加一个以使用此配置文件。',
			'profiles.noConnections' => '没有连接',
			'profiles.plexHomeAccount' => 'Plex Home 账户',
			'profiles.connectionDefault' => '默认',
			'profiles.connectionAs' => ({required Object displayName}) => '以 ${displayName} 身份',
			'profiles.makeDefault' => '设为默认',
			'profiles.removeConnection' => '移除',
			'profiles.profileRenamed' => '个人资料已重命名。',
			'profiles.borrowAddTo' => ({required Object displayName}) => '添加到 ${displayName}',
			'profiles.borrowExplain' => '借用另一个个人资料的连接。受 PIN 保护的个人资料需要 PIN。',
			'profiles.borrowEmpty' => '暂无可借用的内容。',
			'profiles.borrowEmptySubtitle' => '请先将 Plex 或 Jellyfin 连接到另一个个人资料。',
			'profiles.borrowFromProfile' => ({required Object displayName}) => '来自 ${displayName}',
			'profiles.borrowConnectionBorrowed' => '已借用连接。',
			'profiles.borrowFailed' => '无法借用连接。',
			'profiles.incorrectPin' => 'PIN 不正确。',
			'profiles.incorrectPinTryAgain' => 'PIN 不正确。请重试。',
			'profiles.sourceProfileMissingParentAccount' => '源个人资料缺少其父账号。',
			'profiles.failedToLoadHomeUsers' => '无法加载您的 Plex Home 用户。请检查网络连接后重试。',
			'profiles.failedToVerifyPin' => '无法验证 PIN。',
			'profiles.newProfile' => '新建配置文件',
			'profiles.profileNameHint' => '例如：访客、儿童、家庭房',
			'profiles.pinProtectionOptional' => 'PIN 保护（可选）',
			'profiles.pinExplain' => '切换个人资料需要 4 位 PIN。',
			'profiles.continueButton' => '继续',
			'profiles.pinsDontMatch' => 'PIN 不匹配',
			'connections.sectionTitle' => '连接',
			'connections.addConnection' => '添加连接',
			'connections.addConnectionSubtitleNoProfile' => '使用 Plex 登录或连接 Jellyfin 服务器',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => '添加到 ${displayName}: Plex、Jellyfin 或其他个人资料连接',
			'connections.sessionExpiredOne' => ({required Object name}) => '${name} 的会话已过期',
			'connections.sessionExpiredMany' => ({required Object count}) => '${count} 个服务器的会话已过期',
			'connections.signInAgain' => '重新登录',
			'connections.editJellyfinTitle' => '编辑 Jellyfin 连接',
			'connections.editJellyfinIntro' => ({required Object serverName}) => '添加或移除 ${serverName} 的 URL。Plezy 会使用可访问且延迟最低的 URL。',
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
			'discover.movie' => '电影',
			'discover.tvShow' => '电视剧',
			'discover.minutesLeft' => ({required Object minutes}) => '剩余 ${minutes} 分钟',
			'discover.moreLikeThis' => '更多类似内容',
			'errors.searchFailed' => ({required Object error}) => '搜索失败: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => '加载 ${context} 时连接超时',
			'errors.connectionFailed' => '无法连接到媒体服务器',
			'errors.unableToLoad' => ({required Object context}) => '无法加载${context}。请重试。',
			'errors.noClientAvailable' => '没有可用客户端',
			'errors.pleaseEnterToken' => '请输入一个令牌',
			'errors.invalidToken' => '令牌无效',
			'errors.failedToVerifyToken' => ({required Object error}) => '无法验证令牌: ${error}',
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
			'libraries.emptyingTrash' => ({required Object title}) => '正在清空 “${title}” 的回收站...',
			'libraries.trashEmptied' => ({required Object title}) => '已清空 “${title}” 的回收站',
			'libraries.failedToEmptyTrash' => ({required Object error}) => '无法清空回收站: ${error}',
			'libraries.analyzing' => ({required Object title}) => '正在分析 “${title}”...',
			'libraries.analysisStarted' => ({required Object title}) => '已开始分析 “${title}”',
			'libraries.failedToAnalyze' => ({required Object error}) => '无法分析媒体库: ${error}',
			'libraries.noLibrariesFound' => '未找到媒体库',
			'libraries.allLibrariesHidden' => '所有媒体库已隐藏',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => '已隐藏的媒体库 (${count})',
			'libraries.thisLibraryIsEmpty' => '此媒体库为空',
			'libraries.noItemsMatchFilters' => '没有项目符合当前筛选条件',
			'libraries.resetFilters' => '重置筛选条件',
			'libraries.all' => '全部',
			'libraries.clearAll' => '全部清除',
			'libraries.scanLibraryConfirm' => ({required Object title}) => '确定要扫描 “${title}” 吗？',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => '确定要分析 “${title}” 吗？',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => '确定要刷新 “${title}” 的元数据吗？',
			'libraries.emptyTrashConfirm' => ({required Object title}) => '确定要清空 “${title}” 的回收站吗？',
			'libraries.manageLibraries' => '管理媒体库',
			'libraries.sort' => '排序',
			'libraries.sortBy' => '排序依据',
			'libraries.filters' => '筛选器',
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
			'libraries.sortLabels.studio' => '工作室',
			'libraries.sortLabels.random' => '随机',
			'libraries.sortLabels.dateShared' => '共享日期',
			'libraries.sortLabels.latestEpisodeAirDate' => '最新一集播出日期',
			'libraries.sortLabels.lastEpisodeDateAdded' => '最新一集添加日期',
			'about.title' => '关于',
			'about.openSourceLicenses' => '开源许可证',
			'about.versionLabel' => ({required Object version}) => '版本 ${version}',
			'about.appDescription' => '一款精美的 Flutter Plex 和 Jellyfin 客户端',
			'about.viewLicensesDescription' => '查看第三方库的许可证',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => '未找到 ${username} (${email}) 的服务器',
			'serverSelection.failedToLoadServers' => ({required Object error}) => '无法加载服务器: ${error}',
			'hubDetail.title' => '标题',
			'hubDetail.releaseYear' => '发行年份',
			'hubDetail.dateAdded' => '添加日期',
			'hubDetail.rating' => '评分',
			'hubDetail.noItemsFound' => '未找到项目',
			'logs.clearLogs' => '清除日志',
			'logs.copyLogs' => '复制日志',
			'logs.uploadLogs' => '上传日志',
			'licenses.relatedPackages' => '相关软件包',
			'licenses.license' => '许可证',
			'licenses.licenseNumber' => ({required Object number}) => '许可证 ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} 个许可证',
			'navigation.libraries' => '媒体库',
			'navigation.downloads' => '下载',
			'navigation.liveTv' => '电视直播',
			'navigation.explore' => '探索',
			'explore.title' => '探索',
			'explore.selectSource' => '选择来源',
			'explore.rows.watchlist' => '想看列表',
			'explore.rows.recommendedMovies' => '推荐电影',
			'explore.rows.recommendedShows' => '推荐剧集',
			'explore.rows.trendingMovies' => '趋势电影',
			'explore.rows.trendingShows' => '趋势剧集',
			'explore.rows.popularMovies' => '热门电影',
			'explore.rows.popularShows' => '热门剧集',
			'explore.rows.suggestedAnime' => '推荐动画',
			'explore.rows.airingAnime' => '热门连载动画',
			'explore.rows.popularAnime' => '最受欢迎动画',
			'explore.rows.trending' => '趋势',
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
			'explore.watchlistUpdateFailed' => '无法更新想看列表',
			'explore.notInLibrary' => '不在你的媒体库中',
			'explore.inTheseLibraries' => '在这些媒体库中',
			'explore.checkingLibrary' => '正在检查你的媒体库...',
			'explore.emptyTitle' => '这里还什么都没有',
			'explore.emptyMessage' => ({required Object source}) => '当 ${source} 有内容时，相关内容将显示在这里。',
			'explore.searchHint' => ({required Object source}) => '搜索 ${source}',
			'explore.searchEmpty' => ({required Object query}) => '没有“${query}”的结果',
			'explore.searchPrompt' => ({required Object source}) => '在 ${source} 上搜索电影和剧集。',
			'explore.searchFailed' => '搜索失败。请检查网络连接后重试。',
			'liveTv.title' => '电视直播',
			'liveTv.guide' => '节目指南',
			'liveTv.noChannels' => '没有可用的频道',
			'liveTv.noDvr' => '没有服务器配置了DVR',
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
			'liveTv.favoritesLoadFailed' => '无法加载收藏。请检查网络连接后重试。',
			'liveTv.joinSession' => '加入正在进行的会话',
			'liveTv.watchFromStart' => ({required Object minutes}) => '从头观看（${minutes}分钟前开始）',
			'liveTv.watchLive' => '观看直播',
			'liveTv.goToLive' => '跳至直播',
			'liveTv.record' => '录制',
			'liveTv.recordEpisode' => '录制单集',
			'liveTv.recordSeries' => '录制整部剧集',
			'liveTv.recordOptions' => '录制选项',
			'liveTv.saveTo' => '保存到',
			'liveTv.recordings' => '录制内容',
			'liveTv.scheduledRecordings' => '已安排',
			'liveTv.recordingRules' => '录制规则',
			'liveTv.noScheduledRecordings' => '没有安排的录制',
			'liveTv.manageRecording' => '管理录制',
			'liveTv.cancelRecording' => '取消录制',
			'liveTv.cancelRecordingTitle' => '取消此次录制？',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '将不再录制 ${title}。',
			'liveTv.deleteRule' => '删除规则',
			'liveTv.deleteRuleTitle' => '删除录制规则？',
			'liveTv.deleteRuleMessage' => ({required Object title}) => '未来的 ${title} 剧集将不会被录制。',
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
			'liveTv.recordingsCount' => ({required Object count}) => '已安排 ${count} 个',
			'liveTv.editRule' => '编辑规则',
			'liveTv.editRuleAction' => '编辑',
			'liveTv.recordingRuleUpdated' => '录制规则已更新',
			'liveTv.guideReloadRequested' => '已请求更新节目指南',
			'liveTv.rulesProcessRequested' => '已请求重新评估规则',
			'liveTv.recordShow' => '录制节目',
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
			'collections.searchCollections' => '搜索合集...',
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
			'playlists.deleteMessage' => ({required Object name}) => '确定要删除 "${name}" 吗？',
			'playlists.created' => '播放列表已创建',
			'playlists.deleted' => '播放列表已删除',
			'playlists.itemAdded' => '已添加到播放列表',
			'playlists.itemRemoved' => '已从播放列表中移除',
			'playlists.selectPlaylist' => '选择播放列表',
			'playlists.searchPlaylists' => '搜索播放列表...',
			'playlists.errorCreating' => '创建播放列表失败',
			'playlists.errorDeleting' => '删除播放列表失败',
			'playlists.errorLoading' => '加载播放列表失败',
			'playlists.errorAdding' => '添加到播放列表失败',
			'playlists.errorReordering' => '重新排序播放列表项目失败',
			'playlists.errorRemoving' => '从播放列表中移除失败',
			'music.goToAlbum' => '前往专辑',
			'music.goToArtist' => '前往艺术家',
			'music.instantMix' => '即时混音',
			'music.playNext' => '下一首播放',
			'music.addToQueue' => '添加到队列',
			'music.discNumber' => ({required Object n}) => '碟片 ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '${n} 首', ), 
			'music.nowPlaying' => '正在播放',
			'music.playingFrom' => ({required Object title}) => '来自 ${title}',
			'music.queue' => '播放队列',
			'music.clearQueue' => '清空队列',
			'music.lyrics' => '歌词',
			'music.noLyrics' => '暂无歌词',
			'music.sleepTimer' => '睡眠定时器',
			'music.sleepTimerEndOfTrack' => '曲目结束时',
			'music.sleepTimerMinutes' => ({required Object n}) => '${n} 分钟',
			'music.stopPlayback' => '停止播放',
			'music.previousTrack' => '上一首',
			'music.nextTrack' => '下一首',
			'music.repeat' => '循环',
			'music.repeatAll' => '列表循环',
			'music.repeatOne' => '单曲循环',
			'watchTogether.title' => '一起看',
			'watchTogether.description' => '与朋友和家人同步观看内容',
			'watchTogether.createSession' => '创建会话',
			'watchTogether.creating' => '创建中...',
			'watchTogether.joinSession' => '加入会话',
			'watchTogether.joining' => '加入中...',
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
			'watchTogether.syncing' => '同步中...',
			'watchTogether.joinWatchSession' => '加入观看会话',
			'watchTogether.enterCodeHint' => '输入5位代码',
			'watchTogether.pasteFromClipboard' => '从剪贴板粘贴',
			'watchTogether.pleaseEnterCode' => '请输入会话代码',
			'watchTogether.codeMustBe5Chars' => '会话代码必须是5个字符',
			'watchTogether.joinInstructions' => '输入主持人的会话代码以加入。',
			'watchTogether.failedToCreate' => '创建会话失败',
			'watchTogether.failedToJoin' => '加入会话失败',
			'watchTogether.sessionCodeCopied' => '会话代码已复制到剪贴板',
			'watchTogether.relayUnreachable' => '无法访问中继服务器。ISP 阻止可能导致 Watch Together 不可用。',
			'watchTogether.reconnectingToHost' => '正在重新连接到主持人...',
			'watchTogether.currentPlayback' => '当前播放',
			'watchTogether.joinCurrentPlayback' => '加入当前播放',
			'watchTogether.joinCurrentPlaybackDescription' => '回到房主当前正在观看的内容',
			'watchTogether.failedToOpenCurrentPlayback' => '无法打开当前播放',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} 加入了',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} 离开了',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} 暂停了',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} 继续播放了',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} 跳转了',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} 正在缓冲',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name} 正在使用较旧版本的应用，无法同步',
			'watchTogether.resumingWithout' => ({required Object name}) => '不等待 ${name}，继续播放',
			'watchTogether.waitingForParticipants' => '等待其他人加载...',
			'watchTogether.waitingForName' => ({required Object name}) => '正在等待 ${name}...',
			'watchTogether.recentRooms' => '最近的房间',
			'watchTogether.renameRoom' => '重命名房间',
			'watchTogether.removeRoom' => '移除',
			'watchTogether.guestSwitchUnavailable' => '无法切换 — 服务器无法同步',
			'watchTogether.guestSwitchFailed' => '无法切换 — 在此服务器上未找到内容',
			'downloads.title' => '下载',
			'downloads.manage' => '管理',
			'downloads.tvShows' => '电视剧',
			'downloads.movies' => '电影',
			_ => null,
		} ?? switch (path) {
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
			'downloads.episodesQueued' => ({required Object count}) => '${count} 集已加入下载队列',
			'downloads.downloadDeleted' => '下载已删除',
			'downloads.deleteConfirm' => ({required Object title}) => '要从此设备删除“${title}”吗？',
			'downloads.cancelledDownloadTitle' => '已取消的下载',
			'downloads.cancelledDownloadMessage' => '此下载已取消。你想怎么做？',
			'downloads.allEpisodesAlreadyDownloaded' => '所有剧集均已下载',
			'downloads.resumeDownload' => '继续下载',
			'downloads.cancelledDownload' => '已取消的下载',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file}（正在同步 ${status}）',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => '已下载 ${file} — 点击完成',
			'downloads.partialDownloadClickToComplete' => '已部分下载 — 点击完成',
			'downloads.deleting' => '正在删除...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => '正在删除 ${title}... (${current}/${total})',
			'downloads.queuedTooltip' => '已排队',
			'downloads.queuedFilesTooltip' => ({required Object files}) => '已排队：${files}',
			'downloads.downloadingTooltip' => '正在下载...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => '正在下载 ${files}',
			'downloads.noDownloadsTree' => '暂无下载',
			'downloads.pauseAll' => '全部暂停',
			'downloads.resumeAll' => '全部继续',
			'downloads.deleteAll' => '全部删除',
			'downloads.selectVersion' => '选择版本',
			'downloads.allEpisodes' => '所有剧集',
			'downloads.unwatchedOnly' => '仅未观看',
			'downloads.nextNUnwatched' => ({required Object count}) => '接下来 ${count} 集未观看',
			'downloads.customAmount' => '自定义数量...',
			'downloads.includeSpecials' => '包含特别篇',
			'downloads.howManyEpisodes' => '下载几集？',
			'downloads.invalidEpisodeCount' => '请输入有效的集数。',
			'downloads.keepSynced' => '保持同步',
			'downloads.downloadOnce' => '下载一次',
			'downloads.keepNUnwatched' => ({required Object count}) => '保留${count}个未观看',
			'downloads.editSyncRule' => '编辑同步规则',
			'downloads.removeSyncRule' => '删除同步规则',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => '停止同步“${title}”？已下载的剧集将被保留。',
			'downloads.syncRuleCreated' => ({required Object count}) => '同步规则已创建 — 保留${count}个未观看的剧集',
			'downloads.syncRuleUpdated' => '同步规则已更新',
			'downloads.syncRuleRemoved' => '同步规则已删除',
			'downloads.syncedNewEpisodes' => ({required Object title, required Object count}) => '已为${title}同步${count}个新剧集',
			'downloads.activeSyncRules' => '同步规则',
			'downloads.noSyncRules' => '没有同步规则',
			'downloads.manageSyncRule' => '管理同步',
			'downloads.editEpisodeCount' => '剧集数量',
			'downloads.editSyncFilter' => '同步筛选',
			'downloads.syncAllItems' => '同步所有项目',
			'downloads.syncUnwatchedItems' => '同步未观看项目',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => '服务器: ${server} • ${status}',
			'downloads.syncRuleAvailable' => '可用',
			'downloads.syncRuleOffline' => '离线',
			'downloads.syncRuleSignInRequired' => '需要登录',
			'downloads.syncRuleNotAvailableForProfile' => '当前个人资料不可用',
			'downloads.syncRuleUnknownServer' => '未知服务器',
			'downloads.syncRuleListCreated' => '同步规则已创建',
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
			'shaders.deleteShaderConfirm' => ({required Object name}) => '删除"${name}"？',
			'companionRemote.title' => '伴侣遥控',
			'companionRemote.connectedTo' => ({required Object name}) => '已连接到 ${name}',
			'companionRemote.unknownDevice' => '未知设备',
			'companionRemote.session.startingServer' => '正在启动远程服务器...',
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
			'companionRemote.pairing.discoveryDescription' => '使用同一 Plex 账号的 Plezy 设备会显示在这里',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => '正在连接...',
			'companionRemote.pairing.searchingForDevices' => '正在搜索设备...',
			'companionRemote.pairing.noDevicesFound' => '未在网络上找到设备',
			'companionRemote.pairing.noDevicesHint' => '在桌面端打开 Plezy 并使用同一 WiFi',
			'companionRemote.pairing.availableDevices' => '可用设备',
			'companionRemote.pairing.manualConnection' => '手动连接',
			'companionRemote.pairing.cryptoInitFailed' => '无法启动安全连接。请先登录 Plex。',
			'companionRemote.pairing.validationHostRequired' => '请输入主机地址',
			'companionRemote.pairing.validationHostFormat' => '格式必须为IP:端口（例如 192.168.1.100:48632）',
			'companionRemote.pairing.connectionTimedOut' => '连接超时。请在两台设备上使用同一网络。',
			'companionRemote.pairing.sessionNotFound' => '未找到设备。请确认 Plezy 正在主机上运行。',
			'companionRemote.pairing.authFailed' => '认证失败。两台设备需要使用同一 Plex 账号。',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => '连接失败：${error}',
			'companionRemote.remote.disconnectConfirm' => '是否要断开远程会话的连接？',
			'companionRemote.remote.reconnecting' => '重新连接中...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => '第 ${current} 次尝试，共 5 次',
			'companionRemote.remote.retryNow' => '立即重试',
			'companionRemote.remote.tabRemote' => '遥控',
			'companionRemote.remote.tabPlay' => '播放',
			'companionRemote.remote.tabMore' => '更多',
			'companionRemote.remote.menu' => '菜单',
			'companionRemote.remote.tabNavigation' => '标签导航',
			'companionRemote.remote.tabDiscover' => '发现',
			'companionRemote.remote.tabLibraries' => '媒体库',
			'companionRemote.remote.tabSearch' => '搜索',
			'companionRemote.remote.tabDownloads' => '下载',
			'companionRemote.remote.tabSettings' => '设置',
			'companionRemote.remote.previous' => '上一个',
			'companionRemote.remote.playPause' => '播放/暂停',
			'companionRemote.remote.next' => '下一个',
			'companionRemote.remote.seekBack' => '后退',
			'companionRemote.remote.stop' => '停止',
			'companionRemote.remote.seekForward' => '快进',
			'companionRemote.remote.volume' => '音量',
			'companionRemote.remote.volumeDown' => '减小',
			'companionRemote.remote.volumeUp' => '增大',
			'companionRemote.remote.fullscreen' => '全屏',
			'companionRemote.remote.subtitles' => '字幕',
			'companionRemote.remote.audio' => '音频',
			'companionRemote.remote.searchHint' => '在桌面上搜索...',
			'companionRemote.errors.noNetworkInterface' => '未找到网络接口',
			'companionRemote.errors.authenticationFailed' => '身份验证失败',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => '无法启动远程服务器：${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => '无法发送远程命令：${error}',
			'companionRemote.errors.joinTimedOut' => '加入会话超时',
			'companionRemote.errors.failedToConnectAnyAddress' => '无法连接到任何地址',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => '${attempts} 次尝试后连接丢失',
			'companionRemote.errors.connectionLost' => '连接丢失',
			'videoSettings.playbackSpeed' => '播放速度',
			'videoSettings.normalSpeed' => '正常',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => '运行中（${duration}）',
			'videoSettings.zoom' => '缩放',
			'videoSettings.sleepTimer' => '睡眠定时器',
			'videoSettings.audioSync' => '音频同步',
			'videoSettings.subtitleSync' => '字幕同步',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => '音频输出',
			'videoSettings.performanceOverlay' => '性能监控',
			'videoSettings.audioPassthrough' => '音频直通',
			'videoSettings.audioNormalization' => '响度标准化',
			'videoSettings.audioDownmix' => '下混为立体声',
			'performanceOverlay.color' => '颜色',
			'performanceOverlay.performance' => '性能',
			'performanceOverlay.buffer' => '缓冲',
			'performanceOverlay.app' => '应用',
			'performanceOverlay.decoder' => '解码器',
			'performanceOverlay.rawDecoder' => '原始解码器',
			'performanceOverlay.tunneling' => '隧道',
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
			'performanceOverlay.transfer' => '传输',
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
			'metadataEdit.editMetadata' => '编辑...',
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
			'metadataEdit.fromUrl' => '从 URL',
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
			'metadataEdit.style' => '风格',
			'metadataEdit.mood' => '氛围',
			'matchScreen.match' => '匹配...',
			'matchScreen.fixMatch' => '修正匹配...',
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
			'trakt.scrobble' => '实时 Scrobble',
			'trakt.scrobbleDescription' => '在播放时向 Trakt 发送播放、暂停和停止事件。',
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
			'seerr.qualityProfile' => '质量配置文件',
			'seerr.rootFolder' => '根目录',
			'seerr.languageProfile' => '语言配置文件',
			'seerr.requestSubmitted' => '请求已提交',
			'seerr.requestFailed' => ({required Object error}) => '请求失败: ${error}',
			'seerr.requestsLoadFailed' => '无法加载请求选项',
			'seerr.nothingToRequest' => '所有内容都已可用或已请求。',
			'seerr.statusAvailable' => '可用',
			'seerr.statusPartiallyAvailable' => '部分可用',
			'seerr.statusRequested' => '已请求',
			'seerr.statusProcessing' => '处理中',
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
			'services.deviceCode.title' => ({required Object service}) => '在 ${service} 上激活 Plezy',
			'services.deviceCode.body' => ({required Object url}) => '访问 ${url} 并输入此代码：',
			'services.deviceCode.openToActivate' => ({required Object service}) => '打开 ${service} 以激活',
			'services.deviceCode.copyCode' => '复制激活代码',
			'services.deviceCode.waitingForAuthorization' => '等待授权…',
			'services.deviceCode.codeCopied' => '代码已复制',
			'services.oauthProxy.title' => ({required Object service}) => '登录 ${service}',
			'services.oauthProxy.body' => '扫描此二维码，或在任意设备上打开 URL。',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => '打开 ${service} 以登录',
			'services.oauthProxy.copyUrl' => '复制登录 URL',
			'services.oauthProxy.urlCopied' => 'URL 已复制',
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
			'addServer.addJellyfinTitle' => '添加 Jellyfin 服务器',
			'addServer.serverUrls' => '服务器 URL',
			'addServer.serverUrlsHelper' => '可输入多个 URL，以逗号分隔。',
			'addServer.findServer' => '查找服务器',
			'addServer.searchingLocalServers' => '正在查找本地 Jellyfin 服务器...',
			'addServer.localServers' => '本地 Jellyfin 服务器',
			'addServer.username' => '用户名',
			'addServer.password' => '密码',
			'addServer.signIn' => '登录',
			'addServer.change' => '更改',
			'addServer.required' => '必填',
			'addServer.couldNotReachServer' => ({required Object error}) => '无法连接到服务器: ${error}',
			'addServer.signInFailed' => ({required Object error}) => '登录失败: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect 失败: ${error}',
			'addServer.addPlexTitle' => '使用 Plex 登录',
			'addServer.pinExpired' => 'PIN 在登录前已过期。请重试。',
			'addServer.failedToRegisterAccount' => ({required Object error}) => '注册帐户失败: ${error}',
			'addServer.enterJellyfinUrlError' => '输入你的 Jellyfin 服务器 URL',
			'addServer.addConnectionTitle' => '添加连接',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => '添加到 ${name}',
			'addServer.signInWithPlexCard' => '使用 Plex 登录',
			'addServer.signInWithPlexCardSubtitle' => '授权此设备。共享服务器会被添加。',
			'addServer.signInWithPlexCardSubtitleScoped' => '授权一个 Plex 账号。Home 用户会成为个人资料。',
			'addServer.connectToJellyfinCard' => '连接到 Jellyfin',
			'addServer.connectToJellyfinCardSubtitle' => '输入服务器 URL、用户名和密码。',
			'addServer.connectToJellyfinCardSubtitleScoped' => ({required Object name}) => '登录到 Jellyfin 服务器。绑定到 ${name}。',
			'addServer.borrowFromAnotherProfile' => '从另一个配置文件借用',
			'addServer.borrowFromAnotherProfileSubtitle' => '复用另一个个人资料的连接。受 PIN 保护的个人资料需要 PIN。',
			_ => null,
		};
	}
}
