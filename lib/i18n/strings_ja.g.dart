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
class TranslationsJa extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsJa({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ja,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ja>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsJa _root = this; // ignore: unused_field

	@override 
	TranslationsJa $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsJa(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsAppJa app = _TranslationsAppJa._(_root);
	@override late final _TranslationsAuthJa auth = _TranslationsAuthJa._(_root);
	@override late final _TranslationsCommonJa common = _TranslationsCommonJa._(_root);
	@override late final _TranslationsScreensJa screens = _TranslationsScreensJa._(_root);
	@override late final _TranslationsUpdateJa update = _TranslationsUpdateJa._(_root);
	@override late final _TranslationsSettingsJa settings = _TranslationsSettingsJa._(_root);
	@override late final _TranslationsSearchJa search = _TranslationsSearchJa._(_root);
	@override late final _TranslationsHotkeysJa hotkeys = _TranslationsHotkeysJa._(_root);
	@override late final _TranslationsFileInfoJa fileInfo = _TranslationsFileInfoJa._(_root);
	@override late final _TranslationsMediaMenuJa mediaMenu = _TranslationsMediaMenuJa._(_root);
	@override late final _TranslationsRateSheetJa rateSheet = _TranslationsRateSheetJa._(_root);
	@override late final _TranslationsAccessibilityJa accessibility = _TranslationsAccessibilityJa._(_root);
	@override late final _TranslationsTooltipsJa tooltips = _TranslationsTooltipsJa._(_root);
	@override late final _TranslationsVideoControlsJa videoControls = _TranslationsVideoControlsJa._(_root);
	@override late final _TranslationsMessagesJa messages = _TranslationsMessagesJa._(_root);
	@override late final _TranslationsSubtitlingStylingJa subtitlingStyling = _TranslationsSubtitlingStylingJa._(_root);
	@override late final _TranslationsMpvConfigJa mpvConfig = _TranslationsMpvConfigJa._(_root);
	@override late final _TranslationsDialogJa dialog = _TranslationsDialogJa._(_root);
	@override late final _TranslationsProfilesJa profiles = _TranslationsProfilesJa._(_root);
	@override late final _TranslationsConnectionsJa connections = _TranslationsConnectionsJa._(_root);
	@override late final _TranslationsDiscoverJa discover = _TranslationsDiscoverJa._(_root);
	@override late final _TranslationsErrorsJa errors = _TranslationsErrorsJa._(_root);
	@override late final _TranslationsLibrariesJa libraries = _TranslationsLibrariesJa._(_root);
	@override late final _TranslationsAboutJa about = _TranslationsAboutJa._(_root);
	@override late final _TranslationsServerSelectionJa serverSelection = _TranslationsServerSelectionJa._(_root);
	@override late final _TranslationsHubDetailJa hubDetail = _TranslationsHubDetailJa._(_root);
	@override late final _TranslationsLogsJa logs = _TranslationsLogsJa._(_root);
	@override late final _TranslationsLicensesJa licenses = _TranslationsLicensesJa._(_root);
	@override late final _TranslationsNavigationJa navigation = _TranslationsNavigationJa._(_root);
	@override late final _TranslationsExploreJa explore = _TranslationsExploreJa._(_root);
	@override late final _TranslationsLiveTvJa liveTv = _TranslationsLiveTvJa._(_root);
	@override late final _TranslationsCollectionsJa collections = _TranslationsCollectionsJa._(_root);
	@override late final _TranslationsPlaylistsJa playlists = _TranslationsPlaylistsJa._(_root);
	@override late final _TranslationsMusicJa music = _TranslationsMusicJa._(_root);
	@override late final _TranslationsWatchTogetherJa watchTogether = _TranslationsWatchTogetherJa._(_root);
	@override late final _TranslationsDownloadsJa downloads = _TranslationsDownloadsJa._(_root);
	@override late final _TranslationsShadersJa shaders = _TranslationsShadersJa._(_root);
	@override late final _TranslationsCompanionRemoteJa companionRemote = _TranslationsCompanionRemoteJa._(_root);
	@override late final _TranslationsVideoSettingsJa videoSettings = _TranslationsVideoSettingsJa._(_root);
	@override late final _TranslationsPerformanceOverlayJa performanceOverlay = _TranslationsPerformanceOverlayJa._(_root);
	@override late final _TranslationsExternalPlayerJa externalPlayer = _TranslationsExternalPlayerJa._(_root);
	@override late final _TranslationsMetadataEditJa metadataEdit = _TranslationsMetadataEditJa._(_root);
	@override late final _TranslationsMatchScreenJa matchScreen = _TranslationsMatchScreenJa._(_root);
	@override late final _TranslationsServerTasksJa serverTasks = _TranslationsServerTasksJa._(_root);
	@override late final _TranslationsTraktJa trakt = _TranslationsTraktJa._(_root);
	@override late final _TranslationsSeerrJa seerr = _TranslationsSeerrJa._(_root);
	@override late final _TranslationsServicesJa services = _TranslationsServicesJa._(_root);
	@override late final _TranslationsAddServerJa addServer = _TranslationsAddServerJa._(_root);
}

// Path: app
class _TranslationsAppJa extends TranslationsAppEn {
	_TranslationsAppJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _TranslationsAuthJa extends TranslationsAuthEn {
	_TranslationsAuthJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Plexでサインイン';
	@override String get showQRCode => 'QRコードを表示';
	@override String get authenticate => '認証';
	@override String get authenticationTimeout => '認証がタイムアウトしました。もう一度お試しください。';
	@override String get scanQRToSignIn => 'このQRコードをスキャンしてサインイン';
	@override String get waitingForAuth => '認証待ち...\nブラウザでサインインしてください。';
	@override String get useBrowser => 'ブラウザを使用';
	@override String get or => 'または';
	@override String get connectToJellyfin => 'Jellyfinに接続';
	@override String get useQuickConnect => 'Quick Connect を使う';
	@override String get quickConnectInstructions => 'JellyfinでQuick Connectを開き、このコードを入力してください。';
	@override String get quickConnectWaiting => '承認を待っています…';
	@override String get quickConnectCancel => 'キャンセル';
	@override String get quickConnectExpired => 'Quick Connectの有効期限が切れました。もう一度お試しください。';
}

// Path: common
class _TranslationsCommonJa extends TranslationsCommonEn {
	_TranslationsCommonJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'キャンセル';
	@override String get save => '保存';
	@override String get close => '閉じる';
	@override String get clear => 'クリア';
	@override String get reset => 'リセット';
	@override String get later => '後で';
	@override String get submit => '送信';
	@override String get confirm => '確認';
	@override String get retry => '再試行';
	@override String get logout => 'ログアウト';
	@override String get unknown => '不明';
	@override String get refresh => '更新';
	@override String get yes => 'はい';
	@override String get no => 'いいえ';
	@override String get delete => '削除';
	@override String get edit => '編集';
	@override String get shuffle => 'シャッフル';
	@override String get addTo => '追加...';
	@override String get createNew => '新規作成';
	@override String get connect => '接続';
	@override String get disconnect => '切断';
	@override String get play => '再生';
	@override String get pause => '一時停止';
	@override String get resume => '再開';
	@override String get error => 'エラー';
	@override String get search => '検索';
	@override String get home => 'ホーム';
	@override String get back => '戻る';
	@override String get settings => '設定';
	@override String get mute => 'ミュート';
	@override String get ok => 'OK';
	@override String get off => 'オフ';
	@override String seasonNumber({required Object number}) => 'シーズン${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'エピソード${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'チャプター${number}';
	@override String get reconnect => '再接続';
	@override String get viewAll => 'すべて表示';
	@override String get checkingNetwork => 'ネットワークを確認中...';
	@override String get loadingServers => 'サーバーを読み込み中...';
	@override String get connectingToServers => 'サーバーに接続中...';
	@override String get startingOfflineMode => 'オフラインモードを開始中...';
	@override String get loading => '読み込み中...';
	@override String get fullscreen => 'フルスクリーン';
	@override String get exitFullscreen => 'フルスクリーンを終了';
	@override String get pressBackAgainToExit => 'もう一度押すと終了します';
}

// Path: screens
class _TranslationsScreensJa extends TranslationsScreensEn {
	_TranslationsScreensJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'ライセンス';
	@override String get switchProfile => 'プロフィール切替';
	@override String get subtitleStyling => '字幕スタイル';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'ログ';
}

// Path: update
class _TranslationsUpdateJa extends TranslationsUpdateEn {
	_TranslationsUpdateJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get available => 'アップデート利用可能';
	@override String versionAvailable({required Object version}) => 'バージョン ${version} が利用可能です';
	@override String currentVersion({required Object version}) => '現在: ${version}';
	@override String get skipVersion => 'このバージョンをスキップ';
	@override String get viewRelease => 'リリースを表示';
	@override String get latestVersion => '最新バージョンです';
	@override String get checkFailed => 'アップデートの確認に失敗しました';
}

// Path: settings
class _TranslationsSettingsJa extends TranslationsSettingsEn {
	_TranslationsSettingsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '設定';
	@override String get supportDeveloper => 'Plezy を支援';
	@override String get supportDeveloperDescription => 'Liberapay で寄付して開発を支援';
	@override String get language => '言語';
	@override String get theme => 'テーマ';
	@override String get appearance => '外観';
	@override String get videoPlayback => '動画再生';
	@override String get videoPlaybackDescription => '再生動作を設定';
	@override String get advanced => '詳細';
	@override String get episodePosterMode => 'エピソードポスタースタイル';
	@override String get seriesPoster => 'シリーズポスター';
	@override String get seasonPoster => 'シーズンポスター';
	@override String get episodeThumbnail => 'サムネイル';
	@override String get showHeroSectionDescription => 'ホーム画面に注目コンテンツのカルーセルを表示';
	@override String get secondsLabel => '秒';
	@override String get minutesLabel => '分';
	@override String get secondsShort => '秒';
	@override String get minutesShort => '分';
	@override String durationHint({required Object min, required Object max}) => '時間を入力 (${min}-${max})';
	@override String get systemTheme => 'システム';
	@override String get lightTheme => 'ライト';
	@override String get darkTheme => 'ダーク';
	@override String get oledTheme => 'OLED';
	@override String get libraryDensity => 'ライブラリの密度';
	@override String get compact => 'コンパクト';
	@override String get comfortable => 'ゆったり';
	@override String get viewMode => '表示モード';
	@override String get gridView => 'グリッド';
	@override String get listView => 'リスト';
	@override String get showHeroSection => 'ヒーローセクションを表示';
	@override String get continueWatchingAction => '視聴中の操作';
	@override String get continueWatchingPlay => '再生';
	@override String get continueWatchingDetails => '詳細を開く';
	@override String get episodeAction => 'エピソードの操作';
	@override String get episodePlay => '再生';
	@override String get episodeDetails => '詳細を開く';
	@override String get useGlobalHubs => 'ホームレイアウトを使用';
	@override String get useGlobalHubsDescription => '統合ホームハブを表示します。オフの場合はライブラリのおすすめを使用します。';
	@override String get showServerNameOnHubs => 'ハブにサーバー名を表示';
	@override String get showServerNameOnHubsDescription => 'ハブのタイトルに常にサーバー名を表示します。';
	@override String get groupLibrariesByServer => 'サーバーごとにライブラリをグループ化';
	@override String get groupLibrariesByServerDescription => 'サイドバーのライブラリをメディアサーバーごとにまとめます。';
	@override String get alwaysKeepSidebarOpen => 'サイドバーを常に開いておく';
	@override String get alwaysKeepSidebarOpenDescription => 'サイドバーを展開したまま、コンテンツ領域が調整される';
	@override String get showUnwatchedCount => '未視聴数を表示';
	@override String get showUnwatchedCountDescription => '番組とシーズンに未視聴エピソード数を表示';
	@override String get showEpisodeNumberOnCards => 'カードにエピソード番号を表示';
	@override String get showEpisodeNumberOnCardsDescription => 'エピソードカードにシーズン番号とエピソード番号を表示します';
	@override String get showSeasonPostersOnTabs => 'タブにシーズンポスターを表示';
	@override String get showSeasonPostersOnTabsDescription => '各シーズンのポスターをタブの上に表示します';
	@override String get tvFullCardLayout => 'フルTVカード';
	@override String get tvFullCardLayoutDescription => 'TVカードを画像のみで表示し、俳優名を重ねて表示します';
	@override String get focusGlow => 'フォーカス時の光彩';
	@override String get focusGlowDescription => 'フォーカス中のカードの周りに柔らかい光彩を表示します';
	@override String get visualEffects => '視覚効果';
	@override String get visualEffectsAuto => '自動';
	@override String get visualEffectsAutoDescription => '低性能なデバイスでは効果を自動的に減らします';
	@override String get visualEffectsFull => 'フル';
	@override String get visualEffectsReduced => '軽減';
	@override String get visualEffectsReducedDescription => 'アニメーションを減らし、低解像度のアートワークを使用します';
	@override String get hideSpoilers => '未視聴エピソードのネタバレを非表示';
	@override String get hideSpoilersDescription => '未視聴エピソードのサムネイルと説明をぼかします';
	@override String get playerBackend => 'プレーヤーバックエンド';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'ハードウェアデコード';
	@override String get hardwareDecodingDescription => '利用可能な場合にハードウェアアクセラレーションを使用';
	@override String get bufferSize => 'バッファサイズ';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => '自動（推奨）';
	@override String bufferSizeWarning({required Object heap, required Object size}) => '${heap}MBのメモリが利用可能です。${size}MBのバッファは再生に影響する可能性があります。';
	@override String get defaultQualityTitle => 'デフォルト画質';
	@override String get musicQualityTitle => '音楽の音質';
	@override String get subtitleStyling => '字幕スタイル';
	@override String get subtitleStylingDescription => '字幕の外観をカスタマイズ';
	@override String get smallSkipDuration => '短いスキップ時間';
	@override String get largeSkipDuration => '長いスキップ時間';
	@override String get rewindOnResume => '再開時に巻き戻し';
	@override String secondsUnit({required Object seconds}) => '${seconds}秒';
	@override String get defaultSleepTimer => 'デフォルトスリープタイマー';
	@override String minutesUnit({required Object minutes}) => '${minutes}分';
	@override String get rememberTrackSelections => '番組/映画ごとにトラック選択を記憶';
	@override String get rememberTrackSelectionsDescription => 'タイトルごとに音声と字幕の選択を記憶します';
	@override String get showChapterMarkersOnTimeline => 'シークバーにチャプターマーカーを表示';
	@override String get showChapterMarkersOnTimelineDescription => 'チャプターの境界でシークバーを区切る';
	@override String get clickVideoTogglesPlayback => '動画クリックで再生/一時停止を切替';
	@override String get clickVideoTogglesPlaybackDescription => 'コントロール表示ではなく、動画クリックで再生/一時停止します。';
	@override String get videoPlayerControls => '動画プレーヤーコントロール';
	@override String get keyboardShortcuts => 'キーボードショートカット';
	@override String get keyboardShortcutsDescription => 'キーボードショートカットをカスタマイズ';
	@override String get videoPlayerNavigation => '動画プレーヤーナビゲーション';
	@override String get videoPlayerNavigationDescription => '矢印キーで動画プレーヤーコントロールを操作';
	@override String get watchTogetherRelay => '一緒に視聴リレーサーバー';
	@override String get watchTogetherRelayDescription => 'カスタムリレーを設定します。全員が同じサーバーを使う必要があります。';
	@override String get watchTogetherRelayHint => 'https://my-relay.example.com';
	@override String get crashReporting => 'クラッシュレポート';
	@override String get crashReportingDescription => 'アプリの改善に役立つクラッシュレポートを送信';
	@override String get debugLogging => 'デバッグログ';
	@override String get debugLoggingDescription => 'トラブルシューティング用の詳細なログを有効化';
	@override String get viewLogs => 'ログを表示';
	@override String get viewLogsDescription => 'アプリケーションログを表示';
	@override String get clearCache => 'キャッシュをクリア';
	@override String get clearCacheDescription => 'キャッシュ済みの画像とデータを削除します。コンテンツの読み込みが遅くなる場合があります。';
	@override String get clearCacheSuccess => 'キャッシュを正常にクリアしました';
	@override String get resetSettings => '設定をリセット';
	@override String get resetSettingsDescription => '設定を既定に戻します。元に戻せません。';
	@override String get resetSettingsSuccess => '設定を正常にリセットしました';
	@override String get backup => 'バックアップ';
	@override String get exportSettings => '設定をエクスポート';
	@override String get exportSettingsDescription => '設定をファイルに保存';
	@override String get exportSettingsSuccess => '設定をエクスポートしました';
	@override String get exportSettingsFailed => '設定をエクスポートできませんでした';
	@override String get importSettings => '設定をインポート';
	@override String get importSettingsDescription => 'ファイルから設定を復元';
	@override String get importSettingsConfirm => '現在の設定を置き換えます。続行しますか？';
	@override String get importSettingsSuccess => '設定をインポートしました';
	@override String get importSettingsFailed => '設定をインポートできませんでした';
	@override String get importSettingsInvalidFile => 'このファイルは有効なPlezyの設定エクスポートではありません';
	@override String get importSettingsNoUser => '設定をインポートする前にサインインしてください';
	@override String get shortcutsReset => 'ショートカットをデフォルトにリセットしました';
	@override String get about => 'アプリについて';
	@override String get aboutDescription => 'アプリ情報とライセンス';
	@override String get updates => 'アップデート';
	@override String get updateAvailable => 'アップデート利用可能';
	@override String get checkForUpdates => 'アップデートを確認';
	@override String get autoCheckUpdatesOnStartup => '起動時にアップデートを自動的に確認';
	@override String get autoCheckUpdatesOnStartupDescription => '起動時にアップデートがある場合は通知します';
	@override String get validationErrorEnterNumber => '有効な数値を入力してください';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => '時間は${min}から${max} ${unit}の間である必要があります';
	@override String shortcutAlreadyAssigned({required Object action}) => 'ショートカットは既に${action}に割り当てられています';
	@override String shortcutUpdated({required Object action}) => '${action}のショートカットを更新しました';
	@override String get autoSkip => '自動スキップ';
	@override String get autoSkipIntro => 'イントロを自動スキップ';
	@override String get autoSkipIntroDescription => '数秒後にイントロマーカーを自動的にスキップ';
	@override String get autoSkipCredits => 'クレジットを自動スキップ';
	@override String get autoSkipCreditsDescription => 'クレジットを自動的にスキップして次のエピソードを再生';
	@override String get forceSkipMarkerFallback => 'フォールバックマーカーを強制';
	@override String get forceSkipMarkerFallbackDescription => 'Plexにマーカーがある場合でもチャプタータイトルのパターンを使用します';
	@override String get autoSkipDelay => '自動スキップの遅延';
	@override String autoSkipDelayDescription({required Object seconds}) => '自動スキップまで${seconds}秒待機';
	@override String get introPattern => 'イントロマーカーパターン';
	@override String get introPatternDescription => 'チャプタータイトルのイントロマーカーに一致する正規表現パターン';
	@override String get creditsPattern => 'クレジットマーカーパターン';
	@override String get creditsPatternDescription => 'チャプタータイトルのクレジットマーカーに一致する正規表現パターン';
	@override String get invalidRegex => '無効な正規表現';
	@override String get regex => '正規表現';
	@override String get downloads => 'ダウンロード';
	@override String get downloadLocationDescription => 'ダウンロードコンテンツの保存場所を選択';
	@override String get downloadLocationDefault => 'デフォルト（アプリストレージ）';
	@override String get downloadLocationCustom => 'カスタムの場所';
	@override String get selectFolder => 'フォルダを選択';
	@override String get resetToDefault => 'デフォルトに戻す';
	@override String currentPath({required Object path}) => '現在: ${path}';
	@override String get downloadLocationChanged => 'ダウンロード場所を変更しました';
	@override String get downloadLocationReset => 'ダウンロード場所をデフォルトにリセットしました';
	@override String get downloadLocationInvalid => '選択したフォルダは書き込みできません';
	@override String get downloadLocationSelectError => 'フォルダの選択に失敗しました';
	@override String get downloadOnWifiOnly => 'WiFiのみでダウンロード';
	@override String get downloadOnWifiOnlyDescription => 'モバイルデータ通信時のダウンロードを防止';
	@override String get autoRemoveWatchedDownloads => '視聴済みダウンロードの自動削除';
	@override String get autoRemoveWatchedDownloadsDescription => '視聴済みのダウンロードを自動削除します';
	@override String get cellularDownloadBlocked => 'モバイル通信ではダウンロードがブロックされています。WiFiを使うか設定を変更してください。';
	@override String get maxVolume => '最大音量';
	@override String get maxVolumeDescription => '静かなメディアに対して100%以上の音量ブーストを許可';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Discordで視聴中の内容を表示';
	@override String get services => 'サービス';
	@override String get servicesDescription => 'Trakt、MyAnimeList、Seerr などを接続';
	@override String get manageLibrariesDescription => 'ライブラリを並べ替えたり非表示にしたりできます';
	@override String get companionRemoteServer => 'コンパニオンリモートサーバー';
	@override String get companionRemoteServerDescription => 'ネットワーク上のモバイルデバイスからこのアプリを操作できるようにする';
	@override String get autoPip => '自動ピクチャーインピクチャー';
	@override String get autoPipDescription => '再生中に離れるとピクチャーインピクチャーに入ります';
	@override String get matchContentFrameRate => 'コンテンツのフレームレートに合わせる';
	@override String get matchContentFrameRateDescription => '表示のリフレッシュレートを動画コンテンツに合わせます';
	@override String get matchRefreshRate => 'リフレッシュレートを合わせる';
	@override String get matchRefreshRateDescription => '全画面時に表示のリフレッシュレートを合わせます';
	@override String get matchDynamicRange => 'ダイナミックレンジを合わせる';
	@override String get matchDynamicRangeDescription => 'HDRコンテンツではHDRに切り替え、その後SDRに戻します';
	@override String get displaySwitchDelay => 'ディスプレイ切り替え遅延';
	@override String get tunneledPlayback => 'トンネル再生';
	@override String get tunneledPlaybackDescription => '動画トンネリングを使用します。HDR再生で画面が黒くなる場合は無効にしてください。';
	@override String get audioPassthrough => 'オーディオパススルー';
	@override String get audioPassthroughDescription => 'Dolby/DTS音声を再エンコードせずにレシーバーやテレビに送り、サラウンドを維持します。音が出ない場合は無効にしてください。';
	@override String get audioPassthroughDescriptionAppleTv => 'Dolby Digital Plus（Atmos含む）をビットストリームとしてシステムに渡します。DTSとTrueHDは引き続きマルチチャンネルPCMで再生されます。シーク時に短い音切れが発生することがあります。';
	@override String get audioDownmix => 'ステレオにダウンミックス';
	@override String get audioDownmixDescription => 'サラウンド音声をステレオスピーカーやヘッドホン用に2チャンネルへミックスします';
	@override String get downmixCenterBoost => 'センターチャンネルブースト';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'ブースト (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'ダウンミックス時の音量正規化';
	@override String get audioDownmixNormalizeDescription => 'クリッピングを防ぐためにミックス音量を下げます。オフにすると元の音量を維持します（大音量シーンで歪む場合があります）。';
	@override String get atmosDiagnostics => 'Atmos出力テスト';
	@override String get atmosDiagnosticsDescription => 'システムプレイヤーでテスト信号を再生してDolby Atmos出力を診断します';
	@override String get atmosTestHlsAtmos => 'Apple Atmosストリーム';
	@override String get atmosTestHlsAtmosDescription => '動作確認済みのDolby Atmosストリーム。レシーバーにDolby Atmosと表示されるはずです。';
	@override String get atmosTestHlsControl => 'Appleサラウンドストリーム';
	@override String get atmosTestHlsControlDescription => 'Atmosなしの比較用ストリーム。レシーバーにAtmosなしのサラウンドが表示されるはずです。';
	@override String get atmosTestRawStream => '生EAC3ストリーム';
	@override String get atmosTestRawStreamDescription => 'プレイヤー内のAtmos再生と同じ方式でテストファイルをストリーミングします。テストファイルのURLが必要です。';
	@override String get atmosTestRawFile => '生EAC3ファイル';
	@override String get atmosTestRawFileDescription => '長さが既知のテストファイルを再生します。テストファイルのURLが必要です。';
	@override String get atmosTestStop => 'テストを停止';
	@override String get atmosTestUrl => 'テストファイルのURL';
	@override String get atmosTestUrlDescription => '生の.ec3 Dolby AtmosファイルのHTTP URL（例: ffmpegで抽出）';
	@override String get atmosTestUrlMissing => '先にテストファイルのURLを設定してください';
	@override String get atmosTestStatus => 'ステータス';
	@override String get dvConversionMode => 'Dolby Vision 変換';
	@override String get dvConversionModeDescription => 'ExoPlayer が Dolby Vision Profile 7 ファイルを処理する方法を選択します。';
	@override String get dvConversionAuto => '自動';
	@override String get dvConversionNative => 'ネイティブ / 無効';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'デバイスの機能検出と通常のフォールバック動作を使用します';
	@override String get dvConversionNativeDescription => 'ネイティブ DV7 を強制し、DV 変換の再試行を抑制します';
	@override String get dvConversionDv81Description => 'Dolby Vision プロファイル 8.1 へのインライン RPU 変換を強制します';
	@override String get dvConversionHevcStripDescription => 'Dolby Vision の RPU/EL レイヤーを削除し、通常の HEVC として扱います';
	@override String get requireProfileSelectionOnOpen => 'アプリ起動時にプロフィールを確認';
	@override String get requireProfileSelectionOnOpenDescription => 'アプリを開くたびにプロフィール選択を表示';
	@override String get forceTvMode => 'TVモードを強制';
	@override String get forceTvModeDescription => 'TVレイアウトを強制します。自動検出しないデバイス向けです。再起動が必要です。';
	@override String get startInFullscreen => '全画面表示で起動';
	@override String get startInFullscreenDescription => '起動時にPlezyを全画面モードで開きます';
	@override String get exitFullscreenOnPlayerClose => 'プレイヤーを閉じたときに全画面を終了';
	@override String get exitFullscreenOnPlayerCloseDescription => 'ビデオプレイヤーを閉じたときに自動的に全画面モードを終了します';
	@override String get autoHidePerformanceOverlay => 'パフォーマンスオーバーレイを自動非表示';
	@override String get autoHidePerformanceOverlayDescription => '再生コントロールと一緒にパフォーマンスオーバーレイをフェードする';
	@override String get showNavBarLabels => 'ナビゲーションバーラベルを表示';
	@override String get showNavBarLabelsDescription => 'ナビゲーションバーアイコンの下にテキストラベルを表示';
	@override String get startupSection => '起動時のセクション';
	@override String get liveTvDefaultFavorites => 'お気に入りチャンネルをデフォルトに';
	@override String get liveTvDefaultFavoritesDescription => 'ライブTV を開いたときにお気に入りチャンネルのみ表示';
	@override String get display => 'ディスプレイ';
	@override String get homeScreen => 'ホーム画面';
	@override String get navigation => 'ナビゲーション';
	@override String get window => 'ウィンドウ';
	@override String get content => 'コンテンツ';
	@override String get player => 'プレーヤー';
	@override String get subtitlesAndConfig => '字幕と設定';
	@override String get seekAndTiming => 'シークとタイミング';
	@override String get behavior => '動作';
}

// Path: search
class _TranslationsSearchJa extends TranslationsSearchEn {
	_TranslationsSearchJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get hint => '映画、番組、音楽を検索...';
	@override String get tryDifferentTerm => '別の検索語をお試しください';
	@override String get searchYourMedia => 'メディアを検索';
	@override String get enterTitleActorOrKeyword => 'タイトル、俳優、またはキーワードを入力';
}

// Path: hotkeys
class _TranslationsHotkeysJa extends TranslationsHotkeysEn {
	_TranslationsHotkeysJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => '${actionName}のショートカットを設定';
	@override String get clearShortcut => 'ショートカットをクリア';
	@override String get noShortcutSet => 'ショートカット未設定';
	@override String get currentShortcut => '現在のショートカット:';
	@override String get pressToRecord => '選択してショートカットを記録';
	@override String get recordingShortcut => 'ショートカットを押してください';
	@override late final _TranslationsHotkeysActionsJa actions = _TranslationsHotkeysActionsJa._(_root);
}

// Path: fileInfo
class _TranslationsFileInfoJa extends TranslationsFileInfoEn {
	_TranslationsFileInfoJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'ファイル情報';
	@override String get video => '映像';
	@override String get audio => '音声';
	@override String get file => 'ファイル';
	@override String get advanced => '詳細';
	@override String get codec => 'コーデック';
	@override String get resolution => '解像度';
	@override String get bitrate => 'ビットレート';
	@override String get frameRate => 'フレームレート';
	@override String get aspectRatio => 'アスペクト比';
	@override String get profile => 'プロファイル';
	@override String get bitDepth => 'ビット深度';
	@override String get colorSpace => '色空間';
	@override String get colorRange => '色範囲';
	@override String get colorPrimaries => '色原色';
	@override String get chromaSubsampling => 'クロマサブサンプリング';
	@override String get channels => 'チャンネル';
	@override String get subtitles => '字幕';
	@override String get overallBitrate => '全体ビットレート';
	@override String get path => 'パス';
	@override String get size => 'サイズ';
	@override String get container => 'コンテナ';
	@override String get duration => '長さ';
	@override String get optimizedForStreaming => 'ストリーミング最適化';
	@override String get has64bitOffsets => '64ビットオフセット';
}

// Path: mediaMenu
class _TranslationsMediaMenuJa extends TranslationsMediaMenuEn {
	_TranslationsMediaMenuJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => '視聴済みにする';
	@override String get markAsUnwatched => '未視聴にする';
	@override String get removeFromContinueWatching => '視聴中から削除';
	@override String get viewDetails => '詳細を表示';
	@override String get goToSeries => 'シリーズへ移動';
	@override String get shufflePlay => 'シャッフル再生';
	@override String get shuffleNotAvailableOffline => 'オフラインではシャッフルを利用できません';
	@override String get fileInfo => 'ファイル情報';
	@override String get deleteFromServer => 'サーバーから削除';
	@override String get confirmDelete => 'このメディアとそのファイルをサーバーから削除しますか？';
	@override String get deleteMultipleWarning => 'すべてのエピソードとそのファイルが含まれます。';
	@override String get mediaDeletedSuccessfully => 'メディアアイテムを正常に削除しました';
	@override String get mediaFailedToDelete => 'メディアアイテムの削除に失敗しました';
	@override String get rate => '評価';
	@override String get playFromBeginning => '最初から再生';
	@override String get playVersion => 'バージョンを再生...';
}

// Path: rateSheet
class _TranslationsRateSheetJa extends TranslationsRateSheetEn {
	_TranslationsRateSheetJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '評価';
	@override String get server => 'サーバー';
	@override String get favorite => 'お気に入り';
	@override String get favorited => 'お気に入りに追加済み';
	@override String get saved => '保存済み';
	@override String get notAvailable => '一致なし';
	@override String get noConnectedServices => '評価するには、設定でサービスを接続してください。';
}

// Path: accessibility
class _TranslationsAccessibilityJa extends TranslationsAccessibilityEn {
	_TranslationsAccessibilityJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}、映画';
	@override String mediaCardShow({required Object title}) => '${title}、テレビ番組';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}、${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}、${seasonInfo}';
	@override String get mediaCardWatched => '視聴済み';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent}パーセント視聴済み';
	@override String get mediaCardUnwatched => '未視聴';
	@override String get tapToPlay => 'タップして再生';
	@override String get decrease => '下げる';
	@override String get increase => '上げる';
	@override String decreaseValue({required Object label}) => '${label}を下げる';
	@override String increaseValue({required Object label}) => '${label}を上げる';
	@override String get hue => '色相';
	@override String get saturation => '彩度';
	@override String get brightness => '明るさ';
	@override String get hexColor => '16進カラー';
	@override String get expandText => 'テキストを展開';
	@override String get collapseText => 'テキストを折りたたむ';
}

// Path: tooltips
class _TranslationsTooltipsJa extends TranslationsTooltipsEn {
	_TranslationsTooltipsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'シャッフル再生';
	@override String get playTrailer => '予告編を再生';
	@override String get markAsWatched => '視聴済みにする';
	@override String get markAsUnwatched => '未視聴にする';
}

// Path: videoControls
class _TranslationsVideoControlsJa extends TranslationsVideoControlsEn {
	_TranslationsVideoControlsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => '音声';
	@override String get subtitlesLabel => '字幕';
	@override String get resetToZero => '0msにリセット';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label}遅く再生';
	@override String playsEarlier({required Object label}) => '${label}早く再生';
	@override String get noOffset => 'オフセットなし';
	@override String get letterbox => 'レターボックス';
	@override String get fillScreen => '画面を埋める';
	@override String get stretch => '引き延ばす';
	@override String get lockRotation => '回転をロック';
	@override String get unlockRotation => '回転のロックを解除';
	@override String get timerActive => 'タイマー動作中';
	@override String playbackWillPauseIn({required Object duration}) => '再生は${duration}後に一時停止します';
	@override String get sleepTimerEndOfVideo => '現在の動画の最後';
	@override String get sleepTimerStopAtHeader => '停止のタイミング';
	@override String get sleepTimerDurationHeader => 'タイマー';
	@override String get playbackWillPauseAtEnd => '再生はこの動画の最後に一時停止します';
	@override String get stillWatching => 'まだ視聴中ですか？';
	@override String pausingIn({required Object seconds}) => '${seconds}秒後に一時停止';
	@override String get continueWatching => '続ける';
	@override String get autoPlayNext => '次を自動再生';
	@override String get playNext => '次を再生';
	@override String get playButton => '再生';
	@override String get pauseButton => '一時停止';
	@override String seekBackwardButton({required Object seconds}) => '${seconds}秒戻る';
	@override String seekForwardButton({required Object seconds}) => '${seconds}秒進む';
	@override String get previousButton => '前のエピソード';
	@override String get nextButton => '次のエピソード';
	@override String get previousChapterButton => '前のチャプター';
	@override String get nextChapterButton => '次のチャプター';
	@override String get muteButton => 'ミュート';
	@override String get unmuteButton => 'ミュート解除';
	@override String get settingsButton => '再生設定';
	@override String get tracksButton => '音声と字幕';
	@override String get chaptersButton => 'チャプター';
	@override String get versionQualityButton => 'バージョンと画質';
	@override String get versionColumnHeader => 'バージョン';
	@override String get qualityColumnHeader => '画質';
	@override String get qualityOriginal => 'オリジナル';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'トランスコードは利用できません — オリジナル画質で再生中';
	@override String get pipButton => 'ピクチャーインピクチャーモード';
	@override String get aspectRatioButton => 'アスペクト比';
	@override String get ambientLighting => 'アンビエントライティング';
	@override String get fullscreenButton => 'フルスクリーンに入る';
	@override String get exitFullscreenButton => 'フルスクリーンを終了';
	@override String get alwaysOnTopButton => '常に前面に表示';
	@override String get rotationLockButton => '回転ロック';
	@override String get lockScreen => '画面をロック';
	@override String get screenLockButton => '画面ロック';
	@override String get longPressToUnlock => '長押しでロック解除';
	@override String get timelineSlider => '動画タイムライン';
	@override String get volumeSlider => '音量レベル';
	@override String endsAt({required Object time}) => '${time}に終了';
	@override String get pipActive => 'ピクチャーインピクチャーで再生中';
	@override String get pipFailed => 'ピクチャーインピクチャーの開始に失敗しました';
	@override String get screenshotSaved => 'スクリーンショットを保存しました';
	@override String zoomPercent({required Object percent}) => 'ズーム ${percent}%';
	@override late final _TranslationsVideoControlsPipErrorsJa pipErrors = _TranslationsVideoControlsPipErrorsJa._(_root);
	@override String get chapters => 'チャプター';
	@override String get noChaptersAvailable => 'チャプターがありません';
	@override String get queue => 'キュー';
	@override String get noQueueItems => 'キューにアイテムがありません';
	@override String get searchSubtitles => '字幕を検索';
	@override String get language => '言語';
	@override String get noSubtitlesFound => '字幕が見つかりません';
	@override String get downloadedSubtitle => 'ダウンロード済み';
	@override String get noSubtitlesAvailable => '利用可能な字幕はありません';
	@override String get noAudioTracksAvailable => '利用可能な音声トラックはありません';
	@override String get noTracksAvailable => '利用可能なトラックはありません';
	@override String get subtitleDownloaded => '字幕をダウンロードしました';
	@override String get subtitleDownloadFailed => '字幕のダウンロードに失敗しました';
	@override String get searchLanguages => '言語を検索...';
}

