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
	@override late final Translations$appIcon$zh appIcon = Translations$appIcon$zh.internal(_root);
	@override late final Translations$auth$zh auth = Translations$auth$zh.internal(_root);
	@override late final Translations$common$zh common = Translations$common$zh.internal(_root);
	@override late final Translations$screens$zh screens = Translations$screens$zh.internal(_root);
	@override late final Translations$update$zh update = Translations$update$zh.internal(_root);
	@override late final Translations$settings$zh settings = Translations$settings$zh.internal(_root);
	@override late final Translations$themeEditor$zh themeEditor = Translations$themeEditor$zh.internal(_root);
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
	@override late final Translations$accountPreferences$zh accountPreferences = Translations$accountPreferences$zh.internal(_root);
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
	@override late final Translations$streaming$zh streaming = Translations$streaming$zh.internal(_root);
	@override late final Translations$addServer$zh addServer = Translations$addServer$zh.internal(_root);
	@override late final Translations$cast$zh cast = Translations$cast$zh.internal(_root);
	@override late final Translations$automation$zh automation = Translations$automation$zh.internal(_root);
	@override late final Translations$notifications$zh notifications = Translations$notifications$zh.internal(_root);
	@override late final Translations$appAccess$zh appAccess = Translations$appAccess$zh.internal(_root);
	@override late final Translations$detail$zh detail = Translations$detail$zh.internal(_root);
	@override late final Translations$watchLink$zh watchLink = Translations$watchLink$zh.internal(_root);
	@override late final Translations$homeLayout$zh homeLayout = Translations$homeLayout$zh.internal(_root);
	@override late final Translations$platform$zh platform = Translations$platform$zh.internal(_root);
	@override late final Translations$universalMedia$zh universalMedia = Translations$universalMedia$zh.internal(_root);
	@override late final Translations$fileSources$zh fileSources = Translations$fileSources$zh.internal(_root);
	@override late final Translations$lending$zh lending = Translations$lending$zh.internal(_root);
	@override late final Translations$audiobook$zh audiobook = Translations$audiobook$zh.internal(_root);
	@override late final Translations$sourceSetup$zh sourceSetup = Translations$sourceSetup$zh.internal(_root);
	@override late final Translations$comics$zh comics = Translations$comics$zh.internal(_root);
	@override late final Translations$games$zh games = Translations$games$zh.internal(_root);
	@override late final Translations$deepLinks$zh deepLinks = Translations$deepLinks$zh.internal(_root);
}

// Path: app
class Translations$app$zh extends Translations$app$en {
	Translations$app$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: appIcon
class Translations$appIcon$zh extends Translations$appIcon$en {
	Translations$appIcon$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '应用图标';
	@override String get defaultIcon => '默认';
	@override String get current => '当前图标';
	@override String get locked => '终身访问需要';
	@override String get lockedHint => '启动 7 天试用或终身解锁 PlezyNG 以使用替代图标。';
	@override String get changeFailed => '无法更改应用图标';
	@override String get launcherHint => '离开 PlezyNG 后，新图标将显示在主屏幕上。';
	@override String get tvLauncherHint => '离开 PlezyNG 后将显示新横幅。在电视重启之前，Android TV 可能仍会显示旧横幅。';
	@override late final Translations$appIcon$names$zh names = Translations$appIcon$names$zh.internal(_root);
	@override String get description => '选择由您的设备启动器显示的图标. 预览显示每个选项看起来如何。';
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
	@override String get quickConnect => 'Quick Connect';
	@override String get useQuickConnect => '使用 Quick Connect';
	@override String get quickConnectInstructions => '在 Jellyfin 中打开 Quick Connect 并输入此代码。';
	@override String get quickConnectWaiting => '等待批准…';
	@override String get quickConnectCancel => '取消';
	@override String get quickConnectExpired => 'Quick Connect 已过期。请重试。';
	@override String get localDataRecoveryRequired => 'PlezyNG 无法安全恢复本地登录状态和待处理的播放数据。请重新登录。';
	@override String get pinCheckRejected => 'Plex PIN 检查被拒绝';
	@override String get connectToDirectPlex => '连接到本地服务器 Plex';
}

// Path: common
class Translations$common$zh extends Translations$common$en {
	Translations$common$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get cancel => '取消';
	@override String get save => '保存';
	@override String get close => '关闭';
	@override String get closeMiniPlayer => '附近小型玩家';
	@override String get closeWorkspaceWindow => '附近窗口';
	@override String get returnToFullView => '回到全景';
	@override String get manageMediaSessions => '管理媒体会议';
	@override String get hideMediaSessions => '隐藏媒体会议';
	@override String get mediaSessions => '媒體會議';
	@override String get mediaSessionsHint => '选择会话可将其切换到前台。停放会隐藏窗口但保持会话运行。返回会在完整视图中打开会话；关闭则结束会话。';
	@override String get sessionInWorkspace => '在工作场所';
	@override String get sessionParked => '停车';
	@override String get sessionFullscreen => '全屏幕';
	@override String get switchToNextWindow => '与下一个窗口交换';
	@override String get moveWindow => '移动窗口';
	@override String get finishMovingWindow => '结束移动窗口';
	@override String get moveWindowHint => '长压和拖动窗口移动它. 这种控制也允许箭头密钥的运动。';
	@override String get movingWindowHelp => '拖到移动 · 投键调整 · 输入存储器 · 逃避取消';
	@override String get resizeWindow => '修复窗口';
	@override String get resizeWindowHint => '拖这个手套或使用箭头键重新调整窗口。';
	@override String get workspaceWindowHint => '使用移动控件，或长按并拖动窗口来移动。使用调整大小手柄来调整窗口大小。';
	@override String get workspacePaneHint => '选择这个面板以集中它. 使用其全屏控制来扩展。';
	@override String workspaceWindowLabel({required Object title}) => '會議窗口: ${title}';
	@override String get workspaceTitleHint => '选择以聚焦窗口。拖动标题栏来移动；使用全屏按钮展开。';
	@override String get moveToSessionTray => '转到Session Tray';
	@override String get moveToSessionTrayHint => '打开此会议可用,而不显示其窗口。';
	@override String get closeSessionHint => '关闭此窗口并结束会议。';
	@override String get sideBySideLayout => '交换到侧面布局';
	@override String get floatingWindows => '转换为浮动窗口';
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
	@override String get options => '选项';
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
	@override String get supportDeveloper => '支持 PlezyNG';
	@override String get supportDeveloperDescription => '捐赠以支持开发';
	@override String get lifetimeAccess => 'PlezyNG 终身访问';
	@override String get language => '语言';
	@override String get theme => '主题';
	@override String get appearance => '外观';
	@override String get detailPage => '详细页面';
	@override String get themeSongsEnabled => '演奏主题歌曲';
	@override String get themeSongsEnabledDescription => '播放可用的主题歌曲,同时查看媒体细节。';
	@override String get themeSongVolume => '主题歌曲 卷';
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
	@override String get secondsShort => '秒';
	@override String get minutesShort => '分钟';
	@override String durationHint({required Object min, required Object max}) => '输入时长（${min}–${max}）';
	@override String get systemTheme => '系统';
	@override String get lightTheme => '浅色';
	@override String get darkTheme => '深色';
	@override String get oledTheme => 'OLED';
	@override String get emberTheme => '余烬';
	@override String get glacierTheme => '冰川';
	@override String get forestTheme => '森林';
	@override String get plumTheme => '梅子';
	@override String get paperTheme => '纸张';
	@override String get libraryDensity => '媒体库密度';
	@override String get displayScale => '界面缩放';
	@override String get compact => '紧凑';
	@override String get comfortable => '舒适';
	@override String get gridSpacing => '网格间距';
	@override String get gridSpacingTight => '紧密';
	@override String get gridSpacingNormal => '标准';
	@override String get gridSpacingSpacious => '宽松';
	@override String get tvCornerSpotlightBackdrop => '右上角聚焦背景图';
	@override String get tvCornerSpotlightBackdropDescription => '在右上角显示精选内容图片，而不是铺满整个屏幕';
	@override String get viewMode => '视图模式';
	@override String get gridView => '网格视图';
	@override String get listView => '列表视图';
	@override String get showHeroSection => '显示精选内容区';
	@override String get showHomeBackdrop => '展示家居背景艺术作品';
	@override String get showHomeBackdropDescription => '展示大型艺术作品背后展示的家庭行';
	@override String get contentScreensaverEnabled => '内容屏幕保存';
	@override String get contentScreensaverEnabledDescription => '显示全屏艺术作品,应用程序已变成 idle';
	@override String get contentScreensaverDelay => '屏幕保存后启动';
	@override String get contentScreensaverLibraries => '图书馆屏幕';
	@override String get contentScreensaverLibrariesDescription => '选择要用于屏幕保护程序图片的媒体库。如果未选择任何媒体库，则会使用所有媒体库的图片。';
	@override String get contentScreensaverAllLibraries => '所有图书馆';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} 图书馆 选择';
	@override String get contentScreensaverNoLibraries => '没有连接媒体图书馆可用。';
	@override String get contentScreensaverDismissHint => '按下任何按钮或按下取消';
	@override String get newEpisodeNotifications => '新事件通知';
	@override String get newEpisodeNotificationsDescription => '警告当新集添加到一个节目你被抓住时,检查 Plezy 是开放的。';
	@override String get continueWatchingRowSize => '继续观看 序列大小';
	@override String continueWatchingRowSizeValue({required Object label}) => '${label} 卡片';
	@override String get rowSizeCompact => '紧凑';
	@override String get rowSizeStandard => '標準';
	@override String get rowSizeLarge => '大';
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
	@override String get showWatchedIndicators => '显示已观看标记';
	@override String get showWatchedIndicatorsDescription => '在已观看的电影、剧集和单集上显示对勾标记';
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
	@override String get playbackBuffer => '播放缓冲';
	@override String get playbackBufferAuto => '自动（推荐）';
	@override String get playbackBufferLarge => '大';
	@override String get playbackBufferExtraLarge => '特大';
	@override String get playbackBufferDescription => '针对不稳定的连接缓冲更多内容。也受缓冲大小限制。';
	@override String get streamBufferSize => '布格大小';
	@override String streamBufferSizeValue({required Object size}) => '${size} MB';
	@override String get streamBufferSizeDescription => '直接播放时预先加载的视频量。转码播放以服务器自身的转码缓冲区为限。0 = 自动';
	@override String get streamBufferSizeExoNote => '取代 Playback Buffer 设置时,在应用程序的内存限制中半个';
	@override String get streamBufferMegabytes => '梅加比特';
	@override String get defaultQualityTitle => '默认画质';
	@override String get cellularQualityTitle => '移动网络默认画质';
	@override String get remoteQualityTitle => '远程播放质量';
	@override String get remoteQualitySameAsDefault => '与假设质量相同';
	@override String get cellularQualitySameAsDefault => '与默认画质相同';
	@override String get directPlayCoveredQuality => '以原始画质播放较小视频';
	@override String get directPlayCoveredQualityDescription => '已在画质限制内的视频直接播放，而非转码';
	@override String get videoCodecs => '视频编解码器';
	@override String get videoCodecsDescription => '未勾选的编解码器将由服务器转码';
	@override String get videoCodecsAlwaysAccepted => '始终接受';
	@override String get musicQualityTitle => '音乐音质';
	@override String get subtitleStyling => '字幕样式';
	@override String get subtitleStylingDescription => '调整字幕外观';
	@override String get smallSkipDuration => '短跳过时长';
	@override String get largeSkipDuration => '长跳过时长';
	@override String get rewindOnResume => '恢复时回退';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(seconds,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)}秒钟',
	);
	@override String get defaultSleepTimer => '默认睡眠定时器';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(minutes,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)}分钟',
	);
	@override String get rememberTrackSelections => '记住每部剧集或电影的音轨选择';
	@override String get chooseTracksBeforePlayback => '选择音频和字幕在播放前';
	@override String get chooseTracksBeforePlaybackDescription => '在每个视频开始之前,选择源音频和子标题跟踪。';
	@override String get alwaysShowSubtitlesOnDevice => '总是显示该设备上的字幕';
	@override String get alwaysShowSubtitlesOnDeviceDescription => '当服务器没有选定的子标题时,选择一个路径,而此事永远不会改变服务器的偏好。';
	@override String get autoDownloadPreferredSubtitle => '福克斯缺少偏好语言字幕';
	@override String get autoDownloadPreferredSubtitleDescription => '选择您所需的语言中的可用字幕,当地选择;如果没有字幕,请服务器在支持时查找一个字幕;选项将留在该设备上。';
	@override String get rememberTrackSelectionsDescription => '分别记住每部内容的音频和字幕选择';
	@override String get rememberTrackSelectionsBackendRule => 'Plex 会按文件将每个选择保存在服务器上；Jellyfin 还会开启账户的“记住选择”；Emby 不支持';
	@override String get followServerTrackSelections => '使用服务器为每集选择的轨道';
	@override String get followServerTrackSelectionsDescription => '切换剧集时，应用服务器上为该集选择的音频和字幕，而不是沿用当前选择';
	@override String get resumeMusicOnLaunch => '记住音乐会话';
	@override String get resumeMusicOnLaunchDescription => '应用启动时，将上次播放的歌曲在停止位置以暂停状态打开';
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
	@override String get watchTogetherRelayDescription => '除非自行设置，否则使用公共 Open Watch Party 中继服务器';
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
	@override String get importSettingsInvalidFile => '此文件不是有效的 PlezyNG 设置导出';
	@override String get importSettingsNoUser => '导入设置前请先登录';
	@override String get cloudBackup => '云备份';
	@override String get cloudBackupDescription => '通过 HTTPS 将可迁移的设置备份到 WebDAV 地址。服务器连接和登录凭据保留在此设备上。';
	@override String get cloudBackupUrl => 'WebDAV JSON 文件 URL';
	@override String get cloudBackupUsername => '用户名';
	@override String get cloudBackupPassword => '密码';
	@override String get cloudBackupSaved => '云备份目的地保存';
	@override String get cloudBackupNow => '回归现在';
	@override String get cloudBackupComplete => '设置备份上传';
	@override String get cloudBackupRestore => '恢复备份';
	@override String get cloudBackupRestoreConfirm => '此将取代该设备上的相匹配移动设置。';
	@override String get cloudBackupRestored => '從雲端儲備恢復的設定';
	@override String get shortcutsReset => '快捷键已重置为默认值';
	@override String get resetShortcutsConfirm => '这将用默认快捷键替换你的自定义快捷键。继续吗？';
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
	@override String get autoPlayAndSkip => '自动播放与跳过';
	@override String get autoPlayNextEpisode => '自动播放下一集';
	@override String get autoPlayNextEpisodeDescription => '当前剧集结束时自动播放下一集';
	@override String get shuffleStartsFromBeginning => '随机播放从头开始';
	@override String get shuffleStartsFromBeginningDescription => '随机播放时每集从头开始播放，而非续播';
	@override String get plexCinemaPreRoll => '使用服务器电影输入';
	@override String get plexCinemaPreRollDescription => '在电影开始之前,播放配置的Plex预角色或Jellyfin和Emby输入。';
	@override String get playNextCountdown => '播放下一集倒计时';
	@override String get playNextCountdownImmediate => '立即播放';
	@override String get skipIntroMode => '跳过片头';
	@override String get skipIntroModeOffDescription => '正常播放片头，不显示跳过按钮';
	@override String get skipIntroModeButtonDescription => '片头开始时显示跳过按钮';
	@override String get skipIntroModeAutoDescription => '在下方设定的延迟后自动跳过片头';
	@override String get skipCreditsMode => '跳过片尾';
	@override String get skipCreditsModeOffDescription => '正常播放片尾，不显示跳过按钮';
	@override String get skipCreditsModeButtonDescription => '片尾开始时显示跳过按钮';
	@override String get skipCreditsModeAutoDescription => '自动跳过片尾并播放下一集';
	@override String get skipAdsMode => '滑雪广告';
	@override String get skipAdsModeOffDescription => '正常播放被发现的广告,没有跳跃按钮';
	@override String get skipAdsModeButtonDescription => '显示在 Plex 检测广告时,将按钮转';
	@override String get skipAdsModeAutoDescription => '下面的延迟后自动删除被发现的广告';
	@override String get musicPlayback => '音乐播放';
	@override String get musicSweetFades => '甜蜜的Fades';
	@override String get musicSweetFadesDescription => '音乐在轨道边缘时,当Plex有声音数据时,音乐的播放保持不变。';
	@override String get skipMarkerModeOff => '关闭';
	@override String get skipMarkerModeButton => '显示按钮';
	@override String get skipMarkerModeAuto => '自动';
	@override String get forceSkipMarkerFallback => '强制使用备用标记';
	@override String get forceSkipMarkerFallbackDescription => '即使 Plex 有标记，也使用章节标题模式';
	@override String get theIntroDbFallback => '使用 TheIntroDB 作为 Intro Fallback';
	@override String get theIntroDbFallbackDescription => '仅在服务器没有片头标记时使用社区提供的时间点。匹配结果可能因发行版本而异。';
	@override String get autoSkipDelay => '自动跳过延迟';
	@override String autoSkipDelayDescription({required Object seconds}) => '自动跳过前等待 ${seconds} 秒';
	@override String get introPattern => '片头标记模式';
	@override String get introPatternDescription => '用于匹配章节标题中片头标记的正则表达式';
	@override String get creditsPattern => '片尾标记模式';
	@override String get creditsPatternDescription => '用于匹配章节标题中片尾标记的正则表达式';
	@override String get prerolls => '片前视频';
	@override String get playPrerollsBeforeMovies => '电影前玩预告片';
	@override String get playPrerollsBeforeMoviesDescription => '在每部電影之前播放下面的選項中的偶然剪輯,按一下回來跳。';
	@override String get prerollLibrary => '普雷罗图书馆';
	@override String get prerollLibraryNotSet => '未设置';
	@override String get prerollLibraryNoneFound => '您服务器上没有找到图书馆。';
	@override String get prerollSelection => '选择的预算';
	@override String get prerollSelectionPickLibraryFirst => '首先选择图书馆';
	@override String get prerollSelectionNoneSelected => '没有选定的特权';
	@override String prerollSelectionCount({required Object count}) => '已选 ${count} 项';
	@override String get prerollItemPicker => '选择预算';
	@override String get prerollItemPickerLoadFailed => '我不能从这本图书馆上传任何东西。';
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
	@override String get autoDownloadContinueWatching => '自动下载 继续观看';
	@override String get autoDownloadContinueWatchingDescription => '保持在您的继续观看盾牌上下载的项目,并在他们离开盾牌后删除它们';
	@override String get downloadQuality => '下载质量';
	@override String get downloadQualityDescription => 'Plex 在其下载中编制转换副本. Jellyfin 和 Emby 转码,而文件下载; 中断的转换可能需要重新启动。';
	@override String get askDownloadQualityEachTime => '选择每个下载的质量';
	@override String get askDownloadQualityEachTimeDescription => '显示优质点数,在每次视频下载之前';
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
	@override String get companionRemoteServerStartFailed => '无法启动远程控制服务器';
	@override String get companionRemoteServerStopFailed => '无法停止远程控制服务器';
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
	@override String get tunneledPlaybackDescription => '使用视频隧道模式。若播放 HDR 内容时出现黑屏或画面卡顿，请将其关闭。';
	@override String get audioPassthrough => '音频直通';
	@override String get audioPassthroughDescription => '将 Dolby/DTS 音频不经重新编码直接发送到功放或电视，保留环绕声。如果没有声音，请关闭。';
	@override String get audioPassthroughDescriptionApple => '对 Dolby Digital Plus（含 Atmos）使用 Apple 原生 Dolby 解码器。DTS 和 TrueHD 仍以多声道 PCM 播放。如果没有声音，请关闭。';
	@override String get audioPassthroughDescriptionAppleSpatial => '对 Dolby Digital Plus（含 Atmos）使用 Apple 原生 Dolby 解码器。在 iOS、iPadOS 和 tvOS 26 或更高版本上，TrueHD Atmos 和 DTS:X 以空间音频播放。其他 DTS 和 TrueHD 音轨以多声道 PCM 播放。如果没有声音，请关闭。';
	@override String get audioPassthroughOverriddenByNormalization => '响度标准化开启时停用';
	@override String get audioChannelLimit => '音频声道';
	@override String get audioChannelLimitDescription => '为无法播放所有声道的扬声器、耳机或 HDMI 设备下混解码后的音频';
	@override String get audioChannelLimitOriginal => '原始';
	@override String get audioChannelLimitOriginalDescription => '播放音轨中的所有声道';
	@override String get audioChannelLimitSurround51 => '最多 5.1';
	@override String get audioChannelLimitSurround51Description => '为仅支持 5.1 PCM 的电视和功放将 7.1 下混为 5.1。不影响直通。';
	@override String get audioChannelLimitStereo => '立体声';
	@override String get audioChannelLimitStereoDescription => '下混为双声道，适用于立体声扬声器或耳机。将关闭直通。';
	@override String get downmixCenterBoost => '中置声道增强';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => '增强（dB）';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => '下混时音量标准化';
	@override String get audioDownmixNormalizeDescription => '降低混音电平以防止削波。关闭可保持原始音量（大音量场景可能失真）。';
	@override String get dvConversionMode => 'Dolby Vision 转换';
	@override String get dvConversionModeDescription => '选择如何处理 Dolby Vision Profile 7 文件。';
	@override String get dvConversionAuto => '自动';
	@override String get dvConversionNative => '原生 / 禁用';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => '使用设备能力检测和常规回退机制';
	@override String get dvConversionNativeDescription => '强制原生 DV7 并禁止重试 DV 转换';
	@override String get dvConversionDv81Description => '强制内联 RPU 转换为 Dolby Vision Profile 8.1';
	@override String get dvConversionHevcStripDescription => '移除 Dolby Vision RPU/EL 层并呈现普通 HEVC';
	@override String get experimentalDolbyVision => '实验性 Dolby Vision';
	@override String get experimentalDolbyVisionDescription => '下次播放时使用实验性 FEL 渲染器。需要单独构建的播放引擎。';
	@override String get dvExperimentUnavailableDescription => '此实验目前仅支持 Linux。';
	@override String get dvCompatibilityFallback => '兼容性回退';
	@override String get dvCompatibilityFallbackDescription => '如果实验无法启动，则使用标准渲染器。FEL 数据可能会丢失。';
	@override String get dvExperimentDiagnostics => '视频实验日志';
	@override String get dvExperimentDiagnosticsDescription => '在下次播放时启用详细的播放器日志。';
	@override String get disableDolbyVision => '禁用 Dolby Vision';
	@override String get disableDolbyVisionDescription => '文件包含 HDR10 或 HLG 层时，改为播放该层而非 Dolby Vision';
	@override String get hdrSdrConversion => 'HDR 转 SDR';
	@override String get hdrSdrConversionDescription => '选择在显示器无法显示 HDR 时由谁转换 HDR 视频。';
	@override String get hdrSdrConversionAuto => '自动';
	@override String get hdrSdrConversionAutoDescription => 'Android 9 及更高版本使用设备，更早版本使用播放器';
	@override String get hdrSdrConversionDevice => '设备';
	@override String get hdrSdrConversionDeviceDescription => '由设备的视频硬件转换。速度最快，但色彩取决于设备';
	@override String get hdrSdrConversionPlayer => '播放器';
	@override String get hdrSdrConversionPlayerDescription => '由播放器转换。色彩一致，但在低端电视盒上 4K 可能卡顿';
	@override String get deinterlace => '去隔行';
	@override String get deinterlaceDescription => '消除隔行扫描视频中的梳状伪影（仅 mpv 播放器）';
	@override String get deinterlaceOff => '关闭';
	@override String get deinterlaceOffDescription => '按解码原样显示隔行扫描视频';
	@override String get deinterlaceVideo => '视频';
	@override String get deinterlaceVideoDescription => '将每一场转换为完整的一帧。适用于为电视拍摄的视频，如体育、新闻和音乐会';
	@override String get deinterlaceFilm => '电影';
	@override String get deinterlaceFilmDescription => '还原经胶转磁（telecine）处理为 29.97 fps 的电影和动画的原始帧，常见于 NTSC DVD。为电视拍摄的视频会出现卡顿。直播电视使用“视频”模式';
	@override String get requireProfileSelectionOnOpen => '打开应用时选择用户资料';
	@override String get requireProfileSelectionOnOpenDescription => '每次打开应用时都显示用户资料选择界面';
	@override String get forceTvMode => '强制 TV 模式';
	@override String get forceTvModeDescription => '强制 TV 布局。适用于无法自动检测的设备。需要重启。';
	@override String get startInFullscreen => '以全屏模式启动';
	@override String get startInFullscreenDescription => '启动时以全屏模式打开 PlezyNG';
	@override String get exitFullscreenOnPlayerClose => '关闭播放器时退出全屏';
	@override String get exitFullscreenOnPlayerCloseDescription => '关闭视频播放器时自动退出全屏模式';
	@override String get autoHidePerformanceOverlay => '自动隐藏性能叠加层';
	@override String get autoHidePerformanceOverlayDescription => '性能叠加层随播放控件一起淡入淡出';
	@override String get showNavBarLabels => '显示导航栏标签';
	@override String get showNavBarLabelsDescription => '在导航栏图标下方显示文字标签';
	@override String get startupSection => '启动页面';
	@override String get preferredServer => '优先服务器';
	@override String get preferredServerDescription => '优先考虑此服务器的结果,同时保持所有连接的服务器可用。';
	@override String get preferredServerAutomatic => '自动';
	@override String get showExploreTab => '显示“探索”标签页';
	@override String get showExploreTabDescription => '显示“探索”标签页，其中包含来自 Plex Discover 和已连接追踪服务的内容';
	@override String get hideEmptyLibraries => '隐藏空白图书馆';
	@override String get hideEmptyLibrariesDescription => '从导航中删除服务器报告的零件数的图书馆。';
	@override String get liveTvDefaultFavorites => '默认显示收藏频道';
	@override String get liveTvDefaultFavoritesDescription => '打开直播电视时仅显示收藏频道';
	@override String get general => '通用';
	@override String get generalDescription => '语言、启动和窗口行为';
	@override String get languageAndRegion => '语言与地区';
	@override String get startup => '启动';
	@override String get display => '显示';
	@override String get libraryAndCards => '媒体库与卡片';
	@override String get homeScreen => '主屏幕';
	@override String get navigation => '导航';
	@override String get window => '窗口';
	@override String get liveTv => '直播电视';
	@override String get player => '播放器';
	@override String get videoAndDisplay => '视频与显示';
	@override String get audio => '音频';
	@override String get quality => '画质';
	@override String get subtitles => '字幕';
	@override String get seekAndTiming => '跳转与计时';
	@override String get behavior => '行为';
	@override String get gestures => '手势';
	@override String get gestureBrightnessSwipe => '亮度滑动';
	@override String get gestureBrightnessSwipeDescription => '在屏幕左边缘上下滑动以调节亮度';
	@override String get gestureVolumeSwipe => '音量滑动';
	@override String get gestureVolumeSwipeDescription => '在屏幕右边缘上下滑动以调节音量';
	@override String get gesturePinchToZoom => '双指缩放';
	@override String get gesturePinchToZoomDescription => '在视频上双指捏合以放大或缩小';
	@override String get gestureSeekSwipe => '寻找Swipe';
	@override String get gestureSeekSwipeDescription => '向左或向右转到视频中寻找; 释放跳跃';
	@override String get rememberBrightnessLevel => '记住亮度';
	@override String get rememberBrightnessLevelDescription => '以上次滑动设置的亮度开始播放';
	@override String get controls => '控制';
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
	@override String get exportDialogTitle => '导出 PlezyNG 设置';
	@override String get followSystem => '跟随系统';
	@override String get followAppLanguage => '与界面语言一致';
	@override String get regionFormat => '区域格式';
	@override String get regionFormatDescription => '选择日期、数字和计量单位的显示方式。';
	@override String get metadataLanguage => '元数据语言';
	@override String get metadataLanguageDescription => '服务器支持时，优先使用此语言显示标题和简介。音频和字幕偏好单独设置。';
	@override String get enterFullscreenOnPlaybackStart => '在播放开始时输入全屏';
	@override String get enterFullscreenOnPlaybackStartDescription => '打开桌面视频在播放开始时全屏';
	@override String get extendVideoIntoDisplayCutout => '将视频扩展到显示器中';
	@override String get extendVideoIntoDisplayCutoutDescription => '让全屏视频在Android手机上使用相机切割';
	@override String get languageDescription => '选择用于 PlezyNG 控制和消息的语言. 跟踪系统跟踪您的设备语言。';
	@override String get themeDescription => '选择应用程序中使用的颜色和对比。';
	@override String get libraryDensityDescription => '改变每个行中的图书馆卡的数量。';
	@override String get displayScaleDescription => '在此车屏幕上重新设置接口,而无需改变您的设备上的文本大小。';
	@override String get themeSongVolumeDescription => '设置主题歌曲的数量与其他音频相比。';
	@override String get viewModeDescription => '选择图书馆项目是否显示为网上的海报或作为一个小型列表。';
	@override String get gridViewDescription => '安排图书馆项目在海报的行和列。';
	@override String get listViewDescription => '在垂直列表中显示图书馆项目,每个项目有更多的文本。';
	@override String get gridSpacingDescription => '在图书馆网中设置海报之间的差距。';
	@override String get gridSpacingTightDescription => '在屏幕上插入更多的海报,有较小的差距。';
	@override String get gridSpacingNormalDescription => '使用海报之间的标准差距。';
	@override String get gridSpacingSpaciousDescription => '添加海报之间更大的差距,以获得更多的分离。';
	@override String get episodePosterModeDescription => '选择哪个艺术作品出现在节目卡上。';
	@override String get seriesPosterDescription => '使用节目系列的海报为每个集合。';
	@override String get seasonPosterDescription => '使用每集的季节海报,随时可用。';
	@override String get episodeThumbnailDescription => '在可用时使用集中的框架。';
	@override String get continueWatchingActionDescription => '选择当您启动继续观看卡时会发生什么。';
	@override String get continueWatchingPlayDescription => '立即启动电影或节目。';
	@override String get continueWatchingDetailsDescription => '首先打开标题页面,以便您可以查看详细信息并选择一个行动。';
	@override String get episodeActionDescription => '选择当您启动一个节目卡时会发生什么。';
	@override String get episodePlayDescription => '立即开始事件。';
	@override String get episodeDetailsDescription => '在播放之前打开集片页面。';
	@override String get contentScreensaverDelayDescription => '在展示艺术作品之前,选择 PlezyNG 等待多久没有输入。';
	@override String get continueWatchingRowSizeDescription => '在继续观看行中选择卡片的尺寸。';
	@override String get rowSizeCompactDescription => '显示较小的卡片,以便在行列中添加更多的项目。';
	@override String get rowSizeStandardDescription => '使用标准卡尺寸。';
	@override String get rowSizeLargeDescription => '显示更大的卡片,更多艺术作品的细节。';
	@override String get visualEffectsDescription => '选择该设备的动画和艺术作品效果预算。';
	@override String get visualEffectsFullDescription => '在每个设备上使用完整的动画和艺术作品效果。';
	@override String get startupSectionDescription => '在 PlezyNG 启动时选择哪个部分打开。';
	@override late final Translations$settings$startupSectionOptions$zh startupSectionOptions = Translations$settings$startupSectionOptions$zh.internal(_root);
	@override String get smallSkipDurationDescription => '设置由短后方向移动的距离,并向前寻找控制。';
	@override String get largeSkipDurationDescription => '设置远程移动的长后方向和向前寻找控制。';
	@override String get rewindOnResumeDescription => '在重新播放视频时,以此金额返回播放。';
	@override String get defaultSleepTimerDescription => '设置睡眠时间开始时使用的初始时间。';
	@override String get playNextCountdownDescription => '等待很久,直到下一集开始,设置到0即时开始。';
	@override String get autoSkipDelaySettingDescription => '适用于当一个输入、信用或广告设置自动转换时。';
	@override String get downmixCenterBoostDescription => '在周围的音频被混合到斯特里奥时,在中间频道上增加对话。';
	@override String get displaySwitchDelayDescription => '在更改显示模式之前等待,以便电视或接收器可以完成其以前的交换。';
	@override String get playerBackendDescription => '选择哪个播放引擎在该设备上扫描和播放视频。';
	@override String get exoPlayerDescription => '使用 Android 的本地 Media3 基于播放器和支持的硬件路径。';
	@override String get mpvDescription => '使用 mpv,它暴露了额外的播放、子标题和视频处理控制。';
	@override String get scopeOffDescription => '只保留当前播放会的更改。';
	@override String get scopeGlobalDescription => '重复使用每个图书馆和标题的相同值。';
	@override String get scopeLibraryDescription => '记住每个图书馆的单独价值。';
	@override String get scopeTitleDescription => '记住每个节目或电影的单独值。';
	@override String get specialsOrderingServerDescription => '保持媒体服务器提供的集合订单。';
	@override String get specialsOrderingAirDateDescription => '根据他们的空气日期,将特殊物品列入常规事件中。';
	@override String get specialsOrderingLastDescription => '每個特別的位置,在定期季節後。';
	@override String get skipIntroModeDescription => '选择输入标记器是否正常播放,显示滑动按钮或自动滑动。';
	@override String get skipCreditsModeDescription => '选择信用是否正常播放,显示滑动按钮或自动滑动。';
	@override String get skipAdsModeDescription => '选择是否被发现的广告正常播放,显示滑动按钮或自动滑动。';
	@override String get playbackBufferAutoDescription => '让活跃的玩家选择其正常的泡沫大小。';
	@override String get playbackBufferLargeDescription => '保持更多媒体在播放前准备;这使用更多的内存。';
	@override String get playbackBufferExtraLargeDescription => '保持最大的阅读面板泡沫;这使用最多的记忆。';
	@override String get defaultQualityDescription => '设置服务器转码流的默认视频分辨率和最高码率。';
	@override String get cellularQualityDescription => '超越默认质量,当设备使用单细胞连接时。';
	@override String get remoteQualityDescription => '通过远程连接连接到服务器时超越默认质量。';
	@override String get qualityPresetOriginalDescription => '以源文件可用的画质播放，不请求服务器转码。';
	@override String get qualityPresetTranscodeOptionDescription => '请服务器使用上方显示的分辨率和码率进行转码。';
	@override String get qualityPresetSameAsDefaultDescription => '使用默认品质中选择的质量。';
	@override String get musicQualityDescription => '设置向服务器请求的最高音频码率；选择“原始”则保留源音频流。';
	@override String get musicQualityOriginalDescription => '播放源音频,无需Bitrate加密的Transcode。';
	@override String get musicQualityTranscodeOptionDescription => '请求服务器转代码接近上面的比特率;实际输出可能有所不同。';
	@override String get maxVolumeInputLabel => '最大容量(%)';
	@override String get checkForUpdatesDescription => '现在检查是否有更新的PlezyNG版本。';
	@override String get appearanceDescription => '选择应用程序主题,并调整图书馆卡、主行和导航。';
	@override String get prerollLibraryDescription => '选择包含电影预角色可用的剪辑的图书馆。';
	@override String get prerollSelectionDescription => '选择从所选图书馆播放的剪辑在电影之前。';
	@override String get contentScreensaverDelayOptionDescription => '在显示屏保存艺术作品之前等待这些无输入的几分钟。';
	@override String get videoCodecOptionDescription => '允许在支持时直接播放此代码器. 未经检查的代码被媒体服务器编码。';
}

// Path: themeEditor
class Translations$themeEditor$zh extends Translations$themeEditor$en {
	Translations$themeEditor$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get builtIn => '内置';
	@override String get presets => '预设';
	@override String get custom => '自定义';
	@override String get customEmpty => '尚未创建';
	@override String get editCustom => '编辑自定义主题';
	@override String get editCustomDescription => '自行选择每种颜色';
	@override String get locked => '终身访问需要';
	@override String get savedLocked => '保存 - 可用,终身访问';
	@override String get title => '自定义主题';
	@override String get startFrom => '从现有主题开始';
	@override String get startFromDescription => '从其他主题复制所有颜色';
	@override String get colors => '颜色';
	@override String get preview => '预览';
	@override late final Translations$themeEditor$slots$zh slots = Translations$themeEditor$slots$zh.internal(_root);
	@override String get opacity => '不透明度';
	@override String get hexHint => '#RRGGBB 或 #AARRGGBB';
	@override String get fromOtherThemes => '来自其他主题';
	@override String swatchLabel({required Object theme, required Object color}) => '${theme} · ${color}';
	@override late final Translations$themeEditor$contrast$zh contrast = Translations$themeEditor$contrast$zh.internal(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}：${ratio}:1，低于建议的 ${minimum}:1';
	@override String get discardTitle => '放弃更改？';
	@override String get discardMessage => '未保存的颜色更改将会丢失。';
	@override String get discard => '放弃';
	@override String previewCardTitle({required Object number}) => '第${number}集';
	@override String previewCardSubtitle({required Object minutes}) => '剩余 ${minutes} 分钟';
	@override String get previewSwitch => '自动播放';
	@override String get previewMutedText => '次要文字看起来是这样的';
	@override String get themeSystemDescription => '跟踪您的设备的外观,并自动在光和黑暗之间交换。';
	@override String get themeLightDescription => '使用光明的背景与黑暗文本。';
	@override String get themeDarkDescription => '使用黑暗背景与光明文本。';
	@override String get themeOledDescription => '使用近黑的表面,减少OLED屏幕上的光。';
	@override String get themeEmberDescription => '使用温暖的红色和<unk>色的重点颜色。';
	@override String get themeGlacierDescription => '使用冷蓝色焦点颜色。';
	@override String get themeForestDescription => '使用混合的绿色和天然焦点颜色。';
	@override String get themePlumDescription => '使用紫色和<unk>色的重点颜色。';
	@override String get themePaperDescription => '使用温暖的纸类表面和印刷灵感的颜色。';
	@override String get themeCustomDescription => '使用您在自定义主题编辑器中创建的颜色板。';
	@override String get editorDescription => '选择调色板颜色，调整色相、饱和度、亮度或不透明度，并在保存前预览效果。也可以输入十六进制颜色值。';
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
	@override String get people => '人物';
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
		one: '这将删除其中的 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 集及其文件。',
		other: '这将删除其中全部 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 集以及它们的文件。',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '此项目存储在 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 个文件中，该文件将被删除。',
		other: '此项目存储在 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 个文件中，所有这些文件都会被删除。',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '另有 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 集存储在同一个文件中，也会一并删除：',
		other: '另外 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 集存储在同一个文件中，也会一并删除：',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'PlezyNG 无法确认此操作会删除哪些文件，因此删除范围可能超出上面提到的项目。请取消后重试，或仍然删除。';
	@override String get deleteScopeUnverifiedNoFileInfo => '你的服务器没有提供此项目的文件详情，因此 PlezyNG 无法确认此操作会删除哪些文件。删除范围可能超出上面提到的项目。';
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
	@override String get valueShort => '五';
	@override String get red => '红色';
	@override String get green => '绿色';
	@override String get blue => '蓝色';
	@override String get redShort => '里';
	@override String get greenShort => 'G';
	@override String get blueShort => 'B';
	@override String get colorModeHsv => 'HSV';
	@override String get colorModeRgb => '里格';
	@override String get title => '可用性';
	@override String get summary => '文本、对比、动作和控制';
	@override String get systemHint => '您的设备的可用性设置始终适用. 这些选项在 PlezyNG 期间添加调整。';
	@override String get readability => '阅读与可见性';
	@override String get textSize => '附加文本大小';
	@override String get preview => '找下一个故事,阅读,听,并以自己的速度观看。';
	@override String get boldText => '勇敢的界面文本';
	@override String get highContrast => '高度对比';
	@override String get highContrastHint => '在浅色或深色背景上，让文字、轮廓线和焦点指示器更清晰。';
	@override String get interaction => '动作与互动';
	@override String get reduceMotion => '减少动作';
	@override String get reduceMotionHint => '停止焦点指示器、页面切换和装饰效果的动画。';
	@override String get largeTargets => '触摸目标';
	@override String get largeTargetsHint => '共享控制器提供更多触摸和辅助导航空间。';
	@override String get navigationHint => '使用 Tab 和 Shift+Tab 在控件之间移动，按 Enter 或空格键激活，按 Escape 或返回按钮关闭。打开书籍后，可调整缩放比例和阅读偏好。';
	@override String get textSizeDescription => '在 PlezyNG 中扩展接口文本,以及您的设备的系统文本大小设置。';
	@override String get boldTextHint => '加粗界面标签和消息的字重，让它们更容易辨认。';
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
	@override String get timelineSlider => '视频时间轴';
	@override String get volumeSlider => '音量滑块';
	@override String endsAt({required Object time}) => '结束时间：${time}';
	@override String get pipActive => '正在以画中画模式播放';
	@override String get pipFailed => '画中画启动失败';
	@override String get screenshotSaved => '截图已保存';
	@override String get screenshotFailed => '无法截图';
	@override String zoomPercent({required Object percent}) => '缩放 ${percent}%';
	@override String volumePercent({required Object percent}) => '音量 ${percent}%';
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
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 框架',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 框架',
	);
	@override String get trackSelectionTitle => '选择游戏前的游戏';
	@override String get trackSelectionAuto => '自动选择';
	@override String get openMiniPlayer => '開放小型玩家';
	@override String get returnToFullPlayer => '回到全玩家';
	@override String get loadSubtitleFile => '查询下载文件...';
	@override String get subtitleLoadFailed => '未能下载字幕文件';
	@override String get skipAds => '滑雪广告';
	@override String get tapToUnlock => '点按以解锁';
	@override String get tapAgainToUnlock => '再次点按以解锁';
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
		one: '自动移除 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 观看下载',
		other: '已自动移除 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 个看过的下载',
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
	@override String playbackFailedDetail({required Object error}) => '无法开始播放：${error}';
	@override String get audioOutputFailed => '音频输出停止响应。请检查电视或功放的音频连接；如果其他应用也没有声音，请重启设备。';
	@override String get mediaUnavailable => '此内容不再可用。';
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
	@override String get playbackNotAllowedTitle => '不允许播放';
	@override String get playbackNotAllowedBody => '服务器拒绝传输此项目（HTTP 403）。此账户可能没有播放权限，或服务器可能仅允许在其局域网内播放。';
	@override String get logsUploaded => '日志已上传';
	@override String get logsUploadFailed => '上传日志失败';
	@override String get logId => '日志 ID';
	@override String get burnedSubtitlesUseMenu => '字幕已烧录到此视频流中。请从字幕菜单中更改。';
	@override String get noVideoUrl => '没有可用的视频 URL';
	@override String get playbackNoMediaSources => '服务器未返回可播放的媒体源';
	@override String get playbackDataNotPrepared => '播放数据尚未准备就绪时便开始了播放';
	@override String get streamSelectionUnavailable => '此媒体源不支持选择视频流';
	@override String get streamSelectionFailed => '无法应用所选视频流';
	@override String get trackSelectionNotRemembered => '此轨道选择仅对当前播放生效。';
	@override String get serverUnavailableForProfile => '没有可供当前用户资料使用的服务器';
}

// Path: subtitlingStyling
class Translations$subtitlingStyling$zh extends Translations$subtitlingStyling$en {
	Translations$subtitlingStyling$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get previewSample => '快速的棕色<unk>子跳过可怜的狗';
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
	@override String get useMargins => '使用边距';
	@override String get useMarginsDescription => '允许文字字幕显示在视频画面之外的区域。样式字幕可能保留其原始位置。';
	@override String get anchorToScreen => '锚定到屏幕';
	@override String get anchorToScreenDescription => '在宽屏视频下方的黑边中显示文本字幕';
	@override String get bold => '粗体';
	@override String get italic => '斜体';
	@override String get renderResolution => '渲染分辨率';
	@override String get renderResolutionScreen => '屏幕分辨率';
	@override String get renderResolutionVideo => '视频分辨率';
	@override String get fontSizeDescription => '在此设备上设置字幕文本大小。';
	@override String get textColorDescription => '选择用于字幕文本的颜色。';
	@override String get borderSizeDescription => '设置字幕厚度周围的字幕文本。';
	@override String get borderColorDescription => '选择用于子标题输出的颜色。';
	@override String get backgroundColorDescription => '选择字幕文本背后的颜色。';
	@override String get backgroundOpacityDescription => '设置字幕背景透明度:0%是清晰的,100%是坚固的。';
	@override String get positionDescription => '垂直移动字幕:0%是视频的顶部,100%是底部。';
	@override String get assOverrideDescription => '选择玩家是否遵循、调整、更换或删除在 ASS 子标题中嵌入的风格。';
	@override late final Translations$subtitlingStyling$assOverrideOptions$zh assOverrideOptions = Translations$subtitlingStyling$assOverrideOptions$zh.internal(_root);
	@override String get renderResolutionDescription => '选择使用的分辨率来拉斯特化图像和ASS子标题. 较低的Android尺寸可以减少演示工作,但看起来更柔软。';
	@override late final Translations$subtitlingStyling$renderResolutionOptions$zh renderResolutionOptions = Translations$subtitlingStyling$renderResolutionOptions$zh.internal(_root);
	@override String get boldDescription => '以更重的重量绘制字体。';
	@override String get italicDescription => '在意大利语中绘制字幕文本。';
}

// Path: mpvConfig
class Translations$mpvConfig$zh extends Translations$mpvConfig$en {
	Translations$mpvConfig$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
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
	@override String get lineHint => 'option=value';
	@override String get addLine => '添加行';
	@override String get removeLine => '移除行';
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
	@override String get addPlezyProfile => '添加 PlezyNG 用户资料';
	@override String get switchingProfile => '正在切换用户资料…';
	@override String get deleteThisProfileTitle => '删除此用户资料？';
	@override String deleteThisProfileMessage({required Object displayName}) => '移除 ${displayName}。连接不会受影响。';
	@override String get active => '当前使用';
	@override String get manage => '管理';
	@override String get delete => '删除';
	@override String get signOut => '退出登录';
	@override String get signOutPlexTitle => '退出 Plex 登录？';
	@override String signOutPlexMessage({required Object displayName}) => '要移除 ${displayName} 和所有 Plex Home 用户吗？可随时重新登录。';
	@override String get signOutPlexDeleteDownloads => '同时删除下载内容';
	@override String get signOutPlexDeleteDownloadsDescription => '否则下载内容将保留在此设备上，并在你重新登录此账户时恢复。';
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
	@override String get copyAutomationLink => '复制 Android 自动化链接';
	@override String get copyAutomationLinkDescription => '從 Android 意圖或自動化中選擇此檔案,檔案 PIN 檢查仍適用。';
	@override String get automationLinkCopied => '个人资料自动化链接复制。';
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
	@override String get borrowEmptySubtitle => '请先将 Plex、Jellyfin 或 Emby 连接到另一个用户资料。';
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
	@override String get settingsLocked => '此配置已锁定。';
	@override String get unlockSettings => '解锁设置';
	@override String get showExploreForProfile => '查看此资料的探索';
	@override String get showExploreForProfileDescription => '关闭以从此个人资料的导航中删除 Explore。';
}

// Path: connections
class Translations$connections$zh extends Translations$connections$en {
	Translations$connections$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '连接';
	@override String get addConnection => '添加连接';
	@override String get addConnectionSubtitleNoProfile => '使用 Plex 登录，或连接 Jellyfin 或 Emby 服务器';
	@override String addConnectionSubtitleScoped({required Object displayName}) => '添加到 ${displayName}：Plex、Jellyfin、Emby，或其他用户资料的连接';
	@override String sessionExpiredOne({required Object name}) => '${name} 的会话已过期';
	@override String sessionExpiredMany({required Object count}) => '${count} 个服务器的会话已过期';
	@override String accessDeniedOne({required Object name}) => '${name} 拒绝此账户访问';
	@override String accessDeniedMany({required Object count}) => '${count} 台服务器拒绝此账户访问';
	@override String get signInAgain => '重新登录';
	@override String editMediaBrowserTitle({required Object product}) => '编辑 ${product} 连接';
	@override String editMediaBrowserIntro({required Object serverName}) => '为 ${serverName} 添加或移除 URL。PlezyNG 会使用延迟最低且可访问的 URL。';
}

// Path: accountPreferences
class Translations$accountPreferences$zh extends Translations$accountPreferences$en {
	Translations$accountPreferences$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '账户偏好';
	@override String hubSubtitleSingle({required Object account}) => '音频、字幕和媒体库选项已保存在 ${account} 上';
	@override String hubSubtitleMultiple({required Object count}) => '音频、字幕和媒体库选项已保存在 ${count} 个账户上';
	@override String get pickAccount => '每个账户都保存自己的偏好设置。选择要编辑的账户。';
	@override String get storedOnAccount => '这些选项保存在账户本身，因此所有登录该账户的应用都会使用它们——包括你其他设备上的 PlezyNG。';
	@override String get noAccounts => '没有可配置的账户';
	@override String get noAccountsHint => '登录 Plex，或连接 Jellyfin 或 Emby 服务器，该账户上保存的偏好设置就会显示在这里。';
	@override String get unavailable => '无法访问此账户';
	@override String get loadFailed => '无法加载这些偏好设置';
	@override String get noPreference => '无偏好';
	@override String get notSet => '未设置';
	@override late final Translations$accountPreferences$groups$zh groups = Translations$accountPreferences$groups$zh.internal(_root);
	@override String get preferredAudioLanguage => '首选音频语言';
	@override String get autoSelectAudio => '按语言选择音频';
	@override String get autoSelectAudioDescription => '关闭后保留文件标记为默认的音轨。';
	@override String get preferredSubtitleLanguage => '首选字幕语言';
	@override String get subtitleMode => '开启字幕';
	@override late final Translations$accountPreferences$subtitleModes$zh subtitleModes = Translations$accountPreferences$subtitleModes$zh.internal(_root);
	@override String get subtitleAccessibility => 'SDH 字幕';
	@override late final Translations$accountPreferences$subtitleAccessibilityOptions$zh subtitleAccessibilityOptions = Translations$accountPreferences$subtitleAccessibilityOptions$zh.internal(_root);
	@override String get forcedSubtitles => '强制字幕';
	@override late final Translations$accountPreferences$forcedSubtitleOptions$zh forcedSubtitleOptions = Translations$accountPreferences$forcedSubtitleOptions$zh.internal(_root);
	@override String get displayMissingEpisodes => '显示缺失剧集';
	@override String get displayMissingEpisodesDescription => '列出服务器知道但没有对应文件的剧集。';
	@override String get hidePlayedInLatest => '在“最新”中隐藏已观看项目';
	@override String get hidePlayedInLatestDescription => '将你已经看过的项目从服务器的“最新”列表中移除。';
	@override String get displayCollectionsView => '显示合集视图';
	@override String get displayCollectionsViewDescription => '在媒体库之外提供服务器的合集视图。';
	@override String get rewatchingInNextUp => '在“接下来”中保留重看的剧集';
	@override String get rewatchingInNextUpDescription => '看完一部剧集后再次开始观看时，“接下来”会跟随重看进度，而不是将剧集移除。';
	@override String get watchedIndicator => '已观看标记';
	@override late final Translations$accountPreferences$watchedIndicatorOptions$zh watchedIndicatorOptions = Translations$accountPreferences$watchedIndicatorOptions$zh.internal(_root);
	@override String get mediaReviewsVisibility => '评分与评论';
	@override late final Translations$accountPreferences$mediaReviewsOptions$zh mediaReviewsOptions = Translations$accountPreferences$mediaReviewsOptions$zh.internal(_root);
	@override String get preferredAudioLanguageDescription => '在此语言中更喜欢音频轨道,当服务器或播放器自动选择轨道时。';
	@override String get preferredSubtitleLanguageDescription => '自动选择字幕时，优先选择此语言的字幕轨道。';
	@override String get subtitleAccessibilityDescription => '自动选择字幕时，设置听障字幕（SDH）为优先或必选。';
	@override String get forcedSubtitleDescription => '自动选择字幕时，选择优先使用强制字幕轨道，或是必须使用强制字幕轨道。';
	@override String get watchedIndicatorDescription => '选择哪个媒体类型在服务器界面中获得观看的检查标志。';
	@override String get mediaReviewsVisibilityDescription => '选择哪个观众和批判评分服务器在媒体页面上显示。';
	@override String get subtitleModeDescription => '在此服务器帐户中自动启动子标题时选择。';
	@override String get hubDescription => '这些偏好存储在您的媒体服务器帐户上,并可能适用于其他客户。';
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
	@override late final Translations$discover$findNext$zh findNext = Translations$discover$findNext$zh.internal(_root);
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
		one: '第${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}章',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 个标题',
	);
	@override late final Translations$discover$person$zh person = Translations$discover$person$zh.internal(_root);
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
	@override String get reasonTimedOut => '连接超时';
	@override String get reasonUnreachable => '无法连接到服务器';
	@override String get reasonRefused => '服务器拒绝了此请求';
	@override String get reasonNotFound => '该项目已不在服务器上';
	@override String get reasonServerError => '服务器报告了一个错误';
	@override String get reasonCancelled => '请求已取消';
	@override String get reasonUnexpected => '发生了意外错误';
}

// Path: libraries
class Translations$libraries$zh extends Translations$libraries$en {
	Translations$libraries$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => '随机电影播放';
	@override String get randomPickFailed => '不能从这本图书馆选择随机电影。';
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
	@override late final Translations$libraries$advancedFilters$zh advancedFilters = Translations$libraries$advancedFilters$zh.internal(_root);
	@override late final Translations$libraries$selection$zh selection = Translations$libraries$selection$zh.internal(_root);
}

// Path: about
class Translations$about$zh extends Translations$about$en {
	Translations$about$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '关于';
	@override String get openSourceLicenses => '开源许可证';
	@override String versionLabel({required Object version}) => '版本 ${version}';
	@override String get appDescription => '一款精美的 Flutter Plex、Jellyfin 和 Emby 客户端';
	@override String get viewLicensesDescription => '查看第三方库的许可证';
	@override String get privacyPolicy => '隐私政策';
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
	@override String get saveLogs => '存储存档';
	@override String logsSaved({required Object path}) => '存储到 ${path} 的存档';
	@override String get saveLogsFailed => '无法保存存档。';
}

// Path: startup
class Translations$startup$zh extends Translations$startup$en {
	Translations$startup$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'PlezyNG 无法启动';
	@override String get failedBody => '启动过程中出现问题。以下详情指出了失败的原因。';
	@override String get failedBodyRepairable => 'PlezyNG 的已保存设置文件已损坏，必须先重建才能启动。重试没有用——请选择“修复存储”。';
	@override String get phaseLabel => '步骤';
	@override String get showDetails => '显示详情';
	@override String get hideDetails => '隐藏详情';
	@override String get copyDetails => '复制详情';
	@override String get detailsCopied => '详情已复制到剪贴板';
	@override String get uploadDetails => '上传详情';
	@override String get repairStorage => '修复存储';
	@override String get repairTitle => '修复已存储的数据？';
	@override String get repairBodyCommon => 'PlezyNG 的设置文件已损坏且无法读取。修复会将所有设置重置为默认值。';
	@override String get repairBodyOneCredential => '有一项已保存的登录信息已损坏且无法读取。修复只会移除这一项，其他设置保持不变。';
	@override String get repairBodySignInsKept => '你的服务器和个人资料应保持登录状态。';
	@override String get repairBodySignInsLost => '保护已保存登录信息的密钥无法从此文件中恢复，因此你需要重新登录每个服务器和个人资料。媒体服务器上的内容不受影响。';
	@override String get repairBodySessionsUncertain => '追踪服务（MAL、AniList、Simkl、Trakt）和 Seerr 是分开存储的，可能保留也可能无法保留。PlezyNG 会明确告诉你保留了哪些。';
	@override String get repairConfirm => '修复';
	@override String get repairSucceeded => '存储已修复';
	@override String get repairNeedsRestart => '存储已修复 — 需要重启';
	@override String get restartRequiredBody => '你的数据已修复，但 PlezyNG 需要重新启动后才能使用。请关闭 PlezyNG 并重新打开。';
	@override String get quitPlezy => '退出 PlezyNG';
	@override String get repairFailed => '修复失败';
	@override String get repairKeptSignIns => '你的服务器和个人资料仍然保持登录状态。';
	@override String get repairLostSignIns => '保护已保存登录信息的密钥无法恢复。你需要重新登录每个服务器和个人资料。';
	@override String get repairLostSessions => '至少有一个追踪服务或 Seerr 连接已丢失，需要重新连接。';
	@override String get backupTitle => '已保留损坏文件的副本';
	@override String get backupWarning => '其中包含你的登录凭据。请勿上传或分享。';
	@override String get deleteBackup => '删除副本';
	@override String get backupDeleted => '副本已删除。';
	@override String get previousFailureTitle => 'PlezyNG 上次启动失败';
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
	@override late final Translations$explore$mdblistShelves$zh mdblistShelves = Translations$explore$mdblistShelves$zh.internal(_root);
	@override String get title => '探索';
	@override String get selectSource => '选择来源';
	@override late final Translations$explore$rows$zh rows = Translations$explore$rows$zh.internal(_root);
	@override late final Translations$explore$status$zh status = Translations$explore$status$zh.internal(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 集',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 集',
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
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '无法查看 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 服务器',
		other: '无法检查 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 台服务器',
	);
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
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 结果',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 条结果',
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
	@override String get timelineLiveProgram => '直播程序(播放可能不在此程序)';
	@override String get timelineBuffer => '布菲尔时间表';
	@override String get timelineUnavailable => '时间不可用';
	@override String get timelineEstimated => '值得一提的Playback';
	@override String get timelinePending => '求求求';
	@override String get timelineStale => '时间表可能过时';
	@override String get unknownHub => '未知';
	@override String get unknownError => '未知错误';
	@override String channelNumber({required Object number}) => '频道 ${number}';
	@override String get unknownChannel => '未知频道';
	@override String get live => '直播';
	@override String get premiereBadge => '新';
	@override String get reloadGuide => '重新加载节目指南';
	@override String get searchGuide => '搜索节目指南';
	@override String get searchHint => '搜索频道和节目';
	@override String searchNoResults({required Object query}) => '没有与“${query}”匹配的结果';
	@override String get channelsSection => '频道';
	@override String get programsSection => '节目';
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
	@override String get guideReloadFailed => '无法刷新节目指南';
	@override String get rulesProcessRequested => '已请求重新评估规则';
	@override String get rulesProcessFailed => '无法重新评估录制规则';
	@override String get recordShow => '录制节目';
	@override late final Translations$liveTv$recordSettings$zh recordSettings = Translations$liveTv$recordSettings$zh.internal(_root);
	@override String startingInMinutes({required Object minutes}) => '${minutes} 分钟后开始';
	@override String dayAtTime({required Object day, required Object time}) => '${day} ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} 返回了无效的直播电视播放数据';
	@override String get failedToStartChannel => '无法播放直播频道';
	@override String get failedToBuildStreamUrl => '无法生成视频流 URL';
	@override String playbackStartFailed({required Object reason}) => '无法启动该频道：${reason}';
	@override String channelSwitchFailed({required Object reason}) => '无法切换频道：${reason}';
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
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(count,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)}个项目',
	);
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
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 路径',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 首',
	);
	@override String get nowPlaying => '正在播放';
	@override String playingFrom({required Object title}) => '播放来源：${title}';
	@override String get queue => '播放队列';
	@override String get clearQueue => '清空队列';
	@override String get lyrics => '歌词';
	@override String get visualizer => '视觉化';
	@override String get visualizerProfileLoading => '阅读路径分析';
	@override String get visualizerAmbientMotion => '环境动作';
	@override String get visualizerPlexLoudness => 'Plex 噪音';
	@override String get visualizerPreviousPreset => '以前的视觉风格';
	@override String get visualizerNextPreset => '下一篇 视觉风格';
	@override String get visualizerPresetAurora => '奥拉';
	@override String get visualizerPresetBloom => '蓝色';
	@override String get visualizerPresetOrbitals => '轨道';
	@override String get visualizerPresetPrism => '普里斯';
	@override String get visualizerPresetTunnel => '隧道';
	@override String get visualizerPresetTrackMap => '跟踪地图';
	@override String get noLyrics => '暂无歌词';
	@override String get sleepTimer => '睡眠定时器';
	@override String get sleepTimerEndOfTrack => '当前曲目结束时';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}分钟',
	);
	@override String get stopPlayback => '停止播放';
	@override String get previousTrack => '上一首';
	@override String get nextTrack => '下一首';
	@override String get repeat => '循环';
	@override String get repeatAll => '列表循环';
	@override String get repeatOne => '单曲循环';
	@override String get instantMixNoServer => '没有可用于即时混合的服务器';
	@override String get instantMixFailed => '加载即时混合失败';
	@override String get instantMixEmpty => '即时混合没有生成任何曲目';
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
	@override String get createRoom => '创建房间';
	@override String get creatingRoom => '正在创建房间…';
	@override String get joinRoom => '加入房间';
	@override String get joiningRoom => '正在加入房间…';
	@override String get connecting => '正在连接…';
	@override String get relayPublic => '房间使用公共 Open Watch Party 中继服务器。';
	@override String relayCustom({required Object url}) => '房间使用你位于 ${url} 的中继服务器。';
	@override String get recentRooms => '最近的房间';
	@override String get roomActions => '房间操作';
	@override String get renameRoom => '重命名房间';
	@override String get removeRoom => '移除';
	@override String get enterRoomCode => '输入主持人提供的 6 位代码。';
	@override String get roomCode => '房间代码';
	@override String get paste => '粘贴';
	@override String get noCodeInClipboard => '剪贴板中没有房间代码';
	@override String get copyCode => '复制代码';
	@override String get codeCopied => '房间代码已复制';
	@override String get shareInvite => '分享邀请';
	@override String get inviteCopied => '邀请已复制。请将其粘贴到消息中。';
	@override String inviteMessage({required Object code}) => '加入我在 PlezyNG 中的“一起看”房间：打开“一起看”，选择“加入房间”，然后输入 ${code}。';
	@override String get openSessionControls => '打开“一起看”会话控制';
	@override String get reconnecting => '正在重新连接…';
	@override String get reconnectingDescription => '连接已中断。你将自动重新加入房间。';
	@override String get connected => '已连接';
	@override String get disconnected => '已断开连接';
	@override String get youAreHost => '你是主持人';
	@override String hostedBy({required Object name}) => '由 ${name} 主持';
	@override String get hostControlsPlayback => '主持人控制播放';
	@override String get anyoneCanControl => '任何人都可以控制播放';
	@override String get roomLocked => '房间已锁定';
	@override String get nowPlaying => '正在播放';
	@override String get nothingPlaying => '未在播放';
	@override String get nothingPlayingHost => '从任意媒体库播放内容，即可与房间成员分享。';
	@override String get nothingPlayingGuest => '主持人播放内容后，将在此处打开。';
	@override String get notShareable => '此视频没有匹配的影视目录条目，因此只有能访问同一服务器的人才能播放。';
	@override String get searching => '正在你的媒体库中查找此视频…';
	@override String get yourCopy => '你的副本';
	@override String get sharingYourCopy => '你正在分享你的副本';
	@override String playingOtherLength({required Object difference}) => '正在播放你的副本（${difference}）';
	@override String get mismatchTitle => '你的副本时长不同';
	@override String mismatchDescription({required Object difference}) => '你最接近的副本比房间的视频${difference}。它可能是其他剪辑版或版本。';
	@override String get playAnyway => '仍要播放';
	@override String get chooseAnotherCopy => '选择其他副本';
	@override String get dontPlay => '不播放';
	@override String get unavailableTitle => '你没有此视频';
	@override String get unavailableDescription => 'PlezyNG 在你的媒体库中找不到它。请自行选择副本或重新搜索。';
	@override String get chooseCopy => '选择副本';
	@override String get searchAgain => '重新搜索';
	@override String get noCandidates => '在你的媒体库中未找到副本。';
	@override String get choiceFailed => '无法为房间播放此副本';
	@override String lengthLonger({required Object duration}) => '长 ${duration}';
	@override String lengthShorter({required Object duration}) => '短 ${duration}';
	@override String get lengthSame => '时长相同';
	@override String get lengthUnknown => '时长未知';
	@override String get joinCurrentPlayback => '加入当前播放';
	@override String get joinCurrentPlaybackDescription => '加入主持人当前正在观看的内容';
	@override String get stopMedia => '为所有人停止视频';
	@override String get syncOffset => '同步偏移';
	@override String get syncOffsetDescription => '如果你的视频比房间快或慢，可在此调整。';
	@override String offsetHint({required Object difference}) => '你的副本比房间的视频${difference}。';
	@override String applyDifference({required Object offset}) => '使用 ${offset}';
	@override String get offsetMinusSecond => '-1 秒';
	@override String get offsetMinusTenth => '-100 毫秒';
	@override String get offsetPlusTenth => '+100 毫秒';
	@override String get offsetPlusSecond => '+1 秒';
	@override String get participants => '参与者';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 參與者',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 位参与者',
	);
	@override String get hostBadge => '主持人';
	@override String nameYou({required Object name}) => '${name}（你）';
	@override String get playerIdle => '空闲';
	@override String get playerLoading => '加载中';
	@override String get playerReady => '就绪';
	@override String get playerBuffering => '缓冲中';
	@override String get matchSearching => '搜索中';
	@override String get matchMatched => '有此视频';
	@override String get matchMismatched => '时长不同';
	@override String get matchUnavailable => '没有此视频';
	@override String participantOffset({required Object offset}) => '偏移 ${offset}';
	@override String get makeHost => '设为主持人';
	@override String get makeHostQuestion => '移交主持人？';
	@override String makeHostConfirm({required Object name}) => '${name} 将控制播放并主导所有人的会话。';
	@override String get transfer => '移交';
	@override String get removeParticipant => '移出房间';
	@override String removeParticipantQuestion({required Object name}) => '移除 ${name}？';
	@override String removeParticipantConfirm({required Object name}) => '${name} 将离开房间。除非你锁定房间，否则对方仍可使用代码重新加入。';
	@override String get remove => '移除';
	@override String get roomSettings => '房间设置';
	@override String get letEveryoneControl => '允许所有人控制播放';
	@override String get lockRoom => '锁定房间';
	@override String get lockRoomDescription => '新成员无法加入';
	@override String get leaveRoom => '离开房间';
	@override String get leaveRoomQuestion => '离开房间？';
	@override String get leaveRoomConfirm => '你可以使用房间代码重新加入。';
	@override String get leave => '离开';
	@override String get endRoom => '结束房间';
	@override String get endRoomQuestion => '结束房间？';
	@override String get endRoomConfirm => '这将为所有人结束此房间。';
	@override String get end => '结束';
	@override String get playBlockedTitle => '播放未开始';
	@override String get playBlockedDescription => '按下播放，开始与房间成员一起观看。';
	@override late final Translations$watchTogether$notices$zh notices = Translations$watchTogether$notices$zh.internal(_root);
	@override late final Translations$watchTogether$ended$zh ended = Translations$watchTogether$ended$zh.internal(_root);
	@override late final Translations$watchTogether$errors$zh errors = Translations$watchTogether$errors$zh.internal(_root);
	@override String untitledEpisode({required Object number}) => '第${number}集';
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
	@override String get storageFull => '为保护剩余存储空间，下载已停止。请释放空间或选择其他下载位置，然后重试。';
	@override String get storageUnavailable => '无法检查可用存储空间，因此下载已停止。请检查下载位置后重试。';
	@override String episodesQueued({required Object count}) => '${count} 集已加入下载队列';
	@override String get downloadDeleted => '下载已删除';
	@override String deleteConfirm({required Object title}) => '要从此设备删除“${title}”吗？';
	@override String get deleteCollectionDownloads => '删除下载';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => '要从此设备删除“${title}”中的所有下载吗？';
	@override String get collectionDownloadsDeleted => '下载已删除';
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
	@override String get retryAll => '全部重试';
	@override String get retryFailed => '重试失败的下载';
	@override String get deleteAll => '全部删除';
	@override String get selectVersion => '选择版本';
	@override String get allEpisodes => '所有剧集';
	@override String get unwatchedOnly => '仅未观看';
	@override String nextNUnwatched({required Object count}) => '接下来 ${count} 集未观看';
	@override String get customAmount => '自定义数量…';
	@override String get customAmountAny => '每個數量(每個數...';
	@override String get randomEpisodes => '随机事件';
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
	@override String get syncNow => '现在的Sync';
	@override String get downloadsUpToDate => '下载到目前为止';
	@override String syncComplete({required Object queued, required Object removed}) => '合成完整 · ${queued} queued, ${removed} 删除';
	@override String get activeSyncRules => '同步规则';
	@override String get reviewOrphanFiles => '检查无对应记录的下载';
	@override String get orphanReviewTitle => '检查无对应记录的下载';
	@override String get orphanReviewDescription => '这些已标记的文件位于 PlezyNG 默认管理的下载文件夹中，但没有匹配的下载记录或正在进行的任务。删除前请先检查列表。';
	@override String orphanReviewCount({required Object count, required Object size}) => '${count} 个文件 · ${size}';
	@override String orphanDeleteFiles({required Object count}) => '删除 ${count} 个文件';
	@override String get orphanCleanupNone => '未找到无对应记录的下载文件';
	@override String get orphanCleanupFailed => 'PlezyNG 无法安全扫描受管理的下载文件夹。没有删除任何文件。';
	@override String get orphanCleanupChanged => '检查期间下载列表已更改。清理前请重新检查文件。';
	@override String orphanCleanupComplete({required Object count, required Object size}) => '已删除 ${count} 个无对应记录的文件 · 释放 ${size}';
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
	@override String get syncRuleAccessDenied => '访问被拒绝';
	@override String get syncRuleNotAvailableForProfile => '当前用户资料不可用';
	@override String get syncRuleUnknownServer => '未知服务器';
	@override String get syncRuleListCreated => '同步规则已创建';
	@override late final Translations$downloads$backgroundWarning$zh backgroundWarning = Translations$downloads$backgroundWarning$zh.internal(_root);
	@override String get options => '下载选项';
	@override late final Translations$downloads$groupings$zh groupings = Translations$downloads$groupings$zh.internal(_root);
	@override String get unknownLibrary => '未知媒体库';
	@override String get unknownShow => '未知节目';
	@override String get unknownSeason => '未知季';
	@override String get unknownAlbum => '未知专辑';
	@override String completedOfTotal({required Object completed, required Object total}) => '已完成 ${completed}/${total}';
	@override String storageUsed({required Object size}) => '使用的存储: ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}个下载',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}个下载',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 展览',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 显示',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 電影',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 電影',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}张专辑',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}张专辑',
	);
	@override String get errorFileNotFound => '未找到文件（404）';
	@override String get errorDownloadNotAllowed => '服务器不允许下载（403）';
	@override String get errorDownloadFailed => '下载失败';
	@override String errorDownloadFailedWithReason({required Object reason}) => '下载失败：${reason}';
	@override String get convertingOnServer => '转换到服务器';
	@override String convertingOnServerPercent({required Object percent}) => '转换到服务器 · ${percent}%';
	@override String errorHttpStatus({required Object status}) => '下载失败（HTTP ${status}）';
	@override String errorPostProcessing({required Object reason}) => '后处理失败：${reason}';
	@override String get reasonFileNotSaved => '无法将文件保存到此设备';
	@override String get reasonCannotResume => '无法继续未完成的下载';
	@override String get reasonDeviceStorageFull => '此设备的存储空间已满';
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
	@override String get audioEqualizer => '音频平衡器';
	@override String get audioEqualizerDescription => '适用于此设备的五个频率带;可在mpv上;一个活跃的EQ音频解码,并禁用匹配。';
	@override String get audioEqualizerFlat => '平板';
	@override String get audioEqualizerActive => '自定义';
	@override String get audioEqualizerSaveFailed => '无法保存音频平衡器设置。';
	@override String get backgroundVideoAudio => '背景视频音频';
	@override String get backgroundVideoAudioDescription => '离开播放器后继续播放视频音频；返回前画面将被隐藏。Android 会显示媒体播放通知。';
	@override String get audioNormalization => '响度标准化';
	@override String get audioNormalizationDisablesPassthrough => '将音频解码为 PCM；开启时直通关闭';
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
	@override String get dvRouteDecoder => 'Dolby Vision 解码器';
	@override String get dvRouteDecoderP81 => 'Dolby Vision 解码器（P7→8.1）';
	@override String get dvRouteBaseLayer => '基础层';
	@override String get dvRouteBaseLayerHdr10 => 'HDR10 基础层';
	@override String get dvRouteBaseLayerHlg => 'HLG 基础层';
	@override String get dvRouteBaseLayerSdr => 'SDR 基础层';
	@override String get dvRouteReshaped => 'RPU 重塑（gpu-next）';
	@override String get dvRouteFelGraphActive => '实验 P7 FEL 图表(未合格)';
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
	@override String get playMethod => '玩方法';
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
	@override String get description => '选择另一个应用程序打开视频,可用的玩家取决于您的设备和安装的应用程序。';
	@override String get systemDefaultDescription => '让操作系统使用默认应用程序打开视频。';
	@override String playerOptionDescription({required Object player}) => '使用 ${player} 打开视频。';
	@override String get playerNameDescription => '标签显示在玩家列表中。';
	@override String get playerPackageDescription => '输入玩家应用程序的Android包名称,如com.example.player。';
	@override String get playerCommandDescription => '输入该设备安装的播放器命令或可执行路径。';
	@override String get playerUrlSchemeDescription => '输入 URL 格式和可选的 URL 模板,用于启动播放器。';
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
	@override String get quickTag => '快速标签…';
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
	@override String get disconnectConfirmBody => 'PlezyNG 将停止向 Trakt 发送事件。你可随时重新连接。';
	@override String get scrobble => '实时同步播放状态';
	@override String get scrobbleDescription => '播放期间将播放、暂停和停止事件发送到 Trakt。';
	@override String get watchedSync => '同步已观看状态';
	@override String get watchedSyncDescription => '在 PlezyNG 中将内容标记为已观看时，也会在 Trakt 上标记为已观看。';
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
	@override String get noSignInMethods => '此 Seerr 实例未提供 PlezyNG 支持的登录方式。';
	@override String get instance => '实例';
	@override String get disconnectConfirm => '断开 Seerr 连接？';
	@override String get disconnectConfirmBody => 'PlezyNG 将忘记此 Seerr 实例。可随时重新连接。';
	@override String get request => '请求';
	@override String get request4k => '请求 4K';
	@override String get seasons => '季';
	@override String get allSeasons => '全部季';
	@override String get advancedOptions => '高级';
	@override String get destinationServer => '目标服务器';
	@override String get qualityProfile => '画质配置';
	@override String get rootFolder => '根目录';
	@override String get languageProfile => '语言配置';
	@override String get tags => '标签';
	@override String get noTags => '无标签';
	@override String defaultOption({required Object name}) => '${name}（默认）';
	@override String get animeNote => '此剧集为动画。';
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
	@override String get behindAuthProxy => '响应来自需要身份验证的反向代理（SSO 或 HTTP 认证），而非 Seerr。PlezyNG 无法通过它登录：请让 Seerr 的 /api/v1 路径为此应用绕过代理，或使用可直接访问 Seerr 的地址。';
	@override String get invalidUrl => '输入服务器地址，例如 https://seerr.example.com';
	@override String get quickConnectUnsupported => '此 Seerr 实例不支持 Quick Connect。需要 Seerr 3.4 或更高版本。';
	@override String get notInitialized => '此 Seerr 实例尚未完成首次运行设置';
	@override String get noPlexTokenForReauth => '没有可用于重新登录的 Plex 令牌';
	@override String get noStoredCredentials => '没有已保存的凭据可用于重新登录';
	@override String get signInRejected => '登录被拒绝';
	@override String get noSessionCookie => 'Seerr 未签发会话 Cookie';
	@override String get freshCookieRejected => 'Seerr 拒绝了新的会话 Cookie';
	@override String get noUserInformation => 'Seerr 未返回用户信息';
	@override String get sessionRejectedAfterReauth => '重新登录后会话被拒绝';
	@override String get permissionDenied => 'Seerr 拒绝了此操作：你的账户不再拥有所需权限';
	@override String get permissionRevoked => '你不再拥有请求此内容的权限';
}

// Path: services
class Translations$services$zh extends Translations$services$en {
	Translations$services$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '服务';
	@override String get hubSubtitle => '同步观看进度并请求新内容。';
	@override String get integrations => '集成';
	@override String get notConnected => '未连接';
	@override String connectedAs({required Object username}) => '已以 @${username} 身份连接';
	@override String get scrobble => '自动记录进度';
	@override String get scrobbleDescription => '观看完一集或一部电影后更新你的列表。';
	@override String disconnectConfirm({required Object service}) => '断开 ${service} 连接？';
	@override String disconnectConfirmBody({required Object service}) => 'PlezyNG 将停止更新 ${service}。可随时重新连接。';
	@override String connectFailed({required Object service}) => '无法连接到 ${service}。请重试。';
	@override late final Translations$services$names$zh names = Translations$services$names$zh.internal(_root);
	@override late final Translations$services$simklReconnect$zh simklReconnect = Translations$services$simklReconnect$zh.internal(_root);
	@override late final Translations$services$deviceCode$zh deviceCode = Translations$services$deviceCode$zh.internal(_root);
	@override late final Translations$services$oauthProxy$zh oauthProxy = Translations$services$oauthProxy$zh.internal(_root);
	@override late final Translations$services$pendingAuth$zh pendingAuth = Translations$services$pendingAuth$zh.internal(_root);
	@override late final Translations$services$libraryFilter$zh libraryFilter = Translations$services$libraryFilter$zh.internal(_root);
	@override String get seerrDescription => '连接到 Seerr 或 Overseerr 以搜索标题并提交媒体请求。';
	@override late final Translations$services$trackerDescriptions$zh trackerDescriptions = Translations$services$trackerDescriptions$zh.internal(_root);
}

// Path: streaming
class Translations$streaming$zh extends Translations$streaming$en {
	Translations$streaming$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '云端与插件串流';
	@override String get subtitle => '连接 Debrid 账户，即可浏览云端文件并播放受支持的流。兼容 Stremio 的插件会在电影和剧集详情页提供播放选项。连接信息会在此设备上加密，并保存到此个人资料。';
	@override String connectionsConfigured({required Object count}) => '已连接的来源：${count}';
	@override String get settingsLoadFailed => 'PlezyNG 无法解锁已保存的串流设置。请先解锁设备，再重试后更改连接。';
	@override String get settingsUnreadable => 'PlezyNG 无法解锁这些已保存的连接。清除后即可重新连接服务。';
	@override String get clearUnreadableSettings => '清除已保存的设置';
	@override String get clearUnreadableSettingsConfirm => '清除已保存的串流设置？';
	@override String get clearUnreadableSettingsBody => '这会从此个人资料中移除所有已保存的服务商账户和插件地址，且无法撤销。';
	@override String get clearUnreadableSettingsFailed => '无法清除已保存的串流设置。请解锁设备后重试。';
	@override String get retrySettingsLoad => '重新加载连接';
	@override String get addons => '兼容 Stremio 的插件';
	@override String get addonsDescription => '从 Stremio 导入插件，或通过清单网址连接插件。在“探索”中浏览目录，并从电影或剧集详情页打开串流选项。';
	@override String get catalogLoadFailed => '无法加载此目录。请刷新后重试。';
	@override String get catalogFiltersRequired => '选择浏览此目录所需的筛选条件。';
	@override String get catalogRequiredLabel => '必填';
	@override String get importFromStremio => '从 Stremio 导入';
	@override String get stremioImportInstructions => '扫描二维码或打开链接。登录 Stremio 并批准请求。PlezyNG 只会读取你的插件列表，不会索要 Stremio 密码或更改设置。';
	@override String get stremioImportOpen => '打开 Stremio 链接';
	@override String get stremioImportCode => '关联码';
	@override String get stremioImportPreviewTitle => '选择插件';
	@override String get stremioImportPreviewBody => '选择要连接到 PlezyNG 的插件。此导入仅接受 HTTPS 地址。';
	@override String stremioImportIgnored({required Object count}) => '因地址不受支持或不安全而跳过的插件：${count}。';
	@override String get stremioCatalogs => '目录';
	@override String get stremioStreams => '串流';
	@override String stremioImportAddSelected({required Object count}) => '添加所选项（${count}）';
	@override String stremioImportAdded({required Object count}) => '从 Stremio 连接的插件：${count}。';
	@override String stremioImportPartial({required Object added, required Object failed}) => '已连接的插件：${added}；未能连接：${failed}。';
	@override String get stremioImportFailed => '无法从 Stremio 导入插件。请重试。';
	@override String get stremioImportTimedOut => 'Stremio 授权已超时。请重新开始导入。';
	@override String get stremioImportEmpty => '此 Stremio 账户中没有找到新的兼容插件。';
	@override String get stremioImportLimitReached => '请先移除一个插件，再导入更多插件。';
	@override String get addByManifestUrl => '通过清单网址添加';
	@override String get addAddon => '添加插件';
	@override String get manifestUrl => '插件清单网址';
	@override String get manifestUrlHint => '粘贴插件的清单网址。连接前，PlezyNG 会检查其是否支持目录或串流资源。';
	@override String get allowHttp => '允许未加密的 HTTP 地址';
	@override String get allowHttpDescription => '仅对私人网络中可信任的插件使用。';
	@override String get installAddon => '连接插件';
	@override String get addonInstalled => '插件已连接';
	@override String get addonRemoved => '插件已移除';
	@override String get addonToggle => '启用插件';
	@override String get addonEmpty => '尚未连接插件';
	@override String get addonError => 'PlezyNG 无法连接此插件。请检查清单网址并重试。';
	@override String get addonPrivacy => '仅连接你信任的插件。搜索时，插件会收到你要搜索的标题，并可能返回第三方串流链接。';
	@override String get realDebrid => 'Real-Debrid';
	@override String get realDebridDescription => '通过 Real-Debrid 账户播放受支持的种子流。';
	@override String get connectRealDebrid => '使用二维码连接';
	@override String get disconnectRealDebrid => '断开 Real-Debrid';
	@override String realDebridConnected({required Object username}) => '已连接：${username}';
	@override String get realDebridInstructions => '扫描二维码或打开链接，然后输入此激活码以连接 PlezyNG：';
	@override String get realDebridActivate => '打开 Real-Debrid 进行激活';
	@override String get realDebridCode => '激活码';
	@override String get realDebridConnectFailed => '无法连接 Real-Debrid。请重试。';
	@override String get allDebrid => 'AllDebrid';
	@override String get allDebridDescription => '通过 AllDebrid 账户播放受支持的种子流。';
	@override String get connectAllDebrid => '使用二维码连接';
	@override String get allDebridInstructions => '扫描二维码或打开链接以授权 PlezyNG。连接期间请保持此页面打开：';
	@override String get allDebridActivate => '打开 AllDebrid 进行激活';
	@override String get allDebridCode => '激活 PIN 码';
	@override String get allDebridConnectFailed => '无法连接 AllDebrid。请重试。';
	@override String get premiumize => 'Premiumize';
	@override String get premiumizeDescription => '通过 Premiumize 播放已缓存的种子流或浏览文件。';
	@override String get torbox => 'TorBox';
	@override String get torboxDescription => '通过 TorBox 播放已缓存的种子流或浏览文件。';
	@override String get connectApiKey => '使用 API 密钥连接';
	@override String apiKeyTitle({required Object service}) => '连接 ${service}';
	@override String get apiKey => 'API 密钥';
	@override String apiKeyHint({required Object service}) => '粘贴 ${service} 账户设置中的 API 密钥。PlezyNG 会在此设备上加密密钥，并将其保存在此个人资料中。';
	@override String get apiKeyConnectFailed => '无法验证此 API 密钥。请检查后重试。';
	@override String accountConnected({required Object username}) => '已连接：${username}';
	@override String get streamNeedsProvider => '连接 Debrid 服务以播放此种子流。';
	@override String get playViaProvider => '通过 Debrid 播放';
	@override String disconnectConfirm({required Object service}) => '断开 ${service}？';
	@override String get disconnectBody => 'PlezyNG 会移除此设备的授权，不会更改服务商中的文件或正在进行的传输。';
	@override String get streamsTitle => '选择串流';
	@override String get searchingStreams => '正在检查已连接的插件…';
	@override String get noStreams => '未找到此标题的串流。';
	@override String get manageConnections => '管理串流服务';
	@override String subtitleTracks({required Object count}) => '字幕轨道：${count}';
	@override String get chooseSubtitle => '选择字幕';
	@override String get chooseProvider => '选择 Debrid 服务';
	@override String get subtitleOff => '关闭字幕';
	@override String get subtitleLoadFailed => '无法加载此字幕。请尝试其他轨道。';
	@override String get subtitleApplied => '已选择播放字幕';
	@override String get streamLookupPartial => '部分插件无法访问。';
	@override String get streamLookupFailed => '无法检查已连接的插件。';
	@override String get streamOpenExternal => '打开外部链接';
	@override String get streamPrepare => '正在通过 Debrid 服务准备…';
	@override String get streamPrepareFailed => '无法准备此串流。请检查已连接的账户，然后尝试其他来源。';
	@override String get streamNeedsRealDebrid => '连接 Debrid 服务以播放此种子流。';
	@override String get streamUnsupported => '应用内播放器不支持此串流格式。';
	@override String get remoteNeedsEpisode => '请先选择剧集，再搜索串流。';
	@override String get remoteNeedsEpisodeNumber => '此剧集缺少季号或集号。';
	@override String get remoteNeedsExternalId => 'PlezyNG 找不到此标题的 IMDb 或 TMDB ID。';
	@override String get watchWithServices => '通过已连接的服务观看';
	@override String get chooseEpisode => '选择剧集';
	@override String get episodes => '剧集';
	@override String episodePosition({required Object season, required Object episode}) => '第 ${season} 季，第 ${episode} 集';
	@override String get episodeStreamHint => '打开此剧集的可用串流。';
	@override String get cloudFiles => '云端文件';
	@override String get browseCloud => '浏览文件';
	@override String get cloudEmpty => '此账户中没有找到可播放的视频文件。';
	@override String get cloudLoadFailed => '无法加载云端文件。请检查连接后重试。';
	@override String get providers => 'Debrid 服务商';
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
	@override String get signInWithPlexCardSubtitleScoped => '授权一个 Plex 账户。Plex Home 用户将成为 PlezyNG 用户资料。';
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
	@override String get directPlexServerUrl => 'Plex 服务器 URL';
	@override String get directPlexServerUrlHelper => '输入您的 Plex 媒体服务器的本地 IP 和端口。';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex 代币(可选)';
	@override String get plexTokenHelper => '放空,如果在此服务器上允许无 auth 访问。';
	@override String get plexTokenRequired => '请输入您的 Plex 代币(X-Plex-Token)。';
	@override String get connectDirectPlexCard => 'Plex 媒體伺服器(直接/本地)';
	@override String get connectDirectPlexCardSubtitle => '直接使用本地IP或URL连接,无需 plex.tv 帐户。';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => '直接使用本地IP或URL连接,连接到${name}。';
	@override String get insecureTitle => '未加密的连接';
	@override String insecureDescription({required Object url}) => '${url} 使用 HTTP。网络中的其他人可能读取或篡改您的密码、令牌和媒体内容。请尽可能使用 HTTPS。只有在您信任此网络并接受风险时才继续。';
	@override String get allowHttp => '允许 HTTP';
	@override String get httpsRequired => '使用 HTTPS 或明确允许未加密的连接。';
}

// Path: cast
class Translations$cast$zh extends Translations$cast$en {
	Translations$cast$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => '点击一个设备';
	@override String get searching => '寻找卡片设备';
	@override String connectedTo({required Object device}) => '连接到 ${device}';
	@override String get device => '加密装置';
	@override String get readyToCast => '准备放';
	@override String get subtitle => '字幕';
	@override String get serverNotAvailable => '媒体服务器不适用。';
	@override String get stopCasting => '停止加密';
	@override String get castToDevice => '点击设备';
	@override String get noEpisodeAvailable => '没有任何节目可播放。';
	@override String get startFailed => '无法开始投射,检查服务器并尝试一次。';
}

// Path: automation
class Translations$automation$zh extends Translations$automation$en {
	Translations$automation$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => '没有活跃的视频会话可以控制。';
}

// Path: notifications
class Translations$notifications$zh extends Translations$notifications$en {
	Translations$notifications$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => '新集';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appAccess
class Translations$appAccess$zh extends Translations$appAccess$en {
	Translations$appAccess$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '每個功能都免費嘗試7天';
	@override String get description => '开始一个七天的试用,完全访问每个PlezyNG功能,在试用期间没有费用,没有订阅,试用后,在您的商店价格上一生购买,终身开锁PlezyNG。';
	@override String get trialEndedDescription => '按商店显示的价格一次性购买，即可终身解锁 PlezyNG 的全部功能，无需订阅。';
	@override String get startTrial => '开始我的7天免费试验';
	@override String get trialActive => '您的7天全功能测试已活跃。';
	@override String get trialEnded => '你的七天审判结束了';
	@override String get trialStartFailed => '我无法在这个设备上保存测试,请再试一次。';
	@override String get lifetimeTitle => 'PlezyNG 终身禁用';
	@override String get lifetimeBody => '感谢!您终身访问所有 PlezyNG 功能。';
	@override String get manageTitle => 'PlezyNG 终身访问';
	@override String get manageDescription => '每個功能都免費嘗試7天,然後用一個付款解锁一生的一切,以您的商店的價格。';
	@override String buy({required Object price}) => '解锁所有功能为 ${price}';
	@override String get loadingPrice => '货物价格...';
	@override String get retryPrice => '回报价格 查看';
	@override String get restore => '恢复终身购买';
	@override String get pending => '您的购买正在等待付款或批准。商店完成交易后，终身使用权限将立即解锁。';
	@override String get storeUnavailable => '目前无法购买。请确认您已登录商店，且此设备允许购买。';
	@override String get productNotFound => 'PlezyNG 终身解锁 目前尚未在本商店提供。';
	@override String get productQueryFailed => '无法收取商店价格,请检查您的连接并尝试一次。';
	@override String get purchaseFailed => '購買不錯了,再試一次。';
	@override String get restoreFailed => '无法到达商店恢复您的购买,再试一次。';
	@override String get nothingToRestore => '已找到第 PlezyNG 终身购买号,用于此商店帐户。';
}

// Path: detail
class Translations$detail$zh extends Translations$detail$en {
	Translations$detail$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => '结束时间：${time}';
}

// Path: watchLink
class Translations$watchLink$zh extends Translations$watchLink$en {
	Translations$watchLink$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => '无法访问 Plex 服务器此链接。';
	@override String get notFound => '我无法在您的服务器上找到此节目或电影 Plex。';
	@override String get ambiguous => '此链接匹配多个服务器上的项目,并将服务器添加到链接中。';
	@override String get plexOnly => '目前仅支持 Plex 服务器的观看链接。';
	@override String get unsupportedItem => '观看链接只能打开一个节目或电影。';
	@override String get menuItem => '查看链接';
	@override String get dialogTitle => '查看链接';
	@override String get dialogShowHint => '打开此链接播放下一个节目. 添加 &mode=shuffle 到结尾播放节目在 shuffle 上。';
	@override String get dialogMovieHint => '打开这个链接播放电影。';
	@override String get copy => '复制';
	@override String get copied => '链接复制';
}

// Path: homeLayout
class Translations$homeLayout$zh extends Translations$homeLayout$en {
	Translations$homeLayout$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'Home 布局';
	@override String get resetToast => '主页重新设置到原始Plezy英雄配置';
	@override String get resetHeroTitle => '重定向英雄配置到存储Plezy?';
	@override String get resetHeroBody => '关闭所有内容行的焦点横幅设置，并恢复首页顶部的单个轮播横幅，如同引入焦点横幅行之前的布局。内容行的顺序和显示状态不受影响。';
	@override String get removeRowTitle => '取消家居序列?';
	@override String removeRowBody({required Object title}) => '${title} 将被删除,此不能被删除。';
	@override String get sync => '同步';
	@override String get syncAccountTitle => '与您的 Plex 帐户同步配置';
	@override String get syncAccountOn => '开启：此设备会与您的其他设备共享内容行顺序、内容行、焦点横幅和自动轮播设置。';
	@override String get syncAccountOff => '关闭:此设备保持其自己的配置。';
	@override String get syncNow => '现在的Sync';
	@override String get plexHomeManager => 'Plex 主持人';
	@override String get managePlexRows => '管理 Plex 行在 Plezy';
	@override String get managePlexRowsDescription => '开放组织主选行列';
	@override String get organizeHomeRows => '安排家居行';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} 行: 移动, 英雄, 自动滑动, 移除';
	@override String organizeLibraryRows({required Object library}) => '组织 ${library} 行';
	@override String organizeLibraryRowsDescription({required Object n}) => '继续观看 + ${n} 行: 移动, 图书馆, 家, 英雄, 自动滑板';
	@override String get renderAsHero => '显示为焦点横幅';
	@override String get heroOnlySingleCollection => '只有当此行解决到单一集合的实际标题时才可用';
	@override String get hero => '焦点横幅';
	@override String get autoSlide => '自动轮播';
	@override String get autoSlideDescription => '每隔几秒也会自动切换。电脑上的箭头按钮和电视遥控器的方向键始终可用，使用后会重新开始计时。';
	@override String get autoSlideEditDescription => '每隔几秒也会自动切换。关闭时，仅在点击电脑上的箭头按钮或按电视遥控器的左右方向键时切换。无论此设置是否开启，箭头按钮和方向键都可用。';
	@override String get enableHeroFirst => '英雄第一';
	@override String get showOnHome => '显示在主屏幕上';
	@override String get home => '首页';
	@override String get removeFromHome => '离开家';
	@override String get selectRowsFirst => '首先,选择下面的主行。';
	@override String plexManagedRows({required Object n}) => '${n} Plex 管理行';
	@override String get continueWatching => '继续观看';
	@override String get continueWatchingLibraryDescription => '图书馆的本质重建进展顺序';
	@override String get continueWatchingHomeDescription => '重新进展序列显示在家';
	@override String get nextUpHomeDescription => '下一篇 未观看的集合序列在主页上单独显示';
	@override String get library => '媒体库';
	@override String get showInRecommended => '图书馆推荐';
	@override String get customPlexRow => '定制 Plex 行';
	@override String get heroNeedsLibrary => '查看图书馆首先 - 英雄需要在某处展示';
	@override String get heroNeedsSurface => '查看图书馆或家先 - 英雄需要在某处展示';
	@override String get removeHub => '取消 Hub';
	@override String get noPlexRows => '第Plex号管理行返回此图书馆。';
	@override String get openDetails => '开放细节';
	@override String get heroCards => '英雄卡';
	@override String get tapHeroCard => '打破英雄卡';
	@override String get tvPlayFocus => '电视远程:突出点击播放按钮';
	@override String get tvPlayFocusDescription => '按方向键下键时，焦点会先停在播放按钮上，再移到下一行。关闭时会直接跳到下一行。';
	@override String get tvWrap => '电视远程: loop 英雄卡';
	@override String get tvWrapDescription => '在最后一张卡片上按右键会回到第一张；关闭时则停在最后一张。在第一张卡片上按左键始终会进入侧边栏。';
	@override String get castOnHero => '在焦点横幅上显示演员';
	@override String get castOnHeroDescription => '在焦点横幅底部显示演员列表。关闭时仅保留标题和简介。';
	@override String get customRows => '定位线';
	@override String get loading => '家用布局...';
	@override String get noCustomRows => '尚未有定位';
	@override String get addRowHint => '使用添加主行创建一个。';
	@override String get addHomeRow => '添加 Home Rue';
	@override String get addHomeRowDescription => '选择类别;新行将自动添加到组织者';
	@override String get removeRow => '取消行列';
	@override String get recentlyAdded => '最近添加';
	@override String get recentlyReleased => '最近发布';
	@override String get movieCollections => '电影收藏';
	@override String get showCollections => '展示集合';
	@override String get rowTitle => '路 标题';
	@override String get content => '内容';
	@override String get showThisRowIn => '显示此行在:';
	@override String get libraryRecommended => '推荐图书馆';
	@override String get heroCard => '英雄卡';
	@override String get heroCardDescription => '显示为一个全宽旋转卡,而不是海报架。';
	@override String get heroUnavailableDescription => '仅当此内容行展示单个合集中的具体媒体条目时才可用；选择多个合集时，没有可供轮播的单个媒体条目。';
	@override String get librariesSelection => '图书馆(所有未经检查的图书馆都包含)';
	@override String get librariesMergedDescription => '这里查看的每一个图书馆都合并到这个单一的行列。';
	@override String get movieCollectionsSelection => '电影收藏(每个选择的图书馆都没有查看)';
	@override String get showCollectionsSelection => '显示收藏品(每个选择的图书馆都没有查看)';
	@override String get collectionRowsDescription => '如果一个集合相匹配,其标题直接在序列中显示;如果一个集合多,每个集合都显示为单一的海报,则点击它以打开该集合。';
	@override String get allCollections => '所有收藏';
	@override String get noRowsHere => '目前还没有线条。';
	@override String get hideWatchedRows => '隐藏在行列中观看的物品';
	@override String get hideWatchedRowsDescription => '已看完的媒体条目会从首页和媒体库的推荐行中移除，尚未看完的条目会保留。';
	@override String get untitledCollection => '未经标题收藏';
	@override String get moveRowHint => '向上/下: 移动行 · 选择: 将此处放下 · 返回: 取消';
	@override String get organizeRowsHint => '选择行(或保持):移动 · 左/右:行选项 · 返回:完成';
	@override String get layoutNavDescription => '选择行、图书馆和收藏类别';
	@override String get editHomeRow => '编辑 主页 序列';
	@override String get resetHeroButton => '恢复 Plezy 默认焦点横幅布局';
	@override String get reorderingUnlocked => '重新排序 开锁';
	@override String get reorderingLocked => '重新安排锁';
	@override String get rowsCanBeDragged => '可以拖绳 - 点击锁,以防止';
	@override String get tapLockToDrag => '点击锁,拖行列';
	@override String customRowLabel({required Object title}) => '定位: ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => '隐藏';
	@override String get remove => '移除';
	@override String get libraryResumeRow => '图书馆的重复顺序';
	@override String get pressAgainToDelete => '再次按下删除';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => '到';
	@override String get resetHeroButtonDescription => '关闭所有内容行的焦点横幅设置，并恢复顶部的单个轮播横幅，如同引入焦点横幅行之前的布局。内容行顺序保持不变。';
	@override String get tapHeroCardDescription => '选择打字或选择一个英雄卡是否开始播放,或者打开它的细节。';
	@override String get heroTapPlayDescription => '立即启动所选择的项目。';
	@override String get heroTapDetailsDescription => '在选择行动之前,打开所选项目的详细信息。';
}

// Path: platform
class Translations$platform$zh extends Translations$platform$en {
	Translations$platform$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'PlezyNG 会连接到您本地网络中的媒体服务器和播放设备。';
	@override String get locationPermission => '当 iOS 要求提供位置权限才能检测本地网络并连接媒体服务器时，PlezyNG 会使用此权限。';
	@override String get photoLibraryPermission => '从照片图库中选择图片，用作媒体封面等图像。';
	@override String get cameraPermission => '扫描二维码以配对 Companion Remote。';
}

// Path: universalMedia
class Translations$universalMedia$zh extends Translations$universalMedia$en {
	Translations$universalMedia$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '开放媒体';
	@override String get shortcutHelp => '播放此会议的链接、播放列表或文件。';
	@override String get intro => '打开链接、播放列表或文件 Playback 使用 PlezyNG 的标准播放器,并且不会将历史添加到您的图书馆。';
	@override String get openWhat => '你想打开什么?';
	@override String get stream => '流地址';
	@override String get playlist => '播放列表';
	@override String get files => '设备文件';
	@override String get favorites => '保存流喜爱';
	@override String get address => '媒體地址';
	@override String get addressHelp => 'HTTPS 是优先的. 有认可或签名参数的 URL 仅用于此会议,并且不能保存为喜爱。';
	@override String get displayName => '显示名称(可选)';
	@override String get displayNameHelp => '选择玩家和系统媒体控制器的简称。';
	@override String get allowHttp => '允许未加密的 HTTP 连接';
	@override String get allowHttpHelp => 'HTTP 不加密连接. 只允许它在可靠的网络上. 当可能时使用 HTTPS。';
	@override String get advancedProtocols => 'MPV 仅:输入 RTSP、RTMP/RTMPS、UDP 或 RTP 地址,这些地址不能保存为最受欢迎的。';
	@override String get liveStream => '作为活着的待遇';
	@override String get liveStreamHelp => '使用此用于直播视频或广播电台. 该应用程序隐藏了时间栏,滑动按钮和 go-to-time 选项。';
	@override String get privateSession => '只有此播放使用地址. 保存一个合格流最喜欢的,以保持它在这个个人资料。';
	@override String get saveFavorite => '保存最喜欢';
	@override String get playNow => '现在玩';
	@override String get favoriteSaved => '流喜爱保存到此个人资料';
	@override String skippedEntries({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '${count} 不受支持或不安全的播放列表输入。',
		other: '${count} 不受支持或不安全的播放列表输入。',
	);
	@override String get playlistAddress => 'Playlist 地址';
	@override String get playlistAddressHelp => '從網頁地址開啟 M3U、M3U8 或 PLS 播放列表. Direct Stream 連結不會保存播放名單。';
	@override String get choosePlaylist => '选择 Playlist 文件';
	@override String get openPlaylist => '开放播放列表';
	@override String get playlistFormatsHelp => '一张播放列表可以包含最多1000个项目和2MB的HLS显示为流,所以玩家可以选择质量。';
	@override String get noFavorites => '尚未存储流喜爱. 喜爱留在此个人资料中。';
	@override String get removeFavorite => '删除流喜爱';
	@override String get filesHelp => '选择音频、视频或ISO文件,以便进行临时记录. 文件和URL不添加到图书馆历史。';
	@override String get chooseFiles => '选择文件';
	@override String fileQueue({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '1 选择的文件',
		other: '${count} 已选择的文件',
	);
	@override String get wifiTransfer => '通过 Wi-Fi 发送文件';
	@override String get wifiTransferHelp => '从同一信任网络的浏览器传输支持的文件。';
	@override String get wifiTransferIntro => '在另一个设备上的浏览器中打开此地址. 选择文件以将其添加到该设备的文件和书籍图书馆。';
	@override String get wifiTransferPrivacy => '本设备通过您的本地网络接收文件. 任何知道此地址的人都可以发送文件,直到您停止传输或地址在15分钟后终止。';
	@override String get wifiTransferStarting => '准备一个私人,时间有限的转会...';
	@override String get wifiTransferUnavailable => '无法启动转换,检查本地网络接入并尝试一次。';
	@override String get openThisAddress => '在发送设备上打开其中一个地址';
	@override String get copyAddress => '传输地址复制';
	@override String get addressCopied => '传输地址复制';
	@override String transferExpires({required Object time}) => '此地址在 ${time} 中终止。';
	@override String uploadCount({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '${count} 获取文件',
		other: '${count} 收到的文件',
	);
	@override String uploadedData({required Object size}) => '接收 ${size}';
	@override String get stopTransfer => '停止转让和取消地址';
	@override String get startTransfer => '转移开始';
	@override String get wifiImportedFiles => 'Wi-Fi 传输';
	@override String get wifiBrowserTitle => '向 PlezyNG 发送文件';
	@override String get wifiBrowserIntro => '选择音频、视频、电子书或漫画文件发送. 这些文件存储在该设备的文件和书籍库中. 最多: 100 个文件,每个文件 4 GiB,总共 10 GiB。';
	@override String get uploadFilesLabel => '文件发送';
	@override String get uploadSelected => '下载所选择的文件';
	@override String get uploadSelectFirst => '首先选择一个或多个文件。';
	@override String get uploading => '发送';
	@override String get uploadComplete => '文件添加到 PlezyNG。';
	@override String get uploadFailed => '文件无法添加,请保持此页面开放并再次尝试。';
	@override String get liveCue => '生活';
	@override String get liveSession => '直播流';
	@override String get liveCueHelp => '对于直播视频或无线电,应用程序隐藏了时间栏和跳跃按钮,它不会保存地址或观看历史。';
	@override String get sessionOnly => '此播放仅是会话';
	@override String get sessionOnlyHelp => 'Playback 永远不会保存进展或历史. 如果有资格,请将流作为最受欢迎的存储在此个人资料中。';
	@override String get pictureAdjustments => '图像调整';
	@override String get pictureHelp => '这些图像变更只影响此播放,它们在播放结束时重新设置。';
	@override String get resetPicture => '重新设置图像';
	@override String get brightness => '光明';
	@override String get contrast => '矛盾';
	@override String get gamma => '加姆';
	@override String get hue => '胡子';
	@override String get saturation => '土星';
	@override String get view360 => '平板视图360度视频';
	@override String get view360Help => 'MPV 需要 FFmpeg 的 v360 过滤器来查看此视图。';
	@override String get view360Unavailable => '这个MPV构建不能应用360度过滤器。';
	@override String get view360Yaw => '地平线视野';
	@override String get view360Pitch => '垂直视野';
	@override String get view360FieldOfView => '视野领域';
	@override String get recordStream => '记录直播';
	@override String get stopRecording => '停止和保存录制';
	@override String get recordingStarted => '记录是活跃的,让播放停止并保存录制。';
	@override String get recordingSaved => '录制完成并保存。';
	@override String get recordingActive => '放弃播放停止并保存它。';
	@override String get recordingFormatHelp => '对于视频,选择 MKV 或 MPEG-TS. 为音频,选择 MKA 或 MKV。';
	@override String get replaceRecordingTitle => '取代这张录音?';
	@override String get replaceRecordingHelp => 'PlezyNG 在录制时备份现有文件;如果无法保存新录制,PlezyNG 将备份恢复。';
	@override String get replaceRecording => '替换文件';
	@override String get discHelp => '在此计算机的光学驱动器中打开磁盘,您也可以从设备文件中打开ISO图像。';
	@override String get discs => '光学磁盘';
	@override String get dvd => 'DVD';
	@override String get bluray => '蓝光';
	@override String get audioCd => '音频CD';
	@override String get discAvailability => '磁盘播放需要兼容的MPV构建、支持的驱动器和操作系统许可,不能超越商业磁盘保护。';
	@override String get converterTitle => '转换本地媒体文件';
	@override String get converterHelp => '使用 FFmpeg 创建 MP4, M4A 或 MP3 副本。';
	@override String get converterIntro => '将本地音频或视频文件转换为多个设备上运行的格式。';
	@override String get converterPrivacy => 'FFmpeg 必须安装在此计算机上. 转换只读取本地文件. 不下载流或删除 DRM。';
	@override String get converterChooseInput => '选择本地媒体文件';
	@override String get converterFormat => '输出格式';
	@override String get converterMp4 => 'MP4 · H.264 和 AAC';
	@override String get converterM4a => 'M4A · AAC 音频';
	@override String get converterMp3 => 'MP3 · 音频';
	@override String get converterSaveAs => '保存转换的媒体作为';
	@override String get converterExtensionMismatch => '选择与所选输出扩展的文件名。';
	@override String get converterUnsupportedInput => '选择音频或视频文件。';
	@override String get converterLocalOnly => '所选择的文件不作为本地设备路径可用。';
	@override String get converterReplaceTitle => '取代此文件?';
	@override String get converterReplaceHelp => 'PlezyNG 恢复现有文件,直到转换的副本被保存。';
	@override String get converterStarting => '開始 FFmpeg...';
	@override String get converterProgress => '转换到这个计算机......';
	@override String get converterComplete => '转换完成,新文件已准备好。';
	@override String get converterFfmpegMissing => 'FFmpeg 无法找到所需的编码器. 使用 H.264, AAC 和 MP3 支持安装 FFmpEG,然后再次尝试。';
	@override String get converterFailed => '转换失败:检查源文件可以阅读,目的地有足够的免费空间。';
	@override String get converterCancelled => '转换取消了,不完整的输出被删除。';
	@override String get converterDesktopOnly => '本地转换可在桌面计算机上使用 FFmpeg 安装。';
	@override String get converterStart => '转换文件';
	@override String get mediaToolsTitle => '媒體工具';
	@override String get mediaToolsShortcut => '捕获或共享媒体,添加搜索扩展或使用命令行。';
	@override String get mediaToolsIntro => '选择一个专注的工具. 捕获和流出使用 FFmpeg 安装在这个桌面上. 扩展和 CLI 命令使用有限的 HTTPS 请求和现有 Open media 流。';
	@override String get mediaToolsAccessibility => '工具选项和控制器与触摸、指标、键盘和D-pad焦点工作。 录制、共享和搜索状态的变化被公布。';
	@override String get mediaTool => '媒體工具';
	@override String get captureIntro => '在此计算机上记录屏幕或相机到 MP4 文件. FFmpeg 必须安装并包含 H.264 编码器。';
	@override String get captureNoDevices => '没有屏幕或相机被发现 查看 FFmpeg 捕捉支持和操作系统隐私许可证。';
	@override String get captureSource => '屏幕或相机';
	@override String get captureScreen => '屏幕';
	@override String get captureAudioSource => '音频输入(可选)';
	@override String get captureAudioHelp => '添加来自微型或可用的输入的音频 设备选项取决于 FFmpeg 和系统许可。';
	@override String get captureAudioNone => '没有音频';
	@override String get captureDefaultAudio => '默认音频输入';
	@override String get captureWaylandHelp => 'Wayland 限制此 XWayland 捕获到 X display. XWayland 以外的 Windows 可能不会出现。';
	@override String get captureFrameRate => '记录框率';
	@override String get capturePrivacy => '录制仅存储到您选择的文件。 微型录制是可选的. PlezyNG 不会上传录制。';
	@override String get captureSaveAs => '保存屏幕录制如';
	@override String get captureExtensionMismatch => '在 .mp4 中选择终端的文件名。';
	@override String get captureFfmpegMissing => 'FFmpeg 或 H.264 视频编码器不适用. 安装支持的 FFmpeg 构建,然后再次尝试。';
	@override String get captureFailed => '记录无法保存 检查设备许可、可用的存储和 FFmpeg 支持。';
	@override String get captureSaved => '屏幕录制保存';
	@override String get captureElapsedLabel => '录制时间';
	@override String get captureStart => '开始录制';
	@override String get captureStop => '停止和拯救';
	@override String get captureMode => '捕捉';
	@override String get shareMode => '分享';
	@override String get shareIntro => '将本地媒体文件发送到您的私人网络上的另一个设备. PlezyNG 创建一个暂时的 HLS 流。';
	@override String get sharePrivacy => '您的本地网络的任何人,谁接收私人链接可以观看,而它是活跃的. 链接结束后60分钟. 停止共享,关闭服务器并取消链接。';
	@override String get shareChooseFile => '选择媒体文件';
	@override String get shareChooseHelp => '选择一个本地的音频或视频文件. 该文件留在此计算机上。';
	@override String get shareFfmpegMissing => 'FFmpeg 或 H.264/AAC 编码器不适用. 安装 FFmpeg 与 H.264 和 AAC 编码支持。';
	@override String get shareFailed => '流量无法意外地开始或停止。 查看 FFmpeg 和网络访问。';
	@override String get shareActive => '流在您的私人网络上已经准备好了。';
	@override String get shareEnded => '媒體已經到達了結局,並且不再被分享。';
	@override String get shareStopped => '分享停止了,暂时链接不再有效。';
	@override String get shareUrlCopied => '流地址复制。';
	@override String get shareOpenUrl => '在另一台设备上的一个播放器中打开此地址';
	@override String get shareQrLabel => '临时流地址的QR代码';
	@override String get shareQrHelp => '扫描与同一私人网络连接的兼容播放器。';
	@override String get shareHttpHint => '此流使用未加密的 HTTP. 在 PlezyNG 中,允许 HTTP 在打开它之前。';
	@override String get shareCopyUrl => '复制流地址';
	@override String get shareExpiresLabel => '链接终止';
	@override String get shareStarting => '准备流...';
	@override String get shareStart => '开始分享';
	@override String get shareStop => '停止分享';
	@override String get extensionsMode => '扩展和CLI';
	@override String get extensionsIntro => '添加一个数据仅搜索扩展,以找到媒体. 选择一个结果,将其加载到熟悉的 Open media 表格。';
	@override String get extensionsPrivacy => '一个显明可以定义一个 HTTPS 搜索终点和地图响应字段. 它不能运行代码,添加请求标题,阅读文件,或启动盾牌命令。';
	@override String get extensionImport => '添加扩展显明';
	@override String get extensionEmpty => '尚未搜索服务. 选择一个可靠的显明 JSON 文件添加一个。';
	@override String get extensionChoose => '搜索服务';
	@override String get extensionSearchConsent => '每个搜索都会发送您的单词到这个 HTTPS 服务. 结果仅在您选择一个后打开。';
	@override String get extensionSearchLabel => '搜索媒体';
	@override String get extensionSearch => '搜索';
	@override String get extensionSearching => '寻找...';
	@override String get extensionNoResults => '没有安全的媒体结果返回,请尝试另一个搜索。';
	@override String get extensionInstallTitle => '添加此搜索服务?';
	@override String get extensionReplaceTitle => '更新此搜索服务?';
	@override String get extensionService => '服务';
	@override String get extensionEndpoint => 'HTTPS 终点';
	@override String get extensionConsent => '您的搜索文本被发送到此服务. 该示文稿不包含执行代码. 继续只有如果你信任这个终点。';
	@override String get extensionInstall => '添加服务';
	@override String get extensionReplace => '更新服务';
	@override String get extensionRemoveTitle => '删除此搜索服务?';
	@override String get extensionRemoveHelp => '这将取消该服务从此个人资料中. PlezyNG 不联系其终点。';
	@override String get extensionRemove => '取消服务';
	@override String get extensionInvalidManifest => '此文件不是一个支持的扩展显而易见. 查看 Open media 格式指南。';
	@override String get extensionSaveFailed => '该扩展无法存储到活跃的个人资料。';
	@override String get extensionSearchFailed => '搜索服务没有返回有效的答案 检查终点并尝试一次。';
	@override String get cliTitle => '命令线';
	@override String get cliHelp => '使用 plezyctl 指南来验证一个显明或搜索相同的扩展. 每次搜索之前,查看 HTTPS 服务. 结果在现有媒体格式中打开; 选择播放按钮开始。';
	@override String get cliCopyExample => '复制命令示例';
	@override String get cliCopied => '命令例子复制';
}

// Path: fileSources
class Translations$fileSources$zh extends Translations$fileSources$en {
	Translations$fileSources$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '文件和书籍';
	@override String get subtitle => '阅读、听、从自己的文件中观看。';
	@override String get add => '添加源';
	@override String get importFiles => '进口文件';
	@override String get localFiles => '在此设备上';
	@override String get source => '源';
	@override String get name => '名称';
	@override String get endpoint => '服务器 URL';
	@override String get smbEndpointHint => '示例：smb://nas/Movies';
	@override String get smbEndpointInvalid => '请输入 SMB 服务器和一个共享文件夹。';
	@override String get root => '文件夹或前缀';
	@override String get smbFolderHelp => '留空以使用整个共享文件夹，或输入其中的某个文件夹。';
	@override String get username => '用户名';
	@override String get smbDomain => '域（可选）';
	@override String get password => '密码';
	@override String get token => 'API 标志';
	@override String get accessKey => '关键 ID 访问';
	@override String get secretKey => '秘密访问密钥';
	@override String get sessionToken => '會議代碼(可選)';
	@override String get region => '区域';
	@override String get clientId => '客戶 ID';
	@override String get clientSecret => 'OAuth 客户端秘密(仅限 Google 桌面)';
	@override String get allowHttp => '允许在可信网络上使用未加密的 HTTP';
	@override String get smbEncryption => '加密 SMB3 连接';
	@override String get smbEncryptionHint => '当 NAS 支持时，使用 SMB3 加密。';
	@override String get connect => '连接';
	@override String get cancel => '取消';
	@override String get save => '保存';
	@override String get close => '关闭';
	@override String get removeSource => '连接源';
	@override String get disconnectMessage => '要断开此来源的连接吗？已下载的文件以及阅读和收听历史将保留在此设备上。';
	@override String get localFolder => '选择文件夹';
	@override String get empty => '这里还什么都没有';
	@override String get emptyHint => '添加来源，或导入书籍、有声书、音乐或视频。';
	@override String get search => '搜索此文件夹';
	@override String get searchCached => '搜索 保存图书馆';
	@override String get refresh => '刷新';
	@override String get loadMore => '加载更多';
	@override String get offline => '可用 offline';
	@override String get download => '保持离线';
	@override String get removeDownload => '删除非线复印件';
	@override String get continueReading => '继续阅读';
	@override String get continueListening => '继续听';
	@override String get continueWatching => '继续观看';
	@override String get read => '阅读';
	@override String get listen => '听';
	@override String get play => '播放';
	@override String get pause => '暂停';
	@override String get stop => '停止';
	@override String get startOver => '开始过';
	@override String get finished => '已播放完毕';
	@override String get markFinished => '马克结束了';
	@override String get markUnfinished => '马克 未完成';
	@override String get editions => '版和文件';
	@override String get chapters => '章节';
	@override String get bookmarks => '书标和笔记';
	@override String get bookmark => '添加 Bookmark';
	@override String get highlight => '突出';
	@override String get note => '注目';
	@override String get delete => '删除';
	@override String get export => '出口笔记';
	@override String get exported => '出口的笔记';
	@override String get sync => '同步进展';
	@override String get synced => '进展合成';
	@override String get conflict => '另一个设备有不同的位置,选择去哪里。';
	@override String get useLocal => '使用此设备';
	@override String get useRemote => '使用其他设备';
	@override String get history => '位置历史';
	@override String get groupAudio => '听作一本音频书';
	@override String get groupHint => '将目前在此文件夹中加载的音频文件结合起来. 首先加载所有页面。';
	@override String get order => '文件命令';
	@override String get moveUp => '移动上';
	@override String get moveDown => '移动下';
	@override String get speed => '播放速度';
	@override String get sleep => '睡眠定时器';
	@override String get sleepOff => '关闭';
	@override String get endChapter => '章节的结尾';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(count,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)}分钟',
	);
	@override String get skipBack => '滑落回';
	@override String get skipForward => '滑向前';
	@override String get smartRewind => '休假后智能回归';
	@override String get playbackOptions => '听力选项';
	@override String remaining({required Object time}) => '${time} 剩余';
	@override String get contents => '内容';
	@override String get readerSettings => '阅读设置';
	@override String get fontSize => '文本大小';
	@override String get lineHeight => '线路空间';
	@override String get margin => '马格林';
	@override String get font => '型号';
	@override String get serif => '衬线字体';
	@override String get sans => '无衬线字体';
	@override String get mono => '等宽字体';
	@override String get columns => '列';
	@override String get scroll => '垂直滑动';
	@override String get justify => '两端对齐';
	@override String get readerTheme => '页面外观';
	@override String get appTheme => '跟随应用主题';
	@override String get paper => '纸张';
	@override String get sepia => '塞比亚';
	@override String get night => '夜晚';
	@override String get readAloud => '朗读此页';
	@override String get readAlong => '跟读';
	@override String get stopReading => '停止朗读';
	@override String get searchBook => '搜索书中';
	@override String get noMatches => '没有比赛';
	@override String get previousPage => '上一页';
	@override String get nextPage => '下一页';
	@override String page({required Object number}) => '页面 ${number}';
	@override String get externalBlocked => '阅读器中已禁用书籍的外部链接。';
	@override String get loading => '开...';
	@override String get narrator => '讲话者';
	@override String get audio => '音频';
	@override String get video => '视频';
	@override String get ebooks => '电子书';
	@override String get all => '全部';
	@override String get downloads => '非线文件';
	@override String get confirmDelete => '要删除所选的离线副本吗？阅读或收听进度和笔记将会保留。';
	@override String get errorAuthentication => '再登录,重新连接这个来源。';
	@override String get errorPermission => '此源未允许访问所要求的文件。';
	@override String get errorUnavailable => '源不可用 再试一次,或者打开一个离线副本。';
	@override String get errorUnsupported => '此设备不支持该格式或连接方式。请查看来源设置指南。';
	@override String get errorInvalidData => '此文件或服务器回复无法安全地阅读。';
	@override String get errorCancelled => '行动被取消了。';
	@override String get errorConflict => '阅读或收听位置已在另一个会话中改变。请重新打开项目，选择要使用的位置。';
	@override String get signIn => '登录';
	@override String get reconnect => '重新连接';
	@override String get folderHelp => '留空可从来源根目录开始。S3 URL 包含存储桶名称。';
	@override String get preferences => '偏好';
	@override String get timePosition => '位置';
	@override String get audioTrack => '音频轨道';
	@override String get subtitleTrack => '标题 轨道';
	@override String get none => '无';
	@override String get fullscreen => '全屏幕';
	@override String get syncLocation => '进展同步文件夹(可选)';
	@override String get syncLocationHint => '用于保存 PlezyNG 状态的专用 WebDAV 文件夹。采用条件写入，不会更改媒体文件。';
	@override String get audiobooks => '音频书籍';
	@override String get comics => '漫画';
	@override String get scan => '扫描书籍和媒体';
	@override String get browserReader => '开放读者';
	@override String get browserReaderHelp => '阅读器在您的浏览器中开放. 保持 PlezyNG 开放,以保存您的位置和笔记。';
	@override String get on => '到';
	@override String get advancedSetup => 'App 登记';
	@override String get microsoftSignIn => '与Microsoft登录';
	@override String get zoomIn => '放大';
	@override String get zoomOut => '出Zoom';
	@override String get fitPage => '合适页面';
	@override String get fitWidth => '合适的宽度';
	@override String get actualSize => '目前大小';
	@override String get goToPage => '去页面';
	@override String get goToSection => '去章节';
	@override String pageRange({required Object count}) => '输入 1 到 ${count} 的数字';
	@override String get pageLayout => '页面Layout';
	@override String get automatic => '自动';
	@override String get singlePage => '单页';
	@override String get twoPages => '二页';
	@override String get readingDirection => '阅读方向';
	@override String get leftToRight => '左向右';
	@override String get rightToLeft => '从右到左';
	@override String get letterSpacing => '信 空间';
	@override String get wordSpacing => '字 空间';
	@override String get readerControlsHelp => '双指张开或使用缩放控件放大页面，拖动可平移页面。按 Ctrl/⌘ 与 + 或 − 调整缩放，按 Ctrl/⌘ 与 0 重置缩放。使用 Page Up 和 Page Down 翻页。';
	@override String get imagePage => '漫画页面';
	@override String get resetReader => '重新设置阅读偏好';
	@override String get zoom => '缩放';
	@override String get useFiles => '使用文件和书籍';
	@override String get cancelScan => '取消扫描';
	@override String get googleDrive => 'Google Drive';
	@override String get offlineQuota => '离线下载限制';
	@override String get offlineQuotaHelp => '设置离线副本、导入文件和排队中下载占用的最大空间。降低上限不会删除现有副本。';
	@override String get offlineStorageUsage => '非线存储';
	@override String get reservedStorage => '保留';
	@override String get downloadQueue => '下载Queue';
	@override String get downloadRunning => '下载';
	@override String get downloadQueued => '等待';
	@override String get downloadPaused => '休息';
	@override String get downloadFailed => '需要退休';
	@override String get importing => '进口';
	@override String get importInterrupted => '进口中断 · 删除清理';
	@override String get errorQuotaExceeded => '已达到离线存储上限。请提高上限或移除已下载的副本。';
	@override String get errorStorageLow => '没有足够的免费设备存储,以保留保护备份。';
	@override String get errorStorageUnavailable => 'PlezyNG无法检查免费设备存储,所以写作停止了。';
	@override String get removeDownloadJob => '删除下载';
	@override String get downloadAlreadyComplete => '此下载完成之前,它可以被删除. 该项目现在可用于离线。';
	@override String get confirmRemoveDownloadJob => '要移除此下载并丢弃已下载的部分数据吗？阅读位置和笔记会保留。';
}

// Path: lending
class Translations$lending$zh extends Translations$lending$en {
	Translations$lending$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '公共图书馆';
	@override String get add => '添加图书馆';
	@override String get other => '另一家图书馆';
	@override String get libraryName => '图书馆名称';
	@override String get libraryUrl => '图书馆网站';
	@override String get libraryUrlHint => '使用您的图书馆的目录或登录页面。';
	@override String get intro => '从图书馆借阅，让书籍随时相伴。';
	@override String get handoff => '登录、借款和安全阅读,您图书馆的服务。';
	@override String get openService => '开放图书馆';
	@override String get findLibrary => '找个图书馆';
	@override String get search => '搜索书籍和作家';
	@override String get catalogue => '目录';
	@override String get loans => '借阅';
	@override String get holds => '预约';
	@override String get signIn => '与您的图书馆登录';
	@override String get waiting => '结束登录在您的浏览器,然后返回这里。';
	@override String get cancel => '取消';
	@override String get disconnect => '取消图书馆';
	@override String get disconnectMessage => '要从此个人资料中移除此图书馆吗？借阅和预约记录仍会保留在图书馆。';
	@override String get getBook => '获书';
	@override String get checkAvailability => '查看可用性';
	@override String get available => '可借阅';
	@override String get unavailable => '目前不可用';
	@override String get borrow => '借阅';
	@override String get placeHold => '预约借阅';
	@override String get returnBook => '提前归还';
	@override String get cancelHold => '取消预约';
	@override String get confirmBorrow => '借这本书从图书馆里?';
	@override String get confirmReturn => '现在归还此书吗？您可能需要重新借阅才能继续阅读。';
	@override String get confirmCancelHold => '要取消此书的预约吗？';
	@override String get email => '留下通知电子邮件';
	@override String due({required Object date}) => '归还日期：${date}';
	@override String queue({required Object position}) => '排队位置：${position}';
	@override String get empty => '还没有标题。';
	@override String get openLibraryNote => '探索 Open Library 的目录。每本书的页面上都会显示阅读和借阅选项。';
	@override String get more => '加载更多';
	@override String get gateway => '图书馆登录服务';
	@override String get gatewayHint => '由您的图书馆或管理员提供,PlezyNG。';
	@override String get advanced => '图书馆集成';
	@override String get loadLibraries => '选择您的图书馆';
	@override String get expired => '此借阅已到期。';
	@override String get updated => '图书馆更新';
	@override String get continueService => '继续服务';
	@override String get comingSoon => '借款 即将到来';
	@override String get comingSoonDescription => '即将支持 Libby 集成。在连接功能完成之前，您可以先在 Libby 中使用图书馆服务。';
	@override String get suspendHold => '暂停预约';
	@override String get resumeHold => '恢复预约';
	@override String get suspendMessage => '要保留排队位置，让下一位读者先借阅此副本吗？您可以稍后恢复预约。';
	@override String get resumeMessage => '要恢复此预约，以便图书馆为您提供下一份可借阅的副本吗？';
	@override String get editEmail => '更改通知电子邮件';
}

// Path: audiobook
class Translations$audiobook$zh extends Translations$audiobook$en {
	Translations$audiobook$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get syncTitle => '阅读与倾听Sync';
	@override String get syncHelp => '在您的设备上保持阅读位置、倾听位置、完成状态、图标和笔记。 选择附加存储帐户并在每个设备上使用相同的同步代码. 阅读和倾听保持分开。';
	@override String get addSyncSource => '首先将 Google Drive、OneDrive、Dropbox、WebDAV 或 S3 添加到文件和书籍中。';
	@override String get syncDestination => '同步存储帐户';
	@override String get syncFolder => '同步文件夹或预定';
	@override String get syncFolderHelp => '在 WebDAV 源内使用一个单独的现有文件夹,或一个专门的 S3 预定。';
	@override String get syncCode => '个人同步代码';
	@override String get syncCodeHelp => '在您的第一台设备上创建一个代码,然后在您的其他设备上输入该代码. 保持一个私人副本:它是您的加密状态的关键。';
	@override String get showCode => '显示或隐藏同步代码';
	@override String get newSyncCode => '创建一个新的同步代码';
	@override String get saveSync => '保存和同步';
	@override String get disableSync => '在此设备上关闭同步';
	@override String get syncSourceDisconnect => '移除此来源会关闭此设备上的阅读和收听同步。加密的同步文件仍会保留在存储服务提供商处。';
	@override String get syncReconnect => '重新连接存储帐户';
	@override String lastSynced({required Object time}) => '上一篇: ${time}';
	@override String get syncPrivacy => '仅存储加密的进度和笔记。音频文件、电子书文件、账号令牌和密码不会上传。Google Drive 和 OneDrive 使用应用专用存储空间；Dropbox 使用 PlezyNG Sync。启用同步时，可能会请求额外的写入权限。启用后，进度同步由此存储目标负责，服务器进度保持独立。关闭同步后，本地历史记录和远程状态仍会保留。';
	@override String get syncConflicts => '选择重定向的地方';
	@override String get conflictHelp => '这些更改是分别独立做出的。请选择要保留的进度位置或书签版本。时间戳较新或进度百分比较高的版本不会自动优先保留。';
	@override String syncDevice({required Object device}) => '裝置 ${device}';
	@override String get syncUnknownDevice => '未知设备';
	@override String get deletedBookmark => '删除图标';
	@override String get finished => '结束';
	@override String readingPosition({required Object percent}) => '阅读 · ${percent}%';
	@override String get chapterTimeline => '第四章 进展';
	@override String get bookTimeline => '全书进展';
	@override String bookRemaining({required Object time}) => '本书剩余时间：${time}';
	@override String chapterRemaining({required Object time}) => '此分類上一篇: ${time}';
	@override String get unknownRemaining => '全部时间可用,当部分被播放时';
	@override String get undoSeek => '最后寻找';
	@override String get customSpeed => '定制播放速度';
	@override String get speedHelp => '选择速度从 0.25× 到 4×。';
	@override String get apply => '應用';
	@override String get customSleep => '定制睡眠时间';
	@override String get sleepMinutes => '时间(1 - 1440)';
	@override String sleepChapters({required Object count}) => '播放完${count}章后停止';
	@override String get extendSleep => '添加5分钟';
	@override String sleepRemaining({required Object time}) => '睡眠时间: ${time}';
	@override String get useDefaults => '使用这些听力控制器为新书';
	@override String get librarySort => '各式各样的书籍';
	@override String get sortTitle => '标题';
	@override String get sortAuthor => '作者';
	@override String get sortNarrator => '讲话者';
	@override String get sortSeries => '系列命令';
	@override String get sortRecent => '最近开放';
	@override String get statusFilter => '阅读状态';
	@override String get statusAll => '所有书籍';
	@override String get statusNew => '没有开始';
	@override String get statusProgress => '进展';
	@override String get statusFinished => '结束';
	@override String get goToTime => '走到时间';
	@override String get timeHelp => '时间: 分钟: 秒或 分钟: 秒';
	@override String get recoveryHelp => '移动或修复同步数据前，请先导出近期的加密备份。导入内容会与当前状态合并，不会覆盖本地同步历史。请另行保存同步代码。';
	@override String get recoveryExport => '输出加密恢复文件';
	@override String get recoveryImport => '输入加密恢复文件';
	@override String get recoveryImportConfirm => '将此加密恢复文件与当前阅读位置和笔记相结合吗?现有历史记录将被保留. 共享图书馆和项目 ID 不包含; 在进口之前,在每个设备上设置匹配 ID。';
	@override String get recoveryExported => '加密恢复文件保存。';
	@override String get recoveryImported => '恢复数据合并。';
}

// Path: sourceSetup
class Translations$sourceSetup$zh extends Translations$sourceSetup$en {
	Translations$sourceSetup$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get savedCertificate => '已保存的服务器证书';
	@override String get nfsEndpointInvalid => '请输入 NFS 地址，例如 nfs://nas:2049/export。';
	@override String get dlnaNone => '未找到 DLNA 服务器。请手动输入设备描述文件的地址。';
	@override String get dlnaServers => 'DLNA 媒体服务器';
	@override String get dlnaUnavailable => '无法在此网络上发现 DLNA 设备。请手动输入设备描述文件的地址。';
	@override String get dlnaSearching => '正在本地网络中搜索 DLNA 服务器';
	@override String get networkSearching => '正在搜索本地网络…';
	@override String get dlnaDiscover => '发现 DLNA 服务器';
	@override String get dlnaHelp => '设备发现需要本地网络支持组播。如果没有找到服务器，请在上方输入设备描述文件的地址。';
	@override String get dlnaRoot => 'DLNA 对象 ID；留空以使用设备根目录。';
	@override String get passwordOrKey => '请输入密码，或在下方添加私钥。';
	@override String get sshFingerprint => 'SSH 主机密钥 SHA256 指纹';
	@override String get sshFingerprintHelp => '请向服务器管理员核实。在服务器上运行 ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub，并使用显示的 SHA256 值。';
	@override String get sshFingerprintKeep => '留空以保留当前固定的指纹，或输入新的服务器指纹。';
	@override String get sshAuthentication => 'SSH 公钥认证';
	@override String get sshAuthenticationHelp => '可选；也支持密码认证。';
	@override String get privateKey => '私钥（PEM 或 OpenSSH 格式）';
	@override String get privateKeyPassphrase => '私钥口令';
	@override String get nfsMountPort => 'NFS 挂载服务 TCP 端口';
	@override String get nfsMountPortHelp => '默认值：20048';
	@override String get nfsUserId => 'NFS 用户 ID（AUTH_SYS）';
	@override String get nfsUserIdHelp => '默认值：1000。请使用 NAS 导出配置允许的用户 ID。';
	@override String get nfsGroupId => 'NFS 组 ID（AUTH_SYS）';
	@override String get nfsGroupIdHelp => '默认值：1000。请使用 NAS 导出配置允许的组 ID。';
	@override String get nfsEncryption => '要求加密 NFS 连接（RPC-with-TLS）';
	@override String get nfsEncryptionHelp => '要求 NFS 和挂载服务使用 TLS 1.3。如果 NAS 不支持，将拒绝连接。';
	@override String get nfsTrustCertificate => '自定义 NFS CA 或服务器证书（PEM，可选）';
	@override String get nfsTrustHelp => '使用此设备信任的证书时请留空。需要时可添加私有 CA 或自签名服务器证书；证书中的名称必须与 NFS 地址的主机名匹配。';
	@override String get nfsTrustInvalid => '请使用 PEM 格式的 CA 或服务器证书。不要包含私钥。';
	@override String get addTrustCertificate => '添加自定义信任证书';
	@override String get replaceTrustCertificate => '替换已保存的自定义证书';
	@override String get nfsTlsHelp => 'RPC-with-TLS 使用常规 NFS 和挂载服务端口，并要求 NAS 支持 RFC 9289。必须使用 TLS 1.3。主机名或 IP 地址必须与证书匹配。加密通道内仍需使用 AUTH_SYS UID/GID。';
	@override String get clientCertificate => '客户端证书（可选）';
	@override String get clientCertificateHelp => '允许 NAS 验证此客户端的身份；AUTH_SYS ID 仍受 NAS 导出策略约束。';
	@override String get savedIdentity => '将使用已保存的客户端身份凭据。';
	@override String get replaceIdentity => '替换已保存的客户端身份凭据';
	@override String get chooseIdentity => '选择 PKCS#12 客户端身份凭据';
	@override String get identityPassphrase => '客户端身份凭据口令';
	@override String get identityPassphraseHelp => '如果文件没有口令，请留空。';
	@override String get removeIdentity => '移除已保存的客户端身份凭据';
	@override String get identityStorageHelp => '客户端身份凭据保存在加密的来源凭据存储中。保持此部分不变，即可保留已保存的身份凭据。';
	@override String get nfsLimitations => '以只读方式通过 TCP 使用 NFSv3。不使用 RPC-with-TLS 时，NFS 流量不会加密。NAS 必须允许所选 AUTH_SYS ID 和非特权客户端端口（导出选项通常称为“insecure”）。不支持 NFSv4 和 UDP。';
	@override String get nfsSetupHelp => 'NFS 设置帮助';
	@override String get nfsSetupHint => '如果无法建立连接，请检查这些设置。';
	@override String get nfsSetupDetails => '请使用通过 TCP 提供的 NFSv3 导出。要求加密时，NFS 服务和挂载服务必须都支持 RPC-with-TLS。如果服务器证书受此设备信任，自定义证书可留空；否则请添加 NAS 的 CA 或自签名证书。证书名称必须与端点中的主机名匹配。如果 NAS 要求双向 TLS，请添加其 PKCS#12 客户端身份凭据。最后，确认导出配置允许所设的 AUTH_SYS UID/GID 和客户端端口策略。';
	@override String get ftpHelp => 'FTP 使用被动模式。未加密的 FTP 使用 ftp://，显式 TLS 使用 ftpes://；ftps:// 使用 TLS（端口 990 为隐式 TLS，其他端口为显式 TLS）。';
	@override String get openSubtitles => 'OpenSubtitles';
	@override String get subtitleSetup => '为独立视频提供可选的字幕搜索。';
	@override String get apiKey => 'API 密钥';
	@override String get optionalUsername => '账户用户名（可选）';
	@override String get optionalPassword => '账户密码（可选）';
	@override String get subtitlePrivacy => '请从 opensubtitles.com 获取 API 密钥。搜索会发送视频标题和可用的 IMDb/TMDB ID，绝不会发送视频文件。密钥和可选的账户凭据会随此来源加密保存。';
	@override String get automaticMetadata => '自动获取在线视频元数据';
	@override String get metadataPrivacy => '仅发送文件名中的标题、年份和集数，或 NFO ID，绝不发送媒体文件或凭据。NFO 字段始终优先。';
	@override String get nfsEncryptionFailure => '对于加密 NFS，请检查 NAS 的两项服务是否支持 RFC 9289 和 TLS 1.3，并核对证书名称以及导出 UID/GID。PlezyNG 不会在不加密的情况下重试此连接。';
	@override String get sourceConnecting => '正在连接来源';
	@override String get metadataSearchPrivacy => '此标题搜索由 Trakt 处理。只会发送您输入的标题，不会发送视频或来源凭据。';
	@override String get chooseMatch => '选择匹配结果';
	@override String get metadataMatchHelp => '选择前请核对标题和年份。Trakt 会收到搜索标题；视频文件会保留在原来源中。';
	@override String get metadataNoMatches => '未找到在线标题匹配结果。请尝试其他标题。';
	@override String get metadataSearch => '搜索在线元数据';
	@override String get metadataLoading => '正在查询在线电影和剧集信息…';
	@override String get metadataFromTrakt => '来自 Trakt 的在线元数据';
	@override String get metadataNoAutomaticMatch => '未找到自动匹配的标题。请搜索标题并选择匹配结果。';
	@override String get metadataFailed => '无法加载在线元数据。仍可播放媒体和查看本地信息。';
	@override String get videoDetailsLoading => '正在加载视频信息';
	@override String get subtitleKeyRequired => '需要 OpenSubtitles API 密钥';
	@override String get subtitleKeyHelp => '请编辑此文件来源，在可选的字幕设置中添加 OpenSubtitles API 密钥。';
	@override String get subtitleSearchFailed => '字幕搜索失败。请检查 API 密钥、网络连接和服务访问权限。';
	@override String get subtitleApplyFailed => '无法下载或应用此字幕。请检查连接并尝试其他结果。';
	@override String get subtitleSearch => '搜索 OpenSubtitles';
	@override String get subtitleSearchPrivacy => '搜索会使用标题和可用的 IMDb/TMDB ID。视频文件会保留在原来源中。选择前请核对语言、强制字幕或听障字幕标记以及评分。';
	@override String get movieOrShow => '电影或剧集';
	@override String get subtitleTitleHint => '输入标题以缩小结果范围';
	@override String get subtitleLanguage => '字幕语言';
	@override String get subtitleSearching => '正在搜索 OpenSubtitles';
	@override String get subtitleNoMatches => '未找到匹配的字幕。请尝试其他标题或语言。';
	@override String get downloadSubtitle => '下载字幕';
	@override String get subtitle => '字幕';
	@override String get nfsTlsRequired => '要求 RPC-with-TLS';
	@override String get nfsUnencrypted => '未加密的 NFS';
	@override String get tlsEncrypted => '已启用 TLS 加密';
	@override String get ftpPlain => '未加密的 FTP';
	@override String get sshPinned => 'SSH 加密 · 主机密钥已固定';
	@override String get smbEncrypted => 'SMB3 加密已开启';
	@override String get smbUnencrypted => 'SMB3 加密已关闭';
	@override String get httpUnencrypted => 'HTTP 无传输加密';
	@override String get checkEndpointSecurity => '请检查端点安全性';
	@override String fieldRequired({required Object label}) => '请填写${label}。';
	@override String integerRange({required Object min, required Object max, required Object label}) => '请输入 ${min} 至 ${max} 之间的${label}。';
	@override String replaceFile({required Object name}) => '替换 ${name}';
	@override String selectedIdentity({required Object name}) => '已选客户端身份凭据：${name}';
	@override String subtitleRating({required Object rating}) => '评分 ${rating}';
	@override String subtitleDownloading({required Object title}) => '正在下载字幕：${title}';
	@override String get sharedEntryPair => '将此项目配对';
	@override String get sharedEntryPairHelp => '在每台设备上为此项目输入相同的 ID。使用稳定的共享标识符，或生成一个并复制到对应项目。只有版本的文件类型、大小和顺序都一致时，阅读进度才会关联。留空会移除此映射。';
	@override String get sharedEntryId => '共享项目 ID';
	@override String get generateSharedEntryId => '创建共享项目 ID';
	@override String get sharedLibraryId => '共享图书馆 ID(可选)';
	@override String get sharedLibraryHelp => '使用相同 ID 在開啟相同圖書館的裝置上. 這個公共 ID 有助於在不同的來源連接中進行閱讀進步和筆記; 它不是密碼. 当提供商使用不同的項目 ID 時,將這些項目從其細節屏幕組合。';
	@override String get sharedLibraryInvalid => '使用 8 至 100 个字母、数字、点、字幕或字符。';
	@override String get generateSharedLibraryId => '创建共享图书馆 ID';
	@override String get nfsReadAhead => 'NFS Read-ahead 请求';
	@override String get nfsReadAheadHelp => '更多的平行阅读可以改善快速NAS或网络的通道。使用1如果服务器限制当前请求。';
	@override String get nfsReadTest => '测量NFS阅读性能';
	@override String get nfsReadTestHelp => '从最大的文件中读到64 MiB,以测量这个NAS连接,这使用网络带宽。';
	@override String get nfsQualificationResult => 'NFS 阅读测量';
	@override String get nfsReadBytes => '数据阅读';
	@override String get nfsReadSpeed => '测量速度';
	@override String get nfsReadRequests => '阅读请求';
	@override String get sharedEntryConflict => '此共享项目 ID 已与本图书馆中的另一个项目相匹配. 选择不同的 ID。';
}

// Path: comics
class Translations$comics$zh extends Translations$comics$en {
	Translations$comics$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get fitHeight => '适合高度';
	@override String get readingMode => '阅读模式';
	@override String get paged => '分页';
	@override String get webtoon => '连续滚动';
	@override String get coverAlone => '单独显示封面';
	@override String get splitWide => '拆分宽页';
	@override String get splitWideHelp => '按阅读顺序分别显示每一半。开启后暂停双页并排显示。';
	@override String get thumbnails => '页面缩略图';
	@override String get controlsHelp => '滑动翻页，双击切换适配方式。连续滚动时，垂直滑动或使用 Page Up 和 Page Down。';
	@override String get savedForComic => '此个人资料会记住这部漫画的显示设置。';
	@override String get readLists => '阅读列表';
	@override String get collections => '合集';
}

// Path: games
class Translations$games$zh extends Translations$games$en {
	Translations$games$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

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
class Translations$deepLinks$zh extends Translations$deepLinks$en {
	Translations$deepLinks$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get invalid => '此 Plezy 链接不有效。';
	@override String profileNotFound({required Object profile}) => '没有个人资料符合“${profile}”。';
	@override String get serverUnavailable => '我无法到达这个链接的服务器。';
	@override String get notFound => '我无法在图书馆中找到这个标题。';
	@override String get unsupportedItem => '这个链接不能播放。';
	@override String get noLiveTv => '没有现场电视服务器可用于此链接。';
	@override String channelNotFound({required Object channel}) => '我找不到“${channel}”频道。';
	@override String get showLink => '显示链接';
	@override String get showProfileLink => '显示个人资料链接';
	@override String get dialogTitle => '链接';
	@override String get showHint => '打开此链接将播放下一集。要随机播放整部剧集，请在末尾添加 &mode=shuffle。';
	@override String get movieHint => '打开这个链接播放电影。';
	@override String get episodeHint => '打开这个链接播放了这个节目。';
	@override String get profileHint => '打开此链接转换到这个个人资料。';
	@override String openAsProfile({required Object name}) => '打开 ${name}';
	@override String get copy => '复制';
	@override String get copied => '链接复制';
}

// Path: appIcon.names
class Translations$appIcon$names$zh extends Translations$appIcon$names$en {
	Translations$appIcon$names$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get midnight => '午夜';
	@override String get ember => '余烬';
	@override String get paper => '纸张';
	@override String get oled => 'OLED';
	@override String get line => '线条';
	@override String get ocean => '海洋';
	@override String get ultraviolet => '紫外';
	@override String get matcha => '抹茶';
	@override String get sunset => '日落';
	@override String get gold => '金色';
	@override String get titanium => '钛金';
	@override String get glass => '玻璃';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => '合成波';
	@override String get pixel => '像素';
	@override String get neon => '霓虹';
	@override String get sticker => '贴纸';
	@override String get ticket => '票根';
	@override String get pop => '波普';
	@override String get strata => '地层';
	@override String get facet => '切面';
	@override String get tilde => '波浪号';
}

// Path: common.ratingSource
class Translations$common$ratingSource$zh extends Translations$common$ratingSource$en {
	Translations$common$ratingSource$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

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

// Path: settings.startupSectionOptions
class Translations$settings$startupSectionOptions$zh extends Translations$settings$startupSectionOptions$en {
	Translations$settings$startupSectionOptions$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get discover => '从连接的发现来源打开建议和项目。';
	@override String get libraries => '打开您的连接媒体图书馆。';
	@override String get liveTv => '在服务器提供时打开直播电视;否则,初创公司将返回家庭。';
	@override String get search => '开放媒体搜索';
}

// Path: themeEditor.slots
class Translations$themeEditor$slots$zh extends Translations$themeEditor$slots$en {
	Translations$themeEditor$slots$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get bg => '背景';
	@override String get surface => '表面';
	@override String get outline => '描边';
	@override String get text => '文字';
	@override String get textMuted => '次要文字';
	@override String get accent => '强调色';
}

// Path: themeEditor.contrast
class Translations$themeEditor$contrast$zh extends Translations$themeEditor$contrast$en {
	Translations$themeEditor$contrast$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => '背景上的文字';
	@override String get textOnSurface => '表面上的文字';
	@override String get textMutedOnBg => '背景上的次要文字';
	@override String get textMutedOnSurface => '表面上的次要文字';
	@override String get accentOnBg => '背景上的强调色';
	@override String get accentOnSurface => '表面上的强调色';
	@override String get labelOnAccent => '强调色上的按钮文字';
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
	@override String get subtitleDelayIncrease => '延迟字幕';
	@override String get subtitleDelayDecrease => '提前字幕';
	@override String get shaderToggle => '切换着色器';
	@override String get skipMarker => '跳过片头/片尾';
	@override String get screenshot => '截图';
	@override String get framePrevious => '上一篇:框架';
	@override String get frameNext => '下一框';
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

// Path: subtitlingStyling.assOverrideOptions
class Translations$subtitlingStyling$assOverrideOptions$zh extends Translations$subtitlingStyling$assOverrideOptions$en {
	Translations$subtitlingStyling$assOverrideOptions$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get no => '保持字体、颜色、尺寸和位置写在子标题文件中。';
	@override String get yes => '允许玩家的字幕风格设置调整 ASS 字幕。';
	@override String get scale => '应用播放器风格和规模嵌入式尺寸,以匹配视频尺寸。';
	@override String get force => '取代嵌入式 ASS 风格与玩家的字幕风格。';
	@override String get strip => '删除嵌入式 ASS 格式化,并清晰地显示字幕文本。';
}

// Path: subtitlingStyling.renderResolutionOptions
class Translations$subtitlingStyling$renderResolutionOptions$zh extends Translations$subtitlingStyling$renderResolutionOptions$en {
	Translations$subtitlingStyling$renderResolutionOptions$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get screen => '以全显示表面分辨率为最清晰的结果。';
	@override String get video => '以视频分辨率为基准进行渲染，这可以减少高分辨率显示器上的处理量。';
	@override String get threeQuarter => '以75%的显示表面分辨率为低效节约。';
	@override String get half => '放入 50% 的显示表面分辨率,以减少工作,与软的边缘。';
	@override String get third => '以显示表面分辨率的三分之一进行渲染，以减少处理量并获得较柔和的边缘。';
	@override String get quarter => '在显示表面分辨率的四分之一下降,以减少工作,最柔软的结果。';
}

// Path: accountPreferences.groups
class Translations$accountPreferences$groups$zh extends Translations$accountPreferences$groups$en {
	Translations$accountPreferences$groups$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => '音频与字幕';
	@override String get libraryDisplay => '媒体库';
	@override String get personalMedia => '个人媒体';
}

// Path: accountPreferences.subtitleModes
class Translations$accountPreferences$subtitleModes$zh extends Translations$accountPreferences$subtitleModes$en {
	Translations$accountPreferences$subtitleModes$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get none => '手动选择';
	@override String get noneDescription => '从不自动打开字幕。';
	@override String get defaultMode => '遵循轨道标记';
	@override String get defaultModeDescription => '使用存储在各字幕轨道上的默认和强制标记。';
	@override String get always => '始终启用';
	@override String get alwaysDescription => '只要有首选语言的字幕轨道就将其打开。';
	@override String get onlyForced => '仅强制字幕';
	@override String get onlyForcedDescription => '只加载标记为强制的轨道。';
	@override String get smart => '外语音频时显示';
	@override String get smartDescription => '仅在音频为其他语言时打开字幕。';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class Translations$accountPreferences$subtitleAccessibilityOptions$zh extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	Translations$accountPreferences$subtitleAccessibilityOptions$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => '优先非 SDH 字幕';
	@override String get preferSdh => '优先 SDH 字幕';
	@override String get onlySdh => '仅 SDH 字幕';
	@override String get onlyNonSdh => '仅非 SDH 字幕';
	@override String get preferNonSdhDescription => '偏好标准字幕,当既有标准和SDH版本时。';
	@override String get preferSdhDescription => '偏好在可用时使用 SDH 字幕,但允许标准字幕作为落后。';
	@override String get onlySdhDescription => '只使用 SDH 字幕;不要返回标准字幕。';
	@override String get onlyNonSdhDescription => '只使用标准字幕;排除 SDH 字幕。';
}

// Path: accountPreferences.forcedSubtitleOptions
class Translations$accountPreferences$forcedSubtitleOptions$zh extends Translations$accountPreferences$forcedSubtitleOptions$en {
	Translations$accountPreferences$forcedSubtitleOptions$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => '优先非强制字幕';
	@override String get preferForced => '优先强制字幕';
	@override String get onlyForced => '仅强制字幕';
	@override String get onlyNonForced => '仅非强制字幕';
	@override String get preferNonForcedDescription => '更喜欢定期的字幕,但允许强迫轨道作为落后。';
	@override String get preferForcedDescription => '偏好在可用时强迫行列,但允许定期字幕作为落后。';
	@override String get onlyForcedDescription => '只使用被强制标记的轨道。';
	@override String get onlyNonForcedDescription => '排除被强制标记的轨道。';
}

// Path: accountPreferences.watchedIndicatorOptions
class Translations$accountPreferences$watchedIndicatorOptions$zh extends Translations$accountPreferences$watchedIndicatorOptions$en {
	Translations$accountPreferences$watchedIndicatorOptions$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get none => '从不';
	@override String get moviesAndShows => '电影和电视剧';
	@override String get movies => '仅电影';
	@override String get shows => '仅电视剧';
	@override String get noneDescription => '不要显示已观看的检查标志。';
	@override String get moviesAndShowsDescription => '显示观看的电影和电视节目检查标志。';
	@override String get moviesDescription => '只为电影显示观看标签。';
	@override String get showsDescription => '只为电视节目显示观看的检查标志。';
}

// Path: accountPreferences.mediaReviewsOptions
class Translations$accountPreferences$mediaReviewsOptions$zh extends Translations$accountPreferences$mediaReviewsOptions$en {
	Translations$accountPreferences$mediaReviewsOptions$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => '用户和影评人';
	@override String get usersOnly => '仅用户';
	@override String get criticsOnly => '仅影评人';
	@override String get nobody => '隐藏';
	@override String get usersAndCriticsDescription => '显示用户评分和批判性评分。';
	@override String get usersOnlyDescription => '显示用户提交的评分和评论。';
	@override String get criticsOnlyDescription => '显示批判性评分和评论。';
	@override String get nobodyDescription => '隐藏评分和评论。';
}

// Path: discover.findNext
class Translations$discover$findNext$zh extends Translations$discover$findNext$en {
	Translations$discover$findNext$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '发现下一个心头好';
	@override String get open => '发现下一个心头好';
	@override String get anyTime => '不限时长';
	@override String get timeAvailable => '你有多少时间？';
	@override String get filters => '选出此刻想做的事';
	@override String get watch => '观看';
	@override String get listen => '聆听';
	@override String get read => '阅读';
	@override String finishable({required Object duration}) => '${duration}内可完成';
	@override String aboutDuration({required Object duration}) => '约${duration}';
	@override String nextUnit({required Object duration}) => '下一章 · ${duration}';
	@override String totalDuration({required Object duration}) => '共${duration}';
	@override String get timingVaries => '时长可能有所不同';
	@override String get notNow => '暂时跳过';
	@override String get swipeHint => '朝箭头方向滑动封面，或使用下方按钮。';
	@override String get saved => '已保存的推荐';
	@override String savedCount({required Object count}) => '已保存的推荐 · ${count}';
	@override String get undo => '撤销';
	@override String get details => '详情';
	@override String get noPicks => '暂时没有可选内容';
	@override String get noPicksHint => '连接媒体库或添加媒体来源即可开始。';
	@override String get noMatches => '没有适合此刻的内容';
	@override String get noMatchesHint => '试试其他内容类型，或留出更多时间。';
	@override String get allDone => '你已浏览全部推荐';
	@override String get allDoneHint => '换一组推荐，就能再次看到这些选项。';
	@override String get refresh => '寻找另一组推荐';
	@override String sourceReason({required Object source}) => '来自${source}';
	@override String libraryReason({required Object library}) => '来自${library}';
	@override String get ownedReason => '来自你的媒体库';
	@override String get liveNow => '正在播出';
	@override String get watchLive => '观看直播';
	@override String get filterAnything => '不限类型';
	@override String get filterWatch => '观看';
	@override String get filterListen => '聆听';
	@override String get filterRead => '阅读';
	@override String get twentyMinutes => '20分钟';
	@override String get fortyFiveMinutes => '45分钟';
	@override String get ninetyMinutes => '90分钟';
	@override String get apply => '应用';
	@override String get openFailed => '此内容已不可用。刷新后再次查看。';
	@override String get changeFailed => '无法保存此次更改，请重试。';
	@override String get savedLimit => '已保存的推荐列表已满。请先移除一条推荐，再保存其他推荐。';
	@override String get chooseHint => '打开作品、保存以便稍后查看，或跳过。';
	@override String get howItWorks => '使用方法';
	@override String get notNowHelp => '暂时跳过这部作品。它仍会保留在媒体库中。';
	@override String get saveHelp => '保存到此设备上当前个人资料的已保存推荐中。保存不会下载作品。';
	@override String get openHelp => '选择封面查看详情。使用主按钮播放、阅读或打开作品。';
	@override String get controlsHelp => '键盘或遥控器：将焦点移到按钮，然后按 Enter 或选择键。撤销可恢复上一次选择。';
	@override String get artworkLoading => '正在加载图片…';
	@override String get artworkUnavailable => '图片不可用';
	@override String get savedFeedback => '已加入保存的推荐';
	@override String get skippedFeedback => '已暂时跳过';
	@override String get releaseToConfirm => '松开以确认';
	@override String get remoteHint => '封面获得焦点时：← / → 选择 · 选择键查看详情 · ↑ / ↓ 移动焦点';
}

// Path: discover.person
class Translations$discover$person$zh extends Translations$discover$person$en {
	Translations$discover$person$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get born => '出生';
	@override String get died => '逝世';
	@override String get birthplace => '出生地';
	@override String dateWithAge({required Object date, required Object age}) => '${date}（${age} 岁）';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date}（享年 ${age} 岁）';
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
	@override String get filePath => '文件路径';
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
	@override String get dateDownloaded => '下载日期';
	@override String get size => '大小';
	@override String get library => '媒体库';
}

// Path: libraries.advancedFilters
class Translations$libraries$advancedFilters$zh extends Translations$libraries$advancedFilters$en {
	Translations$libraries$advancedFilters$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get include => '包含';
	@override String get exclude => '排除';
	@override String get any => '不限';
	@override String get yes => '是';
	@override String get no => '否';
	@override String not({required Object value}) => '排除 ${value}';
	@override String valueCount({required Object count}) => '已选 ${count} 项';
	@override String valueCountExcluded({required Object count}) => '已排除 ${count} 项';
	@override String get searchValues => '搜索值';
	@override String get noValues => '没有可选值';
	@override String get matchContains => '包含';
	@override String get matchNotContains => '不包含';
	@override String get matchIs => '是';
	@override String get matchIsNot => '不是';
	@override String get matchBeginsWith => '开头为';
	@override String get matchEndsWith => '结尾为';
	@override String get textHint => '输入以匹配';
	@override String get from => '从';
	@override String get to => '至';
	@override String range({required Object from, required Object to}) => '${from} 至 ${to}';
	@override String atLeast({required Object value}) => '${value} 及以上';
	@override String atMost({required Object value}) => '${value} 及以下';
	@override String dateLastDays({required Object count}) => '最近 ${count} 天';
	@override String get dateLastYear => '过去一年';
	@override String dateOlderThanDays({required Object count}) => '早于 ${count} 天前';
	@override String get dateOlderThanYear => '早于一年前';
}

// Path: libraries.selection
class Translations$libraries$selection$zh extends Translations$libraries$selection$en {
	Translations$libraries$selection$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get selectItems => '选择项目';
	@override String selectedCount({required Object count}) => '已选 ${count} 项';
	@override String get actions => '选择行动';
	@override String get confirmDescendants => '这一变化改变了所有节目和季节的节目。';
	@override String get confirmUnwatched => '这也会清除所选项目的播放进度。';
	@override String confirmCount({required Object count}) => '已选择的项目: ${count}。';
	@override String completed({required Object count}) => '更新項目: ${count}';
	@override String partialFailure({required Object succeeded, required Object failed}) => '更新 ${succeeded}; 失败 ${failed}. 失败的项目仍然被选择。';
}

// Path: explore.mdblistShelves
class Translations$explore$mdblistShelves$zh extends Translations$explore$mdblistShelves$en {
	Translations$explore$mdblistShelves$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get manage => '管理 探索 地板';
	@override String get manageDescription => '從您的帳戶中選擇和安排列表 MDBList';
	@override String get description => '從您的 MDBList 帳戶中選擇公開電影和電視列表. 創建或複製列表在 MDBList 然後更新。';
	@override String get selected => '选择的板块';
	@override String get available => '可用的账户列表';
	@override String get noLists => '没有公开的电影或电视列表返回. 创建或复制列表在 MDBList,然后更新。';
	@override String get displayName => '沙尔夫 显示名称';
	@override String get nameHint => '请点击使用源名单名称。';
	@override String get add => '添加Shelf';
	@override String get save => '保存沙地';
	@override String moveUp({required Object title}) => '移动 ${title} 升';
	@override String moveDown({required Object title}) => '移动 ${title} 下载';
	@override String get unavailable => '此列表不可用 退出或在设置中删除其架子。';
	@override String get rateLimited => '第MDBList号请求限制已达到,请随后退出。';
	@override String get loadFailed => '不能充电板,检查你的连接和退出。';
	@override String get saveFailed => '没办法放下,请放下。';
	@override String get accountChanged => '帐户或个人资料已更改 重新打开这些设置。';
	@override String get settingsUnreadable => '保存的字段无法阅读. 重新选择列表以取代这些设置。';
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
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 评论',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 条评论',
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
	@override String get actor => '演员';
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
		one: '由 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 用户推荐',
		other: '由 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 位用户推荐',
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

// Path: watchTogether.notices
class Translations$watchTogether$notices$zh extends Translations$watchTogether$notices$en {
	Translations$watchTogether$notices$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name} 按下了播放';
	@override String get playbackStarted => '已开始播放';
	@override String paused({required Object name}) => '${name} 暂停了播放';
	@override String get playbackPaused => '已暂停播放';
	@override String jumpedTo({required Object name, required Object position}) => '${name} 跳转到了 ${position}';
	@override String roomJumpedTo({required Object position}) => '已跳转到 ${position}';
	@override String changedSpeed({required Object name, required Object speed}) => '${name} 将速度设为 ${speed}';
	@override String speedChanged({required Object speed}) => '速度已设为 ${speed}';
	@override String startedMedia({required Object name, required Object title}) => '${name} 开始播放 ${title}';
	@override String mediaStarted({required Object title}) => '正在播放 ${title}';
	@override String stoppedMedia({required Object name}) => '${name} 停止了视频';
	@override String get mediaStopped => '视频已停止';
	@override String waitingFor({required Object name}) => '正在等待 ${name}…';
	@override String get waitingForSomeone => '正在等待其他人跟上…';
	@override String get finished => '已播放完毕';
	@override String hostChangedTo({required Object name}) => '${name} 现在是主持人';
	@override String get youAreNowHost => '你现在是主持人';
	@override String joined({required Object name}) => '${name} 已加入';
	@override String left({required Object name}) => '${name} 已离开';
	@override String get controlRefused => '只有主持人可以控制播放';
	@override String get searchFailed => '无法在部分服务器上搜索房间的视频';
	@override String get playBlocked => '按下播放即可开始';
	@override String get shareFailed => '无法与房间分享此视频';
	@override String get downloadNotShared => '下载内容所属的服务器离线时，无法与房间分享';
	@override String get openFailed => '无法打开房间的视频';
}

// Path: watchTogether.ended
class Translations$watchTogether$ended$zh extends Translations$watchTogether$ended$en {
	Translations$watchTogether$ended$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get ended => '主持人已结束房间';
	@override String get kicked => '你已被移出房间';
	@override String get expired => '房间已过期';
	@override String get replaced => '你已在另一台设备上加入此房间';
	@override String get lost => '与房间的连接已断开';
}

// Path: watchTogether.errors
class Translations$watchTogether$errors$zh extends Translations$watchTogether$errors$en {
	Translations$watchTogether$errors$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => '这不是房间代码。代码由 6 位字母和数字组成，不含 0、1、I、L 或 O。';
	@override String get roomNotFound => '没有使用此代码的房间。该房间可能已结束。';
	@override String get roomFull => '该房间已满。';
	@override String get roomLocked => '主持人已锁定该房间。';
	@override String get relayFull => '“一起看”当前繁忙。请稍后再试。';
	@override String get unreachable => '无法连接到“一起看”中继服务器。请检查网络连接。';
	@override String get rateLimited => '尝试次数过多。请稍等片刻后重试。';
	@override String get clientBlocked => '此版本的 PlezyNG 无法使用该中继服务器。请更新应用。';
	@override String get forbidden => '只有主持人可以执行此操作。';
	@override String get notInRoom => '你不在房间中。';
	@override String get alreadyInRoom => '你已在房间中。';
	@override String get resumeFailed => '无法重新加入房间。';
	@override String get unsupported => '该中继服务器不支持此操作。';
	@override String get generic => '出现问题。请重试。';
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
	@override String get sheetIntro => 'Android 正在阻止 PlezyNG 在后台稳定下载。';
	@override String get sheetIntroDegraded => '你的设备限制了 PlezyNG 在后台下载的时机。';
	@override String get reasonBackgroundRestricted => 'PlezyNG 的后台使用受到限制。请将其电池用量或后台使用设置为“不受限制”。';
	@override String get reasonStandbyRestricted => 'Android 已将 PlezyNG 置于受限待机状态。请将其电池用量设为“不受限制”。';
	@override String get reasonDownloadChannelBlocked => '下载通知已关闭，因此可能无法查看进度或进行控制。';
	@override String get reasonNotificationsDisabled => '通知已关闭。在 Android 13 或更高版本中，长时间后台下载需要开启通知。';
	@override String get reasonDataSaver => '流量节省程序已开启，会阻止使用移动数据进行后台下载。使用 Wi-Fi 时下载应仍可进行。';
	@override String get reasonOemUnknown => 'PlezyNG 在后台时，下载曾多次停止。请检查 PlezyNG 的电池用量或后台使用设置。';
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

// Path: downloads.groupings
class Translations$downloads$groupings$zh extends Translations$downloads$groupings$en {
	Translations$downloads$groupings$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get library => '媒体库';
	@override String get collections => '合集';
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
	@override String get discoveryDescription => '使用同一 Plex 账号的 PlezyNG 设备会显示在这里';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => '正在连接…';
	@override String get searchingForDevices => '正在搜索设备…';
	@override String get noDevicesFound => '未在网络中找到设备';
	@override String get noDevicesHint => '请在桌面端打开 PlezyNG，并确保设备连接到同一 Wi-Fi 网络';
	@override String get availableDevices => '可用设备';
	@override String get manualConnection => '手动连接';
	@override String get cryptoInitFailed => '无法启动安全连接。请先登录 Plex。';
	@override String get validationHostRequired => '请输入主机地址';
	@override String get validationHostFormat => '格式必须为 IP:端口（例如 192.168.1.100:48632）';
	@override String get connectionTimedOut => '连接超时。请在两台设备上使用同一网络。';
	@override String get sessionNotFound => '未找到设备。请确认 PlezyNG 正在主机上运行。';
	@override String get authFailed => '认证失败。两台设备需要使用同一 Plex 账号。';
	@override String failedToConnect({required Object error}) => '连接失败：${error}';
	@override String get codeTitle => '双重代码';
	@override String get codeDescription => '在主机设备上输入“远程伴侣”中显示的代码,两台设备都必须使用支持安全配对的版本。';
	@override String get codeInvalid => '输入所有 32 个字母和号码的主机代码。';
	@override String get updateRequired => '将两台设备更新到支持安全配对的版本。';
	@override String get hostDescription => '每次输入此代码一次,远程保持隐私:它提供对此个人资料的控制。';
	@override String get resetCode => '重新设置编码';
	@override String get resetDescription => '切断所有远程,并创建一个新的代码,每个远程都需要重新连接。';
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

// Path: services.simklReconnect
class Translations$services$simklReconnect$zh extends Translations$services$simklReconnect$en {
	Translations$services$simklReconnect$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '重新连接 Simkl';
	@override String get subtitle => 'Simkl 即将停用此连接所使用的登录方式。重新连接将打开 simkl.com 以授权 PlezyNG — PlezyNG 永远不会看到你的密码。你的观看记录仍保留在 Simkl 上。';
}

// Path: services.deviceCode
class Translations$services$deviceCode$zh extends Translations$services$deviceCode$en {
	Translations$services$deviceCode$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '在 ${service} 上激活 PlezyNG';
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
	@override String get modeDescription => '选择是阻止已勾选的媒体库同步，还是仅同步已勾选的媒体库。';
}

// Path: services.trackerDescriptions
class Translations$services$trackerDescriptions$zh extends Translations$services$trackerDescriptions$en {
	Translations$services$trackerDescriptions$zh.internal(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get trakt => '与您的 Trakt 帐户同步观看的节目和电影。';
	@override String get mal => '同步动画列表,并通过 MyAnimeList 观看进展。';
	@override String get anilist => '同步动画列表,并与 AniList 观看进展。';
	@override String get simkl => '同步观看电影,电视节目和动画与Simkl。';
	@override String get mdblist => '在推荐和探索中显示 MDBList 评分和列表。';
}

/// The flat map containing all translations for locale <zh>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsZh {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'appIcon.title' => '应用图标',
			'appIcon.defaultIcon' => '默认',
			'appIcon.current' => '当前图标',
			'appIcon.locked' => '终身访问需要',
			'appIcon.lockedHint' => '启动 7 天试用或终身解锁 PlezyNG 以使用替代图标。',
			'appIcon.changeFailed' => '无法更改应用图标',
			'appIcon.launcherHint' => '离开 PlezyNG 后，新图标将显示在主屏幕上。',
			'appIcon.tvLauncherHint' => '离开 PlezyNG 后将显示新横幅。在电视重启之前，Android TV 可能仍会显示旧横幅。',
			'appIcon.names.midnight' => '午夜',
			'appIcon.names.ember' => '余烬',
			'appIcon.names.paper' => '纸张',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => '线条',
			'appIcon.names.ocean' => '海洋',
			'appIcon.names.ultraviolet' => '紫外',
			'appIcon.names.matcha' => '抹茶',
			'appIcon.names.sunset' => '日落',
			'appIcon.names.gold' => '金色',
			'appIcon.names.titanium' => '钛金',
			'appIcon.names.glass' => '玻璃',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => '合成波',
			'appIcon.names.pixel' => '像素',
			'appIcon.names.neon' => '霓虹',
			'appIcon.names.sticker' => '贴纸',
			'appIcon.names.ticket' => '票根',
			'appIcon.names.pop' => '波普',
			'appIcon.names.strata' => '地层',
			'appIcon.names.facet' => '切面',
			'appIcon.names.tilde' => '波浪号',
			'appIcon.description' => '选择由您的设备启动器显示的图标. 预览显示每个选项看起来如何。',
			'auth.signInWithPlex' => '使用 Plex 登录',
			'auth.showQRCode' => '显示二维码',
			'auth.authenticate' => '验证',
			'auth.authenticationTimeout' => '验证超时。请重试。',
			'auth.scanQRToSignIn' => '扫描二维码登录',
			'auth.waitingForAuth' => '正在等待身份验证…\n请在浏览器中登录。',
			'auth.useBrowser' => '使用浏览器',
			'auth.or' => '或',
			'auth.connectToMediaBrowser' => ({required Object product}) => '连接到 ${product}',
			'auth.quickConnect' => 'Quick Connect',
			'auth.useQuickConnect' => '使用 Quick Connect',
			'auth.quickConnectInstructions' => '在 Jellyfin 中打开 Quick Connect 并输入此代码。',
			'auth.quickConnectWaiting' => '等待批准…',
			'auth.quickConnectCancel' => '取消',
			'auth.quickConnectExpired' => 'Quick Connect 已过期。请重试。',
			'auth.localDataRecoveryRequired' => 'PlezyNG 无法安全恢复本地登录状态和待处理的播放数据。请重新登录。',
			'auth.pinCheckRejected' => 'Plex PIN 检查被拒绝',
			'auth.connectToDirectPlex' => '连接到本地服务器 Plex',
			'common.cancel' => '取消',
			'common.save' => '保存',
			'common.close' => '关闭',
			'common.closeMiniPlayer' => '附近小型玩家',
			'common.closeWorkspaceWindow' => '附近窗口',
			'common.returnToFullView' => '回到全景',
			'common.manageMediaSessions' => '管理媒体会议',
			'common.hideMediaSessions' => '隐藏媒体会议',
			'common.mediaSessions' => '媒體會議',
			'common.mediaSessionsHint' => '选择会话可将其切换到前台。停放会隐藏窗口但保持会话运行。返回会在完整视图中打开会话；关闭则结束会话。',
			'common.sessionInWorkspace' => '在工作场所',
			'common.sessionParked' => '停车',
			'common.sessionFullscreen' => '全屏幕',
			'common.switchToNextWindow' => '与下一个窗口交换',
			'common.moveWindow' => '移动窗口',
			'common.finishMovingWindow' => '结束移动窗口',
			'common.moveWindowHint' => '长压和拖动窗口移动它. 这种控制也允许箭头密钥的运动。',
			'common.movingWindowHelp' => '拖到移动 · 投键调整 · 输入存储器 · 逃避取消',
			'common.resizeWindow' => '修复窗口',
			'common.resizeWindowHint' => '拖这个手套或使用箭头键重新调整窗口。',
			'common.workspaceWindowHint' => '使用移动控件，或长按并拖动窗口来移动。使用调整大小手柄来调整窗口大小。',
			'common.workspacePaneHint' => '选择这个面板以集中它. 使用其全屏控制来扩展。',
			'common.workspaceWindowLabel' => ({required Object title}) => '會議窗口: ${title}',
			'common.workspaceTitleHint' => '选择以聚焦窗口。拖动标题栏来移动；使用全屏按钮展开。',
			'common.moveToSessionTray' => '转到Session Tray',
			'common.moveToSessionTrayHint' => '打开此会议可用,而不显示其窗口。',
			'common.closeSessionHint' => '关闭此窗口并结束会议。',
			'common.sideBySideLayout' => '交换到侧面布局',
			'common.floatingWindows' => '转换为浮动窗口',
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
			'common.options' => '选项',
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
			'settings.supportDeveloper' => '支持 PlezyNG',
			'settings.supportDeveloperDescription' => '捐赠以支持开发',
			'settings.lifetimeAccess' => 'PlezyNG 终身访问',
			'settings.language' => '语言',
			'settings.theme' => '主题',
			'settings.appearance' => '外观',
			'settings.detailPage' => '详细页面',
			'settings.themeSongsEnabled' => '演奏主题歌曲',
			'settings.themeSongsEnabledDescription' => '播放可用的主题歌曲,同时查看媒体细节。',
			'settings.themeSongVolume' => '主题歌曲 卷',
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
			'settings.secondsShort' => '秒',
			'settings.minutesShort' => '分钟',
			'settings.durationHint' => ({required Object min, required Object max}) => '输入时长（${min}–${max}）',
			'settings.systemTheme' => '系统',
			'settings.lightTheme' => '浅色',
			'settings.darkTheme' => '深色',
			'settings.oledTheme' => 'OLED',
			'settings.emberTheme' => '余烬',
			'settings.glacierTheme' => '冰川',
			'settings.forestTheme' => '森林',
			'settings.plumTheme' => '梅子',
			'settings.paperTheme' => '纸张',
			'settings.libraryDensity' => '媒体库密度',
			'settings.displayScale' => '界面缩放',
			'settings.compact' => '紧凑',
			'settings.comfortable' => '舒适',
			'settings.gridSpacing' => '网格间距',
			'settings.gridSpacingTight' => '紧密',
			'settings.gridSpacingNormal' => '标准',
			'settings.gridSpacingSpacious' => '宽松',
			'settings.tvCornerSpotlightBackdrop' => '右上角聚焦背景图',
			'settings.tvCornerSpotlightBackdropDescription' => '在右上角显示精选内容图片，而不是铺满整个屏幕',
			'settings.viewMode' => '视图模式',
			'settings.gridView' => '网格视图',
			'settings.listView' => '列表视图',
			'settings.showHeroSection' => '显示精选内容区',
			'settings.showHomeBackdrop' => '展示家居背景艺术作品',
			'settings.showHomeBackdropDescription' => '展示大型艺术作品背后展示的家庭行',
			'settings.contentScreensaverEnabled' => '内容屏幕保存',
			'settings.contentScreensaverEnabledDescription' => '显示全屏艺术作品,应用程序已变成 idle',
			'settings.contentScreensaverDelay' => '屏幕保存后启动',
			'settings.contentScreensaverLibraries' => '图书馆屏幕',
			'settings.contentScreensaverLibrariesDescription' => '选择要用于屏幕保护程序图片的媒体库。如果未选择任何媒体库，则会使用所有媒体库的图片。',
			'settings.contentScreensaverAllLibraries' => '所有图书馆',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} 图书馆 选择',
			'settings.contentScreensaverNoLibraries' => '没有连接媒体图书馆可用。',
			'settings.contentScreensaverDismissHint' => '按下任何按钮或按下取消',
			'settings.newEpisodeNotifications' => '新事件通知',
			'settings.newEpisodeNotificationsDescription' => '警告当新集添加到一个节目你被抓住时,检查 Plezy 是开放的。',
			'settings.continueWatchingRowSize' => '继续观看 序列大小',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => '${label} 卡片',
			'settings.rowSizeCompact' => '紧凑',
			'settings.rowSizeStandard' => '標準',
			'settings.rowSizeLarge' => '大',
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
			'settings.showWatchedIndicators' => '显示已观看标记',
			'settings.showWatchedIndicatorsDescription' => '在已观看的电影、剧集和单集上显示对勾标记',
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
			'settings.playbackBuffer' => '播放缓冲',
			'settings.playbackBufferAuto' => '自动（推荐）',
			'settings.playbackBufferLarge' => '大',
			'settings.playbackBufferExtraLarge' => '特大',
			'settings.playbackBufferDescription' => '针对不稳定的连接缓冲更多内容。也受缓冲大小限制。',
			'settings.streamBufferSize' => '布格大小',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} MB',
			'settings.streamBufferSizeDescription' => '直接播放时预先加载的视频量。转码播放以服务器自身的转码缓冲区为限。0 = 自动',
			'settings.streamBufferSizeExoNote' => '取代 Playback Buffer 设置时,在应用程序的内存限制中半个',
			'settings.streamBufferMegabytes' => '梅加比特',
			'settings.defaultQualityTitle' => '默认画质',
			'settings.cellularQualityTitle' => '移动网络默认画质',
			'settings.remoteQualityTitle' => '远程播放质量',
			'settings.remoteQualitySameAsDefault' => '与假设质量相同',
			'settings.cellularQualitySameAsDefault' => '与默认画质相同',
			'settings.directPlayCoveredQuality' => '以原始画质播放较小视频',
			'settings.directPlayCoveredQualityDescription' => '已在画质限制内的视频直接播放，而非转码',
			'settings.videoCodecs' => '视频编解码器',
			'settings.videoCodecsDescription' => '未勾选的编解码器将由服务器转码',
			'settings.videoCodecsAlwaysAccepted' => '始终接受',
			'settings.musicQualityTitle' => '音乐音质',
			'settings.subtitleStyling' => '字幕样式',
			'settings.subtitleStylingDescription' => '调整字幕外观',
			'settings.smallSkipDuration' => '短跳过时长',
			'settings.largeSkipDuration' => '长跳过时长',
			'settings.rewindOnResume' => '恢复时回退',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(seconds, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)}秒钟', ), 
			'settings.defaultSleepTimer' => '默认睡眠定时器',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(minutes, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)}分钟', ), 
			'settings.rememberTrackSelections' => '记住每部剧集或电影的音轨选择',
			'settings.chooseTracksBeforePlayback' => '选择音频和字幕在播放前',
			'settings.chooseTracksBeforePlaybackDescription' => '在每个视频开始之前,选择源音频和子标题跟踪。',
			'settings.alwaysShowSubtitlesOnDevice' => '总是显示该设备上的字幕',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => '当服务器没有选定的子标题时,选择一个路径,而此事永远不会改变服务器的偏好。',
			'settings.autoDownloadPreferredSubtitle' => '福克斯缺少偏好语言字幕',
			'settings.autoDownloadPreferredSubtitleDescription' => '选择您所需的语言中的可用字幕,当地选择;如果没有字幕,请服务器在支持时查找一个字幕;选项将留在该设备上。',
			'settings.rememberTrackSelectionsDescription' => '分别记住每部内容的音频和字幕选择',
			'settings.rememberTrackSelectionsBackendRule' => 'Plex 会按文件将每个选择保存在服务器上；Jellyfin 还会开启账户的“记住选择”；Emby 不支持',
			'settings.followServerTrackSelections' => '使用服务器为每集选择的轨道',
			'settings.followServerTrackSelectionsDescription' => '切换剧集时，应用服务器上为该集选择的音频和字幕，而不是沿用当前选择',
			'settings.resumeMusicOnLaunch' => '记住音乐会话',
			'settings.resumeMusicOnLaunchDescription' => '应用启动时，将上次播放的歌曲在停止位置以暂停状态打开',
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
			'settings.watchTogetherRelayDescription' => '除非自行设置，否则使用公共 Open Watch Party 中继服务器',
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
			'settings.importSettingsInvalidFile' => '此文件不是有效的 PlezyNG 设置导出',
			'settings.importSettingsNoUser' => '导入设置前请先登录',
			'settings.cloudBackup' => '云备份',
			'settings.cloudBackupDescription' => '通过 HTTPS 将可迁移的设置备份到 WebDAV 地址。服务器连接和登录凭据保留在此设备上。',
			'settings.cloudBackupUrl' => 'WebDAV JSON 文件 URL',
			'settings.cloudBackupUsername' => '用户名',
			'settings.cloudBackupPassword' => '密码',
			'settings.cloudBackupSaved' => '云备份目的地保存',
			'settings.cloudBackupNow' => '回归现在',
			'settings.cloudBackupComplete' => '设置备份上传',
			'settings.cloudBackupRestore' => '恢复备份',
			'settings.cloudBackupRestoreConfirm' => '此将取代该设备上的相匹配移动设置。',
			'settings.cloudBackupRestored' => '從雲端儲備恢復的設定',
			'settings.shortcutsReset' => '快捷键已重置为默认值',
			'settings.resetShortcutsConfirm' => '这将用默认快捷键替换你的自定义快捷键。继续吗？',
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
			'settings.autoPlayAndSkip' => '自动播放与跳过',
			'settings.autoPlayNextEpisode' => '自动播放下一集',
			'settings.autoPlayNextEpisodeDescription' => '当前剧集结束时自动播放下一集',
			'settings.shuffleStartsFromBeginning' => '随机播放从头开始',
			'settings.shuffleStartsFromBeginningDescription' => '随机播放时每集从头开始播放，而非续播',
			'settings.plexCinemaPreRoll' => '使用服务器电影输入',
			'settings.plexCinemaPreRollDescription' => '在电影开始之前,播放配置的Plex预角色或Jellyfin和Emby输入。',
			'settings.playNextCountdown' => '播放下一集倒计时',
			'settings.playNextCountdownImmediate' => '立即播放',
			'settings.skipIntroMode' => '跳过片头',
			'settings.skipIntroModeOffDescription' => '正常播放片头，不显示跳过按钮',
			'settings.skipIntroModeButtonDescription' => '片头开始时显示跳过按钮',
			'settings.skipIntroModeAutoDescription' => '在下方设定的延迟后自动跳过片头',
			'settings.skipCreditsMode' => '跳过片尾',
			'settings.skipCreditsModeOffDescription' => '正常播放片尾，不显示跳过按钮',
			'settings.skipCreditsModeButtonDescription' => '片尾开始时显示跳过按钮',
			'settings.skipCreditsModeAutoDescription' => '自动跳过片尾并播放下一集',
			'settings.skipAdsMode' => '滑雪广告',
			'settings.skipAdsModeOffDescription' => '正常播放被发现的广告,没有跳跃按钮',
			'settings.skipAdsModeButtonDescription' => '显示在 Plex 检测广告时,将按钮转',
			'settings.skipAdsModeAutoDescription' => '下面的延迟后自动删除被发现的广告',
			'settings.musicPlayback' => '音乐播放',
			'settings.musicSweetFades' => '甜蜜的Fades',
			'settings.musicSweetFadesDescription' => '音乐在轨道边缘时,当Plex有声音数据时,音乐的播放保持不变。',
			'settings.skipMarkerModeOff' => '关闭',
			'settings.skipMarkerModeButton' => '显示按钮',
			'settings.skipMarkerModeAuto' => '自动',
			'settings.forceSkipMarkerFallback' => '强制使用备用标记',
			'settings.forceSkipMarkerFallbackDescription' => '即使 Plex 有标记，也使用章节标题模式',
			'settings.theIntroDbFallback' => '使用 TheIntroDB 作为 Intro Fallback',
			'settings.theIntroDbFallbackDescription' => '仅在服务器没有片头标记时使用社区提供的时间点。匹配结果可能因发行版本而异。',
			'settings.autoSkipDelay' => '自动跳过延迟',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => '自动跳过前等待 ${seconds} 秒',
			'settings.introPattern' => '片头标记模式',
			'settings.introPatternDescription' => '用于匹配章节标题中片头标记的正则表达式',
			'settings.creditsPattern' => '片尾标记模式',
			'settings.creditsPatternDescription' => '用于匹配章节标题中片尾标记的正则表达式',
			'settings.prerolls' => '片前视频',
			'settings.playPrerollsBeforeMovies' => '电影前玩预告片',
			'settings.playPrerollsBeforeMoviesDescription' => '在每部電影之前播放下面的選項中的偶然剪輯,按一下回來跳。',
			'settings.prerollLibrary' => '普雷罗图书馆',
			'settings.prerollLibraryNotSet' => '未设置',
			'settings.prerollLibraryNoneFound' => '您服务器上没有找到图书馆。',
			'settings.prerollSelection' => '选择的预算',
			'settings.prerollSelectionPickLibraryFirst' => '首先选择图书馆',
			'settings.prerollSelectionNoneSelected' => '没有选定的特权',
			'settings.prerollSelectionCount' => ({required Object count}) => '已选 ${count} 项',
			'settings.prerollItemPicker' => '选择预算',
			'settings.prerollItemPickerLoadFailed' => '我不能从这本图书馆上传任何东西。',
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
			'settings.autoDownloadContinueWatching' => '自动下载 继续观看',
			'settings.autoDownloadContinueWatchingDescription' => '保持在您的继续观看盾牌上下载的项目,并在他们离开盾牌后删除它们',
			'settings.downloadQuality' => '下载质量',
			'settings.downloadQualityDescription' => 'Plex 在其下载中编制转换副本. Jellyfin 和 Emby 转码,而文件下载; 中断的转换可能需要重新启动。',
			'settings.askDownloadQualityEachTime' => '选择每个下载的质量',
			'settings.askDownloadQualityEachTimeDescription' => '显示优质点数,在每次视频下载之前',
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
			'settings.companionRemoteServerStartFailed' => '无法启动远程控制服务器',
			'settings.companionRemoteServerStopFailed' => '无法停止远程控制服务器',
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
			'settings.tunneledPlaybackDescription' => '使用视频隧道模式。若播放 HDR 内容时出现黑屏或画面卡顿，请将其关闭。',
			'settings.audioPassthrough' => '音频直通',
			'settings.audioPassthroughDescription' => '将 Dolby/DTS 音频不经重新编码直接发送到功放或电视，保留环绕声。如果没有声音，请关闭。',
			'settings.audioPassthroughDescriptionApple' => '对 Dolby Digital Plus（含 Atmos）使用 Apple 原生 Dolby 解码器。DTS 和 TrueHD 仍以多声道 PCM 播放。如果没有声音，请关闭。',
			'settings.audioPassthroughDescriptionAppleSpatial' => '对 Dolby Digital Plus（含 Atmos）使用 Apple 原生 Dolby 解码器。在 iOS、iPadOS 和 tvOS 26 或更高版本上，TrueHD Atmos 和 DTS:X 以空间音频播放。其他 DTS 和 TrueHD 音轨以多声道 PCM 播放。如果没有声音，请关闭。',
			'settings.audioPassthroughOverriddenByNormalization' => '响度标准化开启时停用',
			'settings.audioChannelLimit' => '音频声道',
			'settings.audioChannelLimitDescription' => '为无法播放所有声道的扬声器、耳机或 HDMI 设备下混解码后的音频',
			'settings.audioChannelLimitOriginal' => '原始',
			'settings.audioChannelLimitOriginalDescription' => '播放音轨中的所有声道',
			'settings.audioChannelLimitSurround51' => '最多 5.1',
			'settings.audioChannelLimitSurround51Description' => '为仅支持 5.1 PCM 的电视和功放将 7.1 下混为 5.1。不影响直通。',
			'settings.audioChannelLimitStereo' => '立体声',
			'settings.audioChannelLimitStereoDescription' => '下混为双声道，适用于立体声扬声器或耳机。将关闭直通。',
			'settings.downmixCenterBoost' => '中置声道增强',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => '增强（dB）',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => '下混时音量标准化',
			'settings.audioDownmixNormalizeDescription' => '降低混音电平以防止削波。关闭可保持原始音量（大音量场景可能失真）。',
			'settings.dvConversionMode' => 'Dolby Vision 转换',
			'settings.dvConversionModeDescription' => '选择如何处理 Dolby Vision Profile 7 文件。',
			'settings.dvConversionAuto' => '自动',
			'settings.dvConversionNative' => '原生 / 禁用',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => '使用设备能力检测和常规回退机制',
			'settings.dvConversionNativeDescription' => '强制原生 DV7 并禁止重试 DV 转换',
			'settings.dvConversionDv81Description' => '强制内联 RPU 转换为 Dolby Vision Profile 8.1',
			'settings.dvConversionHevcStripDescription' => '移除 Dolby Vision RPU/EL 层并呈现普通 HEVC',
			'settings.experimentalDolbyVision' => '实验性 Dolby Vision',
			'settings.experimentalDolbyVisionDescription' => '下次播放时使用实验性 FEL 渲染器。需要单独构建的播放引擎。',
			'settings.dvExperimentUnavailableDescription' => '此实验目前仅支持 Linux。',
			'settings.dvCompatibilityFallback' => '兼容性回退',
			'settings.dvCompatibilityFallbackDescription' => '如果实验无法启动，则使用标准渲染器。FEL 数据可能会丢失。',
			'settings.dvExperimentDiagnostics' => '视频实验日志',
			'settings.dvExperimentDiagnosticsDescription' => '在下次播放时启用详细的播放器日志。',
			'settings.disableDolbyVision' => '禁用 Dolby Vision',
			'settings.disableDolbyVisionDescription' => '文件包含 HDR10 或 HLG 层时，改为播放该层而非 Dolby Vision',
			'settings.hdrSdrConversion' => 'HDR 转 SDR',
			'settings.hdrSdrConversionDescription' => '选择在显示器无法显示 HDR 时由谁转换 HDR 视频。',
			_ => null,
		} ?? switch (path) {
			'settings.hdrSdrConversionAuto' => '自动',
			'settings.hdrSdrConversionAutoDescription' => 'Android 9 及更高版本使用设备，更早版本使用播放器',
			'settings.hdrSdrConversionDevice' => '设备',
			'settings.hdrSdrConversionDeviceDescription' => '由设备的视频硬件转换。速度最快，但色彩取决于设备',
			'settings.hdrSdrConversionPlayer' => '播放器',
			'settings.hdrSdrConversionPlayerDescription' => '由播放器转换。色彩一致，但在低端电视盒上 4K 可能卡顿',
			'settings.deinterlace' => '去隔行',
			'settings.deinterlaceDescription' => '消除隔行扫描视频中的梳状伪影（仅 mpv 播放器）',
			'settings.deinterlaceOff' => '关闭',
			'settings.deinterlaceOffDescription' => '按解码原样显示隔行扫描视频',
			'settings.deinterlaceVideo' => '视频',
			'settings.deinterlaceVideoDescription' => '将每一场转换为完整的一帧。适用于为电视拍摄的视频，如体育、新闻和音乐会',
			'settings.deinterlaceFilm' => '电影',
			'settings.deinterlaceFilmDescription' => '还原经胶转磁（telecine）处理为 29.97 fps 的电影和动画的原始帧，常见于 NTSC DVD。为电视拍摄的视频会出现卡顿。直播电视使用“视频”模式',
			'settings.requireProfileSelectionOnOpen' => '打开应用时选择用户资料',
			'settings.requireProfileSelectionOnOpenDescription' => '每次打开应用时都显示用户资料选择界面',
			'settings.forceTvMode' => '强制 TV 模式',
			'settings.forceTvModeDescription' => '强制 TV 布局。适用于无法自动检测的设备。需要重启。',
			'settings.startInFullscreen' => '以全屏模式启动',
			'settings.startInFullscreenDescription' => '启动时以全屏模式打开 PlezyNG',
			'settings.exitFullscreenOnPlayerClose' => '关闭播放器时退出全屏',
			'settings.exitFullscreenOnPlayerCloseDescription' => '关闭视频播放器时自动退出全屏模式',
			'settings.autoHidePerformanceOverlay' => '自动隐藏性能叠加层',
			'settings.autoHidePerformanceOverlayDescription' => '性能叠加层随播放控件一起淡入淡出',
			'settings.showNavBarLabels' => '显示导航栏标签',
			'settings.showNavBarLabelsDescription' => '在导航栏图标下方显示文字标签',
			'settings.startupSection' => '启动页面',
			'settings.preferredServer' => '优先服务器',
			'settings.preferredServerDescription' => '优先考虑此服务器的结果,同时保持所有连接的服务器可用。',
			'settings.preferredServerAutomatic' => '自动',
			'settings.showExploreTab' => '显示“探索”标签页',
			'settings.showExploreTabDescription' => '显示“探索”标签页，其中包含来自 Plex Discover 和已连接追踪服务的内容',
			'settings.hideEmptyLibraries' => '隐藏空白图书馆',
			'settings.hideEmptyLibrariesDescription' => '从导航中删除服务器报告的零件数的图书馆。',
			'settings.liveTvDefaultFavorites' => '默认显示收藏频道',
			'settings.liveTvDefaultFavoritesDescription' => '打开直播电视时仅显示收藏频道',
			'settings.general' => '通用',
			'settings.generalDescription' => '语言、启动和窗口行为',
			'settings.languageAndRegion' => '语言与地区',
			'settings.startup' => '启动',
			'settings.display' => '显示',
			'settings.libraryAndCards' => '媒体库与卡片',
			'settings.homeScreen' => '主屏幕',
			'settings.navigation' => '导航',
			'settings.window' => '窗口',
			'settings.liveTv' => '直播电视',
			'settings.player' => '播放器',
			'settings.videoAndDisplay' => '视频与显示',
			'settings.audio' => '音频',
			'settings.quality' => '画质',
			'settings.subtitles' => '字幕',
			'settings.seekAndTiming' => '跳转与计时',
			'settings.behavior' => '行为',
			'settings.gestures' => '手势',
			'settings.gestureBrightnessSwipe' => '亮度滑动',
			'settings.gestureBrightnessSwipeDescription' => '在屏幕左边缘上下滑动以调节亮度',
			'settings.gestureVolumeSwipe' => '音量滑动',
			'settings.gestureVolumeSwipeDescription' => '在屏幕右边缘上下滑动以调节音量',
			'settings.gesturePinchToZoom' => '双指缩放',
			'settings.gesturePinchToZoomDescription' => '在视频上双指捏合以放大或缩小',
			'settings.gestureSeekSwipe' => '寻找Swipe',
			'settings.gestureSeekSwipeDescription' => '向左或向右转到视频中寻找; 释放跳跃',
			'settings.rememberBrightnessLevel' => '记住亮度',
			'settings.rememberBrightnessLevelDescription' => '以上次滑动设置的亮度开始播放',
			'settings.controls' => '控制',
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
			'settings.exportDialogTitle' => '导出 PlezyNG 设置',
			'settings.followSystem' => '跟随系统',
			'settings.followAppLanguage' => '与界面语言一致',
			'settings.regionFormat' => '区域格式',
			'settings.regionFormatDescription' => '选择日期、数字和计量单位的显示方式。',
			'settings.metadataLanguage' => '元数据语言',
			'settings.metadataLanguageDescription' => '服务器支持时，优先使用此语言显示标题和简介。音频和字幕偏好单独设置。',
			'settings.enterFullscreenOnPlaybackStart' => '在播放开始时输入全屏',
			'settings.enterFullscreenOnPlaybackStartDescription' => '打开桌面视频在播放开始时全屏',
			'settings.extendVideoIntoDisplayCutout' => '将视频扩展到显示器中',
			'settings.extendVideoIntoDisplayCutoutDescription' => '让全屏视频在Android手机上使用相机切割',
			'settings.languageDescription' => '选择用于 PlezyNG 控制和消息的语言. 跟踪系统跟踪您的设备语言。',
			'settings.themeDescription' => '选择应用程序中使用的颜色和对比。',
			'settings.libraryDensityDescription' => '改变每个行中的图书馆卡的数量。',
			'settings.displayScaleDescription' => '在此车屏幕上重新设置接口,而无需改变您的设备上的文本大小。',
			'settings.themeSongVolumeDescription' => '设置主题歌曲的数量与其他音频相比。',
			'settings.viewModeDescription' => '选择图书馆项目是否显示为网上的海报或作为一个小型列表。',
			'settings.gridViewDescription' => '安排图书馆项目在海报的行和列。',
			'settings.listViewDescription' => '在垂直列表中显示图书馆项目,每个项目有更多的文本。',
			'settings.gridSpacingDescription' => '在图书馆网中设置海报之间的差距。',
			'settings.gridSpacingTightDescription' => '在屏幕上插入更多的海报,有较小的差距。',
			'settings.gridSpacingNormalDescription' => '使用海报之间的标准差距。',
			'settings.gridSpacingSpaciousDescription' => '添加海报之间更大的差距,以获得更多的分离。',
			'settings.episodePosterModeDescription' => '选择哪个艺术作品出现在节目卡上。',
			'settings.seriesPosterDescription' => '使用节目系列的海报为每个集合。',
			'settings.seasonPosterDescription' => '使用每集的季节海报,随时可用。',
			'settings.episodeThumbnailDescription' => '在可用时使用集中的框架。',
			'settings.continueWatchingActionDescription' => '选择当您启动继续观看卡时会发生什么。',
			'settings.continueWatchingPlayDescription' => '立即启动电影或节目。',
			'settings.continueWatchingDetailsDescription' => '首先打开标题页面,以便您可以查看详细信息并选择一个行动。',
			'settings.episodeActionDescription' => '选择当您启动一个节目卡时会发生什么。',
			'settings.episodePlayDescription' => '立即开始事件。',
			'settings.episodeDetailsDescription' => '在播放之前打开集片页面。',
			'settings.contentScreensaverDelayDescription' => '在展示艺术作品之前,选择 PlezyNG 等待多久没有输入。',
			'settings.continueWatchingRowSizeDescription' => '在继续观看行中选择卡片的尺寸。',
			'settings.rowSizeCompactDescription' => '显示较小的卡片,以便在行列中添加更多的项目。',
			'settings.rowSizeStandardDescription' => '使用标准卡尺寸。',
			'settings.rowSizeLargeDescription' => '显示更大的卡片,更多艺术作品的细节。',
			'settings.visualEffectsDescription' => '选择该设备的动画和艺术作品效果预算。',
			'settings.visualEffectsFullDescription' => '在每个设备上使用完整的动画和艺术作品效果。',
			'settings.startupSectionDescription' => '在 PlezyNG 启动时选择哪个部分打开。',
			'settings.startupSectionOptions.discover' => '从连接的发现来源打开建议和项目。',
			'settings.startupSectionOptions.libraries' => '打开您的连接媒体图书馆。',
			'settings.startupSectionOptions.liveTv' => '在服务器提供时打开直播电视;否则,初创公司将返回家庭。',
			'settings.startupSectionOptions.search' => '开放媒体搜索',
			'settings.smallSkipDurationDescription' => '设置由短后方向移动的距离,并向前寻找控制。',
			'settings.largeSkipDurationDescription' => '设置远程移动的长后方向和向前寻找控制。',
			'settings.rewindOnResumeDescription' => '在重新播放视频时,以此金额返回播放。',
			'settings.defaultSleepTimerDescription' => '设置睡眠时间开始时使用的初始时间。',
			'settings.playNextCountdownDescription' => '等待很久,直到下一集开始,设置到0即时开始。',
			'settings.autoSkipDelaySettingDescription' => '适用于当一个输入、信用或广告设置自动转换时。',
			'settings.downmixCenterBoostDescription' => '在周围的音频被混合到斯特里奥时,在中间频道上增加对话。',
			'settings.displaySwitchDelayDescription' => '在更改显示模式之前等待,以便电视或接收器可以完成其以前的交换。',
			'settings.playerBackendDescription' => '选择哪个播放引擎在该设备上扫描和播放视频。',
			'settings.exoPlayerDescription' => '使用 Android 的本地 Media3 基于播放器和支持的硬件路径。',
			'settings.mpvDescription' => '使用 mpv,它暴露了额外的播放、子标题和视频处理控制。',
			'settings.scopeOffDescription' => '只保留当前播放会的更改。',
			'settings.scopeGlobalDescription' => '重复使用每个图书馆和标题的相同值。',
			'settings.scopeLibraryDescription' => '记住每个图书馆的单独价值。',
			'settings.scopeTitleDescription' => '记住每个节目或电影的单独值。',
			'settings.specialsOrderingServerDescription' => '保持媒体服务器提供的集合订单。',
			'settings.specialsOrderingAirDateDescription' => '根据他们的空气日期,将特殊物品列入常规事件中。',
			'settings.specialsOrderingLastDescription' => '每個特別的位置,在定期季節後。',
			'settings.skipIntroModeDescription' => '选择输入标记器是否正常播放,显示滑动按钮或自动滑动。',
			'settings.skipCreditsModeDescription' => '选择信用是否正常播放,显示滑动按钮或自动滑动。',
			'settings.skipAdsModeDescription' => '选择是否被发现的广告正常播放,显示滑动按钮或自动滑动。',
			'settings.playbackBufferAutoDescription' => '让活跃的玩家选择其正常的泡沫大小。',
			'settings.playbackBufferLargeDescription' => '保持更多媒体在播放前准备;这使用更多的内存。',
			'settings.playbackBufferExtraLargeDescription' => '保持最大的阅读面板泡沫;这使用最多的记忆。',
			'settings.defaultQualityDescription' => '设置服务器转码流的默认视频分辨率和最高码率。',
			'settings.cellularQualityDescription' => '超越默认质量,当设备使用单细胞连接时。',
			'settings.remoteQualityDescription' => '通过远程连接连接到服务器时超越默认质量。',
			'settings.qualityPresetOriginalDescription' => '以源文件可用的画质播放，不请求服务器转码。',
			'settings.qualityPresetTranscodeOptionDescription' => '请服务器使用上方显示的分辨率和码率进行转码。',
			'settings.qualityPresetSameAsDefaultDescription' => '使用默认品质中选择的质量。',
			'settings.musicQualityDescription' => '设置向服务器请求的最高音频码率；选择“原始”则保留源音频流。',
			'settings.musicQualityOriginalDescription' => '播放源音频,无需Bitrate加密的Transcode。',
			'settings.musicQualityTranscodeOptionDescription' => '请求服务器转代码接近上面的比特率;实际输出可能有所不同。',
			'settings.maxVolumeInputLabel' => '最大容量(%)',
			'settings.checkForUpdatesDescription' => '现在检查是否有更新的PlezyNG版本。',
			'settings.appearanceDescription' => '选择应用程序主题,并调整图书馆卡、主行和导航。',
			'settings.prerollLibraryDescription' => '选择包含电影预角色可用的剪辑的图书馆。',
			'settings.prerollSelectionDescription' => '选择从所选图书馆播放的剪辑在电影之前。',
			'settings.contentScreensaverDelayOptionDescription' => '在显示屏保存艺术作品之前等待这些无输入的几分钟。',
			'settings.videoCodecOptionDescription' => '允许在支持时直接播放此代码器. 未经检查的代码被媒体服务器编码。',
			'themeEditor.builtIn' => '内置',
			'themeEditor.presets' => '预设',
			'themeEditor.custom' => '自定义',
			'themeEditor.customEmpty' => '尚未创建',
			'themeEditor.editCustom' => '编辑自定义主题',
			'themeEditor.editCustomDescription' => '自行选择每种颜色',
			'themeEditor.locked' => '终身访问需要',
			'themeEditor.savedLocked' => '保存 - 可用,终身访问',
			'themeEditor.title' => '自定义主题',
			'themeEditor.startFrom' => '从现有主题开始',
			'themeEditor.startFromDescription' => '从其他主题复制所有颜色',
			'themeEditor.colors' => '颜色',
			'themeEditor.preview' => '预览',
			'themeEditor.slots.bg' => '背景',
			'themeEditor.slots.surface' => '表面',
			'themeEditor.slots.outline' => '描边',
			'themeEditor.slots.text' => '文字',
			'themeEditor.slots.textMuted' => '次要文字',
			'themeEditor.slots.accent' => '强调色',
			'themeEditor.opacity' => '不透明度',
			'themeEditor.hexHint' => '#RRGGBB 或 #AARRGGBB',
			'themeEditor.fromOtherThemes' => '来自其他主题',
			'themeEditor.swatchLabel' => ({required Object theme, required Object color}) => '${theme} · ${color}',
			'themeEditor.contrast.textOnBg' => '背景上的文字',
			'themeEditor.contrast.textOnSurface' => '表面上的文字',
			'themeEditor.contrast.textMutedOnBg' => '背景上的次要文字',
			'themeEditor.contrast.textMutedOnSurface' => '表面上的次要文字',
			'themeEditor.contrast.accentOnBg' => '背景上的强调色',
			'themeEditor.contrast.accentOnSurface' => '表面上的强调色',
			'themeEditor.contrast.labelOnAccent' => '强调色上的按钮文字',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}：${ratio}:1，低于建议的 ${minimum}:1',
			'themeEditor.discardTitle' => '放弃更改？',
			'themeEditor.discardMessage' => '未保存的颜色更改将会丢失。',
			'themeEditor.discard' => '放弃',
			'themeEditor.previewCardTitle' => ({required Object number}) => '第${number}集',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => '剩余 ${minutes} 分钟',
			'themeEditor.previewSwitch' => '自动播放',
			'themeEditor.previewMutedText' => '次要文字看起来是这样的',
			'themeEditor.themeSystemDescription' => '跟踪您的设备的外观,并自动在光和黑暗之间交换。',
			'themeEditor.themeLightDescription' => '使用光明的背景与黑暗文本。',
			'themeEditor.themeDarkDescription' => '使用黑暗背景与光明文本。',
			'themeEditor.themeOledDescription' => '使用近黑的表面,减少OLED屏幕上的光。',
			'themeEditor.themeEmberDescription' => '使用温暖的红色和<unk>色的重点颜色。',
			'themeEditor.themeGlacierDescription' => '使用冷蓝色焦点颜色。',
			'themeEditor.themeForestDescription' => '使用混合的绿色和天然焦点颜色。',
			'themeEditor.themePlumDescription' => '使用紫色和<unk>色的重点颜色。',
			'themeEditor.themePaperDescription' => '使用温暖的纸类表面和印刷灵感的颜色。',
			'themeEditor.themeCustomDescription' => '使用您在自定义主题编辑器中创建的颜色板。',
			'themeEditor.editorDescription' => '选择调色板颜色，调整色相、饱和度、亮度或不透明度，并在保存前预览效果。也可以输入十六进制颜色值。',
			'search.hint' => '搜索电影、剧集、音乐…',
			'search.tryDifferentTerm' => '尝试不同的搜索词',
			'search.searchYourMedia' => '搜索媒体',
			'search.enterTitleActorOrKeyword' => '输入标题、演员或关键词',
			'search.people' => '人物',
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
			'hotkeys.actions.subtitleDelayIncrease' => '延迟字幕',
			'hotkeys.actions.subtitleDelayDecrease' => '提前字幕',
			'hotkeys.actions.shaderToggle' => '切换着色器',
			'hotkeys.actions.skipMarker' => '跳过片头/片尾',
			'hotkeys.actions.screenshot' => '截图',
			'hotkeys.actions.framePrevious' => '上一篇:框架',
			'hotkeys.actions.frameNext' => '下一框',
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
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '这将删除其中的 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 集及其文件。', other: '这将删除其中全部 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 集以及它们的文件。', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '此项目存储在 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 个文件中，该文件将被删除。', other: '此项目存储在 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 个文件中，所有这些文件都会被删除。', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '另有 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 集存储在同一个文件中，也会一并删除：', other: '另外 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 集存储在同一个文件中，也会一并删除：', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'PlezyNG 无法确认此操作会删除哪些文件，因此删除范围可能超出上面提到的项目。请取消后重试，或仍然删除。',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => '你的服务器没有提供此项目的文件详情，因此 PlezyNG 无法确认此操作会删除哪些文件。删除范围可能超出上面提到的项目。',
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
			'accessibility.valueShort' => '五',
			'accessibility.red' => '红色',
			'accessibility.green' => '绿色',
			'accessibility.blue' => '蓝色',
			'accessibility.redShort' => '里',
			'accessibility.greenShort' => 'G',
			'accessibility.blueShort' => 'B',
			'accessibility.colorModeHsv' => 'HSV',
			'accessibility.colorModeRgb' => '里格',
			'accessibility.title' => '可用性',
			'accessibility.summary' => '文本、对比、动作和控制',
			'accessibility.systemHint' => '您的设备的可用性设置始终适用. 这些选项在 PlezyNG 期间添加调整。',
			'accessibility.readability' => '阅读与可见性',
			'accessibility.textSize' => '附加文本大小',
			'accessibility.preview' => '找下一个故事,阅读,听,并以自己的速度观看。',
			'accessibility.boldText' => '勇敢的界面文本',
			'accessibility.highContrast' => '高度对比',
			'accessibility.highContrastHint' => '在浅色或深色背景上，让文字、轮廓线和焦点指示器更清晰。',
			'accessibility.interaction' => '动作与互动',
			'accessibility.reduceMotion' => '减少动作',
			'accessibility.reduceMotionHint' => '停止焦点指示器、页面切换和装饰效果的动画。',
			'accessibility.largeTargets' => '触摸目标',
			'accessibility.largeTargetsHint' => '共享控制器提供更多触摸和辅助导航空间。',
			'accessibility.navigationHint' => '使用 Tab 和 Shift+Tab 在控件之间移动，按 Enter 或空格键激活，按 Escape 或返回按钮关闭。打开书籍后，可调整缩放比例和阅读偏好。',
			'accessibility.textSizeDescription' => '在 PlezyNG 中扩展接口文本,以及您的设备的系统文本大小设置。',
			'accessibility.boldTextHint' => '加粗界面标签和消息的字重，让它们更容易辨认。',
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
			_ => null,
		} ?? switch (path) {
			'videoControls.lockScreen' => '锁定屏幕',
			'videoControls.screenLockButton' => '屏幕锁定',
			'videoControls.timelineSlider' => '视频时间轴',
			'videoControls.volumeSlider' => '音量滑块',
			'videoControls.endsAt' => ({required Object time}) => '结束时间：${time}',
			'videoControls.pipActive' => '正在以画中画模式播放',
			'videoControls.pipFailed' => '画中画启动失败',
			'videoControls.screenshotSaved' => '截图已保存',
			'videoControls.screenshotFailed' => '无法截图',
			'videoControls.zoomPercent' => ({required Object percent}) => '缩放 ${percent}%',
			'videoControls.volumePercent' => ({required Object percent}) => '音量 ${percent}%',
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
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 框架', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 框架', ), 
			'videoControls.trackSelectionTitle' => '选择游戏前的游戏',
			'videoControls.trackSelectionAuto' => '自动选择',
			'videoControls.openMiniPlayer' => '開放小型玩家',
			'videoControls.returnToFullPlayer' => '回到全玩家',
			'videoControls.loadSubtitleFile' => '查询下载文件...',
			'videoControls.subtitleLoadFailed' => '未能下载字幕文件',
			'videoControls.skipAds' => '滑雪广告',
			'videoControls.tapToUnlock' => '点按以解锁',
			'videoControls.tapAgainToUnlock' => '再次点按以解锁',
			'messages.markedAsWatched' => '已标记为已观看',
			'messages.markedAsUnwatched' => '已标记为未观看',
			'messages.markedAsWatchedOffline' => '已标记为已观看（将在联网时同步）',
			'messages.markedAsUnwatchedOffline' => '已标记为未观看（将在联网时同步）',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => '已自动移除：${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '自动移除 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 观看下载', other: '已自动移除 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 个看过的下载', ), 
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
			'messages.playbackFailedDetail' => ({required Object error}) => '无法开始播放：${error}',
			'messages.audioOutputFailed' => '音频输出停止响应。请检查电视或功放的音频连接；如果其他应用也没有声音，请重启设备。',
			'messages.mediaUnavailable' => '此内容不再可用。',
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
			'messages.playbackNotAllowedTitle' => '不允许播放',
			'messages.playbackNotAllowedBody' => '服务器拒绝传输此项目（HTTP 403）。此账户可能没有播放权限，或服务器可能仅允许在其局域网内播放。',
			'messages.logsUploaded' => '日志已上传',
			'messages.logsUploadFailed' => '上传日志失败',
			'messages.logId' => '日志 ID',
			'messages.burnedSubtitlesUseMenu' => '字幕已烧录到此视频流中。请从字幕菜单中更改。',
			'messages.noVideoUrl' => '没有可用的视频 URL',
			'messages.playbackNoMediaSources' => '服务器未返回可播放的媒体源',
			'messages.playbackDataNotPrepared' => '播放数据尚未准备就绪时便开始了播放',
			'messages.streamSelectionUnavailable' => '此媒体源不支持选择视频流',
			'messages.streamSelectionFailed' => '无法应用所选视频流',
			'messages.trackSelectionNotRemembered' => '此轨道选择仅对当前播放生效。',
			'messages.serverUnavailableForProfile' => '没有可供当前用户资料使用的服务器',
			'subtitlingStyling.previewSample' => '快速的棕色<unk>子跳过可怜的狗',
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
			'subtitlingStyling.useMargins' => '使用边距',
			'subtitlingStyling.useMarginsDescription' => '允许文字字幕显示在视频画面之外的区域。样式字幕可能保留其原始位置。',
			'subtitlingStyling.anchorToScreen' => '锚定到屏幕',
			'subtitlingStyling.anchorToScreenDescription' => '在宽屏视频下方的黑边中显示文本字幕',
			'subtitlingStyling.bold' => '粗体',
			'subtitlingStyling.italic' => '斜体',
			'subtitlingStyling.renderResolution' => '渲染分辨率',
			'subtitlingStyling.renderResolutionScreen' => '屏幕分辨率',
			'subtitlingStyling.renderResolutionVideo' => '视频分辨率',
			'subtitlingStyling.fontSizeDescription' => '在此设备上设置字幕文本大小。',
			'subtitlingStyling.textColorDescription' => '选择用于字幕文本的颜色。',
			'subtitlingStyling.borderSizeDescription' => '设置字幕厚度周围的字幕文本。',
			'subtitlingStyling.borderColorDescription' => '选择用于子标题输出的颜色。',
			'subtitlingStyling.backgroundColorDescription' => '选择字幕文本背后的颜色。',
			'subtitlingStyling.backgroundOpacityDescription' => '设置字幕背景透明度:0%是清晰的,100%是坚固的。',
			'subtitlingStyling.positionDescription' => '垂直移动字幕:0%是视频的顶部,100%是底部。',
			'subtitlingStyling.assOverrideDescription' => '选择玩家是否遵循、调整、更换或删除在 ASS 子标题中嵌入的风格。',
			'subtitlingStyling.assOverrideOptions.no' => '保持字体、颜色、尺寸和位置写在子标题文件中。',
			'subtitlingStyling.assOverrideOptions.yes' => '允许玩家的字幕风格设置调整 ASS 字幕。',
			'subtitlingStyling.assOverrideOptions.scale' => '应用播放器风格和规模嵌入式尺寸,以匹配视频尺寸。',
			'subtitlingStyling.assOverrideOptions.force' => '取代嵌入式 ASS 风格与玩家的字幕风格。',
			'subtitlingStyling.assOverrideOptions.strip' => '删除嵌入式 ASS 格式化,并清晰地显示字幕文本。',
			'subtitlingStyling.renderResolutionDescription' => '选择使用的分辨率来拉斯特化图像和ASS子标题. 较低的Android尺寸可以减少演示工作,但看起来更柔软。',
			'subtitlingStyling.renderResolutionOptions.screen' => '以全显示表面分辨率为最清晰的结果。',
			'subtitlingStyling.renderResolutionOptions.video' => '以视频分辨率为基准进行渲染，这可以减少高分辨率显示器上的处理量。',
			'subtitlingStyling.renderResolutionOptions.threeQuarter' => '以75%的显示表面分辨率为低效节约。',
			'subtitlingStyling.renderResolutionOptions.half' => '放入 50% 的显示表面分辨率,以减少工作,与软的边缘。',
			'subtitlingStyling.renderResolutionOptions.third' => '以显示表面分辨率的三分之一进行渲染，以减少处理量并获得较柔和的边缘。',
			'subtitlingStyling.renderResolutionOptions.quarter' => '在显示表面分辨率的四分之一下降,以减少工作,最柔软的结果。',
			'subtitlingStyling.boldDescription' => '以更重的重量绘制字体。',
			'subtitlingStyling.italicDescription' => '在意大利语中绘制字幕文本。',
			'mpvConfig.title' => 'mpv.conf',
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
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => '添加行',
			'mpvConfig.removeLine' => '移除行',
			'mpvConfig.embeddedVoHint' => 'Linux 上会忽略 vo、gpu-context 和 gpu-api：嵌入式视频始终通过视频平面上的 vo=libmpv 渲染，而 gpu-next（ArtCNN 等计算着色器需要它）无法以嵌入式方式运行。',
			'dialog.confirmAction' => '确认操作',
			'profiles.addPlezyProfile' => '添加 PlezyNG 用户资料',
			'profiles.switchingProfile' => '正在切换用户资料…',
			'profiles.deleteThisProfileTitle' => '删除此用户资料？',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => '移除 ${displayName}。连接不会受影响。',
			'profiles.active' => '当前使用',
			'profiles.manage' => '管理',
			'profiles.delete' => '删除',
			'profiles.signOut' => '退出登录',
			'profiles.signOutPlexTitle' => '退出 Plex 登录？',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => '要移除 ${displayName} 和所有 Plex Home 用户吗？可随时重新登录。',
			'profiles.signOutPlexDeleteDownloads' => '同时删除下载内容',
			'profiles.signOutPlexDeleteDownloadsDescription' => '否则下载内容将保留在此设备上，并在你重新登录此账户时恢复。',
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
			'profiles.copyAutomationLink' => '复制 Android 自动化链接',
			'profiles.copyAutomationLinkDescription' => '從 Android 意圖或自動化中選擇此檔案,檔案 PIN 檢查仍適用。',
			'profiles.automationLinkCopied' => '个人资料自动化链接复制。',
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
			'profiles.borrowEmptySubtitle' => '请先将 Plex、Jellyfin 或 Emby 连接到另一个用户资料。',
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
			'profiles.settingsLocked' => '此配置已锁定。',
			'profiles.unlockSettings' => '解锁设置',
			'profiles.showExploreForProfile' => '查看此资料的探索',
			'profiles.showExploreForProfileDescription' => '关闭以从此个人资料的导航中删除 Explore。',
			'connections.sectionTitle' => '连接',
			'connections.addConnection' => '添加连接',
			'connections.addConnectionSubtitleNoProfile' => '使用 Plex 登录，或连接 Jellyfin 或 Emby 服务器',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => '添加到 ${displayName}：Plex、Jellyfin、Emby，或其他用户资料的连接',
			'connections.sessionExpiredOne' => ({required Object name}) => '${name} 的会话已过期',
			'connections.sessionExpiredMany' => ({required Object count}) => '${count} 个服务器的会话已过期',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} 拒绝此账户访问',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} 台服务器拒绝此账户访问',
			'connections.signInAgain' => '重新登录',
			'connections.editMediaBrowserTitle' => ({required Object product}) => '编辑 ${product} 连接',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => '为 ${serverName} 添加或移除 URL。PlezyNG 会使用延迟最低且可访问的 URL。',
			'accountPreferences.sectionTitle' => '账户偏好',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => '音频、字幕和媒体库选项已保存在 ${account} 上',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => '音频、字幕和媒体库选项已保存在 ${count} 个账户上',
			'accountPreferences.pickAccount' => '每个账户都保存自己的偏好设置。选择要编辑的账户。',
			'accountPreferences.storedOnAccount' => '这些选项保存在账户本身，因此所有登录该账户的应用都会使用它们——包括你其他设备上的 PlezyNG。',
			'accountPreferences.noAccounts' => '没有可配置的账户',
			'accountPreferences.noAccountsHint' => '登录 Plex，或连接 Jellyfin 或 Emby 服务器，该账户上保存的偏好设置就会显示在这里。',
			'accountPreferences.unavailable' => '无法访问此账户',
			'accountPreferences.loadFailed' => '无法加载这些偏好设置',
			'accountPreferences.noPreference' => '无偏好',
			'accountPreferences.notSet' => '未设置',
			'accountPreferences.groups.audioAndSubtitles' => '音频与字幕',
			'accountPreferences.groups.libraryDisplay' => '媒体库',
			'accountPreferences.groups.personalMedia' => '个人媒体',
			'accountPreferences.preferredAudioLanguage' => '首选音频语言',
			'accountPreferences.autoSelectAudio' => '按语言选择音频',
			'accountPreferences.autoSelectAudioDescription' => '关闭后保留文件标记为默认的音轨。',
			'accountPreferences.preferredSubtitleLanguage' => '首选字幕语言',
			'accountPreferences.subtitleMode' => '开启字幕',
			'accountPreferences.subtitleModes.none' => '手动选择',
			'accountPreferences.subtitleModes.noneDescription' => '从不自动打开字幕。',
			'accountPreferences.subtitleModes.defaultMode' => '遵循轨道标记',
			'accountPreferences.subtitleModes.defaultModeDescription' => '使用存储在各字幕轨道上的默认和强制标记。',
			'accountPreferences.subtitleModes.always' => '始终启用',
			'accountPreferences.subtitleModes.alwaysDescription' => '只要有首选语言的字幕轨道就将其打开。',
			'accountPreferences.subtitleModes.onlyForced' => '仅强制字幕',
			'accountPreferences.subtitleModes.onlyForcedDescription' => '只加载标记为强制的轨道。',
			'accountPreferences.subtitleModes.smart' => '外语音频时显示',
			'accountPreferences.subtitleModes.smartDescription' => '仅在音频为其他语言时打开字幕。',
			'accountPreferences.subtitleAccessibility' => 'SDH 字幕',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => '优先非 SDH 字幕',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => '优先 SDH 字幕',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => '仅 SDH 字幕',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => '仅非 SDH 字幕',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdhDescription' => '偏好标准字幕,当既有标准和SDH版本时。',
			'accountPreferences.subtitleAccessibilityOptions.preferSdhDescription' => '偏好在可用时使用 SDH 字幕,但允许标准字幕作为落后。',
			'accountPreferences.subtitleAccessibilityOptions.onlySdhDescription' => '只使用 SDH 字幕;不要返回标准字幕。',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdhDescription' => '只使用标准字幕;排除 SDH 字幕。',
			'accountPreferences.forcedSubtitles' => '强制字幕',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => '优先非强制字幕',
			'accountPreferences.forcedSubtitleOptions.preferForced' => '优先强制字幕',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => '仅强制字幕',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => '仅非强制字幕',
			'accountPreferences.forcedSubtitleOptions.preferNonForcedDescription' => '更喜欢定期的字幕,但允许强迫轨道作为落后。',
			'accountPreferences.forcedSubtitleOptions.preferForcedDescription' => '偏好在可用时强迫行列,但允许定期字幕作为落后。',
			'accountPreferences.forcedSubtitleOptions.onlyForcedDescription' => '只使用被强制标记的轨道。',
			'accountPreferences.forcedSubtitleOptions.onlyNonForcedDescription' => '排除被强制标记的轨道。',
			'accountPreferences.displayMissingEpisodes' => '显示缺失剧集',
			'accountPreferences.displayMissingEpisodesDescription' => '列出服务器知道但没有对应文件的剧集。',
			'accountPreferences.hidePlayedInLatest' => '在“最新”中隐藏已观看项目',
			'accountPreferences.hidePlayedInLatestDescription' => '将你已经看过的项目从服务器的“最新”列表中移除。',
			'accountPreferences.displayCollectionsView' => '显示合集视图',
			'accountPreferences.displayCollectionsViewDescription' => '在媒体库之外提供服务器的合集视图。',
			'accountPreferences.rewatchingInNextUp' => '在“接下来”中保留重看的剧集',
			'accountPreferences.rewatchingInNextUpDescription' => '看完一部剧集后再次开始观看时，“接下来”会跟随重看进度，而不是将剧集移除。',
			'accountPreferences.watchedIndicator' => '已观看标记',
			'accountPreferences.watchedIndicatorOptions.none' => '从不',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => '电影和电视剧',
			'accountPreferences.watchedIndicatorOptions.movies' => '仅电影',
			'accountPreferences.watchedIndicatorOptions.shows' => '仅电视剧',
			'accountPreferences.watchedIndicatorOptions.noneDescription' => '不要显示已观看的检查标志。',
			'accountPreferences.watchedIndicatorOptions.moviesAndShowsDescription' => '显示观看的电影和电视节目检查标志。',
			'accountPreferences.watchedIndicatorOptions.moviesDescription' => '只为电影显示观看标签。',
			'accountPreferences.watchedIndicatorOptions.showsDescription' => '只为电视节目显示观看的检查标志。',
			'accountPreferences.mediaReviewsVisibility' => '评分与评论',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => '用户和影评人',
			'accountPreferences.mediaReviewsOptions.usersOnly' => '仅用户',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => '仅影评人',
			'accountPreferences.mediaReviewsOptions.nobody' => '隐藏',
			'accountPreferences.mediaReviewsOptions.usersAndCriticsDescription' => '显示用户评分和批判性评分。',
			'accountPreferences.mediaReviewsOptions.usersOnlyDescription' => '显示用户提交的评分和评论。',
			'accountPreferences.mediaReviewsOptions.criticsOnlyDescription' => '显示批判性评分和评论。',
			'accountPreferences.mediaReviewsOptions.nobodyDescription' => '隐藏评分和评论。',
			'accountPreferences.preferredAudioLanguageDescription' => '在此语言中更喜欢音频轨道,当服务器或播放器自动选择轨道时。',
			'accountPreferences.preferredSubtitleLanguageDescription' => '自动选择字幕时，优先选择此语言的字幕轨道。',
			'accountPreferences.subtitleAccessibilityDescription' => '自动选择字幕时，设置听障字幕（SDH）为优先或必选。',
			'accountPreferences.forcedSubtitleDescription' => '自动选择字幕时，选择优先使用强制字幕轨道，或是必须使用强制字幕轨道。',
			'accountPreferences.watchedIndicatorDescription' => '选择哪个媒体类型在服务器界面中获得观看的检查标志。',
			'accountPreferences.mediaReviewsVisibilityDescription' => '选择哪个观众和批判评分服务器在媒体页面上显示。',
			'accountPreferences.subtitleModeDescription' => '在此服务器帐户中自动启动子标题时选择。',
			'accountPreferences.hubDescription' => '这些偏好存储在您的媒体服务器帐户上,并可能适用于其他客户。',
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
			'discover.findNext.title' => '发现下一个心头好',
			'discover.findNext.open' => '发现下一个心头好',
			'discover.findNext.anyTime' => '不限时长',
			'discover.findNext.timeAvailable' => '你有多少时间？',
			'discover.findNext.filters' => '选出此刻想做的事',
			'discover.findNext.watch' => '观看',
			'discover.findNext.listen' => '聆听',
			'discover.findNext.read' => '阅读',
			'discover.findNext.finishable' => ({required Object duration}) => '${duration}内可完成',
			'discover.findNext.aboutDuration' => ({required Object duration}) => '约${duration}',
			'discover.findNext.nextUnit' => ({required Object duration}) => '下一章 · ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => '共${duration}',
			'discover.findNext.timingVaries' => '时长可能有所不同',
			'discover.findNext.notNow' => '暂时跳过',
			'discover.findNext.swipeHint' => '朝箭头方向滑动封面，或使用下方按钮。',
			'discover.findNext.saved' => '已保存的推荐',
			'discover.findNext.savedCount' => ({required Object count}) => '已保存的推荐 · ${count}',
			'discover.findNext.undo' => '撤销',
			'discover.findNext.details' => '详情',
			'discover.findNext.noPicks' => '暂时没有可选内容',
			'discover.findNext.noPicksHint' => '连接媒体库或添加媒体来源即可开始。',
			'discover.findNext.noMatches' => '没有适合此刻的内容',
			'discover.findNext.noMatchesHint' => '试试其他内容类型，或留出更多时间。',
			'discover.findNext.allDone' => '你已浏览全部推荐',
			'discover.findNext.allDoneHint' => '换一组推荐，就能再次看到这些选项。',
			'discover.findNext.refresh' => '寻找另一组推荐',
			'discover.findNext.sourceReason' => ({required Object source}) => '来自${source}',
			'discover.findNext.libraryReason' => ({required Object library}) => '来自${library}',
			'discover.findNext.ownedReason' => '来自你的媒体库',
			'discover.findNext.liveNow' => '正在播出',
			'discover.findNext.watchLive' => '观看直播',
			'discover.findNext.filterAnything' => '不限类型',
			'discover.findNext.filterWatch' => '观看',
			'discover.findNext.filterListen' => '聆听',
			'discover.findNext.filterRead' => '阅读',
			'discover.findNext.twentyMinutes' => '20分钟',
			'discover.findNext.fortyFiveMinutes' => '45分钟',
			'discover.findNext.ninetyMinutes' => '90分钟',
			'discover.findNext.apply' => '应用',
			'discover.findNext.openFailed' => '此内容已不可用。刷新后再次查看。',
			'discover.findNext.changeFailed' => '无法保存此次更改，请重试。',
			'discover.findNext.savedLimit' => '已保存的推荐列表已满。请先移除一条推荐，再保存其他推荐。',
			'discover.findNext.chooseHint' => '打开作品、保存以便稍后查看，或跳过。',
			'discover.findNext.howItWorks' => '使用方法',
			'discover.findNext.notNowHelp' => '暂时跳过这部作品。它仍会保留在媒体库中。',
			'discover.findNext.saveHelp' => '保存到此设备上当前个人资料的已保存推荐中。保存不会下载作品。',
			'discover.findNext.openHelp' => '选择封面查看详情。使用主按钮播放、阅读或打开作品。',
			'discover.findNext.controlsHelp' => '键盘或遥控器：将焦点移到按钮，然后按 Enter 或选择键。撤销可恢复上一次选择。',
			'discover.findNext.artworkLoading' => '正在加载图片…',
			'discover.findNext.artworkUnavailable' => '图片不可用',
			'discover.findNext.savedFeedback' => '已加入保存的推荐',
			'discover.findNext.skippedFeedback' => '已暂时跳过',
			'discover.findNext.releaseToConfirm' => '松开以确认',
			'discover.findNext.remoteHint' => '封面获得焦点时：← / → 选择 · 选择键查看详情 · ↑ / ↓ 移动焦点',
			'discover.extras' => '预告片与花絮',
			'discover.studio' => '制作公司',
			'discover.rating' => '年龄分级',
			'discover.director' => '导演',
			'discover.directors' => '导演',
			'discover.movie' => '电影',
			'discover.tvShow' => '电视剧',
			'discover.minutesLeft' => ({required Object minutes}) => '剩余 ${minutes} 分钟',
			'discover.moreLikeThis' => '更多类似内容',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '第${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}章', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 个标题', ), 
			'discover.person.born' => '出生',
			'discover.person.died' => '逝世',
			'discover.person.birthplace' => '出生地',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date}（${age} 岁）',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date}（享年 ${age} 岁）',
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
			'errors.reasonTimedOut' => '连接超时',
			'errors.reasonUnreachable' => '无法连接到服务器',
			'errors.reasonRefused' => '服务器拒绝了此请求',
			'errors.reasonNotFound' => '该项目已不在服务器上',
			'errors.reasonServerError' => '服务器报告了一个错误',
			'errors.reasonCancelled' => '请求已取消',
			'errors.reasonUnexpected' => '发生了意外错误',
			'libraries.playRandomMovie' => '随机电影播放',
			'libraries.randomPickFailed' => '不能从这本图书馆选择随机电影。',
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
			_ => null,
		} ?? switch (path) {
			'libraries.filterCategories.unwatched' => '未观看',
			'libraries.filterCategories.unplayed' => '未播放',
			'libraries.filterCategories.favorites' => '收藏夹',
			'libraries.filterCategories.filePath' => '文件路径',
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
			'libraries.sortLabels.dateDownloaded' => '下载日期',
			'libraries.sortLabels.size' => '大小',
			'libraries.sortLabels.library' => '媒体库',
			'libraries.advancedFilters.include' => '包含',
			'libraries.advancedFilters.exclude' => '排除',
			'libraries.advancedFilters.any' => '不限',
			'libraries.advancedFilters.yes' => '是',
			'libraries.advancedFilters.no' => '否',
			'libraries.advancedFilters.not' => ({required Object value}) => '排除 ${value}',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '已选 ${count} 项',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '已排除 ${count} 项',
			'libraries.advancedFilters.searchValues' => '搜索值',
			'libraries.advancedFilters.noValues' => '没有可选值',
			'libraries.advancedFilters.matchContains' => '包含',
			'libraries.advancedFilters.matchNotContains' => '不包含',
			'libraries.advancedFilters.matchIs' => '是',
			'libraries.advancedFilters.matchIsNot' => '不是',
			'libraries.advancedFilters.matchBeginsWith' => '开头为',
			'libraries.advancedFilters.matchEndsWith' => '结尾为',
			'libraries.advancedFilters.textHint' => '输入以匹配',
			'libraries.advancedFilters.from' => '从',
			'libraries.advancedFilters.to' => '至',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from} 至 ${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value} 及以上',
			'libraries.advancedFilters.atMost' => ({required Object value}) => '${value} 及以下',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => '最近 ${count} 天',
			'libraries.advancedFilters.dateLastYear' => '过去一年',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => '早于 ${count} 天前',
			'libraries.advancedFilters.dateOlderThanYear' => '早于一年前',
			'libraries.selection.selectItems' => '选择项目',
			'libraries.selection.selectedCount' => ({required Object count}) => '已选 ${count} 项',
			'libraries.selection.actions' => '选择行动',
			'libraries.selection.confirmDescendants' => '这一变化改变了所有节目和季节的节目。',
			'libraries.selection.confirmUnwatched' => '这也会清除所选项目的播放进度。',
			'libraries.selection.confirmCount' => ({required Object count}) => '已选择的项目: ${count}。',
			'libraries.selection.completed' => ({required Object count}) => '更新項目: ${count}',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => '更新 ${succeeded}; 失败 ${failed}. 失败的项目仍然被选择。',
			'about.title' => '关于',
			'about.openSourceLicenses' => '开源许可证',
			'about.versionLabel' => ({required Object version}) => '版本 ${version}',
			'about.appDescription' => '一款精美的 Flutter Plex、Jellyfin 和 Emby 客户端',
			'about.viewLicensesDescription' => '查看第三方库的许可证',
			'about.privacyPolicy' => '隐私政策',
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
			'logs.saveLogs' => '存储存档',
			'logs.logsSaved' => ({required Object path}) => '存储到 ${path} 的存档',
			'logs.saveLogsFailed' => '无法保存存档。',
			'startup.failedTitle' => 'PlezyNG 无法启动',
			'startup.failedBody' => '启动过程中出现问题。以下详情指出了失败的原因。',
			'startup.failedBodyRepairable' => 'PlezyNG 的已保存设置文件已损坏，必须先重建才能启动。重试没有用——请选择“修复存储”。',
			'startup.phaseLabel' => '步骤',
			'startup.showDetails' => '显示详情',
			'startup.hideDetails' => '隐藏详情',
			'startup.copyDetails' => '复制详情',
			'startup.detailsCopied' => '详情已复制到剪贴板',
			'startup.uploadDetails' => '上传详情',
			'startup.repairStorage' => '修复存储',
			'startup.repairTitle' => '修复已存储的数据？',
			'startup.repairBodyCommon' => 'PlezyNG 的设置文件已损坏且无法读取。修复会将所有设置重置为默认值。',
			'startup.repairBodyOneCredential' => '有一项已保存的登录信息已损坏且无法读取。修复只会移除这一项，其他设置保持不变。',
			'startup.repairBodySignInsKept' => '你的服务器和个人资料应保持登录状态。',
			'startup.repairBodySignInsLost' => '保护已保存登录信息的密钥无法从此文件中恢复，因此你需要重新登录每个服务器和个人资料。媒体服务器上的内容不受影响。',
			'startup.repairBodySessionsUncertain' => '追踪服务（MAL、AniList、Simkl、Trakt）和 Seerr 是分开存储的，可能保留也可能无法保留。PlezyNG 会明确告诉你保留了哪些。',
			'startup.repairConfirm' => '修复',
			'startup.repairSucceeded' => '存储已修复',
			'startup.repairNeedsRestart' => '存储已修复 — 需要重启',
			'startup.restartRequiredBody' => '你的数据已修复，但 PlezyNG 需要重新启动后才能使用。请关闭 PlezyNG 并重新打开。',
			'startup.quitPlezy' => '退出 PlezyNG',
			'startup.repairFailed' => '修复失败',
			'startup.repairKeptSignIns' => '你的服务器和个人资料仍然保持登录状态。',
			'startup.repairLostSignIns' => '保护已保存登录信息的密钥无法恢复。你需要重新登录每个服务器和个人资料。',
			'startup.repairLostSessions' => '至少有一个追踪服务或 Seerr 连接已丢失，需要重新连接。',
			'startup.backupTitle' => '已保留损坏文件的副本',
			'startup.backupWarning' => '其中包含你的登录凭据。请勿上传或分享。',
			'startup.deleteBackup' => '删除副本',
			'startup.backupDeleted' => '副本已删除。',
			'startup.previousFailureTitle' => 'PlezyNG 上次启动失败',
			'licenses.relatedPackages' => '相关软件包',
			'licenses.license' => '许可证',
			'licenses.licenseNumber' => ({required Object number}) => '许可证 ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} 个许可证',
			'navigation.libraries' => '媒体库',
			'navigation.downloads' => '下载',
			'navigation.liveTv' => '直播电视',
			'navigation.explore' => '探索',
			'explore.mdblistShelves.manage' => '管理 探索 地板',
			'explore.mdblistShelves.manageDescription' => '從您的帳戶中選擇和安排列表 MDBList',
			'explore.mdblistShelves.description' => '從您的 MDBList 帳戶中選擇公開電影和電視列表. 創建或複製列表在 MDBList 然後更新。',
			'explore.mdblistShelves.selected' => '选择的板块',
			'explore.mdblistShelves.available' => '可用的账户列表',
			'explore.mdblistShelves.noLists' => '没有公开的电影或电视列表返回. 创建或复制列表在 MDBList,然后更新。',
			'explore.mdblistShelves.displayName' => '沙尔夫 显示名称',
			'explore.mdblistShelves.nameHint' => '请点击使用源名单名称。',
			'explore.mdblistShelves.add' => '添加Shelf',
			'explore.mdblistShelves.save' => '保存沙地',
			'explore.mdblistShelves.moveUp' => ({required Object title}) => '移动 ${title} 升',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => '移动 ${title} 下载',
			'explore.mdblistShelves.unavailable' => '此列表不可用 退出或在设置中删除其架子。',
			'explore.mdblistShelves.rateLimited' => '第MDBList号请求限制已达到,请随后退出。',
			'explore.mdblistShelves.loadFailed' => '不能充电板,检查你的连接和退出。',
			'explore.mdblistShelves.saveFailed' => '没办法放下,请放下。',
			'explore.mdblistShelves.accountChanged' => '帐户或个人资料已更改 重新打开这些设置。',
			'explore.mdblistShelves.settingsUnreadable' => '保存的字段无法阅读. 重新选择列表以取代这些设置。',
			'explore.title' => '探索',
			'explore.selectSource' => '选择来源',
			'explore.rows.watchlist' => '想看列表',
			'explore.rows.recommendedMovies' => '推荐电影',
			'explore.rows.recommendedShows' => '推荐剧集',
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
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 集', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 集', ), 
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
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '无法查看 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 服务器', other: '无法检查 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 台服务器', ), 
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
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 评论', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 条评论', ), 
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
			'explore.creditRole.actor' => '演员',
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
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '由 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 用户推荐', other: '由 ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 位用户推荐', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => '由 ${who} 推荐',
			'explore.detail.favoritedBy' => ({required Object who}) => '由 ${who} 收藏',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '还有 ${n} 集未播出',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => '${percent} 的观众推荐',
			'explore.detail.relatedTitles' => '相关作品',
			'explore.detail.background' => '背景',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 结果', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 条结果', ), 
			'liveTv.title' => '直播电视',
			'liveTv.guide' => '节目指南',
			'liveTv.noChannels' => '没有可用的频道',
			'liveTv.noDvr' => '没有服务器配置 DVR',
			'liveTv.serverUnavailable' => '直播电视服务器不可用。',
			'liveTv.serverNotConnected' => '直播电视服务器未连接。',
			'liveTv.noPrograms' => '没有可用的节目数据',
			'liveTv.liveStreamFailed' => '直播流失败',
			'liveTv.unknownProgram' => '未知节目',
			'liveTv.timelineLiveProgram' => '直播程序(播放可能不在此程序)',
			'liveTv.timelineBuffer' => '布菲尔时间表',
			'liveTv.timelineUnavailable' => '时间不可用',
			'liveTv.timelineEstimated' => '值得一提的Playback',
			'liveTv.timelinePending' => '求求求',
			'liveTv.timelineStale' => '时间表可能过时',
			'liveTv.unknownHub' => '未知',
			'liveTv.unknownError' => '未知错误',
			'liveTv.channelNumber' => ({required Object number}) => '频道 ${number}',
			'liveTv.unknownChannel' => '未知频道',
			'liveTv.live' => '直播',
			'liveTv.premiereBadge' => '新',
			'liveTv.reloadGuide' => '重新加载节目指南',
			'liveTv.searchGuide' => '搜索节目指南',
			'liveTv.searchHint' => '搜索频道和节目',
			'liveTv.searchNoResults' => ({required Object query}) => '没有与“${query}”匹配的结果',
			'liveTv.channelsSection' => '频道',
			'liveTv.programsSection' => '节目',
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
			'liveTv.guideReloadFailed' => '无法刷新节目指南',
			'liveTv.rulesProcessRequested' => '已请求重新评估规则',
			'liveTv.rulesProcessFailed' => '无法重新评估录制规则',
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
			'liveTv.playbackStartFailed' => ({required Object reason}) => '无法启动该频道：${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => '无法切换频道：${reason}',
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
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(count, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)}个项目', ), 
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
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 路径', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 首', ), 
			'music.nowPlaying' => '正在播放',
			'music.playingFrom' => ({required Object title}) => '播放来源：${title}',
			'music.queue' => '播放队列',
			'music.clearQueue' => '清空队列',
			'music.lyrics' => '歌词',
			'music.visualizer' => '视觉化',
			'music.visualizerProfileLoading' => '阅读路径分析',
			'music.visualizerAmbientMotion' => '环境动作',
			'music.visualizerPlexLoudness' => 'Plex 噪音',
			'music.visualizerPreviousPreset' => '以前的视觉风格',
			'music.visualizerNextPreset' => '下一篇 视觉风格',
			'music.visualizerPresetAurora' => '奥拉',
			'music.visualizerPresetBloom' => '蓝色',
			'music.visualizerPresetOrbitals' => '轨道',
			'music.visualizerPresetPrism' => '普里斯',
			'music.visualizerPresetTunnel' => '隧道',
			'music.visualizerPresetTrackMap' => '跟踪地图',
			'music.noLyrics' => '暂无歌词',
			'music.sleepTimer' => '睡眠定时器',
			'music.sleepTimerEndOfTrack' => '当前曲目结束时',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}分钟', ), 
			'music.stopPlayback' => '停止播放',
			'music.previousTrack' => '上一首',
			'music.nextTrack' => '下一首',
			'music.repeat' => '循环',
			'music.repeatAll' => '列表循环',
			'music.repeatOne' => '单曲循环',
			'music.instantMixNoServer' => '没有可用于即时混合的服务器',
			'music.instantMixFailed' => '加载即时混合失败',
			'music.instantMixEmpty' => '即时混合没有生成任何曲目',
			'music.noAudioUrl' => ({required Object track}) => '没有可供 ${track} 使用的音频 URL',
			'music.discography.singlesAndEps' => '单曲和 EP',
			'music.discography.live' => '现场',
			'music.discography.compilations' => '合集',
			'watchTogether.title' => '一起看',
			'watchTogether.description' => '与朋友和家人同步观看内容',
			'watchTogether.createRoom' => '创建房间',
			'watchTogether.creatingRoom' => '正在创建房间…',
			'watchTogether.joinRoom' => '加入房间',
			'watchTogether.joiningRoom' => '正在加入房间…',
			'watchTogether.connecting' => '正在连接…',
			'watchTogether.relayPublic' => '房间使用公共 Open Watch Party 中继服务器。',
			'watchTogether.relayCustom' => ({required Object url}) => '房间使用你位于 ${url} 的中继服务器。',
			'watchTogether.recentRooms' => '最近的房间',
			'watchTogether.roomActions' => '房间操作',
			'watchTogether.renameRoom' => '重命名房间',
			'watchTogether.removeRoom' => '移除',
			'watchTogether.enterRoomCode' => '输入主持人提供的 6 位代码。',
			'watchTogether.roomCode' => '房间代码',
			'watchTogether.paste' => '粘贴',
			'watchTogether.noCodeInClipboard' => '剪贴板中没有房间代码',
			'watchTogether.copyCode' => '复制代码',
			'watchTogether.codeCopied' => '房间代码已复制',
			'watchTogether.shareInvite' => '分享邀请',
			'watchTogether.inviteCopied' => '邀请已复制。请将其粘贴到消息中。',
			'watchTogether.inviteMessage' => ({required Object code}) => '加入我在 PlezyNG 中的“一起看”房间：打开“一起看”，选择“加入房间”，然后输入 ${code}。',
			'watchTogether.openSessionControls' => '打开“一起看”会话控制',
			'watchTogether.reconnecting' => '正在重新连接…',
			'watchTogether.reconnectingDescription' => '连接已中断。你将自动重新加入房间。',
			'watchTogether.connected' => '已连接',
			'watchTogether.disconnected' => '已断开连接',
			'watchTogether.youAreHost' => '你是主持人',
			'watchTogether.hostedBy' => ({required Object name}) => '由 ${name} 主持',
			'watchTogether.hostControlsPlayback' => '主持人控制播放',
			'watchTogether.anyoneCanControl' => '任何人都可以控制播放',
			'watchTogether.roomLocked' => '房间已锁定',
			'watchTogether.nowPlaying' => '正在播放',
			'watchTogether.nothingPlaying' => '未在播放',
			'watchTogether.nothingPlayingHost' => '从任意媒体库播放内容，即可与房间成员分享。',
			'watchTogether.nothingPlayingGuest' => '主持人播放内容后，将在此处打开。',
			'watchTogether.notShareable' => '此视频没有匹配的影视目录条目，因此只有能访问同一服务器的人才能播放。',
			'watchTogether.searching' => '正在你的媒体库中查找此视频…',
			'watchTogether.yourCopy' => '你的副本',
			'watchTogether.sharingYourCopy' => '你正在分享你的副本',
			'watchTogether.playingOtherLength' => ({required Object difference}) => '正在播放你的副本（${difference}）',
			'watchTogether.mismatchTitle' => '你的副本时长不同',
			'watchTogether.mismatchDescription' => ({required Object difference}) => '你最接近的副本比房间的视频${difference}。它可能是其他剪辑版或版本。',
			'watchTogether.playAnyway' => '仍要播放',
			'watchTogether.chooseAnotherCopy' => '选择其他副本',
			'watchTogether.dontPlay' => '不播放',
			_ => null,
		} ?? switch (path) {
			'watchTogether.unavailableTitle' => '你没有此视频',
			'watchTogether.unavailableDescription' => 'PlezyNG 在你的媒体库中找不到它。请自行选择副本或重新搜索。',
			'watchTogether.chooseCopy' => '选择副本',
			'watchTogether.searchAgain' => '重新搜索',
			'watchTogether.noCandidates' => '在你的媒体库中未找到副本。',
			'watchTogether.choiceFailed' => '无法为房间播放此副本',
			'watchTogether.lengthLonger' => ({required Object duration}) => '长 ${duration}',
			'watchTogether.lengthShorter' => ({required Object duration}) => '短 ${duration}',
			'watchTogether.lengthSame' => '时长相同',
			'watchTogether.lengthUnknown' => '时长未知',
			'watchTogether.joinCurrentPlayback' => '加入当前播放',
			'watchTogether.joinCurrentPlaybackDescription' => '加入主持人当前正在观看的内容',
			'watchTogether.stopMedia' => '为所有人停止视频',
			'watchTogether.syncOffset' => '同步偏移',
			'watchTogether.syncOffsetDescription' => '如果你的视频比房间快或慢，可在此调整。',
			'watchTogether.offsetHint' => ({required Object difference}) => '你的副本比房间的视频${difference}。',
			'watchTogether.applyDifference' => ({required Object offset}) => '使用 ${offset}',
			'watchTogether.offsetMinusSecond' => '-1 秒',
			'watchTogether.offsetMinusTenth' => '-100 毫秒',
			'watchTogether.offsetPlusTenth' => '+100 毫秒',
			'watchTogether.offsetPlusSecond' => '+1 秒',
			'watchTogether.participants' => '参与者',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 參與者', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 位参与者', ), 
			'watchTogether.hostBadge' => '主持人',
			'watchTogether.nameYou' => ({required Object name}) => '${name}（你）',
			'watchTogether.playerIdle' => '空闲',
			'watchTogether.playerLoading' => '加载中',
			'watchTogether.playerReady' => '就绪',
			'watchTogether.playerBuffering' => '缓冲中',
			'watchTogether.matchSearching' => '搜索中',
			'watchTogether.matchMatched' => '有此视频',
			'watchTogether.matchMismatched' => '时长不同',
			'watchTogether.matchUnavailable' => '没有此视频',
			'watchTogether.participantOffset' => ({required Object offset}) => '偏移 ${offset}',
			'watchTogether.makeHost' => '设为主持人',
			'watchTogether.makeHostQuestion' => '移交主持人？',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} 将控制播放并主导所有人的会话。',
			'watchTogether.transfer' => '移交',
			'watchTogether.removeParticipant' => '移出房间',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => '移除 ${name}？',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} 将离开房间。除非你锁定房间，否则对方仍可使用代码重新加入。',
			'watchTogether.remove' => '移除',
			'watchTogether.roomSettings' => '房间设置',
			'watchTogether.letEveryoneControl' => '允许所有人控制播放',
			'watchTogether.lockRoom' => '锁定房间',
			'watchTogether.lockRoomDescription' => '新成员无法加入',
			'watchTogether.leaveRoom' => '离开房间',
			'watchTogether.leaveRoomQuestion' => '离开房间？',
			'watchTogether.leaveRoomConfirm' => '你可以使用房间代码重新加入。',
			'watchTogether.leave' => '离开',
			'watchTogether.endRoom' => '结束房间',
			'watchTogether.endRoomQuestion' => '结束房间？',
			'watchTogether.endRoomConfirm' => '这将为所有人结束此房间。',
			'watchTogether.end' => '结束',
			'watchTogether.playBlockedTitle' => '播放未开始',
			'watchTogether.playBlockedDescription' => '按下播放，开始与房间成员一起观看。',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} 按下了播放',
			'watchTogether.notices.playbackStarted' => '已开始播放',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} 暂停了播放',
			'watchTogether.notices.playbackPaused' => '已暂停播放',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} 跳转到了 ${position}',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => '已跳转到 ${position}',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} 将速度设为 ${speed}',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => '速度已设为 ${speed}',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} 开始播放 ${title}',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => '正在播放 ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} 停止了视频',
			'watchTogether.notices.mediaStopped' => '视频已停止',
			'watchTogether.notices.waitingFor' => ({required Object name}) => '正在等待 ${name}…',
			'watchTogether.notices.waitingForSomeone' => '正在等待其他人跟上…',
			'watchTogether.notices.finished' => '已播放完毕',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} 现在是主持人',
			'watchTogether.notices.youAreNowHost' => '你现在是主持人',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} 已加入',
			'watchTogether.notices.left' => ({required Object name}) => '${name} 已离开',
			'watchTogether.notices.controlRefused' => '只有主持人可以控制播放',
			'watchTogether.notices.searchFailed' => '无法在部分服务器上搜索房间的视频',
			'watchTogether.notices.playBlocked' => '按下播放即可开始',
			'watchTogether.notices.shareFailed' => '无法与房间分享此视频',
			'watchTogether.notices.downloadNotShared' => '下载内容所属的服务器离线时，无法与房间分享',
			'watchTogether.notices.openFailed' => '无法打开房间的视频',
			'watchTogether.ended.ended' => '主持人已结束房间',
			'watchTogether.ended.kicked' => '你已被移出房间',
			'watchTogether.ended.expired' => '房间已过期',
			'watchTogether.ended.replaced' => '你已在另一台设备上加入此房间',
			'watchTogether.ended.lost' => '与房间的连接已断开',
			'watchTogether.errors.invalidCode' => '这不是房间代码。代码由 6 位字母和数字组成，不含 0、1、I、L 或 O。',
			'watchTogether.errors.roomNotFound' => '没有使用此代码的房间。该房间可能已结束。',
			'watchTogether.errors.roomFull' => '该房间已满。',
			'watchTogether.errors.roomLocked' => '主持人已锁定该房间。',
			'watchTogether.errors.relayFull' => '“一起看”当前繁忙。请稍后再试。',
			'watchTogether.errors.unreachable' => '无法连接到“一起看”中继服务器。请检查网络连接。',
			'watchTogether.errors.rateLimited' => '尝试次数过多。请稍等片刻后重试。',
			'watchTogether.errors.clientBlocked' => '此版本的 PlezyNG 无法使用该中继服务器。请更新应用。',
			'watchTogether.errors.forbidden' => '只有主持人可以执行此操作。',
			'watchTogether.errors.notInRoom' => '你不在房间中。',
			'watchTogether.errors.alreadyInRoom' => '你已在房间中。',
			'watchTogether.errors.resumeFailed' => '无法重新加入房间。',
			'watchTogether.errors.unsupported' => '该中继服务器不支持此操作。',
			'watchTogether.errors.generic' => '出现问题。请重试。',
			'watchTogether.untitledEpisode' => ({required Object number}) => '第${number}集',
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
			'downloads.storageFull' => '为保护剩余存储空间，下载已停止。请释放空间或选择其他下载位置，然后重试。',
			'downloads.storageUnavailable' => '无法检查可用存储空间，因此下载已停止。请检查下载位置后重试。',
			'downloads.episodesQueued' => ({required Object count}) => '${count} 集已加入下载队列',
			'downloads.downloadDeleted' => '下载已删除',
			'downloads.deleteConfirm' => ({required Object title}) => '要从此设备删除“${title}”吗？',
			'downloads.deleteCollectionDownloads' => '删除下载',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => '要从此设备删除“${title}”中的所有下载吗？',
			'downloads.collectionDownloadsDeleted' => '下载已删除',
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
			'downloads.retryAll' => '全部重试',
			'downloads.retryFailed' => '重试失败的下载',
			'downloads.deleteAll' => '全部删除',
			'downloads.selectVersion' => '选择版本',
			'downloads.allEpisodes' => '所有剧集',
			'downloads.unwatchedOnly' => '仅未观看',
			'downloads.nextNUnwatched' => ({required Object count}) => '接下来 ${count} 集未观看',
			'downloads.customAmount' => '自定义数量…',
			'downloads.customAmountAny' => '每個數量(每個數...',
			'downloads.randomEpisodes' => '随机事件',
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
			'downloads.syncNow' => '现在的Sync',
			'downloads.downloadsUpToDate' => '下载到目前为止',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => '合成完整 · ${queued} queued, ${removed} 删除',
			'downloads.activeSyncRules' => '同步规则',
			'downloads.reviewOrphanFiles' => '检查无对应记录的下载',
			'downloads.orphanReviewTitle' => '检查无对应记录的下载',
			'downloads.orphanReviewDescription' => '这些已标记的文件位于 PlezyNG 默认管理的下载文件夹中，但没有匹配的下载记录或正在进行的任务。删除前请先检查列表。',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count} 个文件 · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => '删除 ${count} 个文件',
			'downloads.orphanCleanupNone' => '未找到无对应记录的下载文件',
			'downloads.orphanCleanupFailed' => 'PlezyNG 无法安全扫描受管理的下载文件夹。没有删除任何文件。',
			'downloads.orphanCleanupChanged' => '检查期间下载列表已更改。清理前请重新检查文件。',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => '已删除 ${count} 个无对应记录的文件 · 释放 ${size}',
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
			'downloads.syncRuleAccessDenied' => '访问被拒绝',
			'downloads.syncRuleNotAvailableForProfile' => '当前用户资料不可用',
			'downloads.syncRuleUnknownServer' => '未知服务器',
			'downloads.syncRuleListCreated' => '同步规则已创建',
			'downloads.backgroundWarning.bannerBlocked' => '离开应用后，下载将停止',
			'downloads.backgroundWarning.bannerDegraded' => '后台下载可能受限',
			'downloads.backgroundWarning.bannerAction' => '详情',
			'downloads.backgroundWarning.sheetTitle' => '后台下载已被阻止',
			'downloads.backgroundWarning.sheetTitleDegraded' => '后台下载可能受限',
			'downloads.backgroundWarning.sheetIntro' => 'Android 正在阻止 PlezyNG 在后台稳定下载。',
			'downloads.backgroundWarning.sheetIntroDegraded' => '你的设备限制了 PlezyNG 在后台下载的时机。',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'PlezyNG 的后台使用受到限制。请将其电池用量或后台使用设置为“不受限制”。',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android 已将 PlezyNG 置于受限待机状态。请将其电池用量设为“不受限制”。',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => '下载通知已关闭，因此可能无法查看进度或进行控制。',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => '通知已关闭。在 Android 13 或更高版本中，长时间后台下载需要开启通知。',
			'downloads.backgroundWarning.reasonDataSaver' => '流量节省程序已开启，会阻止使用移动数据进行后台下载。使用 Wi-Fi 时下载应仍可进行。',
			'downloads.backgroundWarning.reasonOemUnknown' => 'PlezyNG 在后台时，下载曾多次停止。请检查 PlezyNG 的电池用量或后台使用设置。',
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
			'downloads.options' => '下载选项',
			'downloads.groupings.library' => '媒体库',
			'downloads.groupings.collections' => '合集',
			'downloads.unknownLibrary' => '未知媒体库',
			'downloads.unknownShow' => '未知节目',
			'downloads.unknownSeason' => '未知季',
			'downloads.unknownAlbum' => '未知专辑',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '已完成 ${completed}/${total}',
			'downloads.storageUsed' => ({required Object size}) => '使用的存储: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}个下载', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}个下载', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 展览', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 显示', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 電影', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} 電影', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}张专辑', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}张专辑', ), 
			'downloads.errorFileNotFound' => '未找到文件（404）',
			'downloads.errorDownloadNotAllowed' => '服务器不允许下载（403）',
			'downloads.errorDownloadFailed' => '下载失败',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => '下载失败：${reason}',
			'downloads.convertingOnServer' => '转换到服务器',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => '转换到服务器 · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => '下载失败（HTTP ${status}）',
			'downloads.errorPostProcessing' => ({required Object reason}) => '后处理失败：${reason}',
			'downloads.reasonFileNotSaved' => '无法将文件保存到此设备',
			'downloads.reasonCannotResume' => '无法继续未完成的下载',
			'downloads.reasonDeviceStorageFull' => '此设备的存储空间已满',
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
			'companionRemote.pairing.discoveryDescription' => '使用同一 Plex 账号的 PlezyNG 设备会显示在这里',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => '正在连接…',
			'companionRemote.pairing.searchingForDevices' => '正在搜索设备…',
			'companionRemote.pairing.noDevicesFound' => '未在网络中找到设备',
			'companionRemote.pairing.noDevicesHint' => '请在桌面端打开 PlezyNG，并确保设备连接到同一 Wi-Fi 网络',
			'companionRemote.pairing.availableDevices' => '可用设备',
			'companionRemote.pairing.manualConnection' => '手动连接',
			'companionRemote.pairing.cryptoInitFailed' => '无法启动安全连接。请先登录 Plex。',
			'companionRemote.pairing.validationHostRequired' => '请输入主机地址',
			'companionRemote.pairing.validationHostFormat' => '格式必须为 IP:端口（例如 192.168.1.100:48632）',
			'companionRemote.pairing.connectionTimedOut' => '连接超时。请在两台设备上使用同一网络。',
			'companionRemote.pairing.sessionNotFound' => '未找到设备。请确认 PlezyNG 正在主机上运行。',
			'companionRemote.pairing.authFailed' => '认证失败。两台设备需要使用同一 Plex 账号。',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => '连接失败：${error}',
			'companionRemote.pairing.codeTitle' => '双重代码',
			'companionRemote.pairing.codeDescription' => '在主机设备上输入“远程伴侣”中显示的代码,两台设备都必须使用支持安全配对的版本。',
			'companionRemote.pairing.codeInvalid' => '输入所有 32 个字母和号码的主机代码。',
			'companionRemote.pairing.updateRequired' => '将两台设备更新到支持安全配对的版本。',
			'companionRemote.pairing.hostDescription' => '每次输入此代码一次,远程保持隐私:它提供对此个人资料的控制。',
			'companionRemote.pairing.resetCode' => '重新设置编码',
			'companionRemote.pairing.resetDescription' => '切断所有远程,并创建一个新的代码,每个远程都需要重新连接。',
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
			'videoSettings.audioEqualizer' => '音频平衡器',
			'videoSettings.audioEqualizerDescription' => '适用于此设备的五个频率带;可在mpv上;一个活跃的EQ音频解码,并禁用匹配。',
			'videoSettings.audioEqualizerFlat' => '平板',
			'videoSettings.audioEqualizerActive' => '自定义',
			'videoSettings.audioEqualizerSaveFailed' => '无法保存音频平衡器设置。',
			'videoSettings.backgroundVideoAudio' => '背景视频音频',
			'videoSettings.backgroundVideoAudioDescription' => '离开播放器后继续播放视频音频；返回前画面将被隐藏。Android 会显示媒体播放通知。',
			'videoSettings.audioNormalization' => '响度标准化',
			'videoSettings.audioNormalizationDisablesPassthrough' => '将音频解码为 PCM；开启时直通关闭',
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
			'performanceOverlay.dvRouteDecoder' => 'Dolby Vision 解码器',
			'performanceOverlay.dvRouteDecoderP81' => 'Dolby Vision 解码器（P7→8.1）',
			'performanceOverlay.dvRouteBaseLayer' => '基础层',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'HDR10 基础层',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'HLG 基础层',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'SDR 基础层',
			'performanceOverlay.dvRouteReshaped' => 'RPU 重塑（gpu-next）',
			'performanceOverlay.dvRouteFelGraphActive' => '实验 P7 FEL 图表(未合格)',
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
			'performanceOverlay.playMethod' => '玩方法',
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
			'externalPlayer.description' => '选择另一个应用程序打开视频,可用的玩家取决于您的设备和安装的应用程序。',
			'externalPlayer.systemDefaultDescription' => '让操作系统使用默认应用程序打开视频。',
			'externalPlayer.playerOptionDescription' => ({required Object player}) => '使用 ${player} 打开视频。',
			'externalPlayer.playerNameDescription' => '标签显示在玩家列表中。',
			'externalPlayer.playerPackageDescription' => '输入玩家应用程序的Android包名称,如com.example.player。',
			'externalPlayer.playerCommandDescription' => '输入该设备安装的播放器命令或可执行路径。',
			'externalPlayer.playerUrlSchemeDescription' => '输入 URL 格式和可选的 URL 模板,用于启动播放器。',
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
			_ => null,
		} ?? switch (path) {
			'metadataEdit.addTag' => '添加标签',
			'metadataEdit.genre' => '类型',
			'metadataEdit.director' => '导演',
			'metadataEdit.writer' => '编剧',
			'metadataEdit.producer' => '制片人',
			'metadataEdit.country' => '国家',
			'metadataEdit.collection' => '合集',
			'metadataEdit.label' => '标记',
			'metadataEdit.quickTag' => '快速标签…',
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
			'trakt.disconnectConfirmBody' => 'PlezyNG 将停止向 Trakt 发送事件。你可随时重新连接。',
			'trakt.scrobble' => '实时同步播放状态',
			'trakt.scrobbleDescription' => '播放期间将播放、暂停和停止事件发送到 Trakt。',
			'trakt.watchedSync' => '同步已观看状态',
			'trakt.watchedSyncDescription' => '在 PlezyNG 中将内容标记为已观看时，也会在 Trakt 上标记为已观看。',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => '连接 Seerr',
			'seerr.serverUrl' => '服务器 URL',
			'seerr.serverUrlHelper' => '你的 Seerr 实例的地址',
			'seerr.checkServer' => '继续',
			'seerr.signInWithJellyfin' => '使用 Jellyfin 登录',
			'seerr.signInWithEmby' => '使用 Emby 登录',
			'seerr.signInWithLocal' => '使用本地账户',
			'seerr.email' => '邮箱',
			'seerr.noSignInMethods' => '此 Seerr 实例未提供 PlezyNG 支持的登录方式。',
			'seerr.instance' => '实例',
			'seerr.disconnectConfirm' => '断开 Seerr 连接？',
			'seerr.disconnectConfirmBody' => 'PlezyNG 将忘记此 Seerr 实例。可随时重新连接。',
			'seerr.request' => '请求',
			'seerr.request4k' => '请求 4K',
			'seerr.seasons' => '季',
			'seerr.allSeasons' => '全部季',
			'seerr.advancedOptions' => '高级',
			'seerr.destinationServer' => '目标服务器',
			'seerr.qualityProfile' => '画质配置',
			'seerr.rootFolder' => '根目录',
			'seerr.languageProfile' => '语言配置',
			'seerr.tags' => '标签',
			'seerr.noTags' => '无标签',
			'seerr.defaultOption' => ({required Object name}) => '${name}（默认）',
			'seerr.animeNote' => '此剧集为动画。',
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
			'seerr.behindAuthProxy' => '响应来自需要身份验证的反向代理（SSO 或 HTTP 认证），而非 Seerr。PlezyNG 无法通过它登录：请让 Seerr 的 /api/v1 路径为此应用绕过代理，或使用可直接访问 Seerr 的地址。',
			'seerr.invalidUrl' => '输入服务器地址，例如 https://seerr.example.com',
			'seerr.quickConnectUnsupported' => '此 Seerr 实例不支持 Quick Connect。需要 Seerr 3.4 或更高版本。',
			'seerr.notInitialized' => '此 Seerr 实例尚未完成首次运行设置',
			'seerr.noPlexTokenForReauth' => '没有可用于重新登录的 Plex 令牌',
			'seerr.noStoredCredentials' => '没有已保存的凭据可用于重新登录',
			'seerr.signInRejected' => '登录被拒绝',
			'seerr.noSessionCookie' => 'Seerr 未签发会话 Cookie',
			'seerr.freshCookieRejected' => 'Seerr 拒绝了新的会话 Cookie',
			'seerr.noUserInformation' => 'Seerr 未返回用户信息',
			'seerr.sessionRejectedAfterReauth' => '重新登录后会话被拒绝',
			'seerr.permissionDenied' => 'Seerr 拒绝了此操作：你的账户不再拥有所需权限',
			'seerr.permissionRevoked' => '你不再拥有请求此内容的权限',
			'services.title' => '服务',
			'services.hubSubtitle' => '同步观看进度并请求新内容。',
			'services.integrations' => '集成',
			'services.notConnected' => '未连接',
			'services.connectedAs' => ({required Object username}) => '已以 @${username} 身份连接',
			'services.scrobble' => '自动记录进度',
			'services.scrobbleDescription' => '观看完一集或一部电影后更新你的列表。',
			'services.disconnectConfirm' => ({required Object service}) => '断开 ${service} 连接？',
			'services.disconnectConfirmBody' => ({required Object service}) => 'PlezyNG 将停止更新 ${service}。可随时重新连接。',
			'services.connectFailed' => ({required Object service}) => '无法连接到 ${service}。请重试。',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => '重新连接 Simkl',
			'services.simklReconnect.subtitle' => 'Simkl 即将停用此连接所使用的登录方式。重新连接将打开 simkl.com 以授权 PlezyNG — PlezyNG 永远不会看到你的密码。你的观看记录仍保留在 Simkl 上。',
			'services.deviceCode.title' => ({required Object service}) => '在 ${service} 上激活 PlezyNG',
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
			'services.libraryFilter.modeDescription' => '选择是阻止已勾选的媒体库同步，还是仅同步已勾选的媒体库。',
			'services.seerrDescription' => '连接到 Seerr 或 Overseerr 以搜索标题并提交媒体请求。',
			'services.trackerDescriptions.trakt' => '与您的 Trakt 帐户同步观看的节目和电影。',
			'services.trackerDescriptions.mal' => '同步动画列表,并通过 MyAnimeList 观看进展。',
			'services.trackerDescriptions.anilist' => '同步动画列表,并与 AniList 观看进展。',
			'services.trackerDescriptions.simkl' => '同步观看电影,电视节目和动画与Simkl。',
			'services.trackerDescriptions.mdblist' => '在推荐和探索中显示 MDBList 评分和列表。',
			'streaming.title' => '云端与插件串流',
			'streaming.subtitle' => '连接 Debrid 账户，即可浏览云端文件并播放受支持的流。兼容 Stremio 的插件会在电影和剧集详情页提供播放选项。连接信息会在此设备上加密，并保存到此个人资料。',
			'streaming.connectionsConfigured' => ({required Object count}) => '已连接的来源：${count}',
			'streaming.settingsLoadFailed' => 'PlezyNG 无法解锁已保存的串流设置。请先解锁设备，再重试后更改连接。',
			'streaming.settingsUnreadable' => 'PlezyNG 无法解锁这些已保存的连接。清除后即可重新连接服务。',
			'streaming.clearUnreadableSettings' => '清除已保存的设置',
			'streaming.clearUnreadableSettingsConfirm' => '清除已保存的串流设置？',
			'streaming.clearUnreadableSettingsBody' => '这会从此个人资料中移除所有已保存的服务商账户和插件地址，且无法撤销。',
			'streaming.clearUnreadableSettingsFailed' => '无法清除已保存的串流设置。请解锁设备后重试。',
			'streaming.retrySettingsLoad' => '重新加载连接',
			'streaming.addons' => '兼容 Stremio 的插件',
			'streaming.addonsDescription' => '从 Stremio 导入插件，或通过清单网址连接插件。在“探索”中浏览目录，并从电影或剧集详情页打开串流选项。',
			'streaming.catalogLoadFailed' => '无法加载此目录。请刷新后重试。',
			'streaming.catalogFiltersRequired' => '选择浏览此目录所需的筛选条件。',
			'streaming.catalogRequiredLabel' => '必填',
			'streaming.importFromStremio' => '从 Stremio 导入',
			'streaming.stremioImportInstructions' => '扫描二维码或打开链接。登录 Stremio 并批准请求。PlezyNG 只会读取你的插件列表，不会索要 Stremio 密码或更改设置。',
			'streaming.stremioImportOpen' => '打开 Stremio 链接',
			'streaming.stremioImportCode' => '关联码',
			'streaming.stremioImportPreviewTitle' => '选择插件',
			'streaming.stremioImportPreviewBody' => '选择要连接到 PlezyNG 的插件。此导入仅接受 HTTPS 地址。',
			'streaming.stremioImportIgnored' => ({required Object count}) => '因地址不受支持或不安全而跳过的插件：${count}。',
			'streaming.stremioCatalogs' => '目录',
			'streaming.stremioStreams' => '串流',
			'streaming.stremioImportAddSelected' => ({required Object count}) => '添加所选项（${count}）',
			'streaming.stremioImportAdded' => ({required Object count}) => '从 Stremio 连接的插件：${count}。',
			'streaming.stremioImportPartial' => ({required Object added, required Object failed}) => '已连接的插件：${added}；未能连接：${failed}。',
			'streaming.stremioImportFailed' => '无法从 Stremio 导入插件。请重试。',
			'streaming.stremioImportTimedOut' => 'Stremio 授权已超时。请重新开始导入。',
			'streaming.stremioImportEmpty' => '此 Stremio 账户中没有找到新的兼容插件。',
			'streaming.stremioImportLimitReached' => '请先移除一个插件，再导入更多插件。',
			'streaming.addByManifestUrl' => '通过清单网址添加',
			'streaming.addAddon' => '添加插件',
			'streaming.manifestUrl' => '插件清单网址',
			'streaming.manifestUrlHint' => '粘贴插件的清单网址。连接前，PlezyNG 会检查其是否支持目录或串流资源。',
			'streaming.allowHttp' => '允许未加密的 HTTP 地址',
			'streaming.allowHttpDescription' => '仅对私人网络中可信任的插件使用。',
			'streaming.installAddon' => '连接插件',
			'streaming.addonInstalled' => '插件已连接',
			'streaming.addonRemoved' => '插件已移除',
			'streaming.addonToggle' => '启用插件',
			'streaming.addonEmpty' => '尚未连接插件',
			'streaming.addonError' => 'PlezyNG 无法连接此插件。请检查清单网址并重试。',
			'streaming.addonPrivacy' => '仅连接你信任的插件。搜索时，插件会收到你要搜索的标题，并可能返回第三方串流链接。',
			'streaming.realDebrid' => 'Real-Debrid',
			'streaming.realDebridDescription' => '通过 Real-Debrid 账户播放受支持的种子流。',
			'streaming.connectRealDebrid' => '使用二维码连接',
			'streaming.disconnectRealDebrid' => '断开 Real-Debrid',
			'streaming.realDebridConnected' => ({required Object username}) => '已连接：${username}',
			'streaming.realDebridInstructions' => '扫描二维码或打开链接，然后输入此激活码以连接 PlezyNG：',
			'streaming.realDebridActivate' => '打开 Real-Debrid 进行激活',
			'streaming.realDebridCode' => '激活码',
			'streaming.realDebridConnectFailed' => '无法连接 Real-Debrid。请重试。',
			'streaming.allDebrid' => 'AllDebrid',
			'streaming.allDebridDescription' => '通过 AllDebrid 账户播放受支持的种子流。',
			'streaming.connectAllDebrid' => '使用二维码连接',
			'streaming.allDebridInstructions' => '扫描二维码或打开链接以授权 PlezyNG。连接期间请保持此页面打开：',
			'streaming.allDebridActivate' => '打开 AllDebrid 进行激活',
			'streaming.allDebridCode' => '激活 PIN 码',
			'streaming.allDebridConnectFailed' => '无法连接 AllDebrid。请重试。',
			'streaming.premiumize' => 'Premiumize',
			'streaming.premiumizeDescription' => '通过 Premiumize 播放已缓存的种子流或浏览文件。',
			'streaming.torbox' => 'TorBox',
			'streaming.torboxDescription' => '通过 TorBox 播放已缓存的种子流或浏览文件。',
			'streaming.connectApiKey' => '使用 API 密钥连接',
			'streaming.apiKeyTitle' => ({required Object service}) => '连接 ${service}',
			'streaming.apiKey' => 'API 密钥',
			'streaming.apiKeyHint' => ({required Object service}) => '粘贴 ${service} 账户设置中的 API 密钥。PlezyNG 会在此设备上加密密钥，并将其保存在此个人资料中。',
			'streaming.apiKeyConnectFailed' => '无法验证此 API 密钥。请检查后重试。',
			'streaming.accountConnected' => ({required Object username}) => '已连接：${username}',
			'streaming.streamNeedsProvider' => '连接 Debrid 服务以播放此种子流。',
			'streaming.playViaProvider' => '通过 Debrid 播放',
			'streaming.disconnectConfirm' => ({required Object service}) => '断开 ${service}？',
			'streaming.disconnectBody' => 'PlezyNG 会移除此设备的授权，不会更改服务商中的文件或正在进行的传输。',
			'streaming.streamsTitle' => '选择串流',
			'streaming.searchingStreams' => '正在检查已连接的插件…',
			'streaming.noStreams' => '未找到此标题的串流。',
			'streaming.manageConnections' => '管理串流服务',
			'streaming.subtitleTracks' => ({required Object count}) => '字幕轨道：${count}',
			'streaming.chooseSubtitle' => '选择字幕',
			'streaming.chooseProvider' => '选择 Debrid 服务',
			'streaming.subtitleOff' => '关闭字幕',
			'streaming.subtitleLoadFailed' => '无法加载此字幕。请尝试其他轨道。',
			'streaming.subtitleApplied' => '已选择播放字幕',
			'streaming.streamLookupPartial' => '部分插件无法访问。',
			'streaming.streamLookupFailed' => '无法检查已连接的插件。',
			'streaming.streamOpenExternal' => '打开外部链接',
			'streaming.streamPrepare' => '正在通过 Debrid 服务准备…',
			'streaming.streamPrepareFailed' => '无法准备此串流。请检查已连接的账户，然后尝试其他来源。',
			'streaming.streamNeedsRealDebrid' => '连接 Debrid 服务以播放此种子流。',
			'streaming.streamUnsupported' => '应用内播放器不支持此串流格式。',
			'streaming.remoteNeedsEpisode' => '请先选择剧集，再搜索串流。',
			'streaming.remoteNeedsEpisodeNumber' => '此剧集缺少季号或集号。',
			'streaming.remoteNeedsExternalId' => 'PlezyNG 找不到此标题的 IMDb 或 TMDB ID。',
			'streaming.watchWithServices' => '通过已连接的服务观看',
			'streaming.chooseEpisode' => '选择剧集',
			'streaming.episodes' => '剧集',
			'streaming.episodePosition' => ({required Object season, required Object episode}) => '第 ${season} 季，第 ${episode} 集',
			'streaming.episodeStreamHint' => '打开此剧集的可用串流。',
			'streaming.cloudFiles' => '云端文件',
			'streaming.browseCloud' => '浏览文件',
			'streaming.cloudEmpty' => '此账户中没有找到可播放的视频文件。',
			'streaming.cloudLoadFailed' => '无法加载云端文件。请检查连接后重试。',
			'streaming.providers' => 'Debrid 服务商',
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
			'addServer.signInWithPlexCardSubtitleScoped' => '授权一个 Plex 账户。Plex Home 用户将成为 PlezyNG 用户资料。',
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
			'addServer.directPlexServerUrl' => 'Plex 服务器 URL',
			'addServer.directPlexServerUrlHelper' => '输入您的 Plex 媒体服务器的本地 IP 和端口。',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex 代币(可选)',
			'addServer.plexTokenHelper' => '放空,如果在此服务器上允许无 auth 访问。',
			'addServer.plexTokenRequired' => '请输入您的 Plex 代币(X-Plex-Token)。',
			'addServer.connectDirectPlexCard' => 'Plex 媒體伺服器(直接/本地)',
			'addServer.connectDirectPlexCardSubtitle' => '直接使用本地IP或URL连接,无需 plex.tv 帐户。',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => '直接使用本地IP或URL连接,连接到${name}。',
			'addServer.insecureTitle' => '未加密的连接',
			'addServer.insecureDescription' => ({required Object url}) => '${url} 使用 HTTP。网络中的其他人可能读取或篡改您的密码、令牌和媒体内容。请尽可能使用 HTTPS。只有在您信任此网络并接受风险时才继续。',
			'addServer.allowHttp' => '允许 HTTP',
			'addServer.httpsRequired' => '使用 HTTPS 或明确允许未加密的连接。',
			'cast.chooseDevice' => '点击一个设备',
			'cast.searching' => '寻找卡片设备',
			'cast.connectedTo' => ({required Object device}) => '连接到 ${device}',
			'cast.device' => '加密装置',
			'cast.readyToCast' => '准备放',
			'cast.subtitle' => '字幕',
			'cast.serverNotAvailable' => '媒体服务器不适用。',
			'cast.stopCasting' => '停止加密',
			'cast.castToDevice' => '点击设备',
			'cast.noEpisodeAvailable' => '没有任何节目可播放。',
			'cast.startFailed' => '无法开始投射,检查服务器并尝试一次。',
			'automation.noActivePlayback' => '没有活跃的视频会话可以控制。',
			'notifications.newEpisodeTitle' => '新集',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appAccess.title' => '每個功能都免費嘗試7天',
			'appAccess.description' => '开始一个七天的试用,完全访问每个PlezyNG功能,在试用期间没有费用,没有订阅,试用后,在您的商店价格上一生购买,终身开锁PlezyNG。',
			'appAccess.trialEndedDescription' => '按商店显示的价格一次性购买，即可终身解锁 PlezyNG 的全部功能，无需订阅。',
			'appAccess.startTrial' => '开始我的7天免费试验',
			'appAccess.trialActive' => '您的7天全功能测试已活跃。',
			'appAccess.trialEnded' => '你的七天审判结束了',
			'appAccess.trialStartFailed' => '我无法在这个设备上保存测试,请再试一次。',
			'appAccess.lifetimeTitle' => 'PlezyNG 终身禁用',
			'appAccess.lifetimeBody' => '感谢!您终身访问所有 PlezyNG 功能。',
			'appAccess.manageTitle' => 'PlezyNG 终身访问',
			'appAccess.manageDescription' => '每個功能都免費嘗試7天,然後用一個付款解锁一生的一切,以您的商店的價格。',
			'appAccess.buy' => ({required Object price}) => '解锁所有功能为 ${price}',
			'appAccess.loadingPrice' => '货物价格...',
			'appAccess.retryPrice' => '回报价格 查看',
			'appAccess.restore' => '恢复终身购买',
			'appAccess.pending' => '您的购买正在等待付款或批准。商店完成交易后，终身使用权限将立即解锁。',
			'appAccess.storeUnavailable' => '目前无法购买。请确认您已登录商店，且此设备允许购买。',
			'appAccess.productNotFound' => 'PlezyNG 终身解锁 目前尚未在本商店提供。',
			'appAccess.productQueryFailed' => '无法收取商店价格,请检查您的连接并尝试一次。',
			'appAccess.purchaseFailed' => '購買不錯了,再試一次。',
			'appAccess.restoreFailed' => '无法到达商店恢复您的购买,再试一次。',
			'appAccess.nothingToRestore' => '已找到第 PlezyNG 终身购买号,用于此商店帐户。',
			'detail.endsAt' => ({required Object time}) => '结束时间：${time}',
			'watchLink.serverUnavailable' => '无法访问 Plex 服务器此链接。',
			'watchLink.notFound' => '我无法在您的服务器上找到此节目或电影 Plex。',
			'watchLink.ambiguous' => '此链接匹配多个服务器上的项目,并将服务器添加到链接中。',
			'watchLink.plexOnly' => '目前仅支持 Plex 服务器的观看链接。',
			'watchLink.unsupportedItem' => '观看链接只能打开一个节目或电影。',
			'watchLink.menuItem' => '查看链接',
			'watchLink.dialogTitle' => '查看链接',
			'watchLink.dialogShowHint' => '打开此链接播放下一个节目. 添加 &mode=shuffle 到结尾播放节目在 shuffle 上。',
			'watchLink.dialogMovieHint' => '打开这个链接播放电影。',
			'watchLink.copy' => '复制',
			'watchLink.copied' => '链接复制',
			'homeLayout.title' => 'Home 布局',
			'homeLayout.resetToast' => '主页重新设置到原始Plezy英雄配置',
			'homeLayout.resetHeroTitle' => '重定向英雄配置到存储Plezy?',
			'homeLayout.resetHeroBody' => '关闭所有内容行的焦点横幅设置，并恢复首页顶部的单个轮播横幅，如同引入焦点横幅行之前的布局。内容行的顺序和显示状态不受影响。',
			'homeLayout.removeRowTitle' => '取消家居序列?',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} 将被删除,此不能被删除。',
			'homeLayout.sync' => '同步',
			'homeLayout.syncAccountTitle' => '与您的 Plex 帐户同步配置',
			'homeLayout.syncAccountOn' => '开启：此设备会与您的其他设备共享内容行顺序、内容行、焦点横幅和自动轮播设置。',
			'homeLayout.syncAccountOff' => '关闭:此设备保持其自己的配置。',
			'homeLayout.syncNow' => '现在的Sync',
			'homeLayout.plexHomeManager' => 'Plex 主持人',
			'homeLayout.managePlexRows' => '管理 Plex 行在 Plezy',
			'homeLayout.managePlexRowsDescription' => '开放组织主选行列',
			'homeLayout.organizeHomeRows' => '安排家居行',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} 行: 移动, 英雄, 自动滑动, 移除',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => '组织 ${library} 行',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => '继续观看 + ${n} 行: 移动, 图书馆, 家, 英雄, 自动滑板',
			'homeLayout.renderAsHero' => '显示为焦点横幅',
			'homeLayout.heroOnlySingleCollection' => '只有当此行解决到单一集合的实际标题时才可用',
			'homeLayout.hero' => '焦点横幅',
			'homeLayout.autoSlide' => '自动轮播',
			'homeLayout.autoSlideDescription' => '每隔几秒也会自动切换。电脑上的箭头按钮和电视遥控器的方向键始终可用，使用后会重新开始计时。',
			'homeLayout.autoSlideEditDescription' => '每隔几秒也会自动切换。关闭时，仅在点击电脑上的箭头按钮或按电视遥控器的左右方向键时切换。无论此设置是否开启，箭头按钮和方向键都可用。',
			'homeLayout.enableHeroFirst' => '英雄第一',
			'homeLayout.showOnHome' => '显示在主屏幕上',
			'homeLayout.home' => '首页',
			'homeLayout.removeFromHome' => '离开家',
			'homeLayout.selectRowsFirst' => '首先,选择下面的主行。',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} Plex 管理行',
			'homeLayout.continueWatching' => '继续观看',
			'homeLayout.continueWatchingLibraryDescription' => '图书馆的本质重建进展顺序',
			'homeLayout.continueWatchingHomeDescription' => '重新进展序列显示在家',
			'homeLayout.nextUpHomeDescription' => '下一篇 未观看的集合序列在主页上单独显示',
			'homeLayout.library' => '媒体库',
			'homeLayout.showInRecommended' => '图书馆推荐',
			'homeLayout.customPlexRow' => '定制 Plex 行',
			'homeLayout.heroNeedsLibrary' => '查看图书馆首先 - 英雄需要在某处展示',
			'homeLayout.heroNeedsSurface' => '查看图书馆或家先 - 英雄需要在某处展示',
			'homeLayout.removeHub' => '取消 Hub',
			'homeLayout.noPlexRows' => '第Plex号管理行返回此图书馆。',
			'homeLayout.openDetails' => '开放细节',
			'homeLayout.heroCards' => '英雄卡',
			'homeLayout.tapHeroCard' => '打破英雄卡',
			'homeLayout.tvPlayFocus' => '电视远程:突出点击播放按钮',
			'homeLayout.tvPlayFocusDescription' => '按方向键下键时，焦点会先停在播放按钮上，再移到下一行。关闭时会直接跳到下一行。',
			'homeLayout.tvWrap' => '电视远程: loop 英雄卡',
			'homeLayout.tvWrapDescription' => '在最后一张卡片上按右键会回到第一张；关闭时则停在最后一张。在第一张卡片上按左键始终会进入侧边栏。',
			'homeLayout.castOnHero' => '在焦点横幅上显示演员',
			'homeLayout.castOnHeroDescription' => '在焦点横幅底部显示演员列表。关闭时仅保留标题和简介。',
			'homeLayout.customRows' => '定位线',
			'homeLayout.loading' => '家用布局...',
			'homeLayout.noCustomRows' => '尚未有定位',
			'homeLayout.addRowHint' => '使用添加主行创建一个。',
			'homeLayout.addHomeRow' => '添加 Home Rue',
			'homeLayout.addHomeRowDescription' => '选择类别;新行将自动添加到组织者',
			'homeLayout.removeRow' => '取消行列',
			'homeLayout.recentlyAdded' => '最近添加',
			'homeLayout.recentlyReleased' => '最近发布',
			'homeLayout.movieCollections' => '电影收藏',
			'homeLayout.showCollections' => '展示集合',
			'homeLayout.rowTitle' => '路 标题',
			'homeLayout.content' => '内容',
			'homeLayout.showThisRowIn' => '显示此行在:',
			'homeLayout.libraryRecommended' => '推荐图书馆',
			'homeLayout.heroCard' => '英雄卡',
			'homeLayout.heroCardDescription' => '显示为一个全宽旋转卡,而不是海报架。',
			'homeLayout.heroUnavailableDescription' => '仅当此内容行展示单个合集中的具体媒体条目时才可用；选择多个合集时，没有可供轮播的单个媒体条目。',
			'homeLayout.librariesSelection' => '图书馆(所有未经检查的图书馆都包含)',
			'homeLayout.librariesMergedDescription' => '这里查看的每一个图书馆都合并到这个单一的行列。',
			'homeLayout.movieCollectionsSelection' => '电影收藏(每个选择的图书馆都没有查看)',
			'homeLayout.showCollectionsSelection' => '显示收藏品(每个选择的图书馆都没有查看)',
			'homeLayout.collectionRowsDescription' => '如果一个集合相匹配,其标题直接在序列中显示;如果一个集合多,每个集合都显示为单一的海报,则点击它以打开该集合。',
			'homeLayout.allCollections' => '所有收藏',
			'homeLayout.noRowsHere' => '目前还没有线条。',
			'homeLayout.hideWatchedRows' => '隐藏在行列中观看的物品',
			'homeLayout.hideWatchedRowsDescription' => '已看完的媒体条目会从首页和媒体库的推荐行中移除，尚未看完的条目会保留。',
			'homeLayout.untitledCollection' => '未经标题收藏',
			'homeLayout.moveRowHint' => '向上/下: 移动行 · 选择: 将此处放下 · 返回: 取消',
			'homeLayout.organizeRowsHint' => '选择行(或保持):移动 · 左/右:行选项 · 返回:完成',
			'homeLayout.layoutNavDescription' => '选择行、图书馆和收藏类别',
			'homeLayout.editHomeRow' => '编辑 主页 序列',
			'homeLayout.resetHeroButton' => '恢复 Plezy 默认焦点横幅布局',
			'homeLayout.reorderingUnlocked' => '重新排序 开锁',
			'homeLayout.reorderingLocked' => '重新安排锁',
			'homeLayout.rowsCanBeDragged' => '可以拖绳 - 点击锁,以防止',
			'homeLayout.tapLockToDrag' => '点击锁,拖行列',
			'homeLayout.customRowLabel' => ({required Object title}) => '定位: ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => '隐藏',
			'homeLayout.remove' => '移除',
			'homeLayout.libraryResumeRow' => '图书馆的重复顺序',
			'homeLayout.pressAgainToDelete' => '再次按下删除',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => '到',
			'homeLayout.resetHeroButtonDescription' => '关闭所有内容行的焦点横幅设置，并恢复顶部的单个轮播横幅，如同引入焦点横幅行之前的布局。内容行顺序保持不变。',
			'homeLayout.tapHeroCardDescription' => '选择打字或选择一个英雄卡是否开始播放,或者打开它的细节。',
			'homeLayout.heroTapPlayDescription' => '立即启动所选择的项目。',
			'homeLayout.heroTapDetailsDescription' => '在选择行动之前,打开所选项目的详细信息。',
			'platform.localNetworkPermission' => 'PlezyNG 会连接到您本地网络中的媒体服务器和播放设备。',
			'platform.locationPermission' => '当 iOS 要求提供位置权限才能检测本地网络并连接媒体服务器时，PlezyNG 会使用此权限。',
			'platform.photoLibraryPermission' => '从照片图库中选择图片，用作媒体封面等图像。',
			'platform.cameraPermission' => '扫描二维码以配对 Companion Remote。',
			'universalMedia.title' => '开放媒体',
			'universalMedia.shortcutHelp' => '播放此会议的链接、播放列表或文件。',
			'universalMedia.intro' => '打开链接、播放列表或文件 Playback 使用 PlezyNG 的标准播放器,并且不会将历史添加到您的图书馆。',
			'universalMedia.openWhat' => '你想打开什么?',
			'universalMedia.stream' => '流地址',
			'universalMedia.playlist' => '播放列表',
			'universalMedia.files' => '设备文件',
			'universalMedia.favorites' => '保存流喜爱',
			'universalMedia.address' => '媒體地址',
			'universalMedia.addressHelp' => 'HTTPS 是优先的. 有认可或签名参数的 URL 仅用于此会议,并且不能保存为喜爱。',
			'universalMedia.displayName' => '显示名称(可选)',
			'universalMedia.displayNameHelp' => '选择玩家和系统媒体控制器的简称。',
			'universalMedia.allowHttp' => '允许未加密的 HTTP 连接',
			'universalMedia.allowHttpHelp' => 'HTTP 不加密连接. 只允许它在可靠的网络上. 当可能时使用 HTTPS。',
			'universalMedia.advancedProtocols' => 'MPV 仅:输入 RTSP、RTMP/RTMPS、UDP 或 RTP 地址,这些地址不能保存为最受欢迎的。',
			'universalMedia.liveStream' => '作为活着的待遇',
			'universalMedia.liveStreamHelp' => '使用此用于直播视频或广播电台. 该应用程序隐藏了时间栏,滑动按钮和 go-to-time 选项。',
			'universalMedia.privateSession' => '只有此播放使用地址. 保存一个合格流最喜欢的,以保持它在这个个人资料。',
			'universalMedia.saveFavorite' => '保存最喜欢',
			'universalMedia.playNow' => '现在玩',
			'universalMedia.favoriteSaved' => '流喜爱保存到此个人资料',
			'universalMedia.skippedEntries' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '${count} 不受支持或不安全的播放列表输入。', other: '${count} 不受支持或不安全的播放列表输入。', ), 
			'universalMedia.playlistAddress' => 'Playlist 地址',
			'universalMedia.playlistAddressHelp' => '從網頁地址開啟 M3U、M3U8 或 PLS 播放列表. Direct Stream 連結不會保存播放名單。',
			'universalMedia.choosePlaylist' => '选择 Playlist 文件',
			'universalMedia.openPlaylist' => '开放播放列表',
			'universalMedia.playlistFormatsHelp' => '一张播放列表可以包含最多1000个项目和2MB的HLS显示为流,所以玩家可以选择质量。',
			'universalMedia.noFavorites' => '尚未存储流喜爱. 喜爱留在此个人资料中。',
			'universalMedia.removeFavorite' => '删除流喜爱',
			'universalMedia.filesHelp' => '选择音频、视频或ISO文件,以便进行临时记录. 文件和URL不添加到图书馆历史。',
			'universalMedia.chooseFiles' => '选择文件',
			'universalMedia.fileQueue' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '1 选择的文件', other: '${count} 已选择的文件', ), 
			'universalMedia.wifiTransfer' => '通过 Wi-Fi 发送文件',
			'universalMedia.wifiTransferHelp' => '从同一信任网络的浏览器传输支持的文件。',
			'universalMedia.wifiTransferIntro' => '在另一个设备上的浏览器中打开此地址. 选择文件以将其添加到该设备的文件和书籍图书馆。',
			'universalMedia.wifiTransferPrivacy' => '本设备通过您的本地网络接收文件. 任何知道此地址的人都可以发送文件,直到您停止传输或地址在15分钟后终止。',
			'universalMedia.wifiTransferStarting' => '准备一个私人,时间有限的转会...',
			'universalMedia.wifiTransferUnavailable' => '无法启动转换,检查本地网络接入并尝试一次。',
			'universalMedia.openThisAddress' => '在发送设备上打开其中一个地址',
			'universalMedia.copyAddress' => '传输地址复制',
			'universalMedia.addressCopied' => '传输地址复制',
			'universalMedia.transferExpires' => ({required Object time}) => '此地址在 ${time} 中终止。',
			'universalMedia.uploadCount' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '${count} 获取文件', other: '${count} 收到的文件', ), 
			'universalMedia.uploadedData' => ({required Object size}) => '接收 ${size}',
			'universalMedia.stopTransfer' => '停止转让和取消地址',
			'universalMedia.startTransfer' => '转移开始',
			'universalMedia.wifiImportedFiles' => 'Wi-Fi 传输',
			'universalMedia.wifiBrowserTitle' => '向 PlezyNG 发送文件',
			'universalMedia.wifiBrowserIntro' => '选择音频、视频、电子书或漫画文件发送. 这些文件存储在该设备的文件和书籍库中. 最多: 100 个文件,每个文件 4 GiB,总共 10 GiB。',
			'universalMedia.uploadFilesLabel' => '文件发送',
			'universalMedia.uploadSelected' => '下载所选择的文件',
			'universalMedia.uploadSelectFirst' => '首先选择一个或多个文件。',
			'universalMedia.uploading' => '发送',
			'universalMedia.uploadComplete' => '文件添加到 PlezyNG。',
			'universalMedia.uploadFailed' => '文件无法添加,请保持此页面开放并再次尝试。',
			'universalMedia.liveCue' => '生活',
			'universalMedia.liveSession' => '直播流',
			'universalMedia.liveCueHelp' => '对于直播视频或无线电,应用程序隐藏了时间栏和跳跃按钮,它不会保存地址或观看历史。',
			'universalMedia.sessionOnly' => '此播放仅是会话',
			'universalMedia.sessionOnlyHelp' => 'Playback 永远不会保存进展或历史. 如果有资格,请将流作为最受欢迎的存储在此个人资料中。',
			'universalMedia.pictureAdjustments' => '图像调整',
			'universalMedia.pictureHelp' => '这些图像变更只影响此播放,它们在播放结束时重新设置。',
			'universalMedia.resetPicture' => '重新设置图像',
			'universalMedia.brightness' => '光明',
			'universalMedia.contrast' => '矛盾',
			'universalMedia.gamma' => '加姆',
			'universalMedia.hue' => '胡子',
			_ => null,
		} ?? switch (path) {
			'universalMedia.saturation' => '土星',
			'universalMedia.view360' => '平板视图360度视频',
			'universalMedia.view360Help' => 'MPV 需要 FFmpeg 的 v360 过滤器来查看此视图。',
			'universalMedia.view360Unavailable' => '这个MPV构建不能应用360度过滤器。',
			'universalMedia.view360Yaw' => '地平线视野',
			'universalMedia.view360Pitch' => '垂直视野',
			'universalMedia.view360FieldOfView' => '视野领域',
			'universalMedia.recordStream' => '记录直播',
			'universalMedia.stopRecording' => '停止和保存录制',
			'universalMedia.recordingStarted' => '记录是活跃的,让播放停止并保存录制。',
			'universalMedia.recordingSaved' => '录制完成并保存。',
			'universalMedia.recordingActive' => '放弃播放停止并保存它。',
			'universalMedia.recordingFormatHelp' => '对于视频,选择 MKV 或 MPEG-TS. 为音频,选择 MKA 或 MKV。',
			'universalMedia.replaceRecordingTitle' => '取代这张录音?',
			'universalMedia.replaceRecordingHelp' => 'PlezyNG 在录制时备份现有文件;如果无法保存新录制,PlezyNG 将备份恢复。',
			'universalMedia.replaceRecording' => '替换文件',
			'universalMedia.discHelp' => '在此计算机的光学驱动器中打开磁盘,您也可以从设备文件中打开ISO图像。',
			'universalMedia.discs' => '光学磁盘',
			'universalMedia.dvd' => 'DVD',
			'universalMedia.bluray' => '蓝光',
			'universalMedia.audioCd' => '音频CD',
			'universalMedia.discAvailability' => '磁盘播放需要兼容的MPV构建、支持的驱动器和操作系统许可,不能超越商业磁盘保护。',
			'universalMedia.converterTitle' => '转换本地媒体文件',
			'universalMedia.converterHelp' => '使用 FFmpeg 创建 MP4, M4A 或 MP3 副本。',
			'universalMedia.converterIntro' => '将本地音频或视频文件转换为多个设备上运行的格式。',
			'universalMedia.converterPrivacy' => 'FFmpeg 必须安装在此计算机上. 转换只读取本地文件. 不下载流或删除 DRM。',
			'universalMedia.converterChooseInput' => '选择本地媒体文件',
			'universalMedia.converterFormat' => '输出格式',
			'universalMedia.converterMp4' => 'MP4 · H.264 和 AAC',
			'universalMedia.converterM4a' => 'M4A · AAC 音频',
			'universalMedia.converterMp3' => 'MP3 · 音频',
			'universalMedia.converterSaveAs' => '保存转换的媒体作为',
			'universalMedia.converterExtensionMismatch' => '选择与所选输出扩展的文件名。',
			'universalMedia.converterUnsupportedInput' => '选择音频或视频文件。',
			'universalMedia.converterLocalOnly' => '所选择的文件不作为本地设备路径可用。',
			'universalMedia.converterReplaceTitle' => '取代此文件?',
			'universalMedia.converterReplaceHelp' => 'PlezyNG 恢复现有文件,直到转换的副本被保存。',
			'universalMedia.converterStarting' => '開始 FFmpeg...',
			'universalMedia.converterProgress' => '转换到这个计算机......',
			'universalMedia.converterComplete' => '转换完成,新文件已准备好。',
			'universalMedia.converterFfmpegMissing' => 'FFmpeg 无法找到所需的编码器. 使用 H.264, AAC 和 MP3 支持安装 FFmpEG,然后再次尝试。',
			'universalMedia.converterFailed' => '转换失败:检查源文件可以阅读,目的地有足够的免费空间。',
			'universalMedia.converterCancelled' => '转换取消了,不完整的输出被删除。',
			'universalMedia.converterDesktopOnly' => '本地转换可在桌面计算机上使用 FFmpeg 安装。',
			'universalMedia.converterStart' => '转换文件',
			'universalMedia.mediaToolsTitle' => '媒體工具',
			'universalMedia.mediaToolsShortcut' => '捕获或共享媒体,添加搜索扩展或使用命令行。',
			'universalMedia.mediaToolsIntro' => '选择一个专注的工具. 捕获和流出使用 FFmpeg 安装在这个桌面上. 扩展和 CLI 命令使用有限的 HTTPS 请求和现有 Open media 流。',
			'universalMedia.mediaToolsAccessibility' => '工具选项和控制器与触摸、指标、键盘和D-pad焦点工作。 录制、共享和搜索状态的变化被公布。',
			'universalMedia.mediaTool' => '媒體工具',
			'universalMedia.captureIntro' => '在此计算机上记录屏幕或相机到 MP4 文件. FFmpeg 必须安装并包含 H.264 编码器。',
			'universalMedia.captureNoDevices' => '没有屏幕或相机被发现 查看 FFmpeg 捕捉支持和操作系统隐私许可证。',
			'universalMedia.captureSource' => '屏幕或相机',
			'universalMedia.captureScreen' => '屏幕',
			'universalMedia.captureAudioSource' => '音频输入(可选)',
			'universalMedia.captureAudioHelp' => '添加来自微型或可用的输入的音频 设备选项取决于 FFmpeg 和系统许可。',
			'universalMedia.captureAudioNone' => '没有音频',
			'universalMedia.captureDefaultAudio' => '默认音频输入',
			'universalMedia.captureWaylandHelp' => 'Wayland 限制此 XWayland 捕获到 X display. XWayland 以外的 Windows 可能不会出现。',
			'universalMedia.captureFrameRate' => '记录框率',
			'universalMedia.capturePrivacy' => '录制仅存储到您选择的文件。 微型录制是可选的. PlezyNG 不会上传录制。',
			'universalMedia.captureSaveAs' => '保存屏幕录制如',
			'universalMedia.captureExtensionMismatch' => '在 .mp4 中选择终端的文件名。',
			'universalMedia.captureFfmpegMissing' => 'FFmpeg 或 H.264 视频编码器不适用. 安装支持的 FFmpeg 构建,然后再次尝试。',
			'universalMedia.captureFailed' => '记录无法保存 检查设备许可、可用的存储和 FFmpeg 支持。',
			'universalMedia.captureSaved' => '屏幕录制保存',
			'universalMedia.captureElapsedLabel' => '录制时间',
			'universalMedia.captureStart' => '开始录制',
			'universalMedia.captureStop' => '停止和拯救',
			'universalMedia.captureMode' => '捕捉',
			'universalMedia.shareMode' => '分享',
			'universalMedia.shareIntro' => '将本地媒体文件发送到您的私人网络上的另一个设备. PlezyNG 创建一个暂时的 HLS 流。',
			'universalMedia.sharePrivacy' => '您的本地网络的任何人,谁接收私人链接可以观看,而它是活跃的. 链接结束后60分钟. 停止共享,关闭服务器并取消链接。',
			'universalMedia.shareChooseFile' => '选择媒体文件',
			'universalMedia.shareChooseHelp' => '选择一个本地的音频或视频文件. 该文件留在此计算机上。',
			'universalMedia.shareFfmpegMissing' => 'FFmpeg 或 H.264/AAC 编码器不适用. 安装 FFmpeg 与 H.264 和 AAC 编码支持。',
			'universalMedia.shareFailed' => '流量无法意外地开始或停止。 查看 FFmpeg 和网络访问。',
			'universalMedia.shareActive' => '流在您的私人网络上已经准备好了。',
			'universalMedia.shareEnded' => '媒體已經到達了結局,並且不再被分享。',
			'universalMedia.shareStopped' => '分享停止了,暂时链接不再有效。',
			'universalMedia.shareUrlCopied' => '流地址复制。',
			'universalMedia.shareOpenUrl' => '在另一台设备上的一个播放器中打开此地址',
			'universalMedia.shareQrLabel' => '临时流地址的QR代码',
			'universalMedia.shareQrHelp' => '扫描与同一私人网络连接的兼容播放器。',
			'universalMedia.shareHttpHint' => '此流使用未加密的 HTTP. 在 PlezyNG 中,允许 HTTP 在打开它之前。',
			'universalMedia.shareCopyUrl' => '复制流地址',
			'universalMedia.shareExpiresLabel' => '链接终止',
			'universalMedia.shareStarting' => '准备流...',
			'universalMedia.shareStart' => '开始分享',
			'universalMedia.shareStop' => '停止分享',
			'universalMedia.extensionsMode' => '扩展和CLI',
			'universalMedia.extensionsIntro' => '添加一个数据仅搜索扩展,以找到媒体. 选择一个结果,将其加载到熟悉的 Open media 表格。',
			'universalMedia.extensionsPrivacy' => '一个显明可以定义一个 HTTPS 搜索终点和地图响应字段. 它不能运行代码,添加请求标题,阅读文件,或启动盾牌命令。',
			'universalMedia.extensionImport' => '添加扩展显明',
			'universalMedia.extensionEmpty' => '尚未搜索服务. 选择一个可靠的显明 JSON 文件添加一个。',
			'universalMedia.extensionChoose' => '搜索服务',
			'universalMedia.extensionSearchConsent' => '每个搜索都会发送您的单词到这个 HTTPS 服务. 结果仅在您选择一个后打开。',
			'universalMedia.extensionSearchLabel' => '搜索媒体',
			'universalMedia.extensionSearch' => '搜索',
			'universalMedia.extensionSearching' => '寻找...',
			'universalMedia.extensionNoResults' => '没有安全的媒体结果返回,请尝试另一个搜索。',
			'universalMedia.extensionInstallTitle' => '添加此搜索服务?',
			'universalMedia.extensionReplaceTitle' => '更新此搜索服务?',
			'universalMedia.extensionService' => '服务',
			'universalMedia.extensionEndpoint' => 'HTTPS 终点',
			'universalMedia.extensionConsent' => '您的搜索文本被发送到此服务. 该示文稿不包含执行代码. 继续只有如果你信任这个终点。',
			'universalMedia.extensionInstall' => '添加服务',
			'universalMedia.extensionReplace' => '更新服务',
			'universalMedia.extensionRemoveTitle' => '删除此搜索服务?',
			'universalMedia.extensionRemoveHelp' => '这将取消该服务从此个人资料中. PlezyNG 不联系其终点。',
			'universalMedia.extensionRemove' => '取消服务',
			'universalMedia.extensionInvalidManifest' => '此文件不是一个支持的扩展显而易见. 查看 Open media 格式指南。',
			'universalMedia.extensionSaveFailed' => '该扩展无法存储到活跃的个人资料。',
			'universalMedia.extensionSearchFailed' => '搜索服务没有返回有效的答案 检查终点并尝试一次。',
			'universalMedia.cliTitle' => '命令线',
			'universalMedia.cliHelp' => '使用 plezyctl 指南来验证一个显明或搜索相同的扩展. 每次搜索之前,查看 HTTPS 服务. 结果在现有媒体格式中打开; 选择播放按钮开始。',
			'universalMedia.cliCopyExample' => '复制命令示例',
			'universalMedia.cliCopied' => '命令例子复制',
			'fileSources.title' => '文件和书籍',
			'fileSources.subtitle' => '阅读、听、从自己的文件中观看。',
			'fileSources.add' => '添加源',
			'fileSources.importFiles' => '进口文件',
			'fileSources.localFiles' => '在此设备上',
			'fileSources.source' => '源',
			'fileSources.name' => '名称',
			'fileSources.endpoint' => '服务器 URL',
			'fileSources.smbEndpointHint' => '示例：smb://nas/Movies',
			'fileSources.smbEndpointInvalid' => '请输入 SMB 服务器和一个共享文件夹。',
			'fileSources.root' => '文件夹或前缀',
			'fileSources.smbFolderHelp' => '留空以使用整个共享文件夹，或输入其中的某个文件夹。',
			'fileSources.username' => '用户名',
			'fileSources.smbDomain' => '域（可选）',
			'fileSources.password' => '密码',
			'fileSources.token' => 'API 标志',
			'fileSources.accessKey' => '关键 ID 访问',
			'fileSources.secretKey' => '秘密访问密钥',
			'fileSources.sessionToken' => '會議代碼(可選)',
			'fileSources.region' => '区域',
			'fileSources.clientId' => '客戶 ID',
			'fileSources.clientSecret' => 'OAuth 客户端秘密(仅限 Google 桌面)',
			'fileSources.allowHttp' => '允许在可信网络上使用未加密的 HTTP',
			'fileSources.smbEncryption' => '加密 SMB3 连接',
			'fileSources.smbEncryptionHint' => '当 NAS 支持时，使用 SMB3 加密。',
			'fileSources.connect' => '连接',
			'fileSources.cancel' => '取消',
			'fileSources.save' => '保存',
			'fileSources.close' => '关闭',
			'fileSources.removeSource' => '连接源',
			'fileSources.disconnectMessage' => '要断开此来源的连接吗？已下载的文件以及阅读和收听历史将保留在此设备上。',
			'fileSources.localFolder' => '选择文件夹',
			'fileSources.empty' => '这里还什么都没有',
			'fileSources.emptyHint' => '添加来源，或导入书籍、有声书、音乐或视频。',
			'fileSources.search' => '搜索此文件夹',
			'fileSources.searchCached' => '搜索 保存图书馆',
			'fileSources.refresh' => '刷新',
			'fileSources.loadMore' => '加载更多',
			'fileSources.offline' => '可用 offline',
			'fileSources.download' => '保持离线',
			'fileSources.removeDownload' => '删除非线复印件',
			'fileSources.continueReading' => '继续阅读',
			'fileSources.continueListening' => '继续听',
			'fileSources.continueWatching' => '继续观看',
			'fileSources.read' => '阅读',
			'fileSources.listen' => '听',
			'fileSources.play' => '播放',
			'fileSources.pause' => '暂停',
			'fileSources.stop' => '停止',
			'fileSources.startOver' => '开始过',
			'fileSources.finished' => '已播放完毕',
			'fileSources.markFinished' => '马克结束了',
			'fileSources.markUnfinished' => '马克 未完成',
			'fileSources.editions' => '版和文件',
			'fileSources.chapters' => '章节',
			'fileSources.bookmarks' => '书标和笔记',
			'fileSources.bookmark' => '添加 Bookmark',
			'fileSources.highlight' => '突出',
			'fileSources.note' => '注目',
			'fileSources.delete' => '删除',
			'fileSources.export' => '出口笔记',
			'fileSources.exported' => '出口的笔记',
			'fileSources.sync' => '同步进展',
			'fileSources.synced' => '进展合成',
			'fileSources.conflict' => '另一个设备有不同的位置,选择去哪里。',
			'fileSources.useLocal' => '使用此设备',
			'fileSources.useRemote' => '使用其他设备',
			'fileSources.history' => '位置历史',
			'fileSources.groupAudio' => '听作一本音频书',
			'fileSources.groupHint' => '将目前在此文件夹中加载的音频文件结合起来. 首先加载所有页面。',
			'fileSources.order' => '文件命令',
			'fileSources.moveUp' => '移动上',
			'fileSources.moveDown' => '移动下',
			'fileSources.speed' => '播放速度',
			'fileSources.sleep' => '睡眠定时器',
			'fileSources.sleepOff' => '关闭',
			'fileSources.endChapter' => '章节的结尾',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(count, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)}分钟', ), 
			'fileSources.skipBack' => '滑落回',
			'fileSources.skipForward' => '滑向前',
			'fileSources.smartRewind' => '休假后智能回归',
			'fileSources.playbackOptions' => '听力选项',
			'fileSources.remaining' => ({required Object time}) => '${time} 剩余',
			'fileSources.contents' => '内容',
			'fileSources.readerSettings' => '阅读设置',
			'fileSources.fontSize' => '文本大小',
			'fileSources.lineHeight' => '线路空间',
			'fileSources.margin' => '马格林',
			'fileSources.font' => '型号',
			'fileSources.serif' => '衬线字体',
			'fileSources.sans' => '无衬线字体',
			'fileSources.mono' => '等宽字体',
			'fileSources.columns' => '列',
			'fileSources.scroll' => '垂直滑动',
			'fileSources.justify' => '两端对齐',
			'fileSources.readerTheme' => '页面外观',
			'fileSources.appTheme' => '跟随应用主题',
			'fileSources.paper' => '纸张',
			'fileSources.sepia' => '塞比亚',
			'fileSources.night' => '夜晚',
			'fileSources.readAloud' => '朗读此页',
			'fileSources.readAlong' => '跟读',
			'fileSources.stopReading' => '停止朗读',
			'fileSources.searchBook' => '搜索书中',
			'fileSources.noMatches' => '没有比赛',
			'fileSources.previousPage' => '上一页',
			'fileSources.nextPage' => '下一页',
			'fileSources.page' => ({required Object number}) => '页面 ${number}',
			'fileSources.externalBlocked' => '阅读器中已禁用书籍的外部链接。',
			'fileSources.loading' => '开...',
			'fileSources.narrator' => '讲话者',
			'fileSources.audio' => '音频',
			'fileSources.video' => '视频',
			'fileSources.ebooks' => '电子书',
			'fileSources.all' => '全部',
			'fileSources.downloads' => '非线文件',
			'fileSources.confirmDelete' => '要删除所选的离线副本吗？阅读或收听进度和笔记将会保留。',
			'fileSources.errorAuthentication' => '再登录,重新连接这个来源。',
			'fileSources.errorPermission' => '此源未允许访问所要求的文件。',
			'fileSources.errorUnavailable' => '源不可用 再试一次,或者打开一个离线副本。',
			'fileSources.errorUnsupported' => '此设备不支持该格式或连接方式。请查看来源设置指南。',
			'fileSources.errorInvalidData' => '此文件或服务器回复无法安全地阅读。',
			'fileSources.errorCancelled' => '行动被取消了。',
			'fileSources.errorConflict' => '阅读或收听位置已在另一个会话中改变。请重新打开项目，选择要使用的位置。',
			'fileSources.signIn' => '登录',
			'fileSources.reconnect' => '重新连接',
			'fileSources.folderHelp' => '留空可从来源根目录开始。S3 URL 包含存储桶名称。',
			'fileSources.preferences' => '偏好',
			'fileSources.timePosition' => '位置',
			'fileSources.audioTrack' => '音频轨道',
			'fileSources.subtitleTrack' => '标题 轨道',
			'fileSources.none' => '无',
			'fileSources.fullscreen' => '全屏幕',
			'fileSources.syncLocation' => '进展同步文件夹(可选)',
			'fileSources.syncLocationHint' => '用于保存 PlezyNG 状态的专用 WebDAV 文件夹。采用条件写入，不会更改媒体文件。',
			'fileSources.audiobooks' => '音频书籍',
			'fileSources.comics' => '漫画',
			'fileSources.scan' => '扫描书籍和媒体',
			'fileSources.browserReader' => '开放读者',
			'fileSources.browserReaderHelp' => '阅读器在您的浏览器中开放. 保持 PlezyNG 开放,以保存您的位置和笔记。',
			'fileSources.on' => '到',
			'fileSources.advancedSetup' => 'App 登记',
			'fileSources.microsoftSignIn' => '与Microsoft登录',
			'fileSources.zoomIn' => '放大',
			'fileSources.zoomOut' => '出Zoom',
			'fileSources.fitPage' => '合适页面',
			'fileSources.fitWidth' => '合适的宽度',
			'fileSources.actualSize' => '目前大小',
			'fileSources.goToPage' => '去页面',
			'fileSources.goToSection' => '去章节',
			'fileSources.pageRange' => ({required Object count}) => '输入 1 到 ${count} 的数字',
			'fileSources.pageLayout' => '页面Layout',
			'fileSources.automatic' => '自动',
			'fileSources.singlePage' => '单页',
			'fileSources.twoPages' => '二页',
			'fileSources.readingDirection' => '阅读方向',
			'fileSources.leftToRight' => '左向右',
			'fileSources.rightToLeft' => '从右到左',
			'fileSources.letterSpacing' => '信 空间',
			'fileSources.wordSpacing' => '字 空间',
			'fileSources.readerControlsHelp' => '双指张开或使用缩放控件放大页面，拖动可平移页面。按 Ctrl/⌘ 与 + 或 − 调整缩放，按 Ctrl/⌘ 与 0 重置缩放。使用 Page Up 和 Page Down 翻页。',
			'fileSources.imagePage' => '漫画页面',
			'fileSources.resetReader' => '重新设置阅读偏好',
			'fileSources.zoom' => '缩放',
			'fileSources.useFiles' => '使用文件和书籍',
			'fileSources.cancelScan' => '取消扫描',
			'fileSources.googleDrive' => 'Google Drive',
			'fileSources.offlineQuota' => '离线下载限制',
			'fileSources.offlineQuotaHelp' => '设置离线副本、导入文件和排队中下载占用的最大空间。降低上限不会删除现有副本。',
			'fileSources.offlineStorageUsage' => '非线存储',
			'fileSources.reservedStorage' => '保留',
			'fileSources.downloadQueue' => '下载Queue',
			'fileSources.downloadRunning' => '下载',
			'fileSources.downloadQueued' => '等待',
			'fileSources.downloadPaused' => '休息',
			'fileSources.downloadFailed' => '需要退休',
			'fileSources.importing' => '进口',
			'fileSources.importInterrupted' => '进口中断 · 删除清理',
			'fileSources.errorQuotaExceeded' => '已达到离线存储上限。请提高上限或移除已下载的副本。',
			'fileSources.errorStorageLow' => '没有足够的免费设备存储,以保留保护备份。',
			'fileSources.errorStorageUnavailable' => 'PlezyNG无法检查免费设备存储,所以写作停止了。',
			'fileSources.removeDownloadJob' => '删除下载',
			'fileSources.downloadAlreadyComplete' => '此下载完成之前,它可以被删除. 该项目现在可用于离线。',
			'fileSources.confirmRemoveDownloadJob' => '要移除此下载并丢弃已下载的部分数据吗？阅读位置和笔记会保留。',
			'lending.title' => '公共图书馆',
			'lending.add' => '添加图书馆',
			'lending.other' => '另一家图书馆',
			'lending.libraryName' => '图书馆名称',
			'lending.libraryUrl' => '图书馆网站',
			'lending.libraryUrlHint' => '使用您的图书馆的目录或登录页面。',
			'lending.intro' => '从图书馆借阅，让书籍随时相伴。',
			'lending.handoff' => '登录、借款和安全阅读,您图书馆的服务。',
			'lending.openService' => '开放图书馆',
			'lending.findLibrary' => '找个图书馆',
			'lending.search' => '搜索书籍和作家',
			'lending.catalogue' => '目录',
			'lending.loans' => '借阅',
			'lending.holds' => '预约',
			'lending.signIn' => '与您的图书馆登录',
			'lending.waiting' => '结束登录在您的浏览器,然后返回这里。',
			'lending.cancel' => '取消',
			'lending.disconnect' => '取消图书馆',
			'lending.disconnectMessage' => '要从此个人资料中移除此图书馆吗？借阅和预约记录仍会保留在图书馆。',
			'lending.getBook' => '获书',
			'lending.checkAvailability' => '查看可用性',
			'lending.available' => '可借阅',
			'lending.unavailable' => '目前不可用',
			'lending.borrow' => '借阅',
			'lending.placeHold' => '预约借阅',
			'lending.returnBook' => '提前归还',
			'lending.cancelHold' => '取消预约',
			'lending.confirmBorrow' => '借这本书从图书馆里?',
			'lending.confirmReturn' => '现在归还此书吗？您可能需要重新借阅才能继续阅读。',
			'lending.confirmCancelHold' => '要取消此书的预约吗？',
			'lending.email' => '留下通知电子邮件',
			'lending.due' => ({required Object date}) => '归还日期：${date}',
			'lending.queue' => ({required Object position}) => '排队位置：${position}',
			'lending.empty' => '还没有标题。',
			'lending.openLibraryNote' => '探索 Open Library 的目录。每本书的页面上都会显示阅读和借阅选项。',
			'lending.more' => '加载更多',
			'lending.gateway' => '图书馆登录服务',
			'lending.gatewayHint' => '由您的图书馆或管理员提供,PlezyNG。',
			'lending.advanced' => '图书馆集成',
			'lending.loadLibraries' => '选择您的图书馆',
			'lending.expired' => '此借阅已到期。',
			'lending.updated' => '图书馆更新',
			'lending.continueService' => '继续服务',
			'lending.comingSoon' => '借款 即将到来',
			'lending.comingSoonDescription' => '即将支持 Libby 集成。在连接功能完成之前，您可以先在 Libby 中使用图书馆服务。',
			'lending.suspendHold' => '暂停预约',
			'lending.resumeHold' => '恢复预约',
			'lending.suspendMessage' => '要保留排队位置，让下一位读者先借阅此副本吗？您可以稍后恢复预约。',
			'lending.resumeMessage' => '要恢复此预约，以便图书馆为您提供下一份可借阅的副本吗？',
			'lending.editEmail' => '更改通知电子邮件',
			'audiobook.syncTitle' => '阅读与倾听Sync',
			'audiobook.syncHelp' => '在您的设备上保持阅读位置、倾听位置、完成状态、图标和笔记。 选择附加存储帐户并在每个设备上使用相同的同步代码. 阅读和倾听保持分开。',
			'audiobook.addSyncSource' => '首先将 Google Drive、OneDrive、Dropbox、WebDAV 或 S3 添加到文件和书籍中。',
			'audiobook.syncDestination' => '同步存储帐户',
			'audiobook.syncFolder' => '同步文件夹或预定',
			'audiobook.syncFolderHelp' => '在 WebDAV 源内使用一个单独的现有文件夹,或一个专门的 S3 预定。',
			'audiobook.syncCode' => '个人同步代码',
			'audiobook.syncCodeHelp' => '在您的第一台设备上创建一个代码,然后在您的其他设备上输入该代码. 保持一个私人副本:它是您的加密状态的关键。',
			'audiobook.showCode' => '显示或隐藏同步代码',
			'audiobook.newSyncCode' => '创建一个新的同步代码',
			'audiobook.saveSync' => '保存和同步',
			'audiobook.disableSync' => '在此设备上关闭同步',
			'audiobook.syncSourceDisconnect' => '移除此来源会关闭此设备上的阅读和收听同步。加密的同步文件仍会保留在存储服务提供商处。',
			'audiobook.syncReconnect' => '重新连接存储帐户',
			'audiobook.lastSynced' => ({required Object time}) => '上一篇: ${time}',
			'audiobook.syncPrivacy' => '仅存储加密的进度和笔记。音频文件、电子书文件、账号令牌和密码不会上传。Google Drive 和 OneDrive 使用应用专用存储空间；Dropbox 使用 PlezyNG Sync。启用同步时，可能会请求额外的写入权限。启用后，进度同步由此存储目标负责，服务器进度保持独立。关闭同步后，本地历史记录和远程状态仍会保留。',
			'audiobook.syncConflicts' => '选择重定向的地方',
			'audiobook.conflictHelp' => '这些更改是分别独立做出的。请选择要保留的进度位置或书签版本。时间戳较新或进度百分比较高的版本不会自动优先保留。',
			'audiobook.syncDevice' => ({required Object device}) => '裝置 ${device}',
			'audiobook.syncUnknownDevice' => '未知设备',
			'audiobook.deletedBookmark' => '删除图标',
			'audiobook.finished' => '结束',
			'audiobook.readingPosition' => ({required Object percent}) => '阅读 · ${percent}%',
			'audiobook.chapterTimeline' => '第四章 进展',
			'audiobook.bookTimeline' => '全书进展',
			'audiobook.bookRemaining' => ({required Object time}) => '本书剩余时间：${time}',
			'audiobook.chapterRemaining' => ({required Object time}) => '此分類上一篇: ${time}',
			'audiobook.unknownRemaining' => '全部时间可用,当部分被播放时',
			'audiobook.undoSeek' => '最后寻找',
			'audiobook.customSpeed' => '定制播放速度',
			'audiobook.speedHelp' => '选择速度从 0.25× 到 4×。',
			'audiobook.apply' => '應用',
			'audiobook.customSleep' => '定制睡眠时间',
			'audiobook.sleepMinutes' => '时间(1 - 1440)',
			'audiobook.sleepChapters' => ({required Object count}) => '播放完${count}章后停止',
			'audiobook.extendSleep' => '添加5分钟',
			'audiobook.sleepRemaining' => ({required Object time}) => '睡眠时间: ${time}',
			'audiobook.useDefaults' => '使用这些听力控制器为新书',
			'audiobook.librarySort' => '各式各样的书籍',
			'audiobook.sortTitle' => '标题',
			'audiobook.sortAuthor' => '作者',
			'audiobook.sortNarrator' => '讲话者',
			'audiobook.sortSeries' => '系列命令',
			'audiobook.sortRecent' => '最近开放',
			'audiobook.statusFilter' => '阅读状态',
			'audiobook.statusAll' => '所有书籍',
			'audiobook.statusNew' => '没有开始',
			'audiobook.statusProgress' => '进展',
			'audiobook.statusFinished' => '结束',
			'audiobook.goToTime' => '走到时间',
			'audiobook.timeHelp' => '时间: 分钟: 秒或 分钟: 秒',
			'audiobook.recoveryHelp' => '移动或修复同步数据前，请先导出近期的加密备份。导入内容会与当前状态合并，不会覆盖本地同步历史。请另行保存同步代码。',
			'audiobook.recoveryExport' => '输出加密恢复文件',
			'audiobook.recoveryImport' => '输入加密恢复文件',
			'audiobook.recoveryImportConfirm' => '将此加密恢复文件与当前阅读位置和笔记相结合吗?现有历史记录将被保留. 共享图书馆和项目 ID 不包含; 在进口之前,在每个设备上设置匹配 ID。',
			'audiobook.recoveryExported' => '加密恢复文件保存。',
			'audiobook.recoveryImported' => '恢复数据合并。',
			'sourceSetup.savedCertificate' => '已保存的服务器证书',
			'sourceSetup.nfsEndpointInvalid' => '请输入 NFS 地址，例如 nfs://nas:2049/export。',
			'sourceSetup.dlnaNone' => '未找到 DLNA 服务器。请手动输入设备描述文件的地址。',
			'sourceSetup.dlnaServers' => 'DLNA 媒体服务器',
			'sourceSetup.dlnaUnavailable' => '无法在此网络上发现 DLNA 设备。请手动输入设备描述文件的地址。',
			'sourceSetup.dlnaSearching' => '正在本地网络中搜索 DLNA 服务器',
			'sourceSetup.networkSearching' => '正在搜索本地网络…',
			'sourceSetup.dlnaDiscover' => '发现 DLNA 服务器',
			'sourceSetup.dlnaHelp' => '设备发现需要本地网络支持组播。如果没有找到服务器，请在上方输入设备描述文件的地址。',
			'sourceSetup.dlnaRoot' => 'DLNA 对象 ID；留空以使用设备根目录。',
			'sourceSetup.passwordOrKey' => '请输入密码，或在下方添加私钥。',
			'sourceSetup.sshFingerprint' => 'SSH 主机密钥 SHA256 指纹',
			'sourceSetup.sshFingerprintHelp' => '请向服务器管理员核实。在服务器上运行 ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub，并使用显示的 SHA256 值。',
			'sourceSetup.sshFingerprintKeep' => '留空以保留当前固定的指纹，或输入新的服务器指纹。',
			'sourceSetup.sshAuthentication' => 'SSH 公钥认证',
			'sourceSetup.sshAuthenticationHelp' => '可选；也支持密码认证。',
			'sourceSetup.privateKey' => '私钥（PEM 或 OpenSSH 格式）',
			'sourceSetup.privateKeyPassphrase' => '私钥口令',
			'sourceSetup.nfsMountPort' => 'NFS 挂载服务 TCP 端口',
			'sourceSetup.nfsMountPortHelp' => '默认值：20048',
			'sourceSetup.nfsUserId' => 'NFS 用户 ID（AUTH_SYS）',
			'sourceSetup.nfsUserIdHelp' => '默认值：1000。请使用 NAS 导出配置允许的用户 ID。',
			'sourceSetup.nfsGroupId' => 'NFS 组 ID（AUTH_SYS）',
			'sourceSetup.nfsGroupIdHelp' => '默认值：1000。请使用 NAS 导出配置允许的组 ID。',
			'sourceSetup.nfsEncryption' => '要求加密 NFS 连接（RPC-with-TLS）',
			'sourceSetup.nfsEncryptionHelp' => '要求 NFS 和挂载服务使用 TLS 1.3。如果 NAS 不支持，将拒绝连接。',
			'sourceSetup.nfsTrustCertificate' => '自定义 NFS CA 或服务器证书（PEM，可选）',
			'sourceSetup.nfsTrustHelp' => '使用此设备信任的证书时请留空。需要时可添加私有 CA 或自签名服务器证书；证书中的名称必须与 NFS 地址的主机名匹配。',
			'sourceSetup.nfsTrustInvalid' => '请使用 PEM 格式的 CA 或服务器证书。不要包含私钥。',
			'sourceSetup.addTrustCertificate' => '添加自定义信任证书',
			'sourceSetup.replaceTrustCertificate' => '替换已保存的自定义证书',
			'sourceSetup.nfsTlsHelp' => 'RPC-with-TLS 使用常规 NFS 和挂载服务端口，并要求 NAS 支持 RFC 9289。必须使用 TLS 1.3。主机名或 IP 地址必须与证书匹配。加密通道内仍需使用 AUTH_SYS UID/GID。',
			'sourceSetup.clientCertificate' => '客户端证书（可选）',
			'sourceSetup.clientCertificateHelp' => '允许 NAS 验证此客户端的身份；AUTH_SYS ID 仍受 NAS 导出策略约束。',
			'sourceSetup.savedIdentity' => '将使用已保存的客户端身份凭据。',
			'sourceSetup.replaceIdentity' => '替换已保存的客户端身份凭据',
			'sourceSetup.chooseIdentity' => '选择 PKCS#12 客户端身份凭据',
			'sourceSetup.identityPassphrase' => '客户端身份凭据口令',
			'sourceSetup.identityPassphraseHelp' => '如果文件没有口令，请留空。',
			'sourceSetup.removeIdentity' => '移除已保存的客户端身份凭据',
			'sourceSetup.identityStorageHelp' => '客户端身份凭据保存在加密的来源凭据存储中。保持此部分不变，即可保留已保存的身份凭据。',
			'sourceSetup.nfsLimitations' => '以只读方式通过 TCP 使用 NFSv3。不使用 RPC-with-TLS 时，NFS 流量不会加密。NAS 必须允许所选 AUTH_SYS ID 和非特权客户端端口（导出选项通常称为“insecure”）。不支持 NFSv4 和 UDP。',
			'sourceSetup.nfsSetupHelp' => 'NFS 设置帮助',
			'sourceSetup.nfsSetupHint' => '如果无法建立连接，请检查这些设置。',
			'sourceSetup.nfsSetupDetails' => '请使用通过 TCP 提供的 NFSv3 导出。要求加密时，NFS 服务和挂载服务必须都支持 RPC-with-TLS。如果服务器证书受此设备信任，自定义证书可留空；否则请添加 NAS 的 CA 或自签名证书。证书名称必须与端点中的主机名匹配。如果 NAS 要求双向 TLS，请添加其 PKCS#12 客户端身份凭据。最后，确认导出配置允许所设的 AUTH_SYS UID/GID 和客户端端口策略。',
			'sourceSetup.ftpHelp' => 'FTP 使用被动模式。未加密的 FTP 使用 ftp://，显式 TLS 使用 ftpes://；ftps:// 使用 TLS（端口 990 为隐式 TLS，其他端口为显式 TLS）。',
			'sourceSetup.openSubtitles' => 'OpenSubtitles',
			'sourceSetup.subtitleSetup' => '为独立视频提供可选的字幕搜索。',
			'sourceSetup.apiKey' => 'API 密钥',
			'sourceSetup.optionalUsername' => '账户用户名（可选）',
			'sourceSetup.optionalPassword' => '账户密码（可选）',
			'sourceSetup.subtitlePrivacy' => '请从 opensubtitles.com 获取 API 密钥。搜索会发送视频标题和可用的 IMDb/TMDB ID，绝不会发送视频文件。密钥和可选的账户凭据会随此来源加密保存。',
			'sourceSetup.automaticMetadata' => '自动获取在线视频元数据',
			'sourceSetup.metadataPrivacy' => '仅发送文件名中的标题、年份和集数，或 NFO ID，绝不发送媒体文件或凭据。NFO 字段始终优先。',
			'sourceSetup.nfsEncryptionFailure' => '对于加密 NFS，请检查 NAS 的两项服务是否支持 RFC 9289 和 TLS 1.3，并核对证书名称以及导出 UID/GID。PlezyNG 不会在不加密的情况下重试此连接。',
			'sourceSetup.sourceConnecting' => '正在连接来源',
			'sourceSetup.metadataSearchPrivacy' => '此标题搜索由 Trakt 处理。只会发送您输入的标题，不会发送视频或来源凭据。',
			'sourceSetup.chooseMatch' => '选择匹配结果',
			'sourceSetup.metadataMatchHelp' => '选择前请核对标题和年份。Trakt 会收到搜索标题；视频文件会保留在原来源中。',
			'sourceSetup.metadataNoMatches' => '未找到在线标题匹配结果。请尝试其他标题。',
			'sourceSetup.metadataSearch' => '搜索在线元数据',
			'sourceSetup.metadataLoading' => '正在查询在线电影和剧集信息…',
			'sourceSetup.metadataFromTrakt' => '来自 Trakt 的在线元数据',
			'sourceSetup.metadataNoAutomaticMatch' => '未找到自动匹配的标题。请搜索标题并选择匹配结果。',
			'sourceSetup.metadataFailed' => '无法加载在线元数据。仍可播放媒体和查看本地信息。',
			'sourceSetup.videoDetailsLoading' => '正在加载视频信息',
			'sourceSetup.subtitleKeyRequired' => '需要 OpenSubtitles API 密钥',
			'sourceSetup.subtitleKeyHelp' => '请编辑此文件来源，在可选的字幕设置中添加 OpenSubtitles API 密钥。',
			'sourceSetup.subtitleSearchFailed' => '字幕搜索失败。请检查 API 密钥、网络连接和服务访问权限。',
			'sourceSetup.subtitleApplyFailed' => '无法下载或应用此字幕。请检查连接并尝试其他结果。',
			'sourceSetup.subtitleSearch' => '搜索 OpenSubtitles',
			'sourceSetup.subtitleSearchPrivacy' => '搜索会使用标题和可用的 IMDb/TMDB ID。视频文件会保留在原来源中。选择前请核对语言、强制字幕或听障字幕标记以及评分。',
			'sourceSetup.movieOrShow' => '电影或剧集',
			'sourceSetup.subtitleTitleHint' => '输入标题以缩小结果范围',
			'sourceSetup.subtitleLanguage' => '字幕语言',
			'sourceSetup.subtitleSearching' => '正在搜索 OpenSubtitles',
			'sourceSetup.subtitleNoMatches' => '未找到匹配的字幕。请尝试其他标题或语言。',
			'sourceSetup.downloadSubtitle' => '下载字幕',
			'sourceSetup.subtitle' => '字幕',
			'sourceSetup.nfsTlsRequired' => '要求 RPC-with-TLS',
			'sourceSetup.nfsUnencrypted' => '未加密的 NFS',
			'sourceSetup.tlsEncrypted' => '已启用 TLS 加密',
			'sourceSetup.ftpPlain' => '未加密的 FTP',
			'sourceSetup.sshPinned' => 'SSH 加密 · 主机密钥已固定',
			'sourceSetup.smbEncrypted' => 'SMB3 加密已开启',
			'sourceSetup.smbUnencrypted' => 'SMB3 加密已关闭',
			'sourceSetup.httpUnencrypted' => 'HTTP 无传输加密',
			'sourceSetup.checkEndpointSecurity' => '请检查端点安全性',
			'sourceSetup.fieldRequired' => ({required Object label}) => '请填写${label}。',
			'sourceSetup.integerRange' => ({required Object min, required Object max, required Object label}) => '请输入 ${min} 至 ${max} 之间的${label}。',
			'sourceSetup.replaceFile' => ({required Object name}) => '替换 ${name}',
			'sourceSetup.selectedIdentity' => ({required Object name}) => '已选客户端身份凭据：${name}',
			'sourceSetup.subtitleRating' => ({required Object rating}) => '评分 ${rating}',
			'sourceSetup.subtitleDownloading' => ({required Object title}) => '正在下载字幕：${title}',
			'sourceSetup.sharedEntryPair' => '将此项目配对',
			'sourceSetup.sharedEntryPairHelp' => '在每台设备上为此项目输入相同的 ID。使用稳定的共享标识符，或生成一个并复制到对应项目。只有版本的文件类型、大小和顺序都一致时，阅读进度才会关联。留空会移除此映射。',
			'sourceSetup.sharedEntryId' => '共享项目 ID',
			'sourceSetup.generateSharedEntryId' => '创建共享项目 ID',
			'sourceSetup.sharedLibraryId' => '共享图书馆 ID(可选)',
			'sourceSetup.sharedLibraryHelp' => '使用相同 ID 在開啟相同圖書館的裝置上. 這個公共 ID 有助於在不同的來源連接中進行閱讀進步和筆記; 它不是密碼. 当提供商使用不同的項目 ID 時,將這些項目從其細節屏幕組合。',
			'sourceSetup.sharedLibraryInvalid' => '使用 8 至 100 个字母、数字、点、字幕或字符。',
			'sourceSetup.generateSharedLibraryId' => '创建共享图书馆 ID',
			'sourceSetup.nfsReadAhead' => 'NFS Read-ahead 请求',
			_ => null,
		} ?? switch (path) {
			'sourceSetup.nfsReadAheadHelp' => '更多的平行阅读可以改善快速NAS或网络的通道。使用1如果服务器限制当前请求。',
			'sourceSetup.nfsReadTest' => '测量NFS阅读性能',
			'sourceSetup.nfsReadTestHelp' => '从最大的文件中读到64 MiB,以测量这个NAS连接,这使用网络带宽。',
			'sourceSetup.nfsQualificationResult' => 'NFS 阅读测量',
			'sourceSetup.nfsReadBytes' => '数据阅读',
			'sourceSetup.nfsReadSpeed' => '测量速度',
			'sourceSetup.nfsReadRequests' => '阅读请求',
			'sourceSetup.sharedEntryConflict' => '此共享项目 ID 已与本图书馆中的另一个项目相匹配. 选择不同的 ID。',
			'comics.fitHeight' => '适合高度',
			'comics.readingMode' => '阅读模式',
			'comics.paged' => '分页',
			'comics.webtoon' => '连续滚动',
			'comics.coverAlone' => '单独显示封面',
			'comics.splitWide' => '拆分宽页',
			'comics.splitWideHelp' => '按阅读顺序分别显示每一半。开启后暂停双页并排显示。',
			'comics.thumbnails' => '页面缩略图',
			'comics.controlsHelp' => '滑动翻页，双击切换适配方式。连续滚动时，垂直滑动或使用 Page Up 和 Page Down。',
			'comics.savedForComic' => '此个人资料会记住这部漫画的显示设置。',
			'comics.readLists' => '阅读列表',
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
			'deepLinks.invalid' => '此 Plezy 链接不有效。',
			'deepLinks.profileNotFound' => ({required Object profile}) => '没有个人资料符合“${profile}”。',
			'deepLinks.serverUnavailable' => '我无法到达这个链接的服务器。',
			'deepLinks.notFound' => '我无法在图书馆中找到这个标题。',
			'deepLinks.unsupportedItem' => '这个链接不能播放。',
			'deepLinks.noLiveTv' => '没有现场电视服务器可用于此链接。',
			'deepLinks.channelNotFound' => ({required Object channel}) => '我找不到“${channel}”频道。',
			'deepLinks.showLink' => '显示链接',
			'deepLinks.showProfileLink' => '显示个人资料链接',
			'deepLinks.dialogTitle' => '链接',
			'deepLinks.showHint' => '打开此链接将播放下一集。要随机播放整部剧集，请在末尾添加 &mode=shuffle。',
			'deepLinks.movieHint' => '打开这个链接播放电影。',
			'deepLinks.episodeHint' => '打开这个链接播放了这个节目。',
			'deepLinks.profileHint' => '打开此链接转换到这个个人资料。',
			'deepLinks.openAsProfile' => ({required Object name}) => '打开 ${name}',
			'deepLinks.copy' => '复制',
			'deepLinks.copied' => '链接复制',
			_ => null,
		};
	}
}
