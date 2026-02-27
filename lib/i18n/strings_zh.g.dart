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
class TranslationsZh with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsZh({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zh,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <zh>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

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
	@override late final _TranslationsPinEntryZh pinEntry = _TranslationsPinEntryZh._(_root);
	@override late final _TranslationsFileInfoZh fileInfo = _TranslationsFileInfoZh._(_root);
	@override late final _TranslationsMediaMenuZh mediaMenu = _TranslationsMediaMenuZh._(_root);
	@override late final _TranslationsAccessibilityZh accessibility = _TranslationsAccessibilityZh._(_root);
	@override late final _TranslationsTooltipsZh tooltips = _TranslationsTooltipsZh._(_root);
	@override late final _TranslationsVideoControlsZh videoControls = _TranslationsVideoControlsZh._(_root);
	@override late final _TranslationsUserStatusZh userStatus = _TranslationsUserStatusZh._(_root);
	@override late final _TranslationsMessagesZh messages = _TranslationsMessagesZh._(_root);
	@override late final _TranslationsSubtitlingStylingZh subtitlingStyling = _TranslationsSubtitlingStylingZh._(_root);
	@override late final _TranslationsMpvConfigZh mpvConfig = _TranslationsMpvConfigZh._(_root);
	@override late final _TranslationsDialogZh dialog = _TranslationsDialogZh._(_root);
	@override late final _TranslationsDiscoverZh discover = _TranslationsDiscoverZh._(_root);
	@override late final _TranslationsErrorsZh errors = _TranslationsErrorsZh._(_root);
	@override late final _TranslationsLibrariesZh libraries = _TranslationsLibrariesZh._(_root);
	@override late final _TranslationsAboutZh about = _TranslationsAboutZh._(_root);
	@override late final _TranslationsServerSelectionZh serverSelection = _TranslationsServerSelectionZh._(_root);
	@override late final _TranslationsHubDetailZh hubDetail = _TranslationsHubDetailZh._(_root);
	@override late final _TranslationsLogsZh logs = _TranslationsLogsZh._(_root);
	@override late final _TranslationsLicensesZh licenses = _TranslationsLicensesZh._(_root);
	@override late final _TranslationsNavigationZh navigation = _TranslationsNavigationZh._(_root);
	@override late final _TranslationsLiveTvZh liveTv = _TranslationsLiveTvZh._(_root);
	@override late final _TranslationsDownloadsZh downloads = _TranslationsDownloadsZh._(_root);
	@override late final _TranslationsPlaylistsZh playlists = _TranslationsPlaylistsZh._(_root);
	@override late final _TranslationsCollectionsZh collections = _TranslationsCollectionsZh._(_root);
	@override late final _TranslationsWatchTogetherZh watchTogether = _TranslationsWatchTogetherZh._(_root);
	@override late final _TranslationsShadersZh shaders = _TranslationsShadersZh._(_root);
	@override late final _TranslationsCompanionRemoteZh companionRemote = _TranslationsCompanionRemoteZh._(_root);
	@override late final _TranslationsVideoSettingsZh videoSettings = _TranslationsVideoSettingsZh._(_root);
	@override late final _TranslationsExternalPlayerZh externalPlayer = _TranslationsExternalPlayerZh._(_root);
	@override late final _TranslationsMetadataEditZh metadataEdit = _TranslationsMetadataEditZh._(_root);
}

// Path: app
class _TranslationsAppZh implements TranslationsAppEn {
	_TranslationsAppZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _TranslationsAuthZh implements TranslationsAuthEn {
	_TranslationsAuthZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => '使用 Plex 登录';
	@override String get showQRCode => '显示二维码';
	@override String get authenticate => '验证';
	@override String get debugEnterToken => '调试：输入 Plex Token';
	@override String get plexTokenLabel => 'Plex 授权令牌 (Auth Token)';
	@override String get plexTokenHint => '输入你的 Plex.tv 令牌';
	@override String get authenticationTimeout => '验证超时。请重试。';
	@override String get scanQRToSignIn => '扫描二维码登录';
	@override String get waitingForAuth => '等待验证中...\n请在你的浏览器中完成登录。';
	@override String get useBrowser => '使用浏览器';
}

// Path: common
class _TranslationsCommonZh implements TranslationsCommonEn {
	_TranslationsCommonZh._(this._root);

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
	@override String get shuffle => '随机播放';
	@override String get addTo => '添加到...';
	@override String get remove => '删除';
	@override String get paste => '粘贴';
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
	@override String get loading => '加载中...';
	@override String get reconnect => '重新连接';
	@override String get exitConfirmTitle => '退出应用？';
	@override String get exitConfirmMessage => '确定要退出吗？';
	@override String get dontAskAgain => '不再询问';
	@override String get exit => '退出';
	@override String get viewAll => '查看全部';
	@override String get checkingNetwork => '正在检查网络...';
	@override String get refreshingServers => '正在刷新服务器...';
	@override String get loadingServers => '正在加载服务器...';
	@override String get connectingToServers => '正在连接服务器...';
	@override String get startingOfflineMode => '正在启动离线模式...';
}

// Path: screens
class _TranslationsScreensZh implements TranslationsScreensEn {
	_TranslationsScreensZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get licenses => '许可证';
	@override String get switchProfile => '切换用户';
	@override String get subtitleStyling => '字幕样式';
	@override String get mpvConfig => 'MPV 配置';
	@override String get logs => '日志';
}

// Path: update
class _TranslationsUpdateZh implements TranslationsUpdateEn {
	_TranslationsUpdateZh._(this._root);

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
class _TranslationsSettingsZh implements TranslationsSettingsEn {
	_TranslationsSettingsZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '设置';
	@override String get language => '语言';
	@override String get theme => '主题';
	@override String get appearance => '外观';
	@override String get videoPlayback => '视频播放';
	@override String get advanced => '高级';
	@override String get episodePosterMode => '剧集海报样式';
	@override String get seriesPoster => '剧集海报';
	@override String get seriesPosterDescription => '为所有剧集显示剧集海报';
	@override String get seasonPoster => '季海报';
	@override String get seasonPosterDescription => '为剧集显示特定季的海报';
	@override String get episodeThumbnail => '剧集缩略图';
	@override String get episodeThumbnailDescription => '显示16:9剧集截图缩略图';
	@override String get showHeroSectionDescription => '在主屏幕上显示精选内容轮播区';
	@override String get secondsLabel => '秒';
	@override String get minutesLabel => '分钟';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => '输入时长 (${min}-${max})';
	@override String get systemTheme => '系统';
	@override String get systemThemeDescription => '跟随系统设置';
	@override String get lightTheme => '浅色';
	@override String get darkTheme => '深色';
	@override String get oledTheme => 'OLED';
	@override String get oledThemeDescription => '纯黑色适用于 OLED 屏幕';
	@override String get libraryDensity => '媒体库密度';
	@override String get compact => '紧凑';
	@override String get compactDescription => '卡片更小，显示更多项目';
	@override String get normal => '标准';
	@override String get normalDescription => '默认尺寸';
	@override String get comfortable => '舒适';
	@override String get comfortableDescription => '卡片更大，显示更少项目';
	@override String get viewMode => '视图模式';
	@override String get gridView => '网格视图';
	@override String get gridViewDescription => '以网格布局显示项目';
	@override String get listView => '列表视图';
	@override String get listViewDescription => '以列表布局显示项目';
	@override String get showHeroSection => '显示主要精选区';
	@override String get useGlobalHubs => '使用 Plex 主页布局';
	@override String get useGlobalHubsDescription => '显示与官方 Plex 客户端相同的主页推荐。关闭时将显示按媒体库分类的推荐。';
	@override String get showServerNameOnHubs => '在推荐栏显示服务器名称';
	@override String get showServerNameOnHubsDescription => '始终在推荐栏标题中显示服务器名称。关闭时仅在推荐栏名称重复时显示。';
	@override String get alwaysKeepSidebarOpen => '始终保持侧边栏展开';
	@override String get alwaysKeepSidebarOpenDescription => '侧边栏保持展开状态，内容区域自动调整';
	@override String get showUnwatchedCount => '显示未观看数量';
	@override String get showUnwatchedCountDescription => '在剧集和季上显示未观看的集数';
	@override String get hideSpoilers => '隐藏未看剧集的剧透内容';
	@override String get hideSpoilersDescription => '模糊未观看剧集的缩略图并隐藏其描述';
	@override String get playerBackend => '播放器引擎';
	@override String get exoPlayer => 'ExoPlayer（推荐）';
	@override String get exoPlayerDescription => 'Android 原生播放器，硬件支持更好';
	@override String get mpv => 'MPV';
	@override String get mpvDescription => '功能更多的高级播放器，支持 ASS 字幕';
	@override String get hardwareDecoding => '硬件解码';
	@override String get hardwareDecodingDescription => '如果可用，使用硬件加速';
	@override String get bufferSize => '缓冲区大小';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => '自动（推荐）';
	@override String bufferSizeWarning({required Object heap, required Object size}) => '您的设备有 ${heap}MB 内存。${size}MB 的缓冲区可能导致播放问题。';
	@override String get subtitleStyling => '字幕样式';
	@override String get subtitleStylingDescription => '调整字幕外观';
	@override String get smallSkipDuration => '短跳过时长';
	@override String get largeSkipDuration => '长跳过时长';
	@override String secondsUnit({required Object seconds}) => '${seconds} 秒';
	@override String get defaultSleepTimer => '默认睡眠定时器';
	@override String minutesUnit({required Object minutes}) => '${minutes} 分钟';
	@override String get rememberTrackSelections => '记住每个剧集/电影的音轨选择';
	@override String get rememberTrackSelectionsDescription => '在播放过程中更改音轨时自动保存音频和字幕语言偏好';
	@override String get clickVideoTogglesPlayback => '点击视频可切换播放/暂停';
	@override String get clickVideoTogglesPlaybackDescription => '如果启用此选项，点击视频播放器将播放或暂停视频。否则，点击将显示或隐藏播放控件';
	@override String get videoPlayerControls => '视频播放器控制';
	@override String get keyboardShortcuts => '键盘快捷键';
	@override String get keyboardShortcutsDescription => '自定义键盘快捷键';
	@override String get videoPlayerNavigation => '视频播放器导航';
	@override String get videoPlayerNavigationDescription => '使用方向键导航视频播放器控件';
	@override String get debugLogging => '调试日志';
	@override String get debugLoggingDescription => '启用详细日志记录以便故障排除';
	@override String get viewLogs => '查看日志';
	@override String get viewLogsDescription => '查看应用程序日志';
	@override String get clearCache => '清除缓存';
	@override String get clearCacheDescription => '这将清除所有缓存的图片和数据。清除缓存后，应用程序加载内容可能会变慢。';
	@override String get clearCacheSuccess => '缓存清除成功';
	@override String get resetSettings => '重置设置';
	@override String get resetSettingsDescription => '这会将所有设置重置为其默认值。此操作无法撤销。';
	@override String get resetSettingsSuccess => '设置重置成功';
	@override String get shortcutsReset => '快捷键已重置为默认值';
	@override String get about => '关于';
	@override String get aboutDescription => '应用程序信息和许可证';
	@override String get updates => '更新';
	@override String get updateAvailable => '有可用更新';
	@override String get checkForUpdates => '检查更新';
	@override String get validationErrorEnterNumber => '请输入一个有效的数字';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => '时长必须介于 ${min} 和 ${max} ${unit} 之间';
	@override String shortcutAlreadyAssigned({required Object action}) => '快捷键已被分配给 ${action}';
	@override String shortcutUpdated({required Object action}) => '快捷键已为 ${action} 更新';
	@override String get autoSkip => '自动跳过';
	@override String get autoSkipIntro => '自动跳过片头';
	@override String get autoSkipIntroDescription => '几秒钟后自动跳过片头标记';
	@override String get autoSkipCredits => '自动跳过片尾';
	@override String get autoSkipCreditsDescription => '自动跳过片尾并播放下一集';
	@override String get autoSkipDelay => '自动跳过延迟';
	@override String autoSkipDelayDescription({required Object seconds}) => '自动跳过前等待 ${seconds} 秒';
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
	@override String get cellularDownloadBlocked => '蜂窝数据下已禁用下载。请连接 WiFi 或更改设置。';
	@override String get maxVolume => '最大音量';
	@override String get maxVolumeDescription => '允许音量超过 100% 以适应安静的媒体';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord 动态状态';
	@override String get discordRichPresenceDescription => '在 Discord 上显示您正在观看的内容';
	@override String get matchContentFrameRate => '匹配内容帧率';
	@override String get matchContentFrameRateDescription => '调整显示刷新率以匹配视频内容，减少画面抖动并节省电量';
	@override String get requireProfileSelectionOnOpen => '打开应用时询问配置文件';
	@override String get requireProfileSelectionOnOpenDescription => '每次打开应用时显示配置文件选择';
	@override String get confirmExitOnBack => '退出前确认';
	@override String get confirmExitOnBackDescription => '按返回键退出应用时显示确认对话框';
}

// Path: search
class _TranslationsSearchZh implements TranslationsSearchEn {
	_TranslationsSearchZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get hint => '搜索电影、系列、音乐...';
	@override String get tryDifferentTerm => '尝试不同的搜索词';
	@override String get searchYourMedia => '搜索媒体';
	@override String get enterTitleActorOrKeyword => '输入标题、演员或关键词';
}

// Path: hotkeys
class _TranslationsHotkeysZh implements TranslationsHotkeysEn {
	_TranslationsHotkeysZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => '为 ${actionName} 设置快捷键';
	@override String get clearShortcut => '清除快捷键';
	@override late final _TranslationsHotkeysActionsZh actions = _TranslationsHotkeysActionsZh._(_root);
}

// Path: pinEntry
class _TranslationsPinEntryZh implements TranslationsPinEntryEn {
	_TranslationsPinEntryZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get enterPin => '输入 PIN';
	@override String get showPin => '显示 PIN';
	@override String get hidePin => '隐藏 PIN';
}

// Path: fileInfo
class _TranslationsFileInfoZh implements TranslationsFileInfoEn {
	_TranslationsFileInfoZh._(this._root);

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
	@override String get path => '路径';
	@override String get size => '大小';
	@override String get container => '容器';
	@override String get duration => '时长';
	@override String get optimizedForStreaming => '已优化用于流媒体';
	@override String get has64bitOffsets => '64位偏移量';
}

// Path: mediaMenu
class _TranslationsMediaMenuZh implements TranslationsMediaMenuEn {
	_TranslationsMediaMenuZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => '标记为已观看';
	@override String get markAsUnwatched => '标记为未观看';
	@override String get removeFromContinueWatching => '从继续观看中移除';
	@override String get goToSeries => '转到系列';
	@override String get goToSeason => '转到季';
	@override String get shufflePlay => '随机播放';
	@override String get fileInfo => '文件信息';
	@override String get deleteFromServer => '从服务器删除';
	@override String get confirmDelete => '这将永久删除此媒体及其文件。此操作无法撤销。';
	@override String get deleteMultipleWarning => '这包括所有剧集及其文件。';
	@override String get mediaDeletedSuccessfully => '媒体项已成功删除';
	@override String get mediaFailedToDelete => '删除媒体项失败';
	@override String get rate => '评分';
}

// Path: accessibility
class _TranslationsAccessibilityZh implements TranslationsAccessibilityEn {
	_TranslationsAccessibilityZh._(this._root);

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
}

// Path: tooltips
class _TranslationsTooltipsZh implements TranslationsTooltipsEn {
	_TranslationsTooltipsZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => '随机播放';
	@override String get playTrailer => '播放预告片';
	@override String get markAsWatched => '标记为已观看';
	@override String get markAsUnwatched => '标记为未观看';
}

// Path: videoControls
class _TranslationsVideoControlsZh implements TranslationsVideoControlsEn {
	_TranslationsVideoControlsZh._(this._root);

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
	@override String get sleepTimerCompleted => '睡眠定时器已完成 - 播放已暂停';
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
	@override String get settingsButton => '视频设置';
	@override String get audioTrackButton => '音轨';
	@override String get subtitlesButton => '字幕';
	@override String get chaptersButton => '章节';
	@override String get versionsButton => '视频版本';
	@override String get pipButton => '画中画模式';
	@override String get aspectRatioButton => '宽高比';
	@override String get ambientLighting => '氛围灯光';
	@override String get ambientLightingOn => '开启氛围灯光';
	@override String get ambientLightingOff => '关闭氛围灯光';
	@override String get fullscreenButton => '进入全屏';
	@override String get exitFullscreenButton => '退出全屏';
	@override String get alwaysOnTopButton => '置顶窗口';
	@override String get rotationLockButton => '旋转锁定';
	@override String get timelineSlider => '视频时间轴';
	@override String get volumeSlider => '音量调节';
	@override String endsAt({required Object time}) => '${time} 结束';
	@override String get pipFailed => '画中画启动失败';
	@override late final _TranslationsVideoControlsPipErrorsZh pipErrors = _TranslationsVideoControlsPipErrorsZh._(_root);
	@override String get chapters => '章节';
	@override String get noChaptersAvailable => '没有可用的章节';
	@override String get queue => 'Queue';
	@override String get noQueueItems => 'No items in queue';
}

// Path: userStatus
class _TranslationsUserStatusZh implements TranslationsUserStatusEn {
	_TranslationsUserStatusZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get admin => '管理员';
	@override String get restricted => '受限';
	@override String get protected => '受保护';
	@override String get current => '当前';
}

// Path: messages
class _TranslationsMessagesZh implements TranslationsMessagesEn {
	_TranslationsMessagesZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => '已标记为已观看';
	@override String get markedAsUnwatched => '已标记为未观看';
	@override String get markedAsWatchedOffline => '已标记为已观看 (将在联网时同步)';
	@override String get markedAsUnwatchedOffline => '已标记为未观看 (将在联网时同步)';
	@override String get removedFromContinueWatching => '已从继续观看中移除';
	@override String errorLoading({required Object error}) => '错误: ${error}';
	@override String get fileInfoNotAvailable => '文件信息不可用';
	@override String errorLoadingFileInfo({required Object error}) => '加载文件信息时出错: ${error}';
	@override String get errorLoadingSeries => '加载系列时出错';
	@override String get errorLoadingSeason => '加载季时出错';
	@override String get musicNotSupported => '尚不支持播放音乐';
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
	@override String get noEpisodesFound => '在第一季中未找到剧集';
	@override String get noEpisodesFoundGeneral => '未找到剧集';
	@override String get noResultsFound => '未找到结果';
	@override String sleepTimerSet({required Object label}) => '睡眠定时器已设置为 ${label}';
	@override String get noItemsAvailable => '没有可用的项目';
	@override String get failedToCreatePlayQueueNoItems => '创建播放队列失败 - 没有项目';
	@override String failedPlayback({required Object action, required Object error}) => '无法${action}: ${error}';
	@override String get switchingToCompatiblePlayer => '正在切换到兼容的播放器...';
	@override String get logsUploaded => 'Logs uploaded';
	@override String get logsUploadFailed => 'Failed to upload logs';
	@override String get logId => 'Log ID';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingZh implements TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get stylingOptions => '样式选项';
	@override String get fontSize => '字号';
	@override String get textColor => '文本颜色';
	@override String get borderSize => '边框大小';
	@override String get borderColor => '边框颜色';
	@override String get backgroundOpacity => '背景不透明度';
	@override String get backgroundColor => '背景颜色';
	@override String get position => 'Position';
}

// Path: mpvConfig
class _TranslationsMpvConfigZh implements TranslationsMpvConfigEn {
	_TranslationsMpvConfigZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'MPV 配置';
	@override String get description => '高级视频播放器设置';
	@override String get properties => '属性';
	@override String get presets => '预设';
	@override String get noProperties => '未配置任何属性';
	@override String get noPresets => '没有保存的预设';
	@override String get addProperty => '添加属性';
	@override String get editProperty => '编辑属性';
	@override String get deleteProperty => '删除属性';
	@override String get propertyKey => '属性键';
	@override String get propertyKeyHint => '例如 hwdec, demuxer-max-bytes';
	@override String get propertyValue => '属性值';
	@override String get propertyValueHint => '例如 auto, 256000000';
	@override String get saveAsPreset => '保存为预设...';
	@override String get presetName => '预设名称';
	@override String get presetNameHint => '输入此预设的名称';
	@override String get loadPreset => '加载';
	@override String get deletePreset => '删除';
	@override String get presetSaved => '预设已保存';
	@override String get presetLoaded => '预设已加载';
	@override String get presetDeleted => '预设已删除';
	@override String get confirmDeletePreset => '确定要删除此预设吗？';
	@override String get confirmDeleteProperty => '确定要删除此属性吗？';
	@override String entriesCount({required Object count}) => '${count} 条目';
}

// Path: dialog
class _TranslationsDialogZh implements TranslationsDialogEn {
	_TranslationsDialogZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => '确认操作';
}

// Path: discover
class _TranslationsDiscoverZh implements TranslationsDiscoverEn {
	_TranslationsDiscoverZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '发现';
	@override String get switchProfile => '切换用户';
	@override String get noContentAvailable => '没有可用内容';
	@override String get addMediaToLibraries => '请向你的媒体库添加一些媒体';
	@override String get continueWatching => '继续观看';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => '概述';
	@override String get cast => '演员表';
	@override String get extras => '预告片与花絮';
	@override String get seasons => '季数';
	@override String get studio => '制作公司';
	@override String get rating => '年龄分级';
	@override String episodeCount({required Object count}) => '${count} 集';
	@override String watchedProgress({required Object watched, required Object total}) => '已观看 ${watched}/${total} 集';
	@override String get movie => '电影';
	@override String get tvShow => '电视剧';
	@override String minutesLeft({required Object minutes}) => '剩余 ${minutes} 分钟';
}

// Path: errors
class _TranslationsErrorsZh implements TranslationsErrorsEn {
	_TranslationsErrorsZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => '搜索失败: ${error}';
	@override String connectionTimeout({required Object context}) => '加载 ${context} 时连接超时';
	@override String get connectionFailed => '无法连接到 Plex 服务器';
	@override String failedToLoad({required Object context, required Object error}) => '无法加载 ${context}: ${error}';
	@override String get noClientAvailable => '没有可用客户端';
	@override String authenticationFailed({required Object error}) => '验证失败: ${error}';
	@override String get couldNotLaunchUrl => '无法打开授权 URL';
	@override String get pleaseEnterToken => '请输入一个令牌';
	@override String get invalidToken => '令牌无效';
	@override String failedToVerifyToken({required Object error}) => '无法验证令牌: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => '无法切换到 ${displayName}';
}

// Path: libraries
class _TranslationsLibrariesZh implements TranslationsLibrariesEn {
	_TranslationsLibrariesZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '媒体库';
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
	@override String get thisLibraryIsEmpty => '此媒体库为空';
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
}

// Path: about
class _TranslationsAboutZh implements TranslationsAboutEn {
	_TranslationsAboutZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '关于';
	@override String get openSourceLicenses => '开源许可证';
	@override String versionLabel({required Object version}) => '版本 ${version}';
	@override String get appDescription => '一款精美的 Flutter Plex 客户端';
	@override String get viewLicensesDescription => '查看第三方库的许可证';
}

// Path: serverSelection
class _TranslationsServerSelectionZh implements TranslationsServerSelectionEn {
	_TranslationsServerSelectionZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get allServerConnectionsFailed => '无法连接到任何服务器。请检查你的网络并重试。';
	@override String noServersFoundForAccount({required Object username, required Object email}) => '未找到 ${username} (${email}) 的服务器';
	@override String failedToLoadServers({required Object error}) => '无法加载服务器: ${error}';
}

// Path: hubDetail
class _TranslationsHubDetailZh implements TranslationsHubDetailEn {
	_TranslationsHubDetailZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '标题';
	@override String get releaseYear => '发行年份';
	@override String get dateAdded => '添加日期';
	@override String get rating => '评分';
	@override String get noItemsFound => '未找到项目';
}

// Path: logs
class _TranslationsLogsZh implements TranslationsLogsEn {
	_TranslationsLogsZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => '清除日志';
	@override String get copyLogs => '复制日志';
	@override String get uploadLogs => 'Upload Logs';
	@override String get error => '错误:';
	@override String get stackTrace => '堆栈跟踪 (Stack Trace):';
}

// Path: licenses
class _TranslationsLicensesZh implements TranslationsLicensesEn {
	_TranslationsLicensesZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => '相关软件包';
	@override String get license => '许可证';
	@override String licenseNumber({required Object number}) => '许可证 ${number}';
	@override String licensesCount({required Object count}) => '${count} 个许可证';
}

// Path: navigation
class _TranslationsNavigationZh implements TranslationsNavigationEn {
	_TranslationsNavigationZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get libraries => '媒体库';
	@override String get downloads => '下载';
	@override String get liveTv => '电视直播';
}

// Path: liveTv
class _TranslationsLiveTvZh implements TranslationsLiveTvEn {
	_TranslationsLiveTvZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '电视直播';
	@override String get channels => '频道';
	@override String get guide => '节目指南';
	@override String get noChannels => '没有可用的频道';
	@override String get noDvr => '没有服务器配置了DVR';
	@override String get tuneFailed => '无法调谐频道';
	@override String get loading => '正在加载频道...';
	@override String get nowPlaying => '正在播放';
	@override String get noPrograms => '没有可用的节目数据';
	@override String channelNumber({required Object number}) => '频道 ${number}';
	@override String get live => '直播';
	@override String get hd => '高清';
	@override String get premiere => '新';
	@override String get reloadGuide => '重新加载节目指南';
	@override String get allChannels => '所有频道';
	@override String get now => '现在';
	@override String get today => '今天';
	@override String get midnight => '午夜';
	@override String get overnight => '凌晨';
	@override String get morning => '上午';
	@override String get daytime => '白天';
	@override String get evening => '晚上';
	@override String get lateNight => '深夜';
	@override String get whatsOn => '正在播出';
	@override String get watchChannel => '观看频道';
}

// Path: downloads
class _TranslationsDownloadsZh implements TranslationsDownloadsEn {
	_TranslationsDownloadsZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '下载';
	@override String get manage => '管理';
	@override String get tvShows => '电视剧';
	@override String get movies => '电影';
	@override String get noDownloads => '暂无下载';
	@override String get noDownloadsDescription => '下载的内容将在此处显示以供离线观看';
	@override String get downloadNow => '下载';
	@override String get deleteDownload => '删除下载';
	@override String get retryDownload => '重试下载';
	@override String get downloadQueued => '下载已排队';
	@override String episodesQueued({required Object count}) => '${count} 集已加入下载队列';
	@override String get downloadDeleted => '下载已删除';
	@override String deleteConfirm({required Object title}) => '确定要删除 "${title}" 吗？下载的文件将从您的设备中删除。';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => '正在删除 ${title}... (${current}/${total})';
	@override String get noDownloadsTree => '暂无下载';
	@override String get pauseAll => '全部暂停';
	@override String get resumeAll => '全部继续';
	@override String get deleteAll => '全部删除';
}

// Path: playlists
class _TranslationsPlaylistsZh implements TranslationsPlaylistsEn {
	_TranslationsPlaylistsZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '播放列表';
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
	@override String get createNewPlaylist => '创建新播放列表';
	@override String get errorCreating => '创建播放列表失败';
	@override String get errorDeleting => '删除播放列表失败';
	@override String get errorLoading => '加载播放列表失败';
	@override String get errorAdding => '添加到播放列表失败';
	@override String get errorReordering => '重新排序播放列表项目失败';
	@override String get errorRemoving => '从播放列表中移除失败';
	@override String get playlist => '播放列表';
}

// Path: collections
class _TranslationsCollectionsZh implements TranslationsCollectionsEn {
	_TranslationsCollectionsZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '合集';
	@override String get collection => '合集';
	@override String get empty => '合集为空';
	@override String get unknownLibrarySection => '无法删除：未知的媒体库分区';
	@override String get deleteCollection => '删除合集';
	@override String deleteConfirm({required Object title}) => '确定要删除"${title}"吗？此操作无法撤销。';
	@override String get deleted => '已删除合集';
	@override String get deleteFailed => '删除合集失败';
	@override String deleteFailedWithError({required Object error}) => '删除合集失败：${error}';
	@override String failedToLoadItems({required Object error}) => '加载合集项目失败：${error}';
	@override String get selectCollection => '选择合集';
	@override String get createNewCollection => '创建新合集';
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
}

// Path: watchTogether
class _TranslationsWatchTogetherZh implements TranslationsWatchTogetherEn {
	_TranslationsWatchTogetherZh._(this._root);

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
	@override String get enterCodeHint => '输入8位代码';
	@override String get pasteFromClipboard => '从剪贴板粘贴';
	@override String get pleaseEnterCode => '请输入会话代码';
	@override String get codeMustBe8Chars => '会话代码必须是8个字符';
	@override String get joinInstructions => '输入主持人分享的会话代码以加入他们的观看会话。';
	@override String get failedToCreate => '创建会话失败';
	@override String get failedToJoin => '加入会话失败';
	@override String get sessionCodeCopied => '会话代码已复制到剪贴板';
	@override String get relayUnreachable => '无法连接到中继服务器。这可能是由于您的网络运营商屏蔽了连接。您仍然可以尝试，但一起观看功能可能无法正常使用。';
	@override String get reconnectingToHost => '正在重新连接到主持人...';
	@override String participantJoined({required Object name}) => '${name} 加入了';
	@override String participantLeft({required Object name}) => '${name} 离开了';
}

// Path: shaders
class _TranslationsShadersZh implements TranslationsShadersEn {
	_TranslationsShadersZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '着色器';
	@override String get noShaderDescription => '无视频增强';
	@override String get nvscalerDescription => 'NVIDIA 图像缩放，使视频更清晰';
	@override String get qualityFast => '快速';
	@override String get qualityHQ => '高质量';
	@override String get mode => '模式';
}

// Path: companionRemote
class _TranslationsCompanionRemoteZh implements TranslationsCompanionRemoteEn {
	_TranslationsCompanionRemoteZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'Companion Remote';
	@override String get connectToDevice => '连接到设备';
	@override String get hostRemoteSession => '创建远程会话';
	@override String get controlThisDevice => '使用手机控制此设备';
	@override String get remoteControl => '远程控制';
	@override String get controlDesktop => '控制桌面设备';
	@override String connectedTo({required Object name}) => '已连接到 ${name}';
	@override late final _TranslationsCompanionRemoteSessionZh session = _TranslationsCompanionRemoteSessionZh._(_root);
	@override late final _TranslationsCompanionRemotePairingZh pairing = _TranslationsCompanionRemotePairingZh._(_root);
	@override late final _TranslationsCompanionRemoteRemoteZh remote = _TranslationsCompanionRemoteRemoteZh._(_root);
}

// Path: videoSettings
class _TranslationsVideoSettingsZh implements TranslationsVideoSettingsEn {
	_TranslationsVideoSettingsZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get playbackSettings => '播放设置';
	@override String get playbackSpeed => '播放速度';
	@override String get sleepTimer => '睡眠定时器';
	@override String get audioSync => '音频同步';
	@override String get subtitleSync => '字幕同步';
	@override String get hdr => 'HDR';
	@override String get audioOutput => '音频输出';
	@override String get performanceOverlay => '性能监控';
	@override String get audioPassthrough => '音频直通';
}

// Path: externalPlayer
class _TranslationsExternalPlayerZh implements TranslationsExternalPlayerEn {
	_TranslationsExternalPlayerZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '外部播放器';
	@override String get useExternalPlayer => '使用外部播放器';
	@override String get useExternalPlayerDescription => '在外部应用中打开视频，而不是使用内置播放器';
	@override String get selectPlayer => '选择播放器';
	@override String get systemDefault => '系统默认';
	@override String get addCustomPlayer => '添加自定义播放器';
	@override String get playerName => '播放器名称';
	@override String get playerCommand => '命令';
	@override String get playerPackage => '包名';
	@override String get playerUrlScheme => 'URL 方案';
	@override String get customPlayer => '自定义播放器';
	@override String get off => '关闭';
	@override String get launchFailed => '无法打开外部播放器';
	@override String appNotInstalled({required Object name}) => '${name} 未安装';
	@override String get playInExternalPlayer => '在外部播放器中播放';
}

// Path: metadataEdit
class _TranslationsMetadataEditZh implements TranslationsMetadataEditEn {
	_TranslationsMetadataEditZh._(this._root);

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
	@override String get selectPoster => '选择海报';
	@override String get selectBackground => '选择背景';
	@override String get fromUrl => '从 URL';
	@override String get uploadFile => '上传文件';
	@override String get enterImageUrl => '输入图片 URL';
	@override String get imageUrl => '图片 URL';
	@override String get metadataUpdated => '元数据已更新';
	@override String get metadataUpdateFailed => '元数据更新失败';
	@override String get artworkUpdated => '封面图片已更新';
	@override String get artworkUpdateFailed => '封面图片更新失败';
	@override String get noArtworkAvailable => '没有可用的封面图片';
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
}

// Path: hotkeys.actions
class _TranslationsHotkeysActionsZh implements TranslationsHotkeysActionsEn {
	_TranslationsHotkeysActionsZh._(this._root);

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
	@override String get speedIncrease => '加速';
	@override String get speedDecrease => '减速';
	@override String get speedReset => '重置速度';
	@override String get subSeekNext => '跳转到下一字幕';
	@override String get subSeekPrev => '跳转到上一字幕';
	@override String get shaderToggle => '切换着色器';
	@override String get skipMarker => '跳过片头/片尾';
}

// Path: videoControls.pipErrors
class _TranslationsVideoControlsPipErrorsZh implements TranslationsVideoControlsPipErrorsEn {
	_TranslationsVideoControlsPipErrorsZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => '需要 Android 8.0 或更高版本';
	@override String get permissionDisabled => '画中画权限已禁用。请在设置 > 应用 > Plezy > 画中画中启用';
	@override String get notSupported => '此设备不支持画中画模式';
	@override String get failed => '画中画启动失败';
	@override String unknown({required Object error}) => '发生错误：${error}';
}

// Path: libraries.tabs
class _TranslationsLibrariesTabsZh implements TranslationsLibrariesTabsEn {
	_TranslationsLibrariesTabsZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get recommended => '推荐';
	@override String get browse => '浏览';
	@override String get collections => '合集';
	@override String get playlists => '播放列表';
}

// Path: libraries.groupings
class _TranslationsLibrariesGroupingsZh implements TranslationsLibrariesGroupingsEn {
	_TranslationsLibrariesGroupingsZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get all => '全部';
	@override String get movies => '电影';
	@override String get shows => '剧集';
	@override String get seasons => '季';
	@override String get episodes => '集';
	@override String get folders => '文件夹';
}

// Path: companionRemote.session
class _TranslationsCompanionRemoteSessionZh implements TranslationsCompanionRemoteSessionEn {
	_TranslationsCompanionRemoteSessionZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get creatingSession => '正在创建远程会话...';
	@override String get failedToCreate => '创建远程会话失败：';
	@override String get noSession => '没有可用的会话';
	@override String get scanQrCode => '扫描 QR 码';
	@override String get orEnterManually => '或手动输入';
	@override String get hostAddress => '主机地址';
	@override String get sessionId => '会话 ID';
	@override String get pin => 'PIN';
	@override String get connected => '已连接';
	@override String get waitingForConnection => '等待连接中...';
	@override String get usePhoneToControl => '使用移动设备控制此应用';
	@override String copiedToClipboard({required Object label}) => '${label}已复制到剪贴板';
	@override String get copyToClipboard => '复制到剪贴板';
	@override String get newSession => '新建会话';
	@override String get minimize => '最小化';
}

// Path: companionRemote.pairing
class _TranslationsCompanionRemotePairingZh implements TranslationsCompanionRemotePairingEn {
	_TranslationsCompanionRemotePairingZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get scan => '扫描';
	@override String get manual => '手动';
	@override String get pairWithDesktop => '与桌面配对';
	@override String get enterSessionDetails => '输入桌面设备上显示的会话信息';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get sessionIdHint => '输入8位会话 ID';
	@override String get pinHint => '输入6位 PIN';
	@override String get connecting => '连接中...';
	@override String get tips => '提示';
	@override String get tipDesktop => '在桌面上打开 Plezy，并从设置或菜单中启用 Companion Remote';
	@override String get tipScan => '使用扫描选项卡扫描桌面上的 QR 码以快速配对';
	@override String get tipWifi => '请确保两台设备连接到同一个 WiFi 网络';
	@override String get cameraPermissionRequired => '扫描 QR 码需要相机权限。\n请在设备设置中授予相机访问权限。';
	@override String cameraError({required Object error}) => '无法启动相机：${error}';
	@override String get scanInstruction => '将相机对准桌面上显示的 QR 码';
	@override String get invalidQrCode => '无效的 QR 码格式';
	@override String get validationHostRequired => '请输入主机地址';
	@override String get validationHostFormat => '格式必须为 IP:端口（例如 192.168.1.100:48632）';
	@override String get validationSessionIdRequired => '请输入会话 ID';
	@override String get validationSessionIdLength => '会话 ID 必须为8个字符';
	@override String get validationPinRequired => '请输入 PIN';
	@override String get validationPinLength => 'PIN 必须为6位数字';
	@override String get connectionTimedOut => '连接超时。请检查会话 ID 和 PIN。';
	@override String get sessionNotFound => '找不到会话。请检查您的凭据。';
	@override String failedToConnect({required Object error}) => '连接失败：${error}';
}

// Path: companionRemote.remote
class _TranslationsCompanionRemoteRemoteZh implements TranslationsCompanionRemoteRemoteEn {
	_TranslationsCompanionRemoteRemoteZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => '是否要断开远程会话的连接？';
	@override String get reconnecting => '重新连接中...';
	@override String attemptOf({required Object current}) => '第 ${current} 次尝试，共 5 次';
	@override String get retryNow => '立即重试';
	@override String get connectionError => '连接错误';
	@override String get notConnected => '未连接';
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
			'auth.debugEnterToken' => '调试：输入 Plex Token',
			'auth.plexTokenLabel' => 'Plex 授权令牌 (Auth Token)',
			'auth.plexTokenHint' => '输入你的 Plex.tv 令牌',
			'auth.authenticationTimeout' => '验证超时。请重试。',
			'auth.scanQRToSignIn' => '扫描二维码登录',
			'auth.waitingForAuth' => '等待验证中...\n请在你的浏览器中完成登录。',
			'auth.useBrowser' => '使用浏览器',
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
			'common.shuffle' => '随机播放',
			'common.addTo' => '添加到...',
			'common.remove' => '删除',
			'common.paste' => '粘贴',
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
			'common.loading' => '加载中...',
			'common.reconnect' => '重新连接',
			'common.exitConfirmTitle' => '退出应用？',
			'common.exitConfirmMessage' => '确定要退出吗？',
			'common.dontAskAgain' => '不再询问',
			'common.exit' => '退出',
			'common.viewAll' => '查看全部',
			'common.checkingNetwork' => '正在检查网络...',
			'common.refreshingServers' => '正在刷新服务器...',
			'common.loadingServers' => '正在加载服务器...',
			'common.connectingToServers' => '正在连接服务器...',
			'common.startingOfflineMode' => '正在启动离线模式...',
			'screens.licenses' => '许可证',
			'screens.switchProfile' => '切换用户',
			'screens.subtitleStyling' => '字幕样式',
			'screens.mpvConfig' => 'MPV 配置',
			'screens.logs' => '日志',
			'update.available' => '有可用更新',
			'update.versionAvailable' => ({required Object version}) => '版本 ${version} 已发布',
			'update.currentVersion' => ({required Object version}) => '当前版本: ${version}',
			'update.skipVersion' => '跳过此版本',
			'update.viewRelease' => '查看发布详情',
			'update.latestVersion' => '已安装的版本是可用的最新版本',
			'update.checkFailed' => '无法检查更新',
			'settings.title' => '设置',
			'settings.language' => '语言',
			'settings.theme' => '主题',
			'settings.appearance' => '外观',
			'settings.videoPlayback' => '视频播放',
			'settings.advanced' => '高级',
			'settings.episodePosterMode' => '剧集海报样式',
			'settings.seriesPoster' => '剧集海报',
			'settings.seriesPosterDescription' => '为所有剧集显示剧集海报',
			'settings.seasonPoster' => '季海报',
			'settings.seasonPosterDescription' => '为剧集显示特定季的海报',
			'settings.episodeThumbnail' => '剧集缩略图',
			'settings.episodeThumbnailDescription' => '显示16:9剧集截图缩略图',
			'settings.showHeroSectionDescription' => '在主屏幕上显示精选内容轮播区',
			'settings.secondsLabel' => '秒',
			'settings.minutesLabel' => '分钟',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => '输入时长 (${min}-${max})',
			'settings.systemTheme' => '系统',
			'settings.systemThemeDescription' => '跟随系统设置',
			'settings.lightTheme' => '浅色',
			'settings.darkTheme' => '深色',
			'settings.oledTheme' => 'OLED',
			'settings.oledThemeDescription' => '纯黑色适用于 OLED 屏幕',
			'settings.libraryDensity' => '媒体库密度',
			'settings.compact' => '紧凑',
			'settings.compactDescription' => '卡片更小，显示更多项目',
			'settings.normal' => '标准',
			'settings.normalDescription' => '默认尺寸',
			'settings.comfortable' => '舒适',
			'settings.comfortableDescription' => '卡片更大，显示更少项目',
			'settings.viewMode' => '视图模式',
			'settings.gridView' => '网格视图',
			'settings.gridViewDescription' => '以网格布局显示项目',
			'settings.listView' => '列表视图',
			'settings.listViewDescription' => '以列表布局显示项目',
			'settings.showHeroSection' => '显示主要精选区',
			'settings.useGlobalHubs' => '使用 Plex 主页布局',
			'settings.useGlobalHubsDescription' => '显示与官方 Plex 客户端相同的主页推荐。关闭时将显示按媒体库分类的推荐。',
			'settings.showServerNameOnHubs' => '在推荐栏显示服务器名称',
			'settings.showServerNameOnHubsDescription' => '始终在推荐栏标题中显示服务器名称。关闭时仅在推荐栏名称重复时显示。',
			'settings.alwaysKeepSidebarOpen' => '始终保持侧边栏展开',
			'settings.alwaysKeepSidebarOpenDescription' => '侧边栏保持展开状态，内容区域自动调整',
			'settings.showUnwatchedCount' => '显示未观看数量',
			'settings.showUnwatchedCountDescription' => '在剧集和季上显示未观看的集数',
			'settings.hideSpoilers' => '隐藏未看剧集的剧透内容',
			'settings.hideSpoilersDescription' => '模糊未观看剧集的缩略图并隐藏其描述',
			'settings.playerBackend' => '播放器引擎',
			'settings.exoPlayer' => 'ExoPlayer（推荐）',
			'settings.exoPlayerDescription' => 'Android 原生播放器，硬件支持更好',
			'settings.mpv' => 'MPV',
			'settings.mpvDescription' => '功能更多的高级播放器，支持 ASS 字幕',
			'settings.hardwareDecoding' => '硬件解码',
			'settings.hardwareDecodingDescription' => '如果可用，使用硬件加速',
			'settings.bufferSize' => '缓冲区大小',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => '自动（推荐）',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => '您的设备有 ${heap}MB 内存。${size}MB 的缓冲区可能导致播放问题。',
			'settings.subtitleStyling' => '字幕样式',
			'settings.subtitleStylingDescription' => '调整字幕外观',
			'settings.smallSkipDuration' => '短跳过时长',
			'settings.largeSkipDuration' => '长跳过时长',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} 秒',
			'settings.defaultSleepTimer' => '默认睡眠定时器',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} 分钟',
			'settings.rememberTrackSelections' => '记住每个剧集/电影的音轨选择',
			'settings.rememberTrackSelectionsDescription' => '在播放过程中更改音轨时自动保存音频和字幕语言偏好',
			'settings.clickVideoTogglesPlayback' => '点击视频可切换播放/暂停',
			'settings.clickVideoTogglesPlaybackDescription' => '如果启用此选项，点击视频播放器将播放或暂停视频。否则，点击将显示或隐藏播放控件',
			'settings.videoPlayerControls' => '视频播放器控制',
			'settings.keyboardShortcuts' => '键盘快捷键',
			'settings.keyboardShortcutsDescription' => '自定义键盘快捷键',
			'settings.videoPlayerNavigation' => '视频播放器导航',
			'settings.videoPlayerNavigationDescription' => '使用方向键导航视频播放器控件',
			'settings.debugLogging' => '调试日志',
			'settings.debugLoggingDescription' => '启用详细日志记录以便故障排除',
			'settings.viewLogs' => '查看日志',
			'settings.viewLogsDescription' => '查看应用程序日志',
			'settings.clearCache' => '清除缓存',
			'settings.clearCacheDescription' => '这将清除所有缓存的图片和数据。清除缓存后，应用程序加载内容可能会变慢。',
			'settings.clearCacheSuccess' => '缓存清除成功',
			'settings.resetSettings' => '重置设置',
			'settings.resetSettingsDescription' => '这会将所有设置重置为其默认值。此操作无法撤销。',
			'settings.resetSettingsSuccess' => '设置重置成功',
			'settings.shortcutsReset' => '快捷键已重置为默认值',
			'settings.about' => '关于',
			'settings.aboutDescription' => '应用程序信息和许可证',
			'settings.updates' => '更新',
			'settings.updateAvailable' => '有可用更新',
			'settings.checkForUpdates' => '检查更新',
			'settings.validationErrorEnterNumber' => '请输入一个有效的数字',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => '时长必须介于 ${min} 和 ${max} ${unit} 之间',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => '快捷键已被分配给 ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => '快捷键已为 ${action} 更新',
			'settings.autoSkip' => '自动跳过',
			'settings.autoSkipIntro' => '自动跳过片头',
			'settings.autoSkipIntroDescription' => '几秒钟后自动跳过片头标记',
			'settings.autoSkipCredits' => '自动跳过片尾',
			'settings.autoSkipCreditsDescription' => '自动跳过片尾并播放下一集',
			'settings.autoSkipDelay' => '自动跳过延迟',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => '自动跳过前等待 ${seconds} 秒',
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
			'settings.cellularDownloadBlocked' => '蜂窝数据下已禁用下载。请连接 WiFi 或更改设置。',
			'settings.maxVolume' => '最大音量',
			'settings.maxVolumeDescription' => '允许音量超过 100% 以适应安静的媒体',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord 动态状态',
			'settings.discordRichPresenceDescription' => '在 Discord 上显示您正在观看的内容',
			'settings.matchContentFrameRate' => '匹配内容帧率',
			'settings.matchContentFrameRateDescription' => '调整显示刷新率以匹配视频内容，减少画面抖动并节省电量',
			'settings.requireProfileSelectionOnOpen' => '打开应用时询问配置文件',
			'settings.requireProfileSelectionOnOpenDescription' => '每次打开应用时显示配置文件选择',
			'settings.confirmExitOnBack' => '退出前确认',
			'settings.confirmExitOnBackDescription' => '按返回键退出应用时显示确认对话框',
			'search.hint' => '搜索电影、系列、音乐...',
			'search.tryDifferentTerm' => '尝试不同的搜索词',
			'search.searchYourMedia' => '搜索媒体',
			'search.enterTitleActorOrKeyword' => '输入标题、演员或关键词',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => '为 ${actionName} 设置快捷键',
			'hotkeys.clearShortcut' => '清除快捷键',
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
			'hotkeys.actions.speedIncrease' => '加速',
			'hotkeys.actions.speedDecrease' => '减速',
			'hotkeys.actions.speedReset' => '重置速度',
			'hotkeys.actions.subSeekNext' => '跳转到下一字幕',
			'hotkeys.actions.subSeekPrev' => '跳转到上一字幕',
			'hotkeys.actions.shaderToggle' => '切换着色器',
			'hotkeys.actions.skipMarker' => '跳过片头/片尾',
			'pinEntry.enterPin' => '输入 PIN',
			'pinEntry.showPin' => '显示 PIN',
			'pinEntry.hidePin' => '隐藏 PIN',
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
			'fileInfo.path' => '路径',
			'fileInfo.size' => '大小',
			'fileInfo.container' => '容器',
			'fileInfo.duration' => '时长',
			'fileInfo.optimizedForStreaming' => '已优化用于流媒体',
			'fileInfo.has64bitOffsets' => '64位偏移量',
			'mediaMenu.markAsWatched' => '标记为已观看',
			'mediaMenu.markAsUnwatched' => '标记为未观看',
			'mediaMenu.removeFromContinueWatching' => '从继续观看中移除',
			'mediaMenu.goToSeries' => '转到系列',
			'mediaMenu.goToSeason' => '转到季',
			'mediaMenu.shufflePlay' => '随机播放',
			'mediaMenu.fileInfo' => '文件信息',
			'mediaMenu.deleteFromServer' => '从服务器删除',
			'mediaMenu.confirmDelete' => '这将永久删除此媒体及其文件。此操作无法撤销。',
			'mediaMenu.deleteMultipleWarning' => '这包括所有剧集及其文件。',
			'mediaMenu.mediaDeletedSuccessfully' => '媒体项已成功删除',
			'mediaMenu.mediaFailedToDelete' => '删除媒体项失败',
			'mediaMenu.rate' => '评分',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, 电影',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, 电视剧',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => '已观看',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '已观看 ${percent} 百分比',
			'accessibility.mediaCardUnwatched' => '未观看',
			'accessibility.tapToPlay' => '点击播放',
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
			'videoControls.sleepTimerCompleted' => '睡眠定时器已完成 - 播放已暂停',
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
			'videoControls.settingsButton' => '视频设置',
			'videoControls.audioTrackButton' => '音轨',
			'videoControls.subtitlesButton' => '字幕',
			'videoControls.chaptersButton' => '章节',
			'videoControls.versionsButton' => '视频版本',
			'videoControls.pipButton' => '画中画模式',
			'videoControls.aspectRatioButton' => '宽高比',
			'videoControls.ambientLighting' => '氛围灯光',
			'videoControls.ambientLightingOn' => '开启氛围灯光',
			'videoControls.ambientLightingOff' => '关闭氛围灯光',
			'videoControls.fullscreenButton' => '进入全屏',
			'videoControls.exitFullscreenButton' => '退出全屏',
			'videoControls.alwaysOnTopButton' => '置顶窗口',
			'videoControls.rotationLockButton' => '旋转锁定',
			'videoControls.timelineSlider' => '视频时间轴',
			'videoControls.volumeSlider' => '音量调节',
			'videoControls.endsAt' => ({required Object time}) => '${time} 结束',
			'videoControls.pipFailed' => '画中画启动失败',
			'videoControls.pipErrors.androidVersion' => '需要 Android 8.0 或更高版本',
			'videoControls.pipErrors.permissionDisabled' => '画中画权限已禁用。请在设置 > 应用 > Plezy > 画中画中启用',
			'videoControls.pipErrors.notSupported' => '此设备不支持画中画模式',
			'videoControls.pipErrors.failed' => '画中画启动失败',
			'videoControls.pipErrors.unknown' => ({required Object error}) => '发生错误：${error}',
			'videoControls.chapters' => '章节',
			'videoControls.noChaptersAvailable' => '没有可用的章节',
			'videoControls.queue' => 'Queue',
			'videoControls.noQueueItems' => 'No items in queue',
			'userStatus.admin' => '管理员',
			'userStatus.restricted' => '受限',
			'userStatus.protected' => '受保护',
			'userStatus.current' => '当前',
			'messages.markedAsWatched' => '已标记为已观看',
			'messages.markedAsUnwatched' => '已标记为未观看',
			'messages.markedAsWatchedOffline' => '已标记为已观看 (将在联网时同步)',
			'messages.markedAsUnwatchedOffline' => '已标记为未观看 (将在联网时同步)',
			'messages.removedFromContinueWatching' => '已从继续观看中移除',
			'messages.errorLoading' => ({required Object error}) => '错误: ${error}',
			'messages.fileInfoNotAvailable' => '文件信息不可用',
			'messages.errorLoadingFileInfo' => ({required Object error}) => '加载文件信息时出错: ${error}',
			'messages.errorLoadingSeries' => '加载系列时出错',
			'messages.errorLoadingSeason' => '加载季时出错',
			'messages.musicNotSupported' => '尚不支持播放音乐',
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
			'messages.noEpisodesFound' => '在第一季中未找到剧集',
			'messages.noEpisodesFoundGeneral' => '未找到剧集',
			'messages.noResultsFound' => '未找到结果',
			'messages.sleepTimerSet' => ({required Object label}) => '睡眠定时器已设置为 ${label}',
			'messages.noItemsAvailable' => '没有可用的项目',
			'messages.failedToCreatePlayQueueNoItems' => '创建播放队列失败 - 没有项目',
			'messages.failedPlayback' => ({required Object action, required Object error}) => '无法${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => '正在切换到兼容的播放器...',
			'messages.logsUploaded' => 'Logs uploaded',
			'messages.logsUploadFailed' => 'Failed to upload logs',
			'messages.logId' => 'Log ID',
			'subtitlingStyling.stylingOptions' => '样式选项',
			'subtitlingStyling.fontSize' => '字号',
			'subtitlingStyling.textColor' => '文本颜色',
			'subtitlingStyling.borderSize' => '边框大小',
			'subtitlingStyling.borderColor' => '边框颜色',
			'subtitlingStyling.backgroundOpacity' => '背景不透明度',
			'subtitlingStyling.backgroundColor' => '背景颜色',
			'subtitlingStyling.position' => 'Position',
			'mpvConfig.title' => 'MPV 配置',
			'mpvConfig.description' => '高级视频播放器设置',
			'mpvConfig.properties' => '属性',
			'mpvConfig.presets' => '预设',
			'mpvConfig.noProperties' => '未配置任何属性',
			'mpvConfig.noPresets' => '没有保存的预设',
			'mpvConfig.addProperty' => '添加属性',
			'mpvConfig.editProperty' => '编辑属性',
			'mpvConfig.deleteProperty' => '删除属性',
			'mpvConfig.propertyKey' => '属性键',
			'mpvConfig.propertyKeyHint' => '例如 hwdec, demuxer-max-bytes',
			'mpvConfig.propertyValue' => '属性值',
			'mpvConfig.propertyValueHint' => '例如 auto, 256000000',
			'mpvConfig.saveAsPreset' => '保存为预设...',
			'mpvConfig.presetName' => '预设名称',
			'mpvConfig.presetNameHint' => '输入此预设的名称',
			'mpvConfig.loadPreset' => '加载',
			'mpvConfig.deletePreset' => '删除',
			'mpvConfig.presetSaved' => '预设已保存',
			'mpvConfig.presetLoaded' => '预设已加载',
			'mpvConfig.presetDeleted' => '预设已删除',
			'mpvConfig.confirmDeletePreset' => '确定要删除此预设吗？',
			'mpvConfig.confirmDeleteProperty' => '确定要删除此属性吗？',
			'mpvConfig.entriesCount' => ({required Object count}) => '${count} 条目',
			'dialog.confirmAction' => '确认操作',
			'discover.title' => '发现',
			'discover.switchProfile' => '切换用户',
			'discover.noContentAvailable' => '没有可用内容',
			'discover.addMediaToLibraries' => '请向你的媒体库添加一些媒体',
			'discover.continueWatching' => '继续观看',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => '概述',
			'discover.cast' => '演员表',
			'discover.extras' => '预告片与花絮',
			'discover.seasons' => '季数',
			'discover.studio' => '制作公司',
			'discover.rating' => '年龄分级',
			'discover.episodeCount' => ({required Object count}) => '${count} 集',
			'discover.watchedProgress' => ({required Object watched, required Object total}) => '已观看 ${watched}/${total} 集',
			'discover.movie' => '电影',
			'discover.tvShow' => '电视剧',
			'discover.minutesLeft' => ({required Object minutes}) => '剩余 ${minutes} 分钟',
			'errors.searchFailed' => ({required Object error}) => '搜索失败: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => '加载 ${context} 时连接超时',
			'errors.connectionFailed' => '无法连接到 Plex 服务器',
			'errors.failedToLoad' => ({required Object context, required Object error}) => '无法加载 ${context}: ${error}',
			'errors.noClientAvailable' => '没有可用客户端',
			'errors.authenticationFailed' => ({required Object error}) => '验证失败: ${error}',
			'errors.couldNotLaunchUrl' => '无法打开授权 URL',
			'errors.pleaseEnterToken' => '请输入一个令牌',
			'errors.invalidToken' => '令牌无效',
			'errors.failedToVerifyToken' => ({required Object error}) => '无法验证令牌: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => '无法切换到 ${displayName}',
			'libraries.title' => '媒体库',
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
			'libraries.thisLibraryIsEmpty' => '此媒体库为空',
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
			'libraries.groupings.all' => '全部',
			'libraries.groupings.movies' => '电影',
			'libraries.groupings.shows' => '剧集',
			'libraries.groupings.seasons' => '季',
			'libraries.groupings.episodes' => '集',
			'libraries.groupings.folders' => '文件夹',
			'about.title' => '关于',
			'about.openSourceLicenses' => '开源许可证',
			'about.versionLabel' => ({required Object version}) => '版本 ${version}',
			'about.appDescription' => '一款精美的 Flutter Plex 客户端',
			'about.viewLicensesDescription' => '查看第三方库的许可证',
			'serverSelection.allServerConnectionsFailed' => '无法连接到任何服务器。请检查你的网络并重试。',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => '未找到 ${username} (${email}) 的服务器',
			'serverSelection.failedToLoadServers' => ({required Object error}) => '无法加载服务器: ${error}',
			'hubDetail.title' => '标题',
			'hubDetail.releaseYear' => '发行年份',
			'hubDetail.dateAdded' => '添加日期',
			'hubDetail.rating' => '评分',
			'hubDetail.noItemsFound' => '未找到项目',
			'logs.clearLogs' => '清除日志',
			'logs.copyLogs' => '复制日志',
			'logs.uploadLogs' => 'Upload Logs',
			'logs.error' => '错误:',
			'logs.stackTrace' => '堆栈跟踪 (Stack Trace):',
			'licenses.relatedPackages' => '相关软件包',
			'licenses.license' => '许可证',
			'licenses.licenseNumber' => ({required Object number}) => '许可证 ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} 个许可证',
			'navigation.libraries' => '媒体库',
			'navigation.downloads' => '下载',
			'navigation.liveTv' => '电视直播',
			'liveTv.title' => '电视直播',
			'liveTv.channels' => '频道',
			'liveTv.guide' => '节目指南',
			'liveTv.noChannels' => '没有可用的频道',
			'liveTv.noDvr' => '没有服务器配置了DVR',
			'liveTv.tuneFailed' => '无法调谐频道',
			'liveTv.loading' => '正在加载频道...',
			'liveTv.nowPlaying' => '正在播放',
			'liveTv.noPrograms' => '没有可用的节目数据',
			'liveTv.channelNumber' => ({required Object number}) => '频道 ${number}',
			'liveTv.live' => '直播',
			'liveTv.hd' => '高清',
			'liveTv.premiere' => '新',
			'liveTv.reloadGuide' => '重新加载节目指南',
			'liveTv.allChannels' => '所有频道',
			'liveTv.now' => '现在',
			'liveTv.today' => '今天',
			'liveTv.midnight' => '午夜',
			'liveTv.overnight' => '凌晨',
			'liveTv.morning' => '上午',
			'liveTv.daytime' => '白天',
			'liveTv.evening' => '晚上',
			'liveTv.lateNight' => '深夜',
			'liveTv.whatsOn' => '正在播出',
			_ => null,
		} ?? switch (path) {
			'liveTv.watchChannel' => '观看频道',
			'downloads.title' => '下载',
			'downloads.manage' => '管理',
			'downloads.tvShows' => '电视剧',
			'downloads.movies' => '电影',
			'downloads.noDownloads' => '暂无下载',
			'downloads.noDownloadsDescription' => '下载的内容将在此处显示以供离线观看',
			'downloads.downloadNow' => '下载',
			'downloads.deleteDownload' => '删除下载',
			'downloads.retryDownload' => '重试下载',
			'downloads.downloadQueued' => '下载已排队',
			'downloads.episodesQueued' => ({required Object count}) => '${count} 集已加入下载队列',
			'downloads.downloadDeleted' => '下载已删除',
			'downloads.deleteConfirm' => ({required Object title}) => '确定要删除 "${title}" 吗？下载的文件将从您的设备中删除。',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => '正在删除 ${title}... (${current}/${total})',
			'downloads.noDownloadsTree' => '暂无下载',
			'downloads.pauseAll' => '全部暂停',
			'downloads.resumeAll' => '全部继续',
			'downloads.deleteAll' => '全部删除',
			'playlists.title' => '播放列表',
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
			'playlists.createNewPlaylist' => '创建新播放列表',
			'playlists.errorCreating' => '创建播放列表失败',
			'playlists.errorDeleting' => '删除播放列表失败',
			'playlists.errorLoading' => '加载播放列表失败',
			'playlists.errorAdding' => '添加到播放列表失败',
			'playlists.errorReordering' => '重新排序播放列表项目失败',
			'playlists.errorRemoving' => '从播放列表中移除失败',
			'playlists.playlist' => '播放列表',
			'collections.title' => '合集',
			'collections.collection' => '合集',
			'collections.empty' => '合集为空',
			'collections.unknownLibrarySection' => '无法删除：未知的媒体库分区',
			'collections.deleteCollection' => '删除合集',
			'collections.deleteConfirm' => ({required Object title}) => '确定要删除"${title}"吗？此操作无法撤销。',
			'collections.deleted' => '已删除合集',
			'collections.deleteFailed' => '删除合集失败',
			'collections.deleteFailedWithError' => ({required Object error}) => '删除合集失败：${error}',
			'collections.failedToLoadItems' => ({required Object error}) => '加载合集项目失败：${error}',
			'collections.selectCollection' => '选择合集',
			'collections.createNewCollection' => '创建新合集',
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
			'watchTogether.enterCodeHint' => '输入8位代码',
			'watchTogether.pasteFromClipboard' => '从剪贴板粘贴',
			'watchTogether.pleaseEnterCode' => '请输入会话代码',
			'watchTogether.codeMustBe8Chars' => '会话代码必须是8个字符',
			'watchTogether.joinInstructions' => '输入主持人分享的会话代码以加入他们的观看会话。',
			'watchTogether.failedToCreate' => '创建会话失败',
			'watchTogether.failedToJoin' => '加入会话失败',
			'watchTogether.sessionCodeCopied' => '会话代码已复制到剪贴板',
			'watchTogether.relayUnreachable' => '无法连接到中继服务器。这可能是由于您的网络运营商屏蔽了连接。您仍然可以尝试，但一起观看功能可能无法正常使用。',
			'watchTogether.reconnectingToHost' => '正在重新连接到主持人...',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} 加入了',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} 离开了',
			'shaders.title' => '着色器',
			'shaders.noShaderDescription' => '无视频增强',
			'shaders.nvscalerDescription' => 'NVIDIA 图像缩放，使视频更清晰',
			'shaders.qualityFast' => '快速',
			'shaders.qualityHQ' => '高质量',
			'shaders.mode' => '模式',
			'companionRemote.title' => 'Companion Remote',
			'companionRemote.connectToDevice' => '连接到设备',
			'companionRemote.hostRemoteSession' => '创建远程会话',
			'companionRemote.controlThisDevice' => '使用手机控制此设备',
			'companionRemote.remoteControl' => '远程控制',
			'companionRemote.controlDesktop' => '控制桌面设备',
			'companionRemote.connectedTo' => ({required Object name}) => '已连接到 ${name}',
			'companionRemote.session.creatingSession' => '正在创建远程会话...',
			'companionRemote.session.failedToCreate' => '创建远程会话失败：',
			'companionRemote.session.noSession' => '没有可用的会话',
			'companionRemote.session.scanQrCode' => '扫描 QR 码',
			'companionRemote.session.orEnterManually' => '或手动输入',
			'companionRemote.session.hostAddress' => '主机地址',
			'companionRemote.session.sessionId' => '会话 ID',
			'companionRemote.session.pin' => 'PIN',
			'companionRemote.session.connected' => '已连接',
			'companionRemote.session.waitingForConnection' => '等待连接中...',
			'companionRemote.session.usePhoneToControl' => '使用移动设备控制此应用',
			'companionRemote.session.copiedToClipboard' => ({required Object label}) => '${label}已复制到剪贴板',
			'companionRemote.session.copyToClipboard' => '复制到剪贴板',
			'companionRemote.session.newSession' => '新建会话',
			'companionRemote.session.minimize' => '最小化',
			'companionRemote.pairing.scan' => '扫描',
			'companionRemote.pairing.manual' => '手动',
			'companionRemote.pairing.pairWithDesktop' => '与桌面配对',
			'companionRemote.pairing.enterSessionDetails' => '输入桌面设备上显示的会话信息',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.sessionIdHint' => '输入8位会话 ID',
			'companionRemote.pairing.pinHint' => '输入6位 PIN',
			'companionRemote.pairing.connecting' => '连接中...',
			'companionRemote.pairing.tips' => '提示',
			'companionRemote.pairing.tipDesktop' => '在桌面上打开 Plezy，并从设置或菜单中启用 Companion Remote',
			'companionRemote.pairing.tipScan' => '使用扫描选项卡扫描桌面上的 QR 码以快速配对',
			'companionRemote.pairing.tipWifi' => '请确保两台设备连接到同一个 WiFi 网络',
			'companionRemote.pairing.cameraPermissionRequired' => '扫描 QR 码需要相机权限。\n请在设备设置中授予相机访问权限。',
			'companionRemote.pairing.cameraError' => ({required Object error}) => '无法启动相机：${error}',
			'companionRemote.pairing.scanInstruction' => '将相机对准桌面上显示的 QR 码',
			'companionRemote.pairing.invalidQrCode' => '无效的 QR 码格式',
			'companionRemote.pairing.validationHostRequired' => '请输入主机地址',
			'companionRemote.pairing.validationHostFormat' => '格式必须为 IP:端口（例如 192.168.1.100:48632）',
			'companionRemote.pairing.validationSessionIdRequired' => '请输入会话 ID',
			'companionRemote.pairing.validationSessionIdLength' => '会话 ID 必须为8个字符',
			'companionRemote.pairing.validationPinRequired' => '请输入 PIN',
			'companionRemote.pairing.validationPinLength' => 'PIN 必须为6位数字',
			'companionRemote.pairing.connectionTimedOut' => '连接超时。请检查会话 ID 和 PIN。',
			'companionRemote.pairing.sessionNotFound' => '找不到会话。请检查您的凭据。',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => '连接失败：${error}',
			'companionRemote.remote.disconnectConfirm' => '是否要断开远程会话的连接？',
			'companionRemote.remote.reconnecting' => '重新连接中...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => '第 ${current} 次尝试，共 5 次',
			'companionRemote.remote.retryNow' => '立即重试',
			'companionRemote.remote.connectionError' => '连接错误',
			'companionRemote.remote.notConnected' => '未连接',
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
			'videoSettings.playbackSettings' => '播放设置',
			'videoSettings.playbackSpeed' => '播放速度',
			'videoSettings.sleepTimer' => '睡眠定时器',
			'videoSettings.audioSync' => '音频同步',
			'videoSettings.subtitleSync' => '字幕同步',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => '音频输出',
			'videoSettings.performanceOverlay' => '性能监控',
			'videoSettings.audioPassthrough' => '音频直通',
			'externalPlayer.title' => '外部播放器',
			'externalPlayer.useExternalPlayer' => '使用外部播放器',
			'externalPlayer.useExternalPlayerDescription' => '在外部应用中打开视频，而不是使用内置播放器',
			'externalPlayer.selectPlayer' => '选择播放器',
			'externalPlayer.systemDefault' => '系统默认',
			'externalPlayer.addCustomPlayer' => '添加自定义播放器',
			'externalPlayer.playerName' => '播放器名称',
			'externalPlayer.playerCommand' => '命令',
			'externalPlayer.playerPackage' => '包名',
			'externalPlayer.playerUrlScheme' => 'URL 方案',
			'externalPlayer.customPlayer' => '自定义播放器',
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
			'metadataEdit.selectPoster' => '选择海报',
			'metadataEdit.selectBackground' => '选择背景',
			'metadataEdit.fromUrl' => '从 URL',
			'metadataEdit.uploadFile' => '上传文件',
			'metadataEdit.enterImageUrl' => '输入图片 URL',
			'metadataEdit.imageUrl' => '图片 URL',
			'metadataEdit.metadataUpdated' => '元数据已更新',
			'metadataEdit.metadataUpdateFailed' => '元数据更新失败',
			'metadataEdit.artworkUpdated' => '封面图片已更新',
			'metadataEdit.artworkUpdateFailed' => '封面图片更新失败',
			'metadataEdit.noArtworkAvailable' => '没有可用的封面图片',
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
			_ => null,
		};
	}
}