// Path: messages
class _TranslationsMessagesJa extends TranslationsMessagesEn {
	_TranslationsMessagesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => '視聴済みにしました';
	@override String get markedAsUnwatched => '未視聴にしました';
	@override String get markedAsWatchedOffline => '視聴済みにしました（オンライン時に同期）';
	@override String get markedAsUnwatchedOffline => '未視聴にしました（オンライン時に同期）';
	@override String autoRemovedWatchedDownload({required Object title}) => '自動削除: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		other: '視聴済みダウンロードを${n}件自動削除しました',
	);
	@override String get removedFromContinueWatching => '視聴中から削除しました';
	@override String errorLoading({required Object error}) => 'エラー: ${error}';
	@override String get streamInterrupted => 'ストリームが中断されました。再生を押すかシークして再試行してください。';
	@override String get liveStreamInterrupted => 'ライブストリームが中断されました。再生を押して再試行してください。';
	@override String get fileInfoNotAvailable => 'ファイル情報が利用できません';
	@override String errorLoadingFileInfo({required Object error}) => 'ファイル情報の読み込みエラー: ${error}';
	@override String get errorLoadingSeries => 'シリーズの読み込みエラー';
	@override String get musicNotSupported => '音楽の再生はまだサポートされていません';
	@override String get noDescriptionAvailable => '説明はありません';
	@override String get noProfilesAvailable => '利用可能なプロフィールがありません';
	@override String get contactAdminForProfiles => 'プロファイルを追加するにはサーバー管理者に連絡してください';
	@override String get unableToDetermineLibrarySection => 'このアイテムのライブラリセクションを判別できません';
	@override String get logsCleared => 'ログをクリアしました';
	@override String get logsCopied => 'ログをクリップボードにコピーしました';
	@override String get noLogsAvailable => 'ログがありません';
	@override String libraryScanning({required Object title}) => '"${title}"をスキャン中...';
	@override String libraryScanStarted({required Object title}) => '"${title}"のライブラリスキャンを開始しました';
	@override String libraryScanFailed({required Object error}) => 'ライブラリのスキャンに失敗しました: ${error}';
	@override String metadataRefreshing({required Object title}) => '"${title}"のメタデータを更新中...';
	@override String metadataRefreshStarted({required Object title}) => '"${title}"のメタデータ更新を開始しました';
	@override String metadataRefreshFailed({required Object error}) => 'メタデータの更新に失敗しました: ${error}';
	@override String get logoutConfirm => 'ログアウトしてもよろしいですか？';
	@override String get noSeasonsFound => 'シーズンが見つかりません';
	@override String get seasonsLoadFailed => 'シーズンを読み込めませんでした';
	@override String get noEpisodesFound => '最初のシーズンにエピソードが見つかりません';
	@override String get noEpisodesFoundGeneral => 'エピソードが見つかりません';
	@override String get episodesLoadFailed => 'エピソードを読み込めませんでした';
	@override String get noResultsFound => '結果が見つかりません';
	@override String sleepTimerSet({required Object label}) => 'スリープタイマーを${label}に設定しました';
	@override String get noItemsAvailable => 'アイテムがありません';
	@override String get failedToCreatePlayQueueNoItems => '再生キューの作成に失敗しました - アイテムがありません';
	@override String failedPlayback({required Object action, required Object error}) => '${action}に失敗しました: ${error}';
	@override String get switchingToCompatiblePlayer => '互換プレーヤーに切替中...';
	@override String get serverLimitTitle => '再生に失敗しました';
	@override String get serverLimitBody => 'サーバーエラー（HTTP 500）。帯域幅/トランスコード制限により拒否された可能性があります。所有者に調整を依頼してください。';
	@override String get logsUploaded => 'ログをアップロードしました';
	@override String get logsUploadFailed => 'ログのアップロードに失敗しました';
	@override String get logId => 'ログID';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingJa extends TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get text => 'テキスト';
	@override String get border => '枠線';
	@override String get background => '背景';
	@override String get fontSize => 'フォントサイズ';
	@override String get textColor => 'テキストの色';
	@override String get borderSize => '枠線サイズ';
	@override String get borderColor => '枠線の色';
	@override String get backgroundOpacity => '背景の不透明度';
	@override String get backgroundColor => '背景色';
	@override String get position => '位置';
	@override String get assOverride => 'ASSオーバーライド';
	@override String get overrideScale => '拡大縮小';
	@override String get overrideForce => '強制';
	@override String get overrideStrip => 'スタイルを削除';
	@override String get positionTop => '上';
	@override String get positionBottom => '下';
	@override String get bold => '太字';
	@override String get italic => '斜体';
	@override String get renderResolution => 'レンダリング解像度';
	@override String get renderResolutionScreen => '画面解像度';
	@override String get renderResolutionVideo => '動画解像度';
}

// Path: mpvConfig
class _TranslationsMpvConfigJa extends TranslationsMpvConfigEn {
	_TranslationsMpvConfigJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => '高度な動画プレーヤー設定';
	@override String get presets => 'プリセット';
	@override String get noPresets => '保存済みプリセットがありません';
	@override String get saveAsPreset => 'プリセットとして保存...';
	@override String get presetName => 'プリセット名';
	@override String get presetNameHint => 'プリセットの名前を入力';
	@override String get loadPreset => '読み込み';
	@override String get deletePreset => '削除';
	@override String get presetSaved => 'プリセットを保存しました';
	@override String get presetLoaded => 'プリセットを読み込みました';
	@override String get presetDeleted => 'プリセットを削除しました';
	@override String get confirmDeletePreset => 'このプリセットを削除してもよろしいですか？';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comment';
}

// Path: dialog
class _TranslationsDialogJa extends TranslationsDialogEn {
	_TranslationsDialogJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => '操作の確認';
}

// Path: profiles
class _TranslationsProfilesJa extends TranslationsProfilesEn {
	_TranslationsProfilesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Plezyプロファイルを追加';
	@override String get switchingProfile => 'プロファイルを切り替え中…';
	@override String get deleteThisProfileTitle => 'このプロファイルを削除しますか？';
	@override String deleteThisProfileMessage({required Object displayName}) => '${displayName}を削除します。接続には影響しません。';
	@override String get active => 'アクティブ';
	@override String get manage => '管理';
	@override String get delete => '削除';
	@override String get signOut => 'サインアウト';
	@override String get signOutPlexTitle => 'Plex からサインアウトしますか？';
	@override String signOutPlexMessage({required Object displayName}) => '${displayName}とすべてのPlex Homeユーザーを削除しますか？いつでも再サインインできます。';
	@override String get signedOutPlex => 'Plex からサインアウトしました。';
	@override String get signOutFailed => 'サインアウトに失敗しました。';
	@override String get sectionTitle => 'プロファイル';
	@override String get summarySingle => 'プロファイルを追加して、管理対象ユーザーとローカルIDを混在させます';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count}個のプロファイル · アクティブ: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count}個のプロファイル';
	@override String get removeConnectionTitle => '接続を削除しますか？';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => '${displayName}の${connectionLabel}へのアクセスを削除します。他のプロフィールには残ります。';
	@override String get deleteProfileTitle => 'プロファイルを削除しますか？';
	@override String deleteProfileMessage({required Object displayName}) => '${displayName}とその接続を削除します。サーバーは引き続き利用できます。';
	@override String get profileNameLabel => 'プロファイル名';
	@override String get pinProtectionLabel => 'PIN保護';
	@override String get pinManagedByPlex => 'PINはPlexで管理されています。plex.tvで編集してください。';
	@override String get noPinSetEditOnPlex => 'PINが設定されていません。要求するには、plex.tvでHomeユーザーを編集してください。';
	@override String get setPin => 'PINを設定';
	@override String get setPinTitle => 'PINを設定';
	@override String get confirmPinTitle => 'PINを確認';
	@override String get pinSet => 'PIN設定済み';
	@override String get changePin => '変更';
	@override String get removePin => '削除';
	@override String get connectionsLabel => '接続';
	@override String get add => '追加';
	@override String get deleteProfileButton => 'プロファイルを削除';
	@override String get noConnectionsHint => '接続がありません — このプロファイルを使うには1つ追加してください。';
	@override String get noConnections => '接続がありません';
	@override String get plexHomeAccount => 'Plex Homeアカウント';
	@override String get connectionDefault => 'デフォルト';
	@override String connectionAs({required Object displayName}) => '${displayName}として';
	@override String get makeDefault => 'デフォルトに設定';
	@override String get removeConnection => '削除';
	@override String get profileRenamed => 'プロフィール名を変更しました。';
	@override String borrowAddTo({required Object displayName}) => '${displayName}に追加';
	@override String get borrowExplain => '別のプロフィールの接続を借用します。PIN保護されたプロフィールにはPINが必要です。';
	@override String get borrowEmpty => 'まだ借りるものがありません。';
	@override String get borrowEmptySubtitle => 'まず別のプロフィールにPlexまたはJellyfinを接続してください。';
	@override String borrowFromProfile({required Object displayName}) => '${displayName}から';
	@override String get borrowConnectionBorrowed => '接続を借用しました。';
	@override String get borrowFailed => '接続を借用できませんでした。';
	@override String get incorrectPin => 'PINが正しくありません。';
	@override String get incorrectPinTryAgain => 'PINが正しくありません。もう一度お試しください。';
	@override String get sourceProfileMissingParentAccount => 'ソースプロフィールに親アカウントがありません。';
	@override String get failedToLoadHomeUsers => 'Plex Homeユーザーを読み込めませんでした。接続を確認して、もう一度お試しください。';
	@override String get failedToVerifyPin => 'PINを確認できませんでした。';
	@override String get newProfile => '新しいプロファイル';
	@override String get profileNameHint => '例：ゲスト、キッズ、ファミリールーム';
	@override String get pinProtectionOptional => 'PIN保護（オプション）';
	@override String get pinExplain => 'プロフィール切り替えには4桁のPINが必要です。';
	@override String get continueButton => '続ける';
	@override String get pinsDontMatch => 'PINが一致しません';
}

// Path: connections
class _TranslationsConnectionsJa extends TranslationsConnectionsEn {
	_TranslationsConnectionsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '接続';
	@override String get addConnection => '接続を追加';
	@override String get addConnectionSubtitleNoProfile => 'Plexでサインインするか、Jellyfinサーバーに接続';
	@override String addConnectionSubtitleScoped({required Object displayName}) => '${displayName}に追加: Plex、Jellyfin、または別プロフィールの接続';
	@override String sessionExpiredOne({required Object name}) => '${name} のセッションの有効期限が切れました';
	@override String sessionExpiredMany({required Object count}) => '${count} 台のサーバーのセッションの有効期限が切れました';
	@override String get signInAgain => '再度サインイン';
	@override String get editJellyfinTitle => 'Jellyfin接続を編集';
	@override String editJellyfinIntro({required Object serverName}) => '${serverName} のURLを追加または削除します。Plezyは到達可能なURLのうち最も低遅延のものを使用します。';
}

// Path: discover
class _TranslationsDiscoverJa extends TranslationsDiscoverEn {
	_TranslationsDiscoverJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '探す';
	@override String get noContentAvailable => 'コンテンツがありません';
	@override String get addMediaToLibraries => 'ライブラリにメディアを追加してください';
	@override String get continueWatching => '視聴を続ける';
	@override String continueWatchingIn({required Object library}) => '${library}の視聴を続ける';
	@override String get nextUp => '次のエピソード';
	@override String nextUpIn({required Object library}) => '${library}の次のエピソード';
	@override String get recentlyAdded => '最近追加';
	@override String recentlyAddedIn({required Object library}) => '${library}に最近追加';
	@override String latestAlbumsIn({required Object library}) => '${library}の最新アルバム';
	@override String recentlyPlayedIn({required Object library}) => '${library}で最近再生';
	@override String mostPlayedIn({required Object library}) => '${library}で最も再生';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'あらすじ';
	@override String get cast => 'キャスト';
	@override String get extras => '予告編とエクストラ';
	@override String get studio => 'スタジオ';
	@override String get rating => '評価';
	@override String get movie => '映画';
	@override String get tvShow => 'テレビ番組';
	@override String minutesLeft({required Object minutes}) => '残り${minutes}分';
	@override String get moreLikeThis => '似ている作品';
}

// Path: errors
class _TranslationsErrorsJa extends TranslationsErrorsEn {
	_TranslationsErrorsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => '検索に失敗しました: ${error}';
	@override String connectionTimeout({required Object context}) => '${context}の読み込み中に接続がタイムアウトしました';
	@override String get connectionFailed => 'メディアサーバーに接続できません';
	@override String unableToLoad({required Object context}) => '${context}を読み込めませんでした。もう一度お試しください。';
	@override String get noClientAvailable => 'クライアントが利用できません';
	@override String get pleaseEnterToken => 'トークンを入力してください';
	@override String get invalidToken => '無効なトークン';
	@override String failedToVerifyToken({required Object error}) => 'トークンの検証に失敗しました: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => '${displayName}への切替に失敗しました';
	@override String failedToDeleteProfile({required Object displayName}) => '${displayName}の削除に失敗しました';
	@override String get failedToRate => '評価を更新できませんでした';
}

// Path: libraries
class _TranslationsLibrariesJa extends TranslationsLibrariesEn {
	_TranslationsLibrariesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'ライブラリ';
	@override String get fallbackTitle => 'ライブラリ';
	@override String get scanLibraryFiles => 'ライブラリファイルをスキャン';
	@override String get scanLibrary => 'ライブラリをスキャン';
	@override String get analyze => '解析';
	@override String get analyzeLibrary => 'ライブラリを解析';
	@override String get refreshMetadata => 'メタデータを更新';
	@override String get emptyTrash => 'ゴミ箱を空にする';
	@override String emptyingTrash({required Object title}) => '"${title}"のゴミ箱を空にしています...';
	@override String trashEmptied({required Object title}) => '"${title}"のゴミ箱を空にしました';
	@override String failedToEmptyTrash({required Object error}) => 'ゴミ箱を空にできませんでした: ${error}';
	@override String analyzing({required Object title}) => '"${title}"を解析中...';
	@override String analysisStarted({required Object title}) => '"${title}"の解析を開始しました';
	@override String failedToAnalyze({required Object error}) => 'ライブラリの解析に失敗しました: ${error}';
	@override String get noLibrariesFound => 'ライブラリが見つかりません';
	@override String get allLibrariesHidden => 'すべてのライブラリが非表示です';
	@override String hiddenLibrariesCount({required Object count}) => '非表示のライブラリ (${count})';
	@override String get thisLibraryIsEmpty => 'このライブラリは空です';
	@override String get noItemsMatchFilters => '有効なフィルターに一致する項目はありません';
	@override String get resetFilters => 'フィルターをリセット';
	@override String get all => 'すべて';
	@override String get clearAll => 'すべてクリア';
	@override String scanLibraryConfirm({required Object title}) => '"${title}"をスキャンしてもよろしいですか？';
	@override String analyzeLibraryConfirm({required Object title}) => '"${title}"を解析してもよろしいですか？';
	@override String refreshMetadataConfirm({required Object title}) => '"${title}"のメタデータを更新してもよろしいですか？';
	@override String emptyTrashConfirm({required Object title}) => '"${title}"のゴミ箱を空にしてもよろしいですか？';
	@override String get manageLibraries => 'ライブラリを管理';
	@override String get sort => '並べ替え';
	@override String get sortBy => '並べ替え順';
	@override String get filters => 'フィルター';
	@override String get confirmActionMessage => 'この操作を実行してもよろしいですか？';
	@override String get showLibrary => 'ライブラリを表示';
	@override String get hideLibrary => 'ライブラリを非表示';
	@override String get libraryOptions => 'ライブラリオプション';
	@override String get content => 'ライブラリコンテンツ';
	@override String get selectLibrary => 'ライブラリを選択';
	@override String filtersWithCount({required Object count}) => 'フィルター (${count})';
	@override String get noRecommendations => 'おすすめがありません';
	@override String get noCollections => 'このライブラリにコレクションがありません';
	@override String get noFoldersFound => 'フォルダが見つかりません';
	@override String get folders => 'フォルダ';
	@override late final _TranslationsLibrariesTabsJa tabs = _TranslationsLibrariesTabsJa._(_root);
	@override late final _TranslationsLibrariesGroupingsJa groupings = _TranslationsLibrariesGroupingsJa._(_root);
	@override late final _TranslationsLibrariesFilterCategoriesJa filterCategories = _TranslationsLibrariesFilterCategoriesJa._(_root);
	@override late final _TranslationsLibrariesSortLabelsJa sortLabels = _TranslationsLibrariesSortLabelsJa._(_root);
}

// Path: about
class _TranslationsAboutJa extends TranslationsAboutEn {
	_TranslationsAboutJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'アプリについて';
	@override String get openSourceLicenses => 'オープンソースライセンス';
	@override String versionLabel({required Object version}) => 'バージョン ${version}';
	@override String get appDescription => 'Flutter製の美しいPlex・Jellyfinクライアント';
	@override String get viewLicensesDescription => 'サードパーティライブラリのライセンスを表示';
}

// Path: serverSelection
class _TranslationsServerSelectionJa extends TranslationsServerSelectionEn {
	_TranslationsServerSelectionJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => '${username} (${email})のサーバーが見つかりません';
	@override String failedToLoadServers({required Object error}) => 'サーバーの読み込みに失敗しました: ${error}';
}

// Path: hubDetail
class _TranslationsHubDetailJa extends TranslationsHubDetailEn {
	_TranslationsHubDetailJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'タイトル';
	@override String get releaseYear => '公開年';
	@override String get dateAdded => '追加日';
	@override String get rating => '評価';
	@override String get noItemsFound => 'アイテムが見つかりません';
}

// Path: logs
class _TranslationsLogsJa extends TranslationsLogsEn {
	_TranslationsLogsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'ログをクリア';
	@override String get copyLogs => 'ログをコピー';
	@override String get uploadLogs => 'ログをアップロード';
}

// Path: licenses
class _TranslationsLicensesJa extends TranslationsLicensesEn {
	_TranslationsLicensesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => '関連パッケージ';
	@override String get license => 'ライセンス';
	@override String licenseNumber({required Object number}) => 'ライセンス ${number}';
	@override String licensesCount({required Object count}) => '${count}件のライセンス';
}

// Path: navigation
class _TranslationsNavigationJa extends TranslationsNavigationEn {
	_TranslationsNavigationJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'ライブラリ';
	@override String get downloads => 'ダウンロード';
	@override String get liveTv => 'ライブTV';
	@override String get explore => '探索';
}

// Path: explore
class _TranslationsExploreJa extends TranslationsExploreEn {
	_TranslationsExploreJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '探索';
	@override String get selectSource => 'ソースを選択';
	@override late final _TranslationsExploreRowsJa rows = _TranslationsExploreRowsJa._(_root);
	@override late final _TranslationsExploreStatusJa status = _TranslationsExploreStatusJa._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		other: '${n} 話',
	);
	@override String get cast => 'キャスト';
	@override String get characters => 'キャラクター';
	@override String get addToWatchlist => 'ウォッチリストに追加';
	@override String get removeFromWatchlist => 'ウォッチリストから削除';
	@override String get watchlistUpdateFailed => 'ウォッチリストを更新できませんでした';
	@override String get notInLibrary => 'ライブラリにありません';
	@override String get inTheseLibraries => 'これらのライブラリにあります';
	@override String get checkingLibrary => 'ライブラリを確認中...';
	@override String get emptyTitle => 'まだ何もありません';
	@override String emptyMessage({required Object source}) => '${source}にコンテンツが追加されると、ここに表示されます。';
	@override String searchHint({required Object source}) => '${source} で検索';
	@override String searchEmpty({required Object query}) => '「${query}」の結果が見つかりません';
	@override String searchPrompt({required Object source}) => '${source} で映画やテレビ番組を検索します。';
	@override String get searchFailed => '検索に失敗しました。接続を確認してもう一度お試しください。';
}

// Path: liveTv
class _TranslationsLiveTvJa extends TranslationsLiveTvEn {
	_TranslationsLiveTvJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'ライブTV';
	@override String get guide => '番組表';
	@override String get noChannels => 'チャンネルがありません';
	@override String get noDvr => 'どのサーバーにもDVRが設定されていません';
	@override String get serverUnavailable => 'ライブTVサーバーを利用できません。';
	@override String get serverNotConnected => 'ライブTVサーバーに接続されていません。';
	@override String get noPrograms => '番組データがありません';
	@override String get liveStreamFailed => 'ライブストリームに失敗しました';
	@override String get unknownProgram => '不明な番組';
	@override String get unknownHub => '不明';
	@override String get unknownError => '不明なエラー';
	@override String channelNumber({required Object number}) => 'チャンネル ${number}';
	@override String get unknownChannel => '不明なチャンネル';
	@override String get live => 'ライブ';
	@override String get reloadGuide => '番組表を再読込';
	@override String get now => '現在';
	@override String get today => '今日';
	@override String get tomorrow => '明日';
	@override String get midnight => '深夜';
	@override String get overnight => '深夜';
	@override String get morning => '朝';
	@override String get daytime => '昼';
	@override String get evening => '夕方';
	@override String get lateNight => '深夜';
	@override String get whatsOn => '放送中';
	@override String get watchChannel => 'チャンネルを視聴';
	@override String get favorites => 'お気に入り';
	@override String get reorderFavorites => 'お気に入りを並べ替え';
	@override String get favoritesLoadFailed => 'お気に入りを読み込めませんでした。接続を確認してもう一度お試しください。';
	@override String get joinSession => '進行中のセッションに参加';
	@override String watchFromStart({required Object minutes}) => '最初から視聴（${minutes}分前に開始）';
	@override String get watchLive => 'ライブで視聴';
	@override String get goToLive => 'ライブに移動';
	@override String get record => '録画';
	@override String get recordEpisode => 'このエピソードを録画';
	@override String get recordSeries => 'シリーズを録画';
	@override String get recordOptions => '録画オプション';
	@override String get saveTo => '保存先';
	@override String get recordings => '録画';
	@override String get scheduledRecordings => '予約';
	@override String get recordingRules => '録画ルール';
	@override String get noScheduledRecordings => '予約された録画はありません';
	@override String get manageRecording => '録画を管理';
	@override String get cancelRecording => '録画をキャンセル';
	@override String get cancelRecordingTitle => 'この録画をキャンセルしますか？';
	@override String cancelRecordingMessage({required Object title}) => '${title} は録画されなくなります。';
	@override String get deleteRule => 'ルールを削除';
	@override String get deleteRuleTitle => '録画ルールを削除しますか？';
	@override String deleteRuleMessage({required Object title}) => '${title} の今後のエピソードは録画されません。';
	@override String get recordingScheduled => '録画を予約しました';
	@override String get alreadyScheduled => 'この番組はすでに予約されています';
	@override String get dvrAdminRequired => 'DVR 設定には管理者アカウントが必要です';
	@override String get recordingFailed => '録画を予約できませんでした';
	@override String get recordingTargetMissing => '録画ライブラリを特定できませんでした';
	@override String get recordNotAvailable => 'この番組は録画できません';
	@override String get recordingCancelled => '録画をキャンセルしました';
	@override String get recordingRuleDeleted => '録画ルールを削除しました';
	@override String get processRecordingRules => 'ルールを再評価';
	@override String get recordingInProgress => '録画中';
	@override String recordingsCount({required Object count}) => '${count} 件予約済み';
	@override String get editRule => 'ルールを編集';
	@override String get editRuleAction => '編集';
	@override String get recordingRuleUpdated => '録画ルールを更新しました';
	@override String get guideReloadRequested => 'ガイドの更新を要求しました';
	@override String get rulesProcessRequested => 'ルールの再評価を要求しました';
	@override String get recordShow => '番組を録画';
}

// Path: collections
class _TranslationsCollectionsJa extends TranslationsCollectionsEn {
	_TranslationsCollectionsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'コレクション';
	@override String get collection => 'コレクション';
	@override String get empty => 'コレクションは空です';
	@override String get deleteCollection => 'コレクションを削除';
	@override String deleteConfirm({required Object title}) => '「${title}」を削除しますか？元に戻せません。';
	@override String get deleted => 'コレクションを削除しました';
	@override String get deleteFailed => 'コレクションの削除に失敗しました';
	@override String deleteFailedWithError({required Object error}) => 'コレクションの削除に失敗しました: ${error}';
	@override String get selectCollection => 'コレクションを選択';
	@override String get collectionName => 'コレクション名';
	@override String get enterCollectionName => 'コレクション名を入力';
	@override String get addedToCollection => 'コレクションに追加しました';
	@override String get errorAddingToCollection => 'コレクションへの追加に失敗しました';
	@override String get created => 'コレクションを作成しました';
	@override String get removeFromCollection => 'コレクションから削除';
	@override String removeFromCollectionConfirm({required Object title}) => '"${title}"をこのコレクションから削除しますか？';
	@override String get removedFromCollection => 'コレクションから削除しました';
	@override String get removeFromCollectionFailed => 'コレクションからの削除に失敗しました';
	@override String removeFromCollectionError({required Object error}) => 'コレクションからの削除エラー: ${error}';
	@override String get searchCollections => 'コレクションを検索...';
}

// Path: playlists
class _TranslationsPlaylistsJa extends TranslationsPlaylistsEn {
	_TranslationsPlaylistsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'プレイリスト';
	@override String get playlist => 'プレイリスト';
	@override String get noPlaylists => 'プレイリストが見つかりません';
	@override String get create => 'プレイリストを作成';
	@override String get playlistName => 'プレイリスト名';
	@override String get enterPlaylistName => 'プレイリスト名を入力';
	@override String get delete => 'プレイリストを削除';
	@override String get removeItem => 'プレイリストから削除';
	@override String get smartPlaylist => 'スマートプレイリスト';
	@override String itemCount({required Object count}) => '${count}アイテム';
	@override String get oneItem => '1アイテム';
	@override String get emptyPlaylist => 'このプレイリストは空です';
	@override String get deleteConfirm => 'プレイリストを削除しますか？';
	@override String deleteMessage({required Object name}) => '"${name}"を削除してもよろしいですか？';
	@override String get created => 'プレイリストを作成しました';
	@override String get deleted => 'プレイリストを削除しました';
	@override String get itemAdded => 'プレイリストに追加しました';
	@override String get itemRemoved => 'プレイリストから削除しました';
	@override String get selectPlaylist => 'プレイリストを選択';
	@override String get searchPlaylists => 'プレイリストを検索...';
	@override String get errorCreating => 'プレイリストの作成に失敗しました';
	@override String get errorDeleting => 'プレイリストの削除に失敗しました';
	@override String get errorLoading => 'プレイリストの読み込みに失敗しました';
	@override String get errorAdding => 'プレイリストへの追加に失敗しました';
	@override String get errorReordering => 'プレイリストアイテムの並べ替えに失敗しました';
	@override String get errorRemoving => 'プレイリストからの削除に失敗しました';
}

// Path: music
class _TranslationsMusicJa extends TranslationsMusicEn {
	_TranslationsMusicJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'アルバムへ移動';
	@override String get goToArtist => 'アーティストへ移動';
	@override String get instantMix => 'インスタントミックス';
	@override String get playNext => '次に再生';
	@override String get addToQueue => 'キューに追加';
	@override String discNumber({required Object n}) => 'ディスク ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		other: '${n} 曲',
	);
	@override String get nowPlaying => '再生中';
	@override String playingFrom({required Object title}) => '${title} から再生';
	@override String get queue => '再生キュー';
	@override String get clearQueue => 'キューをクリア';
	@override String get lyrics => '歌詞';
	@override String get noLyrics => '歌詞がありません';
	@override String get sleepTimer => 'スリープタイマー';
	@override String get sleepTimerEndOfTrack => '曲の終わり';
	@override String sleepTimerMinutes({required Object n}) => '${n} 分';
	@override String get stopPlayback => '再生を停止';
	@override String get previousTrack => '前の曲';
	@override String get nextTrack => '次の曲';
	@override String get repeat => 'リピート';
	@override String get repeatAll => '全曲リピート';
	@override String get repeatOne => '1曲リピート';
}

// Path: watchTogether
class _TranslationsWatchTogetherJa extends TranslationsWatchTogetherEn {
	_TranslationsWatchTogetherJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '一緒に見る';
	@override String get description => '友達や家族と同期してコンテンツを視聴';
	@override String get createSession => 'セッションを作成';
	@override String get creating => '作成中...';
	@override String get joinSession => 'セッションに参加';
	@override String get joining => '参加中...';
	@override String get controlMode => 'コントロールモード';
	@override String get controlModeQuestion => '誰が再生を制御できますか？';
	@override String get hostOnly => 'ホストのみ';
	@override String get anyone => '全員';
	@override String get hostingSession => 'セッションをホスト中';
	@override String get inSession => 'セッション中';
	@override String get sessionCode => 'セッションコード';
	@override String get openSessionControls => '「一緒に見る」セッションのコントロールを開く';
	@override String get copySessionCode => 'セッションコードをコピー';
	@override String get hostControlsPlayback => 'ホストが再生を制御';
	@override String get anyoneCanControl => '全員が再生を制御可能';
	@override String get hostControls => 'ホストが制御';
	@override String get anyoneControls => '全員が制御';
	@override String get participants => '参加者';
	@override String get host => 'ホスト';
	@override String get hostBadge => 'HOST';
	@override String get youAreHost => 'あなたはホストです';
	@override String get watchingWithOthers => '他の人と視聴中';
	@override String get endSession => 'セッションを終了';
	@override String get leaveSession => 'セッションを退出';
	@override String get endSessionQuestion => 'セッションを終了しますか？';
	@override String get leaveSessionQuestion => 'セッションを退出しますか？';
	@override String get endSessionConfirm => 'すべての参加者のセッションが終了します。';
	@override String get leaveSessionConfirm => 'セッションから退出されます。';
	@override String get endSessionConfirmOverlay => 'すべての参加者の視聴セッションが終了します。';
	@override String get leaveSessionConfirmOverlay => '視聴セッションから切断されます。';
	@override String get end => '終了';
	@override String get leave => '退出';
	@override String get syncing => '同期中...';
	@override String get joinWatchSession => '視聴セッションに参加';
	@override String get enterCodeHint => '5文字のコードを入力';
	@override String get pasteFromClipboard => 'クリップボードから貼り付け';
	@override String get pleaseEnterCode => 'セッションコードを入力してください';
	@override String get codeMustBe5Chars => 'セッションコードは5文字である必要があります';
	@override String get joinInstructions => '参加するにはホストのセッションコードを入力してください。';
	@override String get failedToCreate => 'セッションの作成に失敗しました';
	@override String get failedToJoin => 'セッションへの参加に失敗しました';
	@override String get sessionCodeCopied => 'セッションコードをクリップボードにコピーしました';
	@override String get relayUnreachable => 'リレーサーバーに到達できません。ISPのブロックによりWatch Togetherが使えない可能性があります。';
	@override String get reconnectingToHost => 'ホストに再接続中...';
	@override String get currentPlayback => '現在の再生';
	@override String get joinCurrentPlayback => '現在の再生に参加';
	@override String get joinCurrentPlaybackDescription => 'ホストが現在視聴中のコンテンツに戻る';
	@override String get failedToOpenCurrentPlayback => '現在の再生を開けませんでした';
	@override String participantJoined({required Object name}) => '${name}が参加しました';
	@override String participantLeft({required Object name}) => '${name}が退出しました';
	@override String participantPaused({required Object name}) => '${name}が一時停止しました';
	@override String participantResumed({required Object name}) => '${name}が再開しました';
	@override String participantSeeked({required Object name}) => '${name}がシークしました';
	@override String participantBuffering({required Object name}) => '${name}がバッファリング中';
	@override String participantNeedsUpdate({required Object name}) => '${name} は古いバージョンのアプリを使用しているため、同期できません';
	@override String resumingWithout({required Object name}) => '${name} なしで再開';
	@override String get waitingForParticipants => '他の参加者の読み込みを待っています...';
	@override String waitingForName({required Object name}) => '${name}を待っています...';
	@override String get recentRooms => '最近のルーム';
	@override String get renameRoom => 'ルーム名を変更';
	@override String get removeRoom => '削除';
	@override String get guestSwitchUnavailable => '切り替えできません — サーバーが同期できません';
	@override String get guestSwitchFailed => '切り替えできません — このサーバーにコンテンツが見つかりません';
}

// Path: downloads
class _TranslationsDownloadsJa extends TranslationsDownloadsEn {
	_TranslationsDownloadsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'ダウンロード';
	@override String get manage => '管理';
	@override String get tvShows => 'テレビ番組';
	@override String get movies => '映画';
	@override String get music => '音楽';
	@override String tracksQueued({required Object count}) => '${count} 曲をダウンロード待機中';
	@override String get noDownloads => 'ダウンロードなし';
	@override String get noDownloadsDescription => 'ダウンロードしたコンテンツはここに表示され、オフラインで視聴できます';
	@override String get downloadNow => 'ダウンロード';
	@override String get deleteDownload => 'ダウンロードを削除';
	@override String get retryDownload => 'ダウンロードを再試行';
	@override String get downloadQueued => 'ダウンロードをキューに追加しました';
	@override String get downloadResumed => 'ダウンロードを再開しました';
	@override String get serverErrorBitrate => 'サーバーエラー: ファイルがリモートビットレート制限を超えている可能性があります';
	@override String episodesQueued({required Object count}) => '${count}エピソードをダウンロードキューに追加しました';
	@override String get downloadDeleted => 'ダウンロードを削除しました';
	@override String deleteConfirm({required Object title}) => 'このデバイスから「${title}」を削除しますか？';
	@override String get cancelledDownloadTitle => 'キャンセルされたダウンロード';
	@override String get cancelledDownloadMessage => 'このダウンロードはキャンセルされました。どうしますか？';
	@override String get allEpisodesAlreadyDownloaded => 'すべてのエピソードはすでにダウンロード済みです';
	@override String get resumeDownload => 'ダウンロードを再開';
	@override String get cancelledDownload => 'キャンセルされたダウンロード';
	@override String syncingFile({required Object file, required Object status}) => '${file}（${status}を同期中）';
	@override String downloadedFileClickToComplete({required Object file}) => '${file} をダウンロード済み — クリックして完了';
	@override String get partialDownloadClickToComplete => '一部ダウンロード済み — クリックして完了';
	@override String get deleting => '削除中...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => '${title}を削除中... (${current}/${total})';
	@override String get queuedTooltip => 'キュー';
	@override String queuedFilesTooltip({required Object files}) => 'キュー: ${files}';
	@override String get downloadingTooltip => 'ダウンロード中...';
	@override String downloadingFilesTooltip({required Object files}) => '${files} をダウンロード中';
	@override String get noDownloadsTree => 'ダウンロードなし';
	@override String get pauseAll => 'すべて一時停止';
	@override String get resumeAll => 'すべて再開';
	@override String get deleteAll => 'すべて削除';
	@override String get selectVersion => 'バージョンを選択';
	@override String get allEpisodes => 'すべてのエピソード';
	@override String get unwatchedOnly => '未視聴のみ';
	@override String nextNUnwatched({required Object count}) => '次の${count}件の未視聴';
	@override String get customAmount => '数を指定...';
	@override String get includeSpecials => 'スペシャルを含める';
	@override String get howManyEpisodes => '何エピソード？';
	@override String get invalidEpisodeCount => '有効なエピソード数を入力してください。';
	@override String get keepSynced => '同期を維持';
	@override String get downloadOnce => '一度だけダウンロード';
	@override String keepNUnwatched({required Object count}) => '未視聴を${count}件保持';
	@override String get editSyncRule => '同期ルールを編集';
	@override String get removeSyncRule => '同期ルールを削除';
	@override String removeSyncRuleConfirm({required Object title}) => '「${title}」の同期を停止しますか？ダウンロード済みのエピソードは保持されます。';
	@override String syncRuleCreated({required Object count}) => '同期ルールを作成しました — 未視聴のエピソードを${count}件保持';
	@override String get syncRuleUpdated => '同期ルールを更新しました';
	@override String get syncRuleRemoved => '同期ルールを削除しました';
	@override String syncedNewEpisodes({required Object title, required Object count}) => '${title}の新しいエピソードを${count}件同期しました';
	@override String get activeSyncRules => '同期ルール';
	@override String get noSyncRules => '同期ルールなし';
	@override String get manageSyncRule => '同期を管理';
	@override String get editEpisodeCount => 'エピソード数';
	@override String get editSyncFilter => '同期フィルター';
	@override String get syncAllItems => 'すべてのアイテムを同期中';
	@override String get syncUnwatchedItems => '未視聴のアイテムを同期中';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'サーバー: ${server} • ${status}';
	@override String get syncRuleAvailable => '利用可能';
	@override String get syncRuleOffline => 'オフライン';
	@override String get syncRuleSignInRequired => 'サインインが必要';
	@override String get syncRuleNotAvailableForProfile => '現在のプロフィールでは利用できません';
	@override String get syncRuleUnknownServer => '不明なサーバー';
	@override String get syncRuleListCreated => '同期ルールを作成しました';
}

// Path: shaders
class _TranslationsShadersJa extends TranslationsShadersEn {
	_TranslationsShadersJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'シェーダー';
	@override String get noShaderDescription => '映像補正なし';
	@override String get nvscalerDescription => 'よりシャープな映像のためのNVIDIA画像スケーリング';
	@override String get artcnnVariantNeutral => 'ニュートラル';
	@override String get artcnnVariantDenoise => 'ノイズ除去';
	@override String get artcnnVariantDenoiseSharpen => 'ノイズ除去 + シャープ';
	@override String get qualityFast => '高速';
	@override String get qualityHQ => '高品質';
	@override String get mode => 'モード';
	@override String get importShader => 'シェーダーをインポート';
	@override String get customShaderDescription => 'カスタムGLSLシェーダー';
	@override String get shaderImported => 'シェーダーをインポートしました';
	@override String get shaderImportFailed => 'シェーダーのインポートに失敗しました';
	@override String get deleteShader => 'シェーダーを削除';
	@override String deleteShaderConfirm({required Object name}) => '"${name}"を削除しますか？';
}

// Path: companionRemote
class _TranslationsCompanionRemoteJa extends TranslationsCompanionRemoteEn {
	_TranslationsCompanionRemoteJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'コンパニオンリモート';
	@override String connectedTo({required Object name}) => '${name}に接続中';
	@override String get unknownDevice => '不明なデバイス';
	@override late final _TranslationsCompanionRemoteSessionJa session = _TranslationsCompanionRemoteSessionJa._(_root);
	@override late final _TranslationsCompanionRemotePairingJa pairing = _TranslationsCompanionRemotePairingJa._(_root);
	@override late final _TranslationsCompanionRemoteRemoteJa remote = _TranslationsCompanionRemoteRemoteJa._(_root);
	@override late final _TranslationsCompanionRemoteErrorsJa errors = _TranslationsCompanionRemoteErrorsJa._(_root);
}

// Path: videoSettings
class _TranslationsVideoSettingsJa extends TranslationsVideoSettingsEn {
	_TranslationsVideoSettingsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => '再生速度';
	@override String get normalSpeed => '標準';
	@override String sleepTimerActive({required Object duration}) => '作動中（${duration}）';
	@override String get zoom => 'ズーム';
	@override String get sleepTimer => 'スリープタイマー';
	@override String get audioSync => '音声同期';
	@override String get subtitleSync => '字幕同期';
	@override String get hdr => 'HDR';
	@override String get audioOutput => '音声出力';
	@override String get performanceOverlay => 'パフォーマンスオーバーレイ';
	@override String get audioPassthrough => 'オーディオパススルー';
	@override String get audioNormalization => 'ラウドネス正規化';
	@override String get audioDownmix => 'ステレオにダウンミックス';
}

// Path: performanceOverlay
class _TranslationsPerformanceOverlayJa extends TranslationsPerformanceOverlayEn {
	_TranslationsPerformanceOverlayJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get color => '色';
	@override String get performance => 'パフォーマンス';
	@override String get buffer => 'バッファ';
	@override String get app => 'アプリ';
	@override String get decoder => 'デコーダー';
	@override String get rawDecoder => 'Raw デコーダー';
	@override String get tunneling => 'トンネリング';
	@override String get aspect => 'アスペクト';
	@override String get rotation => '回転';
	@override String get dvSource => 'DV ソース';
	@override String get dvPath => 'DV パス';
	@override String get p7Conversion => 'P7 変換';
	@override String get sampleRate => 'サンプルレート';
	@override String get pixelFormat => 'ピクセル形式';
	@override String get hwFormat => 'HW 形式';
	@override String get matrix => 'マトリクス';
	@override String get primaries => 'プライマリ';
	@override String get transfer => '転送';
	@override String get renderFps => '描画 FPS';
	@override String get displayFps => '表示 FPS';
	@override String get avSync => 'A/V 同期';
	@override String get dropped => 'ドロップ';
	@override String get dvRpus => 'DV RPU';
	@override String get dvRpuAverage => 'DV RPU 平均';
	@override String get dvSampleAverage => 'DV サンプル平均';
	@override String get maxLuma => '最大輝度';
	@override String get minLuma => '最小輝度';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => '使用キャッシュ';
	@override String get cacheLimit => 'キャッシュ上限';
	@override String get speed => '速度';
	@override String get player => 'プレーヤー';
	@override String get memory => 'メモリ';
	@override String get uiFps => 'UI FPS';
}

// Path: externalPlayer
class _TranslationsExternalPlayerJa extends TranslationsExternalPlayerEn {
	_TranslationsExternalPlayerJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '外部プレーヤー';
	@override String get useExternalPlayer => '外部プレーヤーを使用';
	@override String get useExternalPlayerDescription => '動画を別のアプリで開きます';
	@override String get selectPlayer => 'プレーヤーを選択';
	@override String get customPlayers => 'カスタムプレーヤー';
	@override String get systemDefault => 'システムデフォルト';
	@override String get addCustomPlayer => 'カスタムプレーヤーを追加';
	@override String get playerName => 'プレーヤー名';
	@override String get playerNameHint => 'マイプレーヤー';
	@override String get playerCommand => 'コマンド';
	@override String get playerPackage => 'パッケージ名';
	@override String get playerUrlScheme => 'URLスキーム';
	@override String get off => 'オフ';
	@override String get launchFailed => '外部プレーヤーの起動に失敗しました';
	@override String appNotInstalled({required Object name}) => '${name}がインストールされていません';
	@override String get playInExternalPlayer => '外部プレーヤーで再生';
}

// Path: metadataEdit
class _TranslationsMetadataEditJa extends TranslationsMetadataEditEn {
	_TranslationsMetadataEditJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => '編集...';
	@override String get screenTitle => 'メタデータを編集';
	@override String get basicInfo => '基本情報';
	@override String get artwork => 'アートワーク';
	@override String get advancedSettings => '詳細設定';
	@override String get title => 'タイトル';
	@override String get sortTitle => 'ソートタイトル';
	@override String get originalTitle => '原題';
	@override String get releaseDate => '公開日';
	@override String get contentRating => 'コンテンツレーティング';
	@override String get studio => 'スタジオ';
	@override String get tagline => 'タグライン';
	@override String get summary => 'あらすじ';
	@override String get poster => 'ポスター';
	@override String get background => '背景';
	@override String get logo => 'ロゴ';
	@override String get squareArt => '正方形アート';
	@override String get selectPoster => 'ポスターを選択';
	@override String get selectBackground => '背景を選択';
	@override String get selectLogo => 'ロゴを選択';
	@override String get selectSquareArt => '正方形アートを選択';
	@override String get fromUrl => 'URLから';
	@override String get uploadFile => 'ファイルをアップロード';
	@override String get enterImageUrl => '画像URLを入力';
	@override String get imageUrl => '画像URL';
	@override String get metadataUpdated => 'メタデータを更新しました';
	@override String get metadataUpdateFailed => 'メタデータの更新に失敗しました';
	@override String get artworkUpdated => 'アートワークを更新しました';
	@override String get artworkUpdateFailed => 'アートワークの更新に失敗しました';
	@override String get noArtworkAvailable => 'アートワークがありません';
	@override String artworkOption({required Object index}) => 'アートワークの選択肢 ${index}';
	@override String selectedArtworkOption({required Object index}) => 'アートワークの選択肢 ${index}、選択済み';
	@override String get notSet => '未設定';
	@override String get libraryDefault => 'ライブラリのデフォルト';
	@override String get accountDefault => 'アカウントのデフォルト';
	@override String get seriesDefault => 'シリーズのデフォルト';
	@override String get episodeSorting => 'エピソードの並べ替え';
	@override String get oldestFirst => '古い順';
	@override String get newestFirst => '新しい順';
	@override String get keep => '保持';
	@override String get allEpisodes => 'すべてのエピソード';
	@override String latestEpisodes({required Object count}) => '最新${count}エピソード';
	@override String get latestEpisode => '最新エピソード';
	@override String episodesAddedPastDays({required Object count}) => '過去${count}日間に追加されたエピソード';
	@override String get deleteAfterPlaying => '再生後にエピソードを削除';
	@override String get never => 'しない';
	@override String get afterADay => '1日後';
	@override String get afterAWeek => '1週間後';
	@override String get afterAMonth => '1ヶ月後';
	@override String get onNextRefresh => '次回更新時';
	@override String get seasons => 'シーズン';
	@override String get show => '表示';
	@override String get hide => '非表示';
	@override String get episodeOrdering => 'エピソードの順序';
	@override String get tmdbAiring => 'The Movie Database（放送順）';
	@override String get tvdbAiring => 'TheTVDB（放送順）';
	@override String get tvdbAbsolute => 'TheTVDB（絶対順）';
	@override String get metadataLanguage => 'メタデータの言語';
	@override String get useOriginalTitle => '原題を使用';
	@override String get preferredAudioLanguage => '優先音声言語';
	@override String get preferredSubtitleLanguage => '優先字幕言語';
	@override String get subtitleMode => '字幕自動選択モード';
	@override String get manuallySelected => '手動選択';
	@override String get shownWithForeignAudio => '外国語音声時に表示';
	@override String get alwaysEnabled => '常に有効';
	@override String get tags => 'タグ';
	@override String get addTag => 'タグを追加';
	@override String get genre => 'ジャンル';
	@override String get director => '監督';
	@override String get writer => '脚本';
	@override String get producer => 'プロデューサー';
	@override String get country => '国';
	@override String get collection => 'コレクション';
	@override String get label => 'ラベル';
	@override String get style => 'スタイル';
	@override String get mood => 'ムード';
}

// Path: matchScreen
class _TranslationsMatchScreenJa extends TranslationsMatchScreenEn {
	_TranslationsMatchScreenJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get match => 'マッチ...';
	@override String get fixMatch => 'マッチを修正...';
	@override String get unmatch => 'マッチ解除';
	@override String get unmatchConfirm => 'この一致をクリアしますか？再一致するまでPlexでは未一致として扱われます。';
	@override String get unmatchSuccess => 'マッチを解除しました';
	@override String get unmatchFailed => 'マッチの解除に失敗しました';
	@override String get matchApplied => 'マッチを適用しました';
	@override String get matchFailed => 'マッチの適用に失敗しました';
	@override String get titleHint => 'タイトル';
	@override String get yearHint => '年';
	@override String get search => '検索';
	@override String get noMatchesFound => '一致する項目がありません';
}

// Path: serverTasks
class _TranslationsServerTasksJa extends TranslationsServerTasksEn {
	_TranslationsServerTasksJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'サーバータスク';
	@override String get failedToLoad => 'タスクの読み込みに失敗しました';
	@override String get noTasks => '実行中のタスクはありません';
}

// Path: trakt
class _TranslationsTraktJa extends TranslationsTraktEn {
	_TranslationsTraktJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => '接続済み';
	@override String connectedAs({required Object username}) => '@${username} として接続済み';
	@override String get disconnectConfirm => 'Trakt アカウントを切断しますか?';
	@override String get disconnectConfirmBody => 'PlezyはTraktへのイベント送信を停止します。いつでも再接続できます。';
	@override String get scrobble => 'リアルタイムのスクロブル';
	@override String get scrobbleDescription => '再生中に再生・一時停止・停止イベントを Trakt に送信します。';
	@override String get watchedSync => '視聴済みステータスを同期';
	@override String get watchedSyncDescription => 'Plezy で項目を視聴済みにすると、Trakt でも視聴済みになります。';
}

// Path: seerr
class _TranslationsSeerrJa extends TranslationsSeerrEn {
	_TranslationsSeerrJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Seerrに接続';
	@override String get serverUrl => 'サーバー URL';
	@override String get serverUrlHelper => 'Seerr インスタンスのアドレス';
	@override String get checkServer => '続ける';
	@override String get signInWithJellyfin => 'Jellyfinでサインイン';
	@override String get signInWithEmby => 'Embyでサインイン';
	@override String get signInWithLocal => 'ローカルアカウントを使う';
	@override String get email => 'メールアドレス';
	@override String get noSignInMethods => 'この Seerr インスタンスには Plezy が対応しているサインイン方法がありません。';
	@override String get instance => 'インスタンス';
	@override String get disconnectConfirm => 'Seerr の接続を解除しますか？';
	@override String get disconnectConfirmBody => 'Plezy はこの Seerr インスタンスの情報を削除します。いつでも再接続できます。';
	@override String get request => 'リクエスト';
	@override String get request4k => '4K でリクエスト';
	@override String get seasons => 'シーズン';
	@override String get allSeasons => '全シーズン';
	@override String get advancedOptions => '詳細';
	@override String get destinationServer => '宛先サーバー';
	@override String get qualityProfile => '画質プロファイル';
	@override String get rootFolder => 'ルートフォルダ';
	@override String get languageProfile => '言語プロファイル';
	@override String get requestSubmitted => 'リクエストを送信しました';
	@override String requestFailed({required Object error}) => 'リクエストに失敗しました: ${error}';
	@override String get requestsLoadFailed => 'リクエストオプションを読み込めませんでした';
	@override String get nothingToRequest => 'すべてすでに利用可能またはリクエスト済みです。';
	@override String get statusAvailable => '利用可能';
	@override String get statusPartiallyAvailable => '一部利用可能';
	@override String get statusRequested => 'リクエスト済み';
	@override String get statusProcessing => '処理中';
}

// Path: services
class _TranslationsServicesJa extends TranslationsServicesEn {
	_TranslationsServicesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'サービス';
	@override String get hubSubtitle => '視聴の進捗を同期して、新しいタイトルをリクエストします。';
	@override String get notConnected => '未接続';
	@override String connectedAs({required Object username}) => '@${username} として接続済み';
	@override String get scrobble => '進捗を自動で記録';
	@override String get scrobbleDescription => 'エピソードや映画を見終えたときにリストを更新します。';
	@override String disconnectConfirm({required Object service}) => '${service} の接続を解除しますか？';
	@override String disconnectConfirmBody({required Object service}) => 'Plezyは${service}の更新を停止します。いつでも再接続できます。';
	@override String connectFailed({required Object service}) => '${service} に接続できませんでした。もう一度お試しください。';
	@override late final _TranslationsServicesNamesJa names = _TranslationsServicesNamesJa._(_root);
	@override late final _TranslationsServicesDeviceCodeJa deviceCode = _TranslationsServicesDeviceCodeJa._(_root);
	@override late final _TranslationsServicesOauthProxyJa oauthProxy = _TranslationsServicesOauthProxyJa._(_root);
	@override late final _TranslationsServicesLibraryFilterJa libraryFilter = _TranslationsServicesLibraryFilterJa._(_root);
}

// Path: addServer
class _TranslationsAddServerJa extends TranslationsAddServerEn {
	_TranslationsAddServerJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get addJellyfinTitle => 'Jellyfinサーバーを追加';
	@override String get serverUrls => 'サーバーURL';
	@override String get serverUrlsHelper => '複数のURLをカンマ区切りで入力できます。';
	@override String get findServer => 'サーバーを検索';
	@override String get searchingLocalServers => 'ローカル Jellyfin サーバーを検索中...';
	@override String get localServers => 'ローカル Jellyfin サーバー';
	@override String get username => 'ユーザー名';
	@override String get password => 'パスワード';
	@override String get signIn => 'サインイン';
	@override String get change => '変更';
	@override String get required => '必須';
	@override String couldNotReachServer({required Object error}) => 'サーバーに接続できませんでした: ${error}';
	@override String signInFailed({required Object error}) => 'サインインに失敗しました: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connectに失敗しました: ${error}';
	@override String get addPlexTitle => 'Plexでサインイン';
	@override String get pinExpired => 'サインイン前にPINの有効期限が切れました。もう一度お試しください。';
	@override String failedToRegisterAccount({required Object error}) => 'アカウントの登録に失敗しました: ${error}';
	@override String get enterJellyfinUrlError => 'JellyfinサーバーのURLを入力してください';
	@override String get addConnectionTitle => '接続を追加';
	@override String addConnectionTitleScoped({required Object name}) => '${name}に追加';
	@override String get signInWithPlexCard => 'Plexでサインイン';
	@override String get signInWithPlexCardSubtitle => 'このデバイスを承認します。共有サーバーが追加されます。';
	@override String get signInWithPlexCardSubtitleScoped => 'Plexアカウントを承認します。Homeユーザーはプロフィールになります。';
	@override String get connectToJellyfinCard => 'Jellyfinに接続';
	@override String get connectToJellyfinCardSubtitle => 'サーバーURL、ユーザー名、パスワードを入力してください。';
	@override String connectToJellyfinCardSubtitleScoped({required Object name}) => 'Jellyfinサーバーにサインインします。${name}に紐付けられます。';
	@override String get borrowFromAnotherProfile => '別のプロファイルから借りる';
	@override String get borrowFromAnotherProfileSubtitle => '別のプロフィールの接続を再利用します。PIN保護されたプロフィールにはPINが必要です。';
}

// Path: hotkeys.actions
class _TranslationsHotkeysActionsJa extends TranslationsHotkeysActionsEn {
	_TranslationsHotkeysActionsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get playPause => '再生/一時停止';
	@override String get volumeUp => '音量を上げる';
	@override String get volumeDown => '音量を下げる';
	@override String seekForward({required Object seconds}) => '前方にシーク (${seconds}秒)';
	@override String seekBackward({required Object seconds}) => '後方にシーク (${seconds}秒)';
	@override String get fullscreenToggle => 'フルスクリーン切替';
	@override String get muteToggle => 'ミュート切替';
	@override String get subtitleToggle => '字幕切替';
	@override String get audioTrackNext => '次の音声トラック';
	@override String get subtitleTrackNext => '次の字幕トラック';
	@override String get chapterNext => '次のチャプター';
	@override String get chapterPrevious => '前のチャプター';
	@override String get episodeNext => '次のエピソード';
	@override String get episodePrevious => '前のエピソード';
	@override String get speedIncrease => '速度を上げる';
	@override String get speedDecrease => '速度を下げる';
	@override String get speedReset => '速度をリセット';
	@override String get zoomIn => 'ズームイン';
	@override String get zoomOut => 'ズームアウト';
	@override String get zoomReset => 'ズームをリセット';
	@override String get subSeekNext => '次の字幕にシーク';
	@override String get subSeekPrev => '前の字幕にシーク';
	@override String get shaderToggle => 'シェーダー切替';
	@override String get skipMarker => 'イントロ/クレジットをスキップ';
	@override String get screenshot => 'スクリーンショットを撮る';
}

// Path: videoControls.pipErrors
class _TranslationsVideoControlsPipErrorsJa extends TranslationsVideoControlsPipErrorsEn {
	_TranslationsVideoControlsPipErrorsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Android 8.0以降が必要です';
	@override String get iosVersion => 'iOS 15.0以降が必要です';
	@override String get permissionDisabled => 'ピクチャーインピクチャーが無効です。システム設定で有効にしてください。';
	@override String get notSupported => 'デバイスはピクチャーインピクチャーモードをサポートしていません';
	@override String get voSwitchFailed => 'ピクチャーインピクチャーの映像出力切替に失敗しました';
	@override String get failed => 'ピクチャーインピクチャーの開始に失敗しました';
	@override String unknown({required Object error}) => 'エラーが発生しました: ${error}';
}

// Path: libraries.tabs
class _TranslationsLibrariesTabsJa extends TranslationsLibrariesTabsEn {
	_TranslationsLibrariesTabsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'おすすめ';
	@override String get browse => 'ブラウズ';
	@override String get collections => 'コレクション';
	@override String get playlists => 'プレイリスト';
}

// Path: libraries.groupings
class _TranslationsLibrariesGroupingsJa extends TranslationsLibrariesGroupingsEn {
	_TranslationsLibrariesGroupingsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'グループ';
	@override String get all => 'すべて';
	@override String get movies => '映画';
	@override String get shows => 'テレビ番組';
	@override String get seasons => 'シーズン';
	@override String get episodes => 'エピソード';
	@override String get artists => 'アーティスト';
	@override String get albums => 'アルバム';
	@override String get tracks => '曲';
	@override String get folders => 'フォルダ';
}

// Path: libraries.filterCategories
class _TranslationsLibrariesFilterCategoriesJa extends TranslationsLibrariesFilterCategoriesEn {
	_TranslationsLibrariesFilterCategoriesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get genre => 'ジャンル';
	@override String get year => '年';
	@override String get contentRating => '視聴年齢区分';
	@override String get tag => 'タグ';
	@override String get unwatched => '未視聴';
	@override String get unplayed => '未再生';
	@override String get favorites => 'お気に入り';
}

// Path: libraries.sortLabels
class _TranslationsLibrariesSortLabelsJa extends TranslationsLibrariesSortLabelsEn {
	_TranslationsLibrariesSortLabelsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'タイトル';
	@override String get dateAdded => '追加日';
	@override String get releaseDate => 'リリース日';
	@override String get rating => '評価';
	@override String get communityRating => 'コミュニティ評価';
	@override String get criticRating => '批評家評価';
	@override String get userRating => 'ユーザー評価';
	@override String get datePlayed => '再生日';
	@override String get playCount => '再生回数';
	@override String get productionYear => '製作年';
	@override String get runtime => '再生時間';
	@override String get officialRating => '公式レーティング';
	@override String get premiereDate => 'プレミア日';
	@override String get startDate => '開始日';
	@override String get airTime => '放送時刻';
	@override String get studio => 'スタジオ';
	@override String get random => 'ランダム';
	@override String get dateShared => '共有日';
	@override String get latestEpisodeAirDate => '最新エピソード放送日';
	@override String get lastEpisodeDateAdded => '最新エピソード追加日';
}

// Path: explore.rows
class _TranslationsExploreRowsJa extends TranslationsExploreRowsEn {
	_TranslationsExploreRowsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'ウォッチリスト';
	@override String get recommendedMovies => 'おすすめの映画';
	@override String get recommendedShows => 'おすすめのテレビ番組';
	@override String get trendingMovies => 'トレンドの映画';
	@override String get trendingShows => 'トレンドのテレビ番組';
	@override String get popularMovies => '人気の映画';
	@override String get popularShows => '人気のテレビ番組';
	@override String get suggestedAnime => 'おすすめのアニメ';
	@override String get airingAnime => '放送中の注目アニメ';
	@override String get popularAnime => '人気のアニメ';
	@override String get trending => 'トレンド';
	@override String get upcomingMovies => '近日公開の映画';
	@override String get upcomingShows => '放送予定の番組';
}

// Path: explore.status
class _TranslationsExploreStatusJa extends TranslationsExploreStatusEn {
	_TranslationsExploreStatusJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get airing => '放送中';
	@override String get ended => '放送終了';
	@override String get canceled => '打ち切り';
	@override String get upcoming => '放送予定';
}

// Path: companionRemote.session
class _TranslationsCompanionRemoteSessionJa extends TranslationsCompanionRemoteSessionEn {
	_TranslationsCompanionRemoteSessionJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'リモートサーバーを起動中...';
	@override String get hostAddress => 'ホストアドレス';
	@override String get connected => '接続済み';
	@override String get serverRunning => 'リモートサーバー稼働中';
	@override String get serverStopped => 'リモートサーバー停止中';
	@override String get serverRunningDescription => 'ネットワーク上のモバイルデバイスがこのアプリに接続できます';
	@override String get serverStoppedDescription => 'モバイルデバイスの接続を許可するにはサーバーを起動してください';
	@override String get usePhoneToControl => 'モバイルデバイスでこのアプリを操作できます';
	@override String get startServer => 'サーバーを起動';
	@override String get stopServer => 'サーバーを停止';
	@override String get minimize => '最小化';
}

// Path: companionRemote.pairing
class _TranslationsCompanionRemotePairingJa extends TranslationsCompanionRemotePairingEn {
	_TranslationsCompanionRemotePairingJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => '同じPlexアカウントのPlezyデバイスがここに表示されます';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => '接続中...';
	@override String get searchingForDevices => 'デバイスを検索中...';
	@override String get noDevicesFound => 'ネットワーク上にデバイスが見つかりません';
	@override String get noDevicesHint => 'デスクトップでPlezyを開き、同じWiFiを使用してください';
	@override String get availableDevices => '利用可能なデバイス';
	@override String get manualConnection => '手動接続';
	@override String get cryptoInitFailed => '安全な接続を開始できませんでした。先にPlexにサインインしてください。';
	@override String get validationHostRequired => 'ホストアドレスを入力してください';
	@override String get validationHostFormat => '形式はIP:ポートである必要があります（例: 192.168.1.100:48632）';
	@override String get connectionTimedOut => '接続がタイムアウトしました。両方のデバイスで同じネットワークを使用してください。';
	@override String get sessionNotFound => 'デバイスが見つかりません。ホストでPlezyが実行中か確認してください。';
	@override String get authFailed => '認証に失敗しました。両方のデバイスで同じPlexアカウントが必要です。';
	@override String failedToConnect({required Object error}) => '接続に失敗しました: ${error}';
}

// Path: companionRemote.remote
class _TranslationsCompanionRemoteRemoteJa extends TranslationsCompanionRemoteRemoteEn {
	_TranslationsCompanionRemoteRemoteJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'リモートセッションから切断しますか？';
	@override String get reconnecting => '再接続中...';
	@override String attemptOf({required Object current}) => '試行 ${current}/5';
	@override String get retryNow => '今すぐ再試行';
	@override String get tabRemote => 'リモート';
	@override String get tabPlay => '再生';
	@override String get tabMore => 'その他';
	@override String get menu => 'メニュー';
	@override String get tabNavigation => 'タブナビゲーション';
	@override String get tabDiscover => '探す';
	@override String get tabLibraries => 'ライブラリ';
	@override String get tabSearch => '検索';
	@override String get tabDownloads => 'ダウンロード';
	@override String get tabSettings => '設定';
	@override String get previous => '前へ';
	@override String get playPause => '再生/一時停止';
	@override String get next => '次へ';
	@override String get seekBack => '巻き戻し';
	@override String get stop => '停止';
	@override String get seekForward => '早送り';
	@override String get volume => '音量';
	@override String get volumeDown => '下げる';
	@override String get volumeUp => '上げる';
	@override String get fullscreen => 'フルスクリーン';
	@override String get subtitles => '字幕';
	@override String get audio => '音声';
	@override String get searchHint => 'デスクトップで検索...';
}

// Path: companionRemote.errors
class _TranslationsCompanionRemoteErrorsJa extends TranslationsCompanionRemoteErrorsEn {
	_TranslationsCompanionRemoteErrorsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'ネットワークインターフェースが見つかりません';
	@override String get authenticationFailed => '認証に失敗しました';
	@override String serverStartFailed({required Object error}) => 'リモートサーバーを起動できませんでした: ${error}';
	@override String commandFailed({required Object error}) => 'リモートコマンドを送信できませんでした: ${error}';
	@override String get joinTimedOut => 'セッション参加がタイムアウトしました';
	@override String get failedToConnectAnyAddress => 'どのアドレスにも接続できませんでした';
	@override String connectionLostAfterAttempts({required Object attempts}) => '${attempts}回試行後に接続が切断されました';
	@override String get connectionLost => '接続が切断されました';
}

// Path: services.names
class _TranslationsServicesNamesJa extends TranslationsServicesNamesEn {
	_TranslationsServicesNamesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
}

// Path: services.deviceCode
class _TranslationsServicesDeviceCodeJa extends TranslationsServicesDeviceCodeEn {
	_TranslationsServicesDeviceCodeJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '${service} で Plezy を有効化';
	@override String body({required Object url}) => '${url} にアクセスしてこのコードを入力:';
	@override String openToActivate({required Object service}) => '${service} を開いて有効化';
	@override String get copyCode => 'アクティベーションコードをコピー';
	@override String get waitingForAuthorization => '認証を待っています…';
	@override String get codeCopied => 'コードをコピーしました';
}

// Path: services.oauthProxy
class _TranslationsServicesOauthProxyJa extends TranslationsServicesOauthProxyEn {
	_TranslationsServicesOauthProxyJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '${service} にサインイン';
	@override String get body => 'このQRコードをスキャンするか、任意のデバイスでURLを開いてください。';
	@override String openToSignIn({required Object service}) => '${service} を開いてサインイン';
	@override String get copyUrl => 'サインインURLをコピー';
	@override String get urlCopied => 'URLをコピーしました';
}

// Path: services.libraryFilter
class _TranslationsServicesLibraryFilterJa extends TranslationsServicesLibraryFilterEn {
	_TranslationsServicesLibraryFilterJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'ライブラリフィルター';
	@override String get subtitleAllSyncing => 'すべてのライブラリを同期中';
	@override String get subtitleNoneSyncing => '同期なし';
	@override String subtitleBlocked({required Object count}) => '${count} 件をブロック';
	@override String subtitleAllowed({required Object count}) => '${count} 件を許可';
	@override String get mode => 'フィルターモード';
	@override String get modeBlacklist => 'ブロックリスト';
	@override String get modeWhitelist => '許可リスト';
	@override String get modeHintBlacklist => '下でチェックしたライブラリ以外をすべて同期します。';
	@override String get modeHintWhitelist => '下でチェックしたライブラリのみ同期します。';
	@override String get libraries => 'ライブラリ';
	@override String get noLibraries => '利用できるライブラリがありません';
}

/// The flat map containing all translations for locale <ja>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsJa {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Plezy',
			'auth.signInWithPlex' => 'Plexでサインイン',
			'auth.showQRCode' => 'QRコードを表示',
			'auth.authenticate' => '認証',
			'auth.authenticationTimeout' => '認証がタイムアウトしました。もう一度お試しください。',
			'auth.scanQRToSignIn' => 'このQRコードをスキャンしてサインイン',
			'auth.waitingForAuth' => '認証待ち...\nブラウザでサインインしてください。',
			'auth.useBrowser' => 'ブラウザを使用',
			'auth.or' => 'または',
			'auth.connectToJellyfin' => 'Jellyfinに接続',
			'auth.useQuickConnect' => 'Quick Connect を使う',
			'auth.quickConnectInstructions' => 'JellyfinでQuick Connectを開き、このコードを入力してください。',
			'auth.quickConnectWaiting' => '承認を待っています…',
			'auth.quickConnectCancel' => 'キャンセル',
			'auth.quickConnectExpired' => 'Quick Connectの有効期限が切れました。もう一度お試しください。',
			'common.cancel' => 'キャンセル',
			'common.save' => '保存',
			'common.close' => '閉じる',
			'common.clear' => 'クリア',
			'common.reset' => 'リセット',
			'common.later' => '後で',
			'common.submit' => '送信',
			'common.confirm' => '確認',
			'common.retry' => '再試行',
			'common.logout' => 'ログアウト',
			'common.unknown' => '不明',
			'common.refresh' => '更新',
			'common.yes' => 'はい',
			'common.no' => 'いいえ',
			'common.delete' => '削除',
			'common.edit' => '編集',
			'common.shuffle' => 'シャッフル',
			'common.addTo' => '追加...',
			'common.createNew' => '新規作成',
			'common.connect' => '接続',
			'common.disconnect' => '切断',
			'common.play' => '再生',
			'common.pause' => '一時停止',
			'common.resume' => '再開',
			'common.error' => 'エラー',
			'common.search' => '検索',
			'common.home' => 'ホーム',
			'common.back' => '戻る',
			'common.settings' => '設定',
			'common.mute' => 'ミュート',
			'common.ok' => 'OK',
			'common.off' => 'オフ',
			'common.seasonNumber' => ({required Object number}) => 'シーズン${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'エピソード${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'チャプター${number}',
			'common.reconnect' => '再接続',
			'common.viewAll' => 'すべて表示',
			'common.checkingNetwork' => 'ネットワークを確認中...',
			'common.loadingServers' => 'サーバーを読み込み中...',
			'common.connectingToServers' => 'サーバーに接続中...',
			'common.startingOfflineMode' => 'オフラインモードを開始中...',
			'common.loading' => '読み込み中...',
			'common.fullscreen' => 'フルスクリーン',
			'common.exitFullscreen' => 'フルスクリーンを終了',
			'common.pressBackAgainToExit' => 'もう一度押すと終了します',
			'screens.licenses' => 'ライセンス',
			'screens.switchProfile' => 'プロフィール切替',
			'screens.subtitleStyling' => '字幕スタイル',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'ログ',
			'update.available' => 'アップデート利用可能',
			'update.versionAvailable' => ({required Object version}) => 'バージョン ${version} が利用可能です',
			'update.currentVersion' => ({required Object version}) => '現在: ${version}',
			'update.skipVersion' => 'このバージョンをスキップ',
			'update.viewRelease' => 'リリースを表示',
			'update.latestVersion' => '最新バージョンです',
			'update.checkFailed' => 'アップデートの確認に失敗しました',
			'settings.title' => '設定',
			'settings.supportDeveloper' => 'Plezy を支援',
			'settings.supportDeveloperDescription' => 'Liberapay で寄付して開発を支援',
			'settings.language' => '言語',
			'settings.theme' => 'テーマ',
			'settings.appearance' => '外観',
			'settings.videoPlayback' => '動画再生',
			'settings.videoPlaybackDescription' => '再生動作を設定',
			'settings.advanced' => '詳細',
			'settings.episodePosterMode' => 'エピソードポスタースタイル',
			'settings.seriesPoster' => 'シリーズポスター',
			'settings.seasonPoster' => 'シーズンポスター',
			'settings.episodeThumbnail' => 'サムネイル',
			'settings.showHeroSectionDescription' => 'ホーム画面に注目コンテンツのカルーセルを表示',
			'settings.secondsLabel' => '秒',
			'settings.minutesLabel' => '分',
			'settings.secondsShort' => '秒',
			'settings.minutesShort' => '分',
			'settings.durationHint' => ({required Object min, required Object max}) => '時間を入力 (${min}-${max})',
			'settings.systemTheme' => 'システム',
			'settings.lightTheme' => 'ライト',
			'settings.darkTheme' => 'ダーク',
			'settings.oledTheme' => 'OLED',
			'settings.libraryDensity' => 'ライブラリの密度',
			'settings.compact' => 'コンパクト',
			'settings.comfortable' => 'ゆったり',
			'settings.viewMode' => '表示モード',
			'settings.gridView' => 'グリッド',
			'settings.listView' => 'リスト',
			'settings.showHeroSection' => 'ヒーローセクションを表示',
			'settings.continueWatchingAction' => '視聴中の操作',
			'settings.continueWatchingPlay' => '再生',
			'settings.continueWatchingDetails' => '詳細を開く',
			'settings.episodeAction' => 'エピソードの操作',
			'settings.episodePlay' => '再生',
			'settings.episodeDetails' => '詳細を開く',
			'settings.useGlobalHubs' => 'ホームレイアウトを使用',
			'settings.useGlobalHubsDescription' => '統合ホームハブを表示します。オフの場合はライブラリのおすすめを使用します。',
			'settings.showServerNameOnHubs' => 'ハブにサーバー名を表示',
			'settings.showServerNameOnHubsDescription' => 'ハブのタイトルに常にサーバー名を表示します。',
			'settings.groupLibrariesByServer' => 'サーバーごとにライブラリをグループ化',
			'settings.groupLibrariesByServerDescription' => 'サイドバーのライブラリをメディアサーバーごとにまとめます。',
			'settings.alwaysKeepSidebarOpen' => 'サイドバーを常に開いておく',
			'settings.alwaysKeepSidebarOpenDescription' => 'サイドバーを展開したまま、コンテンツ領域が調整される',
			'settings.showUnwatchedCount' => '未視聴数を表示',
			'settings.showUnwatchedCountDescription' => '番組とシーズンに未視聴エピソード数を表示',
			'settings.showEpisodeNumberOnCards' => 'カードにエピソード番号を表示',
			'settings.showEpisodeNumberOnCardsDescription' => 'エピソードカードにシーズン番号とエピソード番号を表示します',
			'settings.showSeasonPostersOnTabs' => 'タブにシーズンポスターを表示',
			'settings.showSeasonPostersOnTabsDescription' => '各シーズンのポスターをタブの上に表示します',
			'settings.tvFullCardLayout' => 'フルTVカード',
			'settings.tvFullCardLayoutDescription' => 'TVカードを画像のみで表示し、俳優名を重ねて表示します',
			'settings.focusGlow' => 'フォーカス時の光彩',
			'settings.focusGlowDescription' => 'フォーカス中のカードの周りに柔らかい光彩を表示します',
			'settings.visualEffects' => '視覚効果',
			'settings.visualEffectsAuto' => '自動',
			'settings.visualEffectsAutoDescription' => '低性能なデバイスでは効果を自動的に減らします',
			'settings.visualEffectsFull' => 'フル',
			'settings.visualEffectsReduced' => '軽減',
			'settings.visualEffectsReducedDescription' => 'アニメーションを減らし、低解像度のアートワークを使用します',
			'settings.hideSpoilers' => '未視聴エピソードのネタバレを非表示',
			'settings.hideSpoilersDescription' => '未視聴エピソードのサムネイルと説明をぼかします',
			'settings.playerBackend' => 'プレーヤーバックエンド',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'ハードウェアデコード',
			'settings.hardwareDecodingDescription' => '利用可能な場合にハードウェアアクセラレーションを使用',
			'settings.bufferSize' => 'バッファサイズ',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => '自動（推奨）',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => '${heap}MBのメモリが利用可能です。${size}MBのバッファは再生に影響する可能性があります。',
			'settings.defaultQualityTitle' => 'デフォルト画質',
			'settings.musicQualityTitle' => '音楽の音質',
			'settings.subtitleStyling' => '字幕スタイル',
			'settings.subtitleStylingDescription' => '字幕の外観をカスタマイズ',
			'settings.smallSkipDuration' => '短いスキップ時間',
			'settings.largeSkipDuration' => '長いスキップ時間',
			'settings.rewindOnResume' => '再開時に巻き戻し',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds}秒',
			'settings.defaultSleepTimer' => 'デフォルトスリープタイマー',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes}分',
			'settings.rememberTrackSelections' => '番組/映画ごとにトラック選択を記憶',
			'settings.rememberTrackSelectionsDescription' => 'タイトルごとに音声と字幕の選択を記憶します',
			'settings.showChapterMarkersOnTimeline' => 'シークバーにチャプターマーカーを表示',
			'settings.showChapterMarkersOnTimelineDescription' => 'チャプターの境界でシークバーを区切る',
			'settings.clickVideoTogglesPlayback' => '動画クリックで再生/一時停止を切替',
			'settings.clickVideoTogglesPlaybackDescription' => 'コントロール表示ではなく、動画クリックで再生/一時停止します。',
			'settings.videoPlayerControls' => '動画プレーヤーコントロール',
			'settings.keyboardShortcuts' => 'キーボードショートカット',
			'settings.keyboardShortcutsDescription' => 'キーボードショートカットをカスタマイズ',
			'settings.videoPlayerNavigation' => '動画プレーヤーナビゲーション',
			'settings.videoPlayerNavigationDescription' => '矢印キーで動画プレーヤーコントロールを操作',
			'settings.watchTogetherRelay' => '一緒に視聴リレーサーバー',
			'settings.watchTogetherRelayDescription' => 'カスタムリレーを設定します。全員が同じサーバーを使う必要があります。',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.crashReporting' => 'クラッシュレポート',
			'settings.crashReportingDescription' => 'アプリの改善に役立つクラッシュレポートを送信',
			'settings.debugLogging' => 'デバッグログ',
			'settings.debugLoggingDescription' => 'トラブルシューティング用の詳細なログを有効化',
			'settings.viewLogs' => 'ログを表示',
			'settings.viewLogsDescription' => 'アプリケーションログを表示',
			'settings.clearCache' => 'キャッシュをクリア',
			'settings.clearCacheDescription' => 'キャッシュ済みの画像とデータを削除します。コンテンツの読み込みが遅くなる場合があります。',
			'settings.clearCacheSuccess' => 'キャッシュを正常にクリアしました',
			'settings.resetSettings' => '設定をリセット',
			'settings.resetSettingsDescription' => '設定を既定に戻します。元に戻せません。',
			'settings.resetSettingsSuccess' => '設定を正常にリセットしました',
			'settings.backup' => 'バックアップ',
			'settings.exportSettings' => '設定をエクスポート',
			'settings.exportSettingsDescription' => '設定をファイルに保存',
			'settings.exportSettingsSuccess' => '設定をエクスポートしました',
			'settings.exportSettingsFailed' => '設定をエクスポートできませんでした',
			'settings.importSettings' => '設定をインポート',
			'settings.importSettingsDescription' => 'ファイルから設定を復元',
			'settings.importSettingsConfirm' => '現在の設定を置き換えます。続行しますか？',
			'settings.importSettingsSuccess' => '設定をインポートしました',
			'settings.importSettingsFailed' => '設定をインポートできませんでした',
			'settings.importSettingsInvalidFile' => 'このファイルは有効なPlezyの設定エクスポートではありません',
			'settings.importSettingsNoUser' => '設定をインポートする前にサインインしてください',
			'settings.shortcutsReset' => 'ショートカットをデフォルトにリセットしました',
			'settings.about' => 'アプリについて',
			'settings.aboutDescription' => 'アプリ情報とライセンス',
			'settings.updates' => 'アップデート',
			'settings.updateAvailable' => 'アップデート利用可能',
			'settings.checkForUpdates' => 'アップデートを確認',
			'settings.autoCheckUpdatesOnStartup' => '起動時にアップデートを自動的に確認',
			'settings.autoCheckUpdatesOnStartupDescription' => '起動時にアップデートがある場合は通知します',
			'settings.validationErrorEnterNumber' => '有効な数値を入力してください',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => '時間は${min}から${max} ${unit}の間である必要があります',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'ショートカットは既に${action}に割り当てられています',
			'settings.shortcutUpdated' => ({required Object action}) => '${action}のショートカットを更新しました',
			'settings.autoSkip' => '自動スキップ',
			'settings.autoSkipIntro' => 'イントロを自動スキップ',
			'settings.autoSkipIntroDescription' => '数秒後にイントロマーカーを自動的にスキップ',
			'settings.autoSkipCredits' => 'クレジットを自動スキップ',
			'settings.autoSkipCreditsDescription' => 'クレジットを自動的にスキップして次のエピソードを再生',
			'settings.forceSkipMarkerFallback' => 'フォールバックマーカーを強制',
			'settings.forceSkipMarkerFallbackDescription' => 'Plexにマーカーがある場合でもチャプタータイトルのパターンを使用します',
			'settings.autoSkipDelay' => '自動スキップの遅延',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => '自動スキップまで${seconds}秒待機',
			'settings.introPattern' => 'イントロマーカーパターン',
			'settings.introPatternDescription' => 'チャプタータイトルのイントロマーカーに一致する正規表現パターン',
			'settings.creditsPattern' => 'クレジットマーカーパターン',
			'settings.creditsPatternDescription' => 'チャプタータイトルのクレジットマーカーに一致する正規表現パターン',
			'settings.invalidRegex' => '無効な正規表現',
			'settings.regex' => '正規表現',
			'settings.downloads' => 'ダウンロード',
			'settings.downloadLocationDescription' => 'ダウンロードコンテンツの保存場所を選択',
			'settings.downloadLocationDefault' => 'デフォルト（アプリストレージ）',
			'settings.downloadLocationCustom' => 'カスタムの場所',
			'settings.selectFolder' => 'フォルダを選択',
			'settings.resetToDefault' => 'デフォルトに戻す',
			'settings.currentPath' => ({required Object path}) => '現在: ${path}',
			'settings.downloadLocationChanged' => 'ダウンロード場所を変更しました',
			'settings.downloadLocationReset' => 'ダウンロード場所をデフォルトにリセットしました',
			'settings.downloadLocationInvalid' => '選択したフォルダは書き込みできません',
			'settings.downloadLocationSelectError' => 'フォルダの選択に失敗しました',
			'settings.downloadOnWifiOnly' => 'WiFiのみでダウンロード',
			'settings.downloadOnWifiOnlyDescription' => 'モバイルデータ通信時のダウンロードを防止',
			'settings.autoRemoveWatchedDownloads' => '視聴済みダウンロードの自動削除',
			'settings.autoRemoveWatchedDownloadsDescription' => '視聴済みのダウンロードを自動削除します',
			'settings.cellularDownloadBlocked' => 'モバイル通信ではダウンロードがブロックされています。WiFiを使うか設定を変更してください。',
			'settings.maxVolume' => '最大音量',
			'settings.maxVolumeDescription' => '静かなメディアに対して100%以上の音量ブーストを許可',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Discordで視聴中の内容を表示',
			'settings.services' => 'サービス',
			'settings.servicesDescription' => 'Trakt、MyAnimeList、Seerr などを接続',
			'settings.manageLibrariesDescription' => 'ライブラリを並べ替えたり非表示にしたりできます',
			'settings.companionRemoteServer' => 'コンパニオンリモートサーバー',
			'settings.companionRemoteServerDescription' => 'ネットワーク上のモバイルデバイスからこのアプリを操作できるようにする',
			'settings.autoPip' => '自動ピクチャーインピクチャー',
			'settings.autoPipDescription' => '再生中に離れるとピクチャーインピクチャーに入ります',
			'settings.matchContentFrameRate' => 'コンテンツのフレームレートに合わせる',
			'settings.matchContentFrameRateDescription' => '表示のリフレッシュレートを動画コンテンツに合わせます',
			'settings.matchRefreshRate' => 'リフレッシュレートを合わせる',
			'settings.matchRefreshRateDescription' => '全画面時に表示のリフレッシュレートを合わせます',
			'settings.matchDynamicRange' => 'ダイナミックレンジを合わせる',
			'settings.matchDynamicRangeDescription' => 'HDRコンテンツではHDRに切り替え、その後SDRに戻します',
			'settings.displaySwitchDelay' => 'ディスプレイ切り替え遅延',
			'settings.tunneledPlayback' => 'トンネル再生',
			'settings.tunneledPlaybackDescription' => '動画トンネリングを使用します。HDR再生で画面が黒くなる場合は無効にしてください。',
			'settings.audioPassthrough' => 'オーディオパススルー',
			'settings.audioPassthroughDescription' => 'Dolby/DTS音声を再エンコードせずにレシーバーやテレビに送り、サラウンドを維持します。音が出ない場合は無効にしてください。',
			'settings.audioPassthroughDescriptionAppleTv' => 'Dolby Digital Plus（Atmos含む）をビットストリームとしてシステムに渡します。DTSとTrueHDは引き続きマルチチャンネルPCMで再生されます。シーク時に短い音切れが発生することがあります。',
			'settings.audioDownmix' => 'ステレオにダウンミックス',
			'settings.audioDownmixDescription' => 'サラウンド音声をステレオスピーカーやヘッドホン用に2チャンネルへミックスします',
			'settings.downmixCenterBoost' => 'センターチャンネルブースト',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'ブースト (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'ダウンミックス時の音量正規化',
			'settings.audioDownmixNormalizeDescription' => 'クリッピングを防ぐためにミックス音量を下げます。オフにすると元の音量を維持します（大音量シーンで歪む場合があります）。',
			'settings.atmosDiagnostics' => 'Atmos出力テスト',
			'settings.atmosDiagnosticsDescription' => 'システムプレイヤーでテスト信号を再生してDolby Atmos出力を診断します',
			'settings.atmosTestHlsAtmos' => 'Apple Atmosストリーム',
			'settings.atmosTestHlsAtmosDescription' => '動作確認済みのDolby Atmosストリーム。レシーバーにDolby Atmosと表示されるはずです。',
			'settings.atmosTestHlsControl' => 'Appleサラウンドストリーム',
			'settings.atmosTestHlsControlDescription' => 'Atmosなしの比較用ストリーム。レシーバーにAtmosなしのサラウンドが表示されるはずです。',
			'settings.atmosTestRawStream' => '生EAC3ストリーム',
			'settings.atmosTestRawStreamDescription' => 'プレイヤー内のAtmos再生と同じ方式でテストファイルをストリーミングします。テストファイルのURLが必要です。',
			'settings.atmosTestRawFile' => '生EAC3ファイル',
			'settings.atmosTestRawFileDescription' => '長さが既知のテストファイルを再生します。テストファイルのURLが必要です。',
			'settings.atmosTestStop' => 'テストを停止',
			'settings.atmosTestUrl' => 'テストファイルのURL',
			'settings.atmosTestUrlDescription' => '生の.ec3 Dolby AtmosファイルのHTTP URL（例: ffmpegで抽出）',
			'settings.atmosTestUrlMissing' => '先にテストファイルのURLを設定してください',
			'settings.atmosTestStatus' => 'ステータス',
			'settings.dvConversionMode' => 'Dolby Vision 変換',
			'settings.dvConversionModeDescription' => 'ExoPlayer が Dolby Vision Profile 7 ファイルを処理する方法を選択します。',
			'settings.dvConversionAuto' => '自動',
			'settings.dvConversionNative' => 'ネイティブ / 無効',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'デバイスの機能検出と通常のフォールバック動作を使用します',
			'settings.dvConversionNativeDescription' => 'ネイティブ DV7 を強制し、DV 変換の再試行を抑制します',
			'settings.dvConversionDv81Description' => 'Dolby Vision プロファイル 8.1 へのインライン RPU 変換を強制します',
			'settings.dvConversionHevcStripDescription' => 'Dolby Vision の RPU/EL レイヤーを削除し、通常の HEVC として扱います',
			'settings.requireProfileSelectionOnOpen' => 'アプリ起動時にプロフィールを確認',
			'settings.requireProfileSelectionOnOpenDescription' => 'アプリを開くたびにプロフィール選択を表示',
			'settings.forceTvMode' => 'TVモードを強制',
			'settings.forceTvModeDescription' => 'TVレイアウトを強制します。自動検出しないデバイス向けです。再起動が必要です。',
			'settings.startInFullscreen' => '全画面表示で起動',
			'settings.startInFullscreenDescription' => '起動時にPlezyを全画面モードで開きます',
			'settings.exitFullscreenOnPlayerClose' => 'プレイヤーを閉じたときに全画面を終了',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'ビデオプレイヤーを閉じたときに自動的に全画面モードを終了します',
			'settings.autoHidePerformanceOverlay' => 'パフォーマンスオーバーレイを自動非表示',
			'settings.autoHidePerformanceOverlayDescription' => '再生コントロールと一緒にパフォーマンスオーバーレイをフェードする',
			'settings.showNavBarLabels' => 'ナビゲーションバーラベルを表示',
			'settings.showNavBarLabelsDescription' => 'ナビゲーションバーアイコンの下にテキストラベルを表示',
			'settings.startupSection' => '起動時のセクション',
			'settings.liveTvDefaultFavorites' => 'お気に入りチャンネルをデフォルトに',
			'settings.liveTvDefaultFavoritesDescription' => 'ライブTV を開いたときにお気に入りチャンネルのみ表示',
			'settings.display' => 'ディスプレイ',
			'settings.homeScreen' => 'ホーム画面',
			'settings.navigation' => 'ナビゲーション',
			'settings.window' => 'ウィンドウ',
			'settings.content' => 'コンテンツ',
			'settings.player' => 'プレーヤー',
			'settings.subtitlesAndConfig' => '字幕と設定',
			'settings.seekAndTiming' => 'シークとタイミング',
			'settings.behavior' => '動作',
			'search.hint' => '映画、番組、音楽を検索...',
			'search.tryDifferentTerm' => '別の検索語をお試しください',
			'search.searchYourMedia' => 'メディアを検索',
			'search.enterTitleActorOrKeyword' => 'タイトル、俳優、またはキーワードを入力',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => '${actionName}のショートカットを設定',
			'hotkeys.clearShortcut' => 'ショートカットをクリア',
			'hotkeys.noShortcutSet' => 'ショートカット未設定',
			'hotkeys.currentShortcut' => '現在のショートカット:',
			'hotkeys.pressToRecord' => '選択してショートカットを記録',
			'hotkeys.recordingShortcut' => 'ショートカットを押してください',
			'hotkeys.actions.playPause' => '再生/一時停止',
			'hotkeys.actions.volumeUp' => '音量を上げる',
			'hotkeys.actions.volumeDown' => '音量を下げる',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => '前方にシーク (${seconds}秒)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => '後方にシーク (${seconds}秒)',
			'hotkeys.actions.fullscreenToggle' => 'フルスクリーン切替',
			'hotkeys.actions.muteToggle' => 'ミュート切替',
			'hotkeys.actions.subtitleToggle' => '字幕切替',
			'hotkeys.actions.audioTrackNext' => '次の音声トラック',
			'hotkeys.actions.subtitleTrackNext' => '次の字幕トラック',
			'hotkeys.actions.chapterNext' => '次のチャプター',
			'hotkeys.actions.chapterPrevious' => '前のチャプター',
			'hotkeys.actions.episodeNext' => '次のエピソード',
			'hotkeys.actions.episodePrevious' => '前のエピソード',
			'hotkeys.actions.speedIncrease' => '速度を上げる',
			'hotkeys.actions.speedDecrease' => '速度を下げる',
			'hotkeys.actions.speedReset' => '速度をリセット',
			'hotkeys.actions.zoomIn' => 'ズームイン',
			'hotkeys.actions.zoomOut' => 'ズームアウト',
			'hotkeys.actions.zoomReset' => 'ズームをリセット',
			'hotkeys.actions.subSeekNext' => '次の字幕にシーク',
			'hotkeys.actions.subSeekPrev' => '前の字幕にシーク',
			'hotkeys.actions.shaderToggle' => 'シェーダー切替',
			'hotkeys.actions.skipMarker' => 'イントロ/クレジットをスキップ',
			'hotkeys.actions.screenshot' => 'スクリーンショットを撮る',
			'fileInfo.title' => 'ファイル情報',
			'fileInfo.video' => '映像',
			'fileInfo.audio' => '音声',
			'fileInfo.file' => 'ファイル',
			'fileInfo.advanced' => '詳細',
			'fileInfo.codec' => 'コーデック',
			'fileInfo.resolution' => '解像度',
			'fileInfo.bitrate' => 'ビットレート',
			'fileInfo.frameRate' => 'フレームレート',
			'fileInfo.aspectRatio' => 'アスペクト比',
			'fileInfo.profile' => 'プロファイル',
			'fileInfo.bitDepth' => 'ビット深度',
			'fileInfo.colorSpace' => '色空間',
			'fileInfo.colorRange' => '色範囲',
			'fileInfo.colorPrimaries' => '色原色',
			'fileInfo.chromaSubsampling' => 'クロマサブサンプリング',
			'fileInfo.channels' => 'チャンネル',
			'fileInfo.subtitles' => '字幕',
			'fileInfo.overallBitrate' => '全体ビットレート',
			'fileInfo.path' => 'パス',
			'fileInfo.size' => 'サイズ',
			'fileInfo.container' => 'コンテナ',
			'fileInfo.duration' => '長さ',
			'fileInfo.optimizedForStreaming' => 'ストリーミング最適化',
			'fileInfo.has64bitOffsets' => '64ビットオフセット',
			'mediaMenu.markAsWatched' => '視聴済みにする',
			'mediaMenu.markAsUnwatched' => '未視聴にする',
			'mediaMenu.removeFromContinueWatching' => '視聴中から削除',
			'mediaMenu.viewDetails' => '詳細を表示',
			'mediaMenu.goToSeries' => 'シリーズへ移動',
			'mediaMenu.shufflePlay' => 'シャッフル再生',
			'mediaMenu.shuffleNotAvailableOffline' => 'オフラインではシャッフルを利用できません',
			'mediaMenu.fileInfo' => 'ファイル情報',
			'mediaMenu.deleteFromServer' => 'サーバーから削除',
			'mediaMenu.confirmDelete' => 'このメディアとそのファイルをサーバーから削除しますか？',
			'mediaMenu.deleteMultipleWarning' => 'すべてのエピソードとそのファイルが含まれます。',
			'mediaMenu.mediaDeletedSuccessfully' => 'メディアアイテムを正常に削除しました',
			'mediaMenu.mediaFailedToDelete' => 'メディアアイテムの削除に失敗しました',
			'mediaMenu.rate' => '評価',
			'mediaMenu.playFromBeginning' => '最初から再生',
			'mediaMenu.playVersion' => 'バージョンを再生...',
			'rateSheet.title' => '評価',
			'rateSheet.server' => 'サーバー',
			'rateSheet.favorite' => 'お気に入り',
			'rateSheet.favorited' => 'お気に入りに追加済み',
			'rateSheet.saved' => '保存済み',
			'rateSheet.notAvailable' => '一致なし',
			'rateSheet.noConnectedServices' => '評価するには、設定でサービスを接続してください。',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}、映画',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}、テレビ番組',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}、${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}、${seasonInfo}',
			'accessibility.mediaCardWatched' => '視聴済み',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent}パーセント視聴済み',
			'accessibility.mediaCardUnwatched' => '未視聴',
			'accessibility.tapToPlay' => 'タップして再生',
			'accessibility.decrease' => '下げる',
			'accessibility.increase' => '上げる',
			'accessibility.decreaseValue' => ({required Object label}) => '${label}を下げる',
			'accessibility.increaseValue' => ({required Object label}) => '${label}を上げる',
			'accessibility.hue' => '色相',
			'accessibility.saturation' => '彩度',
			'accessibility.brightness' => '明るさ',
			'accessibility.hexColor' => '16進カラー',
			'accessibility.expandText' => 'テキストを展開',
			'accessibility.collapseText' => 'テキストを折りたたむ',
			'tooltips.shufflePlay' => 'シャッフル再生',
			'tooltips.playTrailer' => '予告編を再生',
			'tooltips.markAsWatched' => '視聴済みにする',
			'tooltips.markAsUnwatched' => '未視聴にする',
			'videoControls.audioLabel' => '音声',
			'videoControls.subtitlesLabel' => '字幕',
			'videoControls.resetToZero' => '0msにリセット',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount}${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label}遅く再生',
			'videoControls.playsEarlier' => ({required Object label}) => '${label}早く再生',
			'videoControls.noOffset' => 'オフセットなし',
			'videoControls.letterbox' => 'レターボックス',
			'videoControls.fillScreen' => '画面を埋める',
			'videoControls.stretch' => '引き延ばす',
			'videoControls.lockRotation' => '回転をロック',
			'videoControls.unlockRotation' => '回転のロックを解除',
			'videoControls.timerActive' => 'タイマー動作中',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => '再生は${duration}後に一時停止します',
			'videoControls.sleepTimerEndOfVideo' => '現在の動画の最後',
			'videoControls.sleepTimerStopAtHeader' => '停止のタイミング',
			'videoControls.sleepTimerDurationHeader' => 'タイマー',
			'videoControls.playbackWillPauseAtEnd' => '再生はこの動画の最後に一時停止します',
			'videoControls.stillWatching' => 'まだ視聴中ですか？',
			'videoControls.pausingIn' => ({required Object seconds}) => '${seconds}秒後に一時停止',
			'videoControls.continueWatching' => '続ける',
			'videoControls.autoPlayNext' => '次を自動再生',
			'videoControls.playNext' => '次を再生',
			'videoControls.playButton' => '再生',
			'videoControls.pauseButton' => '一時停止',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => '${seconds}秒戻る',
			'videoControls.seekForwardButton' => ({required Object seconds}) => '${seconds}秒進む',
			'videoControls.previousButton' => '前のエピソード',
			'videoControls.nextButton' => '次のエピソード',
			'videoControls.previousChapterButton' => '前のチャプター',
			'videoControls.nextChapterButton' => '次のチャプター',
			'videoControls.muteButton' => 'ミュート',
			'videoControls.unmuteButton' => 'ミュート解除',
			'videoControls.settingsButton' => '再生設定',
			'videoControls.tracksButton' => '音声と字幕',
			'videoControls.chaptersButton' => 'チャプター',
			'videoControls.versionQualityButton' => 'バージョンと画質',
			'videoControls.versionColumnHeader' => 'バージョン',
			'videoControls.qualityColumnHeader' => '画質',
			'videoControls.qualityOriginal' => 'オリジナル',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'トランスコードは利用できません — オリジナル画質で再生中',
			'videoControls.pipButton' => 'ピクチャーインピクチャーモード',
			'videoControls.aspectRatioButton' => 'アスペクト比',
			'videoControls.ambientLighting' => 'アンビエントライティング',
			'videoControls.fullscreenButton' => 'フルスクリーンに入る',
			'videoControls.exitFullscreenButton' => 'フルスクリーンを終了',
			'videoControls.alwaysOnTopButton' => '常に前面に表示',
			'videoControls.rotationLockButton' => '回転ロック',
			'videoControls.lockScreen' => '画面をロック',
			'videoControls.screenLockButton' => '画面ロック',
			'videoControls.longPressToUnlock' => '長押しでロック解除',
			'videoControls.timelineSlider' => '動画タイムライン',
			'videoControls.volumeSlider' => '音量レベル',
			'videoControls.endsAt' => ({required Object time}) => '${time}に終了',
			'videoControls.pipActive' => 'ピクチャーインピクチャーで再生中',
			'videoControls.pipFailed' => 'ピクチャーインピクチャーの開始に失敗しました',
			'videoControls.screenshotSaved' => 'スクリーンショットを保存しました',
			'videoControls.zoomPercent' => ({required Object percent}) => 'ズーム ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Android 8.0以降が必要です',
			'videoControls.pipErrors.iosVersion' => 'iOS 15.0以降が必要です',
			'videoControls.pipErrors.permissionDisabled' => 'ピクチャーインピクチャーが無効です。システム設定で有効にしてください。',
			'videoControls.pipErrors.notSupported' => 'デバイスはピクチャーインピクチャーモードをサポートしていません',
			'videoControls.pipErrors.voSwitchFailed' => 'ピクチャーインピクチャーの映像出力切替に失敗しました',
			'videoControls.pipErrors.failed' => 'ピクチャーインピクチャーの開始に失敗しました',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'エラーが発生しました: ${error}',
			'videoControls.chapters' => 'チャプター',
			'videoControls.noChaptersAvailable' => 'チャプターがありません',
			'videoControls.queue' => 'キュー',
			'videoControls.noQueueItems' => 'キューにアイテムがありません',
			'videoControls.searchSubtitles' => '字幕を検索',
			'videoControls.language' => '言語',
			'videoControls.noSubtitlesFound' => '字幕が見つかりません',
			'videoControls.downloadedSubtitle' => 'ダウンロード済み',
			'videoControls.noSubtitlesAvailable' => '利用可能な字幕はありません',
			'videoControls.noAudioTracksAvailable' => '利用可能な音声トラックはありません',
			'videoControls.noTracksAvailable' => '利用可能なトラックはありません',
			'videoControls.subtitleDownloaded' => '字幕をダウンロードしました',
			'videoControls.subtitleDownloadFailed' => '字幕のダウンロードに失敗しました',
			'videoControls.searchLanguages' => '言語を検索...',
			'messages.markedAsWatched' => '視聴済みにしました',
			'messages.markedAsUnwatched' => '未視聴にしました',
			'messages.markedAsWatchedOffline' => '視聴済みにしました（オンライン時に同期）',
			'messages.markedAsUnwatchedOffline' => '未視聴にしました（オンライン時に同期）',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => '自動削除: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, other: '視聴済みダウンロードを${n}件自動削除しました', ), 
			'messages.removedFromContinueWatching' => '視聴中から削除しました',
			'messages.errorLoading' => ({required Object error}) => 'エラー: ${error}',
			'messages.streamInterrupted' => 'ストリームが中断されました。再生を押すかシークして再試行してください。',
			'messages.liveStreamInterrupted' => 'ライブストリームが中断されました。再生を押して再試行してください。',
			'messages.fileInfoNotAvailable' => 'ファイル情報が利用できません',
			_ => null,
		} ?? switch (path) {
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'ファイル情報の読み込みエラー: ${error}',
			'messages.errorLoadingSeries' => 'シリーズの読み込みエラー',
			'messages.musicNotSupported' => '音楽の再生はまだサポートされていません',
			'messages.noDescriptionAvailable' => '説明はありません',
			'messages.noProfilesAvailable' => '利用可能なプロフィールがありません',
			'messages.contactAdminForProfiles' => 'プロファイルを追加するにはサーバー管理者に連絡してください',
			'messages.unableToDetermineLibrarySection' => 'このアイテムのライブラリセクションを判別できません',
			'messages.logsCleared' => 'ログをクリアしました',
			'messages.logsCopied' => 'ログをクリップボードにコピーしました',
			'messages.noLogsAvailable' => 'ログがありません',
			'messages.libraryScanning' => ({required Object title}) => '"${title}"をスキャン中...',
			'messages.libraryScanStarted' => ({required Object title}) => '"${title}"のライブラリスキャンを開始しました',
			'messages.libraryScanFailed' => ({required Object error}) => 'ライブラリのスキャンに失敗しました: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => '"${title}"のメタデータを更新中...',
			'messages.metadataRefreshStarted' => ({required Object title}) => '"${title}"のメタデータ更新を開始しました',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'メタデータの更新に失敗しました: ${error}',
			'messages.logoutConfirm' => 'ログアウトしてもよろしいですか？',
			'messages.noSeasonsFound' => 'シーズンが見つかりません',
			'messages.seasonsLoadFailed' => 'シーズンを読み込めませんでした',
			'messages.noEpisodesFound' => '最初のシーズンにエピソードが見つかりません',
			'messages.noEpisodesFoundGeneral' => 'エピソードが見つかりません',
			'messages.episodesLoadFailed' => 'エピソードを読み込めませんでした',
			'messages.noResultsFound' => '結果が見つかりません',
			'messages.sleepTimerSet' => ({required Object label}) => 'スリープタイマーを${label}に設定しました',
			'messages.noItemsAvailable' => 'アイテムがありません',
			'messages.failedToCreatePlayQueueNoItems' => '再生キューの作成に失敗しました - アイテムがありません',
			'messages.failedPlayback' => ({required Object action, required Object error}) => '${action}に失敗しました: ${error}',
			'messages.switchingToCompatiblePlayer' => '互換プレーヤーに切替中...',
			'messages.serverLimitTitle' => '再生に失敗しました',
			'messages.serverLimitBody' => 'サーバーエラー（HTTP 500）。帯域幅/トランスコード制限により拒否された可能性があります。所有者に調整を依頼してください。',
			'messages.logsUploaded' => 'ログをアップロードしました',
			'messages.logsUploadFailed' => 'ログのアップロードに失敗しました',
			'messages.logId' => 'ログID',
			'subtitlingStyling.text' => 'テキスト',
			'subtitlingStyling.border' => '枠線',
			'subtitlingStyling.background' => '背景',
			'subtitlingStyling.fontSize' => 'フォントサイズ',
			'subtitlingStyling.textColor' => 'テキストの色',
			'subtitlingStyling.borderSize' => '枠線サイズ',
			'subtitlingStyling.borderColor' => '枠線の色',
			'subtitlingStyling.backgroundOpacity' => '背景の不透明度',
			'subtitlingStyling.backgroundColor' => '背景色',
			'subtitlingStyling.position' => '位置',
			'subtitlingStyling.assOverride' => 'ASSオーバーライド',
			'subtitlingStyling.overrideScale' => '拡大縮小',
			'subtitlingStyling.overrideForce' => '強制',
			'subtitlingStyling.overrideStrip' => 'スタイルを削除',
			'subtitlingStyling.positionTop' => '上',
			'subtitlingStyling.positionBottom' => '下',
			'subtitlingStyling.bold' => '太字',
			'subtitlingStyling.italic' => '斜体',
			'subtitlingStyling.renderResolution' => 'レンダリング解像度',
			'subtitlingStyling.renderResolutionScreen' => '画面解像度',
			'subtitlingStyling.renderResolutionVideo' => '動画解像度',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => '高度な動画プレーヤー設定',
			'mpvConfig.presets' => 'プリセット',
			'mpvConfig.noPresets' => '保存済みプリセットがありません',
			'mpvConfig.saveAsPreset' => 'プリセットとして保存...',
			'mpvConfig.presetName' => 'プリセット名',
			'mpvConfig.presetNameHint' => 'プリセットの名前を入力',
			'mpvConfig.loadPreset' => '読み込み',
			'mpvConfig.deletePreset' => '削除',
			'mpvConfig.presetSaved' => 'プリセットを保存しました',
			'mpvConfig.presetLoaded' => 'プリセットを読み込みました',
			'mpvConfig.presetDeleted' => 'プリセットを削除しました',
			'mpvConfig.confirmDeletePreset' => 'このプリセットを削除してもよろしいですか？',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comment',
			'dialog.confirmAction' => '操作の確認',
			'profiles.addPlezyProfile' => 'Plezyプロファイルを追加',
			'profiles.switchingProfile' => 'プロファイルを切り替え中…',
			'profiles.deleteThisProfileTitle' => 'このプロファイルを削除しますか？',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => '${displayName}を削除します。接続には影響しません。',
			'profiles.active' => 'アクティブ',
			'profiles.manage' => '管理',
			'profiles.delete' => '削除',
			'profiles.signOut' => 'サインアウト',
			'profiles.signOutPlexTitle' => 'Plex からサインアウトしますか？',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => '${displayName}とすべてのPlex Homeユーザーを削除しますか？いつでも再サインインできます。',
			'profiles.signedOutPlex' => 'Plex からサインアウトしました。',
			'profiles.signOutFailed' => 'サインアウトに失敗しました。',
			'profiles.sectionTitle' => 'プロファイル',
			'profiles.summarySingle' => 'プロファイルを追加して、管理対象ユーザーとローカルIDを混在させます',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count}個のプロファイル · アクティブ: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count}個のプロファイル',
			'profiles.removeConnectionTitle' => '接続を削除しますか？',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => '${displayName}の${connectionLabel}へのアクセスを削除します。他のプロフィールには残ります。',
			'profiles.deleteProfileTitle' => 'プロファイルを削除しますか？',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => '${displayName}とその接続を削除します。サーバーは引き続き利用できます。',
			'profiles.profileNameLabel' => 'プロファイル名',
			'profiles.pinProtectionLabel' => 'PIN保護',
			'profiles.pinManagedByPlex' => 'PINはPlexで管理されています。plex.tvで編集してください。',
			'profiles.noPinSetEditOnPlex' => 'PINが設定されていません。要求するには、plex.tvでHomeユーザーを編集してください。',
			'profiles.setPin' => 'PINを設定',
			'profiles.setPinTitle' => 'PINを設定',
			'profiles.confirmPinTitle' => 'PINを確認',
			'profiles.pinSet' => 'PIN設定済み',
			'profiles.changePin' => '変更',
			'profiles.removePin' => '削除',
			'profiles.connectionsLabel' => '接続',
			'profiles.add' => '追加',
			'profiles.deleteProfileButton' => 'プロファイルを削除',
			'profiles.noConnectionsHint' => '接続がありません — このプロファイルを使うには1つ追加してください。',
			'profiles.noConnections' => '接続がありません',
			'profiles.plexHomeAccount' => 'Plex Homeアカウント',
			'profiles.connectionDefault' => 'デフォルト',
			'profiles.connectionAs' => ({required Object displayName}) => '${displayName}として',
			'profiles.makeDefault' => 'デフォルトに設定',
			'profiles.removeConnection' => '削除',
			'profiles.profileRenamed' => 'プロフィール名を変更しました。',
			'profiles.borrowAddTo' => ({required Object displayName}) => '${displayName}に追加',
			'profiles.borrowExplain' => '別のプロフィールの接続を借用します。PIN保護されたプロフィールにはPINが必要です。',
			'profiles.borrowEmpty' => 'まだ借りるものがありません。',
			'profiles.borrowEmptySubtitle' => 'まず別のプロフィールにPlexまたはJellyfinを接続してください。',
			'profiles.borrowFromProfile' => ({required Object displayName}) => '${displayName}から',
			'profiles.borrowConnectionBorrowed' => '接続を借用しました。',
			'profiles.borrowFailed' => '接続を借用できませんでした。',
			'profiles.incorrectPin' => 'PINが正しくありません。',
			'profiles.incorrectPinTryAgain' => 'PINが正しくありません。もう一度お試しください。',
			'profiles.sourceProfileMissingParentAccount' => 'ソースプロフィールに親アカウントがありません。',
			'profiles.failedToLoadHomeUsers' => 'Plex Homeユーザーを読み込めませんでした。接続を確認して、もう一度お試しください。',
			'profiles.failedToVerifyPin' => 'PINを確認できませんでした。',
			'profiles.newProfile' => '新しいプロファイル',
			'profiles.profileNameHint' => '例：ゲスト、キッズ、ファミリールーム',
			'profiles.pinProtectionOptional' => 'PIN保護（オプション）',
			'profiles.pinExplain' => 'プロフィール切り替えには4桁のPINが必要です。',
			'profiles.continueButton' => '続ける',
			'profiles.pinsDontMatch' => 'PINが一致しません',
			'connections.sectionTitle' => '接続',
			'connections.addConnection' => '接続を追加',
			'connections.addConnectionSubtitleNoProfile' => 'Plexでサインインするか、Jellyfinサーバーに接続',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => '${displayName}に追加: Plex、Jellyfin、または別プロフィールの接続',
			'connections.sessionExpiredOne' => ({required Object name}) => '${name} のセッションの有効期限が切れました',
			'connections.sessionExpiredMany' => ({required Object count}) => '${count} 台のサーバーのセッションの有効期限が切れました',
			'connections.signInAgain' => '再度サインイン',
			'connections.editJellyfinTitle' => 'Jellyfin接続を編集',
			'connections.editJellyfinIntro' => ({required Object serverName}) => '${serverName} のURLを追加または削除します。Plezyは到達可能なURLのうち最も低遅延のものを使用します。',
			'discover.title' => '探す',
			'discover.noContentAvailable' => 'コンテンツがありません',
			'discover.addMediaToLibraries' => 'ライブラリにメディアを追加してください',
			'discover.continueWatching' => '視聴を続ける',
			'discover.continueWatchingIn' => ({required Object library}) => '${library}の視聴を続ける',
			'discover.nextUp' => '次のエピソード',
			'discover.nextUpIn' => ({required Object library}) => '${library}の次のエピソード',
			'discover.recentlyAdded' => '最近追加',
			'discover.recentlyAddedIn' => ({required Object library}) => '${library}に最近追加',
			'discover.latestAlbumsIn' => ({required Object library}) => '${library}の最新アルバム',
			'discover.recentlyPlayedIn' => ({required Object library}) => '${library}で最近再生',
			'discover.mostPlayedIn' => ({required Object library}) => '${library}で最も再生',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'あらすじ',
			'discover.cast' => 'キャスト',
			'discover.extras' => '予告編とエクストラ',
			'discover.studio' => 'スタジオ',
			'discover.rating' => '評価',
			'discover.movie' => '映画',
			'discover.tvShow' => 'テレビ番組',
			'discover.minutesLeft' => ({required Object minutes}) => '残り${minutes}分',
			'discover.moreLikeThis' => '似ている作品',
			'errors.searchFailed' => ({required Object error}) => '検索に失敗しました: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => '${context}の読み込み中に接続がタイムアウトしました',
			'errors.connectionFailed' => 'メディアサーバーに接続できません',
			'errors.unableToLoad' => ({required Object context}) => '${context}を読み込めませんでした。もう一度お試しください。',
			'errors.noClientAvailable' => 'クライアントが利用できません',
			'errors.pleaseEnterToken' => 'トークンを入力してください',
			'errors.invalidToken' => '無効なトークン',
			'errors.failedToVerifyToken' => ({required Object error}) => 'トークンの検証に失敗しました: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => '${displayName}への切替に失敗しました',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => '${displayName}の削除に失敗しました',
			'errors.failedToRate' => '評価を更新できませんでした',
			'libraries.title' => 'ライブラリ',
			'libraries.fallbackTitle' => 'ライブラリ',
			'libraries.scanLibraryFiles' => 'ライブラリファイルをスキャン',
			'libraries.scanLibrary' => 'ライブラリをスキャン',
			'libraries.analyze' => '解析',
			'libraries.analyzeLibrary' => 'ライブラリを解析',
			'libraries.refreshMetadata' => 'メタデータを更新',
			'libraries.emptyTrash' => 'ゴミ箱を空にする',
			'libraries.emptyingTrash' => ({required Object title}) => '"${title}"のゴミ箱を空にしています...',
			'libraries.trashEmptied' => ({required Object title}) => '"${title}"のゴミ箱を空にしました',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'ゴミ箱を空にできませんでした: ${error}',
			'libraries.analyzing' => ({required Object title}) => '"${title}"を解析中...',
			'libraries.analysisStarted' => ({required Object title}) => '"${title}"の解析を開始しました',
			'libraries.failedToAnalyze' => ({required Object error}) => 'ライブラリの解析に失敗しました: ${error}',
			'libraries.noLibrariesFound' => 'ライブラリが見つかりません',
			'libraries.allLibrariesHidden' => 'すべてのライブラリが非表示です',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => '非表示のライブラリ (${count})',
			'libraries.thisLibraryIsEmpty' => 'このライブラリは空です',
			'libraries.noItemsMatchFilters' => '有効なフィルターに一致する項目はありません',
			'libraries.resetFilters' => 'フィルターをリセット',
			'libraries.all' => 'すべて',
			'libraries.clearAll' => 'すべてクリア',
			'libraries.scanLibraryConfirm' => ({required Object title}) => '"${title}"をスキャンしてもよろしいですか？',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => '"${title}"を解析してもよろしいですか？',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => '"${title}"のメタデータを更新してもよろしいですか？',
			'libraries.emptyTrashConfirm' => ({required Object title}) => '"${title}"のゴミ箱を空にしてもよろしいですか？',
			'libraries.manageLibraries' => 'ライブラリを管理',
			'libraries.sort' => '並べ替え',
			'libraries.sortBy' => '並べ替え順',
			'libraries.filters' => 'フィルター',
			'libraries.confirmActionMessage' => 'この操作を実行してもよろしいですか？',
			'libraries.showLibrary' => 'ライブラリを表示',
			'libraries.hideLibrary' => 'ライブラリを非表示',
			'libraries.libraryOptions' => 'ライブラリオプション',
			'libraries.content' => 'ライブラリコンテンツ',
			'libraries.selectLibrary' => 'ライブラリを選択',
			'libraries.filtersWithCount' => ({required Object count}) => 'フィルター (${count})',
			'libraries.noRecommendations' => 'おすすめがありません',
			'libraries.noCollections' => 'このライブラリにコレクションがありません',
			'libraries.noFoldersFound' => 'フォルダが見つかりません',
			'libraries.folders' => 'フォルダ',
			'libraries.tabs.recommended' => 'おすすめ',
			'libraries.tabs.browse' => 'ブラウズ',
			'libraries.tabs.collections' => 'コレクション',
			'libraries.tabs.playlists' => 'プレイリスト',
			'libraries.groupings.title' => 'グループ',
			'libraries.groupings.all' => 'すべて',
			'libraries.groupings.movies' => '映画',
			'libraries.groupings.shows' => 'テレビ番組',
			'libraries.groupings.seasons' => 'シーズン',
			'libraries.groupings.episodes' => 'エピソード',
			'libraries.groupings.artists' => 'アーティスト',
			'libraries.groupings.albums' => 'アルバム',
			'libraries.groupings.tracks' => '曲',
			'libraries.groupings.folders' => 'フォルダ',
			'libraries.filterCategories.genre' => 'ジャンル',
			'libraries.filterCategories.year' => '年',
			'libraries.filterCategories.contentRating' => '視聴年齢区分',
			'libraries.filterCategories.tag' => 'タグ',
			'libraries.filterCategories.unwatched' => '未視聴',
			'libraries.filterCategories.unplayed' => '未再生',
			'libraries.filterCategories.favorites' => 'お気に入り',
			'libraries.sortLabels.title' => 'タイトル',
			'libraries.sortLabels.dateAdded' => '追加日',
			'libraries.sortLabels.releaseDate' => 'リリース日',
			'libraries.sortLabels.rating' => '評価',
			'libraries.sortLabels.communityRating' => 'コミュニティ評価',
			'libraries.sortLabels.criticRating' => '批評家評価',
			'libraries.sortLabels.userRating' => 'ユーザー評価',
			'libraries.sortLabels.datePlayed' => '再生日',
			'libraries.sortLabels.playCount' => '再生回数',
			'libraries.sortLabels.productionYear' => '製作年',
			'libraries.sortLabels.runtime' => '再生時間',
			'libraries.sortLabels.officialRating' => '公式レーティング',
			'libraries.sortLabels.premiereDate' => 'プレミア日',
			'libraries.sortLabels.startDate' => '開始日',
			'libraries.sortLabels.airTime' => '放送時刻',
			'libraries.sortLabels.studio' => 'スタジオ',
			'libraries.sortLabels.random' => 'ランダム',
			'libraries.sortLabels.dateShared' => '共有日',
			'libraries.sortLabels.latestEpisodeAirDate' => '最新エピソード放送日',
			'libraries.sortLabels.lastEpisodeDateAdded' => '最新エピソード追加日',
			'about.title' => 'アプリについて',
			'about.openSourceLicenses' => 'オープンソースライセンス',
			'about.versionLabel' => ({required Object version}) => 'バージョン ${version}',
			'about.appDescription' => 'Flutter製の美しいPlex・Jellyfinクライアント',
			'about.viewLicensesDescription' => 'サードパーティライブラリのライセンスを表示',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => '${username} (${email})のサーバーが見つかりません',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'サーバーの読み込みに失敗しました: ${error}',
			'hubDetail.title' => 'タイトル',
			'hubDetail.releaseYear' => '公開年',
			'hubDetail.dateAdded' => '追加日',
			'hubDetail.rating' => '評価',
			'hubDetail.noItemsFound' => 'アイテムが見つかりません',
			'logs.clearLogs' => 'ログをクリア',
			'logs.copyLogs' => 'ログをコピー',
			'logs.uploadLogs' => 'ログをアップロード',
			'licenses.relatedPackages' => '関連パッケージ',
			'licenses.license' => 'ライセンス',
			'licenses.licenseNumber' => ({required Object number}) => 'ライセンス ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count}件のライセンス',
			'navigation.libraries' => 'ライブラリ',
			'navigation.downloads' => 'ダウンロード',
			'navigation.liveTv' => 'ライブTV',
			'navigation.explore' => '探索',
			'explore.title' => '探索',
			'explore.selectSource' => 'ソースを選択',
			'explore.rows.watchlist' => 'ウォッチリスト',
			'explore.rows.recommendedMovies' => 'おすすめの映画',
			'explore.rows.recommendedShows' => 'おすすめのテレビ番組',
			'explore.rows.trendingMovies' => 'トレンドの映画',
			'explore.rows.trendingShows' => 'トレンドのテレビ番組',
			'explore.rows.popularMovies' => '人気の映画',
			'explore.rows.popularShows' => '人気のテレビ番組',
			'explore.rows.suggestedAnime' => 'おすすめのアニメ',
			'explore.rows.airingAnime' => '放送中の注目アニメ',
			'explore.rows.popularAnime' => '人気のアニメ',
			'explore.rows.trending' => 'トレンド',
			'explore.rows.upcomingMovies' => '近日公開の映画',
			'explore.rows.upcomingShows' => '放送予定の番組',
			'explore.status.airing' => '放送中',
			'explore.status.ended' => '放送終了',
			'explore.status.canceled' => '打ち切り',
			'explore.status.upcoming' => '放送予定',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, other: '${n} 話', ), 
			'explore.cast' => 'キャスト',
			'explore.characters' => 'キャラクター',
			'explore.addToWatchlist' => 'ウォッチリストに追加',
			'explore.removeFromWatchlist' => 'ウォッチリストから削除',
			'explore.watchlistUpdateFailed' => 'ウォッチリストを更新できませんでした',
			'explore.notInLibrary' => 'ライブラリにありません',
			'explore.inTheseLibraries' => 'これらのライブラリにあります',
			'explore.checkingLibrary' => 'ライブラリを確認中...',
			'explore.emptyTitle' => 'まだ何もありません',
			'explore.emptyMessage' => ({required Object source}) => '${source}にコンテンツが追加されると、ここに表示されます。',
			'explore.searchHint' => ({required Object source}) => '${source} で検索',
			'explore.searchEmpty' => ({required Object query}) => '「${query}」の結果が見つかりません',
			'explore.searchPrompt' => ({required Object source}) => '${source} で映画やテレビ番組を検索します。',
			'explore.searchFailed' => '検索に失敗しました。接続を確認してもう一度お試しください。',
			'liveTv.title' => 'ライブTV',
			'liveTv.guide' => '番組表',
			'liveTv.noChannels' => 'チャンネルがありません',
			'liveTv.noDvr' => 'どのサーバーにもDVRが設定されていません',
			'liveTv.serverUnavailable' => 'ライブTVサーバーを利用できません。',
			'liveTv.serverNotConnected' => 'ライブTVサーバーに接続されていません。',
			'liveTv.noPrograms' => '番組データがありません',
			'liveTv.liveStreamFailed' => 'ライブストリームに失敗しました',
			'liveTv.unknownProgram' => '不明な番組',
			'liveTv.unknownHub' => '不明',
			'liveTv.unknownError' => '不明なエラー',
			'liveTv.channelNumber' => ({required Object number}) => 'チャンネル ${number}',
			'liveTv.unknownChannel' => '不明なチャンネル',
			'liveTv.live' => 'ライブ',
			'liveTv.reloadGuide' => '番組表を再読込',
			'liveTv.now' => '現在',
			'liveTv.today' => '今日',
			'liveTv.tomorrow' => '明日',
			'liveTv.midnight' => '深夜',
			'liveTv.overnight' => '深夜',
			'liveTv.morning' => '朝',
			'liveTv.daytime' => '昼',
			'liveTv.evening' => '夕方',
			'liveTv.lateNight' => '深夜',
			'liveTv.whatsOn' => '放送中',
			'liveTv.watchChannel' => 'チャンネルを視聴',
			'liveTv.favorites' => 'お気に入り',
			'liveTv.reorderFavorites' => 'お気に入りを並べ替え',
			'liveTv.favoritesLoadFailed' => 'お気に入りを読み込めませんでした。接続を確認してもう一度お試しください。',
			'liveTv.joinSession' => '進行中のセッションに参加',
			'liveTv.watchFromStart' => ({required Object minutes}) => '最初から視聴（${minutes}分前に開始）',
			'liveTv.watchLive' => 'ライブで視聴',
			'liveTv.goToLive' => 'ライブに移動',
			'liveTv.record' => '録画',
			'liveTv.recordEpisode' => 'このエピソードを録画',
			'liveTv.recordSeries' => 'シリーズを録画',
			'liveTv.recordOptions' => '録画オプション',
			'liveTv.saveTo' => '保存先',
			'liveTv.recordings' => '録画',
			'liveTv.scheduledRecordings' => '予約',
			'liveTv.recordingRules' => '録画ルール',
			'liveTv.noScheduledRecordings' => '予約された録画はありません',
			'liveTv.manageRecording' => '録画を管理',
			'liveTv.cancelRecording' => '録画をキャンセル',
			'liveTv.cancelRecordingTitle' => 'この録画をキャンセルしますか？',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} は録画されなくなります。',
			'liveTv.deleteRule' => 'ルールを削除',
			'liveTv.deleteRuleTitle' => '録画ルールを削除しますか？',
			'liveTv.deleteRuleMessage' => ({required Object title}) => '${title} の今後のエピソードは録画されません。',
			'liveTv.recordingScheduled' => '録画を予約しました',
			'liveTv.alreadyScheduled' => 'この番組はすでに予約されています',
			'liveTv.dvrAdminRequired' => 'DVR 設定には管理者アカウントが必要です',
			'liveTv.recordingFailed' => '録画を予約できませんでした',
			'liveTv.recordingTargetMissing' => '録画ライブラリを特定できませんでした',
			'liveTv.recordNotAvailable' => 'この番組は録画できません',
			'liveTv.recordingCancelled' => '録画をキャンセルしました',
			'liveTv.recordingRuleDeleted' => '録画ルールを削除しました',
			'liveTv.processRecordingRules' => 'ルールを再評価',
			'liveTv.recordingInProgress' => '録画中',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} 件予約済み',
			'liveTv.editRule' => 'ルールを編集',
			'liveTv.editRuleAction' => '編集',
			'liveTv.recordingRuleUpdated' => '録画ルールを更新しました',
			'liveTv.guideReloadRequested' => 'ガイドの更新を要求しました',
			'liveTv.rulesProcessRequested' => 'ルールの再評価を要求しました',
			'liveTv.recordShow' => '番組を録画',
			'collections.title' => 'コレクション',
			'collections.collection' => 'コレクション',
			'collections.empty' => 'コレクションは空です',
			'collections.deleteCollection' => 'コレクションを削除',
			'collections.deleteConfirm' => ({required Object title}) => '「${title}」を削除しますか？元に戻せません。',
			'collections.deleted' => 'コレクションを削除しました',
			'collections.deleteFailed' => 'コレクションの削除に失敗しました',
			'collections.deleteFailedWithError' => ({required Object error}) => 'コレクションの削除に失敗しました: ${error}',
			'collections.selectCollection' => 'コレクションを選択',
			'collections.collectionName' => 'コレクション名',
			'collections.enterCollectionName' => 'コレクション名を入力',
			'collections.addedToCollection' => 'コレクションに追加しました',
			'collections.errorAddingToCollection' => 'コレクションへの追加に失敗しました',
			'collections.created' => 'コレクションを作成しました',
			'collections.removeFromCollection' => 'コレクションから削除',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => '"${title}"をこのコレクションから削除しますか？',
			'collections.removedFromCollection' => 'コレクションから削除しました',
			'collections.removeFromCollectionFailed' => 'コレクションからの削除に失敗しました',
			'collections.removeFromCollectionError' => ({required Object error}) => 'コレクションからの削除エラー: ${error}',
			'collections.searchCollections' => 'コレクションを検索...',
			'playlists.title' => 'プレイリスト',
			'playlists.playlist' => 'プレイリスト',
			'playlists.noPlaylists' => 'プレイリストが見つかりません',
			'playlists.create' => 'プレイリストを作成',
			'playlists.playlistName' => 'プレイリスト名',
			'playlists.enterPlaylistName' => 'プレイリスト名を入力',
			'playlists.delete' => 'プレイリストを削除',
			'playlists.removeItem' => 'プレイリストから削除',
			'playlists.smartPlaylist' => 'スマートプレイリスト',
			'playlists.itemCount' => ({required Object count}) => '${count}アイテム',
			'playlists.oneItem' => '1アイテム',
			'playlists.emptyPlaylist' => 'このプレイリストは空です',
			'playlists.deleteConfirm' => 'プレイリストを削除しますか？',
			'playlists.deleteMessage' => ({required Object name}) => '"${name}"を削除してもよろしいですか？',
			'playlists.created' => 'プレイリストを作成しました',
			'playlists.deleted' => 'プレイリストを削除しました',
			'playlists.itemAdded' => 'プレイリストに追加しました',
			'playlists.itemRemoved' => 'プレイリストから削除しました',
			'playlists.selectPlaylist' => 'プレイリストを選択',
			'playlists.searchPlaylists' => 'プレイリストを検索...',
			'playlists.errorCreating' => 'プレイリストの作成に失敗しました',
			'playlists.errorDeleting' => 'プレイリストの削除に失敗しました',
			'playlists.errorLoading' => 'プレイリストの読み込みに失敗しました',
			'playlists.errorAdding' => 'プレイリストへの追加に失敗しました',
			'playlists.errorReordering' => 'プレイリストアイテムの並べ替えに失敗しました',
			'playlists.errorRemoving' => 'プレイリストからの削除に失敗しました',
			'music.goToAlbum' => 'アルバムへ移動',
			'music.goToArtist' => 'アーティストへ移動',
			'music.instantMix' => 'インスタントミックス',
			'music.playNext' => '次に再生',
			'music.addToQueue' => 'キューに追加',
			'music.discNumber' => ({required Object n}) => 'ディスク ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, other: '${n} 曲', ), 
			'music.nowPlaying' => '再生中',
			'music.playingFrom' => ({required Object title}) => '${title} から再生',
			'music.queue' => '再生キュー',
			'music.clearQueue' => 'キューをクリア',
			'music.lyrics' => '歌詞',
			'music.noLyrics' => '歌詞がありません',
			'music.sleepTimer' => 'スリープタイマー',
			'music.sleepTimerEndOfTrack' => '曲の終わり',
			'music.sleepTimerMinutes' => ({required Object n}) => '${n} 分',
			'music.stopPlayback' => '再生を停止',
			'music.previousTrack' => '前の曲',
			'music.nextTrack' => '次の曲',
			'music.repeat' => 'リピート',
			'music.repeatAll' => '全曲リピート',
			'music.repeatOne' => '1曲リピート',
			'watchTogether.title' => '一緒に見る',
			'watchTogether.description' => '友達や家族と同期してコンテンツを視聴',
			'watchTogether.createSession' => 'セッションを作成',
			'watchTogether.creating' => '作成中...',
			'watchTogether.joinSession' => 'セッションに参加',
			'watchTogether.joining' => '参加中...',
			'watchTogether.controlMode' => 'コントロールモード',
			'watchTogether.controlModeQuestion' => '誰が再生を制御できますか？',
			'watchTogether.hostOnly' => 'ホストのみ',
			'watchTogether.anyone' => '全員',
			'watchTogether.hostingSession' => 'セッションをホスト中',
			'watchTogether.inSession' => 'セッション中',
			'watchTogether.sessionCode' => 'セッションコード',
			'watchTogether.openSessionControls' => '「一緒に見る」セッションのコントロールを開く',
			'watchTogether.copySessionCode' => 'セッションコードをコピー',
			'watchTogether.hostControlsPlayback' => 'ホストが再生を制御',
			'watchTogether.anyoneCanControl' => '全員が再生を制御可能',
			'watchTogether.hostControls' => 'ホストが制御',
			'watchTogether.anyoneControls' => '全員が制御',
			'watchTogether.participants' => '参加者',
			'watchTogether.host' => 'ホスト',
			'watchTogether.hostBadge' => 'HOST',
			'watchTogether.youAreHost' => 'あなたはホストです',
			'watchTogether.watchingWithOthers' => '他の人と視聴中',
			'watchTogether.endSession' => 'セッションを終了',
			'watchTogether.leaveSession' => 'セッションを退出',
			'watchTogether.endSessionQuestion' => 'セッションを終了しますか？',
			'watchTogether.leaveSessionQuestion' => 'セッションを退出しますか？',
			'watchTogether.endSessionConfirm' => 'すべての参加者のセッションが終了します。',
			'watchTogether.leaveSessionConfirm' => 'セッションから退出されます。',
			'watchTogether.endSessionConfirmOverlay' => 'すべての参加者の視聴セッションが終了します。',
			'watchTogether.leaveSessionConfirmOverlay' => '視聴セッションから切断されます。',
			'watchTogether.end' => '終了',
			'watchTogether.leave' => '退出',
			'watchTogether.syncing' => '同期中...',
			'watchTogether.joinWatchSession' => '視聴セッションに参加',
			'watchTogether.enterCodeHint' => '5文字のコードを入力',
			'watchTogether.pasteFromClipboard' => 'クリップボードから貼り付け',
			'watchTogether.pleaseEnterCode' => 'セッションコードを入力してください',
			'watchTogether.codeMustBe5Chars' => 'セッションコードは5文字である必要があります',
			'watchTogether.joinInstructions' => '参加するにはホストのセッションコードを入力してください。',
			'watchTogether.failedToCreate' => 'セッションの作成に失敗しました',
			'watchTogether.failedToJoin' => 'セッションへの参加に失敗しました',
			'watchTogether.sessionCodeCopied' => 'セッションコードをクリップボードにコピーしました',
			'watchTogether.relayUnreachable' => 'リレーサーバーに到達できません。ISPのブロックによりWatch Togetherが使えない可能性があります。',
			'watchTogether.reconnectingToHost' => 'ホストに再接続中...',
			'watchTogether.currentPlayback' => '現在の再生',
			'watchTogether.joinCurrentPlayback' => '現在の再生に参加',
			'watchTogether.joinCurrentPlaybackDescription' => 'ホストが現在視聴中のコンテンツに戻る',
			'watchTogether.failedToOpenCurrentPlayback' => '現在の再生を開けませんでした',
			'watchTogether.participantJoined' => ({required Object name}) => '${name}が参加しました',
			'watchTogether.participantLeft' => ({required Object name}) => '${name}が退出しました',
			'watchTogether.participantPaused' => ({required Object name}) => '${name}が一時停止しました',
			'watchTogether.participantResumed' => ({required Object name}) => '${name}が再開しました',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name}がシークしました',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name}がバッファリング中',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name} は古いバージョンのアプリを使用しているため、同期できません',
			'watchTogether.resumingWithout' => ({required Object name}) => '${name} なしで再開',
			'watchTogether.waitingForParticipants' => '他の参加者の読み込みを待っています...',
			'watchTogether.waitingForName' => ({required Object name}) => '${name}を待っています...',
			'watchTogether.recentRooms' => '最近のルーム',
			'watchTogether.renameRoom' => 'ルーム名を変更',
			'watchTogether.removeRoom' => '削除',
			'watchTogether.guestSwitchUnavailable' => '切り替えできません — サーバーが同期できません',
			'watchTogether.guestSwitchFailed' => '切り替えできません — このサーバーにコンテンツが見つかりません',
			'downloads.title' => 'ダウンロード',
			'downloads.manage' => '管理',
			'downloads.tvShows' => 'テレビ番組',
			'downloads.movies' => '映画',
			_ => null,
		} ?? switch (path) {
			'downloads.music' => '音楽',
			'downloads.tracksQueued' => ({required Object count}) => '${count} 曲をダウンロード待機中',
			'downloads.noDownloads' => 'ダウンロードなし',
			'downloads.noDownloadsDescription' => 'ダウンロードしたコンテンツはここに表示され、オフラインで視聴できます',
			'downloads.downloadNow' => 'ダウンロード',
			'downloads.deleteDownload' => 'ダウンロードを削除',
			'downloads.retryDownload' => 'ダウンロードを再試行',
			'downloads.downloadQueued' => 'ダウンロードをキューに追加しました',
			'downloads.downloadResumed' => 'ダウンロードを再開しました',
			'downloads.serverErrorBitrate' => 'サーバーエラー: ファイルがリモートビットレート制限を超えている可能性があります',
			'downloads.episodesQueued' => ({required Object count}) => '${count}エピソードをダウンロードキューに追加しました',
			'downloads.downloadDeleted' => 'ダウンロードを削除しました',
			'downloads.deleteConfirm' => ({required Object title}) => 'このデバイスから「${title}」を削除しますか？',
			'downloads.cancelledDownloadTitle' => 'キャンセルされたダウンロード',
			'downloads.cancelledDownloadMessage' => 'このダウンロードはキャンセルされました。どうしますか？',
			'downloads.allEpisodesAlreadyDownloaded' => 'すべてのエピソードはすでにダウンロード済みです',
			'downloads.resumeDownload' => 'ダウンロードを再開',
			'downloads.cancelledDownload' => 'キャンセルされたダウンロード',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file}（${status}を同期中）',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => '${file} をダウンロード済み — クリックして完了',
			'downloads.partialDownloadClickToComplete' => '一部ダウンロード済み — クリックして完了',
			'downloads.deleting' => '削除中...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => '${title}を削除中... (${current}/${total})',
			'downloads.queuedTooltip' => 'キュー',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'キュー: ${files}',
			'downloads.downloadingTooltip' => 'ダウンロード中...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => '${files} をダウンロード中',
			'downloads.noDownloadsTree' => 'ダウンロードなし',
			'downloads.pauseAll' => 'すべて一時停止',
			'downloads.resumeAll' => 'すべて再開',
			'downloads.deleteAll' => 'すべて削除',
			'downloads.selectVersion' => 'バージョンを選択',
			'downloads.allEpisodes' => 'すべてのエピソード',
			'downloads.unwatchedOnly' => '未視聴のみ',
			'downloads.nextNUnwatched' => ({required Object count}) => '次の${count}件の未視聴',
			'downloads.customAmount' => '数を指定...',
			'downloads.includeSpecials' => 'スペシャルを含める',
			'downloads.howManyEpisodes' => '何エピソード？',
			'downloads.invalidEpisodeCount' => '有効なエピソード数を入力してください。',
			'downloads.keepSynced' => '同期を維持',
			'downloads.downloadOnce' => '一度だけダウンロード',
			'downloads.keepNUnwatched' => ({required Object count}) => '未視聴を${count}件保持',
			'downloads.editSyncRule' => '同期ルールを編集',
			'downloads.removeSyncRule' => '同期ルールを削除',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => '「${title}」の同期を停止しますか？ダウンロード済みのエピソードは保持されます。',
			'downloads.syncRuleCreated' => ({required Object count}) => '同期ルールを作成しました — 未視聴のエピソードを${count}件保持',
			'downloads.syncRuleUpdated' => '同期ルールを更新しました',
			'downloads.syncRuleRemoved' => '同期ルールを削除しました',
			'downloads.syncedNewEpisodes' => ({required Object title, required Object count}) => '${title}の新しいエピソードを${count}件同期しました',
			'downloads.activeSyncRules' => '同期ルール',
			'downloads.noSyncRules' => '同期ルールなし',
			'downloads.manageSyncRule' => '同期を管理',
			'downloads.editEpisodeCount' => 'エピソード数',
			'downloads.editSyncFilter' => '同期フィルター',
			'downloads.syncAllItems' => 'すべてのアイテムを同期中',
			'downloads.syncUnwatchedItems' => '未視聴のアイテムを同期中',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'サーバー: ${server} • ${status}',
			'downloads.syncRuleAvailable' => '利用可能',
			'downloads.syncRuleOffline' => 'オフライン',
			'downloads.syncRuleSignInRequired' => 'サインインが必要',
			'downloads.syncRuleNotAvailableForProfile' => '現在のプロフィールでは利用できません',
			'downloads.syncRuleUnknownServer' => '不明なサーバー',
			'downloads.syncRuleListCreated' => '同期ルールを作成しました',
			'shaders.title' => 'シェーダー',
			'shaders.noShaderDescription' => '映像補正なし',
			'shaders.nvscalerDescription' => 'よりシャープな映像のためのNVIDIA画像スケーリング',
			'shaders.artcnnVariantNeutral' => 'ニュートラル',
			'shaders.artcnnVariantDenoise' => 'ノイズ除去',
			'shaders.artcnnVariantDenoiseSharpen' => 'ノイズ除去 + シャープ',
			'shaders.qualityFast' => '高速',
			'shaders.qualityHQ' => '高品質',
			'shaders.mode' => 'モード',
			'shaders.importShader' => 'シェーダーをインポート',
			'shaders.customShaderDescription' => 'カスタムGLSLシェーダー',
			'shaders.shaderImported' => 'シェーダーをインポートしました',
			'shaders.shaderImportFailed' => 'シェーダーのインポートに失敗しました',
			'shaders.deleteShader' => 'シェーダーを削除',
			'shaders.deleteShaderConfirm' => ({required Object name}) => '"${name}"を削除しますか？',
			'companionRemote.title' => 'コンパニオンリモート',
			'companionRemote.connectedTo' => ({required Object name}) => '${name}に接続中',
			'companionRemote.unknownDevice' => '不明なデバイス',
			'companionRemote.session.startingServer' => 'リモートサーバーを起動中...',
			'companionRemote.session.hostAddress' => 'ホストアドレス',
			'companionRemote.session.connected' => '接続済み',
			'companionRemote.session.serverRunning' => 'リモートサーバー稼働中',
			'companionRemote.session.serverStopped' => 'リモートサーバー停止中',
			'companionRemote.session.serverRunningDescription' => 'ネットワーク上のモバイルデバイスがこのアプリに接続できます',
			'companionRemote.session.serverStoppedDescription' => 'モバイルデバイスの接続を許可するにはサーバーを起動してください',
			'companionRemote.session.usePhoneToControl' => 'モバイルデバイスでこのアプリを操作できます',
			'companionRemote.session.startServer' => 'サーバーを起動',
			'companionRemote.session.stopServer' => 'サーバーを停止',
			'companionRemote.session.minimize' => '最小化',
			'companionRemote.pairing.discoveryDescription' => '同じPlexアカウントのPlezyデバイスがここに表示されます',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => '接続中...',
			'companionRemote.pairing.searchingForDevices' => 'デバイスを検索中...',
			'companionRemote.pairing.noDevicesFound' => 'ネットワーク上にデバイスが見つかりません',
			'companionRemote.pairing.noDevicesHint' => 'デスクトップでPlezyを開き、同じWiFiを使用してください',
			'companionRemote.pairing.availableDevices' => '利用可能なデバイス',
			'companionRemote.pairing.manualConnection' => '手動接続',
			'companionRemote.pairing.cryptoInitFailed' => '安全な接続を開始できませんでした。先にPlexにサインインしてください。',
			'companionRemote.pairing.validationHostRequired' => 'ホストアドレスを入力してください',
			'companionRemote.pairing.validationHostFormat' => '形式はIP:ポートである必要があります（例: 192.168.1.100:48632）',
			'companionRemote.pairing.connectionTimedOut' => '接続がタイムアウトしました。両方のデバイスで同じネットワークを使用してください。',
			'companionRemote.pairing.sessionNotFound' => 'デバイスが見つかりません。ホストでPlezyが実行中か確認してください。',
			'companionRemote.pairing.authFailed' => '認証に失敗しました。両方のデバイスで同じPlexアカウントが必要です。',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => '接続に失敗しました: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'リモートセッションから切断しますか？',
			'companionRemote.remote.reconnecting' => '再接続中...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => '試行 ${current}/5',
			'companionRemote.remote.retryNow' => '今すぐ再試行',
			'companionRemote.remote.tabRemote' => 'リモート',
			'companionRemote.remote.tabPlay' => '再生',
			'companionRemote.remote.tabMore' => 'その他',
			'companionRemote.remote.menu' => 'メニュー',
			'companionRemote.remote.tabNavigation' => 'タブナビゲーション',
			'companionRemote.remote.tabDiscover' => '探す',
			'companionRemote.remote.tabLibraries' => 'ライブラリ',
			'companionRemote.remote.tabSearch' => '検索',
			'companionRemote.remote.tabDownloads' => 'ダウンロード',
			'companionRemote.remote.tabSettings' => '設定',
			'companionRemote.remote.previous' => '前へ',
			'companionRemote.remote.playPause' => '再生/一時停止',
			'companionRemote.remote.next' => '次へ',
			'companionRemote.remote.seekBack' => '巻き戻し',
			'companionRemote.remote.stop' => '停止',
			'companionRemote.remote.seekForward' => '早送り',
			'companionRemote.remote.volume' => '音量',
			'companionRemote.remote.volumeDown' => '下げる',
			'companionRemote.remote.volumeUp' => '上げる',
			'companionRemote.remote.fullscreen' => 'フルスクリーン',
			'companionRemote.remote.subtitles' => '字幕',
			'companionRemote.remote.audio' => '音声',
			'companionRemote.remote.searchHint' => 'デスクトップで検索...',
			'companionRemote.errors.noNetworkInterface' => 'ネットワークインターフェースが見つかりません',
			'companionRemote.errors.authenticationFailed' => '認証に失敗しました',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'リモートサーバーを起動できませんでした: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'リモートコマンドを送信できませんでした: ${error}',
			'companionRemote.errors.joinTimedOut' => 'セッション参加がタイムアウトしました',
			'companionRemote.errors.failedToConnectAnyAddress' => 'どのアドレスにも接続できませんでした',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => '${attempts}回試行後に接続が切断されました',
			'companionRemote.errors.connectionLost' => '接続が切断されました',
			'videoSettings.playbackSpeed' => '再生速度',
			'videoSettings.normalSpeed' => '標準',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => '作動中（${duration}）',
			'videoSettings.zoom' => 'ズーム',
			'videoSettings.sleepTimer' => 'スリープタイマー',
			'videoSettings.audioSync' => '音声同期',
			'videoSettings.subtitleSync' => '字幕同期',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => '音声出力',
			'videoSettings.performanceOverlay' => 'パフォーマンスオーバーレイ',
			'videoSettings.audioPassthrough' => 'オーディオパススルー',
			'videoSettings.audioNormalization' => 'ラウドネス正規化',
			'videoSettings.audioDownmix' => 'ステレオにダウンミックス',
			'performanceOverlay.color' => '色',
			'performanceOverlay.performance' => 'パフォーマンス',
			'performanceOverlay.buffer' => 'バッファ',
			'performanceOverlay.app' => 'アプリ',
			'performanceOverlay.decoder' => 'デコーダー',
			'performanceOverlay.rawDecoder' => 'Raw デコーダー',
			'performanceOverlay.tunneling' => 'トンネリング',
			'performanceOverlay.aspect' => 'アスペクト',
			'performanceOverlay.rotation' => '回転',
			'performanceOverlay.dvSource' => 'DV ソース',
			'performanceOverlay.dvPath' => 'DV パス',
			'performanceOverlay.p7Conversion' => 'P7 変換',
			'performanceOverlay.sampleRate' => 'サンプルレート',
			'performanceOverlay.pixelFormat' => 'ピクセル形式',
			'performanceOverlay.hwFormat' => 'HW 形式',
			'performanceOverlay.matrix' => 'マトリクス',
			'performanceOverlay.primaries' => 'プライマリ',
			'performanceOverlay.transfer' => '転送',
			'performanceOverlay.renderFps' => '描画 FPS',
			'performanceOverlay.displayFps' => '表示 FPS',
			'performanceOverlay.avSync' => 'A/V 同期',
			'performanceOverlay.dropped' => 'ドロップ',
			'performanceOverlay.dvRpus' => 'DV RPU',
			'performanceOverlay.dvRpuAverage' => 'DV RPU 平均',
			'performanceOverlay.dvSampleAverage' => 'DV サンプル平均',
			'performanceOverlay.maxLuma' => '最大輝度',
			'performanceOverlay.minLuma' => '最小輝度',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => '使用キャッシュ',
			'performanceOverlay.cacheLimit' => 'キャッシュ上限',
			'performanceOverlay.speed' => '速度',
			'performanceOverlay.player' => 'プレーヤー',
			'performanceOverlay.memory' => 'メモリ',
			'performanceOverlay.uiFps' => 'UI FPS',
			'externalPlayer.title' => '外部プレーヤー',
			'externalPlayer.useExternalPlayer' => '外部プレーヤーを使用',
			'externalPlayer.useExternalPlayerDescription' => '動画を別のアプリで開きます',
			'externalPlayer.selectPlayer' => 'プレーヤーを選択',
			'externalPlayer.customPlayers' => 'カスタムプレーヤー',
			'externalPlayer.systemDefault' => 'システムデフォルト',
			'externalPlayer.addCustomPlayer' => 'カスタムプレーヤーを追加',
			'externalPlayer.playerName' => 'プレーヤー名',
			'externalPlayer.playerNameHint' => 'マイプレーヤー',
			'externalPlayer.playerCommand' => 'コマンド',
			'externalPlayer.playerPackage' => 'パッケージ名',
			'externalPlayer.playerUrlScheme' => 'URLスキーム',
			'externalPlayer.off' => 'オフ',
			'externalPlayer.launchFailed' => '外部プレーヤーの起動に失敗しました',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name}がインストールされていません',
			'externalPlayer.playInExternalPlayer' => '外部プレーヤーで再生',
			'metadataEdit.editMetadata' => '編集...',
			'metadataEdit.screenTitle' => 'メタデータを編集',
			'metadataEdit.basicInfo' => '基本情報',
			'metadataEdit.artwork' => 'アートワーク',
			'metadataEdit.advancedSettings' => '詳細設定',
			'metadataEdit.title' => 'タイトル',
			'metadataEdit.sortTitle' => 'ソートタイトル',
			'metadataEdit.originalTitle' => '原題',
			'metadataEdit.releaseDate' => '公開日',
			'metadataEdit.contentRating' => 'コンテンツレーティング',
			'metadataEdit.studio' => 'スタジオ',
			'metadataEdit.tagline' => 'タグライン',
			'metadataEdit.summary' => 'あらすじ',
			'metadataEdit.poster' => 'ポスター',
			'metadataEdit.background' => '背景',
			'metadataEdit.logo' => 'ロゴ',
			'metadataEdit.squareArt' => '正方形アート',
			'metadataEdit.selectPoster' => 'ポスターを選択',
			'metadataEdit.selectBackground' => '背景を選択',
			'metadataEdit.selectLogo' => 'ロゴを選択',
			'metadataEdit.selectSquareArt' => '正方形アートを選択',
			'metadataEdit.fromUrl' => 'URLから',
			'metadataEdit.uploadFile' => 'ファイルをアップロード',
			'metadataEdit.enterImageUrl' => '画像URLを入力',
			'metadataEdit.imageUrl' => '画像URL',
			'metadataEdit.metadataUpdated' => 'メタデータを更新しました',
			'metadataEdit.metadataUpdateFailed' => 'メタデータの更新に失敗しました',
			'metadataEdit.artworkUpdated' => 'アートワークを更新しました',
			'metadataEdit.artworkUpdateFailed' => 'アートワークの更新に失敗しました',
			'metadataEdit.noArtworkAvailable' => 'アートワークがありません',
			'metadataEdit.artworkOption' => ({required Object index}) => 'アートワークの選択肢 ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'アートワークの選択肢 ${index}、選択済み',
			'metadataEdit.notSet' => '未設定',
			'metadataEdit.libraryDefault' => 'ライブラリのデフォルト',
			'metadataEdit.accountDefault' => 'アカウントのデフォルト',
			'metadataEdit.seriesDefault' => 'シリーズのデフォルト',
			'metadataEdit.episodeSorting' => 'エピソードの並べ替え',
			'metadataEdit.oldestFirst' => '古い順',
			'metadataEdit.newestFirst' => '新しい順',
			'metadataEdit.keep' => '保持',
			'metadataEdit.allEpisodes' => 'すべてのエピソード',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '最新${count}エピソード',
			'metadataEdit.latestEpisode' => '最新エピソード',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => '過去${count}日間に追加されたエピソード',
			'metadataEdit.deleteAfterPlaying' => '再生後にエピソードを削除',
			'metadataEdit.never' => 'しない',
			'metadataEdit.afterADay' => '1日後',
			'metadataEdit.afterAWeek' => '1週間後',
			'metadataEdit.afterAMonth' => '1ヶ月後',
			'metadataEdit.onNextRefresh' => '次回更新時',
			'metadataEdit.seasons' => 'シーズン',
			'metadataEdit.show' => '表示',
			'metadataEdit.hide' => '非表示',
			'metadataEdit.episodeOrdering' => 'エピソードの順序',
			'metadataEdit.tmdbAiring' => 'The Movie Database（放送順）',
			'metadataEdit.tvdbAiring' => 'TheTVDB（放送順）',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB（絶対順）',
			'metadataEdit.metadataLanguage' => 'メタデータの言語',
			'metadataEdit.useOriginalTitle' => '原題を使用',
			'metadataEdit.preferredAudioLanguage' => '優先音声言語',
			'metadataEdit.preferredSubtitleLanguage' => '優先字幕言語',
			'metadataEdit.subtitleMode' => '字幕自動選択モード',
			'metadataEdit.manuallySelected' => '手動選択',
			'metadataEdit.shownWithForeignAudio' => '外国語音声時に表示',
			'metadataEdit.alwaysEnabled' => '常に有効',
			'metadataEdit.tags' => 'タグ',
			'metadataEdit.addTag' => 'タグを追加',
			'metadataEdit.genre' => 'ジャンル',
			'metadataEdit.director' => '監督',
			'metadataEdit.writer' => '脚本',
			'metadataEdit.producer' => 'プロデューサー',
			'metadataEdit.country' => '国',
			'metadataEdit.collection' => 'コレクション',
			'metadataEdit.label' => 'ラベル',
			'metadataEdit.style' => 'スタイル',
			'metadataEdit.mood' => 'ムード',
			'matchScreen.match' => 'マッチ...',
			'matchScreen.fixMatch' => 'マッチを修正...',
			'matchScreen.unmatch' => 'マッチ解除',
			'matchScreen.unmatchConfirm' => 'この一致をクリアしますか？再一致するまでPlexでは未一致として扱われます。',
			'matchScreen.unmatchSuccess' => 'マッチを解除しました',
			'matchScreen.unmatchFailed' => 'マッチの解除に失敗しました',
			'matchScreen.matchApplied' => 'マッチを適用しました',
			'matchScreen.matchFailed' => 'マッチの適用に失敗しました',
			'matchScreen.titleHint' => 'タイトル',
			'matchScreen.yearHint' => '年',
			'matchScreen.search' => '検索',
			'matchScreen.noMatchesFound' => '一致する項目がありません',
			'serverTasks.title' => 'サーバータスク',
			'serverTasks.failedToLoad' => 'タスクの読み込みに失敗しました',
			'serverTasks.noTasks' => '実行中のタスクはありません',
			'trakt.title' => 'Trakt',
			'trakt.connected' => '接続済み',
			'trakt.connectedAs' => ({required Object username}) => '@${username} として接続済み',
			'trakt.disconnectConfirm' => 'Trakt アカウントを切断しますか?',
			'trakt.disconnectConfirmBody' => 'PlezyはTraktへのイベント送信を停止します。いつでも再接続できます。',
			'trakt.scrobble' => 'リアルタイムのスクロブル',
			'trakt.scrobbleDescription' => '再生中に再生・一時停止・停止イベントを Trakt に送信します。',
			'trakt.watchedSync' => '視聴済みステータスを同期',
			'trakt.watchedSyncDescription' => 'Plezy で項目を視聴済みにすると、Trakt でも視聴済みになります。',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Seerrに接続',
			'seerr.serverUrl' => 'サーバー URL',
			'seerr.serverUrlHelper' => 'Seerr インスタンスのアドレス',
			'seerr.checkServer' => '続ける',
			'seerr.signInWithJellyfin' => 'Jellyfinでサインイン',
			'seerr.signInWithEmby' => 'Embyでサインイン',
			'seerr.signInWithLocal' => 'ローカルアカウントを使う',
			'seerr.email' => 'メールアドレス',
			'seerr.noSignInMethods' => 'この Seerr インスタンスには Plezy が対応しているサインイン方法がありません。',
			'seerr.instance' => 'インスタンス',
			'seerr.disconnectConfirm' => 'Seerr の接続を解除しますか？',
			'seerr.disconnectConfirmBody' => 'Plezy はこの Seerr インスタンスの情報を削除します。いつでも再接続できます。',
			'seerr.request' => 'リクエスト',
			'seerr.request4k' => '4K でリクエスト',
			'seerr.seasons' => 'シーズン',
			'seerr.allSeasons' => '全シーズン',
			'seerr.advancedOptions' => '詳細',
			'seerr.destinationServer' => '宛先サーバー',
			'seerr.qualityProfile' => '画質プロファイル',
			'seerr.rootFolder' => 'ルートフォルダ',
			'seerr.languageProfile' => '言語プロファイル',
			'seerr.requestSubmitted' => 'リクエストを送信しました',
			'seerr.requestFailed' => ({required Object error}) => 'リクエストに失敗しました: ${error}',
			'seerr.requestsLoadFailed' => 'リクエストオプションを読み込めませんでした',
			'seerr.nothingToRequest' => 'すべてすでに利用可能またはリクエスト済みです。',
			'seerr.statusAvailable' => '利用可能',
			'seerr.statusPartiallyAvailable' => '一部利用可能',
			'seerr.statusRequested' => 'リクエスト済み',
			'seerr.statusProcessing' => '処理中',
			'services.title' => 'サービス',
			'services.hubSubtitle' => '視聴の進捗を同期して、新しいタイトルをリクエストします。',
			'services.notConnected' => '未接続',
			'services.connectedAs' => ({required Object username}) => '@${username} として接続済み',
			'services.scrobble' => '進捗を自動で記録',
			'services.scrobbleDescription' => 'エピソードや映画を見終えたときにリストを更新します。',
			'services.disconnectConfirm' => ({required Object service}) => '${service} の接続を解除しますか？',
			'services.disconnectConfirmBody' => ({required Object service}) => 'Plezyは${service}の更新を停止します。いつでも再接続できます。',
			'services.connectFailed' => ({required Object service}) => '${service} に接続できませんでした。もう一度お試しください。',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.deviceCode.title' => ({required Object service}) => '${service} で Plezy を有効化',
			'services.deviceCode.body' => ({required Object url}) => '${url} にアクセスしてこのコードを入力:',
			'services.deviceCode.openToActivate' => ({required Object service}) => '${service} を開いて有効化',
			'services.deviceCode.copyCode' => 'アクティベーションコードをコピー',
			'services.deviceCode.waitingForAuthorization' => '認証を待っています…',
			'services.deviceCode.codeCopied' => 'コードをコピーしました',
			'services.oauthProxy.title' => ({required Object service}) => '${service} にサインイン',
			'services.oauthProxy.body' => 'このQRコードをスキャンするか、任意のデバイスでURLを開いてください。',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => '${service} を開いてサインイン',
			'services.oauthProxy.copyUrl' => 'サインインURLをコピー',
			'services.oauthProxy.urlCopied' => 'URLをコピーしました',
			'services.libraryFilter.title' => 'ライブラリフィルター',
			'services.libraryFilter.subtitleAllSyncing' => 'すべてのライブラリを同期中',
			'services.libraryFilter.subtitleNoneSyncing' => '同期なし',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} 件をブロック',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} 件を許可',
			'services.libraryFilter.mode' => 'フィルターモード',
			'services.libraryFilter.modeBlacklist' => 'ブロックリスト',
			'services.libraryFilter.modeWhitelist' => '許可リスト',
			'services.libraryFilter.modeHintBlacklist' => '下でチェックしたライブラリ以外をすべて同期します。',
			'services.libraryFilter.modeHintWhitelist' => '下でチェックしたライブラリのみ同期します。',
			'services.libraryFilter.libraries' => 'ライブラリ',
			'services.libraryFilter.noLibraries' => '利用できるライブラリがありません',
			'addServer.addJellyfinTitle' => 'Jellyfinサーバーを追加',
			'addServer.serverUrls' => 'サーバーURL',
			'addServer.serverUrlsHelper' => '複数のURLをカンマ区切りで入力できます。',
			'addServer.findServer' => 'サーバーを検索',
			'addServer.searchingLocalServers' => 'ローカル Jellyfin サーバーを検索中...',
			'addServer.localServers' => 'ローカル Jellyfin サーバー',
			'addServer.username' => 'ユーザー名',
			'addServer.password' => 'パスワード',
			'addServer.signIn' => 'サインイン',
			'addServer.change' => '変更',
			'addServer.required' => '必須',
			'addServer.couldNotReachServer' => ({required Object error}) => 'サーバーに接続できませんでした: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'サインインに失敗しました: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connectに失敗しました: ${error}',
			'addServer.addPlexTitle' => 'Plexでサインイン',
			'addServer.pinExpired' => 'サインイン前にPINの有効期限が切れました。もう一度お試しください。',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'アカウントの登録に失敗しました: ${error}',
			'addServer.enterJellyfinUrlError' => 'JellyfinサーバーのURLを入力してください',
			'addServer.addConnectionTitle' => '接続を追加',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => '${name}に追加',
			'addServer.signInWithPlexCard' => 'Plexでサインイン',
			'addServer.signInWithPlexCardSubtitle' => 'このデバイスを承認します。共有サーバーが追加されます。',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Plexアカウントを承認します。Homeユーザーはプロフィールになります。',
			'addServer.connectToJellyfinCard' => 'Jellyfinに接続',
			'addServer.connectToJellyfinCardSubtitle' => 'サーバーURL、ユーザー名、パスワードを入力してください。',
			'addServer.connectToJellyfinCardSubtitleScoped' => ({required Object name}) => 'Jellyfinサーバーにサインインします。${name}に紐付けられます。',
			'addServer.borrowFromAnotherProfile' => '別のプロファイルから借りる',
			'addServer.borrowFromAnotherProfileSubtitle' => '別のプロフィールの接続を再利用します。PIN保護されたプロフィールにはPINが必要です。',
			_ => null,
		};
	}
}
